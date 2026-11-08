local _, GQ = ...
local L = GQ.L

GQ.Tracker = GQ.Tracker or {}

local MIN_WIDTH = 100
local MIN_HEIGHT = 100
local MAX_WIDTH = 400
local MAX_HEIGHT = 1000
local DEFAULT_WIDTH = 100
local MIN_DESC_WORDS = 10
local MAX_DESC_WORDS = 30
local TITLE_TEXT = L["GearQuest Tracker"]
local TITLE_COLOR = { 1, 0.82, 0 }
local ENTRY_NAME_COLOR = { 1, 1, 1 }
local ENTRY_DESC_COLOR = { 1, 1, 1, 0.72 }
local ENTRY_GAP = 6
local TITLE_GAP = 10
local RESIZE_GRIP = 14
local RESIZE_BORDER_THICKNESS = 2
local RESIZE_BORDER_COLOR = { 1, 1, 1, 0.6 }
local SCROLLBAR_WIDTH = 4
local SCROLLBAR_PAD = 2
local TEXT_INSET = 10
local TEXT_PAD_LEFT = 2
local SCROLLBAR_HIDE_DELAY = 1.2
local SCROLLBAR_MIN_THUMB = 18
local SCROLL_STEP = 24

local function WireTrackerHoverRegion(region)
    if not region or region.gqTrackerHoverWired then
        return
    end

    region.gqTrackerHoverWired = true
    if region.EnableMouse then
        region:EnableMouse(true)
    end

    region:HookScript("OnEnter", function()
        local tracker = GQ.Tracker
        tracker.trackerHoverCount = (tracker.trackerHoverCount or 0) + 1
        tracker:UpdateResizeHandleVisibility()
    end)

    region:HookScript("OnLeave", function()
        local tracker = GQ.Tracker
        tracker.trackerHoverCount = math.max(0, (tracker.trackerHoverCount or 0) - 1)
        tracker:UpdateResizeHandleVisibility()
    end)
end
local ROW_TOOLTIP_STILL_DELAY = 3
local ROW_TOOLTIP_MOVE_THRESHOLD = 1
local COLLAPSE_BUTTON_SIZE = 16
local COLLAPSED_HEIGHT_PAD = 4
local GUIDE_FOOTER = 20

local function NormalizeHuntStatus(status)
    if status == "active" then
        return "tracked"
    end
    return status
end

local function ClampSize(width, height)
    return
        math.min(MAX_WIDTH, math.max(MIN_WIDTH, width or DEFAULT_WIDTH)),
        math.min(MAX_HEIGHT, math.max(MIN_HEIGHT, height or MIN_HEIGHT))
end

local function GetDescWordLimit(width)
    width = math.min(MAX_WIDTH, math.max(MIN_WIDTH, width or DEFAULT_WIDTH))
    local ratio = (width - MIN_WIDTH) / (MAX_WIDTH - MIN_WIDTH)
    return math.floor(MIN_DESC_WORDS + ratio * (MAX_DESC_WORDS - MIN_DESC_WORDS) + 0.5)
end

local function FirstWords(text, maxWords)
    if not text or text == "" then
        return ""
    end

    text = text:gsub("\n+", " ")
    local words = {}
    local truncated = false
    for word in text:gmatch("%S+") do
        if #words >= maxWords then
            truncated = true
            break
        end
        words[#words + 1] = word
    end

    local result = table.concat(words, " ")
    if truncated then
        return result .. "..."
    end
    return result
end

local function CreateFontString(parent, font)
    local ok, fs = pcall(parent.CreateFontString, parent, nil, "ARTWORK", font)
    if ok and fs then
        return fs
    end
    return parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
end

local function CreateFontStringWithFallback(parent, candidates)
    for _, font in ipairs(candidates) do
        local ok, fs = pcall(parent.CreateFontString, parent, nil, "ARTWORK", font)
        if ok and fs then
            return fs
        end
    end
    return parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
end

local function ConfigureWrappedFontString(fs)
    if not fs then
        return
    end

    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    -- Without this, WoW truncates the last characters when a word barely
    -- exceeds the set width instead of wrapping it to the next line.
    if fs.SetNonSpaceWrap then
        fs:SetNonSpaceWrap(true)
    end
end

local function CreateEdgeTexture(border)
    local tex = border:CreateTexture(nil, "OVERLAY", nil, 7)
    tex:SetColorTexture(RESIZE_BORDER_COLOR[1], RESIZE_BORDER_COLOR[2], RESIZE_BORDER_COLOR[3], RESIZE_BORDER_COLOR[4])
    return tex
end

local function CreateResizeBorder(parent)
    local border = CreateFrame("Frame", nil, parent)
    border:SetAllPoints(parent)
    border:SetFrameStrata("TOOLTIP")
    border:SetFrameLevel(100)
    border:EnableMouse(false)
    border:Hide()

    local top = CreateEdgeTexture(border)
    top:SetHeight(RESIZE_BORDER_THICKNESS)
    top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)

    local bottom = CreateEdgeTexture(border)
    bottom:SetHeight(RESIZE_BORDER_THICKNESS)
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)

    local left = CreateEdgeTexture(border)
    left:SetWidth(RESIZE_BORDER_THICKNESS)
    left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)

    local right = CreateEdgeTexture(border)
    right:SetWidth(RESIZE_BORDER_THICKNESS)
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)

    return border
end

function GQ.Tracker:GetTrackedEntries()
    local results = {}

    local progress = GQ.Log and GQ.Log.CharProgress and GQ.Log:CharProgress() or GearQuestForeverDB
    for id, record in pairs(progress.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "tracked" then
            local entry = GQ.Data:GetEntryById(id)
            if entry
                and GQ.Data:EntryMatchesPlayer(entry)
                and GQ.Log:EntryMatchesTrackedHunt(entry)
                and not GQ.Log:IsEntryObtained(id) then
                results[#results + 1] = {
                    entry = entry,
                    trackedAt = record.trackedAt or 0,
                }
            end
        end
    end

    table.sort(results, function(a, b)
        if a.trackedAt ~= b.trackedAt then
            return a.trackedAt < b.trackedAt
        end
        return a.entry.id < b.entry.id
    end)

    local entries = {}
    for _, row in ipairs(results) do
        entries[#entries + 1] = row.entry
    end

    return entries
end

function GQ.Tracker:GetSavedSize()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    local size = GearQuestForeverDB.settings.trackerSize or {}
    return ClampSize(size.width or DEFAULT_WIDTH, size.height or 160)
end

function GQ.Tracker:SaveSize(width, height)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    width, height = ClampSize(width, height)
    GearQuestForeverDB.settings.trackerSize = {
        width = width,
        height = height,
    }
end

function GQ.Tracker:SavePosition()
    if not self.frame then
        return
    end

    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    local point, _, relPoint, x, y = self.frame:GetPoint(1)
    GearQuestForeverDB.settings.trackerPos = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

function GQ.Tracker:RestorePosition()
    if not self.frame then
        return
    end

    local pos = GearQuestForeverDB.settings and GearQuestForeverDB.settings.trackerPos
    self.frame:ClearAllPoints()
    if pos and pos.point then
        self.frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -120)
    end
end

function GQ.Tracker:SetFrameSize(width, height, opts)
    if not self.frame then
        return
    end

    opts = opts or {}
    local top = self.frame:GetTop()
    local left = self.frame:GetLeft()

    if opts.collapsed then
        width = math.min(MAX_WIDTH, math.max(MIN_WIDTH, width or DEFAULT_WIDTH))
        height = math.max(self:GetCollapsedHeight(), height or self:GetCollapsedHeight())
    else
        width, height = ClampSize(width, height)
    end

    self.frame:SetSize(width, height)

    if top and left then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end

    return width, height
end

function GQ.Tracker:GetScrollGutter()
    return SCROLLBAR_WIDTH + SCROLLBAR_PAD
end

function GQ.Tracker:IsCollapsed()
    return GearQuestForeverDB.settings and GearQuestForeverDB.settings.trackerCollapsed == true
end

function GQ.Tracker:SetCollapsed(collapsed)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    local wasCollapsed = self:IsCollapsed()

    if collapsed and not wasCollapsed and self.frame then
        local width, height = self.frame:GetSize()
        self:SaveSize(width, height)
    end

    GearQuestForeverDB.settings.trackerCollapsed = collapsed and true or false

    if wasCollapsed and not collapsed then
        self:BeginExpand()
        return
    end

    self:Refresh()
end

function GQ.Tracker:CancelExpandLayoutTimer()
    if not self.expandLayoutTimer then
        return
    end

    if self.expandLayoutTimer.Cancel then
        self.expandLayoutTimer:Cancel()
    end
    self.expandLayoutTimer = nil
end

function GQ.Tracker:BeginExpand()
    if not self.frame then
        return
    end

    self:CancelExpandLayoutTimer()

    local entries = self:GetTrackedEntries()
    if #entries == 0 then
        self.frame:Hide()
        return
    end

    local width, height = self:GetSavedSize()
    width = self:ApplyFrameWidth(width)
    self.title:SetText(TITLE_TEXT)
    self:UpdateCollapseButton()
    width, height = self:SetFrameSize(width, height)
    self:UpdateCollapseVisuals()
    self.frame:Show()

    if C_Timer and C_Timer.After then
        self.expandLayoutTimer = C_Timer.After(0, function()
            GQ.Tracker.expandLayoutTimer = nil
            if GQ.Tracker.frame and not GQ.Tracker:IsCollapsed() then
                GQ.Tracker:Refresh()
            end
        end)
    else
        self:Refresh()
    end
end

function GQ.Tracker:ToggleCollapsed()
    self:SetCollapsed(not self:IsCollapsed())
end

function GQ.Tracker:GetCollapsedHeight()
    local titleHeight = 14
    if self.title and self.title.GetStringHeight then
        titleHeight = self.title:GetStringHeight() or titleHeight
    end
    return titleHeight + COLLAPSED_HEIGHT_PAD
end

function GQ.Tracker:UpdateCollapseButton()
    if not self.collapseBtn then
        return
    end

    local collapsed = self:IsCollapsed()
    self.collapseBtn:SetNormalTexture(
        collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up"
    )
end

function GQ.Tracker:EnsureTrackerHoverWiring()
    if not self.frame or self.trackerHoverWired then
        return
    end

    self.trackerHoverWired = true
    WireTrackerHoverRegion(self.frame)
    WireTrackerHoverRegion(self.scroll)
    -- The list body is taller than the visible tracker. Leaving it mouse-enabled
    -- lets those rows sit on top of the bags and eat the first left-drag.
    if self.contentInner then
        self.contentInner:EnableMouse(false)
    end
    if self.scroll and self.scroll.SetClipsChildren then
        self.scroll:SetClipsChildren(true)
    end
    WireTrackerHoverRegion(self.collapseBtn)
    WireTrackerHoverRegion(self.dragHandle)
    WireTrackerHoverRegion(self.resizeHandle)
    if self.scrollBar then
        WireTrackerHoverRegion(self.scrollBar)
    end
    if self.scrollThumb then
        WireTrackerHoverRegion(self.scrollThumb)
    end
    if self.entryRows then
        for _, row in ipairs(self.entryRows) do
            WireTrackerHoverRegion(row)
        end
    end

    self:UpdateResizeHandleVisibility()
end

function GQ.Tracker:UpdateCollapseVisuals()
    local collapsed = self:IsCollapsed()

    self:UpdateCollapseButton()

    if self.scroll then
        if collapsed then
            self.scroll:Hide()
        else
            self.scroll:Show()
        end
    end

    if collapsed then
        self:HideScrollBar()
        self:StopResize()
    end

    self:UpdateResizeHandleVisibility()
end

function GQ.Tracker:UpdateResizeHandleVisibility()
    if not self.resizeHandle then
        return
    end

    if self:IsCollapsed() then
        self.resizeHandle:Hide()
        return
    end

    local show = self.sizing
        or self.resizeHandleHover
        or (self.trackerHoverCount or 0) > 0

    if show then
        self.resizeHandle:Show()
    else
        self.resizeHandle:Hide()
    end
end

function GQ.Tracker:TrackerHoverEnter()
    self.trackerHoverCount = (self.trackerHoverCount or 0) + 1
    self:UpdateResizeHandleVisibility()
end

function GQ.Tracker:TrackerHoverLeave()
    self.trackerHoverCount = math.max(0, (self.trackerHoverCount or 0) - 1)
    self:UpdateResizeHandleVisibility()
end

function GQ.Tracker:EnsureCollapseButton(frame)
    if not frame or self.collapseBtn then
        return
    end

    local collapseBtn = CreateFrame("Button", nil, frame)
    collapseBtn:SetSize(COLLAPSE_BUTTON_SIZE, COLLAPSE_BUTTON_SIZE)
    collapseBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    collapseBtn:SetScript("OnClick", function()
        GQ.Tracker:ToggleCollapsed()
    end)
    collapseBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(collapseBtn, "ANCHOR_RIGHT")
        if GQ.Tracker:IsCollapsed() then
            GameTooltip:SetText(L["Expand tracker"], 1, 1, 1)
        else
            GameTooltip:SetText(L["Collapse tracker"], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    collapseBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.collapseBtn = collapseBtn
    self.collapseBtn = collapseBtn

    if self.title then
        self.title:ClearAllPoints()
        self.title:SetPoint("TOPLEFT", collapseBtn, "TOPRIGHT", 2, 0)
        self.title:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    end

    if self.dragHandle and self.title then
        self.dragHandle:ClearAllPoints()
        self.dragHandle:SetPoint("TOPLEFT", collapseBtn, "TOPLEFT", -2, 2)
        self.dragHandle:SetPoint("BOTTOMRIGHT", self.title, "BOTTOMRIGHT", 2, -2)
    end

    self:UpdateCollapseButton()
end

function GQ.Tracker:ApplyFrameWidth(width)
    width = math.min(MAX_WIDTH, math.max(MIN_WIDTH, width or DEFAULT_WIDTH))

    if self.title then
        self.title:SetWidth(math.max(MIN_WIDTH - COLLAPSE_BUTTON_SIZE - 2, width - COLLAPSE_BUTTON_SIZE - 2))
    end
    if self.scroll then
        self.scroll:SetWidth(width)
    end

    return width
end

function GQ.Tracker:ApplyTextWidth(textWidth)
    textWidth = math.max(MIN_WIDTH - self:GetScrollGutter(), (textWidth or DEFAULT_WIDTH) - TEXT_INSET - TEXT_PAD_LEFT)

    if self.contentInner then
        self.contentInner:SetWidth(textWidth + TEXT_PAD_LEFT)
    end
    if self.entryRows then
        for _, row in ipairs(self.entryRows) do
            row:SetWidth(textWidth + TEXT_PAD_LEFT)
            if row.name then
                row.name:SetWidth(textWidth)
                ConfigureWrappedFontString(row.name)
            end
            if row.desc then
                row.desc:SetWidth(textWidth)
                ConfigureWrappedFontString(row.desc)
            end
        end
    end

    return textWidth
end

function GQ.Tracker:LayoutEntries(entries, descWordLimit)
    local yOffset = 0

    for i, entry in ipairs(entries) do
        local row = self.entryRows[i]
        if row.cachedEntryId ~= entry.id or not row.cachedItemName then
            row.cachedEntryId = entry.id
            row.cachedItemName = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)
        elseif row.cachedItemName:match("^Item %d+$") then
            local resolved = GQ.Data:GetEntryDisplayName(entry)
            if resolved then
                row.cachedItemName = resolved
            end
        end

        local itemName = row.cachedItemName
        local instructions = entry.instructions
        if entry.sourceType == "profession" and GQ.Data and GQ.Data.GetProfessionInstructions then
            instructions = GQ.Data:GetProfessionInstructions(entry)
        elseif GQ.Data and GQ.Data.VendorBoughtLine then
            local vendorLine = GQ.Data:VendorBoughtLine(entry)
            if vendorLine and vendorLine ~= "" then
                instructions = vendorLine
            end
        end
        if GQ.Data and GQ.Data.SanitizeText then
            instructions = GQ.Data:SanitizeText(instructions) or instructions
        end
        instructions = L.Text(instructions)
        local desc = FirstWords(instructions, descWordLimit)

        row.name:SetText(itemName)
        row.desc:SetText(desc)
        row.entryId = entry.id
        row.name:SetTextColor(ENTRY_NAME_COLOR[1], ENTRY_NAME_COLOR[2], ENTRY_NAME_COLOR[3])
        row.desc:SetTextColor(ENTRY_DESC_COLOR[1], ENTRY_DESC_COLOR[2], ENTRY_DESC_COLOR[3], ENTRY_DESC_COLOR[4])

        local nameHeight = row.name:GetStringHeight() or 12
        local descHeight = row.desc:GetStringHeight() or 0
        local rowHeight = nameHeight + 2 + descHeight + GUIDE_FOOTER
        if row.guideCheck then
            local guided = GQ.Guide and GQ.Guide.GuidedId and GQ.Guide:GuidedId() == entry.id
            row.guideCheck:SetChecked(guided and true or false)
            if row.GetFrameLevel and row.guideCheck.SetFrameLevel then
                local level = row:GetFrameLevel() + 4
                row.guideCheck:SetFrameLevel(level)
                if row.guideHit then
                    row.guideHit:SetFrameLevel(level)
                end
            end
            if row.guideHit and row.guideLabel and row.guideLabel.GetStringWidth then
                row.guideHit:SetWidth((row.guideLabel:GetStringWidth() or 70) + 8)
            end
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.contentInner, "TOPLEFT", 0, -yOffset)
        row:SetHeight(rowHeight)

        yOffset = yOffset + rowHeight + ENTRY_GAP
    end

    return yOffset
end

function GQ.Tracker:UpdateGuideChecks()
    if not self.entryRows then
        return
    end
    local guided = GQ.Guide and GQ.Guide.GuidedId and GQ.Guide:GuidedId()
    for i = 1, #self.entryRows do
        local row = self.entryRows[i]
        if row.guideCheck then
            row.guideCheck:SetChecked(guided ~= nil and row.entryId == guided)
        end
    end
end

function GQ.Tracker:ApplyWidth(width)
    return self:ApplyFrameWidth(width)
end

function GQ.Tracker:IsMouseOverFrame(frame)
    if not frame then
        return false
    end
    if frame.IsMouseOver then
        return frame:IsMouseOver()
    end
    return MouseIsOver(frame)
end

function GQ.Tracker:EnsureRowTooltipTicker()
    if self.rowTooltipTicker then
        return
    end

    local ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", function()
        GQ.Tracker:UpdateRowTooltipWatch()
    end)
    self.rowTooltipTicker = ticker
end

function GQ.Tracker:BeginRowTooltipWatch(row)
    if not row or not row.entryId then
        return
    end

    self:CancelRowTooltipWatch(row, true)
    self:EnsureRowTooltipTicker()

    row.gqTooltipStillSince = nil
    row.gqTooltipLastX = nil
    row.gqTooltipLastY = nil
    row.gqTooltipShown = false

    self.rowTooltipRow = row
    self.rowTooltipTicker:Show()
end

function GQ.Tracker:CancelRowTooltipWatch(row, keepTooltip)
    if row then
        row.gqTooltipStillSince = nil
        row.gqTooltipLastX = nil
        row.gqTooltipLastY = nil
        row.gqTooltipShown = false
    end

    if self.rowTooltipRow == row then
        self.rowTooltipRow = nil
        if self.rowTooltipTicker then
            self.rowTooltipTicker:Hide()
        end
    end

    if not keepTooltip then
        GameTooltip:Hide()
    end
end

function GQ.Tracker:UpdateRowTooltipWatch()
    local row = self.rowTooltipRow
    if not row or not row.entryId then
        if self.rowTooltipTicker then
            self.rowTooltipTicker:Hide()
        end
        return
    end

    if not self:IsMouseOverFrame(row) then
        self:CancelRowTooltipWatch(row)
        return
    end

    local scale = row:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local lastX = row.gqTooltipLastX
    local lastY = row.gqTooltipLastY
    if lastX and (math.abs(cursorX - lastX) > ROW_TOOLTIP_MOVE_THRESHOLD or math.abs(cursorY - lastY) > ROW_TOOLTIP_MOVE_THRESHOLD) then
        row.gqTooltipStillSince = GetTime()
        row.gqTooltipLastX = cursorX
        row.gqTooltipLastY = cursorY
        row.gqTooltipShown = false
        GameTooltip:Hide()
        return
    end

    if not row.gqTooltipStillSince then
        row.gqTooltipStillSince = GetTime()
        row.gqTooltipLastX = cursorX
        row.gqTooltipLastY = cursorY
        return
    end

    if row.gqTooltipShown then
        return
    end

    if GetTime() - row.gqTooltipStillSince >= ROW_TOOLTIP_STILL_DELAY then
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Click to open in GearQuest Log"], 1, 1, 1)
        GameTooltip:Show()
        row.gqTooltipShown = true
    end
end

function GQ.Tracker:EnsureEntryRows(count)
    local width = select(1, self:GetSavedSize())
    width = self:ApplyFrameWidth(width)
    self:ApplyTextWidth(width)
    self.entryRows = self.entryRows or {}

    while #self.entryRows < count do
        local index = #self.entryRows + 1
        local row = CreateFrame("Button", nil, self.contentInner)
        row:SetWidth(width)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        if row.GetHighlightTexture then
            local highlight = row:GetHighlightTexture()
            if highlight and highlight.SetAlpha then
                highlight:SetAlpha(0.35)
            end
        end
        row:RegisterForClicks("LeftButtonUp")

        row.name = CreateFontString(row, "GameFontNormal")
        row.name:SetWidth(width)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", TEXT_PAD_LEFT, 0)
        ConfigureWrappedFontString(row.name)
        row.name:SetTextColor(ENTRY_NAME_COLOR[1], ENTRY_NAME_COLOR[2], ENTRY_NAME_COLOR[3])

        row.desc = CreateFontString(row, "GameFontNormal")
        row.desc:SetWidth(width)
        row.desc:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
        ConfigureWrappedFontString(row.desc)
        row.desc:SetTextColor(ENTRY_DESC_COLOR[1], ENTRY_DESC_COLOR[2], ENTRY_DESC_COLOR[3], ENTRY_DESC_COLOR[4])

        row.guideCheck = CreateFrame("CheckButton", nil, row)
        row.guideCheck:SetSize(16, 16)
        row.guideCheck:SetPoint("TOPLEFT", row.desc, "BOTTOMLEFT", 0, -3)
        row.guideCheck:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        row.guideCheck:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        row.guideCheck:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        row.guideCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.guideCheck:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            if not parent or not parent.entryId or not GQ.Guide then
                return
            end
            if self:GetChecked() then
                local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(parent.entryId)
                if entry then
                    GQ.Guide:ShowEntry(entry)
                end
            else
                GQ.Guide:Dismiss()
            end
        end)

        row.guideLabel = CreateFontString(row, "GameFontHighlightSmall")
        row.guideLabel:SetPoint("LEFT", row.guideCheck, "RIGHT", 2, 0)
        row.guideLabel:SetText(L["Enable Guide"])
        row.guideLabel:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])

        row.guideHit = CreateFrame("Button", nil, row)
        row.guideHit:SetPoint("LEFT", row.guideCheck, "RIGHT", 0, 0)
        row.guideHit:SetSize(90, 16)
        row.guideHit:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local check = parent and parent.guideCheck
            if not check then
                return
            end
            check:SetChecked(not check:GetChecked())
            local click = check:GetScript("OnClick")
            if click then
                click(check)
            end
        end)

        row:SetScript("OnClick", function(self)
            if self.guideCheck and self.guideCheck:IsMouseOver() then
                return
            end
            if self.guideHit and self.guideHit:IsMouseOver() then
                return
            end
            if self.entryId and GQ.Tracker then
                GQ.Tracker:CancelRowTooltipWatch(self)
                GQ.Tracker:OpenHunt(self.entryId)
            end
        end)

        row:SetScript("OnEnter", function(self)
            if self.entryId and GQ.Tracker then
                GQ.Tracker:BeginRowTooltipWatch(self)
            end
        end)

        row:SetScript("OnLeave", function(self)
            if GQ.Tracker then
                GQ.Tracker:CancelRowTooltipWatch(self)
            end
        end)

        self.entryRows[index] = row
        WireTrackerHoverRegion(row)
    end

    for i = 1, #self.entryRows do
        if i <= count then
            self.entryRows[i]:Show()
        else
            self.entryRows[i]:Hide()
        end
    end
end

function GQ.Tracker:GetMaxScroll()
    if not self.scroll or not self.contentInner then
        return 0
    end

    local scrollHeight = self.scroll:GetHeight() or 0
    local contentHeight = self.contentInner:GetHeight() or 0
    return math.max(0, contentHeight - scrollHeight)
end

function GQ.Tracker:HideScrollBar()
    if self.scrollBarHideTimer then
        self.scrollBarHideTimer:Cancel()
        self.scrollBarHideTimer = nil
    end

    self.scrollBarHideAt = nil

    if self.scrollBar then
        self.scrollBar:Hide()
        self.scrollBar:SetAlpha(0)
    end
end

function GQ.Tracker:ScheduleScrollBarHide()
    if self.scrollBarHideTimer then
        self.scrollBarHideTimer:Cancel()
        self.scrollBarHideTimer = nil
    end

    if C_Timer and C_Timer.NewTimer then
        self.scrollBarHideTimer = C_Timer.NewTimer(SCROLLBAR_HIDE_DELAY, function()
            if GQ.Tracker and not GQ.Tracker.scrollBarDragging then
                GQ.Tracker:HideScrollBar()
            end
        end)
        return
    end

    self.scrollBarHideAt = GetTime() + SCROLLBAR_HIDE_DELAY
    self:EnsureScrollBarHideTicker()
end

function GQ.Tracker:ShowScrollBarTemporary()
    if not self.scrollBar or self:GetMaxScroll() <= 0 then
        self:HideScrollBar()
        return
    end

    self.scrollBar:Show()
    self.scrollBar:SetAlpha(1)
    self:ScheduleScrollBarHide()
end

function GQ.Tracker:ClampRowMouse()
    local scroll = self.scroll
    if not scroll or not self.entryRows then
        return
    end
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    if not scrollTop or not scrollBottom then
        return
    end
    for _, row in ipairs(self.entryRows) do
        if row:IsShown() and row.EnableMouse then
            local rowTop = row:GetTop()
            local rowBottom = row:GetBottom()
            local overlaps = rowTop and rowBottom and rowBottom < scrollTop and rowTop > scrollBottom
            row:EnableMouse(overlaps and true or false)
            if overlaps and row.SetHitRectInsets then
                local topInset = math.max(0, rowTop - scrollTop)
                local bottomInset = math.max(0, scrollBottom - rowBottom)
                row:SetHitRectInsets(0, 0, topInset, bottomInset)
            end
        end
    end
end

function GQ.Tracker:SetScrollOffset(offset)
    if not self.scroll then
        return
    end

    local maxScroll = self:GetMaxScroll()
    offset = math.max(0, math.min(maxScroll, offset or 0))
    self.scroll:SetVerticalScroll(offset)
    self:UpdateScrollBar()
    self:ClampRowMouse()
end

function GQ.Tracker:ScrollBy(delta)
    if not self.scroll or delta == 0 then
        return
    end

    local maxScroll = self:GetMaxScroll()
    if maxScroll <= 0 then
        return
    end

    local current = self.scroll:GetVerticalScroll() or 0
    self:SetScrollOffset(current - (delta * SCROLL_STEP))
    self:ShowScrollBarTemporary()
end

function GQ.Tracker:UpdateScrollBar()
    if not self.scroll or not self.scrollBar or not self.scrollThumb then
        return
    end

    local maxScroll = self:GetMaxScroll()
    if maxScroll <= 0 then
        self:HideScrollBar()
        self.scroll:SetVerticalScroll(0)
        return
    end

    local scrollPos = self.scroll:GetVerticalScroll() or 0
    local trackHeight = self.scrollBar:GetHeight() or 1
    local scrollHeight = self.scroll:GetHeight() or 1
    local contentHeight = self.contentInner:GetHeight() or 1
    local thumbHeight = math.max(SCROLLBAR_MIN_THUMB, trackHeight * (scrollHeight / contentHeight))
    local thumbTravel = math.max(0, trackHeight - thumbHeight)
    local thumbOffset = maxScroll > 0 and (scrollPos / maxScroll) * thumbTravel or 0

    self.scrollThumb:SetHeight(thumbHeight)
    self.scrollThumb:ClearAllPoints()
    self.scrollThumb:SetPoint("TOP", self.scrollBar, "TOP", 0, -thumbOffset)
end

function GQ.Tracker:BeginThumbDrag()
    if not self.scrollBar or not self.scrollThumb or not self.scroll then
        return
    end

    self.scrollBarDragging = true
    self:ShowScrollBarTemporary()

    local scale = self.scrollBar:GetEffectiveScale()
    local _, cursorY = GetCursorPosition()
    cursorY = cursorY / scale
    local thumbTop = self.scrollThumb:GetTop() or cursorY
    self.thumbDragOffset = cursorY - thumbTop

    self.scrollBar:SetScript("OnUpdate", function()
        local tracker = GQ.Tracker
        if not tracker.scrollBarDragging or not tracker.scrollBar or not tracker.scrollThumb then
            return
        end

        if not IsMouseButtonDown("LeftButton") then
            tracker:StopThumbDrag()
            return
        end

        local barScale = tracker.scrollBar:GetEffectiveScale()
        local _, y = GetCursorPosition()
        y = y / barScale

        local barTop = tracker.scrollBar:GetTop() or y
        local trackHeight = tracker.scrollBar:GetHeight() or 1
        local scrollHeight = tracker.scroll:GetHeight() or 1
        local contentHeight = tracker.contentInner:GetHeight() or 1
        local thumbHeight = math.max(SCROLLBAR_MIN_THUMB, trackHeight * (scrollHeight / contentHeight))
        local thumbTravel = math.max(0, trackHeight - thumbHeight)
        local thumbTop = y - (tracker.thumbDragOffset or 0)
        local thumbOffset = barTop - thumbTop
        thumbOffset = math.max(0, math.min(thumbTravel, thumbOffset))

        local maxScroll = tracker:GetMaxScroll()
        local scrollPos = thumbTravel > 0 and (thumbOffset / thumbTravel) * maxScroll or 0
        tracker:SetScrollOffset(scrollPos)
        tracker:ShowScrollBarTemporary()
    end)
end

function GQ.Tracker:StopThumbDrag()
    self.scrollBarDragging = false
    self.thumbDragOffset = nil

    if self.scrollBar then
        self.scrollBar:SetScript("OnUpdate", nil)
    end

    self:ScheduleScrollBarHide()
end

function GQ.Tracker:EnsureScrollBarHideTicker()
    if self.scrollBarHideTicker or (C_Timer and C_Timer.NewTimer) then
        return
    end

    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function()
        local tracker = GQ.Tracker
        if not tracker or tracker.scrollBarDragging or not tracker.scrollBarHideAt then
            return
        end

        if GetTime() >= tracker.scrollBarHideAt then
            tracker.scrollBarHideAt = nil
            tracker:HideScrollBar()
        end
    end)
    self.scrollBarHideTicker = ticker
end

function GQ.Tracker:CreateScrollBar(scroll, frame)
    local scrollBar = CreateFrame("Frame", nil, frame)
    scrollBar:SetWidth(SCROLLBAR_WIDTH)
    scrollBar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
    scrollBar:SetFrameLevel(scroll:GetFrameLevel() + 4)
    scrollBar:Hide()
    scrollBar:SetAlpha(0)

    local track = scrollBar:CreateTexture(nil, "ARTWORK")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.12)

    local thumb = CreateFrame("Button", nil, scrollBar)
    thumb:SetWidth(SCROLLBAR_WIDTH)
    thumb:SetHeight(SCROLLBAR_MIN_THUMB)
    thumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)

    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(1, 1, 1, 0.55)

    thumb:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            GQ.Tracker:BeginThumbDrag()
        end
    end)

    thumb:SetScript("OnMouseUp", function()
        GQ.Tracker:StopThumbDrag()
    end)

    scrollBar:SetScript("OnEnter", function()
        GQ.Tracker:ShowScrollBarTemporary()
    end)

    return scrollBar, thumb
end

function GQ.Tracker:OpenHunt(entryId)
    local log = GQ.Log
    if not log or not entryId then
        return
    end

    if log.GetListTab and log:GetListTab() ~= "active" then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.listTab = "active"
    end

    log:Show()
    log:SelectHunt(entryId, true)
end

function GQ.Tracker:ShowResizeBorder()
    if self.resizeBorder then
        self.resizeBorder:Show()
    end
end

function GQ.Tracker:HideResizeBorder()
    if self.resizeBorder then
        self.resizeBorder:Hide()
    end
end

function GQ.Tracker:StopResize()
    if not self.frame then
        return
    end

    local wasSizing = self.sizing

    if self.sizing then
        self.frame:StopMovingOrSizing()
        self.sizing = false
    end

    self:HideResizeBorder()
    self:UpdateResizeHandleVisibility()

    if not wasSizing then
        return
    end

    local width, height = ClampSize(self.frame:GetSize())
    width, height = self:SetFrameSize(width, height)
    self:SaveSize(width, height)
    self:Refresh(width, height)
end

function GQ.Tracker:BeginResize()
    if not self.frame or not self.resizeHandle then
        return
    end

    self.sizing = true
    self:ShowResizeBorder()
    self:UpdateResizeHandleVisibility()
    self.frame:StartSizing("BOTTOMRIGHT")
end

function GQ.Tracker:Refresh(widthOverride, heightOverride)
    if GQ.Pins and GQ.Pins.Sync then
        GQ.Pins:Sync()
    end
    if not self.frame then
        return
    end

    local entries = self:GetTrackedEntries()
    if #entries == 0 then
        self:StopResize()
        self:HideResizeBorder()
        self.frame:Hide()
        return
    end

    local width, height
    if widthOverride and heightOverride then
        width, height = ClampSize(widthOverride, heightOverride)
    elseif self.sizing then
        width, height = ClampSize(self.frame:GetSize())
    else
        width, height = self:GetSavedSize()
    end
    width = self:ApplyFrameWidth(width)
    local collapsed = self:IsCollapsed()

    self.title:SetText(TITLE_TEXT)
    self:UpdateCollapseButton()

    if collapsed then
        self:UpdateCollapseVisuals()
        if self.entryRows then
            for _, row in ipairs(self.entryRows) do
                row:Hide()
            end
        end
        self:SetFrameSize(width, self:GetCollapsedHeight(), { collapsed = true })
        self.frame:Show()
        return
    end

    if not self.sizing then
        width, height = self:SetFrameSize(width, height)
    end

    self:UpdateCollapseVisuals()
    self:EnsureEntryRows(#entries)

    local titleHeight = self.title:GetStringHeight() or 14
    local scrollHeight = math.max(MIN_HEIGHT - titleHeight - TITLE_GAP - RESIZE_GRIP, height - titleHeight - TITLE_GAP - RESIZE_GRIP)

    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -TITLE_GAP)
    self.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, RESIZE_GRIP)
    self.scroll:SetWidth(width)

    self:ApplyTextWidth(width)
    local descWordLimit = GetDescWordLimit(width)
    local yOffset = self:LayoutEntries(entries, descWordLimit)

    self.contentInner:SetHeight(math.max(yOffset, 1))

    if self:GetMaxScroll() > 0 then
        local textWidth = width - self:GetScrollGutter()
        self:ApplyTextWidth(textWidth)
        descWordLimit = GetDescWordLimit(textWidth)
        yOffset = self:LayoutEntries(entries, descWordLimit)
        self.contentInner:SetHeight(math.max(yOffset, 1))
    end

    local maxScroll = self:GetMaxScroll()
    local currentScroll = self.scroll:GetVerticalScroll() or 0
    if currentScroll > maxScroll then
        self.scroll:SetVerticalScroll(maxScroll)
    end

    self:UpdateScrollBar()
    if maxScroll <= 0 then
        self:HideScrollBar()
    end
    self:ClampRowMouse()

    if self.sizing then
        local frameWidth, frameHeight = self.frame:GetSize()
        width, height = ClampSize(frameWidth, frameHeight)
        if width ~= frameWidth or height ~= frameHeight then
            self:SetFrameSize(width, height)
        end
    end

    self.frame:Show()
    self:ClampRowMouse()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if GQ.Tracker and GQ.Tracker.ClampRowMouse then
                GQ.Tracker:ClampRowMouse()
            end
        end)
    end
end

function GQ.Tracker:Init()
    if self.frame and not self.scroll then
        self.frame:Hide()
        self.frame = nil
        self.title = nil
        self.contentInner = nil
        self.resizeHandle = nil
        self.resizeBorder = nil
        self.scrollBar = nil
        self.scrollThumb = nil
        self.entryRows = nil
    end

    if self.frame then
        if not self.resizeBorder then
            self.resizeBorder = CreateResizeBorder(self.frame)
        end
        self:EnsureCollapseButton(self.frame)
        self:EnsureTrackerHoverWiring()
        self:EnsureScrollBarHideTicker()
        self:Refresh()
        return
    end

    local width, height = self:GetSavedSize()

    local frame = CreateFrame("Frame", "GearQuestTracker", UIParent)
    frame:SetSize(width, height)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetResizable(true)
    frame:Hide()

    local title = CreateFontStringWithFallback(frame, {
        "QuestFont_Large",
        "GameFontHighlightLarge",
        "GameFontNormalLarge",
    })
    title:SetWidth(width - COLLAPSE_BUTTON_SIZE - 2)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", COLLAPSE_BUTTON_SIZE + 2, 0)
    title:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(true)
    title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    title:SetText(TITLE_TEXT)

    local collapseBtn = CreateFrame("Button", nil, frame)
    collapseBtn:SetSize(COLLAPSE_BUTTON_SIZE, COLLAPSE_BUTTON_SIZE)
    collapseBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    collapseBtn:SetScript("OnClick", function()
        GQ.Tracker:ToggleCollapsed()
    end)
    collapseBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GQ.Tracker:IsCollapsed() then
            GameTooltip:SetText(L["Expand tracker"], 1, 1, 1)
        else
            GameTooltip:SetText(L["Collapse tracker"], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    collapseBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local dragHandle = CreateFrame("Frame", nil, frame)
    dragHandle:SetPoint("TOPLEFT", collapseBtn, "TOPLEFT", -2, 2)
    dragHandle:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", 2, -2)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        GQ.Tracker:SavePosition()
    end)
    frame:SetMovable(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        GQ.Tracker:ScrollBy(delta)
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -TITLE_GAP)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, RESIZE_GRIP)
    scroll:SetWidth(width)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        GQ.Tracker:ScrollBy(delta)
    end)

    local contentInner = CreateFrame("Frame", nil, scroll)
    contentInner:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    contentInner:SetWidth(width)
    scroll:SetScrollChild(contentInner)

    local scrollBar, scrollThumb = self:CreateScrollBar(scroll, frame)
    self:EnsureScrollBarHideTicker()

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(RESIZE_GRIP, RESIZE_GRIP)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeHandle:SetScript("OnEnter", function(self)
        GQ.Tracker.resizeHandleHover = true
        GQ.Tracker:UpdateResizeHandleVisibility()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Drag to resize"], 1, 1, 1)
        GameTooltip:Show()
    end)
    resizeHandle:SetScript("OnLeave", function()
        GQ.Tracker.resizeHandleHover = false
        GQ.Tracker:UpdateResizeHandleVisibility()
        GameTooltip:Hide()
    end)
    resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            GQ.Tracker:BeginResize()
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        GQ.Tracker:StopResize()
    end)

    frame:SetScript("OnSizeChanged", function(_, frameWidth, frameHeight)
        if not GQ.Tracker.sizing then
            return
        end

        local width, height = ClampSize(frameWidth, frameHeight)
        if width ~= frameWidth or height ~= frameHeight then
            GQ.Tracker:SetFrameSize(width, height)
        end

        GQ.Tracker:Refresh(width, height)
    end)

    self.frame = frame
    self.title = title
    self.collapseBtn = collapseBtn
    self.dragHandle = dragHandle
    self.scroll = scroll
    self.contentInner = contentInner
    self.scrollBar = scrollBar
    self.scrollThumb = scrollThumb
    self.resizeHandle = resizeHandle
    self.resizeBorder = CreateResizeBorder(frame)
    self.entryRows = {}

    self:RestorePosition()

    local listener = CreateFrame("Frame")
    GQ.RegisterEvent(listener, "GET_ITEM_INFO_RECEIVED")
    listener:SetScript("OnEvent", function()
    end)
    self.itemInfoListener = listener

    self:UpdateCollapseButton()
    self:EnsureTrackerHoverWiring()
    self:Refresh()
end
