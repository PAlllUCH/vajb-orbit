"""Report which cue names resolve to which audio files under AudioManager's rules.

`AudioManager._load_cue()` tries `directory + cue + ".ogg"` and then
`directory + cue + "_01.ogg"` (docs/design/IMPLEMENTATION_PLAN.md 3.8), where the
directory is the flat per-bus dir from `ui/paths.gd`. This script reads the shipped
tree and prints the markdown table that goes into docs/design/ASSET_WIRING_HANDOFF.md,
so the handoff cannot drift from the files on disk.

Usage:
    py -3.14 staging/audio/list_cues.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "vajb-orbit" / "assets" / "audio"
BUS_DIRS = ("music", "sfx", "ui", "ambience")

VARIANT = re.compile(r"^(?P<base>.+?)_(?P<index>\d{2})(?:_(?P<descriptor>[a-z0-9_]+))?$")


def reachable_cues(stem: str) -> tuple[str, str]:
    """Return (cue resolved by an exact filename, cue resolved by the _01 fallback)."""
    exact = stem
    match = VARIANT.match(stem)
    fallback = ""
    if match and match.group("index") == "01" and not match.group("descriptor"):
        fallback = match.group("base")
    return exact, fallback


def main() -> int:
    rows: list[tuple[str, str, str, str, str]] = []
    for bus in BUS_DIRS:
        directory = AUDIO / bus
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob("*.ogg")):
            exact, fallback = reachable_cues(path.stem)
            if bus in ("music", "ambience"):
                note = "not reachable through AudioManager (no music/ambience API yet)"
            elif fallback:
                note = f"cue `{fallback}`"
            else:
                note = "cue name must be the full filename stem"
            rows.append((bus, path.name, exact, fallback, note))

    print("| Bus | File | Resolves from cue | ...or `_01` fallback | Note |")
    print("|---|---|---|---|---|")
    for bus, name, exact, fallback, note in rows:
        print(f"| `{bus}` | `{name}` | `{exact}` | {('`' + fallback + '`') if fallback else '-'} | {note} |")

    total = len(rows)
    primary = sum(1 for row in rows if row[3])
    print(f"\n{total} files; {primary} reachable as a primary cue via the `_01` fallback.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
