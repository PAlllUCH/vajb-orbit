#!/usr/bin/env python3
"""Cut a chrome-fit generation sheet into one RGBA file per rail.

The S37 chrome-fit generations render several horizontal rails stacked in a
single column. This slices them into one centred, transparent file per rail,
which is what ChromeFamily.CUT consumes.

Background modes:
  alpha       the source already carries real alpha (qwen2-1 --transparent)
  luminance   a near-white / fake-transparency checker background (seedream)
  pink        the flat magenta #FF00FF key background (gpt-image-2-5 flare)

Segmentation is by ink rows: contiguous row runs where alpha survives are the
bands, and each band is cropped to its own ink bounding box. Objects are found
by masking the ink, never by cutting on a divider.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image, ImageFilter


def luminance_alpha(img, thresh):
    """alpha=0 for near-white background pixels, 255 for the dark plate."""
    rgb = img.convert("RGB")
    lum = rgb.convert("L")
    a = lum.point(lambda v: 0 if v >= thresh else 255)
    # drop 1px speckle from JPEG grain, then soften the cut edge
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    return a


def checker_alpha(img, thresh=190, erode=2):
    """alpha=0 for a light fake-transparency checker background.

    Thresholding alone leaves a light fringe where the plate's thin steel bevel
    is close in luminance to the background. Instead: mask the light pixels,
    erode so the thin bevel drops out, flood-fill the background from the sheet
    border over what remains, then dilate back to recover the true boundary.
    """
    from collections import deque

    light = img.convert("L").point(lambda v: 255 if v >= thresh else 0)
    k = 2 * erode + 1
    er = light.filter(ImageFilter.MinFilter(k))
    w, h = er.size
    ep = er.load()
    seen = bytearray(w * h)
    dq = deque()

    def push(x, y):
        i = y * w + x
        if not seen[i] and ep[x, y] > 127:
            seen[i] = 1
            dq.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                i = ny * w + nx
                if not seen[i] and ep[nx, ny] > 127:
                    seen[i] = 1
                    dq.append((nx, ny))

    bg = Image.new("L", (w, h), 0)
    bp = bg.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            if seen[row + x]:
                bp[x, y] = 255
    bg = bg.filter(ImageFilter.MaxFilter(k))
    alpha = bg.point(lambda v: 0 if v > 127 else 255)
    return alpha.filter(ImageFilter.GaussianBlur(0.6))


def pink_alpha(img, dist):
    """alpha=0 for magenta background pixels within `dist` of #FF00FF."""
    rgb = img.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    a = Image.new("L", (w, h), 255)
    ap = a.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            d = abs(r - 255) + abs(g - 0) + abs(b - 255)
            ap[x, y] = 0 if d < dist else 255
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    return a


def band_runs(alpha, min_ink=1):
    """Contiguous row runs that contain ink."""
    w, h = alpha.size
    ap = alpha.load()
    runs = []
    start = None
    for y in range(h):
        has = any(ap[x, y] > 8 for x in range(w))
        if has and start is None:
            start = y
        elif not has and start is not None:
            if y - start >= min_ink:
                runs.append((start, y))
            start = None
    if start is not None and h - start >= min_ink:
        runs.append((start, h))
    return runs


def crop_band(img, alpha, y0, y1):
    """Crop a row band to its own column ink box."""
    w = alpha.size[0]
    ap = alpha.load()
    x0, x1 = w, 0
    for y in range(y0, y1):
        for x in range(w):
            if ap[x, y] > 8:
                if x < x0:
                    x0 = x
                if x > x1:
                    x1 = x
    if x1 < x0:
        return None
    return (x0, y0, x1 + 1, y1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--mode", choices=("alpha", "luminance", "checker", "pink"), default="alpha")
    ap.add_argument("--lum-thresh", type=int, default=180)
    ap.add_argument("--checker-thresh", type=int, default=190)
    ap.add_argument("--checker-erode", type=int, default=2)
    ap.add_argument("--pink-dist", type=int, default=60)
    ap.add_argument("--min-ink", type=int, default=12)
    ap.add_argument("--min-band", type=int, default=8)
    ap.add_argument("--pad", type=int, default=0)
    args = ap.parse_args()

    img = Image.open(args.src).convert("RGBA")
    if args.mode == "alpha":
        alpha = img.getchannel("A")
    elif args.mode == "luminance":
        alpha = luminance_alpha(img, args.lum_thresh)
    elif args.mode == "checker":
        alpha = checker_alpha(img, args.checker_thresh, args.checker_erode)
    else:
        alpha = pink_alpha(img, args.pink_dist)

    img.putalpha(alpha)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    runs = band_runs(alpha, min_ink=args.min_band)
    saved = []
    for i, (y0, y1) in enumerate(runs, 1):
        box = crop_band(img, alpha, y0, y1)
        if box is None:
            continue
        x0, yy0, x1, yy1 = box
        p = args.pad
        box = (max(0, x0 - p), max(0, yy0 - p), min(img.width, x1 + p), min(img.height, yy1 + p))
        piece = img.crop(box)
        # recentre on its own canvas (object may not sit dead centre in its box)
        path = out / f"{args.prefix}_{i}.png"
        piece.save(path)
        bw, bh = piece.size
        saved.append((path.name, bw, bh, round(bw / bh, 2)))
    for name, bw, bh, ar in saved:
        print(f"{name}\t{bw}x{bh}\t{ar}:1")
    print(f"[cut] {len(saved)} rails -> {out}")


if __name__ == "__main__":
    sys.exit(main())
