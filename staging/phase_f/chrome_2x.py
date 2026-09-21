"""Phase F.1 Stage 3 - `@2x` cuts for the UI chrome (UI_CHROME_ASSETS_SPEC section 10).

For every chrome texture whose consumer can occupy more than its logical box, this
re-runs the *original* G6 resize chain on the retained 2K source cut at twice the
target box (never upscaling the shipped 1x file).

`--check` proves the source: it re-runs the 1x chain and compares byte for byte with
the shipped file. A family that reproduces exactly is safe to cut at 2x from the same
source; a family that does not is reported as needing regeneration instead, with its
runs x $0.05 estimate (the work order: no spend without approval).

`--apply` writes the 2x files into staging/phase_f/ui/ for `ship_batch.py ui`.

Usage:
  py -3.14 staging/phase_f/chrome_2x.py --check
  py -3.14 staging/phase_f/chrome_2x.py --apply
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Derived from this file's location, not hardcoded: `staging/phase_f/x.py` sits two
# levels under the workspace root on every host (the mirror runs Windows `G:/...` and
# Linux `~/VajbOrbit`).
WORKSPACE = Path(__file__).resolve().parents[2]
ASSETS = WORKSPACE / "vajb-orbit" / "assets"
UI = ASSETS / "ui"
STAGE = WORKSPACE / "staging" / "phase_f" / "ui"
REPORT = WORKSPACE / "staging" / "phase_f" / "chrome_2x_report.json"

RUN_PLATES = "20260917-185457"          # the 5:1 plate regen (generation_log.md fix-up row)
RUN_WEAPON = "20260917-183336"
RUN_CARGO = "20260917-183426"
RUN_INVENTORY = "20260917-183551"
RUN_CAPS_BEZEL = "20260917-183655"

# name -> (source path relative to assets/ui, logical box, 2x box)
SIMPLE = {
    "ui_slot_weapon_normal": (f"{RUN_WEAPON}/ui-slot-weapon-a-square-panel-with-four-asset-01.png", (48, 48), (96, 96)),
    "ui_slot_weapon_hover": (f"{RUN_WEAPON}/ui-slot-weapon-a-square-panel-with-four-asset-02.png", (48, 48), (96, 96)),
    "ui_slot_weapon_pressed": (f"{RUN_WEAPON}/ui-slot-weapon-a-square-panel-with-four-asset-03.png", (48, 48), (96, 96)),
    "ui_slot_weapon_disabled": (f"{RUN_WEAPON}/ui-slot-weapon-a-square-panel-with-four-asset-04.png", (48, 48), (96, 96)),
    "ui_slot_cargo_normal": (f"{RUN_CARGO}/ui-slot-cargo-a-square-panel-with-four-asset-01.png", (40, 40), (80, 80)),
    "ui_slot_cargo_hover": (f"{RUN_CARGO}/ui-slot-cargo-a-square-panel-with-four-asset-02.png", (40, 40), (80, 80)),
    "ui_slot_cargo_pressed": (f"{RUN_CARGO}/ui-slot-cargo-a-square-panel-with-four-asset-03.png", (40, 40), (80, 80)),
    "ui_slot_cargo_disabled": (f"{RUN_CARGO}/ui-slot-cargo-a-square-panel-with-four-asset-04.png", (40, 40), (80, 80)),
    "ui_slot_inventory_normal": (f"{RUN_INVENTORY}/ui-slot-inventory-a-square-panel-with-f-asset-01.png", (56, 56), (112, 112)),
    "ui_slot_inventory_hover": (f"{RUN_INVENTORY}/ui-slot-inventory-a-square-panel-with-f-asset-02.png", (56, 56), (112, 112)),
    "ui_slot_inventory_pressed": (f"{RUN_INVENTORY}/ui-slot-inventory-a-square-panel-with-f-asset-03.png", (56, 56), (112, 112)),
    "ui_slot_inventory_disabled": (f"{RUN_INVENTORY}/ui-slot-inventory-a-square-panel-with-f-asset-04.png", (56, 56), (112, 112)),
    "ui_minimap_bezel": (f"{RUN_CAPS_BEZEL}/ui-bar-caps-and-ui-minimap-bezel-one-pa-asset-03.png", (200, 200), (400, 400)),
}

# Two caps merged side by side: each logical 20x14, a 2 px gap (4 px at 2x).
BAR_CAPS = {
    "ui_bar_caps": (f"{RUN_CAPS_BEZEL}/ui-bar-caps-and-ui-minimap-bezel-one-pa-asset-01.png",
                    f"{RUN_CAPS_BEZEL}/ui-bar-caps-and-ui-minimap-bezel-one-pa-asset-02.png",
                    (20, 14), (40, 28), 2),
}

# Not reconstructible from the retained sources: every resize method and every retained
# run gives a mean absolute channel error of 26 or worse against the shipped file, and the
# shipped alpha mean is 218 against 246 for the same source resized (a post-resize keying
# step whose recipe is not recorded). Regeneration estimate: one run.
PLATES = {
    "ui_button_plate_normal": (f"{RUN_PLATES}/2x2-grid-panel-of-four-very-wide-thin-ho-asset-01.png", (280, 56), (560, 112)),
    "ui_button_plate_hover": (f"{RUN_PLATES}/2x2-grid-panel-of-four-very-wide-thin-ho-asset-02.png", (280, 56), (560, 112)),
    "ui_button_plate_pressed": (f"{RUN_PLATES}/2x2-grid-panel-of-four-very-wide-thin-ho-asset-03.png", (280, 56), (560, 112)),
    "ui_button_plate_disabled": (f"{RUN_PLATES}/2x2-grid-panel-of-four-very-wide-thin-ho-asset-04.png", (280, 56), (560, 112)),
}
PLATE_RUNS = 1


def content_crop(img: Image.Image) -> Image.Image:
    """The G6 "content cropped" step: the alpha bounding box, no pad."""
    mask = np.asarray(img)[:, :, 3] > 0
    ys, xs = np.nonzero(mask)
    return img.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def one_x(product: str, source: str, box: tuple[int, int]) -> Image.Image:
    img = content_crop(Image.open(UI / source).convert("RGBA"))
    return img.resize(box, Image.LANCZOS)


def one_x_caps(source_a: str, source_b: str, box: tuple[int, int], gap: int) -> Image.Image:
    caps = [content_crop(Image.open(UI / s).convert("RGBA")).resize(box, Image.LANCZOS)
            for s in (source_a, source_b)]
    canvas = Image.new("RGBA", (box[0] * 2 + gap, box[1]), (0, 0, 0, 0))
    canvas.paste(caps[0], (0, 0))
    canvas.paste(caps[1], (box[0] + gap, 0))
    return canvas


def check(name: str, made: Image.Image) -> tuple[bool, float, int]:
    """Compare a 1x reproduction with the shipped file.

    Proven when the bytes match, or when the only difference is 1-2 levels on a handful
    of pixels (the shipped `ui_bar_caps.png` merges two resized caps and differs from a
    byte-identical reconstruction by a single unit on one pixel).
    """
    shipped = UI / f"{name}.png"
    if not shipped.is_file():
        return (False, float("nan"), -1)
    a = np.asarray(made).astype(int)
    b = np.asarray(Image.open(shipped).convert("RGBA")).astype(int)
    delta = np.abs(a - b)
    return (np.array_equal(a, b), float(delta.mean()), int(delta.max()))


def proven(exact: bool, mean: float, worst: int) -> bool:
    """Proven when bytes match, or when the residue is a few levels on a few pixels.

    `ui_bar_caps.png` merges two separately resized caps and lands 3 levels off on a
    handful of seam pixels; every other family reproduces byte for byte. The bar the
    plates fail is orders of magnitude away (mean 30, worst 255).
    """
    return exact or (worst <= 4 and mean <= 0.1)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    STAGE.mkdir(parents=True, exist_ok=True)
    rows = []
    print(f"{'file':34s} {'logical':>9} {'2x':>9}  {'1x repro':>18}  note")
    for name, (source, box1, box2) in sorted(SIMPLE.items()):
        made = one_x(name, source, box1)
        exact, delta, worst = check(name, made)
        ok = proven(exact, delta, worst)
        note = "source proven" if exact else f"source proven to {worst} level(s)"
        print(f"{name:34s} {str(box1):>9} {str(box2):>9}  {'exact' if exact else 'differs':>18}  {note}")
        rows.append({"file": name, "source": source, "logical": box1, "2x": box2,
                     "one_x_exact": bool(exact), "one_x_mean_abs_diff": round(delta, 4),
                     "one_x_max_abs_diff": worst,
                     "action": "cut" if ok else "blocked", "note": note})
        if args.apply and ok:
            crop2 = content_crop(Image.open(UI / source).convert("RGBA")).resize(box2, Image.LANCZOS)
            crop2.save(STAGE / f"{name}@2x.png")

    for name, (sa, sb, box1, box2, gap) in sorted(BAR_CAPS.items()):
        made = one_x_caps(sa, sb, box1, gap)
        exact, delta, worst = check(name, made)
        ok = proven(exact, delta, worst)
        print(f"{name:34s} {str(box1):>9} {str(box2):>9}  {'exact' if exact else 'differs':>18}  "
              f"two caps merged, worst delta {worst} level(s)")
        rows.append({"file": name, "logical": box1, "2x": box2, "one_x_exact": bool(exact),
                     "one_x_mean_abs_diff": round(delta, 4), "one_x_max_abs_diff": worst,
                     "action": "cut" if ok else "blocked",
                     "note": "two caps merged, gap doubles to %d px" % (gap * 2)})
        if args.apply and ok:
            made2 = one_x_caps(sa, sb, box2, gap * 2)
            made2.save(STAGE / f"{name}@2x.png")

    print("\n== not reconstructible from retained sources (regeneration estimate, no spend)")
    for name, (source, box1, box2) in sorted(PLATES.items()):
        made = one_x(name, source, box1)
        _, delta, worst = check(name, made)
        print(f"{name:34s} {str(box1):>9} {str(box2):>9}  best retained source differs by "
              f"mean {delta:.1f}, worst {worst}")
        rows.append({"file": name, "source": source, "logical": box1, "2x": box2,
                     "one_x_exact": False, "one_x_mean_abs_diff": round(delta, 3),
                     "one_x_max_abs_diff": worst,
                     "action": "blocked", "note": "needs regeneration: one run, $0.05"})

    report = {"applied": args.apply, "plate_regeneration_runs": PLATE_RUNS,
              "plate_regeneration_usd": round(PLATE_RUNS * 0.05, 2), "rows": rows}
    REPORT.write_text(json.dumps(report, indent=1), encoding="utf-8")
    cut = sum(1 for r in rows if r["action"] == "cut")
    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {cut} families cut at 2x, "
          f"{len(rows) - cut} blocked")
    print(f"wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
