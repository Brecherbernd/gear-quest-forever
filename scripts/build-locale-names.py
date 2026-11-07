#!/usr/bin/env python3
"""Write GearQuest/Locales/<locale>.names.lua: official names for NPCs, quests,
items, objects and enchants, taken from QuestieDB's Forever build.

Only names the addon data actually uses are kept: npc= and questName= fields,
quoted quest names, and capitalised runs inside data text that match a name.
A name with two different translations keeps the first one after quote
normalisation; a name with no translation is left out (it stays English).

Usage: build-locale-names.py <QuestieDB>/QuestieDB_Forever.toc [frFR]
"""

from __future__ import annotations

import base64
import collections
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "GearQuest"
TYPES = {"Npc": "npc", "Quest": "quest", "Item": "item", "Object": "object"}
TEXT_FIELDS = ("instructions", "proc", "lore", "npc", "questName", "name")


def cbor(buf: bytes, i: int = 0):
    ib = buf[i]
    i += 1
    major, info = ib >> 5, ib & 31
    if info < 24:
        val = info
    elif info == 24:
        val = buf[i]
        i += 1
    elif info == 25:
        if major == 7:
            return 0.0, i + 2
        val = struct.unpack(">H", buf[i:i + 2])[0]
        i += 2
    elif info == 26:
        if major == 7:
            return struct.unpack(">f", buf[i:i + 4])[0], i + 4
        val = struct.unpack(">I", buf[i:i + 4])[0]
        i += 4
    elif info == 27:
        if major == 7:
            return struct.unpack(">d", buf[i:i + 8])[0], i + 8
        val = struct.unpack(">Q", buf[i:i + 8])[0]
        i += 8
    else:
        raise ValueError("indefinite CBOR length")
    if major == 0:
        return val, i
    if major == 1:
        return -1 - val, i
    if major in (2, 3):
        return buf[i:i + val].decode("utf-8", "replace"), i + val
    if major == 4:
        out = []
        for _ in range(val):
            item, i = cbor(buf, i)
            out.append(item)
        return out, i
    if major == 5:
        out = {}
        for _ in range(val):
            key, i = cbor(buf, i)
            out[key], i = cbor(buf, i)
        return out, i
    if major == 6:
        return cbor(buf, i)
    return {20: False, 21: True, 22: None}.get(info), i


def read_toc(path: str) -> dict[str, str]:
    meta = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("## ") and ":" in line:
                key, value = line[3:].split(":", 1)
                meta[key.strip()] = value.strip()
    return meta


def first_field(row):
    if isinstance(row, list):
        return row[0] if row else None
    if isinstance(row, dict):
        return row.get(1)
    return None


def questie_names(toc: str, locale: str) -> dict[str, dict[str, str]]:
    meta = read_toc(toc)

    def stored(key):
        value = meta.get("X-" + key)
        if value and value.startswith("~") and value.endswith("~"):
            parts = int(value[1:-1])
            value = "".join(meta[f"X-{key}-{n}"] for n in range(1, parts + 1))
        return value

    def decode(key, compressed):
        raw = base64.b64decode(stored(key))
        return cbor(zlib.decompress(raw) if compressed else raw)[0]

    result: dict[str, dict[str, str]] = {}
    for typ, kind in TYPES.items():
        ids = decode(f"{typ}-IDS", True)
        block = decode(f"l10n-{locale}-{typ}", True)
        column = block[0] if isinstance(block, list) else first_field(block)
        if isinstance(column, dict):
            column = [column.get(k) for k in range(1, len(ids) + 1)]
        found: dict[str, set[str]] = collections.defaultdict(set)
        for pos, eid in enumerate(ids):
            translated = column[pos] if column and pos < len(column) else None
            row = stored(f"{typ}-{eid}-S")
            english = first_field(cbor(base64.b64decode(row))[0]) if row else None
            if english and translated and english != translated:
                found[english].add(translated.replace("\u2019", "'"))
        result[kind] = {en: sorted(fr)[0] for en, fr in found.items()}
    return result


def addon_texts() -> tuple[list[str], dict[str, set[str]]]:
    texts: list[str] = []
    fields: dict[str, set[str]] = collections.defaultdict(set)
    files = list(ADDON.glob("*.lua")) + list((ADDON / "_generated").glob("*.lua"))
    pattern = re.compile(r'\b(' + "|".join(TEXT_FIELDS) + r')\s*=\s*"((?:[^"\\]|\\.)*)"')
    for path in files:
        if "Locales" in path.parts:
            continue
        for m in pattern.finditer(path.read_text(encoding="utf-8", errors="replace")):
            fields[m.group(1)].add(m.group(2))
            texts.append(m.group(2))
    return texts, fields


def used_names(names: dict[str, str], texts: list[str], exact: set[str]) -> dict[str, str]:
    lengths = sorted({len(n.split()) for n in names})
    keep = {n: names[n] for n in exact if n in names}
    for text in texts:
        words = re.findall(r"[\w'’:-]+|[^\w\s]", text)
        for size in lengths:
            for start in range(0, len(words) - size + 1):
                candidate = " ".join(words[start:start + size])
                if candidate in names:
                    keep[candidate] = names[candidate]
    return keep


def lua_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main() -> None:
    toc = sys.argv[1]
    locale = sys.argv[2] if len(sys.argv) > 2 else "frFR"
    names = questie_names(toc, locale)
    texts, fields = addon_texts()
    quoted = {q for t in texts for q in re.findall(r"'([^']{3,})'", t)}

    out = {
        "npc": used_names(names["npc"], texts, fields["npc"]),
        "quest": used_names(names["quest"], [], fields["questName"] | quoted),
        "item": used_names(names["item"], texts, fields["name"]),
        "object": used_names(names["object"], texts, set()),
    }
    enchant_source = (ADDON / "Enchant.lua").read_text(encoding="utf-8")
    enchants = {}
    for name in re.findall(r'name = "(Enchant[^"]+)"', enchant_source):
        formula = names["item"].get("Formula: " + name)
        if formula and "(" in formula:
            enchants[name] = re.sub(r"^Formule\s*:\s*", "", formula)
    out["enchant"] = enchants

    lines = [
        "local _, GQ = ...",
        "",
        "-- GENERATED by scripts/build-locale-names.py from QuestieDB (Forever build).",
        "-- Do not edit by hand. Official client names, keyed by the English name.",
        f'if GQ.LOCALE ~= "{locale}" then',
        "    return",
        "end",
        "",
        "local names = GQ.LocaleNames",
    ]
    for kind, table in out.items():
        lines.append("")
        lines.append(f"for k, v in pairs({{")
        for en in sorted(table):
            lines.append(f"    [{lua_string(en)}] = {lua_string(table[en])},")
        lines.append(f"}}) do names.{kind}[k] = v end")
    target = ADDON / "Locales" / f"{locale}.names.lua"
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(target, {k: len(v) for k, v in out.items()})


if __name__ == "__main__":
    main()
