"""D7-A1 QC: does a flat plate render actually cover the box the code-drawn wells sit in?

Wave D7, UI_CHROME_ASSETS_SPEC section 12 Amendment 2. The three console panels are flat painted
plates and their wells are **code-drawn recesses at the pinned rects** (UI_SPEC section 3.7's
mockup blocks), so the plate must cover the rects the engine will draw into. A plate that only
fills part of its pinned master box leaves the code-drawn wells floating off the art.

This probe applies the shipped lane's own geometry, in order, to a candidate render:

1. `panels.py`'s ink box (the object the detector finds),
2. `wave_g.trim_centre`'s pad (4 % of the long axis, each side),
3. `ship_d7.fit_contain`'s scale to the pinned master box,

and reports the drawn plate rect in box space, the fill shares on both axes, and the coverage of
each panel's code-drawn well union (the rects UI_SPEC section 3.7 / 3.8 / 3.10 pin). The well union
is the region the plate must cover; `union_inside` is the share of that union the plate covers.

Usage:
    py -3.14 staging/phase_g/qc_d7_a1.py <render.png> --panel ui_status_panel
    py -3.14 staging/phase_g/qc_d7_a1.py --json staging/phase_g/ui/qc_d7_a1.json
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

import panels
import qc_d7

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"

## The code-drawn well rects, in the pinned master box's own pixels (2x). Sources:
## `ui_cockpit_panel` - `D7_DESIGN_REPORT.md`'s Mockup v5 geometry table and UI_SPEC section 3.7's
##   D7 amendment (gauge well circle (190,172) r 112 + rim, compass well circle (434,172) d 216 at
##   2x, readout stack well (558,62)-(858,442), the two foot recesses (64,370)-(316,442) /
##   (330,370)-(538,442) - with the v7 unified foot band covered by the readout well's own extent).
## `ui_status_panel` - UI_SPEC section 3.8's Mockup C block at 2x: left well (48,120)-(600,856),
##   right well (632,120)-(1392,696), footer strip (48,888)-(1392,988).
## `ui_armory_console` - the approved Mockup A well stack at 2x (the same three rects `qc_d7.py`
##   pins): (60,244)-(1684,1024), (60,1140)-(1684,1480), (60,1592)-(1684,1768).
WELL_UNIONS = {
    "ui_cockpit_panel": [
        ("gauge_well", (70, 52, 310, 292)),
        ("compass_well", (326, 64, 542, 280)),
        ("readout_well", (558, 62, 858, 442)),
        ("foot_recess", (64, 370, 538, 442)),
    ],
    "ui_status_panel": [
        ("left_well", (48, 120, 600, 856)),
        ("right_well", (632, 120, 1392, 696)),
        ("footer_strip", (48, 888, 1392, 988)),
    ],
    "ui_armory_console": [
        ("racks_well", (60, 244, 1684, 1024)),
        ("inventory_well", (60, 1140, 1684, 1480)),
        ("ammo_well", (60, 1592, 1684, 1768)),
    ],
}
## The three panels Amendment 2 re-renders as flat plates. The other three masters are A0's bytes.
FLAT_PANELS = ("ui_cockpit_panel", "ui_armory_console", "ui_status_panel")
## The three Amendment 2 runs, and the panel each one's plate ships as.
FLAT_RUNS = {
    "panel_cockpit_flat": "ui_cockpit_panel",
    "panel_armory_console_flat": "ui_armory_console",
    "panel_status_flat": "ui_status_panel",
}
PAD_SHARE = 0.04       # `wave_g.trim_centre`'s pad


def ink_box(path: Path) -> tuple[int, int, int, int]:
    image = Image.open(path).convert("RGB")
    gray = np.asarray(image.convert("L")).astype(np.float32)
    mask = panels.ink_mask(gray)
    rows, cols = np.where(mask)
    if not len(rows) or not len(cols):
        raise SystemExit(f"{path}: no ink found")
    return int(cols.min()), int(rows.min()), int(cols.max()) + 1, int(rows.max()) + 1


def geometry(path: Path, name: str, pad_share: float = PAD_SHARE) -> dict:
    left, top, right, bottom = ink_box(path)
    ink_w, ink_h = right - left, bottom - top
    pad = max(8, int(round(pad_share * max(ink_w, ink_h))))
    cut_w, cut_h = ink_w + 2 * pad, ink_h + 2 * pad
    box_w, box_h = qc_d7.BOXES[name]
    scale = min(box_w / cut_w, box_h / cut_h)
    drawn_w, drawn_h = int(round(cut_w * scale)), int(round(cut_h * scale))
    x0 = (box_w - drawn_w) // 2
    y0 = (box_h - drawn_h) // 2
    ## The plate's own ink inside that drawn cut (the pad is transparent), so the ink rect is the
    ## union's real host.
    ink_x0 = x0 + int(round(pad * scale))
    ink_y0 = y0 + int(round(pad * scale))
    ink_x1 = ink_x0 + int(round(ink_w * scale))
    ink_y1 = ink_y0 + int(round(ink_h * scale))
    rects = WELL_UNIONS[name]
    ux0 = min(r[1][0] for r in rects)
    uy0 = min(r[1][1] for r in rects)
    ux1 = max(r[1][2] for r in rects)
    uy1 = max(r[1][3] for r in rects)
    inside = 0.0
    for _label, (rx0, ry0, rx1, ry1) in rects:
        area = float((rx1 - rx0) * (ry1 - ry0))
        ix = max(0.0, min(rx1, ink_x1) - max(rx0, ink_x0))
        iy = max(0.0, min(ry1, ink_y1) - max(ry0, ink_y0))
        inside += ix * iy
    union_area = sum(float((r[1][2] - r[1][0]) * (r[1][3] - r[1][1])) for r in rects)
    return {
        "panel": name,
        "render": str(Path(path).resolve().relative_to(ROOT)),
        "ink_box": [ink_w, ink_h],
        "ink_aspect": round(ink_w / ink_h, 3),
        "box": [box_w, box_h],
        "box_aspect": round(box_w / box_h, 3),
        "cut_box": [cut_w, cut_h],
        "scale": round(scale, 4),
        "drawn_plate": [drawn_w, drawn_h],
        "plate_ink_rect": [ink_x0, ink_y0, ink_x1, ink_y1],
        "fill_w": round(100.0 * (ink_x1 - ink_x0) / box_w, 2),
        "fill_h": round(100.0 * (ink_y1 - ink_y0) / box_h, 2),
        "fill_area": round(100.0 * (ink_x1 - ink_x0) * (ink_y1 - ink_y0) / (box_w * box_h), 2),
        "well_union": [ux0, uy0, ux1, uy1],
        "well_union_inside_pct": round(100.0 * inside / union_area, 2),
        "well_union_covered": bool(
            ink_x0 <= ux0 and ink_y0 <= uy0 and ink_x1 >= ux1 and ink_y1 >= uy1),
    }


def shipped_containment(name: str) -> dict:
    """Section 12's own QC on the fitted bytes: the share of the cut's ink that survives the fit.

    `ship_d7.fit_contain` only scales and pastes, so the honest measure is the overlap of the
    master's ink with the resized cut's ink: an object the fit clipped would show up here.
    """
    import ship_d7
    cut_path = STAGE / "ui" / f"{name}.png"
    master_path = STAGE / "ui" / "_masters" / f"{name}.png"
    box = qc_d7.BOXES[name]
    cut = Image.open(cut_path).convert("RGBA")
    master = Image.open(master_path).convert("RGBA")
    width, height = cut.size
    scale = min(box[0] / width, box[1] / height)
    new = (max(1, int(round(width * scale))), max(1, int(round(height * scale))))
    resized = Image.new("L", box, 0)
    resized.paste(cut.getchannel("A").resize(new, Image.LANCZOS),
                  ((box[0] - new[0]) // 2, (box[1] - new[1]) // 2))
    resized_ink = np.asarray(resized) > 8
    master_ink = np.asarray(master.getchannel("A")) > 8
    total = int(resized_ink.sum())
    inside = int((resized_ink & master_ink).sum())
    return {
        "panel": name,
        "box": list(master.size),
        "box_match": list(master.size) == list(box),
        "cut_box": list(cut.size),
        "fit_scale": round(scale, 4),
        "ink_containment": round(inside / total, 4) if total else 0.0,
        "ink_pct": round(100.0 * float(master_ink.mean()), 2),
        "transparent_pct": round(100.0 * float(1.0 - master_ink.mean()), 2),
        "md5": __import__("hashlib").md5(master_path.read_bytes()).hexdigest(),
    }


def chosen_rows() -> list[dict]:
    """The coverage measurement for each flat run's newest render (the pass the lane would cut)."""
    import wave_g
    rows: list[dict] = []
    for run_id, spec_name in FLAT_RUNS.items():
        master = wave_g.find_master(wave_g.RUNS[run_id])
        if master is not None:
            rows.append(geometry(master, spec_name,
                                 wave_g.RUNS[run_id].get("pad_share", PAD_SHARE)))
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("render", nargs="?")
    parser.add_argument("--panel", default="")
    parser.add_argument("--pad-share", type=float, default=PAD_SHARE)
    parser.add_argument("--shipped", action="store_true",
                        help="measure the staged masters' box and ink containment (section 12 QC)")
    parser.add_argument("--json", default="")
    args = parser.parse_args()

    if args.shipped:
        rows = [shipped_containment(name) for name in qc_d7.BOXES]
        for row in rows:
            print(f"{row['panel']:22s} {row['box'][0]}x{row['box'][1]} "
                  f"box_match={row['box_match']} cut {row['cut_box'][0]}x{row['cut_box'][1]} "
                  f"scale {row['fit_scale']} containment {row['ink_containment'] * 100:.2f}% "
                  f"ink {row['ink_pct']}% md5 {row['md5'][:8]}")
        if args.json:
            Path(args.json).write_text(json.dumps(rows, indent=1), encoding="utf-8")
            print(f"wrote {args.json}")
        return 0

    rows: list[dict] = []
    if args.render:
        if not args.panel:
            raise SystemExit("--panel is required with a render")
        rows.append(geometry(Path(args.render), args.panel, args.pad_share))
    else:
        rows = chosen_rows()

    for row in rows:
        print(f"{row['panel']:20s} {row['render']}")
        print(f"    ink {row['ink_box'][0]}x{row['ink_box'][1]} aspect {row['ink_aspect']} "
              f"(box {row['box_aspect']}) -> scale {row['scale']} "
              f"plate fills {row['fill_w']}% x {row['fill_h']}% = {row['fill_area']}% area")
        print(f"    well union {row['well_union']} inside {row['well_union_inside_pct']}% "
              f"covered={row['well_union_covered']}")
    if args.json:
        Path(args.json).write_text(json.dumps(rows, indent=1), encoding="utf-8")
        print(f"wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
