#!/usr/bin/env python3
"""Build the D2 Phase B review sheet: every SVG at 16/24/48/96/192 side by side.

Run under the uv ephemeral env (needs cairosvg):

    uv run --with cairosvg python3 staging/d2/build_svg_review.py

Output: staging/d2/review/D2_SVG_REVIEW_NN.png (3 symbols per row, 9 rows per
sheet) plus a half-scale JPEG check copy per sheet for quick viewing.
"""

import csv
import os
import sys

import cairosvg
from PIL import Image, ImageDraw, ImageFont

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
SVG_DIR = os.path.join(WORKSPACE, "staging/d2/svg")
OUT_DIR = os.path.join(WORKSPACE, "staging/d2/review")
INDEX = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")

SIZES = [16, 24, 48, 96, 192]
CELL_W, ROW_H = 740, 232
COLS, ROWS = 3, 9
HEADER_H = 86
LABEL_W = 250

C_BG = (21, 24, 29)
C_GRID = (58, 66, 76)
C_TEXT = (222, 226, 232)
C_DIM = (150, 158, 168)


def _font(size, bold=False):
    p = "/usr/share/fonts/truetype/dejavu/DejaVuSans" + ("-Bold" if bold else "") + ".ttf"
    return ImageFont.truetype(p, size)


F_TITLE = _font(22, bold=True)
F_NAME = _font(16, bold=True)
F_TAG = _font(14)


def render_svg(path, px):
    png = cairosvg.svg2png(url=path, output_width=px, output_height=px)
    import io
    return Image.open(io.BytesIO(png)).convert("RGBA")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    entries = list(csv.DictReader(open(INDEX), delimiter="\t"))
    n_sheets = (len(entries) + COLS * ROWS - 1) // (COLS * ROWS)
    for s in range(n_sheets):
        chunk = entries[s * COLS * ROWS:(s + 1) * COLS * ROWS]
        W = COLS * CELL_W
        H = HEADER_H + ROWS * ROW_H
        canvas = Image.new("RGB", (W, H), C_BG)
        draw = ImageDraw.Draw(canvas)
        draw.rectangle([0, 0, W, HEADER_H - 2], fill=(12, 14, 18), outline=C_GRID)
        draw.text((14, 10),
                  f"D2 SVG review - sheet {s + 1}/{n_sheets}   scaling proof 16/24/48/96/192",
                  font=F_TITLE, fill=C_TEXT)
        draw.text((14, 44),
                  "Flat fills only, 96 grid, two tones max. Column order per symbol: "
                  "16 | 24 | 48 | 96 | 192 px renders.",
                  font=F_TAG, fill=C_DIM)
        for i, e in enumerate(chunk):
            r, c = divmod(i, COLS)
            x0 = c * CELL_W
            y0 = HEADER_H + r * ROW_H
            draw.rectangle([x0, y0, x0 + CELL_W - 1, y0 + ROW_H - 1], outline=C_GRID)
            svg = os.path.join(SVG_DIR, e["name"] + ".svg")
            draw.text((x0 + 12, y0 + 10), f"#{e['id']} {e['name']}", font=F_NAME, fill=C_TEXT)
            draw.text((x0 + 12, y0 + 32), e["family"], font=F_TAG, fill=C_DIM)
            if not os.path.exists(svg):
                draw.text((x0 + 12, y0 + 60), "MISSING", font=F_NAME, fill=(255, 80, 80))
                continue
            x = x0 + LABEL_W
            for px in SIZES:
                im = render_svg(svg, px)
                y = y0 + 40 + (192 - px) // 2
                canvas.paste(im, (x, y), im)
                draw.text((x, y0 + ROW_H - 22), str(px), font=F_TAG, fill=C_DIM)
                x += px + 26
        out = os.path.join(OUT_DIR, f"D2_SVG_REVIEW_{s + 1:02d}.png")
        canvas.save(out)
        check = canvas.resize((W // 2, H // 2))
        chk = os.path.join(OUT_DIR, f"_check_{s + 1:02d}.jpg")
        check.save(chk, quality=55, optimize=True)
        print(out, os.path.getsize(out), "|", chk, os.path.getsize(chk))


if __name__ == "__main__":
    main()
