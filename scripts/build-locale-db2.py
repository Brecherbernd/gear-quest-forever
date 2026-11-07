#!/usr/bin/env python3
"""Write GearQuest/Locales/<locale>.db2.lua: names from the game client's own tables.

wago.tools serves the client's DB2 tables per build and language. The Forever
client (product wowf) gives item, enchant, faction and zone names, Forever-only
ones included. It loads after <locale>.names.lua, so the client's name wins.
The Classic Era client fills two gaps: random enchant suffixes ("of the Bear"),
since the Forever build does not ship ItemRandomProperties, and the names of
Season of Discovery items the Forever tables lack.

The server patches items the base tables lack (hotfixes). An installed
client keeps those in Cache/ADB/<locale>/DBCache.bin; pass it to add them.

Only names the addon data uses are kept. Downloads (curl) are cached in <cache dir>.

Usage: build-locale-db2.py <cache dir> [frFR] [<client>/Cache/ADB/frFR/DBCache.bin]
"""

from __future__ import annotations

import collections
import csv
import importlib.util
import re
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "GearQuest"
FOREVER_BUILD = "1.60.1.70862"
ERA_BUILD = "1.15.9.70576"

spec = importlib.util.spec_from_file_location("names", ROOT / "scripts" / "build-locale-names.py")
names = importlib.util.module_from_spec(spec)
spec.loader.exec_module(names)
csv.field_size_limit(1 << 30)


def fetch(cache: Path, table: str, build: str, locale: str) -> Path:
    path = cache / f"{table}.{build}.{locale}.csv"
    if not path.exists():
        url = f"https://wago.tools/db2/{table}/csv?build={build}&locale={locale}"
        subprocess.run(["curl", "-sSf", "-o", str(path), url], check=True)
    return path


def pairs(cache: Path, table: str, column: str, locale: str, build: str = FOREVER_BUILD) -> dict[str, str]:
    """English name -> the most common translation over rows with that name."""
    def read(loc):
        with open(fetch(cache, table, build, loc), encoding="utf-8", newline="") as f:
            return {row["ID"]: row[column] for row in csv.DictReader(f)}

    english, translated = read("enUS"), read(locale)
    found: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for rid, en in english.items():
        fr = translated.get(rid)
        if en and fr and fr != en:
            found[en][fr.replace("\u2019", "'")] += 1
    return {en: counts.most_common(1)[0][0] for en, counts in found.items()}


def by_id(cache: Path, table: str, column: str, locale: str, ids: set[int], build: str = FOREVER_BUILD) -> dict[int, str]:
    """Row id -> translated name, for the given ids."""
    with open(fetch(cache, table, build, locale), encoding="utf-8", newline="") as f:
        return {int(row["ID"]): row[column].replace("\u2019", "'")
                for row in csv.DictReader(f) if row[column] and int(row["ID"]) in ids}


ITEM_SPARSE_HASH = 0x919BE54E


def hotfix_item_names(path: Path, ids: set[int]) -> dict[int, str]:
    """Item names from a client hotfix cache (XFTH records)."""
    data = path.read_bytes()
    out = {}
    i = data.find(b"XFTH", 4)  # skip the file header
    while 0 <= i <= len(data) - 32:
        magic, _push, _unique, _, table, record, size, status = struct.unpack_from("<4s7I", data, i)
        if magic != b"XFTH":
            raise ValueError(f"unexpected bytes at {i} in {path}")
        if table == ITEM_SPARSE_HASH and status == 1 and size and record in ids:
            # Description, then Display3, Display2, Display1, Display.
            name = data[i + 32:i + 32 + size].split(b"\0", 5)[4].decode("utf-8")
            if name:
                out[record] = name.replace("\u2019", "'")
        i += 32 + size
    return out


def addon_item_ids() -> set[int]:
    ids = set()
    for path in list(ADDON.glob("*.lua")) + list((ADDON / "_generated").glob("*.lua")):
        text = path.read_text(encoding="utf-8", errors="replace")
        ids |= {int(n) for n in re.findall(r"\bitemId\s*=\s*(\d+)", text)}
        if "ForeverAudit" in path.name or "ItemStats" in path.name or "HuntFacts" in path.name:
            ids |= {int(n) for n in re.findall(r"^\s*\[(\d+)\]\s*=\s*\{", text, re.M)}
    return ids


def lua_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main() -> None:
    cache = Path(sys.argv[1])
    cache.mkdir(parents=True, exist_ok=True)
    locale = sys.argv[2] if len(sys.argv) > 2 else "frFR"
    texts, fields = names.addon_texts()
    blob = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                     for p in list(ADDON.glob("*.lua")) + list((ADDON / "_generated").glob("*.lua")))

    items = pairs(cache, "ItemSparse", "Display_lang", locale)
    spells = pairs(cache, "SpellName", "Name_lang", locale)
    factions = pairs(cache, "Faction", "Name_lang", locale)
    areas = pairs(cache, "AreaTable", "AreaName_lang", locale)
    suffixes = pairs(cache, "ItemRandomProperties", "Name_lang", locale, ERA_BUILD)

    zone_ids = set(re.findall(r'^\s*\["((?:[^"\\]|\\.)*)"\] =', (ADDON / "Locales" / "Zones.lua").read_text(encoding="utf-8"), re.M))
    zone_fields = set(re.findall(r'\b(?:zone|map|place)\s*=\s*"((?:[^"\\]|\\.)*)"', blob))
    enchants = re.findall(r'name = "(Enchant[^"]+)"', (ADDON / "Enchant.lua").read_text(encoding="utf-8"))
    out = {
        "item": names.used_names(items, texts, fields["name"]),
        "enchant": {e: spells[e] for e in enchants if e in spells},
        "faction": {f: fr for f, fr in factions.items() if f'"{f}"' in blob or f"{f} - " in blob},
        "zone": {z: areas[z] for z in zone_fields - zone_ids if z in areas},
    }
    used_suffixes = set(re.findall(r'"(of [^"]+)"', blob))
    suffix = {s: suffixes[s] for s in sorted(used_suffixes) if s in suffixes}

    lines = [
        "local _, GQ = ...",
        "",
        "-- GENERATED by scripts/build-locale-db2.py from the client's DB2 tables (wago.tools).",
        "-- Do not edit by hand. Official client names, keyed by the English name.",
        f'if GQ.LOCALE ~= "{locale}" then',
        "    return",
        "end",
        "",
        "local names = GQ.LocaleNames",
    ]
    for kind, table in out.items():
        lines += ["", "for k, v in pairs({"]
        lines += [f"    [{lua_string(en)}] = {lua_string(table[en])}," for en in sorted(table)]
        lines.append(f"}}) do names.{kind}[k] = v end")
    wanted = addon_item_ids()
    item_ids = by_id(cache, "ItemSparse", "Display_lang", locale, wanted, ERA_BUILD)
    item_ids.update(by_id(cache, "ItemSparse", "Display_lang", locale, wanted))
    hotfixed = hotfix_item_names(Path(sys.argv[3]), wanted) if len(sys.argv) > 3 else {}
    item_ids.update(hotfixed)
    lines += ["", "-- Item names by item id, for items whose English name the data lacks.", "GQ.LocaleItemNames = {"]
    lines += [f"    [{i}] = {lua_string(item_ids[i])}," for i in sorted(item_ids)]
    lines.append("}")
    lines += ["", "-- Random enchant suffixes, shown after the item name.", "local L = GQ.L", "for k, v in pairs({"]
    lines += [f"    [{lua_string(en)}] = {lua_string(fr)}," for en, fr in suffix.items()]
    lines.append("}) do L[k] = v end")
    target = ADDON / "Locales" / f"{locale}.db2.lua"
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(target, {k: len(v) for k, v in out.items()}, "suffix", len(suffix), "item ids", len(item_ids), "from hotfixes", len(hotfixed))


if __name__ == "__main__":
    main()
