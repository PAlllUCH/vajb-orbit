"""The AC5 fallback route for the D6 seven-segment cells: hand-authored SVG segments.

Why the fallback (measured 2026-09-24, `qc_seg_digits.py`):

* the two digit panels came back in two different styles - `panel_sevenseg_a` drew the lit
  segments as hollow bone outlines, `panel_sevenseg_b` drew them as solid filled bone bars
  (lit-ink share 0.045-0.087 against 0.17-0.22 on the same 48x88 master), so the family cannot
  mix them;
* `panel_sevenseg_b`'s percent cell is a diagonal slash with two dots, not seven-segment strokes,
  and it is drawn large enough that 9.7 % of its lit ink falls outside `ui_seg_blank`'s ghost
  segment boxes;
* with two independently rendered panels, AC5's ink-share ordering can never hold: `ui_seg_7`'s
  three bold segments carry more ink than `ui_seg_2`/`ui_seg_3`/`ui_seg_4`'s five, purely because
  panel b's stroke is heavier than panel a's.

`UI_CHROME_ASSETS_SPEC` section 11 names the cure: "a digit that mangles twice on regeneration
falls back to hand-authored SVG segments ... rasterised into the same file names". This script
authors the segment layer once (one geometry, lit segments Bone `#C9CDD2`, unlit segments Panel
Steel `#2A2E35`, the ghost outline of the plate showing through), rasterises each cell with
cairosvg exactly as the D2 route does, and composites it over the one generated plate the family
keeps - so all twelve cells share one plate and one segment lattice and AC5 holds by construction.

Usage:
    uv run --with pillow --with numpy --with scipy --with cairosvg python3 \
        staging/phase_g/seg_svg_digits.py [--pct a,f,g,c,d] [--preview out.png]
"""
from __future__ import annotations

import argparse
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

import wave_g
from seg_geometry import BOX, DIGIT_SEGMENTS, LIT, PCT_SEGMENTS, SS, UNLIT, lattice

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
UI = STAGE / "ui"
SVG_DIR = UI / "_svg"
MASTERS = UI / "_masters"
PLATE_SOURCE = UI / "ui_seg_blank.png"
GHOST_LOW = 30.0            # panel-black face is ~24; the ghost outline is panel steel (~46)
GHOST_HIGH = 120.0


def luminance(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def plate_box(img: Image.Image) -> Image.Image:
    alpha = np.asarray(img.convert("RGBA").getchannel("A"))
    rows = np.where((alpha > 8).any(axis=1))[0]
    cols = np.where((alpha > 8).any(axis=0))[0]
    return img.convert("RGBA").crop((int(cols[0]), int(rows[0]),
                                    int(cols[-1]) + 1, int(rows[-1]) + 1))


def erase_ghost(plate: Image.Image) -> Image.Image:
    """Replace the plate's embossed face with a flat display face.

    The model's plate carries an embossed seven-segment figure in its face at its own geometry;
    leaving it under the authored bars doubles every segment edge and mottles the cells (measured
    on the first SVG pass), and blurring it only turns the emboss into smudges. The face inside the
    painted frame is therefore replaced with its own median colour plus a fixed-seed grain, so the
    lit and unlit bars are the only segment geometry in the cell. The riveted frame is untouched.
    """
    rng = np.random.default_rng(20260924)
    pixels = np.asarray(plate.convert("RGBA")).copy()
    height, width = pixels.shape[:2]
    inset_x, inset_y = max(6, width // 7), max(8, height // 9)
    face = pixels[inset_y:height - inset_y, inset_x:width - inset_x, :3].reshape(-1, 3)
    base = np.median(face, axis=0)
    noise = rng.integers(-3, 4, size=(height - 2 * inset_y, width - 2 * inset_x, 1))
    flat = np.clip(base.reshape(1, 1, 3) + noise, 0, 255).astype(np.uint8)
    pixels[inset_y:height - inset_y, inset_x:width - inset_x, :3] = flat
    return Image.fromarray(pixels, "RGBA")


def segment_field(plate: Image.Image) -> tuple[int, int, int, int]:
    """The ghost outline's own box inside the plate - the seven-segment field.

    The plate's unlit ghost outline traces the full figure 8, so its ink box is exactly the
    segment field; the lattice is built on that box rather than on the plate, so the bars land
    where the plate's own ghost already is.
    """
    lum = luminance(plate)
    height, width = lum.shape
    inner = np.zeros_like(lum, bool)
    inset_x, inset_y = max(2, width // 12), max(2, height // 14)
    inner[inset_y:height - inset_y, inset_x:width - inset_x] = True
    ghost = inner & (lum >= GHOST_LOW) & (lum < GHOST_HIGH)
    rows, cols = np.where(ghost)
    if not len(rows) or not len(cols):
        return inset_x, inset_y, width - inset_x, height - inset_y
    return int(cols.min()), int(rows.min()), int(cols.max()) + 1, int(rows.max()) + 1


def cell_svg(segments: dict[str, tuple[float, float, float, float]], lit: set[str]) -> str:
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{BOX[0]}" height="{BOX[1]}" '
             f'viewBox="0 0 {BOX[0]} {BOX[1]}">']
    for key, (left, top, right, bottom) in segments.items():
        colour = LIT if key in lit else UNLIT
        parts.append(f'<rect x="{left:.2f}" y="{top:.2f}" width="{right - left:.2f}" '
                     f'height="{bottom - top:.2f}" fill="{colour}"/>')
    parts.append("</svg>")
    return "\n".join(parts)


def rasterise(svg: str, name: str) -> Image.Image:
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    path = SVG_DIR / f"{name}.svg"
    path.write_text(svg, encoding="utf-8")
    png = cairosvg.svg2png(url=str(path), output_width=BOX[0] * SS, output_height=BOX[1] * SS)
    import io
    layer = Image.open(io.BytesIO(png)).convert("RGBA")
    return layer.resize(BOX, Image.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pct", default=PCT_SEGMENTS)
    parser.add_argument("--preview", default="")
    args = parser.parse_args()
    pct_segments = args.pct

    if not PLATE_SOURCE.is_file():
        print(f"missing generated plate {PLATE_SOURCE}")
        return 1
    plate = plate_box(Image.open(PLATE_SOURCE)).resize(BOX, Image.LANCZOS)
    field = segment_field(plate)          # read the ghost before it is erased
    plate = erase_ghost(plate)
    segments = lattice(field)
    print(f"plate {plate.size}  segment field {field}  field box "
          f"{field[2] - field[0]}x{field[3] - field[1]}")

    cells: dict[str, set[str]] = {f"ui_seg_{d}": set(DIGIT_SEGMENTS[str(d)].split(","))
                                  for d in range(10)}
    cells["ui_seg_pct"] = set(pct_segments.split(","))
    cells["ui_seg_blank"] = set()

    MASTERS.mkdir(parents=True, exist_ok=True)
    for name, lit in cells.items():
        layer = rasterise(cell_svg(segments, lit), name)
        out = plate.copy()
        out.alpha_composite(layer)
        out.save(MASTERS / f"{name}.png")
        print(f"  {name}: {len(lit)} lit segment(s) -> {MASTERS.name}/{name}.png")

    if args.preview:
        sheet = Image.new("RGB", (12 * (BOX[0] * SS + 6), BOX[1] * SS + 6), (30, 30, 34))
        for index, name in enumerate(list(cells)):
            img = Image.open(MASTERS / f"{name}.png").resize((BOX[0] * SS, BOX[1] * SS),
                                                            Image.NEAREST)
            sheet.paste(img, (index * (BOX[0] * SS + 6) + 3, 3), img)
        sheet.save(args.preview)
        print(f"preview {args.preview} {sheet.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
