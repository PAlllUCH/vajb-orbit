"""Phase D review sheets: labelled contact sheets per asset family.

Renders every consumer PNG in vajb-orbit/assets/<family>/ onto a dark void
background (STYLE_BIBLE dark band #111823) with the file name under each
thumbnail. Phase D files (the expansion set) are labelled in ember; Phase B
files in steel grey. Output: staging/phase_d/_preview/review_<family>.png.

Run: py -3.14 staging/phase_d/build_review.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
OUT = ROOT / "staging" / "phase_d" / "_preview"

BG = (17, 24, 35)
HDR = (223, 226, 230)
LEGEND_NEW = (232, 112, 58)
LEGEND_OLD = (138, 147, 160)
LEGEND_E = (201, 205, 210)
LEGEND_F = (245, 246, 248)
BOX_STROKE = (42, 49, 60)

PHASE_D_PREFIXES = {
    "ships": [
        "ship_interceptor", "ship_gunship", "ship_destroyer", "ship_drone_swarm",
        "ship_trader", "ship_patrol", "ship_bomber", "ship_mine_layer",
        "ship_turret_platform", "ship_boss_thorn", "ship_boss_spire",
        "ship_boss_leviathan", "ship_vanguard_mmo", "ship_fighter_mmo",
        "ship_corvette_mmo", "ship_freighter_mmo", "ship_boss_maw_mmo",
    ],
    "icons": ["icon_equip_", "icon_map_", "icon_ammo_laser", "icon_ammo_rocket"],
    "env": [
        "env_planet_moon", "env_jump_gate", "env_debris_field", "env_nebula_veil",
        "env_pickup_", "env_station_mmo", "env_station_ruined", "env_ice_field",
        "env_ore_cluster", "env_prop_",
    ],
    "ui": ["ui_insignia_", "ui_backdrop_"],
    "fx": [
        "fx_jump_portal", "fx_missile_trail", "fx_shield_break", "fx_tractor_beam",
        "fx_emp_arc", "fx_secondary_explosion", "fx_repair_pulse",
    ],
}

PHASE_E_PREFIXES = {
    "ships": [],
    "icons": ["icon_booster_", "icon_status_", "panel_boosters", "panel_status"],
    "env": [
        "env_base_", "env_outpost_", "env_body_", "env_bg_body_", "env_asteroid_b",
        "env_mine", "panel_asteroids_b",
    ],
    "ui": [],
    "fx": [],
}

# Phase F (docs/gameplay/16_art_design_brief.md): the RPG/economy layer.
# Checked before D/E so env_jump_gate_ring does not read as env_jump_gate.
PHASE_F_PREFIXES = {
    "ships": [
        "ship_miner", "ship_boss_boneyard", "ship_boss_pyre",
        "ship_fighter_concord", "ship_fighter_meridian", "ship_fighter_choir",
    ],
    "icons": [
        "panel_minerals_", "panel_modules_", "panel_slots", "panel_contracts",
        "panel_service_glyphs", "panel_faction_insignia",
        "icon_mineral_", "icon_ingot_", "icon_module_", "icon_slot_",
        "icon_contract_", "icon_service_", "icon_insignia_",
    ],
    "env": ["env_sector_", "env_jump_gate_ring", "env_arena_"],
    "ui": [],
    "fx": ["fx_anomaly_"],
}

SHEETS = {
    "ships": dict(box=(320, 200), cols=5, label=13, upscale=False, plate=None),
    "icons": dict(box=(120, 120), cols=8, label=10, upscale=True, plate=(201, 204, 208)),
    "env": dict(box=(330, 230), cols=5, label=12, upscale=False, plate=None),
    "ui": dict(box=(330, 230), cols=5, label=12, upscale=True, plate=None),
    "fx": dict(box=(400, 300), cols=4, label=13, upscale=False, plate=None),
}


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default(size)


FONT = "C:/Windows/Fonts/consola.ttf"
FONT_B = "C:/Windows/Fonts/consolab.ttf"


def is_phase_d(family: str, name: str) -> bool:
    return any(name.startswith(p) for p in PHASE_D_PREFIXES[family])


def is_phase_e(family: str, name: str) -> bool:
    return any(name.startswith(p) for p in PHASE_E_PREFIXES[family])


def is_phase_f(family: str, name: str) -> bool:
    return any(name.startswith(p) for p in PHASE_F_PREFIXES[family])


def phase_label(family: str, name: str) -> str:
    if is_phase_f(family, name):
        return "F"
    if is_phase_e(family, name):
        return "E"
    return "D" if is_phase_d(family, name) else "B"


def build_sheet(family: str, cfg: dict) -> Path:
    names = sorted(p.name for p in (ASSETS / family).glob("*.png"))
    order = {"F": 0, "E": 1, "D": 2, "B": 3}
    ordered = sorted(names, key=lambda n: (order[phase_label(family, n)], n))
    counts = {k: sum(1 for n in names if phase_label(family, n) == k) for k in "FEDB"}

    bw, bh = cfg["box"]
    cols = cfg["cols"]
    pad = 16
    label_h = cfg["label"] + 10
    rows = math.ceil(len(ordered) / cols)
    title_h = 76
    width = pad + cols * (bw + pad)
    height = title_h + rows * (bh + label_h + pad) + pad

    canvas = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(canvas)

    f_title = load_font(FONT_B, 26)
    f_leg = load_font(FONT, 14)
    f_name = load_font(FONT, cfg["label"])
    f_dim = load_font(FONT, max(8, cfg["label"] - 2))

    title = (f"Vajb Orbit - assets/{family}  ({len(ordered)} files, phase F {counts['F']}, "
             f"E {counts['E']}, D {counts['D']}, B {counts['B']})")
    draw.text((pad, 14), title, font=f_title, fill=HDR)
    lx = pad
    for color, text in ((LEGEND_F, "phase F (new)"), (LEGEND_E, "phase E"),
                        (LEGEND_NEW, "phase D"), (LEGEND_OLD, "phase B (existing)")):
        draw.rectangle((lx, 54, lx + 14, 66), fill=color)
        draw.text((lx + 22, 50), text, font=f_leg, fill=HDR)
        lx += 22 + int(draw.textlength(text, font=f_leg)) + 30

    for i, name in enumerate(ordered):
        r, c = divmod(i, cols)
        x = pad + c * (bw + pad)
        y = title_h + r * (bh + label_h + pad)
        if cfg["plate"]:
            draw.rectangle((x, y, x + bw, y + bh), fill=cfg["plate"])
        draw.rectangle((x - 1, y - 1, x + bw + 1, y + bh + 1), outline=BOX_STROKE)

        img = Image.open(ASSETS / family / name).convert("RGBA")
        w, h = img.size
        fit = min(bw / w, bh / h)
        scale = min(fit, 4.0) if (cfg["upscale"] and fit > 1.0) else fit
        tw, th = max(1, round(w * scale)), max(1, round(h * scale))
        if (tw, th) != (w, h):
            img = img.resize((tw, th), Image.LANCZOS)
        tx = x + (bw - tw) // 2
        ty = y + (bh - th) // 2
        canvas.alpha_composite(img, (tx, ty))

        color = {"F": LEGEND_F, "E": LEGEND_E, "D": LEGEND_NEW, "B": LEGEND_OLD}[phase_label(family, name)]
        stem = name[:-4]
        tw_name = draw.textlength(stem, font=f_name)
        nx = x + (bw - tw_name) / 2
        draw.text((nx, y + bh + 3), stem, font=f_name, fill=color)
        dim = f"{w}x{h}"
        tw_dim = draw.textlength(dim, font=f_dim)
        draw.text((x + (bw - tw_dim) / 2, y + bh + 4 + cfg["label"] + 2), dim, font=f_dim, fill=(97, 105, 116))

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"review_{family}.png"
    canvas.convert("RGB").save(path)
    print(f"{path.name}: {len(ordered)} files (F {counts['F']} / E {counts['E']} / D {counts['D']} / B {counts['B']}), {width}x{height}")
    return path


def main() -> None:
    for family, cfg in SHEETS.items():
        build_sheet(family, cfg)


if __name__ == "__main__":
    main()
