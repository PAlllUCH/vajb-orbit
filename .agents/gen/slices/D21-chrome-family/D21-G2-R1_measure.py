#!/usr/bin/env python3
"""D21-G2-R1 reviewer probe v2: independent re-measurement of the D21-G2 chrome cuts.

Re-derives, from the raw renders and the landed files only:
  renders/keys/ink boxes/law rects (13.1), landed pixels+alpha+centre,
  margins from each cut's own band (mean-abs structure metric),
  uniform-band check on C7/C11/C12 (+shipped controls),
  backdrop crop provenance, swap backups, spend evidence, .import files.
Pure Pillow, no numpy, no paid calls. Writes D21-G2-R1_evidence.json.
"""
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageStat

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
RAW = WS / "asset-library/raw/chrome-family"
UI = WS / "vajb-orbit/assets/ui"
BK = WS / "asset-library/_prekey_backup/chrome_family_2026-10-05"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-R1_evidence.json"

INK_T = 12       # ink alpha threshold
GRAIN_M = 14.0   # mean-abs deviation below this = grain, not structure
STRUCT_M = 30.0  # mean-abs above this = ornament-class deviation

DIRS = {"C1": "20261005-201427", "C2": "20261005-201500", "C3": "20261005-201604",
        "C4": "20261005-201632", "C5": "20261005-201700", "C6": "20261005-201732",
        "C7": "20261005-202052", "C8": "20261005-202141", "C9": "20261005-202203",
        "C10": "20261005-202312", "C11": "20261005-202401", "C12": "20261005-202444",
        "BG1": "20261005-202512", "BG2": "20261005-202550",
        "BG3": "20261005-202617", "BG4": "20261005-203106"}
MASTERS = {"C1": (1134, 280), "C2": (720, 112), "C3": (192, 64), "C4": (1120, 152),
           "C5": (520, 384), "C6": (2720, 1032), "C7": (720, 480), "C8": (112, 112),
           "C9": (720, 112), "C10": (84, 28), "C11": (400, 400), "C12": (192, 192),
           "BG1": (2048, 874), "BG2": (2048, 874), "BG3": (2048, 874), "BG4": (2048, 874)}
USE_MARG = {"C1": (16, 16, 16, 16), "C2": (20, 20, 12, 12), "C3": (8, 8, 8, 8),
            "C4": (12, 12, 8, 8), "C5": (10, 10, 10, 10), "C7": (12, 12, 12, 12),
            "C9": (16, 16, 8, 8), "C11": (16, 16, 16, 16), "C12": (32, 32, 32, 32)}
OPAQUE_RET = {"C2", "C8", "C11", "C12"}
STRIP_TOL = {"C2": 26, "C11": 22, "C12": 22}
LANDED = {"C3": ["ui_inline_chip.png"], "C4": ["ui_row_strip.png"],
          "C5": ["ui_rack_bay_card.png"], "C6": ["ui_armory_console.png"],
          "C7": ["ui_tooltip_frame.png"],
          "C8": ["ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
                 "ui_slot_inventory_normal.png"],
          "C10": ["ui_bar_caps.png"], "C11": ["ui_minimap_bezel.png"],
          "C12": ["ui_panel_frame.png"],
          "BG1": ["ui_backdrop_armory_deck.png"], "BG2": ["ui_backdrop_refinery_deck.png"],
          "BG3": ["ui_backdrop_market_deck.png"], "BG4": ["ui_backdrop_dock_deck.png"]}
EV = {"renders": {}, "landed": {}, "bands": {}, "band_controls": {}, "backdrops": {},
      "backups": {}, "ledger": {}, "imports": {}, "misc": {}}


def load_raw(cid):
    p = RAW / DIRS[cid] / "grimdark-painted-sci-fi-semi-realistic-1.png"
    return Image.open(p).convert("RGBA"), p


def border_med(img, band=8):
    w, h = img.size
    px = img.load()
    ch = [[], [], []]
    stepx = max(1, w // 100)
    stepy = max(1, h // 100)
    for x in range(0, w, stepx):
        for y in list(range(band)) + list(range(h - band, h)):
            p = px[x, y]
            for c in range(3):
                ch[c].append(p[c])
    for y in range(0, h, stepy):
        for x in list(range(band)) + list(range(w - band, w)):
            p = px[x, y]
            for c in range(3):
                ch[c].append(p[c])
    return tuple(sorted(a)[len(a) // 2] for a in ch)


def dist_to(img, bg):
    rgb = img.convert("RGB")
    d = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg))
    r, g, b = d.split()
    return ImageChops.lighter(ImageChops.lighter(r, g), b)


def flood_ink(dist, tol):
    """Border-connected background flood at half res (the law's strip route);
    returns full-res ink mask (255 = ink)."""
    w, h = dist.size
    sw, sh = max(2, w // 2), max(2, h // 2)
    dark_full = dist.point(lambda v: 255 if v <= tol else 0)
    small = dark_full.resize((sw, sh), Image.BOX).point(lambda v: 255 if v >= 250 else 0)
    bg = Image.new("L", (sw, sh), 0)
    d = ImageDraw.Draw(bg)
    px = small.load()
    for x in range(sw):
        for y in (0, sh - 1):
            if px[x, y] == 255:
                d.point((x, y), 255)
    for y in range(sh):
        for x in (0, sw - 1):
            if px[x, y] == 255:
                d.point((x, y), 255)
    for _ in range(900):
        nxt = ImageChops.darker(small, bg.filter(ImageFilter.MaxFilter(5)))
        if ImageChops.difference(nxt, bg).getextrema()[1] == 0:
            break
        bg = nxt
    bg_full = bg.resize((w, h), Image.NEAREST)
    bg_full = ImageChops.multiply(bg_full, dark_full)
    return ImageChops.invert(bg_full)


def alpha_mask(img):
    return img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)


def box_stats(mask):
    box = mask.getbbox()
    if box is None:
        return None
    n = mask.histogram()[255]
    area = (box[2] - box[0]) * (box[3] - box[1])
    return {"box": list(box), "ink_px": n, "solidity": round(n / area, 3),
            "asp": round((box[2] - box[0]) / (box[3] - box[1]), 3)}


def law_rect(box, asp, frame):
    il, it, ir, ib = box
    iw, ih = ir - il, ib - it
    w = max(iw, math.ceil(ih * asp))
    h = max(ih, math.ceil(w / asp))
    w = max(iw, math.ceil(h * asp))
    h = max(ih, math.ceil(w / asp))
    if w > frame[0] or h > frame[1]:
        return None, (w, h)
    cx, cy = (il + ir) / 2.0, (it + ib) / 2.0
    x0 = max(0, min(int(round(cx - w / 2.0)), frame[0] - w))
    y0 = max(0, min(int(round(cy - h / 2.0)), frame[1] - h))
    return (x0, y0, x0 + w, y0 + h), (w, h)


def key_render(cid):
    img, path = load_raw(cid)
    w, h = img.size
    rec = {"dir": DIRS[cid], "render_px": [w, h], "mode": Image.open(path).mode}
    if rec["mode"] == "RGBA":
        a = img.getchannel("A").histogram()
        rec["alpha0_pct"] = round(100.0 * sum(a[:8]) / (w * h), 1)
        rec["alpha_partial_px"] = sum(a[1:255])
    if cid in OPAQUE_RET:
        bg = border_med(img)
        rec["border_med"] = list(bg)
        if max(bg) > 40:
            rec["key"] = "refused: border band is plate grey, not void substrate"
            rec["ink"] = {"box": [0, 0, w, h], "ink_px": w * h, "solidity": 1.0}
            return img, rec
        dist = dist_to(img, bg)
        ladder = []
        chosen = None
        for t in (STRIP_TOL[cid], max(6, STRIP_TOL[cid] - 8), max(6, STRIP_TOL[cid] - 16)):
            ink = flood_ink(dist, t)
            st = box_stats(ink)
            ladder.append({"tol": t, "solidity": st["solidity"],
                           "flood_pct": round(100.0 * (1 - st["ink_px"] / (w * h)), 1),
                           "box": st["box"]})
            if st["solidity"] >= 0.45:
                chosen = (t, ink, st)
                break
        rec["ladder"] = ladder
        if chosen is None:
            rec["key"] = "refused after ladder: every tolerance leaks into the interior"
            rec["ink"] = {"box": [0, 0, w, h], "ink_px": w * h, "solidity": 1.0}
            return img, rec
        t, ink, st = chosen
        rec["key"] = f"strip flood clean at tol {t}"
        rec["ink"] = st
        out = img.copy()
        out.putalpha(ink)
        return out, rec
    rec["key"] = "substrate alpha (transparent return)"
    rec["ink"] = box_stats(alpha_mask(img))
    return img.copy(), rec


def centre_of(mask):
    box = mask.getbbox()
    if box is None:
        return None
    w, h = mask.size
    return (round((box[0] + box[2]) / 2.0 - (w - 1) / 2.0, 2),
            round((box[1] + box[3]) / 2.0 - (h - 1) / 2.0, 2))


def margins(img):
    """Margin = distance from each edge to the last line whose mean-abs deviation
    from the interior reference line exceeds GRAIN_M (grain-robust). A coarse
    sweep past the break point catches late ornament (orn_extent, sweep max)."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    xs = list(range(int(w * 0.15), int(w * 0.85), max(1, w // 50)))
    ys = list(range(int(h * 0.15), int(h * 0.85), max(1, h // 50)))
    yr, xr = h // 2, w // 2
    refs_l = [px[xr, y] for y in ys]
    refs_t = [px[x, yr] for x in xs]

    def scan(pos_range, refs, getter):
        last = -1
        orn = -1
        run = 0
        stop = None
        for pos in pos_range:
            s = 0
            n = 0
            for i, ref in enumerate(refs):
                p = getter(pos, i)
                for c in range(4):
                    s += abs(p[c] - ref[c])
                    n += 1
            mad = s / n
            if mad > GRAIN_M:
                last = pos
                run = 0
            else:
                run += 1
                if run >= 10:
                    stop = pos
                    break
            if mad > STRUCT_M:
                orn = pos
        sweep_max = 0.0
        sweep_orn = -1
        if stop is not None:
            mid = (w // 2) if getter is not None else None
            for pos in list(pos_range)[max(0, (list(pos_range).index(stop) if stop in list(pos_range) else 0))::4]:
                s = 0
                n = 0
                for i, ref in enumerate(refs):
                    p = getter(pos, i)
                    for c in range(4):
                        s += abs(p[c] - ref[c])
                        n += 1
                mad = s / n
                sweep_max = max(sweep_max, mad)
                if mad > STRUCT_M:
                    sweep_orn = max(sweep_orn, pos if pos < (w // 2) else pos)
        return last, orn, sweep_max, sweep_orn

    l_last, l_orn, ls_max, ls_orn = scan(range(0, w // 2), refs_l, lambda x, i: px[x, ys[i]])
    r_last, r_orn, rs_max, rs_orn = scan(range(w - 1, w // 2, -1), refs_l, lambda x, i: px[x, ys[i]])
    t_last, t_orn, ts_max, ts_orn = scan(range(0, h // 2), refs_t, lambda y, i: px[xs[i], y])
    b_last, b_orn, bs_max, bs_orn = scan(range(h - 1, h // 2, -1), refs_t, lambda y, i: px[xs[i], y])
    return {"m": {"l": l_last + 1 if l_last >= 0 else 0,
                  "r": (w - r_last) if r_last >= 0 else 0,
                  "t": t_last + 1 if t_last >= 0 else 0,
                  "b": (h - b_last) if b_last >= 0 else 0},
            "orn_extent": {"l": l_orn + 1 if l_orn >= 0 else 0,
                           "r": (w - r_orn) if r_orn >= 0 else 0,
                           "t": t_orn + 1 if t_orn >= 0 else 0,
                           "b": (h - b_orn) if b_orn >= 0 else 0},
            "sweep": {"l": [round(ls_max, 1), ls_orn], "r": [round(rs_max, 1), rs_orn],
                      "t": [round(ts_max, 1), ts_orn], "b": [round(bs_max, 1), bs_orn]}}


def band_check(img, marg):
    """Edge band identical along its run: per cross-section mean-abs and max-abs
    deviation from the band's median cross-section, at the measured margins."""
    g = img.convert("RGB")
    w, h = g.size
    out = {}
    for key in ("l", "r", "t", "b"):
        m = marg[key]
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
        med = []
        for j in range(npos):
            col = sorted(s[j] for s in secs)
            med.append(col[len(col) // 2])
        means = []
        maxs = []
        for s in secs:
            ssum = 0
            smax = 0
            for j, p in enumerate(s):
                for c in range(3):
                    d = abs(p[c] - med[j][c])
                    ssum += d
                    if d > smax:
                        smax = d
            means.append(ssum / npos)
            maxs.append(smax)
        means.sort()
        maxs.sort()
        out[key] = {"band_px": m,
                    "p95_mean": round(means[int(len(means) * 0.95)], 2),
                    "max_mean": round(means[-1], 2),
                    "max_abs": maxs[-1],
                    "struct_secs": sum(1 for a, b2 in zip(means, maxs)
                                       if a > STRUCT_M or b2 > 100)}
    return out


def composite_grey(img):
    bg = Image.new("RGBA", img.size, (96, 102, 108, 255))
    return Image.alpha_composite(bg, img.convert("RGBA")).convert("RGB")


def diff_stats(a, b):
    if a.size != b.size:
        b = b.resize(a.size, Image.BICUBIC)
    d = ImageChops.difference(a, b)
    st = ImageStat.Stat(d)
    mx = max(e[1] for e in d.getextrema())
    return {"mean": round(sum(st.mean) / len(st.mean), 2), "max": mx}


def diff_best(recon, landed, tw=160):
    """Full-canvas content diff over mid-grey, with a +/-2 px alignment search."""
    a = composite_grey(recon).resize((tw, max(1, round(tw * recon.height / recon.width))), Image.BICUBIC)
    best = None
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            base = Image.new("RGB", landed.size, (96, 102, 108))
            base.paste(landed, (dx, dy), landed.convert("RGBA"))
            b = base.resize(a.size, Image.BICUBIC)
            st = diff_stats(a, b)
            if best is None or st["mean"] < best[0]["mean"]:
                best = (st, dx, dy)
    return {"mean": best[0]["mean"], "max": best[0]["max"], "shift": [best[1], best[2]]}


# ---- 1. renders + keys + law rects (all 16) --------------------------------
for cid in DIRS:
    img, rec = key_render(cid)
    master = MASTERS[cid]
    asp = master[0] / master[1]
    if cid not in ("BG1", "BG2", "BG3", "BG4"):
        st = rec["ink"]
        rect, size = law_rect(st["box"], asp, img.size)
        rec["law_rect"] = None if rect is None else list(rect)
        rec["law_rect_px"] = list(size)
        rec["law_rect_fits"] = rect is not None
        rec["law_rect_aspect_err_pct"] = round(
            100.0 * abs(size[0] / size[1] - asp) / asp, 3)
        if rect is not None:
            m = alpha_mask(img)
            inside = m.crop(rect).histogram()[255]
            rec["containment_pct"] = round(100.0 * inside / max(1, st["ink_px"]), 2)
        if cid in ("C4", "C3", "C5", "C6", "C7"):
            rw, rh = size if rect else (master[0], master[1])
            rec["scale_fx"] = round(master[0] / rw, 5)
            rec["scale_fy"] = round(master[1] / rh, 5)
            rec["skew_pct"] = round(100.0 * abs(master[0] / rw - master[1] / rh)
                                    / (master[1] / rh), 3)
    EV["renders"][cid] = rec

# ---- 2. landed cuts ---------------------------------------------------------
for cid, names in LANDED.items():
    master = MASTERS[cid]
    for name in names:
        img = Image.open(UI / name)
        rgba = img.convert("RGBA") if img.mode != "RGBA" else img
        w, h = rgba.size
        rec = {"file": name, "px": [w, h], "mode": img.mode,
               "master": list(master), "exact_master_px": (w, h) == tuple(master)}
        if img.mode == "RGBA":
            a = img.getchannel("A").histogram()
            rec["alpha0_pct"] = round(100.0 * sum(a[:8]) / (w * h), 2)
            rec["alpha_partial_px"] = sum(a[1:255])
            m = alpha_mask(rgba)
            st = box_stats(m)
            rec["ink"] = st
            rec["fill_pct"] = round(100.0 * st["ink_px"] / (w * h), 1)
            rec["centre_off"] = centre_of(m)
            rec["opaque"] = rec["alpha0_pct"] == 0.0
            wpx = rgba.load()
            ring = 0
            for x in range(w):
                if wpx[x, 0][3] >= INK_T:
                    ring += 1
                if wpx[x, h - 1][3] >= INK_T:
                    ring += 1
            for y in range(1, h - 1):
                if wpx[0, y][3] >= INK_T:
                    ring += 1
                if wpx[w - 1, y][3] >= INK_T:
                    ring += 1
            rec["border_fringe_px"] = ring
            rec["containment_pct"] = 100.0 if rec["opaque"] else None
        else:
            rec["opaque"] = True
            rec["fill_pct"] = 100.0
            rec["centre_off"] = [0, 0]
            rec["containment_pct"] = 100.0
        if cid in USE_MARG:
            mm = margins(rgba)
            rec["margins_measured"] = mm["m"]
            rec["orn_extent"] = mm["orn_extent"]
            rec["margins_sweep"] = mm["sweep"]
            decl = USE_MARG[cid]
            rec["margins_declared_master"] = [decl[0] * 2, decl[1] * 2,
                                              decl[2] * 2, decl[3] * 2]
            rec["margins_max_dev_px"] = max(
                abs(mm["m"][k] - decl[i] * 2) for i, k in enumerate("lrtb"))
        EV["landed"][name] = rec

# ---- 3. reconstruction against the law pipeline -----------------------------
for cid in ("C3", "C4", "C5", "C6", "C7", "C8", "C10", "C11", "C12"):
    raw, _ = load_raw(cid)
    rrec = EV["renders"][cid]
    master = MASTERS[cid]
    if rrec.get("law_rect_fits"):
        rec_img = raw.crop(tuple(rrec["law_rect"])).resize(master, Image.LANCZOS)
    else:
        rec_img = raw.resize(master, Image.LANCZOS)
    for name in LANDED[cid]:
        landed = Image.open(UI / name)
        EV["landed"][name]["recon_vs_landed"] = diff_best(rec_img, landed)

# ---- 4. uniform-band check: C7/C11/C12 + shipped controls -------------------
for name in ("ui_tooltip_frame.png", "ui_minimap_bezel.png", "ui_panel_frame.png"):
    img = Image.open(UI / name).convert("RGBA")
    mm = margins(img)
    EV["bands"][name] = band_check(img, mm["m"])
for name, path in (("ui_minimap_bezel(shipped)", BK / "ui_minimap_bezel.png"),
                   ("ui_panel_frame(shipped)", BK / "ui_panel_frame.png")):
    img = Image.open(path).convert("RGBA")
    mm = margins(img)
    EV["band_controls"][name] = band_check(img, mm["m"])

# ---- 5. backdrops -----------------------------------------------------------
for cid in ("BG1", "BG2", "BG3", "BG4"):
    raw, _ = load_raw(cid)
    w, h = raw.size
    asp = 1765 / 753
    if w / h > asp:
        rw, rh = round(h * asp), h
    else:
        rw, rh = w, round(w / asp)
    x0, y0 = (w - rw) // 2, (h - rh) // 2
    crop = raw.crop((x0 + 2, y0 + 2, x0 + rw - 2, y0 + rh - 2))
    rec_img = crop.resize(MASTERS[cid], Image.BICUBIC).convert("RGB")
    name = LANDED[cid][0]
    landed = Image.open(UI / name)
    rec = {"file": name, "px": list(landed.size), "mode": landed.mode,
           "master": list(MASTERS[cid]),
           "exact_master_px": landed.size == MASTERS[cid],
           "crop_rect_raw_wh": [rw, rh],
           "crop_aspect": round(rw / rh, 5), "target_aspect": round(asp, 5)}
    amin, amax = landed.convert("RGBA").getchannel("A").getextrema()
    rec["alpha_min_max"] = [amin, amax]
    rec["opaque_no_alpha"] = amin == 255
    rec["vs_my_crop"] = diff_stats(
        rec_img.resize((160, 68), Image.BICUBIC),
        landed.convert("RGB").resize((160, 68), Image.BICUBIC))
    EV["backdrops"][name] = rec

# ---- 6. backups / swap pairs ------------------------------------------------
man = json.loads((BK / "manifest.json").read_text())
EV["backups"]["manifest"] = man
rows = {}
for f in sorted(BK.glob("*.png")):
    md5 = hashlib.md5(f.read_bytes()).hexdigest()
    rows[f.name] = {"px": list(Image.open(f).size), "md5": md5}
swaps = man.get("swaps", []) if isinstance(man, dict) else []
for s in swaps:
    n = s.get("shipped", s.get("name", "")) if isinstance(s, dict) else ""
    if n in rows and isinstance(s, dict) and "md5" in s:
        rows[n]["manifest_md5_match"] = s["md5"] == rows[n]["md5"]
for stem, bkname in (("ui_armory_console.png", "ui_armory_console.png"),
                     ("ui_bar_caps.png", "ui_bar_caps.png"),
                     ("ui_minimap_bezel.png", "ui_minimap_bezel.png"),
                     ("ui_panel_frame.png", "ui_panel_frame.png"),
                     ("ui_slot_weapon_normal.png", "ui_slot_weapon_normal.png"),
                     ("ui_slot_cargo_normal.png", "ui_slot_cargo_normal.png"),
                     ("ui_slot_inventory_normal.png", "ui_slot_inventory_normal.png")):
    if bkname in rows:
        rows[bkname]["landed_md5_differs"] = (
            hashlib.md5((UI / stem).read_bytes()).hexdigest() != rows[bkname]["md5"])
EV["backups"]["files"] = rows
EV["backups"]["c8_three_names_identical"] = len({
    hashlib.md5((UI / n).read_bytes()).hexdigest() for n in LANDED["C8"]}) == 1

# ---- 7. spend evidence ------------------------------------------------------
led = WS / "asset-library/_keying/recraft_ledger.jsonl"
EV["ledger"]["recraft_ledger_lines"] = sum(1 for _ in led.open()) if led.exists() else None
cache = WS / "asset-library/_keying/recraft"
EV["ledger"]["recraft_cache_json"] = len(list(cache.glob("*.json"))) if cache.exists() else None
EV["ledger"]["raw_dir_count"] = len(list(RAW.glob("20261005-*")))

# ---- 8. .import stanzas -----------------------------------------------------
all_uids = {}
for ip in UI.glob("*.import"):
    txt = ip.read_text(errors="replace")
    for ln in txt.splitlines():
        if ln.startswith("uid="):
            all_uids[ip.name] = ln.split("=", 1)[1].strip().strip('"')
            break
dup = {}
for k, v in all_uids.items():
    dup.setdefault(v, []).append(k)
EV["imports"]["uid_collisions"] = {v: ks for v, ks in dup.items() if len(ks) > 1}
EV["imports"]["md5_res_path_ui_status_panel"] = hashlib.md5(
    b"res://assets/ui/ui_status_panel.png").hexdigest()
EV["imports"]["ui_status_panel_uid"] = all_uids.get("ui_status_panel.png.import")


def enc(n, base, cs):
    out = ""
    while n:
        out = cs[n % base] + out
        n //= base
    return out


uid_target = all_uids.get("ui_status_panel.png.import", "").replace("uid://", "")
h = hashlib.md5(b"res://assets/ui/ui_status_panel.png").digest()
c62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
tries = {"b36_be": enc(int.from_bytes(h[:8], "big"), 36, c62[:36]),
         "b36_le": enc(int.from_bytes(h[:8], "little"), 36, c62[:36]),
         "b62_be": enc(int.from_bytes(h[:8], "big"), 62, c62),
         "b32_be": enc(int.from_bytes(h[:8], "big"), 32, "0123456789abcdefghijklmnopqrstuv")}
EV["imports"]["uid_derivation_match"] = [k for k, v in tries.items() if v == uid_target]
for names in LANDED.values():
    for name in names:
        ip = UI / (name + ".import")
        ok = ip.exists()
        rec = {"import_exists": ok}
        if ok:
            txt = ip.read_text(errors="replace")
            rec["has_uid"] = "uid=" in txt
            rec["source_ok"] = f'source_file="res://assets/ui/{name}"' in txt
            rec["has_dest"] = "dest_files" in txt
        EV["imports"][name] = rec

# ---- 9. misc ----------------------------------------------------------------
c10 = Image.open(UI / "ui_bar_caps.png").convert("RGBA")
apx = c10.getchannel("A").load()
w, h = c10.size
mid = [apx[x, y] for x in range(w // 3, 2 * w // 3) for y in range(h)]
EV["misc"]["c10_mid_alpha_min"] = min(mid)
EV["misc"]["c10_mid_partial_px"] = sum(1 for v in mid if 0 < v < 250)
c6 = Image.open(UI / "ui_armory_console.png").convert("RGBA")
b6 = alpha_mask(c6).getbbox()
EV["misc"]["c6_pad_t"] = b6[1]
EV["misc"]["c6_pad_b"] = c6.height - b6[3]
c8l = Image.open(UI / "ui_slot_weapon_normal.png").convert("RGBA")
EV["misc"]["c8_landed_corner_px"] = [list(c8l.getpixel((0, 0))), list(c8l.getpixel((111, 111)))]
c8r, _ = load_raw("C8")
c8r_a = c8r.getchannel("A").histogram()
EV["misc"]["c8_raw_alpha_hist"] = {"a0": c8r_a[0], "a_partial": sum(c8r_a[1:255]),
                                   "a255": c8r_a[255],
                                   "corner_px": [list(c8r.getpixel((0, 0))),
                                                 list(c8r.getpixel((2047, 2047)))]}
SUBJ = {"BG1": "ordnance", "BG2": "processing", "BG3": "lockers", "BG4": "mooring"}
EV["misc"]["bg_subject_map"] = {
    cid: {"dir": DIRS[cid], "keyword_in_prompt": kw in (RAW / DIRS[cid] / "job.json").read_text(errors="replace")}
    for cid, kw in SUBJ.items()}
EV["misc"]["cut_sheet_exists"] = (WS / "asset-library/_review/chrome_family_cuts_2026-10-05.png").exists()
EV["misc"]["state_qc_sheet_exists"] = (WS / "asset-library/_review/qc_state_modulate_2026-10-05.png").exists()
EV["misc"]["c1c2c9_stems_absent"] = all(
    not (UI / n).exists() for n in ("ui_tile_slab.png", "ui_action_bar.png", "ui_drawer_entry.png"))

OUT.write_text(json.dumps(EV, indent=1))

print("== R1 digest v2 ==")
for cid in ("C1", "C2", "C9", "C3", "C4", "C5", "C6", "C7", "C8", "C10", "C11", "C12"):
    r = EV["renders"][cid]
    print(cid, "|", r["key"], "| ink", r["ink"]["box"], r["ink"]["solidity"],
          "| law_rect", r["law_rect_px"], "fits", r["law_rect_fits"],
          "| contain", r.get("containment_pct"), "| skew", r.get("skew_pct"))
for name, rec in EV["landed"].items():
    print(name, rec["px"], "exact", rec["exact_master_px"], "mode", rec["mode"],
          "a0%", rec.get("alpha0_pct"), "fill", rec.get("fill_pct"),
          "ctr", rec.get("centre_off"), "fringe", rec.get("border_fringe_px"),
          "marg", rec.get("margins_measured"), "decl", rec.get("margins_declared_master"),
          "orn", rec.get("orn_extent"), "recon", rec.get("recon_vs_landed"))
print("bands:", json.dumps(EV["bands"]))
print("controls:", json.dumps(EV["band_controls"]))
print("backdrops:", json.dumps({k: {kk: vv for kk, vv in v.items()
                                    if kk in ("px", "mode", "exact_master_px", "opaque_no_alpha",
                                              "crop_aspect", "target_aspect", "vs_my_crop")}
                                 for k, v in EV["backdrops"].items()}))
print("backups:", json.dumps({k: v for k, v in EV["backups"].items() if k not in ("files", "manifest")}))
for k, v in EV["backups"]["files"].items():
    print("  bk", k, v)
print("manifest:", json.dumps(EV["backups"]["manifest"])[:400])
print("ledger:", EV["ledger"])
print("imports: collisions", EV["imports"]["uid_collisions"],
      "| md5", EV["imports"]["md5_res_path_ui_status_panel"],
      "| uid", EV["imports"]["ui_status_panel_uid"],
      "| derivation", EV["imports"]["uid_derivation_match"])
missing = [n for names in LANDED.values() for n in names if not EV["imports"][n]["import_exists"]]
bad_source = [n for names in LANDED.values() for n in names
              if EV["imports"][n]["import_exists"] and not EV["imports"][n]["source_ok"]]
print("imports missing:", missing, "bad_source:", bad_source)
print("misc:", json.dumps(EV["misc"]))
