local _, GQ = ...
local L = GQ.L

GQ.Commands = GQ.Commands or {}

local PREVIEW_PREFIXES = {
    "set ",
    "class ",
    "level ",
    "lvl ",
    "faction ",
    "spec ",
    "preview ",
}

local function IsPreviewCommand(lower)
    if lower == "set"
        or lower == "debug"
        or lower == "status"
        or lower == "preview"
        or lower == "me"
    then
        return true
    end

    for _, prefix in ipairs(PREVIEW_PREFIXES) do
        if lower:sub(1, #prefix) == prefix then
            return true
        end
    end

    return false
end

function GQ.Commands:Init()
    SLASH_GEARQUEST1 = "/gearquest"
    SLASH_GEARQUEST2 = "/gq"

    SlashCmdList["GEARQUEST"] = function(msg)
        msg = strtrim(msg or "")
        local lower = msg:lower()

        if lower == "" then
            GQ.Log:Toggle()
        elseif IsPreviewCommand(lower) then
            GQ.Preview:HandleCommand(lower)
            GQ:RefreshUI()
        elseif lower == "log" then
            GQ.Log:Toggle()
        elseif lower == "track" then
            if GQ.Log.selectedHuntId then
                GQ.Log:TrackHunt(GQ.Log.selectedHuntId)
            else
                GQ:Chat("|cff66ccffGearQuest|r: " .. L["No upgrade selected. Open |cff00ff00/gq log|r and pick one."])
            end
        elseif lower == "untrack" then
            if GQ.Log.selectedHuntId then
                GQ.Log:RequestUntrackHunt(GQ.Log.selectedHuntId)
            else
                GQ:Chat("|cff66ccffGearQuest|r: " .. L["No upgrade selected."])
            end
        elseif lower == "help" then
            GQ.Preview:PrintHelp()
        elseif lower == "wipe data" then
            GQ.Log:WipeCharacterData()
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["Cleared hunt progress for this character (tracked, completed, and obtained). Preview and UI settings kept."])
        elseif lower == "seen" or lower == "seen wipe" then
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["The seen-item notebook is retired. Forever item data comes from Wowhead."])
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["Unknown command. Try |cff00ff00/gq help|r, |cff00ff00/gq set|r, or |cff00ff00/gq log|r."])
        end
    end
end
