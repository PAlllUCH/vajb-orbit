#!/usr/bin/env python3
"""mockup_rest.py — the remaining D7 look mockups (design pass, not shipping art).

A) armory_mockup.png    — the gun battery selection window (ARMORY console)
B) context_mockup.png   — the game frame with the new cockpit + old HUD gone
C) status_mockup.png    — the ship status modal on the instrument language

Reuses cockpit_mockup's painted-metal helpers; text stands for engine Labels.
"""
import glob
import math
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cockpit_mockup import (  # noqa: E402
    ASSETS, BONE, DIM, EMBER, EMBER_BRIGHT, F_LABEL, F_SMALL, GHOST,
    METAL, METAL_DARK, METAL_MID, VOID, bevel, bolt, brushed, cardinals,
    disc_well, font, gauge, recess, seg_glyph,
)

OUT = "staging/mockup/out"
F_HINT = font(17)
F_TINY = font(15)

random.seed(11)


def panel(canvas: Image.Image, inset_bolts=True):
    d = ImageDraw.Draw(canvas)
    bevel(canvas, (2, 2, canvas.width - 3, canvas.height - 3), light=METAL_MID, dark=METAL_DARK, w=4)
    if inset_bolts:
        w, h = canvas.size
        for (bx, by) in [(22, 22), (w - 23, 22), (22, h - 23), (w - 23, h - 23)]:
            bolt(canvas, bx, by, 8)


def mini_drums(d: ImageDraw.Draw, x, y, names, scale=1.0):
    for n in names:
        seg_glyph(d, x, y, n)
        x += int(44 * scale)


def find_ship(kind_hint="vanguard"):
    hits = sorted(glob.glob(f"vajb-orbit/assets/**/ship_*{kind_hint}*_side.png", recursive=True))
    if not hits:
        hits = sorted(glob.glob("vajb-orbit/assets/**/ship_*_side.png", recursive=True))
    return hits[0] if hits else None


def ship_sprite(width, hint="vanguard"):
    p = find_ship(hint)
    if not p:
        img = Image.new("RGBA", (width, width // 2), (90, 96, 104, 255))
        return img
    im = Image.open(p).convert("RGBA")
    ratio = width / im.width
    return im.resize((width, max(1, int(im.height * ratio))), Image.LANCZOS)


# ---------------------------------------------------------------- A: armory
def armory():
    W, H = 872, 908
    img = brushed(W, H).convert("RGBA")
    panel(img)
    d = ImageDraw.Draw(img)

    d.text((36, 30), "ARMORY", font=F_LABEL, fill=BONE)
    d.text((36, 58), "drag a weapon onto a rack  \u00b7  the salvo fires at the slowest member's cycle",
           font=F_HINT, fill=DIM)

    # --- well 1: BATTERY RACKS (7 bays, 4 + 3) ---
    d.text((36, 92), "BATTERY RACKS", font=F_SMALL, fill=DIM)
    recess(img, (30, 122, W - 30, 512))
    bay_w, bay_h = 194, 182
    fills = {0: ["laser"], 1: ["cannon", "cannon", "rocket"], 2: [], 3: ["laser", "cannon"],
             4: [], 5: ["rocket"], 6: []}
    salvos = ["073", "048", "150", "096", "120", "048", "150"]
    for i in range(7):
        col, row = i % 4, i // 4
        x = 44 + col * (bay_w + 8)
        y = 136 + row * (bay_h + 8)
        selected = (i == 1)
        if selected:
            d.rectangle((x - 3, y - 3, x + bay_w + 2, y + bay_h + 2), outline=EMBER_BRIGHT, width=2)
        recess(img, (x, y, x + bay_w, y + bay_h), radius=8)
        d.text((x + 10, y + 8), f"B{i + 1}", font=F_SMALL, fill=BONE if selected else DIM)
        d.text((x + bay_w - 34, y + 10), f"({i + 1})", font=F_TINY, fill=DIM)
        for s in range(4):
            sx = x + 10 + s * 44
            recess(img, (sx, y + 38, sx + 40, y + 82), radius=4)
            if s < len(fills[i]):
                d.rounded_rectangle((sx + 10, y + 48, sx + 30, y + 72), radius=3, fill=(96, 102, 110))
        bevel(img, (x + 8, y + 96, x + bay_w - 8, y + 100), light=METAL_DARK, dark=METAL_MID, w=2)
        d.text((x + 10, y + 112), "SALVO s", font=F_TINY, fill=DIM)
        cx = x + 64
        for ch in salvos[i]:
            seg_glyph(d, cx, y + 104, ch)
            cx += 42

    # --- well 2: INVENTORY ---
    d.text((36, 540), "INVENTORY", font=F_SMALL, fill=DIM)
    recess(img, (30, 570, W - 30, 740))
    inv = [("LASER MKI", "OWNED \u00d73"), ("CANNON MKI", "OWNED \u00d72"), ("ROCKET POD", "OWNED \u00d71")]
    for r, (name, owned) in enumerate(inv):
        y = 584 + r * 50
        bevel(img, (44, y, W - 44, y + 44), light=METAL_MID, dark=METAL_DARK, w=2)
        recess(img, (52, y + 4, 92, y + 40), radius=4)
        d.rounded_rectangle((62, y + 12, 82, y + 32), radius=3, fill=(96, 102, 110))
        d.text((108, y + 12), name, font=F_SMALL, fill=BONE)
        d.text((W - 190, y + 13), owned, font=F_SMALL, fill=DIM)

    # --- well 3: AMMUNITION ---
    d.text((36, 766), "AMMUNITION", font=F_SMALL, fill=DIM)
    recess(img, (30, 796, W - 30, 884))
    ammo = [("LASER CELLS", "HELD 30 / MAX 100", "240 CR", False),
            ("CANNON ROUNDS", "HELD 4 / MAX 60", "180 CR", True),
            ("ROCKETS", "HELD 12 / MAX 30", "400 CR", False)]
    for r, (name, held, price, danger) in enumerate(ammo):
        x = 44 + r * 266
        box = (x, 808, x + 254, 872)
        if danger:
            d.rectangle(box, outline=EMBER, width=2)
        bevel(img, box, light=METAL_MID, dark=METAL_DARK, w=2)
        d.text((x + 12, 814), name, font=F_SMALL, fill=EMBER_BRIGHT if danger else BONE)
        d.text((x + 12, 840), held, font=F_TINY, fill=EMBER_BRIGHT if danger else DIM)
        d.text((x + 170, 840), price, font=F_TINY, fill=DIM)

    img.convert("RGB").save(f"{OUT}/armory_mockup.png")
    img.convert("RGB").save(f"{OUT}/armory_mockup.jpg", quality=85)
    print("wrote armory_mockup")


# ------------------------------------------------------------- B: game context
def context():
    W, H = 1152, 648
    img = Image.new("RGBA", (W, H), (8, 10, 14, 255))
    d = ImageDraw.Draw(img)
    random.seed(5)
    for _ in range(160):
        x, y = random.randint(0, W - 1), random.randint(0, H - 1)
        c = random.randint(60, 170)
        d.point((x, y), fill=(c, c, c + 6))
    for i in range(3):
        cx, cy = random.randint(100, W - 100), random.randint(80, H - 200)
        d.ellipse((cx - 60, cy - 40, cx + 60, cy + 40), fill=(22, 26, 33))

    # station/gate hint top-right
    d.arc((W - 190, -60, W + 80, 210), 100, 320, fill=(60, 64, 72), width=26)
    d.arc((W - 165, -35, W + 55, 185), 100, 320, fill=(38, 42, 50), width=10)

    player = ship_sprite(120)
    img.alpha_composite(player, (W // 2 - player.width // 2, H // 2 - player.height // 2))
    foe = ship_sprite(70, "sibelon")
    fx, fy = W - 420, 170
    img.alpha_composite(foe, (fx - foe.width // 2, fy - foe.height // 2))
    for (ox, oy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
        x0, y0 = fx + ox * 44, fy + oy * 34
        d.line([(x0, y0), (x0 - ox * 14, y0)], fill=EMBER, width=1)
        d.line([(x0, y0), (x0, y0 - oy * 14)], fill=EMBER, width=1)
    d.rectangle((fx - 44, fy + 44, fx + 44, fy + 48), fill=(50, 55, 62))
    d.rectangle((fx - 44, fy + 44, fx + 10, fy + 48), fill=EMBER)

    # minimap bottom-right (section 3.3)
    mx, my = W - 232, H - 232
    panel(img.crop((mx - 6, my - 6, mx + 220, my + 224)).convert("RGBA"), inset_bolts=False)
    mm = brushed(216, 224)
    bevel(mm, (0, 0, 215, 223), light=METAL_MID, dark=METAL_DARK, w=3)
    ImageDraw.Draw(mm).rectangle((10, 10, 205, 185), fill=VOID, outline=(34, 38, 45))
    md = ImageDraw.Draw(mm)
    for (bx, by, col) in [(60, 120, BONE), (120, 90, EMBER), (150, 140, DIM), (95, 60, DIM), (175, 70, DIM)]:
        md.ellipse((bx - 3, by - 3, bx + 3, by + 3), fill=col)
    md.ellipse((102, 102, 122, 122), outline=METAL_MID)
    md.text((10, 194), "HALCYON REACH", font=F_TINY, fill=DIM)
    md.text((178, 194), "+  \u2212", font=F_TINY, fill=DIM)
    img.alpha_composite(mm.convert("RGBA"), (mx, my))

    # the new cockpit cluster bottom-left (v5 render at logical size)
    cl = Image.open(f"{OUT}/cockpit_mockup_v5.png").convert("RGBA").resize((464, 256), Image.LANCZOS)
    img.alpha_composite(cl, (8, H - 264))

    img.convert("RGB").save(f"{OUT}/context_mockup.png")
    img.convert("RGB").save(f"{OUT}/context_mockup.jpg", quality=85)
    print("wrote context_mockup")


# ------------------------------------------------------------- C: ship status
def status():
    W, H = 720, 520
    img = brushed(W, H).convert("RGBA")
    panel(img)
    d = ImageDraw.Draw(img)
    d.text((30, 22), "SHIP STATUS", font=F_LABEL, fill=BONE)
    d.rectangle((W - 52, 20, W - 26, 46), fill=(36, 40, 47), outline=METAL_DARK, width=2)
    d.text((W - 44, 22), "\u00d7", font=F_SMALL, fill=DIM)

    # left: hull render well + hardpoint markers
    recess(img, (24, 60, 300, 428))
    ship = ship_sprite(240)
    img.alpha_composite(ship, (42, 200 - ship.height // 2))
    md = ImageDraw.Draw(img)
    for (hx, hy) in [(80, 205), (120, 190), (170, 195), (215, 215), (145, 225)]:
        md.ellipse((hx - 5, hy - 5, hx + 5, hy + 5), outline=BONE, fill=EMBER)
    d.text((44, 392), "VANGUARD \u00b7 FIGHTER", font=F_SMALL, fill=DIM)
    d.text((44, 408), "5 hardpoints mapped", font=F_TINY, fill=DIM)

    # right: slot grid (shipyard plate recipe)
    recess(img, (316, 60, 696, 348))
    refs = ["W1", "W2", "W3", "W4", "W5"]
    fitted = {0: "laser", 3: "cannon"}
    for r in range(3):
        for c in range(5):
            x, y = 332 + c * 72, 76 + r * 88
            recess(img, (x, y, x + 60, y + 74), radius=5)
            if r == 0:
                d.text((x + 6, y + 4), refs[c], font=F_TINY, fill=DIM)
            if r == 0 and c in fitted:
                md.rounded_rectangle((x + 16, y + 26, x + 44, y + 58), radius=4, fill=(96, 102, 110))
            if r == 1 and c == 1:
                md.rounded_rectangle((x + 16, y + 26, x + 44, y + 58), radius=4, fill=(76, 82, 90))

    d.text((316, 360), "SLOT LAYOUT", font=F_SMALL, fill=DIM)

    # footer
    bevel(img, (24, 444, W - 24, 494), light=METAL_MID, dark=METAL_DARK, w=2)
    d.text((40, 458), "HULL  812 / 1000", font=F_SMALL, fill=BONE)
    d.text((250, 458), "SHLD  240 / 300", font=F_SMALL, fill=BONE)
    d.text((470, 458), "PWR  5 / 8", font=F_SMALL, fill=BONE)

    img.convert("RGB").save(f"{OUT}/status_mockup.png")
    img.convert("RGB").save(f"{OUT}/status_mockup.jpg", quality=85)
    print("wrote status_mockup")


if __name__ == "__main__":
    armory()
    context()
    status()
