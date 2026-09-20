"""Apply the loop flag from the audio build report to the Godot import sidecars.

Godot stores an OGG's loop setting in `<file>.ogg.import` under `[params]`:

    loop=false
    loop_offset=0
    bpm=0
    beat_count=0
    bar_beats=4

`staging/audio/build_audio.py` records which outputs are loop material, so this script flips
`loop` to match. Run it after a build, then reimport the changed files in the editor
(`filesystem_manage reimport`, batches of <=11 paths) so the imported stream is rebuilt.

Usage:
    py -3.14 staging/audio/set_loop_flags.py            # patch
    py -3.14 staging/audio/set_loop_flags.py --check     # report only
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "vajb-orbit" / "assets" / "audio"
REPORT = Path(__file__).resolve().parent / "audio_report.json"


def patch_sidecar(sidecar: Path, loop: bool) -> bool:
    text = sidecar.read_text(encoding="utf-8")
    updated, count = re.subn(r"^loop=(true|false)$", f"loop={'true' if loop else 'false'}",
                             text, count=1, flags=re.MULTILINE)
    if count == 0:
        raise RuntimeError(f"no loop= line in {sidecar}")
    if updated == text:
        return False
    sidecar.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    report = json.loads(REPORT.read_text(encoding="utf-8"))
    changed: list[str] = []
    missing: list[str] = []
    for entry in report:
        rel = entry["dest"].split("assets/audio/")[-1]
        sidecar = AUDIO / (rel + ".import")
        if not sidecar.exists():
            missing.append(rel)
            continue
        if args.check:
            text = sidecar.read_text(encoding="utf-8")
            current = re.search(r"^loop=(true|false)$", text, flags=re.MULTILINE).group(1) == "true"
            if current != entry["loops"]:
                changed.append(rel)
            continue
        if patch_sidecar(sidecar, entry["loops"]):
            changed.append(rel)

    loop_count = sum(1 for entry in report if entry["loops"])
    print(f"{len(report)} files, {loop_count} loop material, {len(changed)} sidecars "
          f"{'out of sync' if args.check else 'patched'}")
    for rel in sorted(changed):
        print(f"  {rel}")
    if missing:
        print(f"not yet imported ({len(missing)}): {', '.join(sorted(missing)[:8])} ...")
    return 0


if __name__ == "__main__":
    sys.exit(main())
