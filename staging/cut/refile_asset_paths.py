"""Re-point every asset reference at the folder the naming pass filed it into.

The naming pass (`docs/design/ASSET_NAMING_SPEC.md` section 2) moved `assets/` from flat family
folders into one level of grouping (`icons/mineral/`, `icons/hud/`, `env/backdrop/`, `env/poi/`,
`env/tile/`, `env/pickup/`, ...), and `pull.py` copies that tree into the project verbatim. The
rename rewrite covered renamed files but not the folder prefix, so code and scenes still said
`res://assets/icons/icon_gear_48.png` while the file lives at
`res://assets/icons/hud/icon_gear_48.png`. This walks the project, resolves each flat reference
against the real tree, and rewrites the ones that moved.

Usage:
    py -3.14 staging/cut/refile_asset_paths.py --check
    py -3.14 staging/cut/refile_asset_paths.py --apply

The derived tint set keeps its flat namespace (`icons/tint/`), because every icon stem is unique
across groups; the panel tint lookups resolve by file name for the same reason. References to a
file that no longer exists anywhere are reported and left alone.
"""

from __future__ import annotations

import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJECT = os.path.join(ROOT, "vajb-orbit")
ASSETS = os.path.join(PROJECT, "assets")
PREFIX = "res://assets/"
SKIP_DIRS = {".godot", ".import", "addons", "tint", "raw"}
SOURCE_DIRS = ("game", "ui", "tools", "tests", "shaders", "autoload")
TEXT_SUFFIXES = (".gd", ".tscn", ".tres", ".cfg")


def asset_index() -> dict[str, list[str]]:
    """base file name -> res:// paths that hold it."""
    index: dict[str, list[str]] = {}
    for dir_path, dir_names, file_names in os.walk(ASSETS):
        dir_names[:] = [d for d in dir_names if d not in SKIP_DIRS]
        for file_name in file_names:
            if not file_name.endswith(".png"):
                continue
            rel = os.path.relpath(os.path.join(dir_path, file_name), PROJECT).replace("\\", "/")
            index.setdefault(file_name, []).append("res://" + rel)
    return index


def references(text: str) -> list[str]:
    """Every `res://assets/...png` path in a line of code or scene text."""
    found: list[str] = []
    start = 0
    while True:
        at = text.find(PREFIX, start)
        if at < 0:
            break
        tail = text[at + len(PREFIX):]
        ref = ""
        for stop in ("\"", "'", ")", ",", " ", "\t"):
            cut = tail.split(stop)[0]
            ref = cut if not ref or len(cut) < len(ref) else ref
        start = at + len(PREFIX)
        if ref.endswith(".png"):
            found.append(ref)
    return found


def scan() -> tuple[dict[str, list[tuple[str, str]]], int, list[str]]:
    index = asset_index()
    plan: dict[str, list[tuple[str, str]]] = {}
    dangling: list[str] = []
    ok = 0
    for top in SOURCE_DIRS:
        for dir_path, dir_names, file_names in os.walk(os.path.join(PROJECT, top)):
            dir_names[:] = [d for d in dir_names if d not in SKIP_DIRS and not d.startswith(".")]
            for file_name in file_names:
                if not file_name.endswith(TEXT_SUFFIXES):
                    continue
                path = os.path.join(dir_path, file_name)
                text = io.open(path, encoding="utf-8", errors="replace").read()
                for ref in references(text):
                    flat = PREFIX + ref
                    if os.path.exists(os.path.join(PROJECT, flat.replace("res://", ""))):
                        ok += 1
                        continue
                    hits = index.get(ref.rsplit("/", 1)[-1])
                    if not hits:
                        if flat not in dangling:
                            dangling.append(flat)
                        continue
                    if len(hits) > 1:
                        print(f"  ambiguous {flat} -> {hits}, left alone")
                        continue
                    plan.setdefault(path, []).append((flat, hits[0]))
    return plan, ok, dangling


def main() -> int:
    apply = "--apply" in sys.argv
    plan, ok, dangling = scan()
    moved = sum(len(v) for v in plan.values())
    print(f"references already correct : {ok}")
    print(f"references to re-point     : {moved} in {len(plan)} files")
    for path in sorted(plan):
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        print(f"  {rel}: {len(plan[path])} refs")
        for old, new in sorted(set(plan[path]))[:3]:
            print(f"      {old}\n   -> {new}")
    if dangling:
        print(f"references with no file at all: {len(dangling)}")
        for name in dangling[:20]:
            print(f"      {name}")
    if not apply:
        print("\n--check only; re-run with --apply to rewrite")
        return 0
    for path, edits in plan.items():
        text = io.open(path, encoding="utf-8", newline="").read()
        for old, new in sorted(set(edits)):
            text = text.replace(old, new)
        io.open(path, "w", encoding="utf-8", newline="").write(text)
    print(f"\nrewrote {moved} references in {len(plan)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
