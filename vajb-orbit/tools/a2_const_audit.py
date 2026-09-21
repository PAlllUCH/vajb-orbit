#!/usr/bin/env python3
"""A2's constant audit: prove no gameplay number moved in a wave's changed files.

The reviewer's instrument for the "no balance number moved" claim. Two independent
passes over each changed production file, HEAD (the pre-wave revision) against the
working tree:

  1. a **const map** - every `const NAME := ...` declaration's own text, so a renamed
     constant, a changed table row or a new constant is named rather than felt;
  2. a **numeral multiset** - every numeric literal outside a comment, so a changed
     value inside a function body (where no `const` sits) cannot hide.

Usage (run from the workspace root, where the project lives in `vajb-orbit/`):

    python3 vajb-orbit/tools/a2_const_audit.py                     # the wave's six files
    python3 vajb-orbit/tools/a2_const_audit.py path/to/file.gd ...

Exit code 0 always: this prints evidence, it does not judge. Read the two lists and
account for every entry; an unexplained entry is a finding.
"""

from __future__ import annotations

import collections
import re
import subprocess
import sys

## The rock-cleave wave's changed production files, as its brief tables them.
DEFAULT_FILES = [
    "vajb-orbit/autoload/audio_manager.gd",
    "vajb-orbit/game/asteroid.gd",
    "vajb-orbit/game/asteroid_field.gd",
    "vajb-orbit/game/projectile.gd",
]

CONST_START = re.compile(
    r"^(?:static\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=]+)?:?=\s*(.*)$"
)
NUMERAL = re.compile(r"\b\d+(?:\.\d+)?(?:e-?\d+)?\b")


def _head(path: str) -> str:
    done = subprocess.run(
        ["git", "show", "HEAD:" + path], capture_output=True, text=True, check=False
    )
    return done.stdout


def _const_blocks(text: str) -> dict[str, str]:
    """Every `const` declaration's full text, dictionary bodies included."""
    out: dict[str, str] = {}
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        match = CONST_START.match(lines[index])
        if not match:
            index += 1
            continue
        name, body = match.group(1), match.group(2)
        depth = body.count("{") + body.count("[") - body.count("}") - body.count("]")
        while depth > 0 and index + 1 < len(lines):
            index += 1
            body += "\n" + lines[index]
            depth += (
                lines[index].count("{")
                + lines[index].count("[")
                - lines[index].count("}")
                - lines[index].count("]")
            )
        out[name] = body.strip()
        index += 1
    return out


def _strip_comments(text: str) -> str:
    kept: list[str] = []
    for line in text.splitlines():
        if line.strip().startswith("#"):
            continue
        if "#" in line:
            cut = line.find("#")
            if line[:cut].count('"') % 2 == 0:
                line = line[:cut]
        kept.append(line)
    return "\n".join(kept)


def _numerals(text: str) -> collections.Counter:
    return collections.Counter(NUMERAL.findall(_strip_comments(text)))


def main(argv: list[str]) -> int:
    files = argv[1:] or DEFAULT_FILES
    for path in files:
        before = _head(path)
        if not before:
            print(f"=== {path}\n  SKIPPED: not in HEAD")
            continue
        with open(path, encoding="utf-8") as handle:
            now = handle.read()
        print(f"=== {path}")
        old_consts, new_consts = _const_blocks(before), _const_blocks(now)
        if old_consts == new_consts:
            print(f"  consts: IDENTICAL ({len(old_consts)} declarations)")
        else:
            for name in sorted(set(old_consts) | set(new_consts)):
                if old_consts.get(name) != new_consts.get(name):
                    print(f"  const {name}:")
                    print(f"    HEAD -> {old_consts.get(name)!r}")
                    print(f"    NOW  -> {new_consts.get(name)!r}")
        added = _numerals(now) - _numerals(before)
        removed = _numerals(before) - _numerals(now)
        print(f"  numerals added:   {dict(sorted(added.items())) if added else '{}'}")
        print(f"  numerals removed: {dict(sorted(removed.items())) if removed else '{}'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
