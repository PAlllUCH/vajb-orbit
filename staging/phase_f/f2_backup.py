"""Phase F.2 - pre-regeneration backup of every asset the batch overwrites.

The F.2 batch (C1 frame, C2b outline glyphs, C3 drone swarm, chrome plates, C4 ice
moon) replaces shipped files, and `ship_batch.py` copies without backing up. This
script snapshots each file once into staging/phase_f/_f2_backup/ so the reversal path
is the same shape as F.1's (_cut_backup/, _rekey_backup/, _fringe_backup/).

Copies are taken only if the backup does not exist yet (first run wins), so re-running
after a partial batch never overwrites the true pre-F.2 bytes.

Usage:
  py -3.14 staging/phase_f/f2_backup.py            # dry run
  py -3.14 staging/phase_f/f2_backup.py --apply
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
STAGE = ROOT / "staging" / "phase_f"
BACKUP = STAGE / "_f2_backup"

# Shipped files the F.2 batch rewrites.
SHIPPED = [
    "ui/ui_panel_frame.png", "ui/ui_panel_frame@2x.png",
    "ui/ui_button_plate_normal.png", "ui/ui_button_plate_hover.png",
    "ui/ui_button_plate_pressed.png", "ui/ui_button_plate_disabled.png",
    "ships/ship_drone_swarm_front.png", "ships/ship_drone_swarm_three_quarter.png",
    "ships/ship_drone_swarm_side.png", "ships/ship_drone_swarm_back.png",
    "env/env_body_ice_moon.png",
    "icons/icon_zoom_plus.png", "icons/icon_zoom_minus.png",
    "icons/icon_credits.png", "icons/icon_shield.png",
]
# The same families' quartet cuts (the C2b master fix re-cuts all four tiers).
for _base in ("icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield"):
    for _size in (16, 48, 96, 192):
        SHIPPED.append(f"icons/{_base}_{_size}.png")

# Staging masters that the runs overwrite.
STAGED = ["ui/ui_panel_frame-master.png"]


def main() -> int:
    apply = "--apply" in sys.argv
    BACKUP.mkdir(parents=True, exist_ok=True)
    made = kept = missing = 0
    for rel in SHIPPED:
        src = ASSETS / rel
        dest = BACKUP / rel.replace("/", "__")
        if not src.is_file():
            missing += 1
            continue
        if dest.is_file():
            kept += 1
            continue
        if apply:
            shutil.copy2(src, dest)
        made += 1
    for rel in STAGED:
        src = STAGE / rel
        dest = BACKUP / ("staging__" + rel.replace("/", "__"))
        if not src.is_file():
            missing += 1
            continue
        if dest.is_file():
            kept += 1
            continue
        if apply:
            shutil.copy2(src, dest)
        made += 1
    print(f"{'BACKED UP' if apply else 'WOULD BACK UP'}: {made} new, {kept} already held, "
          f"{missing} not present -> {BACKUP}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
