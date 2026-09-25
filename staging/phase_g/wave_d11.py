"""D11-A1 driver: render, cut, key, trim and QC the approved station element set.

Wave D11 (`D11_BRIEF.md`), the plan of record is `D11-A0_report.md`'s 15-row render
table (15 files = 15 runs = 150 credits = $0.75), the style source is
`vajb-orbit/assets/style-block.txt` verbatim as the prompt preamble (ENVIRONMENT_SPEC
section 8), and the panel order is law (AGENTS.md Phase G):

    render (flare, 2K 1:1) -> panels.py --detect -> cut each object
        -> key each cut (local auto-key first, recraft only if it fails)
        -> trim -> QC -> ship

QC per file (the task's green set): qc_fx_alpha-style containment on the keyed cut,
final transparent share > 10 %, the section 9 negative list (saturated / second-accent
pixel scan), and section 6's one-emissive hard line (ember hot pixels only on the hero
and the two lamp runs). The hero additionally carries the approved scale floor: its
canvas is padded to 2048 px so frame = 2048 x 0.1459 = 298.8 u (footprint x2.2 of
today's 135.8 u) with content >= 87.7 % per axis (mockup's +/-131 u dashed content).

Usage:
    python3 staging/phase_g/wave_d11.py render [name ...] [--dry-run]
    python3 staging/phase_g/wave_d11.py build [name ...]
    python3 staging/phase_g/wave_d11.py qc
    python3 staging/phase_g/wave_d11.py ship
    python3 staging/phase_g/wave_d11.py review
"""
from __future__ import annotations

import argparse
import json
import math
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import panels
import wave_g

ROOT = wave_g.ROOT
STAGE = wave_g.STAGE
SKILL = wave_g.SKILL
PY = sys.executable
FAMILY = STAGE / "env"
D11 = FAMILY / "d11"
CUTS = D11 / "cuts"
FINAL = D11 / "final"
SHIP = ROOT / "vajb-orbit" / "assets" / "env" / "poi"
GEN_LOG = ROOT / "vajb-orbit" / "assets" / "env" / "generation_log_d11.md"
STYLE = ROOT / "vajb-orbit" / "assets" / "style-block.txt"
KEY_NEW = STAGE / "key_new.py"
QC_SCRIPT = ROOT / "staging" / "cut" / "qc_fx_alpha.py"

## Approved mockup (D11-A0_report.md): hero frame 298.8 u at the effective scale, so the
## shipped hero canvas must be >= 2048 px; content >= 87.7 % of the canvas per axis keeps
## the visible hull at the mockup's +/-131 u (2.20x today's 119.1 u).
HERO_CANVAS = 2048
HERO_SCALE = 0.1459            # 0.0663 x 2.2, the approved pin's effective scale
HERO_CONTENT_MIN = 1796        # 262.0 u / 0.1459 = the mockup's 2.2x visible hull
HERO_AREA_TARGET = 0.88        # final transparent share ~12 % (> the 10 % QC floor)

TRANSPARENT_MIN = 0.10         # final files: > 10 % of pixels at alpha 0
HOT_NONE_MAX = 0.0005          # no-emissive rows: ember-hot pixels < 0.05 % of ink
                               # (clean rows measure <= 0.00013; the furnace-glow
                               # violations on windows_a/b measure >= 0.00099)
ACCENT_MAX = 0.001             # section 9: saturated non-ember pixels < 0.1 % of ink
CROP_TOL = 8                   # qc_fx_alpha's own containment tolerance, px
PART_FLOOR = 800               # px; see keep_parts()
INK_RETENTION_MIN = 0.85       # final ink / keyed ink, the subject-must-survive row

FRAME = ("single game sprite: one object centred in frame, top-down orthographic view, "
         "the object fills about 80 percent of the frame, isolated on a flat solid void "
         "black #0A0E14 background with nothing else in frame")
FRAME_HERO = ("single game sprite: one object centred in frame, top-down orthographic "
              "view, the station hull spans the frame nearly edge to edge and fills at "
              "least 90 percent of the frame, isolated on a flat solid void black #0A0E14 "
              "background with nothing else in frame")
NEG = ("no planets, no atmosphere, no nebula, no bright nebula, no saturated colours, "
       "no second accent colour, no purple, no green, no teal, no yellow, no chrome, "
       "no neon, no perspective, no tilt, no text, no watermark, no grid lines, no "
       "labels, no border, no frame, no vignette")

## The A0 plan of record's 15 rows, subjects keeping its ENVIRONMENT vocabulary verbatim.
NO_GLOW = "no emissive, no glow"
RUNS: dict[str, dict] = {
    "env_station_hero": dict(
        hero=True, emissive=True,
        subject=("top-down station hero: welded platework in gunmetal mid #3A3F46 and "
                 "gunmetal dark #2B2F35, panel seams and rivet lines, heavy hull grime "
                 "films, rust streaks from the seams and rivets, pitted metal, a cold "
                 "steel rim tracing the shadow-side silhouette, one value step darker "
                 "than ships; ember warning lamps are the only emissive: small hot burnt "
                 "ember #C8461B lamp points along the hull, no halo beyond the points")),
    "env_station_arm_a": dict(
        subject=("a truss docking arm of welded platework in gunmetal mid #3A3F46 and "
                 "gunmetal dark #2B2F35, weld beads over the joints, hull grime, rust "
                 "streaks from the seams, a cold steel rim on the shadow side; " + NO_GLOW)),
    "env_station_arm_b": dict(
        subject=("a truss docking arm of welded platework in gunmetal mid and gunmetal "
                 "dark, weld beads over the joints, a distinct weathering pass with "
                 "heavier grime and longer rust streaks than the other docking arm, a "
                 "cold steel rim; " + NO_GLOW)),
    "env_station_mast_a": dict(
        subject=("an antenna and mast cluster on a welded platework base, gunmetal mid "
                 "and gunmetal dark plating, hull grime, rust streaks at the foot, a "
                 "cold steel rim; " + NO_GLOW)),
    "env_station_mast_b": dict(
        subject=("an antenna and mast cluster on a welded platework base, gunmetal mid "
                 "and gunmetal dark plating, a distinct weathering pass from the other "
                 "mast cluster, hull grime, rust streaks at the foot, a cold steel rim; "
                 + NO_GLOW)),
    "env_station_gantry_a": dict(
        subject=("a rail gantry crane of welded platework in gunmetal mid and gunmetal "
                 "dark, heavy hull grime along the rail, rust streaks at the wheels, a "
                 "cold steel rim; " + NO_GLOW)),
    "env_station_gantry_b": dict(
        subject=("a rail gantry crane of welded platework in gunmetal mid and gunmetal "
                 "dark standing on its slew pivot, a pivot plate and a counterweight jib, "
                 "grime, rust streaks at the pivot, a cold steel rim; " + NO_GLOW)),
    "env_station_windows_a": dict(
        subject=("a horizontal band of lit hull windows painted pale steel-highlight "
                 "#565C63 on gunmetal mid and gunmetal dark plating, grime around the "
                 "frames, rust streaks below the sills; the light is painted, not "
                 "glowing, " + NO_GLOW)),
    "env_station_windows_b": dict(
        subject=("a horizontal band of lit hull windows painted pale steel-highlight "
                 "#565C63 on gunmetal mid and gunmetal dark plating, a distinct "
                 "weathering pass from the other window band, grime around the frames, "
                 "rust streaks below the sills; the light is painted, not glowing, "
                 + NO_GLOW)),
    "env_station_plate_a": dict(
        subject=("a raised hull-plate spine: welded platework seams and rivet lines in "
                 "gunmetal mid and gunmetal dark, hull grime film, rust streaks bleeding "
                 "from the rivets; " + NO_GLOW)),
    "env_station_plate_b": dict(
        subject=("a raised hull-plate spine: welded platework seams and rivet lines in "
                 "gunmetal mid and gunmetal dark, a distinct weathering pass from the "
                 "other plate spine, hull grime film, rust streaks bleeding from the "
                 "rivets; " + NO_GLOW)),
    "env_station_lamp_a": dict(
        emissive=True,
        subject=("a run of ember warning lamps: small hot burnt ember #C8461B lamp "
                 "points in a row on a gunmetal dark strip with rivets and grime; the "
                 "ember warning lamps are the only emissive, small hot points with no "
                 "halo beyond them")),
    "env_station_lamp_b": dict(
        emissive=True,
        subject=("a run of ember warning lamps with a distinct lamp spacing from the "
                 "other run: small hot burnt ember #C8461B lamp points in a row on a "
                 "gunmetal dark strip with rivets and grime; the ember warning lamps are "
                 "the only emissive, small hot points with no halo beyond them")),
    "env_station_shuttle_a": dict(
        subject=("a top-down service shuttle, gunmetal mid and gunmetal dark hull with a "
                 "cold steel rim, hull grime, rust streaks on the aft plating; the "
                 "engines stay dark, " + NO_GLOW)),
    "env_station_shuttle_b": dict(
        subject=("a top-down service shuttle, gunmetal mid and gunmetal dark hull with a "
                 "cold steel rim, a distinct weathering pass from the other shuttle, "
                 "hull grime, rust streaks on the aft plating; the engines stay dark, "
                 + NO_GLOW)),
}

## One re-prompt per file, keyed by the failure class (the task's rule: a render that
## ignores its brief gets re-prompted once, and a file that still violates is not shipped).
REINFORCE = {
    "emissive": (" absolutely no glow and no emissive anywhere on this object, no bloom, "
                 "no light sources, the metal is completely unlit dark paint"),
    "lamps": (" the small hot burnt ember #C8461B warning-lamp points must clearly be "
              "visible along the hull, as small hot points with no halo"),
    "background": (" the background must be one flat solid void black #0A0E14 colour "
                   "with no gradient, no glow and no vignette anywhere"),
    "hero": (" the station must span the frame edge to edge, filling at least 92 percent "
             "of the frame width and height"),
    "accent": (" use only the desaturated gunmetal and rust palette, absolutely no "
               "saturated colours and no accent colour other than burnt ember lamps"),
    "object": (" exactly one object in frame, centred, fully inside the frame, nothing "
               "else drawn anywhere"),
}


def prompt_for(name: str, extra: str = "") -> str:
    spec = RUNS[name]
    frame = FRAME_HERO if spec.get("hero") else FRAME
    body = f"{frame}: {spec['subject']}. {NEG}{extra}"
    return STYLE.read_text(encoding="utf-8").strip() + "\n\n" + body


def log(text: str) -> None:
    print(text, flush=True)


def run_render(names: list[str], dry: bool = False, extra: str = "", tag: str = "") -> int:
    suffix = f"_{tag}" if tag else ""
    FAMILY.mkdir(parents=True, exist_ok=True)
    D11.mkdir(parents=True, exist_ok=True)
    failures = 0
    for name in names:
        prompt = prompt_for(name, extra)
        cmd = [PY, str(SKILL), "--model", "flare", "--aspect", "1:1", "--resolution", "2K",
               "--out", str(FAMILY), "--prompt", prompt]
        if dry:
            cmd.append("--dry-run")
        else:
            cmd.append("--yes")
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                              errors="replace")
        if proc.returncode != 0:
            log(f"[{name}] FAILED rc={proc.returncode}\n{proc.stdout[-800:]}\n{proc.stderr[-800:]}")
            failures += 1
            continue
        if dry:
            log(f"[{name}] dry-run:\n{proc.stdout.strip()}")
            continue
        payload = json.loads(proc.stdout)
        master = Path(payload["local_paths"][0])
        dest = D11 / f"{name}_render{suffix}.png"
        shutil.copy2(master, dest)
        job_src = Path(master).parent / "job.json"
        record = {
            "file": name,
            "model": "gpt-image-2-5-flare-text-to-image (flare)",
            "resolution": "2K 1:1",
            "task_id": payload.get("task_id", "?"),
            "elapsed_s": payload.get("elapsed_s", "?"),
            "date": datetime.now().isoformat(timespec="seconds"),
            "master": str(dest),
            "run_folder": str(Path(master).parent),
            "prompt": prompt,
            "attempt": tag or "pass1",
        }
        if job_src.exists():
            shutil.copy2(job_src, D11 / f"{name}_render{suffix}.job.json")
            record["job_json"] = str(D11 / f"{name}_render{suffix}.job.json")
        (D11 / f"{name}_render{suffix}.json").write_text(json.dumps(record, indent=1),
                                                       encoding="utf-8")
        log(f"[{name}] ok task={record['task_id']} {record['elapsed_s']}s -> {dest.name}")
    return 0 if not failures else 1


def detect_and_cut(name: str, render: Path) -> tuple[Path | None, str]:
    """panels.py --detect then panels.py --cut, exactly the law's two commands."""
    json_out = D11 / f"{name}_detect.json"
    proc = subprocess.run([PY, str(STAGE / "panels.py"), "--detect", str(render),
                           "--grid", "1x1", "--json", str(json_out)],
                          capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        return None, f"detect rc={proc.returncode}: {proc.stderr[-200:]}"
    detail = " | ".join(line.strip() for line in proc.stdout.splitlines() if line.strip())
    CUTS.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run([PY, str(STAGE / "panels.py"), "--cut", str(render),
                           "--out", str(CUTS), "--names", name, "--grid", "1x1"],
                          capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        return None, f"cut rc={proc.returncode}: {proc.stderr[-200:]}"
    cut = CUTS / f"{name}.png"
    if not cut.exists():
        return None, "cut produced no file"
    return cut, detail


def auto_key(cut: Path) -> Path | None:
    """The free local key (`--strip-only`, PIL colour key from the cut's flat black)."""
    proc = subprocess.run([PY, str(SKILL), "--strip-only", str(cut)],
                          capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        log(f"    auto-key rc={proc.returncode}: {(proc.stderr or proc.stdout)[-300:]}")
        return None
    try:
        return Path(json.loads(proc.stdout)["alpha_paths"][0])
    except Exception:
        return None


def recraft_key(cut: Path) -> Path | None:
    proc = subprocess.run([PY, str(KEY_NEW), str(cut)], capture_output=True, text=True,
                          encoding="utf-8", errors="replace")
    keyed = cut.with_name(f"{cut.stem}-keyed.png")
    if proc.returncode != 0 or not keyed.exists():
        log(f"    recraft rc={proc.returncode}: {(proc.stderr or proc.stdout)[-300:]}")
        return None
    return keyed


def structural_fail(row: dict) -> bool:
    delta = row["box_delta"]
    if delta is None:
        return True
    return (delta[0] > CROP_TOL or delta[1] > CROP_TOL or delta[2] < -CROP_TOL
            or delta[3] < -CROP_TOL or row["transparent_share"] < 0.05
            or (row["kept_mean_rgb"] and min(row["kept_mean_rgb"]) > 200.0))


def accent_share(rgb: np.ndarray, ink: np.ndarray) -> float:
    """Section 9's second-accent scan: saturated pixels whose hue is not ember/rust.

    Only visible art counts: keyed background remnants sit at alpha > 8 but are near-black
    void blue (measured mean (7, 10, 14) on the hero), and they would otherwise flag as a
    "saturated" second accent purely for being blue-black.
    """
    arr = rgb.astype(np.int16)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    mx = arr.max(axis=2).astype(np.float32)
    mn = arr.min(axis=2).astype(np.float32)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    delta = np.maximum(mx - mn, 1e-6)
    hue = np.zeros_like(mx)
    hue = np.where(mx == r, (60.0 * (g - b) / delta) % 360.0, hue)
    hue = np.where(mx == g, 60.0 * (b - r) / delta + 120.0, hue)
    hue = np.where(mx == b, 60.0 * (r - g) / delta + 240.0, hue)
    visible = mx > 45
    wrong = (sat > 0.6) & ~(((hue >= 340.0) | (hue <= 40.0))) & visible
    hit = wrong & ink
    return float(hit.sum()) / max(int(ink.sum()), 1)


def hot_share(rgb: np.ndarray, ink: np.ndarray) -> tuple[int, float]:
    """Ember-hot pixels: bright, strongly red-dominant (lamps and ember glow only)."""
    arr = rgb.astype(np.int16)
    hot = (arr[..., 0] > 170) & ((arr[..., 0] - arr[..., 2]) > 80)
    hit = hot & ink
    return int(hit.sum()), float(hit.sum()) / max(int(ink.sum()), 1)


def keep_parts(image: Image.Image) -> tuple[Image.Image, int]:
    """Drop speck components only; keep every plate section of a multi-part sprite.

    `wave_g.keep_main`'s 10 %-of-biggest floor is tuned for hull sheets (one subject per
    cell). These station elements are multi-part platework that the model draws with
    near-black seams, so the cut separates them into islands: at the 10 % floor lamp_a
    lost its whole ember-lamp run (7019 hot px -> 157), shuttle_a lost both wings and
    windows_a lost hull modules (measured 2026-09-24). Everything below PART_FLOOR px is
    film grain or a keyed dust speck; everything at or above it is art.
    """
    alpha = np.asarray(image.getchannel("A"))
    opaque = alpha > 8
    labels, count = ndimage.label(opaque, np.ones((3, 3), int))
    if count <= 1:
        return image, 0
    sizes = ndimage.sum(opaque, labels, range(1, count + 1))
    keep_ids = [index for index in range(1, count + 1)
                if sizes[index - 1] >= PART_FLOOR]
    dropped = max((int(sizes[index - 1]) for index in range(1, count + 1)
                   if sizes[index - 1] < PART_FLOOR), default=0)
    mask = np.isin(labels, keep_ids)
    out = image.copy()
    out.putalpha(Image.fromarray(np.where(mask, alpha, 0).astype(np.uint8)))
    return out, dropped


def finalize(name: str, keyed: Path, cut: Path) -> tuple[Path | None, dict]:
    spec = RUNS[name]
    image = Image.open(keyed).convert("RGBA")
    k_alpha = np.asarray(image.getchannel("A"))
    k_ink = int((k_alpha > 8).sum())
    k_rgb = np.asarray(image.convert("RGB"))
    k_hot, _ = hot_share(k_rgb, k_alpha > 8)
    image, dropped_max = keep_parts(image)
    info: dict = {"keyed_ink_px": k_ink, "keyed_hot_px": k_hot,
                  "largest_dropped_px": dropped_max}
    if spec.get("hero"):
        alpha = np.asarray(image.getchannel("A"))
        rows = np.where(alpha.max(axis=1) > 8)[0]
        cols = np.where(alpha.max(axis=0) > 8)[0]
        if not len(rows) or not len(cols):
            return None, {"error": "alpha empty after keep_parts"}
        content = image.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))
        cw, ch = content.size
        area = cw * ch
        target = HERO_AREA_TARGET * HERO_CANVAS * HERO_CANVAS
        if area > target:
            scale = math.sqrt(target / area)
            content = content.resize((max(1, int(round(cw * scale))),
                                      max(1, int(round(ch * scale)))), Image.LANCZOS)
        cw, ch = content.size
        canvas = Image.new("RGBA", (HERO_CANVAS, HERO_CANVAS), (0, 0, 0, 0))
        canvas.paste(content, ((HERO_CANVAS - cw) // 2, (HERO_CANVAS - ch) // 2))
        final = canvas
        info.update({"content_px": [cw, ch],
                "content_share": [round(cw / HERO_CANVAS, 4), round(ch / HERO_CANVAS, 4)],
                "frame_u": round(HERO_CANVAS * HERO_SCALE, 1),
                "hull_u": [round(cw * HERO_SCALE, 1), round(ch * HERO_SCALE, 1)],
                "hull_x_today": [round(cw * HERO_SCALE / 119.1, 2),
                                 round(ch * HERO_SCALE / 119.1, 2)]})
        if cw < HERO_CONTENT_MIN or ch < HERO_CONTENT_MIN:
            info["floor_miss"] = (f"content {cw}x{ch} < {HERO_CONTENT_MIN} per axis "
                                  "(mockup's 2.2x visible hull)")
    else:
        ## trim_centre would re-run keep_main's 10 % floor on the way out; do the same
        ## trim (alpha bbox + 4 % proportional pad) on the already-filtered sprite.
        alpha = np.asarray(image.getchannel("A"))
        rows = np.where(alpha.max(axis=1) > 8)[0]
        cols = np.where(alpha.max(axis=0) > 8)[0]
        if not len(rows) or not len(cols):
            return None, {"error": "alpha empty after keep_parts"}
        image = image.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))
        pad = max(8, int(round(0.04 * max(image.size))))
        canvas = Image.new("RGBA", (image.size[0] + 2 * pad, image.size[1] + 2 * pad),
                           (0, 0, 0, 0))
        canvas.paste(image, (pad, pad))
        final = canvas
    out = FINAL / f"{name}.png"
    FINAL.mkdir(parents=True, exist_ok=True)
    final.save(out)
    info.update(final_checks(out, cut, spec))
    retention = info["ink_px"] / max(k_ink, 1)
    info["ink_retention"] = round(retention, 4)
    if retention < INK_RETENTION_MIN:
        info["problems"].append(
            f"ink retention {retention:.3f} < {INK_RETENTION_MIN} (subject lost in trim)")
    if spec.get("emissive") and k_hot:
        hot_ret = info["hot_px"] / k_hot
        info["hot_retention"] = round(hot_ret, 3)
        if hot_ret < 0.5:
            info["problems"].append(
                f"ember-lamp retention {hot_ret:.3f} < 0.5 (lamp run lost in trim)")
    return out, info


def final_checks(path: Path, cut: Path, spec: dict) -> dict:
    image = Image.open(path).convert("RGBA")
    alpha = np.asarray(image.getchannel("A"))
    rgb = np.asarray(image.convert("RGB"))
    ink = alpha > 8
    transparent = float((alpha == 0).mean())
    hot_px, hot = hot_share(rgb, ink)
    accent = accent_share(rgb, ink)
    problems: list[str] = []
    if transparent <= TRANSPARENT_MIN:
        problems.append(f"transparent {transparent:.3f} <= {TRANSPARENT_MIN}")
    if accent > ACCENT_MAX:
        problems.append(f"second-accent share {accent:.4f} > {ACCENT_MAX}")
    if spec.get("emissive"):
        if hot_px == 0:
            problems.append("no ember-hot pixels where the brief requires ember lamps")
    elif hot > HOT_NONE_MAX:
        problems.append(f"emissive-rule breach: hot share {hot:.5f} > {HOT_NONE_MAX}")
    return {
        "size": list(image.size),
        "transparent": round(transparent, 4),
        "ink_px": int(ink.sum()),
        "hot_px": hot_px,
        "hot_share": round(hot, 5),
        "accent_share": round(accent, 5),
        "problems": problems,
    }


def build_one(name: str) -> dict:
    """detect -> cut -> auto-key -> QC -> (recraft fallback) -> trim -> final QC."""
    record: dict = {"file": name, "status": "FAIL", "key_route": None}
    rerender = D11 / f"{name}_render_r2.png"
    render = rerender if rerender.exists() else D11 / f"{name}_render.png"
    record["render_file"] = render.name
    record["attempt"] = "pass2" if rerender.exists() else "pass1"
    if not render.exists():
        record["error"] = "no render"
        return record
    cut, detail = detect_and_cut(name, render)
    if cut is None:
        record["error"] = detail
        return record
    record["detect"] = detail
    row_source = None
    chosen = None
    auto = auto_key(cut)
    if auto is not None:
        row = json.loads(_qc_pair(cut, auto))
        if not structural_fail(row):
            chosen, row_source, record["key_route"] = auto, row, "auto (local strip)"
        else:
            record["auto_key_fail"] = " | ".join(_qc_problems(row))
    if chosen is None:
        keyed = recraft_key(cut)
        if keyed is None:
            record["error"] = "auto-key failed and recraft failed"
            return record
        row = json.loads(_qc_pair(cut, keyed))
        if structural_fail(row):
            record["error"] = "recraft keying still fails QC: " + " | ".join(_qc_problems(row))
            return record
        chosen, row_source, record["key_route"] = keyed, row, "recraft (paid fallback)"
    record["keyed_qc"] = {
        "box_delta": row_source["box_delta"],
        "transparent": round(row_source["transparent_share"], 4),
        "hole_px": row_source["hole_px"],
        "hole_share": round(row_source["hole_share_of_spans"], 5),
        "ink_px": row_source["ink_px"],
    }
    final, info = finalize(name, chosen, cut)
    if final is None:
        record["error"] = info.get("error", "finalize failed")
        return record
    record.update(info)
    record["status"] = "FAIL" if info.get("problems") or info.get("floor_miss") else "GREEN"
    record["final"] = str(final)
    if info.get("floor_miss"):
        record.setdefault("problems", []).append(info["floor_miss"])
    return record


def _qc_pair(source: Path, keyed: Path) -> str:
    sys.path.insert(0, str(ROOT / "staging" / "cut"))
    import qc_fx_alpha  # noqa: PLC0415
    row = qc_fx_alpha.measure(source, Path(keyed))
    row["_verdict"] = qc_fx_alpha.verdict(row)
    return json.dumps(row)


def _qc_problems(row: dict) -> list[str]:
    verdict = row.get("_verdict", "PASS")
    return [] if verdict == "PASS" else [verdict]


def results_path() -> Path:
    return D11 / "qc_results.json"


def build(names: list[str]) -> int:
    all_rows = {}
    if results_path().exists():
        all_rows = json.loads(results_path().read_text(encoding="utf-8"))
    bad = 0
    for name in names:
        row = build_one(name)
        all_rows[name] = row
        results_path().write_text(json.dumps(all_rows, indent=1), encoding="utf-8")
        mark = "GREEN" if row["status"] == "GREEN" else "FAIL"
        if mark == "FAIL":
            bad += 1
        log(f"[{name}] {mark} key={row.get('key_route')} "
            f"transparent={row.get('transparent')} hot={row.get('hot_share')} "
            f"accent={row.get('accent_share')} problems={row.get('problems') or row.get('error')}")
    return 0 if not bad else 2


def qc() -> int:
    rows = json.loads(results_path().read_text(encoding="utf-8"))
    bad = 0
    print(f"{'file':26s} {'status':6s} {'size':11s} {'transp':7s} {'hot':8s} "
          f"{'accent':8s} key / problems")
    for name in sorted(rows):
        row = rows[name]
        size = "x".join(str(v) for v in row.get("size", []))
        probs = row.get("problems") or row.get("error") or []
        if row["status"] != "GREEN":
            bad += 1
        print(f"{name:26s} {row['status']:6s} {size:11s} "
              f"{row.get('transparent', 0):<7} {row.get('hot_share', 0):<8} "
              f"{row.get('accent_share', 0):<8} {row.get('key_route')} {'; '.join(probs)}")
    print(f"{len(rows)} files, {len(rows) - bad} green, {bad} fail")
    return 0 if not bad else 2


def review() -> int:
    rows = json.loads(results_path().read_text(encoding="utf-8"))
    names = sorted(rows)
    thumb = 300
    cols = 5
    rows_n = math.ceil(len(names) / cols)
    sheet = Image.new("RGB", (cols * thumb, rows_n * thumb), (10, 14, 20))
    for index, name in enumerate(names):
        path = FINAL / f"{name}.png"
        if not path.exists():
            continue
        img = Image.open(path).convert("RGBA")
        img.thumbnail((thumb - 8, thumb - 8), Image.LANCZOS)
        cell = Image.new("RGBA", (thumb, thumb), (10, 14, 20, 255))
        cell.paste(img, ((thumb - img.size[0]) // 2, (thumb - img.size[1]) // 2), img)
        sheet.paste(cell.convert("RGB"), ((index % cols) * thumb, (index // cols) * thumb))
    out = STAGE / "_review" / "d11_ship.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    log(f"wrote {out} {sheet.size}")
    return 0


def ship() -> int:
    rows = json.loads(results_path().read_text(encoding="utf-8"))
    SHIP.mkdir(parents=True, exist_ok=True)
    shipped, skipped = [], []
    for name in sorted(rows):
        row = rows[name]
        if row["status"] != "GREEN":
            skipped.append(name)
            continue
        src = FINAL / f"{name}.png"
        shutil.copy2(src, SHIP / f"{name}.png")
        shipped.append(name)
    lines = [
        "# Generation log - env D11 (station scene elements)",
        "",
        f"**Wave:** D11 (worker D11-A1). **Generated:** "
        f"{datetime.now().isoformat(timespec='seconds')}.",
        "",
        "Plan of record: `.agents/gen/slices/D11-station-scene/D11-A0_report.md` "
        "(15 runs = 150 credits = $0.75). Model for every run: "
        "`gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1. Style source: "
        "`vajb-orbit/assets/style-block.txt` verbatim prompt preamble "
        "(ENVIRONMENT_SPEC section 8).",
        "",
        "Route per file: render -> `panels.py --detect` -> `panels.py --cut` -> local "
        "auto-key (`--strip-only`; recraft only on auto-key failure) -> trim -> QC "
        "(containment, transparent > 10 %, negative list section 9, one-emissive rule "
        "section 6).",
        "",
        "| File | Job id | Model | Date | Key route | Prompt |",
        "|---|---|---|---|---|---|",
    ]
    for name in sorted(shipped):
        row = rows[name]
        render_file = row.get("render_file", f"{name}_render.png")
        rec_path = D11 / render_file.replace(".png", ".json")
        rec = json.loads(rec_path.read_text(encoding="utf-8")) if rec_path.exists() else {}
        prompt = rec.get("prompt", "").replace("\n", " ").replace("|", "\\|")
        if len(prompt) > 400:
            prompt = prompt[:397] + "..."
        lines.append(f"| `{name}.png` | `{rec.get('task_id', '?')}` | flare | "
                     f"{rec.get('date', '?')[:10]} | {row.get('key_route')} "
                     f"({row.get('attempt')}) | {prompt} |")
    lines += ["", "Full prompts per run are stored beside the renders in "
                  "`staging/phase_g/env/d11/<name>_render.json` (prompt + job id + model + "
                  "date + run folder; a re-prompted file keeps its first attempt as "
                  "`<name>_render.json` and ships from `<name>_render_r2.json`), and each "
                  "run folder keeps its `job.json`.",
              "", "AI-generated art (kie.ai) is **not CC0**; record the generator's usage "
                  "terms before shipping (AGENTS.md)."]
    reprompted = [n for n in sorted(shipped) if rows[n].get("attempt") == "pass2"]
    if reprompted:
        lines += ["", "**Shipped from a re-prompt (one per violating first render):** "
                  + ", ".join(f"`{n}`" for n in reprompted)
                  + " - the first renders carried an orange furnace glow, which breaches "
                    "section 6's one-emissive rule; no other file was re-rendered."]
    if skipped:
        lines += ["", "**Not shipped (QC not green):** " + ", ".join(f"`{n}`" for n in skipped)]
    GEN_LOG.write_text("\n".join(lines) + "\n", encoding="utf-8")
    log(f"shipped {len(shipped)} file(s) to {SHIP}; skipped: {skipped or 'none'}")
    log(f"wrote {GEN_LOG}")
    return 0 if not skipped else 2


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("render", "build", "qc", "ship", "review"))
    parser.add_argument("names", nargs="*")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--extra", default="", help="reinforcement text for a re-prompt")
    parser.add_argument("--tag", default="", help="render attempt tag (e.g. r2)")
    args = parser.parse_args()
    names = args.names or list(RUNS)
    unknown = [n for n in names if n not in RUNS]
    if unknown:
        print(f"unknown run id(s): {unknown}")
        return 1
    if args.command == "render":
        return run_render(names, dry=args.dry_run, extra=args.extra, tag=args.tag)
    if args.command == "build":
        return build(names)
    if args.command == "qc":
        return qc()
    if args.command == "ship":
        return ship()
    return review()


if __name__ == "__main__":
    raise SystemExit(main())
