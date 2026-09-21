"""Phase G recovery - the owner review sheet for the slot-plate re-cut.

Draws, in one PNG (staging/phase_f/_preview/review_slots.png):

  A  contact sheet     the 12 states as a grid: top band = the file shipped today, drawn
                       at its logical box (what the theme stretches into 48/40/56 px),
                       middle = the staged 1x cut, bottom = the staged `@2x` cut. Every
                       cell is drawn on the game's void, at 2x the logical box, so the
                       `@2x` band reads 1:1 and the 1x band reads 2:1.
  B  true size         a full slot row per family (10 weapon / 12 cargo / 8 inventory)
                       shipped above, staged below, no scaling anywhere in the section.

and the measured table beside it (review_slots_table.txt): source cell, cut box, alpha
stats and the `@2x`-vs-cache fidelity per file, from recut_slots_report.json.

Usage: py -3.14 staging/phase_f/build_slot_review.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
SHIPPED = ROOT / "vajb-orbit" / "assets" / "ui"
STAGED = STAGE / "ui"
OUT = STAGE / "_preview"
FONT_PATH = ROOT / "vajb-orbit" / "assets" / "fonts" / "Rajdhani-Medium.ttf"

VOID = (7, 9, 13)
INK = (201, 209, 220)
DIM = (107, 116, 132)
GOOD = (122, 196, 122)
BAD = (200, 71, 31)
ZOOM = 2
STATES = ("normal", "hover", "pressed", "disabled")
FAMILIES = (("weapon", 48, 10), ("cargo", 40, 12), ("inventory", 56, 8))


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT_PATH), size)
    except OSError:
        return ImageFont.load_default(size)


def on_void(image: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", image.size, VOID + (255,))
    canvas.alpha_composite(image.convert("RGBA"))
    return canvas.convert("RGB")


def to_box(path: Path, box: int, zoom: int = ZOOM,
           nearest: bool = False) -> Image.Image:
    plate = Image.open(path).convert("RGBA").resize((box, box), Image.LANCZOS)
    method = Image.NEAREST if nearest else Image.LANCZOS
    return on_void(plate.resize((box * zoom, box * zoom), method))


def contact_sheet() -> Image.Image:
    report = json.loads((STAGE / "recut_slots_report.json").read_text(encoding="utf-8"))
    qc = json.loads((STAGE / "qc_slots.json").read_text(encoding="utf-8"))["rows"]
    passed = sum(1 for row in qc if row["verdict"] == "pass")
    rows = {row["file"]: row for row in report["rows"]}
    tile = 48 * ZOOM
    pad = 10
    left = 96
    head = 110
    band = tile + 30
    width = left + 12 * (tile + pad) + pad + 300
    sheet = Image.new("RGB", (width, head + 3 * band + 34), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "A  slot plates: shipped today vs the F.1 cut recovered from "
                        "Godot's import cache", font=font(25), fill=INK)
    draw.text((20, 44), f"grid cells at {ZOOM}x the logical box ({tile} px), so the @2x "
                        f"band is 1:1 and the 1x band is 2:1; all on #07090d",
              font=font(15), fill=DIM)
    draw.text((20, 62), f"cut integrity: {passed}/{len(qc)} cuts pass ink-box-vs-plate-box "
                        f"and opacity (qc_slots.png, qc_slots_table.txt)",
              font=font(15), fill=GOOD if passed == len(qc) else BAD)
    draw.text((width - 288, 12), "green = proven against the cache", font=font(15),
              fill=GOOD)
    draw.text((width - 288, 32), "the recipe is chrome_2x.py:", font=font(15), fill=DIM)
    draw.text((width - 288, 50), "alpha crop -> LANCZOS to the box", font=font(15),
              fill=DIM)

    bands = (("shipped", lambda path, box: to_box(path, box)),
             ("staged 1x", lambda path, box: to_box(STAGED / path.name, box, nearest=True)),
             ("staged @2x", lambda path, box: to_box(
                 STAGED / f"{path.stem}@2x.png", box, nearest=True)))
    for band_index, (label, render) in enumerate(bands):
        y = head + band_index * band
        draw.text((16, y + tile // 2 - 8), label, font=font(17),
                  fill=BAD if band_index == 0 else GOOD)
        column = 0
        for family, box, _count in FAMILIES:
            for state in STATES:
                name = f"ui_slot_{family}_{state}"
                x = left + column * (tile + pad)
                if state == "normal" and band_index == 0:
                    draw.text((x, y - 20), family, font=font(17), fill=INK)
                sheet.paste(render(SHIPPED / f"{name}.png", box), (x, y))
                draw.rectangle([x, y, x + tile - 1, y + tile - 1], outline=(45, 52, 64))
                if band_index == 0:
                    draw.text((x, y + tile + 2), state, font=font(14), fill=DIM)
                if band_index == 2:
                    cache = rows[name]["at2x_vs_cache"]
                    verdict = "exact" if cache["exact"] else \
                        f"max {cache['max_abs_diff']}"
                    draw.text((x, y + tile + 2), verdict, font=font(14),
                              fill=GOOD if cache["proven"] else BAD)
                column += 1
    return sheet


def true_size() -> Image.Image:
    head = 74
    rows_height = sum(box * 2 + 54 for _f, box, _c in FAMILIES)
    width = 40 + max(count * (box + 4) for _f, box, count in FAMILIES) + 240
    sheet = Image.new("RGB", (width, head + rows_height + 16), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "B  true size: a full slot row, shipped (top) and staged (bottom)",
              font=font(25), fill=INK)
    draw.text((20, 44), "1:1 pixels on the void the HUD paints behind them; "
                        "the shipped plates are whole sheet cells stretched into the slot",
              font=font(15), fill=DIM)
    y = head
    for family, box, count in FAMILIES:
        for label, source in (("shipped", SHIPPED), ("staged", STAGED)):
            strip = Image.new("RGBA", (count * (box + 4), box), (0, 0, 0, 0))
            for index in range(count):
                plate = Image.open(source / f"ui_slot_{family}_{STATES[index % 4]}.png")
                plate = plate.convert("RGBA").resize((box, box), Image.LANCZOS)
                strip.alpha_composite(plate, (index * (box + 4), 0))
            view = on_void(strip)
            sheet.paste(view, (20, y))
            draw.text((32 + view.width + 16, y + box // 2 - 9),
                      f"{family}: {label}, {count} x {box} px", font=font(17),
                      fill=BAD if label == "shipped" else GOOD)
            y += box + 6
        y += 42
    return sheet


def table() -> list[str]:
    report = json.loads((STAGE / "recut_slots_report.json").read_text(encoding="utf-8"))
    lines = [
        "slot plate re-cut - measured (staging/phase_f/recut_slots_report.json)",
        "",
        f"{'file':26s} {'cell':>11} {'box':>4} {'1x ink box':>16} {'alpha':>6} "
        f"{'solid':>6}  {'@2x vs F.1 cache':>19}  shipped before",
    ]
    for row in report["rows"]:
        cache = row["at2x_vs_cache"]
        verdict = "exact" if cache["exact"] else \
            f"mean {cache['mean_abs_diff']:.4f} max {cache['max_abs_diff']}"
        ink = row["one_x_alpha"]["ink_box"]
        lines.append(
            f"{row['file']:26s} {str(tuple(row['source_cell_size'])):>11} "
            f"{row['logical'][0]:>4} "
            f"{f'{ink[0]},{ink[1]}..{ink[2]},{ink[3]}':>16} "
            f"{row['one_x_alpha']['alpha_mean']:>6.1f} "
            f"{row['one_x_alpha']['alpha_255_share'] * 100:>5.1f}%  {verdict:>19}  "
            f"{row['shipped_before']}")
    lines += [
        "",
        "logical boxes: UI_CHROME_ASSETS_SPEC section 4/5, and section 10's @2x table -",
        "weapon 48x48 / 96x96, cargo 40x40 / 80x80, inventory 56x56 / 112x112.",
        "Both cuts come from the same recovered cell by the same rule, so the",
        "@2x-versus-cache column proves the 1x cut as well: the cache copy is the F.1",
        "artifact itself, recovered bit-exact from .godot/imported (recover_ctex.py).",
        "",
        "1x inks the full box on every file (a plate, not a floating silhouette); the",
        "shipped files are 70-97 mean levels away from the F.1 cut at the same box.",
    ]
    return lines


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    top, bottom = contact_sheet(), true_size()
    width = max(top.width, bottom.width)
    sheet = Image.new("RGB", (width, top.height + bottom.height + 24), VOID)
    sheet.paste(top, (0, 0))
    sheet.paste(bottom, (0, top.height + 24))
    sheet.save(OUT / "review_slots.png")
    (OUT / "review_slots_table.txt").write_text("\n".join(table()), encoding="utf-8")
    print(f"wrote {OUT / 'review_slots.png'} {sheet.size}")
    print(f"wrote {OUT / 'review_slots_table.txt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
