#!/usr/bin/env python3
"""D11-R1 independent pixel probe: AC2 hero footprint + §6 one-emissive + §9 accent scan."""
import colorsys, glob, os
from PIL import Image

POI = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "env", "poi")
OLD_SCALE = 0.0663
HERO_SCALE = 0.1459


def hue_sat(r, g, b):
    h, s, _ = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    return h * 360.0, s


def is_ember_hue(h):
    return h >= 340.0 or h <= 40.0


def scan(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    total = visible = hot = hot_ember = accent = ink = 0
    hot_hues = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            total += 1
            if a == 0:
                continue
            visible += 1
            if a <= 8:
                continue
            ink += 1
            hu, s = hue_sat(r, g, b)
            # A1's hot definition: r > 170 and r - b > 80
            if r > 170 and (r - b) > 80:
                hot += 1
                hot_hues.append(hu)
                if is_ember_hue(hu):
                    hot_ember += 1
            # §9: no second accent - sat > 0.6, hue outside the ember window,
            # bright visible art only (mx > 45), matching wave_d11.accent_share
            if s > 0.6 and not is_ember_hue(hu) and max(r, g, b) > 45:
                accent += 1
    return w, h, total, visible, ink, hot, hot_ember, hot_hues, accent


def main():
    files = sorted(glob.glob(os.path.join(POI, "env_station_*.png")))
    files = [f for f in files if not any(k in f for k in ("_mmo", "_ruined"))]
    print(f"{'file':30} {'size':11} {'transp%':>8} {'hot':>6} {'hot_frac':>9} {'emberOfHot%':>11} {'accent_frac':>11}")
    for f in files:
        w, h, total, visible, ink, hot, hot_ember, hot_hues, accent = scan(f)
        name = os.path.basename(f)
        mean_hue = (sum(hot_hues) / len(hot_hues)) if hot_hues else float("nan")
        print(
            f"{name:30} {w}x{h:<6} {100.0 * (total - visible) / total:8.1f} {hot:6d} "
            f"{hot / max(ink, 1):9.5f} {100.0 * hot_ember / max(hot, 1):11.1f} "
            f"{accent / max(ink, 1):11.5f} meanHotHue={mean_hue:.0f}"
        )

    def bbox(path):
        im = Image.open(path).convert("RGBA")
        return im.size, im.getchannel("A").getbbox()

    (ow, oh), obb = bbox(os.path.join(POI, "env_station.png"))
    (hw, hh), hbb = bbox(os.path.join(POI, "env_station_hero.png"))
    old_half = ow * OLD_SCALE / 2.0
    new_half = hw * HERO_SCALE / 2.0
    print()
    print(f"old env_station.png {ow}x{oh} alpha_bbox={obb}")
    print(f"hero {hw}x{hh} alpha_bbox={hbb}")
    print(f"frame half-extent: old={old_half:.2f} u new={new_half:.2f} u ratio={new_half / old_half:.4f}")
    old_c = (obb[2] - obb[0]) * OLD_SCALE / 2.0
    new_c = (hbb[2] - hbb[0]) * HERO_SCALE / 2.0
    print(f"content half-extent: old={old_c:.2f} u new={new_c:.2f} u ratio={new_c / old_c:.4f}")
    print(f"new frame half vs brief's 67.9 u pin: {new_half / 67.9:.4f}")


if __name__ == "__main__":
    main()
