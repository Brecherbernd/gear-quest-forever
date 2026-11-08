-- GearQuest Forever localization core.
-- Usage:  L["English text"]             -> translated text (falls back to the English key)
--         L("English %s text", value)    -> string.format on the translated text
--
-- German is used automatically on a German (deDE) game client.
-- To force German on a client with another language, set this to true:
GearQuest_ForceGerman = false

local _, GQ = ...

local L = {}
GQ.L = setmetatable(L, {
    __index = function(_, key) return key end,
    __call = function(self, key, ...) return string.format(self[key], ...) end,
})
_G.GearQuest_L = GQ.L

L.IsGerman = GearQuest_ForceGerman or GetLocale() == "deDE"

function L.Add(translations)
    if not L.IsGerman then return end
    for english, translated in pairs(translations) do
        rawset(L, english, translated)
    end
end

-- Zone, dungeon, city and faction names. The data files keep the English names
-- (they are also lookup keys); L.Zone() turns them into the client's name for
-- display and for comparing with GetZoneText()/C_Map on a German client.
L.Zones = {}
local zoneKeysByLength
function L.AddZones(translations)
    if not L.IsGerman then return end
    for english, translated in pairs(translations) do
        L.Zones[english] = translated
    end
    zoneKeysByLength = nil
end

function L.Zone(name)
    if type(name) ~= "string" then return name end
    return L.Zones[name] or name
end

-- Names the game reports in the client language (professions) mapped back to the
-- English names the hunt data uses.
local englishByLocal = {}
function L.AddEnglishNames(translations)
    if not L.IsGerman then return end
    for english, translated in pairs(translations) do
        englishByLocal[translated] = english
    end
end

function L.EnglishName(name)
    return englishByLocal[name] or name
end

-- Quest titles: the client returns the localized title once the quest is cached.
function L.QuestTitle(questId, fallback)
    if L.IsGerman and questId and C_QuestLog then
        local getter = C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo
        if getter then
            local ok, title = pcall(getter, questId)
            if ok and type(title) == "string" and title ~= "" then
                return title
            end
        end
    end
    return fallback
end

-- Free text from the generated data (item instructions, notes, Wowhead tooltips).
-- The text is cut into sentences. A sentence is looked up in L.Sentences first;
-- otherwise every rule { luaPattern, replacement } is applied with gsub (the
-- patterns are usually anchored with ^ and $). Zone names are translated last.
L.Sentences = {}
L.TextRules = {}
L.TextPreRules = {} -- run on the whole text before it is cut into sentences

function L.AddTextPreRules(rules)
    if not L.IsGerman then return end
    for _, rule in ipairs(rules) do
        L.TextPreRules[#L.TextPreRules + 1] = rule
    end
end

function L.AddSentences(translations)
    if not L.IsGerman then return end
    for english, translated in pairs(translations) do
        L.Sentences[english] = translated
    end
end

function L.AddTextRules(rules)
    if not L.IsGerman then return end
    for _, rule in ipairs(rules) do
        L.TextRules[#L.TextRules + 1] = rule
    end
end

local function TranslateSentence(sentence)
    local lead, body, trail = sentence:match("^(%s*)(.-)(%s*)$")
    if body == "" then
        return sentence
    end
    local hit = L.Sentences[body] or rawget(L, body)
    if not hit then
        hit = body
        for _, rule in ipairs(L.TextRules) do
            hit = hit:gsub(rule[1], rule[2])
        end
    end
    return lead .. hit .. trail
end

local function TranslateZones(text)
    if not zoneKeysByLength then
        zoneKeysByLength = {}
        for english in pairs(L.Zones) do
            zoneKeysByLength[#zoneKeysByLength + 1] = english
        end
        table.sort(zoneKeysByLength, function(a, b) return #a > #b end)
    end
    -- Whole-word matches only. Replacements are parked behind markers, so a shorter
    -- name ("Stormwind") cannot hit inside an already translated longer one.
    local protected = {}
    for _, english in ipairs(zoneKeysByLength) do
        if text:find(english, 1, true) then
            local escaped = english:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
            text = text:gsub("%f[%w']" .. escaped .. "%f[^%w']", function()
                protected[#protected + 1] = L.Zones[english]
                return "\1" .. #protected .. "\2"
            end)
        end
    end
    return (text:gsub("\1(%d+)\2", function(i) return protected[tonumber(i)] end))
end

local textCache = {}
local cacheSize = 0

function L.Text(text)
    if not L.IsGerman or type(text) ~= "string" or text == "" then
        return text
    end
    if GQ.PublicText then
        local public = GQ.PublicText(text)
        if public ~= text then
            return text
        end
    end
    local cached = textCache[text]
    if cached then return cached end

    local out = rawget(L, text) or L.Sentences[text]
    if not out then
        local pieces = {}
        local rest = text
        for _, rule in ipairs(L.TextPreRules) do
            rest = rest:gsub(rule[1], rule[2])
        end
        while true do
            local a, b = rest:find("[%.!?]%s+")
            if not a then break end
            pieces[#pieces + 1] = TranslateSentence(rest:sub(1, a))
            pieces[#pieces + 1] = rest:sub(a + 1, b)
            rest = rest:sub(b + 1)
        end
        if rest ~= "" then
            pieces[#pieces + 1] = TranslateSentence(rest)
        end
        out = TranslateZones(table.concat(pieces))
    end

    if cacheSize > 4000 then
        textCache, cacheSize = {}, 0
    end
    textCache[text] = out
    cacheSize = cacheSize + 1
    return out
end

-- Translates every string in a list of description lines (in place) and returns it.
function L.TextLines(lines)
    if L.IsGerman and type(lines) == "table" then
        for i = 1, #lines do
            if type(lines[i]) == "string" then
                lines[i] = L.Text(lines[i])
            end
        end
    end
    return lines
end
