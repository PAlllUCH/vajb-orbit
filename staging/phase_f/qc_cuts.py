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
INK_TOLERANCE = 3          # px an inset art's ink box may drift from its imprint
INSET_INK_MEAN = 60.0      # an inset art's ink region must carry real art
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


def measure(path: Path, box: tuple[int, int], expected_ink: list[int] | None = None) -> dict:
    image = Image.open(path).convert("RGBA")
    alpha = np.asarray(image)[..., 3]
    total = alpha.size
    ink = np.nonzero(alpha > 0)
    core = np.nonzero(alpha >= 128)
    ink_box = (None if not len(ink[0]) else
               [int(ink[1].min()), int(ink[0].min()),
                int(ink[1].max()) + 1, int(ink[0].max()) + 1])
    transparent = float((alpha == 0).mean())
    on_canvas = [image.width, image.height] == [int(box[0]), int(box[1])]
    if expected_ink is None:
        fills = (on_canvas and ink_box is not None
                 and ink_box[0] <= BOX_TOLERANCE and ink_box[1] <= BOX_TOLERANCE
                 and ink_box[2] >= image.width - BOX_TOLERANCE
                 and ink_box[3] >= image.height - BOX_TOLERANCE)
        solid = transparent <= SOLID_TRANSPARENT and float(alpha.mean()) >= SOLID_MEAN
    else:
        # An inset art (the wordmark sits inside its shadow pad and the canvas is
        # deliberately larger than the ink): the ink box is the thing to match, and
        # solidity is judged on the ink rather than on the whole canvas.
        fills = (on_canvas and ink_box is not None
                 and all(abs(ink_box[i] - expected_ink[i]) <= INK_TOLERANCE
                         for i in range(4)))
        inside = alpha[ink_box[1]:ink_box[3], ink_box[0]:ink_box[2]]
        solid = float(inside.mean()) >= INSET_INK_MEAN
    return {
        "name": path.name,
        "canvas": [image.width, image.height],
        "expected_box": [int(box[0]), int(box[1])],
        "expected_ink": expected_ink,
        "ink_box": ink_box,
        "core_box": (None if not len(core[0]) else
                     [int(core[1].min()), int(core[0].min()),
                      int(core[1].max()) + 1, int(core[0].max()) + 1]),
        "alpha_mean": round(float(alpha.mean()), 1),
        "alpha_255_share": round(float((alpha == 255).mean()), 4),
        "transparent_share": round(transparent, 4),
        "ink_pixels": int((alpha > 0).sum()),
        "alpha_pixels_total": int(total),
        "canvas_is_box": on_canvas,
        "ink_fills_box": bool(fills),
        "mostly_solid": bool(solid),
        "verdict": "pass" if fills and solid else "FAIL",
      }

def expectations(args) -> list[tuple[Path, tuple[int, int], list[int] | None]]:
    pairs: list[tuple[Path, tuple[int, int], list[int] | None]] = []

    def size(text: str) -> tuple[int, int]:
        parts = text.lower().split("x")
        return (int(parts[0]), int(parts[0])) if len(parts) == 1 else (int(parts[0]),
                                                                     int(parts[1]))

    if args.report:
        report = json.loads(Path(args.report).read_text(encoding="utf-8"))
        directory = Path(args.dir)
        for row in report["rows"]:
            ink = row.get("expected_ink")
            logical = row["logical"]
            box = (logical[0], logical[-1])
            pairs.append((directory / f"{row['file']}.png", box, ink))
            if row.get("at2x") and (directory / f"{row['file']}@2x.png").is_file():
                pairs.append((directory / f"{row['file']}@2x.png",
                              (row["at2x"][0], row["at2x"][-1]), None))
    for spec in args.px:
        name, _, dimensions = spec.partition("=")
        pairs.append((Path(args.dir) / name, size(dimensions), None))
    missing = [str(p) for p, _b, _i in pairs if not p.is_file()]
    if missing:
        raise SystemExit("not staged: " + ", ".join(missing))
    return pairs


def sheet(rows: list[dict], directory: Path, tag: str) -> Image.Image:
    # Capped: one row here is a 2048 px logo, and sizing every tile to that would build a
    # 700-megapixel sheet.
    tile = min(max(max(row["expected_box"]) for row in rows) * ZOOM, 420)
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
        scale = min(tile / plate.width, tile / plate.height)
        big = plate.resize((max(1, int(plate.width * scale)),
                            max(1, int(plate.height * scale))), Image.NEAREST)
        board = checkerboard(big.size)
        board.paste(big.convert("RGB"), (0, 0), big)
        image.paste(board, (x, y))
        draw.rectangle([x - 1, y - 1, x + big.width, y + big.height],
                       outline=EMBER if row["verdict"] == "pass" else BAD)
        tone = GOOD if row["verdict"] == "pass" else BAD
        draw.text((x, y + tile + 2), row["name"], font=font(14), fill=tone)
        ink = row["ink_box"]
        draw.text((x, y + tile + 18),
                  f"{row['canvas'][0]}x{row['canvas'][1]} box "
                  f"{row['expected_box'][0]}x{row['expected_box'][1]}", font=font(13),
                  fill=DIM)
        draw.text((x, y + tile + 32),
                  f"ink {ink[2] - ink[0]}x{ink[3] - ink[1]} alpha "
                  f"{row['alpha_mean']:.0f} clear {row['transparent_share'] * 100:.0f}%",
                  font=font(13), fill=DIM)
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
    rows = [measure(path, box, ink) for path, box, ink in pairs]
    tag = args.tag or (Path(args.report).stem.replace("recut_", "").replace("_report", "")
                       if args.report else directory.name)
    OUT.mkdir(parents=True, exist_ok=True)
    table = OUT / f"qc_{tag}_table.txt"
    record = STAGE / f"qc_{tag}.json"
    record.write_text(json.dumps({"rows": rows}, indent=1), encoding="utf-8")
    header = (f"{'cut':30s} {'canvas':>10} {'box':>9} {'ink box':>16} {'alpha':>6} "
              f"{'solid':>6} {'clear':>6}  verdict")
    lines = [header]
    for row in rows:
        ink = row["ink_box"]
        canvas = f"{row['canvas'][0]}x{row['canvas'][1]}"
        bounds = f"{ink[0]},{ink[1]}..{ink[2]},{ink[3]}"
        expected = f"{row['expected_box'][0]}x{row['expected_box'][1]}"
        lines.append(f"{row['name']:30s} {canvas:>10} {expected:>9} "
                     f"{bounds:>16} {row['alpha_mean']:>6.1f} "
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
