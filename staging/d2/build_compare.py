#!/usr/bin/env python3
"""Build the D2 batch comparison sheets: B1 (round 1), B2 (round 2), B3 (round 3).

Per symbol row: each batch at 16/24/48 (the play sizes); B3 adds the 96 px
detail reference. The owner compiles keep-choices from these sheets ("which to
keep from which batch").

Run under the uv ephemeral env (needs cairosvg):

    uv run --with cairosvg python3 staging/d2/build_compare.py
"""

import csv
import io
import os

import cairosvg
from PIL import Image, ImageDraw, ImageFont

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
BATCHES = [
    ("B1", os.path.join(WORKSPACE, "staging/d2/svg"), (150, 158, 168)),
    ("B2", os.path.join(WORKSPACE, "staging/d2/svg_v2"), (150, 112, 58)),
    ("B3", os.path.join(WORKSPACE, "staging/d2/svg_v3"), (112, 168, 96)),
]
OUT_DIR = os.path.join(WORKSPACE, "staging/d2/review_v2")
INDEX = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")

SIZES = [16, 24, 48]
ROW_H = 120
LABEL_W = 250
GROUP_W = 150
ROWS_PER_SHEET = 24
HEADER_H = 96

C_BG = (21, 24, 29)
C_GRID = (58, 66, 76)
C_TEXT = (222, 226, 232)
C_DIM = (150, 158, 168)


def _font(size, bold=False):
    p = "/usr/share/fonts/truetype/dejavu/DejaVuSans" + ("-Bold" if bold else "") + ".ttf"
    return ImageFont.truetype(p, size)


F_TITLE = _font(22, bold=True)
F_NAME = _font(15, bold=True)
F_TAG = _font(13)


def render_svg(path, px):
    if not os.path.exists(path):
        return None
    png = cairosvg.svg2png(url=path, output_width=px, output_height=px)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def draw_group(canvas, draw, x, y, svg_path, label, colour, with_detail):
    draw.text((x, y + 6), label, font=F_TAG, fill=colour)
    cx = x + 6
    sizes = SIZES + ([96] if with_detail else [])
    for px in sizes:
        im = render_svg(svg_path, px)
        cell_y = y + 28 + (96 - px) // 2
        if im is None:
            draw.text((cx, y + 40), "missing", font=F_TAG, fill=(255, 80, 80))
        else:
            canvas.paste(im, (cx, cell_y), im)
        draw.text((cx, y + ROW_H - 20), str(px), font=F_TAG, fill=C_DIM)
        cx += px + 14


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    entries = list(csv.DictReader(open(INDEX), delimiter="\t"))
    n_sheets = (len(entries) + ROWS_PER_SHEET - 1) // ROWS_PER_SHEET
    width = LABEL_W + 2 * (GROUP_W + 40) + 280
    for s in range(n_sheets):
        chunk = entries[s * ROWS_PER_SHEET:(s + 1) * ROWS_PER_SHEET]
        H = HEADER_H + ROWS_PER_SHEET * ROW_H
        canvas = Image.new("RGB", (width, H), C_BG)
        draw = ImageDraw.Draw(canvas)
        draw.rectangle([0, 0, width, HEADER_H - 2], fill=(12, 14, 18), outline=C_GRID)
        draw.text((14, 10),
                  f"D2 batch compile - sheet {s + 1}/{n_sheets}: "
                  "B1 (round 1) vs B2 (round 2) vs B3 (round 3)",
                  font=F_TITLE, fill=C_TEXT)
        draw.text((14, 42),
                  "Pick per icon which batch to keep (or none). 16/24/48 px are the "
                  "play sizes; B3 adds the 96 px detail reference.",
                  font=F_TAG, fill=C_DIM)
        draw.text((14, 62),
                  "B1: detailed but fine parts dissolve in play.  B2: legible but crude, "
                  "style drifts.  B3: in-between - one shared style, 4u floor, "
                  "12-28u signature feature, subject stays readable.",
                  font=F_TAG, fill=C_DIM)
        for i, e in enumerate(chunk):
            y = HEADER_H + i * ROW_H
            draw.rectangle([0, y, width - 1, y + ROW_H - 1], outline=C_GRID)
            draw.text((10, y + 12), f"#{e['id']} {e['name']}", font=F_NAME, fill=C_TEXT)
            draw.text((10, y + 34), e["family"], font=F_TAG, fill=C_DIM)
            draw.text((10, y + 62), "keep:  B1 / B2 / B3 / none", font=F_TAG, fill=C_DIM)
            gx = LABEL_W
            for label, folder, colour in BATCHES:
                draw_group(canvas, draw, gx, y, os.path.join(folder, e["name"] + ".svg"),
                           label, colour, with_detail=(label == "B3"))
                gx += (GROUP_W + 40) if label != "B3" else 0
        out = os.path.join(OUT_DIR, f"D2_COMPARE_{s + 1:02d}.png")
        canvas.save(out)
        chk = os.path.join(OUT_DIR, f"_check_{s + 1:02d}.jpg")
        canvas.resize((width // 2, H // 2)).save(chk, quality=58, optimize=True)
        print(out, os.path.getsize(out), "|", chk, os.path.getsize(chk))


if __name__ == "__main__":
    main()
