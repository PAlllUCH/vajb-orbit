"""Gather every raw render into asset-library/raw/, in one flat folder.

The gathered originals lived under asset-library/<family>/ as `<name>__raw.png` plus, for
the sheets that were keyed, `<name>__keyed.png`. This moves the raw renders to
asset-library/raw/<name>.png -- the single folder the cutter reads.

The keyed sheets go to the same folder under `<name>__keyed.png`: they are a keyed copy of
a sheet that already has a pristine render, so they keep the marker rather than
overwriting one, and the cutter ignores them because their stem matches no run.

Every file is hashed before and after the move, and the move is refused if a stem would
collide or a hash would change.

Usage:
    py -3.14 staging/cut/make_raw.py --check     # report only, change nothing
    py -3.14 staging/cut/make_raw.py
"""
from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
FAMILIES = ("ships", "env", "ui", "icons", "fx")
RAW_SUFFIX = "__raw.png"
KEYED_SUFFIX = "__keyed.png"


def md5(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def collect() -> tuple[list[tuple[Path, str]], list[tuple[Path, str]]]:
    """(source, destination name) for the raw renders and for the keyed sheets."""
    raws, keyed = [], []
    for family in FAMILIES:
        folder = LIBRARY / family
        if not folder.is_dir():
            continue
        for path in sorted(folder.glob("*.png")):
            if path.name.endswith(RAW_SUFFIX):
                raws.append((path, path.name[: -len(RAW_SUFFIX)] + ".png"))
            elif path.name.endswith(KEYED_SUFFIX):
                keyed.append((path, path.name[: -len(".png")] + "__keyed.png"))
    return raws, keyed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="report only, move nothing")
    args = parser.parse_args()

    raws, keyed = collect()
    for label, moves, folder in (("raw", raws, "raw"), ("keyed", keyed, "raw")):
        names = [destination for _, destination in moves]
        duplicates = sorted({name for name in names if names.count(name) > 1})
        if duplicates:
            print(f"{label}: stem collision, nothing moved: {duplicates}")
            return 1
        target = LIBRARY / folder
        existing = len(list(target.glob("*.png"))) if target.is_dir() else 0
        print(f"{label:5} {len(moves):4} file(s) -> {folder}/{'' if not existing else f'  ({existing} already there)'}")

    if args.check:
        return 0

    before = {path: md5(path) for path, _ in raws + keyed}
    plan = [(source, LIBRARY / "raw" / destination, md5(source))
            for moves in (raws, keyed) for source, destination in moves]
    (LIBRARY / "raw").mkdir(exist_ok=True)

    moved = 0
    for source, target, digest in plan:
        shutil.move(str(source), str(target))
        if not target.exists():
            print(f"MISSING after move: {target}")
            return 1
        if md5(target) != digest:
            print(f"HASH CHANGED: {target}")
            return 1
        moved += 1

    for family in FAMILIES:
        folder = LIBRARY / family
        if folder.is_dir() and not any(folder.iterdir()):
            folder.rmdir()

    print(f"moved {moved} file(s), every md5 unchanged")
    print(f"raw/ {len(list((LIBRARY / 'raw').glob('*.png')))} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
