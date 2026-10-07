"""D21-G2-B2 driver: the owner-approved 4-run re-batch (T-140, 2026-10-05).

Re-runs C1/C2/C9/C5 on gpt-image-2-5-flare-text-to-image with the class aspect
RE-STATED (numeric proportion added to the aspect phrasing; style block and
negative list verbatim from the D21-G1 prompts), then key -> ink box ->
crop-to-master -> one uniform resize -> centre -> margins -> land, the same law
as D21-G2 (functions copied verbatim from g2_driver.py, which runs on import
and therefore cannot be imported).

Stages: prep | dryrun | run | cut.  Never backgrounded internally; every kie
subprocess is bounded (480 s).
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import random
import shutil
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

WS = Path(__file__).resolve().parents[4]
RAW = WS / "asset-library" / "raw" / "chrome-family"
UI = WS / "vajb-orbit" / "assets" / "ui"
BACKUP = WS / "asset-library" / "_prekey_backup" / "chrome_family_b2_2026-10-05"
REVIEW = WS / "asset-library" / "_review"
SLICE = WS / ".agents" / "gen" / "slices" / "D21-chrome-family"
PROMPTS = SLICE / "prompts"
LOGS = SLICE / "logs"
KIE = os.environ["KIE_GENERATE"]
MODEL = "gpt-image-2-5-flare-text-to-image"

INK_T = 48
TRIM_T = 12
CENTRE_TOL = 2
MARGIN_PASS = 2

RUNS = ["C1", "C2", "C9", "C5"]
RATIO = {"C1": "4.05", "C2": "6.43", "C9": "6.43", "C5": "1.35"}
CLASSES = {
    "C1": dict(master=(1134, 280), strip_tol=22, stems=["ui_tile_slab"],
               state=True, use=(567, 140), margins=(16, 16, 16, 16)),
    "C2": dict(master=(720, 112), strip_tol=26, stems=["ui_action_bar"],
               state=True, use=(360, 56), margins=(20, 20, 12, 12)),
    "C9": dict(master=(720, 112), strip_tol=22, stems=["ui_drawer_entry"],
               state=True, use=(272, 56), margins=(16, 16, 8, 8)),
    "C5": dict(master=(520, 384), strip_tol=22, stems=["ui_rack_bay_card"],
               state=False, use=(260, 192), margins=(10, 10, 10, 10)),
}
STATE_SHEET_CLASSES = ["C1", "C2", "C3", "C4", "C8", "C9"]
OWNER_SHEET_ORDER = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9",
                     "C10", "C11", "C12", "BG-1", "BG-2", "BG-3", "BG-4"]
DELTA_ANCHOR = (", centred in the frame with plain background margins on every "
                "side and filling about four fifths of the frame width.")


def prompt_paths() -> dict:
    return {rid: PROMPTS / f"{rid}.txt" for rid in RUNS}


def build_prompt(rid: str) -> str:
    text = prompt_paths()[rid].read_text(encoding="utf-8").strip()
    parts = text.split("\n")
    style = parts[0]
    body = "\n".join(parts[1:])
    assert body.count(DELTA_ANCHOR) == 1, f"{rid}: delta anchor not unique"
    clause = f", the plate's width about {RATIO[rid]} times its height"
    body = body.replace(DELTA_ANCHOR, clause + DELTA_ANCHOR, 1)
    return style + "\n" + body


def cmd_prep() -> None:
    plan = []
    for rid in RUNS:
        text = build_prompt(rid)
        path = PROMPTS / f"{rid}_b2.txt"
        path.write_text(text + "\n", encoding="utf-8")
        plan.append({"id": rid, "aspect": "4:3", "resolution": "2K",
                     "transparent": True, "prompt_file": str(path),
                     "prompt_chars": len(text),
                     "delta": f"inserted 'the plate's width about {RATIO[rid]} "
                              "times its height' before the centre clause; "
                              "style block + negative list verbatim from "
                              f"{rid}.txt (D21-G1)"})
    (SLICE / "g2b2_plan.json").write_text(json.dumps(plan, indent=2),
                                          encoding="utf-8")
    for row in plan:
        print(row["id"], row["prompt_chars"], "chars")


def kie_args(plan_entry: dict, dry: bool) -> list:
    prompt = Path(plan_entry["prompt_file"]).read_text(encoding="utf-8").strip()
    cmd = [sys.executable, KIE, "--model", MODEL, "--prompt", prompt,
           "--aspect", plan_entry["aspect"],
           "--resolution", plan_entry["resolution"], "--out", str(RAW)]
    if plan_entry["transparent"]:
        cmd.append("--transparent")
    cmd.append("--dry-run" if dry else "--yes")
    return cmd


def cmd_dryrun() -> None:
    plan = json.loads((SLICE / "g2b2_plan.json").read_text(encoding="utf-8"))
    c1 = plan[0]
    r = subprocess.run(kie_args(c1, dry=True), capture_output=True, text=True,
                       timeout=120)
    print(r.stdout)
    if r.returncode != 0:
        print("STDERR:", r.stderr, file=sys.stderr)
        sys.exit(r.returncode)


def cmd_run() -> None:
    plan = json.loads((SLICE / "g2b2_plan.json").read_text(encoding="utf-8"))
    LOGS.mkdir(exist_ok=True)
    status = {"started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "model": MODEL, "runs": {}}
    for entry in plan:
        rid = entry["id"]
        t0 = time.time()
        log = LOGS / f"b2_{rid}.log"
        try:
            with open(log, "w") as fh:
                p = subprocess.run(kie_args(entry, dry=False), stdout=fh,
                                   stderr=subprocess.STDOUT, timeout=480)
            rc = p.returncode
        except subprocess.TimeoutExpired:
            rc = -9
            with open(log, "a") as fh:
                fh.write("\nDRIVER TIMEOUT 480s\n")
        out = {}
        try:
            out = json.loads(log.read_text(encoding="utf-8"))
        except Exception:
            text = log.read_text(encoding="utf-8")
            try:
                out = json.loads(text[text.index("{"):text.rindex("}") + 1])
            except Exception:
                out = {"ok": False, "error": text.strip()[:400]}
        status["runs"][rid] = {
            "rc": rc, "seconds": round(time.time() - t0, 1),
            "task_id": out.get("task_id"), "estimate": out.get("estimate"),
            "local_paths": out.get("local_paths"), "ok": rc == 0 and bool(out.get("ok")),
        }
        status["updated_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        (SLICE / "g2b2_batch_status.json").write_text(json.dumps(status, indent=2),
                                                      encoding="utf-8")
        print(rid, "rc", rc, round(time.time() - t0, 1), "s", flush=True)
    print("batch done")


def render_for(rid: str, status: dict) -> Path:
    paths = status["runs"][rid].get("local_paths") or []
    if not paths:
        raise SystemExit(f"{rid}: no local render path in batch status")
    return Path(paths[0])


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
    sk = dist.point(lambda v: 255 if v >= thresh else 0)
    w, h = dist.size
    rows = sk.resize((1, h), Image.BOX).point(lambda v: 255 if v >= density else 0)
    cols = sk.resize((w, 1), Image.BOX).point(lambda v: 255 if v >= density else 0)
    rb, cb = rows.getbbox(), cols.getbbox()
    if rb is None or cb is None:
        return None
    return (cb[0], rb[1], cb[2], rb[3])


def strip_key(img: Image.Image, tol: int) -> tuple[Image.Image, dict]:
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
        for _ in range(60):
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


def ink_stats(img: Image.Image) -> dict:
    hard = img.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
    box = hard.getbbox()
    if box is None:
        return {"box": None}
    n = hard.histogram()[255]
    area = (box[2] - box[0]) * (box[3] - box[1])
    return {"box": list(box), "ink_px": n, "solidity": round(n / max(1, area), 3)}


def crop_rect_masterAspect(ink, aspect: float, frame):
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


def _band_end_scan(img: Image.Image, side: str, bright: int = 50,
                   run: int = 6) -> int:
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


def containment(img: Image.Image, rect, frame) -> dict:
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


STEM_BY_CLASS = {"C1": "ui_tile_slab", "C2": "ui_action_bar",
                 "C3": "ui_inline_chip", "C4": "ui_row_strip",
                 "C8": "ui_slot_weapon_normal", "C9": "ui_drawer_entry"}


def build_state_sheet() -> None:
    tile_w, tile_h = 300, 120
    sheet = Image.new("RGB", (tile_w * 3 + 32,
                              tile_h * len(STATE_SHEET_CLASSES) + 40), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), "state QC: normal | modulate x0.60 | modulate x0.45",
           fill=(200, 200, 200))
    for row, rid in enumerate(STATE_SHEET_CLASSES):
        stem = STEM_BY_CLASS[rid]
        path = UI / f"{stem}.png"
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
               f"{rid} {stem}", fill=(220, 220, 220))
    sheet.save(REVIEW / "qc_state_modulate_2026-10-05.png")
    small = sheet.copy()
    small.thumbnail((900, 900), Image.LANCZOS)
    small.save(REVIEW / "qc_state_modulate_2026-10-05_view.jpg", "JPEG", quality=78)
    print("state QC sheet -> _review/qc_state_modulate_2026-10-05.png")


def build_owner_sheet(b2_evidence: dict) -> None:
    g2 = json.loads((SLICE / "g2_evidence.json").read_text(encoding="utf-8"))
    tiles = []
    for rid in OWNER_SHEET_ORDER:
        rec = b2_evidence["classes"].get(rid) or g2["classes"].get(rid)
        if not rec or rec.get("verdict") != "LANDED":
            tiles.append((f"{rid} FAIL", None, {}))
            continue
        stem = rec["landed"][0]
        label = f"{rid} {stem}" + (" (one master)" if rid == "C8" else "")
        stem_path = stem if stem.endswith(".png") else stem + ".png"
        tiles.append((label, UI / stem_path, rec))
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
                bg = checker(im.size, 16)
                bg.alpha_composite(im)
                sheet.paste(bg.convert("RGB"),
                            (x + (tile - im.size[0]) // 2,
                             y + (tile - im.size[1]) // 2))
        mm = rec.get("margins_master")
        mtxt = ("margins n/a" if mm is None else
                "margins L{l} R{r} T{t} B{b}".format(**mm))
        master = rec.get("master", [0, 0])
        d.text((x + 2, y + tile + 2), label[:56], fill=(225, 225, 225))
        if master[0]:
            d.text((x + 2, y + tile + 14),
                   f"{master[0]}x{master[1]}  {mtxt}",
                   fill=(170, 200, 170))
    sheet.save(REVIEW / "chrome_family_cuts_2026-10-05.png")
    small = sheet.copy()
    small.thumbnail((1100, 1100), Image.LANCZOS)
    small.save(REVIEW / "chrome_family_cuts_2026-10-05_view.jpg", "JPEG", quality=80)
    print("owner contact sheet -> _review/chrome_family_cuts_2026-10-05.png")


def pipeline(status: dict, land: bool) -> dict:
    """Key -> ink box -> crop-to-master -> resize -> centre -> margins.

    land=False re-measures the four renders without touching any landed file
    (the sheets/evidence rebuild path; deterministic, same numbers).
    """
    evidence = {"runs": [], "classes": {}, "swaps": [], "failures": []}
    if land:
        BACKUP.mkdir(parents=True, exist_ok=True)

    for rid in RUNS:
        cfg = CLASSES[rid]
        rec: dict = {"prompt_file": f"prompts/{rid}_b2.txt",
                     "delta": f"numeric proportion {RATIO[rid]} inserted",
                     "master": list(cfg["master"])}
        run = status["runs"].get(rid, {})
        rec["task_id"] = run.get("task_id")
        rec["estimate"] = run.get("estimate")
        path = render_for(rid, status)
        rec["render"] = str(path.relative_to(WS))
        img = Image.open(path)
        rec["render_px"] = list(img.size)
        img = img.convert("RGBA")
        frame = img.size

        want = 4 / 3
        got = frame[0] / frame[1]
        rec["run_aspect_diff_pct"] = round(abs(got - want) / want * 100, 2)
        if rec["run_aspect_diff_pct"] > 2.0:
            rec["verdict"] = "FAIL run-aspect verify"
            rec["fail_cause"] = (f"frame {frame[0]}x{frame[1]} deviates "
                                 f"{rec['run_aspect_diff_pct']} % from 4:3; "
                                 "reported, never re-run without a fresh owner call")
            evidence["failures"].append({"id": rid, "cause": rec["fail_cause"]})
            evidence["classes"][rid] = rec
            print(f"{rid}: FAIL-ASPECT - {rec['fail_cause']}")
            continue

        a = img.getchannel("A")
        alpha0_pct = round(100.0 * a.histogram()[0] / (frame[0] * frame[1]), 1)
        rec["alpha0_pct"] = alpha0_pct
        if alpha0_pct > 10.0:
            img = substrate_trim(img)
            rec["key_route"] = f"substrate trim (alpha < {TRIM_T} -> 0; {alpha0_pct} % alpha-0)"
        else:
            img, kstats = strip_key(img, cfg["strip_tol"])
            rec["key_route"] = kstats["route"]
            rec["key_stats"] = {k: v for k, v in kstats.items() if k != "route"}

        istats = ink_stats(img)
        rec["ink"] = istats
        ink = istats["box"]
        aspect = cfg["master"][0] / cfg["master"][1]
        rect = crop_rect_masterAspect(ink, aspect, frame) if ink else None
        if rect is None:
            w_need = max(ink[2] - ink[0], math.ceil((ink[3] - ink[1]) * aspect))
            h_need = math.ceil(w_need / aspect)
            rec["verdict"] = "FAIL crop-to-master"
            rec["fail_cause"] = (f"master-aspect rect {w_need}x{h_need} exceeds "
                                 f"frame {frame[0]}x{frame[1]}; reported, never "
                                 "clipped, never re-run without a fresh owner call")
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

        tmp = SLICE / f"_tmp_b2_{rid}.png"
        cut.save(tmp)
        rec["centre_check"] = centre_apply(tmp)
        cut = Image.open(tmp)
        tmp.unlink()

        mm, plateaus, bands = measure_margins(cut)
        rec["margins_master"] = mm
        rec["margins_plateau_scan"] = plateaus
        rec["margins_band_scan"] = bands
        rec["pad_from_ink"] = pad_from_ink(cut)
        rec["margins_declared_master"] = [2 * v for v in cfg["margins"]]
        rec["margins_pass"] = all(
            mm[s] >= 0 and abs(mm[s] - dcl) <= MARGIN_PASS
            for s, dcl in zip(("l", "r", "t", "b"), rec["margins_declared_master"]))

        hard = cut.getchannel("A").point(lambda v: 255 if v >= INK_T else 0)
        lb = hard.getbbox()
        rec["landed_ink_box"] = list(lb) if lb else None
        rec["ink_fill_pct"] = round(100.0 * hard.histogram()[255]
                                    / (cut.size[0] * cut.size[1]), 2)

        name = cfg["stems"][0] + ".png"
        target = UI / name
        if land:
            if rid == "C5":
                old_md5 = hashlib.md5(target.read_bytes()).hexdigest()
                old_px = list(Image.open(target).size)
                shutil.move(str(target), BACKUP / name)
                evidence["swaps"].append({
                    "class": rid, "shipped": f"assets/ui/{name}",
                    "backup": ("asset-library/_prekey_backup/"
                               f"chrome_family_b2_2026-10-05/{name}"),
                    "old_px": old_px, "old_md5": old_md5,
                    "new_px": list(cfg["master"]),
                    "note": "rejected D21-G2 cut (t/b pads 89/88, fill 53.5 %)"})
            else:
                if not target.exists():
                    write_import(name)
                    rec["import_stanza"] = f"new .import for {name} (md5 scheme of D21-G2)"
                else:
                    rec["import_stanza"] = f"{name} already existed; stanza kept"
            cut.save(target)
        rec["landed"] = [name]
        rec["verdict"] = "LANDED"
        evidence["classes"][rid] = rec
        evidence["runs"].append({"id": rid, "task_id": run.get("task_id"),
                                 "render": rec["render"], "px": rec["render_px"]})
        print(f"{rid}: LANDED {name} margins={mm} fill={rec['ink_fill_pct']}% "
              f"containment={rec['containment']['pct']}%")
    return evidence


def cmd_cut() -> None:
    status = json.loads((SLICE / "g2b2_batch_status.json").read_text(encoding="utf-8"))
    evidence = pipeline(status, land=True)

    manifest = {"date": "2026-10-05", "wave": "D21-G2-B2",
                "swaps": evidence["swaps"]}
    (BACKUP / "manifest.json").write_text(json.dumps(manifest, indent=1),
                                          encoding="utf-8")

    build_state_sheet()
    build_owner_sheet(evidence)
    (SLICE / "g2b2_evidence.json").write_text(json.dumps(evidence, indent=1),
                                              encoding="utf-8")
    print("evidence -> g2b2_evidence.json")


def cmd_sheets() -> None:
    status = json.loads((SLICE / "g2b2_batch_status.json").read_text(encoding="utf-8"))
    evidence = pipeline(status, land=False)
    manifest = json.loads((BACKUP / "manifest.json").read_text(encoding="utf-8"))
    evidence["swaps"] = manifest["swaps"]
    build_state_sheet()
    build_owner_sheet(evidence)
    (SLICE / "g2b2_evidence.json").write_text(json.dumps(evidence, indent=1),
                                              encoding="utf-8")
    print("evidence -> g2b2_evidence.json")


if __name__ == "__main__":
    {"prep": cmd_prep, "dryrun": cmd_dryrun, "run": cmd_run,
     "cut": cmd_cut, "sheets": cmd_sheets}[sys.argv[1]]()