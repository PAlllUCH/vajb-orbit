"""Collect the names this project already uses, so a rename can be checked against them.

Three sources, and they disagree in useful ways:

* `docs/` mentions an asset by name -- `icon_gear`, `ship_vanguard_front`, `env_sector_1_bg`.
  These are the names the design specs and the screen contracts are written against.
* `docs/design/ASSET_CATALOG.md` files each name under the folder it shipped in
  (`ships/`, `icons/`, `env/`, `ui/`, `fx/`), taken from the real `vajb-orbit/assets/` tree
  before it was emptied. This is the only place the folder taxonomy survives.
* `vajb-orbit/` code and scenes hold literal `res://assets/...` paths -- 201 of them across
  34 files. A rename that ignores these leaves the game loading a file that is not there.

Output `asset-library/_vocabulary.json`:

    {
      "docs":      {"<name>": {"files": [...], "refs": N}},
      "catalog":   {"<name>": "<folder>", ...},
      "code":      {"<path from vajb-orbit/>": ["res://assets/..."], ...},
      "derived":   {"_16": "...", ...},
      "families":  {"icon": N, "ship": N, ...}
    }

Usage:
    py -3.14 staging/cut/vocabulary.py            # write asset-library/_vocabulary.json
    py -3.14 staging/cut/vocabulary.py --show     # summary, no write
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
OUT = LIBRARY / "_vocabulary.json"
CATALOG = WORKSPACE / "docs" / "design" / "ASSET_CATALOG.md"
PROJECT = WORKSPACE / "vajb-orbit"

NAME_RE = re.compile(r"\b(icon|ship|env|fx|ui|panel|logo|livery)_[a-z0-9_]{2,60}\b")
ASSET_PATH_RE = re.compile(r"res://assets/[A-Za-z0-9_./@-]+")
CATALOG_ROW_RE = re.compile(r"^\|\s*`([^`]+?\.(?:png|ogg|ttf|otf))`", re.M)
CATALOG_SECTION_RE = re.compile(r"^##\s+(\S+)\s+-\s+.+$", re.M)

DERIVED = {
    "_16": "icon split, engine-side tint source, 16 px",
    "_48": "icon split, engine-side tint source, 48 px",
    "_96": "icon split, chrome glyph, 96 px",
    "_192": "icon split, largest shipped icon, 192 px",
    "@2x": "chrome plate cut at double resolution, raster of a nine-slice",
}
SKIP_CODE_DIRS = {"assets", ".godot", "addons"}
TEXT_EXT = (".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".txt", ".theme", ".import")


def doc_names() -> dict[str, dict]:
    found: dict[str, dict] = {}
    for root, _dirs, files in os.walk(WORKSPACE / "docs"):
        for name in files:
            if not name.endswith(".md"):
                continue
            path = Path(root) / name
            text = path.read_text(encoding="utf-8", errors="replace")
            rel = str(path.relative_to(WORKSPACE)).replace("\\", "/")
            for match in NAME_RE.finditer(text):
                entry = found.setdefault(match.group(0), {"files": [], "refs": 0})
                entry["refs"] += 1
                if rel not in entry["files"]:
                    entry["files"].append(rel)
    return found


def catalog_folders() -> dict[str, str]:
    """Each catalogued file name mapped to the folder it shipped in."""
    text = CATALOG.read_text(encoding="utf-8")
    sections = [(m.start(), m.group(1)) for m in CATALOG_SECTION_RE.finditer(text)]
    out: dict[str, str] = {}
    for i, (start, folder) in enumerate(sections):
        end = sections[i + 1][0] if i + 1 < len(sections) else len(text)
        for row in CATALOG_ROW_RE.finditer(text[start:end]):
            out[row.group(1)] = folder
    return out


def code_refs() -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for root, dirs, files in os.walk(PROJECT):
        dirs[:] = [d for d in dirs if d not in SKIP_CODE_DIRS]
        for name in files:
            if not name.endswith(TEXT_EXT):
                continue
            path = Path(root) / name
            text = path.read_text(encoding="utf-8", errors="replace")
            hits = sorted(set(ASSET_PATH_RE.findall(text)))
            if hits:
                out[str(path.relative_to(WORKSPACE)).replace("\\", "/")] = hits
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--show", action="store_true")
    args = parser.parse_args()

    docs = doc_names()
    catalog = catalog_folders()
    code = code_refs()

    families = collections.Counter()
    project = LIBRARY.parent / "asset-library"
    for folder in ("cut", "raw"):
        for path in sorted((project / folder).glob("*.png")):
            families[path.stem.split("_")[0]] += 1

    payload = {"docs": docs, "catalog": catalog, "code": code,
               "derived": DERIVED, "families": dict(families)}
    if not args.show:
        OUT.write_text(json.dumps(payload, indent=1, ensure_ascii=False), encoding="utf-8")

    print(f"docs referencing a name       : {len(docs)} names")
    print(f"catalogued file names         : {len(catalog)} in "
          f"{len(set(catalog.values()))} folders {sorted(set(catalog.values()))}")
    print(f"code files with asset paths   : {len(code)} "
          f"({sum(len(v) for v in code.values())} paths)")
    print(f"names on disk by family       : {dict(families)}")
    print(f"wrote {OUT.relative_to(WORKSPACE)}" if not args.show else "(show only)")


if __name__ == "__main__":
    main()
