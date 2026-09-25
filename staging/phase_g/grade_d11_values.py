#!/usr/bin/env python3
"""D11-F1 MED-1: value-grade the 15 shipped env_station_* files so the family
reads one value step darker than ships (ENVIRONMENT_SPEC §1.1/§1.3).

Local grade, no re-render: RGB only, alpha byte-identical, ember-hot pixels
(r>170 & r-b>80, wave_d11.hot_share) left untouched so §6's one-emissive row,
the QC hot/accent/transparency numbers and every layout pin stay exactly as
approved. Originals are copied to staging/phase_g/_d11_pregrade/ first
(reversal: copy them back).

Usage:
  uv run --with numpy --with scipy --with pillow python \
      staging/phase_g/grade_d11_values.py [--apply]
  --apply off -> measure + dry-run plan only.
"""
import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
POI = ROOT / "vajb-orbit" / "assets" / "env" / "poi"
BACKUP = ROOT / "staging" / "phase_g" / "_d11_pregrade"

TARGET_MEAN = 0.160  # below the old station's 0.166 and the vanguard hull's 0.175 (R1's re-measure)

NAMES = [
    "env_station_hero", "env_station_arm_a", "env_station_arm_b",
    "env_station_mast_a", "env_station_mast_b",
    "env_station_gantry_a", "env_station_gantry_b",
    "env_station_windows_a", "env_station_windows_b",
    "env_station_plate_a", "env_station_plate_b",
    "env_station_lamp_a", "env_station_lamp_b",
    "env_station_shuttle_a", "env_station_shuttle_b",
]

ANCHORS = {
    "OLD env_station.png": ROOT / "vajb-orbit" / "assets" / "env" / "poi" / "env_station.png",
    "SHIP ship_vanguard_side": ROOT / "vajb-orbit" / "assets" / "ships" / "ship_vanguard_side.png",
}


def load(path: Path):
    arr = np.asarray(Image.open(path).convert("RGBA"))
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3]
    return arr, rgb, alpha


def measure(rgb: np.ndarray, alpha: np.ndarray) -> dict:
    opaque = alpha > 0
    ink = alpha > 8
    val = rgb.max(axis=2) / 255.0
    v = val[opaque]
    r = rgb[..., 0]
    b = rgb[..., 2]
    hot = ((r > 170) & ((r - b) > 80) & ink)
    return {
        "mean": float(v.mean()),
        "median": float(np.median(v)),
        "hot_px": int(hot.sum()),
        "transparent": float((alpha == 0).mean()),
        "ink_px": int(ink.sum()),
        "_hot": hot,
        "_opaque": opaque,
    }


def grade(rgb: np.ndarray, alpha: np.ndarray, target: float):
    opaque = alpha > 0
    r = rgb[..., 0]
    b = rgb[..., 2]
    hot = ((r > 170) & ((r - b) > 80) & (alpha > 8)) & opaque
    val = rgb.max(axis=2) / 255.0
    n = int(opaque.sum())
    hot_sum = float(val[hot].sum())
    nohot_sum = float(val[opaque & ~hot].sum())
    n_nohot = int((opaque & ~hot).sum())
    k = (target * n - hot_sum) / max(nohot_sum, 1e-6)
    k = float(np.clip(k, 0.0, 1.0))
    out = rgb.copy()
    sel = ~hot
    out[sel] = np.clip(np.round(out[sel] * k), 0, 255)
    return out, k


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def load_wave_d11():
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "wave_d11", Path(__file__).resolve().parent / "wave_d11.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write the graded files")
    ap.add_argument("--update-rows", action="store_true",
                    help="refresh stored qc_results.json rows from fresh final_checks")
    args = ap.parse_args()

    w11 = load_wave_d11()
    stored = json.loads(w11.results_path().read_text(encoding="utf-8"))

    print(f"{'file':26} {'mean before':>11} {'median':>7} -> {'mean after':>10} {'median':>7} "
          f"{'k':>6} {'hot':>7} {'transp':>7} {'accent':>7}")
    plan = {}
    failures = []
    fresh_rows = []
    for name in NAMES:
        path = POI / f"{name}.png"
        arr, rgb, alpha = load(path)
        before = measure(rgb, alpha)
        graded, k = grade(rgb, alpha, TARGET_MEAN)
        after = measure(graded, alpha)
        plan[name] = {"k": k, "before": before, "after": after}
        if after["hot_px"] != before["hot_px"]:
            failures.append(f"{name}: hot_px moved {before['hot_px']} -> {after['hot_px']}")
        row = stored.get(name, {})
        info = w11.final_checks(path, None, w11.RUNS[name])
        for key in ("transparent", "hot_share", "ink_px", "hot_px"):
            if key in row and row[key] != info.get(key):
                failures.append(f"{name}: stored qc row {key}={row[key]} != fresh {info.get(key)}")
        if "accent_share" in row and info["accent_share"] > row["accent_share"]:
            failures.append(
                f"{name}: stored qc row accent_share rose {row['accent_share']} -> "
                f"{info['accent_share']}")
        fresh_rows.append((name, info))
        if info["problems"]:
            failures.append(f"{name}: fresh final_checks problems {info['problems']}")
        print(f"{name:26} {before['mean']:11.4f} {before['median']:7.4f} -> "
              f"{after['mean']:10.4f} {after['median']:7.4f} {k:6.3f} "
              f"{after['hot_px']:7d} {info['transparent']:7.4f} {info['accent_share']:7.5f}")

    print("\nanchors (read-only):")
    for label, path in ANCHORS.items():
        _, rgb, alpha = load(path)
        m = measure(rgb, alpha)
        print(f"  {label:28} mean={m['mean']:.4f} median={m['median']:.4f}")

    if failures:
        print("\nFAILURES:")
        for f in failures:
            print(f"  {f}")
        return 2

    if args.update_rows:
        changed = []
        for name, info in fresh_rows:
            row = stored.get(name, {})
            for key in ("transparent", "hot_share", "accent_share", "ink_px", "hot_px"):
                if key in row and row[key] != info.get(key):
                    changed.append(f"{name}.{key}: {row[key]} -> {info.get(key)}")
                    row[key] = info.get(key)
            if info.get("problems"):
                row["problems"] = info["problems"]
        w11.results_path().write_text(json.dumps(stored, indent=1), encoding="utf-8")
        print("\nupdated qc_results.json rows:")
        for c in changed:
            print(f"  {c}")
        if not changed:
            print("  (no drift)")
        return 0

    if not args.apply:
        print("\ndry run (no --apply): plan above is green; re-run with --apply to write")
        return 0

    BACKUP.mkdir(parents=True, exist_ok=True)
    manifest_path = BACKUP / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    for name in NAMES:
        src = POI / f"{name}.png"
        dst = BACKUP / f"{name}.png"
        if name not in manifest:
            shutil.copy2(src, dst)
            manifest[name] = {"md5": md5(src), "mean": plan[name]["before"]["mean"],
                              "median": plan[name]["before"]["median"]}
    manifest_path.write_text(json.dumps(manifest, indent=1), encoding="utf-8")

    for name in NAMES:
        path = POI / f"{name}.png"
        _, rgb, alpha = load(path)
        if md5(path) != manifest[name]["md5"]:
            print(f"  {name}: live file md5 != backup md5, skipping (backup is the reversal)")
            continue
        graded, _ = grade(rgb, alpha, TARGET_MEAN)
        out = np.concatenate([graded.astype(np.uint8), alpha[..., None]], axis=2)
        Image.fromarray(out, "RGBA").save(path)

    print(f"\ngraded {len(NAMES)} files; originals in {BACKUP}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
