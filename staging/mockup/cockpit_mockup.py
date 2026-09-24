#!/usr/bin/env python3
"""cockpit_mockup.py — D7 cockpit rework look mockup (design pass, not shipping art).

v2: bare seven-segment drums (no per-cell plates), rim-wedge speed arc, rows fit
their wells, leading blanks per UI_SPEC section 3.7. Box 464x256 logical at 2x
(928x512); interior 400x192 (800x384); bays 252 / 208 / 312 with 14 gutters.
Rose/lubber/needle composite the shipped masters.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

random.seed(7)

S = 2
W, H = 928, 512

METAL = (42, 46, 53)
METAL_MID = (86, 92, 99)
METAL_DARK = (26, 29, 34)
VOID = (21, 24, 29)
BONE = (201, 205, 210)
DIM = (122, 130, 138)
EMBER = (200, 70, 27)
EMBER_BRIGHT = (232, 112, 58)
GHOST = (52, 57, 65)

ASSETS = "vajb-orbit/assets/ui"
OUT = "staging/mockup/out"

CELL_W, CELL_H, GAP = 40, 72, 4
PITCH = CELL_W + GAP

SEGS = {
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
    "5": "afgcd", "6": "afgecd", "7": "abc", "8": "abcdefg", "9": "abcdfg",
    "blank": "", "pct": "",
}

ROWS = [
    ("SPD", ["blank", "blank", "4", "2"], False),
    ("HULL", ["1", "2", "5", "0"], False),
    ("SHLD", ["blank", "8", "0", "0"], False),
    ("FUEL", ["blank", "1", "5", "pct"], True),
    ("ENRG", ["1", "0", "0", "pct"], False),
]


def font(px: int):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(p, px)
        except OSError:
            continue
    return ImageFont.load_default()


F_LABEL = font(21)
F_SMALL = font(21)


def brushed(w: int, h: int, base=METAL) -> Image.Image:
    img = Image.new("RGB", (w, h), base)
    px = img.load()
    for y in range(h):
        row_shift = random.randint(-6, 6)
        sheen = int(10 * math.sin(math.pi * y / max(h - 1, 1)))
        for x in range(w):
            r, g, b = px[x, y]
            n = row_shift + sheen + random.randint(-2, 2)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
    return img.filter(ImageFilter.GaussianBlur(0.4))


def bevel(img: Image.Image, box, light=METAL_MID, dark=METAL_DARK, w=3):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    d.line([(x0, y0), (x1, y0)], fill=light, width=w)
    d.line([(x0, y0), (x0, y1)], fill=light, width=w)
    d.line([(x1, y0), (x1, y1)], fill=dark, width=w)
    d.line([(x0, y1), (x1, y1)], fill=dark, width=w)


def recess(img: Image.Image, box, fill=VOID, radius=14):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, radius=radius, fill=fill)
    bevel(img, box, light=METAL_DARK, dark=METAL_MID, w=3)
    d.rounded_rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), radius=radius - 3, outline=(34, 38, 45), width=1)


def bolt(img: Image.Image, cx, cy, r=9):
    d = ImageDraw.Draw(img)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(58, 63, 71))
    d.arc((cx - r, cy - r, cx + r, cy + r), 180, 360, fill=METAL_MID, width=2)
    d.arc((cx - r, cy - r, cx + r, cy + r), 0, 180, fill=METAL_DARK, width=2)
    d.line([(cx - r + 3, cy), (cx + r - 3, cy)], fill=METAL_DARK, width=2)


def disc_well(img: Image.Image, cx, cy, r):
    d = ImageDraw.Draw(img)
    d.ellipse((cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8), fill=(36, 40, 47))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=VOID)
    d.arc((cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5), 200, 340, fill=METAL_MID, width=3)
    d.arc((cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5), 20, 160, fill=METAL_DARK, width=3)


def gauge(img: Image.Image, cx, cy, r, ratio=0.62, prograde_deg=-40):
    """Speed dial: 10 rim wedges across 270 deg (gap at bottom), 8 graduated ticks,
    prograde needle. NO heading tick (the section 3.6 amendment)."""
    d = ImageDraw.Draw(img)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(31, 35, 41))
    d.ellipse((cx - r + 8, cy - r + 8, cx + r - 8, cy + r - 8), fill=(24, 27, 33))
    a0, sweep = 135.0, 270.0
    r_out, r_in = r - 14, r - 34
    for i in range(10):
        f0 = a0 + sweep * (i / 10.0) + 1.5
        f1 = a0 + sweep * ((i + 1) / 10.0) - 1.5
        col = METAL_MID if i < round(ratio * 10) else (44, 48, 55)
        if i < round(ratio * 10):
            col = (116, 123, 132)
        d.pieslice((cx - r_out, cy - r_out, cx + r_out, cy + r_out), f0, f1, fill=col)
    d.ellipse((cx - r_in, cy - r_in, cx + r_in, cy + r_in), fill=(24, 27, 33))
    for i in range(8):
        frac = i / 7.0
        ang = math.radians(a0 + sweep * frac)
        toward_top = 1.0 - abs(frac - 0.5) * 2.0
        ln = 8 + int(10 * toward_top)
        r0, r1 = r - 6, r - 6 - ln
        col = BONE if toward_top > 0.7 else METAL_MID
        d.line([(cx + r0 * math.cos(ang), cy + r0 * math.sin(ang)),
                (cx + r1 * math.cos(ang), cy + r1 * math.sin(ang))], fill=col, width=3)
    ang = math.radians(prograde_deg - 90)
    nx, ny = cx + (r - 44) * math.cos(ang), cy + (r - 44) * math.sin(ang)
    d.line([(cx, cy), (nx, ny)], fill=BONE, width=4)
    d.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=METAL_MID)
    d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=METAL_DARK)


def seg_glyph(d: ImageDraw.Draw, x, y, name):
    """Bare seven-segment drum in a 40x72 cell: lit BONE, unlit ghost."""
    t = 6
    hx0, hx1 = x + 8, x + 32
    ytop, ymid, ybot = y + 8, y + 36, y + 64
    geom = {
        "a": ("h", hx0, hx1, ytop), "g": ("h", hx0, hx1, ymid), "d": ("h", hx0, hx1, ybot),
        "f": ("v", x + 8, y + 10, y + 34), "b": ("v", x + 32, y + 10, y + 34),
        "e": ("v", x + 8, y + 38, y + 62), "c": ("v", x + 32, y + 38, y + 62),
    }
    lit = set(SEGS[name])
    for key, g in geom.items():
        col = BONE if key in lit else GHOST
        if g[0] == "h":
            _, x0, x1, yy = g
            d.rounded_rectangle((x0, yy - t // 2, x1, yy + t // 2), radius=t // 2, fill=col)
        else:
            _, xx, y0, y1 = g
            d.rounded_rectangle((xx - t // 2, y0, xx + t // 2, y1), radius=t // 2, fill=col)
    if name == "pct":
        col = BONE
        d.line([(x + 30, y + 12), (x + 10, y + 60)], fill=col, width=5)
        d.ellipse((x + 6, y + 8, x + 14, y + 16), fill=col)
        d.ellipse((x + 26, y + 56, x + 34, y + 64), fill=col)


def draw_row(img: Image.Image, x, y, label_text, cells, danger=False, label_zone=72):
    dd = ImageDraw.Draw(img)
    if danger:
        dd.rectangle((x - 4, y - 3, x + label_zone + 4 + len(cells) * PITCH, y + CELL_H + 2),
                     outline=EMBER, width=2)
    bb = dd.textbbox((0, 0), label_text, font=F_LABEL)
    dd.text((x, y + (CELL_H - (bb[3] - bb[1])) // 2 - bb[1],), label_text, font=F_LABEL,
            fill=EMBER_BRIGHT if danger else DIM)
    cx = x + label_zone + 2
    for name in cells:
        seg_glyph(dd, cx, y, name)
        cx += PITCH


def battery_squares(img, x0, y0, selected=1):
    d = ImageDraw.Draw(img)
    for i in range(5):
        x = x0 + i * 50
        box = (x, y0, x + 44, y0 + 44)
        if i == selected:
            d.rounded_rectangle((x - 3, y0 - 3, x + 47, y0 + 47), radius=7, outline=(96, 52, 32), width=2)
            d.rounded_rectangle(box, radius=5, fill=(52, 34, 24), outline=EMBER_BRIGHT, width=3)
            col = EMBER_BRIGHT
        else:
            d.rounded_rectangle(box, radius=5, fill=(36, 40, 47), outline=METAL_DARK, width=2)
            col = DIM
        t = f"B{i + 1}"
        bb = d.textbbox((0, 0), t, font=F_SMALL)
        d.text((x + (44 - (bb[2] - bb[0])) / 2 - bb[0],
                y0 + (44 - (bb[3] - bb[1])) / 2 - bb[1]), t, font=F_SMALL, fill=col)


def cardinals(img, cx, cy, r, heading=13.0):
    d = ImageDraw.Draw(img)
    for txt, a in (("N", -90 - heading), ("E", -heading), ("S", 90 - heading), ("W", 180 - heading)):
        ang = math.radians(a)
        x, y = cx + r * math.cos(ang), cy + r * math.sin(ang)
        bb = d.textbbox((0, 0), txt, font=F_SMALL)
        col = BONE if txt == "N" else (150, 157, 165)
        d.text((x - (bb[2] - bb[0]) / 2 - bb[0], y - (bb[3] - bb[1]) / 2 - bb[1]),
               txt, font=F_SMALL, fill=col)


def main():
    base = brushed(W, H)
    d = ImageDraw.Draw(base)
    bevel(base, (2, 2, W - 3, H - 3), light=METAL_MID, dark=METAL_DARK, w=4)
    for (bx, by) in [(26, 26), (W - 27, 26), (26, H - 27), (W - 27, H - 27)]:
        bolt(base, bx, by)
    for bx in range(140, W - 120, 150):
        bolt(base, bx, 24, 7)
        bolt(base, bx, H - 25, 7)
    d.rectangle((56, 56, W - 57, H - 57), outline=(33, 37, 44), width=2)

    img = base.convert("RGBA")

    # left bay (2x: x 64..316): gauge + battery lamps + AMMO row (72 tall, foot-aligned)
    disc_well(img, 190, 172, 112)
    gauge(img, 190, 172, 106)
    battery_squares(img, 70, 302, selected=1)
    recess(img, (64, 370, 316, 442))
    draw_row(img, 66, 370, "AMMO", ["blank", "1", "7", "6"])

    # middle bay (2x: x 330..538): compass + HDG row (72 tall, foot-aligned)
    disc_well(img, 434, 172, 100)
    rose = Image.open(f"{ASSETS}/ui_compass_rose.png").convert("RGBA")
    rose = rose.rotate(13, resample=Image.BICUBIC)
    img.alpha_composite(rose, (434 - 96, 172 - 96))
    cardinals(img, 434, 172, 84, heading=13.0)
    lubber = Image.open(f"{ASSETS}/ui_compass_lubber.png").convert("RGBA")
    img.alpha_composite(lubber, (434 - 16, 70))
    recess(img, (330, 370, 538, 442))
    draw_row(img, 334, 370, "HDG", ["blank", "1", "3"])

    # right bay (2x: x 552..864): five readout rows
    recess(img, (558, 62, 858, 442))
    y = 66
    for name, cells, danger in ROWS:
        draw_row(img, 566, y, name, cells, danger)
        y += CELL_H + 4

    img.convert("RGB").save(f"{OUT}/cockpit_mockup_v2.png")
    img.convert("RGB").save(f"{OUT}/cockpit_mockup_v2.jpg", quality=86)
    print(f"wrote {OUT}/cockpit_mockup_v2.png + .jpg ({W}x{H})")


if __name__ == "__main__":
    main()
