#!/usr/bin/env python3
"""D2 import-settings unification for surviving masters (PNG + SVG).

Rewrites only the [params] block of each .import (the [remap] block stays
byte-identical, same contract as staging/phase_f/apply_import_settings.py):

    mipmaps/generate=true       - scaled-down icons get a mip chain, no aliasing
    compress/mode=0             - lossless, the mandated mode
    detect_3d/compress_to=0     - 3D auto-detection disabled

Targets: every .import under assets/icons and assets/ui EXCEPT the tint/ set
(the tint stencils' import cleanup is D3 item 2's named leftover). The tint set
is untouched here.

    python3 staging/d2/apply_master_import_settings.py [--apply]   (default: dry run)
"""

import os
import re
import sys

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
ASSETS = os.path.join(WORKSPACE, "vajb-orbit/assets")

WANTED = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}
# SVG masters only: the 96-grid source rasterizes at 2x so the imported master is
# 192 px, the documented detail band (ICONS_SPEC band law; the old set shipped a
# _192 cut for the same band). Reversal: svg/scale=1.0.
WANTED_SVG = {
    "svg/scale": "2.0",
}


def targets():
    out = []
    for base in ("icons", "ui"):
        root = os.path.join(ASSETS, base)
        for dirpath, dirs, files in os.walk(root):
            if os.path.relpath(dirpath, root) == "tint":
                continue
            for f in sorted(files):
                if f.endswith(".import"):
                    out.append(os.path.join(dirpath, f))
    return sorted(out)


def patch(path, apply):
    wanted = dict(WANTED)
    if path.endswith(".svg.import"):
        wanted.update(WANTED_SVG)
    text = open(path, encoding="utf-8").read()
    m = re.search(r"^\[params\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
    if not m:
        return False, "no [params] block"
    block = m.group(1)
    lines = [ln for ln in block.splitlines() if ln.strip()]
    keys = {ln.split("=")[0].strip(): ln for ln in lines}
    changed = False
    for key, want in wanted.items():
        cur = keys.get(key)
        new = f"{key}={want}"
        if cur is None:
            lines.append(new)
            changed = True
        elif cur != new:
            lines = [new if ln == cur else ln for ln in lines]
            changed = True
    if changed and apply:
        new_block = "\n".join(lines) + "\n"
        text = text[:m.start(1)] + new_block + text[m.end(1):]
        open(path, "w", encoding="utf-8").write(text)
    return changed, ""


def main():
    apply = "--apply" in sys.argv
    n_changed = 0
    for path in targets():
        changed, err = patch(path, apply)
        if err:
            print("SKIP", os.path.relpath(path, WORKSPACE), err)
        elif changed:
            n_changed += 1
    print(f"{n_changed} .import files {'patched' if apply else 'want patching'} "
          f"of {len(targets())} targets")
    if not apply:
        print("(dry run - rerun with --apply)")


if __name__ == "__main__":
    main()
