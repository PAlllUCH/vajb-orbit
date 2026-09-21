"""Review sheet for the 2026-09-21 FX additions: the two regenerated sheets and the mine.

    page 1  fx_mining_beam_v2's four frames, as they ship (RGB on void black)
    page 2  fx_laser_bolt_v2's two frames, same
    page 3  the mine: the render, the keyed cut on magenta, and its alpha

The frames are shown on void black because that is how they ship (FX_SPEC section 0.1: the
additive effects stay RGB); the mine is shown on magenta because it is the one new file that
carries alpha (a solid object cannot be drawn additively).

Usage: py -3.14 staging/cut/build_fx_new_sheet.py --out staging/cut/_fx_review
"""
from __future__ import annotations

import argparse
import glob
from pathlib import Path

from PIL import Image, ImageDraw

FRAMES = Path(__file__).resolve().parents[2] / "staging" / "cut" / "_fx_frames"
SIDE = 240


def strip(paths: list[Path], label: str) -> Image.Image:
    tiles = []
    for path in paths:
        image = Image.open(path).convert("RGB")
        ratio = min(SIDE / image.width, SIDE / image.height, 1.0)
        tiles.append((path.stem, image.resize(
            (max(1, int(image.width * ratio)), max(1, int(image.height * ratio))),
            Image.LANCZOS)))
    head = 30
    width = sum(t[1].width + 6 for t in tiles) + 6
    height = max(t[1].height for t in tiles) + head
    page = Image.new("RGB", (width, height), (12, 12, 12))
    draw = ImageDraw.Draw(page)
    draw.text((6, 6), label, fill=(150, 230, 150))
    x = 6
    for name, tile in tiles:
        page.paste(tile, (x, head + (max(t[1].height for t in tiles) - tile.height) // 2))
        draw.text((x + 4, head - 12), name, fill=(215, 215, 215))
        x += tile.width + 6
    return page


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="staging/cut/_fx_review")
    parser.add_argument("--tag", default="fx_new")
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    pages = []
    for folder, label in (("fx_mining_beam_v2", "fx_mining_beam_v2 -> fx_mining_beam_f1..f4 "
                                               "(FX_SPEC 1.6: 4-frame chip sparks)"),
                          ("fx_laser_bolt_v2", "fx_laser_bolt_v2 -> fx_laser_bolt_f1/f2 "
                                               "(FX_SPEC 1.1: light + medium)")):
        paths = [Path(p) for p in sorted(glob.glob(str(FRAMES / folder / "*.png")))]
        if paths:
            page = strip(paths, label)
            target = out / f"{args.tag}_{folder}.jpg"
            page.save(target, quality=88)
            pages.append(target)

    source = Path("staging/phase_g/fx/fx_mine.png")
    keyed = Path("staging/phase_g/fx/fx_mine_final.png")
    if source.is_file() and keyed.is_file():
        render = Image.open(source).convert("RGB").resize((SIDE, SIDE), Image.LANCZOS)
        cut = Image.open(keyed).convert("RGBA")
        ratio = min(SIDE / cut.width, SIDE / cut.height, 1.0)
        size = (max(1, int(cut.width * ratio)), max(1, int(cut.height * ratio)))
        cut = cut.resize(size, Image.LANCZOS)
        magenta = Image.new("RGB", size, (255, 0, 255))
        magenta.paste(cut, (0, 0), cut)
        alpha = Image.merge("RGB", (cut.getchannel("A"),) * 3)
        head = 30
        page = Image.new("RGB", (SIDE * 3 + 20, SIDE + head), (12, 12, 12))
        draw = ImageDraw.Draw(page)
        draw.text((6, 6), "fx_mine (new object sprite, alpha-keyed: additive would erase "
                          "its dark hull)", fill=(150, 230, 150))
        for index, (name, tile) in enumerate((("source (void)", render),
                                              ("keyed (magenta=alpha 0)", magenta),
                                              ("alpha", alpha))):
            page.paste(tile, (6 + index * (SIDE + 6), head), tile if tile.mode == "RGBA" else None)
            draw.text((10 + index * (SIDE + 6), head - 12), name, fill=(215, 215, 215))
        target = out / f"{args.tag}_fx_mine.jpg"
        page.save(target, quality=88)
        pages.append(target)

    if pages:
        width = max(Image.open(p).width for p in pages)
        height = sum(Image.open(p).height for p in pages) + 6 * (len(pages) - 1)
        combined = Image.new("RGB", (width, height), (8, 8, 8))
        y = 0
        for path in pages:
            page = Image.open(path)
            combined.paste(page, (0, y))
            y += page.height + 6
        final = out / f"{args.tag}_all.jpg"
        combined.save(final, quality=86)
        print(f"pages: {[str(p) for p in pages]}")
        print(f"combined: {final}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
