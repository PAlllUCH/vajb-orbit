"""One review row per pane: its frames, as they will ship, on magenta.

Magenta is the background because a transparent frame and a void-black one look identical on a
black page. Each row is one sheet's frames in order, so a wrong cut (a frame missing its tail, a
frame holding a neighbour's sparks, a frame that is only grain) is visible at a glance. The sheet
name and the route that keyed it are printed on the row.

Usage:
    py -3.14 staging/cut/build_fx_pane_sheet.py --scope staging/cut/_fx_cycles \
        --out staging/cut/_fx_review --tag cycles
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

SIDE = 190
MAGENTA = (255, 0, 255)


def row(folder: Path) -> Image.Image | None:
    files = sorted(p for p in folder.glob("*.png") if not p.stem.endswith("-keyed"))
    if not files:
        return None
    tiles = []
    for path in files:
        keyed = path.with_name(f"{path.stem}-keyed.png")
        source = Image.open(keyed if keyed.exists() else path).convert("RGBA")
        ratio = min(SIDE / source.width, SIDE / source.height, 1.0)
        size = (max(1, int(source.width * ratio)), max(1, int(source.height * ratio)))
        tile = source.resize(size, Image.LANCZOS)
        board = Image.new("RGB", size, MAGENTA)
        board.paste(tile, (0, 0), tile)
        tiles.append((path.stem, board))
    head = 26
    width = sum(t[1].width + 6 for t in tiles) + 6
    height = max(t[1].height for t in tiles) + head
    page = Image.new("RGB", (width, height), (12, 12, 12))
    draw = ImageDraw.Draw(page)
    draw.text((6, 6), folder.name, fill=(150, 230, 150))
    x = 6
    for name, tile in tiles:
        page.paste(tile, (x, head + (max(t[1].height for t in tiles) - tile.height) // 2))
        draw.text((x + 4, head - 11), name, fill=(210, 210, 210))
        x += tile.width + 6
    return page


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", action="append", default=[])
    parser.add_argument("--out", default="staging/cut/_fx_review")
    parser.add_argument("--tag", default="panes")
    parser.add_argument("--group", type=int, default=8, help="rows per combined page")
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    folders = []
    for scope in args.scope:
        folders += sorted(p for p in Path(scope).iterdir() if p.is_dir())

    pages = []
    for folder in folders:
        page = row(folder)
        if page is None:
            continue
        target = out / f"{args.tag}_{folder.name}.jpg"
        page.save(target, quality=88)
        pages.append(target)

    for index in range(0, len(pages), args.group):
        chunk = pages[index:index + args.group]
        width = max(Image.open(p).width for p in chunk)
        height = sum(Image.open(p).height for p in chunk) + 6 * (len(chunk) - 1)
        combined = Image.new("RGB", (width, height), (8, 8, 8))
        y = 0
        for path in chunk:
            page = Image.open(path)
            combined.paste(page, (0, y))
            y += page.height + 6
        final = out / f"{args.tag}_page{index // args.group + 1}.jpg"
        combined.save(final, quality=86)
        print(f"{final}  {len(chunk)} row(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
