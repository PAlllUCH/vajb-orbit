#!/usr/bin/env python3
"""D2 Phase C consolidation: ship SVG masters, delete every non-master raster
PROJECT-SIDE only (vajb-orbit/assets/), record a reversal manifest.

Per symbol (x = in svg_picked.tsv):
  x:     staging/d2/svg/<name>.svg -> assets/icons/<fam>/<name>.svg
         delete <name>.png + _16/_48/_96/_192 (+ .import) + icons/tint/<name>_{16,48,96,192}
  kept:  keep <name>.png master, delete _16/_48/_96/_192 (+ .import); tint stencils stay
  chrome: delete every @2x (+ .import); base masters stay (owner tick 2026-09-22)

Reversal: masters are in asset-library/cut/; the quartet re-cuts from the master
(staging/phase_f/recut_quartet.py); tint stencils re-derive via tools/derive_icon_tints.gd;
@2x re-cuts via staging/phase_f/chrome_2x.py.

    python3 staging/d2/phase_c_consolidate.py [--apply]   (default: dry run)
"""

import csv
import json
import os
import re
import shutil
import sys

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
ASSETS = os.path.join(WORKSPACE, "vajb-orbit/assets")
SVG_SRC = os.path.join(WORKSPACE, "staging/d2/svg")
PICKED = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")
MANIFEST = os.path.join(WORKSPACE, "staging/d2/phase_c_manifest.json")
SIZES = ("16", "48", "96", "192")


def plan():
    picked = {p["name"]: p["family"] for p in csv.DictReader(open(PICKED), delimiter="\t")}
    ship, delete = [], []

    icons_root = os.path.join(ASSETS, "icons")
    for fam in sorted(os.listdir(icons_root)):
        fam_dir = os.path.join(icons_root, fam)
        if not os.path.isdir(fam_dir) or fam == "tint":
            continue
        for f in sorted(os.listdir(fam_dir)):
            if not f.endswith(".png"):
                continue
            name = f[:-4]
            m = re.search(r"_(16|48|96|192)$", name)
            base = name[:m.start()] if m else name
            variant = m.group(1) if m else None
            path = os.path.relpath(os.path.join(fam_dir, f), WORKSPACE)
            if base in picked:
                if variant is None:
                    ship.append(os.path.join(SVG_SRC, base + ".svg"))
                delete.append(path)
            else:
                if variant is not None:
                    delete.append(path)
            for p in (path, path + ".import"):
                if p in delete and not os.path.exists(os.path.join(WORKSPACE, p)):
                    delete.remove(p)

    tint_dir = os.path.join(icons_root, "tint")
    for f in sorted(os.listdir(tint_dir)):
        if not f.endswith(".png"):
            continue
        m = re.match(r"(.+)_(16|48|96|192)\.png$", f)
        if m and m.group(1) in picked:
            delete.append(os.path.relpath(os.path.join(tint_dir, f), WORKSPACE))

    ui_dir = os.path.join(ASSETS, "ui")
    for f in sorted(os.listdir(ui_dir)):
        if "@2x" in f and f.endswith(".png"):
            delete.append(os.path.relpath(os.path.join(ui_dir, f), WORKSPACE))

    # .import twins of every deleted PNG
    for p in list(delete):
        twin = p + ".import"
        if twin not in delete and os.path.exists(os.path.join(WORKSPACE, twin)):
            delete.append(twin)
    ship = sorted(set(ship))
    delete = sorted(set(delete))
    return picked, ship, delete


def main():
    apply = "--apply" in sys.argv
    picked, ship, delete = plan()

    def count(path):
        root = os.path.join(ASSETS, path)
        n = 0
        for dirpath, dirs, files in os.walk(root):
            n += sum(1 for f in files if f.endswith((".png", ".svg")))
        return n

    before = {fam: count(fam) for fam in ["icons", "ui"] if os.path.isdir(os.path.join(ASSETS, fam))}
    fam_before = {}
    for fam in sorted(os.listdir(os.path.join(ASSETS, "icons"))):
        d = os.path.join(ASSETS, "icons", fam)
        if os.path.isdir(d):
            fam_before[fam] = sum(1 for f in os.listdir(d) if f.endswith((".png", ".svg")))

    print(f"plan: ship {len(ship)} SVG, delete {len(delete)} files")
    if apply:
        for src in ship:
            name = os.path.basename(src)[:-4]
            fam = picked[name]
            dst_dir = os.path.join(ASSETS, "icons", fam)
            os.makedirs(dst_dir, exist_ok=True)
            shutil.copy2(src, os.path.join(dst_dir, os.path.basename(src)))
        for p in delete:
            fp = os.path.join(WORKSPACE, p)
            if os.path.exists(fp):
                os.remove(fp)
        with open(MANIFEST, "w") as fh:
            json.dump({"shipped": sorted(os.path.relpath(s, WORKSPACE) for s in ship),
                       "deleted": delete}, fh, indent=1)
        print("manifest:", MANIFEST)

    fam_after = {}
    for fam in sorted(os.listdir(os.path.join(ASSETS, "icons"))):
        d = os.path.join(ASSETS, "icons", fam)
        if os.path.isdir(d):
            fam_after[fam] = sum(1 for f in os.listdir(d) if f.endswith((".png", ".svg")))
    after = {fam: count(fam) for fam in before}
    print(f"{'folder':12s} {'before':>7s} {'after':>7s}")
    for fam in sorted(set(fam_before) | set(fam_after)):
        print(f"icons/{fam:8s} {fam_before.get(fam, 0):7d} {fam_after.get(fam, 0):7d}")
    for fam in before:
        print(f"{fam:12s} {before[fam]:7d} {after[fam]:7d}")
    print("total png+svg:", sum(before.values()), "->", sum(after.values()))


if __name__ == "__main__":
    main()
