local _, GQ = ...
local L = GQ.L

GQ.Compare = GQ.Compare or {}

local function GetItemLevel(itemLinkOrId, entry)
    if type(entry) == "table" and entry.minLevel then
        local itemId = entry.itemId or itemLinkOrId
        if itemId then
            local _, _, _, itemLevel = GetItemInfo(itemId)
            if itemLevel and itemLevel > 0 then
                return itemLevel
            end
        end
        return entry.minLevel
    end

    if not itemLinkOrId then
        return 0
    end

    if type(itemLinkOrId) == "number" then
        local _, _, _, itemLevel = GetItemInfo(itemLinkOrId)
        return itemLevel or 0
    end

    local _, _, _, itemLevel = GetItemInfo(itemLinkOrId)
    return itemLevel or 0
end

function GQ.Compare:GetEquippedItemLevel(slotName)
    local invSlots = GQ.Data:GetInventorySlots(slotName)
    if #invSlots == 0 then
        return 0
    end

    if #invSlots == 1 then
        local link = GetInventoryItemLink("player", invSlots[1])
        return GetItemLevel(link)
    end

    -- Rings/trinkets: compare against the weaker equipped slot.
    local lowestIlvl
    for _, invSlot in ipairs(invSlots) do
        local ilvl = GetItemLevel(GetInventoryItemLink("player", invSlot))
        if lowestIlvl == nil or ilvl < lowestIlvl then
            lowestIlvl = ilvl
        end
    end

    return lowestIlvl or 0
end

-- Lower-tier armor only ranks if it is clearly stronger than the best preferred-tier option.
local LOWER_ARMOR_ILVL_MARGIN = 8
local LOWER_ARMOR_SCORE_PENALTY = 500

-- Stat-based BiS reordering applies to generated sub-60 picks and notables only.
-- Level 60 Wowhead guide rows (origin="guide") and hand-curated Data.lua rows
-- (generated=false, curatedRank) keep their professional list order untouched.
-- Weights come from GearQuest/_generated/*.weights.json (TBC stat priorities) via
-- StatWeights.generated.lua — spec-aware at every level when the player has
-- picked (or defaulted) a spec. levelling_1_9 is only the no-spec fallback.
-- Weapons still rank on pipeline DPS, not these weights.
-- https://www.wowhead.com/tbc/guide/classic-the-burning-crusade-stats-overview

local STAT_NAME_TO_KEY = {
    Agility = "agi",
    Strength = "str",
    Intellect = "int",
    Stamina = "sta",
    Spirit = "spi",
    ["Attack Power"] = "ap",
    ["Ranged Attack Power"] = "rap",
    ["Feral Attack Power"] = "feralAp",
    Healing = "heal",
    ["Spell Damage"] = "sp",
    ["Spell Power"] = "sp",
    ["Hit Rating"] = "hit",
    ["Critical Strike Rating"] = "crit",
    ["Critical Strike"] = "crit",
    ["Haste Rating"] = "haste",
    ["Expertise Rating"] = "expertise",
    ["Armor Penetration Rating"] = "armorPen",
    ["Spell Hit Rating"] = "spellHit",
    ["Spell Critical Strike Rating"] = "spellCrit",
    ["Spell Critical Strike"] = "spellCrit",
    ["Spell Haste Rating"] = "spellHaste",
}

local DEFAULT_STAT_WEIGHT = {
    agi = 0.5,
    str = 0.5,
    int = 0.5,
    sta = 0.35,
    spi = 0.25,
    ap = 0.15,
    heal = 0.5,
    sp = 0.5,
}

local function GetStatWeightProfile(classFile, playerLevel, specId)
    local classWeights = GQ.StatWeights and GQ.StatWeights[classFile]
    if not classWeights then
        return nil
    end

    if specId and classWeights[specId] then
        return classWeights[specId]
    end

    if playerLevel <= 9 and classWeights.levelling_1_9 then
        return classWeights.levelling_1_9
    end

    return classWeights.default
end

local function ResolveStatWeightKey(statName)
    local key = STAT_NAME_TO_KEY[statName]
    if key then
        return key
    end

    if statName:find("forms only", 1, true) then
        return "feralAp"
    end

    local lower = statName:lower()
    if lower:find("spell hit", 1, true) then
        return "spellHit"
    end
    if lower:find("spell crit", 1, true) or lower:find("spell critical", 1, true) then
        return "spellCrit"
    end
    if lower:find("spell haste", 1, true) then
        return "spellHaste"
    end
    if lower:find("hit rating", 1, true) or lower:find("improves hit", 1, true) then
        return "hit"
    end
    if lower:find("crit rating", 1, true) or lower:find("critical strike", 1, true) then
        return "crit"
    end
    if lower:find("haste rating", 1, true) then
        return "haste"
    end
    if lower:find("expertise", 1, true) then
        return "expertise"
    end
    if lower:find("armor penetration", 1, true) then
        return "armorPen"
    end

    return nil
end

-- Hunters and warlocks rely on pets for mitigation; mail/leather/cloth tier should not
-- reorder DPS gear — only stat totals matter for BiS display.
local ARMOR_CLASS_NEUTRAL_CLASSES = {
    HUNTER = true,
    WARLOCK = true,
}

local function GetArmorClassMultiplier(itemId)
    if not itemId or not GQ.StatWeightsArmorClass or not GQ.Equip or not GQ.Equip.GetItemArmorSubclass then
        return 1
    end

    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass() or "WARRIOR"
    if ARMOR_CLASS_NEUTRAL_CLASSES[classFile] then
        return 1
    end

    local subclass = GQ.Equip:GetItemArmorSubclass(itemId)
    if not subclass then
        return 1
    end

    local playerLevel = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local specId = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or nil
    local classTable = GQ.StatWeightsArmorClass[classFile]
    if not classTable then
        return 1
    end

    local specTable
    if specId and classTable[specId] then
        specTable = classTable[specId]
    elseif playerLevel <= 9 and classTable.levelling_1_9 then
        specTable = classTable.levelling_1_9
    else
        specTable = classTable.default
    end

    if not specTable then
        return 1
    end

    return specTable[subclass] or 1
end

local LEGACY_STAT_WEIGHT = {
    Agility = 1.0,
    Strength = 1.0,
    Stamina = 0.35,
    Intellect = 0.8,
    Spirit = 0.5,
    ["Attack Power"] = 0.15,
    ["Spell Damage"] = 0.8,
    Healing = 0.5,
}

local function TrimStatName(name)
    if strtrim then
        return strtrim(name)
    end
    return (name:gsub("^%s*(.-)%s*$", "%1"))
end

local function SuffixStatWeight(statName)
    return GQ.Compare:GetStatWeight(statName)
end

function GQ.Compare:GetStatWeight(statName)
    statName = TrimStatName(statName)
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass() or "WARRIOR"
    local playerLevel = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local specId = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or nil

    local profile = GetStatWeightProfile(classFile, playerLevel, specId)
    if profile then
        local key = ResolveStatWeightKey(statName)
        if key and profile[key] ~= nil then
            -- Gear "+N Attack Power" is ranged DPS for hunters (1 AP ≈ 1 RAP).
            if classFile == "HUNTER" and key == "ap" then
                return math.max(profile.ap or 0, profile.rap or 0)
            end
            -- Pet-tank DPS classes: stamina is QoL, not BiS rank fuel.
            if (classFile == "HUNTER" or classFile == "WARLOCK") and key == "sta" then
                return 0
            end
            return profile[key]
        end
    end

    return LEGACY_STAT_WEIGHT[statName] or DEFAULT_STAT_WEIGHT[STAT_NAME_TO_KEY[statName]] or 0.5
end

-- Best possible roll from a suffixRange string ("+1-2 Agility", "+11 Agility", etc.).
function GQ.Compare:ScoreSuffixRangeMax(suffixRange)
    if not suffixRange or suffixRange == "" then
        return 0
    end

    local total = 0
    local ranged = {}

    for minVal, maxVal, statName in suffixRange:gmatch("+(%d+)-(%d+) ([^,]+)") do
        ranged[minVal .. "-" .. maxVal .. " " .. statName] = true
        total = total + tonumber(maxVal) * SuffixStatWeight(statName)
    end

    for val, statName in suffixRange:gmatch("+(%d+) ([^,]+)") do
        local token = val .. " " .. statName
        local isRangeHalf = false
        for key in pairs(ranged) do
            if key:find("^" .. val .. "-", 1, false) and key:find(statName, 1, true) then
                isRangeHalf = true
                break
            end
        end
        if not isRangeHalf then
            total = total + tonumber(val) * SuffixStatWeight(statName)
        end
    end

    return total
end

function GQ.Compare:ScoreSuffixRangeExpected(suffixRange, suffixChance)
    if not suffixRange or suffixRange == "" then
        return 0
    end

    local maxScore = self:ScoreSuffixRangeMax(suffixRange)
    if maxScore <= 0 then
        return 0
    end

    local chance = suffixChance
    if not chance or chance <= 0 then
        chance = 10
    elseif chance > 100 then
        chance = 100
    end

    local midpoint = 0
    local ranged = {}
    local hasRange = false

    for minVal, maxVal, statName in suffixRange:gmatch("+(%d+)-(%d+) ([^,]+)") do
        hasRange = true
        ranged[minVal .. "-" .. maxVal .. " " .. statName] = true
        midpoint = midpoint + ((tonumber(minVal) + tonumber(maxVal)) / 2) * SuffixStatWeight(statName)
    end

    for val, statName in suffixRange:gmatch("+(%d+) ([^,]+)") do
        local isRangeHalf = false
        for key in pairs(ranged) do
            if key:find("^" .. val .. "-", 1, false) and key:find(statName, 1, true) then
                isRangeHalf = true
                break
            end
        end
        if not isRangeHalf then
            hasRange = true
            midpoint = midpoint + tonumber(val) * SuffixStatWeight(statName)
        end
    end

    if not hasRange then
        midpoint = maxScore
    end

    return midpoint * (chance / 100)
end

local function ParseStatAmount(statKey)
    if not statKey then
        return nil, nil
    end

    local amount, statName = statKey:match("+(%d+) (.+)")
    if amount and statName then
        return tonumber(amount), TrimStatName(statName)
    end

    amount, statName = statKey:match("(%d+) (.+)")
    if amount and statName then
        return tonumber(amount), TrimStatName(statName)
    end

    local modAliases = {
        ITEM_MOD_AGILITY_SHORT = "Agility",
        ITEM_MOD_STRENGTH_SHORT = "Strength",
        ITEM_MOD_STAMINA_SHORT = "Stamina",
        ITEM_MOD_INTELLECT_SHORT = "Intellect",
        ITEM_MOD_SPIRIT_SHORT = "Spirit",
        ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged Attack Power",
        ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "Feral Attack Power",
        ITEM_MOD_HIT_RATING_SHORT = "Hit Rating",
        ITEM_MOD_HIT_RATING = "Hit Rating",
        ITEM_MOD_HIT_MELEE_RATING = "Hit Rating",
        ITEM_MOD_HIT_RANGED_RATING = "Hit Rating",
        ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike Rating",
        ITEM_MOD_CRIT_RATING = "Critical Strike Rating",
        ITEM_MOD_CRIT_MELEE_RATING = "Critical Strike Rating",
        ITEM_MOD_CRIT_RANGED_RATING = "Critical Strike Rating",
        ITEM_MOD_HASTE_RATING_SHORT = "Haste Rating",
        ITEM_MOD_HASTE_RATING = "Haste Rating",
        ITEM_MOD_HASTE_MELEE_RATING = "Haste Rating",
        ITEM_MOD_HASTE_RANGED_RATING = "Haste Rating",
        ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise Rating",
        ITEM_MOD_EXPERTISE_RATING = "Expertise Rating",
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "Armor Penetration Rating",
        ITEM_MOD_ARMOR_PENETRATION_RATING = "Armor Penetration Rating",
        ITEM_MOD_HIT_SPELL_RATING_SHORT = "Spell Hit Rating",
        ITEM_MOD_HIT_SPELL_RATING = "Spell Hit Rating",
        ITEM_MOD_CRIT_SPELL_RATING_SHORT = "Spell Critical Strike Rating",
        ITEM_MOD_CRIT_SPELL_RATING = "Spell Critical Strike Rating",
        ITEM_MOD_HASTE_SPELL_RATING_SHORT = "Spell Haste Rating",
        ITEM_MOD_HASTE_SPELL_RATING = "Spell Haste Rating",
        ITEM_MOD_SPELLPOWER_SHORT = "Spell Damage",
        ITEM_MOD_SPELL_POWER_SHORT = "Spell Damage",
    }
    local alias = modAliases[statKey]
    if alias then
        return nil, alias
    end

    return nil, nil
end

local function MergeItemStatTable(into, from)
    if type(from) ~= "table" then
        return
    end
    for statKey, amount in pairs(from) do
        if type(amount) == "number" and amount > 0 then
            into[statKey] = amount
        end
    end
end

local function CollectItemStats(itemLink, itemId)
    local statTable = {}

    if GetItemStats and itemLink then
        local base = {}
        if GetItemStats(itemLink, base) then
            MergeItemStatTable(statTable, base)
        end
    end

    if C_Item and C_Item.GetItemStats then
        local enriched = C_Item.GetItemStats(itemLink or itemId)
        MergeItemStatTable(statTable, enriched)
    end

    return statTable
end

local function ScoreNormalizedStats(statTable)
    local byName = {}

    for statKey, amount in pairs(statTable) do
        if type(amount) == "number" and amount > 0 then
            local parsedAmount, statName = ParseStatAmount(statKey)
            if statName then
                local value = parsedAmount or amount
                -- Melee/ranged hit often duplicate the same equip aura — take max.
                byName[statName] = math.max(byName[statName] or 0, value)
            end
        end
    end

    local total = 0
    for statName, amount in pairs(byName) do
        total = total + amount * SuffixStatWeight(statName)
    end

    return total
end

local function ParseTooltipStatLine(text, byName)
    text = GQ.PublicText(text)
    if not text then
        return
    end

    for amount, stat in text:gmatch("+(%d+) ([^+]+)") do
        stat = TrimStatName(stat)
        if ResolveStatWeightKey(stat) or STAT_NAME_TO_KEY[stat] then
            byName[stat] = math.max(byName[stat] or 0, tonumber(amount))
        end
    end

    local patterns = {
        { "(%d+) hit rating", "Hit Rating" },
        { "[Ii]mproves hit rating by (%d+)", "Hit Rating" },
        { "[Ii]ncreases attack power by (%d+)", "Attack Power" },
        { "[Ii]ncreases ranged attack power by (%d+)", "Ranged Attack Power" },
        { "(%d+) critical strike rating", "Critical Strike Rating" },
        { "[Ii]mproves critical strike rating by (%d+)", "Critical Strike Rating" },
        { "[Ii]ncreases damage done by magical spells and effects by up to (%d+)", "Spell Damage" },
        { "[Ii]ncreases healing done by spells and effects by up to (%d+)", "Healing" },
    }

    local lower = text:lower()
    for _, pattern in ipairs(patterns) do
        local amount = text:match(pattern[1])
        if not amount and lower then
            amount = lower:match(pattern[1]:lower())
        end
        if amount then
            local statName = pattern[2]
            byName[statName] = math.max(byName[statName] or 0, tonumber(amount))
        end
    end
end

local function ScoreItemStatsFromTooltip(itemId, itemLink)
    if not GQ.Data or not GQ.Data.GetTooltipScanner then
        return 0
    end

    local scanner = GQ.Data:GetTooltipScanner()
    if not scanner then
        return 0
    end

    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()

    if itemLink then
        scanner:SetHyperlink(itemLink)
    elseif itemId then
        scanner:SetHyperlink("item:" .. itemId)
    else
        return 0
    end

    local byName = {}
    local scannerName = scanner:GetName()
    for i = 1, scanner:NumLines() do
        local line = _G[scannerName .. "TextLeft" .. i]
        if line then
            ParseTooltipStatLine(line:GetText(), byName)
        end
    end

    local total = 0
    for statName, amount in pairs(byName) do
        total = total + amount * SuffixStatWeight(statName)
    end

    return total
end

function GQ.Compare:ScoreItemStats(entry)
    if not entry or not entry.itemId then
        return 0
    end

    if GQ.Equip and GQ.Equip.PrimeItem then
        GQ.Equip:PrimeItem(entry.itemId)
    else
        GetItemInfo(entry.itemId)
    end

    local itemLink = select(2, GetItemInfo(entry.itemId))
    if not itemLink then
        itemLink = "item:" .. entry.itemId
    end

    local statTable = CollectItemStats(itemLink, entry.itemId)
    local apiScore = next(statTable) and ScoreNormalizedStats(statTable) or 0
    if apiScore > 0 then
        return apiScore * GetArmorClassMultiplier(entry.itemId)
    end

    local tooltipScore = ScoreItemStatsFromTooltip(entry.itemId, itemLink)
    local statScore = math.max(apiScore, tooltipScore)

    if statScore <= 0 then
        return 0
    end

    return statScore * GetArmorClassMultiplier(entry.itemId)
end

function GQ.Compare:GetEntryPowerScore(entry)
    if not entry then
        return 0
    end

    if entry.suffix and entry.suffixRange and entry.suffixRange ~= "" then
        local maxSuffix = self:ScoreSuffixRangeMax(entry.suffixRange)
        local score = maxSuffix
        if entry.pipelineScore then
            score = math.max(score, entry.pipelineScore)
        end
        return score
    end

    if entry.pipelineScore then
        return entry.pipelineScore
    end

    return self:ScoreItemStats(entry)
end

function GQ.Compare:ScoreEntry(entry, equippedIlvl, slotName, maxPreferredIlvl)
    local itemIlvl = GetItemLevel(entry.itemId, entry)
    local upgradeDelta = itemIlvl - equippedIlvl

    -- Simple relevance: prefer higher item level upgrades; slight bonus for quest/boss sources.
    local sourceBonus = 0
    if entry.sourceType == "quest_reward" then
        sourceBonus = 2
    elseif entry.sourceType == "boss_drop" or entry.sourceType == "raid_trash" then
        sourceBonus = 1
    elseif entry.sourceType == "vendor" then
        sourceBonus = 1
    elseif entry.sourceType == "profession" then
        sourceBonus = 1
    end

    local armorPenalty = 0
    if slotName and GQ.Equip and GQ.Equip.MeetsArmorPreference then
        local classFile = GQ:GetEffectiveClass()
        local playerLevel = GQ:GetEffectiveLevel()
        if not GQ.Equip:MeetsArmorPreference(entry.itemId, slotName, classFile, playerLevel) then
            if not maxPreferredIlvl or itemIlvl < maxPreferredIlvl + LOWER_ARMOR_ILVL_MARGIN then
                armorPenalty = -LOWER_ARMOR_SCORE_PENALTY
            end
        end
    end

    return upgradeDelta * 10 + sourceBonus + armorPenalty, itemIlvl
end

function GQ.Compare:UsesCuratedOrder(entry)
    if not entry or not entry.curatedRank then
        return false
    end

    if entry.origin == "guide" then
        return true
    end

    local playerLevel = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    if playerLevel >= 60 and not entry.generated then
        return true
    end

    return false
end

-- Unified display sort key: best possible item power first (left / top).
function GQ.Compare:GetSortScore(entry, slotName, equippedIlvl, maxPreferredIlvl)
    if not entry then
        return 0
    end

    if self:UsesCuratedOrder(entry) then
        return 1000000 - entry.curatedRank
    end

    -- Same order as the (i) rank list: curated place, then pipeline score.
    -- A hand-placed Forever piece is not marked generated. Scoring it as raw
    -- item power dropped it out of the three hunt rows while the rank list
    -- still counted it, so the rows read #1, #3, #4 or #1, #3, #2.
    if type(entry.curatedRank) == "number" and entry.curatedRank > 0 and not entry.notable then
        return 500000 - entry.curatedRank + (tonumber(entry.pipelineScore) or 0) * 0.0001
    end

    local itemIlvl = GetItemLevel(entry.itemId, entry)
    local score = self:GetEntryPowerScore(entry)

    if score > 0 then
        return score + itemIlvl * 0.001
    end

    local runtimeScore = self:ScoreEntry(entry, equippedIlvl, slotName, maxPreferredIlvl)
    return runtimeScore / 100 + itemIlvl * 0.01
end

function GQ.Compare:RankEntries(entries, slotName, maxResults)
    maxResults = maxResults or 3
    local equippedIlvl = self:GetEquippedItemLevel(slotName)
    local classFile = GQ:GetEffectiveClass()
    local playerLevel = GQ:GetEffectiveLevel()
    local maxPreferredIlvl = 0
    local equip = GQ.Equip
    local prevSuppress = equip and equip._suppressItemPrime
    if equip then
        equip._suppressItemPrime = true
    end

    if GQ.Equip and GQ.Equip.MeetsArmorPreference then
        for _, entry in ipairs(entries) do
            if (not GQ.Equip.MeetsRequiredLevel or GQ.Equip:MeetsRequiredLevel(entry.itemId, playerLevel))
                and GQ.Equip:MeetsArmorPreference(entry.itemId, slotName, classFile, playerLevel) then
                maxPreferredIlvl = math.max(maxPreferredIlvl, GetItemLevel(entry.itemId, entry))
            end
        end
    end

    local scored = {}

    for _, entry in ipairs(entries) do
        if GQ.Equip and GQ.Equip.EntryArmorIsWearable and not GQ.Equip:EntryArmorIsWearable(entry, slotName) then
            -- A hunter cannot wear mail until 40. Leave it out of the three rows.
        elseif not GQ.Equip or not GQ.Equip.MeetsRequiredLevel
            or GQ.Equip:MeetsRequiredLevel(entry.itemId, playerLevel) then
            local sortScore = self:GetSortScore(entry, slotName, equippedIlvl, maxPreferredIlvl)
            local _, itemIlvl = self:ScoreEntry(entry, equippedIlvl, slotName, maxPreferredIlvl)
            table.insert(scored, { entry = entry, sortScore = sortScore, itemIlvl = itemIlvl })
        end
    end

    table.sort(scored, function(a, b)
        if a.sortScore ~= b.sortScore then
            return a.sortScore > b.sortScore
        end

        local rankA = a.entry.curatedRank
        local rankB = b.entry.curatedRank
        if rankA and rankB and rankA ~= rankB then
            return rankA < rankB
        end
        if rankA and not rankB then
            return true
        end
        if rankB and not rankA then
            return false
        end

        return a.itemIlvl > b.itemIlvl
    end)

    local results = {}
    local seenName = {}
    for i = 1, #scored do
        if #results >= maxResults then
            break
        end
        local entry = scored[i].entry
        local name = GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(entry.itemId)
        if name and name ~= "" and seenName[name] then
            -- skip PvP rank twin
        else
            if name and name ~= "" then
                seenName[name] = true
            end
            results[#results + 1] = entry
        end
    end

    if equip then
        equip._suppressItemPrime = prevSuppress
    end

    return results, equippedIlvl
end

local function FormatScoringWeight(value)
    local text = string.format("%.2f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    return text
end

local function ScoringRowsFromWeights(weights, dpsWeight, dpsRanged, speedWeight)
    local rows = {}
    for key, value in pairs(weights or {}) do
        if value > 0 then
            local label = (GQ.ScoringWeightLabels and GQ.ScoringWeightLabels[key]) or key
            rows[#rows + 1] = { label = label, value = value }
        end
    end
    if (dpsWeight or 0) > 0 then
        rows[#rows + 1] = { label = "Melee weapon damage", value = dpsWeight }
    end
    if (dpsRanged or 0) > 0 then
        rows[#rows + 1] = { label = "Ranged weapon damage", value = dpsRanged }
    end
    table.sort(rows, function(a, b)
        if a.value ~= b.value then
            return a.value > b.value
        end
        return a.label < b.label
    end)
    if (speedWeight or 0) ~= 0 then
        local at = #rows + 1
        for i = 1, #rows do
            if rows[i].label == "Melee weapon damage" then
                at = i + 1
                break
            end
        end
        table.insert(rows, at, { label = "Weapon speed", value = speedWeight })
    end
    return rows
end

function GQ.Compare:GetEffectiveScoringRows(classFile, specId, playerLevel)
    playerLevel = playerLevel or 1
    local custom = GQ.Custom and classFile and specId and GQ.Custom.Get and GQ.Custom:Get(classFile, specId)
    if custom then
        local weights, dpsWeight, dpsRanged, speedWeight = GQ.Custom:Weights(classFile, custom, playerLevel)
        local leveling = GQ.ScoringLeveling
        local useLeveling = leveling and playerLevel <= (leveling.untilLevel or 60)
        local rows = ScoringRowsFromWeights(weights, dpsWeight, dpsRanged, speedWeight)
        return rows, custom.name, useLeveling, true
    end

    local classTable = GQ.ScoringWeights and GQ.ScoringWeights[classFile]
    local specRow = classTable and specId and classTable[specId]
    if not specRow or not specRow.weights then
        return nil
    end

    local leveling = GQ.ScoringLeveling
    local useLeveling = leveling and playerLevel <= (leveling.untilLevel or 60)
    local weights = {}
    for key, raw in pairs(specRow.weights) do
        local mult = 1
        if useLeveling and leveling[key] then
            mult = leveling[key]
        end
        local value = raw * mult
        -- Enhancement tank: 1 agility is also 2 armor, plus 1% dodge and
        -- 1% crit per 20. Show that in the same number the scorer uses.
        if specId == "enhancement_tank" and key == "agi" then
            local armorMult = 1
            if useLeveling and leveling.armor then
                armorMult = leveling.armor
            end
            local armorW = (specRow.weights.armor or 0) * armorMult
            value = value + 2 * armorW + (specRow.weights.dodge or 0) / 20 + (specRow.weights.crit or 0) / 20
        end
        weights[key] = value
    end

    local rows = ScoringRowsFromWeights(weights, specRow.dpsWeight, specRow.dpsWeightRanged, specRow.speedWeight)
    return rows, specRow.label, useLeveling, false
end

function GQ.Compare:ShowScoringWeightTooltip(owner)
    if not owner or not GameTooltip then
        return
    end

    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local specId = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local playerLevel = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local rows, specLabel = self:GetEffectiveScoringRows(classFile, specId, playerLevel)

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local title = specLabel
    if GQ.Spec and GQ.Spec.GetSelectedSpecLabel then
        title = GQ.Spec:GetSelectedSpecLabel() or title
    end
    GameTooltip:SetText(title or L["Specialization"], 1, 0.82, 0)

    if not rows then
        GameTooltip:AddLine(L["Click to change specialization."], 1, 1, 1, true)
        GameTooltip:Show()
        return
    end

    GameTooltip:AddLine(L["How GearQuest ranks gear for this spec."], 1, 1, 1, true)
    GameTooltip:AddLine(" ")

    for i = 1, #rows do
        GameTooltip:AddDoubleLine(L[rows[i].label], FormatScoringWeight(rows[i].value), 1, 1, 1, 1, 0.82, 0)
    end
    GameTooltip:Show()
end
