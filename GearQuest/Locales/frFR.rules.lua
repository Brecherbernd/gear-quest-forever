local _, GQ = ...

-- French patterns for the sentence shapes the data pipeline repeats.
-- Names inside them are translated through GQ.LocaleNames and the client.
-- A rule that cannot place a name still answers, with the English name.
if GQ.LOCALE ~= "frFR" then
    return
end

local L = GQ.L
local rules = GQ.LocaleRules
GQ.LocaleObjectiveLabel = "Objectif : "

local function Any(name)
    return GQ.TAny(name)
end

local function Zone(name)
    return GQ.TN("zone", name)
end

local function Quest(name)
    return "« " .. GQ.TN("quest", name) .. " »"
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
            parts[#parts + 1] = count .. " " .. Thing(name)
        elseif piece ~= "" then
            parts[#parts + 1] = Thing(piece)
        end
    end
    if #parts == 1 then
        return parts[1]
    end
    return table.concat(parts, ", ", 1, #parts - 1) .. " et " .. parts[#parts]
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

-- "de" before a name: elide before a vowel, fold the article (de Le -> du).
local function De(name)
    local first = name:sub(1, 1)
    if name:match("^Le ") then
        return "du " .. name:sub(4)
    elseif name:match("^Les ") then
        return "des " .. name:sub(5)
    elseif name:match("^La ") then
        return "de la " .. name:sub(4)
    elseif name:match("^L'") then
        return "de l'" .. name:sub(3)
    elseif first:match("[AEIOUYaeiouyH]") or name:match("^[\195][\128-\191]") then
        return "d'" .. name
    end
    return "de " .. name
end

local function add(pattern, fn)
    rules[#rules + 1] = { pattern, fn }
end

-- Sources
add("^Reward from the quest '(.+)'%.$", function(q)
    return "Récompense de la quête " .. Quest(q) .. "."
end)
add("^Reward from the quest '(.+)'%. Pick it over the other reward choices%.$", function(q)
    return "Récompense de la quête " .. Quest(q) .. ". Choisissez-la parmi les récompenses."
end)
add("^Starts with (.+)%.$", function(rest)
    return "Commence auprès " .. De(NpcAt(rest)) .. "."
end)
add("^The chain starts with (.+)%.$", function(rest)
    return "La suite commence auprès " .. De(NpcAt(rest)) .. "."
end)
add("^The quest is in (.+)%.$", function(z)
    return "Lieu de la quête : " .. Zone(z) .. "."
end)
add("^This quest is in (.+)%.$", function(z)
    return "Lieu de la quête : " .. Zone(z) .. "."
end)
add("^That step is level (%d+)%.$", function(n)
    return "Cette étape est de niveau " .. n .. "."
end)
add("^Drops from trash in (.+)%.$", function(z)
    return "Tombe sur les monstres " .. De((Zone((z:gsub("^the ", "")))))  .. "."
end)
add("^Drops in the (.+)%.$", function(z)
    return "Tombe dans " .. Zone(z) .. "."
end)
add("^Drops in (.+)%.$", function(z)
    return "Tombe dans " .. Zone(z) .. "."
end)
add("^Drops from (.+) in (.+)%.$", function(who, z)
    return "Butin " .. De(List(who)) .. " (" .. Zone(z) .. ")."
end)
add("^Drops from (.+)%.$", function(who)
    return "Butin " .. De(List(who)) .. "."
end)
add("^Dropped by (.+)%.$", function(who)
    return "Butin " .. De(List(who)) .. "."
end)
add("^World drop around level (%d+)%-(%d+)%.$", function(a, b)
    return "Butin du monde, vers les niveaux " .. a .. " à " .. b .. "."
end)
add("^World drop around level (%d+)%.$", function(a)
    return "Butin du monde, vers le niveau " .. a .. "."
end)
add("^World drop%.$", function()
    return "Butin du monde."
end)
add("^Bought from (.+) %((%a+)%) or (.+) %((%a+)%)%.$", function(a, fa, b, fb)
    return "Vendu par " .. NpcAt(a) .. " [" .. L[fa] .. "] ou " .. NpcAt(b) .. " [" .. L[fb] .. "]."
end)
add("^Bought from (.+) %- costs tokens or reputation%.$", function(who)
    return "Vendu par " .. NpcAt(who) .. ", contre des jetons ou de la réputation."
end)
add("^Bought from (.+)%. Costs Honor Points and tokens %(Marks of Honor%)%.$", function(who)
    return "Vendu par " .. NpcAt(who) .. ". Coûte des points d'honneur et des jetons (marques d'honneur)."
end)
add("^Bought from (.+)%.$", function(who)
    if who == "a vendor" then
        return "Vendu par un marchand."
    end
    return "Vendu par " .. NpcAt(who) .. "."
end)
add("^Crafted with (%a[%a ]-) %(requires skill (%d+)%)%.$", function(prof, skill)
    return "Fabrication : " .. L[prof] .. " (compétence " .. skill .. " requise)."
end)
add("^Crafted with (%a[%a ]-)%.$", function(prof)
    return "Fabrication : " .. L[prof] .. "."
end)
add("^Craft (.+) %((%a+)%)%.$", function(item, prof)
    return "Fabriquez " .. Thing(item) .. " (" .. L[prof] .. ")."
end)
add("^Recipe in (.+), (.+)%.$", function(place, z)
    return "Recette : " .. Zone(place) .. ", " .. Zone(z) .. "."
end)
add("^Requires level (%d+)%.$", function(n)
    return "Niveau " .. n .. " requis."
end)
add("^Requires (.+) %- (%a+)%.$", function(faction, standing)
    return "Réputation requise : " .. L[standing] .. " auprès de " .. GQ.TN("faction", faction) .. "."
end)
add("^Set piece of (.+) %((.+)%)%.$", function(set, z)
    return "Pièce de l'ensemble " .. Any(set) .. " (" .. Zone(z) .. ")."
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
    return "+" .. a .. " " .. Stat(sa) .. " et +" .. b .. " " .. Stat(sb)
end)
add("^%+(%d+) ([%a ]+), %+(%d+) ([%a ]+)$", function(a, sa, b, sb)
    return "+" .. a .. " " .. Stat(sa) .. ", +" .. b .. " " .. Stat(sb)
end)

-- Objectives with no client text (new Forever quests, renamed quests).
local function Rest(text)
    return GQ.LocaleTranslateSentence(text)
end
add("^Objective: (.+)$", function(rest)
    return "Objectif : " .. Rest(rest)
end)
add("^Bring (.+) to (.+)%.$", function(what, who)
    return "Apporter " .. List(what) .. " à " .. NpcAt(who) .. "."
end)
add("^Take (.+) to (.+)%.$", function(what, who)
    return "Apporter " .. List(what) .. " à " .. NpcAt(who) .. "."
end)
add("^Collect (.+) and (%a+) them to (.+)%.$", function(what, _, who)
    return "Récupérer " .. List(what) .. " et les apporter à " .. NpcAt(who) .. "."
end)
add("^Collect (.+)%.$", function(what)
    return "Récupérer " .. List(what) .. "."
end)
add("^Retrieve (.+) and return them to (.+)%.$", function(what, who)
    return "Récupérer " .. List(what) .. " et les rapporter à " .. NpcAt(who) .. "."
end)
add("^Kill (.+) for (.+)%.$", function(what, who)
    return "Tuer " .. List(what) .. " pour " .. NpcAt(who) .. "."
end)
add("^Kill (.+), then return to (.+)%.$", function(what, who)
    return "Tuer " .. List(what) .. ", puis retourner voir " .. NpcAt(who) .. "."
end)
add("^Kill (.+)%.$", function(what)
    return "Tuer " .. List(what) .. "."
end)
add("^Slay (.+) and return to (.+)%.$", function(what, who)
    return "Tuer " .. List(what) .. " et retourner voir " .. NpcAt(who) .. "."
end)
add("^(.+) wants you to kill (.+)%.$", function(who, what)
    return NpcAt(who) .. " veut que vous tuiez " .. List(what) .. "."
end)
add("^Speak with (.+)%.$", function(who)
    return "Parler à " .. NpcAt(who) .. "."
end)
add("^Talk to (.+)%.$", function(who)
    return "Parler à " .. NpcAt(who) .. "."
end)
add("^Found in (.+)%.$", function(what)
    return "Se trouve dans : " .. Thing(what) .. "."
end)
add("^Combined from (.+) and (.+)%.$", function(a, b)
    return "Combinaison de " .. Thing(a) .. " et " .. Thing(b) .. "."
end)
add("^Seen in (.+) on (.+)%.$", function(place, z)
    return "Vu à " .. Zone(place) .. " (" .. Zone(z) .. ")."
end)
add("^Quest reward in (.+) on (.+)%.$", function(place, z)
    return "Récompense de quête à " .. Zone(place) .. " (" .. Zone(z) .. ")."
end)
add("^Rank (%d+) behind (.+)%.$", function(n, what)
    return "Rang " .. n .. " derrière " .. Thing(what) .. "."
end)
add("^Rank (%d+) at ([%d–%-]+) behind (.+)%.$", function(n, lvl, what)
    return "Rang " .. n .. " au niveau " .. lvl .. ", derrière " .. Thing(what) .. "."
end)
add("^Requires level (%d+) to pick up%.$", function(n)
    return "Niveau " .. n .. " requis pour la prendre."
end)
add("^The quest requires level (%d+)%.$", function(n)
    return "La quête demande le niveau " .. n .. "."
end)
add("^Alliance: (.+) at (.+)%.$", function(who, where)
    return "Alliance : " .. Any(who) .. " (" .. Zone(where) .. ")."
end)
add("^Horde: (.+) at (.+)%.$", function(who, where)
    return "Horde : " .. Any(who) .. " (" .. Zone(where) .. ")."
end)
add("^Reward from '(.+)' %(Alliance%) or '(.+)' %(Horde%)%.$", function(a, b)
    return "Récompense de " .. Quest(a) .. " (Alliance) ou " .. Quest(b) .. " (Horde)."
end)
add("^You can buy the recipe from (.+) at the Durotar Supply and Logistics camp northwest of the Crossroads in The Barrens, or from (.+) at the Azeroth Commerce Authority camp at Three Corners in Redridge Mountains%.$", function(h, a)
    return "Recette vendue par " .. Any(h) .. " au camp de Durotar Supply and Logistics, au nord-ouest de la Croisée (" .. Zone("The Barrens")
        .. "), ou par " .. Any(a) .. " au camp de l'Azeroth Commerce Authority, aux Trois chemins (" .. Zone("Redridge Mountains") .. ")."
end)

-- Stat lists written by the pipeline: "+7 Intellect, +6 Stamina, +20 healing / +7 spell damage, 109 armor".
local STAT_WORDS = {
    ["healing"] = "soins", ["spell damage"] = "dégâts des sorts", ["spell power"] = "puissance des sorts",
    ["armor"] = "armure", ["Fire damage"] = "dégâts de Feu", ["Frost damage"] = "dégâts de Givre",
    ["Shadow damage"] = "dégâts d'Ombre", ["Arcane damage"] = "dégâts des Arcanes",
    ["Nature damage"] = "dégâts de Nature", ["Holy damage"] = "dégâts du Sacré",
    ["Spell Damage"] = "dégâts des sorts", ["Weapon Damage"] = "dégâts de l'arme",
    ["Defense"] = "Défense", ["Mana per 5 sec"] = "mana toutes les 5 s", ["Mana every 5 sec"] = "mana toutes les 5 s",
    ["Health every 5 sec"] = "vie toutes les 5 s",
    ["Fire Spell Power"] = "puissance des sorts de Feu", ["Frost Spell Power"] = "puissance des sorts de Givre",
    ["Shadow Spell Power"] = "puissance des sorts d'Ombre", ["Nature Spell Power"] = "puissance des sorts de Nature",
    ["Arcane Spell Power"] = "puissance des sorts des Arcanes", ["Holy Spell Power"] = "puissance des sorts du Sacré",
    ["Mana per 5"] = "mana toutes les 5 s", ["Spell Damage and Healing"] = "dégâts des sorts et soins",
    ["Holy Damage"] = "dégâts du Sacré", ["Healing"] = "soins", ["Spell Power"] = "puissance des sorts",
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
    return "Récompense de la quête " .. Quest(q) .. "."
end)

-- Item effects (proc text), worded like the French client's tooltips.
local SCHOOL = {
    Fire = "de Feu", Frost = "de Givre", Nature = "de Nature", Shadow = "d'Ombre",
    Arcane = "des Arcanes", Holy = "du Sacré", Physical = "physiques", Holyfire = "de Feu sacré",
    Holystorm = "de Tempête sacrée",
}
local function Dmg(amount, school)
    local kind = school and SCHOOL[school]
    if school and not kind then
        return nil
    end
    return amount .. " points de dégâts" .. (kind and (" " .. kind) or "")
end
local function Range(text)
    return (text:gsub(" to ", " à "))
end
local function Secs(n)
    return n .. " s"
end

add("^Chance on hit: (.+)$", function(rest)
    return "Chances quand vous touchez : " .. Rest(rest)
end)
add("^Equip: (.+)$", function(rest)
    return "Équipé : " .. Rest(rest)
end)
add("^Use: (.+)$", function(rest)
    return "Utiliser : " .. Rest(rest)
end)
add("^%(Proc chance: (%d+%%)%)$", function(p)
    return "(Chance de déclenchement : " .. p .. ")"
end)
add("^%(Proc chance: (%d+%%), (%d+)(m?s?) cooldown%)$", function(p, n, unit)
    local u = unit == "m" and " min" or unit == "ms" and " ms" or " s"
    return "(Chance de déclenchement : " .. p .. ", recharge " .. n .. u .. ")"
end)
add("^%((%d+)(m?s?) cooldown%)$", function(n, unit)
    local u = unit == "m" and " min" or unit == "ms" and " ms" or " s"
    return "(Recharge " .. n .. u .. ")"
end)
add("^%((%d+) Min Cooldown%)$", function(n)
    return "(Recharge " .. n .. " min)"
end)
add("^%((%d+) Hours? Cooldown%)$", function(n)
    return "(Recharge " .. n .. " h)"
end)
add("^%((%d+) Hrs Cooldown%)$", function(n)
    return "(Recharge " .. n .. " h)"
end)
add("^%((%d+) Min, (%d+) Sec Cooldown%)$", function(m, s)
    return "(Recharge " .. m .. " min " .. s .. " s)"
end)

add("^Improves your chance to hit by ([%d%.]+%%)%.$", function(p)
    return "Augmente vos chances de toucher de " .. p .. "."
end)
add("^Improves your chance to get a critical strike by ([%d%.]+%%)%.$", function(p)
    return "Augmente vos chances d'infliger un coup critique de " .. p .. "."
end)
add("^Increases your chance to Dodge an attack by ([%d%.]+%%)%.$", function(p)
    return "Augmente vos chances d'esquiver une attaque de " .. p .. "."
end)
add("^Increases your chance to Parry an attack by ([%d%.]+%%)%.$", function(p)
    return "Augmente vos chances de parer une attaque de " .. p .. "."
end)
add("^Increases your chance to Block attacks with a shield by ([%d%.]+%%)%.$", function(p)
    return "Augmente vos chances de bloquer les attaques avec un bouclier de " .. p .. "."
end)
add("^Reduces chance to be Dodged or Parried by ([%d%.]+%%)%.$", function(p)
    return "Réduit de " .. p .. " les chances que vos attaques soient esquivées ou parées."
end)
add("^Gives you a 50%% chance to avoid interruption caused by damage while casting (.+)%.$", function(spell)
    return "Vous donne 50 % de chances d'éviter les interruptions dues aux dégâts quand vous lancez " .. spell .. "."
end)

add("^Blasts a target for ([%d to]+) (%a+) damage%.$", function(n, school)
    local d = Dmg(Range(n), school)
    return d and ("Inflige " .. d .. " à une cible.")
end)
add("^Blasts up to (%d+) targets for ([%d to]+) (%a+) damage%.$", function(t, n, school)
    local d = Dmg(Range(n), school)
    return d and ("Inflige " .. d .. " à " .. t .. " cibles au maximum.")
end)
add("^Sends a shadowy bolt at the enemy,? causing ([%d to]+) Shadow damage%.$", function(n)
    return "Lance un trait d'ombre sur l'ennemi, qui subit " .. Dmg(Range(n), "Shadow") .. "."
end)
add("^Poisons target for (%d+) Nature damage every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Empoisonne la cible, qui subit " .. Dmg(n, "Nature") .. " toutes les " .. Secs(every) .. " pendant " .. Secs(dur) .. "."
end)
add("^Wounds the target causing them to bleed for (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Blesse la cible, qui saigne et subit " .. Dmg(n) .. " en " .. Secs(dur) .. "."
end)
add("^Wounds the target for ([%d to]+) damage%.$", function(n)
    return "Blesse la cible et lui inflige " .. Dmg(Range(n)) .. "."
end)
add("^Wounds the target for ([%d to]+) Physical damage%.$", function(n)
    return "Blesse la cible et lui inflige " .. Dmg(Range(n), "Physical") .. "."
end)
add("^Wounds the target for (%d+) damage and lowers their armor by (%d+)%.$", function(n, a)
    return "Blesse la cible, qui subit " .. Dmg(n) .. " et perd " .. a .. " points d'armure."
end)
add("^Hurls a fiery ball that causes ([%d to]+) Fire damage and an additional (%d+) damage over (%d+) sec%.$", function(n, extra, dur)
    return "Lance une boule de feu qui inflige " .. Dmg(Range(n), "Fire") .. ", plus " .. Dmg(extra) .. " en " .. Secs(dur) .. "."
end)
add("^Launches a bolt of frost at the enemy causing ([%d to]+) Frost damage and slowing movement speed by (%d+%%) for (%d+) sec%.$", function(n, p, dur)
    return "Lance un éclair de givre sur l'ennemi, qui subit " .. Dmg(Range(n), "Frost") .. " et voit sa vitesse de déplacement réduite de " .. p .. " pendant " .. Secs(dur) .. "."
end)
add("^Corrupts the target, causing (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Corrompt la cible, qui subit " .. Dmg(n) .. " en " .. Secs(dur) .. "."
end)
add("^Puncture the target, inflicting (%d+) Physical damage%.$", function(n)
    return "Perfore la cible et lui inflige " .. Dmg(n, "Physical") .. "."
end)
add("^Delivers a fatal wound for ([%d to]+) Physical damage%.$", function(n)
    return "Inflige une blessure mortelle de " .. Dmg(Range(n), "Physical") .. "."
end)
add("^Steals ([%d to]+) life from target enemy%.$", function(n)
    return "Dérobe " .. Range(n) .. " points de vie à l'ennemi ciblé."
end)
add("^Heals wielder of (%d+) damage%.$", function(n)
    return "Rend " .. n .. " points de vie au porteur."
end)
add("^Heals wielder of (%d+) damage over (%d+) sec%.$", function(n, dur)
    return "Rend " .. n .. " points de vie au porteur en " .. Secs(dur) .. "."
end)
add("^Stuns? target for ([%d%.]+) sec%.$", function(n)
    return "Étourdit la cible pendant " .. Secs(n) .. "."
end)
add("^Stun the target for ([%d%.]+) sec%.$", function(n)
    return "Étourdit la cible pendant " .. Secs(n) .. "."
end)
add("^Disarm target's weapon for (%d+) sec%.$", function(n)
    return "Désarme la cible pendant " .. Secs(n) .. "."
end)
add("^Reduces target enemy's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Réduit la puissance d'attaque de l'ennemi ciblé de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Reduces the target enemy's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Réduit la puissance d'attaque de l'ennemi ciblé de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Reduces target's attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Réduit la puissance d'attaque de la cible de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Grants a?n? ?1? ?extra attack on your next swing%.$", function()
    return "Confère une attaque supplémentaire lors de votre prochain coup."
end)
add("^Increases attack power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Augmente la puissance d'attaque de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Increases Attack Power by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Augmente la puissance d'attaque de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Increases armor by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Augmente l'armure de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Increases Spirit by (%d+) for (%d+) sec%.$", function(n, dur)
    return "Augmente l'Esprit de " .. n .. " pendant " .. Secs(dur) .. "."
end)
add("^Increases run speed by (%d+%%) for (%d+) sec%.$", function(p, dur)
    return "Augmente la vitesse de course de " .. p .. " pendant " .. Secs(dur) .. "."
end)
add("^Restores (%d+) mana%.$", function(n)
    return "Rend " .. n .. " points de mana."
end)
add("^Restores (%d+) to (%d+) mana%.$", function(a, b)
    return "Rend " .. a .. " à " .. b .. " points de mana."
end)
add("^Restores (%d+) health%.$", function(n)
    return "Rend " .. n .. " points de vie."
end)
add("^Restores (%d+) health every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Rend " .. n .. " points de vie toutes les " .. Secs(every) .. " pendant " .. Secs(dur) .. "."
end)
add("^Restores (%d+) mana every (%d+) sec for (%d+) sec%.$", function(n, every, dur)
    return "Rend " .. n .. " points de mana toutes les " .. Secs(every) .. " pendant " .. Secs(dur) .. "."
end)
add("^Restores (%d+) mana over (%d+) sec%.$", function(n, dur)
    return "Rend " .. n .. " points de mana en " .. Secs(dur) .. "."
end)
add("^Heal yourself for (%d+) to (%d+)%.$", function(a, b)
    return "Vous rend " .. a .. " à " .. b .. " points de vie."
end)
add("^Heal your target for (%d+) to (%d+)%.$", function(a, b)
    return "Rend " .. a .. " à " .. b .. " points de vie à votre cible."
end)
add("^Heal friendly target for (%d+) to (%d+)%.$", function(a, b)
    return "Rend " .. a .. " à " .. b .. " points de vie à une cible amie."
end)
add("^Absorbs (%d+) to (%d+) physical damage%. � Lasts (%d+) sec%.$", function(a, b, dur)
    return "Absorbe " .. a .. " à " .. b .. " points de dégâts physiques. Dure " .. Secs(dur) .. "."
end)
add("^Deals (%d+) times as much damage to (.+)%.$", function(n, who)
    return "Inflige " .. n .. " fois plus de dégâts aux " .. who .. "."
end)
add("^Deals 2x damage to (.+)%.$", function(who)
    return "Inflige deux fois plus de dégâts aux " .. who .. "."
end)
add("^Mechanical targets take 2x damage%.$", function()
    return "Les cibles mécaniques subissent deux fois plus de dégâts."
end)
add("^Must remain seated while drinking%.$", function()
    return "Vous devez rester assis pendant que vous buvez."
end)

-- Text the addon builds at display time (Data.lua, Log.lua).
add("^Costs (.+)%.$", function(rest)
    return "Coûte " .. rest .. "."
end)
add("^The (%a[%a ]-) pattern drops from (.+)%.$", function(prof, who)
    return "Le patron (" .. L[prof] .. ") est un butin " .. De(List(who)) .. "."
end)
add("^The (%a[%a ]-) pattern is dropped by (.+)%.$", function(prof, who)
    return "Le patron (" .. L[prof] .. ") est un butin " .. De(List(who)) .. "."
end)
add("^The (%a[%a ]-) pattern is the drop%.$", function(prof)
    return "Le butin est le patron (" .. L[prof] .. ")."
end)
