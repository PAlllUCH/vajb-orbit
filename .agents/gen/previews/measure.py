"""D5b pixel measurements for the station mockup renders.

Usage: py -3.14 measure.py <command> [args]

Commands:
  layout FRAME               panel frame lines, rail and host extents
  ink FRAME X0 Y0 X1 Y1 THR  ink bbox and peak inside a region
  contrast FRAME X0 Y0 X1 Y1 text vs background contrast inside a region
  plates FRAME               slot plate bands (weapon 48, cargo 40)
  scale FRAME1 FRAME2 X0 Y0 X1 Y1   compare ink height and width between two frames
  white FRAME                count of near-white pixels (entry flash check)
  rows FRAME X0 X1 Y0 Y1     horizontal row bands inside a pane
"""

import os
import sys

from PIL import Image
import numpy as np

TOKENS = {
    "void_base": (0x07, 0x09, 0x0d),
    "void_panel": (0x0b, 0x0f, 0x15),
    "void_panel_raised": (0x10, 0x15, 0x1d),
    "metal_dark": (0x1b, 0x20, 0x28),
    "metal_mid": (0x2a, 0x31, 0x3c),
    "metal_light": (0x3d, 0x46, 0x54),
    "text_primary": (0xc9, 0xd1, 0xdc),
    "text_dim": (0x6b, 0x74, 0x84),
    "accent_danger": (0xc8, 0x47, 0x1f),
    "accent_danger_bright": (0xe8, 0x62, 0x2a),
}


def load(path):
    image = Image.open(path).convert("RGB")
    return np.array(image).astype(np.float64)


def lum_linear(rgb):
    srgb = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def lum_srgb(arr):
    return 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]


def contrast_of(a, b):
    la = float(lum_linear(a))
    lb = float(lum_linear(b))
    hi = max(la, lb)
    lo = min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def region(arr, x0, y0, x1, y1):
    return arr[y0:y1, x0:x1].reshape(-1, 3)


def ink_stats(arr, box, threshold):
    x0, y0, x1, y1 = box
    sub = arr[y0:y1, x0:x1]
    lum = lum_srgb(sub)
    mask = lum >= threshold
    count = int(mask.sum())
    if count == 0:
        return None
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    flat = sub.reshape(-1, 3)
    picked = flat[lum.reshape(-1) >= threshold]
    peak = flat[lum.reshape(-1).argmax()]
    return {
        "count": count,
        "box": (x0 + int(cols[0]), y0 + int(rows[0]), x0 + int(cols[-1]), y0 + int(rows[-1])),
        "height": int(rows[-1] - rows[0] + 1),
        "width": int(cols[-1] - cols[0] + 1),
        "ink_rgb": tuple(round(float(v), 1) for v in picked.mean(axis=0)),
        "peak_rgb": tuple(int(v) for v in peak),
        "peak": round(float(lum.max()), 1),
    }


def background_rgb(arr, box, quantile=0.5):
    flat = region(arr, *box)
    lum = lum_srgb(flat)
    cut = np.quantile(lum, quantile)
    picked = flat[lum <= cut]
    return tuple(round(float(v), 1) for v in picked.mean(axis=0))


def cmd_layout(path):
    arr = load(path)
    lum = lum_srgb(arr)
    height, width = lum.shape
    print("frame %s  %dx%d" % (os.path.basename(path), width, height))
    bright = (lum > 70).sum(axis=0)
    cols = [x for x in range(width) if bright[x] > 300]
    groups = []
    for x in cols:
        if groups and x - groups[-1][-1] <= 2:
            groups[-1].append(x)
        else:
            groups.append([x])
    print("vertical bright lines (x, rows>300 threshold):", [(g[0], g[-1]) for g in groups])
    rowbright = (lum > 70).sum(axis=1)
    rows = [y for y in range(height) if rowbright[y] > 400]
    rgroups = []
    for y in rows:
        if rgroups and y - rgroups[-1][-1] <= 2:
            rgroups[-1].append(y)
        else:
            rgroups.append([y])
    print("horizontal bright lines (y spans):", [(g[0], g[-1]) for g in rgroups])


def cmd_ink(path, x0, y0, x1, y1, threshold):
    arr = load(path)
    stats = ink_stats(arr, (int(x0), int(y0), int(x1), int(y1)), float(threshold))
    print("ink", stats)


def cmd_contrast(path, x0, y0, x1, y1):
    arr = load(path)
    box = (int(x0), int(y0), int(x1), int(y1))
    stats = ink_stats(arr, box, float(np.quantile(lum_srgb(region(arr, *box)), 0.995)))
    if stats is None:
        print("no ink")
        return
    bg = background_rgb(arr, box, 0.6)
    print("region", box)
    print("  ink rgb", stats["ink_rgb"], "peak", stats["peak_rgb"], "px", stats["count"])
    print("  background rgb", bg)
    print("  contrast ink vs background: %.2f:1" % contrast_of(stats["ink_rgb"], bg))
    print("  contrast peak vs background: %.2f:1" % contrast_of(stats["peak_rgb"], bg))


def plate_band(arr, box, size):
    """Return the number of distinct plate cells of `size` found in a box."""
    x0, y0, x1, y1 = box
    sub = arr[y0:y1, x0:x1]
    lum = lum_srgb(sub)
    mask = lum > 26
    colsum = mask.sum(axis=0)
    groups = []
    for x in range(x1 - x0):
        if colsum[x] > size * 0.5:
            if groups and x - groups[-1][-1] <= 2:
                groups[-1].append(x)
            else:
                groups.append([x])
    return [(x0 + g[0], x0 + g[-1], g[-1] - g[0] + 1) for g in groups]


def cmd_plates(path, ycenter, x0, x1):
    arr = load(path)
    yc = int(ycenter)
    stats = plate_band(arr, (int(x0), yc - 40, int(x1), yc + 40), 48)
    print("plate columns (x0, x1, width):", stats)
    for start, end, width in stats:
        cell = arr[yc - 24 : yc + 24, start : end + 1]
        print(
            "  cell x %d..%d width %d mean rgb %s"
            % (start, end, width, tuple(round(float(v), 1) for v in cell.reshape(-1, 3).mean(axis=0)))
        )


def cmd_white(path):
    arr = load(path)
    flat = arr.reshape(-1, 3)
    white = ((flat[:, 0] > 200) & (flat[:, 1] > 200) & (flat[:, 2] > 200)).sum()
    print("near-white pixels (>200 on all channels):", int(white))


def cmd_rows(path, x0, x1, y0, y1):
    arr = load(path)
    sub = arr[int(y0) : int(y1), int(x0) : int(x1)]
    lum = lum_srgb(sub)
    rowmax = lum.max(axis=1)
    bands = []
    current = None
    for index, value in enumerate(rowmax):
        if value > 60:
            if current is None:
                current = [index, index]
            else:
                current[1] = index
        else:
            if current is not None and current[1] - current[0] > 1:
                bands.append((int(y0) + current[0], int(y0) + current[1]))
            current = None
    if current is not None:
        bands.append((int(y0) + current[0], int(y0) + current[1]))
    print("bright bands (y0, y1):", bands)


def cmd_scale(path_a, path_b, x0, y0, x1, y1):
    box = (int(x0), int(y0), int(x1), int(y1))
    for path in (path_a, path_b):
        arr = load(path)
        stats = ink_stats(arr, box, float(np.quantile(lum_srgb(region(arr, *box)), 0.99)))
        print(os.path.basename(path), "ink box", stats["box"], "h", stats["height"], "w", stats["width"], "peak", stats["peak"])


def cmd_scan(path, axis, fixed, start, end):
    arr = load(path)
    lum = lum_srgb(arr)
    fixed = int(fixed)
    values = []
    for pos in range(int(start), int(end)):
        if axis == "x":
            values.append((pos, round(float(lum[fixed, pos]), 1)))
        else:
            values.append((pos, round(float(lum[pos, fixed]), 1)))
    text = " ".join("%d:%s" % (pos, value) for pos, value in values)
    print("scan %s=%d from %s to %s" % (axis, fixed, start, end))
    print(text)


def cmd_blob(path, x0, y0, x1, y1, block, threshold):
    arr = load(path)
    lum = lum_srgb(arr)[int(y0) : int(y1), int(x0) : int(x1)]
    size = int(block)
    rows = lum.shape[0] // size * size
    cols = lum.shape[1] // size * size
    reduced = lum[:rows, :cols].reshape(rows // size, size, cols // size, size).mean(axis=(1, 3))
    mask = reduced > float(threshold)
    if not mask.any():
        print("no blob")
        return
    ys = np.where(mask.any(axis=1))[0]
    xs = np.where(mask.any(axis=0))[0]
    box = (
        int(x0) + int(xs[0]) * size,
        int(y0) + int(ys[0]) * size,
        int(x0) + int(xs[-1] + 1) * size,
        int(y0) + int(ys[-1] + 1) * size,
    )
    print(
        "blob block=%d thr=%s box=%s size=%dx%d blocks=%d"
        % (size, threshold, box, box[2] - box[0], box[3] - box[1], int(mask.sum()))
    )
    core = arr[box[1] : box[3], box[0] : box[2]].reshape(-1, 3)
    print("  mean rgb in box", tuple(round(float(v), 1) for v in core.mean(axis=0)))


def cmd_profile(path, axis, fixed0, fixed1, start, end):
    arr = load(path)
    lum = lum_srgb(arr)
    values = []
    for pos in range(int(start), int(end)):
        if axis == "x":
            values.append(round(float(lum[int(fixed0) : int(fixed1), pos].mean()), 1))
        else:
            values.append(round(float(lum[pos, int(fixed0) : int(fixed1)].mean()), 1))
    print("profile %s over %s..%s, other axis %s..%s" % (axis, start, end, fixed0, fixed1))
    print(" ".join(str(v) for v in values))


def cmd_ascii(path, x0, y0, x1, y1, block):
    arr = load(path)
    lum = lum_srgb(arr)[int(y0) : int(y1), int(x0) : int(x1)]
    size = int(block)
    rows = lum.shape[0] // size
    cols = lum.shape[1] // size
    reduced = lum[: rows * size, : cols * size].reshape(rows, size, cols, size).mean(axis=(1, 3))
    ramp = " .:-=+*#%@"
    print("ascii map x %s..%s y %s..%s block %d" % (x0, x1, y0, y1, size))
    for row in reduced:
        line = "".join(ramp[min(len(ramp) - 1, int(v / 12.0))] for v in row)
        print(line)


def cmd_strip(path, x0, y0, x1, y1, gap):
    """Detect plate cells inside a strip: contiguous runs above the local floor."""
    arr = load(path)
    sub = arr[int(y0) : int(y1), int(x0) : int(x1)]
    lum = lum_srgb(sub)
    colmean = lum.mean(axis=0)
    floor = float(np.quantile(colmean, 0.15))
    limit = floor + 6.0
    runs = []
    start = None
    for index, value in enumerate(colmean):
        if value >= limit:
            if start is None:
                start = index
        else:
            if start is not None:
                runs.append((start, index - 1))
                start = None
    if start is not None:
        runs.append((start, len(colmean) - 1))
    merged = []
    for run in runs:
        if merged and run[0] - merged[-1][1] <= int(gap):
            merged[-1] = (merged[-1][0], run[1])
        else:
            merged.append(list(run))
    print("strip %s floor=%.1f limit=%.1f" % ((int(x0), int(y0), int(x1), int(y1)), floor, limit))
    for start, end in merged:
        cell = sub[:, start : end + 1]
        cell_lum = lum_srgb(cell)
        print(
            "  cell x %d..%d width %d mean %.1f max %.1f"
            % (
                int(x0) + start,
                int(x0) + end,
                end - start + 1,
                float(cell_lum.mean()),
                float(cell_lum.max()),
            )
        )


def cmd_deviation(path, x0, y0, x1, y1, axis, threshold):
    """Per-column (or row) standard deviation, and the extent above a threshold."""
    arr = load(path)
    lum = lum_srgb(arr)[int(y0) : int(y1), int(x0) : int(x1)]
    profile = lum.std(axis=0) if axis == "x" else lum.std(axis=1)
    limit = float(threshold)
    hits = np.where(profile > limit)[0]
    if len(hits) == 0:
        print("deviation: nothing above", limit)
        return
    offset = int(x0) if axis == "x" else int(y0)
    print(
        "deviation on %s over %s: first %d last %d extent %d px, peak std %.1f"
        % (axis, (int(x0), int(y0), int(x1), int(y1)), offset + int(hits[0]), offset + int(hits[-1]), int(hits[-1] - hits[0] + 1), float(profile.max()))
    )


def cmd_accent(path, x0, y0, x1, y1):
    """Locate accent_danger / accent_danger_bright pixels (warm orange)."""
    arr = load(path)
    sub = arr[int(y0) : int(y1), int(x0) : int(x1)]
    red = sub[..., 0]
    green = sub[..., 1]
    blue = sub[..., 2]
    mask = (red > 120) & (red - blue > 50) & (green < red * 0.75) & (green > blue)
    count = int(mask.sum())
    print("accent pixels in %s: %d" % ((int(x0), int(y0), int(x1), int(y1)), count))
    if count == 0:
        return
    ys = np.where(mask.any(axis=1))[0]
    xs = np.where(mask.any(axis=0))[0]
    print(
        "  bbox x %d..%d y %d..%d  size %dx%d"
        % (
            int(x0) + int(xs[0]),
            int(x0) + int(xs[-1]),
            int(y0) + int(ys[0]),
            int(y0) + int(ys[-1]),
            int(xs[-1] - xs[0] + 1),
            int(ys[-1] - ys[0] + 1),
        )
    )
    cols = np.where(mask.sum(axis=0) >= 8)[0]
    if len(cols):
        print("  solid columns (>=8 accent px): %d" % len(cols))
    flat = sub[mask]
    print("  mean accent rgb", tuple(round(float(v), 1) for v in flat.mean(axis=0)), "count", count)


def cmd_mean(path, x0, y0, x1, y1):
    arr = load(path)
    sub = arr[int(y0) : int(y1), int(x0) : int(x1)].reshape(-1, 3)
    print(
        "%s region %s mean rgb %s max %s"
        % (
            os.path.basename(path),
            (int(x0), int(y0), int(x1), int(y1)),
            tuple(round(float(v), 1) for v in sub.mean(axis=0)),
            tuple(int(v) for v in sub.max(axis=0)),
        )
    )


if __name__ == "__main__":
    command = sys.argv[1]
    args = sys.argv[2:]
    if command == "layout":
        cmd_layout(args[0])
    elif command == "mean":
        cmd_mean(*args)
    elif command == "accent":
        cmd_accent(*args)
    elif command == "strip":
        cmd_strip(*args)
    elif command == "deviation":
        cmd_deviation(*args)
    elif command == "ascii":
        cmd_ascii(*args)
    elif command == "blob":
        cmd_blob(*args)
    elif command == "profile":
        cmd_profile(*args)
    elif command == "scan":
        cmd_scan(*args)
    elif command == "ink":
        cmd_ink(*args)
    elif command == "contrast":
        cmd_contrast(*args)
    elif command == "plates":
        cmd_plates(*args)
    elif command == "white":
        cmd_white(args[0])
    elif command == "rows":
        cmd_rows(*args)
    elif command == "scale":
        cmd_scale(*args)
    else:
        raise SystemExit("unknown command " + command)
