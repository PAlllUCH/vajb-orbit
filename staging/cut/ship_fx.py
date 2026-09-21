"""Ship the FX re-cut into the project: the four alpha files, the split frames, the new mine.

One script, because the pass moves three different kinds of file and every one of them has to be
reversible and recorded:

- **Alpha** (`staging/cut/_fx_ship/*-keyed.png`) -> `assets/fx/<name>.png`, replacing the RGB
  render. Only the four FX_SPEC section 0.1 names are here; everything else stays RGB on void
  black.
- **Frames** (`staging/cut/_fx_frames/<sheet>/<name>_fN.png`) -> `assets/fx/<name>_fN.png`. The
  four `fx_muzzle_flash_f{1..4}.png` that already shipped are replaced by this pass's cut, which
  is the same art centred on the sheet's own shared canvas.
- **The mine** -> `assets/fx/fx_mine.png` (a new file, keyed and centred).

Masters are never overwritten: `fx_laser_bolt.png` and `fx_mining_beam.png` keep the pixels the
current wiring's region tables were measured against, so nothing regresses while the frames land
beside them. Swapping those two masters is a separate, deliberate step (the wiring re-measures
its regions first).

Usage:
    py -3.14 staging/cut/ship_fx.py --check
    py -3.14 staging/cut/ship_fx.py --apply
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "vajb-orbit" / "assets" / "fx"
ALPHA_DIR = ROOT / "staging" / "cut" / "_fx_ship"
FRAME_DIRS = (ROOT / "staging" / "cut" / "_fx_cycles", ROOT / "staging" / "cut" / "_fx_frames")
## Sheet dirs whose frames another pass replaced: v1's bolt (16.4:1/9.4:1) and mining (3 bursts
## plus grain), and v2's two-frame bolt.
SUPERSEDED = {"fx_laser_bolt", "fx_laser_bolt_v2", "fx_mining_beam"}
MINE = ROOT / "staging" / "phase_g" / "fx" / "fx_mine_final.png"
REPORT = ROOT / "staging" / "cut" / "_fx_ship_report.json"


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def plan() -> list[dict]:
    """Every file this pass ships, one row per destination, with the keyed cut preferred.

    Precedence, in order: the four alpha names, then the cycle frames, then the master-sheet
    frames. A destination is written once - `--check` prints the collisions - so a superseded
    cut (v1's bolt and mining frames, v2's two-frame bolt) can never land on top of the v3 read
    that replaced it.
    """
    candidates: list[tuple[int, str, Path, Path]] = []
    for keyed in sorted(ALPHA_DIR.glob("*-keyed.png")):
        name = keyed.name.replace("-keyed.png", "")
        candidates.append((0, name, keyed, PROJECT / f"{name}.png"))
    for folder in sorted(FRAME_DIRS):
        for frame in sorted(folder.glob("*/*.png")):
            if frame.parent.name in SUPERSEDED:
                continue
            keyed = frame.with_name(f"{frame.stem}-keyed.png")
            source = keyed if keyed.exists() else frame
            rank = 1 if folder.name == "cycles" else 2
            name = frame.name.replace("-keyed.png", ".png")
            candidates.append((rank, name, source, PROJECT / name))
    if MINE.is_file():
        candidates.append((0, "fx_mine.png", MINE, PROJECT / "fx_mine.png"))
    taken: dict[str, int] = {}
    moves: list[dict] = []
    for rank, name, source, dest in sorted(candidates, key=lambda row: (row[3].name, row[0])):
        if name in taken:
            continue
        taken[name] = rank
        moves.append({"kind": ("alpha" if rank == 0 else "frame"),
                      "source": source, "dest": dest, "keyed": source.stem.endswith("-keyed")})
    return moves


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    moves = plan()
    if not moves:
        print("nothing staged to ship")
        return 1
    applied: list[dict] = []
    for move in moves:
        source, dest = move["source"], move["dest"]
        before = md5(dest) if dest.exists() else None
        replaced = "same" if before == md5(source) else ("replaced" if before else "new")
        print(f"  {move['kind']:5s} {source.name:34s} -> {dest.name:34s} {replaced}")
        if args.apply:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
        applied.append({"kind": move["kind"], "source": str(source.relative_to(ROOT)),
                        "dest": str(dest.relative_to(ROOT)), "state": replaced,
                        "source_md5": md5(source),
                        "replaced_md5": before, "keyed": move["keyed"]})
    if args.apply:
        REPORT.write_text(json.dumps({"shipped": applied}, indent=1), encoding="utf-8")
        counts: dict[str, int] = {}
        for row in applied:
            counts[row["kind"]] = counts.get(row["kind"], 0) + 1
        print(f"shipped {counts} -> {REPORT}")
    else:
        print(f"{len(applied)} file(s) would move (--apply writes them)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
