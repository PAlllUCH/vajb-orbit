"""Cut each raw sheet into sprites: one file per named panel, object centred.

The grid in asset-library/_sheets.json says how many panels a sheet holds and what each one
is called, in reading order. It is authoritative: it is the same grid the original pass used
to name the shipped files, so the names cannot drift from the set the game knows. The panel
geometry it implies is *not* used to cut anything, though -- each object is found by looking
at the artwork -- so a divider landing a few pixels off can no longer slice an object.

For every sheet:

  1. mask the ink (everything that differs from the sheet's own outside colour),
  2. label the artwork, bridging small gaps and dropping the film grain,
  3. collect, per grid cell, every blob whose centre falls in that cell. One object drawn as
     several pieces (a pylon and its beacon, a gate's two arcs, a glyph in strokes) is
     therefore gathered back together, and a stray fragment cannot become its own sprite,
  4. crop each cell's artwork to its own bounding box and paste it centred on the canvas.

Canvas sizes, so that a sheet's sprites are all one size and line up when laid out:

  * the icons family is written on a single fixed square canvas for the whole set, and each
    icon is scaled to the same share of it -- that is what turns a 5x4 panel into 20 sprite
    files of one size and one visual weight;
  * anything else keeps its own scale and is only centred, on a canvas the size of the
    largest object on that sheet. A ship must not change size as it turns through its four
    views, and an L asteroid's sprite must stay bigger than an S one, so those are never
    rescaled.

Sheets that are whole-frame layers rather than objects -- backdrops, tiling layers, menu and
loading screens, full-frame vignettes, shipped panel assets -- are copied through untouched.
`plate` in the plan says which, and why.

Nothing is keyed and no alpha is written: the background is still in the file, which is what
the next pass needs.

Usage:
    py -3.14 staging/cut/cut_sheets.py --check          # report, write nothing
    py -3.14 staging/cut/cut_sheets.py
    py -3.14 staging/cut/cut_sheets.py --only contracts --verbose
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
PLAN = LIBRARY / "_sheets.json"
CUTS = LIBRARY / "cut"
MANIFEST = LIBRARY / "_cuts_manifest.json"
LAYOUT = LIBRARY / "_layout_deepseek.json"

BORDER = 4            # px of each edge sampled to learn the sheet's outside colour
INK_TOL = 8           # max-channel distance from the outside colour that still counts as background
TOLERANCES = (8, 12, 16, 24, 32, 48)   # raised in turn until the ink is not the whole frame
MAX_COMPONENT_SHARE = 0.9   # of the frame: a piece spanning more than this is background
BAND_QUANTUM = 16     # colour quantisation when counting the outside colour
BACKGROUND_MIN_SHARE = 0.08   # a border colour below this share is artwork, not background
BACKGROUND_MAX_COLOURS = 4    # a flat sheet has one; a baked checkerboard has two
BRIDGE = 10           # px of dilation, so the strokes of one object join into one blob
MIN_OBJECT_PX = 500   # ink pixels below which a connected piece is grain, not artwork
MARGIN_SHARE = 0.06   # canvas margin either side, as a share of the canvas's longest side
MIN_MARGIN = 8        # px floor on that margin
ICON_CANVAS = 512     # the one size every icon is written at
UNIFORM_FAMILIES = {"icons"}  # families whose objects are all scaled to the same extent


def outside_colours(image: np.ndarray) -> list[tuple[int, int, int]]:
    """The colours the sheet's outside is made of, from its border.

    Usually one. Some renders answered a request for transparency by baking a checkerboard
    into the RGB, and then the outside is two colours -- calling one of them artwork makes half
    the frame read as ink, which is what fused a drone-swarm sheet into six blobs. Any border
    colour holding at least `BACKGROUND_MIN_SHARE` of the border is background.
    """
    strips = np.concatenate([
        image[:BORDER].reshape(-1, 3),
        image[-BORDER:].reshape(-1, 3),
        image[:, :BORDER].reshape(-1, 3),
        image[:, -BORDER:].reshape(-1, 3),
    ])
    quantised = (strips // BAND_QUANTUM).astype(np.int32)
    keys = quantised[:, 0] * 4096 + quantised[:, 1] * 64 + quantised[:, 2]
    values, counts = np.unique(keys, return_counts=True)
    order = np.argsort(counts)[::-1]
    colours = []
    for index in order:
        if counts[index] / len(strips) < BACKGROUND_MIN_SHARE:
            break
        if len(colours) >= BACKGROUND_MAX_COLOURS:
            break
        colours.append(tuple(int(round(value))
                             for value in strips[keys == values[index]].mean(axis=0)))
    return colours or [(int(round(value)) for value in strips.mean(axis=0))]


def ink_mask(image: np.ndarray, background, tol: int = INK_TOL) -> np.ndarray:
    """Pixels that are none of the sheet's background colours."""
    if isinstance(background, tuple):
        background = [background]
    pixels = image.astype(np.int16)
    delta = np.full(image.shape[:2], 255, dtype=np.int16)
    for colour in background:
        delta = np.minimum(delta, np.abs(pixels - np.array(colour, dtype=np.int16)).max(axis=2))
    return delta > tol


def biggest_piece(mask: np.ndarray) -> int:
    """The pixel count of the largest piece of artwork the mask holds."""
    labelled, count = ndimage.label(mask)
    if not count:
        return 0
    sizes = np.bincount(labelled.ravel())[1:]
    sizes = sizes[sizes >= MIN_OBJECT_PX]
    return int(sizes.max()) if len(sizes) else 0


def artwork_mask(image: np.ndarray, background, cells: int) -> tuple[np.ndarray, int]:
    """The ink mask, at the lowest tolerance that does not swallow the frame.

    A sheet whose background is a gradient rather than a flat colour reads as ink almost
    everywhere at threshold 8, and then one piece spans the whole frame and every cell is
    handed the same giant object -- which is what happened to one of the two button-plate
    sheets. Raising the tolerance until the largest piece is a sane share of a cell is what
    separates the artwork from a noisy background; the tolerance used is reported.
    """
    limit = image.shape[0] * image.shape[1] * MAX_COMPONENT_SHARE * (2 if cells <= 1 else 1)
    mask = ink_mask(image, background, TOLERANCES[0])
    for tol in TOLERANCES:
        mask = ink_mask(image, background, tol)
        if biggest_piece(mask) <= limit:
            return mask, tol
    return mask, TOLERANCES[-1]


def tight_box(mask: np.ndarray, window: tuple[int, int, int, int]):
    """The artwork's own bounding box inside `window`, without the dilation that found it."""
    left, top, right, bottom = window
    inside = mask[top:bottom, left:right]
    rows = np.flatnonzero(inside.any(axis=1))
    columns = np.flatnonzero(inside.any(axis=0))
    if not len(rows) or not len(columns):
        return None
    return (int(left + columns[0]), int(top + rows[0]),
            int(left + columns[-1]) + 1, int(top + rows[-1]) + 1)


def blobs_on(mask: np.ndarray, cells: int = 1) -> list[tuple[int, int, int, int]]:
    """Every piece of artwork on the sheet, as a bounding box in sheet coordinates.

    Grain has to go **before** anything is bridged. Measured on `icon_map`, threshold 8 leaves
    25,064 components — the film grain the renders bake in — and bridging them joins the whole
    frame into one blob of 1.6M px, which is what silently merged every icon on a sheet into a
    single object. So: label, drop every component smaller than `MIN_OBJECT_PX` (real artwork on
    these sheets is 10k px and up, grain is tens of px), then bridge what is left so the strokes
    of one shape join, and tighten each box back onto the clean mask.

    On a sheet of more than one panel, a piece whose box spans nearly the whole frame is a faint
    backdrop structure, not an object — one button-plate sheet carries such a piece, and it
    swallowed whichever cell its centre landed in.
    """
    labelled, count = ndimage.label(mask)
    if not count:
        return []
    sizes = np.bincount(labelled.ravel())
    keep = np.flatnonzero(sizes >= MIN_OBJECT_PX)
    keep = keep[keep != 0]
    if not len(keep):
        return []
    clean = np.isin(labelled, keep)

    height, width = mask.shape
    grown = ndimage.binary_dilation(clean, np.ones((BRIDGE, BRIDGE), dtype=bool))
    found = []
    for window in ndimage.find_objects(ndimage.label(grown)[0]):
        if window is None:
            continue
        if cells > 1 and (window[1].stop - window[1].start) > width * MAX_COMPONENT_SHARE \
                and (window[0].stop - window[0].start) > height * MAX_COMPONENT_SHARE:
            continue
        box = tight_box(clean, (window[1].start, window[0].start, window[1].stop, window[0].stop))
        if box is not None:
            found.append(box)
    return found


def cell_of(box, grid: tuple[int, int], width: int, height: int) -> tuple[int, int]:
    """The reading-order cell a point falls in, as (column, row), 1-based."""
    columns, rows = grid
    centre_x = (box[0] + box[2]) / 2
    centre_y = (box[1] + box[3]) / 2
    column = min(columns, int(centre_x * columns / width) + 1)
    row = min(rows, int(centre_y * rows / height) + 1)
    return max(1, column), max(1, row)


def cell_bounds(grid: tuple[int, int], width: int, height: int) -> tuple[list[int], list[int]]:
    """The cell boundary lines a grid implies, for reporting stray artwork."""
    return ([round(index * width / grid[0]) for index in range(1, grid[0])],
            [round(index * height / grid[1]) for index in range(1, grid[1])])


def margin_for(canvas: tuple[int, int]) -> int:
    return max(MIN_MARGIN, round(MARGIN_SHARE * max(canvas)))


def fit(crop: Image.Image, canvas: tuple[int, int], uniform: bool) -> Image.Image:
    """The object at the size its canvas wants: one uniform extent, or its own size."""
    width, height = canvas
    room = margin_for(canvas)
    if uniform or crop.width > width - 2 * room or crop.height > height - 2 * room:
        scale = min((width - 2 * room) / crop.width, (height - 2 * room) / crop.height)
    else:
        scale = 1.0
    if abs(scale - 1.0) < 1e-3:
        return crop
    return crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
                       Image.LANCZOS)


def read_arrangements() -> dict:
    """The arrangements a vision model read off the renders, if that pass has been run."""
    if not LAYOUT.exists():
        return {}
    return json.loads(LAYOUT.read_text(encoding="utf-8")).get("sheets", {})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="", help="only sheets whose raw stem contains this")
    parser.add_argument("--check", action="store_true", help="report only, write nothing")
    parser.add_argument("--verbose", action="store_true", help="one line per sheet")
    parser.add_argument("--replace", action="store_true",
                        help="clear stale .png from cut/ first (names change between runs)")
    args = parser.parse_args()

    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    sheets = [s for s in plan["sheets"] if args.only in s["raw"]]
    if not sheets:
        print(f"no sheet matches {args.only!r}")
        return 1
    if not args.check:
        CUTS.mkdir(exist_ok=True)
        stale = sorted(CUTS.glob("*.png"))
        if stale and not args.replace:
            print(f"cut/ already holds {len(stale)} file(s) and the cutter never deletes: "
                  f"re-run with --replace to clear them first, or the output will be a mix of "
                  f"two runs")
            return 1
        if stale:
            for path in stale:
                path.unlink()
            print(f"cleared {len(stale)} stale file(s) from cut/")

    seen = read_arrangements()
    entries, missing, straddling, oversized, relaid, raised = [], [], [], [], [], []
    plates = sprites = resized = 0
    for sheet in sheets:
        image = np.array(Image.open(LIBRARY / sheet["raw"]).convert("RGB"),
                         dtype=np.uint8, copy=True)
        height, width = image.shape[:2]
        planned = tuple(sheet["grid"])
        # A model that looked at the render decides the arrangement when its answer holds the
        # same number of cells; otherwise the prompt's arrangement stands.
        read = seen.get(sheet["raw"], {})
        grid = planned
        if read and len(sheet["cuts"]) > 1 and not sheet.get("plate") \
                and read.get("columns", 0) * read.get("rows", 0) == planned[0] * planned[1]:
            grid = (read["columns"], read["rows"])
            if grid != planned:
                relaid.append((sheet["raw"], f"{planned[0]}x{planned[1]}", f"{grid[0]}x{grid[1]}",
                               f"read by {read.get('model')}, confidence {read.get('confidence')}"))
        unnamed = "unnamed" in sheet["plan_from"]
        tolerance = INK_TOL
        entry = {
            "raw": sheet["raw"],
            "family": sheet["family"],
            "stamp": sheet["stamp"],
            "run_key": sheet["run_key"],
            "grid": list(grid),
            "planned_grid": list(planned),
            "ink_tolerance": tolerance,
            "arrangement_from": "model" if grid != planned else "plan",
            "plate": bool(sheet.get("plate")),
            "plate_because": sheet.get("plate_because", ""),
            "plan_from": sheet["plan_from"],
            "sprites": [],
        }

        if sheet.get("plate"):
            entry["canvas"] = [width, height]
            entry["plate_name"] = sheet["cuts"][0]
            plates += 1
            if not args.check:
                Image.fromarray(image).save(CUTS / f"{sheet['cuts'][0]}.png")
            entries.append(entry)
            if args.verbose:
                print(f"  {sheet['raw']:62} plate {width}x{height} -> {sheet['cuts'][0]}")
            continue

        mask, tolerance = artwork_mask(image, outside_colours(image), max(1, len(sheet["cuts"])))
        if tolerance != INK_TOL:
            raised.append((sheet["raw"], tolerance, len(sheet["cuts"])))
        pieces = blobs_on(mask, len(sheet["cuts"]))
        columns, rows = cell_bounds(grid, width, height)
        for box in pieces:
            if any(box[0] < line < box[2] for line in columns) \
                    or any(box[1] < line < box[3] for line in rows):
                straddling.append((sheet["raw"], box))
                break

        per_cell: dict[tuple[int, int], list] = {}
        for box in pieces:
            per_cell.setdefault(cell_of(box, grid, width, height), []).append(box)

        cells = []
        for order, name in enumerate(sheet["cuts"], start=1):
            column = (order - 1) % grid[0] + 1
            row = (order - 1) // grid[0] + 1
            found = per_cell.get((column, row), [])
            if not found:
                if not unnamed:
                    missing.append((sheet["raw"], name, f"cell r{row}c{column} holds no artwork"))
                continue
            box = (min(b[0] for b in found), min(b[1] for b in found),
                   max(b[2] for b in found), max(b[3] for b in found))
            cells.append((name, (column, row), box, len(found)))

        for column, row in per_cell:
            if (row - 1) * grid[0] + column > len(sheet["cuts"]):
                missing.append((sheet["raw"], "-", f"artwork in cell r{row}c{column}, past the "
                                                   f"{len(sheet['cuts'])} named panel(s)"))

        uniform = sheet["family"] in UNIFORM_FAMILIES
        if uniform:
            canvas = (ICON_CANVAS, ICON_CANVAS)
        elif cells:
            widths = [c[2][2] - c[2][0] for c in cells]
            heights = [c[2][3] - c[2][1] for c in cells]
            room = margin_for((max(widths), max(heights)))
            canvas = (max(widths) + 2 * room, max(heights) + 2 * room)
        else:
            canvas = (width, height)
        entry["canvas"] = list(canvas)

        for name, (column, row), box, pieces_in_cell in cells:
            crop = Image.fromarray(image[box[1]:box[3], box[0]:box[2]])
            if not uniform and (crop.width > canvas[0] or crop.height > canvas[1]):
                oversized.append((sheet["raw"], name,
                                  f"{crop.width}x{crop.height} against a {canvas[0]}x{canvas[1]} canvas"))
            sprite = fit(crop, canvas, uniform)
            if (sprite.width, sprite.height) != (crop.width, crop.height):
                resized += 1
            out = Image.new("RGB", canvas, (0, 0, 0))
            out.paste(sprite, ((canvas[0] - sprite.width) // 2, (canvas[1] - sprite.height) // 2))
            entry["sprites"].append({
                "name": name,
                "row": row,
                "col": column,
                "source_box": [int(value) for value in box],
                "source_size": [int(box[2] - box[0]), int(box[3] - box[1])],
                "pieces": pieces_in_cell,
            })
            sprites += 1
            if not args.check:
                out.save(CUTS / f"{name}.png")

        entries.append(entry)
        if args.verbose:
            print(f"  {sheet['raw']:62} {grid[0]}x{grid[1]} canvas {canvas[0]}x{canvas[1]}  "
                  f"{len(pieces)} piece(s) -> {len(cells)} sprite(s)")

    print(f"sheets {len(entries)}  plates {plates}  sprites {sprites}  resized {resized}")
    if raised:
        print(f"{len(raised)} sheet(s) whose background needed a higher ink tolerance:")
        for raw, tol, cells in raised:
            print(f"  tolerance {tol:3} for {cells:2} cell(s)   [{raw}]")
    if relaid:
        print(f"{len(relaid)} sheet(s) cut in an arrangement a model read off the render:")
        for raw, was, now, why in relaid:
            print(f"  {was} -> {now:8} {why:44} [{raw}]")
    if straddling:
        print(f"{len(straddling)} sheet(s) with artwork across a cell line (worth an eye):")
        for raw, box in straddling:
            print(f"  {box}   [{raw}]")
    if oversized:
        print(f"{len(oversized)} sprite(s) bigger than their canvas:")
        for raw, name, why in oversized[:20]:
            print(f"  {name:42} {why}   [{raw}]")
    if missing:
        print(f"{len(missing)} named panel(s) with no artwork:")
        for raw, name, why in missing:
            print(f"  {name:42} {why}   [{raw}]")
    if args.check:
        print("check only, nothing written")
        return 0

    MANIFEST.write_text(json.dumps({
        "note": (
            "What the cutter produced. One entry per raw sheet. `plate` marks a whole-frame "
            "layer copied as is (a backdrop, a tiling layer, a full-frame vignette, a shipped "
            "panel asset), with `plate_because` saying why. Otherwise the artwork was "
            "segmented from the sheet and every blob whose centre falls in a cell was gathered "
            "into that cell's sprite, so a shape drawn as several pieces stays one sprite. Each "
            "sprite is pasted centred on `canvas`: a sheet's sprites are all one size, and the "
            "`icons` family additionally shares a single "
            f"{ICON_CANVAS}px square canvas with every icon scaled to the same extent, while "
            "other families keep their own scale so a ship does not change size as it turns and "
            "a small asteroid stays small. `source_box` is where the artwork sat on the raw "
            "sheet. No keying, no alpha: the background is still in the file for the next pass."
        ),
        "counts": {"sheets": len(entries), "plates": plates, "sprites": sprites,
                   "resized": resized, "sheets_with_artwork_across_a_cell_line": len(straddling),
                   "named_panels_without_artwork": len(missing),
                   "arrangement_read_by_a_model": len(relaid),
                   "tolerance_raised": len(raised)},
        "sheets": entries,
    }, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {MANIFEST}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
