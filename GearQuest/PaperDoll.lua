local _, GQ = ...

GQ.PaperDoll = GQ.PaperDoll or {}

local function KnownSlot(slotName)
    local slots = GQ.Data and GQ.Data.PAPER_DOLL_SLOTS
    if not slots or not slotName then
        return false
    end
    for i = 1, #slots do
        if slots[i] == slotName then
            return true
        end
    end
    return false
end

local function SlotFromWidget(widget)
    local node = widget
    local guard = 0
    while node and guard < 8 do
        guard = guard + 1
        local name = node.GetName and node:GetName()
        if type(name) == "string" then
            local slotName = name:match("^Character(.+)Slot$")
            if slotName and KnownSlot(slotName) and _G[name] == node then
                return slotName, node
            end
        end
        node = node.GetParent and node:GetParent()
    end
end

-- ButtonIndexToConfigName and the state array are not always the same base.
-- The same offset the log uses keeps a right-stick click from reading as
-- another button.
local stickApiBase
local function StickConfigName(index)
    if type(index) ~= "number" or not C_GamePad or not C_GamePad.ButtonIndexToConfigName then
        return nil
    end
    local ok, name = pcall(C_GamePad.ButtonIndexToConfigName, index)
    if ok and type(name) == "string" and name ~= "" then
        return name:upper()
    end
end

local function StickApiBase()
    if stickApiBase ~= nil then
        return stickApiBase
    end
    if StickConfigName(0) == "PAD1" then
        stickApiBase = 0
    elseif StickConfigName(1) == "PAD1" then
        stickApiBase = 1
    else
        stickApiBase = 0
    end
    return stickApiBase
end

local function StickTableBase(buttons)
    if type(buttons) == "table" and buttons[0] ~= nil then
        return 0
    end
    return 1
end

function GQ.PaperDoll:SlotAllowsUpgrade(slotName)
    if slotName ~= "SecondaryHand" then
        return true
    end
    local data = GQ.Data
    local log = GQ.Log
    if not data or not log then
        return false
    end
    local offOn = log.WeaponStyleEnabled and log:WeaponStyleEnabled("off")
    local shield = data.OffHandShowsShieldOrHeld and data:OffHandShowsShieldOrHeld()
    local dual = data.CanDualWield and data:CanDualWield()
    -- A damaging off hand opens when Off Hand is on and the spec can dual
    -- wield. Shamans cannot. Shields still open here.
    return shield or (dual and offOn)
end

function GQ.PaperDoll:OpenSlot(slotName, button)
    if not slotName or not KnownSlot(slotName) then
        return
    end
    if not CharacterFrame or not CharacterFrame:IsShown() then
        return
    end
    if not PaperDollFrame or not PaperDollFrame:IsShown() then
        return
    end
    if not self:SlotAllowsUpgrade(slotName) then
        return
    end
    if GQ.Popup then
        GQ.Popup:ShowForSlot(slotName, button)
    end
end

function GQ.PaperDoll:FocusedSlot()
    -- Read only. Calling FrameControlsManager changes the binding stack.
    local mgr = _G.FrameControlsManager
    local slotName, button = SlotFromWidget(mgr and mgr.currentFrame)
    if slotName then
        return slotName, button
    end
    if self.lastSlot and self.lastButton and self.lastButton.IsShown and self.lastButton:IsShown() then
        return self.lastSlot, self.lastButton
    end
end

function GQ.PaperDoll:StickClickDown()
    if not C_GamePad or not C_GamePad.GetDeviceMappedState then
        return false
    end
    local ok, state = pcall(C_GamePad.GetDeviceMappedState)
    if not ok or type(state) ~= "table" or type(state.buttons) ~= "table" then
        return false
    end
    local base = StickTableBase(state.buttons)
    local api = StickApiBase()
    for index, pressed in pairs(state.buttons) do
        if pressed and type(index) == "number" then
            local name = StickConfigName(index - base + api)
            if name == "PADRSTICK" then
                return true
            end
        end
    end
    return false
end

function GQ.PaperDoll:OnStickClick()
    if GQ.Log and GQ.Log._padNavOwned then
        return
    end
    local slotName, button = self:FocusedSlot()
    if not slotName then
        return
    end
    local popup = GQ.Popup
    local normalized = GQ.Data and GQ.Data.NormalizeSlotName and GQ.Data:NormalizeSlotName(slotName)
    if popup and popup.container and popup.container:IsShown() and popup.activeSlotName == normalized then
        popup:Hide()
        return
    end
    self:OpenSlot(slotName, button)
end

function GQ.PaperDoll:EnsureStickWatch()
    if self.stickWatch then
        return
    end
    local watch = CreateFrame("Frame")
    watch:Hide()
        watch:SetScript("OnUpdate", function()
            local doll = GQ.PaperDoll
            if not CharacterFrame or not CharacterFrame:IsShown() then
                doll.stickWasDown = false
                if doll.stickWatch then
                    doll.stickWatch:Hide()
                end
                return
            end
            if not PaperDollFrame or not PaperDollFrame:IsShown()
                or not GQ.UsesGamepad or not GQ:UsesGamepad() then
                doll.stickWasDown = false
                return
            end
        local down = doll:StickClickDown()
        local was = doll.stickWasDown
        doll.stickWasDown = down
        if down and not was then
            doll:OnStickClick()
        end
    end)
    self.stickWatch = watch
end

function GQ.PaperDoll:WatchStick()
    self:EnsureStickWatch()
    if CharacterFrame and CharacterFrame:IsShown() then
        self.stickWatch:Show()
    end
end

function GQ.PaperDoll:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    local slots = GQ.Data and GQ.Data.PAPER_DOLL_SLOTS
    if not slots then
        return
    end

    for _, slotName in ipairs(slots) do
        local button = _G["Character" .. slotName .. "Slot"]
        if button and not button.GearQuestHooked then
            button.GearQuestHooked = true
            button:HookScript("OnEnter", function(self)
                local doll = GQ.PaperDoll
                if doll then
                    doll.lastSlot = slotName
                    doll.lastButton = self
                end
            end)
            button:HookScript("OnClick", function(self, mouseButton)
                local gq = _G.GearQuest
                if mouseButton == "RightButton" then
                    if gq and gq.PaperDoll then
                        gq.PaperDoll:OpenSlot(slotName, self)
                    end
                    return
                end
                if gq and gq.Popup and gq.Popup.container and gq.Popup.container:IsShown() then
                    gq.Popup:Hide()
                end
            end)
        end
    end

    self:EnsureStickWatch()
    if CharacterFrame and CharacterFrame.HookScript and not CharacterFrame.GearQuestStickHooked then
        CharacterFrame.GearQuestStickHooked = true
        CharacterFrame:HookScript("OnShow", function()
            local doll = _G.GearQuest and _G.GearQuest.PaperDoll
            if doll then
                doll:WatchStick()
            end
        end)
        CharacterFrame:HookScript("OnHide", function()
            local doll = _G.GearQuest and _G.GearQuest.PaperDoll
            if doll then
                doll.stickWasDown = false
                if doll.stickWatch then
                    doll.stickWatch:Hide()
                end
            end
        end)
    end
    self:WatchStick()
end
