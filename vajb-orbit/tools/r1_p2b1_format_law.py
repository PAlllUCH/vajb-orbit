#!/usr/bin/env python3
"""P2-B1 R1 check: the wave's pinned strings are byte-exact.

Reads the law (the wave brief, `STATION_HUB.md` §5.1) and the shipped panel, and
compares, byte for byte:

  * the four STATUS labels, the four ACTION labels, the strip's two line shapes and
    the `W SLOT · DRAW n` meta against the pin's own literals;
  * the power-overload format rendered on 09 §2's own example (`13 / 11 PWR — OVER
    BY 2`) against that example as the document writes it;
  * `W SLOTS FULL — SWAP OR REMOVE FIRST` against STATION_HUB §5.1's own line;
  * the six EFFECT strings against 09 §3.1's Effect column;
  * `buy_module`'s signature against CONTRACTS §12's pin.

Run from the workspace root:

    python3 vajb-orbit/tools/r1_p2b1_format_law.py

Exit code 0 = every string is the law's; 1 = at least one drifted (printed).
"""

from __future__ import annotations

import os
import re
import sys

PANEL = "vajb-orbit/ui/station/outfitting_panel.gd"
PROFILE = "vajb-orbit/autoload/player_profile.gd"
BRIEF = ".agents/gen/p2b1_weapon_fit_wave_task.md"
HUB = "docs/design/STATION_HUB.md"
DOC09 = "docs/gameplay/09_ship_slots_modules.md"
CONTRACTS = "docs/CONTRACTS.md"


def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def const(source: str, name: str) -> str | None:
    match = re.search(
        r"^const " + name + r"\s*(?::=\s*|:\s*[^=]+?=\s*)(.+)$", source, re.M
    )
    return match.group(1).strip() if match else None


def main() -> int:
    for path in (PANEL, PROFILE, BRIEF, HUB, DOC09, CONTRACTS):
        if not os.path.exists(path):
            print("MISSING %s (run from the workspace root)" % path)
            return 1

    panel = read(PANEL)
    hub = read(HUB)
    doc09 = read(DOC09)
    profile = read(PROFILE)

    checks: list[tuple[str, object, object]] = []

    def chk(label: str, got: object, want: object) -> None:
        checks.append((label, got, want))

    # STATUS / ACTION / strip / meta literals, from STATION_HUB §5.1 and the brief §3.
    chk("STATUS_FITTED", const(panel, "STATUS_FITTED"), '"FITTED (W%d)"')
    chk("STATUS_OWNED", const(panel, "STATUS_OWNED"), '"OWNED ×%d"')
    chk("STATUS_FOR_SALE", const(panel, "STATUS_FOR_SALE"), '"FOR SALE"')
    chk("STATUS_LOCKED", const(panel, "STATUS_LOCKED"), '"LOCKED"')
    chk("ACTION_BUY", const(panel, "ACTION_BUY"), '&"BUY"')
    chk("ACTION_INSTALL", const(panel, "ACTION_INSTALL"), '&"INSTALL"')
    chk("ACTION_SWAP", const(panel, "ACTION_SWAP"), '&"SWAP"')
    chk("ACTION_REMOVE", const(panel, "ACTION_REMOVE"), '&"REMOVE"')
    chk("STRIP_LINE", const(panel, "STRIP_LINE"), '"W%d %s"')
    chk("STRIP_EMPTY", const(panel, "STRIP_EMPTY"), '"— EMPTY"')
    chk("META_DRAW", const(panel, "META_DRAW"), '"W SLOT · DRAW %d"')

    # The two refusal wordings, against the documents that own them.
    doc_full = re.search(r"`(W SLOTS FULL[^`]*)`", hub)
    chk(
        "REFUSAL_SLOTS_FULL vs STATION_HUB 5.1",
        const(panel, "REFUSAL_SLOTS_FULL"),
        '"%s"' % (doc_full.group(1) if doc_full else "<not quoted in the doc>"),
    )
    doc_example = re.search(r"`([^`]*PWR — OVER BY[^`]*)`", doc09)
    rendered = const(panel, "REFUSAL_OVERLOAD").strip('"') % (13, 11, 2)
    chk(
        "overload format applied to 09 §2's own example",
        rendered,
        doc_example.group(1) if doc_example else "<not quoted in the doc>",
    )
    chk(
        "REFUSAL_OVERLOAD format",
        const(panel, "REFUSAL_OVERLOAD"),
        '"%d / %d PWR — OVER BY %d"',
    )

    # The six EFFECT strings against 09 §3.1's Effect column.
    table = doc09[doc09.index("### 3.1 WEAPONS") : doc09.index("### 3.2")]
    for mid, _draw, effect, _cost in re.findall(
        r"\|\s*`(w_\w+)`\s*\|[^|]*\|\s*(\d+)\s*\|[^|]*\|[^|]*\|\s*([^|]+?)\s*\|\s*([\d ]+)\s*\|",
        table,
    ):
        match = re.search(r'&"' + mid + r'":\s*"([^"]*)"', panel)
        chk("EFFECT " + mid, match.group(1) if match else None, effect.strip())

    # CONTRACTS §12's pinned signature.
    signature = re.search(
        r"func buy_module\(module_id: StringName, cost: int\) -> bool:", profile
    )
    chk(
        "CONTRACTS §12 buy_module signature",
        signature.group(0) if signature else None,
        "func buy_module(module_id: StringName, cost: int) -> bool:",
    )

    failures = 0
    for label, got, want in checks:
        if got == want:
            print("PASS  %s" % label)
        else:
            failures += 1
            print("FAIL  %s\n        got  %r\n        want %r" % (label, got, want))
    print(
        "\nformat-law checks: %d, failures: %d" % (len(checks), failures)
    )
    print("the two shipped refusal wordings, rendered:")
    print("  " + repr(rendered))
    print("  " + repr(const(panel, "REFUSAL_SLOTS_FULL")))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
