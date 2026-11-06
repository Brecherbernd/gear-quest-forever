# GearQuest Forever

**GearQuest Forever** (`/gq`) is the WoW Forever fork of GearQuest. It answers: *"What should I upgrade next, and how do I get it?"*

This is a **new repo and a new CurseForge project**. The TBC Anniversary addon stays at [Henrik8210/gear-quest](https://github.com/Henrik8210/gear-quest). Do not copy that project's CurseForge ID or GitHub `CF_API_KEY` secret into this repo.

Click a gear slot on your character panel (right-click), browse from the log, or click the minimap icon to open GearQuest.

## WoW Forever

Forever is the live 1–60 Classic+ client (original continents, before Molten Core). TOC interface is **16001** (CurseForge game version **1.60.1**). After you launch the client, confirm `lastAddonVersion` in:

   `World of Warcraft\_forever_\WTF\Config.wtf`

The only install this repo syncs is the live client:

   `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns`

Lists are the Forever scoring model for all nine classes, levels 1–60, both factions, including paladin and warrior levels 1–9. Do not put a hand-written Alliance list back. Scoring rules: [pipeline/docs/FOREVER-SCORING.md](pipeline/docs/FOREVER-SCORING.md). Paladin has a fourth spec, Shockadin, for spell damage in melee. It is in the spec menu, not a talent tab. Holy, Shockadin, Elemental, and Restoration start with two-hand and one-hand both on. Rogues hunt one-hand axes, swords, maces, fists, and daggers on every spec. Assassination and Subtlety are not dagger-locked. The Weapons menu lists those types under Main Hand and under Off Hand. A one-hand weapon belongs to both hands, so one hand can hide a type while the other still shows it. A main-hand-only weapon stays under Main Hand. An off-hand-only weapon stays under Off Hand. Hunters filter the Ranged header by Bow, Gun, and Crossbow. Rank numbers stay the real ones. Protection and Shockadin score weapon speed at -2, so a faster weapon loses less when the other stats are close. Holy and Retribution do not.

**Play style** sits at the bottom of the log. Seven cards, names under the pictures, three then three, then **Focus Zone** under Manageable Dungeons. **No Dungeons!** hides hunts that send you into a dungeon or raid, including a quest that enters one. A world drop stays even when its zone is a dungeon name. World bosses and crafts you can buy stay. **Dungeon Enjoyer** keeps only those dungeon and raid hunts. The two turn each other off. **Get it now!** hides a hunt until this character meets the reputation on that item, or can make a bind-on-pickup craft. A bind-on-equip craft stays unless the item itself requires the profession to wear. **Manageable Dungeons** hides a boss drop, and dungeon and raid trash, until the level you are viewing is 4 under that item's level. The wait stops at 60. **Manageable Quests** hides a quest reward until the level you are viewing is 4 under that item's level. The wait stops at 60. A quest reward also says **Recommended to pick this quest up at level M.** M is that same wait. When the quest cannot be picked up until a higher level, M is that pickup level. **Replica Crescent Necklace** recommends 25. The earlier line, **This quest can be picked up at level N**, stays the earliest the quest can be taken. **Buy it** keeps vendor pieces and anything that is not bind on pickup, unless a vendor sells that bind-on-pickup piece. **Focus Zone** keeps a hunt only when the zone you are standing in is that hunt's zone or one of its spots. Quests, vendors, crafts, world drops, and dungeon drops all follow. A hunt with no place stays hidden. Walking into another zone changes the list. Get it now, Manageable Dungeons, Manageable Quests, Buy it, and Focus Zone can be on with either dungeon card.

The source **Filter** is alphabetical. Profession, Boss drop, Dungeon & Raid trash, and Vendor each open a flyout when checked. The trash boxes are separate from Boss drop. Select all / Deselect all on the main menu covers the sources and every flyout. Each flyout has the same button, and it covers only the boxes on that flyout. A filter or a play style fills a slot back up to the **Hunts per gear slot** count. That bar is as wide as the hunt list above it. The words sit on the left, the number on the right, and the slider fills the space between. It runs from 3 to 10. 3 is the default. The number shows while you drag, and the list updates when you let go. It is one account setting, including while simulating. Each hunt is two lines tall, with a larger gear icon and a gap before the next hunt. The first line is the item name, and **Recommended** sits after it. The second line says **New at this level**, or **Since level N** when the hunt was already on the list. **(Set piece)**, **(Guide)**, and **(Tracked)** stay on that second line. Rank numbers stay the real ones, so a later piece still says **#4**. Weapons stay one header. The character panel, the obtain toast, and **Recommended** stay on rank 1, 2, and 3. A green arrow shows when that hunt beats what you are wearing, including a later rank the slider put on the list. An empty slot counts. While simulating there is nothing worn to compare, so the listed hunts keep the arrow. Hovering a hunt fades the gold out toward the right of the row, and the selected row uses that same fade. There is no notable shelf. The **Play style** button sits under the parchment, and its left edge lines up with that parchment. It reads **Play style*** while any play style is on.

The portrait in the corner is **The GearQuest Knight**. Logging in does not open him. The first time you open GearQuest on an account, leave the window up for 5 seconds. The parchment fades in above the portrait, the tail sits just above him, and he speaks. Closing the window during those 5 seconds does not count, so the next open waits again. Once the bubble has appeared, a reload or a later login does not play it. Click the portrait to start from the first page again, or to hear the current page again if he is already talking. Hovering the portrait lights his face. The bubble has no border, and the world shows through the torn edge of the parchment. The speaker shows one line at volume 1, two lines at volume 2, and three lines at volume 3. Mute is still the speaker with a slash. Making the window larger keeps the tail on the portrait.

Page 1 asks if you are ready. It shows **Yes!** and no arrows. **Yes!** goes to page 2. From page 2 the arrows and the counter are there, **2/12** through **12/12**. **X** dismisses him. Voice is on. The speaker at the lower right mutes him. **−**, the number, and **+** sit just left of that speaker. There are three volumes, and 2 is the default. Changing the volume plays the current page again.

The page breaks where he pauses, and the words he is pointing at are black. Page 3 and page 9 print the info icon in the sentence. A gold glow marks what that page is about. The Log, Lookup, Simulator, and Settings handles glow even while you are still on another page. The controls inside a tab wait until that tab is open. Page 4 also glows the arrow on the **Weapons** header, and scrolls the list to it if it is below the fold. He walks the hunt list, the (i) and the slider, Filter and Play style, the parchment, Track, Show on map, and Remove, the Index Score bar and the spec picker, Lookup, the Simulator, and Settings. The last page glows the whole window. With the gamepad UI on, the bubble takes the pad. A selects **Yes!**, the arrows, the volume buttons, mute, and **X**. The bumpers move one page and stop at the ends. B closes the bubble, and a second B closes the log. Y does nothing while he is talking. Up from Active reaches the portrait. Mouse mode is unchanged. The hunts slider stays a mouse control.

The parchment shows **Rank #N** in a black box above the item name. That number is the slot rank, so a filtered list still shows the real place. Hovering the box says best, 2nd, 3rd, or 4th, and why a later rank is on the list. The reward name uses the item's rarity color, and the full name wraps onto the next line instead of ending in an ellipsis. A rare such as **Garb of Florid Feathers** is blue, and the strip behind the name is dark enough to read it. A quest with no earlier step says **No prequests. You can pick this quest up without finishing another quest first.** **Weather-worn Boots** say that for Princess Must Die!. A chain lists every step through the reward. **Lion-stamped Gloves** list Lost Necklace, Pie for Billy, Back to Billy, then Goldtooth. A finished step is green. A boss drop or dungeon trash hunt says **Recommended dungeon entry at level N.** N is four under the item level, and it stops at 60. The line is green once the level you are viewing has reached it, and red before that.

The green upgrade arrow stays on the unfiltered best pieces when a filter or a play style hides them, and on every hunt still showing. The obtain toast follows the unfiltered top three and any hunt you Track. A filter does not stop a tracked toast.

A crafted hunt lists the recipe materials, and the skill line just before Source. That clause is green when you meet the recipe and red when you are short or do not have the profession.

A piece you already have leaves **Active** on that character and sits on **Completed**. Another character still sees it. **Hammerbone** on a druid does not hide **Hammerbone** on a paladin.

**Lookup** is the handle under the log tabs. It searches the database for the class you are viewing. The Simulator switches that class. A chain reward lists the steps through the item. A quest with no earlier step says there are no prequests. **Thunderbrew's Boot Flask** is Sweet Amber in Westfall and requires 40.

Quest text on the parchment, the lore, and the tracker uses your character's name. **Wildhunter Cloak** no longer prints the code from the quest page. A vendor price uses the same coin icons as the game. **Sergeant's Cape** shows that price beside the coins.

The minimap button sits on the rim of the minimap.

**General → Window size** runs from 100% to 150%, one percent at a time. 100% is the normal log. 150% is half again as tall and wide. The window changes when you let go of the slider. The hunt list, the parchment, the filter, Play style, and the spec menu follow that size. The **100%** and **150%** labels are black, the same as the rest of that page. The knight's bubble grows with the window, and the tail stays on the portrait. The tracker, the guide arrow, the toast, the map pins, and item tooltips stay the normal size.

The spec menu ends with **+ custom stat weights**. Name it (20 characters), pick the premade spec it starts from, and type over any weight. An empty box shows the weight that spec uses, including the leveling multipliers through 60. A number you type replaces it, including 0, and is not multiplied again. **Save and score items!** reorders that spec's hunts. The portrait spins on the GearQuest window, not over the whole screen, and stays until the list is on screen and can scroll. The weights are saved on the account. The selected spec stays on the character. Right-click a custom spec to edit it. Delete removes it. The list only reorders pieces that spec already hunts. Weapon style and pins stay the base spec's. Embrace of the Viper and Rotmender's Raiment still count when the base spec uses them. A proc such as Thunderfury stays on the printed stats.

A Spell power number you type scores the Spell Power stat. The Equip line **Increases damage and healing done by magical spells and effects by up to N** stays on Healing. Leave Spell power empty and that line's damage half still counts as spell power, the same as the premade list. **Healing as spell power** is the box for a heal-only line.

Simulating another class and choosing a custom spec for that class builds the list. **Turn off simulation** builds your character's custom spec when that is the spec you had selected. After a reload, while a simulated class is on a premade spec, left-clicking a custom spec opens its hunts. The header uses the custom name.

A vendor line names the standing this character has. **Ratchet Wristwraps** says **Requires Friendly with Ratchet. Your standing is Neutral.** That standing clause is red while you are short and green once you have reached it. **You have not met this faction yet** appears only when this character's reputation list has no row for that faction. Neutral still counts. The bought-from line adds **(be aware that some vendors sell items at random)** after the seller's name. A reputation or honor sentence after the first period stays.

**Stormrider's Leather Pants** says **Increases damage and healing done by magical spells and effects by up to 10.** That 10 is healing and damage done. Elemental Horde, level 25–28, legs, stays rank 3. Restoration Shaman and Restoration Druid list it at 25–28, legs, rank 13. Holy Paladin lists it at 25–27, legs, rank 14. **Totemic Leather Pants** is the same sentence at 7.

If Auctionator is enabled, a hunt hover adds Auctionator's price lines under the Forever tooltip. The GearQuest score stays underneath. Nothing is added when Auctionator is off.

Eight starter drops that used to be white are green, and all nine classes were scored again. **Wispy Cloak** requires level 5. **Wendigo Fur Cloak** is +1 Strength. **Ratty Old Belt** drops from Narg the Taskmaster. **The GearQuest Community** lists Thrayne.

## GearQuest score

Hover a piece of gear and the tooltip gains a line after the stats. The same trail is on each row of the (i) rank list. The hunt list itself does not show it.

The line is **Rank #N for your level** and a GearQuest index from **0** to **100**. **100** is the best stored score in that slot at your level. **0** is the worst. That index is how the tooltip draws the score. The hunt order still uses the stored scores. There is no notable shelf. A piece only says Rank #N when it is on the list for your current level.

When the slot has something equipped, a green up arrow and **+N** means this piece is better by that many index points. A red down arrow and **−N** means it is worse. An empty slot shows the index only. The same item shows no arrow. Rings and trinkets compare to the weaker piece, and only when both slots are filled.

A set piece can stay rank 1 because the set is scored together even when another piece in the slot has a higher score on its own. The tooltip then adds **Rank 1 when you wear multiple pieces of this set.** Enhancement at 25–27: **Leggings of the Fang** stay rank 1 for Embrace of the Viper; **Triprunner Dungarees** can still read **+100**.

If the piece is gear and it is not the ranked row, the tooltip says why: the ranked suffix (**Only Pathfinder Belt of the Falcon is ranked for your level**), another level range, another spec, class, or faction, or **GearQuest has no score for this item.** Bags, quivers, and ammo are skipped. A chat link uses the same rank as the hunt list. **Kodohide Legguards** is rank 4 for Enhancement Horde at 25–27.

**General → GearQuest score on tooltips** is on by default. Simulation mode shows **Turn off simulation mode to see your GearQuest Score for this item.** The Simulator button says **Turn off simulation**.

**Hunts → Recommended gear enchantment** is off until you turn it on. The tooltip then adds one line just above the rank line. Only the words **Recommended enchantment** are yellow. The rest is the formula and the effect, in white. It uses the class and spec on screen, including while you are simulating. Enchant formulas, armor kits, and scopes are for every character. You do not need the profession. Armor on that line counts for a tank only: Protection warrior, Protection paladin, Bear, and Enhancement Tank. A scope is a bow, a gun, or a crossbow. A wand and a thrown weapon get no scope. **Enchant Cloak - Defense** is +30 armor, **Greater Defense** is +60, and **Superior Defense** is +70.

When you are not simulating, the log header is the **GearQuest Index Score** bar. It averages the index of every gear slot, from 0 to 100, in four sections of 25: green, then blue, then purple, then orange. An empty slot is 0 in that average. The hover lists the same number, and an empty slot says **(empty slot)** after it. The list is highest index first. White text above the bar reads **GearQuest Index Score - Collecting feedback on this**. **General → GearQuest score bar** is on by default. Off restores the viewing-upgrades line. The bar updates when you equip or remove a piece. Hovering it does not keep checking.

On the active list, a slot whose rank #1 you already have reads **- Rank #1 BiS acquired**. Up to three rank #1 pieces you do not have, the ones that improve what you are wearing the most, read **- Recommended**. A later rank is never the recommendation.

## Where a piece is pinned

A new item stores every real spot in the same pass it is added: the first quest in the chain, a dungeon or raid entrance, a named creature, every vendor, and a published camp in each zone a dropping creature lives in (up to three spawns per zone when they are far apart). The log offers the closest. Updating an item's quest, source, or faction indexes that coordinate in the same pass. A stat or tooltip change leaves the stored spots. Do not invent a coordinate. Heart of Disruption starts at level 30. Alliance pins Emissary Jacques in Hillsbrad Foothills (48.3, 60.1). Horde pins Magus Wordeen Voidglare in Tarren Mill (61.4, 20.8). The level-60 dungeon sets (**Feralheart**, **Beastmaster**, **Heroism**, **The Five Thunders**, **Darkmantle**, **Deathmist**, **Soulforge**, **Virtuous**, **Sorcerer's**, and the Forever copies) are quest rewards at 60. The pin is the start of the chain, **An Earnest Proposition**.

A vendor hunt names the seller at the closest pin. **Dirty Leather Bracers** in Mulgore says **Bought from Varia Hardhide.** Lauren Newcomb is the name when the closest pin is hers in Undercity. The tracker uses that same line, and both update when you change zone. A reputation or honor sentence after the name stays.

A vendor with a required standing gets its own line just before Source. The standing clause is green when this character has reached it and red when they are short. **Requires Friendly with Ratchet. Your standing is Neutral.** **You have not met this faction yet** is only for a faction missing from this character's reputation list.

With the gamepad UI on, the log takes the pad while it is open and GearQuest is the window you are using. A gold arrow, a smaller chevron inside a larger one, sits beside the focused control and eases toward it. A blue highlight marks the control, and clicking a hunt moves that arrow onto the row. The window gets a soft gold glow that follows the portrait ring. LB sits above the side handles and RB below them. A bar under the window reads A Select, Y Filters, Navigate, and B Close. An open menu gets a smaller bar that reads A Select, Navigate, and B Close. Those marks hide while another window has the pad. Opening a Blizzard window gives that window the pad. A click anywhere on GearQuest takes the pad back. Closing Play Style, the source filter, or the weapon menu clears the highlight, so the blue square does not stay on the hunt list. On the hunt list the arrows and the left stick move through the hunts and skip the filters. Down moves to the next hunt and stops at the last one. Up from the top hunt reaches Active, Completed, and Removed. Left and right move among those tabs, and down from a tab returns to the first hunt. On Settings and the other pages, up and down walk the next control in that column and stop at the ends. Left and right move only when a control is there. One press does one thing. A direction does not also confirm or close. Y moves the arrow onto the filter controls and does not change the list. A second Y returns to the hunts. A on a filter control opens it. The bottom face button confirms a checkbox, a button, or the highlighted hunt, and moving onto a control does not change it. A on a hunt moves the arrow to Track. The d-pad and the left stick then move among Track, Show on map, and Remove, and back to the hunts. The right stick scrolls the text. While the paper doll is open and the log is not using the pad, clicking the right stick opens the upgrade list for the focused slot, or the slot you last hovered. The same click closes that list. The bumpers do not change Active, Completed, or Removed. The left bumper goes to the previous page, up the side tabs, and the right bumper goes to the next, down the side tabs. From Log the left bumper wraps to Settings, and from Settings the right bumper wraps to Log. The level box and the search box open the on-screen keyboard, and B leaves that box. The right face button closes a menu, then the filters, then the log. The highlight stops when the log closes. Mouse mode does not start it. The world map still gets no GearQuest pin frames in gamepad UI. Show on map and the guide still set the waypoint.

**The GearQuest Community**, on the Settings page, lists Eao, MainWon, Stikmyre, Click, Vaniron, Thrayne, Alteredigor, and Deadlybrew.

Leveling up, changing zone, logging in, and opening a merchant spread the paper-doll arrows and the hunt list across frames. The arrows you already have stay until the new set is ready. Opening the log or a filter keeps the current rows until the rank lists are built, then swaps them in once. Hovering a tooltip and switching class in the Simulator are unchanged.

## Guide and the world map

Each tracked hunt has **Enable Guide**. One hunt is guided at a time, stored on that character (`GearQuestForeverCharDB.guideEntryId`). A logout countdown clears it. `/reload` and the AddOn List Reload button keep it. Those buttons call a protected reload, so the addon does not replace `ReloadUI` or `C_UI.Reload`. Tracked hunts stay either way. **Hide guide arrow** on the Hunts page hides the arrow for the whole account (`settings.hideGuideArrow`).

The arrow sits just above the tracker, bottom-left of the arrow on the top-left of the tracker, with a 4px gap. Dragging the arrow moves the tracker. The art is `GearQuest/Art/GQ-GuideArrow3D.png`, a 32-frame horizontal strip, 4096×128, each cell 128. It is drawn at 110×110. Frame 0 points the way you are facing, including west. The frame changes with `SetTexCoord`. The texture is never rotated. Inside 12 yards the line says **Here** and the arrow uses the frame that points back at you.

The guide samples your position once every 5 seconds and turns the arrow from that sample. The closest camp updates on a zone change, when you track the hunt, and when you select it.

On the same continent the line is yards, from the world-position delta. On another continent the arrow aims at the nearest dock this faction can board whose other end is the hunt's continent. The dock is found from the map, so a client in another language still aims at the ship, zeppelin, or skycutter. The line names the dock: **Ship in Menethil Harbor**, **Ship in Auberdine**, **Zeppelin in Durotar**. Those words stay English. The world-map waypoint stays on the hunt. Arrival on that continent aims at the pin again.

Published docks only. Horde zeppelins: Durotar 50.8, 13.6, Tirisfal Glades 61.0, 59.0, and Grom'gol in Stranglethorn Vale 31.5, 29.6. Both factions: Ratchet 63.6, 38.7 and Booty Bay 26.0, 73.2. Alliance ships: Auberdine 32.7, 43.7 and Menethil Harbor 4.7, 57.0; Menethil 5.0, 63.0 and Theramore 71.0, 56.0.

When a hunt has several spots for this faction, the coordinate line and the guide use the closest. That spot stays until another is at least 20 yards closer, so a camp of spawns does not swap the line on every step.

Tracked hunts pin the world map. The minimap does not. The pins are GearQuest's own frames on the map. They are not registered with the map's pin list, so closing the map with a gamepad does not block jump or talking to an NPC. The icon matches the source: skull for a boss, chest for a container, red raid mark for trash, book for a profession, yellow exclamation for a quest, silver dragon for a rare, red X for unsourced, sack for a vendor, and the sunset picture shipped with the addon for a world drop. The client does not have the Far Sight icon, so that path draws nothing. The guided pin has a blue ring. Left-click guides. Right-click opens that hunt in the log. The tooltip lines are **Left-click to Guide** and **Right click to open Hunt**.

The Filter list uses the same icons, after the checkbox and before the name. Profession, Boss drop, and Dungeon & Raid trash flyout rows do not.

The rank list on a slot header opens only while the cursor is on the info mark.

The Track button pulses gold once per account, the same wash as Play Style (`ui.trackSeen`). The pulse runs only while the button is on screen and enabled: a hunt is selected, the log page is open, and the list is not Removed. The first click dismisses it. Hovering Track, in white, says the guide can be enabled. Hovering Show on map, in white, says where the pin is and that the guide can point there.

A generic world drop through level 15 is pinned on a published mob, not the quest camp. Alliance 1–7 is Kobold Vermin in Elwynn Forest (47.4, 35.0). Horde 1–7 is a Mottled Boar in Durotar (41.2, 64.4). Alliance 8–15 is a Harvest Watcher in Westfall (36.4, 50.4). Horde 8–15 is a Plainstrider in the Barrens (47.5, 26.8). **Patchwork Cloak** uses the 1–7 pair. **Calico** uses the 8–15 pair. Quest starts stay where the quest begins. The Durotar quest camp is still 42.0, 68.4. Above 15 both factions share the catalog spot. A named creature stays on that creature.

## Commands

| Command | Action |
|---------|--------|
| `/gq` or `/gearquest` | Toggle GearQuest log |
| `/gq log` | Toggle log |
| `/gq class hunter` | Set preview class |
| `/gq level 37` | Set preview level |
| `/gq spec holy` | Set preview specialization |
| `/gq faction alliance` | Set preview faction |
| `/gq set on` / `/gq set off` | Enable or disable preview mode |
| `/gq set me` | Copy your real character into preview (Reset on the Simulator tab) |
| `/gq help` | List commands |
| `/gq seen` | The seen-item notebook is retired. Item facts come from Wowhead Forever. |

**Minimap:** any click opens GearQuest. Use the **Simulator** handle tab (class, faction, spec, level 1–60). **Turn off simulation** = `/gq set me`.

The AddOn List, on the character selection screen, shows the loot sack on **GearQuest Forever**, the same picture as the minimap button. Each class row shows that class's icon: Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, and Warrior. Those rows stay load-on-demand. The pictures do not change the hunts.

## Local WoW install

After **every** edit under `GearQuest/` (Lua, `_generated/`, art), sync to the live Forever client. The repo is not what WoW loads until you do. The addon folder is **`GearQuestForever`**.

```powershell
.\scripts\sync-addon.ps1
```

That copies into `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns` and nowhere else.

The log shows a line under the **GearQuest** title: **simulation mode** (level, spec, class, faction) or **live character** + spec picker hint.

## Development

- Source in repo: `GearQuest/`; game folder / CurseForge package: **`GearQuestForever`** (`GearQuestForever.toc`)
- In-game title: **GearQuest Forever**
- Interface: `## Interface: 16001` (CurseForge **WoW Forever 1.60.1**)
- Project brief: [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Data rules: [docs/DATA_RULES.md](docs/DATA_RULES.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- BiS scorer (authors only, not in CurseForge zip): [pipeline/README.md](pipeline/README.md) — adding Forever items: [pipeline/docs/FOREVER-SCORING.md](pipeline/docs/FOREVER-SCORING.md)
- CurseForge: [RELEASE.md](RELEASE.md)

## CurseForge

CurseForge project **1698950** (`## X-Curse-Project-ID: 1698950`). Follow [RELEASE.md](RELEASE.md). Never use TBC GearQuest `1669225`.

## License

See repository license file when added.
