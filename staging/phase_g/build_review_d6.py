"""The D6 review sheet: all 18 masters at their logical box and at 2x (UI_CHROME_ASSETS_SPEC 11).

One tile per master, labelled with its name and both boxes, drawn on a checkerboard so alpha is
visible. The logical drawing is at the spec's logical size and the 2x drawing is the shipped
master's own pixels, so the owner reviews the real geometry, not a scaled-down impression.

Writes a full-size PNG for review and a JPEG copy small enough for the image viewer.

Usage:
    py -3.14 staging/phase_g/build_review_d6.py
"""
from __future__ import annotations

import io
from pathlib import Path

from PIL import Image, ImageDraw

import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
MASTERS = STAGE / "ui" / "_masters"
REVIEW = STAGE / "_review"
ORDER = ["ui_cockpit_frame", "ui_gauge_face", "ui_gauge_needle", "ui_compass_rose",
         "ui_compass_lubber", "ui_readout_glass"] + \
        [f"ui_seg_{i}" for i in range(10)] + ["ui_seg_pct", "ui_seg_blank"]
COLS = 3
TILE = 320
PAD = 10


def checker(size: tuple[int, int], step: int = 12) -> Image.Image:
    img = Image.new("RGB", size, (46, 46, 50))
    draw = ImageDraw.Draw(img)
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2 == 0:
                draw.rectangle([x, y, x + step - 1, y + step - 1], fill=(62, 62, 68))
    return img


def main() -> int:
    missing = [n for n in ORDER if not (MASTERS / f"{n}.png").is_file()]
    if missing:
        print(f"missing masters in {MASTERS}: {', '.join(missing)}")
        return 1
    rows = (len(ORDER) + COLS - 1) // COLS
    sheet = checker((COLS * TILE, rows * TILE))
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(ORDER):
        master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
        logical_box = wave_g.UI_LOGICAL[name]
        logical = master.resize(logical_box, Image.LANCZOS)
        col, row = index % COLS, index // COLS
        x0, y0 = col * TILE, row * TILE
        draw.text((x0 + 6, y0 + 6), f"{name}", fill=(230, 232, 236))
        draw.text((x0 + 6, y0 + 22),
                  f"logical {logical_box[0]}x{logical_box[1]} / master {master.size[0]}x"
                  f"{master.size[1]}", fill=(170, 176, 184))
        lx = x0 + PAD
        ly = y0 + 44 + (TILE - 44 - 2 * PAD - logical.size[1]) // 2
        sheet.paste(logical, (lx, ly), logical)
        draw.rectangle([lx - 1, ly - 1, lx + logical.size[0], ly + logical.size[1]],
                       outline=(120, 126, 134))
        mx = x0 + PAD + logical.size[0] + 12
        my = y0 + 44 + (TILE - 44 - 2 * PAD - master.size[1]) // 2
        if master.size[1] <= TILE - 44 - 2 * PAD:
            sheet.paste(master, (mx, my), master)
            draw.rectangle([mx - 1, my - 1, mx + master.size[0], my + master.size[1]],
                           outline=(74, 232, 108))
        else:
            thumb = master.copy()
            thumb.thumbnail((TILE - 44 - 2 * PAD, TILE - 44 - 2 * PAD), Image.LANCZOS)
            sheet.paste(thumb, (mx, my), thumb)
            draw.rectangle([mx - 1, my - 1, mx + thumb.size[0], my + thumb.size[1]],
                           outline=(74, 232, 108))
            draw.text((mx + 4, my + 4), f"shown {thumb.size[0]}x{thumb.size[1]}",
                      fill=(170, 176, 184))
    REVIEW.mkdir(parents=True, exist_ok=True)
    full = REVIEW / "d6_masters.png"
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
    jpg = REVIEW / "d6_masters.jpg"
    jpg.write_bytes(payload)
    print(f"{full.relative_to(ROOT)}  {sheet.size} full sheet")
    print(f"{jpg.relative_to(ROOT)}  {viewer.size}  {len(payload) / 1000:.0f} KB  "
          f"{len(ORDER)} master(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
