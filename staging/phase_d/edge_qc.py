"""Edge QC: find white/bright fringes on keyed sprites.

Reports, per PNG: opaque pixel count, near-white opaque pixels (min RGB >= 190),
and near-white pixels sitting on the matte boundary (adjacent to alpha < 16),
which is the 'white border' artifact from keying.

Run: py -3.14 staging/phase_d/edge_qc.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"


def scan(path: Path) -> tuple[int, int, int] | None:
    im = Image.open(path)
    if im.mode != "RGBA":
        return None
    w, h = im.size
    px = im.load()
    opaque = 0
    white = 0
    edge_white = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 200:
                continue
            opaque += 1
            is_white = r >= 190 and g >= 190 and b >= 190
            if not is_white:
                continue
            white += 1
            boundary = False
            for ny in range(max(0, y - 1), min(h, y + 2)):
                for nx in range(max(0, x - 1), min(w, x + 2)):
                    if px[nx, ny][3] < 16:
                        boundary = True
                        break
                if boundary:
                    break
            if boundary:
                edge_white += 1
    return opaque, white, edge_white


def main() -> None:
    families = sys.argv[1:] or ["ships", "icons", "env", "ui"]
    rows = []
    for family in families:
        for path in sorted((ASSETS / family).glob("*.png")):
            result = scan(path)
            if result is None:
                continue
            opaque, white, edge_white = result
            if edge_white > 0 or (white > opaque * 0.02 and white > 50):
                rows.append((edge_white, white, opaque, family, path.name))
    rows.sort(reverse=True)
    print(f"{'edgeW':>6} {'white':>7} {'opaque':>8}  file")
    for edge_white, white, opaque, family, name in rows:
        print(f"{edge_white:>6} {white:>7} {opaque:>8}  {family}/{name}")


if __name__ == "__main__":
    main()
