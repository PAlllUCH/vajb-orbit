"""The deploy sheet: source | the route chosen for that file (on magenta) | its alpha.

One page per file, and the page names the route that was chosen for it in the header, so the
sheet is the record of the decision as well as the picture of the result. Magenta is the
background because transparency is invisible on a black panel.

Usage:
    py -3.14 staging/cut/build_fx_deploy_sheet.py --scope staging/cut/_fx_ship \
        --out staging/cut/_fx_review --tag fx_deploy
"""
from __future__ import annotations

import argparse
import glob
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SIDE = 320
MAGENTA = (255, 0, 255)
## Which route each file shipped on, with the measurement that decided it.
ROUTES = {
    "fx_acid_burn": "recraft matte (matte keeps the bright wisps; luminance graded the mist "
                    "away and read as 'holes' to the vision check)",
    "fx_smoke_plume": "recraft matte (smoke opacity follows density, not brightness: the "
                      "luminance key thinned the body to 14 enclosed gaps)",
    "fx_dust_streak": "recraft matte (both routes pass; the matte's cut is tighter)",
    "fx_hull_critical_vignette": "luminance key (the matte kept 99.7% of the frame and left the "
                                 "centre black; FX_SPEC 1.8 wants the centre fully transparent)",
}


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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", default="staging/cut/_fx_ship")
    parser.add_argument("--out", default="staging/cut/_fx_review")
    parser.add_argument("--tag", default="fx_deploy")
    args = parser.parse_args()

    pages = []
    for keyed_path in sorted(glob.glob(str(Path(args.scope) / "*-keyed.png"))):
        keyed_path = Path(keyed_path)
        name = keyed_path.name.replace("-keyed.png", "")
        source_path = keyed_path.with_name(f"{name}.png")
        source = Image.open(source_path).convert("RGB")
        keyed = Image.open(keyed_path).convert("RGBA")
        box = crop_box(source, keyed)
        ratio = min(SIDE / (box[2] - box[0]), SIDE / (box[3] - box[1]), 1.0)
        size = (max(1, int((box[2] - box[0]) * ratio)), max(1, int((box[3] - box[1]) * ratio)))

        magenta = Image.new("RGB", (box[2] - box[0], box[3] - box[1]), MAGENTA)
        cut = keyed.crop(box)
        magenta.paste(cut, (0, 0), cut)
        alpha = Image.merge("RGB", (cut.getchannel("A"),) * 3)

        panels = [("source (void black)", source.crop(box).resize(size, Image.LANCZOS)),
                  (ROUTES.get(name, "keyed").split(" (")[0], magenta.resize(size, Image.LANCZOS)),
                  ("alpha", alpha.resize(size, Image.LANCZOS))]
        head = 40
        page = Image.new("RGB", (size[0] * 3 + 8, size[1] + head), (16, 16, 16))
        for index, (_, panel) in enumerate(panels):
            page.paste(panel, (index * (size[0] + 4), head))
        draw = ImageDraw.Draw(page)
        draw.text((6, 5), f"{name}  -  {ROUTES.get(name, '')}"[:150], fill=(150, 230, 150))
        for index, (label, _) in enumerate(panels):
            draw.text((index * (size[0] + 4) + 6, head - 14), label, fill=(220, 220, 220))
        page_path = Path(args.out) / f"{args.tag}_{name}.jpg"
        page_path.parent.mkdir(parents=True, exist_ok=True)
        page.save(page_path, quality=88)
        pages.append(page_path)

    width = max(Image.open(p).width for p in pages)
    height = sum(Image.open(p).height for p in pages)
    stacked = Image.new("RGB", (width, height), (10, 10, 10))
    y = 0
    for page_path in pages:
        page = Image.open(page_path)
        stacked.paste(page, (0, y))
        y += page.height
    combined = Path(args.out) / f"{args.tag}_all.jpg"
    stacked.save(combined, quality=86)
    print(json.dumps({"pages": [str(p) for p in pages], "combined": str(combined)}, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
