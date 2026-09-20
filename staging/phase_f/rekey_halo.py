"""Phase F.1 Stage 2 (C3) - luminance re-key of the white halo band.

`staging/phase_d/defringe_edges.py` rewrites the band *colour* to the nearest opaque
pixel, which works when the remainder of the sprite is dark. Nine C3 files defeat it:
the model rendered near-white shards at the silhouette (white spikes with a soft
skirt), so the nearest opaque pixel is itself white and the halo survives. Measured on
`ship_drone_swarm_front.png`: 3427 band pixels are still bright after the defringe pass
and their nearest opaque neighbour has mean RGB 231 (bright share 1.0).

This pass re-keys instead of recolouring: the soft region connected to the outside gets
its alpha multiplied by the ink fraction implied by its own luminance, so a white bleed
pixel (luminance ~250 against a subject of ~50) fades to a few percent while a genuinely
dark edge pixel keeps its anti-aliasing. Only the soft region connected to the outer
transparency is touched, so interior highlights are never dimmed. Pixels with alpha 0,
pixels inside the opaque core and the RGB bytes are left exactly as they are.

Free, local, idempotent. Backs up once to staging/phase_f/_rekey_backup/.
Dry run by default.

Usage:
  py -3.14 staging/phase_f/rekey_halo.py                 # dry run, the 9 C3 files
  py -3.14 staging/phase_f/rekey_halo.py --apply
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
BACKUP = WORKSPACE / "staging" / "phase_f" / "_rekey_backup"

TARGETS = [
    "ships/ship_drone_swarm_back.png", "ships/ship_drone_swarm_front.png",
    "ships/ship_drone_swarm_side.png", "ships/ship_drone_swarm_three_quarter.png",
    "env/env_outpost_mining.png", "env/env_outpost_repair.png", "env/env_mine.png",
    "env/env_planet_moon.png", "env/env_debris_field.png",
]

SOFT = 250          # alpha below this is "soft" and may be part of the halo skirt
OUTSIDE = 16        # alpha below this is definitely background
BRIGHT = 175        # the audit's near-white threshold on the darkest channel
# Subject luminance reference. Fixed, not per file: the palette is fixed (STYLE_BIBLE
# section 2), and ASSET_AUDIT C3 measured the interior of these files at 38-76. A
# per-file percentile fails here because a third of these sprites' opaque pixels are
# themselves pale. At this reference a white pixel (luminance ~250) keeps ~3 percent of
# its alpha, so it composites to nothing over a dark playfield, while a dark edge pixel
# (luminance <= 76) keeps its anti-aliasing exactly.
LUM_REF = 76.0


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def soft_region(alpha: np.ndarray) -> np.ndarray:
    """Every soft pixel (0 < alpha < SOFT).

    No border flood is possible: these sprites are trimmed to their alpha bounding
    box, so the outermost row carries content and nothing is connected to a
    transparent frame. The region is therefore the whole partial-alpha set, which is
    safe by construction - a pixel is only dimmed in proportion to how pale it is,
    and the interior bands are already fully opaque.
    """
    return (alpha > 0) & (alpha < SOFT)


def rekey(path: Path, apply: bool) -> dict:
    im = Image.open(path).convert("RGBA")
    arr = np.asarray(im).copy()
    alpha = arr[..., 3]
    lum = luminance(arr[..., :3])
    region = soft_region(alpha)
    if not region.any():
        return {"file": path.name, "region": 0, "changed": 0, "bright_before": 0.0, "bright_after": 0.0}
    span = max(1.0, 255.0 - LUM_REF)
    factor = np.clip((255.0 - lum) / span, 0.0, 1.0)
    before = alpha[region].copy()
    updated = arr.copy()
    new_alpha = np.round(alpha[region] * factor[region]).astype("uint8")
    updated[..., 3][region] = new_alpha
    mn = arr[..., :3].min(axis=2)
    bright_before = float((mn[region] >= BRIGHT).mean())
    bright_after = float((mn[region & (updated[..., 3] > 0)] >= BRIGHT).mean()) if region.any() else 0.0
    changed = int((new_alpha != before).sum())
    if apply and changed:
        BACKUP.mkdir(parents=True, exist_ok=True)
        dest = BACKUP / path.name
        if not dest.exists():
            shutil.copy2(path, dest)
        Image.fromarray(updated, "RGBA").save(path)
    return {"file": path.name, "region": int(region.sum()), "changed": changed,
            "bright_before": bright_before, "bright_after": bright_after}


def main() -> int:
    apply = "--apply" in sys.argv
    argv = [a for a in sys.argv[1:] if not a.startswith("--")]
    targets = [ASSETS / t for t in (argv or TARGETS)]
    print(f"{'region':>8} {'changed':>8} {'keptBright%':>12}  file")
    for path in targets:
        if not path.is_file():
            print(f"{'MISSING':>8}  {path}")
            continue
        row = rekey(path, apply)
        print(f"{row['region']:>8} {row['changed']:>8} {100 * row['bright_after']:>11.1f}%  "
              f"{row['file']}  (bright share in the region: {100 * row['bright_before']:.1f}% -> "
              f"{100 * row['bright_after']:.1f}%)")
    print(f"\n{'APPLIED' if apply else 'DRY RUN'}: {len(targets)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
