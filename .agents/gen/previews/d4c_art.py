"""D4c art inspection: plate border profile, emblem ink profile, texture sizes."""

import sys

import numpy as np
from PIL import Image

ASSETS = r"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit/assets"


def luma(rgb):
    arr = np.asarray(rgb, dtype=np.float64)
    return 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]


def show(path):
    image = Image.open(path)
    arr = np.array(image.convert("RGBA"))
    print(path.split("/")[-1], "size", image.size, "mode", image.mode)
    return arr


def profile(name, arr, mid_x, mid_y, span):
    lum = luma(arr[..., :3])
    alpha = arr[..., 3]
    print("  vertical profile x=%d, y 0..%d" % (mid_x, span - 1))
    for y in range(span):
        print("    y %2d lum %6.1f alpha %3d rgb %s" % (
            y, lum[y, mid_x], alpha[y, mid_x],
            "#%02x%02x%02x" % tuple(int(v) for v in arr[y, mid_x, :3])))
    print("  horizontal profile y=%d, x 0..%d" % (mid_y, span - 1))
    for x in range(span):
        print("    x %2d lum %6.1f alpha %3d rgb %s" % (
            x, lum[mid_y, x], alpha[mid_y, x],
            "#%02x%02x%02x" % tuple(int(v) for v in arr[mid_y, x, :3])))
    print("  interior patch y %d..%d x %d..%d mean lum %.2f" % (
        span, arr.shape[0] - span, span, arr.shape[1] - span,
        float(lum[span:arr.shape[0] - span, span:arr.shape[1] - span].mean())))


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "plate"
    if which == "plate":
        arr = show(ASSETS + "/ui/ui_button_plate_normal.png")
        profile("plate", arr, arr.shape[1] // 2, arr.shape[0] // 2, 12)
    elif which == "emblem":
        arr = show(ASSETS + "/ui/ui_insignia_neutral.png")
        lum = luma(arr[..., :3])
        alpha = arr[..., 3]
        mask = alpha > 40
        print("  alpha>40 px", int(mask.sum()), "of", arr.shape[0] * arr.shape[1])
        values = lum[mask]
        print("  ink lum min %.1f median %.1f mean %.1f p95 %.1f max %.1f" % (
            float(values.min()), float(np.median(values)), float(values.mean()),
            float(np.quantile(values, 0.95)), float(values.max())))
        print("  ink rgb mean", "#%02x%02x%02x" % tuple(
            int(v) for v in arr[..., :3][mask].mean(axis=0)))
    elif which == "logo":
        arr = show(ASSETS + "/ui/logo_vajb_orbit.png")
    else:
        raise SystemExit("unknown " + which)


main()
