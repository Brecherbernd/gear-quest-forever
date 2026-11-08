#!/usr/bin/env python3
"""Install per-class GearQuest Forever hunt addons next to the main addon.

The repo keeps every class file under GearQuest/_generated. At login only the
player's class should be parsed. This copies each class into
GearQuestForever_<CLASS> and moves that class's Wowhead tooltip text out of
the main foreverAudit into AuditTips.lua, which loads with the class.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "GearQuest" / "_generated"
AUDIT_NAME = "Data.ForeverAudit.generated.lua"

CLASSES = {
    "PALADIN": (
        "Paladin",
        ["Data.Paladin.generated.lua", "Data.Paladin.Early.1to9.generated.lua"],
    ),
    "WARRIOR": (
        "Warrior",
        ["Data.Warrior.generated.lua", "Data.Warrior.Early.1to9.generated.lua"],
    ),
    "HUNTER": (
        "Hunter",
        ["Data.Hunter.generated.lua", "Data.Hunter.Early.1to9.generated.lua"],
    ),
    "DRUID": (
        "Druid",
        ["Data.Druid.generated.lua", "Data.Druid.Early.1to9.generated.lua"],
    ),
    "SHAMAN": (
        "Shaman",
        ["Data.Shaman.generated.lua", "Data.Shaman.Early.1to9.generated.lua"],
    ),
    "ROGUE": (
        "Rogue",
        ["Data.Rogue.generated.lua", "Data.Rogue.Early.1to9.generated.lua"],
    ),
    "PRIEST": (
        "Priest",
        ["Data.Priest.generated.lua", "Data.Priest.Early.1to9.generated.lua"],
    ),
    "WARLOCK": (
        "Warlock",
        ["Data.Warlock.generated.lua", "Data.Warlock.Early.1to9.generated.lua"],
    ),
    "MAGE": (
        "Mage",
        ["Data.Mage.generated.lua", "Data.Mage.Early.1to9.generated.lua"],
    ),
}

HEADER_OLD = "local _, GQ = ...\n"
HEADER_NEW = (
    "local GQ = _G.GearQuest\n"
    "if not GQ then\n"
    '    error("GearQuest Forever class data loaded without the main addon")\n'
    "end\n"
)

FACT_ID = re.compile(r"^\s*\[(\d+)\]=\{")
ROW_ID = re.compile(r"^\s*\{(\d+),")


def lua_str(text: str) -> str:
    out = (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", " ")
        .replace("\n", "\\n")
    )
    return '"' + out + '"'


def read_lua_string(src: str, quote_at: int) -> tuple[str, int]:
    if src[quote_at] != '"':
        raise ValueError("expected quote")
    i = quote_at + 1
    chars: list[str] = []
    while i < len(src):
        c = src[i]
        if c == "\\":
            nxt = src[i + 1]
            chars.append({"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}.get(nxt, nxt))
            i += 2
            continue
        if c == '"':
            return "".join(chars), i + 1
        chars.append(c)
        i += 1
    raise ValueError("unterminated lua string")


def strip_tip(line: str) -> tuple[str, str | None]:
    i = 0
    n = len(line)
    in_str = False
    esc = False
    while i < n:
        c = line[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            i += 1
            continue
        if line.startswith("tip=", i) and i + 4 < n and line[i + 4] == '"':
            tip, end = read_lua_string(line, i + 4)
            start = i - 1 if i > 0 and line[i - 1] == "," else i
            return line[:start] + line[end:], tip
        i += 1
    return line, None


def item_ids(path: Path) -> set[int]:
    ids: set[int] = set()
    # Class files are not all valid UTF-8. Ids are ASCII either way.
    with path.open(encoding="latin-1") as handle:
        for line in handle:
            fact = FACT_ID.match(line)
            if fact:
                ids.add(int(fact.group(1)))
                continue
            row = ROW_ID.match(line)
            if row:
                ids.add(int(row.group(1)))
    return ids


def copy_class_lua(src: Path, dest: Path) -> None:
    raw = src.read_bytes()
    old_crlf = (HEADER_OLD.replace("\n", "\r\n")).encode("ascii")
    old_lf = HEADER_OLD.encode("ascii")
    if raw.startswith(old_crlf):
        raw = HEADER_NEW.replace("\n", "\r\n").encode("ascii") + raw[len(old_crlf) :]
    elif raw.startswith(old_lf):
        raw = HEADER_NEW.encode("ascii") + raw[len(old_lf) :]
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(raw)


def addon_version() -> str:
    toc = Path(__file__).resolve().parents[1] / "GearQuest" / "GearQuestForever.toc"
    for line in toc.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("GearQuestForever.toc has no ## Version")


def write_toc(folder: Path, title: str, files: list[str]) -> None:
    lines = [
        "## Interface: 16001",
        f"## Title: GearQuest Forever: {title}",
        "## Notes: Hunt lists for this class. GearQuest Forever loads this when you play or simulate it.",
        "## Notes-deDE: Hunt-Listen für diese Klasse. GearQuest Forever lädt sie, wenn du die Klasse spielst oder simulierst.",
        "## Author: Henrik8210",
        f"## Version: {addon_version()}",
        f"## IconTexture: Interface\\Icons\\ClassIcon_{title}",
        "## LoadOnDemand: 1",
        "## Dependencies: GearQuestForever",
        "## RequiredDeps: GearQuestForever",
        "",
        *files,
        "AuditTips.lua",
        "",
    ]
    (folder / f"{folder.name}.toc").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def write_audit_tips(path: Path, tips: dict[int, str]) -> None:
    rows = ["local GQ = _G.GearQuest", "local audit = GQ and GQ.Data and GQ.Data.foreverAudit", "if not audit then return end", "local tips = {"]
    for item_id in sorted(tips):
        rows.append(f"    [{item_id}]={lua_str(tips[item_id])},")
    rows.append("}")
    rows.append("for id, tip in pairs(tips) do")
    rows.append("    local row = audit[id]")
    rows.append("    if row then row.tip = tip end")
    rows.append("end")
    rows.append("")
    path.write_text("\n".join(rows), encoding="utf-8", newline="\n")


def class_tips(audit_path: Path, class_ids: dict[str, set[int]]) -> tuple[list[str], dict[str, dict[int, str]]]:
    owned: dict[int, list[str]] = {}
    for class_file, ids in class_ids.items():
        for item_id in ids:
            owned.setdefault(item_id, []).append(class_file)

    tips_by_class = {class_file: {} for class_file in class_ids}
    stripped_lines: list[str] = []
    id_re = re.compile(r"^\s*\[(\d+)\]=")
    with audit_path.open(encoding="utf-8") as handle:
        for line in handle:
            match = id_re.match(line)
            if not match:
                stripped_lines.append(line)
                continue
            item_id = int(match.group(1))
            classes = owned.get(item_id)
            if not classes:
                stripped_lines.append(line)
                continue
            new_line, tip = strip_tip(line)
            stripped_lines.append(new_line)
            if tip:
                for class_file in classes:
                    tips_by_class[class_file][item_id] = tip
    return stripped_lines, tips_by_class


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dest", required=True, help="AddOns directory or .release directory")
    parser.add_argument("--main", required=True, help="Staged GearQuestForever addon folder to strip")
    args = parser.parse_args()

    dest = Path(args.dest)
    main_addon = Path(args.main)
    audit_src = GENERATED / AUDIT_NAME
    if not audit_src.is_file():
        raise SystemExit(f"missing {audit_src}")

    class_ids = {}
    for class_file, (_title, files) in CLASSES.items():
        ids: set[int] = set()
        for name in files:
            ids |= item_ids(GENERATED / name)
        class_ids[class_file] = ids

    stripped, tips_by_class = class_tips(audit_src, class_ids)
    audit_dest = main_addon / "_generated" / AUDIT_NAME
    audit_dest.parent.mkdir(parents=True, exist_ok=True)
    audit_dest.write_text("".join(stripped), encoding="utf-8", newline="\n")

    for class_file, (title, files) in CLASSES.items():
        folder = dest / f"GearQuestForever_{class_file}"
        folder.mkdir(parents=True, exist_ok=True)
        for name in files:
            copy_class_lua(GENERATED / name, folder / name)
            staged_main = main_addon / "_generated" / name
            if staged_main.is_file():
                staged_main.unlink()
        write_audit_tips(folder / "AuditTips.lua", tips_by_class[class_file])
        write_toc(folder, title, files)
        print(f"{folder.name}: {len(tips_by_class[class_file])} tooltip texts")

    print(f"stripped audit -> {audit_dest}")


if __name__ == "__main__":
    main()
