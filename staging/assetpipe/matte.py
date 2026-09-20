"""Alpha matte for generated sheets. See docs/design/ASSET_PIPELINE_V2.md.

The v1 matte (staging/phase_d/reprocess.py) keyed every pixel within a fixed distance of the
estimated background. Measured against the raw renders, 51-76% of the area it keyed out was
rendered artwork, not background: a hull's own shadowed panels sit inside that distance, so
the matte punched blotches through every ship, prop and icon.

This matte makes the background/artwork decision from two pieces of evidence instead of one:

  * `mask`   - colour distance to the estimated background, as before.
  * `sealed` - the mask closed and hole-filled, which establishes "inside the object".

Any pixel that is inside the object but outside the mask was deleted by the distance test
alone. Whether it was really background or really artwork is then decided by how far its
*raw* colour sits from the background: near-background stays transparent (this is what keeps
a genuine aperture such as the jump gate ring open, with no per-asset allow list), anything
further is artwork and is restored.

Edge treatment is unchanged from v1 (a small Gaussian on the final mask) on purpose, so
nothing that F.1/F.2 approved for edge quality regresses.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

# ---------------------------------------------------------------- defaults

BORDER_STEP = 8
VOID_THRESHOLD = 8       # colour distance that separates object from a void background
# v1 used 16, which is above the distance of a hull's own shadowed plating (measured 12.3)
# and of every dithered dark fringe, so it deleted rendered artwork across all families.
# The distance map is smoothed first (see DIST_SMOOTH_SIGMA), which drops background noise
# to roughly 1 count, so 8 is still close to eight sigma clear of the noise floor.
WHITE_THRESHOLD = 40     # a white source is much further from any hull colour
VOID_TOL = 8.0           # "this raw pixel really was background" tolerance
WHITE_TOL = 16.0
SEAL_ITERATIONS = 3      # 3x3 closing passes that seal a thin channel into the silhouette
MIN_COMPONENT_FRAC = 0.00005   # drop opaque islands below this share of the sheet (stars)
MIN_RESTORE_FRAC = 0.00005     # drop restored art specks below this share (noise)
FEATHER_RADIUS = 0.8
# The renders carry a soft ambient glow around every object. Keying its falloff directly
# produces a cloud of one-to-five pixel islands hugging the silhouette, so the distance map
# is smoothed before thresholding: background noise (sigma ~5) drops well under the
# threshold while the object edge, an order of magnitude stronger, survives intact.
DIST_SMOOTH_SIGMA = 1.5
# A hole is damage when its raw pixels are rendered surface rather than background. Texture
# separates them cleanly on this project's art: laplacian std measures ~1.8 for flat
# background, 3.0-4.8 for hull shadow, 14.6 for lit hull. A colour-distance test cannot do
# this job - it is the same statistic that built the mask, so it always agrees with itself.
TEXTURE_ART = 3.0
MIN_HOLE_PX = 64   # an enclosed region smaller than this is anti-aliasing, not a hole


@dataclass
class SheetResult:
    alpha: np.ndarray
    mask: np.ndarray
    sealed: np.ndarray
    mode: str
    background: tuple[int, int, int]
    restored_px: int = 0
    dropped_px: int = 0
    notes: list[str] = field(default_factory=list)


def estimate_background(rgb: np.ndarray, step: int = BORDER_STEP) -> tuple[int, int, int]:
    """Median colour of a border ring. Robust to content bleeding into one edge."""
    h, w = rgb.shape[:2]
    ring = np.concatenate([
        rgb[1:5, :, :].reshape(-1, 3), rgb[h - 5:h - 1, :, :].reshape(-1, 3),
        rgb[:, 1:5, :].reshape(-1, 3), rgb[:, w - 5:w - 1, :].reshape(-1, 3),
    ])
    ring = ring[:: max(1, len(ring) // 20000)]
    return tuple(int(v) for v in np.median(ring, axis=0))


def classify_background(bg: tuple[int, int, int]) -> str:
    """`void`, `white` or `warm`.

    `warm` is the ember-vignette case: a full-frame additive overlay whose background is
    part of the effect, so it must not be keyed at all.
    """
    r, g, b = bg
    if sum(bg) / 3 > 128:
        return "white"
    if r > b + 24:
        return "warm"
    return "void"


def _distance(rgb: np.ndarray, bg: tuple[int, int, int]) -> np.ndarray:
    return np.max(np.abs(rgb - np.array(bg, dtype=np.float32)), axis=2)


def _drop_small(mask: np.ndarray, min_area: int) -> tuple[np.ndarray, int]:
    labels, count = ndimage.label(mask)
    if count == 0:
        return mask, 0
    areas = ndimage.sum(mask, labels, range(1, count + 1))
    keep = np.zeros(count + 1, dtype=bool)
    keep[1:] = areas >= min_area
    dropped = int(mask.sum() - (areas * keep[1:]).sum())
    return keep[labels], dropped


def build_alpha(image: Image.Image, *, feather: float = FEATHER_RADIUS,
                background: tuple[int, int, int] | None = None,
                mode: str | None = None) -> SheetResult:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    bg = background if background is not None else estimate_background(rgb)
    if mode is None:
        mode = classify_background(bg)

    if mode == "warm":
        return SheetResult(
            alpha=np.full(rgb.shape[:2], 255, dtype=np.uint8), mask=np.ones(rgb.shape[:2], bool),
            sealed=np.ones(rgb.shape[:2], bool), mode=mode, background=bg,
            notes=["warm-background overlay: kept fully opaque, never keyed"],
        )

    threshold = WHITE_THRESHOLD if mode == "white" else VOID_THRESHOLD
    tolerance = WHITE_TOL if mode == "white" else VOID_TOL
    dist = _distance(rgb, bg)
    smooth = ndimage.gaussian_filter(dist, DIST_SMOOTH_SIGMA)
    sheet_px = rgb.shape[0] * rgb.shape[1]

    mask, dropped = _drop_small(smooth > threshold, max(1, int(MIN_COMPONENT_FRAC * sheet_px)))

    # Seal thin channels to the outside, then treat everything enclosed as object interior.
    structure = ndimage.generate_binary_structure(2, 2)
    sealed = ndimage.binary_fill_holes(
        ndimage.binary_closing(mask, structure, iterations=SEAL_ITERATIONS)
    )

    interior = sealed & ~mask
    notes: list[str] = []
    restored = 0
    if interior.any():
        artwork = interior & (dist > tolerance)
        artwork, dropped_art = _drop_small(artwork, max(1, int(MIN_RESTORE_FRAC * sheet_px)))
        restored = int(artwork.sum())
        if restored:
            mask = mask | artwork
            notes.append(f"restored {restored} px of artwork the distance test deleted "
                         f"({100 * restored / max(1, int(interior.sum())):.0f}% of the "
                         f"{int(interior.sum())} px inside the silhouette)")
        dropped += dropped_art
        dropped += int(interior.sum()) - restored - int(((interior & (dist <= tolerance)).sum()))

    alpha = Image.fromarray((mask * 255).astype(np.uint8))
    if feather:
        alpha = alpha.filter(ImageFilter.GaussianBlur(feather))
    alpha_arr = np.array(alpha, dtype=np.uint8, copy=True)

    # Semi-transparent interior is never legitimate: the art is solid. Only the outer edge
    # may be soft, so anything interior that came back blurry is forced opaque.
    core = ndimage.binary_erosion(mask, structure, iterations=2)
    alpha_arr[core & (alpha_arr < 255)] = 255

    return SheetResult(alpha=alpha_arr, mask=mask, sealed=sealed, mode=mode, background=bg,
                       restored_px=restored, dropped_px=dropped, notes=notes)


def art_tolerance(mode: str) -> float:
    """Tolerance that means "this raw pixel really was background" for a background mode."""
    return WHITE_TOL if mode == "white" else VOID_TOL


def grayscale(image: Image.Image) -> np.ndarray:
    """Raw luminance, for the texture half of the QC metric."""
    return np.asarray(image.convert("L"))


def estimate_background_for_sprite(rgb: np.ndarray, alpha: np.ndarray) -> tuple[tuple[int, int, int] | None, str]:
    """Background colour of an already-keyed sprite, read from its transparent pixels.

    A border ring is not usable on a shipped cut: a button plate fills its frame and a
    narrow hull touches the edge, so the ring is content rather than background. The
    transparent pixels are the better evidence, because the v1 matte only ever wrote the
    alpha channel - their RGB is still the render.

    The background is the *dominant* colour among them rather than the median. Damage can
    cover more of the transparent area than the background does, but artwork spreads over
    hundreds of distinct colours while the background is one flat colour plus speckle, so
    the most populated colour bucket is the background even when it is a minority of the
    area.

    Validated before use: the estimate must sit closer to the bulk of the transparent
    pixels than to the opaque ones, which fails loudly rather than guessing.
    """
    clear = alpha <= CLEAR_MAX
    count = int(clear.sum())
    if count < 16:
        return None, f"only {count} transparent pixels, nothing to derive a background from"
    px = rgb[clear]
    quantised = np.clip((px // 16).astype(np.int16), 0, 15)
    keys = quantised[:, 0] * 256 + quantised[:, 1] * 16 + quantised[:, 2]
    values, counts = np.unique(keys, return_counts=True)
    bucket = values[int(np.argmax(counts))]
    bg = tuple(int(v) for v in np.median(px[keys == bucket], axis=0))
    solid = alpha >= SOLID_MIN
    if not solid.any():
        return None, "no opaque pixels to validate against"
    dist = _distance(rgb, bg)
    if np.median(dist[clear]) >= np.median(dist[solid]):
        return None, ("background estimate does not separate the transparent area from "
                      "the object; needs review rather than a guess")
    return bg, ""


CLEAR_MAX = 8      # alpha at or below this is a hole; the 0.8 px feather ring is not
SOLID_MIN = 200


def alpha_metrics(alpha: np.ndarray, gray: np.ndarray | None = None) -> dict:
    """QC numbers for a cut: how much of its enclosed transparent area is damage.

    A hole is a region the player sees the backdrop through, so only near-fully
    transparent pixels count as clear. Anti-aliased edge pixels sit between the two
    thresholds and belong to the object, which keeps the 0.8 px feather from registering
    as thousands of one-pixel holes.

    Damage is then decided by the *texture* of the raw pixels in each enclosed region:
    flat background reads ~1.8 laplacian std, rendered surface ~3.0 and up. This is
    deliberately not a colour-distance test, because the mask was built from colour
    distance and such a test would simply agree with itself.
    """
    solid = alpha >= SOLID_MIN
    clear = alpha <= CLEAR_MAX
    labels, _ = ndimage.label(clear)
    if not labels.any():
        return {"silhouette_px": int(solid.sum()), "enclosed_px": 0, "art_loss_px": 0,
                "art_loss_pct": 0.0, "hole_blobs": 0}
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    enclosed = clear & ~np.isin(labels, list(border)) if border else clear
    # A thin opaque detail (panel line, antenna, fin) drops below CLEAR_MAX along its
    # middle once the 0.8 px feather is applied, so it reads as a chain of tiny enclosed
    # regions. Only regions large enough to be seen as a hole count.
    enclosed, _ = _drop_small(enclosed, MIN_HOLE_PX)
    enclosed_px = int(enclosed.sum())

    art_loss = 0
    blobs = 0
    if enclosed_px and gray is not None:
        lap = ndimage.laplace(ndimage.gaussian_filter(gray.astype(np.float32), 1.0))
        regions, count = ndimage.label(enclosed)
        damage = np.zeros(enclosed.shape, dtype=bool)
        for index in range(1, count + 1):
            region = regions == index
            if float(lap[region].std()) > TEXTURE_ART:
                damage |= region
        art_loss = int(damage.sum())
        if art_loss:
            _, blobs = ndimage.label(damage)
    return {
        "silhouette_px": int(solid.sum()),
        "enclosed_px": enclosed_px,
        "art_loss_px": art_loss,
        "art_loss_pct": round(100 * art_loss / max(1, enclosed_px), 2),
        "hole_blobs": int(blobs),
    }


def distance_for(image: Image.Image) -> np.ndarray:
    """Colour distance to the estimated background, for QC on a cut."""
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    return _distance(rgb, estimate_background(rgb))


def load(path: Path) -> Image.Image:
    return Image.open(path)


def save_rgba(image: Image.Image, alpha: np.ndarray, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    out = image.convert("RGBA")
    out.putalpha(Image.fromarray(alpha))
    out.save(dest)
    return dest


def _with_alpha(image: Image.Image, alpha: np.ndarray) -> Image.Image:
    out = image.convert("RGBA")
    out.putalpha(Image.fromarray(alpha))
    return out
