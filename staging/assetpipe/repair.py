"""Rebuild the alpha of every shipped sprite, in place, from its own RGB.

Why this is not a re-cut: the v1 matte only ever wrote the alpha channel
(`img.convert("RGBA"); putalpha(alpha)`), so the RGB under every transparent pixel still
holds the full render. Measured on the damaged sprites, their border rings are clean
background (median distance 1-2 counts) and their enclosed transparent regions carry
textured artwork (laplacian std 3.1-8.6 against ~1.8 for flat background). The damage is
therefore alpha-only, and rebuilding the alpha from the sprite's own pixels fixes it
without moving a single cut boundary - which also means no grid inference, no re-split and
no chance of a sprite ending up under the wrong name.

Only sprites that were keyed at all are touched. A sprite saved fully opaque was never
keyed (the full-frame backdrop, starfield, sector and nebula layers), so it is copied
through byte for byte.

Usage:
    py -3.14 staging/assetpipe/repair.py --list
    py -3.14 staging/assetpipe/repair.py
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import matte

WORKSPACE = Path(__file__).resolve().parents[2]
BACKUP = WORKSPACE / "staging" / "_prune_backup"
OUT_ROOT = WORKSPACE / "asset-library" / "_cuts"
REPORT = WORKSPACE / "asset-library" / "_repair_report.json"

FAMILIES = ("ships", "env", "ui", "icons")
# Derived sets whose transparent RGB is not the render, so they cannot be repaired in
# place and must be regenerated from their repaired parent:
#   *_{16,48,96,192}  F.1 contain-fit quartets      -> staging/phase_f/recut_quartet.py
#   */tint/*          the tint set                  -> vajb-orbit/tools/derive_icon_tints.gd
#   *@2x              chrome @2x cuts               -> staging/phase_f/chrome_2x.py
# Measured on the backups: a quartet's transparent pixels are 56-89% pure black and a tint's
# are uniform white, while a parent's still carry the render (mean #060B11, std 3.2).
DERIVED_QUARTET = re.compile(r"_(16|48|96|192)$")
DERIVED_SUFFIXES = ("@2x",)


def derivation(name: str, rel: str) -> str | None:
    """How a derived sprite must be regenerated, or None if it is a repairable parent."""
    if rel.startswith("tint/"):
        return "vajb-orbit/tools/derive_icon_tints.gd"
    stem = Path(name).stem
    if DERIVED_QUARTET.search(stem):
        return "staging/phase_f/recut_quartet.py"
    if stem.endswith(DERIVED_SUFFIXES):
        return "staging/phase_f/chrome_2x.py"
    return None


def repair_one(path: Path) -> tuple[Image.Image | None, dict]:
    with Image.open(path) as handle:
        image = handle.convert("RGBA")
        info = {"name": path.name, "size": list(image.size)}
        alpha = np.asarray(image.getchannel("A"))
        if alpha.min() == 255:
            return image, {**info, "action": "passthrough", "reason": "fully opaque, never keyed"}
        clear = int((alpha <= matte.CLEAR_MAX).sum())
        if clear < 16:
            # Nothing to repair: a solid plate with a soft outer edge has no transparent
            # area that could be showing the backdrop, so its alpha is not the defect.
            return image, {**info, "action": "passthrough",
                           "reason": f"only {clear} fully transparent pixels, nothing to repair"}

        rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
        bg, why = matte.estimate_background_for_sprite(rgb, alpha)
        if bg is None:
            return image, {**info, "action": "review", "reason": why}
        mode = matte.classify_background(bg)
        info.update({"background": "#%02X%02X%02X" % bg, "mode": mode})

        if mode == "warm":
            # An effect overlay whose background is part of the effect: never key it.
            return image, {**info, "action": "passthrough",
                           "reason": "warm/effect background"}

        result = matte.build_alpha(image, background=bg, mode=mode)
        metrics = matte.alpha_metrics(result.alpha, matte.grayscale(image))
        info.update({
            "action": "repaired",
            "restored_px": result.restored_px,
            "enclosed_px": metrics["enclosed_px"],
            "damage_px": metrics["art_loss_px"],
            "damage_blobs": metrics["hole_blobs"],
            "alpha_before_clear": int((alpha <= matte.CLEAR_MAX).sum()),
        })
        return matte._with_alpha(image, result.alpha), info


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    jobs: list[tuple[str, Path, str]] = []
    for family in FAMILIES:
        source = BACKUP / family
        if not source.is_dir():
            continue
        for png in sorted(source.glob("*.png")):
            jobs.append((family, png, png.name))
        tint = source / "tint"
        if tint.is_dir():
            for png in sorted(tint.glob("*.png")):
                jobs.append((family, png, f"tint/{png.name}"))

    print(f"sprites to process: {len(jobs)}")

    rows = []
    for family, src, rel in jobs:
        dest = OUT_ROOT / family / rel
        regen = derivation(src.name, rel)
        if regen:
            # Derived art: its transparent RGB was overwritten, so there is no render left
            # to rebuild alpha from. It is regenerated from the repaired parent instead, and
            # the parent is what this pass writes out.
            rows.append({"name": rel, "family": family, "action": "derived",
                         "regenerate_with": regen,
                         "dest": dest.relative_to(WORKSPACE).as_posix()})
            continue
        image, info = repair_one(src)
        if image is None:
            continue
        info["family"] = family
        info["dest"] = dest.relative_to(WORKSPACE).as_posix()
        rows.append(info)
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)

    counts: dict[str, int] = {}
    for row in rows:
        counts[row["action"]] = counts.get(row["action"], 0) + 1
    print(f"  {counts}")

    damaged = sorted((r for r in rows if r.get("damage_px")),
                     key=lambda r: -r["damage_px"])
    print(f"\nsprites still showing damage after repair: {len(damaged)}")
    print(f"{'sprite':46s} {'mode':5s} {'encl px':>8s} {'damage':>7s} {'blobs':>6s}")
    for row in damaged[:25]:
        print(f"{row['name']:46s} {row['mode']:5s} {row['enclosed_px']:8d} "
              f"{row['damage_px']:7d} {row['damage_blobs']:6d}")

    if not args.list:
        REPORT.write_text(json.dumps({"rows": rows}, indent=2), encoding="utf-8")
        print(f"\nreport -> {REPORT.relative_to(WORKSPACE).as_posix()}")
        print(f"output -> {OUT_ROOT.relative_to(WORKSPACE).as_posix()}")
    else:
        print("\n(dry run - nothing written)")


if __name__ == "__main__":
    main()
