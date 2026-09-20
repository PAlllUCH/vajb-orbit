"""Pull repaired sprites from the library into the Godot project, on demand.

Sprites are not restored in bulk. They live in `asset-library/_cuts/<family>/` and are
copied into `vajb-orbit/assets/<family>/` only when a feature needs them, so the project
holds what it uses and nothing else.

    py -3.14 staging/assetpipe/pull.py --status                    what the project has
    py -3.14 staging/assetpipe/pull.py --list ships                what is available
    py -3.14 staging/assetpipe/pull.py ships ship_bomber_front.png ship_miner_front.png
    py -3.14 staging/assetpipe/pull.py ships --all                 the whole family
    py -3.14 staging/assetpipe/pull.py ships --pattern "ship_bomber_*"

Each pulled sprite gets a `.job.json` recording the run it came from (job id, model, prompt)
and the raw sheet it was rendered as, so provenance survives the copy. A `.import` file is
written by Godot on reimport - run `filesystem_manage reimport` in the editor, or a headless
`--editor --quit` with the editor closed.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import shutil
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
CUTS = LIBRARY / "_cuts"
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
ORIGINALS = LIBRARY / "_originals_manifest.json"
FAMILIES = ("ships", "env", "fx", "ui", "icons")


def run_index() -> dict[str, dict]:
    """sprite stem -> the run that produced it."""
    data = json.loads(ORIGINALS.read_text(encoding="utf-8"))
    index: dict[str, dict] = {}
    for run in data["runs"]:
        raw = next((f for f in run["files"] if f["role"] == "raw"), None)
        for name in run["produced_assets"]:
            index[name] = {
                "run_key": run["run_key"],
                "run_dir": run["run_dir"],
                "job_id": run["job_id"],
                "model": run["model"],
                "prompt": run["prompt"],
                "raw_sheet": f"asset-library/{run['family']}/{raw['name']}" if raw else None,
            }
    return index


def available(family: str) -> list[Path]:
    family_dir = CUTS / family
    if not family_dir.is_dir():
        return []
    return sorted(family_dir.glob("*.png"))


def shipped(family: str) -> set[str]:
    family_dir = ASSETS / family
    if not family_dir.is_dir():
        return set()
    return {p.name for p in family_dir.glob("*.png")}


def status() -> None:
    print(f"{'family':7s} {'in library':>10s} {'in project':>10s}")
    for family in FAMILIES:
        print(f"{family:7s} {len(available(family)):10d} {len(shipped(family)):10d}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("family", nargs="?", default="")
    ap.add_argument("names", nargs="*", default=[])
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--pattern", default="")
    args = ap.parse_args()

    if args.status or not args.family:
        status()
        if not args.family:
            print("\npick a family and either names, --all or --pattern")
        if not args.family:
            return

    family = args.family
    if family not in FAMILIES:
        raise SystemExit(f"unknown family {family!r}; expected one of {', '.join(FAMILIES)}")

    pool = available(family)
    if args.all:
        wanted = pool
    elif args.pattern:
        wanted = [p for p in pool if fnmatch.fnmatch(p.name, args.pattern)]
    elif args.names:
        by_name = {p.name: p for p in pool}
        wanted = []
        for name in args.names:
            key = name if name.endswith(".png") else f"{name}.png"
            if key not in by_name:
                raise SystemExit(f"{key} is not in asset-library/_cuts/{family}/")
            wanted.append(by_name[key])
    else:
        print(f"asset-library/_cuts/{family}/ holds {len(pool)} sprites:")
        for p in pool:
            mark = "*" if p.name in shipped(family) else " "
            print(f"  {mark} {p.name}")
        print("\n  * = already in the project")
        return

    if args.list:
        for p in wanted:
            print(p.name)
        return

    index = run_index()
    dest_dir = ASSETS / family
    dest_dir.mkdir(parents=True, exist_ok=True)
    pulled = 0
    for src in wanted:
        dest = dest_dir / src.name
        shutil.copy2(src, dest)
        origin = index.get(src.stem)
        record = {
            "shipped_from": f"asset-library/_cuts/{family}/{src.name}",
            "repaired_by": "staging/assetpipe/repair.py",
            "note": ("alpha rebuilt from the render RGB preserved under the old transparent "
                     "pixels; geometry unchanged"),
        }
        if origin:
            record["origin"] = origin
        dest.with_name(dest.name + ".job.json").write_text(
            json.dumps(record, indent=2), encoding="utf-8")
        pulled += 1
    print(f"pulled {pulled} sprites into vajb-orbit/assets/{family}/")
    print("now reimport: filesystem_manage reimport, or a headless --editor --quit "
          "with the editor closed")


if __name__ == "__main__":
    main()
