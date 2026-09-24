"""Take the painted needle out of the D6 dial face.

`UI_CHROME_ASSETS_SPEC` section 11 asks for a painted dial with "no numbers, no needle" - the code
draws the prograde needle and the heading tick itself (UI_SPEC sections 3.6/3.7). Three renders of
the instrument panel (tasks fcadff98, f72d6e47, 001cb6bb) each painted the needle onto the face
instead, so the face is cleaned here and the needle ships as its own authored sprite
(`ui_authored.py`).

The clean is measured. A first pass built the needle mask from the difference between the face and
its own rotation median (the dial is radially symmetric); that failed - measured 27 % of the
canvas flagged, because the painted face carries non-radial texture and scratches, not just the
needle. The needle is instead found as what it is: the only long straight bar running out of the
hub. For every bearing, the mean luminance profile across the bearing (offsets -28..+28 px, radii
0.12..0.55 R) is measured; the needle's bearing is the one whose profile has the largest
peak-to-median step, and the bar is the contiguous run around that peak. The masked pixels are then
filled from the face's own rotation median (median across ten rotations about the hub), which is
needle-free by construction.

Usage:
    uv run --with pillow --with numpy --with scipy python3 staging/phase_g/gauge_clean.py
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
UI = STAGE / "ui"
MASTERS = UI / "_masters"
SOURCE = UI / "ui_gauge_face.png"
BOX = (240, 240)               # section 11: logical 120x120, master 240x240
ROTATIONS = 10
BEARING_STEP = 0.5
RADII = (0.12, 0.55)
OFFSETS = 28                   # perpendicular half-window in pixels of the cut
WEDGE_PX = 60                  # the needle's bearing estimate is coarse; widen it into a wedge
TEXTURE_STEP = 12.0            # luminance step from the rotation median that is not dial texture

DEBUG = True


def luminance(img: Image.Image) -> np.ndarray:
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def plate_crop(img: Image.Image) -> Image.Image:
    alpha = np.asarray(img.convert("RGBA").getchannel("A"))
    rows = np.where((alpha > 8).any(axis=1))[0]
    cols = np.where((alpha > 8).any(axis=0))[0]
    return img.convert("RGBA").crop((int(cols[0]), int(rows[0]),
                                    int(cols[-1]) + 1, int(rows[-1]) + 1))


def sample(lum: np.ndarray, xs: np.ndarray, ys: np.ndarray) -> np.ndarray:
    height, width = lum.shape
    xs = np.clip(xs, 0, width - 1.001)
    ys = np.clip(ys, 0, height - 1.001)
    x0, y0 = np.floor(xs).astype(int), np.floor(ys).astype(int)
    dx, dy = xs - x0, ys - y0
    return (lum[y0, x0] * (1 - dx) * (1 - dy) + lum[y0, x0 + 1] * dx * (1 - dy)
            + lum[y0 + 1, x0] * (1 - dx) * dy + lum[y0 + 1, x0 + 1] * dx * dy)


def needle_band(face: Image.Image, clean: Image.Image) -> tuple[np.ndarray, dict]:
    """The needle's own pixels, as a mask, plus the measurement that found it.

    Two measurements stack here, because neither alone is enough:

    * a **bearing search** - for every bearing, the mean luminance profile across it (offsets
      -28..+28 px, radii 0.12..0.55 R) is measured and the bearing with the largest peak-to-median
      step is the needle's. The search is coarse (measured 9.5 degrees off the drawn needle), so it
      is used as a wedge, not as the mask;
    * inside that wedge, the mask is every pixel where the face differs from its own **rotation
      median** by more than the texture step. The median is needle-free by construction, so it is
      both the detector's reference and the fill source, and a few texture pixels caught by the
      threshold cost nothing - they are filled with the dial's own look.
    """
    lum = luminance(face)
    median_lum = luminance(clean)
    height, width = lum.shape
    centre_x, centre_y = width / 2.0, height / 2.0
    radius = min(width, height) / 2.0
    bearings = np.deg2rad(np.arange(0.0, 360.0, BEARING_STEP))
    radii = np.linspace(RADII[0], RADII[1], 24) * radius
    offsets = np.linspace(-OFFSETS, OFFSETS, 2 * OFFSETS + 1)

    cos_b, sin_b = np.cos(bearings)[:, None, None], np.sin(bearings)[:, None, None]
    radii_v = radii[None, :, None]
    offsets_v = offsets[None, None, :]
    xs = centre_x + radii_v * cos_b - offsets_v * sin_b
    ys = centre_y + radii_v * sin_b + offsets_v * cos_b
    profile = sample(lum, xs, ys).mean(axis=1)                  # (bearing, offset)
    medians = np.median(profile, axis=1, keepdims=True)
    steps = profile.max(axis=1) - medians[:, 0]
    best = int(np.argmax(steps))
    bearing = float(np.rad2deg(bearings[best]))

    yy, xx = np.mgrid[0:height, 0:width]
    dx, dy = xx - centre_x, yy - centre_y
    along = dx * np.cos(bearings[best]) + dy * np.sin(bearings[best])
    across = -dx * np.sin(bearings[best]) + dy * np.cos(bearings[best])
    wedge = (along >= 26.0) & (along <= 0.70 * radius) & (np.abs(across) <= WEDGE_PX)
    mask = wedge & (np.abs(lum - median_lum) > TEXTURE_STEP)
    mask = ndimage.binary_closing(mask, np.ones((7, 7), bool))
    mask = ndimage.binary_dilation(mask, np.ones((5, 5), bool))
    print(f"  bearing {bearing:.1f} deg (step {steps[best]:.1f} levels), wedge {WEDGE_PX} px, "
          f"r 26..{0.70 * radius:.0f} px, texture step {TEXTURE_STEP:.0f}")
    return mask, {"bearing_deg": bearing, "wedge_px": WEDGE_PX, "step": float(steps[best])}


def rotation_median(face: Image.Image) -> Image.Image:
    centre = (face.size[0] / 2.0, face.size[1] / 2.0)
    stack = np.stack([
        np.asarray(face.rotate(360.0 * k / ROTATIONS, resample=Image.BILINEAR,
                               center=centre, expand=False).convert("RGB"), dtype=np.float64)
        for k in range(ROTATIONS)])
    return Image.fromarray(np.median(stack, axis=0).astype(np.uint8), "RGB")


def main() -> int:
    if not SOURCE.is_file():
        print(f"missing {SOURCE}")
        return 1
    face = plate_crop(Image.open(SOURCE))
    print(f"face cut {face.size}")
    clean = rotation_median(face)
    mask, detail = needle_band(face, clean)
    mask = ndimage.binary_closing(mask, np.ones((5, 5), bool))
    print(f"needle mask {int(mask.sum())} px ({100.0 * mask.mean():.2f} % of the cut)")

    pixels = np.asarray(face.convert("RGBA")).copy()
    clean_rgba = np.asarray(clean.convert("RGBA"), dtype=np.uint8)
    pixels[mask, :3] = clean_rgba[mask, :3]
    cleaned = Image.fromarray(pixels, "RGBA")
    if DEBUG:
        debug = np.asarray(face.convert("RGB")).copy()
        debug[mask] = (255, 0, 0)
        Image.fromarray(debug, "RGB").save(UI / "_needle_mask.png")

    scaled = cleaned.resize(BOX, Image.LANCZOS)
    alpha = np.asarray(scaled.getchannel("A")).copy()
    alpha[alpha < 8] = 0
    scaled.putalpha(Image.fromarray(alpha, "L"))
    MASTERS.mkdir(parents=True, exist_ok=True)
    scaled.save(MASTERS / "ui_gauge_face.png")
    print(f"wrote {MASTERS.name}/ui_gauge_face.png {scaled.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
