"""Wave 1 driver for the Phase D asset expansion (docs/design/ASSET_EXPANSION_SPEC.md).

Usage:
    python staging/phase_d/wave1.py <run-id> [<run-id> ...]
    python staging/phase_d/wave1.py --list

Each run shells out to the image-generator skill once (one paid API call), then
alpha-processes, splits, renames and logs the result locally. Free post-processing
only: no extra API calls after the generation itself.
"""
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[2]
PROJECT = WORKSPACE / "vajb-orbit"
STAGE = WORKSPACE / "staging" / "phase_d"
STYLE_FILE = PROJECT / "assets" / "style-block.txt"
SKILL = Path(r"C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py")
PY = sys.executable
# The `python` on PATH is Inkscape's bundled interpreter and has no CA roots, which
# breaks TLS for the generator. Run this driver under the python.org 3.14 build
# (`py -3.14`) and hand the same interpreter to the generator.
CA_BUNDLE = r"C:/Users/Kamil/AppData/Local/Python/pythoncore-3.14-64/Lib/site-packages/certifi/cacert.pem"

SHIP_NEG = ("no chrome, no neon, no saturated colours, no second accent, no perspective, "
            "no tilt, no text, no watermark, no grid lines, no labels.")
ICON_NEG = ("no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, "
            "no shadows, no text, no watermark, no grid lines, no labels, no multicolour.")
ENV_NEG = ("no planets with atmospheres, no clouds, no bright nebula, no saturated colours, "
           "no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.")
FX_NEG = ("no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, "
          "no text, no watermark, no grid lines, no frames, no UI chrome.")

SHEET_GRID = ("four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, "
              "the four ships isolated on a fully transparent background with completely empty transparent "
              "margins separating the cells so they can be cut apart, no background colour, no backdrop, "
              "no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt "
              "and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, "
              "bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, "
              "bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, "
              "centroid at its cell centre. Identical proportions, identical palette and identical lighting in all "
              "four cells. ")


def ship_sheet(subject):
    return subject + " " + SHEET_GRID + SHIP_NEG


ICON_PANEL_FRAME = ("flat vector icon sheet, {grid} grid (icons arranged left to right, top to bottom), generous even "
                    "gaps between icons, plain solid pure white background, isolated objects, icons drawn as "
                    "single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred "
                    "corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the "
                    "painted metal style. Subjects in reading order: {subjects}. " + ICON_NEG)

RUNS = {
    # ---------------- ships: hostile ---------------
    "ship_interceptor": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_interceptor_front", "ship_interceptor_three_quarter", "ship_interceptor_side", "ship_interceptor_back"],
        subject=ship_sheet(
            "Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, "
            "visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a "
            "fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine "
            "nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, "
            "scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail "
            "nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. "
            "Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim.")),
    "ship_gunship": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_gunship_front", "ship_gunship_three_quarter", "ship_gunship_side", "ship_gunship_back"],
        subject=ship_sheet(
            "Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly "
            "the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a "
            "squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods "
            "dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with "
            "dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull "
            "grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow "
            "E8703A halos, small and hot, no other glow.")),
    "ship_destroyer": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_destroyer_front", "ship_destroyer_three_quarter", "ship_destroyer_side", "ship_destroyer_back"],
        subject=ship_sheet(
            "Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest "
            "hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a "
            "flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row "
            "and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line "
            "hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, "
            "oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with "
            "small hot ember glow E8703A halos, small and hot, no other glow.")),
    "ship_drone_swarm": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_drone_swarm_front", "ship_drone_swarm_three_quarter", "ship_drone_swarm_side", "ship_drone_swarm_back"],
        subject=ship_sheet(
            "Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular "
            "shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, "
            "no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, "
            "immediately readable as smaller than every other hull. Weathering density: light, scratches and hull "
            "grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. "
            "The drone is drawn small inside each cell, occupying about 40 percent of its cell width.")),
    # ---------------- ships: neutral ----------------
    "ship_trader": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_trader_front", "ship_trader_three_quarter", "ship_trader_side", "ship_trader_back"],
        subject=ship_sheet(
            "Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy "
            "segmented hull with external container racks running along both flanks, four identical containers per "
            "side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external "
            "container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: "
            "heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no "
            "battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow "
            "E8703A halo, civilian throttle, small and contained, no other glow.")),
    "ship_patrol": dict(
        family="ships", aspect="1:1", mode="ship_sheet", cuts=["ship_patrol_front", "ship_patrol_three_quarter", "ship_patrol_side", "ship_patrol_back"],
        subject=ship_sheet(
            "Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, "
            "noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, "
            "a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; "
            "no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, "
            "oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot "
            "ember glow E8703A halos, small and hot, no other glow.")),
    # ---------------- bosses ----------------
    "ship_boss_thorn": dict(
        family="ships", aspect="1:1", mode="single_trim", subject=(
            "Hive-mother boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt "
            "and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame "
            "centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. "
            "Silhouette: a huge broad carapace hull with short thorned protrusions radiating from the bow and both "
            "flanks, each thorn large enough to catch the rim light on its edge, four spore vent blocks along the "
            "dorsal line, and a visible ember core glowing through a split in the forward plating. Class markers: "
            "hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest in the "
            "roster, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, pitted "
            "metal, hull grime, oil stains, scratches. Engines and glow: 2 recessed stern nozzles with burnt ember "
            "C8461B flares and small hot ember glow E8703A halos; the exposed ember core glows ember glow E8703A "
            "over a burnt ember C8461B heart, the largest single contained glow in the image, local to the core gap, "
            "never ambient scene glow. " + SHIP_NEG)),
    "ship_boss_spire": dict(
        family="ships", aspect="1:1", mode="single_trim", subject=(
            "Relay leviathan boss dreadnought, a single centred top-down orthographic render, bow pointing right, no "
            "tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the "
            "frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground "
            "shadow. Silhouette: a very long spine of stacked rectangular plate segments forming a tall central ridge, "
            "with two heavy flank outriggers projecting sideways, each carrying a weapon block, and thorned nodes "
            "along the ridge. Class markers: hostile hull with thorned protrusions and a visible ember core burning "
            "inside a stern cavity. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened "
            "craters, weld beads, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: "
            "2 engines at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the stern "
            "core glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow. "
            + SHIP_NEG)),
    # ---------------- faction liveries (i2i from the shipped masters) ----------------
    "livery_vanguard": dict(
        family="ships", aspect="1:1", mode="i2i_sheet", cuts=["ship_vanguard_mmo_front", "ship_vanguard_mmo_three_quarter", "ship_vanguard_mmo_side", "ship_vanguard_mmo_back"],
        ref=PROJECT / "assets/ships/20260917-183041/vanguard-cutter-player-ship-rotation-she-1-alpha.png",
        subject=("Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical "
                 "proportions, identical framing, identical camera, identical lighting and identical engine glow; "
                 "re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy "
                 "horizontal riveted plate rows stacked across the hull with chevron weld seams running along the "
                 "flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust "
                 "over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing "
                 "engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on "
                 "a fully transparent background with empty transparent margins, and keep the same reading order: "
                 "front, three-quarter, side, back. "
                 + SHIP_NEG)),
    "livery_fighter": dict(
        family="ships", aspect="1:1", mode="i2i_sheet", cuts=["ship_fighter_mmo_front", "ship_fighter_mmo_three_quarter", "ship_fighter_mmo_side", "ship_fighter_mmo_back"],
        ref=PROJECT / "assets/ships/20260917-183314/fighter-enemy-hull-rotation-sheet-four-1-alpha.png",
        subject=("Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, "
                 "identical framing, identical camera, identical lighting and identical engine glow; re-render only "
                 "the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate "
                 "bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the "
                 "company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no "
                 "rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B "
                 "engine flares exactly as in the reference, keep the four cells on a fully transparent background "
                 "with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. "
                 + SHIP_NEG)),
    "livery_corvette": dict(
        family="ships", aspect="1:1", mode="i2i_sheet", cuts=["ship_corvette_mmo_front", "ship_corvette_mmo_three_quarter", "ship_corvette_mmo_side", "ship_corvette_mmo_back"],
        ref=PROJECT / "assets/ships/20260917-183440/corvette-enemy-hull-rotation-sheet-four-1-alpha.png",
        subject=("Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, "
                 "identical framing, identical camera, identical lighting and identical engine glow; re-render only "
                 "the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with "
                 "weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. "
                 "Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and "
                 "oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block "
                 "exactly as in the reference, keep the four cells on a fully transparent background with empty "
                 "transparent margins, and keep the same reading order: front, three-quarter, side, back. "
                 + SHIP_NEG)),
    # ---------------- icon panels (flat vector, pure white, per ICONS_SPEC) ----------------
    "panel_equipment": dict(
        family="icons", aspect="1:1", mode="panel_white", cuts=[
            "icon_equip_generator", "icon_equip_shield_gen", "icon_equip_engine",
            "icon_equip_extra", "icon_equip_module", "icon_equip_drone",
            "icon_equip_pet", "icon_ammo_laser", "icon_ammo_rocket"],
        downscale=[16, 48],
        subject=ICON_PANEL_FRAME.format(grid="3x3", subjects=(
            "1 generator core, a rectangular housing with three vertical coil slats and a base mount; "
            "2 shield generator, a circular emitter ring on a square base plate with two anchor lugs; "
            "3 drive nozzle, a truncated cone with an inner combustion ring and two flanking stabiliser fins; "
            "4 utility pod, a boxy module with a side latch bracket and a top connector stub; "
            "5 upgrade module, stacked dual-slab boards with three edge connector teeth on one side; "
            "6 combat drone, a small arrowhead body with two side thruster nubs and no cockpit; "
            "7 pet unit, a rounded shell body with one forward sensor notch and three underside clamps; "
            "8 laser ammo cell, a vertical cylinder with a banded waist and a squared charge terminal on top; "
            "9 rocket magazine, a rectangular rack holding two upright ordnance rounds"))),
    "panel_map_markers": dict(
        family="icons", aspect="1:1", mode="panel_white", grid=(3, 3), cuts=[
            "icon_map_node_home", "icon_map_node_neutral", "icon_map_node_pvp",
            "icon_map_node_danger", "icon_map_node_asteroid", "icon_map_node_station",
            "icon_map_node_gate", "icon_map_bookmark", "icon_map_route"],
        downscale=[16, 48],
        subject=ICON_PANEL_FRAME.format(grid="3x3", subjects=(
            "1 hex node with a solid inner dot (home sector); "
            "2 plain hex node with an empty centre (neutral sector); "
            "3 hex node crossed by a single diagonal bar (pvp sector); "
            "4 hex node with one downward barb under it (danger sector); "
            "5 irregular angular rock cluster node (asteroid field); "
            "6 hexagonal ring node (station); "
            "7 twin-arc gate node with a gap in the middle (jump gate); "
            "8 pennant flag with a notched tail (bookmark); "
            "9 broken path line with three waypoint ticks (plotted route)"))),
    # ---------------- painted prop panels ----------------
    "panel_pickups": dict(
        family="env", aspect="1:1", mode="panel_white", cuts=[
            "env_pickup_bonus_box", "env_pickup_repair_pod", "env_pickup_shield_pod",
            "env_pickup_speed_pod", "env_pickup_ammo_pod", "env_pickup_ore_pod"],
        subject=(
            "game pickup props sheet, six separate small cargo and supply objects in an evenly spaced 2x3 grid "
            "(two columns, three rows) with generous gaps, left to right then top to bottom, each object isolated on a "
            "plain solid pure white background with empty white margins between objects so they can be cut apart, no "
            "grid lines, no labels, no text, no shadows on the background. Every object is a top-down orthographic "
            "painted render, one step darker than ships, weathered gunmetal and rusted steel, scratches, hull grime, "
            "oil stains, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh "
            "directional key light from the upper left, subtle film grain. Subjects in reading order: 1 sealed "
            "ordnance crate with banded reinforcement and one small burnt ember #C8461B lamp; 2 maintenance pod with "
            "an external tool rack and one burnt ember #C8461B lamp; 3 emitter pod with a steel highlight #565C63 "
            "aperture ring and no ember; 4 slim boost pod with two rear vent slots and one burnt ember #C8461B lamp; "
            "5 drum-shaped ammunition canister with a lift lug and no glow; 6 ore container with rusted ochre #6E5B4A "
            "and dry rust #8A6A50 ore veins visible at the seam. " + ENV_NEG)),
    "panel_insignia": dict(
        family="ui", aspect="1:1", mode="panel_white", cuts=[
            "ui_insignia_mmo", "ui_insignia_mic", "ui_insignia_ven", "ui_insignia_neutral"],
        subject=(
            "company emblem sheet, four separate painted emblems in an evenly spaced 2x2 grid with generous gaps, "
            "left to right then top to bottom, each emblem isolated on a plain solid pure white background with empty "
            "white margins between emblems so they can be cut apart, no grid lines, no labels, no letterforms, no "
            "text, no watermark, no shadows on the background. Every emblem is a flat frontal painted plaque, not "
            "perspective, built from a bevelled hexagonal plate of panel steel #2A2E35 over iron black #232629 with "
            "raised bone text #C9CDD2 emblem geometry, a thin cold steel highlight #565C63 catch along the top-left "
            "edges and an iron black drop shadow toward the lower right, subtle film grain. Subjects in reading "
            "order: 1 crossed mining picks over a hex plate (Mars Mining Operations); 2 three stacked ingot bars over "
            "a hex plate (Miner's Incorporated); 3 radiating sun spokes over a hex plate (Venus Resources); "
            "4 plain hex plate with a single vertical centre seam and no emblem geometry (neutral). The only ember in "
            "the sheet is one small burnt ember #C8461B notch on the first emblem. " + ENV_NEG)),
    # ---------------- environment ----------------
    "env_planet_moon": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Airless dead moon, one single centred top-down orthographic render of a spherical rock body, the disc "
            "occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully "
            "transparent background, no background colour, no backdrop, no ground shadow, no stars behind it. "
            "Surface: cracked grey rock faces in gunmetal dark #2B2F35 and gunmetal mid #3A3F46, one value step darker "
            "than ships, heavy cratering with iron black #232629 core shadows, rusted ochre #6E5B4A and dry rust "
            "#8A6A50 mineral seams running through the cracks, pitted metal speckle catching the cold steel highlight "
            "#565C63 rim along the shadow-side limb, harsh directional key light from the upper left, subtle film "
            "grain. No atmosphere, no clouds, no haze, no terminator glow, no emissive light anywhere, no rings. "
            + ENV_NEG)),
    "env_jump_gate": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Jump gate structure, one single centred top-down orthographic render, the structure occupying about 60 "
            "percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no "
            "background colour, no backdrop, no ground shadow. Structure: two heavy anchor pylons joined by a "
            "segmented open ring, welded station platework with visible panel seams and rivet lines in gunmetal mid "
            "#3A3F46 and gunmetal dark #2B2F35, heavy hull grime films, rust streaks bleeding from the seams, pitted "
            "metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh "
            "directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B "
            "warning lamps only, a handful of lamp points along the hull, no ember glow halo, no energy field, no "
            "glowing aperture, no interior glow, no beam. " + ENV_NEG)),
    "env_debris_field": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, "
            "panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and "
            "clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully "
            "transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is "
            "dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, "
            "scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, "
            "hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on "
            "the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never "
            "touch or overlap. No emissive, no glow, no fire, no smoke. " + ENV_NEG)),
    "env_nebula_veil": dict(
        family="env", aspect="1:1", mode="single_full", subject=(
            "Deep space haze texture, a single square full-frame painterly wash, seamless and tileable in both X and "
            "Y with no visible seam and no hard feature touching the frame border. Content is only soft drifting "
            "washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue "
            "grey only, extremely low contrast, uniform and featureless, mild cloud-like mottling and thin dust "
            "veils, subtle film grain over the whole frame. This is a background layer, not a scene: absolutely no "
            "stars, no starfield, no ships, no wrecks, no debris, no stations, no asteroids, no planets, no focal "
            "point, no silhouettes, no hard shapes, no ember or orange anywhere, no glow, no bright nebula, no "
            "saturated colour. " + ENV_NEG)),
    # ---------------- FX (void black, additive, no alpha keying) ----------------
    "fx_jump_portal": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "Single space jump portal effect, one isolated object centred in the frame, flat void black #0A0E14 "
            "background that is NOT white. A wide ember jump aperture: a large horizontal elliptical ring of burnt "
            "ember #C8461B with a thin ember glow #E8703A rim along its inner edge, painterly heat striations running "
            "around the ring, the aperture interior completely empty void black with no energy fill, no beam and no "
            "field, the ring thin and contained, hottest and brightest only along the inner rim, slight painterly "
            "wobble allowed, harsh directional key light from the upper left leaving the outer metal edge dark, subtle "
            "film grain, no ship parts, no silhoette, no panel, no frame. " + FX_NEG)),
    "fx_missile_trail": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "4-frame horizontal sprite sheet of a rocket exhaust trail, four separate effects in a single row with "
            "generous gaps, left to right: frame 1 a short hot burnt ember #C8461B head streak with an ember glow "
            "#E8703A core; frame 2 the streak extended with a widening smoke plume in grimy umber #4A423B and iron "
            "black #232629 beginning behind it; frame 3 a long dissipating smoke plume with ember only at the head; "
            "frame 4 a thin nearly empty residual trail of dark smoke. Each frame isolated on a flat void black "
            "#0A0E14 background that is NOT white, no grid lines, no labels, effects only, no missile, no rocket body, "
            "no ship parts, subtle film grain. " + FX_NEG)),
    "fx_shield_break": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "4-frame horizontal sprite sheet of a shield break effect, four separate effects in a single row with "
            "generous gaps, left to right: frame 1 a cold pale steel highlight #565C63 impact point with short "
            "radiating shatter arcs; frame 2 the arcs spreading outward as thin fractured plate flakes of the same "
            "steel highlight; frame 3 the fragments separating and thinning with a faint inner haze; frame 4 a thin "
            "nearly empty remnant ring. The entire sheet uses steel highlight #565C63 only with iron black #232629 "
            "shadows, absolutely no orange, no ember, no burnt ember, no ember glow, no blue, no glow colour of any "
            "kind, each frame isolated on a flat void black #0A0E14 background that is NOT white, effects only, no "
            "ship parts, no shield panel, no UI, no grid lines, subtle film grain. "
            + FX_NEG + " no orange glow, no ember, no warm colour.")),
    # =============== WAVE 2 ===============
    "ship_bomber": dict(
        family="ships", aspect="1:1", mode="ship_sheet",
        cuts=["ship_bomber_front", "ship_bomber_three_quarter", "ship_bomber_side", "ship_bomber_back"],
        subject=ship_sheet(
            "Bomber enemy hull rotation sheet, a hostile ordnance ship. Silhouette: fat deep-bodied fuselage, clearly "
            "the deepest hull of the roster, with a wide underslung ordnance bay recessed into the belly and two short "
            "stub wings projecting just far enough to catch the rim light, twin recessed nozzles at the tail. Class "
            "markers: the underslung bay and the stub wings; no spine ridges, no thorned protrusions. Weathering "
            "density: heavy, scorch marks radiating from the bay mouth, oil stains, battle damage, hull grime, pitted "
            "metal. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, "
            "small and hot, no other glow.")),
    "ship_mine_layer": dict(
        family="ships", aspect="1:1", mode="ship_sheet",
        cuts=["ship_mine_layer_front", "ship_mine_layer_three_quarter", "ship_mine_layer_side", "ship_mine_layer_back"],
        subject=ship_sheet(
            "Mine layer enemy hull rotation sheet, a hostile support ship. Silhouette: slim central hull with a blunt "
            "squared bow, a single low dorsal rail and a wide flat stern rack holding six empty mine cradles along its "
            "trailing edge, each cradle a clear open notch. Class markers: the stern mine rack is the whole read; no "
            "wings, no thorned protrusions. Weathering density: heavy, rust streaks, battle damage, hull grime, oil "
            "stains, pitted metal. Engines and glow: 2 engines inside the stern block, burnt ember C8461B flares with "
            "small hot ember glow E8703A halos, small and hot, no other glow.")),
    "ship_turret_platform": dict(
        family="ships", aspect="1:1", mode="single_trim", out="ship_turret_platform", subject=(
            "Hostile turret platform, one single centred top-down orthographic render, the emplacement occupying about "
            "60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no "
            "background colour, no backdrop, no ground shadow. Silhouette: a radially symmetric hexagonal armoured "
            "emplacement with no bow and no stern, one long barrel on a central pivot ring projecting to the right, "
            "three armoured stabiliser legs spaced evenly around the base, and a low sensor drum at the hub centre. "
            "Class markers: radial symmetry, no hull axis. Weathering density: heavy, pitted metal, scorch marks "
            "around the barrel base, rust streaks, hull grime, battle damage. Emissive: small hot burnt ember C8461B "
            "warning lamps only on the hub ring, three lamp points, no ember glow halo, no muzzle glow. " + SHIP_NEG)),
    "ship_boss_leviathan": dict(
        family="ships", aspect="1:1", mode="single_trim", out="ship_boss_leviathan", subject=(
            "Leviathan boss dreadnought, one single centred top-down orthographic render, bow pointing right, no tilt "
            "and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame "
            "centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. "
            "Silhouette: a blunt hammerhead fore-section wider than the rest of the hull, joined to a long ribbed hull "
            "with visible exposed structural ribs along both flanks and thorned protrusions at the stern, with two "
            "exposed drive cores recessed into the flanks and a visible ember core burning in a forward cavity behind "
            "the hammerhead. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering "
            "density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads over repairs, "
            "rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engine blocks at the "
            "stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the two exposed drive cores "
            "glow ember glow E8703A over burnt ember C8461B hearts, contained and local, no other glow. " + SHIP_NEG)),
    "livery_freighter": dict(
        family="ships", aspect="1:1", mode="i2i_sheet",
        cuts=["ship_freighter_mmo_front", "ship_freighter_mmo_three_quarter",
               "ship_freighter_mmo_side", "ship_freighter_mmo_back"],
        ref=PROJECT / "assets/ships/20260917-183532/freighter-enemy-hull-rotation-sheet-fou-1-alpha.png",
        subject=("Same 2x2 rotation sheet of the same enemy freighter hull, identical silhouette, identical "
                 "proportions, identical framing, identical camera, identical lighting and identical engine glow; "
                 "re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy "
                 "horizontal riveted plate rows crossing the three hull blocks with chevron weld seams along the "
                 "flanks, industrial mining-company refit. Weathering: extra hull grime film and industrial dust over "
                 "the standard scratches, rust streaks and oil stains, no new battle damage. Keep the bow, cargo and "
                 "engine blocks, the external container racks and the burnt ember C8461B engine flares exactly as in "
                 "the reference, keep the four cells on a fully transparent background with empty transparent margins, "
                 "and keep the same reading order: front, three-quarter, side, back. " + SHIP_NEG)),
    "livery_maw": dict(
        family="ships", aspect="1:1", mode="i2i_single", out="ship_boss_maw_mmo",
        ref=PROJECT / "assets/ships/20260917-183626/maw-dreadnought-boss-ship-single-centre-1-alpha.png",
        subject=("Same maw dreadnought boss, identical silhouette, identical proportions, identical framing, "
                 "identical camera and identical lighting; re-render only the hull plate pattern and the weathering "
                 "distribution. New plate pattern: heavy horizontal riveted plate rows laid over the carapace with "
                 "chevron weld seams between the thorn roots, industrial mining-company refit. Weathering: extra hull "
                 "grime film and industrial dust over the existing battle damage and scorch marks. Keep every thorn, "
                 "the spore vents, the exposed ember core through the split plate and the stern nozzles exactly as in "
                 "the reference, keep the render isolated on a fully transparent background with no backdrop and no "
                 "ground shadow. " + SHIP_NEG)),
    "panel_props": dict(
        family="env", aspect="1:1", mode="panel_white", grid=(3, 2), cuts=[
            "env_prop_hull_nose", "env_prop_hull_mid", "env_prop_hull_stern",
            "env_prop_plate_section", "env_prop_drive_core", "env_prop_rib_cluster"],
        subject=(
            "Dead hull debris props sheet, six separate wreck fragments in an evenly spaced 2x3 grid (three columns, "
            "two rows) with generous gaps, left to right then top to bottom, each fragment isolated on a plain solid "
            "pure white background with empty white margins between fragments so they can be cut apart, no grid lines, "
            "no labels, no text, no shadows on the background, fragments never touching or overlapping. Every fragment "
            "is a top-down orthographic painted render one value step darker than ships: ripped-open plating with bent "
            "torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks "
            "bleeding from seams, hull grime toward trailing edges, oil stains, pitted metal, cold steel highlight "
            "#565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. "
            "Subjects in reading order: 1 a torn bow section with a crushed prow; 2 a mid-hull cargo block with a "
            "ripped container rack; 3 a stern section with two cold dead nozzles; 4 a detached hull plate section with "
            "rivet rows; 5 a torn drive core housing with exposed rings; 6 a cluster of bent structural ribs. "
            "No emissive, no glow, no fire, no smoke. " + ENV_NEG)),
    "env_station_mmo": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Faction mining station exterior, one single centred top-down orthographic render, the station occupying "
            "about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent "
            "background, no background colour, no backdrop, no ground shadow. Subject: a heavy industrial station of "
            "welded platework with heavy horizontal riveted plate rows and chevron weld seams, a central hexagonal "
            "hub, two docking arms ending in open clamp frames, ore silo drums along one flank and a squared cargo "
            "wing, all in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, one value step darker than ships, with "
            "heavy hull grime films, rust streaks from the seams, pitted metal on the older plates, cold steel "
            "highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper "
            "left, subtle film grain. Emissive: small hot burnt ember C8461B warning lamps only, a handful of lamp "
            "points along the hull, no ember glow halo, no window glow, no interior light. " + ENV_NEG)),
    "env_station_ruined": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Gutted hostile station wreck, one single centred top-down orthographic render, the structure occupying "
            "about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent "
            "background, no background colour, no backdrop, no ground shadow. Subject: a torn-open station ring, the "
            "outer ring snapped and bent, plating ripped away to expose dark ribs and decks, scorch-blackened craters, "
            "weld beads over old repairs, one docking arm sheared off and drifting clear of the hull in the same "
            "frame, heavy rust streaks and hull grime, pitted metal, everything one value step darker than ships, "
            "cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, "
            "subtle film grain. Emissive: two small hot burnt ember C8461B warning lamps only, dying, no ember glow "
            "halo, no fire, no smoke. " + ENV_NEG)),
    "env_ice_field": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Frozen fragment field, one single top-down orthographic render of a cluster of ice-crusted rock shards, "
            "the cluster occupying about 70 percent of the frame width with clear empty gaps between the shards, no "
            "tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, "
            "no ground shadow. Every shard is desaturated death-cold rock in gunmetal dark #2B2F35 and iron black "
            "#232629 one value step darker than ships, encrusted with a pale crust that catches the cold steel "
            "highlight #565C63 rim as frost speckle, cracked faces, battle-damage dents, pitted metal, no colour "
            "beyond the fixed palette, no blue tint, no transparency, no glow. Shards never touch. " + ENV_NEG)),
    "env_ore_cluster": dict(
        family="env", aspect="1:1", mode="single_trim", subject=(
            "Dense mineable asteroid cluster, one single top-down orthographic render of three large rock bodies "
            "joined into a single mass, the cluster occupying about 70 percent of the frame width, no tilt and no "
            "perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground "
            "shadow. Rock body is desaturated gunmetal-grey stone in the #2B2F35 to #3A3F46 range, one value step "
            "darker than ships, with cracked rock faces, iron black #232629 core shadows, rich ore veins in rusted "
            "ochre #6E5B4A and dry rust #8A6A50 running through the cracks and glowing nowhere, dense pitted metal "
            "speckle catching the cold steel highlight #565C63 rim, harsh directional key light from the upper left, "
            "subtle film grain, no emissive, no glow of any kind. " + ENV_NEG)),
    "ui_backdrop_hangar": dict(
        family="ui", aspect="16:9", mode="single_full", subject=(
            "Docking bay interior backdrop, a wide 16:9 cinematic top-down painted plate for a menu screen, no "
            "interface elements baked in, no text, no logos. Subject: a dark industrial hangar deck seen from above, "
            "heavy structural girders and gantry rails crossing the frame, service cranes, fuel lines and mooring "
            "clamps along the walls, painted gunmetal and rusted steel in the fixed palette, heavy hull grime, oil "
            "stains, rust streaks, pitted metal, subtle film grain. Composition: the centre of the frame stays dark, "
            "empty and low detail so foreground interface elements read on top of it, with all structural detail and "
            "the only lighting interest pushed to the left, right and bottom edges. Emissive: a few small hot burnt "
            "ember C8461B service lamps along the girders, contained, never a glow bloom. No ships, no vehicles, no "
            "figures, no icons. " + ENV_NEG)),
    "ui_backdrop_starmap": dict(
        family="ui", aspect="16:9", mode="single_full", subject=(
            "Starmap backdrop, a wide 16:9 cinematic painted plate for a navigation screen, no interface elements "
            "baked in, no markers, no nodes, no lines, no text, no logos. Subject: a very dark desaturated starfield "
            "haze with faint drifting dust veils in deep void blue #111823 and void haze #1A2230 over void black "
            "#0A0E14, sparse faint stars, a whisper of dust structure and one very faint grey nebula wash, subtle film "
            "grain. Composition: extremely low contrast overall, the centre of the frame the quietest and darkest "
            "region so navigation markers and panels read on top of it, with slightly more dust density toward the "
            "frame corners. No planets, no ships, no ember, no orange, no glow, no bright nebula, no saturated "
            "colour. " + ENV_NEG)),
    "ui_backdrop_login": dict(
        family="ui", aspect="16:9", mode="single_full", subject=(
            "Station interior wall backdrop, a wide 16:9 cinematic painted plate for a login and account screen, no "
            "interface elements baked in, no text, no logos, no figures. Subject: a dark armoured corridor wall seen "
            "flat from above, large welded plate panels with rivet lines and panel seams in gunmetal dark #2B2F35 and "
            "iron black #232629, one heavy blast door frame with a riveted border, cable conduits and a grated vent "
            "run, heavy hull grime and oil stains along the seams, rust streaks, pitted metal, subtle film grain, "
            "desaturated and dark overall. Composition: the centre of the frame stays plain, dark and empty for the "
            "form panel, all detail pushed to the edges. Emissive: exactly one small hot burnt ember C8461B wall lamp "
            "in the upper right, contained, no glow bloom. " + ENV_NEG)),
    "fx_tractor_beam": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "Single tractor beam effect, one isolated object centred in the frame, flat void black #0A0E14 background "
            "that is NOT white. A wide tapered beam of burnt ember #C8461B with a thin ember glow #E8703A core running "
            "along its centre, drawn horizontally and narrowing toward the right, faint concentric containment bands "
            "along the length, a small emitter flare cone where it originates on the left, the beam thin and contained "
            "with no fill glow around it, painterly heat striations, slight wobble allowed, subtle film grain, effects "
            "only, no ship parts, no tractor target, no panel, no frame. " + FX_NEG)),
    "fx_emp_arc": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "Single electromagnetic disruption arc effect, one isolated object centred in the frame, flat void black "
            "#0A0E14 background that is NOT white. A branching electrical arc in burnt ember #C8461B with ember glow "
            "#E8703A only at the hottest junctions, jagged branching bolts radiating outward from a small dense core, "
            "thin filaments, no blue, no cyan, no white core, contained and small, painterly heat bleed along the "
            "branches, subtle film grain, effects only, no ship parts, no panel, no frame. " + FX_NEG)),
    "fx_secondary_explosion": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "4-frame horizontal sprite sheet of a small secondary detonation, four separate effects in a single row "
            "with generous gaps, left to right: frame 1 a compact brightened desaturated ember hot flash; frame 2 a "
            "small burnt ember #C8461B bloom with an ember glow #E8703A rim; frame 3 the bloom collapsing into iron "
            "black #232629 smoke with a few gunmetal #2B2F35 fragments thrown clear; frame 4 a thin dark smoke "
            "residual. Clearly smaller and tighter than a capital-ship explosion, each frame isolated on a flat void "
            "black #0A0E14 background that is NOT white, effects only, no ship parts, no panel, no grid lines, subtle "
            "film grain. " + FX_NEG)),
    "fx_repair_pulse": dict(
        family="fx", aspect="1:1", mode="fx_void", subject=(
            "Single field repair pulse effect, one isolated object centred in the frame, flat void black #0A0E14 "
            "background that is NOT white. An expanding maintenance ring drawn in cold pale steel highlight #565C63 "
            "only, a thin crisp ring with a faint inner haze and a handful of tiny angular engineering sparks riding "
            "the ring edge, cold and clinical, absolutely no orange, no ember, no burnt ember, no ember glow, no warm "
            "colour anywhere, the ring thin and contained with a completely empty centre, subtle film grain, effects "
            "only, no ship parts, no panel, no frame. " + FX_NEG + " no orange glow, no ember, no warm colour.")),
}

# split-component reading order is row-banded, left to right, so cuts follow the
# same order the prompt describes the cells in.
CUT_PAD = 10


def log_run(entry):
    log_path = STAGE / entry["family"] / "generation_log.md"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if not log_path.exists():
        log_path.write_text(
            "# Phase D wave 1 - generation log\n\n"
            "Model: `gpt-image-2-5-flare-text-to-image` (`flare`, `flare-i2i` for edits), 2K. "
            "Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file`.\n"
            "Spec: `docs/design/ASSET_EXPANSION_SPEC.md`. Price basis $0.05 per 2K run (user-verified); "
            "the script's printed 30-credit estimate is the stale hint.\n"
            "Alpha: `--transparent` native first, `--strip-bg local` fallback; splitting via the alpha "
            "channel (`--split-only`). AI-generated art is not CC0 (AGENTS.md).\n\n---\n\n",
            encoding="utf-8")
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(entry["markdown"])
        fh.write("\n---\n\n")


def ensure_alpha(path, explicit_bg=None):
    """Return a path whose image has a usable alpha channel."""
    img = Image.open(path)
    if img.mode in ("RGBA", "LA"):
        alpha = img.convert("RGBA").getchannel("A")
        hist = alpha.histogram()
        total = img.size[0] * img.size[1]
        if hist[0] / total > 0.10:
            return path, "native-alpha"
    # opaque result: key the background out locally (free, no API call)
    img = img.convert("RGB")
    if explicit_bg:
        hex_digits = explicit_bg.lstrip("#")
        bg = tuple(int(hex_digits[i:i + 2], 16) for i in (0, 2, 4))
    else:
        px = img.load()
        w, h = img.size
        corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
        bg = max(set(corners), key=corners.count)
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.size[1]):
        for x in range(rgba.size[0]):
            r, g, b, _ = px[x, y]
            distance = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
            if distance <= 12:
                px[x, y] = (r, g, b, 0)
            elif distance <= 40:
                px[x, y] = (r, g, b, int(255 * (distance - 12) / 28))
    out = Path(path).with_name(Path(path).stem + "-keyed.png")
    rgba.save(out)
    return out, "local-keyed"


def trim(path, pad=CUT_PAD, out_name=None):
    img = Image.open(path).convert("RGBA")
    bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if not bbox:
        return path
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(img.size[0], bbox[2] + pad)
    bottom = min(img.size[1], bbox[3] + pad)
    dest = Path(path).parent / (out_name or (Path(path).stem + "-trim.png"))
    img.crop((left, top, right, bottom)).save(dest)
    return dest


def downscale(src, sizes, base_name, family_dir):
    img = Image.open(src).convert("RGBA")
    out = []
    for size in sizes:
        dest = family_dir / f"{base_name}_{size}.png"
        img.resize((size, size), Image.LANCZOS).save(dest)
        out.append(dest)
    return out


def run_one(run_id):
    spec = RUNS[run_id]
    family_dir = STAGE / spec["family"]
    family_dir.mkdir(parents=True, exist_ok=True)

    cmd = [PY, str(SKILL), "--model", "flare", "--prompt", spec["subject"],
           "--aspect", spec["aspect"], "--resolution", "2K",
           "--style-file", str(STYLE_FILE), "--out", str(family_dir), "--yes"]
    if spec.get("mode") in ("ship_sheet", "single_trim", "i2i_sheet", "i2i_single"):
        cmd.append("--transparent")
    if spec.get("mode") == "panel_white":
        cmd += ["--strip-bg", "local", "--bg-color", "FFFFFF"]
    refs = spec.get("ref")
    if refs:
        if isinstance(refs, (str, Path)):
            refs = [refs]
        cmd += ["--ref"] + [str(r) for r in refs]

    print(f"[{run_id}] submitting", flush=True)
    env = dict(os.environ)
    if Path(CA_BUNDLE).is_file():
        env["SSL_CERT_FILE"] = CA_BUNDLE
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                          errors="replace", env=env)
    if proc.returncode != 0:
        print(f"[{run_id}] FAILED rc={proc.returncode}\n{proc.stdout}\n{proc.stderr}", flush=True)
        return False
    payload = json.loads(proc.stdout)
    master = payload["local_paths"][0]
    if payload.get("alpha_paths"):
        master = payload["alpha_paths"][0]
    task_id = payload.get("task_id", "?")
    elapsed = payload.get("elapsed_s", "?")
    print(f"[{run_id}] ok task={task_id} {elapsed}s master={master}", flush=True)

    notes = []
    source, how = (master, "provided-alpha") if spec["mode"] == "panel_white" else ensure_alpha(master)
    notes.append(how)

    finals = []
    mode = spec["mode"]
    if mode in ("ship_sheet", "i2i_sheet", "panel_white"):
        import importlib.util
        spec_mod = importlib.util.spec_from_file_location("kg", SKILL)
        kg = importlib.util.module_from_spec(spec_mod)
        spec_mod.loader.exec_module(kg)
        cuts = kg.split_components(Path(source), Path(source).parent, Path(source).stem + "-cut")
        if len(cuts) != len(spec["cuts"]):
            print(f"[{run_id}] WARNING expected {len(spec['cuts'])} cuts, got {len(cuts)}: {cuts}", flush=True)
        for cut_path, name in zip(cuts, spec["cuts"]):
            dest = family_dir / f"{name}.png"
            img = Image.open(cut_path).convert("RGBA")
            img.save(dest)
            finals.append(dest)
            job_src = Path(master).parent / "job.json"
            if job_src.exists():
                (family_dir / f"{name}.job.json").write_text(job_src.read_text(encoding="utf-8"), encoding="utf-8")
            if spec.get("downscale"):
                downscale(dest, spec["downscale"], name, family_dir)
    elif mode in ("single_trim", "i2i_single"):
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        trim(source, out_name=dest.name).replace(dest)
        finals.append(dest)
        job_src = Path(master).parent / "job.json"
        if job_src.exists():
            (family_dir / f"{run_id}.job.json").write_text(job_src.read_text(encoding="utf-8"), encoding="utf-8")
    else:  # fx_void / single_full: keep the full 2K canvas, RGB only for FX
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        img = Image.open(source)
        img.convert("RGB").save(dest) if spec["family"] == "fx" else img.save(dest)
        finals.append(dest)
        job_src = Path(master).parent / "job.json"
        if job_src.exists():
            (family_dir / f"{run_id}.job.json").write_text(job_src.read_text(encoding="utf-8"), encoding="utf-8")

    for path in finals:
        img = Image.open(path)
        alpha = img.convert("RGBA").getchannel("A").histogram() if img.mode == "RGBA" else None
        total = img.size[0] * img.size[1]
        cover = f" alpha0={100 * alpha[0] / total:.0f}%" if alpha else " opaque"
        print(f"[{run_id}] final {path.name} {img.size} {img.mode}{cover}", flush=True)

    log_run(dict(family=spec["family"], markdown=(
        f"## {run_id}\n\n"
        f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
        f"- Model: `{'gpt-image-2-5-flare-image-to-image' if spec.get('ref') else 'gpt-image-2-5-flare-text-to-image'}` "
        f"(`{'flare-i2i' if spec.get('ref') else 'flare'}`), 2K, {spec['aspect']}\n"
        f"- Job id: `{task_id}` (elapsed {elapsed}s)\n"
        f"- Reference: {spec['ref'] if spec.get('ref') else 'none (text-to-image)'}\n"
        f"- Alpha: {', '.join(notes)}; run folder `{Path(master).parent.name}` keeps `job.json`\n"
        f"- Final files: {', '.join(p.name for p in finals)}\n"
        f"- Status: success\n\n"
        f"Full SUBJECT text:\n\n> {spec['subject']}\n")))
    return True


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or args[0] == "--list":
        for key in RUNS:
            print(key)
        sys.exit(0)
    ok = all(run_one(run_id) for run_id in args)
    sys.exit(0 if ok else 1)
