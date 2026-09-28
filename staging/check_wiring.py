#!/usr/bin/env python3
"""Wiring check: fail on a res:// reference that must resolve but does not.

Why: coders wired things "weirdly" partly by guessing paths, and a bad guess
surfaced late (load error in a probe, or never). Hard references break the game
the moment they are wrong, so they fail here in seconds; soft references
(format-string templates, optional user overrides, existence-probed negative
controls) are reported as advisory only. The same hard rules run inside the gate
as res://tests/test_wiring_map.gd.

Usage:

    python3 staging/check_wiring.py             # Linux: hard = exit code
    py -3.14 staging/check_wiring.py            # Windows
    python3 staging/check_wiring.py --strict    # advisory findings also fail

Hard set (exit 1 when broken):
  - `preload("res://...")` literals in .gd (a wrong one is a parse error)
  - `[ext_resource ... path="res://..."]` in .tscn (a wrong one breaks the scene)

Advisory set (printed, exit 1 only with --strict):
  - every other quoted res:// literal, checked by shape: a `%s`-style template
    or bare prefix must have its parent dir, a trailing-slash ref its dir, a
    plain ref its file
  - literals passed to `exists(` / `file_exists(` are existence-probed on
    purpose (negative controls asserting a retired file is gone) and skipped
  - KNOWN_OPTIONAL below lists the intentionally-absent files with their owner

Scans every .gd and .tscn under vajb-orbit/; addons/ is vendored and skipped as
a source, but is a valid target. Comment text is not code: .gd lines are cut at
the first `#` before matching, so prose that quotes a path can never fail it.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJ = ROOT / "vajb-orbit"
SKIP_SOURCE_DIRS = {"addons", ".godot"}

KNOWN_OPTIONAL = {
    "res://ui/hud/cockpit_style_user.tres":
        "optional user override (ui/hud/cockpit_style.gd, UI_SPEC section 3.9 rule 5)",
    "res://ui/station/armory_style_user.tres":
        "optional user override (ui/station/armory_style.gd)",
    "res://ui/hud/d7_missing_style.tres":
        "negative control (tests/test_d7_cockpit.gd)",
}

PRELOAD = re.compile(r"""preload\(\s*["'](res://[^"']+)["']""")
EXT_RESOURCE = re.compile(r"""^\[ext_resource[^\]]*path="([^"]+)""", re.M)
QUOTED_RES = re.compile(r"""["'](res://[^"']+)["']""")
EXISTS_CALL = re.compile(r"""(?:exists|file_exists)\(\s*["'](res://[^"']+)["']""")


def sources(suffix: str):
    for p in sorted(PROJ.rglob(f"*{suffix}")):
        rel = p.relative_to(PROJ).as_posix()
        if rel.split("/")[0] in SKIP_SOURCE_DIRS:
            continue
        yield p, rel


def exists(res: str) -> bool:
    return (PROJ / res[len("res://"):]).exists()


def check_soft(res: str) -> bool:
    """True when the advisory ref is satisfiable by its shape."""
    if res in KNOWN_OPTIONAL:
        return True
    path = res[len("res://"):]
    if "%" in res:
        path = path.split("%", 1)[0]
        return (PROJ / path).parent.is_dir() if "/" in path else PROJ.is_dir()
    if res.endswith("/"):
        return (PROJ / path).is_dir()
    if "." not in path.rsplit("/", 1)[-1]:
        return (PROJ / path).parent.is_dir()
    return exists(res)


def main() -> int:
    strict = "--strict" in sys.argv[1:]
    hard_broken: list[str] = []
    soft_broken: list[str] = []
    hard_refs = 0
    soft_refs = 0

    for path, rel in sources(".gd"):
        text = path.read_text(encoding="utf-8")
        for lineno, line in enumerate(text.split("\n"), 1):
            code = line.split("#")[0]
            preloaded = {m.group(1) for m in PRELOAD.finditer(code)}
            probed = {m.group(1) for m in EXISTS_CALL.finditer(code)}
            for res in preloaded:
                hard_refs += 1
                if not exists(res):
                    hard_broken.append(f"{rel}:{lineno} -> {res}")
            for m in QUOTED_RES.finditer(code):
                res = m.group(1)
                if res in preloaded or res in probed:
                    continue
                soft_refs += 1
                if not check_soft(res):
                    soft_broken.append(f"{rel}:{lineno} -> {res}")

    for path, rel in sources(".tscn"):
        text = path.read_text(encoding="utf-8")
        for m in EXT_RESOURCE.finditer(text):
            hard_refs += 1
            if not exists(m.group(1)):
                hard_broken.append(f"{rel} -> {m.group(1)}")
        probed = {m.group(1) for m in EXISTS_CALL.finditer(text)}
        for lineno, line in enumerate(text.split("\n"), 1):
            for m in QUOTED_RES.finditer(line):
                res = m.group(1)
                if res in probed:
                    continue
                soft_refs += 1
                if not check_soft(res):
                    soft_broken.append(f"{rel}:{lineno} -> {res}")

    print(f"check_wiring: {hard_refs} hard refs, {soft_refs} advisory refs")
    for b in hard_broken:
        print(f"BROKEN    {b}")
    for b in soft_broken:
        print(f"advisory  {b}")
    if hard_broken:
        print(f"check_wiring: {len(hard_broken)} broken hard references",
              file=sys.stderr)
        return 1
    if soft_broken and strict:
        print(f"check_wiring: {len(soft_broken)} unmet advisory references (--strict)",
              file=sys.stderr)
        return 1
    print("check_wiring: every hard reference resolves")
    return 0


if __name__ == "__main__":
    sys.exit(main())
