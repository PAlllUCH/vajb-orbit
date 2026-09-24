"""The D7 review sheet: the six masters at their logical box and at 2x, plus the well overlay.

Section 1 shows every shipped master twice - drawn at the spec's logical size and at the master's
own pixels - on a checkerboard so alpha is visible, labelled with its box, its route and the QC
verdict from `qc_d7.py`.

Section 2 is the measurement itself: for each well-bearing panel, the master at 2x with the pinned
UI_SPEC 3.7 / 3.8 / 3.10 bay rects drawn in ember and every recess `qc_d7.py` detected outlined in
green. The owner can see at a glance where a render's own wells are and where the engine will mount.

Usage:
    py -3.14 staging/phase_g/build_review_d7.py
"""
from __future__ import annotations

import io
import json
from pathlib import Path

from PIL import Image, ImageDraw

import qc_d7
import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
MASTERS = STAGE / "ui" / "_masters"
REVIEW = STAGE / "_review"
QC = STAGE / "ui" / "qc_d7_ship.json"
AUTHORED = STAGE / "ui" / "_authored_ship"
ORDER = ["ui_cockpit_panel", "ui_gauge_face", "ui_armory_console", "ui_armory_rack_plate",
         "ui_armory_row_plate", "ui_status_panel"]
WELL_PANELS = ["ui_cockpit_panel", "ui_armory_console", "ui_armory_rack_plate", "ui_status_panel"]
COLS = 3
TILE = 460
PAD = 12
EMBER = (200, 70, 27)
GREEN = (74, 232, 108)
BACKDROP = (28, 30, 34)
INK = (230, 232, 236)
DIM = (170, 176, 184)


def checker(size: tuple[int, int], step: int = 12) -> Image.Image:
    img = Image.new("RGB", size, (46, 46, 50))
    draw = ImageDraw.Draw(img)
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2 == 0:
                draw.rectangle([x, y, x + step - 1, y + step - 1], fill=(62, 62, 68))
    return img


def section_one(qc: dict) -> Image.Image:
    rows = (len(ORDER) + COLS - 1) // COLS
    sheet = checker((COLS * TILE, rows * TILE + 34))
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 8), f"D7 masters - logical box and 2x master ({len(ORDER)} files)", fill=INK)
    for index, name in enumerate(ORDER):
        master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
        logical_box = wave_g.UI_D7_LOGICAL[name]
        logical = master.resize(logical_box, Image.LANCZOS)
        ## The armory console's logical box (872x908) is wider than a tile: the drawing is capped so
        ## the tile shows the whole thing, and the label still carries the true logical box.
        logical.thumbnail((TILE - 2 * PAD, 150), Image.LANCZOS)
        col, row = index % COLS, index // COLS
        x0, y0 = col * TILE, row * TILE + 34
        verdict = qc[name].get("wells_pass")
        detail = "no wells to check" if "wells" not in qc[name] else (
            "wells PASS" if verdict else f"wells FAIL (worst recess {qc[name].get('plate_median')} "
            f"median)")
        if name == "ui_gauge_face":
            detail = "wells PASS" if qc[name].get("wells_pass") else "wells FAIL"
        draw.text((x0 + 8, y0 + 8), name, fill=INK)
        shown = "" if logical.size == tuple(logical_box) else f" (shown {logical.size[0]}x{logical.size[1]})"
        draw.text((x0 + 8, y0 + 24),
                  f"logical {logical_box[0]}x{logical_box[1]}{shown} / master {master.size[0]}x"
                  f"{master.size[1]} · {detail}", fill=DIM)
        lx = x0 + PAD
        ly = y0 + 48 + (TILE - 48 - 2 * PAD - logical.size[1]) // 2
        sheet.paste(logical, (lx, ly), logical)
        draw.rectangle([lx - 1, ly - 1, lx + logical.size[0], ly + logical.size[1]],
                       outline=(120, 126, 134))
        mx = x0 + PAD + logical.size[0] + 14
        room = TILE - 48 - 2 * PAD - 4
        thumb = master.copy()
        thumb.thumbnail((room, room), Image.LANCZOS)
        my = y0 + 48 + (room - thumb.size[1]) // 2
        sheet.paste(thumb, (mx, my), thumb)
        draw.rectangle([mx - 1, my - 1, mx + thumb.size[0], my + thumb.size[1]], outline=GREEN)
        draw.text((mx + 4, my + 4),
                  f"2x {master.size[0]}x{master.size[1]}"
                  + ("" if thumb.size == master.size else f" shown {thumb.size[0]}x{thumb.size[1]}"),
                  fill=DIM)
    return sheet


def section_two(qc: dict) -> Image.Image:
    tiles: list[Image.Image] = []
    for name in WELL_PANELS:
        master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
        room = 460
        scale = min(room / master.size[0], room / master.size[1], 1.0)
        view = master.resize((int(master.size[0] * scale), int(master.size[1] * scale)),
                             Image.LANCZOS)
        canvas = Image.new("RGB", (TILE, TILE + 40), BACKDROP)
        canvas.paste(view, ((TILE - view.size[0]) // 2, 34), view)
        draw = ImageDraw.Draw(canvas)
        draw.text((8, 6), f"{name} - pinned bays (ember) vs detected wells (green)", fill=INK)
        draw.text((8, 20), f"scale {scale:.2f}x of the 2x master", fill=DIM)
        offset = ((TILE - view.size[0]) // 2, 34)
        for label, spec in qc_d7.EXPECTED[name]:
            x0, y0, x1, y1 = (int(v * scale) + offset[0] for v in _box_for(spec))
            draw.rectangle([x0, y0, x1, y1], outline=EMBER, width=2)
            draw.text((x0 + 3, y0 + 3), label, fill=EMBER)
        for well in qc[name].get("wells", []):
            if not well.get("found"):
                continue
            bx0, by0, bx1, by1 = well["well_box"]
            x0, y0 = int(bx0 * scale) + offset[0], int(by0 * scale) + offset[1]
            x1, y1 = int(bx1 * scale) + offset[0], int(by1 * scale) + offset[1]
            draw.rectangle([x0, y0, x1, y1], outline=GREEN, width=1)
        tiles.append(canvas)
    cols = 2
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * TILE, rows * (TILE + 40) + 26), BACKDROP)
    sheet_draw = ImageDraw.Draw(sheet)
    sheet_draw.text((8, 6), "well registration - the pins the engine mounts to, the wells the "
                            "render drew", fill=INK)
    for index, tile in enumerate(tiles):
        sheet.paste(tile, ((index % cols) * TILE, 26 + (index // cols) * (TILE + 40)))
    return sheet


def section_three() -> Image.Image:
    """The section 12 fallback route's own output, for the same four panels, side by side."""
    tiles: list[Image.Image] = []
    for name in WELL_PANELS:
        path = AUTHORED / f"{name}.png"
        if not path.is_file():
            continue
        master = Image.open(path).convert("RGBA")
        room = 460
        scale = min(room / master.size[0], room / master.size[1], 1.0)
        view = master.resize((int(master.size[0] * scale), int(master.size[1] * scale)),
                             Image.LANCZOS)
        canvas = Image.new("RGB", (TILE, TILE + 40), BACKDROP)
        canvas.paste(view, ((TILE - view.size[0]) // 2, 34), view)
        draw = ImageDraw.Draw(canvas)
        draw.text((8, 6), f"{name} - authored route (ui_authored_d7.py)", fill=INK)
        draw.text((8, 20), "pinned wells drawn; the render's own wells erased and refilled", fill=DIM)
        tiles.append(canvas)
    cols = 2
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * TILE, rows * (TILE + 40) + 26), BACKDROP)
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 6), "section 12's fallback (staged, NOT shipped): shapes over a painted plate",
              fill=INK)
    for index, tile in enumerate(tiles):
        sheet.paste(tile, ((index % cols) * TILE, 26 + (index // cols) * (TILE + 40)))
    return sheet


def _box_for(spec: dict) -> tuple[float, float, float, float]:
    return tuple(qc_d7.reference_box(spec))


def main() -> int:
    qc = json.loads(QC.read_text(encoding="utf-8"))
    one = section_one(qc)
    two = section_two(qc)
    three = section_three()
    width = max(one.size[0], two.size[0], three.size[0])
    sheet = Image.new("RGB", (width, one.size[1] + two.size[1] + three.size[1]), BACKDROP)
    sheet.paste(one, (0, 0))
    sheet.paste(two, (0, one.size[1]))
    sheet.paste(three, (0, one.size[1] + two.size[1]))
    REVIEW.mkdir(parents=True, exist_ok=True)
    full = REVIEW / "d7_masters.png"
    sheet.save(full)
    payload = b""
    viewer = sheet
    for quality in (74, 66, 58, 50, 42):
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
    jpg = REVIEW / "d7_masters.jpg"
    jpg.write_bytes(payload)
    print(f"{full.relative_to(ROOT)}  {sheet.size} full sheet")
    print(f"{jpg.relative_to(ROOT)}  {viewer.size}  {len(payload) / 1000:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
