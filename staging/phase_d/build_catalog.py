"""Build docs/design/ASSET_CATALOG.md from the shipped files in vajb-orbit/assets/.

File list, sizes and alpha come from the filesystem (never hand-maintained);
purpose strings are curated here from the spec set. Phase B/D split reuses the
same prefix table as build_review.py.

Run: py -3.14 staging/phase_d/build_catalog.py
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_review import PHASE_D_PREFIXES, phase_label  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "phase_f"))
import wave_f  # noqa: E402  (Phase F roster: single source for the flat icon names)

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
OUT = ROOT / "docs" / "design" / "ASSET_CATALOG.md"
AUDIO = ASSETS / "audio"
AUDIO_REPORT = ROOT / "staging" / "audio" / "audio_report.json"
AUDIO_DIRS = ("music", "sfx", "ambience", "ui")

# Phase F flat icons (16_art_design_brief P0/P2): generated as flat iron-black
# silhouettes on white and consumed through the tint stencil, so their _16/_48 splits
# get the tintable wording like the Phase B flat glyphs.
F_FLAT_ICONS = {f"icon_mineral_{m}" for m in wave_f.MINERALS}
F_FLAT_ICONS |= {f"icon_ingot_{m}" for m in wave_f.MINERALS}
for _names in wave_f.MODULE_PANELS.values():
    F_FLAT_ICONS |= set(_names)
F_FLAT_ICONS |= set(wave_f.SLOT_GLYPHS)
F_FLAT_ICONS |= set(wave_f.CONTRACT_GLYPHS)
F_FLAT_ICONS |= set(wave_f.SERVICE_GLYPHS)
F_FLAT_ICONS |= set(wave_f.INSIGNIA_GLYPHS)


VIEW_SUFFIX = {
    "_three_quarter": "three-quarter view, bow 45 deg",
    "_front": "front view, bow up",
    "_side": "side view, bow right",
    "_back": "back view, bow down",
}

SHIP_ROLES = {
    "ship_vanguard_damaged": "Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2)",
    "ship_vanguard": "Player Vanguard cutter (SHIPS_SPEC 3.1)",
    "ship_fighter": "Fighter, enemy hull class (SHIPS_SPEC 3.3)",
    "ship_corvette": "Corvette, enemy hull class (SHIPS_SPEC 3.4)",
    "ship_freighter": "Freighter, enemy hull class (SHIPS_SPEC 3.5)",
    "ship_boss_maw": "Maw dreadnought, boss (SHIPS_SPEC 3.6)",
    "ship_miner": "Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1)",
    "ship_boss_boneyard": "Boneyard Behemoth, S3 Meridian arena boss (SHIPS_SPEC 3.8)",
    "ship_boss_pyre": "Pyre Hierophant, S6 Choir arena boss (SHIPS_SPEC 3.9)",
    "ship_interceptor": "Interceptor, hostile fast attack (expansion spec 3 #7)",
    "ship_gunship": "Gunship, hostile mid-tier (expansion spec 3 #8)",
    "ship_destroyer": "Destroyer, hostile capital (expansion spec 3 #9)",
    "ship_drone_swarm": "Drone swarm unit (expansion spec 3 #10)",
    "ship_trader": "Trader, neutral civil (expansion spec 3 #11)",
    "ship_patrol": "Patrol, neutral enforcer (expansion spec 3 #12)",
    "ship_bomber": "Bomber, hostile ordnance (expansion spec 3 #13)",
    "ship_mine_layer": "Mine layer, hostile support (expansion spec 3 #14)",
    "ship_turret_platform": "Turret platform, hostile static (expansion spec 3 #15)",
    "ship_boss_thorn": "Thorn, hive-mother boss (expansion spec 3)",
    "ship_boss_spire": "Spire, relay leviathan boss (expansion spec 3)",
    "ship_boss_leviathan": "Leviathan, hammerhead boss (expansion spec 3)",
}

# Livery codes: the suffix stripped between the hull stem and the view suffix.
LIVERY_CODES = {
    "mmo": "MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4).",
    "concord": "Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1).",
    "meridian": "Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1).",
    "choir": "Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1).",
}

B_FLAT_ICONS = [
    "icon_ammo", "icon_cargo_container", "icon_cargo_crate", "icon_cargo_data_core",
    "icon_cargo_fuel_cell", "icon_cargo_ore", "icon_cargo_salvage", "icon_close",
    "icon_credits", "icon_gear", "icon_hull", "icon_logout", "icon_shield",
    "icon_weapon_cannon", "icon_weapon_laser", "icon_weapon_mine", "icon_weapon_plasma",
    "icon_weapon_rocket", "icon_zoom_minus", "icon_zoom_plus",
]

PANEL_PURPOSE = {
    "panel_weapons": "weapon glyphs, 2x3",
    "panel_cargo": "cargo item glyphs, 2x3",
    "panel_glyphs": "HUD glyphs, 3x3",
    "panel_boosters": "booster consumable icons, 2x3 - spec E 6",
    "panel_status": "HUD status effect icons, 3x3 - spec E 6",
    "panel_minerals_ore": "20 ore glyphs in 02 section 2 tier order, 5x4 - brief P0",
    "panel_minerals_ingot": "20 ingot glyphs in 02 section 2 tier order, 5x4 - brief P0",
    "panel_modules_a": "module glyphs (weapons/shields/armour/reactor), 3x3 - brief P0",
    "panel_modules_b": "module glyphs (reactor/engines/boosters/computers), 3x3 - brief P0",
    "panel_modules_c": "module glyphs (computers/utility), 3x3 - brief P0",
    "panel_slots": "slot-type socket glyphs, 4x2 - brief P0",
    "panel_contracts": "contract-type glyphs, 2x3 - brief P2",
    "panel_service_glyphs": "service glyphs (vault/insurance/bounty), 2x2 - brief P2",
    "panel_faction_insignia": "faction insignia glyphs, 2x2 - brief P2",
}

ENV_PURPOSE = {
    "env_asteroid": "Asteroid sprite, size tier and variant per name (ENVIRONMENT_SPEC 4)",
    "env_stars_layer1": "Parallax star layer 1 (tiling, RGB; ENVIRONMENT_SPEC 2)",
    "env_stars_layer2": "Parallax star layer 2 (tiling, RGB; ENVIRONMENT_SPEC 2)",
    "env_stars_layer3": "Parallax star layer 3 (tiling, RGB; ENVIRONMENT_SPEC 2)",
    "env_menu_bg": "Main menu background, 16:9 opaque (MAIN_MENU_SPEC)",
    "env_loading_bg": "Loading screen background, 16:9 opaque",
    "env_station": "Dockable station (POI)",
    "env_wreck_hulk": "Wreck hulk, salvage POI",
    "env_planet_moon": "Airless dead moon (map/skybox POI; expansion spec 6)",
    "env_jump_gate": "Jump gate structure, welded pylons + segmented ring (expansion spec 6)",
    "env_debris_field": "Scattered torn-hull debris field (expansion spec 6)",
    "env_nebula_veil": "Tiling nebula haze, very low contrast, RGB (expansion spec 6)",
    "env_station_mmo": "Station in MMO plate pattern (expansion spec 6)",
    "env_station_ruined": "Gutted hostile station, torn ring (expansion spec 6)",
    "env_ice_field": "Frozen fragment cluster (expansion spec 6)",
    "env_ore_cluster": "Dense mineable ore cluster with veins (expansion spec 6)",
    "env_pickup_bonus_box": "World pickup: sealed ordnance crate (expansion spec 5)",
    "env_pickup_repair_pod": "World pickup: repair pod (expansion spec 5)",
    "env_pickup_shield_pod": "World pickup: shield emitter pod (expansion spec 5)",
    "env_pickup_speed_pod": "World pickup: speed boost pod (expansion spec 5)",
    "env_pickup_ammo_pod": "World pickup: ammo canister (expansion spec 5)",
    "env_pickup_ore_pod": "World pickup: ore container (expansion spec 5)",
    "env_prop_hull_nose": "Wreck fragment: bow section (expansion spec 9)",
    "env_prop_hull_mid": "Wreck fragment: mid section (expansion spec 9)",
    "env_prop_hull_stern": "Wreck fragment: stern section (expansion spec 9)",
    "env_prop_plate_section": "Wreck fragment: plate section (expansion spec 9)",
    "env_prop_drive_core": "Wreck fragment: drive core (expansion spec 9)",
    "env_prop_rib_cluster": "Wreck fragment: rib cluster (expansion spec D 9)",
    # --- Phase E ---
    "env_base_mining": "Mining base, station-scale POI: silo row, crusher derrick, conveyor arms (spec E 3)",
    "env_base_trade": "Trade/refinery base: docking ring, mooring arms, transfer cranes (spec E 3)",
    "env_base_defense": "Defense fortress: terraced casemates, battery row, sensor masts (spec E 3)",
    "env_base_shipyard": "Shipyard/drydock: empty construction cradle between gantry towers (spec E 3)",
    "env_outpost_mining": "Mining outpost: drill tower anchored on a rock chunk (spec E 4)",
    "env_outpost_defense": "Defense outpost: stacked turrets on an armoured drum (spec E 4)",
    "env_outpost_relay": "Comms relay outpost: lattice mast with three dishes (spec E 4)",
    "env_outpost_repair": "Repair post: open cradle, clamp arms, tool rack (spec E 4)",
    "env_body_ice_moon": "Airless ice moon, top-down body sprite (spec E 5)",
    "env_body_ore_moon": "Airless mining-scarred moon with ore seams (spec E 5)",
    "env_body_shattered": "Airless shattered moon with a chunk ring (spec E 5)",
    "env_bg_body_plate": "Background body plate, 16:9 opaque parallax layer (spec E 5)",
    "env_asteroid_b1": "Rock look 2: large elongated cigar body (spec E 7)",
    "env_asteroid_b2": "Rock look 2: large twin-lobed body (spec E 7)",
    "env_asteroid_b3": "Rock look 2: medium heavily pitted body (spec E 7)",
    "env_asteroid_b4": "Rock look 2: medium ore-flecked body (spec E 7)",
    "env_asteroid_b5": "Rock look 2: small flat shard (spec E 7)",
    "env_asteroid_b6": "Rock look 2: small rubble cluster (spec E 7)",
    "env_mine": "Deployed mine world object: spiked sphere, ember seam lamp (spec E 7)",
    "panel_asteroids_b": "Asteroid sheet master, 2K (source of env_asteroid_b1..b6; not a runtime sprite)",
    # --- Phase F (16_art_design_brief P1) ---
    "env_sector_1_bg": "Sector backdrop: Halcyon Reach, ordered home space, 2048x1152 opaque (brief P1, 11 section 1)",
    "env_sector_2_bg": "Sector backdrop: Iron Marches, the industrial belt, 2048x1152 opaque (brief P1)",
    "env_sector_3_bg": "Sector backdrop: Meridian Span, the trade crossroads, 2048x1152 opaque (brief P1)",
    "env_sector_4_bg": "Sector backdrop: Ashveil Expanse, the contested edge, 2048x1152 opaque (brief P1)",
    "env_sector_5_bg": "Sector backdrop: Cinder Verge, exotic territory, 2048x1152 opaque (brief P1)",
    "env_sector_6_bg": "Sector backdrop: The Hollows, the deep exotic belt, 2048x1152 opaque (brief P1)",
    "env_sector_7_bg": "Sector backdrop: Maw Belt, lawless arena belt, 2048x1152 opaque (brief P1)",
    "env_jump_gate_ring": "Jump gate ring: segmented radial structure with four engine blocks, no aperture glow (brief P1, 11 section 2.1)",
    "env_arena_nav_pylon": "Arena prop: nav-pylon ring beacon post, ember lamps (brief P1, 14 section 5)",
    "env_arena_barricade": "Arena prop: bolted barricade plate run, no lamps (brief P1, 14 section 5)",
}

UI_PURPOSE = {
    "ui_panel_frame": "9-slice panel frame, 96x96 with a 32 px painted border band "
                      "(the nine-slice margin; ICONS_SPEC 9.8 C1)",
    "ui_bar_caps": "Status bar end caps (42x14)",
    "ui_minimap_bezel": "Minimap bezel ring, 200x200",
    "logo_vajb_orbit": "Game logo (menu title)",
    "ui_insignia_mmo": "Company emblem: Mars Mining Operations (MENU_FLOW 3.3-3.7)",
    "ui_insignia_mic": "Company emblem: Miner's Incorporated (MENU_FLOW 3.3-3.7)",
    "ui_insignia_ven": "Company emblem: Venus Resources (MENU_FLOW 3.3-3.7)",
    "ui_insignia_neutral": "Company emblem: neutral plate (MENU_FLOW 3.3-3.7)",
    "ui_backdrop_hangar": "Hangar screen backdrop, 16:9 opaque (expansion spec 8)",
    "ui_backdrop_starmap": "Starmap screen backdrop, 16:9 opaque (expansion spec 8)",
    "ui_backdrop_login": "Login/company-select backdrop, 16:9 opaque (expansion spec 8)",
}

FX_PURPOSE = {
    "fx_laser_bolt": "Laser bolt projectile (single frame)",
    "fx_muzzle_flash": "Muzzle flash, 4-frame sheet",
    "fx_engine_trail": "Engine trail",
    "fx_explosion": "Explosion, 5-frame sheet",
    "fx_shield_ripple": "Shield hit ripple (steel highlight)",
    "fx_mining_beam": "Mining beam, 4-frame sheet",
    "fx_cargo_pulse": "Cargo tractor pulse",
    "fx_hull_critical_vignette": "Hull-critical screen vignette (single)",
    "fx_ember_pulse": "Ember pulse, generic danger bloom",
    "fx_jump_portal": "Jump aperture ring, ember (single frame; expansion spec 7)",
    "fx_missile_trail": "Missile trail, 4-frame sheet (expansion spec 7)",
    "fx_shield_break": "Shield collapse, 4-frame sheet, no ember (expansion spec 7)",
    "fx_tractor_beam": "Tractor beam (expansion spec 7)",
    "fx_emp_arc": "EMP arc discharge (expansion spec 7)",
    "fx_secondary_explosion": "Secondary explosion (expansion spec 7)",
    "fx_repair_pulse": "Repair pulse ring, steel highlight (non-ember exception; expansion spec 7)",
    # --- Phase F ---
    "fx_anomaly_shimmer": "Ore-bloom anomaly shimmer, steel highlight only, RGB on void black (brief P1, 11 section 3.2)",
    "fx_anomaly_grave_glow": "Grave-cache anomaly glow, steel highlight core, RGB on void black (brief P1)",
    "fx_anomaly_rift": "Void-rift anomaly tear, ember pair (hazard), RGB on void black (brief P1)",
}


def phase_is_d(family: str, name: str) -> bool:
    return any(name.startswith(p) for p in PHASE_D_PREFIXES[family])

def ship_purpose(name: str) -> str:
    stem = name[:-4]
    view = ""
    for suf, label in VIEW_SUFFIX.items():
        if stem.endswith(suf):
            view = label
            stem = stem[: -len(suf)]
            break
    livery = ""
    for code, text in LIVERY_CODES.items():
        if stem.endswith("_" + code):
            livery = " " + text
            stem = stem[: -len(code) - 1]
            break
    role = next((v for k, v in sorted(SHIP_ROLES.items(), key=lambda kv: -len(kv[0])) if stem == k), None)
    if role is None:
        return "Ship sprite."
    if view:
        return f"{role}. Rotation sheet: {view}.{livery}"
    return f"{role}. Single centred render.{livery}"


def icon_purpose(name: str) -> str:
    stem = name[:-4]
    if stem.startswith("panel_"):
        base = next((k for k in PANEL_PURPOSE if stem == k), None)
        what = f" ({PANEL_PURPOSE[base]})" if base else ""
        return f"Icon atlas panel, 2K{what}. Source of the cut icon_* sprites; not a runtime sprite."
    if name.endswith(".svg"):
        return ("Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). "
                "The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family "
                "and its tint stencils (D2 icon unification, 2026-09-22).")
    base, suffix = stem, ""
    for s in ("_16", "_48", "_96", "_192"):
        if stem.endswith(s):
            base, suffix = stem[: -len(s)], s[1:]
            break
    flat = base in B_FLAT_ICONS or base in F_FLAT_ICONS
    if suffix:
        if not flat:
            return f"Painted icon split, {suffix} px. Direct consumer, no tint derivation (expansion spec 11.2)."
        # ICONS_SPEC 9.2: _16 micro chips, _48 legacy consumers, _96 the default band
        # for new consumers (1:1 at 4K / 2x canvas), _192 detail and 4K+UI-scale headroom.
        role = {"16": "micro chip band (HUD spots; ICONS_SPEC 6 legibility check)",
                "48": "legacy consumer band (never silently re-pointed)",
                "96": "default band for new consumers (1:1 at 4K / 2x canvas)",
                "192": "detail band (inspect panes, 4K + UI-scale headroom)"}[suffix]
        return (f"Flat single-colour glyph, {suffix} px, {role}; contain-fit cut from the master, "
                f"tintable via icons/tint/ (ICONS_SPEC 9.2/9.6).")
    if flat:
        return "Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts)."
    return "Painted icon master (source of the icon splits; not a runtime sprite)."


def env_purpose(name: str) -> str:
    stem = name[:-4]
    for base, text in sorted(ENV_PURPOSE.items(), key=lambda kv: -len(kv[0])):
        if stem == base or stem.startswith(base + "_") or (base.endswith("asteroid") and stem.startswith(base)):
            if base == "env_asteroid":
                tier = stem.split("_")[2]
                return f"Asteroid sprite, size tier {tier} (S/M/L x1-3; ENVIRONMENT_SPEC 4)."
            return text + "."
    return "Environment sprite."


def ui_purpose(name: str) -> str:
    stem = name[:-4]
    if stem.endswith("@2x"):
        # UI_CHROME_ASSETS_SPEC section 10: the same retained 2K source cut at twice the
        # logical box; display size stays logical, the coder scales it explicitly.
        base = stem[: -len("@2x")]
        if base == "ui_panel_frame":
            return ("9-slice panel frame, 192x192 with a 64 px painted border band, "
                    "2x cut of the 96x96 frame (ICONS_SPEC 9.8 C1; "
                    "UI_CHROME_ASSETS_SPEC 10).")
        if base in UI_PURPOSE:
            return UI_PURPOSE[base] + " (2x cut, UI_CHROME_ASSETS_SPEC 10)."
        if base.startswith("ui_button_plate_"):
            state = base.split("ui_button_plate_")[1]
            return f"UI button plate, {state} state, 560x112 2x cut (UI_CHROME_ASSETS_SPEC 10)."
        if base.startswith("ui_slot_"):
            parts = base.split("_")
            return (f"Slot plate: {parts[2]} slot, {parts[3]} state, 2x cut "
                    f"(UI_CHROME_ASSETS_SPEC 10).")
        return "UI chrome 2x cut (UI_CHROME_ASSETS_SPEC 10)."
    if stem in UI_PURPOSE:
        return UI_PURPOSE[stem] + ("." if not UI_PURPOSE[stem].endswith(")") else "")
    if stem.startswith("ui_button_plate_"):
        state = stem.split("ui_button_plate_")[1]
        return f"UI button plate, {state} state, 280x56 (UI_CHROME_ASSETS_SPEC)."
    if stem.startswith("ui_slot_"):
        parts = stem.split("_")
        kind, state = parts[2], parts[3]
        return f"Slot plate: {kind} slot, {state} state (UI_CHROME_ASSETS_SPEC)."
    return "UI sprite."


def fx_purpose(name: str) -> str:
    return FX_PURPOSE.get(name[:-4], "FX sprite.") + ("." if not FX_PURPOSE.get(name[:-4], "").endswith(")") else "")


PURPOSE = {"ships": ship_purpose, "icons": icon_purpose, "env": env_purpose, "ui": ui_purpose, "fx": fx_purpose}
FAMILY_TITLE = {
    "ships": "ships - hulls, bosses, liveries",
    "icons": "icons - glyphs, item art, starmap markers",
    "env": "env - scenery, POIs, pickups, props",
    "ui": "ui - chrome, insignia, backdrops",
    "fx": "fx - combat and screen effects",
}


def audio_rows() -> tuple[list[str], dict[str, int]]:
    """Rows for the audio family, read from the audio build report (not the filesystem).

    The report carries what a directory listing cannot: length, channel count, loop flag,
    processing mode and the source pack each file came from.
    """
    if not AUDIO_REPORT.exists():
        return [], {}
    report = json.loads(AUDIO_REPORT.read_text(encoding="utf-8"))
    by_bus: dict[str, int] = {}
    rows: list[str] = []
    for entry in sorted(report, key=lambda item: item["dest"]):
        parts = entry["dest"].split("assets/audio/")[-1].split("/")
        if len(parts) != 2:
            continue
        bus, name = parts
        by_bus[bus] = by_bus.get(bus, 0) + 1
        rows.append(
            f"| `{name}` | {entry['duration_s']} | {entry['channels']} | "
            f"{'yes' if entry['loops'] else '-'} | {entry['mode']} | {entry['note']} | "
            f"{entry['source'].split('/')[0]} ({entry['author']}) |"
        )
    return rows, by_bus


def family_files(family: str) -> list[Path]:
    root = ASSETS / family
    files = [p for p in sorted(root.iterdir()) if p.suffix in (".png", ".svg")]
    if family == "icons":
        for sub in sorted(root.iterdir()):
            if sub.is_dir() and sub.name != "tint" and not sub.name.startswith("2026"):
                files += [p for p in sorted(sub.iterdir()) if p.suffix in (".png", ".svg")]
    return files


def svg_size(path: Path) -> str:
    head = path.read_text(encoding="utf-8", errors="replace")[:400]
    w = re.search(r'width="(\d+)', head)
    h = re.search(r'height="(\d+)', head)
    return f"{w.group(1) if w else '?'}x{h.group(1) if h else '?'}"


def row(family: str, path: Path) -> str:
    if path.suffix == ".svg":
        size, alpha = svg_size(path), "rgba"
    else:
        im = Image.open(path)
        size, alpha = f"{im.size[0]}x{im.size[1]}", ("rgba" if im.mode == "RGBA" else "rgb")
    ph = phase_label(family, path.name)
    return f"| `{path.name}` | {size} | {alpha} | {ph} | {PURPOSE[family](path.name)} |"


def main() -> None:
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines: list[str] = []
    lines.append("# Vajb Orbit - Asset Catalog")
    lines.append("")
    lines.append(f"**Generated:** {stamp} from `vajb-orbit/assets/` by `staging/phase_d/build_catalog.py`. "
                 "Tables are mechanical (filesystem); do not hand-edit - regenerate instead.")
    lines.append("")
    lines.append("**Scope:** Phase B (109 files, `GENERATION_PLAN.md`) + Phase D expansion "
                 "(141 files, `ASSET_EXPANSION_SPEC.md`) + Phase E expansion "
                 "(67 files, `ASSET_EXPANSION_SPEC_E.md`) + Phase F RPG/economy layer "
                 "(`docs/gameplay/16_art_design_brief.md`) + the F.1 resolution and integrity "
                 "pass (icon quartet, `ICONS_SPEC.md` 9.7) + the audio family "
                 "(95 files, `AUDIO_SPEC.md` section 8), all imported by the live editor.")
    lines.append("")
    lines.append("## How to use")
    lines.append("")
    lines.append("- Paths below are relative to `vajb-orbit/`; load as `res://assets/...`. Every file is imported "
                 "(.import sidecars exist).")
    lines.append("- Column `ph`: `F`/`E`/`D` = expansion phases F (RPG/economy layer), E (bases, outposts, "
                 "bodies, asteroid set B) and D; `B` = original Phase B set.")
    lines.append("- Column `a`: `rgba` = sprite with real alpha (cut locally, see expansion spec 11.1); "
                 "`rgb` = opaque (FX on void black for additive blending, backdrops, tiling layers).")
    lines.append("- Each sprite has a `<file>.job.json` manifest (prompt/model/seed/date) next to it; per-family "
                 "`generation_log.md` and `generation_log_phase_d.md` hold the full history.")
    lines.append("- Audio rows come from `staging/audio/audio_report.json`; per-file provenance and loop-seam "
                 "measurements are in `vajb-orbit/assets/audio/generation_log_audio.md`, and the cue names the "
                 "code can pass today are in `docs/design/ASSET_WIRING_HANDOFF.md`.")
    lines.append("- Never reference these from code, they are provenance only: `style-block.txt`, "
                 "the `20260917-*`/`20260918-*` run folders (raw generator downloads), and `icons/tint/` "
                 "(derived white stencils; only the flat glyphs are consumed tinted).")
    lines.append("- Visual review sheets (Phase D marked in ember): `staging/phase_d/_preview/review_<family>.png`.")
    lines.append("")

    family_rows: dict[str, list[str]] = {}
    stats: dict[str, tuple[int, int, int, int]] = {}
    for family in ("ships", "icons", "env", "ui", "fx"):
        files = family_files(family)
        family_rows[family] = [row(family, p) for p in files]
        labels = [phase_label(family, p.name) for p in files]
        stats[family] = (labels.count("B"), labels.count("D"), labels.count("E"), labels.count("F"))

    total_b = sum(b for b, _, _, _ in stats.values())
    total_d = sum(d for _, d, _, _ in stats.values())
    total_e = sum(e for _, _, e, _ in stats.values())
    total_f = sum(f for _, _, _, f in stats.values())
    audio, audio_by_bus = audio_rows()
    lines.append("## Summary")
    lines.append("")
    lines.append("| Folder | Files | Phase B | Phase D | Phase E | Phase F |")
    lines.append("|---|---|---|---|---|---|")
    for family in ("ships", "icons", "env", "ui", "fx"):
        b, d, e, f = stats[family]
        lines.append(f"| `res://assets/{family}/` | {b + d + e + f} | {b} | {d} | {e} | {f} |")
    lines.append(f"| **Total** | **{total_b + total_d + total_e + total_f}** | **{total_b}** | "
                 f"**{total_d}** | **{total_e}** | **{total_f}** |")
    lines.append("")
    lines.append("| Audio folder | Files |")
    lines.append("|---|---|")
    for bus in AUDIO_DIRS:
        lines.append(f"| `res://assets/audio/{bus}/` | {audio_by_bus.get(bus, 0)} |")
    lines.append(f"| **Audio total** | **{len(audio)}** |")
    lines.append("")

    for family in ("ships", "icons", "env", "ui", "fx"):
        lines.append(f"## {FAMILY_TITLE[family]}")
        lines.append("")
        lines.append("| File | px | a | ph | Purpose |")
        lines.append("|---|---|---|---|---|")
        lines.extend(family_rows[family])
        lines.append("")

    lines.append("## audio - music, sfx, ambience, ui")
    lines.append("")
    lines.append("Cue resolution and the names the code can pass today: `docs/design/ASSET_WIRING_HANDOFF.md`.")
    lines.append("")
    lines.append("| File | Len s | Ch | Loop | Mode | Purpose | Source |")
    lines.append("|---|---|---|---|---|---|---|")
    lines.extend(audio)
    lines.append("")

    lines.append("## Provenance appendix")
    lines.append("")
    lines.append(f"- Audio (`audio/generation_log_audio.md`): every file is CC0 1.0, no attribution required. "
                 "25 sources were downloaded into `asset-library/` and recorded in "
                 "`asset-library/ASSET_MANIFEST.json` with their checksums; the per-file source pack, author "
                 "and URL are in the table above and in the generation log.")
    run_dirs = sum(1 for family in ("ships", "icons", "env", "ui", "fx")
                   for p in (ASSETS / family).glob("2026*") if p.is_dir())
    tint = len(list((ASSETS / "icons" / "tint").glob("*.png")))
    lines.append(f"- Run folders (`assets/<family>/20260917-*/`): {run_dirs} directories holding the raw generator "
                 "downloads and their `job.json`; kept for provenance, not consumers.")
    lines.append(f"- `icons/tint/`: {tint} PNGs, derived white stencils (RGB = white, alpha byte-identical) of the "
                 "raster-kept icon masters' historical size cuts, written by `tools/derive_icon_tints.gd`. Engine-side "
                 "modulate tints them with theme colours. The 135 SVG-side symbols' stencils were retired with their "
                 "raster families (D2 icon unification, 2026-09-22); the painted D/E stencils stay unused until the "
                 "tint rework (D3 item 2).")
    lines.append("- Phase D panel masters (`panel_equipment`, `panel_map_markers`, `panel_pickups`, "
                 "`panel_insignia`, `panel_props`) were consumed during splitting and deleted with the other "
                 "intermediates; only the splits ship (deviation from expansion spec 2.6, recorded in 12).")
    lines.append("- Phase F panel masters (`panel_minerals_ore`, `panel_minerals_ingot`, `panel_modules_a/b/c`, "
                 "`panel_slots`, `panel_contracts`, `panel_service_glyphs`, `panel_faction_insignia`) never "
                 "entered `assets/`: they stay in `staging/phase_f/<family>/` with their `job.json` files as "
                 "provenance, and only the cut sprites ship. Per-family evidence: "
                 "`assets/<family>/generation_log_phase_f.md`.")
    lines.append("")

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {total_b + total_d + total_e + total_f} art files "
          f"({total_b} B / {total_d} D / {total_e} E / {total_f} F), {len(audio)} audio, "
          f"run dirs {run_dirs}, tint {tint}")


if __name__ == "__main__":
    main()
