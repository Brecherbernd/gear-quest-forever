local _, GQ = ...
local L = GQ.L

GQ.Toast = GQ.Toast or {}

local FADE_IN = 0.45
local HOLD = 4.0
local FADE_OUT = 0.65
local SCREEN_HEIGHT_RATIO = 0.20
local FRAME_WIDTH = 320
local FRAME_HEIGHT = 56

local toastFrame
local queue = {}
local animState
local animStart
local hoverPaused = false

local function PlayQuestCompleteSound()
    if not PlaySound then
        return
    end

    if SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE then
        PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
        return
    end

    PlaySound("igQuestListComplete")
end

local function EnsureFrame()
    if toastFrame then
        return toastFrame
    end

    local frame = CreateFrame("Button", "GearQuestObtainToast", UIParent)
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:Hide()
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        frame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
        frame:SetBackdropBorderColor(0.85, 0.65, 0.12, 1)
    else
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
    end

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(36, 36)
    frame.icon:SetPoint("LEFT", frame, "LEFT", 12, 0)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 10, -2)
    frame.title:SetPoint("RIGHT", frame, "RIGHT", -22, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetText("|cffffd200" .. L["Hunt obtained"] .. "|r")

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -2)
    frame.subtitle:SetPoint("RIGHT", frame, "RIGHT", -22, 0)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetTextColor(0.85, 0.85, 0.85)

    frame.closeButton = CreateFrame("Button", nil, frame)
    frame.closeButton:SetSize(18, 18)
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.closeButton:SetNormalFontObject("GameFontNormal")
    frame.closeButton:SetHighlightFontObject("GameFontHighlight")
    frame.closeButton:SetText("×")
    frame.closeButton:GetFontString():SetTextColor(0.75, 0.75, 0.75)
    frame.closeButton:SetScript("OnClick", function()
        GQ.Toast:Dismiss()
    end)
    frame.closeButton:SetScript("OnEnter", function(self)
        self:GetFontString():SetTextColor(1, 0.82, 0)
        GQ.Toast:PauseForHover()
    end)
    frame.closeButton:SetScript("OnLeave", function(self)
        self:GetFontString():SetTextColor(0.75, 0.75, 0.75)
        GQ.Toast:ResumeFromHover()
    end)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 6)
    frame.hint:SetText(L["Click to open log"])

    frame:SetScript("OnClick", function(self)
        local entryId = self.entryId
        if not entryId then
            return
        end

        local gq = _G.GearQuest
        if gq and gq.Log then
            gq.Log:Show()
            gq.Log:SelectHunt(entryId, true)
        end

        GQ.Toast:Dismiss()
    end)

    frame:SetScript("OnEnter", function()
        GQ.Toast:PauseForHover()
    end)

    frame:SetScript("OnLeave", function()
        GQ.Toast:ResumeFromHover()
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        GQ.Toast:OnUpdate(elapsed)
    end)

    toastFrame = frame
    return frame
end

function GQ.Toast:PauseForHover()
    hoverPaused = true
    local frame = toastFrame
    if not frame then
        return
    end

    if animState == "out" then
        animState = "hold"
        animStart = GetTime()
        frame:SetAlpha(1)
        frame:EnableMouse(true)
    end
end

function GQ.Toast:ResumeFromHover()
    hoverPaused = false
    if animState == "hold" then
        animStart = GetTime()
    end
end

function GQ.Toast:PositionFrame()
    local frame = EnsureFrame()
    frame:ClearAllPoints()
    local height = UIParent:GetHeight() or 768
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, math.floor(height * SCREEN_HEIGHT_RATIO))
end

function GQ.Toast:Init()
    if self.initialized then
        return
    end
    self.initialized = true
    EnsureFrame()
    self:PositionFrame()

    if UIParent and UIParent.HookScript then
        UIParent:HookScript("OnSizeChanged", function()
            GQ.Toast:PositionFrame()
        end)
    end
end

function GQ.Toast:ApplyEntryVisuals(entry)
    local frame = EnsureFrame()
    frame.entryId = entry and entry.id or nil
    frame.itemId = entry and entry.itemId or nil

    if not entry then
        frame.subtitle:SetText("")
        frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end

    local itemName = GQ.Data:GetEntryDisplayName(entry) or (L["Item "] .. entry.itemId)
    local title = GQ.Log and GQ.Log.ObtainToastTitle and GQ.Log:ObtainToastTitle(entry)
    frame.title:SetText(title or "|cffffd200" .. L["Hunt obtained"] .. "|r")
    frame.subtitle:SetText(itemName)

    if GQ.Data and GQ.Data.RequestItemInfo then
        GQ.Data:RequestItemInfo(entry.itemId)
    end
    local texture = GQ.Equip and GQ.Equip.GetItemIconTexture and GQ.Equip:GetItemIconTexture(entry.itemId)
    if not texture then
        texture = select(10, GetItemInfo(entry.itemId))
    end
    frame.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
end

function GQ.Toast:SetCloseEnabled(enabled)
    local frame = toastFrame
    if frame and frame.closeButton then
        if enabled then
            frame.closeButton:Show()
            frame.closeButton:Enable()
        else
            frame.closeButton:Disable()
            frame.closeButton:Hide()
        end
    end
end

function GQ.Toast:BeginFadeIn()
    local frame = EnsureFrame()
    hoverPaused = false
    animState = "in"
    animStart = GetTime()
    frame:SetAlpha(0)
    frame:Show()
    frame:EnableMouse(false)
    self:SetCloseEnabled(true)
    PlayQuestCompleteSound()
end

function GQ.Toast:BeginHold()
    local frame = EnsureFrame()
    animState = "hold"
    animStart = GetTime()
    frame:SetAlpha(1)
    frame:EnableMouse(true)
    self:SetCloseEnabled(true)
end

function GQ.Toast:BeginFadeOut()
    local frame = EnsureFrame()
    animState = "out"
    animStart = GetTime()
    frame:EnableMouse(false)
    self:SetCloseEnabled(true)
end

function GQ.Toast:FinishCurrent()
    local frame = EnsureFrame()
    frame:Hide()
    frame:SetAlpha(0)
    frame.entryId = nil
    self:SetCloseEnabled(false)
    animState = nil
    animStart = nil
    hoverPaused = false
end

function GQ.Toast:OnUpdate(elapsed)
    if not animState or not animStart or hoverPaused then
        return
    end

    local frame = EnsureFrame()
    local now = GetTime()
    local t = now - animStart

    if animState == "in" then
        local alpha = math.min(1, t / FADE_IN)
        frame:SetAlpha(alpha)
        if t >= FADE_IN then
            self:BeginHold()
        end
    elseif animState == "hold" then
        if t >= HOLD then
            self:BeginFadeOut()
        end
    elseif animState == "out" then
        local alpha = math.max(0, 1 - (t / FADE_OUT))
        frame:SetAlpha(alpha)
        if t >= FADE_OUT then
            self:FinishCurrent()
            self:ShowNext()
        end
    end
end

function GQ.Toast:ShowNext()
    if animState or #queue == 0 then
        return
    end

    local entry = table.remove(queue, 1)
    self:ApplyEntryVisuals(entry)
    self:PositionFrame()
    self:BeginFadeIn()
end

function GQ.Toast:ShowForEntry(entry)
    if not entry or not entry.id then
        return
    end

    self:Init()

    for _, queued in ipairs(queue) do
        if queued.id == entry.id or (entry.itemId and queued.itemId == entry.itemId) then
            return
        end
    end

    local frame = toastFrame
    if frame and frame:IsShown() and (frame.entryId == entry.id or (entry.itemId and frame.itemId == entry.itemId)) then
        return
    end

    table.insert(queue, entry)
    self:ShowNext()
end

function GQ.Toast:ClearQueue()
    wipe(queue)
    hoverPaused = false
    animState = nil
    animStart = nil
    self:FinishCurrent()
    if toastFrame then
        toastFrame:Hide()
    end
end

function GQ.Toast:Dismiss()
    self:FinishCurrent()
    self:ShowNext()
end
