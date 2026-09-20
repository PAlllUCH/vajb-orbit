"""Phase F P1/P2 scene review sheets - ships, sector backdrops, props, anomaly FX.

Output (staging/phase_f/_preview/):
  review_f_ships.png   the Delver miner rotation sheet, the two arena bosses, the three
                       hunter liveries, and a base-vs-livery side-view comparison strip
                       (expansion spec 10: liveries change pattern/weathering only)
  review_f_env.png     the seven sector backdrops at 16:9, the jump gate ring and the
                       two arena props on void black
  review_f_fx.png      the anomaly trio, RGB on void black, checked not alpha-keyed

Run: py -3.14 staging/phase_f/build_review_scene.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
SHIPPED = ROOT / "vajb-orbit" / "assets"
OUT = STAGE / "_preview"

BG = (17, 24, 35)
VOID = (10, 14, 20)
BOX = (42, 49, 60)
HDR = (223, 226, 230)
NOTE = (138, 147, 160)
NEW = (245, 246, 248)
ACCENT = (232, 112, 58)

VIEWS = ["front", "three_quarter", "side", "back"]
SECTORS = [
    ("env_sector_1_bg", "1 Halcyon Reach - ordered home space (Concord, T1)"),
    ("env_sector_2_bg", "2 Iron Marches - industrial belt (Concord, T1-T2)"),
    ("env_sector_3_bg", "3 Meridian Span - trade crossroads (Meridian, T2)"),
    ("env_sector_4_bg", "4 Ashveil Expanse - contested edge (Meridian, T2-T3)"),
    ("env_sector_5_bg", "5 Cinder Verge - exotic territory (Choir, T3)"),
    ("env_sector_6_bg", "6 The Hollows - deep exotic belt (Choir, T3-T4)"),
    ("env_sector_7_bg", "7 Maw Belt - no law, the arena (unaligned, T4)"),
]
LIVERIES = [
    ("ship_fighter", "base fighter hull (shipped)"),
    ("ship_fighter_concord", "Concord of Iron hunter livery"),
    ("ship_fighter_meridian", "Meridian Free Ports hunter livery"),
    ("ship_fighter_choir", "Ember Choir hunter livery"),
]


def font(name, size):
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except OSError:
        return ImageFont.load_default(size)


F_TITLE = font("consolab.ttf", 26)
F_SECT = font("consolab.ttf", 17)
F_LBL = font("consola.ttf", 12)
F_SMALL = font("consola.ttf", 10)


def load(name, shipped=False):
    for base in ((SHIPPED if shipped else STAGE) / "ships", STAGE / "ships",
                 SHIPPED / "ships", STAGE / "env", STAGE / "fx"):
        p = base / f"{name}.png"
        if p.exists():
            raw = Image.open(p)
            return raw.convert("RGBA"), p, raw.mode
    return None, None, None


def fit(img, w, h):
    c = img.copy()
    c.thumbnail((w, h), Image.LANCZOS)
    return c


def canvas_of(w, h, title, subtitle):
    c = Image.new("RGBA", (w, h), BG + (255,))
    d = ImageDraw.Draw(c)
    d.text((24, 16), title, font=F_TITLE, fill=HDR)
    d.text((24, 50), subtitle, font=F_LBL, fill=NOTE)
    return c, d


def ships_sheet():
    rows = [
        ("Delver miner player hull (SHIPS_SPEC 3.7) - front, three-quarter, side, back",
         [f"ship_miner_{v}" for v in VIEWS]),
        ("Arena bosses (SHIPS_SPEC 3.8 / 3.9) - single centred renders",
         ["ship_boss_boneyard", "ship_boss_pyre"]),
        ("Concord of Iron hunter livery", [f"ship_fighter_concord_{v}" for v in VIEWS]),
        ("Meridian Free Ports hunter livery", [f"ship_fighter_meridian_{v}" for v in VIEWS]),
        ("Ember Choir hunter livery", [f"ship_fighter_choir_{v}" for v in VIEWS]),
        ("base-vs-livery side views: silhouette and palette must be identical",
         [f"{n}_side" for n, _ in LIVERIES]),
    ]
    cell_w, cell_h = 300, 190
    gap = 14
    pad = 24
    width = pad * 2 + 4 * (cell_w + gap)
    height = 96 + len(rows) * (cell_h + 40 + gap) + 24
    c, d = canvas_of(width, height,
                     "Vajb Orbit - Phase F ships review (16_art_design_brief P1)",
                     "SHIPS_SPEC section 1 framing constant: top-down orthographic, bow right in the side view, "
                     "~60 percent of frame width, transparent where a sprite is required (shown on void black)")
    y = 96
    for title, names in rows:
        d.text((pad, y), title, font=F_SECT, fill=NEW)
        y += 26
        for i, name in enumerate(names):
            x = pad + i * (cell_w + gap)
            d.rectangle((x, y, x + cell_w, y + cell_h), fill=VOID)
            img, path, disk_mode = load(name, shipped=(name == "ship_fighter_side"))
            if img is None:
                d.text((x + 8, y + 8), f"MISSING {name}", font=F_LBL, fill=ACCENT)
            else:
                t = fit(img, cell_w - 8, cell_h - 22)
                c.alpha_composite(t, (x + (cell_w - t.width) // 2, y + 4 + (cell_h - 22 - t.height) // 2))
                d.text((x + 4, y + cell_h - 16), f"{name} {img.width}x{img.height} {disk_mode}", font=F_SMALL, fill=NOTE)
            d.rectangle((x, y, x + cell_w, y + cell_h), outline=BOX)
        y += cell_h + 40
    OUT.mkdir(parents=True, exist_ok=True)
    p = OUT / "review_f_ships.png"
    c.convert("RGB").save(p)
    print(f"{p.name}: {width}x{height}")
    return p


def env_sheet():
    bg_w, bg_h = 560, 315
    gap = 16
    pad = 24
    width = pad * 2 + 2 * (bg_w + gap)
    rows = math.ceil(len(SECTORS) / 2)
    height = 104 + rows * (bg_h + 30 + gap) + 210 + 24
    c, d = canvas_of(width, height,
                     "Vajb Orbit - Phase F environment review (brief P1: sector backdrops, gate ring, arena props)",
                     "backdrops are 2048x1152 opaque 16:9, ENVIRONMENT_SPEC rules, no emissive; props and the ring "
                     "are alpha sprites shown on void black")
    y = 104
    for i, (name, label) in enumerate(SECTORS):
        r, col = divmod(i, 2)
        x = pad + col * (bg_w + gap)
        yy = y + r * (bg_h + 30 + gap)
        d.rectangle((x, yy, x + bg_w, yy + bg_h), fill=VOID)
        img, _p, disk_mode = load(name)
        if img is not None:
            t = fit(img, bg_w, bg_h)
            c.alpha_composite(t, (x + (bg_w - t.width) // 2, yy + (bg_h - t.height) // 2))
            d.text((x + 4, yy + bg_h + 3), f"{label}  [{img.width}x{img.height} {disk_mode}]",
                   font=F_SMALL, fill=NOTE)
        else:
            d.text((x + 8, yy + 8), f"MISSING {name}", font=F_LBL, fill=ACCENT)
        d.rectangle((x, yy, x + bg_w, yy + bg_h), outline=BOX)

    y = y + rows * (bg_h + 30 + gap) + 20
    d.text((pad, y), "jump gate ring and arena props (alpha sprites, one value step darker than ships)", font=F_SECT, fill=NEW)
    y += 26
    for i, (name, label) in enumerate([
        ("env_jump_gate_ring", "jump gate ring (brief P1, 11 section 2.1) - aperture stays empty, no field"),
        ("env_arena_nav_pylon", "arena nav-pylon ring beacon"),
        ("env_arena_barricade", "arena barricade plate run"),
    ]):
        x = pad + i * (bg_w // 2 + gap)
        w, h = bg_w // 2, 160
        d.rectangle((x, y, x + w, y + h), fill=VOID)
        img, _p, disk_mode = load(name)
        if img is not None:
            t = fit(img, w - 8, h - 22)
            c.alpha_composite(t, (x + (w - t.width) // 2, y + 4 + (h - 22 - t.height) // 2))
            d.text((x + 4, y + h - 17), f"{label}  [{img.width}x{img.height} {disk_mode}]", font=F_SMALL, fill=NOTE)
        d.rectangle((x, y, x + w, y + h), outline=BOX)

    p = OUT / "review_f_env.png"
    c.convert("RGB").save(p)
    print(f"{p.name}: {width}x{height}")
    return p


def fx_sheet():
    cell = 520
    gap = 20
    pad = 24
    names = [
        ("fx_anomaly_shimmer", "ore bloom (reward) - Steel Highlight #565C63 only, no ember"),
        ("fx_anomaly_grave_glow", "grave cache (reward) - Steel Highlight core, no ember"),
        ("fx_anomaly_rift", "void rift (HAZARD) - the ember pair is sanctioned here"),
    ]
    width = pad * 2 + len(names) * (cell + gap)
    height = 130 + cell + 60
    c, d = canvas_of(width, height,
                     "Vajb Orbit - Phase F anomaly FX review (brief P1, 11 section 3.2)",
                     "FX_SPEC 0.1: flat void black #0A0E14 background, RGB output, additive blending, "
                     "NEVER alpha-keyed. Exactly one accent per file.")
    y = 130
    for i, (name, label) in enumerate(names):
        x = pad + i * (cell + gap)
        img, path, disk_mode = load(name)
        d.rectangle((x, y, x + cell, y + cell), fill=VOID)
        if img is not None:
            t = fit(img, cell, cell)
            c.alpha_composite(t, (x + (cell - t.width) // 2, y + (cell - t.height) // 2))
            d.text((x + 4, y + cell + 6), f"{name}  [{img.width}x{img.height} {disk_mode}, not alpha-keyed]",
                   font=F_LBL, fill=NEW)
            d.text((x + 4, y + cell + 24), label, font=F_SMALL, fill=NOTE)
        else:
            d.text((x + 8, y + 8), f"MISSING {name}", font=F_LBL, fill=ACCENT)
        d.rectangle((x, y, x + cell, y + cell), outline=BOX)
    p = OUT / "review_f_fx.png"
    c.convert("RGB").save(p)
    print(f"{p.name}: {width}x{height}")
    return p


if __name__ == "__main__":
    ships_sheet()
    env_sheet()
    fx_sheet()
