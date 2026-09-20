"""Phase F.1 Stage 0 - reconcile Phase F output into the shipped asset tree.

Work order: DESIGNER_TODO.MD Stage 0. For every consumer PNG that Phase F left
in staging/phase_f/<family>/, confirm it is (a) moved into
vajb-orbit/assets/<family>/, (b) reimported by the editor (an `.import` sidecar
exists), (c) catalogued in docs/design/ASSET_CATALOG.md.

Read-only. Prints one line per family plus a missing list.

Usage: py -3.14 staging/phase_f/stage0_reconcile.py
"""

import json
import re
import sys
from pathlib import Path

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
STAGE = WORKSPACE / "staging" / "phase_f"
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
CATALOG = WORKSPACE / "docs" / "design" / "ASSET_CATALOG.md"
ICONS_SPEC = WORKSPACE / "docs" / "design" / "ICONS_SPEC.md"

# Intermediates the pipeline writes next to the consumer files, never shipped.
INTERMEDIATE = re.compile(
    r"(-alpha|-matte|-cut-\d+|-cell-\d+|-trim|-keyed|-split-\d+|\d+-alpha|\d+-matte)$")

# Families staged by Phase F and the asset folder each one ships into.
FAMILIES = {
    "ships": "ships",
    "env": "env",
    "fx": "fx",
    "icons": "icons",
}


def consumer_files(family_dir):
    out = []
    for path in sorted(family_dir.glob("*.png")):
        stem = path.stem
        if INTERMEDIATE.search(stem):
            continue
        if family_dir.name == "icons" and stem.startswith("panel_"):
            continue
        out.append(path)
    return out


def catalog_text():
    return CATALOG.read_text(encoding="utf-8")


def main():
    if not CATALOG.is_file():
        print(f"FATAL: {CATALOG} missing")
        return 1
    catalog = catalog_text()
    total = moved = imported = catalogued = 0
    missing = {"NOT_MOVED": [], "NOT_IMPORTED": [], "NOT_CATALOGUED": []}

    for stage_family, asset_family in FAMILIES.items():
        stage_dir = STAGE / stage_family
        asset_dir = ASSETS / asset_family
        files = consumer_files(stage_dir)
        stage_moved = stage_import = stage_cat = 0
        print(f"\n== {stage_family} ({len(files)} staged consumer files) -> assets/{asset_family}/")
        # Icons: the flat families also carry _16/_48 cuts, which are consumer files too.
        extra_cuts = []
        if stage_family == "icons":
            extra_cuts = sorted(
                p for p in stage_dir.glob("*_[0-9]*.png") if not INTERMEDIATE.search(p.stem))
        names = [p.name for p in files + extra_cuts]
        for name in names:
            total += 1
            shipped = asset_dir / name
            if not shipped.is_file():
                missing["NOT_MOVED"].append(f"{asset_family}/{name}")
                continue
            moved += 1
            stage_moved += 1
            if (asset_dir / f"{name}.import").is_file():
                imported += 1
                stage_import += 1
            else:
                missing["NOT_IMPORTED"].append(f"{asset_family}/{name}")
            if name in catalog:
                catalogued += 1
                stage_cat += 1
            else:
                missing["NOT_CATALOGUED"].append(f"{asset_family}/{name}")
        print(f"   moved {stage_moved}/{len(names)}  imported {stage_import}/{len(names)}"
              f"  catalogued {stage_cat}/{len(names)}")

    print(f"\n== totals over {total} staged consumer files")
    print(f"   moved {moved}  imported {imported}  catalogued {catalogued}")
    for kind, items in missing.items():
        print(f"   {kind}: {len(items)}")
        for item in items[:25]:
            print(f"      {item}")
        if len(items) > 25:
            print(f"      ... and {len(items) - 25} more")

    # Masters retained for the re-cut pass: per-icon unsuffixed masters, and the
    # legacy 2K panels that have no per-icon master.
    masters = sorted(p for p in ASSETS.glob("icons/icon_*.png")
                     if not re.search(r"_[0-9]+\.png$", p.name))
    panels = sorted(ASSETS.glob("icons/panel_*.png"))
    print(f"\n== re-cut sources retained in assets/icons/")
    print(f"   per-icon masters: {len(masters)}")
    print(f"   2K panels: {[p.name for p in panels]}")

    print("\n== staged run-folder manifests (evidence of the paid calls)")
    jobs = sorted(STAGE.glob("*/*/job.json"))
    flat_jobs = sorted(STAGE.glob("*/*.job.json"))
    print(f"   run folders with job.json: {len(jobs)}; family-level job.json: {len(flat_jobs)}")

    report = WORKSPACE / "staging" / "phase_f" / "stage0_reconcile.json"
    report.write_text(json.dumps(
        {"total": total, "moved": moved, "imported": imported, "catalogued": catalogued,
         "missing": missing, "masters": len(masters),
         "panels": [p.name for p in panels]}, indent=2), encoding="utf-8")
    print(f"\nwrote {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
