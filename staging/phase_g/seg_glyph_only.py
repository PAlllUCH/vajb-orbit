"""Re-author the twelve D6 seven-segment cells as GLYPH-ONLY, transparent-background masters.

`UI_CHROME_ASSETS_SPEC` section 12's post-mockup amendment (2026-09-24): the approved cockpit look
mounts **bare** seven-segment drums on metal - the D6 `ui_seg_*` cells carry painted plate
backgrounds and are **re-authored as glyph-only, transparent-background cells under the same 12
names**: rasterise the existing `staging/phase_g/ui/_svg/ui_seg_*.svg` segment lattice alone (drop
the plate-face layer) at 48x88 - no paid generation.

The D6 route (`seg_svg_digits.py`) composited that same lattice over one generated plate; this step
keeps the lattice and drops the plate. The SVG files are the ones `seg_svg_digits.py` authored from
`seg_geometry.lattice`, so the glyph geometry is exactly the geometry AC5 measures against.

Output goes to `staging/phase_g/ui/_seg_glyph/` (the prepared masters for the glyph-only family; the
D6 plate-composited masters stay in `ui/_masters/` as the D6 record). `--ship` copies the twelve
files into `vajb-orbit/assets/ui/` after snapshotting the bytes they replace into `ui/_a1b_backup/`.

Usage:
    python3 staging/phase_g/seg_glyph_only.py [--ship] [--preview out.png]
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import shutil
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

import wave_g
from seg_geometry import BOX, LIT, SS, UNLIT

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
UI = STAGE / "ui"
SVG_DIR = UI / "_svg"
OUT = UI / "_seg_glyph"
BACKUP = UI / "_a1b_backup"
ASSETS_UI = ROOT / "vajb-orbit" / "assets" / "ui"
CELLS = tuple(f"ui_seg_{i}" for i in range(10)) + ("ui_seg_pct", "ui_seg_blank")


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def opaque_palette(img: Image.Image, top: int = 4) -> list[tuple[str, float]]:
    """The most common fully opaque colours and their shares of the opaque pixels.

    Rasterised directly at the master box, cairo antialiases only the bar edges, so a bar's core is
    exactly LIT or UNLIT and the two colours are the whole opaque palette; the fringe pixels carry
    the same two colours at partial alpha. The two dominant entries are therefore the segment
    colours themselves - that is the whole palette check the glyph-only family needs.
    """
    pixels = np.asarray(img.convert("RGBA"))
    solid = pixels[pixels[..., 3] == 255][:, :3]
    if not len(solid):
        return []
    packed = (solid[:, 0].astype(np.uint32) << 16) | (solid[:, 1].astype(np.uint32) << 8) \
        | solid[:, 2].astype(np.uint32)
    values, counts = np.unique(packed, return_counts=True)
    order = np.argsort(-counts)[:top]
    return [(f"#{values[i]:06X}", round(float(counts[i]) / len(solid), 4)) for i in order]


def rasterise(svg_path: Path) -> Image.Image:
    """The SVG's own lattice at the master box, on a transparent canvas (no plate behind it).

    Rasterised **directly at 48x88** rather than supersampled and downscaled: the amendment names
    the master box, and a direct render keeps the two segment fills as the only fully opaque
    colours (measured: 2 distinct opaque colours, 1310 + 160 px) where an RGBA-plane LANCZOS
    downscale of a 4x render leaves 1272 partial-alpha pixels and invents lighter off-palette
    blends (the D6 route composited the soft layer over an opaque plate, which hid that).
    """
    png = cairosvg.svg2png(url=str(svg_path), output_width=BOX[0], output_height=BOX[1])
    return Image.open(io.BytesIO(png)).convert("RGBA")


def measure(path: Path) -> dict:
    img = Image.open(path).convert("RGBA")
    alpha = np.asarray(img.getchannel("A"))
    return {
        "pixels": list(img.size),
        "bytes": path.stat().st_size,
        "md5": md5(path),
        "transparent_pct": round(100.0 * float((alpha == 0).mean()), 2),
        "ink_pct": round(100.0 * float((alpha > 8).mean()), 2),
        "palette": opaque_palette(img),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ship", action="store_true")
    parser.add_argument("--preview", default="")
    args = parser.parse_args()

    missing = [n for n in CELLS if not (SVG_DIR / f"{n}.svg").is_file()]
    if missing:
        print(f"missing SVG lattice(s) in {SVG_DIR.relative_to(ROOT)}: {', '.join(missing)}")
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    report: dict = {}
    for name in CELLS:
        layer = rasterise(SVG_DIR / f"{name}.svg")
        if layer.size != BOX:
            print(f"{name}: rasterised {layer.size}, expected {BOX[0]}x{BOX[1]}")
            return 1
        target = OUT / f"{name}.png"
        layer.save(target)
        report[name] = measure(target)
        palette = report[name]["palette"]
        ## Glyph-only proof: the plate-face layer is gone (most of the cell is transparent) and the
        ## opaque pixels carry the lattice's own two segment fills and nothing else.
        if report[name]["transparent_pct"] < 50.0:
            print(f"{name}: only {report[name]['transparent_pct']}% transparent - the plate face "
                  f"is still behind the lattice")
            return 1
        extra = [c for c, _s in palette if c not in (UNLIT, LIT)]
        if extra:
            print(f"{name}: off-palette opaque colour(s) {extra} "
                  f"(the lattice is {UNLIT} / {LIT})")
            return 1
        print(f"{name:16s} {layer.size[0]}x{layer.size[1]}  "
              f"transparent {report[name]['transparent_pct']:6.2f}%  "
              f"ink {report[name]['ink_pct']:6.2f}%  md5 {report[name]['md5'][:8]}  "
              + " ".join(f"{c}:{s:.3f}" for c, s in palette))

    if args.preview:
        sheet = Image.new("RGB", (12 * (BOX[0] * SS + 6), BOX[1] * SS + 6), (30, 30, 34))
        for index, name in enumerate(CELLS):
            img = Image.open(OUT / f"{name}.png").resize((BOX[0] * SS, BOX[1] * SS), Image.NEAREST)
            sheet.paste(img, (index * (BOX[0] * SS + 6) + 3, 3), img)
        sheet.save(args.preview)
        print(f"preview {args.preview} {sheet.size}")

    if not args.ship:
        print(f"{len(CELLS)} glyph-only master(s) in {OUT.relative_to(ROOT)} (dry run; --ship copies)")
        return 0

    BACKUP.mkdir(parents=True, exist_ok=True)
    backup_rows: list[str] = []
    for name in CELLS:
        current = ASSETS_UI / f"{name}.png"
        if current.is_file():
            shutil.copyfile(current, BACKUP / f"{name}.png")
            backup_rows.append(f"{name}.png  {md5(current)}")
        shutil.copyfile(OUT / f"{name}.png", current)
        print(f"  shipped {name}.png -> assets/ui/ ({md5(current)[:8]})")
    (BACKUP / "MANIFEST.md5").write_text("\n".join(backup_rows) + "\n", encoding="utf-8")
    (BACKUP / "README.md").write_text(
        "# D7-A1b backup\n\n"
        "The twelve `ui_seg_*` bytes this step replaced (plate-composited D6 masters), one line per\n"
        "file in `MANIFEST.md5`. Reversal: copy a file back over `vajb-orbit/assets/ui/<name>.png`,\n"
        "then reimport. The glyph-only replacements stay in `staging/phase_g/ui/_seg_glyph/`.\n",
        encoding="utf-8")
    print(f"backup of the replaced bytes -> {BACKUP.relative_to(ROOT)} "
          f"({len(backup_rows)} file(s))")
    print(json.dumps({n: report[n]["md5"] for n in CELLS}, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
