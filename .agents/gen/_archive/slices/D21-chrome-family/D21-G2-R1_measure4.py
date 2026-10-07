#!/usr/bin/env python3
"""D21-G2-R1 probe 5: composite margins (plateau + sustained ornament), C7 recon
with full shift range, alpha audit of all 15 landed files."""
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
RAW = WS / "asset-library/raw/chrome-family"
UI = WS / "vajb-orbit/assets/ui"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-R1_evidence4.json"
EV = {}
GRAIN_M = 14.0
DIRS = {"C7": "20261005-202052", "C8": "20261005-202141"}


def margins4(img):
    """margin = max(plateau onset, end of the last sustained ornament run).
    Ornament per position: mean-abs > 14, or >=3 sampled channels > 60 off, or
    the position's mean luminance > 6 off the interior reference (faint bevel)."""
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
        s = 0
        n = 0
        strong = 0
        lum = 0.0
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
        orn_end = -1
        run = 0
        plateau = None
        clean = 0
        for pos in pos_range:
            mad, strong, dlum = line_stat(pos, refs, getter, ref_lum)
            orn = mad > GRAIN_M or strong >= 3 or dlum > 6
            if orn:
                run += 1
                if run >= 4:
                    orn_end = pos
            else:
                run = 0
            if not orn:
                clean += 1
                if clean >= 10 and plateau is None:
                    plateau = pos - 9
            else:
                clean = 0
        return plateau if plateau is not None else 0, orn_end + 1 if orn_end >= 0 else 0

    pl, ol = scan(range(0, w // 2), refs_l, lambda x, i: px[x, ys[i]], ref_lum_l)
    pr, orr = scan(range(w - 1, w // 2, -1), refs_l, lambda x, i: px[x, ys[i]], ref_lum_l)
    pt, ot = scan(range(0, h // 2), refs_t, lambda y, i: px[xs[i], y], ref_lum_t)
    pb, ob = scan(range(h - 1, h // 2, -1), refs_t, lambda y, i: px[xs[i], y], ref_lum_t)
    return {"l": max(pl, ol), "r": max(w - pr, w - orr) if pr or orr else 0,
            "t": max(pt, ot), "b": max(h - pb, h - ob) if pb or ob else 0}


DECL = {"ui_inline_chip.png": (16, 16, 16, 16), "ui_row_strip.png": (24, 24, 16, 16),
        "ui_rack_bay_card.png": (20, 20, 20, 20), "ui_tooltip_frame.png": (24, 24, 24, 24),
        "ui_minimap_bezel.png": (32, 32, 32, 32), "ui_panel_frame.png": (64, 64, 64, 64)}
EV["margins4"] = {}
for name in DECL:
    img = Image.open(UI / name).convert("RGBA")
    mm = margins4(img)
    mm["declared"] = list(DECL[name])
    mm["dev"] = [mm[k] - DECL[name][i] for i, k in enumerate("lrtb")]
    EV["margins4"][name] = mm

# C7 recon with a wide shift range
raw7 = Image.open(RAW / DIRS["C7"] / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
rec7 = raw7.resize((720, 480), Image.LANCZOS).convert("RGB")
landed7 = Image.open(UI / "ui_tooltip_frame.png").convert("RGBA")
a2 = rec7.resize((160, 107), Image.BICUBIC)
best = None
for dx in range(-5, 6):
    for dy in range(-5, 6):
        base = Image.new("RGB", landed7.size, (96, 102, 108))
        base.paste(landed7, (dx, dy), landed7)
        b2 = base.resize((160, 107), Image.BICUBIC)
        dd = ImageChops.difference(a2, b2)
        st = ImageStat.Stat(dd)
        mean = sum(st.mean) / len(st.mean)
        if best is None or mean < best[0]:
            mx = max(e[1] for e in dd.getextrema())
            best = (mean, mx, dx, dy)
EV["c7_recon_shifted"] = {"mean": round(best[0], 2), "max": round(best[1], 1),
                          "shift": [best[2], best[3]]}

# alpha audit of every landed file
EV["landed_alpha"] = {}
names = [n for ns in ("ui_inline_chip.png", "ui_row_strip.png", "ui_rack_bay_card.png",
                      "ui_armory_console.png", "ui_tooltip_frame.png",
                      "ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
                      "ui_slot_inventory_normal.png", "ui_bar_caps.png",
                      "ui_minimap_bezel.png", "ui_panel_frame.png")
         for n in [ns]]
for name in names:
    a = Image.open(UI / name).convert("RGBA").getchannel("A")
    h = a.histogram()
    mn, mx = a.getextrema()
    mean = sum(i * v for i, v in enumerate(h)) / max(1, sum(h))
    EV["landed_alpha"][name] = {"min": mn, "max": mx, "mean": round(mean, 1),
                                "pct_lt_250": round(100.0 * sum(h[:250]) / max(1, sum(h)), 2)}
for name in ("ui_backdrop_armory_deck.png", "ui_backdrop_refinery_deck.png",
             "ui_backdrop_market_deck.png", "ui_backdrop_dock_deck.png"):
    a = Image.open(UI / name).convert("RGBA").getchannel("A")
    EV["landed_alpha"][name] = {"min": a.getextrema()[0], "max": a.getextrema()[1]}

# builder border_med for C8 (report claims 53,56,58)
img = Image.open(RAW / DIRS["C8"] / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
px = img.load()
w, h = img.size
ch = [[], [], []]
for x in range(0, w, max(1, w // 100)):
    for y in list(range(8)) + list(range(h - 8, h)):
        p = px[x, y]
        for c in range(3):
            ch[c].append(p[c])
for y in range(0, h, max(1, h // 100)):
    for x in list(range(8)) + list(range(w - 8, w)):
        p = px[x, y]
        for c in range(3):
            ch[c].append(p[c])
EV["c8_border_med"] = [sorted(a)[len(a) // 2] for a in ch]

OUT.write_text(json.dumps(EV, indent=1))
print(json.dumps(EV, indent=1))
