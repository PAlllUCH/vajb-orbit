"""QC an alpha-keyed FX render before it is shipped: box agreement, holes, inverted matte.

The keying route is the one that ate the UI slot plates, so nothing ships on the strength of
"the call returned 200". Four measurements per file, all against the pre-key render:

- **Box agreement.** The alpha box must cover the ink box: a matte that crops the subject
  shows up as a short edge (measured in pixels).
- **Holes.** Transparent pixels *inside* the silhouette on a row span (leftmost to rightmost
  opaque pixel). The v1 matte punched blotches through hull plating; an interior hole share
  above a fraction of a percent means the matte removed artwork, not background.
- **Inverted matte.** If the kept pixels are mostly near-white ink, the model read the
  figure as background (the flat-icon failure on `icon_zoom_plus`).
- **Kept share.** How much of the frame survived. A matte that keeps nearly everything kept
  the background with it.

Usage:
    py -3.14 staging/cut/qc_fx_alpha.py <source.png> <keyed.png> [<source.png> <keyed.png> ...]
    py -3.14 staging/cut/qc_fx_alpha.py --scope staging/cut/_fx_key
"""
from __future__ import annotations

import argparse
import glob
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
## A row-span hole share above this fails: the matte removed artwork.
HOLE_LIMIT = 0.002
## Kept pixels this bright, on average, mean the matte kept white ink and cut the figure.
INVERT_MEAN = 200.0
## An alpha box may sit a few pixels inside the ink box on a soft edge; beyond this it is a crop.
CROP_TOL = 8


def ink_mask(gray: np.ndarray, tol: float = 14.0, block: int = 8, min_ink: int = 12) -> np.ndarray:
    """The render's ink, with film grain filtered out (same rule as `split_fx.py`).

    Without the block filter a handful of 40-grey grain specks near the canvas edge widen the ink
    box, and every keyed frame then looks like it "crops the art" by 50 px an edge - measured on
    `fx_laser_bolt_f3` and `fx_tractor_beam_f2`, both of which are clean cuts.
    """
    ring = 16
    bg = float(np.median(np.concatenate([gray[:ring, :].ravel(), gray[-ring:, :].ravel(),
                                         gray[:, :ring].ravel(), gray[:, -ring:].ravel()])))
    contrast = float(np.percentile(gray, 99.9) - bg)
    mask = np.abs(gray - bg) > max(tol, 0.02 * contrast)
    rows = gray.shape[0] // block
    cols = gray.shape[1] // block
    blocks = mask[: rows * block, : cols * block].reshape(
        rows, block, cols, block).sum(axis=(1, 3)) >= min_ink
    clean = np.zeros_like(mask)
    clean[: rows * block, : cols * block] = np.repeat(np.repeat(blocks, block, axis=0),
                                                      block, axis=1)
    return clean


def box_of(mask: np.ndarray) -> list[int] | None:
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return None
    return [int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1]


def hole_mask(transparent: np.ndarray, block: int = 8) -> np.ndarray:
    """Transparent pixels not connected to the border: a pocket punched inside the object.

    A row span (leftmost to rightmost opaque pixel) is the wrong measure here: every wispy
    effect - smoke, acid, a spark field - is full of legitimate gaps, and counting them
    flagged all four files at 0.4-28% "holes" on the first pass. Background-connected
    transparency is the honest test: only the transparent region sealed inside the
    silhouette counts, and it is found on an 8x block reduction so the cost stays small.
    """
    height, width = transparent.shape
    rows = height // block
    cols = width // block
    sealed = transparent[: rows * block, : cols * block].reshape(
        rows, block, cols, block).all(axis=(1, 3))
    reached = np.zeros_like(sealed)
    stack: list[tuple[int, int]] = []
    for y in range(rows):
        for x in (0, cols - 1):
            if sealed[y, x] and not reached[y, x]:
                reached[y, x] = True
                stack.append((y, x))
    for x in range(cols):
        for y in (0, rows - 1):
            if sealed[y, x] and not reached[y, x]:
                reached[y, x] = True
                stack.append((y, x))
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < rows and 0 <= nx < cols and sealed[ny, nx] and not reached[ny, nx]:
                reached[ny, nx] = True
                stack.append((ny, nx))
    holes = sealed & ~reached
    full = np.zeros_like(transparent)
    full[: rows * block, : cols * block] = np.repeat(np.repeat(holes, block, axis=0),
                                                     block, axis=1)
    return full & transparent


def measure(source: Path, keyed: Path) -> dict:
    original = Image.open(source).convert("RGB")
    image = Image.open(keyed).convert("RGBA")
    if image.size != original.size:
        image = image.resize(original.size, Image.LANCZOS)
    alpha = np.asarray(image.getchannel("A"))
    rgb = np.asarray(image.convert("RGB")).astype(np.float32)
    ink = ink_mask(np.asarray(original.convert("L")).astype(np.float32))
    opaque = alpha > 8
    ink_box = box_of(ink)
    alpha_box = box_of(opaque)
    delta = None
    if ink_box and alpha_box:
        delta = [alpha_box[i] - ink_box[i] for i in range(4)]
    holes = int(hole_mask(~opaque).sum())
    inside = int(opaque.sum())
    holes_share = (holes / inside) if inside else 0.0
    kept = rgb[opaque]
    return {
        "file": keyed.name,
        "size": list(original.size),
        "ink_box": ink_box,
        "alpha_box": alpha_box,
        "box_delta": delta,
        "ink_px": int(ink.sum()),
        "opaque_px": int(opaque.sum()),
        "transparent_share": float((alpha == 0).mean()),
        "hole_px": holes,
        "hole_share_of_spans": holes_share,
        "kept_mean_rgb": [round(float(v), 1) for v in kept.mean(axis=0)] if len(kept) else None,
    }


def verdict(row: dict) -> str:
    """Hard checks only; the hole count is reported, not judged here.

    Enclosed transparency is a fact of graded art, not automatically a defect: a mixing-blended
    smoke plume is translucent by nature, and the vignette's clear centre *is* an enclosed
    transparent region (FX_SPEC 1.8 asks for it). Whether a given pocket is a bite out of the
    artwork or the effect's own softness is what `verify_fx_alpha.py` asks the vision model.
    """
    problems: list[str] = []
    delta = row["box_delta"]
    if delta is None:
        problems.append("NO ALPHA or NO INK")
    else:
        if delta[0] > CROP_TOL or delta[1] > CROP_TOL or delta[2] < -CROP_TOL \
                or delta[3] < -CROP_TOL:
            problems.append(f"MATTE CROPS THE ART delta={delta}")
        if row["transparent_share"] < 0.05:
            problems.append("MATTE KEPT THE BACKGROUND")
        if row["kept_mean_rgb"] and min(row["kept_mean_rgb"]) > INVERT_MEAN:
            problems.append(f"INVERTED MATTE kept_mean={row['kept_mean_rgb']}")
    if row["hole_share_of_spans"] > HOLE_LIMIT:
        problems.append(f"REPORT {row['hole_share_of_spans'] * 100:.2f}% enclosed transparency")
    structural = [p for p in problems if not p.startswith("REPORT")]
    return "PASS" if not structural else "; ".join(problems)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", default="")
    parser.add_argument("pairs", nargs="*")
    args = parser.parse_args()

    pairs: list[tuple[Path, Path]] = []
    if args.scope:
        for keyed in sorted(Path(args.scope).rglob("*-keyed.png")):
            source = keyed.with_name(keyed.name.replace("-keyed.png", ".png"))
            if source.exists():
                pairs.append((source, keyed))
    for index in range(0, len(args.pairs) - 1, 2):
        pairs.append((Path(args.pairs[index]), Path(args.pairs[index + 1])))
    if not pairs:
        print("nothing to check: pass --scope <dir> or source/keyed pairs")
        return 1
    failures = 0
    for source, keyed in pairs:
        row = measure(source, keyed)
        result = verdict(row)
        if result != "PASS":
            failures += 1
        print(f"{row['file']:44s} {result}")
        print(f"    size={row['size']} alpha={row['transparent_share'] * 100:.1f}% transparent"
              f" opaque={row['opaque_px']}px ink={row['ink_px']}px"
              f" box_delta={row['box_delta']}"
              f" holes={row['hole_px']}px ({row['hole_share_of_spans'] * 100:.3f}% of the object)"
              f" kept_mean={row['kept_mean_rgb']}")
    print(f"qc_fx_alpha: {len(pairs) - failures} pass, {failures} fail")
    return 0 if not failures else 2


if __name__ == "__main__":
    raise SystemExit(main())
