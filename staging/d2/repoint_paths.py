#!/usr/bin/env python3
"""D2 Phase C reference re-point: every res://assets/icons reference lands on the
one surviving art source per symbol.

Rules (applied as exact string replacement across vajb-orbit text files):
- icons/<fam>/<name>_<size>.png and icons/tint/<name>_<size>.png for an SVG-side
  symbol -> icons/<fam>/<name>.svg  (fills replace tint stencils)
- icons/<fam>/<name>_<size>.png for a raster-kept symbol -> icons/<fam>/<name>.png
  (the one master; control size scales it)
- icons/tint/... for a raster-kept symbol -> unchanged (stencils survive until D3)
- template/suffix constants follow the same split (mineral/ingot/module/weapon/
  slot/cargo families are entirely SVG-side -> templates end in .svg)
- launch_panel's cargo-only CARGO_ICON_DIR moves off tint/ to cargo/

    python3 staging/d2/repoint_paths.py [--apply]   (default: check)
"""

import csv
import os
import re
import sys

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
PROJ = os.path.join(WORKSPACE, "vajb-orbit")
PICKED = os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")
SCAN_EXT = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".md"}
SKIP_DIRS = {"addons", ".godot", ".git", "node_modules", "assets"}
SIZES = ("_16", "_48", "_96", "_192")

FIXED = [
    ('"icon_slot_%s_48.png"', '"icon_slot_%s.svg"'),
    ('"icon_cargo_%s_48.png"', '"icon_cargo_%s.svg"'),
    ('const ICON_SUFFIX := "_48.png"', 'const ICON_SUFFIX := ".svg"'),
    ('const CARGO_ICON_DIR := "res://assets/icons/tint/"',
     'const CARGO_ICON_DIR := "res://assets/icons/cargo/"'),
]

LIT_RE = re.compile(
    r"res://assets/icons/(?:tint/|[a-z_]+/)[a-z0-9_]+(?:%s)?(?:_(?:16|48|96|192))?\.png")


def build_map(picked):
    mapping = {}

    def fam_of(name):
        return picked[name]

    def repl(m):
        s = m.group(0)
        if s in mapping:
            return mapping[s]
        body = s[len("res://assets/"):]
        tint = body.startswith("icons/tint/")
        core = body[len("icons/tint/"):] if tint else body[len("icons/"):]
        m2 = re.match(r"([a-z_]+)/(.+)$", core)
        fam, leaf = (m2.group(1), m2.group(2)) if m2 else ("", core)
        name = leaf[:-4]
        suffix = ""
        for sfx in SIZES:
            if name.endswith(sfx):
                name, suffix = name[: -len(sfx)], sfx
                break
        if name.endswith("%s"):
            target = f"res://assets/icons/{fam}/{name}.svg"
        elif name in picked:
            target = f"res://assets/icons/{fam_of(name)}/{name}.svg"
        elif suffix:
            target = f"res://assets/icons/{fam}/{name}.png"
        else:
            target = s
        if tint and name in picked and not name.endswith("%s"):
            target = f"res://assets/icons/{fam_of(name)}/{name}.svg"
        mapping[s] = target
        return target

    return mapping, repl


def main():
    apply = "--apply" in sys.argv
    picked = {p["name"]: p["family"] for p in csv.DictReader(open(PICKED), delimiter="\t")}
    mapping, repl = build_map(picked)

    files = []
    for dirpath, dirs, fnames in os.walk(PROJ):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in fnames:
            if os.path.splitext(f)[1] in SCAN_EXT or f == "project.godot":
                files.append(os.path.join(dirpath, f))

    total = 0
    for path in sorted(files):
        text = open(path, encoding="utf-8", errors="replace").read()
        new = LIT_RE.sub(repl, text)
        for old, rep in FIXED:
            new = new.replace(old, rep)
        if new != text:
            n = sum(1 for a, b in zip(text.splitlines(), new.splitlines()) if a != b)
            rel = os.path.relpath(path, WORKSPACE)
            print(f"{rel}: {n} line(s) change")
            total += n
            if apply:
                open(path, "w", encoding="utf-8").write(new)
    changed = sum(1 for k, v in mapping.items() if k != v)
    print(f"\n{total} line edits across {len(files)} scanned files; "
          f"{changed} distinct reference strings remapped")
    if not apply:
        print("(check mode - rerun with --apply)")


if __name__ == "__main__":
    main()
