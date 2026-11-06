"""Vendor prices and quest-chain lengths for hunt descriptions.

Forever item XML supplies buyprice in copper. A quest page series table
supplies the reward quest's step. The addon prints coins, honor, and
badges with the in-game icons.

  python pipeline/scripts/fetch_hunt_descriptions.py
"""
from __future__ import annotations

import gzip
import json
import os
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "pipeline" / "data"
CACHE_PATH = DATA / "forever_wowhead" / "hunt_desc_cache.json"
LUA_PATH = ROOT / "GearQuest" / "_generated" / "Data.HuntFacts.generated.lua"
UA = "GearQuestForever-data/1.0"
DELAY = float(os.environ.get("GQ_TIP_DELAY", "0.8"))
BUY_RE = re.compile(r'"buyprice":(\d+)')
QUEST_RE = re.compile(r'"t":5,"ti":(\d+)')
SERIES_RE = re.compile(r'<table class="series">(.*?)</table>', re.S)
STEP_RE = re.compile(r"<th>(\d+)\.</th>\s*<td>(.*?)</td>", re.S)
LINK_RE = re.compile(r"quest=(\d+)")


def fetch(url: str) -> str:
    pauses = (20, 60, 120)
    for attempt in range(len(pauses) + 1):
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Encoding": "gzip"})
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                raw = resp.read()
                if resp.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
                time.sleep(DELAY)
                return raw.decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code in (403, 429) and attempt < len(pauses):
                pause = pauses[attempt]
                print(f"  HTTP {e.code} waiting {pause}s", flush=True)
                time.sleep(pause)
                continue
            if e.code == 404:
                time.sleep(DELAY)
                return ""
            raise
    return ""


def load_cache() -> dict:
    if CACHE_PATH.exists():
        stored = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
        if isinstance(stored, dict):
            stored.setdefault("item", {})
            stored.setdefault("quest", {})
            return stored
    return {"item": {}, "quest": {}}


def save_cache(cache: dict) -> None:
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE_PATH.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cache, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    tmp.replace(CACHE_PATH)


def series_steps(html: str, quest_id: int) -> int:
    match = SERIES_RE.search(html or "")
    if not match:
        return 1
    steps = []
    for num, cell in STEP_RE.findall(match.group(1)):
        link = LINK_RE.search(cell)
        steps.append((int(num), int(link.group(1)) if link else quest_id))
    if len(steps) < 2:
        return 1
    for num, qid in steps:
        if qid == quest_id:
            return num
    return steps[-1][0]


def item_fact(item_id: int, cache: dict) -> dict:
    key = str(item_id)
    row = cache["item"].get(key)
    if isinstance(row, dict) and "copper" in row and "quests" in row:
        return row
    body = fetch(f"https://www.wowhead.com/forever/item={item_id}&xml")
    copper = 0
    quests = []
    if body:
        buy = BUY_RE.search(body)
        if buy:
            copper = int(buy.group(1))
        quests = [int(n) for n in QUEST_RE.findall(body)]
    row = {"copper": copper, "quests": quests}
    cache["item"][key] = row
    return row


def quest_steps(quest_id: int, cache: dict) -> int:
    key = str(quest_id)
    if key in cache["quest"]:
        return int(cache["quest"][key])
    body = fetch(f"https://www.wowhead.com/forever/quest={quest_id}?power")
    steps = series_steps(body, quest_id) if body else 1
    cache["quest"][key] = steps
    return steps


def lua_number_rows(mapping: dict, key_name: str) -> list[str]:
    lines = []
    for item_id in sorted(mapping):
        lines.append(f"GQ.Data.{key_name}[{item_id}] = {mapping[item_id]}")
    return lines


CHAIN_LINE = re.compile(r"^GQ\.Data\.questChain\[(\d+)\] = (\{.*\})$")
VENDOR_LINE = re.compile(r"^GQ\.Data\.vendorCost\[(\d+)\] = (\{.*\})$")
SELLERS_CLAUSE = re.compile(r"sellers = \{.*\}")


def preserved_rows(path: Path) -> tuple[dict[int, str], dict[int, str]]:
    """Named quest steps and per-seller prices live in the emitted file.

    A later price fetch must not turn a named chain back into a step count,
    or drop a sellers table when the item XML only has one copper price.
    """
    chains: dict[int, str] = {}
    sellers: dict[int, str] = {}
    if not path.exists():
        return chains, sellers
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        chain = CHAIN_LINE.match(stripped)
        if chain and '"' in chain.group(2):
            chains[int(chain.group(1))] = chain.group(2)
        vendor = VENDOR_LINE.match(stripped)
        if vendor and "sellers" in vendor.group(2):
            sellers[int(vendor.group(1))] = vendor.group(2)
    return chains, sellers


def emit(vendor: dict, chains: dict) -> None:
    kept_chains, kept_sellers = preserved_rows(LUA_PATH)
    lines = [
        "-- AUTO-GENERATED by pipeline/scripts/fetch_hunt_descriptions.py — do not edit.",
        "-- Vendor prices and quest chains for hunt descriptions.",
        "",
        "local _, GQ = ...",
        "GQ.Data = GQ.Data or {}",
        "",
        "GQ.Data.vendorCost = {}",
    ]
    vendor_ids = set(vendor) | set(kept_sellers)
    for item_id in sorted(vendor_ids):
        row = vendor.get(item_id) or {}
        kept = kept_sellers.get(item_id)
        if kept and not row:
            lines.append(f"GQ.Data.vendorCost[{int(item_id)}] = {kept}")
            continue
        parts = []
        if row.get("copper"):
            parts.append(f"copper = {int(row['copper'])}")
        if row.get("honor"):
            parts.append(f"honor = {int(row['honor'])}")
        tokens = row.get("tokens") or []
        if tokens:
            shown = ", ".join(
                "{" + f"{int(count)}, {json.dumps(icon)}" + "}"
                for count, icon in tokens
            )
            parts.append(f"tokens = {{ {shown} }}")
        if kept:
            clause = SELLERS_CLAUSE.search(kept)
            if clause and not any(part.startswith("sellers") for part in parts):
                parts.append(clause.group(0))
        if not parts:
            continue
        lines.append(f"GQ.Data.vendorCost[{int(item_id)}] = {{ {', '.join(parts)} }}")
    lines.append("")
    lines.append("GQ.Data.questChain = {}")
    merged: dict[int, str] = dict(kept_chains)
    for item_id, steps in chains.items():
        if int(item_id) in merged:
            continue
        merged[int(item_id)] = str(int(steps))
    for item_id in sorted(merged):
        rhs = merged[item_id]
        if rhs.startswith("{"):
            lines.append(f"GQ.Data.questChain[{int(item_id)}] = {rhs}")
        else:
            lines.append(f"GQ.Data.questChain[{int(item_id)}] = {rhs}")
    lines.append("")
    text = "\n".join(lines)
    tmp = LUA_PATH.with_suffix(".lua.tmp")
    tmp.write_bytes(text.encode("utf-8"))
    tmp.replace(LUA_PATH)


def main() -> None:
    hunts = json.loads((DATA / "forever_wowhead" / "hunt_ids.json").read_text(encoding="utf-8"))
    sources = json.loads((DATA / "sources.json").read_text(encoding="utf-8"))
    coord = json.loads((DATA / "forever_wowhead" / "coord_cache.json").read_text(encoding="utf-8"))
    item_quest = coord.get("itemQuest") or {}
    cache = load_cache()

    vendors = []
    quests = []
    for item_id in hunts["ids"]:
        src = sources.get(str(item_id)) or {}
        kind = src.get("sourceType") or ""
        if kind == "vendor":
            vendors.append(int(item_id))
        elif kind in ("quest_reward", "seasonal_quest"):
            quests.append(int(item_id))

    print(f"vendors {len(vendors)} quests {len(quests)}", flush=True)
    for n, item_id in enumerate(vendors, 1):
        item_fact(item_id, cache)
        if n % 25 == 0:
            save_cache(cache)
            print(f"  vendor xml {n}/{len(vendors)}", flush=True)
    save_cache(cache)

    vendor_out = {}
    for item_id in vendors:
        row = cache["item"].get(str(item_id)) or {}
        copper = int(row.get("copper") or 0)
        if copper > 0:
            vendor_out[item_id] = {"copper": copper}
    emit(vendor_out, {})

    chain_out = {}
    for n, item_id in enumerate(quests, 1):
        linked = item_quest.get(str(item_id)) or []
        if not linked:
            linked = (cache["item"].get(str(item_id)) or {}).get("quests") or []
            if not linked:
                linked = item_fact(item_id, cache).get("quests") or []
        if not linked:
            continue
        best = 1
        for quest_id in linked:
            best = max(best, quest_steps(int(quest_id), cache))
        # 1 means the reward quest is the whole series. The log says there
        # are no prequests. A later step stays the chain length.
        chain_out[item_id] = best
        if n % 25 == 0:
            save_cache(cache)
            emit(vendor_out, chain_out)
            print(f"  quest series {n}/{len(quests)} chains {len(chain_out)}", flush=True)
    save_cache(cache)
    emit(vendor_out, chain_out)
    print(f"wrote {LUA_PATH.name} costs {len(vendor_out)} chains {len(chain_out)}", flush=True)


if __name__ == "__main__":
    main()
