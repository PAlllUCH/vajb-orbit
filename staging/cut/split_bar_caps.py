"""Split the sheet's two cap plates off the sprite the cutter merged them into.

The sheet holds three objects: two caps and the minimap bezel. The cutter gave both caps one cell,
found both objects in it, and drew them as a single sprite on the canvas its largest object needed,
which left 681x174 of art floating in a 1063x1065 black square. A bar cap is stretched by the bar
it caps, so it wants a tight frame, and it is its own element.

**What the sheet does not hold is a left and a right cap.** Measured on the two crops: the mean
absolute difference between them is 6.0, and between the first and the second mirrored is 34.7, so
they are two near-identical copies of one plate and not a pair. The brightness profile of both runs
dark on the left and bright on the right. They are therefore named as what they are, the cap and a
near-identical alternate, and the opposite end of a bar wants the cap mirrored in the engine.

Usage:
    py -3.14 staging/cut/split_bar_caps.py --check     # the measured split, no files written
    py -3.14 staging/cut/split_bar_caps.py
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import label

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
SHEET = LIBRARY / "raw" / "ui" / "ui_bar_caps_sheet.png"
OUT_DIR = LIBRARY / "cut" / "ui"
OLD = OUT_DIR / "ui_bar_caps.png"
DROPPED = LIBRARY / "_dropped"
NAMES = ("ui_bar_caps", "ui_bar_caps_alt")
MIN_PX = 300
TOL = 14
MARGIN = 2
# The grid is 2 columns by 1 row, so the caps live in the left cell.
LEFT_CELL = 0.5


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    image = Image.open(SHEET).convert("RGB")
    array = np.asarray(image, dtype=np.int16)
    width = array.shape[1]
    outer = np.concatenate([array[0], array[-1], array[:, 0], array[:, -1]])
    colours, counts = np.unique(outer.reshape(-1, 3), axis=0, return_counts=True)
    background = colours[counts.argmax()].astype(np.int16)
    print(f"sheet {image.size}, backdrop {background.tolist()}")

    delta = np.abs(array - background).max(axis=2)
    ink = delta > TOL
    labels, count = label(ink)
    pieces = []
    for index in range(1, count + 1):
        rows, cols = np.where(labels == index)
        if rows.size < MIN_PX:
            continue
        pieces.append((cols.min(), cols.max(), rows.min(), rows.max(), rows.size))
    # The caps are the two short plates; the bezel is the tall frame. Picking by height avoids
    # slicing the sheet, which would cut the bezel in half and invent a third object.
    pieces.sort(key=lambda box: box[3] - box[2])
    print(f"{len(pieces)} object(s) on the sheet, shortest first:")
    for box in pieces:
        print(f"   x {box[0]}..{box[1]}  y {box[2]}..{box[3]}  "
              f"{box[3] - box[2]} tall  {box[4]} px")
    if len(pieces) < 3:
        raise SystemExit(f"expected at least 3 objects, found {len(pieces)}; not splitting")
    caps, tallest = pieces[:2], pieces[2]
    if (tallest[3] - tallest[2]) < 2 * (caps[1][3] - caps[1][2]):
        raise SystemExit("the third object is not clearly taller; refusing to guess which are caps")
    pieces = sorted(caps)

    crops = []
    for left, right, top, bottom, _px in pieces:
        box = (max(left - MARGIN, 0), max(top - MARGIN, 0),
               min(right + MARGIN + 1, width), min(bottom + MARGIN + 1, array.shape[0]))
        crops.append(image.crop(box))
    canvas = (max(c.width for c in crops), max(c.height for c in crops))
    first = np.asarray(crops[0], dtype=np.int16)
    second = np.asarray(crops[1], dtype=np.int16)
    if first.shape == second.shape:
        same = float(np.abs(first - second).mean())
        mirrored = float(np.abs(first[:, ::-1] - second).mean())
        verdict = ("two near-identical copies, not a pair" if same < mirrored
                   else "a mirrored pair")
        print(f"crop difference {same:.1f}, mirrored {mirrored:.1f}: {verdict}")
    print(f"each cap on a shared {canvas[0]}x{canvas[1]} canvas")

    if args.check:
        preview = Image.new("RGB", (canvas[0] * 2 + 6, canvas[1]), tuple(int(v) for v in background))
        for index, crop in enumerate(crops):
            preview.paste(crop, (index * (canvas[0] + 6), 0))
        preview.save(LIBRARY / "_review" / "peek_bar_caps_split.jpg", "JPEG", quality=88)
        print("wrote asset-library/_review/peek_bar_caps_split.jpg")
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # Write to temp names first: OLD lives at one of the final names, so the
    # merged sprite must be out of the way before the crops take its place.
    temps = []
    for index, (name, crop) in enumerate(zip(NAMES, crops)):
        tmp = OUT_DIR / f"_{name}.tmp"
        tile = Image.new("RGB", canvas, tuple(int(v) for v in background))
        tile.paste(crop, ((canvas[0] - crop.width) // 2, (canvas[1] - crop.height) // 2))
        tile.save(tmp)
        temps.append(tmp)
    if OLD.exists():
        DROPPED.mkdir(exist_ok=True)
        OLD.replace(DROPPED / OLD.name)
        print("moved the merged ui_bar_caps.png to _dropped/")
    for name, tmp in zip(NAMES, temps):
        tmp.replace(OUT_DIR / f"{name}.png")
        print(f"wrote cut/ui/{name}.png  {tmp.with_name(f'{name}.png').stat().st_size} bytes")

    sheets_path = LIBRARY / "_sheets.json"
    sheets = json.loads(sheets_path.read_text(encoding="utf-8"))
    for entry in sheets["sheets"]:
        if entry.get("raw") == "raw/ui/ui_bar_caps_sheet.png":
            entry["cuts"] = [c for c in entry["cuts"] if c != "ui_bar_caps"] + list(NAMES)
            entry["grid"] = [2, 2]
            entry["note"] = ("the caps cell holds two objects and is cut as two sprites; the "
                             "bezel is the other cell")
    sheets_path.write_text(json.dumps(sheets, indent=1, ensure_ascii=False), encoding="utf-8")
    print("updated _sheets.json")
    print("now: py -3.14 staging/cut/build_library.py && py -3.14 staging/cut/validate_names.py --library")


if __name__ == "__main__":
    main()
