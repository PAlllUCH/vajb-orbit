"""Phase F.2 (C2b) - thicken an outline glyph at the MASTER until 16 px reads solid.

ICONS_SPEC section 9.4 item 2 asks for the four outline glyphs (zoom_plus, zoom_minus,
credits, shield) to "threshold to solid iron black" at 16 px, and the work order (Stage 1,
DESIGNER_TODO.MD) gives the rule for getting there: *thicken at the MASTER and regenerate
only that family - never fix a cut*. F.2 regenerated the four with a heavy-stroke prompt; the
model answered with 2 px-equivalent strokes and a 0.16-0.25 solid-ink share at 16 px, still
under the 0.28 median of the 139-family set.

This is the second half of that rule, applied locally and measured: dilate the master's alpha
with a disk until the cut's measured stroke at 16 px reaches the target, then re-cut the
quartet from the thickened master (`recut_quartet.py`). A greyscale dilation keeps the
master's anti-aliasing ramp, so the thicker stroke is not a hard-edged blob; the RGB of the
new pixels is copied from the nearest existing ink pixel, so the flat iron black is untouched.

Refusals (the pass prints a number and stops rather than shipping a blob):
  - the enclosed negative-space hole at 16 px must stay at least `HOLE_MIN` px, so the glyph
    cannot close up into the C2 data-core defect (a solid block);
  - ink coverage at 16 px must stay under 0.85 (C2's own bar for a block is 0.90).

Dry run by default; `--apply` backs the master up into `_f2_backup/staging__icons__<base>.png`
once and overwrites the staged master.

Usage:
  py -3.14 staging/phase_f/thicken_master.py --families icon_zoom_plus,icon_shield
  py -3.14 staging/phase_f/thicken_master.py --families ... --apply
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
ICONS = STAGE / "icons"
BACKUP = STAGE / "_f2_backup"
REPORT = STAGE / "thicken_report.json"

sys.path.insert(0, str(STAGE))
from recut_quartet import cut, min_stroke      # noqa: E402

TARGET_STROKE = 3.0     # px at 16, the stroke width that thresholds to solid ink
SIZE = 16
R_MAX = 60              # master px; the master is ~44x the 16 px cut, so 60 px is 1.4 px
HOLE_MIN = 16           # the glyph must keep at least a 4x4 enclosure at 16 px;
                        # below that it reads as a solid block, which is the C2 data-core
                        # defect this bar exists to avoid (zoom_plus has only 25 px to start)
COVERAGE_MAX = 0.85     # C2's block bar is 0.90


def disk(radius: int) -> np.ndarray:
    r = int(radius)
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return (x * x + y * y) <= r * r


def metrics(img: Image.Image) -> dict:
    cut16 = cut(img, SIZE, "contain")
    arr = np.asarray(cut16)
    alpha = arr[..., 3]
    ink = alpha > 8
    hole = int((~ink).sum()) - int(_outside_count(~ink))
    return {"stroke": round(min_stroke(cut16), 2),
            "coverage": round(float(ink.mean()), 3),
            "solid": round(float((alpha[ink] >= 250).mean()) if ink.any() else 0.0, 3),
            "hole": hole}


def _outside_count(background: np.ndarray) -> int:
    """Background pixels connected to the tile border (i.e. not enclosed by the glyph)."""
    labels, n = ndi.label(background)
    if n == 0:
        return 0
    border = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
    border.discard(0)
    return int(np.isin(labels, list(border)).sum())


def thicken(master: Image.Image, radius: int) -> Image.Image:
    arr = np.asarray(master.convert("RGBA")).copy()
    alpha = arr[..., 3].astype(np.uint8)
    grown = ndi.grey_dilation(alpha, footprint=disk(radius))
    rgb = arr[..., :3]
    ink = alpha > 8
    if not ink.any():
        return master
    indices = ndi.distance_transform_edt(~ink, return_distances=False, return_indices=True)
    nearest = rgb[indices[0], indices[1]]
    added = (grown > alpha) & ~ink
    rgb[added] = nearest[added]
    arr[..., 3] = grown
    return Image.fromarray(arr, "RGBA")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--families", required=True)
    ap.add_argument("--target", type=float, default=TARGET_STROKE)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    wanted = [f.strip() for f in args.families.split(",") if f.strip()]

    rows = []
    for base in wanted:
        src = ICONS / f"{base}.png"
        if not src.is_file():
            print(f"{base}: no staged master at {src}")
            continue
        master = Image.open(src).convert("RGBA")
        before = metrics(master)
        print(f"{base}: master {master.size}  before stroke {before['stroke']} "
              f"solid {before['solid']} coverage {before['coverage']} hole {before['hole']}")
        chosen = None
        for radius in range(1, R_MAX + 1):
            cand = thicken(master, radius)
            m = metrics(cand)
            if m["hole"] < HOLE_MIN or m["coverage"] > COVERAGE_MAX:
                print(f"  r={radius:2d} refused: hole {m['hole']} coverage {m['coverage']}")
                break
            chosen = (radius, cand, m)
            if m["stroke"] >= args.target:
                break
        if chosen is None:
            print(f"  no admissible radius: the glyph cannot be thickened without closing up")
            rows.append({"family": base, "applied": False, "reason": "no admissible radius"})
            continue
        radius, cand, after = chosen
        print(f"  r={radius} px -> stroke {after['stroke']} solid {after['solid']} "
              f"coverage {after['coverage']} hole {after['hole']}"
              f"  ({'applied' if args.apply else 'dry run'})")
        if args.apply:
            BACKUP.mkdir(parents=True, exist_ok=True)
            dest = BACKUP / f"staging__icons__{base}.png"
            if not dest.exists():
                shutil.copy2(src, dest)
            cand.save(src)
        rows.append({"family": base, "radius": radius, "before": before, "after": after,
                     "target": args.target, "applied": bool(args.apply)})

    REPORT.write_text(json.dumps({"target_stroke": args.target, "size": SIZE,
                                  "hole_min": HOLE_MIN, "rows": rows}, indent=1),
                      encoding="utf-8")
    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {len(rows)} families")
    print("next: py -3.14 staging/phase_f/ship_batch.py icons --only <base>.png  then  "
          "py -3.14 staging/phase_f/recut_quartet.py --families <base>,... --apply")
    print(f"wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
