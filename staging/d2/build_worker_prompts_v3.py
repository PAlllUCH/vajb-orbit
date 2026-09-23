#!/usr/bin/env python3
"""Build the D2 batch-v3 worker prompt files (round-3 SVG authoring).

Round 3 is the in-between the owner asked for: round 1 was too fine (details
dissolved in play), round 2 was too crude and drifted in style. Round 3 keeps
round 2's legibility, round 1's subject fidelity, and ONE shared style
constitution with inline exemplar SVGs so all 15 batches read as one set.

Route (owner-confirmed 2026-09-22): deepseek/deepseek-flash (DeepSeek API
direct, DeepSeek-V4.1-Flash), reasoning effort high.
"""

import csv
import os

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
OUT = os.path.join(WORKSPACE, "staging/d2/prompts_v3")
FINDINGS = os.path.join(WORKSPACE, "staging/d2/review_v1_findings.tsv")
PICKED = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")

EMBER_OK = {
    "icon_ammo", "icon_weapon_cannon", "icon_weapon_laser", "icon_weapon_mine",
    "icon_weapon_plasma", "icon_weapon_rocket", "icon_alt_missile_crosshair",
    "icon_alt_crosshair_target_reticle", "icon_alt_flame_emblem",
    "icon_alt_thruster_exhaust",
}

EXEMPLARS = """\
STYLE EXEMPLARS - three finished icons of this exact set. Match this
construction vocabulary: hard chamfered geometry, light outer mass, one dark
cut feature, integer coordinates, medium feature sizes.

EXEMPLAR 1 (vault - object with one round part):
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path fill="#c9cdd2" fill-rule="evenodd" d="M20 8h56l12 12v68H8V20zM48 36a12 12 0 1 0 0 24 12 12 0 0 0 0-24z"/>
  <path fill="#232629" d="M62 64h18v18H62z"/>
</svg>

EXEMPLAR 2 (mineral - chunky faceted rock with one big dark wedge):
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path fill="#c9cdd2" d="M14 40l14-22h18l10-10h18l12 14 10 8v28l-14 24H30L12 64z"/>
  <path fill="#232629" d="M38 46l24-14 6 10-24 16z"/>
</svg>

EXEMPLAR 3 (slot mark - pure glyph, two bold strokes):
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <path fill="#c9cdd2" d="M48 8l30 24-12 14L48 28 30 46 18 32zM48 46l30 24-12 14L48 66 30 84 18 70z"/>
</svg>
"""

RULES = """\
You are hand-authoring ROUND 3 of flat SVG UI icons for a sci-fi VIDEO GAME
(Vajb Orbit). The icons render at 16, 24 and 48 px in HUD, inventory and
fitting screens and up to 192 px in inspection panes, always on dark metal
panels. Every icon must look like it belongs to ONE icon set - the same style,
drawn by one hand. Round 1 was too fine-grained (details dissolved in play),
round 2 was too crude and inconsistent; round 3 is the in-between: readable at
24 px, still recognisable as its subject, one style throughout.

Write EXACTLY the files listed below, at the exact paths given, and nothing
else. No reports, no README, no changes to other files.

STYLE CONSTITUTION - identical for every icon of the set:
- 96x96 viewBox, integer or .5 coordinates inside 0..96. Fills only, never
  stroke, no gradients, filters, text, images or opacity below 1.
- Outer mass is LIGHT #c9cdd2. Interior detail is DARK #232629 shapes or
  transparent fill-rule evenodd holes. Mid-tone-on-light details are forbidden.
  In EMBER OK files one ember feature (#c8461b or #e8703a, at least 10 units)
  replaces the dark feature.
- Geometry: straight edges, 45-degree chamfers on outer corners (2-4 units).
  Circles only for genuinely round parts (lenses, hubs, barrels). No dots, no
  rivets, no decorative texture.
- Size ladder: interior features and gaps at least 4 units; distinguishing
  features 12-28 units; exactly ONE signature feature per icon in that range.
  6 to 10 shapes per icon. Detail density is similar across the whole set.
- The drawing must read as its SUBJECT (see the per-file line and the master
  PNG listed) - do not reduce it to an abstract mark. The SIGNATURE line gives
  the one large feature that distinguishes it from its siblings; build it at
  12-28 units, and change the OUTLINE slightly per icon (chamfer here, step
  there) so silhouettes do not collide.

FILES - one line per output: path | subject | SIGNATURE | master PNG
"""

BATCH_NOTE = {
    "A01": "Slot glyphs: slot SOCKETS, not module art. No letterforms.",
    "A02": "Contract and service marks. Instantly distinct subjects.",
    "A03": "HUD glyphs: plain utility marks, biggest shapes of the set.",
    "A04": "Cargo and currency glyphs: industrial container language.",
    "A05": "Weapons and ammo - EMBER OK. One hot ember feature per icon.",
    "A06": "Modules b/c/e classes. One shared plated-module language, but a "
           "different outline per icon.",
    "A07": "Modules h/p/s classes. Same module language, different outlines.",
    "A08": "Modules u/w classes. Same module language, different outlines.",
    "A09": "Minerals: chunky faceted rocks (exemplar 2 language). One radical "
           "silhouette difference per mineral from its SIGNATURE line.",
    "A10": "Minerals: same rock language as the other mineral batch.",
    "A11": "Ingots: beveled metal bars. The distinguishing mark is a large cut "
           "or an outline move (bites, steps, splits), never small grooves.",
    "A12": "Ingots: same bar language as the other ingot batch.",
    "A13": "Alt module-chips: light outer mass mandatory. One chip language.",
    "A14": "Alt devices and structures: light outer mass mandatory.",
    "A15": "Alt marks and part chips. The three part_* stay generic chips but "
           "must not collide with each other.",
}

BATCHES = {
    "A01": list(range(1, 9)),
    "A02": list(range(9, 17)),
    "A03": list(range(17, 24)),
    "A04": list(range(24, 31)),
    "A05": [31, 34, 35, 36, 37, 38],
    "A06": list(range(39, 49)),
    "A07": list(range(49, 58)),
    "A08": list(range(58, 66)),
    "A09": list(range(66, 76)),
    "A10": list(range(76, 86)),
    "A11": list(range(86, 96)),
    "A12": list(range(96, 106)),
    "A13": [147, 148, 149, 155, 174, 213, 214, 237, 251, 262],
    "A14": [157, 159, 176, 177, 182, 189, 202, 204, 207, 228, 269],
    "A15": [164, 168, 169, 178, 188, 209, 259, 261, 219, 220, 221],
}


def main():
    os.makedirs(OUT, exist_ok=True)
    findings = {r["name"]: r for r in csv.DictReader(open(FINDINGS), delimiter="\t")}
    picked = {int(p["id"]): p for p in csv.DictReader(open(PICKED), delimiter="\t")}

    for key, ids in BATCHES.items():
        lines = [RULES, EXEMPLARS]
        lines.append("BATCH NOTE: " + BATCH_NOTE[key] + "\n")
        out_paths = []
        for i in ids:
            p = picked[i]
            name, fam = p["name"], p["family"]
            f = findings.get(name, {})
            fix = f.get("fix", "one clear distinguishing feature")
            out = f"staging/d2/svg_v3/{name}.svg"
            out_paths.append(out)
            master = f"vajb-orbit/assets/icons/{fam}/{name}.png"
            ember = "EMBER OK" if name in EMBER_OK else "steel only"
            lines.append(f"- {out} | subject: {name} | SIGNATURE: {fix} | "
                         f"master: {master} | {ember}")
        lines.append("\nOutput ONLY the .svg files listed above. "
                     "No markdown, no explanations.")
        with open(os.path.join(OUT, f"D2_{key}.txt"), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        with open(os.path.join(OUT, f"D2_{key}.files"), "w") as fh:
            fh.write(",".join(out_paths))
        print(f"D2_{key}.txt {len(ids)} files")


if __name__ == "__main__":
    main()
