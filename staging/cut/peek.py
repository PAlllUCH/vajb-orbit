"""Build a labelled contact sheet of named assets, small enough to look at directly.

Every description in this library is written by a model or read from a prompt, and both can be
wrong about what is actually in the pixels. The only way to settle that is to look. This tool
turns any list of files into one JPEG tile grid, each tile labelled with the file stem and,
optionally, the subject a vision model claimed for it, so a mismatch is visible in a single
glance. Output is kept under a size limit because a viewer will refuse a larger image; when the
list will not fit in one sheet it is split into numbered pages.

Usage:
    py -3.14 staging/cut/peek.py --glob "raw/seamless*" --out _review/peek_haze.jpg
    py -3.14 staging/cut/peek.py --names raw/a.png,cut/b.png --labels vision
    py -3.14 staging/cut/peek.py --page 1 --cols 6 < list.txt
    py -3.14 staging/cut/peek.py --all-suspicious       # the files worth a second look

Lists come from `--names`, `--glob`, a file of one path per line on stdin, or one of the
built-in selections.
"""
from __future__ import annotations

import argparse
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
VISION = LIBRARY / "_vision.json"
REVIEW = LIBRARY / "_review"
LIMIT_BYTES = 200_000

# A sheet whose prompt forbids ships and hardware, in case the render ignored it.
ABSTRACT_SUSPECTS = (
    "raw/seamless-tileable-starfield-layer-a-fla.png",
    "raw/seamless-tileable-void-haze-layer-soft.png",
    "raw/seamless-tileable-foreground-dust-layer.png",
    "raw/seamless-tileable-void-haze-texture-abs.png",
    "raw/seamless-repeating-pattern-wallpaper-tex.png",
    "raw/deep-space-nebula-veil-a-single-square.png",
    "raw/full-screen-vignette-burnt-ember-c8461.png",
    "raw/single-thin-horizontal-ember-streak-bur.png",
    "raw/small-radial-ember-glow-orb-soft-radial.png",
    "raw/single-small-energy-ring-burnt-ember-c__20260917-183628.png",
    "raw/mining-base-structure-a-station-scale-i.png",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111724.png",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111829.png",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111927.png",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-112053.png",
    "raw/body_ice_moon.png",
    "raw/f1_ice_moon.png",
    "raw/logo-vajb-orbit-the-word-vajb-orbit-as.png",
)
SUSPICIOUS = ABSTRACT_SUSPECTS


def vision() -> dict:
    if not VISION.exists():
        return {}
    return json.loads(VISION.read_text(encoding="utf-8")).get("files", {})


def label_for(rel: str, entry: dict | None, mode: str) -> list[str]:
    stem = Path(rel).stem
    if mode == "name" or not entry:
        return textwrap.wrap(stem, 34)[:2]
    if rel.startswith("raw/"):
        subject = entry.get("sheet_subject", "")
        objects = entry.get("objects") or []
        lines = [f"{stem[:20]}", f"{subject[:32]}"]
        if objects:
            lines.append(f"{len(objects)} obj: {', '.join(objects)[:36]}")
        return lines[:3]
    return [stem[:22], entry.get("subject", "")[:32], entry.get("kind", "")[:32]]


def tiles(paths: list[str], cols: int, tile: int, labels: str) -> Image.Image:
    entries = vision()
    rows = (len(paths) + cols - 1) // cols
    line = 12
    pad = 4
    cell_h = tile + line * 3 + pad
    sheet = Image.new("RGB", (cols * (tile + pad) + pad, rows * cell_h + pad), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    for index, rel in enumerate(paths):
        path = LIBRARY / rel
        if not path.exists():
            path = WORKSPACE / rel
        col, row = index % cols, index // cols
        x = pad + col * (tile + pad)
        y = pad + row * cell_h
        try:
            image = Image.open(path).convert("RGB")
        except Exception:
            draw.text((x + 2, y + 2), "unreadable", fill=(220, 80, 80))
            continue
        image.thumbnail((tile, tile))
        sheet.paste(image, (x + (tile - image.width) // 2, y + (tile - image.height) // 2))
        for i, text in enumerate(label_for(rel, entries.get(rel), labels)):
            draw.text((x + 1, y + tile + 2 + i * line), text, fill=(235, 235, 235))
    return sheet


def save(sheet: Image.Image, out: Path) -> None:
    quality = 86
    while quality > 40:
        sheet.save(out, "JPEG", quality=quality)
        if out.stat().st_size <= LIMIT_BYTES:
            break
        quality -= 8
    size = out.stat().st_size
    flag = "ok" if size <= LIMIT_BYTES else "STILL OVERSIZE"
    print(f"{out.relative_to(WORKSPACE)}  {sheet.width}x{sheet.height}  {size} bytes  {flag}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--names", default="", help="comma separated paths")
    parser.add_argument("--glob", default="", help="glob relative to asset-library")
    parser.add_argument("--all-suspicious", action="store_true")
    parser.add_argument("--labels", choices=("name", "vision"), default="vision")
    parser.add_argument("--cols", type=int, default=5)
    parser.add_argument("--tile", type=int, default=300)
    parser.add_argument("--per-page", type=int, default=20)
    parser.add_argument("--page", type=int, default=0, help="0 = every page")
    parser.add_argument("--out", default="")
    args = parser.parse_args()

    paths: list[str] = []
    if args.names:
        paths = [n.strip() for n in args.names.split(",") if n.strip()]
    elif args.glob:
        paths = sorted(str(p.relative_to(LIBRARY)).replace("\\", "/")
                       for p in LIBRARY.glob(args.glob, recursive=True))
    elif args.all_suspicious:
        paths = list(SUSPICIOUS)
    else:
        import sys
        paths = [line.strip() for line in sys.stdin if line.strip()]
    if not paths:
        raise SystemExit("no files selected")

    REVIEW.mkdir(parents=True, exist_ok=True)
    pages = [paths[i:i + args.per_page] for i in range(0, len(paths), args.per_page)]
    if args.out:
        save(tiles(paths, args.cols, args.tile, args.labels), WORKSPACE / args.out)
        return
    selected = pages if args.page == 0 else [pages[min(args.page, len(pages)) - 1]]
    for number, page in enumerate(selected, 1):
        out = REVIEW / f"peek_{number:02d}.jpg"
        save(tiles(page, args.cols, args.tile, args.labels), out)
    print(f"{len(paths)} file(s) in {len(pages)} page(s)")


if __name__ == "__main__":
    main()
