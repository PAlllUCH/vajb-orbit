"""Ad-hoc measurement helper for the D6 insignia defringe task (not a deliverable).

stats <paths...>            per-file band/luminance/alpha/hash table
diff <before> <after>       pixel-level before/after comparison of one pair
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

BAND_LO = 1
BAND_HI = 249
OPAQUE = 250
HIGH_LUM = 175


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def load(path: str) -> tuple[Image.Image, np.ndarray]:
    im = Image.open(path)
    return im, np.array(im.convert("RGBA"))


def stats(path: str) -> dict:
    im, arr = load(path)
    alpha = arr[..., 3]
    lum = luminance(arr[..., :3])
    band = (alpha >= BAND_LO) & (alpha <= BAND_HI)
    opaque = alpha >= OPAQUE
    out = {
        "file": Path(path).name,
        "size": [im.width, im.height],
        "mode": im.mode,
        "png_info_keys": sorted(im.info.keys()),
        "band_pixels": int(band.sum()),
        "band_mean_lum": round(float(lum[band].mean()), 3) if band.any() else None,
        "band_max_lum": round(float(lum[band].max()), 2) if band.any() else None,
        "band_frac_gt175": round(float((lum[band] > HIGH_LUM).mean()), 6) if band.any() else None,
        "band_gt175_pixels": int((lum[band] > HIGH_LUM).sum()) if band.any() else None,
        "opaque_pixels": int(opaque.sum()),
        "opaque_mean_lum": round(float(lum[opaque].mean()), 3) if opaque.any() else None,
        "opaque_gt175_pixels": int((lum[opaque] > HIGH_LUM).sum()) if opaque.any() else None,
        "alpha0_pixels": int((alpha == 0).sum()),
        "alpha255_pixels": int((alpha == 255).sum()),
        "alpha_sha256": hashlib.sha256(alpha.tobytes()).hexdigest(),
        "file_sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest(),
    }
    return out


def diff(before: str, after: str) -> dict:
    _, b = load(before)
    _, f = load(after)
    ba, fa = b[..., 3], f[..., 3]
    rgb_changed = (b[..., :3] != f[..., :3]).any(axis=2)
    band = (ba >= BAND_LO) & (ba <= BAND_HI)
    return {
        "file": Path(after).name,
        "dims_identical": tuple(b.shape) == tuple(f.shape),
        "alpha_identical": bool(np.array_equal(ba, fa)),
        "rgb_changed_pixels": int(rgb_changed.sum()),
        "rgb_changed_where_alpha0": int((rgb_changed & (ba == 0)).sum()),
        "rgb_changed_where_alpha255": int((rgb_changed & (ba == 255)).sum()),
        "rgb_changed_in_band": int((rgb_changed & band).sum()),
        "band_pixels": int(band.sum()),
        "alpha_sha256_before": hashlib.sha256(ba.tobytes()).hexdigest(),
        "alpha_sha256_after": hashlib.sha256(fa.tobytes()).hexdigest(),
        "file_sha256_before": hashlib.sha256(Path(before).read_bytes()).hexdigest(),
        "file_sha256_after": hashlib.sha256(Path(after).read_bytes()).hexdigest(),
    }


def main() -> None:
    mode = sys.argv[1]
    if mode == "stats":
        for path in sys.argv[2:]:
            print(json.dumps(stats(path)))
    elif mode == "diff":
        before, after = sys.argv[2], sys.argv[3]
        print(json.dumps(diff(before, after)))
    else:
        raise SystemExit("mode must be stats or diff")


if __name__ == "__main__":
    main()
