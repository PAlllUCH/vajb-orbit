"""Purge the project's own copy of the FX family, and make the library's FX full-frame.

Two things the owner asked for, done together because the second is what the first requires.

**The purge.** `vajb-orbit/assets/fx/` was the one family the old prune deliberately kept, because
FX are RGB on void black for additive blending and the v1 matte would have destroyed them. Every
other family was emptied, so the project held 19 FX textures and nothing else, which is why the
prune's own manifest still records `kept_families: ["fx"]`. The owner's ruling is that these go the
same way as the rest: the library is the single source for every asset. The files are removed and
the removal is recorded in `asset-library/_project_purge.json`, so the trail survives the delete.

**The full frame.** With the project's copies gone, the library's FX would be the only FX, and the
cutter had cropped each one to its object (`fx_engine_trail` came out 1277x248). Cropping an
additive effect changes where it sits on screen and how it scales, and the shipped convention was
a full 2048 square per effect with the game offsetting and tinting it. So every single-read effect
is now a whole-frame plate copied straight from its raw sheet, the same way the env backdrops are,
and only the genuinely separate frames stay cropped: `fx_muzzle_flash_f1` to `_f4` are four frames
of one animation and are meant to be individual sprites.

Usage:
    py -3.14 staging/cut/fx_full_frame.py --check
    py -3.14 staging/cut/fx_full_frame.py
"""
from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
PROJECT_FX = WORKSPACE / "vajb-orbit" / "assets" / "fx"
SHEETS = LIBRARY / "_sheets.json"
CUTS = LIBRARY / "_cuts_manifest.json"
PURGE = LIBRARY / "_project_purge.json"

# An effect that ships as one file keeps its whole frame. These are the frame splits, which do not.
FRAME_SPLITS = ("fx_muzzle_flash_f1", "fx_muzzle_flash_f2", "fx_muzzle_flash_f3",
                "fx_muzzle_flash_f4")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    raw_fx = {p.stem: p for p in (LIBRARY / "raw" / "fx").glob("*.png")}
    cut_fx = {p.stem: p for p in (LIBRARY / "cut" / "fx").glob("*.png")}
    # A sheet whose name is also a cut is a single-read effect: one file, whole frame.
    effects = sorted(name for name in cut_fx
                     if name in raw_fx and name not in FRAME_SPLITS)
    print(f"library FX: {len(cut_fx)} cuts, {len(raw_fx)} sheets")
    print(f"effects to make full-frame: {len(effects)}")

    # --- the purge -------------------------------------------------------------------------
    victims = sorted(p for p in PROJECT_FX.iterdir()
                     if p.suffix in (".png", ".import")) if PROJECT_FX.is_dir() else []
    bytes_in = sum(p.stat().st_size for p in victims)
    print(f"\nproject fx to purge: {len(victims)} file(s), {bytes_in / 1e6:.0f} MB")
    if args.check:
        for path in victims[:5]:
            print(f"   {path.name}")
        print(f"   ... and {max(0, len(victims) - 5)} more")
        return

    if victims:
        record = {
            "at": datetime.now().isoformat(timespec="seconds"),
            "reason": ("the project's FX copies are removed so the library is the single source of "
                       "every asset, as it already is for every other family. This family was the "
                       "one the earlier prune kept, because additive FX must never be keyed."),
            "folder": "vajb-orbit/assets/fx",
            "files": [{"path": str(p.relative_to(WORKSPACE)).replace("\\", "/"),
                       "bytes": p.stat().st_size} for p in victims],
            "total_bytes": bytes_in,
        }
        PURGE.write_text(json.dumps(record, indent=1, ensure_ascii=False), encoding="utf-8")
        for path in victims:
            path.unlink()
        print(f"purged {len(victims)} file(s); record in {PURGE.relative_to(WORKSPACE)}")

    # --- the full frames -------------------------------------------------------------------
    sheets = json.loads(SHEETS.read_text(encoding="utf-8"))
    cuts = json.loads(CUTS.read_text(encoding="utf-8"))
    sheet_by_raw = {e["raw"]: e for e in sheets["sheets"]}
    plate_names = set()
    for entry in cuts["sheets"]:
        name = entry.get("raw", "")
        if not name.startswith("raw/fx/"):
            continue
        stem = Path(name).stem
        if stem in FRAME_SPLITS or stem not in cut_fx:
            continue
        shutil.copy2(raw_fx[stem], cut_fx[stem])
        plate_names.add(stem)
        entry["plate"] = True
        entry["plate_because"] = ("a single-read additive effect: the whole frame is the asset, "
                                 "because cropping it would move it on screen")
        entry["plate_name"] = stem
        entry["sprites"] = []
        plan = sheet_by_raw.get(name)
        if plan:
            plan["plate"] = True
            plan["plate_because"] = entry["plate_because"]
    SHEETS.write_text(json.dumps(sheets, indent=1, ensure_ascii=False), encoding="utf-8")
    CUTS.write_text(json.dumps(cuts, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"made {len(plate_names)} effect(s) whole-frame plates from their raw sheet")
    print("now: py -3.14 staging/cut/build_library.py && py -3.14 staging/cut/validate_names.py --library")


if __name__ == "__main__":
    main()
