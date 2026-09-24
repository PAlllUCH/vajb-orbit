"""Unify the import settings of the D7 cockpit-family masters (one .import sidecar per file).

The wave's masters were written by different steps (`ship_d7.py` for A0/A1's panels, the SVG
authoring step for the digit cells), so their `.import` sidecars disagree: the five panels A0/A1
copied in carry `mipmaps/generate=false` and `detect_3d/compress_to=1` (the editor's defaults for a
plain UI texture) while the digit cells and the D6 instruments carry the unified set.

The unified set is ICONS_SPEC section 9.3 / the Phase F.1 Stage 4 law, applied here to the
cockpit family:

    mipmaps/generate=true       - a mip chain for a 2x master scaled down on a 1080p canvas
    compress/mode=0             - lossless
    detect_3d/compress_to=0     - 3D auto-detection disabled

Only the three `[params]` lines are rewritten; `[remap]`, `[deps]` and every other param stay
byte-identical, so the editor keeps the imported path and uid it already derived. A reimport is
still required afterwards - run it through the open editor (`filesystem_manage reimport`), never a
second engine instance.

Usage:
    python3 staging/phase_g/import_settings_d7.py            # check only
    python3 staging/phase_g/import_settings_d7.py --apply
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / "vajb-orbit" / "assets" / "ui"
BACKUP = ROOT / "staging" / "phase_g" / "ui" / "_a1b_backup" / "import"

WANTED = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}

## The six section 12 masters and the twelve digit cells - the cockpit family this wave ships.
TARGETS = ("ui_cockpit_panel", "ui_gauge_face", "ui_armory_console", "ui_armory_rack_plate",
           "ui_armory_row_plate", "ui_status_panel",
           *(f"ui_seg_{i}" for i in range(10)), "ui_seg_pct", "ui_seg_blank")


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def rewrite(text: str) -> tuple[str, dict]:
    """Set the three wanted params, leaving every other line and the line ending untouched."""
    found: dict[str, str] = {}
    newline = "\r\n" if "\r\n" in text else "\n"
    out: list[str] = []
    for line in text.splitlines():
        match = re.match(r"^([a-z0-9_]+/[a-z0-9_]+)=", line)
        if match and match.group(1) in WANTED:
            key = match.group(1)
            found[key] = line.split("=", 1)[1]
            out.append(f"{key}={WANTED[key]}")
        else:
            out.append(line)
    return newline.join(out) + newline, found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", default="")
    args = parser.parse_args()

    report: dict = {}
    print(f"{'file':26s} {'mipmaps':8s} {'compress':9s} {'detect_3d':10s} action")
    for name in TARGETS:
        png = UI / f"{name}.png"
        sidecar = UI / f"{name}.png.import"
        if not sidecar.is_file():
            print(f"{name + '.png':26s} MISSING sidecar")
            report[name] = {"error": "no sidecar"}
            continue
        before_md5 = md5(sidecar)
        text = sidecar.read_text(encoding="utf-8")
        new, found = rewrite(text)
        changed = new != text
        if changed:
            if args.apply:
                BACKUP.mkdir(parents=True, exist_ok=True)
                (BACKUP / f"{name}.png.import").write_text(text, encoding="utf-8")
                sidecar.write_text(new, encoding="utf-8")
            action = "rewritten" if args.apply else "would rewrite"
        else:
            action = "unchanged"
        report[name] = {"sidecar_md5_before": before_md5, "sidecar_md5_after": md5(sidecar),
                        "before": found,
                        "after": {k: WANTED[k] for k in WANTED}, "changed": changed,
                        "png_md5": md5(png) if png.is_file() else None}
        print(f"{name + '.png':26s} "
              f"{found.get('mipmaps/generate', '-'):8s} "
              f"{found.get('compress/mode', '-'):9s} "
              f"{found.get('detect_3d/compress_to', '-'):10s} {action}")

    changed = [n for n, row in report.items()
               if row.get("before") and row["before"] != WANTED]
    if args.json:
        Path(args.json).write_text(json.dumps(
            {"wanted": WANTED, "targets": report, "files_needing_rewrite": changed}, indent=1),
            encoding="utf-8")
    print("")
    print(f"{len(TARGETS)} master(s); {len(changed)} needed the unified set"
          + ("" if args.apply else " (`--apply` writes them)"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
