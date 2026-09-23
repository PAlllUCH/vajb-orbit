#!/usr/bin/env python3
"""Build the D2 batch-v2 worker prompt files (round-2 SVG authoring).

Round 1 failed playtest: fine details disappear at small sizes and icons are not
unique enough. The review findings (review_v1_findings.tsv, five agent audits)
become the per-icon design brief here: the FIX column is the signature feature to
build, the WEAK/CONTRAST columns name what to kill.

Owner model route: opencode-go/mimo-v2.6-flash, reasoning effort medium.
"""

import csv
import os

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
OUT = os.path.join(WORKSPACE, "staging/d2/prompts_v2")
FINDINGS = os.path.join(WORKSPACE, "staging/d2/review_v1_findings.tsv")
PICKED = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")

EMBER_OK = {
    "icon_ammo", "icon_weapon_cannon", "icon_weapon_laser", "icon_weapon_mine",
    "icon_weapon_plasma", "icon_weapon_rocket", "icon_alt_missile_crosshair",
    "icon_alt_crosshair_target_reticle", "icon_alt_flame_emblem",
    "icon_alt_thruster_exhaust",
}

RULES = """\
You are hand-authoring ROUND 2 of flat SVG game icons. Round 1 failed playtest:
fine details disappeared at small render sizes and icons were not unique enough.
Round 2 is bolder, higher-contrast and silhouette-distinct. Write EXACTLY the
files listed below, at the exact paths given, and nothing else. No reports, no
README, no changes to existing files.

HARD RULES - a validator rejects violations of 1-4:
1. Root element exactly: <svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
2. Fills only. Never use stroke. No gradients, no filters, no text, no embedded
   images, no opacity below 1. Solid flat colours only.
3. SIZE FLOORS - the playtest fix. Nothing narrower than 5 units anywhere: no
   bars, walls, gaps, dots, tips or seams below it. At least ONE signature
   feature of 24+ units per icon (it must still read at 16 px). At least 5 units
   of empty space between any two shapes. Use 4 to 8 LARGE shapes per icon -
   fewer and chunkier than round 1.
4. CONTRAST LAW. The outer mass of the icon is LIGHT #C9CDD2. Interior detail is
   cut as LARGE dark #232629 shapes or transparent fill-rule="evenodd" holes,
   each at least 5 units wide. Never place mid-tone details (#8D939B or #565C63
   shapes) on a #C9CDD2 body - they smear into mud. Never build an icon whose
   outer mass is dark (#2B2F35 / #3A3F46 / #232629): it disappears against the
   dark UI panel. In EMBER OK files one large ember accent (#C8461B or #E8703A,
   10+ units as a band or tip) replaces the second tone.
5. UNIQUENESS LAW. The OUTLINE itself must be unique - at 16 px only the outline
   and the signature feature carry identity. The per-icon SIGNATURE line below is
   the design brief: build exactly that large feature and the silhouette move it
   names. Two icons in one batch must never share an outer shape; siblings take
   different outline moves (stepped top, angled cut, punched corner, split
   halves, notch crown, overhanging cap...).
6. Coordinates on integer or .5 steps within the 0..96 canvas. Mirrored
   coordinates are fine for symmetric subjects, but take one deliberate
   asymmetry when the SIGNATURE line asks for it.
7. staging/d2/style_ref_rocket.svg is the SIMPLICITY FLOOR only - round 2 is
   chunkier and more defined than it. The master PNG listed per file shows the
   subject: keep the concept, rebuild the drawing under these rules.

FILES - one line per output:
path | subject | KILL (round-1 failures) | SIGNATURE (what to build)
"""

BATCH_NOTE = {
    "A01": "Slot glyphs depict slot SOCKETS, not module art; no letterforms.",
    "A02": "Contract and service marks; keep each subject instantly distinct.",
    "A03": "HUD glyphs: the plainest set. Big shapes, zero fiddly detail.",
    "A04": "Cargo and currency glyphs: industrial container language.",
    "A05": "Weapons and ammo - EMBER OK. One hot ember feature per icon.",
    "A06": "Modules b/c/e classes. Round 1 failed here: identical plates. Each "
           "icon gets a DIFFERENT outer shape.",
    "A07": "Modules h/p/s classes. Same rule: unique outline per icon.",
    "A08": "Modules u/w classes. Same rule: unique outline per icon.",
    "A09": "Minerals. Round 1 failed here: twenty similar blobs. Each rock gets "
           "a radically different silhouette from its SIGNATURE line.",
    "A10": "Minerals. Same rule: radical silhouette variety per mineral.",
    "A11": "Ingots. Round 1 failed here: twenty bars with tiny marks. The mark "
           "must be a HUGE void or an outline change.",
    "A12": "Ingots. Same rule: huge voids and outline moves, no small marks.",
    "A13": "Alt module-chips. Light outer mass mandatory (round 1 dark bodies "
           "vanished into the panel).",
    "A14": "Alt devices/structures. Light outer mass mandatory.",
    "A15": "Alt marks and part chips. Light outer mass; the three part_* stay "
           "generic chips but must not collide with each other.",
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
        lines = [RULES]
        lines.append("BATCH NOTE: " + BATCH_NOTE[key] + "\n")
        out_paths = []
        for i in ids:
            p = picked[i]
            name, fam = p["name"], p["family"]
            f = findings.get(name, {})
            out = f"staging/d2/svg_v2/{name}.svg"
            out_paths.append(out)
            master = f"vajb-orbit/assets/icons/{fam}/{name}.png"
            ember = "EMBER OK" if name in EMBER_OK else "steel only"
            lines.append(
                f"- {out} | subject: {name} | "
                f"KILL: {f.get('weak', '')}; {f.get('contrast', '')} | "
                f"SIGNATURE: {f.get('fix', '')} | master: {master} | {ember}")
        lines.append("\nOutput ONLY the .svg files listed above.")
        with open(os.path.join(OUT, f"D2_{key}.txt"), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        with open(os.path.join(OUT, f"D2_{key}.files"), "w") as fh:
            fh.write(",".join(out_paths))
        print(f"D2_{key}.txt {len(ids)} files")


if __name__ == "__main__":
    main()
