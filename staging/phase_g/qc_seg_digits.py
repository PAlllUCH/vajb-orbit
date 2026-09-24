"""AC5 digit QC for the D6 seven-segment masters (UI_CHROME_ASSETS_SPEC section 11).

Two hard checks, per the spec:

1. **Containment.** For every cell, the lit ink must sit inside `ui_seg_blank`'s ghost segment
   boxes, containment >= 95 % (a Pillow mask check). The ghost boxes are read off the blank
   cell: its unlit segment outlines (panel steel over the panel-black face) are hole-filled into
   solid segment shapes, labelled, and each label's bounding box is a ghost box.
2. **Ink-share ordering.** `blank` smallest of all, then `1` ... through `8` largest.

The ordering is reported twice, because a canonical seven-segment font cannot satisfy the literal
reading: the lit-segment counts are 1 -> 2, 2 -> 5, 3 -> 5, 4 -> 4, 5 -> 5, 6 -> 6, 7 -> 3,
8 -> 7, so a digit with fewer segments (4) sits between two with more (3 and 5) and the strict
`1 < 2 < ... < 8` sequence is geometrically impossible. This script therefore prints

  * `literal` - whether the shares are strictly non-decreasing 1..8, and
  * `by-segment` - whether any digit with fewer lit segments carries more ink than one with more
    (the reading the spec's intent requires: more lit segments means more lit ink),

and passes the ordering only when blank is the minimum, 1 is the minimum of the digits, 8 the
maximum, and no by-segment inversion exists. The literal wording is reported as a finding for the
developer session rather than silently rewritten (`AGENTS.md` escalation bucket 2).

Usage:
    py -3.14 staging/phase_g/qc_seg_digits.py [--dir <dir-with-the-12-cells>] [--json out.json]
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from seg_geometry import lattice

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"
DEFAULT_DIR = STAGE / "ui" / "_masters"

DIGITS = [f"ui_seg_{i}" for i in range(10)]
CELLS = DIGITS + ["ui_seg_pct", "ui_seg_blank"]
LIT_THRESHOLD = 120.0          # bone text #C9CDD2 is ~204; panel steel ~46, gunmetal mid ~62
DILATE_PX = 2                  # the lit segment may be drawn a hair larger than the ghost
CONTAINMENT_MIN = 0.95
SEGMENTS = {"ui_seg_0": 6, "ui_seg_1": 2, "ui_seg_2": 5, "ui_seg_3": 5, "ui_seg_4": 4,
            "ui_seg_5": 5, "ui_seg_6": 6, "ui_seg_7": 3, "ui_seg_8": 7, "ui_seg_9": 6,
            "ui_seg_pct": 5}


def luminance(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def plate_mask(img: Image.Image) -> np.ndarray:
    return np.asarray(img.convert("RGBA").getchannel("A")) > 8


def ghost_boxes(blank: Image.Image) -> tuple[np.ndarray, dict]:
    """The blank cell's unlit segment boxes, as a boolean region plus the boxes themselves.

    The reference is the blank's own unlit bars. They sit a step above the plate's face (measured
    on the shipped cell: face ~25-31, unlit bars ~45), so the mask between the two levels is the
    ghost ink; its bounding box is the segment field, and `seg_geometry.lattice` - the same
    geometry `seg_svg_digits.py` rasterises - turns that field into the seven segment boxes. The
    lattice is used rather than connected components because a seven-segment face's middle bar
    touches the vertical bars, so components merge (measured: four components, not seven).

    A cell that carries no ghost ink at all (a generated blank whose unlit bars were matted away)
    falls back to the lattice over the plate's own inner area, and that is reported.
    """
    plate = plate_mask(blank)
    lum = luminance(blank)
    height, width = lum.shape
    inset_x, inset_y = max(2, width // 12), max(2, height // 14)
    inner = np.zeros_like(plate, bool)
    inner[inset_y:height - inset_y, inset_x:width - inset_x] = True
    inside = plate & inner
    if not inside.any():
        return np.zeros_like(plate, bool), {"boxes": [], "source": "no plate"}
    face = float(np.percentile(lum[inside], 20))
    unlit = float(np.percentile(lum[inside], 80))
    threshold = (face + unlit) / 2.0
    ceiling = min(LIT_THRESHOLD, unlit + 12.0)
    ## An opening first: the rasteriser's antialiasing leaves a one-pixel mid-tone bridge across a
    ## segment gap.
    ghost = ndimage.binary_opening(
        inside & (lum >= threshold) & (lum < ceiling), np.ones((2, 2), bool))
    source = "ghost ink"
    if int(ghost.sum()) < 40:
        field = (inset_x, inset_y, width - inset_x, height - inset_y)
        source = "plate inner area (no ghost ink found)"
    else:
        rows, cols = np.where(ghost)
        field = (int(cols.min()), int(rows.min()), int(cols.max()) + 1, int(rows.max()) + 1)
    boxes: list[list[int]] = []
    region = np.zeros_like(plate, bool)
    for left, top, right, bottom in lattice(field).values():
        left, top = max(0, int(left) - DILATE_PX), max(0, int(top) - DILATE_PX)
        right, bottom = min(width, int(round(right)) + DILATE_PX), min(height, int(round(bottom)) + DILATE_PX)
        if right <= left or bottom <= top:
            continue
        boxes.append([left, top, right, bottom])
        region[top:bottom, left:right] = True
    return region & plate, {"boxes": boxes, "source": source,
                            "face": face, "unlit": unlit, "threshold": threshold,
                            "field": list(field)}


def field_mask(img: Image.Image) -> np.ndarray:
    """The cell's face: the plate inside its painted frame, where the segments live.

    Lit ink is counted only here, so a specular catch on a rivet or the frame's own bevel cannot
    read as a lit segment (the blank cell carries two such pixels on the frame, which would
    otherwise fail its own reference check).
    """
    plate = plate_mask(img)
    height, width = plate.shape
    inset_x, inset_y = max(2, width // 12), max(2, height // 14)
    inner = np.zeros_like(plate, bool)
    inner[inset_y:height - inset_y, inset_x:width - inset_x] = True
    return plate & inner


def measure(name: str, img: Image.Image, ghost: np.ndarray) -> dict:
    plate = plate_mask(img)
    lum = luminance(img)
    lit = field_mask(img) & (lum >= LIT_THRESHOLD)
    plate_px = int(plate.sum())
    lit_px = int(lit.sum())
    inside = int((lit & ghost).sum())
    containment = (inside / lit_px) if lit_px else 1.0
    return {
        "name": name,
        "plate_px": plate_px,
        "lit_px": lit_px,
        "ink_share": (lit_px / plate_px) if plate_px else 0.0,
        "containment": containment,
        "containment_ok": containment >= CONTAINMENT_MIN,
        "segments": SEGMENTS.get(name),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", default=str(DEFAULT_DIR))
    parser.add_argument("--json", default="")
    args = parser.parse_args()
    folder = Path(args.dir)

    missing = [n for n in CELLS if not (folder / f"{n}.png").is_file()]
    if missing:
        print(f"missing cells in {folder}: {', '.join(missing)}")
        return 1

    images = {name: Image.open(folder / f"{name}.png").convert("RGBA") for name in CELLS}
    ghost, ghost_info = ghost_boxes(images["ui_seg_blank"])
    rows = [measure(name, images[name], ghost) for name in CELLS]

    print(f"reference ui_seg_blank: {len(ghost_info['boxes'])} ghost segment box(es) "
          f"({ghost_info['source']}) {ghost_info['boxes']}")
    print(f"{'cell':16s} {'plate px':>9s} {'lit px':>8s} {'ink share':>10s} {'contain':>8s} "
          f"{'segs':>4s}  verdict")
    for row in rows:
        print(f"{row['name']:16s} {row['plate_px']:9d} {row['lit_px']:8d} "
              f"{row['ink_share']:10.4f} {row['containment']:8.4f} "
              f"{str(row['segments']):>4s}  "
              f"{'PASS' if row['containment_ok'] else 'FAIL'}")

    shares = {row["name"]: row["ink_share"] for row in rows}
    blank = shares["ui_seg_blank"]
    digits = [f"ui_seg_{i}" for i in range(10)]
    literal_seq = [shares[f"ui_seg_{i}"] for i in range(1, 9)]
    literal = all(literal_seq[i] <= literal_seq[i + 1] + 1e-9 for i in range(len(literal_seq) - 1))
    by_segment = True
    inversions: list[str] = []
    for a in DIGITS:
        for b in DIGITS:
            if SEGMENTS[a] < SEGMENTS[b] and shares[a] > shares[b] + 1e-9:
                by_segment = False
                inversions.append(f"{a}({SEGMENTS[a]}) > {b}({SEGMENTS[b]})")
    blank_min = blank <= min(shares.values()) + 1e-9
    one_min = shares["ui_seg_1"] <= min(shares[d] for d in digits) + 1e-9
    eight_max = shares["ui_seg_8"] >= max(shares[d] for d in digits) - 1e-9
    containment_ok = all(row["containment_ok"] for row in rows)
    ordering_ok = bool(blank_min and one_min and eight_max and by_segment)

    print("")
    print(f"containment >= {CONTAINMENT_MIN:.0%} on every cell: "
          f"{'PASS' if containment_ok else 'FAIL'}")
    print(f"blank smallest of all: {'PASS' if blank_min else 'FAIL'} "
          f"(blank {blank:.4f}, next {sorted(shares.values())[1]:.4f})")
    print(f"1 smallest of the digits: {'PASS' if one_min else 'FAIL'} "
          f"(1 {shares['ui_seg_1']:.4f})")
    print(f"8 largest of the digits: {'PASS' if eight_max else 'FAIL'} "
          f"(8 {shares['ui_seg_8']:.4f}, max {max(shares[d] for d in digits):.4f})")
    print(f"by-segment order (more lit segments => more ink): "
          f"{'PASS' if by_segment else 'FAIL'}"
          + (f"  inversions: {', '.join(inversions)}" if inversions else ""))
    print(f"literal 1<=2<=...<=8 (impossible for a seven-segment font, reported, not enforced): "
          f"{'holds' if literal else 'does not hold'}")
    print(f"AC5 verdict: {'PASS' if (containment_ok and ordering_ok) else 'FAIL'}")

    if args.json:
        Path(args.json).write_text(json.dumps({
            "reference": ghost_info,
            "rows": rows,
            "containment_ok": bool(containment_ok),
            "blank_min": bool(blank_min),
            "one_min": bool(one_min),
            "eight_max": bool(eight_max),
            "by_segment": bool(by_segment),
            "inversions": inversions,
            "literal_monotone": bool(literal),
            "verdict": "PASS" if (containment_ok and ordering_ok) else "FAIL",
        }, indent=1), encoding="utf-8")
    return 0 if (containment_ok and ordering_ok) else 1


if __name__ == "__main__":
    raise SystemExit(main())
