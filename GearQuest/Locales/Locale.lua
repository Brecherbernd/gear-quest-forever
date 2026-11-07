local _, GQ = ...

-- Localization. English is the source text and the fallback: GQ.L[text]
-- returns the translation when the active locale has one, else text itself.
-- Locale files fill their tables only when GetLocale() matches them.
--
-- Data tables stay English on purpose: several code paths search them.
-- Translate at display time:
--   GQ.TL(text)        a data text (instructions, lore, proc), sentence by sentence
--   GQ.TN(kind, name)  a proper noun: zone, npc, quest, item, object, enchant, faction
--   GQ.TX(text)        a label that may be UI text or a place name
--
-- GQ.LocaleText      whole English text -> translation
-- GQ.LocaleSentences one English sentence -> translation
-- GQ.LocaleRules     { pattern, function(...) return translation end } tried in
--                    order on a sentence with no exact translation. A rule
--                    returns nil to pass the sentence on to the next rule.
-- GQ.LocaleObjectives the text after "Objective: " in instructions -> the
--                    quest's objective as the client words it
-- GQ.LocaleNames     English proper noun -> translation, by kind
--
-- GQ.LocaleActive is false on an English client, or when the player picks
-- English in the settings (GQ.ApplyLanguageSetting, after /reload). The
-- tables still load then: GQ.TClient gives the client's name for matching
-- against what the client reports (zones, factions, maps).

GQ.LOCALE = (GetLocale and GetLocale()) or "enUS"
local ENGLISH = GQ.LOCALE == "enUS" or GQ.LOCALE == "enGB"
GQ.LocaleActive = not ENGLISH

local ui = {}
GQ.LocaleUI = ui
-- Text handed out before the saved settings exist: translation -> English key.
local loadTimeKeys = {}
local settingsKnown = false
GQ.L = setmetatable({}, {
    __index = function(_, key)
        if GQ.LocaleActive then
            local translated = ui[key]
            if translated ~= nil then
                if not settingsKnown and loadTimeKeys[translated] == nil then
                    loadTimeKeys[translated] = key
                end
                return translated
            end
        end
        return key
    end,
    __newindex = function(_, key, value)
        ui[key] = value
    end,
})

-- Tables built while the files load take GQ.L text before the saved
-- settings exist. GQ.LocaleTable marks them so English can be put back.
local loadTimeTables = {}
function GQ.LocaleTable(tbl)
    loadTimeTables[#loadTimeTables + 1] = tbl
    return tbl
end

local function RestoreEnglish(tbl, english, depth)
    for key, value in pairs(tbl) do
        if type(value) == "string" and english[value] then
            tbl[key] = english[value]
        elseif type(value) == "table" and depth < 3 then
            RestoreEnglish(value, english, depth + 1)
        end
    end
end

-- Called once the saved settings exist. English keeps the client's own names
-- (items, zones) that the game itself hands back in its language.
function GQ.ApplyLanguageSetting(settings)
    settingsKnown = true
    GQ.LocaleActive = not ENGLISH and not (settings and settings.englishInterface)
    if GQ.LocaleActive or ENGLISH then
        return
    end
    for i = 1, #loadTimeTables do
        RestoreEnglish(loadTimeTables[i], loadTimeKeys, 1)
    end
end

GQ.LocaleText = {}
GQ.LocaleSentences = {}
GQ.LocaleRules = {}
GQ.LocaleObjectives = {}
GQ.LocaleNames = { zone = {}, npc = {}, quest = {}, item = {}, object = {}, enchant = {}, faction = {} }

-- Zone names come from the client, in its own language, through the ids in
-- Locales/Zones.lua (positive = area id, negative = uiMapId).
local zoneCache = {}
local function ClientZoneName(name)
    local cached = zoneCache[name]
    if cached ~= nil then
        return cached or nil
    end
    local id = GQ.ZONE_IDS and GQ.ZONE_IDS[name]
    local found
    if id and id < 0 and C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(-id)
        found = info and info.name
    elseif id and C_Map and C_Map.GetAreaInfo then
        found = C_Map.GetAreaInfo(id)
    end
    if type(found) ~= "string" or found == "" then
        found = nil
    end
    zoneCache[name] = found or false
    return found
end

-- Returns the translation, or nil when this kind has none.
local function Lookup(kind, name)
    local names = GQ.LocaleNames[kind]
    local translated = names and names[name]
    if translated then
        return translated
    end
    if kind == "zone" then
        return ClientZoneName(name)
    end
    return nil
end
GQ.LocaleLookup = Lookup

function GQ.TN(kind, name)
    if type(name) ~= "string" or not GQ.LocaleActive then
        return name
    end
    return Lookup(kind, name) or name
end

-- The client's name for a data name, whatever the display language: for
-- comparing with names the client reports (map names, faction list).
function GQ.TClient(kind, name)
    if type(name) ~= "string" or ENGLISH then
        return name
    end
    return Lookup(kind, name) or name
end

-- A name of unknown kind, as found inside a sentence.
local ANY_ORDER = { "npc", "zone", "quest", "item", "object" }
function GQ.TAny(name)
    if type(name) ~= "string" or not GQ.LocaleActive then
        return name
    end
    for i = 1, #ANY_ORDER do
        local translated = Lookup(ANY_ORDER[i], name)
        if translated then
            return translated
        end
    end
    return name
end

-- A label that may be UI text or a place name (filter rows mix both).
function GQ.TX(text)
    if type(text) ~= "string" then
        return text
    end
    local translated = GQ.L[text]
    if translated ~= text then
        return translated
    end
    return GQ.TN("zone", text)
end

-- Search key: lower case with accents dropped, so "epee" finds "Épée".
-- string.lower only folds ASCII.
local FOLD = {}
for plain, letters in pairs({
    a = "àâäáãåÀÂÄÁÃÅ", c = "çÇ", e = "éèêëÉÈÊË", i = "îïíìÎÏÍÌ", n = "ñÑ",
    o = "ôöóòõÔÖÓÒÕ", u = "ùûüúÙÛÜÚ", y = "ÿýŸÝ", oe = "œŒ", ae = "æÆ",
}) do
    for letter in letters:gmatch("[\192-\255][\128-\191]*") do
        FOLD[letter] = plain
    end
end
function GQ.FoldText(text)
    return (string.lower(text):gsub("[\192-\255][\128-\191]*", FOLD))
end

local function TranslateSentence(sentence)
    local exact = GQ.LocaleSentences[sentence]
    if exact then
        return exact
    end
    local rules = GQ.LocaleRules
    for i = 1, #rules do
        local rule = rules[i]
        local captures = { sentence:match(rule[1]) }
        if captures[1] ~= nil then
            local translated = rule[2](unpack(captures))
            if translated then
                return translated
            end
        end
    end
    return sentence
end
GQ.LocaleTranslateSentence = TranslateSentence

-- One line: split after . ! ? when a space and a capital, quote or bracket follow.
local function TranslateLine(line)
    if line == "" then
        return line
    end
    local out = {}
    local start = 1
    local len = #line
    while start <= len do
        local stop, nextStart
        local search = start
        while true do
            local s, e = line:find("[%.!?]+['\"]?%s+", search)
            if not s then
                break
            end
            local following = line:sub(e + 1, e + 1)
            if following:match("[%u%(\"'%d%+]") then
                stop, nextStart = e, e + 1
                break
            end
            search = e + 1
        end
        if not stop then
            out[#out + 1] = TranslateSentence(line:sub(start))
            break
        end
        local chunk = line:sub(start, stop)
        local body, space = chunk:match("^(.-)(%s+)$")
        out[#out + 1] = TranslateSentence(body) .. space
        start = nextStart
    end
    return table.concat(out)
end

local cache = {}
function GQ.TL(text)
    if type(text) ~= "string" or not GQ.LocaleActive or text == "" then
        return text
    end
    local whole = GQ.LocaleText[text]
    if whole then
        return whole
    end
    local cached = cache[text]
    if cached then
        return cached
    end
    local source = text
    -- A quest objective is the tail of the text and is translated whole.
    local objectiveTail
    local at = text:find("Objective: ", 1, true)
    if at then
        local objective = GQ.LocaleObjectives[text:sub(at + 11)]
        if objective then
            objectiveTail = (GQ.LocaleObjectiveLabel or "Objective: ") .. objective
            text = text:sub(1, at - 1):gsub("%s+$", "")
        end
    end
    local lines = {}
    for line, sep in text:gmatch("([^\n]*)(\n?)") do
        if line == "" and sep == "" then
            break
        end
        lines[#lines + 1] = TranslateLine(line) .. sep
    end
    local translated = table.concat(lines)
    if objectiveTail then
        translated = translated ~= "" and (translated .. " " .. objectiveTail) or objectiveTail
    end
    cache[source] = translated
    return translated
end
