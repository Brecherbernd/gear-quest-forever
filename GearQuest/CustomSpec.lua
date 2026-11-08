local _, GQ = ...
local L = GQ.L

GQ.Custom = GQ.Custom or {}

local NAME_LIMIT = 20
local ARMOR_SLOTS = {
    Head = true, Shoulder = true, Chest = true, Wrist = true,
    Hands = true, Waist = true, Legs = true, Feet = true,
}
local SKIP_STAT = { dps = true, spd = true, kind = true, ilvl = true }
local RELIC_KIND = { Totem = true, Idol = true, Libram = true }
local FOLD_INTO = {
    spellHit = "hit", hitRanged = "hit",
    spellCrit = "crit", critRanged = "crit",
    spellHaste = "haste",
}
local DEAD_STAT = { expertise = true, armorPen = true, resilience = true }

local FIELDS = {
    { key = "dpsWeight", label = "Weapon damage", weapon = true },
    { key = "dpsWeightRanged", label = "Ranged weapon damage", weapon = true },
    { key = "speedWeight", label = "Weapon speed", weapon = true },
    { key = "str", label = "Strength" },
    { key = "agi", label = "Agility" },
    { key = "sta", label = "Stamina" },
    { key = "int", label = "Intellect" },
    { key = "spi", label = "Spirit" },
    { key = "ap", label = "Attack power" },
    { key = "rap", label = "Ranged attack power" },
    { key = "feralAp", label = "Feral attack power" },
    { key = "sp", label = "Spell power" },
    { key = "heal", label = "Healing" },
    { key = "sp_from_heal", label = "Healing as spell power" },
    { key = "spHoly", label = "Holy spell power" },
    { key = "spFire", label = "Fire spell power" },
    { key = "spFrost", label = "Frost spell power" },
    { key = "spNature", label = "Nature spell power" },
    { key = "spArcane", label = "Arcane spell power" },
    { key = "spShadow", label = "Shadow spell power" },
    { key = "hit", label = "Hit" },
    { key = "crit", label = "Critical strike" },
    { key = "haste", label = "Haste" },
    { key = "armor", label = "Armor" },
    { key = "health", label = "Health" },
    { key = "hp5", label = "Health per 5" },
    { key = "mana", label = "Mana" },
    { key = "mp5", label = "Mana per 5" },
    { key = "defense", label = "Defense" },
    { key = "dodge", label = "Dodge" },
    { key = "parry", label = "Parry" },
    { key = "blockRating", label = "Block" },
    { key = "blockValue", label = "Block value" },
    { key = "resist", label = "Resistance" },
}

local EMBRACE = {
    [6473] = "Chest", [10410] = "Legs", [10413] = "Hands",
    [10412] = "Waist", [10411] = "Feet",
}
local EMBRACE_SPEC = {
    HUNTER = { beast_mastery = true, marksmanship = true, survival = true },
    ROGUE = { combat = true, assassination = true, subtlety = true },
    SHAMAN = { enhancement = true },
    DRUID = { feral = true },
}
local ROTMENDER = {
    [286978] = "Chest", [286980] = "Waist", [271207] = "Legs",
    [271214] = "Feet", [286979] = "Hands",
}
local ROTMENDER_SPEC = {
    PRIEST = { holy = true, discipline = true },
    DRUID = { restoration = true },
    PALADIN = { holy = true },
    SHAMAN = { restoration = true },
}

local function Trim(text)
    if not text then
        return ""
    end
    if strtrim then
        return strtrim(text)
    end
    return (text:gsub("^%s*(.-)%s*$", "%1"))
end

local function FormatWeight(value)
    if type(value) ~= "number" then
        return "0"
    end
    if value == math.floor(value) then
        return tostring(value)
    end
    local text = string.format("%.4f", value)
    text = text:gsub("0+$", "")
    text = text:gsub("%.$", "")
    return text
end

-- The number an empty box keeps. Through 60 this is the shipped weight times
-- the leveling multiplier, which is the weight the hunt actually uses.
local function EffectiveShipped(key, value)
    value = value or 0
    local leveling = GQ.ScoringLeveling
    local mult = leveling and leveling[key]
    if type(mult) == "number" then
        return value * mult
    end
    return value
end

local function RoundScore(value)
    return math.floor((value * 100) + 0.5) / 100
end

function GQ.Custom:Store()
    if type(GearQuestForeverDB) ~= "table" then
        return nil
    end
    GearQuestForeverDB.customSpecs = GearQuestForeverDB.customSpecs or {}
    return GearQuestForeverDB.customSpecs
end

function GQ.Custom:List(classFile)
    classFile = classFile and string.upper(classFile)
    local store = self:Store()
    if not classFile or not store or type(store[classFile]) ~= "table" then
        return {}
    end
    return store[classFile]
end

function GQ.Custom:Get(classFile, specId)
    if not specId then
        return nil
    end
    local list = self:List(classFile)
    for i = 1, #list do
        if list[i].id == specId then
            return list[i]
        end
    end
end

function GQ.Custom:FindByName(classFile, name)
    name = Trim(name):lower()
    if name == "" then
        return nil
    end
    local list = self:List(classFile)
    for i = 1, #list do
        if Trim(list[i].name):lower() == name then
            return list[i].id
        end
    end
end

function GQ.Custom:BaseOf(specId, classFile)
    local record = self:Get(classFile or (GQ.GetEffectiveClass and GQ:GetEffectiveClass()), specId)
    return record and record.base
end

function GQ.Custom:Option(classFile, specId)
    local record = self:Get(classFile, specId)
    if not record then
        return nil
    end
    local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    if GQ.Spec and GQ.Spec.GetSpecIcon then
        icon = GQ.Spec:GetSpecIcon(record.base, classFile)
    end
    return {
        id = record.id,
        label = record.name,
        icon = icon,
        custom = true,
        base = record.base,
    }
end

local function NextId(list)
    local highest = 0
    for i = 1, #list do
        local n = tonumber((list[i].id or ""):match("^c:(%d+)$"))
        if n and n > highest then
            highest = n
        end
    end
    return "c:" .. tostring(highest + 1)
end

function GQ.Custom:Shipped(classFile, baseSpec)
    local block = GQ.ScoringWeights and GQ.ScoringWeights[classFile]
    local spec = block and block[baseSpec]
    if not spec then
        return nil
    end
    local weights = {}
    for key, value in pairs(spec.weights or {}) do
        weights[key] = value
    end
    return {
        label = spec.label or baseSpec,
        weights = weights,
        dpsWeight = spec.dpsWeight or 0,
        dpsWeightRanged = spec.dpsWeightRanged or 0,
        speedWeight = spec.speedWeight or 0,
    }
end

function GQ.Custom:Weights(classFile, record, level)
    local shipped = self:Shipped(classFile, record.base)
    if not shipped then
        return {}, 0, 0, 0, {}
    end
    local weights = {}
    for key, value in pairs(shipped.weights) do
        weights[key] = value
    end
    local dps = shipped.dpsWeight
    local dpsRanged = shipped.dpsWeightRanged
    local speed = shipped.speedWeight
    local overrides = record.overrides or {}
    local typed = {}
    for key, value in pairs(overrides) do
        if key == "dpsWeight" then
            dps = value
        elseif key == "dpsWeightRanged" then
            dpsRanged = value
        elseif key == "speedWeight" then
            speed = value
        elseif type(value) == "number" then
            weights[key] = value
            typed[key] = true
        end
    end
    local leveling = GQ.ScoringLeveling
    if leveling and (tonumber(level) or 1) <= (leveling.untilLevel or 60) then
        for key, mult in pairs(leveling) do
            if key ~= "untilLevel" and type(mult) == "number" and weights[key] and not typed[key] then
                weights[key] = weights[key] * mult
            end
        end
    end
    return weights, dps, dpsRanged, speed, typed
end

-- Damage Done stays off Spell Power when the player typed that weight.
-- The "damage and healing" line then scores on Healing. A spec that leaves
-- Spell power empty still folds Damage Done in, matching the premade list.
-- Healing with no Spell Power and no Damage Done is one third spell power.
local function Fold(stats, spellPowerTyped)
    local out = {}
    for key, value in pairs(stats) do
        if type(value) == "number" and not SKIP_STAT[key] and not DEAD_STAT[key] then
            out[key] = value
        end
    end
    for src, dst in pairs(FOLD_INTO) do
        if out[src] then
            out[dst] = (out[dst] or 0) + out[src]
            out[src] = nil
        end
    end
    local damage = out.damageDone
    out.damageDone = nil
    if damage and damage ~= 0 and not spellPowerTyped then
        out.sp = (out.sp or 0) + damage
    end
    if out.heal and not out.sp and not (damage and damage ~= 0) then
        local fromHeal = out.heal / 3
        if not out.sp_from_heal or out.sp_from_heal < fromHeal then
            out.sp_from_heal = fromHeal
        end
    end
    return out
end

local function StatScore(stats, weights)
    local total = 0
    for key, value in pairs(stats) do
        local weight = weights[key]
        if weight and weight ~= 0 then
            total = total + value * weight
        end
    end
    return total
end

local function ScorePiece(entry, row, weights, dpsWeight, dpsRanged, speedWeight, armorClass, spellPowerTyped)
    local base = {}
    if row then
        for key, value in pairs(row) do
            if type(value) == "number" and not SKIP_STAT[key] then
                base[key] = value
            end
        end
    end
    local folded = Fold(base, spellPowerTyped)
    local best = StatScore(folded, weights)
    local suffix, suffixChance, suffixRange, suffixId
    local rolls = GQ.Data.itemRolls and entry.itemId and GQ.Data.itemRolls[entry.itemId]
    if rolls then
        for i = 1, #rolls do
            local roll = rolls[i]
            local merged = {}
            for key, value in pairs(base) do
                merged[key] = value
            end
            for key, value in pairs(roll) do
                if type(value) == "number" and key ~= "c" and key ~= "id" then
                    merged[key] = (merged[key] or 0) + value
                end
            end
            local score = StatScore(Fold(merged, spellPowerTyped), weights)
            if score > best then
                best = score
                suffix = roll.n
                suffixChance = roll.c
                suffixRange = roll.r
                suffixId = roll.id
            end
        end
    end
    local slot = entry.slot
    if ARMOR_SLOTS[slot] and armorClass and row and row.kind then
        best = best * (armorClass[row.kind] or 1)
    end
    local dps = row and row.dps or 0
    if dps > 0 then
        local weaponWeight = dpsWeight or 0
        if slot == "Ranged" then
            weaponWeight = dpsRanged or weaponWeight
        elseif slot == "SecondaryHand" then
            weaponWeight = weaponWeight * 0.5
        end
        best = best + dps * weaponWeight
        if speedWeight and speedWeight ~= 0 and slot ~= "Ranged" and slot ~= "SecondaryHand" then
            best = best + speedWeight * (row.spd or 0)
        end
    elseif row and RELIC_KIND[row.kind] and best <= 0 then
        best = (row.ilvl or 0) * 0.01
    end
    return best, suffix, suffixChance, suffixRange, suffixId
end

local function AssignRanks(list)
    local names = {}
    local unique = 0
    for i = 1, #list do
        local entry = list[i]
        entry.curatedRank = i
        local name = tostring(entry.itemId)
        if GQ.Data.GetEntryDisplayName then
            name = GQ.Data:GetEntryDisplayName(entry) or name
        end
        if not names[name] then
            names[name] = true
            unique = unique + 1
        end
        if unique <= 3 then
            entry.reserve = nil
        else
            entry.reserve = true
        end
    end
end

local function BestOther(list, itemId)
    local best = 0
    for i = 1, #list do
        local entry = list[i]
        if entry.itemId ~= itemId and (entry.pipelineScore or 0) > best then
            best = entry.pipelineScore
        end
    end
    return best
end

local function Promote(list, entry)
    for i = 1, #list do
        if list[i] == entry then
            table.remove(list, i)
            break
        end
    end
    table.insert(list, 1, entry)
end

local function SetChoices(found)
    local slots = {}
    for slot in pairs(found) do
        slots[#slots + 1] = slot
    end
    local count = #slots
    local options = {}
    if count == 5 then
        options[#options + 1] = found
    end
    if count == 4 then
        options[#options + 1] = found
    elseif count > 4 then
        for drop = 1, count do
            local sub = {}
            for i = 1, count do
                if i ~= drop then
                    sub[slots[i]] = found[slots[i]]
                end
            end
            options[#options + 1] = sub
        end
    end
    return options
end

local function EmbracePoints(weights, dpsWeight, specId, pieces)
    local points = 0
    if pieces >= 2 then
        points = points + 10 * (weights.int or 0)
    end
    if pieces >= 3 then
        points = points + 10 * (weights.ap or 0)
    end
    if pieces >= 4 then
        points = points + (100 / 10) * (weights.sta or 0)
        if weights.mana and weights.mana ~= 0 then
            points = points + 100 * weights.mana
        elseif weights.int then
            points = points + (100 / 15) * weights.int
        end
    end
    if pieces >= 5 then
        local weapon = dpsWeight or 0
        if weapon <= 0 and specId == "feral" then
            weapon = 14
        elseif weapon <= 0 and (specId == "beast_mastery" or specId == "marksmanship") then
            weapon = 4.31 * (weights.agi or 0)
        end
        if weapon > 0 then
            points = points + (22 * 1.05) * (2 * 1 / 60) * weapon
        end
        if specId == "feral" then
            points = points + 1
        end
    end
    return points
end

local function RotmenderPoints(weights, pieces)
    local points = 0
    if pieces >= 2 then
        points = points + 5 * (weights.resist or 0)
    end
    if pieces >= 3 then
        points = points + 10 * (weights.int or 0)
    end
    if pieces >= 4 then
        if weights.mana and weights.mana ~= 0 then
            points = points + 200 * weights.mana
        elseif weights.int then
            points = points + (200 / 15) * weights.int
        end
    end
    if pieces >= 5 and (weights.heal or 0) > 0 then
        points = points + (200 / 10) * (weights.sta or 0)
    end
    return points
end

local function ApplyPackage(slots, found, bonusFor)
    local best, bestCount, bestMargin
    for _, chosen in ipairs(SetChoices(found)) do
        local count = 0
        for _ in pairs(chosen) do
            count = count + 1
        end
        local bonus = bonusFor(count)
        local cost = 0
        for slot, entry in pairs(chosen) do
            cost = cost + math.max(0, BestOther(slots[slot], entry.itemId) - (entry.pipelineScore or 0))
        end
        local margin = bonus - cost
        if margin >= 0 and (not best or count > bestCount or (count == bestCount and margin > bestMargin)) then
            best = chosen
            bestCount = count
            bestMargin = margin
        end
    end
    if not best then
        return
    end
    local share = bonusFor(bestCount) / bestCount
    for slot, entry in pairs(best) do
        entry.pipelineScore = RoundScore((entry.pipelineScore or 0) + share)
        Promote(slots[slot], entry)
    end
end

function GQ.Custom:Strip(specId)
    local entries = GQ.Data and GQ.Data.entries
    if not entries or not specId then
        return
    end
    local kept = {}
    for i = 1, #entries do
        local entry = entries[i]
        if not (entry and entry.customSpec == specId) then
            kept[#kept + 1] = entry
        end
    end
    GQ.Data.entries = kept
end

function GQ.Custom:Prepare(classFile, specId)
    classFile = classFile and string.upper(classFile)
    local record = self:Get(classFile, specId)
    if not record or not GQ.Data or not GQ.Data.entries then
        return nil
    end
    self:Strip(specId)
    local armorTables = GQ.StatWeightsArmorClass and GQ.StatWeightsArmorClass[classFile]
    local armorClass = armorTables and (armorTables[record.base] or armorTables.default)
    local weightCache = {}
    local function weightsAt(level)
        local cached = weightCache[level]
        if not cached then
            local weights, dpsWeight, dpsRanged, speedWeight, typed = self:Weights(classFile, record, level)
            cached = { weights, dpsWeight, dpsRanged, speedWeight, typed and typed.sp or false }
            weightCache[level] = cached
        end
        return cached[1], cached[2], cached[3], cached[4], cached[5]
    end

    local entries = GQ.Data.entries
    return {
        classFile = classFile,
        specId = specId,
        record = record,
        armorClass = armorClass,
        weightsAt = weightsAt,
        bands = {},
        stats = GQ.Data.itemStats,
        entries = entries,
        count = #entries,
    }
end

function GQ.Custom:Consume(job, entry)
    local record = job.record
    local classFile = job.classFile
    local specId = job.specId
    if entry and not entry.customSpec and entry.classes and entry.classes[classFile] then
        job.classRows = (job.classRows or 0) + 1
        if entry.generated then
            job.generatedSeen = (job.generatedSeen or 0) + 1
        end
    end
    local base = record.base
    local specHit = entry and entry.specs and base and (entry.specs[base] or entry.specs[string.lower(base)])
    local specMatch = entry and not entry.customSpec and entry.classes and entry.classes[classFile]
        and (specHit or (not entry.specs and not entry.generated))
    if specMatch then
        job.matched = (job.matched or 0) + 1
            local copy = {}
            for key, value in pairs(entry) do
                copy[key] = value
            end
            copy.specs = { [specId] = true }
            copy.customSpec = specId
            copy.id = tostring(entry.id) .. ":" .. specId
            local level = entry.minLevel or 1
            local weights, dpsWeight, dpsRanged, speedWeight, spellPowerTyped = job.weightsAt(level)
            local stats = job.stats
            local row = stats and stats[entry.itemId]
            if row then
                local score, suffix, chance, range, suffixId = ScorePiece(
                    entry, row, weights, dpsWeight, dpsRanged, speedWeight, job.armorClass, spellPowerTyped
                )
                copy.pipelineScore = RoundScore(score)
                if GQ.Data.itemRolls and GQ.Data.itemRolls[entry.itemId] then
                    copy.suffix = suffix
                    copy.suffixChance = chance
                    copy.suffixRange = range
                    copy.suffixId = suffixId
                end
            end
            local faction = "Both"
            if entry.factions then
                local names = {}
                for name, on in pairs(entry.factions) do
                    if on then
                        names[#names + 1] = name
                    end
                end
                table.sort(names)
                if names[1] then
                    faction = table.concat(names, "/")
                end
            end
            local bandKey = faction .. "|" .. tostring(level)
            local bands = job.bands
            local band = bands[bandKey]
            if not band then
                band = { level = level, slots = {} }
                bands[bandKey] = band
            end
            local slot = entry.slot or ""
            local list = band.slots[slot]
            if not list then
                list = {}
                band.slots[slot] = list
            end
            list[#list + 1] = copy
    end
end

function GQ.Custom:Finish(job)
    local classFile = job.classFile
    local record = job.record
    local bands = job.bands
    local entries = GQ.Data and GQ.Data.entries
    if not entries then
        return false
    end
    local added = 0
    local weightsAt = job.weightsAt
    local embraceSpecs = EMBRACE_SPEC[classFile]
    local rotmenderSpecs = ROTMENDER_SPEC[classFile]
    local useEmbrace = embraceSpecs and embraceSpecs[record.base]
    local useRotmender = rotmenderSpecs and rotmenderSpecs[record.base]
    for _, band in pairs(bands) do
        for slot, list in pairs(band.slots) do
            table.sort(list, function(a, b)
                local as, bs = a.pipelineScore or 0, b.pipelineScore or 0
                if as ~= bs then
                    return as > bs
                end
                return (a.itemId or 0) < (b.itemId or 0)
            end)
            local seenItem = {}
            local unique = {}
            for i = 1, #list do
                local itemId = list[i].itemId
                if not seenItem[itemId] then
                    seenItem[itemId] = true
                    unique[#unique + 1] = list[i]
                end
            end
            band.slots[slot] = unique
        end
        if useEmbrace or useRotmender then
            local weights, dpsWeight = weightsAt(band.level)
            if useEmbrace then
                local found = {}
                for slot, list in pairs(band.slots) do
                    for i = 1, #list do
                        if EMBRACE[list[i].itemId] == slot then
                            found[slot] = list[i]
                            break
                        end
                    end
                end
                ApplyPackage(band.slots, found, function(pieces)
                    return EmbracePoints(weights, dpsWeight, record.base, pieces)
                end)
            end
            if useRotmender then
                local found = {}
                for slot, list in pairs(band.slots) do
                    for i = 1, #list do
                        if ROTMENDER[list[i].itemId] == slot then
                            found[slot] = list[i]
                            break
                        end
                    end
                end
                ApplyPackage(band.slots, found, function(pieces)
                    return RotmenderPoints(weights, pieces)
                end)
            end
        end
        for _, list in pairs(band.slots) do
            AssignRanks(list)
            for i = 1, #list do
                entries[#entries + 1] = list[i]
                added = added + 1
            end
        end
    end

    self._built = self._built or {}
    -- Curated rows live in the core file for every class. A walk that only
    -- saw those, before the simulated class's generated hunts were in the
    -- table, must not count as scored. Level 27 would stay empty.
    local generatedSeen = job.generatedSeen or 0
    if added > 0 and generatedSeen > 0 then
        self._built[job.specId] = true
    elseif generatedSeen > 0 and added == 0 and (job.classRows or 0) > 0 then
        self._failed = self._failed or {}
        self._failed[job.specId] = true
        if GQ.Chat then
            local name = record.name or record.base or job.specId
            GQ:Chat("|cffff0000GearQuest|r: " .. L("custom spec %s found no %s hunts to rescore.", name, tostring(record.base)))
        end
    elseif generatedSeen == 0 and job.retried and GQ.Data and GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(job.classFile) then
        self._failed = self._failed or {}
        self._failed[job.specId] = true
    end
    if GQ.Data.BuildIndex then
        GQ.Data:BuildIndex()
    end
    if GQ.Data.InvalidateQueryCache then
        GQ.Data:InvalidateQueryCache()
    end
    return true
end

function GQ.Custom:EnsureWorking()
    local host = GQ.Log and GQ.Log.frame
    if not host then
        return nil
    end
    if self._working then
        if self._working:GetParent() ~= host then
            self._working:SetParent(host)
        end
        self._working:SetAllPoints(host)
        return self._working
    end
    local cover = CreateFrame("Frame", "GearQuestCustomWorking", host)
    cover:SetAllPoints(host)
    cover:SetFrameStrata("FULLSCREEN_DIALOG")
    cover:SetFrameLevel(500)
    cover:EnableMouse(true)
    cover:Hide()
    local shade = cover:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, 0.55)

    local holder = CreateFrame("Frame", nil, cover)
    holder:SetSize(84, 84)
    local face = holder:CreateTexture(nil, "ARTWORK")
    face:SetAllPoints()
    local addon = (GQ and GQ.ADDON_NAME) or "GearQuestForever"
    face:SetTexture("Interface\\AddOns\\" .. addon .. "\\Art\\GearQuest-Portrait")
    face:SetTexCoord(0, 1, 1, 0)
    if holder.CreateMaskTexture and face.AddMaskTexture then
        local mask = holder:CreateMaskTexture()
        mask:SetAllPoints(holder)
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        pcall(face.AddMaskTexture, face, mask)
    end
    local spin = face:CreateAnimationGroup()
    local rot = spin:CreateAnimation("Rotation")
    rot:SetDegrees(-360)
    rot:SetDuration(1.1)
    pcall(function()
        rot:SetOrigin("CENTER", 0, 0)
    end)
    spin:SetLooping("REPEAT")
    cover.spin = spin
    cover.holder = holder

    local text = cover:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", holder, "BOTTOM", 0, -14)
    text:SetText(L["Working on your BiS hunt lists..."])
    text:SetTextColor(1, 0.82, 0)
    cover.text = text
    cover:SetScript("OnHide", function(self)
        if self.spin then
            self.spin:Stop()
        end
    end)
    self._working = cover
    return cover
end

function GQ.Custom:ShowWorking()
    local cover = self:EnsureWorking()
    if not cover then
        return
    end
    cover.holder:ClearAllPoints()
    cover.holder:SetPoint("CENTER", cover, "CENTER", 0, 28)
    cover:Show()
    if cover.spin then
        cover.spin:Play()
    end
end

function GQ.Custom:NoteListPainted()
    if self._job or not self._awaitList then
        return
    end
    self._awaitList = nil
    self:HideWorking()
end

function GQ.Custom:HideWorking()
    if self._working then
        self._working:Hide()
    end
end

function GQ.Custom:EnsureWorker()
    if self._worker then
        return self._worker
    end
    local worker = CreateFrame("Frame")
    worker:Hide()
    worker:SetScript("OnUpdate", function()
        GQ.Custom:Pump()
    end)
    self._worker = worker
    return worker
end

function GQ.Custom:StartBuild(classFile, specId, onDone, modal)
    classFile = classFile and string.upper(classFile)
    local job = self:Prepare(classFile, specId)
    if not job then
        if onDone then
            onDone(false)
        end
        return false
    end
    job.onDone = onDone
    job.modal = modal and true or false
    job.i = 1
    self._job = job
    local logShown = GQ.Log and GQ.Log.frame and GQ.Log.frame.IsShown and GQ.Log.frame:IsShown()
    if job.modal or logShown then
        self:ShowWorking()
    end
    local worker = self:EnsureWorker()
    worker:Show()
    return true
end

function GQ.Custom:Pump()
    local job = self._job
    if not job then
        if self._worker then
            self._worker:Hide()
        end
        return
    end
    local live = GQ.Data and GQ.Data.entries
    if live and live ~= job.entries then
        -- Class load replaced the table. Score the new one from the start.
        job.entries = live
        job.count = #live
        job.i = 1
        job.bands = {}
        job.classRows = 0
        job.matched = 0
        job.generatedSeen = 0
    elseif live and #live > job.count then
        -- Rows were appended after this job started. Keep what is already scored.
        job.count = #live
    end
    local limit = debugprofilestop and (debugprofilestop() + 12) or nil
    local entries = job.entries
    while job.i <= job.count do
        local ok, err = pcall(self.Consume, self, job, entries[job.i])
        if not ok and not job.consumeError then
            job.consumeError = err
            if GQ.Chat then
                GQ:Chat("|cffff0000GearQuest|r: " .. L["custom spec scoring failed: "] .. tostring(err))
            end
        end
        job.i = job.i + 1
        if limit and debugprofilestop() >= limit then
            return
        end
        if not limit and (job.i % 250) == 0 then
            return
        end
    end
    local ok, err = pcall(self.Finish, self, job)
    local built = self._built and self._built[job.specId]
    local failed = self._failed and self._failed[job.specId]
    if ok and not built and not failed and not job.retried
        and GQ.Data and GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(job.classFile) then
        local again = self:Prepare(job.classFile, job.specId)
        if again then
            again.onDone = job.onDone
            again.modal = job.modal
            again.i = 1
            again.retried = true
            self._job = again
            return
        end
    end
    self._job = nil
    if self._worker then
        self._worker:Hide()
    end
    local logShown = GQ.Log and GQ.Log.frame and GQ.Log.frame:IsShown()
    if ok and logShown and self._working and self._working:IsShown() then
        -- The hunt rows are built one slot per frame after this. Leave the
        -- spinner on the log until that list is painted and can scroll.
        self._awaitList = true
    else
        self._awaitList = nil
        self:HideWorking()
    end
    if job.onDone then
        job.onDone(ok, err)
    end
    if not ok then
        self._awaitList = nil
        self:HideWorking()
    end
end

function GQ.Custom:SpecIsIndexed(classFile, specId)
    local by = GQ.Data and GQ.Data.byClassSlotSpec
    local slots = by and classFile and by[classFile]
    if not slots or not specId then
        return false
    end
    for _, specMap in pairs(slots) do
        local list = specMap[specId]
        if type(list) == "table" and list[1] then
            return true
        end
    end
    return false
end

function GQ.Custom:ClearFlags(classFile)
    local list = self:List(classFile)
    self._built = self._built or {}
    self._failed = self._failed or {}
    self._rebuilt = self._rebuilt or {}
    for i = 1, #list do
        local id = list[i].id
        self._built[id] = nil
        self._failed[id] = nil
        self._rebuilt[id] = nil
    end
end

function GQ.Custom:CancelJob(classFile)
    local job = self._job
    if not job or (classFile and job.classFile ~= classFile) then
        return
    end
    self._job = nil
    self._awaitList = nil
    if self._worker then
        self._worker:Hide()
    end
    self:HideWorking()
    local panel = self._editor
    if job.modal and panel and panel.saveButton then
        panel.saveButton:Enable()
        panel.saveButton:SetText(L["Save and score items!"])
    end
end

function GQ.Custom:EnsureBuilt(classFile, specId)
    classFile = classFile and string.upper(classFile)
    if not self:Get(classFile, specId) then
        return false
    end
    if self._built and self._built[specId] then
        if self:SpecIsIndexed(classFile, specId) then
            return true
        end
        self._built[specId] = nil
        if self._rebuilt and self._rebuilt[specId] then
            return false
        end
        self._rebuilt = self._rebuilt or {}
        self._rebuilt[specId] = true
    end
    if self._failed and self._failed[specId] then
        return false
    end
    if self._job and self._job.specId == specId then
        return false
    end
    if not (GQ.Data and GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(classFile)) then
        if GQ.Data and GQ.Data.EnsureClassLoaded then
            GQ.Data:EnsureClassLoaded(classFile)
        end
        if not (GQ.Data and GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(classFile)) then
            return false
        end
    end
    self:StartBuild(classFile, specId, function()
        if GQ.RefreshUI then
            GQ:RefreshUI({ reason = "spec" })
        end
        if GQ.Log and GQ.Log.UpdateSpecButton then
            GQ.Log:UpdateSpecButton()
        end
    end)
    return false
end

function GQ.Custom:OnClassExpanded(classFile)
    -- Scoring starts after the caller indexes the new rows. A score that
    -- starts in here walks the table the class load is about to replace,
    -- and that walk was latching the spec before the simulated class's
    -- hunts were in it.
    self:ClearFlags(classFile)
end

function GQ.Custom:OnClassReleased(classFile)
    self:CancelJob(classFile)
    self:ClearFlags(classFile)
end

function GQ.Custom:Forget(classFile, specId)
    local store = self:Store()
    local list = store and store[classFile]
    if not list then
        return
    end
    local kept = {}
    for i = 1, #list do
        if list[i].id ~= specId then
            kept[#kept + 1] = list[i]
        end
    end
    store[classFile] = kept
    self:Strip(specId)
    if self._built then
        self._built[specId] = nil
    end
    if GQ.Data and GQ.Data.BuildIndex then
        GQ.Data:BuildIndex()
    end
    if GQ.Data and GQ.Data.InvalidateQueryCache then
        GQ.Data:InvalidateQueryCache()
    end
end

-- Editor -----------------------------------------------------------------

local function FieldLabel(field)
    local labels = GQ.ScoringWeightLabels
    if labels and labels[field.key] then
        return L[labels[field.key]]
    end
    return L[field.label]
end

function GQ.Custom:EnsureEditor()
    if self._editor then
        return self._editor
    end
    local parent = (GQ.Log and GQ.Log.frame) or UIParent
    local panel = CreateFrame("Frame", "GearQuestCustomSpecPanel", parent, "BackdropTemplate")
    -- Above the log title. PortraitFrame keeps that title at a high level on the same strata.
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(300)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetSize(700, 480)
    panel:SetPoint("CENTER", parent, "CENTER", 0, 16)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0.07, 0.06, 0.05, 1)
    panel:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    panel:Hide()
    panel:SetScript("OnHide", function(self)
        if self.baseMenu then
            self.baseMenu:Hide()
        end
    end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -16)
    title:SetText(L["Custom stat weights"])
    title:SetTextColor(1, 0.82, 0)
    panel.title = title

    local nameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -52)
    nameLabel:SetText(L["Name"])
    local nameBox = CreateFrame("EditBox", "GearQuestCustomSpecName", panel, "InputBoxTemplate")
    nameBox:SetSize(180, 22)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 6, -6)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(NAME_LIMIT)
    nameBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    nameBox:SetScript("OnTabPressed", function(box)
        GQ.Custom:FocusNextBox(box, IsShiftKeyDown())
    end)
    panel.nameBox = nameBox

    local specLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    specLabel:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", -6, -16)
    specLabel:SetText(L["Based on"])
    local specButton = CreateFrame("Button", "GearQuestCustomSpecBase", panel, "UIPanelButtonTemplate")
    specButton:SetSize(180, 22)
    specButton:SetPoint("TOPLEFT", specLabel, "BOTTOMLEFT", 0, -6)
    specButton:SetText(L["Select a spec"])
    specButton:SetScript("OnClick", function()
        GQ.Custom:ToggleBaseMenu()
    end)
    panel.specButton = specButton

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", specButton, "BOTTOMLEFT", 0, -16)
    hint:SetPoint("RIGHT", panel, "LEFT", 230, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetWordWrap(true)
    hint:SetText(L["The grey number is the weight an empty box uses. Type a number to replace it, including 0. Right-click a custom spec in the list to edit it.")
    panel.hint = hint

    local errorText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    errorText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 22, 54)
    errorText:SetPoint("RIGHT", panel, "LEFT", 230, 0)
    errorText:SetJustifyH("LEFT")
    errorText:SetTextColor(1, 0.35, 0.35)
    panel.errorText = errorText

    local scroll = CreateFrame("ScrollFrame", "GearQuestCustomWeightScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 248, -48)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 52)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(400, 40)
    scroll:SetScrollChild(content)
    panel.scroll = scroll
    panel.content = content
    panel.rows = {}

    local placeholder = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    placeholder:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
    placeholder:SetText(L["Select a spec to see its weights."])
    panel.placeholder = placeholder

    for i = 1, #FIELDS do
        local field = FIELDS[i]
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(390, 24)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((i - 1) * 24))
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label:SetWidth(168)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(FieldLabel(field))
        row.box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        row.box:SetSize(64, 20)
        row.box:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
        row.box:SetAutoFocus(false)
        row.box:SetMaxLetters(12)
        row.box.gqRow = row
        row.box:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
        row.box:SetScript("OnTabPressed", function(box)
            GQ.Custom:FocusNextBox(box, IsShiftKeyDown())
        end)
        row.box:SetScript("OnTextChanged", function(box)
            local owner = box.gqRow
            if not owner or not owner.ghost then
                return
            end
            if (box:GetText() or "") == "" then
                owner.ghost:Show()
            else
                owner.ghost:Hide()
            end
        end)
        row.ghost = row.box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.ghost:SetPoint("LEFT", row.box, "LEFT", 5, 0)
        row.ghost:SetWidth(52)
        row.ghost:SetJustifyH("LEFT")
        row.ghost:SetTextColor(0.5, 0.48, 0.42)
        row.shipped = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.shipped:SetPoint("LEFT", row.box, "RIGHT", 10, 0)
        row.shipped:SetTextColor(0.72, 0.66, 0.5)
        row.field = field
        row:Hide()
        panel.rows[i] = row
    end

    local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteButton:SetSize(90, 24)
    deleteButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 16)
    deleteButton:SetText(L["Delete"])
    deleteButton:SetScript("OnClick", function()
        GQ.Custom:DeleteEditing()
    end)
    deleteButton:Hide()
    panel.deleteButton = deleteButton

    local closeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 24)
    closeButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 16)
    closeButton:SetText(L["Close"])
    closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)

    local saveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveButton:SetSize(180, 24)
    saveButton:SetPoint("RIGHT", closeButton, "LEFT", -8, 0)
    saveButton:SetText(L["Save and score items!"])
    saveButton:SetScript("OnClick", function()
        GQ.Custom:SaveAndScore()
    end)
    panel.saveButton = saveButton

    local menu = CreateFrame("Frame", "GearQuestCustomSpecMenu", panel, "BackdropTemplate")
    menu:SetFrameLevel(panel:GetFrameLevel() + 5)
    menu:SetPoint("TOPLEFT", specButton, "BOTTOMLEFT", 0, -2)
    menu:SetSize(180, 22)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    menu:SetBackdropColor(0.07, 0.06, 0.05, 1)
    menu:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    menu:Hide()
    menu.rows = {}
    panel.baseMenu = menu

    self._editor = panel
    return panel
end

function GQ.Custom:ToggleBaseMenu()
    local panel = self:EnsureEditor()
    local menu = panel.baseMenu
    if menu:IsShown() then
        menu:Hide()
        return
    end
    local classFile = panel.classFile
    local options = GQ.Spec and GQ.Spec:GetOptions(classFile) or {}
    for i, row in ipairs(menu.rows) do
        row:Hide()
    end
    local shown = 0
    for i = 1, #options do
        local opt = options[i]
        if opt.id ~= "levelling_1_9" and not opt.comingLater then
            shown = shown + 1
            local row = menu.rows[shown]
            if not row then
                row = CreateFrame("Button", nil, menu)
                row:SetSize(168, 20)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.label:SetJustifyH("LEFT")
                menu.rows[shown] = row
            end
            row:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -4 - ((shown - 1) * 20))
            row.label:SetText(L[opt.label])
            row.baseId = opt.id
            row:SetScript("OnClick", function(self)
                GQ.Custom:SelectBase(self.baseId)
            end)
            row:Show()
        end
    end
    menu:SetHeight(8 + (shown * 20))
    menu:Show()
end

function GQ.Custom:SelectBase(baseId)
    local panel = self._editor
    if not panel then
        return
    end
    if panel.baseId ~= baseId then
        panel.overrides = {}
    end
    panel.baseId = baseId
    panel.baseMenu:Hide()
    local label = GQ.Spec and GQ.Spec:GetSpecLabel(baseId, panel.classFile) or baseId
    panel.specButton:SetText(label)
    self:RefreshFields()
end

function GQ.Custom:FocusNextBox(box, backward)
    local panel = self._editor
    if not panel or not box then
        return
    end
    local chain = { panel.nameBox }
    for i = 1, #panel.rows do
        if panel.rows[i]:IsShown() then
            chain[#chain + 1] = panel.rows[i].box
        end
    end
    local index = 1
    for i = 1, #chain do
        if chain[i] == box then
            index = i
            break
        end
    end
    local nextIndex = index + (backward and -1 or 1)
    if nextIndex < 1 then
        nextIndex = #chain
    elseif nextIndex > #chain then
        nextIndex = 1
    end
    local target = chain[nextIndex]
    for i = 1, #panel.rows do
        if panel.rows[i].box == target then
            local scroll = panel.scroll
            local rowTop = (i - 1) * 24
            local view = scroll:GetHeight() or 0
            local offset = scroll:GetVerticalScroll() or 0
            if rowTop < offset then
                scroll:SetVerticalScroll(rowTop)
            elseif rowTop + 24 > offset + view then
                local maxScroll = math.max(0, (panel.content:GetHeight() or 0) - view)
                scroll:SetVerticalScroll(math.min(maxScroll, rowTop + 24 - view))
            end
            break
        end
    end
    target:SetFocus()
end

function GQ.Custom:RefreshFields()
    local panel = self._editor
    if not panel then
        return
    end
    local shipped = panel.baseId and self:Shipped(panel.classFile, panel.baseId)
    local overrides = panel.overrides or {}
    if not shipped then
        panel.placeholder:Show()
        for i = 1, #panel.rows do
            panel.rows[i]:Hide()
        end
        panel.content:SetHeight(30)
        return
    end
    panel.placeholder:Hide()
    for i = 1, #panel.rows do
        local row = panel.rows[i]
        local field = row.field
        local value
        if field.weapon then
            value = shipped[field.key] or 0
        else
            value = EffectiveShipped(field.key, shipped.weights[field.key])
        end
        local shown = FormatWeight(value)
        row.shipped:SetText(L["shipped "] .. shown)
        if row.ghost then
            row.ghost:SetText(shown)
        end
        local typed = overrides[field.key]
        if typed == nil then
            row.box:SetText("")
        else
            row.box:SetText(FormatWeight(typed))
        end
        row:Show()
    end
    panel.content:SetHeight(#FIELDS * 24)
end

function GQ.Custom:ShowEditor(classFile, specId)
    classFile = classFile or (GQ.GetEffectiveClass and GQ:GetEffectiveClass())
    classFile = classFile and string.upper(classFile)
    if GQ.Log and GQ.Log.HideSpecPicker then
        GQ.Log:HideSpecPicker()
    end
    local panel = self:EnsureEditor()
    local host = (GQ.Log and GQ.Log.frame) or UIParent
    if panel:GetParent() ~= host then
        panel:SetParent(host)
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", host, "CENTER", 0, 16)
    end
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(300)
    panel.classFile = classFile
    panel.errorText:SetText("")
    panel.baseMenu:Hide()
    local record = specId and self:Get(classFile, specId)
    if record then
        panel.editingId = record.id
        panel.baseId = record.base
        panel.overrides = {}
        for key, value in pairs(record.overrides or {}) do
            panel.overrides[key] = value
        end
        panel.nameBox:SetText(record.name or "")
        panel.specButton:SetText(GQ.Spec:GetSpecLabel(record.base, classFile) or record.base)
        panel.deleteButton:Show()
        panel.title:SetText(L["Edit stat weights"])
    else
        panel.editingId = nil
        panel.baseId = nil
        panel.overrides = {}
        panel.nameBox:SetText("")
        panel.specButton:SetText(L["Select a spec"])
        panel.deleteButton:Hide()
        panel.title:SetText(L["Custom stat weights"])
    end
    self:RefreshFields()
    panel:Show()
    panel.nameBox:SetFocus()
end

function GQ.Custom:ReadOverrides()
    local panel = self._editor
    local overrides = {}
    for i = 1, #panel.rows do
        local row = panel.rows[i]
        if row:IsShown() then
            local text = Trim(row.box:GetText() or "")
            if text ~= "" then
                local value = tonumber(text)
                if not value then
                    return nil, row.field.label
                end
                overrides[row.field.key] = value
            end
        end
    end
    return overrides
end

function GQ.Custom:SaveAndScore()
    local panel = self._editor
    if not panel then
        return
    end
    panel.errorText:SetText("")
    local classFile = panel.classFile
    local name = Trim(panel.nameBox:GetText() or "")
    if name == "" then
        panel.errorText:SetText(L["Name the spec."])
        return
    end
    if #name > NAME_LIMIT then
        panel.errorText:SetText(L("The name can be %s characters.", NAME_LIMIT))
        return
    end
    if not panel.baseId then
        panel.errorText:SetText(L["Select the spec this is based on."])
        return
    end
    local existing = self:FindByName(classFile, name)
    if existing and existing ~= panel.editingId then
        panel.errorText:SetText(L["This class already has a spec with that name."])
        return
    end
    local overrides, badField = self:ReadOverrides()
    if not overrides then
        panel.errorText:SetText(L("%s needs a number, or leave it empty.", L[badField]))
        return
    end

    local store = self:Store()
    if not store then
        panel.errorText:SetText(L["The addon save is not ready yet."])
        return
    end
    store[classFile] = store[classFile] or {}
    local list = store[classFile]
    local record
    if panel.editingId then
        record = self:Get(classFile, panel.editingId)
    end
    if not record then
        record = { id = NextId(list) }
        list[#list + 1] = record
    end
    record.name = name
    record.base = panel.baseId
    record.overrides = overrides

    if GQ.Data and GQ.Data.EnsureClassLoaded and not (GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(classFile)) then
        GQ.Data:EnsureClassLoaded(classFile)
    end
    panel.saveButton:Disable()
    panel.saveButton:SetText(L["Scoring..."])
    self._built = self._built or {}
    self._built[record.id] = nil
    self._failed = self._failed or {}
    self._failed[record.id] = nil
    local specId = record.id
    self:StartBuild(classFile, specId, function(ok, err)
        if panel.saveButton then
            panel.saveButton:Enable()
            panel.saveButton:SetText(L["Save and score items!"])
        end
        if not ok then
            if panel.errorText then
                panel.errorText:SetText(L["Scoring failed."])
            end
            GQ:Chat("|cffff0000GearQuest|r: " .. L["custom spec scoring failed: "] .. tostring(err))
            return
        end
        if GQ.Spec and GQ.Spec.SetSelectedSpec then
            GQ.Spec:SetSelectedSpec(specId, classFile)
        end
        panel:Hide()
        if GQ.Log and GQ.Log.UpdateSpecButton then
            GQ.Log:UpdateSpecButton()
        end
        GQ:Chat("|cff66ccffGearQuest|r: " .. L("Saved |cff00ff00%s|r and scored its hunt list.", name))
    end, true)
end

function GQ.Custom:DeleteSpec(classFile, specId)
    classFile = classFile and string.upper(classFile)
    local record = self:Get(classFile, specId)
    if not record then
        return
    end
    local name = record.name or L["that spec"]
    local base = record.base
    self:Forget(classFile, specId)
    if self._editor and self._editor.editingId == specId then
        self._editor:Hide()
    end
    local current = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    if current == specId and base and GQ.Spec and GQ.Spec.SetSelectedSpec then
        GQ.Spec:SetSelectedSpec(base, classFile)
    elseif GQ.RefreshUI then
        GQ:RefreshUI({ reason = "spec" })
    end
    if GQ.Log and GQ.Log.UpdateSpecButton then
        GQ.Log:UpdateSpecButton()
    end
    if GQ.Log and GQ.Log.RefreshSpecPickerRows and GQ.Log.frame and GQ.Log.frame.specPicker and GQ.Log.frame.specPicker:IsShown() then
        GQ.Log:RefreshSpecPickerRows()
    end
    GQ:Chat("|cff66ccffGearQuest|r: " .. L("Removed custom spec |cff00ff00%s|r.", name))
end

function GQ.Custom:DeleteEditing()
    local panel = self._editor
    if not panel or not panel.editingId then
        return
    end
    self:DeleteSpec(panel.classFile, panel.editingId)
end
