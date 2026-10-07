"""D21-G2-B2-R1: independent re-measurement of the four B2 chrome cuts.

Own keying (border-connected flood from a 12 px band median, own tol ladder,
morphological opening against star specks), own law-rect maths, own margin
profiles, own sheet rebuilds. Reads anything; writes only this slice folder.
No paid calls. Pure Pillow, bounded, never backgrounded.
"""
from __future__ import annotations

import hashlib
import json
import math
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
SLICE = WS / ".agents" / "gen" / "slices" / "D21-chrome-family"
RAW = WS / "asset-library" / "raw" / "chrome-family"
UI = WS / "vajb-orbit" / "assets" / "ui"
BACKUP = WS / "asset-library" / "_prekey_backup" / "chrome_family_b2_2026-10-05"
REVIEW = WS / "asset-library" / "_review"
SPEC = WS / "docs" / "design" / "UI_CHROME_ASSETS_SPEC.md"

RUNS = ["C1", "C2", "C9", "C5"]
RENDER_DIR = {"C1": "20261005-224516", "C2": "20261005-224538",
              "C9": "20261005-224600", "C5": "20261005-224628"}
MASTER = {"C1": (1134, 280), "C2": (720, 112), "C9": (720, 112), "C5": (520, 384)}
RATIO = {"C1": "4.05", "C2": "6.43", "C9": "6.43", "C5": "1.35"}
OUT = {"generated_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}


# ---------- part 1: prompts vs spec 13.1 ----------
def spec_blocks() -> tuple[str, dict]:
    text = SPEC.read_text(encoding="utf-8")
    marker = "The one shared style block + framing"
    i = text.index(marker)
    f1 = text.index("```", i)
    f2 = text.index("```", f1 + 3)
    style = text[f1 + 4:f2].strip("\n")
    heads = {"C1": "C1 tile slab", "C2": "C2 action bar",
             "C5": "C5 rack bay card", "C9": "C9 drawer entry plate"}
    bodies = {}
    for rid, h in heads.items():
        j = text.index("**" + h)
        f1 = text.index("```", j)
        f2 = text.index("```", f1 + 3)
        bodies[rid] = text[f1 + 4:f2].strip("\n")
    return style, bodies


def check_prompts() -> None:
    style, bodies = spec_blocks()
    res = {}
    for rid in RUNS:
        b2 = (SLICE / "prompts" / f"{rid}_b2.txt").read_text(encoding="utf-8").strip()
        g1 = (SLICE / "prompts" / f"{rid}.txt").read_text(encoding="utf-8").strip()
        parts = b2.split("\n")
        style_b2, body_b2 = parts[0], "\n".join(parts[1:])
        clause = f", the plate's width about {RATIO[rid]} times its height"
        restored = body_b2.replace(clause, "", 1)
        res[rid] = {
            "style_verbatim_spec": style_b2 == style,
            "body_minus_clause_eq_spec": restored == bodies[rid],
            "body_minus_clause_eq_g1": ("\n".join(g1.split("\n")[1:])) == restored,
            "g1_body_eq_spec": ("\n".join(g1.split("\n")[1:])) == bodies[rid],
            "clause_count": body_b2.count(clause),
            "b2_chars": len(b2), "g1_chars": len(g1),
        }
    OUT["prompts"] = res


# ---------- part 2: own ink derivation ----------
def band_median(img: Image.Image, band: int = 12):
    w, h = img.size
    px: list[tuple] = []
    for box in ((0, 0, w, band), (0, h - band, w, h),
                (0, 0, band, h), (w - band, 0, w, h)):
        px.extend(list(img.crop(box).getdata()))
    chans = []
    for c in range(3):
        chans.append(sorted(p[c] for p in px)[len(px) // 2])
    return tuple(chans)


def border_connected_bg(rgb: Image.Image, tol: int):
    """Background = pixels within tol of the border median that are connected
    to the border. Flood on a half-res binary mask, then refine at full res."""
    w, h = rgb.size
    bg = band_median(rgb)
    diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg))
    r, g, b = diff.split()
    dist = ImageChops.lighter(ImageChops.lighter(r, g), b)
    dark = dist.point(lambda v, t=tol: 255 if v <= t else 0)
    sw, sh = w // 2, h // 2
    small = dark.resize((sw, sh), Image.BOX).point(lambda v: 255 if v >= 250 else 0)
    work = small.copy()
    step = 12
    for x in range(0, sw, step):
        for sy in (0, sh - 1):
            if work.getpixel((x, sy)) == 255:
                ImageDraw.floodfill(work, (x, sy), 128, thresh=0)
    for y in range(0, sh, step):
        for sx in (0, sw - 1):
            if work.getpixel((sx, y)) == 255:
                ImageDraw.floodfill(work, (sx, y), 128, thresh=0)
    grown = work.point(lambda v: 255 if v == 128 else 0).resize((w, h), Image.NEAREST)
    grown = ImageChops.multiply(grown, dark)
    for _ in range(80):
        nxt = ImageChops.multiply(grown.filter(ImageFilter.MaxFilter(3)), dark)
        if ImageChops.difference(grown, nxt).getextrema()[1] == 0:
            break
        grown = nxt
    share = round(1 - grown.histogram()[0] / (w * h), 4)
    return grown, bg, share


def ink_mask(img: Image.Image) -> tuple[Image.Image, dict]:
    alpha0 = img.getchannel("A").histogram()[0]
    w, h = img.size
    info = {"alpha0_pct": round(100.0 * alpha0 / (w * h), 1)}
    if info["alpha0_pct"] > 10.0:
        a = img.getchannel("A")
        mask = a.point(lambda v: 255 if v >= 48 else 0)
        info["route"] = "alpha>=48 (transparent return)"
        info["box_a1"] = list(a.point(lambda v: 255 if v >= 1 else 0).getbbox())
    else:
        rgb = img.convert("RGB")
        grown, bg, share = border_connected_bg(rgb, 22)
        info["bg_med_mine"] = list(bg)
        info["flood_share_tol22"] = share
        keep = grown.point(lambda v: 255 if v == 0 else 0)
        info["unbounded_keep_box"] = list(keep.getbbox())
        diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg))
        r, g, b = diff.split()
        dist = ImageChops.lighter(ImageChops.lighter(r, g), b)
        core = dist.point(lambda v: 255 if v >= 60 else 0)
        rows = core.resize((1, h), Image.BOX).point(lambda v: 255 if v >= 9 else 0)
        cols = core.resize((w, 1), Image.BOX).point(lambda v: 255 if v >= 9 else 0)
        rb, cb = rows.getbbox(), cols.getbbox()
        sbox = (cb[0], rb[1], cb[2], rb[3])
        info["structure_box"] = list(sbox)
        pad_box = (max(0, sbox[0] - 6), max(0, sbox[1] - 6),
                   min(w, sbox[2] + 6), min(h, sbox[3] + 6))
        inside = Image.new("L", (w, h), 0)
        ImageDraw.Draw(inside).rectangle(pad_box, fill=255)
        mask = ImageChops.multiply(keep, inside)
        mask = (mask.filter(ImageFilter.MinFilter(3))
                    .filter(ImageFilter.MaxFilter(3)))
        info["route"] = ("own border-connected flood tol 22, bounded by own "
                         "bright-structure box (dist>=60, row/col density>=9) "
                         "+ 3x3 opening")
    info["solidity"] = None
    return mask, info


def law_rect(ink, aspect: float, frame):
    l, t, r, b = ink
    iw, ih = r - l, b - t
    w = max(iw, math.ceil(ih * aspect))
    h = max(ih, math.ceil(w / aspect))
    w2 = max(iw, math.ceil(h * aspect))
    if w2 > w:
        w = w2
        h = max(ih, math.ceil(w / aspect))
    if w > frame[0] or h > frame[1]:
        return None, (w, h)
    cx, cy = (l + r) / 2.0, (t + b) / 2.0
    x0 = int(round(cx - w / 2.0))
    y0 = int(round(cy - h / 2.0))
    x0 = max(0, min(x0, frame[0] - w))
    y0 = max(0, min(y0, frame[1] - h))
    return (x0, y0, x0 + w, y0 + h), (w, h)


def check_renders() -> None:
    g2 = json.loads((SLICE / "g2_evidence.json").read_text(encoding="utf-8"))
    b2 = json.loads((SLICE / "g2b2_evidence.json").read_text(encoding="utf-8"))
    res = {}
    for rid in RUNS:
        path = RAW / RENDER_DIR[rid] / "grimdark-painted-sci-fi-semi-realistic-1.png"
        img = Image.open(path).convert("RGBA")
        w, h = img.size
        rec = {"render": str(path.relative_to(WS)), "px": [w, h],
               "aspect_diff_pct_4x3": round(abs(w / h - 4 / 3) / (4 / 3) * 100, 3)}
        mask, kinfo = ink_mask(img)
        rec.update(kinfo)
        box = mask.getbbox()
        rec["ink_box_mine"] = list(box)
        iw, ih = box[2] - box[0], box[3] - box[1]
        rec["ink_wh_mine"] = [iw, ih]
        rec["ink_aspect_mine"] = round(iw / ih, 3)
        rec["ink_frame_w_pct"] = round(100.0 * iw / w, 1)
        rec["g1_ink_aspect"] = None
        g1ink = (g2.get("classes", {}).get(rid, {}) or {}).get("ink", {}).get("box")
        if g1ink:
            rec["g1_ink_aspect"] = round((g1ink[2] - g1ink[0]) / (g1ink[3] - g1ink[1]), 3)
        aspect = MASTER[rid][0] / MASTER[rid][1]
        rect, need = law_rect(box, aspect, (w, h))
        rec["law_rect_needed_wh_mine"] = list(need)
        if rect is None:
            rec["verdict_mine"] = "FAIL crop-to-master (rect exceeds frame)"
            res[rid] = rec
            continue
        rec["law_rect_mine"] = list(rect)
        b2rect = b2["classes"][rid].get("crop_rect")
        if b2rect:
            rec["b2_crop_rect"] = b2rect
            rec["rect_delta"] = [a - c for a, c in zip(rect, b2rect)]
            hard = mask
            total = hard.histogram()[255]
            inside = hard.crop(b2rect).histogram()[255]
            rec["containment_mine_pct"] = round(100.0 * inside / max(1, total), 3)
            incrop = hard.crop(b2rect)
            cb = incrop.getbbox()
            exp = (box[0] - b2rect[0], box[1] - b2rect[1],
                   box[2] - b2rect[0], box[3] - b2rect[1])
            rec["incrop_ink_bbox"] = list(cb) if cb else None
            rec["incrop_expected_bbox"] = exp
            rec["clipped_ink_px"] = total - inside
            fx = MASTER[rid][0] / (b2rect[2] - b2rect[0])
            fy = MASTER[rid][1] / (b2rect[3] - b2rect[1])
            rec["resize_factors_mine"] = [round(fx, 6), round(fy, 6)]
            rec["scale_skew_pct"] = round(abs(fx - fy) / fx * 100, 4)
        rec["verdict_mine"] = "FIT"
        res[rid] = rec
    OUT["renders"] = res


# ---------- part 3: landed C5 ----------
def profile_margin(img: Image.Image, side: str) -> dict:
    a = img.getchannel("A")
    grey = img.convert("L")
    w, h = img.size
    horiz = side in ("l", "r")
    n = w if horiz else h
    m = h if horiz else w
    lo, hi = int(m * 0.25), int(m * 0.75)
    limit = n // 2

    def line(i):
        box = (i, lo, i + 1, hi) if horiz else (lo, i, hi, i + 1)
        al = a.crop(box)
        amin = al.getextrema()[0]
        if amin < 200:
            return None
        lum = list(grey.crop(box).getdata())
        return sum(lum) / len(lum)

    prof = [line(i) for i in range(limit)]
    known = [v for v in prof if v is not None]
    inner = sorted(known[len(known) // 3:])[len(known[len(known) // 3:]) // 2]
    first_settled = -1
    run_need, tol = 12, 4.0
    count = 0
    for i, v in enumerate(prof):
        if v is None or abs(v - inner) > tol:
            count = 0
            continue
        count += 1
        if count >= run_need:
            first_settled = i - run_need + 1
            break
    grad = -1
    for i in range(1, limit):
        if prof[i] is None or prof[i - 1] is None:
            continue
        if abs(prof[i] - prof[i - 1]) >= 12 and prof[i + 1 if i + 1 < limit else i] is not None:
            grad = i
            break
    return {"settled": first_settled, "first_gradient": grad, "inner_ref": round(inner, 1)}


def check_landed() -> None:
    path = UI / "ui_rack_bay_card.png"
    data = path.read_bytes()
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    rec = {"px": [w, h], "md5": hashlib.md5(data).hexdigest(),
           "aspect_exact_65x48": w * 48 == h * 65}
    a = img.getchannel("A")
    hist = a.histogram()
    rec["alpha0_px"] = hist[0]
    rec["alpha_buckets"] = {"a0": hist[0],
                            "a1_99": sum(hist[1:100]),
                            "a100_199": sum(hist[100:200]),
                            "a200_249": sum(hist[200:250]),
                            "a250plus": sum(hist[250:])}
    rec["alpha_ge250_pct"] = round(100.0 * sum(hist[250:]) / (w * h), 2)
    raw_c5 = Image.open(
        RAW / RENDER_DIR["C5"] / "grimdark-painted-sci-fi-semi-realistic-1.png"
    ).convert("RGBA")
    rh = raw_c5.getchannel("A").histogram()
    rec["raw_c5_alpha_buckets"] = {"a0": rh[0], "a1_99": sum(rh[1:100]),
                                  "a100_199": sum(rh[100:200]),
                                  "a200_249": sum(rh[200:250]),
                                  "a250plus": sum(rh[250:])}
    old_cut = Image.open(BACKUP / "ui_rack_bay_card.png").convert("RGBA")
    oh = old_cut.getchannel("A").histogram()
    rec["old_g2_cut_alpha_buckets"] = {"a0": oh[0], "a200_249": sum(oh[200:250]),
                                      "a250plus_pct": round(
                                          100.0 * sum(oh[250:]) /
                                          (old_cut.size[0] * old_cut.size[1]), 2)}
    hard = a.point(lambda v: 255 if v >= 48 else 0)
    box = hard.getbbox()
    rec["ink_box_mine_a48"] = list(box)
    rec["ink_box_mine_a1"] = list(a.point(lambda v: 255 if v >= 1 else 0).getbbox())
    iw, ih = box[2] - box[0], box[3] - box[1]
    rec["ink_aspect_mine"] = round(iw / ih, 3)
    rec["master_aspect"] = round(w / h, 4)
    rec["ink_fill_pct"] = round(100.0 * hard.histogram()[255] / (w * h), 2)
    cx = (box[0] + box[2]) / 2.0
    cy = (box[1] + box[3]) / 2.0
    rec["centre_offset_mine"] = [round(cx - w / 2.0, 2), round(cy - h / 2.0, 2)]
    rec["pads_mine_a48"] = {"l": box[0], "t": box[1], "r": w - box[2], "b": h - box[3]}
    marg = {}
    for s in ("l", "r", "t", "b"):
        marg[s] = profile_margin(img, s)
    rec["margins_mine"] = marg
    OUT["landed_c5"] = rec


# ---------- part 4: backup, assets, ledger ----------
def check_state() -> None:
    rec = {}
    bp = BACKUP / "ui_rack_bay_card.png"
    rec["backup_exists"] = bp.exists()
    rec["backup_md5"] = hashlib.md5(bp.read_bytes()).hexdigest() if bp.exists() else None
    rec["backup_px"] = list(Image.open(bp).size) if bp.exists() else None
    man = json.loads((BACKUP / "manifest.json").read_text(encoding="utf-8"))
    rec["manifest_swap_row"] = man["swaps"][0]
    landed = UI / "ui_rack_bay_card.png"
    rec["landed_md5"] = hashlib.md5(landed.read_bytes()).hexdigest()
    rec["landed_import_stanza"] = (UI / "ui_rack_bay_card.png.import").exists()
    for stem in ("ui_tile_slab.png", "ui_action_bar.png", "ui_drawer_entry.png"):
        rec[f"stem_absent_{stem}"] = not (UI / stem).exists()
        rec[f"import_absent_{stem}"] = not (UI / f"{stem}.import").exists()
    variants = [p.name for p in UI.glob("ui_*.png")
                if any(p.name.endswith(s + ".png") for s in
                       ("_pressed", "_hover", "_disabled"))]
    rec["state_variant_files"] = variants
    recraft = WS / "asset-library" / "_keying" / "recraft"
    rec["recraft_oct5_evening"] = []
    recraft = WS / "asset-library" / "_keying" / "recraft"
    if recraft.exists():
        cutoff = time.mktime(time.strptime("2026-10-05 22:00", "%Y-%m-%d %H:%M"))
        rec["recraft_oct5_evening"] = sorted(
            p.name for p in recraft.glob("*") if p.stat().st_mtime > cutoff)
    variant_mt = {p.name: time.strftime(
        "%m-%d %H:%M", time.localtime(p.stat().st_mtime))
        for p in UI.glob("ui_*_pressed.png")}
    rec["variant_file_mtimes_sample"] = dict(sorted(variant_mt.items())[:4])
    raw_dirs = sorted(p.name for p in RAW.iterdir() if p.is_dir())
    rec["raw_dir_count"] = len(raw_dirs)
    rec["raw_b2_dirs"] = raw_dirs[-4:]
    led = Path("/home/kamil-paluszkiewicz/.local/share/crush/skills/"
               "image-generator/usage-ledger.jsonl")
    lines = [json.loads(x) for x in led.read_text(encoding="utf-8").splitlines() if x.strip()]
    flare = [x for x in lines if "flare" in x.get("model", "")]
    rec["ledger_entries"] = len(lines)
    rec["ledger_flare"] = len(flare)
    ids_json = json.loads((SLICE / "g2b2_batch_status.json").read_text(encoding="utf-8"))
    b2_ids = {r["task_id"] for r in ids_json["runs"].values()}
    new = [x for x in lines if x.get("task_id") in b2_ids]
    rec["b2_ledger_rows"] = [{k: x.get(k) for k in ("ts", "task_id", "model", "aspect",
                                                    "resolution", "est_credits")}
                             for x in new]
    rec["b2_ledger_all_flare"] = all("flare" in x.get("model", "") for x in new)
    idx = {x.get("task_id"): i for i, x in enumerate(lines)}
    first_b2 = min(idx[t] for t in b2_ids if t in idx)
    rec["rows_between_last_g1_and_first_b2"] = [
        {"ts": x.get("ts"), "model": x.get("model"), "task_id": x.get("task_id")}
        for x in lines[:first_b2][-3:]]
    last_b2 = max(idx[t] for t in b2_ids if t in idx)
    rec["ledger_rows_after_b2"] = [
        {k: x.get(k) for k in ("ts", "task_id", "model", "aspect", "resolution",
                               "est_credits")} for x in lines[last_b2 + 1:]]
    new_dirs = sorted(p.name for p in RAW.iterdir()
                      if p.is_dir() and p.name > "20261005-224628")
    rec["raw_dirs_after_b2"] = new_dirs
    jobs = {}
    for dname in new_dirs:
        jb = RAW / dname / "job.json"
        if jb.exists():
            j = json.loads(jb.read_text(encoding="utf-8"))
            prompt = j.get("prompt", "")
            marker = [r for r in RUNS if f"width about {RATIO[r]} times" in prompt]
            jobs[dname] = {"task_id": j.get("task_id"),
                           "ratio_clause": marker,
                           "b3_style": "never wider than tall" in prompt
                                       or "three quarters of the frame height" in prompt,
                           "prompt_head": prompt[:80]}
    rec["post_b2_job_json"] = jobs
    OUT["state"] = rec


# ---------- part 5: sheet rebuilds ----------
def rebuild_owner(tag: str, c5_source: Path) -> Image.Image:
    b2 = json.loads((SLICE / "g2b2_evidence.json").read_text(encoding="utf-8"))
    g2 = json.loads((SLICE / "g2_evidence.json").read_text(encoding="utf-8"))
    order = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9",
             "C10", "C11", "C12", "BG-1", "BG-2", "BG-3", "BG-4"]
    tiles = []
    for rid in order:
        rec = b2["classes"].get(rid) or g2["classes"].get(rid)
        if not rec or rec.get("verdict") != "LANDED":
            tiles.append((f"{rid} FAIL", None, {}))
            continue
        stem = rec["landed"][0]
        label = f"{rid} {stem}" + (" (one master)" if rid == "C8" else "")
        p = UI / (stem if stem.endswith(".png") else stem + ".png")
        if rid == "C5":
            p = c5_source
        tiles.append((label, p, rec))
    cols, tile, pad, label_h = 4, 330, 10, 30
    rows = (len(tiles) + cols - 1) // cols
    W = cols * (tile + pad) + pad
    H = rows * (tile + pad + label_h) + pad + 26
    sheet = Image.new("RGB", (W, H), (14, 16, 20))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 6), "D21 chrome family cuts - landed 2026-10-05 "
                     "(B2 re-runs of C1/C2/C9/C5; checker = transparency)",
           fill=(210, 214, 220))
    for i, (label, path, rec) in enumerate(tiles):
        x = pad + (i % cols) * (tile + pad)
        y = 26 + pad + (i // cols) * (tile + pad + label_h)
        d.rectangle([x, y, x + tile - 1, y + tile - 1], outline=(70, 76, 84))
        if path is None or not path.exists():
            d.text((x + 8, y + 40), "FAIL - not landed", fill=(200, 70, 27))
        else:
            with Image.open(path) as im:
                im = im.convert("RGBA")
                im.thumbnail((tile - 8, tile - 8), Image.LANCZOS)
                bgc = Image.new("RGB", (32, 32), (58, 60, 66))
                dd = ImageDraw.Draw(bgc)
                dd.rectangle([0, 0, 15, 15], fill=(84, 86, 92))
                dd.rectangle([16, 16, 31, 31], fill=(84, 86, 92))
                bgc = bgc.resize(im.size, Image.NEAREST).convert("RGBA")
                bgc.alpha_composite(im)
                sheet.paste(bgc.convert("RGB"),
                            (x + (tile - im.size[0]) // 2,
                             y + (tile - im.size[1]) // 2))
        mm = rec.get("margins_master")
        mtxt = ("margins n/a" if mm is None else
                "margins L{l} R{r} T{t} B{b}".format(**mm))
        master = rec.get("master", [0, 0])
        d.text((x + 2, y + tile + 2), label[:56], fill=(225, 225, 225))
        if master[0]:
            d.text((x + 2, y + tile + 14),
                   f"{master[0]}x{master[1]}  {mtxt}", fill=(170, 200, 170))
    sheet.save(SLICE / f"D21-G2-B2-R1_owner_sheet_{tag}.png")
    return sheet


def diff_sheets(a: Image.Image, b: Image.Image) -> dict:
    if a.size != b.size:
        return {"same_size": False, "a": a.size, "b": b.size}
    d = ImageChops.difference(a, b)
    bbox = d.getbbox()
    ext = d.getextrema()
    return {"same_size": True, "diff_bbox": list(bbox) if bbox else None,
            "max_channel_delta": ext[1][0] if isinstance(ext[1], tuple) else ext[1]}


def rebuild_state() -> Image.Image:
    stems = {"C1": "ui_tile_slab", "C2": "ui_action_bar", "C3": "ui_inline_chip",
             "C4": "ui_row_strip", "C8": "ui_slot_weapon_normal", "C9": "ui_drawer_entry"}
    tile_w, tile_h = 300, 120
    sheet = Image.new("RGB", (tile_w * 3 + 32, tile_h * 6 + 40), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), "state QC: normal | modulate x0.60 | modulate x0.45",
           fill=(200, 200, 200))
    for row, rid in enumerate(stems):
        path = UI / f"{stems[rid]}.png"
        if not path.exists():
            d.text((16, 30 + row * tile_h - 12),
                   f"{rid} {stems[rid]} - no landed cut (state QC n/a)",
                   fill=(200, 140, 130))
            continue
        art = Image.open(path).convert("RGBA")
        art.thumbnail((tile_w - 24, tile_h - 24), Image.LANCZOS)
        base = Image.new("RGB", (16, 16), (58, 60, 66))
        dd = ImageDraw.Draw(base)
        dd.rectangle([0, 0, 7, 7], fill=(84, 86, 92))
        dd.rectangle([8, 8, 15, 15], fill=(84, 86, 92))
        base = base.resize(art.size, Image.NEAREST).convert("RGBA")
        base.alpha_composite(art)
        for col, mul in enumerate((1.0, 0.60, 0.45)):
            cell = base
            if mul != 1.0:
                r, g, b, al = base.split()
                cell = Image.merge("RGBA", tuple(
                    c.point(lambda v, mm=mul: int(v * mm)) for c in (r, g, b)) + (al,))
            x = 16 + col * tile_w + (tile_w - 24 - art.size[0]) // 2
            y = 30 + row * tile_h + (tile_h - 24 - art.size[1]) // 2
            sheet.paste(cell.convert("RGB"), (x, y))
        d.text((16, 30 + row * tile_h - 12), f"{rid} {stems[rid]}",
               fill=(220, 220, 220))
    sheet.save(SLICE / "D21-G2-B2-R1_state_sheet_rebuild.png")
    return sheet


def check_sheets() -> None:
    shipped_owner = Image.open(REVIEW / "chrome_family_cuts_2026-10-05.png").convert("RGB")
    mine_new = rebuild_owner("new", UI / "ui_rack_bay_card.png")
    mine_old = rebuild_owner("old", BACKUP / "ui_rack_bay_card.png")
    res = {"shipped_owner_px": list(shipped_owner.size),
           "rebuild_new_vs_shipped": diff_sheets(mine_new, shipped_owner),
           "rebuild_old_vs_shipped": diff_sheets(mine_old, shipped_owner)}
    shipped_state = Image.open(REVIEW / "qc_state_modulate_2026-10-05.png").convert("RGB")
    mine_state = rebuild_state()
    res["shipped_state_px"] = list(shipped_state.size)
    res["rebuild_state_vs_shipped"] = diff_sheets(mine_state, shipped_state)
    OUT["sheets"] = res


if __name__ == "__main__":
    check_prompts()
    check_renders()
    check_landed()
    check_state()
    check_sheets()
    (SLICE / "D21-G2-B2-R1_evidence.json").write_text(
        json.dumps(OUT, indent=1), encoding="utf-8")
    print(json.dumps(OUT, indent=1)[:6000])