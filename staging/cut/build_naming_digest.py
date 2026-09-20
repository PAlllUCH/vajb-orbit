"""Write the naming pass's working set as small flat files, so a worker can read all of it.

The raw working files are too big to hand a worker: `_vision.json` is 339 KB, `_library.json` is
1.7 MB, and a brief that tells a model to read them spends a whole context on data it does not
need. This writes the four things a naming pass actually reads and nothing else:

    _naming/broken.tsv      one row per file whose name cannot be kept, with the evidence beside
                            it: what it shows, and for a cut sprite the sheet and cell it came
                            from plus the ordered objects the sheet's own render holds
    _naming/live_names.txt  every name already on disk, so a new name cannot collide
    _naming/canonical.txt   every name the docs and the shipped catalog already use
    _naming/sheets.tsv      per raw sheet: family, grid, plate flag, its cut names in cell order,
                            and the objects a vision model saw on it in reading order
    _naming/brief_digest.md the counts, so the brief does not have to describe the shape of the
                            problem in prose

Usage:
    py -3.14 staging/cut/build_naming_digest.py
    py -3.14 staging/cut/build_naming_digest.py --show
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
OUT = Path(__file__).resolve().parent / "_naming"

BROKEN = ("content-mismatch", "placeholder", "twin", "slug", "phase-prefix")


def load(name: str) -> dict:
    path = LIBRARY / name
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def tsv(rows: list[list[str]]) -> str:
    return "\n".join("\t".join(str(c).replace("\t", " ").replace("\n", " ") for c in row)
                     for row in rows) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--show", action="store_true")
    args = parser.parse_args()

    library = load("_library.json")
    assets = library["assets"]
    issues = library["name_issues"]
    vision = load("_vision.json").get("files", {})
    sheets = load("_sheets.json").get("sheets", [])
    vocabulary = load("_vocabulary.json")

    OUT.mkdir(parents=True, exist_ok=True)

    # broken files, with the render's own objects for whichever sheet they came from
    objects_of = {k: v.get("objects") or [] for k, v in vision.items() if k.startswith("raw/")}
    plan_of = {e["raw"]: e for e in sheets}
    rows = [["path", "issue", "family", "current_name", "role", "kind", "subject", "detail",
             "sheet", "cell", "of", "grid", "sheet_objects_in_reading_order"]]
    report = []
    seen: set[str] = set()
    for key in BROKEN:
        for rel in sorted(issues.get(key) or []):
            if rel in seen:
                continue  # one row per file: the most specific issue wins
            seen.add(rel)
            r = assets[rel]
            panel = r.get("cut_from") or {}
            sheet = panel.get("sheet") or (rel if r["role"].startswith("sheet") else "")
            plan = plan_of.get(sheet) or {}
            rows.append([
                rel, key, r["family"], r["name"], r["role"], r["kind"] or "", r["subject"] or "",
                r["detail"] or "", sheet, panel.get("panel", ""), panel.get("of", ""),
                "x".join(map(str, (plan.get("grid") or panel.get("grid") or []))),
                " | ".join(objects_of.get(sheet, [])),
            ])
            report.append((key, rel, r["description"] or ""))
    (OUT / "broken.tsv").write_text(tsv(rows), encoding="utf-8")

    live = sorted({r["name"] for r in assets.values()})
    (OUT / "live_names.txt").write_text("\n".join(live) + "\n", encoding="utf-8")

    docs = vocabulary.get("docs", {})
    catalog = vocabulary.get("catalog", {})
    canonical = sorted(set(docs) | {Path(n).stem for n in catalog})
    (OUT / "canonical.txt").write_text("\n".join(canonical) + "\n", encoding="utf-8")

    srows = [["raw_sheet", "family", "grid", "cells", "plate", "cut_names_in_cell_order",
              "objects_seen_in_reading_order"]]
    for e in sheets:
        srows.append([e["raw"], e["family"], "x".join(map(str, e["grid"])),
                      e["grid"][0] * e["grid"][1], e["plate"], " | ".join(e["cuts"]),
                      " | ".join(objects_of.get(e["raw"], []))])
    (OUT / "sheets.tsv").write_text(tsv(srows), encoding="utf-8")

    code = vocabulary.get("code", {})
    brief = [
        "# The naming pass, in numbers",
        "",
        f"- Files: {library['counts']['files']} "
        f"({', '.join(f'{v} {k}' for k, v in library['counts']['roles'].items())}).",
        f"- Names that cannot be kept: {sum(len(issues.get(k) or []) for k in BROKEN)}",
    ]
    for key in BROKEN:
        brief.append(f"  - `{key}`: {len(issues.get(key) or [])}")
    brief += [
        f"- Names on disk, so a new name must not collide: {len(live)}.",
        f"- Names the docs and the catalog already use: {len(canonical)}.",
        f"- Raw sheets: {len(sheets)}. Sheets whose panels are placeholders: "
        f"{sum(1 for e in sheets if any('_sheet_' in c for c in e['cuts']))}.",
        f"- Code and scene files holding a literal asset path: {len(code)} "
        f"({sum(len(v) for v in code.values())} paths).",
        "",
        "## Files",
        "",
        "| File | Rows | What it is |",
        "|---|---|---|",
        f"| `_naming/broken.tsv` | {len(rows) - 1} | every name that must change, with what the "
        "file shows and, for a cut sprite, the sheet and cell it came from and that sheet's own "
        "objects in reading order |",
        f"| `_naming/live_names.txt` | {len(live)} | every name on disk now |",
        f"| `_naming/canonical.txt` | {len(canonical)} | every name the docs or the catalog use; "
        "reuse these rather than inventing near-duplicates |",
        f"| `_naming/sheets.tsv` | {len(sheets)} | per sheet: family, grid, plate flag, its cut "
        "names in cell order, and the objects vision saw on it |",
        "",
    ]
    (OUT / "brief_digest.md").write_text("\n".join(brief), encoding="utf-8")

    print(f"wrote {OUT.relative_to(WORKSPACE)}/")
    for path in sorted(OUT.iterdir()):
        print(f"  {path.name:<20} {path.stat().st_size:>8} bytes")
    print()
    print((OUT / "brief_digest.md").read_text(encoding="utf-8")[:1200])


if __name__ == "__main__":
    main()
