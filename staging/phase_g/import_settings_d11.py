"""D11 import settings - the unified texture set for the 15 station element files.

Same three params as ICONS_SPEC section 9.3 / the Phase F.1 Stage 4 law and the D7
precedent (`import_settings_d7.py`), applied to `assets/env/poi/`'s D11 files:

    mipmaps/generate=true       - mip chain for a 2K master scaled down at runtime
    compress/mode=0             - lossless
    detect_3d/compress_to=0     - 3D auto-detection disabled

Only the three `[params]` lines are rewritten; `[remap]`, `[deps]` and every other param
stay byte-identical, so the editor keeps the imported path and uid it already derived.
The sidecars are created by the editor's scan first; a reimport through the open editor
(`filesystem_manage reimport`) is required afterwards, never a second engine instance.

Usage:
    python3 staging/phase_g/import_settings_d11.py            # check only
    python3 staging/phase_g/import_settings_d11.py --apply
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POI = ROOT / "vajb-orbit" / "assets" / "env" / "poi"
BACKUP = ROOT / "staging" / "phase_g" / "env" / "d11" / "_import_backup"

WANTED = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}

TARGETS = (
    "env_station_hero",
    "env_station_arm_a", "env_station_arm_b",
    "env_station_mast_a", "env_station_mast_b",
    "env_station_gantry_a", "env_station_gantry_b",
    "env_station_windows_a", "env_station_windows_b",
    "env_station_plate_a", "env_station_plate_b",
    "env_station_lamp_a", "env_station_lamp_b",
    "env_station_shuttle_a", "env_station_shuttle_b",
)


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
    missing = 0
    print(f"{'file':30s} {'mipmaps':8s} {'compress':9s} {'detect_3d':10s} action")
    for name in TARGETS:
        png = POI / f"{name}.png"
        sidecar = POI / f"{name}.png.import"
        if not sidecar.is_file():
            print(f"{name + '.png':30s} MISSING sidecar (editor scan first)")
            report[name] = {"error": "no sidecar"}
            missing += 1
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
                        "before": found, "after": dict(WANTED), "changed": changed,
                        "png_md5": md5(png) if png.is_file() else None}
        print(f"{name + '.png':30s} "
              f"{found.get('mipmaps/generate', '-'):8s} "
              f"{found.get('compress/mode', '-'):9s} "
              f"{found.get('detect_3d/compress_to', '-'):10s} {action}")

    changed = [n for n, row in report.items()
               if row.get("before") and row["before"] != WANTED]
    if args.json:
        Path(args.json).write_text(json.dumps(
            {"wanted": WANTED, "targets": report, "files_needing_rewrite": changed,
             "missing_sidecars": missing}, indent=1), encoding="utf-8")
    print("")
    print(f"{len(TARGETS)} file(s); {missing} missing sidecar(s); {len(changed)} needed the "
          "unified set" + ("" if args.apply else " (`--apply` writes them)"))
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
