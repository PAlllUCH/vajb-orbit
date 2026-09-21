"""D4c measurement and settings helpers for the main menu v2 mockup, final revision.

Subcommands:
  sha                     sha256 of user://settings.cfg
  set W H SCALE           write windowed WxH with ui_scale SCALE
  restore                 restore user://settings.cfg from the D4c backup
  elements FRAME FACTOR   ink box, peak ink and contrast per element, regions scaled by FACTOR
  plates FRAME            plate bands, row pitch, visible gap, plate box from the focus ring
  border FRAME            focus ring run thickness and the plate art's own bevel profile
  emblem FRAME FACTOR     emblem highlight and body ink against the backdrop-plus-grain behind it
  offscreen FRAME         composition checks: element extents inside the frame
"""

import hashlib
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

USER_DIR = r"C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit"
SETTINGS = os.path.join(USER_DIR, "settings.cfg")
BACKUP = r"C:\Users\Kamil\AppData\Local\Temp\vajb_d4c\settings.cfg.bak"

TOKENS = {
    "void_base": (0x07, 0x09, 0x0D),
    "metal_dark": (0x1B, 0x20, 0x28),
    "metal_mid": (0x2A, 0x31, 0x3C),
    "metal_light": (0x3D, 0x46, 0x54),
    "text_primary": (0xC9, 0xD1, 0xDC),
    "text_dim": (0x6B, 0x74, 0x84),
    "accent_danger_bright": (0xE8, 0x62, 0x2A),
}

REGIONS = {
    "logo": (60, 40, 700, 240),
    "badge": (108, 455, 184, 540),
    "tick1": (88, 530, 112, 620),
    "plate1": (104, 528, 480, 624),
    "play_label": (200, 550, 400, 602),
    "plate2": (104, 612, 480, 708),
    "plate3": (104, 696, 480, 792),
    "readout": (90, 1000, 700, 1036),
    "stamp": (1600, 1000, 1840, 1036),
}


def luminance(rgb):
    srgb = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def luma(rgb):
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


def cmd_sha():
    with open(SETTINGS, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    print("settings.cfg sha256", digest)
    print("settings.cfg sha256 short", digest[:16])
    sys.stdout.write(read_settings())


def cmd_set(width, height, scale):
    text = read_settings()
    text = set_key(text, "graphics", "display_mode", "0")
    text = set_key(text, "graphics", "resolution", "Vector2i(%s, %s)" % (width, height))
    text = set_key(text, "interface", "ui_scale", scale)
    write_settings(text)
    sys.stdout.write(text)


def cmd_restore():
    shutil.copyfile(BACKUP, SETTINGS)
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


def runs(profile, offset, threshold):
    found = []
    start = None
    for index, value in enumerate(profile):
        if value > threshold and start is None:
            start = index
        elif value <= threshold and start is not None:
            found.append((offset + start, offset + index - 1))
            start = None
    if start is not None:
        found.append((offset + start, offset + len(profile) - 1))
    return found


def cmd_plates(path, factor=1.0):
    factor = float(factor)
    image, arr = load(path)
    lum = luma(arr)
    x0 = int(round(104 * factor))
    x1 = int(round(480 * factor))
    y0 = int(round(500 * factor))
    y1 = int(round(820 * factor))
    profile = lum[y0:y1, x0:x1].mean(axis=1)
    print("frame", os.path.basename(path), image.size, "factor", factor)
    print("  row mean lum profile x %d..%d, threshold 35" % (x0, x1 - 1))
    bands = runs(profile, y0, 35.0)
    print("  plate bands:", bands,
          "heights:", [b[1] - b[0] + 1 for b in bands])
    for index in range(1, len(bands)):
        gap = bands[index][0] - bands[index - 1][1] - 1
        print("  gap between band %d and %d: %d rows (%d..%d)"
              % (index, index + 1, gap, bands[index - 1][1] + 1, bands[index][0] - 1))
    if len(bands) >= 2:
        pitch = bands[1][0] - bands[0][0]
        print("  row pitch %d" % pitch)
    print("  row tops and the gap in rows of backdrop between plate bottoms:")
    for y in range(y0, y1):
        row = lum[y, x0:x1]
        if y in [b[0] for b in bands] or (y - 1) in [b[1] for b in bands]:
            print("    y %4d mean %6.2f max %6.2f" % (y, float(row.mean()), float(row.max())))


def cmd_border(path, factor=1.0, row_top=541.0):
    factor = float(factor)
    image, arr = load(path)
    lum = luma(arr)
    accent = TOKENS["accent_danger_bright"]
    print("frame", os.path.basename(path), image.size, "factor", factor)
    plate_x0 = int(round(118 * factor))
    plate_x1 = int(round(468 * factor))
    plate_y0 = int(round(float(row_top) * factor))
    plate_y1 = plate_y0 + int(round(70 * factor)) - 1
    mid_x = (plate_x0 + plate_x1) // 2
    mid_y = (plate_y0 + plate_y1) // 2
    print("  plate 1 box x %d..%d y %d..%d, mid %d,%d"
          % (plate_x0, plate_x1, plate_y0, plate_y1, mid_x, mid_y))
    print("  focus ring rows at mid-plate x %d:" % mid_x)
    for y in range(plate_y0 - 3, plate_y0 + 5):
        px = arr[y, mid_x]
        print("    y %4d lum %6.2f rgb #%02x%02x%02x accent_match %s"
              % (y, lum[y, mid_x], px[0], px[1], px[2],
                 bool(np.abs(px.astype(int) - np.array(accent)).max() <= 6)))
    for y in range(plate_y1 - 4, plate_y1 + 4):
        px = arr[y, mid_x]
        print("    y %4d lum %6.2f rgb #%02x%02x%02x accent_match %s"
              % (y, lum[y, mid_x], px[0], px[1], px[2],
                 bool(np.abs(px.astype(int) - np.array(accent)).max() <= 6)))
    print("  focus ring columns at mid-plate y %d:" % mid_y)
    for x in list(range(plate_x0 - 2, plate_x0 + 4)) + list(range(plate_x1 - 3, plate_x1 + 3)):
        px = arr[mid_y, x]
        print("    x %4d lum %6.2f rgb #%02x%02x%02x accent_match %s"
              % (x, lum[mid_y, x], px[0], px[1], px[2],
                 bool(np.abs(px.astype(int) - np.array(accent)).max() <= 6)))
    tol = 6
    mask = np.abs(arr.astype(int) - np.array(accent)).max(axis=2) <= tol
    col = mask[plate_y0 - 3:plate_y1 + 3, mid_x]
    row = mask[mid_y, plate_x0 - 2:plate_x1 + 2]
    print("  accent pixels in the column at x %d:" % mid_x,
          runs(col.astype(float), plate_y0 - 3, 0.5))
    print("  accent pixels in the row at y %d:" % mid_y,
          runs(row.astype(float), plate_x0 - 2, 0.5))
    print("  plate art top bevel, rows %d..%d mean over x %d..%d:"
          % (plate_y0 - 2, plate_y0 + 12, plate_x0 + 30, plate_x1 - 30))
    band = lum[plate_y0 - 2:plate_y0 + 13, plate_x0 + 30:plate_x1 - 30].mean(axis=1)
    for index, value in enumerate(band):
        print("    y %4d mean %6.2f" % (plate_y0 - 2 + index, float(value)))
    print("  plate art left bevel, columns %d..%d mean over y %d..%d:"
          % (plate_x0 - 2, plate_x0 + 12, plate_y0 + 12, plate_y1 - 12))
    band = lum[plate_y0 + 12:plate_y1 - 12, plate_x0 - 2:plate_x0 + 13].mean(axis=0)
    for index, value in enumerate(band):
        print("    x %4d mean %6.2f" % (plate_x0 - 2 + index, float(value)))


def cmd_emblem(path, factor=1.0):
    factor = float(factor)
    image, arr = load(path)
    lum = luma(arr)
    region = tuple(int(round(v * factor)) for v in REGIONS["badge"])
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1]
    slum = lum[y0:y1, x0:x1]
    print("frame", os.path.basename(path), image.size, "region", region)
    ink_mask = slum >= 60.0
    box, count = ink_box(arr, region, 60.0)
    print("  ink box (lum >= 60)", box, "px", count)
    if count == 0:
        return
    ink = sub[ink_mask]
    ink_lum = slum[ink_mask]
    bg = sub[~ink_mask]
    bg_lum = slum[~ink_mask]
    bg_rgb = np.median(bg, axis=0)
    bx0, by0, bx1, by1 = box
    foot = lum[by0:by1, bx0:bx1].reshape(-1)
    print("  footprint (the ink box area, dark body included): px %d lum min %.1f "
          "median %.1f mean %.1f p90 %.1f max %.1f"
          % (int(foot.size), float(foot.min()), float(np.median(foot)),
             float(foot.mean()), float(np.quantile(foot, 0.90)), float(foot.max())))
    print("  ink lum: min %.1f median %.1f mean %.1f p90 %.1f max %.1f"
          % (float(ink_lum.min()), float(np.median(ink_lum)), float(ink_lum.mean()),
             float(np.quantile(ink_lum, 0.90)), float(ink_lum.max())))
    ink_mean_rgb = tuple(int(v) for v in ink.mean(axis=0))
    ink_peak_rgb = tuple(int(v) for v in ink[int(np.argmax(ink_lum))])
    print("  ink mean rgb #%02x%02x%02x, peak rgb #%02x%02x%02x"
          % (ink_mean_rgb[0], ink_mean_rgb[1], ink_mean_rgb[2],
             ink_peak_rgb[0], ink_peak_rgb[1], ink_peak_rgb[2]))
    bg_rgb_int = tuple(int(v) for v in bg_rgb)
    print("  backdrop+grain behind (region minus ink): median lum %.2f median rgb #%02x%02x%02x"
          % (float(np.median(bg_lum)), bg_rgb_int[0], bg_rgb_int[1], bg_rgb_int[2]))
    for name, value in (("peak highlight", ink[int(np.argmax(ink_lum))]),
                        ("p90 ink", ink[ink_lum >= np.quantile(ink_lum, 0.90)].mean(axis=0)),
                        ("mean ink", ink.mean(axis=0)),
                        ("median ink", ink[np.argsort(ink_lum)[len(ink_lum) // 2]])):
        print("  contrast %-14s lum %6.1f vs backdrop %5.2f:1"
              % (name, float(luma(np.asarray(value, dtype=np.float64))),
                 contrast(value, bg_rgb)))
    body = foot[foot < 60.0]
    if body.size:
        print("  body (footprint pixels under 60 lum): px %d median lum %.1f contrast %.2f:1"
              % (int(body.size), float(np.median(body)), contrast(
                  np.full(3, float(np.median(body))), bg_rgb)))
    for floor in (4.5, 3.0):
        need = floor * (float(luminance(np.asarray(bg_rgb, dtype=np.float64))) + 0.05) - 0.05
        srgb = np.where(need <= 0.0031308, need * 12.92, 1.055 * (max(need, 0.0) ** (1 / 2.4)) - 0.055)
        print("  ink pixels clearing %0.1f:1: %d of %d (%.1f %%), needs lum >= %.1f"
              % (floor, int((ink_lum >= float(srgb * 255.0)).sum()), int(count),
                 100.0 * float((ink_lum >= float(srgb * 255.0)).sum()) / float(count),
                 float(srgb * 255.0)))


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
    for threshold in (60.0, 120.0):
        bright = lum >= threshold
        if not bright.any():
            print("  no pixel >= %0.0f lum" % threshold)
            continue
        rows = np.where(bright.any(axis=1))[0]
        cols = np.where(bright.any(axis=0))[0]
        print("  pixels >= %3.0f lum: %5d rows %d..%d cols %d..%d of %dx%d"
              % (threshold, int(bright.sum()), int(rows[0]), int(rows[-1]),
                 int(cols[0]), int(cols[-1]), width, height))


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "elements"
    if command == "sha":
        cmd_sha()
    elif command == "set":
        cmd_set(sys.argv[2], sys.argv[3], sys.argv[4])
    elif command == "restore":
        cmd_restore()
    elif command == "elements":
        cmd_elements(sys.argv[2], sys.argv[3])
    elif command == "plates":
        cmd_plates(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 1.0)
    elif command == "border":
        cmd_border(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 1.0,
                   sys.argv[4] if len(sys.argv) > 4 else 541.0)
    elif command == "emblem":
        cmd_emblem(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 1.0)
    elif command == "offscreen":
        cmd_offscreen(sys.argv[2])
    else:
        raise SystemExit("unknown command " + command)
