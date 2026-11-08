#!/usr/bin/env python3
"""Write GearQuest/Locales/<locale>.quests.lua: official quest text for data text.

- lore (a quest's description) -> the client's description of that quest
- the "Objective: ..." tail of instructions -> the client's objective text

Quests are found by the entry's quest name (questName=, or 'Quoted' in the
instructions) through QuestieDB's Forever ids. Objectives come from QuestieDB's
Forever localisation block; descriptions from Questie's lookupQuests files
(Classic, then TBC). Text with no match stays English.

Sources (GPL-3.0 data):
- QuestieDB_Forever.toc from an installed QuestieDB (Forever build).
- Questie tag v11.20.0, Localization/lookups: later tags dropped these files.
  https://github.com/Questie/Questie/archive/refs/tags/v11.20.0.tar.gz

Usage: build-locale-quests.py <QuestieDB_Forever.toc> <Questie>/Localization/lookups [frFR]
"""

from __future__ import annotations

import base64
import difflib
import collections
import importlib.util
import re
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "GearQuest"

spec = importlib.util.spec_from_file_location("names", ROOT / "scripts" / "build-locale-names.py")
names = importlib.util.module_from_spec(spec)
spec.loader.exec_module(names)

# The client's own placeholders. Data.lua:SanitizeText fills the English ones.
PLACEHOLDERS = {
    "frFR": {"<nom>": "<name>", "<classe>": "<class>"},
    "deDE": {"<Name>": "<name>", "<Klasse>": "<class>"},
    "esES": {"<nombre>": "<name>", "<clase>": "<class>"},
    "esMX": {"<nombre>": "<name>", "<clase>": "<class>"},
    "ruRU": {"<имя>": "<name>", "<класс>": "<class>"},
}


def lua_elements(body: str) -> list:
    """Top-level elements of a Lua table body: strings, nil, and nested string lists."""
    out, i, n = [], 0, len(body)
    while i < n:
        c = body[i]
        if c == '"':
            j = i + 1
            while body[j] != '"':
                j += 2 if body[j] == "\\" else 1
            out.append(body[i + 1:j].replace('\\"', '"').replace("\\\\", "\\"))
            i = j + 1
        elif c == "{":
            depth, j = 1, i + 1
            while depth:
                if body[j] == '"':
                    j += 1
                    while body[j] != '"':
                        j += 2 if body[j] == "\\" else 1
                elif body[j] == "{":
                    depth += 1
                elif body[j] == "}":
                    depth -= 1
                j += 1
            out.append([e for e in lua_elements(body[i + 1:j - 1]) if isinstance(e, str)])
            i = j
        elif body.startswith("nil", i):
            out.append(None)
            i += 3
        else:
            i += 1
    return out


def questie_lookup(path: Path) -> dict[int, tuple[list[str], list[str]]]:
    """quest id -> (description paragraphs, objective lines) from a lookupQuests file."""
    out = {}
    for m in re.finditer(r"^\[(\d+)\] = \{(.*)\},?$", path.read_text(encoding="utf-8"), re.M):
        parts = lua_elements(m.group(2))
        desc = parts[1] if len(parts) > 1 and isinstance(parts[1], list) else []
        obj = parts[2] if len(parts) > 2 and isinstance(parts[2], list) else []
        out[int(m.group(1))] = (desc, obj)
    return out


def forever_quests(toc: str, locale: str):
    meta = names.read_toc(toc)

    def stored(key):
        value = meta.get("X-" + key)
        if value and value.startswith("~") and value.endswith("~"):
            value = "".join(meta[f"X-{key}-{n}"] for n in range(1, int(value[1:-1]) + 1))
        return value

    ids = names.cbor(zlib.decompress(base64.b64decode(stored("Quest-IDS"))))[0]
    block = names.cbor(zlib.decompress(base64.b64decode(stored(f"l10n-{locale}-Quest"))))[0]
    objectives = block[1] if isinstance(block, list) and len(block) > 1 else []
    by_name: dict[str, list[int]] = collections.defaultdict(list)
    objective_by_id = {}
    english_objective = {}
    for pos, qid in enumerate(ids):
        row = stored(f"Quest-{qid}-S")
        english = names.first_field(names.cbor(base64.b64decode(row))[0]) if row else None
        if english:
            by_name[english].append(qid)
        if pos < len(objectives) and objectives[pos]:
            objective_by_id[qid] = objectives[pos]
        field = stored(f"Quest-{qid}-8")  # objectivesText, English
        if field:
            value = names.cbor(base64.b64decode(field))[0]
            if isinstance(value, dict):
                value = [value[k] for k in sorted(value)]
            if isinstance(value, list):
                english_objective[qid] = " ".join(str(v) for v in value if v)
    return by_name, objective_by_id, english_objective


def entries():
    """Yield dicts of questName / lore / instructions per data row."""
    row = re.compile(r"\{[^{}]*?\b(?:instructions|lore)\s*=\s*\"[^{}]*\}")
    field = re.compile(r'\b(questName|lore|instructions)\s*=\s*"((?:[^"\\]|\\.)*)"')
    files = list(ADDON.glob("*.lua")) + list((ADDON / "_generated").glob("*.lua"))
    for path in files:
        if "Locales" in path.parts:
            continue
        for m in row.finditer(path.read_text(encoding="utf-8", errors="replace")):
            yield dict(field.findall(m.group(0)))


SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=\S)")


def same_length(translated: str, english: str) -> str:
    """The data keeps the first sentences of a description. Keep as many."""
    count = len(SENTENCE_END.split(english.strip()))
    parts = SENTENCE_END.split(translated.strip())
    return " ".join(parts[:count]) if count < len(parts) else translated


def lua_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def unlua(text: str) -> str:
    return text.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def main() -> None:
    toc, lookups = sys.argv[1], Path(sys.argv[2])
    locale = sys.argv[3] if len(sys.argv) > 3 else "frFR"
    by_name, objective_by_id, english_objective = forever_quests(toc, locale)

    def pick(qids, tail):
        """The quest among same-named ones whose English objective matches the tail."""
        if not qids:
            return []
        if len(qids) == 1 or not tail:
            return qids if len(qids) == 1 else []
        scored = sorted(
            qids,
            key=lambda q: difflib.SequenceMatcher(None, english_objective.get(q, ""), tail).ratio(),
            reverse=True,
        )
        best = difflib.SequenceMatcher(None, english_objective.get(scored[0], ""), tail).ratio()
        return scored[:1] if best >= 0.6 else []
    described = {}
    for flavor in ("TBC", "Classic"):  # Classic wins where both have the quest.
        path = lookups / flavor / "lookupQuests" / f"{locale}.lua"
        if path.exists():
            described.update(questie_lookup(path))

    def localize(text: str) -> str:
        for theirs, ours in PLACEHOLDERS.get(locale, {}).items():
            text = text.replace(theirs, ours)
        return text.replace("\u2019", "'")

    lore, objective = {}, {}
    stats = collections.Counter()
    for row in entries():
        quest = row.get("questName")
        how = row.get("instructions", "")
        if not quest:
            m = re.search(r"the quest '(.+?)'\.", unlua(how))
            quest = m and m.group(1)
        qids = by_name.get(unlua(quest)) if quest else None
        tail = unlua(how).split("Objective: ", 1)[1] if "Objective: " in how else None
        if qids and len(qids) > 1:
            same = {tuple(described.get(q, ([], []))[0]) for q in qids}
            qids = pick(qids, tail) if (tail or len(same) > 1) else qids[:1]
        if row.get("lore"):
            stats["lore"] += 1
            for qid in qids or []:
                desc = described.get(qid, ([], []))[0]
                if desc:
                    english = unlua(row["lore"])
                    lore[english] = localize(same_length(" ".join(desc), english))
                    stats["lore matched"] += 1
                    break
        if "Objective: " in how:
            stats["objective"] += 1
            for qid in qids or []:
                lines = objective_by_id.get(qid) or described.get(qid, ([], []))[1]
                if lines:
                    objective[tail] = localize(" ".join(lines))
                    stats["objective matched"] += 1
                    break

    lines = [
        "local _, GQ = ...",
        "",
        "-- GENERATED by scripts/build-locale-quests.py. Do not edit by hand.",
        "-- The client's own quest descriptions and objectives (Questie / QuestieDB data).",
        f'if GQ.LOCALE ~= "{locale}" then',
        "    return",
        "end",
        "",
        "local text = GQ.LocaleText",
        "for k, v in pairs({",
    ]
    lines += [f"    [{lua_string(en)}] = {lua_string(fr)}," for en, fr in sorted(lore.items())]
    lines += ["}) do text[k] = v end", "", "local objectives = GQ.LocaleObjectives", "for k, v in pairs({"]
    lines += [f"    [{lua_string(en)}] = {lua_string(fr)}," for en, fr in sorted(objective.items())]
    lines.append("}) do objectives[k] = v end")
    target = ADDON / "Locales" / f"{locale}.quests.lua"
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(target, dict(stats), "unique lore", len(lore), "unique objectives", len(objective))


if __name__ == "__main__":
    main()
