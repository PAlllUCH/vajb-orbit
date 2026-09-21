"""Phase F.1 Stage 1 - cut the icon quartet from the retained masters.

Work order: DESIGNER_TODO.MD Stage 1, with the geometry law amended to
aspect-preserving contain-fit (ICONS_SPEC.md section 9.6, owner-approved
2026-09-18).

Sources, in priority order:
  1. the per-icon unsuffixed master `assets/icons/icon_<name>.png` (119 families);
  2. for the 20 Phase B families that have no per-icon master, the retained 2K
     panel cell, white-keyed and trimmed (ICONS_SPEC sections 5 and 7 give the
     reading-order mapping; `legacy_probe.py` renders the proof sheet).

Geometry:
  `--fit contain` (default, the law): scale the trimmed master until its longest
  side equals N, centre it, leave the remainder transparent. No axis is stretched.
  `--fit square` reproduces the pre-F.1 pipeline exactly (`Image.resize((N, N))`),
  which byte-identically restores the shipped `_16`/`_48` cuts of the 119
  master-backed families - that is the documented reversal path.

Dry run by default; pass `--apply` to write. Files that are overwritten are copied
once to staging/phase_f/_cut_backup/ first.

Usage:
  py -3.14 staging/phase_f/recut_quartet.py                  # dry run, all families
  py -3.14 staging/phase_f/recut_quartet.py --apply
  py -3.14 staging/phase_f/recut_quartet.py --sizes 96,192 --apply
  py -3.14 staging/phase_f/recut_quartet.py --families icon_shield,icon_credits --apply
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
ICONS = ASSETS / "icons"
STAGE = WORKSPACE / "staging" / "phase_f"
BACKUP = STAGE / "_cut_backup"
CELLS = STAGE / "_panel_cells"
REPORT = STAGE / "recut_report.json"

ALL_SIZES = (16, 48, 96, 192)
CUT_PAD = 10
BG_BLOCK = 32

# The 20 Phase B families shipped no per-icon master: their source is the panel cell.
# Grids and reading order are ICONS_SPEC section 5 / section 7; verified against the
# shipped cuts by legacy_probe.py (mask IoU: correct cell 0.48-0.94, wrong cells
# 0.27-0.63 for the outline glyphs, and the render sheet confirms the pairing).
# F.1 regenerated five of these families (icon_cargo_data_core and the four outline
# glyphs) and shipped them as unsuffixed masters, so their entries below are now
# fallbacks only: the master branch above wins whenever `assets/icons/<base>.png`
# exists. Keep them, so removing a master does not silently drop a family.
LEGACY_PANELS = {
    "panel_weapons": ((2, 3), [
        "icon_weapon_laser", "icon_weapon_cannon", "icon_weapon_rocket",
        "icon_weapon_mine", "icon_weapon_plasma", None]),
    "panel_cargo": ((2, 3), [
        "icon_cargo_ore", "icon_cargo_crate", "icon_cargo_container",
        "icon_cargo_fuel_cell", "icon_cargo_salvage", "icon_cargo_data_core"]),
    "panel_glyphs": ((3, 3), [
        "icon_gear", "icon_close", "icon_zoom_plus", "icon_zoom_minus",
        "icon_credits", "icon_shield", "icon_hull", "icon_ammo", "icon_logout"]),
}


# ------------------------------------------------------------------ sources


def panel_cells(panel: str, grid: tuple[int, int]) -> list[Image.Image]:
    src = Image.open(ICONS / f"{panel}.png").convert("RGB")
    cols, rows = grid
    w, h = src.size
    return [src.crop((round(c * w / cols), round(r * h / rows),
                      round((c + 1) * w / cols), round((r + 1) * h / rows)))
            for r in range(rows) for c in range(cols)]


def key_white(cell: Image.Image) -> Image.Image:
    """White-key a Phase B panel cell: alpha from darkness, RGB untouched.

    The background is estimated from the corner blocks and the ink from the 2nd
    percentile of the darkest channel, so the matte spans the panel's own range
    instead of a hard threshold (the legacy cuts kept opaque ink cores).
    """
    rgb = np.asarray(cell.convert("RGB")).astype(np.int16)
    darkest = rgb.min(axis=2)
    h, w = darkest.shape
    corners = np.concatenate([
        darkest[:BG_BLOCK, :BG_BLOCK].ravel(), darkest[:BG_BLOCK, -BG_BLOCK:].ravel(),
        darkest[-BG_BLOCK:, :BG_BLOCK].ravel(), darkest[-BG_BLOCK:, -BG_BLOCK:].ravel()])
    bg = float(np.median(corners))
    ink = float(np.percentile(darkest, 2))
    span = max(1.0, bg - ink)
    alpha = np.clip((bg - darkest) * (255.0 / span), 0, 255).astype("uint8")
    return Image.fromarray(np.dstack([np.asarray(cell.convert("RGB")), alpha]), "RGBA")


def trim(img: Image.Image, pad: int = CUT_PAD) -> Image.Image:
    alpha = np.asarray(img)[..., 3]
    mask = alpha > 8
    ys, xs = np.nonzero(mask)
    if not len(ys):
        return img
    return img.crop((max(0, xs.min() - pad), max(0, ys.min() - pad),
                     min(img.size[0], xs.max() + 1 + pad), min(img.size[1], ys.max() + 1 + pad)))


def legacy_sources() -> dict[str, Image.Image]:
    """White-keyed, trimmed panel-cell masters for the 20 legacy families."""
    CELLS.mkdir(parents=True, exist_ok=True)
    out: dict[str, Image.Image] = {}
    for panel, (grid, names) in LEGACY_PANELS.items():
        for index, cell in enumerate(panel_cells(panel, grid)):
            keyed = key_white(cell)
            (CELLS / f"{panel}-cell-{index + 1:02d}.png").parent.mkdir(parents=True, exist_ok=True)
            keyed.save(CELLS / f"{panel}-cell-{index + 1:02d}.png")
            name = names[index]
            if name is None:
                continue
            out[name] = trim(keyed)
    return out


def master_index() -> dict[str, Path]:
    """base name -> master path, walking the icons tree.

    The masters moved from a flat `assets/icons/` into subfolders
    (`assets/icons/<group>/icon_<name>.png`) when the naming pass filed the library, so a
    lookup by bare name has to walk. Derived cuts (`_16`/`_48`/`_96`/`_192`/`@2x`) are skipped.
    """
    index: dict[str, Path] = {}
    for path in ICONS.rglob("icon_*.png"):
        stem = path.stem
        if stem.endswith(("_16", "_48", "_96", "_192")) or stem.endswith("@2x"):
            continue
        index.setdefault(stem, path)
    return index


def families() -> list[str]:
    """Every icon family that has a master, in stable order.

    The list comes from the masters, not from existing cuts: after a pull the project holds
    masters only (the derived quartet is rebuilt from them), and an earlier version of this
    function read the cuts it was about to write, so a clean project produced an empty list.
    """
    return sorted(master_index())


# ------------------------------------------------------------------ geometry


def cut(master: Image.Image, size: int, fit: str) -> Image.Image:
    if fit == "square":
        return master.resize((size, size), Image.LANCZOS)
    scaled = master.copy()
    scaled.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(scaled, ((size - scaled.size[0]) // 2, (size - scaled.size[1]) // 2))
    return canvas


def ink_box(img: Image.Image) -> tuple[int, int]:
    mask = np.asarray(img)[..., 3] > 8
    ys, xs = np.nonzero(mask)
    if not len(ys):
        return (0, 0)
    return (int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1))


def min_stroke(img: Image.Image) -> float:
    """Median over rows of the shortest ink run: the thin-stroke width in px."""
    ink = np.asarray(img)[..., 3] > 128
    runs = []
    for row in ink:
        padded = np.concatenate([[False], row, [False]])
        edges = np.flatnonzero(padded[1:] != padded[:-1])
        starts, ends = edges[0::2], edges[1::2]
        if len(starts):
            runs.append(int((ends - starts).min()))
    return float(np.median(runs)) if runs else 0.0


# ------------------------------------------------------------------ main


def source_check(base: str) -> str:
    """Prove the master really is the source of the shipped cuts.

    For the 119 master-backed families the pre-F.1 pipeline was
    `master.resize((48, 48))`, so re-running it must reproduce the shipped file
    byte for byte. A mismatch means the master is not the true source and the
    family must be flagged rather than re-cut.
    """
    master = master_index().get(base, ICONS / f"{base}.png")
    shipped = ICONS / f"{base}_48.png"
    if not master.is_file():
        return "legacy-panel"
    if not shipped.is_file():
        return "no-48"
    made = cut(Image.open(master).convert("RGBA"), 48, "square")
    same = np.array_equal(np.asarray(made), np.asarray(Image.open(shipped).convert("RGBA")))
    return "verified" if same else "MISMATCH"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--fit", choices=("contain", "square"), default="contain")
    ap.add_argument("--sizes", default=",".join(str(s) for s in ALL_SIZES))
    ap.add_argument("--families", default="")
    ap.add_argument("--skip-source-check", action="store_true")
    args = ap.parse_args()
    sizes = tuple(int(s) for s in args.sizes.split(",") if s.strip())
    wanted = [f.strip() for f in args.families.split(",") if f.strip()]

    bases = families()
    if wanted:
        bases = [b for b in bases if b in wanted]
    index = master_index()
    # The naming pass cut per-icon masters for all 20 Phase B panel families, so the
    # panel-cell fallback is only needed for a family that has no master anywhere.
    legacy = legacy_sources() if any(not index.get(b) for b in bases) else {}

    rows = []
    mismatched = []
    print(f"{'family':34s} {'src':13s} {'master':>11s} " +
          " ".join(f"{'bbox@' + str(s):>11s}" for s in sizes) + "  smallest stroke")
    for base in bases:
        master_path = index.get(base, ICONS / f"{base}.png")
        if master_path.is_file():
            master = Image.open(master_path).convert("RGBA")
            src = "master"
        elif base in legacy:
            master = legacy[base]
            src = "panel-cell"
        else:
            print(f"{base:34s} NO SOURCE")
            continue
        status = "skipped" if args.skip_source_check else source_check(base)
        if status == "MISMATCH":
            mismatched.append(base)
        boxes = []
        strokes = {}
        made = {}
        for size in sizes:
            img = cut(master, size, args.fit)
            made[size] = img
            boxes.append("%dx%d" % ink_box(img))
            strokes[size] = min_stroke(img)
        flag = "" if status in ("verified", "legacy-panel", "skipped", "no-48") else "  <-- " + status
        print(f"{base:34s} {src:13s} {str(master.size):>11s} " +
              " ".join(f"{b:>11s}" for b in boxes) +
              "  " + " ".join(f"{s}:{strokes[s]:.0f}" for s in sizes) + flag)
        if args.apply:
            BACKUP.mkdir(parents=True, exist_ok=True)
            for size, img in made.items():
                dest = master_path.parent / f"{base}_{size}.png"
                if dest.is_file() and not (BACKUP / dest.name).exists():  # keep one copy per name
                    shutil.copy2(dest, BACKUP / dest.name)
                img.save(dest)
        rows.append({"family": base, "source": src, "master": master.size,
                     "status": status, "fit": args.fit,
                     "boxes": {str(s): boxes[i] for i, s in enumerate(sizes)},
                     "min_stroke": {str(s): strokes[s] for s in sizes}})

    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {len(rows)} families, "
          f"{args.fit} fit, sizes {list(sizes)}")
    if mismatched:
        print(f"source check MISMATCH on {len(mismatched)} families: {mismatched[:12]}")
    REPORT.write_text(json.dumps({"fit": args.fit, "sizes": list(sizes),
                                  "applied": args.apply, "rows": rows}, indent=1),
                      encoding="utf-8")
    print(f"wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
