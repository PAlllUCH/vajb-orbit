"""Find the objects on a 2K panel render and cut each one out of it, before any keying.

The first pass keyed the whole 2x2 panel through `recraft/remove-background` and then cut it on a
blind 2x2 grid, and both halves of that are wrong on real renders:

1. **A panel is not one subject.** recraft's matte treats the strongest object as the subject and
   can delete or crop the others: on `ship_apex_sheet` it removed the bottom ~300 px of the
   bottom-right cell and the left quarter of the top-left one; on `ship_sibelon_sheet` it cropped
   both sides of the top-left object and the top and bottom of the bottom-left one. Measured by
   comparing each quadrant's ink bounding box before keying with its alpha box after.
2. **Objects do not respect the quadrant midlines.** A ship drawn in the top-left cell routinely
   runs past the halfway column, so a grid cut truncates its tail: `ship_apex_side` and
   `ship_sibelon_side` were both clipped this way (their raw ink boxes start at x=0 of the right
   half, i.e. they begin left of the midline).

So the order is: **render -> find the objects -> cut each object's own box -> key each cut on its
own -> trim and centre**. One object per keying call is what makes the paid matte reliable, and a
box taken from the object's own pixels is what makes the cut complete.

Usage:
    py -3.14 staging/phase_g/panels.py --detect <render.png> [--page out.jpg]
    py -3.14 staging/phase_g/panels.py --cut <render.png> --out <dir> --names a,b,c,d
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
INK_TOL = 16.0          # a pixel this far from the border median is not background
MIN_SHARE = 0.002       # blobs smaller than this share of the biggest one are dust
CLOSE = 3               # dilate before labelling, so a thin antenna does not fall off its hull


def background_value(gray: np.ndarray, ring: int = 12) -> float:
    edges = np.concatenate([gray[:ring, :].ravel(), gray[-ring:, :].ravel(),
                            gray[:, :ring].ravel(), gray[:, -ring:].ravel()])
    return float(np.median(edges))


def ink_mask(gray: np.ndarray) -> np.ndarray:
    bg = background_value(gray)
    contrast = float(np.percentile(gray, 99.9) - bg)
    tolerance = max(INK_TOL, 0.04 * contrast)
    mask = np.abs(gray - bg) > tolerance
    return mask


def objects(image: Image.Image) -> list[dict]:
    """Every object on the panel, as a bounding box plus its own pixel mask."""
    gray = np.asarray(image.convert("L")).astype(np.float32)
    mask = ink_mask(gray)
    grown = ndimage.binary_dilation(mask, np.ones((CLOSE, CLOSE), bool))
    labels, count = ndimage.label(grown, np.ones((3, 3), int))
    if not count:
        return []
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    floor = float(sizes.max()) * MIN_SHARE
    found: list[dict] = []
    for index in range(1, count + 1):
        if sizes[index - 1] < floor:
            continue
        own = (labels == index) & mask
        rows = np.where(own.any(axis=1))[0]
        cols = np.where(own.any(axis=0))[0]
        if not len(rows) or not len(cols):
            continue
        found.append({
            "box": [int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1],
            "px": int(own.sum()),
            "centre": [float(cols.mean()), float(rows.mean())],
            "index": index,
        })
    return found


def cells(image: Image.Image, cols: int = 2, rows: int = 2) -> list[dict]:
    """Group the render's ink into the panel's cells, in reading order.

    Grouping is by **pixel mass in a grid cell**, not by centroid and not by the component list:
    a hull is usually several components (tendrils, detached fins, a separated antenna) and it
    routinely runs past a midline, so each component is assigned to the grid cell that holds most
    of its pixels and each cell's box is the union of the boxes that ended up there. The box
    therefore covers the whole object even when the object crosses a midline, which is exactly
    what a grid cut got wrong.

    `cols`/`rows` come from the panel's own plan (the driver's `cells` is the authority): the
    Phase G hull sheets are 2x2, the D6 instrument panel is 2x2, its frame+glass panel is 1x2 and
    the two seven-segment panels are 3x2 (`UI_CHROME_ASSETS_SPEC` section 11).
    """
    gray = np.asarray(image.convert("L")).astype(np.float32)
    height, width = gray.shape
    mask = ink_mask(gray)
    grown = ndimage.binary_dilation(mask, np.ones((CLOSE, CLOSE), bool))
    labels, count = ndimage.label(grown, np.ones((3, 3), int))
    if not count:
        return []
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    floor = max(float(sizes.max()) * MIN_SHARE, 64.0)
    row_edges = [r * height // rows for r in range(rows + 1)]
    col_edges = [c * width // cols for c in range(cols + 1)]
    grid = [[np.zeros((height, width), bool) for _ in range(cols)] for _ in range(rows)]
    for index in range(1, count + 1):
        if sizes[index - 1] < floor:
            continue
        own = (labels == index) & mask
        rows_at, cols_at = np.where(own)
        areas = np.array([
            [int(((rows_at >= row_edges[r]) & (rows_at < row_edges[r + 1])
                  & (cols_at >= col_edges[c]) & (cols_at < col_edges[c + 1])).sum())
             for c in range(cols)]
            for r in range(rows)
        ])
        row, col = np.unravel_index(int(np.argmax(areas)), areas.shape)
        grid[row][col] |= own
    groups: list[dict] = []
    for row in range(rows):
        for col in range(cols):
            own = grid[row][col]
            rows_at, cols_at = np.where(own)
            if not len(rows_at):
                continue
            groups.append({
                "box": [int(cols_at.min()), int(rows_at.min()),
                        int(cols_at.max()) + 1, int(rows_at.max()) + 1],
                "px": int(own.sum()),
                "mask": own,
                "centre": [float(cols_at.mean()), float(rows_at.mean())],
                "quadrant": [row, col],
            })
    return groups


def clusters(image: Image.Image, expected: int = 4, cols: int = 2, rows: int = 2) -> list[dict]:
    return cells(image, cols, rows)


def has_native_alpha(image: Image.Image, share: float = 0.01) -> bool:
    """True when the render came back with real transparency (the native-alpha route)."""
    if image.mode not in ("RGBA", "LA"):
        return False
    alpha = np.asarray(image.convert("RGBA").getchannel("A"))
    return float((alpha == 0).mean()) > share


def cut_object(image: Image.Image, group: dict, pad_share: float = 0.03) -> Image.Image:
    """Crop one cell to its own box, clearing everything that is not part of that object.

    An opaque render (white backdrop, the D6 route) is cleared to opaque black so the paid matte
    has one object on a flat field; a render that already carries alpha keeps it, so the cut never
    paints a black frame around art that was transparent to begin with.
    """
    rgba = image.convert("RGBA")
    left, top, right, bottom = group["box"]
    pad = max(6, int(round(pad_share * max(right - left, bottom - top))))
    left, top = max(0, left - pad), max(0, top - pad)
    right, bottom = min(rgba.size[0], right + pad), min(rgba.size[1], bottom + pad)
    pixels = np.asarray(rgba).copy()
    keep = np.zeros(pixels.shape[:2], bool)
    keep[top:bottom, left:right] = True
    outside = ~(group["mask"] & keep)
    if has_native_alpha(image):
        pixels[outside, 3] = 0
    else:
        pixels[outside] = (0, 0, 0, 255)
    return Image.fromarray(pixels[top:bottom, left:right], "RGBA")


def _union(group: list[dict]) -> tuple[int, int, int, int]:
    left = min(o["box"][0] for o in group)
    top = min(o["box"][1] for o in group)
    right = max(o["box"][2] for o in group)
    bottom = max(o["box"][3] for o in group)
    return left, top, right, bottom


def build_page(render: Path, page: Path, cols: int = 2, rows: int = 2) -> None:
    image = Image.open(render).convert("RGB")
    found = objects(image)
    ordered = clusters(image, cols=cols, rows=rows)
    draw = ImageDraw.Draw(image)
    for order, group in enumerate(ordered, 1):
        left, top, right, bottom = group["box"]
        draw.rectangle([left, top, right, bottom], outline=(74, 232, 108), width=6)
        draw.text((left + 10, top + 10), f"{order}", fill=(74, 232, 108))
    for entry in found:
        left, top, right, bottom = entry["box"]
        draw.rectangle([left, top, right, bottom], outline=(200, 70, 27), width=2)
    image.thumbnail((560, 560), Image.LANCZOS)
    page.parent.mkdir(parents=True, exist_ok=True)
    image.save(page, quality=74)
    print(f"{page}  {image.size}  objects={len(found)} groups={len(ordered)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--detect", default="")
    parser.add_argument("--cut", default="")
    parser.add_argument("--out", default="")
    parser.add_argument("--names", default="")
    parser.add_argument("--page", default="")
    parser.add_argument("--json", default="")
    parser.add_argument("--grid", default="2x2",
                        help="panel grid as CxR, the driver's `cells` plan (default 2x2)")
    args = parser.parse_args()
    grid_cols, grid_rows = (int(v) for v in args.grid.lower().split("x"))

    if args.detect:
        render = Path(args.detect)
        ordered = clusters(Image.open(render), cols=grid_cols, rows=grid_rows)
        if args.json:
            Path(args.json).write_text(json.dumps(
                [{"box": g["box"], "px": g["px"], "centre": g["centre"]} for g in ordered], indent=1),
                encoding="utf-8")
        for order, group in enumerate(ordered, 1):
            print(f"  {order}: box={group['box']} px={group['px']} centre={[round(v) for v in group['centre']]}")
        if args.page:
            build_page(render, Path(args.page), cols=grid_cols, rows=grid_rows)
        return 0

    if args.cut:
        render = Path(args.cut)
        names = [n for n in args.names.split(",") if n]
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        ordered = clusters(Image.open(render), cols=grid_cols, rows=grid_rows)
        if not names:
            names = [f"cell{i + 1}" for i in range(len(ordered))]
        if len(ordered) != len(names):
            print(f"  WARNING {len(ordered)} object group(s) for {len(names)} name(s)")
        for group, name in zip(ordered, names):
            cut = cut_object(Image.open(render), group)
            dest = out / f"{name}.png"
            cut.convert("RGB").save(dest)
            print(f"  {dest.name} {cut.size}")
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
