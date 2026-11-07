local _, GQ = ...

GQ.Map = GQ.Map or {}

local PREFIX = "|cff66ccffGearQuest|r: "
local zoneCache = {}

local ZONE_MAP = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3

local function MapAcceptsWorld(mapId)
    if not (mapId and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return true
    end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, mapId, CreateVector2D(0.5, 0.5))
    return ok and continent and world and true or false
end

-- The first id with this name is often a duplicate that cannot take a world
-- position. Prefer the outdoor zone, and one the guide can measure yards on.
local function FindMapId(zoneName)
    if not zoneName or zoneName == "" then
        return nil
    end
    if zoneCache[zoneName] ~= nil then
        return zoneCache[zoneName] or nil
    end
    local found = false
    local bestScore = -1
    if C_Map and C_Map.GetMapInfo then
        for id = 1, 3000 do
            local info = C_Map.GetMapInfo(id)
            if info and info.name == zoneName then
                local score = info.mapType == ZONE_MAP and 100 or 10
                if MapAcceptsWorld(id) then
                    score = score + 50
                end
                if score > bestScore then
                    bestScore = score
                    found = id
                end
            end
        end
    end
    zoneCache[zoneName] = found
    return found or nil
end

function GQ.Map:ZoneMap(zoneName)
    return FindMapId(zoneName)
end

function GQ.Map:KindFor(entry)
    if GQ.Log and GQ.Log.SourceIconKind then
        return GQ.Log:SourceIconKind(entry)
    end
    local src = entry and entry.sourceType or ""
    if GQ.NormalizeSourceType then
        src = GQ:NormalizeSourceType(src) or src
    end
    return src
end

-- Faction-matching coordinate, before the zone name is turned into a map id.
function GQ.Map:DisplaySpot(entry)
    if not entry or not entry.itemId or not GQ.Data or not GQ.Data.coordinates then
        return nil
    end
    if GQ.Data.NearestCoordinateSpot then
        return GQ.Data:NearestCoordinateSpot(entry.itemId)
    end
    local row = GQ.Data.coordinates[entry.itemId]
    if not row or not row.spots or #row.spots == 0 then
        return nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or nil
    local openWorld = GQ.Data.PinIgnoresFactionZone and GQ.Data:PinIgnoresFactionZone(row)
    for i = 1, #row.spots do
        local spot = row.spots[i]
        if spot.x and spot.y and GQ.Data:SpotVisible(spot, faction, openWorld) then
            return spot
        end
    end
    return nil
end

function GQ.Map:HasSpot(entry)
    return self:DisplaySpot(entry) ~= nil
end

-- The same spot the coordinate line shows for this faction. One pin.
function GQ.Map:SpotForEntry(entry)
    local spot = self:DisplaySpot(entry)
    if not spot then
        return nil
    end
    -- The client's map id for this zone name. A stored id can be a Wowhead
    -- id the world map does not use, and then the pin never lands.
    local mapId = self:ZoneMap(spot.map) or spot.mapId
    if not mapId then
        return nil
    end
    return {
        mapId = mapId,
        x = spot.x,
        y = spot.y,
        map = spot.map,
        kind = self:KindFor(entry),
        entry = entry,
    }
end

-- Shift-click on a user waypoint inserts the pin in chat, then copies a
-- /mappin command with CopyToClipboard. That copy is reserved for Blizzard
-- UI. A pin placed from this addon runs the click tainted, so the copy pops
-- "blocked from an action only available to the Blizzard UI" after the chat
-- link is already in. Skip the clipboard step; chat share stays.
local function SkipWaypointClipboard()
end

local function GuardWaypointClipboard()
    -- The gamepad UI closes the map through a protected focus clear. Do not
    -- touch WorldMapFrame.pinPools or a live pin: writing an addon function
    -- onto one taints that hide. Mouse mode only skips the clipboard copy.
    if GQ.UsesGamepad and GQ:UsesGamepad() then
        return
    end
    if type(WaypointLocationPinMixin) == "table"
        and type(WaypointLocationPinMixin.CopySlashCommandToClipboard) == "function"
        and WaypointLocationPinMixin.CopySlashCommandToClipboard ~= SkipWaypointClipboard
    then
        WaypointLocationPinMixin.CopySlashCommandToClipboard = SkipWaypointClipboard
    end
end

local clipboardGuard = CreateFrame("Frame")
clipboardGuard:RegisterEvent("ADDON_LOADED")
clipboardGuard:RegisterEvent("PLAYER_LOGIN")
clipboardGuard:SetScript("OnEvent", function()
    GuardWaypointClipboard()
end)

local function OpenToMap(mapId)
    GuardWaypointClipboard()
    if mapId and C_Map and C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(mapId)
        return
    end
    if mapId and OpenWorldMap then
        OpenWorldMap(mapId)
        return
    end
    if WorldMapFrame and not WorldMapFrame:IsShown() and ToggleWorldMap then
        ToggleWorldMap()
    end
end

local function SetPin(mapId, x, y, label)
    x, y = x / 100, y / 100
    if TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(mapId, x, y, { title = "GearQuest: " .. label })
        return true
    end
    if C_Map.SetUserWaypoint and UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapId) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        return true
    end
    return false
end

function GQ.Map:Show(entry)
    if not entry then
        return
    end
    if GQ.Guide and GQ.Guide.ShowEntry then
        GQ.Guide:ShowEntry(entry)
    end
    local spot = self:SpotForEntry(entry)
    local mapId = spot and spot.mapId or self:ZoneMap(entry.zone)
    local label = entry.questName or entry.npc or entry.zone or "GearQuest"

    OpenToMap(mapId)

    if not spot then
        GQ:Chat(PREFIX .. "No exact spot for this item.")
        return
    end

    local pinned = SetPin(spot.mapId, spot.x, spot.y, label)
    GuardWaypointClipboard()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, GuardWaypointClipboard)
    end
    local where = string.format("%s %.1f, %.1f", spot.map or label, spot.x, spot.y)
    GQ:Chat(PREFIX .. where .. (pinned and " — pin placed" or ""))
end
