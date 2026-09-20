"""Key a flat background by deleting the flat fields it is made of, as regions.

The icon renders are built from flat fields: a black margin, often a white card, and the object.
Deleting a *colour* everywhere is unsafe (a dark object on a black margin would lose its fill), so
this deletes *regions*: the field connected to the image border first, then any large, uniform,
near-black or near-white field that touches what was already removed. Interior artwork is never
touched because it is never connected to the removed region.

This is the honest local answer to "can Python do the simple icons". It works when the fields are
genuinely flat; a render with a soft vignette instead of a card is not a field and is left to
recraft. `staging/cut/key_assets.py` is the route that ships; this tool is kept as the comparison
record (see `_review/ab_*` and `_review/audit_*`).

Usage:
    py -3.14 staging/cut/key_flat.py --check  <name>...     # write results to _keying/flat/
    py -3.14 staging/cut/key_flat.py --apply  <name>...     # write into cut/ (backs up first)
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
OUT = LIBRARY / "_keying" / "flat"
BACKUP = LIBRARY / "_prekey_backup"

HARD = 8
SOFT_HI = 40
BAND = 2
KEEP_MAX = 0.60      # a survivor bigger than this is the field, so the render is the other way round
KEEP_MIN = 0.04      # a survivor this small means the key ate the object; refuse
ERODE = 2
TOL = 8
MIN_FIELD = 0.06      # a flat field is at least this share of the canvas
FIELD_UNIFORMITY = 12  # a field is flat; painted metal is not
RECT_SHARE = 0.62      # a field reads as a plate; a glyph or a ring does not fill its box
CARD_UNIFORMITY = 4


def load_library() -> dict:
    return json.loads((LIBRARY / "_library.json").read_text(encoding="utf-8"))


def flat_fields(array: np.ndarray) -> tuple[np.ndarray, list[list[int]]]:
    """Return (removed mask, background colours that were removed).

    An icon render is a painted object on a flat field, and the field can be either way round:
    `icon_zoom_plus` is a dark magnifier on white, `icon_module_b_fold` is a white arrow on a dark
    card. So every flat field is a background candidate: the one connected to the image border
    (the margin), plus any uniform component at least MIN_FIELD of the canvas. What survives is
    the object. If the survivor still covers most of the canvas the render was the other way round
    and this key is refused (`key()` returns None), which leaves the file to recraft.
    """
    height, width, _ = array.shape
    border = np.concatenate([array[0], array[-1], array[:, 0], array[:, -1]])
    colours, counts = np.unique(border, axis=0, return_counts=True)
    base = colours[counts.argmax()].astype(np.int16)
    delta = np.abs(array - base).max(axis=2)
    seed = delta <= TOL
    labels, _ = ndimage.label(seed)
    border_labels = set(labels[0]) | set(labels[-1]) | set(labels[:, 0]) | set(labels[:, -1])
    border_labels.discard(0)
    removed = np.isin(labels, list(border_labels)) if border_labels else np.zeros_like(seed)
    background = [base]

    for _ in range(4):
        candidate_mask = ~removed
        values = array[candidate_mask]
        if values.size == 0:
            break
        quant = (values // 8).astype(np.int64)
        flat_keys = quant[:, 0] * 65536 + quant[:, 1] * 256 + quant[:, 2]
        inverse = np.unique(flat_keys, return_inverse=True)[1].reshape(-1)
        added = False
        order = np.argsort(-np.bincount(inverse))
        for key_index in order[:32]:
            selection = inverse == key_index
            if selection.sum() < MIN_FIELD * height * width:
                continue
            pixels = values[selection].astype(np.int16)
            spread = pixels.max(axis=0) - pixels.min(axis=0)
            if int(spread.max()) > FIELD_UNIFORMITY:
                continue  # painted, not a flat field
            colour = np.median(pixels, axis=0).astype(np.int16)
            close = np.zeros(candidate_mask.shape, dtype=bool)
            close[candidate_mask] = np.abs(values - colour).max(axis=1) <= TOL
            labels, count = ndimage.label(close)
            if not count:
                continue
            areas = ndimage.sum(close, labels, index=np.arange(1, count + 1))
            for index in np.argsort(-areas)[:4]:
                piece = labels == index + 1
                area = int(piece.sum())
                if area < MIN_FIELD * height * width:
                    continue
                rows = np.flatnonzero(piece.any(axis=1))
                cols = np.flatnonzero(piece.any(axis=0))
                box_area = (rows[-1] - rows[0] + 1) * (cols[-1] - cols[0] + 1)
                if area / box_area < RECT_SHARE:
                    continue  # a glyph or a ring, not a field
                removed |= piece
                background.append(colour)
                added = True
        if not added:
            break
    return removed, background


def key(image: Image.Image) -> tuple[Image.Image, dict]:
    rgb = image.convert("RGB")
    array = np.asarray(rgb, dtype=np.int16)
    height, width, _ = array.shape
    removed, background = flat_fields(array)
    subject = ~removed
    if subject.mean() > KEEP_MAX or subject.mean() < KEEP_MIN:
        return None, {"refused": True, "subject_pct": round(float(subject.mean()) * 100, 2)}
    core = ndimage.binary_erosion(subject, iterations=ERODE)
    band = (subject & ~core) | (ndimage.binary_dilation(subject, iterations=BAND) & ~subject)

    delta = np.full((height, width), 255, dtype=np.int16)
    for colour in background:
        delta = np.minimum(delta, np.abs(array - np.asarray(colour, dtype=np.int16)).max(axis=2))
    ramp = np.clip((delta.astype(np.float32) - HARD) / (SOFT_HI - HARD), 0.0, 1.0)
    alpha = np.zeros((height, width), dtype=np.float32)
    alpha[core] = 255.0
    alpha[band] = 255.0 * ramp[band]
    alpha = np.clip(np.round(alpha), 0, 255).astype(np.uint8)
    out = np.dstack([np.asarray(rgb, dtype=np.uint8), alpha])
    stats = {
        "background_colours": [list(map(int, c)) for c in background],
        "removed_pct": round(float(removed.mean()) * 100, 2),
        "soft_px": int(((alpha > 0) & (alpha < 255)).sum()),
    }
    return Image.fromarray(out, "RGBA"), stats


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="+")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    library = load_library()
    by_name = {v["name"]: v for v in library["assets"].values()
               if v["role"] in ("sprite", "plate")}
    OUT.mkdir(parents=True, exist_ok=True)
    for name in args.names:
        record = by_name.get(name)
        if not record:
            print(f"!! {name}: not in the library")
            continue
        target = LIBRARY / record["path"]
        backup = BACKUP / record["path"]
        source = backup if backup.exists() else target
        result, stats = key(Image.open(source))
        if result is None:
            print(f"{name}: refused ({stats}) - this one stays on its recraft key")
            continue
        if args.apply:
            backup.parent.mkdir(parents=True, exist_ok=True)
            if not backup.exists():
                shutil.copyfile(target, backup)
            result.save(target)
            print(f"{name}: keyed flat {stats['background_colours']} into cut/")
        else:
            result.save(OUT / f"{name}_flat.png")
            print(f"{name}: {stats}")


if __name__ == "__main__":
    main()
