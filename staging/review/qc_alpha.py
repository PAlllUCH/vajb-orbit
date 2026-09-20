"""Alpha QC pass over the shipping sprites. Read-only, no API calls.

For every PNG it measures the silhouette and the *enclosed* transparent
regions (holes punched through the hull by the local matte) plus the
border fringe, and writes a table + an optional overlay sheet.

Usage:
    py -3.14 staging/review/qc_alpha.py [--families ships,env,fx,ui] [--all]
                                        [--json out.json] [--overlay]
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

WORKSPACE = Path(__file__).resolve().parents[2]
ASSETS = WORKSPACE / "vajb-orbit" / "assets"

# families whose root-level PNGs are shipping sprites
DEFAULT_FAMILIES = ("ships", "env", "fx", "ui")

HOLE_FLAG_PCT = 0.5  # report as suspect above this share of the silhouette


def analyse(path: Path) -> dict:
    im = Image.open(path).convert("RGBA")
    a = np.array(im.getchannel("A"))
    op = a > 128
    sil = int(op.sum())
    trans = ~op

    # transparent regions touching the border are background, the rest are holes
    labels, _ = ndimage.label(trans)
    border_ids = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border_ids.discard(0)
    holes = trans & ~np.isin(labels, list(border_ids)) if border_ids else trans
    hole_px = int(holes.sum())
    hlabels, hcount = ndimage.label(holes)
    areas = (
        sorted((int(v) for v in ndimage.sum(holes, hlabels, range(1, hcount + 1))), reverse=True)
        if hcount
        else []
    )

    # fully transparent fraction, matching the generation logs
    alpha0 = 100.0 * float((a == 0).sum()) / a.size
    pct = 100.0 * hole_px / sil if sil else 0.0

    return {
        "path": path.as_posix(),
        "name": path.name,
        "family": path.parent.name,
        "size": [im.size[0], im.size[1]],
        "silhouette_px": sil,
        "alpha0_pct": round(alpha0, 2),
        "hole_px": hole_px,
        "hole_pct_of_silhouette": round(pct, 2),
        "hole_blobs": hcount,
        "largest_holes": areas[:6],
        "flag": pct > HOLE_FLAG_PCT,
    }


def collect(families: tuple[str, ...], include_subfolders: bool) -> list[Path]:
    out: list[Path] = []
    for fam in families:
        base = ASSETS / fam
        if not base.is_dir():
            continue
        out += sorted(base.glob("*.png"))
        if include_subfolders:
            out += sorted(p for p in base.rglob("*.png") if p.parent != base)
    return out


def overlay(path: Path, row: dict, dest: Path) -> None:
    """Tint the enclosed holes so they read at a glance."""
    im = Image.open(path).convert("RGBA")
    a = np.array(im.getchannel("A"))
    op = a > 128
    trans = ~op
    labels, _ = ndimage.label(trans)
    border_ids = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border_ids.discard(0)
    holes = trans & ~np.isin(labels, list(border_ids)) if border_ids else trans
    if not holes.any():
        return
    rgb = np.array(im)
    rgb[holes] = [255, 0, 128, 255]
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgb).save(dest)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--families", default=",".join(DEFAULT_FAMILIES))
    ap.add_argument("--all", action="store_true", help="include timestamped run folders and subvariants")
    ap.add_argument("--json", default="")
    ap.add_argument("--overlay", action="store_true")
    args = ap.parse_args()

    families = tuple(f.strip() for f in args.families.split(",") if f.strip())
    files = collect(families, args.all)
    rows = [analyse(p) for p in files]

    flagged = sorted((r for r in rows if r["flag"]), key=lambda r: -r["hole_pct_of_silhouette"])
    clean = sum(1 for r in rows if not r["flag"])
    print(f"{len(rows)} sprites scanned, {clean} clean, {len(flagged)} flagged "
          f"(> {HOLE_FLAG_PCT}% of silhouette punched out)\n")
    print(f"{'asset':44s} {'size':>11s} {'sil?':>8s} {'holes':>7s} {'%sil':>6s} {'blobs':>6s}  largest")
    for r in flagged:
        print(f"{r['name']:44s} {r['size'][0]:5d}x{r['size'][1]:<5d} {r['silhouette_px']:8d} "
              f"{r['hole_px']:7d} {r['hole_pct_of_silhouette']:6.2f} {r['hole_blobs']:6d}  {r['largest_holes']}")

    if args.overlay:
        out = WORKSPACE / "staging" / "review" / "_preview"
        for r in flagged:
            overlay(Path(r["path"]), r, out / f"holes_{Path(r['path']).stem}.png")
        print(f"\noverlays -> {out}")

    if args.json:
        dest = Path(args.json)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps({"rows": rows, "flagged": len(flagged)}, indent=2), encoding="utf-8")
        print(f"json -> {dest}")


if __name__ == "__main__":
    main()
