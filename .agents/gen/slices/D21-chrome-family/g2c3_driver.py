#!/usr/bin/env python3
"""D21-G2-B3 hands-on round (owner 2026-10-05: "do yourself a third flare
attempt, if doesnt work fallback"). Measures the four re-renders against the
crop law (UI_CHROME_ASSETS_SPEC.md 13.1) and lands the ones that pass.

Usage:
  python3 g2c3_driver.py measure <class> <png> [<class> <png> ...]
  python3 g2c3_driver.py land    <class> <png> [<class> <png> ...]

measure: ink box -> master-aspect crop-rect check -> fill; JSON to stdout.
land:    key -> ink box -> crop-to-master (centred, contains ink in full,
         a rect exceeding the frame is a FAIL, never a clip) -> one uniform
         resize to master pixels -> save under vajb-orbit/assets/ui/ at the
         13.4 stem. Prints a JSON report; a FAIL class is never landed.
"""
import json
import sys
from pathlib import Path

from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[4]
ASSETS = WORKSPACE / "vajb-orbit" / "assets" / "ui"
BACKUP = WORKSPACE / "asset-library" / "_prekey_backup" / "chrome_family_b3_2026-10-05"

MASTERS = {
    "C1": (1134, 280),   # ui_tile_slab 567x140
    "C2": (720, 112),    # ui_action_bar 360x56
    "C9": (720, 112),    # ui_drawer_entry 360x56
    "C5": (520, 384),    # ui_rack_bay_card 260x192
}
STEMS = {
    "C1": "ui_tile_slab.png",
    "C2": "ui_action_bar.png",
    "C9": "ui_drawer_entry.png",
    "C5": "ui_rack_bay_card.png",
}
FILL_MIN = {"C1": 0.80, "C2": 0.80, "C9": 0.80, "C5": 0.70}
A_THRESH = 8
COLOR_DIST = 28
DENSITY_MIN = 0.02
LUM_T = 34.0


def alpha_box(im):
    a = im.getchannel("A")
    mask = a.point(lambda v: 255 if v >= A_THRESH else 0)
    return mask.getbbox()


def region_grow_mask(im, step_tol=6):
    """Ink mask for opaque renders: binary luminance band plus hole-fill. The
    plate's hard border separates its dark interior from the painted void, so
    flooding the complement from the border leaves the interior enclosed.
    Ink pixels are 255."""
    px = im.convert("RGB")
    w, h = px.size
    ppx = px.load()
    band = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b = ppx[x, y]
            if 0.299 * r + 0.587 * g + 0.114 * b >= LUM_T:
                band[y][x] = 1
    out_bg = [[0] * w for _ in range(h)]
    stack = []
    for x in range(w):
        for yy in (0, h - 1):
            if not band[yy][x] and not out_bg[yy][x]:
                out_bg[yy][x] = 1
                stack.append((x, yy))
    for y in range(h):
        for xx in (0, w - 1):
            if not band[y][xx] and not out_bg[y][xx]:
                out_bg[y][xx] = 1
                stack.append((xx, y))
    head = 0
    while head < len(stack):
        x, y = stack[head]
        head += 1
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not band[ny][nx] and not out_bg[ny][nx]:
                out_bg[ny][nx] = 1
                stack.append((nx, ny))
    mask = Image.new("L", (w, h), 0)
    mpx = mask.load()
    for y in range(h):
        for x in range(w):
            if band[y][x] or not out_bg[y][x]:
                mpx[x, y] = 255
    return mask


def color_box(im):
    mask = region_grow_mask(im)
    w, h = im.size
    mpx = mask.load()
    cols = [sum(1 for y in range(h) if mpx[x, y]) for x in range(w)]
    rows = [sum(1 for x in range(w) if mpx[x, y]) for y in range(h)]
    x0 = next((x for x in range(w) if cols[x] >= DENSITY_MIN * h), 0)
    x1 = next((x for x in range(w - 1, -1, -1) if cols[x] >= DENSITY_MIN * h), w - 1)
    y0 = next((y for y in range(h) if rows[y] >= DENSITY_MIN * w), 0)
    y1 = next((y for y in range(h - 1, -1, -1) if rows[y] >= DENSITY_MIN * w), h - 1)
    return (x0, y0, x1 + 1, y1 + 1)


def analyse(cls, path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    a0 = sum(1 for p in im.getchannel("A").getdata() if p < A_THRESH) / float(w * h)
    box = alpha_box(im) if a0 > 0.10 else color_box(im)
    bx0, by0, bx1, by1 = box
    bw, bh = bx1 - bx0, by1 - by0
    mw, mh = MASTERS[cls]
    m = mw / float(mh)
    rw = max(bw, bh * m)
    rh = rw / m
    fits = rw <= w and rh <= h
    fill = min(bw / rw, bh / rh)
    return {
        "class": cls,
        "file": str(path),
        "pixels": [w, h],
        "alpha0_share": round(a0, 4),
        "ink_box": [bx0, by0, bx1, by1],
        "ink_wh": [bw, bh],
        "ink_aspect": round(bw / float(bh), 3),
        "master_aspect": round(m, 3),
        "crop_rect_wh": [round(rw), round(rh)],
        "crop_fits": bool(fits),
        "fill": round(fill, 4),
        "pass": bool(fits and fill >= FILL_MIN[cls]),
    }


def keyed_layer(im, a0):
    if a0 > 0.10:
        return im
    mask = region_grow_mask(im)
    out = im.copy()
    opx = out.load()
    mpx = mask.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if not mpx[x, y]:
                opx[x, y] = (0, 0, 0, 0)
    return out


def land(cls, path, force=False):
    info = analyse(cls, path)
    if not (info["pass"] or (force and info["crop_fits"])):
        info["landed"] = False
        info["reason"] = "crop-law or fill check failed - fallback for this class"
        return info
    im = Image.open(path).convert("RGBA")
    im = keyed_layer(im, info["alpha0_share"])
    bx0, by0, bx1, by1 = info["ink_box"]
    rw, rh = info["crop_rect_wh"]
    cx, cy = (bx0 + bx1) / 2.0, (by0 + by1) / 2.0
    rect = (round(cx - rw / 2.0), round(cy - rh / 2.0), round(cx + rw / 2.0), round(cy + rh / 2.0))
    mw, mh = MASTERS[cls]
    cut = im.crop(rect).resize((mw, mh), Image.LANCZOS)
    target = ASSETS / STEMS[cls]
    if target.exists():
        BACKUP.mkdir(parents=True, exist_ok=True)
        backup = BACKUP / STEMS[cls]
        backup.write_bytes(target.read_bytes())
        info["backup"] = str(backup)
    target.parent.mkdir(parents=True, exist_ok=True)
    cut.save(target)
    info["landed"] = str(target)
    info["crop_rect"] = list(rect)
    return info


def main():
    args = sys.argv[1:]
    if len(args) < 3 or len(args) % 2 == 0:
        print(__doc__)
        return 1
    op, pairs = args[0], zip(args[1::2], args[2::2])
    out = []
    for cls, png in pairs:
        if cls not in MASTERS:
            print(f"unknown class {cls}", file=sys.stderr)
            return 1
        if op in ("land", "force"):
            out.append(land(cls, png, force=(op == "force")))
        else:
            out.append(analyse(cls, png))
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
