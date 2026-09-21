"""Phase G recovery - the integrity check every cut passes before a review sheet.

The owner's verification rule (2026-09-21): every shipped cut gets a model-vision
integrity check - contact sheet plus measure - before it reaches the owner: ink box
against the expected plate box, no whole-cell cuts, no 90 %-transparent plates.

This tool produces both halves of that check:

  measure  per file, the exact canvas size against the expected box, the alpha>0 and
           alpha>=128 bounding boxes, the alpha mean and the solid/transparent shares.
           A cut passes when its canvas *is* the box, its ink fills that box, and it is
           mostly solid. A whole sheet cell fails the first two by a mile (the shipped
           slot cells are 880x876 with a 528x300 ink box at 90 % transparent).
  sheet    the same files drawn on a mid-grey/dark checkerboard at 3x with the expected
           box outlined, so a human or a model can see a gutter, a neighbouring cell's
           ink, a clipped plate or a plate that is missing its border.

The sheet is the artefact that gets looked at; the numbers are what the review sheets
quote. Both are written under staging/phase_f/_preview/.

Usage:
  py -3.14 staging/phase_f/qc_cuts.py --report staging/phase_f/recut_slots_report.json
  py -3.14 staging/phase_f/qc_cuts.py --dir staging/phase_f/ui --px ui_thing.png=48 \
        [--tag slots]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
OUT = STAGE / "_preview"
FONT_PATH = ROOT / "vajb-orbit" / "assets" / "fonts" / "Rajdhani-Medium.ttf"

VOID = (7, 9, 13)
INK = (201, 209, 220)
DIM = (107, 116, 132)
GOOD = (122, 196, 122)
BAD = (200, 71, 31)
EMBER = (232, 112, 58)

ZOOM = 3
BOX_TOLERANCE = 1          # px the ink box may fall short of the canvas
SOLID_MEAN = 180.0         # a plate is opaque; the failed cells measure ~20-40
SOLID_TRANSPARENT = 0.50   # the failed cells are 77-92 % transparent


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT_PATH), size)
    except OSError:
        return ImageFont.load_default(size)


def checkerboard(size: tuple[int, int], cell: int = 6) -> Image.Image:
    board = Image.new("RGB", size, (38, 42, 50))
    draw = ImageDraw.Draw(board)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle([x, y, x + cell - 1, y + cell - 1], fill=(58, 63, 72))
    return board


def measure(path: Path, box: int) -> dict:
    image = Image.open(path).convert("RGBA")
    alpha = np.asarray(image)[..., 3]
    total = alpha.size
    ink = np.nonzero(alpha > 0)
    core = np.nonzero(alpha >= 128)
    ink_box = (None if not len(ink[0]) else
               [int(ink[1].min()), int(ink[0].min()),
                int(ink[1].max()) + 1, int(ink[0].max()) + 1])
    transparent = float((alpha == 0).mean())
    fills = (image.width == box and image.height == box and ink_box is not None
             and ink_box[0] <= BOX_TOLERANCE and ink_box[1] <= BOX_TOLERANCE
             and ink_box[2] >= box - BOX_TOLERANCE and ink_box[3] >= box - BOX_TOLERANCE)
    solid = transparent <= SOLID_TRANSPARENT and float(alpha.mean()) >= SOLID_MEAN
    return {
        "name": path.name,
        "canvas": [image.width, image.height],
        "expected_box": box,
        "ink_box": ink_box,
        "core_box": (None if not len(core[0]) else
                     [int(core[1].min()), int(core[0].min()),
                      int(core[1].max()) + 1, int(core[0].max()) + 1]),
        "alpha_mean": round(float(alpha.mean()), 1),
        "alpha_255_share": round(float((alpha == 255).mean()), 4),
        "transparent_share": round(transparent, 4),
        "ink_pixels": int((alpha > 0).sum()),
        "alpha_pixels_total": int(total),
        "canvas_is_box": image.width == box and image.height == box,
        "ink_fills_box": bool(fills),
        "mostly_solid": bool(solid),
        "verdict": "pass" if fills and solid else "FAIL",
    }


def expectations(args) -> list[tuple[Path, int]]:
    pairs: list[tuple[Path, int]] = []
    if args.report:
        report = json.loads(Path(args.report).read_text(encoding="utf-8"))
        directory = Path(args.dir)
        for row in report["rows"]:
            pairs.append((directory / f"{row['file']}.png", row["logical"][0]))
            if (directory / f"{row['file']}@2x.png").is_file():
                pairs.append((directory / f"{row['file']}@2x.png", row["at2x"][0]))
    for spec in args.px:
        name, _, size = spec.partition("=")
        pairs.append((Path(args.dir) / name, int(size)))
    missing = [str(p) for p, _ in pairs if not p.is_file()]
    if missing:
        raise SystemExit("not staged: " + ", ".join(missing))
    return pairs


def sheet(rows: list[dict], directory: Path, tag: str) -> Image.Image:
    tile = max(row["expected_box"] for row in rows) * ZOOM
    pad = 12
    columns = 6
    lines = 44
    width = pad + columns * (tile + pad) + pad + 340
    height = 74 + ((len(rows) + columns - 1) // columns) * (tile + lines + pad)
    image = Image.new("RGB", (width, height), VOID)
    draw = ImageDraw.Draw(image)
    failed = sum(1 for row in rows if row["verdict"] != "pass")
    draw.text((20, 12), f"cut integrity - {len(rows)} cuts, ink box vs plate box, "
                        f"{'all pass' if not failed else f'{failed} FAIL'}",
              font=font(25), fill=INK if not failed else BAD)
    draw.text((20, 44), f"expected box outlined in ember, drawn at {ZOOM}x on a "
                        f"checkerboard; a screenshot of the art is not evidence, a "
                        f"measurement plus a look is", font=font(15), fill=DIM)
    for index, row in enumerate(rows):
        column, line = index % columns, index // columns
        x = pad + column * (tile + pad)
        y = 74 + line * (tile + lines + pad)
        plate = Image.open(directory / row["name"]).convert("RGBA")
        scaled = plate.resize((plate.width * ZOOM, plate.height * ZOOM), Image.NEAREST)
        board = checkerboard(scaled.size)
        board.paste(scaled.convert("RGB"), (0, 0), scaled)
        image.paste(board, (x, y))
        draw.rectangle([x, y, x + plate.width * ZOOM - 1, y + plate.height * ZOOM - 1],
                       outline=EMBER if row["verdict"] == "pass" else BAD)
        box = row["expected_box"]
        draw.rectangle([x - 1, y - 1, x + box * ZOOM, y + box * ZOOM],
                       outline=EMBER)
        tone = GOOD if row["verdict"] == "pass" else BAD
        draw.text((x, y + tile + 2), row["name"], font=font(14), fill=tone)
        draw.text((x, y + tile + 18),
                  f"{row['canvas'][0]}x{row['canvas'][1]} box {box} "
                  f"ink {row['ink_box'][2] - row['ink_box'][0]}x"
                  f"{row['ink_box'][3] - row['ink_box'][1]}", font=font(13), fill=DIM)
        draw.text((x, y + tile + 32),
                  f"alpha {row['alpha_mean']:.0f} solid {row['alpha_255_share'] * 100:.0f}% "
                  f"clear {row['transparent_share'] * 100:.0f}%", font=font(13), fill=DIM)
    return image


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", default="", help="a recut report with rows[file,logical,at2x]")
    ap.add_argument("--dir", default="staging/phase_f/ui")
    ap.add_argument("--px", nargs="*", default=[], help="extra checks, name=size")
    ap.add_argument("--tag", default="")
    args = ap.parse_args()

    directory = Path(args.dir)
    if not directory.is_absolute():
        directory = ROOT / directory
    pairs = expectations(args)
    rows = [measure(path, box) for path, box in pairs]
    tag = args.tag or (Path(args.report).stem.replace("recut_", "").replace("_report", "")
                       if args.report else directory.name)
    OUT.mkdir(parents=True, exist_ok=True)
    table = OUT / f"qc_{tag}_table.txt"
    record = STAGE / f"qc_{tag}.json"
    record.write_text(json.dumps({"rows": rows}, indent=1), encoding="utf-8")
    header = (f"{'cut':34s} {'canvas':>9} {'box':>4} {'ink box':>14} {'alpha':>6} "
              f"{'solid':>6} {'clear':>6}  verdict")
    lines = [header]
    for row in rows:
        ink = row["ink_box"]
        canvas = f"{row['canvas'][0]}x{row['canvas'][1]}"
        bounds = f"{ink[0]},{ink[1]}..{ink[2]},{ink[3]}"
        lines.append(f"{row['name']:34s} {canvas:>9} {row['expected_box']:>4} "
                     f"{bounds:>14} {row['alpha_mean']:>6.1f} "
                     f"{row['alpha_255_share'] * 100:>5.1f}% "
                     f"{row['transparent_share'] * 100:>5.1f}%  {row['verdict']}")
    table.write_text("\n".join(lines), encoding="utf-8")
    image = sheet(rows, directory, tag)
    sheet_path = OUT / f"qc_{tag}.png"
    image.save(sheet_path)
    print("\n".join(lines))
    failed = [row["name"] for row in rows if row["verdict"] != "pass"]
    print(f"\n{len(rows) - len(failed)}/{len(rows)} pass; wrote {sheet_path.relative_to(ROOT)}, "
          f"{table.relative_to(ROOT)}, {record.relative_to(ROOT)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
