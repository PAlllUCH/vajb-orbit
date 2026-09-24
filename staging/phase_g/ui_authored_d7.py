"""D7 authored fallback: pinned well geometry drawn over a render's painted plate.

Wave D7, `docs/design/UI_CHROME_ASSETS_SPEC.md` section 12's fallback route, named there as "the
D6-authored route (`ui_authored.py` shapes over a painted plate)". Section 12 gates the ship step
on the well QC: for every well-bearing panel the wells must be measured against the UI_SPEC
section 3.7 / 3.8 / 3.10 bay rects at 2x, and a render whose wells do not line up re-renders once,
then falls back to this route. This is that route for the wells.

It does three things per panel, all measured rather than invented:

1. **The model's own wells are erased.** The same dark-region detector `qc_d7.py` measures with
   finds them, and each one is clone-filled from the plate's own painted texture (a mirrored copy
   of the nearest fully-painted patch of the same box), so the panel keeps its painted material.
   The plate's own dark outline and any sub-recess nested inside a bigger well are kept.
2. **The pinned wells are drawn at their exact 2x rects** - rounded rects for the rectangular
   wells, ellipses for the circular ones - in the palette sampled from the render itself (rim
   light, rim dark, void interior). A recess reads as a raised rim band, a dark inner shadow on
   the upper-left wall, and a void interior.
3. **The pinned sub-recesses come with them**: the armory rack bay's four 20x22 slots on a 22
   pitch with their engraved ledge (section 3.10 / Mockup A), the console's seven slots along its
   top well and the status panel's fifteen slots in its right well (section 12's own prompts).

Usage:
    py -3.14 staging/phase_g/ui_authored_d7.py --list
    py -3.14 staging/phase_g/ui_authored_d7.py ui_status_panel ...
    py -3.14 staging/phase_g/ui_authored_d7.py --all --preview      # + a JPEG per panel
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"
## `D7_MASTERS_DIR` lets the authored pass read the pass-1 fitted masters (`_masters_pass1`) while
## the re-render's own pass is still in flight, so a route decision can be measured, not guessed.
MASTERS = Path(os.environ.get("D7_MASTERS_DIR", STAGE / "ui" / "_masters"))
AUTHORED = Path(os.environ.get("D7_AUTHORED_DIR", STAGE / "ui" / "_authored"))
BOXES = {
    "ui_cockpit_panel": (928, 512),
    "ui_status_panel": (1440, 1040),
    "ui_armory_console": (1744, 1816),
    "ui_armory_rack_plate": (194, 182),
}
## Every pinned well, at 2x. `circle` = (cx, cy, r); `rect` = (x0, y0, x1, y1).
WELLS: dict[str, list[dict]] = {
    ## UI_SPEC section 3.7's D7 amendment + the approved Mockup v5 geometry table.
    "ui_cockpit_panel": [
        {"label": "gauge_well", "circle": (190, 172, 116)},
        {"label": "compass_well", "circle": (434, 172, 58)},
        {"label": "readout_well", "rect": (558, 62, 858, 442)},
        {"label": "ammo_recess", "rect": (64, 370, 316, 442)},
        {"label": "hdg_recess", "rect": (330, 370, 538, 442)},
    ],
    ## UI_SPEC section 3.8's Mockup C block at 2x, carrying its 5x3 slot grid (60x74 logical cells
    ## on a 72x88 pitch -> 120x148 on a 144x176 pitch at 2x).
    "ui_status_panel": [
        {"label": "left_well", "rect": (48, 120, 600, 856)},
        {"label": "right_well", "rect": (632, 120, 1392, 696), "grid": {
            "size": (120, 148), "pitch": (144, 176), "count": (5, 3), "margin": (20, 24)}},
        {"label": "footer_strip", "rect": (48, 888, 1392, 988)},
    ],
    ## UI_SPEC section 3.10 / Mockup A's three-well console, plus section 12 run 3's own "seven
    ## short machined slot recesses along" the top well.
    "ui_armory_console": [
        {"label": "racks_well", "rect": (60, 244, 1684, 1024), "strip": {
            "size": (150, 260), "count": 7, "margin": (78, 120)}},
        {"label": "inventory_well", "rect": (60, 1140, 1684, 1480)},
        {"label": "ammo_well", "rect": (60, 1592, 1684, 1768)},
    ],
    ## UI_SPEC section 3.10 / Mockup A: four 20x22 logical slots on a 22 pitch, plus the thin
    ## engraved ledge along the bay's bottom edge.
    "ui_armory_rack_plate": [
        *[{"label": f"slot_{s + 1}", "rect": (10 + 44 * s, 38, 50 + 44 * s, 82)} for s in range(4)],
        {"label": "engraved_ledge", "rect": (8, 96, 186, 100)},
    ],
}
## What each panel needs from this route. `None` means the render's own wells passed the QC's
## `lines up` rule (each well's centre inside its pinned bay at 2x) and nothing is authored.
## `erase` is "all" (every detected well) or "off-grid" (only the wells whose centre is outside the
## pinned rect they belong to); `fill` is "reflect" (hole-only) or "mirror" (the plate is mirrored
## across its own edges to fill a box wider than the render, which is what the armory console needs:
## its render is a tall 0.56-aspect plate in a 0.96-aspect box, so a contain fit leaves the pinned
## wells wider than the plate).
PLAN: dict[str, dict | None] = {
    "ui_cockpit_panel": {"erase": "all", "fill": "reflect", "draw": "all"},
    "ui_status_panel": {"erase": "off-grid", "fill": "reflect", "draw": "off-grid"},
    "ui_armory_console": {"erase": "all", "fill": "mirror", "draw": "all"},
    "ui_armory_rack_plate": {"erase": "all", "fill": "reflect", "draw": "all"},
}
DARK_FRACTION = 0.5   # the same split qc_d7.py measures with
CLOSE = 5
MIN_AREA = 240
RIM_GROW = 5            # px of raised rim around a well opening, at 2x
ERASE_GROW = 26         # px the old well's own bevel/rim around its void core
AUTHORED_FOOTPRINT = 10  # px of the authored well's footprint erased with it
## Only a dark region this big a share of the plate's painted pixels is a well of the model's own
## drawing; smaller ones are grunge, bolt shadows and seams, and erasing them would eat the plate.
ERASE_MIN_SHARE = 0.01
RIM_INNER_GROW = 2      # px of dark outline right at the opening
INNER_WALL = 7          # px of inner wall (shadow upper-left, light catch lower-right)
SUPERSAMPLE = 2


# ------------------------------------------------------------------ measurement helpers

def dark_regions(img: Image.Image) -> list[dict]:
    """The same dark-region read `qc_d7.py` measures with."""
    rgba = np.asarray(img.convert("RGBA"))
    alpha = rgba[..., 3]
    gray = np.asarray(img.convert("L")).astype(np.float32)
    opaque = alpha > 8
    if not opaque.any():
        return []
    thr = DARK_FRACTION * float(np.median(gray[opaque]))
    dark = ndimage.binary_closing(opaque & (gray < thr), np.ones((CLOSE, CLOSE), bool))
    dark = ndimage.binary_fill_holes(dark)
    labels, count = ndimage.label(dark, np.ones((3, 3), bool))
    found: list[dict] = []
    for index in range(1, count + 1):
        own = labels == index
        area = int(own.sum())
        if area < MIN_AREA:
            continue
        rows_at, cols_at = np.where(own)
        found.append({"box": [int(cols_at.min()), int(rows_at.min()),
                              int(cols_at.max()) + 1, int(rows_at.max()) + 1],
                      "area": area, "mask": own})
    return found


def regions_to_erase(img: Image.Image, name: str) -> np.ndarray:
    """The model's own wells, without the plate's outline and without nested sub-recesses."""
    rgba = np.asarray(img.convert("RGBA"))
    opaque = rgba[..., 3] > 8
    rows_at, cols_at = np.where(opaque)
    if not len(rows_at):
        return np.zeros(opaque.shape, bool)
    plate = [int(cols_at.min()), int(rows_at.min()),
             int(cols_at.max()) + 1, int(rows_at.max()) + 1]
    keep: list[dict] = []
    plate_area = float((plate[2] - plate[0]) * (plate[3] - plate[1]))
    for region in dark_regions(img):
        bx0, by0, bx1, by1 = region["box"]
        shares_plate = ((min(bx1, plate[2]) - max(bx0, plate[0]))
                        * (min(by1, plate[3]) - max(by0, plate[1])) / max(1.0, plate_area))
        if shares_plate >= 0.90:
            continue                       # the plate's own dark outline
        if region["area"] < ERASE_MIN_SHARE * float(opaque.sum()):
            continue                       # grunge, not a well
        keep.append(region)
    keep.sort(key=lambda r: -r["area"])
    chosen: list[dict] = []
    for region in keep:
        bx0, by0, bx1, by1 = region["box"]
        if any((max(0, min(bx1, o["box"][2]) - max(bx0, o["box"][0]))
                * max(0, min(by1, o["box"][3]) - max(by0, o["box"][1])))
               >= 0.80 * (bx1 - bx0) * (by1 - by0) for o in chosen):
            continue                        # a sub-recess inside a well already being erased
        chosen.append(region)
    mask = np.zeros(opaque.shape, bool)
    for region in chosen:
        mask |= region["mask"]
    ## A well is not only its darkest core: the bevel, the rim and the cast shadow around the void
    ## are part of the object the model drew, and leaving them behind would show as a ghost of the
    ## old well behind the authored one. So the erase grows each core generously and then takes in
    ## the authored well's own footprint too.
    mask = ndimage.binary_dilation(mask, ndimage.generate_binary_structure(2, 2),
                                   iterations=ERASE_GROW)
    for well in WELLS[name]:
        kind, geom = geometry(well)
        grown = grow({kind: geom}, AUTHORED_FOOTPRINT)
        mask |= shape_mask((opaque.shape[1], opaque.shape[0]), grown[0], grown[1]) > 127
    inner = ndimage.binary_erosion(opaque, np.ones((9, 9), bool))
    mask &= inner | (opaque & ~ndimage.binary_erosion(opaque, np.ones((3, 3), bool)))
    mask &= opaque
    return mask


def reflect_fill(rgb: np.ndarray, opaque: np.ndarray, mask: np.ndarray,
                 grain: bool = True) -> np.ndarray:
    """Fill each erased region by reflecting the plate's own edge pixels inward, then regrain.

    The model's wells are large (two thirds of a plate's painted pixels on the cockpit render), so a
    diffusion of the whole hole washes the panel out and a clone has no well-free source big enough
    to take from. A mirror of the four edges onto the hole keeps the plate's local tone and grain
    direction, which is what a recess sitting in a plate would have around it; the seam is feathered
    and the plate's measured grain is put back so the patch does not read as a smooth smear.
    """
    from scipy import ndimage as ndi
    work = rgb.astype(np.float32)
    labels, count = ndi.label(mask, np.ones((3, 3), bool))
    for index in range(1, count + 1):
        own = labels == index
        rows_at, cols_at = np.where(own)
        x0, y0 = int(cols_at.min()), int(rows_at.min())
        x1, y1 = int(cols_at.max()) + 1, int(rows_at.max()) + 1
        if x0 < 1 or y0 < 1 or x1 >= rgb.shape[1] or y1 >= rgb.shape[0]:
            continue
        width, height = x1 - x0, y1 - y0
        left = np.repeat(work[y0:y1, x0 - 1:x0], width, axis=1)
        right = np.repeat(work[y0:y1, x1:x1 + 1], width, axis=1)[:, ::-1]
        top = np.repeat(work[y0 - 1:y0, x0:x1], height, axis=0)
        bottom = np.repeat(work[y1:y1 + 1, x0:x1], height, axis=0)[::-1]
        candidates = np.stack([left[:, ::-1], right, top[::-1], bottom])
        patch = np.median(candidates, axis=0)
        solid = ndi.binary_erosion(own, np.ones((5, 5), bool))[y0:y1, x0:x1]
        alpha = ndi.gaussian_filter(solid.astype(np.float32), 3.0)[..., None]
        window = work[y0:y1, x0:x1]
        window[:] = patch * alpha + window * (1.0 - alpha)
    detail = rgb.astype(np.float32) - ndi.gaussian_filter(rgb.astype(np.float32), 2.0, mode="nearest")
    valid = opaque & ~mask
    if grain and valid.any():
        sigma = float(np.percentile(np.abs(detail[valid]).mean(axis=1), 60))
        rng = np.random.default_rng(7)
        work[mask] = np.clip(work[mask] + rng.normal(0.0, max(1.0, sigma), work[mask].shape),
                             0, 255)
    return np.clip(work, 0, 255).astype(np.uint8)


def sample_palette(rgb: np.ndarray, opaque: np.ndarray) -> dict:
    """Rim light / rim dark / void interior, sampled from the render's own painted pixels."""
    gray = rgb.mean(axis=2)[opaque]
    mean_rgb = rgb[opaque].mean(axis=0).astype(np.float32)
    levels = {"rim_light": np.percentile(gray, 90), "rim_dark": np.percentile(gray, 25),
              "void": np.percentile(gray, 6)}
    palette: dict[str, list[int]] = {}
    for key, level in levels.items():
        scale = float(level) / max(1.0, float(gray.mean()))
        palette[key] = [int(v) for v in np.clip(mean_rgb * scale, 4, 250)]
    palette["shadow"] = [int(v) for v in np.clip(np.array(palette["void"]) * 0.45, 2, 250)]
    return palette


# ------------------------------------------------------------------ drawing helpers

def shape_mask(size: tuple[int, int], kind: str, geom: tuple) -> np.ndarray:
    """An anti-aliased 0..255 mask for a circle (cx, cy, r) or a rounded rect (x0, y0, x1, y1)."""
    width, height = size[0] * SUPERSAMPLE, size[1] * SUPERSAMPLE
    mask = Image.new("L", (width, height), 0)
    from PIL import ImageDraw
    draw = ImageDraw.Draw(mask)
    if kind == "circle":
        cx, cy, radius = geom
        draw.ellipse([(cx - radius) * SUPERSAMPLE, (cy - radius) * SUPERSAMPLE,
                      (cx + radius) * SUPERSAMPLE, (cy + radius) * SUPERSAMPLE], fill=255)
    else:
        x0, y0, x1, y1 = geom
        draw.rounded_rectangle([x0 * SUPERSAMPLE, y0 * SUPERSAMPLE,
                                x1 * SUPERSAMPLE, y1 * SUPERSAMPLE],
                               radius=7 * SUPERSAMPLE, fill=255)
    return np.asarray(mask.resize(size, Image.LANCZOS)).astype(np.float32)


def geometry(well: dict) -> tuple[str, tuple]:
    return ("circle", well["circle"]) if "circle" in well else ("rect", well["rect"])


def grow(well: dict, amount: int) -> tuple[str, tuple]:
    kind, geom = geometry(well)
    if kind == "circle":
        return kind, (geom[0], geom[1], geom[2] + amount)
    return kind, (geom[0] - amount, geom[1] - amount, geom[2] + amount, geom[3] + amount)


def diagonal_gradient(size: tuple[int, int]) -> np.ndarray:
    """0 at the upper-left corner, 1 at the lower-right (the render's own light direction)."""
    ys, xs = np.mgrid[0:size[1], 0:size[0]]
    ramp = (xs / max(1, size[0] - 1) + ys / max(1, size[1] - 1)) / 2.0
    return ramp.astype(np.float32)


def compose(layer: Image.Image, colour: list[int], alpha: np.ndarray) -> None:
    """Alpha-composite a flat tint over the layer, where alpha is a 0..255 float array."""
    alpha = np.clip(alpha, 0, 255).astype(np.uint8)
    if not alpha.any():
        return
    patch = np.zeros((layer.size[1], layer.size[0], 4), np.uint8)
    patch[..., 0], patch[..., 1], patch[..., 2] = colour
    patch[..., 3] = alpha
    layer.alpha_composite(Image.fromarray(patch, "RGBA"))


def draw_recess(layer: Image.Image, kind: str, geom: tuple, palette: dict, *, rim: int = RIM_GROW,
                wall: int = INNER_WALL, dark: bool = False) -> None:
    """One recessed well: raised rim, dark inner shadow (upper-left), void interior, light lip."""
    size = layer.size
    opening = shape_mask(size, kind, geom)
    outer = shape_mask(size, *grow({"circle" if kind == "circle" else "rect": geom}, rim))
    grad = diagonal_gradient(size)
    ## The raised rim band around the opening: dark where it faces up-left, catching light where it
    ## faces down-right, the same read the render's own bevels have.
    ## Seat the recess: a soft dark cast just outside the raised rim, so the well reads as sunk
    ## into the plate rather than drawn on it.
    band = np.clip(outer - opening, 0, 255)
    ## The raised rim: bright where it faces the light (down-right), shaded where it faces away.
    lift = band * (0.5 + 0.5 * grad)
    compose(layer, palette["rim_light"], lift)
    compose(layer, palette["shadow"], band * (1.0 - grad) * 0.55)
    ## The opening: a dark cut line, then the interior.
    compose(layer, palette["shadow"], opening * 0.7)
    kind_key = "circle" if kind == "circle" else "rect"
    inner_mask = shape_mask(size, *grow({kind_key: geom}, -RIM_INNER_GROW))
    ## The void interior: a touch darker at the top than the bottom, the way a shallow recess
    ## under a light from above reads.
    depth = (1.0 - grad * 0.45)[..., None] * (inner_mask / 255.0)[..., None]
    tint = np.array(palette["void"], np.float32) * depth
    patch = np.zeros((size[1], size[0], 4), np.uint8)
    patch[..., :3] = np.clip(tint, 0, 255).astype(np.uint8)
    patch[..., 3] = inner_mask.astype(np.uint8)
    layer.alpha_composite(Image.fromarray(patch, "RGBA"))
    if dark:
        return
    ## The inner wall: shaded on the upper-left, catching a thin light on the lower-right.
    inner = np.clip(opening - ndimage.binary_erosion(
        opening > 127, np.ones((wall, wall), bool)).astype(np.float32) * 255.0, 0, 255)
    compose(layer, palette["shadow"], inner * (1.0 - grad) * 0.8)
    compose(layer, palette["rim_light"], inner * grad * 0.45)


def sub_recesses(well: dict) -> list[tuple[str, tuple]]:
    """The sub-recesses a well carries, laid on the well's own pitch and margins."""
    if "rect" not in well:
        return []
    x0, y0, x1, y1 = well["rect"]
    out: list[tuple[str, tuple]] = []
    grid = well.get("grid")
    if grid:
        (sw, sh), (pw, ph), (cols, rows), (mx, my) = (grid["size"], grid["pitch"],
                                                      grid["count"], grid["margin"])
        for row in range(rows):
            for col in range(cols):
                sx = x0 + mx + col * pw
                sy = y0 + my + row * ph
                out.append(("rect", (sx, sy, sx + sw, sy + sh)))
    strip = well.get("strip")
    if strip:
        (sw, sh), count, (mx, my) = strip["size"], strip["count"], strip["margin"]
        span = (x1 - x0) - 2 * mx - sw
        pitch = span / max(1, count - 1)
        for index in range(count):
            sx = x0 + mx + index * pitch
            out.append(("rect", (int(round(sx)), y0 + my, int(round(sx)) + sw, y0 + my + sh)))
    return out


def _centre_inside(centre: tuple[float, float], pinned: dict) -> bool:
    """Does a point (a detected region's centre) sit inside a pinned well's rect?"""
    px0, py0, px1, py1 = reference_box(pinned)
    return px0 <= centre[0] <= px1 and py0 <= centre[1] <= py1


def region_centre(region: dict) -> tuple[float, float]:
    bx0, by0, bx1, by1 = region["box"]
    return (bx0 + bx1) / 2.0, (by0 + by1) / 2.0


def reference_box(well: dict) -> tuple[float, float, float, float]:
    kind, geom = geometry(well)
    if kind == "circle":
        return geom[0] - geom[2], geom[1] - geom[2], geom[0] + geom[2], geom[1] + geom[2]
    return float(geom[0]), float(geom[1]), float(geom[2]), float(geom[3])


def off_grid_wells(model_wells: list[dict], pinned: list[dict]) -> list[dict]:
    """The model's wells that are not where their pinned rect is: erase (and redraw) those only."""
    out: list[dict] = []
    for well in model_wells:
        cx, cy = region_centre(well)
        host = min(pinned, key=lambda p: abs((reference_box(p)[0] + reference_box(p)[2]) / 2.0 - cx)
                   + abs((reference_box(p)[1] + reference_box(p)[3]) / 2.0 - cy))
        if not _centre_inside((cx, cy), host):
            out.append(well)
    return out


def mirror_fill(plate: Image.Image, box: tuple[int, int]) -> Image.Image:
    """Fill a box wider than the plate by mirroring the plate across its own opaque bounds."""
    rgba = np.asarray(plate)
    rows_at, cols_at = np.where(rgba[..., 3] > 8)
    x0, x1 = int(cols_at.min()), int(cols_at.max()) + 1
    source = plate.crop((x0, 0, x1, plate.size[1]))
    canvas = Image.new("RGBA", box, (0, 0, 0, 0))
    step = source.size[0]
    for index, offset in enumerate(range(0, box[0], step)):
        tile = source if index % 2 == 0 else source.transpose(Image.FLIP_LEFT_RIGHT)
        canvas.alpha_composite(tile, (offset, 0))
    return canvas


def author(name: str, preview: bool) -> dict:
    box = BOXES[name]
    plan = PLAN.get(name)
    if plan is None:
        return {"name": name, "route": "render", "note": "render's own wells pass the lines-up QC"}
    master = Image.open(MASTERS / f"{name}.png").convert("RGBA")
    if master.size != box:
        raise SystemExit(f"{name}: master is {master.size}, expected {box[0]}x{box[1]}")
    rgba = np.asarray(master)
    rgb = rgba[..., :3].astype(np.uint8)
    opaque = rgba[..., 3] > 8
    palette = sample_palette(rgb, opaque)
    pinned = WELLS[name]
    model = dark_regions(master)
    targets = model if plan["erase"] == "all" else off_grid_wells(model, pinned)
    erase = np.zeros(opaque.shape, bool)
    for region in targets:
        assert region["area"] >= MIN_AREA
        erase |= region["mask"]
    erase = ndimage.binary_dilation(erase, ndimage.generate_binary_structure(2, 2),
                                    iterations=ERASE_GROW)
    erase &= opaque
    for well in pinned:
        if plan["draw"] == "all":
            pass
        elif not any(_centre_inside(region_centre(region), well) for region in model):
            continue
        kind, geom = geometry(well)
        grown = grow({kind: geom}, AUTHORED_FOOTPRINT)
        erase |= shape_mask(box, grown[0], grown[1]) > 127
    erase &= opaque
    filled = reflect_fill(rgb, opaque, erase)
    plate = Image.fromarray(np.dstack([filled, rgba[..., 3]]), "RGBA")
    if plan["fill"] == "mirror":
        plate = mirror_fill(plate, box)
    layer = Image.new("RGBA", box, (0, 0, 0, 0))
    drawn: list[str] = []
    for well in pinned:
        if plan["draw"] == "all" or not any(
                _centre_inside(region_centre(region), well) for region in model):
            kind, geom = geometry(well)
            for sub_kind, sub_geom in sub_recesses(well):
                draw_recess(layer, sub_kind, sub_geom, palette, rim=3, wall=4, dark=True)
            draw_recess(layer, kind, geom, palette)
            drawn.append(well["label"])
    result = plate.copy()
    result.alpha_composite(layer)
    AUTHORED.mkdir(parents=True, exist_ok=True)
    result.save(AUTHORED / f"{name}.png")
    if preview:
        result.convert("RGB").save(AUTHORED / f"{name}.preview.jpg", quality=84)
    return {"name": name, "route": "authored", "box": list(box), "palette": palette,
            "fill": plan["fill"], "erase": plan["erase"],
            "erased_px": int(erase.sum()), "erased_regions": len(targets),
            "authored_wells": drawn,
            "sub_recesses": sum(len(sub_recesses(w)) for w in pinned if w["label"] in drawn)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--json", default=str(STAGE / "ui" / "authored_d7.json"))
    args = parser.parse_args()
    if args.list or not (args.names or args.all):
        for name in BOXES:
            print(f"{name:24s} {BOXES[name][0]}x{BOXES[name][1]}  {len(WELLS[name])} well(s)")
        return 0
    names = list(BOXES) if args.all else args.names
    report = [author(name, args.preview) for name in names]
    for entry in report:
        if entry["route"] == "render":
            print(f"{entry['name']:24s} route=render ({entry['note']})")
            continue
        print(f"{entry['name']:24s} route=authored fill={entry['fill']} erase={entry['erase']}: "
              f"{entry['erased_px']} px over {entry['erased_regions']} region(s), "
              f"{len(entry['authored_wells'])} well(s) + {entry['sub_recesses']} sub-recess(es) "
              f"{entry['authored_wells']}")
    Path(args.json).write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(f"wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
