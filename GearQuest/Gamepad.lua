local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Log = GQ.Log or {}

-- Gamepad UI only. Mouse mode never enables this. Opening the log takes the
-- pad, including from /gq. A gold chevron sits to the left of the focused
-- control and a blue highlight marks it. On the hunt list the arrows and the
-- left stick move through the hunts. Down stays on the next hunt. Up from the
-- top hunt reaches Active, Completed, and Removed, and left and right move
-- among those tabs. Moving onto a control does not change it. Y moves the
-- arrow onto the filter controls and does not apply a filter. A second Y
-- returns to the hunts. A confirms. A on a hunt moves the arrow to Track.
-- The right stick scrolls the parchment. The left bumper goes to the previous
-- page and the right bumper to the next. The level box and the search box
-- open the on-screen keyboard, and while that box has focus the pad belongs
-- to the keyboard.
local DIRECTION = {
    PADDUP = "up",
    PADDDOWN = "down",
    PADDLEFT = "left",
    PADDRIGHT = "right",
    PADLSTICKUP = "up",
    PADLSTICKDOWN = "down",
    PADLSTICKLEFT = "left",
    PADLSTICKRIGHT = "right",
}

local HELD_MOVE = {
    dpad = {
        up = { PADDUP = true },
        down = { PADDDOWN = true },
        left = { PADDLEFT = true },
        right = { PADDRIGHT = true },
    },
    stick = {
        up = { PADLSTICKUP = true },
        down = { PADLSTICKDOWN = true },
        left = { PADLSTICKLEFT = true },
        right = { PADLSTICKRIGHT = true },
    },
}

local HELD_SCROLL = {
    up = { PADRSTICKUP = true },
    down = { PADRSTICKDOWN = true },
}

local PAGES = { "log", "lookup", "simulator", "settings" }

local function ObjectType(widget)
    if widget and widget.GetObjectType then
        return widget:GetObjectType()
    end
end

local function WidgetName(widget)
    if widget and widget.GetName then
        return widget:GetName()
    end
end

local function IsScrollBar(widget)
    local name = WidgetName(widget)
    return name and name:find("ScrollBar", 1, true) ~= nil
end

local function SliderAncestor(widget)
    local parent = widget and widget.GetParent and widget:GetParent()
    while parent do
        if ObjectType(parent) == "Slider" then
            return true
        end
        parent = parent.GetParent and parent:GetParent()
    end
    return false
end

local CONFIRM_NAMES = {
    PAD1 = true,
    PADA = true,
    PADFACE1 = true,
    PADBOTTOM = true,
    PADSOUTH = true,
    JUMP = true,
}

local FILTER_NAMES = {
    PAD4 = true,
    PADY = true,
    PADFACE4 = true,
    PADNORTH = true,
}

local function ButtonDown(log, names)
    local down = log and log._padDown
    if not down then
        return false
    end
    for name in pairs(down) do
        if names[name] or (DIRECTION[name] and names == DIRECTION) then
            return true
        end
    end
    return false
end

-- A direction press must not run OnClick. CheckButtons flip their checked
-- state before that script, so a stray gamepad click is put back. A confirm
-- sets _padAllowClick and is allowed through. Y is swallowed so the same
-- press cannot open a filter menu.
local function GuardClick(widget)
    if not widget or not widget.GetScript or not widget.SetScript then
        return
    end
    if widget:GetScript("OnClick") == widget._gqPadClickFn then
        return
    end
    local original = widget:GetScript("OnClick")
    local function wrapped(self, button, down)
        local log = GQ.Log
        local now = GetTime()
        if log and log.GamepadReadButtons then
            log:GamepadReadButtons()
        end
        local swallowed = log and log._padSwallowUntil and now < log._padSwallowUntil
        local steering = log and ButtonDown(log, DIRECTION)
        local filtering = log and ButtonDown(log, FILTER_NAMES)
        if log and log._padOn and not log._padAllowClick and (steering or swallowed or filtering) then
            if self.GetChecked and self.SetChecked and ObjectType(self) == "CheckButton" then
                self:SetChecked(not self:GetChecked())
            end
            return
        end
        if log and log._padOn and not log._padAllowClick and ButtonDown(log, CONFIRM_NAMES) then
            log._padEngineClickWidget = self
            log._padEngineClickAt = now
        end
        if original then
            original(self, button, down)
        end
        if log and log._padOn and log.GamepadFollowClick and log._padAllowClick then
            log:GamepadFollowClick(self)
        elseif log and log._padOn and log.GamepadFollowClick and not steering and not swallowed then
            log:GamepadFollowClick(self)
        end
    end
    widget._gqPadClickFn = wrapped
    widget:SetScript("OnClick", wrapped)
end

local function SilenceFrame(widget, owner)
    if not widget or widget == owner or widget.gqGamepadRing then
        return
    end
    local kind = ObjectType(widget)
    if kind == "Button" or kind == "CheckButton" or kind == "Slider" then
        if widget.EnableGamePadButton and not widget._gqPadSilenced then
            widget._gqPadSilenced = true
            pcall(widget.EnableGamePadButton, widget, false)
        end
        if widget.EnableGamePadStick then
            pcall(widget.EnableGamePadStick, widget, false)
        end
    end
    if kind == "Button" or kind == "CheckButton" then
        if not widget._gqPadButtonBlocked then
            widget._gqPadButtonBlocked = true
            local function ignore()
            end
            pcall(widget.SetScript, widget, "OnGamePadButtonDown", ignore)
            pcall(widget.SetScript, widget, "OnGamePadButtonUp", ignore)
        end
        GuardClick(widget)
    end
end

local function Usable(widget)
    if not widget or widget.gqGamepadRing then
        return false
    end
    if not widget.IsShown or not widget:IsShown() then
        return false
    end
    if widget.IsVisible and not widget:IsVisible() then
        return false
    end
    local kind = ObjectType(widget)
    if kind ~= "Button" and kind ~= "CheckButton" and kind ~= "EditBox" and kind ~= "Slider" then
        return false
    end
    if IsScrollBar(widget) or (kind ~= "Slider" and SliderAncestor(widget)) then
        return false
    end
    local width = widget.GetWidth and widget:GetWidth() or 0
    local height = widget.GetHeight and widget:GetHeight() or 0
    if width < 8 or height < 8 then
        return false
    end
    if widget.IsEnabled and not widget:IsEnabled() then
        return false
    end
    if (kind == "Button" or kind == "CheckButton") and widget.IsMouseEnabled and not widget:IsMouseEnabled() then
        return false
    end
    return widget.GetCenter and widget:GetCenter() ~= nil
end

local function Walk(root, into, owner)
    if not root or not root.IsShown or not root:IsShown() then
        return
    end
    SilenceFrame(root, owner)
    if Usable(root) then
        into[#into + 1] = root
    end
    if root.GetChildren then
        local children = { root:GetChildren() }
        for i = 1, #children do
            Walk(children[i], into, owner)
        end
    end
end

local function PageTab(log, page)
    local frame = log.frame
    if not frame then
        return nil
    end
    if page == "log" then
        return frame.tabLog
    elseif page == "lookup" then
        return frame.tabLookup
    elseif page == "simulator" then
        return frame.tabSimulator
    elseif page == "settings" then
        return frame.tabSettings
    end
end

local function ConfigButtonName(index)
    if type(index) ~= "number" or not C_GamePad or not C_GamePad.ButtonIndexToConfigName then
        return nil
    end
    local ok, name = pcall(C_GamePad.ButtonIndexToConfigName, index)
    if ok and type(name) == "string" and name ~= "" then
        return name:upper()
    end
    return nil
end

-- Face buttons are bound to jump and interact, and the left bumper emulates
-- Ctrl. The button array and ButtonIndexToConfigName are not always the same
-- base. A wrong base turns the d-pad into confirm and the left bumper into
-- the right one. The binding name is never used: Jump is A, and also whatever
-- else the player bound to Jump.
local apiBase
local function ApiBase()
    if apiBase ~= nil then
        return apiBase
    end
    if ConfigButtonName(0) == "PAD1" then
        apiBase = 0
    elseif ConfigButtonName(1) == "PAD1" then
        apiBase = 1
    else
        apiBase = 0
    end
    return apiBase
end

local function TableBase(buttons)
    if type(buttons) == "table" and buttons[0] ~= nil then
        return 0
    end
    return 1
end

local function NameFor(index, tableBase)
    if type(index) ~= "number" then
        return nil
    end
    return ConfigButtonName(index - tableBase + ApiBase())
end

local function Canonical(button)
    if type(button) == "number" then
        return NameFor(button, 0) or ""
    end
    if type(button) ~= "string" then
        return ""
    end
    local name = button:upper()
    return name:match("(PAD[A-Z0-9]+)") or name
end

-- Returns action, a, b. Move: direction, source. Page: step. Scroll: direction.
local function PadAction(name)
    if not name or name == "" then
        return nil
    end
    local direction = DIRECTION[name]
    if direction then
        if name:find("STICK", 1, true) then
            return "move", direction, "stick"
        end
        return "move", direction, "dpad"
    end
    if name == "PADRSTICKUP" then
        return "scroll", "up"
    end
    if name == "PADRSTICKDOWN" then
        return "scroll", "down"
    end
    if name:find("LSHOULDER", 1, true) or name:find("LBUMPER", 1, true) then
        return "page", -1
    end
    if name:find("RSHOULDER", 1, true) or name:find("RBUMPER", 1, true) then
        return "page", 1
    end
    -- Bottom face: Xbox A, PlayStation Cross. Some pads report the face by
    -- binding (A is Jump) instead of PAD1.
    if name == "PAD1" or name == "PADA" or name == "PADFACE1" or name == "PADBOTTOM" or name == "PADSOUTH"
        or name == "JUMP" then
        return "confirm"
    end
    -- Right face: Xbox B, PlayStation Circle.
    if name == "PAD2" or name == "PADB" or name == "PADFACE2" or name == "PADEAST" then
        return "back"
    end
    -- Top face: Xbox Y, PlayStation Triangle.
    if name == "PAD4" or name == "PADY" or name == "PADFACE4" or name == "PADNORTH" then
        return "filters"
    end
    return nil
end

function GQ.Log:GamepadGuideBubble()
    if not GQ.UsesGamepad or not GQ:UsesGamepad() then
        return nil
    end
    local guide = GQ.PortraitGuide
    local bubble = guide and guide.bubble
    if bubble and bubble.IsShown and bubble:IsShown() then
        return bubble
    end
    return nil
end

function GQ.Log:GamepadIsGuidePortrait(widget)
    local hit = GQ.PortraitGuide and GQ.PortraitGuide.hit
    return hit and widget == hit or false
end

function GQ.Log:GamepadSyncGuide()
    if not self._padOn or not GQ.UsesGamepad or not GQ:UsesGamepad() then
        return
    end
    local list = self:GamepadCandidates()
    local focus = self._padFocus
    if focus and self:GamepadContains(list, focus) and self:GamepadFocusVisible(focus) then
        return
    end
    local bubble = self:GamepadGuideBubble()
    local initial
    if bubble and Usable(bubble.yes) then
        initial = bubble.yes
    elseif bubble and Usable(bubble.forward) then
        initial = bubble.forward
    elseif bubble and Usable(bubble.back) then
        initial = bubble.back
    else
        initial = self:GamepadPickInitial(list)
    end
    self:GamepadSetFocus(initial)
end

function GQ.Log:GamepadOverlay()
    local bubble = self:GamepadGuideBubble()
    if bubble then
        local probe = {}
        Walk(bubble, probe, self.frame)
        if #probe > 0 then
            return bubble
        end
    end
    local frame = self.frame
    local panels = {
        frame and frame.sourceFilterMenu,
        frame and frame.playStylePanel,
        frame and frame.specPicker,
        self.weaponMenu,
    }
    local best, bestLevel
    for i = 1, #panels do
        local panel = panels[i]
        if panel and panel.IsShown and panel:IsShown() then
            local level = panel.GetFrameLevel and panel:GetFrameLevel() or 0
            if not best or level >= bestLevel then
                best = panel
                bestLevel = level
            end
        end
    end
    if not best then
        return nil
    end
    local probe = {}
    Walk(best, probe, self.frame)
    if #probe == 0 then
        return nil
    end
    return best
end

function GQ.Log:GamepadIsPageTab(widget)
    local frame = self.frame
    if not frame or not widget then
        return false
    end
    return widget == frame.tabLog or widget == frame.tabLookup
        or widget == frame.tabSimulator or widget == frame.tabSettings
end

function GQ.Log:GamepadIsListTarget(widget)
    local kind = widget.rowType
    if kind == "item" or kind == "notable" or kind == "header" then
        return true
    end
    local frame = self.frame
    if not frame then
        return false
    end
    return widget == frame.tabActive or widget == frame.tabCompleted or widget == frame.tabRemoved
        or widget == frame.trackBtn or widget == frame.mapBtn or widget == frame.removeBtn
        or self:GamepadIsGuidePortrait(widget)
end

function GQ.Log:GamepadIsRow(widget)
    local kind = widget and widget.rowType
    return kind == "item" or kind == "notable" or kind == "header"
end

function GQ.Log:GamepadIsListTab(widget)
    local frame = self.frame
    return frame and (widget == frame.tabActive or widget == frame.tabCompleted or widget == frame.tabRemoved) or false
end

function GQ.Log:GamepadIsFilterTarget(widget)
    local frame = self.frame
    if frame and (widget == frame.sourceFilterBtn or widget == frame.playStyleBtn) then
        return true
    end
    local parent = widget.GetParent and widget:GetParent()
    return parent and parent.weaponArrow == widget or false
end

function GQ.Log:GamepadCandidates()
    local list = {}
    local overlay = self:GamepadOverlay()
    if overlay then
        Walk(overlay, list, self.frame)
        return list
    end
    local frame = self.frame
    if frame then
        Walk(frame, list, frame)
        Walk(frame.sideTabRail, list, frame)
    end
    local page = self.GetPageTab and self:GetPageTab() or "log"
    local filtered = {}
    for i = 1, #list do
        local widget = list[i]
        if not self:GamepadIsPageTab(widget) then
            if page ~= "log" then
                filtered[#filtered + 1] = widget
            elseif self._padFilterMode then
                if self:GamepadIsFilterTarget(widget) then
                    filtered[#filtered + 1] = widget
                end
            elseif self:GamepadIsListTarget(widget) then
                filtered[#filtered + 1] = widget
            end
        end
    end
    if #filtered > 0 then
        return filtered
    end
    return list
end

function GQ.Log:GamepadContains(list, widget)
    for i = 1, #list do
        if list[i] == widget then
            return true
        end
    end
    return false
end

local function CallHandler(widget, name)
    if not widget or not widget.GetScript then
        return
    end
    local handler = widget:GetScript(name)
    if handler then
        pcall(handler, widget)
    end
end

-- Mouse OnLeave closes filter flyouts. Only hunt rows and their (i) buttons
-- use those handlers, so a pad move can show the same tooltip a hover would.
local function HoverWidget(widget)
    if not widget then
        return false
    end
    if widget.rowType or widget.entry or widget.lookupItem then
        return true
    end
    local parent = widget.GetParent and widget:GetParent()
    return parent and (parent.rowType or parent.entry or parent.lookupItem) or false
end

function GQ.Log:GamepadEnsureRing()
    if self._padRing then
        return self._padRing
    end
    local ring = CreateFrame("Frame", nil, UIParent)
    ring.gqGamepadRing = true
    ring:Hide()
    ring:EnableMouse(false)
    ring:SetSize(1, 1)
    ring:SetFrameStrata("TOOLTIP")
    ring:SetFrameLevel(80)

    local wash = ring:CreateTexture(nil, "ARTWORK")
    wash:SetColorTexture(0.22, 0.52, 1, 1)
    wash:SetAlpha(0.18)
    wash:Hide()
    ring.wash = wash

    local hilight = ring:CreateTexture(nil, "OVERLAY")
    hilight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hilight:SetBlendMode("ADD")
    hilight:SetAlpha(0.95)
    hilight:Hide()
    ring.hilight = hilight

    local arrow = ring:CreateTexture(nil, "OVERLAY")
    local addon = GQ.ADDON_NAME or "GearQuestForever"
    arrow:SetTexture("Interface\\AddOns\\" .. addon .. "\\Art\\GQ-PadArrow.png")
    ring.arrow = arrow

    self._padRing = ring
    return ring
end

function GQ.Log:GamepadFocusVisible(widget)
    if not widget then
        return false
    end
    if widget.IsVisible then
        return widget:IsVisible() and true or false
    end
    return widget.IsShown and widget:IsShown() and true or false
end

function GQ.Log:GamepadPlaceCursor(widget)
    local ring = self:GamepadEnsureRing()
    ring:SetParent(UIParent)
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", widget, "CENTER", 0, 0)
    ring:SetFrameStrata("TOOLTIP")
    ring:SetFrameLevel(80)

    local width = widget.GetWidth and widget:GetWidth() or 24
    local height = widget.GetHeight and widget:GetHeight() or 24
    if not width or width < 8 then
        width = 24
    end
    if not height or height < 8 then
        height = 24
    end
    local arrowSize = height * 1.05
    if arrowSize < 26 then
        arrowSize = 26
    elseif arrowSize > 34 then
        arrowSize = 34
    end
    local nudge = math.sin(GetTime() * 4.2) * 4
    ring.arrow:ClearAllPoints()
    ring.arrow:SetSize(arrowSize, arrowSize)
    ring.arrow:SetPoint("RIGHT", widget, "LEFT", nudge, 0)
    ring.arrow:Show()

    local icon = widget.itemIcon
    local iconShown = icon and icon.IsShown and icon:IsShown() and icon.GetWidth and (icon:GetWidth() or 0) >= 8
    ring.hilight:ClearAllPoints()
    ring.wash:ClearAllPoints()
    if iconShown then
        ring.hilight:SetPoint("TOPLEFT", icon, "TOPLEFT", -5, 5)
        ring.hilight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 5, -5)
        ring.hilight:Show()
        ring.wash:SetPoint("TOPLEFT", widget, "TOPLEFT")
        ring.wash:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT")
        ring.wash:SetAlpha(0.14)
        ring.wash:Show()
    elseif width > height * 2.2 then
        ring.hilight:Hide()
        ring.wash:SetPoint("TOPLEFT", widget, "TOPLEFT")
        ring.wash:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT")
        ring.wash:SetAlpha(0.22)
        ring.wash:Show()
    else
        ring.wash:Hide()
        ring.hilight:SetPoint("TOPLEFT", widget, "TOPLEFT", -4, 4)
        ring.hilight:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 4, -4)
        ring.hilight:Show()
    end
end

function GQ.Log:GamepadReveal(widget)
    local node = widget
    while node and node.GetParent do
        local parent = node:GetParent()
        if parent and parent.GetScrollChild and parent:GetScrollChild() == node and parent.GetVerticalScroll then
            local top = widget:GetTop()
            local bottom = widget:GetBottom()
            local frameTop = parent:GetTop()
            local frameBottom = parent:GetBottom()
            if not top or not bottom or not frameTop or not frameBottom then
                return
            end
            local scale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
            if scale <= 0 then
                scale = 1
            end
            local current = parent:GetVerticalScroll() or 0
            local pad = 12
            if top > frameTop - 2 then
                parent:SetVerticalScroll(math.max(0, current - ((top - frameTop) / scale) - pad))
            elseif bottom < frameBottom + 2 then
                local range = 0
                if parent.GetVerticalScrollRange then
                    range = parent:GetVerticalScrollRange() or 0
                end
                local dest = current + ((frameBottom - bottom) / scale) + pad
                if dest > range then
                    dest = range
                end
                if dest < 0 then
                    dest = 0
                end
                parent:SetVerticalScroll(dest)
            end
            return
        end
        node = parent
    end
end

function GQ.Log:GamepadOpenKeyboard(edit)
    if not edit or not edit.SetFocus then
        return
    end
    if edit.EnableKeyboard then
        pcall(edit.EnableKeyboard, edit, true)
    end
    if edit.EnableGamePadButton then
        pcall(edit.EnableGamePadButton, edit, true)
    end
    pcall(edit.SetFocus, edit)
    if edit.HighlightText then
        pcall(edit.HighlightText, edit)
    end
end

function GQ.Log:GamepadSetFocus(widget)
    local previous = self._padFocus
    if previous == widget then
        self:GamepadReveal(widget)
        return
    end
    if previous and HoverWidget(previous) then
        CallHandler(previous, "OnLeave")
    end
    if previous and ObjectType(previous) == "EditBox" and previous.ClearFocus then
        pcall(previous.ClearFocus, previous)
    end
    self._padFocus = widget
    local ring = self:GamepadEnsureRing()
    if not widget then
        ring:Hide()
        return
    end
    self:GamepadPlaceCursor(widget)
    ring:Show()
    self:GamepadReveal(widget)
    if HoverWidget(widget) then
        CallHandler(widget, "OnEnter")
    end
    if ObjectType(widget) == "EditBox" then
        self:GamepadOpenKeyboard(widget)
    end
end

function GQ.Log:GamepadPickInitial(list)
    local bubble = self:GamepadGuideBubble()
    if bubble and self:GamepadOverlay() == bubble and Usable(bubble.yes) then
        return bubble.yes
    end
    if bubble and self:GamepadOverlay() == bubble and Usable(bubble.forward) then
        return bubble.forward
    end
    local best, bestY, bestX
    local rowBest, rowY, rowX
    local preferRow = not self._padFilterMode and not self:GamepadOverlay()
        and (self.GetPageTab and self:GetPageTab() or "log") == "log"
    for i = 1, #list do
        local widget = list[i]
        if not self:GamepadIsPageTab(widget) then
            local x, y = widget:GetCenter()
            if y then
                if not best or y > bestY + 4 or (math.abs(y - bestY) <= 4 and x < bestX) then
                    best = widget
                    bestY = y
                    bestX = x
                end
                local kind = widget.rowType
                if preferRow and (kind == "item" or kind == "notable" or kind == "header") then
                    if not rowBest or y > rowY + 4 or (math.abs(y - rowY) <= 4 and x < rowX) then
                        rowBest = widget
                        rowY = y
                        rowX = x
                    end
                end
            end
        end
    end
    return rowBest or best or list[1]
end

function GQ.Log:GamepadPick(origin, direction, list)
    local ox, oy = origin:GetCenter()
    if not ox then
        return nil
    end
    local best, bestScore
    for i = 1, #list do
        local widget = list[i]
        if widget ~= origin then
            local x, y = widget:GetCenter()
            if x then
                if self:GamepadIsGuidePortrait(widget) and origin ~= (self.frame and self.frame.tabActive) then
                    x = nil
                elseif self:GamepadIsRow(origin) and self:GamepadIsListTab(widget) then
                    x = nil
                end
            end
            if x then
                local dx = x - ox
                local dy = y - oy
                local primary, secondary
                if direction == "up" then
                    primary, secondary = dy, math.abs(dx)
                elseif direction == "down" then
                    primary, secondary = -dy, math.abs(dx)
                elseif direction == "left" then
                    primary, secondary = -dx, math.abs(dy)
                else
                    primary, secondary = dx, math.abs(dy)
                end
                if primary > 6 then
                    local score = primary + (secondary * 2.2)
                    if secondary < (primary * 1.75) + 48 and (not best or score < bestScore) then
                        best = widget
                        bestScore = score
                    end
                end
            end
        end
    end
    return best
end

function GQ.Log:GamepadNudgeSlider(slider, direction)
    local value = slider:GetValue() or 0
    local step = slider.GetValueStep and slider:GetValueStep() or 1
    if not step or step <= 0 then
        step = 1
    end
    if direction == "left" then
        value = value - step
    else
        value = value + step
    end
    local minValue, maxValue
    if slider.GetMinMaxValues then
        minValue, maxValue = slider:GetMinMaxValues()
    end
    if minValue and value < minValue then
        value = minValue
    end
    if maxValue and value > maxValue then
        value = maxValue
    end
    slider:SetValue(value)
end

function GQ.Log:GamepadScrollDetail(direction)
    local frame = self.frame
    local scroll = frame and frame.detailScroll
    local page = self.GetPageTab and self:GetPageTab()
    if page == "simulator" then
        scroll = frame and frame.simScroll
    elseif page == "settings" then
        scroll = frame and frame.settingsGeneralScroll
        if self.settingsSection == "commands" then
            scroll = frame and frame.settingsCommandsScroll
        elseif self.settingsSection and self.settingsSection ~= "general" then
            scroll = nil
        end
    elseif page == "lookup" and frame and frame.lookupInset and frame.lookupInset.IsMouseOver and frame.lookupInset:IsMouseOver() then
        scroll = frame.lookupScroll
    end
    if not scroll or not scroll.IsShown or not scroll:IsShown() then
        return false
    end
    if not scroll.GetVerticalScroll or not scroll.SetVerticalScroll then
        return false
    end
    local range = 0
    if scroll.GetVerticalScrollRange then
        range = scroll:GetVerticalScrollRange() or 0
    end
    if range <= 1 then
        return false
    end
    local current = scroll:GetVerticalScroll() or 0
    local dest = current
    if direction == "up" then
        dest = current - 36
        if dest < 0 then
            dest = 0
        end
    elseif direction == "down" then
        dest = current + 36
        if dest > range then
            dest = range
        end
    else
        return false
    end
    if math.abs(dest - current) < 1 then
        return false
    end
    scroll:SetVerticalScroll(dest)
    return true
end

function GQ.Log:GamepadOrderedRows(list)
    local rows = {}
    for i = 1, #list do
        local widget = list[i]
        if self:GamepadIsRow(widget) then
            rows[#rows + 1] = widget
        end
    end
    table.sort(rows, function(a, b)
        local ax, ay = a:GetCenter()
        local bx, by = b:GetCenter()
        ay = ay or 0
        by = by or 0
        if math.abs(ay - by) > 4 then
            return ay > by
        end
        return (ax or 0) < (bx or 0)
    end)
    return rows
end

function GQ.Log:GamepadListTabs()
    local frame = self.frame
    local tabs = {}
    if not frame then
        return tabs
    end
    local widgets = { frame.tabActive, frame.tabCompleted, frame.tabRemoved }
    for i = 1, #widgets do
        if Usable(widgets[i]) then
            tabs[#tabs + 1] = widgets[i]
        end
    end
    table.sort(tabs, function(a, b)
        local ax = a:GetCenter()
        local bx = b:GetCenter()
        return (ax or 0) < (bx or 0)
    end)
    return tabs
end

-- Up and down on the hunt list stay on the hunts. The Active, Completed, and
-- Removed tabs are reached by pressing up from the top hunt, then left and
-- right. Down from a tab returns to the first hunt.
function GQ.Log:GamepadListStep(direction, focus, list)
    local page = self.GetPageTab and self:GetPageTab() or "log"
    if page ~= "log" or self._padFilterMode or self:GamepadOverlay() then
        return nil, false
    end
    local portrait = GQ.PortraitGuide and GQ.PortraitGuide.hit
    if self:GamepadIsGuidePortrait(focus) then
        if direction == "down" and self.frame and Usable(self.frame.tabActive) then
            return self.frame.tabActive, true
        end
        return focus, true
    end
    if self:GamepadIsListTab(focus) then
        local tabs = self:GamepadListTabs()
        local index
        for i = 1, #tabs do
            if tabs[i] == focus then
                index = i
                break
            end
        end
        if direction == "left" and index and index > 1 then
            return tabs[index - 1], true
        end
        if direction == "right" and index and tabs[index + 1] then
            return tabs[index + 1], true
        end
        if direction == "down" then
            local rows = self:GamepadOrderedRows(list)
            return rows[1] or focus, true
        end
        if direction == "up" or direction == "left" or direction == "right" then
            if direction == "up" and focus == self.frame.tabActive and Usable(portrait) then
                return portrait, true
            end
            return focus, true
        end
        return nil, false
    end
    if not self:GamepadIsRow(focus) or (direction ~= "up" and direction ~= "down") then
        return nil, false
    end
    local rows = self:GamepadOrderedRows(list)
    local index
    for i = 1, #rows do
        if rows[i] == focus then
            index = i
            break
        end
    end
    if not index then
        return nil, false
    end
    if direction == "down" then
        return rows[index + 1] or focus, true
    end
    if rows[index - 1] then
        return rows[index - 1], true
    end
    local tabs = self:GamepadListTabs()
    if #tabs == 0 then
        return focus, true
    end
    local rx = focus:GetCenter()
    local best, bestDx
    for i = 1, #tabs do
        local tx = tabs[i]:GetCenter()
        local dx = math.abs((tx or 0) - (rx or 0))
        if not best or dx < bestDx then
            best = tabs[i]
            bestDx = dx
        end
    end
    return best or focus, true
end

-- Up and down walk the next control in that direction. The nearest row wins,
-- and a control in the same column wins over one far to the side.
function GQ.Log:GamepadVerticalStep(direction, focus, list)
    local ox, oy = focus:GetCenter()
    if not oy then
        return nil, false
    end
    local best, bestDy, bestDx
    for i = 1, #list do
        local widget = list[i]
        if widget ~= focus then
            local x, y = widget:GetCenter()
            if y then
                local dy = (direction == "down") and (oy - y) or (y - oy)
                if dy > 4 then
                    local dx = math.abs((x or 0) - (ox or 0))
                    local nearer = not best or dy < bestDy - 4 or (math.abs(dy - bestDy) <= 4 and dx < bestDx)
                    if nearer then
                        best = widget
                        bestDy = dy
                        bestDx = dx
                    end
                end
            end
        end
    end
    if not best then
        return focus, true
    end
    return best, true
end

function GQ.Log:GamepadMove(direction)
    self._padNavAt = GetTime()
    local source = self._padMoveSource or "dpad"
    if source == "stick" then
        self._padReading = false
    elseif source == "dpad" and self._padReading and not self:GamepadOverlay()
        and (direction == "up" or direction == "down")
        and not self:GamepadIsRow(self._padFocus) and not self:GamepadIsListTab(self._padFocus) then
        if self:GamepadScrollDetail(direction) then
            return
        end
        self._padReading = false
    end
    local list = self:GamepadCandidates()
    local focus = self._padFocus
    if not focus or not self:GamepadContains(list, focus) then
        self:GamepadSetFocus(self:GamepadPickInitial(list))
        return
    end
    local kind = ObjectType(focus)
    if kind == "Slider" and (direction == "left" or direction == "right") then
        self:GamepadNudgeSlider(focus, direction)
        return
    end
    local stepped, handled = self:GamepadListStep(direction, focus, list)
    if not handled and (direction == "up" or direction == "down") then
        stepped, handled = self:GamepadVerticalStep(direction, focus, list)
    end
    if handled then
        if stepped and stepped ~= focus then
            self:GamepadSetFocus(stepped)
        end
        return
    end
    local nextWidget = self:GamepadPick(focus, direction, list)
    if nextWidget then
        self:GamepadSetFocus(nextWidget)
    end
end

function GQ.Log:GamepadPage(step)
    local guide = GQ.PortraitGuide
    if self:GamepadGuideBubble() and guide and guide.SetPage then
        guide:SetPage((guide.page or 1) + step)
        self:GamepadSyncGuide()
        return
    end
    if self:GamepadOverlay() then
        return
    end
    self._padFilterMode = false
    self._padReading = false
    local current = self:GetPageTab()
    local index = 1
    for i = 1, #PAGES do
        if PAGES[i] == current then
            index = i
            break
        end
    end
    index = index + step
    if index < 1 then
        index = #PAGES
    elseif index > #PAGES then
        index = 1
    end
    self:SetPageTab(PAGES[index])
    local list = self:GamepadCandidates()
    self:GamepadSetFocus(self:GamepadPickInitial(list))
end

function GQ.Log:GamepadActivate(widget)
    local kind = ObjectType(widget)
    if kind == "EditBox" then
        if widget.HasFocus and widget:HasFocus() then
            CallHandler(widget, "OnEnterPressed")
            if widget.ClearFocus then
                pcall(widget.ClearFocus, widget)
            end
        else
            self:GamepadOpenKeyboard(widget)
        end
        return
    end
    if kind == "Button" or kind == "CheckButton" then
        local now = GetTime()
        if self._padEngineClickWidget == widget and self._padEngineClickAt and (now - self._padEngineClickAt) < 0.2 then
            self._padEngineClickWidget = nil
            return
        end
        self._padAllowClick = true
        self._padSwallowUntil = GetTime() + 0.15
        pcall(widget.Click, widget, "LeftButton")
        self._padAllowClick = false
    end
end

function GQ.Log:GamepadConfirm()
    local widget = self._padFocus
    local list = self:GamepadCandidates()
    if not widget or not self:GamepadContains(list, widget) then
        self:GamepadSetFocus(self:GamepadPickInitial(list))
        return
    end
    local before = self:GamepadOverlay()
    local rowType = widget.rowType
    self:GamepadActivate(widget)
    if (rowType == "item" or rowType == "notable") and not before then
        self._padReading = false
        local track = self.frame and self.frame.trackBtn
        if Usable(track) then
            self:GamepadSetFocus(track)
            return
        end
    end
    local after = self:GamepadOverlay()
    if after and after ~= before then
        self._padReading = false
        local opened = {}
        Walk(after, opened, self.frame)
        self:GamepadSetFocus(self:GamepadPickInitial(opened))
        return
    end
    if widget.IsShown and not widget:IsShown() then
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
    end
end

function GQ.Log:GamepadFilters()
    if self:GamepadGuideBubble() then
        return
    end
    if not self.GetPageTab or self:GetPageTab() ~= "log" then
        return
    end
    local overlay = self:GamepadOverlay()
    local frame = self.frame
    local filterOverlay = overlay and frame and (
        overlay == frame.sourceFilterMenu or overlay == frame.playStylePanel or overlay == self.weaponMenu
    )
    if overlay and not filterOverlay and not self._padFilterMode then
        self._padReading = false
        self:GamepadBack()
        return
    end
    if filterOverlay and overlay.Hide then
        overlay:Hide()
    end
    self._padReading = false
    self._padFilterMode = not self._padFilterMode
    self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
end

function GQ.Log:GamepadBack()
    if self:GamepadGuideBubble() and GQ.PortraitGuide and GQ.PortraitGuide.Dismiss then
        GQ.PortraitGuide:Dismiss()
        return
    end
    if self.slotRankPanel and self.slotRankPanel:IsShown() and self.HideSlotRankPanel then
        self:HideSlotRankPanel()
        return
    end
    local overlay = self:GamepadOverlay()
    if overlay then
        self._padReading = false
        if overlay == self.slotRankPanel and self.HideSlotRankPanel then
            self:HideSlotRankPanel()
        elseif overlay == (self.frame and self.frame.specPicker) and self.HideSpecPicker then
            self:HideSpecPicker()
        else
            overlay:Hide()
        end
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
        return
    end
    if self._padFilterMode then
        self._padFilterMode = false
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
        return
    end
    self:Hide()
end

function GQ.Log:GamepadButton(button)
    if not self._padOn or not GQ.UsesGamepad or not GQ:UsesGamepad() then
        return
    end
    if not self._padNavOwned then
        return
    end
    local editing = self:GamepadEditFocused()
    if editing then
        local name = Canonical(button)
        local action = PadAction(name)
        if action == "back" and editing.ClearFocus then
            pcall(editing.ClearFocus, editing)
        end
        return
    end
    local name = Canonical(button)
    local action, a, b = PadAction(name)
    if not action then
        return
    end
    local key = action
    if action == "move" then
        key = "move:" .. a .. ":" .. b
    elseif action == "page" then
        key = "page:" .. tostring(a)
    elseif action == "scroll" then
        key = "scroll:" .. a
    end
    local now = GetTime()
    if key == self._padLastKey and self._padLastAt and (now - self._padLastAt) < 0.08 then
        return
    end
    self._padLastKey = key
    self._padLastAt = now
    if action ~= "move" and action ~= "scroll" then
        self._padSwallowUntil = now + 0.15
    end
    if action == "move" then
        self._padSwallowUntil = now + 0.05
        self._padMoveSource = b
        self._padRepeatKind = "move"
        self._padRepeatDir = a
        self._padRepeatSource = b
        self._padRepeatAt = now + 0.34
        self:GamepadMove(a)
        return
    end
    self._padRepeatKind = nil
    self._padRepeatDir = nil
    if action == "scroll" then
        self._padRepeatKind = "scroll"
        self._padRepeatDir = a
        self._padRepeatAt = now + 0.34
        self:GamepadScrollDetail(a)
    elseif action == "page" then
        self:GamepadPage(a)
    elseif action == "confirm" then
        self:GamepadConfirm()
    elseif action == "back" then
        self:GamepadBack()
    elseif action == "filters" then
        self:GamepadFilters()
    end
end

function GQ.Log:GamepadEditFocused()
    local widget = self._padFocus
    if widget and ObjectType(widget) == "EditBox" and widget.HasFocus and widget:HasFocus() then
        return widget
    end
end

function GQ.Log:GamepadReadButtons()
    local down = {}
    local saw = false
    local function ingest(api, shouldersOnly)
        if not api then
            return
        end
        local ok, state = pcall(api)
        if not ok or type(state) ~= "table" or type(state.buttons) ~= "table" then
            return
        end
        saw = true
        local base = TableBase(state.buttons)
        for index, pressed in pairs(state.buttons) do
            if pressed then
                local name = NameFor(index, base)
                local shoulder = name and (name:find("SHOULDER", 1, true) or name:find("BUMPER", 1, true))
                if name and (not shouldersOnly or shoulder) and not down[name] then
                    down[name] = true
                end
            end
        end
    end
    if C_GamePad then
        ingest(C_GamePad.GetDeviceMappedState, false)
        -- The left bumper emulates Ctrl and is often missing from the mapped
        -- state. The raw state still has it. Face buttons and the d-pad stay
        -- on the mapped names, so one press cannot also confirm or close.
        ingest(C_GamePad.GetDeviceRawState, true)
    end
    if not saw then
        return nil
    end
    self._padDown = down
    return down
end

function GQ.Log:GamepadPollEdges()
    local down = self:GamepadReadButtons()
    if not down then
        return
    end
    local was = self._padWasDown or {}
    self._padWasDown = down
    for name in pairs(down) do
        if not was[name] then
            self:GamepadButton(name)
        end
    end
end

function GQ.Log:GamepadHeld(names)
    local down = self:GamepadReadButtons()
    if not down or not names then
        return false
    end
    for name in pairs(down) do
        if names[name] then
            return true
        end
    end
    return false
end

local CHIP_COLOR = {
    A = { 0.12, 0.62, 0.18 },
    B = { 0.72, 0.14, 0.14 },
    X = { 0.18, 0.38, 0.82 },
    Y = { 0.82, 0.68, 0.12 },
}

local CHIP_ATLAS = {
    A = { "Gamepad_Gen_A", "Gamepad_A" },
    B = { "Gamepad_Gen_B", "Gamepad_B" },
    X = { "Gamepad_Gen_X", "Gamepad_X" },
    Y = { "Gamepad_Gen_Y", "Gamepad_Y" },
    LB = { "Gamepad_Gen_L_Bumper", "Gamepad_L_Bumper", "Gamepad_LB" },
    RB = { "Gamepad_Gen_R_Bumper", "Gamepad_R_Bumper", "Gamepad_RB" },
    NAV = {
        "Gamepad_Gen_Dpad",
        "Gamepad_Gen_DPad",
        "Gamepad_Gen_Dpad_64",
        "Gamepad_Gen_DPad_64",
        "Gamepad_Gen_Dpad_All",
        "Gamepad_Gen_Navigate",
        "Gamepad_Gen_Move",
        "Gamepad_Dpad",
    },
}

local function AtlasOn(tex, key)
    local names = CHIP_ATLAS[key]
    if not names or not tex or not tex.SetAtlas or not C_Texture or not C_Texture.GetAtlasInfo then
        return false
    end
    for i = 1, #names do
        local ok, info = pcall(C_Texture.GetAtlasInfo, names[i])
        if ok and info then
            tex:SetAtlas(names[i])
            return true
        end
    end
    return false
end

function GQ.Log:GamepadIsOurFrame(widget)
    local frame = self.frame
    if not widget or not frame then
        return false
    end
    local node = widget
    while node do
        if node == frame or node == frame.sideTabRail or node == self.weaponMenu
            or node == frame.sourceFilterMenu or node == frame.playStylePanel
            or node == frame.specPicker then
            return true
        end
        node = node.GetParent and node:GetParent()
    end
    return false
end

local FOREIGN_KEYS = { "currentFrame", "focusedFrame", "activeFrame", "focusFrame", "currentButton", "selectedButton", "activeButton" }

local BLIZZARD_WINDOWS = {
    "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "QuestFrame", "QuestLogFrame",
    "QuestLogPopupDetailFrame", "MerchantFrame", "GossipFrame", "GameMenuFrame", "SettingsPanel",
    "WorldMapFrame", "CollectionsJournal", "FriendsFrame", "CommunitiesFrame", "LootFrame",
    "BankFrame", "TaxiFrame", "ClassTrainerFrame", "TradeFrame", "AuctionFrame", "AuctionHouseFrame",
    "MailFrame", "OpenMailFrame", "PlayerTalentFrame", "TalentFrame", "PVPFrame", "PVEFrame",
    "InspectFrame", "DressUpFrame", "ItemTextFrame", "GuildBankFrame", "TradeSkillFrame", "CraftFrame",
    "MacroFrame", "AddonList", "InterfaceOptionsFrame", "VideoOptionsFrame", "HelpFrame",
    "PetStableFrame", "TabardFrame", "BattlefieldFrame", "LFDParentFrame", "AchievementFrame",
    "CalendarFrame", "EncounterJournal", "ProfessionsFrame", "ContainerFrameCombinedBags",
    "ContainerFrame1", "ContainerFrame2", "ContainerFrame3", "ContainerFrame4", "ContainerFrame5",
    "ReadyCheckFrame", "StaticPopup1",
}

local function WindowVisible(frame)
    if not frame or not frame.IsVisible then
        return false
    end
    local ok, visible = pcall(frame.IsVisible, frame)
    return ok and visible or false
end

local function ShownFrame(widget)
    if not widget or widget == UIParent or widget == WorldFrame then
        return nil
    end
    if not widget.GetObjectType or not widget.IsShown or not widget:IsShown() then
        return nil
    end
    return widget
end

-- Read only. Calling FrameControlsManager or SmartNavigation methods changes the
-- binding stack and can freeze the controller.
function GQ.Log:GamepadForeignWidget(widget)
    widget = ShownFrame(widget)
    if not widget or self:GamepadIsOurFrame(widget) then
        return nil
    end
    local node = widget
    while node and node.GetParent do
        if node == UIParent or node == WorldFrame then
            break
        end
        if self:GamepadIsOurFrame(node) then
            return nil
        end
        node = node:GetParent()
    end
    return widget
end

function GQ.Log:GamepadReadFocusTable(mgr)
    if type(mgr) ~= "table" then
        return nil
    end
    for i = 1, #FOREIGN_KEYS do
        local found = self:GamepadForeignWidget(mgr[FOREIGN_KEYS[i]])
        if found then
            return found
        end
    end
    return nil
end

function GQ.Log:GamepadCursorTarget(region)
    if not region or not region.GetObjectType or region:GetObjectType() ~= "Texture" then
        return nil
    end
    if not region.IsShown or not region:IsShown() or not region.GetPoint then
        return nil
    end
    local width = region.GetWidth and region:GetWidth() or 0
    if width < 8 or width > 96 then
        return nil
    end
    local _, target = region:GetPoint(1)
    return self:GamepadForeignWidget(target)
end

function GQ.Log:GamepadScanCursor(frame, depth)
    if not frame or not frame.GetRegions or depth > 2 then
        return nil
    end
    if frame.IsShown and not frame:IsShown() then
        return nil
    end
    local regions = { frame:GetRegions() }
    for i = 1, #regions do
        local found = self:GamepadCursorTarget(regions[i])
        if found then
            return found
        end
    end
    if depth < 2 and frame.GetChildren then
        local kids = { frame:GetChildren() }
        for i = 1, #kids do
            local found = self:GamepadScanCursor(kids[i], depth + 1)
            if found then
                return found
            end
        end
    end
    return nil
end

function GQ.Log:GamepadForeignFrame()
    local mode = _G.GamepadMode
    local found = self:GamepadReadFocusTable(mode and mode.FrameControlsManager)
    if found then
        return found
    end
    found = self:GamepadReadFocusTable(_G.FrameControlsManager)
    if found then
        return found
    end
    local nav = _G.SmartNavigation
    found = self:GamepadReadFocusTable(nav)
    if found then
        return found
    end
    if nav then
        found = self:GamepadReadFocusTable(nav.frameControlsManager or nav.FrameControlsManager)
        if found then
            return found
        end
        found = self:GamepadScanCursor(nav, 0)
        if found then
            return found
        end
    end
    local cursor = _G.SmartNavigationCursor
    if cursor then
        found = self:GamepadScanCursor(cursor, 0) or self:GamepadForeignWidget(cursor)
        if found then
            return found
        end
    end
    return nil
end

function GQ.Log:GamepadPointerFrame()
    local focus
    if GetMouseFocus then
        focus = GetMouseFocus()
    end
    if (not focus) and GetMouseFoci then
        local foci = GetMouseFoci()
        focus = foci and foci[1]
    end
    return focus
end

function GQ.Log:GamepadForeignPanel()
    local mode = _G.GamepadMode
    local sources = {
        mode and mode.FrameControlsManager,
        _G.FrameControlsManager,
        _G.SmartNavigation,
    }
    local nav = _G.SmartNavigation
    if nav then
        sources[#sources + 1] = nav.frameControlsManager or nav.FrameControlsManager
    end
    for i = 1, #sources do
        local mgr = sources[i]
        if type(mgr) == "table" then
            for k = 1, #FOREIGN_KEYS do
                local widget = mgr[FOREIGN_KEYS[k]]
                if WindowVisible(widget) and not self:GamepadIsOurFrame(widget) then
                    return widget
                end
            end
        end
    end
    return nil
end

function GQ.Log:GamepadPanelRoot(widget)
    local node = widget
    while node and node.GetParent do
        local parent = node:GetParent()
        if not parent or parent == UIParent or parent == WorldFrame then
            return node
        end
        node = parent
    end
    return widget
end

function GQ.Log:GamepadNoteBlizzard()
    local shown = {}
    for i = 1, #BLIZZARD_WINDOWS do
        local name = BLIZZARD_WINDOWS[i]
        if WindowVisible(_G[name]) then
            shown[name] = true
        end
    end
    self._padBlizzShown = shown
end

function GQ.Log:GamepadBlizzardOpened()
    local prev = self._padBlizzShown
    if not prev then
        self:GamepadNoteBlizzard()
        return false
    end
    local opened = false
    local shown = {}
    for i = 1, #BLIZZARD_WINDOWS do
        local name = BLIZZARD_WINDOWS[i]
        if WindowVisible(_G[name]) then
            shown[name] = true
            if not prev[name] then
                opened = true
            end
        end
    end
    self._padBlizzShown = shown
    return opened
end

function GQ.Log:GamepadDropFocus()
    self._padPreferUs = false
    self._padNavOwned = false
    self._padRepeatKind = nil
    self._padRepeatDir = nil
end

function GQ.Log:GamepadClaim()
    if not self._padOn then
        return
    end
    local hidden = not self._padNavOwned
    self._padNavOwned = true
    self._padPreferUs = true
    self._padHoldForeign = nil
    self._padForeign = self:GamepadForeignPanel()
    self:GamepadNoteBlizzard()
    if hidden then
        local list = self:GamepadCandidates()
        local focus = self._padFocus
        if not self:GamepadFocusVisible(focus) or not self:GamepadContains(list, focus) then
            self:GamepadSetFocus(self:GamepadPickInitial(list))
        end
    end
    self:GamepadUpdateChrome()
end

function GQ.Log:GamepadHookClaim(widget)
    if not widget or widget._gqPadClaimHook or not widget.HookScript then
        return
    end
    widget._gqPadClaimHook = true
    widget:HookScript("OnMouseDown", function()
        if GQ.Log and GQ.Log.GamepadClaim then
            GQ.Log:GamepadClaim()
        end
    end)
end

function GQ.Log:GamepadSyncOwnership()
    if self._padPreferUs and self:GamepadBlizzardOpened() then
        self:GamepadDropFocus()
    end
    local foreign = self:GamepadForeignPanel()
    local foreignRoot = foreign and self:GamepadPanelRoot(foreign)
    local ownedRoot = self._padForeign and self:GamepadPanelRoot(self._padForeign)
    if self._padHoldForeign then
        self._padHoldForeign = nil
        self._padForeign = foreign
        self._padPreferUs = true
        self._padNavOwned = true
    elseif self._padPreferUs then
        if foreignRoot and foreignRoot ~= ownedRoot then
            self:GamepadDropFocus()
        else
            self._padNavOwned = true
        end
        self._padForeign = foreign
    else
        self._padForeign = foreign
        self._padNavOwned = false
    end
    if IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then
        local focus = self:GamepadPointerFrame()
        if focus and focus ~= WorldFrame and focus ~= UIParent then
            if self:GamepadIsOurFrame(focus) then
                if not self._padNavOwned then
                    self:GamepadClaim()
                end
            elseif self._padNavOwned then
                self:GamepadDropFocus()
                self._padForeign = foreign
            end
        end
    end
end

function GQ.Log:GamepadFollowClick(widget)
    if not self._padOn or not widget then
        return
    end
    if not self:GamepadIsOurFrame(widget) then
        return
    end
    self._padNavOwned = true
    self._padPreferUs = true
    local target = widget
    if not Usable(target) then
        local parent = target.GetParent and target:GetParent()
        if parent and Usable(parent) then
            target = parent
        end
    end
    local overlay = self:GamepadOverlay()
    if overlay and target then
        local inside = false
        local node = target
        while node do
            if node == overlay then
                inside = true
                break
            end
            node = node.GetParent and node:GetParent()
        end
        if not inside then
            target = self:GamepadPickInitial(self:GamepadCandidates())
        end
    end
    if not Usable(target) then
        target = self:GamepadPickInitial(self:GamepadCandidates())
    end
    if target and (target.rowType == "item" or target.rowType == "notable") then
        self._padFilterMode = false
        self._padReading = true
    elseif target and target.rowType == "header" then
        self._padFilterMode = false
        self._padReading = false
    end
    if Usable(target) then
        self:GamepadSetFocus(target)
    end
    self:GamepadUpdateChrome()
end

function GQ.Log:GamepadStyleChip(chip, key)
    if chip.dpad then
        chip.dpad:Hide()
    end
    if AtlasOn(chip.icon, key) then
        chip.icon:Show()
        chip.letter:Hide()
        if chip.SetBackdrop then
            chip:SetBackdrop(nil)
        end
        return
    end
    if key == "NAV" then
        chip.icon:Hide()
        chip.letter:Hide()
        if chip.SetBackdrop then
            chip:SetBackdrop(nil)
        end
        if not chip.dpad then
            local dpad = CreateFrame("Frame", nil, chip)
            dpad:SetAllPoints()
            local function mark(w, h, x, y)
                local tex = dpad:CreateTexture(nil, "OVERLAY")
                tex:SetColorTexture(0.93, 0.91, 0.84, 1)
                tex:SetSize(w, h)
                tex:SetPoint("CENTER", dpad, "CENTER", x, y)
            end
            mark(3, 14, 0, 0)
            mark(14, 3, 0, 0)
            mark(7, 3, 0, 6)
            mark(7, 3, 0, -6)
            mark(3, 7, 6, 0)
            mark(3, 7, -6, 0)
            chip.dpad = dpad
        end
        chip.dpad:Show()
        return
    end
    chip.icon:Hide()
    chip.letter:SetText(key)
    chip.letter:Show()
    local color = CHIP_COLOR[key] or { 0.15, 0.15, 0.15 }
    if chip.SetBackdrop then
        chip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        chip:SetBackdropColor(color[1], color[2], color[3], 1)
        chip:SetBackdropBorderColor(0.04, 0.03, 0.02, 1)
    end
end

function GQ.Log:GamepadCreateChip(bar)
    local chip = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    chip:SetSize(20, 20)
    chip:EnableMouse(false)
    local icon = chip:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:Hide()
    chip.icon = icon
    local letter = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    letter:SetPoint("CENTER", 0, 0)
    chip.letter = letter
    local label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetTextColor(1, 1, 1)
    chip.label = label
    return chip
end

function GQ.Log:GamepadCreateBar()
    local bar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    bar:Hide()
    bar:EnableMouse(false)
    bar:SetFrameStrata("FULLSCREEN_DIALOG")
    bar:SetFrameLevel(80)
    if bar.SetClampedToScreen then
        bar:SetClampedToScreen(true)
    end
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bar:SetBackdropColor(0.04, 0.03, 0.02, 0.92)
    bar:SetBackdropBorderColor(0.72, 0.58, 0.24, 0.95)
    bar:SetSize(180, 28)
    bar.chips = {}
    for i = 1, 4 do
        bar.chips[i] = self:GamepadCreateChip(bar)
        bar.chips[i]:Hide()
    end
    return bar
end

function GQ.Log:GamepadCreateBumper(parent, key)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(36, 18)
    badge:EnableMouse(false)
    badge:Hide()
    badge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    badge:SetBackdropColor(0.06, 0.05, 0.04, 0.95)
    badge:SetBackdropBorderColor(0.86, 0.7, 0.28, 1)
    local icon = badge:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 18)
    icon:SetPoint("CENTER")
    if AtlasOn(icon, key) then
        badge:SetBackdrop(nil)
        badge:SetSize(32, 20)
    else
        icon:Hide()
        local letter = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        letter:SetPoint("CENTER", 0, 0)
        letter:SetText(key)
        letter:SetTextColor(1, 0.95, 0.8)
    end
    return badge
end

function GQ.Log:GamepadEnsureHints()
    if not self._padHintBar then
        self._padHintBar = self:GamepadCreateBar()
        self._padMenuBar = self:GamepadCreateBar()
    end
    local rail = self.frame and self.frame.sideTabRail
    if rail and not self._padLb then
        self._padLb = self:GamepadCreateBumper(rail, "LB")
        self._padRb = self:GamepadCreateBumper(rail, "RB")
        self._padLb:SetPoint("BOTTOM", rail, "TOP", 0, 4)
        self._padRb:SetPoint("TOP", rail, "BOTTOM", 0, -4)
    end
end

function GQ.Log:GamepadHintPrompts(menu)
    if menu then
        return {
            { key = "A", text = "Select" },
            { key = "NAV", text = "Navigate" },
            { key = "B", text = "Close" },
        }
    end
    local prompts = {
        { key = "A", text = "Select" },
    }
    if self.GetPageTab and self:GetPageTab() == "log" and not self._padFilterMode then
        prompts[#prompts + 1] = { key = "Y", text = "Filters" }
    end
    prompts[#prompts + 1] = { key = "NAV", text = "Navigate" }
    local back = "Close"
    if self._padFilterMode then
        back = "Back"
    end
    prompts[#prompts + 1] = { key = "B", text = back }
    return prompts
end

function GQ.Log:GamepadFillBar(bar, prompts)
    local x = 8
    for i = 1, #bar.chips do
        local chip = bar.chips[i]
        local prompt = prompts[i]
        if prompt then
            self:GamepadStyleChip(chip, prompt.key)
            chip:ClearAllPoints()
            chip:SetPoint("LEFT", bar, "LEFT", x, 0)
            chip:Show()
            chip.label:SetText(L[prompt.text])
            chip.label:ClearAllPoints()
            chip.label:SetPoint("LEFT", chip, "RIGHT", 4, 0)
            chip.label:Show()
            local textWidth = chip.label:GetStringWidth() or 0
            if textWidth < 8 then
                textWidth = #(prompt.text or "") * 6
            end
            x = x + 20 + 4 + textWidth + 14
        else
            chip:Hide()
            if chip.label then
                chip.label:Hide()
            end
        end
    end
    if x < 48 then
        x = 48
    end
    bar:SetWidth(x + 4)
end

local GLOW_THICK = 14

local function GlowArt(file)
    local addon = GQ.ADDON_NAME or "GearQuestForever"
    return "Interface\\AddOns\\" .. addon .. "\\Art\\" .. file
end

local function MakeGlowTexture(parent, file)
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(GlowArt(file))
    tex:SetBlendMode("ADD")
    tex:Hide()
    return tex
end

function GQ.Log:GamepadEnsureFocusGlow()
    local frame = self.frame
    if not frame then
        return nil
    end
    local glow = frame.gqPadFocusGlow
    if glow and not glow.gqGlowSeam then
        glow:Hide()
        frame.gqPadFocusGlow = nil
        glow = nil
    end
    if glow and glow.gqGlowSeam then
        return glow
    end
    glow = CreateFrame("Frame", nil, UIParent)
    glow.gqGlowSoft = true
    glow.gqGlowJoined = true
    glow.gqGlowSeam = true
    glow:EnableMouse(false)
    if glow.SetClipsChildren then
        glow:SetClipsChildren(false)
    end
    glow.edgeTop = MakeGlowTexture(glow, "GQ-FocusGlow.png")
    glow.edgeBottom = MakeGlowTexture(glow, "GQ-FocusGlow.png")
    glow.edgeLeft = MakeGlowTexture(glow, "GQ-FocusGlow.png")
    glow.edgeRight = MakeGlowTexture(glow, "GQ-FocusGlow.png")
    glow.cornerTR = MakeGlowTexture(glow, "GQ-FocusGlowCorner.png")
    glow.cornerBL = MakeGlowTexture(glow, "GQ-FocusGlowCorner.png")
    glow.cornerBR = MakeGlowTexture(glow, "GQ-FocusGlowCorner.png")
    glow.ring = MakeGlowTexture(glow, "GQ-FocusGlowArc2.png")
    glow.cornerTL = MakeGlowTexture(glow, "GQ-FocusGlowCornerTL.png")
    glow.edgeJoinTop = MakeGlowTexture(glow, "GQ-FocusGlowJoin.png")
    glow.edgeJoinLeft = MakeGlowTexture(glow, "GQ-FocusGlowJoin.png")
    -- Fade runs across the texture. Bright side stays against the frame.
    glow.edgeTop:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    glow.edgeBottom:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    glow.edgeRight:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    glow.edgeLeft:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerTR:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerBL:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
    glow.cornerBR:SetTexCoord(1, 1, 1, 0, 0, 1, 0, 0)
    glow.edgeJoinTop:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
    glow.edgeJoinLeft:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
    glow:Hide()
    frame.gqPadFocusGlow = glow
    return glow
end

function GQ.Log:GamepadLayoutFocusGlow()
    local frame = self.frame
    local glow = self:GamepadEnsureFocusGlow()
    if not frame or not glow then
        return
    end
    local strata = frame.GetFrameStrata and frame:GetFrameStrata() or "DIALOG"
    glow:SetFrameStrata(strata)
    glow:SetFrameLevel((frame:GetFrameLevel() or 1) + 4)
    local thick = GLOW_THICK
    local overlap = 2
    local fadeStart = 62
    local fadeEnd = 80
    local cornerPad = 48
    local cornerSide = 128

    local top = glow.edgeTop
    top:ClearAllPoints()
    top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", fadeEnd - 4, -overlap)
    top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -overlap, -overlap)
    top:SetHeight(thick)
    top:Show()

    local joinTop = glow.edgeJoinTop
    joinTop:ClearAllPoints()
    joinTop:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", fadeStart, -overlap)
    joinTop:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", fadeEnd, -overlap)
    joinTop:SetHeight(thick)
    joinTop:Show()

    local bottom = glow.edgeBottom
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", overlap, overlap)
    bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -overlap, overlap)
    bottom:SetHeight(thick)
    bottom:Show()

    local left = glow.edgeLeft
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", frame, "TOPLEFT", overlap, -(fadeEnd - 4))
    left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", overlap, overlap)
    left:SetWidth(thick)
    left:Show()

    local joinLeft = glow.edgeJoinLeft
    joinLeft:ClearAllPoints()
    joinLeft:SetPoint("TOPRIGHT", frame, "TOPLEFT", overlap, -fadeStart)
    joinLeft:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", overlap, -fadeEnd)
    joinLeft:SetWidth(thick)
    joinLeft:Show()

    local right = glow.edgeRight
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", frame, "TOPRIGHT", -overlap, -overlap)
    right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -overlap, overlap)
    right:SetWidth(thick)
    right:Show()

    local tr = glow.cornerTR
    tr:ClearAllPoints()
    tr:SetSize(thick, thick)
    tr:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", -overlap, -overlap)
    tr:Show()

    local bl = glow.cornerBL
    bl:ClearAllPoints()
    bl:SetSize(thick, thick)
    bl:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", overlap, overlap)
    bl:Show()

    local br = glow.cornerBR
    br:ClearAllPoints()
    br:SetSize(thick, thick)
    br:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT", -overlap, overlap)
    br:Show()

    local ring = glow.ring
    if ring then
        ring:Hide()
    end
    local corner = glow.cornerTL
    corner:ClearAllPoints()
    corner:SetPoint("TOPLEFT", frame, "TOPLEFT", -cornerPad, cornerPad)
    corner:SetSize(cornerSide, cornerSide)
    corner:Show()
end

local NINE_EDGE = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

function GQ.Log:GamepadPanelRoot(widget)
    local node = widget
    local root = widget
    while node and node.GetParent do
        local parent = node:GetParent()
        if not parent or parent == UIParent or parent == WorldFrame then
            root = node
            break
        end
        node = parent
    end
    return root
end

function GQ.Log:GamepadRestoreForeign()
    local list = self._padMuted
    if not list then
        return
    end
    for i = 1, #list do
        local widget = list[i]
        if widget then
            if widget._gqPadR and widget.SetVertexColor then
                pcall(widget.SetVertexColor, widget, widget._gqPadR, widget._gqPadG, widget._gqPadB, widget._gqPadA or 1)
            end
            if widget._gqPadWasShown and widget.Show then
                pcall(widget.Show, widget)
            end
            if widget._gqPadAlpha and widget.SetAlpha then
                pcall(widget.SetAlpha, widget, widget._gqPadAlpha)
            end
            widget._gqPadMuted = nil
            widget._gqPadFaded = nil
            widget._gqPadR = nil
            widget._gqPadG = nil
            widget._gqPadB = nil
            widget._gqPadA = nil
            widget._gqPadAlpha = nil
            widget._gqPadWasShown = nil
        end
    end
    self._padMuted = nil
end

function GQ.Log:GamepadDimTexture(tex)
    if not tex or not tex.SetVertexColor then
        return
    end
    if not tex._gqPadMuted then
        tex._gqPadMuted = true
        if tex.GetVertexColor then
            local r, g, b, a = tex:GetVertexColor()
            tex._gqPadR, tex._gqPadG, tex._gqPadB, tex._gqPadA = r, g, b, a or 1
        end
        self._padMuted = self._padMuted or {}
        self._padMuted[#self._padMuted + 1] = tex
    end
    pcall(tex.SetVertexColor, tex, 0.58, 0.52, 0.4)
end

local function SafeName(widget)
    if not widget or not widget.GetName then
        return ""
    end
    local ok, name = pcall(widget.GetName, widget)
    if not ok or type(name) ~= "string" then
        return ""
    end
    return name:lower()
end

function GQ.Log:GamepadSuppressForeignCursor()
    if not self._padNavOwned or self._padSuppressing then
        return
    end
    self._padSuppressing = true
    local function walk(frame, depth)
        if not frame or depth > 3 then
            return
        end
        local okRegions, regions = pcall(function()
            if not frame.GetRegions then
                return nil
            end
            return { frame:GetRegions() }
        end)
        if okRegions and regions then
            for i = 1, #regions do
                local region = regions[i]
                local shown = false
                pcall(function()
                    shown = region and region.GetObjectType and region:GetObjectType() == "Texture" and region.IsShown and region:IsShown()
                end)
                if shown then
                    local name = SafeName(region)
                    local width, height = 0, 0
                    pcall(function()
                        width = region:GetWidth() or 0
                        height = region:GetHeight() or 0
                    end)
                    local square = depth <= 1 and width >= 16 and width <= 80 and height >= 16 and height <= 80
                    if name:find("cursor", 1, true) or name:find("arrow", 1, true) or square then
                        self:GamepadHideTexture(region)
                    end
                end
            end
        end
        if depth < 3 then
            local okKids, kids = pcall(function()
                if not frame.GetChildren then
                    return nil
                end
                return { frame:GetChildren() }
            end)
            if okKids and kids then
                for i = 1, #kids do
                    local kid = kids[i]
                    local name = SafeName(kid)
                    if name:find("cursor", 1, true) or name:find("arrow", 1, true) then
                        self:GamepadFadeWidget(kid)
                    end
                    walk(kid, depth + 1)
                end
            end
        end
    end
    local nav = _G.SmartNavigation
    if nav then
        walk(nav, 0)
        if not nav._gqPadCursorHook and nav.HookScript then
            nav._gqPadCursorHook = true
            pcall(nav.HookScript, nav, "OnUpdate", function()
                local log = GQ.Log
                if log and log._padNavOwned and log.GamepadSuppressForeignCursor then
                    log:GamepadSuppressForeignCursor()
                end
            end)
        end
    end
    local named = _G.SmartNavigationCursor or _G.GamepadCursor
    if named then
        walk(named, 0)
    end
    self._padSuppressing = false
end

function GQ.Log:GamepadHideTexture(tex)
    if not tex or not tex.Hide then
        return
    end
    if not tex._gqPadMuted then
        if not tex.IsShown or not tex:IsShown() then
            return
        end
        tex._gqPadMuted = true
        tex._gqPadWasShown = true
        self._padMuted = self._padMuted or {}
        self._padMuted[#self._padMuted + 1] = tex
    end
    if tex._gqPadWasShown then
        pcall(tex.Hide, tex)
    end
end

function GQ.Log:GamepadDimNineSlice(owner)
    local ns = owner and (owner.NineSlice or owner)
    if not ns then
        return
    end
    for i = 1, #NINE_EDGE do
        self:GamepadDimTexture(ns[NINE_EDGE[i]])
    end
end

function GQ.Log:GamepadFadeWidget(widget)
    if not widget or not widget.SetAlpha then
        return
    end
    if not widget._gqPadFaded then
        widget._gqPadFaded = true
        widget._gqPadMuted = true
        if widget.GetAlpha then
            widget._gqPadAlpha = widget:GetAlpha()
        end
        self._padMuted = self._padMuted or {}
        self._padMuted[#self._padMuted + 1] = widget
    end
    pcall(widget.SetAlpha, widget, 0)
end

function GQ.Log:GamepadTextureOnEdge(tex, root)
    if not tex or not tex.GetObjectType or tex:GetObjectType() ~= "Texture" then
        return false
    end
    if not tex.IsShown or not tex:IsShown() then
        return false
    end
    local width = tex.GetWidth and tex:GetWidth() or 0
    local height = tex.GetHeight and tex:GetHeight() or 0
    local rootWidth = root.GetWidth and root:GetWidth() or 0
    local rootHeight = root.GetHeight and root:GetHeight() or 0
    if width < 28 or height < 28 or rootWidth < 40 or rootHeight < 40 then
        return false
    end
    if width > rootWidth * 0.85 and height > rootHeight * 0.85 then
        return false
    end
    local top, bottom = tex:GetTop(), tex:GetBottom()
    local left, right = tex:GetLeft(), tex:GetRight()
    local rootTop, rootBottom = root:GetTop(), root:GetBottom()
    local rootLeft, rootRight = root:GetLeft(), root:GetRight()
    if not top or not rootTop or not left or not rootLeft then
        return false
    end
    local pad = 40
    return math.abs(top - rootTop) < pad or math.abs(bottom - rootBottom) < pad
        or math.abs(left - rootLeft) < pad or math.abs(right - rootRight) < pad
end

function GQ.Log:GamepadMuteOwner(owner)
    if not owner then
        return
    end
    self:GamepadDimNineSlice(owner)
    local fadeKey = {
        FocusBorder = true, focusBorder = true, FocusGlow = true, focusGlow = true,
        HighlightBorder = true, GoldGlow = true, SelectedHighlight = true,
    }
    for key in pairs(fadeKey) do
        if owner[key] then
            self:GamepadFadeWidget(owner[key])
        end
    end
    if not owner.GetRegions then
        return
    end
    local regions = { owner:GetRegions() }
    for i = 1, #regions do
        local tex = regions[i]
        if self:GamepadTextureOnEdge(tex, owner) then
            local name = (tex.GetName and tex:GetName()) or ""
            local blend = tex.GetBlendMode and tex:GetBlendMode()
            if blend == "ADD" or name:find("Focus") or name:find("Glow") or name:find("Highlight") then
                self:GamepadFadeWidget(tex)
            else
                self:GamepadDimTexture(tex)
            end
        end
    end
end

-- SetUIFocusState and FrameHidden change the binding stack from addon code and
-- freeze the controller until /reload. While GearQuest is the window in use,
-- the other window's focus stroke is faded and its border is dulled.
function GQ.Log:GamepadApplyMute(root)
    if not root then
        return
    end
    self:GamepadMuteOwner(root)
    self:GamepadMuteOwner(root.NineSlice)
    if root.GetChildren then
        local kids = { root:GetChildren() }
        local rootWidth = root:GetWidth() or 0
        for i = 1, #kids do
            local kid = kids[i]
            local name = (kid.GetName and kid:GetName()) or ""
            if name:find("Focus") or name:find("Glow") or name:find("Highlight") then
                self:GamepadFadeWidget(kid)
            elseif kid.GetWidth and (kid:GetWidth() or 0) > rootWidth * 0.7 then
                self:GamepadMuteOwner(kid)
                self:GamepadMuteOwner(kid.NineSlice)
            end
        end
    end
    local nav = _G.SmartNavigation
    if nav and nav.GetRegions then
        local function hideCursor(frame, depth)
            if not frame or depth > 2 or not frame.GetRegions then
                return
            end
            local regions = { frame:GetRegions() }
            for i = 1, #regions do
                local region = regions[i]
                if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.GetPoint and region.IsShown and region:IsShown() then
                    local _, target = region:GetPoint(1)
                    if target and (target == root or self:GamepadPanelRoot(target) == root) then
                        self:GamepadHideTexture(region)
                    end
                end
            end
            if depth < 2 and frame.GetChildren then
                local kids = { frame:GetChildren() }
                for i = 1, #kids do
                    hideCursor(kids[i], depth + 1)
                end
            end
        end
        hideCursor(nav, 0)
    end
end

function GQ.Log:GamepadMuteForeign(foreign)
    if not foreign or not self._padNavOwned then
        self:GamepadRestoreForeign()
        self._padMutedRoot = nil
        return
    end
    local root = self:GamepadPanelRoot(foreign)
    if not root or self:GamepadIsOurFrame(root) then
        self:GamepadRestoreForeign()
        self._padMutedRoot = nil
        return
    end
    if self._padMutedRoot ~= root then
        self:GamepadRestoreForeign()
        self._padMutedRoot = root
    end
    self:GamepadApplyMute(root)
    if not root._gqPadMuteHook and root.HookScript then
        root._gqPadMuteHook = true
        pcall(root.HookScript, root, "OnUpdate", function(frame)
            local log = GQ.Log
            if log and log._padNavOwned and log._padMutedRoot == frame and log.GamepadApplyMute then
                log:GamepadApplyMute(frame)
            end
        end)
    end
end

function GQ.Log:GamepadUpdateChrome()
    if not self.frame then
        return
    end
    self:GamepadEnsureHints()
    local show = self._padOn and self._padNavOwned and self.frame:IsShown()
    local overlay = show and self:GamepadOverlay() or nil
    if self._padRing then
        if show and self:GamepadFocusVisible(self._padFocus) then
            self:GamepadPlaceCursor(self._padFocus)
            self._padRing:Show()
        else
            self._padRing:Hide()
        end
    end
    if self._padLb then
        if show then
            self._padLb:Show()
        else
            self._padLb:Hide()
        end
    end
    if self._padRb then
        if show then
            self._padRb:Show()
        else
            self._padRb:Hide()
        end
    end
    local windowBar = self._padHintBar
    if windowBar then
        if show and not overlay then
            windowBar:ClearAllPoints()
            windowBar:SetPoint("TOP", self.frame, "BOTTOM", 0, 8)
            self:GamepadFillBar(windowBar, self:GamepadHintPrompts(false))
            windowBar:Show()
        else
            windowBar:Hide()
        end
    end
    local menuBar = self._padMenuBar
    if menuBar then
        if overlay then
            menuBar:ClearAllPoints()
            menuBar:SetPoint("TOP", overlay, "BOTTOM", 0, 2)
            menuBar:SetFrameStrata("TOOLTIP")
            menuBar:SetFrameLevel(400)
            self:GamepadFillBar(menuBar, self:GamepadHintPrompts(true))
            menuBar:Show()
        else
            menuBar:Hide()
        end
    end
    local glow = self:GamepadEnsureFocusGlow()
    if glow then
        if show then
            self:GamepadLayoutFocusGlow()
            glow:Show()
        else
            glow:Hide()
        end
    end
    if show then
        self:GamepadSuppressForeignCursor()
    else
        self:GamepadRestoreForeign()
        self._padMutedRoot = nil
    end
end

function GQ.Log:GamepadOnUpdate()
    if not self._padOn then
        return
    end
    if not self.frame or not self.frame:IsShown() or not GQ:UsesGamepad() then
        self:GamepadRelease()
        return
    end
    local now = GetTime()
    if not self._padSilenceAt or now >= self._padSilenceAt then
        self._padSilenceAt = now + 0.25
        if self.GamepadSilence then
            self:GamepadSilence()
        end
    end
    self:GamepadSyncOwnership()
    if not self._padNavOwned then
        self._padRepeatKind = nil
        if self._padPoll then
            self._padWasDown = self:GamepadReadButtons() or {}
        end
        self:GamepadUpdateChrome()
        return
    end
    local focus = self._padFocus
    if not self:GamepadFocusVisible(focus) then
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
    end
    local kind = self._padRepeatKind
    local direction = self._padRepeatDir
    if self._padPoll then
        self:GamepadPollEdges()
        if not self._padOn then
            return
        end
    end
    self:GamepadUpdateChrome()
    if kind and direction and self._padRepeatAt and GetTime() >= self._padRepeatAt and not self:GamepadEditFocused() then
        local held = false
        if kind == "scroll" then
            held = self:GamepadHeld(HELD_SCROLL[direction])
        elseif kind == "move" then
            local source = self._padRepeatSource or "dpad"
            local bySource = HELD_MOVE[source]
            held = bySource and self:GamepadHeld(bySource[direction])
        end
        if held then
            if kind == "scroll" then
                self:GamepadScrollDetail(direction)
            else
                self._padMoveSource = self._padRepeatSource
                self:GamepadMove(direction)
            end
            local delay = 0.09
            if kind == "move" and ObjectType(self._padFocus) == "Slider" then
                delay = 0.18
            end
            self._padRepeatAt = GetTime() + delay
        else
            self._padRepeatKind = nil
            self._padRepeatDir = nil
        end
    end
end

local function PadTick()
    if GQ.Log and GQ.Log.GamepadOnUpdate then
        GQ.Log:GamepadOnUpdate()
    end
end

function GQ.Log:GamepadEnsureDriver()
    if self._padDriver then
        return
    end
    self._padDriver = CreateFrame("Frame")
end

function GQ.Log:GamepadHoldCursor()
    if self._padCursorHeld or not C_GamePad or not C_GamePad.SetGamePadCursorControl then
        return
    end
    self._padCursorWas = true
    if C_GamePad.IsGamePadCursorControlEnabled then
        local ok, enabled = pcall(C_GamePad.IsGamePadCursorControlEnabled)
        if ok then
            self._padCursorWas = enabled and true or false
        end
    end
    pcall(C_GamePad.SetGamePadCursorControl, false)
    self._padCursorHeld = true
end

function GQ.Log:GamepadReleaseCursor()
    if not self._padCursorHeld then
        return
    end
    self._padCursorHeld = false
    if self._padCursorWas and C_GamePad and C_GamePad.SetGamePadCursorControl then
        pcall(C_GamePad.SetGamePadCursorControl, true)
    end
    self._padCursorWas = nil
end

local function SilenceTree(root, owner)
    if not root or not root.IsShown or not root:IsShown() then
        return
    end
    SilenceFrame(root, owner)
    if root.GetChildren then
        local children = { root:GetChildren() }
        for i = 1, #children do
            SilenceTree(children[i], owner)
        end
    end
end

function GQ.Log:GamepadSilence()
    local frame = self.frame
    if frame then
        SilenceTree(frame, frame)
        SilenceTree(frame.sideTabRail, frame)
    end
    if self.weaponMenu then
        SilenceTree(self.weaponMenu, frame)
    end
    local bubble = GQ.PortraitGuide and GQ.PortraitGuide.bubble
    if bubble then
        SilenceTree(bubble, frame)
    end
end

function GQ.Log:GamepadAcquire()
    local frame = self.frame
    if not frame or not frame:IsShown() or not GQ.UsesGamepad or not GQ:UsesGamepad() then
        self:GamepadRelease()
        return
    end
    if GQ.SilenceGamepadActionPopup then
        GQ:SilenceGamepadActionPopup()
    end
    self:GamepadHoldCursor()
    SilenceTree(frame, frame)
    SilenceTree(frame.sideTabRail, frame)
    self:GamepadEnsureDriver()
    self._padDriver:SetScript("OnUpdate", PadTick)
    self:GamepadEnsureRing()
    local enabled = pcall(frame.EnableGamePadButton, frame, true)
    if enabled then
        pcall(frame.SetScript, frame, "OnGamePadButtonDown", function(_, button)
            GQ.Log:GamepadButton(button)
        end)
    end
    self._padOn = true
    self._padPoll = true
    self._padFilterMode = false
    self._padReading = false
    self._padWasDown = self:GamepadReadButtons() or {}
    self._padForeign = nil
    self._padPreferUs = true
    self._padNavOwned = true
    self._padHoldForeign = true
    self:GamepadNoteBlizzard()
    self:GamepadHookClaim(frame)
    self:GamepadHookClaim(frame.sideTabRail)
    self:GamepadHookClaim(frame.logPage)
    self:GamepadHookClaim(frame.playStylePanel)
    self:GamepadHookClaim(frame.sourceFilterMenu)
    self:GamepadHookClaim(frame.specPicker)
    self:GamepadHookClaim(self.weaponMenu)
    local bubble = GQ.PortraitGuide and GQ.PortraitGuide.bubble
    if bubble then
        SilenceTree(bubble, frame)
    end
    self:GamepadSyncOwnership()
    local list = self:GamepadCandidates()
    self:GamepadSetFocus(self:GamepadPickInitial(list))
    self:GamepadUpdateChrome()
end

function GQ.Log:GamepadRelease()
    self._padOn = false
    self._padPoll = false
    self._padRepeatKind = nil
    self._padRepeatDir = nil
    self._padWasDown = nil
    self._padDown = nil
    self._padEngineClickWidget = nil
    self._padFilterMode = false
    self._padReading = false
    self._padAllowClick = false
    if self._padDriver then
        self._padDriver:SetScript("OnUpdate", nil)
    end
    local frame = self.frame
    if frame then
        pcall(frame.EnableGamePadButton, frame, false)
        local hasScript, current = pcall(frame.GetScript, frame, "OnGamePadButtonDown")
        if hasScript and current then
            pcall(frame.SetScript, frame, "OnGamePadButtonDown", nil)
        end
    end
    if self._padFocus and HoverWidget(self._padFocus) then
        CallHandler(self._padFocus, "OnLeave")
    end
    if self._padFocus and ObjectType(self._padFocus) == "EditBox" and self._padFocus.ClearFocus then
        pcall(self._padFocus.ClearFocus, self._padFocus)
    end
    self._padFocus = nil
    if self._padRing then
        self._padRing:Hide()
        self._padRing:SetParent(UIParent)
    end
    if self._padHintBar then
        self._padHintBar:Hide()
    end
    if self._padMenuBar then
        self._padMenuBar:Hide()
    end
    if self._padLb then
        self._padLb:Hide()
    end
    if self._padRb then
        self._padRb:Hide()
    end
    local glow = self.frame and self.frame.gqPadFocusGlow
    if glow then
        glow:Hide()
    end
    self:GamepadRestoreForeign()
    self._padMutedRoot = nil
    self._padNavOwned = false
    self._padPreferUs = false
    self._padForeign = nil
    self._padHoldForeign = nil
    self._padBlizzShown = nil
    self:GamepadReleaseCursor()
end
