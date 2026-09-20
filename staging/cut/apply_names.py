"""Apply the naming plan: rename and file every asset into the tree the spec lays down.

Reads `_naming/assignments.tsv`, which already carries a validated decision per file, and does
three things in one pass, each of which is reversible:

* **rename** - the file takes the name the table gives it;
* **swap** - two files exchange names, done through a temporary name so neither is lost;
* **drop** - the file moves to `asset-library/_dropped/`, never deleted, because a drop is an
  owner ruling that should still be inspectable afterwards.

It also **files every asset** into the folder tree `docs/design/ASSET_NAMING_SPEC.md` section 3
lays down, whether or not the name changed, so the library stops being one flat folder of 540
files.

`_rename_map.json` records every move, so `--undo` puts the library back exactly as it was. The
derived manifests (`_sheets.json`, `_cuts_manifest.json`, `_vision.json`) have their keys and
name lists rewritten through the same map, so nothing is left pointing at a path that no longer
exists.

Usage:
    py -3.14 staging/cut/apply_names.py --check      # the plan and the conflicts, no moves
    py -3.14 staging/cut/apply_names.py              # do it
    py -3.14 staging/cut/apply_names.py --undo       # put it all back
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
DIGEST = Path(__file__).resolve().parent / "_naming"
ASSIGN = DIGEST / "assignments.tsv"
MAP = LIBRARY / "_rename_map.json"
DROPPED = LIBRARY / "_dropped"

ICON_CONTAINERS = (
    ("mineral", "mineral"), ("ingot", "ingot"), ("cargo", "cargo"), ("credits", "cargo"),
    ("contract", "contract"), ("map", "map"), ("booster", "booster"), ("equip", "equip"),
    ("module", "module"), ("weapon", "weapon"), ("ammo", "weapon"), ("insignia", "insignia"),
    ("service", "service"), ("slot", "slot"), ("status", "status"), ("alt", "alt"),
)
ENV_CONTAINERS = (
    ("backdrop", ("_bg", "_plate", "backdrop", "menu_bg", "loading_bg", "nebula", "haze")),
    ("tile", ("stars_layer", "wallpaper", "dust", "tileable")),
    ("body", ("body_", "planet", "moon", "shattered")),
    ("pickup", ("pickup",)),
    ("poi", ("base_", "outpost", "station", "jump_gate", "gate", "mine", "shipyard")),
    ("prop", ("prop", "wreck", "debris", "asteroid", "ice_field", "ore_cluster", "arena",
              "turret")),
)


def load_assignments() -> list[dict]:
    """One row per file. A file can be mentioned twice, once to note a spurious stamp and once to
    rename it; the later row is the decision, so last wins."""
    lines = ASSIGN.read_text(encoding="utf-8").splitlines()
    head = lines[0].split("\t")
    rows: dict[str, dict] = {}
    for line in lines[1:]:
        if not line.strip():
            continue
        row = dict(zip(head, line.split("\t")))
        rows[row["path"]] = row
    return list(rows.values())


def icon_container(name: str) -> str:
    for prefix, container in ICON_CONTAINERS:
        if name.startswith(f"icon_{prefix}") or (prefix == "credits" and name == "icon_credits"):
            return container
    return "hud"


def container_for(name: str, family: str, sheet: bool) -> str:
    """The folder under the family folder, or the family folder itself."""
    if family in ("ship", "livery"):
        return "ships"
    if family == "icon":
        if name.startswith("panel_alt_"):
            return "icons/alt" if sheet else "icons/alt"
        return "icons/" + icon_container(name)
    if family == "panel":
        return "icons"
    if family == "env":
        for container, needles in ENV_CONTAINERS:
            if any(needle in name for needle in needles):
                return "env/" + container
        return "env"
    if family in ("ui", "logo"):
        return "ui"
    if family == "fx":
        return "fx"
    return ""


def family_of(path: str, name: str) -> str:
    del path
    if name.startswith("panel_"):
        return "panel"
    head = name.split("_")[0]
    return head if head in ("ship", "icon", "env", "ui", "fx", "panel", "logo", "livery") else ""


def build(rows: list[dict]) -> tuple[list[tuple[Path, Path, str]], list[str], list[str]]:
    """(source, target, action) per file, the collisions, and the rows with no file behind them.

    A missing source is not a conflict: two sheets hold a blank cell, so the plan names a panel
    the cutter never wrote because there was no artwork in it. Those rows are reported and
    skipped.
    """
    ops: list[tuple[Path, Path, str]] = []
    conflicts: list[str] = []
    missing: list[str] = []
    for row in rows:
        source = LIBRARY / row["path"]
        if not source.exists():
            missing.append(f"{row['path']} ({row['action']})")
            continue
        action = row["action"]
        is_cut = row["path"].startswith("cut/")
        sheet = not is_cut
        root_dir = LIBRARY / ("cut" if is_cut else "raw")
        name = row["new_name"] or source.stem
        if action == "drop":
            target = DROPPED / Path(row["path"]).name
        elif action == "keep":
            if source.parent == root_dir:
                target = source  # the keyed references stay at the root
            else:
                family = family_of(row["path"], name)
                target = root_dir / container_for(name, family, sheet) / source.name
        else:
            family = family_of(row["path"], name)
            folder = container_for(name, family, sheet)
            target = root_dir / folder / f"{name}.png" if folder else root_dir / f"{name}.png"
        ops.append((source, target, action))
    seen: dict[Path, Path] = {}
    for source, target, action in ops:
        if action == "drop":
            continue
        if target in seen and seen[target] != source:
            conflicts.append(f"two files want {target.name}: {seen[target].name} and {source.name}")
        seen[target] = source

    # Categorisation covers every file, not only the ones the table names: a sprite whose name was
    # always right still has to be filed.
    covered = {source for source, _target, _action in ops}
    for root_name in ("cut", "raw"):
        for path in sorted((LIBRARY / root_name).rglob("*.png")):
            if path in covered:
                continue
            name = path.stem
            family = family_of(root_name, name)
            folder = container_for(name, family, root_name == "raw")
            base = LIBRARY / root_name
            target = base / folder / f"{name}.png" if folder else base / f"{name}.png"
            if target not in seen:
                seen[target] = path
            ops.append((path, target, "file"))
    return ops, conflicts, missing


def move(source: Path, target: Path, log: list[list[str]]) -> None:
    if source == target:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(source), str(target))
    log.append([str(source.relative_to(LIBRARY)).replace("\\", "/"),
                str(target.relative_to(LIBRARY)).replace("\\", "/")])


def apply_ops(ops: list[tuple[Path, Path, str]], log: list[list[str]]) -> None:
    swaps = [(s, t) for s, t, a in ops if a == "swap"]
    rest = [(s, t, a) for s, t, a in ops if a != "swap"]
    staging = LIBRARY / "_swap_tmp"
    staging.mkdir(exist_ok=True)
    for index, (source, target) in enumerate(swaps):
        held = staging / f"{index}_{source.name}"
        move(source, held, log)
    for index, (source, target) in enumerate(swaps):
        _ = source
        held = staging / f"{index}_{source.name}"
        move(held, target, log)
    staging.rmdir()
    for source, target, _action in rest:
        move(source, target, log)


def rewrite_manifests(log: list[list[str]]) -> None:
    """Point the derived manifests at the new paths, through the same map."""
    forward = {old: new for old, new in log}
    for name, path_key in (("_sheets.json", None), ("_cuts_manifest.json", None),
                           ("_vision.json", None)):
        path = LIBRARY / name
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        text = json.dumps(data, ensure_ascii=False)
        for old, new in forward.items():
            text = text.replace(f'"{old[:-4]}"', f'"{new[:-4]}"')
            text = text.replace(f'"{old}"', f'"{new}"')
        (LIBRARY / name).write_text(json.dumps(json.loads(text), indent=1, ensure_ascii=False),
                                   encoding="utf-8")
        _ = path_key


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--undo", action="store_true")
    args = parser.parse_args()

    if args.undo:
        if not MAP.exists():
            raise SystemExit("no rename map to undo")
        log = json.loads(MAP.read_text(encoding="utf-8"))["moves"]
        back: list[list[str]] = []
        for old, new in reversed(log):
            source, target = LIBRARY / new, LIBRARY / old
            if source.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(source), str(target))
                back.append([new, old])
        print(f"reversed {len(back)} move(s)")
        return

    rows = load_assignments()
    ops, conflicts, missing = build(rows)
    moves = sum(1 for source, target, _ in ops if source != target)
    drops = sum(1 for _s, _t, a in ops if a == "drop")
    print(f"rows {len(rows)}  moves {moves}  of which drops {drops}")
    if missing:
        print(f"\n{len(missing)} row(s) name a file that does not exist, skipped:")
        for line in missing:
            print(f"   {line}")
        print("   (a blank cell: the plan names the panel, the cutter wrote nothing for it)")
    if conflicts:
        print(f"\n{len(conflicts)} conflict(s):")
        for line in conflicts[:20]:
            print(f"   {line}")
        if args.check:
            return
        raise SystemExit("refusing to move files while conflicts are open")

    if args.check:
        print("\nno conflicts. the plan would file every asset under:")
        folders: dict[str, int] = {}
        for source, target, _a in ops:
            key = str(target.parent.relative_to(LIBRARY)).replace("\\", "/")
            folders[key] = folders.get(key, 0) + 1
        for key in sorted(folders):
            print(f"   {key:<28} {folders[key]:>4}")
        return

    log: list[list[str]] = []
    apply_ops(ops, log)
    previous: list[list[str]] = []
    if MAP.exists():
        previous = json.loads(MAP.read_text(encoding="utf-8")).get("moves", [])
    MAP.write_text(json.dumps({"moves": previous + log, "count": len(previous) + len(log)},
                              indent=1), encoding="utf-8")
    rewrite_manifests(log)
    print(f"moved {len(log)} file(s); map holds {len(previous) + len(log)} move(s)")
    print("regenerate the index with: py -3.14 staging/cut/build_library.py")


if __name__ == "__main__":
    main()
