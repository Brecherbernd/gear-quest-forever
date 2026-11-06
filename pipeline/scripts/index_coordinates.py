"""Index one map coordinate per hunt item and emit it for the log.

Wowhead Forever entity pages carry g_mapperData. Dungeon bosses have an empty
map, so their pin is the entrance in pipeline/data/dungeon_entrances.json
(classic doors, plus the two Forever doors that have numbers).

Resume-safe. The cache is pipeline/data/forever_wowhead/coord_cache.json.

  python pipeline/scripts/index_coordinates.py
  python pipeline/scripts/index_coordinates.py --smoke
  python pipeline/scripts/index_coordinates.py --emit-only
"""
from __future__ import annotations

import gzip
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commerce_camps import CAMP_NOTE, camp_pins
from gq_paths import ADDON_GEN, DATA

UA = "wow-classic-data-research/1.0 (+contact: local script)"
DELAY = float(os.environ.get("GQ_COORD_DELAY", "0.7"))
DOORS = json.loads((Path(DATA) / "dungeon_entrances.json").read_text(encoding="utf-8"))
CACHE_PATH = Path(DATA) / "forever_wowhead" / "coord_cache.json"
QUEST_XML = Path(DATA) / "forever_wowhead" / "quest_req_cache.json"
JSON_BLOCK = re.compile(r"<json><!\[CDATA\[(.*?)\]\]></json>", re.S)
GAPS_PATH = Path(DATA) / "coordinate_gaps.json"
LUA_PATH = Path(ADDON_GEN) / "Data.Coordinates.generated.lua"
SOURCES = Path(DATA) / "sources.json"
ITEMS = Path(DATA) / "items.json"
GENERATED = Path(ADDON_GEN)

NOTE_QUEST = "beginning of the quest or chain"
NOTE_DOOR = "entrance to dungeon or raid"

# The first quest in the chain starts inside this dungeon (a drop or an
# indoor NPC), so the pin is the entrance. The turn-in on that quest page
# is where you hand the step in, not where the chain begins.
QUEST_START_DOOR = {
    95810: "Excavation Site",  # Lost Relic Carry (Alliance) — Relic Guardian
    95664: "Excavation Site",  # Elder Knowledge (Horde) — same dungeon
    6522: "Razorfen Kraul",  # An Unholy Alliance — Small Scroll from Charlga Razorflank
    6564: "Blackfathom Deeps",  # Allegiance to the Old Gods
    7461: "Dire Maul",  # The Madness Within — Shen'dralar Ancient
    1487: "Wailing Caverns",  # Deviate Eradication — Ebru. Pattern: Deviate Scale Belt
}
# Wowhead's series on the reward is one faction's chain. The other faction
# starts the same rewards at these quests. Pin those starts too.
# Turn-ins with no Wowhead quest, and rewards whose shared quest name would
# take the wrong Side. --repair-quests rebuilds quest_faction from quest
# rewards, then these sides replace whatever that pass parsed.
# Malignant Root: Rotheap Inards to Rethiel the Greenwarden, who is hostile to the Horde.
HAND_FACTION = {
    # Heart of Disruption is two quests with one name. Alliance 92458 chooses
    # Spellguard Pauldrons, Renewing Footpads, or Defender of Dalaran. Horde
    # 96984 chooses Battle Spaulders, Enchanted Sandals, or Striking Staff.
    279839: "Alliance",
    279840: "Alliance",
    279841: "Alliance",
    279842: "Horde",
    279843: "Horde",
    279844: "Horde",
    # Opportunistic Education is Side: Horde. City of Dalaran, Rexxie Copperclutch.
    279845: "Horde",
    279846: "Horde",
    282283: "Alliance",
}

EXTRA_CHAIN_ROOTS = {
    96016: (1531, 1532),  # Alliance Tempest's Weapons — also pin Horde Call of Air
}
# The series begins at a later giver. Pin these quests instead of that root.
# Horde Tempest's Weapons lists Elemental Aid (Rau Cliffrunner) as step 1.
# Call of Air is the starter; Prate Cloudseer is where that step turns in.
REPLACE_CHAIN_ROOTS = {
    79442: (1531, 1532),
}
# The quest page has no start pin. The note that begins the chain drops from
# this patrol. Three published camps, far apart, so the log can pick the nearest.
ITEM_START_PINS = {
    4881: (
        {"map": "Thousand Needles", "mapId": 1441, "x": 18.4, "y": 22.2, "faction": "Horde", "npc": "Galak Messenger"},
        {"map": "Thousand Needles", "mapId": 1441, "x": 28.2, "y": 33.4, "faction": "Horde", "npc": "Galak Messenger"},
        {"map": "Thousand Needles", "mapId": 1441, "x": 39.6, "y": 32.2, "faction": "Horde", "npc": "Galak Messenger"},
    ),
}
NOTE_VENDOR = "vendor that sells this"
NOTE_FARM = "a farming spot"
NOTE_RARE = "where this rare spawns"
NOTE_OBJECT = "one of the spots to farm it"
NOTE_BOSS = "where this boss spawns"

_last = 0.0


def fetch(url: str) -> str:
    global _last
    wait = DELAY - (time.time() - _last)
    if wait > 0:
        time.sleep(wait)
    # A 403 is Wowhead asking us to stop. Wait minutes, then try once more.
    pauses = (180, 360)
    for attempt in range(len(pauses) + 1):
        _last = time.time()
        req = urllib.request.Request(
            url, headers={"User-Agent": UA, "Accept-Encoding": "gzip"}
        )
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                raw = resp.read()
                if resp.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
                return raw.decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code in (403, 429) and attempt < len(pauses):
                pause = pauses[attempt]
                print(f"  HTTP {e.code} waiting {pause}s", flush=True)
                time.sleep(pause)
                continue
            if e.code == 404:
                return ""
            raise
    return ""


def load_cache() -> dict:
    cache = {"search": {}, "npc": {}, "quest": {}, "object": {}, "itemQuest": {}, "itemLists": {}}
    if CACHE_PATH.exists():
        stored = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
        if isinstance(stored, dict):
            cache.update(stored)
    for key in ("search", "npc", "quest", "object", "itemQuest", "itemLists"):
        if not isinstance(cache.get(key), dict):
            cache[key] = {}
    return cache


def save_cache(cache: dict) -> None:
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE_PATH.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cache, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    tmp.replace(CACHE_PATH)


def json_scripts(html: str) -> dict:
    out = {}
    for m in re.finditer(
        r'<script type="application/json" id="data\.([^"]+)">(\[.*?\])</script>',
        html,
    ):
        try:
            out[m.group(1)] = json.loads(m.group(2))
        except json.JSONDecodeError:
            continue
    return out


def listviews(html: str) -> list[dict]:
    blobs = json_scripts(html)
    views = []
    for m in re.finditer(r"new Listview\(\{(.*?)\}\);", html, re.S):
        body = m.group(1)
        template = re.search(r'template:\s*"([^"]+)"', body)
        lid = re.search(r"\bid:\s*\"([^\"]+)\"", body)
        page = re.search(r'getPageData\("([^"]+)"\)', body)
        data = blobs.get(page.group(1)) if page else None
        views.append(
            {
                "template": template.group(1) if template else "",
                "id": lid.group(1) if lid else "",
                "data": data if isinstance(data, list) else [],
            }
        )
    return views


def faction_from_react(react) -> str | None:
    if not isinstance(react, list) or len(react) < 2:
        return None
    alliance, horde = react[0], react[1]
    a = alliance == 1
    h = horde == 1
    if a and not h:
        return "Alliance"
    if h and not a:
        return "Horde"
    return None


def mapper_spots(html: str) -> list[dict]:
    i = html.find("g_mapperData")
    if i < 0:
        return []
    eq = html.find("=", i)
    if eq < 0:
        return []
    start = html.find("{", eq)
    bracket = html.find("[", eq)
    if start < 0 or (bracket >= 0 and bracket < start):
        return []
    depth = 0
    for p in range(start, len(html)):
        if html[p] == "{":
            depth += 1
        elif html[p] == "}":
            depth -= 1
            if depth == 0:
                try:
                    data = json.loads(html[start : p + 1])
                except json.JSONDecodeError:
                    return []
                break
    else:
        return []
    spots = []
    seen = set()
    if not isinstance(data, dict):
        return []
    for groups in data.values():
        if not isinstance(groups, list):
            continue
        for group in groups:
            if not isinstance(group, dict):
                continue
            map_name = group.get("uiMapName") or ""
            for xy in group.get("coords") or []:
                if not isinstance(xy, (list, tuple)) or len(xy) < 2:
                    continue
                x, y = xy[0], xy[1]
                if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
                    continue
                if x < 0 or y < 0 or x > 100 or y > 100:
                    continue
                key = (map_name, round(float(x), 1), round(float(y), 1))
                if key in seen or not map_name:
                    continue
                seen.add(key)
                spot = {"map": map_name, "x": key[1], "y": key[2]}
                ui_map = group.get("uiMapId")
                if isinstance(ui_map, int):
                    spot["mapId"] = ui_map
                spots.append(spot)
    return spots


def search_rows(kind: str, name: str, cache: dict) -> list[dict]:
    key = kind + "\n" + name.casefold()
    if key in cache["search"]:
        return cache["search"][key]
    url = "https://www.wowhead.com/forever/search?q=" + urllib.parse.quote(name)
    try:
        html = fetch(url)
    except Exception as e:
        print("  search fail", kind, name, e, flush=True)
        return []
    want = name.casefold()
    rows = []
    for view in listviews(html):
        if view["template"] != kind:
            continue
        for row in view["data"]:
            if not isinstance(row, dict):
                continue
            label = (row.get("displayName") or row.get("name") or "").casefold()
            if label == want and row.get("id"):
                rows.append(
                    {
                        "id": int(row["id"]),
                        "name": row.get("displayName") or row.get("name") or name,
                        "faction": faction_from_react(row.get("react")),
                    }
                )
    cache["search"][key] = rows
    return rows


def npc_record(npc_id: int, cache: dict, hint_faction: str | None = None) -> dict:
    key = str(npc_id)
    if key in cache["npc"]:
        row = cache["npc"][key]
        if hint_faction and not row.get("faction"):
            row["faction"] = hint_faction
        return row
    try:
        html = fetch(f"https://www.wowhead.com/forever/npc={npc_id}?power")
    except Exception as e:
        print("  npc fail", npc_id, e, flush=True)
        return {"spots": [], "faction": hint_faction}
    row = {"spots": mapper_spots(html) if html else [], "faction": hint_faction}
    cache["npc"][key] = row
    return row


def object_record(object_id: int, cache: dict) -> dict:
    key = str(object_id)
    if key in cache["object"]:
        return cache["object"][key]
    try:
        html = fetch(f"https://www.wowhead.com/forever/object={object_id}?power")
    except Exception as e:
        print("  object fail", object_id, e, flush=True)
        return {"spots": []}
    row = {"spots": mapper_spots(html) if html else []}
    cache["object"][key] = row
    return row


# Maps that belong to one faction. A pin here is that faction's, even when the
# quest page says Side: Both and the other faction turns in somewhere else.
ALLIANCE_MAPS = {
    "Northshire Valley", "Elwynn Forest", "Dun Morogh", "Coldridge Valley", "Kharanos",
    "Teldrassil", "Shadowglen", "Darnassus", "Ironforge", "Stormwind City", "Loch Modan",
    "Westfall", "Darkshore", "Redridge Mountains", "Duskwood",
}
HORDE_MAPS = {
    "Valley of Trials", "Durotar", "Razor Hill", "Orgrimmar", "Mulgore", "Camp Narache",
    "Thunder Bluff", "Deathknell", "Tirisfal Glades", "Brill", "Undercity",
    "Silverpine Forest", "The Barrens", "Camp Mojache",
}
MAP_IDS = {
    "Stormwind City": 1453, "Orgrimmar": 1454, "Ironforge": 1455,
    "Thunder Bluff": 1456, "Darnassus": 1457, "Undercity": 1458,
    "Durotar": 1411, "Mulgore": 1412, "The Barrens": 1413,
    "Teldrassil": 1438, "Dun Morogh": 1426, "Elwynn Forest": 1429,
    "Redridge Mountains": 1433, "Tirisfal Glades": 1420, "Silverpine Forest": 1421,
    "Westfall": 1436, "Darkshore": 1439, "Loch Modan": 1432, "Duskwood": 1431,
    "Hillsbrad Foothills": 1424, "Silverpine Forest": 1421,
}


def quest_side(html: str) -> str | None:
    """Alliance, Horde, or None when the quest is Side: Both.

    The end-NPC icons sit in the same infobox. Reading those marked every
    both-faction quest as Horde and then stamped the Alliance turn-in with
    that side. Friend of the Library starts in Stormwind and also turns in
    to Owen Thadd in Undercity. The Side word is often inside an
    icon-alliance or icon-horde span, so a 40-character window misses it.
    """
    i = html.find("Side:")
    if i < 0:
        return None
    window = html[i : i + 160]
    if re.search(r"icon-alliance|Side:\s*Alliance\b", window):
        return "Alliance"
    if re.search(r"icon-horde|Side:\s*Horde\b", window):
        return "Horde"
    return None


def faction_for_map(map_name: str, faction: str | None) -> str | None:
    if map_name in ALLIANCE_MAPS:
        return "Alliance"
    if map_name in HORDE_MAPS:
        return "Horde"
    return faction


def _json_object_at(html: str, start: int) -> dict | None:
    if start < 0 or start >= len(html) or html[start] != "{":
        return None
    depth = 0
    for p in range(start, len(html)):
        if html[p] == "{":
            depth += 1
        elif html[p] == "}":
            depth -= 1
            if depth == 0:
                try:
                    data = json.loads(html[start : p + 1])
                except json.JSONDecodeError:
                    return None
                return data if isinstance(data, dict) else None
    return None


def mapper_places(html: str) -> list[dict]:
    """One pin per quest NPC, faction taken from react and from the map."""
    i = html.find("new Mapper(")
    if i < 0:
        return []
    data = _json_object_at(html, html.find("{", i))
    if not data:
        return []
    places = []
    seen = set()
    for zone_obj in (data.get("objectives") or {}).values():
        if not isinstance(zone_obj, dict):
            continue
        map_name = zone_obj.get("zone") or ""
        for level in zone_obj.get("levels") or []:
            if not isinstance(level, list):
                continue
            for pin in level:
                if not isinstance(pin, dict):
                    continue
                coords = pin.get("coords") or []
                if not coords and pin.get("coord"):
                    coords = [pin["coord"]]
                if not coords or not map_name:
                    continue
                xy = coords[0]
                if not isinstance(xy, (list, tuple)) or len(xy) < 2:
                    continue
                react_a = pin.get("reactalliance")
                react_h = pin.get("reacthorde")
                if react_a == 1 and react_h != 1:
                    fac = "Alliance"
                elif react_h == 1 and react_a != 1:
                    fac = "Horde"
                else:
                    fac = None
                fac = faction_for_map(map_name, fac)
                npc_id = pin.get("id")
                key = (fac, npc_id or map_name, pin.get("point") or "")
                if key in seen:
                    continue
                seen.add(key)
                spot = {
                    "map": map_name,
                    "x": round(float(xy[0]), 1),
                    "y": round(float(xy[1]), 1),
                    "point": pin.get("point") or "",
                    "npc": npc_id,
                }
                if fac:
                    spot["faction"] = fac
                if map_name in MAP_IDS:
                    spot["mapId"] = MAP_IDS[map_name]
                places.append(spot)
    return places


def choose_quest_places(places: list[dict], side: str | None) -> list[dict]:
    """Start pin for each faction. An end pin is used when that side has no start."""
    grouped: dict[str | None, list[dict]] = {}
    for place in places:
        fac = place.get("faction")
        if side == "Alliance" and fac == "Horde":
            continue
        if side == "Horde" and fac == "Alliance":
            continue
        grouped.setdefault(fac, []).append(place)
    chosen = []
    seen = set()
    for rows in grouped.values():
        starts = [row for row in rows if row.get("point") == "start"]
        for row in starts or rows:
            key = (row.get("faction"), row.get("npc") or (row["map"], row["x"], row["y"]))
            if key in seen:
                continue
            seen.add(key)
            chosen.append(row)
    return chosen


def series_info(html: str, quest_id: int) -> tuple[int | None, bool]:
    """First quest id in the series, and whether this quest is the last step.

    The current step is bold and has no link. Earlier and later steps are links.
    A quest with no series table is both the start and the reward.
    """
    m = re.search(r'<table class="series">(.*?)</table>', html, re.S)
    if not m:
        return None, True
    steps = []
    for num, cell in re.findall(r"<th>(\d+)\.</th>\s*<td>(.*?)</td>", m.group(1), re.S):
        link = re.search(r"quest=(\d+)", cell)
        steps.append((int(num), int(link.group(1)) if link else quest_id))
    if not steps:
        return None, True
    steps.sort()
    first = steps[0][1]
    last = steps[-1][1]
    return (first if first != quest_id else None), last == quest_id


def quest_record(quest_id: int, cache: dict) -> dict:
    key = str(quest_id)
    cached = cache["quest"].get(key)
    if cached and "isLast" in cached and "places" in cached:
        return cached
    try:
        html = fetch(f"https://www.wowhead.com/forever/quest={quest_id}?power")
    except Exception as e:
        print("  quest fail", quest_id, e, flush=True)
        if cached:
            return cached
        return {
            "startNpcs": [],
            "startObjects": [],
            "earlier": None,
            "isLast": True,
            "faction": None,
            "places": [],
        }
    start = html.find("Start:")
    end = html.find("End:", start if start >= 0 else 0)
    chunk = html[start:end] if start >= 0 and end > start else ""
    npcs = [int(n) for n in re.findall(r"npc=(\d+)", chunk)]
    objects = [int(n) for n in re.findall(r"object=(\d+)", chunk)]
    earlier, is_last = series_info(html, quest_id) if html else (None, True)
    row = {
        "startNpcs": npcs,
        "startObjects": objects,
        "earlier": earlier,
        "isLast": is_last,
        "faction": quest_side(html) if html else None,
        "places": mapper_places(html) if html else [],
    }
    cache["quest"][key] = row
    return row


def root_quest(quest_id: int, cache: dict, depth: int = 0) -> dict:
    row = quest_record(quest_id, cache)
    earlier = row.get("earlier")
    if earlier and depth < 12 and earlier != quest_id:
        return root_quest(int(earlier), cache, depth + 1)
    return row


def parse_item_xml(body: str) -> dict | None:
    m = JSON_BLOCK.search(body or "")
    if not m:
        return None
    blob = m.group(1).strip()
    if not blob.startswith("{"):
        blob = "{" + blob
    if not blob.endswith("}"):
        blob = blob + "}"
    try:
        return json.loads(blob)
    except json.JSONDecodeError:
        return None


def quest_ids_for_item(item_id: int, quest_name: str, cache: dict, xml_cache: dict) -> list[int]:
    key = str(item_id)
    if key in cache["itemQuest"]:
        return cache["itemQuest"][key]
    ids = []
    row = xml_cache.get(key) or {}
    if not row:
        try:
            row = parse_item_xml(fetch(f"https://www.wowhead.com/forever/item={item_id}&xml")) or {}
        except Exception as e:
            print("  item xml fail", item_id, e, flush=True)
            row = {}
    want = (quest_name or "").casefold()
    for entry in row.get("sourcemore") or []:
        if entry.get("t") == 5 and entry.get("ti"):
            if not want or (entry.get("n") or "").casefold() == want:
                ids.append(int(entry["ti"]))
    cache["itemQuest"][key] = ids
    return ids


def hunt_ids() -> list[int]:
    ids = set()
    for path in GENERATED.glob("Data.*.generated.lua"):
        if "Audit" in path.name or "Scored" in path.name or "Stat" in path.name:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        ids.update(int(n) for n in re.findall(r"\[(\d+)\]=\{name=", text))
    return sorted(ids)


def door_key(zone: str | None) -> str | None:
    if not zone:
        return None
    z = zone.casefold()
    keys = sorted(DOORS["entrances"], key=len, reverse=True)
    for key in keys:
        k = key.casefold()
        if z == k or k in z or z in k:
            return key
    return None


def described_key(zone: str | None) -> str | None:
    if not zone:
        return None
    z = zone.casefold()
    for key in DOORS["describedOnly"]:
        k = key.casefold()
        if z == k or k in z or z in k:
            return key
    return None


def copy_spots(spots: list[dict], faction: str | None = None) -> list[dict]:
    out = []
    for spot in spots:
        row = {"map": spot["map"], "x": spot["x"], "y": spot["y"]}
        if spot.get("mapId"):
            row["mapId"] = int(spot["mapId"])
        fac = spot.get("faction") or faction
        if fac:
            row["faction"] = fac
        if spot.get("npc"):
            row["npc"] = spot["npc"]
        out.append(row)
    return out


def shared_drop_spots(spots: list[dict]) -> list[dict]:
    """A creature, rare, or open boss is the same place for both factions."""
    for spot in spots:
        spot.pop("faction", None)
    return spots


def spots_for_npc_name(name: str, cache: dict) -> list[dict]:
    if not name or name.casefold() in ("a container", "none"):
        return []
    spots = []
    for row in search_rows("npc", name, cache):
        rec = npc_record(row["id"], cache, row.get("faction"))
        fac = rec.get("faction") or row.get("faction")
        spots.extend(copy_spots(rec.get("spots") or [], fac))
    return spots


def spots_for_object_name(name: str, cache: dict) -> list[dict]:
    if not name:
        return []
    spots = []
    for row in search_rows("object", name, cache):
        rec = object_record(row["id"], cache)
        spots.extend(copy_spots(rec.get("spots") or []))
    return spots


def quest_hits(name: str, item_id: int, cache: dict, xml_cache: dict) -> list[dict]:
    ids = quest_ids_for_item(item_id, name, cache, xml_cache) if item_id else []
    if ids:
        return [{"id": qid, "faction": None} for qid in ids]
    found = search_rows("quest", name, cache) if name else []
    if len(found) <= 1:
        return found
    # Several quests share the name. The reward is the last step of the series.
    last = []
    for hit in found:
        if quest_record(hit["id"], cache).get("isLast"):
            last.append(hit)
    return last or found


def _stamp_spot(spot: dict, faction: str | None) -> dict:
    row = {
        "map": spot["map"],
        "x": spot["x"],
        "y": spot["y"],
    }
    if spot.get("mapId"):
        row["mapId"] = spot["mapId"]
    fac = faction_for_map(spot.get("map") or "", spot.get("faction") or faction)
    if fac:
        row["faction"] = fac
    return row


CONTINENT_MAPS = {"Eastern Kingdoms", "Kalimdor", "Azeroth", "Outland"}


def _add_spot(spots: list[dict], seen: set, spot: dict) -> None:
    if not spot.get("map") or spot.get("map") in CONTINENT_MAPS:
        return
    if spot.get("x") is None or spot.get("y") is None:
        return
    key = (spot["map"], spot["x"], spot["y"], spot.get("faction"))
    if key in seen:
        return
    seen.add(key)
    spots.append(spot)


def chain_root_id(quest_id: int, cache: dict) -> int:
    """First quest in the Wowhead series. That is where the chain begins."""
    seen = set()
    current = int(quest_id)
    for _ in range(12):
        if current in seen:
            break
        seen.add(current)
        earlier = quest_record(current, cache).get("earlier")
        if not earlier or int(earlier) == current:
            break
        current = int(earlier)
    return current


def beginning_spots(quest_id: int, cache: dict, faction: str | None) -> list[dict]:
    """Where this quest starts. An end pin is the turn-in, not the start.

    A start inside a dungeon has no outdoor NPC pin. Use the entrance.
    """
    row = quest_record(quest_id, cache)
    spots: list[dict] = []
    seen: set = set()
    for place in row.get("places") or []:
        if place.get("point") != "start":
            continue
        _add_spot(spots, seen, _stamp_spot(place, place.get("faction") or faction))
    if spots:
        return spots
    fac = faction or row.get("faction")
    for npc_id in row.get("startNpcs") or []:
        rec = npc_record(npc_id, cache)
        for spot in rec.get("spots") or []:
            _add_spot(spots, seen, _stamp_spot(spot, rec.get("faction") or fac))
    for object_id in row.get("startObjects") or []:
        rec = object_record(object_id, cache)
        for spot in rec.get("spots") or []:
            _add_spot(spots, seen, _stamp_spot(spot, fac))
    if spots:
        return spots
    pinned = ITEM_START_PINS.get(int(quest_id))
    if pinned:
        for spot in pinned:
            _add_spot(spots, seen, dict(spot))
    if spots:
        return spots
    door = QUEST_START_DOOR.get(int(quest_id))
    if door:
        for spot in entrance_spots(door):
            _add_spot(spots, seen, spot)
    return spots


def spots_for_quest(name: str, item_id: int, cache: dict, xml_cache: dict) -> list[dict]:
    """Pin the start of the chain that awards the item.

    A later quest's giver is where you continue. The coordinate is where the
    first step begins. A one-step quest with no start pin still uses its end,
    because that NPC both gives and completes it.
    """
    hits = quest_hits(name, item_id, cache, xml_cache)
    spots: list[dict] = []
    seen: set = set()
    for hit in hits:
        qid = int(hit["id"])
        reward = quest_record(qid, cache)
        replace = REPLACE_CHAIN_ROOTS.get(qid)
        if replace:
            for extra in replace:
                for spot in beginning_spots(int(extra), cache, None):
                    _add_spot(spots, seen, spot)
            continue
        root_id = chain_root_id(qid, cache)
        side = reward.get("faction") or quest_record(root_id, cache).get("faction")
        chosen = beginning_spots(root_id, cache, side)
        if chosen:
            for spot in chosen:
                _add_spot(spots, seen, spot)
        for extra in EXTRA_CHAIN_ROOTS.get(qid, ()):
            for spot in beginning_spots(int(extra), cache, None):
                _add_spot(spots, seen, spot)
        if chosen or EXTRA_CHAIN_ROOTS.get(qid):
            continue
        if root_id != qid:
            continue
        for place in choose_quest_places(reward.get("places") or [], side):
            _add_spot(spots, seen, _stamp_spot(place, place.get("faction") or side))
    return spots


def faction_names(text: str) -> list[tuple[str, str]]:
    """'Alliance: Illiyana Moonblaze at Silverwing Grove' -> named quartermasters."""
    found = []
    for faction, label in (("Alliance", "Alliance:"), ("Horde", "Horde:")):
        match = re.search(re.escape(label) + r"\s+(.+?)\s+at\b", text)
        if match:
            found.append((match.group(1).strip(), faction))
    return found


def entrance_spots(key: str) -> list[dict]:
    return copy_spots(DOORS["entrances"].get(key) or [])


# Generic drops at level 1-15 get one pin per faction. Each number is the
# first Wowhead Forever spawn of a mob that actually drops that gear, not
# the quest hub in the same valley. 1-7 is Kobold Vermin and Mottled Boar.
# 8-15 is Harvest Watcher and Plainstrider. Above 15 both factions share
# the catalog spot, with no faction tag.
GENERIC_LOW_FARM = (
    ("Alliance", "Elwynn Forest", 1429, 47.4, 35.0, 1, 7),
    ("Alliance", "Westfall", 1436, 36.4, 50.4, 8, 15),
    ("Horde", "Durotar", 1411, 41.2, 64.4, 1, 7),
    ("Horde", "The Barrens", 1413, 47.5, 26.8, 8, 15),
)
GENERIC_LOW_MAX = 15


def generic_world_drop(src: dict) -> bool:
    if not src or src.get("sourceType") != "world_drop" or src.get("npc"):
        return False
    return (src.get("instructions") or "").startswith("World drop")


def generic_level_span(src: dict) -> tuple[int, int]:
    match = re.search(r"level (\d+)-(\d+)", src.get("instructions") or "")
    if match:
        return int(match.group(1)), int(match.group(2))
    gate = int(src.get("gateLevel") or 1)
    return gate, gate


def generic_rep_spot(row: tuple, tagged: bool = True) -> dict:
    spot = {
        "map": row[1],
        "mapId": row[2],
        "x": row[3],
        "y": row[4],
    }
    if tagged:
        spot["faction"] = row[0]
    return spot


def pick_low_farm(faction: str, lo: int) -> dict:
    band = 1 if lo <= 7 else 8
    for row in GENERIC_LOW_FARM:
        if row[0] == faction and row[5] == band:
            return generic_rep_spot(row)
    raise KeyError(faction)


def shared_catalog_spot(home: dict | None) -> list[dict] | None:
    if not home or home.get("x") is None or not home.get("map"):
        return None
    spot = {
        "map": home["map"],
        "x": home["x"],
        "y": home["y"],
    }
    if home.get("mapId"):
        spot["mapId"] = int(home["mapId"])
    return [spot]


def generic_faction_spots(src: dict, home: dict | None = None) -> list[dict] | None:
    """Level 1-15 fallback: one pin per faction. Above that: the catalog spot for both."""
    if not generic_world_drop(src):
        return None
    lo, _hi = generic_level_span(src)
    if lo > GENERIC_LOW_MAX:
        return shared_catalog_spot(home)
    return [pick_low_farm("Alliance", lo), pick_low_farm("Horde", lo)]


def _array_at(html: str, start: int) -> list | None:
    """JSON array that begins at start, ignoring braces inside strings."""
    if start < 0 or start >= len(html) or html[start] != "[":
        return None
    depth = 0
    in_str = False
    esc = False
    for i in range(start, min(len(html), start + 800000)):
        ch = html[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                try:
                    data = json.loads(html[start : i + 1])
                except json.JSONDecodeError:
                    return None
                return data if isinstance(data, list) else None
    return None


def listview_rows(html: str, view_id: str) -> list[dict]:
    """Inline Forever listview rows. The item page uses single-quoted ids."""
    for token in (f"id: '{view_id}'", f'id: "{view_id}"'):
        at = 0
        while True:
            i = html.find(token, at)
            if i < 0:
                break
            data_at = html.find("data:", i)
            if data_at < 0 or data_at - i > 1200:
                at = i + len(token)
                continue
            start = html.find("[", data_at)
            if start < 0 or start - data_at > 40:
                at = i + len(token)
                continue
            rows = _array_at(html, start)
            if rows is not None:
                return [row for row in rows if isinstance(row, dict)]
            at = i + len(token)
    return []


def item_related(item_id: int, cache: dict) -> dict:
    """NPC ids that drop this, and NPC ids that sell it, from the Forever item page."""
    key = str(item_id)
    stored = cache["itemLists"].get(key)
    if isinstance(stored, dict):
        return stored
    html = fetch(f"https://www.wowhead.com/forever/item={item_id}")
    drop = []
    sell = []
    if not html:
        return {"drop": drop, "sell": sell}
    for row in listview_rows(html, "dropped-by"):
        npc_id = row.get("id")
        if isinstance(npc_id, int):
            drop.append({"id": npc_id, "react": row.get("react")})
    for row in listview_rows(html, "sold-by"):
        npc_id = row.get("id")
        if isinstance(npc_id, int):
            entry = {"id": npc_id, "react": row.get("react")}
            if isinstance(row.get("name"), str) and row["name"].strip():
                entry["name"] = row["name"].strip()
            sell.append(entry)
    record = {"drop": drop, "sell": sell}
    cache["itemLists"][key] = record
    return record


# A camp this far from the ones already kept is a different place to farm.
CAMP_SEPARATION = 15.0
MAX_CAMPS_PER_MAP = 3
# A continent overview is not a place to stand.
CONTINENT_MAPS = {"Eastern Kingdoms", "Kalimdor", "Azeroth", "Outland"}


def _far_enough(spot: dict, kept: list[dict]) -> bool:
    for other in kept:
        dx = float(spot["x"]) - float(other["x"])
        dy = float(spot["y"]) - float(other["y"])
        if dx * dx + dy * dy < CAMP_SEPARATION * CAMP_SEPARATION:
            return False
    return True


def camps_from_npcs(npcs: list[dict], cache: dict, tag_faction: bool) -> list[dict]:
    """One to three published spawns per zone, plus a dungeon door when the drop is inside."""
    by_map: dict[str, list[dict]] = {}
    doors: list[str] = []
    seen_door = set()
    for npc in npcs:
        rec = npc_record(int(npc["id"]), cache)
        side = faction_from_react(npc.get("react")) if tag_faction else None
        for spot in rec.get("spots") or []:
            if spot.get("x") == 50.0 and spot.get("y") == 50.0:
                continue
            if (spot.get("map") or "") in CONTINENT_MAPS:
                continue
            door = door_key(spot.get("map") or "")
            if door:
                if door not in seen_door:
                    seen_door.add(door)
                    doors.append(door)
                continue
            row = {"map": spot["map"], "x": spot["x"], "y": spot["y"]}
            if spot.get("mapId"):
                row["mapId"] = spot["mapId"]
            elif spot["map"] in MAP_IDS:
                row["mapId"] = MAP_IDS[spot["map"]]
            # Vendor pins name the seller who stands there. World drops do not.
            seller = rec.get("name") or npc.get("name")
            if tag_faction and isinstance(seller, str) and seller.strip():
                row["npc"] = seller.strip()
                if not rec.get("name"):
                    rec["name"] = row["npc"]
            if side:
                row["faction"] = side
            elif tag_faction and spot.get("faction"):
                row["faction"] = spot["faction"]
            by_map.setdefault(row["map"], []).append(row)
    chosen: list[dict] = []
    seen = set()
    for rows in by_map.values():
        kept: list[dict] = []
        for spot in rows:
            if not _far_enough(spot, kept):
                continue
            key = (spot["map"], spot["x"], spot["y"], spot.get("faction"))
            if key in seen:
                continue
            seen.add(key)
            kept.append(spot)
            if len(kept) >= MAX_CAMPS_PER_MAP:
                break
        chosen.extend(kept)
    for door in doors:
        for spot in entrance_spots(door):
            key = (spot["map"], spot["x"], spot["y"])
            if key in seen:
                continue
            seen.add(key)
            chosen.append(spot)
    return chosen


def resolve_item(item_id: int, src: dict, cache: dict, xml_cache: dict) -> tuple[dict | None, str | None]:
    kind = src.get("sourceType") or ""
    zone = src.get("zone")
    npc = src.get("npc") or ""
    door = door_key(zone)
    if not door and npc:
        mapped = DOORS["bossNpcs"].get(npc)
        if mapped:
            door = mapped
    described = described_key(zone)

    if kind in ("boss_drop", "raid_trash"):
        door_names = []
        for zone_name in src.get("zones") or []:
            found = door_key(zone_name)
            if found and found not in door_names:
                door_names.append(found)
        if not door_names and door:
            door_names.append(door)
        if door_names:
            spots = []
            seen_door = set()
            for name in door_names:
                for spot in entrance_spots(name):
                    key = (spot.get("map"), spot.get("x"), spot.get("y"))
                    if key in seen_door:
                        continue
                    seen_door.add(key)
                    spots.append(spot)
            if spots:
                return {"note": NOTE_DOOR, "spots": spots, "more": len(spots) > 1}, None
        if described:
            return None, "entrance has no exact coordinate yet (" + DOORS["describedOnly"][described] + ")"
        if npc:
            spots = shared_drop_spots(spots_for_npc_name(npc, cache))
            if spots:
                return {"note": NOTE_BOSS, "spots": spots, "more": len(spots) > 1}, None
        return None, "dungeon entrance is not known"

    if kind == "quest_reward":
        spots = spots_for_quest(src.get("questName") or "", item_id, cache, xml_cache)
        if spots:
            return {"note": NOTE_QUEST, "spots": spots, "more": faction_more(spots)}, None
        return None, "quest starter has no map pin"

    if kind == "vendor":
        spots = camps_from_npcs((item_related(item_id, cache).get("sell") or []), cache, True)
        if not spots:
            spots = spots_for_npc_name(npc, cache)
            for spot in spots:
                spot["npc"] = npc
            if not spots:
                for named, fac in faction_names(src.get("instructions") or ""):
                    for spot in spots_for_npc_name(named, cache):
                        spot["faction"] = fac
                        spot["npc"] = named
                        spots.append(spot)
        if spots:
            return {"note": NOTE_VENDOR, "spots": spots, "more": len(spots) > 1}, None
        if not npc and "quartermaster" not in (src.get("instructions") or "").lower():
            return None, "vendor is not named"
        return None, "vendor has no map pin"

    if kind == "rare_npc":
        if door:
            spots = entrance_spots(door)
            return {"note": NOTE_DOOR, "spots": spots, "more": len(spots) > 1}, None
        if not npc:
            return None, "rare npc is not named"
        spots = shared_drop_spots(spots_for_npc_name(npc, cache))
        if spots:
            return {"note": NOTE_RARE, "spots": spots, "more": len(spots) > 1}, None
        return None, "rare npc has no map pin"

    if kind == "unsourced":
        return None, "source not listed yet"

    if kind == "world_drop":
        spots = camps_from_npcs((item_related(item_id, cache).get("drop") or []), cache, False)
        if spots:
            return {"note": NOTE_FARM, "spots": spots, "more": len(spots) > 1}, None
        if door:
            spots = entrance_spots(door)
            return {"note": NOTE_DOOR, "spots": spots, "more": len(spots) > 1}, None
        if not npc:
            if described:
                return None, "entrance has no exact coordinate yet (" + DOORS["describedOnly"][described] + ")"
            spots = generic_faction_spots(src)
            if spots:
                return {"note": NOTE_FARM, "spots": spots, "more": False}, None
            return None, "world drop names no creature"
        spots = shared_drop_spots(spots_for_npc_name(npc, cache))
        alts = [
            a.get("npc")
            for a in (src.get("alts") or [])
            if isinstance(a, dict) and a.get("npc") and a.get("npc").casefold() != npc.casefold()
        ]
        if spots:
            more = len(spots) > 1 or len(alts) > 0
            return {"note": NOTE_FARM, "spots": spots, "more": more}, None
        if door:
            spots = entrance_spots(door)
            return {"note": NOTE_DOOR, "spots": spots, "more": len(spots) > 1}, None
        return None, "drop creature has no map pin"

    if kind == "profession":
        pins = camp_pins(src.get("instructions") or "", src.get("profession"))
        if pins:
            return {"note": CAMP_NOTE, "spots": pins, "more": False}, None
        return None, "recipe trainer is not listed on the Wowhead page we can fetch"

    if kind == "object_drop":
        if npc and npc.casefold() not in ("a container",):
            spots = spots_for_object_name(npc, cache)
            if not spots:
                spots = spots_for_npc_name(npc, cache)
            if spots:
                return {"note": NOTE_OBJECT, "spots": spots, "more": len(spots) > 1}, None
        return None, "container is not a named object"

    if kind == "container":
        return None, "found inside another item, and that container has no pin"

    if kind == "fishing":
        return None, "fished up, with no pool or zone"

    if kind == "mail":
        return None, "delivered by mail"

    if kind == "special":
        if "Ragnaros" in (src.get("instructions") or ""):
            spots = entrance_spots("Molten Core")
            return {"note": NOTE_DOOR, "spots": spots, "more": len(spots) > 1}, None
        return None, "source is a special chain with no starter pin"

    return None, "source type has no coordinate"


def faction_more(spots: list[dict]) -> bool:
    """True when the viewer's own faction has a second place, not the other faction."""
    counts: dict[str | None, int] = {}
    for spot in spots:
        key = spot.get("faction")
        counts[key] = counts.get(key, 0) + 1
    return any(n > 1 for n in counts.values())


def lua_row(item_id: int, row: dict) -> str:
    spots = ",".join(lua_spot(s) for s in row["spots"])
    more = ",more=true" if row.get("more") else ""
    note = row["note"].replace('"', "")
    return f'    [{item_id}]={{note="{note}"{more},spots={{{spots}}}}},'


def patch_coordinate_rows(updates: dict[int, str]) -> None:
    """Replace or append coordinate rows. Leaves every other pin alone."""
    text = LUA_PATH.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    seen = set()
    out = []
    for line in lines:
        match = re.match(r"    \[(\d+)\]=\{", line)
        if match and int(match.group(1)) in updates:
            iid = int(match.group(1))
            if iid not in seen:
                out.append(updates[iid])
                seen.add(iid)
            continue
        out.append(line)
    missing = [iid for iid in updates if iid not in seen]
    if missing:
        while out and not out[-1].strip():
            out.pop()
        if not out or out[-1].strip() != "}":
            raise SystemExit("coordinate file does not end with }")
        close = out.pop()
        if out and not out[-1].rstrip().endswith(","):
            out[-1] = out[-1].rstrip() + ","
        for iid in sorted(missing):
            out.append(updates[iid])
        out.append(close)
    tmp = LUA_PATH.with_suffix(".lua.tmp")
    tmp.write_text(nl.join(out) + nl, encoding="utf-8", newline="")
    tmp.replace(LUA_PATH)


def lua_spot(spot: dict) -> str:
    parts = [
        f'map="{spot["map"].replace(chr(92), "").replace(chr(34), "")}"',
    ]
    if spot.get("mapId"):
        parts.append(f'mapId={int(spot["mapId"])}')
    parts.extend([
        f'x={spot["x"]}',
        f'y={spot["y"]}',
    ])
    if spot.get("faction"):
        parts.append(f'faction="{spot["faction"]}"')
    if spot.get("npc"):
        safe = str(spot["npc"]).replace("\\", "").replace('"', "")
        parts.append(f'npc="{safe}"')
    return "{" + ",".join(parts) + "}"


def emit(rows: dict[int, dict]) -> None:
    lines = []
    for iid in sorted(rows):
        row = rows[iid]
        spots = ",".join(lua_spot(s) for s in row["spots"])
        more = ",more=true" if row.get("more") else ""
        note = row["note"].replace('"', "")
        lines.append(f'    [{iid}]={{note="{note}"{more},spots={{{spots}}}}},')
    text = """local _, GQ = ...
GQ.Data = GQ.Data or {}

-- GENERATED by pipeline/scripts/index_coordinates.py
-- One displayed coordinate per hunt item. more=true means another valid
-- spot exists, so the log says so. Faction spots are filtered in the log.
-- Merchant's Favor recipes use the camp vendor, not a city trainer.

GQ.Data.coordinates = {
""" + "\n".join(lines) + """
}
"""
    LUA_PATH.write_text(text, encoding="utf-8", newline="\n")


def write_gaps(gaps: list[dict], by_type: dict) -> None:
    summary = {}
    for kind, ctr in sorted(by_type.items()):
        summary[kind] = dict(ctr)
    GAPS_PATH.write_text(
        json.dumps({"summary": summary, "gaps": gaps}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def smoke(cache: dict) -> None:
    samples = [
        ("npc", "Deputy Willem"),
        ("quest", "Bounty on Garrick Padfoot"),
        ("quest", "The Defias Brotherhood"),
        ("object", "Wooden Chair"),
    ]
    for kind, name in samples:
        rows = search_rows(kind, name, cache)
        print(kind, name, "->", rows)
        if kind == "quest" and rows:
            rec = quest_record(rows[0]["id"], cache)
            print("  quest", rec)
            root = root_quest(rows[0]["id"], cache)
            print("  root start", root.get("startNpcs"), "earlier chain", rec.get("earlier"))
        if kind == "npc" and rows:
            print("  spots", npc_record(rows[0]["id"], cache, rows[0].get("faction")))
        if kind == "object" and rows:
            print("  spots", object_record(rows[0]["id"], cache))
    rec = quest_record(166, cache)
    print("quest 166", rec)
    print("chain root npcs", root_quest(166, cache).get("startNpcs"), "faction", root_quest(166, cache).get("faction"))
    save_cache(cache)


QUEST_FACTION_JSON = Path(DATA) / "quest_faction.json"
QUEST_FACTION_LUA = Path(ADDON_GEN) / "Data.QuestFaction.generated.lua"


def write_quest_faction(sides: dict[int, str]) -> None:
    for iid, side in HAND_FACTION.items():
        sides[iid] = side
    payload = {str(iid): side for iid, side in sorted(sides.items())}
    QUEST_FACTION_JSON.write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    lines = [f'    [{iid}] = "{side}",' for iid, side in sorted(sides.items())]
    QUEST_FACTION_LUA.write_text(
        "local _, GQ = ...\n"
        "GQ.Data = GQ.Data or {}\n"
        "\n"
        "-- Exclusive quest rewards. Side: Both is omitted, so both factions see it.\n"
        "GQ.Data.questFaction = {\n"
        + "\n".join(lines)
        + "\n}\n",
        encoding="utf-8",
        newline="\n",
    )


def repair_quests(cache: dict) -> None:
    """Re-read quest Side and give each faction its own turn-in pin."""
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    xml_cache = json.loads(QUEST_XML.read_text(encoding="utf-8")) if QUEST_XML.exists() else {}
    ids = [
        iid
        for iid in hunt_ids()
        if (sources.get(str(iid)) or {}).get("sourceType") == "quest_reward"
    ]
    item_hits: dict[int, list] = {}
    quest_ids = set()
    for iid in ids:
        src = sources.get(str(iid)) or {}
        hits = quest_hits(src.get("questName") or "", iid, cache, xml_cache)
        item_hits[iid] = hits
        for hit in hits:
            quest_ids.add(int(hit["id"]))
    print(f"quest hunts {len(ids)} unique quests {len(quest_ids)}", flush=True)
    for n, qid in enumerate(sorted(quest_ids), 1):
        quest_record(qid, cache)
        root_quest(qid, cache)
        if n % 20 == 0:
            save_cache(cache)
            print(f"  quests {n}/{len(quest_ids)}", flush=True)
    save_cache(cache)
    updates = {}
    exclusive: dict[int, str] = {}
    counts: dict[str, int] = {}
    for iid in ids:
        src = sources.get(str(iid)) or {}
        side = None
        for hit in item_hits.get(iid) or []:
            rec = quest_record(int(hit["id"]), cache)
            if rec.get("faction") in ("Alliance", "Horde"):
                side = rec["faction"]
                break
        counts[side or "Both"] = counts.get(side or "Both", 0) + 1
        if side:
            exclusive[iid] = side
        spots = spots_for_quest(src.get("questName") or "", iid, cache, xml_cache)
        if not spots:
            continue
        updates[iid] = lua_row(
            iid,
            {"note": NOTE_QUEST, "spots": spots, "more": faction_more(spots)},
        )
    patch_coordinate_rows(updates)
    write_quest_faction(exclusive)
    print(f"quest pins rewritten {len(updates)} sides {counts}", flush=True)


def index_item_ids(cache: dict, only: list[int]) -> None:
    """Look up coordinates for these hunt ids and patch them in. Does not rebuild the file."""
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    xml_cache = json.loads(QUEST_XML.read_text(encoding="utf-8")) if QUEST_XML.exists() else {}
    updates = {}
    missed = 0
    for n, iid in enumerate(only, 1):
        src = sources.get(str(iid)) or {}
        try:
            row, _reason = resolve_item(iid, src, cache, xml_cache)
        except Exception as e:
            print("  fail", iid, e, flush=True)
            row = None
        if row and row.get("spots"):
            updates[iid] = lua_row(iid, row)
        else:
            missed += 1
        if n % 25 == 0:
            save_cache(cache)
            if updates:
                patch_coordinate_rows(updates)
            print(f"  indexed {n}/{len(only)} patched {len(updates)}", flush=True)
    save_cache(cache)
    if updates:
        patch_coordinate_rows(updates)
    print(f"patched {len(updates)} left without a pin {missed}", flush=True)


def main() -> None:
    cache = load_cache()
    if "--smoke" in sys.argv:
        smoke(cache)
        return
    if "--repair-quests" in sys.argv:
        repair_quests(cache)
        return
    if "--ids" in sys.argv:
        i = sys.argv.index("--ids")
        blob = json.loads(Path(sys.argv[i + 1]).read_text(encoding="utf-8"))
        index_item_ids(cache, [int(n) for n in blob])
        return
    if "--places" in sys.argv:
        ids = hunt_ids()
        sources = json.loads(SOURCES.read_text(encoding="utf-8"))
        want = [
            iid
            for iid in ids
            if (sources.get(str(iid)) or {}).get("sourceType") in ("world_drop", "vendor")
        ]
        print(f"world drop and vendor hunts {len(want)}", flush=True)
        index_item_ids(cache, want)
        return

    ids = hunt_ids()
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    xml_cache = json.loads(QUEST_XML.read_text(encoding="utf-8")) if QUEST_XML.exists() else {}
    print(f"hunt items {len(ids)}", flush=True)

    if "--emit-only" not in sys.argv:
        # Touch every entity the resolver needs. Cache makes a rerun cheap.
        names = {"npc": set(), "quest": set(), "object": set()}
        checked = 0
        for iid in ids:
            src = sources.get(str(iid)) or {}
            kind = src.get("sourceType")
            npc = src.get("npc") or ""
            if kind == "quest_reward" and src.get("questName"):
                checked += 1
                if not quest_ids_for_item(iid, src["questName"], cache, xml_cache):
                    names["quest"].add(src["questName"])
                if checked % 40 == 0:
                    save_cache(cache)
                    print(f"  quest items {checked}", flush=True)
            elif kind == "vendor" and npc:
                names["npc"].add(npc)
            elif kind in ("world_drop", "rare_npc") and npc and not door_key(src.get("zone")):
                names["npc"].add(npc)
            elif kind == "boss_drop" and npc and not door_key(src.get("zone")) and npc not in DOORS["bossNpcs"]:
                names["npc"].add(npc)
            elif kind == "object_drop" and npc and npc.casefold() != "a container":
                names["object"].add(npc)
        print(
            f"lookup npc {len(names['npc'])} quest {len(names['quest'])} object {len(names['object'])}",
            flush=True,
        )
        done = 0
        for kind in ("quest", "npc", "object"):
            for name in sorted(names[kind]):
                search_rows(kind, name, cache)
                done += 1
                if done % 25 == 0:
                    save_cache(cache)
                    print(f"  searched {done}", flush=True)
        save_cache(cache)
        # Pages for every id the searches found, plus quest-chain starters.
        seen_q = set()

        def walk_quest(qid: int) -> None:
            guard = 0
            while qid and qid not in seen_q and guard < 12:
                seen_q.add(qid)
                row = quest_record(qid, cache)
                qid = row.get("earlier")
                guard += 1
                if len(seen_q) % 25 == 0:
                    save_cache(cache)
                    print(f"  quests {len(seen_q)}", flush=True)

        for iid in ids:
            src = sources.get(str(iid)) or {}
            if src.get("sourceType") != "quest_reward":
                continue
            for qid in quest_ids_for_item(iid, src.get("questName") or "", cache, xml_cache):
                walk_quest(qid)
        for name in names["quest"]:
            for hit in search_rows("quest", name, cache):
                if quest_record(hit["id"], cache).get("isLast", True):
                    walk_quest(hit["id"])
        save_cache(cache)
        npc_ids = {}
        for name in names["npc"]:
            for hit in search_rows("npc", name, cache):
                npc_ids[hit["id"]] = hit.get("faction")
        for qid in seen_q:
            root = root_quest(qid, cache)
            for npc_id in root.get("startNpcs") or []:
                npc_ids.setdefault(npc_id, root.get("faction"))
        n = 0
        for npc_id, fac in npc_ids.items():
            npc_record(npc_id, cache, fac)
            n += 1
            if n % 25 == 0:
                save_cache(cache)
                print(f"  npcs {n}/{len(npc_ids)}", flush=True)
        obj_ids = []
        for name in names["object"]:
            for hit in search_rows("object", name, cache):
                obj_ids.append(hit["id"])
        for qkey, row in cache["quest"].items():
            obj_ids.extend(row.get("startObjects") or [])
        for i, object_id in enumerate(dict.fromkeys(obj_ids)):
            object_record(object_id, cache)
            if (i + 1) % 25 == 0:
                save_cache(cache)
        save_cache(cache)
        print(f"fetched quests {len(seen_q)} npcs {len(npc_ids)} objects {len(set(obj_ids))}", flush=True)

    rows = {}
    gaps = []
    by_type = {}
    for iid in ids:
        src = sources.get(str(iid)) or {}
        kind = src.get("sourceType") or "?"
        ctr = by_type.setdefault(kind, Counter())
        try:
            row, reason = resolve_item(iid, src, cache, xml_cache)
        except Exception as e:
            row, reason = None, "lookup failed: " + str(e)[:80]
        if row and row.get("spots"):
            rows[iid] = row
            ctr["ok"] += 1
        else:
            ctr["gap"] += 1
            ctr["gap:" + (reason or "unknown")] += 1
            gaps.append(
                {
                    "id": iid,
                    "name": (items.get(str(iid)) or {}).get("name"),
                    "sourceType": kind,
                    "reason": reason,
                    "zone": src.get("zone"),
                    "npc": src.get("npc"),
                    "questName": src.get("questName"),
                }
            )
    emit(rows)
    write_gaps(gaps, {k: dict(v) for k, v in by_type.items()})
    print(f"coordinates {len(rows)} gaps {len(gaps)}", flush=True)
    for kind, ctr in sorted(by_type.items()):
        print(f"  {kind}: ok {ctr.get('ok', 0)} gap {ctr.get('gap', 0)}", flush=True)


if __name__ == "__main__":
    main()
