"""The naming decisions, as data, so the rename engine applies them and nothing is guessed.

Owner rulings, 2026-09-20. Every one of these is folded in below:

1. the 17 off-brief icon sheets are parked as declared alternates, `panel_alt_<NN>` for the
   sheet and `icon_alt_<subject>` for each cell, named from what the render shows;
2. the second renders of named art are dropped;
3. the four sector backdrop plates extend the roster to `env_sector_8_bg` to `_11_bg`;
4. the F.1 ice-moon re-render swaps into `env_body_ice_moon` and the old render becomes `_prev`;
5. the nine names that contradict their picture, the bar caps and the muzzle flash frames are
   handled as recommended: eight star-ship renders that defied their brief are dropped, the two
   genuine ember rings and the one genuine starfield are kept and named, the four muzzle flash
   frames take the names FX_SPEC section 3 sanctions.

Every row cites the evidence its name rests on:

    icons-spec-7/8.x  a name ICONS_SPEC orders for that panel
    fx-spec-3         a frame-split name FX_SPEC section 3 sanctions
    catalog           a name the shipped catalog already files under that folder
    matches-<n>       the pixels: `find_matches.py` scored this sheet against named art, so it
                      is a second render of that art
    stamp-absent      the stamp is spurious and no file holds the plain name
    render            the render itself, used only for alternates, which are declared as such
    owner             an owner ruling recorded in the note

Usage:
    py -3.14 staging/cut/naming_assignments.py            # write _naming/assignments.tsv
    py -3.14 staging/cut/naming_assignments.py --brief    # the ruling summary
"""
from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
OUT = Path(__file__).resolve().parent / "_naming"

# Sheets whose stamp is spurious: the plain name never existed, so the sheet owns the art and its
# cells already carry the sanctioned names. Only the sheet's own name changes.
SPURIOUS = {
    "raw/icon_module__20260918-114107.png": ("panel_modules_a", "icons-spec-8.2",
        "its cells are icon_module_w_railgun onwards, which is section 8.2 panel_modules_a"),
    "raw/icon_module__20260918-114156.png": ("panel_modules_b", "icons-spec-8.2",
        "its cells are icon_module_p_mk2 onwards, which is section 8.2 panel_modules_b"),
    "raw/icon_module__20260918-114240.png": ("panel_modules_c", "icons-spec-8.2",
        "its cells are icon_module_c_twin onwards, which is section 8.2 panel_modules_c"),
    "raw/ui_button_plate__20260918-133142.png": ("panel_button_plates", "catalog",
        "its cells own the four ui_button_plate_ names, so this is the panel master"),
}

# Second renders of art that already has a name, measured by find_matches.py against already
# named sprites in the same family. Owner ruling: dropped.
SECOND_RENDER = {
    "raw/p2_contracts.png": 0.963,
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-123214.png": 0.984,
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-111327.png": 0.913,
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-113357.png": 0.853,
    "raw/same-2x2-rotation-sheet-of-the-same-enem__20260918-112624.png": 0.978,
    "raw/same-2x2-rotation-sheet-of-the-same-enem__20260918-112721.png": 0.978,
    "raw/ship_drone_swarm__20260917-213637.png": 0.891,
    "raw/body_ice_moon.png": 0.869,
    "raw/ui_button_plate__20260917-185457.png": 0.530,
}

# The off-brief icon sheets. Owner ruling: park as declared alternates. The sheet takes
# panel_alt_<NN> and each cell takes icon_alt_<subject> read from the render.
OFF_BRIEF = (
    "raw/flat-vector-icon-sheet-2x2-grid-icons.png",
    "raw/flat-vector-icon-sheet-3x3-grid-icons__20260918-110409.png",
    "raw/flat-vector-icon-sheet-3x3-grid-icons__20260918-110458.png",
    "raw/flat-vector-icon-sheet-3x3-grid-icons__20260918-110547.png",
    "raw/flat-vector-icon-sheet-4x2-grid-icons__20260918-110642.png",
    "raw/flat-vector-icon-sheet-4x2-grid-icons__20260918-110921.png",
    "raw/flat-vector-icon-sheet-5x4-grid-icons__20260918-110236.png",
    "raw/flat-vector-icon-sheet-5x4-grid-icons__20260918-110318.png",
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-111044.png",
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-111411.png",
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-111450.png",
    "raw/grimdark-painted-sci-fi-semi-realistic__20260918-133035.png",
    "raw/same-2x2-rotation-sheet-of-the-same-enem__20260918-112813.png",
    "raw/p2_faction_insignia.png",
    "raw/flat-vector-icon-sheet-for-a-dark-sci-fi.png",
    "raw/ui-button-plate-a-square-panel-with-fou.png",
)

# 16:9 plates that extend the sector roster. Owner ruling 3.
SECTOR_PLATES = {
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111724.png": "env_sector_8_bg",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111829.png": "env_sector_9_bg",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-111927.png": "env_sector_10_bg",
    "raw/sector-backdrop-plate-a-wide-16-9-cinem__20260918-112053.png": "env_sector_11_bg",
}

# The F.1 ice-moon swap. Owner ruling 4: the re-render wins the plain name, the old one is kept
# as a record rather than deleted, because it is a different render of the same body.
SWAP = {
    "raw/env_body_ice_moon.png": "env_body_ice_moon_prev",
    "raw/f1_ice_moon.png": "env_body_ice_moon",
    "cut/env_body_ice_moon.png": "env_body_ice_moon_prev",
    "cut/env_sheet_1x1_20260918_123247.png": "env_body_ice_moon",
}

# Renders that defied their brief and hold a spaceship where the name promises a layer or an
# effect. Owner ruling 5: dropped. Each was looked at against its own prompt.
SHIPS_THAT_LIE = {
    "raw/seamless-tileable-starfield-layer-a-fla.png": "asks for star points, holds a combat starship",
    "raw/seamless-tileable-void-haze-layer-soft.png": "asks for soft haze, holds a fleet",
    "raw/seamless-tileable-foreground-dust-layer.png": "asks for dust motes, holds a damaged ship",
    "raw/seamless-tileable-void-haze-texture-abs.png": "forbids spaceships, holds a battlecruiser",
    "raw/deep-space-nebula-veil-a-single-square.png": "asks for a wash, holds a war fleet",
    "raw/full-screen-vignette-burnt-ember-c8461.png": "asks for an empty vignette, holds a battleship",
    "raw/single-thin-horizontal-ember-streak-bur.png": "asks for a streak, holds a whole ship",
    "raw/small-radial-ember-glow-orb-soft-radial.png": "asks for a glow, holds an industrial ship",
}

# Kept and named, with the reason each name is defensible.
NAMED_ODD = {
    "raw/seamless-repeating-pattern-wallpaper-tex.png": ("env_stars_layer4", "catalog",
        "the one abstract-layer run that honoured its brief: a genuine starfield. The catalog "
        "carries env_stars_layer1 to _3, so this is the fourth layer the owner asked for"),
    "raw/single-small-energy-ring-burnt-ember-c__20260917-183628.png": ("fx_ember_ring", "render",
        "a genuine ember ring, the only isolated-effect run that honoured its brief"),
    "raw/single-small-energy-ring-burnt-ember-c__20260917-184216.png": ("fx_ember_ring_alt",
        "render", "the second ember ring render, kept as a declared alternate"),
    "raw/4-frame-horizontal-sprite-sheet-of-a-wea.png": ("fx_muzzle_flash_frames", "fx-spec-3",
        "four muzzle flash frames in reading order, which FX_SPEC section 3 sanctions as "
        "fx_muzzle_flash_f1 to _f4"),
    "raw/mining-base-structure-a-station-scale-i.png": ("env_base_mining_alt", "render",
        "an industrial mining station that honoured its brief, kept as a declared alternate "
        "because the catalogued env_base_mining is a different render"),
    "raw/ui-bar-caps-and-ui-minimap-bezel-one-pa.png": ("ui_bar_caps_sheet", "render",
        "the sheet behind ui_bar_caps and ui_minimap_bezel. Its two cells already have those "
        "names and they stay; the caps want splitting into left and right sprites, which is a "
        "re-cut, not a rename"),
    "raw/f1_panel_frame.png": ("ui_panel_frame_alt", "render",
        "the F.1 nine-slice frame pass, scoring 0.807 against ui_minimap_bezel: a frame, kept as "
        "a declared alternate because the catalogued ui_panel_frame is a different render"),
}

# Cells whose own name is already right, so only the sheet is renamed.
SHEET_ONLY = {"raw/ui-bar-caps-and-ui-minimap-bezel-one-pa.png"}

# Anything the first pass left carrying an old shape. Keyed sheets keep a `__keyed` marker
# because they are references, not assets, so their base takes the name its sheet took.
RESIDUAL = {
    "raw/ship_drone_swarm__20260918-133108.png": ("ship_drone_swarm", "common-stem",
        "the newer drone swarm sheet owns the four view names, so its own name takes their stem"),
    "raw/f1_panel_frame__keyed.png": ("ui_panel_frame_alt__keyed", "render",
        "the keyed reference of the F.1 frame sheet, which is parked as ui_panel_frame_alt"),
    "raw/ui-bar-caps-and-ui-minimap-bezel-one-pa__keyed.png": ("ui_bar_caps_sheet__keyed",
        "render", "the keyed reference of the bar caps sheet, parked as ui_bar_caps_sheet"),
    "raw/ui-button-plate-a-square-panel-with-fou__keyed.png":
        ("panel_alt_metal_button_plates_four__keyed", "render",
         "the keyed reference of the parked button plate sheet"),
}

# The shipped manifest is the arbiter of a sanctioned name. `_deleted_manifest.json` records, for
# every file the catalog shipped, the sheet it was cut from. A name that shipped belongs to the
# sprite cut from that sheet, whichever render happens to be newest: the game already loads it.
# Four glyphs were mis-filed as alternates because their sheet looked off-brief, and this is what
# caught it.
SHIPPED_OVERRIDES = {
    "cut/icons/alt/icon_alt_zoom_in.png": ("icon_zoom_plus", "shipped-manifest",
        "icons/icon_zoom_plus.png shipped from this cell of grimdark-...-133035__raw.png"),
    "cut/icons/alt/icon_alt_zoom_out.png": ("icon_zoom_minus", "shipped-manifest",
        "icons/icon_zoom_minus.png shipped from this cell of grimdark-...-133035__raw.png"),
    "cut/icons/alt/icon_alt_hexagon_info.png": ("icon_credits", "shipped-manifest",
        "icons/icon_credits.png shipped from this cell of grimdark-...-133035__raw.png"),
    "cut/icons/alt/icon_alt_shield_2.png": ("icon_shield", "shipped-manifest",
        "icons/icon_shield.png shipped from this cell of grimdark-...-133035__raw.png"),
    "raw/icons/panel_alt_black_sci_fi_set.png": ("panel_hud_controls", "shipped-manifest",
        "the sheet behind the four shipped HUD glyphs, so it is a panel master and not an alternate"),
}

# The panel masters the specs name. A sheet that produced an ordered glyph set takes the master
# name `ICONS_SPEC.md` gives it, so a doc that says "panel_slots is the master of icon_slot_*" is
# true of this library too. The three painted sheets (`ui_insignia`, `env_pickup`, `env_prop`)
# are deliberately left alone: their cells are painted sprites whose stems must stay aligned with
# the sheet, and the doc names describe atlas regions inside them.
PANEL_MASTERS = {
    "raw/icons/mineral/icon_mineral.png": "panel_minerals_ore",
    "raw/icons/ingot/icon_ingot.png": "panel_minerals_ingot",
    "raw/icons/slot/icon_slot.png": "panel_slots",
    "raw/icons/contract/icon_contract.png": "panel_contracts",
    "raw/icons/service/icon_service.png": "panel_service_glyphs",
    "raw/icons/map/icon_map.png": "panel_map_markers",
    "raw/icons/booster/icon_booster.png": "panel_boosters",
    "raw/icons/status/icon_status.png": "panel_status",
    "raw/icons/panel_alt_hexagonal_insignia_set.png": "panel_faction_insignia",
}

# The three faction insignia are a sanctioned panel set, so their glyphs keep the sanctioned
# names. The cell order is the spec's: Concord three stacked bars, Meridian split hex, Choir
# flame, and each render read confirms it.
INSIGNIA_RESTORE = {
    "cut/icons/alt/icon_alt_three_slat_insignia.png": ("icon_insignia_concord",
        "icons-spec-8.5", "the three-stacked-bar read is Concord, in the spec's cell order"),
    "cut/icons/alt/icon_alt_split_hex_insignia.png": ("icon_insignia_meridian",
        "icons-spec-8.5", "the split hexagon read is Meridian"),
    "cut/icons/alt/icon_alt_flame_leaf_insignia.png": ("icon_insignia_choir",
        "icons-spec-8.5", "the flame-tongue read is Choir"),
}

# Frames and alternates carry a qualifier the spec declares for that purpose.
FRAMES = ("f1", "f2", "f3", "f4")
STOP = {"icon", "icons", "the", "a", "of", "and"}


def slug(text: str, limit: int = 4) -> str:
    words = [w for w in re.split(r"[^a-z0-9]+", text.lower()) if w and w not in STOP]
    return "_".join(words[:limit]) or "unnamed"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--brief", action="store_true")
    args = parser.parse_args()

    library = json.loads((LIBRARY / "_library.json").read_text(encoding="utf-8"))
    assets = library["assets"]
    issues = library["name_issues"]
    plan = {e["raw"]: e for e in
            json.loads((LIBRARY / "_sheets.json").read_text(encoding="utf-8"))["sheets"]}
    vision = json.loads((LIBRARY / "_vision.json").read_text(encoding="utf-8"))["files"]

    names = {r["name"] for r in assets.values()}
    taken = set(names)
    rows = [["path", "action", "new_name", "evidence", "note"]]
    counts: collections.Counter[str] = collections.Counter()

    def add(path: str, action: str, name: str, evidence: str, note: str) -> None:
        if not (LIBRARY / path).exists():
            return  # a later pass already moved it; the table describes the library as it is
        rows.append([path, action, name, evidence, note])
        counts[action] += 1

    def cells(sheet: str) -> list[str]:
        return plan.get(sheet, {}).get("cuts") or []

    def unique(name: str) -> str:
        if name not in taken:
            taken.add(name)
            return name
        index = 2
        while f"{name}_{index}" in taken:
            index += 1
        taken.add(f"{name}_{index}")
        return f"{name}_{index}"

    # 1. stamped twins where the plain name exists: dropped. Elsewhere the stamp is spurious.
    for rel in sorted(issues.get("twin") or []):
        stem = assets[rel]["name"]
        plain = re.sub(r"__\d{8}-\d{6}$", "", stem)
        if plain in names:
            add(rel, "drop", "", "owner",
                f"second render of {plain}, which stays; owner ruling drops the twin")
        else:
            add(rel, "keep", stem, "stamp-absent", "the stamp is spurious, handled below")

    # 2. spurious stamps: the sheet owns its art, only the sheet name changes
    for rel, (name, evidence, note) in sorted(SPURIOUS.items()):
        add(rel, "rename", name, evidence, note)

    # 3. second renders and ship renders that lie: dropped, with their cells
    for rel, score in sorted(SECOND_RENDER.items()):
        add(rel, "drop", "", f"matches-{score:.3f}",
            f"its cells score {score:.3f} against named art, so it is a second render")
        for cut in cells(rel):
            add(f"cut/{cut}.png", "drop", "", f"matches-{score:.3f}",
                "a cell of a second render")
    for rel, why in sorted(SHIPS_THAT_LIE.items()):
        add(rel, "drop", "", "owner", f"name contradicts the picture: {why}")
        for cut in cells(rel):
            add(f"cut/{cut}.png", "drop", "", "owner", f"a cell of a render that lied: {why}")
    logo = "raw/logo-vajb-orbit-the-word-vajb-orbit-as.png"
    add(logo, "drop", "", "owner",
        "the wordmark again, over a starfield, so it cannot be keyed; the plain logo stays")
    for cut in cells(logo):
        add(f"cut/{cut}.png", "drop", "", "owner", "the wordmark cut off the unkeyable logo sheet")

    # 4. kept and named odd files
    for rel, (name, evidence, note) in sorted(NAMED_ODD.items()):
        add(rel, "rename", unique(name), evidence, note)
        if rel in SHEET_ONLY:
            continue
        cuts = cells(rel)
        if rel.endswith("4-frame-horizontal-sprite-sheet-of-a-wea.png"):
            for index, cut in enumerate(cuts):
                add(f"cut/{cut}.png", "rename", f"fx_muzzle_flash_f{index + 1}", "fx-spec-3",
                    "a frame of the muzzle flash animation, sanctioned by FX_SPEC section 3")
        else:
            for cut in cuts:
                add(f"cut/{cut}.png", "rename", name, "render",
                    "the sprite cut off the sheet of the same name")

    # 5. sector plates, and the plates cut from them
    for rel, name in sorted(SECTOR_PLATES.items()):
        add(rel, "rename", name, "catalog",
            "a 16:9 backdrop plate; the roster extends past the catalogued seven")
        for cut in cells(rel):
            add(f"cut/{cut}.png", "rename", name, "catalog", "the plate cut off its sheet")

    # 6. the ice-moon swap
    for rel, name in sorted(SWAP.items()):
        add(rel, "swap", name, "matches-0.941",
            "the F.1 re-render takes the plain name; the older render is kept as _prev")

    # 7. the off-brief icon sheets: declared alternates, named from the render
    for rel in sorted(OFF_BRIEF):
        sheet_name = unique(f"panel_alt_{slug(vision.get(rel, {}).get('sheet_subject')
                                             or Path(rel).stem)}")
        add(rel, "rename", sheet_name, "owner-alt",
            "off-brief sheet: no spec orders its panels, parked as a declared alternate")
        objects = vision.get(rel, {}).get("objects") or []
        for position, cut in enumerate(cells(rel)):
            subject = objects[position] if position < len(objects) else f"part {position + 1}"
            add(f"cut/{cut}.png", "rename", unique(f"icon_alt_{slug(subject)}"), "owner-alt",
                f"off-brief glyph reading '{subject}', parked under icons/alt")

    # 8. the keyed survivors of the old matte: kept deliberately, they are not assets
    for rel, rec in sorted(assets.items()):
        if rec["role"] == "sheet-keyed":
            add(rel, "keep", rec["name"], "keyed-reference",
                "output of the discarded v1 matte, held as a reference and never shipped")

    # 10. what a first pass left carrying an old shape
    for rel, (name, evidence, note) in sorted(RESIDUAL.items()):
        add(rel, "rename", name, evidence, note)

    # 11. names the shipped catalog already loads, restored to the sprite that shipped them
    for rel, (name, evidence, note) in sorted(SHIPPED_OVERRIDES.items()):
        add(rel, "rename", name, evidence, note)

    # 12. the panel masters the specs name, and the sanctioned insignia set
    for rel, name in sorted(PANEL_MASTERS.items()):
        add(rel, "rename", name, "icons-spec-8",
            "the specs name this sheet as the panel master of the glyph set it produced")
    for rel, (name, evidence, note) in sorted(INSIGNIA_RESTORE.items()):
        add(rel, "rename", name, evidence, note)

    # 13. anything broken still unaccounted for
    decided = {r[0] for r in rows[1:]}
    for key, rels in sorted(issues.items()):
        for rel in sorted(rels):
            if rel in decided:
                continue
            add(rel, "keep", assets[rel]["name"], f"unresolved-{key}",
                f"no evidence names this; left alone and reported as unresolved {key}")
            for cut in cells(rel):
                path = f"cut/{cut}.png"
                if path not in decided:
                    add(path, "keep", cut, f"unresolved-{key}",
                        f"no evidence names this; left alone and reported as unresolved {key}")

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "assignments.tsv").write_text(
        "\n".join("\t".join(str(c) for c in row) for row in rows) + "\n", encoding="utf-8")

    print(f"rows: {len(rows) - 1}")
    for action, count in sorted(counts.items()):
        print(f"  {action:<8} {count}")
    if args.brief:
        print()
        for row in rows[1:]:
            if row[1] == "keep" and "unresolved" in row[3]:
                print(f"  unresolved: {row[0]}")


if __name__ == "__main__":
    main()
