"""D4b measurement and settings helpers for the main menu v2 mockup revision.

Subcommands:
  backup                  copy user://settings.cfg to the Temp backup
  set W H SCALE           write windowed WxH with ui_scale SCALE
  restore                 restore user://settings.cfg from the backup
  rail FRAME              housing-absence evidence over the region the rail occupied
  elements FRAME FACTOR   ink box, peak ink and contrast per element, regions scaled by FACTOR
  bands FRAME             row and column luminance profiles of the console column
  offscreen FRAME         composition checks: element extents inside the frame
"""

import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

USER_DIR = r"C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit"
SETTINGS = os.path.join(USER_DIR, "settings.cfg")
BACKUP = r"C:\Users\Kamil\AppData\Local\Temp\vajb_d4b\settings.cfg.bak"

TOKENS = {
    "void_base": (0x07, 0x09, 0x0D),
    "void_panel": (0x0B, 0x0F, 0x15),
    "void_panel_raised": (0x10, 0x15, 0x1D),
    "metal_dark": (0x1B, 0x20, 0x28),
    "metal_mid": (0x2A, 0x31, 0x3C),
    "metal_light": (0x3D, 0x46, 0x54),
    "text_primary": (0xC9, 0xD1, 0xDC),
    "text_dim": (0x6B, 0x74, 0x84),
    "accent_danger": (0xC8, 0x47, 0x1F),
    "accent_danger_bright": (0xE8, 0x62, 0x2A),
}

REGIONS = {
    "logo": (60, 40, 700, 240),
    "badge": (100, 480, 176, 560),
    "caption": (168, 480, 420, 560),
    "tick1": (88, 550, 112, 620),
    "plate1": (104, 545, 420, 620),
    "play_label": (200, 566, 340, 616),
    "plate2": (104, 615, 420, 690),
    "plate3": (104, 685, 420, 760),
    "readout": (90, 1004, 600, 1034),
    "stamp": (1600, 1004, 1840, 1034),
}

RAIL = (96, 469, 476, 783)


def luminance(rgb):
    srgb = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def luma(rgb):
    """Weighted sRGB mean, 0..255: a brightness locator, not a WCAG term."""
    arr = np.asarray(rgb, dtype=np.float64)
    return 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]


def contrast(a, b):
    la = float(luminance(np.asarray(a, dtype=np.float64)))
    lb = float(luminance(np.asarray(b, dtype=np.float64)))
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def load(path):
    image = Image.open(path).convert("RGB")
    return image, np.array(image)


def read_settings():
    with open(SETTINGS, "r", encoding="utf-8") as handle:
        return handle.read()


def write_settings(text):
    with open(SETTINGS, "w", encoding="utf-8") as handle:
        handle.write(text)


def set_key(text, section, key, value):
    pattern = re.compile(r"(\[" + section + r"\]\s*\n)(.*?)(?=\n\[|\Z)", re.S)
    match = pattern.search(text)
    body = match.group(2)
    if re.search(r"^" + key + r"=", body, re.M):
        body = re.sub(r"^" + key + r"=.*$", key + "=" + value, body, flags=re.M)
    else:
        body = body.rstrip("\n") + "\n" + key + "=" + value + "\n"
    return text[: match.start(2)] + body + text[match.end(2):]


def cmd_backup():
    shutil.copyfile(SETTINGS, BACKUP)
    print("backed up", SETTINGS, "->", BACKUP)
    sys.stdout.write(read_settings())


def cmd_set(width, height, scale):
    text = read_settings()
    text = set_key(text, "graphics", "display_mode", "0")
    text = set_key(text, "graphics", "resolution", "Vector2i(%s, %s)" % (width, height))
    text = set_key(text, "interface", "ui_scale", scale)
    write_settings(text)
    sys.stdout.write(text)


def cmd_restore():
    with open(BACKUP, "r", encoding="utf-8") as handle:
        write_settings(handle.read())
    sys.stdout.write(read_settings())


def ink_box(arr, region, threshold):
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1]
    lum = luma(sub)
    mask = lum >= threshold
    if not mask.any():
        return None, 0
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    box = (x0 + int(cols[0]), y0 + int(rows[0]), x0 + int(cols[-1]) + 1, y0 + int(rows[-1]) + 1)
    return box, int(mask.sum())


def text_measure(arr, region, text_fraction=0.02):
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    lum = luma(sub)
    cut = np.quantile(lum, 1.0 - text_fraction)
    ink = sub[lum >= cut]
    ink_peak = sub[int(np.argmax(lum))]
    bg = sub[lum <= cut * 0.75]
    bg_median = float(np.median(luma(bg))) if bg.size else float("nan")
    bg_median_rgb = np.median(bg, axis=0) if bg.size else np.zeros(3)
    ink_mean = ink.mean(axis=0)
    return {
        "ink_mean": ink_mean,
        "ink_peak": ink_peak,
        "ink_peak_lum": float(np.max(lum)),
        "bg_median_lum": bg_median,
        "bg_median_rgb": bg_median_rgb,
    }


def near(arr, rgb, tolerance=3):
    return int((np.abs(arr.astype(int) - np.array(rgb)).max(axis=2) <= tolerance).sum())

def cmd_rail(path, factor=1.0):
    factor = float(factor)
    image, arr = load(path)
    x0, y0, x1, y1 = (int(round(v * factor)) for v in RAIL)
    band = arr[y0:y1, x0:x1]
    lum = luma(band)
    print("frame", os.path.basename(path), image.size, "rail region", (x0, y0, x1, y1))
    print("  mean lum", round(float(lum.mean()), 2),
          "p95", round(float(np.quantile(lum, 0.95)), 2),
          "p99", round(float(np.quantile(lum, 0.99)), 2))
    for name in ("metal_dark", "metal_mid", "metal_light", "void_base"):
        print("  pixels within 6 of", name, near(band, TOKENS[name], 6))
    left = luma(arr[int(round(560 * factor)):int(round(660 * factor)),
                   int(round(90 * factor)):int(round(120 * factor))]).mean(axis=0)
    print("  left border column mean lum:", [round(float(v), 1) for v in left])
    top = luma(arr[int(round(455 * factor)):int(round(490 * factor)),
                  int(round(200 * factor)):int(round(320 * factor))]).mean(axis=1)
    print("  top border row mean lum:", [round(float(v), 1) for v in top])
    interior = luma(arr[int(round(500 * factor)):int(round(750 * factor)),
                        int(round(250 * factor)):int(round(460 * factor))])
    print("  interior patch mean lum", round(float(interior.mean()), 2),
          "p99", round(float(np.quantile(interior, 0.99)), 2))


def cmd_patch(path, x0, y0, x1, y1, factor):
    factor = float(factor)
    x0, y0, x1, y1 = float(x0), float(y0), float(x1), float(y1)
    image, arr = load(path)
    box = tuple(int(round(v * factor)) for v in (x0, y0, x1, y1))
    sub = arr[box[1]:box[3], box[0]:box[2]].reshape(-1, 3)
    lum = luma(sub)
    modal = np.median(sub, axis=0)
    print("frame", os.path.basename(path), image.size, "patch", (x0, y0, x1, y1),
          "->", box)
    print("  mean lum", round(float(lum.mean()), 2),
          "median lum", round(float(np.median(lum)), 2),
          "p95", round(float(np.quantile(lum, 0.95)), 2),
          "max", round(float(lum.max()), 2),
          "median rgb #%02x%02x%02x" % tuple(int(round(c)) for c in modal))


def cmd_match(path, x0, y0, x1, y1, token, tolerance, factor):
    factor = float(factor)
    x0, y0, x1, y1 = float(x0), float(y0), float(x1), float(y1)
    region = tuple(int(round(v * factor)) for v in (x0, y0, x1, y1))
    image, arr = load(path)
    sub = arr[region[1]:region[3], region[0]:region[2]]
    mask = np.abs(sub.astype(int) - np.array(TOKENS[token])).max(axis=2) <= int(tolerance)
    print("frame", os.path.basename(path), image.size, "region", region,
          "token", token, "tolerance", tolerance)
    if not mask.any():
        print("  no pixel matches")
        return
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    print("  px", int(mask.sum()),
          "box", (region[0] + int(cols[0]), region[1] + int(rows[0]),
                  region[0] + int(cols[-1]) + 1, region[1] + int(rows[-1]) + 1),
          "size", (int(cols[-1] - cols[0] + 1), int(rows[-1] - rows[0] + 1)))
    full_rows = np.where(mask.sum(axis=1) >= (cols[-1] - cols[0] + 1) // 2)[0]
    print("  rows carrying the full width of the match:",
          [region[1] + int(r) for r in full_rows])


def cmd_plates(path, x0, x1, y0, y1, threshold, min_run):
    x0, x1, y0, y1 = int(x0), int(x1), int(y0), int(y1)
    threshold, min_run = float(threshold), int(min_run)
    image, arr = load(path)
    lum = luma(arr)
    print("frame", os.path.basename(path), image.size, "x", x0, "..", x1 - 1,
          "y", y0, "..", y1 - 1, "threshold", threshold, "min run", min_run)
    hits = []
    for y in range(y0, y1):
        row = lum[y, x0:x1] >= threshold
        best = 0
        current = 0
        for value in row:
            current = current + 1 if value else 0
            best = max(best, current)
        if best >= min_run:
            hits.append((y, int(best)))
    print("  rows with a horizontal run >= %d:" % min_run, hits)


def cmd_col(path, x0, x1, y0, y1):
    x0, x1, y0, y1 = int(x0), int(x1), int(y0), int(y1)
    image, arr = load(path)
    lum = luma(arr)
    profile = lum[y0:y1, x0:x1].mean(axis=1)
    print("frame", os.path.basename(path), image.size, "columns", x0, "..", x1 - 1)
    for index, value in enumerate(profile):
        print("  y %4d %6.1f" % (y0 + index, float(value)))


def cmd_box(path, x0, y0, x1, y1, threshold, factor):
    factor = float(factor)
    x0, y0, x1, y1 = float(x0), float(y0), float(x1), float(y1)
    region = tuple(int(round(v * factor)) for v in (x0, y0, x1, y1))
    image, arr = load(path)
    measured = text_measure(arr, region)
    box, count = ink_box(arr, region, float(threshold))
    ratio = contrast(measured["ink_peak"], measured["bg_median_rgb"])
    print("frame", os.path.basename(path), image.size, "region", region,
          "threshold", threshold)
    print("  ink box", box, "px", count,
          "size", None if box is None else (box[2] - box[0], box[3] - box[1]),
          "peak lum", round(measured["ink_peak_lum"], 2),
          "bg", "#%02x%02x%02x" % tuple(int(round(c)) for c in measured["bg_median_rgb"]),
          "bg lum", round(measured["bg_median_lum"], 2),
          "contrast_peak", round(ratio, 2))


def cmd_runs(path, axis, a0, a1, b0, b1, threshold):
    image, arr = load(path)
    lum = luma(arr)
    a0, a1, b0, b1 = int(a0), int(a1), int(b0), int(b1)
    threshold = float(threshold)
    if axis.upper() == "R":
        profile = lum[b0:b1, a0:a1].mean(axis=1)
        offset = b0
        label = "rows y"
    else:
        profile = lum[b0:b1, a0:a1].mean(axis=0)
        offset = a0
        label = "columns x"
    runs = []
    start = None
    for index, value in enumerate(profile):
        if value > threshold and start is None:
            start = index
        elif value <= threshold and start is not None:
            runs.append((offset + start, offset + index - 1))
            start = None
    if start is not None:
        runs.append((offset + start, offset + len(profile) - 1))
    print("frame", os.path.basename(path), image.size, label, a0, "..", a1 - 1,
          "band", b0, "..", b1 - 1, "threshold", threshold)
    print("  runs:", runs)


def cmd_elements(path, factor):
    factor = float(factor)
    image, arr = load(path)
    print("frame", os.path.basename(path), image.size, "factor", factor)
    for name, region in REGIONS.items():
        scaled = tuple(int(round(v * factor)) for v in region)
        x0, y0, x1, y1 = scaled
        x1 = min(x1, arr.shape[1])
        y1 = min(y1, arr.shape[0])
        if x1 <= x0 or y1 <= y0:
            continue
        measured = text_measure(arr, (x0, y0, x1, y1))
        peak_box, count = ink_box(arr, (x0, y0, x1, y1), 60.0)
        ink = measured["ink_mean"]
        bg_rgb = measured["bg_median_rgb"]
        print("  %-11s %-24s box %-26s px %5d peaklum %6.2f ink %s "
              "bg %s lum %5.2f ratio_ink %5.2f ratio_peak %5.2f"
              % (name, str(scaled), str(peak_box), count, measured["ink_peak_lum"],
                 "#%02x%02x%02x" % tuple(int(round(c)) for c in ink),
                 "#%02x%02x%02x" % tuple(int(round(c)) for c in bg_rgb),
                 measured["bg_median_lum"], contrast(ink, bg_rgb),
                 contrast(measured["ink_peak"], bg_rgb)))


def cmd_bands(path):
    image, arr = load(path)
    lum = luma(arr)
    print("frame", os.path.basename(path), image.size)
    print("console column mean row lum x 88..410 at y 490,500,545,560,620,690,750:",
          [(y, round(float(lum[y, 88:410].mean()), 2)) for y in (490, 500, 545, 560, 620, 690, 750)])
    print("full-width row mean lum at y 96,250,500,626,900,1025:",
          [(y, round(float(lum[y].mean()), 2)) for y in (96, 250, 500, 626, 900, 1025)])
    print("column mean lum x 88..130 at y 600:", [round(float(v), 1) for v in lum[600, 88:130]])
    rows = np.where(lum[400:900, 88:410].mean(axis=1) > 45.0)[0]
    print("rows in 400..899 whose console-band mean exceeds 45:", (400 + rows).tolist()[:40])


def cmd_offscreen(path):
    image, arr = load(path)
    height, width = arr.shape[:2]
    lum = luma(arr)
    print("frame", os.path.basename(path), image.size)
    edges = {
        "top row 0": lum[0].mean(),
        "bottom row last": lum[-1].mean(),
        "left column 0": lum[:, 0].mean(),
        "right column last": lum[:, -1].mean(),
    }
    for name, value in edges.items():
        print("  edge", name, "mean lum", round(float(value), 2))
    bright = lum >= 60.0
    rows = np.where(bright.any(axis=1))[0]
    cols = np.where(bright.any(axis=0))[0]
    print("  pixels >= 60 lum:", int(bright.sum()),
          "rows", int(rows[0]), "..", int(rows[-1]),
          "cols", int(cols[0]), "..", int(cols[-1]),
          "of", width, "x", height)


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "elements"
    if command == "backup":
        cmd_backup()
    elif command == "set":
        cmd_set(sys.argv[2], sys.argv[3], sys.argv[4])
    elif command == "restore":
        cmd_restore()
    elif command == "rail":
        cmd_rail(sys.argv[2])
    elif command == "railold":
        cmd_rail(sys.argv[2], sys.argv[3])
    elif command == "patch":
        cmd_patch(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6],
                  sys.argv[7] if len(sys.argv) > 7 else 1.0)
    elif command == "match":
        cmd_match(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6],
                  sys.argv[7], sys.argv[8], sys.argv[9] if len(sys.argv) > 9 else 1.0)
    elif command == "plates":
        cmd_plates(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6],
                   sys.argv[7], sys.argv[8])
    elif command == "col":
        cmd_col(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
    elif command == "box":
        cmd_box(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6],
                sys.argv[7], sys.argv[8] if len(sys.argv) > 8 else 1.0)
    elif command == "runs":
        cmd_runs(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5],
                 sys.argv[6], sys.argv[7], sys.argv[8])
    elif command == "elements":
        cmd_elements(sys.argv[2], sys.argv[3])
    elif command == "bands":
        cmd_bands(sys.argv[2])
    elif command == "offscreen":
        cmd_offscreen(sys.argv[2])
    else:
        raise SystemExit("unknown command " + command)
