"""The owner-facing alpha review sheet: one page per FX, both keying routes side by side.

    source (void black)  |  recraft matte on magenta  |  luminance key on magenta

Magenta is what makes transparency visible - a transparent background and a black one look
identical on a black page. The two routes are the two the project owns: the paid matte
(`recraft/remove-background`, the route the library took for 407 sprites) and the local
luminance key (`key_luminance.py`, the route for art whose brightness *is* its opacity).

Usage:
    py -3.14 staging/cut/build_fx_alpha_sheet.py --scope staging/cut/_fx_key \
        --lum staging/cut/_fx_key/lum --out staging/cut/_fx_review
"""
from __future__ import annotations

import argparse
import glob
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SIDE = 300
MAGENTA = (255, 0, 255)


def crop_box(source: Image.Image, keyed: Image.Image) -> list[int]:
    gray = np.asarray(source.convert("L")).astype(np.float32)
    ring = np.concatenate([gray[:16].ravel(), gray[-16:].ravel(),
                           gray[:, :16].ravel(), gray[:, -16:].ravel()])
    mask = np.abs(gray - float(np.median(ring))) > 14
    alpha = np.asarray(keyed.convert("RGBA").getchannel("A")) > 8
    both = mask | alpha
    rows = np.where(both.any(axis=1))[0]
    cols = np.where(both.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return [0, 0, source.width, source.height]
    pad = 40
    return [max(0, int(cols[0]) - pad), max(0, int(rows[0]) - pad),
            min(source.width, int(cols[-1]) + pad), min(source.height, int(rows[-1]) + pad)]


def on_magenta(keyed: Image.Image, box: list[int], size: tuple[int, int]) -> Image.Image:
    panel = Image.new("RGB", (box[2] - box[0], box[3] - box[1]), MAGENTA)
    cut = keyed.convert("RGBA").crop(box)
    panel.paste(cut, (0, 0), cut)
    return panel.resize(size, Image.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", default="staging/cut/_fx_key")
    parser.add_argument("--lum", default="staging/cut/_fx_key/lum")
    parser.add_argument("--out", default="staging/cut/_fx_review")
    parser.add_argument("--tag", default="fx_alpha")
    args = parser.parse_args()

    rows = []
    for matte_path in sorted(glob.glob(str(Path(args.scope) / "*-keyed.png"))):
        matte = Path(matte_path)
        name = matte.name.replace("-keyed.png", "")
        source_path = matte.with_name(f"{name}.png")
        lum_path = Path(args.lum) / matte.name
        if not source_path.exists() or not lum_path.exists():
            continue
        source = Image.open(source_path).convert("RGB")
        matte_img = Image.open(matte).convert("RGBA")
        lum_img = Image.open(lum_path).convert("RGBA")
        box = crop_box(source, matte_img)
        ratio = min(SIDE / (box[2] - box[0]), SIDE / (box[3] - box[1]), 1.0)
        size = (max(1, int((box[2] - box[0]) * ratio)), max(1, int((box[3] - box[1]) * ratio)))
        panels = [("source (void black)", source.crop(box).resize(size, Image.LANCZOS)),
                  ("recraft matte", on_magenta(matte_img, box, size)),
                  ("luminance key", on_magenta(lum_img, box, size))]
        head = 24
        page = Image.new("RGB", (size[0] * 3 + 8, size[1] + head), (16, 16, 16))
        for index, (label, panel) in enumerate(panels):
            page.paste(panel, (index * (size[0] + 4), head))
        draw = ImageDraw.Draw(page)
        for index, (label, _) in enumerate(panels):
            draw.text((index * (size[0] + 4) + 6, 6), label, fill=(225, 225, 225))
        draw.text((4, head + 4), name, fill=(120, 200, 120))
        out = Path(args.out) / f"{args.tag}_{name}.jpg"
        out.parent.mkdir(parents=True, exist_ok=True)
        page.save(out, quality=88)
        rows.append({"name": name, "page": str(out), "box": box})

    stacked = Image.new("RGB", (max(Image.open(r["page"]).width for r in rows),
                                 sum(Image.open(r["page"]).height for r in rows)),
                        (10, 10, 10))
    y = 0
    for row in rows:
        page = Image.open(row["page"])
        stacked.paste(page, (0, y))
        y += page.height
    combined = Path(args.out) / f"{args.tag}_all.jpg"
    stacked.save(combined, quality=86)
    print(json.dumps({"pages": rows, "combined": str(combined)}, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
