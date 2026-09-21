"""Split a multi-object FX render into one file per frame, before any keying.

The FX masters are grids: `fx_explosion` is FX_SPEC section 1.4's five frames on a 2 by 3
sheet, `fx_muzzle_flash` section 1.2's four, `fx_missile_trail` and `fx_shield_break`
(ASSET_EXPANSION_SPEC section 7), `fx_secondary_explosion` and `fx_mining_beam` (section
1.6's chip sparks) are one row of four, `fx_arc_spark` is 2 by 2 and `fx_laser_bolt`
section 1.1's two tiers are two rows. Keying such a master in one
`recraft/remove-background` call is the documented way to ship damaged art (AGENTS.md:
"Never key a panel that holds more than one object"; measured on `ship_apex_sheet`, the
matte deleted the bottom 299 px of one hull), so the order is split -> key each frame ->
ship the frames.

How a frame's box is chosen, and why (each rule is a measured failure of a simpler one):

1. **Objects are found by masking the ink, then cut from their own box.** The nominal grid
   is the grouping window only, so a burst that drifts off its cell's centre is still
   whole. Components are labelled on an 8x block reduction and re-measured at full
   resolution; block reduction is what makes it fast without scipy.
2. **Effect ink is a component; film grain is not.** These renders carry a starfield of
   30-50 grey specks in the void. A plain bounding box of `fx_mining_beam`'s first cell
   measured 365 x 1778 - almost the whole column - because a handful of specks sit at the
   cell's top and bottom edges; a mass percentile over the cell's ink is no better, since
   the specks are a few percent of it and drag the box out with them. A per-component area
   floor is what separates them: the bursts are 1280-26732 px components, the specks 3-64.
3. **A cell holding under 5% of the sheet's ink is not a frame.** `fx_explosion`'s sixth
   cell holds 0.5% (the spec's "last cell empty"); `fx_mining_beam`'s fourth holds 1.6%,
   which is the open gap in LOW_BACKLOG L52 (the spec states four frames, the render holds
   three bursts and one near-empty). A sheet that resolves to fewer frames than its spec
   states is reported and refused, never cut short.
4. **Every frame of a sheet shares one canvas, and the object is centred on it.** A
   sequence whose canvas changes per frame cannot be drawn to one size: the engine scales a
   sprite by its longest side (`Fx.scale_for`), so frames of different sizes would change
   scale as they play. The canvas is the sheet's largest frame plus a margin, and each
   frame's own ink box is centred on it, so relative size within the sequence survives.

Usage:
    py -3.14 staging/cut/split_fx.py --detect              # report every fx sheet
    py -3.14 staging/cut/split_fx.py --detect --page <dir> # + a numbered review page
    py -3.14 staging/cut/split_fx.py --cut --out <dir>     # write the frames
"""
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FX = ROOT / "vajb-orbit" / "assets" / "fx"

## Per sheet: the nominal grid and how many frames the spec states, in reading order
## (row by row). Counts: FX_SPEC 1.1 (two tiers), 1.2 (four), 1.4 (five of six cells),
## 1.6 (four chip sparks), 7.2 (arc) and ASSET_EXPANSION_SPEC section 7 for the strips it
## adds. Names follow ASSET_NAMING_SPEC section 4's closed vocabulary (`_f1`, `_f2`, ...).
PLAN: dict[str, dict] = {
    "fx_explosion": {"grid": (2, 3), "frames": 5},
    "fx_muzzle_flash": {"grid": (4, 1), "frames": 4},
    "fx_mining_beam": {"grid": (4, 1), "frames": 4},
    "fx_missile_trail": {"grid": (4, 1), "frames": 4},
    "fx_shield_break": {"grid": (4, 1), "frames": 4},
    "fx_secondary_explosion": {"grid": (4, 1), "frames": 4},
    "fx_arc_spark": {"grid": (2, 2), "frames": 4},
    "fx_laser_bolt": {"grid": (1, 2), "frames": 2},
    ## The 2026-09-21 re-cuts (LOW_BACKLOG L52/L57). They are staged outside the project, so a
    ## run against them passes `--dir staging/phase_g/fx`.
    "fx_mining_beam_v2": {"grid": (4, 1), "frames": 4},
    "fx_laser_bolt_v2": {"grid": (1, 2), "frames": 2},
}

## The four-frame cycles (owner instruction 2026-09-21: every FX needs at least four frames to
## animate). Each is a 2x2 sheet; `--tag` cuts them to the shipped `_f1.._f4` names.
for _cycle in (
    "fx_acid_burn_v2",
    "fx_smoke_plume_v2",
    "fx_dust_streak_v2",
    "fx_hull_critical_vignette_v2",
    "fx_anomaly_rift_v2",
    "fx_anomaly_shimmer_v2",
    "fx_anomaly_grave_glow_v2",
    "fx_bio_plasma_v2",
    "fx_cargo_pulse_v2",
    "fx_dash_charge_v2",
    "fx_ember_pulse_v2",
    "fx_ember_ring_v2",
    "fx_ember_ring_alt_v2",
    "fx_emp_arc_v2",
    "fx_engine_trail_v2",
    "fx_jump_portal_v2",
    "fx_lock_channel_v2",
    "fx_mine_v2",
    "fx_repair_pulse_v2",
    "fx_shield_ripple_v2",
    "fx_tractor_beam_v2",
    "fx_laser_bolt_v3",
):
    PLAN.setdefault(_cycle, {"grid": (2, 2), "frames": 4})


## A pixel this grey distance from the border median is not background.
INK_TOL = 14.0
## Side of the block reduction the components are labelled on.
BLOCK = 8
## A block counts as ink at this many pixels, so two effects are not joined by a stray dot.
MIN_BLOCK_INK = 3
## A component smaller than this is grain. The floor is also scaled against the cell's own
## biggest component, because the specks are 3-64 px and a fixed number either keeps them
## (`fx_mining_beam`'s first cell grew to 1263 px of empty black on a 44 px speck) or
## empties a sparse frame.
MIN_AREA = 80
MIN_AREA_SHARE = 0.05
## The fallback floor for a spec'd frame whose sparks are all tiny (see `sheet`).
MIN_AREA_SOFT = 12
## A cell holding fewer ink pixels than this carries no effect at all (the release's fourth
## chip-spark frame is nearly empty by design, so this floor is deliberately tiny: the *spec*
## owns the frame count, this only tells an empty cell from a sparse one).
MIN_CELL_INK = 100
## The shared canvas is the sheet's largest frame grown by this much on every side.
PAD_SHARE = 0.06
## How far the object mask is grown past its own ink, in pixels.
MASK_GROW = 16
ROUND = 8
MIN_CANVAS = 64


def background_value(gray: np.ndarray, ring: int = 16) -> float:
    edges = np.concatenate([gray[:ring, :].ravel(), gray[-ring:, :].ravel(),
                            gray[:, :ring].ravel(), gray[:, -ring:].ravel()])
    return float(np.median(edges))


def ink_mask(gray: np.ndarray) -> np.ndarray:
    bg = background_value(gray)
    contrast = float(np.percentile(gray, 99.9) - bg)
    return np.abs(gray - bg) > max(INK_TOL, 0.02 * contrast)


def _labels(blocks: np.ndarray) -> np.ndarray:
    """8-connected labels for a small boolean grid, numpy-only (no scipy in this venv)."""
    height, width = blocks.shape
    out = np.zeros((height, width), np.int32)
    current = 0
    for y0 in range(height):
        for x0 in range(width):
            if not blocks[y0, x0] or out[y0, x0]:
                continue
            current += 1
            out[y0, x0] = current
            queue = deque([(y0, x0)])
            while queue:
                y, x = queue.popleft()
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < height and 0 <= nx < width \
                                and blocks[ny, nx] and not out[ny, nx]:
                            out[ny, nx] = current
                            queue.append((ny, nx))
    return out


def components(image: Image.Image) -> list[dict]:
    """Every ink component on the render: full-resolution box, ink area, centre."""
    gray = np.asarray(image.convert("L")).astype(np.float32)
    mask = ink_mask(gray)
    height, width = mask.shape
    rows = height // BLOCK
    cols = width // BLOCK
    counts = mask[: rows * BLOCK, : cols * BLOCK].reshape(
        rows, BLOCK, cols, BLOCK).sum(axis=(1, 3))
    labels = _labels(counts >= MIN_BLOCK_INK)
    if labels.max() == 0:
        return []
    expanded = np.repeat(np.repeat(labels, BLOCK, axis=0), BLOCK, axis=1)
    area = np.bincount(expanded.ravel(),
                       weights=mask[: expanded.shape[0], : expanded.shape[1]].ravel())
    found: list[dict] = []
    for index in range(1, len(area)):
        if area[index] <= 0:
            continue
        cells = np.argwhere(labels == index)
        y0, x0 = cells.min(axis=0)
        y1, x1 = cells.max(axis=0) + 1
        top, bottom = int(y0) * BLOCK, min(int(y1) * BLOCK, height)
        left, right = int(x0) * BLOCK, min(int(x1) * BLOCK, width)
        own = mask[top:bottom, left:right]
        rows_ink = np.where(own.any(axis=1))[0]
        cols_ink = np.where(own.any(axis=0))[0]
        found.append({"box": [left + int(cols_ink[0]), top + int(rows_ink[0]),
                              left + int(cols_ink[-1]) + 1, top + int(rows_ink[-1]) + 1],
                      "px": float(area[index])})
    return found


def sheet(name: str, directory: Path | None = None) -> dict:
    path = (directory or FX) / f"{name}.png"
    image = Image.open(path)
    plane = PLAN[name]
    cols, rows = plane["grid"]
    width, height = image.size
    found = components(image)
    grid: list[list[dict]] = [[[] for _ in range(cols)] for _ in range(rows)]
    for item in found:
        box = item["box"]
        shares = np.zeros((rows, cols))
        for r in range(rows):
            for c in range(cols):
                window = [round(c * width / cols), round(r * height / rows),
                          round((c + 1) * width / cols), round((r + 1) * height / rows)]
                shares[r, c] = max(0, min(box[2], window[2]) - max(box[0], window[0])) * \
                    max(0, min(box[3], window[3]) - max(box[1], window[1]))
        r, c = np.unravel_index(int(np.argmax(shares)), shares.shape)
        grid[int(r)][int(c)].append(item)
    cells: list[dict | None] = []
    floors: list[float] = []
    for r in range(rows):
        for c in range(cols):
            items = grid[r][c]
            if not items:
                cells.append(None)
                floors.append(0.0)
                continue
            floor = max(MIN_AREA, max(o["px"] for o in items) * MIN_AREA_SHARE)
            keep = [o for o in items if o["px"] >= floor]
            if sum(o["px"] for o in keep) < MIN_CELL_INK:
                ## A spec'd frame whose sparks are each smaller than the grain floor (the mining
                ## sheet's fourth release frame is "nearly empty" by design, FX_SPEC 1.6) would
                ## read as an empty cell. Retry it with a floor that only rejects single-pixel
                ## noise, so the frame is represented by what it actually holds.
                soft = max(MIN_AREA_SOFT, max(o["px"] for o in items) * 0.02)
                keep = [o for o in items if o["px"] >= soft]
            floors.append(floor)
            if not keep:
                cells.append(None)
                continue
            box = [min(o["box"][0] for o in keep), min(o["box"][1] for o in keep),
                   max(o["box"][2] for o in keep), max(o["box"][3] for o in keep)]
            cells.append({"cell": [r, c],
                          "window": [round(c * width / cols), round(r * height / rows),
                                     round((c + 1) * width / cols),
                                     round((r + 1) * height / rows)],
                          "box": box, "px": sum(o["px"] for o in keep),
                          "parts": len(keep), "grain": len(items) - len(keep),
                          "floor": int(floor)})
    ## The spec owns the frame count: take the first `frames` cells in reading order that hold
    ## ink. A cell past the count is not a frame (explosion's sixth cell is the spec's "last cell
    ## empty"), and a cell inside the count with almost no ink is still that frame - the mining
    ## sheet's fourth release frame is nearly empty by design (FX_SPEC 1.6).
    ordered = [cell for cell in cells if cell]
    used = [cell for cell in ordered if cell["px"] >= MIN_CELL_INK][:plane["frames"]]
    for cell in ordered:
        if cell not in used:
            cell["dropped"] = True
    return {"name": name, "path": path, "size": [width, height], "grid": [cols, rows],
            "cells": cells, "used": used, "want": plane["frames"],
            "floor": int(min(f for f in floors if f) if any(floors) else 0)}


def canvas_for(target: dict) -> tuple[int, int]:
    widest = max(c["box"][2] - c["box"][0] for c in target["used"])
    tallest = max(c["box"][3] - c["box"][1] for c in target["used"])
    return (max(MIN_CANVAS, int(np.ceil(widest * (1 + 2 * PAD_SHARE) / ROUND)) * ROUND),
            max(MIN_CANVAS, int(np.ceil(tallest * (1 + 2 * PAD_SHARE) / ROUND)) * ROUND))


def object_mask(gray: np.ndarray, tol: float = 14.0, block: int = 8, min_ink: int = 4,
                grow: int = 12) -> np.ndarray:
    """The frame's own object, grown a little, as a mask.

    The generator draws a faint dark card behind some effects (measured on `fx_lock_channel`'s
    and `fx_dust_streak`'s cycle frames: a rectangle a few grey levels above the void). No key
    can tell that card from background - the paid matte kept it and the luminance key gave it a
    few percent of alpha, and both read as a grey box on magenta. Masking to the object's own ink
    removes it at the source, and the mask is dilated so an anti-aliased edge or a soft halo
    skirt is never clipped.
    """
    bg = background_value(gray)
    contrast = float(np.percentile(gray, 99.9) - bg)
    mask = np.abs(gray - bg) > max(tol, 0.01 * contrast)
    rows = gray.shape[0] // block
    cols = gray.shape[1] // block
    blocks = mask[: rows * block, : cols * block].reshape(
        rows, block, cols, block).sum(axis=(1, 3)) >= min_ink
    grown = blocks.copy()
    for _ in range(max(1, grow // block)):
        grown = grown | np.roll(grown, 1, 0) | np.roll(grown, -1, 0) \
            | np.roll(grown, 1, 1) | np.roll(grown, -1, 1)
    out = np.zeros_like(mask)
    out[: rows * block, : cols * block] = np.repeat(np.repeat(grown, block, axis=0),
                                                    block, axis=1)
    return out


def cut(target: dict, cell: dict, canvas: tuple[int, int]) -> Image.Image:
    """Crop the cell's own box, mask to the object, centre it on the shared canvas."""
    image = Image.open(target["path"]).convert("RGB")
    left, top, right, bottom = cell["box"]
    pad = max(4, int(round(PAD_SHARE * max(right - left, bottom - top))))
    left, top = max(0, left - pad), max(0, top - pad)
    right, bottom = min(image.size[0], right + pad), min(image.size[1], bottom + pad)
    pixels = np.asarray(image).copy()
    keep = np.zeros(pixels.shape[:2], bool)
    keep[top:bottom, left:right] = True
    gray = np.asarray(image.convert("L")).astype(np.float32)
    keep &= object_mask(gray, grow=MASK_GROW)
    pixels[~keep] = 0
    patch = Image.fromarray(pixels[top:bottom, left:right], "RGB")
    frame = Image.new("RGB", canvas, (0, 0, 0))
    frame.paste(patch, ((canvas[0] - patch.width) // 2, (canvas[1] - patch.height) // 2))
    return frame


def page(target: dict, out: Path) -> None:
    image = Image.open(target["path"]).convert("RGB")
    draw = ImageDraw.Draw(image)
    cols, rows = target["grid"]
    for col in range(1, cols):
        x = round(col * image.size[0] / cols)
        draw.line([(x, 0), (x, image.size[1])], fill=(60, 70, 80), width=2)
    for row in range(1, rows):
        y = round(row * image.size[1] / rows)
        draw.line([(0, y), (image.size[0], y)], fill=(60, 70, 80), width=2)
    for cell in target["cells"]:
        if not cell:
            continue
        colour = (90, 90, 90) if cell.get("dropped") else (74, 232, 108)
        draw.rectangle(cell["box"], outline=colour, width=6)
    for index, cell in enumerate(target["used"], 1):
        draw.text((cell["box"][0] + 12, cell["box"][1] + 12), f"{index}",
                  fill=(74, 232, 108))
    image.thumbnail((900, 900), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, quality=80)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--detect", action="store_true")
    parser.add_argument("--cut", action="store_true")
    parser.add_argument("--out", default="")
    parser.add_argument("--only", default="", help="comma-separated names to narrow the run")
    parser.add_argument("--dir", default="", help="source directory (default vajb-orbit/assets/fx)")
    parser.add_argument("--tag", action="store_true",
                        help="name the frames after the sheet, not after a name it replaces")
    parser.add_argument("--page", default="")
    parser.add_argument("--allow-short", action="store_true",
                        help="cut the frames a sheet does resolve, reporting the shortfall")
    parser.add_argument("--json", default="")
    args = parser.parse_args()

    wanted = [n.strip() for n in args.only.split(",") if n.strip()] or sorted(PLAN)
    report: dict[str, dict] = {}
    source_dir = Path(args.dir) if args.dir else None
    for name in wanted:
        if not ((source_dir or FX) / f"{name}.png").is_file():
            print(f"{name:24s} missing (its render is staged elsewhere - pass --dir)")
            continue
        target = sheet(name, source_dir)
        used = target["used"]
        canvas = canvas_for(target)
        flag = "" if len(used) == target["want"] else f"   <-- spec states {target['want']}"
        print(f"{target['name']:24s} grid={target['grid'][0]}x{target['grid'][1]}"
              f" frames={len(used)} canvas={canvas[0]}x{canvas[1]}"
              f" area_floor={target['floor']}{flag}")
        for index, cell in enumerate(used, 1):
            box = cell["box"]
            print(f"    f{index}: cell={cell['cell']} {box[2] - box[0]}x{box[3] - box[1]}"
                  f" at {box[:2]} ink={int(cell['px'])} parts={cell['parts']}")
        for cell in target["cells"]:
            if cell and cell.get("dropped"):
                print(f"    dropped cell={cell['cell']} ink={int(cell['px'])}"
                      f" parts={cell['parts']} (under the cell floor)")
        report[name] = {"grid": target["grid"], "found": len(used), "want": target["want"],
                        "canvas": list(canvas), "boxes": [c["box"] for c in used],
                        "dropped": [c["box"] for c in target["cells"]
                                    if c and c.get("dropped")]}
        if args.page:
            page(target, Path(args.page) / f"{name}.jpg")
        if args.cut:
            if len(used) != target["want"] and not args.allow_short:
                print(f"   refused: {name} resolves to {len(used)} frame(s), "
                      f"not {target['want']} (--allow-short cuts what is there)")
                continue
            if len(used) != target["want"]:
                print(f"   SHORT: {name} cuts {len(used)} of {target['want']} frame(s); "
                      f"the render holds no fourth burst (LOW_BACKLOG L52)")
            out = Path(args.out) if args.out else ROOT / "staging" / "cut" / "_fx_frames"
            folder = out / name
            folder.mkdir(parents=True, exist_ok=True)
            stem = name[:-3] if args.tag and name[-3:] in ("_v2", "_v3") else name
            for index, cell in enumerate(used, 1):
                cut(target, cell, canvas).save(folder / f"{stem}_f{index}.png")
            print(f"   cut {len(used)} frame(s) -> {folder}")
    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
