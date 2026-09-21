"""Key an emissive FX render by luminance, when the paid matte will not.

`recraft/remove-background` treats the strongest object on the sheet as its subject, which is
right for a ship or a prop and wrong for an effect whose whole frame is a gradient:

- **`fx_hull_critical_vignette`** is ember at the screen edges fading to a void-dark centre.
  The matte kept 99.7% of the frame (measured: 4 179 224 opaque px of 4 194 304), the model
  classified "background_clear": false and found a magenta gap punched inside the ring, and
  FX_SPEC section 1.8 requires the opposite - "background discarded on import; centre must be
  fully transparent".

The effect's own brightness *is* its opacity for art rendered on Void Black: a pixel at the
void level is background, a bright pixel is the effect, and everything between is the soft
edge. That is the key this tool writes, RGB untouched so additive blending still reads the
same and MIX blending finally has something to mix.

Usage:
    py -3.14 staging/cut/key_luminance.py --check <src.png> [--out dir]
    py -3.14 staging/cut/key_luminance.py --check --scope staging/cut/_fx_key
"""
from __future__ import annotations

import argparse
import glob
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
## Fraction of the effect's own contrast that is treated as pure background, with its own
## absolute floor. Kept low on purpose: a brighter floor drops the faintest halo pixels to
## alpha 0, which `qc_fx_alpha.py` then reports as "matte crops the art" (measured on
## `fx_laser_bolt_f3` at 63 px an edge and `fx_tractor_beam_f2` at 56 px at 0.04).
FLOOR_SHARE = 0.02
## Luminance percentile that becomes fully opaque.
CEIL_PCT = 99.0
## Alpha below this is grain haze and is dropped to zero. Without it every frame keeps a faint
## dark wash across its void (film grain at 2-10% alpha), which reads as a grey rectangle on
## magenta - measured on `fx_mining_beam_f4` and `fx_engine_trail_f3`. A real effect's soft tail
## sits well above it, and the dim effects that do not are matte-keyed instead.
CUTOFF = 0.12
## Below this spread between the void and the effect's own ceiling there is no gradient to key.
MIN_CONTRAST = 30.0


def background(gray: np.ndarray, ring: int = 16) -> float:
    edges = np.concatenate([gray[:ring, :].ravel(), gray[-ring:, :].ravel(),
                            gray[:, :ring].ravel(), gray[:, -ring:].ravel()])
    return float(np.median(edges))


def key(source: Path, gamma: float = 1.0) -> tuple[Image.Image, dict]:
    image = Image.open(source).convert("RGB")
    rgb = np.asarray(image).astype(np.float32)
    gray = rgb.mean(axis=2)
    bg = background(gray)
    ceiling = float(np.percentile(gray, CEIL_PCT))
    ## The floor has to clear the frame's own film grain, or every grain speck keeps a few
    ## percent of alpha and the frame ships with a faint dark haze across its void (measured on
    ## `fx_mining_beam_f4` and the arc frames: a visible rectangle on magenta). The grain level is
    ## read from a border ring, and the floor is capped at a third of the effect's own contrast so
    ## a genuinely dim effect is not erased by specks brighter than it (the dust streak is dimmer
    ## than its grain, and it is matte-keyed for exactly that reason).
    ring = np.concatenate([gray[:24, :].ravel(), gray[-24:, :].ravel(),
                           gray[:, :24].ravel(), gray[:, -24:].ravel()])
    grain = float(np.percentile(ring, 99.9))
    floor = bg + max(3.0, FLOOR_SHARE * max(ceiling - bg, 1.0))
    floor = min(max(floor, grain), bg + 0.35 * max(ceiling - bg, 1.0))
    span = max(ceiling - floor, 1.0)
    if ceiling - bg < MIN_CONTRAST:
        ## A frame whose own content is at the void's own level (the mining sheet's nearly empty
        ## fourth cell: p99 = 12 against a 10 void) has no gradient to key - dividing by a 1.3
        ## spread turned every void pixel into 20% alpha, a grey box on magenta. A binary
        ## threshold at the grain level is the honest key there: the sparks are 200+.
        alpha = (gray > max(grain + 4.0, bg + 20.0)).astype(np.float32)
    else:
        alpha = np.clip((gray - floor) / span, 0.0, 1.0)
        if gamma != 1.0:
            alpha = np.power(alpha, gamma)
    alpha[alpha < CUTOFF] = 0.0
    out = np.dstack([rgb, np.round(alpha * 255.0)]).astype(np.uint8)
    keyed = Image.fromarray(out, "RGBA")
    centre = slice(gray.shape[0] * 45 // 100, gray.shape[0] * 55 // 100), \
        slice(gray.shape[1] * 45 // 100, gray.shape[1] * 55 // 100)
    report = {
        "file": source.name,
        "bg": round(bg, 1),
        "ceiling": round(ceiling, 1),
        "floor": round(floor, 1),
        "grain": round(grain, 1),
        "gamma": gamma,
        "transparent_share": round(float((alpha <= 0).mean()), 4),
        "opaque_share": round(float((alpha >= 1).mean()), 4),
        "centre_max_alpha": int(np.round(alpha[centre].max() * 255.0)),
        "mean_rgb": [round(float(v), 1) for v in rgb.reshape(-1, 3).mean(axis=0)],
    }
    return keyed, report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--scope", action="append", default=[],
                        help="a directory of renders; repeat for several")
    parser.add_argument("--exclude", default="",
                        help="comma-separated folder names to skip (the matte's own effects)")
    parser.add_argument("--out", default="")
    parser.add_argument("--gamma", type=float, default=1.0)
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()

    sources = [Path(p) for p in args.paths]
    skip = {name.strip() for name in args.exclude.split(",") if name.strip()}
    for scope in args.scope:
        for p in sorted(Path(scope).rglob("*.png")):
            if p.stem.endswith("-keyed") or p.parent.name in skip:
                continue
            sources.append(p)
    if not sources:
        print("nothing to key: pass paths or --scope <dir>")
        return 1
    for source in sources:
        keyed, report = key(source, args.gamma)
        if args.out:
            target = Path(args.out) / f"{source.stem}-keyed.png"
        else:
            target = source.with_name(f"{source.stem}-keyed.png")
        keyed.save(target)
        print(f"{source.name:34s} -> {target}")
        print("    " + "  ".join(f"{k}={v}" for k, v in report.items() if k != "file"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
