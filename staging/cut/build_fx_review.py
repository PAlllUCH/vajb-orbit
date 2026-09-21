"""Build the alpha review sheet for the FX that must be transparent.

One page per file, three reads side by side, cropped to the union of the source's ink box and
the keyed alpha box so a small effect is not a speck on a 2048 px page:

    source on void black   |   keyed on a checkerboard   |   keyed alpha, greyscale

The checkerboard is what proves transparency (a black background and a transparent one look
identical on a black page) and the alpha read is what shows a hole punched inside the
silhouette. Measurements are printed beside the run, from `qc_fx_alpha.measure`.

Usage:
    py -3.14 staging/cut/build_fx_review.py --scope staging/cut/_fx_key --out staging/cut/_fx_review
"""
from __future__ import annotations

import argparse
import glob
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CHECK = 32


def checkerboard(size: tuple[int, int], tint: int = 90) -> Image.Image:
    board = Image.new("RGB", size, (tint, tint, tint))
    draw = ImageDraw.Draw(board)
    for y in range(0, size[1], CHECK):
        for x in range(0, size[0], CHECK):
            if (x // CHECK + y // CHECK) % 2:
                draw.rectangle([x, y, x + CHECK - 1, y + CHECK - 1], fill=(tint + 55,) * 3)
    return board


def union_box(source: Image.Image, keyed: Image.Image) -> list[int]:
    ink = np.asarray(source.convert("L")).astype(np.float32)
    alpha = np.asarray(keyed.convert("RGBA").getchannel("A"))
    rows = np.where((np.abs(ink - np.median(np.concatenate(
        [ink[:16].ravel(), ink[-16:].ravel()]))) > 10).any(axis=1))[0]
    cols = np.where((np.abs(ink - np.median(np.concatenate(
        [ink[:16].ravel(), ink[-16:].ravel()]))) > 10).any(axis=0))[0]
    if len(rows) and len(cols):
        ink_box = [int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1]
    else:
        ink_box = [0, 0, source.width, source.height]
    ar = np.where((alpha > 8).any(axis=1))[0]
    ac = np.where((alpha > 8).any(axis=0))[0]
    if len(ar) and len(ac):
        alpha_box = [int(ac[0]), int(ar[0]), int(ac[-1]) + 1, int(ar[-1]) + 1]
    else:
        alpha_box = ink_box
    pad = 48
    return [max(0, min(ink_box[0], alpha_box[0]) - pad),
            max(0, min(ink_box[1], alpha_box[1]) - pad),
            min(source.width, max(ink_box[2], alpha_box[2]) + pad),
            min(source.height, max(ink_box[3], alpha_box[3]) + pad)]


def page(source_path: Path, keyed_path: Path, out: Path, side: int = 460) -> dict:
    source = Image.open(source_path).convert("RGB")
    keyed = Image.open(keyed_path).convert("RGBA")
    box = union_box(source, keyed)
    crop_source = source.crop(box)
    crop_keyed = keyed.crop(box)
    ratio = min(side / crop_source.width, side / crop_source.height, 1.0)
    size = (max(1, int(crop_source.width * ratio)), max(1, int(crop_source.height * ratio)))
    crop_source = crop_source.resize(size, Image.LANCZOS)
    crop_keyed = crop_keyed.resize(size, Image.LANCZOS)

    board = checkerboard(size)
    board.paste(crop_keyed, (0, 0), crop_keyed)
    alpha = Image.new("RGB", size, (0, 0, 0))
    alpha.paste(Image.merge("RGB", (crop_keyed.getchannel("A"),) * 3), (0, 0))

    head = 26
    sheet = Image.new("RGB", (size[0] * 3 + 8, size[1] + head), (18, 18, 18))
    for index, panel in enumerate((crop_source, board, alpha)):
        sheet.paste(panel, (index * (size[0] + 4), head))
    draw = ImageDraw.Draw(sheet)
    for index, label in enumerate(("source (void)", "keyed (alpha)", "keyed (A)")):
        draw.text((index * (size[0] + 4) + 6, 7), label, fill=(200, 200, 200))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=88)
    return {"file": out.name, "page": str(out), "box": box, "panel": list(size)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", default="")
    parser.add_argument("--out", default="staging/cut/_fx_review")
    args = parser.parse_args()
    pairs: list[tuple[Path, Path]] = []
    for keyed in sorted(glob.glob(str(Path(args.scope) / "*-keyed.png"))):
        keyed_path = Path(keyed)
        source = keyed_path.with_name(keyed_path.name.replace("-keyed.png", ".png"))
        if source.exists():
            pairs.append((source, keyed_path))
    if not pairs:
        print("nothing to review: pass --scope <dir>")
        return 1
    for source, keyed in pairs:
        info = page(source, keyed, Path(args.out) / f"{source.stem}_alpha.jpg")
        print(f"   {info['file']}  crop={info['box']}  panel={info['panel']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
