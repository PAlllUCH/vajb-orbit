"""Contact sheets of the gathered originals, one per family.

Whole 2K sheets are downscaled into a labelled grid so the library can be browsed
without opening 163 files by hand. Superseded runs are marked in the caption.

Usage:
    py -3.14 staging/review/build_originals_sheet.py [--tag o1] [--cell 300] [--cols 5]
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
OUT = WORKSPACE / "staging" / "review" / "_preview"
FAMILIES = ("ships", "env", "fx", "ui", "icons")


def load_font(size: int) -> ImageFont.ImageFont:
    for name in ("consola.ttf", "arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="o1")
    ap.add_argument("--cell", type=int, default=300)
    ap.add_argument("--cols", type=int, default=5)
    args = ap.parse_args()

    manifest = json.loads((LIBRARY / "_originals_manifest.json").read_text(encoding="utf-8"))
    superseded = {f["name"] for r in manifest["runs"] for f in r["files"]
                  if r["superseded_by"] and f["role"] == "raw"}

    font = load_font(13)
    small = load_font(11)
    pad, caption = 8, 28

    for family in FAMILIES:
        raws = sorted((LIBRARY / family).glob("*__raw.png"))
        if not raws:
            continue
        rows = (len(raws) + args.cols - 1) // args.cols
        cell = args.cell
        canvas = Image.new("RGB", (args.cols * (cell + pad) + pad,
                                  rows * (cell + caption + pad) + pad + 24), (16, 17, 20))
        draw = ImageDraw.Draw(canvas)
        draw.text((pad, 6), f"asset-library/{family} - {len(raws)} original sheets ({args.tag})",
                  fill=(210, 214, 220), font=font)
        for i, path in enumerate(raws):
            cx = pad + (i % args.cols) * (cell + pad)
            cy = pad + 24 + (i // args.cols) * (cell + caption + pad)
            with Image.open(path) as im:
                im = im.convert("RGB")
                im.thumbnail((cell, cell), Image.LANCZOS)
                canvas.paste(im, (cx + (cell - im.size[0]) // 2, cy + (cell - im.size[1]) // 2))
            name = path.name[: -len("__raw.png")]
            if len(name) > 34:
                name = name[:33] + "\u2026"
            draw.text((cx + 2, cy + cell + 2), name, fill=(226, 230, 236), font=small)
            if path.name in superseded:
                draw.text((cx + 2, cy + cell + 15), "superseded run", fill=(210, 120, 90), font=small)
        dest = OUT / f"originals_{args.tag}_{family}.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(dest, optimize=True)
        canvas.convert("RGB").save(dest.with_suffix(".jpg"), quality=74, optimize=True)
        print(f"{dest.name}  {canvas.size[0]}x{canvas.size[1]}  ({len(raws)} sheets)")


if __name__ == "__main__":
    main()
