"""Phase F.1 Stage 2 QC: measured checks for the integrity fix list.

Two checks, both numbers-only (no eyeballing):

`fringe`  - reproduces ASSET_AUDIT section C3: for every pixel in the anti-aliased
            band (0 < alpha < 250) report the band mean/p95 luminance, the share of
            band pixels whose darkest channel is still bright (>= 175), and the
            share that is near-neutral (min/max channel ratio >= 0.88). A keyed
            sprite passes when the band carries subject colour, i.e. band mean
            luminance is in the interior range (<= 80), not the 168-252 range the
            audit measured.

`cuts`    - 16 px read of the two C2/C2b items: ink coverage of the frame, how
            many of the four frame edges the silhouette touches (C2 data_core), and
            the share of ink pixels that is not fully solid (alpha < 250 -> reads
            grey instead of iron black, C2b outline-weight glyphs).

Usage:
  py -3.14 staging/phase_f/qc_f1.py fringe [paths ...]
  py -3.14 staging/phase_f/qc_f1.py cuts
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
ICONS = ASSETS / "icons"

C3_FILES = [
    "ui/ui_insignia_mic.png", "ui/ui_insignia_mmo.png", "ui/ui_insignia_neutral.png",
    "ui/ui_insignia_ven.png", "ships/ship_drone_swarm_back.png",
    "ships/ship_drone_swarm_front.png", "ships/ship_drone_swarm_side.png",
    "ships/ship_drone_swarm_three_quarter.png", "env/env_outpost_mining.png",
    "env/env_outpost_repair.png", "env/env_mine.png", "env/env_planet_moon.png",
    "env/env_debris_field.png",
]

C2B_GLYPHS = ["icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield"]
C2_GLYPH = "icon_cargo_data_core"
PEERS = ["icon_cargo_ore", "icon_hull"]

BRIGHT_MIN = 175
NEUTRAL_RATIO = 0.88
BAND_LO, BAND_HI = 1, 249
SOLID = 250


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def outer_shells(alpha: np.ndarray, shells: int = 2) -> np.ndarray:
    """Partial-alpha pixels on the outer boundary: the visible halo band.

    The audit measured a *narrow outer* band (its scanline crosses three fringe
    pixels before the subject), so the measurement walks inward from the fully
    transparent region instead of averaging every partial-alpha pixel in the file -
    on a coarsely feathered sprite the second reading would average the whole body.
    """
    out = np.zeros(alpha.shape, dtype=bool)
    reach = alpha < 16
    for _ in range(shells):
        grown = reach.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                shifted = np.zeros_like(reach)
                ys = slice(max(0, dy), reach.shape[0] + min(0, dy))
                xs = slice(max(0, dx), reach.shape[1] + min(0, dx))
                ys_src = slice(max(0, -dy), reach.shape[0] + min(0, -dy))
                xs_src = slice(max(0, -dx), reach.shape[1] + min(0, -dx))
                shifted[ys, xs] = reach[ys_src, xs_src]
                grown |= shifted
        shell = grown & ~reach & (alpha > 0)
        out |= shell
        reach = grown
    return out


def fringe(path: Path) -> dict | None:
    im = Image.open(path).convert("RGBA")
    arr = np.asarray(im)
    alpha = arr[..., 3]
    band = outer_shells(alpha)
    if not band.any():
        return None
    rgb = arr[..., :3][band].astype(np.int16)
    lum = luminance(rgb)
    darkest = rgb.min(axis=1)
    brightest = rgb.max(axis=1)
    neutral = darkest / np.maximum(1, brightest)
    interior = arr[..., :3][alpha >= 250]
    # What the eye actually sees: a bright band pixel only reads as a halo when its
    # alpha is high enough to survive compositing. halo_strength is the strongest
    # alpha-weighted white contribution on the outer edge; anything at or below the
    # sprite's own interior luminance (ASSET_AUDIT C3 measured 38-76) cannot be told
    # apart from the subject on a dark playfield.
    contribution = alpha[band].astype(np.float64) / 255.0 * lum
    interior_lum = float(luminance(interior).mean()) if interior.size else float("nan")
    return {
        "file": path.name,
        "band": int(band.sum()),
        "lum_mean": float(lum.mean()),
        "lum_p95": float(np.percentile(lum, 95)),
        "bright_share": float((darkest >= BRIGHT_MIN).mean()),
        "neutral_share": float((neutral >= NEUTRAL_RATIO).mean()),
        "interior_lum": interior_lum,
        "halo_strength": float(contribution.max()),
        "halo_px": int(((alpha[band] >= 64) & (darkest >= BRIGHT_MIN)).sum()),
        "halo_opaque_share": float((alpha[band][(alpha[band] >= 64) & (darkest >= BRIGHT_MIN)]
                                    >= 250).mean()) if int(((alpha[band] >= 64) &
                                                            (darkest >= BRIGHT_MIN)).sum()) else float("nan"),
    }


def run_fringe(args):
    targets = [ASSETS / a for a in args] if args else [ASSETS / f for f in C3_FILES]
    backup = WORKSPACE / "staging" / "phase_d" / "_fringe_backup"
    print(f"{'band':>9} {'lumMean':>8} {'lumP95':>7} {'bright%':>8} {'haloPx':>7} "
          f"{'opaque%':>8} {'interior':>9}  file")
    fails = 0
    for path in targets:
        if not path.exists():
            print(f"{'MISSING':>9}  {path}")
            fails += 1
            continue
        row = fringe(path)
        if row is None:
            print(f"{'no band':>9}  {path.name}")
            continue
        share = row["halo_px"] / max(1, row["band"])
        if row["lum_mean"] <= 80 and share <= 0.01:
            verdict = "PASS"
        elif row["halo_px"] and row["halo_opaque_share"] >= 0.8:
            verdict = "CONTENT"
        else:
            verdict = "KEYING"
        if verdict != "PASS":
            fails += 1
        before = backup / row["file"]
        if before.is_file():
            old = fringe(before)
            if old:
                print(f"      before: band {old['band']}, mean lum {old['lum_mean']:.1f}, "
                      f"bright {100 * old['bright_share']:.1f}%, halo px {old['halo_px']}, "
                      f"halo strength {old['halo_strength']:.1f}")
        print(f"{row['band']:>9} {row['lum_mean']:>8.1f} {row['lum_p95']:>7.1f} "
              f"{100 * row['bright_share']:>7.2f}% {row['halo_px']:>7} "
              f"{100 * row['halo_opaque_share']:>7.0f}% {row['interior_lum']:>9.1f}  "
              f"{row['file']}  {verdict}")
    print(f"\n{len(targets)} files, {fails} not passing the clean-edge bar. PASS = outer band mean "
          f"luminance <= 80 and <= 1% of it bright. CONTENT = the residual bright edge pixels are "
          f">= 80% fully opaque, i.e. subject pixels (frost, ice catch, shards), not a keying band. "
          f"KEYING = a bright semi-transparent band survived the passes.")
    return 0 if fails == 0 else 1


def cut_report(name: str, size: int = 16, detail: bool = False):
    path = ICONS / f"{name}_{size}.png"
    arr = np.asarray(Image.open(path).convert("RGBA"))
    alpha = arr[..., 3]
    ink = alpha > 8
    total = alpha.size
    coverage = ink.sum() / total
    edges = {
        "top": bool(ink[0, :].any()), "bottom": bool(ink[-1, :].any()),
        "left": bool(ink[:, 0].any()), "right": bool(ink[:, -1].any()),
    }
    solid = alpha[ink] >= SOLID if ink.any() else np.array([])
    row = {
        "file": path.name,
        "coverage": coverage,
        "touched": sum(edges.values()),
        "edges": "".join(k[0].upper() for k, v in edges.items() if v) or "-",
        "solid_share": float(solid.mean()) if solid.size else float("nan"),
        "grey_share": float(1 - solid.mean()) if solid.size else float("nan"),
    }
    if detail:
        print(f"   {row['file']:34s} coverage {row['coverage']:.2f}  edges {row['edges']}"
              f"  solid ink {100 * row['solid_share']:5.1f}%  grey {100 * row['grey_share']:5.1f}%")
    return row


def run_cuts(_args):
    print("== C2 - data_core 16 px read (bar: coverage <= 0.90, fewer than 4 edges touched)")
    for name in [C2_GLYPH] + PEERS:
        cut_report(name, 16, detail=True)
    print("\n== C2b - outline-weight glyphs at 16 px (bar: grey share <= 5%)")
    for name in C2B_GLYPHS:
        cut_report(name, 16, detail=True)
    print("\n== C2b - the same glyphs at 48 px for context")
    for name in C2B_GLYPHS:
        cut_report(name, 48, detail=True)
    return 0


def main():
    argv = sys.argv[1:]
    mode = argv[0] if argv else "fringe"
    rest = argv[1:]
    if mode == "fringe":
        return run_fringe(rest)
    if mode == "cuts":
        return run_cuts(rest)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
