"""Build the graphics-review contact sheets from staging/review/alpha_qc.json.

Two panels per flagged asset: the sprite as shipped, and the same sprite with
every enclosed transparent region tinted magenta. Small sprites are magnified
so a 1 px hole is still visible on the sheet.

Usage:
    py -3.14 staging/review/build_review_sheet.py [--family ships] [--tag r1]
                                                  [--cell 220] [--cols 4]
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

WORKSPACE = Path(__file__).resolve().parents[2]
REVIEW = WORKSPACE / "staging" / "review"
OUT = REVIEW / "_preview"

TINT = (255, 0, 128)


def load_font(size: int) -> ImageFont.ImageFont:
    for name in ("consola.ttf", "arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def hole_mask(path: Path) -> np.ndarray:
    im = Image.open(path).convert("RGBA")
    a = np.array(im.getchannel("A"))
    op = a > 128
    trans = ~op
    labels, _ = ndimage.label(trans)
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    return trans & ~np.isin(labels, list(border)) if border else trans


def thumb(path: Path, box: int, tint: bool) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    if tint:
        holes = hole_mask(path)
        if holes.any():
            rgb = np.array(im)
            rgb[holes] = [*TINT, 255]
            im = Image.fromarray(rgb)
    # checkerboard so transparent regions read as transparent
    scale = min(box / im.size[0], box / im.size[1])
    if scale > 1:
        scale = min(scale, 3.0)  # magnify small sprites, but not absurdly
    size = (max(1, round(im.size[0] * scale)), max(1, round(im.size[1] * scale)))
    im = im.resize(size, Image.LANCZOS if scale < 1 else Image.NEAREST)
    board = Image.new("RGBA", size, (26, 28, 32, 255))
    step = 8
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2:
                board.paste((38, 41, 47, 255), (x, y, min(x + step, size[0]), min(y + step, size[1])))
    board.alpha_composite(im)
    return board.convert("RGB")


def sheet(rows: list[dict], cols: int, cell: int, dest: Path, title: str) -> None:
    font = load_font(13)
    small = load_font(11)
    label_h = 30
    pad = 8
    row_h = cell + label_h + pad
    w = cols * (cell + pad) + pad
    h = ((len(rows) + cols - 1) // cols) * row_h + pad + 24
    canvas = Image.new("RGB", (w, h), (16, 17, 20))
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 6), title, fill=(210, 214, 220), font=font)

    for i, r in enumerate(rows):
        cx = pad + (i % cols) * (cell + pad)
        cy = pad + 24 + (i // cols) * row_h
        for j, tint in enumerate((False, True)):
            t = thumb(Path(r["path"]), cell // 2 - 2, tint)
            ox = cx + j * (cell // 2) + (cell // 2 - t.size[0]) // 2
            oy = cy + (cell - t.size[1]) // 2
            canvas.paste(t, (ox, oy))
        name = r["name"].rsplit(".", 1)[0]
        if len(name) > 30:
            name = name[:29] + "\u2026"
        draw.text((cx + 2, cy + cell + 2), name, fill=(226, 230, 236), font=small)
        draw.text(
            (cx + 2, cy + cell + 15),
            f"{r['hole_pct_of_silhouette']:.1f}% in {r['hole_blobs']} blobs",
            fill=TINT,
            font=small,
        )

    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest, optimize=True)
    print(f"{dest}  {canvas.size[0]}x{canvas.size[1]}  ({len(rows)} assets)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", default=str(REVIEW / "alpha_qc.json"))
    ap.add_argument("--family", default="")
    ap.add_argument("--tag", default="r1")
    ap.add_argument("--cell", type=int, default=220)
    ap.add_argument("--cols", type=int, default=4)
    args = ap.parse_args()

    data = json.loads(Path(args.json).read_text(encoding="utf-8"))
    rows = [r for r in data["rows"] if r["flag"]]
    families = [args.family] if args.family else sorted({r["family"] for r in rows})

    for fam in families:
        fam_rows = [r for r in rows if r["family"] == fam]
        if not fam_rows:
            continue
        # worst first, but chunk so a sheet stays legible
        fam_rows.sort(key=lambda r: -r["hole_pct_of_silhouette"])
        per_sheet = args.cols * 5
        for n in range(0, len(fam_rows), per_sheet):
            chunk = fam_rows[n : n + per_sheet]
            part = "" if len(fam_rows) <= per_sheet else f"-{n // per_sheet + 1}"
            title = (f"{fam}{part}  -  left: as shipped   right: enclosed transparent regions in magenta"
                     f"  ({args.tag})")
            sheet(chunk, args.cols, args.cell, OUT / f"review_{args.tag}_{fam}{part}.png", title)


if __name__ == "__main__":
    main()
