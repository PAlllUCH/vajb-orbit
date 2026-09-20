"""Build the review sheets for what the cutter produced.

Two artefacts per family, both written to asset-library/_review/:

  cutmap_<family>.jpg   every raw sheet at a legible size with the cut lines drawn and
                        each panel's name printed in it -- this is what says whether the
                        dividers landed on the gutters.
  cuts_<family>.jpg     a contact sheet of the cut sprites themselves.

Usage:
    py -3.14 staging/cut/build_review.py
    py -3.14 staging/cut/build_review.py --only bomber
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
MANIFEST = LIBRARY / "_cuts_manifest.json"
RAW = LIBRARY / "raw"
CUT = LIBRARY / "cut"
REVIEW = LIBRARY / "_review"

FONT = WORKSPACE / "vajb-orbit" / "assets" / "fonts" / "Rajdhani-SemiBold.ttf"
MAP_WIDTH = 512        # px per cut-map cell
MAP_COLUMNS = 4
THUMB = 192            # px per sprite thumbnail cell
THUMB_COLUMNS = 8
PAD = 6
BACKDROP = (14, 17, 22)
LINE = (232, 96, 46)
TEXT = (201, 205, 210)
LABEL = (141, 147, 155)


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT), size)
    except OSError:
        return ImageFont.load_default(size=size)


def cut_map(entry: dict, width: int = MAP_WIDTH) -> Image.Image:
    """The raw sheet, scaled, with the cut lines and panel names drawn on it."""
    sheet = Image.open(RAW / Path(entry["raw"]).name).convert("RGB")
    scale = width / sheet.width
    canvas = sheet.resize((width, max(1, round(sheet.height * scale))), Image.LANCZOS)
    draw = ImageDraw.Draw(canvas)
    label = font(max(11, round(width / 34)))
    small = font(max(9, round(width / 46)))

    for panel in entry["panels"]:
        left, top, right, bottom = (value * scale for value in panel["box"])
        draw.rectangle((left, top, right - 1, bottom - 1), outline=LINE, width=2)
        name = panel["name"]
        drawn = small if len(name) > 20 else label
        draw.text((left + 6, top + 4), name, font=drawn, fill=TEXT,
                  stroke_width=2, stroke_fill=(0, 0, 0))
    header = font(max(13, round(width / 26)))
    draw.text((8, canvas.height - round(width / 14)), 
              f"{Path(entry['raw']).stem}  {entry['grid'][0]}x{entry['grid'][1]}  "
              f"{entry['method']}  ratio {entry['divider_ink_ratio']}",
              font=header, fill=LABEL, stroke_width=2, stroke_fill=(0, 0, 0))
    return canvas


def contact(images: list[tuple[str, Image.Image]], columns: int, cell: int,
            label_size: int, family: str) -> Image.Image:
    """Lay named images out in a grid."""
    rows = (len(images) + columns - 1) // columns
    band = round(cell * 0.16) + 8
    sheet = Image.new("RGB", (columns * (cell + PAD) + PAD, rows * (cell + band + PAD) + PAD),
                      BACKDROP)
    draw = ImageDraw.Draw(sheet)
    caption = font(label_size)
    for index, (name, image) in enumerate(images):
        row, column = divmod(index, columns)
        x = PAD + column * (cell + PAD)
        y = PAD + row * (cell + band + PAD)
        sheet.paste(image, (x, y + band))
        draw.text((x + 3, y + 2), name[:44], font=caption, fill=TEXT)
    draw.text((PAD, sheet.height - label_size - 2), family, font=caption, fill=LABEL)
    return sheet


def save_capped(image: Image.Image, path: Path, limit: int = 190_000) -> Path:
    """Save a JPEG small enough to open in a chat viewer."""
    for _ in range(8):
        image.save(path, quality=76)
        if path.stat().st_size <= limit:
            return path
        image = image.resize((round(image.width * 0.75), round(image.height * 0.75)), Image.LANCZOS)
    return path


def scaled(image: Image.Image, cell: int) -> Image.Image:
    scale = min(cell / image.width, cell / image.height)
    return image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                        Image.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="", help="only sheets whose raw stem contains this")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    sheets = [s for s in manifest["sheets"] if args.only in s["raw"]]
    if not sheets:
        print(f"no sheet matches {args.only!r}")
        return 1
    REVIEW.mkdir(exist_ok=True)

    families: dict[str, list[dict]] = {}
    for entry in sheets:
        families.setdefault(entry["family"], []).append(entry)

    for family, entries in sorted(families.items()):
        maps = [(Path(entry["raw"]).stem, cut_map(entry)) for entry in entries]
        height = max(image.height for _, image in maps)
        maps = [(name, image if image.height == height else image.resize(
            (round(image.width * height / image.height), height), Image.LANCZOS))
            for name, image in maps]
        contact(maps, MAP_COLUMNS, MAP_WIDTH, 13, f"{family} - cut maps").save(
            REVIEW / f"cutmap_{family}.jpg", quality=88)

        # The per-family sheet is too big to open in a chat viewer; keep a tile per row of
        # four sheets so single rows can be inspected directly.
        for index in range(0, len(maps), MAP_COLUMNS):
            row = maps[index:index + MAP_COLUMNS]
            height = max(image.height for _, image in row)
            padded = [(name, image if image.height == height else image.resize(
                (round(image.width * height / image.height), height), Image.LANCZOS))
                for name, image in row]
            save_capped(contact(padded, MAP_COLUMNS, MAP_WIDTH, 13, f"{family} cut maps"),
                        REVIEW / f"tile_{family}_{index // MAP_COLUMNS + 1:03d}.jpg",
                        limit=100_000)

        sprites = []
        for entry in entries:
            for panel in entry["panels"]:
                name = panel["name"]
                sprites.append((name, scaled(Image.open(CUT / f"{name}.png").convert("RGB"), THUMB)))
        for name in [n for entry in entries for n in entry["master"]]:
            sprites.append((name, scaled(Image.open(CUT / f"{name}.png").convert("RGB"), THUMB)))
        contact(sprites, THUMB_COLUMNS, THUMB, 11, f"{family} - {len(sprites)} cut sprite(s)").save(
            REVIEW / f"cuts_{family}.jpg", quality=88)
        for index in range(0, len(sprites), THUMB_COLUMNS * 2):
            save_capped(contact(sprites[index:index + THUMB_COLUMNS * 2], THUMB_COLUMNS, THUMB, 11,
                                family), REVIEW / f"cuts_{family}_{index // (THUMB_COLUMNS * 2) + 1:03d}.jpg")
        print(f"{family:6} {len(entries):3} sheet(s)  {len(sprites):4} sprite(s)  "
              f"-> {REVIEW.name}/cutmap_{family}.jpg, cuts_{family}.jpg")

    print(f"review sheets in {REVIEW}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
