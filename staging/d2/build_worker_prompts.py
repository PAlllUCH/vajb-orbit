#!/usr/bin/env python3
"""Build the D2 Phase B worker prompt files (mimo-v2.6-flash SVG authoring).

Owner amendment 2026-09-22: SVGs are designed on a 96 grid (viewBox 0 0 96 96)
with richer interior detail than the original 48-grid source rule, and each
worker authors at most ~10 icons.
"""

import csv
import json
import os

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
OUT = os.path.join(WORKSPACE, "staging/d2/prompts")

EMBER_OK = {
    "icon_ammo", "icon_weapon_cannon", "icon_weapon_laser", "icon_weapon_mine",
    "icon_weapon_plasma", "icon_weapon_rocket", "icon_alt_missile_crosshair",
    "icon_alt_crosshair_target_reticle", "icon_alt_flame_emblem",
    "icon_alt_thruster_exhaust",
}

SPEC_SHAPES = {
    "icon_slot_engine": "a single nozzle block",
    "icon_slot_power": "a reactor core with three coil bars",
    "icon_slot_w": "a hardpoint mount with two clamp jaws",
    "icon_slot_s": "an arc emitter half-ring",
    "icon_slot_h": "a three-layer plate stack",
    "icon_slot_c": "a square board with a central node",
    "icon_slot_b": "a chevron burst vent",
    "icon_slot_u": "an open pod socket with a latch bracket",
    "icon_contract_haul": "a crate on a two-wheel pallet bar",
    "icon_contract_hunt": "a crosshair over a target chevron",
    "icon_contract_gather": "a claw over a faceted chunk",
    "icon_contract_escort": "two chevrons travelling in column with a bracket",
    "icon_contract_expedition": "a ring with a single outward arrow",
    "icon_service_vault": "a door slab with a three-spoke wheel",
    "icon_service_insurance": "a shield plate with a horizontal seam and one rivet notch",
    "icon_service_bounty": "a coin outline struck through by a notched band",
}

RULES = """\
You are hand-authoring flat SVG icon masters for the grimdark sci-fi game Vajb Orbit.
This is careful, detailed icon work - take the time to design each glyph properly.
Write EXACTLY the files listed below, at the exact paths given, and nothing else.
No reports, no README, no extra files, no changes to existing files.

HARD RULES - a validator rejects any violation:
1. Root element exactly: <svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
2. Fills only. Never use stroke. No gradients, no filters, no text, no embedded
   images, no opacity below 1. Solid flat colours only.
3. Shapes: path, rect, circle, ellipse, polygon. A wrapper like <g fill="...">
   is fine. Use fill-rule="evenodd" for holes and cutouts.
4. Colours: at most TWO distinct colours per file, only from this set:
   #C9CDD2 (default body), #8D939B, #565C63, #3A3F46, #2B2F35, #232629.
   In EMBER OK files only, ONE ember tone #C8461B or #E8703A is allowed as the
   second colour. Never invent another colour.
5. The 96 grid: 1 unit = 1 px at the 96 px render. Use integer or .5
   coordinates within the 0..96 canvas. DETAIL LEVEL: 8 to 14 flat shapes per
   icon - a bold outer silhouette plus layered interior plates, seams, bolts or
   marks. The style reference is the SIMPLICITY FLOOR, not the ceiling: go
   clearly more detailed than it. Keep the outer silhouette thick enough to read
   at 16 px (identity-carrying features at least 5 units); interior detail may
   go down to 2 units. Symmetric subjects use mirrored coordinates.
6. Style reference file: staging/d2/style_ref_rocket.svg - same construction
   style (flat fills, evenodd cutouts, hard industrial geometry), but on the 96
   grid and more detailed. The listed master PNG shows the current artwork:
   take the SUBJECT and the silhouette and design a crisp flat symbol from it -
   never trace pixel noise, texture or shading.

FILES - one line per output: path | subject | detail | shape note | master PNG
"""

# (batch key, id list, note)
BATCHES = [
    ("A01", list(range(1, 9)),
     "Slot glyphs. These depict slot SOCKETS, not module art, and NO letterform "
     "is ever baked into a glyph. Hard industrial geometry, one visual family."),
    ("A02", list(range(9, 17)),
     "Contract and service glyphs. One visual family of bold flat marks with "
     "layered interior detail; keep each subject instantly distinct."),
    ("A03", list(range(17, 24)),
     "HUD glyphs: the plainest symbols in the set. Crisp, utilitarian, "
     "unmistakable at 16 px; detail belongs in the interior marks only."),
    ("A04", list(range(24, 31)),
     "Cargo and currency glyphs. Industrial container language; the credits "
     "coin is a hexagonal coin with a vertical bar."),
    ("A05", [31, 34, 35, 36, 37, 38],
     "Ammunition and weapon glyphs - all EMBER OK. One weapon-family language: "
     "hard silhouettes with a small hot ember core or edge per icon."),
    ("A06", list(range(39, 49)),
     "Ship-module glyphs, classes b booster, c computer, e engine. Keep the "
     "module-family language shared across the other module batches: layered "
     "plated silhouettes, a distinct outer shape per class."),
    ("A07", list(range(49, 58)),
     "Ship-module glyphs, classes h hull, p power, s shield. Shared module "
     "family language: layered plated silhouettes, distinct outer shape per class."),
    ("A08", list(range(58, 66)),
     "Ship-module glyphs, classes u utility, w weapon. Shared module family "
     "language: layered plated silhouettes, distinct outer shape per class."),
    ("A09", list(range(66, 76)),
     "Ten ore/mineral glyphs. One rock-family language: chunky faceted rocks "
     "with interior facet seams. Differentiate each mineral by facet count, "
     "notch or crystal mark. Related silhouettes, clearly different marks."),
    ("A10", list(range(76, 86)),
     "Ten ore/mineral glyphs. Same rock-family language as the other mineral "
     "batch: chunky faceted rocks with interior facet seams. Differentiate by "
     "facet count, notch or crystal mark."),
    ("A11", list(range(86, 96)),
     "Ten ingot glyphs. One bar-family language: the same beveled bar at the "
     "same angle in every file, layered face plus end cap, differentiated only "
     "by tier mark (groove count, notch, band). Keep the family tight."),
    ("A12", list(range(96, 106)),
     "Ten ingot glyphs. Same bar-family language as the other ingot batch: "
     "beveled bar, layered face plus end cap, differentiated only by tier mark."),
    ("A13", [147, 148, 149, 155, 174, 213, 214, 237, 251, 262],
     "Parked alternates remade as clean flat module-chip symbols. Distil the "
     "master's subject into a bold chip/crate/device mark with layered interior "
     "detail. One shared chip language with the other alt batches."),
    ("A14", [157, 159, 176, 177, 182, 189, 202, 204, 207, 228, 269],
     "Parked alternates remade as clean flat device/structure symbols. Distil "
     "the master's subject into a bold industrial mark with layered interior "
     "detail. One shared language with the other alt batches."),
    ("A15", [164, 168, 169, 178, 188, 209, 259, 261, 219, 220, 221],
     "Parked alternates remade as clean flat marks: crosshairs, arrows, bars, "
     "emblems and three generic component chips (the part_* names stay but read "
     "as generic chips with different interior marks). Crisp bold symbols."),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    lib = {a["name"]: a for a in json.load(
        open(os.path.join(WORKSPACE, "asset-library/_library.json")))["assets"].values()}
    picked = {int(p["id"]): p for p in csv.DictReader(
        open(os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")), delimiter="\t")}

    for key, ids, note in BATCHES:
        lines = [RULES]
        lines.append("BATCH NOTE: " + note + "\n")
        out_paths = []
        for i in ids:
            p = picked[i]
            name, fam = p["name"], p["family"]
            a = lib.get(name, {})
            out = f"staging/d2/svg/{name}.svg"
            out_paths.append(out)
            master = f"vajb-orbit/assets/icons/{fam}/{name}.png"
            shape = SPEC_SHAPES.get(name, "")
            ember = "EMBER OK" if name in EMBER_OK else "steel only"
            subject = a.get("subject", name)
            detail = a.get("detail", "")
            lines.append(f"- {out} | subject: {subject} | {detail}"
                         + (f" | shape: {shape}" if shape else "")
                         + f" | master: {master} | {ember}")
        lines.append("\nOutput ONLY the .svg files listed above.")
        prompt_path = os.path.join(OUT, f"D2_{key}.txt")
        with open(prompt_path, "w") as fh:
            fh.write("\n".join(lines) + "\n")
        files_path = os.path.join(OUT, f"D2_{key}.files")
        with open(files_path, "w") as fh:
            fh.write(",".join(out_paths))
        print(prompt_path, len(ids), "files")


if __name__ == "__main__":
    main()
