#!/usr/bin/env python3
"""Read the owner's red-X marks off the D2 mark sheets.

Detection is a DIFF against the reference render (build_mark_sheets.py draws the
same cell), so any mark colour works and ember/red art cannot false-positive.

    python3 staging/d2/read_marks.py            # scan staging/d2/mark_sheets/
    python3 staging/d2/read_marks.py <dir>      # scan a folder of marked sheets

Prints the marked global cell IDs and writes D2_MARKS_READ.tsv next to the
sheets. A cell counts as marked at >= 25 changed pixels after a 45-level
per-channel diff threshold (anti-aliasing tolerant, JPEG-save tolerant).
"""

import os
import sys

from PIL import Image, ImageChops

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_mark_sheets as bms  # noqa: E402

DIFF_THRESHOLD = 45
MARK_PIXELS = 25


def diff_count(ref_img, marked_img, box):
    ref = ref_img.crop(box).convert("RGB")
    got = marked_img.crop(box).convert("RGB")
    if ref.size != got.size:
        got = got.resize(ref.size)
    diff = ImageChops.difference(ref, got).convert("L")
    mask = diff.point(lambda p: 255 if p > DIFF_THRESHOLD else 0)
    return sum(1 for p in mask.getdata() if p)


def main():
    scan_dir = sys.argv[1] if len(sys.argv) > 1 else bms.OUT_DIR
    entries = bms.build_index()
    g = bms.sheet_geometry()
    n_sheets = (len(entries) + bms.PER_SHEET - 1) // bms.PER_SHEET

    marked, detail = [], []
    for s in range(n_sheets):
        path = os.path.join(scan_dir, f"D2_MARK_{s + 1:02d}.png")
        if not os.path.exists(path):
            print(f"MISSING {path}")
            continue
        marked_img = Image.open(path)
        ref_canvas = Image.new("RGB", (g["width"], g["height"]), bms.C_BG)
        from PIL import ImageDraw
        draw = ImageDraw.Draw(ref_canvas)
        chunk = entries[s * bms.PER_SHEET:(s + 1) * bms.PER_SHEET]
        for i, entry in enumerate(chunk):
            r, c = divmod(i, bms.COLS)
            bms.draw_cell(ref_canvas, draw, entry,
                          c * bms.CELL_W, bms.HEADER_H + r * bms.CELL_H)
        for i, entry in enumerate(chunk):
            r, c = divmod(i, bms.COLS)
            x = c * bms.CELL_W
            y = bms.HEADER_H + r * bms.CELL_H
            n = diff_count(ref_canvas, marked_img, (x, y, x + bms.CELL_W, y + bms.CELL_H))
            detail.append((entry, n, s + 1))
            if n >= MARK_PIXELS:
                marked.append(entry)

    out = os.path.join(scan_dir, "D2_MARKS_READ.tsv")
    with open(out, "w") as fh:
        fh.write("id\tname\tfamily\tcls\tdiff_px\tmarked\n")
        for entry, n, s in detail:
            fh.write(f"{entry['id']}\t{entry['name']}\t{entry['family']}\t"
                     f"{entry['cls']}\t{n}\t{'X' if n >= MARK_PIXELS else ''}\n")

    print(f"marked {len(marked)} of {len(entries)}")
    print("ids:", ",".join(str(e["id"]) for e in marked))
    for e in marked:
        print(f"  #{e['id']:<4} {e['name']}  ({e['family']}, {e['cls']})")
    border = sorted((n, e) for e, n, s in detail if 5 <= n < MARK_PIXELS)
    if border:
        print("borderline cells (5..%d diff px, verify by eye):" % (MARK_PIXELS - 1))
        for n, e in border:
            print(f"  #{e['id']:<4} {e['name']}  diff={n}")
    print("detail:", out)


if __name__ == "__main__":
    main()
