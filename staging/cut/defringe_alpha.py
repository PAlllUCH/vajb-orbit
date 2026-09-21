"""Defringe a keyed sprite: give the semi-transparent band its own colour.

A matte leaves a band of pixels with low alpha *and* near-black RGB - the background it subtracted
from, and on some renders the faint dark card the generator drew behind the effect. Alpha keeps
the band nearly invisible under additive blending, but a MIX-blended draw shows it as a dark halo
around the object, which is exactly what the vision check flagged on the cycle frames of
`fx_cargo_pulse`, `fx_lock_channel`, `fx_shield_ripple`, `fx_dust_streak` and `fx_smoke_plume`
("black halo around pixels", "black stepped box around arc", "grey fringe and grey speckle").

The fix is the library's own defringe rule (`staging/phase_d/defringe_edges.py`,
`staging/phase_f/rekey_halo.py`): the band takes the colour of the nearest opaque pixel, so the
object's edge fades out in its own colour instead of into black. Alpha and the opaque core are
never touched, so additive blending is unchanged.

Free, local, idempotent.

Usage:
    py -3.14 staging/cut/defringe_alpha.py --scope staging/cut/_fx_cycles
    py -3.14 staging/cut/defringe_alpha.py <keyed.png> [<keyed.png> ...]
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

## Alpha at or above this is the object's core and is never rewritten.
SOLID = 0.85
## Propagation passes: enough to cross a wide soft band (each pass grows the known colour 1 px).
PASSES = 24


def defringe(image: Image.Image) -> tuple[Image.Image, int]:
    rgba = np.asarray(image.convert("RGBA")).astype(np.float32)
    rgb = rgba[..., :3].copy()
    alpha = rgba[..., 3:4] / 255.0
    solid = alpha[..., 0] >= SOLID
    band = (alpha[..., 0] > 0) & ~solid
    changed = int(band.sum())
    if not changed:
        return image, 0
    filled = solid.copy()
    known = rgb.copy()
    for _ in range(PASSES):
        if not (band & ~filled).any():
            break
        spread = np.zeros_like(known)
        seen = np.zeros_like(filled)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            shifted = np.roll(np.roll(known, dy, 0), dx, 1)
            mask = np.roll(np.roll(filled, dy, 0), dx, 1)
            take = mask & ~seen
            spread[take] = shifted[take]
            seen |= take
        adopt = seen & band & ~filled
        known[adopt] = spread[adopt]
        filled |= adopt
    rgb[band] = np.where(filled[band][..., None], known[band], rgb[band])
    out = np.dstack([np.clip(rgb, 0, 255), rgba[..., 3]]).astype(np.uint8)
    return Image.fromarray(out, "RGBA"), changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", action="append", default=[])
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()

    targets = [Path(p) for p in args.paths]
    for scope in args.scope:
        targets += sorted(Path(scope).rglob("*-keyed.png"))
    if not targets:
        print("nothing to defringe: pass paths or --scope <dir>")
        return 1
    total = 0
    for path in targets:
        image = Image.open(path)
        fixed, changed = defringe(image)
        if changed:
            fixed.save(path)
        total += changed
        print(f"  {path.name:44s} band px={changed}")
    print(f"defringe_alpha: {len(targets)} file(s), {total} band pixel(s) recoloured")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
