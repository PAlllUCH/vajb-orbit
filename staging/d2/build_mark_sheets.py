#!/usr/bin/env python3
"""D2 icon unification - owner mark sheets.

Renders every icon symbol master from vajb-orbit/assets into numbered sheets
(30 cells per sheet). The owner paints a red X on the cells that must become
SVG masters; blank cells keep ONE raster master (all size variants die in
Phase C either way). read_marks.py diffs a marked sheet against the reference
render produced here, so any mark colour works.

Regenerate after any asset change:
    python3 staging/d2/build_mark_sheets.py
"""

import os
import re
import csv

from PIL import Image, ImageDraw, ImageFont

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
ASSETS = os.path.join(WORKSPACE, "vajb-orbit/assets")
OUT_DIR = os.path.join(WORKSPACE, "staging/d2/mark_sheets")

COLS = 5
ROWS = 6
CELL_W = 300
CELL_H = 340
HEADER_H = 78
PER_SHEET = COLS * ROWS

C_BG = (31, 35, 40)
C_BG_ALT = (36, 40, 46)
C_GRID = (58, 66, 76)
C_TEXT = (222, 226, 232)
C_DIM = (150, 158, 168)
C_ID = (255, 255, 255)

FONT_DIR = "/usr/share/fonts/truetype/dejavu"


def _font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    path = os.path.join(FONT_DIR, name)
    if os.path.exists(path):
        return ImageFont.truetype(path, size)
    return ImageFont.load_default()


F_ID = _font(30, bold=True)
F_NAME = _font(15)
F_TAG = _font(13)
F_TITLE = _font(20, bold=True)
F_LEG = _font(14)

PAINTED = {
    "booster", "equip", "map", "status",
}
PAINTED_EXTRA = {"icon_ammo_laser", "icon_ammo_rocket"}

# Family reading order: ruling-named glyph families first, then the flat
# remainder, then the painted families, then parked alternates, then UI marks.
FAMILY_ORDER = [
    "slot", "contract", "service",
    "hud", "cargo", "weapon", "module", "mineral", "ingot", "insignia",
    "booster", "equip", "map", "status",
    "alt",
    "ui_insignia",
]


def classify(family, symbol):
    if family == "alt":
        return "alt-parked"
    if family == "ui_insignia":
        return "ui-emblem"
    if family in PAINTED or symbol in PAINTED_EXTRA:
        return "painted"
    return "flat-glyph"


def build_index():
    """Return the ordered cell list: dicts with id, name, family, cls, path, px."""
    entries = []
    icons_root = os.path.join(ASSETS, "icons")
    subdirs = sorted(
        d for d in os.listdir(icons_root) if os.path.isdir(os.path.join(icons_root, d))
    )
    for sub in subdirs:
        if sub == "tint":
            continue
        for f in sorted(os.listdir(os.path.join(icons_root, sub))):
            if not f.endswith(".png") or re.search(r"_(16|48|96|192)\.png$", f):
                continue
            entries.append({
                "name": f[:-4],
                "family": sub,
                "path": os.path.join(icons_root, sub, f),
            })
    ui_root = os.path.join(ASSETS, "ui")
    for f in sorted(os.listdir(ui_root)):
        if f.startswith("ui_insignia_") and f.endswith(".png"):
            entries.append({
                "name": f[:-4],
                "family": "ui_insignia",
                "path": os.path.join(ui_root, f),
            })

    order = {fam: i for i, fam in enumerate(FAMILY_ORDER)}
    entries.sort(key=lambda e: (order.get(e["family"], 99), e["name"]))
    for i, e in enumerate(entries, start=1):
        e["id"] = i
        e["cls"] = classify(e["family"], e["name"])
        with Image.open(e["path"]) as im:
            e["px"] = f"{im.width}x{im.height}"
    return entries


def wrap(draw, text, font, max_w, max_lines=2):
    words = text.split("_")
    lines, cur = [], ""
    for w in words:
        trial = (cur + "_" + w).strip("_")
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines[:max_lines]


def draw_cell(canvas, draw, entry, x, y):
    alt = entry["id"] % 2 == 0
    draw.rectangle([x, y, x + CELL_W - 1, y + CELL_H - 1],
                   fill=C_BG_ALT if alt else C_BG, outline=C_GRID)
    draw.text((x + 10, y + 6), f"#{entry['id']}", font=F_ID, fill=C_ID)
    art_box = (x + 20, y + 46, CELL_W - 40, 190)
    try:
        im = Image.open(entry["path"]).convert("RGBA")
        im.thumbnail((art_box[2], art_box[3]))
        tile = Image.new("RGBA", (art_box[2], art_box[3]), (0, 0, 0, 0))
        tile.paste(im, ((art_box[2] - im.width) // 2, (art_box[3] - im.height) // 2), im)
        canvas.paste(tile, (art_box[0], art_box[1]), tile)
    except Exception:
        draw.text((x + 12, y + 60), "ERR", font=F_NAME, fill=(255, 80, 80))
    lines = wrap(draw, entry["name"], F_NAME, CELL_W - 24)
    ty = y + 246
    for ln in lines:
        draw.text((x + 12, ty), ln, font=F_NAME, fill=C_TEXT)
        ty += 18
    draw.text((x + 12, y + CELL_H - 26),
              f"{entry['family']} · {entry['cls']} · {entry['px']}",
              font=F_TAG, fill=C_DIM)


def sheet_geometry():
    return {
        "cols": COLS, "rows": ROWS,
        "cell_w": CELL_W, "cell_h": CELL_H, "header_h": HEADER_H,
        "width": COLS * CELL_W,
        "height": HEADER_H + ROWS * CELL_H,
    }


def render_sheet(entries, sheet_no, n_sheets, out_path):
    g = sheet_geometry()
    canvas = Image.new("RGB", (g["width"], g["height"]), C_BG)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([0, 0, g["width"], HEADER_H - 1], fill=(20, 23, 27), outline=C_GRID)
    draw.text((14, 10),
              f"D2 icon unification - mark sheet {sheet_no}/{n_sheets}"
              f"   (cells #{entries[0]['id']}..#{entries[-1]['id']})",
              font=F_TITLE, fill=C_TEXT)
    draw.text((14, 40),
              "Red X = remade as SVG master. Blank = keep ONE raster master.",
              font=F_LEG, fill=C_TEXT)
    draw.text((14, 58),
              "Either way Phase C deletes every _16/_48/_96/_192 and @2x variant "
              "and the X'd symbols' tint stencils.",
              font=F_LEG, fill=C_DIM)
    for i, entry in enumerate(entries):
        r, c = divmod(i, COLS)
        draw_cell(canvas, draw, entry,
                  c * CELL_W, HEADER_H + r * CELL_H)
    canvas.save(out_path)
    return out_path


def write_index(entries, out_path):
    with open(out_path, "w", newline="") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["id", "name", "family", "cls", "px", "sheet", "cell"])
        for e in entries:
            sheet = (e["id"] - 1) // PER_SHEET + 1
            cell = (e["id"] - 1) % PER_SHEET + 1
            w.writerow([e["id"], e["name"], e["family"], e["cls"], e["px"], sheet, cell])
    return out_path


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    entries = build_index()
    n_sheets = (len(entries) + PER_SHEET - 1) // PER_SHEET
    print(f"cells: {len(entries)} -> {n_sheets} sheets of {PER_SHEET}")
    for s in range(n_sheets):
        chunk = entries[s * PER_SHEET:(s + 1) * PER_SHEET]
        out = os.path.join(OUT_DIR, f"D2_MARK_{s + 1:02d}.png")
        render_sheet(chunk, s + 1, n_sheets, out)
        print(out, os.path.getsize(out), "bytes")
    idx = write_index(entries, os.path.join(OUT_DIR, "MARK_INDEX.tsv"))
    print(idx)
    counts = {}
    for e in entries:
        counts[(e["family"], e["cls"])] = counts.get((e["family"], e["cls"]), 0) + 1
    for (fam, cls), n in sorted(counts.items()):
        print(f"  {fam:12s} {cls:12s} {n}")


if __name__ == "__main__":
    main()
