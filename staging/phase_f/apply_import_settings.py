"""Phase F.1 Stage 4 - import settings for the new resolution bands.

ICONS_SPEC section 9.3 / the work order Stage 4: `_96` and `_192` icon cuts (and the
`@2x` chrome cuts) import with

    mipmaps/generate=true       - so a 96 px texture scaled down on a 1080p canvas
                                  has a mip chain instead of aliasing
    compress/mode=0             - lossless, the mandated mode
    detect_3d/compress_to=0     - 3D auto-detection disabled

Only the `[params]` block of an existing `.import` file is rewritten; the `[remap]`
block (uid, imported path) is left byte-identical so the editor does not have to
re-derive it. The editor still has to reimport the files afterwards.

Usage:
  py -3.14 staging/phase_f/apply_import_settings.py          # dry run
  py -3.14 staging/phase_f/apply_import_settings.py --apply
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets"

WANT = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}


def targets() -> list[Path]:
    found: list[Path] = []
    for family in ("icons", "ui"):
        # rglob: the naming pass filed the masters into subfolders, so the derived cuts
        # sit next to them (`icons/<group>/icon_<name>_96.png.import`) rather than flat.
        for path in sorted((ASSETS / family).rglob("*.png.import")):
            stem = path.name[: -len(".png.import")]
            if family == "ui":
                if stem.endswith("@2x"):
                    found.append(path)
                continue
            if stem.endswith(("_96", "_192")):
                found.append(path)
    for path in sorted((ASSETS / "icons" / "tint").glob("*.png.import")):
        stem = path.name[: -len(".png.import")]
        if stem.endswith(("_96", "_192")):
            found.append(path)
    return found


def rewrite(path: Path, apply: bool) -> list[str]:
    text = path.read_text(encoding="utf-8")
    if "[params]" not in text:
        return []
    head, _, params = text.partition("[params]")
    changed = []
    for key, value in WANT.items():
        pattern = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
        if not pattern.search(params):
            params = params.rstrip("\n") + f"\n{key}={value}\n"
            changed.append(f"{key}={value} (added)")
            continue
        current = pattern.search(params).group(0)
        if current != f"{key}={value}":
            params = pattern.sub(f"{key}={value}", params)
            changed.append(f"{current} -> {key}={value}")
    if apply and changed:
        path.write_text(head + "[params]" + params, encoding="utf-8")
    return changed


def main() -> int:
    apply = "--apply" in sys.argv
    files = targets()
    touched = 0
    for path in files:
        changed = rewrite(path, apply)
        if changed:
            touched += 1
            print(f"{path.relative_to(ASSETS)}: {'; '.join(changed)}")
    print(f"\n{'APPLIED' if apply else 'DRY RUN'}: {touched} of {len(files)} .import files "
          f"need the quartet settings (mipmaps on, lossless, 3D detection off)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
