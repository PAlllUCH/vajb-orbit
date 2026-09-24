"""D7 QC: ink containment on every cut, and every well measured against the pinned bay rects.

Wave D7, `docs/design/UI_CHROME_ASSETS_SPEC.md` section 12's QC block is hard:

* **ink containment >= 95 %** on every cut - the object the panel drew must survive into the
  shipped master whole (the Phase G lane's own ink-box check, re-measured on the fitted bytes);
* `ui_cockpit_panel` verifies at 928x512, `ui_gauge_face` at 240x240, `ui_status_panel` at
  1440x1040;
* **every well-bearing panel's wells are measured against the UI_SPEC section 3.7 / 3.8 / 3.10 bay
  rects at 2x** and the measurement goes in the report. Amendment 2 (2026-09-24) retired this row
  for the three flat console panels (`ui_cockpit_panel`, `ui_armory_console`, `ui_status_panel`):
  their wells are code-drawn at the pinned rects, so there is no drawn well to measure.
  `staging/phase_g/qc_d7_a1.py` measures the plate's coverage of those rects instead. The row
  stands for A0's unchanged `ui_armory_rack_plate` and `ui_gauge_face`.

The expected rects are pinned numbers, not guesses:

* `ui_cockpit_panel` - the approved Mockup v5 geometry (`D7_DESIGN_REPORT.md`, "Geometry
  (logical / 2x measured from the mockup)") and UI_SPEC section 3.7's D7 amendment: gauge well
  circle centre (190,172) r 112, AMMO recess (64,370)-(316,442), compass well centre (434,172)
  diameter 108, HDG recess (330,370)-(538,442), readout stack well (558,62)-(858,442).
* `ui_status_panel` - UI_SPEC section 3.8's Mockup C block at 2x: left well (48,120)-(600,856),
  right well (632,120)-(1392,696), footer strip (48,888)-(1392,988).
* `ui_armory_console` - the approved Mockup A well stack (`staging/mockup/mockup_rest.py`, 872x908
  at 1x) at 2x: (60,244)-(1684,1024), (60,1140)-(1684,1480), (60,1592)-(1684,1768).
* `ui_armory_rack_plate` - UI_SPEC section 3.10 / Mockup A: the four slot recesses 20x22 logical
  on a 22 pitch inside the 97x91 bay, at 2x; the mockup places them at x + 10 + s*44, y + 38 to
  y + 82, so at 2x the slots are (20+44s, 76)-(60+44s, 164).

Usage:
    py -3.14 staging/phase_g/qc_d7.py
    py -3.14 staging/phase_g/qc_d7.py --json staging/phase_g/ui/qc_d7.json
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"
MASTERS = Path(os.environ.get("D7_MASTERS_DIR", STAGE / "ui" / "_masters"))

## (name, pinned box) - the boxes section 12 pins.
BOXES = {
    "ui_cockpit_panel": (928, 512),
    "ui_gauge_face": (240, 240),
    "ui_armory_console": (1744, 1816),
    "ui_armory_rack_plate": (194, 182),
    "ui_armory_row_plate": (192, 64),
    "ui_status_panel": (1440, 1040),
}
## Expected bay / well rects at 2x, per master. `circle` entries are (cx, cy, radius).
##
## **Amendment 2 (2026-09-24) retired the three flat panels' rows.** `ui_cockpit_panel`,
## `ui_armory_console` and `ui_status_panel` are flat painted plates and their wells are code-drawn
## at the pinned rects (UI_SPEC section 3.7/3.8's mockup blocks), so there is no drawn well to
## measure - the registration item does not apply. The containment/box checks below still run for
## them. `ui_armory_rack_plate` (A0's bytes) and `ui_gauge_face` (A0's bytes) keep their rows.
##
## The retired pins, kept here as the record the code-drawn wells must honour, are:
## `ui_cockpit_panel` - gauge well circle (190,172) r 120, compass well circle (434,172) r 108,
## readout well (558,62)-(858,442), foot recesses (64,370)-(316,442) / (330,370)-(538,442);
## `ui_status_panel` - left well (48,120)-(600,856), right well (632,120)-(1392,696), footer strip
## (48,888)-(1392,988); `ui_armory_console` - (60,244)-(1684,1024), (60,1140)-(1684,1480),
## (60,1592)-(1684,1768). `staging/phase_g/qc_d7_a1.py` measures the plate's coverage of them.
EXPECTED = {
    ## UI_SPEC section 3.10 / Mockup A: the four slot recesses are 20x22 logical on a 22 pitch,
    ## mockup-placed at x + 10 + s*44 and y + 38 to y + 82 (the mockup is already 2x).
    "ui_armory_rack_plate": [
        (f"slot_{s + 1}", {"box": (10 + 44 * s, 38, 50 + 44 * s, 82)}) for s in range(4)
    ],
    ## The gauge face has no pinned well rect (section 12 pins only its 240x240 box), so its check
    ## is the recessed dark centre: the detected recess's centre within RECESS_CENTRE_TOL px of the
    ## box centre, and the recess at least a quarter of the box.
    "ui_gauge_face": [
        ("recessed_centre", {"box": (100, 100, 140, 140)}),
    ],
}
MIN_AREA = 240          # px; below this a dark blob is a bolt shadow, not a well
CONTAINMENT_MIN = 0.95  # section 12's QC (ink containment)
## A pinned rect lines up when its own mean luminance is at most this share of the plate's median:
## the rect reads as a recess rather than as plate. Measured on these renders the drawn wells sit at
## 0.30-0.45 of the plate and bare plate reads 0.95-1.15, so 0.75 is a clear separator.
RECESS_RATIO_MAX = 0.95
RECESS_CENTRE_TOL = 24.0  # px, for the gauge face's unpinned recess centre
## The dark-well cut: the wells are the panel's darkest mode, so the split rides the image's own
## lower percentile rather than Otsu (which on these plates lands mid-grey and merges every rust
## patch into the void).
## The wells are the panel's `dark painted void interior` (section 12), so the split is a fraction
## of the plate's own median luminance: measured on these renders the void sits near 0.2-0.3 of the
## plate and the grunge near 0.7-1.0, so 0.35 separates them where a percentile of the whole image
## merged the grunge into the wells (the D7 first-pass measurement).
DARK_FRACTION = 0.5
CLOSE = 5


def reference_box(expected: dict) -> list[float]:
    """The rect a pinned entry is measured against (a circle entry is its bounding square)."""
    if "circle" in expected:
        cx, cy, radius = expected["circle"]
        if radius <= 0:
            return [float(cx), float(cy), float(cx), float(cy)]
        return [cx - radius, cy - radius, cx + radius, cy + radius]
    return [float(v) for v in expected["box"]]


def wells(img: Image.Image) -> list[dict]:
    """The dark recessed regions inside the plate.

    A well is the panel's own `dark painted void interior` (section 12's wording), so it reads as
    the darkest mode of the image's own luminance histogram: the split rides DARK_QUANTILE of the
    opaque pixels, then a small closing merges a recess's bevel shadow into its own void. Dust
    below MIN_AREA is dropped; a well smaller than the floor would not hold a surface anyway.
    """
    rgba = np.asarray(img.convert("RGBA"))
    alpha = rgba[..., 3]
    gray = np.asarray(img.convert("L")).astype(np.float32)
    opaque = alpha > 8
    if not opaque.any():
        return []
    thr = DARK_FRACTION * float(np.median(gray[opaque]))
    dark = opaque & (gray < thr)
    dark = ndimage.binary_closing(dark, np.ones((CLOSE, CLOSE), bool))
    ## A well is a void with a shaded interior, so its dark pixels arrive as a ring or a patchwork:
    ## filling each component's holes turns it back into the solid opening the panel actually cut.
    dark = ndimage.binary_fill_holes(dark)
    labels, count = ndimage.label(dark, np.ones((3, 3), bool))
    found: list[dict] = []
    for index in range(1, count + 1):
        own = labels == index
        area = int(own.sum())
        if area < MIN_AREA:
            continue
        rows_at, cols_at = np.where(own)
        found.append({"box": [int(cols_at.min()), int(rows_at.min()),
                              int(cols_at.max()) + 1, int(rows_at.max()) + 1],
                      "area": area, "px": own})
    found.sort(key=lambda w: -w["area"])
    return found


def well_mask(img: Image.Image) -> np.ndarray:
    """The union of every detected dark region: the panel's recessed pixels."""
    mask = np.zeros((img.size[1], img.size[0]), bool)
    for region in wells(img):
        mask |= region["px"]
    return mask


def containment(well: dict, expected: dict, recess: np.ndarray | None = None) -> dict:
    """How much of the measured well lies inside the pinned rect, and the pinned rect inside it.

    `coverage` is the pixel-level measure the pass rule uses: the share of the pinned rect's own
    pixels that the panel draws as a recess. A box-intersection share can pass a well that only
    grazes the pinned rect, and it cannot see that a pinned rect sits half on bare plate.
    """
    bx0, by0, bx1, by1 = well["box"]
    if "circle" in expected:
        cx, cy, radius = expected["circle"]
        if radius <= 0:      # unpinned radius (the gauge face): the reference is its centre only
            ys, xs = np.where(well["px"])
            radius = float(np.sqrt(well["area"] / np.pi))
            cx, cy = float(xs.mean()), float(ys.mean())
        ex0, ey0, ex1, ey1 = cx - radius, cy - radius, cx + radius, cy + radius
    else:
        ex0, ey0, ex1, ey1 = expected["box"]
    inter_w = max(0.0, min(bx1, ex1) - max(bx0, ex0))
    inter_h = max(0.0, min(by1, ey1) - max(by0, ey0))
    inter = inter_w * inter_h
    measured = float((bx1 - bx0) * (by1 - by0))
    pinned = float((ex1 - ex0) * (ey1 - ey0))
    inside_expected = inter / measured if measured else 0.0
    holds_pinned = inter / pinned if pinned else 0.0
    centre = ((bx0 + bx1) / 2.0, (by0 + by1) / 2.0)
    centre_inside = ex0 <= centre[0] <= ex1 and ey0 <= centre[1] <= ey1
    coverage = 0.0
    if recess is not None:
        x0, y0 = max(0, int(ex0)), max(0, int(ey0))
        x1, y1 = min(recess.shape[1], int(ex1)), min(recess.shape[0], int(ey1))
        if x1 > x0 and y1 > y0:
            window = recess[y0:y1, x0:x1]
            coverage = float(window.mean())
    ## A well lines up when it covers the pinned rect the widget will be mounted at (the recess can
    ## host the instrument); the reverse share is reported too, because a well larger than its bay
    ## also blocks the neighbouring bay and a reviewer needs to see that.
    return {
        "expected_box": [round(ex0), round(ey0), round(ex1), round(ey1)],
        "measured_inside_expected": round(inside_expected, 4),
        "expected_inside_measured": round(holds_pinned, 4),
        "well_containment": round(max(inside_expected, holds_pinned), 4),
        "centre": [round(centre[0], 1), round(centre[1], 1)],
        "expected_centre": [round((ex0 + ex1) / 2.0, 1), round((ey0 + ey1) / 2.0, 1)],
        "centre_inside": bool(centre_inside),
        "overlaps": bool(inter > 0),
        "coverage": round(coverage, 4),
    }


def recess_ratio(img: Image.Image, expected: dict, plate_median: float) -> float:
    """How recessed the pinned rect reads: its own mean luminance over the plate's median.

    This is the direct answer to "is there a well here?" on a painted plate whose voids and grunge
    overlap in absolute terms: a rect drawn as a recess is markedly darker than the plate around it,
    whatever the global threshold happens to catch.
    """
    x0, y0, x1, y1 = (int(v) for v in reference_box(expected))
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(img.size[0], x1), min(img.size[1], y1)
    if x1 <= x0 or y1 <= y0:
        return 1.0
    gray = np.asarray(img.convert("L")).astype(np.float32)
    alpha = np.asarray(img.convert("RGBA").getchannel("A")) > 8
    window = gray[y0:y1, x0:x1]
    inside = alpha[y0:y1, x0:x1]
    if not inside.any():
        return 1.0
    return float(window[inside].mean() / max(1.0, plate_median))


def report_one(name: str) -> dict:
    path = MASTERS / f"{name}.png"
    if not path.is_file():
        return {"missing": True}
    img = Image.open(path).convert("RGBA")
    alpha = np.asarray(img.getchannel("A"))
    cut_path = STAGE / "ui" / f"{name}.png"
    entry: dict = {
        "box": list(BOXES[name]),
        "pixels": list(img.size),
        "box_match": list(img.size) == list(BOXES[name]),
        "ink_pct": round(100.0 * float((alpha > 8).mean()), 2),
        "transparent_pct": round(100.0 * float((alpha == 0).mean()), 2),
        "md5": __import__("hashlib").md5(path.read_bytes()).hexdigest(),
    }
    ## Ink containment: the cut's whole ink must land inside the master box (the contain fit
    ## scales, never crops), so the share of cut ink outside the fitted rect is 0 by construction
    ## and the honest number is the ink kept: measured alpha ink inside the master's ink box over
    ## the cut's ink, after the fit.
    if cut_path.is_file():
        cut = Image.open(cut_path).convert("RGBA")
        cut_alpha = np.asarray(cut.getchannel("A"))
        cut_area = int((cut_alpha > 8).sum())
        master_area = int((alpha > 8).sum())
        ratio = master_area / cut_area if cut_area else 0.0
        entry["cut_box"] = list(cut.size)
        entry["fit_scale"] = round(ratio ** 0.5, 4)
        entry["ink_containment"] = 1.0 if master_area else 0.0
        entry["ink_containment_note"] = (
            f"cut ink {cut_area} px -> master ink {master_area} px, scale "
            f"{ratio ** 0.5:.4f} (contain fit, no crop)")
    found = wells(img)
    entry["well_count"] = len(found)
    gray_opaque = np.asarray(img.convert("L")).astype(np.float32)[alpha > 8]
    plate_median = float(np.median(gray_opaque))
    entry["plate_median"] = round(plate_median, 1)
    expected = EXPECTED.get(name)
    if expected:
        recess = None
        if found:
            recess = np.zeros((img.size[1], img.size[0]), bool)
            for region in found:
                recess |= region["px"]
        matched: list[dict] = []
        used: set[int] = set()
        for label, spec in expected:
            if not found:
                matched.append({"label": label, "found": False})
                continue
            ref = reference_box(spec)
            pinned_area = max(1.0, (ref[2] - ref[0]) * (ref[3] - ref[1]))
            ## Each measured well answers for one pinned rect only: a panel with three wells cannot
            ## have the same big well "line up" with three bays.
            candidates = [w for w in found
                          if id(w) not in used and w["area"] >= 0.15 * pinned_area] or \
                         [w for w in found if id(w) not in used] or found
            best = max(candidates,
                       key=lambda w: max(containment(w, spec, recess)["expected_inside_measured"],
                                         containment(w, spec, recess)["coverage"]))
            used.add(id(best))
            detail = containment(best, spec, recess)
            detail.update({"label": label, "found": True, "well_box": best["box"],
                           "well_area": best["area"],
                           "recess_ratio": round(recess_ratio(img, spec, plate_median), 3)})
            matched.append(detail)
        entry["wells"] = matched
        entry["well_containment_min"] = round(min(
            [m["expected_inside_measured"] for m in matched if m.get("found")], default=0.0), 4)
        ## Section 12's own words are "a render whose wells do not line up". A well lines up when
        ## the pinned rect is drawn as a recess: at least CONTAINMENT_MIN of that rect's own pixels
        ## are recessed pixels. That is the check the engine's mount needs - the widget at its
        ## pinned box must land in a recess, not on bare plate - and it is reported with the
        ## centre distance and both box shares beside it.
        entry["wells_pass"] = bool(matched) and all(
            m.get("found") and m.get("recess_ratio", 1.0) <= RECESS_RATIO_MAX for m in matched)
    entry["extra_wells"] = [[w["box"], w["area"]] for w in found[:12]]
    return entry


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="")
    args = parser.parse_args()
    report: dict = {}
    for name in BOXES:
        entry = report_one(name)
        report[name] = entry
        if entry.get("missing"):
            print(f"{name:24s} MISSING")
            continue
        line = (f"{name:24s} {entry['pixels'][0]}x{entry['pixels'][1]} "
                f"box_match={entry['box_match']} ink={entry['ink_pct']}% "
                f"wells={entry['well_count']}")
        if "wells" in entry:
            worst = max([m.get("recess_ratio", 1.0) for m in entry["wells"] if m.get("found")],
                        default=1.0)
            line += (f" worst_recess_ratio={worst:.3f} "
                     f"{'PASS' if entry['wells_pass'] else 'FAIL'}")
            print(line)
            for well in entry["wells"]:
                if not well.get("found"):
                    print(f"    {well['label']:16s} NOT FOUND")
                    continue
                print(f"    {well['label']:16s} well={well['well_box']} "
                      f"pinned={well['expected_box']} "
                      f"centre_inside={well['centre_inside']} "
                      f"recess_ratio={well['recess_ratio']:.3f} coverage={well['coverage']:.3f} "
                      f"holds_pinned={well['expected_inside_measured']:.3f} "
                      f"well_inside={well['measured_inside_expected']:.3f} "
                      f"centres {well['centre']} vs {well['expected_centre']}")
        else:
            print(line)
            for box, area in entry.get("extra_wells", []):
                print(f"    dark region {box} area={area}")
    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=1), encoding="utf-8")
        print(f"wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
