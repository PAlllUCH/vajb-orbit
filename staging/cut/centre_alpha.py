"""Trim a keyed sprite to its alpha box and centre it on a square canvas, without scipy.

`staging/phase_g/wave_g.py`'s `trim_centre` does this with `scipy.ndimage`, which this host's
interpreter does not have, so the same two steps are done here with numpy only:

1. **Trim** to the alpha box (alpha > 8), so the shipped file has no void margin around it.
2. **Centre** the object on a square canvas - a sprite that is not centred rotates and scales
   off its mount.

Padding is the same 6% the FX frames use, and the canvas side is rounded up to 8 px so the size
is a stable number for the wiring's own `scale_for`.

Usage:
    py -3.14 staging/cut/centre_alpha.py <keyed.png> <out.png> [--pad 0.06]
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROUND = 8
MIN_SIDE = 64


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("dest")
    parser.add_argument("--pad", type=float, default=0.06)
    parser.add_argument("--alpha", type=int, default=8)
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGBA")
    alpha = np.asarray(image.getchannel("A"))
    rows = np.where((alpha > args.alpha).any(axis=1))[0]
    cols = np.where((alpha > args.alpha).any(axis=0))[0]
    if not len(rows) or not len(cols):
        print("no object: every pixel is transparent")
        return 1
    box = [int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1]
    patch = image.crop(tuple(box))
    span = max(patch.width, patch.height)
    side = max(MIN_SIDE, int(np.ceil(span * (1 + 2 * args.pad) / ROUND)) * ROUND)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(patch, ((side - patch.width) // 2, (side - patch.height) // 2))
    dest = Path(args.dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest)
    print(f"{Path(args.source).name} box={box} object={patch.width}x{patch.height} "
          f"-> {dest} {side}x{side}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
