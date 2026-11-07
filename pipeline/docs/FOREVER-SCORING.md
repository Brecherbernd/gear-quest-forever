# Scoring Forever / Classic items

Player-edited stat weights (not built): [CURSOR-NOTE-PLAYER-WEIGHTS.md](CURSOR-NOTE-PLAYER-WEIGHTS.md).

This folder is the **authoring asset**. Players never see it. CurseForge zips
ignore `pipeline/` (`.pkgmeta`). The addon ships `GearQuest/_generated/*.lua`.

## Philosophy: damage, then survive, then endure

Leveling BiS is not a raid spreadsheet. The model answers “what should I hunt
**now** so I kill faster, die less, and keep playing.” Weights apply in this
order of importance. Do not invert them.

1. **Damage first.** The spec primary still leads: Agility for a hunter,
   Strength for arms, spell power for a mage. A hunt that does not make you
   hit harder (or threaten harder, for a tank) is not BiS. Dual-wield rules,
   weapon style, and “does this proc even fire in this slot” stay in the
   damage layer.

2. **Survivability second (through 60).** A naked +1 primary-stat upgrade that
   leaves you squishy loses to a piece with stamina, health, hp5, or armor.
   `weights_at_level()` multiplies sta / health / hp5 ×3 and armor ×2 when
   `level < 61` (`LEVELING_SURVIVE_UNTIL`). Example: at 22, **Brawler’s / Trapper’s Leather Tunic**
   (8 Agi + stam / str / int) beat **Panther Armor** (9 Agi, no stam).
   Leveling is travel, extra pulls, and no healer. Dying costs more time than
   a one-stat edge saves.

3. **Endurance third (through 60).** Staying effective also means having and
   keeping mana. Int / spirit / mp5 / mana ×2 — real, but **less than stam**.
   Paladin seals and heals, shaman shocks, hunter shots, and caster drinks
   all run out. A glass cannon that is OOM every two pulls is not a better
   hunt.

Level **60** uses those same survivability and endurance multipliers. Hit,
crit, and weapon damage stay on the raw weights. `GQ_NO_GUIDES=1` until
Forever guides exist.

The same multipliers live in the addon as `GQ.ScoringLeveling` in
`GearQuest/_generated/ScoringWeights.generated.lua` (from
`pipeline/data/weights.json` via `scripts/generate-stat-weights-lua.mjs`).
Hovering the spec name or icon in the log shows the **effective** weights
for the current level: through 60 the tooltip already includes ×3 / ×2.
If you change `LEVELING_*` in `score.py`, change `GQ.ScoringLeveling` to
match and regenerate that file. `GQ.StatWeights` is still the Compare.lua
reorder table; the tooltip does not read it.

**Jackpot greens are BiS, not an average.** Rank a random-enchant on the
**best suffix it can roll** (top of that suffix’s range). Superior Shoulders
of Agility at 22 is +6–7 Agi (~9.5%). If +7 would be #1, the item **is** #1.
`suffixChance` tells the player the roll is slim; chance never buries the
hunt. Implemented in `score.py` `best_variant` (`ROLL_POLICY="bestRoll"`).

## Rules that stay unless you ask

**Do not change weights unless asked.** `pipeline/data/weights.json`, the
numbers in `score.py` `weights_at_level()`, and
`GearQuest/_generated/ScoringWeights.generated.lua` stay as they are until
you explicitly ask for a retune. A piece ranking first because of an
existing weight is the model working.

**Where to look up a weight change.** The community sheet is
[GearQuest Forever - Class Stat Weights](https://docs.google.com/spreadsheets/d/1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok/edit).
One tab per class (Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman,
Warlock, Warrior), themed with that class's log scene from
`GearQuest/Art/GQ-LogScene-*.png`. The live grid is the raw `weights.json`
row. Do not pre-multiply the leveling bonuses into it. Those cells are
locked so only Henrik can edit them. Anyone with the link can add a row
under **Suggest a change** (name, spec, stat, suggested weight, and why).
Henrik's note column stays locked. A suggestion does not change the addon.
When a suggestion is accepted, copy it into `weights.json` and re-score
that class. Do not retune from the sheet unless asked.

**Custom spec.** The spec menu has a divider, then any custom specs for this
class, then **+ custom stat weights**. The window sits on the log. The name
is at most 20 characters. The player picks which premade spec it is based on,
and the right side lists that spec's weights. The grey number in an empty box,
and the number beside it, is the weight that spec uses through level 60,
including the leveling multipliers. A typed number replaces it, including 0,
with no extra multiplier. A typed Spell power weight scores the Spell Power
stat only. The line "Increases damage and healing done" stays on Healing.
An empty Spell power box still counts that line's damage half as spell power,
which is how the premade list scores it.
**Save and score items!** reorders that spec's existing hunts for every level
band and saves the weights on the account (`GearQuestForeverDB.customSpecs`).
Which spec is selected stays on the character. Right-click a custom spec to
edit it. Delete removes it. The item pool, weapon style, and pins stay the
base spec's. A custom list cannot surface a piece that never ranked for that
class. Stats, weapon damage, armor class, the best suffix, Embrace of
the Viper, and Rotmender's Raiment are scored again. A proc such as
Thunderfury is not re-priced, so it ranks on the printed stats. The stat rows
live in `Data.ItemStats.generated.lua`, written by
`pipeline/scripts/emit_item_stats.py`. The label **Healing as spell power**
is `sp_from_heal`.

While that score runs, a portrait spins on the GearQuest window only. The
shade covers the log, not the whole screen. It stays up through the
slot-by-slot list build and comes down when the hunt list is painted and
can scroll.

Simulating another class and choosing a custom spec for that class scores
after that class's hunts are indexed. **Turn off simulation** scores the
character's saved spec when that spec is custom. After a reload on a
simulated premade spec, a left click on a custom spec selects it. The
header and the spec button use the custom name.

Priest, mage, and warlock ranged damage (`dpsWeightRanged`) is **7**, the
same scale as a warrior's melee weapon. These classes cast, then wand. A
higher-DPS wand is the ranged hunt. **White Obsidian Wand** (274425) is
rank 1 ranged at 39 for mage (including Battle Mage), priest, and warlock
because 7 × 41.47 DPS dominates the slot. Do not lower that weight to bury
the wand. Greater Magic Wand stays the client **17.5** DPS (22–41 Arcane,
+2 spell power, requires 13). Warlock school weights stay as written under
Stat weights: Affliction is shadow, Destruction is fire, Demonology is
generic spell power, and a healing-only line scores as nothing for those
three. Enhancement Tank armor stays **0.20** (0.40 below 60), with one
agility also counting as 2 armor plus dodge and crit.

**A hunt gets a coordinate when one can be found.** Quest start, dungeon or
raid entrance, named creature, vendor, or object. Shared dungeon, farm,
rare, boss, and object pins ignore the faction-zone deny. Do not invent a
pin, a zone center, or a city for a battleground vendor. An Unsourced item
has no pin until a source exists. Ruins of Lordaeron is **Undercity**
(map 1458) at 71.6, 11.4. Patch with
`python pipeline/scripts/index_coordinates.py --ids <json list>`. Do not
full-emit. `emit()` rewrites the whole coordinate file. A source `zone` is
not a pin. The log reads `Data.Coordinates.generated.lua`. A boss drop
whose zone is already a known door still has no **Show on map** until that
file has a row. On 5 Oct 2026, 25 boss drops had the dungeon and no row.
**Embrace of the Viper** (6473 Armor of the Fang, 10410 Leggings, 10411
Footpads, 10412 Belt, 10413 Gloves) now pins Wailing Caverns at The Barrens
46.0, 36.5, the same door as the other cavern hunts. The same pass pinned
Blackened Defias (Deadmines, Westfall 42.5, 71.7), Scarlet chest, legs,
wrists, Mantle of Doan, and Dog Training Gloves (Scarlet Monastery), the
four Gnomeregan boss weapons, Wind Spirit Staff and the two Agamaggan pieces
(Razorfen Kraul), Windshrieker Pauldrons (Stratholme), Emberweave Leggings
(Blackwing Lair), and Ring of Entropy (Lord Kazzak, Blasted Lands 45.3, 55.0).

**A re-score always counts set bonuses.** Embrace of the Viper,
Rotmender's Raiment, and any later `(N) Set` are part of the score for the
specs that wear them. Scoring the pieces on their own stats and skipping
`apply_embrace_package` / `apply_rotmender_package` produces the wrong list.

**Tooltip layout stays the Wowhead line order.** Slot and type are one
double line (`Feet` | `Cloth`), and so are Damage and Speed. The client set
is spliced where the Wowhead set sat. Drop Chance, Requires Level, and
Sell Price stay in the tail. If the stored tip already has `(N) Set`, do
not add the client set again. `Unique-Equipped` splits only when the next
character is not `:` or a space. Random-suffix greens keep the jackpot
tooltip. The hover background is opaque.

**A Wowhead Forever scrape also rechecks Unsourced.** See
[Scraping Wowhead Forever](#scraping-wowhead-forever).

## Embrace of the Viper (set 162)

Forever reworked this Wailing Caverns leather set. The pieces were already
in `items.json` on Classic stats, and the tooltip scrape had 404'd them, so
`forever_missing_ids()` hid every hunt. The 10 Oct 2026 dataEnv 16 tooltip
replaced the 27 Sep chest. **Armor of the Fang** (6473) is now 91 armor,
+3 Strength, +3 Intellect, +10 Spirit, required level 18, and no stamina.
Legs, feet, belt, and gloves did not change. Do not retune weights to
restore the older windows. The chest got worse, so the package stops
winning earlier.

A piece is still scored alone. After the slot lists exist,
`apply_embrace_package` compares two packages in the same point currency:
the set, and the best item already chosen for each of those slots. If the
set wins, those pieces become the hunt. Bonuses, same weights as printed
stats:

- 2 pieces: +10 Intellect
- 3 pieces: +10 Attack Power
- 4 pieces: 100 health (10 stamina) and 100 mana, once per 5 min at 25% health
- 5 pieces: Dream Venom, a 1-second melee stun. Raid stuns stay worth 0 in
  `procs.py` (bosses are immune). This stun is priced as one second of white
  melee at item level 22, because the proc does not grow with the wearer.

DPS specs only: hunter (all three), rogue (all three), enhancement, feral.
Bear, Balance, Restoration, Elemental, and Enhancement Tank are not on it.

Verified windows, both factions (10 Oct 2026, after the chest tooltip
above, with Beast Mastery and Marksmanship melee `dpsWeight` still **0.05**):

- Beast Mastery and Marksmanship: legs, feet, belt, and gloves from 18
  through about 24. **Armor of the Fang is not on the list.** The chest has
  no agility, and Dream Venom is priced at `dpsWeight` 0.05, so the stun is
  almost nothing. Do not force the chest back unless asked.
- Survival: the chest is rank 1 only at 18–21. At 22 it falls off
  (**Brawler's Leather Tunic**, 252508, takes the slot). The other four
  pieces carry the set.
- Combat, Assassination, Subtlety: the package still covers the early
  leather slots. Once it stops, **Blackened Defias Belt** (10402) enters
  the top 3 from 17 and is rank 1 from 22. That is the Fang chest getting
  worse, not a Defias stat change.
- Enhancement: the chest stays forced at rank 1 through 27. At 29 the
  other four leave as well.
- Feral: the chest is rank 1 only at 18–21. At 22 feet and waist lose the
  set share. Legs stay rank 1 on agility.

Gloves (from 14) and legs (from 17) are already hunts on their own stats.
Dream Venom is priced at item level 22, not the wearer’s level, or
Enhancement keeps the chest too long. Feral has no weapon `dpsWeight`; the
stun uses 14 (cat: 1 AP = 1/14 white dps) plus 1 point. Do not drop that
extra point. The 10 Oct chest no longer pays for every slot through 23.

The list tags these rows `(Set piece)`, the same way a proc row is tagged
`(Notable)`. The drop text names the bonuses and the level window for that
class. A druid in all five pieces turns into a serpent (race colors it;
Prowl and Stealth slither). That is flavor on the description, not a stat.

Do not promote a set until the Forever bonus text is known and this package
comparison wins. A single piece is still scored on its own stats. The
package only inserts pieces at rank 1 when the bonuses pay for the slots
you give up. Do not copy a set-bonus line (`+15 Attack Power against
Humanoids`) onto the item’s own stats. `wpnSkill` is 0 on every spec, so
`+1 Daggers` does not move a rank.

**Defias Leather (161),** Deadmines. Forever stats, not the Classic row:
chest is item level 22, requires 17, 89 armor, +4 Strength, +3 Agility,
+10 Stamina. Bonuses: +5 arcane resist, +15 attack power vs humanoids, a
5% behind-only bleed, +1 daggers. Those bonuses do not carry the weak
slots. Defias stats did not change on 10 Oct 2026. For Combat, Assassination, and Subtlety, both factions: legs are a hunt at 14–16, boots at 15–16, and gloves are rank 3 at 14. The chest touches rank 2–3 at 17–19. The belt is in the top 3 from 17 and rank 1 from 22, after Fang stops paying for that slot.

**Chain of the Scarlet Crusade (163),** Scarlet Monastery mail. Bonuses:
+10 shadow resist, +30 attack power vs undead, Enraging Light (20 Holy on
melee, 60 vs undead), +1% hit at 5, and a 480 absorb at 20% health on a
4 minute cooldown at 6. Do not price that absorb as 48 permanent stamina.
Pieces that rank do it on their own stats:

- Retribution: belt 32–36, chest 34–39, legs at 39. Gauntlets are in the
  top 3 at 33–34.
- Arms and Fury: belt 32–39, chest 34–39, legs at 39. Gauntlets are in the
  top 3 around 33–34.
- Protection, paladin and warrior: boots 30–36, bracers 31–35, chest 34–39.

The list tags Defias and Scarlet rows `(Set piece)` on the classes above.

**Rotmender's Raiment (2133),** Ruins of Lordaeron cloth. Five pieces,
requires 17-19. Stats are the Forever tooltip (4 Oct 2026). The chest is
Rotmender's Garb, not Robes: +10 Intellect, healing 11 and damage 4 (10 Oct 2026; the older tip was healing 10 and damage 3). Legs, treads, gloves, and sash did not change.
Leggings are +5 Stamina and +4 mana per 5, not the old intellect and
spirit. Treads are +7 Stamina, healing 15 and damage 5. Gloves are +3
Intellect and +8 Spirit. Sash is +6 Stamina and +6 Intellect. Leggings
drop from The Abandoned, treads from Rath'mael, and the garb has no named
npc. Gloves drop from Stone Watcher. The sash drops from Shrieking Banshee.

`apply_rotmender_package` uses the item-set page. The leggings and treads
tooltips also print an older +10 Intellect at 2 pieces and 5% less threat
at 3. The set page, garb, gloves, and sash do not, so those two lines are
not scored. Bonuses:

- 2 pieces: +5 Shadow Resistance, at the resist weight
- 3 pieces: +10 Intellect
- 4 pieces: 200 mana when mana falls below 15%, once per 5 min. Priced
  like Embrace's 100 mana (the amount, not a permanent aura). The doubled
  restore in Haunted and Wasteland is not in the score
- 5 pieces: a chance to heal 40 every 3 sec for 15 sec. The chance is not
  stated, so one proc is priced as 200 health (20 stamina), not as +200
  healing power

Healer specs only: priest Holy and Discipline, druid Restoration, paladin
Holy, shaman Restoration. A piece is still scored alone. The package
promotes a 4- or 5-piece set only when the bonuses pay for the slots you
give up. Checked 4 Oct 2026, both factions:

- Holy and Discipline: at 18 the chest, sash, gloves, and leggings. At 19
  all five. From 20 the leggings fall off. Chest, sash, and gloves stay
  through 21. The treads stay in the top 3 into the high 20s.
- Restoration druid: all five at 19. On Horde the sash and gloves leave after 19. The chest stays in the top 3 through 21. Treads stay through about 29.
- Restoration shaman: all five at 19. Treads stay through about 29.
- Holy paladin: the treads are rank 6–7 at 17–28. **Acolyte's Boots** (250506), **Wisdom's Leather Boots** (252444), and **Stormrider's Leather Boots** (252443) outrank them. The treads' own stats did not change. The other four do not beat mail and plate.

Smaller sets left on their own stats until the same check: Stormshroud
(rogue energy, about 50), Black Dragon Mail (1% hit at 2 pieces, 2% melee
crit at 3, about 53), Ironfeather (2 pieces, +20 spell power, about 49),
Green Dragon Mail (mana regen, about 47), Imperial Plate (defense, hit,
strength, about 47). Level-60 dungeon sets stay unscored for bonuses.

Set tooltips follow the Wowhead block: the set name and `(0/N)`, one line
per piece, then one line per bonus such as `(2) Set : +10 Intellect.`
The `+N` stays on that bonus line.


**Healing Done is a healer stat.** Holy paladin, Restoration druid, Restoration
shaman, and Holy or Discipline priest score it. Every other spec, including
Elemental, Balance, and Shadow, scores **+Damage Done** as spell power (one
point equals one point of generic spell power) and ignores Healing Done.
School-only damage stays on that school’s weight (Elemental nature is 0.8,
because frost and fire still exist in the kit). Do not add Damage Done and
Healing Done together, and do not count Damage Done twice.

**Three.** Top 3 unique names per slot. There is no notable shelf. A proc, a
jackpot, or a spell-power piece on a physical spec takes whatever rank its
score earns, including rank 4 and later on the rank list. The hunt list
still shows three.

**Warrior Protection is physical.** No spell power / healing weight. A glove
with +SP and +healing (Silvered Gauntlets) ranks on the stamina, armor, and
defense it actually has. Paladin Protection still scores holy/spell threat;
Ret and Enhance stay hybrids.

**Wolfsbane (267369)** is the Horde paladin two-hander from the Diplomatic Incident chain (Danitha Morr, Bandarion Keep, Tirisfal). The quest can be finished at level 20. Wowhead has no Requires Level; the stored level 26 was inferred from item level 31. `client_item_overrides.json` pins required level 20 and Classes: Paladin, so Alliance and other classes do not get it. 25.59 weapon damage is why it is rank 1 for Horde Retribution at 20.

**Enhancement intellect is 0.6 raw.** Mental Dexterity grants 1 attack power per intellect, and the scorer does not convert intellect into attack power on its own. Through 60 the endurance rule doubles intellect, so the lists use **1.2**, just above agility at 1.0. Level 60 keeps that ×2. Do not drop it back to 0.6 at 60. Spell power stays 0.35 for Mental Quickness and Maelstrom. Enhancement Tank is unchanged and still stamina-first.

**Shaman Enhancement Tank is a hybrid**, like paladin Protection: 1h + shield,
stamina / armor / defense first, then Rockbiter melee threat, then Earth Shock /
Lightning Shield spell threat. Not dual-wield (Forever has no shaman DW).
`enhancement_tank` in `weights.json`. No combat log sim — EP only. Do not
retune tankier vs threatier unless asked.

Armor weight is **0.20** (0.40 below 60). A mail shaman has no plate multiplier, so the armor on the piece is a large part of staying alive while questing. One agility is also **2 armor**, **1% dodge per 20**, and **1% crit per 20**. That is added on top of the listed agility weight, using the same armor weight as armor on the item. Through 60, +6 stamina and +4 agility beats +7 stamina. A much larger stamina gap still wins, which is the early-leveling rule. Level 60 keeps the ×3 on stamina. The tripling does not drop off at 60.

**Mage Battle Mage is a caster who swings.** Three specs, same pillars as every
other class: damage, then survivability, then endurance. Stamina is only a
step above frost (`0.15` vs `0.1`) because the build is usually behind a tank.
`battlemage_frost` is the one scored as the hunt; fire and arcane are the same
skeleton with that school in front.

- Damage is frost / fire / arcane spell power, plus a small weapon DPS weight
  (`0.35`, so a swing is real and still loses to spell power).
- **Coldflame Saber** (276631) is mage-only. The hover is the 14 Oct 2026
  dataEnv 16 page: 17–32 damage, 12.25 DPS, +7 Intellect, Durability 90,
  Classes: Mage, requires level 21, and `Equip: Increases damage and healing
  done by magical spells and effects by up to 32.` That sentence is stored as
  heal 32 and damageDone 32, never as two green `+32 Spell Power` /
  `+32 Healing Done` lines. The page says `Equip: Melee attacks deal 98
  additional Fire damage against Frozen targets.` Pinned in
  `client_item_overrides.json`. The 22 Sep nether tip (25–48 damage, 18.25
  DPS, no spell bonus) was the stale one. Do not sync an older cached tip
  back over it.
- The 98 Fire line is every swing while Frozen, priced at 25% of swings for
  frost battle mage and 15% for fire and arcane (`FROZEN_MELEE_UPTIME`).
  Retune if a melee hit breaks the freeze.
- **Blade of Silverlaine** (273637) is the sword Imbue Blade consumes. The
  hover is the 14 Oct 2026 dataEnv 16 page: 17–33 damage, 10.87 DPS, +6
  Shadow Resistance, Durability 80, requires level 21, and `Equip: Increases
  damage and healing done by magical spells and effects by up to 28.` That
  sentence is stored as spell power 28 and healing 28. Do not print two green
  `+28 Spell Power` and `+28 Healing Done` lines. It is not mage-locked.
  Dropped by Baron Silverlaine.
- The log shows the imbued saber. Intellect, spell power, and healing stay
  the normal colors. Only the effect the scroll adds is grey (98 Fire vs
  Frozen). Do not print that effect a second time. Under it:
  `Use: Combine the Blade of Silverlaine and Imbue Blade.`
  Same shape for any later imbue: `Use: Combine the <base weapon> and <scroll>.`
  Register the pair in `CLIENT_IMBUE` (`GearQuest/Data.lua`) and as
  `imbueBase` / `imbueScroll` on the client override. Hovering the grey
  effect still names the scroll.

These rules apply to **every class**. Re-score **one class at a time** after
a rule change. Do not `reemit_all.py` from stale JSON. After a tip sync or
rule change, run `python pipeline/scripts/rescore_hunter_shaman.py` (all nine
despite the name; `GQ_NO_GUIDES=1`). Pass a class name to do one.

**Class lock uses historical set names, then the tip.** Deathmist is warlock,
Virtuous is priest, even when Forever omits `Classes:`. Names only gate class;
stats always come from the Forever tip. `score.py` `family_class_lock` then
`TIP_CLASS_LOCK`.

## Item facts come from Wowhead Forever hunt tips

Ingest **never overwrites** an id that already exists in `items.json`. Classic
pieces that Forever remade (Serpent's Shoulders +9 Agi vs live +5, Marshal's
Chain Legguards +34 Agi and no AP, Jouster's Crest 1051+50 armor) keep stale
stats until you sync.

Scoring reads `items.json`. `foreverAudit.tip` is still stored for class
gates and the random-suffix score. The hunt hover uses the client item
tooltip. GearQuest adds the recommended enchantment, the rank line, and the
score after it. A random-suffix green uses that same client tooltip, which
is the base piece, and one line under it names the jackpot suffix and the
chance. Do not paint the stored Wowhead tip on the hover when the client has
the item. If the client has no such item, the hover shows that stored
tip, and two red lines under it read `Wowhead Forever lists this item.`
and `This game client does not have it yet.` The hunt description says
the same sentence in one line. A hover that is still waiting on the client
says it is retrieving the item. That wait is not the fallback.
An imbued weapon greys the scroll effect when that line is on the tooltip. The parchment adds `Use: Combine the <base> and <scroll>.` The Wowhead fallback adds that combine line too.

**A tip sync that only walks the Forever index is not a tip sync.** Classic
hunt ids (Ghostly Mantle **3324**, Slime-encrusted Pads **6461**) are not in
`index.json`. `refresh_forever_tips.py` must take every hunt id from the
generated class files **and** the Forever index. Skipping an id because it
is below 200000 leaves the old rebuild hover (`+3 Damage Done` / `+9 Healing
Done` instead of the Equip sentence). Do not run `sync_forever_item_stats.py`
to invent green `+N Damage Done` lines from a rebuild string.

`emit_forever_audit.py` `keep_rebuilt_tip` copies the previous audit line for
a random enchant and Greater Magic Wand **11288**. That stored line is what
the score uses for the jackpot roll. The hover is the client tooltip. A
random enchant adds the suffix line under it. Greater Magic Wand stays the
client **17.5** DPS. A quality-2 world drop is not a reason to keep the old
line on the hover.
Heavy Shortbow was still showing classic 17–33 (10.00 DPS) after Forever
had moved it to 10–20 (6.00 DPS). Daryl's Hunting Rifle **2904** is the
Forever gun: 11–21, 6.40 DPS. The classic 18–35 (10.60 DPS) line is a
different item (Blackrock Mace **1296**).

```powershell
python pipeline/scripts/refresh_forever_tips.py
python pipeline/scripts/emit_forever_audit.py
python pipeline/scripts/rescore_hunter_shaman.py
python pipeline/scripts/index_coordinates.py
.\scripts\sync-addon.ps1
```

`index_coordinates.py` is part of the scrape, not a later backfill. A new
hunt id is not finished until that script has stored the full coordinate
list for the item. An existing item is re-indexed only when its places
changed: new droppers, new sellers, a source that was empty, or a quest,
door, or object pin that moved. A stat change, a tooltip rewrite, or a
rename leaves the stored coordinates as they are. When coordinates are
indexed, that is every published camp the pattern under **Map tracking**
keeps, not one pin taken from the page. `NearestCoordinateSpot` then offers
the closest of those spots to wherever the player is standing.

A new hunt also matches the description the other hunts of that source already use. A quest reward from a chain lists every Wowhead series step from the first quest through the quest that rewards the item, then `This quest can be picked up at level N.` The next line is `Recommended to pick this quest up at level M.` M is the item level minus 4, the same wait as Manageable Quests, and it stops at 60. When that quest cannot be picked up until a higher level, M is that pickup level. A missing item level skips that line. A single quest has the pickup line and no step list. A vendor names the seller on the pin, the coin price, and any reputation or honor sentence after the first period. A boss drop and dungeon trash pin the entrance, and a dungeon with an attunement gets the access line. Those two sources also say `Recommended dungeon entry at level N.` N is the item level minus 4, and it stops at 60. A world drop names the creature and the camp. An empty source stays Unsourced. Do not invent a pin, a price, or a chain step.

`sync_forever_item_stats.py` dry-run first. `--apply` only when the parse of
known items is sane (Imperial Plate Helm **18/17** Str/Sta, not 38 from the
set bonus; Lionheart **+20 Hit**; Jouster's Crest **1101** armor).

### Client tooltip wins when Wowhead disagrees

A nether tip is not automatically the Forever client. Do not `--apply` a bulk
tip refresh over an id the client has already contradicted.

Pinned in `pipeline/data/client_item_overrides.json`. `sync_forever_item_stats.py`
and `ingest_forever_wowhead.py` skip these ids. `emit_forever_audit.py` paints
the client tip.

| Item | Wowhead nether | Forever client (22 Sep 2026) |
|------|----------------|------------------------------|
| Coldflame Saber (276631) | 25–48 damage, 18.25 DPS, +7 Int, no spell power, rlvl stored as 24 | 17–32 damage, 12.2 DPS, +7 Int, +32 spell power and healing, 98 Fire vs Frozen, requires 21, Classes: Mage. **30 Sep 2026:** Wowhead now serves the same numbers and prints `Equip: Increases damage and healing done by magical spells and effects by up to 32.` The hover uses that sentence. The hand-written `+32 Spell Power` / `+32 Healing Done` lines were wrong and are gone. |
| Blade of Silverlaine (273637) | 26–50 damage, 16.52 DPS, +6 Shadow Resistance, no spell power | 17–33 damage, 10.87 DPS, +6 Shadow Resistance, Equip spell bonus 28, requires 21. **14 Oct 2026:** the hover is that Equip line. The hand-written `+28 Spell Power` / `+28 Healing Done` lines were wrong and are gone. |

Coldflame is mage-only. After the client stats, it is the mage main hand from
21 until the level-60 raid staves, and it leaves rogue, warrior, and paladin
lists. Silverlaine is not mage-locked; +28 spell power puts it on paladin Holy
and warlock main hands at 21.

**Imbue tooltip.** Printed stats stay the normal colors. Only the effect the
scroll adds is grey. Do not repeat that Equip line from `entry.proc`. Under it:

`Use: Combine the <base weapon> and <scroll>.`

Coldflame: `Use: Combine the Blade of Silverlaine and Imbue Blade.` Register
the next pair in `CLIENT_IMBUE` (`GearQuest/Data.lua`) and as `imbueBase` /
`imbueScroll` on the override. Hovering the grey effect still names the scroll.

**22 Sep index: 3,634.** One new piece ingested: Shapeshifting Sentinel's
Strides (284403), leather feet, level 24, 70 armor, +8 Agility, +16 Attack
Power. Rank 1 feet at 24 for hunter, rogue, feral, and enhancement. Still no
tooltip: Death Prophet Spine (274158), Corsepickers (282012), Slimy Sword
(284702).

**Login chat** is the two welcome lines only. Ring and specialization notices
print when the character crosses that level, then never again on `/reload`.

### Merchant's Favor camps

A lot of the crafted BiS (Brawler's leather, Trapper's leather, Veteran's silvered
mail, Shining / Flame cloth, the enchanting staves and off-hands, the engineering
goggles and belts) is bought as a recipe for Merchant's Favor, then crafted.

| | Horde | Alliance |
|---|---|---|
| Camp | Durotar Supply and Logistics, northwest of the Crossroads in The Barrens | Azeroth Commerce Authority, Three Corners in Redridge Mountains |
| Leatherworking | Pawani | Daniel Stitchsong |
| Blacksmithing | Gor'mak | Stondry Darkhammer |
| Tailoring | Jim'bek | Mivin Shadowweave |
| Enchanting | Beneris | Alynsia |
| Engineering | Fizzlefuse | Fritz Fizzle |

Alchemy (Horde: Apothecary Durelle, Alliance: Nina Surefire) and cooking
(Horde: Aza'bek, Alliance: Kalsey Sanden) stand in the same camps. They do not
make worn gear, so those recipes are not hunt text.

The hunt line is `Crafted with <profession>. You can buy the recipe from <Horde vendor> at <Horde camp>, or from <Alliance vendor> at <Alliance camp>.` The pattern and the crafted piece often use different slot words (Stormrider's Leather Armor and Tunic; Gilded Sandals and Gilded Slippers; Waistcord and Cord). Every piece of those named sets gets the camp sentence (`pipeline/scripts/commerce_camps.py`). Trainer recipes (linen, mageweave, mithril, scorpid, and the rest) stay on the short profession line.

The coordinate for a camp recipe is that vendor, not a capital-city trainer. Horde is The Barrens (map 1413), northwest of the Crossroads. Alliance is Redridge Mountains (map 1433), at Three Corners. The note is `(vendor that sells the recipe)`. One pin per faction.

| Profession | Horde | Alliance |
|---|---|---|
| Leatherworking | Pawani, 49.6, 29.6 | Daniel Stitchsong, 10.0, 72.4 |
| Blacksmithing | Gor'mak, 49.8, 29.6 | Stondry Darkhammer, 10.4, 74.4 |
| Tailoring | Jim'bek, 49.6, 29.4 | Mivin Shadowweave, 10.0, 72.2 |
| Enchanting | Beneris, 49.6, 29.8 | Alynsia, 11.2, 71.4 |
| Engineering | Fizzlefuse, 49.8, 29.6 | Fritz Fizzle, 10.4, 74.2 |

`camp_pins()` in `commerce_camps.py` is the test: the hunt sentence names the camp. A dye word is not enough (Black Mageweave and Golden Scale are trainer crafts). `index_coordinates.py` writes these pins. `enrich_coordinates.py` must not replace them with Stormwind or Orgrimmar.

Index listview rows are not item facts. Veldt is not item facts. A client
tooltip overrides a Forever tip only when it is pinned above. Otherwise the
client tooltip is the fallback when Forever has **no** tip.

### Tip parser pitfalls (nether text is mashed)

Wowhead Forever tips often have no spaces (`1051 Armor17 Block+9 Stamina+50 Bonus ArmorDurability`).

| Trap | Wrong | Right |
|------|--------|--------|
| Set listing / `(N) Set:` bonuses | Imperial Plate Helm 18+20 Str = 38 | `body_only()` cuts at the set header |
| `Restores +4 mana per 5` | miss mp5 | `Restores \+?N mana per 5` |
| `+N Bonus Armor` | 185 Feralheart, or **50** on a 1051 shield | base armor + bonus (185+140=325, 1051+50=1101) |
| `(\d+) Armor\b` | skips `1051 Armor17` (`1` is `\w`, no boundary) | no `\b`; do not take the Bonus Armor digit as base |
| `+20 Hit+28 Crit`, `+9 Defense+60`, `+6 DodgeClasses` | rating dropped | lookahead `+` / `Durability` / `Classes` |
| `re.I` + `(?![a-z])` | `HitDurability` fails (`D` matches `[a-z]`) | do not use case-insensitive letter lookahead |
| Listview armor vs tooltip | PvP 168 vs 128 | trust the hunt tip + bonus armor |
| `+N Damage Done` | ignored | store `damageDone`; `forever_stats()` folds it into SP |

Index listview rows are not item facts. Veldt is not item facts. Unless an id is pinned above, the client tooltip is the fallback only when Forever has **no** tip.

## Hunt tooltip (addon)

Players should see the Wowhead Forever tip, not the client's stale Equip
paragraph.

- **Quality** comes from Forever first (`GetItemQualityForDisplay`). Reinforced
  Woolen Shoulders is **green**, even if `items.json` still says quality 1.
- **Layout:** slot on the left, armor type on the right (`Shoulder | Leather`).
  Same for `Damage | Speed`.
- **Sets:** Wowhead order. Stats, durability, required level, then the set
  name with `(0/N)`, one line per piece, then one line per bonus:
  `(2) Set : +10 Intellect.` Do not tear `+N` onto the next line. The old
  hand-written Viper tip (`Embrace of the Viper(2) Set:` above the level
  requirement) was that bug. `FormatAuditTip` keeps the bonus on the set
  line. A stored tip with real newlines from the nether HTML is the source.
  Client set-bonus overlay only when the bonuses are usable
  (`GetClientSetBlock` / `ApplyClientSetBlock`).
- **No Forever tip** goes to `ShowClientItemTooltip` (`SetItemByID`), then
  `AppendScoredStatLines` from `GQ.Data.scoredStats` for any of armor, str,
  agi, sta, int, spi, sp, heal, ap still missing from that tip. The same
  lines are added to the fact fallback. **Belt of the Stars** (7107) has no
  Forever tip: 117 armor, +6 Strength, +6 Stamina.
  `Data.ScoredStats.generated.lua` must start with `local _, GQ = ...`
  (`GQ` is the addon table, not a global). It loads after ForeverAudit.
- A green random enchant completes on the **full name**, not the base item
  id. `EntrySuffixMatchesLink` compares that name (case-insensitive).
  `of the Bear` is not `of the Falcon`. An exact suffix id is only the
  fallback when the name is not ready. Do not treat a higher suffix id as
  this hunt. `ownedAtLogin` stores the lowercased full name when the link
  contains ` of `, otherwise the item id.
- Keep the Equip sentence `Increases damage and healing done by magical
  spells and effects by up to N`. Store it as healing N and damage done N.
  Do not store that sentence as generic spell power. Premade scoring folds
  damage done into spell power, and a healer also scores the healing half.
  A typed Spell power weight on a custom spec does not. An empty Spell
  power box still folds the damage half, matching the premade list. A green
  `+N Spell Power` line is generic spell power only. Greater Magic Wand
  (11288) is the `+2 Spell Power` line and is not a hunt row. A party line
  (`of all party members`) is not personal spell power. Set bonuses start
  with `(N) Set`, not `Equip:`, and stay on the set block.
  **Stormrider's Leather Pants** (252502) says up to 10 and is stored as
  healing 10 and damage done 10. Elemental Horde, legs, 25–28, stays rank
  3 at 18.22. Restoration Shaman and Restoration Druid list it at 25–28,
  legs, rank 13, score 24.42. Holy Paladin lists it at 25–27, legs, rank
  14, score 35.55. **Totemic Leather Pants** (252446) is the same sentence
  at 7. Blade of Silverlaine and Coldflame Saber stay pinned.

## GearQuest score (tooltip display)

The hunt order is still the stored `pipelineScore`. The number on a tooltip
is a display index only. Do not retune weights so the index and the rank
agree, and do not write the index back onto a pick.

A bag hover must not rebuild a slot it already scored, and it must not call
`GetItemInfo` for an item the client has not already cached. Doing that for
every piece in the slot is what dropped FPS on a bag hover. While item
priming is suppressed, `IsItemDataCached` returns false instead of calling
`GetItemInfo`. `GetEquipSlot` and `GetItemArmorSubclass` return before
`GetItemInfo` when the item is not already cached. `GetSlotRankList` is
cached per slot. `GearScoreContext` keeps every slot scored for this level,
spec, class, faction, and equipped gear, so leaving a slot and coming back
does not scan it again. The context remembers what is equipped, so the
arrow updates when gear changes. Required level on that list is the stored
fact, not a client item query. The first hover of a slot does the scan
once. The line the player sees does not change. The obtain toast does not
use this scan. It compares the item id in the bags to the hunt on the list.

`GearScoreIndex` maps the slot's raw scores onto **0..100**. The best
score in that comparison is **100**. The worst is **0**. One score in
the slot is **100**. The displayed index is clamped and rounded. The scale
is the live level's rank list (`GetSlotRankList`), the notables, and the
equipped piece's raw score (so a worn piece that has aged out of the band
still sits on the same line). Rank text is that piece's place on the list
this character can see: **Rank #N for your level**. A piece the other
faction cannot get is omitted and the numbers close up. Stored
`curatedRank` still orders the list. There is no notable line. Rank #N is only said when the piece is on the list for this level.

The line is inside the item tooltip, after the stats, before any addon
source line. `AppendGearScoreLine` runs before `Show()`, so the dark
backdrop grows to include it. It is not a second tooltip. It is not drawn
on hunt-list rows. It is drawn on:

- the hunt hover
- each line of the (i) slot-rank tooltip (`GearScoreTrail`)
- the character panel, including the upgrade hover (above **World drop**
  and **Left-click to see more details.**)
- chat links and quest-log items (`GameTooltip` and `ItemRefTooltip`,
  plus `TooltipDataProcessor` for items)

Bags, quivers, and ammo are skipped. **General → GearQuest score on
tooltips** is on unless `settings.showGearScore` is false. Off hides the
line on item tooltips and the (i) list. The hunt order does not change.

**Hunts → Recommended gear enchantment** (`settings.showGearEnchant`) is
off until the player turns it on. The checkbox reads **Recommended gear
enchantment**. The hint is **Enable the recommended enchantment line on
gear tooltips**. The gear tooltip then adds one line immediately above the
rank line, including while the score line is off and while simulation is
on. Simulation still replaces the rank line with **Turn off simulation
mode to see your GearQuest Score for this item.** The enchant line uses
the class and spec on screen. Only the words **Recommended enchantment**
are yellow. The rest is white: the formula name, then the effect. A score
of zero draws nothing.

The formula is the best one this level can reach for the spec on screen.
Enchanting formulas, armor kits, and scopes are for every character. You
take a piece to an enchanter. Anyone can apply a bought armor kit or a
scope. The level decides how high a formula is in reach: under 10 the cap
is 75, under 20 it is 150, under 35 it is 225, and after that it is 300.
A formula stored above 300 counts as 300. A kit or a scope also keeps its
own required level, and a kit keeps the minimum item level on its Use
line. An unknown item level leaves those kits off. Wowhead Forever does
not list a tailoring embroidery, an enchanter-only ring enchant, or any
other worn effect that says only one profession can wear it. A formula's
**Requires Enchanting** line is the recipe, not a wearer lock. Necklace
formulas are for everyone. Until a spell says only one profession can
wear it, nothing is hidden for lack of a profession.

Armor on an enchant counts for a tank only: warrior Protection, paladin
Protection, druid Bear, and shaman Enhancement Tank. Every other spec
scores the enchant's other stats and ignores its armor. Hunt scores are
unchanged. Flat stats use the same weights as the hunt, including the
leveling multipliers through 60. A weapon proc is a judgment of what the
effect does. Insight is the healer proc. Revelation is the caster proc.
Recovery, Fiery Weapon, Crusader, Grand Crusader, and Lifestealing are
the melee and tank procs. A flat stat can still win at 60 when the
weights say so.

Wrists, chest, hands, feet, cloak, neck, shield, and weapons have
formulas. Legs take an armor kit. The chest, hands, feet, and legs share
the kits. **Light Armor Kit** is +1 Stamina and +8 Armor. **Medium** is
+2 Stamina and +16 Armor. **Heavy** is +3 Stamina and +24 Armor, requires
20, and goes on items level 15 and above. **Thick** is +4 Stamina and +32
Armor at 30, items 25+. **Rugged** is +5 Stamina and +40 Armor at 40,
items 35+. The Forceful kits add attack power and the Mystic kits add
spell power, on the same armor. **Mystic Rugged Armor Kit** is +6 Spell
Power and +40 Armor, requires 50, and the pattern requires Leatherworking
235. The pattern page's Use sentence that says 75 and 0 is a broken
description. Spell 1254770 says Spell Power +6 and Armor +40.
**Enchant Cloak - Defense** is +30 Armor (spell 13635). **Greater
Defense** is +60 (13746). **Superior Defense** is +70 (20015). A non-tank
still prefers agility on a cloak.

A scope is only a bow, a gun, or a crossbow. The client names those
**Bows**, **Guns**, and **Crossbows**. **Crude Scope** is +1 ranged
damage at level 5, **Standard** +2 at 10, **Accurate** +3 at 20,
**Deadly** +5 at 30, and **Sniper** +7 at 40. A wand, a thrown weapon, a
fishing pole, a ring, and a trinket have no line. The enchant line uses
`GetItemInfoInstant` and does not call `GetItemInfo` on an id the client
has not already cached. A hover down the hunt list must not request every
piece. Rebuilding a tooltip clears the enchant flag with the rank flag,
or the line disappears on the refresh.

Comparison is `index(hovered) − index(equipped)`, rounded. A positive delta
is the green `GQ-ArrowUp.png` and a green **+N**. A negative delta is the
red `GQ-ArrowDown.png` and a red **−N**. The Forever font has no arrows
(they render as `[]`), and `Interface\BUTTONS\Arrow-Up-Up` is a caret, so
the pictures ship with the addon. An empty slot shows the index only. The
same item, or a delta of 0, shows no arrow. Rings and trinkets compare to
the weaker equipped piece only when **both** slots are filled. A free slot
is a fill, not a replacement.

The active hunt list points at the next hunt with the raw pipeline score, not the tooltip index. A slot whose rank #1 the character already has, obtained or worn, shows **- Rank #1 BiS acquired** just after the header (i). Among the rank #1 pieces they do not have, the three largest raw gains are marked **- Recommended** right after the item name, each with its own (i). A filled slot's gain is the rank #1 score minus the worn piece's score. An empty slot's gain is the rank #1 score itself. It is not an index jump from nothing to +100. That piece is recommended only when its score is larger than the best raw upgrade in a slot that already has gear. Talbar Mantle at 11 is a few points. Hammerbone, against the weapon already worn, is the hunt. A long item name truncates so that label stays whole. The hover says: "One of the best upgrades for your level. GearQuest marks up to three rank #1 pieces, the ones that improve what you are wearing the most." A downgrade is not marked. A later rank is never the recommendation. Fewer than three are marked when fewer rank #1 pieces would be an upgrade. Simulation hides both lines. Turning the score off hides the recommendation and leaves the acquired line. The recommendation only shows when that rank 1 is still on the active list: the weapon filter, the hunter ranged filter, the source filter, and the play style. **Rank #1 BiS acquired** still shows when you own that piece even if one of those hides the row.

Each hunt row shows a small item icon immediately before the name, the same height as the row font. A question mark stands in until the client has the icon. Slot headers stay the plus and minus. In the collapse-icon column, every hunt row shows `#N` in faded grey. N is that piece's place on the (i) rank tooltip (`GetSlotRankList`), including `#4` and later when an earlier piece was already obtained. Stored `curatedRank` is not that number: it still counts pieces this faction cannot see. **Leafre's Ring** can be stored rank 2 and still be `#1` on the list. A faction hole closes up, so the list number matches the tooltip.

A quest reward states `This quest can be picked up at level N.` on the line just before Source. N is the stored required level, the same gate the hunt list uses. Skip the line when that level is missing. The line is green when this character (the simulated level, when simulation is on) is at that level or above, and red when they are below. The following line is `Recommended to pick this quest up at level M.` M is the item level minus 4, the same wait as Manageable Quests, never past 60, and at least 1. When that quest cannot be picked up until a higher level, M is that pickup level. A missing item level skips it. That line uses the same green and red. **Replica Crescent Necklace** (281290) recommends 25, because the quest cannot be picked up until 25, which is above the item level minus 4. The pickup line stays the earliest the quest can be taken. A reward from a chain of at least two quests lists the Wowhead series from the first quest through the quest that gives the item, and no later quest. Each step the character has not completed stays in the parchment color and ends with `- not completed yet`. A completed step ends with `- completed` in green. A single quest does not get that list. A boss drop and dungeon or raid trash say `Recommended dungeon entry at level N.` on the line just before Source. N is the item level minus 4, the same wait as Manageable Dungeons, and it stops at 60. The line is green once the viewed level has reached it, and red before that. A missing item level skips it.

A vendor hunt states the price on its own line, `Costs` followed by the same icons the game uses, with the number beside each icon. The number is the price of the seller named on the line when Wowhead's sellers disagree. Gold, silver, and copper use the money-frame coins. Honor uses the faction honor icon when Wowhead lists honor. A mark or other token uses that token's item icon, with the count, when Wowhead lists it. The old sentence `Costs Honor Points and tokens (Marks of Honor).` is left off once that line is present. A rank-named purchase states the required rank on the line just before Source (`Requires Sergeant (Rank 3).`). A reputation requirement is printed for every source that stores one, not only vendors, and the character's standing is green or red the same way. A boss, trash, world, or rare drop in Onyxia's Lair says the lair requires the Drakefire Amulet.

`SanitizeText` decodes Wowhead quest entities before the parchment, the lore, and the tracker draw. `&nbsp;` is a space. `&lt;name&gt;` is `UnitName("player")`, or "you". `&lt;class&gt;` and `&lt;race&gt;` use this character. `&lt;sir/madam&gt;` follows `UnitSex`. A remaining `&lt;...&gt;` emote is the sentence inside it. `commended!Please` gains a space. **Wildhunter Cloak** (16658), The Hunt Completed, is the check.

**Lookup** is the log handle. It searches the loaded class database, 2000 rows a frame, and does not change the hunt selection or the Simulator. The detail parchment is the same hunt detail. A chain of at least two steps is the list in `GQ.Data.questChain`, from the first series quest through the reward. **Thunderbrew's Boot Flask** (744) is 5 steps.

The minimap button center is half the minimap plus 5 (`MINIMAP_BORDER_OUTSET` in `Minimap.lua`).

**General → Window size** (`settings.windowScalePercent`, 100 when nil) is a slider from 100 to 150. Each step is one percent. 100 is the normal log. 150 is half again as tall and wide. The percent uses the same color as the **Window size** label. Dragging updates the percent and leaves the window alone until the mouse button is released, so the frame does not jump under the cursor. A click on the track, or the mouse wheel, applies that step immediately. An old `largeWindow` check still means 150 until the slider is moved. Hunt rows, icons, parchment, buttons, Play style, the filter and its flyouts, the weapon filter, and the spec picker are children of the log and grow with it. Do not set their scale again. The (i) rank list is parented to UIParent, so `ApplyWindowScale` sets that panel to the same scale. The filter click-catcher stays full screen. The tracker, the guide arrow, the toast, the map pins, and item tooltips stay at the normal size.

A hunt hover asks Auctionator for its price lines only when that addon is loaded (`Auctionator.Tooltip.ShowTipWithPricing`). The Forever tip stays. Auctionator appends its own vendor, auction, and disenchant lines. The GearQuest score stays under those. If Auctionator is not enabled, nothing is added.

## GearQuest Index Score bar

When you are not simulating, and the log page is open, the header is a four-section bar instead of "Viewing upgrades for your current level, class and faction". **General → GearQuest score bar** (`settings.showGearScoreBar`) is on unless that setting is false. Off hides the bar and shows that sentence. Simulation and Settings keep their own header sentences. White text above the bar reads **GearQuest Index Score - Collecting feedback on this**.

The fill is the average GearQuest index of every gear slot, then clamped to **0–100**. `GearScoreWornRows` builds one row per slot. Head, neck, shoulder, chest, waist, legs, feet, wrist, hands, back, main hand, and ranged each count once. Finger counts both rings. Trinket counts both trinkets. An empty off hand is left out when the main hand is a two-hand weapon, and Enhancement (`UsesTwoHandOnlyWeapons`) never counts an off hand. Hunter two-hand uses the two-hand list. Hunter one-hand main uses the main-hand list. Rogue main hand uses the main-hand list.

An empty slot is **0** and the tooltip writes **(empty slot)** after that score. A worn piece with no pipeline score is **0**. A worn piece that aged out of the band still has an index, from the nearest same-spec, same-faction band (`EquippedPipelineScore`). The tooltip list shows that same 0–100 number. The line above the list is one sentence: "The average GearQuest index of the gear you are wearing."

Each 25 points is one section. The fill color uses the raw average, before it is rounded for the word: above 75 legendary orange, above 50 epic purple, above 25 rare blue, otherwise uncommon green. The hover word uses the rounded integer: **Below average** (0–25, green), **Fair** (26–50, blue), **Great** (51–75, purple), **Legend** (76–100, orange). The number stays white. The header is yellow **GearQuest Score**, then `N / 100 · WORD`.

Under a blank line the tooltip lists every slot in the average, highest index first. Equal indexes keep the original slot order. The slot name is gold. The item name uses its quality color. **Empty** is grey.

The bar does not tick while you hover it. Hover only draws the rows from the last update. `PLAYER_EQUIPMENT_CHANGED` clears the GearQuest score cache and refreshes the bar on the next tick. If the log is open, the hunt list refreshes too, so **- Recommended** and **- Rank #1 BiS acquired** follow the new gear. Bag updates do not rebuild the bar.

Do not call `GearScoreContext` once per slot to draw the bar. The bar uses `GearScoreWornRows` and `WornSlotIndex`. The score cache keeps every slot scored for this level, spec, and gear, so a bag hover reuses a slot it already scanned. A scan must not call `GetItemInfo` for an item the client has not already cached.

The weapon filter does not move the bar. The main-hand index uses the whole main-hand list, with no hand style applied. The Weapons (i) list uses one scale for both hands. Each weapon arrow compares to the hand that weapon is worn in. An empty hand shows the index only.

Level 60 uses the same survivability and endurance multipliers as levels 1–59. Stamina, health, and health per 5 stay ×3. Armor stays ×2. Intellect, spirit, mana per 5, and mana stay ×2. The index does not flip to a naked primary-stat ranking at 60.

`EquippedPipelineScore` uses the current band first. If the worn piece has
aged out, it uses the nearest same-spec, same-faction band: the highest
`maxLevel` at or below the player, otherwise the soonest band above.
**Slick Deviate Leggings** (6480) last score for Enhancement Horde at 21–23
(7.11) still compare when worn at 27.

`EntryForItemLink` prefers the suffix, then filters to the active band
(exact min and max, not `LEVEL_GRACE`). A chat link then matches the hunt
list. **Kodohide Legguards** (285338) is rank 4 for Enhancement Horde at
25–27 (score 18.52). **Pathfinder Belt** (15347) is the unsuffixed base;
Enhancement ranks **Pathfinder Belt of the Falcon**.

When the hovered piece is gear and it is not the ranked row, say why
(`GearScoreMissText`) instead of leaving the tooltip blank:

- **Only &lt;Name of the Falcon&gt; is ranked for your level.** (one suffix)
- **Not this roll. Ranked for your level: …** (several)
- **Not ranked at your level. Ranked from N to M.** / **Ranked at level N.**
- **Not ranked for &lt;spec label&gt;.**
- **Not ranked for your class.** / **Not ranked for your faction.**
- **GearQuest has no score for this item.** Food, reagents, quest items, trade goods, bags, quivers, and ammo get no line at all.

Simulation mode does not score. The line is **Turn off simulation mode to
see your GearQuest Score for this item.** The Simulator page button says
**Turn off simulation** (148px). The old preview dialog's Reset is unchanged.

A set piece that is `curatedRank` 1, with `setPiece`, whose own stored
score is below another piece in that slot, adds **Rank 1 when you wear
multiple pieces of this set.** Embrace of the Viper inserts each piece at
the front of the slot (`apply_embrace_package`): the score is the piece
plus an equal share of the set bonus, which does not always beat the next
individual piece. Enhancement Horde legs at 25–27: **Leggings of the Fang**
(10410) rank 1, score 20.87, index 94; **Triprunner Dungarees** (9624)
rank 2, score 21.56, index 100. Fang stays rank 1. Do not change the set
promotion or the weights to make those two numbers match.

## Staying smooth

A ding does not build the new list, the paper-doll arrows, and the obtain check on one frame. `PLAYER_LEVEL_UP` warms the query cache one slot per frame, then an idle frame (`WarmQueryCacheAsync` with gap 1). Milestones, the obtain check, and the redraw each wait a frame after that. Paper-doll arrows on a ding are one slot per frame. The previous-level "new" probe idles between slots. The arrows you already have stay up until the new set is ready.

Changing zone, logging in, and opening a merchant rebuild those arrows in the background the same way. Opening the log, changing a filter, or returning to Active, when the rank lists are not ready, keeps the rows on screen and swaps the whole list once they are built. Completed and Removed do not wait. A list that is already warm opens at once. Hovering an item tooltip, and switching class in the Simulator, stay on the frame they already used. Do not slice those.

## Log window

- **Side handles** are Log (gold exclamation), Simulator (gold question mark,
  stem clear of the dot), and Settings (gold gear). Files are
  `GearQuest/Art/GQ-Handle-Log.png`, `GQ-Handle-Simulator.png`, and
  `GQ-Handle-Settings.png`, 64×64, drawn at 36px in the 53px tab. Hover
  shows `GQ-Handle-InnerGlow.png`: a soft gold rim just inside the metal
  edge. It must not halo the icon. Unselected icons are dimmed
  (0.55, 0.50, 0.42).
- **Active, Completed, and Removed** take a faint gold wash on hover
  (0.90, 0.75, 0.28, alpha 0.14). The selected tab keeps the brighter label.
- The status line uses `GameFontNormalLarge`. **Simulation mode:** is
  `|cffe6bf47` (gold 0.90, 0.75, 0.28). The rest of that sentence,
  **Settings**, and **Viewing upgrades…** are solid `1, 0.97, 0.88` with a
  1px black shadow, so the sky art does not wash them out. The spec control
  on that row is larger: icon 22, arrow 30, label width 130.
- **Turn off simulation** on the Simulator page is enabled only while a
  simulation is applied. On your own character it stays grey. The hover says
  you are already seeing your character unsimulated. The button is 148px.
  The older preview dialog still says Reset.
- **Settings** pages are General, Hunts, GearQuest Commands, and Credits.
  Rows highlight on hover (0.62, 0.50, 0.18, 0.55). The selected row keeps
  its gold bar. The page heading is centered. The setting name is the large
  text; the note under it is smaller. Clicking the label toggles the
  checkbox. Hide minimap is `GearQuestForeverDB.settings.hideMinimapIcon`.
  **GearQuest score on tooltips** is on the General page, under the
  background-art row (`settings.showGearScore`, on when nil).
  **Hide upgrade arrows** is under Hunts
  (`settings.hideUpgradeArrows`). It removes the green arrow from the quest
  log, quest giver, loot, and vendors. **Hide chat messages** is on General
  (`settings.hideChat`, off when nil). It stops every GearQuest line in chat,
  including login, obtain notices, errors, and `/gq` replies. The log,
  tooltips, obtain popup, and score bar stay. The General page scrolls when
  the options run past the pane. The chat box reads the saved check whenever
  Settings is shown and writes it on the next frame. **GearQuest Commands** lists each
  slash command with a 1px shadow and the explanation in plain text under it.
- The source filter and a play style apply together with the Weapons filter. Hunt rows, the shield list, and the character-panel bar hide a weapon that fails any of them. The Weapons menu and the hunter Ranged menu list a hand or a type only when something of that kind still passes those two. A box the player turned off stays off when it comes back. Rank numbers and the (i) list stay the unfiltered order, at most 30 weapons in the current band. Changing the source filter or a play style drops the cached weapon hunt rows and does not drop the rank cache. The Off Hand shield and held-item list is cached apart from those weapon rows (`_heldOffHand`). Drop that cache in the same pass, or a Boss drop filter keeps the world-drop shields from the previous filter. If the parchment is open on a hunt the filter or a play style just hid, close it. The green arrow stays on the unfiltered best piece when the weapon filter hides it. The paper doll follows the weapon filter, including hunter, rogue, and enhancement. Toggling a weapon checkbox clears the paper-doll upgrade cache. Do not clear that cache on every refresh.

The source **Filter** closes on a click outside the menu. The Profession
  flyout closes when the cursor leaves both the row and the flyout. Boss drop
  has the same flyout, but only for dungeons that have a boss-drop hunt in
  the current level window, including ranks below the top 3. Dungeon & Raid
  trash has the same flyout for trash hunts in that window, and those boxes
  are separate from Boss drop. Hall of Thanes and The Stockade are inside
  Alliance cities. Ragefire Chasm and Ruins of Lordaeron are inside Horde
  cities. Those hunts are on both faction lists. **Their Cities** hides the
  other faction's city dungeons. Alliance hides Ragefire Chasm and Ruins of
  Lordaeron. Horde hides Hall of Thanes and The Stockade. Boss drops, trash,
  rares, and quest rewards filed in that dungeon follow the play style. A
  piece filed in another dungeon stays. Rank numbers stay the unfiltered
  order. The flyout still lists a dungeon that has a hunt in the band.
  Excavation Site stays on both. Other is bosses
  that are not in an instance. The flyouts do not scroll. A cleared box
  stays cleared. Select all / Deselect all on the filter menu covers the source
  list and the profession, boss, trash, vendor, and quest sub-filters. Quest reward
  opens Regular quest and Dungeon quest. A dungeon quest is one that sends you
  into an instance, the same test as No Dungeons. Unchecking Quest reward hides
  both. Unchecking one box hides only that kind. Each of those
  flyouts has the same button, and it covers only the boxes on that flyout. Menu text uses the Filter button's font.
  Each main-list row draws the source icon after the checkbox and before
  the name, 18px, the same art as the world-map pin. The Quest reward flyout
  shows the yellow exclamation on Regular quest and the client's dungeon-quest
  icon on Dungeon quest. Other flyout rows keep the chevron and do not get an
  icon. The row's hit width includes the icon.
  Each hunt row draws that same picture at the right, 14px, alpha 0.7
  (`row.sourceMark`). Hovering it names the source. A click still selects
  the hunt, and the mouse wheel still scrolls the list. Unsourced is
  `GearQuest/Art/GQ-Unsourced.png`, the orange circle.
  Checking Profession, Boss drop, Dungeon & Raid trash, Vendor, or Quest reward opens that flyout
  on the click. You do not have to leave the row and come back.
- **Play style** is the button at the bottom of the log
  (`GearQuestForeverDB.ui`). While any of the eight is on, the button reads
  **Play style***. Eight cards, names under the pictures, three then three,
  then **Focus Zone** under **Manageable Dungeons** and **Their Cities** under
  **Manageable Quests**. **Get it now!** can be on
  with either dungeon card, and with **Manageable Dungeons**, **Manageable Quests**, **Buy it**, **Focus Zone**, and **Their Cities**.
  **No Dungeons!** and **Dungeon Enjoyer** turn each other off. A play
  style hides hunts across several sources. The filter still only chooses a source. Any of them widens the slot list the
  same way a filter does, so a later rank can show, and the rank box says why.
  The green arrow on the quest log, quest giver, loot, and vendors is on
  both lists. The unfiltered best pieces keep it when a filter or a play
  style hides them. Every hunt still on the list keeps it too, including a
  later rank, a notable, or a tracked hunt that the filter left showing.
  - **No Dungeons!** (`playNoDungeons`) hides a hunt that sends you into a
    dungeon or raid. Dungeon and raid trash always goes. A boss drop goes
    unless `BossDungeonKey` is **Other** (a world boss stays). A profession
    craft stays. A world drop stays, even when its zone is a dungeon or
    raid name or the pin is that entrance. **Melrache's Cape** drops from
    Captain Melrache in the outdoor graveyard, and the stored zone is
    Scarlet Monastery. A quest goes when its instructions or quest name contain a
    catalog dungeon, or when the pin note says `entrance to dungeon`. The
    match is the catalog spelling, case-sensitive: **Whelgar Excavation
    Site** is not **Excavation Site**. **the Deadmines** is not **The
    Deadmines**, so Underground Assault stays. **Ahn'Qiraj** is not **Ruins
    of Ahn'Qiraj** or **Temple of Ahn'Qiraj**, so Genesis Helm and Savior
    of Kalimdor stay.
  - **Dungeon Enjoyer** (`playDungeonEnjoyer`) is that same test, kept
    instead of hidden. The list is dungeon and raid bosses, trash, and
    quests that enter an instance. World bosses, crafts, vendors, and
    outdoor hunts stay off. The Deadmines and Ahn'Qiraj misses above stay
    off this list too, because they fail the same match.
  - **Get it now!** (`playGetItToday`) hides a hunt this character cannot
    get yet. Reputation uses the standing stored on that item (`reqRep`).
    A bind-on-pickup craft waits until the character has that profession
    and the recipe skill. A bind-on-equip craft stays, unless the item
    itself requires the profession to wear (`reqSkills`). Reaching the
    standing or the skill shows the hunt without turning the style off.
    If the reputation scan fails, reputation hunts stay. A bind type that
    is still unknown does not hide the craft.
  - **Manageable Dungeons** (`playManageableDungeons`) hides a boss drop,
    and dungeon and raid trash, until the viewed level reaches 4 under
    that item's level (`ilvl` on the fact). The same floor as Manageable
    Quests: an item of level 49 can show from 45, and the floor is
    `min(ilvl - 4, 60)`, so a raid drop with a higher item level still
    shows at 60. A missing item level stays. Quests, vendors, crafts, and
    world drops stay. Replaces **Don't look back**.
  - **Manageable Quests** (`playManageableQuests`) hides a quest reward
    until the viewed level reaches 4 under
    that item's level (`ilvl` on the fact). When the quest cannot be
    picked up until a higher level, the wait uses that pickup level.
    Sprightring Helm is 49, so it
    stays hidden until 45. Clergy Ring is 22, so a level 13 list hides it
    and it can show from 18. The floor is `min(ilvl - 4, 60)`, so Cloak of
    the Fallen God (item level 88) still shows at 60. A missing item level
    stays. The hunt still leaves when its band ends. Boss drops, vendors,
    and crafts stay.
  - **Buy it** (`playBuyIt`) keeps a vendor or auction hunt, and any item
    that is not bind on pickup or quest-bound (bind when equipped, bind
    when used, or no bind). Bind on pickup stays hidden unless a vendor
    sells it. An unknown bind stays. **Get it now!** still hides a vendor
    piece until the stored standing is met.
  - **Focus Zone** (`playFocusZone`) keeps a hunt only when the zone the
    character is standing in is that hunt's zone or one of its spots.
    Quests, vendors, crafts, world drops, and dungeon drops all follow.
    A hunt with no place stays hidden. Changing zone keeps the current
    rows and builds the new zone one slot per frame, with an idle frame
    between slots, then swaps the list once. The art is
    `GearQuest/Art/GQ-Play-FocusZone.png`.
  - **Their Cities** (`playTheirCities`) hides hunts filed in a dungeon
    inside the other faction's capital. Alliance hides Ragefire Chasm and
    Ruins of Lordaeron. Horde hides Hall of Thanes and The Stockade. The
    test is the stored zone, or `BossDungeonKey` when that key is one of
    those four names. Boss drops, trash, rares, and quest rewards filed
    there go. A piece filed in another dungeon stays. The rows stay in the
    scored lists, so the rank number does not close up. The art is
    `GearQuest/Art/GQ-Play-TheirCities.png`.
- **Rank on the parchment.** Above the item title, a black box reads
  `Rank #N` from that piece's place on the rank list this character can
  see. A hunt the other faction cannot get is left out and the numbers
  close up, for every class. A source filter or a play style does not
  change that number. A notable with no stored rank uses the scored twin
  in that slot (same item and minimum level). Hovering the box says this
  is the best, 2nd, 3rd, or 4th in that slot for a hunt on the unfiltered,
  no-play-style list. A hunt that is not on that list uses the same place,
  then one sentence: a filter is on, a play style is on, or both. Rank 1
  says **best**, not
  "1st best". Hunter and Enhancement two-hand say **Two-hand**. A hunter
  main-hand-only weapon says **Main hand**. The box watches the mouse
  itself. A frame inside the parchment scroll child often never receives
  OnEnter.
- Shift-click on a Blizzard map pin still inserts the chat link. Do not call
  `CopyToClipboard`. Open the map with `C_Map.OpenWorldMap`, not
  `ShowUIPanel` or `WorldMapFrame:SetMapID`. The close button is anchored
  `TOPRIGHT` **-6, 1**.
- **Scrollbars** on the hunt list and the parchment sit just outside the
  scroll frame, as children of it. `SetClipsChildren` on that frame hides
  them. Do not clip `GearQuestLogListScrollFrame` or
  `GearQuestLogDetailScrollFrame`. The ScrollFrame already clips its scroll
  child. The bar still hides when the content fits.
- **Remove background art** sits under Hide minimap icon.
  `GearQuestForeverDB.settings.hideLogArt`. Unchecked by default, so the
  class scene is on. Checked restores the plain brown log and the solid
  list fill.

### Class identity scenes

One backdrop per class, `GearQuest/Art/GQ-LogScene-<Class>.png`. `SetTexture`
must include `.png` (without the extension WoW looks for `.blp` / `.tga`).

Only the class you are playing or simulating is `SetTexture`'d
(`LOG_SCENE_TEXTURE` / `LogSceneTexture`). The other eight stay on disk.
Shared overlays, not per class: `GQ-LogScene-Vignette.png` (corner shadow)
and `GQ-ListShade.png` (list darker on the left). Parchment alpha is
**0.72** while a scene is showing.

Do not stretch a scene to the window. The log is 768×512 and the pictures
are wider. `ApplyLogSceneCrop` center-crops using `LOG_SCENE_SIZE` (the
file's real pixels) against the texture rect (frame size minus 2px). A
circle in the art stays a circle. Folder exports are **1024×572** except
**Rogue 1024×559**. Shaman stays the existing **1024×512** file. Do not
replace it with the folder `Shaman.jpg`. Export is color **0.58** and
brightness **0.90** on the native pixels. No non-uniform scale.

`ApplyBlackBackground` calls `SetColorTexture` on `listInset.blackBg`, which
is the same texture as the list shade. `UpdateLogScene` runs after that and
must `SetTexture` the shade again every time a scene is showing. A
"already loaded" flag leaves the list solid black.

### Simulator class rows

The nine class buttons fill `simClassInset`. That frame keeps the same
anchors as the parchment. No scroll. Rows share the inner width (10px pad,
1px gap). The "Classes" title is hidden.

Each row is a center horizontal band of that class's scene
(`ApplySimClassRowCrop`), full width of the picture, top and bottom cut so
the band matches the row. `GQ-ClassRowShade.png` darkens the left (about
the first two-thirds) so the class-colored name reads, and the right side
of the art stays clear. Names use `QuestFont_Super_Huge`.

Those nine files load only while the Simulator tab is open and
`hideLogArt` is off. Leaving the tab clears the textures.

**Do not scan the live client for new items.** `Collector.lua` is gone. Do not
hook `TRAINER_SHOW` / `TRAINER_UPDATE`, call `SetTrainerService`, rebuild the
BiS cache when speaking to a profession trainer, or walk every trainer recipe.
That path exceeded the Lua execution time limit (~90 times) and froze the
client. Item facts come from Wowhead ingest only. BiS arrows still paint on
loot, vendors, quests, and the player's own trade-skill window — not at a
trainer NPC.

## When you find a new or retuned item in Forever

Do not hand-edit generated Lua as the long-term fix. Do not hand-edit
`items.json` stats when a Forever hunt tip exists — sync from the tip, then
re-score the class, then copy Lua back.

1. **Item facts** — add or edit `pipeline/data/items.json` keyed by item id
   (string). Copy a nearby item of the same slot and fill:

   | Field | What it is |
   |---|---|
   | `id`, `name`, `slot`, `kind`, `inv` | Identity and inventory type |
   | `quality`, `ilvl`, `rlvl` | Quality, item level, required level |
   | `cls` / `sub` | Item class / subclass (armor, weapon, …) |
   | `allowClass`, `allowRace` | Bitmasks (`-1` = anyone) |
   | `stats` | Named stats the scorer weights (`str`, `agi`, `spFire`, …) |
   | `dps`, `speed` | Weapons only |
   | `effects`, `procs` | Tooltip lines; procs.py prices `Chance on hit` / `Use:` |
   | `randomEnchant` | `true` if it rolls a suffix |

2. **How to get it** — same id in `pipeline/data/sources.json`:

   ```json
   {
     "sourceType": "quest_reward",
     "instructions": "One or two sentences the log can show.",
     "zone": "The Barrens",
     "npc": null,
     "questName": "Quest title",
     "profession": null,
     "dropChance": null,
     "alts": [],
     "gateLevel": 18,
     "questClasses": 0,
     "questRaces": 0,
     "seasonal": false,
     "obtainable": true,
     "excludedBecause": null
   }
   ```

3. **Pool** — append the numeric id to `pipeline/data/classic_item_ids.json`.
   `score.py` only considers ids in that list (TBC/Outland stays out).

   Forever-only items (id ≥ 200000) come from Wowhead `/forever/items`:

   ```powershell
   node scripts/scrape-forever-wowhead-items.mjs
   python pipeline/scripts/ingest_forever_wowhead.py
   ```

4. **Random green?** — scrape Classic/Forever suffix tables, then convert:

   ```powershell
   node scripts/scrape-classic-random-enchants.mjs --ids 12345
   node scripts/convert-classic-random-to-pipeline.mjs
   ```

   Era fingerprint: Vice Grips **9640** must stay **+17 Strength @ 9%**.

5. **Re-score** with the Forever model. One class at a time. `GQ_NO_GUIDES=1`
   is set inside the script. It writes `pipeline/out/` and copies the Lua
   into `GearQuest/_generated/`.

   ```powershell
   python pipeline/scripts/rescore_hunter_shaman.py HUNTER
   .\scripts\sync-addon.ps1
   ```

   All nine classes is the same command with no class name. Do not
   `reemit_all.py` from stale `pipeline/out/*.json`. Do not run a bare
   `score.py` plus `payload.py` plus `emit_early.py` for a Forever list.

   After a Classic `score.py` regen, do **not** run `apply-classic-random-enchants.mjs`
   (that tool patches TBC-scored Lua). Suffixes already come from Classic
   `items_random.json`.

6. **Profession recipe skill.** Do this for every new hunt whose source is
   profession, and again whenever an existing indexed hunt with a profession
   source is updated. The old sentence `requires skill 1` is not a lookup.

   ForeverDB `https://foreverdb.net/data/crafting/{itemId % 64}.json` stores
   `made` as `[profession, spellId, skill, name, count]`. The Wowhead Forever
   item tooltip does not carry the recipe skill. The spell page does:
   `Requires Leatherworking (40)`. When Wowhead is up, confirm the stored
   skill against that line.

   ```powershell
   python pipeline/scripts/fetch_craft_skills.py
   ```

   That rewrites `GearQuest/_generated/CraftSkills.generated.lua` for every
   profession hunt. A skill of 1 is real when ForeverDB and the spell page
   say 1 (Linen Cloak, Copper Bracers, the first leather kits). Do not
   invent 1 when both are empty. Dress Shoes (6836) has no recipe, so the
   parchment line stays off.

Python 3.12 is installed on the authoring PC.

## Levels 1–9

Every class is scored for levels 1–9, both factions, one list per spec. Paladin and warrior used to be the exception. Alliance had one shared hand-written mail list in `Data.lua`, and Horde had `Data.Paladin.Horde.1to9.generated.lua` and `Data.Warrior.Horde.1to9.generated.lua`. Those files and that list are gone. Do not put them back.

The emitter is `emit_early.py` with `GQ_FACTIONS=Alliance,Horde`. `reemit_all.py` and `rescore_hunter_shaman.py` use kind `early` for all nine classes. Do not run `emit_horde19.py` for paladin or warrior. The tables are `paladinEarly1to9` / `paladinEarly1to9Facts` and `warriorEarly1to9` / `warriorEarly1to9Facts`. `GetItemFact` reads those fact tables. A nil `paladinHorde1to9Facts` is not a source.

`Data.lua` is not a leveling catalog. The rows left there are Forever pins (`foreverDelta`) for shaman, hunter, druid, priest, mage, warlock, and rogue. Paladin and warrior do not have those pins. Do not add a hand-written 1–9 band for any class.

Retribution Alliance main hand: **Northshire Hammer** (248005) is rank 1 from 1 through 5, **Empyrean Greatsword** (263407) at 7 and 8, **Ironforge Greathammer** (279895) at 9. Holy Alliance at 8–9 is **Thornroot Club** (5587). Horde Arms main hand: **Rusty Cutlass** (270001) from 1 through 4, **Goblin Smasher** (4964) at 5, **Riptear's Cleaver** (286742) at 6. Back at 1–2 is **Linen Cloak** (2570) for Retribution Alliance and for Arms Horde.

## Guide memory

`HideGuide` always clears `frame.entryId`. A hidden frame still runs OnUpdate, and a leftover id kept sampling the map after Enable Guide was cleared. `collectgarbage("collect")` runs once, only when the frame was shown, after the aim and crossing tables are cleared. It does not run while the guide stays off. Do not add a background position poll. That is what used to climb memory, and it is why a proximity alert stays off.

## v0.6.1 facts

Premade spec hover uses `playerLevel <= untilLevel`, the same test custom specs already used. Level 60 shows the ×3 / ×2 weights. Do not retune so the hover matches an old raw row.

`drop_faction.json` keeps a drop on the side that can attack the dropper when every Wowhead reaction is friendly to one faction and hostile to the other. Dun Garok Rifle (282710), Humbert's Helm, Humbert's Chestpiece, and Circlet of the Order are Horde only. Opportunistic Education is Horde, so Solid Gold Band (279845) and Larcenist's Belt (279846) stay off the Alliance list. Friend of the Library is 10 books and Greater Friend of the Library is 20. Both factions turn them in: Garion Wendell in Stormwind, Owen Thadd in Undercity.

Ashbringer (13262) is a quest reward. Do not invent a quest name for it. Sulfuras (17182) is a boss drop from Ragnaros, and the description says you also need the Sulfuron Hammer. Nature's Whisper (20645) is A Terrible Purpose, required level 54, pinned in Silithus. Crown of the Fire Festival (23323) is not a hunt.

Lookup searches the loaded class, both factions. The index is released when you leave the Lookup tab. Closing the log while that tab is still selected keeps it.

## Three picks per slot

Generated lists should **aim for three items in every slot at every level**. A rank 2 or 3 that is a lower-`rlvl` leftover is still a hunt — show it. Empty bands (Horde enhancement Trinket 20–27 before the WSG rune fix) mean the pool was gated out, not that the player should see a blank slot.

`score.py` already considers every eligible item with `rlvl` ≤ the character level. If a slot still has fewer than three picks, chase **source/faction/class gates** and **Wowhead coverage**, then re-score. Do not hand-edit generated Lua as the long-term fill.

## Shared-ID Warsong Gulch runes

`21565`/`21566` Rune of Perfection and `21567`/`21568` Rune of Duty are sold by **both** WSG quartermasters under the **same item IDs**. They are not Alliance-only.

In `pipeline/data/sources.json` those four rows must have `npc: null` and `zone: null`. Instructions name both vendors (Illiyana at Silverwing Grove, Kelm at Mor'shan Base Camp). If `npc` is Illiyana, `npc_ok` + `npc_faction.json` drops every Horde pick and the first Horde trinket becomes Defiler's Talisman **21120** at 28.

Forever nether tooltips have no class restriction — set `allowClass` to `-1`. (A leftover negative mask excluded shaman/druid from Duty.) Unique-Equipped: Rune of Battle (1): list both as alternatives.

After changing those sources, re-score **all nine classes**, not only shaman.

## Re-scrape Wowhead as Forever fills in

The Forever catalog is not finished. Plan **many** scrape → ingest → re-score passes over the coming months:

```powershell
node scripts/scrape-forever-wowhead-items.mjs
python pipeline/scripts/ingest_forever_wowhead.py
python pipeline/scripts/refresh_forever_tips.py
python pipeline/scripts/index_coordinates.py --ids pipeline/data/forever_wowhead/coord_needed.json
node scripts/diff-veldt-wowhead.mjs
```

Then `score.py` one class at a time (`GQ_NO_GUIDES=1`) and copy the emitted Lua into `GearQuest/_generated/`. Ingest does **not** overwrite a source that already names a quest, vendor, drop, or profession. A row whose text is still `Source not listed yet` is replaced when the new listview names one, and that id is written to `coord_needed.json` so the coordinate lookup runs for it. New Forever-only ids (≥ 200000) merge in the same way. Stats on those rows come from the refreshed nether tooltip, not the listview.

Every id that scrape adds is indexed in that same pass with `index_coordinates.py --ids`. An existing id is indexed when its places changed (new droppers, new sellers, a source that was empty, or a pin that moved) and whenever its quest, source, or faction is updated. A stat change or a tooltip rewrite leaves the stored coordinates as they are. Updating an item's quest or faction without a pin is incomplete: the same pass runs `index_coordinates.py --ids` for those ids. The pin is the start of the first quest in the chain, not the reward step. When the index does run, it stores the full camp list for that item, not one coordinate. A world drop keeps a published camp in each zone its creatures live in (up to three when they are far apart, plus a dungeon entrance when a dropper is inside). A vendor keeps every NPC who sells it. The log, the guide, and the map pin then use the spot closest to the character, so a player in any zone is sent to a nearby farm or seller.

Quest Side is the word after `Side:` (`Alliance`, `Horde`, or `Both`). Do not read the end-NPC icon. A both-faction quest gets one pin per faction (Friend of the Library: Garion Wendell in Stormwind for Alliance, Owen Thadd in Undercity for Horde). An Alliance-only quest never scores or displays for Horde, and the reverse. `index_coordinates.py --repair-quests` rewrites those pins and `quest_faction.json`.

`diff-veldt-wowhead.mjs` is **not** a second ingest. It diffs the Wowhead cache against [veldt1 wowf-items](https://veldt1.github.io/wowf-items/) (client `1.60.1` vs `1.15.9`) and writes `pipeline/data/forever_wowhead/veldt_wowhead_diff.json`. Use that to chase empty tooltips and missing Wowhead pages; do not copy veldt stats into `items.json`.

Hunt-id probe (`pipeline/scripts/probe_forever_hunt_tooltips.py`) labels 200 vs 404. Missing classic ids are pruned at runtime; existing items with no combat stats get the datamine notice.

**19 Sep 2026 scrape:** 3,245 → **3,586** Forever items. Ingest **+316** pool ids. All nine classes × every spec re-scored and copied into `GearQuest/_generated/`.

**20 Sep 2026 scrape (morning):** index still **3,586** listview rows. `diff_forever_index.py` found **25** ids in the index that were missing from `items.json` (ingest **+24**; Wildstalker's Helm **280898** 404). Mid-level rares that made a list after re-score: **Silvered Gauntlets** (270025), **Cultist's Armguards** (270032), **Dark Ritual Leggings** (270031). Ilvl-65 set pieces (Manaflare, Grimstitch, Wildstalker, Conviction, Spiritcaller) were scored and did not beat existing 60 lists. `clean_source_instructions.py` rewrote world / quest / vendor / drop copy (no “364 creature types”, zone/NPC live in fields). Hunt parchment no longer dumps the mashed Forever audit tooltip; `QuestFont` was eating spaces — body/title use Friz (`GameFontNormal`). **Source** always prints.

**20 Sep 2026 scrape (evening) + tip sync:** index **3,621** listview rows, **0** new Forever remakes vs the morning catalog. Scoring `items.json` was still Classic/TBC on ~640 hunt pieces. After parser fixes, `sync_forever_item_stats.py --apply` brought those in line (0 dry-run mismatches). Hunt list **3,876** unique ids: **3,858** Forever tips, **18** Classic 404s still on lists (Ten Storms shoulders, Drillborer Disk, Amberseal Keeper, Eskhandar's Left Claw, Will of Arlokk, Staff of the Ruins, The 1 Ring / Woven Copper Ring, and a few unnamed early whites). Historical audit cache still has ~1,500 old 404 rows; current hunt count is the one that matters. Enhancement Tank scored 1–60 with the other shaman specs.

**21 Sep 2026 scrape:** index **3,625** (+4 vs 20 Sep evening). New held-in-off-hand greens: Gnawed Bone (282654), Apothecary's Concoction (284668), Kobold Firestarter (285192), Bael'dun Tankard (286541). Mage / priest / warlock / druid / shaman / paladin re-scored; none beat existing offhand top 3 (mage 22 is already ~6.4 EP). Hunter / rogue / warrior skipped — held offhands are gated once they can dual wield. Live client: Collector removed; class-trainer hooks disabled after a freeze on `TRAINER_UPDATE`.

**23 Sep 2026 scrape:** index **3,637** (same count as 22 Sep; six ids rotated into the list). Ingest **+6** pool ids after fetching missing tooltips. **397** nether tooltips re-fetched where the listview armor/DPS no longer matched `items.json` (mostly PvP / rank-set pieces). Re-ingest merged stats; `client_item_overrides.json` pins untouched. All nine classes × every spec re-scored. New pick on lists: **Death Prophet Spine** (274158) Enhancement shaman MainHand @ 26. Other new ids (274042 belt, 282012 hands, 282019 neck, 282658 back, 284702 sword) scored but did not take top-3 yet.

**27 Sep 2026.** Spec picker is no longer session-only. A manual pick is stored on `GearQuestForeverCharDB.specPick` and survives `/reload`. Talent tree (most points) is used only when this character has not picked a spec. Simulation preview still has its own spec.

**Jewelry and held items with kind `?` do not score.** Wowhead Forever subclasses: neck `-3`, finger `-2`, trinket `-4`, cloak `-6`, held `-5`. `ARMOR_SUB` maps those to `Misc` for **new** rows. Ingest does **not** overwrite `kind` on an id already in `items.json` (`kind` is not in the update field list). Do not mass-edit the leftover `?` rows. Hand-patched only:

- **Snake Eye Kaleidoscope** (273088) neck, `kind` Misc, +1 str/agi/sta/int/spi and `resist` 5. Boss pin: Lady Anacondra, Wailing Caverns. On neck lists from req 17 (level 20 Enhancement Tank Horde: rank 2 behind Scout's Medallion).
- **Heart of Alterac** (283254) held, `kind` Misc. Limited top-3 only (Guardian around 34–39, Destruction and Arcane Battle Mage at 34). Source still unknown. Do not invent a drop.

**Boss pins** live in `pipeline/data/forever_boss_sources.json`. `apply_pinned_boss_sources` runs after `source_from_row`, which would otherwise clear zone and instructions on every id ≥ 200000. A later ingest must keep that call. Ruins of Lordaeron: Witherfang, The Baron, Viktor the Vile, The Abandoned, Bjork, Rath'Mael. Hall of Thanes: Faldrim Anvilmar, Magmatus, Plunder, Durgen Dirgehammer. Kaleidoscope is on the same pin list. Wowhead renamed **Rotmender's Leggings** (271207) and **Rotmender's Treads** (271214).

**Coldspire Staff** (271215) is Rath'Mael's drop, required level 19. The Forever tooltip is +13 Frost Resistance and +32 frost spell damage. It does not have the old "damage and healing by up to 26" line. Drop chance 29.69%. Frost, both factions, stays rank 1 at 19 (score 29.83). Enhancement Alliance 19-20 is rank 23 (score 272.78). Priest, druid, and warlock were re-scored without that healing and generic spell-damage line, and the staff left their lists.

**Coldflame Saber (276631)** is on the same pin list: `boss_drop`, Baron Silverlaine, Shadowfang Keep. It was `world_drop` with "Source not listed yet" because the listview names no source. The Blade of Silverlaine it is made from drops there too. The log description adds `Use: Combine the Blade of Silverlaine and Imbue Blade.` The hover is the client tooltip, and that combine line is added on it. A re-score reads the pin from `sources.json`, so the generated mage file does not need a hand edit after one.

**Faction zone pins** live in `pipeline/data/forever_faction_zones.json`. `apply_pinned_faction_zones` sets `zone` only. `zone_ok` is what gates the faction; quest text that names Stormwind does nothing if zone is null. Stormwind City and Teldrassil are Alliance. Thunder Bluff is Horde. Wailing Caverns is both.

- 279868 Duty Bound Leggings, 279869 Remembrance Armor → Stormwind City (Bloodied Insignia, General Marcus Jonathan). Horde must not see them.
- 281250 Forest Oracle's Cloak → Teldrassil. `kind` is `Misc`, so it can score.
- 270008 Heat Resistant Mitts, 270009 Safety Boots → Thunder Bluff (Serpentbloom, Apothecary Zamah). Alliance must not see them. Instructions may still mention Wailing Caverns; the displayed zone is what gates.

**Clicks.** Do not parent a fullscreen mouse catcher to `UIParent`. `GearQuestPopupDismiss` exists only under `CharacterFrame`, and hides when that frame hides. Log list and detail scrolls use `SetClipsChildren`. Scroll children are not mouse-enabled. Tracker and log rows outside the visible scroll have mouse off and a shrunk hit rect. Opening the profession book (`TRADE_SKILL_SHOW` / `CRAFT_SHOW`) drops the log from DIALOG to MEDIUM so the book receives clicks. Clicking the log calls `BringLogWindowToFront` and puts it back on DIALOG.

**Chat.** Some `CHAT_MSG_LOOT` / skill lines are secret strings during a boss pull. `ExtractItemIdFromChatMessage` returns before `:find` when `issecretvalue(msg)`.

**Completed tab.** Once `byId` exists, `GetEntryById` must not walk `self.entries` (~467k). A miss is a stale saved id. `CollectCompletedBySlot` walks obtained hunts once. `MarkEntryObtained` does not record every sibling band from `GetEntriesByItemId`.

**Worn gear beside the hunt tooltip.** After the hunt tooltip, `ShowEquippedCompare` fills `ShoppingTooltip1` / `2` from `GetInventorySlots`. Finger 11+12, Trinket 13+14, other slots one. Gold line `Currently equipped`. Empty slot shows nothing.

**Obtain toast is once per item.** `AnnounceObtained` runs only from `MarkEntryObtained`, and only when that item id was not already in this character's `obtainedItems` and was not in `ownedAtLogin`. The first time it is in bags or equipped. Unequip and re-equip must not toast. `ToastReequippedUpgrades` is gone; do not toast from `PLAYER_EQUIPMENT_CHANGED`.

**Obtained is this character.** `GearQuestForeverCharDB.obtainedItems` is the record. Do not read or write `GearQuestForeverDB.obtainedItems` for a new obtain. Another character's copy stays on that character. **Hammerbone** on a druid stays on the paladin's Active list. Bags and gear on the character you are logged into still hide it here. The (i) list never used the account map.

**Spec switch does not scan gear.** `SetSelectedSpec` refreshes the UI and does not call `CheckAutoCompletion`. Completion is by item id (`obtainedItems`). A hunt already completed on this character is completed on the new spec immediately (`IsEntryObtained` checks the item id) and does not toast. A piece you are wearing that was never recorded stays on Active until the next bag update, equip change, or login scan. That scan marks it completed. No toast if `ownedAtLogin` or `obtainedItems` already has the id. A random-enchant hunt still needs the matching suffix.

**Finger gap (shaman, levels 9–14):** the old Alliance-only curated paladin and warrior rings are gone. Those classes' 1–9 rings come from the scorer for both factions. Generated shaman Finger starts at 10 with **The 1 Ring (8350)**, which 404s on Forever and is pruned. Jewelcrafting is not in the Forever client. Woven Copper Ring and the rest of that catalog are not hunts. Horde enhancement rings that exist are Bounty Hunter's Ring (5351, Barrens) and Ring of Scorn (3235, Silverpine) around 15. Do not toast “ring slot eligible” unless `SlotHasHunts("Finger")`.

**28 Sep 2026 (v0.2.15-beta).**

- **Profession book performance.** Do not paint green BiS arrows on the trade skill or craft windows (recipe list or detail icon). Switching profession tabs or crafting used to call `RebuildCache()` on every `TRADE_SKILL_*` event and scan every recipe via `CacheTradeSkillRecipes()` — full-slot rescans on each tab change. Arrows stay on loot, vendors, quests, and loot rolls. `Indicator.lua` only hides profession overlays now; no cache rebuild on profession events.
- **Owned gear and the log.** If you already have a top upgrade in bags or equipped, it is hidden on the **Active** list (less clutter). Auto-complete still records it on **Completed** when you enter that level band or on login scan. Real **`PLAYER_LEVEL_UP`** invalidates bands and runs `CheckAutoCompletion`. Preview / simulator level changes do the same via `Preview:SetLevel` (they do not fire `PLAYER_LEVEL_UP`). Simulator: typing a level only updates the hint until you click **Simulate** (or Enter in the level box); that applies preview and refreshes hunts.
- **Snake Eye Kaleidoscope (273088).** In generated data for all classes/specs from character level 17 while it stays in the top three neck picks for that band; it is not shown below 17. If you are already wearing it, Active hides it; Completed should list it after auto-complete. Re-score is not required for the item itself; `items.json` kind is `Misc`.
- **Horde faction leaks (runtime).** Generated `itemFacts` are keyed by item id only, so Alliance Rune Broker libram copy could appear on Horde rows until the next re-emit. `Data.lua` `EntryMatchesPlayerFaction` hides Alliance-only broker relic ids on Horde (and the mirror on Alliance), denies one-faction **zones** on entries (e.g. Stormwind City on Horde), and tightens backfill / source-filter pools with `EntryMatchesPlayer`. `score.py` `RUNE_BROKER_ALLIANCE` / `RUNE_BROKER_HORDE` gates the next paladin (etc.) re-score so bad rows leave `_generated/`.

**27 Sep 2026 (v0.2.16-beta).**

- **Log header.** `GearQuestWindowTitle` in `Log.lua` is `GearQuest Forever v` plus `GQ.VERSION`. Every release bump of `GQ.VERSION` (and the TOC `## Version:`) updates the band. Do not hardcode a second version string in the title. See `RELEASE.md`.
- **Source filter must not duplicate Completed onto Active.** The same item can exist under several generated hunt ids (level band vs the wide filter pool). `IsItemIdObtained` is true if any hunt id for that item is in `obtained` or a completed hunt, or `obtainedItems`. `ShouldHideFromActiveList` also hides an item whose list key is already on **Completed** for that slot. With a filter on, Active starts from the normal top upgrades / notables / tracked hunts (source-gated), then backfills from `GetFilteredTopForSlot` only while the slot has fewer than 3 rows. Example: level 20 Beast Mastery, World drop unchecked, **Snake Eye Kaleidoscope** stays on Completed only.
- **Filter toggles stay cheap.** Do not bag-scan or walk every sibling hunt id per row in the wide pool. `EnsureActiveListCaches` builds completed keys, obtained item ids, and a bag/equip id set once per class/level/spec/faction. `GetFilteredTopForSlot` uses `EntryHiddenFromActiveFast` and caches per slot until `InvalidateSourceFilterCache`. Checkbox clicks call `ScheduleListRefresh` (debounced), not a synchronous `Refresh` plus a full indicator rebuild in the same frame. `InvalidateQueryCache` also drops the filtered-top cache.
- **`/gq wipe data` then sim up.** Wipe clears this character's progress. Obtained items are `GearQuestForeverCharDB.obtainedItems`. Do not read `GearQuestForeverDB.obtainedItems` when hiding an Active hunt, and do not write a new obtain into that account map or `completedItemBackup`. Another character's copy stays on that character. A jump from 10 to 20 does not pass through earlier bands, so wipe and `Preview:SetLevel` call `ScheduleAutoCompletionCheck(true)`. That path records owned hunts with `minLevel <=` effective level (class/spec/faction via `EntryMatchesTrackedHunt`) and **does not toast**. It looks up `GetEntriesByItemId` for items already in bags. It must not walk `GetClassSlotEntryList`.
- **Toasts are the current list only.** Bag, equip, loot, and a normal level-up call `CheckAutoCompletion()` with no reached-band scan. Complete and toast only top upgrades, the notable, and a tracked hunt that still `EntryMatchesPlayer`. A filter or a play style does not change that list. A rank 6 that is only showing because of a filter does not toast. Tracking it does. Hovering **Track** says so. A level 20 Enhancement shaman looting **Calico Cloak** (level 9 back) must not toast or complete it. Do not treat `GetCandidatesForSlot` as the list. The full catalog walk on `BAG_UPDATE` was the dungeon `Log.lua` "script ran too long" error.

**28 Sep 2026 (v0.2.17-beta).**

- **Spec weight tooltip.** Hover the spec name or icon. `GQ.Compare:ShowScoringWeightTooltip` reads `GQ.ScoringWeights` (pipeline `weights.json`) and applies `GQ.ScoringLeveling` when the level is 60 or below (`playerLevel <= untilLevel` for premade and custom). Level 60 shows the multiplied weights. Do not treat 60 as the raw row. Do not show `GQ.StatWeights` (Compare.lua reorder table). Weapon `dpsWeight` / `dpsWeightRanged` are extra rows. Regenerate with `node scripts/generate-stat-weights-lua.mjs` after a weight edit. `sources.json` must stay ASCII JSON (`ensure_ascii=True`); `score.py` opens it with the Windows default encoding and rejects raw UTF-8.
- **Enhancement intellect.** `weights.json` Enhancement `int` is **0.6**. `weights_at_level` doubles intellect below 60, so those bands score it at **1.2**, above agility **1.0**. Level 60 keeps the same ×2, so those bands still score it at 1.2. The scorer does not turn intellect into attack power; Mental Dexterity lives only in this weight. Enhancement Tank `int` stays 0.4. Shaman was re-scored and `Data.Shaman.generated.lua` plus the early 1–9 file were copied. Do not `reemit_all.py` for this.
- **Wolfsbane (267369).** Horde Retribution main hand rank 1 from level **20 through 26** (score 124 vs Hammerbone 103 at 20). Pin in `client_item_overrides.json`: `rlvl` 20, `tipClasses` Paladin, Holystorm proc text. Source is Diplomatic Incident, Danitha Morr, Bandarion Keep, Tirisfal Glades (`sources.json` `gateLevel` 20). Tirisfal is a Horde zone, so Alliance never sees it. Warrior was re-scored after the class lock so Arms/Fury/Protection no longer list it. The paladin hunt file is `Data.Paladin.generated.lua`. Levels 1–9 are `Data.Paladin.Early.1to9.generated.lua` and do not include Wolfsbane.
- **Memory.** Do not list class hunt files in `GearQuestForever.toc`, and do not put those class addons in `## OptionalDeps` (that loads every class before `Core.lua` sets `_G.GearQuest`, so each file errors and the hunt list stays empty). Each class is a load-on-demand addon `GearQuestForever_<CLASS>` (`scripts/stage-class-addons.py` copies the lua and writes `AuditTips.lua`). Login loads the player's class only. `Preview:SetClass` expands the simulated class. Your class and the class on screen keep their expanded rows. Switching to another sim class drops the previous one's expanded rows (`ReleaseIdleHuntClasses`). The addon stays in the memory list until `/reload` (WoW cannot unload it); pick arrays stay so switching back does not rerun the file. The main `foreverAudit` keeps `status` / `name` / `quality` for every item. The long Wowhead `tip` for a class item ships in that class's `AuditTips.lua` and is applied when the class loads, so hunt tooltips stay the Forever text. Curated Data.lua items that are not in a class file keep their tip on the main audit.

**7 Nov 2026 catalog.** Wowhead Forever listed 196 pieces that were not in the addon. All 196 return a classic nether tooltip 404, so all of them are stamped New in Forever (`new_in_forever.json` is 2,985). 33 are quest rewards and 163 stayed Unsourced. The gear list named no drop, seller, or recipe for those 163, and no farm was invented. They were added to `classic_item_ids.json` so the score pool keeps them, then all nine classes were rescored with `GQ_NO_GUIDES=1`. Weights were not changed. Wicked Ritualist's Kris (273832) is a quest item and was not added. Nine stored ids that are missing from the live gear list stay: Phoenix Bindings (210781), Invoker's Mantle (215365), Invoker's Cord (215366), Turtle Scale Gloves (217270), Golden Scale Gauntlets (217273), Greater Mystic Wand (217287), and the three Leafre rings (274978, 276765, 285326). A missing list row is not a 404. Leafre's Ring of Precise Spell Power stays required level 60.

Quest rewards and the pickup level. Horde 30, A Tale Spun Around the Fire (96078, no series, chain 1): Ceremonial Mallet (279885), Sacrificial Sword (279886), I'lalai Flayer (279887). Alliance 30, Findings for the Explorer's League (95799): Ancient Voodoo Pouch (279880), Intrepid Explorer's Chainmail (279881). Alliance 30, The Web of Magic (95798): Apprentice Sorcerer's Slacks (279878), Rune-Etched Epaulets (279879). Alliance 35, The Lost Tablets of Will (1139, no series): Medal of Valor (270095), pin Ironforge 76.4, 10.8, required level 35. Horde 36, Death to the Executioner (95433): the series through the reward is Rise Up! (95432) then Death to the Executioner. Later steps stay off. Thud Hammer (275011). Horde 36, Farholde Scouting Report (93971): Head-Harvest Crossbow (275040), Bloodied Sash (275041), no pin. Alliance 36, Fit for a Princess (95913): Apple of My Eye (95561) then Fit for a Princess. Stepped Out is after the reward. Fur-Lined Bracers (274931), Coyote Hide Wraps (274932), no pin. Horde 36, Jom-jom's Escape (94556): Jom-jom's Gabbar (274952), chain 1, and the page names no giver and no coordinate, so there is no pin. Alliance 36, Preventative Measures (95064): Farholde Horns (274959). Alliance 36, The Rog'mar Situation (95066): Orc Bone Bow (275052). Alliance 37, The Hidden Chamber (2240): Guardian Staff (270078), pin Ironforge 73.8, 13.0, faction Alliance. The earlier quest 2398 has no stored name, so the chain line stays quiet. Horde 38, A Token of Vengeance (94975): Semblance of Twilight (267090). Alliance 38, Drop the Hammer (94926): Pauldron of Order (275036). Alliance 38, Dunston Checks Out (94927): Prisoner Handwraps (275021), Bolder'ok Loincloth (275023), Dunston's Ogre Duster (275025). Horde 38, Gordunni Cobalt (2987): Orwin's Axe (287073), chain 1, pin Feralas 75.6, 44.2. Tome of Twilight, pickup 39. Alliance 94984 is A Small Favor (94907) then Tome of Twilight: Twilight Initiate's Belt (279854), Torn Cultist Cloak (279855). Horde 94972 has no series: Indoctrinated Choker (279859), Convert's Bindings (279860). Both 40, Eye of Mugg (Horde 94968, Alliance 94982, no series, no pins): Bigger Rock on Bigger Stick (279480), Rock on Stick (279852), Stick No Rock (279853), required level 40. Both 43, Tiara of the Deep (2846), chain Tabetha's Task (2861) then Tiara of the Deep: Dank Shoulderpads (270098). Four trainer pins: Undercity 84.4, 11.0, Ironforge 26.4, 9.4, Stormwind 38.4, 79.4, Orgrimmar 37.8, 86.6. The log shows the closest of the viewer's faction. Both 44, Divino-matic Rod (2768, chain 1): Magister Cowl (270099), pin Tanaris 52.4, 28.4. Both 50, Jammal'an the Prophet (1446, chain 1): Leggings of Freedom and Sorrow (270115), pin the Hinterlands 33.6, 75.2. Required level was lowered from the item-level floor to the quest's Requires level only when the tooltip had no Requires Level above 1. Do not run `apply_quest_req_levels.py` on the catalog.

Stopping the Cycle (98297) rewards Subdued Dragon's Fang (281314), Trusty Sword (281313), and Fallen Dragon's Scepter (281312). Wowhead's series box is empty. The chain is still Old Habits (98223), Crocs of the Sky (98072), Crimson Crate Delivery (98240), Razormaw Needling (98245), Trying Times (98246), This Land Was Their Land (98230), Death to the Dragonmaw (98291), then Stopping the Cycle. Razormaw Needling's own series is the two steps before it. Word to Ironforge (98300) is after the reward and stays off. The pin is the Tattered Spellbook in the Wetlands at 53.4, 54.5, not Howin Kindfeather at 77.0, 45.4. Alliance. Do not write the chain back to 1, and do not move the pin back to the reward giver. `quest_faction.json` marks the three Alliance. A rescore is what drops them from a Horde list.
**14 Oct 2026 index: 3,796** (10 Oct was 3,785). The listview armor column is base armor. Stored armor is base plus the green bonus, so a lower listview number is not a tooltip change. Live dataEnv 16 still matched Violet Sash, Gravewalker Boots, Desperate Barrier (1257), Feralheart Embrace, and Summit Guardian Polearm. Those rows were left as they were.

Eleven ids were new to the index. Jewelcrafting Chisel (271965) and the paladin monster shield (286140) stay skipped. Blackthorne Maul (273830) is a quest objective, not a reward, and stays out. The other ten were inserted from the dataEnv 16 tooltip. Wowhead names no drop, quest, vendor, or recipe for them, so the source is unsourced and the hunt says the source is not listed yet. No coordinate was invented. `build_forever_new.py` stamped the uncached ids. New in Forever is 2,785.

The ten, and where they lead:

- **Firebird Leggings** (286569), cloth legs, requires 43. +14 intellect, +17 fire spell power. Rank 1 legs from 43 through 50 for Fire and Battle Mage (Fire), both factions. Rank 3 legs from 43 through 49 for Destruction.
- **Stone Keeper Spire** (274432), staff, requires 44. 31.72 DPS, +19 stamina, +105 healing, +35 spell damage. Rank 1 main hand at 44 for Holy and Discipline, both factions. Rank 1 for Bear from 44 through 54, rank 2 at 55–59.
- **Moonchaser's Headdress** (283545), leather head, requires 41. Rank 2–3 for Balance around 41–44.
- **Abomination Chain** (274385), neck, requires 37. Rank 3 for Bear necks at 37–44.
- **Well-Worn Pitchfork** (281661) requires 33. **Surveyor's Gloves** (281896) requires 39. **Cliffbreaker's Pauldrons** (284064) requires 47. **Feardred's Gauntlets** (284285) requires 49. **Crown of Maldazzar** (284065) requires 53. **High Priestess's Kilt** (286640) requires 54. They are on the rank list below the hunt's top three.

The Desolace centaur weapons (271794–271805) were refreshed from the same tooltip. Required level is 35. Item level is 38 or 42, and damage and stats are lower than the previous row. **Centaur Spear** is 26.61 DPS, +9 strength, +11 stamina, from Test Your Theory. **Staff of Revelations** is +8 intellect, +11 spirit, +30 healing and spell damage, from Proof of Concept. **Desperate Barrier** stays 1257 armor. **Thrice-Damned Effigy** is the held item from Khan Jehn. Their quest names and pins were already stored.

**28 Sep 2026 index: 3,693** (26 Sep was 3,678). Fifteen new listview ids. Ingest added the seven that had a nether tooltip: Needletooth's Needletooth (282703), Bloodstained Pants (282713), Denmother's Hide (283253), Arcane Charged Robes (284697), Still Water Band (284699), Wyvern Heart Band (285190), Winds of Tanaris (286556). Eight still 404 and are not in the pool: Wail of Death (281600), Fishscale Hauberk (281891), Unmovable Sabatons (284154), Eternally Frozen Band (284253), Budding Leaf Belt (284382), Faerie Dragon's Skin (284383), Ursol'lok's Paws (284573), Snapped Branch Wand (284574). All nine classes were re-scored. **Wyvern Heart Band** is rank 1 finger from 29 through 37 for Arms, Fury, Retribution, Combat, Subtlety, Survival, and Feral, and through 47 for Assassination. The other six did not take a top-3 slot.

A full ingest rewrites sources.json for every id >= 200000. That cleared 162 zones, including Wolfsbane (Tirisfal / Diplomatic Incident became Old Fire-Eye) and dropped Kaleidoscope's hand-patched resist 5. After ingest, restore every source key that already existed and only add new ids. Keep Kaleidoscope resist 5. Client pins stay skipped. Do not rescore from the wiped sources.

**7 Oct 2026 (v0.3.6-beta). Score the stored row only when it matches the tooltip.**

`refresh_forever_tips.py` is the refresh. It reads the live Forever tooltip `https://nether.wowhead.com/tooltip/item/{id}?dataEnv=16` (the item-page database) and writes quality, required level, and stats to `items.json`. The older `nether.wowhead.com/forever/tooltip/item/` feed can lag that page: Talbar Mantle (10657) is uncommon/green on the page and on dataEnv 16, and was still rare/blue on the old feed. Do not reuse `refresh_cache.json` from that feed. The live cache is `refresh_cache_env16.json`. One request at a time, `GQ_TIP_DELAY` default 1.5 seconds. A full ingest is not a refresh: ingest inserts new ids and must not rewrite existing stat rows from `tooltips.json` (that reverted Erudite). It does fill an empty source, and when the listview names a different quest, vendor, dropper, or profession it updates that place and indexes coordinates for those ids. Client pins and Greater Magic Wand **11288** stay skipped. A stated Requires Level above 1 replaces the stored level. A tooltip with no Requires Level line does not. The hunt list hides a piece until the stored required level (Fiery War Axe is 35, so level 30 must not list it). On 7 Oct the previous feed updated **1186** items, then all nine classes were re-scored with `rescore_hunter_shaman.py`. Holy paladin and Beast Mastery / Marksmanship weights in this file are the weights that score used. Do not rescore from a stale row.

**Heart of Disruption** is two City of Dalaran quests that share the name. Alliance quest 92458 chooses Spellguard Pauldrons (279839), Renewing Footpads (279840), or Defender of Dalaran (279841). Horde quest 96984 chooses Battle Spaulders (279842), Enchanted Sandals (279843), or Striking Staff (279844). A Tauren does not see Defender of Dalaran. Those six ids are exclusive in `quest_faction.json`. The dungeon step says Requires level 24. The chain starts earlier, and that first quest says Requires level 30, so the hunts are level 30. Alliance begins at An Alarming Request (92432), Emissary Jacques in Hillsbrad Foothills (48.3, 60.1). Horde begins at Blood in the Streets (92434), Magus Wordeen Voidglare in Tarren Mill (61.4, 20.8). The pin is that start, not Image of Archmage Modera. The dungeon itself has two doors, both in Alterac Mountains (map 1416). Alliance is in front of the city at 14.2, 61.1. Horde is the outside sewer at 8.8, 59.6. Boss drops and dungeon trash in City of Dalaran use those doors. The parchment access line is faction-specific. Alliance starts at An Alarming Request, and Image of Archmage Modera teleports the group in. The dungeon pipe is inside the city, in the sewers at Cantrips & Crows. Horde starts with Key to the City from Magus Wordeen Voidglare, and Heart of Disruption awards the Dalaran Sewer Key. One person in the group needs the key. Defeating Shade of the Archmage and finishing Shrewd Negotiations makes the city guards neutral. Most citizens still will not offer their services. Do not pin Alliance in Silverpine Forest. Modera's quest coordinate is not the door.

**Malignant Root (282283)** is a finger. Alliance Arms and Fury, rank 1 at level **27** only. Source is the rare **Nightveiled Rotheap** in the Wetlands (pins 21.2, 43.2 / 21.9, 43.3 / 23.0, 43.6). Rotheap Inards are party loot at 100%. Turn them in to Rethiel the Greenwarden. The Greenwarden is hostile to Horde, so `questRaces` 77 and `GQ.Data.questFaction[282283] = "Alliance"`. Do not pin the turn-in. The classic nether tooltip 404s, so the reward carries the New in Forever stamp.

**29 Sep 2026 (v0.2.19-beta). Score from the refreshed Wowhead Forever tooltip.**

`pipeline/scripts/refresh_forever_tips.py` re-fetches nether tips for **every
hunt id** (the generated class files) plus the Forever index. The index
alone is not enough: classic ids are absent from it, and that is how Ghostly
Mantle kept a rebuild tooltip. Do not pass a list that is only `index.json`.
`emit_forever_audit.py` runs **before** the re-score, and it keeps the
previous line for jackpot greens and the wand. Then
`rescore_hunter_shaman.py` with `GQ_NO_GUIDES=1` for all nine classes. Do
not `reemit_all.py` from stale JSON. Do not run a full ingest to refresh
tips: a full ingest replaces existing `sources.json` rows for id ≥ 200000.
Restore existing source keys and only append new ids. Re-apply boss pins,
faction zone pins, and `apply_named_drop_kinds` (dungeon bosses stay
`boss_drop`; "(rare spawn)" stays `rare_npc`). Wolfsbane's Tirisfal zone is
hand-maintained. Kaleidoscope (273088) resist 5 must survive a refresh
(`refresh_forever_tips.py` keeps resist when the new parse has none). Client
pins (Coldflame, Silverlaine, Wolfsbane rlvl 20) must not be overwritten by
the nether tip. Greater Magic Wand **11288** is not refreshed: nether still
prints 11.39 DPS. `sources.json` stays ASCII (`ensure_ascii=True`).

**Spell line → stats.** The equal sentence `Increases damage and healing
done by magical spells and effects by up to N` stores **both** `heal=N` and
`damageDone=N`. Do not collapse it to `sp` only. `forever_stats` folds
`damageDone` into `sp` and zeros `damageDone`, so it is not counted twice.
Holy weights: heal 1.0, sp 0.3, `sp_from_heal` 0.3. Mage heal weight is 0
and sp is 1.0, so a mage gets the damage half only. The unequal sentence
`Increases healing done by up to X and damage done by up to Y` is
`heal=X`, `damageDone=Y` (Staff of Westfall: heal 48, damage done 16, from
`rtg41=48` and `rtg42=16`). Nether HTML tags the equal sentence as
`<!--rtg41-->` only. Keep the heal and **add** `damageDone` for that amount.
Skip that special case when `rtg42` is also present, or when the line says
`party`. A green `+N Spell Power` line stays `sp` only. Do not remap every
Spell Power piece into heal.

Checked after the refresh:

| Item | Stored stats | Level |
|---|---|---|
| Staff of Westfall (2042) | int 5, spi 6, heal 48, damageDone 16, 15.17 dps | 14, quest The Defias Brotherhood |
| Golemheart Stave (270228) | sta 3, int 6, spi 5, heal 18, damageDone 18, 11.88 dps | 13, Plunder, Hall of Thanes |
| Fang of Magmatus (271095) | int 4, heal 18, damageDone 18, 7.94 dps | 13, Magmatus, Hall of Thanes |
| Royal Dagger (281297) | int 4, heal 18, damageDone 18, 8.53 dps | 20, Alliance, A Friend of the Family |
| Grave Shroud (279865) | 20 armor, str 3, agi 2, sta 5, kind Misc | 16, both faction quests |

Fang is **not** Holy rank 1. Horde Holy 13–17: Crescent Staff (6505, Leaders
of the Fang, requires 10) is rank 1, Trogg Scepter (272996) is rank 2, Staff
of Orgrimmar (15444) is rank 3. Fang is rank 8 there. Alliance Holy at 13:
Trogg Scepter, Golemheart, Fang. From 14, Staff of Westfall is rank 1.
Frost mage 13–18: Golemheart rank 1, Fang rank 2. Do not pin Fang over
Golemheart.

**Required level is the tooltip, never item level.** `build_item`: if the
tip states `Requires Level` greater than 1, that number is the equip level.
Fang's tip is `<!--rlvl-->13`. It was never gated at item level 18. It
ranked low because spell power was stored as 0. Do not lower a stated equip
level. A quest reward may still be raised when the quest itself opens later
than that line. The hunt level is the higher of the two.

**No required level means look the item up.** Every time an item has no
`Requires Level` (nothing on the tip, or Wowhead's stub of 1), assume it is
a quest reward, or some other source that has a level gate, and look it up
on Wowhead Forever. Do not leave it on the item-level floor (`ILVL_FLOOR`:
ilvl 18 → 13, ilvl 23 → 18, ilvl 24 → 19). That floor is only a stand-in
until the lookup has been done. Find the quest attached to the item. The
**minimum** level required to pick up that quest becomes the item's `rlvl`
and the source `gateLevel`. Several quests: take the lowest. A chain of at least five steps that must enter a dungeon uses that step's quest level when it is at least 8 levels above the pickup. Final Passage (Windstorm Hammer 6804, Dancing Flame 6806) is 36 because Test of Lore in Scarlet Monastery Library is level 36. Mage's Wand (Ragefire Wand 7513, Icefury Wand 7514, Nether Force Wand 11263) is 40 because Rituals of Power is level 40. Confront Yeh'kinya (Faded Hakkari Cloak 20218, Tattered Hakkari Cape 20219) is 58 because The Final Tablets in Blackrock Spire are level 58. Drakefire Amulet (16309) is 60 because General Drakkisath is level 60. Leaders of the Fang stays 10. The Defias Brotherhood stays 14. Medal of Courage (6723) is 35. The five Zandalar pieces that the quest page listed at 58 are **Zandalar Illusionist's Wraps** (19846), **Zandalar Demoniac's Wraps** (19848), **Zandalar Demoniac's Mantle** (19849), **Zandalar Demoniac's Robe** (20033), and **Zandalar Illusionist's Robe** (20034). The level-60 dungeon upgrade sets stay locked at 60 in `DUNGEON_SET_60`. A quest lookup must not lower them to 58. `eff_req` then
uses `rlvl` when it is &gt; 0.

The dungeon upgrade sets are level **60** quests. Classic **Feralheart**,
**Beastmaster**, **Heroism**, **The Five Thunders**, **Darkmantle**,
**Deathmist**, **Soulforge**, **Virtuous**, and **Sorcerer's** (72 pieces)
were raised from the 58 pickup to required level 60 and gate 60. The Forever
spec copies (144 pieces) are the same quests at 60, not world drops or
vendors, with `questRaces` 0 so both factions see them. Slot to quest:
wrists **An Earnest Proposition**; hands and waist **Just Compensation**;
feet, legs, and shoulders **Anthion's Parting Words**; head and chest
**Saving the Best for Last**. The pin is the start of that chain, An Earnest
Proposition, not the turn-in for the piece. The hunt text is
`Reward from the quest '{quest}'. The chain starts with An Earnest Proposition.`
Leave these out of that retag: the Beaststalker drop set, Beastmaster's
Girdle (5355), Darkmoon Card: Heroism, Uncle's Heroism, Violet Sorcerer's,
Ogre Sorcerer Belt, and Sorcerer Collar. A piece with no quest and item
level 15 or below, and no real Requires Level, is wearable at 1. A higher
item level with no quest stays on the lookup. Do not mark the dungeon sets
wearable at 1.

The item XML `https://www.wowhead.com/forever/item=ID&xml` first `<json>`
CDATA `reqlevel` matches the quest page `Requires level N`. `jsonEquip`
reqlevel is often the stub 1. Ignore it. Quest HTML `Requires level N` is
the pickup level. The scaling `minLevel` is the reward-scale level. Do not
use it. `sourcemore.ti` is the quest id (`t==5`, or source list contains 4).
If the page has no quest, use the real gate for whatever the source actually
is. Do not treat a drop's page level as a quest pickup. Staff of Nobles
(3902) is a drop (source `[2]`, reqlevel 15), not a quest.

`apply_quest_req_levels.py` writes through a `.json.tmp` then `Path.replace`
(`items.json` `write_text` raises `OSError` 22). Cache is
`pipeline/data/forever_wowhead/quest_req_cache.json`. Kris of Orgrimmar
(15443) and Staff of Orgrimmar (15444) are 9 (Hidden Enemies, 5730). Staff
of Westfall stays 14. Grave Shroud stays 16. Fang stays 13. Wolfsbane stays
the pinned 20. The first lookup used a browser user agent and cached HTTP
403 for most rows. Retry those with `wow-classic-data-research/1.0`. Do not
refetch a row that already has `reqlevel`. A cached 403 is not a level.

## Scraping Wowhead Forever

On 5 Oct 2026 the Forever listview and item XML on `www.wowhead.com`
returned HTTP 200 (`node scripts/scrape-forever-wowhead-items.mjs --index`,
then diff against `items.json`). Nether
(`https://nether.wowhead.com/forever/tooltip/item/{id}`) is still the
tooltip. When Nether 404s, the item page
`https://www.wowhead.com/forever/item={id}&xml` has `htmlTooltip`. A 403 is
not an empty source and is not cached as "no pin". ForeverDB
(`https://foreverdb.net`) is the fallback when neither has the fact. The
5 Oct pieces were not in ForeverDB.

Ingest **inserts new ids only**. An existing `items.json` row keeps its
facts. Refreshing every cached tooltip put Erudite's Amulet back to a stale
blue +4 Agility / +6 Stamina and dropped school damage. A source row is
replaced only when the old text is missing or still says
"Source not listed yet" **and** the new row names an npc, a quest, a
profession, or a source type other than world drop or unsourced. A real
boss pin, camp vendor, or hand edit stays.

**Then recheck every item that is still Unsourced.** If the new listview or
the tooltip now names a quest, a vendor, or `Dropped by`, fill that source
(`boss_drop` when the npc is in `dungeon_entrances.json` `bossNpcs`,
otherwise the specific type the page names) and run
`index_coordinates.py --ids` for those ids. On 5 Oct that pass filled 45
placeholder sources and turned tooltip-only droppers (Worgpelt Leggings /
Wolf Master Nandos, and the other named bosses in WC, SFK, RFK, Stockade,
and Scarlet Monastery) into real sources with entrance pins. Thirteen new
items stayed Unsourced because the tooltip named no dropper. Do not call
those world drops.

**Then check every newly indexed id for New in Forever.** Wowhead prints that badge when the id is absent from the classic item database. Probe `https://nether.wowhead.com/classic/tooltip/item/{id}`: HTTP 404 is the badge, HTTP 200 is a classic or Season of Discovery item and stays unstamped. `id >= 200000` is not the test. Privateer's Ornate Pistol (202256) is in that range and is not new. Run `python pipeline/scripts/build_forever_new.py`. It probes only ids missing from `pipeline/data/forever_wowhead/new_in_forever.json` and rewrites `GearQuest/_generated/Data.ForeverNew.generated.lua`. The log draws the burnt Forever mark beside the reward for those ids. Hovering it says "New in Forever".

Re-score with `python pipeline/scripts/rescore_hunter_shaman.py` after new
gear is actually ingested. One class name does one class. Do not
`reemit_all.py` from stale JSON.

`Requires Level` on the tooltip is the equip level. Item level is not.
ForeverDB field `rl` is that same required level. ForeverDB field `il` is
item level. Do not equip from `il`. A stated level greater than 1 is never
replaced. An item with no required level (or Wowhead's stub of 1) is still
looked up, and the hunt level is the source gate, not the item-level floor.

When Nether or www does not have the fact, ForeverDB
(`https://foreverdb.net`) is the source. The files are static. No key.

- `data/items.json` — name, class, subclass, inventory type, quality, `il`, `rl`, stats.
- `data/sources/{id % 64}.json` — drop, quest, and vendor rows.
- `data/questguides/index.json` — `min` is the pickup level. `lv` is the suggested level. Do not use `lv`.
- `data/questguides/{id % 64}.json` — quest giver, faction (`side`), and coordinates.
- `data/rares.json` — rare zone and spawns.
- `data/world.json` — map id to zone name. Type 3 is a zone. Type 2 is a continent.

The browsable lists are `https://foreverdb.net/items?cls=2` (weapons) and
`https://foreverdb.net/items?cls=4` (armor). A new equippable piece is built
from the Nether tooltip plus that ForeverDB row. An item with no inventory
slot (seals, toys, hidden placeholders, a deprecated name) is not hunt gear.

Quest pickup from ForeverDB: Arachnophobia (6284) is min 15 and lv 21. The
Tower of Althalaxx is min 13. A quest source row has `t` `quest` and quest
id `q`. Only fill an item whose `rlvl` is still 0 or 1. Do not lower a
level the tooltip already set.

The hunt zone is the zone, not a place inside it. Tower of Ilgalar is
Redridge Mountains. ForeverDB `data/world.json` pins name that parent, and
an existing coordinate row that sits entirely on one zone map wins over the
area name. An open-world rare stays on both factions' lists when that zone
is the other side's territory, and the rare pin ignores the faction map
deny. A world drop that was already listed under the area name stays listed
after the label becomes the parent zone (`zoneOpen`). Do not rename a
dungeon to the zone its entrance sits in. Do not turn Refuge Pointe or
Alliance. Through level 15 the log shows that faction's own farming pin
and leaves the other faction's zone off the parchment. Above 15 a
world drop stores a published camp in every zone a dropping creature
lives in, up to three spawns per zone when they are far apart, and the
log shows the camp closest to the character. A named creature in that zone stays on
that faction's list. A world drop that was already listed under the area
name stays listed after the label becomes the parent zone (`zoneOpen`).
Do not rename a
dungeon to the zone its entrance sits in. Do not turn Refuge Pointe or
Hammerfall into Arathi Highlands: that name is what keeps the other faction
off those vendors.

**Vendor reputation is a line of its own, just before Source.** A Forever tip
`Requires Booty Bay - Honored` is `reqRep`. The parchment reads
`Requires Honored with Booty Bay. Your standing is Friendly.` The standing
clause is green (`|cff0c4a1c`) when this character has reached it and red
(`|cff6e1212`) when they are short. Neutral still counts: a Ratchet vendor
that wants Friendly says `Your standing is Neutral` in red. `You have not
met this faction yet` is red, and only when this character's reputation
list has no row for that name. The list is `C_Reputation` on this
character. It is not saved and it is not read from another character. The
instructions can still say `Bought from Gezzy Gunkgear. Requires Booty Bay - Honored.`
Souvenier Sea Shell **274749** is that neck. Darkspear Raiders is Horde, so
those pieces are not on the Alliance list. League of Arathor is Alliance.
The Defilers are Horde. Goblin towns (Booty Bay, Ratchet, Gadgetzan,
Everlook) stay on both lists, with the standing written out.

**Starter whites Forever turned green** (dataEnv 16). Ice-covered Bracers (763) is +1 Agility and 27 armor. Royal Frostmane Girdle (2546) is +2 Intellect and 73 armor. Wendigo Fur Cloak (3008) is +1 Strength. Wispy Cloak (3322) is item level 10, requires 5, +1 Spirit, and 10 armor. Ghostly Bracers (3323) is +1 Intellect. Lithe Boots (6201) is +2 Stamina and 42 armor. Fingerless Gloves (6202) is +2 Agility. Ratty Old Belt (6147) is +2 Strength and 35 armor, from Narg the Taskmaster in Elwynn Forest. It had been marked unobtainable because the word Old matched an unused-name rule. That flag is cleared. All nine classes were re-scored from these stats. Wispy Cloak is not on a list before level 5. Wendigo Fur Cloak is rank 1 back at 6 for arms and fury.

**Blank item kind.** Subclass −2 ring, −3 neck, −4 trinket, −5 held, −6
cloak must be `kind` `Misc` (`ARMOR_SUB`). `kind` `?` makes `eligible()`
reject the piece. A full ingest does not copy `kind` onto existing items.
`refresh_forever_tips.py` sets `kind` `?` to `Misc` for those subclasses.
Weapon subclass `?` (test spears and the like) stays. Grave Shroud was
`kind` `?` and `rlvl` 18 from the ilvl floor. It is now Misc, rlvl 16,
`gateLevel` 16, zone null, instructions naming Alliance **Abominable
Creatures** (95250) and Horde **Unending Torment** (97290). Horde and
Alliance Bear back: rank 1 at 16 (score ~21.15). Levels 19–22 Horde Bear:
rank 3 behind Sporid Cape (6629, 22.0) and Sentry Cloak (2059, 21.4).

**Weapon headers are display-only** (`Data.lua` `WeaponHeaderSuffix`). The
lists stay per slot. `pair_weapon_styles` in `score.py` runs when the slot
is MainHand and the style is `twohand_or_onehand`. Rank 1 stays the best
weapon. Rank 2 is the best weapon of the **other** hand style, so a staff
at rank 1 is followed by the one-hand that Off Hand rank 1 pairs with.
Rank 3+ keeps score order, so a second staff can sit at rank 3 with a
higher score than rank 2. That is intentional for casters. Off hand stays
score-sorted for them. `EntryOffWeaponRoute` is unused. Do not grey the off hand.

**Hunter and Enhancement weapon categories.** The log does not mix them
into one Main Hand list. **Two-hand** is its own block, the best two-handers
by themselves, and it is what the Main Hand paper-doll slot shows. Under it,
hunters get a **Main hand** block of main-hand-only weapons, then an
**Off Hand** slot. Main-hand weapons stay in that list. The Off Hand
character panel bar shows either-hand weapons only (InventoryType 13,
One-Hand), because a main-hand weapon cannot be equipped there. The Off
Hand paper-doll slot is that either-hand list. Enhancement shows the **Two-hand** block only. No one-hand list
and no off-hand list. Forever Enhancement does not dual wield.
Rogue **Main Hand** and **Off Hand** each list the one-hand types in the
current band. Assassination, Combat, and Subtlety are not dagger-locked.
Each lists the daggers, swords, maces, axes, and fists a rogue can equip.
Combat still scores the axe highly. A One-Hand weapon belongs to both
hands, so a type can be off under one hand and on under the other.
Main-hand-only stays under Main Hand. Off-hand-only stays under Off Hand.
The hunt keeps a One-Hand weapon while either hand still allows that type. For every class, the
printed weapon damage is the damage in either hand. A caster dagger that
only says Main Hand stays on the main-hand list and ranks on its weapon
damage.

| Who | Main Hand header | Off Hand header |
|---|---|---|
| Mage, priest, warlock, balance and restoration druid | Two-hand and Main Hand, both start on, so a one-hander in the top three stays beside the staff. The hunt is still three names | Off Hand |
| Druid, paladin/warrior levelling when a route exists | Two-hand or main hand | Off Hand |
| Enhancement | Two-hand | (no off-hand list) |
| Hunter | Two-hand, then a Main hand list of main-hand-only weapons | Off Hand is either-hand only, and that is the character panel bar. The ranged slot title is **Ranged** |
| Rogue (combat, assassination, subtlety) | One-Hand and Main Hand, types under that hand | One-Hand and Off Hand, types under that hand |
| Warrior Fury | Dual wield | Off Hand |
| Paladin Retribution, Warrior Arms | Two-hand | Off Hand |
| Paladin Protection, Warrior Protection, Shaman Enhancement Tank | Main Hand | Shield |
| Paladin Holy and Shockadin, Shaman Elemental and Restoration | Two-hand and one-hand, both start on | Shield |

The weapon filter is saved for the class and spec on screen. A filter set while simulating is saved only for that simulated spec. It does not apply to another spec you simulate, and it does not apply after simulation is turned off. The character's own filter is unchanged.

Hunter ranged weapons are **Bow, Gun, and Crossbow** only. The slot title
is **Ranged**, the same word a warrior sees, because the list is not only
bows. A thrown weapon does not fire Auto Shot, so `HUNTER`
`_weaponSubclasses` does not include `Thrown`. Houndmaster Boomerang,
Quilrager Throwing Axe, Vicious Throwing Stars, and Assassin's Throwing Axe
are not hunter hunts. Rogue and warrior still list thrown weapons. Do not
put Thrown back on the hunter list.

The arrow on the hunter **Ranged** header, before the (i), is the filter.
Bow, Gun, and Crossbow are checkboxes, and a type is listed only when the
current band still has one after the source filter and the play style. Each
starts checked. A type with nothing left is not listed, and it comes back
with the same check when those filters allow it again. The header reads **Ranged*** while
any of those is off. Unchecking a type hides that type from the hunt rows
and from the character-panel list. Rank numbers and the (i) list stay the
unfiltered order. A piece whose type cannot be read stays out once any box
is off. The choice is remembered per hunter spec. Other classes do not get
this filter.

Ranged DPS, damage, and speed are the Forever tooltip, not a stale stored
number. Beast Mastery and Marksmanship melee `dpsWeight` is **0.05** (they also
melee: Raptor Strike, Wing Clip, Mongoose Bite). Strength is **0** for Beast
Mastery and Marksmanship, and **0.7** for Survival. Levels 1–9 stay at **0.3**.
Their `dpsWeightRanged` is
**14**. Survival melee is **10** and ranged is **6**. Defense on every hunter
spec is **0.02**. A gun with defense and a
lower DPS loses to the higher-DPS bow, gun, or crossbow. Do not retune
defense to bury it. **Hi-tech Supergun** (9487) is not rank 1 at 26 for that
reason. After the 5 Oct 2026 fact pass, level 22 Beast Mastery Horde ranged
is **Alliance Outrunner Bow** (285347, 13.33 DPS, +4 Agility, +3 Spirit),
**Double-barreled Shotgun** (2098), and **Naga Heartpiercer** (3078, same
13.33 DPS; the wound proc is not in `items.json`, so it is not scored).
Notable is **Venomstrike** (6469). **Steelarrow Crossbow** (6315) is 10.88
DPS, 29–45, speed 3.40, +3 Agility, and is not in that top 3. Level 26 Beast
Mastery Horde is **Concealed Hand Crossbow** (273829), **Dun Garok Rifle**
(282710), and **Outrider's Bow** (212585).

Forever Enhancement has no dual wield. Do not label it Dual-wield.
Rogues cannot wear two-hand. Hunters: the bow is its own slot.

Holy and Shockadin keep two-hand swords, maces, axes, and polearms beside
the shield. Elemental and Restoration keep staves and the other two-handers
a shaman can equip. **Odo's Ley Staff** (6318) is Restoration rank 2 at
21–23, behind Staff of the Friar, and it stays on that list through 29.
The two-hand slice reserves staves so a mace does not crowd the staff out.
Enhancement stays two-hand only. Shamans cannot dual wield.

Rogues include one-hand axes, swords, maces, fists, and daggers on every
spec. Assassination and Subtlety are not dagger-locked. The Weapons menu is
where a player turns a type off for one hand. Combat still scores the axe
highly. **Axe of the Deep Woods** (811) is a main-hand axe and rank 1 for
Horde Combat at 52–59. The first view follows the spec: two-hand
for a hunter, a feral druid, an arms warrior, a retribution paladin, or
enhancement; one-hand for a rogue, a fury warrior, or a shield spec. Holy,
Shockadin, Elemental, and Restoration start with both styles on.

**Source filter.** `EntrySourceAllowed` used to return `not hidden[src]`.
A source type with no checkbox is never in `hidden`, so it showed on every
filtered list. The 1 Ring (8350), Steelscale Crushfish (6360), and Broken
Wine Bottle (6651) are `sourceType` `fishing` ("Fished up.") and leaked
onto a Boss drop only list. `GQ:NormalizeSourceType` maps `fishing` and
`skinning` to `profession`, and `container` to `object_drop` (the Container
checkbox). There is no Special source and no Seasonal quest source. While a filter is
active, a type that is still not a checkbox id is hidden. `unknown` stays
on the unfiltered list. `GetSourceLabel` prints Profession, not the raw
string `fishing`. `build_sources.py` stores new fishing and skinning rows
as `profession`. Instructions stay "Fished up." Do not add a Fishing
checkbox.

**Placeholder client names.** `GetItemInfo` returns `Item 23173` when the
Forever client has the id and not the name. `GetItemDisplayName` treats
`Item 23173`, `Item #23173`, and a bare id as missing, then uses the fact
name, then the audit name, then `PROFESSION_ITEM_NAMES`. 23173 is
Abomination Skin Leggings. 6750 is Snake Hoop. Every listed hunt already
has a real name in `items.json`. Do not display `Item` plus the id when
either of those names exists. `Indicator` must not cache the stub.

Set packages were not retuned by the tooltip refresh. Embrace of the
Viper, Defias Leather, and Chain of the Scarlet Crusade stay. Wolfsbane
stays Horde Retribution main hand rank 1 from 20 through 26. Snake Eye
Kaleidoscope keeps resist 5.

Eight Forever index items still have no tooltip and are not ingested:
281600 Wail of Death, 281891 Fishscale Hauberk, 284154 Unmovable Sabatons,
284253 Eternally Frozen Band, 284382 Budding Leaf Belt, 284383 Faerie
Dragon's Skin, 284573 Ursol'lok's Paws, 284574 Snapped Branch Wand. Do not
invent stats.

## Relic effect scoring

Totems/idols/librams often have **no flat stats** — only an Equip line. Without
effect text, `score.py` fell back to `ilvl × 0.01`, which wrongly ranked e.g.
**Totem of Ancestral Protection** above **Polished Driftwood Icon** for elemental.

1. `python pipeline/scripts/patch_relic_effects.py` — copies Equip/Engrave lines
   from `pipeline/data/forever_wowhead/tooltips.json` into `items.json` for
   relics missing `effects`.
2. `relic_score.py` — prices casting mana reg, “increases damage/healing of … by
   up to N”, grounding-totem CD trims (low for elemental), and spec-specific
   rune unlocks. Re-score shaman (or `score_all.py`) after changing weights or
   patterns.

Shaman **relic slot** is stored as pipeline slot **`Ranged`**; the log labels it
**Totem** via `Data.lua`.

## Pick quality checks

- **Forever 404:** `gq_paths.forever_missing_ids()` reads
  `Data.ForeverAudit.generated.lua`; `score.py` / `payload.py` skip those ids.
- **Same display name, different id:** `unique_name_rows` / `unique_picks` keep one
  id per name in the top 3 (PvP rank variants).
- **Audits:** `node scripts/audit-generated-slots.mjs` (overlap bands, short slots,
  duplicate names) and `node scripts/audit-unique-top3.mjs` after large regens.

## What is already wired

- Paths are repo-relative (`gq_paths.py`). No `/home/claude/gq/`.
- Scoring bands are **10–60** (not 69).
- `items_random.json` is converted Classic tables (TBC copy kept as
  `items_random.tbc.json`).
- `check_era.py` asserts Classic Vice Grips, not TBC.
- All nine classes have been re-scored into `GearQuest/_generated/`.

## Stat weights (Forever model)

`data/weights.json` is the Forever combat scale: no expertise / armour pen /
resilience, unified Hit/Crit/Haste, hunter 1 Agi = 1 RAP, 14 AP = 1 DPS, no
Steady Shot, shaman no dual wield. Level 60 is scored from the model
(`GQ_NO_GUIDES=1`); Classic Wowhead BiS guides stay out until we write
Forever ones.

`check_roles.py` enforces the role split: casters carry no str/ap/rap;
physical specs carry no sp/heal except Ret, Enhance, Enhancement Tank,
Paladin Protection, and Shockadin. Warrior Protection is physical (no SP/heal).
Shockadin is spell Retribution: spell power and holy spell power, healing 0.

### Wand damage

Priest, mage, and warlock `dpsWeightRanged` is **7**, the same scale as a
warrior's melee weapon. These classes cast, then wand. A higher-DPS wand
is the ranged hunt. Greater Magic Wand is the client **17.5** DPS
(22–41 Arcane), not the older 11.39 Wowhead line.

### Warlock schools

Healing Done is not spell damage for Affliction, Demonology, or
Destruction. A line that is only healing scores as nothing. An unequal
"healing up to X and damage up to Y" scores the damage half.

`Increases damage done by Shadow/Fire/Frost/Nature/Arcane/Holy spells`
is that school's spell power. It has to be on the item stats, not only
in the effect sentence.

Affliction is shadow (`spShadow` 0.95, fire near 0). Spirit is raised
because Life Tap scales with it, and crit is real because DoTs can crit.
Demonology prefers generic spell power; shadow and fire are both partial.
Destruction prefers fire (`spFire` 0.95) over shadow (`spShadow` 0.2),
and crit is its highest of the three specs because of Ruin. Hit stays
above crit on all three.

### Holy paladin

Holy levels in melee, then wears mail and, from 40, plate. The scored row
in `weights.json` is what the tooltip and the hunt use. Through 60 the
leveling multipliers still apply (stamina, health, and health per 5 ×3,
armor ×2, intellect, spirit, mana per 5, and mana ×2). The tooltip prints
two decimals, so a product of 0.008 shows as 0.01.

| Stat | Raw weight | Shown through 60 |
|---|---|---|
| Healing | 1.3 | 1.3 |
| Spell power | 1.35 | 1.35 |
| Holy spell power | 1.8 | 1.8 |
| Intellect | 0.85 | 1.7 |
| Spirit | 0.3 | 0.6 |
| Mana per 5 | 1.1 | 2.2 |
| Mana | 0.04 | 0.08 |
| Crit | 0.8 | 0.8 |
| Stamina | 0.3 | 0.9 |
| Armor | 0.004 | 0.01 on the tooltip (0.008 before rounding) |

A note written in v0.3.6 said healing, spell power, and holy spell power
were **1.8**, intellect **1.2** (raw 0.60), spirit **1.5** (raw 0.75), and
armor **0.15** (raw 0.075). Those figures were never copied into the weight
row. The row has been the table above since the first Classic re-score.
Do not retune the row to match that note. `+N Holy Spell Damage` is
`spHoly`, and for Holy it stays at **1.8**. Cloth is `armorClass` 0.62,
leather 0.82, mail 0.96, plate 1.0. A cloth piece shows up only when its
healing pays for the missing armor. Blacksmithing healing mail and plate
(Acolyte's, Prefect's, and the later plate sets) outrank tailoring cloth
of the same band.

Protection paladin armor is **0.2**, shown as **0.4** through 60. Its
`armorClass` is plate 1.0, mail 0.55, leather 0.35, cloth 0.18. The ×2
line on the spec tooltip is the leveling armor stat. It is not an armor
budget, and it is not why cloth loses. Generic spell power is **0.9**.
`spHoly` is **0.05**. Mana per 5 is **0.2** (shown **0.4**). Ranged attack
power is **0** on every paladin spec, including levels 1–9. Do not copy
Holy's equality rule onto Protection. `speedWeight` is **-2**: points per
second of weapon speed. A 2 second weapon loses 4 points and a 3 second
weapon loses 6, on top of melee weapon damage **0.5**. The seal lands on
each hit, so the faster weapon loses less when the stats are close. The
spec tooltip labels the row **Weapon speed** and prints **-2**. The grey
line says the same 2 second and 3 second examples. Holy and Retribution
do not use it.

### Shockadin

Shockadin is a fourth paladin spec in the log menu. It is not a talent tab.
`SPEC_BY_TAB` stays holy, protection, retribution, and the default spec stays
retribution. The label is **Shockadin**. Aliases are `shockadin` and `shock`.
It is spell Retribution: you swing, and the spell is what you are hunting.
It is not a healer. `HEALER_SPECS` does not include it.

The order is spell power, then holy spell power, then intellect, then crit.
The raw row keeps that order after the endurance multiplier:

| Stat | Raw weight | Shown through 60 |
|---|---|---|
| Spell power | 1.0 | 1.0 |
| Holy spell power | 0.85 | 0.85 |
| Intellect | 0.4 | 0.8 |
| Crit | 0.55 | 0.55 |
| Hit | 0.4 | 0.4 |
| Haste | 0.3 | 0.3 |
| Strength | 0.2 | 0.2 |
| Stamina | 0.15 | 0.45 |
| Attack power | 0.1 | 0.1 |
| Spirit | 0.1 | 0.2 |
| Mana per 5 | 0.2 | 0.4 |
| Mana | 0.03 | 0.06 |
| Armor | 0.004 | 0.01 |
| Healing | 0 | 0 |

Weapon `dpsWeight` is **0.4**, so a swing still counts and a spell-power
weapon stays ahead. `speedWeight` is **-2**, the same weapon-speed penalty as
Protection. A faster weapon loses less when the spell power is close. Healing and `sp_from_heal` stay **0**. The damage half
of an Equip line still folds into spell power. Do not copy Holy's
`spHoly` equals healing rule onto this row. Holy `spHoly` stays **1.8**.
`armorClass` matches Holy: plate 1.0, mail 0.96, leather 0.82, cloth 0.62.
Do not flatten the cloth penalty.

`weaponStyle` is `onehand_shield`. Both weapon styles start checked, the
same as Holy, Elemental, and Restoration. Two-hand swords, maces, axes, and
polearms stay beside the shield. Paladins do not dual wield. The off-hand
slot stays the shield. Relics that count are Holy Shock, Exorcism, Holy
Wrath, Consecration, Seal, Judgement, and Holy Strike. Shockadin is not in
`ROTMENDER_SPECS`. The Paladin sheet column is the raw row. A suggestion
there does not change the addon until it is copied into `weights.json`.

### Hunt instructions

`sources.json` `instructions` are one short sentence. Zone, quest name, and
NPC live in their own fields — the log prints them once. World drops:
`World drop around level X-Y.` Quests: `Reward from the quest 'Name'.`
Vendors/bosses: `Bought from X.` / `Drops from X.` Auction House is a
separate BoE line, not repeated inside the sentence.

A crafted hunt states the Forever recipe skill on the line just before
Source: `Requires Leatherworking (155) to craft. Your Leatherworking is 157.`
or `You don't have Leatherworking.` That clause is green when the character's skill is at least the recipe, and red when it is short or the profession is missing. The description does not repeat that
skill. `Crafted with Leatherworking (requires skill 130).` is stripped.
In its place the description lists the recipe materials from the Wowhead
Forever spell tooltip, `Materials: Light Leather (8), Coarse Thread (4).`,
when that spell page has them. `fetch_craft_skills.py --reagents` writes
those onto `GQ.CraftSkills`. Look the skill up for every new
profession hunt, and again when an existing profession hunt is updated.
See step 6 under **When you find a new or retuned item**. The character's
rank is `GetProfessions` / `GetProfessionInfo`, then the skill-line list.
Do not print a stub skill of 1. Dress Shoes (6836) have no Forever recipe,
so that line stays off.

A named dungeon boss is `boss_drop`, even when the old sentence said
"(rare elite)". Mutanus the Devourer is Wailing Caverns, not a world drop.
A generic mob in a dungeon or raid is not a boss. **Druid of the Fang**
drops **Gloves of the Fang**, and that source is `raid_trash`. The log
labels `raid_trash` **Dungeon & Raid trash**, one filter for dungeon trash
and raid trash. Wowhead leaves the boss flag off real bosses (Edwin
VanCleef has none), so a missing flag does not make a boss into trash.
`bossNpcs` stays a boss. A rare that is not on that list is `rare_npc`.
`apply_named_drop_kinds` in the ingest promotes those from
`dungeon_entrances.json` `bossNpcs` and sets the zone to that dungeon.
"(rare spawn)" and a "(rare elite)" that is not one of those bosses is
`rare_npc` ("Rare NPC"). The pin is where that rare spawns. A rare inside a
dungeon uses the entrance. A green from a world drop or a rare uses the
client tooltip. When it is a random suffix, the line under that tooltip
names the jackpot roll. Paint the stored Wowhead tip only when the client
has no such item, with the two red lines under it.

**Lookie's Spyglass** (273298) is `boss_drop`, "Drops from Cookie.", zone
The Deadmines, npc Cookie. Do not patch that by replacing the first shared
"Indexed from Wowhead Forever" sentence in a generated file. That sentence
belongs to other items. Patch the spyglass fact line, or re-score from
`sources.json`.

Wowhead HTML tooltips must replace `<br>` / `</div>` with newlines before
stripping tags (`probe_forever_hunt_tooltips.plain`). The log must not
paste `foreverAudit.tip` into the parchment (that is how
`ItemLevel27Bindswhenequipped` happened).

Full write-up: [../../docs/FOREVER-DATA-MIGRATION.md](../../docs/FOREVER-DATA-MIGRATION.md).

## Map tracking

### Coordinate line (built)

The log description prints one coordinate line **below** the Source line
when a pin exists. When a hunt has more than one spot this faction can
use, `NearestCoordinateSpot` picks the closest. The last shown spot stays
until another is at least 20 yards closer, so a camp of spawns does not
swap the line on every step. The guide aims at that same spot. Show on map
opens the zone. Hunt pins are on the world map only.

```
Coordinates: Elwynn Forest 48.2, 42.8 (beginning of the quest or chain)
Coordinates: Ashenvale 61.4, 83.8 more coordinates for this (vendor that sells this)
```

The zone name is part of the line because a dungeon door sits on a different
map than the dungeon. Faction is a filter: the viewer sees their faction
(or the simulated faction) plus neutral spots. "more coordinates for this"
means another valid spot exists for that faction, even when only the first
pin is stored.

`GQ.Data.coordinates` lives in
`GearQuest/_generated/Data.Coordinates.generated.lua`. `Data.lua`
`CoordinateLine` formats it. Rebuild with
`python pipeline/scripts/index_coordinates.py` (resume cache in
`pipeline/data/forever_wowhead/coord_cache.json`). Items with no pin are
listed in `pipeline/data/coordinate_gaps.json`.

Notes by source:

- Quest: where the first step of the chain begins. Walk the Wowhead series
  to that quest and pin its start. A later step's giver is where you
  continue, not the pin. If the first step starts inside a dungeon, pin
  that entrance. Heavehammer's chain starts at Lost Relic Carry (Alliance,
  quest 95810) and Elder Knowledge (Horde, quest 95664), both at the
  Excavation Site door in the Wetlands (47.8, 56.3), not at Whelgar or
  Bashana. Rage of the Storm (280604) and the other Tempest's Weapons
  rewards start at Call of Air: Alliance Ironforge 46.2, 13.0 (94789),
  Horde Orgrimmar 37.4, 37.2 (1531) and Thunder Bluff 24.2, 20.4 (1532).
  Wowhead's Horde series begins at Elemental Aid with Rau Cliffrunner;
  that giver is the next step. `(beginning of the quest or chain)`
- Boss and raid trash: the dungeon or raid entrance, not the boss room.
  `(entrance to dungeon or raid)`
- Vendor: every NPC who sells it. The line shows the seller closest to
  the character. `(vendor that sells this)`
- World drop: a published camp in every zone a dropping creature lives in,
  up to three when they are far apart, plus a dungeon entrance when a
  dropper is inside. The line shows the closest camp. `(a farming spot)`
- World boss with an outdoor pin: `(where this boss spawns)`

Classic dungeon doors are the pre-Cataclysm Questie entrance table (Forever
still uses classic geography). Forever doors with exact numbers: Hall of
Thanes 43.6, 51.7 in Ironforge, Ruins of Lordaeron 71.6, 11.4 in
Undercity, Excavation Site 47.8, 56.3 in the Wetlands (Wowhead Forever
dungeon guide, zone 11 pin "Entrance to Excavation Site"), and City of
Dalaran in Alterac Mountains (map 1416): Alliance 14.2, 61.1 in front of
the city, Horde 8.8, 59.6 at the outside sewer. These five have a
description only, so nothing is pinned there: The Drowned City (Gillijim's
Isle), Krol'dok Stronghold (Riverglades), Alcaz Prison (Alcaz Island),
Blackmaw Hold (northern Azshara), Shaper's Terrace (northern Un'Goro).
Table: `pipeline/data/dungeon_entrances.json`.

### What could not be indexed (2 Oct 2026)

Of 8,096 hunt items, **5,555** have a line and **2,541** do not. A second
pass filled gaps from the Questie location index
(`pipeline/scripts/enrich_coordinates.py`) and left every pin we already
had in place. That index is not loaded at runtime.

| Source | With a line | Without | Why the rest are missing |
|---|---:|---:|---|
| Boss drop | 663 | 0 | Classic entrance, or the two Forever doors above |
| Profession | 1,082 | 0 | Capital-city trainer for each faction |
| Quest reward | 1,501 | 103 | Starter has no outdoor pin in either index |
| Vendor | 768 | 661 | 257 unnamed; the rest have no outdoor pin |
| World drop | 1,521 | 1,757 | No named creature, and Questie has no classic-map spawn either |
| Object | 15 | 9 | Container was not a named object |
| Container / fishing | 4 | 10 | The container or pool is still unnamed |

Do not invent a city pin for a battleground vendor, and do not invent
numbers for the six Forever doors above.

### Pins (built)

Tracking a gearquest puts one pin on the world map, the same spot the
coordinate line shows for the viewer's faction. The pin leaves when the
hunt is untracked. The minimap does not draw hunt pins.

`Pins.lua` `PIN_ICONS` is one texture per normalized source, drawn at 24px
on the map and 18px in the filter list. `ApplyIcon` sets the texture. It
does not clear the icon's anchors, so a filter icon keeps its own point.

| Source | Art |
|---|---|
| Boss drop | `Interface\TargetingFrame\UI-RaidTargetingIcon_8` (skull) |
| Container | `Interface\GossipFrame\BankerGossipIcon` (chest) |
| Dungeon & Raid trash | `Interface\TargetingFrame\UI-RaidTargetingIcon_7` (red raid mark) |
| Profession | `Interface\QuestFrame\UI-QuestLog-BookIcon` |
| Quest reward | `Interface\GossipFrame\AvailableQuestIcon` (regular quests) |
| Dungeon quest | atlas `questlog-questtypeicon-dungeon`, else the dungeon crop of `Interface\QuestFrame\QuestTypeIcons`. The hunt, the parchment title, the Quest reward flyout, and the map pin use it when the quest sends you into an instance. |
| Rare NPC | atlas `nameplates-icon-elite-silver`, else a crop of `UI-TargetingFrame-Rare` |
| Unsourced | `GearQuest/Art/GQ-Unsourced.png` (orange circle). The old ready-check mark is not used. |
| Vendor | `Interface\Cursor\Buy` (the buy-cursor sack) |
| World drop | `GearQuest/Art/GQ-WorldDrop.png` (sunset over dark hills). `Interface\Icons\Spell_Nature_FarSight` is not in this client, so that path draws nothing. |

Fishing and skinning use the profession book. A container source uses the chest. `Interface\GossipFrame\VendorIcon`
is not on this client. The world-drop icon is not the micro-button globe:
that texture is a tall button, and a crop of it draws as a dash or as
nothing. It is also not `Spell_Nature_FarSight`: that file is not in this
client, and `SetTexture` on it leaves the pin blank. The sunset is
`GQ-WorldDrop.png` in the addon, and the path includes `.png`.

The guided pin gets a blue ring (`UI-Minimap-Ping-Center`). Other pins do
not. Left-click calls `GQ.Guide:ShowEntry`. Right-click calls
`GQ.Tracker:OpenHunt`, which opens the log on Active and selects that hunt.
The tooltip lines are exactly `Left-click to Guide` and
`Right click to open Hunt`.

The Filter menu draws the same icon after the checkbox and before the
label. Profession, Boss drop, and Dungeon & Raid trash flyout rows do not.
The row hit width includes the icon.

The pin table is ours. Questie is not required in game.

### Guide (built)

`Guide.lua` loads after `Tracker.lua`. One guided hunt per character,
`GearQuestForeverCharDB.guideEntryId`. `settings.hideGuideArrow` is
account-wide and hides the arrow without clearing the id. A logout
countdown (`PLAYER_CAMPING`, cleared again if the player cancels) clears
only `guideEntryId`. `/reload` keeps it. `ReloadUI` and `C_UI.Reload` are
not replaced: `C_UI.Reload` is protected, and a replacement makes the
AddOn List Reload button fail with `Interface action failed because of an AddOn`.
Tracked hunts are not cleared. An old account-wide `settings.guideEntryId`
is dropped on init.

The frame `GearQuestGuide` is anchored `BOTTOMLEFT` of the arrow to
`TOPLEFT` of the tracker, offset `0, 4`. Dragging the arrow calls
`StartMoving` on the tracker. The texture is
`Interface\AddOns\GearQuestForever\Art\GQ-GuideArrow3D.png`, 32 frames in
one horizontal strip. Display size is 110×110. Frame 0 is the tip pointing
forward. `SetTexCoord` selects the frame. `SetRotation` is never called.
Inside 12 yards (`HERE_YARDS`) the text is `Here` and the frame is 16,
which points back at the player.

Aim matches TomTom and HereBeDragons. `atan2(east, north)` is normalized so
0 is north and the angle grows counterclockwise, the same way
`GetPlayerFacing` works. The sprite frames then turn clockwise, so the
bearing is `facing - angle`. `angle - facing` points the wrong way,
including west. If facing is not a number, facing stays 0.

Yards come from `GetWorldPosFromMapPos`. `WorldBasis` samples a step east
and a step north on that map, because world x is not east on every map.
The player delta is projected onto those two axes.

A hunt on another continent aims at the dock this character should board.
The ride is the one with the shortest walk to that dock plus the shortest
walk after the last landing, including a walk between two ships. The arrow
text stays `Ship`, `Zeppelin`, or `Skycutter`. Hovering it names the dock
and where to get off, `Ship in Auberdine to Southshore`. Inside 12 yards it
still says `Here`. The user waypoint stays on the hunt (`PlaceForeverPin`).
On arrival both are on one continent and the arrow aims at the pin.

Menethil Harbor, Southshore, and Auberdine are one ship, both ways.
Southshore is the stop in the middle, so the return from Auberdine calls
at Southshore before Menethil. Stormwind Harbor and Auberdine are a
separate ship, both ways.

| Dock | Faction | Kind | Where |
|---|---|---|---|
| Durotar zeppelin | Horde | Zeppelin | 50.8, 13.6, to Tirisfal and Grom'gol |
| Tirisfal zeppelin | Horde | Zeppelin | 61.0, 59.0, to Durotar and Grom'gol |
| Grom'gol | Horde | Zeppelin | Stranglethorn Vale 31.5, 29.6, to Durotar and Tirisfal |
| Ratchet | Both | Ship | The Barrens 63.6, 38.7, to Booty Bay |
| Booty Bay | Both | Ship | Stranglethorn Vale 26.0, 73.2, to Ratchet |
| Auberdine | Alliance | Ship | Darkshore 32.7, 43.7, to Southshore and Stormwind Harbor |
| Menethil north | Alliance | Ship | Wetlands 4.7, 57.0, to Southshore |
| Southshore | Alliance | Ship | Hillsbrad Foothills 50.6, 61.0, to Auberdine and Menethil Harbor |
| Stormwind Harbor | Alliance | Ship | Stormwind City 22.6, 56.1, to Auberdine |
| Menethil south | Alliance | Ship | Wetlands 5.0, 63.0, to Theramore |
| Theramore | Alliance | Ship | Dustwallow Marsh 71.0, 56.0, to Menethil south |
| Steamwheedle Port | Both | Ship | Tanaris 66.6, 22.0, to Powderfuse Port |
| Powderfuse Port | Both | Ship | Riverglades 78.1, 51.9, to Steamwheedle Port |
| Valanaar east | Alliance | Skycutter | Zephras Isle 65.9, 83.5, to Dalaran |
| Dalaran | Alliance | Skycutter | Alterac Mountains 12.5, 51.8, to Valanaar east |
| Valanaar west | Horde | Zeppelin | Zephras Isle 57.9, 80.9, to Skywatcher Plateau |
| Skywatcher Plateau | Horde | Zeppelin | Mulgore 34.3, 25.8, to Valanaar west |

Each tracker row has an **Enable Guide** checkbox. Checking it
calls `ShowEntry`. Clearing it calls `Dismiss`.

### Indexing a new or updated item

Every Wowhead Forever item-database scrape indexes coordinates for each
item it adds, in the same pass as the usual facts: tooltip stats, required
level, source, zone, npc, and quest. An existing item is indexed in that
pass only when its places changed: new droppers, new sellers, a source that
was empty, or a quest, door, or object pin that moved. A stat change, a
tooltip rewrite, or a rename leaves the stored coordinates as they are.
The lookup, when it runs, stores every real spot the pattern below keeps.
It does not store one pin chosen from the page. That list is what lets
`NearestCoordinateSpot` offer a nearby farm or seller to a player standing
anywhere. Also recheck items that are still Unsourced; if Wowhead now
names a source, index those ids the same way. Every new id is also checked
for New in Forever (`build_forever_new.py`) and stamped on the parchment
when the classic nether tooltip 404s. A profession source, new or already
indexed, is also checked for its recipe skill in that same pass
(`fetch_craft_skills.py`, ForeverDB `made`, confirmed on the Wowhead spell
page when it is up). Coordinates are patched with
`python pipeline/scripts/index_coordinates.py --ids <json list>`. A full
`emit()` rewrites every coordinate. The cache is
`pipeline/data/forever_wowhead/coord_cache.json` (gitignored). Use the
research user agent in that script. A Chrome user agent is rejected. An
HTTP 403 is not cached as "no pin"; the next run retries it.

The script writes `GearQuest/_generated/Data.Coordinates.generated.lua`
and `pipeline/data/coordinate_gaps.json`. The toc must keep loading
`Data.Coordinates.generated.lua`, `Map.lua`, and `Pins.lua`. An item that
lands in the gap file ships without a coordinate line. **Show on map**
stays disabled, and hovering it says we are missing exact coordinates.
Do not invent a pin so the button lights up.

What the lookup uses:

- Quest reward: where the first step of the chain begins. Walk the Wowhead
  series to that quest and pin its start. A later step's giver is where you
  continue, not the pin. If the first step starts inside a dungeon, pin
  that entrance. Heavehammer starts at Lost Relic Carry (Alliance) and
  Elder Knowledge (Horde), both at the Excavation Site door. Tempest's
  Weapons starts at Call of Air (Alliance Ironforge 46.2, 13.0; Horde
  Orgrimmar 37.4, 37.2 and Thunder Bluff 24.2, 20.4), not at Rau
  Cliffrunner. Note `(beginning of the quest or chain)`.
- Boss drop and raid trash: the dungeon or raid entrance in
  `pipeline/data/dungeon_entrances.json`, not the boss's room. Note
  `(entrance to dungeon or raid)`. Classic doors are the pre-Cataclysm
  entrance table. Forever doors with numbers are Hall of Thanes
  (Ironforge 43.6, 51.7), Ruins of Lordaeron (Undercity 71.6,
  11.4), and Excavation Site (Wetlands 47.8, 56.3). The other six Forever
  doors have a description and no numbers.
  Leave them unpinned until someone measures the door.
- Vendor: every NPC who sells it, from the Forever sold-by list. Note
  `(vendor that sells this)`. Each spot stores that seller's name (`npc`).
  The log, the guide, and the map pin use the vendor closest to the
  character. The description and the tracker say **Bought from** that
  person, not the one name stored on the hunt. Dirty Leather Bracers in
  Mulgore is Varia Hardhide at 43.8, 77.6. Lauren Newcomb is the name when
  the closest pin is hers in Undercity. A sentence after the first period,
  such as a reputation or honor cost, stays. Changing zone updates the
  parchment and the tracker. A faction-only vendor stays on
  that faction's list. When both factions sell the item, the stored hunt
  line can still name one seller per side. The line the player reads is
  the seller at the pin. `vendor_side.json` keeps an item off the
  other list only when every Wowhead seller is that one faction. A
  neutral seller stays on both. Anachronos stays on both, because both
  factions turn quests in to him. A battleground quartermaster with no outdoor
  pin stays a gap.
- World drop: a published camp in every zone a dropping creature lives
  in, from the Forever dropped-by list. Up to three spawns per zone, and
  only when they sit far apart. A dropper inside a dungeon becomes that
  dungeon's entrance. Note `(a farming spot)`. The log, the guide, and
  the map pin use the camp closest to the character. Spots are not tagged
  by faction, so both sides can farm a contested zone. Through level 15,
  when Wowhead lists no dropper, give each faction one pin already
  published on a mob, not the quest hub (`GENERIC_LOW_FARM`): Kobold
  Vermin in Elwynn Forest 47.4, 35.0 and Mottled Boar in Durotar 41.2,
  64.4 for levels 1–7, Harvest Watcher in Westfall 36.4, 50.4 and
  Plainstrider in the Barrens 47.5, 26.8 for levels 8–15. Above 15, that
  same missing-dropper case uses one shared catalog spot. Do not invent a
  coordinate.
- Profession taught by a trainer: the trainer pin. Note
  `(the trainer that teaches this)`. The six leather helms
  (Brawler's, Trapper's, Stormrider's, Wisdom's, Defender's, Totemic) are
  boss drops of the Leatherworking pattern, not the helm, and not Karolek
  or Pawani. The description says the pattern drops from those bosses and
  shows the Leatherworking skill line. The helm is crafted. All six
  patterns drop in Blackfathom Deeps, Razorfen Kraul, and the Stockade.
  Scarlet Monastery drops Brawler's, Trapper's, and Defender's only.
  Stormrider's, Wisdom's, and Totemic do not. The pin is each dungeon
  entrance that pattern drops in.
  The six Leather Armor chests and the six Leather Pants from those sets
  are Merchant's Favor patterns. Pawani sells them at the Barrens camp and
  Daniel Stitchsong sells them at the Redridge camp. Do not pin those on
  Orgrimmar or Stormwind.
- Profession bought at a Merchant's Favor camp: the vendor pin in the camps
  table above, for every leatherworking, blacksmithing, tailoring,
  enchanting, and engineering piece whose hunt sentence names that camp.
  Note `(vendor that sells the recipe)`. Do not put these on Orgrimmar or
  Stormwind. Trainer recipes stay on the trainer pins.
- World boss with an outdoor pin: `(where this boss spawns)`.

Faction is a filter on spots that carry one. A world-drop camp has no
faction, so both sides can farm it. A vendor spot keeps the seller's
faction. Set `more=true` when more than one spot is stored. The log prints
`more coordinates for this` and shows the closest spot. The guide and the
world-map pin use that same closest spot. The other spots stay in the row
so the closest one can change as the character moves. Continent overview
maps (Eastern Kingdoms, Kalimdor, Azeroth, Outland) and an exact 50, 50
center are not coordinates.

`enrich_coordinates.py` only fills gaps. It must not replace a Wowhead pin
or a dungeon door. It does not run on the scrape. Unnamed world drops that
Questie also cannot place stay in `coordinate_gaps.json`.

Show on map opens that zone and sets the user waypoint. With the mouse UI,
tracked hunts draw their frames on the map canvas through the pin mixin, so
the pin stays on the spot when the map zooms. They do not use
`AddDataProvider`, and they do not write `WorldMapFrame.pinPools`. Do not
hook `WorldMapFrame` OnShow. The map's hide must not run addon code: a data
provider, or `Hide()` on a pin while the map hides, calls
`SetPreferredGamepadInteractTarget` and taints gamepad focus, so jump and
talking to an NPC stop working after the map closes. While the gamepad UI
is on (`InputDeviceInterfaceStyle` is `1` or contains `gamepad`), the canvas
gets no frames. Show on map and the guide still set the Blizzard user waypoint.
The log itself takes the pad while it is open and GearQuest is the window
being used. On the hunt list the arrows and the left stick move a gold
chevron and a blue highlight through the hunts and skip the filters. The
chevron sits to the left of the focused control, a smaller arrow inside a larger
one, and it eases toward that control. A click on a hunt moves it onto that
row. A soft gold glow follows the portrait ring and the window edges while GearQuest is the focused window. A square
control gets the blue button highlight. A wide row gets a blue wash, and a
hunt icon gets the blue box. LB sits above the side handles and RB below
them. A dark bar under the window reads A Select, Y Filters, Navigate, and B Close.
An open filter, play style, weapon, or spec menu gets a smaller bar under it
that reads A Select, Navigate, and B Close. The arrow, the gold border, the bumper marks, and both bars
hide while another window has the pad. Opening a Blizzard window while GearQuest has the pad gives that window the pad. A click anywhere on GearQuest takes the pad back. That check only reads
FrameControlsManager.currentFrame. Do not call its methods. Down on the hunt list moves to the next hunt. Up from the top hunt reaches Active, Completed, and Removed. Left and right move among those tabs, and down from a tab returns to the first hunt. On Settings, Lookup, and the Simulator, up and down walk the next control in that column and stop at the ends. Left and right move only when a control sits that way. One press is one action. A direction does not also confirm or close. Closing Play Style, the source filter, or the weapon menu clears the highlight, so a card that just closed does not leave the blue square on the list. The top face button (Y / Triangle) moves the arrow onto the source filter, Play style, and the weapon arrows, and does not change the list. A second Y returns to the hunts. A on a filter control opens it. The bottom face
button (A / Cross) confirms. Moving onto a checkbox or a button does not
change it. A on a hunt moves the arrow to Track. The d-pad and the left stick
then move among Track, Show on map, and Remove, and back to the hunts. The
right stick scrolls the parchment. The bumpers do not change those tabs.
The left bumper goes to the previous page and the right
bumper to the next, wrapping across Log, Lookup, Simulator, and Settings.
The level box and the search box open the on-screen keyboard when the
highlight lands on them. While that box has focus, the pad belongs to the
keyboard, and B leaves the box. A slider still steps left and right. The right face
button closes a menu, then the filters, then the log. Button names come from the mapped pad state, lined up so the bottom face button is confirm and the right face button is back. The raw state only fills a bumper the mapped state left out. The left bumper is the previous page. Do not treat Ctrl as the left bumper, and do not relabel a direction as Jump. Do not call FrameControlsManager methods. Do not walk UIParent children. Do not call SetUIFocusState. Mouse mode never starts the driver, and the click that takes the pad back does nothing until the log is open in gamepad UI. The highlight ticks only while the log is
open. Mouse mode never starts it. Closing the log stops it. The gamepad
cursor is held off while the log is open so a direction does not click the
control under it, and it is restored when the log closes. Do not parent pin frames to the map in this mode.
Pins are placed from the addon's own update only while the map is shown.
The world-drop icon is the addon picture `GQ-WorldDrop.png`. The icon keeps
its size when the map zooms. The same pin is translated onto a continent
map. The minimap does not draw it. The guided pin has the blue ring.
Left-click guides. Right-click opens the hunt. Untrack removes the pin.
Track and Untrack are one button under the reward, beside Show on map.
Exit sits in the footer on the log, the simulator, and settings. The first
time that button is visible and enabled it pulses gold
(`GearQuestForeverDB.ui.trackSeen`), the same wash as Play Style. A greyed
or hidden button does not pulse. The first click sets `trackSeen`. Hover
text on Track is white: `Click to track this hunt. The Guide feature can be enabled.`
Show on map is white too: `See where you can find this on the world map, and let the guide show directions.`
Missing coordinates stay `We are missing exact coordinates for this item.`

The slot-rank list ("Ranked for your level") opens only from the 13×13 info
button on that header. The rest of the header still collapses the slot.
The open panel stays while the cursor is on that header or the panel.

Untrack removes the hunt immediately. There is no confirmation. A filtered
hunt, a hunt outside the top three, and a hunt tracked during a simulation
all untrack the same way.

A simulated character passes `CanPlayerEquip` after the required level.
Weapon skill and `IsEquippableItem` describe whoever is logged in, so a
level 2 would otherwise hide a level 15 hunt. The required level is still
enforced.
