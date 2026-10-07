#!/usr/bin/env python3
"""S36-R1 independent measurement pass (Pillow).

Measures every chrome-family cut and keep-list texture:
  * pixel size + aspect (vs the class master within 1 percent),
  * per-side ink extent (the composite criterion: alpha < 250 or a colour
    channel deviating > 24 from the inner-plateau median),
  * band uniformity at the wired margin (max cross-section deviation),
  * the keep-list shipped sizes.

Read-only; prints one line per file. Never writes an asset.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

UI = Path(__file__).resolve().parents[1] / "assets" / "ui"

MASTERS = {
    "C1": (567.0, 140.0), "C2": (360.0, 56.0), "C3": (96.0, 32.0),
    "C4": (560.0, 76.0), "C5": (260.0, 192.0), "C6": (1360.0, 516.0),
    "C7": (360.0, 240.0), "C9": (272.0, 56.0), "C9_cut": (360.0, 56.0),
    "C12": (96.0, 96.0), "C13": (1765.0, 753.0),
}
CUTS = {
    "C1": "ui_tile_slab.png", "C2": "ui_action_bar.png", "C3": "ui_inline_chip.png",
    "C4": "ui_row_strip.png", "C5": "ui_rack_bay_card.png", "C6": "ui_armory_console.png",
    "C7": "ui_tooltip_frame.png", "C9": "ui_drawer_entry.png", "C12": "ui_panel_frame.png",
}
BGS = {
    "BG-1": "ui_backdrop_armory_deck.png", "BG-2": "ui_backdrop_refinery_deck.png",
    "BG-3": "ui_backdrop_market_deck.png", "BG-4": "ui_backdrop_dock_deck.png",
}
KEEP = {
    "ui_slot_weapon_normal.png": (48, 48), "ui_bar_caps.png": (42, 14),
    "ui_minimap_bezel.png": (200, 200),
}
WIRED = {  # texture px, l/r/t/b, from ui/theme/chrome_family.gd MARGINS
    "C3": (24, 34, 23, 39), "C4": (74, 74, 35, 49), "C7": (22, 43, 50, 64),
}


def ink_extents(im: Image.Image) -> tuple[int, int, int, int]:
    """Per-side max depth of any ink pixel (alpha < 250 or |c - plateau| > 24)."""
    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    mid = px[w // 2, h // 2]
    plateau = (mid[0], mid[1], mid[2])

    def ink(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        if a < 250:
            return True
        return abs(r - plateau[0]) > 24 or abs(g - plateau[1]) > 24 or abs(b - plateau[2]) > 24

    l = next((x for x in range(w) if any(ink(x, y) for y in range(h))), w)
    r = next((x for x in range(w - 1, -1, -1) if any(ink(x, y) for y in range(h))), -1)
    t = next((y for y in range(h) if any(ink(x, y) for x in range(w))), h)
    b = next((y for y in range(h - 1, -1, -1) if any(ink(x, y) for x in range(w))), -1)
    return (l, w - 1 - r if r >= 0 else w, t, h - 1 - b if b >= 0 else h)


def band_deviation(im: Image.Image, m: tuple[int, int, int, int]) -> dict:
    """Max per-cross-section deviation inside each wired margin band."""
    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def dev(cells: list[tuple]) -> float:
        vals = [(c[0], c[1], c[2]) for c in cells if c[3] >= 250]
        if len(vals) < 2:
            return 0.0
        med = [sorted(v[i] for v in vals)[len(vals) // 2] for i in range(3)]
        return max(max(abs(v[i] - med[i]) for i in range(3)) for v in vals)

    out = {}
    left = max(dev([px[x, y] for y in range(h)]) for x in range(min(m[0], w)))
    right = max(dev([px[x, y] for y in range(h)]) for x in range(w - min(m[1], w), w))
    top = max(dev([px[x, y] for x in range(w)]) for y in range(min(m[2], h)))
    bot = max(dev([px[x, y] for x in range(w)]) for y in range(h - min(m[3], h), h))
    out.update(l=round(left, 1), r=round(right, 1), t=round(top, 1), b=round(bot, 1))
    return out


def aspect_close(a: float, b: float) -> bool:
    return b > 0 and abs(a - b) / b <= 0.01


# --- R1's composite criterion (D21-G2-R1_measure4.py margins4, replicated) ---

GRAIN_M = 14.0


def margins4(img: Image.Image) -> dict:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    xs = list(range(int(w * 0.15), int(w * 0.85), max(1, w // 50)))
    ys = list(range(int(h * 0.15), int(h * 0.85), max(1, h // 50)))
    yr, xr = h // 2, w // 2
    refs_l = [px[xr, y] for y in ys]
    refs_t = [px[x, yr] for x in xs]
    ref_lum_l = sum(sum(p[:3]) / 3 for p in refs_l) / len(refs_l)
    ref_lum_t = sum(sum(p[:3]) / 3 for p in refs_t) / len(refs_t)

    def line_stat(pos, refs, getter, ref_lum):
        s, n, strong, lum = 0, 0, 0, 0.0
        for i, ref in enumerate(refs):
            p = getter(pos, i)
            lum += sum(p[:3]) / 3
            for c in range(4):
                d = abs(p[c] - ref[c])
                s += d
                n += 1
                if d > 60:
                    strong += 1
        return s / n, strong, abs(lum / len(refs) - ref_lum)

    def scan(pos_range, refs, getter, ref_lum):
        orn_end, run, plateau, clean = -1, 0, None, 0
        for pos in pos_range:
            mad, strong, dlum = line_stat(pos, refs, getter, ref_lum)
            orn = mad > GRAIN_M or strong >= 3 or dlum > 6
            if orn:
                run += 1
                if run >= 4:
                    orn_end = pos
            else:
                run = 0
                clean += 1
                if clean >= 10 and plateau is None:
                    plateau = pos - 9
            if orn:
                clean = 0
        return plateau if plateau is not None else 0, orn_end + 1 if orn_end >= 0 else 0

    pl, ol = scan(range(0, w // 2), refs_l, lambda x, i: px[x, ys[i]], ref_lum_l)
    pr, orr = scan(range(w - 1, w // 2, -1), refs_l, lambda x, i: px[x, ys[i]], ref_lum_l)
    pt, ot = scan(range(0, h // 2), refs_t, lambda y, i: px[xs[i], y], ref_lum_t)
    pb, ob = scan(range(h - 1, h // 2, -1), refs_t, lambda y, i: px[xs[i], y], ref_lum_t)
    return {
        "l": max(pl, ol),
        "r": max(w - pr, w - orr) if pr or orr else 0,
        "t": max(pt, ot),
        "b": max(h - pb, h - ob) if pb or ob else 0,
    }


# --- The builder's criterion (g2_driver.py measure_margins, replicated) ---


def _band_scan(img: Image.Image, side: str, band_frac: float = 0.4) -> int:
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
            count = run_len
    return -1


def _band_end_scan(img: Image.Image, side: str, bright: int = 50, run: int = 6) -> int:
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


def builder_margins(img: Image.Image) -> dict:
    plateaus = {s: _band_scan(img, s) for s in ("l", "r", "t", "b")}
    bands = {s: _band_end_scan(img, s) for s in ("l", "r", "t", "b")}
    return {s: max(plateaus[s], bands[s]) for s in plateaus}


def main() -> int:
    report = {}
    for cls, name in CUTS.items():
        im = Image.open(UI / name)
        w, h = im.size
        asp = w / h
        master = MASTERS["C9_cut"] if cls == "C9" else MASTERS[cls]
        masp = master[0] / master[1]
        row = {
            "file": name, "size": [w, h], "aspect": round(asp, 4),
            "master_aspect": round(masp, 4),
            "aspect_ok_vs_doc": aspect_close(asp, masp) if cls != "C9" else aspect_close(asp, MASTERS["C9"][0] / MASTERS["C9"][1]),
            "aspect_ok_vs_cut_master": aspect_close(asp, masp),
        }
        if cls in WIRED:
            im4 = margins4(im)
            imb = builder_margins(im)
            ext = ink_extents(im)
            row["r1_method_lrtb"] = [im4[k] for k in "lrtb"]
            row["builder_method_lrtb"] = [imb[k] for k in "lrtb"]
            row["max_rule_lrtb"] = [max(im4[k], imb[k]) for k in "lrtb"]
            row["wired_lrtb"] = WIRED[cls]
            row["wired_covers_ink"] = all(wi >= e for wi, e in zip(WIRED[cls], ext))
            row["band_dev_at_wired"] = band_deviation(im, WIRED[cls])
        report[cls] = row
    for bg, name in BGS.items():
        im = Image.open(UI / name)
        w, h = im.size
        report[bg] = {
            "file": name, "size": [w, h], "aspect": round(w / h, 4),
            "master_aspect": round(MASTERS["C13"][0] / MASTERS["C13"][1], 4),
            "aspect_ok_vs_doc": aspect_close(w / h, MASTERS["C13"][0] / MASTERS["C13"][1]),
        }
    for name, want in KEEP.items():
        p = UI / name
        im = Image.open(p)
        report[name] = {"size": list(im.size), "expect": list(want), "ok": im.size == want}

    console = Image.open(UI / "ui_armory_console.png")
    report["C6"]["size"] = list(console.size)
    report["C6"]["aspect"] = round(console.size[0] / console.size[1], 4)
    report["C6"]["master_aspect"] = round(MASTERS["C6"][0] / MASTERS["C6"][1], 4)
    report["C6"]["aspect_ok_vs_doc"] = aspect_close(
        console.size[0] / console.size[1], MASTERS["C6"][0] / MASTERS["C6"][1]
    )

    json.dump(report, sys.stdout, indent=1)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
