"""Describe every gathered sheet and every cut sprite with a vision model, and record it.

Two prompts. A **cut sprite** is one object on a frame of backdrop, so it is asked for a
subject, a kind and a distinguishing detail -- that is the evidence the name is checked
against. A **raw sheet** may hold one object or a grid of them, so it is asked for the objects
it can actually SEE in reading order; one call then covers every panel the cutter lifted off
that sheet, which is what the placeholder-named sheets need (43 sheets carry no name list in
any manifest, and the render is the only place their contents exist).

Model: `deepseek-chat` on the direct DeepSeek key. Probed against every alternative on
2026-09-20, same 512 px sprite, comparing the prompt-token count with and without the
attachment (`delta` is proof the image was read; `out` is the completion tokens):

| model | route | delta | out | verdict |
|---|---|---|---|---|
| `deepseek-chat` | api.deepseek.com | +206 | 5 | sees it, answers in a few tokens |
| `deepseek-v4-flash` | api.deepseek.com | +206 | 300, empty | sees it, reasons, truncates at a normal budget |
| `deepseek-flash` | api.deepseek.com | +206 | needs 12288 | sees it, reasons at length |
| `deepseek-reasoner` | api.deepseek.com | +206 | 300, empty | same as v4-flash |
| `deepseek-v4-pro` | api.deepseek.com | **+5** | 224 | "Cannot identify without the image" - drops it |
| `deepseek-v4.1-flash` | api.deepseek.com | - | - | rejected: only `deepseek-flash` and `deepseek-v4-pro` are supported names |
| `deepseek-v4-flash-vision-exp` | opencode-go | +206 | 485-4096, empty 2/8 | sees it, reasons, stalls |
| `deepseek-v4-flash` | opencode-go | - | - | HTTP 400: "Model only supports text input" |

The
`deepseek-flash` / `deepseek-v4-flash` family is the fallback for anything `deepseek-chat`
fails on or disagrees with - re-ask those with `--model deepseek-flash --tokens 8192`.

Answers are written to asset-library/_vision.json after every file, so a kill keeps every
reply that was paid for. Answered files are skipped on the next run.

Usage:
    py -3.14 staging/cut/tag_vision.py --dry-run             # prompts, no calls
    py -3.14 staging/cut/tag_vision.py --only cut --limit 8  # a taste
    py -3.14 staging/cut/tag_vision.py --only raw            # the 170 sheets
    py -3.14 staging/cut/tag_vision.py --report              # what is already answered
    py -3.14 staging/cut/tag_vision.py --redo <name> --model deepseek-flash --tokens 8192
    py -3.14 -u staging/cut/tag_vision.py > staging/cut/_vision_pass.log 2>&1
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import re
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
RAW = LIBRARY / "raw"
CUT = LIBRARY / "cut"
SHEETS = LIBRARY / "_sheets.json"
ANSWER = LIBRARY / "_vision.json"
CRUSH = Path("C:/Users/Kamil/AppData/Local/crush/crush.json")
MODEL = "deepseek-chat"
ENDPOINT = "https://api.deepseek.com/chat/completions"

SIDE_CUT = 768         # px a cut sprite is scaled to before sending
SIDE_RAW = 1024        # a sheet holds many panels, so it gets more pixels
QUALITY = 85
TOKENS = 900           # deepseek-chat answers in ~50; the headroom is for a 20-cell list
WORKERS = 8
TRIES = 3

KINDS = ("ship, station, asteroid, planet, moon, debris, gate, fx, icon, ui_frame, ui_button, "
         "ui_slot, bar, backdrop, tile, logo, portrait, prop, structure, pickup, other")

CUT_INSTRUCTIONS = """One asset from a space-combat game, sent scaled to {side} px. The \
background is the render backdrop, not part of the asset.

Put the JSON on the very first line, then at most 10 words of note. Nothing else, no prose, \
no code fence:

{{"subject": "<2 to 4 lowercase words, the thing depicted>", "kind": "<one of: {kinds}>", \
"detail": "<3 to 6 lowercase words, its distinguishing feature>", "panels": <int, how many \
separate objects you can see, 1 if just one>, "flat_bg": <true if the backdrop behind the \
object is one flat colour, else false>}}

The requested name of this asset was "{name}"."""

RAW_INSTRUCTIONS = """One game texture sheet from a space-combat game, sent scaled to {side} \
px. It may hold a single object filling the frame, or a grid of separate objects on a plain \
backdrop. The project expected {expected}.

List every separate object you can actually SEE, reading left to right then top to bottom. \
Do not invent objects and do not repeat one. Put the JSON on the very first line, then at \
most 15 words of note. Nothing else, no prose, no code fence:

{{"sheet_subject": "<3 to 6 lowercase words, what the sheet as a whole shows>", \
"kind": "<one of: {kinds}>", "columns": <int columns of objects you see>, "rows": <int rows \
you see>, "objects": ["<2 to 4 lowercase words each, in reading order, one entry per object \
you can see>"], "flat_bg": <true if the backdrop behind the objects is one flat colour, else \
false>}}

The requested name of this sheet was "{name}"."""


def api_key() -> str:
    cfg = json.loads(CRUSH.read_text(encoding="utf-8"))
    return cfg["providers"]["deepseek"]["api_key"]


def encode(path: Path, side: int) -> tuple[str, list[int]]:
    image = Image.open(path).convert("RGB")
    image.thumbnail((side, side))
    size = list(image.size)
    buf = io.BytesIO()
    image.save(buf, "JPEG", quality=QUALITY)
    return base64.b64encode(buf.getvalue()).decode(), size


def ask(key: str, prompt: str, b64: str, model: str = MODEL, tokens: int = TOKENS,
        tries: int = TRIES) -> dict:
    body = {"model": model, "messages": [{"role": "user", "content": [
        {"type": "text", "text": prompt},
        {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}},
    ]}], "max_tokens": tokens}
    last = {}
    for attempt in range(tries):
        req = urllib.request.Request(
            ENDPOINT, data=json.dumps(body).encode(),
            headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=240) as response:
                out = json.loads(response.read())
            message = out["choices"][0]["message"]
            text = (message.get("content") or "").strip()
            parsed = first_json(text)
            if parsed is not None:
                parsed["_usage"] = out.get("usage", {})
                parsed["_raw"] = text[:400]
                return parsed
            last = {"_error": f"no JSON: {text[:120]!r}",
                    "_usage": out.get("usage", {}),
                    "_finish": out["choices"][0].get("finish_reason")}
        except urllib.error.HTTPError as exc:
            last = {"_error": f"HTTP {exc.code}: {exc.read()[:140]!r}"}
        except Exception as exc:  # noqa: BLE001 - network shape varies
            last = {"_error": f"{type(exc).__name__}: {exc}"}
        time.sleep(2 * (attempt + 1))
    return last


def first_json(text: str) -> dict | None:
    """The first JSON object in the reply, tolerating a code fence or trailing prose."""
    text = re.sub(r"^\s*```(?:json)?\s*", "", text)
    depth = 0
    start = None
    in_str = False
    escape = False
    for i, ch in enumerate(text):
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                try:
                    return json.loads(text[start:i + 1])
                except json.JSONDecodeError:
                    start = None
    return None


def planned_grid() -> dict[str, list[int]]:
    """The arrangement the cut stage settled on, per raw path, as a hint for the sheet prompt."""
    if not SHEETS.exists():
        return {}
    sheets = json.loads(SHEETS.read_text(encoding="utf-8"))["sheets"]
    return {e["raw"]: e["grid"] for e in sheets}


def work() -> list[tuple[str, Path, str]]:
    """Every file to describe: (key, path, prompt)."""
    grids = planned_grid()
    out: list[tuple[str, Path, str]] = []
    for path in sorted(CUT.glob("*.png")):
        out.append((f"cut/{path.name}", path,
                    CUT_INSTRUCTIONS.format(side=SIDE_CUT, kinds=KINDS, name=path.stem)))
    for path in sorted(RAW.glob("*.png")):
        key = f"raw/{path.name}"
        grid = grids.get(key)
        expected = (f"a grid of {grid[0]} columns by {grid[1]} rows" if grid and grid != [1, 1]
                    else "a single object filling the frame")
        out.append((key, path, RAW_INSTRUCTIONS.format(side=SIDE_RAW, kinds=KINDS,
                                                      name=path.stem, expected=expected)))
    return out


def report(state: dict) -> None:
    files = state.get("files", {})
    for group, side in (("cut", SIDE_CUT), ("raw", SIDE_RAW)):
        keys = [k for k in files if k.startswith(group + "/")]
        bad = [k for k in keys if "_error" in files[k]]
        print(f"{group}: {len(keys)} answered, {len(bad)} failed")
        for k in sorted(bad)[:10]:
            print("   FAIL", k, files[k]["_error"][:90])
    total = state.get("usage", {})
    print("usage:", {k: total.get(k) for k in ("prompt_tokens", "completion_tokens", "calls")})
    print(f"total files answered: {len(files)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", choices=("cut", "raw"), default=None)
    parser.add_argument("--limit", type=int, default=0, help="stop after N files")
    parser.add_argument("--redo", default="", help="re-ask files whose key contains this")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--workers", type=int, default=WORKERS)
    parser.add_argument("--model", default=MODEL,
                        help="deepseek-chat answers in ~50 tokens; deepseek-flash and "
                             "deepseek-v4-flash also see the image but reason first and need "
                             "--tokens 8192 or they return empty")
    parser.add_argument("--tokens", type=int, default=TOKENS)
    args = parser.parse_args()

    items = work()
    if args.only:
        items = [i for i in items if i[0].startswith(args.only + "/")]
    state: dict = {"model": args.model, "endpoint": ENDPOINT, "files": {}, "usage": {}}
    if ANSWER.exists():
        state = json.loads(ANSWER.read_text(encoding="utf-8"))
        state.setdefault("files", {})
        state.setdefault("usage", {})
        state.setdefault("model", args.model)

    if args.report:
        report(state)
        return

    todo = [i for i in items if args.redo and args.redo in i[0]
            or (not args.redo and i[0] not in state["files"])]
    if args.redo:
        todo = [i for i in items if args.redo in i[0]]
    if args.limit:
        todo = todo[:args.limit]

    if args.dry_run:
        for key, path, prompt in todo[:3]:
            print(f"--- {key}\n{prompt}\n")
        print(f"{len(todo)} file(s) would be described")
        return

    if not todo:
        print("nothing to do; every selected file is already answered")
        report(state)
        return

    key = api_key()
    lock = threading.Lock()
    done = 0
    started = time.time()

    def one(item: tuple[str, Path, str]) -> None:
        nonlocal done
        name, path, prompt = item
        side = SIDE_CUT if name.startswith("cut/") else SIDE_RAW
        b64, size = encode(path, side)
        answer = ask(key, prompt, b64, model=args.model, tokens=args.tokens)
        answer["_image"] = size
        answer["_model"] = args.model
        with lock:
            state["files"][name] = answer
            usage = state["usage"]
            got = answer.pop("_usage", {}) or {}
            usage["prompt_tokens"] = usage.get("prompt_tokens", 0) + got.get("prompt_tokens", 0)
            usage["completion_tokens"] = usage.get("completion_tokens", 0) + got.get("completion_tokens", 0)
            usage["calls"] = usage.get("calls", 0) + 1
            done += 1
            state["generated"] = datetime.now().isoformat(timespec="seconds")
            tmp = ANSWER.with_suffix(".json.tmp")
            tmp.write_text(json.dumps(state, indent=1, ensure_ascii=False), encoding="utf-8")
            tmp.replace(ANSWER)
            if done % 10 == 0 or done == len(todo):
                rate = done / max(time.time() - started, 0.1)
                print(f"[{done}/{len(todo)}] {rate:.1f}/s  {name}  "
                      f"{json.dumps({k: v for k, v in answer.items() if not k.startswith('_')}, ensure_ascii=False)[:150]}",
                      flush=True)

    print(f"describing {len(todo)} file(s) with {args.model}, {args.workers} at a time", flush=True)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        list(pool.map(one, todo))

    print()
    report(state)


if __name__ == "__main__":
    main()
