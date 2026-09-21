"""D5b measurement and settings helpers.

Subcommands:
  windowed          set user://settings.cfg to display_mode 0 and 1920x1080
  restore           restore user://settings.cfg from the backup
  uiscale N         set user://settings.cfg ui_scale to N
  info FRAME        report frame size, plate bands, text ink, contrast
  contrast FRAME    report WCAG contrast for named regions
  plates FRAME      locate the slot plate bands and their art
"""

import os
import re
import sys

from PIL import Image
import numpy as np

USER_DIR = r"C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit"
SETTINGS = os.path.join(USER_DIR, "settings.cfg")
BACKUP = r"C:\Users\Kamil\AppData\Local\Temp\vajb_d5\settings.cfg.bak"

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


def luminance(rgb):
    srgb = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def contrast(a, b):
    la = luminance(a)
    lb = luminance(b)
    hi = np.maximum(la, lb)
    lo = np.minimum(la, lb)
    return (hi + 0.05) / (lo + 0.05)


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
    return text[: match.start(2)] + body + text[match.end(2) :]


def cmd_windowed():
    text = read_settings()
    text = set_key(text, "graphics", "display_mode", "0")
    text = set_key(text, "graphics", "resolution", "Vector2i(1920, 1080)")
    text = set_key(text, "interface", "ui_scale", "1.0")
    write_settings(text)
    sys.stdout.write(text)


def cmd_uiscale(value):
    text = read_settings()
    text = set_key(text, "interface", "ui_scale", value)
    write_settings(text)
    sys.stdout.write(text)


def cmd_resolution(width, height):
    text = read_settings()
    text = set_key(text, "graphics", "display_mode", "0")
    text = set_key(text, "graphics", "resolution", "Vector2i(%s, %s)" % (width, height))
    write_settings(text)
    sys.stdout.write(text)


def cmd_restore():
    with open(BACKUP, "r", encoding="utf-8") as handle:
        write_settings(handle.read())
    sys.stdout.write(read_settings())


def load_frame(path):
    image = Image.open(path).convert("RGB")
    return image, np.array(image)


def ink_boxes(arr, region, threshold):
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1]
    lum = luminance(sub)
    mask = lum >= threshold
    if not mask.any():
        return None
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    return (x0 + int(cols[0]), y0 + int(rows[0]), x0 + int(cols[-1]), y0 + int(rows[-1]))


def bright_text_rgb(arr, region, top_fraction=0.02):
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    lum = luminance(sub)
    cut = np.quantile(lum, 1.0 - top_fraction)
    picked = sub[lum >= cut]
    return picked.mean(axis=0)


def background_rgb(arr, region, low_fraction=0.4):
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    lum = luminance(sub)
    cut = np.quantile(lum, low_fraction)
    picked = sub[lum <= cut]
    return picked.mean(axis=0)


def cmd_info(path):
    image, arr = load_frame(path)
    print("frame", os.path.basename(path), image.size, "mode", image.mode)
    lum = luminance(arr)
    print("mean luminance", round(float(lum.mean()), 2))
    print("p99 luminance", round(float(np.quantile(lum, 0.99)), 2))
    for name, rgb in TOKENS.items():
        print("  token", name, "present pixels", int((np.abs(arr.astype(int) - np.array(rgb)).max(axis=2) <= 1).sum()))


def cmd_rail(path):
    _, arr = load_frame(path)
    lum = luminance(arr)
    band = lum[:, 24:384]
    print("rail band columns 24..384 mean", round(float(band.mean()), 2))
    rows = lum.mean(axis=1)
    print("row luminance 0,20,40,60,80,1000,1060", [round(float(rows[i]), 2) for i in (0, 20, 40, 60, 80, 1000, 1056)])


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "info"
    if command == "windowed":
        cmd_windowed()
    elif command == "resolution":
        cmd_resolution(sys.argv[2], sys.argv[3])
    elif command == "restore":
        cmd_restore()
    elif command == "uiscale":
        cmd_uiscale(sys.argv[2])
    elif command == "info":
        cmd_info(sys.argv[2])
    elif command == "rail":
        cmd_rail(sys.argv[2])
    else:
        raise SystemExit("unknown command " + command)
