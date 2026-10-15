#!/usr/bin/env python3
"""Lift the regenerated pack icon masters to the ICONS_SPEC §10.2 gates.

The 2026-10-15 T-203 round: the chosen renders read slightly under the pinned
luminance gates (laser avg 88 / rocket avg 85 against the ≥90 gate), so this
script applies a deterministic linear gain on RGB (alpha untouched) computed
from the measured average, then downscales the 1024 render to the 512 master
(downscale-from-master only, ICONS_SPEC §9.3). Parameters are recorded in the
weapon generation_log's regeneration appendix.

Usage:
    python3 staging/cut/lift_pack_icons.py \
        --laser <render.png> --rocket <render.png> \
        --out-laser <master.png> --out-rocket <master.png>
"""

import argparse
import statistics
from pathlib import Path

from PIL import Image

TARGET_AVG = 90.0
MASTER_SIZE = 512
LUM_WEIGHTS = (0.2126, 0.7152, 0.0722)


def measure(im: Image.Image) -> dict:
    px = [q for q in list(im.convert("RGBA").getdata()) if q[3] > 40]
    lum = [sum(w * c for w, c in zip(LUM_WEIGHTS, q[:3])) for q in px]
    return {
        "opaque": len(px),
        "avg": statistics.mean(lum),
        "p90": sorted(lum)[int(len(lum) * 0.9)],
    }


def lift(src: Path, dst: Path) -> dict:
    im = Image.open(src).convert("RGBA")
    before = measure(im)
    if before["avg"] >= TARGET_AVG:
        gain = 1.0
    else:
        gain = TARGET_AVG / before["avg"]
    if gain != 1.0:
        lut = [min(255, round(i * gain)) for i in range(256)] * 3 + list(range(256))
        im = im.point(lut)
    master = im.resize((MASTER_SIZE, MASTER_SIZE), Image.LANCZOS)
    master.save(dst)
    after = measure(Image.open(dst))
    return {"gain": gain, "before": before, "after": after}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--laser", required=True)
    ap.add_argument("--rocket", required=True)
    ap.add_argument("--out-laser", required=True)
    ap.add_argument("--out-rocket", required=True)
    args = ap.parse_args()
    for src, dst, tag in [
        (args.laser, args.out_laser, "laser"),
        (args.rocket, args.out_rocket, "rocket"),
    ]:
        r = lift(Path(src), Path(dst))
        print(
            "%s: gain=%.3f avg %.0f->%.0f p90 %.0f->%.0f opaque %d->%d"
            % (
                tag,
                r["gain"],
                r["before"]["avg"],
                r["after"]["avg"],
                r["before"]["p90"],
                r["after"]["p90"],
                r["before"]["opaque"],
                r["after"]["opaque"],
            )
        )


if __name__ == "__main__":
    main()
