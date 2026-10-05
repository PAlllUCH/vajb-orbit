#!/usr/bin/env python3
"""D21-G2-R1 probe 4: full-scan margins, C2 threshold-profile ink box, direct-route
C7 reconstruction, C3/C4 end-patch evidence, uid base36 test."""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
RAW = WS / "asset-library/raw/chrome-family"
UI = WS / "vajb-orbit/assets/ui"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-R1_evidence3.json"
EV = {}
GRAIN_M = 14.0

DIRS = {"C2": "20261005-201500", "C7": "20261005-202052"}


def border_med(img, band=8):
    w, h = img.size
    px = img.load()
    ch = [[], [], []]
    for x in range(0, w, max(1, w // 100)):
        for y in list(range(band)) + list(range(h - band, h)):
            p = px[x, y]
            for c in range(3):
                ch[c].append(p[c])
    for y in range(0, h, max(1, h // 100)):
        for x in list(range(band)) + list(range(w - band, w)):
            p = px[x, y]
            for c in range(3):
                ch[c].append(p[c])
    return tuple(sorted(a)[len(a) // 2] for a in ch)


def margins3(img):
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    xs = list(range(int(w * 0.15), int(w * 0.85), max(1, w // 50)))
    ys = list(range(int(h * 0.15), int(h * 0.85), max(1, h // 50)))
    yr, xr = h // 2, w // 2
    refs_l = [px[xr, y] for y in ys]
    refs_t = [px[x, yr] for x in xs]

    def line_stat(pos, refs, getter):
        s = 0
        n = 0
        strong = 0
        for i, ref in enumerate(refs):
            p = getter(pos, i)
            for c in range(4):
                d = abs(p[c] - ref[c])
                s += d
                n += 1
                if d > 60:
                    strong += 1
        return s / n, strong

    def scan(pos_range, refs, getter):
        last = -1
        orn = -1
        for pos in pos_range:
            mad, strong = line_stat(pos, refs, getter)
            if mad > GRAIN_M or strong >= 3:
                last = pos
            if mad > 30 or strong >= 6:
                orn = pos
        return last, orn

    l_last, l_orn = scan(range(0, w // 2), refs_l, lambda x, i: px[x, ys[i]])
    r_last, r_orn = scan(range(w - 1, w // 2, -1), refs_l, lambda x, i: px[x, ys[i]])
    t_last, t_orn = scan(range(0, h // 2), refs_t, lambda y, i: px[xs[i], y])
    b_last, b_orn = scan(range(h - 1, h // 2, -1), refs_t, lambda y, i: px[xs[i], y])
    return {"l": l_last + 1 if l_last >= 0 else 0,
            "r": (w - r_last) if r_last >= 0 else 0,
            "t": t_last + 1 if t_last >= 0 else 0,
            "b": (h - b_last) if b_last >= 0 else 0,
            "orn": {"l": l_orn + 1 if l_orn >= 0 else 0,
                    "r": (w - r_orn) if r_orn >= 0 else 0,
                    "t": t_orn + 1 if t_orn >= 0 else 0,
                    "b": (h - b_orn) if b_orn >= 0 else 0}}


DECL = {"ui_inline_chip.png": (16, 16, 16, 16), "ui_row_strip.png": (24, 24, 16, 16),
        "ui_rack_bay_card.png": (20, 20, 20, 20), "ui_tooltip_frame.png": (24, 24, 24, 24),
        "ui_minimap_bezel.png": (32, 32, 32, 32), "ui_panel_frame.png": (64, 64, 64, 64)}
EV["margins3"] = {}
for name in DECL:
    img = Image.open(UI / name).convert("RGBA")
    mm = margins3(img)
    mm["declared"] = list(DECL[name])
    mm["max_dev"] = max(abs(mm[k] - DECL[name][i]) for i, k in enumerate("lrtb"))
    EV["margins3"][name] = mm

# ---- C2 ink box via threshold profiles --------------------------------------
img = Image.open(RAW / DIRS["C2"] / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
bg = border_med(img)
d = ImageChops.difference(img.convert("RGB"), Image.new("RGB", img.size, bg))
r, g, b = d.split()
dist = ImageChops.lighter(ImageChops.lighter(r, g), b)
w, h = img.size
prof = {}
for t in (26, 40, 60):
    m = dist.point(lambda v, tt=t: 255 if v > tt else 0)
    px = m.load()
    rows = [sum(1 for x in range(0, w, 4) if px[x, y]) * 4 for y in range(h)]
    cols = [sum(1 for y in range(0, h, 4) if px[x, y]) * 4 for x in range(w)]
    thr = max(30, int(w * 0.02))

    def runs(counts, lo, hi, minimum):
        best = None
        cur = None
        for i in range(lo, hi):
            if counts[i] >= minimum:
                if cur is None:
                    cur = [i, i]
                else:
                    cur[1] = i
            else:
                if counts[i - 1] >= minimum if i > lo else False:
                    pass
                if cur and (best is None or cur[1] - cur[0] > best[1] - best[0]):
                    best = cur
                cur = None
        if cur and (best is None or cur[1] - cur[0] > best[1] - best[0]):
            best = cur
        return best

    rrun = runs(rows, 0, h, thr)
    crun = runs(cols, 0, w, max(30, int(h * 0.02)))
    prof[t] = {"row_run": rrun, "col_run": crun,
               "box_wh": [crun[1] - crun[0], rrun[1] - rrun[0]] if rrun and crun else None}
EV["c2_profile_box"] = {"bg_med": list(bg), "thresholds": prof}
rr = prof[40]["row_run"]
cr = prof[40]["col_run"]
if rr and cr:
    box = [cr[0], rr[0], cr[1], rr[1]]
    iw, ih = cr[1] - cr[0], rr[1] - rr[0]
    asp = 720 / 112
    rw = max(iw, -(-ih * asp // 1))
    rh = max(ih, -(-rw / asp // 1))
    rw = max(iw, -(-rh * asp // 1))
    rh = max(ih, -(-rw / asp // 1))
    EV["c2_profile_box"]["ink_box_40"] = box
    EV["c2_profile_box"]["law_rect_px"] = [int(rw), int(rh)]
    EV["c2_profile_box"]["exceeds_frame_w"] = int(rw) > 2368

# ---- C7 direct-route reconstruction (full frame, LANCZOS) -------------------
raw7 = Image.open(RAW / DIRS["C7"] / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
rec7 = raw7.resize((720, 480), Image.LANCZOS)
landed7 = Image.open(UI / "ui_tooltip_frame.png").convert("RGBA")


def best_diff(a, bimg, tw=160):
    a2 = a.convert("RGB").resize((tw, max(1, round(tw * a.height / a.width))), Image.BICUBIC)
    bgim = Image.new("RGB", a2.size, (96, 102, 108))
    best = None
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            base = Image.new("RGB", bimg.size, (96, 102, 108))
            base.paste(bimg, (dx, dy), bimg.convert("RGBA"))
            b2 = base.resize(a2.size, Image.BICUBIC)
            dd = ImageChops.difference(a2, b2)
            st = ImageStat.Stat(dd)
            mean = sum(st.mean) / len(st.mean)
            mx = max(e[1] for e in dd.getextrema())
            if best is None or mean < best[0]:
                best = (mean, mx, dx, dy)
    return {"mean": round(best[0], 2), "max": round(best[1], 1), "shift": [best[2], best[3]]}


EV["c7_recon_full_frame"] = best_diff(rec7, landed7)

# ---- C3 / C4 end patches (luminance evidence) -------------------------------
def lum(p):
    return (p[0] + p[1] + p[2]) // 3


c3 = Image.open(UI / "ui_inline_chip.png").convert("RGBA")
p3 = c3.load()
EV["c3_left_patch"] = [[lum(p3[x, y]) for x in range(0, 32, 2)] for y in range(24, 44, 4)]
c4 = Image.open(UI / "ui_row_strip.png").convert("RGBA")
p4 = c4.load()
EV["c4_left_patch_cols"] = [round(sum(lum(p4[x, y]) for y in range(40, 112, 4)) / 18, 1)
                            for x in range(0, 96, 4)]
EV["c4_right_patch_cols"] = [round(sum(lum(p4[x, y]) for y in range(40, 112, 4)) / 18, 1)
                             for x in range(1120 - 96, 1120, 4)]

# ---- uid base36 test --------------------------------------------------------
cs = "0123456789abcdefghijklmnopqrstuvwxyz"


def dec36(txt):
    n = 0
    for ch in txt:
        n = n * 36 + cs.index(ch)
    return n


uid = "djucd2xl1ai6r"
h = hashlib.md5(b"res://assets/ui/ui_status_panel.png").digest()
EV["uid36"] = {"decoded_b36": dec36(uid),
               "md5_be64": int.from_bytes(h[:8], "big"),
               "md5_le64": int.from_bytes(h[:8], "little"),
               "match_be": dec36(uid) == int.from_bytes(h[:8], "big"),
               "match_le": dec36(uid) == int.from_bytes(h[:8], "little")}

OUT.write_text(json.dumps(EV, indent=1))
print(json.dumps(EV, indent=1))
