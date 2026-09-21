"""Phase G recovery - the R7 chrome re-cut, every band out of the import cache.

The 2026-09-21 cut redesign pulled the pre-09-21 chrome into `assets/ui/` as whole sheet
cells: `ui_button_plate_*` 1041x1087 with the plate in a 861x131 band (the theme stretches
that into a 350x70 button, so the painted plate renders 287.1x8.6 px, 90 % transparent),
`ui_minimap_bezel` 1063x1065 (a 200x200 nine-patch, so the frame band draws 3.0 px),
`ui_bar_caps` 317x178 (both `AtlasTexture` regions crop the wrong part of it),
`ui_panel_frame` 1782x1784 (a 96x96 nine-patch, so a drawn panel's band is 8 px instead of
32) and `logo_vajb_orbit` 2170x823 (the frozen `Rect2(44,707,1961,615)` crop looks past the
bottom of it, so the Logo slot draws nothing).

None of it is regenerated. Every band comes from one of three routes, and each route is
justified by a number rather than by taste:

  cache-2x  the `@2x` cut is recovered verbatim from `.godot/imported` (it *is* the F.1/F.2
            artefact the redesign deleted) and the 1x is that `@2x` halved. Used where the
            recorded recipe cannot be replayed and the family's own record says halving is
            safe: the F.2 button plates measured the pair 0.21-0.44 levels apart
            (`plates_report.json`), the bar caps are the same two caps at 20x14 and 40x28
            with a 2/4 px gap, and the F.2 panel frame was rebuilt as 3x3 tiles of exactly
            size/3 (32 px band at 96, 64 px at 192), so halving maps tile to tile.
  recipe    both bands cut from the recovered source cell by `chrome_2x`'s own rule
            (alpha bbox, no pad, then LANCZOS), then proven against the recovered `@2x`.
  logo      the frozen 2048x2048 lockup: the wordmark is keyed out of the recovered raw
            render by keeping large *bright* components (which drops the starfield and the
            nebula), then normalised into the frozen imprint.

Measured on 2026-09-21: the `recipe` route for the button plates is dead (mean 27-38
levels off the F.2 `@2x`, the same failure `chrome_2x.py` recorded), and the `@2x` cuts do
not exist anywhere else - the cache is the only copy.

Usage:
  py -3.14 staging/phase_f/recut_chrome.py            # dry run, prints the table
  py -3.14 staging/phase_f/recut_chrome.py --apply    # writes staging/phase_f/ui/
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import chrome_2x  # noqa: E402
import recover_ctex  # noqa: E402

STAGE = ROOT / "staging" / "phase_f"
REC = STAGE / "_recover" / "ui_chrome"
OUT = STAGE / "ui"
REPORT = STAGE / "recut_chrome_report.json"

## IMPLEMENTATION_PLAN.md line 46: `ui/logo_vajb_orbit.png` is 2048x2048 RGBA with its ink
## bbox at Rect2i(56, 719, 1937, 591), and the scene crops Rect2(44, 707, 1961, 615)
## (a 12 px pad). ASSET_NAMING_SPEC.md calls that geometry frozen, so the recovered
## wordmark is normalised onto the imprint rather than shipped where the render put it.
LOGO_CANVAS = 2048
LOGO_INK = (56, 719, 1937, 591)
LOGO_BRIGHT = 90      # the letterforms; the nebula and the faint stars sit far below it
LOGO_MIN_PX = 12      # component size at 1/4 scale: a star is 1 cell, a letter is hundreds
LOGO_DILATE = 8       # reach, in px, that brings the soft edge and the near shadow back

CACHE_2X = {
    "ui_button_plate_normal": (280, 56, "F.2 plates_report same-art 0.21 levels"),
    "ui_button_plate_hover": (280, 56, "F.2 plates_report same-art 0.25 levels"),
    "ui_button_plate_pressed": (280, 56, "F.2 plates_report same-art 0.44 levels"),
    "ui_button_plate_disabled": (280, 56, "F.2 plates_report same-art 0.21 levels"),
    "ui_bar_caps": (42, 14, "84x28 halved: the engine crops (0,0,20,14) and (22,0,20,14)"),
    "ui_panel_frame": (96, 96, "F.2 built 3x3 tiles of size/3: 32 px band at 96, 64 at 192"),
    "ui_minimap_bezel": (200, 200, "F.1 nine-patch, 16 px band at 200 and 32 px at 400"),
}

## Not a route, a cross-check: the F.1 recipe re-run from the recovered cell, to show the
## halved `@2x` and the original rule land on the same art.
CROSS_CHECK = {
    "ui_minimap_bezel": (chrome_2x.SIMPLE["ui_minimap_bezel"], (200, 200), (400, 400)),
}


def cached(name: str) -> Image.Image:
    path = REC / name
    if not path.is_file():
        raise SystemExit(f"missing recovered cache copy {path.relative_to(ROOT)} - run "
                         f"recover_ctex.py --out {REC.relative_to(ROOT)} --get {name}")
    return Image.open(path).convert("RGBA")


def alpha_stats(image: Image.Image) -> dict:
    alpha = np.asarray(image)[..., 3]
    return {"alpha_mean": round(float(alpha.mean()), 1),
            "alpha_255_share": round(float((alpha == 255).mean()), 4),
            "transparent_share": round(float((alpha == 0).mean()), 4)}


def ink_box(image: Image.Image) -> list[int] | None:
    ys, xs = np.nonzero(np.asarray(image.convert("RGBA"))[..., 3] > 0)
    return (None if not len(ys) else
            [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1])


def diff(a: Image.Image, b: Image.Image) -> tuple[bool, float, int]:
    left, right = np.asarray(a).astype(int), np.asarray(b).astype(int)
    if left.shape != right.shape:
        return (False, float("nan"), -1)
    delta = np.abs(left - right)
    return (bool(np.array_equal(left, right)), float(delta.mean()), int(delta.max()))


def logo_source() -> tuple[Image.Image, Image.Image]:
    raw = REC / "_sheets" / "logo-vajb-orbit-the-word-vajb-orbit-as-1.png"
    alpha = REC / "_sheets" / "logo-vajb-orbit-the-word-vajb-orbit-as-1-alpha.png"
    for path in (raw, alpha):
        if not path.is_file():
            raise SystemExit(f"missing {path.relative_to(ROOT)} - recover the logo sheet "
                             f"with recover_ctex.py first")
    return Image.open(raw).convert("RGB"), Image.open(alpha).convert("RGBA")


def key_wordmark() -> tuple[Image.Image, dict]:
    """Keep the render's bright, large components: the letters and the shadow that travels
    with them. The starfield and the nebula are bright-but-small and dim-but-large, so
    neither survives; the matte's own alpha is kept inside what does."""
    raw, keyed = logo_source()
    rgb = np.asarray(raw)
    alpha = np.asarray(keyed)[..., 3].astype(np.int16)
    lum = np.asarray(raw.convert("L")).astype(np.int16)

    step = 4
    seed = ((lum >= LOGO_BRIGHT) & (alpha >= 32)).astype(np.uint8)
    small = np.asarray(Image.fromarray(seed * 255).resize(
        (LOGO_CANVAS // step, LOGO_CANVAS // step), Image.BOX)) > 0
    height, width = small.shape
    labels = np.zeros((height, width), np.int32)
    sizes: list[tuple[int, int]] = []
    current = 0
    for y0 in range(height):
        for x0 in range(width):
            if not small[y0, x0] or labels[y0, x0]:
                continue
            current += 1
            queue = deque([(y0, x0)])
            labels[y0, x0] = current
            count = 0
            while queue:
                y, x = queue.popleft()
                count += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if (0 <= yy < height and 0 <= xx < width and small[yy, xx]
                            and not labels[yy, xx]):
                        labels[yy, xx] = current
                        queue.append((yy, xx))
            sizes.append((current, count))

    keep_ids = [index for index, count in sizes if count >= LOGO_MIN_PX]
    keep_small = np.isin(labels, keep_ids)
    keep = np.asarray(Image.fromarray((keep_small * 255).astype(np.uint8)).resize(
        (LOGO_CANVAS, LOGO_CANVAS), Image.NEAREST)) > 0
    grown = keep.copy()
    for _ in range(LOGO_DILATE):
        moved = grown.copy()
        moved[1:, :] |= grown[:-1, :]
        moved[:-1, :] |= grown[1:, :]
        moved[:, 1:] |= grown[:, :-1]
        moved[:, :-1] |= grown[:, 1:]
        grown = moved
    out = np.where(grown, alpha, 0)
    art = Image.fromarray(np.dstack([rgb, np.clip(out, 0, 255).astype(np.uint8)]), "RGBA")
    stats = {"bright_components": current, "kept_components": len(keep_ids),
             "min_component_px": LOGO_MIN_PX * step * step, "dilate_px": LOGO_DILATE,
             "kept_brightness": LOGO_BRIGHT, "ink_box_in_render": ink_box(art)}
    return art, stats


def logo_frozen() -> tuple[Image.Image, dict]:
    art, stats = key_wordmark()
    box = stats["ink_box_in_render"]
    canvas = Image.new("RGBA", (LOGO_CANVAS, LOGO_CANVAS), (0, 0, 0, 0))
    crop = art.crop(tuple(box)).resize((LOGO_INK[2], LOGO_INK[3]), Image.LANCZOS)
    canvas.paste(crop, (LOGO_INK[0], LOGO_INK[1]))
    stats["render_ink_size"] = [box[2] - box[0], box[3] - box[1]]
    stats["normalised_to"] = list(LOGO_INK)
    stats["scale"] = [round(LOGO_INK[2] / (box[2] - box[0]), 4),
                      round(LOGO_INK[3] / (box[3] - box[1]), 4)]
    stats["frozen_ink_box"] = ink_box(canvas)
    return canvas, stats


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    rows = []
    print(f"{'file':30s} {'route':>9} {'1x':>9} {'@2x':>9}  proof")
    for name, (box1, box2, why) in sorted(CACHE_2X.items()):
        two = cached(f"{name}@2x.png")
        one = two.resize((box1, box2), Image.LANCZOS)
        rows.append({"file": name, "route": "cache-2x", "logical": [box1, box2],
                     "at2x": [box1 * 2, box2 * 2], "justification": why,
                     "at2x_source": "recovered from the import cache, shipped verbatim",
                     "one_x_source": "the @2x halved (LANCZOS)",
                     "cache_2x_md5": recover_ctex.digest(two),
                     "one_x_alpha": alpha_stats(one), "at2x_alpha": alpha_stats(two),
                     "one_x_ink": ink_box(one), "at2x_ink": ink_box(two)})
        print(f"{name:30s} {'cache-2x':>9} {str(one.size):>9} {str(two.size):>9}  {why}")
        if args.apply:
            OUT.mkdir(parents=True, exist_ok=True)
            one.save(OUT / f"{name}.png")
            two.save(OUT / f"{name}@2x.png")

    cross = []
    for name, ((source, box1, box2), _sizes, _two) in CROSS_CHECK.items():
        cell = Image.open(REC / Path(source).name).convert("RGBA")
        cropped = chrome_2x.content_crop(cell)
        reference = cached(f"{name}@2x.png")
        exact, mean, worst = diff(cropped.resize(box2, Image.LANCZOS), reference)
        exact1, mean1, worst1 = diff(cropped.resize(box1, Image.LANCZOS),
                                     Image.open(OUT / f"{name}.png").convert("RGBA")
                                     if (OUT / f"{name}.png").is_file() else
                                     cached(f"{name}@2x.png").resize(box1, Image.LANCZOS))
        cross.append({"file": name, "source_cell": Path(source).name,
                      "at2x_vs_cache": {"exact": exact, "mean_abs_diff": round(mean, 4),
                                        "max_abs_diff": worst},
                      "one_x_vs_shipped_route": {"exact": exact1,
                                                 "mean_abs_diff": round(mean1, 4),
                                                 "max_abs_diff": worst1}})
        print(f"{name:30s} {'cross':>9} {str(cropped.size):>9} {'-':>9}  F.1 recipe re-run: "
              f"@2x mean {mean:.4f} max {worst}, 1x mean {mean1:.4f} max {worst1}")

    logo, stats = logo_frozen()
    within = all(abs(stats["frozen_ink_box"][i] - (LOGO_INK[0], LOGO_INK[1],
                                                  LOGO_INK[0] + LOGO_INK[2],
                                                  LOGO_INK[1] + LOGO_INK[3])[i]) <= 1
                 for i in range(4))
    rows.append({"file": "logo_vajb_orbit", "route": "logo", "logical": [LOGO_CANVAS, LOGO_CANVAS],
                 "at2x": None, "expected_ink": [LOGO_INK[0], LOGO_INK[1],
                                                LOGO_INK[0] + LOGO_INK[2],
                                                LOGO_INK[1] + LOGO_INK[3]],
                 "logo": {**stats, "on_imprint": bool(within)},
                 "one_x_alpha": alpha_stats(logo), "one_x_ink": ink_box(logo)})
    print(f"{'logo_vajb_orbit':30s} {'logo':>9} {str(logo.size):>9} {'-':>9}  keyed "
          f"{stats['kept_components']}/{stats['bright_components']} components, "
          f"scale {stats['scale']}, ink {stats['frozen_ink_box']} "
          f"({'on imprint' if within else 'OFF IMPRINT'})")
    if args.apply:
        OUT.mkdir(parents=True, exist_ok=True)
        logo.save(OUT / "logo_vajb_orbit.png")

    report = {"applied": args.apply, "files": len(rows), "cross_checks": cross,
              "rows": rows}
    REPORT.write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {len(rows)} chrome files "
          f"({sum(1 for r in rows if r['at2x'])} with an @2x band)")
    if args.apply:
        print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"wrote {REPORT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
