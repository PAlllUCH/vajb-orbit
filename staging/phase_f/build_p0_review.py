"""Phase F P0 review sheet - flat icon families, with the ICONS_SPEC conformance checks.

Renders every Phase F flat icon at its two shipping sizes, twice: as generated (iron
black on white, the ICONS_SPEC section 1 spec check) and as consumed (the white tint
stencil on the panel black HUD background). The 16 px cut is shown native plus at 3x
nearest-neighbour so the 16 px silhouette read can actually be judged.

Also prints a conformance table: opaque pixel count, background alpha, maximum warmth
(r - b, the ember test: the accent may never appear on an icon), the mean luminance of
the glyph ink against the Phase B reference set, and a 16 px silhouette sanity check.

Output: staging/phase_f/_preview/review_p0_icons.png
Run:    py -3.14 staging/phase_f/build_p0_review.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / "vajb-orbit" / "assets" / "icons"
# F.1: the shipped cuts are the authority for this sheet. staging/phase_f/icons still holds
# the pre-F.1 stretched geometry as provenance, but it is no longer what consumers load.
STAGE = ICONS
OUT = ROOT / "staging" / "phase_f" / "_preview"

BG = (17, 24, 35)
PLATE = (21, 24, 29)
BOX = (42, 49, 60)
HDR = (223, 226, 230)
NOTE = (138, 147, 160)
F_NEW = (245, 246, 248)
BAD = (232, 112, 58)
GOOD = (150, 214, 160)

MINERALS = [
    "iron", "copper", "chromium", "silicon", "aluminium",
    "titanium", "nickel", "cobalt", "tungsten", "silver",
    "gold", "platinum", "neodymium", "iridium", "osmium",
    "palladium", "cerulite", "emberite", "voidglass", "krilium",
]


def font(name, size):
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except OSError:
        return ImageFont.load_default(size)


F_TITLE = font("consolab.ttf", 26)
F_SECT = font("consolab.ttf", 17)
F_NAME = font("consola.ttf", 10)
F_STAT = font("consola.ttf", 9)


def stages(*names):
    """The shipped split for each name, at 48 and 16, from the staging folder."""
    found = {}
    for name in names:
        for size in (48, 16):
            hits = sorted(STAGE.glob(f"{name}_{size}.png"))
            found[(name, size)] = hits[0] if hits else None
    return found


def describe(path):
    img = Image.open(path).convert("RGBA")
    px = img.load()
    w, h = img.size
    opaque = alpha0 = warm = 0
    lum_sum = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 24:
                opaque += 1
                lum_sum += (r + g + b) / 3
                warm = max(warm, r - b)
            elif a == 0:
                alpha0 += 1
    return dict(size=(w, h), opaque=opaque, alpha0=100 * alpha0 / (w * h),
                warmth=warm, lum=(lum_sum / opaque if opaque else 0))


def stencil(path):
    """The white-RGB/alpha-preserved form the engine tints (derive_icon_tints.gd)."""
    img = Image.open(path).convert("RGBA")
    white = Image.new("RGBA", img.size, (255, 255, 255, 0))
    white.putalpha(img.getchannel("A"))
    return white


def build(groups):
    cell_w, cell_h = 74, 74
    gap = 18
    per_row = 8
    label_h = 30
    row_h = label_h + cell_h + 6 + 48 + 16
    title_h = 96
    width = 28 + per_row * (cell_w + gap) + 28
    total_rows = sum(math.ceil(len(names) / per_row) + 1 for _title, names in groups)
    height = title_h + total_rows * row_h + 28

    canvas = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.text((28, 18), "Vajb Orbit - Phase F flat icon review (16_art_design_brief P0 + P2)", font=F_TITLE, fill=HDR)
    draw.text((28, 52), "per icon: 48 px iron-black on white (as generated)  |  48 px tint stencil on panel black  "
                        "|  16 px native and 16 px at 3x nearest", font=font("consola.ttf", 13), fill=NOTE)
    draw.text((28, 70), "ICONS_SPEC section 1 law: flat single-colour iron black #232629, no glow, no gradient, "
                        "no ember, mitred corners", font=font("consola.ttf", 13), fill=NOTE)

    y = title_h
    report = []
    for title, names in groups:
        draw.text((28, y), title, font=F_SECT, fill=F_NEW)
        y += 30
        for i, name in enumerate(names):
            r, c = divmod(i, per_row)
            if i and c == 0:
                y += row_h
            x = 28 + c * (cell_w + gap)
            p48 = STAGE / f"{name}_48.png"
            p16 = STAGE / f"{name}_16.png"
            if not p48.exists() or not p16.exists():
                draw.text((x, y), f"MISSING {name}", font=F_NAME, fill=BAD)
                report.append((name, None, None, "MISSING"))
                continue

            art48 = Image.open(p48).convert("RGBA")
            art16 = Image.open(p16).convert("RGBA")
            st48 = stencil(p48)
            st16 = stencil(p16)

            draw.rectangle((x, y, x + cell_w, y + cell_h), fill=(255, 255, 255))
            canvas.alpha_composite(art48.resize((cell_w, cell_h), Image.LANCZOS), (x, y))
            draw.rectangle((x, y, x + cell_w, y + cell_h), outline=BOX)

            x2 = x + cell_w + 6
            draw.rectangle((x2, y, x2 + cell_w, y + cell_h), fill=PLATE)
            canvas.alpha_composite(st48.resize((cell_w, cell_h), Image.LANCZOS), (x2, y))
            draw.rectangle((x2, y, x2 + cell_w, y + cell_h), outline=BOX)

            x3 = x2 + cell_w + 6
            draw.rectangle((x3, y, x3 + cell_w, y + cell_h), fill=PLATE)
            canvas.alpha_composite(st16, (x3 + (cell_w - 16) // 2, y + 6))
            canvas.alpha_composite(st16.resize((48, 48), Image.NEAREST), (x3 + (cell_w - 48) // 2, y + 26))
            draw.rectangle((x3, y, x3 + cell_w, y + cell_h), outline=BOX)

            draw.text((x, y + cell_h + 3), name.replace("icon_", ""), font=F_NAME, fill=F_NEW)

            canary = describe(p48)
            small = describe(p16)
            flag = "" if (canary["warmth"] <= 40 and small["opaque"] > 8) else " CHECK"
            draw.text((x, y + cell_h + 15), f"lum {canary['lum']:.0f} warm {canary['warmth']}"
                                            f" a0 {canary['alpha0']:.0f}%", font=F_STAT, fill=NOTE)
            draw.text((x, y + cell_h + 26), f"16px ink {small['opaque']}px{flag}", font=F_STAT,
                      fill=GOOD if not flag and small["opaque"] > 8 else BAD)
            report.append((name, canary, small, flag))
        y += row_h

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "review_flat_icons.png"
    canvas.convert("RGB").save(path)
    print(f"{path.name}: {width}x{height}")

    print(f"\n{'icon':40} {'48px lum':>9} {'warmth':>7} {'alpha0':>7} {'16px ink':>9}")
    bad = 0
    for name, canary, small, flag in report:
        if canary is None:
            bad += 1
            print(f"{name:40} {'-':>9} {'-':>7} {'-':>7} {'MISSING':>9}")
            continue
        print(f"{name:40} {canary['lum']:>9.1f} {canary['warmth']:>7} {canary['alpha0']:>6.0f}% "
              f"{small['opaque']:>9}")
        if flag:
            bad += 1
    print(f"\n{len(report)} icons, {bad} flagged")

    ref = ROOT / "vajb-orbit" / "assets" / "icons"
    print("\nPhase B flat reference (shipped, for comparison):")
    for name in ("icon_cargo_ore_48.png", "icon_weapon_laser_48.png", "icon_credits_48.png"):
        p = ref / name
        if p.exists():
            d = describe(p)
            print(f"{name:40} {d['lum']:>9.1f} {d['warmth']:>7} {d['alpha0']:>6.0f}%")
    return bad


def main():
    groups = [
        ("minerals - ore, tier order T1 -> T4 (5x4 sheet)", [f"icon_mineral_{m}" for m in MINERALS]),
        ("minerals - ingot, tier order T1 -> T4 (5x4 sheet)", [f"icon_ingot_{m}" for m in MINERALS]),
        ("modules - 09 section 3, panels A/B/C (3x3 each)",
         [f"icon_module_{m}" for m in (
             "w_railgun", "w_mining", "s_light", "s_heavy", "s_ion", "h_plate_light", "h_plate_heavy",
             "h_composite", "p_std", "p_mk2", "p_core", "e_std", "e_ion", "e_vector", "b_afterburner",
             "b_fold", "c_target", "c_scanner", "c_twin", "c_ewar", "c_nexus", "u_cargo", "u_salvage",
             "u_refine", "u_drones", "u_tractor", "u_holds")]),
        ("slot types - 4x2 sheet", [f"icon_slot_{s}" for s in
                                    ("engine", "power", "w", "s", "h", "c", "b", "u")]),
        ("contract types - P2 (2x3 sheet)", [f"icon_contract_{s}" for s in
                                             ("haul", "hunt", "gather", "escort", "expedition")]),
        ("service glyphs - P2 (2x2 sheet)", [f"icon_service_{s}" for s in
                                             ("vault", "insurance", "bounty")]),
        ("faction insignia - P2, 12 section 1 (2x2 sheet)", [f"icon_insignia_{s}" for s in
                                                            ("concord", "meridian", "choir")]),
    ]
    build(groups)


if __name__ == "__main__":
    main()
