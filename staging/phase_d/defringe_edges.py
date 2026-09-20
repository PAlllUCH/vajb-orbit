"""Re-key the anti-aliased edge band of sprites keyed from a light background.

Some Phase B/D sprites were keyed off a light source background. The matte is
soft: pixels inside the boundary band (0 < alpha < 250) still carry near-white
RGB (band mean luminance around 168 of 255, 61 percent of band pixels above
175) while the emblem interior is dark (opaque mean luminance 38 to 51). Alpha
compositing multiplies that RGB by the partial alpha, so on a dark backdrop the
band reads as a white halo around the emblem.

cleanup_fringe.py does not catch these: it targets *opaque* near-white pixels
adjacent to outer transparency (alpha < 16), and these files instead have a wide
anti-aliased band, so it reports 0 files for the ui family.

This pass leaves alpha untouched and rewrites only the band RGB: for every pixel
with 0 < alpha < 250 the RGB is replaced by the RGB of the nearest fully opaque
pixel (alpha >= 250), located with an EDT distance transform over the matte, so
the replacement colour follows the local interior. Pixels with alpha == 0 and
with alpha == 255 keep their exact RGB bytes. Files with no band pixels or no
opaque pixels are skipped. Files that would not change are not rewritten, which
makes the pass idempotent at the byte level: a second --apply is a no-op.

Files are backed up once to staging/phase_d/_fringe_backup before their first
modification; an existing backup is never overwritten. Dry run by default.

Run: py -3.14 staging/phase_d/defringe_edges.py [--apply] [paths ...]
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
BACKUP = Path(__file__).resolve().parent / "_fringe_backup"

BAND_LO = 1
BAND_HI = 249
OPAQUE = 250
DEFAULT_TARGETS = (
    "ui/ui_insignia_neutral.png",
    "ui/ui_insignia_mic.png",
    "ui/ui_insignia_ven.png",
    "ui/ui_insignia_mmo.png",
)


def luminance(rgb: np.ndarray) -> np.ndarray:
    """ITU-R 601-2 weights, the same L PIL derives from RGB."""
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def resolve(arg: str) -> Path:
    """Absolute path, or a path relative to cwd, or a path under assets/."""
    path = Path(arg)
    if path.is_absolute():
        return path
    cwd_candidate = Path.cwd() / path
    return cwd_candidate if cwd_candidate.exists() else ASSETS / path


def defringe(path: Path, apply: bool) -> dict | None:
    """Advance one file. Returns a report row, or None when there is no band."""
    image = Image.open(path)
    arr = np.array(image.convert("RGBA"))
    alpha = arr[..., 3]
    opaque = alpha >= OPAQUE
    band = (alpha >= BAND_LO) & (alpha <= BAND_HI)
    if not band.any() or not opaque.any():
        return None

    _, indices = ndi.distance_transform_edt(~opaque, return_indices=True)
    nearest = arr[indices[0], indices[1], :3]
    updated = arr.copy()
    updated[..., :3] = np.where(band[..., None], nearest, arr[..., :3])

    changed = int(((updated[..., :3] != arr[..., :3]).any(axis=2) & band).sum())
    lum_before = luminance(arr[..., :3])[band]
    lum_after = luminance(updated[..., :3])[band]

    if apply and changed:
        BACKUP.mkdir(parents=True, exist_ok=True)
        dest = BACKUP / path.name
        if not dest.exists():
            shutil.copy2(path, dest)
        Image.fromarray(updated, "RGBA").save(path)

    return {
        "file": path.name,
        "band": int(band.sum()),
        "lum_before": float(lum_before.mean()),
        "lum_after": float(lum_after.mean()),
        "changed": changed,
    }


def main() -> None:
    argv = sys.argv[1:]
    apply = "--apply" in argv
    args = [a for a in argv if a != "--apply"]
    targets = [resolve(a) for a in args] if args else [ASSETS / t for t in DEFAULT_TARGETS]

    print(f"{'band':>6} {'lumBef':>7} {'lumAft':>7} {'changed':>8}  file")
    files = missing = changed_total = 0
    for path in targets:
        if not path.exists():
            missing += 1
            print(f"{'-':>6} {'-':>7} {'-':>7} {'-':>8}  MISSING {path}")
            continue
        row = defringe(path, apply)
        if row is None:
            continue
        print(
            f"{row['band']:>6} {row['lum_before']:>7.1f} {row['lum_after']:>7.1f} "
            f"{row['changed']:>8}  {path.name}"
        )
        files += 1
        changed_total += row["changed"]
    verb = "changed" if apply else "would change"
    status = "APPLIED" if apply else "DRY RUN"
    print(f"{status}: {files} files, {changed_total} edge pixels {verb}, {missing} missing")


if __name__ == "__main__":
    main()
