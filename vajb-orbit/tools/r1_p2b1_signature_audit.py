#!/usr/bin/env python3
"""P2-B1 R1 check: no pinned signature in CONTRACTS §8/§11/§12 drifted.

Parses every `func <name>(<params>)` out of CONTRACTS §11 and §12's fenced pins
(the file each fence names is the `## <path>` comment above it) and looks the same
signature up in the shipped source, comparing the parameter list with whitespace
removed. For §8 it checks the two signatures this wave could have touched
(`set_ammo`, and the whole player_profile file's shape being additive).

Run from the workspace root:

    python3 vajb-orbit/tools/r1_p2b1_signature_audit.py

Exit code 0 = no drift; 1 = at least one signature is missing or different.
"""

from __future__ import annotations

import os
import re
import sys

CONTRACTS = "docs/CONTRACTS.md"
PROJECT = "vajb-orbit"


def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def pins(section: str) -> list[tuple[str, str, str]]:
    """(file, name, params) for every pinned `func` in one CONTRACTS section."""
    found: list[tuple[str, str, str]] = []
    current = None
    for line in section.split("\n"):
        named = re.match(r"##\s+(res://)?(\S+\.gd)", line)
        if named:
            current = named.group(2)
        signature = re.search(r"\bfunc\s+(\w+)\s*\(([^)]*)\)", line)
        if signature and current:
            found.append((current, signature.group(1), signature.group(2).strip()))
    return found


def main() -> int:
    if not os.path.exists(CONTRACTS):
        print("MISSING %s (run from the workspace root)" % CONTRACTS)
        return 1
    text = read(CONTRACTS)
    s11 = text[text.index("## §11 P2 ship frames") : text.index("## §12 P2-B1 weapon fit")]
    s12 = text[text.index("## §12 P2-B1 weapon fit") : text.index("## §10 Changelog")]

    normalise = lambda value: re.sub(r"\s+", "", value)  # noqa: E731
    failures = 0
    checked = 0
    for label, section in (("§11", s11), ("§12", s12)):
        print("--- CONTRACTS %s ---" % label)
        seen: set[tuple[str, str]] = set()
        for target, name, params in pins(section):
            if (target, name) in seen:
                continue
            seen.add((target, name))
            checked += 1
            path = os.path.join(PROJECT, target.lstrip("/"))
            if not os.path.exists(path):
                print("  %s::%s -> FILE ABSENT (%s)" % (target, name, path))
                failures += 1
                continue
            live = re.search(
                r"func\s+" + re.escape(name) + r"\s*\(([^)]*)\)", read(path)
            )
            if not live:
                print("  %s::%s -> MISSING" % (target, name))
                failures += 1
            elif normalise(live.group(1)) != normalise(params):
                print(
                    "  %s::%s -> DIFFERS pinned:'%s' live:'%s'"
                    % (target, name, normalise(params), normalise(live.group(1)))
                )
                failures += 1
            else:
                print("  %s::%s -> EXACT" % (target, name))

    # §8's own pins this wave's files could have moved.
    print("--- CONTRACTS §8 (the two seams this wave could touch) ---")
    profile = read(os.path.join(PROJECT, "autoload/player_profile.gd"))
    set_ammo = re.search(
        r"func set_ammo\(weapon_id: StringName, rounds: int\) -> void:", profile
    )
    print(
        "  autoload/player_profile.gd::set_ammo -> %s"
        % ("EXACT" if set_ammo else "MISSING/DIFFERENT")
    )
    if not set_ammo:
        failures += 1
    checked += 1
    log = read(os.path.join(PROJECT, "game/economy_log.gd"))
    append = re.search(
        r"static func append\(event: String, item: StringName, qty: int, "
        r"credits_delta: int, balance: int\) -> void:",
        log,
    )
    print(
        "  game/economy_log.gd::append -> %s" % ("EXACT" if append else "MISSING/DIFFERENT")
    )
    if not append:
        failures += 1
    checked += 1

    print("\nsignatures checked: %d, drift: %d" % (checked, failures))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
