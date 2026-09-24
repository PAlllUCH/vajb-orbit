"""Reconcile the shipped D7 cockpit-family masters against the pinned section 12 table (name + box).

`docs/design/UI_CHROME_ASSETS_SPEC.md` section 11's instrument table and section 12's cockpit-panel
table pin, for every file in this family, its name and its master box. This step reads the shipped
bytes (not the generation log) and reports, per file:

* **present** - the file exists in `vajb-orbit/assets/ui/`;
* **box** - the actual PNG size against the pinned master box;
* **logical** - the pinned box at 1x (the in-game rect the 2x master serves), where section 11/12
  pins one;
* **import** - the three unified import parameters (mipmaps on, lossless, 3D auto-detect off).

The table below is transcribed from the two spec sections; it is the yardstick, so a mismatch is
reported and never silently repaired. `--json` writes the whole reconciliation for the report.

Usage:
    python3 staging/phase_g/reconcile_d7.py [--json out.json]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
UI = ASSETS / "ui"
ICONS = ASSETS / "icons"

## name -> (logical box | None, master box | None, spec reference)
## Section 11's instrument table (the D6 family the D7 cockpit reuses), section 11's digit cells,
## and section 12's cockpit-panel table with its Amendment 2 and post-mockup amendment.
TABLE: dict[str, tuple[tuple[int, int] | None, tuple[int, int] | None, str]] = {
    "ui_cockpit_panel": ((464, 256), (928, 512), "section 12 run 1"),
    "ui_gauge_face": ((120, 120), (240, 240), "section 12 run 2 / section 11"),
    "ui_armory_console": ((872, 956), (1744, 1912),
                          "section 12 run 3 + section 3.10 Amendment 2 (2x the ruled canvas)"),
    "ui_armory_rack_plate": ((97, 91), (194, 182), "section 12 run 4 / section 3.10 bay (2x)"),
    "ui_armory_row_plate": (None, (192, 64), "section 12 run 4 (nine-slice)"),
    "ui_status_panel": ((720, 520), (1440, 1040), "section 12 run 5"),
    "ui_cockpit_frame": (None, (192, 192), "section 11 (nine-slice, 64 px band)"),
    "ui_gauge_needle": ((8, 96), (16, 192), "section 11"),
    "ui_compass_rose": ((96, 96), (192, 192), "section 11"),
    "ui_compass_lubber": ((16, 12), (32, 24), "section 11"),
    "ui_readout_glass": ((136, 190), (272, 380), "section 11"),
}
for _i in range(10):
    TABLE[f"ui_seg_{_i}"] = ((20, 36), (48, 88), "section 11 digit cells")
TABLE["ui_seg_pct"] = ((20, 36), (48, 88), "section 11 digit cells")
TABLE["ui_seg_blank"] = ((20, 36), (48, 88), "section 11 digit cells")

## The five provenance panels `ship_d7.py` writes under `assets/icons/`; ASSET_NAMING_SPEC
## section 12 names three, the batch needs five (A0's derived names, reported there).
PANELS = ("panel_cockpit", "panel_gauge", "panel_armory", "panel_armory_plates", "panel_status")

IMPORT_WANTED = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def import_params(path: Path) -> dict:
    sidecar = path.with_name(path.name + ".import")
    if not sidecar.is_file():
        return {"sidecar": False, "params": {}, "unified": False}
    params: dict[str, str] = {}
    for line in sidecar.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^([a-z0-9_]+/[a-z0-9_]+)=(.+)$", line.strip())
        if match:
            params[match.group(1)] = match.group(2)
    read = {key: params.get(key, "-") for key in IMPORT_WANTED}
    return {"sidecar": True, "params": read,
            "unified": all(read[key] == value for key, value in IMPORT_WANTED.items())}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="")
    args = parser.parse_args()

    rows: list[dict] = []
    print(f"{'file':26s} {'present':7s} {'box':11s} {'pinned':10s} {'logical':10s} "
          f"{'box':5s} {'import':7s} spec")
    for name, (logical, master, ref) in sorted(TABLE.items()):
        path = UI / f"{name}.png"
        present = path.is_file()
        box = Image.open(path).size if present else None
        pin = import_params(path) if present else {"unified": False}
        box_ok = bool(present and master and box == master)
        rows.append({"name": name, "present": present,
                     "box": list(box) if box else None,
                     "pinned_box": list(master) if master else None,
                     "logical": list(logical) if logical else None,
                     "box_ok": box_ok, "import": pin, "md5": md5(path) if present else None,
                     "spec": ref})
        print(f"{name + '.png':26s} {str(present):7s} "
              f"{(f'{box[0]}x{box[1]}' if box else '-'):11s} "
              f"{(f'{master[0]}x{master[1]}' if master else '-'):10s} "
              f"{(f'{logical[0]}x{logical[1]}' if logical else '-'):10s} "
              f"{('OK' if box_ok else 'FAIL'):5s} "
              f"{('on' if pin['unified'] else 'NO'):7s} {ref}")

    panel_rows: list[dict] = []
    print("")
    print(f"{'panel':26s} {'present':7s} {'box':11s} note")
    for name in PANELS:
        path = ICONS / f"{name}.png"
        present = path.is_file()
        box = Image.open(path).size if present else None
        panel_rows.append({"name": name, "present": present,
                           "box": list(box) if box else None,
                           "md5": md5(path) if present else None})
        print(f"{name + '.png':26s} {str(present):7s} "
              f"{(f'{box[0]}x{box[1]}' if box else '-'):11s} provenance render (2048 sheet)")

    missing = [row["name"] for row in rows if not row["present"]]
    box_fail = [row["name"] for row in rows if row["present"] and not row["box_ok"]]
    import_fail = [row["name"] for row in rows if row["present"] and not row["import"]["unified"]]
    print("")
    print(f"{len(rows) - len(missing)}/{len(rows)} master(s) present; "
          f"box mismatch: {', '.join(box_fail) if box_fail else 'none'}; "
          f"import not unified: {', '.join(import_fail) if import_fail else 'none'}")

    if args.json:
        Path(args.json).write_text(json.dumps(
            {"masters": rows, "panels": panel_rows, "missing": missing,
             "box_mismatch": box_fail, "import_not_unified": import_fail}, indent=1),
            encoding="utf-8")
    return 1 if (missing or box_fail) else 0


if __name__ == "__main__":
    raise SystemExit(main())
