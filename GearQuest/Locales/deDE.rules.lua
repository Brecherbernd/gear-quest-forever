local _, GQ = ...

-- German patterns for the sentence shapes the data pipeline repeats.
-- Names inside them are translated through GQ.LocaleNames and the client.
-- A rule that cannot place a name still answers, with the English name.
if GQ.LOCALE ~= "deDE" then
    return
end

local L = GQ.L
local rules = GQ.LocaleRules
GQ.LocaleObjectiveLabel = "Ziel: "

local function Any(name)
    return GQ.TAny(name)
end

local function Zone(name)
    return GQ.TN("zone", name)
end

local function Quest(name)
    return "„" .. GQ.TN("quest", name) .. "“"
end

-- "Name" or "the Name" or "a Name": the article is English, drop it for the lookup.
local function Thing(name)
    local bare = name:gsub("^[Tt]he ", ""):gsub("^an? ", "")
    local translated = Any(bare)
    if translated ~= bare then
        return translated
    end
    -- English plural on an item name: "Idols of the Sage", "Gold Scarabs".
    local head, tail = bare:match("^(.-)s( of .+)$")
    if head and Any(head .. tail) ~= head .. tail then
        return Any(head .. tail)
    end
    if bare:sub(-1) == "s" then
        local single = bare:sub(1, -2)
        if Any(single) ~= single then
            return Any(single)
        end
        if bare:sub(-3) == "ies" and Any(bare:sub(1, -4) .. "y") ~= bare:sub(1, -4) .. "y" then
            return Any(bare:sub(1, -4) .. "y")
        end
    end
    return name
end

-- "1 A, 2 B and 5 C" or "A, B, and C".
local function List(text)
    text = text:gsub(",? and ", ", ")
    local parts = {}
    for piece in (text .. ", "):gmatch("(.-), ") do
        local count, name = piece:match("^(%d+) (.+)$")
        if count then
            parts[#parts + 1] = count .. "x " .. Thing(name)
        elseif piece ~= "" then
            parts[#parts + 1] = Thing(piece)
        end
    end
    if #parts == 1 then
        return parts[1]
    end
    return table.concat(parts, ", ", 1, #parts - 1) .. " und " .. parts[#parts]
end

-- "Npc in Zone" -> "Npc (Zone)"
local function NpcAt(text)
    local who, where = text:match("^(.+) in (.+)$")
    if who then
        return Any(who) .. " (" .. Zone(where) .. ")"
    end
    local who2, where2 = text:match("^(.+) at (.+)$")
    if who2 then
        return Any(who2) .. " (" .. Zone(where2:gsub("^the ", "")) .. ")"
    end
    return Any(text)
end

local function Stat(name)
    local word = GQ.LocaleStatWords and GQ.LocaleStatWords[name]
    if word then
        return word
    end
    local translated = L[name]
    if translated ~= name then
        return translated
    end
    local lower = name:sub(1, 1):upper() .. name:sub(2):lower()
    translated = L[lower]
    return translated ~= lower and translated or name
end

local function add(pattern, fn)
    rules[#rules + 1] = { pattern, fn }
end

local NUMBER_WORDS = {
    two = "zwei", three = "drei", four = "vier", five = "fünf", six = "sechs",
    seven = "sieben", eight = "acht", nine = "neun", ten = "zehn",
}

-- Sources
add("^Reward from the quest '(.+)'%.$", function(q)
    return "Belohnung der Quest " .. Quest(q) .. "."
end)
add("^Reward from the quest '(.+)'%. Pick it over the other reward choices%.$", function(q)
    return "Belohnung der Quest " .. Quest(q) .. ". Wähle sie statt der anderen Belohnungen."
end)
add("^Reward from the quest '(.+)', the last of (%a+) steps%.$", function(q, steps)
    return "Belohnung der Quest " .. Quest(q) .. ", dem letzten von " .. (NUMBER_WORDS[steps] or steps) .. " Schritten."
end)
add("^Starts with (.+)%.$", function(rest)
    return "Beginnt bei " .. NpcAt(rest) .. "."
end)
add("^The chain starts with (.+)%.$", function(rest)
    return "Die Questreihe beginnt bei " .. NpcAt(rest) .. "."
end)
add("^The quest is in (.+)%.$", function(z)
    return "Ort der Quest: " .. Zone(z) .. "."
end)
add("^This quest is in (.+)%.$", function(z)
    return "Ort der Quest: " .. Zone(z) .. "."
end)
add("^That step is level (%d+)%.$", function(n)
    return "Dieser Schritt ist Stufe " .. n .. "."
end)
add("^Drops from trash in (.+)%.$", function(z)
    return "Beute von normalen Gegnern in: " .. Zone((z:gsub("^the ", ""))) .. "."
end)
add("^Drops in the (.+)%.$", function(z)
    return "Beute in: " .. Zone(z) .. "."
end)
add("^Drops in (.+)%.$", function(z)
    return "Beute in: " .. Zone(z) .. "."
end)
add("^Drops from (.+) in (.+)%.$", function(who, z)
    return "Beute von " .. List(who) .. " (" .. Zone(z) .. ")."
end)
add("^Drops from (.+)%.$", function(who)
    return "Beute von " .. List(who) .. "."
end)
add("^Dropped by (.+)%.$", function(who)
    return "Beute von " .. List(who) .. "."
end)
add("^World drop around level (%d+)%-(%d+)%.$", function(a, b)
    return "Weltdrop etwa auf Stufe " .. a .. " bis " .. b .. "."
end)
add("^World drop around level (%d+)%.$", function(a)
    return "Weltdrop etwa auf Stufe " .. a .. "."
end)
add("^World drop%.$", function()
    return "Weltdrop."
end)
add("^Bought from (.+) %((%a+)%) or (.+) %((%a+)%)%.$", function(a, fa, b, fb)
    return "Erhältlich bei " .. NpcAt(a) .. " [" .. L[fa] .. "] oder " .. NpcAt(b) .. " [" .. L[fb] .. "]."
end)
add("^Bought from (.+) %- costs tokens or reputation%.$", function(who)
    return "Erhältlich bei " .. NpcAt(who) .. ", gegen Abzeichen oder Ruf."
end)
add("^Bought from (.+)%. Costs Honor Points and tokens %(Marks of Honor%)%.$", function(who)
    return "Erhältlich bei " .. NpcAt(who) .. ". Kostet Ehrenpunkte und Abzeichen (Ehrenabzeichen)."
end)
add("^Bought from (.+)%.$", function(who)
    if who == "a vendor" then
        return "Bei einem Händler erhältlich."
    end
    return "Erhältlich bei " .. NpcAt(who) .. "."
end)
add("^Crafted with (%a[%a ]-) %(requires skill (%d+)%)%.$", function(prof, skill)
    return "Hergestellt mit " .. L[prof] .. " (erfordert Fertigkeit " .. skill .. ")."
end)
add("^Crafted with (%a[%a ]-)%.$", function(prof)
    return "Hergestellt mit " .. L[prof] .. "."
end)
add("^Craft (.+) %((%a+)%)%.$", function(item, prof)
    return "Stelle " .. Thing(item) .. " her (" .. L[prof] .. ")."
end)
add("^Recipe in (.+), (.+)%.$", function(place, z)
    return "Rezept: " .. Zone(place) .. ", " .. Zone(z) .. "."
end)
add("^Requires level (%d+)%.$", function(n)
    return "Erfordert Stufe " .. n .. "."
end)
add("^Requires (.+) %- (%a+)%.$", function(faction, standing)
    return "Erfordert " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. "."
end)
add("^Set piece of (.+) %((.+)%)%.$", function(set, z)
    return "Setteil von " .. Any(set) .. " (" .. Zone(z) .. ")."
end)
add("^Set piece of (.+)%.$", function(set)
    return "Setteil von " .. Any(set) .. "."
end)
add("^Part of the (.+)%.$", function(set)
    return "Teil von " .. Any(set) .. "."
end)

-- Stats and set bonuses: "+10 Intellect", "(2) +10 Intellect."
add("^%((%d)%) %+(%d+) ([%a ]+)%.$", function(n, value, stat)
    return "(" .. n .. ") +" .. value .. " " .. Stat(stat) .. "."
end)
add("^%+(%d+) ([%a ]+)$", function(value, stat)
    local translated = Stat(stat)
    if translated == stat then
        return nil
    end
    return "+" .. value .. " " .. translated
end)
add("^%+(%d+) ([%a ]+) and %+(%d+) ([%a ]+)$", function(a, sa, b, sb)
    return "+" .. a .. " " .. Stat(sa) .. " und +" .. b .. " " .. Stat(sb)
end)
add("^%+(%d+) ([%a ]+), %+(%d+) ([%a ]+)$", function(a, sa, b, sb)
    return "+" .. a .. " " .. Stat(sa) .. ", +" .. b .. " " .. Stat(sb)
end)

-- Objectives with no client text (new Forever quests, renamed quests).
local function Rest(text)
    return GQ.LocaleTranslateSentence(text)
end
add("^Objective: (.+)$", function(rest)
    return "Ziel: " .. Rest(rest)
end)
add("^Bring (.+) to (.+)%.$", function(what, who)
    return "Bringe " .. List(what) .. " zu " .. NpcAt(who) .. "."
end)
add("^Take (.+) to (.+)%.$", function(what, who)
    return "Bringe " .. List(what) .. " zu " .. NpcAt(who) .. "."
end)
add("^Deliver (.+) to (.+)%.$", function(what, who)
    return "Bringe " .. List(what) .. " zu " .. NpcAt(who) .. "."
end)
add("^Collect (.+) and (%a+) them to (.+)%.$", function(what, _, who)
    return "Sammle " .. List(what) .. " und bringe sie zu " .. NpcAt(who) .. "."
end)
add("^Collect (.+)%.$", function(what)
    return "Sammle " .. List(what) .. "."
end)
add("^Retrieve (.+) and return them to (.+)%.$", function(what, who)
    return "Beschaffe " .. List(what) .. " und bringe sie zu " .. NpcAt(who) .. " zurück."
end)
add("^Kill (.+) for (.+)%.$", function(what, who)
    return "Töte " .. List(what) .. " für " .. NpcAt(who) .. "."
end)
add("^Kill (.+), then return to (.+)%.$", function(what, who)
    return "Töte " .. List(what) .. " und kehre dann zu " .. NpcAt(who) .. " zurück."
end)
add("^Kill (.+)%.$", function(what)
    return "Töte " .. List(what) .. "."
end)
add("^Slay (.+) and return to (.+)%.$", function(what, who)
    return "Erschlage " .. List(what) .. " und kehre zu " .. NpcAt(who) .. " zurück."
end)
add("^(.+) wants you to kill (.+)%.$", function(who, what)
    return NpcAt(who) .. " möchte, dass du " .. List(what) .. " tötest."
end)
add("^Speak with (.+)%.$", function(who)
    return "Sprich mit " .. NpcAt(who) .. "."
end)
add("^Speak to (.+)%.$", function(who)
    return "Sprich mit " .. NpcAt(who) .. "."
end)
add("^Talk to (.+)%.$", function(who)
    return "Sprich mit " .. NpcAt(who) .. "."
end)
add("^Found in (.+)%.$", function(what)
    return "Zu finden in: " .. Thing(what) .. "."
end)
add("^Combined from (.+) and (.+)%.$", function(a, b)
    return "Zusammengesetzt aus " .. Thing(a) .. " und " .. Thing(b) .. "."
end)
add("^Seen in (.+) on (.+)%.$", function(place, z)
    return "Gesehen in " .. Zone(place) .. " (" .. Zone(z) .. ")."
end)
add("^Quest reward in (.+) on (.+)%.$", function(place, z)
    return "Questbelohnung in " .. Zone(place) .. " (" .. Zone(z) .. ")."
end)
add("^Rank (%d+) behind (.+)%.$", function(n, what)
    return "Rang " .. n .. " hinter " .. Thing(what) .. "."
end)
add("^Rank (%d+) at ([%d–%-]+) behind (.+)%.$", function(n, lvl, what)
    return "Rang " .. n .. " auf Stufe " .. lvl .. ", hinter " .. Thing(what) .. "."
end)
add("^Requires level (%d+) to pick up%.$", function(n)
    return "Annehmbar ab Stufe " .. n .. "."
end)
add("^The quest requires level (%d+)%.$", function(n)
    return "Die Quest erfordert Stufe " .. n .. "."
end)
add("^Alliance: (.+) at (.+)%.$", function(who, where)
    return "Allianz: " .. Any(who) .. " (" .. Zone(where) .. ")."
end)
add("^Horde: (.+) at (.+)%.$", function(who, where)
    return "Horde: " .. Any(who) .. " (" .. Zone(where) .. ")."
end)
add("^Reward from '(.+)' %(Alliance%) or '(.+)' %(Horde%)%.$", function(a, b)
    return "Belohnung aus " .. Quest(a) .. " (Allianz) oder " .. Quest(b) .. " (Horde)."
end)
add("^You must also attain (%a+) reputation with (.+) to complete this quest%.$", function(standing, faction)
    return "Du brauchst außerdem den Ruf " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. ", um diese Quest abzuschließen."
end)
add("^You must also obtain (%a+) reputation with (.+) to complete this quest%.$", function(standing, faction)
    return "Du brauchst außerdem den Ruf " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. ", um diese Quest abzuschließen."
end)
add("^You must also attain (%a+) reputation with (.+) to be able to complete this quest%.$", function(standing, faction)
    return "Du brauchst außerdem den Ruf " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. ", um diese Quest abschließen zu können."
end)
add("^You must also be of (%a+) reputation with (.+)%.$", function(standing, faction)
    return "Du brauchst außerdem den Ruf " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. "."
end)
add("^This quest also requires (%a+) faction with (.+)%.$", function(standing, faction)
    return "Diese Quest erfordert außerdem den Ruf " .. L[standing] .. " bei " .. GQ.TN("faction", faction) .. "."
end)
add("^You can buy the recipe from (.+) at the Durotar Supply and Logistics camp northwest of the Crossroads in The Barrens, or from (.+) at the Azeroth Commerce Authority camp at Three Corners in Redridge Mountains%.$", function(h, a)
    return "Das Rezept gibt es bei " .. Any(h) .. " im Lager von Durotar Supply and Logistics nordwestlich des Wegekreuzes (" .. Zone("The Barrens")
        .. ") oder bei " .. Any(a) .. " im Lager der Azeroth Commerce Authority an der Dreiecken-Kreuzung (" .. Zone("Redridge Mountains") .. ")."
end)

-- Stat lists written by the pipeline: "+7 Intellect, +6 Stamina, +20 healing / +7 spell damage, 109 armor".
local STAT_WORDS = {
    ["healing"] = "Heilung", ["spell damage"] = "Zauberschaden", ["spell power"] = "Zaubermacht",
    ["armor"] = "Rüstung", ["Fire damage"] = "Feuerschaden", ["Frost damage"] = "Frostschaden",
    ["Shadow damage"] = "Schattenschaden", ["Arcane damage"] = "Arkanschaden",
    ["Nature damage"] = "Naturschaden", ["Holy damage"] = "Heiligschaden",
    ["Spell Damage"] = "Zauberschaden", ["Weapon Damage"] = "Waffenschaden",
    ["Defense"] = "Verteidigung", ["Mana per 5 sec"] = "Mana alle 5 Sek.", ["Mana every 5 sec"] = "Mana alle 5 Sek.",
    ["Health every 5 sec"] = "Gesundheit alle 5 Sek.",
    ["Fire Spell Power"] = "Feuerzaubermacht", ["Frost Spell Power"] = "Frostzaubermacht",
    ["Shadow Spell Power"] = "Schattenzaubermacht", ["Nature Spell Power"] = "Naturzaubermacht",
    ["Arcane Spell Power"] = "Arkanzaubermacht", ["Holy Spell Power"] = "Heiligzaubermacht",
    ["Mana per 5"] = "Mana alle 5 Sek.", ["Spell Damage and Healing"] = "Zauberschaden und Heilung",
    ["Holy Damage"] = "Heiligschaden", ["Healing"] = "Heilung", ["Spell Power"] = "Zaubermacht",
    ["All Resistances"] = "alle Widerstandsarten", ["Shadow Resistance"] = "Schattenwiderstand",
    ["Fire Resistance"] = "Feuerwiderstand", ["Frost Resistance"] = "Frostwiderstand",
    ["Nature Resistance"] = "Naturwiderstand", ["Arcane Resistance"] = "Arkanwiderstand",
    ["Ranged Weapon Damage"] = "Distanzwaffenschaden", ["Attack Power"] = "Angriffskraft",
    ["Ranged Attack Power"] = "Distanzangriffskraft", ["All Stats"] = "alle Werte",
}
local function StatPart(part)
    local alternatives = {}
    for alt in (part .. " / "):gmatch("(.-) / ") do
        local sign, value, stat = alt:match("^([%+%-]?)(%d+%-?%d*%%?) (.+)$")
        if not value then
            return nil
        end
        local word = STAT_WORDS[stat] or Stat(stat)
        if word == stat then
            return nil
        end
        alternatives[#alternatives + 1] = sign .. value .. " " .. word
    end
    return table.concat(alternatives, " / ")
end
local function StatList(text)
    local parts = {}
    for part in (text .. ", "):gmatch("(.-), ") do
        local translated = StatPart(part)
        if not translated then
            return nil
        end
        parts[#parts + 1] = translated
    end
    return table.concat(parts, ", ")
end
GQ.LocaleStatList = StatList
GQ.LocaleStatWords = STAT_WORDS
add("^([%+%-]?%d[^%.]*)%.$", function(text)
    local stats = StatList(text)
    if stats then
        return stats .. "."
    end
    -- Reagents: "8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye".
    for piece in (text:gsub(",? and ", ", ") .. ", "):gmatch("(.-), ") do
        if not piece:match("^%d+ %u") then
            return nil
        end
    end
    return List(text) .. "."
end)
add("^([%+%-]%d[^%.]*)$", function(text)
    return StatList(text)
end)
add('^Reward from the quest "(.+)"%.$', function(q)
    return "Belohnung der Quest " .. Quest(q) .. "."
end)

-- Item effects (proc text), worded like the German client's tooltips.
local SCHOOL = {
    Fire = "Feuer", Frost = "Frost", Nature = "Natur", Shadow = "Schatten",
    Arcane = "Arkan", Holy = "Heilig", Holyfire = "Heiligfeuer", Holystorm = "Heiligsturm",
}
local function Dmg(amount, school)
    if school == "Physical" then
        return amount .. " körperlichen Schaden"
    end
    local kind = school and SCHOOL[school]
    if school and not kind then
        return nil
    end
    return amount .. " " .. (kind and (kind .. "schaden") or "Schaden")
end
local function Range(text)
    return (text:gsub(" to ", " bis "))
end
local function Secs(n)
    return n .. " Sek."
end

add("^Chance on hit: (.+)$", function(rest)
    return "Chance bei Treffer: " .. Rest(rest)
end)
add("^Equip: (.+)$", function(rest)
    return "Anlegen: " .. Rest(rest)
end)
add("^Use: (.+)$", function(rest)
    return "Benutzen: " .. Rest(rest)
end)
add("^%(Proc chance: (%d+%%)%)$", function(p)
    return "(Auslösechance: " .. p .. ")"
end)
add("^%(Proc chance: (%d+%%), (%d+)(m?s?) cooldown%)$", function(p, n, unit)
    local u = unit == "m" and " Min." or unit == "ms" and " ms" or " Sek."
    return "(Auslösechance: " .. p .. ", Abklingzeit " .. n .. u .. ")"
end)
add("^%((%d+)(m?s?) cooldown%)$", function(n, unit)
    local u = unit == "m" and " Min." or unit == "ms" and " ms" or " Sek."
    return "(Abklingzeit " .. n .. u .. ")"
end)
add("^%((%d+) Min Cooldown%)$", function(n)
    return "(" .. n .. " Min. Abklingzeit)"
end)
add("^%((%d+) Hours? Cooldown%)$", function(n)
    return "(" .. n .. " Std. Abklingzeit)"
end)
add("^%((%d+) Hrs Cooldown%)$", function(n)
    return "(" .. n .. " Std. Abklingzeit)"
end)
add("^%((%d+) Min, (%d+) Sec Cooldown%)$", function(m, s)
    return "(" .. m .. " Min. " .. s .. " Sek. Abklingzeit)"
end)

add("^Improves your chance to hit by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Trefferchance um " .. p .. "."
end)
add("^Improves your chance to get a critical strike by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Chance, einen kritischen Treffer zu erzielen, um " .. p .. "."
end)
add("^Improves your chance to get a critical strike with spells by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Chance, mit Zaubern einen kritischen Treffer zu erzielen, um " .. p .. "."
end)
add("^Increases your chance to Dodge an attack by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Chance, einem Angriff auszuweichen, um " .. p .. "."
end)
add("^Increases your chance to Parry an attack by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Chance, einen Angriff zu parieren, um " .. p .. "."
end)
add("^Increases your chance to Block attacks with a shield by ([%d%.]+%%)%.$", function(p)
    return "Erhöht Eure Chance, Angriffe mit einem Schild zu blocken, um " .. p .. "."
end)
add("^Reduces chance to be Dodged or Parried by ([%d%.]+%%)%.$", function(p)
    return "Verringert die Chance, dass Euren Angriffen ausgewichen wird oder sie pariert werden, um " .. p .. "."
end)
add("^Gives you a 50%% chance to avoid interruption caused by damage while casting (.+)%.$", function(spell)
    return "Gewährt Euch eine Chance von 50 %, beim Wirken von " .. spell .. " nicht durch Schaden unterbrochen zu werden."
end)

add("^Blasts a target for ([%d to]+) (%a+) damage%.$", function(n, school)
    local d = Dmg(Range(n), school)
    return d and ("Trifft ein Ziel und fügt ihm " .. d .. " zu.")
end)
add("^Blasts up to (%d+) targets for ([%d to]+) (%a+) damage%.$", function(t, n, school)
    local d = Dmg(Range(n), school)
    return d and ("Trifft bis zu " .. t .. " Ziele und fügt ihnen " .. d .. " zu.")
end)
add("^Sends a shadowy bolt at the enemy,? causing ([%d to]+) Shadow damage%.$", function(n)
    return "Schleudert einen Schattenblitz auf den Gegner, der " .. Dmg(Range(n), "Shadow") .. " verursacht."
end)
add("^Poisons target for (%d+) Nature damage every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Vergiftet das Ziel und fügt ihm " .. Secs(dur) .. " lang alle " .. Secs(every) .. " " .. Dmg(n, "Nature") .. " zu."
end)
add("^Wounds the target causing them to bleed for (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Verwundet das Ziel, sodass es blutet und im Verlauf von " .. Secs(dur) .. " " .. Dmg(n) .. " erleidet."
end)
add("^Wounds the target for ([%d to]+) damage%.$", function(n)
    return "Verwundet das Ziel und fügt ihm " .. Dmg(Range(n)) .. " zu."
end)
add("^Wounds the target for ([%d to]+) Physical damage%.$", function(n)
    return "Verwundet das Ziel und fügt ihm " .. Dmg(Range(n), "Physical") .. " zu."
end)
add("^Wounds the target for (%d+) damage and lowers their armor by (%d+)%.$", function(n, a)
    return "Verwundet das Ziel, fügt ihm " .. Dmg(n) .. " zu und verringert seine Rüstung um " .. a .. "."
end)
add("^Hurls a fiery ball that causes ([%d to]+) Fire damage and an additional (%d+) damage over (%d+) sec%.$", function(n, extra, dur)
    return "Schleudert einen Feuerball, der " .. Dmg(Range(n), "Fire") .. " und im Verlauf von " .. Secs(dur) .. " zusätzlich " .. Dmg(extra) .. " verursacht."
end)
add("^Launches a bolt of frost at the enemy causing ([%d to]+) Frost damage and slowing movement speed by (%d+%%) for (%d+) sec%.$", function(n, p, dur)
    return "Schießt einen Frostblitz auf den Gegner, der " .. Dmg(Range(n), "Frost") .. " verursacht und das Bewegungstempo " .. Secs(dur) .. " lang um " .. p .. " verringert."
end)
add("^Corrupts the target, causing (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Verderbt das Ziel und fügt ihm im Verlauf von " .. Secs(dur) .. " " .. Dmg(n) .. " zu."
end)
add("^Puncture the target, inflicting (%d+) Physical damage%.$", function(n)
    return "Durchbohrt das Ziel und fügt ihm " .. Dmg(n, "Physical") .. " zu."
end)
add("^Delivers a fatal wound for ([%d to]+) Physical damage%.$", function(n)
    return "Fügt eine tödliche Wunde zu, die " .. Dmg(Range(n), "Physical") .. " verursacht."
end)
add("^Steals ([%d to]+) life from target enemy%.$", function(n)
    return "Stiehlt dem feindlichen Ziel " .. Range(n) .. " Leben."
end)
add("^Heals wielder of (%d+) damage%.$", function(n)
    return "Heilt den Träger um " .. n .. " Gesundheit."
end)
add("^Heals wielder of (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Heilt den Träger im Verlauf von " .. Secs(dur) .. " um " .. n .. " Gesundheit."
end)
add("^Stuns? target for ([%d%.]+) sec%.$", function(n)
    return "Betäubt das Ziel " .. Secs(n:gsub("%.", ",")) .. " lang."
end)
add("^Stun the target for ([%d%.]+) sec%.$", function(n)
    return "Betäubt das Ziel " .. Secs(n:gsub("%.", ",")) .. " lang."
end)
add("^Disarm target's weapon for (%d+) sec%.$", function(n)
    return "Entwaffnet das Ziel " .. Secs(n) .. " lang."
end)
add("^Reduces target enemy's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Verringert " .. Secs(dur) .. " lang die Angriffskraft des feindlichen Ziels um " .. n .. "."
end)
add("^Reduces the target enemy's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Verringert " .. Secs(dur) .. " lang die Angriffskraft des feindlichen Ziels um " .. n .. "."
end)
add("^Reduces target's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Verringert " .. Secs(dur) .. " lang die Angriffskraft des Ziels um " .. n .. "."
end)
add("^Grants a?n? ?1? ?extra attack on your next swing%.$", function()
    return "Gewährt bei Eurem nächsten Schlag einen zusätzlichen Angriff."
end)
add("^Increases attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Erhöht " .. Secs(dur) .. " lang die Angriffskraft um " .. n .. "."
end)
add("^Increases Attack Power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Erhöht " .. Secs(dur) .. " lang die Angriffskraft um " .. n .. "."
end)
add("^Increases armor by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Erhöht " .. Secs(dur) .. " lang die Rüstung um " .. n .. "."
end)
add("^Increases Spirit by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Erhöht " .. Secs(dur) .. " lang die Willenskraft um " .. n .. "."
end)
add("^Increases run speed by (%d+%%) for (%d+) sec%.$", function(p, dur)
    return "Erhöht " .. Secs(dur) .. " lang das Lauftempo um " .. p .. "."
end)
add("^Restores (%d+) mana%.$", function(n)
    return "Stellt " .. n .. " Mana wieder her."
end)
add("^Restores (%d+) to (%d+) mana%.$", function(a, b)
    return "Stellt " .. a .. " bis " .. b .. " Mana wieder her."
end)
add("^Restores (%d+) health%.$", function(n)
    return "Stellt " .. n .. " Gesundheit wieder her."
end)
add("^Restores (%d+) health every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Stellt " .. Secs(dur) .. " lang alle " .. Secs(every) .. " " .. n .. " Gesundheit wieder her."
end)
add("^Restores (%d+) mana every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Stellt " .. Secs(dur) .. " lang alle " .. Secs(every) .. " " .. n .. " Mana wieder her."
end)
add("^Restores (%d+) mana over (%d+) sec%.$", function(n, dur)
    return "Stellt im Verlauf von " .. Secs(dur) .. " " .. n .. " Mana wieder her."
end)
add("^Heal yourself for (%d+) to (%d+)%.$", function(a, b)
    return "Heilt Euch um " .. a .. " bis " .. b .. "."
end)
add("^Heal your target for (%d+) to (%d+)%.$", function(a, b)
    return "Heilt Euer Ziel um " .. a .. " bis " .. b .. "."
end)
add("^Heal friendly target for (%d+) to (%d+)%.$", function(a, b)
    return "Heilt ein freundliches Ziel um " .. a .. " bis " .. b .. "."
end)
add("^Absorbs (%d+) to (%d+) physical damage%. \239\191\189 Lasts (%d+) sec%.$", function(a, b, dur)
    return "Absorbiert " .. a .. " bis " .. b .. " körperlichen Schaden. Hält " .. Secs(dur) .. " lang an."
end)
add("^Deals (%d+) times as much damage to (.+)%.$", function(n, who)
    return "Fügt " .. who .. " " .. n .. "-mal so viel Schaden zu."
end)
add("^Deals 2x damage to (.+)%.$", function(who)
    return "Fügt " .. who .. " doppelten Schaden zu."
end)
add("^Mechanical targets take 2x damage%.$", function()
    return "Mechanische Ziele erleiden doppelten Schaden."
end)
add("^Must remain seated while drinking%.$", function()
    return "Ihr müsst beim Trinken sitzen bleiben."
end)

-- Text the addon builds at display time (Data.lua, Log.lua).
add("^Costs (.+)%.$", function(rest)
    return "Kostet " .. rest .. "."
end)
add("^The (%a[%a ]-) pattern drops from (.+)%.$", function(prof, who)
    return "Das Muster (" .. L[prof] .. ") ist Beute von " .. List(who) .. "."
end)
add("^The (%a[%a ]-) pattern is dropped by (.+)%.$", function(prof, who)
    return "Das Muster (" .. L[prof] .. ") ist Beute von " .. List(who) .. "."
end)
add("^The (%a[%a ]-) pattern is the drop%.$", function(prof)
    return "Die Beute ist das Muster (" .. L[prof] .. ")."
end)

-- Wowhead tooltip lines, shown when the client does not know the item.
-- Worded like the German client's own tooltips.
local CLASS_DE = {
    Warrior = "Krieger", Paladin = "Paladin", Hunter = "Jäger", Rogue = "Schurke", Priest = "Priester",
    Shaman = "Schamane", Mage = "Magier", Warlock = "Hexenmeister", Druid = "Druide",
}
local CREATURE_DE = {
    Beasts = "Wildtiere", Humanoids = "Humanoide", Undead = "Untote", Demons = "Dämonen",
    Dragonkin = "Drachkin", Elementals = "Elementare", Giants = "Riesen", Mechanicals = "mechanische Wesen",
}
local function Tip(pattern, fn)
    add(pattern, fn)
end
Tip("^Item Level (%d+)$", function(n) return "Gegenstandsstufe " .. n end)
Tip("^Requires Level (%d+)$", function(n) return "Benötigt Stufe " .. n end)
Tip("^(%d+) Armor$", function(n) return n .. " Rüstung" end)
Tip("^(%d+) Block$", function(n) return n .. " Blocken" end)
Tip("^Durability (%d+) / (%d+)$", function(a, b) return "Haltbarkeit " .. a .. " / " .. b end)
Tip("^Speed ([%d%.]+)$", function(n) return "Tempo " .. n:gsub("%.", ",") end)
Tip("^%(([%d%.]+) damage per second%)$", function(n) return "(" .. n:gsub("%.", ",") .. " Schaden pro Sekunde)" end)
Tip("^(%d+) %- (%d+) Damage$", function(a, b) return a .. " - " .. b .. " Schaden" end)
Tip("^%+?%s?(%d+) %- (%d+) (%a+) Damage$", function(a, b, school)
    return SCHOOL[school] and ("+" .. a .. " - " .. b .. " " .. SCHOOL[school] .. "schaden")
end)
Tip("^Sell Price: (.+)$", function(coin) return "Verkaufspreis: " .. coin end)
Tip("^Drop Chance: ([%d%.]+%%)$", function(p) return "Dropchance: " .. p end)
Tip("^Dropped by: (.+)$", function(who) return "Beute von: " .. Any(who) end)
Tip("^Binds when picked up$", function() return "Wird beim Aufheben gebunden" end)
Tip("^Binds when equipped$", function() return "Wird beim Anlegen gebunden" end)
Tip("^Binds when used$", function() return "Wird bei Benutzung gebunden" end)
Tip("^Quest Item$", function() return "Questgegenstand" end)
Tip("^Unique%-Equipped$", function() return "Einzigartig anlegbar" end)
Tip("^(%d+) Charges$", function(n) return n .. " Aufladungen" end)
Tip("^Classes: (.+)$", function(list)
    local names = {}
    for class in (list .. ", "):gmatch("(.-), ") do
        local client = type(LOCALIZED_CLASS_NAMES_MALE) == "table" and LOCALIZED_CLASS_NAMES_MALE[class:upper()]
        names[#names + 1] = type(client) == "string" and client or CLASS_DE[class] or class
    end
    return "Klassen: " .. table.concat(names, ", ")
end)
Tip("^Requires (%a[%a ]-) %((%d+)%)$", function(skill, n) return "Benötigt " .. L[skill] .. " (" .. n .. ")" end)
Tip("^%+(%d+) (%a+) Resistance%.?$", function(n, school)
    return SCHOOL[school] and ("+" .. n .. " " .. SCHOOL[school] .. "widerstand")
end)
Tip("^%+(%d+) Spell Penetration$", function(n) return "+" .. n .. " Zauberdurchschlagskraft" end)
Tip("^%+(%d+) Attack Power against (%a+)%.?$", function(n, who)
    return CREATURE_DE[who] and ("+" .. n .. " Angriffskraft gegen " .. CREATURE_DE[who] .. ".")
end)
Tip("^%((%d+)%) Set ?: (.+)$", function(n, rest) return "(" .. n .. ") Set: " .. Rest(rest) end)
Tip("^Increases damage and healing done by magical spells and effects by up to (%d+)%.?$", function(n)
    return "Erhöht durch Zauber und magische Effekte zugefügten Schaden und Heilung um bis zu " .. n .. "."
end)
Tip("^Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects%.?$", function(h, d)
    return "Erhöht durch sämtliche Zauber und magischen Effekte verursachte Heilung um bis zu " .. h .. " und zugefügten Schaden um bis zu " .. d .. "."
end)
Tip("^Increases healing done by magical spells and effects by up to (%d+)%.?$", function(n)
    return "Erhöht durch Zauber und magische Effekte verursachte Heilung um bis zu " .. n .. "."
end)
Tip("^Increases healing done by spells and effects by up to (%d+)%.?$", function(n)
    return "Erhöht durch Zauber und Effekte verursachte Heilung um bis zu " .. n .. "."
end)
Tip("^Increases damage done by magical spells and effects by up to (%d+)%.?$", function(n)
    return "Erhöht durch Zauber und magische Effekte zugefügten Schaden um bis zu " .. n .. "."
end)
Tip("^Increases damage done by (%a+) spells and effects by up to (%d+)%.?$", function(school, n)
    local s = SCHOOL[school]
    return s and ("Erhöht durch " .. s .. "zauber und " .. s .. "effekte zugefügten Schaden um bis zu " .. n .. ".")
end)
Tip("^Increases damage done to (%a+) by magical spells and effects by up to (%d+)%.?$", function(who, n)
    return CREATURE_DE[who] and ("Erhöht den Schaden, den Zauber und magische Effekte " .. CREATURE_DE[who] .. " zufügen, um bis zu " .. n .. ".")
end)
Tip("^Increased Defense %+(%d+)%.?$", function(n) return "Verteidigung +" .. n .. "." end)
Tip("^Increased (%a+) %+(%d+)%.?$", function(skill, n)
    local name = L[skill]
    return name ~= skill and (name .. " +" .. n .. ".")
end)
Tip("^Increases all Resistances by (%d+)%.?$", function(n) return "Erhöht alle Widerstände um " .. n .. "." end)
Tip("^Restores %+?(%d+) health per (%d+) sec%.?$", function(n, s) return "Stellt alle " .. Secs(s) .. " " .. n .. " Gesundheit wieder her." end)
Tip("^Restores %+?(%d+) mana per (%d+) sec%.?$", function(n, s) return "Stellt alle " .. Secs(s) .. " " .. n .. " Mana wieder her." end)
Tip("^Lasts (%d+) sec%.?$", function(n) return "Hält " .. Secs(n) .. " lang an." end)
Tip("^Lasts (%d+) min%.?$", function(n) return "Hält " .. n .. " Min. lang an." end)
Tip("^Can only occur once every (%d+) sec%.?$", function(n) return "Kann nur einmal alle " .. Secs(n) .. " auftreten." end)
Tip("^%((%d+) Sec Cooldown%)$", function(n) return "(" .. Secs(n) .. " Abklingzeit)" end)
Tip("^Stacks up to (%d+) times%.?$", function(n) return "Bis zu " .. n .. "-mal stapelbar." end)
Tip("^Does not stack with similar effects%.?$", function() return "Nicht mit ähnlichen Effekten stapelbar." end)
Tip("^Only active outdoors%.?$", function() return "Nur im Freien aktiv." end)
Tip("^Absorbs (%d+) to (%d+) physical damage%.?$", function(a, b) return "Absorbiert " .. a .. " bis " .. b .. " körperlichen Schaden." end)
Tip("^Increases your attack speed and casting speed by (%d+%%)%.?$", function(p)
    return "Erhöht Euer Angriffs- und Zaubertempo um " .. p .. "."
end)
Tip("^Increases healing done by spells and effects by up to (%d+)%.$", function(n)
    return "Erhöht durch Zauber und Effekte verursachte Heilung um bis zu " .. n .. "."
end)
Tip("^Restores %+?(%d+) mana per 5 sec%.$", function(n)
    return "Stellt alle 5 Sek. " .. n .. " Mana wieder her."
end)
Tip("^(.+) %((%d+)/(%d+)%)$", function(set, a, b)
    local name = Any(set)
    return name ~= set and (name .. " (" .. a .. "/" .. b .. ")")
end)
local TIP_WORDS = {
    Head = "Kopf", Neck = "Hals", Shoulder = "Schulter", Back = "Rücken", Chest = "Brust", Shirt = "Hemd",
    Tabard = "Wappenrock", Wrist = "Handgelenke", Hands = "Hände", Waist = "Taille", Legs = "Beine", Feet = "Füße",
    Finger = "Finger", Trinket = "Schmuck", ["One-Hand"] = "Einhändig", ["Two-Hand"] = "Zweihändig",
    ["Main Hand"] = "Waffenhand", ["Off Hand"] = "Schildhand", ["Held In Off-hand"] = "In Schildhand geführt",
    Ranged = "Distanz", Relic = "Relikt", Cloth = "Stoff", Leather = "Leder", Mail = "Schwere Rüstung",
    Plate = "Platte", Shield = "Schild", Idol = "Götze", Totem = "Totem", Libram = "Buchband",
    Sword = "Schwert", Axe = "Axt", Mace = "Streitkolben", Dagger = "Dolch", Staff = "Stab", Polearm = "Stangenwaffe",
    ["Fist Weapon"] = "Faustwaffe", Bow = "Bogen", Gun = "Schusswaffe", Crossbow = "Armbrust",
    Wand = "Zauberstab", Thrown = "Wurfwaffe", ["Fishing Pole"] = "Angelrute", Unique = "Einzigartig",
    Miscellaneous = "Verschiedenes", Projectile = "Projektil", Arrow = "Pfeil", Bullet = "Kugel", Quiver = "Köcher",
    ["Ammo Pouch"] = "Munitionsbeutel", Bag = "Tasche", Ammo = "Munition",
}
Tip("^([%a][%a%- ]*)$", function(word) return TIP_WORDS[word] end)
