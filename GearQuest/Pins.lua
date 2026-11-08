local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Pins = GQ.Pins or {}

-- Classic interface art. The vendor sack is the buy cursor. The rare
-- dragon is the nameplate silver dragon, the same one on a rare portrait.
local PIN_ICONS = {
    boss_drop = { path = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
    object_drop = { path = "Interface\\GossipFrame\\BankerGossipIcon" },
    raid_trash = { path = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    profession = { path = "Interface\\QuestFrame\\UI-QuestLog-BookIcon" },
    quest_reward = { path = "Interface\\GossipFrame\\AvailableQuestIcon" },
    -- The round mark on a dungeon quest in the quest log. The atlas is that
    -- same picture. The sheet is the fallback when the client has no atlas.
    quest_dungeon = {
        atlases = {
            "questlog-questtypeicon-dungeon",
            "QuestLog-QuestTypeIcon-Dungeon",
        },
        path = "Interface\\QuestFrame\\QuestTypeIcons",
        coord = { 0.421875, 0.5625, 0, 0.28125 },
    },
    rare_npc = {
        atlas = "nameplates-icon-elite-silver",
        path = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare",
        coord = { 0, 0.22, 0, 0.62 },
    },
    unsourced = { path = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-Unsourced.png" },
    vendor = { path = "Interface\\Cursor\\Buy" },
    -- Far Sight is not in this client, so the sunset ships with the addon.
    world_drop = { path = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-WorldDrop.png" },
}

local function ApplyPinIcon(icon, kind, owner)
    local spec = PIN_ICONS[kind] or PIN_ICONS.unsourced
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetTexCoord(0, 1, 0, 1)
    local atlasName = spec.atlas
    if not atlasName and spec.atlases and C_Texture and C_Texture.GetAtlasInfo then
        for i = 1, #spec.atlases do
            if C_Texture.GetAtlasInfo(spec.atlases[i]) then
                atlasName = spec.atlases[i]
                break
            end
        end
    end
    if atlasName and icon.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName) then
        icon:SetAtlas(atlasName, false)
        if owner and owner.SetNormalAtlas then
            owner:SetNormalAtlas(atlasName)
        end
        icon:Show()
        return
    end
    -- A previous atlas sticks and hides the file. World drops are the sunset.
    if icon.SetAtlas then
        pcall(icon.SetAtlas, icon, nil)
    end
    icon:SetTexture(spec.path)
    if owner and owner.SetNormalTexture then
        owner:SetNormalTexture(spec.path)
        local normal = owner.GetNormalTexture and owner:GetNormalTexture()
        if normal then
            normal:SetTexCoord(0, 1, 0, 1)
            if spec.coord then
                normal:SetTexCoord(spec.coord[1], spec.coord[2], spec.coord[3], spec.coord[4])
            end
        end
    end
    if spec.coord then
        icon:SetTexCoord(spec.coord[1], spec.coord[2], spec.coord[3], spec.coord[4])
    end
    icon:Show()
end

function GQ.Pins:ApplyIcon(icon, kind)
    if icon then
        ApplyPinIcon(icon, kind)
    end
end
local AREA_TEXTURE = "Interface\\Minimap\\UI-Minimap-Ping-Center"
local AREA_COLOR = { 0.3, 0.55, 1, 0.55 }
local WORLD_PIN_SIZE = 24

local pins = {}
local pinGen = 0
local frames = {}
local driver
local placed = 0
local placedMap, placedGen, placedGuided

local function ShowPinTooltip(frame)
    local pin = frame.pinData
    if not pin or not pin.entry then
        return
    end
    local entry = pin.entry
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local name = GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)
    GameTooltip:AddLine(name or (L["Item "] .. tostring(entry.itemId)), 1, 0.82, 0)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(pin.mapId)
    local zone = L.Zone(pin.map) or (info and info.name) or L.Zone(entry.zone) or ""
    if zone ~= "" then
        GameTooltip:AddLine(string.format("%s %.1f, %.1f", zone, pin.x, pin.y), 0.6, 0.8, 1)
    end
    GameTooltip:AddLine(L["Left-click to Guide"], 0.75, 0.75, 0.75)
    GameTooltip:AddLine(L["Right click to open Hunt"], 0.75, 0.75, 0.75)
    GameTooltip:Show()
end

local function OpenHuntFromPin(entry)
    if not entry or not entry.id then
        return
    end
    if GQ.Tracker and GQ.Tracker.OpenHunt then
        GQ.Tracker:OpenHunt(entry.id)
    end
end

local function PinClick(frame, button)
    local pin = frame.pinData
    local entry = pin and pin.entry
    if not entry then
        return
    end
    if button == "RightButton" then
        OpenHuntFromPin(entry)
        return
    end
    if GQ.Guide and GQ.Guide.ShowEntry then
        GQ.Guide:ShowEntry(entry)
    end
end

local function GuidedEntryId()
    return GQ.Guide and GQ.Guide.GuidedId and GQ.Guide:GuidedId() or nil
end

-- Our own click handlers. The map pin pool is not used: registering a data
-- provider makes the map call addon code while it hides, and that taints
-- the gamepad focus clear (SetPreferredGamepadInteractTarget).
local function WirePin(frame)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        ShowPinTooltip(self)
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        PinClick(self, button)
    end)
    return frame
end

local function MapName(mapId)
    local info = mapId and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
    return info and info.name or nil
end

local function VecXY(v)
    if type(v) ~= "table" then
        return nil
    end
    if v.GetXY then
        local x, y = v:GetXY()
        if type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if type(v.x) == "number" and type(v.y) == "number" then
        return v.x, v.y
    end
    return nil
end

-- The client's id for the zone name. A Wowhead id on the spot can be a map
-- this world map does not draw.
local function ClientMapId(pin)
    if pin.map and GQ.Map and GQ.Map.ZoneMap then
        local id = GQ.Map:ZoneMap(pin.map)
        if id then
            return id
        end
    end
    return pin.mapId
end

-- Zone coordinates placed on whatever map is open, including the continent.
local function ProjectPin(pin, shownMapId)
    if not pin or not shownMapId or not pin.x or not pin.y then
        return nil
    end
    local srcId = ClientMapId(pin)
    local nx, ny = pin.x / 100, pin.y / 100
    if srcId and srcId == shownMapId then
        return nx, ny
    end
    if MapName(shownMapId) == pin.map then
        return nx, ny
    end
    if not (srcId and C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then
        return nil
    end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, srcId, CreateVector2D(nx, ny))
    if not ok or not continent or not world then
        return nil
    end
    local wx, wy = VecXY(world)
    if not wx or not wy then
        return nil
    end
    local ok2, first, second = pcall(C_Map.GetMapPosFromWorldPos, continent, CreateVector2D(wx, wy), shownMapId)
    if not ok2 then
        return nil
    end
    local mx, my
    if type(first) == "number" and type(second) == "number" then
        mx, my = first, second
    elseif type(first) == "table" then
        mx, my = VecXY(first)
    elseif type(second) == "table" then
        mx, my = VecXY(second)
    end
    if type(mx) ~= "number" or type(my) ~= "number" then
        return nil
    end
    if mx < -0.02 or my < -0.02 or mx > 1.02 or my > 1.02 then
        return nil
    end
    if mx < 0 then
        mx = 0
    elseif mx > 1 then
        mx = 1
    end
    if my < 0 then
        my = 0
    elseif my > 1 then
        my = 1
    end
    return mx, my
end

local PinMixin = {}

function PinMixin:OnLoad()
    if self.owningMap and self.UseFrameLevelType then
        self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    end
    self:SetScalingLimits(1, 1, 1.2)
end

function PinMixin:OnAcquired(pin, x, y)
    self.owningMap = WorldMapFrame
    if self.UseFrameLevelType then
        self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    end
    self:SetScalingLimits(1, 1, 1.2)
    self:SetPosition(x, y)
    self.pinData = {
        entry = pin.entry,
        map = pin.map,
        mapId = pin.mapId,
        x = pin.x,
        y = pin.y,
        kind = pin.kind,
    }
    self.lastKind = pin.kind
    if self.icon then
        ApplyPinIcon(self.icon, pin.kind, self)
    end
    local guided = GuidedEntryId()
    if self.ring then
        if guided and pin.entry and pin.entry.id == guided then
            self.ring:Show()
        else
            self.ring:Hide()
        end
    end
    self:Show()
end

function PinMixin:OnReleased()
    self.pinData = nil
    if self.ring then
        self.ring:Hide()
    end
end

local function CreateMapPin()
    local canvas = WorldMapFrame:GetCanvas()
    -- Mouse mode only. GamepadMap() never reaches here. A Button would be a
    -- gamepad focus target, so this stays a Frame placed by the map pin mixin.
    local frame = CreateFrame("Frame", nil, canvas)
    frame:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    frame.icon:SetPoint("CENTER")
    frame.ring = frame:CreateTexture(nil, "BACKGROUND")
    frame.ring:SetTexture(AREA_TEXTURE)
    frame.ring:SetSize(48, 48)
    frame.ring:SetPoint("CENTER")
    frame.ring:SetVertexColor(AREA_COLOR[1], AREA_COLOR[2], AREA_COLOR[3], AREA_COLOR[4])
    frame.ring:Hide()
    Mixin(frame, MapCanvasPinMixin, PinMixin)
    frame.owningMap = WorldMapFrame
    if frame.OnLoad then
        frame:OnLoad()
    end
    WirePin(frame)
    frame:Hide()
    return frame
end

local function MapIsOpen()
    return WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()
end

-- GetCanvas creates or wakes the map canvas. Call it only while the map is
-- open and the pins actually need to be drawn. A closed map does not need it.
local function GamepadMap()
    return GQ.UsesGamepad and GQ:UsesGamepad()
end

local function MapReady()
    if GamepadMap() then
        return false
    end
    return MapIsOpen() and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
        and WorldMapFrame.GetMapID and MapCanvasPinMixin
end

local function EnsureFrame(index)
    local frame = frames[index]
    if not frame then
        frame = CreateMapPin()
        frames[index] = frame
    end
    return frame
end

-- Runs from our own OnUpdate, never from the map's show or hide.
local function PlacePins()
    if not MapIsOpen() then
        return
    end
    local mapId = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not mapId then
        return
    end
    -- Normalized pin positions do not change while the same map stays open.
    -- Projecting every pin on every frame was a steady map-API cost.
    local guided = GuidedEntryId()
    if mapId == placedMap and pinGen == placedGen and guided == placedGuided then
        return
    end
    if not MapReady() then
        return
    end
    placedMap, placedGen, placedGuided = mapId, pinGen, guided
    local n = 0
    for i = 1, #pins do
        local x, y = ProjectPin(pins[i], mapId)
        if x and y then
            n = n + 1
            local frame = EnsureFrame(n)
            frame.owningMap = WorldMapFrame
            frame:OnAcquired(pins[i], x, y)
        end
    end
    for i = n + 1, placed do
        local frame = frames[i]
        if frame then
            frame:Hide()
            if frame.OnReleased then
                frame:OnReleased()
            end
        end
    end
    placed = n
end

local function RefreshPins()
    if not MapIsOpen() then
        return
    end
    PlacePins()
end

function GQ.Pins:Sync()
    if not driver then
        self:Init()
    end
    -- The gamepad map close clears focus with a protected call. A frame on
    -- the canvas is hidden with the map and taints that call. The guide and
    -- Show on map still set the Blizzard user waypoint.
    if GamepadMap() then
        pins = {}
        pinGen = pinGen + 1
        placedMap = nil
        return
    end
    pins = {}
    pinGen = pinGen + 1
    local entries = GQ.Tracker and GQ.Tracker.GetTrackedEntries and GQ.Tracker:GetTrackedEntries()
    if entries and GQ.Map and GQ.Map.SpotForEntry then
        for _, entry in ipairs(entries) do
            local pin = GQ.Map:SpotForEntry(entry)
            if pin then
                pins[#pins + 1] = pin
            end
        end
    end
    RefreshPins()
end

function GQ.Pins:Init()
    if driver then
        return
    end
    driver = CreateFrame("Frame")
    -- Place pins on our own tick once the map is already open. The map's
    -- show and hide must not call into this addon, or the gamepad cannot
    -- clear its interact target when the map closes. A closed map only
    -- checks IsShown. GetCanvas runs on the open edge, then not again
    -- until the map, the tracked hunts, or the guide pin changes.
    local mapWasOpen = false
    driver:SetScript("OnUpdate", function()
        local open = MapIsOpen()
        if not open then
            mapWasOpen = false
            return
        end
        if not mapWasOpen then
            mapWasOpen = true
            placedMap = nil
        end
        PlacePins()
    end)
    RefreshPins()
    if GQ.Log and GQ.Log.EnsureCoordinateWatch then
        GQ.Log:EnsureCoordinateWatch()
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    GQ.Pins:Init()
    GQ.Pins:Sync()
end)
