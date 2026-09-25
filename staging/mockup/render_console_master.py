#!/usr/bin/env python3
"""render_console_master.py - the ARMORY console master, scripted (wave S18).

Renders `vajb-orbit/assets/ui/ui_armory_console.png` at exactly 2x the D13
landscape console: 1360x516 drawn -> 2720x1032 at `art_scale` 2. The language is
the owner-approved mockup's own (`armory_mockup_v2.py`'s `metal_rect`): brushed
metal, a 3 px drawn bevel (light top/left, dark bottom/right) and four corner
bolts at a 16 px drawn inset with an 8 px drawn radius, all doubled here.

Nothing else is baked: the pane title, captions, bays, cells, ledges, rows and
cards are code-drawn treatments (UI_SPEC section 3.10 Amendment 3). The plate
mounts as a nine-slice over the runtime console rect - the border and bolts sit
inside a 64 master px patch margin, the flat grain stretches.

Deterministic: `random.seed(11)` once, the same call order every run, so a
re-render is byte-identical (md5-verified; no paid calls). Run from the
workspace root:

    python3 staging/mockup/render_console_master.py
"""
import hashlib
import os
import random
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cockpit_mockup import METAL_MID, brushed, bevel, bolt  # noqa: E402

random.seed(11)

OUT = "vajb-orbit/assets/ui/ui_armory_console.png"
W, H = 2720, 1032
BEVEL = 6
BOLT_INSET = 32
BOLT_RADIUS = 16


def render() -> Image.Image:
    img = brushed(W, H).convert("RGBA")
    bevel(img, (0, 0, W - 1, H - 1), w=BEVEL)
    for cx, cy in (
        (BOLT_INSET, BOLT_INSET),
        (W - BOLT_INSET, BOLT_INSET),
        (BOLT_INSET, H - BOLT_INSET),
        (W - BOLT_INSET, H - BOLT_INSET),
    ):
        bolt(img, cx, cy, BOLT_RADIUS)
    return img


def main() -> int:
    img = render()
    img.save(OUT, optimize=True)
    with open(OUT, "rb") as handle:
        digest = hashlib.md5(handle.read()).hexdigest()
    print("wrote %s %dx%d md5=%s" % (OUT, img.width, img.height, digest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
