"""Rebuild a panel run the correct way: cut each object out of the render first, key it second.

The first pass keyed the whole panel and then cut it on a blind 2x2 grid, and both steps are
wrong on real renders:

- **A panel is not one subject.** `recraft/remove-background` picks the strongest object and can
  drop the rest: on `ship_apex_sheet` it deleted the bottom 299 px of the bottom-right hull
  (ink box height 933 px, keyed alpha height 634 px, alpha fill 17 % against 50-70 % elsewhere),
  so `ship_apex_side` shipped with its tail missing.
- **Objects ignore the quadrant midlines.** The apex and sibelon sheets each have a hull whose ink
  starts left of x = 1024 and continues to x = 1121: a grid cut truncates it.

`panels.py` finds every object on the render and groups the ink into the four cells by pixel mass,
so each cell's box covers its own object whatever the midline says. This script runs the rest of
the order for one run: crop each cell (neighbours blacked out) -> key each crop on its own
(1 credit, cached) -> trim and centre -> verify that the keyed alpha box still matches the ink box.

Usage:
    py -3.14 staging/phase_g/refit_panels.py ship_apex_sheet --dry-run
    py -3.14 staging/phase_g/refit_panels.py ship_apex_sheet ship_sibelon_sheet
    py -3.14 staging/phase_g/refit_panels.py ship_apex_sheet --verify-only
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import panels
import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
TOLERANCE_PX = 4
TOLERANCE_SHARE = 0.02


def restore_flare(keyed: Image.Image, crop: Image.Image) -> Image.Image:
    """Put back the engine flame the paid matte trimmed off the nose or tail.

    recraft reads the ember plume spilling past a hull as background and trims it, which is the
    honest call for soft haze but wrong when the plume is the outermost part of the silhouette
    (measured on the vanguard: the dropped band's mean colour is (98, 41, 25) - ember, and a third
    of it is bright). The rule is component-wise, not pixel-wise: an ink component is restored
    **whole** when it holds at least one unambiguously bright or ember-toned pixel and it lies
    near the kept matte, so a flame keeps its own dim halo while a patch of bare haze (no bright
    pixel anywhere in it) stays trimmed - the boundary the matte is trusted for.
    """
    pixels = np.asarray(keyed.convert("RGBA")).copy()
    alpha = pixels[:, :, 3]
    rgb = np.asarray(crop.convert("RGB")).astype(np.int16)
    gray = rgb.mean(axis=2).astype(np.float32)
    ink = panels.ink_mask(gray)
    matte = alpha > 8
    ember = (rgb[:, :, 0] > 60) & (rgb[:, :, 0] > rgb[:, :, 2] + 30)
    bright = gray > max(90.0, panels.background_value(gray) + 60)
    strong = ember | bright
    near = ndimage.binary_dilation(matte, np.ones((49, 49), bool))
    labels, count = ndimage.label(ink, np.ones((3, 3), int))
    restore = np.zeros_like(ink)
    for index in range(1, count + 1):
        component = labels == index
        if not (component & strong).any() or not (component & near).any():
            continue
        restore |= component
    restore &= ~matte
    if not restore.any():
        return keyed
    pixels[:, :, 3] = np.where(restore, 255, alpha)
    print(f"    restored {int(restore.sum())} flare px the matte had trimmed")
    return Image.fromarray(pixels, "RGBA")


def duplicate_views(paths: dict[str, Path], threshold: float = 0.80) -> list[str]:
    """Flag two cuts that share a silhouette.

    The model's recurring failure on a 2x2 sheet is to draw the **front a second time** in the
    bottom-right cell and never a rear: `ship_miner_back` scored 0.91 against `ship_miner_front`,
    `ship_sibelon_back` 0.83, `ship_trader_back` 0.91, and the swarmer's fourth cell was a
    duplicate front before that. A genuine front/rear pair of a boxy hull lands near 0.74-0.78, so
    the line is drawn at 0.80 — above it the pair is reported, never silently shipped.

    The signature keeps each cut's **aspect ratio** (the alpha box is scaled to fit a 64x64 cell,
    not stretched to fill it): a boxy hull's front and side views are both "a rounded rectangle"
    once the aspect is thrown away, which is what made the trader's honest front/side pair read as
    a duplicate at 0.82.
    """
    from itertools import combinations
    import numpy as _np

    def signature(path: Path) -> object:
        alpha = Image.open(path).convert("RGBA").getchannel("A")
        box = alpha.point(lambda v: 255 if v > 8 else 0).getbbox()
        if box:
            alpha = alpha.crop(box)
        alpha.thumbnail((64, 64), Image.BILINEAR)
        canvas = Image.new("L", (64, 64), 0)
        canvas.paste(alpha, ((64 - alpha.size[0]) // 2, (64 - alpha.size[1]) // 2))
        return _np.asarray(canvas).astype(_np.float32) > 127

    signatures: dict[str, object] = {}
    for name, path in paths.items():
        if not Path(path).exists():
            continue
        signatures[name] = signature(Path(path))
    flagged: list[str] = []
    for left, right in combinations(sorted(signatures), 2):
        a, b = signatures[left], signatures[right]
        union = float((a | b).sum())
        if union and float((a & b).sum()) / union > threshold:
            flagged.append(f"{left}/{right}={float((a & b).sum()) / union:.2f}")
    return flagged


def cell_plan(spec: dict) -> list[tuple[int, str, int]]:
    if spec.get("cells"):
        return [(int(i), str(name), int(rot)) for i, name, rot in spec["cells"]]
    return [(index, str(name), 0) for index, name in enumerate(spec.get("cuts") or [])]


def verify(ink: tuple[int, int, int, int], alpha: np.ndarray) -> tuple[bool, str]:
    rows = np.where((alpha > 8).any(axis=1))[0]
    cols = np.where((alpha > 8).any(axis=0))[0]
    if not len(rows) or not len(cols):
        return False, "alpha empty"
    ink_w, ink_h = ink[2] - ink[0], ink[3] - ink[1]
    got_w, got_h = int(cols[-1] - cols[0] + 1), int(rows[-1] - rows[0] + 1)
    ok_w = got_w >= ink_w - max(TOLERANCE_PX, ink_w * TOLERANCE_SHARE)
    ok_h = got_h >= ink_h - max(TOLERANCE_PX, ink_h * TOLERANCE_SHARE)
    return (ok_w and ok_h), f"ink {ink_w}x{ink_h} -> alpha {got_w}x{got_h}"


def refit(run_id: str, dry: bool, verify_only: bool) -> bool:
    spec = wave_g.RUNS[run_id]
    master = wave_g.find_master(spec)
    if master is None:
        print(f"[{run_id}] NO MASTER FOUND")
        return False
    sheet = Image.open(master)
    cols, rows = spec.get("grid", [2, 2])
    groups = panels.cells(sheet, cols, rows)
    by_quadrant = {(g["quadrant"][0], g["quadrant"][1]): g for g in groups}
    print(f"[{run_id}] {master.name}: {len(groups)} cell(s) found on a {cols}x{rows} grid")

    cells_dir = STAGE / spec["family"] / "_cells" / master.parent.name
    cells_dir.mkdir(parents=True, exist_ok=True)
    todo: list[Path] = []
    plan = cell_plan(spec)
    for index, name, _rotate in plan:
        group = by_quadrant.get((index // cols, index % cols))
        if group is None:
            print(f"  cell{index} ({name}): no object found in that grid cell, skipped")
            continue
        crop = cells_dir / f"{name}.png"
        if not crop.exists():
            panels.cut_object(sheet, group).convert("RGB").save(crop)
        todo.append(crop)
        print(f"  {name}: ink box {group['box']} -> {crop.name} {Image.open(crop).size}")

    if dry:
        print(f"[{run_id}] dry run: {len(todo)} crop(s) staged, nothing keyed or written")
        return True
    if verify_only:
        todo = [p for p in todo if (p.with_name(f"{p.stem}-keyed.png")).exists()]

    missing = [p for p in todo if not p.with_name(f"{p.stem}-keyed.png").exists()]
    if missing:
        cmd = [sys.executable, str(STAGE / "key_new.py")] + [str(p) for p in missing]
        print(f"  keying {len(missing)} crop(s): {' '.join(p.name for p in missing)}")
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                              errors="replace")
        tail = [line for line in (proc.stdout or "").splitlines() if "keyed" in line or "done" in line]
        print("  " + "\n  ".join(tail[-4:]))
        if proc.returncode != 0:
            print(f"  keying failed: {(proc.stderr or '')[-300:]}")
            return False

    ok = True
    for index, name, rotate in plan:
        group = by_quadrant.get((index // cols, index % cols))
        keyed = cells_dir / f"{name}-keyed.png"
        if group is None or not keyed.exists():
            continue
        alpha = np.asarray(Image.open(keyed).convert("RGBA").getchannel("A"))
        passed, detail = verify(group["box"], alpha)
        print(f"  {'PASS' if passed else 'FAIL'} {name}: {detail}")
        image = Image.open(keyed).convert("RGBA")
        if not passed:
            ## A miss is almost always the matte trimming an engine flare off the object; restore
            ## the measured flare and re-check rather than shipping a hull with its glow cut off.
            image = restore_flare(image, Image.open(cells_dir / f"{name}.png"))
            alpha = np.asarray(image.getchannel("A"))
            passed, detail = verify(group["box"], alpha)
            print(f"    re-verify: {'PASS' if passed else 'FAIL'} {detail}")
            if not passed:
                print(f"    {name}: still short after restore, needs an eye")
        ok = ok and passed
        if rotate:
            image = image.rotate(rotate, expand=True)
        ## The pad is the lane's sprite hygiene (`trim_centre`'s own 4 % default). A panel plate
        ## whose pinned master box is what the code mounts to has no room for it: the pad is inside
        ## the fit, so it costs the plate that share of its box on both axes and the code-drawn
        ## wells land off the art. A run that pins its own box sets `pad_share` (the D7-A1 flat
        ## plates use 0.0, which `trim_centre` floors at 8 px).
        image = wave_g.trim_centre(image, spec.get("pad_share", 0.04))
        dest = STAGE / spec["family"] / f"{name}.png"
        image.save(dest)
        print(f"    wrote {dest.name} {image.size}")

    written = {name: STAGE / spec["family"] / f"{name}.png" for _i, name, _r in plan}
    ## The duplicate-view check is for a hull sheet that repeats a view. It is off for panels
    ## whose cells are deliberately identical in silhouette (the D6 seven-segment cells are all the
    ## same plate rectangle, so every pair would read as a duplicate), and it is only meaningful
    ## when the spec asks for it.
    if spec.get("dup_check", True):
        flagged = duplicate_views(written)
        if flagged:
            ok = False
            print(f"  FAIL duplicate view(s) among the cuts: {', '.join(flagged)}")
            print("       a 2x2 sheet that repeats a view needs its own *_back_single run")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("runs", nargs="*")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    if not args.runs:
        print(__doc__)
        return 1
    results = [refit(run_id, args.dry_run, args.verify_only) for run_id in args.runs]
    return 0 if all(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
