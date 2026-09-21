"""Phase F driver - RPG/economy art deliverables.

Work order: docs/gameplay/16_art_design_brief.md
Style law:  docs/design/STYLE_BIBLE.md, ICONS_SPEC.md (section 1 and the
            2026-09-18 amendment section 8), SHIPS_SPEC.md (section 1 framing
            constant, sections 3.7-3.9), ASSET_EXPANSION_SPEC.md (generation
            rules), UI_CHROME_ASSETS_SPEC.md, FX_SPEC.md (section 0.1).

Usage:
    py -3.14 staging/phase_f/wave_f.py --list
    py -3.14 staging/phase_f/wave_f.py --dry-run p0_minerals_ore      # free price check
    py -3.14 staging/phase_f/wave_f.py p0_minerals_ore p0_slots ...   # one paid call each

One paid skill call per run, then free local alpha/matte/split/trim/downscale work.
Every run passes vajb-orbit/assets/style-block.txt verbatim via --style-file.
"""
import importlib.util
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
PROJECT = WORKSPACE / "vajb-orbit"
STAGE = WORKSPACE / "staging" / "phase_f"
ASSETS = PROJECT / "assets"
PHASE_D = WORKSPACE / "staging" / "phase_d"
STYLE_FILE = ASSETS / "style-block.txt"
SKILL = Path(r"C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py")
PY = sys.executable
# Run under the python.org build (`py -3.14`); the PATH `python` is Inkscape's
# bundled 3.12 and has no CA roots, which breaks TLS for the generator.
CA_BUNDLE = r"C:/Users/Kamil/AppData/Local/Python/pythoncore-3.14-64/Lib/site-packages/certifi/cacert.pem"

sys.path.insert(0, str(PHASE_D))
from reprocess import matte, grid_split  # noqa: E402

# ---------------------------------------------------------------- style law

SHIP_NEG = ("no chrome, no neon, no saturated colours, no second accent, no perspective, "
            "no tilt, no text, no watermark, no grid lines, no labels.")
ICON_NEG = ("no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, "
            "no shadows, no text, no watermark, no grid lines, no labels, no multicolour, "
            "no rounded corners, no rounded stroke ends, no tapering strokes.")

# ICONS_SPEC section 5 states the flat framing sentence; the style block this project
# passes verbatim on every run ends with painted-metal, void-background and glow wording,
# which the model lets win by default (it governs the render style). This override block
# is added on the subject side of every flat icon run to make the section 5 sentence win.
# It is required: the first P0 pass rendered painted 3D objects on void black with ember
# glow, which breaks the brief's flat-silhouette rule and ICONS_SPEC section 1.
ICON_OVERRIDE = (
    "STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic "
    "instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a "
    "photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in "
    "iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil "
    "sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no "
    "reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D "
    "depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no "
    "ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white "
    "#FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed "
    "only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, "
    "corner radius zero, no rounded corners, no rounded stroke ends, no tapering.")

# F.2 (C2b). ICON_OVERRIDE's closing sentence pins interior detail to section 1's 1.5
# px-equivalent stroke and is read last, so a subject-side "draw thicker" sentence loses
# (measured: the F.1 glyph run landed 1.67 px-equivalent and read grey at 16 px). This tail
# is appended AFTER ICON_OVERRIDE so the heavy weight is the final instruction on the sheet.
HEAVY_STROKE_TAIL = (
    " FINAL STROKE OVERRIDE - for this sheet only, ignore every 1.5 px-equivalent, thin, hairline or "
    "fine-line stroke instruction anywhere above, including the 1.5 px-equivalent sentence inside the "
    "flat-vector override block: on THIS sheet every stroke, outline and bar of every glyph is a HEAVY BOLD "
    "BAR at least 3 px wide at 16 px final size, about one fifth of the glyph's own width and roughly twice "
    "a normal outline pictogram, drawn like a heavy stencil or a bold road sign. The strokes are as thick as "
    "the white negative space they enclose, every weight is uniform along its length, corners are hard mitred, "
    "no taper and no rounded ends. This heavy weight is the point of the sheet: when it is reduced to 16 px "
    "every stroke must still cover whole pixels and read as solid iron black, never as a grey, broken or "
    "hairy line.")

ENV_NEG = ("no planets with atmospheres, no clouds, no bright nebula, no saturated colours, "
           "no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, "
           "no ships, no figures.")
FX_NEG = ("no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy "
          "highlights, no text, no watermark, no grid lines, no frames, no UI chrome, no ship parts.")

# SHIPS_SPEC section 1, verbatim - copied into every hull prompt.
FRAMING_CONSTANT = ("top-down orthographic, facing right, ship occupies about 60 percent of frame "
                    "width, centroid at frame centre, background flat void black 0A0E14, "
                    "transparent where a sprite is required.")

SHEET_GRID = ("four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, "
              "the four ships isolated on a fully transparent background with completely empty transparent "
              "margins separating the cells so they can be cut apart, no background colour, no backdrop, "
              "no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt "
              "and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, "
              "bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, "
              "bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, "
              "centroid at its cell centre. Identical proportions, identical palette and identical lighting in all "
              "four cells. ")

ICON_FRAME = ("flat vector icon sheet, {grid} grid (icons arranged left to right, top to bottom), generous even "
              "gaps between icons, plain solid pure white background, isolated objects, icons drawn as "
              "single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred "
              "corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the "
              "painted metal style. Subjects in reading order: {subjects}. " + ICON_OVERRIDE + " " + ICON_NEG)


def ship_sheet(subject):
    return subject + " " + SHEET_GRID + SHIP_NEG


VIEWS = ["front", "three_quarter", "side", "back"]
VIEW_SUFFIX = {"front": "front-bow-up", "three_quarter": "three-quarter",
               "side": "side-bow-right", "back": "back-bow-down"}


def sheet_cuts(stem):
    return [f"{stem}_{v}" for v in VIEWS]


# ---------------------------------------------------------------- P0 minerals

# 02 section 2 tier order - the reading order of both 5x4 panels.
MINERALS = [
    "iron", "copper", "chromium", "silicon", "aluminium",
    "titanium", "nickel", "cobalt", "tungsten", "silver",
    "gold", "platinum", "neodymium", "iridium", "osmium",
    "palladium", "cerulite", "emberite", "voidglass", "krilium",
]

ORE_SHAPES = {
    "iron": "a heavy blocky chunk with three flat fracture faces, squat and dense",
    "copper": "a chunky lump with a curled shard edge peeling off one side",
    "chromium": "a slim elongated shard with one sharp tapered tip",
    "silicon": "a flat wide wedge with one broad planar cleaved face and a knife edge",
    "aluminium": "a thin wide flake with a feathered folded rim",
    "titanium": "a stout nugget with five clean facets meeting at a single ridge",
    "nickel": "an oblong lump carrying one flat band across its face",
    "cobalt": "a small rounded lobe of mineral still locked in a square host-rock corner",
    "tungsten": "a dense cube-faced chunk with one corner sheared away square",
    "silver": "a pointed chunk sprouting three short needle crystals",
    "gold": "a lumpy nugget with one rounded drooping edge read as sagging metal",
    "platinum": "a layered flake-plate chunk with a stepped bright top face",
    "neodymium": "a blocky matrix chunk holding one dark angular inclusion block",
    "iridium": "a dense jagged shard barbed with short spikes on every side",
    "osmium": "a squat heavy chunk with a chipped flat rim",
    "palladium": "a slatted crystal chunk of three flat parallel blades",
    "cerulite": "a shard cluster split by one raised vein ridge running its length",
    "emberite": "a chunk cut through by a single deep internal fissure crack",
    "voidglass": "a smooth curved shell shard with one hooked lip, glassier and rounder than every other ore",
    "krilium": "an irregular asymmetric chunk with one long spike, visibly refusing the geometry of the others",
}

INGOT_SHAPES = {
    "iron": "a wide squat bar with one chiselled end",
    "copper": "a bar with a rounded end and one raised ridge line along the top",
    "chromium": "a slim long bar tapered at one end",
    "silicon": "a flat wide slab bar with a stepped top face",
    "aluminium": "a small neat bar with one folded corner tab",
    "titanium": "a stout bar struck twice with two parallel vertical marks",
    "nickel": "an oblong bar with one chamfered top corner",
    "cobalt": "a bar with a banded waist pinched at the middle",
    "tungsten": "a near-cubic heavy bar with one chiselled side notch",
    "silver": "a bar with a single fine hairline seam down the middle",
    "gold": "a bar carrying one lone centre punch mark",
    "platinum": "a bar with a stepped double top face",
    "neodymium": "a bar with a pair of crossed grooves cut across its top",
    "iridium": "a bar with one barbed end notch",
    "osmium": "a thick squat bar with a heavy chamfer on all four long edges",
    "palladium": "a bar with a lattice-pierced top face",
    "cerulite": "a bar with a single central ridge running its full length",
    "emberite": "a bar with a chiselled V groove notch cut into one end",
    "voidglass": "a bar with a concave scoop taken out of one end, glassier and rounder than the rest",
    "krilium": "a bar with a visibly warped irregular profile and one barb, refusing the geometry of the others",
}


def ore_subjects():
    return "; ".join(
        f"{i + 1} raw {name} ore, {ORE_SHAPES[name]}"
        for i, name in enumerate(MINERALS))


def ingot_subjects():
    return "; ".join(
        f"{i + 1} refined {name} ingot, a single stamped metal bar with a flat top face, {INGOT_SHAPES[name]}"
        for i, name in enumerate(MINERALS))


# ---------------------------------------------------------------- P0 modules

MODULE_GLYPHS = {
    # 09 section 3.1 weapons that do NOT already have a glyph (section 2 of ICONS_SPEC)
    "icon_module_w_railgun": "railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile",
    "icon_module_w_mining": "mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile",
    # 09 section 3.2 shields
    "icon_module_s_light": "light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs",
    "icon_module_s_heavy": "heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs",
    "icon_module_s_ion": "ion shield generator, an arc emitter half-ring carrying three short inner coil bars",
    # 09 section 3.3 armour
    "icon_module_h_plate_light": "light armour plate, one flat rectangular plate seen square on with two large square notches cut out of its top and bottom edges and one wide diagonal slot cut right through the plate, so the shape reads as a plate and never as a filled square",
    "icon_module_h_plate_heavy": "heavy armour plate, two stacked flat plates with a wide open gap cut between the two layers and three bold round rivet holes cut right through the upper plate",
    "icon_module_h_composite": "composite armour plate, one flat plate cut through by a bold diagonal lattice of wide crossing bars, leaving large open square holes between them",
    # 09 section 3.8 power
    "icon_module_p_std": "standard reactor core, a rectangular housing with three wide vertical slots cut right through its face and a stepped base mount plate",
    "icon_module_p_mk2": "upgraded reactor core, a rectangular housing with five wide vertical slots cut right through its face, a bold open cap block on top and a stepped base mount plate",
    "icon_module_p_core": "high-output power core, a hexagonal housing around one large open square core opening with four bold bolt notches cut at the corners",
    # 09 section 3.7 engines
    "icon_module_e_std": "standard drive nozzle, a truncated cone with one plain ring around its throat and a wide open mouth cut at the exhaust end",
    "icon_module_e_ion": "ion drive nozzle, a truncated cone with a doubled ring around its throat, one bold short vane projecting from each side and a wide open mouth at the exhaust end",
    "icon_module_e_vector": "vector drive nozzle, a truncated cone held in a gimbal yoke with two bold projecting actuator arms and a wide open mouth at the exhaust end",
    # 09 section 3.5 boosters
    "icon_module_b_afterburner": "afterburner booster, a vent block with three wide open chevron slots cut straight through its face",
    "icon_module_b_fold": "fold drive booster, a square plate cut by one bold wide folded arrow-shaped slot straight through it, leaving a clear arrow-shaped opening",
    # 09 section 3.4 computers
    "icon_module_c_target": "targeting computer, a square boresight reticle frame with one large open square cut through its centre, a cross struck across the opening and one bold ranging tick on the lower edge",
    "icon_module_c_scanner": "scanner computer, a bold dish arc on a short stem with two wide concentric return arcs behind it",
    "icon_module_c_twin": "twin targeting stack, two square reticle frames with large open centres stacked one above the other and joined by one bold side bracket",
    "icon_module_c_ewar": "electronic warfare suite, a square board with one large open square cut through its centre and three bold radiating jam bars projecting from its right edge",
    "icon_module_c_nexus": "nexus computer, a square board with one large open central square and four wide straight slots cut from its corners to its edges",
    # 09 section 3.6 utility
    "icon_module_u_cargo": "cargo expander, an open crate with a thick raised lid held on one bold latch and a wide open interior gap",
    "icon_module_u_salvage": "salvage rig, a heavy clamp claw with one straight handle and a bold open hook curling from its jaw",
    "icon_module_u_refine": "ore refiner, a wide hopper funnel sitting on a squat drum with one bold output spout at the base and a large open funnel mouth",
    "icon_module_u_drones": "drone bay, an open bay slot with two bold arrowhead drones racked side by side inside a wide open frame",
    "icon_module_u_tractor": "tractor emitter, a bold cone emitter projecting three wide parallel field bars from its open mouth",
    "icon_module_u_holds": "hold expander, two stacked container blocks with a wide open rectangular gap cut between them and three bold vertical slots cut through each block",
}

MODULE_PANELS = {
    "panel_modules_a": [
        "icon_module_w_railgun", "icon_module_w_mining", "icon_module_s_light",
        "icon_module_s_heavy", "icon_module_s_ion", "icon_module_h_plate_light",
        "icon_module_h_plate_heavy", "icon_module_h_composite", "icon_module_p_std",
    ],
    "panel_modules_b": [
        "icon_module_p_mk2", "icon_module_p_core", "icon_module_e_std",
        "icon_module_e_ion", "icon_module_e_vector", "icon_module_b_afterburner",
        "icon_module_b_fold", "icon_module_c_target", "icon_module_c_scanner",
    ],
    "panel_modules_c": [
        "icon_module_c_twin", "icon_module_c_ewar", "icon_module_c_nexus",
        "icon_module_u_cargo", "icon_module_u_salvage", "icon_module_u_refine",
        "icon_module_u_drones", "icon_module_u_tractor", "icon_module_u_holds",
    ],
}

SLOT_GLYPHS = {
    "icon_slot_engine": "an engine slot socket: one bold trapezoidal nozzle block on a flat mount plate with a wide open mouth cut at the exhaust end",
    "icon_slot_power": "a power slot socket: a reactor core block with three wide vertical coil slots cut right through its face",
    "icon_slot_w": "a weapon slot socket: a hardpoint mount plate with a wide open U-shaped jaw cut through its top edge and two bold side lugs",
    "icon_slot_s": "a shield slot socket: a bold arc emitter half-ring set into a flat base plate, the arc open at the bottom",
    "icon_slot_h": "an armour slot socket: three flat plates stacked in a clearly offset step with wide open gaps between the layers",
    "icon_slot_c": "a computer slot socket: a square board frame with one large open square cut right through its centre and two bold corner notches",
    "icon_slot_b": "a booster slot socket: a vent block carrying one bold open chevron burst cut right through it",
    "icon_slot_u": "a utility slot socket: an open pod socket with a wide open mouth and a bold latch bracket across it",
}

CONTRACT_GLYPHS = {
    "icon_contract_haul": "haul contract: a closed crate sitting on a two-wheeled pallet bar",
    "icon_contract_hunt": "hunt contract: a crosshair reticle centred on a downward pointing chevron target",
    "icon_contract_gather": "gather contract: a two-jaw claw gripping a faceted rock chunk",
    "icon_contract_escort": "escort contract: two chevrons travelling in column inside a squared bracket",
    "icon_contract_expedition": "expedition contract: a ring with one bold arrow projecting outward from its rim",
}

SERVICE_GLYPHS = {
    "icon_service_vault": "vault service: a heavy vault door slab carrying a bold open three-spoke wheel with the spaces between the spokes cut right through as large openings",
    "icon_service_insurance": "insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it",
    "icon_service_bounty": "bounty service: a thick circular coin outline with a small square notch cut out of its rim and one short vertical tally mark cut inside it, unambiguously a coin and not a prohibition sign",
}

INSIGNIA_GLYPHS = {
    "icon_insignia_concord": "Concord of Iron emblem: a hex plate carrying three stacked horizontal plate bars",
    "icon_insignia_meridian": "Meridian Free Ports emblem: a hex plate split by one diagonal dock seam with a small pod block docked on the seam",
    "icon_insignia_choir": "Ember Choir emblem: a hex plate carrying a three-tongued radial flame",
}

# ---------------------------------------------------------------- P1 sectors

# 11 section 1 sector feel, one backdrop each.
SECTORS = [
    ("env_sector_1_bg", "Halcyon Reach, ordered home space under Concord of Iron law",
     "even, calm and orderly - a uniform very dark deep void blue #111823 field with a sparse even faint "
     "starfield and almost no dust structure at all, one very faint cool steel-grey wash toward the upper edge"),
    ("env_sector_2_bg", "Iron Marches, the industrial belt",
     "industrial and drab - a broad soft veil of grimy umber #4A423B dust hung low across the lower half only, "
     "grey and brown and fully desaturated, drifting in thin uncounted layers, over a sparse even faint starfield"),
    ("env_sector_3_bg", "Meridian Span, the trade crossroads",
     "open and travelled - a very faint cool grey-blue wash drifting across the upper right and a faint band of "
     "slightly brighter stars running along one diagonal as if a well travelled route, otherwise empty deep void "
     "blue #111823"),
    ("env_sector_4_bg", "Ashveil Expanse, the contested edge",
     "unsettled and cold - soft ragged bands of dark ash-grey haze in void haze #1A2230 and grimy umber #4A423B "
     "drifting in loose frayed layers with no hard edge anywhere, greyer and distinctly colder than the warm "
     "sectors, no brown glow and no warm tint"),
    ("env_sector_5_bg", "Cinder Verge, exotic territory",
     "warm and strange - broad soft veils of rusted ochre #6E5B4A and dry rust #8A6A50 dust drifting in a low "
     "arc across the lower third, still very dark, matte and non-emissive, the warmest of the seven plates, "
     "absolutely no glow, no ember and no burnt ember #C8461B"),
    ("env_sector_6_bg", "The Hollows, the deep exotic belt",
     "oppressive and close - heavy very dark dust density with long slow veils of void haze #1A2230 and grimy "
     "umber #4A423B, the faint starfield almost extinguished, the darkest and densest of the seven plates"),
    ("env_sector_7_bg", "Maw Belt, unaligned, no law, the arena",
     "hostile and abandoned - near-black void black #0A0E14 with faint soot-black smudges and a thin scatter of "
     "dark iron black #232629 grit suspended in the haze, completely cold and empty, no light source and no warm "
     "colour anywhere"),
]

SECTOR_SUBJECT = (
    "Sector backdrop plate for a space playfield, a single wide 16:9 full-frame painterly wash of empty deep "
    "space. The plate is ALMOST EMPTY: soft drifting haze, dust veils and a sparse faint starfield only, spread "
    "across the whole frame, with no focal point anywhere. Absolutely no stations, no ships, no wrecks, no "
    "debris, no asteroids, no planets, no moons, no atmospheric limbs, no rings, no structures, no silhouettes, "
    "no hard shapes and no objects of any kind; nothing crosses the frame and nothing sits centred or off-centre "
    "as a subject. Extremely low contrast, one value step darker than ships and never brighter than a whisper, "
    "so gameplay and interface elements read on top of it; the frame centre is the quietest and darkest region. "
    "Sector identity is carried only by colour and haze density: {feel}. Subtle film grain. " + ENV_NEG + " no "
    "space station, no docking ring, no ship, no hull, no wreck, no planet, no moon, no body limb, no torch "
    "light, no lamp and no glowing point of any kind.")


# ---------------------------------------------------------------- P1 anomaly FX trio

ANOMALY_FX = {
    "fx_anomaly_shimmer": (
        "Single ore-bloom anomaly shimmer effect, one isolated object centred in the frame, flat void black "
        "#0A0E14 background that is NOT white. A wide thin cold refraction ring drawn in cold pale steel highlight "
        "#565C63, its edge broken into short wavy refraction bands as if light is bending through it, the ring "
        "completely hollow and empty in the middle, a handful of suspended non-glowing ore flecks in rusted ochre "
        "#6E5B4A and dry rust #8A6A50 caught inside the wavy bands, cold and clinical with no warmth and no ember "
        "anywhere, absolutely no burnt ember #C8461B, no ember glow #E8703A, no orange, the ring thin and "
        "contained, subtle film grain, effects only, no ship parts, no rock body, no panel, no frame. "),
    "fx_anomaly_grave_glow": (
        "Single grave-cache anomaly glow effect, one isolated object centred in the frame, flat void black "
        "#0A0E14 background that is NOT white. A small dense cold point glow in cold pale steel highlight #565C63 "
        "at the centre of a soft unlit halo of deep void blue #111823 and void haze #1A2230, with a slow column of "
        "pale non-glowing motes rising from the point and a thin dark iron black #232629 ring of debris haze "
        "settled flat around its base, sombre and cold, absolutely no burnt ember #C8461B, no ember glow #E8703A, "
        "no orange, no warm colour anywhere, the glow small and contained, subtle film grain, effects only, no "
        "ship parts, no wreck hull, no panel, no frame, no gravestone shape. "),
    "fx_anomaly_rift": (
        "Single void-rift anomaly effect, one isolated object centred in the frame, flat void black #0A0E14 "
        "background that is NOT white. A vertical tear in space: a ragged torn slit of pure void with hard iron "
        "black #232629 jaw edges, the tear rim burning in burnt ember #C8461B with a thin ember glow #E8703A line "
        "only along the very edge of the tear, short crooked ember stress cracks radiating outward from both ends "
        "of the slit, a few dark shards caught in the tear, the interior of the tear completely black and empty, "
        "dangerous and thin, no fill glow, no beam, no field, no blue, no purple, no white core, painterly heat "
        "striations along the rim, subtle film grain, effects only, no ship parts, no panel, no frame. "),
}


# ---------------------------------------------------------------- P1 arena props

ARENA_PROP_SUBJECT = (
    "Arena prop sheet, two separate structures in an evenly spaced 1x2 grid (two columns, one row) with a "
    "generous gap, left to right, each structure isolated on a plain solid pure white background with empty "
    "white margins between them so they can be cut apart, no grid lines, no labels, no text, no shadows on the "
    "background, the two structures never touching. Every structure is a top-down orthographic painted render, "
    "one value step darker than ships, weathered gunmetal and rusted steel with scratches, hull grime, oil "
    "stains, rust streaks, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh "
    "directional key light from the upper left, subtle film grain. Subjects in reading order: 1 an arena nav "
    "pylon, a short heavy pylon post on a wide anchor base with a stacked ring beacon head at its top and small "
    "hot burnt ember #C8461B lamps set in the ring, a single isolated pylon with no fence and no wire; "
    "2 an arena barricade, a run of three bolted armour plates on two short posts with a segmented top rail and "
    "hazard-scored diagonal weld seams across the plate faces, no lamps, no glow, no ember. " + ENV_NEG)


# ---------------------------------------------------------------- run table

RUNS = {}

# Flat icon sheets pass the style block as the prompt preamble (see run_one) instead of
# via --style-file, so the ICONS_SPEC section 5 flat-vector sentence lands last.
ICON_STYLE_FIRST = dict(style_first=True)

# The F.1 resolution standard: every split icon family ships the four tiers from one
# master, cut aspect-preserving (ICONS_SPEC section 9.6). `cut_size` below is the rule.
ICON_SIZES = (16, 48, 96, 192)

# ---- P0 ----
RUNS["p0_minerals_ore"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(5, 4), sizes=ICON_SIZES,
    cuts=[f"icon_mineral_{m}" for m in MINERALS],
    subject=ICON_FRAME.format(grid="5x4", subjects=ore_subjects()), **ICON_STYLE_FIRST)

RUNS["p0_minerals_ingot"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(5, 4), sizes=ICON_SIZES,
    cuts=[f"icon_ingot_{m}" for m in MINERALS],
    subject=ICON_FRAME.format(grid="5x4", subjects=ingot_subjects()), **ICON_STYLE_FIRST)

for _panel, _names in MODULE_PANELS.items():
    RUNS[f"p0_{_panel}"] = dict(
        family="icons", aspect="1:1", mode="panel_white", grid=(3, 3), sizes=ICON_SIZES,
        cuts=list(_names),
        subject=ICON_FRAME.format(
            grid="3x3",
            subjects="; ".join(f"{i + 1} {MODULE_GLYPHS[n]}" for i, n in enumerate(_names))),
        **ICON_STYLE_FIRST)

RUNS["p0_slots"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(4, 2), sizes=ICON_SIZES,
    cuts=list(SLOT_GLYPHS),
    subject=ICON_FRAME.format(
        grid="4x2",
        subjects="; ".join(f"{i + 1} {s}" for i, s in enumerate(SLOT_GLYPHS.values()))),
    **ICON_STYLE_FIRST)

# ---- P1: hull ----
RUNS["ship_miner"] = dict(
    family="ships", aspect="1:1", mode="ship_sheet", cuts=sheet_cuts("ship_miner"),
    subject=ship_sheet(
        "Delver miner hull rotation sheet, a player mining ship. Framing: " + FRAMING_CONSTANT + " "
        "Silhouette: the central hull is the largest mass and is a broad flat slab, clearly wider than it is "
        "long, the flattest and widest hull in the roster. A ventral cutter bar projects below the centreline "
        "along the mid-hull carrying a row of cutting teeth large enough to catch the rim light on their tips, a "
        "boxed lidded dorsal ore bin rides above the mid-hull, and twin blunt engine pods flank the stern clear "
        "of the slab so their edges read. No weapon mounts, no thorns, no wings. Class markers: the ventral "
        "cutter bar plus the dorsal ore bin, a low wide working platform that cannot be mistaken for a boxy "
        "segmented freighter, an elongated spine-ridged corvette or a pod-flanked gunship. Weathering density: "
        "heavy industrial, hull grime toward the trailing edges, ore dust staining over the slab and the bin lid, "
        "oil stains around the engine pods, rust streaks from the rivet seams, pitted metal on the cutter bar, "
        "scratches, light battle damage on the forward plate only. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 "
        "hull with a cold steel highlight #565C63 rim. Engines and glow: 2 engines in the twin outboard side "
        "pods, dim civilian burnt ember C8461B flares with a faint small ember glow E8703A halo, small and "
        "contained, no other glow."))

# ---- P1: sector backdrops ----
for _name, _label, _feel in SECTORS:
    _n = _name.rsplit("_", 1)[0].rsplit("_", 1)[1]
    RUNS[f"sector_{_n}_bg"] = dict(
        family="env", aspect="16:9", mode="single_full", out=_name,
        subject=SECTOR_SUBJECT.format(feel=f"{_label}: {_feel}"))

# ---- P1: jump gate ring ----
RUNS["env_jump_gate_ring"] = dict(
    family="env", aspect="1:1", mode="single_trim", out="env_jump_gate_ring",
    subject=(
        "Jump gate ring, one single centred top-down orthographic render of a large radial gate structure, the "
        "structure occupying about 70 percent of the frame width, radially symmetric, no tilt and no perspective, "
        "isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. "
        "Structure: a very large segmented open ring of heavy welded platework, the ring visibly built from "
        "bolted arc segments with wide plate seams and rivet lines, and four massive square engine blocks "
        "clamped to the ring at the four diagonal stations, each block carrying a deep recessed vent grille, so "
        "the silhouette reads as four heavy masses ringing an open aperture. The aperture interior is completely "
        "empty: no energy field, no glow, no beam, no portal, no fill. Platework in gunmetal mid #3A3F46 and "
        "gunmetal dark #2B2F35 with heavy hull grime films, rust streaks bleeding from the segment seams, pitted "
        "metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh "
        "directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B "
        "warning lamps only, a handful of lamp points along the ring and one on each engine block, no ember glow "
        "halo, no aperture glow. " + ENV_NEG))

# ---- P1: anomaly FX trio ----
for _run, _subject in ANOMALY_FX.items():
    RUNS[_run] = dict(
        family="fx", aspect="1:1", mode="fx_void", out=_run,
        subject=_subject + FX_NEG + " no orange glow except where ember is named, nothing may be more than one "
                                    "accent colour.")

# ---- P1: arena props ----
RUNS["env_arena_props"] = dict(
    family="env", aspect="1:1", mode="panel_white", grid=(2, 1), sizes=None,
    cuts=["env_arena_nav_pylon", "env_arena_barricade"],
    subject=ARENA_PROP_SUBJECT)

# ---- P1: arena bosses (i2i from the shipped band hulls) ----
RUNS["ship_boss_boneyard"] = dict(
    family="ships", aspect="1:1", mode="i2i_single", out="ship_boss_boneyard",
    ref=ASSETS / "ships/ship_gunship_side.png",
    subject=(
        "Same gunship-band hull, identical silhouette massing, identical proportions, identical framing, "
        "identical camera and identical lighting; re-render only the weathering and the boss core. Framing: "
        + FRAMING_CONSTANT + " Keep the two oversized blocky broadside weapon pods flanking the squat core and "
        "the twin recessed stern nozzles exactly as in the reference. New boss feature: the forward plate is "
        "split open to expose one wide horizontal ember core slot across the bow shoulder, glowing ember glow "
        "E8703A over a burnt ember C8461B heart, contained to the slot and never ambient; two short thorned "
        "protrusions project from the bow beside the core slot. Weathering: heaviest in the roster, battle "
        "damage with dents, torn plate edges and scorch-blackened craters, weld beads over repairs, scorch marks "
        "radiating from the pods and the core slot, rust streaks, oil stains, hull grime, pitted metal, "
        "scratches. Engines: burnt ember C8461B flares with small hot ember glow E8703A halos. Keep the render "
        "isolated on a fully transparent background with no backdrop and no ground shadow. " + SHIP_NEG))

RUNS["ship_boss_pyre"] = dict(
    family="ships", aspect="1:1", mode="i2i_single", out="ship_boss_pyre",
    ref=ASSETS / "ships/ship_patrol_side.png",
    subject=(
        "Same frigate-band patrol hull, identical silhouette massing, identical proportions, identical framing, "
        "identical camera and identical lighting; re-render only the weathering and the boss core. Framing: "
        + FRAMING_CONSTANT + " Keep the mid-length hull, the forward lance mount at the bow and the clean flat "
        "plated sides exactly as in the reference. New boss feature: the single dorsal fin is replaced by a tall "
        "stacked altar of three stepped plate segments carrying a vertical ember core in a recessed channel down "
        "its face, glowing ember glow E8703A over a burnt ember C8461B heart, contained to the channel and never "
        "ambient; short thorned nodes stand along both flanks. Weathering: heaviest in the roster, battle damage "
        "with dents, torn plate edges and scorch-blackened craters, weld beads over repairs, scorch marks "
        "radiating from the core channel, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines: "
        "burnt ember C8461B flares with small hot ember glow E8703A halos. Keep the render isolated on a fully "
        "transparent background with no backdrop and no ground shadow. " + SHIP_NEG))

# ---- P1: hunter liveries (3 factions, i2i from the shipped fighter sheet) ----
_HUNTER_LIVERIES = {
    "concord": ("Concord of Iron", "heavy horizontal riveted plate rows stacked across the hull with squared "
                                   "weld seams and stamped serial bands along the flanks, regulation naval "
                                   "refit, uniform and maintained",
                "extra hull grime film and heavy oil staining over the standard scratches, no battle damage, "
                "dented forward plate only"),
    "meridian": ("Meridian Free Ports", "long continuous plate bands wrapping the hull with sparse rivet lines, "
                                        "very few panel seams and mismatched replacement plates swapped in "
                                        "around the engine block, company-town patchwork",
                 "scratches, oil stains and busy handling scuffing, hull grime along the seams, no battle "
                 "damage"),
    "choir": ("Ember Choir", "dense pitted metal scored with soot-blackened ritual seam grooves cut in a radial "
                             "pattern over the hull, tally notches cut into the plating and crude weld-bead "
                             "patch repairs",
              "heaviest rust streaks and battle damage over the front plating, scorch marks around the engine "
              "block, pitted metal"),
}
for _code, (_faction, _pattern, _weather) in _HUNTER_LIVERIES.items():
    RUNS[f"livery_fighter_{_code}"] = dict(
        family="ships", aspect="1:1", mode="i2i_sheet", cuts=sheet_cuts(f"ship_fighter_{_code}"),
        ref=ASSETS / "ships/20260917-183314/fighter-enemy-hull-rotation-sheet-four-1-alpha.png",
        subject=(
            f"Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical "
            f"proportions, identical framing, identical camera, identical lighting and identical engine glow; "
            f"re-render only the hull plate pattern and the weathering distribution. Framing constant, per cell: "
            f"{FRAMING_CONSTANT} This is the {_faction} bounty-hunter livery. New plate pattern: {_pattern}. "
            f"Weathering: {_weather}. Keep the short dart-like hull, the twin close-set engines and the burnt "
            f"ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent "
            f"background with empty transparent margins, and keep the same reading order: front, three-quarter, "
            f"side, back. " + SHIP_NEG))

# ---- P2 ----
RUNS["p2_contracts"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(2, 3), sizes=ICON_SIZES,
    cuts=list(CONTRACT_GLYPHS),
    subject=ICON_FRAME.format(
        grid="2x3",
        subjects="; ".join(f"{i + 1} {s}" for i, s in enumerate(CONTRACT_GLYPHS.values()))
                 + "; 6 an empty blank white cell, leave the last cell completely empty and blank"),
    **ICON_STYLE_FIRST)

RUNS["p2_service_glyphs"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(2, 2), sizes=ICON_SIZES,
    cuts=list(SERVICE_GLYPHS),
    subject=ICON_FRAME.format(
        grid="2x2",
        subjects="; ".join(f"{i + 1} {s}" for i, s in enumerate(SERVICE_GLYPHS.values()))
                 + "; 4 an empty blank white cell, leave the last cell completely empty and blank"),
    **ICON_STYLE_FIRST)

RUNS["p2_faction_insignia"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(2, 2), sizes=ICON_SIZES,
    cuts=list(INSIGNIA_GLYPHS),
    subject=ICON_FRAME.format(
        grid="2x2",
        subjects="; ".join(f"{i + 1} {s}" for i, s in enumerate(INSIGNIA_GLYPHS.values()))
                 + "; 4 an empty blank white cell, leave the last cell completely blank"),
    **ICON_STYLE_FIRST)

# ---- F.1 integrity pass (work order DESIGNER_TODO.MD Stage 2, owner-approved 2026-09-18) ----

# C2 - the data core 16 px read was a solid square (ink coverage 0.98, silhouette touching
# all four frame edges, ASSET_AUDIT C2). The correction is at the MASTER: fewer interior
# cuts and a clear margin, so the 16 px cut thresholds to a glyph instead of a block.
RUNS["f1_data_core"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(1, 1), sizes=ICON_SIZES,
    cuts=["icon_cargo_data_core"],
    subject=ICON_FRAME.format(
        grid="1x1",
        subjects=("a single data core slab, frontal flat view: a plain square slab drawn as a "
                  "THIN OUTLINE with a uniform 1.5 px-equivalent stroke, one small square inset "
                  "centred inside it drawn the same weight with a wide clear gap of white between "
                  "the inset and the outer slab edge, and two small rectangular notches cut out of "
                  "the slab's top-left and bottom-right corners. Only two interior cuts in total, "
                  "large open negative space, the whole silhouette clear of the cell edges with a "
                  "generous even white margin on every side so the glyph reads as an outline "
                  "square at 16 px and never as a solid block")),
    **ICON_STYLE_FIRST)

# C2b - outline-weight glyphs: at 16 px the ~1.4 px-equivalent strokes of the Phase B panel
# read grey instead of solid iron black (ICONS_SPEC section 9.4 item 2). Thickening is a
# master fix, so the four glyphs are regenerated on their own sheet and re-cut.
RUNS["f1_glyph_outline"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(2, 2), sizes=ICON_SIZES,
    cuts=["icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield"],
    subject=ICON_FRAME.format(
        grid="2x2",
        subjects=("1 a zoom-in glyph: a square magnifier outline with a plus built from two crossing "
                  "bars inside, 2 a zoom-out glyph: the same square magnifier outline with a single "
                  "horizontal bar inside, 3 a credits glyph: a hexagonal coin outline with a plain "
                  "vertical bar struck through its centre, 4 a shield glyph: a flat heater-shield "
                  "outline with a single vertical centre seam. Every stroke of every glyph is drawn "
                  "at a uniform THICK weight of at least 2 px at 16 px final size, that is about "
                  "three times the stroke of the thinnest hairlines, so each stroke still thresholds "
                  "to solid iron black when the sheet is reduced to 16 px, with no grey or broken "
                  "hairlines anywhere")),
    **ICON_STYLE_FIRST)

# C4 - env_body_ice_moon read one value step brighter than the ships family (ASSET_AUDIT C4).
# Optional item, run only in a scheduled batch; the subject is wave_e's with the value fixed.
RUNS["f1_ice_moon"] = dict(
    family="env", aspect="1:1", mode="single_trim", out="env_body_ice_moon",
    subject=(
        "Airless ice moon, a dead spherical body seen from above with no atmosphere, top-down orthographic, "
        "the moon occupies about 70 percent of frame width, centroid at frame centre, background flat void "
        "black 0A0E14, transparent where a sprite is required. Surface: a desaturated ice-crusted crust TWO "
        "value steps darker than ships, a dark grey-blue ice in the #2B2F35 to #3A3F46 range with only sparse "
        "pale frost speckle, cracked into polygonal plates with a cold steel highlight #565C63 rim catching "
        "along the cracks, ancient impact craters with raised rims, dirty streaks of grey rock between the ice "
        "fields, no blue tint, no atmosphere, no clouds, no terminator glow, no emissive, no glow of any kind. "
        "The moon surface fills the frame edge to edge with the round limb of the body visible. " + ENV_NEG))

# C1 - the shipped frame's painted border band is 7 px against the 32 px nine-slice margin, so
# a 32 px slice tiles 7 px of border plus 25 px of panel black and the frame reads about 4.5x
# too thick with the riveted corners cropped (ASSET_AUDIT C1, UI_CHROME_ASSETS_SPEC section 2).
# Regenerated with the band fixed at exactly one third of the square, plus the @2x cut
# (section 10: 192 px, 64 px band).
RUNS["f1_panel_frame"] = dict(
    family="ui", aspect="1:1", mode="single_trim", out="ui_panel_frame",
    sizes=(96, 192), size_names={192: "ui_panel_frame@2x"},
    subject=(
        "ui_panel_frame: a single square painted gunmetal metal panel frame, top-down orthographic, grimdark "
        "painted sci-fi. The painted border band is EXACTLY ONE THIRD of the square's total width on all four "
        "sides, that is 32 px thick at a final texture size of 96 px and 64 px thick at 192 px, so the recessed "
        "interior opening is the central third square. The band is uniform and straight so the left edge band is "
        "identical top to bottom, the top edge band identical left to right, and the frame stretches cleanly when "
        "tiled over a larger panel. Border face is panel steel #2A2E35 with a 1 px steel highlight #565C63 inner "
        "edge catch against the interior and an iron black #232629 outer edge giving a shallow bevelled read, no "
        "deep 3D bevel. Recessed interior fill is panel black #15181D with a very subtle inner shadow just inside "
        "the frame edge. Corners bevelled with chamfered 45 degree corner cuts, never rounded, never arcs. Each "
        "corner carries a riveted corner detail of two or three small rivet heads with pitted metal speckle and a "
        "steel highlight catch set into a slightly denser corner plate, and those rivets stay entirely inside the "
        "corner squares and never bleed into the straight edge bands. Subtle film grain at reduced opacity, faint "
        "hull grime toward the frame, at most a few faint scratches, no rust streaks, no oil stains, no gloss, no "
        "chrome, no text, no labels, no grid lines, no glow. The square frame is centred on a plain solid pure "
        "white background with clean pure white margins all around it for background removal."))

# ------------------------------------------------------------------ Phase F.2
# Owner-approved batch (2026-09-18) closing the F.1 C1/C2b/C3/C4 residue plus the four
# blocked ui_button_plate @2x chrome cuts: five runs, $0.25. Each run fixes its defect at
# the MASTER (never at a cut) and is followed by a free local step that measures the fix:
#   f2_panel_frame   -> reband_frame.py cuts the nine-slice at an exact 1/3 band
#   f2_glyph_heavy   -> recut_quartet.py re-cuts the quartet from the heavy master
#   f2_drone_swarm   -> the F.1 fringe/re-key passes, re-measured by qc_f1.py
#   f2_button_plates -> plates_cut.py cuts the 1x and the 2x from the same cells
#   f2_ice_moon      -> qc_f2.py measures the subject mean against the ships family

# C1 - the F.1 frame regeneration landed a band of 15 px at 96 against the spec's 32 px
# nine-slice margin (ICONS_SPEC section 9.7, UI_CHROME_ASSETS_SPEC section 2). One more
# run that makes the band the dominant feature: the master is then re-banded locally to an
# exact 1/3 band, so the margin law holds whatever band the model returns.
RUNS["f2_panel_frame"] = dict(
    family="ui", aspect="1:1", mode="single_trim", out="ui_panel_frame-master",
    subject=(
        "ui_panel_frame: a single square painted gunmetal metal panel frame, top-down orthographic, grimdark "
        "painted sci-fi. THE BORDER IS THE SUBJECT: the frame is an extremely heavy square ring whose painted "
        "band is EXACTLY ONE THIRD of the square's total width on all four sides, so the recessed interior "
        "opening is only the central third square - a small opening surrounded by a band as thick as a third of "
        "the whole image, 32 px thick at a final texture size of 96 px and 64 px thick at 192 px. The band is "
        "uniform and straight so the left edge band is identical top to bottom, the top edge band identical left "
        "to right, and the frame stretches cleanly when tiled over a larger panel. Border face is panel steel "
        "#2A2E35 with a 1 px steel highlight #565C63 inner edge catch against the interior and an iron black "
        "#232629 outer edge giving a shallow bevelled read, no deep 3D bevel. Recessed interior fill is panel "
        "black #15181D with a very subtle inner shadow just inside the frame edge. Corners bevelled with chamfered "
        "45 degree corner cuts, never rounded, never arcs. Each corner carries a riveted corner detail of two or "
        "three small rivet heads with pitted metal speckle and a steel highlight catch set into a slightly denser "
        "corner plate; every rivet, plate and chamfer is small, no more than one sixth of the band's own width, so "
        "the whole corner detail sits deep inside the band and never touches or crosses the interior opening. "
        "Subtle film grain at reduced opacity, faint hull grime toward the frame, at most a few faint scratches, no "
        "rust streaks, no oil stains, no gloss, no chrome, no text, no labels, no grid lines, no glow. The square "
        "frame is centred on a plain solid pure white background with clean pure white margins all around it for "
        "background removal."))

# C2b - the F.1 outline glyphs comply with section 1 (1.67 px-equivalent stroke at 16 px) and
# therefore still read grey at 16 px: the acceptance sentence and the stroke law contradict
# each other (ICONS_SPEC section 9.7). This run draws the same four glyphs in a deliberately
# heavy stroke weight, the F.2 resolution of that contradiction.
RUNS["f2_glyph_heavy"] = dict(
    family="icons", aspect="1:1", mode="panel_white", grid=(2, 2), sizes=ICON_SIZES,
    cuts=["icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield"],
    subject=ICON_FRAME.format(
        grid="2x2",
        subjects=("1 a zoom-in glyph: a square magnifier outline with a plus built from two crossing bars "
                  "inside, 2 a zoom-out glyph: the same square magnifier outline with a single horizontal bar "
                  "inside, 3 a credits glyph: a hexagonal coin outline with a plain vertical bar struck through "
                  "its centre, 4 a shield glyph: a flat heater-shield outline with a single vertical centre seam. "
                  "EVERY STROKE IS HEAVY AND CHUNKY: each stroke is a bold bar at least 3 px wide at 16 px final "
                  "size, that is about one fifth of the glyph's own width, drawn like a heavy stencil or a bold "
                  "road sign; the strokes are as thick as the negative space they enclose, the enclosed white "
                  "gaps stay wide and open, corners are hard mitred, no taper and no rounded ends")
                  + HEAVY_STROKE_TAIL),
    **ICON_STYLE_FIRST)

# C3 - the four ship_drone_swarm_* views carry model-rendered white shards at the silhouette
# (99 components, the largest 252 px) that survive both the defringe and the luminance
# re-key, because the nearest opaque pixel is itself white (ICONS_SPEC section 9.7). The
# F.2 prompt removes the cause: the pale rim light and every value lighter than the palette's
# darkest steel are excluded from the hull.
RUNS["f2_drone_swarm"] = dict(
    family="ships", aspect="1:1", mode="ship_sheet",
    cuts=sheet_cuts("ship_drone_swarm"),
    subject=ship_sheet(
        "Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular "
        "shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, "
        "no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, "
        "immediately readable as smaller than every other hull. Weathering density: light, scratches and hull "
        "grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. "
        "The drone is drawn small inside each cell, occupying about 40 percent of its cell width. THE HULL CARRIES "
        "NO PALE VALUE ANYWHERE: no white, no cream, no pale grey, no bright specular highlight, no rim light and "
        "no white or light-grey shard, spike, sliver, chip or speck anywhere on the hull or along its silhouette; "
        "the brightest colour anywhere on the ship is the palette's cold steel highlight #565C63 and even that is "
        "used only as a thin edge catch, never as a large or bright area. Every silhouette edge is a crisp dark "
        "edge against empty transparent space, with no white anti-aliased fringe, no pale halo, no white glow and "
        "no bright outline tracing the hull."))

# Chrome - the four ui_button_plate_* have no retained source that reproduces them, so their
# @2x cuts are blocked (UI_CHROME_ASSETS_SPEC section 10). One run redraws the 2x2 plate panel;
# plates_cut.py then cuts BOTH the logical 280x56 and the 560x112 @2x from the same cells, so
# the pair is the same art at two scales by construction.
RUNS["f2_button_plates"] = dict(
    family="ui", aspect="1:1", mode="panel_white", grid=(2, 2),
    cuts=["ui_button_plate_normal", "ui_button_plate_hover",
          "ui_button_plate_pressed", "ui_button_plate_disabled"],
    subject=(
        "2x2 grid panel of four very wide thin horizontal gunmetal button plates, each plate exactly five times "
        "as wide as it is tall, long narrow painted metal plates centred in each square cell, drawn perfectly "
        "horizontal and perfectly straight, spanning about 80 percent of the cell width, with large plain solid "
        "pure white margins above and below every plate, top-left plate normal gunmetal with two small rivets at "
        "its two ends, top-right plate one step brighter with a faint burnt ember under-light baked along the "
        "lower bevel only, bottom-left plate darker and slightly inset with a shallow pressed bevel, bottom-right "
        "plate dimmed and desaturated with no glow, no text, no glyphs, no icons on any plate. Each plate has a "
        "clean crisp dark edge all the way around it: no white or pale halo, no white or pale fringe, no soft or "
        "feathered edge, no glow around the plate, no cast shadow and no drop shadow on the white background, no "
        "white highlight larger than a hairline, plain solid pure white background, 2K, 1:1"))

# C4 - the F.1 ice moon landed 36 percent darker than the ships family mean but still one bar
# above it (mean subject luminance 58.7 against 54.3). Three value steps, not two.
RUNS["f2_ice_moon"] = dict(
    family="env", aspect="1:1", mode="single_trim", out="env_body_ice_moon",
    subject=(
        "Airless ice moon, a dead spherical body seen from above with no atmosphere, top-down orthographic, "
        "the moon occupies about 70 percent of frame width, centroid at frame centre, background flat void "
        "black 0A0E14, transparent where a sprite is required. Surface: a very dark desaturated ice-crusted "
        "crust THREE value steps darker than the ships family, a near-black grey-blue ice in the #171A1F to "
        "#24282E range with only sparse and faint pale frost speckle at a low opacity, cracked into polygonal "
        "plates with a dim cold steel highlight #565C63 caught along the cracks and no brighter highlight "
        "anywhere, ancient impact craters with raised rims, dirty streaks of grey rock between the ice fields, "
        "the whole surface reading aggressively dark and low-key with nothing at full white, no bright specular "
        "catch, no blue tint, no atmosphere, no clouds, no terminator glow, no emissive, no glow of any kind. "
        "The moon surface fills the frame edge to edge with the round limb of the body visible. " + ENV_NEG))

# ---------------------------------------------------------------- helpers


def log_run(family, markdown, phase="Phase F"):
    log_path = STAGE / family / "generation_log_phase_f.md"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if not log_path.exists():
        log_path.write_text(
            f"# {phase} - generation log\n\n"
            "Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.\n"
            "Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, "
            "`docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), "
            "`docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).\n"
            "Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.\n"
            "Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed "
            "30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.\n"
            "Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). "
            "FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).\n"
            "AI-generated art is not CC0 (AGENTS.md).\n\n---\n\n",
            encoding="utf-8")
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(markdown)
        fh.write("\n---\n\n")


def load_kg():
    spec_mod = importlib.util.spec_from_file_location("kg", SKILL)
    kg = importlib.util.module_from_spec(spec_mod)
    spec_mod.loader.exec_module(kg)
    return kg


def ensure_alpha(master):
    """Return (path, note): native alpha if present, else local matte."""
    img = Image.open(master)
    if img.mode in ("RGBA", "LA"):
        alpha = img.convert("RGBA").getchannel("A").histogram()
        total = img.size[0] * img.size[1]
        if alpha[0] / total > 0.10:
            return master, "native-alpha"
    out = Path(master).with_name(Path(master).stem + "-matte.png")
    _, bg, alpha0, _, dropped = matte(master, out)
    return out, (f"local matte bg=#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} "
                 f"alpha0={alpha0:.0f}% dropped={dropped}")


def trim_to(src, dest, pad=None):
    """Trim to the alpha bounding box, keeping a small even margin."""
    import reprocess as rp
    pad = rp.CUT_PAD if pad is None else pad
    img = Image.open(src).convert("RGBA")
    bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        left = max(0, bbox[0] - pad)
        top = max(0, bbox[1] - pad)
        right = min(img.size[0], bbox[2] + pad)
        bottom = min(img.size[1], bbox[3] + pad)
        img = img.crop((left, top, right, bottom))
    img.save(dest)
    return dest


def cut_size(master, size):
    """Aspect-preserving contain cut: the master's longest side becomes `size`.

    ICONS_SPEC section 9.6 (F.1). The pre-F.1 code stretched the trimmed master to a
    square (`Image.resize((size, size))`), which distorted every non-square glyph by
    up to 2.6x; `staging/phase_f/recut_quartet.py --fit square` still reproduces that
    old geometry as the reversal path.
    """
    scaled = master.convert("RGBA").copy()
    scaled.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(scaled, ((size - scaled.size[0]) // 2, (size - scaled.size[1]) // 2))
    return canvas


def find_master(spec):
    """Locate this run's own master: newest run folder whose stored prompt is this
    spec's subject, exactly.

    The whole subject must be matched, not a prefix or suffix of it: every flat icon
    panel shares the ICON_OVERRIDE + negative-list tail verbatim, so a tail match
    resolves to whichever panel was generated last (this silently re-cut nine panels
    from the wrong master once - do not weaken this comparison).
    """
    subject = spec["subject"].strip()
    family_dir = STAGE / spec["family"]
    if not family_dir.is_dir():
        return None
    for run_dir in sorted((p for p in family_dir.iterdir() if p.is_dir()), reverse=True):
        job = run_dir / "job.json"
        if not job.exists():
            continue
        payload = json.loads(job.read_text(encoding="utf-8"))
        prompt = (payload.get("input", {}).get("prompt") or "").strip()
        if not (prompt.startswith(subject) or prompt.endswith(subject)):
            continue
        for pattern in ("*-1-alpha.png", "*-1.png"):
            hits = sorted(run_dir.glob(pattern))
            if hits:
                return hits[0]
    return None


def split_cuts(source, cuts, grid, prefer_grid=False):
    """Cut a panel into cells.

    Grid cut first for panels that declare a grid: ICONS_SPEC section 5 says the panel
    is split on its grid, and it is deterministic. Component splitting is only a
    fallback (it can fragment one glyph into two connected components and still happen
    to total the expected count - observed on panel_modules_c, where the twin reticle
    pair was cut as a 102 px sliver).
    """
    if prefer_grid and grid:
        got = grid_split(Path(source), cols=grid[0], rows=grid[1])
        if len(got) == len(cuts):
            return got, "grid"
        print(f"  grid cut gave {len(got)} of {len(cuts)} cells; trying component split", flush=True)
    kg = load_kg()
    got = kg.split_components(Path(source), Path(source).parent, Path(source).stem + "-cut")
    mode = "component"
    if len(got) != len(cuts) and grid:
        print(f"  component split gave {len(got)} of {len(cuts)} cells; using grid cut {grid}", flush=True)
        got = grid_split(Path(source), cols=grid[0], rows=grid[1])
        mode = "grid"
    return got, mode


def run_one(run_id, dry=False, note=None, post_only=False):
    spec = RUNS[run_id]
    family_dir = STAGE / spec["family"]
    family_dir.mkdir(parents=True, exist_ok=True)
    mode = spec["mode"]

    cmd = [PY, str(SKILL), "--model", "flare",
           "--aspect", spec["aspect"], "--resolution", "2K",
           "--out", str(family_dir)]
    if spec.get("style_first"):
        # The style block is appended by --style-file, i.e. always after the subject, and
        # on the flat icon sheets its painted-metal / void-background / ember-glow wording
        # deterministically beats the ICONS_SPEC section 5 flat framing sentence (verified:
        # two consecutive painted renders with ember glow). The block is still copied
        # verbatim - read from the file at run time, so it cannot drift - but passed as the
        # prompt preamble instead, so the flat-vector instruction is the last thing read.
        style_text = STYLE_FILE.read_text(encoding="utf-8").strip()
        prompt = style_text + "\n\n" + spec["subject"]
        cmd += ["--prompt", prompt]
    else:
        cmd += ["--prompt", spec["subject"], "--style-file", str(STYLE_FILE)]
    if mode == "panel_white":
        cmd += ["--strip-bg", "local", "--bg-color", "FFFFFF"]
    elif mode in ("ship_sheet", "i2i_sheet", "i2i_single", "single_trim"):
        cmd.append("--transparent")
    # single_full (opaque backdrops) and fx_void (RGB on void black) take neither.
    refs = spec.get("ref")
    if refs:
        cmd += ["--ref"] + [str(r) for r in (refs if isinstance(refs, (list, tuple)) else [refs])]

    if post_only:
        master = find_master(spec)
        if master is None:
            print(f"[{run_id}] NO MASTER FOUND", flush=True)
            return False
        task_id, elapsed = "post-only", "post-only"
        print(f"[{run_id}] post-only master={master}", flush=True)
    else:
        if dry:
            proc = subprocess.run(cmd + ["--dry-run"], capture_output=True, text=True,
                                  encoding="utf-8", errors="replace")
            print(f"[{run_id}] {proc.stdout.strip()}\n{proc.stderr.strip()}", flush=True)
            return proc.returncode == 0

        cmd.append("--yes")
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
    finals = []
    extra = []

    if mode == "panel_white":
        # The skill's --strip-bg local does not key these off-white renders;
        # matte the master locally (free), then split on that alpha.
        source, how = ensure_alpha(master)
        notes.append(how)
        cuts, how_cut = split_cuts(source, spec["cuts"], spec["grid"], prefer_grid=True)
        notes.append(f"{how_cut} split")
        if len(cuts) != len(spec["cuts"]):
            print(f"[{run_id}] WARNING expected {len(spec['cuts'])} cuts, got {len(cuts)}", flush=True)
        for cut_path, name in zip(cuts, spec["cuts"]):
            dest = family_dir / f"{name}.png"
            trim_to(cut_path, dest)
            finals.append(dest)
            if spec.get("sizes"):
                master_img = Image.open(dest).convert("RGBA")
                for size in spec["sizes"]:
                    out = family_dir / f"{name}_{size}.png"
                    cut_size(master_img, size).save(out)
                    extra.append(out)
    elif mode in ("ship_sheet", "i2i_sheet"):
        source, how = ensure_alpha(master)
        notes.append(how)
        cuts, how_cut = split_cuts(source, spec["cuts"], (2, 2))
        notes.append(f"{how_cut} split")
        if len(cuts) != len(spec["cuts"]):
            print(f"[{run_id}] WARNING expected {len(spec['cuts'])} cuts, got {len(cuts)}", flush=True)
        for cut_path, name in zip(cuts, spec["cuts"]):
            dest = family_dir / f"{name}.png"
            trim_to(cut_path, dest)
            finals.append(dest)
    elif mode in ("single_trim", "i2i_single"):
        source, how = ensure_alpha(master)
        notes.append(how)
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        trim_to(source, dest)
        finals.append(dest)
        if spec.get("sizes"):
            # Chrome cuts (UI_CHROME_ASSETS_SPEC section 10). Chrome keeps the G6
            # convention of an exact resize to the target box; a size may carry its own
            # name because the 2x chrome cut is `@2x`, not `_192`.
            master_img = Image.open(dest).convert("RGBA")
            for size in spec["sizes"]:
                label = spec.get("size_names", {}).get(size, f"{dest.stem}_{size}")
                out = family_dir / f"{label}.png"
                master_img.resize((size, size), Image.LANCZOS).save(out)
                extra.append(out)
    elif mode == "fx_void":
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        Image.open(master).convert("RGB").save(dest)
        notes.append("RGB on void black, not alpha-keyed (FX_SPEC 0.1)")
        finals.append(dest)
    else:  # single_full - opaque backdrop
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        Image.open(master).convert("RGB").save(dest)
        notes.append("opaque, no alpha key")
        finals.append(dest)

    job_src = Path(master).parent / "job.json"
    if job_src.exists():
        for path in finals:
            (family_dir / f"{path.stem}.job.json").write_text(
                job_src.read_text(encoding="utf-8"), encoding="utf-8")

    for path in finals:
        img = Image.open(path)
        alpha = img.convert("RGBA").getchannel("A").histogram() if img.mode == "RGBA" else None
        total = img.size[0] * img.size[1]
        cover = f" alpha0={100 * alpha[0] / total:.0f}%" if alpha else " opaque"
        print(f"[{run_id}] final {path.name} {img.size} {img.mode}{cover}", flush=True)

    log_run(spec["family"], (
        (f"## {run_id} - post-only re-cut\n\n"
         f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
         f"- Reason: free local re-cut of the stored master (split method change, no API call).\n"
         f"- Master: `{Path(master).parent.name}`\n"
         if post_only else
         f"## {run_id}\n\n"
         f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
         f"- Model: `{'gpt-image-2-5-flare-image-to-image' if spec.get('ref') else 'gpt-image-2-5-flare-text-to-image'}` "
         f"(`{'flare-i2i' if spec.get('ref') else 'flare'}`), 2K, {spec['aspect']}\n"
         f"- Job id: `{task_id}` (elapsed {elapsed}s)\n"
         f"- Style block: `style-block.txt` verbatim"
         f"{' as the prompt preamble (see the ICONS_SPEC section 8 note)' if spec.get('style_first') else ' via --style-file'}\n") +
        f"- Reference: {spec.get('ref', 'none (text-to-image)')}\n"
        f"- Alpha: {', '.join(notes)}; run folder `{Path(master).parent.name}` keeps `job.json`\n"
        f"- Final files: {', '.join(p.name for p in finals)}"
        f"{' (+ ' + str(len(extra)) + ' size cuts)' if extra else ''}\n"
        f"{'- Note: ' + note + chr(10) if note else ''}"
        f"- Status: success\n\n"
        f"Full SUBJECT text:\n\n> {spec['subject']}\n"))
    return True


if __name__ == "__main__":
    args = sys.argv[1:]
    dry = "--dry-run" in args
    post_only = "--post-only" in args
    note = None
    if "--note" in args:
        note = args[args.index("--note") + 1]
        args = [a for a in args if a != note]
    args = [a for a in args if not a.startswith("--")]
    if not args:
        for key in RUNS:
            print(key)
        sys.exit(0)
    ok = all(run_one(run_id, dry=dry, note=note, post_only=post_only) for run_id in args)
    sys.exit(0 if ok else 1)
