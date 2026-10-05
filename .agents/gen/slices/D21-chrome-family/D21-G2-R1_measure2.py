#!/usr/bin/env python3
"""D21-G2-R1 probe 3: band-metric fix (per-channel mean), strong-local margins,
C2 bright-bbox ink box, alpha-veil audit, backup md5 cross-check, uid decode."""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
RAW = WS / "asset-library/raw/chrome-family"
UI = WS / "vajb-orbit/assets/ui"
BK = WS / "asset-library/_prekey_backup/chrome_family_2026-10-05"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-R1_evidence2.json"
EV = {}

DIRS = {"C2": "20261005-201500", "C8": "20261005-202141", "C11": "20261005-202401",
        "C12": "20261005-202444"}


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


# ---- 1. band check fixed (mean over npos*3 terms) + diagnostics -------------
def band_diag(img, key, m):
    g = img.convert("RGB")
    w, h = g.size
    m = max(2, min(m, w // 4 if key in "lr" else h // 4))
    if key in "lr":
        x0 = 0 if key == "l" else w - m
        strip = g.crop((x0, int(h * 0.2), x0 + m, int(h * 0.8)))
        data = list(strip.getdata())
        mw = strip.size[0]
        secs = [data[i * mw:(i + 1) * mw] for i in range(strip.size[1])]
    else:
        y0 = 0 if key == "t" else h - m
        strip = g.crop((int(w * 0.2), y0, int(w * 0.8), y0 + m))
        data = list(strip.getdata())
        mw = strip.size[0]
        secs = [[data[y * mw + x] for y in range(m)] for x in range(mw)]
    npos = len(secs[0])
    grey_secs = [[(p[0] + p[1] + p[2]) // 3 for p in s] for s in secs]
    med = [sorted(s[j] for s in secs)[len(secs) // 2] for j in range(npos)]
    gmed = [sorted(s[j] for s in grey_secs)[len(secs) // 2] for j in range(npos)]
    means, maxs, gmeans = [], [], []
    for s, gs in zip(secs, grey_secs):
        ssum = smax = 0
        for j, p in enumerate(s):
            for c in range(3):
                d = abs(p[c] - med[j][c])
                ssum += d
                smax = max(smax, d)
        means.append(ssum / (npos * 3))
        maxs.append(smax)
        gmeans.append(sum(abs(v - gmed[j]) for j, v in enumerate(gs)) / npos)
    means.sort()
    maxs.sort()
    gmeans.sort()
    return {"band_px": m,
            "p95_mean": round(means[int(len(means) * 0.95)], 2),
            "max_mean": round(means[-1], 2),
            "p95_grey": round(gmeans[int(len(gmeans) * 0.95)], 2),
            "max_grey": round(gmeans[-1], 2),
            "max_abs": maxs[-1],
            "n_max_gt100": sum(1 for v in maxs if v > 100),
            "n_mean_gt30": sum(1 for v in means if v > 30)}


EV["bands_fixed"] = {}
for name, sides in (("ui_tooltip_frame.png", {"l": 21, "r": 23, "t": 48, "b": 44}),
                    ("ui_minimap_bezel.png", {"l": 39, "r": 38, "t": 39, "b": 40}),
                    ("ui_panel_frame.png", {"l": 12, "r": 13, "t": 12, "b": 14})):
    img = Image.open(UI / name).convert("RGB")
    EV["bands_fixed"][name] = {k: band_diag(img, k, v) for k, v in sides.items()}
for name, path, sides in (
        ("ui_minimap_bezel(shipped)", BK / "ui_minimap_bezel.png", {"l": 17, "r": 16, "t": 17, "b": 17}),
        ("ui_panel_frame(shipped)", BK / "ui_panel_frame.png", {"l": 24, "r": 12, "t": 12, "b": 11})):
    img = Image.open(path).convert("RGB")
    EV["bands_fixed"][name] = {k: band_diag(img, k, v) for k, v in sides.items()}

# ---- 2. margins with strong-local ornament criterion ------------------------
GRAIN_M = 14.0


def margins2(img):
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
                if d > 90:
                    strong += 1
        return s / n, strong

    def scan(pos_range, refs, getter):
        last = -1
        orn = -1
        run = 0
        for pos in pos_range:
            mad, strong = line_stat(pos, refs, getter)
            if mad > GRAIN_M or strong >= 3:
                last = pos
                run = 0
            else:
                run += 1
                if run >= 10:
                    break
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


EV["margins2"] = {}
DECL = {"ui_inline_chip.png": (16, 16, 16, 16), "ui_row_strip.png": (24, 24, 16, 16),
        "ui_rack_bay_card.png": (20, 20, 20, 20), "ui_tooltip_frame.png": (24, 24, 24, 24),
        "ui_minimap_bezel.png": (32, 32, 32, 32), "ui_panel_frame.png": (64, 64, 64, 64)}
for name in DECL:
    img = Image.open(UI / name).convert("RGBA")
    mm = margins2(img)
    mm["declared"] = list(DECL[name])
    mm["max_dev"] = max(abs(mm[k] - DECL[name][i]) for i, k in enumerate("lrtb"))
    EV["margins2"][name] = mm

# ---- 3. C2 ink box via bright-structure bbox (independent of the flood) -----
img = Image.open(RAW / DIRS["C2"] / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
bg = border_med(img)
d = ImageChops.difference(img.convert("RGB"), Image.new("RGB", img.size, bg))
r, g, b = d.split()
dist = ImageChops.lighter(ImageChops.lighter(r, g), b)
bright = dist.point(lambda v: 255 if v > 26 else 0)
box = bright.getbbox()
n = bright.histogram()[255]
EV["c2_bright_bbox"] = {"box": list(box), "wh": [box[2] - box[0], box[3] - box[1]],
                        "asp": round((box[2] - box[0]) / (box[3] - box[1]), 3),
                        "bright_px": n}
iw, ih = box[2] - box[0], box[3] - box[1]
asp = 720 / 112
rw = max(iw, -(-ih * asp // 1))
rh = max(ih, -(-rw / asp // 1))
rw = max(iw, -(-rh * asp // 1))
rh = max(ih, -(-rw / asp // 1))
EV["c2_bright_bbox"]["law_rect_px"] = [int(rw), int(rh)]
EV["c2_bright_bbox"]["exceeds_frame_w"] = int(rw) > 2368

# ---- 4. alpha-veil audit ----------------------------------------------------
def alpha_stats(img, label):
    a = img.convert("RGBA").getchannel("A")
    h = a.histogram()
    mn, mx = a.getextrema()
    mean = sum(i * v for i, v in enumerate(h)) / max(1, sum(h))
    return {"label": label, "min": mn, "max": mx, "mean": round(mean, 1),
            "pct_lt_200": round(100.0 * sum(h[:200]) / max(1, sum(h)), 2)}


EV["alpha_audit"] = []
for cid in ("C2", "C8", "C11", "C12"):
    im = Image.open(RAW / DIRS[cid] / "grimdark-painted-sci-fi-semi-realistic-1.png")
    EV["alpha_audit"].append(alpha_stats(im, f"raw {cid}"))
for name in ("ui_slot_weapon_normal.png", "ui_panel_frame.png"):
    EV["alpha_audit"].append(alpha_stats(Image.open(UI / name), f"landed {name}"))
for name in ("ui_slot_weapon_normal.png", "ui_panel_frame.png", "ui_minimap_bezel.png"):
    EV["alpha_audit"].append(alpha_stats(Image.open(BK / name), f"shipped-backup {name}"))

# ---- 5. backup md5 cross-check against the manifest -------------------------
man = json.loads((BK / "manifest.json").read_text())
rows = {}
for f in sorted(BK.glob("*.png")):
    rows[f.name] = hashlib.md5(f.read_bytes()).hexdigest()
EV["swap_md5_check"] = []
for s in man.get("swaps", []):
    bn = Path(s["shipped"]).name
    EV["swap_md5_check"].append({"class": s["class"], "file": bn,
                                 "manifest_old_md5": s.get("old_md5"),
                                 "measured_backup_md5": rows.get(bn),
                                 "match": s.get("old_md5") == rows.get(bn),
                                 "new_px": s.get("new_px")})

# ---- 6. uid decode test -----------------------------------------------------
cs = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


def dec(txt, base):
    n = 0
    for chch in txt:
        n = n * base + cs.index(chch)
    return n


uid = "djucd2xl1ai6r"
h = hashlib.md5(b"res://assets/ui/ui_status_panel.png").digest()
EV["uid_test"] = {"uid": uid,
                  "decoded_b62": dec(uid, 62),
                  "md5_be64": int.from_bytes(h[:8], "big"),
                  "md5_le64": int.from_bytes(h[:8], "little"),
                  "md5_be64_mask60": int.from_bytes(h[:8], "big") & ((1 << 60) - 1),
                  "match_b62_be": dec(uid, 62) == int.from_bytes(h[:8], "big"),
                  "match_b62_le": dec(uid, 62) == int.from_bytes(h[:8], "little")}

OUT.write_text(json.dumps(EV, indent=1))
print(json.dumps(EV, indent=1))
