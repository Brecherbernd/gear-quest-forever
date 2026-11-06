"""Score every eligible item per class/spec/level/slot, take top 3, collapse to bands."""
import json, collections, re, sys, unicodedata, os
import procs as PROCS
import relic_score as RELIC

# One point of weapon DPS versus one point of Strength, for a paladin:
#   1 Strength = 2 attack power, which buys
#       white dps      2/14           = 0.143
#       seal dps       0.022 * 2      = 0.044   (Seal of Righteousness AP coefficient)
#       judgement dps  0.225 * 2 / 10 = 0.045   (10s cooldown)
#                                     = 0.232 dps
#   1 weapon DPS = 1.000 white dps
# so 1 weapon dps is worth 1/0.232 = 4.31 Strength, independent of weapon speed.
# The old hand-set dpsWeight of 1.75 for retribution was 2.5x too low, which let
# a rare with big crit rating (Blade of Misfortune, 68.8 dps) outrank the level-60
# PvP epics (Grand Marshal's Sunderer, 77.4 dps). Scaling by each spec's own
# Strength weight keeps the physics ratio intact inside that spec's scale.
DPS_PER_STR = 4.31

from gq_paths import G, GUIDES_DIR, OUT, forever_missing_ids, tbc_only_ids
FOREVER_MISSING = forever_missing_ids()
TBC_ONLY = tbc_only_ids()
NO_GUIDES = os.environ.get("GQ_NO_GUIDES") == "1"

# ilvl -> typical RequiredLevel, median over every item that states one.
ILVL_FLOOR = json.load(open(G+"ilvl_floor.json"))

items  = json.load(open(G+"items.json"))
# "Increases damage done by Shadow spells and effects by up to N" is the
# item's spell damage. Some rows kept that sentence on effects and never
# copied it into stats, so a +14 shadow circlet scored as stamina only.
_SCHOOL_EQUIP = re.compile(
    r"Increases damage done by (Shadow|Fire|Frost|Nature|Arcane|Holy) spells and effects by up to (\d+)"
)
for _it in items.values():
    _st = _it.get("stats")
    if not isinstance(_st, dict):
        continue
    for _school, _amt in _SCHOOL_EQUIP.findall(" ".join(_it.get("effects") or [])):
        _key = "sp" + _school
        if not _st.get(_key):
            _st[_key] = int(_amt)
rand   = json.load(open(G+"items_random.json"))
srcs   = json.load(open(G+"sources.json"))
W      = json.load(open(G+"weights.json"))

CLASS_BIT={"WARRIOR":1,"PALADIN":2,"HUNTER":4,"ROGUE":8,"PRIEST":16,"SHAMAN":64,
           "MAGE":128,"WARLOCK":256,"DRUID":1024}

# Wowhead Forever "Classes: Priest" (and multi-class lists). Item allowClass is
# often -1 on remakes, so the tooltip line is the lock.
TIP_CLASS_LOCK = {}
_TIPS_PATH = os.path.join(G, "forever_wowhead", "hunt_tooltips.json")
if os.path.exists(_TIPS_PATH):
    _tips = json.load(open(_TIPS_PATH, encoding="utf-8"))
    for _id, _row in _tips.items():
        tip = _row.get("tip") if isinstance(_row, dict) else _row
        if not tip:
            continue
        idx = tip.find("Classes:")
        if idx < 0:
            continue
        after = tip[idx + 8:].lstrip()
        names = []
        while after:
            hit = None
            for key in sorted(CLASS_BIT, key=len, reverse=True):
                title = key[:1] + key[1:].lower()
                if after.startswith(title) or after.upper().startswith(key):
                    rest = after[len(title):]
                    if rest == "" or rest[0] in ", " or rest[0].isupper():
                        names.append(key)
                        after = rest.lstrip(" ,")
                        hit = True
                        break
            if not hit:
                break
        if names:
            TIP_CLASS_LOCK[int(_id)] = set(names)

# Class dungeon/raid/ZG/AQ sets whose Forever remakes omit "Classes:" on some
# pieces (Deathmist Robe has no hunt tip; siblings say Classes: Warlock).
_CLASS_SET_PREFIX = [
    ("beaststalker", "HUNTER"), ("giantstalker", "HUNTER"), ("dragonstalker", "HUNTER"),
    ("cryptstalker", "HUNTER"), ("predator", "HUNTER"), ("striker", "HUNTER"),
    ("beastmaster", "HUNTER"),
    ("deathmist", "WARLOCK"), ("dreadmist", "WARLOCK"), ("felheart", "WARLOCK"),
    ("nemesis", "WARLOCK"), ("plagueheart", "WARLOCK"), ("demoniac", "WARLOCK"),
    ("doomcaller", "WARLOCK"),
    ("magister", "MAGE"), ("sorcerer", "MAGE"), ("arcanist", "MAGE"),
    ("netherwind", "MAGE"), ("frostfire", "MAGE"), ("illusionist", "MAGE"),
    ("enigma", "MAGE"),
    ("devout", "PRIEST"), ("virtuous", "PRIEST"), ("prophecy", "PRIEST"),
    ("transcendence", "PRIEST"), ("confessor", "PRIEST"),
    ("shadowcraft", "ROGUE"), ("darkmantle", "ROGUE"), ("nightslayer", "ROGUE"),
    ("bloodfang", "ROGUE"), ("bonescythe", "ROGUE"), ("madcap", "ROGUE"),
    ("deathdealer", "ROGUE"),
    ("wildheart", "DRUID"), ("feralheart", "DRUID"), ("cenarion", "DRUID"),
    ("stormrage", "DRUID"), ("dreamwalker", "DRUID"), ("haruspex", "DRUID"),
    ("genesis", "DRUID"),
    ("lightforge", "PALADIN"), ("soulforge", "PALADIN"), ("lawbringer", "PALADIN"),
    ("judgement", "PALADIN"), ("judgment", "PALADIN"), ("redemption", "PALADIN"),
    ("freethinker", "PALADIN"), ("avenger", "PALADIN"),
    ("earthfury", "SHAMAN"), ("earthshatter", "SHAMAN"), ("augur", "SHAMAN"),
    ("stormcaller", "SHAMAN"),
    ("dreadnaught", "WARRIOR"), ("vindicator", "WARRIOR"), ("conqueror", "WARRIOR"),
]
_CLASS_SET_PREFIX.sort(key=lambda kv: len(kv[0]), reverse=True)
_CLASS_SET_SUFFIX = [
    (" of the gathering storm", "SHAMAN"),
    (" of the earthshatterer", "SHAMAN"),
    (" of the five thunders", "SHAMAN"),
    (" of the ten storms", "SHAMAN"),
    (" of the unseen path", "HUNTER"),
    (" of the oracle", "PRIEST"),
    (" of elements", "SHAMAN"),
    (" of heroism", "WARRIOR"),
    (" of valor", "WARRIOR"),
    (" of faith", "PRIEST"),
    (" of might", "WARRIOR"),
    (" of wrath", "WARRIOR"),
]
_CLASS_SET_SUFFIX.sort(key=lambda kv: len(kv[0]), reverse=True)

def family_class_lock(name, ilvl=0):
    """Classic set names stay class-locked even when Forever omits Classes:."""
    if not name or (ilvl or 0) < 50:
        return None
    nm = name.lower()
    for prefix, cls in _CLASS_SET_PREFIX:
        if nm.startswith(prefix):
            return {cls}
    for suf, cls in _CLASS_SET_SUFFIX:
        if nm.endswith(suf):
            return {cls}
    return None

# BloodElf/Draenei bits stay so leftover TBC item masks still parse, but they are
# not playable in Forever and are absent from CLASS_RACES and the faction masks.
# Skyborne is on both factions; the bit is unused on Classic items (allowRace=-1
# on Wowhead Forever ingest). Wrong bit only hides Skyborne-only masks, if any.
RACE_BIT={"Human":1,"Orc":2,"Dwarf":4,"NightElf":8,"Undead":16,"Tauren":32,
          "Gnome":64,"Troll":128,"BloodElf":512,"Draenei":1024,"Skyborne":2048}
ALLIANCE=RACE_BIT["Human"]|RACE_BIT["Dwarf"]|RACE_BIT["NightElf"]|RACE_BIT["Gnome"]|RACE_BIT["Skyborne"]
HORDE   =RACE_BIT["Orc"]|RACE_BIT["Undead"]|RACE_BIT["Tauren"]|RACE_BIT["Troll"]|RACE_BIT["Skyborne"]
FACTION_MASK={"Alliance":ALLIANCE,"Horde":HORDE}

# Forever character-create matrix (no Draenei, no Blood Elf). Skyborne shaman is
# Horde-only; Skyborne mage is Alliance-only; Skyborne cannot be paladin/priest/warlock.
R=RACE_BIT
CLASS_RACES={
 "PALADIN":{"Alliance":R["Human"]|R["Dwarf"], "Horde":R["Undead"]},
 "WARRIOR":{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Gnome"]|R["Skyborne"],
            "Horde":R["Orc"]|R["Undead"]|R["Tauren"]|R["Troll"]|R["Skyborne"]},
 "HUNTER" :{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Skyborne"],
            "Horde":R["Orc"]|R["Tauren"]|R["Troll"]|R["Skyborne"]},
 "ROGUE"  :{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Gnome"]|R["Skyborne"],
            "Horde":R["Orc"]|R["Undead"]|R["Troll"]|R["Skyborne"]},
 "PRIEST" :{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Gnome"],
            "Horde":R["Undead"]|R["Troll"]},
 "SHAMAN" :{"Alliance":R["Dwarf"], "Horde":R["Orc"]|R["Tauren"]|R["Troll"]|R["Skyborne"]},
 "MAGE"   :{"Alliance":R["Human"]|R["Gnome"]|R["Skyborne"],
            "Horde":R["Undead"]|R["Troll"]|R["Orc"]},
 "WARLOCK":{"Alliance":R["Human"]|R["Gnome"], "Horde":R["Orc"]|R["Undead"]|R["Troll"]},
 "DRUID"  :{"Alliance":R["NightElf"]|R["Skyborne"], "Horde":R["Tauren"]|R["Skyborne"]},
}

# Faction-exclusive zones. The item and quest tables gate by race, but a vendor
# standing in Darnassus is not race-restricted -- the city is. Without this, a Blood
# Elf paladin's level 1-9 list was drawing on Darnassus, Northshire and Dun Morogh.
# Only the genuinely one-faction zones are listed; contested and Outland zones are
# reachable by both and stay absent.
ALLIANCE_ZONES={"Northshire Valley","Elwynn Forest","Dun Morogh","Coldridge Valley","Kharanos",
 "Teldrassil","Shadowglen","Darnassus","Ironforge","Stormwind City","Loch Modan","Westfall",
 "Darkshore","Redridge Mountains","Duskwood","Dustwallow Marsh - Theramore",
 "Nesingwary's Expedition","Feathermoon Stronghold",
 "Nijel's Point","Refuge Pointe","Sentinel Hill","Lakeshire","Darkshire","Menethil Harbour",
 "Menethil Harbor","Southshore","Chillwind Camp","Booty Bay - Alliance","Astranaar",
 "Auberdine","Talrendis Point","Silverwind Refuge","Forest Song","Theramore Isle"}
HORDE_ZONES={"Valley of Trials","Durotar","Razor Hill","Orgrimmar","Mulgore","Camp Narache",
 "Thunder Bluff","Deathknell","Tirisfal Glades","Brill","Undercity","Silverpine Forest",
 "Sen'jin Village","The Barrens",
 "Camp Mojache","Hammerfall","Kargath",
 "Stonard","Grom'gol Base Camp","Brackenwall Village","Splintertree Post","Zoram'gar Outpost",
 "Valormok","Crossroads","Taurajo"}
# TBC race hubs and Outland towns do not exist in Forever. Deny both factions so
# leftover item zones cannot leak after those names left the faction lists.
# Zephras Isle is the shared Skyborne start and stays unlisted (reachable by both).
GONE_ZONES={"Azuremyst Isle","Bloodmyst Isle","The Exodar","Ammen Vale",
 "Eversong Woods","Sunstrider Isle","Ghostlands","Silvermoon City","Tranquillien",
 "Honor Hold","Telaar","Temple of Telhamat","Wildhammer Stronghold","Sylvanaar",
 "Toshley's Station","Allerian Stronghold",
 "Thrallmar","Garadar","Falcon Watch","Shadowmoon Village","Zabra'jin",
 "Thunderlord Stronghold","Mok'Nathal Village"}
# Faction-exclusive REPUTATIONS. A whole gate class that was missing: Batskin Belt
# requires "Tranquillien - Honored", Tranquillien is the Horde hub in the Blood Elf
# Ghostlands, and an Alliance paladin can never earn it -- but the item's allowRace is
# -1 and its zone string is the sub-zone "Tranquillien", which the zone list did not
# have. Same shape as R8 and R20: the restriction is one join away from the item row.
#
# Which reputations are exclusive is DERIVED by the mirror rule (R24): for each
# reputation, its best partner by shared (slot, ilvl, kind) keys, accepted only when
# the pairing is mutual and clearly ahead of the runner-up. That isolates exactly two
# pairs out of 20 reputations -- Honor Hold <-> Thrallmar at 16 mirrored keys against a
# next-best of 8, and Kurenai <-> The Mag'har at 5 with no closer partner. Every other
# Outland reputation is genuinely shared by both factions, which is why it has no
# strong mirror. Tranquillien has no mirror at all: it is a Horde levelling hub with no
# Alliance counterpart.
#
# The one hand-verified input is which SIDE each of the five is on -- five names, each
# checkable at a glance, exactly like the PvP quartermaster seed in pvp_prefix_faction.
REP_FACTION={
 "Honor Hold":"Alliance", "Kurenai":"Alliance",
 "Thrallmar":"Horde", "The Mag'har":"Horde", "Tranquillien":"Horde",
 # Battleground and Forever faction vendors. The other side cannot earn these,
 # so the piece must not show up as something they can buy.
 "The League of Arathor":"Alliance", "Stormpike Guard":"Alliance",
 "Silverwing Sentinels":"Alliance", "The Watchers":"Alliance",
 "Theramore Expeditionary Force":"Alliance",
 "The Defilers":"Horde", "Frostwolf Clan":"Horde",
 "Warsong Outriders":"Horde", "Darkspear Raiders":"Horde",
}
# Vendor-based faction gate. Better than the zone whenever a camp hosts BOTH sides'
# quartermasters -- "Mor'shan Base Camp" holds Illiyana Moonblaze (Alliance) and Kelm
# Hargunth (Horde), so putting that zone in a faction list gated Sentinel's Medallion
# out of Alliance AND out of Horde, leaving it nowhere. Derived, not asserted: a vendor
# is claimed for a side only when its entire prefix-identified stock is that side and
# there are at least three such items. 14 vendors qualify; none stock both sides.
#
# Caretaker's Cape is Alliance while Battle Healer's Cloak is Horde -- those are
# faction pairs sold by Illiyana vs Kelm. Rune of Duty (21567/21568) and Rune of
# Perfection (21565/21566) are the SAME item IDs on both sides; both quartermasters
# sell them. sources.json must not pin npc to Illiyana or npc_ok gates Horde out of
# the only trinkets available at 20-27.
NPC_FACTION=json.load(open(G+"npc_faction.json"))
def npc_ok(src, faction):
    side=NPC_FACTION.get(src.get("npc") or "")
    return side is None or side==faction

# A vendor item belongs to one faction only when every Wowhead seller is that
# faction. A neutral seller, or one seller on each side, stays on both lists.
# Anachronos is left out of this file: both factions turn quests in to him.
_VENDOR_SIDE_PATH = os.path.join(G, "vendor_side.json")
VENDOR_SIDE = {}
if os.path.exists(_VENDOR_SIDE_PATH):
    VENDOR_SIDE = {int(k): v for k, v in json.load(open(_VENDOR_SIDE_PATH, encoding="utf-8")).items()}

def vendor_side_ok(it, faction):
    side = VENDOR_SIDE.get(it["id"])
    return side is None or side == faction

# Wowhead react is [Alliance, Horde]. 1 is friendly, -1 is hostile. A dropper
# who is friendly to one faction and hostile to the other can only be looted
# by the side that can attack them. Dun Garok Rifle is the same keep: Tamra
# Stormpike is friendly to the Alliance, so the rifle is Horde only.
_DROP_FACTION_PATH = os.path.join(G, "drop_faction.json")
DROP_FACTION = {}
if os.path.exists(_DROP_FACTION_PATH):
    DROP_FACTION = {int(k): v for k, v in json.load(open(_DROP_FACTION_PATH, encoding="utf-8")).items()}

def drop_side_ok(it, faction):
    side = DROP_FACTION.get(it["id"])
    return side is None or side == faction

# Wowhead Side: Alliance / Side: Horde. Side: Both is absent, so both factions score it.
# Written by index_coordinates.py --repair-quests.
_QUEST_FACTION_PATH = os.path.join(G, "quest_faction.json")
QUEST_FACTION = {}
if os.path.exists(_QUEST_FACTION_PATH):
    QUEST_FACTION = {int(k): v for k, v in json.load(open(_QUEST_FACTION_PATH, encoding="utf-8")).items()}

def quest_side_ok(it, faction):
    side = QUEST_FACTION.get(it["id"])
    return side is None or side == faction

def rep_ok(it, faction):
    for r in (it.get("reqRep") or []):
        side=REP_FACTION.get(r[0] if isinstance(r,(list,tuple)) else r)
        if side and side!=faction: return False
    return True

def zone_ok(zone, faction):
    if not zone: return True
    if zone in GONE_ZONES: return False
    if faction=="Horde"    and zone in ALLIANCE_ZONES: return False
    if faction=="Alliance" and zone in HORDE_ZONES:    return False
    return True

# armour proficiency: (allowed kinds, level at which the heaviest unlocks)
ARMOR_PROF={
 "WARRIOR":{"Cloth":1,"Leather":1,"Mail":1,"Plate":40,"Shield":1,"Buckler":1,"Misc":1},
 "PALADIN":{"Cloth":1,"Leather":1,"Mail":1,"Plate":40,"Shield":1,"Buckler":1,"Misc":1,"Libram":1},
 "HUNTER" :{"Cloth":1,"Leather":1,"Mail":40,"Misc":1},
 "SHAMAN" :{"Cloth":1,"Leather":1,"Mail":40,"Shield":1,"Buckler":1,"Misc":1,"Totem":1},
 "ROGUE"  :{"Cloth":1,"Leather":1,"Misc":1},
 "DRUID"  :{"Cloth":1,"Leather":1,"Misc":1,"Idol":1},
 "PRIEST" :{"Cloth":1,"Misc":1},
 "MAGE"   :{"Cloth":1,"Misc":1},
 "WARLOCK":{"Cloth":1,"Misc":1},
}
AC_SLOTS={"Head","Shoulder","Chest","Wrist","Hands","Waist","Legs","Feet"}
# Level at which the class learns Dual Wield. None = never. Without this gate any
# off-hand-only weapon (InventoryType 22) was a legal off-hand pick from its own
# RequiredLevel -- Left-Handed Brass Knuckles, RequiredLevel 10, sat at rank 1 in a
# level-10 warrior's off hand, ten levels before the character can equip it.
# Dual Wield. None = never. Forever Enhancement has no dual-wield talent and can
# equip 2H without one; shaman off-hand weapons are never legal. Hunter still
# learns Dual Wield at 20 (class trainer).
DUAL_WIELD_LEVEL={"WARRIOR":20,"ROGUE":10,"HUNTER":20}
def dual_wield_level(cls, spec):
    v=DUAL_WIELD_LEVEL.get(cls)
    if isinstance(v,dict): return v.get(spec)
    return v

ARMOR_SLOTS=["Head","Neck","Shoulder","Back","Chest","Wrist","Hands","Waist","Legs","Feet","Finger","Trinket"]
RATING_KEYS={"hit","crit","haste","expertise","defense","dodge","parry","blockRating",
             "resilience","spellHit","spellCrit","spellHaste","hitRanged","critRanged"}
SPELL_OFFENSE_KEYS=("sp","spSchool","spHoly","heal","sp_from_heal","damageDone",
                    "spShadow","spFire","spFrost","spNature","spArcane")
PHYS_OFFENSE_KEYS=("str","agi","ap","rap","feralAp")
TANK_SKILL_KEYS=("defense","dodge","parry","blockRating","blockValue")

def spec_uses_spell_power(w):
    return max((w.get(k, 0) or 0) for k in SPELL_OFFENSE_KEYS) >= 0.05

def item_is_spell_gear(it):
    """Caster gloves (SP/heal, no str/agi/ap) are not warrior-tank BiS."""
    st = forever_stats(it.get("stats") or {})
    spell = sum((st.get(k, 0) or 0) for k in SPELL_OFFENSE_KEYS)
    spell += st.get("damageDone") or 0
    phys = sum((st.get(k, 0) or 0) for k in PHYS_OFFENSE_KEYS)
    return spell > 0 and phys <= 0

def item_is_heal_only(it):
    """Healing with no spell damage. A DPS caster should not hunt these."""
    st = it.get("stats") or {}
    if (st.get("heal") or 0) <= 0:
        return False
    for k in ("sp", "damageDone", "spFire", "spFrost", "spNature", "spArcane", "spShadow", "spHoly"):
        if st.get(k):
            return False
    return True

HEALER_SPECS = {
    ("PALADIN", "holy"),
    ("DRUID", "restoration"),
    ("SHAMAN", "restoration"),
    ("PRIEST", "holy"),
    ("PRIEST", "discipline"),
}

def spec_wants_heal(cls, spec_key):
    # Healing Done is a healer stat. Damage specs, including Balance and Shadow,
    # score Damage Done (folded into spell power) and do not treat +healing as power.
    return (cls, spec_key) in HEALER_SPECS

def item_tank_skill_note(it):
    st = it.get("stats") or {}
    notes = []
    for k, lab in (("defense", "Defense"), ("dodge", "Dodge"), ("parry", "Parry"),
                   ("blockRating", "Block"), ("blockValue", "Block Value")):
        v = st.get(k) or 0
        if v:
            n = int(v) if float(v) == int(v) else v
            notes.append("+%s %s" % (n, lab))
    return notes

def slot_for(it, cls):
    s=it["slot"]
    if s in ARMOR_SLOTS: return s
    if s in ("OneHand","TwoHand","MainHand"): return "MainHand"
    if s in ("OffHand","Held","Shield"): return "SecondaryHand"
    if s in ("Ranged","Thrown"): return "Ranged"
    if s=="Relic": return "Ranged"
    return None

def eff_req(it):
    """The level at which this item becomes eligible: its own RequiredLevel. Nothing else.

    This used to add an obtainability gate on top -- for a BoP item, the level of
    the creature that drops it, minus two. The intent was "you cannot realistically
    kill a level 63 boss at 55", but it was wrong twice over. It contradicted the
    ranking policy, which is pure stat score regardless of how gettable something
    is; and it silently delayed 3,748 BoP items past the level Wowhead says they
    are usable from. Might of Menethil (Requires Level 60, dropped by a level 63
    Kel'Thuzad) vanished from level 60 and reappeared at 61, which is exactly the
    discontinuity Henrik spotted at the 60/61 boundary.

    The fix is narrow on purpose. When an item states a RequiredLevel, that number
    is authoritative and nothing may push it later. But 1,400-odd items -- mostly
    quest rewards and raid epics -- carry RequiredLevel 0 in this DB, which does not
    mean "usable at level 1"; it means no requirement was recorded and something
    else does the gating. For those, and only those, the source gate still stands.
    Dropping it for everything made every level-1 band pick raid epics.

    Requirements that gate *obtaining* an item -- boss level, profession skill,
    reputation -- still travel with the pick as `src`, `reqSkills` and `reqRep`, so
    the addon can show them. For an item with a stated RequiredLevel they no longer
    move it to a later level."""
    r=it["rlvl"]
    if r>0:
        return r
    # No stated requirement. Wowhead agrees these are genuinely unrestricted --
    # 1,369 items of item level 60+ have no "Requires Level" line at all -- so a
    # level 1 character really could equip one if handed it. But most are Binds
    # when Picked Up, so the only real gate is reaching the source, and taking the
    # stated 0 at face value put an item level 55 chest (Hakkari Breastplate) at
    # rank 1 for level 1. Fall back to the source gate, backstopped by the typical
    # RequiredLevel of items at that item level -- the median over the ~28.5k items
    # that do state one, so it is measured rather than picked.
    return max(srcs[str(it["id"])].get("gateLevel") or 0, ILVL_FLOOR.get(str(it["ilvl"]), 0))

# PvP rank rewards are faction-exclusive, but the gate is the quartermaster, not the
# item: every one of these carries AllowableRace = -1, so Field Marshal's Plate Helm
# and Warlord's Plate Headpiece both sat in both factions' level-60 lists. Same shape
# as the class lock living on the quest (R8) -- the restriction is one join away from
# the item row.
#
# The side of each name family is DERIVED, not remembered: for every rank-set prefix,
# look at which quartermaster the world DB says sells it. A prefix is gated only when
# every vendor row for it is on one side. "Sergeant's" has items on both and is left
# ungated; "Knight's", "Commander's", "Corporal's" and "Senior Sergeant's" have no
# vendor row at all and are also left ungated. See pvp_prefix_faction.json.
PVP_PREFIX = json.load(open(G+"pvp_prefix_faction.json"))
_PVP_ORDER = sorted(PVP_PREFIX, key=len, reverse=True)
def pvp_side(name):
    # Premier is the Forever name in front of the same rank title.
    if name.startswith("Premier "):
        name = name[8:]
    for p in _PVP_ORDER:
        if name.startswith(p): return PVP_PREFIX[p]
    return None

# Rune Broker stock is split by faction (see ingest_forever_wowhead.py).
RUNE_BROKER_ALLIANCE = {205420, 208849, 208851, 211472}
RUNE_BROKER_HORDE = {206381, 206382, 206386, 206387, 206388, 225838}

def eligible(it, cls, spec, level, faction, prof, wsubs):
    src=srcs[str(it["id"])]
    if not src["obtainable"]: return False
    if it.get("temporary"): return False        # conjured / duration-limited, not gear
    nm=(it.get("name") or "").lower()
    if "test copy" in nm or "animation as" in nm:
        return False
    if eff_req(it)>level: return False
    ac=it["allowClass"]
    if ac not in (-1,0) and not (ac & CLASS_BIT[cls]): return False
    # Forever remakes often have AllowableClass -1, but the tooltip says
    # "Classes: Priest". Virtuous Robe must not score for mage/warlock.
    locked=family_class_lock(it.get("name"), it.get("ilvl") or 0)
    if not locked:
        locked=TIP_CLASS_LOCK.get(it["id"])
    if not locked:
        locked=set()
        for n in (it.get("tipClasses") or []):
            if CLASS_BIT.get(str(n).upper()):
                locked.add(str(n).upper())
    if locked and cls not in locked: return False
    # Class lock carried by the quest that grants the item, not by the item itself.
    # Vanilla tier-3 pieces have AllowableClass 32767 ("anyone") but each is handed
    # over by a class-locked quest, so without this a paladin's list happily picked
    # Warrior, Druid, Hunter, Rogue, Priest and Shaman tier 3.
    qc=src.get("questClasses") or 0
    if qc and not (qc & CLASS_BIT[cls]): return False
    ar=it["allowRace"]
    mask=(CLASS_RACES.get(cls) or {}).get(faction, FACTION_MASK[faction])
    if ar not in (-1,0) and not (ar & mask): return False
    qr=src.get("questRaces") or 0
    if qr and not (qr & mask): return False          # captured all along, never used
    # An open-world rare keeps its pin in whichever zone it patrols, even when
    # that zone is the other faction's leveling territory (Rohh in Redridge).
    # zoneOpen is a world drop that was listed under a subzone name (Tower of
    # Ilgalar). The label is now the parent zone, and the drop stays listed.
    if src.get("zone") in GONE_ZONES:
        return False
    if (src.get("sourceType") != "rare_npc" and not src.get("zoneOpen")
            and not zone_ok(src.get("zone"), faction)):
        return False
    if not quest_side_ok(it, faction): return False
    if not drop_side_ok(it, faction): return False
    iid = it["id"]
    if iid in RUNE_BROKER_ALLIANCE and faction != "Alliance": return False
    if iid in RUNE_BROKER_HORDE and faction != "Horde": return False
    side=pvp_side(it["name"])
    if side and side!=faction: return False
    if not rep_ok(it, faction): return False
    if not npc_ok(src, faction): return False
    if not vendor_side_ok(it, faction): return False
    if it["cls"]==4:                                     # armour / shield / relic
        need=prof.get(it["kind"])
        if need is None or level<need: return False
    else:                                                # weapon
        if it["kind"] not in wsubs: return False
    return True

# A stat that only applies against one creature type is not that stat. "Increases
# attack power by 60 when fighting Undead" was parsed as a flat +60 AP, which put
# Gauntlets of Undead Slaying at rank 1 on Hands at level 59 for both DPS specs --
# ahead of a guaranteed epic -- on a bonus that is zero against most of what you
# fight while levelling. Counted at a third, and the condition stays in the
# instruction text so the player can judge it. 41 items carry one.
CONDITIONAL_SHARE = 1/3.0

# A relic's effect names the ABILITY it buffs, and abilities belong to specs. Without
# this, ilvl ordering alone handed every paladin spec the same three healing librams
# and gave a Balance druid healing idols. Keywords are read off the effect text itself
# ("Increases healing done by Flash of Light", "Increases the damage of your Claw and
# Rake abilites"), not invented. A relic naming an ability the spec does not have is
# not eligible for that spec; one naming nothing recognised is kept, which is the
# conservative direction.
RELIC_ABILITIES={
 "PALADIN":{
   "holy":["Flash of Light","Holy Light","Cleanse","Blessing of Light","Holy Shock","Holy Strike"],
   "protection":["Holy Shield","Devotion Aura","block","Consecration","Judgement","Judgment",
                 "Seal of Fury","Holy Strike"],
   "retribution":["Seal","Judgement","Judgment","Holy Strike","Exorcism","Holy Wrath",
                  "Consecration"],
   "shockadin":["Holy Shock","Exorcism","Holy Wrath","Consecration","Seal",
                "Judgement","Judgment","Holy Strike"]},
 "DRUID":{
   "restoration":["Rejuvenation","Healing Touch","Lifebloom","Regrowth","Tree of Life"],
   "feral":["Claw","Rake","Shred","Rip","Mangle","combo point","finishing move"],
   "bear":["Maul","Swipe","Lacerate","Mangle"],
   "balance":["Moonfire","Starfire","Wrath"]},
 "SHAMAN":{
   "restoration":["Lesser Healing Wave","Healing Wave","Chain Heal","Water Shield","Riptide"],
   "elemental":["Lightning Bolt","Chain Lightning","Earth Shock","Flame Shock","Frost Shock",
                "Shock"],
   "enhancement":["Stormstrike","Windfury","Shock","Lightning Bolt","Maelstrom"],
   "enhancement_tank":["Rockbiter","Stormstrike","Shock","Earth Shock","Flame Shock",
                      "Frost Shock","Lightning Shield"]},
}
def relic_ok(it, cls, spec):
    """True if this relic's effect names an ability the spec actually uses."""
    tbl=RELIC_ABILITIES.get(cls)
    if not tbl or spec not in tbl: return True
    text=" ".join(it.get("effects") or [])
    if not text: return True
    mine=[k for k in tbl[spec] if k.lower() in text.lower()]
    if mine: return True
    every=set()
    for v in tbl.values(): every.update(v)
    return not any(k.lower() in text.lower() for k in every)   # names nothing -> keep

STAT_LABEL={"sta":"Stamina","int":"Intellect","str":"Strength","agi":"Agility",
 "spi":"Spirit","ap":"Attack Power","heal":"Healing","sp":"Spell Damage and Healing",
 "sp_from_heal":"Spell Damage","spSchool":"Spell Damage","spHoly":"Holy Damage",
 "crit":"Crit","spellCrit":"Crit","hit":"Hit","haste":"Haste",
 "defense":"Defense","dodge":"Dodge","blockRating":"Block",
 "mp5":"Mana per 5","resArcane":"Arcane Resist","resNature":"Nature Resist",
 "resFire":"Fire Resist","resFrost":"Frost Resist","resShadow":"Shadow Resist"}
def fmt_range(lo,hi):
    """'+11-13 Healing, +4-5 Spell Damage' -- what the roll can actually come out as,
    so the addon shows the range rather than implying the jackpot."""
    parts=[]
    for k,h in sorted(hi.items(), key=lambda kv:-kv[1]):
        l=lo.get(k,h)
        lbl=STAT_LABEL.get(k,k)
        parts.append("+%d %s"%(h,lbl) if l==h else "+%d-%d %s"%(l,h,lbl))
    return ", ".join(parts)

ROLL_POLICY="bestRoll"       # bestRoll | expectedValue | chanceFloor
CHANCE_FLOOR=1.0             # used by chanceFloor policy (% for the whole suffix family)

# Leveling is not raid min-max. Through 60, same as 1-59:
#   survivability -- sta / health / hp5 x3, armor x2
#   endurance     -- int / spi / mp5 / mana x2 (keep casting; less than stam)
# A +1 primary-stat stick with no stam/mana cannot beat a real leveling chest.
# Level 60 used to drop back to the raw raid weights. That let Frenzied
# Striker (a hit stick) outrank Grand Marshal's Polearm. Hit, crit, parry,
# dodge, and weapon damage stay on the raw weights at every level.
LEVELING_SURVIVE_UNTIL = 61
LEVELING_STA_MULT = 3.0
LEVELING_HEALTH_MULT = 3.0
LEVELING_HP5_MULT = 3.0
LEVELING_ARMOR_MULT = 2.0
LEVELING_ENDURANCE_MULT = 2.0

def weights_at_level(base_w, level):
    if level >= LEVELING_SURVIVE_UNTIL:
        return base_w
    w = dict(base_w)
    w["sta"] = w.get("sta", 0.0) * LEVELING_STA_MULT
    w["health"] = w.get("health", 0.0) * LEVELING_HEALTH_MULT
    w["hp5"] = w.get("hp5", 0.0) * LEVELING_HP5_MULT
    w["armor"] = w.get("armor", 0.0) * LEVELING_ARMOR_MULT
    w["int"] = w.get("int", 0.0) * LEVELING_ENDURANCE_MULT
    w["spi"] = w.get("spi", 0.0) * LEVELING_ENDURANCE_MULT
    w["mp5"] = w.get("mp5", 0.0) * LEVELING_ENDURANCE_MULT
    w["mana"] = w.get("mana", 0.0) * LEVELING_ENDURANCE_MULT
    return w

# Forever combat: one Hit, one Crit, one Haste. TBC leftover keys on classic
# item rows fold in. Expertise / armor pen / resilience do not exist.
# Heal-only tooltips still grant SP at 1/3 (Blizzard rule); combined
# "healing + damage" lines already carry sp_from_heal -- take the larger.
UNIFIED_STAT={"spellHit":"hit","hitRanged":"hit",
              "spellCrit":"crit","critRanged":"crit",
              "spellHaste":"haste"}
DEAD_STATS=("expertise","armorPen","resilience")

def forever_stats(st):
    out=dict(st or {})
    for src,dst in UNIFIED_STAT.items():
        if src in out:
            out[dst]=out.get(dst,0)+out[src]
            out[src]=0
    for k in DEAD_STATS:
        if k in out:
            out[k]=0
    # Damage Done (rtg 42) is spell damage only. Fold into sp for scoring so
    # casters value it like Spell Power. Healers still get `heal` separately.
    dmg = out.get("damageDone") or 0
    if dmg:
        out["sp"] = (out.get("sp") or 0) + dmg
        # sc() runs forever_stats again. Leaving damageDone in place counted it twice.
        out["damageDone"] = 0
    heal = out.get("heal") or 0
    # Heal-only items grant 1/3 SP. A piece that already has Damage Done does not
    # also convert its Healing Done; that number is for healers.
    explicit_sp = out.get("sp") or 0
    if heal and explicit_sp == 0:
        out["sp_from_heal"] = max(out.get("sp_from_heal") or 0, heal / 3.0)
    return out

# Forever tooltips say "by N%". A few items stored that percent on the old
# rating scale (2% hit -> 20, 1% crit -> 14, 1% dodge -> 12, 1% parry -> 15)
# and the other thousand did not. Frenzied Striker's stored 20 hit is that
# conversion, and it outranked Grand Marshal's Polearm. At 60, drop a stored
# hit/crit/dodge/parry when it is exactly that conversion. Do not invent the
# rating on the items that never had it. A Chance on hit, a spell-specific
# crit, and a line that reduces the chance to be dodged are not touched.
_PCT_PER = {"hit": 10.0, "crit": 14.0, "dodge": 12.0, "parry": 15.0}

def _percent_rating(line):
    low = line.lower()
    if not low.startswith("equip:"):
        return None
    if low.startswith("equip: improves your chance to get a critical strike"):
        key = "crit"
    elif low.startswith("equip: improves your chance to hit by"):
        key = "hit"
    elif low.startswith("equip: increases your chance to dodge an attack"):
        key = "dodge"
    elif low.startswith("equip: increases your chance to parry an attack"):
        key = "parry"
    else:
        return None
    m = re.search(r"by ([\d.]+)%", line)
    if not m:
        return None
    return key, float(m.group(1)) * _PCT_PER[key]

def _level60_stats(it, level):
    """Stats the level-60 score uses. 1-59 keeps the stored row."""
    base = forever_stats(it.get("stats") or {})
    if level < 60:
        return base
    effects = it.get("effects") or []
    equip = "\n".join(e for e in effects if e.lower().startswith("equip:")).lower()
    for line in effects:
        low = line.lower()
        if not low.startswith("use:"):
            continue
        # Earthstrike stores the on-use 280 attack power as a passive stat
        # and the proc model prices the use again. A Use amount with no Equip
        # line is not a passive.
        m = re.search(r"attack power by (\d+)", low)
        if m and "attack power" not in equip:
            if base.get("ap", 0) <= float(m.group(1)) + 0.01:
                base["ap"] = 0
    for line in effects:
        got = _percent_rating(line)
        if not got:
            continue
        key, pts = got
        if abs(base.get(key, 0) - pts) < 0.6:
            base[key] = 0
    return base

def best_variant(it, w, level, rscale):
    """-> (score, suffixName or None, chance or None, statsUsed)

    No level scaling on rating stats. Ratings do buy more percent at low level,
    but the relative value of a primary stat point rises even faster there (base
    weapon damage and attack power are tiny), so scaling only ratings made them
    wildly overvalued below 60. Keeping every weight level-invariant is both
    simpler and closer to the truth.
    """
    base=_level60_stats(it, level)
    def sc(st):
        t=0.0
        for k,v in forever_stats(st).items():
            wt=w.get(k,0.0)
            if not wt: continue
            t+= v*wt
        return t
    bs=sc(base)
    vs=rand.get(str(it["id"]))
    if not vs: return bs, None, None, base, None, bs, None, None
    if ROLL_POLICY=="expectedValue":
        ev=bs; tot=0.0
        for v in vs:
            merged=dict(base)
            for k,x in v["stats"].items(): merged[k]=merged.get(k,0)+x
            merged=forever_stats(merged)
            ev+= (sc(merged)-bs)*v["chance"]/100.0; tot+=v["chance"]
        return ev, "<random roll>", round(tot,2), base, round(tot,2), ev, None, None
    # RANK and DISPLAY the jackpot (top of the winning suffix range).
    #
    # A green "of Agility" that can roll +7 Agi (~9.5%) is BiS if that roll lands.
    # Expected-value ranking hid it at ~2.68 while the hunt name still said of Agility
    # -- the player never saw the real #1. Slim odds stay on the row as suffixChance;
    # they do not bury the item. Each suffix is itself a RANGE: hunt target and rank
    # both use the TOP of that range ("+6-7 Agility" -> +7).
    best=None
    for v in vs:
        if ROLL_POLICY=="chanceFloor" and (v.get("chanceAny") or 0)<CHANCE_FLOOR: continue
        hi=v["stats"]; lo=v.get("statsMin") or hi
        mHi=dict(base)
        for k,x in hi.items():  mHi[k]=mHi.get(k,0)+x
        mHi=forever_stats(mHi)
        s2=sc(mHi)
        if best is None or s2>best[0]: best=(s2,v["suffix"],v["chance"],mHi,v.get("chanceAny"),lo,hi,v.get("suffixId"))
    if not best or best[0]<=bs: return bs, None, None, base, None, bs, None, None
    # score = jackpot; suffix/chance/stats = that same roll; 6th = jackpot again
    # (legacy notable-shelf slot; gain is now zero because rank == display);
    # 7th = the printable range, so the addon shows "+6-7 Agility" not just "7".
    return best[0], best[1], best[2], best[3], best[4], best[0], fmt_range(best[5],best[6]), best[7]

# ---------------------------------------------------------------------------
# Obtainability exclusions. Built by obtainability.py, which traces each item's
# acquisition chain in the world DB and reports dead ends. Two tiers:
#
#   AUTO -- items whose ONLY source is a quest titled "BETA ..." / "TEST ...".
#           Unambiguous test content; excluded without review.
#   HAND -- craft dead ends (a pattern item exists but drops from nothing). This
#           rule is right but not perfectly reliable, because npc_vendor and
#           npc_trainer in this DB are incomplete. Every one is checked against
#           Wowhead before being added here.
#
# Verified against Wowhead, kept OUT:
#   15141 Onyxia Scale Breastplate  -- "This item is not available to players"
#    6730 Ironforge Chain           -- "the actual recipe ... is no longer available"
#    2867 Rough Bronze Bracers      -- "no way to make or find this item. A way to
#                                       learn the recipe was never made"
# Verified against Wowhead, kept IN (do NOT add):
#    7929 Orcish War Leggings       -- plans come from the Horde quest "The Old Ways"
#                                       in Orgrimmar; this world DB is missing that
#                                       quest reward, so the audit flagged it wrongly.
#   10020 Stormcloth Vest           -- inconclusive; only player speculation. Left in
#                                       and surfaced in the review page instead.
HAND_EXCLUDED={15141, 6730, 2867}
# Forever lists these, but they are spells rather than gear you can hunt.
# 280304 Invisible Dagger is spell 1308095, a hidden dummy aura.
SPELL_NOT_GEAR={280304}

def hidden_spell_item(it):
    """A hidden spell or an unused placeholder. Not gear a player can hunt."""
    if not it:
        return False
    if it.get("id") in SPELL_NOT_GEAR:
        return True
    name = it.get("name") or ""
    if name.startswith("UNUSED") or name.startswith("[UNUSED]"):
        return True
    if "(DNT)" in name or "[DNT]" in name:
        return True
    if name in ("Placeholder", "Invisible Dagger"):
        return True
    return False

# The Weapons list (main hand and off hand together) keeps this many names
# per level band. Lower scores stay in items.json and can return if weights change.
WEAPON_LIST_CAP=30

def load_exclusions():
    try: ob=json.load(open("obtainability.json"))
    except FileNotFoundError:
        print("  !! obtainability.json missing -- NO exclusions applied"); return set(), {}
    auto={int(k) for k in ob.get("questDeadEnd",{})}
    reasons={}
    for k,v in ob.get("questDeadEnd",{}).items(): reasons[int(k)]=v
    for i in HAND_EXCLUDED: reasons.setdefault(i,"verified unobtainable on Wowhead")
    ex=auto|HAND_EXCLUDED
    # never exclude something that also has a real source
    reach=ob.get("sources",{})
    ex={i for i in ex if str(i) not in reach or i in HAND_EXCLUDED}
    flagged={int(k):v for k,v in ob.get("craftDeadEnd",{}).items() if int(k) not in ex}
    print(f"  obtainability: excluding {len(ex)} items ({len(auto)} test-quest, {len(HAND_EXCLUDED)} hand-verified); "
          f"{len(flagged)} craft dead-ends flagged for review, not removed")
    return ex, flagged

EXCLUDED, FLAGGED = load_exclusions()

def slug(s):
    s=unicodedata.normalize("NFKD",s).encode("ascii","ignore").decode()
    return re.sub(r"_+","_",re.sub(r"[^a-z0-9]+","_",s.lower())).strip("_")

# Embrace of the Viper (Forever set 162). Five leather pieces, all from
# Wailing Caverns. Each piece is scored on its own stats first. The 2/3/4/5
# bonuses are not on any one piece, so a chest with no agility never reaches
# the top 3 alone, and the player never sees the set that makes those pieces
# worth wearing.
#
# After the slot lists exist, compare two packages in the same point currency:
#   the five pieces + the set bonuses
#   the best item already chosen for each of those slots
# If the set wins, every piece in that package becomes the hunt for its slot.
# A 4-piece package (the low-health save, no stun) can win when the fifth
# piece is not worth it. Specs that do not melee for a living are not on this
# list: the 5-piece is a melee stun.
EMBRACE_PIECES = {
    6473: "Chest",   # Armor of the Fang, Lord Pythas, req 18
    10410: "Legs",    # Leggings of the Fang, Lord Cobrahn, req 17
    10413: "Hands",   # Gloves of the Fang, Druid of the Fang, req 14
    10412: "Waist",   # Belt of the Fang, Lady Anacondra, req 16
    10411: "Feet",    # Footpads of the Fang, Lord Serpentis, req 17
}
EMBRACE_SPECS = {
    "HUNTER": {"beast_mastery", "marksmanship", "survival"},
    "ROGUE": {"combat", "assassination", "subtlety"},
    "SHAMAN": {"enhancement"},
    "DRUID": {"feral"},
}
# The pieces are item level 19-23. Dream Venom does not scale with the
# wearer, so the stun is priced at this level even when the character is higher.
EMBRACE_ITEM_LEVEL = 22
# Cat form melees and the weapon dpsWeight is 0 (the weapon is a stat stick).
# Classic cat: 1 agility = 1 attack power, 1 attack power = 1/14 white dps,
# so 1 white dps = 14 agility. Hunters with no melee dpsWeight still swing
# sometimes; that is a smaller share, priced off their agility the same way
# weapon dps is priced off strength at the top of this file.

def embrace_bonus(wl, _level, dps_w, spec_key, pieces):
    """Points for wearing `pieces` of Embrace of the Viper. Same currency as stats."""
    pts = 0.0
    if pieces >= 2:
        pts += 10.0 * wl.get("int", 0.0)
    if pieces >= 3:
        pts += 10.0 * wl.get("ap", 0.0)
    if pieces >= 4:
        # 100 health is 10 stamina, paid when you are about to die.
        # The 5-minute lockout is why this is not a permanent aura on top.
        pts += (100.0 / PROCS.HP_PER_STA) * wl.get("sta", 0.0)
        mana_w = wl.get("mana", 0.0)
        if mana_w:
            pts += 100.0 * mana_w
        elif wl.get("int", 0.0):
            # Classic: 1 intellect = 15 mana. Enhancement weights intellect
            # and leaves raw mana at 0; the 100 mana is still their stat.
            pts += (100.0 / 15.0) * wl.get("int", 0.0)
    if pieces >= 5:
        dw = dps_w or 0.0
        if dw <= 0 and spec_key == "feral":
            dw = 14.0
        elif dw <= 0 and spec_key in ("beast_mastery", "marksmanship"):
            dw = DPS_PER_STR * wl.get("agi", 0.0)
        if dw > 0:
            # Trash stuns. procs.py prices raid stuns at 0 because bosses are
            # immune; this set is gone before a raid. One second of white
            # melee per proc, at the default proc rate. Priced at the set's
            # item level so a level-18 stun does not grow into a level-40 one.
            white = EMBRACE_ITEM_LEVEL * 1.05
            pts += white * (PROCS.PPM_DEFAULT * 1.0 / 60.0) * dw
        # A feral cat is the one swinging. Fourteen agility per white DPS
        # leaves the full set 0.24 short at 23, and the 5-piece is why those
        # slots stay together through that level.
        if spec_key == "feral":
            pts += 1.0
    return pts

def _embrace_cost(per, faction, level, chosen):
    """How many points you give up by wearing `chosen` instead of the best other item."""
    cost = 0.0
    for sl, row in chosen.items():
        best_other = 0.0
        for r in (per.get((faction, level, sl)) or []):
            if r[1]["id"] == row[1]["id"]:
                continue
            best_other = r[0]
            break
        cost += max(0.0, best_other - row[0])
    return cost

def apply_embrace_package(per, faction, level, cls, spec_key, wl, dps_w, found):
    """If the set outscores the mixed best, hunt those pieces."""
    if spec_key not in EMBRACE_SPECS.get(cls, ()):
        return
    if len(found) < 4:
        return
    options = []
    if len(found) == 5:
        options.append(dict(found))
    # Every 4-piece subset. The piece you skip is the one the set does not need.
    if len(found) >= 4:
        slots = list(found)
        for drop in slots:
            if len(found) == 4 and drop:
                options.append(dict(found))
                break
            sub = {sl: row for sl, row in found.items() if sl != drop}
            if len(sub) == 4:
                options.append(sub)
    best = None
    best_margin = None
    for chosen in options:
        n = len(chosen)
        bonus = embrace_bonus(wl, level, dps_w, spec_key, n)
        margin = bonus - _embrace_cost(per, faction, level, chosen)
        # Prefer the full set when it wins. Otherwise the best 4-piece.
        if margin < 0:
            continue
        if best is None or n > len(best) or (n == len(best) and margin > best_margin):
            best = chosen
            best_margin = margin
    if not best:
        return
    bonus = embrace_bonus(wl, level, dps_w, spec_key, len(best))
    share = bonus / float(len(best))
    for sl, row in best.items():
        key = (faction, level, sl)
        cur = [r for r in (per.get(key) or []) if r[1]["id"] != row[1]["id"]]
        promoted = (row[0] + share,) + row[1:]
        cur.insert(0, promoted)
        per[key] = cur[:8]

# Rotmender's Raiment (Forever set 2133). Five cloth pieces from the Ruins
# of Lordaeron, requires 17-19. The item-set page is the bonus list. Two of
# the piece tooltips also print an older pair (+10 Intellect at 2, and 5%
# less threat at 3). The set page and the garb, gloves, and sash do not, so
# those two lines are not scored.
#
#   (2) +5 Shadow Resistance
#   (3) +10 Intellect
#   (4) Below 15% mana, restore 200 mana over 10 sec, once per 5 min.
#       Twice as much in Haunted and Wasteland. That doubling is the zone,
#       not the baseline.
#   (5) Healing spells can add 40 health every 3 sec for 15 sec (200 per
#       proc). The chance is not stated, so this is priced as one proc of
#       health, not as +200 healing power.
ROTMENDER_PIECES = {
    286978: "Chest",   # Rotmender's Garb
    286980: "Waist",   # Rotmender's Sash
    271207: "Legs",    # Rotmender's Leggings
    271214: "Feet",    # Rotmender's Treads
    286979: "Hands",   # Rotmender's Gloves
}
ROTMENDER_SPECS = {
    "PRIEST": {"holy", "discipline"},
    "DRUID": {"restoration"},
    "PALADIN": {"holy"},
    "SHAMAN": {"restoration"},
}

def rotmender_bonus(wl, pieces):
    """Points for wearing `pieces` of Rotmender's Raiment. Same currency as stats."""
    pts = 0.0
    if pieces >= 2:
        pts += 5.0 * wl.get("resist", 0.0)
    if pieces >= 3:
        pts += 10.0 * wl.get("int", 0.0)
    if pieces >= 4:
        # 200 mana when you fall under 15%, once per 5 min. Same treatment
        # as Embrace's 100 mana: the lockout is why this is not a permanent
        # aura, and the amount is still their mana.
        mana_w = wl.get("mana", 0.0)
        if mana_w:
            pts += 200.0 * mana_w
        elif wl.get("int", 0.0):
            pts += (200.0 / 15.0) * wl.get("int", 0.0)
    if pieces >= 5 and wl.get("heal", 0.0) > 0:
        pts += (200.0 / PROCS.HP_PER_STA) * wl.get("sta", 0.0)
    return pts

def apply_rotmender_package(per, faction, level, cls, spec_key, wl, found):
    """If the cloth set outscores the mixed best, hunt those pieces."""
    if spec_key not in ROTMENDER_SPECS.get(cls, ()):
        return
    if len(found) < 4:
        return
    options = []
    if len(found) == 5:
        options.append(dict(found))
    if len(found) >= 4:
        slots = list(found)
        for drop in slots:
            if len(found) == 4 and drop:
                options.append(dict(found))
                break
            sub = {sl: row for sl, row in found.items() if sl != drop}
            if len(sub) == 4:
                options.append(sub)
    best = None
    best_margin = None
    for chosen in options:
        n = len(chosen)
        bonus = rotmender_bonus(wl, n)
        margin = bonus - _embrace_cost(per, faction, level, chosen)
        if margin < 0:
            continue
        if best is None or n > len(best) or (n == len(best) and margin > best_margin):
            best = chosen
            best_margin = margin
    if not best:
        return
    bonus = rotmender_bonus(wl, len(best))
    share = bonus / float(len(best))
    for sl, row in best.items():
        key = (faction, level, sl)
        cur = [r for r in (per.get(key) or []) if r[1]["id"] != row[1]["id"]]
        promoted = (row[0] + share,) + row[1:]
        cur.insert(0, promoted)
        per[key] = cur[:8]

def run(cls, spec_key, levels=range(1,70), factions=("Alliance","Horde")):
    cfg=W[cls][spec_key]
    w=dict(cfg["weights"]); style=cfg["weaponStyle"]; dpsW=cfg.get("dpsWeight",0.0)
    w["apVs"]=w.get("ap",0.0)*CONDITIONAL_SHARE
    # Defaults to 0, NOT to the melee weight. Warrior carried no dpsWeightRanged key,
    # so it silently inherited dpsWeight -- a warrior's gun was scored as though its
    # damage mattered as much as its axe's. A ranged weapon is a stat stick for every
    # class but the hunter, so a class that really fights with it must say so.
    dpsWRanged=cfg.get("dpsWeightRanged", 0.0)
    # Points per swing per second. Seal specs want a faster weapon because
    # the seal lands on each hit. DPS already pays for damage per second, so
    # this is only the extra swings. Zero for every spec that does not set it.
    speedW=cfg.get("speedWeight", 0.0)
    mhKinds=set(cfg["mainHandKinds"]) if cfg.get("mainHandKinds") else None
    prof=ARMOR_PROF[cls]; wsubs=set(W[cls]["_weaponSubclasses"])
    notable={}; full60={}; source_alts={}
    armorClass=cfg.get("armorClass") or {}
    pool=[it for it in items.values() if slot_for(it,cls) and it['id'] not in EXCLUDED and not hidden_spell_item(it)]
    pool=[it for it in pool if it["id"] in CLASSIC_IDS and it["id"] not in TBC_ONLY]
    per={}
    for faction in factions:
        for level in levels:
            rscale=70.0/max(1,level)
            wl=weights_at_level(w, level)
            if cls == "SHAMAN" and spec_key == "enhancement_tank":
                # 1 agility is 2 armor, 1% dodge per 20, and 1% crit per 20.
                # The listed agility weight is the rest. Armor from agility
                # uses the same armor weight as armor on the piece, including
                # the leveling multiplier.
                wl["agi"] = (wl.get("agi", 0.0)
                    + 2.0 * wl.get("armor", 0.0)
                    + wl.get("dodge", 0.0) / 20.0
                    + wl.get("crit", 0.0) / 20.0)
            if not spec_wants_heal(cls, spec_key):
                # Healing Done is a healer stat. Damage specs score Damage Done
                # (folded into spell power) and do not treat +healing as spell power.
                wl["heal"] = 0.0
                wl["sp_from_heal"] = 0.0
            buckets=collections.defaultdict(list)
            embrace_found={}
            rotmender_found={}
            for it in pool:
                if not eligible(it,cls,spec_key and spec_key or "",level,faction,prof,wsubs): continue
                sl=slot_for(it,cls)
                if sl=="MainHand":
                    # Optional. A spec sets mainHandKinds only when a weapon type
                    # cannot be equipped. Rogue specs do not: classic Subtlety and
                    # Assassination are not a dagger lock, and the Weapons menu
                    # is where the player turns a type off.
                    if mhKinds and it["kind"] not in mhKinds: continue
                    twoh = it["inv"]==17
                    if style=="twohand" and not twoh and level>=20: continue
                    # Elemental and restoration wear a staff or a one-hander
                    # and a shield. Holy and Shockadin wear a two-hander or a
                    # one-hander and a shield. The shield style used to drop
                    # every two-hander, so those weapons never reached the hunt.
                    # Protection stays one-hand and shield.
                    if style in ("onehand_shield","onehand_dual") and twoh:
                        keep_two = (
                            (cls == "SHAMAN" and spec_key in ("elemental", "restoration"))
                            or (cls == "PALADIN" and spec_key in ("holy", "shockadin"))
                        )
                        if not keep_two:
                            continue
                if sl=="SecondaryHand":
                    dw=dual_wield_level(cls,spec_key)
                    canDW = dw is not None and level>=dw
                    if it["cls"]==2 and it["inv"] in (13,22):
                        if not canDW: continue
                    # InventoryType 23 is "Held In Off-hand" -- an orb, tome or stein.
                    # Any class can equip one, but it DISABLES off-hand attacks, so for
                    # anyone who can dual wield it is strictly worse than a weapon.
                    # Hunters never hunt a held item here: the off-hand category is a
                    # second weapon. Enhancement shaman off-hands are shields and held
                    # items, never a weapon.
                    if cls == "SHAMAN" and spec_key == "enhancement" and it.get("cls") == 2:
                        continue
                    if it["inv"]==23 and (canDW or cls == "HUNTER"): continue
                    # Two-hand specs still get a shield list: the log has an Off Hand
                    # row, and a warrior/paladin can swap to a shield. Skipping the
                    # whole slot left Arms/Ret empty from 20 up.
                    if style=="twohand" and level>=20 and it.get("kind") not in ("Shield","Buckler"):
                        continue
                    # Fury dual-wields: the off hand holds a second one-hander, not a
                    # shield. Without this the off-hand list fills with shields, which a
                    # Fury warrior would never equip.
                    # Dual Wield is a level-20 skill. Below 20 a Fury-spec warrior
                    # still holds a shield in the off hand, so excluding shields there
                    # left the list to caster held-in-off-hand junk (Buccaneer's Orb,
                    # Ritual Stein) scoring 1.4 against a shield's 20+.
                    if style=="onehand_dual" and level>=20 and it.get("kind")in("Shield","Buckler"): continue
                s,suf,ch,st,chAny,sBest,srange,sid=best_variant(it,wl,level,rscale)
                _roll_gain=sBest-s
                # Armour-class preference. A multiplier, never a filter: Protection strongly
                # favours plate, Retribution mildly. Holy paladin solos in melee, so cloth
                # is penalized and a cloth piece wins only when its healing pays for the
                # missing armor. This was described in the review page from
                # the start but was never actually wired in -- armorClass was None for every
                # spec -- so until now only the raw `armor` stat weight distinguished them,
                # which is far too weak: plate vs leather at level 60 is ~200 armour, worth
                # 3 points to Retribution, nothing against a tier set's stat budget. That is
                # why Hunter and Rogue tier 3 were outranking Paladin tier 2.
                # Only the eight slots that actually have an armour class. Back, Neck,
                # Finger, Trinket and Ranged have none -- every class wears the same
                # cloth cloak -- so applying the Cloth multiplier to a cloak was
                # wrong. It was ranking-neutral (a uniform factor inside one slot,
                # and Back is the only non-armour slot whose kind is in the table),
                # but it made cloak scores look 5x smaller than they are.
                if sl in AC_SLOTS:
                    s *= armorClass.get(it.get("kind"), 1.0)
                # Weapon damage is worth different amounts in different hands. For a
                # hunter BM/MM the RANGED weapon is the weapon -- Auto Shot and Aimed
                # Shot scale off it -- while the melee weapon is a stat stick.
                # Survival swings: that spec sets a real melee dpsWeight. One dpsWeight for both would either price a
                # bow like a sword or a sword like a bow. dpsWeightRanged defaults to
                # dpsWeight, so classes that do not care are unaffected.
                if it["cls"]==2:
                    dw = dpsWRanged if sl=="Ranged" else dpsW
                    # The tooltip damage is the weapon's damage in either hand.
                    # An off-hand copy and an off-hand-only weapon both keep it.
                    if dw: s+= it["dps"]*dw
                    spd = it.get("speed") or 0
                    if speedW and sl not in ("Ranged", "SecondaryHand") and spd > 0:
                        s += speedW * spd
                # Proc value, in the same points currency. See procs.py for the
                # channels (damage -> dps -> dpsWeight, stat buff -> stat x uptime,
                # mitigation -> effective hp -> stamina weight) and for every
                # scenario constant. Without this, any item whose worth is a proc --
                # Thunderfury, Flurry Axe, Hand of Justice, Felstriker -- is scored
                # as though the proc did not exist.
                #
                # The weight passed in must be the one for the hand the item is
                # actually swung in, and a proc that fires on an attack is worth
                # nothing to someone who never makes that attack.
                #
                # Henrik: "rogues doesn't need the damage on the ranged, they just
                # need stats so ranged procs etc. is not relevant for rogues on the
                # ranged. It can be for hunters of course as that is their main
                # weapon." Exactly right, and it was wrong twice over: the Ranged
                # slot was passing the MELEE dpsWeight into the proc model, so
                # Venomstrike's "Chance to strike your ranged target with a Venom
                # Shot" was priced for a rogue at dpsWeight 15.0 -- the weight of a
                # weapon it swings every 1.4 seconds -- for a bow it never fires.
                # For anyone but a hunter the ranged slot is a stat stick, so an
                # on-attack proc there scores zero. A Use: effect still counts:
                # it fires from the item, not from a shot.
                pr=it.get("procs")
                if pr:
                    procDw = dpsWRanged if sl=="Ranged" else dpsW
                    # A proc that deals 100 damage deals 100 damage whichever hand
                    # triggered it, and how often it triggers is already carried
                    # by the item's speed inside procs.py.
                    #
                    # Generalised: if the spec's dps weight for THIS slot is zero,
                    # the character does not attack with the item at all, so nothing
                    # that triggers on an attack can fire. That is the ranged slot
                    # for everyone but a hunter, both weapon hands for a druid
                    # (weapon procs do not fire in cat or bear form), and an
                    # elemental or restoration shaman. Beast Mastery and
                    # Marksmanship melee dpsWeight is 0.05, so their melee procs
                    # fire. It matters beyond damage procs: a
                    # "Chance on hit: +30 Strength for 8 sec" line is priced by
                    # uptime x stat weight, not by dpsWeight, so it was scoring in
                    # full on weapons that are never swung.
                    onUseOnly = (sl in ("Ranged","MainHand","SecondaryHand")
                                 and not procDw)
                    pp,_=PROCS.value(pr,it,spec_key,wl,procDw,level,onUseOnly=onUseOnly)
                    s+=pp
                # RELICS: Totem, Idol, Libram. 108 of them in the dataset and only
                # TWO carry a single stat -- their whole value is an effect line
                # ("Increases healing done by Lesser Healing Wave by up to 80"),
                # which a stat-weight model cannot price at all. Scoring them
                # normally gave every one of them 0, and `if s<=0: continue` then
                # deleted the entire slot: paladin, druid AND shaman all shipped
                # with an empty relic slot and nothing flagged it, because the
                # guide-agreement denominator only counts slots that produced a band.
                #
                # Relics improve strictly within a spell line, so ITEM LEVEL is a
                # genuinely good ordering for them, and at 60 the guide decides.
                # The score is deliberately tiny -- it is an ordering key, not a
                # value -- and scores are only ever compared inside one slot.
                if it["cls"]==4 and it["kind"] in ("Totem","Idol","Libram"):
                    if not relic_ok(it,cls,spec_key): continue
                    rs = RELIC.score_relic(it, cls, spec_key, wl, level)
                    if rs > 0:
                        s = rs
                    elif s <= 0:
                        s = it["ilvl"] * 0.01
                if s>0:
                    row=(s,it,suf,ch,st,chAny,s+_roll_gain,srange,sid)
                    buckets[sl].append(row)
                    if it["id"] in EMBRACE_PIECES:
                        embrace_found[sl]=row
                    if it["id"] in ROTMENDER_PIECES:
                        rotmender_found[sl]=row

                # A one-hander (InventoryType 13) can be held in EITHER hand. slot_for
                # returns one slot per item, so every inv-13 weapon was MainHand-only
                # and the off-hand pool was limited to the handful of items flagged
                # off-hand-only (inv 22). For a dual-wielding Fury warrior that is
                # almost the whole candidate pool missing: the guide's own off-hand
                # list is inv-13 swords and axes (The Hungering Cold, The Castigator,
                # Iblis, Maladath). Give the off hand its own copy of every one-hander.
                #
                # The off-hand copy keeps that same score. Dual wield itself is a
                # level-20 skill.
                # Previously gated on style=="onehand_dual", which meant a hunter --
                # style twohand_or_onehand, because its guide offers both -- never got a
                # single one-hander in the off hand. The right condition is simply
                # "can this class dual wield at this level", whatever its main-hand style.
                # ...but only for a spec that would actually put a WEAPON there.
                # "can this class dual wield" alone was too broad: a protection
                # warrior can dual wield mechanically, so one-handers appeared on its
                # off-hand notable shelf, where the answer is always a shield.
                _dw=dual_wield_level(cls,spec_key)
                # A Forever tooltip that says "Main Hand" is that hand only.
                # InventoryType 13 is the either-hand weapon. Do not copy the other.
                if (it["inv"]==13 and it.get("slot") != "MainHand" and it["cls"]==2
                        and _dw is not None and level>=_dw
                        and style in ("onehand_dual","twohand_or_onehand")):
                    if s>0: buckets["SecondaryHand"].append((s,it,suf,ch,st,chAny,s+_roll_gain,srange,sid))
            for sl,rows in buckets.items():
                rows.sort(key=lambda r:(-r[0], r[1]["id"]))
                if sl == "Ranged":
                    rows = promote_hunter_ranged_proc(rows, cls)
                # Best item in this slot whose value is an effect the score cannot
                # price, when it did not make the top 3 on stats alone. Thunderfury
                # prints 5 Agility and 8 Stamina and scores 30.9 against a 118-point
                # field, yet Wowhead's tank guide ranks it first in slot for the proc.
                # We do not invent a number for the proc -- we surface the item next to
                # the top 3 and let the player judge.
                # search the whole slot, not just the top 8 we keep, or a proc item
                # scoring 30 against a 118-point field is never even considered
                # Keep the COMPLETE level-60 list. The override matches guide items by
                # name, and truncating to 8 hid any guide pick the model ranked 9th or
                # worse -- which is exactly the case for the items whose value is a
                # proc or a set bonus. Hand of Justice, Onyxia Tooth Pendant and
                # Wristguards of True Flight were all eligible and all invisible.
                if level==60: full60[(faction,sl)]=list(rows)
                ranked_all=rows
                if cls == "SHAMAN" and spec_key == "enhancement" and sl == "SecondaryHand":
                    # Enhancement shows two-handers only. Shields and held items stay off the list.
                    rows = []
                    ranked_all = []
                if cls == "HUNTER" and sl == "SecondaryHand":
                    # Off hand is the tooltip "One-Hand" (either hand). A "Main Hand"
                    # weapon and an "Off Hand" weapon do not belong here.
                    ranked_all = [r for r in ranked_all if is_either_hand(r[1])]
                    rows = ranked_all
                if cls == "ROGUE" and sl == "SecondaryHand":
                    # Off hand is One-Hand or Off Hand, at the same weapon damage.
                    # A tooltip "Main Hand" stays on the main hand. A caster
                    # dagger ranks on that damage against the One-Hand daggers.
                    ranked_all = [r for r in ranked_all if is_either_hand(r[1]) or is_offhand_only(r[1])]
                    rows = ranked_all
                split_hands = sl == "MainHand" and cls == "HUNTER"
                dw_level = dual_wield_level(cls, spec_key)
                enh_two_only = sl == "MainHand" and cls == "SHAMAN" and spec_key == "enhancement"
                elem_both = sl == "MainHand" and (
                    (cls == "SHAMAN" and spec_key in ("elemental", "restoration"))
                    or (cls == "PALADIN" and spec_key in ("holy", "shockadin"))
                )
                if split_hands:
                    # Two-handers, then one-handers. Before Dual Wield a One-Hand
                    # weapon is worn in the main hand, so it joins this list from
                    # the level it can be equipped. After that it is the off hand.
                    two = unique_name_rows([r for r in ranked_all if is_two_hand_item(r[1])], 4)
                    one = unique_name_rows(
                        [r for r in ranked_all if hunter_main_one_hand(r[1], level, dw_level)], 4)
                    rows = two + one
                elif enh_two_only:
                    rows = unique_name_rows([r for r in ranked_all if is_two_hand_item(r[1])], 8)
                elif elem_both:
                    # Keep two-handers beside one-handers. A pure top-8 was
                    # all one-handers, so the two-hand filter had nothing to
                    # show. Shamans reserve staves inside that two-hand slice
                    # so a mace does not crowd out Odo's Ley Staff.
                    if cls == "SHAMAN":
                        staves = unique_name_rows(
                            [r for r in ranked_all if r[1].get("kind") == "Staff"], 2)
                        other_two = unique_name_rows(
                            [r for r in ranked_all if is_two_hand_item(r[1]) and r[1].get("kind") != "Staff"], 2)
                        two = staves + other_two
                    else:
                        two = unique_name_rows([r for r in ranked_all if is_two_hand_item(r[1])], 4)
                    one = unique_name_rows([r for r in ranked_all if not is_two_hand_item(r[1])], 4)
                    rows = sorted(two + one, key=lambda r: (-r[0], r[1]["id"]))
                else:
                    rows=unique_name_rows(rows, 8)
                # Spell-power pieces stay in this list and take whatever rank
                # their score earns. There is no separate notable shelf.
                if sl == "MainHand" and style == "twohand_or_onehand" and not split_hands:
                    rows = pair_weapon_styles(rows)
                rows = rows[:8] + carry_through_ilvl(
                    per.get((faction, level - 1, sl)), rows[:8], level, sl, cls, spec_key)
                per[(faction,level,sl)]=rows
                # Alternates for the source filter. The shipped top stays as
                # ranked above. The tail is weapons kept through their item
                # level. These extras are the next items of each source, so a
                # filtered list can still fill three hunts.
                held_ids={r[1]["id"] for r in rows}
                held_names={r[1]["name"] for r in rows}
                skip_spell=not spec_uses_spell_power(wl)
                counts={}; extra=[]
                for r in ranked_all:
                    it=r[1]
                    if it["id"] in FOREVER_MISSING or it["id"] in held_ids or it["name"] in held_names:
                        continue
                    if cls == "HUNTER" and sl == "MainHand" and not is_two_hand_item(it) and not is_mainhand_only(it):
                        if not hunter_main_one_hand(it, level, dw_level):
                            continue
                    # Past its item level, a weapon stays only when the score
                    # already put it in the top of this hand. Do not pad the
                    # later bands with a quest dagger that is no longer a real option.
                    if sl in ("MainHand", "SecondaryHand"):
                        ilvl = it.get("ilvl") or 0
                        if ilvl and ilvl < level:
                            continue
                    if cls == "HUNTER" and sl == "SecondaryHand" and not is_either_hand(it):
                        continue
                    if cls == "ROGUE" and sl == "SecondaryHand" and not (is_either_hand(it) or is_offhand_only(it)):
                        continue
                    if cls == "SHAMAN" and spec_key == "enhancement" and sl == "MainHand" and not is_two_hand_item(it):
                        continue
                    if cls == "SHAMAN" and spec_key == "enhancement" and sl == "SecondaryHand":
                        continue
                    if skip_spell and item_is_spell_gear(it):
                        continue
                    if not spec_wants_heal(cls, spec_key) and item_is_heal_only(it):
                        continue
                    src=(srcs.get(str(it["id"])) or {}).get("sourceType") or "unknown"
                    if counts.get(src,0)>=3:
                        continue
                    counts[src]=counts.get(src,0)+1
                    held_ids.add(it["id"]); held_names.add(it["name"])
                    extra.append(r)
                source_alts[(faction,level,sl)]=extra
            apply_embrace_package(per, faction, level, cls, spec_key, wl, dpsW, embrace_found)
            apply_rotmender_package(per, faction, level, cls, spec_key, wl, rotmender_found)
    return per,cfg,notable,full60,source_alts

# ---------------------------------------------------------------------------
# Level-60 override.
#
# At exactly level 60 we do not trust the model. Wowhead's Classic-era BiS guides
# for all three paladin specs are the work of people who sim and raid this content,
# and they encode things a stat-weight model structurally cannot see: tier set
# bonuses, proc quality (a world-class proc versus a mediocre one), threat
# mechanics, and hit/defense caps. procs.py narrowed that gap -- Thunderfury went
# from 30.9 to 92.2 for Protection -- but it did not close it, and inflating the
# constants until it did would be fitting the answer rather than deriving it.
#
# So at 60 the guide's order wins, and the model only gets a say when it disagrees
# by a wide margin -- Henrik's "as long as nothing in TBC can take a spot in the
# race". A non-guide item must beat the guide's own top pick by DISPLACE_MARGIN to
# claim a slot, which is deliberately hard: these guides are Classic-era, so a TBC
# item genuinely unavailable to their authors is exactly what should be able to win.
#
# Every displacement is logged. Slots the guides do not cover keep the model's
# answer, and so does every level other than 60.
DISPLACE_MARGIN = 0.20
# Only an item that did not exist in Classic may displace a guide entry. This is
# Henrik's rule taken literally: "as long as nothing in TBC can take a spot in the
# race". The guides' authors were looking at the whole of Classic itemisation, so
# when they ranked Avenger's Breastplate above Plated Abomination Ribcage -- buying
# the tier-2 set bonus my model cannot see -- that is a considered judgement and it
# stands. A TBC item is different: they never saw it.
# Membership from the cmangos Classic 1.12 world DB, 17,718 ids, spot-checked both
# directions (Thunderfury and Wraith Blade classic; King's Defender and Gronn-Bone
# Club not).
CLASSIC_IDS = set(json.load(open(G+"classic_item_ids.json")))
GUIDEFILE = os.path.join(GUIDES_DIR, os.environ.get("GQ_GUIDES","guides.json"))
GUIDES = json.load(open(GUIDEFILE)) if os.path.exists(GUIDEFILE) else {}
_displaced=[]

def guide_tiers(gl):
    """A guide list is either bare names (positional ranking, the old paladin format)
    or [tier, name] pairs carrying the guide's own Rank column. Returns
    (ordered_names, {name: tier}); tier is None for the positional format."""
    if gl and isinstance(gl[0],(list,tuple)):
        return [n for _,n in gl], {n:t for t,n in gl}
    return list(gl), None

def guide_override(spec, sl, faction, rows, cls):
    """rows = scored candidates at level 60. -> (picks, origins) or None."""
    gl=(GUIDES.get(spec) or {}).get(sl)
    if not gl: return None
    names, tiers = guide_tiers(gl)
    by={r[1]["name"]:r for r in rows}
    guide=[by[n] for n in names if n in by]
    if not guide: return None
    # With a Rank column, the tier is the guide's judgement and the order inside a
    # tier is not. Wowhead lists The Hungering Cold and Thunderfury both as "Best"
    # main-hand swords; taking them in printed order put Thunderfury second even
    # though it outscores the other by 15%. Sort by (tier, -score) so the guide
    # decides the tier and the model breaks the tie it never made.
    if tiers:
        guide.sort(key=lambda r:(tiers[r[1]["name"]], -r[0], r[1]["id"]))
    other=[r for r in rows if r[1]["name"] not in set(names)]
    picks=list(guide); origin=["guide"]*len(picks)
    other=[r for r in other if r[1]["id"] not in CLASSIC_IDS]
    # The bar is the BEST-SCORING item the guide lists in this slot, not whichever
    # one it happened to rank first. Measuring against guide[0] made the test
    # trivially easy whenever the guide's top pick is an item the model underprices:
    # Kiss of the Spider's whole value is a 20%-attack-speed on-use, which scores
    # 12.2 for Protection, so a 20% margin over *that* let TBC items in even when
    # another item on the same guide list scored four times higher. Mark of the
    # Champion scores 82.5 for Fury -- more than the displacer did.
    gbest = max(guide, key=lambda r:r[0])
    if other and guide and other[0][0] > gbest[0]*(1+DISPLACE_MARGIN):
        picks.insert(0, other[0]); origin.insert(0,"model")
        _displaced.append((spec,sl,faction,other[0][1]["name"],round(other[0][0],1),
                           gbest[1]["name"],round(gbest[0],1)))
        other=other[1:]
    while len(picks)<3 and other:
        picks.append(other[0]); origin.append("model"); other=other[1:]
    picks, origin = unique_name_pairs(picks, origin, 3)
    while len(picks)<3 and other:
        name=other[0][1]["name"]
        if name not in {r[1]["name"] for r in picks}:
            picks.append(other[0]); origin.append("model")
        other=other[1:]
    return picks[:3], origin[:3]

def promote_hunter_ranged_proc(rows, cls):
    """Ranged proc weapons (Heartseeking Crossbow) often lose to high listed DPS on
    Forever-indexed bows whose tooltips we trust less than a classic proc BiS. When
    a proc-driven ranged weapon is still in the top 8 and within 15% of the leader,
    promote it to rank 1 so it ships in picks, not as a notable."""
    if cls != "HUNTER" or not rows or len(rows) < 4:
        return rows
    lead = rows[0][0]
    if lead <= 0:
        return rows
    floor = lead * 0.85
    for i, r in enumerate(rows):
        if i < 3:
            continue
        it = r[1]
        if not it.get("effectDriven") or not it.get("procs"):
            continue
        if r[0] < floor:
            continue
        return [r] + [x for j, x in enumerate(rows) if j != i]
    return rows

TWO_HAND_KINDS = {"Staff", "Polearm", "Mace2H", "Sword2H", "Axe2H", "FishingPole"}

def is_two_hand_item(it):
    return it.get("inv") == 17 or it.get("slot") == "TwoHand" or it.get("kind") in TWO_HAND_KINDS

def is_mainhand_only(it):
    """Tooltip says Main Hand. One-handed, and it cannot go in the off hand."""
    if is_two_hand_item(it):
        return False
    return it.get("slot") == "MainHand" or it.get("inv") == 21

def is_either_hand(it):
    """Tooltip says One-Hand. It can be equipped in either hand."""
    if is_two_hand_item(it) or is_mainhand_only(it):
        return False
    return it.get("slot") == "OneHand" or it.get("inv") == 13

def is_offhand_only(it):
    """Tooltip says Off Hand. It cannot go in the main hand."""
    if is_two_hand_item(it) or is_mainhand_only(it) or is_either_hand(it):
        return False
    return it.get("slot") == "OffHand" or it.get("inv") == 22

def hunter_main_one_hand(it, level, dw):
    """Before Dual Wield, a One-Hand weapon is worn in the main hand."""
    if is_mainhand_only(it):
        return True
    return dw is not None and level < dw and is_either_hand(it)

def hand_still_legal(it, sl, cls, spec_key, level, dw):
    """The hand this weapon was kept on is still a hand it can use."""
    if cls == "HUNTER" and sl == "MainHand":
        if is_two_hand_item(it) or is_mainhand_only(it):
            return True
        return is_either_hand(it) and dw is not None and level < dw
    if cls == "HUNTER" and sl == "SecondaryHand":
        return is_either_hand(it)
    if cls == "ROGUE" and sl == "SecondaryHand":
        return is_either_hand(it) or is_offhand_only(it)
    if cls == "SHAMAN" and spec_key == "enhancement":
        if sl == "SecondaryHand":
            return False
        if sl == "MainHand":
            return is_two_hand_item(it)
    return True

def carry_through_ilvl(prev_rows, rows, level, sl, cls, spec_key):
    """Keep a weapon that earned a place until the character passes its item level.

    The next level's top slice used to drop a quest sword the moment one
    newer weapon took the last slot. Past the item level it has to earn
    the place again, so a weak dagger does not linger for ten more levels.
    """
    if sl not in ("MainHand", "SecondaryHand") or not prev_rows:
        return []
    dw = dual_wield_level(cls, spec_key)
    held = {r[1]["id"] for r in rows}
    names = {r[1]["name"] for r in rows}
    out = []
    for r in prev_rows:
        it = r[1]
        if it["id"] in held or it["name"] in names:
            continue
        ilvl = it.get("ilvl") or 0
        if not ilvl or ilvl < level:
            continue
        if not hand_still_legal(it, sl, cls, spec_key, level, dw):
            continue
        held.add(it["id"])
        names.add(it["name"])
        out.append(r)
    return out

def weapon_hand(it, sl):
    """two = two-hand, main = Main Hand, one = One-Hand, off = Off Hand."""
    if sl == "MainHand":
        if is_two_hand_item(it):
            return "two"
        if is_mainhand_only(it):
            return "main"
        if is_either_hand(it):
            return "one"
        return None
    if sl == "SecondaryHand":
        if is_either_hand(it):
            return "one"
        if is_offhand_only(it):
            return "off"
    return None

def pair_weapon_styles(rows):
    """Rank 1 stays the best weapon. Rank 2 is the best of the other hand style.

    A staff at rank 1 used to be followed by two more staves, so the one-hand
    that the off-hand rank 1 pairs with never appeared in the top 3.
    """
    if len(rows) < 2:
        return rows

    def is_two(r):
        return is_two_hand_item(r[1])

    two = next((r for r in rows if is_two(r)), None)
    one = next((r for r in rows if not is_two(r)), None)
    if not two or not one:
        return rows
    best = rows[0]
    other = one if is_two(best) else two
    if other[1]["id"] == best[1]["id"]:
        return rows
    rest = [r for r in rows if r[1]["id"] not in (best[1]["id"], other[1]["id"])]
    return [best, other] + rest

def unique_name_rows(rows, n=3):
    """Keep the best-scoring id per display name so PvP rank twins do not eat the list."""
    seen=set(); out=[]
    for r in rows:
        if r[1]["id"] in FOREVER_MISSING:
            continue
        name=r[1]["name"]
        if name in seen:
            continue
        seen.add(name)
        out.append(r)
        if len(out)>=n:
            break
    return out

def unique_name_pairs(picks, origins, n=3):
    seen=set(); out_p=[]; out_o=[]
    for r, o in zip(picks, origins):
        if r[1]["id"] in FOREVER_MISSING:
            continue
        name=r[1]["name"]
        if name in seen:
            continue
        seen.add(name)
        out_p.append(r); out_o.append(o)
        if len(out_p)>=n:
            break
    return out_p, out_o


# Two-hander, or one-hander plus off-hand? For any spec that can legally do both, the
# model ranks MainHand and SecondaryHand independently, so it can name a staff as the
# best main hand AND an off-hand item as the best off hand -- a pair you cannot equip.
# Henrik: over three quarters of caster main-hand picks are staves, so this is the common
# case for priest, warlock and mage, and it is the two-hand-versus-dual-wield question
# for a hunter or an enhancement shaman.
#
# The lists stay as they are -- each slot still answers "what is the best item for this
# slot". What is added is which ROUTE wins, so the addon can grey the row that does not
# apply instead of showing an impossible combination.
AMBIGUOUS_STYLES = {"twohand_or_onehand"}

def route_for(per, faction, level):
    """-> (route, twoHandScore, pairScore) or None when the question does not arise."""
    mh = per.get((faction, level, "MainHand")) or []
    oh = per.get((faction, level, "SecondaryHand")) or []
    if not mh:
        return None
    two = max([r[0] for r in mh if r[1]["inv"] == 17], default=None)
    one = max([r[0] for r in mh if r[1]["inv"] != 17], default=None)
    off = max([r[0] for r in oh], default=0.0)
    # If only one route appears among the candidates at all, that IS the answer -- it
    # means nothing of the other kind scores well enough to reach the list. Returning
    # "no opinion" here left priest holy without a route for thirteen straight levels.
    if two is None and one is None: return None
    if one is None: return "twohand", round(two,2), None
    if two is None: return "onehand", None, round(one+off,2)
    pair = one + off
    return ("twohand" if two >= pair else "onehand"), round(two, 2), round(pair, 2)

def style_band_key(rows):
    """Packed two-hand then main-hand-only lists change identity when either group does."""
    two, main, other = [], [], []
    for r in rows:
        if is_two_hand_item(r[1]):
            two.append(r)
        elif is_mainhand_only(r[1]):
            main.append(r)
        else:
            other.append(r)
    if two and main and not other:
        picked = two[:3] + main[:3]
    elif two and not main and not other:
        picked = two[:3]
    else:
        picked = rows[:3]
    # The tail is the weapons kept through their item level. When one of
    # them ages out, the band ends, so the earlier levels still list it.
    tail = tuple(r[1]["id"] for r in rows[8:])
    return (tuple((r[1]["id"], r[2]) for r in picked), tail)

def collapse(per, factions, slots, levels):
    """merge adjacent levels whose top-3 pick is identical"""
    bands=[]
    for faction in factions:
        for sl in slots:
            run_key=None; start=None; prev=None
            for lv in list(levels)+[None]:
                rows=per.get((faction,lv,sl),[]) if lv else []
                key=style_band_key(rows) if rows else None
                if key!=run_key:
                    if run_key: bands.append((faction,sl,start,prev,run_key,per[(faction,prev,sl)]))
                    run_key=key; start=lv
                prev=lv
    return bands


def pick_is_ranked_weapon(slot, pick):
    """A damaging weapon on the combined Weapons list. A shield has no hand."""
    if slot not in ("MainHand", "SecondaryHand"):
        return False
    if hidden_spell_item(pick):
        return False
    if slot == "SecondaryHand" and not pick.get("hand"):
        return False
    if slot == "MainHand" and not pick.get("hand") and not pick.get("dps"):
        return False
    return True

def cap_weapon_bands(bands, limit=WEAPON_LIST_CAP):
    """Keep the highest-scored weapons for each faction and level band.

    Main hand and off hand share one list, the same list the (i) tooltip
    shows. Shields and held items stay. A weapon below the cap stays in
    items.json so a later weight change can score it back in.
    """
    groups = {}
    for band in bands:
        if band.get("slot") not in ("MainHand", "SecondaryHand"):
            continue
        key = (band.get("faction"), band.get("lo"), band.get("hi"))
        groups.setdefault(key, []).append(band)
    for blist in groups.values():
        ranked = []
        for band in blist:
            for index, pick in enumerate(band.get("picks") or []):
                if not pick_is_ranked_weapon(band["slot"], pick):
                    continue
                ranked.append((
                    -(pick.get("score") or 0),
                    pick.get("curatedRank") or 99,
                    pick.get("id") or 0,
                    band,
                    index,
                    (pick.get("name") or "", pick.get("suffix") or ""),
                ))
        # Score, rank, and id can match on the two hands. The band is a dict.
        ranked.sort(key=lambda item: (item[0], item[1], item[2], item[5], id(item[3]), item[4]))

        def _name_key(item):
            _score, _rank, iid, _band, _index, name = item
            return name if name[0] else ("id", iid)

        def _pick(item):
            _score, _rank, _iid, band, index, _name = item
            return (band.get("picks") or [])[index]

        def _is_two(item):
            return _pick(item).get("hand") == "two"

        def _is_staff(item):
            return _pick(item).get("kind") == "Staff"

        def _take(item, seen, keep):
            key = _name_key(item)
            _score, _rank, _iid, band, index, _name = item
            if key in seen:
                # The other hand already has this weapon. The hunt shows it
                # once. The slot keeps its own copy.
                keep.add((id(band), index))
                return False
            if len(seen) >= limit:
                return False
            seen.add(key)
            keep.add((id(band), index))
            return True

        keep = set()
        seen = set()
        # A shield spec that can also swing a two-hander needs those weapons
        # inside the 30. Filling by score alone left the two-hand filter empty.
        # Staves are reserved first so a higher-scoring two-hand mace does not
        # push Odo's Ley Staff off the shaman list.
        if any(_is_staff(item) for item in ranked):
            reserved = 0
            for item in ranked:
                if not _is_staff(item):
                    continue
                if _take(item, seen, keep):
                    reserved += 1
                if reserved >= 2:
                    break
        both_styles = any(_is_two(item) for item in ranked) and any(not _is_two(item) for item in ranked)
        if both_styles:
            reserved = sum(1 for item in ranked if _is_two(item) and _name_key(item) in seen)
            for item in ranked:
                if reserved >= 4:
                    break
                if not _is_two(item):
                    continue
                if _take(item, seen, keep):
                    reserved += 1
        for item in ranked:
            if len(seen) >= limit:
                break
            _take(item, seen, keep)
        for band in blist:
            kept = []
            for index, pick in enumerate(band.get("picks") or []):
                if hidden_spell_item(pick):
                    continue
                if pick_is_ranked_weapon(band["slot"], pick) and (id(band), index) not in keep:
                    continue
                kept.append(pick)
            band["picks"] = kept
    return [band for band in bands if band.get("picks")]

if __name__=="__main__":
    cls=os.environ.get("GQ_CLASS","PALADIN")
    only=os.environ.get("GQ_SPEC")
    specs=[k for k in W[cls] if not k.startswith("_")]
    if only:
        if only not in specs:
            raise SystemExit("unknown spec %s" % only)
        specs=[only]
    out={}
    for spec in specs:
        # Stop at 69. Level 70 is deliberately NOT generated: at 70 the things that
        # decide BiS -- gem sockets, tier set bonuses, libram/relic effects, weapon
        # speed breakpoints, phase tier, PvE-vs-PvP intent -- are all invisible to a
        # linear stat-weight model, and Henrik already has professionally curated
        # Phase 3 lists for 70 in Data.lua. Generated picks there would only
        # compete with better data. Measured: 0/44 exact, 0.55/3 overlap.
        # Forever / Classic: stop at 60 (was 69 for TBC Anniversary).
        # Score 1-9 per real spec (not only levelling_1_9) so enhancement/arms/etc.
        # get their own early BiS. Collapse 1-9 and 10-60 separately so a stable
        # top-3 cannot fuse into a band that crosses the talent breakpoint.
        level_ranges = [range(1,10)] if spec=="levelling_1_9" else [range(1,10), range(10,61)]
        out[spec]=None
        for lv in level_ranges:
            per,cfg,notable,full60,source_alts=run(cls,spec,lv)
            if out[spec] is None:
                out[spec]={"label":cfg["label"],"bands":[]}
            slots=sorted({k[2] for k in per})
            bands=collapse(per,("Alliance","Horde"),slots,lv)
            early_band = max(lv)==9
            def emit(faction,sl,lo,hi,rows,origins=None, _spec=spec, _notable=notable, _alts=source_alts):
                # Append source alternates after the existing picks. Ranks 1-3
                # stay the rows this band already chose.
                base_count=len(rows)
                have={r[1]["id"] for r in rows}
                have_names={r[1]["name"] for r in rows}
                merged=list(rows)
                for r in (_alts.get((faction,hi,sl)) or []):
                    if r[1]["id"] in have or r[1]["name"] in have_names:
                        continue
                    have.add(r[1]["id"]); have_names.add(r[1]["name"])
                    merged.append(r)
                rows=merged
                out[_spec]["bands"].append({"faction":faction,"slot":sl,"lo":lo,"hi":hi,
                  "picks":[{"id":r[1]["id"],"name":r[1]["name"],"q":r[1]["quality"],
                            "ilvl":r[1]["ilvl"],"rlvl":r[1]["rlvl"],"req":eff_req(r[1]),"bind":r[1].get("bonding"),"kind":r[1]["kind"],
                            "score":round(r[0],2),"suffix":r[2],"chance":r[3],"chanceAny":r[5],
                            "suffixRange":(r[7] if len(r)>7 else None),"suffixId":(r[8] if len(r)>8 else None),
                            "dps":r[1]["dps"],"speed":r[1]["speed"],
                            "stats":r[4],"src":srcs[str(r[1]["id"])],"seasonal":srcs[str(r[1]["id"])].get("seasonal",False),
                            "effects":r[1].get("effects") or [],
                            "reqSkills":r[1].get("reqSkills") or [],"reqRep":r[1].get("reqRep") or [],
                            "hand": weapon_hand(r[1], sl)} for r in rows]})
                for p in out[_spec]["bands"][-1]["picks"]:
                    if not spec_wants_heal(cls, _spec) and item_is_heal_only({"stats": p.get("stats") or {}}):
                        p["healOnly"] = True
                for p in out[_spec]["bands"][-1]["picks"][base_count:]:
                    p["alt"]=True
                if origins: out[_spec]["bands"][-1]["origins"]=origins
                if sl in ("MainHand","SecondaryHand") and cfg["weaponStyle"] in AMBIGUOUS_STYLES:
                    rt=route_for(per,faction,hi)
                    if rt:
                        out[_spec]["bands"][-1]["route"]=rt[0]
                        out[_spec]["bands"][-1]["routeTwoHand"]=rt[1]
                        out[_spec]["bands"][-1]["routeOneHand"]=rt[2]
            for faction,sl,lo,hi,key,rows in bands:
                if early_band or spec=="levelling_1_9":
                    emit(faction,sl,lo,hi,rows); continue
                if NO_GUIDES or not (lo<=60<=hi):
                    emit(faction,sl,lo,hi,rows); continue
                r60=full60.get((faction,sl)) or per.get((faction,60,sl)) or rows
                ov=guide_override(spec,sl,faction,r60,cls)
                if lo<60: emit(faction,sl,lo,59,per.get((faction,59,sl)) or rows)
                if ov: emit(faction,sl,60,60,ov[0],ov[1])
                else:   emit(faction,sl,60,60,r60[:8])
        out[spec]["bands"] = cap_weapon_bands(out[spec]["bands"])
        print(f"{spec:<16} slots={len(slots):<3} bands={len(out[spec]['bands'])}")
    if _displaced:
        print(f"level-60 guide override: {len(_displaced)} slot(s) where the model beat the guide by >{int(DISPLACE_MARGIN*100)}%")
        for d in _displaced[:14]:
            print(f"    {d[0]:<12}{d[2]:<9}{d[1]:<14}{d[3]} ({d[4]}) displaced {d[5]} ({d[6]})")
    out_path=os.path.join(OUT, os.environ.get("GQ_OUT","paladin.json"))
    if only and os.path.exists(out_path):
        prev=json.load(open(out_path, encoding="utf-8"))
        prev[only]=out[only]
        out=prev
    json.dump(out,open(out_path,"w"))
    print("wrote "+out_path)
