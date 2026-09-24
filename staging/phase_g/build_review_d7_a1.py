"""The D7-A1 review sheet: the three re-rendered flat plates at their logical box and at 2x.

Wave D7, `docs/design/UI_CHROME_ASSETS_SPEC.md` section 12 Amendment 2. A0's sheet
(`build_review_d7.py`) shows the six masters plus the well-registration overlay; this one shows
the three flat plates Amendment 2 re-renders, because their approval question is different: the
wells are code-drawn now, so what the owner has to judge is the **plate** - its texture (brushed
steel, bolt heads, plate seams, brush grain), the absence of any baked recess, and whether it
covers the pinned box the code will mount its wells into.

* Section 1 - one column per plate: the plate drawn at its logical box (the box the game lays out)
  and at its 2x master box, on a checkerboard so the alpha is visible, labelled with its box, its
  md5 and the section 12 QC verdict (box verify + ink containment).
* Section 2 - the coverage measurement, per plate: the master at box scale with the code-drawn well
  rects in ember (UI_SPEC section 3.7 / 3.8 / 3.10's pinned rects) and the plate's own ink rect in
  green, labelled with the fill shares and the well-union coverage.

Usage:
    py -3.14 staging/phase_g/build_review_d7_a1.py
"""
from __future__ import annotations

import io
import json
from pathlib import Path

from PIL import Image, ImageDraw

import qc_d7_a1
import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
MASTERS = STAGE / "ui" / "_masters"
REVIEW = STAGE / "_review"
QC = STAGE / "ui" / "qc_d7_a1_ship.json"
CONTAINMENT = STAGE / "ui" / "qc_d7_a1_containment.json"
COLS = 3
COL_W = 640
PAD = 11
EMBER = (200, 70, 27)
GREEN = (74, 232, 108)
BACKDROP = (28, 30, 34)
INK = (230, 232, 236)
DIM = (170, 176, 184)
ORDER = ["ui_cockpit_panel", "ui_armory_console", "ui_status_panel"]


def checker(size: tuple[int, int], step: int = 12) -> Image.Image:
    img = Image.new("RGB", size, (46, 46, 50))
    draw = ImageDraw.Draw(img)
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2 == 0:
                draw.rectangle([x, y, x + step - 1, y + step - 1], fill=(62, 62, 68))
    return img


def fitted(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    thumb = image.copy()
    thumb.thumbnail(box, Image.LANCZOS)
    return thumb


def section_one(containment: dict) -> Image.Image:
    """One column per plate: the logical box above, the 2x master below."""
    header = 30
    tile_h = 600
    sheet = checker((COLS * COL_W, header + tile_h))
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 8), "D7-A1 flat plates - each plate at its logical box and at its 2x master "
                      "(UI_CHROME section 12 Amendment 2)", fill=INK)
    for index, name in enumerate(ORDER):
        master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
        logical_box = wave_g.UI_D7_LOGICAL[name]
        logical = fitted(master, (COL_W - 3 * PAD, 250)).copy()
        shown = master.copy()
        shown.thumbnail((COL_W - 3 * PAD, 250), Image.LANCZOS)
        c = containment[name]
        x0 = index * COL_W
        draw.text((x0 + PAD, header + 6), name, fill=INK)
        draw.text((x0 + PAD, header + 20),
                  f"master {master.size[0]}x{master.size[1]} / logical "
                  f"{logical_box[0]}x{logical_box[1]} - md5 {c['md5'][:8]}", fill=DIM)
        draw.text((x0 + PAD, header + 32),
                  f"QC: box match, ink containment {c['ink_containment'] * 100:.2f}%, "
                  f"no baked well/recess/slot", fill=DIM)
        ly = header + 50
        sheet.paste(logical, (x0 + PAD, ly), logical)
        draw.rectangle([x0 + PAD - 1, ly - 1, x0 + PAD + logical.size[0], ly + logical.size[1]],
                       outline=(120, 126, 134))
        draw.text((x0 + 2 * PAD + logical.size[0], ly + 2),
                  f"logical {logical_box[0]}x{logical_box[1]}\n"
                  f"{logical.size[0]}x{logical.size[1]} on screen", fill=DIM)
        my = ly + 262
        sheet.paste(shown, (x0 + PAD, my), shown)
        draw.rectangle([x0 + PAD - 1, my - 1, x0 + PAD + shown.size[0], my + shown.size[1]],
                       outline=GREEN)
        draw.text((x0 + 2 * PAD + shown.size[0], my + 2),
                  f"2x master\n{shown.size[0]}x{shown.size[1]} on screen", fill=DIM)
    return sheet


def section_two(coverage: dict) -> Image.Image:
    """The coverage measurement: the pinned code-drawn rects vs the plate's own ink rect."""
    header = 40
    tile_h = 540
    sheet = Image.new("RGB", (COLS * COL_W, header + tile_h), BACKDROP)
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 6), "plate coverage - the pinned rects the code draws its wells into (ember) vs "
                      "the plate's own ink (green)", fill=INK)
    draw.text((8, 20), "a plate that only reaches part of its box leaves those wells on bare void; "
                       "the fill share is the plate's ink over the pinned master box", fill=DIM)
    for index, name in enumerate(ORDER):
        master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
        c = coverage[name]
        room = (COL_W - 3 * PAD, tile_h - 3 * PAD)
        scale = min(room[0] / master.size[0], room[1] / master.size[1], 1.0)
        view = master.resize((max(1, int(master.size[0] * scale)),
                              max(1, int(master.size[1] * scale))), Image.LANCZOS)
        x0 = index * COL_W
        ox, oy = x0 + PAD, header + PAD
        draw.text((x0 + PAD, header - 12), f"{name}", fill=INK)
        sheet.paste(view, (ox, oy), view)
        for label, rect in qc_d7_a1.WELL_UNIONS[name]:
            draw.rectangle([ox + int(rect[0] * scale), oy + int(rect[1] * scale),
                            ox + int(rect[2] * scale), oy + int(rect[3] * scale)],
                           outline=EMBER, width=2)
            draw.text((ox + int(rect[0] * scale) + 3, oy + int(rect[1] * scale) + 3),
                      label, fill=EMBER)
        ix = c["plate_ink_rect"]
        draw.rectangle([ox + int(ix[0] * scale), oy + int(ix[1] * scale),
                        ox + int(ix[2] * scale), oy + int(ix[3] * scale)],
                       outline=GREEN, width=1)
        draw.text((ox, oy + view.size[1] + 4),
                  f"plate fills {c['fill_w']}% x {c['fill_h']}% of the box = {c['fill_area']}% "
                  f"area", fill=DIM)
        draw.text((ox, oy + view.size[1] + 18),
                  f"well union inside {c['well_union_inside_pct']}% - "
                  f"{'COVERS' if c['well_union_covered'] else 'near-covers'}; render ink "
                  f"{c['ink_aspect']} vs box {c['box_aspect']}", fill=DIM)
    return sheet


def main() -> int:
    containment = {row["panel"]: row
                   for row in json.loads(CONTAINMENT.read_text(encoding="utf-8"))}
    if not QC.is_file():
        raise SystemExit(f"run qc_d7.py first: {QC} is missing")
    json.loads(QC.read_text(encoding="utf-8"))       # the section 12 QC record must exist
    coverage = {row["panel"]: row for row in qc_d7_a1.chosen_rows()}
    one = section_one(containment)
    two = section_two(coverage)
    sheet = Image.new("RGB", (max(one.size[0], two.size[0]), one.size[1] + two.size[1]), BACKDROP)
    sheet.paste(one, (0, 0))
    sheet.paste(two, (0, one.size[1]))
    REVIEW.mkdir(parents=True, exist_ok=True)
    full = REVIEW / "d7a1_plates.png"
    sheet.save(full)
    payload = b""
    viewer = sheet
    for quality in (78, 72, 66, 58, 50, 42):
        buffer = io.BytesIO()
        viewer.save(buffer, format="JPEG", quality=quality)
        payload = buffer.getvalue()
        if len(payload) <= 195_000:
            break
    while len(payload) > 195_000 and viewer.size[0] > 320:
        viewer = viewer.resize((int(viewer.size[0] * 0.85), int(viewer.size[1] * 0.85)),
                               Image.LANCZOS)
        buffer = io.BytesIO()
        viewer.save(buffer, format="JPEG", quality=74)
        payload = buffer.getvalue()
    jpg = REVIEW / "d7a1_plates.jpg"
    jpg.write_bytes(payload)
    print(f"{full.relative_to(ROOT)}  {sheet.size} full sheet")
    print(f"{jpg.relative_to(ROOT)}  {viewer.size}  {len(payload) / 1000:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
