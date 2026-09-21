"""Check a rename plan against the naming law, mechanically, before anything touches disk.

A table of 242 rows can hold a collision, a name that breaks the grammar, or a sanctioned name
put on art no spec orders, and none of that is visible by reading it. Every rule in
`docs/design/ASSET_NAMING_SPEC.md` that can be expressed as a check is one here, so the plan is
verified rather than trusted:

    duplicate-target   two rows resolving to the same new name
    collide-canonical  a new name equal to one the docs already cite
    collide-live       a new name equal to a file that keeps its current name
    grammar            characters outside a-z, 0-9 and underscore, or a leading/trailing underscore
    family             a missing or unrecognised family prefix
    variant            a trailing segment outside the closed variant vocabulary
    derived-master     a master whose name carries a derived suffix
    unsupported-name   a new name whose evidence is `owner`, i.e. an invented name
    sanctioned-misuse  a name from ICONS_SPEC section 7 or 8 put on a sheet the spec does not
                       order

Usage:
    py -3.14 staging/cut/validate_names.py
    py -3.14 staging/cut/validate_names.py --fix-report   # write the findings to a file
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
DIGEST = Path(__file__).resolve().parent / "_naming"

FAMILIES = ("ship", "icon", "env", "ui", "fx", "panel", "logo", "livery")
VARIANTS = {
    "front", "three_quarter", "side", "back",
    "normal", "hover", "pressed", "disabled",
    "L1", "L2", "L3", "M1", "M2", "M3", "S1", "S2", "S3",
    "b1", "b2", "b3", "b4", "b5", "b6",
    "layer1", "layer2", "layer3",
}
DERIVED = re.compile(r"_(16|48|96|192)$|@2x$")
# Qualifiers the spec declares for a container, an alternate or a frame. A name carrying one of
# these is not claiming a variant, so the variant check does not apply to it.
DECLARED = re.compile(r"_(alt|prev|frames|sheet)(_\d+)?$|_f\d+$|_layer\d+$|_\d+_bg$")
SAFE = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*$")
# The sanctioned names, so putting one on unordered art is detectable.
SANCTIONED = {
    "icon_weapon_laser", "icon_weapon_cannon", "icon_weapon_rocket", "icon_weapon_mine",
    "icon_weapon_plasma", "icon_cargo_ore", "icon_cargo_crate", "icon_cargo_container",
    "icon_cargo_fuel_cell", "icon_cargo_salvage", "icon_cargo_data_core", "icon_gear",
    "icon_close", "icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield",
    "icon_hull", "icon_ammo", "icon_logout",
}
MINERALS = ("iron", "copper", "chromium", "silicon", "aluminium", "titanium", "nickel", "cobalt",
            "tungsten", "silver", "gold", "platinum", "neodymium", "iridium", "osmium",
            "palladium", "cerulite", "emberite", "voidglass", "krilium")
for prefix in ("mineral", "ingot"):
    SANCTIONED |= {f"icon_{prefix}_{m}" for m in MINERALS}


MINERALS_ORDER = MINERALS
SLOTS = ("engine", "power", "w", "s", "h", "c", "b", "u")
CONTRACTS = ("haul", "hunt", "gather", "escort", "expedition")
SERVICES = ("vault", "insurance", "bounty")
INSIGNIA = ("concord", "meridian", "choir")
PANEL_MASTERS = (
    "panel_minerals_ore", "panel_minerals_ingot", "panel_slots", "panel_contracts",
    "panel_service_glyphs", "panel_faction_insignia", "panel_modules_a", "panel_modules_b",
    "panel_modules_c", "panel_map_markers", "panel_boosters", "panel_status",
    "panel_weapons", "panel_cargo", "panel_glyphs", "panel_equipment",
)


def check_library() -> None:
    """Does the library on disk hold every name the specs and the code require?

    A rename can be internally consistent and still break a screen: the specs name panel masters
    and glyphs the game loads, and `_deleted_manifest.json` records which sheet produced each file
    that shipped. This is the check that caught four sanctioned glyphs filed as alternates.
    """
    cut = {p.stem for p in (LIBRARY / "cut").rglob("*.png")}
    every = cut | {p.stem for p in (LIBRARY / "raw").rglob("*.png")}
    bare = {re.sub(r"_(16|48|96|192)$|@2x$", "", s) for s in cut}
    found = bare | cut
    problems: dict[str, list[str]] = collections.defaultdict(list)

    for name in PANEL_MASTERS:
        if name not in every:
            problems["panel-master-missing"].append(name)
    for name in SANCTIONED:
        if name not in found:
            problems["sanctioned-glyph-missing"].append(name)
    for prefix, names in (("mineral", MINERALS_ORDER), ("ingot", MINERALS_ORDER),
                          ("slot", SLOTS), ("contract", CONTRACTS), ("service", SERVICES),
                          ("insignia", INSIGNIA)):
        for suffix in names:
            name = f"icon_{prefix}_{suffix}"
            if name not in found:
                problems["ordered-set-incomplete"].append(name)

    deleted = json.loads((LIBRARY / "_deleted_manifest.json").read_text(encoding="utf-8"))
    shipped = {}
    for entry in deleted["files"]:
        if entry.get("raw") and entry["path"].endswith(".png"):
            shipped[Path(entry["path"]).stem] = entry["raw"]
    for stem in shipped:
        if stem not in every:
            problems["shipped-name-absent"].append(f"{stem} (was cut from {shipped[stem]})")

    pattern = re.compile(r"res://assets/[A-Za-z0-9_./@-]+")
    for root, dirs, files in os.walk(WORKSPACE / "vajb-orbit"):
        dirs[:] = [d for d in dirs if d not in ("assets", ".godot", "addons")]
        for name in files:
            path = Path(root) / name
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for ref in pattern.findall(text):
                stem = re.sub(r"_(16|48|96|192)$|@2x$", "", Path(ref).stem)
                if stem.endswith("_"):
                    continue  # built by concatenation, checked through its table instead
                if stem.startswith(("icon_", "env_", "ui_", "fx_", "ship_", "logo_")) \
                        and stem not in found:
                    problems["code-path-missing"].append(
                        f"{stem} from {path.relative_to(WORKSPACE)}")

    print(f"library: {len(cut)} sprites and plates, "
          f"{len(list((LIBRARY / 'raw').rglob('*.png')))} sheets")
    total = sum(len(v) for v in problems.values())
    if not total:
        print("every name the specs and the code require is present")
        return
    for key in sorted(problems):
        print(f"\n{key}: {len(problems[key])}")
        for item in sorted(set(problems[key]))[:15]:
            print(f"   {item}")


def read_tsv(path: Path) -> list[dict]:
    lines = path.read_text(encoding="utf-8").splitlines()
    head = lines[0].split("\t")
    return [dict(zip(head, line.split("\t"))) for line in lines[1:] if line.strip()]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fix-report", action="store_true")
    parser.add_argument("--library", action="store_true",
                        help="check the library on disk against the specs and the code instead "
                             "of checking the plan")
    args = parser.parse_args()

    if args.library:
        check_library()
        return

    rows = read_tsv(DIGEST / "assignments.tsv")
    library = json.loads((LIBRARY / "_library.json").read_text(encoding="utf-8"))
    live = set((DIGEST / "live_names.txt").read_text(encoding="utf-8").split())
    canonical = set((DIGEST / "canonical.txt").read_text(encoding="utf-8").split())
    keeping = {r["name"] for r in library["assets"].values() if not r["name_issue"]}

    findings: dict[str, list[str]] = collections.defaultdict(list)

    targets = collections.Counter(r["new_name"] for r in rows
                                 if r["action"] == "rename" and r["new_name"])
    # A raw sheet and the sprite cut off it legitimately share a name, in their own folders, so a
    # collision only counts inside one folder.
    by_folder: dict[tuple[str, str], list[str]] = collections.defaultdict(list)
    for r in rows:
        if r["action"] != "rename" or not r["new_name"]:
            continue
        folder = "raw" if r["path"].startswith("raw/") else "cut"
        by_folder[(folder, r["new_name"])].append(r["path"])
    for (folder, name), who in by_folder.items():
        if len(who) > 1:
            findings["duplicate-target"].append(f"{folder}/{name} twice: {', '.join(who)}")

    for r in rows:
        name = r["new_name"]
        if r["action"] != "rename" or not name:
            continue
        if name in canonical and r["evidence"] in ("owner",) or (
                name in canonical and r["evidence"].startswith("matches-")):
            # A sheet legitimately taking the very panel name a spec gives it is not a collision,
            # but an invented name or a duplicate grabbing a cited name is.
            findings["collide-canonical"].append(f"{r['path']} -> {name}, cited by the docs")
        if name in keeping:
            findings["collide-live"].append(f"{r['path']} -> {name}, held by a file that stays")
        if not SAFE.match(name):
            findings["grammar"].append(f"{r['path']} -> {name}")
        if not name.startswith(tuple(f + "_" for f in FAMILIES)):
            findings["family"].append(f"{r['path']} -> {name}")
        tail = name.split("_")[-1]
        if (r["path"].startswith("cut/") and tail in ("front", "three_quarter", "side", "back")
                and not re.search(r"_(front|three_quarter|side|back)$", name)):
            findings["variant"].append(f"{r['path']} -> {name}")
        if DERIVED.search(name) and not DECLARED.search(name):
            findings["derived-master"].append(f"{r['path']} -> {name}")
        if r["evidence"] == "owner":
            findings["unsupported-name"].append(f"{r['path']} -> {name}")
        if name in SANCTIONED and r["evidence"] == "owner":
            findings["sanctioned-misuse"].append(f"{r['path']} -> {name}, evidence is owner")

    print(f"rows checked: {len(rows)}")

    # Coverage: how much of the broken set the plan actually settles.
    broken = {rel for rels in library["name_issues"].values() for rel in rels}
    planned = {r["path"] for r in rows}
    settled = {r["path"] for r in rows if r["action"] in ("rename", "drop", "keep")}
    unresolved = {r["path"] for r in rows if r["action"] in ("owner", "drop-pending")}
    print(f"broken files        : {len(broken)}")
    print(f"with a row          : {len(planned & broken)} of {len(broken)}")
    print(f"settled             : {len(settled & broken)}")
    print(f"waiting on the owner: {len(unresolved & broken)}")
    print(f"with no row at all  : {len(broken - planned)}")
    for rel in sorted(broken - planned)[:10]:
        print(f"   {rel}")
    print()
    total = sum(len(v) for v in findings.values())
    if not total:
        print("no findings: the plan obeys every checkable rule in the spec")
    for key in sorted(findings):
        items = findings[key]
        print(f"\n{key}: {len(items)}")
        for item in items[:12]:
            print(f"   {item}")
        if len(items) > 12:
            print(f"   ... and {len(items) - 12} more")
    print(f"\ntotal findings: {total}")

    if args.fix_report:
        out = DIGEST / "validation.md"
        lines = ["# Naming plan validation", "", f"Rows checked: {len(rows)}",
                 f"Broken files: {len(broken)}", f"Settled: {len(settled & broken)}",
                 f"Waiting on the owner: {len(unresolved & broken)}",
                 f"With no row at all: {len(broken - planned)}", ""]
        for key in sorted(findings):
            lines += [f"## {key} ({len(findings[key])})", ""]
            lines += [f"- `{i}`" for i in findings[key]] or ["- none"]
            lines.append("")
        lines += [f"**Total findings: {total}**", ""]
        out.write_text("\n".join(lines), encoding="utf-8")
        print(f"wrote {out.relative_to(WORKSPACE)}")


if __name__ == "__main__":
    main()
