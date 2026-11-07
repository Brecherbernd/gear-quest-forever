local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Minimap = GQ.Minimap or {}

local MINIMAP_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GearQuest-Icon"
local MINIMAP_ICON_SIZE = 20
local BUTTON_SIZE = 31
-- Center sits on the rim, the same offset Questie uses (half the minimap, plus 5).
local MINIMAP_BORDER_OUTSET = 5

local function GetRadius()
    if not Minimap then
        return 70
    end
    local w = Minimap:GetWidth() or 140
    local h = Minimap:GetHeight() or w
    return (math.min(w, h) / 2) + MINIMAP_BORDER_OUTSET
end

local function ApplyMinimapIcon(icon)
    if not icon then
        return
    end

    icon:SetTexture(MINIMAP_TEXTURE)
end

local function EnsureMinimapIcon(button)
    if not button.gqIcon then
        button.gqIcon = button:CreateTexture(nil, "BACKGROUND")
        button.gqIcon:SetSize(MINIMAP_ICON_SIZE, MINIMAP_ICON_SIZE)
        button.gqIcon:SetPoint("CENTER", 0, 1)
    end

    ApplyMinimapIcon(button.gqIcon)
    return button.gqIcon
end

local function GetAngle()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    return GearQuestForeverDB.settings.minimapAngle or 200
end

local function SetAngle(angle)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.minimapAngle = angle
end

local function UpdatePosition(button)
    if not button or not Minimap then
        return
    end
    local radius = GetRadius()
    local angle = math.rad(GetAngle())
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function RegisterButtonClicks(button)
    if not button.RegisterForClicks then
        return
    end

    if pcall(function() button:RegisterForClicks("LeftButtonUp", "RightButtonUp") end) then
        return
    end
    pcall(function() button:RegisterForClicks("LeftButton", "RightButton") end)
end

local function OnMinimapClick()
    local gq = _G.GearQuest
    if gq and gq.Log then
        gq.Log:Toggle()
    end
end

local function WireMinimapButton(button)
    EnsureMinimapIcon(button)
    RegisterButtonClicks(button)
    button:SetScript("OnClick", OnMinimapClick)
    button:SetScript("OnMouseUp", nil)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GearQuest", 0.90, 0.75, 0.28)
        GameTooltip:AddLine(L["Click to open GearQuest"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function GQ.Minimap:IsHidden()
    return type(GearQuestForeverDB) == "table"
        and type(GearQuestForeverDB.settings) == "table"
        and GearQuestForeverDB.settings.hideMinimapIcon
        and true
        or false
end

function GQ.Minimap:ApplyVisibility()
    local button = self.button
    if not button then
        return
    end
    if self:IsHidden() then
        button:Hide()
        if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == button then
            GameTooltip:Hide()
        end
    else
        button:Show()
        UpdatePosition(button)
    end
end

function GQ.Minimap:SetHidden(hidden)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.hideMinimapIcon = hidden and true or false
    self:ApplyVisibility()
end

function GQ.Minimap:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    if self.button or _G.GearQuestMinimapButton then
        self.button = self.button or _G.GearQuestMinimapButton
        if self.button then
            WireMinimapButton(self.button)
            UpdatePosition(self.button)
            self:ApplyVisibility()
        end
        return
    end

    if not Minimap then
        return
    end

    local button = CreateFrame("Button", "GearQuestMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(20)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    WireMinimapButton(button)
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(s)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            SetAngle(math.deg(math.atan2(py - my, px - mx)))
            UpdatePosition(s)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    UpdatePosition(button)
    self.button = button
    self:ApplyVisibility()

    if Minimap.HookScript then
        pcall(function()
            Minimap:HookScript("OnSizeChanged", function()
                if GQ.Minimap.button then
                    UpdatePosition(GQ.Minimap.button)
                end
            end)
        end)
    end
end
