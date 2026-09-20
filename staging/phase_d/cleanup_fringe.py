"""Peel white keying fringes off shipped sprites.

The Phase B objects were keyed from a light source background; the anti-aliased
boundary retained near-white blend pixels (a 1-3 px trace that reads as a white
border on dark playfields). This pass walks the *outer* matte boundary (the
transparency region connected to the image border, so interior holes and pale
surface pixels are untouched) and clears near-white pixels:

  repeat up to MAX_PEEL shells: opaque near-white pixels adjacent to outer
  transparency -> alpha 0 (peels the trace until it meets dark hull)

Only files with at least MIN_EDGE_WHITES such pixels are touched. Files are
backed up to staging/phase_d/_fringe_backup before the first change.
Dry run by default; pass --apply to write.

Run: py -3.14 staging/phase_d/cleanup_fringe.py [--apply] [family ...]
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
BACKUP = Path(__file__).resolve().parent / "_fringe_backup"

NEAR_WHITE = 175
MAX_PEEL = 6
MIN_EDGE_WHITES = 20
EXCLUDE_PREFIX = ("ui_button_plate",)
EXCLUDE_EXACT = {"logo_vajb_orbit.png"}


def dilate(mask: np.ndarray) -> np.ndarray:
    out = mask.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            shifted = np.zeros_like(mask)
            ys = slice(max(0, dy), mask.shape[0] + min(0, dy))
            xs = slice(max(0, dx), mask.shape[1] + min(0, dx))
            ys_src = slice(max(0, -dy), mask.shape[0] + min(0, -dy))
            xs_src = slice(max(0, -dx), mask.shape[1] + min(0, -dx))
            shifted[ys, xs] = mask[ys_src, xs_src]
            out |= shifted
    return out


def outer_transparency(alpha: np.ndarray) -> np.ndarray:
    """Transparency connected to the image border (interior holes stay False)."""
    trans = alpha < 16
    labelled, _ = ndi.label(trans, structure=np.ones((3, 3), dtype=int))
    border_labels = set(labelled[0, :]) | set(labelled[-1, :]) | set(labelled[:, 0]) | set(labelled[:, -1])
    border_labels.discard(0)
    if not border_labels:
        return np.zeros_like(trans)
    return np.isin(labelled, list(border_labels))


def analyse(alpha: np.ndarray, near: np.ndarray) -> int:
    outside = outer_transparency(alpha)
    return int((dilate(outside) & (alpha >= 200) & near).sum())


def cleanup(path: Path, apply: bool) -> tuple[int, int] | None:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    rgb_min = arr[..., :3].astype(np.int16).min(axis=2)
    near = rgb_min >= NEAR_WHITE
    edge_white = analyse(arr[..., 3], near)
    if edge_white < MIN_EDGE_WHITES:
        return None

    alpha = arr[..., 3]
    outside = outer_transparency(alpha)
    removed = 0
    for _ in range(MAX_PEEL):
        shell = dilate(outside) & (alpha >= 200) & near
        n = int(shell.sum())
        if n == 0:
            break
        alpha[shell] = 0
        outside |= shell
        removed += n

    if apply:
        BACKUP.mkdir(parents=True, exist_ok=True)
        dest = BACKUP / path.name
        if not dest.exists():
            shutil.copy2(path, dest)
        Image.fromarray(arr, "RGBA").save(path)
    return edge_white, removed


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--apply"]
    apply = "--apply" in sys.argv
    families = args or ["ships", "icons", "env", "ui"]
    total = 0
    print(f"{'edgeW':>6} {'peeled':>7}  file")
    for family in families:
        for path in sorted((ASSETS / family).glob("*.png")):
            if path.name in EXCLUDE_EXACT or path.name.startswith(EXCLUDE_PREFIX):
                continue
            result = cleanup(path, apply)
            if result is None:
                continue
            edge_white, removed = result
            print(f"{edge_white:>6} {removed:>7}  {family}/{path.name}")
            total += 1
    print(f"{'APPLIED' if apply else 'DRY RUN'}: {total} files")


if __name__ == "__main__":
    main()
