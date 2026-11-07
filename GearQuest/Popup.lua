local _, GQ = ...
local L = GQ.L

GQ.Popup = GQ.Popup or {}

local MAX_OPTIONS = 3
local ICON_GAP = 4
local SLOT_GAP = 4
local BAR_PAD = 5
local DEFAULT_ICON_SIZE = 37

local function ShowUpgradeTooltip(button)
    if not button.entry then
        return
    end

    local gq = _G.GearQuest
    if gq and gq.Data and gq.Data.ShowEntryItemTooltip then
        gq.Data:ShowEntryItemTooltip(GameTooltip, button, button.entry, "ANCHOR_RIGHT")
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. button.entry.itemId)
        GameTooltip:Show()
    end

    if gq then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(gq:GetSourceLabel(button.entry.sourceType), 1, 1, 1)
        GameTooltip:AddLine(L["Left-click to see more details."], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end
end

local function OpenUpgradeInLog(button)
    if not button or not button.entry then
        return
    end

    local entry = button.entry
    local entryId = entry.id
    local gq = _G.GearQuest
    if not gq or not gq.Log or not gq.Popup or not entryId then
        return
    end

    gq.Popup:Hide()
    gq.Log:Show()
    gq.Log:SelectHunt(entryId, true, entry)
end

local function OnUpgradeIconClick(self, mouseButton)
    if mouseButton == "RightButton" then
        return
    end
    OpenUpgradeInLog(self)
end

local function GetSlotIconSize(slotButton)
    local size = slotButton and math.floor(slotButton:GetWidth() + 0.5) or 0
    if size < 1 then
        size = DEFAULT_ICON_SIZE
    end
    return size
end

local function EnsureCheckmark(icon)
    if icon.checkmark then
        return icon.checkmark
    end

    local mark = icon:CreateTexture(nil, "OVERLAY", nil, 7)
    mark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    mark:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    mark:SetSize(16, 16)
    mark:Hide()
    icon.checkmark = mark
    return mark
end

local function CreateUpgradeIcon(parent, index)
    local btn = CreateFrame("Button", "GearQuestUpgradeIcon" .. index, parent)
    btn:Hide()

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture("Interface\\Buttons\\UI-EmptySlot")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    btn.border:SetTexture("Interface\\Common\\WhiteIconFrame")

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(1, 1, 1, 0.18)

    if btn.RegisterForClicks then
        pcall(function() btn:RegisterForClicks("LeftButtonUp", "RightButtonUp") end)
    end

    btn:SetScript("OnEnter", function(self)
        ShowUpgradeTooltip(self)
    end)

    btn:SetScript("OnLeave", function()
        local gq = _G.GearQuest
        if gq and gq.Data and gq.Data.ClearPendingItemTooltip then
            gq.Data:ClearPendingItemTooltip(GameTooltip)
        end
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", OnUpgradeIconClick)

    EnsureCheckmark(btn)

    return btn
end

function GQ.Popup:WireIconScripts()
    if not self.container or not self.container.icons then
        return
    end

    for i = 1, MAX_OPTIONS do
        local icon = self.container.icons[i]
        if icon then
            EnsureCheckmark(icon)
            if icon.RegisterForClicks then
                icon:RegisterForClicks("LeftButtonUp")
            end
            icon:SetScript("OnEnter", function(self)
                ShowUpgradeTooltip(self)
            end)
            icon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            icon:SetScript("OnClick", OnUpgradeIconClick)
        end
    end
end

function GQ.Popup:HookCharacterFrameHide()
    if not CharacterFrame or not CharacterFrame.HookScript or CharacterFrame.GearQuestOnHideHooked then
        return
    end
    CharacterFrame.GearQuestOnHideHooked = true
    CharacterFrame:HookScript("OnHide", function()
        local popup = _G.GearQuest and _G.GearQuest.Popup
        if popup then
            popup:Hide()
        end
    end)
    if PaperDollFrame and PaperDollFrame.HookScript and not PaperDollFrame.GearQuestOnHideHooked then
        PaperDollFrame.GearQuestOnHideHooked = true
        PaperDollFrame:HookScript("OnHide", function()
            local popup = _G.GearQuest and _G.GearQuest.Popup
            if popup then
                popup:Hide()
            end
        end)
    end
end

function GQ.Popup:EnsureDismissLayer()
    self:HookCharacterFrameHide()
    local parent = CharacterFrame
    if not parent then
        return
    end
    if self.dismissLayer and self.dismissLayer:GetParent() ~= parent then
        self.dismissLayer:Hide()
        self.dismissLayer:SetParent(parent)
        self.dismissLayer:ClearAllPoints()
        self.dismissLayer:SetAllPoints(parent)
    end
    if self.dismissLayer then
        return
    end

    local layer = CreateFrame("Button", "GearQuestPopupDismiss", parent)
    -- Match the character sheet. HIGH + UIParent used to sit over the
    -- profession book and swallow every click while the sheet was closed.
    if parent.GetFrameStrata and layer.SetFrameStrata then
        layer:SetFrameStrata(parent:GetFrameStrata())
    end
    layer:SetAllPoints(parent)
    layer:EnableMouse(true)
    layer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    layer:SetScript("OnMouseDown", function()
        local popup = _G.GearQuest and _G.GearQuest.Popup
        if popup then
            popup:Hide()
        end
    end)
    layer:Hide()
    self.dismissLayer = layer
end

function GQ.Popup:EnsureOutsideCatcher()
    if self.outsideCatcher then
        return
    end

    -- World clicks only. Other windows sit above LOW, and this hides with the bar.
    local catcher = CreateFrame("Button", "GearQuestPopupOutside", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("LOW")
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    catcher:SetScript("OnMouseDown", function()
        local popup = _G.GearQuest and _G.GearQuest.Popup
        if popup then
            popup:Hide()
        end
    end)
    catcher:Hide()
    self.outsideCatcher = catcher
end

function GQ.Popup:ShowDismissLayer()
    if not CharacterFrame or not CharacterFrame:IsShown() then
        if self.dismissLayer then
            self.dismissLayer:Hide()
        end
        if self.outsideCatcher then
            self.outsideCatcher:Hide()
        end
        return
    end
    self:EnsureDismissLayer()
    self:EnsureOutsideCatcher()
    if not self.dismissLayer or not self.container then
        return
    end

    local sheet = PaperDollFrame or self.dismissLayer:GetParent()
    self.dismissLayer:ClearAllPoints()
    self.dismissLayer:SetAllPoints(sheet)

    local skip = {
        [self.dismissLayer] = true,
        [self.container] = true,
    }
    if self.container.bar then
        skip[self.container.bar] = true
        self.container.bar:EnableMouse(true)
    end
    if GQ.Data and GQ.Data.PAPER_DOLL_SLOTS then
        for _, slotName in ipairs(GQ.Data.PAPER_DOLL_SLOTS) do
            local button = _G["Character" .. slotName .. "Slot"]
            if button then
                skip[button] = true
            end
        end
    end

    local function treeTop(frame, best)
        if not frame or skip[frame] then
            return best
        end
        local level = frame.GetFrameLevel and frame:GetFrameLevel() or 0
        if level > best then
            best = level
        end
        if frame.GetChildren then
            local children = { frame:GetChildren() }
            for i = 1, #children do
                best = treeTop(children[i], best)
            end
        end
        return best
    end

    -- Above the model and stats, under the slots and the bar. A catcher
    -- above the slots swallows the click that picks up a worn item.
    local dismissLevel = treeTop(sheet, 0) + 2
    self.dismissLayer:SetFrameLevel(dismissLevel)
    local slotLevel = dismissLevel + 4
    if GQ.Data and GQ.Data.PAPER_DOLL_SLOTS then
        for _, slotName in ipairs(GQ.Data.PAPER_DOLL_SLOTS) do
            local button = _G["Character" .. slotName .. "Slot"]
            if button and button.SetFrameLevel and (button:GetFrameLevel() or 0) < slotLevel then
                button:SetFrameLevel(slotLevel)
            end
        end
    end
    local barLevel = slotLevel + 4
    if (self.container:GetFrameLevel() or 0) < barLevel then
        self.container:SetFrameLevel(barLevel)
    end

    self.dismissLayer:Show()
    if self.outsideCatcher then
        self.outsideCatcher:Show()
    end
end

function GQ.Popup:EnsureItemInfoListener()
    if self.itemInfoListener then
        return
    end

    local refreshFrame = CreateFrame("Frame")
    GQ.RegisterEvent(refreshFrame, "GET_ITEM_INFO_RECEIVED")
    refreshFrame:SetScript("OnEvent", function(_, _, itemId)
        local popup = _G.GearQuest and _G.GearQuest.Popup
        if not popup or not popup.container or not popup.container:IsShown() then
            return
        end

        itemId = tonumber(itemId)
        local relevant = false
        if itemId and popup.currentUpgrades then
            for i = 1, #popup.currentUpgrades do
                local entry = popup.currentUpgrades[i]
                if entry and entry.itemId == itemId then
                    relevant = true
                    break
                end
            end
        end
        if not relevant then
            return
        end

        if popup._itemInfoRefreshScheduled then
            return
        end
        popup._itemInfoRefreshScheduled = true
        local function refresh()
            popup._itemInfoRefreshScheduled = false
            if not popup.container or not popup.container:IsShown() then
                return
            end
            popup:RefreshIcons()
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.2, refresh)
        else
            refresh()
        end
    end)
    self.itemInfoListener = refreshFrame
end

function GQ.Popup:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    self:EnsureItemInfoListener()

    if _G.GearQuestSlotPopup then
        self.container = _G.GearQuestSlotPopup
        self.container.bar = self.container.bar or _G.GearQuestUpgradeBar
        if not self.container.icons then
            self.container.icons = {}
            for i = 1, MAX_OPTIONS do
                self.container.icons[i] = _G["GearQuestUpgradeIcon" .. i]
            end
        end
        self:WireIconScripts()
        self:EnsureDismissLayer()
        return
    end

    local parent = CharacterFrame or UIParent
    local container = CreateFrame("Frame", "GearQuestSlotPopup", parent)
    container:SetFrameStrata("HIGH")
    if CharacterFrame then
        container:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)
    end
    container:Hide()

    local bar = CreateFrame("Frame", "GearQuestUpgradeBar", container)
    bar:Hide()
    if bar.SetBackdrop then
        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        bar:SetBackdropColor(0.05, 0.05, 0.05, 0.88)
        bar:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
    else
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.88)
    end

    container.bar = bar
    container.icons = {}
    for i = 1, MAX_OPTIONS do
        container.icons[i] = CreateUpgradeIcon(bar, i)
    end

    self.container = container
    self.activeSlotName = nil
    self.activeSlotButton = nil
    self.pendingItemIds = {}

    self:WireIconScripts()
    self:HookCharacterFrameHide()
    self:EnsureDismissLayer()
end

function GQ.Popup:PositionBar(slotButton, count)
    local iconSize = GetSlotIconSize(slotButton)
    local barWidth = (BAR_PAD * 2) + (count * iconSize) + ((count - 1) * ICON_GAP)
    local barHeight = iconSize + (BAR_PAD * 2)

    self.container.bar:SetSize(barWidth, barHeight)
    -- Bar sits to the right of the slot; icons read left -> right (best first).
    self.container.bar:ClearAllPoints()
    self.container.bar:SetPoint("LEFT", slotButton, "RIGHT", SLOT_GAP, 0)

    for i = 1, MAX_OPTIONS do
        local icon = self.container.icons[i]
        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        if i <= count then
            local x = BAR_PAD + (i - 1) * (iconSize + ICON_GAP)
            icon:SetPoint("TOPLEFT", self.container.bar, "TOPLEFT", x, -BAR_PAD)
        end
    end
end

function GQ.Popup:UpdateObtainCheckmark(icon, entry)
    if not icon then
        return
    end

    local mark = EnsureCheckmark(icon)
    local obtained = entry and GQ.Log and GQ.Log:IsEntryObtained(entry.id)
    if obtained then
        local iconSize = icon:GetWidth() or DEFAULT_ICON_SIZE
        mark:SetSize(math.max(14, math.floor(iconSize * 0.42)), math.max(14, math.floor(iconSize * 0.42)))
        mark:Show()
    else
        mark:Hide()
    end
end

function GQ.Popup:ApplyIconData(icon, entry)
    icon.entry = entry

    local texture = GQ.Equip and GQ.Equip.GetItemIconTexture and GQ.Equip:GetItemIconTexture(entry.itemId)
    if not texture then
        texture = select(10, GetItemInfo(entry.itemId))
    end

    icon.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    local quality = GQ.Data and GQ.Data.GetItemQualityForDisplay and GQ.Data:GetItemQualityForDisplay(entry.itemId)
    local r, g, b
    if quality then
        r, g, b = GetItemQualityColor(quality)
    else
        r, g, b = 1, 0.82, 0
    end
    icon.icon:SetVertexColor(1, 1, 1)
    icon.border:SetVertexColor(r, g, b)
    self:UpdateObtainCheckmark(icon, entry)
end

function GQ.Popup:RefreshIcons()
    if not self.container:IsShown() or not self.currentUpgrades then
        return
    end

    for i, entry in ipairs(self.currentUpgrades) do
        local icon = self.container.icons[i]
        if icon and icon:IsShown() then
            self:ApplyIconData(icon, entry)
        end
    end
end

function GQ.Popup:Hide()
    if self.dismissLayer then
        self.dismissLayer:Hide()
    end
    if self.outsideCatcher then
        self.outsideCatcher:Hide()
    end
    if not self.container then
        return
    end

    self.container:Hide()
    self.container.bar:Hide()
    for i = 1, MAX_OPTIONS do
        self.container.icons[i]:Hide()
        self.container.icons[i].entry = nil
        if self.container.icons[i].checkmark then
            self.container.icons[i].checkmark:Hide()
        end
    end
    self.activeSlotName = nil
    self.activeSlotButton = nil
    self.currentUpgrades = nil
    self.pendingItemIds = {}
end

function GQ.Popup:ShowForSlot(slotName, slotButton)
    if not self.container then
        return
    end

    slotName = GQ.Data:NormalizeSlotName(slotName)
    local slotLabel = GQ.Data:SlotLabel(slotName)
    local upgrades
    if GQ.Log and GQ.Log.UsesWideHuntList and GQ.Log:UsesWideHuntList() then
        upgrades = GQ.Log:GetFilteredTopForSlot(slotName)
    else
        upgrades = GQ.Data:GetTopUpgradesForSlot(slotName, MAX_OPTIONS)
    end

    if #upgrades == 0 then
        self:Hide()
        local hint = GQ:IsPreviewEnabled() and "" or L[" Try |cff00ff00/gq set|r to configure class, level, and faction."]
        GQ:Chat("|cff66ccffGearQuest|r: " .. string.format(L["No upgrade hunts found for %s."], slotLabel) .. hint)
        return
    end

    self.activeSlotName = slotName
    self.activeSlotButton = slotButton
    self.currentUpgrades = upgrades
    self.pendingItemIds = {}

    self:PositionBar(slotButton, #upgrades)

    for i = 1, MAX_OPTIONS do
        local icon = self.container.icons[i]
        local entry = upgrades[i]
        if entry then
            self:ApplyIconData(icon, entry)
            icon:Show()
        else
            icon.entry = nil
            icon:Hide()
        end
    end

    self.container.bar:Show()
    self.container:SetFrameLevel((CharacterFrame and CharacterFrame:GetFrameLevel() or 0) + 10)
    self.container:Show()
    self:ShowDismissLayer()
end

function GQ.Popup:Toggle()
    if self.container:IsShown() then
        self:Hide()
    end
end
