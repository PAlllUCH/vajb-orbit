"""Ask DeepSeek to read each sheet's layout from the render, and record the answer.

The prompts are ambiguous about a sheet's arrangement: one says "2x3 grid (three columns, two
rows)" and the next says "2x3 grid (two columns, three rows)", and a few renders simply
ignore what was asked. The cell *count* is known -- it is how many panels the plan names --
but which way round those cells lie decides what each icon is called. This pass shows the
render to a vision model and asks it for the arrangement and the cut lines, then writes the
answer into asset-library/_layout_deepseek.json, which `cut_sheets.py` reads in preference to
the plan's arrangement. Keeping it in its own file means the plan can be rebuilt from the
manifests at any time without throwing the models' answers away.

Only the arrangement is taken from the model. It is accepted when it holds the same number of
cells as the plan, so no panel can lose its name; anything else, or an unparseable answer, is
reported and the plan is left alone.

Model: deepseek-flash is the one on this key that actually reads images -- deepseek-v4-pro
returns the same prompt-token count with and without an attachment, i.e. it drops them.

Usage:
    py -3.14 staging/cut/deepseek_layout.py --dry-run               # prompts, no calls
    py -3.14 staging/cut/deepseek_layout.py --only contracts        # one sheet, one call
    py -3.14 staging/cut/deepseek_layout.py                         # every multi-panel sheet
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import re
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
PLAN = LIBRARY / "_sheets.json"
ANSWER = LIBRARY / "_layout_deepseek.json"
CRUSH = Path("C:/Users/Kamil/AppData/Local/crush/crush.json")
MODEL = "deepseek-flash"
ENDPOINT = "https://api.deepseek.com/chat/completions"
MAX_SIDE = 1024        # px the sheet is scaled to before sending
QUALITY = 88           # JPEG quality of that copy
TOKENS = 12288         # deepseek-flash reasons at length before it answers

INSTRUCTIONS = """Layout of one game texture sheet, sent scaled to {side} px. The artwork \
sits in a grid of separate pieces on a plain background, one asset per cell, sometimes one \
single object filling the whole frame.

Count the columns and rows of artwork you can actually SEE. Do not trust what was requested: \
the prompt is often ambiguous about which number is columns, and renders do sometimes ignore \
it. It was requested as {cols} columns by {rows} rows, which is {cells} cells, and the project \
names {named} of them.

Put the JSON on the very first line, then at most 12 words of note. Nothing else, no prose, no \
code fence:

{{"columns": <int the columns you see>, "rows": <int the rows you see>, "cut_x": [<one \
fraction of the width per internal vertical gap, increasing, each passing through empty \
background without touching artwork>], "cut_y": [<same for the horizontal gaps>], \
"confidence": "high" or "low", "note": "<12 words at most>"}}

A single object filling the frame is columns 1, rows 1, empty cut lists."""


def api_key() -> str:
    cfg = json.loads(CRUSH.read_text(encoding="utf-8"))
    return cfg["providers"]["deepseek"]["api_key"]


def payload(path: Path) -> tuple[str, tuple[int, int]]:
    """The sheet, scaled down and encoded, plus the size it was scaled to."""
    image = Image.open(path).convert("RGB")
    scale = min(1.0, MAX_SIDE / max(image.size))
    if scale < 1.0:
        image = image.resize((max(1, round(image.width * scale)),
                              max(1, round(image.height * scale))), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, "JPEG", quality=QUALITY)
    return "data:image/jpeg;base64," + base64.b64encode(buffer.getvalue()).decode(), image.size


def question(sheet: dict) -> str:
    columns, rows = sheet.get("planned_grid") or sheet["grid"]
    return INSTRUCTIONS.format(side=MAX_SIDE, cols=columns, rows=rows,
                               cells=columns * rows, named=len(sheet["cuts"]))


def call(key: str, prompt: str, image: str) -> dict:
    body = {
        "model": MODEL,
        "max_tokens": TOKENS,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image}},
        ]}],
    }
    request = urllib.request.Request(
        ENDPOINT, data=json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=300) as response:
        return json.loads(response.read().decode())


def parse(reply: str):
    """The first JSON object in the model's answer, if it produced one.

    The model reasons at length before answering, so the answer can still be cut off; asking
    for the JSON on the first line means a truncated reply usually still carries it.
    """
    text = reply or ""
    for match in re.finditer(r"\{(?:[^{}]|\{[^{}]*\})*\}", text, re.S):
        try:
            answer = json.loads(match.group(0))
        except ValueError:
            continue
        if isinstance(answer, dict) and "columns" in answer:
            return answer
    return None


def usable(answer: dict, sheet: dict) -> tuple[bool, str]:
    """Whether the model's arrangement can be adopted."""
    columns, rows = answer.get("columns"), answer.get("rows")
    if not isinstance(columns, int) or not isinstance(rows, int):
        return False, "no integer columns/rows"
    planned = tuple(sheet.get("planned_grid") or sheet["grid"])
    if columns * rows != planned[0] * planned[1]:
        return False, (f"it says {columns}x{rows} = {columns * rows} cells but the plan names "
                       f"{planned[0] * planned[1]}")
    if columns < 1 or rows < 1 or max(columns, rows) > 12:
        return False, f"implausible size {columns}x{rows}"
    for key, count in (("cut_x", columns - 1), ("cut_y", rows - 1)):
        cuts = answer.get(key) or []
        if not isinstance(cuts, list) or len(cuts) != count:
            return False, f"{key} holds {len(cuts)} values, expected {count}"
        if any(not isinstance(value, (int, float)) or not 0 < value < 1 for value in cuts):
            return False, f"{key} is not fractions strictly inside the frame"
        if cuts != sorted(cuts):
            return False, f"{key} is not in increasing order"
    return True, ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="", help="only sheets whose raw stem contains this")
    parser.add_argument("--dry-run", action="store_true", help="show the questions, call nothing")
    parser.add_argument("--readonly", action="store_true", help="call and report, write nothing")
    parser.add_argument("--redo", action="store_true",
                        help="re-ask sheets that already have an answer (costs tokens again)")
    args = parser.parse_args()

    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    sheets = [s for s in plan["sheets"] if args.only in s["raw"]]
    targets = [s for s in sheets if len(s["cuts"]) > 1 and not s.get("plate")]
    skipped = [s for s in sheets if not (len(s["cuts"]) > 1 and not s.get("plate"))]
    print(f"{len(targets)} sheet(s) to read, {len(skipped)} skipped "
          f"(single panel or whole-frame plate)")

    if args.dry_run:
        for sheet in targets[:3]:
            print(f"\n--- {sheet['raw']}")
            print(question(sheet))
        return 0

    key = api_key()
    answers = {}
    if ANSWER.exists():
        answers = json.loads(ANSWER.read_text(encoding="utf-8")).get("sheets", {})
    if not args.redo:
        done = [s for s in targets if s["raw"] in answers]
        targets = [s for s in targets if s["raw"] not in answers]
        if done:
            print(f"{len(done)} sheet(s) already answered, skipping (--redo to ask again)")
    agreed = changed = refused = 0
    spent = 0
    for sheet in targets:
        image, size = payload(LIBRARY / sheet["raw"])
        try:
            reply = call(key, question(sheet), image)
        except urllib.error.HTTPError as error:
            print(f"  {sheet['raw']:60} HTTP {error.code}: {error.read().decode()[:120]}")
            refused += 1
            continue
        except Exception as error:                                   # noqa: BLE001
            print(f"  {sheet['raw']:60} {type(error).__name__}: {error}")
            refused += 1
            continue

        spent += reply.get("usage", {}).get("total_tokens", 0)
        choice = reply["choices"][0]
        answer = parse(choice["message"].get("content") or "")
        if answer is None:
            usage = reply.get("usage", {})
            print(f"  {sheet['raw']:60} unparseable ({choice.get('finish_reason')}, "
                  f"{usage.get('completion_tokens')} tokens, "
                  f"{usage.get('completion_tokens_details', {}).get('reasoning_tokens')} reasoning): "
                  f"{(choice['message'].get('content') or '')[:60]!r}")
            refused += 1
            continue

        ok, why = usable(answer, sheet)
        if not ok:
            print(f"  {sheet['raw']:60} refused: {why}")
            refused += 1
            continue

        planned = tuple(sheet.get("planned_grid") or sheet["grid"])
        found = [answer["columns"], answer["rows"]]
        if found == list(planned):
            agreed += 1
            verdict = "agrees"
        else:
            changed += 1
            verdict = f"re-read {planned[0]}x{planned[1]} -> {found[0]}x{found[1]}"
        print(f"  {sheet['raw']:60} {verdict:28} "
              f"{answer.get('confidence', '?'):4} {(answer.get('note') or '')[:40]}", flush=True)
        if not args.readonly:
            write_answers(answers)

        answers[sheet["raw"]] = {
            "planned": list(planned),
            "columns": answer["columns"],
            "rows": answer["rows"],
            "cut_x": answer["cut_x"],
            "cut_y": answer["cut_y"],
            "confidence": answer.get("confidence"),
            "note": answer.get("note"),
            "image": list(size),
            "model": MODEL,
        }

    print(f"\n{agreed} agreement(s), {changed} re-read, {refused} refused, "
          f"{spent} tokens across {len(targets)} sheet(s)")
    if args.readonly:
        print("read-only, nothing written")
        return 0
    write_answers(answers)
    print(f"wrote {ANSWER} ({len(answers)} sheet(s))")
    return 0


def write_answers(answers: dict) -> None:
    """Save after every sheet, so a kill or a crash keeps the answers already paid for."""
    ANSWER.write_text(json.dumps({
        "note": (
            "Sheet layouts read from the render by a vision model, keyed by raw sheet. "
            f"`planned` is the arrangement the prompt asked for; `columns`/`rows` is what the "
            f"model counted and `cut_x`/`cut_y` are the fractions it says a cut could pass "
            f"through. `cut_sheets.py` prefers this arrangement when it holds the same number "
            f"of cells as the plan, so no panel can lose its name. Model: {MODEL}."
        ),
        "model": MODEL,
        "sheets": answers,
    }, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
