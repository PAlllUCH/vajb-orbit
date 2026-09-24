"""The D7-A2 review sheet: the armory console plate re-rendered on the ruled canvas.

Wave D7, `docs/design/UI_SPEC.md` section 3.10 Amendment 2 (the D7-R1 MED-1 ruling) and
`docs/design/UI_CHROME_ASSETS_SPEC.md` section 12 Amendment 2. A1's sheet shows the three flat
plates; this one shows the console alone, because its approval question is the one MED-1 named:
does the plate cover the box the code mounts its wells into, at the ruled 872x956 canvas instead
of the retired 872x908 one?

* Section 1 - the plate drawn at its logical box (872x956, what the game lays out) and at its 2x
  master box (1744x1912), on a checkerboard so the alpha is visible, with its md5 and the section
  12 QC verdict (box verify + ink containment).
* Section 2 - the coverage measurement: the master at box scale with the code-drawn well rects in
  ember (UI_SPEC section 3.10's pinned rects on the ruled canvas) and the plate's own ink rect in
  green, labelled with the fill shares and the well-union coverage.
* Section 3 - the eight render passes and why pass 8 is the one that ships (ink box -> cut aspect
  -> well-union coverage), the chosen pass's own render with its detected ink box, and the trim
  margins of the shipped cut.

Usage:
    py -3.14 staging/phase_g/build_review_d7_a2.py
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
CONTAINMENT = STAGE / "ui" / "qc_d7_a2_shipped.json"
COVERAGE = STAGE / "ui" / "qc_d7_a2_coverage.json"
PANEL = "ui_armory_console"
EMBER = (200, 70, 27)
GREEN = (74, 232, 108)
BACKDROP = (28, 30, 34)
INK = (230, 232, 236)
DIM = (170, 176, 184)
## The eight passes this worker ran, in order: (folder, canvas, ink box, cut aspect, union %).
## Measured record; the numbers are also in `_a2_render.log`, `_a2_detect_*.json` and
## `D7-A0_report.md`'s A2 section.
PASSES = [
    ("p1 20260924-123123", "1:1", (1667, 2025), 0.823, 96.18),
    ("p2 20260924-123236", "1:1", (1946, 1940), 1.003, 96.62),
    ("p3 20260924-123344", "1:1", (1385, 1976), 0.701, 81.83),
    ("p4 20260924-123458", "1:1", (1663, 2000), 0.832, 97.11),
    ("p5 20260924-123645", "1:1", (1493, 2030), 0.735, 85.90),
    ("p6 20260924-123758", "3:4", (1182, 1930), 0.612, 71.49),
    ("p7 20260924-123919", "1:1", (1473, 2035), 0.724, 84.54),
    ("p8 20260924-124037", "1:1", (1905, 2048), 0.930, 100.00),
]


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
    header = 30
    height = 640
    sheet = checker((760, header + height))
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 8), "D7-A2 armory console - at its logical box and at its 2x master "
                      "(UI_SPEC section 3.10 Amendment 2)", fill=INK)
    master = Image.open(MASTERS / f"{PANEL}.png").convert("RGBA")
    logical_box = wave_g.UI_D7_LOGICAL[PANEL]
    c = containment[PANEL]
    draw.text((12, header + 6), f"{PANEL}   master {master.size[0]}x{master.size[1]} / logical "
                                f"{logical_box[0]}x{logical_box[1]}   md5 {c['md5'][:8]}", fill=INK)
    draw.text((12, header + 20), f"QC: box match, ink containment "
                                 f"{c['ink_containment'] * 100:.2f}%, no baked well/recess/slot",
              fill=DIM)
    logical = fitted(master, (320, 420))
    sheet.paste(logical, (12, header + 44), logical)
    draw.rectangle([11, header + 43, 12 + logical.size[0], header + 44 + logical.size[1]],
                   outline=(120, 126, 134))
    draw.text((12, header + 50 + logical.size[1]),
              f"logical {logical_box[0]}x{logical_box[1]}\n{logical.size[0]}x{logical.size[1]} "
              f"on screen", fill=DIM)
    shown = master.copy()
    shown.thumbnail((380, 520), Image.LANCZOS)
    sheet.paste(shown, (360, header + 44), shown)
    draw.rectangle([359, header + 43, 360 + shown.size[0], header + 44 + shown.size[1]],
                   outline=GREEN)
    draw.text((360, header + 50 + shown.size[1]),
              f"2x master {shown.size[0]}x{shown.size[1]} on screen", fill=DIM)
    return sheet


def section_two(coverage: dict) -> Image.Image:
    header = 40
    height = 620
    sheet = Image.new("RGB", (760, header + height), BACKDROP)
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 6), "plate coverage - the pinned rects the code draws its wells into (ember) vs "
                      "the plate's own ink (green)", fill=INK)
    draw.text((8, 20), "a plate that only reaches part of its box leaves those wells on bare void; "
                       "the fill share is the plate's ink over the pinned master box", fill=DIM)
    master = Image.open(MASTERS / f"{PANEL}.png").convert("RGBA")
    cov = coverage[PANEL]
    room = (700, height - 60)
    scale = min(room[0] / master.size[0], room[1] / master.size[1], 1.0)
    view = master.resize((max(1, int(master.size[0] * scale)),
                          max(1, int(master.size[1] * scale))), Image.LANCZOS)
    ox, oy = 12, header + 8
    sheet.paste(view, (ox, oy), view)
    for label, rect in qc_d7_a1.WELL_UNIONS[PANEL]:
        draw.rectangle([ox + int(rect[0] * scale), oy + int(rect[1] * scale),
                        ox + int(rect[2] * scale), oy + int(rect[3] * scale)],
                       outline=EMBER, width=2)
        draw.text((ox + int(rect[0] * scale) + 4, oy + int(rect[1] * scale) + 4),
                  label, fill=EMBER)
    ix = cov["plate_ink_rect"]
    draw.rectangle([ox + int(ix[0] * scale), oy + int(ix[1] * scale),
                    ox + int(ix[2] * scale), oy + int(ix[3] * scale)], outline=GREEN, width=1)
    draw.text((ox, oy + view.size[1] + 6),
              f"plate fills {cov['fill_w']}% x {cov['fill_h']}% of the 1744x1912 box = "
              f"{cov['fill_area']}% area", fill=DIM)
    draw.text((ox, oy + view.size[1] + 20),
              f"well union inside {cov['well_union_inside_pct']}% - "
              f"{'COVERS' if cov['well_union_covered'] else 'near-covers'}; render ink aspect "
              f"{cov['ink_aspect']} vs box {cov['box_aspect']}", fill=DIM)
    return sheet


def section_three(coverage: dict) -> Image.Image:
    header = 34
    height = 620
    sheet = Image.new("RGB", (760, header + height), BACKDROP)
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 4), "the eight render passes - only a cut aspect in [0.855, 0.960] lets "
                      "`contain` cover the pinned well union", fill=INK)
    draw.text((8, 18), "pass 8 names the vertical axis as a frame-filling clause and the missing "
                       "6 % of width as white side strips, so no clause contradicts another",
              fill=DIM)
    for index, (label, canvas, ink, aspect, union) in enumerate(PASSES):
        y = header + 6 + index * 15
        chosen = union >= 100.0
        draw.text((12, y), f"{label}  canvas {canvas}   ink {ink[0]}x{ink[1]}  aspect "
                           f"{aspect:.3f}  union {union:6.2f}%  "
                           f"{'SHIPS' if chosen else 'rejected'}", fill=GREEN if chosen else DIM)
    image = Image.open(STAGE / "ui" / "20260924-124037"
                       / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGB")
    box = json.loads((STAGE / "ui" / "_a2_detect_panel_armory_console_flat_a2_p8.json")
                     .read_text(encoding="utf-8"))[0]["box"]
    view = image.copy()
    view.thumbnail((300, 300), Image.LANCZOS)
    sheet.paste(view, (12, header + 136))
    draw.rectangle([12 + box[0] * view.size[0] // image.size[0],
                    header + 136 + box[1] * view.size[1] // image.size[1],
                    12 + box[2] * view.size[0] // image.size[0],
                    header + 136 + box[3] * view.size[1] // image.size[1]],
                   outline=GREEN, width=2)
    draw.text((12, header + 142 + view.size[1]),
              f"pass 8 render {image.size[0]}x{image.size[1]} (green = detected ink box), ink "
              f"aspect {coverage[PANEL]['ink_aspect']}", fill=DIM)
    cut = Image.open(STAGE / "ui" / f"{PANEL}.png").convert("RGBA")
    cut_view = cut.copy()
    cut_view.thumbnail((300, 460), Image.LANCZOS)
    sheet.paste(cut_view, (360, header + 136), cut_view)
    draw.text((360, header + 142 + cut_view.size[1]),
              f"shipped cut {cut.size[0]}x{cut.size[1]} -> drawn "
              f"{coverage[PANEL]['drawn_plate'][0]}x"
              f"{coverage[PANEL]['drawn_plate'][1]} in the 1744x1912 box (scale "
              f"{coverage[PANEL]['scale']}, pad 0.00 floored at 8 px, canvas 1:1); shipped master "
              f"is 1744x1912", fill=DIM)
    return sheet


def main() -> int:
    containment = {row["panel"]: row
                   for row in json.loads(CONTAINMENT.read_text(encoding="utf-8"))}
    coverage = {row["panel"]: row for row in json.loads(COVERAGE.read_text(encoding="utf-8"))}
    sections = [section_one(containment), section_two(coverage), section_three(coverage)]
    width = max(s.size[0] for s in sections)
    sheet = Image.new("RGB", (width, sum(s.size[1] for s in sections)), BACKDROP)
    y = 0
    for section in sections:
        sheet.paste(section, (0, y))
        y += section.size[1]
    REVIEW.mkdir(parents=True, exist_ok=True)
    full = REVIEW / "d7a2_console.png"
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
    jpg = REVIEW / "d7a2_console.jpg"
    jpg.write_bytes(payload)
    print(f"{full.relative_to(ROOT)}  {sheet.size} full sheet")
    print(f"{jpg.relative_to(ROOT)}  {viewer.size}  {len(payload) / 1000:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
