"""Phase G driver: alien hull sheets, the Phase G FX inventory, and the human ship rework.

Work order: `.agents/gen/dispatch_designer.md` (graphics orchestrator lane) - alien hulls for all
three families (swarmer first, slice-2 W3 gates its visual pass on that sheet), then the Phase G
FX of `docs/design/FX_SPEC.md` section 7.2, then the human-family ship rework sheets. Style law:
`docs/design/STYLE_BIBLE.md` - the human block (section 9) for human assets, the alien addendum
(section 9.1) for alien ones, both passed verbatim as the prompt preamble.

Alpha route, in the owner's order ("best without background, or do background removal"): ask for
native transparency with `--transparent`, keep it when the render comes back with real alpha, and
otherwise leave the master opaque for `staging/phase_g/key_new.py`, which keys it on kie.ai with
recraft/remove-background exactly like the 2026-09-20 pass. FX are never keyed: they stay RGB on
void black for additive blending (FX_SPEC sections 0 and 0.1).

Usage:
    py -3.14 staging/phase_g/wave_g.py --list
    py -3.14 staging/phase_g/wave_g.py <run-id> --dry-run
    py -3.14 staging/phase_g/wave_g.py <run-id> [<run-id> ...]
    py -3.14 staging/phase_g/wave_g.py <run-id> --post-only     # re-cut the stored master, free
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"
ASSETS = ROOT / "vajb-orbit" / "assets"
STYLE_HUMAN = ASSETS / "style-block.txt"
STYLE_ALIEN = ASSETS / "style-block-alien.txt"
## The image-generator skill's script, which lives under a different prefix per host (AGENTS.md,
## host portability): `KIE_SKILL_SCRIPTS` wins, then the Windows install, then this host's.
_WINDOWS_SKILL_DIR = Path("C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts")
SKILL = (Path(os.environ["KIE_SKILL_SCRIPTS"]) / "kie_generate.py"
         if os.environ.get("KIE_SKILL_SCRIPTS")
         else (_WINDOWS_SKILL_DIR / "kie_generate.py" if _WINDOWS_SKILL_DIR.is_dir()
               else Path.home() / ".local/share/crush/skills/image-generator/scripts"
               / "kie_generate.py"))
CA_BUNDLE = ROOT.parent / "cacert.pem"
PY = sys.executable

## SHIPS_SPEC section 1, verbatim framing constant, and section 6, verbatim negative list.
FRAME = ("top-down orthographic, facing right, ship occupies about 60 percent of frame width, "
         "centroid at frame centre, background flat void black #0A0E14")
NEG = ("no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, "
       "no text, no watermark, no grid lines, no labels")
## FX_SPEC section 0.1's negative list.
NEG_FX = ("no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, "
          "no lens flare, no bokeh, no second glow colour")

VIEWS = ("front", "three_quarter", "side", "back")

## One 2x2 sheet per hull: the four views of the same object, cells named in reading order.
CELL_ORDER = ("top-left cell: bow pointing up (front view). "
              "top-right cell: bow rotated 45 degrees (three-quarter view). "
              "bottom-left cell: bow pointing right (side view). "
              "bottom-right cell: bow pointing down (rear view)")


def hull(clss: str, watch: str) -> str:
    return (f"single {clss} hull, {watch}. A panel of four views of the SAME ship in an evenly "
            "spaced 2x2 grid, one view per cell, generous gaps of flat void black between cells, "
            "no grid lines, no labels, no text, no border. " + CELL_ORDER +
            ". Each view occupies about 60 percent of its own cell width, centroid at the centre "
            "of its cell, " + FRAME + ". " + NEG)


# --------------------------------------------------------------- human ship rework
VANGUARD = hull(
    "Vanguard cutter, human player warship",
    "a broad arrow-head cutter body as the central mass, one large asymmetric weapon mount pod "
    "projecting forward-left and a smaller rail mount forward-right, two engine blocks at the "
    "trailing corners with burnt ember #C8461B flares and small hot ember glow #E8703A halos, "
    "gunmetal mid #3A3F46 and gunmetal dark #2B2F35 plates, steel highlight #565C63 rim on the "
    "shadow-side silhouette, scratches, hull grime and oil stains, light pitted metal on the "
    "older plates, twin trailing engines")
FIGHTER = hull(
    "Fighter, human hostile warship",
    "a short dart-like hull with a visibly tighter length-to-width ratio than a cutter, twin "
    "engines close together at the tail, two small stubby wing pods, gunmetal mid #3A3F46 and "
    "gunmetal dark #2B2F35 plates, steel highlight #565C63 rim, burnt ember #C8461B twin tail "
    "nozzles with small hot ember glow #E8703A halos, scratches, hull grime, oil stains, light "
    "scorch marks and pitted metal on the veteran hostile hull")
CORVETTE = hull(
    "Corvette, human hostile warship",
    "an elongated hull clearly longer and narrower than a fighter, a row of spine ridges along "
    "the dorsal spine with the central hull dominating, gunmetal mid #3A3F46 and gunmetal dark "
    "#2B2F35 plates, steel highlight #565C63 rim, two engines in a single recessed exhaust block "
    "at the tail in burnt ember #C8461B with small hot ember glow #E8703A halos, rust streaks "
    "from rivets and seams, battle damage, scorch marks at the weapon ports, scratches, hull "
    "grime, oil stains")
FREIGHTER = hull(
    "Freighter, human civilian cargo hull",
    "a boxy hull in three visible segmented blocks, bow block, cargo block and engine block, "
    "with clear panel breaks and the widest hull of the roster, minimal appendages, gunmetal mid "
    "#3A3F46 and gunmetal dark #2B2F35 plates, steel highlight #565C63 rim, two engines side by "
    "side in the stern block in burnt ember #C8461B with small hot ember glow #E8703A halos, "
    "hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, "
    "light battle damage on the cargo block")
MINER = hull(
    "Delver mining platform, human player industrial hull",
    "a broad flat slab hull wider than it is long, a ventral cutter bar below the centreline "
    "carrying a row of cutting teeth, a boxed lidded dorsal ore bin above the mid-hull, twin "
    "outboard side engine pods flanking the stern, no weapon mounts and no thorns, gunmetal mid "
    "#3A3F46 and gunmetal dark #2B2F35 plates, steel highlight #565C63 rim, dim civilian burnt "
    "ember #C8461B flares with faint small ember glow #E8703A halos, ore dust staining over the "
    "slab and the bin lid, hull grime toward the trailing edges, oil stains around the engine "
    "pods, rust streaks from the rivet seams, pitted metal on the cutter bar, scratches, light "
    "battle damage on the forward plate only")

# --------------------------------------------------------------- alien hulls
SWARMER = (hull(
    "Swarmer combat drone, alien hostile bioform",
    "a jagged chitin-plate cluster roughly as long as it is wide, insectoid mandible jaws split "
    "open at the bow, segmented chitin plates in corrosive dark #1A281F with chitin green "
    "#3D6E49 mid-tone plate edges, one small hot bioluminescent green #4AE86C energy signature at "
    "the stern thruster and a faint one deep inside the mandible throat, no ember, no orange, no "
    "metal plating, no cockpit glass, no insignia") + " Alien chitin, not a human ship: no "
    "gunmetal, no rivets, no painted panels.")
SIBELON = (hull(
    "Sibelon pod, alien hostile bio-mechanical vessel",
    "a curved bio-mechanical teardrop pod, smooth grown plating over a segmented body with a "
    "cluster of small glowing eye-lenses set into the bow shoulder, stubby vented fins at the "
    "stern, abyssal void #1C1F2B body with deep teal #3A4B6E plate mid-tones, one small hot "
    "corrupted plasma cyan #2BE8E8 energy signature at the stern vent and a dim one in the "
    "eye-cluster, no ember, no orange, no human plating, no insignia") + " Alien bio-mechanical "
    "chitin and grown pod plating, not a human ship: no gunmetal, no rivets, no painted panels.")
APEX = (hull(
    "Apex leviathan, alien apex bioform capital hull",
    "a massive hunched leviathan body whose long tendrils read as part of the outline, tendril "
    "bundle trailing from the stern and two shorter tendril arms framing the bow, thick mutated "
    "tissue over grown plate in warp purple #2B1A28 with mutated violet #6E3A63 plate mid-tones, "
    "one small hot void magenta #E82BE8 energy signature burning in a recessed stern socket and "
    "dim along the tendril roots, no detached wisps, no ember, no orange, no human plating, no "
    "insignia") + " Alien bioform, not a human ship: no gunmetal, no rivets, no painted panels.")

# --------------------------------------------------------------- Phase G FX (FX_SPEC 7.2)
BIO_PLASMA = ("single game FX sprite, one object centred: a pulsing organic plasma orb with a "
              "ragged living outline, trailing a short comet of falling bio-spore motes behind "
              "it, bioluminescent green #4AE86C hot glow over a corrosive dark #1A281F organic "
              "mass, small and hot, isolated on flat void black #0A0E14, nothing else in frame. "
              + NEG_FX)
ACID_BURN = ("single game FX sprite, one object centred: a dissolving puff of bio-acid wisps "
             "drifting upward in a spreading stain, chitin green #3D6E49 body with a few hot "
             "bioluminescent green #4AE86C flecks, matte stain-looking corrosion, not light, "
             "isolated on flat void black #0A0E14, nothing else in frame. " + NEG_FX)
SHIELD_SHATTER = ("a 2x2 animation sheet of a shield shatter burst in four evenly spaced frames, "
                  "generous gaps of flat void black between frames, no grid lines, no labels: "
                  "top-left frame the shards still hold a curved plate shape, top-right frame "
                  "they spread outward, bottom-left frame they scatter as separate shards, "
                  "bottom-right frame empty of shards with only faint dust. Cold pale steel "
                  "highlight #565C63 glass-like shards only, no ember, no orange, no other "
                  "colour, isolated on flat void black #0A0E14. " + NEG_FX)
SMOKE_PLUME = ("single game FX sprite, one object centred: one painterly black smoke puff, a "
               "soft irregular column of soot with soft alpha edges, iron black #232629 core "
               "with gunmetal dark #2B2F35 highlight on the lit side, non-emissive, no glow at "
               "all, isolated on flat void black #0A0E14, nothing else in frame. " + NEG_FX)
ARC_SPARK = ("a 2x2 animation sheet of a jagged electrical arc snapping in four evenly spaced "
             "frames, generous gaps of flat void black between frames, no grid lines, no labels: "
             "each frame a different crooked forked arc between the same two invisible contact "
             "points. The arc is cold pale steel highlight #565C63, thin and hard-edged, pale and "
             "desaturated exactly like brushed steel, and only its very middle carries one small "
             "hot brightened ember core flash; the rest of the arc is never ember, never orange, "
             "never rust-red, and no other glow colour exists anywhere in the frame. Isolated on "
             "flat void black #0A0E14. " + NEG_FX)
DUST_STREAK = ("single game FX sprite, one object centred: one thin horizontal micro streak of "
               "dust, a short soft smear no thicker than a hair with soft fading ends, void haze "
               "#1A2230 fading to nothing at both tips, very low contrast, non-emissive, no glow, "
               "isolated on flat void black #0A0E14, nothing else in frame. " + NEG_FX)
DASH_CHARGE = ("single game FX sprite, one centred ring: a circular charge ring with a burst of "
               "short streaks breaking outward from its rim, burnt ember #C8461B rim with a hot "
               "ember glow #E8703A inner edge, small and hot, an engine charge state, isolated on "
               "flat void black #0A0E14, nothing else in frame, symmetric, seen face-on. " + NEG_FX)
LOCK_CHANNEL = ("single game FX sprite, one centred ring: a thin circular progress arc, a "
                "single clean curved stroke running about three quarters around a circle with a "
                "clearly cut end, even thickness, cold pale steel highlight #565C63 only, no "
                "glow, no ticks, no numbers, isolated on flat void black #0A0E14, nothing else "
                "in frame, seen face-on. " + NEG_FX)

# ------------------------------------------------- the three re-cuts the specs still owe
#
# Owner scoping 2026-09-21 (LOW_BACKLOG L52/L57/L58). Each of these is a gap between a spec row
# and the shipped art, not a new idea:
#
# - `fx_mining_beam_v2`: FX_SPEC 1.6 states a four-frame chip-spark sheet. The shipped master
#   holds three bursts (measured by `staging/cut/split_fx.py`: cells resolve at 29 248 / 12 116 /
#   2 379 / 467 ink px, the fourth under the cell floor), so this run asks for the four the spec
#   describes, in one row of four cells.
# - `fx_laser_bolt_v2`: FX_SPEC 1.1 states light 4:1 and medium 6:1. The shipped objects measure
#   16.4:1 and 9.4:1 (L57's probe: regions 1718x105 and 1680x178 read at world 64 and 96), so the
#   prompt states the two ratios in numbers rather than "elongated" and hopes.
# - `fx_mine`: FX_SPEC has no mine row at all, and the wiring borrows a 423x421 crop of
#   `fx_ember_pulse.png` - a file the spec names for the menu's wreck pulse (L58). A mine is a
#   solid object, so unlike every ember effect it needs alpha to draw at all.
MINING_CHIPS_V2 = ("a one-row four-cell animation sheet of asteroid mining chip sparks, four "
                   "evenly spaced cells across one horizontal strip, generous gaps of flat void "
                   "black between cells, no grid lines, no labels, no border: first cell a small "
                   "angular spark burst radiating from one point, burnt ember #C8461B sparks with "
                   "hot ember glow #E8703A tips; second cell the same sparks flying further "
                   "outward and dimming; third cell the sparks scattered and fading; fourth cell "
                   "only a few nearly extinct sparks left. Small, hard-edged, hot; no beam line, "
                   "no ship, no rock, no second glow colour. Isolated on flat void black #0A0E14. "
                   + NEG_FX)
LASER_BOLT_V2 = ("a one-column two-cell projectile sheet, two energy bolts in two evenly spaced "
                 "cells stacked one above the other, generous gaps of flat void black between "
                 "cells, no grid lines, no labels, no border: the upper cell holds one short thick "
                 "bolt whose length is about four times its own width, and the lower cell holds "
                 "one longer bolt whose length is about six times its own width at a similar "
                 "thickness. Both are horizontal, pointing right, a burnt ember #C8461B hot core "
                 "line inside a soft ember glow #E8703A halo, painterly but hard-edged along the "
                 "core, fat capsule shapes rather than thin scratches, no ship, no muzzle, no "
                 "beam, no streak. Isolated on flat void black #0A0E14. " + NEG_FX)
MINE = ("single game object sprite, one object centred: a small deployable contact mine, a short "
        "riveted drum of iron black #232629 armour with gunmetal dark #2B2F35 banding and a "
        "gunmetal mid #3A3F46 upper cap, four short spiked contact prongs projecting in a cross "
        "from the drum's middle, one small hot burnt ember #C8461B warning lamp on the cap with a "
        "dim ember glow #E8703A pilot light beside it, the armour is non-emissive with only the "
        "lamp glowing, seen face-on, isolated on flat void black #0A0E14, nothing else in frame. "
        + NEG_FX)

## --------------------------------------------------- four-frame cycles for every FX
##
## Owner instruction 2026-09-21: "i want all fx to have at least 4 frames like explosion", so a
## client can animate them. These effects shipped as single textures (tiled/pulsed in the engine);
## each now gets a four-cell sheet whose cells are the phases of its own read, in reading order.
## Cells stay RGB on void black (FX_SPEC section 0.1) except where the master is listed as needing
## alpha, and every sheet is 2x2 so `staging/cut/split_fx.py` cuts it to `_f1.._f4`.
def fx_cycle(subject: str, phases: tuple[str, str, str, str]) -> str:
    return ("a 2x2 animation sheet of " + subject + ", four evenly spaced cells, generous gaps of "
            "flat void black between the cells, no grid lines, no labels, no border: top-left "
            "cell " + phases[0] + "; top-right cell " + phases[1] + "; bottom-left cell "
            + phases[2] + "; bottom-right cell " + phases[3] + ". Each cell holds one object, "
            "the same effect at a later moment, at the same size and place within its cell. "
            "Isolated on flat void black #0A0E14, nothing else in frame, one effect only. " + NEG_FX)


EMBER_GLOW = "burnt ember #C8461B with ember glow #E8703A"
STEEL = "cold pale steel highlight #565C63"
VOID_HAZE = "void haze #1A2230 fading to nothing at the tips"

## (run id, alpha needed, subject with its palette, the four phases)
FX_CYCLES: tuple[tuple[str, bool, str, tuple[str, str, str, str]], ...] = (
    ("fx_acid_burn_v2", True,
     "a dissolving bio-acid stain, chitin green #3D6E49 body with hot bioluminescent green "
     "#4AE86C flecks, matte stain-looking corrosion rather than light",
     ("a small acid puff just starting to dissolve",
      "the acid spreading into a widening stain",
      "the full dissolving stain with hot green flecks at its edges",
      "the stain thinning out into faint wisps")),
    ("fx_smoke_plume_v2", True,
     "one painterly black smoke plume, iron black #232629 core with gunmetal dark #2B2F35 on the "
     "lit side, non-emissive, no glow",
     ("a thin wisp of black soot rising",
      "the wisp swelling into a rounded puff",
      "a full column of dense sooty smoke",
      "the column thinning and breaking up")),
    ("fx_dust_streak_v2", True,
     "one thin horizontal micro streak of dust no thicker than a hair, " + VOID_HAZE
     + ", very low contrast, non-emissive",
     ("one short faint hair-thin dust smear",
      "the smear stretching longer and slightly brighter",
      "a long soft dust streak at its full length",
      "the streak fading away at both ends")),
    ("fx_hull_critical_vignette_v2", True,
     "a full-frame damage vignette, dark " + EMBER_GLOW + " smouldering inward from all four "
     "screen edges with an iron black #232629 smoke texture inside it and a completely empty "
     "centre",
     ("a faint dark ember rim just appearing at the frame edges",
      "the ember rim strengthening all round",
      "heavy smouldering ember edges with the centre still clear",
      "the ember rim dimming back toward the edges")),
    ("fx_anomaly_rift_v2", False,
     "a vertical void rift tear, " + EMBER_GLOW + " rim with crooked ember stress cracks",
     ("a thin vertical ember crack with a hair-thin hot line",
      "the crack opening into a narrow tear with crooked stress cracks",
      "a wide torn rift with a hot ember rim and crooked cracks",
      "the tear closing back to a thin bright line")),
    ("fx_anomaly_shimmer_v2", False,
     "a wide thin cold refraction ring, " + STEEL + " only, hollow centre, a few suspended dull "
     "ore flecks, no warm colour",
     ("a faint cold thin refraction ring",
      "the ring widening and sharpening",
      "a wide hollow steel ring with suspended dull ore flecks",
      "the ring thinning and fading")),
    ("fx_anomaly_grave_glow_v2", False,
     "a pale " + STEEL + " core glow over an unlit deep void blue #111823 haze with pale motes "
     "rising through it, no warm colour",
     ("a small dim steel core glow with a haze of rising motes",
      "the halo widening with more motes rising",
      "a full pale core over a broad halo with dense rising motes",
      "the glow settling and the motes thinning")),
    ("fx_bio_plasma_v2", False,
     "a pulsing organic plasma orb with a ragged living outline, bioluminescent green #4AE86C "
     "hot glow over a corrosive dark #1A281F organic mass",
     ("a small organic green orb just coalescing",
      "the orb pulsing bright with its ragged living outline",
      "the orb at full brightness trailing bio-spore motes",
      "the orb shrinking and dimming")),
    ("fx_cargo_pulse_v2", False,
     "a small compact energy ring pulse, " + EMBER_GLOW,
     ("a tiny ember ring just igniting",
      "the ring expanding with a warm inner glow",
      "a full compact ember ring at its widest",
      "the ring thinning and fading out")),
    ("fx_dash_charge_v2", False,
     "a circular charge ring with short streaks breaking outward from its rim, " + EMBER_GLOW
     + " inner edge, symmetric, face-on",
     ("a charge ring still forming with no streaks yet",
      "short streaks breaking outward from the ring rim",
      "the full charge burst with streaks all round",
      "the ring collapsing and dimming")),
    ("fx_ember_pulse_v2", False,
     "a small round ember orb pulse, " + EMBER_GLOW,
     ("a dim ember orb",
      "the orb swelling brighter",
      "the orb at its hottest with a rounded halo",
      "the orb dimming back down")),
    ("fx_ember_ring_v2", False,
     "a heavy gate ring of dark banded stone with an ember-lit rim, " + EMBER_GLOW
     + " running along the band",
     ("a dim ember gate ring with a dark stone band",
      "the ring's rim lighting up warm ember",
      "the full bright ember ring with a hot inner edge",
      "the ring's glow fading along the band")),
    ("fx_ember_ring_alt_v2", False,
     "a heavy alternate gate ring of banded stone with ember studs on the band, " + EMBER_GLOW,
     ("a dim alternate ember gate ring with a heavy band",
      "the rim brightening with the ember studs lit",
      "the full alternate ring glowing with a hot inner edge",
      "the glow retreating around the band")),
    ("fx_emp_arc_v2", False,
     "a jagged electrical arc discharge, " + STEEL + " arcs with one small hot brightened ember "
     "core flash, the arcs themselves never ember",
     ("one single crooked electrical arc",
      "the arc forking into three branches",
      "a full electrical discharge with arcs all around",
      "the arcs breaking up into dying sparks")),
    ("fx_engine_trail_v2", False,
     "one thin horizontal ember thrust streak, burnt ember #C8461B hot head fading through ember "
     "glow #E8703A to nothing at the tail",
     ("one short bright ember streak",
      "the streak stretching longer",
      "a long ember streak at its full length with a soft tail",
      "the streak fading out along its tail")),
    ("fx_jump_portal_v2", False,
     "a wide ember jump aperture ring, burnt ember #C8461B core with ember glow #E8703A rim, "
     "thin and contained, no field fill",
     ("a narrow vertical ember slit",
      "the slit opening into a small oval aperture",
      "a wide ember jump aperture ring, thin and contained",
      "the aperture narrowing and dimming")),
    ("fx_lock_channel_v2", False,
     "a thin circular progress arc of even thickness with a clearly cut end, " + STEEL
     + " only, seen face-on",
     ("a short cold steel progress arc stub",
      "the arc grown to a quarter circle",
      "the arc three quarters around the circle",
      "the arc closing into a full thin ring")),
    ("fx_mine_v2", True,
     "a small deployable contact mine, a short riveted drum of iron black #232629 armour with "
     "gunmetal dark #2B2F35 banding and four short spiked prongs, one ember warning lamp, "
     "seen face-on",
     ("the mine's warning lamp unlit, armour only",
      "the warning lamp lit with a small hot ember point",
      "the lamp bright with a dim ember pilot glow beside it",
      "the lamp dimming back toward unlit")),
    ("fx_repair_pulse_v2", False,
     "a cold " + STEEL + " maintenance ring with fine engineering sparks along its rim",
     ("a small cold steel maintenance ring",
      "the ring expanding with fine sparks at its rim",
      "a wide steel ring with engineering sparks around it",
      "the ring thinning and fading")),
    ("fx_shield_ripple_v2", False,
     "an expanding shield ripple ring, " + STEEL + " only, thin cold pale rim, faint inner haze, "
     "no ember",
     ("a small cold steel ripple ring",
      "the ring expanding and thinning",
      "a wide thin steel ring with a faint inner haze",
      "the ring fading to a faint cold rim")),
    ("fx_tractor_beam_v2", False,
     "a thin horizontal ember tractor beam line, " + EMBER_GLOW,
     ("a thin ember tractor beam line",
      "the beam pulsing thicker",
      "a full ember beam with small motes drawn along it",
      "the beam flickering thin again")),
    ("fx_laser_bolt_v3", False,
     "two horizontal energy bolt projectiles, burnt ember #C8461B hot core inside a soft ember "
     "glow #E8703A halo, fat capsule shapes, the upper pair about four times as long as wide and "
     "the lower pair about six times",
     ("a short thick light bolt at full brightness",
      "the same light bolt dimming along its tail",
      "a longer medium bolt at full brightness",
      "the medium bolt dimming along its tail")),
)

RUNS: dict[str, dict] = {}

for _id, _subject in (("ship_swarmer_sheet", SWARMER),
                      ("ship_sibelon_sheet", SIBELON),
                      ("ship_apex_sheet", APEX)):
    RUNS[_id] = dict(
        family="ships", source="alien", mode="sheet4", alpha=True,
        hull=_id.split("ship_")[1].split("_sheet")[0], subject=_subject,
        cuts=[f"{_id[:-6]}_{view}" for view in VIEWS], review_only=False,
    )

## The swarmer's sheet, cut by what its cells actually show (2026-09-21): cell 3 is a second
## front view the model drew instead of a rear, so it is dropped and the rear is its own run;
## cell 0 is the front seen bow-down, which is rotated to the bow-up convention of SHIPS_SPEC
## section 4.1. Read off the render, not off the prompt: the sheet came back front (top-left),
## three-quarter (top-right), side (bottom-left), front again (bottom-right).
RUNS["ship_swarmer_sheet"]["cuts"] = ["ship_swarmer_front", "ship_swarmer_three_quarter",
                                      "ship_swarmer_side"]
RUNS["ship_swarmer_sheet"]["cells"] = [
    [0, "ship_swarmer_front", 180],
    [1, "ship_swarmer_three_quarter", 0],
    [2, "ship_swarmer_side", 0],
]
RUNS["ship_swarmer_back_single"] = dict(
    family="ships", source="alien", mode="single", alpha=True, out="ship_swarmer_back",
    subject=("single rear view of the Swarmer combat drone, alien hostile bioform: the ship "
             "seen from directly behind, its stern thruster filling the middle of the silhouette "
             "with one small hot bioluminescent green #4AE86C engine signature, the jagged "
             "chitin-plate cluster splayed outward around it, insectoid mandible tips just "
             "visible past the hull on both sides, segmented plates in corrosive dark #1A281F "
             "with chitin green #3D6E49 plate edges, no ember, no orange, no metal plating, no "
             "insignia. Alien chitin, not a human ship: no gunmetal, no rivets, no painted "
             "panels. Single object centred, bow pointing down, " + FRAME + ". " + NEG),
    review_only=False,
)

for _id, _subject in (("ship_vanguard_sheet", VANGUARD),
                      ("ship_fighter_sheet", FIGHTER),
                      ("ship_corvette_sheet", CORVETTE),
                      ("ship_freighter_sheet", FREIGHTER),
                      ("ship_miner_sheet", MINER)):
    RUNS[_id] = dict(
        family="ships", source="human", mode="sheet4", alpha=True,
        hull=_id.split("ship_")[1].split("_sheet")[0], subject=_subject,
        cuts=[f"{_id[:-6]}_{view}" for view in VIEWS], review_only=True,
    )

## The fighter's sheet: cell 3 came back as a broken fragment (two engine bells and a wing edge,
## no hull), so it is cut as three cells and the rear view comes from its own single run
## (`ship_fighter_back_single`) — the same repair the swarmer sheet needed.
RUNS["ship_fighter_sheet"]["cells"] = [
    [0, "ship_fighter_front", 0],
    [1, "ship_fighter_three_quarter", 0],
    [2, "ship_fighter_side", 0],
]

## Rear views the panels did not deliver. The model's recurring failure is to draw the **front a
## second time** in the bottom-right cell and never a rear; measured by silhouette IoU against the
## front view (`miner` 0.91, `sibelon` 0.83, and the swarmer sheet before it). Those sheets are cut
## as three cells and the rear comes from its own single run, the same repair as the fighter's cell.
RUNS["ship_miner_sheet"]["cells"] = [
    [0, "ship_miner_front", 0],
    [1, "ship_miner_three_quarter", 0],
    [2, "ship_miner_side", 0],
]
RUNS["ship_miner_back_single"] = dict(
    family="ships", source="human", mode="single", alpha=True, out="ship_miner_back",
    subject=("single rear view of the Delver mining platform, human player industrial hull: the "
             "ship seen from directly behind, the broad flat slab foreshortened so its trailing "
             "edge fills the frame, the two twin outboard engine pods flanking the stern with "
             "dim civilian burnt ember #C8461B flares and faint small ember glow #E8703A halos, "
             "the boxed lidded dorsal ore bin seen end-on between them, gunmetal mid #3A3F46 and "
             "gunmetal dark #2B2F35 plates, steel highlight #565C63 rim, ore dust staining, hull "
             "grime, oil stains around the engine pods, rust streaks, pitted metal, scratches. "
             "Single ship centred, bow pointing away from the viewer, " + FRAME + ". " + NEG),
    review_only=True,
)
RUNS["ship_sibelon_sheet"]["cells"] = [
    [0, "ship_sibelon_front", 0],
    [1, "ship_sibelon_three_quarter", 0],
    [2, "ship_sibelon_side", 0],
]
RUNS["ship_sibelon_back_single"] = dict(
    family="ships", source="alien", mode="single", alpha=True, out="ship_sibelon_back",
    subject=("single rear view of the Sibelon pod, alien hostile bio-mechanical vessel: the pod "
             "seen from directly behind, its blunt stern filling the frame with one small hot "
             "corrupted plasma cyan #2BE8E8 vent signature centred in the middle of the rear face "
             "and a dim second one just above it, the curved grown plating and the stubby vented "
             "fins splayed outward around the stern, abyssal void #1C1F2B body with deep teal "
             "#3A4B6E plate mid-tones, no ember, no orange, no human plating, no insignia. Alien "
             "bio-mechanical chitin, not a human ship: no gunmetal, no rivets, no painted panels. "
             "Single object centred, bow pointing away from the viewer, " + FRAME + ". " + NEG),
    review_only=False,
)

## Hull classes 7 to 15 of `ASSET_EXPANSION_SPEC.md` section 3, restored to the same four-view
## standard as the five core hulls. Silhouette, class markers, weathering density and engine count
## are that table's own wording; the palette stays STYLE_BIBLE section 2.
PLATE = ("gunmetal mid #3A3F46 and gunmetal dark #2B2F35 plates, steel highlight #565C63 rim on the "
         "shadow-side silhouette")
EMBER = "burnt ember #C8461B flares with small hot ember glow #E8703A halos"
ROSTER = (
    ("ship_interceptor_sheet",
     ("a narrow needle hull with swept-forward twin prongs at the bow and no spine mass, a single "
      "central engine at the tail, " + PLATE + ", " + EMBER + ", scratches, hull grime, oil "
      "stains, light pitted metal on the older plates")),
    ("ship_gunship_sheet",
     ("a broad short hull with two oversized broadside weapon pods flanking a squat core, twin "
      "recessed nozzles at the tail with " + EMBER + ", " + PLATE + ", heavy battle damage, "
      "scorch-blackened craters, scorch marks at the gun ports, rust streaks, oil stains, hull "
      "grime, pitted metal, scratches")),
    ("ship_destroyer_sheet",
     ("a long wedge hull with a row of dorsal turret blocks along its spine and a flared stern, "
      "four engines in paired stern blocks with " + EMBER + ", " + PLATE + ", the heaviest "
      "weathering of the roster: battle damage, torn plate edges, weld beads over repairs, rust "
      "streaks, scorch marks, pitted metal, scratches")),
    ("ship_drone_swarm_sheet",
     ("a tiny angular shard body with one stubby thruster at the tail and no cockpit, minimal "
      "appendages, " + PLATE + ", one small hot burnt ember #C8461B thruster flare, light "
      "weathering: scratches only")),
    ("ship_trader_sheet",
     ("a boxy segmented hull with external container racks along both flanks, the racks are the "
      "read, two engines side by side at the stern with " + EMBER + ", " + PLATE + ", heavy hull "
      "grime, rust streaks, oil stains, scratches, no battle damage")),
    ("ship_patrol_sheet",
     ("a mid-length hull with a forward lance mount and one dorsal fin, clean plated sides, two "
      "engines at the tail with " + EMBER + ", " + PLATE + ", moderate weathering: scratches, hull "
      "grime, oil stains")),
    ("ship_bomber_sheet",
     ("a fat fuselage with an underslung ordnance bay and two stub wings, the bay is the read, two "
      "engines at the tail with " + EMBER + ", " + PLATE + ", heavy weathering: scorch marks, "
      "battle damage, oil stains, rust streaks, hull grime, scratches")),
    ("ship_mine_layer_sheet",
     ("a blunt bow with a wide flat stern rack carrying visible mine cradles, two engines in the "
      "stern block with " + EMBER + ", " + PLATE + ", heavy weathering: rust streaks, battle "
      "damage, scorch marks, oil stains, hull grime, pitted metal, scratches")),
)
for _id, _detail in ROSTER:
    RUNS[_id] = dict(
        family="ships", source="human", mode="sheet4", alpha=True,
        hull=_id.split("ship_")[1].split("_sheet")[0], subject=hull(
            f"{_id.split('_')[1].replace('_', ' ')} hull, human warship of the Vajb Orbit roster",
            _detail),
        cuts=[f"{_id[:-6]}_{view}" for view in VIEWS], review_only=False,
    )

## Hull 15 is radially symmetric (no bow, no stern), so a rotation sheet would be four pictures of
## the same thing: one centred render, cut like any single.
RUNS["ship_turret_platform_single"] = dict(
    family="ships", source="human", mode="single", alpha=True, out="ship_turret_platform",
    subject=("single turret platform, human hostile static emplacement: a symmetric hexagonal "
             "emplacement with a single long barrel on a pivot ring at its centre, no hull axis, "
             "radially symmetric, " + PLATE + ", heavy pitted metal, scorch marks around the "
             "barrel, battle damage, rust streaks, hull grime, a single small hot burnt ember "
             "#C8461B warning lamp on the ring, no engine plume. Single object centred, seen from "
             "above, " + FRAME + ". " + NEG),
    review_only=False,
)

## Three more of the roster's sheets repeated the front in the bottom-right cell; the duplicate
## check in `refit_panels.py` caught them (`ship_trader_back` 0.91 against its front, `ship_gunship`
## 0.83, `ship_drone_swarm` 0.82). Each gets its own rear run and cuts three cells.
REAR_SINGLES = (
    ("ship_gunship_sheet", "ship_gunship_back", "ship_gunship",
     "single rear view of the gunship, human hostile warship: the broad short hull seen from "
     "directly behind, its two oversized broadside weapon pods flanking the squat core with their "
     "muzzles pointing away, twin recessed nozzles centred at the trailing edge with " + EMBER +
     ", " + PLATE + ", heavy battle damage, scorch-blackened craters, rust streaks, oil stains, "
     "hull grime, pitted metal, scratches"),
    ("ship_drone_swarm_sheet", "ship_drone_swarm_back", "ship_drone_swarm",
     "single rear view of the drone swarm unit, human hostile swarm shard seen from directly "
     "behind: a tiny angular shard body with one stubby thruster centred in the middle of its "
     "trailing face, one small hot burnt ember #C8461B thruster flare, no cockpit, minimal "
     "appendages, " + PLATE + ", light weathering, scratches only"),
    ("ship_trader_sheet", "ship_trader_back", "ship_trader",
     "single rear view of the trader, human civilian hull seen from directly behind: the boxy "
     "segmented hull end-on with its external container racks flanking it on both sides, two "
     "engines side by side centred at the stern with " + EMBER + ", " + PLATE + ", heavy hull "
     "grime, rust streaks, oil stains, scratches, no battle damage"),
)
for _sheet, _out, _hull, _detail in REAR_SINGLES:
    RUNS[_sheet]["cells"] = [[0, f"{_hull}_front", 0], [1, f"{_hull}_three_quarter", 0],
                             [2, f"{_hull}_side", 0]]
    RUNS[f"{_out}_single"] = dict(
        family="ships", source="human", mode="single", alpha=True, out=_out,
        subject=(f"{_detail}. Single ship centred, bow pointing away from the viewer, "
                 + FRAME + ". " + NEG),
        review_only=False,
    )

RUNS["ship_fighter_back_single"] = dict(
    family="ships", source="human", mode="single", alpha=True, out="ship_fighter_back",
    subject=("single rear view of the Fighter, human hostile warship: the ship seen from directly "
             "behind, its two tail engine nozzles side by side at the middle of the silhouette "
             "with hot burnt ember #C8461B flares and small ember glow #E8703A halos, the short "
             "dart hull and its two stubby wing pods splayed out around them, gunmetal mid #3A3F46 "
             "and gunmetal dark #2B2F35 plates, steel highlight #565C63 rim, scratches, hull "
             "grime, oil stains, light scorch marks and pitted metal on the veteran hostile hull. "
             "Single ship centred, bow pointing away from the viewer, " + FRAME + ". " + NEG),
    review_only=True,
)

for _id, _subject, _source, _mode in (
    ("fx_bio_plasma", BIO_PLASMA, "alien", "fx"),
    ("fx_acid_burn", ACID_BURN, "alien", "fx"),
    ("fx_shield_shatter", SHIELD_SHATTER, "human", "fx_sheet"),
    ("fx_smoke_plume", SMOKE_PLUME, "human", "fx"),
    ("fx_arc_spark", ARC_SPARK, "human", "fx_sheet"),
    ("fx_dust_streak", DUST_STREAK, "human", "fx"),
    ("fx_dash_charge", DASH_CHARGE, "human", "fx"),
    ("fx_lock_channel", LOCK_CHANNEL, "human", "fx"),
):
    RUNS[_id] = dict(family="fx", source=_source, mode=_mode, alpha=False,
                     out=_id, subject=_subject, review_only=False)

## The 2026-09-21 re-cuts. The two sheets stay RGB on void black (they are additive, FX_SPEC
## section 0.1); the mine is a `single` with alpha, so it needs `key_new.py` before it can be
## cut, exactly like a hull.
RUNS["fx_mining_beam_v2"] = dict(family="fx", source="human", mode="fx_sheet", alpha=False,
                                 out="fx_mining_beam_v2", subject=MINING_CHIPS_V2,
                                 review_only=False)
RUNS["fx_laser_bolt_v2"] = dict(family="fx", source="human", mode="fx_sheet", alpha=False,
                                out="fx_laser_bolt_v2", subject=LASER_BOLT_V2,
                                review_only=False)
RUNS["fx_mine"] = dict(family="fx", source="human", mode="single", alpha=False,
                       out="fx_mine", subject=MINE, review_only=False)

## The four-frame cycles (owner instruction 2026-09-21). They land as `_v2` renders and cut to
## the shipped `_f1.._f4` names, so a client animates the effect without a rename.
for _id, _needs_key, _subject, _phases in FX_CYCLES:
    RUNS[_id] = dict(family="fx", source="human", mode="fx_sheet", alpha=False, out=_id,
                     subject=fx_cycle(_subject, _phases), review_only=False,
                     needs_key=_needs_key)

## Retired before shipping: the owner ruled (2026-09-21) that this four-frame sheet duplicates the
## shipped `fx_shield_break.png`, which FX_SPEC section 7.1 already names as the asset for the
## shield-shatter event. The render stays in `staging/phase_g/fx/` as provenance; `ships=False`
## keeps `ship_batch_g.py` from copying it.
RUNS["fx_shield_shatter"]["ships"] = False

## ---------------------------------------------- D6 cockpit instruments (UI_CHROME section 11)
## Wave D6, `docs/design/UI_CHROME_ASSETS_SPEC.md` section 11. Four panel renders, one family per
## panel, on the plain solid pure white background the chrome law requires (section 1.2). The
## framing sentence is section 11's own constant, verbatim; the per-run subjects are section 11's
## verbatim prompts; the negative list is section 8's. The style block is passed verbatim as the
## prompt preamble by `run_one`, exactly as every other Phase G run does.
##
## The masters are one render per panel and the cuts ship at 2x their logical box (section 11's
## table, the D2 ruling: no `@2x` files, no size-variant families). `cells` is the authority on the
## cell count and the names; the grid is read off the render with `panels.py --detect` before the
## cut (a 3x2 panel is not caught by the old quadrant grouping).
UI_FRAME = ("painted UI instrument part, straight-on flat view, centred, "
            "plain solid pure white background")
UI_NEG = "no stars, no ships, no wrecks, no ember glow, no logos, no text"


def ui_prompt(subject: str) -> str:
    return f"{UI_FRAME}: {subject}. {UI_NEG}"


UI_INSTRUMENTS = ui_prompt(
    "cockpit instrument parts on white, arranged with wide gaps: a round aircraft-style speed "
    "dial face with a recessed dark centre and a 270-degree arc of ten metal tick marks; a slim "
    "metal needle; a round compass rose disc with engraved tick rings and four small diamond "
    "cardinal marks; a small metal pointer triangle")
UI_FRAME_GLASS = ui_prompt(
    "a rectangular instrument bezel frame with a thick bevelled metal border, empty dark interior, "
    "nine-patch proportions; a soft dark rectangular glass readout plate with faint inner glow "
    "along its top edge")
UI_SEVENSEG_A = ui_prompt(
    "six rectangular digital seven-segment display cells on white, wide gaps, showing digits "
    "0 1 2 3 4 5 in glowing bone-white segments with the unlit segments dark grey, each digit in "
    "its own cell, flat straight-on")
UI_SEVENSEG_B = ui_prompt(
    "six rectangular digital seven-segment display cells on white, wide gaps: digits 6 7 8 9, then "
    "a percent sign made of seven-segment style strokes, then an empty cell showing only the dim "
    "unlit segment outline")

## Section 11's table, logical box -> master box (the master is the shipped file).
UI_LOGICAL = {
    "ui_cockpit_frame": (96, 96),
    "ui_gauge_face": (120, 120),
    "ui_gauge_needle": (8, 96),
    "ui_compass_rose": (96, 96),
    "ui_compass_lubber": (16, 12),
    "ui_readout_glass": (136, 190),
}
UI_MASTER = {
    "ui_cockpit_frame": (192, 192),
    "ui_gauge_face": (240, 240),
    "ui_gauge_needle": (16, 192),
    "ui_compass_rose": (192, 192),
    "ui_compass_lubber": (32, 24),
    "ui_readout_glass": (272, 380),
}
for _i in range(10):
    UI_LOGICAL[f"ui_seg_{_i}"] = (20, 36)
    UI_MASTER[f"ui_seg_{_i}"] = (48, 88)
for _cell in ("ui_seg_pct", "ui_seg_blank"):
    UI_LOGICAL[_cell] = (20, 36)
    UI_MASTER[_cell] = (48, 88)

RUNS["panel_instruments"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_instruments",
    subject=UI_INSTRUMENTS, cells=[[0, "ui_gauge_face", 0], [1, "ui_compass_rose", 0],
                                   [3, "ui_compass_lubber", 0]],
    grid=[2, 2], boxes=UI_MASTER, logical=UI_LOGICAL, panel_name="panel_instruments",
    dup_check=True, review_only=False,
)
## Three renders of the instrument panel (2026-09-24, tasks fcadff98, f72d6e47, 001cb6bb) each
## came back with the same three objects and the needle painted ONTO the dial face instead of beside
## it: `panels.py --detect` finds the face (which carries a needle, against section 11's "no
## needle"), the rose and the lubber triangle, and never a fourth object. The face, rose and lubber
## are cut from the render; `ui_gauge_needle` is recovered from the painted needle by
## `gauge_split.py` (extract it, then inpaint it out of the face), and `ui_cockpit_frame`'s missing
## glass half is authored by `frame_glass_ui.py`. Both repairs are reported in the D6-M0 report.
RUNS["panel_frame_glass"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_frame_glass",
    subject=UI_FRAME_GLASS, cells=[[0, "ui_cockpit_frame", 0]],
    grid=[2, 1], boxes=UI_MASTER, logical=UI_LOGICAL, panel_name="panel_frame_glass",
    dup_check=False, review_only=False,
)
## The two digit panels came back as one row of six, not the 3x2 the panel paragraph describes
## (2026-09-24, `panels.py --detect`: six objects on a single horizontal band). The arrangement is
## read off the render (AGENTS.md Phase G lane) while the cell count and the names come from
## section 11, so the grid is 6x1 here and the 3x2 wording is reported as a doc/render mismatch.
RUNS["panel_sevenseg_a"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_sevenseg_a",
    subject=UI_SEVENSEG_A,
    cells=[[i, f"ui_seg_{i}", 0] for i in range(6)],
    grid=[6, 1], boxes=UI_MASTER, logical=UI_LOGICAL, panel_name="panel_sevenseg_a",
    dup_check=False, review_only=False,
)
RUNS["panel_sevenseg_b"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_sevenseg_b",
    subject=UI_SEVENSEG_B,
    cells=[[0, "ui_seg_6", 0], [1, "ui_seg_7", 0], [2, "ui_seg_8", 0], [3, "ui_seg_9", 0],
           [4, "ui_seg_pct", 0], [5, "ui_seg_blank", 0]],
    grid=[6, 1], boxes=UI_MASTER, logical=UI_LOGICAL, panel_name="panel_sevenseg_b",
    dup_check=False, review_only=False,
)

## ------------------------------------- D7 cockpit panel family (UI_CHROME_ASSETS_SPEC section 12)
## Wave D7, `docs/design/UI_CHROME_ASSETS_SPEC.md` section 12. Five renders on the chrome law's
## plain solid pure white background; the framing sentence is D7's own U_FRAME constant (the same
## wording section 11 used), the per-run subjects are section 12's verbatim prompts, the negative
## list is section 8's, and the style block is the prompt preamble (section 12's explicit route,
## "the section 11 route: prompt preamble, not --style-file"). `flare` returns opaque on white
## here, so every object is cut on its own box and keyed on its own (`refit_panels.py`); a panel
## is never keyed whole (Phase G lane law).
##
## The armory boxes are the measured ones, not invented ones. `staging/d7/measure_armory.gd`
## instantiates `res://ui/station/armory_panel.tscn` headlessly and reads the pane's own rects:
## the pane's content frame is 872x908 (mockup A's frame, `staging/mockup/mockup_rest.py`), the
## racks well min 420x255, the racks caption band 122x23, the ammo rows 870x76 on ROW_HEIGHT 76.
## `ui_armory_console` rides the pane's own content rect (872x908 -> 1744x1816 at 2x);
## `ui_armory_rack_plate` rides section 3.10's approved bay 97x91 -> 194x182 at 2x;
## `ui_armory_row_plate` rides section 3.10's approved ammunition row height 32 -> 64 at 2x.
UI_D7_FRAME = ("painted UI instrument part, straight-on flat view, centred, "
               "plain solid pure white background")


def ui_d7_prompt(subject: str) -> str:
    return f"{UI_D7_FRAME}: {subject}. {UI_NEG}"


UI_D7_COCKPIT = ui_d7_prompt(
    "a wide rectangular painted metal instrument panel face for a spaceship cockpit: brushed "
    "steel plates with visible brush grain, bolt heads at the corners and along the seams, one "
    "large recessed circular instrument well on the left, one smaller circular well in the "
    "middle, and a tall recessed rectangular well on the right with five shallow machined "
    "ledges across it; dark painted void interior in each recess; no glass, no screens, no "
    "glowing")
UI_D7_GAUGE = ui_d7_prompt(
    "a round aircraft-style speed dial face on a painted metal bezel, recessed dark centre, an "
    "arc of eight graduated metal speed ticks growing longer toward the top of the arc, no "
    "numbers, no needle, no compass marks")
UI_D7_ARMORY_CONSOLE = ui_d7_prompt(
    "a tall rectangular painted metal console face: brushed steel plate with bolt heads, three "
    "stacked recessed wells with bevelled rims, the top well long and shallow with seven short "
    "machined slot recesses along it, the lower two wells plain and deep; dark void interior in "
    "the recesses; no glass, no screens")
UI_D7_ARMORY_PLATES = ui_d7_prompt(
    "two painted metal plates on white with wide gaps: a small bolted bay plate with four "
    "shallow machined slot recesses in a row and a thin engraved ledge along its bottom edge; a "
    "plain brushed metal row strip with softly bevelled long edges and two bolt heads at the "
    "left end")
UI_D7_STATUS = ui_d7_prompt(
    "a rectangular painted metal console face for a ship-status readout: brushed steel plate "
    "with bolt heads, one large recessed display well on the left with a bevelled rim, fifteen "
    "shallow machined slot recesses on the right in three rows of five, and a thin recessed "
    "strip along the bottom; dark void interior in the recesses; no glass, no screens")

## Section 12's own numbers: the master box is what ships. Section 3.7's D7 amendment pins
## 928x512 for the 464x256 cluster box; section 3.8's pins 1440x1040 for the 720x520 modal;
## section 3.10's pins the armory bay 194x182 and the row-plate band (ammunition rows 32 tall).
UI_D7_LOGICAL = {
    "ui_cockpit_panel": (464, 256),
    "ui_gauge_face": (120, 120),
    "ui_armory_console": (872, 908),
    "ui_armory_rack_plate": (97, 91),
    "ui_armory_row_plate": (96, 32),
    "ui_status_panel": (720, 520),
}
UI_D7_MASTER = {
    "ui_cockpit_panel": (928, 512),
    "ui_gauge_face": (240, 240),
    "ui_armory_console": (1744, 1816),
    "ui_armory_rack_plate": (194, 182),
    "ui_armory_row_plate": (192, 64),
    "ui_status_panel": (1440, 1040),
}

RUNS["panel_cockpit"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_cockpit",
    subject=UI_D7_COCKPIT, cells=[[0, "ui_cockpit_panel", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_cockpit",
    dup_check=False, review_only=False,
)
RUNS["panel_gauge"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_gauge",
    subject=UI_D7_GAUGE, cells=[[0, "ui_gauge_face", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_gauge",
    dup_check=False, review_only=False,
)
RUNS["panel_armory_console"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_armory_console",
    subject=UI_D7_ARMORY_CONSOLE, cells=[[0, "ui_armory_console", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_armory_console",
    dup_check=False, review_only=False,
)
RUNS["panel_armory_plates"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_armory_plates",
    subject=UI_D7_ARMORY_PLATES,
    cells=[[0, "ui_armory_rack_plate", 0], [1, "ui_armory_row_plate", 0]],
    ## The arrangement is read off the render (Phase G lane): `panels.py --detect` finds the bay
    ## plate above the row strip, so the grid is 1x2, not the side-by-side 2x1 a two-plate prompt
    ## suggests. `cells` below stays the authority on the count and the names.
    grid=[1, 2], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_armory_plates",
    dup_check=False, review_only=False,
)
RUNS["panel_status"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_status",
    subject=UI_D7_STATUS, cells=[[0, "ui_status_panel", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_status",
    dup_check=False, review_only=False,
)

## ---------------------- D7-A1 flat-plate re-render (UI_CHROME_ASSETS_SPEC section 12 Amendment 2)
## Amendment 2 (2026-09-24): the three console panels are **flat painted plates** - "their per-run
## prompts above drop every `recessed well` phrase". Cause, measured: A0's baked wells landed wrong
## on 4 of 6 masters (`D7-A0_report.md`, worst `recess_ratio` 1.403) and the Mockup v7 layout moved
## the bays after the renders. Wells are code-drawn recesses at the pinned rects (UI_SPEC section
## 3.7's mockup blocks), so layout/styling changes never invalidate art; bolt heads, plate seams and
## brush grain stay in the art. The well-registration QC rows retire for these three
## (`qc_d7.py`); containment/box checks stay.
##
## The subjects below are section 12's own per-run prompts with every well/recess/slot clause
## dropped and the flatness stated outright, so a model cannot read a recess back in. The master
## boxes are section 12's pinned ones (the armory box is A0's measured 2x content rect 1744x1816,
## `staging/d7/measure_armory.gd`). `ui_gauge_face`, `ui_armory_rack_plate` and
## `ui_armory_row_plate` are A0's bytes and are not re-rendered here.
## The outline proportion in each subject is the pinned master box's own aspect (cockpit 928/512 =
## 1.81, console 1744/1816 = 0.96, status 1440/1040 = 1.38): with the well clauses dropped the
## prompt no longer fixes the plate's internal layout, so without the proportion the model composes
## its own outline and `contain` letterboxes it (measured on pass 1: the console came back 0.51
## aspect and could only fill 49 percent of its pinned box's width - the code-drawn wells at the
## pinned rects would have landed off the plate). Reversal: drop the clause and accept the
## letterbox, or move the fit from `contain` to `fill`/`cover` (both change a pinned number).
UI_D7_COCKPIT_FLAT = ui_d7_prompt(
    "a wide rectangular painted metal instrument panel face for a spaceship cockpit, plain flat, "
    "its outline about 1.8 times as wide as it is tall with a clear white margin all around: "
    "brushed steel plates with visible brush grain and flat plate seams between the plates, bolt "
    "heads at the corners and along the seams, a continuous flat steel surface carrying no "
    "openings, no wells, no recesses and no machined slots; no glass, no screens, no glowing")
UI_D7_ARMORY_CONSOLE_FLAT = ui_d7_prompt(
    "a rectangular painted metal console face, plain flat, the plate filling the frame up to a "
    "narrow plain white border all around, its outline nearly square, about as wide as it is "
    "tall: brushed steel plate with visible brush grain and flat plate seams between the steel "
    "plates, bolt heads at the four corners and along the seams, a continuous flat steel surface "
    "carrying no openings, no wells, no recesses and no machined slots; no glass, no screens")
UI_D7_STATUS_FLAT = ui_d7_prompt(
    "a rectangular painted metal console face, plain flat, the plate filling the frame up to a "
    "narrow plain white border all around, its outline matching the frame's own proportions of "
    "about 4 to 3, wider than it is tall: brushed steel plate with visible brush grain and flat "
    "plate seams between the plates, bolt heads at the four corners and along the seams, a "
    "continuous flat steel surface carrying no openings, no wells, no recesses and no machined "
    "slots; no glass, no screens")

RUNS["panel_cockpit_flat"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_cockpit_flat",
    subject=UI_D7_COCKPIT_FLAT, cells=[[0, "ui_cockpit_panel", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_cockpit_flat",
    dup_check=False, review_only=False,
    ## A flat plate carries no wells, so the plate itself is the surface the pinned box mounts: the
    ## lane's 4 % trim pad would eat 8 % of the box's own size and push the code-drawn wells off the
    ## art (measured: the cockpit's well union sits from 10 % to 86 % of the box's height). 0.0 is
    ## floored at 8 px by `trim_centre`. Reversal: drop the key and accept the letterbox.
    pad_share=0.0,
)
RUNS["panel_armory_console_flat"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_armory_console_flat",
    subject=UI_D7_ARMORY_CONSOLE_FLAT, cells=[[0, "ui_armory_console", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL,
    panel_name="panel_armory_console_flat", dup_check=False, review_only=False,
    ## The canvas aspect is the pinned master box's own (0.96 -> the nearest supported 1:1). The
    ## model's plate outline follows the canvas more than the wording (measured: at 1:1 the console
    ## came back 0.81 with the proportion clause alone, against 0.51 without it), and the shipped
    ## fit is pinned to `contain`, so a canvas at the box's aspect is the only lever that fills the
    ## box without a pinned number moving. Reversal: drop the key and accept the letterbox.
    aspect="1:1",
    pad_share=0.0,
)
RUNS["panel_status_flat"] = dict(
    family="ui", source="human", mode="panel", alpha=False, out="panel_status_flat",
    subject=UI_D7_STATUS_FLAT, cells=[[0, "ui_status_panel", 0]],
    grid=[1, 1], boxes=UI_D7_MASTER, logical=UI_D7_LOGICAL, panel_name="panel_status_flat",
    dup_check=False, review_only=False,
    ## Box aspect 1.385 -> the nearest supported canvas is 4:3 (1.333). See the console's note.
    aspect="4:3",
    pad_share=0.0,
)

## `cells` is the authority on what a sheet produces: a repaired sheet cuts three cells, not four.
## Deriving `cuts` from it stops a stale four-name list from planning one file twice (the sibelon
## and miner sheets each still declared `back` after their cell plan stopped cutting one).
for _spec in RUNS.values():
    if _spec.get("cells"):
        _spec["cuts"] = [name for _index, name, _rotate in _spec["cells"]]


def log_run(family: str, markdown: str) -> None:
    log_path = STAGE / family / "generation_log_phase_g.md"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if not log_path.exists():
        log_path.write_text(
            "# Phase G - generation log\n\n"
            "Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, aspect 1:1.\n"
            "Work order: `.agents/gen/dispatch_designer.md`. Style law: `docs/design/STYLE_BIBLE.md` "
            "section 9 (human block, `vajb-orbit/assets/style-block.txt`) and section 9.1 (alien "
            "addendum, `vajb-orbit/assets/style-block-alien.txt`), both passed verbatim as the "
            "prompt preamble. Alien palettes: STYLE_BIBLE section 2.5. FX inventory: "
            "`docs/design/FX_SPEC.md` section 7.2.\n"
            "Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the "
            "script's printed estimate is the stale hint.\n"
            "Alpha: `--transparent` native first; an opaque render is keyed by "
            "`staging/phase_g/key_new.py` through recraft/remove-background (the 2026-09-20 route). "
            "FX stay RGB on void black for additive blending and are never keyed "
            "(FX_SPEC sections 0 and 0.1).\n"
            "AI-generated art is not CC0 (AGENTS.md).\n\n---\n\n",
            encoding="utf-8")
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(markdown)
        fh.write("\n---\n\n")


def has_alpha(path: Path, share: float = 0.10) -> bool:
    img = Image.open(path)
    if img.mode not in ("RGBA", "LA"):
        return False
    alpha = np.asarray(img.convert("RGBA").getchannel("A"))
    return float((alpha == 0).mean()) > share


def find_master(spec: dict) -> Path | None:
    """Newest run folder whose stored prompt is this spec's subject, exactly."""
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


def grid_cells(source: Path, cols: int, rows: int) -> list[Image.Image]:
    img = Image.open(source).convert("RGBA")
    width, height = img.size
    return [img.crop((c * width // cols, r * height // rows,
                      (c + 1) * width // cols, (r + 1) * height // rows))
            for r in range(rows) for c in range(cols)]


def keep_main(img: Image.Image, floor: float = 0.10) -> Image.Image:
    """Drop stray fragments: a cell boundary can carry a sliver of its neighbour's tail, and a
    sliver left in place survives the trim and ships as if it were part of the hull."""
    from scipy import ndimage
    alpha = np.asarray(img.getchannel("A"))
    labels, count = ndimage.label(alpha > 8)
    if count <= 1:
        return img
    sizes = ndimage.sum(alpha > 8, labels, range(1, count + 1))
    biggest = float(sizes.max())
    keep = {index + 1 for index, size in enumerate(sizes) if size >= biggest * floor}
    mask = np.isin(labels, list(keep))
    out = img.copy()
    out.putalpha(Image.fromarray(np.where(mask, alpha, 0).astype(np.uint8)))
    return out


def trim_centre(img: Image.Image, pad_share: float = 0.04) -> Image.Image:
    """Trim to the alpha bounding box and re-pad evenly, so the object sits at the canvas centre.

    The pad is proportional, not a square canvas: the shipped ship set is trimmed tight to the
    hull (a corvette side view is a long thin strip, not a sliver in a 2K square), and the game
    draws these centred on a Node2D, which a square canvas would only pad with dead pixels.
    """
    img = keep_main(img)
    alpha = np.asarray(img.getchannel("A"))
    rows = np.where(alpha.max(axis=1) > 8)[0]
    cols = np.where(alpha.max(axis=0) > 8)[0]
    if len(rows) and len(cols):
        img = img.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))
    pad = max(8, int(round(pad_share * max(img.size))))
    canvas = Image.new("RGBA", (img.size[0] + 2 * pad, img.size[1] + 2 * pad), (0, 0, 0, 0))
    canvas.paste(img, (pad, pad))
    return canvas


def run_one(run_id: str, dry: bool = False, post_only: bool = False) -> bool:
    spec = RUNS[run_id]
    family_dir = STAGE / spec["family"]
    family_dir.mkdir(parents=True, exist_ok=True)
    mode = spec["mode"]
    style = STYLE_ALIEN if spec["source"] == "alien" else STYLE_HUMAN

    cmd = [PY, str(SKILL), "--model", "flare", "--aspect", spec.get("aspect", "1:1"),
           "--resolution", "2K", "--out", str(family_dir)]
    ## STYLE_BIBLE section 8: the block goes FIRST, so it goes in as the prompt preamble;
    ## --style-file would append it after the subject.
    prompt = style.read_text(encoding="utf-8").strip() + "\n\n" + spec["subject"]
    cmd += ["--prompt", prompt]
    if spec["alpha"]:
        cmd.append("--transparent")

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
        if CA_BUNDLE.is_file():
            env["SSL_CERT_FILE"] = str(CA_BUNDLE)
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                              errors="replace", env=env)
        if proc.returncode != 0:
            print(f"[{run_id}] FAILED rc={proc.returncode}\n{proc.stdout}\n{proc.stderr}", flush=True)
            return False
        payload = json.loads(proc.stdout)
        master = Path(payload["alpha_paths"][0] if payload.get("alpha_paths")
                      else payload["local_paths"][0])
        task_id, elapsed = payload.get("task_id", "?"), payload.get("elapsed_s", "?")
        print(f"[{run_id}] ok task={task_id} {elapsed}s master={master}", flush=True)

    notes: list[str] = []
    finals: list[Path] = []

    if mode == "fx":
        dest = family_dir / f"{spec['out']}.png"
        Image.open(master).convert("RGB").save(dest)
        notes.append("RGB on void black, never alpha-keyed (FX_SPEC 0.1)")
        finals.append(dest)
    elif mode == "fx_sheet":
        dest = family_dir / f"{spec['out']}.png"
        Image.open(master).convert("RGB").save(dest)
        notes.append("4-frame 2x2 sheet, RGB on void black, never alpha-keyed (FX_SPEC 0.1)")
        finals.append(dest)
    elif mode == "sheet4":
        ## `key_new.py` writes `<stem>-keyed.png` beside the render; prefer it over the raw master.
        source = master.with_name(f"{master.stem}-keyed.png")
        if not source.exists():
            source = master
        if not has_alpha(source):
            notes.append("OPAQUE: needs `key_new.py` before it can be cut")
            print(f"[{run_id}] opaque render, no alpha - key it, then re-run with --post-only",
                  flush=True)
            return False
        notes.append("native alpha" if source == master else f"recraft matte ({source.name})")
        cells = grid_cells(source, 2, 2)
        plan = spec.get("cells") or [[i, name, 0] for i, name in enumerate(spec["cuts"])]
        for index, name, rotate in plan:
            cell = cells[index]
            if rotate:
                cell = cell.rotate(rotate, expand=True)
            dest = family_dir / f"{name}.png"
            trim_centre(cell).save(dest)
            finals.append(dest)
    elif mode == "single":
        source = master.with_name(f"{master.stem}-keyed.png")
        if not source.exists():
            source = master
        if not has_alpha(source):
            notes.append("OPAQUE: needs `key_new.py` before it can be cut")
            print(f"[{run_id}] opaque render, no alpha - key it, then re-run with --post-only",
                  flush=True)
            return False
        notes.append("native alpha" if source == master else f"recraft matte ({source.name})")
        dest = family_dir / f"{spec['out']}.png"
        trim_centre(Image.open(source).convert("RGBA")).save(dest)
        finals.append(dest)
    elif mode == "panel":
        ## A multi-object panel is never keyed and never cut on a blind grid: the render is stored
        ## whole (opaque, the white backdrop the chrome law asks for) and `refit_panels.py` runs the
        ## order that is law - `panels.py` finds each object, cuts its own box, keys that cut on its
        ## own, trims and centres it. `final` here is the provenance panel.
        dest = family_dir / f"{spec['out']}.png"
        Image.open(master).convert("RGB").save(dest)
        notes.append("opaque panel on white; objects cut and keyed one at a time by refit_panels.py")
        finals.append(dest)
    else:
        raise SystemExit(f"unknown mode {mode}")

    job_src = Path(master).parent / "job.json"
    if job_src.exists():
        for path in finals:
            if path.suffix == ".png":
                (family_dir / f"{path.stem}.job.json").write_text(
                    job_src.read_text(encoding="utf-8"), encoding="utf-8")

    for path in finals:
        img = Image.open(path)
        print(f"[{run_id}] final {path.name} {img.size} {img.mode}", flush=True)

    log_run(spec["family"], (
        f"## {run_id}\n\n"
        f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
        f"- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1\n"
        f"- Job id: `{task_id}` (elapsed {elapsed}s)\n"
        f"- Style: `{style.name}` verbatim as the prompt preamble (STYLE_BIBLE section 8)\n"
        f"- Alpha: {', '.join(notes)}; run folder `{Path(master).parent.name}` keeps `job.json`\n"
        f"- Review-only: {spec['review_only']}\n"
        f"- Final files: {', '.join(p.name for p in finals)}\n"
        f"- Status: success\n\n"
        f"Full prompt:\n\n> {spec['subject']}\n"))
    return True


if __name__ == "__main__":
    args = sys.argv[1:]
    dry = "--dry-run" in args
    post_only = "--post-only" in args
    args = [a for a in args if not a.startswith("--")]
    if not args or "--list" in sys.argv:
        for key, spec in RUNS.items():
            print(f"{key:24s} {spec['family']:6s} {spec['source']:6s} {spec['mode']:9s} "
                  f"{'retired      ' if spec.get('ships') is False else ('review-only  ' if spec['review_only'] else 'ship-to-game ')}"
                  f"{', '.join(spec.get('cuts', [])) or spec.get('out', '')}")
        sys.exit(0)
    ## Every run is attempted even when an earlier one comes back opaque: an opaque render is a
    ## normal stop on the alpha route (key it, then --post-only), never a reason to skip the rest.
    results = [run_one(run_id, dry=dry, post_only=post_only) for run_id in args]
    sys.exit(0 if all(results) else 1)
