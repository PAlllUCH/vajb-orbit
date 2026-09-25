#!/usr/bin/env python3
"""armory_mockup_v2.py - D13 armory rework mockups (design pass, not shipping art).

Owner ticks 2026-09-25: T2 = approach B (full-width dashboard) is CHOSEN;
T1 y with the condition "all resolutions work"; T3-T8 y. B is therefore the
design of record and is rendered at THREE virtual canvases to prove the
resolution law (tick T1's condition):

  out/armory_mockup_v2_b.png          1920x1080  (base 16:9)
  out/armory_mockup_v2_b_wide.png     2580x1080  (21:9 window, e.g. 3440x1440)
  out/armory_mockup_v2_b_tall.png     1920x1536  (5:4 window, e.g. 1280x1024)

The game runs canvas_items stretch with aspect=expand, so the virtual canvas
is 1920x1080 scaled for small windows and EXPANDS with the aspect for larger
or odd ones. The layout law this mockup encodes: every pane rect derives from
the station host rect at runtime (proportional splits, containers), nothing is
an absolute constant; text ink stays 13 px virtual at every size; cell names
(13 px, widest family word RAILGUN = 58 px) fit one line at the BASE width and
only gain room wider.

  out/armory_mockup_v2_a.png/.jpg     approach A (the runner-up, kept for the
                                      record: workbench + supply drawer)
  out/armory_mockup_v2_sheet.png      both + the tick list with the owner's
                                      answers + PROPOSED values + reversals

Geometry + painted-metal helpers are the D7 mockup language
(cockpit_mockup). PROPOSED console canvas 1360x516 landscape at the pinned
1392x610 host (was 872x956 portrait - the portrait canvas ruled for a
landscape host is the measured root cause of HIGH-4's fold and the dead
zone). Bay cells are 2x2 per bay (PROPOSED, reverses the S15 pitch) so full
barrel names fit at 13 px. Deterministic (random.seed(11)); no paid calls.
Design pass only: nothing here is drawn in the engine.
"""
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cockpit_mockup import (  # noqa: E402
    BONE, EMBER, EMBER_BRIGHT, GHOST, METAL_MID,
    bevel, bolt, brushed, font, recess, seg_glyph,
)

random.seed(11)

OUT = "staging/mockup/out"

CAP = (172, 178, 186)        # dim ink on painted metal, measured >= 4.5:1
CAP_VOID = (150, 157, 165)   # dim ink on the dark host, measured >= 4.5:1
DARK = (24, 27, 33)
BAY_BG = (30, 34, 41)
CHIP_BG = (78, 32, 18)
LEDGE_BG = (22, 26, 31)
ROW_BG = (38, 43, 50)

F_TITLE = font(34)
F_PANE = font(22)
F_MOD = font(20)
F_13B = font(13)
F_13 = font(13)

RAIL_LABELS = ["ARMORY", "REFINERY", "EXCHANGE", "AUCTION",
               "SHIPYARD", "FITTING", "REPAIRS", "LAUNCH"]

BAY_FITS = [
    ["W1 LASER|MKII", "W2 CANNON|MKI", "W3 CANNON|MKI", None],
    ["W5 MINE LAYER|MKI", "W6 PLASMA|MKI", "W7 RAILGUN|MKI", None],
    ["W9 ROCKET|MKII", "W10 LASER|MKI", None, None],
    [None, None, None, None],
    ["W13 CANNON|MKII", None, None, None],
]
BAY_STATE = ["READY", "READY", "OVER CAP", "READY", "READY"]
SALVO = ["062", "058", "124", "048", "071"]

BARRELS = [
    ("LASER MKII", "2,4 DPS"),
    ("CANNON MKI", "3,1 DPS"),
    ("MINE LAYER MKI", "4 MINES"),
    ("PLASMA MKI", "5,0 DPS"),
    ("RAILGUN MKI", "7,2 DPS"),
    ("ROCKET MKII", "22 DMG"),
]

PACKS = [
    ("LASER CELLS", "300 ROUNDS PER PACK", "HELD 60 ROUNDS", "HOLD 30 UNITS", "120 CR"),
    ("CANNON ROUNDS", "300 ROUNDS PER PACK", "HELD 300 ROUNDS", "HOLD 30 UNITS", "180 CR"),
    ("ROCKETS", "60 ROUNDS PER PACK", "HELD 60 ROUNDS", "HOLD 10 UNITS", "240 CR"),
    ("MINES", "100 ROUNDS PER PACK", "HELD 300 ROUNDS", "HOLD 30 UNITS", "200 CR"),
    ("PLASMA CELLS", "100 ROUNDS PER PACK", "HELD 0 ROUNDS", "HOLD 10 UNITS", "320 CR"),
    ("RAIL SLUGS", "60 ROUNDS PER PACK", "HELD 12 ROUNDS", "HOLD 6 UNITS", "400 CR"),
]

BASE_W, BASE_H = 1920, 1080
PANE_BASE = (452, 214, 1844, 824)     # measured host rect, 1392x610
CONSOLE_BASE = (468, 282, 1828, 818)  # 1360x516, the PROPOSED landscape canvas


def txt(d, xy, s, f, fill, anchor=None):
    d.text(xy, s, font=f, fill=fill, anchor=anchor)


def seg_small(img, x, y, names, scale=0.55):
    tile = Image.new("RGB", (40, 72), LEDGE_BG)
    w, h = int(40 * scale), int(72 * scale)
    for i, n in enumerate(names):
        seg_glyph(ImageDraw.Draw(tile), 0, 0, n)
        img.paste(tile.resize((w, h), Image.LANCZOS), (int(x + i * (w + 2)), int(y)))
    return len(names) * (w + 2)


def metal_rect(img, box, bolts=True):
    x0, y0, x1, y1 = box
    img.paste(brushed(int(x1 - x0), int(y1 - y0)), (int(x0), int(y0)))
    bevel(img, box)
    if bolts:
        bolt(img, x0 + 16, y0 + 16, 8)
        bolt(img, x1 - 16, y0 + 16, 8)
        bolt(img, x0 + 16, y1 - 16, 8)
        bolt(img, x1 - 16, y1 - 16, 8)


def chip(d, box, label, danger=False):
    x0, y0, x1, y1 = box
    bg = CHIP_BG if danger else (46, 51, 58)
    d.rounded_rectangle(box, radius=6, fill=bg)
    d.rounded_rectangle(box, radius=6, outline=EMBER_BRIGHT if danger else GHOST, width=1)
    if danger:
        d.polygon([(x0 + 8, y1 - 7), (x0 + 13, y0 + 6), (x0 + 18, y1 - 7)], fill=EMBER_BRIGHT)
    txt(d, ((x0 + x1) / 2 + (5 if danger else 0), (y0 + y1) / 2), label, F_13B,
        EMBER_BRIGHT if danger else CAP, anchor="mm")


def cell(img, box, entry, drop=False):
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    recess(img, box, fill=(18, 21, 26), radius=10)
    if drop:
        txt(d, ((x0 + x1) / 2, (y0 + y1) / 2), "DROP HERE", F_13, CAP, anchor="mm")
        return
    name, var = entry.split("|")
    txt(d, ((x0 + x1) / 2, y0 + 14), name, F_13B, BONE, anchor="mm")
    txt(d, ((x0 + x1) / 2, y0 + 32), var, F_13, CAP, anchor="mm")
    d.line([(x0 + 8, y1 - 12), (x1 - 8, y1 - 12)], fill=EMBER, width=2)


def salvo_ledge(img, box, digits):
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=8, fill=LEDGE_BG)
    d.rounded_rectangle(box, radius=8, outline=METAL_MID, width=1)
    seg_small(img, x0 + 10, y0 + 2, list(digits))
    txt(d, (x0 + 92, (y0 + y1) / 2), "SALVO s", F_13, CAP, anchor="lm")


def bay(img, box, label, key, fit, state, digits, cells_wide=2):
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=12, fill=BAY_BG)
    d.rounded_rectangle(box, radius=12, outline=METAL_MID, width=1)
    txt(d, (x0 + 12, y0 + 18), label, F_13B, BONE, anchor="lm")
    txt(d, (x0 + 52, y0 + 18), key, F_13, CAP, anchor="lm")
    if state == "OVER CAP":
        chip(d, (x1 - 118, y0 + 5, x1 - 12, y0 + 29), "OVER CAP", danger=True)
    else:
        chip(d, (x1 - 96, y0 + 5, x1 - 12, y0 + 29), "READY")
    ledge_h = 34
    cells_top = y0 + 34
    cells_bot = y1 - ledge_h - 16
    rows = 4 // cells_wide
    gap = 8
    cw = (x1 - x0 - 24 - (cells_wide - 1) * gap) // cells_wide
    ch = (cells_bot - cells_top - (rows - 1) * gap) // rows
    for i in range(4):
        cx = x0 + 12 + (i % cells_wide) * (cw + gap)
        cy = cells_top + (i // cells_wide) * (ch + gap)
        entry = fit[i]
        cell(img, (cx, cy, cx + cw, cy + ch), entry, drop=entry is None)
    salvo_ledge(img, (x0 + 12, y1 - ledge_h - 8, x1 - 12, y1 - 8), digits)


def supply_row(d, box, name, stat):
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, radius=8, fill=ROW_BG)
    d.rounded_rectangle(box, radius=8, outline=METAL_MID, width=1)
    for i in range(3):
        d.ellipse((x0 + 8, y0 + (y1 - y0) / 2 - 10 + i * 7,
                   x0 + 13, y0 + (y1 - y0) / 2 - 5 + i * 7), fill=CAP)
    txt(d, (x0 + 24, (y0 + y1) / 2), name, F_13B, BONE, anchor="lm")
    txt(d, (x1 - 10, (y0 + y1) / 2), stat, F_13, CAP, anchor="rm")


def pack_card(d, box, pack):
    x0, y0, x1, y1 = box
    name, per, held, hold, price = pack
    d.rounded_rectangle(box, radius=8, fill=ROW_BG)
    d.rounded_rectangle(box, radius=8, outline=METAL_MID, width=1)
    txt(d, (x0 + 12, y0 + 18), name, F_13B, BONE, anchor="lm")
    txt(d, (x1 - 12, y0 + 18), price, F_13, CAP, anchor="rm")
    txt(d, (x0 + 12, y0 + 40), per, F_13, CAP, anchor="lm")
    txt(d, (x0 + 12, y0 + 62), f"{held} - {hold}", F_13, CAP, anchor="lm")
    chip(d, (x1 - 88, y0 + (y1 - y0) - 34, x1 - 12, y0 + (y1 - y0) - 8), "BUY")


def frame(img, cw, ch):
    d = ImageDraw.Draw(img)
    img.paste(brushed(cw, ch, base=DARK), (0, 0))
    txt(d, (40, 24), "ORBITAL DRYDOCK KEPLER-9", F_TITLE, BONE, anchor="lm")
    txt(d, (40, 68), "DOCKING RING 04 - HELIOS DRIFT - HULL TRAFFIC LOW",
        F_13, CAP_VOID, anchor="lm")
    metal_rect(img, (cw - 260, 22, cw - 40, 86))
    txt(d, (cw - 150, 54), "10,000 CR", F_MOD, BONE, anchor="mm")

    metal_rect(img, (20, 100, 360, 960), bolts=False)
    d = ImageDraw.Draw(img)
    txt(d, (44, 118), "MODULES", F_13, CAP, anchor="lm")
    for i, label in enumerate(RAIL_LABELS):
        y = 140 + i * 72
        img.paste(brushed(308, 62), (36, y))
        bevel(img, (36, y, 344, y + 62))
        if label == "ARMORY":
            d.rectangle((36, y, 42, y + 62), fill=EMBER)
            txt(d, (66, y + 31), label, F_MOD, BONE, anchor="lm")
        else:
            txt(d, (66, y + 31), label, F_MOD, CAP, anchor="lm")
        bolt(img, 52, y + 31, 7)
        bolt(img, 328, y + 31, 7)
    txt(d, (44, 736), "SESSION", F_13, CAP, anchor="lm")
    img.paste(brushed(308, 62), (36, 756))
    bevel(img, (36, 756, 344, 818))
    txt(d, (66, 787), "LOG OUT", F_MOD, CAP, anchor="lm")

    d = ImageDraw.Draw(img)
    txt(d, (40, ch - 28), "STATUS - ALL SYSTEMS NORMAL", F_13, CAP_VOID, anchor="lm")
    txt(d, (cw - 40, ch - 28), "ARMORY - DOCKED - KEPLER-9 - FULL OPERATIONS RESUMED",
        F_13, CAP_VOID, anchor="rm")


def derive(cw, ch):
    """The resolution law: every rect derives from the canvas, nothing is pinned."""
    px0 = 452
    px1 = cw - (BASE_W - PANE_BASE[2])
    py0 = 214
    py1 = ch - (BASE_H - PANE_BASE[3])
    pane = (px0, py0, px1, py1)
    cons = (px0 + 16, py0 + 68, px1 - 16, py1 - 6)
    insp = (px0, ch - 250, px1, ch - 126)
    return pane, cons, insp


def pane_chrome(img, pane, cons, insp):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(pane, radius=10, fill=(22, 26, 31))
    d.rounded_rectangle(pane, radius=10, outline=METAL_MID, width=1)
    txt(d, (pane[0] + 20, pane[1] + 18), "ARMORY", F_PANE, BONE, anchor="lm")
    txt(d, (pane[0] + 20, pane[1] + 48),
        "BATTERY RACKS AND AMMUNITION - 5 RACKS - 6 PACKS", F_13, CAP_VOID, anchor="lm")
    txt(d, (pane[2] - 20, pane[1] + 48),
        "DRAG TO FIT - RIGHT-CLICK TO PULL - 1-5 SELECT RACK", F_13, CAP_VOID, anchor="rm")
    metal_rect(img, insp, bolts=False)
    d = ImageDraw.Draw(img)
    txt(d, (insp[0] + 20, insp[1] + 22), "W1 LASER MKII", F_MOD, BONE, anchor="lm")
    txt(d, (insp[0] + 20, insp[1] + 50),
        "Dense lasers, it never misses and never stops asking the reactor for more.",
        F_13, CAP, anchor="lm")
    txt(d, (insp[0] + 20, insp[1] + 72),
        "SALVO 0.62 s - CYCLE 2,4 /s - HEAT 40 % - FITTED IN B1 W1", F_13, CAP, anchor="lm")
    metal_rect(img, cons, bolts=True)


def approach(cw, ch, mode, out_name):
    img = Image.new("RGB", (cw, ch), DARK)
    frame(img, cw, ch)
    pane, cons, insp = derive(cw, ch)
    pane_chrome(img, pane, cons, insp)
    d = ImageDraw.Draw(img)
    cx0, cy0, cx1, cy1 = cons
    inner_w = cx1 - cx0 - 32
    ky = (cy1 - cy0) / 536.0

    if mode == "b":
        band_top = cy0 + 40 * ky
        band_h = 200 * ky
        gap = 7
        bw = (inner_w - 4 * gap) // 5
        for i in range(5):
            x0 = cx0 + 16 + i * (bw + gap)
            bay(img, (x0, band_top, x0 + bw, band_top + band_h),
                f"B{i + 1}", f"({i + 1})", BAY_FITS[i], BAY_STATE[i], SALVO[i])
        txt(d, (cx0 + 16, cy0 + 274 * ky), "BARREL INVENTORY - 6 OWNED",
            F_13, CAP, anchor="lm")
        txt(d, (cx0 + 16 + inner_w / 2 + 16, cy0 + 274 * ky), "AMMUNITION - 6 PACKS",
            F_13, CAP, anchor="lm")
        well_top = cy0 + 296 * ky
        well_h = (cy1 - 12 - well_top)
        col_w = (inner_w - 32) // 2
        for i, (name, stat) in enumerate(BARRELS):
            r, c = divmod(i, 2)
            rh = (well_h - 2 * 8) // 3
            bx = cx0 + 16 + c * (col_w + 32)
            by = well_top + r * (rh + 8)
            supply_row(d, (bx, by, bx + col_w, by + rh), name, stat)
        for i, pack in enumerate(PACKS):
            r, c = divmod(i, 2)
            rh = (well_h - 2 * 8) // 3
            bx = cx0 + 16 + inner_w / 2 + 16 + c * (col_w + 32)
            by = well_top + r * (rh + 8)
            pack_card(d, (bx, by, bx + col_w, by + rh), pack)
    else:
        zone_l = inner_w * 0.765
        zone_s = inner_w * 0.223
        band_top = cy0 + 40 * ky
        band_h = 200 * ky
        gap = 8
        bw = (zone_l - 3 * gap) // 4
        for i in range(4):
            x0 = cx0 + 16 + i * (bw + gap)
            bay(img, (x0, band_top, x0 + bw, band_top + band_h),
                f"B{i + 1}", f"({i + 1})", BAY_FITS[i], BAY_STATE[i], SALVO[i])
        tail_y = band_top + band_h + 10 * ky
        tail_h = band_h
        bay(img, (cx0 + 16, tail_y, cx0 + 16 + zone_l, tail_y + tail_h),
            "B5", "(5)", BAY_FITS[4], BAY_STATE[4], SALVO[4], cells_wide=4)
        sx0 = cx0 + 16 + zone_l + 32
        txt(d, (sx0, cy0 + 274 * ky), "BARREL INVENTORY - 6 OWNED", F_13, CAP, anchor="lm")
        for i, (name, stat) in enumerate(BARRELS):
            rh = 32 * ky
            by = cy0 + 296 * ky + i * (rh + 4)
            supply_row(d, (sx0, by, sx0 + zone_s, by + rh), name, stat)
        tab_y = cy0 + 296 * ky + 6 * (32 * ky + 4) + 10
        d.rounded_rectangle((sx0, tab_y, sx0 + zone_s, tab_y + 28), radius=8, fill=ROW_BG)
        txt(d, (sx0 + 52, tab_y + 14), "AMMO", F_13B, BONE, anchor="mm")
        txt(d, (sx0 + 160, tab_y + 14), "SHOP", F_13, CAP, anchor="mm")
        d.line([(sx0 + 12, tab_y + 26), (sx0 + 96, tab_y + 26)], fill=EMBER, width=3)
        for i, pack in enumerate(PACKS):
            by = tab_y + 36 + i * 32
            name, per, held, _hold, price = pack
            d.rounded_rectangle((sx0, by, sx0 + zone_s, by + 28), radius=8, fill=ROW_BG)
            d.rounded_rectangle((sx0, by, sx0 + zone_s, by + 28), radius=8,
                                outline=METAL_MID, width=1)
            txt(d, (sx0 + 12, by + 14), name, F_13B, BONE, anchor="lm")
            txt(d, (sx0 + zone_s - 12, by + 14), f"{price}  [BUY]", F_13B,
                EMBER_BRIGHT, anchor="rm")

    img.save(f"{OUT}/{out_name}.png")
    img.convert("RGB").save(f"{OUT}/{out_name}.jpg", quality=85)
    print("wrote", out_name)
    return img


TICKS = [
    ("T1", "y (condition: all resolutions work)", "landscape console 1360x516 at the pinned 1392x610 host; layout derives from the host rect (see proofs)"),
    ("T2", "y = B", "full-width dashboard: 5 bays up top, barrel inventory + ammunition wells below"),
    ("T3", "y", "cells print W-index + name + variant at 13 px; floating chip + x die"),
    ("T4", "y", "DROP HERE cue at 13 px inside empty cells"),
    ("T5", "y", "description -> inspector 2-3 lines; pane footer caption dies"),
    ("T6", "y", "captions to the light ramp (>= 4.5:1); 13 px floor everywhere"),
    ("T7", "y", "OVER CAP = chevron + label chip on the bay head"),
    ("T8", "y", "per-bay SALVO ledge stays; hidden head line removed"),
]

PROPOSED = [
    "P1  console canvas 872x956 -> 1360x516 landscape (master re-render 2x). Reversal: UI_SPEC 3.10 A2.",
    "P2  ammo well 136 tall -> 2x3 pack-card grid in the wells band. Reversal: restore.",
    "P3  bay cells 4-in-a-row -> 2x2 rack per bay (RAILGUN = 58 px fits at 13 px). Reversal: S15 pitch.",
    "P4  inspector strip carries 2-3 body lines (MED-3). Reversal: single 13 px line.",
    "P5  pack wording carries unit words (HELD 60 ROUNDS - HOLD 30 UNITS, was HELD 60/30). Reversal: old string.",
    "P6  resolution law: every pane rect derives from the host rect at runtime (proportional, no pinned",
    "    constants); 13 px virtual ink floor at every canvas; proofs at 1920x1080 / 2580x1080 / 1920x1536.",
]


def sheet():
    sw, sh = 1920, 3260
    img = Image.new("RGB", (sw, sh), (13, 16, 21))
    d = ImageDraw.Draw(img)
    txt(d, (40, 40), "D13 ARMORY REWORK - APPROACH B CHOSEN (owner 2026-09-25)",
        F_TITLE, BONE, anchor="lm")
    txt(d, (40, 84), "T1 y (all resolutions must work) - T2 B - T3-T8 y. "
                     "Layout language for other panes: deferred, not in this wave.",
        F_13, CAP_VOID, anchor="lm")
    b = Image.open(f"{OUT}/armory_mockup_v2_b.png").resize((1600, 900), Image.LANCZOS)
    img.paste(b, (160, 120))
    txt(d, (160, 110), "CHOSEN - B DASHBOARD AT BASE 1920x1080", F_13B, EMBER_BRIGHT,
        anchor="ls")
    txt(d, (40, 1050), "TICK LIST (owner answers)", F_13B, BONE, anchor="lm")
    for i, (tid, ans, what) in enumerate(TICKS):
        txt(d, (40, 1082 + i * 22), f"[x] {tid}  {ans}  -  {what}", F_13, CAP, anchor="lm")
    txt(d, (40, 1270), "RESOLUTION PROOFS (tick T1's condition)", F_13B, BONE, anchor="lm")
    wide = Image.open(f"{OUT}/armory_mockup_v2_b_wide.png").resize((820, 342), Image.LANCZOS)
    tall = Image.open(f"{OUT}/armory_mockup_v2_b_tall.png").resize((620, 496), Image.LANCZOS)
    img.paste(wide, (40, 1304))
    txt(d, (40, 1298), "21:9 WINDOW -> 2580x1080 CANVAS (bays widen)", F_13, CAP,
        anchor="ls")
    img.paste(tall, (900, 1304))
    txt(d, (900, 1298), "5:4 WINDOW -> 1920x1536 CANVAS (bands grow)", F_13, CAP,
        anchor="ls")
    txt(d, (40, 1840), "PROPOSED (with reversal)", F_13B, BONE, anchor="lm")
    for i, t in enumerate(PROPOSED):
        txt(d, (40, 1872 + i * 22), t, F_13, CAP, anchor="lm")
    a = Image.open(f"{OUT}/armory_mockup_v2_a.png").resize((1400, 788), Image.LANCZOS)
    img.paste(a, (260, 2050))
    txt(d, (260, 2044), "RUNNER-UP - A WORKBENCH (kept for the record)", F_13, CAP,
        anchor="ls")
    txt(d, (40, 2880), "REVERSAL LAW: restore UI_SPEC 3.10 Amendment 2 geometry and the S15 "
                       "bay pitch; every number above is proposed, nothing is assumed moved.",
        F_13, CAP_VOID, anchor="lm")
    txt(d, (40, 2910), "DATA MODEL UNCHANGED: 5 racks x 4 cells, pack cards, salvo readouts, "
                       "13/16 transactions, CONTRACTS 17 seams.", F_13, CAP_VOID, anchor="lm")
    txt(d, (40, 2940), "NEXT: the implementation wave is briefed on these ticks only.",
        F_13, CAP_VOID, anchor="lm")
    img.save(f"{OUT}/armory_mockup_v2_sheet.png")
    img.convert("RGB").save(f"{OUT}/armory_mockup_v2_sheet.jpg", quality=85)
    print("wrote armory_mockup_v2_sheet")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    approach(BASE_W, BASE_H, "a", "armory_mockup_v2_a")
    approach(BASE_W, BASE_H, "b", "armory_mockup_v2_b")
    approach(2580, 1080, "b", "armory_mockup_v2_b_wide")
    approach(1920, 1536, "b", "armory_mockup_v2_b_tall")
    sheet()
