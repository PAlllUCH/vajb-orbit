"""Copy the library's shippable assets into the Godot project, and log where each came from.

Reads `asset-library/_library.json`, which already knows each file's role, its target family
folder and its provenance, so this is a copy with three guards rather than a decision:

1. A `sheet` or `sheet-keyed` file is provenance and never enters a family folder. The raw
   renders go to `vajb-orbit/assets/_sheets/` only when `--include-sheets` is passed.
2. An existing file is not overwritten unless its md5 matches or `--replace` is passed, because
   a silent overwrite of art is indistinguishable from art that never changed.
3. Every file with a `name_issue` is copied anyway, since the art is wanted, and listed in the
   report so a rename cannot land without someone seeing what it will touch.

The run also writes `vajb-orbit/assets/<family>/generation_log.md`: for each shipped file, the
model, job id, date and the prompt that produced its sheet. The project rule is that generated
art keeps a generation log next to it, and this is that log, regenerated rather than appended.

Usage:
    py -3.14 staging/cut/pull.py --check                  # what would move, and the size
    py -3.14 staging/cut/pull.py                          # sprites and plates into their folders
    py -3.14 staging/cut/pull.py --include-sheets         # also copy the raw renders
    py -3.14 staging/cut/pull.py --family icons --check   # one family only
    py -3.14 staging/cut/pull.py --replace                # overwrite what is already there
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from collections import defaultdict
from datetime import datetime
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
PROJECT_ASSETS = WORKSPACE / "vajb-orbit" / "assets"
LIBRARY_JSON = LIBRARY / "_library.json"
REPORT = LIBRARY / "_pull_report.json"


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def log_for(family: str, rows: list[dict]) -> str:
    lines = [
        f"# Generation log - {family}",
        "",
        f"**Generated:** {datetime.now().isoformat(timespec='seconds')} by "
        "`staging/cut/pull.py`. Regenerate, never hand-edit.",
        "",
        "One row per shipped file. `sheet` is the render it was cut out of, `panel` its cell. "
        "The prompt is the exact text sent to the image model for that render; identical "
        "prompts on different stamps are separate runs, not duplicates.",
        "",
        "| File | Sheet | Panel | Model | Job | Stamp |",
        "|---|---|---|---|---|---|",
    ]
    for r in sorted(rows, key=lambda r: r["name"]):
        panel = r.get("cut_from") or {}
        run = r.get("requested") or {}
        lines.append(
            f"| `{r['name']}.png` | {panel.get('sheet', '-')} | "
            f"{panel.get('panel', '-')} of {panel.get('of', '-')} | "
            f"{run.get('model', '-')} | {run.get('job_id', '-')} | {run.get('stamp', '-')} |")
    prompts = {r["name"]: (r.get("requested") or {}).get("prompt") for r in rows}
    lines += ["", "## The prompts", ""]
    for name, prompt in sorted(prompts.items()):
        if prompt:
            lines += [f"### `{name}.png`", "", "```", prompt.strip(), "```", ""]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--include-sheets", action="store_true")
    parser.add_argument("--family", default="", help="ships, icons, env, ui or fx")
    parser.add_argument("--shippable-only", action="store_true",
                        help="skip anything whose name still carries an issue")
    args = parser.parse_args()

    if not LIBRARY_JSON.exists():
        raise SystemExit("run staging/cut/build_library.py first")
    library = json.loads(LIBRARY_JSON.read_text(encoding="utf-8"))
    assets = library["assets"]

    chosen = [r for r in assets.values() if r["role"] in ("sprite", "plate")]
    if args.family:
        chosen = [r for r in chosen if r["folder"] == args.family]
    if args.shippable_only:
        chosen = [r for r in chosen if not r["name_issue"]]
    sheets = [r for r in assets.values() if r["role"] in ("sheet", "sheet-keyed")] \
        if args.include_sheets else []

    plan: list[tuple[Path, Path, dict]] = []
    for r in chosen:
        if not r["folder"]:
            continue
        plan.append((LIBRARY / r["path"], PROJECT_ASSETS / r["folder"] / f"{r['name']}.png", r))
    for r in sheets:
        plan.append((LIBRARY / r["path"], PROJECT_ASSETS / "_sheets" / Path(r["path"]).name, r))

    copied = skipped = 0
    total = 0
    by_family: dict[str, list[dict]] = defaultdict(list)
    for source, target, record in plan:
        total += source.stat().st_size
        if target.exists() and not args.replace:
            if md5(target) == record["measured"]["md5"]:
                skipped += 1
                by_family[record["folder"] or "_sheets"].append(record)
                continue
            print(f"  exists, differs, left alone: {target.relative_to(WORKSPACE)}")
            skipped += 1
            continue
        if args.check:
            copied += 1
            if record.get("folder") != "":
                by_family[record["folder"] or "_sheets"].append(record)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied += 1
        by_family[record["folder"] or "_sheets"].append(record)

    print(f"{'would copy' if args.check else 'copied'} {copied}, left {skipped} alone, "
          f"{total / 1e6:.0f} MB of source")
    for family in sorted(by_family):
        rows = by_family[family]
        print(f"  {family:<9} {len(rows):>4} file(s)")
    if args.check:
        return

    for family, rows in by_family.items():
        if family == "_sheets":
            continue
        (PROJECT_ASSETS / family / "generation_log.md").write_text(
            log_for(family, rows), encoding="utf-8")

    issues = defaultdict(list)
    for r in chosen:
        if r["name_issue"]:
            issues[r["name_issue"]].append(r["name"])
    REPORT.write_text(json.dumps({
        "generated": datetime.now().isoformat(timespec="seconds"),
        "copied": copied, "left_alone": skipped, "bytes": total,
        "families": {k: len(v) for k, v in by_family.items()},
        "name_issues_still_shipped": {k: sorted(v) for k, v in issues.items()},
    }, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {REPORT.relative_to(WORKSPACE)} and a generation log per family")
    for key, value in issues.items():
        print(f"  shipped with a name issue ({key}): {len(value)}")


if __name__ == "__main__":
    main()
