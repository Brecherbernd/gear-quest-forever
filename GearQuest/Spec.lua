local _, GQ = ...
local L = GQ.L

GQ.Spec = GQ.Spec or {}

GQ.Spec.TALENT_LEVEL = 10

-- Talent tab index (1–3) -> spec id per class (TBC Classic order).
local SPEC_BY_TAB = {
    WARRIOR = { "arms", "fury", "protection" },
    PALADIN = { "holy", "protection", "retribution" },
    HUNTER = { "beast_mastery", "marksmanship", "survival" },
    ROGUE = { "assassination", "combat", "subtlety" },
    PRIEST = { "discipline", "holy", "shadow" },
    SHAMAN = { "elemental", "enhancement", "restoration" },
    MAGE = { "arcane", "fire", "frost" },
    WARLOCK = { "affliction", "demonology", "destruction" },
    DRUID = { "balance", "feral", "restoration" },
}

-- classFile -> spec options (id, label, icon, default for leveling BiS, comingLater)
GQ.Spec.CLASS_SPECS = {
    WARRIOR = {
        { id = "arms", label = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", default = true },
        { id = "fury", label = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { id = "protection", label = "Protection", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
    },
    PALADIN = {
        { id = "retribution", label = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", default = true },
        { id = "holy", label = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { id = "protection", label = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        { id = "shockadin", label = "Shockadin", icon = "Interface\\Icons\\Spell_Holy_HolySmite" },
    },
    HUNTER = {
        { id = "beast_mastery", label = "Beast Mastery", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", default = true },
        { id = "marksmanship", label = "Marksmanship", icon = "Interface\\Icons\\Ability_Hunter_AimedShot" },
        { id = "survival", label = "Survival", icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike" },
    },
    ROGUE = {
        { id = "combat", label = "Combat", icon = "Interface\\Icons\\Ability_BackStab", default = true },
        { id = "assassination", label = "Assassination", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        { id = "subtlety", label = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth" },
    },
    PRIEST = {
        { id = "shadow", label = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", default = true },
        { id = "discipline", label = "Discipline", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { id = "holy", label = "Holy", icon = "Interface\\Icons\\Spell_Holy_Heal" },
    },
    SHAMAN = {
        { id = "elemental", label = "Elemental", icon = "Interface\\Icons\\Spell_Nature_Lightning", default = true },
        { id = "enhancement", label = "Enhancement", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
        { id = "enhancement_tank", label = "Enhancement Tank", icon = "Interface\\Icons\\INV_Shield_06" },
        { id = "restoration", label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
    },
    MAGE = {
        { id = "frost", label = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", default = true },
        { id = "arcane", label = "Arcane", icon = "Interface\\Icons\\Spell_Holy_ArcaneIntellect" },
        { id = "fire", label = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02" },
        { id = "battlemage_frost", label = "Battle Mage (Frost)", icon = "Interface\\Icons\\INV_Sword_04" },
        { id = "battlemage_fire", label = "Battle Mage (Fire)", icon = "Interface\\Icons\\INV_Sword_11" },
        { id = "battlemage_arcane", label = "Battle Mage (Arcane)", icon = "Interface\\Icons\\INV_Sword_20" },
    },
    WARLOCK = {
        { id = "affliction", label = "Affliction", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", default = true },
        { id = "demonology", label = "Demonology", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
        { id = "destruction", label = "Destruction", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" },
    },
    DRUID = {
        { id = "feral", label = "Feral (Cat)", icon = "Interface\\Icons\\Ability_Druid_CatForm", default = true },
        { id = "bear", label = "Bear Tank", icon = "Interface\\Icons\\Ability_Druid_Maul" },
        { id = "balance", label = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall" },
        { id = "restoration", label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
    },
}

local SPEC_ALIASES = {
    -- Paladin
    ret = "retribution",
    retribution = "retribution",
    holy = "holy",
    prot = "protection",
    protection = "protection",
    shockadin = "shockadin",
    shock = "shockadin",
    -- Warrior
    arms = "arms",
    fury = "fury",
    -- Hunter
    bm = "beast_mastery",
    beast = "beast_mastery",
    beastmastery = "beast_mastery",
    beast_mastery = "beast_mastery",
    mm = "marksmanship",
    marksmanship = "marksmanship",
    marks = "marksmanship",
    survival = "survival",
    surv = "survival",
    -- Rogue
    assassination = "assassination",
    assa = "assassination",
    combat = "combat",
    subtlety = "subtlety",
    sub = "subtlety",
    -- Priest
    discipline = "discipline",
    disc = "discipline",
    shadow = "shadow",
    -- Shaman
    elemental = "elemental",
    ele = "elemental",
    enhancement = "enhancement",
    enh = "enhancement",
    enhancement_tank = "enhancement_tank",
    enhancementtank = "enhancement_tank",
    enhtank = "enhancement_tank",
    enh_tank = "enhancement_tank",
    restoration = "restoration",
    resto = "restoration",
    rest = "restoration",
    -- Mage
    arcane = "arcane",
    fire = "fire",
    frost = "frost",
    battlemage = "battlemage_frost",
    battlemage_frost = "battlemage_frost",
    battlemagefrost = "battlemage_frost",
    frostbattlemage = "battlemage_frost",
    battlemage_fire = "battlemage_fire",
    battlemagefire = "battlemage_fire",
    firebattlemage = "battlemage_fire",
    battlemage_arcane = "battlemage_arcane",
    battlemagearcane = "battlemage_arcane",
    arcanebattlemage = "battlemage_arcane",
    -- Warlock
    affliction = "affliction",
    aff = "affliction",
    demonology = "demonology",
    demo = "demonology",
    destruction = "destruction",
    destro = "destruction",
    -- Druid
    balance = "balance",
    feral = "feral",
    bear = "bear",
    tank = "protection",
}

local function NormalizeClassFile(classFile)
    if type(classFile) ~= "string" or classFile == "" then
        return nil
    end
    return classFile:upper()
end

function GQ.Spec:GetOptions(classFile)
    classFile = NormalizeClassFile(classFile)
    if not classFile then
        return nil
    end
    return self.CLASS_SPECS[classFile]
end

function GQ.Spec:HasSpecs(classFile)
    classFile = NormalizeClassFile(classFile or GQ:GetEffectiveClass())
    return classFile ~= nil and self.CLASS_SPECS[classFile] ~= nil
end

function GQ.Spec:IsActive()
    return GQ:GetEffectiveLevel() >= self.TALENT_LEVEL and self:HasSpecs()
end

function GQ.Spec:GetDefaultSpec(classFile)
    local options = self:GetOptions(classFile)
    if not options then
        return nil
    end

    for _, opt in ipairs(options) do
        if opt.default then
            return opt.id
        end
    end

    return options[1] and options[1].id
end

function GQ.Spec:GetSpecOption(specId, classFile)
    classFile = NormalizeClassFile(classFile or GQ:GetEffectiveClass())
    for _, opt in ipairs(self:GetOptions(classFile) or {}) do
        if opt.id == specId then
            return opt
        end
    end
    if GQ.Custom and GQ.Custom.Option then
        return GQ.Custom:Option(classFile, specId)
    end
end

function GQ.Spec:GetRuleSpec(specId, classFile)
    specId = specId or (GQ.GetEffectiveSpec and GQ:GetEffectiveSpec())
    if GQ.Custom and GQ.Custom.BaseOf then
        local base = GQ.Custom:BaseOf(specId, classFile)
        if base then
            return base
        end
    end
    return specId
end

function GQ.Spec:IsSpecSelectable(specId, classFile)
    local opt = self:GetSpecOption(specId, classFile)
    return opt ~= nil and not opt.comingLater
end

function GQ.Spec:GetSpecLabel(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    local options = self:GetOptions(classFile)
    if not options or not specId then
        return nil
    end

    for _, opt in ipairs(options) do
        if opt.id == specId then
            return L[opt.label]
        end
    end
    local custom = GQ.Custom and GQ.Custom.Option and GQ.Custom:Option(classFile, specId)
    return custom and custom.label
end

function GQ.Spec:GetSpecIcon(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    if not specId then
        specId = self:GetDisplaySpec(classFile)
    end
    local opt = self:GetSpecOption(specId, classFile)
    if opt and opt.icon then
        return opt.icon
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function NormalizeSavedSpecId(specId, classFile)
    if type(specId) ~= "string" or specId == "" then
        return nil
    end
    specId = GQ.Spec:ResolveSpecInput(specId, classFile) or specId
    if GQ.Spec:IsSpecSelectable(specId, classFile) then
        return specId
    end
    return nil
end

local function EnsurePreviewSpecStore()
    if GQ.EnsureSavedVariableDefaults then
        GQ:EnsureSavedVariableDefaults(true)
    end
    if type(GearQuestForeverDB) ~= "table" then
        return nil
    end
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.preview = GearQuestForeverDB.settings.preview or {}
    GearQuestForeverDB.settings.preview.specByClass = GearQuestForeverDB.settings.preview.specByClass or {}
    return GearQuestForeverDB.settings.preview.specByClass
end

local function GetSimulatedSpec(classFile)
    if not (GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()) then
        return nil
    end
    local store = EnsurePreviewSpecStore()
    if not store then
        return nil
    end
    local specId = store[classFile]
    if type(specId) ~= "string" or specId == "" then
        return nil
    end
    specId = GQ.Spec:ResolveSpecInput(specId, classFile) or specId
    if GQ.Spec:IsSpecSelectable(specId, classFile) then
        return specId
    end
    return nil
end

local function EnsureCharSpecStore()
    if type(GearQuestForeverCharDB) ~= "table" then
        GearQuestForeverCharDB = {}
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
    GearQuestForeverCharDB.specPick = GearQuestForeverCharDB.specPick or {}
    return GearQuestForeverCharDB.specPick
end

local function GetSavedSpecPick(classFile)
    if type(GearQuestForeverCharDB) ~= "table" or type(GearQuestForeverCharDB.specPick) ~= "table" then
        return nil
    end
    return NormalizeSavedSpecId(GearQuestForeverCharDB.specPick[classFile], classFile)
end

local function StoreSpecPick(classFile, specId)
    local store = EnsureCharSpecStore()
    store[classFile] = specId
end

function GQ.Spec:GetDisplaySpec(classFile)
    classFile = NormalizeClassFile(classFile or GQ:GetEffectiveClass())
    if not classFile or not self:HasSpecs(classFile) then
        local _, playerClass = UnitClass("player")
        classFile = NormalizeClassFile(playerClass)
        if not classFile or not self:HasSpecs(classFile) then
            return nil
        end
    end

    local previewMode = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    if previewMode then
        local saved = GetSimulatedSpec(classFile)
        if saved then
            return saved
        end
        return self:GetDefaultSpec(classFile)
    end

    -- Manual pick sticks across login until they choose a different spec.
    local picked = GetSavedSpecPick(classFile)
    if picked then
        return picked
    end

    local fromTalents = self:DetectSpecFromTalents(classFile)
    if fromTalents and self:IsSpecSelectable(fromTalents, classFile) then
        return fromTalents
    end

    return self:GetDefaultSpec(classFile)
end

function GQ.Spec:GetSavedSpec(classFile)
    return GetSimulatedSpec(classFile)
end

function GQ.Spec:ResolveSpecInput(specId, classFile)
    specId = strtrim((specId or ""):lower())
    if specId == "" then
        return nil
    end

    specId = SPEC_ALIASES[specId] or specId

    local options = self:GetOptions(classFile) or {}
    for _, opt in ipairs(options) do
        if opt.id == specId or opt.label:lower() == specId then
            return opt.id
        end
    end

    if GQ.Custom and GQ.Custom.FindByName then
        local customId = GQ.Custom:FindByName(classFile, specId)
        if customId then
            return customId
        end
    end

    local compact = specId:gsub("[%s_%-]", "")
    for _, opt in ipairs(options) do
        local optCompact = opt.id:gsub("_", "")
        local labelCompact = opt.label:lower():gsub("[%s_%-]", "")
        if optCompact == compact or labelCompact == compact then
            return opt.id
        end
    end

    return specId
end

function GQ.Spec:SetSelectedSpec(specId, classFile)
    classFile = NormalizeClassFile(classFile or GQ:GetEffectiveClass())
    if not classFile then
        return false, L["Could not determine your class."]
    end
    local options = self:GetOptions(classFile)
    if not options then
        return false, L["This class has no specialization options in GearQuest yet."]
    end

    specId = self:ResolveSpecInput(specId, classFile)
    local matched
    for _, opt in ipairs(options) do
        if opt.id == specId then
            matched = opt
            break
        end
    end

    if not matched and GQ.Custom and GQ.Custom.Option then
        matched = GQ.Custom:Option(classFile, specId)
    end

    if not matched then
        local names = {}
        for _, opt in ipairs(options) do
            if self:IsSpecSelectable(opt.id, classFile) then
                table.insert(names, opt.id)
            end
        end
        return false, L["Unknown spec. Use: "] .. table.concat(names, ", ")
    end

    if not self:IsSpecSelectable(matched.id, classFile) then
        return false, L("%s is coming later.", L[matched.label])
    end

    if matched.custom and GQ.Custom and GQ.Custom.EnsureBuilt then
        GQ.Custom:EnsureBuilt(classFile, matched.id)
    end

    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        local store = EnsurePreviewSpecStore()
        if store then
            store[classFile] = matched.id
        end
    else
        StoreSpecPick(classFile, matched.id)
    end

    if GQ.Data and GQ.Data.InvalidateSpecCache then
        GQ.Data:InvalidateSpecCache()
    end

    if GQ.RefreshUI then
        GQ:RefreshUI({ reason = "spec" })
    end

    if self._talentFrame then
        self._talentFrame._lastSpec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or matched.id
    end

    return true
end

local function SumRanksInTalentTab(tab)
    if not GetNumTalents or not GetTalentInfo then
        return nil
    end
    local talentGroup = (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    local count = GetNumTalents(tab, talentGroup) or GetNumTalents(tab)
    if not count or count <= 0 then
        return nil
    end

    local total = 0
    for index = 1, count do
        local ok, a, b, c, d, e, f, g, h = pcall(GetTalentInfo, tab, index, talentGroup)
        if not ok then
            ok, a, b, c, d, e, f, g, h = pcall(GetTalentInfo, tab, index)
        end
        if ok then
            local rank = tonumber(e) or tonumber(d) or tonumber(c) or tonumber(a)
            if rank and rank >= 0 and rank <= 10 then
                total = total + rank
            end
        end
    end
    if total > 0 then
        return total
    end
    return nil
end

local function GetTalentTabPoints(tab)
    if GetTalentTabInfo then
        local talentGroup = (GetActiveTalentGroup and GetActiveTalentGroup()) or nil
        local ok, a, b, c, d, e, f, g, h = pcall(GetTalentTabInfo, tab, talentGroup)
        if not ok then
            ok, a, b, c, d, e, f, g, h = pcall(GetTalentTabInfo, tab)
        end
        if ok then
            local candidates = { c, e, f, d, g, b, h, a }
            for i = 1, #candidates do
                local pts = tonumber(candidates[i])
                if pts and pts >= 1 and pts <= 51 then
                    return pts
                end
            end
        end
    end

    local summed = SumRanksInTalentTab(tab)
    if summed then
        return summed
    end

    return 0
end

function GQ.Spec:DetectSpecFromTalents(classFile)
    classFile = NormalizeClassFile(classFile)
    local byTab = SPEC_BY_TAB[classFile]
    if not byTab then
        return nil
    end

    if GetPrimaryTalentTree then
        local group = (GetActiveTalentGroup and GetActiveTalentGroup()) or nil
        local primary = group and GetPrimaryTalentTree(group) or GetPrimaryTalentTree()
        primary = tonumber(primary)
        if primary then
            if byTab[primary] then
                return byTab[primary]
            end
            if byTab[primary + 1] then
                return byTab[primary + 1]
            end
        end
    end

    local tabCount = #byTab
    if GetNumTalentTabs then
        tabCount = math.max(tabCount, GetNumTalentTabs() or 0)
    end

    local bestTab, bestPoints = nil, 0
    for tab = 1, tabCount do
        local points = GetTalentTabPoints(tab)
        if points > bestPoints and byTab[tab] then
            bestPoints = points
            bestTab = tab
        end
    end

    if bestTab and bestPoints > 0 then
        return byTab[bestTab]
    end

    return nil
end

function GQ.Spec:EnsureTalentRefresh()
    if self._talentFrame then
        return
    end
    local frame = CreateFrame("Frame")
    local function currentSpec()
        return GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or nil
    end
    frame._lastSpec = currentSpec()
    local function applyTalentChange()
        -- Every ding from 10 gives a talent point and fires this. With no spec
        -- change, wiping the cache would throw away the level-up rebuild.
        local spec = currentSpec()
        if spec == frame._lastSpec then
            if GQ.Log and GQ.Log.UpdateSpecButton then
                GQ.Log:UpdateSpecButton()
            end
            return
        end
        frame._lastSpec = spec
        if GQ.Data and GQ.Data.InvalidateSpecCache then
            GQ.Data:InvalidateSpecCache()
        end
        if GQ.Log and GQ.Log.UpdateSpecButton then
            GQ.Log:UpdateSpecButton()
        end
        if GQ.RefreshUI then
            GQ:RefreshUI({ reason = "spec" })
        end
    end
    local function onTalentChange()
        -- A ding fires this even when no talent changed. applyTalentChange
        -- leaves the lists alone unless the spec actually changed.
        applyTalentChange()
    end
    GQ.RegisterEvent(frame, "PLAYER_TALENT_UPDATE")
    GQ.RegisterEvent(frame, "CHARACTER_POINTS_CHANGED")
    frame:SetScript("OnEvent", onTalentChange)
    self._talentFrame = frame
end

function GQ.Spec:OnPlayerLogin()
    self:EnsureTalentRefresh()
    local function refreshSpecUi()
        if GQ.Log and GQ.Log.UpdateSpecButton then
            GQ.Log:UpdateSpecButton()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, refreshSpecUi)
        C_Timer.After(1, refreshSpecUi)
    else
        refreshSpecUi()
    end
end

function GQ.Spec:GetEffectiveSpec()
    return self:GetDisplaySpec()
end

function GQ.Spec:GetSelectedSpecLabel()
    local classFile = NormalizeClassFile(GQ:GetEffectiveClass())
    local specId = self:GetDisplaySpec(classFile) or self:GetEffectiveSpec()
    return self:GetSpecLabel(specId, classFile) or "Specialization"
end

function GQ.Spec:PrintSpecDebug()
    local classFile = NormalizeClassFile(GQ:GetEffectiveClass())
    if not classFile then
        GQ:Chat("|cff66ccffGearQuest|r: " .. L["Could not read your class."])
        return
    end

    local display = self:GetDisplaySpec(classFile)
    local talents = self:DetectSpecFromTalents(classFile)
    local default = self:GetDefaultSpec(classFile)
    local previewOn = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    local picked = GetSavedSpecPick(classFile)

    GQ:Chat("|cff66ccffGearQuest|r spec debug (" .. classFile .. "):")
    GQ:Chat("  simulation: " .. (previewOn and "on" or "off"))
    GQ:Chat("  sim spec: " .. tostring(GetSimulatedSpec(classFile)))
    GQ:Chat("  saved picker: " .. tostring(picked))
    GQ:Chat("  talent-tree guess: " .. tostring(talents))
    GQ:Chat("  using for hunts: " .. tostring(display))
    if picked and display == picked then
        GQ:Chat("  source: saved spec picker")
    elseif display == talents and talents then
        GQ:Chat("  source: talent tree (most points)")
    elseif previewOn and GetSimulatedSpec(classFile) then
        GQ:Chat("  source: simulation picker")
    else
        GQ:Chat("  class default (fallback): " .. tostring(default))
    end
end
