local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Guide = GQ.Guide or {}

local ARROW_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-GuideArrow3D.png"
local ARROW_FRAMES = 32
local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local HERE_YARDS = 12
-- Where you are, and which camp is closest. The arrow still turns every
-- frame from the last sample. Asking the map more often than this is what
-- made the guide's memory climb.
local SAMPLE_SEC = 5

local function Settings()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    return GearQuestForeverDB.settings
end

local function CharSettings()
    if type(GearQuestForeverCharDB) ~= "table" then
        GearQuestForeverCharDB = {}
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
    return GearQuestForeverCharDB
end

function GQ.Guide:IsSuppressed()
    return Settings().hideGuideArrow and true or false
end

function GQ.Guide:GuidedId()
    return CharSettings().guideEntryId
end

-- /reload keeps the guide. A logout countdown clears it. Tracked hunts stay.
-- C_UI.Reload is protected. Replacing ReloadUI or C_UI.Reload puts this
-- addon on that call, and the AddOn List Reload button then fails with
-- "Interface action failed because of an AddOn". PLAYER_CAMPING fires when
-- the logout countdown starts, and it does not fire for a reload.
local guideLoggingOut = false
local guideLogout = CreateFrame("Frame")
guideLogout:RegisterEvent("PLAYER_CAMPING")
guideLogout:RegisterEvent("PLAYER_LOGOUT")
guideLogout:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_CAMPING" then
        guideLoggingOut = true
        return
    end
    if not guideLoggingOut then
        return
    end
    if type(GearQuestForeverCharDB) == "table" then
        GearQuestForeverCharDB.guideEntryId = nil
    end
end)
if hooksecurefunc and type(CancelLogout) == "function" then
    hooksecurefunc("CancelLogout", function()
        guideLoggingOut = false
    end)
end

local function WorldXY(world)
    if type(world) ~= "table" then
        return nil
    end
    if world.GetXY then
        local x, y = world:GetXY()
        if type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if type(world.x) == "number" and type(world.y) == "number" then
        return world.x, world.y
    end
    return nil
end

-- One vector for every map query. A new one each frame is what made the
-- guide's memory climb for as long as the arrow stayed on screen.
local mapVector

local function MapVector(x, y)
    if not CreateVector2D then
        return nil
    end
    if not mapVector then
        mapVector = CreateVector2D(x, y)
        return mapVector
    end
    if mapVector.SetXY then
        mapVector:SetXY(x, y)
    else
        mapVector.x = x
        mapVector.y = y
    end
    return mapVector
end

local function WorldOn(mapId, x, y)
    local vec = MapVector(x, y)
    if not (mapId and vec and C_Map and C_Map.GetWorldPosFromMapPos) then
        return nil
    end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, mapId, vec)
    if not ok or not continent or not world then
        return nil
    end
    local wx, wy = WorldXY(world)
    if not wx or not wy then
        return nil
    end
    return continent, wx, wy
end

-- Position on a specific map. A cave or town map still reports the parent
-- zone, which is the map the pin is stored on.
local function PositionOn(mapId)
    if not (mapId and C_Map and C_Map.GetPlayerMapPosition) then
        return nil
    end
    local pos = C_Map.GetPlayerMapPosition(mapId, "player")
    if not pos or not pos.GetXY then
        return nil
    end
    local x, y = pos:GetXY()
    if not x or not y or (x == 0 and y == 0) then
        return nil
    end
    return x, y
end

-- Same bearing as TomTom and HereBeDragons. 0 is north and the angle
-- increases counterclockwise, which is also how GetPlayerFacing works.
-- Subtracting it from facing leaves 0 when you are looking at the hunt,
-- including when that direction is west. Our frames then turn clockwise,
-- so the difference is flipped and the right-hand side stays on the right.
local function Aim(east, north, facing)
    local angle = math.atan2(east or 0, north or 0)
    if angle > 0 then
        angle = math.pi * 2 - angle
    else
        angle = -angle
    end
    return (facing or 0) - angle
end

local function FormatYards(dist)
    if not dist then
        return nil
    end
    if dist < HERE_YARDS then
        return L["Here"]
    end
    return L("%d yards", dist + 0.5)
end

local function WrapPi(angle)
    while angle > math.pi do
        angle = angle - math.pi * 2
    end
    while angle < -math.pi do
        angle = angle + math.pi * 2
    end
    return angle
end

-- Frame 0 points forward, away from the camera. Positive turns to the right.
local function ArrowIndex(rel)
    local t = rel / (math.pi * 2)
    if t < 0 then
        t = t + 1
    end
    return math.floor(t * ARROW_FRAMES + 0.5) % ARROW_FRAMES
end

local axisSignCache = {}

-- World axes are not "x is east". Measure which way east and north
-- actually move, then project the waypoint onto those two directions.
local function WorldBasis(mapId)
    local cached = axisSignCache[mapId]
    if cached then
        return cached[1], cached[2], cached[3], cached[4]
    end
    local _, eastX, eastY = WorldOn(mapId, 0.6, 0.5)
    local _, westX, westY = WorldOn(mapId, 0.4, 0.5)
    local _, northX, northY = WorldOn(mapId, 0.5, 0.4)
    local _, southX, southY = WorldOn(mapId, 0.5, 0.6)
    if not (eastX and westX and eastY and westY and northX and northY and southX and southY) then
        return nil
    end
    local basis = { eastX - westX, eastY - westY, northX - southX, northY - southY }
    axisSignCache[mapId] = basis
    return basis[1], basis[2], basis[3], basis[4]
end

local function AimWorld(mapId, dx, dy, facing)
    local eastX, eastY, northX, northY = WorldBasis(mapId)
    if not eastX then
        return 0
    end
    local det = eastX * northY - eastY * northX
    if det == 0 then
        return 0
    end
    local east = (dx * northY - dy * northX) / det
    local north = (eastX * dy - eastY * dx) / det
    return Aim(east, north, facing)
end

local function ParentChain(mapId)
    local chain, seen = {}, {}
    local guard = 0
    while mapId and mapId ~= 0 and not seen[mapId] and guard < 12 and C_Map and C_Map.GetMapInfo do
        seen[mapId] = true
        chain[#chain + 1] = mapId
        local info = C_Map.GetMapInfo(mapId)
        mapId = info and info.parentMapID
        guard = guard + 1
    end
    return chain
end

local function CommonMap(a, b)
    local parents = {}
    local chain = ParentChain(a)
    for i = 1, #chain do
        parents[chain[i]] = true
    end
    chain = ParentChain(b)
    for i = 1, #chain do
        if parents[chain[i]] then
            return chain[i]
        end
    end
end

-- GetMapPosFromWorldPos leads with the map id (a number) and then the
-- position. A transport load, such as the zeppelin into Tirisfal, does this
-- every frame. Indexing that number is what made the guide error climb.
local function VectorXY(pos)
    if type(pos) ~= "table" then
        return nil
    end
    if pos.GetXY then
        local x, y = pos:GetXY()
        if type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if type(pos.x) == "number" and type(pos.y) == "number" then
        return pos.x, pos.y
    end
    return nil
end

local function ProjectToMap(srcMap, x, y, destMap)
    if not destMap then
        return nil
    end
    if srcMap == destMap then
        return x, y
    end
    local continent, wx, wy = WorldOn(srcMap, x, y)
    if not (continent and wx and C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then
        return nil
    end
    local vec = MapVector(wx, wy)
    if not vec then
        return nil
    end
    local ok, first, second, third = pcall(C_Map.GetMapPosFromWorldPos, continent, vec, destMap)
    if not ok then
        return nil
    end
    local mx, my = VectorXY(first)
    if not mx then
        mx, my = VectorXY(second)
    end
    if not mx and type(second) == "number" and type(third) == "number" then
        mx, my = second, third
    elseif not mx and type(first) == "number" and type(second) == "number"
        and first >= -0.05 and first <= 1.05 and second >= -0.05 and second <= 1.05 then
        mx, my = first, second
    end
    return mx, my
end

-- Published docks that cross continents. mapId is the client's map number,
-- the same one the hunt pins use, so a German client finds the dock without
-- the English zone name. The arrow aims at the dock where this character
-- boards. The ride it picks is the one with the shortest walk to that dock
-- plus the shortest walk after the last landing. Menethil, Southshore, and
-- Auberdine are one ship, both ways. Southshore is the stop in the middle.
-- Stormwind Harbor and Auberdine are a separate ship.
local CROSSINGS = {
    { id = "durotar", zone = "Durotar", mapId = 1411, place = "Durotar", x = 50.8, y = 13.6, faction = "Horde", kind = "Zeppelin", to = { "tirisfal", "gromgol" } },
    { id = "tirisfal", zone = "Tirisfal Glades", mapId = 1420, place = "Tirisfal Glades", x = 61.0, y = 59.0, faction = "Horde", kind = "Zeppelin", to = { "durotar", "gromgol" } },
    { id = "gromgol", zone = "Stranglethorn Vale", mapId = 1434, place = "Grom'gol", x = 31.5, y = 29.6, faction = "Horde", kind = "Zeppelin", to = { "durotar", "tirisfal" } },
    { id = "ratchet", zone = "The Barrens", mapId = 1413, place = "Ratchet", x = 63.6, y = 38.7, kind = "Ship", to = { "booty" } },
    { id = "booty", zone = "Stranglethorn Vale", mapId = 1434, place = "Booty Bay", x = 26.0, y = 73.2, kind = "Ship", to = { "ratchet" } },
    { id = "auberdine", zone = "Darkshore", mapId = 1439, place = "Auberdine", x = 32.7, y = 43.7, faction = "Alliance", kind = "Ship", to = { "southshore", "stormwind" } },
    { id = "menethilNorth", zone = "Wetlands", mapId = 1437, place = "Menethil Harbor", x = 4.7, y = 57.0, faction = "Alliance", kind = "Ship", to = { "southshore" } },
    { id = "southshore", zone = "Hillsbrad Foothills", mapId = 1424, place = "Southshore", x = 50.6, y = 61.0, faction = "Alliance", kind = "Ship", to = { "auberdine", "menethilNorth" } },
    { id = "stormwind", zone = "Stormwind City", mapId = 1453, place = "Stormwind Harbor", x = 22.6, y = 56.1, faction = "Alliance", kind = "Ship", to = { "auberdine" } },
    { id = "menethilSouth", zone = "Wetlands", mapId = 1437, place = "Menethil Harbor", x = 5.0, y = 63.0, faction = "Alliance", kind = "Ship", to = { "theramore" } },
    { id = "theramore", zone = "Dustwallow Marsh", mapId = 1445, place = "Theramore", x = 71.0, y = 56.0, faction = "Alliance", kind = "Ship", to = { "menethilSouth" } },
    { id = "steamwheedle", zone = "Tanaris", mapId = 1446, place = "Steamwheedle Port", x = 66.6, y = 22.0, kind = "Ship", to = { "powderfuse" } },
    { id = "powderfuse", zone = "Riverglades", mapId = 2548, place = "Powderfuse Port", x = 78.1, y = 51.9, kind = "Ship", to = { "steamwheedle" } },
    { id = "valanaarEast", zone = "Zephras Isle", mapId = 2521, place = "Valanaar", x = 65.9, y = 83.5, faction = "Alliance", kind = "Skycutter", to = { "dalaran" } },
    { id = "dalaran", zone = "Alterac Mountains", mapId = 1416, place = "Dalaran", x = 12.5, y = 51.8, faction = "Alliance", kind = "Skycutter", to = { "valanaarEast" } },
    { id = "valanaarWest", zone = "Zephras Isle", mapId = 2521, place = "Valanaar", x = 57.9, y = 80.9, faction = "Horde", kind = "Zeppelin", to = { "skywatcher" } },
    { id = "skywatcher", zone = "Mulgore", mapId = 1412, place = "Skywatcher Plateau", x = 34.3, y = 25.8, faction = "Horde", kind = "Zeppelin", to = { "valanaarWest" } },
}

local function DockLabel(dock)
    if dock and dock.place and dock.place ~= "" then
        return L("%s in %s", L[dock.kind], L.Zone(dock.place))
    end
    return dock and L[dock.kind] or ""
end

local crossingById = {}
for i = 1, #CROSSINGS do
    crossingById[CROSSINGS[i].id] = CROSSINGS[i]
end

local function DockWorld(place)
    if place.continent then
        return place.continent, place.wx, place.wy, place.mapId
    end
    -- The stored map number is the same on every client language. The
    -- English zone name is only a fallback for a dock that has no number.
    local mapId = place.mapId
    if not mapId and GQ.Map and GQ.Map.ZoneMap then
        mapId = GQ.Map:ZoneMap(place.zone)
    end
    if not mapId then
        return nil
    end
    local continent, wx, wy = WorldOn(mapId, place.x / 100, place.y / 100)
    if not continent then
        return nil
    end
    place.mapId = mapId
    place.continent = continent
    place.wx = wx
    place.wy = wy
    return continent, wx, wy, mapId
end

-- Reused for every search. A new table each frame, while the arrow is up,
-- is the same kind of churn the score hover used to cause.
local crossCost, crossPrev, crossRide, crossOrigin = {}, {}, {}, {}
local crossRev = {}

local function NearestCrossing(playerContinent, pwx, pwy, huntContinent, hwx, hwy)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local function canBoard(dock)
        return dock and (not dock.faction or dock.faction == faction)
    end
    local function hypot(ax, ay, bx, by)
        local dx = ax - bx
        local dy = ay - by
        return math.sqrt(dx * dx + dy * dy)
    end

    local INF = 1e12
    local cost, prev, viaRide, origin = crossCost, crossPrev, crossRide, crossOrigin
    for i = 1, #CROSSINGS do
        local id = CROSSINGS[i].id
        cost[id] = INF
        prev[id] = nil
        viaRide[id] = nil
        origin[id] = nil
    end
    for i = 1, #CROSSINGS do
        local dock = CROSSINGS[i]
        if canBoard(dock) then
            local continent, wx, wy = DockWorld(dock)
            if continent == playerContinent and wx then
                cost[dock.id] = hypot(wx, wy, pwx, pwy)
                origin[dock.id] = dock
            end
        end
    end

    local guard = 0
    local updated = true
    while updated and guard < 24 do
        updated = false
        guard = guard + 1
        for i = 1, #CROSSINGS do
            local dock = CROSSINGS[i]
            local base = cost[dock.id]
            local boarded = origin[dock.id]
            if base < INF and boarded and canBoard(dock) then
                local continent, wx, wy = DockWorld(dock)
                local tos = dock.to
                for t = 1, #tos do
                    local dest = crossingById[tos[t]]
                    if dest and base < cost[dest.id] then
                        cost[dest.id] = base
                        prev[dest.id] = dock.id
                        viaRide[dest.id] = true
                        origin[dest.id] = boarded
                        updated = true
                    end
                end
                if continent and wx then
                    for j = 1, #CROSSINGS do
                        local other = CROSSINGS[j]
                        if other.id ~= dock.id and canBoard(other) then
                            local otherContinent, ox, oy = DockWorld(other)
                            if otherContinent == continent and ox then
                                local nextCost = base + hypot(wx, wy, ox, oy)
                                if nextCost < cost[other.id] then
                                    cost[other.id] = nextCost
                                    prev[other.id] = dock.id
                                    viaRide[other.id] = false
                                    origin[other.id] = boarded
                                    updated = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local bestCost, bestDepart, bestArrive
    for i = 1, #CROSSINGS do
        local dock = CROSSINGS[i]
        local base = cost[dock.id]
        if base < INF and origin[dock.id] then
            local continent, wx, wy = DockWorld(dock)
            if continent == huntContinent and wx then
                local total = base
                if hwx and hwy then
                    total = base + hypot(wx, wy, hwx, hwy)
                end
                if not bestCost or total < bestCost then
                    bestCost = total
                    bestDepart = origin[dock.id]
                    bestArrive = dock
                end
            end
        end
    end
    if not bestDepart or not bestArrive then
        return nil
    end

    -- Stay aboard through stops that are still the same ride. Get off where
    -- the next step is a walk, or at the landing on the hunt's continent.
    local disembark = bestArrive
    local rev = crossRev
    for i = #rev, 1, -1 do
        rev[i] = nil
    end
    local id = bestArrive.id
    local steps = 0
    while id and steps < 24 do
        rev[#rev + 1] = crossingById[id]
        if id == bestDepart.id then
            break
        end
        id = prev[id]
        steps = steps + 1
    end
    local departAt = #rev
    if departAt > 1 and rev[departAt] and rev[departAt].id == bestDepart.id then
        disembark = rev[departAt - 1]
        local n = departAt - 1
        while n > 1 and viaRide[rev[n].id] and viaRide[rev[n - 1].id] do
            n = n - 1
            disembark = rev[n]
        end
    end
    return bestDepart, disembark
end

function GQ.Guide:AnchorToTracker()
    local frame = self.frame
    local tracker = GQ.Tracker and GQ.Tracker.frame
    if not frame or not tracker or frame.anchorHost == tracker then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", tracker, "TOPLEFT", 0, 4)
    frame.anchorHost = tracker
    local strata = tracker.GetFrameStrata and tracker:GetFrameStrata()
    if strata then
        frame:SetFrameStrata(strata)
    end
    if tracker.GetFrameLevel and frame.SetFrameLevel then
        frame:SetFrameLevel((tracker:GetFrameLevel() or 0) + 4)
    end
end

function GQ.Guide:RefreshChecks()
    if GQ.Tracker and GQ.Tracker.UpdateGuideChecks then
        GQ.Tracker:UpdateGuideChecks()
    end
end

function GQ.Guide:ShowEntry(entry)
    if not entry or not entry.id then
        return
    end
    CharSettings().guideEntryId = entry.id
    self._waypointKey = nil
    self:Apply()
    self:PlaceForeverPin(entry)
    self:RefreshChecks()
    if GQ.Pins and GQ.Pins.Sync then
        GQ.Pins:Sync()
    end
end

function GQ.Guide:PlaceForeverPin(entry)
    if not (entry and GQ.Map and GQ.Map.SpotForEntry and C_Map and C_Map.SetUserWaypoint and UiMapPoint) then
        return
    end
    local spot = GQ.Map:SpotForEntry(entry)
    if not spot or not spot.mapId or not spot.x or not spot.y then
        return
    end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(spot.mapId) then
        return
    end
    local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(spot.mapId, spot.x / 100, spot.y / 100))
    if not ok then
        return
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    self.ownsWaypoint = true
    self._waypointKey = string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0)
end

function GQ.Guide:ClearForeverPin()
    if not self.ownsWaypoint then
        return
    end
    self.ownsWaypoint = false
    self._waypointKey = nil
    if C_Map and C_Map.ClearUserWaypoint then
        pcall(C_Map.ClearUserWaypoint)
    end
end

function GQ.Guide:Dismiss()
    CharSettings().guideEntryId = nil
    self:ClearForeverPin()
    self:Apply()
    self:RefreshChecks()
    if GQ.Pins and GQ.Pins.Sync then
        GQ.Pins:Sync()
    end
end

local function HideGuide(frame)
    if not frame then
        return
    end
    -- A hidden frame still runs OnUpdate. A leftover id keeps sampling the map.
    frame.entryId = nil
    frame.spot = nil
    frame.spotUntil = nil
    local shown = frame.IsShown and frame:IsShown()
    frame:Hide()
    if not shown then
        return
    end
    frame.aim = nil
    frame.aimSpot = nil
    frame.crossingCache = nil
    frame.crossing = nil
    frame.crossingTo = nil
    -- Once, on the close. The map objects from this session are already
    -- unhooked. This is what lets that memory fall instead of sitting there.
    if collectgarbage then
        collectgarbage("collect")
    end
end

function GQ.Guide:Apply()
    local frame = self.frame
    if not frame then
        return
    end
    local id = CharSettings().guideEntryId
    if self:IsSuppressed() or not id then
        HideGuide(frame)
        return
    end
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if not entry then
        HideGuide(frame)
        return
    end
    frame.entryId = id
    frame.spot = nil
    frame.spotUntil = 0
    frame:Show()
end

local function UpdateGuide(frame)
    local saved = GQ.Guide:GuidedId()
    local id = frame.entryId
    if not saved or id ~= saved or GQ.Guide:IsSuppressed() then
        if id or (frame.IsShown and frame:IsShown()) then
            HideGuide(frame)
        end
        return
    end
    GQ.Guide:AnchorToTracker()
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if not entry then
        HideGuide(frame)
        return
    end
    local now = GetTime and GetTime() or 0
    if not frame.spotUntil or now >= frame.spotUntil then
        frame.spotUntil = now + SAMPLE_SEC
        frame.spot = GQ.Data and GQ.Data.NearestCoordinateSpot and GQ.Data:NearestCoordinateSpot(entry.itemId) or nil
    end
    local spot = frame.spot
    local facing = 0
    if GetPlayerFacing then
        local ok, value = pcall(GetPlayerFacing)
        if ok and type(value) == "number" then
            facing = value
        end
    end
    local sample = frame.aim
    local refresh = not sample or sample.spot ~= spot or now >= (frame.aimUntil or 0)
    if refresh then
        sample = { spot = spot, text = spot and L.Zone(spot.map) or L["No pin"], kind = "none" }
        local spotMap = spot and GQ.Data and GQ.Data.SpotMapId and GQ.Data:SpotMapId(spot)
        local px, py = spotMap and PositionOn(spotMap)
        if spot and px and py and spot.x and spot.y then
        local sx, sy = spot.x / 100, spot.y / 100
        local pc, pwx, pwy = WorldOn(spotMap, px, py)
        local sc, swx, swy = WorldOn(spotMap, sx, sy)
        if pc and sc and pc == sc then
            local dx = swx - pwx
            local dy = swy - pwy
            local dist = math.sqrt(dx * dx + dy * dy)
            sample.text = FormatYards(dist) or sample.text
            sample.mapId = spotMap
            sample.dx = dx
            sample.dy = dy
            sample.kind = dist < HERE_YARDS and "here" or "world"
        else
            -- Map y grows south. Yards need a world position, so the line
            -- keeps the zone name until that conversion exists.
            sample.kind = "map"
            sample.east = sx - px
            sample.north = py - sy
            sample.text = L.Zone(spot.map) or sample.text
        end
    elseif spot and spotMap and spot.x and spot.y and C_Map and C_Map.GetBestMapForUnit then
        local playerMap = C_Map.GetBestMapForUnit("player")
        local guard = 0
        local pc, pwx, pwy
        while playerMap and guard < 8 and not pc do
            local x, y = PositionOn(playerMap)
            if x and y then
                pc, pwx, pwy = WorldOn(playerMap, x, y)
            end
            if pc then
                break
            end
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(playerMap)
            playerMap = info and info.parentMapID
            if playerMap == 0 then
                break
            end
            guard = guard + 1
        end
        local sc, swx, swy = WorldOn(spotMap, spot.x / 100, spot.y / 100)
        if pc and sc and pc == sc then
            local dx = swx - pwx
            local dy = swy - pwy
            local dist = math.sqrt(dx * dx + dy * dy)
            sample.text = FormatYards(dist) or sample.text
            sample.mapId = spotMap
            sample.dx = dx
            sample.dy = dy
            sample.kind = dist < HERE_YARDS and "here" or "world"
        else
            local dock, arrive
            if pc and sc and pc ~= sc then
                -- The dock does not change while you stand still. Searching
                -- every frame rebuilt the route graph for the whole trip.
                local cache = frame.crossingCache
                local faction = UnitFactionGroup and UnitFactionGroup("player")
                local sameHunt = cache and cache.pc == pc and cache.sc == sc
                    and cache.faction == faction
                    and cache.hwx and swx and math.abs(cache.hwx - swx) < 80
                    and math.abs(cache.hwy - swy) < 80
                local stillClose = sameHunt and cache.pwx
                    and math.abs(cache.pwx - pwx) < 600
                    and math.abs(cache.pwy - pwy) < 600
                if stillClose then
                    dock, arrive = cache.dock, cache.arrive
                else
                    dock, arrive = NearestCrossing(pc, pwx, pwy, sc, swx, swy)
                    frame.crossingCache = {
                        pc = pc, sc = sc, faction = faction,
                        hwx = swx, hwy = swy, pwx = pwx, pwy = pwy,
                        dock = dock, arrive = arrive,
                    }
                end
            end
            if dock then
                local dx = dock.wx - pwx
                local dy = dock.wy - pwy
                local dist = math.sqrt(dx * dx + dy * dy)
                sample.dock = dock
                sample.arrive = arrive
                sample.mapId = dock.mapId
                sample.dx = dx
                sample.dy = dy
                if dist < HERE_YARDS then
                    sample.kind = "here"
                    sample.text = L["Here"]
                else
                    sample.kind = "world"
                    sample.text = dock.kind
                end
            else
                local here = C_Map.GetBestMapForUnit("player")
                local shared = here and CommonMap(here, spotMap)
                local ppx, ppy, ssx, ssy
                if shared then
                    ppx, ppy = PositionOn(shared)
                    if not ppx and here then
                        local hx, hy = PositionOn(here)
                        ppx, ppy = ProjectToMap(here, hx, hy, shared)
                    end
                    ssx, ssy = ProjectToMap(spotMap, spot.x / 100, spot.y / 100, shared)
                end
                if ppx and ppy and ssx and ssy then
                    sample.kind = "map"
                    sample.east = ssx - ppx
                    sample.north = ppy - ssy
                    sample.text = L.Zone(spot.map) or sample.text
                end
            end
        end
    end
        frame.aim = sample
        frame.aimUntil = now + SAMPLE_SEC
        if spot and GQ.Guide.ownsWaypoint then
            local key = string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0)
            if key ~= GQ.Guide._waypointKey then
                local guided = GQ.Data:GetEntryById(id)
                if guided then
                    GQ.Guide:PlaceForeverPin(guided)
                end
                GQ.Guide._waypointKey = key
            end
        end
    end
    frame.crossing = sample.dock
    frame.crossingTo = sample.arrive
    local text = sample.text
    local rotation = 0
    if sample.kind == "here" then
        rotation = math.pi
    elseif sample.kind == "world" then
        rotation = AimWorld(sample.mapId, sample.dx, sample.dy, facing)
    elseif sample.kind == "map" then
        rotation = Aim(sample.east, sample.north, facing)
    end
    if frame.distance and frame.distanceText ~= text then
        frame.distanceText = text
        frame.distance:SetText(text)
    end
    if frame.arrow then
        frame.arrow:Show()
        frame.arrow:SetAlpha(1)
        local rel = WrapPi(rotation)
        local index = text == "Here" and (ARROW_FRAMES / 2) or ArrowIndex(rel)
        local left = index / ARROW_FRAMES
        frame.arrow:SetTexCoord(left, left + 1 / ARROW_FRAMES, 0, 1)
    end
end

function GQ.Guide:Init()
    if GearQuestForeverDB and GearQuestForeverDB.settings then
        GearQuestForeverDB.settings.guideEntryId = nil
    end
    if self.frame then
        self:AnchorToTracker()
        self:Apply()
        return
    end

    local frame = CreateFrame("Frame", "GearQuestGuide", UIParent)
    frame:SetSize(136, 130)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        GameTooltip:Hide()
        local tracker = GQ.Tracker and GQ.Tracker.frame
        if tracker and tracker.StartMoving then
            tracker:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        local tracker = GQ.Tracker and GQ.Tracker.frame
        if tracker and tracker.StopMovingOrSizing then
            tracker:StopMovingOrSizing()
        end
        if GQ.Tracker and GQ.Tracker.SavePosition then
            GQ.Tracker:SavePosition()
        end
    end)
    frame:SetScript("OnUpdate", UpdateGuide)
    frame:SetScript("OnEnter", function(self)
        local entry = self.entryId and GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(self.entryId)
        if not entry then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local name = GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry) or entry.questName or "Hunt"
        GameTooltip:SetText(name, GOLD_R, GOLD_G, GOLD_B)
        local spot = self.spot
        if spot and spot.map then
            GameTooltip:AddLine(string.format("%s %.1f, %.1f", L.Zone(spot.map), spot.x or 0, spot.y or 0), 1, 1, 1)
        end
        if self.crossing then
            local depart = self.crossing
            local dest = self.crossingTo
            local line = L("%s in %s", L[depart.kind], L.Zone(depart.place or depart.zone))
            if dest and dest.place and dest.id ~= depart.id then
                line = line .. L(" to %s", L.Zone(dest.place))
            end
            GameTooltip:AddLine(line, 1, 1, 1)
        end
        GameTooltip:AddLine(L["Drag to move"], 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local distance = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, _, flags = GameFontNormal:GetFont()
    if font then
        distance:SetFont(font, 16, "OUTLINE")
    end
    distance:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    distance:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    distance:SetWidth(112)
    distance:SetJustifyH("LEFT")
    distance:SetText(" ")
    frame.distance = distance

    local arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(110, 110)
    arrow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18)
    arrow:SetTexture(ARROW_TEXTURE)
    frame.arrow = arrow

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(18, 18)
    close:SetPoint("TOPLEFT", frame, "TOPLEFT", 114, 0)
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if font then
        closeText:SetFont(font, 13, "OUTLINE")
    end
    closeText:SetPoint("CENTER", close, "CENTER", 1, 0)
    closeText:SetText("X")
    closeText:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    close:SetScript("OnClick", function()
        GQ.Guide:Dismiss()
    end)
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Remove the guide"], 1, 1, 1)
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.frame = frame
    frame:Hide()
    self:AnchorToTracker()
    self:Apply()
end
