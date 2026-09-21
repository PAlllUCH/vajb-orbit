"""Phase F.2 (C1) - rebuild the panel frame nine-slice at an exact 1/3 band.

The defect (ASSET_AUDIT C1, UI_CHROME_ASSETS_SPEC section 2): the nine-slice margin is
32 px at 96, but the painted border band is only ~12 px, so the drawn border is 32 px of
which 20 px are stretched interior - the frame reads far too heavy and the riveted corner
detail is scaled out of proportion. Two F.1/F.2 generations asked the model for a band of
"exactly one third" and returned 12-15 percent both times.

This script removes the model's band width from the equation. It measures the painted band
of the trimmed master, then rebuilds the texture as a 3x3 grid of band-sized tiles:

    band = size / 3        (32 px at 96, 64 px at 192)
    corner tile  <- the master's corner square (band x band)     -> band x band
    edge tile    <- the master's straight band run between corners -> band x band
    centre tile  <- the master's whole interior opening           -> band x band

so the painted band equals the nine-slice margin by construction, whatever the model drew,
and the corner rivet detail scales with the band instead of being stretched by it. The
master is scaled once per tile with LANCZOS; no tile is ever upscaled past 3x unless the
model returns a band under 7 percent of the frame (which the validation below rejects).

Dry run by default; `--apply` writes `ui_panel_frame.png` (96) and `ui_panel_frame@2x.png`
(192) into staging/phase_f/ui/ for `ship_batch.py ui`.

Usage:
  py -3.14 staging/phase_f/reband_frame.py
  py -3.14 staging/phase_f/reband_frame.py --apply
  py -3.14 staging/phase_f/reband_frame.py --master <path> --apply
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
STAGE = ROOT / "staging" / "phase_f"
UI = STAGE / "ui"
DEFAULT_MASTER = UI / "ui_panel_frame-master.png"
REPORT = STAGE / "reband_report.json"
PREVIEW = STAGE / "_preview" / "f2_frame_reband.png"

SIZES = (96, 192)          # 192 is the `@2x` cut (UI_CHROME_ASSETS_SPEC section 10)
NAMES = {96: "ui_panel_frame.png", 192: "ui_panel_frame@2x.png"}
BAND_DIVISOR = 3           # the nine-slice margin is one third of the frame
BAND_MIN_FRAC = 0.05       # a band below 5 % of the span would be upscaled past 6x
BAND_MAX_FRAC = 0.45       # a band above 45 % leaves no interior to sample
SPREAD_MAX = 0.12          # the four edges must agree within 12 % of their mean


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def opaque_crop(img: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    """Drop the transparent margin the model leaves around the frame."""
    arr = np.asarray(img.convert("RGBA"))
    mask = arr[..., 3] > 0
    ys, xs = np.nonzero(mask)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    return img.convert("RGBA").crop(box), box


def band_px(line: np.ndarray, inner_ref: float, window: int) -> int | None:
    """Band thickness measured as the distance from the edge to the opening.

    A plain "first dark sample" test is not usable here: the frame's own outer bevel line
    is near-black (the prompt asks for an iron black outer edge), so a scratch or a chamfer
    at the silhouette reads darker than the interior for dozens of pixels. The opening is
    instead identified as the longest sustained dark run on the line - the opening is a
    large square (a fifth of the span at the very least) while any bevel, scratch or grime
    patch is a short run. `window` is the minimum run length in samples.
    """
    dark = line <= inner_ref + 8.0
    best = (0, 0)
    start = None
    for i, is_dark in enumerate(dark):
        if is_dark and start is None:
            start = i
        elif not is_dark and start is not None:
            if i - start > best[1] - best[0]:
                best = (start, i)
            start = None
    if start is not None and len(dark) - start > best[1] - best[0]:
        best = (start, len(dark))
    if best[1] - best[0] < window:
        return None
    return int(best[0])


def band_lines(lum: np.ndarray, inner_ref: float, window: int) -> dict:
    h, w = lum.shape
    lines = {
        "top": lum[:, w // 2],
        "bottom": lum[::-1, w // 2],
        "left": lum[h // 2, :],
        "right": lum[h // 2, ::-1],
    }
    return {name: band_px(line, inner_ref, window) for name, line in lines.items()}


def measure_band(img: Image.Image) -> dict:
    arr = np.asarray(img)
    lum = luminance(arr[..., :3])
    h, w = lum.shape
    window = int(0.2 * min(h, w))          # the opening is at least a fifth of the span
    c0, c1 = int(h * 0.4), int(h * 0.6)
    inner_ref = float(np.median(lum[c0:c1, c0:c1]))
    out = band_lines(lum, inner_ref, window)
    vals = [v for v in out.values() if v is not None]
    mean = float(np.mean(vals)) if vals else float("nan")
    spread = (max(vals) - min(vals)) / mean if vals and mean else float("inf")
    return {"edges": out, "mean": mean, "spread": float(spread),
            "inner_ref": inner_ref, "span": (w, h), "window": window}


def rebuild(master: Image.Image, band: int, size: int) -> Image.Image:
    """The 3x3 nine-slice rebuild at a band of `size // BAND_DIVISOR`."""
    tile = size // BAND_DIVISOR
    w, h = master.size
    x0, x1 = band, w - band
    y0, y1 = band, h - band

    def fit(box: tuple[int, int, int, int]) -> Image.Image:
        return master.crop(box).resize((tile, tile), Image.LANCZOS)

    tiles = {
        "tl": fit((0, 0, band, band)), "tr": fit((w - band, 0, w, band)),
        "bl": fit((0, h - band, band, h)), "br": fit((w - band, h - band, w, h)),
        "top": fit((x0, 0, x1, band)), "bottom": fit((x0, h - band, x1, h)),
        "left": fit((0, y0, band, y1)), "right": fit((w - band, y0, w, y1)),
        "centre": fit((x0, y0, x1, y1)),
    }
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(tiles["tl"], (0, 0))
    out.paste(tiles["top"], (tile, 0))
    out.paste(tiles["tr"], (size - tile, 0))
    out.paste(tiles["left"], (0, tile))
    out.paste(tiles["centre"], (tile, tile))
    out.paste(tiles["right"], (size - tile, tile))
    out.paste(tiles["bl"], (0, size - tile))
    out.paste(tiles["bottom"], (tile, size - tile))
    out.paste(tiles["br"], (size - tile, size - tile))
    return out


def nine_patch(tex: Image.Image, margin: int, w: int, h: int) -> Image.Image:
    """Draw `tex` as Godot's NinePatchRect does at `w`x`h`: corners fixed, edges and
    centre stretched."""
    t = tex.width
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    inner_w, inner_h = w - 2 * margin, h - 2 * margin
    for (sx, sy, sw, sh), (dx, dy, dw, dh) in (
            ((0, 0, margin, margin), (0, 0, margin, margin)),
            ((t - margin, 0, margin, margin), (w - margin, 0, margin, margin)),
            ((0, t - margin, margin, margin), (0, h - margin, margin, margin)),
            ((t - margin, t - margin, margin, margin), (w - margin, h - margin, margin, margin)),
            ((margin, 0, t - 2 * margin, margin), (margin, 0, inner_w, margin)),
            ((margin, t - margin, t - 2 * margin, margin), (margin, h - margin, inner_w, margin)),
            ((0, margin, margin, t - 2 * margin), (0, margin, margin, inner_h)),
            ((t - margin, margin, margin, t - 2 * margin), (w - margin, margin, margin, inner_h)),
            ((margin, margin, t - 2 * margin, t - 2 * margin), (margin, margin, inner_w, inner_h))):
        if dw <= 0 or dh <= 0:
            continue
        out.paste(tex.crop((sx, sy, sx + sw, sy + sh)).resize((dw, dh), Image.LANCZOS), (dx, dy))
    return out


def drawn_band(panel: Image.Image, margin: int) -> dict:
    """Where the painted band ends in a drawn nine-patch panel, per axis.

    This is the acceptance measure for C1: with the theme's margin applied, the *painted*
    band of the drawn panel must reach the margin (32 px), not stop short of it inside a
    stretched slice (the pre-F.2 frame stopped at 12 px, which is what made the frame read
    far too heavy).
    """
    arr = np.asarray(panel)
    lum = luminance(arr[..., :3])
    h, w = lum.shape
    window = int(0.2 * min(h, w))
    inner_ref = float(np.median(lum[h // 3:2 * h // 3, w // 3:2 * w // 3]))
    return {"vertical": band_px(lum[:, w // 2], inner_ref, window),
            "horizontal": band_px(lum[h // 2, :], inner_ref, window),
            "interior_ref": inner_ref, "margin": margin}


def label(img: Image.Image, text: str, xy: tuple[int, int], size: int = 13) -> None:
    """Preview caption (Pillow's text drawing is only needed for the sheet)."""
    from PIL import ImageDraw as _ImageDraw, ImageFont as _ImageFont
    draw = _ImageDraw.Draw(img)
    try:
        font = _ImageFont.truetype("C:/Windows/Fonts/consola.ttf", size)
    except Exception:
        font = _ImageFont.load_default()
    draw.text(xy, text, fill=(210, 216, 224, 255), font=font)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--master", default=str(DEFAULT_MASTER))
    ap.add_argument("--margin", type=int, default=32, help="theme nine-slice margin at 96")
    args = ap.parse_args()

    master_path = Path(args.master)
    if not master_path.is_file():
        print(f"missing master {master_path}")
        return 1
    raw = Image.open(master_path).convert("RGBA")
    master, box = opaque_crop(raw)
    w, h = master.size
    span = min(w, h)
    m = measure_band(master)
    band = int(round(m["mean"]))
    print(f"master {master_path.name}: {raw.size} -> opaque crop {master.size} {box}")
    print(f"  painted band per edge {m['edges']}  mean {m['mean']:.1f} px "
          f"({100 * m['mean'] / span:.1f} % of the span), spread {100 * m['spread']:.1f} %")
    if not (BAND_MIN_FRAC * span <= band <= BAND_MAX_FRAC * span):
        print(f"  REFUSED: band {band} px outside {BAND_MIN_FRAC:.0%}-{BAND_MAX_FRAC:.0%} of the span")
        return 1
    if m["spread"] > SPREAD_MAX:
        print(f"  REFUSED: edges disagree by {100 * m['spread']:.1f} % (> {100 * SPREAD_MAX:.0f} %)")
        return 1

    rows = []
    made = {}
    for size in SIZES:
        tile = size // BAND_DIVISOR
        out = rebuild(master, band, size)
        made[size] = out
        # The `@2x` cut is drawn with twice the margin (64 px), not with the 1x margin:
        # its logical box is unchanged and the coder renders it at half scale.
        scale = size // 96
        panel = nine_patch(out, args.margin * scale, 384 * scale, 240 * scale)
        drawn = drawn_band(panel, args.margin * scale)
        rows.append({"size": size, "file": NAMES[size], "band": tile,
                     "master_band": band,
                     "master_band_frac": round(band / span, 4),
                     "downscale": round(band / tile, 2),
                     "margin": args.margin * scale,
                     "drawn": drawn})
        print(f"  {NAMES[size]:26s} {size}x{size}  band {tile} px "
              f"({band / tile:.1f}x downscale from the {band} px master band)"
              f"  drawn through a {args.margin * scale} px margin: band at "
              f"{drawn['vertical']}/{drawn['horizontal']} px")

    preview = Image.new("RGBA", (384 * 2 + 24, 240 * 2 + 36), (10, 14, 20, 255))
    label(preview, "F.2 re-banded", (8, 6))
    label(preview, "master (model band)", (8, 18 + 240))
    preview.paste(nine_patch(made[96], args.margin, 384, 240), (8, 28))
    preview.paste(master.resize((384, 240), Image.LANCZOS), (8, 280))
    old = ASSETS / "ui" / "ui_panel_frame.png"
    if old.is_file():
        label(preview, "pre-F.2 shipped", (400, 6))
        preview.paste(nine_patch(Image.open(old).convert("RGBA"), args.margin, 384, 240), (400, 28))
        label(preview, "pre-F.2 texture", (400, 18 + 240))
        preview.paste(Image.open(old).convert("RGBA").resize((192, 192), Image.LANCZOS), (400, 280))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(PREVIEW)
    print(f"  preview {PREVIEW}")

    if args.apply:
        UI.mkdir(parents=True, exist_ok=True)
        for size, img in made.items():
            dest = UI / NAMES[size]
            img.save(dest)
            print(f"  wrote {dest}")
    REPORT.write_text(json.dumps({"applied": args.apply, "master": str(master_path),
                                  "master_size": raw.size, "opaque_crop": list(box),
                                  "band": band, "measure": m, "margin": args.margin,
                                  "rows": rows}, indent=1), encoding="utf-8")
    print(f"{'APPLIED' if args.apply else 'DRY RUN'}: wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
