"""D21-G2 driver: key, ink-box, crop-to-master, resize, centre, margins, land.

Pure Pillow (no numpy in this env). Never hand-edits a PNG: every pixel op here
is scripted. Writes: landed cuts under vajb-orbit/assets/ui/, swap backups under
asset-library/_prekey_backup/chrome_family_2026-10-05/, QC sheets under
asset-library/_review/, evidence JSON in this slice folder.

Usage: python3 g2_driver.py run
"""
from __future__ import annotations

import hashlib
import json
import math
import random
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

WS = Path(__file__).resolve().parents[4]
RAW = WS / "asset-library" / "raw" / "chrome-family"
UI = WS / "vajb-orbit" / "assets" / "ui"
BACKUP = WS / "asset-library" / "_prekey_backup" / "chrome_family_2026-10-05"
REVIEW = WS / "asset-library" / "_review"
SLICE = WS / ".agents" / "gen" / "slices" / "D21-chrome-family"
SRC = "grimdark-painted-sci-fi-semi-realistic-1.png"

INK_T = 48          # alpha that counts as ink for boxes
TRIM_T = 12         # substrate trim: alpha below this goes to 0
CENTRE_TOL = 2      # centre-check tolerance, px (center_check.py semantics)
MARGIN_PASS = 2     # +/-1 px at native size == +/-2 px at master

CLASSES = {
    "C1": dict(dir="20261005-201427", master=(1134, 280), route="crop", key="trim",
               stems=["ui_tile_slab"], swap=[], state=True, use=(567, 140),
               margins=(16, 16, 16, 16)),
    "C2": dict(dir="20261005-201500", master=(720, 112), route="crop", key="strip",
               stems=["ui_action_bar"], swap=[], state=True, use=(360, 56),
               margins=(20, 20, 12, 12), strip_tol=26),
    "C3": dict(dir="20261005-201604", master=(192, 64), route="crop", key="trim",
               stems=["ui_inline_chip"], swap=[], state=True, use=(96, 32),
               margins=(8, 8, 8, 8)),
    "C4": dict(dir="20261005-201632", master=(1120, 152), route="crop", key="trim",
               stems=["ui_row_strip"], swap=[], state=True, use=(560, 76),
               margins=(12, 12, 8, 8)),
    "C5": dict(dir="20261005-201700", master=(520, 384), route="crop", key="trim",
               stems=["ui_rack_bay_card"], swap=[], state=False, use=(260, 192),
               margins=(10, 10, 10, 10)),
    "C6": dict(dir="20261005-201732", master=(2720, 1032), route="crop", key="trim",
               stems=["ui_armory_console"], swap=["ui_armory_console.png"],
               state=False, use=None, margins=None),
    "C7": dict(dir="20261005-202052", master=(720, 480), route="direct", key="trim",
               stems=["ui_tooltip_frame"], swap=[], state=False, use=(360, 240),
               margins=(12, 12, 12, 12)),
    "C8": dict(dir="20261005-202141", master=(112, 112), route="direct", key="strip",
               stems=["ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
                      "ui_slot_inventory_normal.png"],
               swap=["ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
                     "ui_slot_inventory_normal.png"],
               state=True, use=None, margins=None, strip_tol=20),
    "C9": dict(dir="20261005-202203", master=(720, 112), route="crop", key="trim",
               stems=["ui_drawer_entry"], swap=[], state=True, use=(272, 56),
               margins=(16, 16, 8, 8)),
    "C10": dict(dir="20261005-202312", master=(84, 28), route="crop", key="trim",
                stems=["ui_bar_caps"], swap=["ui_bar_caps.png"],
                state=False, use=None, margins=None),
    "C11": dict(dir="20261005-202401", master=(400, 400), route="direct", key="strip",
                stems=["ui_minimap_bezel"], swap=["ui_minimap_bezel.png"],
                state=False, use=(200, 200), margins=(16, 16, 16, 16), strip_tol=22),
    "C12": dict(dir="20261005-202444", master=(192, 192), route="direct", key="strip",
                stems=["ui_panel_frame"], swap=["ui_panel_frame.png"],
                state=False, use=(96, 96), margins=(32, 32, 32, 32), strip_tol=22),
    "BG-1": dict(dir="20261005-202512", master=(2048, 874), route="backdrop", key="none",
                 stems=["ui_backdrop_armory_deck"], swap=[], state=False, use=None,
                 margins=None),
    "BG-2": dict(dir="20261005-202550", master=(2048, 874), route="backdrop", key="none",
                 stems=["ui_backdrop_refinery_deck"], swap=[], state=False, use=None,
                 margins=None),
    "BG-3": dict(dir="20261005-202617", master=(2048, 874), route="backdrop", key="none",
                 stems=["ui_backdrop_market_deck"], swap=[], state=False, use=None,
                 margins=None),
    "BG-4": dict(dir="20261005-203106", master=(2048, 874), route="backdrop", key="none",
                 stems=["ui_backdrop_dock_deck"], swap=[], state=False, use=None,
                 margins=None),
}
STATE_SHEET_CLASSES = ["C2", "C3", "C4", "C8"]  # state-bearing AND landed
UNIFORM_BAND_CLASSES = ["C7", "C11", "C12"]


def load(rid: str) -> Image.Image:
    return Image.open(RAW / CLASSES[rid]["dir"] / SRC)


def substrate_trim(img: Image.Image) -> Image.Image:
    a = img.getchannel("A").point(lambda v: 0 if v < TRIM_T else v)
    out = img.copy()
    out.putalpha(a)
    return out


def border_median(rgb: Image.Image, band: int = 8) -> tuple[int, int, int]:
    w, h = rgb.size
    strips = [rgb.crop((0, 0, w, band)), rgb.crop((0, h - band, w, h)),
              rgb.crop((0, 0, band, h)), rgb.crop((w - band, 0, w, h))]
    px: list[tuple] = []
    for s in strips:
        px.extend(list(s.getdata()))
    px.sort(key=lambda p: max(p))
    return px[len(px) // 2]


def skeleton_box(dist: Image.Image, thresh: int = 55, density: int = 2):
    """Plate bounds from bright plate structure via dense row/col profiles.

    A row/column counts only when at least `density`/255 of its pixels are
    skeleton ink, so scattered field specks cannot inflate the box.
    """
    sk = dist.point(lambda v: 255 if v >= thresh else 0)
    w, h = dist.size
    rows = sk.resize((1, h), Image.BOX).point(lambda v: 255 if v >= density else 0)
    cols = sk.resize((w, 1), Image.BOX).point(lambda v: 255 if v >= density else 0)
    rb, cb = rows.getbbox(), cols.getbbox()
    if rb is None or cb is None:
        return None
    return (cb[0], rb[1], cb[2], rb[3])


def strip_key(img: Image.Image, tol: int) -> tuple[Image.Image, dict]:
    """Local background-strip fallback key.

    Border-connected dark flood at half resolution, healed at full resolution,
    with enclosed-interior leak detection (ink solidity) and a tolerance ladder.
    A class whose plate fills its frame refuses the key and lands opaque.
    """
    rgb = img.convert("RGB")
    w, h = img.size
    bg = border_median(rgb)
    stats = {"bg_med": list(bg)}
    if max(bg) > 40:
        stats["route"] = "strip-key refused: border band is plate grey, not void substrate"
        return img.copy(), stats
    diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg))
    r, g, b = diff.split()
    dist = ImageChops.lighter(ImageChops.lighter(r, g), b)

    box = skeleton_box(dist)
    if box is None:
        stats["route"] = "strip-key refused: no bright plate structure found"
        return img.copy(), stats

    sw, sh = w // 2, h // 2
    dark_full = dist.point(lambda v: 255 if v <= tol else 0)
    alpha0 = img.getchannel("A")
    flooded_work = None
    ladder = [tol, max(10, tol - 8), max(10, tol - 16), max(10, tol - 24)]
    tried = []
    for t in ladder:
        dark = dist.point(lambda v, tt=t: 255 if v <= tt else 0)
        small = dark.resize((sw, sh), Image.BOX).point(lambda v: 255 if v >= 250 else 0)
        work = small.copy()
        seeds = 0
        step = 16
        for x in range(0, sw, step):
            for sy in (1, sh - 2):
                if work.getpixel((x, sy)) == 255:
                    ImageDraw.floodfill(work, (x, sy), 128, thresh=0)
                    seeds += 1
        for y in range(0, sh, step):
            for sx in (1, sw - 2):
                if work.getpixel((sx, y)) == 255:
                    ImageDraw.floodfill(work, (sx, y), 128, thresh=0)
                    seeds += 1
        grown = work.point(lambda v: 255 if v == 128 else 0)
        grown = grown.resize((w, h), Image.NEAREST)
        grown = ImageChops.multiply(grown, dark)
        for _ in range(60):  # heal the blocky fringe + fine remnants
            nxt = ImageChops.multiply(grown.filter(ImageFilter.MaxFilter(3)), dark)
            if ImageChops.difference(grown, nxt).getextrema()[1] == 0:
                break
            grown = nxt
        keep = grown.point(lambda v: 255 - v)
        inside_box = keep.crop(box).histogram()[255]
        solidity = inside_box / max(1, (box[2] - box[0]) * (box[3] - box[1]))
        tried.append({"tol": t, "seeds": seeds,
                      "flood_share": round(1 - keep.histogram()[255] / (w * h), 4),
                      "ink_box": list(box), "solidity": round(solidity, 3)})
        if solidity >= 0.45:
            flooded_work = grown
            break
    stats["ladder"] = tried
    if flooded_work is None:
        stats["route"] = ("strip-key refused after ladder: every tolerance leaks "
                          "into the enclosed interior; landed opaque like the "
                          "shipped convention")
        return img.copy(), stats

    # everything outside the plate box is substrate by definition: clamp keep
    pad_box = (max(0, box[0] - 4), max(0, box[1] - 4),
               min(w, box[2] + 4), min(h, box[3] + 4))
    inside = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inside).rectangle(pad_box, fill=255)
    keep_final = ImageChops.multiply(keep, inside)
    keep_soft = keep_final.filter(ImageFilter.GaussianBlur(1.2))
    alpha_new = ImageChops.darker(alpha0, keep_soft)
    out = img.copy()
    out.putalpha(alpha_new)
    stats["route"] = f"strip-key border-connected dark flood (tol ladder from {tol})"
    return out, stats


def ink_box(img: Image.Image):
    hard = img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
    return hard.getbbox()


def ink_stats(img: Image.Image) -> dict:
    if img.mode != "RGBA":
        w, h = img.size
        return {"box": [0, 0, w, h], "ink_px": w * h, "solidity": 1.0,
                "note": "opaque RGB render"}
    hard = img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
    box = hard.getbbox()
    if box is None:
        return {"box": None}
    n = hard.histogram()[255]
    area = (box[2] - box[0]) * (box[3] - box[1])
    return {"box": list(box), "ink_px": n, "solidity": round(n / max(1, area), 3)}


def crop_rect_masterAspect(ink, aspect: float, frame):
    """Smallest centred rect at `aspect` containing ink; None if it cannot fit."""
    il, it, ir, ib = ink
    iw, ih = ir - il, ib - it
    w = max(iw, math.ceil(ih * aspect))
    h = max(ih, math.ceil(w / aspect))
    w = max(iw, math.ceil(h * aspect))
    h = max(ih, math.ceil(w / aspect))
    if w > frame[0] or h > frame[1]:
        return None
    cx, cy = (il + ir) / 2.0, (it + ib) / 2.0
    x0 = int(round(cx - w / 2.0))
    y0 = int(round(cy - h / 2.0))
    x0 = max(0, min(x0, frame[0] - w))
    y0 = max(0, min(y0, frame[1] - h))
    return (x0, y0, x0 + w, y0 + h)


def centre_offset(img: Image.Image):
    a = img.getchannel("A")
    box = a.point(lambda v: 255 if v > 0 else 0).getbbox()
    if box is None:
        return None, None
    w, h = img.size
    cx = (box[0] + box[2]) / 2.0
    cy = (box[1] + box[3]) / 2.0
    return (round(cx - (w - 1) / 2.0, 2), round(cy - (h - 1) / 2.0, 2)), box


def centre_apply(path: Path, tol: int = CENTRE_TOL) -> dict:
    """center_check.py semantics: shift by -offset, verify, roll back if worse."""
    img = Image.open(path).convert("RGBA")
    off, _ = centre_offset(img)
    if off is None:
        return {"skipped": "empty"}
    dx, dy = -int(round(off[0])), -int(round(off[1]))
    if abs(dx) <= tol and abs(dy) <= tol:
        return {"offset_before": off, "shift": [0, 0], "offset_after": off}
    w, h = img.size
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(img, (dx, dy))
    off_after, _ = centre_offset(canvas)
    better = (abs(off_after[0]) <= abs(off[0])
              and abs(off_after[1]) <= abs(off[1]))
    if better:
        canvas.save(path)
        return {"offset_before": off, "shift": [dx, dy], "offset_after": off_after,
                "applied": True}
    return {"offset_before": off, "shift": [0, 0], "offset_after": off,
            "rolled_back": True}


def _band_scan(img: Image.Image, side: str, band_frac: float = 0.4) -> int:
    """Distance from the canvas edge to the sustained flat interior plateau.

    Forward scan from the edge; the run must persist (run_len more columns
    within 2x tolerance), so edge vignettes and bevel faces cannot read as
    interior. Alpha-zero (keyed pad) columns never count.
    """
    a = img.getchannel("A")
    grey = img.convert("L")
    w, h = img.size
    horizontal = side in ("l", "r")
    n = w if horizontal else h
    m = h if horizontal else w
    lo, hi = int(m * (0.5 - band_frac / 2)), int(m * (0.5 + band_frac / 2))
    run_len, flat_tol, opaque_min = 8, 2.5, 200
    limit = n // 2

    def col_mean(i: int):
        box = (i, lo, i + 1, hi) if horizontal else (lo, i, hi, i + 1)
        al = a.crop(box)
        if al.getextrema()[0] < opaque_min:
            return None
        lum = list(grey.crop(box).getdata())
        return sum(lum) / len(lum)

    means = [col_mean(i) for i in range(limit)]
    known = [v for v in means if v is not None]
    if len(known) < run_len + 4:
        return -1
    ref = sorted(known)[len(known) // 2]
    count = 0
    for i, val in enumerate(means):
        if val is None or abs(val - ref) > flat_tol:
            count = 0
            continue
        count += 1
        if count >= run_len:
            end = min(limit, i + 1 + run_len)
            tail = [v for v in means[i + 1:end] if v is not None]
            if tail and all(abs(v - ref) <= 2 * flat_tol for v in tail):
                return i - run_len + 1
            count = run_len  # keep the run alive while it persists
    return -1


def _band_end_scan(img: Image.Image, side: str, bright: int = 50,
                   run: int = 6) -> int:
    """End of the first sustained bright ornament band from the edge.

    Dark-on-dark art (a shadowed outer edge matching a dark interior) defeats
    the flat-plateau scan; a metal band's bright face does not. The nine-slice
    margin must cover every bright band, so the margin is the max of both
    scans. Alpha-zero (keyed pad) columns are skipped.
    """
    a = img.getchannel("A")
    grey = img.convert("L")
    w, h = img.size
    horizontal = side in ("l", "r")
    n = w if horizontal else h
    m = h if horizontal else w
    lo, hi = int(m * (0.5 - 0.2)), int(m * (0.5 + 0.2))
    limit = n // 2

    def col_mean(i: int):
        box = (i, lo, i + 1, hi) if horizontal else (lo, i, hi, i + 1)
        al = a.crop(box)
        if al.getextrema()[0] < 200:
            return None
        lum = list(grey.crop(box).getdata())
        return sum(lum) / len(lum)

    means = [col_mean(i) for i in range(limit)]
    i = 0
    while i < limit and means[i] is None:
        i += 1
    while i < limit:
        v = means[i]
        if v is not None and v >= bright:
            j = i
            while j < limit and means[j] is not None and means[j] >= bright - 10:
                j += 1
            if j - i >= run:
                return j
            i = max(j, i + 1)
        else:
            i += 1
    return 0


def measure_margins(img: Image.Image) -> dict:
    plateaus = {s: _band_scan(img, s) for s in ("l", "r", "t", "b")}
    bands = {s: _band_end_scan(img, s) for s in ("l", "r", "t", "b")}
    return {s: max(plateaus[s], bands[s]) for s in plateaus}, plateaus, bands


def pad_from_ink(img: Image.Image) -> dict:
    hard = img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
    box = hard.getbbox()
    if box is None:
        return {}
    w, h = img.size
    return {"l": box[0], "t": box[1], "r": w - 1 - box[2], "b": h - 1 - box[3]}


def uniform_band_check(img: Image.Image, margins: dict) -> dict:
    """Each edge band identical along its run (p95 row deviation <= 8)."""
    grey = img.convert("L")
    w, h = img.size
    out = {}
    for key in ("l", "r", "t", "b"):
        m = margins.get(key, -1)
        if m is None or m <= 0:
            m = 12
        m = max(2, min(m, w // 4 if key in ("l", "r") else h // 4))
        if key in ("l", "r"):
            x0 = 0 if key == "l" else w - m
            strip = grey.crop((x0, int(h * 0.2), x0 + m, int(h * 0.8)))
            across = strip.size[1]
        else:
            y0 = 0 if key == "t" else h - m
            strip = grey.crop((int(w * 0.2), y0, int(w * 0.8), y0 + m))
            across = strip.size[0]
        profiles = []
        for i in range(across):
            if key in ("l", "r"):
                row = list(strip.crop((0, i, strip.size[0], i + 1)).getdata())
            else:
                row = list(strip.crop((i, 0, i + 1, strip.size[1])).getdata())
            profiles.append(row)
        width = len(profiles[0])
        med = [sorted(p[j] for p in profiles)[len(profiles) // 2]
               for j in range(width)]
        devs = sorted(sum(abs(v - med[j]) for j, v in enumerate(p)) / width
                      for p in profiles)
        p95 = devs[int(len(devs) * 0.95)]
        out[key] = {"band_px": m, "p95": round(p95, 2), "max": round(devs[-1], 2),
                    "pass": p95 <= 8.0}
    return out


def containment(img: Image.Image, rect, frame) -> dict:
    """Share of the render's ink pixels that land inside the crop rect."""
    if img.mode != "RGBA":
        return {"ink_px": frame[0] * frame[1],
                "inside": (rect[2] - rect[0]) * (rect[3] - rect[1]), "pct": 100.0}
    hard = img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
    total = hard.histogram()[255]
    inside = hard.crop(rect).histogram()[255]
    return {"ink_px": total, "inside": inside,
            "pct": round(100.0 * inside / max(1, total), 2)}


def gen_uid() -> str:
    cs = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    n = random.getrandbits(60) | (1 << 59)
    txt = ""
    while n:
        txt = cs[n % 62] + txt
        n //= 62
    return "uid://" + txt


IMPORT_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{name}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/ui/{name}"
dest_files=["res://.godot/imported/{name}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


def write_import(name: str) -> None:
    md5 = hashlib.md5(f"res://assets/ui/{name}".encode()).hexdigest()
    (UI / f"{name}.import").write_text(
        IMPORT_TEMPLATE.format(uid=gen_uid(), name=name, md5=md5), encoding="utf-8")


def checker(size, cell: int = 16) -> Image.Image:
    tile = Image.new("RGB", (cell * 2, cell * 2), (58, 60, 66))
    d = ImageDraw.Draw(tile)
    d.rectangle([0, 0, cell - 1, cell - 1], fill=(84, 86, 92))
    d.rectangle([cell, cell, cell * 2 - 1, cell * 2 - 1], fill=(84, 86, 92))
    rgba = tile.convert("RGBA")
    return rgba.resize(size, Image.NEAREST)


def dim_copy(rgba: Image.Image, mul: float) -> Image.Image:
    r, g, b, a = rgba.split()
    r = r.point(lambda v: int(v * mul))
    g = g.point(lambda v: int(v * mul))
    b = b.point(lambda v: int(v * mul))
    return Image.merge("RGBA", (r, g, b, a))


def run() -> None:
    evidence = {"classes": {}, "swaps": [], "variants": "NONE", "failures": []}
    BACKUP.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    landed_files: list[tuple[str, str, Path, dict]] = []

    for rid, cfg in CLASSES.items():
        rec: dict = {"dir": cfg["dir"], "master": list(cfg["master"]),
                     "route": cfg["route"]}
        img = load(rid)
        rec["render_px"] = list(img.size)
        frame = img.size

        if cfg["key"] == "trim":
            img = substrate_trim(img)
            rec["key_route"] = f"substrate trim (alpha < {TRIM_T} -> 0)"
        elif cfg["key"] == "strip":
            img, kstats = strip_key(img, cfg.get("strip_tol", 22))
            rec["key_route"] = kstats["route"]
            rec["key_stats"] = {k: v for k, v in kstats.items() if k != "route"}
        else:
            rec["key_route"] = "none (opaque backdrop, never keyed)"

        istats = ink_stats(img)
        rec["ink"] = istats
        ink = istats["box"]
        aspect = cfg["master"][0] / cfg["master"][1]

        if cfg["route"] == "crop":
            rect = crop_rect_masterAspect(ink, aspect, frame) if ink else None
            if rect is None:
                w_need = max(ink[2] - ink[0], math.ceil((ink[3] - ink[1]) * aspect))
                h_need = math.ceil(w_need / aspect)
                rec["verdict"] = "FAIL crop-to-master"
                rec["fail_cause"] = (f"master-aspect rect {w_need}x{h_need} exceeds "
                                     f"frame {frame[0]}x{frame[1]}; never clipped")
                evidence["failures"].append({"id": rid, "cause": rec["fail_cause"],
                                             "ink": istats})
                evidence["classes"][rid] = rec
                print(f"{rid}: FAIL - {rec['fail_cause']}")
                continue
            rec["crop_rect"] = list(rect)
            rec["containment"] = containment(img, rect, frame)
            cut = img.crop(rect).resize(cfg["master"], Image.LANCZOS)
            rec["resize_factors"] = [
                round(cfg["master"][0] / (rect[2] - rect[0]), 6),
                round(cfg["master"][1] / (rect[3] - rect[1]), 6)]
        elif cfg["route"] == "direct":
            rect = (0, 0, frame[0], frame[1])
            rec["containment"] = containment(img, rect, frame)
            cut = img.resize(cfg["master"], Image.LANCZOS)
            rec["resize_factors"] = [round(cfg["master"][0] / frame[0], 6),
                                     round(cfg["master"][1] / frame[1], 6)]
        else:  # backdrop: largest centred rect at master aspect + 2 px trim chain
            aw, ah = cfg["master"]
            ch = min(frame[1], round(frame[0] * ah / aw))
            cw = round(ch * aw / ah)
            if cw > frame[0]:
                cw = frame[0]
                ch = round(cw * ah / aw)
            y0 = (frame[1] - ch) // 2
            rect = (0, y0, cw, y0 + ch)
            rec["crop_rect"] = list(rect)
            trimmed = img.crop(rect).crop((2, 2, cw - 2, ch - 2))
            tw, th = trimmed.size
            scale = ah / th
            grown = trimmed.resize((round(tw * scale), ah), Image.LANCZOS)
            gw, gh = grown.size
            cut = grown.crop(((gw - aw) // 2, 0, (gw - aw) // 2 + aw, gh))
            rec["resize_factors"] = [round(scale, 6), round(scale, 6)]
            rec["resize_note"] = (f"crop {cw}x{ch} at master aspect -> trim 2 px/side "
                                  f"-> {tw}x{th} -> one scale {round(scale, 6)} -> "
                                  f"{grown.size} -> trim 2 px/side horizontal -> "
                                  f"{list(cut.size)}")
            rec["containment"] = {"ink_px": frame[0] * frame[1],
                                  "inside": (rect[2] - rect[0]) * (rect[3] - rect[1]),
                                  "pct": 100.0}

        if cfg["route"] != "backdrop":
            tmp = SLICE / f"_tmp_{rid}.png"
            cut.save(tmp)
            rec["centre_check"] = centre_apply(tmp)
            cut = Image.open(tmp)
            tmp.unlink()
        else:
            rec["centre_check"] = "exempt (full-bleed cover)"

        if cfg["margins"]:
            mm, plateaus, bands = measure_margins(cut)
            rec["margins_master"] = mm
            rec["margins_plateau_scan"] = plateaus
            rec["margins_band_scan"] = bands
            rec["pad_from_ink"] = pad_from_ink(cut)
            declared_master = [2 * v for v in cfg["margins"]]
            rec["margins_declared_master"] = declared_master
            rec["margins_pass"] = all(
                mm[s] >= 0 and abs(mm[s] - d) <= MARGIN_PASS
                for s, d in zip(("l", "r", "t", "b"), declared_master))
        else:
            rec["margins_master"] = None
            rec["margins_declared_master"] = None
            rec["margins_pass"] = None

        if rid in UNIFORM_BAND_CLASSES:
            rec["uniform_band"] = uniform_band_check(cut, rec["margins_master"])
            rec["uniform_band_pass"] = all(v["pass"] for v in
                                           rec["uniform_band"].values())

        hard = (cut.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
                if cut.mode == "RGBA" else None)
        if hard is not None:
            lb = hard.getbbox()
            rec["landed_ink_box"] = list(lb) if lb else None
            rec["ink_fill_pct"] = round(100.0 * hard.histogram()[255]
                                        / (cut.size[0] * cut.size[1]), 2)
        else:
            rec["landed_ink_box"] = [0, 0, *cut.size]
            rec["ink_fill_pct"] = 100.0

        out_img = cut.convert("RGB") if cfg["route"] == "backdrop" else cut
        for stem in cfg["stems"]:
            name = stem if stem.endswith(".png") else f"{stem}.png"
            target = UI / name
            if name in cfg["swap"]:
                backup_file = BACKUP / name
                if backup_file.exists():
                    old_img = Image.open(backup_file)
                    old_md5 = hashlib.md5(backup_file.read_bytes()).hexdigest()
                else:
                    old_md5 = hashlib.md5(target.read_bytes()).hexdigest()
                    old_img = Image.open(target)
                    shutil.move(str(target), backup_file)
                evidence["swaps"].append({
                    "class": rid, "shipped": f"assets/ui/{name}",
                    "backup": ("asset-library/_prekey_backup/"
                               f"chrome_family_2026-10-05/{name}"),
                    "old_px": list(old_img.size), "old_md5": old_md5,
                    "new_px": list(cfg["master"])})
            elif not target.exists():
                write_import(name)
            out_img.save(target)
            landed_files.append((rid, name, target, rec))
        rec["landed"] = [s if s.endswith(".png") else s + ".png"
                         for s in cfg["stems"]]
        rec["verdict"] = "LANDED"
        evidence["classes"][rid] = rec
        print(f"{rid}: LANDED {rec['landed']} margins={rec['margins_master']} "
              f"fill={rec['ink_fill_pct']}% pass={rec['margins_pass']}")

    (BACKUP / "manifest.json").write_text(json.dumps(
        {"date": "2026-10-05", "wave": "D21-G2", "swaps": evidence["swaps"]},
        indent=1), encoding="utf-8")

    build_state_sheet()
    build_contact_sheet(landed_files, evidence)

    (SLICE / "g2_evidence.json").write_text(json.dumps(evidence, indent=1),
                                            encoding="utf-8")
    print("evidence -> g2_evidence.json")


def build_state_sheet() -> None:
    tile_w, tile_h = 300, 120
    sheet = Image.new("RGB", (tile_w * 3 + 32,
                              tile_h * len(STATE_SHEET_CLASSES) + 40), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), "state QC: normal | modulate x0.60 | modulate x0.45",
           fill=(200, 200, 200))
    for row, rid in enumerate(STATE_SHEET_CLASSES):
        stem = CLASSES[rid]["stems"][0]
        path = UI / (stem if stem.endswith(".png") else stem + ".png")
        if not path.exists():
            d.text((16, 30 + row * tile_h - 12),
                   f"{rid} {stem} - no landed cut (state QC n/a)",
                   fill=(200, 140, 130))
            continue
        art = Image.open(path).convert("RGBA")
        art.thumbnail((tile_w - 24, tile_h - 24), Image.LANCZOS)
        base = checker(art.size, 8)
        base.alpha_composite(art)
        for col, mul in enumerate((1.0, 0.60, 0.45)):
            cell = base if mul == 1.0 else dim_copy(base, mul)
            x = 16 + col * tile_w + (tile_w - 24 - art.size[0]) // 2
            y = 30 + row * tile_h + (tile_h - 24 - art.size[1]) // 2
            sheet.paste(cell.convert("RGB"), (x, y))
        d.text((16, 30 + row * tile_h - 12),
               f"{rid} {CLASSES[rid]['stems'][0]}", fill=(220, 220, 220))
    sheet.save(REVIEW / "qc_state_modulate_2026-10-05.png")
    small = sheet.copy()
    small.thumbnail((900, 900), Image.LANCZOS)
    small.save(REVIEW / "qc_state_modulate_2026-10-05_view.jpg", "JPEG", quality=78)
    print("state QC sheet -> _review/qc_state_modulate_2026-10-05.png")


def build_contact_sheet(landed_files, evidence) -> None:
    fails = [(rid, rec) for rid, rec in evidence["classes"].items()
             if rec.get("verdict") != "LANDED"]
    tiles = []
    seen = set()
    for rid, name, path, rec in landed_files:
        if rid == "C8":
            if rid in seen:
                continue
            seen.add(rid)
            label = "C8 ui_slot_weapon/cargo/inventory_normal (one master)"
        else:
            label = f"{rid} {name}"
        tiles.append((label, path, rec, False))
    for rid, rec in fails:
        tiles.append((f"{rid} FAIL", None, rec, True))
    cols, tile, pad, label_h = 4, 330, 10, 30
    rows = (len(tiles) + cols - 1) // cols
    W = cols * (tile + pad) + pad
    H = rows * (tile + pad + label_h) + pad + 26
    sheet = Image.new("RGB", (W, H), (14, 16, 20))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 6), "D21-G2 chrome family cuts - landed 2026-10-05 "
                     "(checker = transparency)", fill=(210, 214, 220))
    for i, (label, path, rec, is_fail) in enumerate(tiles):
        x = pad + (i % cols) * (tile + pad)
        y = 26 + (i // cols) * (tile + pad + label_h)
        if is_fail:
            d.rectangle([x, y, x + tile, y + tile], fill=(30, 22, 22),
                        outline=(160, 60, 50))
            d.text((x + 8, y + tile // 2), "no cut landed", fill=(200, 120, 110))
        else:
            art = Image.open(path).convert("RGBA")
            amin = art.getchannel("A").getextrema()[0]
            bg = checker(art.size, 14) if amin < 250 else Image.new(
                "RGBA", art.size, (20, 22, 26, 255))
            bg.alpha_composite(art)
            bg.thumbnail((tile, tile), Image.LANCZOS)
            sheet.paste(bg.convert("RGB"), (x + (tile - bg.size[0]) // 2,
                                            y + (tile - bg.size[1]) // 2))
        mm = rec.get("margins_master")
        mtxt = ("margins n/a" if mm is None else
                "margins L{l} R{r} T{t} B{b}".format(**mm))
        d.text((x + 2, y + tile + 2), label[:56], fill=(225, 225, 225))
        d.text((x + 2, y + tile + 14),
               f"{rec['master'][0]}x{rec['master'][1]}  {mtxt}",
               fill=(170, 200, 170) if not is_fail else (200, 140, 130))
    sheet.save(REVIEW / "chrome_family_cuts_2026-10-05.png")
    small = sheet.copy()
    small.thumbnail((1100, 1100), Image.LANCZOS)
    small.save(REVIEW / "chrome_family_cuts_2026-10-05_view.jpg", "JPEG", quality=80)
    print("contact sheet -> _review/chrome_family_cuts_2026-10-05.png")


if __name__ == "__main__":
    run()