local _, GQ = ...
local L = GQ.L

GQ.Preview = GQ.Preview or {}

local CLASS_ALIASES = {
    warrior = "WARRIOR",
    paladin = "PALADIN",
    hunter = "HUNTER",
    rogue = "ROGUE",
    priest = "PRIEST",
    shaman = "SHAMAN",
    mage = "MAGE",
    warlock = "WARLOCK",
    druid = "DRUID",
}

local FACTION_ALIASES = {
    alliance = "Alliance",
    horde = "Horde",
}

local function NormalizeClass(input)
    if not input or input == "" then
        return nil
    end
    input = strtrim(input):lower()
    if CLASS_ALIASES[input] then
        return CLASS_ALIASES[input]
    end
    local upper = strtrim(input):upper()
    for _, classFile in pairs(CLASS_ALIASES) do
        if classFile == upper then
            return classFile
        end
    end
end

local function NormalizeFaction(input)
    if not input or input == "" then
        return nil
    end
    input = strtrim(input):lower()
    if FACTION_ALIASES[input] then
        return FACTION_ALIASES[input]
    end
    if input == "alliance" or input == "horde" then
        return FACTION_ALIASES[input]
    end
    local title = strtrim(input):sub(1, 1):upper() .. strtrim(input):sub(2):lower()
    if title == "Alliance" or title == "Horde" then
        return title
    end
end

function GQ.Preview:MigrateSettings()
    if GQ.BindSavedVariableGlobals then
        GQ:BindSavedVariableGlobals()
    end
    if type(GearQuestForeverDB) ~= "table" then
        return
    end
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    local settings = GearQuestForeverDB.settings

    if settings.debugAsHunter37 ~= nil then
        settings.preview = settings.preview or {}
        if settings.preview.enabled == nil then
            settings.preview.enabled = settings.debugAsHunter37
        end
        settings.debugAsHunter37 = nil
    end
end

function GQ.Preview:GetSettings()
    if GQ.BindSavedVariableGlobals then
        GQ:BindSavedVariableGlobals()
    end
    if GQ.EnsureSavedVariableDefaults then
        GQ:EnsureSavedVariableDefaults(true)
    end
    self:MigrateSettings()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.preview = GearQuestForeverDB.settings.preview or {}

    local preview = GearQuestForeverDB.settings.preview
    if preview.enabled == nil then
        preview.enabled = false
    end
    if not preview.class then
        preview.class = "PALADIN"
    end
    if not preview.level then
        preview.level = 4
    end
    preview.level = GQ:ClampPlayerLevel(preview.level)
    if not preview.faction then
        local faction = UnitFactionGroup("player")
        preview.faction = faction or "Alliance"
    end

    return preview
end

function GQ.Preview:IsEnabled()
    return self:GetSettings().enabled
end

function GQ.Preview:SetEnabled(enabled)
    self:GetSettings().enabled = enabled
    if not enabled and GQ.Data and GQ.Data.ReleaseIdleHuntClasses then
        if GQ.Data:ReleaseIdleHuntClasses() and GQ.Data.BuildIndex then
            GQ.Data:BuildIndex()
            if GQ.Data.InvalidateClassCache then
                GQ.Data:InvalidateClassCache()
            end
        end
    end
    -- Same class at another level still has its hunt data loaded, so the
    -- filtered list has to drop here too. Otherwise a profession filter
    -- keeps the simulated rows after Reset.
    if not enabled and GQ.Log and GQ.Log.InvalidateActiveListCaches then
        GQ.Log:InvalidateActiveListCaches()
    end
    -- The character's own spec was not scored while a simulated class was
    -- on screen. A custom spec on this character has to be scored now.
    if not enabled and GQ.Custom and GQ.Custom.EnsureBuilt and GQ.GetEffectiveClass and GQ.GetEffectiveSpec then
        local classFile = GQ:GetEffectiveClass()
        local specId = GQ:GetEffectiveSpec()
        if classFile and specId then
            GQ.Custom:EnsureBuilt(classFile, specId)
        end
    end
end

function GQ.Preview:SetClass(classFile)
    local normalized = NormalizeClass(classFile)
    if not normalized then
        return false, L["Unknown class. Use: warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid."]
    end
    local wasExpanded = GQ.Data and GQ.Data.IsClassExpanded and GQ.Data:IsClassExpanded(normalized)
    self:GetSettings().class = normalized
    self:SetEnabled(true)
    if GQ.Data and GQ.Data.EnsureClassLoaded then
        local loaded = GQ.Data:EnsureClassLoaded(normalized)
        local removed = GQ.Data.ReleaseIdleHuntClasses and GQ.Data:ReleaseIdleHuntClasses()
        if loaded and ((not wasExpanded) or removed) and GQ.Data.BuildIndex then
            GQ.Data:BuildIndex()
            if collectgarbage then
                collectgarbage("collect")
            end
        end
        if GQ.Custom and GQ.Custom.EnsureBuilt and GQ.GetEffectiveSpec then
            local specId = GQ:GetEffectiveSpec()
            if specId then
                GQ.Custom:EnsureBuilt(normalized, specId)
            end
        end
    end
    if GQ.Data and GQ.Data.InvalidateClassCache then
        GQ.Data:InvalidateClassCache()
    end
    if GQ.Log and GQ.Log.InvalidateActiveListCaches then
        GQ.Log:InvalidateActiveListCaches()
    end
    return true
end

function GQ.Preview:SetLevel(level)
    local previousLevel = self:GetSettings().level
    level = tonumber(level)
    local maxLevel = GQ.MAX_PLAYER_LEVEL or 60
    if not level or level < 1 or level > maxLevel then
        return false, string.format(L["Level must be a number between 1 and %d."], maxLevel)
    end
    level = GQ:ClampPlayerLevel(level)
    self:GetSettings().level = level
    self:SetEnabled(true)
    if GQ.Data and GQ.Data.InvalidatePlayerBandCache then
        GQ.Data:InvalidatePlayerBandCache()
    end
    if GQ.Log and GQ.Log.InvalidateActiveListCaches then
        GQ.Log:InvalidateActiveListCaches()
    end
    if GQ.CheckLevelMilestones then
        GQ:CheckLevelMilestones(previousLevel, level)
    end
    -- Preview jumps (simulator, /gq level) do not fire PLAYER_LEVEL_UP; still
    -- need obtain checks when a new level band unlocks hunts you already have.
    if self:IsEnabled() and GQ.Log and GQ.Log.ScheduleAutoCompletionCheck then
        -- A sim jump can skip bands. Record gear already owned in those bands
        -- with no toast. Live loot does not use this path.
        GQ.Log:ScheduleAutoCompletionCheck(true)
    end
    return true
end

function GQ.Preview:SetFaction(faction)
    local normalized = NormalizeFaction(faction)
    if not normalized then
        return false, L["Unknown faction. Use: alliance or horde."]
    end
    self:GetSettings().faction = normalized
    self:SetEnabled(true)
    if GQ.Data and GQ.Data.InvalidatePlayerBandCache then
        GQ.Data:InvalidatePlayerBandCache()
    end
    if GQ.Log and GQ.Log.InvalidateActiveListCaches then
        GQ.Log:InvalidateActiveListCaches()
    end
    return true
end

function GQ.Preview:ApplyCurrentCharacter()
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")
    local faction = UnitFactionGroup("player") or "Alliance"
    local preview = self:GetSettings()
    preview.enabled = true
    preview.class = classFile
    preview.level = GQ:ClampPlayerLevel(level)
    preview.faction = faction
end

function GQ.Preview:GetLoginCharacterKey()
    if UnitGUID then
        local guid = UnitGUID("player")
        if guid then
            return guid
        end
    end
    return (UnitName("player") or "") .. "-" .. (GetRealmName() or "")
end

-- New character login: drop simulation from a previous toon; keep it on /reload.
function GQ.Preview:OnPlayerLogin()
    local settings = self:GetSettings()
    local key = self:GetLoginCharacterKey()
    if settings.loginCharacterKey == key then
        return false
    end

    settings.loginCharacterKey = key
    self:SetEnabled(false)

    local _, classFile = UnitClass("player")
    settings.class = classFile
    settings.level = GQ:ClampPlayerLevel(UnitLevel("player"))
    settings.faction = UnitFactionGroup("player") or "Alliance"
    return true
end

function GQ.Preview:GetEffectiveClass()
    if self:IsEnabled() then
        return self:GetSettings().class
    end
    local _, classFile = UnitClass("player")
    return classFile
end

function GQ.Preview:GetEffectiveLevel()
    if self:IsEnabled() then
        return self:GetSettings().level
    end
    return UnitLevel("player")
end

function GQ.Preview:GetEffectiveFaction()
    if self:IsEnabled() then
        return self:GetSettings().faction
    end
    return UnitFactionGroup("player") or "Alliance"
end

function GQ.Preview:GetEffectiveSpec()
    if GQ.Spec and GQ.Spec.GetEffectiveSpec then
        return GQ.Spec:GetEffectiveSpec()
    end
    return nil
end

function GQ.Preview:GetLabel()
    if not self:IsEnabled() then
        return L["using your character"]
    end
    local preview = self:GetSettings()
    return string.format(
        L["preview: lvl %d %s (%s)"],
        preview.level,
        self:FormatClassName(preview.class),
        preview.faction
    )
end

function GQ.Preview:FormatClassName(classFile)
    local localized = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]
    if localized then
        return localized
    end
    return classFile:sub(1, 1) .. classFile:sub(2):lower()
end


function GQ.Preview:PrintNowViewing()
    if not self:IsEnabled() then
        local _, classFile = UnitClass("player")
        local specSuffix = ""
        if GQ.Spec and GQ.Spec.IsActive and GQ.Spec:IsActive() then
            specSuffix = string.format(", %s", GQ.Spec:GetSelectedSpecLabel())
        end
        GQ:Chat(string.format(
            L["|cff66ccffGearQuest|r: Now viewing upgrades as |cff00ff00your character|r — level %d %s (%s%s)."],
            UnitLevel("player"),
            self:FormatClassName(classFile),
            UnitFactionGroup("player") or "?",
            specSuffix
        ))
        return
    end

    local preview = self:GetSettings()
    local specSuffix = ""
    if GQ.Spec and GQ.Spec.IsActive and GQ.Spec:IsActive() then
        specSuffix = string.format(", %s", GQ.Spec:GetSelectedSpecLabel())
    end
    GQ:Chat(string.format(
        L["|cff66ccffGearQuest|r: Now viewing upgrades as a |cff00ff00level %d %s|r (%s%s). Right-click a gear slot on your character panel, or |cff00ff00/gq|r."],
        preview.level,
        self:FormatClassName(preview.class),
        preview.faction,
        specSuffix
    ))
end

function GQ.Preview:PrintHelp()
    GQ:Chat(L["|cff66ccffGearQuest|r commands:"])
    GQ:Chat(L["  |cff00ff00/gq set|r — show preview settings"])
    GQ:Chat(L["  |cff00ff00/gq class hunter|r — set preview class"])
    GQ:Chat(L["  |cff00ff00/gq level 37|r — set preview level"])
    GQ:Chat(L["  |cff00ff00/gq faction alliance|r — set preview faction"])
    GQ:Chat(L["  |cff00ff00/gq set on|r / |cff00ff00/gq set off|r — enable or disable preview"])
    GQ:Chat(L["  |cff00ff00/gq set me|r — copy your real character into preview"])
    GQ:Chat(L["  |cff00ff00/gq spec enhancement|r — set specialization (level 10+)"])
    GQ:Chat(L["  |cff00ff00/gq log|r — toggle GearQuest log window"])
    GQ:Chat(L["  |cff00ff00/gq wipe data|r — reset hunt progress (for testing obtain/toast)"])
end

function GQ.Preview:PrintStatus()
    local preview = self:GetSettings()
    if preview.enabled then
        GQ:Chat(string.format(
            L["|cff66ccffGearQuest|r preview |cff00ff00on|r — level %d, %s, %s."],
            preview.level,
            preview.class,
            preview.faction
        ))
    else
        local _, classFile = UnitClass("player")
        GQ:Chat(string.format(
            L["|cff66ccffGearQuest|r preview |cff888888off|r — using your character (lvl %d %s, %s)."],
            UnitLevel("player"),
            classFile,
            UnitFactionGroup("player") or "?"
        ))
    end
    self:PrintHelp()
end

function GQ.Preview:HandleCommand(msg)
    msg = strtrim(msg:lower())

    if msg == "debug" then
        self:SetEnabled(not self:IsEnabled())
        self:PrintNowViewing()
        return
    end

    if msg == "set" then
        self:PrintStatus()
        self:PrintNowViewing()
        return
    end

    if msg == "status" or msg == "preview" then
        self:PrintStatus()
        self:PrintNowViewing()
        return
    end

    if msg == "me" then
        self:ApplyCurrentCharacter()
        self:PrintNowViewing()
        return
    end

    local rest = msg:match("^set%s+(.*)$") or msg
    rest = strtrim(rest)

    if rest == "" or rest == "show" or rest == "status" then
        self:PrintStatus()
        self:PrintNowViewing()
        return
    end

    if rest == "on" then
        self:SetEnabled(true)
        self:PrintNowViewing()
        return
    end

    if rest == "off" then
        self:SetEnabled(false)
        self:PrintNowViewing()
        return
    end

    if rest == "me" or rest == "char" or rest == "character" then
        self:ApplyCurrentCharacter()
        self:PrintNowViewing()
        return
    end

    local key, value = rest:match("^(%S+)%s+(.+)$")
    if not key then
        self:PrintStatus()
        return
    end

    key = key:lower()
    value = strtrim(value)

    if key == "class" then
        local ok, err = self:SetClass(value)
        if ok then
            self:PrintNowViewing()
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. err)
        end
        return
    end

    if key == "level" or key == "lvl" then
        local ok, err = self:SetLevel(value)
        if ok then
            self:PrintNowViewing()
            if GQ.RefreshUI then
                GQ:RefreshUI()
            end
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. err)
        end
        return
    end

    if key == "faction" then
        local ok, err = self:SetFaction(value)
        if ok then
            self:PrintNowViewing()
            if GQ.RefreshUI then
                GQ:RefreshUI()
            end
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. err)
        end
        return
    end

    if key == "spec" or key == "specialization" or key == "talent" then
        if (value == "status" or value == "debug") and GQ.Spec and GQ.Spec.PrintSpecDebug then
            GQ.Spec:PrintSpecDebug()
            return
        end
        if GQ.Spec and GQ.Spec.SetSelectedSpec then
            local ok, err = GQ.Spec:SetSelectedSpec(value)
            if ok then
                GQ:Chat(string.format(
                    L["|cff66ccffGearQuest|r: Now viewing |cff00ff00%s|r upgrades."],
                    GQ.Spec:GetSelectedSpecLabel()
                ))
            else
                GQ:Chat("|cff66ccffGearQuest|r: " .. (err or L["Could not set specialization."]))
            end
        end
        return
    end

    self:PrintStatus()
end

-- --- Simulate dialog (minimap right-click) ---

local SIM_DIALOG_WIDTH = 280
local SIM_DIALOG_HEIGHT = 268
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"

local CLASS_ORDER = {
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "DRUID",
}

GQ.Preview.CLASS_ORDER = CLASS_ORDER

local function ApplySimDialogChrome(frame)
    if not frame.blackBg then
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        bg:SetColorTexture(0.02, 0.02, 0.02, 1)
        frame.blackBg = bg
    end

    if frame.SetBackdrop then
        frame:SetBackdrop({
            edgeFile = METAL_EDGE,
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
    end
end

local function SanitizeLevelInput(edit)
    if not edit then
        return ""
    end

    local text = edit:GetText() or ""
    text = text:gsub("%D", "")
    if text == "" then
        if text ~= edit:GetText() then
            edit:SetText("")
        end
        return ""
    end

    local level = tonumber(text)
    local maxLevel = tostring(GQ.MAX_PLAYER_LEVEL or 60)
    if level and level > tonumber(maxLevel) then
        text = maxLevel
    end

    if text ~= edit:GetText() then
        edit:SetText(text)
        edit:SetCursorPosition(#text)
    end

    return text
end

function GQ.Preview:SanitizeLevelEdit(edit)
    return SanitizeLevelInput(edit)
end

local function GetDialogSpecOptions(classFile)
    if not GQ.Spec then
        return {}
    end

    local options = GQ.Spec:GetOptions(classFile) or {}
    local selectable = {}
    for _, opt in ipairs(options) do
        if GQ.Spec:IsSpecSelectable(opt.id, classFile) then
            table.insert(selectable, opt)
        end
    end
    return selectable
end

local function PickDialogSpec(classFile)
    if not GQ.Spec or not GQ.Spec:HasSpecs(classFile) then
        return nil
    end

    local saved = GQ.Spec:GetSavedSpec(classFile)
    if saved and GQ.Spec:IsSpecSelectable(saved, classFile) then
        return saved
    end

    return GQ.Spec:GetDefaultSpec(classFile)
end

function GQ.Preview:RefreshDialogSpecDropdown()
    local dialog = self.dialog
    if not dialog or not dialog.specDrop then
        return
    end

    local classFile = dialog.selectedClass
    local options = GetDialogSpecOptions(classFile)

    if #options == 0 then
        dialog.specLabel:Hide()
        dialog.specDrop:Hide()
        dialog.selectedSpec = nil
        UIDropDownMenu_SetText(dialog.specDrop, "—")
        return
    end

    local valid = false
    for _, opt in ipairs(options) do
        if opt.id == dialog.selectedSpec then
            valid = true
            break
        end
    end
    if not valid then
        dialog.selectedSpec = PickDialogSpec(classFile)
    end

    dialog.specLabel:Show()
    dialog.specDrop:Show()

    local label = L["Specialization"]
    for _, opt in ipairs(options) do
        if opt.id == dialog.selectedSpec then
            label = opt.label
            break
        end
    end

    UIDropDownMenu_SetSelectedValue(dialog.specDrop, dialog.selectedSpec)
    UIDropDownMenu_SetText(dialog.specDrop, label)
    UIDropDownMenu_Initialize(dialog.specDrop, function(_, level)
        if level ~= 1 then
            return
        end

        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.label
            info.value = opt.id
            info.func = function()
                dialog.selectedSpec = opt.id
                UIDropDownMenu_SetSelectedValue(dialog.specDrop, opt.id)
                UIDropDownMenu_SetText(dialog.specDrop, opt.label)
            end
            info.checked = (dialog.selectedSpec == opt.id)
            UIDropDownMenu_AddButton(info)
        end
    end)
end

function GQ.Preview:ApplySimulation(classFile, level, specId, faction)
    local okClass, errClass = self:SetClass(classFile)
    if not okClass then
        return false, errClass
    end

    local okLevel, errLevel = self:SetLevel(level)
    if not okLevel then
        return false, errLevel
    end

    if faction then
        local okFaction, errFaction = self:SetFaction(faction)
        if not okFaction then
            return false, errFaction
        end
    end

    if specId and GQ.Spec then
        local okSpec, errSpec = GQ.Spec:SetSelectedSpec(specId, classFile)
        if not okSpec then
            return false, errSpec
        end
    end

    self:PrintNowViewing()
    if GQ.RefreshUI then
        GQ:RefreshUI()
    end
    return true
end

function GQ.Preview:EnsureDialog()
    if self.dialog then
        ApplySimDialogChrome(self.dialog)
        self.dialog:EnableMouse(true)
        return self.dialog
    end

    local dialog
    local ok, framed = pcall(CreateFrame, "Frame", "GearQuestSimulateDialog", UIParent, "BackdropTemplate")
    if ok and framed then
        dialog = framed
    else
        dialog = CreateFrame("Frame", "GearQuestSimulateDialog", UIParent)
    end

    dialog:SetSize(SIM_DIALOG_WIDTH, SIM_DIALOG_HEIGHT)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:EnableMouse(true)
    dialog:Hide()
    ApplySimDialogChrome(dialog)

    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.title:SetPoint("TOP", dialog, "TOP", 0, -14)
    dialog.title:SetWidth(SIM_DIALOG_WIDTH - 48)
    dialog.title:SetText(L["Want to see BiS for another level or class?"])

    dialog.closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    dialog.closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -4, -4)
    dialog.closeBtn:SetScript("OnClick", function()
        GQ.Preview:HideDialog()
    end)

    dialog.classLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.classLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -44)
    dialog.classLabel:SetText(L["Class"])

    dialog.classDrop = CreateFrame("Frame", "GearQuestSimulateClassDropDown", dialog, "UIDropDownMenuTemplate")
    dialog.classDrop:SetPoint("TOPLEFT", dialog.classLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dialog.classDrop, 180)

    dialog.specLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.specLabel:SetPoint("TOPLEFT", dialog.classDrop, "BOTTOMLEFT", 16, -8)
    dialog.specLabel:SetText(L["Specialization"])

    dialog.specDrop = CreateFrame("Frame", "GearQuestSimulateSpecDropDown", dialog, "UIDropDownMenuTemplate")
    dialog.specDrop:SetPoint("TOPLEFT", dialog.specLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dialog.specDrop, 180)

    dialog.levelLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.levelLabel:SetPoint("TOPLEFT", dialog.specDrop, "BOTTOMLEFT", 16, -8)
    dialog.levelLabel:SetText(L["Level"])

    dialog.levelEdit = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.levelEdit:SetSize(64, 20)
    dialog.levelEdit:SetPoint("LEFT", dialog.levelLabel, "RIGHT", 12, 0)
    dialog.levelEdit:SetAutoFocus(false)
    dialog.levelEdit:SetMaxLetters(2)
    dialog.levelEdit:SetScript("OnTextChanged", function(self)
        SanitizeLevelInput(self)
    end)
    dialog.levelEdit:SetScript("OnEnterPressed", function()
        dialog.submit:Click()
    end)
    dialog.levelEdit:SetScript("OnEscapePressed", function()
        GQ.Preview:HideDialog()
    end)

    dialog.factionLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.factionLabel:SetPoint("TOPLEFT", dialog.specDrop, "BOTTOMLEFT", 16, -36)
    dialog.factionLabel:SetText(L["Faction"])

    dialog.factionDrop = CreateFrame("Frame", "GearQuestSimulateFactionDropDown", dialog, "UIDropDownMenuTemplate")
    dialog.factionDrop:SetPoint("TOPLEFT", dialog.factionLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dialog.factionDrop, 180)
    dialog.selectedFaction = self:GetEffectiveFaction() or "Alliance"
    UIDropDownMenu_Initialize(dialog.factionDrop, function(_, level)
        if level ~= 1 then
            return
        end
        for _, faction in ipairs({ "Alliance", "Horde" }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = faction
            info.value = faction
            info.func = function()
                dialog.selectedFaction = faction
                UIDropDownMenu_SetSelectedValue(dialog.factionDrop, faction)
                UIDropDownMenu_SetText(dialog.factionDrop, faction)
            end
            info.checked = (dialog.selectedFaction == faction)
            UIDropDownMenu_AddButton(info)
        end
    end)

    dialog.submit = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.submit:SetSize(96, 22)
    dialog.submit:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 18)
    dialog.submit:SetText(L["Simulate"])
    dialog.submit:SetScript("OnClick", function()
        local classFile = dialog.selectedClass
        if not classFile then
            GQ:Chat(L["|cff66ccffGearQuest|r: Choose a class."])
            return
        end

        local levelText = SanitizeLevelInput(dialog.levelEdit)
        if levelText == "" then
            GQ:Chat(string.format(L["|cff66ccffGearQuest|r: Enter a level between 1 and %d."], GQ.MAX_PLAYER_LEVEL or 60))
            return
        end

        local ok, err = GQ.Preview:ApplySimulation(classFile, levelText, dialog.selectedSpec, dialog.selectedFaction)
        if ok then
            GQ.Preview:HideDialog()
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. (err or L["Could not simulate."]))
        end
    end)

    dialog.reset = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.reset:SetSize(80, 22)
    dialog.reset:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 18)
    dialog.reset:SetText(L["Reset"])
    dialog.reset:SetScript("OnClick", function()
        GQ.Preview:ApplyCurrentCharacter()
        GQ.Preview:PrintNowViewing()
        if GQ.RefreshUI then
            GQ:RefreshUI()
        end
        GQ.Preview:RefreshDialogFields()
    end)

    dialog:SetScript("OnShow", function()
        GQ.Preview:RefreshDialogFields()
    end)

    dialog.selectedClass = "PALADIN"
    dialog.selectedSpec = nil
    UIDropDownMenu_Initialize(dialog.classDrop, function(_, level)
        if level ~= 1 then
            return
        end

        for _, classFile in ipairs(CLASS_ORDER) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = GQ.Preview:FormatClassName(classFile)
            info.value = classFile
            info.func = function()
                dialog.selectedClass = classFile
                UIDropDownMenu_SetSelectedValue(dialog.classDrop, classFile)
                UIDropDownMenu_SetText(dialog.classDrop, GQ.Preview:FormatClassName(classFile))
                GQ.Preview:RefreshDialogSpecDropdown()
            end
            info.checked = (dialog.selectedClass == classFile)
            UIDropDownMenu_AddButton(info)
        end
    end)

    self.dialog = dialog
    return dialog
end

function GQ.Preview:RefreshDialogFields()
    local dialog = self:EnsureDialog()
    local classFile = self:GetEffectiveClass()
    local level = self:GetEffectiveLevel()

    dialog.selectedClass = classFile
    UIDropDownMenu_SetSelectedValue(dialog.classDrop, classFile)
    UIDropDownMenu_SetText(dialog.classDrop, self:FormatClassName(classFile))

    if GQ.Spec and level >= GQ.Spec.TALENT_LEVEL then
        local spec = GQ.Spec:GetEffectiveSpec()
        if spec and GQ.Spec:IsSpecSelectable(spec, classFile) then
            dialog.selectedSpec = spec
        else
            dialog.selectedSpec = PickDialogSpec(classFile)
        end
    else
        dialog.selectedSpec = PickDialogSpec(classFile)
    end

    self:RefreshDialogSpecDropdown()
    dialog.levelEdit:SetText(tostring(level))

    dialog.selectedFaction = self:GetEffectiveFaction() or "Alliance"
    if dialog.factionDrop then
        UIDropDownMenu_SetSelectedValue(dialog.factionDrop, dialog.selectedFaction)
        UIDropDownMenu_SetText(dialog.factionDrop, dialog.selectedFaction)
    end
end

function GQ.Preview:HideDialog()
    if self.dialog then
        self.dialog:Hide()
    end
end

function GQ.Preview:ShowDialog(anchor)
    if GQ.Log then
        if not GQ.Log.frame then
            GQ.Log:Init()
        end
        GQ.Log:SetPageTab("simulator")
        GQ.Log:Show()
        return
    end

    local dialog = self:EnsureDialog()

    self:RefreshDialogFields()
    dialog:ClearAllPoints()
    if anchor then
        dialog:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    else
        dialog:SetPoint("CENTER")
    end

    local anchorLevel = anchor and anchor:GetFrameLevel() or 1
    dialog:SetFrameLevel(anchorLevel + 20)
    dialog:Show()
end

function GQ.Preview:ToggleDialog(anchor)
    self:ShowDialog(anchor)
end

-- Backwards-compatible helpers used elsewhere in the addon.
-- Inside GQ:WithContextSnapshot (a list build) each answer is read once.
function GQ:IsPreviewEnabled()
    local ctx = self._ctx
    local value = ctx and ctx.preview
    if value == nil then
        value = self.Preview:IsEnabled()
        if ctx then
            ctx.preview = value
        end
    end
    return value
end

function GQ:GetEffectiveClass()
    local ctx = self._ctx
    local value = ctx and ctx.class
    if value == nil then
        value = self.Preview:GetEffectiveClass()
        if ctx then
            ctx.class = value
        end
    end
    return value
end

function GQ:GetEffectiveFaction()
    local ctx = self._ctx
    local value = ctx and ctx.faction
    if value == nil then
        value = self.Preview:GetEffectiveFaction()
        if ctx then
            ctx.faction = value
        end
    end
    return value
end

-- No spec (below 10, or a class without specs) is common; remember that too.
local NO_SPEC = {}

function GQ:GetEffectiveSpec()
    local ctx = self._ctx
    local value = ctx and ctx.spec
    if value == NO_SPEC then
        return nil
    end
    if value == nil then
        value = self.Preview:GetEffectiveSpec()
        if ctx then
            ctx.spec = value == nil and NO_SPEC or value
        end
    end
    return value
end

function GQ:GetPreviewLabel()
    return self.Preview:GetLabel()
end
