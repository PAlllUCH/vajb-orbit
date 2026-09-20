"""Prune every damaged sprite and every timestamped run folder from the project.

Part of the ASSET_PIPELINE_V2 rebuild. Two things go:

1. The timestamped generation folders inside `vajb-orbit/assets/<family>/`. Every sheet
   they hold is already in `asset-library/` (md5-verified by gather_originals.py), so they
   are pure surplus inside the Godot project - 655 MB the engine was importing for nothing.
2. Every keyed sprite. Measured against the raw renders, the current matte deletes
   rendered artwork in 51-76% of the area it keys out, so the sprites are rebuilt from
   the raws by the new matte rather than patched. `fx/` is kept: FX are RGB on void for
   additive blending and are never keyed, so they cannot be damaged this way.

Every removal is written to `asset-library/_deleted_manifest.json` with its size, plus the
raw sheet each sprite re-derives from, so the delete stays auditable. The old matte lives in
git history (`staging/phase_d/reprocess.py`) and the raws are held in `asset-library/`, so
the deleted bytes are reconstructible.

Usage:
    py -3.14 staging/review/prune_broken.py --list
    py -3.14 staging/review/prune_broken.py --yes
"""

from __future__ import annotations

import argparse
import json
import shutil
import time
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
LIBRARY = WORKSPACE / "asset-library"
MANIFEST = LIBRARY / "_deleted_manifest.json"
# Follows the repo's existing _*_backup convention (staging/phase_*/_fringe_backup,
# _f2_backup, _cut_backup). Derived PNGs are the one thing not reconstructible from the
# raw sheets alone, so they are kept here rather than destroyed outright.
BACKUP = WORKSPACE / "staging" / "_prune_backup"

# fx is kept: RGB on void for additive blending, never keyed, so never damaged.
PRUNE_FAMILIES = ("ships", "env", "ui", "icons")
KEEP_FAMILIES = ("fx",)
# Whole subfolders of derived art that the rebuild regenerates from the parent cuts.
PRUNE_SUBDIRS = {"icons": ("tint",)}
SIDECAR_SUFFIXES = (".import", ".job.json", ".uid")


def run_folders(family_dir: Path) -> list[Path]:
    return sorted(p for p in family_dir.iterdir() if p.is_dir() and (p / "job.json").is_file())


def raw_index() -> dict[str, str]:
    """shipped sprite stem -> the asset-library raw sheet it came from."""
    out: dict[str, str] = {}
    manifest = json.loads((LIBRARY / "_originals_manifest.json").read_text(encoding="utf-8"))
    for run in manifest["runs"]:
        raw = next((f for f in run["files"] if f["role"] == "raw"), None)
        if not raw:
            continue
        for produced in run["produced_assets"]:
            out[produced] = f"{run['family']}/{raw['name']}"
    return out


def build_plan() -> tuple[list[Path], list[Path]]:
    """Return (folders to remove, files to remove)."""
    folders: list[Path] = []
    files: list[Path] = []

    for family in PRUNE_FAMILIES + KEEP_FAMILIES:
        family_dir = ASSETS / family
        if not family_dir.is_dir():
            continue
        folders += run_folders(family_dir)

    for family in PRUNE_FAMILIES:
        family_dir = ASSETS / family
        if not family_dir.is_dir():
            continue
        for sprite in sorted(family_dir.glob("*.png")):
            files.append(sprite)
            for suffix in SIDECAR_SUFFIXES:
                side = sprite.with_name(sprite.name + suffix)
                if side.is_file():
                    files.append(side)
        for sub in PRUNE_SUBDIRS.get(family, ()):
            subdir = family_dir / sub
            if subdir.is_dir():
                folders.append(subdir)

    return folders, files


def dir_size(path: Path) -> tuple[int, int]:
    total = 0
    count = 0
    for f in path.rglob("*"):
        if f.is_file():
            total += f.stat().st_size
            count += 1
    return count, total


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--yes", action="store_true", help="actually delete")
    args = ap.parse_args()

    folders, files = build_plan()
    raws = raw_index()

    folder_n = sum(dir_size(f)[0] for f in folders)
    folder_b = sum(dir_size(f)[1] for f in folders)
    file_b = sum(f.stat().st_size for f in files if f.is_file())
    files = [f for f in files if f.is_file()]

    print(f"folders to remove : {len(folders):4d}  ({folder_n} files, {folder_b / 1048576:.1f} MB)")
    print(f"files   to remove : {len(files):4d}  ({file_b / 1048576:.1f} MB)")
    print(f"total freed       : {(folder_b + file_b) / 1048576:.1f} MB")
    print()
    by_family: dict[str, list[int]] = {}
    for f in files:
        if f.suffix == ".png":
            row = by_family.setdefault(f.parent.name, [0, 0])
            row[0] += 1
            row[1] += f.stat().st_size
    for fam, (n, b) in sorted(by_family.items()):
        print(f"  {fam:6s} {n:4d} sprites  {b / 1048576:6.1f} MB")

    unresolved = [
        f.name for f in files
        if f.suffix == ".png" and f.stem not in raws and f.parent.name in PRUNE_FAMILIES
    ]
    print(f"\nsprites with no recorded raw provenance: {len(unresolved)}")
    for name in unresolved[:15]:
        print(f"  {name}")

    if args.list or not args.yes:
        if not args.yes:
            print("\n(dry run - pass --yes to delete)")
        return

    record = {
        "at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "reason": ("ASSET_PIPELINE_V2 rebuild: the old matte deleted rendered artwork in "
                   "51-76% of the area it keyed out, so every keyed sprite is rebuilt from "
                   "the raw sheets in asset-library/."),
        "kept_families": list(KEEP_FAMILIES),
        "folders": [
            {"path": f.relative_to(WORKSPACE).as_posix(), "files": dir_size(f)[0],
             "bytes": dir_size(f)[1]}
            for f in folders
        ],
        "files": [
            {"path": f.relative_to(WORKSPACE).as_posix(), "bytes": f.stat().st_size,
             "raw": raws.get(f.stem) if f.suffix == ".png" else None}
            for f in files
        ],
        "totals": {"folders": len(folders), "files": len(files),
                   "bytes": folder_b + file_b},
    }
    MANIFEST.write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(f"\nmanifest -> {MANIFEST.relative_to(WORKSPACE).as_posix()}")

    kept = 0
    for f in files:
        if f.suffix != ".png":
            continue
        dest = BACKUP / f.parent.name / f.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dest)
        kept += 1
    for sub in ("tint",):
        src = ASSETS / "icons" / sub
        if src.is_dir():
            dest = BACKUP / "icons" / sub
            dest.mkdir(parents=True, exist_ok=True)
            for f in src.glob("*.png"):
                shutil.copy2(f, dest / f.name)
                kept += 1
    print(f"backup   -> {BACKUP.relative_to(WORKSPACE).as_posix()} ({kept} png kept, "
          f"restore by copying back over vajb-orbit/assets/<family>/)")

    for folder in folders:
        shutil.rmtree(folder)
    for f in files:
        f.unlink()
    print(f"removed {len(folders)} folders and {len(files)} files")


if __name__ == "__main__":
    main()
