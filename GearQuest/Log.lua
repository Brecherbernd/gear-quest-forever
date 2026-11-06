local ADDON_NAME, GQ = ...

GQ.Log = GQ.Log or {}

local FRAME_WIDTH = 768
local FRAME_HEIGHT = 512
local ROW_HEIGHT = 16
-- A hunt is two of those lines: the name, then the notes.
local TAB_HEIGHT = 24
local TAB_BAR_PAD = 4
local TAB_ROW_HEIGHT = TAB_HEIGHT + TAB_BAR_PAD
local CONTEXT_BAND_HEIGHT = 46
local CONTEXT_BAND_TOP = -27
local TAB_TOP_OFFSET = 56 + CONTEXT_BAND_HEIGHT
local PORTRAIT_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GearQuest-Portrait"
local PORTRAIT_DISPLAY_SIZE = 61
local PORTRAIT_OFFSET_X = -6
local PORTRAIT_OFFSET_Y = 7

-- Track and Show on map sit inside the description. Remove sits to the right of those.
-- A removed hunt's parchment shows Restore only. Exit sits in the footer on every tab.
local HEADER_OFFSET = 74
local FOOTER_OFFSET = 42
local FOOTER_BUTTON_Y = 14
local DETAIL_BUTTON_BAND = 36
local CONTENT_LEFT = 14
local CONTENT_RIGHT_GUTTER = 14
local COLUMN_GAP = 8
local USABLE_WIDTH = FRAME_WIDTH - CONTENT_LEFT - CONTENT_RIGHT_GUTTER
local LEFT_COLUMN_WIDTH = math.floor((USABLE_WIDTH - COLUMN_GAP) / 2)
local RIGHT_COLUMN_WIDTH = USABLE_WIDTH - COLUMN_GAP - LEFT_COLUMN_WIDTH
local PANEL_WIDTH = LEFT_COLUMN_WIDTH
local PANEL_INSET = 4
local GUTTER_INSET = 6
local PAGE_TAB_LOG_WIDTH = 108
local PAGE_TAB_SIM_WIDTH = 92
local FILTER_TAB_WIDTH = 84
local PAGE_GROUP_WIDTH = PAGE_TAB_LOG_WIDTH + PAGE_TAB_SIM_WIDTH + 4
local FILTER_TAB_OVERLAP = 3
local FILTER_TAB_LEFT = 12
-- Status band lives on the main frame above logPage; tabs still sit on the list edge.
local LOG_SECTION_TOP = -(TAB_HEIGHT - FILTER_TAB_OVERLAP)
local SIDE_TAB_HEIGHT = 53
local SIDE_TAB_WIDTH = 53
local SIDE_TAB_OVERLAP = 8
local SIDE_TAB_GAP = 10
local SIDE_TAB_ICON_SIZE = 36
local SIDE_TAB_ICON_PAD = 8
local SIDE_TAB_TOP = -(TAB_TOP_OFFSET - LOG_SECTION_TOP)
local TAB_BORDER_EDGE = 12
local FILTER_BORDER_EDGE = 8
local HANDLE_ART = {
    log = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-Handle-Log.png",
    simulator = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-Handle-Simulator.png",
    settings = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-Handle-Settings.png",
    lookup = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-Handle-Lookup.png",
    glow = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-Handle-InnerGlow.png",
}
local SECTION_DIVIDER_HEIGHT = 3
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local GOLD = { 0.90, 0.75, 0.28 }
local GOLD_DIM = { 0.55, 0.45, 0.22 }
local FRAME_METAL = { 0.78, 0.72, 0.58 }
local FRAME_METAL_DIM = { 0.42, 0.38, 0.30 }
local PANEL_BG = { 0.14, 0.10, 0.06, 1 }
local LIST_BG = { 0.02, 0.02, 0.02, 1 }
local WHEEL_STEP = ROW_HEIGHT * 4
GQ.Log.ITEM_ROW_HEIGHT = ROW_HEIGHT * 2
GQ.Log.HUNT_ICON_SIZE = 28
GQ.Log.HUNT_ROW_GAP = 4
local REWARD_ICON_SIZE = 44
local REWARD_NAME_MIN_WIDTH = 150
local REWARD_NAME_TEXT_PAD = 18

local function TruncateFontStringToWidth(fontString, text, maxWidth)
    text = text and tostring(text) or ""
    fontString:SetText(text)
    if text == "" then
        return text
    end

    if (fontString:GetStringWidth() or 0) <= maxWidth then
        return text
    end

    local ellipsis = "..."
    for len = #text - 1, 1, -1 do
        local candidate = text:sub(1, len) .. ellipsis
        fontString:SetText(candidate)
        if (fontString:GetStringWidth() or 0) <= maxWidth then
            return candidate
        end
    end

    fontString:SetText(ellipsis)
    return ellipsis
end

local LIST_ROW_RIGHT_PAD = 6
local LIST_ROW_ITEM_LEFT = 20
local LIST_ROW_NOTABLE_LEFT = 24
local LIST_NEW_LABEL = " |cffFFD200New|r"
local LIST_TOOLTIP_X_GAP = 20
local NOTABLE_LIST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local SCROLLBAR_WIDTH = 18
local SCROLLBAR_INSET = SCROLLBAR_WIDTH + 8

local function SafeGetItemIcon(itemId)
    if not itemId then
        return nil
    end
    if GQ.Equip and GQ.Equip.GetItemIconTexture then
        return GQ.Equip:GetItemIconTexture(itemId)
    end
    if type(GetItemIcon) == "function" then
        return GetItemIcon(itemId)
    end
    return select(10, GetItemInfo(itemId))
end

local function GetListRowTextMaxWidth(row, leftInset)
    local width = row:GetWidth()
    if not width or width <= 0 then
        width = LEFT_COLUMN_WIDTH - (PANEL_INSET * 2)
    end
    return math.max(40, width - leftInset - LIST_ROW_RIGHT_PAD)
end

local function ApplyHuntRowHighlight(tex)
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetVertexColor(1, 1, 1, 1)
    local leftR, leftG, leftB, leftA = 0.28, 0.22, 0.08, 0.55
    local applied = false
    if tex.SetGradient and CreateColor then
        applied = pcall(tex.SetGradient, tex, "HORIZONTAL",
            CreateColor(leftR, leftG, leftB, leftA),
            CreateColor(leftR, leftG, leftB, 0))
    end
    if not applied and tex.SetGradientAlpha then
        applied = pcall(tex.SetGradientAlpha, tex, "HORIZONTAL",
            leftR, leftG, leftB, leftA,
            leftR, leftG, leftB, 0)
    end
    if not applied then
        tex:SetColorTexture(leftR, leftG, leftB, leftA)
    end
end

local function IsListRowHighlightable(rowType)
    return rowType == "item" or rowType == "notable"
end

local function UpdateListRowHighlight(row)
    if not row or not row.highlight then
        return
    end
    if not IsListRowHighlightable(row.rowType) then
        row.highlight:Hide()
        return
    end

    local log = _G.GearQuest and _G.GearQuest.Log
    local selected = log and row.entry and row.entry.id and row.entry.id == log.selectedHuntId
    if selected or row:IsMouseOver() then
        row.highlight:Show()
    else
        row.highlight:Hide()
    end
end

local function AnchorListRow(row, scrollChild, scroll, yOffset)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    if scroll then
        row:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
    else
        row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    end
end

local function GetListItemQualityColor(itemId)
    if not itemId then
        return 1, 0.82, 0
    end

    local quality = GQ.Data and GQ.Data.GetItemQualityForDisplay and GQ.Data:GetItemQualityForDisplay(itemId)
    if not quality then
        return 1, 0.82, 0
    end
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c then
        return c.r, c.g, c.b
    end
    return GetItemQualityColor(quality)
end

local function PrimeListEntryItemInfo(entry)
end

local function BuildListItemTags(entry, status, includeNewLabel, slotName)
    local tags = ""

    if entry and entry.origin == "guide" then
        tags = tags .. " |cff88ccff(Guide)|r"
    end

    if entry and entry.setPiece then
        tags = tags .. " |cff88ccff(Set piece)|r"
    end

    if includeNewLabel and entry and GQ.Data:IsEntryNewForPlayer(entry) then
        tags = tags .. LIST_NEW_LABEL
    end

    if status == "tracked" then
        tags = tags .. " |cff00ff00(Tracked)|r"
    end

    return tags
end

local function FormatListItemText(fontString, name, entry, status, includeNewLabel, maxWidth, r, g, b, slotName)
    local tags = BuildListItemTags(entry, status, includeNewLabel, slotName)

    fontString:SetText(tags)
    local tagsWidth = fontString:GetStringWidth() or 0
    local nameMaxWidth = math.max(20, maxWidth - tagsWidth)

    TruncateFontStringToWidth(fontString, name, nameMaxWidth)
    local truncatedName = fontString:GetText() or name

    local hex = string.format("%02x%02x%02x",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
    return "|cff" .. hex .. truncatedName .. "|r" .. tags
end

local function SetListRowItemText(row, leftInset, name, entry, status, showNewLabel, r, g, b, slotName, extraRight)
    local maxWidth = GetListRowTextMaxWidth(row, leftInset) - (extraRight or 0)
    if maxWidth < 20 then
        maxWidth = 20
    end
    local text = FormatListItemText(row.text, name, entry, status, showNewLabel, maxWidth, r, g, b, slotName)
    row.text:SetText(text)
    row.text:SetTextColor(1, 1, 1)
end

local SPEC_PICKER_WIDTH = 228
local SPEC_PICKER_ROW_HEIGHT = 20
local SPEC_PICKER_PAD = 4
local SPEC_ICON_SIZE = 22
local SPEC_ARROW_SIZE = 30
local SPEC_CONTROL_GAP = 2
local SPEC_LABEL_WIDTH = 130
local SPEC_CONTROL_WIDTH = SPEC_LABEL_WIDTH + SPEC_CONTROL_GAP + SPEC_ICON_SIZE + SPEC_CONTROL_GAP + SPEC_ARROW_SIZE
local SPEC_CONTROL_HEIGHT = math.max(SPEC_ICON_SIZE, SPEC_ARROW_SIZE)
local SPEC_ROW_GAP = 2
local LOG_FRAME_STRATA = "DIALOG"
local LOG_FRAME_LEVEL = 100

local function SafeRegisterForClicks(frame, ...)
    if not frame or type(frame.RegisterForClicks) ~= "function" then
        return
    end
    pcall(frame.RegisterForClicks, frame, ...)
end

local function ApplyLogWindowLayer(frame)
    if not frame then
        return
    end

    if frame.SetFrameStrata then
        frame:SetFrameStrata(LOG_FRAME_STRATA)
    end
    if frame.SetFrameLevel then
        frame:SetFrameLevel(LOG_FRAME_LEVEL)
    end
end

local function BringLogWindowToFront(frame)
    ApplyLogWindowLayer(frame)
    if frame and frame.Raise then
        frame:Raise()
    end
    local log = _G.GearQuest and _G.GearQuest.Log
    if log and log.LayoutSideTabs then
        log:LayoutSideTabs(frame)
    end
end
local TAB_GROUP_WIDTH = (88 * 2) + 4
local DETAIL_TEXT_COLOR = { 0, 0, 0 }
local LORE_TEXT_COLOR = { 0, 0, 0 }
-- Same faces as the quest log: QuestTitleFont for the title and
-- DESCRIPTION/REWARD headers, QuestFont for the paragraph.
local QUEST_DETAIL_TITLE_FONTS = {
    "QuestTitleFont", "QuestFont_Super_Huge", "QuestFont_Huge", "QuestFont_Large",
}

local QUEST_DETAIL_HEADER_FONTS = {
    "QuestTitleFont", "QuestFont_Large", "QuestFont",
}

local QUEST_DETAIL_BODY_FONTS = {
    "QuestFont", "QuestFontNormalSmall", "QuestFont_Large",
}

local function CopyProgressMap(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            local row = {}
            for rk, rv in pairs(v) do
                row[rk] = rv
            end
            out[k] = row
        else
            out[k] = v
        end
    end
    return out
end

local function EnsureProgressTables(db)
    db.hunts = db.hunts or {}
    db.obtained = db.obtained or {}
    db.obtainedItems = db.obtainedItems or {}
    db.crafted = db.crafted or {}
    return db
end

local function CharProgress()
    if type(GearQuestForeverCharDB) ~= "table" then
        GearQuestForeverCharDB = {}
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
    local guid = UnitGUID and UnitGUID("player")
    if GearQuestForeverCharDB.progressReady then
        return EnsureProgressTables(GearQuestForeverCharDB)
    end
    if not guid then
        return EnsureProgressTables(GearQuestForeverCharDB)
    end
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    if not GearQuestForeverDB.settings.completedClaimedBy then
        GearQuestForeverCharDB.hunts = CopyProgressMap(GearQuestForeverDB.hunts)
        GearQuestForeverCharDB.obtained = CopyProgressMap(GearQuestForeverDB.obtained)
        GearQuestForeverCharDB.obtainedItems = CopyProgressMap(GearQuestForeverDB.obtainedItems)
        GearQuestForeverCharDB.crafted = CopyProgressMap(GearQuestForeverDB.crafted)
        GearQuestForeverDB.settings.completedClaimedBy = guid
    end
    GearQuestForeverCharDB.progressReady = true
    return EnsureProgressTables(GearQuestForeverCharDB)
end

function GQ.Log:CharProgress()
    return CharProgress()
end

local function GetHuntRecord(id)
    local db = CharProgress()
    return db.hunts[id]
end

local function GetObtainedTimestamp(id)
    local db = CharProgress()
    return db.obtained[id]
end

local function IsDismissedCompleted(id)
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
    return GearQuestForeverDB.dismissedCompleted[id] == true
end

local function EnsureHuntRecord(id)
    local db = CharProgress()
    if not db.hunts[id] then
        db.hunts[id] = {
            status = "tracked",
            trackedAt = time(),
        }
    end
    return db.hunts[id]
end

local function NormalizeHuntStatus(status)
    if status == "active" then
        return "tracked"
    end
    return status
end

local function GetHuntStatus(id)
    local record = GetHuntRecord(id)
    if not record then
        return "available"
    end
    return NormalizeHuntStatus(record.status or "tracked")
end

local function FormatCompletedDate(timestamp)
    if not timestamp then
        return nil
    end
    if date then
        return date("%B %d, %Y at %H:%M", timestamp)
    end
    return tostring(timestamp)
end

local function ItemLinkToId(link)
    if not link then
        return nil
    end
    local ok, id = pcall(function()
        return tonumber(link:match("item:(%d+)"))
    end)
    if not ok then
        return nil
    end
    return id
end

local function GetBagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
end

local function GetBagSlotCount(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function PlayerOwnsItem(itemId)
    if not itemId then
        return false
    end

    local ok, owned = pcall(function()
        for invSlot = 1, 19 do
            if ItemLinkToId(GetInventoryItemLink("player", invSlot)) == itemId then
                return true
            end
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                if ItemLinkToId(GetBagItemLink(bag, slot)) == itemId then
                    return true
                end
            end
        end

        return false
    end)

    return ok and owned or false
end

local function GetCraftedTimestamp(itemId)
    local db = CharProgress()
    return db.crafted[itemId] or db.crafted[tostring(itemId)]
end

local function ExtractItemIdFromChatMessage(msg)
    if not msg then
        return nil
    end
    -- Forever marks some loot/craft lines as secret. Reading them from addon
    -- code errors instead of returning the text.
    if issecretvalue and issecretvalue(msg) then
        return nil
    end

    -- Only the local player's craft/loot lines — never party loot chat with item links.
    if msg:find("You create", 1, true) then
        local itemId = tonumber(msg:match("item:(%d+)"))
        if itemId then
            return itemId
        end

        local itemName = msg:match("You create %[(.-)%]")
            or msg:match("You create (.+)%.")
        if not itemName then
            return nil
        end

        itemName = strtrim(itemName)

        for _, entry in ipairs(GQ.Data.entries) do
            if entry.sourceType == "profession" and entry.itemId then
                local name = (GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(entry.itemId))
                    or GetItemInfo(entry.itemId)
                if name == itemName then
                    return entry.itemId
                end
            end
        end

        return nil
    end

    if msg:find("You receive loot", 1, true) or msg:find("You loot", 1, true) then
        return tonumber(msg:match("item:(%d+)"))
    end

    return nil
end

local function PlayerHasProducedProfessionItem(entry)
    if not entry or entry.sourceType ~= "profession" or not entry.itemId then
        return false
    end
    return GetCraftedTimestamp(entry.itemId) ~= nil
end

local function PlayerHasObtainedEntryItem(entry)
    if not entry then
        return false
    end

    if entry.sourceType == "profession" then
        if PlayerHasProducedProfessionItem(entry) then
            return true
        end
        return GQ.Data:PlayerOwnsEntryItem(entry)
    end

    return GQ.Data:PlayerOwnsEntryItem(entry)
end

local function HideEquippedCompare()
    for i = 1, 2 do
        local tip = _G["ShoppingTooltip" .. i]
        if tip then
            tip:Hide()
        end
    end
end

local function ShowEquippedCompare(entry)
    HideEquippedCompare()
    if not entry or not entry.slot or not GQ.Data or not GQ.Data.GetInventorySlots then
        return
    end
    if not GetInventoryItemLink then
        return
    end

    local tips = {}
    for _, invSlot in ipairs(GQ.Data:GetInventorySlots(entry.slot)) do
        if #tips >= 2 then
            break
        end
        if GetInventoryItemLink("player", invSlot) then
            local tip = _G["ShoppingTooltip" .. (#tips + 1)]
            if tip and tip.SetInventoryItem then
                tip:SetOwner(GameTooltip, "ANCHOR_NONE")
                tip:SetInventoryItem("player", invSlot)
                tip:AddLine("Currently equipped", 1, 0.82, 0)
                tip:Show()
                tips[#tips + 1] = tip
            end
        end
    end

    if #tips == 0 then
        return
    end

    local totalWidth = 0
    for i = 1, #tips do
        totalWidth = totalWidth + (tips[i]:GetWidth() or 0)
    end
    local tooltipRight = GameTooltip:GetRight() or 0
    local screenRight = (UIParent and UIParent:GetRight()) or tooltipRight
    local placeRight = (tooltipRight + totalWidth) <= (screenRight - 8)
    local point, relative, x = "TOPLEFT", "TOPRIGHT", 0
    if not placeRight then
        point, relative, x = "TOPRIGHT", "TOPLEFT", 0
    end

    local anchor = GameTooltip
    for i = 1, #tips do
        tips[i]:ClearAllPoints()
        tips[i]:SetPoint(point, anchor, relative, x, 0)
        anchor = tips[i]
    end
end

local function ShowItemTooltipForRow(row)
    if GQ.Log and GQ.Log.HideSlotRankPanel then
        GQ.Log:HideSlotRankPanel()
    end
    if not row or not row.entry or not GQ.Data then
        return
    end

    GameTooltip.gqSkipScoreHook = true
    GameTooltip.gqScoreLineAdded = nil
    GameTooltip.gqEnchantAdded = nil
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GQ.Data:PopulateEntryItemTooltip(GameTooltip, row.entry)

    local textTop = row.text and row.text:GetTop()
    local textBottom = row.text and row.text:GetBottom()
    local textLeft = row.text and row.text:GetLeft()
    local textWidth = row.text and row.text:GetStringWidth()
    if textTop and textBottom then
        local textCenterY = (textTop + textBottom) / 2
        local anchorX = row:GetRight()
        if not anchorX and textLeft and textWidth then
            anchorX = textLeft + textWidth
        end
        if anchorX then
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint("LEFT", UIParent, "BOTTOMLEFT", anchorX + LIST_TOOLTIP_X_GAP, textCenterY)
        end
    end

    if row.entry.itemId and GQ.Data.ApplyImbueTooltipLines then
        GQ.Data:ApplyImbueTooltipLines(GameTooltip, row.entry.itemId)
    end
    if GQ.Data.AppendGearScoreLine then
        GQ.Data:AppendGearScoreLine(GameTooltip, row.entry)
    end
    GameTooltip:Show()
    if GQ.Data.SolidItemTooltip then
        GQ.Data:SolidItemTooltip(GameTooltip)
    end
    GameTooltip.gqSkipScoreHook = nil
    ShowEquippedCompare(row.entry)
end

local function HideItemTooltip()
    HideEquippedCompare()
    if GQ.Data and GQ.Data.ClearPendingItemTooltip then
        GQ.Data:ClearPendingItemTooltip(GameTooltip)
    end
    GameTooltip:Hide()
end

local function TryHandleModifiedItemClick(entry)
    if not entry or not entry.itemId or not IsModifiedClick or not IsModifiedClick() then
        return false
    end

    local link = GQ.Data and GQ.Data.GetEntryItemHyperlink and GQ.Data:GetEntryItemHyperlink(entry)
        or select(2, GetItemInfo(entry.itemId))
        or ("item:" .. entry.itemId)

    if HandleModifiedItemClick then
        local handled = HandleModifiedItemClick(link)
        if handled then
            return true
        end
    end

    if IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
        return true
    end

    if IsModifiedClick("DRESSUP") then
        if DressUpItemLink then
            DressUpItemLink(link)
            return true
        end
        if DressUpFrame and DressUpFrame_Show then
            DressUpFrame_Show(DressUpFrame)
            if DressUpFrameModel and DressUpFrameModel.TryOn then
                DressUpFrameModel:TryOn(link)
                return true
            end
        end
    end

    return false
end

local function OnListRowItemClick(entry)
    if not entry or not entry.id then
        return
    end

    if entry.itemId and TryHandleModifiedItemClick(entry) then
        HideItemTooltip()
        return
    end

    local log = _G.GearQuest and _G.GearQuest.Log
    if log then
        log:SelectHunt(entry.id, false, entry)
    end
end

local function CreateRewardItemButton(parent, name)
    local button = CreateFrame("Button", name, parent)
    button:SetHeight(REWARD_ICON_SIZE)
    button:SetWidth(REWARD_ICON_SIZE + REWARD_NAME_MIN_WIDTH)

    local iconFrame = CreateFrame("Frame", nil, button)
    iconFrame:SetSize(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
    iconFrame:SetPoint("LEFT", button, "LEFT", 0, 0)
    iconFrame:EnableMouse(false)

    button.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(iconFrame)

    local foreverMark = CreateFrame("Frame", nil, button)
    foreverMark:SetSize(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
    foreverMark:SetPoint("LEFT", button, "RIGHT", 12, 0)
    foreverMark:EnableMouse(true)
    foreverMark:Hide()
    local foreverTex = foreverMark:CreateTexture(nil, "ARTWORK")
    foreverTex:SetAllPoints()
    foreverTex:SetTexture("Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-ForeverMark.png")
    foreverMark:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("New in Forever")
        GameTooltip:Show()
    end)
    foreverMark:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button.foreverMark = foreverMark

    button.nameBg = button:CreateTexture(nil, "BACKGROUND")
    button.nameBg:SetPoint("LEFT", iconFrame, "RIGHT", 0, 0)
    button.nameBg:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    button.nameBg:SetPoint("TOP", button, "TOP", 0, 0)
    button.nameBg:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
    button.nameBg:SetColorTexture(0, 0, 0, 0.68)

    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.name:SetPoint("LEFT", button.nameBg, "LEFT", 8, 0)
    button.name:SetPoint("RIGHT", button.nameBg, "RIGHT", -10, 0)
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(false)
    button.name:SetTextColor(1, 1, 1)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnEnter", function(self)
        if not self.entry and not self.itemId then
            return
        end
        local entry = self.entry or { itemId = self.itemId }
        if GQ.Data and GQ.Data.ShowEntryItemTooltip then
            GQ.Data:ShowEntryItemTooltip(GameTooltip, self, entry, "ANCHOR_RIGHT")
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemId)
            GameTooltip:Show()
        end
        ShowEquippedCompare(entry)
    end)

    button:SetScript("OnLeave", function()
        HideItemTooltip()
    end)

    button:SetScript("OnClick", function(self)
        local entry = self.entry or (self.itemId and { itemId = self.itemId })
        if entry and TryHandleModifiedItemClick(entry) then
            HideItemTooltip()
        end
    end)

    return button
end

local function CreateFontStringWithFallback(parent, candidates)
    for _, font in ipairs(candidates) do
        local ok, created = pcall(parent.CreateFontString, parent, nil, "ARTWORK", font)
        if ok and created then
            return created
        end
    end
    return parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
end

local PARCHMENT_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Textures\\GQ-Parchment.png"
local SHAMAN_LOG_SCENE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-LogScene-Shaman.png"
local SHAMAN_LOG_VIGNETTE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-LogScene-Vignette.png"
local SHAMAN_LIST_SHADE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-ListShade.png"
local SHAMAN_PARCHMENT_ALPHA = 0.72

local function LogSceneArt(file)
    return "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\" .. file
end

local function ApplyParchmentBackground(parent)
    if parent.parchmentApplied then
        return
    end
    parent.parchmentApplied = true

    local parchment = parent:CreateTexture(nil, "BACKGROUND", nil, 0)
    parchment:SetTexture(PARCHMENT_TEXTURE)
    parchment:SetAllPoints()
    parent.gqParchment = parchment
    -- Stretch once so clean top/left and worn bottom/right stay anchored to the panel.
end

local function ApplyFill(parent, color)
    if not parent.blackBg then
        local bg = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        parent.blackBg = bg
    end
    parent.blackBg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function ApplyBlackBackground(parent)
    ApplyFill(parent, LIST_BG)
end

local function ApplyPanelBackground(parent)
    ApplyFill(parent, PANEL_BG)
end

local function EnsureBackdrop(frame)
    if not frame then
        return false
    end
    if frame.SetBackdrop then
        return true
    end
    if Mixin and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropLoaded then
            pcall(frame.OnBackdropLoaded, frame)
        end
    end
    return frame.SetBackdrop ~= nil
end

local function ApplyDrawnGoldBorder(frame)
    if frame.gqBorderTop then
        return
    end
    local function makeEdge()
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.95)
        return tex
    end
    frame.gqBorderTop = makeEdge()
    frame.gqBorderTop:SetHeight(1)
    frame.gqBorderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.gqBorderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.gqBorderBottom = makeEdge()
    frame.gqBorderBottom:SetHeight(1)
    frame.gqBorderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.gqBorderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.gqBorderLeft = makeEdge()
    frame.gqBorderLeft:SetWidth(1)
    frame.gqBorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.gqBorderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.gqBorderRight = makeEdge()
    frame.gqBorderRight:SetWidth(1)
    frame.gqBorderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.gqBorderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

local function ApplyMetalEdge(frame, edgeSize)
    if not frame then
        return
    end
    if not EnsureBackdrop(frame) then
        ApplyDrawnGoldBorder(frame)
        return
    end
    frame:SetBackdrop({
        edgeFile = METAL_EDGE,
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize or 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    end
end

local function HideRegion(obj)
    if obj and obj.Hide then
        obj:Hide()
    end
end

local SetupQuestLogPortrait

local function HideDefaultFrameArt(frame)
    if not frame then
        return
    end

    -- Keep PortraitFrame metal (NineSlice) and the circular portrait well.
    -- Strip only interior fills so the panel can be tinted warmer.
    for _, key in ipairs({
        "Bg", "TitleBg", "TopTileStreaks", "Inset",
    }) do
        HideRegion(frame[key])
    end

    local name = frame.GetName and frame:GetName()
    if name then
        for _, suffix in ipairs({
            "TitleBg", "Bg", "TopTileStreaks", "Inset",
        }) do
            HideRegion(_G[name .. suffix])
        end
    end

    if frame.gqBookIcon then
        frame.gqBookIcon:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end
    if frame.gqOuterBorder then
        frame.gqOuterBorder:Hide()
    end
end

local PORTRAIT_NINESLICE_LAYOUTS = {
    "PortraitFrameTemplate",
    "PortraitFrameTemplateMinimizable",
}

local function HideNineSliceCenter(container)
    if container and container.Center then
        container.Center:SetAlpha(0)
        HideRegion(container.Center)
    end
end

local function TryApplyPortraitFrameLayout(container)
    if not container or not NineSliceUtil then
        return false
    end
    local apply = NineSliceUtil.ApplyLayout
    local applyByName = NineSliceUtil.ApplyLayoutByName
    if not apply and not applyByName then
        return false
    end

    for _, layoutName in ipairs(PORTRAIT_NINESLICE_LAYOUTS) do
        if applyByName then
            local ok = pcall(applyByName, container, layoutName)
            if ok then
                HideNineSliceCenter(container)
                return true
            end
        end
        if apply and NineSliceLayouts and NineSliceLayouts[layoutName] then
            local ok = pcall(apply, container, NineSliceLayouts[layoutName])
            if ok then
                HideNineSliceCenter(container)
                return true
            end
        end
    end
    return false
end

local function GetFrameTitle(frame)
    if frame.TitleContainer and frame.TitleContainer.TitleText then
        return frame.TitleContainer.TitleText
    end
    if frame.TitleText then
        return frame.TitleText
    end
    local name = frame.GetName and frame:GetName()
    return name and _G[name .. "TitleText"] or nil
end

local function EnsurePortraitBorderMetal(frame)
    if not frame then
        return
    end

    local ns = frame.NineSlice
    if ns then
        ns:Show()
        if ns.SetFrameLevel then
            -- Above the portrait face so the TopLeftCorner ring matches the window edge.
            ns:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
        end
        local corner = ns.TopLeftCorner
        if corner then
            corner:Show()
            corner:SetAlpha(1)
        end
    end

    if frame.gqPortraitBorderRing then
        frame.gqPortraitBorderRing:Hide()
    end
end

local function GetFrameCloseButton(frame)
    if frame.CloseButton then
        return frame.CloseButton
    end
    local name = frame.GetName and frame:GetName()
    return name and _G[name .. "CloseButton"] or nil
end

local function ApplyOuterWindowBorder(frame)
    if not frame then
        return
    end

    if frame.gqOuterBorder then
        frame.gqOuterBorder:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end

    local ns = frame.NineSlice
    local hasMetal = false
    if ns then
        ns:Show()
        ns:SetFrameLevel((frame:GetFrameLevel() or 1) + 2)
        TryApplyPortraitFrameLayout(ns)
        HideNineSliceCenter(ns)
        hasMetal = ns.TopLeftCorner or ns.TopEdge or ns.LeftEdge
    else
        hasMetal = TryApplyPortraitFrameLayout(frame)
        HideNineSliceCenter(frame)
    end

    if not hasMetal then
        if not frame.gqOuterBorder then
            local ok, created = pcall(CreateFrame, "Frame", nil, frame, "BackdropTemplate")
            frame.gqOuterBorder = (ok and created) or CreateFrame("Frame", nil, frame)
            frame.gqOuterBorder:SetAllPoints(frame)
            frame.gqOuterBorder:EnableMouse(false)
        end
        frame.gqOuterBorder:Show()
        frame.gqOuterBorder:SetFrameLevel((frame:GetFrameLevel() or 1) + 2)
        ApplyMetalEdge(frame.gqOuterBorder, 16)
    end

    EnsurePortraitBorderMetal(frame)

    if frame.OverlayElements and frame.OverlayElements.Show then
        frame.OverlayElements:Show()
    end

    local close = GetFrameCloseButton(frame)
    if close then
        close:SetParent(frame)
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, 1)
        if close.SetFrameLevel then
            close:SetFrameLevel((frame:GetFrameLevel() or 1) + 10)
        end
        close:Show()
    end
end

local function ApplyModernChrome(frame)
    if not frame then
        return
    end

    HideDefaultFrameArt(frame)
    ApplyPanelBackground(frame)
    ApplyOuterWindowBorder(frame)
    if SetupQuestLogPortrait then
        SetupQuestLogPortrait(frame)
    end

    local title = GetFrameTitle(frame)
    if frame.TitleContainer then
        frame.TitleContainer:Show()
        frame.TitleContainer:ClearAllPoints()
        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 58, -1)
        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -1)
        frame.TitleContainer:SetHeight(22)
    end
    if title then
        if frame.TitleContainer then
            title:SetParent(frame.TitleContainer)
            title:ClearAllPoints()
            title:SetPoint("CENTER", frame.TitleContainer, "CENTER", 0, 0)
        else
            title:SetParent(frame)
            title:ClearAllPoints()
            title:SetPoint("TOP", frame, "TOP", 0, -12)
        end
        if title.SetJustifyH then
            title:SetJustifyH("CENTER")
        end
        title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        title:Show()
    end

    if frame.gqHeaderLine then
        frame.gqHeaderLine:Hide()
    end
end

local function StripDefaultButtonArt(btn)
    if not btn then
        return
    end
    local getters = {
        btn.GetNormalTexture,
        btn.GetPushedTexture,
        btn.GetHighlightTexture,
        btn.GetDisabledTexture,
    }
    for _, getter in ipairs(getters) do
        if getter then
            HideRegion(getter(btn))
        end
    end
    local name = btn.GetName and btn:GetName()
    if name then
        for _, part in ipairs({
            "Left", "Middle", "Right",
            "LeftDisabled", "MiddleDisabled", "RightDisabled",
            "HighlightLeft", "HighlightMiddle", "HighlightRight",
        }) do
            HideRegion(_G[name .. part])
        end
    end
end

local function BackdropFrameTemplate()
    if BackdropTemplateMixin then
        return "BackdropTemplate"
    end
    return nil
end

local function HideTabEdges(btn)
    if not btn then
        return
    end
    for _, key in ipairs({ "gqEdgeTop", "gqEdgeBottom", "gqEdgeLeft", "gqEdgeRight" }) do
        if btn[key] then
            btn[key]:Hide()
        end
    end
end

local function EnsureTabChrome(btn)
    if not btn then
        return
    end
    if not btn.gqFill then
        btn.gqFill = btn:CreateTexture(nil, "BACKGROUND")
        btn.gqFill:SetAllPoints()
    end
    if not btn.gqOpenCover then
        local cover = btn:CreateTexture(nil, "OVERLAY")
        cover:SetDrawLayer("OVERLAY", 7)
        btn.gqOpenCover = cover
    end
    HideTabEdges(btn)
end

local function LayoutOpenCover(btn, opts, fill, edgeSize)
    local cover = btn.gqOpenCover
    if not cover then
        return
    end
    cover:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    cover:ClearAllPoints()
    local coverSize = math.max(3, math.floor(edgeSize * 0.7))
    if opts.hideLeft then
        cover:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        cover:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        cover:SetWidth(coverSize)
        cover:Show()
    elseif opts.hideBottom then
        -- Just inside the side metal, so the opening meets the borders.
        cover:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 0)
        cover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        cover:SetHeight(edgeSize)
        cover:SetDrawLayer("OVERLAY", 5)
        cover:Show()
    else
        cover:Hide()
    end
end

local function LayoutTabChrome(btn, opts)
    if not btn then
        return
    end

    EnsureTabChrome(btn)
    opts = opts or {}
    local fill = opts.fill or LIST_BG
    local border = opts.border or GOLD
    local edgeSize = opts.edgeSize or TAB_BORDER_EDGE
    local thick = opts.thick or 1

    if EnsureBackdrop(btn) then
        if btn.gqFill then
            btn.gqFill:Hide()
        end
        HideTabEdges(btn)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = METAL_EDGE,
            tile = true,
            tileSize = 8,
            edgeSize = edgeSize,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        if btn.SetBackdropColor then
            btn:SetBackdropColor(fill[1], fill[2], fill[3], fill[4] or 1)
        end
        if btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        end
        LayoutOpenCover(btn, opts, fill, edgeSize)
        return
    end

    if btn.gqFill then
        btn.gqFill:Show()
        btn.gqFill:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    end

    local function ensureEdge(key)
        if not btn[key] then
            btn[key] = btn:CreateTexture(nil, "OVERLAY")
        end
        return btn[key]
    end

    local function paint(edge, shown)
        if not edge then
            return
        end
        edge:SetColorTexture(border[1], border[2], border[3], border[4] or 1)
        if shown then
            edge:Show()
        else
            edge:Hide()
        end
    end

    local top = ensureEdge("gqEdgeTop")
    top:ClearAllPoints()
    top:SetHeight(thick)
    top:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    paint(top, not opts.hideTop)

    local bottom = ensureEdge("gqEdgeBottom")
    bottom:ClearAllPoints()
    bottom:SetHeight(thick)
    bottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    paint(bottom, not opts.hideBottom)

    local left = ensureEdge("gqEdgeLeft")
    left:ClearAllPoints()
    left:SetWidth(thick)
    left:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    paint(left, not opts.hideLeft)

    local right = ensureEdge("gqEdgeRight")
    right:ClearAllPoints()
    right:SetWidth(thick)
    right:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    paint(right, not opts.hideRight)

    LayoutOpenCover(btn, opts, fill, thick + 2)
end

local function StyleGoldTab(btn, selected)
    if not btn then
        return
    end

    StripDefaultButtonArt(btn)
    btn:EnableMouse(true)
    if btn.SetEnabled then
        btn:SetEnabled(true)
    end

    if btn.gqTabBg then
        btn.gqTabBg:Hide()
    end
    if btn.gqTabTop then
        btn.gqTabTop:Hide()
    end
    if btn.gqTabBottom then
        btn.gqTabBottom:Hide()
    end

    local fs = btn:GetFontString()
    if not fs then
        fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER")
        btn:SetFontString(fs)
    end
    fs:Show()

    if selected then
        btn:SetHeight(TAB_HEIGHT)
        LayoutTabChrome(btn, {
            fill = LIST_BG,
            border = GOLD,
            hideBottom = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    else
        btn:SetHeight(TAB_HEIGHT)
        LayoutTabChrome(btn, {
            fill = { 0.05, 0.05, 0.05, 1 },
            border = GOLD_DIM,
            hideBottom = false,
            edgeSize = FILTER_BORDER_EDGE,
        })
        fs:SetTextColor(GOLD_DIM[1], GOLD_DIM[2], GOLD_DIM[3])
    end

    if btn.gqOpenMask then
        btn.gqOpenMask:Hide()
    end

    if not btn.gqHover then
        local hover = btn:CreateTexture(nil, "ARTWORK", nil, 6)
        hover:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        hover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        hover:SetBlendMode("BLEND")
        hover:SetColorTexture(0.90, 0.75, 0.28, 0.14)
        hover:Hide()
        btn.gqHover = hover
        btn:HookScript("OnEnter", function(self)
            if self.gqHover then
                self.gqHover:Show()
            end
        end)
        btn:HookScript("OnLeave", function(self)
            if self.gqHover then
                self.gqHover:Hide()
            end
        end)
    end
    -- The open bottom edge sits above ARTWORK. Lift the wash over it, then the label.
    if btn.gqHover then
        btn.gqHover:SetDrawLayer("OVERLAY", 6)
    end
    if fs.SetDrawLayer then
        fs:SetDrawLayer("OVERLAY", 7)
    end
end

local function CreateGoldTab(parent, name, label, width)
    local btn = CreateFrame("Button", name, parent, BackdropFrameTemplate())
    btn:SetSize(width, TAB_HEIGHT)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    btn:SetFontString(fs)
    StyleGoldTab(btn, false)
    return btn
end

local function StyleHandleTab(btn, selected)
    if not btn then
        return
    end

    StripDefaultButtonArt(btn)
    btn:EnableMouse(true)
    if btn.SetEnabled then
        btn:SetEnabled(true)
    end
    btn:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)

    local fs = btn:GetFontString()
    if fs then
        fs:Hide()
    end
    if btn.gqTabBg then
        btn.gqTabBg:Hide()
    end
    if btn.gqTabTop then
        btn.gqTabTop:Hide()
    end
    if btn.gqTabBottom then
        btn.gqTabBottom:Hide()
    end
    if btn.gqTabRight then
        btn.gqTabRight:Hide()
    end

    if btn.gqMetalHost then
        btn.gqMetalHost:Hide()
    end
    if btn.gqHandleFill then
        btn.gqHandleFill:Hide()
    end
    for _, key in ipairs({
        "gqMetalTL", "gqMetalTR", "gqMetalBL", "gqMetalBR",
        "gqMetalTop", "gqMetalBottom", "gqMetalLeft", "gqMetalRight",
    }) do
        if btn[key] then
            btn[key]:Hide()
        end
    end

    if not btn.gqIcon then
        btn.gqIcon = btn:CreateTexture(nil, "OVERLAY")
    end
    btn.gqIcon:SetDrawLayer("OVERLAY", 6)
    btn.gqIcon:ClearAllPoints()
    btn.gqIcon:SetSize(SIDE_TAB_ICON_SIZE, SIDE_TAB_ICON_SIZE)
    btn.gqIcon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    if btn.gqIconPath then
        btn.gqIcon:SetTexture(btn.gqIconPath)
    end
    btn.gqIcon:Show()

    if selected then
        LayoutTabChrome(btn, {
            fill = PANEL_BG,
            border = FRAME_METAL,
            hideLeft = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        btn.gqIcon:SetVertexColor(1, 1, 1, 1)
    else
        LayoutTabChrome(btn, {
            fill = { 0.05, 0.04, 0.03, 1 },
            border = FRAME_METAL,
            hideLeft = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        btn.gqIcon:SetVertexColor(0.55, 0.50, 0.42, 1)
    end

    if not btn.gqEdgeGlow then
        local glow = btn:CreateTexture(nil, "ARTWORK", nil, 4)
        glow:SetAllPoints()
        glow:SetTexture(HANDLE_ART.glow)
        glow:SetBlendMode("BLEND")
        glow:Hide()
        btn.gqEdgeGlow = glow
    end
end

local function CreateHandleTab(parent, name, label, iconPath)
    local btn = CreateFrame("Button", name, parent, BackdropFrameTemplate())
    btn:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
    btn.gqLabel = label
    btn.gqIconPath = iconPath
    StyleHandleTab(btn, false)
    btn:SetScript("OnEnter", function(self)
        if self.gqEdgeGlow then
            self.gqEdgeGlow:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.gqLabel or "", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        if self.gqEdgeGlow then
            self.gqEdgeGlow:Hide()
        end
        GameTooltip:Hide()
    end)
    return btn
end

local function GetScrollRange(scroll)
    if not scroll then
        return 0
    end
    if scroll.GetVerticalScrollRange then
        local range = scroll:GetVerticalScrollRange()
        if range and range > 0 then
            return range
        end
    end
    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if bar and bar.GetMinMaxValues then
        local minVal, maxVal = bar:GetMinMaxValues()
        return math.max(0, (maxVal or 0) - (minVal or 0))
    end
    return 0
end

local function ScrollFrameOnMouseWheel(scroll, delta)
    if not scroll or not scroll.IsShown or not scroll:IsShown() then
        return
    end

    local range = GetScrollRange(scroll)
    if not range or range <= 0 then
        return
    end

    local current = 0
    if scroll.GetVerticalScroll then
        current = scroll:GetVerticalScroll() or 0
    end
    local dest = current - (delta * WHEEL_STEP)
    if dest < 0 then
        dest = 0
    elseif dest > range then
        dest = range
    end

    if scroll.SetVerticalScroll then
        scroll:SetVerticalScroll(dest)
    end

    local log = _G.GearQuest and _G.GearQuest.Log
    if log and log.frame and scroll == log.frame.scroll and log.ClampListRowMouse then
        log:ClampListRowMouse()
    end

    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if bar and bar.SetValue then
        bar:SetValue(dest)
    end
end

local function ApplyScrollBarVisibility(scroll)
    if not scroll then
        return
    end
    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if not bar then
        return
    end
    if GetScrollRange(scroll) > 0 then
        bar:Show()
    else
        if scroll.SetVerticalScroll then
            scroll:SetVerticalScroll(0)
        end
        if bar.SetValue then
            bar:SetValue(0)
        end
        bar:Hide()
    end
end

local function WireLogWindowMouseWheel(frame)
    if not frame or not frame.EnableMouseWheel then
        return
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end
        local page = log:GetPageTab()
        if page == "lookup" then
            if self.detailBg and self.detailBg.IsMouseOver and self.detailBg:IsMouseOver() then
                ScrollFrameOnMouseWheel(self.detailScroll, delta)
            elseif self.lookupInset and self.lookupInset.IsMouseOver and self.lookupInset:IsMouseOver() then
                ScrollFrameOnMouseWheel(self.lookupScroll, delta)
            end
            return
        end
        if page == "simulator" then
            if self.simDetail and self.simDetail.IsMouseOver and self.simDetail:IsMouseOver() then
                ScrollFrameOnMouseWheel(self.simScroll, delta)
            end
            return
        end
        if page ~= "log" then
            return
        end
        if self.detailBg and self.detailBg.IsMouseOver and self.detailBg:IsMouseOver() then
            ScrollFrameOnMouseWheel(self.detailScroll, delta)
        else
            ScrollFrameOnMouseWheel(self.scroll, delta)
        end
    end)
end

local function WireMouseWheel(frame, scroll)
    if not frame or not scroll or not frame.EnableMouseWheel then
        return
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        ScrollFrameOnMouseWheel(scroll, delta)
    end)
end

local function LayoutColumnScroll(scroll, host, bottomPad)
    if not scroll or not host then
        return
    end

    scroll:SetParent(host)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", host, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -(PANEL_INSET + SCROLLBAR_WIDTH + 6), bottomPad or PANEL_INSET)

    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scrollName and _G[scrollName .. "ScrollBar"]
    if bar then
        if bar.gqTrackBg then
            bar.gqTrackBg:Hide()
        end
        -- Keep the bar parented to the scroll frame so UIPanelScrollBar OnValueChanged works.
        if bar.SetFrameLevel then
            bar:SetFrameLevel(scroll:GetFrameLevel() + 5)
        end
        ApplyScrollBarVisibility(scroll)
    end

    if scrollName then
        for _, suffix in ipairs({ "Top", "Bottom", "Middle" }) do
            local tex = _G[scrollName .. suffix]
            if tex and tex.Show then
                tex:Show()
            end
        end
    end

    WireMouseWheel(scroll, scroll)
    WireMouseWheel(host, scroll)
    if scroll.GetScrollChild then
        WireMouseWheel(scroll:GetScrollChild(), scroll)
    end
end

local function CreateSectionDivider(parent)
    local divider = CreateFrame("Frame", nil, parent)
    divider:SetHeight(SECTION_DIVIDER_HEIGHT)

    local top = divider:CreateTexture(nil, "ARTWORK")
    top:SetPoint("TOPLEFT", divider, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", divider, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(0.62, 0.54, 0.36, 1)

    local bottom = divider:CreateTexture(nil, "ARTWORK")
    bottom:SetPoint("BOTTOMLEFT", divider, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", divider, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(0.22, 0.19, 0.14, 1)

    return divider
end

local function EnableClipping(frame)
    if frame and frame.SetClipsChildren then
        frame:SetClipsChildren(true)
    end
end

local function ConfigurePanelScrollBar(scroll)
    if not scroll or not scroll.GetName then
        return
    end

    local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
    if scrollBar then
        if scrollBar.gqTrackBg then
            scrollBar.gqTrackBg:Hide()
        end
        scrollBar:Show()
    end
end

local function LayoutDetailScroll(frame)
    if not frame or not frame.detailScroll or not frame.detailBg then
        return
    end

    LayoutColumnScroll(frame.detailScroll, frame.detailBg, DETAIL_BUTTON_BAND)
    local log = _G.GearQuest and _G.GearQuest.Log
    if log and log.GetPageTab and log:GetPageTab() == "simulator" then
        frame.detailScroll:Hide()
        local bar = frame.detailScroll.GetName and _G[frame.detailScroll:GetName() .. "ScrollBar"]
        if bar then
            bar:Hide()
        end
    else
        frame.detailScroll:Show()
    end
end

local function CreatePanelScrollFrame(name, parent)
    local scrollOk, scroll = pcall(CreateFrame, "ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    if not scrollOk or not scroll then
        scroll = CreateFrame("ScrollFrame", name, parent)
    end

    return scroll
end

local function UpdateScrollChildRect(scroll)
    if not scroll then
        return
    end
    if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    elseif _G.ScrollFrame_UpdateScrollChildRect then
        ScrollFrame_UpdateScrollChildRect(scroll)
    end
end

local function SetFrameTitle(frame, text)
    if frame.TitleText then
        frame.TitleText:SetText(text)
        return
    end
    local title = frame:GetName() and _G[frame:GetName() .. "TitleText"]
    if title then
        title:SetText(text)
    end
end

local function GearQuestWindowTitle()
    local version = (GQ and GQ.VERSION) or ""
    if version == "" then
        return "GearQuest Forever"
    end
    return "GearQuest Forever v" .. version
end

local function GetPortraitTexture(frame)
    if not frame then
        return nil
    end

    if frame.portrait then
        return frame.portrait
    end
    local container = frame.PortraitContainer or (frame.GetName and _G[frame:GetName() .. "PortraitContainer"])
    if container and container.portrait then
        return container.portrait
    end
    if container and container.GetName then
        local named = _G[container:GetName() .. "Portrait"]
        if named then
            return named
        end
    end

    if frame.GetName then
        return _G[frame:GetName() .. "Portrait"]
    end
    return nil
end

local CIRCLE_MASKS = {
    "Interface\\Masks\\CircleMaskScalable",
    "Interface\\CharacterFrame\\TempPortraitAlphaMask",
}

local function CollectPortraitMasks(tex, owner)
    local masks = {}
    local seen = {}
    local function add(mask)
        if mask and not seen[mask] then
            seen[mask] = true
            masks[#masks + 1] = mask
        end
    end
    if owner then
        add(owner.CircleMask)
    end
    add(tex.gqCircleMask)
    local okCount, count = pcall(function()
        return tex.GetNumMaskTextures and tex:GetNumMaskTextures()
    end)
    if okCount and count and tex.GetMaskTexture then
        for i = 1, count do
            local okMask, mask = pcall(tex.GetMaskTexture, tex, i)
            if okMask then
                add(mask)
            end
        end
    end
    return masks
end

local function ApplyCircleMask(tex, owner)
    if not tex then
        return
    end
    if owner and owner.CircleMask and tex.AddMaskTexture then
        pcall(tex.AddMaskTexture, tex, owner.CircleMask)
        return
    end
    if tex.gqCircleMask or (owner and owner.CircleMask) then
        return
    end
    if not owner or not owner.CreateMaskTexture then
        return
    end
    for _, maskPath in ipairs(CIRCLE_MASKS) do
        local mask = owner:CreateMaskTexture()
        mask:SetAllPoints(tex)
        if pcall(mask.SetTexture, mask, maskPath) then
            tex:AddMaskTexture(mask)
            tex.gqCircleMask = mask
            return
        end
        HideRegion(mask)
    end
end

local function ApplyPortraitTexture(tex, texturePath, owner)
    if not tex or not texturePath then
        return
    end

    owner = owner or (tex.GetParent and tex:GetParent())
    local masks = CollectPortraitMasks(tex, owner)
    if tex.RemoveMaskTexture then
        for _, mask in ipairs(masks) do
            pcall(tex.RemoveMaskTexture, tex, mask)
        end
    end

    tex:Show()
    tex:SetTexture(texturePath)
    -- WoW TGA rows are bottom-up; flip V so the portrait is right-side up.
    -- SetTexCoord is illegal while a mask is attached (PortraitFrame CircleMask).
    pcall(tex.SetTexCoord, tex, 0, 1, 1, 0)

    local restored = false
    if tex.AddMaskTexture then
        for _, mask in ipairs(masks) do
            if pcall(tex.AddMaskTexture, tex, mask) then
                restored = true
            end
        end
    end
    if not restored then
        ApplyCircleMask(tex, owner)
    end
end

local function EnsureFallbackPortraitIcon(frame, container)
    if frame.gqPortraitIcon and frame.gqPortraitHolder then
        return frame.gqPortraitIcon, frame.gqPortraitHolder
    end

    local parent = container or frame
    local holder = CreateFrame("Frame", nil, parent)
    local icon = holder:CreateTexture(nil, "ARTWORK")
    frame.gqPortraitHolder = holder
    frame.gqPortraitIcon = icon
    return icon, holder
end

local function PlacePortraitOnFrame(region, frame)
    region:ClearAllPoints()
    region:SetSize(PORTRAIT_DISPLAY_SIZE, PORTRAIT_DISPLAY_SIZE)
    region:SetPoint("TOPLEFT", frame, "TOPLEFT", PORTRAIT_OFFSET_X, PORTRAIT_OFFSET_Y)
    if region.SetFrameLevel and frame.GetFrameLevel then
        -- Under PortraitFrame NineSlice (+3) so the same metal ring shows around the face.
        region:SetFrameLevel(frame:GetFrameLevel() + 1)
    end
    region:Show()
end

function SetupQuestLogPortrait(frame)
    if frame.gqBookIcon then
        frame.gqBookIcon:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end

    local name = frame.GetName and frame:GetName()
    local container = frame.PortraitContainer or (name and _G[name .. "PortraitContainer"])
    if container then
        PlacePortraitOnFrame(container, frame)
    end

    if frame.portrait then
        frame.portrait:Show()
    end
    if name then
        local named = _G[name .. "Portrait"]
        if named and named.Show then
            named:Show()
        end
    end

    local tex = GetPortraitTexture(frame)
    if tex then
        if frame.gqPortraitHolder then
            frame.gqPortraitHolder:Hide()
        end
        if container then
            tex:ClearAllPoints()
            tex:SetAllPoints(container)
        else
            PlacePortraitOnFrame(tex, frame)
        end
        ApplyPortraitTexture(tex, PORTRAIT_TEXTURE, container or frame)
        EnsurePortraitBorderMetal(frame)
        return
    end

    local icon, holder = EnsureFallbackPortraitIcon(frame, frame)
    if holder:GetParent() ~= frame then
        holder:SetParent(frame)
    end
    PlacePortraitOnFrame(holder, frame)
    icon:ClearAllPoints()
    icon:SetAllPoints(holder)
    ApplyPortraitTexture(icon, PORTRAIT_TEXTURE, holder)
    holder:Show()
    EnsurePortraitBorderMetal(frame)
end

-- One scene file per class. Only the active class is SetTexture'd, so the
-- other eight stay on disk until that class (or its simulator) is shown.
local LOG_SCENE_TEXTURE = {
    DRUID = LogSceneArt("GQ-LogScene-Druid.png"),
    HUNTER = LogSceneArt("GQ-LogScene-Hunter.png"),
    MAGE = LogSceneArt("GQ-LogScene-Mage.png"),
    PALADIN = LogSceneArt("GQ-LogScene-Paladin.png"),
    PRIEST = LogSceneArt("GQ-LogScene-Priest.png"),
    ROGUE = LogSceneArt("GQ-LogScene-Rogue.png"),
    SHAMAN = SHAMAN_LOG_SCENE,
    WARLOCK = LogSceneArt("GQ-LogScene-Warlock.png"),
    WARRIOR = LogSceneArt("GQ-LogScene-Warrior.png"),
}

-- Pixel size of each scene file. The log is taller than these pictures, so
-- the visible window is a center crop. Nothing is scaled on one axis.
local LOG_SCENE_SIZE = {
    DRUID = { 1024, 572 },
    HUNTER = { 1024, 572 },
    MAGE = { 1024, 572 },
    PALADIN = { 1024, 572 },
    PRIEST = { 1024, 572 },
    ROGUE = { 1024, 559 },
    SHAMAN = { 1024, 512 },
    WARLOCK = { 1024, 572 },
    WARRIOR = { 1024, 572 },
}

local SIM_CLASS_ROW_SHADE = LogSceneArt("GQ-ClassRowShade.png")
local SIM_CLASS_ROW_PAD = 10
local SIM_CLASS_ROW_GAP = 1
local SIM_CLASS_FONTS = { "QuestFont_Super_Huge", "QuestFont_Huge", "QuestTitleFont", "GameFontNormalLarge" }

local function SimulatorClassInsetHeight(inset)
    local h = inset and inset.GetHeight and inset:GetHeight() or 0
    if h and h > 80 then
        return h
    end
    return (FRAME_HEIGHT - TAB_TOP_OFFSET) + LOG_SECTION_TOP - FOOTER_OFFSET
end

local function ApplySimClassRowCrop(tex, classFile, rowW, rowH)
    local size = LOG_SCENE_SIZE[classFile]
    if not size or not rowW or not rowH or rowW <= 1 or rowH <= 1 then
        tex:SetTexCoord(0, 1, 0, 1)
        return
    end
    local rowAspect = rowW / rowH
    local texAspect = size[1] / size[2]
    if rowAspect >= texAspect then
        local pad = (1 - (texAspect / rowAspect)) * 0.5
        tex:SetTexCoord(0, 1, pad, 1 - pad)
    else
        local pad = (1 - (rowAspect / texAspect)) * 0.5
        tex:SetTexCoord(pad, 1 - pad, 0, 1)
    end
end

local function ApplyLogSceneCrop(tex, frame, classFile)
    local size = classFile and LOG_SCENE_SIZE[classFile]
    local viewW = (frame:GetWidth() or 0) - 4
    local viewH = (frame:GetHeight() or 0) - 4
    if not size or viewW <= 1 or viewH <= 1 then
        tex:SetTexCoord(0, 1, 0, 1)
        return
    end
    local viewAspect = viewW / viewH
    local texAspect = size[1] / size[2]
    if viewAspect < texAspect then
        local pad = (1 - (viewAspect / texAspect)) * 0.5
        tex:SetTexCoord(pad, 1 - pad, 0, 1)
    else
        local pad = (1 - (texAspect / viewAspect)) * 0.5
        tex:SetTexCoord(0, 1, pad, 1 - pad)
    end
end

function GQ.Log:LogSceneTexture()
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.hideLogArt then
        return nil
    end
    local classFile = GQ:GetEffectiveClass()
    return classFile and LOG_SCENE_TEXTURE[classFile] or nil
end

function GQ.Log:UpdateLogScene()
    local frame = self.frame
    if not frame then
        return
    end

    if not frame.gqLogScene then
        local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        frame.gqLogScene = tex
        local shade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
        shade:SetPoint("TOPLEFT", tex, "TOPLEFT", 0, 0)
        shade:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0)
        frame.gqLogSceneShade = shade
    end

    local texture = self:LogSceneTexture()
    if texture then
        if frame.gqLogScenePath ~= texture then
            frame.gqLogScene:SetTexture(texture)
            frame.gqLogScenePath = texture
        end
        ApplyLogSceneCrop(frame.gqLogScene, frame, GQ:GetEffectiveClass())
        if not frame.gqLogSceneShadeLoaded then
            frame.gqLogSceneShade:SetTexture(SHAMAN_LOG_VIGNETTE)
            frame.gqLogSceneShadeLoaded = true
        end
        frame.gqLogScene:Show()
        frame.gqLogSceneShade:Show()
        if frame.blackBg then
            frame.blackBg:SetAlpha(0)
        end
    else
        frame.gqLogScene:Hide()
        frame.gqLogSceneShade:Hide()
        if frame.blackBg then
            frame.blackBg:SetAlpha(1)
        end
    end

    local listBg = frame.listInset and frame.listInset.blackBg
    if listBg then
        -- Layout paints a solid fill on this same texture. Re-apply the shade
        -- whenever a scene is showing so that fill cannot stick.
        if texture then
            listBg:SetTexture(SHAMAN_LIST_SHADE)
            listBg:SetVertexColor(1, 1, 1, 1)
        else
            listBg:SetColorTexture(LIST_BG[1], LIST_BG[2], LIST_BG[3], LIST_BG[4] or 1)
        end
    end

    local parchment = frame.detailBg and frame.detailBg.gqParchment
    if parchment then
        parchment:SetAlpha(texture and SHAMAN_PARCHMENT_ALPHA or 1)
    end

    if self.UpdateSimClassRowArt then
        self:UpdateSimClassRowArt()
    end
end

function GQ.Log:UpdateSimClassRowArt()
    local frame = self.frame
    local buttons = frame and frame.simClassButtons
    if not buttons then
        return
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    local show = self:GetPageTab() == "simulator" and not (settings and settings.hideLogArt)
    for _, btn in ipairs(buttons) do
        if not btn.scene then
            return
        end
        if show then
            local path = LOG_SCENE_TEXTURE[btn.classFile]
            if path and btn.scenePath ~= path then
                btn.scene:SetTexture(path)
                btn.scenePath = path
            end
            ApplySimClassRowCrop(btn.scene, btn.classFile, btn.rowW, btn.rowH)
            btn.scene:Show()
            if not btn.shadeLoaded then
                btn.shade:SetTexture(SIM_CLASS_ROW_SHADE)
                btn.shadeLoaded = true
            end
            btn.shade:Show()
        elseif btn.scenePath then
            btn.scene:SetTexture(nil)
            btn.scenePath = nil
            btn.scene:Hide()
            btn.shade:Hide()
        end
    end
end

function GQ.Log:GetListTab()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    return GearQuestForeverDB.ui.listTab or "active"
end

function GQ.Log:SetListTab(tab)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.listTab = tab
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    self:Refresh()
end

function GQ.Log:GetPageTab()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    return GearQuestForeverDB.ui.pageTab or "log"
end

function GQ.Log:SetPageTab(tab)
    tab = tab or "log"
    local leavingLookup = self:GetPageTab() == "lookup" and tab ~= "lookup"
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.pageTab = tab
    self:HideSpecPicker()
    if leavingLookup then
        self:ReleaseLookupIndex()
        self:RestoreHuntDetail()
    end
    self:ApplyPageTab()
    if self:GetPageTab() == "simulator" then
        self:SeedSimulatorFromCharacter()
        self:RefreshSimulator()
    elseif self:GetPageTab() == "settings" then
        self:RefreshSettings()
    elseif self:GetPageTab() == "lookup" then
        self:RefreshLookup()
    else
        self:Refresh()
    end
end

function GQ.Log:EntryMatchesTrackedHunt(entry)
    if not entry then
        return false
    end

    local classFile = GQ:GetEffectiveClass()
    if entry.classes and not entry.classes[classFile] then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    if GQ.Equip and GQ.Equip.EntryMatchesSpec and not GQ.Equip:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Log:IsSlotCollapsed(slotName, cachedUpgrades)
    slotName = GQ.Data:NormalizeSlotName(slotName)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.collapsedSlots = GearQuestForeverDB.ui.collapsedSlots or {}

    if GearQuestForeverDB.ui.collapsedSlots[slotName] ~= nil then
        return GearQuestForeverDB.ui.collapsedSlots[slotName]
    end

    -- Migrate saved collapse state from old duplicate categories.
    if slotName == "Finger" then
        for _, legacy in ipairs({ "Finger0", "Finger1" }) do
            if GearQuestForeverDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestForeverDB.ui.collapsedSlots[legacy]
            end
        end
    elseif slotName == "Trinket" then
        for _, legacy in ipairs({ "Trinket0", "Trinket1" }) do
            if GearQuestForeverDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestForeverDB.ui.collapsedSlots[legacy]
            end
        end
    end

    if cachedUpgrades ~= nil then
        return #cachedUpgrades == 0
    end

    -- WeaponPair is not a paper-doll slot, so the empty-slot fallback would
    -- report it collapsed and the first header click would not fold it.
    if slotName == "WeaponPair" then
        return false
    end

    local upgrades = GQ.Data:GetTopUpgradesForSlot(slotName, 1)
    return #upgrades == 0 and #self:GetActiveSlotListEntries(slotName) == 0
end

function GQ.Log:SetSlotCollapsed(slotName, collapsed)
    slotName = GQ.Data:NormalizeSlotName(slotName)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.collapsedSlots = GearQuestForeverDB.ui.collapsedSlots or {}
    GearQuestForeverDB.ui.collapsedSlots[slotName] = collapsed
end

function GQ.Log:ToggleSlotCollapsed(slotName)
    self:SetSlotCollapsed(slotName, not self:IsSlotCollapsed(slotName))
    self:Refresh()
end

local SOURCE_FILTERS = {
    { id = "boss_drop", label = "Boss drop" },
    { id = "object_drop", label = "Container" },
    { id = "raid_trash", label = "Dungeon & Raid trash" },
    { id = "profession", label = "Profession" },
    { id = "quest_reward", label = "Quest reward" },
    { id = "rare_npc", label = "Rare NPC" },
    { id = "unsourced", label = "Unsourced" },
    { id = "vendor", label = "Vendor" },
    { id = "world_drop", label = "World drop" },
}

-- Every profession that has a hunt item, at any level and for any class.
-- The branch stays this full list so a box you clear stays cleared when you
-- level up or simulate a class that gains a different craft.
local PROFESSION_FILTERS = {
    "Alchemy",
    "Blacksmithing",
    "Enchanting",
    "Engineering",
    "Fishing",
    "Leatherworking",
    "Tailoring",
}

-- Dungeons and raids that have a boss-drop hunt, alphabetical.
-- The flyout only lists the ones that have a hunt in the current level
-- window, including ranks below the top 3. A cleared box stays cleared.
GQ.Log.DUNGEON_FILTERS = {
    "Blackfathom Deeps",
    "Blackrock Depths",
    "Blackrock Spire",
    "Blackwing Lair",
    "City of Dalaran",
    "Dire Maul",
    "Excavation Site",
    "Gnomeregan",
    "Hall of Thanes",
    "Maraudon",
    "Molten Core",
    "Naxxramas",
    "Onyxia's Lair",
    "Other",
    "Ragefire Chasm",
    "Razorfen Downs",
    "Razorfen Kraul",
    "Ruins of Ahn'Qiraj",
    "Ruins of Lordaeron",
    "Scarlet Monastery",
    "Scholomance",
    "Shadowfang Keep",
    "Stratholme",
    "Sunken Temple",
    "Temple of Ahn'Qiraj",
    "The Deadmines",
    "The Stockade",
    "Uldaman",
    "Wailing Caverns",
    "Zul'Farrak",
    "Zul'Gurub",
}

-- A few instance bosses are stored under the entrance zone, or with no zone.
-- The flyout still files them with the instance.
GQ.Log.BOSS_DUNGEON = {
    ["Ragnaros"] = "Molten Core",
    ["Nefarian"] = "Blackwing Lair",
    ["Lord Valthalak"] = "Blackrock Spire",
    ["Warchief Rend Blackhand"] = "Blackrock Spire",
    ["High Priestess Arlokk"] = "Zul'Gurub",
    ["Wushoolay"] = "Zul'Gurub",
    ["Sapphiron"] = "Naxxramas",
    ["General Rajaxx"] = "Ruins of Ahn'Qiraj",
    ["Ouro"] = "Temple of Ahn'Qiraj",
    ["Relic Guardian"] = "Excavation Site",
}

-- Vendor flyout. Checked means show. Ordinary is a purchase with no faction
-- standing and no honor cost. An item that needs both standing and honor
-- hides when either of those boxes is off.
GQ.Log.VENDOR_KINDS = {
    { id = "reputation", label = "Reputation" },
    { id = "honor", label = "Honor (PvP)" },
    { id = "gold", label = "Ordinary" },
}

-- Sellers whose stock is battleground marks, arena points, or PvP rank gear.
-- A general merchant who happens to sell one rank-named piece is not on this
-- list. Thrallmar and Honor Hold quartermasters are reputation, not honor.
GQ.Log.HONOR_VENDORS = {
    ["Brave Stonehide"] = true,
    ["Blood Guard Porung"] = true,
    ["Captain Dirgehammer"] = true,
    ["Captain O'Neal"] = true,
    ["Doris Volanthius"] = true,
    ["First Sergeant Hola'mahi"] = true,
    ["Gaelden Hammersmith"] = true,
    ["Grunnda Wolfheart"] = true,
    ["Illiyana Moonblaze"] = true,
    ["Jekyll Flandring"] = true,
    ["Kayri"] = true,
    ["Kelm Hargunth"] = true,
    ["Lady Palanseer"] = true,
    ["Lieutenant Jackspring"] = true,
    ["Lieutenant Tristia"] = true,
    ["Master Sergeant Biggins"] = true,
    ["Rutherford Twing"] = true,
    ["Samuel Hawke"] = true,
    ["Sergeant Major Clate"] = true,
    ["Sergeant Thunderhorn"] = true,
    ["Stone Guard Zarg"] = true,
    ["Thanthaldis Snowgleam"] = true,
    ["Sergeant Ba'sha"] = true,
    ["Officer Areyn"] = true,
}

-- Standing with one of these means the purchase is also a battleground reward.
GQ.Log.HONOR_FACTIONS = {
    ["Frostwolf Clan"] = true,
    ["Silverwing Sentinels"] = true,
    ["Stormpike Guard"] = true,
    ["The Defilers"] = true,
    ["The League of Arathor"] = true,
    ["Warsong Outriders"] = true,
}

-- Longest first, so "Sergeant Major's" is not filed as "Sergeant's".
GQ.Log.HONOR_PREFIXES = {
    "Lieutenant Commander's",
    "Lieutenant General's",
    "Knight-Lieutenant's",
    "Senior Sergeant's",
    "Knight-Champion's",
    "Master Sergeant's",
    "Sergeant Major's",
    "First Sergeant's",
    "Field Marshal's",
    "Grand Marshal's",
    "Knight-Captain's",
    "Stone Guard's",
    "High Warlord's",
    "Blood Guard's",
    "Legionnaire's",
    "Bloodguard's",
    "Protector's",
    "Commander's",
    "Centurion's",
    "Outrider's",
    "Sentinel's",
    "Champion's",
    "Marksman's",
    "Stormpike",
    "Frostwolf",
    "Warlord's",
    "Advisor's",
    "Marshal's",
    "Private's",
    "Corporal's",
    "Sergeant's",
    "General's",
    "Knight's",
    "Scout's",
    "Grunt's",
}

function GQ.Log:GetHiddenSources()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.hiddenSources = GearQuestForeverDB.ui.hiddenSources or {}
    -- Unsourced starts off. A later check or uncheck is remembered.
    if not GearQuestForeverDB.ui.unsourcedDefaulted then
        GearQuestForeverDB.ui.unsourcedDefaulted = true
        if GearQuestForeverDB.ui.hiddenSources.unsourced == nil then
            GearQuestForeverDB.ui.hiddenSources.unsourced = true
        end
    end
    return GearQuestForeverDB.ui.hiddenSources
end

function GQ.Log:GetHiddenProfessions()
    -- Same saved table as the source filter, so it is still there after logout.
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.hiddenProfessions = GearQuestForeverDB.ui.hiddenProfessions or {}
    return GearQuestForeverDB.ui.hiddenProfessions
end

function GQ.Log:GetHiddenDungeons()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.hiddenDungeons = GearQuestForeverDB.ui.hiddenDungeons or {}
    return GearQuestForeverDB.ui.hiddenDungeons
end

function GQ.Log:ProfessionSubfilterActive()
    if self:GetHiddenSources().profession then
        return false
    end
    local hidden = self:GetHiddenProfessions()
    for _ in pairs(hidden) do
        return true
    end
    return false
end

function GQ.Log:DungeonSubfilterActive()
    if self:GetHiddenSources().boss_drop then
        return false
    end
    local hidden = self:GetHiddenDungeons()
    local reachable = self:ReachableBossDungeons()
    for i = 1, #reachable do
        if hidden[reachable[i]] then
            return true
        end
    end
    return false
end

function GQ.Log:GetHiddenTrashDungeons()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.hiddenTrashDungeons = GearQuestForeverDB.ui.hiddenTrashDungeons or {}
    return GearQuestForeverDB.ui.hiddenTrashDungeons
end

function GQ.Log:TrashSubfilterActive()
    if self:GetHiddenSources().raid_trash then
        return false
    end
    local hidden = self:GetHiddenTrashDungeons()
    local reachable = self:ReachableTrashDungeons()
    for i = 1, #reachable do
        if hidden[reachable[i]] then
            return true
        end
    end
    return false
end

function GQ.Log:GetHiddenVendors()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.hiddenVendors = GearQuestForeverDB.ui.hiddenVendors or {}
    return GearQuestForeverDB.ui.hiddenVendors
end

function GQ.Log:VendorSubfilterActive()
    if self:GetHiddenSources().vendor then
        return false
    end
    local hidden = self:GetHiddenVendors()
    local kinds = self.VENDOR_KINDS or {}
    for i = 1, #kinds do
        if hidden[kinds[i].id] then
            return true
        end
    end
    return false
end

function GQ.Log:VendorFlags(entry)
    if not entry then
        return false, false
    end
    if entry._gqVendorChecked then
        return entry._gqVendorRep, entry._gqVendorHonor
    end
    local rep = false
    local bgRep = false
    local reps = entry.reqRep
    if reps and #reps > 0 then
        rep = true
        local factions = self.HONOR_FACTIONS
        for i = 1, #reps do
            local row = reps[i]
            local faction = row and (row[1] or row.faction)
            if faction and factions and factions[faction] then
                bgRep = true
                break
            end
        end
    end
    local honor = bgRep
    local npc = entry.npc
    if not honor and npc and npc ~= "" and self.HONOR_VENDORS and self.HONOR_VENDORS[npc] then
        honor = true
    end
    if not honor then
        local instructions = entry.instructions
        if type(instructions) == "string" and (
            string.find(instructions, "costs tokens", 1, true)
            or string.find(instructions, "Honor Points", 1, true)
        ) then
            honor = true
        end
    end
    -- A rank-named piece with no seller still belongs in Honor. The same
    -- prefix on a town vendor (Legionnaire's Leggings, Grunt's Harness) does not.
    if not honor and (not npc or npc == "") then
        local name
        if GQ.Data and GQ.Data.GetItemFact and entry.itemId then
            local fact = GQ.Data:GetItemFact(entry.itemId)
            name = fact and fact.name
        end
        local prefixes = self.HONOR_PREFIXES
        if type(name) == "string" and prefixes then
            for i = 1, #prefixes do
                local prefix = prefixes[i]
                if string.sub(name, 1, #prefix) == prefix then
                    honor = true
                    break
                end
            end
        end
    end
    entry._gqVendorChecked = true
    entry._gqVendorRep = rep and true or false
    entry._gqVendorHonor = honor and true or false
    return entry._gqVendorRep, entry._gqVendorHonor
end

function GQ.Log:DungeonFilterSet()
    if self._dungeonFilterSet then
        return self._dungeonFilterSet
    end
    local set = {}
    local list = self.DUNGEON_FILTERS or {}
    for i = 1, #list do
        local name = list[i]
        if name ~= "Other" then
            set[name] = true
        end
    end
    self._dungeonFilterSet = set
    return set
end

function GQ.Log:BossDungeonKey(entry)
    local zone = entry and entry.zone
    if zone and zone ~= "" and self:DungeonFilterSet()[zone] then
        return zone
    end
    local npc = entry and entry.npc
    local mapped = npc and self.BOSS_DUNGEON and self.BOSS_DUNGEON[npc]
    if mapped then
        return mapped
    end
    return "Other"
end

function GQ.Log:ReachableBossDungeons()
    -- Dungeons that have a boss-drop hunt for this class, spec, faction, and
    -- level, including ranks the log does not show.
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass() or ""
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or ""
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local cacheKey = table.concat({ tostring(classFile), tostring(spec), tostring(faction), tostring(level) }, "|")
    if self._reachableDungeonsKey == cacheKey and self._reachableDungeons then
        return self._reachableDungeons
    end
    local present = {}
    local slots = {}
    local base = GQ.Data and GQ.Data.BASE_SLOTS or {}
    for i = 1, #base do
        slots[#slots + 1] = base[i]
    end
    slots[#slots + 1] = "Ranged"
    for i = 1, #slots do
        local list = GQ.Data and GQ.Data.GetClassSlotEntryList and GQ.Data:GetClassSlotEntryList(slots[i])
        if list then
            for j = 1, #list do
                local entry = list[j]
                local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType((entry and entry.sourceType) or "")
                if src == "boss_drop" and GQ.Data:EntryMatchesPlayerBand(entry) then
                    present[self:BossDungeonKey(entry)] = true
                end
            end
        end
    end
    local names = {}
    local catalog = self.DUNGEON_FILTERS or {}
    for i = 1, #catalog do
        if present[catalog[i]] then
            names[#names + 1] = catalog[i]
        end
    end
    self._reachableDungeons = names
    self._reachableDungeonsKey = cacheKey
    return names
end

function GQ.Log:ReachableTrashDungeons()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass() or ""
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or ""
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local cacheKey = table.concat({ tostring(classFile), tostring(spec), tostring(faction), tostring(level) }, "|")
    if self._reachableTrashKey == cacheKey and self._reachableTrash then
        return self._reachableTrash
    end
    local present = {}
    local slots = {}
    local base = GQ.Data and GQ.Data.BASE_SLOTS or {}
    for i = 1, #base do
        slots[#slots + 1] = base[i]
    end
    slots[#slots + 1] = "Ranged"
    for i = 1, #slots do
        local list = GQ.Data and GQ.Data.GetClassSlotEntryList and GQ.Data:GetClassSlotEntryList(slots[i])
        if list then
            for j = 1, #list do
                local entry = list[j]
                local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType((entry and entry.sourceType) or "")
                if src == "raid_trash" and GQ.Data:EntryMatchesPlayerBand(entry) then
                    present[self:BossDungeonKey(entry)] = true
                end
            end
        end
    end
    local names = {}
    local catalog = self.DUNGEON_FILTERS or {}
    for i = 1, #catalog do
        if present[catalog[i]] then
            names[#names + 1] = catalog[i]
        end
    end
    self._reachableTrash = names
    self._reachableTrashKey = cacheKey
    return names
end

function GQ.Log:NoDungeonsEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playNoDungeons and true or false
end

function GQ.Log:DungeonEnjoyerEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playDungeonEnjoyer and true or false
end

function GQ.Log:ManageableDungeonsEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playManageableDungeons and true or false
end

function GQ.Log:BuyItEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playBuyIt and true or false
end

function GQ.Log:ManageableQuestsEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playManageableQuests and true or false
end

function GQ.Log:FocusZoneEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playFocusZone and true or false
end

function GQ.Log:PlayStyleActive()
    return self:NoDungeonsEnabled() or self:DungeonEnjoyerEnabled() or self:GetItTodayEnabled()
        or self:ManageableDungeonsEnabled() or self:BuyItEnabled() or self:ManageableQuestsEnabled()
        or self:FocusZoneEnabled()
end

function GQ.Log:PlayerZoneName()
    local zone = ""
    if GetRealZoneText then
        zone = GetRealZoneText() or ""
    end
    if zone == "" and GetZoneText then
        zone = GetZoneText() or ""
    end
    return zone
end

function GQ.Log:ZoneNamesMatch(a, b)
    if not a or not b or a == "" or b == "" then
        return false
    end
    if a == b then
        return true
    end
    return string.lower(a) == string.lower(b)
end

-- A hunt can be finished here when its zone, or any spot this faction can
-- use, is the zone the character is standing in. No place means it stays out.
function GQ.Log:EntryInPlayerZone(entry)
    if not entry then
        return false
    end
    local zone = self:PlayerZoneName()
    if zone == "" then
        zone = self._focusZoneSeen or ""
    end
    if zone == "" then
        return true
    end
    local itemId = entry.itemId
    local cache = self._focusZoneMatch
    if itemId and cache and self._focusZoneCacheName == zone then
        local hit = cache[itemId]
        if hit ~= nil then
            return hit
        end
    end
    local function remember(ok)
        if itemId and self._focusZoneMatch and self._focusZoneCacheName == zone then
            self._focusZoneMatch[itemId] = ok and true or false
        end
        return ok
    end
    if self:ZoneNamesMatch(entry.zone, zone) then
        return remember(true)
    end
    local spots = GQ.Data and GQ.Data.VisibleCoordinateSpots and itemId and GQ.Data:VisibleCoordinateSpots(itemId)
    if spots then
        for i = 1, #spots do
            if self:ZoneNamesMatch(spots[i].map, zone) then
                return remember(true)
            end
        end
    end
    return remember(false)
end

-- The rows on screen stay until each slot has been checked, one slot per
-- frame with an idle frame between slots. The list swaps once at the end.
function GQ.Log:ScheduleFocusZoneRefresh()
    if not self:FocusZoneEnabled() then
        return
    end
    if not (self.frame and self.frame:IsShown()) then
        return
    end
    if self._focusZoneWarm then
        self._focusZoneWarmAgain = true
        return
    end
    if not (C_Timer and C_Timer.After) then
        self:Refresh()
        return
    end
    self._focusZoneWarm = true
    local zone = self:PlayerZoneName()
    if zone == "" then
        zone = self._focusZoneSeen or ""
    end
    self._focusZoneSeen = zone
    self._focusZoneCacheName = zone
    self._focusZoneMatch = {}
    local slots = (GQ.Data and GQ.Data.GetSlotsForClass and GQ.Data:GetSlotsForClass(GQ:GetEffectiveClass())) or {}
    local index = 0
    local phase = "slots"
    local gapLeft = 0
    local function finish()
        self._focusZoneWarm = false
        if not (self.frame and self.frame:IsShown() and self:FocusZoneEnabled()) then
            return
        end
        local nowZone = self:PlayerZoneName()
        if self._focusZoneWarmAgain or (nowZone ~= "" and nowZone ~= zone) then
            self._focusZoneWarmAgain = nil
            self:ScheduleFocusZoneRefresh()
            return
        end
        self:Refresh()
    end
    local function step()
        if not (self.frame and self:FocusZoneEnabled()) then
            self._focusZoneWarm = false
            self._focusZoneWarmAgain = nil
            return
        end
        local nowZone = self:PlayerZoneName()
        if nowZone ~= "" and nowZone ~= zone then
            self._focusZoneWarm = false
            self:ScheduleFocusZoneRefresh()
            return
        end
        if gapLeft > 0 then
            gapLeft = gapLeft - 1
            C_Timer.After(0, step)
            return
        end
        if phase == "slots" then
            index = index + 1
            local slotName = slots[index]
            if slotName then
                local handKind = nil
                if slotName == "MainHand" and self.WeaponHeaderKind then
                    handKind = self:WeaponHeaderKind()
                end
                local list = self:GetSlotRankList(slotName, handKind)
                if list then
                    for i = 1, #list do
                        self:EntryInPlayerZone(list[i])
                    end
                end
                gapLeft = 1
                C_Timer.After(0, step)
                return
            end
            phase = "weapons"
            gapLeft = 1
            C_Timer.After(0, step)
            return
        end
        if phase == "weapons" then
            phase = "done"
            local pool = self:CollectWeaponPool()
            if pool then
                for i = 1, #pool do
                    self:EntryInPlayerZone(pool[i])
                end
            end
            gapLeft = 1
            C_Timer.After(0, step)
            return
        end
        C_Timer.After(0, finish)
    end
    C_Timer.After(0, step)
end

function GQ.Log:UsesWideHuntList()
    return self:SourceFilterActive() or self:PlayStyleActive()
end

function GQ.Log:TextNamesInstance(text)
    if not text or text == "" then
        return false
    end
    local catalog = self.DUNGEON_FILTERS or {}
    for i = 1, #catalog do
        local name = catalog[i]
        if name ~= "Other" and name ~= "Excavation Site" and string.find(text, name, 1, true) then
            return true
        end
    end
    if string.find(text, "Excavation Site", 1, true) and not string.find(text, "Whelgar Excavation Site", 1, true) then
        return true
    end
    return false
end

function GQ.Log:EntryRequiresInstance(entry)
    if not entry then
        return false
    end
    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    if src == "raid_trash" then
        return true
    end
    if src == "boss_drop" then
        return self:BossDungeonKey(entry) ~= "Other"
    end
    if src == "profession" or src == "world_drop" then
        return false
    end
    local zone = entry.zone
    if zone and zone ~= "" and self:DungeonFilterSet()[zone] then
        return true
    end
    local coords = GQ.Data and GQ.Data.coordinates
    local row = coords and entry.itemId and coords[entry.itemId]
    if row and row.note and string.find(row.note, "entrance to dungeon", 1, true) then
        return true
    end
    if src == "quest_reward" then
        if self:TextNamesInstance(entry.instructions) or self:TextNamesInstance(entry.questName) then
            return true
        end
    end
    return false
end

function GQ.Log:GetItTodayEnabled()
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    return ui and ui.playGetItToday and true or false
end

-- Stored item level. Manageable Quests and Manageable Dungeons wait until
-- the viewed level reaches this minus 4. That wait never goes past 60.
function GQ.Log:QuestRewardItemLevel(entry)
    if not entry then
        return nil
    end
    -- Remembered on the row. A play style checks this once per hunt while the
    -- list is built, and a later rebuild must not walk the fact tables again.
    local cached = entry._gqIlvl
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached
    end
    local ilvl
    if entry.itemId and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        ilvl = fact and tonumber(fact.ilvl)
        if not ilvl or ilvl < 1 then
            ilvl = nil
        end
    end
    entry._gqIlvl = ilvl or false
    return ilvl
end

-- Same wait as Manageable Quests: 4 under the item level, and never past 60.
-- A quest that cannot be picked up until later uses that pickup level, so
-- the recommendation is never lower than the level the quest actually starts.
function GQ.Log:QuestRewardRecommendedLevel(entry)
    local ilvl = self:QuestRewardItemLevel(entry)
    if not ilvl then
        return nil
    end
    local floor = ilvl - 4
    if floor > 60 then
        floor = 60
    end
    if floor < 1 then
        floor = 1
    end
    local src = entry and (GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or entry.sourceType or "")
    if src == "quest_reward" and entry.itemId and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        local pickup = fact and tonumber(fact.reqLevel)
        if pickup and pickup > floor then
            floor = pickup
        end
        if floor > 60 then
            floor = 60
        end
    end
    return floor
end

-- Same wait as Manageable Dungeons: 4 under the item level, never past 60.
-- Green once the viewed level has reached it, red before that.
function GQ.Log:AppendDungeonEntryLine(lines, entry)
    local recommended = self:QuestRewardRecommendedLevel(entry)
    if type(recommended) ~= "number" or recommended < 1 then
        return
    end
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local color = level >= recommended and "|cff0c4a1c" or "|cff6e1212"
    table.insert(lines, string.format(
        "\n%sRecommended dungeon entry at level %d.|r",
        color,
        math.floor(recommended)
    ))
end

function GQ.Log:ItemLevelTooSoon(entry)
    local floor = self:QuestRewardRecommendedLevel(entry)
    if not floor then
        return false
    end
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    return level < floor
end

function GQ.Log:QuestRewardTooHard(entry)
    if not entry then
        return false
    end
    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    if src ~= "quest_reward" then
        return false
    end
    return self:ItemLevelTooSoon(entry)
end

function GQ.Log:DungeonDropTooSoon(entry)
    if not entry then
        return false
    end
    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    if src ~= "boss_drop" and src ~= "raid_trash" then
        return false
    end
    return self:ItemLevelTooSoon(entry)
end

function GQ.Log:EntryCanBeBought(entry)
    if not entry then
        return false
    end
    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    if src == "vendor" or src == "auction_house" then
        return true
    end
    local bindType = GQ.Equip and GQ.Equip.GetItemBindType and GQ.Equip:GetItemBindType(entry.itemId)
    if bindType == nil then
        return true
    end
    local onPickup = (Enum and Enum.ItemBind and Enum.ItemBind.OnAcquire) or 1
    local onQuest = (Enum and Enum.ItemBind and Enum.ItemBind.Quest) or 4
    if bindType == onPickup or bindType == onQuest then
        return false
    end
    return true
end

function GQ.Log:RepRank(standing)
    local map = self._repRankByName
    if not map then
        map = {
            Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4,
            Friendly = 5, Honored = 6, Revered = 7, Exalted = 8,
        }
        self._repRankByName = map
    end
    return standing and map[standing]
end

function GQ.Log:RepStandingName(standingId)
    local names = self._repNameById
    if not names then
        names = {
            "Hated", "Hostile", "Unfriendly", "Neutral",
            "Friendly", "Honored", "Revered", "Exalted",
        }
        self._repNameById = names
    end
    return names[standingId]
end

function GQ.Log:FactionStandingId(standings, faction)
    if not standings or type(faction) ~= "string" or faction == "" then
        return nil
    end
    local have = standings[faction] or standings[string.lower(faction)]
    if have then
        return have
    end
    local key = string.lower(faction)
    key = string.gsub(key, "^%s+", "")
    key = string.gsub(key, "%s+$", "")
    key = string.gsub(key, "^the ", "")
    return standings[key]
end

function GQ.Log:ReputationRequirementLine(faction, standing)
    local need = self:RepRank(standing)
    local standings = self:PlayerFactionStandings()
    -- A failed read is not the same as a faction this character has never seen.
    if not standings then
        return string.format("\nRequires %s with %s.", standing, faction)
    end
    local have = self:FactionStandingId(standings, faction)
    if not have then
        return string.format(
            "\nRequires %s with %s. |cff6e1212You have not met this faction yet.|r",
            standing,
            faction
        )
    end
    local haveName = self:RepStandingName(have) or "Unknown"
    local met = need and have >= need
    local color = met and "|cff0c4a1c" or "|cff6e1212"
    return string.format(
        "\nRequires %s with %s. %sYour standing is %s.|r",
        standing,
        faction,
        color,
        haveName
    )
end

function GQ.Log:ReadFactionStandings()
    -- This character's reputation panel only. Nothing here is saved or shared.
    local ranks = {}
    local function note(name, standingId, isHeader, hasRep)
        if issecretvalue and (issecretvalue(name) or issecretvalue(standingId) or issecretvalue(isHeader)) then
            return
        end
        if type(name) ~= "string" or name == "" then
            return
        end
        standingId = tonumber(standingId)
        if not standingId or standingId < 1 then
            return
        end
        if isHeader and not hasRep then
            return
        end
        ranks[name] = standingId
        local key = string.lower(name)
        key = string.gsub(key, "^%s+", "")
        key = string.gsub(key, "%s+$", "")
        ranks[key] = standingId
        local bare = string.gsub(key, "^the ", "")
        ranks[bare] = standingId
    end

    local cRep = C_Reputation
    if cRep and cRep.GetNumFactions and cRep.GetFactionDataByIndex then
        local opened = {}
        local guard = 0
        while guard < 40 do
            guard = guard + 1
            local expanded = false
            local okCount, count = pcall(cRep.GetNumFactions)
            if not okCount or type(count) ~= "number" then
                break
            end
            for i = 1, count do
                local okRow, data = pcall(cRep.GetFactionDataByIndex, i)
                if okRow and type(data) == "table" and data.isHeader and data.isCollapsed and cRep.ExpandFactionHeader then
                    pcall(cRep.ExpandFactionHeader, i)
                    if type(data.name) == "string" then
                        opened[#opened + 1] = data.name
                    end
                    expanded = true
                    break
                end
            end
            if not expanded then
                break
            end
        end
        local okCount, count = pcall(cRep.GetNumFactions)
        if okCount and type(count) == "number" then
            for i = 1, count do
                local okRow, data = pcall(cRep.GetFactionDataByIndex, i)
                if okRow and type(data) == "table" then
                    note(data.name, data.reaction, data.isHeader, data.isHeaderWithRep)
                end
            end
        end
        if cRep.CollapseFactionHeader then
            for n = #opened, 1, -1 do
                local want = opened[n]
                local okBack, total = pcall(cRep.GetNumFactions)
                if okBack and type(total) == "number" then
                    for i = total, 1, -1 do
                        local okRow, data = pcall(cRep.GetFactionDataByIndex, i)
                        if okRow and type(data) == "table" and data.isHeader and not data.isCollapsed and data.name == want then
                            pcall(cRep.CollapseFactionHeader, i)
                            break
                        end
                    end
                end
            end
        end
        if next(ranks) then
            return ranks
        end
    end

    if not GetNumFactions or not GetFactionInfo then
        return nil
    end
    local opened = {}
    local guard = 0
    while guard < 30 do
        guard = guard + 1
        local expanded = false
        local count = GetNumFactions()
        for i = 1, count do
            local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
            if isHeader and isCollapsed and ExpandFactionHeader then
                ExpandFactionHeader(i)
                if name then
                    opened[#opened + 1] = name
                end
                expanded = true
                break
            end
        end
        if not expanded then
            break
        end
    end
    for i = 1, GetNumFactions() do
        local name, _, standingId, _, _, _, _, _, isHeader, _, hasRep = GetFactionInfo(i)
        note(name, standingId, isHeader, hasRep)
    end
    if CollapseFactionHeader then
        for n = #opened, 1, -1 do
            local want = opened[n]
            for i = GetNumFactions(), 1, -1 do
                local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
                if isHeader and not isCollapsed and name == want then
                    CollapseFactionHeader(i)
                    break
                end
            end
        end
    end
    if not next(ranks) then
        return nil
    end
    return ranks
end

function GQ.Log:ReadProfessionRanks()
    local ranks = {}
    local scanned = false
    local function note(name, rank)
        if issecretvalue and issecretvalue(name) then
            return
        end
        rank = tonumber(rank)
        if type(name) ~= "string" or name == "" or not rank or rank <= 0 then
            return
        end
        if not ranks[name] or rank > ranks[name] then
            ranks[name] = rank
        end
    end

    local count = 0
    if GetNumSkillLines then
        local ok, n = pcall(GetNumSkillLines)
        if ok and type(n) == "number" then
            count = n
        end
    end
    if count == 0 and ExpandSkillHeader then
        pcall(ExpandSkillHeader, 0)
        if GetNumSkillLines then
            local ok, n = pcall(GetNumSkillLines)
            if ok and type(n) == "number" then
                count = n
            end
        end
    end
    if GetSkillLineInfo and count > 0 then
        for i = 1, count do
            local ok, name, _, _, rank = pcall(GetSkillLineInfo, i)
            if ok then
                note(name, rank)
            end
        end
    end

    -- The profession window on Forever does not fill the skill-line list.
    -- GetProfessions still has the rank shown there (Leatherworking 157/225).
    if GetProfessions and GetProfessionInfo then
        local ok, a, b, c, d, e, f = pcall(GetProfessions)
        if ok then
            scanned = true
            local indexes = { a, b, c, d, e, f }
            for i = 1, #indexes do
                local index = indexes[i]
                if index then
                    local got, name, _, skillLevel = pcall(GetProfessionInfo, index)
                    if got then
                        note(name, skillLevel)
                    end
                end
            end
        end
    end

    if GetTradeSkillLine then
        local ok, name, rank = pcall(GetTradeSkillLine)
        if ok and type(name) == "string" and name ~= "" then
            note(name, rank)
            scanned = true
        end
    end
    if not scanned and count > 0 then
        scanned = true
    end

    return ranks, scanned
end

function GQ.Log:PlayerFactionStandings()
    if self._playerRep == nil then
        local ok, ranks = pcall(function()
            return self:ReadFactionStandings()
        end)
        if ok and type(ranks) == "table" then
            self._playerRep = ranks
        end
    end
    if type(self._playerRep) ~= "table" then
        return nil
    end
    return self._playerRep
end

function GQ.Log:PlayerProfessionRanks()
    local cached = self._playerProf
    if type(cached) == "table" and next(cached) then
        return cached
    end
    local ranks = self:ReadProfessionRanks()
    if type(ranks) == "table" and next(ranks) then
        self._playerProf = ranks
    end
    return ranks or {}
end

function GQ.Log:SameRankMap(previous, current)
    if not previous or not current then
        return false
    end
    for key, value in pairs(previous) do
        if current[key] ~= value then
            return false
        end
    end
    for key, value in pairs(current) do
        if previous[key] ~= value then
            return false
        end
    end
    return true
end

function GQ.Log:NoteObtainabilityChanged()
    if not self:GetItTodayEnabled() then
        self._repSnapshot = nil
        self._profSnapshot = nil
        return
    end
    self._playerRep = nil
    self._playerProf = nil
    local rep = self:PlayerFactionStandings()
    local prof = self:PlayerProfessionRanks()
    if not rep then
        return
    end
    local changed = false
    if self._repSnapshot and next(rep) then
        if not next(self._repSnapshot) or not self:SameRankMap(self._repSnapshot, rep) then
            changed = true
        end
    end
    if self._profSnapshot and next(prof) then
        if not next(self._profSnapshot) or not self:SameRankMap(self._profSnapshot, prof) then
            changed = true
        end
    end
    self._repSnapshot = rep
    self._profSnapshot = prof
    self._playerRep = rep
    self._playerProf = prof
    if not changed then
        return
    end
    self:InvalidateSourceFilterCache()
    self:ScheduleListRefresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

function GQ.Log:HuntTooltipText(entry)
    local audit = GQ.Data and GQ.Data.foreverAudit
    local row = audit and entry and entry.itemId and audit[entry.itemId]
    return row and row.tip or nil
end

function GQ.Log:CraftBindsOnPickup(entry)
    local tip = self:HuntTooltipText(entry)
    if tip and string.find(tip, "Binds when picked up", 1, true) then
        return true
    end
    if tip and string.find(tip, "Binds when equipped", 1, true) then
        return false
    end
    return GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(entry.itemId) == true
end

-- A "Requires Engineering (100)" line before the set block is a wear
-- requirement. The same words inside a set are the recipe.
function GQ.Log:ProfessionWearSkill(entry)
    local tip = self:HuntTooltipText(entry)
    if not tip or tip == "" then
        return nil, nil
    end
    local prof, need
    for line in string.gmatch(tip, "[^\n]+") do
        if string.find(line, "%(%d+/%d+%)") then
            break
        end
        local wearProf, wearNeed = string.match(line, "^Requires ([%a][%a ]-) %((%d+)%)")
        if wearProf and wearProf ~= "Level" then
            prof = wearProf
            need = tonumber(wearNeed)
        end
    end
    return prof, need
end

function GQ.Log:EntryBlockedToday(entry)
    if not entry then
        return false
    end
    local reps = entry.reqRep
    if reps then
        local standings = self:PlayerFactionStandings()
        if standings then
            for i = 1, #reps do
                local row = reps[i]
                local faction = row[1] or row.faction
                local need = self:RepRank(row[2] or row.standing)
                local have = self:FactionStandingId(standings, faction)
                if need and (not have or have < need) then
                    return true
                end
            end
        end
    end
    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    local skills = entry.reqSkills
    -- A crafted row stores the recipe in reqSkills. A drop or a quest that
    -- needs the profession to equip still uses that field.
    if skills and src ~= "profession" then
        local ranks = self:PlayerProfessionRanks()
        for i = 1, #skills do
            local row = skills[i]
            local prof = row[1]
            local need = row[2] or 1
            if (ranks[prof] or 0) < need then
                return true
            end
        end
    end
    if src ~= "profession" then
        return false
    end
    if self:CraftBindsOnPickup(entry) then
        local prof = entry.profession
        local need = 1
        if GQ.Data and GQ.Data.ProfessionCraftRequirement then
            local craftProf, craftSkill = GQ.Data:ProfessionCraftRequirement(entry)
            if craftSkill and craftSkill > 0 then
                need = craftSkill
                prof = craftProf or prof
            end
        end
        if need <= 1 then
            local stated = entry.instructions and entry.instructions:match("requires skill (%d+)")
            if stated then
                need = tonumber(stated) or 1
            end
        end
        local have = prof and (self:PlayerProfessionRanks()[prof] or 0) or 0
        if have < need then
            return true
        end
    else
        local wearProf, wearNeed = self:ProfessionWearSkill(entry)
        if wearProf and wearNeed and (self:PlayerProfessionRanks()[wearProf] or 0) < wearNeed then
            return true
        end
    end
    return false
end

function GQ.Log:EntryMatchesPlayStyle(entry)
    if self:NoDungeonsEnabled() and self:EntryRequiresInstance(entry) then
        return false
    end
    if self:DungeonEnjoyerEnabled() and not self:EntryRequiresInstance(entry) then
        return false
    end
    if self:GetItTodayEnabled() and self:EntryBlockedToday(entry) then
        return false
    end
    if self:ManageableDungeonsEnabled() and self:DungeonDropTooSoon(entry) then
        return false
    end
    if self:ManageableQuestsEnabled() and self:QuestRewardTooHard(entry) then
        return false
    end
    if self:BuyItEnabled() and not self:EntryCanBeBought(entry) then
        return false
    end
    if self:FocusZoneEnabled() and not self:EntryInPlayerZone(entry) then
        return false
    end
    return true
end

function GQ.Log:SourceFilterActive()
    local hidden = self:GetHiddenSources()
    for _, opt in ipairs(SOURCE_FILTERS) do
        if hidden[opt.id] then
            return true
        end
    end
    return self:ProfessionSubfilterActive() or self:DungeonSubfilterActive() or self:TrashSubfilterActive() or self:VendorSubfilterActive()
end

function GQ.Log:EntrySourceAllowed(entry)
    if not self:SourceFilterActive() then
        return true
    end
    local hidden = self:GetHiddenSources()
    local allHidden = true
    for _, opt in ipairs(SOURCE_FILTERS) do
        if not hidden[opt.id] then
            allHidden = false
            break
        end
    end
    if allHidden then
        return false
    end
    local src = GQ:NormalizeSourceType((entry and entry.sourceType) or "unknown")
    local known = false
    for _, opt in ipairs(SOURCE_FILTERS) do
        if opt.id == src then
            known = true
            break
        end
    end
    -- A source with no checkbox was treated as allowed, so fishing showed on a
    -- Boss drop list. Unlisted sources stay off a filtered list.
    if not known then
        return false
    end
    if hidden[src] then
        return false
    end
    if src == "profession" then
        local name = entry and entry.profession
        if (not name or name == "") and entry and entry.sourceType == "fishing" then
            name = "Fishing"
        end
        if name and name ~= "" and self:GetHiddenProfessions()[name] then
            return false
        end
    end
    if src == "boss_drop" and self:GetHiddenDungeons()[self:BossDungeonKey(entry)] then
        return false
    end
    if src == "raid_trash" and self:GetHiddenTrashDungeons()[self:BossDungeonKey(entry)] then
        return false
    end
    if src == "vendor" then
        local rep, honor = self:VendorFlags(entry)
        local hiddenVendors = self:GetHiddenVendors()
        if rep and hiddenVendors.reputation then
            return false
        end
        if honor and hiddenVendors.honor then
            return false
        end
        if not rep and not honor and hiddenVendors.gold then
            return false
        end
    end
    return true
end

function GQ.Log:GetBisProfessionNames()
    return PROFESSION_FILTERS
end

function GQ.Log:CopyFilterDraft()
    local sources = {}
    local hidden = self:GetHiddenSources()
    for _, opt in ipairs(SOURCE_FILTERS) do
        if hidden[opt.id] then
            sources[opt.id] = true
        end
    end
    local professions = {}
    local hiddenProfs = self:GetHiddenProfessions()
    for i = 1, #PROFESSION_FILTERS do
        local name = PROFESSION_FILTERS[i]
        if hiddenProfs[name] then
            professions[name] = true
        end
    end
    local dungeons = {}
    local hiddenDungeons = self:GetHiddenDungeons()
    local dungeonList = self.DUNGEON_FILTERS or {}
    for i = 1, #dungeonList do
        local name = dungeonList[i]
        if hiddenDungeons[name] then
            dungeons[name] = true
        end
    end
    local trash = {}
    local hiddenTrash = self:GetHiddenTrashDungeons()
    for i = 1, #dungeonList do
        local name = dungeonList[i]
        if hiddenTrash[name] then
            trash[name] = true
        end
    end
    local vendors = {}
    local hiddenVendors = self:GetHiddenVendors()
    local vendorKinds = self.VENDOR_KINDS or {}
    for i = 1, #vendorKinds do
        local kind = vendorKinds[i].id
        if hiddenVendors[kind] then
            vendors[kind] = true
        end
    end
    self._filterDraft = { sources = sources, professions = professions, dungeons = dungeons, trashDungeons = trash, vendors = vendors }
    return self._filterDraft
end

function GQ.Log:CommitSourceFilter()
    self:UpdateSourceFilterButton()
    self:InvalidateSourceFilterCache()
    self:ScheduleListRefresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

function GQ.Log:ApplyFilterDraft()
    local draft = self._filterDraft
    if not draft then
        return
    end
    local hidden = self:GetHiddenSources()
    for _, opt in ipairs(SOURCE_FILTERS) do
        if draft.sources[opt.id] then
            hidden[opt.id] = true
        else
            hidden[opt.id] = nil
        end
    end
    local hiddenProfs = self:GetHiddenProfessions()
    local clear = {}
    for name in pairs(hiddenProfs) do
        clear[#clear + 1] = name
    end
    for i = 1, #clear do
        hiddenProfs[clear[i]] = nil
    end
    for name, hiddenName in pairs(draft.professions) do
        if hiddenName then
            hiddenProfs[name] = true
        end
    end
    local hiddenDungeons = self:GetHiddenDungeons()
    local clearDungeons = {}
    for name in pairs(hiddenDungeons) do
        clearDungeons[#clearDungeons + 1] = name
    end
    for i = 1, #clearDungeons do
        hiddenDungeons[clearDungeons[i]] = nil
    end
    for name, hiddenName in pairs(draft.dungeons or {}) do
        if hiddenName then
            hiddenDungeons[name] = true
        end
    end
    local hiddenTrash = self:GetHiddenTrashDungeons()
    local clearTrash = {}
    for name in pairs(hiddenTrash) do
        clearTrash[#clearTrash + 1] = name
    end
    for i = 1, #clearTrash do
        hiddenTrash[clearTrash[i]] = nil
    end
    for name, hiddenName in pairs(draft.trashDungeons or {}) do
        if hiddenName then
            hiddenTrash[name] = true
        end
    end
    local hiddenVendors = self:GetHiddenVendors()
    local clearVendors = {}
    for name in pairs(hiddenVendors) do
        clearVendors[#clearVendors + 1] = name
    end
    for i = 1, #clearVendors do
        hiddenVendors[clearVendors[i]] = nil
    end
    for name, hiddenName in pairs(draft.vendors or {}) do
        if hiddenName then
            hiddenVendors[name] = true
        end
    end
    self:CommitSourceFilter()
end

function GQ.Log:InvalidateActiveListCaches()
    self._activeListCachesReady = false
    self._activeListCacheContext = nil
    self._completedBySlot = nil
    self._completedItemKeysBySlot = nil
    self._obtainedItemIdSet = nil
    self._ownedItemIdSet = nil
    self._heldOffHand = nil
    self._heldOffBand = nil
    self._weaponPool = nil
    self._weaponPoolBand = nil
    self._weaponStyles = nil
    self._weaponStylesBand = nil
    self._weaponTrueList = nil
    self._weaponTrueBand = nil
    self:InvalidateSourceFilterCache()
end

function GQ.Log:GetActiveListCacheContextKey()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    return table.concat({
        tostring(GQ:GetEffectiveClass()),
        tostring(GQ:GetEffectiveLevel()),
        tostring(spec),
        tostring(GQ:GetEffectiveFaction()),
        self:NoDungeonsEnabled() and "nodung" or "",
        self:DungeonEnjoyerEnabled() and "enjoy" or "",
        self:GetItTodayEnabled() and "today" or "",
        self:ManageableDungeonsEnabled() and "mdung" or "",
        self:ManageableQuestsEnabled() and "manage" or "",
        self:BuyItEnabled() and "buy" or "",
        self:FocusZoneEnabled() and ("zone:" .. self:PlayerZoneName()) or "",
    }, "|")
end

function GQ.Log:ForEachOwnedItemLink(callback)
    if not callback then
        return
    end
    pcall(function()
        for invSlot = 1, 19 do
            local link = GetInventoryItemLink("player", invSlot)
            if link then
                callback(link)
            end
        end
        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                local link = GetBagItemLink(bag, slot)
                if link then
                    callback(link)
                end
            end
        end
    end)
end

function GQ.Log:ForEachOwnedItemId(callback)
    if not callback then
        return
    end
    self:ForEachOwnedItemLink(function(link)
        callback(ItemLinkToId(link))
    end)
end

function GQ.Log:EntrySuffixOwned(entry, links)
    if not entry or not entry.suffix or entry.suffix == "" then
        return false
    end
    if GQ.Data.EnrichEntrySuffix then
        GQ.Data:EnrichEntrySuffix(entry)
    end
    for i = 1, #links do
        if GQ.Data:EntrySuffixMatchesLink(entry, links[i]) then
            return true
        end
    end
    return false
end

function GQ.Log:InvalidateSourceFilterCache()
    self._filteredTopBySlot = nil
    -- The weapon hunt list is the source filter and the weapon filter together.
    -- Drop the saved rows. The rank list stays. The hand and type boxes are
    -- rebuilt from what that filter still leaves.
    self._weaponFiltered = nil
    self._weaponStyleNow = nil
    self._weaponMenuStyles = nil
    self._weaponMenuStylesBand = nil
    -- Shields and held items keep their own hunt rows. That list is filtered
    -- when it is built, then saved for the level and spec. The source filter
    -- is not part of that key, so a Boss drop list was still the old world
    -- drops until the level changed. Drop it with the other filtered rows.
    self._heldOffHand = nil
    self._heldOffBand = nil
end

function GQ.Log:EnsureActiveListCaches()
    local ctx = self:GetActiveListCacheContextKey()
    if self._activeListCachesReady and self._activeListCacheContext == ctx then
        return
    end
    self._activeListCacheContext = ctx
    -- The filtered slot list is keyed only by slot. A new level, class, or
    -- spec must not keep the previous character's rows.
    self._filteredTopBySlot = nil
    self._completedBySlot = nil

    self:CollectCompletedBySlot()

    local keysBySlot = {}
    for slotName, entries in pairs(self._completedBySlot or {}) do
        local keys = {}
        for i = 1, #entries do
            local key = GQ.Data:EntryListKey(entries[i])
            if key then
                keys[key] = true
            end
        end
        keysBySlot[slotName] = keys
    end
    self._completedItemKeysBySlot = keysBySlot

    local obtained = {}
    local function markItemId(itemId)
        if itemId then
            obtained[tostring(itemId)] = true
        end
    end

    local progress = CharProgress()
    for itemKey in pairs(progress.obtainedItems or {}) do
        markItemId(tonumber(itemKey) or itemKey)
    end
    for id in pairs(progress.obtained or {}) do
        local entry = GQ.Data:GetEntryById(id)
        if entry then
            markItemId(entry.itemId)
        end
    end
    for id, record in pairs(progress.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed" then
            local entry = GQ.Data:GetEntryById(id)
            if entry then
                markItemId(entry.itemId)
            end
        end
    end
    local owned = {}
    local function markOwned(itemId)
        if not itemId then
            return
        end
        local key = tostring(itemId)
        owned[key] = true
        obtained[key] = true
    end

    pcall(function()
        for invSlot = 1, 19 do
            markOwned(ItemLinkToId(GetInventoryItemLink("player", invSlot)))
        end
        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                markOwned(ItemLinkToId(GetBagItemLink(bag, slot)))
            end
        end
    end)
    self._obtainedItemIdSet = obtained
    self._ownedItemIdSet = owned

    self._activeListCachesReady = true
end

function GQ.Log:EntryHiddenFromActiveFast(entry, slotName)
    if not entry then
        return true
    end
    self:EnsureActiveListCaches()

    slotName = GQ.Data:NormalizeSlotName(slotName or entry.slot)
    local itemKey = GQ.Data:EntryListKey(entry)
    local completedKeys = self._completedItemKeysBySlot and self._completedItemKeysBySlot[slotName]
    if itemKey and completedKeys and completedKeys[itemKey] then
        return true
    end
    if entry.itemId and self._obtainedItemIdSet and self._obtainedItemIdSet[tostring(entry.itemId)] then
        return true
    end
    if self:IsHuntRemoved(entry) then
        return true
    end
    return false
end

function GQ.Log:GetFilteredTopForSlot(slotName)
    -- A filter can use an earlier level band, so a slot still shows the best
    -- allowed piece the character can equip when this level's band has none.
    slotName = GQ.Data:NormalizeSlotName(slotName)
    if slotName == "MainHand" or (slotName == "SecondaryHand" and GQ.Data:CanDualWield() and self:WeaponStyleEnabled("off")) then
        local list = self:FilteredWeaponEntries()
        local out = {}
        local claimed = {}
        local function entryStyle(entry)
            if GQ.Data:EntryIsTwoHand(entry) then
                return "two"
            end
            return "one"
        end
        if slotName == "SecondaryHand" then
            -- A unique weapon stays on the main hand. It is not also rank 1 off hand.
            for i = 1, #list do
                if GQ.Data:WeaponFitsPaperSlot(list[i], "MainHand", entryStyle(list[i])) and list[i].itemId then
                    claimed[list[i].itemId] = true
                end
            end
        end
        for i = 1, #list do
            local entry = list[i]
            if GQ.Data:WeaponFitsPaperSlot(entry, slotName, entryStyle(entry)) and not claimed[entry.itemId] then
                out[#out + 1] = entry
            end
        end
        if slotName == "SecondaryHand" and #out < 3 then
            local pool = self:CollectWeaponPool()
            local seenName = {}
            for i = 1, #out do
                local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(out[i])) or ""
                if name ~= "" then
                    seenName[name] = true
                end
            end
            for i = 1, #pool do
                if #out >= 3 then
                    break
                end
                local entry = pool[i]
                local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)) or ""
                if self:WeaponShownInHunt(entry)
                    and GQ.Data:WeaponFitsPaperSlot(entry, "SecondaryHand", entryStyle(entry))
                    and not claimed[entry.itemId]
                    and (name == "" or not seenName[name]) then
                    if name ~= "" then
                        seenName[name] = true
                    end
                    if entry.itemId then
                        claimed[entry.itemId] = true
                    end
                    out[#out + 1] = entry
                end
            end
        end
        return out
    end
    self:EnsureActiveListCaches()

    self._filteredTopBySlot = self._filteredTopBySlot or {}
    local cached = self._filteredTopBySlot[slotName]
    if cached then
        return cached
    end

    local pool = {}
    local seen = {}
    local playerLevel = GQ:GetEffectiveLevel()
    local equip = GQ.Equip

    for _, key in ipairs(GQ.Data:GetCandidateSlotKeys(slotName)) do
        for _, entry in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
            if entry and entry.id and not seen[entry.id]
                and not entry.healOnly
                and playerLevel >= (entry.minLevel or 1)
                and self:EntrySourceAllowed(entry)
                and self:EntryMatchesPlayStyle(entry)
                and not self:EntryHiddenFromActiveFast(entry, slotName)
                and GQ.Data:ShouldShowEntry(entry)
                and GQ.Data:EntryMatchesPlayer(entry)
                and GQ.Data:EntryFitsPaperDollSlot(entry, slotName)
                and (not equip or not equip.EntryArmorIsWearable or equip:EntryArmorIsWearable(entry, slotName))
                and (not equip or not equip.EntryMatchesSpec or equip:EntryMatchesSpec(entry))
                and (not equip or not equip.MeetsRequiredLevel or equip:MeetsRequiredLevel(entry.itemId, playerLevel))
            then
                seen[entry.id] = true
                pool[#pool + 1] = entry
            end
        end
    end

    table.sort(pool, function(a, b)
        local levelA = a.minLevel or 0
        local levelB = b.minLevel or 0
        if levelA ~= levelB then
            return levelA > levelB
        end
        local scoreA = a.pipelineScore or 0
        local scoreB = b.pipelineScore or 0
        if scoreA ~= scoreB then
            return scoreA > scoreB
        end
        return (a.curatedRank or 99) < (b.curatedRank or 99)
    end)

    local results = {}
    local seenName = {}
    for i = 1, #pool do
        if #results >= 3 then
            break
        end
        local entry = pool[i]
        local name = GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(entry.itemId)
        if not (name and name ~= "" and seenName[name]) then
            if name and name ~= "" then
                seenName[name] = true
            end
            results[#results + 1] = entry
        end
    end
    self._filteredTopBySlot[slotName] = results
    return results
end

function GQ.Log:GetCompletedItemKeysForSlot(slotName)
    self:EnsureActiveListCaches()
    slotName = GQ.Data:NormalizeSlotName(slotName)
    return (self._completedItemKeysBySlot and self._completedItemKeysBySlot[slotName]) or {}
end

function GQ.Log:ShouldHideFromActiveList(entry, slotName, completedItemKeys)
    if self:EntryHiddenFromActiveFast(entry, slotName) then
        return true
    end

    if not completedItemKeys and slotName then
        completedItemKeys = self:GetCompletedItemKeysForSlot(slotName)
    end

    local itemKey = GQ.Data:EntryListKey(entry)
    if itemKey and completedItemKeys and completedItemKeys[itemKey] then
        return true
    end

    if entry.itemId and self._ownedItemIdSet and self._ownedItemIdSet[tostring(entry.itemId)] then
        return true
    end

    if self:IsEntryObtained(entry.id) or PlayerHasObtainedEntryItem(entry) then
        return true
    end

    if self:IsHuntRemoved(entry) then
        return true
    end

    return false
end

function GQ.Log:HuntsPerSlot()
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    local count = settings and tonumber(settings.huntsPerSlot) or 3
    count = math.floor(count + 0.5)
    if count < 3 then
        count = 3
    elseif count > 10 then
        count = 10
    end
    return count
end

function GQ.Log:SetHuntsPerSlot(count)
    count = math.floor((tonumber(count) or 3) + 0.5)
    if count < 3 then
        count = 3
    elseif count > 10 then
        count = 10
    end
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    if GearQuestForeverDB.settings.huntsPerSlot == count then
        return
    end
    GearQuestForeverDB.settings.huntsPerSlot = count
    self._weaponFiltered = nil
    self._heldOffHand = nil
    self._heldOffBand = nil
    self:ScheduleListRefresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

-- A listed piece gets the green arrow only when it beats what is worn.
-- An empty slot counts. Simulation has no worn comparison, so the listed
-- hunts keep the arrow there.
function GQ.Log:EntryIsListedUpgrade(entry, slotName)
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return true
    end
    if not entry or not GQ.Data or not GQ.Data.GearScoreUpgradeDelta then
        return true
    end
    local delta = GQ.Data:GearScoreUpgradeDelta(entry, slotName)
    if type(delta) ~= "number" then
        return true
    end
    return delta > 0
end

-- The hunt rows are the next ranked pieces this character does not already
-- have. Owning rank 2 at a count of 3 shows #1, #3, #4. A worn piece that
-- is not on the rank list does not take one of those places. The count is
-- Hunts per gear slot. Rank numbers stay the real ones.
function GQ.Log:RankedHuntEntries(slotName, applyFilters, limit)
    local results = {}
    local seenName = {}
    local list = self:GetSlotRankList(slotName)
    limit = limit or self:HuntsPerSlot()
    for i = 1, list and #list or 0 do
        if #results >= limit then
            break
        end
        local entry = list[i]
        if entry and not self:ShouldHideFromActiveList(entry, slotName)
            and (not applyFilters or (self:EntrySourceAllowed(entry) and self:EntryMatchesPlayStyle(entry) and self:RangedPassesFilter(entry, slotName))) then
            local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)) or ""
            if name == "" or not seenName[name] then
                if name ~= "" then
                    seenName[name] = true
                end
                results[#results + 1] = entry
            end
        end
    end
    return results
end

function GQ.Log:GetActiveSlotListEntries(slotName, plain)
    local results = {}
    local seenId = {}
    local seenItem = {}
    local notableCount = 0
    local MAX_NOTABLES_PER_SLOT = 1
    local completedItemKeys = self:GetCompletedItemKeysForSlot(slotName)

    local function addEntry(entry, allowNotable, keepObtained)
        if not entry or not entry.id or seenId[entry.id] then
            return false
        end
        if not keepObtained and self:ShouldHideFromActiveList(entry, slotName, completedItemKeys) then
            return false
        end

        local itemKey = GQ.Data:EntryListKey(entry)
        if itemKey and seenItem[itemKey] then
            return false
        end

        if allowNotable then
            if notableCount >= MAX_NOTABLES_PER_SLOT then
                return false
            end
            notableCount = notableCount + 1
        end

        seenId[entry.id] = true
        if itemKey then
            seenItem[itemKey] = true
        end
        results[#results + 1] = entry
        return true
    end

    if not plain and self:UsesWideHuntList() then
        for _, entry in ipairs(self:RankedHuntEntries(slotName, true)) do
            addEntry(entry, false)
        end

        for _, entry in ipairs(GQ.Data:GetNotableForSlot(slotName)) do
            if self:EntrySourceAllowed(entry) and self:EntryMatchesPlayStyle(entry) and self:RangedPassesFilter(entry, slotName) then
                addEntry(entry, true)
            end
        end

        for id, record in pairs(CharProgress().hunts) do
            if not seenId[id] and NormalizeHuntStatus(record.status) == "tracked" and not self:IsEntryObtained(id) then
                local entry = GQ.Data:GetEntryById(id)
                if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                    and GQ.Data:EntryMatchesPlayer(entry)
                    and self:EntryMatchesTrackedHunt(entry)
                    and self:EntrySourceAllowed(entry)
                    and self:EntryMatchesPlayStyle(entry)
                    and self:RangedPassesFilter(entry, slotName) then
                    addEntry(entry, entry.notable == true)
                end
            end
        end

        return results
    end

    for _, entry in ipairs(self:RankedHuntEntries(slotName, true)) do
        addEntry(entry, false)
    end

    for _, entry in ipairs(GQ.Data:GetNotableForSlot(slotName)) do
        if self:RangedPassesFilter(entry, slotName) then
            addEntry(entry, true)
        end
    end

    for id, record in pairs(CharProgress().hunts) do
        if not seenId[id] and NormalizeHuntStatus(record.status) == "tracked" and not self:IsEntryObtained(id) then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                and GQ.Data:EntryMatchesPlayer(entry)
                and self:EntryMatchesTrackedHunt(entry)
                and self:RangedPassesFilter(entry, slotName) then
                addEntry(entry, entry.notable == true)
            end
        end
    end

    return results
end

function GQ.Log:DisplayEntryForObtainedItem(itemId, slotName)
    if not itemId or not GQ.Data or not GQ.Data.GetEntriesByItemId then
        return nil
    end

    local matches = {}
    for _, entry in ipairs(GQ.Data:GetEntriesByItemId(itemId)) do
        if entry and (not slotName or GQ.Data:EntryMatchesSlot(entry, slotName))
            and self:EntryMatchesTrackedHunt(entry)
            and not IsDismissedCompleted(entry.id) then
            matches[#matches + 1] = entry
        end
    end
    if #matches == 0 then
        return nil
    end

    local band = GQ.Data.FilterToActiveBand and GQ.Data:FilterToActiveBand(matches) or matches
    return band[1] or matches[1]
end

function GQ.Log:CollectCompletedBySlot()
    if self._completedBySlot then
        return self._completedBySlot
    end

    local rowsBySlot = {}
    local seenId = {}

    local function consider(entry, completedAt, trustProgress)
        if not entry or not entry.id or seenId[entry.id] or IsDismissedCompleted(entry.id) then
            return
        end
        if not GQ.Data then
            return
        end
        if trustProgress then
            if not GQ.Data:EntryMatchesPlayerClass(entry) or not GQ.Data:EntryMatchesPlayerFaction(entry) then
                return
            end
        elseif not self:EntryMatchesTrackedHunt(entry) then
            return
        end
        local slotName = GQ.Data:NormalizeSlotName(entry.slot)
        if not slotName then
            return
        end
        seenId[entry.id] = true
        local bucket = rowsBySlot[slotName]
        if not bucket then
            bucket = {}
            rowsBySlot[slotName] = bucket
        end
        bucket[#bucket + 1] = {
            entry = entry,
            completedAt = completedAt or 0,
        }
    end

    local progress = CharProgress()
    if not self._prunedStaleObtained then
        self._prunedStaleObtained = true
        local dropObtained, dropHunts = {}, {}
        for id in pairs(progress.obtained or {}) do
            if not GQ.Data:GetEntryById(id) then
                dropObtained[#dropObtained + 1] = id
            end
        end
        for id, record in pairs(progress.hunts or {}) do
            if NormalizeHuntStatus(record.status) == "completed" and not GQ.Data:GetEntryById(id) then
                dropHunts[#dropHunts + 1] = id
            end
        end
        for i = 1, #dropObtained do
            progress.obtained[dropObtained[i]] = nil
        end
        for i = 1, #dropHunts do
            progress.hunts[dropHunts[i]] = nil
        end
    end

    for id, obtainedAt in pairs(progress.obtained or {}) do
        consider(GQ.Data:GetEntryById(id), obtainedAt, true)
    end

    for id, record in pairs(progress.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed" then
            consider(GQ.Data:GetEntryById(id), record.completedAt or record.trackedAt or 0, true)
        end
    end

    -- Item ids survive even when the per-hunt rows were cleared.
    local seenItem = {}
    for _, bucket in pairs(rowsBySlot) do
        for i = 1, #bucket do
            local itemId = bucket[i].entry and bucket[i].entry.itemId
            if itemId then
                seenItem[tostring(itemId)] = true
            end
        end
    end
    GearQuestForeverDB.dismissedItems = GearQuestForeverDB.dismissedItems or {}
    for itemKey, obtainedAt in pairs(progress.obtainedItems or {}) do
        if not seenItem[itemKey] and not GearQuestForeverDB.dismissedItems[itemKey] then
            local entry = self:DisplayEntryForObtainedItem(tonumber(itemKey))
            if entry then
                seenItem[itemKey] = true
                consider(entry, obtainedAt, true)
            end
        end
    end

    local bySlot = {}
    for slotName, results in pairs(rowsBySlot) do
        local equippedIlvl = GQ.Compare:GetEquippedItemLevel(slotName)
        table.sort(results, function(a, b)
            local scoreA = GQ.Compare:GetSortScore(a.entry, slotName, equippedIlvl, 0)
            local scoreB = GQ.Compare:GetSortScore(b.entry, slotName, equippedIlvl, 0)
            if scoreA ~= scoreB then
                return scoreA > scoreB
            end
            if a.completedAt ~= b.completedAt then
                return a.completedAt > b.completedAt
            end
            return a.entry.id < b.entry.id
        end)

        local entries = {}
        local seenKey = {}
        for i = 1, #results do
            local entry = results[i].entry
            local itemKey = GQ.Data:EntryListKey(entry)
            if not itemKey or not seenKey[itemKey] then
                if itemKey then
                    seenKey[itemKey] = true
                end
                entries[#entries + 1] = entry
            end
        end
        bySlot[slotName] = entries
    end

    self._completedBySlot = bySlot
    return bySlot
end

function GQ.Log:GetCompletedSlotListEntries(slotName)
    local bySlot = self:CollectCompletedBySlot()
    slotName = GQ.Data:NormalizeSlotName(slotName)
    return bySlot[slotName] or {}
end

function GQ.Log:GetRemovedScope()
    local classFile = GQ:GetEffectiveClass() or ""
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    return classFile .. ":" .. tostring(spec)
end

function GQ.Log:GetRemovedMap(create)
    local progress = CharProgress()
    local all = progress.removedItems
    if not all then
        if not create then
            return nil
        end
        all = {}
        progress.removedItems = all
    end
    local scope = self:GetRemovedScope()
    local map = all[scope]
    if not map then
        if not create then
            return nil
        end
        map = {}
        all[scope] = map
    end
    return map
end

function GQ.Log:IsHuntRemoved(entry)
    if not entry or not GQ.Data or not GQ.Data.EntryListKey then
        return false
    end
    local map = self:GetRemovedMap(false)
    if not map then
        return false
    end
    local key = GQ.Data:EntryListKey(entry)
    return key ~= nil and map[key] == true
end

function GQ.Log:GetRemovedSlotListEntries(slotName)
    local results = {}
    local seen = {}

    local function consider(entry)
        if not self:IsHuntRemoved(entry) then
            return
        end
        local key = GQ.Data:EntryListKey(entry)
        if not key or seen[key] then
            return
        end
        seen[key] = true
        results[#results + 1] = entry
    end

    for _, entry in ipairs(GQ.Data:GetCandidatesForSlot(slotName)) do
        consider(entry)
    end
    if GQ.Data.GetNotableForSlot then
        for _, entry in ipairs(GQ.Data:GetNotableForSlot(slotName)) do
            consider(entry)
        end
    end

    table.sort(results, function(a, b)
        return (a.curatedRank or 99) < (b.curatedRank or 99)
    end)
    return results
end

function GQ.Log:RemoveHunt(entry)
    if not entry or not GQ.Data or not GQ.Data.EntryListKey then
        return
    end
    local key = GQ.Data:EntryListKey(entry)
    if not key then
        return
    end

    self:GetRemovedMap(true)[key] = true
    if entry.id then
        CharProgress().hunts[entry.id] = nil
    end

    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    if GQ.Data.InvalidateQueryCache then
        GQ.Data:InvalidateQueryCache()
    end
    self:InvalidateActiveListCaches()
    self:Refresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:RestoreHunt(entry)
    if not entry or not GQ.Data or not GQ.Data.EntryListKey then
        return
    end
    local key = GQ.Data:EntryListKey(entry)
    local map = key and self:GetRemovedMap(false)
    if not key or not map then
        return
    end

    map[key] = nil
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    if GQ.Data.InvalidateQueryCache then
        GQ.Data:InvalidateQueryCache()
    end
    self:InvalidateActiveListCaches()
    self:Refresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

-- Backwards-compatible alias
function GQ.Log:GetSlotListEntries(slotName)
    local tab = self:GetListTab()
    if tab == "completed" then
        return self:GetCompletedSlotListEntries(slotName)
    end
    if tab == "removed" then
        return self:GetRemovedSlotListEntries(slotName)
    end
    return self:GetActiveSlotListEntries(slotName)
end

function GQ.Log:TrackHunt(id)
    local entry = GQ.Data:GetEntryById(id)
    if not entry then
        return
    end

    local record = EnsureHuntRecord(id)
    record.status = "tracked"
    record.trackedAt = time()
    self:CheckAutoCompletion()
    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:ActivateHunt(id)
    self:TrackHunt(id)
end

function GQ.Log:RecordCraftedItem(itemId)
    if not itemId then
        return false
    end

    local crafted = CharProgress().crafted
    if crafted[itemId] or crafted[tostring(itemId)] then
        return false
    end

    crafted[itemId] = time()
    return true
end

function GQ.Log:HandleCraftChatMessage(msg)
    local itemId = ExtractItemIdFromChatMessage(msg)
    if not itemId then
        return
    end

    if self:RecordCraftedItem(itemId) then
        self:ScheduleAutoCompletionCheck()
    end
end

function GQ.Log:HasObtainedItemId(itemId)
    if not itemId then
        return false
    end
    -- This character only. Another character's obtain must not hide the hunt.
    local items = CharProgress().obtainedItems
    local numId = tonumber(itemId)
    if items[itemId] or items[tostring(itemId)] or (numId and items[numId]) then
        return true
    end
    return false
end

function GQ.Log:IsEntryObtained(id)
    if not id then
        return false
    end
    if GetObtainedTimestamp(id) then
        return true
    end
    local record = GetHuntRecord(id)
    if record and NormalizeHuntStatus(record.status) == "completed" then
        return true
    end
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if entry and entry.suffix and entry.suffix ~= "" then
        return false
    end
    if entry and entry.itemId and self:IsItemIdObtained(entry.itemId) then
        return true
    end
    return false
end

function GQ.Log:IsItemIdObtained(itemId)
    if not itemId then
        return false
    end
    if self:HasObtainedItemId(itemId) then
        return true
    end

    local needle = tostring(itemId)
    local progress = CharProgress()

    local function entryItemMatches(entry)
        return entry and entry.itemId and tostring(entry.itemId) == needle
    end

    for id, _ in pairs(progress.obtained or {}) do
        if entryItemMatches(GQ.Data:GetEntryById(id)) then
            return true
        end
    end

    for id, record in pairs(progress.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed"
            and entryItemMatches(GQ.Data:GetEntryById(id)) then
            return true
        end
    end

    -- Same item can appear under several generated hunt ids (level band, filter pool).
    local numId = tonumber(itemId)
    local lists = { GQ.Data:GetEntriesByItemId(itemId) }
    if numId and numId ~= itemId then
        lists[#lists + 1] = GQ.Data:GetEntriesByItemId(numId)
    end

    for li = 1, #lists do
        for _, entry in ipairs(lists[li]) do
            if GetObtainedTimestamp(entry.id) then
                return true
            end
            local record = GetHuntRecord(entry.id)
            if record and NormalizeHuntStatus(record.status) == "completed" then
                return true
            end
        end
    end

    return false
end

function GQ.Log:ObtainToastTitle(entry)
    local rank = self.HuntDisplayRank and self:HuntDisplayRank(entry)
    local upgrade = false
    if entry and GQ.Data and GQ.Data.GearScoreUpgradeDelta and self.RankListContext then
        local slotName, handKind = self:RankListContext(entry)
        local deltaHand = handKind == "both" and nil or handKind
        local delta = GQ.Data:GearScoreUpgradeDelta(entry, slotName, deltaHand)
        upgrade = type(delta) == "number" and delta > 0
    end
    if rank then
        if upgrade then
            return string.format("|cffffd200Rank #%d upgrade obtained!|r", rank)
        end
        return string.format("|cffffd200Rank #%d obtained|r", rank)
    end
    if upgrade then
        return "|cffffd200Upgrade obtained!|r"
    end
    return "|cffffd200Hunt obtained|r"
end

function GQ.Log:AnnounceObtained(entry)
    if not entry or not self.obtainToastsEnabled then
        return
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if GQ.Toast and not (settings and settings.hideObtainToast) then
        GQ.Toast:ShowForEntry(entry)
    end
    local itemName = (GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry))
        or ("Item " .. tostring(entry.itemId))
    if entry.sourceType == "profession" then
        GQ:Chat("|cff66ccffGearQuest|r: Completed — " .. itemName .. " crafted.")
    else
        GQ:Chat("|cff66ccffGearQuest|r: Completed — " .. itemName .. " obtained.")
    end
end

function GQ.Log:EntryOnCurrentGearQuestList(entry, cacheOnly)
    -- The log's current list: top upgrades and the notable for this level.
    -- Not the whole candidate pool, and not an earlier band (a level 9 cloak
    -- is not a level 20 hunt). cacheOnly never builds that list.
    if not entry or not entry.slot or not GQ.Data then
        return false
    end
    local slotName = GQ.Data:NormalizeSlotName(entry.slot)
    local itemKey = GQ.Data.EntryListKey and GQ.Data:EntryListKey(entry)
    local function listHasMatch(list)
        for _, row in ipairs(list or {}) do
            if row.id == entry.id then
                return true
            end
            if entry.itemId and row.itemId == entry.itemId then
                return true
            end
            if itemKey and GQ.Data:EntryListKey(row) == itemKey then
                return true
            end
        end
        return false
    end
    local top
    if cacheOnly and GQ.Data.PeekTopUpgradesForSlot then
        top = GQ.Data:PeekTopUpgradesForSlot(slotName)
    else
        top = GQ.Data:GetTopUpgradesForSlot(slotName)
    end
    if listHasMatch(top) then
        return true
    end
    if listHasMatch(GQ.Data:GetNotableForSlot(slotName)) then
        return true
    end
    return false
end

function GQ.Log:ShouldAutoCompleteOnObtain(entry, includeReached)
    if not entry or self:IsEntryObtained(entry.id) then
        return false
    end
    if entry.suffix and entry.suffix ~= "" then
        local suffixKey = GQ.Data.EntryListKey and GQ.Data:EntryListKey(entry)
        if suffixKey and self:HasObtainedItemId(suffixKey) then
            return false
        end
    elseif self:HasObtainedItemId(entry.itemId) then
        return false
    end

    if not self:EntryMatchesTrackedHunt(entry) or not GQ.Data:ShouldShowEntry(entry) then
        return false
    end

    -- Tracked hunts are already a match. Asking the slot list first builds
    -- the catalog when the cache is cold.
    if GetHuntStatus(entry.id) == "tracked" and GQ.Data:EntryMatchesPlayer(entry) then
        return true
    end

    -- Simulator jumps and /gq wipe data only. A live loot of an older piece
    -- (Calico Cloak at level 20) is not a current hunt and must not complete.
    -- Wait until the slot list exists so this pass does not scan the catalog.
    if includeReached then
        if GQ.Data.QueryCacheNeedsWarm and GQ.Data:QueryCacheNeedsWarm() then
            return false
        end
        local playerLevel = GQ:GetEffectiveLevel()
        return playerLevel >= (entry.minLevel or 1)
    end

    return self:EntryOnCurrentGearQuestList(entry, true)
end

function GQ.Log:RememberObtainedEntry(entry, now)
    if not entry or not entry.id then
        return
    end

    now = now or time()
    local progress = CharProgress()

    self:InvalidateActiveListCaches()
    progress.obtained[entry.id] = progress.obtained[entry.id] or now
    if entry.itemId then
        local itemKey = tostring(entry.itemId)
        if entry.suffix and entry.suffix ~= "" and GQ.Data.EntryListKey then
            itemKey = GQ.Data:EntryListKey(entry) or itemKey
        end
        progress.obtainedItems[itemKey] = progress.obtainedItems[itemKey] or now
    end

    local record = GetHuntRecord(entry.id) or {}
    record.status = "completed"
    record.completedAt = record.completedAt or now
    record.obtained = true
    progress.hunts[entry.id] = record
end

function GQ.Log:MarkEntryObtained(entry, options)
    if not entry or not entry.id or self:IsEntryObtained(entry.id) then
        return false
    end

    local now = time()
    local loginKey = entry.itemId
    if entry.suffix and entry.suffix ~= "" and GQ.Data.GetEntryDisplayName then
        local fullName = GQ.Data:GetEntryDisplayName(entry)
        if fullName then
            loginKey = fullName:lower()
        end
    end
    local alreadyHadItem = self:HasObtainedItemId(loginKey)
        or (entry.suffix and entry.suffix ~= "" and GQ.Data.EntryListKey and self:HasObtainedItemId(GQ.Data:EntryListKey(entry)))
        or (not entry.suffix or entry.suffix == "") and self:HasObtainedItemId(entry.itemId)
        or (loginKey and self.ownedAtLogin and self.ownedAtLogin[loginKey])
    self:RememberObtainedEntry(entry, now)

    -- Once per item, the first time it is in bags or on the character.
    -- Taking it off and putting it back on must not toast again.
    local announce = not options or (options.showToast ~= false and options.announce ~= false)
    if announce and not alreadyHadItem then
        self:AnnounceObtained(entry)
    end

    return true
end

function GQ.Log:CompleteHunt(id)
    local entry = GQ.Data:GetEntryById(id)
    if entry then
        self:MarkEntryObtained(entry, { showToast = false })
    else
        local record = GetHuntRecord(id)
        if record then
            record.status = "completed"
            record.completedAt = time()
            CharProgress().obtained[id] = record.completedAt
        end
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:WillHuntDisappearFromActiveList(id)
    if self:GetListTab() ~= "active" then
        return false
    end

    local record = GetHuntRecord(id)
    if not record or NormalizeHuntStatus(record.status) ~= "tracked" then
        return false
    end

    local entry = GQ.Data:GetEntryById(id)
    if not entry or not entry.slot then
        return false
    end

    local slotName = GQ.Data:NormalizeSlotName(entry.slot)
    for _, upgrade in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName)) do
        if upgrade.id == id then
            return false
        end
    end

    return true
end

function GQ.Log:RequestUntrackHunt(id)
    if not id then
        return
    end
    self:UntrackHunt(id)
end

function GQ.Log:UntrackHunt(id)
    local willDisappear = self:WillHuntDisappearFromActiveList(id)
    local onCompletedTab = self:GetListTab() == "completed"

    if self:IsEntryObtained(id) and onCompletedTab then
        GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
        local entry = GQ.Data:GetEntryById(id)
        local itemKey = entry and GQ.Data:EntryListKey(entry)
        local dismissedSibling = false
        if itemKey and entry.itemId and GQ.Data.GetEntriesByItemId then
            for _, sibling in ipairs(GQ.Data:GetEntriesByItemId(entry.itemId)) do
                if sibling and sibling.id and GQ.Data:EntryListKey(sibling) == itemKey then
                    GearQuestForeverDB.dismissedCompleted[sibling.id] = true
                    dismissedSibling = true
                end
            end
        end
        if not dismissedSibling then
            GearQuestForeverDB.dismissedCompleted[id] = true
        end
        local entry = GQ.Data:GetEntryById(id)
        if entry and entry.itemId then
            local itemKey = tostring(entry.itemId)
            GearQuestForeverDB.dismissedItems = GearQuestForeverDB.dismissedItems or {}
            GearQuestForeverDB.dismissedItems[itemKey] = true
            CharProgress().obtainedItems[itemKey] = nil
            GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
            if GearQuestForeverDB.settings.completedItemBackup then
                GearQuestForeverDB.settings.completedItemBackup[itemKey] = nil
            end
        end
    end

    CharProgress().hunts[id] = nil

    if self.selectedHuntId == id and (willDisappear or onCompletedTab) then
        self.selectedHuntId = nil
    self.selectedEntry = nil
        self:ClearDetail()
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:AbandonHunt(id)
    self:RequestUntrackHunt(id)
end

function GQ.Log:WipeCharacterData()
    local progress = CharProgress()
    progress.hunts = {}
    progress.obtained = {}
    progress.obtainedItems = {}
    progress.crafted = {}
    GearQuestForeverCharDB.hunts = progress.hunts
    GearQuestForeverCharDB.obtained = progress.obtained
    GearQuestForeverCharDB.obtainedItems = progress.obtainedItems
    GearQuestForeverCharDB.crafted = progress.crafted
    GearQuestForeverDB.dismissedCompleted = {}
    GearQuestForeverDB.dismissedItems = {}
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.completedItemBackup = {}
    GearQuestForeverDB.settings.completedWipeAt = time()
    progress.removedItems = {}
    GearQuestForeverCharDB.removedItems = progress.removedItems
    GearQuestForeverDB.obtainedItems = {}
    self.ownedAtLogin = {}
    self:InvalidateActiveListCaches()

    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    self:SetListTab("active")

    if GQ.Toast and GQ.Toast.ClearQueue then
        GQ.Toast:ClearQueue()
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
    if GQ.RefreshUI then
        GQ:RefreshUI()
    end
    self:ScheduleAutoCompletionCheck(true)
end

function GQ.Log:CollectAutoCompletionCandidates()
    return GQ:WithContextSnapshot(self.BuildCollectAutoCompletionCandidates, self)
end

function GQ.Log:BuildCollectAutoCompletionCandidates()
    local seen = {}
    local candidates = {}

    local function add(entry)
        if entry and entry.id and not seen[entry.id]
            and not self:IsEntryObtained(entry.id)
            and not self:HasObtainedItemId(entry.itemId) then
            seen[entry.id] = true
            table.insert(candidates, entry)
        end
    end

    for id, record in pairs(CharProgress().hunts) do
        if NormalizeHuntStatus(record.status) == "tracked" then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesPlayer(entry) then
                add(entry)
            end
        end
    end

    -- The pinned list is already cached, so this compares bags to the list
    -- on screen. Do not build that list here. GetSlotsForClass walks every
    -- row for the class, and a loot event in a dungeon trips
    -- "script ran too long". A cold cache is filled one slot per frame.
    if GQ.Data.PeekTopUpgradesForSlot and GQ.Data.WarmSlotNames then
        local slots = GQ.Data:WarmSlotNames()
        for i = 1, #slots do
            local cached = GQ.Data:PeekTopUpgradesForSlot(slots[i])
            if cached then
                for j = 1, #cached do
                    add(cached[j])
                end
            end
        end
    end

    return candidates
end

function GQ.Log:CollectReachedOwnedHunts()
    -- Items already in bags after a sim jump or wipe. One row per item id.
    -- Never call this from a loot or bag event: walking the class catalog
    -- there trips "script ran too long" in a dungeon.
    local candidates = {}
    local seenItem = {}
    local playerLevel = GQ:GetEffectiveLevel()
    self:ForEachOwnedItemLink(function(link)
        local itemId = ItemLinkToId(link)
        if not itemId or seenItem[itemId] or self:HasObtainedItemId(itemId) then
            return
        end
        local entries = GQ.Data.GetEntriesByItemId and GQ.Data:GetEntriesByItemId(itemId) or {}
        local matched = false
        for i = 1, #entries do
            local entry = entries[i]
            if entry and entry.id
                and not entry.healOnly
                and playerLevel >= (entry.minLevel or 1)
                and GQ.Data:ShouldShowEntry(entry)
                and self:EntryMatchesTrackedHunt(entry)
                and (not entry.suffix or entry.suffix == "" or GQ.Data:EntrySuffixMatchesLink(entry, link)) then
                candidates[#candidates + 1] = entry
                matched = true
                break
            end
        end
        if matched and not (entries[1] and entries[1].suffix and entries[1].suffix ~= "") then
            seenItem[itemId] = true
        elseif matched then
            seenItem[link] = true
        end
    end)
    return candidates
end

function GQ.Log:CheckAutoCompletion(includeReached)
    local changed = false

    local ok, err = pcall(function()
        local owned = {}
        local ownedLinks = {}
        self:ForEachOwnedItemLink(function(link)
            local itemId = ItemLinkToId(link)
            if itemId then
                owned[itemId] = true
                ownedLinks[#ownedLinks + 1] = link
            end
        end)

        local function owns(entry)
            if not entry or not entry.itemId then
                return false
            end
            if entry.sourceType == "profession" and GetCraftedTimestamp(entry.itemId) then
                return true
            end
            if entry.suffix and entry.suffix ~= "" then
                return self:EntrySuffixOwned(entry, ownedLinks)
            end
            return owned[entry.itemId] == true
        end

        local seen = {}
        local list = self:CollectAutoCompletionCandidates()
        if includeReached then
            local extra = self:CollectReachedOwnedHunts()
            for i = 1, #extra do
                list[#list + 1] = extra[i]
            end
        end

        for _, entry in ipairs(list) do
            if entry and entry.id and not seen[entry.id] and owns(entry)
                and self:ShouldAutoCompleteOnObtain(entry, includeReached) then
                seen[entry.id] = true
                local tracked = GetHuntStatus(entry.id) == "tracked"
                    and GQ.Data:EntryMatchesPlayer(entry)
                local onList = tracked or self:EntryOnCurrentGearQuestList(entry, true)
                local options = nil
                if not onList then
                    options = { showToast = false, announce = false }
                end
                if self:MarkEntryObtained(entry, options) then
                    changed = true
                end
            end
        end
    end)

    if not ok then
        GQ:Chat("|cffff0000GearQuest auto-complete error:|r " .. tostring(err))
        return
    end

    if changed then
        self:InvalidateActiveListCaches()
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end

        if GQ.Tracker then
            GQ.Tracker:Refresh()
        end

        if GQ and GQ.RefreshUI then
            GQ:RefreshUI()
        end
    end

    if GQ.Data and GQ.Data.QueryCacheNeedsWarm and GQ.Data:QueryCacheNeedsWarm()
        and GQ.Data.WarmQueryCacheAsync then
        local reached = includeReached
        GQ.Data:WarmQueryCacheAsync(function()
            if GQ.Log and GQ.Log.CheckAutoCompletion then
                GQ.Log:CheckAutoCompletion(reached)
            end
        end)
    end
end

function GQ.Log:RankListCacheKey(slotName)
    local handKind = nil
    if slotName == "MainHand" and self.WeaponHeaderKind then
        handKind = self:WeaponHeaderKind()
    end
    return tostring(slotName) .. ":" .. tostring(handKind), handKind
end

function GQ.Log:RankListsReady()
    if not (GQ.Data and GQ.Data.GetSlotsForClass and GQ.Data.GetActiveBandCacheKey) then
        return true
    end
    local band = GQ.Data:GetActiveBandCacheKey()
    if self._slotRankBand ~= band or not self._slotRankCache then
        return false
    end
    local slots = GQ.Data:GetSlotsForClass(GQ:GetEffectiveClass()) or {}
    for i = 1, #slots do
        local cacheKey = self:RankListCacheKey(slots[i])
        if not self._slotRankCache[cacheKey] then
            return false
        end
    end
    return true
end

-- The hunt rows stay as they are until every slot for this level is built,
-- then the list swaps once. A cached level still refreshes on this frame.
function GQ.Log:ScheduleRankListWarm()
    if self._rankWarmRunning then
        self._rankWarmAgain = true
        return
    end
    if not (C_Timer and C_Timer.After) or not self.frame then
        self:Refresh()
        return
    end
    self._rankWarmRunning = true
    local band = GQ.Data:GetActiveBandCacheKey()
    local slots = GQ.Data:GetSlotsForClass(GQ:GetEffectiveClass()) or {}
    local index = 0
    local phase = "ranks"
    local function finish()
        self._rankWarmRunning = false
        local again = self._rankWarmAgain
        self._rankWarmAgain = nil
        local bandNow = GQ.Data.GetActiveBandCacheKey and GQ.Data:GetActiveBandCacheKey()
        if not self.frame then
            return
        end
        if again or bandNow ~= band then
            self:Refresh()
            return
        end
        self._refreshPainting = true
        self:Refresh()
    end
    local function step()
        if not self.frame then
            self._rankWarmRunning = false
            self._rankWarmAgain = nil
            return
        end
        if phase == "ranks" then
            index = index + 1
            local slotName = slots[index]
            if slotName then
                local cacheKey, handKind = self:RankListCacheKey(slotName)
                local cached = self._slotRankCache and self._slotRankBand == band and self._slotRankCache[cacheKey]
                if not cached then
                    self:GetSlotRankList(slotName, handKind)
                    C_Timer.After(0, step)
                    return
                end
                return step()
            end
            phase = "weapons"
        end
        if phase == "weapons" then
            phase = "held"
            local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
            if not (self._weaponPool and self._weaponPoolBand == ctx) then
                self:CollectWeaponPool()
                C_Timer.After(0, step)
                return
            end
        end
        if phase == "held" then
            phase = "done"
            local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
            if not (self._heldOffHand and self._heldOffBand == ctx) then
                self:HeldOffHandEntries()
                C_Timer.After(0, step)
                return
            end
        end
        C_Timer.After(0, finish)
    end
    C_Timer.After(0, step)
end

function GQ.Log:RefreshAfterRankWarm()
    if not (self.frame and self.frame:IsShown()) or not (C_Timer and C_Timer.After) then
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end
        return
    end

    local slots = {}
    if GQ.Data and GQ.Data.GetSlotsForClass then
        slots = GQ.Data:GetSlotsForClass(GQ:GetEffectiveClass()) or {}
    end
    local index = 0
    local gapLeft = 0
    local function step()
        if not (self.frame and self.frame:IsShown()) then
            return
        end
        if gapLeft > 0 then
            gapLeft = gapLeft - 1
            C_Timer.After(0, step)
            return
        end
        index = index + 1
        local slotName = slots[index]
        if not slotName then
            C_Timer.After(0, function()
                if self.frame and self.frame:IsShown() then
                    self:Refresh()
                end
            end)
            return
        end
        local handKind = nil
        if slotName == "MainHand" and self.WeaponHeaderKind then
            handKind = self:WeaponHeaderKind()
        end
        local cacheKey = tostring(slotName) .. ":" .. tostring(handKind)
        local band = GQ.Data.GetActiveBandCacheKey and GQ.Data:GetActiveBandCacheKey()
        local cached = self._slotRankCache and self._slotRankBand == band and self._slotRankCache[cacheKey]
        if not cached then
            self:GetSlotRankList(slotName, handKind)
            gapLeft = 1
            C_Timer.After(0, step)
            return
        end
        step()
    end
    C_Timer.After(0, step)
end

function GQ.Log:ScheduleListRefresh(paced)
    if paced then
        self._listRefreshPaced = true
    end
    if not C_Timer or not C_Timer.After then
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end
        return
    end

    if self._listRefreshScheduled then
        return
    end
    self._listRefreshScheduled = true
    C_Timer.After(0.15, function()
        self._listRefreshScheduled = false
        local spread = self._listRefreshPaced
        self._listRefreshPaced = nil
        if self.frame and self.frame:IsShown() then
            if spread then
                self:RefreshAfterRankWarm()
            else
                self:Refresh()
            end
        end
    end)
end

function GQ.Log:UnionOwnedAtLogin()
    self.ownedAtLogin = self.ownedAtLogin or {}

    local function add(link)
        local id = ItemLinkToId(link)
        if not id then
            return
        end
        local fullName = GQ.Data and GQ.Data.ItemLinkFullName and GQ.Data:ItemLinkFullName(link)
        if fullName and fullName:lower():find(" of ", 1, true) then
            self.ownedAtLogin[fullName:lower()] = true
        else
            self.ownedAtLogin[id] = true
        end
    end

    pcall(function()
        for invSlot = 1, 19 do
            add(GetInventoryItemLink("player", invSlot))
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                add(GetBagItemLink(bag, slot))
            end
        end
    end)
end

function GQ.Log:BeginLoginObtainScan()
    -- Later zone loads must not turn toasts off. The first scan is the only
    -- window where bags are recorded as already owned.
    if self.obtainToastsEnabled then
        return
    end
    self.obtainToastsEnabled = false
    self:UnionOwnedAtLogin()
    self:ScheduleAutoCompletionCheck()

    if self.loginObtainScanTimer then
        return
    end
    self.loginObtainScanTimer = true
    if C_Timer and C_Timer.After then
        C_Timer.After(2.5, function()
            local log = GQ.Log
            if not log then
                return
            end
            log:UnionOwnedAtLogin()
            log.completionPending = false
            log:CheckAutoCompletion()
            log.obtainToastsEnabled = true
        end)
    else
        self.obtainToastsEnabled = true
    end
end

function GQ.Log:ScheduleAutoCompletionCheck(includeReached)
    if includeReached then
        self.completionIncludeReached = true
    end
    if self.completionPending then
        return
    end
    self.completionPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            -- Bag and skill events land on the ding too. Wait for the sliced
            -- cache build rather than walking every slot here in one frame.
            local function run()
                local reached = GQ.Log.completionIncludeReached
                GQ.Log.completionPending = false
                GQ.Log.completionIncludeReached = nil
                GQ.Log:CheckAutoCompletion(reached)
            end
            if GQ.Data and GQ.Data.WarmQueryCacheAsync then
                GQ.Data:WarmQueryCacheAsync(run)
            else
                run()
            end
        end)
    else
        local reached = self.completionIncludeReached
        self.completionPending = false
        self.completionIncludeReached = nil
        self:CheckAutoCompletion(reached)
    end
end

function GQ.Log:EnsureDetailLore(frame)
    if not frame or not frame.detailChild or frame.detailLore then
        return
    end

    frame.detailLore = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailLore:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -8)
    frame.detailLore:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailLore:SetJustifyH("LEFT")
    frame.detailLore:SetWordWrap(true)
    frame.detailLore:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailLore:Hide()
end

function GQ.Log:EnsureDetailReward(frame)
    if not frame or not frame.detailChild then
        return
    end

    if frame.detailRewardIcon and frame.detailRewardIcon.name then
        return
    end

    if frame.detailRewardIcon then
        frame.detailRewardIcon:Hide()
        frame.detailRewardIcon:SetParent(nil)
        frame.detailRewardIcon = nil
    end

    if not frame.detailRewardHeader then
        frame.detailRewardHeader = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_HEADER_FONTS)
        frame.detailRewardHeader:SetPoint("TOPLEFT", frame.detailBody, "BOTTOMLEFT", 0, -16)
        frame.detailRewardHeader:SetText("REWARD")
        frame.detailRewardHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
        frame.detailRewardHeader:Hide()
    end

    frame.detailRewardIcon = CreateRewardItemButton(frame.detailChild, frame:GetName() .. "RewardItem")
    frame.detailRewardIcon:SetPoint("TOPLEFT", frame.detailRewardHeader, "BOTTOMLEFT", 0, -8)
    frame.detailRewardIcon:Hide()
end

function GQ.Log:UpdateDetailReward(entryOrItemId)
    if not self.frame then
        return
    end

    self:EnsureDetailReward(self.frame)

    local header = self.frame.detailRewardHeader
    local icon = self.frame.detailRewardIcon
    if not header or not icon then
        return
    end

    local entry = type(entryOrItemId) == "table" and entryOrItemId
        or self.selectedEntry
        or (self.selectedHuntId and GQ.Data:GetEntryById(self.selectedHuntId))
    local itemId = type(entryOrItemId) == "number" and entryOrItemId
        or (entry and entry.itemId)

    if not itemId then
        header:Hide()
        icon:Hide()
        icon.itemId = nil
        icon.entry = nil
        return
    end

    if GQ.Data and GQ.Data.RequestItemInfo then
        GQ.Data:RequestItemInfo(itemId)
    end

    header:Show()
    icon:Show()
    icon.itemId = itemId
    icon.entry = entry

    local itemName = (entry and GQ.Data:GetEntryDisplayName(entry))
        or (GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId))
        or ("Item " .. itemId)
    local nameR, nameG, nameB = 1, 1, 1
    local quality = GQ.Data and GQ.Data.GetItemQualityForDisplay and GQ.Data:GetItemQualityForDisplay(itemId)
    if quality then
        nameR, nameG, nameB = GetListItemQualityColor(itemId)
    end
    icon.name:SetTextColor(nameR, nameG, nameB)
    if icon.foreverMark then
        local foreverNew = GQ.Data and GQ.Data.foreverNew and GQ.Data.foreverNew[itemId]
        icon.foreverMark:SetShown(not not foreverNew)
    end
    local child = icon:GetParent()
    local childWidth = child and child:GetWidth() or 0
    if childWidth < 80 then
        childWidth = RIGHT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8
    end
    local reserve = 0
    if icon.foreverMark and icon.foreverMark:IsShown() then
        reserve = REWARD_ICON_SIZE + 12
    end
    local budget = childWidth - REWARD_ICON_SIZE - reserve - 4
    if budget < REWARD_NAME_MIN_WIDTH then
        budget = REWARD_NAME_MIN_WIDTH
    end
    icon.name:ClearAllPoints()
    icon.name:SetWordWrap(false)
    icon.name:SetWidth(1000)
    icon.name:SetText(itemName)
    local natural = icon.name:GetStringWidth() or 0
    local nameWidth = natural + REWARD_NAME_TEXT_PAD
    if nameWidth < REWARD_NAME_MIN_WIDTH then
        nameWidth = REWARD_NAME_MIN_WIDTH
    end
    local wrap = nameWidth > budget
    if wrap then
        nameWidth = budget
    end
    icon:SetWidth(REWARD_ICON_SIZE + nameWidth)
    icon.name:SetWordWrap(wrap)
    icon.name:SetWidth(nameWidth - REWARD_NAME_TEXT_PAD)
    icon.name:SetPoint("LEFT", icon.nameBg, "LEFT", 8, 0)
    icon.name:SetJustifyH("LEFT")
    icon.name:SetJustifyV("MIDDLE")
    local textH = icon.name:GetStringHeight() or 14
    if textH < 8 then
        textH = 14
    end
    local boxH = textH + 16
    if boxH < REWARD_ICON_SIZE then
        boxH = REWARD_ICON_SIZE
    end
    icon:SetHeight(boxH)

    local texture = SafeGetItemIcon(itemId)
    if texture then
        icon.icon:SetTexture(texture)
    else
        icon.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function GQ.Log:MeasureDetailContentHeight()
    if not self.frame then
        return 0
    end

    local height = 8

    if self.frame.detailTitle and self.frame.detailTitle:IsShown() then
        height = height + (self.frame.detailTitle:GetStringHeight() or 0) + 16
    end
    if self.frame.detailRankBox and self.frame.detailRankBox:IsShown() then
        height = height + (self.frame.detailRankBox:GetHeight() or 0) + 8
    end
    if self.frame.detailLore and self.frame.detailLore:IsShown() then
        height = height + (self.frame.detailLore:GetStringHeight() or 0) + 12
    end
    if self.frame.detailHeader and self.frame.detailHeader:IsShown() then
        height = height + (self.frame.detailHeader:GetStringHeight() or 0) + 8
    end
    if self.frame.detailBody and self.frame.detailBody:IsShown() then
        height = height + (self.frame.detailBody:GetStringHeight() or 0) + 4
    end
    if self.frame.detailCoords and self.frame.detailCoords:IsShown() then
        height = height + (self.frame.detailCoords:GetStringHeight() or 0) + 16
    end
    if self.frame.detailDone and self.frame.detailDone:IsShown() then
        height = height + (self.frame.detailDone:GetStringHeight() or 0) + 8
    end
    if self.frame.detailRewardHeader and self.frame.detailRewardHeader:IsShown() then
        local rewardH = REWARD_ICON_SIZE
        if self.frame.detailRewardIcon and self.frame.detailRewardIcon:IsShown() then
            rewardH = self.frame.detailRewardIcon:GetHeight() or REWARD_ICON_SIZE
        end
        if rewardH < REWARD_ICON_SIZE then
            rewardH = REWARD_ICON_SIZE
        end
        height = height + (self.frame.detailRewardHeader:GetStringHeight() or 0) + 8 + rewardH + 16
    end

    return height
end

function GQ.Log:UpdateDetailScrollHeight()
    if not self.frame or not self.frame.detailScroll or not self.frame.detailChild then
        return
    end

    local contentHeight = self:MeasureDetailContentHeight()
    local visibleHeight = self.frame.detailScroll:GetHeight() or 120
    if contentHeight > visibleHeight then
        self.frame.detailChild:SetHeight(contentHeight)
    else
        self.frame.detailChild:SetHeight(visibleHeight)
        self.frame.detailScroll:SetVerticalScroll(0)
    end
    UpdateScrollChildRect(self.frame.detailScroll)
    ApplyScrollBarVisibility(self.frame.detailScroll)
end

function GQ.Log:CreateListRow(index)
    local row = CreateFrame("Button", "GearQuestLogRow" .. index, self.frame.scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:Hide()
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.itemIcon = row:CreateTexture(nil, "ARTWORK")
    row.itemIcon:Hide()

    row.rankMark = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.rankMark:SetSize(16, 16)
    row.rankMark:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.rankMark:SetJustifyH("CENTER")
    row.rankMark:SetJustifyV("MIDDLE")
    row.rankMark:SetWordWrap(false)
    row.rankMark:SetTextColor(0.55, 0.55, 0.55)
    row.rankMark:Hide()

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -LIST_ROW_RIGHT_PAD, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    if row.text.SetMaxLines then
        row.text:SetMaxLines(1)
    end

    row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.meta:SetJustifyH("LEFT")
    row.meta:SetJustifyV("MIDDLE")
    row.meta:SetWordWrap(false)
    if row.meta.SetMaxLines then
        row.meta:SetMaxLines(1)
    end
    row.meta:Hide()

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    ApplyHuntRowHighlight(row.highlight)
    row.highlight:Hide()

    row.info = CreateFrame("Button", nil, row)
    row.info:SetSize(13, 13)
    row.info:SetFrameLevel(row:GetFrameLevel() + 5)
    row.info.icon = row.info:CreateTexture(nil, "OVERLAY")
    row.info.icon:SetAllPoints()
    row.info.icon:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    row.info:Hide()
    row.info:SetScript("OnEnter", function(self)
        local parent = self:GetParent()
        if parent and parent.rowType == "header" then
            GQ.Log:ShowSlotRankTooltip(parent)
        end
    end)
    row.info:EnableMouseWheel(true)
    row.info:SetScript("OnMouseWheel", function(_, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.frame and log.frame.scroll then
            ScrollFrameOnMouseWheel(log.frame.scroll, delta)
        end
    end)

    row.weaponArrow = CreateFrame("Button", nil, row)
    row.weaponArrow:SetSize(16, 16)
    row.weaponArrow:SetFrameLevel(row:GetFrameLevel() + 6)
    row.weaponArrow.icon = row.weaponArrow:CreateTexture(nil, "ARTWORK")
    row.weaponArrow.icon:SetAllPoints()
    row.weaponArrow.icon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    row.weaponArrow:Hide()
    row.weaponArrow:SetScript("OnClick", function(self)
        local log = _G.GearQuest and _G.GearQuest.Log
        local row = self:GetParent()
        if not log then
            return
        end
        if row and row.slotName == "Ranged" then
            log:ToggleRangedMenu(self)
        else
            log:ToggleWeaponMenu(self)
        end
    end)

    row:SetScript("OnEnter", function(self)
        if self.rowType == "header" then
            return
        end
        ShowItemTooltipForRow(self)
        UpdateListRowHighlight(self)
    end)

    row:SetScript("OnLeave", function(self)
        if self.recommendInfo and self.recommendInfo:IsMouseOver() then
            UpdateListRowHighlight(self)
            return
        end
        HideItemTooltip()
        UpdateListRowHighlight(self)
    end)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.frame and log.frame.scroll then
            ScrollFrameOnMouseWheel(log.frame.scroll, delta)
        end
    end)

    return row
end

function GQ.Log:EnsureTrackerEvents()
    if self.trackerFrame then
        return
    end

    local tracker = CreateFrame("Frame")
    local events = {
        "BAG_UPDATE",
        "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "MERCHANT_CLOSED",
        "CHAT_MSG_SKILL",
        "CHAT_MSG_LOOT",
        "UPDATE_FACTION",
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_SHOW",
        "TRADE_SKILL_UPDATE",
    }
    for i = 1, #events do
        GQ.RegisterEvent(tracker, events[i])
    end
    tracker:SetScript("OnEvent", function(_, event, msg)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            log:BeginLoginObtainScan()
            return
        end

        if event == "CHAT_MSG_SKILL" or event == "CHAT_MSG_LOOT" then
            log:HandleCraftChatMessage(msg)
            if event == "CHAT_MSG_SKILL" then
                log:NoteObtainabilityChanged()
            end
            return
        end

        if event == "UPDATE_FACTION" or event == "SKILL_LINES_CHANGED"
            or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
            log._playerRep = nil
            log._playerProf = nil
            log:NoteObtainabilityChanged()
            local entry = log.selectedEntry
            local src = entry and ((GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "")) or entry.sourceType)
            if entry and log.frame and log.frame:IsShown()
                and (src == "profession" or (src == "vendor" and entry.reqRep)) then
                log:ApplyEntryDetail(entry)
            end
            return
        end

        if event == "PLAYER_EQUIPMENT_CHANGED" then
            if GQ.Data then
                GQ.Data._gearScoreCache = nil
            end
            local function refreshWorn()
                if log.UpdateGearScoreBar then
                    log:UpdateGearScoreBar()
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, refreshWorn)
            else
                refreshWorn()
            end
            if log.frame and log.frame:IsShown() and log.ScheduleListRefresh then
                log:ScheduleListRefresh()
            end
        end

        if event == "BAG_UPDATE" then
            if GQ.Data and GQ.Data.CacheContainerItemLinks then
                GQ.Data:CacheContainerItemLinks()
            end
            if not log.obtainToastsEnabled then
                log:UnionOwnedAtLogin()
            end
        end

        log:ScheduleAutoCompletionCheck()
    end)
    self.trackerFrame = tracker
end

local function ApplySpecPickerChrome(picker)
    if not picker then
        return
    end

    ApplyBlackBackground(picker)
    ApplyMetalEdge(picker, 12)
end

function GQ.Log:HideSpecPicker()
    if self.frame and self.frame.specPicker then
        self.frame.specPicker:Hide()
    end
    if self._specPickerCatcher then
        self._specPickerCatcher:Hide()
    end
    -- Legacy catcher was parented to UIParent and could block the whole UI if left shown.
    local orphan = _G.GearQuestSpecPickerCatcher
    if orphan and orphan ~= self._specPickerCatcher and orphan:IsShown() then
        orphan:Hide()
    end
end

function GQ.Log:EnsureSpecPicker(frame)
    if frame.specPicker then
        ApplySpecPickerChrome(frame.specPicker)
        return frame.specPicker
    end

    local parent = frame.tabBar or frame
    local picker
    local ok, framed = pcall(CreateFrame, "Frame", "GearQuestSpecPicker", parent, "BackdropTemplate")
    if ok and framed then
        picker = framed
    else
        picker = CreateFrame("Frame", "GearQuestSpecPicker", parent)
    end

    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    picker:SetSize(SPEC_PICKER_WIDTH, SPEC_PICKER_PAD * 2)
    picker:Hide()
    ApplySpecPickerChrome(picker)
    picker.rows = {}

    if not picker.gqHideHooked then
        picker.gqHideHooked = true
        picker:HookScript("OnHide", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and log._specPickerCatcher then
                log._specPickerCatcher:Hide()
            end
        end)
    end

    frame.specPicker = picker
    return picker
end

function GQ.Log:RefreshSpecPickerRows()
    local frame = self.frame
    if not frame or not frame.specPicker or not GQ.Spec then
        return
    end

    local picker = frame.specPicker
    local classFile = GQ:GetEffectiveClass()
    local options = GQ.Spec:GetOptions(classFile) or {}
    local current = GQ.Spec:GetDisplaySpec(classFile)
    local lines = {}
    for i = 1, #options do
        lines[#lines + 1] = { kind = "spec", opt = options[i] }
    end
    lines[#lines + 1] = { kind = "divider" }
    local customs = (GQ.Custom and GQ.Custom.List and GQ.Custom:List(classFile)) or {}
    for i = 1, #customs do
        lines[#lines + 1] = { kind = "custom", record = customs[i] }
    end
    lines[#lines + 1] = { kind = "add" }

    for i, row in ipairs(picker.rows) do
        row:Hide()
    end

    local y = SPEC_PICKER_PAD
    for i = 1, #lines do
        local line = lines[i]
        local row = picker.rows[i]
        if not row then
            row = CreateFrame("Button", nil, picker)
            row:SetSize(SPEC_PICKER_WIDTH - (SPEC_PICKER_PAD * 2), SPEC_PICKER_ROW_HEIGHT)
            SafeRegisterForClicks(row, "LeftButtonUp", "RightButtonUp")
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.label:SetJustifyH("LEFT")
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.55)
            row.highlight:Hide()
            row:SetScript("OnEnter", function(self)
                if self.highlight and self:IsEnabled() then
                    self.highlight:Show()
                end
                if self.tip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.tip, 1, 0.82, 0)
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                if self.highlight then
                    self.highlight:Hide()
                end
                GameTooltip:Hide()
            end)
            row.rule = row:CreateTexture(nil, "ARTWORK")
            row.rule:SetColorTexture(0.78, 0.7, 0.48, 0.95)
            row.rule:SetHeight(1)
            row.rule:SetPoint("LEFT", row, "LEFT", 6, 0)
            row.rule:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.rule:Hide()
            row.remove = CreateFrame("Button", nil, row)
            row.remove:SetSize(16, 16)
            row.remove:SetPoint("RIGHT", row, "RIGHT", -1, 0)
            row.remove.label = row.remove:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.remove.label:SetPoint("CENTER", row.remove, "CENTER", 0, 0)
            row.remove.label:SetText("|cffff6666X|r")
            row.remove:SetScript("OnClick", function(self)
                local parent = self:GetParent()
                if parent.customId and GQ.Custom and GQ.Custom.DeleteSpec then
                    GQ.Custom:DeleteSpec(parent.classFile, parent.customId)
                end
            end)
            row.remove:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete this custom spec", 1, 0.82, 0)
                GameTooltip:Show()
            end)
            row.remove:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            row.remove:Hide()
            picker.rows[i] = row
        end

        local height = line.kind == "divider" and 10 or SPEC_PICKER_ROW_HEIGHT
        row:SetHeight(height)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", picker, "TOPLEFT", SPEC_PICKER_PAD, -y)
        row:Show()
        row.tip = nil
        row.specId = nil
        row.customId = nil
        row.classFile = classFile
        row.icon:Show()
        if row.rule then
            row.rule:Hide()
        end
        if row.remove then
            row.remove:Hide()
        end
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetText("")
        y = y + height

        if line.kind == "divider" then
            row:Disable()
            row.icon:Hide()
            if row.rule then
                row.rule:Show()
            end
            row:SetScript("OnClick", nil)
        elseif line.kind == "add" then
            row:Enable()
            row.icon:Hide()
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
            row.label:SetText("|cffFFD200+ custom stat weights|r")
            row:SetScript("OnClick", function()
                if GQ.Custom and GQ.Custom.ShowEditor then
                    GQ.Custom:ShowEditor(classFile)
                end
            end)
        else
            local specId, specLabel, icon
            if line.kind == "custom" then
                specId = line.record.id
                specLabel = line.record.name
                icon = GQ.Spec:GetSpecIcon(line.record.base, classFile)
                row.customId = specId
                row.tip = "Right-click to edit these weights."
                if row.remove then
                    row.remove:Show()
                    row.label:SetPoint("RIGHT", row.remove, "LEFT", -2, 0)
                end
            else
                specId = line.opt.id
                specLabel = line.opt.label
                icon = GQ.Spec:GetSpecIcon(specId, classFile)
            end
            row.specId = specId
            local selectable = GQ.Spec:IsSpecSelectable(specId, classFile)
            row.icon:SetTexture(icon)
            if selectable then
                row.icon:SetVertexColor(1, 1, 1)
            else
                row.icon:SetVertexColor(0.45, 0.45, 0.45)
            end
            if not selectable then
                row:Disable()
                row.label:SetText("|cff888888" .. specLabel .. " (coming later)|r")
                row:SetScript("OnClick", nil)
            else
                row:Enable()
                if current == specId then
                    row.label:SetText("|cffFFD200> |r" .. specLabel)
                else
                    row.label:SetText(specLabel)
                end
                row:SetScript("OnClick", function(self, button)
                    if button == "RightButton" and self.customId and GQ.Custom and GQ.Custom.ShowEditor then
                        GQ.Custom:ShowEditor(classFile, self.customId)
                        return
                    end
                    local picked = self.specId
                    local ok, err = GQ.Spec:SetSelectedSpec(picked, classFile)
                    if not ok then
                        GQ:Chat("|cff66ccffGearQuest|r: " .. (err or "Could not change specialization."))
                        return
                    end
                    GQ:Chat(string.format(
                        "|cff66ccffGearQuest|r: Now viewing |cff00ff00%s|r upgrades.",
                        GQ.Spec:GetSpecLabel(picked, classFile) or specLabel
                    ))
                    GQ.Log:HideSpecPicker()
                    GQ.Log:UpdateSpecButton()
                end)
            end
        end
    end

    picker:SetHeight(y + SPEC_PICKER_PAD)
end

function GQ.Log:ToggleSpecPicker(anchorBtn)
    local frame = self.frame
    if not frame or not anchorBtn then
        return
    end

    self:EnsureSpecPicker(frame)
    local picker = frame.specPicker

    if picker:IsShown() then
        self:HideSpecPicker()
        return
    end

    self:RefreshSpecPickerRows()
    picker:ClearAllPoints()
    picker:SetPoint("TOPRIGHT", anchorBtn, "BOTTOMRIGHT", 0, -2)
    local anchorLevel = anchorBtn:GetFrameLevel() or 1
    local logLevel = (frame.GetFrameLevel and frame:GetFrameLevel()) or LOG_FRAME_LEVEL
    local pickerLevel = math.max(anchorLevel, logLevel) + 30
    picker:SetFrameLevel(pickerLevel)
    picker:Show()

    if not self._specPickerCatcher then
        local catcher = CreateFrame("Frame", "GearQuestSpecPickerCatcher", frame)
        catcher:SetAllPoints(frame)
        catcher:EnableMouse(true)
        catcher:Hide()
        catcher:SetScript("OnMouseDown", function()
            GQ.Log:HideSpecPicker()
        end)
        self._specPickerCatcher = catcher
    elseif self._specPickerCatcher:GetParent() ~= frame then
        self._specPickerCatcher:SetParent(frame)
        self._specPickerCatcher:SetAllPoints(frame)
    end

    self._specPickerCatcher:SetFrameLevel(pickerLevel - 5)
    self._specPickerCatcher:Show()
end

function GQ.Log:WireSpecArrow(arrowFrame)
    if not arrowFrame or arrowFrame.gqArrowWired then
        return
    end

    arrowFrame.gqArrowWired = true
    arrowFrame:EnableMouse(true)
    SafeRegisterForClicks(arrowFrame, "LeftButtonUp")

    arrowFrame:SetScript("OnEnter", function(self)
        if self.gqHighlight then
            self.gqHighlight:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Change specialization", 1, 1, 1)
        GameTooltip:Show()
    end)
    arrowFrame:SetScript("OnLeave", function(self)
        if self.gqHighlight then
            self.gqHighlight:Hide()
        end
        GameTooltip:Hide()
    end)
    arrowFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSpecPicker(self)
            end
        end
    end)
end

function GQ.Log:ApplySpecArrowStyle(arrowFrame, iconFrame)
    if not arrowFrame then
        return
    end

    arrowFrame:SetSize(SPEC_ARROW_SIZE, SPEC_ARROW_SIZE)

    if arrowFrame.bg then
        arrowFrame.bg:Hide()
    end

    if arrowFrame.border then
        arrowFrame.border:Hide()
    end

    if arrowFrame.text then
        arrowFrame.text:Hide()
    end

    if arrowFrame.GetNormalTexture then
        HideRegion(arrowFrame:GetNormalTexture())
        HideRegion(arrowFrame.GetPushedTexture and arrowFrame:GetPushedTexture())
        HideRegion(arrowFrame.GetDisabledTexture and arrowFrame:GetDisabledTexture())
        HideRegion(arrowFrame.GetHighlightTexture and arrowFrame:GetHighlightTexture())
    end

    if not arrowFrame.arrow then
        arrowFrame.arrow = arrowFrame:CreateTexture(nil, "ARTWORK")
        arrowFrame.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    end

    arrowFrame.arrow:ClearAllPoints()
    arrowFrame.arrow:SetAllPoints(arrowFrame)
    arrowFrame.arrow:Show()

    if not arrowFrame.gqHighlight then
        arrowFrame.gqHighlight = arrowFrame:CreateTexture(nil, "HIGHLIGHT")
        arrowFrame.gqHighlight:SetAllPoints()
        arrowFrame.gqHighlight:SetColorTexture(1, 1, 1, 0.15)
        arrowFrame.gqHighlight:Hide()
    end

    if iconFrame then
        arrowFrame:ClearAllPoints()
        arrowFrame:SetPoint("CENTER", iconFrame, "RIGHT", SPEC_CONTROL_GAP + (SPEC_ARROW_SIZE / 2), 0)
    end
end

function GQ.Log:EnsureSpecArrow(frame)
    if frame.tabSpecArrow and frame.tabSpecArrow:GetObjectType() == "Button" then
        frame.tabSpecArrow:Hide()
        frame.tabSpecArrow = nil
    end

    if not frame.tabSpecArrow and frame.tabSpecControl then
        local arrowFrame = CreateFrame("Frame", nil, frame.tabSpecControl)
        frame.tabSpecArrow = arrowFrame
        self:WireSpecArrow(arrowFrame)
    end

    self:ApplySpecArrowStyle(frame.tabSpecArrow, frame.tabSpecIcon)
end

function GQ.Log:EnsureSpecControl(frame)
    if frame.tabSpecControl then
        frame.tabSpecControl:SetSize(SPEC_CONTROL_WIDTH, SPEC_CONTROL_HEIGHT)
        self:EnsureSpecArrow(frame)
        if frame.tabSpecIcon and not frame.tabSpecIcon.label then
            frame.tabSpecIcon.label = frame.tabSpecControl:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            frame.tabSpecIcon.label:SetPoint("LEFT", frame.tabSpecControl, "LEFT", 0, 0)
            frame.tabSpecIcon.label:SetPoint("RIGHT", frame.tabSpecIcon, "LEFT", -SPEC_CONTROL_GAP, 0)
            frame.tabSpecIcon.label:SetJustifyH("RIGHT")
            frame.tabSpecIcon.label:SetTextColor(1, 0.82, 0)
        end
        return frame.tabSpecControl
    end

    if frame.tabSpec then
        frame.tabSpec:Hide()
        frame.tabSpec:SetScript("OnClick", nil)
    end

    local tabBar = frame.pageBar or frame.tabBar or frame
    local control = CreateFrame("Frame", "GearQuestLogSpecControl", tabBar)
    control:SetSize(SPEC_CONTROL_WIDTH, SPEC_CONTROL_HEIGHT)
    control:Hide()

    local iconFrame = CreateFrame("Frame", nil, control)
    iconFrame:SetSize(SPEC_ICON_SIZE, SPEC_ICON_SIZE)
    iconFrame:SetPoint("LEFT", control, "LEFT", SPEC_LABEL_WIDTH + SPEC_CONTROL_GAP, 0)
    iconFrame:EnableMouse(true)
    SafeRegisterForClicks(iconFrame, "LeftButtonUp")

    iconFrame.label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    iconFrame.label:SetPoint("LEFT", control, "LEFT", 0, 0)
    iconFrame.label:SetPoint("RIGHT", iconFrame, "LEFT", -SPEC_CONTROL_GAP, 0)
    iconFrame.label:SetJustifyH("RIGHT")
    iconFrame.label:SetTextColor(1, 0.82, 0)

    iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.border:SetAllPoints()
    iconFrame.border:SetTexture("Interface\\Common\\WhiteIconFrame")

    iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)

    iconFrame:SetScript("OnEnter", function(self)
        if GQ.Compare and GQ.Compare.ShowScoringWeightTooltip then
            GQ.Compare:ShowScoringWeightTooltip(self)
            return
        end
        if not GQ.Spec then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(GQ.Spec:GetSelectedSpecLabel(), 1, 1, 1)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local nameHit = CreateFrame("Button", nil, control)
    nameHit:SetPoint("LEFT", control, "LEFT", 0, 0)
    nameHit:SetPoint("RIGHT", iconFrame, "LEFT", -SPEC_CONTROL_GAP, 0)
    nameHit:SetHeight(SPEC_CONTROL_HEIGHT)
    nameHit:SetScript("OnEnter", function(self)
        if GQ.Compare and GQ.Compare.ShowScoringWeightTooltip then
            GQ.Compare:ShowScoringWeightTooltip(self)
        end
    end)
    nameHit:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    nameHit:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ToggleSpecPicker(iconFrame)
        end
    end)
    iconFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSpecPicker(self)
            end
        end
    end)

    local arrowFrame = CreateFrame("Frame", nil, control)
    frame.tabSpecArrow = arrowFrame
    self:ApplySpecArrowStyle(arrowFrame, iconFrame)
    self:WireSpecArrow(arrowFrame)

    frame.tabSpecControl = control
    frame.tabSpecIcon = iconFrame
    return control
end

function GQ.Log:RepositionSpecButton(frame)
    if not frame then
        return
    end

    self:EnsureLogPages(frame)
    local logPage = frame.logPage
    if not logPage then
        return
    end

    self:EnsureSpecControl(frame)
    local control = frame.tabSpecControl
    if not control then
        return
    end

    if control:GetParent() ~= logPage then
        control:SetParent(logPage)
    end
    control:ClearAllPoints()
    if frame.detailBg then
        control:SetPoint("BOTTOMRIGHT", frame.detailBg, "TOPRIGHT", -2, 4)
    else
        control:SetPoint("TOPRIGHT", logPage, "TOPRIGHT", 0, 0)
    end
    if control.SetFrameLevel then
        control:SetFrameLevel(logPage:GetFrameLevel() + 8)
    end

    if frame.sourceFilterBtn then
        local listEdge = frame.listInset or logPage
        if frame.sourceFilterBtn:GetParent() ~= logPage then
            frame.sourceFilterBtn:SetParent(logPage)
        end
        frame.sourceFilterBtn:ClearAllPoints()
        -- Same row as the spec picker, flush with the gear list's right edge.
        local rowCenter = 4 + (SPEC_CONTROL_HEIGHT / 2)
        if frame.listInset then
            frame.sourceFilterBtn:SetPoint("RIGHT", frame.listInset, "TOPRIGHT", -2, rowCenter)
        else
            frame.sourceFilterBtn:SetPoint("TOPRIGHT", logPage, "TOPLEFT", LEFT_COLUMN_WIDTH - 2, 0)
        end
        frame.sourceFilterBtn:SetFrameLevel((listEdge:GetFrameLevel() or 1) + 12)
    end
end

function GQ.Log:LayoutListTopOpening()
    local frame = self.frame
    local list = frame and frame.listInset
    local top = list and list.TopEdge
    if not list or not top then
        return
    end

    if not list.gqTopLeft then
        list.gqTopLeft = list:CreateTexture(nil, "BORDER")
        list.gqTopRight = list:CreateTexture(nil, "BORDER")
    end
    local leftTex = list.gqTopLeft
    local rightTex = list.gqTopRight

    local function copyEdge(from, to)
        local path = from.GetTexture and from:GetTexture()
        if path then
            to:SetTexture(path)
        end
        if from.GetTexCoord and to.SetTexCoord then
            local u1, v1, u2, v2, u3, v3, u4, v4 = from:GetTexCoord()
            if u3 then
                to:SetTexCoord(u1, v1, u2, v2, u3, v3, u4, v4)
            elseif u2 then
                to:SetTexCoord(u1, v1, u2, v2)
            end
        end
        if from.GetVertexColor and to.SetVertexColor then
            local r, g, b, a = from:GetVertexColor()
            if r then
                to:SetVertexColor(r, g, b, a or 1)
            end
        end
        if from.GetDrawLayer and to.SetDrawLayer then
            local layer, sub = from:GetDrawLayer()
            if layer then
                to:SetDrawLayer(layer, sub)
            end
        end
    end

    local function restore()
        top:Show()
        leftTex:Hide()
        rightTex:Hide()
    end

    local page = self.GetPageTab and self:GetPageTab()
    local which = self.GetListTab and self:GetListTab()
    local tab = which == "completed" and frame.tabCompleted
        or which == "removed" and frame.tabRemoved
        or frame.tabActive
    if page ~= "log" or not tab or not tab:IsShown() or not list:IsShown() then
        restore()
        return
    end

    local listLeft, listRight = list:GetLeft(), list:GetRight()
    local tabLeft, tabRight = tab:GetLeft(), tab:GetRight()
    if not listLeft or not listRight or not tabLeft or not tabRight then
        if C_Timer and C_Timer.After and not self.gqTopOpeningQueued then
            self.gqTopOpeningQueued = true
            C_Timer.After(0, function()
                self.gqTopOpeningQueued = nil
                if self.LayoutListTopOpening then
                    self:LayoutListTopOpening()
                end
            end)
        end
        return
    end

    copyEdge(top, leftTex)
    copyEdge(top, rightTex)
    top:Hide()

    local height = top:GetHeight()
    if not height or height < 1 then
        height = 16
    end
    local corner = height
    local leftW = (tabLeft - listLeft) - corner
    local rightW = (listRight - tabRight) - corner

    leftTex:ClearAllPoints()
    leftTex:SetPoint("TOPLEFT", list, "TOPLEFT", corner, 0)
    leftTex:SetHeight(height)
    if leftW > 1 then
        leftTex:SetWidth(leftW)
        leftTex:Show()
    else
        leftTex:Hide()
    end

    rightTex:ClearAllPoints()
    rightTex:SetPoint("TOPRIGHT", list, "TOPRIGHT", -corner, 0)
    rightTex:SetHeight(height)
    if rightW > 1 then
        rightTex:SetWidth(rightW)
        rightTex:Show()
    else
        rightTex:Hide()
    end
end

function GQ.Log:UpdateTabVisuals()
    if not self.frame or not self.frame.tabActive then
        return
    end

    local tab = self:GetListTab()
    StyleGoldTab(self.frame.tabActive, tab == "active")
    StyleGoldTab(self.frame.tabCompleted, tab == "completed")
    if self.frame.tabRemoved then
        StyleGoldTab(self.frame.tabRemoved, tab == "removed")
    end
    local listLevel = (self.frame.listInset and self.frame.listInset:GetFrameLevel()) or (self.frame:GetFrameLevel() + 2)
    self.frame.tabActive:SetFrameLevel(tab == "active" and (listLevel + 8) or math.max(1, listLevel - 1))
    self.frame.tabCompleted:SetFrameLevel(tab == "completed" and (listLevel + 8) or math.max(1, listLevel - 1))
    if self.frame.tabRemoved then
        self.frame.tabRemoved:SetFrameLevel(tab == "removed" and (listLevel + 8) or math.max(1, listLevel - 1))
    end
    self:LayoutListTopOpening()
    self:UpdatePageTabVisuals()
    self:UpdateSpecButton()
end

function GQ.Log:UpdatePageTabVisuals()
    if not self.frame or not self.frame.tabLog then
        return
    end

    local page = self:GetPageTab()
    self:LayoutSideTabs(self.frame)
    if self.frame.tabBar then
        if page == "log" then
            self.frame.tabBar:Show()
        else
            self.frame.tabBar:Hide()
        end
    end
end

function GQ.Log:UpdateSpecButton()
    if not self.frame then
        return
    end

    self:EnsureSpecControl(self.frame)
    local control = self.frame.tabSpecControl
    if not control then
        return
    end

    if GQ.Spec and GQ.Spec.HasSpecs and GQ.Spec:HasSpecs() then
        control:Show()
        local classFile = GQ:GetEffectiveClass()
        local specId = GQ.Spec:GetDisplaySpec(classFile)
        if self.frame.tabSpecIcon and self.frame.tabSpecIcon.icon then
            self.frame.tabSpecIcon.icon:SetTexture(GQ.Spec:GetSpecIcon(specId, classFile))
        end
        if self.frame.tabSpecIcon and self.frame.tabSpecIcon.label then
            self.frame.tabSpecIcon.label:SetText(GQ.Spec:GetSpecLabel(specId, classFile) or "")
        end
    else
        control:Hide()
    end
    self:RepositionSpecButton(self.frame)
end

function GQ.Log:UpdateContextStatus()
    if not self.frame or not self.frame.contextStatus then
        return
    end

    local text
    if self:GetPageTab() == "settings" then
        text = "Settings"
    elseif GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        local level = GQ:GetEffectiveLevel() or UnitLevel("player") or 1
        local spec = (GQ.Spec and GQ.Spec.GetSelectedSpecLabel and GQ.Spec:GetSelectedSpecLabel()) or "Specialization"
        local classFile = GQ:GetEffectiveClass()
        local className = classFile
        if GQ.Preview and GQ.Preview.FormatClassName then
            className = GQ.Preview:FormatClassName(classFile)
        elseif classFile then
            className = classFile:sub(1, 1) .. classFile:sub(2):lower()
        end
        local faction = (GQ.GetEffectiveFaction and GQ:GetEffectiveFaction())
            or UnitFactionGroup("player")
            or "Alliance"
        text = string.format(
            "|cffe6bf47Simulation mode:|r Level %d %s %s of the %s Faction.",
            level,
            spec,
            className,
            faction
        )
    else
        local spec = (GQ.Spec and GQ.Spec.GetSelectedSpecLabel and GQ.Spec:GetSelectedSpecLabel()) or "your spec"
        text = "Viewing upgrades for your current level, class and faction — " .. spec .. "."
    end

    self.frame.contextStatus:SetText(text)
    self:LayoutContextHeading()
    self:UpdateGearScoreBar()
end

function GQ.Log:GearScoreBarShown()
    if not self.frame or self:GetPageTab() ~= "log" then
        return false
    end
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return false
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.showGearScoreBar == false then
        return false
    end
    return true
end

function GQ.Log:GearScoreFillColor(score)
    local quality = 2
    if score > 75 then
        quality = 5
    elseif score > 50 then
        quality = 4
    elseif score > 25 then
        quality = 3
    end
    local row = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if row then
        return row.r, row.g, row.b
    end
    if quality == 5 then
        return 1, 0.5, 0
    end
    if quality == 4 then
        return 0.64, 0.21, 0.93
    end
    if quality == 3 then
        return 0, 0.44, 0.87
    end
    return 0.12, 1, 0
end

function GQ.Log:GearScoreBarWords(score)
    local n = math.floor((score or 0) + 0.5)
    if n > 100 then
        n = 100
    elseif n < 0 then
        n = 0
    end
    local word = "Below average"
    if n >= 76 then
        word = "Legend"
    elseif n >= 51 then
        word = "Great"
    elseif n >= 26 then
        word = "Fair"
    end
    return n, word
end

function GQ.Log:EnsureGearScoreBar(frame)
    if frame.gearScoreBar then
        return frame.gearScoreBar
    end
    local shell = CreateFrame("Frame", nil, frame.contextStatusBar, "BackdropTemplate")
    shell:SetHeight(16)
    shell:SetPoint("BOTTOMLEFT", frame.contextStatusBar, "BOTTOMLEFT", 36, 2)
    shell:SetPoint("BOTTOMRIGHT", frame.contextStatusBar, "BOTTOMRIGHT", -36, 2)
    local title = shell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("BOTTOM", shell, "TOP", 0, 5)
    title:SetTextColor(1, 1, 1)
    shell.title = title
    shell:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = METAL_EDGE,
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    shell:SetBackdropColor(0.04, 0.03, 0.02, 0.95)
    shell:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    shell:EnableMouse(true)
    shell:SetScript("OnEnter", function(self)
        local shown, word = GQ.Log:GearScoreBarWords(self.score)
        local r, g, b = GQ.Log:GearScoreFillColor(shown)
        local hex = string.format("%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("GearQuest Score", 1, 0.82, 0)
        GameTooltip:AddLine(string.format("%d / 100 · |cff%s%s|r", shown, hex, word), 1, 1, 1)
        GameTooltip:AddLine("The average GearQuest index of the gear you are wearing.", 0.9, 0.9, 0.9, true)
        local worn = self.rows
        if worn and #worn > 0 then
            GameTooltip:AddLine(" ")
            for i = 1, #worn do
                local row = worn[i]
                local n = math.floor((row.index or 0) + 0.5)
                local scoreText = string.format("|cffffffff%d|r", n)
                if row.empty or not row.name then
                    GameTooltip:AddLine(string.format("|cffffd100%s|r  |cff999999Empty|r  %s |cff999999(empty slot)|r", row.slot or "", scoreText))
                else
                    local qr, qg, qb = GetListItemQualityColor(row.itemId)
                    local qhex = string.format("%02x%02x%02x", math.floor((qr or 1) * 255 + 0.5), math.floor((qg or 1) * 255 + 0.5), math.floor((qb or 1) * 255 + 0.5))
                    GameTooltip:AddLine(string.format("|cffffd100%s|r  |cff%s%s|r  %s", row.slot or "", qhex, row.name, scoreText))
                end
            end
        end
        GameTooltip:Show()
    end)
    shell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local status = CreateFrame("StatusBar", nil, shell)
    status:SetPoint("TOPLEFT", shell, "TOPLEFT", 4, -4)
    status:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -4, 4)
    status:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    status:SetMinMaxValues(0, 100)
    status:SetValue(0)
    shell.status = status

    local divs = {}
    for i = 1, 3 do
        local div = status:CreateTexture(nil, "OVERLAY")
        div:SetWidth(3)
        div:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        divs[i] = div
    end
    shell.divs = divs
    status:SetScript("OnSizeChanged", function(self, width)
        width = width or self:GetWidth() or 0
        for i = 1, 3 do
            local div = divs[i]
            div:ClearAllPoints()
            div:SetPoint("TOP", self, "TOPLEFT", width * i / 4, 0)
            div:SetPoint("BOTTOM", self, "BOTTOMLEFT", width * i / 4, 0)
        end
    end)

    shell:Hide()
    frame.gearScoreBar = shell
    return shell
end

function GQ.Log:UpdateGearScoreBar()
    local frame = self.frame
    if not frame or not frame.contextStatusBar then
        return
    end
    local shell = self:EnsureGearScoreBar(frame)
    if not self:GearScoreBarShown() then
        shell:Hide()
        if frame.contextStatus then
            frame.contextStatus:Show()
        end
        return
    end
    local score = 0
    local rows
    if GQ.Data and GQ.Data.GearScoreWornRows then
        rows = GQ.Data:GearScoreWornRows()
        local sum, count = 0, #rows
        for i = 1, count do
            local index = rows[i].index or 0
            if index < 0 then
                index = 0
            end
            sum = sum + index
        end
        if count > 0 then
            score = sum / count
        end
        if score < 0 then
            score = 0
        elseif score > 100 then
            score = 100
        end
        for i = 1, count do
            rows[i].order = i
        end
        table.sort(rows, function(a, b)
            local ai = a.index or 0
            local bi = b.index or 0
            if ai ~= bi then
                return ai > bi
            end
            return (a.order or 0) < (b.order or 0)
        end)
    elseif GQ.Data and GQ.Data.GearScoreBarAverage then
        score = GQ.Data:GearScoreBarAverage() or 0
    end
    shell.rows = rows
    shell.score = score
    local n, word = self:GearScoreBarWords(score)
    local r, g, b = self:GearScoreFillColor(n)
    local hex = string.format(
        "%02x%02x%02x",
        math.floor((r or 1) * 255 + 0.5),
        math.floor((g or 1) * 255 + 0.5),
        math.floor((b or 1) * 255 + 0.5)
    )
    if shell.title then
        shell.title:SetText(string.format("Your GearQuest Index Score is |cff%s%d %s|r", hex, n, word))
    end
    shell.status:SetStatusBarColor(r, g, b)
    shell.status:SetValue(score)
    shell:Show()
    if frame.contextStatus then
        frame.contextStatus:Hide()
    end
    local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
    if owner == shell then
        shell:GetScript("OnEnter")(shell)
    end
end

function GQ.Log:LayoutContextHeading()
    local frame = self.frame
    local fs = frame and frame.contextStatus
    if not fs then
        return
    end
    local simulated = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() and self:GetPageTab() ~= "settings"
    fs:ClearAllPoints()
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    if self:GetPageTab() == "settings" then
        local mid = (CONTEXT_BAND_TOP - TAB_TOP_OFFSET) / 2
        fs:SetPoint("CENTER", frame, "TOP", 0, mid)
    elseif simulated then
        local bar = frame.contextStatusBar
        fs:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -1)
        fs:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -1)
        fs:SetHeight(18)
    else
        local bar = frame.contextStatusBar
        fs:SetPoint("LEFT", bar, "LEFT", 0, 0)
        fs:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
        fs:SetPoint("TOP", bar, "TOP", 0, 0)
        fs:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    end
    local offBtn = frame.simHeaderOffBtn
    if offBtn then
        if simulated then
            offBtn:ClearAllPoints()
            offBtn:SetPoint("TOP", fs, "BOTTOM", 0, -1)
            offBtn:Show()
        else
            offBtn:Hide()
        end
    end
end

function GQ.Log:EnsureContextStatus(frame)
    if not frame.contextStatusBar then
        frame.contextStatusBar = CreateFrame("Frame", nil, frame)
        frame.contextStatusBar:SetHeight(CONTEXT_BAND_HEIGHT)
    end
    frame.contextStatusBar:ClearAllPoints()
    frame.contextStatusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 58, CONTEXT_BAND_TOP)
    frame.contextStatusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, CONTEXT_BAND_TOP)
    frame.contextStatusBar:Show()

    if not frame.contextStatus then
        frame.contextStatus = CreateFontStringWithFallback(frame.contextStatusBar, {
            "GameFontNormalLarge",
            "GameFontHighlight",
            "QuestFont",
        })
        frame.contextStatus:SetJustifyH("CENTER")
        frame.contextStatus:SetJustifyV("MIDDLE")
        frame.contextStatus:SetTextColor(1, 0.97, 0.88, 1)
        frame.contextStatus:SetAlpha(1)
        if frame.contextStatus.SetShadowColor then
            frame.contextStatus:SetShadowColor(0, 0, 0, 1)
        end
        if frame.contextStatus.SetShadowOffset then
            frame.contextStatus:SetShadowOffset(1, -1)
        end
    end
    frame.contextStatus:ClearAllPoints()
    frame.contextStatus:SetPoint("LEFT", frame.contextStatusBar, "LEFT", 0, 0)
    frame.contextStatus:SetPoint("RIGHT", frame.contextStatusBar, "RIGHT", 0, 0)
    frame.contextStatus:SetPoint("TOP", frame.contextStatusBar, "TOP", 0, 0)
    frame.contextStatus:SetPoint("BOTTOM", frame.contextStatusBar, "BOTTOM", 0, 0)
    frame.contextStatus:Show()
    if not frame.simHeaderOffBtn then
        local offBtn = CreateFrame("Button", "GearQuestSimHeaderOffButton", frame.contextStatusBar, "UIPanelButtonTemplate")
        offBtn:SetSize(168, 22)
        offBtn:SetText("Turn off simulation")
        offBtn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
                log:ResetSimulator()
            end
        end)
        offBtn:Hide()
        frame.simHeaderOffBtn = offBtn
    end
    self:UpdateContextStatus()
end

function GQ.Log:UpdateFooterButtons()
    if not self.frame then
        return
    end

    local track = self.frame.trackBtn
    local mapBtn = self.frame.mapBtn
    if self.frame.untrackBtn then
        self.frame.untrackBtn:Hide()
    end

    if self.frame.exitBtn then
        self.frame.exitBtn:Show()
    end

    if self:GetPageTab() ~= "log" and self:GetPageTab() ~= "lookup" then
        if track then
            track:Hide()
        end
        if mapBtn then
            mapBtn:Hide()
        end
        if self.frame.removeBtn then
            self.frame.removeBtn:Hide()
        end
        if self.frame.restoreBtn then
            self.frame.restoreBtn:Hide()
        end
        self:StartTrackIntro(track)
        return
    end

    local onLookup = self:GetPageTab() == "lookup"
    local tab = onLookup and "active" or self:GetListTab()
    local lookupEntry = onLookup and self.lookupEntry or nil
    local selectedId = lookupEntry and lookupEntry.id or (not onLookup and self.selectedHuntId or nil)
    local status = selectedId and GetHuntStatus(selectedId) or nil
    local isTracked = status == "tracked"

    if track then
        track:Show()
        if tab == "completed" then
            track:SetText("Remove")
            track:SetEnabled(selectedId ~= nil)
        elseif isTracked then
            track:SetText("Untrack")
            track:SetEnabled(selectedId ~= nil)
        else
            track:SetText("Track")
            track:SetEnabled(selectedId ~= nil)
        end
    end
    local onRemovedTab = tab == "removed"
    if mapBtn then
        if onRemovedTab then
            mapBtn:Hide()
        else
            mapBtn:Show()
            local entry = lookupEntry or self.selectedEntry
            if not entry and selectedId and GQ.Data and GQ.Data.GetEntryById then
                entry = GQ.Data:GetEntryById(selectedId)
            end
            local hasSpot = entry and GQ.Map and GQ.Map.HasSpot and GQ.Map:HasSpot(entry)
            mapBtn:SetEnabled(hasSpot and true or false)
            mapBtn.missingCoords = entry and not hasSpot and true or false
        end
    end
    if track and onRemovedTab then
        track:Hide()
    end
    if self.frame.removeBtn then
        if tab == "active" and selectedId and self:GetPageTab() ~= "lookup" then
            self.frame.removeBtn:Show()
            self.frame.removeBtn:SetEnabled(true)
        else
            self.frame.removeBtn:Hide()
        end
    end
    if self.frame.restoreBtn then
        if onRemovedTab and selectedId then
            self.frame.restoreBtn:Show()
            self.frame.restoreBtn:SetEnabled(true)
        else
            self.frame.restoreBtn:Hide()
        end
    end
    self:StartTrackIntro(track)
end

function GQ.Log:EnsurePageBar(frame)
    if not frame.pageBar then
        local pageBar = CreateFrame("Frame", nil, frame)
        pageBar:SetHeight(math.max(TAB_HEIGHT, SPEC_CONTROL_HEIGHT))
        frame.pageBar = pageBar
    end
    if frame.pageBar.tabGroup then
        frame.pageBar.tabGroup:Hide()
    end
    return frame.pageBar
end

local function SideTabStride()
    return SIDE_TAB_HEIGHT + SIDE_TAB_GAP
end

local function SideTabRailHeight()
    return (SIDE_TAB_HEIGHT * 4) + (SIDE_TAB_GAP * 3)
end

function GQ.Log:EnsureSideTabs(frame)
    if not frame.sideTabRail then
        frame.sideTabRail = CreateFrame("Frame", nil, frame)
        frame.sideTabRail:SetSize(SIDE_TAB_WIDTH, SideTabRailHeight())
    end
    local rail = frame.sideTabRail

    if not frame.tabLog then
        frame.tabLog = CreateHandleTab(rail, "GearQuestPageTabLog", "GearQuest Log", HANDLE_ART.log)
        frame.tabLog:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("log")
            end
        end)
    else
        frame.tabLog:SetParent(rail)
        frame.tabLog.gqLabel = frame.tabLog.gqLabel or "GearQuest Log"
        frame.tabLog.gqIconPath = HANDLE_ART.log
        frame.tabLog:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabLog:GetScript("OnClick") then
            frame.tabLog:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("log")
                end
            end)
        end
    end


    if not frame.tabLookup then
        frame.tabLookup = CreateHandleTab(rail, "GearQuestPageTabLookup", "Lookup", HANDLE_ART.lookup)
        frame.tabLookup:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("lookup")
            end
        end)
    else
        frame.tabLookup:SetParent(rail)
        frame.tabLookup.gqLabel = frame.tabLookup.gqLabel or "Lookup"
        frame.tabLookup.gqIconPath = HANDLE_ART.lookup
        frame.tabLookup:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabLookup:GetScript("OnClick") then
            frame.tabLookup:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("lookup")
                end
            end)
        end
    end

    if not frame.tabSimulator then
        frame.tabSimulator = CreateHandleTab(rail, "GearQuestPageTabSimulator", "Simulator", HANDLE_ART.simulator)
        frame.tabSimulator:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("simulator")
            end
        end)
    else
        frame.tabSimulator:SetParent(rail)
        frame.tabSimulator.gqLabel = frame.tabSimulator.gqLabel or "Simulator"
        frame.tabSimulator.gqIconPath = HANDLE_ART.simulator
        frame.tabSimulator:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabSimulator:GetScript("OnClick") then
            frame.tabSimulator:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("simulator")
                end
            end)
        end
    end

    if not frame.tabSettings then
        frame.tabSettings = CreateHandleTab(rail, "GearQuestPageTabSettings", "Settings", HANDLE_ART.settings)
        frame.tabSettings:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("settings")
            end
        end)
    else
        frame.tabSettings:SetParent(rail)
        frame.tabSettings.gqLabel = frame.tabSettings.gqLabel or "Settings"
        frame.tabSettings.gqIconPath = HANDLE_ART.settings
        frame.tabSettings:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabSettings:GetScript("OnClick") then
            frame.tabSettings:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("settings")
                end
            end)
        end
    end

    return rail
end

function GQ.Log:LayoutSideTabs(frame)
    if not frame then
        return
    end

    local rail = self:EnsureSideTabs(frame)
    if rail:GetParent() ~= UIParent then
        rail:SetParent(UIParent)
    end
    if rail.SetFrameStrata then
        rail:SetFrameStrata(LOG_FRAME_STRATA)
    end

    local frameLevel = frame:GetFrameLevel() or LOG_FRAME_LEVEL
    local railLevel = frameLevel + 5
    local frontLevel = frameLevel + 12
    local backLevel = frameLevel + 6
    rail:SetFrameLevel(railLevel)
    rail:ClearAllPoints()
    rail:SetPoint("TOPLEFT", frame, "TOPRIGHT", -SIDE_TAB_OVERLAP, SIDE_TAB_TOP)
    rail:SetSize(SIDE_TAB_WIDTH, SideTabRailHeight())
    if frame:IsShown() then
        rail:Show()
    else
        rail:Hide()
    end

    if not frame.gqRailHideWired then
        frame.gqRailHideWired = true
        local prevHide = frame:GetScript("OnHide")
        frame:SetScript("OnHide", function(self, ...)
            if self.sideTabRail then
                self.sideTabRail:Hide()
            end
            if GQ.Log and GQ.Log.weaponMenu then
                GQ.Log.weaponMenu:Hide()
            end
            if prevHide then
                prevHide(self, ...)
            end
        end)
    end

    local page = self:GetPageTab()
    frame.tabLog:ClearAllPoints()
    frame.tabLog:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, 0)
    frame.tabLookup:ClearAllPoints()
    frame.tabLookup:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, -SideTabStride())
    frame.tabSimulator:ClearAllPoints()
    frame.tabSimulator:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, -(SideTabStride() * 2))
    frame.tabSettings:ClearAllPoints()
    frame.tabSettings:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, -(SideTabStride() * 3))
    frame.tabLog:Show()
    frame.tabLookup:Show()
    frame.tabSimulator:Show()
    frame.tabSettings:Show()
    frame.tabLog:SetFrameLevel(page == "log" and frontLevel or backLevel)
    frame.tabLookup:SetFrameLevel(page == "lookup" and frontLevel or backLevel)
    frame.tabSimulator:SetFrameLevel(page == "simulator" and frontLevel or backLevel)
    frame.tabSettings:SetFrameLevel(page == "settings" and frontLevel or backLevel)
    StyleHandleTab(frame.tabLog, page == "log")
    StyleHandleTab(frame.tabLookup, page == "lookup")
    StyleHandleTab(frame.tabSimulator, page == "simulator")
    StyleHandleTab(frame.tabSettings, page == "settings")
end

function GQ.Log:EnsureLogPages(frame)
    if not frame.logPage then
        frame.logPage = CreateFrame("Frame", nil, frame)
    end
    if not frame.simPage then
        frame.simPage = CreateFrame("Frame", nil, frame)
    end
    if not frame.settingsPage then
        frame.settingsPage = CreateFrame("Frame", nil, frame)
    end
    if not frame.lookupPage then
        frame.lookupPage = CreateFrame("Frame", nil, frame)
    end
    return frame.logPage, frame.simPage
end

function GQ.Log:LayoutMainWindow(frame)
    if not frame then
        return
    end

    local pageBar = self:EnsurePageBar(frame)
    local logPage, simPage = self:EnsureLogPages(frame)
    self:EnsureSideTabs(frame)

    logPage:ClearAllPoints()
    logPage:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_LEFT, -TAB_TOP_OFFSET)
    logPage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, 0)

    simPage:ClearAllPoints()
    simPage:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
    simPage:SetPoint("BOTTOMRIGHT", logPage, "BOTTOMRIGHT", 0, 0)

    if frame.lookupPage then
        frame.lookupPage:ClearAllPoints()
        frame.lookupPage:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
        frame.lookupPage:SetPoint("BOTTOMRIGHT", logPage, "BOTTOMRIGHT", 0, 0)
    end

    local settingsPage = frame.settingsPage
    if settingsPage then
        settingsPage:ClearAllPoints()
        settingsPage:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
        settingsPage:SetPoint("BOTTOMRIGHT", logPage, "BOTTOMRIGHT", 0, 0)
    end

    if pageBar:GetParent() ~= logPage then
        pageBar:SetParent(logPage)
    end
    pageBar:SetHeight(TAB_HEIGHT)
    pageBar:ClearAllPoints()
    pageBar:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
    pageBar:SetWidth(LEFT_COLUMN_WIDTH)
    pageBar:Show()

    self:EnsureContextStatus(frame)

    self:LayoutSideTabs(frame)
    self:EnsureLookupWidgets(frame)
    self:LayoutLookupPage(frame)
    self:LayoutLogColumns(frame)
    self:RepositionSpecButton(frame)
    self:LayoutSimulatorPage(frame)
    self:LayoutSettingsPage(frame)
    self:LayoutFooterButtons(frame)
    self:ApplyPageTab()
end

function GQ.Log:LayoutLogColumns(frame)
    local logPage = frame.logPage
    if not logPage then
        return
    end

    local filterHeight = math.max(TAB_HEIGHT, SPEC_CONTROL_HEIGHT)
    local listTop = LOG_SECTION_TOP

    if frame.listInset then
        if frame.listInset:GetParent() ~= logPage then
            frame.listInset:SetParent(logPage)
        end
        frame.listInset:ClearAllPoints()
        frame.listInset:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, listTop)
        frame.listInset:SetPoint("BOTTOMLEFT", logPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
        frame.listInset:SetWidth(LEFT_COLUMN_WIDTH)
        if not self:LogSceneTexture() then
            ApplyBlackBackground(frame.listInset)
        end
        ApplyMetalEdge(frame.listInset, 16)
        if self.LayoutListTopOpening then
            self:LayoutListTopOpening()
        end
    end

    if frame.scroll and frame.listInset then
        LayoutColumnScroll(frame.scroll, frame.listInset)
    end

    if frame.scrollChild then
        frame.scrollChild:SetWidth(LEFT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET)
    end

    if frame.sectionDivider then
        frame.sectionDivider:Hide()
    end

    if frame.listGutter then
        frame.listGutter:Hide()
    end
    if frame.detailGutter then
        frame.detailGutter:Hide()
    end

    self:PlaceDetailPanel(frame)

    if self.UpdateLogScene then
        self:UpdateLogScene()
    end

    if frame.detailChild then
        frame.detailChild:SetWidth(RIGHT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8)
    end

    LayoutDetailScroll(frame)
end

local function WireHuntButtonTooltip(btn, text)
    if not btn or btn.gqTipWired then
        return
    end
    btn.gqTipWired = true
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function GQ.Log:EnsureOmitButtons(frame)
    if not frame or not frame.detailBg then
        return
    end

    if not frame.removeBtn then
        local btn = CreateFrame("Button", "GearQuestLogRemoveButton", frame.detailBg, "UIPanelButtonTemplate")
        btn:SetSize(78, 22)
        btn:SetText("Remove")
        btn:Hide()
        btn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log or not log.selectedEntry then
                return
            end
            log:RemoveHunt(log.selectedEntry)
        end)
        WireHuntButtonTooltip(btn, "The hunt will be removed.")
        frame.removeBtn = btn
    end

    if not frame.restoreBtn then
        local btn = CreateFrame("Button", "GearQuestLogRestoreButton", frame.detailBg, "UIPanelButtonTemplate")
        btn:SetSize(84, 22)
        btn:SetText("Restore")
        btn:Hide()
        btn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log or not log.selectedEntry then
                return
            end
            log:RestoreHunt(log.selectedEntry)
        end)
        WireHuntButtonTooltip(btn, "Puts the hunt back into its rightful place.")
        frame.restoreBtn = btn
    end
end

function GQ.Log:EnsureHuntsPerSlot(frame)
    frame = frame or self.frame
    if not frame or frame.huntsPerSlot then
        return
    end

    local host = CreateFrame("Frame", nil, frame, BackdropFrameTemplate())
    host:SetHeight(22)
    host:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_LEFT, FOOTER_BUTTON_Y)
    local windowLevel = (frame.gqOuterBorder and frame.gqOuterBorder.GetFrameLevel and frame.gqOuterBorder:GetFrameLevel() or (frame:GetFrameLevel() or 1)) + 3
    host:SetFrameLevel(windowLevel)
    if host.SetBackdrop then
        host:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 8,
        })
        -- Same fill as the side handle bars.
        host:SetBackdropColor(PANEL_BG[1], PANEL_BG[2], PANEL_BG[3], PANEL_BG[4] or 1)
    else
        local fill = host:CreateTexture(nil, "BACKGROUND")
        fill:SetAllPoints()
        fill:SetColorTexture(PANEL_BG[1], PANEL_BG[2], PANEL_BG[3], PANEL_BG[4] or 1)
    end

    local label = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", host, "LEFT", 8, 0)
    label:SetJustifyH("LEFT")
    label:SetText("Hunts per gear slot")
    label:SetTextColor(1, 0.82, 0)

    local slider
    local createdOk, created = pcall(CreateFrame, "Slider", "GearQuestHuntsPerSlotSlider", host, "OptionsSliderTemplate")
    if createdOk and created then
        slider = created
    else
        slider = CreateFrame("Slider", "GearQuestHuntsPerSlotSlider", host)
        slider:SetOrientation("HORIZONTAL")
        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        thumb:SetSize(32, 32)
        slider:SetThumbTexture(thumb)
    end
    slider:SetMinMaxValues(3, 10)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end
    local sliderName = slider:GetName()
    local lowText = slider.Low or (sliderName and _G[sliderName .. "Low"])
    local highText = slider.High or (sliderName and _G[sliderName .. "High"])
    local titleText = slider.Text or (sliderName and _G[sliderName .. "Text"])
    if lowText then
        lowText:SetText("")
    end
    if highText then
        highText:SetText("")
    end
    if titleText then
        titleText:SetText("")
        titleText:Hide()
    end

    local valueText = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("RIGHT", host, "RIGHT", -8, 0)
    valueText:SetWidth(22)
    valueText:SetJustifyH("RIGHT")
    valueText:SetTextColor(1, 0.82, 0)
    slider:ClearAllPoints()
    slider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    slider:SetPoint("RIGHT", valueText, "LEFT", -8, 0)
    slider:SetHeight(17)

    local function ShowCount(raw)
        local count = math.floor((tonumber(raw) or 3) + 0.5)
        if count < 3 then
            count = 3
        elseif count > 10 then
            count = 10
        end
        valueText:SetText(tostring(count))
        return count
    end

    slider:SetScript("OnValueChanged", function(self, raw)
        ShowCount(raw)
        if self._gqQuiet then
            return
        end
        if IsMouseButtonDown and IsMouseButtonDown("LeftButton") then
            return
        end
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetHuntsPerSlot(raw)
        end
    end)
    slider:SetScript("OnMouseUp", function(self)
        if self._gqQuiet then
            return
        end
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetHuntsPerSlot(self:GetValue())
        end
    end)
    slider:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Hunts per gear slot")
        GameTooltip:AddLine("The list updates when you let go. Rank 1, 2, and 3 stay the best in slot.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    slider:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    slider._gqQuiet = true
    slider:SetValue(self:HuntsPerSlot())
    slider._gqQuiet = nil
    ShowCount(self:HuntsPerSlot())

    host:SetWidth(LEFT_COLUMN_WIDTH)
    frame.huntsPerSlot = host
    frame.huntsPerSlotSlider = slider
end

function GQ.Log:EnsurePlayStyle(frame)
    frame = frame or self.frame
    if GearQuestForeverDB and GearQuestForeverDB.ui then
        GearQuestForeverDB.ui.playDontLookBack = nil
    end
    if not frame or frame.playStyleBtn then
        return
    end

    local btn = CreateFrame("Button", "GearQuestPlayStyleButton", frame, "UIPanelButtonTemplate")
    btn:SetSize(118, 22)
    btn:SetText("Play style")
    btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_LEFT + LEFT_COLUMN_WIDTH + COLUMN_GAP, FOOTER_BUTTON_Y)
    btn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:DismissPlayStyleIntro()
            log:TogglePlayStylePanel()
        end
    end)
    local windowLevel = (frame.gqOuterBorder and frame.gqOuterBorder.GetFrameLevel and frame.gqOuterBorder:GetFrameLevel() or (frame:GetFrameLevel() or 1)) + 3
    btn:SetFrameLevel(windowLevel)
    frame.playStyleBtn = btn
    self:UpdatePlayStyleButton()

    local panel = CreateFrame("Frame", "GearQuestPlayStylePanel", frame, "BackdropTemplate")
    -- The log title is drawn on the portrait frame above a DIALOG child.
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(300)
    panel:EnableMouse(true)
    panel:SetSize(640, 560)
    if panel.SetClampedToScreen then
        panel:SetClampedToScreen(true)
    end
    panel:SetPoint("CENTER", frame, "CENTER", 0, 20)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if panel.SetBackdropColor then
        panel:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if panel.SetBackdropBorderColor then
        panel:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    panel:Hide()

    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", panel, "TOP", 0, -14)
    heading:SetJustifyH("CENTER")
    heading:SetText("Play Style")
    heading:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    local headingFont, _, headingFlags = heading:GetFont()
    if headingFont then
        heading:SetFont(headingFont, 18, headingFlags)
    end
    panel.heading = heading

    local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -40)
    intro:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -40)
    intro:SetJustifyH("CENTER")
    intro:SetJustifyV("TOP")
    intro:SetWordWrap(true)
    local introFont, _, introFlags = intro:GetFont()
    if introFont then
        intro:SetFont(introFont, 15, introFlags)
    end
    intro:SetText("A play style hides hunts that do not fit how you want to play. You can turn several on at once. Each one can cover several sources. The filter still only chooses a source.")
    panel.intro = intro

    local function cardTip(owner, heading, body)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(heading, 1, 0.82, 0)
        GameTooltip:AddLine(body, 1, 1, 1, true)
        GameTooltip:SetFrameStrata("TOOLTIP")
        GameTooltip:Show()
        GameTooltip:SetFrameLevel(400)
    end

    local function makeCard(titleText, iconPath, anchor, dx, dy, tip, onClick)
        local card = CreateFrame("Button", nil, panel, "BackdropTemplate")
        card:SetSize(88, 88)
        card:SetPoint("TOP", anchor, "BOTTOM", dx, dy)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        card:SetBackdropColor(0, 0, 0, 0.9)
        card:SetBackdropBorderColor(1, 0.82, 0.2, 1)
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(76, 76)
        icon:SetPoint("CENTER", card, "CENTER", 0, 0)
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetTexture(iconPath)
        card.icon = icon
        local titleFs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFs:SetPoint("TOP", card, "BOTTOM", 0, -6)
        titleFs:SetWidth(160)
        titleFs:SetJustifyH("CENTER")
        titleFs:SetText(titleText)
        titleFs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        card.title = titleFs
        card:SetScript("OnClick", onClick)
        card:SetScript("OnEnter", function(self)
            cardTip(self, titleText, tip)
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        return card
    end

    local art = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\"
    panel.noDungeonsCard = makeCard(
        "No Dungeons!",
        art .. "GQ-Play-NoDungeon.png",
        intro, -190, -32,
        "Hides hunts that send you into a dungeon or raid: boss drops, trash, and quests that enter an instance at any step. World bosses stay. Crafts you can buy stay. Turns off Dungeon Enjoyer.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetNoDungeons(not log:NoDungeonsEnabled())
            end
        end
    )
    panel.dungeonEnjoyerCard = makeCard(
        "Dungeon Enjoyer",
        art .. "GQ-Play-Dungeon.png",
        intro, 0, -32,
        "Shows only hunts from a dungeon or raid: boss drops, trash, and quests that enter an instance at any step. World bosses, crafts, vendors, and outdoor hunts stay hidden. Turns off No Dungeons!",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetDungeonEnjoyer(not log:DungeonEnjoyerEnabled())
            end
        end
    )
    panel.getItTodayCard = makeCard(
        "Get it now!",
        art .. "GQ-Play-GetItNow.png",
        intro, 190, -32,
        "Hides a hunt you cannot get yet. A vendor piece waits until you reach the standing stored on that item. A bind-on-pickup craft waits until you have that profession and the skill on the hunt. A bind-on-equip craft stays, unless the item itself requires the profession to wear. When you reach the standing or the skill, the hunt shows up on its own.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetGetItToday(not log:GetItTodayEnabled())
            end
        end
    )
    panel.manageableDungeonsCard = makeCard(
        "Manageable Dungeons",
        art .. "GQ-Play-ManageableDungeons.png",
        panel.dungeonEnjoyerCard, -190, -36,
        "Hides a boss drop, and dungeon and raid trash, until the level you are viewing is 4 under that item's level. An item of level 49 can show from 45. The wait stops at 60, so a raid drop with a higher item level still shows at 60. Other sources stay.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetManageableDungeons(not log:ManageableDungeonsEnabled())
            end
        end
    )
    panel.manageableCard = makeCard(
        "Manageable Quests",
        art .. "GQ-Play-Manageable.png",
        panel.dungeonEnjoyerCard, 0, -36,
        "Hides a quest reward until the level you are viewing is 4 under that item's level. An item of level 49 can show from 45. The wait stops at 60, so a raid reward with a higher item level still shows at 60. Other sources stay.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetManageableQuests(not log:ManageableQuestsEnabled())
            end
        end
    )
    panel.buyItCard = makeCard(
        "Buy it",
        art .. "GQ-Play-BuyIt.png",
        panel.dungeonEnjoyerCard, 190, -36,
        "Keeps hunts you can buy. Vendor pieces stay. So does anything that binds when equipped, binds when used, or does not bind. Bind on pickup stays hidden, unless a vendor sells it. Get it now still waits on the standing.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetBuyIt(not log:BuyItEnabled())
            end
        end
    )
    panel.focusZoneCard = makeCard(
        "Focus Zone",
        art .. "GQ-Play-FocusZone.png",
        panel.manageableDungeonsCard, 0, -36,
        "Shows only hunts with a spot in the zone you are standing in. Quests, vendors, crafts, world drops, and dungeon drops all follow that zone. A drop with a camp here stays, even when it also drops somewhere else. A hunt with no place stays hidden. Walk into another zone and the list changes.",
        function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetFocusZone(not log:FocusZoneEnabled())
            end
        end
    )

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 22)
    closeBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 14)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)
    frame.playStylePanel = panel
    self:SetSimulatorChoiceHighlight(panel.noDungeonsCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.dungeonEnjoyerCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.getItTodayCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.manageableDungeonsCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.manageableCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.buyItCard, false, 0.35)
    self:SetSimulatorChoiceHighlight(panel.focusZoneCard, false, 0.35)
    self:StartPlayStyleIntro(btn)
end

function GQ.Log:StartPlayStyleIntro(btn)
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    if not btn or (ui and ui.playStyleSeen) or btn.introWash then
        return
    end

    local wash = btn:CreateTexture(nil, "OVERLAY")
    wash:SetPoint("TOPLEFT", btn, "TOPLEFT", 5, -4)
    wash:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -5, 4)
    wash:SetColorTexture(1, 0.82, 0.28, 1)
    wash:SetBlendMode("ADD")
    wash:SetAlpha(0)
    btn.introWash = wash
    btn._pulseT = 0
    btn:SetScript("OnUpdate", function(self, elapsed)
        self._pulseT = (self._pulseT or 0) + (elapsed or 0)
        local wave = 0.5 - 0.5 * math.cos(self._pulseT * 1.4)
        wash:SetAlpha(wave * 0.28)
    end)
end

function GQ.Log:DismissPlayStyleIntro()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.playStyleSeen = true
    local btn = self.frame and self.frame.playStyleBtn
    if not btn then
        return
    end
    btn:SetScript("OnUpdate", nil)
    if btn.introWash then
        btn.introWash:Hide()
    end
end

function GQ.Log:StartTrackIntro(btn)
    local ui = GearQuestForeverDB and GearQuestForeverDB.ui
    if not btn or (ui and ui.trackSeen) then
        if btn and btn.introWash then
            btn.introWash:Hide()
        end
        if btn and btn._trackIntro then
            btn:SetScript("OnUpdate", nil)
            btn._trackIntro = nil
        end
        return
    end
    if not btn.introWash then
        local wash = btn:CreateTexture(nil, "OVERLAY")
        wash:SetPoint("TOPLEFT", btn, "TOPLEFT", 5, -4)
        wash:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -5, 4)
        wash:SetColorTexture(1, 0.82, 0.28, 1)
        wash:SetBlendMode("ADD")
        wash:SetAlpha(0)
        wash:Hide()
        btn.introWash = wash
    end
    -- Greyed-out and hidden buttons still draw child textures. Pulse only
    -- while this button can take a click.
    local active = btn:IsVisible() and btn:IsEnabled()
    if not active then
        btn.introWash:Hide()
        if btn._trackIntro then
            btn:SetScript("OnUpdate", nil)
            btn._trackIntro = nil
        end
        return
    end
    btn.introWash:Show()
    if btn._trackIntro then
        return
    end
    btn._pulseT = btn._pulseT or 0
    btn._trackIntro = true
    local wash = btn.introWash
    btn:SetScript("OnUpdate", function(self, elapsed)
        self._pulseT = (self._pulseT or 0) + (elapsed or 0)
        local wave = 0.5 - 0.5 * math.cos(self._pulseT * 1.4)
        wash:SetAlpha(wave * 0.28)
    end)
end

function GQ.Log:DismissTrackIntro()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.trackSeen = true
    local btn = self.frame and self.frame.trackBtn
    if not btn then
        return
    end
    btn:SetScript("OnUpdate", nil)
    if btn.introWash then
        btn.introWash:Hide()
    end
end

function GQ.Log:SetPlayStyleFlag(key, enabled)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    if enabled then
        GearQuestForeverDB.ui[key] = true
    else
        GearQuestForeverDB.ui[key] = nil
    end
    self._playerRep = nil
    self._playerProf = nil
    self:RefreshPlayStylePanel()
    self:CommitSourceFilter()
end

function GQ.Log:SetNoDungeons(enabled)
    if enabled then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.playDungeonEnjoyer = nil
    end
    self:SetPlayStyleFlag("playNoDungeons", enabled)
end

function GQ.Log:SetDungeonEnjoyer(enabled)
    if enabled then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.playNoDungeons = nil
    end
    self:SetPlayStyleFlag("playDungeonEnjoyer", enabled)
end

function GQ.Log:SetGetItToday(enabled)
    self._repSnapshot = nil
    self._profSnapshot = nil
    self:SetPlayStyleFlag("playGetItToday", enabled)
    if enabled then
        self:NoteObtainabilityChanged()
    end
end

function GQ.Log:SetManageableDungeons(enabled)
    self:SetPlayStyleFlag("playManageableDungeons", enabled)
end

function GQ.Log:SetBuyIt(enabled)
    self:SetPlayStyleFlag("playBuyIt", enabled)
end

function GQ.Log:SetManageableQuests(enabled)
    self:SetPlayStyleFlag("playManageableQuests", enabled)
end

function GQ.Log:SetFocusZone(enabled)
    self._focusZoneSeen = self:PlayerZoneName()
    self._focusZoneMatch = nil
    self._focusZoneCacheName = nil
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    if enabled then
        GearQuestForeverDB.ui.playFocusZone = true
    else
        GearQuestForeverDB.ui.playFocusZone = nil
    end
    self:RefreshPlayStylePanel()
    self:InvalidateSourceFilterCache()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
    if enabled then
        self:ScheduleFocusZoneRefresh()
    end
    if not enabled or not (self.frame and self.frame:IsShown()) then
        self:ScheduleListRefresh()
    end
end

function GQ.Log:UpdatePlayStyleButton()
    local btn = self.frame and self.frame.playStyleBtn
    if not btn then
        return
    end
    if self:PlayStyleActive() then
        btn:SetText("Play style*")
    else
        btn:SetText("Play style")
    end
end

function GQ.Log:RefreshPlayStylePanel()
    local panel = self.frame and self.frame.playStylePanel
    local card = panel and panel.noDungeonsCard
    if card then
        self:SetSimulatorChoiceHighlight(card, self:NoDungeonsEnabled(), 0.35)
    end
    local enjoy = panel and panel.dungeonEnjoyerCard
    if enjoy then
        self:SetSimulatorChoiceHighlight(enjoy, self:DungeonEnjoyerEnabled(), 0.35)
    end
    local today = panel and panel.getItTodayCard
    if today then
        self:SetSimulatorChoiceHighlight(today, self:GetItTodayEnabled(), 0.35)
    end
    local dungeons = panel and panel.manageableDungeonsCard
    if dungeons then
        self:SetSimulatorChoiceHighlight(dungeons, self:ManageableDungeonsEnabled(), 0.35)
    end
    local manage = panel and panel.manageableCard
    if manage then
        self:SetSimulatorChoiceHighlight(manage, self:ManageableQuestsEnabled(), 0.35)
    end
    local buy = panel and panel.buyItCard
    if buy then
        self:SetSimulatorChoiceHighlight(buy, self:BuyItEnabled(), 0.35)
    end
    local focus = panel and panel.focusZoneCard
    if focus then
        self:SetSimulatorChoiceHighlight(focus, self:FocusZoneEnabled(), 0.35)
    end
    self:UpdatePlayStyleButton()
end

function GQ.Log:TogglePlayStylePanel()
    local panel = self.frame and self.frame.playStylePanel
    if not panel then
        return
    end
    if panel:IsShown() then
        panel:Hide()
        return
    end
    self:RefreshPlayStylePanel()
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(300)
    panel:Show()
end

function GQ.Log:LayoutFooterButtons(frame)
    if not frame.trackBtn or not frame.detailBg then
        return
    end

    local chromeLevel = (frame.detailBg:GetFrameLevel() or 1) + 5
    frame.trackBtn:SetParent(frame.detailBg)
    frame.trackBtn:SetFrameLevel(chromeLevel)
    frame.trackBtn:ClearAllPoints()
    frame.trackBtn:SetPoint("BOTTOMLEFT", frame.detailBg, "BOTTOMLEFT", 8, 8)

    if frame.untrackBtn then
        frame.untrackBtn:Hide()
    end

    if frame.mapBtn then
        frame.mapBtn:SetParent(frame.detailBg)
        frame.mapBtn:SetFrameLevel(chromeLevel)
        frame.mapBtn:ClearAllPoints()
        frame.mapBtn:SetPoint("LEFT", frame.trackBtn, "RIGHT", 4, 0)
    end

    self:EnsureOmitButtons(frame)
    if frame.removeBtn then
        frame.removeBtn:SetParent(frame.detailBg)
        frame.removeBtn:SetFrameLevel(chromeLevel)
        frame.removeBtn:ClearAllPoints()
        if frame.mapBtn then
            frame.removeBtn:SetPoint("LEFT", frame.mapBtn, "RIGHT", 4, 0)
        else
            frame.removeBtn:SetPoint("LEFT", frame.trackBtn, "RIGHT", 4, 0)
        end
    end
    if frame.restoreBtn then
        frame.restoreBtn:SetParent(frame.detailBg)
        frame.restoreBtn:SetFrameLevel(chromeLevel)
        frame.restoreBtn:ClearAllPoints()
        frame.restoreBtn:SetPoint("BOTTOMLEFT", frame.detailBg, "BOTTOMLEFT", 8, 8)
    end

    if frame.exitBtn then
        local windowLevel = (frame.gqOuterBorder and frame.gqOuterBorder.GetFrameLevel and frame.gqOuterBorder:GetFrameLevel() or (frame:GetFrameLevel() or 1)) + 2
        frame.exitBtn:SetFrameLevel(windowLevel)
        frame.exitBtn:ClearAllPoints()
        frame.exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, FOOTER_BUTTON_Y)
    end

    self:EnsurePlayStyle(frame)
    if frame.playStyleBtn then
        frame.playStyleBtn:ClearAllPoints()
        frame.playStyleBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_LEFT + LEFT_COLUMN_WIDTH + COLUMN_GAP, FOOTER_BUTTON_Y)
    end
    self:EnsureHuntsPerSlot(frame)
    if frame.huntsPerSlot then
        frame.huntsPerSlot:ClearAllPoints()
        frame.huntsPerSlot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_LEFT, FOOTER_BUTTON_Y)
        frame.huntsPerSlot:SetWidth(LEFT_COLUMN_WIDTH)
    end
end

function GQ.Log:ApplyPageTab()
    if not self.frame then
        return
    end

    local page = self:GetPageTab()
    if self.frame.logPage then
        if page == "log" then
            self.frame.logPage:Show()
        else
            self.frame.logPage:Hide()
        end
    end
    if self.frame.lookupPage then
        if page == "lookup" then
            self.frame.lookupPage:Show()
        else
            self.frame.lookupPage:Hide()
            if self.frame.lookupBox then
                self.frame.lookupBox:ClearFocus()
            end
        end
    end
    if self.frame.detailEmpty and page ~= "lookup" then
        self.frame.detailEmpty:SetText("Select an upgrade to see how to get it.")
    end
    self:PlaceDetailPanel(self.frame)
    if self.frame.detailScroll then
        if page == "log" or page == "lookup" then
            self.frame.detailScroll:Show()
        else
            self.frame.detailScroll:Hide()
        end
        local detailBar = self.frame.detailScroll.GetName and _G[self.frame.detailScroll:GetName() .. "ScrollBar"]
        if page == "log" or page == "lookup" then
            ApplyScrollBarVisibility(self.frame.detailScroll)
        elseif detailBar then
            detailBar:Hide()
        end
    end
    if self.frame.scroll then
        local listBar = self.frame.scroll.GetName and _G[self.frame.scroll:GetName() .. "ScrollBar"]
        if page == "log" then
            self.frame.scroll:Show()
            ApplyScrollBarVisibility(self.frame.scroll)
        else
            if listBar then
                listBar:Hide()
            end
        end
    end
    if self.frame.simPage then
        if page == "simulator" then
            self.frame.simPage:Show()
        else
            self.frame.simPage:Hide()
        end
    end
    if self.frame.settingsPage then
        if page == "settings" then
            self.frame.settingsPage:Show()
            self:RefreshSettings()
            self:LayoutSettingsGeneral(self.frame)
        else
            self.frame.settingsPage:Hide()
        end
    end

    if self.frame.playStyleBtn then
        if page == "log" then
            self.frame.playStyleBtn:Show()
        else
            self.frame.playStyleBtn:Hide()
            if self.frame.playStylePanel then
                self.frame.playStylePanel:Hide()
            end
        end
    end
    if self.frame.huntsPerSlot then
        if page == "log" then
            self.frame.huntsPerSlot:Show()
        else
            self.frame.huntsPerSlot:Hide()
        end
    end

    self:UpdatePageTabVisuals()
    self:UpdateFooterButtons()
    self:UpdateContextStatus()
    if page == "log" then
        self:UpdateSpecButton()
    elseif self.frame.tabSpecControl then
        self.frame.tabSpecControl:Hide()
    end
    if self.UpdateSimClassRowArt then
        self:UpdateSimClassRowArt()
    end
end

function GQ.Log:EnsureTabBar(frame)
    local pageBar = self:EnsurePageBar(frame)
    self:EnsureLogPages(frame)

    if not frame.tabBar then
        local tabBar = CreateFrame("Frame", nil, pageBar)
        tabBar:SetHeight(TAB_HEIGHT)
        tabBar:SetWidth(FILTER_TAB_WIDTH * 3 + 8)
        tabBar:SetPoint("TOPLEFT", pageBar, "TOPLEFT", FILTER_TAB_LEFT, 0)
        frame.tabBar = tabBar
        tabBar.tabGroup = tabBar

        local tabActive = CreateGoldTab(tabBar, "GearQuestLogTabActive", "Active", FILTER_TAB_WIDTH)
        tabActive:SetPoint("TOPLEFT", tabBar, "TOPLEFT", 0, 0)
        frame.tabActive = tabActive

        local tabCompleted = CreateGoldTab(tabBar, "GearQuestLogTabCompleted", "Completed", FILTER_TAB_WIDTH)
        tabCompleted:SetPoint("TOPLEFT", tabActive, "TOPRIGHT", 4, 0)
        frame.tabCompleted = tabCompleted

        local tabRemoved = CreateGoldTab(tabBar, "GearQuestLogTabRemoved", "Removed", FILTER_TAB_WIDTH)
        tabRemoved:SetPoint("TOPLEFT", tabCompleted, "TOPRIGHT", 4, 0)
        frame.tabRemoved = tabRemoved

        tabActive:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:HideSpecPicker()
                log:SetListTab("active")
            end
        end)

        tabCompleted:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:HideSpecPicker()
                log:SetListTab("completed")
            end
        end)

        tabRemoved:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:HideSpecPicker()
                log:SetListTab("removed")
            end
        end)
    else
        if frame.tabBar:GetParent() ~= pageBar then
            frame.tabBar:SetParent(pageBar)
        end
        frame.tabBar:ClearAllPoints()
        frame.tabBar:SetWidth(FILTER_TAB_WIDTH * 3 + 8)
        frame.tabBar:SetPoint("TOPLEFT", pageBar, "TOPLEFT", FILTER_TAB_LEFT, 0)
        if not frame.tabRemoved and frame.tabCompleted then
            local tabRemoved = CreateGoldTab(frame.tabBar, "GearQuestLogTabRemoved", "Removed", FILTER_TAB_WIDTH)
            tabRemoved:SetPoint("TOPLEFT", frame.tabCompleted, "TOPRIGHT", 4, 0)
            tabRemoved:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:HideSpecPicker()
                    log:SetListTab("removed")
                end
            end)
            frame.tabRemoved = tabRemoved
        end
        StyleGoldTab(frame.tabActive, self:GetListTab() == "active")
        StyleGoldTab(frame.tabCompleted, self:GetListTab() == "completed")
        if frame.tabRemoved then
            StyleGoldTab(frame.tabRemoved, self:GetListTab() == "removed")
        end
    end

    self:EnsureSourceFilter(frame)
    self:EnsureSimulatorPage(frame)
    self:EnsureSettingsPage(frame)
    self:LayoutMainWindow(frame)
    self:UpdateTabVisuals()
end

local function ApplyFilterButtonFont(fs)
    if not fs then
        return
    end
    local btn = GQ.Log.frame and GQ.Log.frame.sourceFilterBtn
    local buttonText = btn and btn.GetFontString and btn:GetFontString()
    local font, size, flags
    if buttonText then
        font, size, flags = buttonText:GetFont()
    end
    if (not font or not size) and _G.GameFontHighlight then
        font, size, flags = _G.GameFontHighlight:GetFont()
    end
    if font and size then
        fs:SetFont(font, size, flags)
    end
end

local function MouseOverFilterRow(check)
    if not check or not check.IsShown or not check:IsShown() or not check.IsMouseOver then
        return false
    end
    local right = 12
    if check.label and check.label.GetStringWidth then
        right = (check.label:GetStringWidth() or 0) + 20
        if check.sourceIcon then
            right = right + (check.sourceIcon:GetWidth() or 18) + 4
        end
    end
    local ok, over = pcall(function()
        return check:IsMouseOver(3, 3, 4, right)
    end)
    if ok then
        return over and true or false
    end
    return check:IsMouseOver() and true or false
end

function GQ.Log:UpdateSourceFilterButton()
    local btn = self.frame and self.frame.sourceFilterBtn
    if not btn then
        return
    end
    if self:SourceFilterActive() then
        btn:SetText("Filter*")
    else
        btn:SetText("Filter")
    end
end

function GQ.Log:EnsureSourceFilter(frame)
    local pageBar = frame.pageBar or frame.tabBar and frame.tabBar:GetParent()
    if not pageBar then
        return
    end

    if not frame.sourceFilterBtn then
        local btn = CreateFrame("Button", "GearQuestSourceFilterButton", frame.logPage or pageBar, "UIPanelButtonTemplate")
        btn:SetSize(72, 22)
        btn:SetText("Filter")
        btn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSourceFilterMenu()
            end
        end)
        frame.sourceFilterBtn = btn
    else
        self:RepositionSpecButton(frame)
    end

    if frame.sourceFilterMenu then
        self:UpdateSourceFilterButton()
        return
    end

    local menu = CreateFrame("Frame", "GearQuestSourceFilterMenu", frame, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(50)
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:SetSize(200, 12 + (#SOURCE_FILTERS * 20) + 66)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if menu.SetBackdropColor then
        menu:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if menu.SetBackdropBorderColor then
        menu:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    menu:SetPoint("TOPRIGHT", frame.sourceFilterBtn, "BOTTOMRIGHT", 0, -2)
    menu:Hide()
    menu:SetScript("OnEnter", HideItemTooltip)
    local catcher = CreateFrame("Frame", "GearQuestSourceFilterCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function()
        menu:Hide()
    end)
    menu.catcher = catcher

    menu:SetScript("OnShow", function(self)
        HideItemTooltip()
        self:SetFrameStrata("TOOLTIP")
        self:SetFrameLevel(50)
        if self.catcher then
            self.catcher:Show()
        end
    end)
    menu:SetScript("OnHide", function(self)
        if self.profBranch then
            self.profBranch:Hide()
        end
        if self.dungeonBranch then
            self.dungeonBranch:Hide()
        end
        if self.trashBranch then
            self.trashBranch:Hide()
        end
        if self.vendorBranch then
            self.vendorBranch:Hide()
        end
        if self.catcher then
            self.catcher:Hide()
        end
    end)
    frame.sourceFilterMenu = menu

    local branch = CreateFrame("Frame", "GearQuestProfessionFilterBranch", menu, "BackdropTemplate")
    branch:SetFrameStrata("TOOLTIP")
    branch:SetFrameLevel(60)
    branch:EnableMouse(true)
    branch:SetSize(168, 28)
    branch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if branch.SetBackdropColor then
        branch:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if branch.SetBackdropBorderColor then
        branch:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    if branch.SetClampedToScreen then
        branch:SetClampedToScreen(true)
    end
    branch:Hide()
    branch.rows = {}
    branch.empty = branch:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ApplyFilterButtonFont(branch.empty)
    branch.empty:SetPoint("LEFT", branch, "LEFT", 12, 0)
    branch.empty:SetText("No profession hunts")
    branch:SetScript("OnEnter", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._profBranchHot = true
            log._profHideGen = (log._profHideGen or 0) + 1
        end
        HideItemTooltip()
    end)
    branch:SetScript("OnLeave", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._profBranchHot = false
            log:ScheduleHideProfessionBranch()
        end
    end)
    menu.profBranch = branch
    self:CreateDungeonFilterBranch(menu)
    self:CreateTrashFilterBranch(menu)
    self:CreateVendorFilterBranch(menu)

    local function draftSources()
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return nil
        end
        return log._filterDraft or log:CopyFilterDraft()
    end

    local selectBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    selectBtn:SetHeight(22)
    selectBtn:SetText("Deselect all")
    selectBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -8)
    selectBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -10, -8)
    selectBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end
        local draft = log._filterDraft or log:CopyFilterDraft()
        local allOn = log:FilterDraftAllOn(draft)
        log:SetFilterDraftAll(draft, allOn)
        if allOn then
            if menu.profBranch then
                menu.profBranch:Hide()
            end
            if menu.dungeonBranch then
                menu.dungeonBranch:Hide()
            end
            if menu.trashBranch then
                menu.trashBranch:Hide()
            end
            if menu.vendorBranch then
                menu.vendorBranch:Hide()
            end
        end
        if menu.sync then
            menu.sync()
        end
        if not allOn then
            if menu.profBranch and menu.profBranch:IsShown() then
                log:PopulateProfessionBranch(menu)
            end
            if menu.dungeonBranch and menu.dungeonBranch:IsShown() then
                log:PopulateDungeonBranch(menu)
            end
            if menu.trashBranch and menu.trashBranch:IsShown() then
                log:PopulateTrashBranch(menu)
            end
            if menu.vendorBranch and menu.vendorBranch:IsShown() then
                log:PopulateVendorBranch(menu)
            end
        end
    end)
    menu.selectBtn = selectBtn

    local previous
    local menuWidth = 200
    for _, opt in ipairs(SOURCE_FILTERS) do
        local check = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        if previous then
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 2)
        else
            check:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -36)
        end
        check.sourceId = opt.id
        local icon = check:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", check, "RIGHT", 1, 0)
        check.sourceIcon = icon
        if GQ.Pins and GQ.Pins.ApplyIcon then
            GQ.Pins:ApplyIcon(icon, opt.id)
        end
        local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        ApplyFilterButtonFont(label)
        label:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        label:SetText(opt.label)
        check.label = label
        local iconPad = (icon:GetWidth() or 18) + 4
        local rowWidth = 40 + iconPad + (label:GetStringWidth() or 90)
        if rowWidth > menuWidth then
            menuWidth = rowWidth
        end
        check:SetHitRectInsets(0, -((label:GetStringWidth() or 90) + iconPad + 8), -2, -2)
        check:SetScript("OnEnter", function(self)
            HideItemTooltip()
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log then
                return
            end
            if self.sourceId == "profession" then
                log:ShowProfessionBranch(self)
                log._vendorRowHot = false
                log._vendorBranchHot = false
                log._vendorLeaveAt = nil
                if menu.dungeonBranch then
                    menu.dungeonBranch:Hide()
                end
                if menu.trashBranch then
                    menu.trashBranch:Hide()
                end
                if menu.vendorBranch then
                    menu.vendorBranch:Hide()
                end
            elseif self.sourceId == "boss_drop" then
                log:ShowDungeonBranch(self)
                log._profRowHot = false
                log._profBranchHot = false
                log._profLeaveAt = nil
                log._trashRowHot = false
                log._trashBranchHot = false
                log._trashLeaveAt = nil
                log._vendorRowHot = false
                log._vendorBranchHot = false
                log._vendorLeaveAt = nil
                if menu.profBranch then
                    menu.profBranch:Hide()
                end
                if menu.trashBranch then
                    menu.trashBranch:Hide()
                end
                if menu.vendorBranch then
                    menu.vendorBranch:Hide()
                end
            elseif self.sourceId == "raid_trash" then
                log:ShowTrashBranch(self)
                log._profRowHot = false
                log._profBranchHot = false
                log._profLeaveAt = nil
                log._dungeonRowHot = false
                log._dungeonBranchHot = false
                log._dungeonLeaveAt = nil
                log._vendorRowHot = false
                log._vendorBranchHot = false
                log._vendorLeaveAt = nil
                if menu.profBranch then
                    menu.profBranch:Hide()
                end
                if menu.dungeonBranch then
                    menu.dungeonBranch:Hide()
                end
                if menu.vendorBranch then
                    menu.vendorBranch:Hide()
                end
            elseif self.sourceId == "vendor" then
                log:ShowVendorBranch(self)
                log._profRowHot = false
                log._profBranchHot = false
                log._profLeaveAt = nil
                log._dungeonRowHot = false
                log._dungeonBranchHot = false
                log._dungeonLeaveAt = nil
                log._trashRowHot = false
                log._trashBranchHot = false
                log._trashLeaveAt = nil
                if menu.profBranch then
                    menu.profBranch:Hide()
                end
                if menu.dungeonBranch then
                    menu.dungeonBranch:Hide()
                end
                if menu.trashBranch then
                    menu.trashBranch:Hide()
                end
            else
                log._profRowHot = false
                log._profBranchHot = false
                log._profLeaveAt = nil
                log._dungeonRowHot = false
                log._dungeonBranchHot = false
                log._dungeonLeaveAt = nil
                log._trashRowHot = false
                log._trashBranchHot = false
                log._trashLeaveAt = nil
                log._vendorRowHot = false
                log._vendorBranchHot = false
                log._vendorLeaveAt = nil
                if menu.profBranch then
                    menu.profBranch:Hide()
                end
                if menu.dungeonBranch then
                    menu.dungeonBranch:Hide()
                end
                if menu.trashBranch then
                    menu.trashBranch:Hide()
                end
                if menu.vendorBranch then
                    menu.vendorBranch:Hide()
                end
            end
        end)
        check:SetScript("OnLeave", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and self.sourceId == "profession" then
                log._profRowHot = false
                log:ScheduleHideProfessionBranch()
            elseif log and self.sourceId == "boss_drop" then
                log._dungeonRowHot = false
                log:ScheduleHideDungeonBranch()
            elseif log and self.sourceId == "raid_trash" then
                log._trashRowHot = false
                log:ScheduleHideTrashBranch()
            elseif log and self.sourceId == "vendor" then
                log._vendorRowHot = false
                log:ScheduleHideVendorBranch()
            end
        end)
        check:SetScript("OnClick", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            local draft = draftSources()
            if not log or not draft then
                return
            end
            if self:GetChecked() then
                draft.sources[self.sourceId] = nil
            else
                draft.sources[self.sourceId] = true
            end
            if self.sourceId == "profession" then
                log:SyncProfessionRowLabel(self)
                log:ShowProfessionBranch(self)
            elseif self.sourceId == "boss_drop" then
                log:SyncBossDropRowLabel(self)
                log:ShowDungeonBranch(self)
            elseif self.sourceId == "raid_trash" then
                log:SyncTrashRowLabel(self)
                log:ShowTrashBranch(self)
            elseif self.sourceId == "vendor" then
                log:SyncVendorRowLabel(self)
                log:ShowVendorBranch(self)
            end
            log:SyncSourceSelectButton(menu)
        end)
        if opt.id == "profession" then
            menu.profRow = check
        elseif opt.id == "boss_drop" then
            menu.bossRow = check
        elseif opt.id == "raid_trash" then
            menu.trashRow = check
        elseif opt.id == "vendor" then
            menu.vendorRow = check
        end
        previous = check
    end
    menu:SetWidth(menuWidth + 32)

    local applyBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    applyBtn:SetHeight(22)
    applyBtn:SetText("Apply filter")
    applyBtn:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 10, 10)
    applyBtn:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -10, 10)
    applyBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ApplyFilterDraft()
        end
    end)
    menu.applyBtn = applyBtn

    menu:SetScript("OnUpdate", function(self)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end
        local function watch(flyout, row, leaveKey, rowHotKey, branchHotKey)
            if not flyout or not flyout:IsShown() then
                return
            end
            local overBranch = flyout.IsMouseOver and flyout:IsMouseOver(10, 10, 10, 10)
            if MouseOverFilterRow(row) or overBranch then
                log[leaveKey] = nil
                log[rowHotKey] = true
                return
            end
            if not log[leaveKey] then
                log[leaveKey] = GetTime()
                return
            end
            if GetTime() - log[leaveKey] > 0.2 then
                log[rowHotKey] = false
                log[branchHotKey] = false
                log[leaveKey] = nil
                flyout:Hide()
            end
        end
        watch(self.profBranch, self.profRow, "_profLeaveAt", "_profRowHot", "_profBranchHot")
        watch(self.dungeonBranch, self.bossRow, "_dungeonLeaveAt", "_dungeonRowHot", "_dungeonBranchHot")
        watch(self.trashBranch, self.trashRow, "_trashLeaveAt", "_trashRowHot", "_trashBranchHot")
        watch(self.vendorBranch, self.vendorRow, "_vendorLeaveAt", "_vendorRowHot", "_vendorBranchHot")
    end)

    menu.sync = function()
        local log = GQ.Log
        local draft = log._filterDraft or log:CopyFilterDraft()
        local kids = { menu:GetChildren() }
        for _, childBtn in ipairs(kids) do
            if childBtn.sourceId then
                childBtn:SetChecked(not draft.sources[childBtn.sourceId])
                if childBtn.sourceId == "profession" then
                    GQ.Log:SyncProfessionRowLabel(childBtn)
                elseif childBtn.sourceId == "boss_drop" then
                    GQ.Log:SyncBossDropRowLabel(childBtn)
                elseif childBtn.sourceId == "raid_trash" then
                    GQ.Log:SyncTrashRowLabel(childBtn)
                elseif childBtn.sourceId == "vendor" then
                    GQ.Log:SyncVendorRowLabel(childBtn)
                end
            end
        end
        GQ.Log:SyncSourceSelectButton(menu)
    end
    self:UpdateSourceFilterButton()
end

function GQ.Log:FilterDraftAllOn(draft)
    draft = draft or self._filterDraft or self:CopyFilterDraft()
    local sources = draft.sources or {}
    for _, opt in ipairs(SOURCE_FILTERS) do
        if sources[opt.id] then
            return false
        end
    end
    local profs = draft.professions or {}
    for i = 1, #PROFESSION_FILTERS do
        if profs[PROFESSION_FILTERS[i]] then
            return false
        end
    end
    local dungeons = draft.dungeons or {}
    local catalog = self.DUNGEON_FILTERS or {}
    for i = 1, #catalog do
        if dungeons[catalog[i]] then
            return false
        end
    end
    local trash = draft.trashDungeons or {}
    for i = 1, #catalog do
        if trash[catalog[i]] then
            return false
        end
    end
    local vendors = draft.vendors or {}
    local vendorKinds = self.VENDOR_KINDS or {}
    for i = 1, #vendorKinds do
        if vendors[vendorKinds[i].id] then
            return false
        end
    end
    return true
end

function GQ.Log:SetFilterDraftAll(draft, hidden)
    draft.sources = draft.sources or {}
    for _, opt in ipairs(SOURCE_FILTERS) do
        if hidden then
            draft.sources[opt.id] = true
        else
            draft.sources[opt.id] = nil
        end
    end
    draft.professions = draft.professions or {}
    for i = 1, #PROFESSION_FILTERS do
        local name = PROFESSION_FILTERS[i]
        if hidden then
            draft.professions[name] = true
        else
            draft.professions[name] = nil
        end
    end
    draft.dungeons = draft.dungeons or {}
    local catalog = self.DUNGEON_FILTERS or {}
    for i = 1, #catalog do
        local name = catalog[i]
        if hidden then
            draft.dungeons[name] = true
        else
            draft.dungeons[name] = nil
        end
    end
    draft.trashDungeons = draft.trashDungeons or {}
    for i = 1, #catalog do
        local trashName = catalog[i]
        if hidden then
            draft.trashDungeons[trashName] = true
        else
            draft.trashDungeons[trashName] = nil
        end
    end
    draft.vendors = draft.vendors or {}
    local vendorKinds = self.VENDOR_KINDS or {}
    for i = 1, #vendorKinds do
        local kind = vendorKinds[i].id
        if hidden then
            draft.vendors[kind] = true
        else
            draft.vendors[kind] = nil
        end
    end
end

function GQ.Log:SyncSourceSelectButton(menu)
    local btn = menu and menu.selectBtn
    if not btn then
        return
    end
    local allOn = self:FilterDraftAllOn()
    btn:SetText(allOn and "Deselect all" or "Select all")
end

function GQ.Log:FilterBranchAnchor(check)
    if check and check.branchArrow and check.branchArrow:IsShown() then
        return check.branchArrow
    end
    if check and check.label then
        return check.label
    end
    return check
end

function GQ.Log:SyncFilterBranchMark(check, name)
    if not check or not check.label or not name then
        return
    end
    check.label:SetText(name)
    if not check.branchArrow then
        local arrow = check:CreateTexture(nil, "OVERLAY")
        arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        arrow:SetSize(12, 15)
        arrow:SetBlendMode("ADD")
        -- The gold chevron sits in the middle of that button. Crop to it and
        -- turn the downward tip to the right. Black around the chevron adds nothing.
        local left, right = 8 / 32, 23 / 32
        local top, bottom = 10 / 32, 22 / 32
        arrow:SetTexCoord(right, top, left, top, right, bottom, left, bottom)
        arrow:SetPoint("LEFT", check.label, "RIGHT", 2, 0)
        check.branchArrow = arrow
    end
    if check:GetChecked() then
        check.branchArrow:Show()
    else
        check.branchArrow:Hide()
    end
    local iconPad = check.sourceIcon and ((check.sourceIcon:GetWidth() or 18) + 4) or 0
    local arrowPad = check.branchArrow:IsShown() and 16 or 0
    local textW = check.label:GetStringWidth() or 90
    check:SetHitRectInsets(0, -(textW + iconPad + arrowPad + 8), -2, -2)
    local menu = self.frame and self.frame.sourceFilterMenu
    if menu then
        local needed = 40 + iconPad + textW + arrowPad
        if needed > (menu:GetWidth() or 0) then
            menu:SetWidth(needed)
        end
    end
end

function GQ.Log:SyncProfessionRowLabel(check)
    self:SyncFilterBranchMark(check, "Profession")
end

function GQ.Log:EnsureBranchSelectButton(branch)
    if not branch then
        return nil
    end
    if branch.selectBtn then
        return branch.selectBtn
    end
    local btn = CreateFrame("Button", nil, branch, "UIPanelButtonTemplate")
    btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", branch, "TOPLEFT", 8, -6)
    btn:SetPoint("TOPRIGHT", branch, "TOPRIGHT", -8, -6)
    btn:SetScript("OnEnter", function()
        HideItemTooltip()
    end)
    btn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ToggleBranchSelectAll(branch)
        end
    end)
    branch.selectBtn = btn
    return btn
end

function GQ.Log:AnchorBranchCheck(branch, row, index)
    row:ClearAllPoints()
    if index == 1 and branch.selectBtn then
        row:SetPoint("TOPLEFT", branch.selectBtn, "BOTTOMLEFT", 0, -2)
    elseif index == 1 then
        row:SetPoint("TOPLEFT", branch, "TOPLEFT", 8, -6)
    else
        row:SetPoint("TOPLEFT", branch.rows[index - 1], "BOTTOMLEFT", 0, 2)
    end
end

function GQ.Log:SyncBranchSelectLabel(branch, hidden, keys)
    local btn = self:EnsureBranchSelectButton(branch)
    if not btn then
        return
    end
    if not keys or #keys == 0 then
        btn:Hide()
        return
    end
    btn:Show()
    hidden = hidden or {}
    local allOn = true
    for i = 1, #keys do
        if hidden[keys[i]] then
            allOn = false
            break
        end
    end
    btn:SetText(allOn and "Deselect all" or "Select all")
end

function GQ.Log:ToggleBranchSelectAll(branch)
    local keys = branch and branch._selectKeys
    local bucketName = branch and branch._selectBucket
    local refill = branch and branch._selectRefill
    if not keys or not bucketName or not refill then
        return
    end
    local draft = self._filterDraft or self:CopyFilterDraft()
    draft[bucketName] = draft[bucketName] or {}
    local bucket = draft[bucketName]
    local allOn = true
    for i = 1, #keys do
        if bucket[keys[i]] then
            allOn = false
            break
        end
    end
    for i = 1, #keys do
        if allOn then
            bucket[keys[i]] = true
        else
            bucket[keys[i]] = nil
        end
    end
    local menu = self.frame and self.frame.sourceFilterMenu
    refill(self, menu)
    self:SyncSourceSelectButton(menu)
end

function GQ.Log:RememberBranchSelection(branch, bucketName, refill, keys, hidden)
    branch._selectBucket = bucketName
    branch._selectRefill = refill
    branch._selectKeys = keys
    self:SyncBranchSelectLabel(branch, hidden, keys)
end

function GQ.Log:PopulateProfessionBranch(menu)
    local branch = menu and menu.profBranch
    if not branch then
        return
    end
    self:EnsureBranchSelectButton(branch)
    local names = self:GetBisProfessionNames()
    local draft = self._filterDraft or self:CopyFilterDraft()
    local hidden = draft.professions
    local width = 168
    for i, name in ipairs(names) do
        local row = branch.rows[i]
        if not row then
            row = CreateFrame("CheckButton", nil, branch, "UICheckButtonTemplate")
            row:SetSize(22, 22)
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ApplyFilterButtonFont(label)
            label:SetPoint("LEFT", row, "RIGHT", 2, 0)
            row.label = label
            row:SetScript("OnEnter", function()
                HideItemTooltip()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log._profBranchHot = true
                    log._profHideGen = (log._profHideGen or 0) + 1
                end
            end)
            row:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log or not self.professionName then
                    return
                end
                local pending = log._filterDraft or log:CopyFilterDraft()
                if self:GetChecked() then
                    pending.professions[self.professionName] = nil
                else
                    pending.professions[self.professionName] = true
                end
                local menu = log.frame and log.frame.sourceFilterMenu
                log:SyncSourceSelectButton(menu)
                log:SyncBranchSelectLabel(branch, pending.professions, branch._selectKeys)
            end)
            branch.rows[i] = row
        end
        self:AnchorBranchCheck(branch, row, i)
        row.professionName = name
        row.label:SetText(name)
        row:SetChecked(not hidden[name])
        row:SetHitRectInsets(0, -((row.label:GetStringWidth() or 90) + 8), -2, -2)
        row:Show()
        local rowWidth = (row.label:GetStringWidth() or 80) + 46
        if rowWidth > width then
            width = rowWidth
        end
    end
    for i = #names + 1, #branch.rows do
        branch.rows[i]:Hide()
    end
    if #names == 0 then
        branch.empty:Show()
        branch._selectKeys = nil
        if branch.selectBtn then
            branch.selectBtn:Hide()
        end
        branch:SetSize(168, 32)
    else
        branch.empty:Hide()
        local keys = {}
        for i = 1, #names do
            keys[i] = names[i]
        end
        self:RememberBranchSelection(branch, "professions", self.PopulateProfessionBranch, keys, hidden)
        branch:SetSize(width, 40 + (#names * 20))
    end
end

function GQ.Log:ShowProfessionBranch(check)
    local menu = self.frame and self.frame.sourceFilterMenu
    local branch = menu and menu.profBranch
    if not branch or not check then
        return
    end
    self._profHideGen = (self._profHideGen or 0) + 1
    if not check:GetChecked() then
        self._profRowHot = false
        branch:Hide()
        return
    end
    self._profRowHot = true
    branch:ClearAllPoints()
    branch:SetPoint("TOPLEFT", self:FilterBranchAnchor(check), "TOPRIGHT", 2, 6)
    self:PopulateProfessionBranch(menu)
    branch:Show()
end

function GQ.Log:ScheduleHideProfessionBranch()
    local gen = (self._profHideGen or 0) + 1
    self._profHideGen = gen
    local function hide()
        if self._profHideGen ~= gen then
            return
        end
        if self._profRowHot or self._profBranchHot then
            return
        end
        local menu = self.frame and self.frame.sourceFilterMenu
        local branch = menu and menu.profBranch
        if branch then
            branch:Hide()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, hide)
    else
        hide()
    end
end

function GQ.Log:RefreshProfessionBranch()
    local menu = self.frame and self.frame.sourceFilterMenu
    local branch = menu and menu.profBranch
    if not branch or not branch:IsShown() then
        return
    end
    local row = menu.profRow
    if not row or not row:GetChecked() then
        branch:Hide()
        return
    end
    self:PopulateProfessionBranch(menu)
end

function GQ.Log:SyncVendorRowLabel(check)
    self:SyncFilterBranchMark(check, "Vendor")
end

function GQ.Log:CreateVendorFilterBranch(menu)
    if not menu or menu.vendorBranch then
        return
    end
    local branch = CreateFrame("Frame", "GearQuestVendorFilterBranch", menu, "BackdropTemplate")
    branch:SetFrameStrata("TOOLTIP")
    branch:SetFrameLevel(60)
    branch:EnableMouse(true)
    branch:SetSize(168, 28)
    branch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if branch.SetBackdropColor then
        branch:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if branch.SetBackdropBorderColor then
        branch:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    if branch.SetClampedToScreen then
        branch:SetClampedToScreen(true)
    end
    branch:Hide()
    branch.rows = {}
    branch:SetScript("OnEnter", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._vendorBranchHot = true
            log._vendorHideGen = (log._vendorHideGen or 0) + 1
        end
        HideItemTooltip()
    end)
    branch:SetScript("OnLeave", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._vendorBranchHot = false
            log:ScheduleHideVendorBranch()
        end
    end)
    menu.vendorBranch = branch
end

function GQ.Log:PopulateVendorBranch(menu)
    local branch = menu and menu.vendorBranch
    if not branch then
        return
    end
    self:EnsureBranchSelectButton(branch)
    local kinds = self.VENDOR_KINDS or {}
    local draft = self._filterDraft or self:CopyFilterDraft()
    draft.vendors = draft.vendors or {}
    local hidden = draft.vendors
    local width = 168
    for i = 1, #kinds do
        local kind = kinds[i]
        local row = branch.rows[i]
        if not row then
            row = CreateFrame("CheckButton", nil, branch, "UICheckButtonTemplate")
            row:SetSize(22, 22)
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ApplyFilterButtonFont(label)
            label:SetPoint("LEFT", row, "RIGHT", 2, 0)
            row.label = label
            row:SetScript("OnEnter", function()
                HideItemTooltip()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log._vendorBranchHot = true
                    log._vendorHideGen = (log._vendorHideGen or 0) + 1
                end
            end)
            row:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log or not self.vendorKind then
                    return
                end
                local pending = log._filterDraft or log:CopyFilterDraft()
                pending.vendors = pending.vendors or {}
                if self:GetChecked() then
                    pending.vendors[self.vendorKind] = nil
                else
                    pending.vendors[self.vendorKind] = true
                end
                local filterMenu = log.frame and log.frame.sourceFilterMenu
                log:SyncSourceSelectButton(filterMenu)
                log:SyncBranchSelectLabel(branch, pending.vendors, branch._selectKeys)
            end)
            branch.rows[i] = row
        end
        self:AnchorBranchCheck(branch, row, i)
        row.vendorKind = kind.id
        row.label:SetText(kind.label)
        row:SetChecked(not hidden[kind.id])
        row:SetHitRectInsets(0, -((row.label:GetStringWidth() or 90) + 8), -2, -2)
        row:Show()
        local rowWidth = (row.label:GetStringWidth() or 80) + 46
        if rowWidth > width then
            width = rowWidth
        end
    end
    for i = #kinds + 1, #branch.rows do
        branch.rows[i]:Hide()
    end
    local keys = {}
    for i = 1, #kinds do
        keys[i] = kinds[i].id
    end
    self:RememberBranchSelection(branch, "vendors", self.PopulateVendorBranch, keys, hidden)
    branch:SetSize(width, 40 + (#kinds * 20))
end

function GQ.Log:ShowVendorBranch(check)
    local menu = self.frame and self.frame.sourceFilterMenu
    local branch = menu and menu.vendorBranch
    if not branch or not check then
        return
    end
    self._vendorHideGen = (self._vendorHideGen or 0) + 1
    if not check:GetChecked() then
        self._vendorRowHot = false
        branch:Hide()
        return
    end
    self._vendorRowHot = true
    branch:ClearAllPoints()
    branch:SetPoint("TOPLEFT", self:FilterBranchAnchor(check), "TOPRIGHT", 2, 6)
    self:PopulateVendorBranch(menu)
    branch:Show()
end

function GQ.Log:ScheduleHideVendorBranch()
    local gen = (self._vendorHideGen or 0) + 1
    self._vendorHideGen = gen
    local function hide()
        if self._vendorHideGen ~= gen then
            return
        end
        if self._vendorRowHot or self._vendorBranchHot then
            return
        end
        local menu = self.frame and self.frame.sourceFilterMenu
        local branch = menu and menu.vendorBranch
        if branch then
            branch:Hide()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, hide)
    else
        hide()
    end
end

function GQ.Log:SyncBossDropRowLabel(check)
    self:SyncFilterBranchMark(check, "Boss drop")
end

function GQ.Log:CreateDungeonFilterBranch(menu)
    if not menu or menu.dungeonBranch then
        return
    end
    local branch = CreateFrame("Frame", "GearQuestDungeonFilterBranch", menu, "BackdropTemplate")
    branch:SetFrameStrata("TOOLTIP")
    branch:SetFrameLevel(60)
    branch:EnableMouse(true)
    branch:SetSize(236, 28)
    branch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if branch.SetBackdropColor then
        branch:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if branch.SetBackdropBorderColor then
        branch:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    if branch.SetClampedToScreen then
        branch:SetClampedToScreen(true)
    end
    branch:Hide()
    branch.rows = {}
    branch.empty = branch:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ApplyFilterButtonFont(branch.empty)
    branch.empty:SetPoint("LEFT", branch, "LEFT", 12, 0)
    branch.empty:SetText("No boss hunts at this level")
    branch.empty:Hide()
    branch:SetScript("OnEnter", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._dungeonBranchHot = true
            log._dungeonHideGen = (log._dungeonHideGen or 0) + 1
        end
        HideItemTooltip()
    end)
    branch:SetScript("OnLeave", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._dungeonBranchHot = false
            log:ScheduleHideDungeonBranch()
        end
    end)
    menu.dungeonBranch = branch
end

function GQ.Log:PopulateDungeonBranch(menu)
    local branch = menu and menu.dungeonBranch
    if not branch then
        return
    end
    self:EnsureBranchSelectButton(branch)
    local names = self:ReachableBossDungeons()
    local draft = self._filterDraft or self:CopyFilterDraft()
    local hidden = draft.dungeons or {}
    local width = 200
    for i, name in ipairs(names) do
        local row = branch.rows[i]
        if not row then
            row = CreateFrame("CheckButton", nil, branch, "UICheckButtonTemplate")
            row:SetSize(22, 22)
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ApplyFilterButtonFont(label)
            label:SetPoint("LEFT", row, "RIGHT", 2, 0)
            row.label = label
            row:SetScript("OnEnter", function()
                HideItemTooltip()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log._dungeonBranchHot = true
                    log._dungeonHideGen = (log._dungeonHideGen or 0) + 1
                end
            end)
            row:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log or not self.dungeonName then
                    return
                end
                local pending = log._filterDraft or log:CopyFilterDraft()
                pending.dungeons = pending.dungeons or {}
                if self:GetChecked() then
                    pending.dungeons[self.dungeonName] = nil
                else
                    pending.dungeons[self.dungeonName] = true
                end
                log:SyncSourceSelectButton(menu)
                log:SyncBranchSelectLabel(branch, pending.dungeons, branch._selectKeys)
            end)
            branch.rows[i] = row
        end
        self:AnchorBranchCheck(branch, row, i)
        row.dungeonName = name
        row.label:SetText(name)
        row:SetChecked(not hidden[name])
        row:SetHitRectInsets(0, -((row.label:GetStringWidth() or 90) + 8), -2, -2)
        row:Show()
        local rowWidth = (row.label:GetStringWidth() or 80) + 46
        if rowWidth > width then
            width = rowWidth
        end
    end
    for i = #names + 1, #branch.rows do
        branch.rows[i]:Hide()
    end
    if #names == 0 then
        if branch.empty then
            branch.empty:Show()
        end
        branch._selectKeys = nil
        if branch.selectBtn then
            branch.selectBtn:Hide()
        end
        branch:SetSize(236, 32)
        return
    end
    if branch.empty then
        branch.empty:Hide()
    end
    if width < 200 then
        width = 200
    end
    width = width + 36
    local keys = {}
    for i = 1, #names do
        keys[i] = names[i]
    end
    self:RememberBranchSelection(branch, "dungeons", self.PopulateDungeonBranch, keys, hidden)
    branch:SetSize(width, 40 + (#names * 20))
end

function GQ.Log:ShowDungeonBranch(check)
    local menu = self.frame and self.frame.sourceFilterMenu
    local branch = menu and menu.dungeonBranch
    if not branch or not check then
        return
    end
    self._dungeonHideGen = (self._dungeonHideGen or 0) + 1
    if not check:GetChecked() then
        self._dungeonRowHot = false
        branch:Hide()
        return
    end
    self._dungeonRowHot = true
    branch:ClearAllPoints()
    branch:SetPoint("TOPLEFT", self:FilterBranchAnchor(check), "TOPRIGHT", 2, 6)
    self:PopulateDungeonBranch(menu)
    branch:Show()
end

function GQ.Log:ScheduleHideDungeonBranch()
    local gen = (self._dungeonHideGen or 0) + 1
    self._dungeonHideGen = gen
    local function hide()
        if self._dungeonHideGen ~= gen then
            return
        end
        if self._dungeonRowHot or self._dungeonBranchHot then
            return
        end
        local menu = self.frame and self.frame.sourceFilterMenu
        local branch = menu and menu.dungeonBranch
        if branch then
            branch:Hide()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, hide)
    else
        hide()
    end
end

function GQ.Log:SyncTrashRowLabel(check)
    self:SyncFilterBranchMark(check, "Dungeon & Raid trash")
end

function GQ.Log:CreateTrashFilterBranch(menu)
    if not menu or menu.trashBranch then
        return
    end
    local branch = CreateFrame("Frame", "GearQuestTrashFilterBranch", menu, "BackdropTemplate")
    branch:SetFrameStrata("TOOLTIP")
    branch:SetFrameLevel(60)
    branch:EnableMouse(true)
    branch:SetSize(236, 28)
    branch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if branch.SetBackdropColor then
        branch:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if branch.SetBackdropBorderColor then
        branch:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    if branch.SetClampedToScreen then
        branch:SetClampedToScreen(true)
    end
    branch:Hide()
    branch.rows = {}
    branch.empty = branch:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ApplyFilterButtonFont(branch.empty)
    branch.empty:SetPoint("LEFT", branch, "LEFT", 12, 0)
    branch.empty:SetText("No trash hunts at this level")
    branch.empty:Hide()
    branch:SetScript("OnEnter", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._trashBranchHot = true
            log._trashHideGen = (log._trashHideGen or 0) + 1
        end
        HideItemTooltip()
    end)
    branch:SetScript("OnLeave", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log._trashBranchHot = false
            log:ScheduleHideTrashBranch()
        end
    end)
    menu.trashBranch = branch
end

function GQ.Log:PopulateTrashBranch(menu)
    local branch = menu and menu.trashBranch
    if not branch then
        return
    end
    self:EnsureBranchSelectButton(branch)
    local names = self:ReachableTrashDungeons()
    local draft = self._filterDraft or self:CopyFilterDraft()
    local hidden = draft.trashDungeons or {}
    local width = 200
    for i, name in ipairs(names) do
        local row = branch.rows[i]
        if not row then
            row = CreateFrame("CheckButton", nil, branch, "UICheckButtonTemplate")
            row:SetSize(22, 22)
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ApplyFilterButtonFont(label)
            label:SetPoint("LEFT", row, "RIGHT", 2, 0)
            row.label = label
            row:SetScript("OnEnter", function()
                HideItemTooltip()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log._trashBranchHot = true
                    log._trashHideGen = (log._trashHideGen or 0) + 1
                end
            end)
            row:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log or not self.dungeonName then
                    return
                end
                local pending = log._filterDraft or log:CopyFilterDraft()
                pending.trashDungeons = pending.trashDungeons or {}
                if self:GetChecked() then
                    pending.trashDungeons[self.dungeonName] = nil
                else
                    pending.trashDungeons[self.dungeonName] = true
                end
                log:SyncSourceSelectButton(menu)
                log:SyncBranchSelectLabel(branch, pending.trashDungeons, branch._selectKeys)
            end)
            branch.rows[i] = row
        end
        self:AnchorBranchCheck(branch, row, i)
        row.dungeonName = name
        row.label:SetText(name)
        row:SetChecked(not hidden[name])
        row:SetHitRectInsets(0, -((row.label:GetStringWidth() or 90) + 8), -2, -2)
        row:Show()
        local rowWidth = (row.label:GetStringWidth() or 80) + 46
        if rowWidth > width then
            width = rowWidth
        end
    end
    for i = #names + 1, #branch.rows do
        branch.rows[i]:Hide()
    end
    if #names == 0 then
        if branch.empty then
            branch.empty:Show()
        end
        branch._selectKeys = nil
        if branch.selectBtn then
            branch.selectBtn:Hide()
        end
        branch:SetSize(236, 32)
        return
    end
    if branch.empty then
        branch.empty:Hide()
    end
    if width < 200 then
        width = 200
    end
    width = width + 36
    local keys = {}
    for i = 1, #names do
        keys[i] = names[i]
    end
    self:RememberBranchSelection(branch, "trashDungeons", self.PopulateTrashBranch, keys, hidden)
    branch:SetSize(width, 40 + (#names * 20))
end

function GQ.Log:ShowTrashBranch(check)
    local menu = self.frame and self.frame.sourceFilterMenu
    local branch = menu and menu.trashBranch
    if not branch or not check then
        return
    end
    self._trashHideGen = (self._trashHideGen or 0) + 1
    if not check:GetChecked() then
        self._trashRowHot = false
        branch:Hide()
        return
    end
    self._trashRowHot = true
    branch:ClearAllPoints()
    branch:SetPoint("TOPLEFT", self:FilterBranchAnchor(check), "TOPRIGHT", 2, 6)
    self:PopulateTrashBranch(menu)
    branch:Show()
end

function GQ.Log:ScheduleHideTrashBranch()
    local gen = (self._trashHideGen or 0) + 1
    self._trashHideGen = gen
    local function hide()
        if self._trashHideGen ~= gen then
            return
        end
        if self._trashRowHot or self._trashBranchHot then
            return
        end
        local menu = self.frame and self.frame.sourceFilterMenu
        local branch = menu and menu.trashBranch
        if branch then
            branch:Hide()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, hide)
    else
        hide()
    end
end

function GQ.Log:ToggleSourceFilterMenu()
    local menu = self.frame and self.frame.sourceFilterMenu
    if not menu then
        return
    end
    if menu:IsShown() then
        menu:Hide()
        return
    end
    self:CopyFilterDraft()
    if menu.sync then
        menu.sync()
    end
    menu:Show()
end

function GQ.Log:EnsureSimulatorPage(frame)
    self:EnsureLogPages(frame)
    local simPage = frame.simPage
    if simPage.simReady then
        return simPage
    end
    simPage.simReady = true

    local classInset = CreateFrame("Frame", nil, simPage)
    ApplyBlackBackground(classInset)
    ApplyMetalEdge(classInset, 12)
    frame.simClassInset = classInset

    local classTitle = classInset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classTitle:SetPoint("TOPLEFT", classInset, "TOPLEFT", 10, -8)
    classTitle:SetText("Classes")
    frame.simClassTitle = classTitle

    frame.simClassButtons = {}
    local classOrder = (GQ.Preview and GQ.Preview.CLASS_ORDER) or {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
    }
    for i, classFile in ipairs(classOrder) do
        local btn = CreateFrame("Button", "GearQuestSimClass" .. classFile, classInset)
        btn:SetHeight(22)

        btn.scene = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
        btn.scene:SetAllPoints()
        btn.scene:Hide()

        btn.shade = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        btn.shade:SetAllPoints()
        btn.shade:Hide()

        btn.highlight = btn:CreateTexture(nil, "ARTWORK")
        btn.highlight:SetAllPoints()
        btn.highlight:SetColorTexture(0.90, 0.75, 0.28, 1)
        btn.highlight:SetAlpha(0.22)
        btn.highlight:Hide()

        btn.text = CreateFontStringWithFallback(btn, SIM_CLASS_FONTS)
        btn.text:SetDrawLayer("OVERLAY")
        btn.text:SetPoint("LEFT", btn, "LEFT", 14, 0)
        btn.text:SetJustifyH("LEFT")
        btn.text:SetShadowColor(0, 0, 0, 0.85)
        btn.text:SetShadowOffset(1, -1)
        local label = (GQ.Preview and GQ.Preview.FormatClassName and GQ.Preview:FormatClassName(classFile)) or classFile
        btn.text:SetText(label)
        local colors = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[classFile]
        if colors then
            btn.text:SetTextColor(colors.r, colors.g, colors.b)
        end

        btn.classFile = classFile
        btn:SetScript("OnClick", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SelectSimulatorClass(self.classFile)
            end
        end)
        btn:SetScript("OnEnter", function(self)
            if not self.selected then
                local art = self.scene and self.scene:IsShown()
                self.highlight:SetAlpha(art and 0.12 or 0.35)
                self.highlight:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self.selected then
                self.highlight:Hide()
            end
        end)

        frame.simClassButtons[i] = btn
    end

    local simDetail = CreateFrame("Frame", nil, simPage)
    EnableClipping(simDetail)
    ApplyParchmentBackground(simDetail)
    ApplyMetalEdge(simDetail, 12)
    frame.simDetail = simDetail

    local simScroll = CreatePanelScrollFrame("GearQuestSimScroll", simDetail)
    local simChild = CreateFrame("Frame", "GearQuestSimScrollChild", simScroll)
    simChild:SetSize(300, 420)
    simScroll:SetScrollChild(simChild)
    frame.simScroll = simScroll
    frame.simScrollChild = simChild

    local title = CreateFontStringWithFallback(simChild, QUEST_DETAIL_TITLE_FONTS)
    title:SetPoint("TOPLEFT", simChild, "TOPLEFT", 8, -8)
    title:SetPoint("RIGHT", simChild, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetText("SIMULATOR")
    title:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simTitle = title

    local body = CreateFontStringWithFallback(simChild, QUEST_DETAIL_BODY_FONTS)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    body:SetPoint("RIGHT", simChild, "RIGHT", -8, 0)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetText("Pick a class on the left, then set faction, specialization, and level. Simulate to browse that character's upgrades in the log.")
    body:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.simBody = body

    local factionHeader = CreateFontStringWithFallback(simChild, QUEST_DETAIL_HEADER_FONTS)
    factionHeader:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -16)
    factionHeader:SetText("FACTION")
    factionHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simFactionHeader = factionHeader

    local allianceBtn = CreateFrame("Button", "GearQuestSimFactionAlliance", simChild, "UIPanelButtonTemplate")
    allianceBtn:SetSize(96, 22)
    allianceBtn:SetPoint("TOPLEFT", factionHeader, "BOTTOMLEFT", 0, -6)
    allianceBtn:SetText("Alliance")
    frame.simAllianceBtn = allianceBtn

    local hordeBtn = CreateFrame("Button", "GearQuestSimFactionHorde", simChild, "UIPanelButtonTemplate")
    hordeBtn:SetSize(96, 22)
    hordeBtn:SetPoint("LEFT", allianceBtn, "RIGHT", 6, 0)
    hordeBtn:SetText("Horde")
    frame.simHordeBtn = hordeBtn

    allianceBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log.simFaction = "Alliance"
            log:RefreshSimulator()
        end
    end)
    hordeBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log.simFaction = "Horde"
            log:RefreshSimulator()
        end
    end)

    local specHeader = CreateFontStringWithFallback(simChild, QUEST_DETAIL_HEADER_FONTS)
    specHeader:SetPoint("TOPLEFT", allianceBtn, "BOTTOMLEFT", 0, -16)
    specHeader:SetText("SPECIALIZATION")
    specHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simSpecHeader = specHeader

    frame.simSpecButtons = {}
    -- Mage has six specs. The rest have four or fewer. Layout wraps them.
    for i = 1, 6 do
        local specBtn = CreateFrame("Button", "GearQuestSimSpec" .. i, simChild, "UIPanelButtonTemplate")
        specBtn:SetSize(150, 22)
        specBtn:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -6)
        specBtn:Hide()
        specBtn:SetScript("OnEnter", function(self)
            local label = self.specLabel
            if not label or label == "" or not GameTooltip then
                return
            end
            local shown = self:GetText() or ""
            local text = self.GetFontString and self:GetFontString()
            if text and text.GetText then
                shown = text:GetText() or shown
            end
            if shown == label then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:Show()
        end)
        specBtn:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        specBtn:SetScript("OnClick", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log then
                return
            end
            log.simSpec = self.specId
            if GQ.Spec and self.specId then
                GQ.Spec:SetSelectedSpec(self.specId, log.simClass)
            end
            log:RefreshSimulator()
        end)
        frame.simSpecButtons[i] = specBtn
    end

    local levelHeader = CreateFontStringWithFallback(simChild, QUEST_DETAIL_HEADER_FONTS)
    levelHeader:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -72)
    levelHeader:SetText("LEVEL")
    levelHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simLevelHeader = levelHeader

    local levelEdit = CreateFrame("EditBox", "GearQuestSimLevelEdit", simChild, "InputBoxTemplate")
    levelEdit:SetSize(64, 20)
    levelEdit:SetPoint("LEFT", levelHeader, "RIGHT", 12, 0)
    levelEdit:SetAutoFocus(false)
    levelEdit:SetMaxLetters(2)
    frame.simLevelEdit = levelEdit
    levelEdit:SetScript("OnTextChanged", function(self)
        if GQ.Preview and GQ.Preview.SanitizeLevelEdit then
            GQ.Preview:SanitizeLevelEdit(self)
        end
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.RefreshSimulator then
            log:RefreshSimulator()
        end
    end)
    levelEdit:SetScript("OnEnterPressed", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ApplySimulator()
        end
    end)
    levelEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    for _, header in ipairs({ factionHeader, specHeader, levelHeader }) do
        local font, size, flags = header:GetFont()
        if font and size and size > 14 then
            header:SetFont(font, 14, flags)
        end
    end

    local status = CreateFontStringWithFallback(simChild, QUEST_DETAIL_BODY_FONTS)
    status:SetPoint("TOPLEFT", levelHeader, "BOTTOMLEFT", 0, -18)
    status:SetPoint("RIGHT", simChild, "RIGHT", -8, 0)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(true)
    status:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.simStatus = status

    local simulateBtn = CreateFrame("Button", "GearQuestSimApplyButton", simDetail, "UIPanelButtonTemplate")
    simulateBtn:SetSize(106, 22)
    simulateBtn:SetPoint("BOTTOMLEFT", simDetail, "BOTTOMLEFT", 16, 14)
    simulateBtn:SetText("Simulate")
    frame.simApplyBtn = simulateBtn
    simulateBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ApplySimulator()
        end
    end)

    local resetBtn = CreateFrame("Button", "GearQuestSimResetButton", simDetail, "UIPanelButtonTemplate")
    resetBtn:SetSize(148, 22)
    resetBtn:SetPoint("LEFT", simulateBtn, "RIGHT", 6, 0)
    resetBtn:SetText("Turn off simulation")
    frame.simResetBtn = resetBtn
    resetBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
            log:ResetSimulator()
        end
    end)

    -- A disabled button does not receive mouse events, so the hover tip sits on this frame.
    local resetHover = CreateFrame("Frame", nil, simDetail)
    resetHover:SetAllPoints(resetBtn)
    resetHover:EnableMouse(true)
    resetHover:SetFrameLevel((resetBtn:GetFrameLevel() or 1) + 5)
    resetHover:Hide()
    frame.simResetHover = resetHover
    resetHover:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("You are already seeing your character unsimulated.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    resetHover:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return simPage
end

function GQ.Log:LayoutSimulatorSpecs(frame)
    local header = frame and frame.simSpecHeader
    local levelHeader = frame and frame.simLevelHeader
    local child = frame and frame.simScrollChild
    if not header or not levelHeader or not child then
        return
    end

    local inner = child:GetWidth() or 0
    if inner < 80 then
        inner = RIGHT_COLUMN_WIDTH - 56
    end
    inner = inner - 16
    if inner < 80 then
        inner = 80
    end

    local shown = {}
    local buttons = frame.simSpecButtons or {}
    for i = 1, #buttons do
        if buttons[i]:IsShown() then
            shown[#shown + 1] = buttons[i]
        end
    end

    local gap = 6
    local half = math.floor((inner - gap) / 2)
    local columns = 2
    if half < 110 then
        columns = 1
    else
        for i = 1, #shown do
            local fs = shown[i]:GetFontString()
            local label = shown[i].specLabel or ""
            if fs and label ~= "" then
                fs:SetText(label)
                if (fs:GetStringWidth() or 0) > (half - 16) then
                    columns = 1
                    break
                end
            end
        end
    end

    local btnW = columns == 2 and half or inner
    for i = 1, #shown do
        local btn = shown[i]
        btn:ClearAllPoints()
        btn:SetSize(btnW, 22)
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        btn:SetPoint("TOPLEFT", header, "BOTTOMLEFT", col * (btnW + gap), -6 - (row * 26))
        local fs = btn:GetFontString()
        if fs then
            TruncateFontStringToWidth(fs, btn.specLabel or btn:GetText() or "", btnW - 16)
        end
    end

    local rows = 0
    if #shown > 0 then
        rows = math.floor((#shown - 1) / columns) + 1
    end
    local drop = 16
    if rows > 0 then
        drop = 6 + (rows * 26) + 12
    end
    levelHeader:ClearAllPoints()
    if header:IsShown() then
        levelHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -drop)
    elseif frame.simAllianceBtn then
        levelHeader:SetPoint("TOPLEFT", frame.simAllianceBtn, "BOTTOMLEFT", 0, -16)
    end
end

function GQ.Log:LayoutSimulatorContent(frame)
    local scroll = frame and frame.simScroll
    local child = frame and frame.simScrollChild
    local detail = frame and frame.simDetail
    if not scroll or not child or not detail then
        return
    end

    -- Simulate and Turn off simulation stay pinned under the scrolling text.
    LayoutColumnScroll(scroll, detail, 46)
    local width = scroll:GetWidth()
    if not width or width < 40 then
        width = RIGHT_COLUMN_WIDTH - 56
    end
    child:SetWidth(math.max(width, 40))
    self:LayoutSimulatorSpecs(frame)

    local top = child:GetTop()
    local status = frame.simStatus
    local bottom = status and status.GetBottom and status:GetBottom()
    if not top or not bottom or top <= bottom then
        local pageShown = frame.simPage and frame.simPage.IsShown and frame.simPage:IsShown()
        if pageShown and not frame._simScrollWait and C_Timer and C_Timer.After then
            frame._simScrollWait = true
            C_Timer.After(0, function()
                frame._simScrollWait = nil
                local log = _G.GearQuest and _G.GearQuest.Log
                if log and log.frame and log.LayoutSimulatorContent then
                    log:LayoutSimulatorContent(log.frame)
                end
            end)
        end
        return
    end

    local kept = 0
    if scroll.GetVerticalScroll then
        kept = scroll:GetVerticalScroll() or 0
    end
    child:SetHeight((top - bottom) + 14)
    UpdateScrollChildRect(scroll)
    local range = 0
    if scroll.GetVerticalScrollRange then
        range = scroll:GetVerticalScrollRange() or 0
    end
    if kept > range then
        kept = range
    end
    if kept < 0 then
        kept = 0
    end
    if scroll.SetVerticalScroll then
        scroll:SetVerticalScroll(kept)
    end
    ApplyScrollBarVisibility(scroll)
end

function GQ.Log:LayoutSimulatorPage(frame)
    if not frame.simPage or not frame.simClassInset or not frame.simDetail then
        return
    end

    frame.simClassInset:ClearAllPoints()
    frame.simClassInset:SetPoint("TOPLEFT", frame.simPage, "TOPLEFT", 0, LOG_SECTION_TOP)
    frame.simClassInset:SetPoint("BOTTOMLEFT", frame.simPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
    frame.simClassInset:SetWidth(LEFT_COLUMN_WIDTH)
    ApplyBlackBackground(frame.simClassInset)
    ApplyMetalEdge(frame.simClassInset, 16)

    if frame.simClassTitle then
        frame.simClassTitle:Hide()
    end
    local buttons = frame.simClassButtons
    if buttons and #buttons > 0 then
        local n = #buttons
        local innerH = SimulatorClassInsetHeight(frame.simClassInset) - (SIM_CLASS_ROW_PAD * 2)
        local rowH = math.floor((innerH - (SIM_CLASS_ROW_GAP * (n - 1))) / n)
        if rowH < 16 then
            rowH = 16
        end
        local rowW = LEFT_COLUMN_WIDTH - (SIM_CLASS_ROW_PAD * 2)
        for i, btn in ipairs(buttons) do
            local y = -SIM_CLASS_ROW_PAD - ((i - 1) * (rowH + SIM_CLASS_ROW_GAP))
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame.simClassInset, "TOPLEFT", SIM_CLASS_ROW_PAD, y)
            btn:SetSize(rowW, rowH)
            btn.rowW = rowW
            btn.rowH = rowH
        end
    end
    if self.UpdateSimClassRowArt then
        self:UpdateSimClassRowArt()
    end

    frame.simDetail:ClearAllPoints()
    frame.simDetail:SetPoint("TOPLEFT", frame.simPage, "TOPLEFT", LEFT_COLUMN_WIDTH + COLUMN_GAP, LOG_SECTION_TOP)
    frame.simDetail:SetPoint("BOTTOMRIGHT", frame.simPage, "BOTTOMRIGHT", 0, FOOTER_OFFSET)
    ApplyMetalEdge(frame.simDetail, 16)
    self:LayoutSimulatorContent(frame)
end

local function CreateSettingsCheck(parent, label, frameName)
    local ok, btn = pcall(CreateFrame, "CheckButton", frameName or "GearQuestHideMinimapCheck", parent, "UICheckButtonTemplate")
    if not ok or not btn then
        btn = CreateFrame("CheckButton", nil, parent)
        btn:SetSize(24, 24)
        btn:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        btn:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    end
    btn:SetSize(24, 24)
    local text = btn.Text
    if not text and btn.GetName and btn:GetName() then
        text = _G[btn:GetName() .. "Text"]
    end
    if not text then
        text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "RIGHT", 2, 0)
    end
    text:SetText(label)
    text:SetTextColor(0, 0, 0)
    btn.text = text
    return btn
end

function GQ.Log:CreateGearScoreSetting(frame, detail, anchor)
    local label = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    label:SetJustifyH("LEFT")
    label:SetText("GearQuest score on tooltips")
    label:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsScoreLabel = label

    local hit = CreateFrame("Button", nil, detail)
    hit:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    hit:SetSize(math.max(label:GetStringWidth() or 0, 1) + 4, math.max(label:GetStringHeight() or 0, 18))
    label:SetParent(hit)
    label:ClearAllPoints()
    label:SetPoint("LEFT", hit, "LEFT", 0, 0)
    frame.settingsScoreLabelHit = hit

    local function ApplyScoreCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.showGearScore = checked and true or false
    end

    local check = CreateSettingsCheck(detail, "")
    check:SetPoint("RIGHT", hit, "LEFT", -6, 0)
    check:SetChecked(true)
    if check.text then
        check.text:SetText("")
        check.text:Hide()
    end
    check:SetScript("OnClick", function(self)
        ApplyScoreCheck(self:GetChecked())
    end)
    hit:SetScript("OnClick", function()
        local checked = not check:GetChecked()
        check:SetChecked(checked)
        ApplyScoreCheck(checked)
    end)
    frame.settingsScoreCheck = check

    local hint = CreateFontStringWithFallback(detail, {
        "QuestFontNormalSmall",
        "SystemFont_Small",
        "SystemFont_Shadow_Small",
        "QuestFont",
    })
    hint:SetPoint("TOPLEFT", hit, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText("Shows the rank, score, and comparison to your equipped gear on gear tooltips.")
    hint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsScoreHint = hint

    local barLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    barLabel:SetJustifyH("LEFT")
    barLabel:SetText("GearQuest score bar")
    barLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsScoreBarLabel = barLabel

    local barHit = CreateFrame("Button", nil, detail)
    barHit:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -16)
    barHit:SetSize(math.max(barLabel:GetStringWidth() or 0, 1) + 4, math.max(barLabel:GetStringHeight() or 0, 18))
    barLabel:SetParent(barHit)
    barLabel:ClearAllPoints()
    barLabel:SetPoint("LEFT", barHit, "LEFT", 0, 0)
    frame.settingsScoreBarLabelHit = barHit

    local function ApplyBarCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.showGearScoreBar = checked and true or false
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.UpdateContextStatus then
            log:UpdateContextStatus()
        end
    end

    local barCheck = CreateSettingsCheck(detail, "")
    barCheck:SetPoint("RIGHT", barHit, "LEFT", -6, 0)
    barCheck:SetChecked(true)
    if barCheck.text then
        barCheck.text:SetText("")
        barCheck.text:Hide()
    end
    barCheck:SetScript("OnClick", function(self)
        ApplyBarCheck(self:GetChecked())
    end)
    barHit:SetScript("OnClick", function()
        local checked = not barCheck:GetChecked()
        barCheck:SetChecked(checked)
        ApplyBarCheck(checked)
    end)
    frame.settingsScoreBarCheck = barCheck

    local barHint = CreateFontStringWithFallback(detail, {
        "QuestFontNormalSmall",
        "SystemFont_Small",
        "SystemFont_Shadow_Small",
        "QuestFont",
    })
    barHint:SetPoint("TOPLEFT", barHit, "BOTTOMLEFT", 0, -4)
    barHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    barHint:SetJustifyH("LEFT")
    barHint:SetWordWrap(true)
    barHint:SetText("Shows the score bar in the log header. Off restores the viewing-upgrades line.")
    barHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsScoreBarHint = barHint
end

function GQ.Log:CreateChatSetting(frame, detail, anchor)
    local label = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    label:SetJustifyH("LEFT")
    label:SetText("Hide chat messages")
    label:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsChatLabel = label

    local hit = CreateFrame("Button", nil, detail)
    hit:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    hit:SetSize(math.max(label:GetStringWidth() or 0, 1) + 4, math.max(label:GetStringHeight() or 0, 18))
    label:SetParent(hit)
    label:ClearAllPoints()
    label:SetPoint("LEFT", hit, "LEFT", 0, 0)
    frame.settingsChatLabelHit = hit

    local function ApplyChatCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.hideChat = checked and true or false
    end

    local check = CreateSettingsCheck(detail, "", "GearQuestHideChatCheck")
    check:SetPoint("RIGHT", hit, "LEFT", -6, 0)
    local saved = GearQuestForeverDB and GearQuestForeverDB.settings
    check:SetChecked(saved and saved.hideChat and true or false)
    if check.text then
        check.text:SetText("")
        check.text:Hide()
    end
    check:SetScript("OnClick", function(self)
        local box = self
        local function save()
            ApplyChatCheck(box:GetChecked() and true or false)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, save)
        else
            save()
        end
    end)
    hit:SetScript("OnClick", function()
        local checked = not check:GetChecked()
        check:SetChecked(checked)
        ApplyChatCheck(checked)
    end)
    frame.settingsChatCheck = check

    local hint = CreateFontStringWithFallback(detail, {
        "QuestFontNormalSmall",
        "SystemFont_Small",
        "SystemFont_Shadow_Small",
        "QuestFont",
    })
    hint:SetPoint("TOPLEFT", hit, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText("Stops every GearQuest line in chat, including login, obtain notices, and /gq replies. The log stays.")
    hint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsChatHint = hint
end

function GQ.Log:EnsureSettingsPage(frame)
    self:EnsureLogPages(frame)
    local page = frame.settingsPage
    if page.settingsReady then
        return page
    end
    page.settingsReady = true

    local list = CreateFrame("Frame", nil, page)
    ApplyBlackBackground(list)
    ApplyMetalEdge(list, 16)
    frame.settingsList = list

    local function WireSettingsListHover(btn)
        if not btn or btn.gqHover then
            return
        end
        local hover = btn:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetColorTexture(0.62, 0.50, 0.18, 0.55)
        btn:SetHighlightTexture(hover)
        btn.gqHover = hover
    end

    local general = CreateFrame("Button", "GearQuestSettingsGeneral", list)
    general:SetHeight(22)
    general:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -8)
    general:SetPoint("TOPRIGHT", list, "TOPRIGHT", -8, -8)
    general.highlight = general:CreateTexture(nil, "BACKGROUND")
    general.highlight:SetAllPoints()
    general.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.85)
    general.highlight:Show()
    general.text = general:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    general.text:SetPoint("LEFT", general, "LEFT", 8, 0)
    general.text:SetJustifyH("LEFT")
    general.text:SetText("General")
    general.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    general:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetSettingsSection("general")
        end
    end)
    WireSettingsListHover(general)
    frame.settingsGeneralBtn = general

    local hunts = CreateFrame("Button", "GearQuestSettingsHunts", list)
    hunts:SetHeight(22)
    hunts:SetPoint("TOPLEFT", general, "BOTTOMLEFT", 0, -2)
    hunts:SetPoint("TOPRIGHT", general, "BOTTOMRIGHT", 0, -2)
    hunts.highlight = hunts:CreateTexture(nil, "BACKGROUND")
    hunts.highlight:SetAllPoints()
    hunts.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.85)
    hunts.highlight:Hide()
    hunts.text = hunts:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hunts.text:SetPoint("LEFT", hunts, "LEFT", 8, 0)
    hunts.text:SetJustifyH("LEFT")
    hunts.text:SetText("Hunts")
    hunts.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    hunts:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetSettingsSection("hunts")
        end
    end)
    WireSettingsListHover(hunts)
    frame.settingsHuntsBtn = hunts

    local commands = CreateFrame("Button", "GearQuestSettingsCommands", list)
    commands:SetHeight(22)
    commands:SetPoint("TOPLEFT", hunts, "BOTTOMLEFT", 0, -2)
    commands:SetPoint("TOPRIGHT", hunts, "BOTTOMRIGHT", 0, -2)
    commands.highlight = commands:CreateTexture(nil, "BACKGROUND")
    commands.highlight:SetAllPoints()
    commands.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.85)
    commands.highlight:Hide()
    commands.text = commands:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    commands.text:SetPoint("LEFT", commands, "LEFT", 8, 0)
    commands.text:SetPoint("RIGHT", commands, "RIGHT", -8, 0)
    commands.text:SetJustifyH("LEFT")
    commands.text:SetText("GearQuest Commands")
    commands.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    commands:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetSettingsSection("commands")
        end
    end)
    WireSettingsListHover(commands)
    frame.settingsCommandsBtn = commands

    local credits = CreateFrame("Button", "GearQuestSettingsCredits", list)
    credits:SetHeight(22)
    credits:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -2)
    credits:SetPoint("TOPRIGHT", commands, "BOTTOMRIGHT", 0, -2)
    credits.highlight = credits:CreateTexture(nil, "BACKGROUND")
    credits.highlight:SetAllPoints()
    credits.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.85)
    credits.highlight:Hide()
    credits.text = credits:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    credits.text:SetPoint("LEFT", credits, "LEFT", 8, 0)
    credits.text:SetPoint("RIGHT", credits, "RIGHT", -8, 0)
    credits.text:SetJustifyH("LEFT")
    credits.text:SetText("The GearQuest Community")
    credits.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    credits:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:SetSettingsSection("credits")
        end
    end)
    WireSettingsListHover(credits)
    frame.settingsCreditsBtn = credits

    local detail = CreateFrame("Frame", nil, page)
    EnableClipping(detail)
    ApplyParchmentBackground(detail)
    ApplyMetalEdge(detail, 16)
    frame.settingsDetail = detail

    local pageTitle = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    pageTitle:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -16)
    pageTitle:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    pageTitle:SetJustifyH("LEFT")
    pageTitle:SetWordWrap(true)
    pageTitle:SetText("General")
    pageTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsPageTitle = pageTitle

    local SETTINGS_NOTE_FONTS = {
        "QuestFontNormalSmall",
        "SystemFont_Small",
        "SystemFont_Shadow_Small",
        "QuestFont",
    }

    local label = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    label:SetJustifyH("LEFT")
    label:SetText("Hide minimap icon")
    label:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsMinimapLabel = label

    local labelHit = CreateFrame("Button", nil, detail)
    labelHit:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 32, -14)
    labelHit:SetSize(math.max(label:GetStringWidth() or 0, 1) + 4, math.max(label:GetStringHeight() or 0, 18))
    label:SetParent(labelHit)
    label:ClearAllPoints()
    label:SetPoint("LEFT", labelHit, "LEFT", 0, 0)
    frame.settingsMinimapLabelHit = labelHit

    local function ApplyMinimapCheck(checked)
        if GQ.Minimap and GQ.Minimap.SetHidden then
            GQ.Minimap:SetHidden(checked)
        end
    end

    local check = CreateSettingsCheck(detail, "")
    check:SetPoint("RIGHT", labelHit, "LEFT", -6, 0)
    if check.text then
        check.text:SetText("")
        check.text:Hide()
    end
    check:SetScript("OnClick", function(self)
        ApplyMinimapCheck(self:GetChecked())
    end)
    labelHit:SetScript("OnClick", function()
        local checked = not check:GetChecked()
        check:SetChecked(checked)
        ApplyMinimapCheck(checked)
    end)
    frame.settingsMinimapCheck = check

    local hint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    hint:SetPoint("TOPLEFT", labelHit, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText("You can still open GearQuest with /gq while the icon is hidden.")
    hint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsHint = hint

    local largeLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    largeLabel:SetJustifyH("LEFT")
    largeLabel:SetText("Window size")
    largeLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsLargeLabel = largeLabel

    local largeHit = CreateFrame("Button", nil, detail)
    largeHit:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -16)
    largeHit:SetSize(math.max(largeLabel:GetStringWidth() or 0, 1) + 4, math.max(largeLabel:GetStringHeight() or 0, 18))
    largeLabel:SetParent(largeHit)
    largeLabel:ClearAllPoints()
    largeLabel:SetPoint("LEFT", largeHit, "LEFT", 0, 0)
    frame.settingsLargeLabelHit = largeHit

    local largeValue = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    largeValue:SetPoint("LEFT", largeHit, "RIGHT", 8, 0)
    largeValue:SetJustifyH("LEFT")
    largeValue:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsLargeValue = largeValue

    local function WindowPercent()
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        local percent = settings and tonumber(settings.windowScalePercent)
        if not percent and settings and settings.largeWindow then
            percent = 150
        end
        percent = math.floor((tonumber(percent) or 100) + 0.5)
        if percent < 100 then
            percent = 100
        elseif percent > 150 then
            percent = 150
        end
        return percent
    end

    local slider
    local createdOk, created = pcall(CreateFrame, "Slider", "GearQuestWindowScaleSlider", detail, "OptionsSliderTemplate")
    if createdOk and created then
        slider = created
    else
        slider = CreateFrame("Slider", "GearQuestWindowScaleSlider", detail)
        slider:SetOrientation("HORIZONTAL")
        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        thumb:SetSize(32, 32)
        slider:SetThumbTexture(thumb)
    end
    slider:SetPoint("TOPLEFT", largeHit, "BOTTOMLEFT", 0, -6)
    slider:SetWidth(220)
    slider:SetHeight(17)
    slider:SetMinMaxValues(100, 150)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end
    local sliderName = slider:GetName()
    local lowText = slider.Low or (sliderName and _G[sliderName .. "Low"])
    local highText = slider.High or (sliderName and _G[sliderName .. "High"])
    local titleText = slider.Text or (sliderName and _G[sliderName .. "Text"])
    if lowText then
        lowText:SetText("100%")
        lowText:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    end
    if highText then
        highText:SetText("150%")
        highText:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    end
    if titleText then
        titleText:SetText("")
        titleText:Hide()
    end
    local function ApplyWindowPercent(percent)
        percent = math.floor((tonumber(percent) or 100) + 0.5)
        if percent < 100 then
            percent = 100
        elseif percent > 150 then
            percent = 150
        end
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.windowScalePercent = percent
        GearQuestForeverDB.settings.largeWindow = nil
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.ApplyWindowScale then
            log:ApplyWindowScale()
        end
    end

    slider:SetScript("OnValueChanged", function(self, value)
        local percent = math.floor((tonumber(value) or 100) + 0.5)
        if percent < 100 then
            percent = 100
        elseif percent > 150 then
            percent = 150
        end
        largeValue:SetText(tostring(percent) .. "%")
        if self._gqQuiet then
            return
        end
        -- Resizing while the thumb is held moves the slider under the cursor.
        if IsMouseButtonDown and IsMouseButtonDown("LeftButton") then
            return
        end
        ApplyWindowPercent(percent)
    end)
    slider:SetScript("OnMouseUp", function(self)
        if self._gqQuiet then
            return
        end
        ApplyWindowPercent(self:GetValue())
    end)
    slider._gqQuiet = true
    slider:SetValue(WindowPercent())
    slider._gqQuiet = nil
    largeValue:SetText(tostring(WindowPercent()) .. "%")
    frame.settingsLargeSlider = slider

    local largeHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    largeHint:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -16)
    largeHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    largeHint:SetJustifyH("LEFT")
    largeHint:SetWordWrap(true)
    largeHint:SetText("100% is the normal window. 150% is half again as tall and wide. Each step is one percent. The filter and the spec menu follow this size.")
    largeHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsLargeHint = largeHint

    local artLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    artLabel:SetJustifyH("LEFT")
    artLabel:SetText("Remove background art")
    artLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsArtLabel = artLabel

    local artHit = CreateFrame("Button", nil, detail)
    artHit:SetPoint("TOPLEFT", frame.settingsLargeHint, "BOTTOMLEFT", 0, -16)
    artHit:SetSize(math.max(artLabel:GetStringWidth() or 0, 1) + 4, math.max(artLabel:GetStringHeight() or 0, 18))
    artLabel:SetParent(artHit)
    artLabel:ClearAllPoints()
    artLabel:SetPoint("LEFT", artHit, "LEFT", 0, 0)
    frame.settingsArtLabelHit = artHit

    local function ApplyArtCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.hideLogArt = checked and true or false
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.UpdateLogScene then
            log:UpdateLogScene()
        end
    end

    local artCheck = CreateSettingsCheck(detail, "")
    artCheck:SetPoint("RIGHT", artHit, "LEFT", -6, 0)
    if artCheck.text then
        artCheck.text:SetText("")
        artCheck.text:Hide()
    end
    artCheck:SetScript("OnClick", function(self)
        ApplyArtCheck(self:GetChecked())
    end)
    artHit:SetScript("OnClick", function()
        local checked = not artCheck:GetChecked()
        artCheck:SetChecked(checked)
        ApplyArtCheck(checked)
    end)
    frame.settingsArtCheck = artCheck

    local artHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    artHint:SetPoint("TOPLEFT", artHit, "BOTTOMLEFT", 0, -4)
    artHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    artHint:SetJustifyH("LEFT")
    artHint:SetWordWrap(true)
    artHint:SetText("Shows the plain brown log background instead of the class art.")
    artHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.settingsArtHint = artHint

    self:CreateGearScoreSetting(frame, detail, artHint)
    self:CreateChatSetting(frame, detail, frame.settingsScoreBarHint)

    local toastLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    toastLabel:SetJustifyH("LEFT")
    toastLabel:SetText("Hide obtain popup")
    toastLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsToastLabel = toastLabel

    local toastHit = CreateFrame("Button", nil, detail)
    toastHit:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 32, -14)
    toastHit:SetSize(math.max(toastLabel:GetStringWidth() or 0, 1) + 4, math.max(toastLabel:GetStringHeight() or 0, 18))
    toastLabel:SetParent(toastHit)
    toastLabel:ClearAllPoints()
    toastLabel:SetPoint("LEFT", toastHit, "LEFT", 0, 0)
    toastHit:Hide()
    frame.settingsToastLabelHit = toastHit

    local function ApplyToastCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.hideObtainToast = checked and true or false
        if checked and GQ.Toast and GQ.Toast.ClearQueue then
            GQ.Toast:ClearQueue()
        end
    end

    local toastCheck = CreateSettingsCheck(detail, "")
    toastCheck:SetPoint("RIGHT", toastHit, "LEFT", -6, 0)
    if toastCheck.text then
        toastCheck.text:SetText("")
        toastCheck.text:Hide()
    end
    toastCheck:SetScript("OnClick", function(self)
        ApplyToastCheck(self:GetChecked())
    end)
    toastHit:SetScript("OnClick", function()
        local checked = not toastCheck:GetChecked()
        toastCheck:SetChecked(checked)
        ApplyToastCheck(checked)
    end)
    toastCheck:Hide()
    frame.settingsToastCheck = toastCheck

    local toastHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    toastHint:SetPoint("TOPLEFT", toastHit, "BOTTOMLEFT", 0, -4)
    toastHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    toastHint:SetJustifyH("LEFT")
    toastHint:SetWordWrap(true)
    toastHint:SetText("Stops the popup when you obtain a piece from the hunt list.")
    toastHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    toastHint:Hide()
    frame.settingsToastHint = toastHint

    local arrowLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    arrowLabel:SetJustifyH("LEFT")
    arrowLabel:SetText("Hide upgrade arrows")
    arrowLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsArrowLabel = arrowLabel

    local arrowHit = CreateFrame("Button", nil, detail)
    arrowHit:SetPoint("TOPLEFT", toastHint, "BOTTOMLEFT", 0, -16)
    arrowHit:SetSize(math.max(arrowLabel:GetStringWidth() or 0, 1) + 4, math.max(arrowLabel:GetStringHeight() or 0, 18))
    arrowLabel:SetParent(arrowHit)
    arrowLabel:ClearAllPoints()
    arrowLabel:SetPoint("LEFT", arrowHit, "LEFT", 0, 0)
    arrowHit:Hide()
    frame.settingsArrowLabelHit = arrowHit

    local function ApplyArrowCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.hideUpgradeArrows = checked and true or false
        if GQ.Indicator and GQ.Indicator.ApplyArrowVisibility then
            GQ.Indicator:ApplyArrowVisibility()
        end
    end

    local arrowCheck = CreateSettingsCheck(detail, "")
    arrowCheck:SetPoint("RIGHT", arrowHit, "LEFT", -6, 0)
    if arrowCheck.text then
        arrowCheck.text:SetText("")
        arrowCheck.text:Hide()
    end
    arrowCheck:SetScript("OnClick", function(self)
        ApplyArrowCheck(self:GetChecked())
    end)
    arrowHit:SetScript("OnClick", function()
        local checked = not arrowCheck:GetChecked()
        arrowCheck:SetChecked(checked)
        ApplyArrowCheck(checked)
    end)
    arrowCheck:Hide()
    frame.settingsArrowCheck = arrowCheck

    local arrowHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    arrowHint:SetPoint("TOPLEFT", arrowHit, "BOTTOMLEFT", 0, -4)
    arrowHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    arrowHint:SetJustifyH("LEFT")
    arrowHint:SetWordWrap(true)
    arrowHint:SetText("Removes the green arrow from the quest log, quest giver, loot window, and vendors.")
    arrowHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    arrowHint:Hide()
    frame.settingsArrowHint = arrowHint

    local guideLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    guideLabel:SetJustifyH("LEFT")
    guideLabel:SetText("Hide guide arrow")
    guideLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsGuideLabel = guideLabel

    local guideHit = CreateFrame("Button", nil, detail)
    guideHit:SetPoint("TOPLEFT", arrowHint, "BOTTOMLEFT", 0, -16)
    guideHit:SetSize(math.max(guideLabel:GetStringWidth() or 0, 1) + 4, math.max(guideLabel:GetStringHeight() or 0, 18))
    guideLabel:SetParent(guideHit)
    guideLabel:ClearAllPoints()
    guideLabel:SetPoint("LEFT", guideHit, "LEFT", 0, 0)
    guideHit:Hide()
    frame.settingsGuideLabelHit = guideHit

    local function ApplyGuideCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.hideGuideArrow = checked and true or false
        if GQ.Guide and GQ.Guide.Apply then
            GQ.Guide:Apply()
        end
    end

    local guideCheck = CreateSettingsCheck(detail, "")
    guideCheck:SetPoint("RIGHT", guideHit, "LEFT", -6, 0)
    if guideCheck.text then
        guideCheck.text:SetText("")
        guideCheck.text:Hide()
    end
    guideCheck:SetScript("OnClick", function(self)
        ApplyGuideCheck(self:GetChecked())
    end)
    guideHit:SetScript("OnClick", function()
        local checked = not guideCheck:GetChecked()
        guideCheck:SetChecked(checked)
        ApplyGuideCheck(checked)
    end)
    guideCheck:Hide()
    frame.settingsGuideCheck = guideCheck

    local guideHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    guideHint:SetPoint("TOPLEFT", guideHit, "BOTTOMLEFT", 0, -4)
    guideHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    guideHint:SetJustifyH("LEFT")
    guideHint:SetWordWrap(true)
    guideHint:SetText("Removes the arrow that points you toward a hunt. It stays hidden until this is off.")
    guideHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    guideHint:Hide()
    frame.settingsGuideHint = guideHint

    local enchantLabel = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    enchantLabel:SetJustifyH("LEFT")
    enchantLabel:SetText("Recommended gear enchantment")
    enchantLabel:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.settingsEnchantLabel = enchantLabel

    local enchantHit = CreateFrame("Button", nil, detail)
    enchantHit:SetPoint("TOPLEFT", guideHint, "BOTTOMLEFT", 0, -16)
    enchantHit:SetSize(math.max(enchantLabel:GetStringWidth() or 0, 1) + 4, math.max(enchantLabel:GetStringHeight() or 0, 18))
    enchantLabel:SetParent(enchantHit)
    enchantLabel:ClearAllPoints()
    enchantLabel:SetPoint("LEFT", enchantHit, "LEFT", 0, 0)
    enchantHit:Hide()
    frame.settingsEnchantLabelHit = enchantHit

    local function ApplyEnchantCheck(checked)
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        GearQuestForeverDB.settings.showGearEnchant = checked and true or false
    end

    local enchantCheck = CreateSettingsCheck(detail, "")
    enchantCheck:SetPoint("RIGHT", enchantHit, "LEFT", -6, 0)
    if enchantCheck.text then
        enchantCheck.text:SetText("")
        enchantCheck.text:Hide()
    end
    enchantCheck:SetScript("OnClick", function(self)
        ApplyEnchantCheck(self:GetChecked())
    end)
    enchantHit:SetScript("OnClick", function()
        local checked = not enchantCheck:GetChecked()
        enchantCheck:SetChecked(checked)
        ApplyEnchantCheck(checked)
    end)
    enchantCheck:Hide()
    frame.settingsEnchantCheck = enchantCheck

    local enchantHint = CreateFontStringWithFallback(detail, SETTINGS_NOTE_FONTS)
    enchantHint:SetPoint("TOPLEFT", enchantHit, "BOTTOMLEFT", 0, -4)
    enchantHint:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    enchantHint:SetJustifyH("LEFT")
    enchantHint:SetWordWrap(true)
    enchantHint:SetText("Enable the recommended enchantment line on gear tooltips")
    enchantHint:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    enchantHint:Hide()
    frame.settingsEnchantHint = enchantHint

    local creditsTitle = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    creditsTitle:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -12)
    creditsTitle:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    creditsTitle:SetJustifyH("LEFT")
    creditsTitle:SetWordWrap(true)
    creditsTitle:SetText(
        "Collaborators from the community |cffffffff|TInterface\\AddOns\\"
            .. ADDON_NAME
            .. "\\Art\\GQ-Heart.png:16:16|t|r"
    )
    creditsTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    creditsTitle:Hide()
    frame.settingsCreditsTitle = creditsTitle

    local creditsBody = CreateFontStringWithFallback(detail, QUEST_DETAIL_BODY_FONTS)
    creditsBody:SetPoint("TOPLEFT", creditsTitle, "BOTTOMLEFT", 0, -6)
    creditsBody:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    creditsBody:SetJustifyH("LEFT")
    creditsBody:SetText("Eao\nMainWon\nStikmyre\nClick\nVaniron\nThrayne\nAlteredigor\nDeadlybrew")
    creditsBody:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    creditsBody:Hide()
    frame.settingsCreditsBody = creditsBody

    local discordInvite = "https://discord.gg/gQSVunBsR"

    local discordHeader = CreateFontStringWithFallback(detail, QUEST_DETAIL_TITLE_FONTS)
    discordHeader:SetPoint("TOPLEFT", creditsBody, "BOTTOMLEFT", 0, -22)
    discordHeader:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    discordHeader:SetJustifyH("LEFT")
    discordHeader:SetText("Discord")
    discordHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    discordHeader:Hide()
    frame.settingsDiscordHeader = discordHeader

    local discordBody = CreateFontStringWithFallback(detail, QUEST_DETAIL_BODY_FONTS)
    discordBody:SetPoint("TOPLEFT", discordHeader, "BOTTOMLEFT", 0, -6)
    discordBody:SetPoint("RIGHT", detail, "RIGHT", -16, 0)
    discordBody:SetJustifyH("LEFT")
    discordBody:SetWordWrap(true)
    discordBody:SetText("Join the GearQuest community to talk about class specs, stat weights, and what to hunt next. Share how GearQuest is going for you. Bug reports and feature ideas are welcome there too. Get the latest news and insights, and comment on upcoming features before they are released.")
    discordBody:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    discordBody:Hide()
    frame.settingsDiscordBody = discordBody

    local discordCopy = CreateFrame("Button", "GearQuestDiscordCopy", detail, "UIPanelButtonTemplate")
    discordCopy:SetSize(72, 22)
    discordCopy:SetPoint("TOPRIGHT", discordBody, "BOTTOMRIGHT", 0, -12)
    discordCopy:SetText("Copy")
    discordCopy:Hide()
    frame.settingsDiscordCopy = discordCopy

    local discordBox = CreateFrame("EditBox", "GearQuestDiscordInvite", detail, "InputBoxTemplate")
    discordBox:SetAutoFocus(false)
    discordBox:SetHeight(22)
    discordBox:SetPoint("TOPLEFT", discordBody, "BOTTOMLEFT", 8, -12)
    discordBox:SetPoint("RIGHT", discordCopy, "LEFT", -8, 0)
    discordBox:SetText(discordInvite)
    discordBox:SetCursorPosition(0)
    discordBox:Hide()
    frame.settingsDiscordBox = discordBox

    local function KeepDiscordInvite(box)
        if box._gqLock then
            return
        end
        if box:GetText() ~= discordInvite then
            box._gqLock = true
            box:SetText(discordInvite)
            box._gqLock = false
        end
    end
    discordBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    discordBox:SetScript("OnEditFocusGained", function(self)
        KeepDiscordInvite(self)
        self:HighlightText()
    end)
    discordBox:SetScript("OnTextChanged", function(self)
        KeepDiscordInvite(self)
    end)
    discordBox:SetScript("OnChar", function(self)
        KeepDiscordInvite(self)
        self:HighlightText()
    end)
    discordCopy:SetScript("OnClick", function(self)
        discordBox:Show()
        KeepDiscordInvite(discordBox)
        discordBox:SetFocus()
        discordBox:HighlightText()
        self:SetText("Ctrl+C")
        if C_Timer and C_Timer.After then
            C_Timer.After(1.6, function()
                if self:GetText() == "Ctrl+C" then
                    self:SetText("Copy")
                end
            end)
        end
    end)

    local commandScroll = CreatePanelScrollFrame("GearQuestSettingsCommandsScroll", detail)
    commandScroll:Hide()
    frame.settingsCommandsScroll = commandScroll

    local commandChild = CreateFrame("Frame", nil, commandScroll)
    commandChild:SetSize(20, 20)
    commandScroll:SetScrollChild(commandChild)
    frame.settingsCommandsChild = commandChild

    local commandEntries = {
        { "/gq", "Opens or closes the GearQuest window. /gearquest does the same." },
        { "/gq log", "Opens or closes the log. Same as /gq." },
        { "/gq help", "Prints the command list in chat." },
        { "/gq track", "Tracks the upgrade you have selected in the log." },
        { "/gq untrack", "Stops tracking the selected upgrade." },
        { "/gq set", "Shows the preview class, level, faction, and spec." },
        { "/gq set on", "Shows upgrades for the preview character instead of yours." },
        { "/gq set off", "Returns the lists to your own character." },
        { "/gq set me", "Copies your class, level, and faction into the preview. /gq me does the same." },
        { "/gq class hunter", "Sets the preview class. Use a class name, such as mage or shaman." },
        { "/gq level 37", "Sets the preview level from 1 to 60. /gq lvl 37 does the same." },
        { "/gq faction alliance", "Sets the preview faction to Alliance or Horde." },
        { "/gq spec enhancement", "Sets the specialization. Available from level 10." },
        { "/gq wipe data", "Clears tracked, completed, and obtained hunts for this character. Preview and these settings stay." },
    }
    local commandRows = {}
    local commandAnchor = nil
    for i = 1, #commandEntries do
        local entry = commandEntries[i]
        local cmd = CreateFontStringWithFallback(commandChild, QUEST_DETAIL_BODY_FONTS)
        if commandAnchor then
            cmd:SetPoint("TOPLEFT", commandAnchor, "BOTTOMLEFT", 0, -10)
        else
            cmd:SetPoint("TOPLEFT", commandChild, "TOPLEFT", 4, -2)
        end
        cmd:SetJustifyH("LEFT")
        cmd:SetWordWrap(true)
        cmd:SetText(entry[1])
        cmd:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
        if cmd.SetShadowColor then
            cmd:SetShadowColor(0, 0, 0, 1)
        end
        if cmd.SetShadowOffset then
            cmd:SetShadowOffset(1, -1)
        end
        local expl = CreateFontStringWithFallback(commandChild, QUEST_DETAIL_BODY_FONTS)
        expl:SetPoint("TOPLEFT", cmd, "BOTTOMLEFT", 0, -1)
        expl:SetJustifyH("LEFT")
        expl:SetWordWrap(true)
        expl:SetText(entry[2])
        expl:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
        if expl.SetShadowOffset then
            expl:SetShadowOffset(0, 0)
        end
        commandRows[#commandRows + 1] = { cmd = cmd, expl = expl }
        commandAnchor = expl
    end
    frame.settingsCommandRows = commandRows

    WireMouseWheel(commandScroll, commandScroll)
    WireMouseWheel(commandChild, commandScroll)
    self:MountSettingsGeneral(frame, detail)
    self:RefreshSettings()

    return page
end

function GQ.Log:MountSettingsGeneral(frame, detail)
    if not frame or not detail or frame.settingsGeneralScroll then
        return
    end
    local scroll = CreatePanelScrollFrame("GearQuestSettingsGeneralScroll", detail)
    scroll:Hide()
    frame.settingsGeneralScroll = scroll
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(20, 20)
    scroll:SetScrollChild(child)
    frame.settingsGeneralChild = child

    local widgets = {
        frame.settingsMinimapLabelHit, frame.settingsMinimapCheck, frame.settingsHint,
        frame.settingsLargeLabelHit, frame.settingsLargeValue, frame.settingsLargeSlider, frame.settingsLargeHint,
        frame.settingsArtLabelHit, frame.settingsArtCheck, frame.settingsArtHint,
        frame.settingsScoreLabelHit, frame.settingsScoreCheck, frame.settingsScoreHint,
        frame.settingsScoreBarLabelHit, frame.settingsScoreBarCheck, frame.settingsScoreBarHint,
        frame.settingsChatLabelHit, frame.settingsChatCheck, frame.settingsChatHint,
    }
    for i = 1, #widgets do
        if widgets[i] then
            widgets[i]:SetParent(child)
        end
    end
    if frame.settingsMinimapLabelHit then
        frame.settingsMinimapLabelHit:ClearAllPoints()
        frame.settingsMinimapLabelHit:SetPoint("TOPLEFT", child, "TOPLEFT", 32, -4)
    end
    local hints = {
        frame.settingsHint, frame.settingsLargeHint, frame.settingsArtHint, frame.settingsScoreHint,
        frame.settingsScoreBarHint, frame.settingsChatHint,
    }
    for i = 1, #hints do
        if hints[i] then
            hints[i]:SetPoint("RIGHT", child, "RIGHT", -8, 0)
        end
    end
    WireMouseWheel(scroll, scroll)
    WireMouseWheel(child, scroll)
    if detail.EnableMouseWheel then
        detail:EnableMouseWheel(true)
        detail:SetScript("OnMouseWheel", function(_, delta)
            local target = scroll
            if self.settingsSection == "commands" then
                target = frame.settingsCommandsScroll or scroll
            end
            ScrollFrameOnMouseWheel(target, delta)
        end)
    end
end

function GQ.Log:LayoutSettingsGeneral(frame)
    local scroll = frame and frame.settingsGeneralScroll
    local child = frame and frame.settingsGeneralChild
    local detail = frame and frame.settingsDetail
    if not scroll or not child or not detail then
        return
    end

    scroll:ClearAllPoints()
    local pageTitle = frame.settingsPageTitle
    if pageTitle then
        scroll:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", -2, -8)
    else
        scroll:SetPoint("TOPLEFT", detail, "TOPLEFT", 14, -40)
    end
    scroll:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -(14 + SCROLLBAR_WIDTH), 12)

    local width = scroll:GetWidth()
    if not width or width < 40 then
        width = RIGHT_COLUMN_WIDTH - 56
    end
    child:SetWidth(math.max(width, 40))

    local top = child:GetTop()
    local hint = frame.settingsChatHint
    local bottom = hint and hint.GetBottom and hint:GetBottom()
    local height = 520
    if top and bottom and top > bottom then
        height = (top - bottom) + 24
    end
    child:SetHeight(height)
    UpdateScrollChildRect(scroll)

    local show = self.settingsSection == nil or self.settingsSection == "general"
    local barName = scroll.GetName and scroll:GetName()
    local bar = barName and _G[barName .. "ScrollBar"]
    if show then
        scroll:Show()
        ApplyScrollBarVisibility(scroll)
        if bar and bar.SetFrameLevel and scroll.GetFrameLevel then
            bar:SetFrameLevel(scroll:GetFrameLevel() + 5)
        end
    else
        scroll:Hide()
        if scroll.SetVerticalScroll then
            scroll:SetVerticalScroll(0)
        end
        if bar then
            bar:Hide()
        end
    end

    if not frame.settingsGeneralMeasured and C_Timer and C_Timer.After then
        frame.settingsGeneralMeasured = true
        C_Timer.After(0, function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and log.frame then
                log:LayoutSettingsGeneral(log.frame)
            end
        end)
    end
end

function GQ.Log:LayoutSettingsCommands(frame)
    local scroll = frame and frame.settingsCommandsScroll
    local detail = frame and frame.settingsDetail
    if not scroll or not detail then
        return
    end

    scroll:ClearAllPoints()
    local pageTitle = frame.settingsPageTitle
    if pageTitle then
        scroll:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", -2, -8)
    else
        scroll:SetPoint("TOPLEFT", detail, "TOPLEFT", 14, -14)
    end
    scroll:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -(14 + SCROLLBAR_WIDTH), 12)

    local width = scroll:GetWidth()
    if not width or width < 40 then
        width = RIGHT_COLUMN_WIDTH - 56
    end
    local rows = frame.settingsCommandRows
    local child = frame.settingsCommandsChild
    local textWidth = math.max(width - 8, 40)
    if rows then
        for i = 1, #rows do
            rows[i].cmd:SetWidth(textWidth)
            rows[i].expl:SetWidth(textWidth)
        end
    end
    if child then
        local function lineHeight(fs, fallback)
            local h = fs and fs.GetStringHeight and fs:GetStringHeight() or 0
            if not h or h < 1 then
                return fallback
            end
            return h
        end
        local height = 4
        if rows then
            for i = 1, #rows do
                height = height + lineHeight(rows[i].cmd, 14) + 1 + lineHeight(rows[i].expl, 14)
                if i < #rows then
                    height = height + 10
                end
            end
        end
        child:SetWidth(math.max(width, 40))
        child:SetHeight(height + 16)
    end
    UpdateScrollChildRect(scroll)

    local barName = scroll.GetName and scroll:GetName()
    local bar = barName and _G[barName .. "ScrollBar"]
    if self.settingsSection == "commands" then
        scroll:Show()
        ApplyScrollBarVisibility(scroll)
        if bar and bar.SetFrameLevel and scroll.GetFrameLevel then
            bar:SetFrameLevel(scroll:GetFrameLevel() + 5)
        end
    else
        scroll:Hide()
        if bar then
            bar:Hide()
        end
    end

    if not frame.settingsCommandsMeasured and C_Timer and C_Timer.After then
        frame.settingsCommandsMeasured = true
        C_Timer.After(0, function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and log.frame then
                log:LayoutSettingsCommands(log.frame)
            end
        end)
    end
end

function GQ.Log:SetSettingsSection(section)
    if section ~= "hunts" and section ~= "credits" and section ~= "commands" then
        section = "general"
    end
    self.settingsSection = section
    local frame = self.frame
    if not frame then
        return
    end

    local pageTitle = frame.settingsPageTitle
    if pageTitle then
        local titleText = "General"
        if section == "hunts" then
            titleText = "Hunts"
        elseif section == "commands" then
            titleText = "GearQuest Commands"
        elseif section == "credits" then
            titleText = "The GearQuest Community"
        end
        pageTitle:SetText(titleText)
    end

    local function setHighlight(btn, on)
        if btn and btn.highlight then
            if on then
                btn.highlight:Show()
            else
                btn.highlight:Hide()
            end
        end
    end

    setHighlight(frame.settingsGeneralBtn, section == "general")
    setHighlight(frame.settingsHuntsBtn, section == "hunts")
    setHighlight(frame.settingsCommandsBtn, section == "commands")
    setHighlight(frame.settingsCreditsBtn, section == "credits")

    local function setShown(widgets, on)
        for i = 1, #widgets do
            local widget = widgets[i]
            if widget then
                if on then
                    widget:Show()
                else
                    widget:Hide()
                end
            end
        end
    end

    setShown({
        frame.settingsMinimapLabelHit,
        frame.settingsMinimapCheck,
        frame.settingsHint,
        frame.settingsLargeLabelHit,
        frame.settingsLargeValue,
        frame.settingsLargeSlider,
        frame.settingsLargeHint,
        frame.settingsArtLabelHit,
        frame.settingsArtCheck,
        frame.settingsArtHint,
        frame.settingsScoreLabelHit,
        frame.settingsScoreCheck,
        frame.settingsScoreHint,
        frame.settingsScoreBarLabelHit,
        frame.settingsScoreBarCheck,
        frame.settingsScoreBarHint,
        frame.settingsChatLabelHit,
        frame.settingsChatCheck,
        frame.settingsChatHint,
    }, section == "general")
    setShown({
        frame.settingsToastLabelHit,
        frame.settingsToastCheck,
        frame.settingsToastHint,
        frame.settingsArrowLabelHit,
        frame.settingsArrowCheck,
        frame.settingsArrowHint,
        frame.settingsGuideLabelHit,
        frame.settingsGuideCheck,
        frame.settingsGuideHint,
        frame.settingsEnchantLabelHit,
        frame.settingsEnchantCheck,
        frame.settingsEnchantHint,
    }, section == "hunts")
    local showCredits = section == "credits"
    setShown({
        frame.settingsCreditsTitle,
        frame.settingsCreditsBody,
        frame.settingsDiscordHeader,
        frame.settingsDiscordBody,
        frame.settingsDiscordBox,
        frame.settingsDiscordCopy,
    }, showCredits)
    if frame.settingsDiscordBox and not showCredits then
        frame.settingsDiscordBox:ClearFocus()
    end
    if frame.settingsDiscordCopy and showCredits then
        frame.settingsDiscordCopy:SetText("Copy")
    end
    self:LayoutSettingsCommands(frame)
    self:LayoutSettingsGeneral(frame)
end

function GQ.Log:LayoutSettingsPage(frame)
    if not frame.settingsPage or not frame.settingsList or not frame.settingsDetail then
        return
    end

    frame.settingsList:ClearAllPoints()
    frame.settingsList:SetPoint("TOPLEFT", frame.settingsPage, "TOPLEFT", 0, LOG_SECTION_TOP)
    frame.settingsList:SetPoint("BOTTOMLEFT", frame.settingsPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
    frame.settingsList:SetWidth(LEFT_COLUMN_WIDTH)
    ApplyBlackBackground(frame.settingsList)
    ApplyMetalEdge(frame.settingsList, 16)

    frame.settingsDetail:ClearAllPoints()
    frame.settingsDetail:SetPoint("TOPLEFT", frame.settingsPage, "TOPLEFT", LEFT_COLUMN_WIDTH + COLUMN_GAP, LOG_SECTION_TOP)
    frame.settingsDetail:SetPoint("BOTTOMRIGHT", frame.settingsPage, "BOTTOMRIGHT", 0, FOOTER_OFFSET)
    ApplyMetalEdge(frame.settingsDetail, 16)
    self:LayoutSettingsCommands(frame)
    self:LayoutSettingsGeneral(frame)
end

function GQ.Log:RefreshSettings()
    local frame = self.frame
    local check = frame and frame.settingsMinimapCheck
    if not check then
        return
    end
    local hidden = GQ.Minimap and GQ.Minimap.IsHidden and GQ.Minimap:IsHidden()
    check:SetChecked(hidden and true or false)
    local largeSlider = frame.settingsLargeSlider
    if largeSlider and largeSlider.SetValue then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        local percent = settings and tonumber(settings.windowScalePercent)
        if not percent and settings and settings.largeWindow then
            percent = 150
        end
        percent = math.floor((tonumber(percent) or 100) + 0.5)
        if percent < 100 then
            percent = 100
        elseif percent > 150 then
            percent = 150
        end
        largeSlider._gqQuiet = true
        largeSlider:SetValue(percent)
        largeSlider._gqQuiet = nil
        if frame.settingsLargeValue then
            frame.settingsLargeValue:SetText(tostring(percent) .. "%")
        end
    end
    local label = frame.settingsMinimapLabel
    local hit = frame.settingsMinimapLabelHit
    if label and hit and label.GetStringWidth then
        local width = label:GetStringWidth()
        local height = label.GetStringHeight and label:GetStringHeight()
        if width and width > 1 then
            hit:SetWidth(width + 4)
        end
        if height and height > 1 then
            hit:SetHeight(height)
        end
    end

    local artCheck = frame.settingsArtCheck
    if artCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        artCheck:SetChecked(settings and settings.hideLogArt and true or false)
    end
    local scoreCheck = frame.settingsScoreCheck
    if scoreCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        scoreCheck:SetChecked(not settings or settings.showGearScore ~= false)
    end
    local barCheck = frame.settingsScoreBarCheck
    if barCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        barCheck:SetChecked(not settings or settings.showGearScoreBar ~= false)
    end
    local chatCheck = frame.settingsChatCheck
    if chatCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        chatCheck:SetChecked(settings and settings.hideChat and true or false)
    end
    local chatLabel = frame.settingsChatLabel
    local chatHit = frame.settingsChatLabelHit
    if chatLabel and chatHit and chatLabel.GetStringWidth then
        local width = chatLabel:GetStringWidth()
        local height = chatLabel.GetStringHeight and chatLabel:GetStringHeight()
        if width and width > 1 then
            chatHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            chatHit:SetHeight(height)
        end
    end
    local barLabel = frame.settingsScoreBarLabel
    local barHit = frame.settingsScoreBarLabelHit
    if barLabel and barHit and barLabel.GetStringWidth then
        local width = barLabel:GetStringWidth()
        local height = barLabel.GetStringHeight and barLabel:GetStringHeight()
        if width and width > 1 then
            barHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            barHit:SetHeight(height)
        end
    end
    local scoreLabel = frame.settingsScoreLabel
    local scoreHit = frame.settingsScoreLabelHit
    if scoreLabel and scoreHit and scoreLabel.GetStringWidth then
        local width = scoreLabel:GetStringWidth()
        local height = scoreLabel.GetStringHeight and scoreLabel:GetStringHeight()
        if width and width > 1 then
            scoreHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            scoreHit:SetHeight(height)
        end
    end
    local artLabel = frame.settingsArtLabel
    local artHit = frame.settingsArtLabelHit
    if artLabel and artHit and artLabel.GetStringWidth then
        local width = artLabel:GetStringWidth()
        local height = artLabel.GetStringHeight and artLabel:GetStringHeight()
        if width and width > 1 then
            artHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            artHit:SetHeight(height)
        end
    end

    local arrowCheck = frame.settingsArrowCheck
    if arrowCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        arrowCheck:SetChecked(settings and settings.hideUpgradeArrows and true or false)
    end
    local arrowLabel = frame.settingsArrowLabel
    local arrowHit = frame.settingsArrowLabelHit
    if arrowLabel and arrowHit and arrowLabel.GetStringWidth then
        local width = arrowLabel:GetStringWidth()
        local height = arrowLabel.GetStringHeight and arrowLabel:GetStringHeight()
        if width and width > 1 then
            arrowHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            arrowHit:SetHeight(height)
        end
    end

    local guideCheck = frame.settingsGuideCheck
    if guideCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        guideCheck:SetChecked(settings and settings.hideGuideArrow and true or false)
    end
    local guideLabel = frame.settingsGuideLabel
    local guideHit = frame.settingsGuideLabelHit
    if guideLabel and guideHit and guideLabel.GetStringWidth then
        local width = guideLabel:GetStringWidth()
        local height = guideLabel.GetStringHeight and guideLabel:GetStringHeight()
        if width and width > 1 then
            guideHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            guideHit:SetHeight(height)
        end
    end

    local toastCheck = frame.settingsToastCheck
    if toastCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        toastCheck:SetChecked(settings and settings.hideObtainToast and true or false)
    end
    local toastLabel = frame.settingsToastLabel
    local toastHit = frame.settingsToastLabelHit
    if toastLabel and toastHit and toastLabel.GetStringWidth then
        local width = toastLabel:GetStringWidth()
        local height = toastLabel.GetStringHeight and toastLabel:GetStringHeight()
        if width and width > 1 then
            toastHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            toastHit:SetHeight(height)
        end
    end

    local enchantCheck = frame.settingsEnchantCheck
    if enchantCheck then
        local settings = GearQuestForeverDB and GearQuestForeverDB.settings
        enchantCheck:SetChecked(settings and settings.showGearEnchant and true or false)
    end
    local enchantLabel = frame.settingsEnchantLabel
    local enchantHit = frame.settingsEnchantLabelHit
    if enchantLabel and enchantHit and enchantLabel.GetStringWidth then
        local width = enchantLabel:GetStringWidth()
        local height = enchantLabel.GetStringHeight and enchantLabel:GetStringHeight()
        if width and width > 1 then
            enchantHit:SetWidth(width + 4)
        end
        if height and height > 1 then
            enchantHit:SetHeight(height)
        end
    end
end

function GQ.Log:SeedSimulatorFromCharacter()
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return
    end
    self.simClass = GQ:GetEffectiveClass()
    self.simFaction = GQ:GetEffectiveFaction() or "Alliance"
    if GQ.Spec and GQ.Spec.GetDisplaySpec then
        self.simSpec = GQ.Spec:GetDisplaySpec(self.simClass)
    end
    if self.frame and self.frame.simLevelEdit and not (self.frame.simLevelEdit.HasFocus and self.frame.simLevelEdit:HasFocus()) then
        self.frame.simLevelEdit:SetText(tostring(GQ:GetEffectiveLevel() or 1))
    end
end

function GQ.Log:SelectSimulatorClass(classFile)
    self.simClass = classFile
    if GQ.Spec then
        local options = GQ.Spec:GetOptions(classFile) or {}
        local stillValid = false
        for _, opt in ipairs(options) do
            if opt.id == self.simSpec and GQ.Spec:IsSpecSelectable(opt.id, classFile) then
                stillValid = true
                break
            end
        end
        if not stillValid then
            local ownClass = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
            local previewOn = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
            if not previewOn and classFile == ownClass and GQ.Spec.GetDisplaySpec then
                self.simSpec = GQ.Spec:GetDisplaySpec(classFile)
            else
                self.simSpec = GQ.Spec:GetSavedSpec(classFile) or GQ.Spec:GetDefaultSpec(classFile)
            end
        end
    end
    self:RefreshSimulator()
end

function GQ.Log:SetSimulatorChoiceHighlight(btn, selected, moteScale)
    if not btn then
        return
    end
    btn:SetEnabled(true)
    local border = btn.gqChoiceBorder
    if not border then
        border = CreateFrame("Frame", nil, btn)
        border:SetPoint("TOPLEFT", btn, "TOPLEFT", -4, 4)
        border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, -4)
        border:EnableMouse(false)
        border:SetFrameLevel((btn:GetFrameLevel() or 1) + 6)

        local function rim(r, g, b, a1, a2, thickness, horizontal)
            local tex = border:CreateTexture(nil, "ARTWORK", nil, 1)
            tex:SetColorTexture(r, g, b, 1)
            tex:SetPoint(a1, border, a1, 0, 0)
            tex:SetPoint(a2, border, a2, 0, 0)
            if horizontal then
                tex:SetHeight(thickness)
            else
                tex:SetWidth(thickness)
            end
        end
        rim(1, 0.84, 0.1, "TOPLEFT", "TOPRIGHT", 3, true)
        rim(1, 0.7, 0.05, "BOTTOMLEFT", "BOTTOMRIGHT", 3, true)
        rim(1, 0.8, 0.08, "TOPLEFT", "BOTTOMLEFT", 3, false)
        rim(1, 0.74, 0.06, "TOPRIGHT", "BOTTOMRIGHT", 3, false)

        local motes = {}
        local moteCount = 28
        local scale = moteScale or 1
        for i = 1, moteCount do
            local mote = border:CreateTexture(nil, "OVERLAY", nil, 7)
            mote:SetTexture("Interface\\Minimap\\Ping\\ping4")
            mote:SetBlendMode("ADD")
            local size = (4 + (i % 3)) * scale
            if i % 7 == 0 then
                size = size + scale
            end
            if size < 1 then
                size = 1
            end
            mote:SetSize(size, size)
            mote:SetVertexColor(1, 0.9, 0.35)
            mote.gqOffset = (i - 1) / moteCount
            mote.gqRadius = (i % 2 == 0) and 1 or 0.9
            mote.gqSpeed = (i % 2 == 0) and (1 / 9) or (1 / 13)
            mote.gqAlpha = 0.85 + ((i % 4) * 0.05)
            motes[i] = mote
        end
        border.gqSparks = motes

        border:SetScript("OnUpdate", function(self, elapsed)
            elapsed = elapsed or 0
            self.gqPhase = (self.gqPhase or 0) + elapsed
            local w = self:GetWidth()
            local h = self:GetHeight()
            if not w or not h or w < 4 or h < 4 then
                return
            end
            local cx = w * 0.5
            local cy = h * 0.5
            local rx = w * 0.5
            local ry = h * 0.5
            for i = 1, #self.gqSparks do
                local mote = self.gqSparks[i]
                local travel = (mote.gqOffset + (self.gqPhase * mote.gqSpeed)) % 1
                local turn = travel * math.pi * 2
                local breathe = 1 + (0.06 * math.sin((self.gqPhase * 1.3) + (i * 0.7)))
                local reach = mote.gqRadius * breathe
                local x = cx + (rx * reach * math.sin(turn))
                local y = cy + (ry * reach * math.cos(turn))
                mote:ClearAllPoints()
                mote:SetPoint("CENTER", self, "BOTTOMLEFT", x, y)
                mote:SetAlpha(mote.gqAlpha * (0.92 + (0.08 * math.sin((self.gqPhase * 0.8) + i))))
            end
        end)
        btn.gqChoiceBorder = border
    end
    if selected then
        border:Show()
    else
        border:Hide()
    end
end

function GQ.Log:RefreshSimulator()
    if not self.frame or not self.frame.simClassButtons then
        return
    end

    if not self.simClass then
        self.simClass = GQ:GetEffectiveClass()
    end
    if not self.simFaction then
        self.simFaction = GQ:GetEffectiveFaction() or "Alliance"
    end
    if self.frame.simLevelEdit then
        local focused = false
        if self.frame.simLevelEdit.HasFocus then
            focused = self.frame.simLevelEdit:HasFocus()
        end
        local text = self.frame.simLevelEdit:GetText() or ""
        if not focused and text == "" then
            self.frame.simLevelEdit:SetText(tostring(GQ:GetEffectiveLevel() or 1))
        end
    end

    for _, btn in ipairs(self.frame.simClassButtons) do
        local selected = btn.classFile == self.simClass
        btn.selected = selected
        if selected then
            local art = btn.scene and btn.scene:IsShown()
            btn.highlight:SetAlpha(art and 0.22 or 0.55)
            btn.highlight:Show()
        else
            btn.highlight:Hide()
        end
    end

    if self.frame.simAllianceBtn then
        self:SetSimulatorChoiceHighlight(self.frame.simAllianceBtn, self.simFaction == "Alliance")
        self:SetSimulatorChoiceHighlight(self.frame.simHordeBtn, self.simFaction == "Horde")
    end

    local level = tonumber(self.frame.simLevelEdit and self.frame.simLevelEdit:GetText()) or GQ:GetEffectiveLevel() or 1
    local specOptions = {}
    if GQ.Spec and GQ.Spec.GetOptions then
        for _, opt in ipairs(GQ.Spec:GetOptions(self.simClass) or {}) do
            if GQ.Spec:IsSpecSelectable(opt.id, self.simClass) then
                specOptions[#specOptions + 1] = opt
            end
        end
    end

    local specValid = false
    for _, opt in ipairs(specOptions) do
        if opt.id == self.simSpec then
            specValid = true
            break
        end
    end
    if not specValid then
        local ownClass = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
        local previewOn = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
        local picked = nil
        if not previewOn and self.simClass == ownClass and GQ.Spec.GetDisplaySpec then
            picked = GQ.Spec:GetDisplaySpec(self.simClass)
        elseif GQ.Spec.GetSavedSpec then
            picked = GQ.Spec:GetSavedSpec(self.simClass)
        end
        local pickedOk = false
        if picked then
            for _, opt in ipairs(specOptions) do
                if opt.id == picked then
                    pickedOk = true
                    break
                end
            end
        end
        self.simSpec = pickedOk and picked or (specOptions[1] and specOptions[1].id or nil)
    end

    if self.frame.simSpecHeader then
        if #specOptions > 0 then
            self.frame.simSpecHeader:Show()
        else
            self.frame.simSpecHeader:Hide()
        end
    end

    for i, specBtn in ipairs(self.frame.simSpecButtons) do
        local opt = specOptions[i]
        if opt then
            specBtn:Show()
            specBtn.specLabel = opt.label
            specBtn:SetText(opt.label)
            specBtn.specId = opt.id
            self:SetSimulatorChoiceHighlight(specBtn, self.simSpec == opt.id)
        else
            specBtn:Hide()
            specBtn.specLabel = nil
            specBtn.specId = nil
        end
    end

    local className = (GQ.Preview and GQ.Preview.FormatClassName and GQ.Preview:FormatClassName(self.simClass)) or self.simClass
    local specLabel = ""
    if self.simSpec and GQ.Spec then
        for _, opt in ipairs(specOptions) do
            if opt.id == self.simSpec then
                specLabel = ", " .. opt.label
                break
            end
        end
    end

    local viewing = string.format(
        "Simulate a level %s %s %s%s, then click Simulate to apply and open the log.",
        tostring(level),
        self.simFaction or "Alliance",
        className,
        specLabel
    )
    if self.frame.simStatus then
        self.frame.simStatus:SetText(viewing)
    end

    self:UpdateSimulatorResetButton()
    self:LayoutSimulatorContent(self.frame)
end

function GQ.Log:UpdateSimulatorResetButton()
    local frame = self.frame
    local btn = frame and frame.simResetBtn
    if not btn then
        return
    end
    local simulated = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    btn:SetEnabled(simulated and true or false)
    local hover = frame.simResetHover
    if not hover then
        return
    end
    if simulated then
        hover:Hide()
        if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == hover then
            GameTooltip:Hide()
        end
    else
        hover:Show()
    end
end

function GQ.Log:ApplySimulator()
    if not GQ.Preview then
        return
    end

    local levelText = ""
    if self.frame.simLevelEdit and GQ.Preview.SanitizeLevelEdit then
        levelText = GQ.Preview:SanitizeLevelEdit(self.frame.simLevelEdit)
    elseif self.frame.simLevelEdit then
        levelText = tostring(self.frame.simLevelEdit:GetText() or ""):gsub("%D", "")
    end
    if levelText == "" then
        GQ:Chat(string.format("|cff66ccffGearQuest|r: Enter a level between 1 and %d.", GQ.MAX_PLAYER_LEVEL or 60))
        return
    end

    local ok, err = GQ.Preview:ApplySimulation(self.simClass, levelText, self.simSpec, self.simFaction)
    if not ok then
        GQ:Chat("|cff66ccffGearQuest|r: " .. (err or "Could not simulate."))
        return
    end

    self:SetPageTab("log")
end

function GQ.Log:ResetSimulator()
    if not GQ.Preview then
        return
    end
    GQ.Preview:ApplyCurrentCharacter()
    GQ.Preview:SetEnabled(false)
    GQ.Preview:PrintNowViewing()
    self.simClass = GQ:GetEffectiveClass()
    self.simFaction = GQ:GetEffectiveFaction()
    self.simSpec = (GQ.Spec and GQ.Spec.GetDisplaySpec and GQ.Spec:GetDisplaySpec())
        or (GQ.Spec and GQ.Spec:GetEffectiveSpec())
        or nil
    if self.frame and self.frame.simLevelEdit then
        self.frame.simLevelEdit:SetText(tostring(GQ:GetEffectiveLevel() or 1))
    end
    if GQ.RefreshUI then
        GQ:RefreshUI()
    end
    self:RefreshSimulator()
    self:SetPageTab("log")
end

function GQ.Log:WireControls(frame)
    frame.trackBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:DismissTrackIntro()
        end
        if not log or not log.selectedHuntId and log:GetPageTab() ~= "lookup" then
            return
        end
        local huntId = log.selectedHuntId
        if log:GetPageTab() == "lookup" then
            huntId = log.lookupEntry and log.lookupEntry.id
        end
        if not huntId then
            return
        end
        local status = GetHuntStatus(huntId)
        local onLookup = log:GetPageTab() == "lookup"
        if (not onLookup and log:GetListTab() == "completed") or status == "tracked" then
            log:RequestUntrackHunt(huntId)
        else
            log:TrackHunt(huntId)
        end
    end)
    frame.trackBtn:SetScript("OnEnter", function(self)
        if self:GetText() ~= "Track" then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Click to track this hunt. The Guide feature can be enabled.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.trackBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.untrackBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.selectedHuntId then
            log:RequestUntrackHunt(log.selectedHuntId)
        end
    end)

    if frame.mapBtn then
        frame.mapBtn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log or not GQ.Map or not GQ.Map.Show then
                return
            end
            local entry = log:GetPageTab() == "lookup" and log.lookupEntry or log.selectedEntry
            if not entry and log:GetPageTab() ~= "lookup" and log.selectedHuntId and GQ.Data and GQ.Data.GetEntryById then
                entry = GQ.Data:GetEntryById(log.selectedHuntId)
            end
            if entry then
                GQ.Map:Show(entry)
            end
        end)
    end

    frame.exitBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:Hide()
        end
    end)
    self:StartTrackIntro(frame.trackBtn)
end

function GQ.Log:BindExistingFrame(frame)
    self.frame = frame
    ApplyLogWindowLayer(frame)
    ApplyModernChrome(frame)
    WireLogWindowMouseWheel(frame)
    self.listRows = {}
    self.selectedHuntId = nil
    self.selectedEntry = nil
    frame.scroll = frame.scroll or _G.GearQuestLogListScrollFrame
    frame.scrollChild = frame.scrollChild or _G.GearQuestLogListScrollChild
    frame.detailScroll = frame.detailScroll or _G.GearQuestLogDetailScrollFrame
    frame.detailChild = frame.detailChild or _G.GearQuestLogDetailScrollChild
    frame.listInset = frame.listInset or frame
    self:EnsureTabBar(frame)
    self:EnsureDetailLore(frame)
    self:EnsureDetailReward(frame)
    LayoutDetailScroll(frame)
    if frame.trackBtn and frame.untrackBtn and frame.exitBtn then
        self:WireControls(frame)
    end
    self:EnsureTrackerEvents()
end

function GQ.Log:SyncCompletedItemBackup()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    local settings = GearQuestForeverDB.settings
    local backup = settings.completedItemBackup or {}
    local wipedAt = settings.completedWipeAt or 0

    for itemId, when in pairs(backup) do
        if (when or 0) > wipedAt and not GearQuestForeverDB.obtainedItems[itemId]
            and not (GearQuestForeverDB.dismissedItems and GearQuestForeverDB.dismissedItems[itemId]) then
            GearQuestForeverDB.obtainedItems[itemId] = when
        end
    end

    for itemId, when in pairs(GearQuestForeverDB.obtainedItems) do
        if (when or 0) > wipedAt then
            local prev = backup[itemId]
            if not prev or prev < when then
                backup[itemId] = when
            end
        end
    end

    settings.completedItemBackup = backup
end

function GQ.Log:RestoreLostCompletedProgress()
    -- This character's completed hunts were cleared while settings were kept.
    -- Put the two pieces back once. Other characters are left alone.
    local guid = UnitGUID and UnitGUID("player")
    if guid ~= "Player-4613-00530DE6" then
        local saved = GearQuestForeverDB.settings and GearQuestForeverDB.settings.preview
        guid = saved and saved.loginCharacterKey
    end
    if guid ~= "Player-4613-00530DE6" then
        return
    end

    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    if GearQuestForeverDB.settings.restoredLostCompleted then
        return
    end
    GearQuestForeverDB.settings.restoredLostCompleted = true

    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    local lost = {
        ["252495"] = 1790113531,
        ["263412"] = 1790106509,
    }
    for itemId, when in pairs(lost) do
        if not GearQuestForeverDB.obtainedItems[itemId] then
            GearQuestForeverDB.obtainedItems[itemId] = when
        end
    end

    local crafted = {
        [2287] = 1790107045, [5030] = 1790106679, [2319] = 1790113806,
        [253710] = 1790108331, [11227] = 1790109830, [2934] = 1790106984,
        [1499] = 1790107078, [1503] = 1790109472, [858] = 1790106679,
        [276070] = 1790107809, [2313] = 1790114014, [2455] = 1790109493,
        [2589] = 1790106679, [5115] = 1790110140, [2881] = 1790106809,
        [17056] = 1790109771, [5574] = 1790109472, [5023] = 1790106914,
        [248706] = 1790109494, [5025] = 1790109422, [2592] = 1790110202,
        [3301] = 1790109988, [4239] = 1790112772, [252495] = 1790113512,
        [4233] = 1790114076, [3299] = 1790106809, [4246] = 1790112894,
        [2778] = 1790106774, [2318] = 1790106814, [14119] = 1790110285,
        [5065] = 1790110140, [1502] = 1790107045, [248687] = 1790107738,
    }
    for itemId, when in pairs(crafted) do
        if not GearQuestForeverDB.crafted[itemId] then
            GearQuestForeverDB.crafted[itemId] = when
        end
    end
end

function GQ.Log:MigrateObtainedRecords()
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
    GearQuestForeverDB.dismissedItems = GearQuestForeverDB.dismissedItems or {}

    self:RestoreLostCompletedProgress()
    self:SyncCompletedItemBackup()

    for id, record in pairs(GearQuestForeverDB.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed" and not GearQuestForeverDB.obtained[id] then
            GearQuestForeverDB.obtained[id] = record.completedAt or record.trackedAt or time()
        end
    end

    for id, obtainedAt in pairs(GearQuestForeverDB.obtained) do
        local entry = GQ.Data:GetEntryById(id)
        if entry and entry.itemId then
            local key = tostring(entry.itemId)
            if not GearQuestForeverDB.obtainedItems[key] then
                GearQuestForeverDB.obtainedItems[key] = obtainedAt
            end
        end
        if entry and entry.sourceType == "profession" and entry.itemId and not GearQuestForeverDB.crafted[entry.itemId] then
            GearQuestForeverDB.crafted[entry.itemId] = obtainedAt
        end
    end
end

function GQ.Log:Init()
    self.obtainToastsEnabled = false
    self:MigrateObtainedRecords()
    self:BeginLoginObtainScan()

    if self.frame then
        return
    end

    self:EnsureItemInfoListener()

    if _G.GearQuestLogFrame then
        self:BindExistingFrame(_G.GearQuestLogFrame)
        return
    end

    local ok, frame = pcall(CreateFrame, "Frame", "GearQuestLogFrame", UIParent, "PortraitFrameTemplate")
    if not ok or not frame then
        frame = CreateFrame("Frame", "GearQuestLogFrame", UIParent)
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 32,
                edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
        end
        CreateFrame("Button", nil, frame, "UIPanelCloseButton"):SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, 1)
    end

    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end
    self.frame = frame
    self:ApplyWindowScale()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        BringLogWindowToFront(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function(self)
        BringLogWindowToFront(self)
    end)
    frame:HookScript("OnMouseDown", function(self)
        BringLogWindowToFront(self)
    end)
    WireLogWindowMouseWheel(frame)
    ApplyLogWindowLayer(frame)
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    SetFrameTitle(frame, GearQuestWindowTitle())
    ApplyModernChrome(frame)
    self.frame = frame
    self:EnsureLogPages(frame)

    frame.listInset = CreateFrame("Frame", nil, frame.logPage)
    frame.listInset:SetSize(LEFT_COLUMN_WIDTH, 200)
    ApplyBlackBackground(frame.listInset)
    ApplyMetalEdge(frame.listInset, 12)

    frame.scroll = CreatePanelScrollFrame("GearQuestLogListScrollFrame", frame.listInset)
    frame.scroll:SetPoint("TOPLEFT", frame.listInset, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame.listInset, "BOTTOMRIGHT", -PANEL_INSET, PANEL_INSET)

    frame.scrollChild = CreateFrame("Frame", "GearQuestLogListScrollChild", frame.scroll)
    frame.scrollChild:SetWidth(LEFT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET)
    frame.scrollChild:SetHeight(1)
    frame.scroll:SetScrollChild(frame.scrollChild)
    -- Do not clip this frame. The scrollbar is a child drawn just outside
    -- the scroll rect, and SetClipsChildren hides it. The scroll child is
    -- already clipped by the ScrollFrame.
    frame.scrollChild:EnableMouse(false)

    frame.listGutter = CreateFrame("Frame", nil, frame)
    frame.listGutter:Hide()

    frame.sectionDivider = CreateSectionDivider(frame)
    frame.sectionDivider:Hide()

    frame.detailBg = CreateFrame("Frame", nil, frame.logPage)
    EnableClipping(frame.detailBg)
    ApplyParchmentBackground(frame.detailBg)
    ApplyMetalEdge(frame.detailBg, 12)

    frame.detailScroll = CreatePanelScrollFrame("GearQuestLogDetailScrollFrame", frame)
    LayoutDetailScroll(frame)

    frame.detailChild = CreateFrame("Frame", "GearQuestLogDetailScrollChild", frame.detailScroll)
    frame.detailChild:SetWidth(RIGHT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8)
    frame.detailScroll:SetScrollChild(frame.detailChild)
    frame.detailChild:EnableMouse(false)

    frame.detailGutter = CreateFrame("Frame", nil, frame)
    frame.detailGutter:Hide()

    ConfigurePanelScrollBar(frame.scroll)
    local listBar = _G[frame.scroll:GetName() .. "ScrollBar"]
    if listBar and listBar.HookScript then
        listBar:HookScript("OnValueChanged", function()
            if GQ.Log and GQ.Log.ClampListRowMouse then
                GQ.Log:ClampListRowMouse()
            end
        end)
    end

    frame.detailTitle = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_TITLE_FONTS)
    frame.detailTitle:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
    frame.detailTitle:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailTitle:SetJustifyH("LEFT")
    frame.detailTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailTitle:Hide()

    frame.detailRankBox = CreateFrame("Frame", nil, frame.detailChild)
    frame.detailRankBox:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
    frame.detailRankBox:SetFrameLevel((frame.detailChild:GetFrameLevel() or 1) + 2)
    frame.detailRankBox:Hide()
    local rankBg = frame.detailRankBox:CreateTexture(nil, "BACKGROUND")
    rankBg:SetAllPoints()
    rankBg:SetColorTexture(0, 0, 0, 1)
    frame.detailRankBox.bg = rankBg
    frame.detailRankBox.text = CreateFontStringWithFallback(frame.detailRankBox, {
        "GameFontHighlight", "GameFontNormal", "QuestFont",
    })
    frame.detailRankBox.text:SetPoint("LEFT", frame.detailRankBox, "LEFT", 8, 0)
    frame.detailRankBox.text:SetJustifyH("LEFT")
    frame.detailRankBox.text:SetJustifyV("MIDDLE")
    frame.detailRankBox.text:SetTextColor(1, 1, 1)
    frame.detailRankBox.text:SetWordWrap(false)
    frame.detailRankBox:EnableMouse(true)
    frame.detailRankBox:SetScript("OnEnter", function(self)
        self.gqTipShown = true
        GQ.Log:ShowRankBoxTooltip(self)
    end)
    frame.detailRankBox:SetScript("OnLeave", function(self)
        self.gqTipShown = false
        GameTooltip:Hide()
    end)
    -- The parchment sits in a scroll child, which often never sends OnEnter.
    frame.detailRankBox:SetScript("OnUpdate", function(self)
        if not self:IsShown() then
            return
        end
        if self:IsMouseOver() then
            if not self.gqTipShown then
                self.gqTipShown = true
                GQ.Log:ShowRankBoxTooltip(self)
            end
        elseif self.gqTipShown then
            self.gqTipShown = false
            local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
            if owner == self then
                GameTooltip:Hide()
            end
        end
    end)

    frame.detailLore = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailLore:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -8)
    frame.detailLore:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailLore:SetJustifyH("LEFT")
    frame.detailLore:SetWordWrap(true)
    frame.detailLore:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailLore:Hide()

    frame.detailHeader = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_HEADER_FONTS)
    frame.detailHeader:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -16)
    frame.detailHeader:SetText("DESCRIPTION")
    frame.detailHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailHeader:Hide()

    frame.detailBody = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailBody:SetPoint("TOPLEFT", frame.detailHeader, "BOTTOMLEFT", 0, -8)
    frame.detailBody:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailBody:SetJustifyH("LEFT")
    frame.detailBody:SetWordWrap(true)
    frame.detailBody:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailBody:Hide()

    frame.detailCoords = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailCoords:SetPoint("TOPLEFT", frame.detailBody, "BOTTOMLEFT", 0, -16)
    frame.detailCoords:SetJustifyH("LEFT")
    frame.detailCoords:SetWordWrap(true)
    frame.detailCoords:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailCoords:Hide()

    frame.detailCoordsProbe = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailCoordsProbe:Hide()

    frame.detailCoordsInfo = CreateFrame("Button", nil, frame.detailChild)
    frame.detailCoordsInfo:SetSize(17, 17)
    frame.detailCoordsInfo:Hide()
    local coordInfoShade = frame.detailCoordsInfo:CreateTexture(nil, "BACKGROUND")
    coordInfoShade:SetSize(17, 17)
    coordInfoShade:SetPoint("CENTER", 0, -1)
    coordInfoShade:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    coordInfoShade:SetVertexColor(0.08, 0.05, 0.02, 0.92)
    local coordInfoTex = frame.detailCoordsInfo:CreateTexture(nil, "OVERLAY")
    coordInfoTex:SetSize(13, 13)
    coordInfoTex:SetPoint("CENTER")
    coordInfoTex:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    frame.detailCoordsInfo:SetScript("OnUpdate", function(self)
        if not self:IsShown() then
            return
        end
        if self:IsMouseOver() then
            if not self.gqTipShown then
                self.gqTipShown = true
                GQ.Log:ShowCoordinateTooltip(self)
            end
        elseif self.gqTipShown then
            self.gqTipShown = false
            local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
            if owner == self then
                GameTooltip:Hide()
            end
        end
    end)

    frame.detailDone = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailDone:SetJustifyH("LEFT")
    frame.detailDone:SetWordWrap(true)
    frame.detailDone:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailDone:Hide()

    self:EnsureDetailLore(frame)
    self:EnsureDetailReward(frame)

    frame.detailEmpty = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailEmpty:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
    frame.detailEmpty:SetText("Select an upgrade to see how to get it.")
    frame.detailEmpty:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailEmpty:Show()

    frame.trackBtn = CreateFrame("Button", "GearQuestLogTrackButton", frame.detailBg, "UIPanelButtonTemplate")
    frame.trackBtn:SetSize(106, 22)
    frame.trackBtn:SetText("Track")

    frame.untrackBtn = CreateFrame("Button", "GearQuestLogUntrackButton", frame, "UIPanelButtonTemplate")
    frame.untrackBtn:SetSize(106, 22)
    frame.untrackBtn:SetText("Untrack")
    frame.untrackBtn:Hide()

    frame.mapBtn = CreateFrame("Button", "GearQuestLogMapButton", frame.detailBg, "UIPanelButtonTemplate")
    frame.mapBtn:SetSize(120, 22)
    frame.mapBtn:SetText("Show on map")
    if frame.mapBtn.SetMotionScriptsWhileDisabled then
        frame.mapBtn:SetMotionScriptsWhileDisabled(true)
    end
    frame.mapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if self.missingCoords then
            GameTooltip:SetText("We are missing exact coordinates for this item.", 1, 1, 1, 1, true)
        else
            GameTooltip:SetText("See where you can find this on the world map, and let the guide show directions.", 1, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    frame.mapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.exitBtn = CreateFrame("Button", "GearQuestLogExitButton", frame, "UIPanelButtonTemplate")
    frame.exitBtn:SetSize(106, 22)
    frame.exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, FOOTER_BUTTON_Y)
    frame.exitBtn:SetText("Exit")

    self:EnsurePlayStyle(frame)

    self:WireControls(frame)
    self:EnsureTrackerEvents()
    self:EnsureTabBar(frame)

    self.listRows = {}
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
end

function GQ.Log:SetDetailEmpty(empty)
    if not self.frame then
        return
    end

    if empty then
        self.frame.detailEmpty:Show()
        self.frame.detailHeader:Hide()
        self.frame.detailTitle:Hide()
        if self.frame.detailRankBox then
            self.frame.detailRankBox:Hide()
        end
        if self.frame.detailLore then
            self.frame.detailLore:Hide()
        end
        self.frame.detailBody:Hide()
        if self.frame.detailCoords then
            self.frame.detailCoords:Hide()
        end
        if self.frame.detailCoordsInfo then
            self.frame.detailCoordsInfo:Hide()
        end
        if self.frame.detailDone then
            self.frame.detailDone:Hide()
        end
        if self.frame.detailRewardHeader then
            self.frame.detailRewardHeader:Hide()
        end
        if self.frame.detailRewardIcon then
            self.frame.detailRewardIcon:Hide()
        end
    else
        self.frame.detailEmpty:Hide()
        self.frame.detailHeader:Show()
        self.frame.detailTitle:Show()
        self.frame.detailBody:Show()
    end
end

function GQ.Log:ClearDetail()
    if not self.frame then
        return
    end
    self.frame.detailTitle:SetText("")
    if self.frame.detailRankBox then
        self.frame.detailRankBox:Hide()
    end
    self.frame.detailBody:SetText("")
    if self.frame.detailCoords then
        self.frame.detailCoords:SetText("")
        self.frame.detailCoords:Hide()
    end
    if self.frame.detailCoordsInfo then
        self.frame.detailCoordsInfo:Hide()
        self.frame.detailCoordsInfo.spots = nil
    end
    if self.frame.detailDone then
        self.frame.detailDone:SetText("")
        self.frame.detailDone:Hide()
    end
    if self.frame.detailLore then
        self.frame.detailLore:SetText("")
        self.frame.detailLore:Hide()
    end
    self:UpdateDetailReward(nil)
    self:SetDetailEmpty(true)
end

function GQ.Log:RankOneEntry(slotName, handKind)
    -- First piece this character can see. A rank stored for the other
    -- faction is already absent, so the list's first row is rank 1.
    -- A weapon filter hides rows. It does not give the next weapon that number.
    if slotName == "MainHand" and self:IsWeaponHandKind(handKind) then
        local weapons = self:UnfilteredWeaponList()
        return weapons and weapons[1] or nil
    end
    local list = self:GetSlotRankList(slotName, handKind)
    return list and list[1] or nil
end

function GQ.Log:PlayerOwnsRankOne(entry)
    if not entry then
        return false
    end
    if self:IsEntryObtained(entry.id) then
        return true
    end
    if not entry.itemId or not GetInventoryItemLink or not GQ.Data or not GQ.Data.GetInventorySlots then
        return false
    end
    local slotName = entry.slot
    local slots = GQ.Data:GetInventorySlots(slotName) or {}
    for i = 1, #slots do
        local link = GetInventoryItemLink("player", slots[i])
        if link and GQ.Data:ItemLinkToId(link) == entry.itemId then
            if not entry.suffix or entry.suffix == "" or GQ.Data:EntrySuffixMatchesLink(entry, link) then
                return true
            end
        end
    end
    return false
end

function GQ.Log:UpdateHuntAdvice(layoutRows, tab)
    self._rankOneOwned = {}
    self._recommendKeys = nil
    if not layoutRows then
        return
    end
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return
    end
    local wantRecommend = tab == "active"
        and GQ.Data and GQ.Data.GearScoreTooltipEnabled and GQ.Data:GearScoreTooltipEnabled()
    local picks = {}
    for i = 1, #layoutRows do
        local spec = layoutRows[i]
        if spec.type == "header" and spec.slotName then
            local rankOne = self:RankOneEntry(spec.slotName, spec.handKind)
            if rankOne then
                local key = tostring(spec.slotName) .. ":" .. tostring(spec.handKind)
                local weaponHeader = self:IsWeaponHandKind(spec.handKind)
                local rankOneVisible = true
                if weaponHeader then
                    rankOneVisible = self:WeaponPassesFilter(rankOne)
                end
                if rankOneVisible and self:PlayerOwnsRankOne(rankOne) then
                    self._rankOneOwned[key] = true
                elseif wantRecommend then
                    local dataSlot = spec.slotName == "WeaponPair" and "MainHand" or spec.slotName
                    local shown
                    if weaponHeader then
                        shown = self:WeaponShownInHunt(rankOne)
                    else
                        shown = self:EntryShownOnActiveList(rankOne, dataSlot)
                    end
                    if shown
                        and (not spec.handKind or self:EntryInWeaponHand(rankOne, dataSlot, spec.handKind)) then
                        local delta, filled = nil, false
                        if GQ.Data.GearScoreUpgradeDelta then
                            -- The upgrade is raw score versus what is worn. The weapon
                            -- filter does not shrink that comparison.
                            local deltaHand = weaponHeader and nil or spec.handKind
                            delta, filled = GQ.Data:GearScoreUpgradeDelta(rankOne, spec.slotName, deltaHand)
                        end
                        if delta and delta > 0 then
                            picks[#picks + 1] = { entry = rankOne, delta = delta, order = #picks, filled = filled }
                        end
                    end
                end
            end
        end
    end
    if #picks == 0 then
        return
    end
    local bestFilled
    for i = 1, #picks do
        local pick = picks[i]
        if pick.filled and (not bestFilled or pick.delta > bestFilled) then
            bestFilled = pick.delta
        end
    end
    if bestFilled then
        local kept = {}
        for i = 1, #picks do
            local pick = picks[i]
            if pick.filled or pick.delta > bestFilled then
                kept[#kept + 1] = pick
            end
        end
        picks = kept
    end
    if #picks == 0 then
        return
    end
    table.sort(picks, function(a, b)
        if a.delta ~= b.delta then
            return a.delta > b.delta
        end
        return a.order < b.order
    end)
    local keys = {}
    local limit = #picks
    if limit > 3 then
        limit = 3
    end
    for i = 1, limit do
        local entry = picks[i].entry
        if entry.id then
            keys[entry.id] = true
        end
        keys[tostring(entry.itemId or 0) .. "\0" .. (entry.suffix or "")] = true
    end
    self._recommendKeys = keys
end

function GQ.Log:EntryIsRecommended(entry)
    local keys = self._recommendKeys
    if not entry or not keys then
        return false
    end
    if entry.id and keys[entry.id] then
        return true
    end
    return keys[tostring(entry.itemId or 0) .. "\0" .. (entry.suffix or "")] == true
end

function GQ.Log:EnsureAcquiredLabel(row)
    if row.acquired then
        return row.acquired
    end
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText("- Rank #1 BiS acquired")
    label:SetTextColor(1, 1, 1)
    label:Hide()
    row.acquired = label
    return label
end

function GQ.Log:EnsureRecommendWidgets(row)
    if row.recommend then
        return
    end
    local info = CreateFrame("Button", nil, row)
    info:SetSize(13, 13)
    info:SetFrameLevel(row:GetFrameLevel() + 6)
    info.icon = info:CreateTexture(nil, "OVERLAY")
    info.icon:SetAllPoints()
    info.icon:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    info:SetScript("OnEnter", function(self)
        HideItemTooltip()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("GearQuest Recommends", 1, 0.82, 0)
        GameTooltip:AddLine("One of the best upgrades for your level. GearQuest marks up to three rank #1 pieces, the ones that improve what you are wearing the most.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    info:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    info:SetScript("OnClick", function() end)
    info:EnableMouseWheel(true)
    info:SetScript("OnMouseWheel", function(_, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.frame and log.frame.scroll then
            ScrollFrameOnMouseWheel(log.frame.scroll, delta)
        end
    end)
    info:Hide()
    row.recommendInfo = info

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText("Recommended")
    label:SetTextColor(1, 0.82, 0)
    label:Hide()
    row.recommend = label
end

function GQ.Log:HideHuntAdvice(row)
    if row.acquired then
        row.acquired:Hide()
    end
    if row.recommend then
        row.recommend:Hide()
    end
    if row.recommendInfo then
        row.recommendInfo:Hide()
    end
end

function GQ.Log:RecommendTailWidth(row, entry)
    if not self:EntryIsRecommended(entry) then
        return 0
    end
    self:EnsureRecommendWidgets(row)
    local label = row.recommend
    label:SetText("Recommended")
    label:SetJustifyH("LEFT")
    local labelWidth = label:GetStringWidth() or 0
    if labelWidth < 20 then
        labelWidth = 100
    end
    return labelWidth + 13 + 10
end

function GQ.Log:PlaceRecommend(row)
    local label = row.recommend
    local info = row.recommendInfo
    if not label or not info then
        return
    end
    local textWidth = row.text:GetStringWidth() or 0
    local nameLeft = row._huntNameLeft or 0
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", row, "TOPLEFT", nameLeft + textWidth + 6, -1)
    info:ClearAllPoints()
    info:SetPoint("LEFT", label, "RIGHT", 2, 0)
    label:Show()
    info:Show()
end

function GQ.Log:RankMarkWidth()
    if self._rankMarkWidth then
        return self._rankMarkWidth
    end
    local probe = self._rankProbe
    if not probe then
        probe = UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        probe:SetWordWrap(false)
        probe:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -40)
        probe:Hide()
        self._rankProbe = probe
    end
    probe:Show()
    probe:SetWidth(0)
    probe:SetText("#99")
    local width = probe:GetStringWidth() or 0
    if width < 8 then
        probe:SetWidth(64)
        width = probe:GetStringWidth() or 0
    end
    probe:Hide()
    probe:SetText("")
    width = math.ceil(width + 1)
    if width < 24 then
        width = 24
    end
    self._rankMarkWidth = width
    return width
end

function GQ.Log:PlaceHuntItemIcon(row, itemId, left)
    local icon = row and row.itemIcon
    left = left or LIST_ROW_ITEM_LEFT
    if not icon then
        return left
    end
    local iconSize = self.HUNT_ICON_SIZE or 28
    local gap = 4
    icon:ClearAllPoints()
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("LEFT", row, "LEFT", left, 0)
    icon:SetVertexColor(1, 1, 1)
    local texture = SafeGetItemIcon(itemId)
    if texture then
        icon:SetTexture(texture)
    else
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    icon:Show()
    return left + iconSize + gap
end

function GQ.Log:HuntListRank(entry, slotName, handKind)
    if not entry then
        return nil
    end
    local dataSlot = slotName == "WeaponPair" and "MainHand" or slotName
    if dataSlot == "MainHand" and self:IsWeaponHandKind(handKind) then
        return self:WeaponTrueRank(entry)
    end
    local list = self:GetSlotRankList(dataSlot or slotName, handKind)
    local suffix = entry.suffix or ""
    for i = 1, list and #list or 0 do
        local row = list[i]
        if row == entry or row.id == entry.id
            or (row.itemId == entry.itemId and (row.suffix or "") == suffix) then
            return i
        end
    end
    local display = self:HuntDisplayRank(entry)
    if type(display) == "number" and display >= 1 then
        return display
    end
    if type(entry.curatedRank) == "number" and entry.curatedRank >= 1 then
        return entry.curatedRank
    end
    return nil
end

function GQ.Log:SetHuntNameLine(row, nameLeft, name, r, g, b, reserveRight)
    row._huntNameLeft = nameLeft
    row.text:ClearAllPoints()
    row.text:SetPoint("TOPLEFT", row, "TOPLEFT", nameLeft, -1)
    row.text:SetPoint("TOPRIGHT", row, "TOPRIGHT", -LIST_ROW_RIGHT_PAD, -1)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("MIDDLE")
    row.text:SetWordWrap(false)
    local maxWidth = GetListRowTextMaxWidth(row, nameLeft) - (reserveRight or 0)
    if maxWidth < 20 then
        maxWidth = 20
    end
    TruncateFontStringToWidth(row.text, name, maxWidth)
    row.text:SetTextColor(r, g, b)
end

function GQ.Log:PlaceHuntName(row, nameLeft, name, entry, r, g, b)
    local tail = self:RecommendTailWidth(row, entry)
    self:SetHuntNameLine(row, nameLeft, name, r, g, b, 0)
    if tail <= 0 then
        return
    end
    local rowWidth = row:GetWidth()
    if not rowWidth or rowWidth <= 0 then
        rowWidth = LEFT_COLUMN_WIDTH - (PANEL_INSET * 2)
    end
    local textWidth = row.text:GetStringWidth() or 0
    if nameLeft + textWidth + tail + LIST_ROW_RIGHT_PAD > rowWidth then
        self:SetHuntNameLine(row, nameLeft, name, r, g, b, tail)
    end
    self:PlaceRecommend(row)
end

function GQ.Log:PlaceHuntNotes(row, nameLeft, entry, status, showNewLabel)
    local meta = row.meta
    if not meta then
        return
    end
    local notes = {}
    local timingReady = true
    if showNewLabel and GQ.Data and GQ.Data.PreviousLevelShownKeys then
        timingReady = GQ.Data:PreviousLevelShownKeys() ~= nil
    end
    if timingReady and showNewLabel and entry and GQ.Data:IsEntryNewForPlayer(entry) then
        notes[#notes + 1] = "|cffFFD200New at this level|r"
    elseif timingReady and entry and GQ.Data.EntryListSinceLevel then
        local since = GQ.Data:EntryListSinceLevel(entry)
        if since then
            notes[#notes + 1] = "|cffd0d0d0Since level " .. since .. "|r"
        end
    end
    if entry and entry.setPiece then
        notes[#notes + 1] = "|cff88ccff(Set piece)|r"
    end
    if entry and entry.origin == "guide" then
        notes[#notes + 1] = "|cff88ccff(Guide)|r"
    end
    if status == "tracked" then
        notes[#notes + 1] = "|cff00ff00(Tracked)|r"
    end
    meta:SetFontObject("GameFontHighlightSmall")
    meta:SetJustifyH("LEFT")
    meta:SetJustifyV("MIDDLE")
    meta:SetWordWrap(false)
    meta:SetText(table.concat(notes, "  "))
    meta:SetTextColor(1, 1, 1)
    local nameH = row.text:GetStringHeight() or 12
    local noteH = meta:GetStringHeight() or 10
    if nameH < 8 then
        nameH = 12
    end
    if noteH < 8 then
        noteH = 10
    end
    local rowH = row:GetHeight() or 32
    local tightTop = 1 + nameH - 2
    local lowTop = rowH - 1 - noteH
    local midTop = math.floor((tightTop + lowTop) / 2 + 0.5)
    meta:ClearAllPoints()
    meta:SetPoint("TOPLEFT", row, "TOPLEFT", nameLeft, -midTop)
    meta:SetPoint("TOPRIGHT", row, "TOPRIGHT", -LIST_ROW_RIGHT_PAD, -midTop)
    meta:Show()
end

function GQ.Log:ConfigureRow(row, yOffset, rowType, slotName, entry, label, handKind)
    row:Show()
    local scrollChild = self.frame.scrollChild
    local scroll = self.frame.scroll
    AnchorListRow(row, scrollChild, scroll, yOffset)
    local rowHeight = ROW_HEIGHT
    if rowType == "item" or rowType == "notable" then
        rowHeight = self.ITEM_ROW_HEIGHT or (ROW_HEIGHT * 2)
    end
    row:SetHeight(rowHeight)
    row._listTop = yOffset
    row._listHeight = rowHeight
    row.rowType = rowType
    row.slotName = slotName
    row.handKind = handKind
    row.entry = entry
    row.huntId = entry and entry.id or nil
    if row.info then
        row.info:Hide()
    end
    self:HideHuntAdvice(row)
    if row.meta then
        row.meta:Hide()
        row.meta:SetText("")
    end
    if row.itemIcon then
        row.itemIcon:Hide()
        row.itemIcon:SetTexture(nil)
    end
    if row.rankMark then
        row.rankMark:Hide()
        row.rankMark:SetText("")
    end
    if row.weaponArrow then
        row.weaponArrow:Hide()
    end

    if rowType == "header" then
        row.icon:Show()
        row.icon:SetSize(16, 16)
        local collapsed = self:IsSlotCollapsed(slotName)
        row.icon:SetTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -24, 0)
        local header = label or GQ.Data:SlotHeaderLabel(slotName)
        if label == "Weapons" and self:WeaponFilterNarrowed() then
            header = "Weapons*"
        elseif slotName == "Ranged" and self:HunterRangedFilter() and self:RangedFilterNarrowed() then
            header = header .. "*"
        end
        row.text:SetText(header)
        row.text:SetTextColor(1, 0.82, 0)
        if row.info then
            local titleWidth = row.text:GetStringWidth() or 0
            if titleWidth < 8 then
                titleWidth = 8 * #(row.text:GetText() or "")
            end
            local infoAnchor = row.text
            local infoPoint = "LEFT"
            local infoX = titleWidth + 4
            if row.weaponArrow and (label == "Weapons" or (slotName == "Ranged" and self:HunterRangedFilter())) then
                row.weaponArrow:ClearAllPoints()
                row.weaponArrow:SetPoint("LEFT", row.text, "LEFT", titleWidth + 2, 0)
                row.weaponArrow:Show()
                infoAnchor = row.weaponArrow
                infoPoint = "RIGHT"
                infoX = 2
            end
            row.info:ClearAllPoints()
            row.info:SetPoint("LEFT", infoAnchor, infoPoint, infoX, 0)
            row.info:Show()
            local owned = self._rankOneOwned
            local key = tostring(slotName) .. ":" .. tostring(handKind)
            if owned and owned[key] then
                local acquired = self:EnsureAcquiredLabel(row)
                acquired:SetTextColor(1, 1, 1)
                acquired:ClearAllPoints()
                acquired:SetPoint("LEFT", row.info, "RIGHT", 4, 0)
                acquired:Show()
            end
        end
        row.highlight:Hide()
        row:SetScript("OnClick", function(self)
            HideItemTooltip()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSlotCollapsed(slotName)
                if log.GamepadFollowClick then
                    log:GamepadFollowClick(self)
                end
            end
        end)
    elseif rowType == "empty" then
        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        local listTab = self:GetListTab()
        if listTab == "completed" then
            row.text:SetText("No completed hunts in this slot.")
        elseif listTab == "removed" then
            row.text:SetText("No removed hunts in this slot.")
        else
            row.text:SetText("No upgrades for your level yet.")
        end
        row.text:SetTextColor(0.6, 0.6, 0.6)
        row.highlight:Hide()
        row:SetScript("OnClick", nil)
    elseif rowType == "empty_all" then
        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        if self:GetListTab() == "removed" then
            row.text:SetText("No removed hunts.")
        else
            row.text:SetText("No completed hunts yet.")
        end
        row.text:SetTextColor(0.6, 0.6, 0.6)
        row.highlight:Hide()
        row:SetScript("OnClick", nil)
    elseif rowType == "subheader" then
        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetText(label or "")
        row.text:SetTextColor(0.85, 0.75, 0.45)
        row.highlight:Hide()
        row:SetScript("OnClick", nil)
    elseif rowType == "notable" then
        local name = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)
        PrimeListEntryItemInfo(entry)
        local r, g, b = GetListItemQualityColor(entry.itemId)
        local status = GetHuntStatus(entry.id)

        row.icon:Show()
        row.icon:SetSize(self.HUNT_ICON_SIZE or 28, self.HUNT_ICON_SIZE or 28)
        row.icon:SetTexture(NOTABLE_LIST_ICON)
        row.icon:SetVertexColor(1, 1, 1)
        local nameLeft = LIST_ROW_NOTABLE_LEFT + ((self.HUNT_ICON_SIZE or 28) - 16)
        self:PlaceHuntName(row, nameLeft, name, entry, r, g, b)
        self:PlaceHuntNotes(row, nameLeft, entry, status, false)

        UpdateListRowHighlight(row)
        row:SetScript("OnClick", function(self)
            OnListRowItemClick(entry)
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and log.GamepadFollowClick then
                log:GamepadFollowClick(self)
            end
        end)
    else
        local name = tostring(GQ.Data:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId)))
        PrimeListEntryItemInfo(entry)
        local r, g, b = GetListItemQualityColor(entry.itemId)
        local status = GetHuntStatus(entry.id)
        local listTab = self:GetListTab()
        local isObtained = entry.id and self:IsEntryObtained(entry.id)

        row.icon:Hide()
        row.icon:SetTexture(nil)
        local iconLeft = LIST_ROW_ITEM_LEFT
        local rank = self:HuntListRank(entry, slotName, handKind)
        if row.rankMark and type(rank) == "number" and rank >= 1 then
            local markWidth = self:RankMarkWidth()
            row.rankMark:SetWidth(markWidth)
            row.rankMark:SetText("#" .. rank)
            row.rankMark:SetTextColor(0.55, 0.55, 0.55)
            row.rankMark:Show()
            local markRight = 4 + markWidth + 1
            if markRight > iconLeft then
                iconLeft = markRight
            end
        end
        local nameLeft = self:PlaceHuntItemIcon(row, entry.itemId, iconLeft)
        local showNewLabel = listTab == "active" and not isObtained and status ~= "completed"
        self:PlaceHuntName(row, nameLeft, name, entry, r, g, b)
        self:PlaceHuntNotes(row, nameLeft, entry, status, showNewLabel)

        UpdateListRowHighlight(row)
        row:SetScript("OnClick", function(self)
            OnListRowItemClick(entry)
            local log = _G.GearQuest and _G.GearQuest.Log
            if log and log.GamepadFollowClick then
                log:GamepadFollowClick(self)
            end
        end)
    end
end

function GQ.Log:ScrollListToRow(layoutIndex)
    if not layoutIndex or not self.frame or not self.frame.scroll then
        return
    end

    local scroll = self.frame.scroll
    local scrollChild = self.frame.scrollChild
    if not scrollChild then
        return
    end

    local visibleHeight = scroll:GetHeight() or 200
    local contentHeight = scrollChild:GetHeight() or 0
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    if maxScroll <= 0 then
        scroll:SetVerticalScroll(0)
        return
    end

    local row = self.listRows and self.listRows[layoutIndex]
    local rowTop = row and row._listTop or ((layoutIndex - 1) * ROW_HEIGHT)
    local rowHeight = row and row._listHeight or ROW_HEIGHT
    local target = rowTop - math.floor((visibleHeight - rowHeight) / 2)
    target = math.max(0, math.min(target, maxScroll))
    scroll:SetVerticalScroll(target)

    local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetValue(target)
    end
end

function GQ.Log:ProfessionSkillLine(profession, skill)
    if not profession or not skill then
        return nil
    end
    local yours = ""
    local ranks, scanned = self:ReadProfessionRanks()
    local have = ranks and ranks[profession]
    if have and have > 0 then
        local color = have >= skill and "|cff0c4a1c" or "|cff6e1212"
        yours = string.format(" %sYour %s is %d.|r", color, profession, have)
    elseif scanned then
        yours = string.format(" |cff6e1212You don't have %s.|r", profession)
    end
    return string.format("Requires %s (%d) to craft.%s", profession, skill, yours)
end

function GQ.Log:BuildDetailLines(entry)
    if entry and entry.sourceType == "profession" and GQ.Data and GQ.Data.EnrichProfessionEntry then
        GQ.Data:EnrichProfessionEntry(entry)
    end

    local intro
    local vendorLine
    if entry and entry.sourceType == "profession" and GQ.Data and GQ.Data.GetProfessionInstructions then
        intro = GQ.Data:GetProfessionInstructions(entry) or ""
    else
        vendorLine = GQ.Data and GQ.Data.VendorBoughtLine and GQ.Data:VendorBoughtLine(entry)
        if vendorLine and vendorLine ~= "" then
            intro = vendorLine
        else
            intro = (GQ.Data and GQ.Data.GetEntryInstructions and GQ.Data:GetEntryInstructions(entry))
                or (entry and entry.instructions)
        end
    end
    local patternProf, patternSkill = nil, nil
    if entry and GQ.Data and GQ.Data.PatternDropCraft then
        patternProf, patternSkill = GQ.Data:PatternDropCraft(entry)
    end
    if patternProf and intro and intro ~= ""
        and not intro:find("pattern drops", 1, true)
        and not intro:find("pattern is dropped", 1, true) then
        if intro:sub(1, 11) == "Drops from " then
            intro = "The " .. patternProf .. " pattern drops from " .. intro:sub(12)
        elseif intro:sub(1, 11) == "Dropped by " then
            intro = "The " .. patternProf .. " pattern is dropped by " .. intro:sub(12)
        else
            intro = "The " .. patternProf .. " pattern is the drop. " .. intro
        end
    end
    local lines = {}
    if intro and intro ~= "" then
        lines[1] = intro
    end

    local audit = GQ.Data and GQ.Data.GetForeverAudit and GQ.Data:GetForeverAudit(entry.itemId)
    if audit and audit.status == "missing" then
        table.insert(lines, "\nNot found on Wowhead Forever - it may not exist in this game.")
    elseif GQ.Data and GQ.Data.NeedsDatamineNotice and GQ.Data:NeedsDatamineNotice(entry) then
        table.insert(lines, "\nHas not been datamined yet")
    end

    local hasStoredTip = audit and audit.tip and audit.tip ~= ""
    if entry.itemId and GQ.Data and GQ.Data.IsClientItemMissing and GQ.Data:IsClientItemMissing(entry.itemId)
        and not hasStoredTip
        and not (GQ.Data.EntryUsesRebuiltTooltip and GQ.Data:EntryUsesRebuiltTooltip(entry)) then
        table.insert(lines, "\nNot found in the client yet.")
    end

    local suffixHint = GQ.Data:GetSuffixHint(entry)
    if suffixHint then
        table.insert(lines, "\nRandom enchant: " .. suffixHint)
    end

    if entry.proc then
        table.insert(lines, "\nWhy it's good: " .. entry.proc)
    end

    if GQ.Data:ShouldDisplayAsNotable(entry, entry and entry.slot) and entry.proc then
        table.insert(lines, "\nWorth considering - the proc is the point.")
    end

    if entry.origin == "guide" then
        table.insert(lines, "\nRanked from the Wowhead Classic BiS guide.")
    end

    local how = string.lower(lines[1] or "")

    local function alreadySays(needle)
        return needle and needle ~= "" and how:find(string.lower(needle), 1, true)
    end

    if entry.sourceType == "world_drop" or entry.sourceType == "rare_npc" or entry.sourceType == "profession" then
        local mentionsAh = how:find("auction", 1, true)
        if not mentionsAh then
            local isBoE = GQ.Equip and GQ.Equip.IsBindOnEquip and GQ.Equip:IsBindOnEquip(entry.itemId)
            if isBoE then
                local ah = entry.sourceType == "profession"
                    and "\nAlso available on the Auction House (crafted by others; binds when equipped)."
                    or "\nAlso available on the Auction House (binds when equipped)."
                table.insert(lines, ah)
            end
        end
    end

    local zoneName = entry.zone
    if (entry.sourceType == "world_drop" or entry.sourceType == "vendor")
        and entry.itemId and GQ.Data and GQ.Data.NearestCoordinateSpot then
        local spot = GQ.Data:NearestCoordinateSpot(entry.itemId)
        if spot and spot.map and spot.map ~= "" then
            zoneName = spot.map
        end
    end
    if zoneName and not alreadySays(zoneName) then
        local instructions = entry.instructions or ""
        local genericDrop = entry.sourceType == "world_drop"
            and (not entry.npc or entry.npc == "")
            and instructions:sub(1, 10) == "World drop"
            and zoneName == entry.zone
        local hideCatalogZone = false
        if genericDrop then
            local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
            local deny = faction and GQ.Data.FACTION_ZONE_DENY and GQ.Data.FACTION_ZONE_DENY[faction]
            if deny and deny[entry.zone] then
                hideCatalogZone = true
            end
        end
        if not hideCatalogZone then
            table.insert(lines, "\nZone: " .. zoneName)
        end
    end
    if entry.questName and not alreadySays(entry.questName) then
        table.insert(lines, "Quest: " .. entry.questName)
    end
    if entry.npc and not vendorLine and not alreadySays(entry.npc) then
        table.insert(lines, "NPC: " .. entry.npc)
    end

    -- The tooltip stays the Wowhead tip. How an imbued weapon is made lives
    -- here in the description, since Wowhead does not say it.
    local imbue = GQ.Data and GQ.Data.ImbueInfo and GQ.Data:ImbueInfo(entry.itemId)
    local combine = imbue and GQ.Data:ImbueCombineLine(imbue)
    if combine then
        table.insert(lines, "\n" .. combine)
    end

    local craftProf, craftSkill = patternProf, patternSkill
    if entry and entry.sourceType == "profession" and GQ.Data.ProfessionCraftRequirement then
        craftProf, craftSkill = GQ.Data:ProfessionCraftRequirement(entry)
    elseif not craftProf and entry and entry.profession and entry.itemId and GQ.CraftSkills then
        -- A quest can award the pattern. The row still names the profession,
        -- and the recipe skill stays on the line before Source.
        local known = GQ.CraftSkills[entry.itemId]
        if known and known.skill and known.skill > 0 then
            craftProf = known.profession or entry.profession
            craftSkill = known.skill
        end
    end
    if craftProf and entry and entry.sourceType ~= "profession" and not patternProf
        and GQ.Data.ProfessionMaterialsLine then
        local materials = GQ.Data:ProfessionMaterialsLine(entry)
        if materials and materials ~= "" then
            table.insert(lines, "\n" .. materials)
        end
    end
    local skillLine = self:ProfessionSkillLine(craftProf, craftSkill)
    if skillLine then
        table.insert(lines, "\n" .. skillLine)
    end

    local src = GQ.NormalizeSourceType and GQ:NormalizeSourceType(entry.sourceType or "") or (entry.sourceType or "")
    if src == "quest_reward" and GQ.Data and GQ.Data.QuestChainSteps then
        local chainSteps = GQ.Data:QuestChainSteps(entry)
        if chainSteps then
            table.insert(lines, "\nPart of a quest chain.")
            local useFlag = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
            local completedMap
            if not useFlag and GetQuestsCompleted then
                local ok, map = pcall(GetQuestsCompleted)
                if ok and type(map) == "table" then
                    completedMap = map
                end
            end
            for i = 1, #chainSteps do
                local step = chainSteps[i]
                local questId = step and tonumber(step[1])
                local questName = step and step[2]
                if type(questName) == "string" and questName ~= "" then
                    local known, done = false, false
                    if useFlag and questId then
                        local ok, flagged = pcall(C_QuestLog.IsQuestFlaggedCompleted, questId)
                        if ok then
                            known = true
                            done = flagged and true or false
                        end
                    elseif completedMap and questId then
                        known = true
                        done = completedMap[questId] and true or false
                    end
                    if known and done then
                        table.insert(lines, questName .. " - |cff0c4a1ccompleted|r")
                    elseif known then
                        table.insert(lines, questName .. " - not completed yet")
                    else
                        table.insert(lines, questName)
                    end
                end
            end
        elseif GQ.Data.QuestChainLines then
            local chainLead, chainCount = GQ.Data:QuestChainLines(entry)
            if chainLead then
                table.insert(lines, chainLead)
            end
            if chainCount then
                table.insert(lines, "\n" .. chainCount)
            end
        end
    end

    if entry.reqRep then
        for i = 1, #entry.reqRep do
            local row = entry.reqRep[i]
            local faction = row[1] or row.faction
            local standing = row[2] or row.standing
            if faction and standing then
                table.insert(lines, self:ReputationRequirementLine(faction, standing))
            end
        end
    end

    if src == "quest_reward" and entry.itemId and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        local pickup = fact and fact.reqLevel
        if type(pickup) == "number" and pickup >= 1 then
            local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
            local color = level >= pickup and "|cff0c4a1c" or "|cff6e1212"
            table.insert(lines, string.format(
                "\n%sThis quest can be picked up at level %d.|r",
                color,
                math.floor(pickup)
            ))
        end
        local recommended = self.QuestRewardRecommendedLevel and self:QuestRewardRecommendedLevel(entry)
        if type(recommended) == "number" and recommended >= 1 then
            local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
            local color = level >= recommended and "|cff0c4a1c" or "|cff6e1212"
            table.insert(lines, string.format(
                "\n%sRecommended to pick this quest up at level %d.|r",
                color,
                math.floor(recommended)
            ))
        end
    end

    if (src == "boss_drop" or src == "raid_trash") and self.AppendDungeonEntryLine then
        self:AppendDungeonEntryLine(lines, entry)
    end

    if src == "vendor" and GQ.Data and GQ.Data.VendorCostLine then
        local costLine = GQ.Data:VendorCostLine(entry)
        if costLine then
            if lines[1] and GQ.Data.StripGenericVendorCost then
                local stripped = GQ.Data:StripGenericVendorCost(lines[1])
                if stripped then
                    lines[1] = stripped
                else
                    table.remove(lines, 1)
                end
            end
            table.insert(lines, costLine)
        end
    end

    if entry.itemId and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        local pvpRank = fact and fact.pvpRank
        if (type(pvpRank) ~= "string" or pvpRank == "") and src == "vendor" and GQ.Data.PvpRankLabel then
            pvpRank = GQ.Data:PvpRankLabel(entry.name)
        end
        if type(pvpRank) == "string" and pvpRank ~= "" then
            table.insert(lines, "\nRequires " .. pvpRank .. ".")
        end
    end

    if GQ.Data and GQ.Data.AccessLine then
        local access = GQ.Data:AccessLine(entry)
        if access then
            table.insert(lines, "\n" .. access)
        end
    end

    table.insert(lines, "\nSource: " .. GQ:GetSourceLabel(entry.sourceType))

    local record = GetHuntRecord(entry.id)
    local completed = record and NormalizeHuntStatus(record.status) == "completed"
    if not completed and entry.itemId and GQ.Log and GQ.Log.HasObtainedItemId then
        completed = GQ.Log:HasObtainedItemId(entry.itemId) and true or false
    end
    if not completed then
        completed = GetObtainedTimestamp(entry.id) and true or false
    end
    if completed then
        local when = record and record.completedAt
        if type(when) ~= "number" or when <= 0 then
            when = GetObtainedTimestamp(entry.id)
        end
        if (type(when) ~= "number" or when <= 0) and entry.itemId and GQ.Log and GQ.Log.HasObtainedItemId then
            when = GQ.Log:HasObtainedItemId(entry.itemId)
        end
        if (type(when) ~= "number" or when <= 0) and entry.itemId then
            when = GetCraftedTimestamp(entry.itemId)
        end
        local completedText = type(when) == "number" and when > 0 and FormatCompletedDate(when)
        if completedText then
            return lines, "Completed: " .. completedText
        end
        return lines, "Completed"
    end

    return lines
end

function GQ.Log:EnsureItemInfoListener()
    if self.itemInfoListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId, success)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log or not log.frame or not log.frame:IsShown() then
            return
        end

        itemId = tonumber(itemId)
        if success == false and itemId and GQ.Data and GQ.Data.NoteClientItemMissing then
            GQ.Data:NoteClientItemMissing(itemId)
        end
        local entry
        if log:GetPageTab() == "lookup" then
            entry = log.lookupEntry
        else
            entry = log.selectedEntry or GQ.Data:GetEntryById(log.selectedHuntId)
        end
        if not entry or not itemId or entry.itemId ~= itemId then
            return
        end

        if success == false then
            log:ApplyEntryDetail(entry)
        end
        log:UpdateDetailReward(entry)
    end)
    self.itemInfoListener = frame
end

function GQ.Log:VisibleSlotRank(entry)
    if not entry or not entry.itemId then
        return nil
    end
    if GQ.Data and GQ.Data.EntryIsDamagingWeapon and GQ.Data:EntryIsDamagingWeapon(entry) then
        return self:WeaponTrueRank(entry)
    end
    local slotName, handKind = self:RankListContext(entry)
    if not slotName then
        return nil
    end
    local list = self:GetSlotRankList(slotName, handKind)
    local suffix = entry.suffix or ""
    for i = 1, #list do
        local row = list[i]
        if row == entry or row.id == entry.id
            or (row.itemId == entry.itemId and (row.suffix or "") == suffix and row.minLevel == entry.minLevel) then
            return i
        end
    end
    return nil
end

function GQ.Log:HuntDisplayRank(entry)
    if not entry then
        return nil
    end
    -- Place among the pieces this faction can see. Stored ranks still
    -- include the other side, and printing those leaves a hole.
    local visible = self:VisibleSlotRank(entry)
    if visible then
        return visible
    end
    if type(entry.curatedRank) == "number" and entry.curatedRank > 0 then
        return entry.curatedRank
    end
    if not GQ.Data or not GQ.Data.GetCandidateSlotKeys or not GQ.Data.GetClassSlotEntryList
        or not entry.slot or not entry.itemId then
        return nil
    end
    local fallback
    for _, key in ipairs(GQ.Data:GetCandidateSlotKeys(entry.slot)) do
        for _, row in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
            if row.itemId == entry.itemId and type(row.curatedRank) == "number" and row.curatedRank > 0 then
                if row.minLevel == entry.minLevel then
                    return row.curatedRank
                end
                fallback = fallback or row.curatedRank
            end
        end
    end
    return fallback
end

function GQ.Log:RankListContext(entry)
    local slotName = entry and entry.slot
    if GQ.Data and GQ.Data.NormalizeSlotName then
        slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
    end
    local handKind
    local label
    if entry and GQ.Data and GQ.Data.EntryIsDamagingWeapon and GQ.Data:EntryIsDamagingWeapon(entry) then
        -- One scale for the merged weapon list. The filter does not change it.
        return "MainHand", "both", "Weapons"
    end
    if not label and GQ.Data and GQ.Data.SlotLabel then
        label = GQ.Data:SlotLabel(slotName)
    end
    return slotName, handKind, label or slotName or "slot"
end

function GQ.Log:EntryOnPlainList(entry, slotName)
    if not entry then
        return false
    end
    if self:ShouldHideFromActiveList(entry, slotName) then
        return false
    end
    return true
end

function GQ.Log:PlainWeaponList(slotName, handKind)
    local pool = {}
    for _, row in ipairs(GQ.Data:GetCandidatesForSlot(slotName) or {}) do
        if self:EntryOnPlainList(row, slotName) and self:EntryInWeaponHand(row, slotName, handKind) then
            pool[#pool + 1] = row
        end
    end
    local list = GQ.Data:TopUniqueEntries(pool, 3)
    if slotName == "MainHand" and GQ.Data.GetNotableForSlot then
        for _, row in ipairs(GQ.Data:GetNotableForSlot(slotName) or {}) do
            if self:EntryOnPlainList(row, slotName) and self:EntryInWeaponHand(row, slotName, handKind) then
                local seen = false
                for i = 1, #list do
                    if list[i].itemId == row.itemId then
                        seen = true
                        break
                    end
                end
                if not seen then
                    list[#list + 1] = row
                end
                break
            end
        end
    end
    return list
end

function GQ.Log:PlainListPlace(entry)
    if not entry or not GQ.Data then
        return nil
    end
    if GQ.Data.EntryIsDamagingWeapon and GQ.Data:EntryIsDamagingWeapon(entry) then
        return self:WeaponTrueRank(entry)
    end
    local slotName, handKind = self:RankListContext(entry)
    if not slotName then
        return nil
    end
    local list
    if handKind then
        list = self:PlainWeaponList(slotName, handKind)
    else
        list = self:GetActiveSlotListEntries(slotName, true)
    end
    list = list or {}
    for i = 1, #list do
        local row = list[i]
        if row == entry or row.id == entry.id or (row.itemId == entry.itemId and row.minLevel == entry.minLevel) then
            return i
        end
    end
    return nil
end

function GQ.Log:BestInSlotLine(place, slotLabel)
    if place == 1 then
        return string.format("This is the best in slot %s for you.", slotLabel)
    end
    local teen = place % 100
    local suffix = "th"
    if teen < 11 or teen > 13 then
        local last = place % 10
        if last == 1 then
            suffix = "st"
        elseif last == 2 then
            suffix = "nd"
        elseif last == 3 then
            suffix = "rd"
        end
    end
    return string.format("This is the %d%s best in slot %s for you.", place, suffix, slotLabel)
end

function GQ.Log:GetSlotRankList(slotName, handKind)
    local dataSlot = slotName == "WeaponPair" and "MainHand" or slotName
    if not dataSlot or not GQ.Data or not GQ.Data.GetClassSlotEntryList then
        return {}
    end
    -- Reused by the (i) list and by every item hover. One build per slot
    -- until level, spec, class, or faction changes.
    local band = GQ.Data:GetActiveBandCacheKey()
    if self._slotRankBand ~= band or not self._slotRankCache then
        self._slotRankBand = band
        self._slotRankCache = {}
    end
    local cacheKey = tostring(slotName) .. ":" .. tostring(handKind)
    local cached = self._slotRankCache and self._slotRankCache[cacheKey]
    if cached then
        return cached
    end
    -- The stored band for this level, spec, and faction. A simulated hunter
    -- is not limited to what the logged-in character can equip today.
    -- Required level comes from the stored fact. Asking the client for every
    -- item in the slot loads those tooltips and is what dropped FPS on hover.
    local level = GQ:GetEffectiveLevel() or 1
    local pool = {}
    local seen = {}
    local equip = GQ.Equip
    local prevSuppress = equip and equip._suppressItemPrime
    if equip then
        equip._suppressItemPrime = true
    end
    local loadSlots = { dataSlot }
    if handKind == "both" and dataSlot == "MainHand" then
        -- The weapons (i) list is both hands. The index uses that same list.
        loadSlots[2] = "SecondaryHand"
    end
    for s = 1, #loadSlots do
        local loadSlot = loadSlots[s]
    for _, key in ipairs(GQ.Data:GetCandidateSlotKeys(loadSlot)) do
        for _, entry in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
            if entry and entry.id and not seen[entry.id]
                and GQ.Data:ShouldShowEntry(entry)
                and GQ.Data:EntryMatchesPlayerBand(entry)
                and (not equip or not equip.EntryArmorIsWearable or equip:EntryArmorIsWearable(entry, loadSlot))
                and (not handKind or self:EntryInWeaponHand(entry, loadSlot, handKind)) then
                local fact = GQ.Data:GetItemFact(entry.itemId)
                local req = fact and fact.reqLevel
                if not (type(req) == "number" and req > 1 and req > level) then
                    seen[entry.id] = true
                    pool[#pool + 1] = entry
                end
            end
        end
    end
    end
    if equip then
        equip._suppressItemPrime = prevSuppress
    end
    pool = GQ.Data:FilterToActiveBand(pool)
    pool = GQ.Data:DeduplicateEntriesByItem(pool)
    table.sort(pool, function(a, b)
        local rankA = a.curatedRank or 99
        local rankB = b.curatedRank or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        local scoreA = (self.WeaponCompareScore and self:WeaponCompareScore(a)) or (a.pipelineScore or 0)
        local scoreB = (self.WeaponCompareScore and self:WeaponCompareScore(b)) or (b.pipelineScore or 0)
        if scoreA ~= scoreB then
            return scoreA > scoreB
        end
        return (a.curatedRank or 99) < (b.curatedRank or 99)
    end)
    self._slotRankCache[cacheKey] = pool
    return pool
end

function GQ.Log:EnsureSlotRankPanel()
    if self.slotRankPanel then
        return self.slotRankPanel
    end
    local panel = CreateFrame("Frame", "GearQuestSlotRankPanel", UIParent)
    panel:SetFrameStrata("TOOLTIP")
    panel:SetFrameLevel(400)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)
    ApplyFill(panel, { 0.05, 0.04, 0.02, 0.96 })
    ApplyMetalEdge(panel, 12)

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    panel.title:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)
    panel.title:SetJustifyH("LEFT")
    panel.title:SetTextColor(1, 0.82, 0)

    panel.sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.sub:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -2)
    panel.sub:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)
    panel.sub:SetJustifyH("LEFT")
    panel.sub:SetTextColor(0.75, 0.75, 0.75)

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -40)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 8)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    panel.scroll = scroll
    panel.child = child
    panel.lines = {}
    panel.scrollTop = 40

    panel.probe = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.probe:Hide()

    panel.bar = panel:CreateTexture(nil, "OVERLAY")
    panel.bar:SetWidth(3)
    panel.bar:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.9)
    panel.bar:Hide()

    function panel:UpdateBar()
        local view = self.scroll:GetHeight() or 1
        local content = self.child:GetHeight() or 1
        if content <= view + 1 then
            self.bar:Hide()
            return
        end
        local barH = math.max(18, view * view / content)
        local maxScroll = content - view
        local travel = math.max(0, view - barH)
        local offset = maxScroll > 0 and (self.scroll:GetVerticalScroll() / maxScroll) * travel or 0
        self.bar:SetHeight(barH)
        self.bar:ClearAllPoints()
        self.bar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -6, -self.scrollTop - offset)
        self.bar:Show()
    end

    panel:SetScript("OnMouseWheel", function(self, delta)
        local view = self.scroll:GetHeight() or 0
        local maxScroll = math.max(0, (self.child:GetHeight() or 0) - view)
        local nextScroll = self.scroll:GetVerticalScroll() - delta * 24
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end
        self.scroll:SetVerticalScroll(nextScroll)
        self:UpdateBar()
    end)

    panel.watch = CreateFrame("Frame", nil, panel)
    panel.watch:Hide()
    panel.watch:SetScript("OnUpdate", function(watch)
        local owner = panel.owner
        if owner and owner:IsShown() and (owner:IsMouseOver() or panel:IsMouseOver()) then
            return
        end
        panel:Hide()
        watch:Hide()
    end)
    panel:SetScript("OnShow", function(self)
        self.watch:Show()
    end)
    panel:SetScript("OnHide", function(self)
        self.watch:Hide()
    end)

    panel:Hide()
    self.slotRankPanel = panel
    panel:SetScale(self:WindowScale())
    return panel
end

function GQ.Log:HideSlotRankPanel()
    if self.slotRankPanel then
        self.slotRankPanel:Hide()
    end
end

function GQ.Log:ShowSlotRankTooltip(row)
    if not row or not GQ.Data then
        return
    end
    local slotName = row.slotName
    local handKind = row.handKind
    local weaponList = (slotName == "MainHand" or slotName == "WeaponPair") and self:IsWeaponHandKind(handKind)
    local entries
    if weaponList then
        -- The weapon filter only hides hunt rows. This list is every ranked weapon.
        entries = self:UnfilteredWeaponList()
    else
        entries = self:GetSlotRankList(slotName, handKind)
    end
    local title = row.text and row.text:GetText()
    if not title or title == "" then
        title = (GQ.Data.SlotHeaderLabel and GQ.Data:SlotHeaderLabel(slotName)) or slotName or "Slot"
    end

    local scoreOn = GQ.Data.GearScoreTooltipEnabled and GQ.Data:GearScoreTooltipEnabled()
    local scoreSim = scoreOn and GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    local scoreCtx
    if scoreOn and not scoreSim and GQ.Data.GearScoreContext then
        -- Weapon rank numbers ignore the filter. The index spans both hands.
        local scoreHand = handKind
        local scoreSlot = slotName
        if weaponList then
            scoreHand = "both"
            scoreSlot = "MainHand"
        end
        scoreCtx = GQ.Data:GearScoreContext(scoreSlot, scoreHand)
    end
    local function scoreTrail(entry)
        if scoreSim or not scoreCtx or not GQ.Data.GearScoreTrail then
            return ""
        end
        local text = GQ.Data:GearScoreTrail(entry, scoreCtx)
        if not text or text == "" then
            return ""
        end
        return "  " .. text
    end

    local lines = {}
    local function add(text, gap)
        lines[#lines + 1] = { text = text, gap = gap or 0 }
    end
    if #entries == 0 then
        add("|cff999999Nothing ranked for this slot.|r")
    else
        for i = 1, #entries do
            local entry = entries[i]
            local name = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId))
            local r, g, b = GetListItemQualityColor(entry.itemId)
            local color = string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
            local place = i
            if weaponList and self.WeaponTrueRank then
                place = self:WeaponTrueRank(entry) or i
            end
            add(string.format("|cffffd100#%d|r %s%s|r%s", place, color, name, scoreTrail(entry)))
        end
    end

    if GameTooltip then
        GameTooltip:Hide()
    end

    local panel = self:EnsureSlotRankPanel()
    panel.owner = row
    panel.title:SetText(title)
    panel.sub:SetWordWrap(true)
    panel.sub:SetText(scoreSim and "Turn off simulation mode to see your GearQuest Score for this item" or "Ranked for your level.")
    panel.probe:SetText(title)
    local width = panel.probe:GetStringWidth() or 160
    panel.probe:SetText("Ranked for your level.")
    width = math.max(width, panel.probe:GetStringWidth() or 0)
    for i = 1, #lines do
        panel.probe:SetText(lines[i].text)
        width = math.max(width, panel.probe:GetStringWidth() or 0)
    end
    width = math.min(560, math.max(200, width + 36))
    local yMeasure = 0
    for i = 1, #lines do
        yMeasure = yMeasure + lines[i].gap + 16
    end
    local screen = UIParent and UIParent:GetHeight() or 600
    local panelH = math.min(screen - 24, 52 + yMeasure)
    if panelH < 52 then
        panelH = 52
    end
    panel:SetSize(width, panelH)
    local subH = panel.sub:GetStringHeight() or 14
    if subH < 12 then
        subH = 14
    end
    local header = 28 + subH
    if panel.scroll then
        panel.scroll:ClearAllPoints()
        panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -header)
        panel.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 8)
    end
    panelH = math.min(screen - 24, header + 8 + yMeasure)
    if panelH < header + 16 then
        panelH = header + 16
    end
    panel:SetHeight(panelH)
    panel.child:SetWidth(width - 28)

    local y = 0
    for i = 1, #lines do
        y = y + lines[i].gap
        local fs = panel.lines[i]
        if not fs then
            fs = panel.child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            panel.lines[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", panel.child, "TOPLEFT", 0, -y)
        fs:SetPoint("TOPRIGHT", panel.child, "TOPRIGHT", 0, -y)
        fs:SetText(lines[i].text)
        fs:Show()
        y = y + 16
    end
    for i = #lines + 1, #panel.lines do
        panel.lines[i]:Hide()
    end

    panel.child:SetHeight(math.max(y, 1))
    panel.scroll:SetVerticalScroll(0)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", row, "TOPRIGHT", -2, 0)
    panel:Show()
    panel:UpdateBar()
end

function GQ.Log:ShowRankBoxTooltip(box)
    local entry = box and box.entry
    local rank = box and box.rank
    if not entry then
        return
    end
    local _, _, slotLabel = self:RankListContext(entry)
    local place = self:PlainListPlace(entry)
    local onPlainList = place ~= nil
    if not place then
        place = rank
    end
    if type(place) ~= "number" or place <= 0 then
        return
    end
    local statement = self:BestInSlotLine(place, slotLabel)
    local extra
    if not onPlainList then
        local filterOn = self:SourceFilterActive()
        local playOn = self:PlayStyleActive()
        if filterOn and playOn then
            extra = "You are seeing it in the list because a filter and a play style are both on."
        elseif filterOn then
            extra = "You are seeing it in the list because a filter is on."
        elseif playOn then
            extra = "You are seeing it in the list because a play style is on."
        end
    end
    GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
    GameTooltip:SetText(statement, 1, 1, 1, 1, true)
    local pairNote = self:OffHandPairNote(entry)
    if pairNote then
        GameTooltip:AddLine(pairNote, 1, 1, 1, true)
    end
    if extra then
        GameTooltip:AddLine(extra, 1, 1, 1, true)
    end
    GameTooltip:SetFrameStrata("TOOLTIP")
    GameTooltip:Show()
    GameTooltip:SetFrameLevel(400)
end

function GQ.Log:LayoutDetailRank(rank, entry)
    local frame = self.frame
    if not frame or not frame.detailRankBox or not frame.detailTitle or not frame.detailChild then
        return
    end
    local box = frame.detailRankBox
    if type(rank) ~= "number" or rank <= 0 then
        box.rank = nil
        box.entry = nil
        local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
        if owner == box then
            GameTooltip:Hide()
        end
        box:Hide()
        frame.detailTitle:ClearAllPoints()
        frame.detailTitle:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
        frame.detailTitle:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
        return
    end
    box.rank = rank
    box.entry = entry
    box.text:SetText(string.format("Rank #%d", rank))
    local width = box.text:GetStringWidth() or 0
    if width < 8 then
        width = 7 * #box.text:GetText()
    end
    local height = box.text:GetStringHeight() or 0
    if height < 10 then
        height = 14
    end
    box:SetSize(width + 16, height + 10)
    box:Show()
    frame.detailTitle:ClearAllPoints()
    frame.detailTitle:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
    frame.detailTitle:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
    if owner == box then
        self:ShowRankBoxTooltip(box)
    end
end

function GQ.Log:ShowCoordinateTooltip(button)
    local spots = button and button.spots
    if not spots or #spots == 0 then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Coordinates", 1, 0.82, 0, 1, true)
    local limit = #spots
    if limit > 10 then
        limit = 10
    end
    for i = 1, limit do
        local spot = spots[i]
        GameTooltip:AddLine(string.format("%s %.1f, %.1f", spot.map or "", spot.x or 0, spot.y or 0), 1, 1, 1, true)
    end
    if #spots > 10 then
        GameTooltip:AddLine(string.format("And %d more.", #spots - 10), 0.75, 0.75, 0.75, true)
    end
    GameTooltip:SetFrameStrata("TOOLTIP")
    GameTooltip:Show()
    GameTooltip:SetFrameLevel(400)
end

function GQ.Log:CoordLineEnd(text, maxWidth)
    local probe = self.frame and self.frame.detailCoordsProbe
    if not probe or not text or text == "" or not maxWidth or maxWidth < 20 then
        return 0, 1
    end
    local function widthOf(sample)
        probe:SetText(sample)
        local width = probe:GetStringWidth() or 0
        if width < 1 then
            width = 7 * #sample
        end
        return width
    end
    local gap = widthOf(" ")
    local line, lines, started = 0, 1, false
    local i = 1
    while i <= #text do
        local startAt, endAt = text:find("%S+", i)
        if not startAt then
            break
        end
        local wordWidth = widthOf(text:sub(startAt, endAt))
        if started and (line + gap + wordWidth) > (maxWidth - 2) then
            lines = lines + 1
            line = wordWidth
        elseif started then
            line = line + gap + wordWidth
        else
            line = wordWidth
            started = true
        end
        i = endAt + 1
    end
    probe:SetText("")
    return line, lines
end

function GQ.Log:LayoutDetailCoords(entry, completedLine)
    local frame = self.frame
    if not frame or not frame.detailCoords or not frame.detailBody then
        return
    end
    local line, spots
    if entry and entry.itemId and GQ.Data and GQ.Data.CoordinateLine then
        line, spots = GQ.Data:CoordinateLine(entry.itemId)
    end
    local done = frame.detailDone
    local reward = frame.detailRewardHeader
    local anchor = frame.detailBody
    if not line or line == "" then
        frame.detailCoords:Hide()
        if frame.detailCoordsInfo then
            frame.detailCoordsInfo:Hide()
            frame.detailCoordsInfo.spots = nil
        end
        self._nearestSpotKey = nil
    else
        frame.detailCoords:SetWordWrap(true)
        local maxWidth = frame.detailBody:GetWidth() or 0
        if maxWidth < 40 then
            maxWidth = (frame.detailChild and frame.detailChild:GetWidth() or 0) - 16
        end
        if maxWidth < 40 then
            maxWidth = RIGHT_COLUMN_WIDTH - 28
        end
        local info = frame.detailCoordsInfo
        local showInfo = spots and #spots > 1
        local textWidth = maxWidth
        if showInfo then
            textWidth = maxWidth - 22
        end
        if textWidth < 40 then
            textWidth = maxWidth
        end
        local lastWidth, lines = self:CoordLineEnd(line, textWidth)
        frame.detailCoords:SetWidth(textWidth)
        frame.detailCoords:SetText(line)
        frame.detailCoords:Show()
        if info then
            if showInfo then
                info.spots = spots
                local lineH = 14
                if frame.detailCoordsProbe then
                    frame.detailCoordsProbe:SetText("Ay")
                    lineH = frame.detailCoordsProbe:GetStringHeight() or 14
                    frame.detailCoordsProbe:SetText("")
                end
                if lineH < 10 then
                    lineH = 14
                end
                info:ClearAllPoints()
                info:SetPoint("TOPLEFT", frame.detailCoords, "TOPLEFT", lastWidth + 4, -((lines - 1) * lineH) + 2)
                if frame.detailChild and frame.detailChild.GetFrameLevel and info.SetFrameLevel then
                    info:SetFrameLevel(frame.detailChild:GetFrameLevel() + 20)
                end
                info:Show()
            else
                info.spots = nil
                info:Hide()
            end
        end
        local spot = spots and spots[1]
        self._nearestSpotKey = spot and string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0) or nil
        anchor = frame.detailCoords
    end
    if done then
        if completedLine and completedLine ~= "" then
            done:ClearAllPoints()
            done:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
            done:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
            done:SetText(completedLine)
            done:Show()
            anchor = done
        else
            done:Hide()
            done:SetText("")
        end
    end
    if reward then
        reward:ClearAllPoints()
        reward:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    end
end

function GQ.Log:RefreshNearestCoordinates()
    if not GQ.Data or not GQ.Data.NearestCoordinateSpot then
        return
    end
    -- Called when you change zone. A tracked pin is placed once; asking the
    -- map again every second was what climbed memory with the guide off.
    if GQ.Data then
        GQ.Data._playerWorldAt = nil
    end
    local frame = self.frame
    local entry = self.selectedEntry
    if entry and frame and frame:IsShown() and frame.detailBody and frame.detailBody:IsShown() then
        local spot = GQ.Data:NearestCoordinateSpot(entry.itemId)
        local key = spot and string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0) or ""
        if key ~= (self._nearestSpotKey or "") then
            self._nearestSpotKey = key
            self:ApplyEntryDetail(entry)
        end
    end
    if not (GQ.Pins and GQ.Pins.Sync and GQ.Tracker and GQ.Tracker.GetTrackedEntries) then
        return
    end
    local entries = GQ.Tracker:GetTrackedEntries() or {}
    local parts = {}
    for i = 1, #entries do
        local tracked = entries[i]
        local spot = tracked and tracked.itemId and GQ.Data:NearestCoordinateSpot(tracked.itemId)
        parts[i] = spot and string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0) or ""
    end
    local sig = table.concat(parts, ";")
    if sig ~= self._trackedSpotSig then
        self._trackedSpotSig = sig
        if GQ.Tracker.Refresh then
            GQ.Tracker:Refresh()
        else
            GQ.Pins:Sync()
        end
    end
end

function GQ.Log:EnsureCoordinateWatch()
    if self._coordWatch then
        return
    end
    local watch = CreateFrame("Frame")
    watch:RegisterEvent("ZONE_CHANGED")
    watch:RegisterEvent("ZONE_CHANGED_INDOORS")
    watch:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    watch:SetScript("OnEvent", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.RefreshNearestCoordinates then
            log:RefreshNearestCoordinates()
        end
        if log and log.FocusZoneEnabled and log:FocusZoneEnabled() then
            local zone = log:PlayerZoneName()
            if zone ~= "" and zone ~= log._focusZoneSeen then
                log:ScheduleFocusZoneRefresh()
            end
        end
    end)
    self._coordWatch = watch
end

function GQ.Log:ApplyEntryDetail(entry)
    if not self.frame or not entry then
        return
    end

    self:EnsureDetailLore(self.frame)

    local itemName = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)

    self:SetDetailEmpty(false)
    if entry.itemId and GQ.Data and GQ.Data.RequestItemInfo and GQ.Data.IsClientItemMissing
        and not GQ.Data:IsClientItemMissing(entry.itemId)
        and GQ.Data.ItemInfoIsReady and not GQ.Data:ItemInfoIsReady(entry.itemId) then
        GQ.Data:RequestItemInfo(entry.itemId, true)
    end
    local title = itemName:upper()
    if GQ.Data and GQ.Data.SanitizeText then
        title = GQ.Data:SanitizeText(title) or title
    end
    self.frame.detailTitle:SetText(title)
    self.frame.detailTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    self:LayoutDetailRank(self:HuntDisplayRank(entry), entry)

    local lore = entry.lore
    if self.frame.detailLore then
        if lore and lore ~= "" then
            self.frame.detailLore:SetText(GQ.Data:SanitizeText(lore) or lore)
            self.frame.detailLore:Show()
            self.frame.detailHeader:ClearAllPoints()
            self.frame.detailHeader:SetPoint("TOPLEFT", self.frame.detailLore, "BOTTOMLEFT", 0, -12)
        else
            self.frame.detailLore:SetText("")
            self.frame.detailLore:Hide()
            self.frame.detailHeader:ClearAllPoints()
            self.frame.detailHeader:SetPoint("TOPLEFT", self.frame.detailTitle, "BOTTOMLEFT", 0, -16)
        end
    end

    local lines, completedLine = self:BuildDetailLines(entry)
    local body = table.concat(lines, "\n")
    if GQ.Data and GQ.Data.SanitizeText then
        body = GQ.Data:SanitizeText(body) or body
    end
    self.frame.detailBody:SetText(body)

    self:UpdateDetailReward(entry)
    self:LayoutDetailCoords(entry, completedLine)
    self:UpdateDetailScrollHeight()
end

function GQ.Log:SelectHunt(id, scrollToSelection, entryOverride)
    local entry = entryOverride or GQ.Data:GetEntryById(id)
    if not entry then
        return
    end

    local targetTab = "active"
    if self:IsHuntRemoved(entry) then
        targetTab = "removed"
    elseif self:IsEntryObtained(id) then
        targetTab = "completed"
    end
    if self:GetListTab() ~= targetTab then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.listTab = targetTab
    end
    if self:GetPageTab() ~= "log" then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.pageTab = "log"
        self:HideSpecPicker()
        self:ApplyPageTab()
    end

    self.selectedHuntId = id
    self.selectedEntry = entry
    self.scrollListToSelected = scrollToSelection == true

    if entry.slot then
        self:SetSlotCollapsed(GQ.Data:NormalizeSlotName(entry.slot), false)
    end

    self:ApplyEntryDetail(entry)
    self:Refresh()
end

function GQ.Log:EntryShownOnActiveList(entry, slotName)
    if not entry then
        return false
    end
    if self:ShouldHideFromActiveList(entry, slotName) then
        return false
    end
    if self.SourceFilterActive and self:SourceFilterActive() and not self:EntrySourceAllowed(entry) then
        return false
    end
    if not self:EntryMatchesPlayStyle(entry) then
        return false
    end
    if not self:RangedPassesFilter(entry, slotName) then
        return false
    end
    return true
end

function GQ.Log:EntryInWeaponHand(entry, slotName, handKind)
    if self:IsWeaponHandKind(handKind) and handKind ~= "both" then
        return GQ.Data:WeaponFitsStyle(entry, handKind)
    end
    if handKind == "both" then
        return GQ.Data:EntryIsDamagingWeapon(entry)
    end
    if handKind == "main" then
        return GQ.Data:EntryIsMainHandOnly(entry)
    end
    if slotName == "SecondaryHand" then
        return GQ.Data:EntryIsEitherHand(entry)
    end
    return true
end

function GQ.Log:CollectWeaponCategory(slotName, handKind)
    local pool = {}
    for _, entry in ipairs(GQ.Data:GetCandidatesForSlot(slotName) or {}) do
        if self:EntryShownOnActiveList(entry, slotName) and self:EntryInWeaponHand(entry, slotName, handKind) then
            pool[#pool + 1] = entry
        end
    end
    local list = GQ.Data:TopUniqueEntries(pool, 3)
    if slotName == "MainHand" and GQ.Data.GetNotableForSlot then
        for _, entry in ipairs(GQ.Data:GetNotableForSlot(slotName) or {}) do
            if self:EntryShownOnActiveList(entry, slotName)
                and self:EntryInWeaponHand(entry, slotName, handKind) then
                local seen = false
                for i = 1, #list do
                    if list[i].itemId == entry.itemId then
                        seen = true
                        break
                    end
                end
                if not seen then
                    list[#list + 1] = entry
                end
                break
            end
        end
    end
    return list
end

function GQ.Log:ClearWeaponFilterCache()
    -- Style and type only. The weapon pool and every other slot's rank list stay.
    self._weaponFiltered = nil
    self._weaponStyleNow = nil
end

function GQ.Log:WeaponFilterRecord()
    if not GearQuestForeverDB then
        return nil
    end
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.weaponFilter = GearQuestForeverDB.settings.weaponFilter or {}
    local store = GearQuestForeverDB.settings.weaponFilter
    local classFile = (GQ.GetEffectiveClass and GQ:GetEffectiveClass()) or "?"
    local spec = (GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()) or "?"
    -- Simulation keeps its own checks. A warrior filter set while simulating
    -- does not apply to another simulated spec, or after simulation is off.
    local simulating = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    local key = (simulating and "sim:" or "play:") .. classFile .. ":" .. spec
    local rec = store[key]
    if not rec and not simulating then
        local old = store[classFile .. ":" .. spec]
        if type(old) == "table" then
            rec = old
            store[key] = rec
        end
    end
    if not rec then
        rec = {}
        store[key] = rec
    end
    return rec
end

function GQ.Log:CasterBisOffHand()
    if not (GQ.Data and GQ.Data.PairsWeaponWithOffHand and GQ.Data:PairsWeaponWithOffHand()) then
        return nil
    end
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._casterOffBand == ctx then
        return self._casterOffHand
    end
    local pool = {}
    local seen = {}
    local playerLevel = GQ:GetEffectiveLevel() or 1
    for _, key in ipairs(GQ.Data:GetCandidateSlotKeys("SecondaryHand") or {}) do
        for _, entry in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
            if entry and entry.id and not seen[entry.id]
                and not entry.healOnly
                and playerLevel >= (entry.minLevel or 1)
                and GQ.Data:ShouldShowEntry(entry)
                and GQ.Data:EntryMatchesPlayer(entry)
                and not GQ.Data:EntryIsDamagingWeapon(entry)
            then
                seen[entry.id] = true
                pool[#pool + 1] = entry
            end
        end
    end
    pool = GQ.Data:FilterToActiveBand(pool) or pool
    -- Same order as the off-hand rank list: stored rank, then score.
    -- The note names that rank 1 piece.
    local best
    for i = 1, #pool do
        local entry = pool[i]
        local score = entry.pipelineScore or 0
        local rank = entry.curatedRank or 99
        local bestRank = best and (best.curatedRank or 99) or 99
        local bestScore = best and (best.pipelineScore or 0) or 0
        if not best or rank < bestRank or (rank == bestRank and score > bestScore) then
            best = entry
        end
    end
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if classFile and GQ.Data.IsClassExpanded and not GQ.Data:IsClassExpanded(classFile) then
        return best
    end
    self._casterOffBand = ctx
    self._casterOffHand = best
    return best
end

function GQ.Log:WeaponCompareScore(entry)
    local score = entry and entry.pipelineScore or 0
    if not entry or not GQ.Data or not GQ.Data.PairsWeaponWithOffHand or not GQ.Data:PairsWeaponWithOffHand() then
        return score
    end
    if not GQ.Data:EntryIsDamagingWeapon(entry) or GQ.Data:EntryIsTwoHand(entry) or GQ.Data:EntryIsOffHandOnly(entry) then
        return score
    end
    local off = self:CasterBisOffHand()
    if not off or off.itemId == entry.itemId then
        return score
    end
    return score + (off.pipelineScore or 0)
end

function GQ.Log:OffHandPairNote(entry)
    if not entry or not self.WeaponCompareScore then
        return nil
    end
    if not GQ.Data or not GQ.Data.PairsWeaponWithOffHand or not GQ.Data:PairsWeaponWithOffHand() then
        return nil
    end
    if not GQ.Data:EntryIsDamagingWeapon(entry) or GQ.Data:EntryIsTwoHand(entry) or GQ.Data:EntryIsOffHandOnly(entry) then
        return nil
    end
    local off = self:CasterBisOffHand()
    if not off then
        return nil
    end
    local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(off)) or "the best off-hand"
    return "(only when combined with " .. name .. ")"
end

function GQ.Log:CollectWeaponPool()
    return GQ:WithContextSnapshot(self.BuildCollectWeaponPool, self)
end

function GQ.Log:BuildCollectWeaponPool()
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._weaponPool and self._weaponPoolBand == ctx then
        return self._weaponPool
    end
    local pool = {}
    local seen = {}
    local playerLevel = GQ:GetEffectiveLevel() or 1
    local equip = GQ.Equip
    local prevSuppress = equip and equip._suppressItemPrime
    if equip then
        equip._suppressItemPrime = true
    end
    local slots = { "MainHand", "SecondaryHand" }
    for s = 1, #slots do
        local slotName = slots[s]
        for _, key in ipairs(GQ.Data:GetCandidateSlotKeys(slotName) or {}) do
            for _, entry in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
                if entry and entry.id and not seen[entry.id]
                    and not entry.healOnly
                    and GQ.Data:ShouldShowEntry(entry)
                    and GQ.Data:EntryMatchesPlayer(entry)
                    and GQ.Data:EntryIsDamagingWeapon(entry)
                    and (not equip or not equip.EntryMatchesSpec or equip:EntryMatchesSpec(entry))
                    and (not equip or not equip.MeetsRequiredLevel or equip:MeetsRequiredLevel(entry.itemId, playerLevel))
                then
                    seen[entry.id] = true
                    pool[#pool + 1] = entry
                end
            end
        end
    end
    if equip then
        equip._suppressItemPrime = prevSuppress
    end
    -- Styles, types, and the (i) list are this level's band. Earlier bands stay out.
    pool = GQ.Data:FilterToActiveBand(pool) or pool
    table.sort(pool, function(a, b)
        local levelA = a.minLevel or 0
        local levelB = b.minLevel or 0
        if levelA ~= levelB then
            return levelA > levelB
        end
        local scoreA = self:WeaponCompareScore(a)
        local scoreB = self:WeaponCompareScore(b)
        if scoreA ~= scoreB then
            return scoreA > scoreB
        end
        return (a.curatedRank or 99) < (b.curatedRank or 99)
    end)
    self._weaponPoolBand = ctx
    self._weaponPool = pool
    return pool
end

function GQ.Log:BestOpenWeaponStyle(pool, hasTwo, hasOne)
    if hasTwo and not hasOne then
        return "two"
    end
    if hasOne and not hasTwo then
        return "one"
    end
    if not hasTwo and not hasOne then
        return GQ.Data:DefaultWeaponStyle()
    end
    local bestTwo, bestOne
    for i = 1, #pool do
        local entry = pool[i]
        local level = entry.minLevel or 0
        local score = self:WeaponCompareScore(entry)
        local two = GQ.Data:WeaponFitsStyle(entry, "two")
        local best = two and bestTwo or nil
        if not two then
            best = bestOne
        end
        if not best or level > best.level or (level == best.level and score > best.score) then
            best = { level = level, score = score }
            if two then
                bestTwo = best
            else
                bestOne = best
            end
        end
    end
    if bestTwo and not bestOne then
        return "two"
    end
    if bestOne and not bestTwo then
        return "one"
    end
    if bestTwo.level ~= bestOne.level then
        if bestTwo.level > bestOne.level then
            return "two"
        end
        return "one"
    end
    if bestTwo.score >= bestOne.score then
        return "two"
    end
    return "one"
end

function GQ.Log:PreferredWeaponStyle(pool, hasTwo, hasOne)
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = GQ.Data and GQ.Data.RuleSpec and GQ.Data:RuleSpec()
        or (GQ.GetEffectiveSpec and GQ:GetEffectiveSpec())
    if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" or (classFile == "DRUID" and spec ~= "feral") then
        return self:BestOpenWeaponStyle(pool, hasTwo, hasOne)
    end
    local style = GQ.Data:DefaultWeaponStyle()
    if style == "two" and not hasTwo and hasOne then
        return "one"
    end
    if style == "one" and not hasOne and hasTwo then
        return "two"
    end
    return style
end

function GQ.Log:WeaponStyle()
    if self._weaponStyleNow then
        return self._weaponStyleNow
    end
    local pool = self:CollectWeaponPool()
    local hasTwo, hasOne = false, false
    for i = 1, #pool do
        if GQ.Data:WeaponFitsStyle(pool[i], "two") then
            hasTwo = true
        else
            hasOne = true
        end
    end
    if GQ.Data:UsesTwoHandOnlyWeapons() then
        hasOne = false
    end
    local rec = self:WeaponFilterRecord()
    local style = rec and rec.style
    if style == "two" and not hasTwo and hasOne then
        style = nil
    end
    if style == "one" and (not hasOne or GQ.Data:UsesTwoHandOnlyWeapons()) then
        style = nil
    end
    if style ~= "two" and style ~= "one" then
        style = self:PreferredWeaponStyle(pool, hasTwo, hasOne)
    end
    if style ~= "two" and style ~= "one" then
        style = "two"
    end
    self._weaponStyleNow = style
    return style
end

function GQ.Log:IsWeaponHandKind(handKind)
    return handKind == "two" or handKind == "one" or handKind == "both"
end

function GQ.Log:IsWeaponFilterStyle(style)
    return style == "two" or style == "main" or style == "off"
end

-- A saved "one" checkbox is both hands for a dual-wield spec, and Main Hand
-- only when the off hand is a shield or held item.
function GQ.Log:LegacyOneHandEnables(style)
    if style == "main" then
        return true
    end
    if style == "off" then
        return GQ.Data:CanDualWield() and true or false
    end
    return false
end

function GQ.Log:WeaponStyleEnabled(style)
    if not self:IsWeaponFilterStyle(style) then
        return false
    end
    local available = self:WeaponStylesAvailable()
    local exists = false
    for i = 1, #available do
        if available[i] == style then
            exists = true
            break
        end
    end
    if not exists then
        return false
    end
    if GQ.Data:UsesTwoHandOnlyWeapons() then
        return style == "two"
    end
    local rec = self:WeaponFilterRecord()
    if rec and rec.styles then
        if rec.styles[style] ~= nil then
            return rec.styles[style] and true or false
        end
        if rec.styles.one ~= nil and rec.styles.main == nil and rec.styles.off == nil and style ~= "two" then
            return rec.styles.one and self:LegacyOneHandEnables(style)
        end
    end
    if GQ.Data.UsesBothWeaponStyles and GQ.Data:UsesBothWeaponStyles() then
        return true
    end
    local saved = rec and rec.style
    if saved == "one" and style ~= "two" then
        return self:LegacyOneHandEnables(style)
    end
    if saved == "two" then
        return style == "two"
    end
    if self:WeaponStyle() == "one" then
        return style ~= "two" and self:LegacyOneHandEnables(style)
    end
    return style == "two"
end

function GQ.Log:WeaponHeaderKind()
    local two = self:WeaponStyleEnabled("two")
    local one = self:WeaponStyleEnabled("main") or self:WeaponStyleEnabled("off")
    if two and one then
        return "both"
    end
    if one then
        return "one"
    end
    return "two"
end

function GQ.Log:WeaponTypeChecked(style, typeId)
    local rec = self:WeaponFilterRecord()
    local byStyle = rec and rec.typesByStyle
    local by = byStyle and byStyle[style]
    if by and by[typeId] ~= nil then
        return by[typeId] and true or false
    end
    -- Types saved under the old combined One-hand box apply to a hand that
    -- has not been changed yet.
    if not by and (style == "main" or style == "off") and byStyle and byStyle.one and byStyle.one[typeId] ~= nil then
        return byStyle.one[typeId] and true or false
    end
    if rec and rec.types and rec.types[typeId] ~= nil then
        local legacy = rec.style
        if legacy ~= "two" and legacy ~= "one" then
            legacy = self:WeaponStyle()
        end
        if legacy == style or (legacy == "one" and (style == "main" or style == "off")) then
            return rec.types[typeId] and true or false
        end
    end
    return true
end

function GQ.Log:WeaponFilterNarrowed()
    local available = self:WeaponStylesForMenu()
    for i = 1, #available do
        local style = available[i]
        if not self:WeaponStyleEnabled(style) then
            return true
        end
        if self:WeaponTypeFilterNarrowed(style) then
            return true
        end
    end
    return false
end

function GQ.Log:WeaponTypeFilterNarrowed(style)
    local available = self:WeaponTypesForStyle(style)
    for i = 1, #available do
        if not self:WeaponTypeChecked(style, available[i]) then
            return true
        end
    end
    return false
end

function GQ.Log:WeaponTypeAllowed(entry, style)
    if not entry then
        return false
    end
    if not style then
        style = GQ.Data:EntryIsTwoHand(entry) and "two" or "main"
    end
    local kind = GQ.Data:WeaponTypeOf(entry)
    if not kind then
        -- An unread type is not a selected type. It stays out once any box is off.
        return not self:WeaponTypeFilterNarrowed(style)
    end
    return self:WeaponTypeChecked(style, kind)
end

function GQ.Log:WeaponPassesFilter(entry)
    if not entry or not GQ.Data:EntryIsDamagingWeapon(entry) then
        return false
    end
    if GQ.Data:EntryIsTwoHand(entry) then
        if not self:WeaponStyleEnabled("two") then
            return false
        end
        return self:WeaponTypeAllowed(entry, "two")
    end
    -- A One-Hand weapon stays while either hand still allows that type.
    -- Main-hand-only leaves when Main Hand is off. Off-hand-only leaves
    -- when Off Hand is off.
    local hands = { "main", "off" }
    for i = 1, #hands do
        local hand = hands[i]
        if GQ.Data:WeaponCanEquipHand(entry, hand) and self:WeaponStyleEnabled(hand) and self:WeaponTypeAllowed(entry, hand) then
            return true
        end
    end
    return false
end

-- A hand or a type is listed only when a weapon of that kind still passes
-- the source filter and the play style. The weapon filter's own boxes do
-- not hide themselves. Rank numbers stay the full band.
function GQ.Log:WeaponMenuEntryVisible(entry)
    if not entry then
        return false
    end
    if self.EntrySourceAllowed and not self:EntrySourceAllowed(entry) then
        return false
    end
    if self.EntryMatchesPlayStyle and not self:EntryMatchesPlayStyle(entry) then
        return false
    end
    return true
end

function GQ.Log:WeaponTypesForStyle(style)
    local order = { "Dagger", "Sword", "Mace", "Axe", "Fist", "Polearm", "Staff" }
    local seen = {}
    local pool = self:CollectWeaponPool()
    for i = 1, #pool do
        if self:WeaponMenuEntryVisible(pool[i]) and GQ.Data:WeaponCanEquipHand(pool[i], style) then
            local kind = GQ.Data:WeaponTypeOf(pool[i])
            if kind then
                seen[kind] = true
            end
        end
    end
    local out = {}
    for i = 1, #order do
        if seen[order[i]] then
            out[#out + 1] = order[i]
        end
    end
    return out
end

function GQ.Log:WeaponStylesAvailable()
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._weaponStyles and self._weaponStylesBand == ctx then
        return self._weaponStyles
    end
    local pool = self:CollectWeaponPool()
    local hasTwo, hasMain, hasOff = false, false, false
    for i = 1, #pool do
        local entry = pool[i]
        if GQ.Data:WeaponCanEquipHand(entry, "two") then
            hasTwo = true
        end
        if GQ.Data:WeaponCanEquipHand(entry, "main") then
            hasMain = true
        end
        if GQ.Data:WeaponCanEquipHand(entry, "off") then
            hasOff = true
        end
    end
    local out = {}
    if hasTwo then
        out[#out + 1] = "two"
    end
    if hasMain then
        out[#out + 1] = "main"
    end
    if hasOff then
        out[#out + 1] = "off"
    end
    self._weaponStylesBand = ctx
    self._weaponStyles = out
    return out
end

-- Hands shown in the menu. A hand with nothing left after the source filter
-- and the play style is left out. The saved check stays, so the hand comes
-- back the way the player left it. Rank checks still use the full band.
function GQ.Log:WeaponStylesForMenu()
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._weaponMenuStyles and self._weaponMenuStylesBand == ctx then
        return self._weaponMenuStyles
    end
    local pool = self:CollectWeaponPool()
    local hasTwo, hasMain, hasOff = false, false, false
    for i = 1, #pool do
        local entry = pool[i]
        if self:WeaponMenuEntryVisible(entry) then
            if GQ.Data:WeaponCanEquipHand(entry, "two") then
                hasTwo = true
            end
            if GQ.Data:WeaponCanEquipHand(entry, "main") then
                hasMain = true
            end
            if GQ.Data:WeaponCanEquipHand(entry, "off") then
                hasOff = true
            end
        end
    end
    local out = {}
    if hasTwo then
        out[#out + 1] = "two"
    end
    if hasMain then
        out[#out + 1] = "main"
    end
    if hasOff then
        out[#out + 1] = "off"
    end
    self._weaponMenuStylesBand = ctx
    self._weaponMenuStyles = out
    return out
end

function GQ.Log:UnfilteredWeaponList()
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._weaponTrueList and self._weaponTrueBand == ctx then
        return self._weaponTrueList
    end
    local pool = self:CollectWeaponPool()
    local list = {}
    local seenName = {}
    for i = 1, #pool do
        local entry = pool[i]
        local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)) or ""
        if name == "" or not seenName[name] then
            if name ~= "" then
                seenName[name] = true
            end
            list[#list + 1] = entry
        end
    end
    self._weaponTrueBand = ctx
    self._weaponTrueList = list
    return list
end

function GQ.Log:WeaponTrueRank(entry)
    if not entry then
        return nil
    end
    local list = self:UnfilteredWeaponList()
    local suffix = entry.suffix or ""
    for i = 1, #list do
        local row = list[i]
        if row == entry or row.id == entry.id
            or (row.itemId == entry.itemId and (row.suffix or "") == suffix and row.minLevel == entry.minLevel) then
            return i
        end
    end
    return nil
end

function GQ.Log:WeaponShownInHunt(entry)
    if not self:WeaponPassesFilter(entry) then
        return false
    end
    if self.EntrySourceAllowed and not self:EntrySourceAllowed(entry) then
        return false
    end
    if self.EntryMatchesPlayStyle and not self:EntryMatchesPlayStyle(entry) then
        return false
    end
    local slotName = (GQ.Data.NormalizeSlotName and GQ.Data:NormalizeSlotName(entry.slot)) or "MainHand"
    if self:EntryHiddenFromActiveFast(entry, slotName) then
        return false
    end
    return true
end

function GQ.Log:FilteredWeaponEntries()
    if self._weaponFiltered then
        return self._weaponFiltered
    end
    local pool = self:CollectWeaponPool()
    local picked = {}
    local seenName = {}
    local limit = self:HuntsPerSlot()
    for i = 1, #pool do
        if #picked >= limit then
            break
        end
        local entry = pool[i]
        if self:WeaponShownInHunt(entry) then
            local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)) or ""
            if name == "" or not seenName[name] then
                if name ~= "" then
                    seenName[name] = true
                end
                picked[#picked + 1] = entry
            end
        end
    end
    self._weaponFiltered = picked
    return picked
end

function GQ.Log:HeldOffHandEntries()
    local ctx = self.GetActiveListCacheContextKey and self:GetActiveListCacheContextKey() or ""
    if self._heldOffHand and self._heldOffBand == ctx then
        return self._heldOffHand
    end
    local pool = {}
    local seen = {}
    local playerLevel = GQ:GetEffectiveLevel() or 1
    for _, key in ipairs(GQ.Data:GetCandidateSlotKeys("SecondaryHand") or {}) do
        for _, entry in ipairs(GQ.Data:GetClassSlotEntryList(key) or {}) do
            if entry and entry.id and not seen[entry.id]
                and not entry.healOnly
                and playerLevel >= (entry.minLevel or 1)
                and not GQ.Data:EntryIsDamagingWeapon(entry)
                and self:EntrySourceAllowed(entry)
                and self:EntryMatchesPlayStyle(entry)
                and not self:EntryHiddenFromActiveFast(entry, "SecondaryHand")
                and GQ.Data:ShouldShowEntry(entry)
                and GQ.Data:EntryMatchesPlayer(entry)
            then
                seen[entry.id] = true
                pool[#pool + 1] = entry
            end
        end
    end
    table.sort(pool, function(a, b)
        local levelA = a.minLevel or 0
        local levelB = b.minLevel or 0
        if levelA ~= levelB then
            return levelA > levelB
        end
        local scoreA = a.pipelineScore or 0
        local scoreB = b.pipelineScore or 0
        if scoreA ~= scoreB then
            return scoreA > scoreB
        end
        return (a.curatedRank or 99) < (b.curatedRank or 99)
    end)
    local picked = {}
    local seenName = {}
    local limit = self:HuntsPerSlot()
    for i = 1, #pool do
        if #picked >= limit then
            break
        end
        local entry = pool[i]
        local name = (GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)) or ""
        if name == "" or not seenName[name] then
            if name ~= "" then
                seenName[name] = true
            end
            picked[#picked + 1] = entry
        end
    end
    -- A class that is still loading has an empty slot list. Caching that
    -- empty list kept the Off Hand section blank after the data arrived.
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if classFile and GQ.Data.IsClassExpanded and not GQ.Data:IsClassExpanded(classFile) then
        return picked
    end
    self._heldOffBand = ctx
    self._heldOffHand = picked
    return picked
end

function GQ.Log:ToggleWeaponStyle(style)
    local rec = self:WeaponFilterRecord()
    if not rec or not self:IsWeaponFilterStyle(style) then
        return
    end
    local now = {
        two = self:WeaponStyleEnabled("two"),
        main = self:WeaponStyleEnabled("main"),
        off = self:WeaponStyleEnabled("off"),
    }
    now[style] = not now[style]
    rec.styles = now
    rec.style = nil
    self:ClearWeaponFilterCache()
    if GQ.Data.ClearTopUpgradeCache then
        GQ.Data:ClearTopUpgradeCache()
    end
    self._reopenWeaponMenu = true
    self:Refresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

function GQ.Log:ToggleWeaponType(typeId, style)
    local rec = self:WeaponFilterRecord()
    if not rec or not self:IsWeaponFilterStyle(style) then
        return
    end
    rec.typesByStyle = rec.typesByStyle or {}
    local map = rec.typesByStyle[style]
    if not map then
        map = {}
        local available = self:WeaponTypesForStyle(style)
        for i = 1, #available do
            map[available[i]] = self:WeaponTypeChecked(style, available[i])
        end
        rec.typesByStyle[style] = map
    end
    if map[typeId] == nil then
        map[typeId] = true
    end
    map[typeId] = not map[typeId]
    self:ClearWeaponFilterCache()
    if GQ.Data.ClearTopUpgradeCache then
        GQ.Data:ClearTopUpgradeCache()
    end
    self._reopenWeaponMenu = true
    self:Refresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

function GQ.Log:HunterRangedFilter()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    return classFile == "HUNTER"
end

function GQ.Log:RangedTypesAvailable()
    local order = { "Bow", "Gun", "Crossbow" }
    local seen = {}
    local list = self:GetSlotRankList("Ranged")
    for i = 1, list and #list or 0 do
        if self:WeaponMenuEntryVisible(list[i]) then
            local kind = GQ.Data.RangedTypeOf and GQ.Data:RangedTypeOf(list[i])
            if kind then
                seen[kind] = true
            end
        end
    end
    local out = {}
    for i = 1, #order do
        if seen[order[i]] then
            out[#out + 1] = order[i]
        end
    end
    return out
end

function GQ.Log:RangedTypeChecked(typeId)
    local rec = self:WeaponFilterRecord()
    local map = rec and rec.ranged
    if map and map[typeId] ~= nil then
        return map[typeId] and true or false
    end
    return true
end

function GQ.Log:RangedFilterNarrowed()
    if not self:HunterRangedFilter() then
        return false
    end
    local available = self:RangedTypesAvailable()
    for i = 1, #available do
        if not self:RangedTypeChecked(available[i]) then
            return true
        end
    end
    return false
end

function GQ.Log:RangedPassesFilter(entry, slotName)
    if not self:HunterRangedFilter() then
        return true
    end
    local slot = slotName or (entry and GQ.Data.NormalizeSlotName and GQ.Data:NormalizeSlotName(entry.slot))
    if slot ~= "Ranged" then
        return true
    end
    if not self:RangedFilterNarrowed() then
        return true
    end
    local kind = GQ.Data.RangedTypeOf and GQ.Data:RangedTypeOf(entry)
    if not kind then
        return false
    end
    return self:RangedTypeChecked(kind)
end

function GQ.Log:ToggleRangedType(typeId)
    local rec = self:WeaponFilterRecord()
    if not rec or not self:HunterRangedFilter() then
        return
    end
    rec.ranged = rec.ranged or {}
    if rec.ranged[typeId] == nil then
        rec.ranged[typeId] = true
    end
    rec.ranged[typeId] = not rec.ranged[typeId]
    if GQ.Data.ClearTopUpgradeCache then
        GQ.Data:ClearTopUpgradeCache()
    end
    self._reopenRangedMenu = true
    self:Refresh()
    if GQ.Indicator and GQ.Indicator.ScheduleRebuildCache then
        GQ.Indicator:ScheduleRebuildCache()
    end
end

function GQ.Log:EnsureWeaponMenu()
    if self.weaponMenu then
        return self.weaponMenu
    end
    local menu = CreateFrame("Frame", "GearQuestWeaponMenu", self.frame or UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(50)
    menu:EnableMouse(true)
    menu:SetClampedToScreen(true)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if menu.SetBackdropColor then
        menu:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if menu.SetBackdropBorderColor then
        menu:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    menu.checks = {}
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function()
        menu:Hide()
    end)
    menu.catcher = catcher
    menu:SetScript("OnShow", function(self)
        self:SetFrameStrata("TOOLTIP")
        self:SetFrameLevel(80)
        if self.catcher then
            self.catcher:SetFrameLevel(self:GetFrameLevel() - 1)
            self.catcher:Show()
        end
    end)
    menu:SetScript("OnHide", function(self)
        if self.catcher then
            self.catcher:Hide()
        end
    end)
    menu:Hide()
    self.weaponMenu = menu
    return menu
end

function GQ.Log:FillWeaponMenu()
    local menu = self:EnsureWeaponMenu()
    local styles = self:WeaponStylesForMenu()
    local lines = {}
    for i = 1, #styles do
        local styleId = styles[i]
        lines[#lines + 1] = { kind = "style", id = styleId, style = styleId, indent = 0 }
        local types = self:WeaponTypesForStyle(styleId)
        for t = 1, #types do
            lines[#lines + 1] = { kind = "type", id = types[t], style = styleId, indent = 18 }
        end
    end
    local width = 168
    for i = 1, #lines do
        local check = menu.checks[i]
        if not check then
            check = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
            check:SetSize(22, 22)
            check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            check.label:SetJustifyH("LEFT")
            check:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log then
                    return
                end
                if self.kind == "style" then
                    log:ToggleWeaponStyle(self.choiceId)
                elseif self.kind == "ranged" then
                    log:ToggleRangedType(self.choiceId)
                else
                    log:ToggleWeaponType(self.choiceId, self.styleId)
                end
            end)
            menu.checks[i] = check
        end
        local line = lines[i]
        check.kind = line.kind
        check.choiceId = line.id
        check.styleId = line.style
        local indent = line.indent or 0
        local name
        local checked
        if line.kind == "style" then
            if line.id == "two" then
                name = "Two-hand"
            elseif line.id == "main" then
                name = "Main Hand"
            elseif line.id == "off" then
                name = "Off Hand"
            else
                name = line.id
            end
            checked = self:WeaponStyleEnabled(line.id)
            check.label:SetTextColor(1, 0.82, 0)
        else
            name = (line.id == "Fist") and "Fist Weapon" or line.id
            checked = self:WeaponTypeChecked(line.style, line.id)
            if self:WeaponStyleEnabled(line.style) then
                check.label:SetTextColor(1, 1, 1)
            else
                check.label:SetTextColor(0.55, 0.55, 0.55)
            end
        end
        check.label:SetText(name)
        check:SetChecked(checked)
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", menu, "TOPLEFT", 8 + indent, -8 - ((i - 1) * 20))
        local rowWidth = 36 + indent + (check.label:GetStringWidth() or 60)
        if rowWidth > width then
            width = rowWidth
        end
        check:SetHitRectInsets(0, -((check.label:GetStringWidth() or 60) + 12), -1, -1)
        check:Show()
    end
    for i = #lines + 1, #menu.checks do
        menu.checks[i]:Hide()
    end
    menu:SetSize(width + 12, 16 + (math.max(#lines, 1) * 20))
end

function GQ.Log:ShowWeaponMenu(anchor)
    if not anchor then
        return
    end
    local menu = self:EnsureWeaponMenu()
    self:FillWeaponMenu()
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -2)
    menu:Show()
end

function GQ.Log:FillRangedMenu()
    local menu = self:EnsureWeaponMenu()
    local types = self:RangedTypesAvailable()
    local width = 140
    for i = 1, #types do
        local check = menu.checks[i]
        if not check then
            check = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
            check:SetSize(22, 22)
            check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            check.label:SetJustifyH("LEFT")
            check:SetScript("OnClick", function(self)
                local log = _G.GearQuest and _G.GearQuest.Log
                if not log then
                    return
                end
                if self.kind == "style" then
                    log:ToggleWeaponStyle(self.choiceId)
                elseif self.kind == "ranged" then
                    log:ToggleRangedType(self.choiceId)
                else
                    log:ToggleWeaponType(self.choiceId, self.styleId)
                end
            end)
            menu.checks[i] = check
        end
        local typeId = types[i]
        check.kind = "ranged"
        check.choiceId = typeId
        check.styleId = nil
        check.label:SetText(typeId)
        check.label:SetTextColor(1, 1, 1)
        check:SetChecked(self:RangedTypeChecked(typeId))
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -8 - ((i - 1) * 20))
        local rowWidth = 36 + (check.label:GetStringWidth() or 60)
        if rowWidth > width then
            width = rowWidth
        end
        check:SetHitRectInsets(0, -((check.label:GetStringWidth() or 60) + 12), -1, -1)
        check:Show()
    end
    for i = #types + 1, #menu.checks do
        menu.checks[i]:Hide()
    end
    menu:SetSize(width + 12, 16 + (math.max(#types, 1) * 20))
end

function GQ.Log:ShowRangedMenu(anchor)
    if not anchor then
        return
    end
    local menu = self:EnsureWeaponMenu()
    self:FillRangedMenu()
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -2)
    menu:Show()
end

function GQ.Log:ToggleRangedMenu(anchor)
    local menu = self:EnsureWeaponMenu()
    if menu:IsShown() then
        menu:Hide()
        return
    end
    self:ShowRangedMenu(anchor)
end

function GQ.Log:ToggleWeaponMenu(anchor)
    local menu = self:EnsureWeaponMenu()
    if menu:IsShown() then
        menu:Hide()
        return
    end
    self:ShowWeaponMenu(anchor)
end

function GQ.Log:AppendListedEntries(layoutRows, entries, slotName)
    for _, entry in ipairs(entries) do
        local rowType = GQ.Data:ShouldDisplayAsNotable(entry, slotName) and "notable" or "item"
        layoutRows[#layoutRows + 1] = { type = rowType, slotName = slotName, entry = entry }
    end
end

function GQ.Log:Refresh()
    if self:GetPageTab() == "lookup" then
        self:RefreshLookup()
        if GQ.Custom and GQ.Custom.NoteListPainted then
            GQ.Custom:NoteListPainted()
        end
        return
    end
    local tab = self:GetListTab()
    if self._refreshPainting then
        self._refreshPainting = nil
    elseif tab == "active" and not self:RankListsReady() and C_Timer and C_Timer.After and self.frame then
        self:UpdateTabVisuals()
        self:UpdateFooterButtons()
        self:UpdateContextStatus()
        self:ScheduleRankListWarm()
        return
    end
    self:HideSpecPicker()
    self:UpdateLogScene()
    self:EnsureActiveListCaches()
    self:ClearWeaponFilterCache()

    local classFile = GQ:GetEffectiveClass()
    local slots = GQ.Data:GetSlotsForClass(classFile)
    local layoutRows = {}
    local rowIndex = 0
    local yOffset = 0
    local selectedLayoutIndex
    local tab = self:GetListTab()

    self:UpdateTabVisuals()
    self:UpdateFooterButtons()
    self:UpdateContextStatus()

    if tab == "completed" then
        local anyCompleted = false

        for _, slotName in ipairs(slots) do
            local completed = self:GetCompletedSlotListEntries(slotName)
            if #completed > 0 then
                anyCompleted = true
                table.insert(layoutRows, { type = "header", slotName = slotName })

                if not self:IsSlotCollapsed(slotName, completed) then
                    for _, entry in ipairs(completed) do
                        table.insert(layoutRows, { type = "item", slotName = slotName, entry = entry })
                    end
                end
            end
        end

        if not anyCompleted then
            table.insert(layoutRows, { type = "empty_all" })
        end
    elseif tab == "removed" then
        local anyRemoved = false

        for _, slotName in ipairs(slots) do
            local removed = self:GetRemovedSlotListEntries(slotName)
            if #removed > 0 then
                anyRemoved = true
                table.insert(layoutRows, { type = "header", slotName = slotName })

                if not self:IsSlotCollapsed(slotName, removed) then
                    for _, entry in ipairs(removed) do
                        table.insert(layoutRows, { type = "item", slotName = slotName, entry = entry })
                    end
                end
            end
        end

        if not anyRemoved then
            table.insert(layoutRows, { type = "empty_all" })
        end
    else
        for _, slotName in ipairs(slots) do
            if slotName == "MainHand" then
                local handKind = self:WeaponHeaderKind()
                local weapons = self:FilteredWeaponEntries()
                table.insert(layoutRows, { type = "header", slotName = "MainHand", label = "Weapons", handKind = handKind })
                if #weapons > 0 and not self:IsSlotCollapsed("MainHand", weapons) then
                    for _, entry in ipairs(weapons) do
                        local rowType = GQ.Data:ShouldDisplayAsNotable(entry, "MainHand") and "notable" or "item"
                        table.insert(layoutRows, { type = rowType, slotName = "MainHand", entry = entry, handKind = handKind })
                    end
                end
            elseif slotName == "SecondaryHand" then
                if not GQ.Data:UsesTwoHandOnlyWeapons() then
                    local held = self:HeldOffHandEntries()
                    if #held > 0 or GQ.Data:OffHandShowsShieldOrHeld() then
                        table.insert(layoutRows, { type = "header", slotName = "SecondaryHand" })
                        if #held > 0 and not self:IsSlotCollapsed("SecondaryHand", held) then
                            self:AppendListedEntries(layoutRows, held, "SecondaryHand")
                        end
                    end
                end
            else
                local upgrades = self:GetActiveSlotListEntries(slotName)
                table.insert(layoutRows, { type = "header", slotName = slotName })

                if #upgrades > 0 and not self:IsSlotCollapsed(slotName, upgrades) then
                    for _, entry in ipairs(upgrades) do
                        local rowType = GQ.Data:ShouldDisplayAsNotable(entry, slotName) and "notable" or "item"
                        table.insert(layoutRows, { type = rowType, slotName = slotName, entry = entry })
                    end
                end
            end
        end
    end

    self:UpdateHuntAdvice(layoutRows, tab)

    for i, spec in ipairs(layoutRows) do
        if spec.entry then
            PrimeListEntryItemInfo(spec.entry)
        end
        if not self.listRows[i] then
            self.listRows[i] = self:CreateListRow(i)
        end
        local ok, err = pcall(self.ConfigureRow, self, self.listRows[i], yOffset, spec.type, spec.slotName, spec.entry, spec.label, spec.handKind)
        if not ok then
            GQ:Chat("|cffff0000GearQuest row error:|r " .. tostring(err))
        end
        if self.selectedHuntId and spec.entry and (spec.type == "item" or spec.type == "notable") then
            local selected = spec.entry.id == self.selectedHuntId
            if not selected and self.selectedEntry then
                local entryKey = GQ.Data:EntryListKey(spec.entry)
                local selectedKey = GQ.Data:EntryListKey(self.selectedEntry)
                selected = entryKey and selectedKey and entryKey == selectedKey
            end
            if selected then
                selectedLayoutIndex = i
            end
        end
        yOffset = yOffset + (self.listRows[i]._listHeight or ROW_HEIGHT)
        if spec.type == "item" or spec.type == "notable" then
            yOffset = yOffset + (self.HUNT_ROW_GAP or 4)
        end
        rowIndex = i
    end

    for i = rowIndex + 1, #self.listRows do
        self.listRows[i]:Hide()
    end

    if self._reopenRangedMenu then
        self._reopenRangedMenu = nil
        for i = 1, #self.listRows do
            local row = self.listRows[i]
            if row:IsShown() and row.slotName == "Ranged" and row.weaponArrow and row.weaponArrow:IsShown() then
                self:ShowRangedMenu(row.weaponArrow)
                break
            end
        end
    elseif self._reopenWeaponMenu then
        self._reopenWeaponMenu = nil
        for i = 1, #self.listRows do
            local row = self.listRows[i]
            if row:IsShown() and row.slotName ~= "Ranged" and row.weaponArrow and row.weaponArrow:IsShown() then
                self:ShowWeaponMenu(row.weaponArrow)
                break
            end
        end
    elseif self.weaponMenu then
        self.weaponMenu:Hide()
    end

    self.frame.scrollChild:SetHeight(math.max(yOffset, 1))
    UpdateScrollChildRect(self.frame.scroll)

    ConfigurePanelScrollBar(self.frame.scroll)
    self:UpdateDetailScrollHeight()
    LayoutDetailScroll(self.frame)
    self:ApplyPageTab()
    self:ClampListRowMouse()
    if GQ.Custom and GQ.Custom.NoteListPainted then
        GQ.Custom:NoteListPainted()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if GQ.Log and GQ.Log.ClampListRowMouse then
                GQ.Log:ClampListRowMouse()
            end
        end)
    end

    if self.scrollListToSelected and selectedLayoutIndex then
        local layoutIndex = selectedLayoutIndex
        self.scrollListToSelected = false
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self.frame and self.frame:IsShown() then
                    self:ScrollListToRow(layoutIndex)
                end
            end)
        else
            self:ScrollListToRow(layoutIndex)
        end
    end

    if self.selectedHuntId then
        local record = GetHuntRecord(self.selectedHuntId)
        local entry = self.selectedEntry or GQ.Data:GetEntryById(self.selectedHuntId)
        local status = record and NormalizeHuntStatus(record.status)
        local clearSelection = false

        if not entry then
            clearSelection = true
        elseif tab == "completed" and status ~= "completed" and not self:IsEntryObtained(self.selectedHuntId) then
            clearSelection = true
        elseif tab == "removed" and not self:IsHuntRemoved(entry) then
            clearSelection = true
        elseif tab == "active" and (status == "completed" or self:IsHuntRemoved(entry)) then
            clearSelection = true
        elseif tab == "active" and not self:EntrySourceAllowed(entry) then
            clearSelection = true
        elseif tab == "active" and not self:EntryMatchesPlayStyle(entry) then
            clearSelection = true
        end

        if clearSelection then
            self.selectedHuntId = nil
            self.selectedEntry = nil
            self:ClearDetail()
        end
    end
end

function GQ.Log:ClampListRowMouse()
    local scroll = self.frame and self.frame.scroll
    if not scroll or not self.listRows then
        return
    end
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    if not scrollTop or not scrollBottom then
        return
    end
    for _, row in ipairs(self.listRows) do
        if row:IsShown() and row.EnableMouse then
            local rowTop = row:GetTop()
            local rowBottom = row:GetBottom()
            local overlaps = rowTop and rowBottom and rowBottom < scrollTop and rowTop > scrollBottom
            row:EnableMouse(overlaps and true or false)
            if overlaps and row.SetHitRectInsets then
                row:SetHitRectInsets(0, 0, math.max(0, rowTop - scrollTop), math.max(0, scrollBottom - rowBottom))
            end
        end
    end
end

-- The log sits on DIALOG, above the profession book. List rows also stick out
-- of the scroll and keep taking clicks. Drop both while that book is open.
function GQ.Log:ReleaseMouseForGameUI()
    if self._specPickerCatcher then
        self._specPickerCatcher:Hide()
    end
    local orphan = _G.GearQuestSpecPickerCatcher
    if orphan and orphan.IsShown and orphan:IsShown() then
        orphan:Hide()
    end
    local frame = self.frame
    if frame and frame:IsShown() then
        if frame.SetFrameStrata then
            frame:SetFrameStrata("MEDIUM")
        end
        if frame.SetFrameLevel then
            frame:SetFrameLevel(1)
        end
        local rail = frame.sideTabRail
        if rail and rail.SetFrameStrata then
            rail:SetFrameStrata("MEDIUM")
        end
    end
    self:ClampListRowMouse()
    self:RefreshProfessionBranch()
end

function GQ.Log:WindowScale()
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    local percent = settings and tonumber(settings.windowScalePercent)
    if not percent and settings and settings.largeWindow then
        percent = 150
    end
    percent = math.floor((tonumber(percent) or 100) + 0.5)
    if percent < 100 then
        percent = 100
    elseif percent > 150 then
        percent = 150
    end
    return percent / 100
end

function GQ.Log:ApplyWindowScale()
    local scale = self:WindowScale()
    local frame = self.frame
    if frame and frame.SetScale then
        frame:SetScale(scale)
        if frame.SetClampedToScreen then
            frame:SetClampedToScreen(true)
        end
    end
    -- Filter, its flyouts, the weapon filter, the spec picker, and Play style
    -- are children of the log, so they use this scale. The (i) list is not.
    local rank = self.slotRankPanel
    if rank and rank.SetScale then
        rank:SetScale(scale)
    end
end

function GQ.Log:Show()
    if not self.frame then
        return
    end

    self:ApplyWindowScale()
    ApplyModernChrome(self.frame)
    ApplyParchmentBackground(self.frame.detailBg)
    self:LayoutMainWindow(self.frame)
    LayoutDetailScroll(self.frame)
    BringLogWindowToFront(self.frame)
    self.frame:Show()
    if self:GetPageTab() == "simulator" then
        self:SeedSimulatorFromCharacter()
        self:RefreshSimulator()
    end
    if GQ.Custom and GQ.Custom.EnsureBuilt and GQ.GetEffectiveClass and GQ.GetEffectiveSpec then
        local classFile = GQ:GetEffectiveClass()
        local specId = GQ:GetEffectiveSpec()
        if classFile and specId and GQ.Custom:Get(classFile, specId) then
            GQ.Custom:EnsureBuilt(classFile, specId)
        end
    end
    if GQ.Custom and GQ.Custom.ShowWorking and (GQ.Custom._job or GQ.Custom._awaitList) then
        GQ.Custom:ShowWorking()
    end
    self:LayoutSideTabs(self.frame)
    self:EnsureCoordinateWatch()

    local refreshOk, refreshErr = pcall(function()
        self:Refresh()
    end)
    if not refreshOk then
        GQ:Chat("|cffff0000GearQuest log error:|r " .. tostring(refreshErr))
    end

    self:ScheduleAutoCompletionCheck()
    if self.GamepadAcquire then
        self:GamepadAcquire()
    end
    if GQ.PortraitGuide and GQ.PortraitGuide.OnLogShown then
        GQ.PortraitGuide:OnLogShown(self.frame)
    end
end

function GQ.Log:LookupClassName()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local name = classFile
    if GQ.Preview and GQ.Preview.FormatClassName and classFile then
        name = GQ.Preview:FormatClassName(classFile)
    elseif classFile then
        name = classFile:sub(1, 1) .. classFile:sub(2):lower()
    end
    return name or "this class", classFile
end

function GQ.Log:LookupSpecLabel(entry, classFile)
    local specId
    if entry and entry.specs then
        for id in pairs(entry.specs) do
            specId = id
            break
        end
    end
    if not specId then
        return "All specs"
    end
    local options = GQ.Spec and GQ.Spec.GetOptions and GQ.Spec:GetOptions(classFile)
    if options then
        for i = 1, #options do
            if options[i].id == specId then
                return options[i].label or specId
            end
        end
    end
    return specId
end

function GQ.Log:LookupFactionLabel(entry)
    local factions = entry and entry.factions
    if not factions then
        return "both"
    end
    local alliance = factions.Alliance
    local horde = factions.Horde
    if alliance and horde then
        return "both"
    end
    if alliance then
        return "Alliance"
    end
    if horde then
        return "Horde"
    end
    return "both"
end

function GQ.Log:LookupDisplayName(entry)
    local base = entry and entry.name
    if (not base or base == "") and entry and entry.itemId and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        base = fact and fact.name
    end
    if not base or base == "" then
        base = "Item " .. tostring(entry and entry.itemId or "?")
    end
    local suffix = entry and entry.suffix
    if suffix and suffix ~= "" then
        suffix = tostring(suffix)
        if suffix:sub(1, 1) ~= " " then
            suffix = " " .. suffix
        end
        return base .. suffix
    end
    return base
end

-- The catalog is every level band for the class. Walking it on the search
-- click froze the frame. Two thousand rows a frame stays inside the budget.
function GQ.Log:EnsureLookupIndex(classFile, onReady)
    if self._lookupIndex and self._lookupIndexClass == classFile and not self._lookupBuild then
        if onReady then
            onReady()
        end
        return
    end
    self._lookupReady = self._lookupReady or {}
    if onReady then
        self._lookupReady[#self._lookupReady + 1] = onReady
    end
    if self._lookupBuild and self._lookupBuild.classFile == classFile then
        return
    end
    if GQ.Data and GQ.Data.EnsureClassLoaded and classFile then
        GQ.Data:EnsureClassLoaded(classFile)
    end
    local first, last = 1, 0
    local span = GQ.Data and GQ.Data._classEntrySpan and GQ.Data._classEntrySpan[classFile]
    local entries = GQ.Data and GQ.Data.entries
    if span then
        first, last = span[1], span[2]
    elseif entries then
        last = #entries
    end
    if last < first then
        last = first - 1
    end
    self._lookupIndex = {}
    self._lookupIndexClass = classFile
    self._lookupBuild = {
        classFile = classFile,
        i = first,
        last = last,
        items = {},
        generation = GQ.Data and GQ.Data._entryGeneration or 0,
    }
    self:StepLookupIndex()
end

function GQ.Log:FinishLookupIndex()
    self._lookupBuild = nil
    local ready = self._lookupReady
    self._lookupReady = nil
    if not ready then
        return
    end
    for i = 1, #ready do
        ready[i]()
    end
end

function GQ.Log:StepLookupIndex()
    local build = self._lookupBuild
    if not build then
        return
    end
    local generation = GQ.Data and GQ.Data._entryGeneration or 0
    if build.generation ~= generation then
        local classFile = build.classFile
        self._lookupBuild = nil
        self._lookupIndex = nil
        self._lookupIndexClass = nil
        self:EnsureLookupIndex(classFile)
        return
    end
    local entries = GQ.Data and GQ.Data.entries
    local classFile = build.classFile
    local items = build.items
    local order = self._lookupIndex
    local stop = build.i + 1999
    if stop > build.last then
        stop = build.last
    end
    for i = build.i, stop do
        local entry = entries and entries[i]
        if entry and entry.classes and classFile and entry.classes[classFile] and entry.itemId then
            local suffix = entry.suffix or ""
            local key = tostring(entry.itemId) .. "\0" .. tostring(suffix)
            local row = items[key]
            if not row then
                local name = self:LookupDisplayName(entry)
                row = {
                    key = key,
                    itemId = entry.itemId,
                    name = name,
                    nameLower = string.lower(name),
                    entries = {},
                }
                items[key] = row
                order[#order + 1] = row
            end
            row.entries[#row.entries + 1] = entry
        end
    end
    if stop >= build.last then
        self:FinishLookupIndex()
        return
    end
    build.i = stop + 1
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if GQ.Log then
                GQ.Log:StepLookupIndex()
            end
        end)
    else
        self:StepLookupIndex()
    end
end

function GQ.Log:LookupDetailEntry(item)
    local entries = item and item.entries
    if not entries or #entries == 0 then
        return nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
    local best = entries[1]
    for i = 2, #entries do
        local entry = entries[i]
        local bestSide = best.factions and faction and best.factions[faction]
        local side = entry.factions and faction and entry.factions[faction]
        local take = false
        if side and not bestSide then
            take = true
        elseif side == bestSide then
            local rank = entry.curatedRank or 99
            local bestRank = best.curatedRank or 99
            if rank < bestRank then
                take = true
            elseif rank == bestRank and (entry.minLevel or 0) < (best.minLevel or 0) then
                take = true
            end
        end
        if take then
            best = entry
        end
    end
    return best
end

function GQ.Log:LookupRankLines(item, classFile)
    local groups = {}
    local entries = item.entries or {}
    for i = 1, #entries do
        local entry = entries[i]
        local spec = self:LookupSpecLabel(entry, classFile)
        local faction = self:LookupFactionLabel(entry)
        local rank = entry.curatedRank or 0
        local key = spec .. "\0" .. faction .. "\0" .. tostring(rank)
        local group = groups[key]
        if not group then
            group = { spec = spec, faction = faction, rank = rank, ranges = {} }
            groups[key] = group
        end
        local minLevel = entry.minLevel or 0
        local maxLevel = entry.maxLevel or minLevel
        group.ranges[#group.ranges + 1] = { minLevel, maxLevel }
    end

    local merged = {}
    for _, group in pairs(groups) do
        table.sort(group.ranges, function(a, b)
            return a[1] < b[1]
        end)
        local ranges = {}
        for i = 1, #group.ranges do
            local range = group.ranges[i]
            local last = ranges[#ranges]
            if last and range[1] <= last[2] + 1 then
                if range[2] > last[2] then
                    last[2] = range[2]
                end
            else
                ranges[#ranges + 1] = { range[1], range[2] }
            end
        end
        merged[#merged + 1] = {
            spec = group.spec,
            faction = group.faction,
            rank = group.rank,
            ranges = ranges,
        }
    end

    local function rangeKey(ranges)
        local parts = {}
        for i = 1, #ranges do
            parts[i] = tostring(ranges[i][1]) .. "-" .. tostring(ranges[i][2])
        end
        return table.concat(parts, ",")
    end

    local combined = {}
    local seen = {}
    for i = 1, #merged do
        local row = merged[i]
        local id = row.spec .. "\0" .. tostring(row.rank) .. "\0" .. rangeKey(row.ranges)
        local bucket = seen[id]
        if not bucket then
            bucket = { spec = row.spec, rank = row.rank, ranges = row.ranges, alliance = false, horde = false }
            seen[id] = bucket
            combined[#combined + 1] = bucket
        end
        if row.faction == "Alliance" or row.faction == "both" then
            bucket.alliance = true
        end
        if row.faction == "Horde" or row.faction == "both" then
            bucket.horde = true
        end
    end

    table.sort(combined, function(a, b)
        if a.spec ~= b.spec then
            return a.spec < b.spec
        end
        if a.rank ~= b.rank then
            return a.rank < b.rank
        end
        return (a.ranges[1] and a.ranges[1][1] or 0) < (b.ranges[1] and b.ranges[1][1] or 0)
    end)

    local lines = {}
    for i = 1, #combined do
        local row = combined[i]
        local parts = {}
        for r = 1, #row.ranges do
            local minLevel = row.ranges[r][1]
            local maxLevel = row.ranges[r][2]
            if minLevel == maxLevel then
                parts[r] = "level " .. tostring(minLevel)
            else
                parts[r] = "levels " .. tostring(minLevel) .. "-" .. tostring(maxLevel)
            end
        end
        local side
        if row.alliance and row.horde then
            side = "Alliance and Horde"
        elseif row.alliance then
            side = "Alliance"
        elseif row.horde then
            side = "Horde"
        else
            side = "Alliance and Horde"
        end
        local rank = row.rank
        local rankText = (type(rank) == "number" and rank > 0) and ("rank " .. tostring(rank)) or "ranked"
        lines[#lines + 1] = string.format(
            "|cffe6bf47%s|r, %s, %s. %s.",
            row.spec,
            rankText,
            table.concat(parts, ", "),
            side
        )
    end
    return lines
end

function GQ.Log:ShowLookupRankTooltip(button, item)
    if not item then
        return
    end
    local _, classFile = self:LookupClassName()
    local lines = self:LookupRankLines(item, classFile)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText(item.name or "Item", 1, 0.82, 0)
    local entry = item.entries and item.entries[1]
    if entry and entry.slot and GQ.Data and GQ.Data.SlotHeaderLabel then
        GameTooltip:AddLine(GQ.Data:SlotHeaderLabel(entry.slot), 0.8, 0.8, 0.8, true)
    end
    if #lines == 0 then
        GameTooltip:AddLine("Not ranked in this class database.", 0.7, 0.7, 0.7, true)
    else
        for i = 1, #lines do
            GameTooltip:AddLine(lines[i], 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

function GQ.Log:ShowLookupDetail(item)
    local entry = self:LookupDetailEntry(item)
    if not entry or not self.frame then
        return
    end
    self.lookupItemKey = item.key
    self.lookupEntry = entry
    self:ApplyEntryDetail(entry)
    self:LayoutDetailRank(nil)
    self:UpdateFooterButtons()
    self:PaintLookupRows()
end

function GQ.Log:EnsureLookupWidgets(frame)
    if not frame or frame.lookupInset then
        return
    end
    local page = frame.lookupPage
    if not page then
        return
    end

    local inset = CreateFrame("Frame", nil, page)
    EnableClipping(inset)
    ApplyBlackBackground(inset)
    ApplyMetalEdge(inset, 16)
    frame.lookupInset = inset

    local intro = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetJustifyH("LEFT")
    intro:SetJustifyV("TOP")
    intro:SetWordWrap(true)
    intro:SetTextColor(1, 0.97, 0.88)
    frame.lookupIntro = intro

    local prompt = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    prompt:SetJustifyH("LEFT")
    prompt:SetJustifyV("TOP")
    prompt:SetWordWrap(true)
    prompt:SetTextColor(1, 0.82, 0)
    frame.lookupPrompt = prompt

    local box = CreateFrame("EditBox", "GearQuestLookupBox", inset, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlight)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if GQ.Log then
            GQ.Log:RunLookup()
        end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    frame.lookupBox = box

    local search = CreateFrame("Button", "GearQuestLookupSearch", inset, "UIPanelButtonTemplate")
    search:SetText("Search")
    search:SetScript("OnClick", function()
        if frame.lookupBox then
            frame.lookupBox:ClearFocus()
        end
        if GQ.Log then
            GQ.Log:RunLookup()
        end
    end)
    frame.lookupSearch = search

    local resultsScroll = CreatePanelScrollFrame("GearQuestLookupResultsScroll", inset)
    local resultsChild = CreateFrame("Frame", "GearQuestLookupResultsChild", resultsScroll)
    resultsChild:SetSize(200, 200)
    resultsScroll:SetScrollChild(resultsChild)
    frame.lookupScroll = resultsScroll
    frame.lookupScrollChild = resultsChild
    WireMouseWheel(resultsScroll, resultsScroll)
    WireMouseWheel(resultsChild, resultsScroll)

    local empty = resultsScroll:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetJustifyH("LEFT")
    empty:SetJustifyV("TOP")
    empty:SetWordWrap(true)
    empty:SetTextColor(0.7, 0.7, 0.7)
    empty:SetText("No matches. Try another class in the Simulator, or change what you typed.")
    empty:Hide()
    frame.lookupEmpty = empty

    frame.lookupRows = {}
    for i = 1, 10 do
        local row = CreateFrame("Button", nil, resultsChild)
        row:SetHeight(18)
        row:RegisterForClicks("LeftButtonUp")
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.55)
        row.highlight:Hide()
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -22, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row.info = CreateFrame("Button", nil, row)
        row.info:SetSize(13, 13)
        row.info:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.info:SetFrameLevel(row:GetFrameLevel() + 5)
        row.info.icon = row.info:CreateTexture(nil, "OVERLAY")
        row.info.icon:SetAllPoints()
        row.info.icon:SetTexture("Interface\\FriendsFrame\\InformationIcon")
        row.info:SetScript("OnEnter", function(self)
            local parent = self:GetParent()
            HideItemTooltip()
            if parent and parent.lookupItem and GQ.Log then
                GQ.Log:ShowLookupRankTooltip(self, parent.lookupItem)
            end
        end)
        row.info:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row.info:SetScript("OnClick", function()
        end)
        row:SetScript("OnEnter", function(self)
            if self.entry then
                ShowItemTooltipForRow(self)
            end
            if self.highlight and self.lookupItem then
                self.highlight:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            if self.info and self.info:IsMouseOver() then
                return
            end
            HideItemTooltip()
            local selected = GQ.Log and self.lookupItem and self.lookupItem.key == GQ.Log.lookupItemKey
            if self.highlight then
                if selected then
                    self.highlight:Show()
                else
                    self.highlight:Hide()
                end
            end
        end)
        row:SetScript("OnClick", function(self)
            HideItemTooltip()
            if self.lookupItem and GQ.Log then
                GQ.Log:ShowLookupDetail(self.lookupItem)
            end
        end)
        row:Hide()
        frame.lookupRows[i] = row
    end

    local wait = CreateFrame("Frame", nil, resultsScroll)
    wait:SetSize(240, 108)
    wait:Hide()
    local icon = wait:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("TOP", wait, "TOP", 0, 0)
    ApplyPortraitTexture(icon, PORTRAIT_TEXTURE, wait)
    if icon.SetDesaturated then
        icon:SetDesaturated(true)
    end
    icon:SetAlpha(0.88)
    wait.icon = icon
    local label = wait:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOP", icon, "BOTTOM", -8, -6)
    label:SetJustifyH("CENTER")
    label:SetText("Searching for matching items")
    label:SetTextColor(1, 0.97, 0.88)
    wait.label = label
    local dots = wait:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dots:SetPoint("LEFT", label, "RIGHT", 0, 0)
    dots:SetJustifyH("LEFT")
    dots:SetTextColor(1, 0.97, 0.88)
    dots:SetText("")
    wait.dots = dots
    frame.lookupWait = wait
end

function GQ.Log:LayoutLookupPage(frame)
    if not frame or not frame.lookupInset or not frame.lookupPage then
        return
    end
    local inset = frame.lookupInset
    inset:ClearAllPoints()
    inset:SetPoint("TOPLEFT", frame.lookupPage, "TOPLEFT", 0, LOG_SECTION_TOP)
    inset:SetPoint("BOTTOMLEFT", frame.lookupPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
    inset:SetWidth(LEFT_COLUMN_WIDTH)

    local pad = 12
    local width = LEFT_COLUMN_WIDTH - (pad * 2)
    frame.lookupIntro:ClearAllPoints()
    frame.lookupIntro:SetPoint("TOPLEFT", inset, "TOPLEFT", pad, -pad)
    frame.lookupIntro:SetWidth(width)
    local introH = frame.lookupIntro:GetStringHeight() or 0
    if introH < 36 then
        introH = 64
    end

    frame.lookupPrompt:ClearAllPoints()
    frame.lookupPrompt:SetPoint("TOPLEFT", frame.lookupIntro, "BOTTOMLEFT", 0, -8)
    frame.lookupPrompt:SetWidth(width)
    local promptH = frame.lookupPrompt:GetStringHeight() or 0
    if promptH < 14 then
        promptH = 28
    end

    frame.lookupBox:ClearAllPoints()
    frame.lookupBox:SetPoint("TOPLEFT", frame.lookupPrompt, "BOTTOMLEFT", 8, -8)
    frame.lookupBox:SetSize(math.max(80, width - 92), 22)
    frame.lookupSearch:ClearAllPoints()
    frame.lookupSearch:SetPoint("LEFT", frame.lookupBox, "RIGHT", 6, 0)
    frame.lookupSearch:SetSize(74, 22)

    local rowTop = pad + introH + 8 + promptH + 8 + 22 + 6
    local scroll = frame.lookupScroll
    local child = frame.lookupScrollChild
    if scroll and child then
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -rowTop)
        scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -(4 + SCROLLBAR_WIDTH), 8)
        local scrollWidth = scroll:GetWidth()
        if not scrollWidth or scrollWidth < 40 then
            scrollWidth = width
        end
        child:SetWidth(math.max(scrollWidth, 40))
        for i = 1, 10 do
            local row = frame.lookupRows[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -((i - 1) * 20))
            row:SetPoint("RIGHT", child, "RIGHT", -4, 0)
            row:SetHeight(18)
        end
        if frame.lookupEmpty then
            frame.lookupEmpty:SetParent(child)
            frame.lookupEmpty:ClearAllPoints()
            frame.lookupEmpty:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -4)
            frame.lookupEmpty:SetPoint("RIGHT", child, "RIGHT", -8, 0)
        end
        if frame.lookupWait then
            frame.lookupWait:ClearAllPoints()
            frame.lookupWait:SetPoint("TOP", scroll, "TOP", 0, -8)
            if frame.lookupWait.SetFrameLevel and scroll.GetFrameLevel then
                frame.lookupWait:SetFrameLevel(scroll:GetFrameLevel() + 8)
            end
        end
        local bar = scroll.GetName and _G[scroll:GetName() .. "ScrollBar"]
        if bar and bar.SetFrameLevel and scroll.GetFrameLevel then
            bar:SetFrameLevel(scroll:GetFrameLevel() + 5)
        end
        self:LayoutLookupResults(frame)
    end
end

function GQ.Log:LayoutLookupResults(frame)
    local scroll = frame and frame.lookupScroll
    local child = frame and frame.lookupScrollChild
    if not scroll or not child then
        return
    end
    local count = self._lookupResults and #self._lookupResults or 0
    if count < 1 then
        count = 1
    end
    local height = (count * 20) + 4
    local empty = frame.lookupEmpty
    if empty and empty:IsShown() then
        local textH = empty:GetStringHeight() or 0
        if textH + 8 > height then
            height = textH + 8
        end
    end
    child:SetHeight(height)
    UpdateScrollChildRect(scroll)
    ApplyScrollBarVisibility(scroll)
end

function GQ.Log:HideLookupSearchWait()
    local wait = self.frame and self.frame.lookupWait
    if not wait then
        return
    end
    wait:SetScript("OnUpdate", nil)
    wait:Hide()
end

function GQ.Log:ShowLookupSearchWait()
    local frame = self.frame
    local wait = frame and frame.lookupWait
    if not wait then
        return
    end
    if frame.lookupEmpty then
        frame.lookupEmpty:Hide()
    end
    if frame.lookupRows then
        for i = 1, #frame.lookupRows do
            frame.lookupRows[i]:Hide()
        end
    end
    wait.angle = 0
    wait.dotT = 0
    wait.dotN = 0
    if wait.dots then
        wait.dots:SetText("")
    end
    if wait.icon and wait.icon.SetRotation then
        wait.icon:SetRotation(0)
    end
    wait:Show()
    -- OnUpdate only while this is on screen. A hidden frame would still tick.
    wait:SetScript("OnUpdate", function(self, elapsed)
        elapsed = elapsed or 0
        local turn = 6.283185
        self.angle = (self.angle or 0) + elapsed * (turn / 1.8)
        if self.angle >= turn then
            self.angle = self.angle - turn
        end
        if self.icon and self.icon.SetRotation then
            self.icon:SetRotation(self.angle)
        end
        self.dotT = (self.dotT or 0) + elapsed
        if self.dotT >= 0.45 then
            self.dotT = self.dotT - 0.45
            self.dotN = ((self.dotN or 0) + 1) % 4
            local marks = { "", ".", "..", "..." }
            if self.dots then
                self.dots:SetText(marks[self.dotN + 1])
            end
        end
    end)
end

function GQ.Log:PaintLookupRows()
    local frame = self.frame
    if not frame or not frame.lookupRows then
        return
    end
    local results = self._lookupResults
    local searched = self._lookupSearched
    local count = results and #results or 0
    if frame.lookupEmpty then
        if searched and count == 0 then
            frame.lookupEmpty:Show()
        else
            frame.lookupEmpty:Hide()
        end
    end
    for i = 1, 10 do
        local row = frame.lookupRows[i]
        local item = searched and results and results[i]
        if item then
            row.lookupItem = item
            row.entry = self:LookupDetailEntry(item)
            row:Show()
            local texture = SafeGetItemIcon(item.itemId)
            if texture then
                row.icon:SetTexture(texture)
            else
                row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            local r, g, b = GetListItemQualityColor(item.itemId)
            row.text:SetText(item.name or "")
            row.text:SetTextColor(r, g, b)
            if item.key == self.lookupItemKey then
                row.highlight:Show()
            elseif not row:IsMouseOver() then
                row.highlight:Hide()
            end
        else
            row.lookupItem = nil
            row.entry = nil
            row.highlight:Hide()
            row:Hide()
        end
    end
    self:LayoutLookupResults(frame)
end

function GQ.Log:ApplyLookupHits(classFile, query)
    if not self.frame then
        return
    end
    if query ~= "" and (self._lookupIndexClass ~= classFile or self._lookupBuild) then
        return
    end
    self._lookupSearched = true
    self._lookupClass = classFile
    local hits = {}
    if query ~= "" then
        local index = self._lookupIndex or {}
        for i = 1, #index do
            local item = index[i]
            local name = item.nameLower or ""
            local rank
            if name == query then
                rank = 0
            elseif name:sub(1, #query) == query then
                rank = 1
            elseif name:find(query, 1, true) then
                rank = 2
            end
            if rank then
                hits[#hits + 1] = { item = item, rank = rank }
            end
        end
        table.sort(hits, function(a, b)
            if a.rank ~= b.rank then
                return a.rank < b.rank
            end
            return a.item.nameLower < b.item.nameLower
        end)
    end
    local results = {}
    local limit = #hits
    if limit > 10 then
        limit = 10
    end
    for i = 1, limit do
        results[i] = hits[i].item
    end
    self._lookupResults = results
    local still = false
    for i = 1, #results do
        if results[i].key == self.lookupItemKey then
            still = true
            break
        end
    end
    if not still then
        self.lookupItemKey = nil
        self.lookupEntry = nil
        self:ClearDetail()
    end
    self:HideLookupSearchWait()
    self:PaintLookupRows()
    self:UpdateFooterButtons()
end

function GQ.Log:RunLookup()
    if not self.frame or not self.frame.lookupBox then
        return
    end
    local _, classFile = self:LookupClassName()
    local query = self.frame.lookupBox:GetText() or ""
    query = string.lower((strtrim and strtrim(query)) or query:gsub("^%s+", ""):gsub("%s+$", ""))
    self._lookupSerial = (self._lookupSerial or 0) + 1
    local serial = self._lookupSerial
    if query == "" then
        self:HideLookupSearchWait()
        self:ApplyLookupHits(classFile, query)
        return
    end
    local indexReady = self._lookupIndex and self._lookupIndexClass == classFile and not self._lookupBuild
    if not indexReady then
        self:ShowLookupSearchWait()
    end
    self:EnsureLookupIndex(classFile, function()
        local log = GQ.Log
        if log and log._lookupSerial == serial then
            log:ApplyLookupHits(classFile, query)
        end
    end)
end

function GQ.Log:ReleaseLookupIndex()
    self._lookupIndex = nil
    self._lookupIndexClass = nil
    self._lookupBuild = nil
    self._lookupReady = nil
    self._lookupSerial = (self._lookupSerial or 0) + 1
    self:HideLookupSearchWait()
    self._lookupResults = nil
    self._lookupSearched = false
    self._lookupClass = nil
    self.lookupItemKey = nil
    self.lookupEntry = nil
    if self.frame and self.frame.lookupBox then
        self.frame.lookupBox:SetText("")
    end
    if self.frame and self.frame.lookupRows then
        for i = 1, #self.frame.lookupRows do
            local row = self.frame.lookupRows[i]
            row.lookupItem = nil
            row.entry = nil
            row:Hide()
        end
    end
end

function GQ.Log:RestoreHuntDetail()
    local entry = self.selectedEntry
    if not entry and self.selectedHuntId and GQ.Data and GQ.Data.GetEntryById then
        entry = GQ.Data:GetEntryById(self.selectedHuntId)
        self.selectedEntry = entry
    end
    if entry then
        self:ApplyEntryDetail(entry)
    else
        self:ClearDetail()
    end
end

function GQ.Log:RefreshLookup()
    local frame = self.frame
    if not frame then
        return
    end
    self:EnsureLookupWidgets(frame)
    local name, classFile = self:LookupClassName()
    if frame.lookupIntro then
        frame.lookupIntro:SetText(string.format(
            "You are currently looking through the %s GearQuest Forever database. We only store items that are relevant for this class. Use the Simulator to switch to another class to get the item database you wish.",
            name
        ))
    end
    if frame.lookupPrompt then
        frame.lookupPrompt:SetText(string.format(
            "Look up the item you are looking for (%s database)",
            name
        ))
    end
    if self._lookupClass ~= classFile then
        self._lookupClass = classFile
        self._lookupIndex = nil
        self._lookupIndexClass = nil
        self._lookupBuild = nil
        self._lookupReady = nil
        self._lookupSerial = (self._lookupSerial or 0) + 1
        self:HideLookupSearchWait()
        self._lookupResults = nil
        self._lookupSearched = false
        self.lookupItemKey = nil
        self.lookupEntry = nil
        if frame.lookupBox then
            frame.lookupBox:SetText("")
        end
        self:ClearDetail()
    end
    if frame.detailEmpty then
        frame.detailEmpty:SetText("Select an item to see how to get it.")
    end
    self:PaintLookupRows()
    self:LayoutLookupPage(frame)
    self:UpdateFooterButtons()
    self:UpdateContextStatus()
    self:UpdatePageTabVisuals()
end

function GQ.Log:PlaceDetailPanel(frame)
    if not frame or not frame.detailBg or not frame.logPage then
        return
    end
    local page = self:GetPageTab()
    local host = frame.logPage
    if page == "lookup" and frame.lookupPage then
        host = frame.lookupPage
    end
    if frame.detailBg:GetParent() ~= host then
        frame.detailBg:SetParent(host)
    end
    frame.detailBg:ClearAllPoints()
    frame.detailBg:SetPoint("TOPLEFT", host, "TOPLEFT", LEFT_COLUMN_WIDTH + COLUMN_GAP, LOG_SECTION_TOP)
    frame.detailBg:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, FOOTER_OFFSET)
    ApplyMetalEdge(frame.detailBg, 16)
end

function GQ.Log:Hide()
    if self.GamepadRelease then
        self:GamepadRelease()
    end
    self:HideSpecPicker()
    if self:GetPageTab() == "lookup" then
        self:ReleaseLookupIndex()
        self:RestoreHuntDetail()
    end
    if self.frame then
        if self.frame.sideTabRail then
            self.frame.sideTabRail:Hide()
        end
        self.frame:Hide()
    end
end

function GQ.Log:Toggle()
    if not self.frame then
        return
    end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
