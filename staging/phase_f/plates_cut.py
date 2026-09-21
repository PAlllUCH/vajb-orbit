"""Phase F.2 (chrome) - cut the button plates at 1x and 2x from one panel.

The four `ui_button_plate_*` were the only chrome family with no retained source that
reproduces them (UI_CHROME_ASSETS_SPEC section 10: the shipped 1x files came out of a
post-resize keying step whose recipe was never recorded, so the chain cannot be replayed
and a `@2x` cut could not be derived from it). The F.2 run redraws the 2x2 plate panel;
this script cuts BOTH the logical 280x56 and the 560x112 `@2x` out of the same cell by the
same rule, which is what makes the pair literally the same art at two scales - and it
proves it numerically by downscaling the `@2x` back to the logical box and comparing.

Rules:
  - crop to the plate's *core* alpha (>= 128) plus a small pad, so a faint keying haze in
    the cell margin cannot inflate the box (the 1x box is the plate, not the cell);
  - resize exactly to the target box (the chrome convention: `chrome_2x.py` and the
    original G6 chain both resize exactly), with contain-fit only as a guard for a render
    whose proportions are off by more than `ASPECT_TOL`;
  - the panel masters are renamed `*-master.png` so `ship_batch.py` keeps them in staging.

Dry run by default; `--apply` writes the 1x and `@2x` files into staging/phase_f/ui/.

Usage:
  py -3.14 staging/phase_f/plates_cut.py
  py -3.14 staging/phase_f/plates_cut.py --apply
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
UI = STAGE / "ui"
REPORT = STAGE / "plates_report.json"

PLATES = ["ui_button_plate_normal", "ui_button_plate_hover",
          "ui_button_plate_pressed", "ui_button_plate_disabled"]
BOX_1X = (280, 56)
BOX_2X = (560, 112)
ASPECT_TOL = 0.40          # guard only: chrome resizes exactly to the box (the G6
                           # convention), and contain-fit is the fallback for a badly
                           # proportioned render. The F.2 cells measure 5.75:1 against
                           # the 5:1 box, which an exact resize absorbs invisibly.
CORE_ALPHA = 128           # the plate's own edge, not the keying haze
PAD_FRAC = 0.02            # crop pad as a fraction of the crop's short side


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def core_crop(img: Image.Image) -> tuple[Image.Image, dict]:
    arr = np.asarray(img)
    alpha = arr[..., 3]
    box = {}
    for name, mask in (("any", alpha > 8), ("core", alpha >= CORE_ALPHA)):
        ys, xs = np.nonzero(mask)
        box[name] = None if not len(ys) else (int(xs.min()), int(ys.min()),
                                              int(xs.max()) + 1, int(ys.max()) + 1)
    use = box["core"] or box["any"]
    if use is None:
        return img, box
    pad = max(2, int(round(PAD_FRAC * min(use[2] - use[0], use[3] - use[1]))))
    crop = (max(0, use[0] - pad), max(0, use[1] - pad),
            min(img.width, use[2] + pad), min(img.height, use[3] + pad))
    box["used"] = crop
    box["pad"] = pad
    return img.crop(crop), box


def fit(img: Image.Image, box: tuple[int, int], exact: bool) -> Image.Image:
    if exact:
        return img.resize(box, Image.LANCZOS)
    out = Image.new("RGBA", box, (0, 0, 0, 0))
    scaled = img.copy()
    scaled.thumbnail(box, Image.LANCZOS)
    out.paste(scaled, ((box[0] - scaled.width) // 2, (box[1] - scaled.height) // 2))
    return out


def outer_band(img: Image.Image) -> dict:
    """Mean luminance of the 2 px outer alpha shell (the C3 fringe measure, local copy so
    this script has no import order dependency)."""
    arr = np.asarray(img)
    alpha = arr[..., 3]
    reach = alpha < 16
    shell = np.zeros(alpha.shape, dtype=bool)
    for _ in range(2):
        grown = reach.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                shifted = np.zeros_like(reach)
                ys = slice(max(0, dy), reach.shape[0] + min(0, dy))
                xs = slice(max(0, dx), reach.shape[1] + min(0, dx))
                ys_src = slice(max(0, -dy), reach.shape[0] + min(0, -dy))
                xs_src = slice(max(0, -dx), reach.shape[1] + min(0, -dx))
                shifted[ys, xs] = reach[ys_src, xs_src]
                grown |= shifted
        shell |= grown & ~reach & (alpha > 0)
        reach = grown
    if not shell.any():
        return {"px": 0, "mean": float("nan"), "bright_share": float("nan")}
    rgb = arr[..., :3][shell]
    lum = luminance(rgb)
    return {"px": int(shell.sum()), "mean": float(lum.mean()),
            "bright_share": float((rgb.min(axis=1) >= 175).mean())}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    UI.mkdir(parents=True, exist_ok=True)

    rows = []
    ok = True
    print(f"{'plate':30s} {'cell':>11} {'core crop':>12} {'ratio':>6} {'rule':>11} "
          f"{'band':>7} {'alpha':>6} {'sameArt':>8}")
    for name in PLATES:
        src = UI / f"{name}.png"
        if not src.is_file():
            print(f"{name:30s} MISSING ({src.name})")
            ok = False
            continue
        img = Image.open(src).convert("RGBA")
        crop, box = core_crop(img)
        ratio = crop.width / max(1, crop.height)
        exact = abs(ratio / 5.0 - 1.0) <= ASPECT_TOL
        one = fit(crop, BOX_1X, exact)
        two = fit(crop, BOX_2X, exact)
        back = two.resize(BOX_1X, Image.LANCZOS)
        same = float(np.abs(np.asarray(back).astype(int)
                            - np.asarray(one).astype(int)).mean())
        band = outer_band(one)
        alpha = np.asarray(one)[..., 3]
        row = {"plate": name, "cell": img.size, "core_box": box.get("core"),
               "crop": crop.size, "ratio": round(ratio, 3), "exact": bool(exact),
               "box_1x": list(BOX_1X), "box_2x": list(BOX_2X),
               "same_art_mean_abs_diff": round(same, 3),
               "band": {k: (round(v, 2) if isinstance(v, float) else v)
                        for k, v in band.items()},
               "alpha_mean": round(float(alpha.mean()), 1),
               "alpha_255_share": round(float((alpha == 255).mean()), 4)}
        rows.append(row)
        print(f"{name:30s} {str(img.size):>11} {str(crop.size):>12} {ratio:>6.2f} "
              f"{'exact' if exact else 'contain':>11} {band['mean']:>7.1f} "
              f"{alpha.mean():>6.1f} {same:>8.2f}")
        if same > 8.0:
            print(f"    WARNING: the 2x cut is not the same art at 2x (mean abs diff {same:.2f})")
            ok = False
        if args.apply:
            (UI / f"{name}-master.png").write_bytes(src.read_bytes())
            one.save(UI / f"{name}.png")
            two.save(UI / f"{name}@2x.png")

    REPORT.write_text(json.dumps({"applied": args.apply, "rows": rows}, indent=1),
                      encoding="utf-8")
    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {len(rows)} plates, "
          f"1x {BOX_1X}, 2x {BOX_2X}"
          + (", masters renamed *-master.png" if args.apply else ""))
    print("sameArt = mean absolute difference between the 2x cut downscaled to the logical "
          "box and the 1x cut (bar <= 8 levels: the pair is the same art at two scales)")
    print(f"wrote {REPORT}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
