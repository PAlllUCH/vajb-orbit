"""Phase F.2 (C3, second half) - recolour the pale needles the model draws on the silhouette.

The F.2 drone-swarm regeneration removed the cause the prompt named (a bright specular rim
light) but the subject still triggers the artifact: the model renders the shard hull with
near-white needles standing off the silhouette. They are connected to the hull (one
connected component, so a component filter cannot see them) and `defringe_edges.py` cannot
fix them either - it rewrites the soft band to the nearest *opaque* pixel's colour, and the
nearest opaque pixel to a needle is the needle itself.

The palette has no white: its brightest value is steel highlight #565C63 (luminance 88), and
the audit's C3 bar is "a clean outer alpha edge, measured". So the needles are a colour
defect, not a silhouette defect, and this pass corrects the colour rather than deleting the
shape:

  - `pale` = pixels whose darkest channel is still bright (>= 175) and whose colour is
    near-neutral (min/max >= 0.88) - i.e. white, cream or pale grey;
  - `anchor` = the fully opaque, non-pale pixels (the hull's own gunmetal and rust);
  - every pale pixel takes the RGB of its nearest anchor, found with an exact EDT; alpha is
    left exactly as it was, so the anti-aliased silhouette keeps its shape and its softness;
  - warm pixels are protected: a white-hot engine core is surrounded by ember pixels, so a
    pixel with an ember/pale-orange neighbour within 2 px is never touched and the flare
    stays exactly as rendered.

Run `staging/phase_d/defringe_edges.py --apply` afterwards: the *band* pixels still carry
the needle's white (they were copied from it), and with the needles now dark the defringe
pass resolves them to the hull colour instead.

Backs up once to `_f2_needle_backup/`; idempotent; dry run by default.

Usage:
  py -3.14 staging/phase_f/silhouette_clean.py                 # dry run, the 4 staged cuts
  py -3.14 staging/phase_f/silhouette_clean.py --apply
  py -3.14 staging/phase_f/silhouette_clean.py --apply <paths ...>

The default targets are the STAGED cuts. Run the passes in staging and ship the result:
resolving a bare `ships/<file>.png` against `assets/` is how the shipped sprites were
silently rewritten once during this batch, so every path is printed resolved.
"""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
STAGE = ROOT / "staging" / "phase_f"
BACKUP = STAGE / "_f2_needle_backup"
REPORT = STAGE / "silhouette_clean_report.json"

# Default targets are the STAGED F.2 cuts, not the shipped assets: the whole point of the
# batch is to run the integrity passes before the bytes are shipped, and an assets-relative
# fallback silently rewrote the shipped drone sprites once (2026-09-18). Every path is
# printed resolved for that reason.
TARGETS = [f"staging/phase_f/ships/ship_drone_swarm_{v}.png"
           for v in ("front", "three_quarter", "side", "back")]

BRIGHT = 175        # near-neutral pale: the darkest channel is still bright
NEUTRAL = 0.72      # min/max channel ratio above this counts as a pale pixel; the
                    # residual needles measure (236,210,200) - warm-tinted white at
                    # neutrality 0.845 - so a strict 0.88 test leaves ~83 px behind
WARM_R = 2          # ember-neighbour protection radius
EMBER_RG = 50       # ember = strongly red-dominant; rust (r-g ~ 20-35) is NOT ember
DARK_ANCHOR = 140   # an anchor must be a mid-to-dark hull pixel
                    # (transparent pixels keep the original white RGB after the matte,
                    # so alpha is part of the pale test)


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def warm_mask(rgb: np.ndarray) -> np.ndarray:
    """Ember pixels and anything directly around them (the engine flare).

    The test has to separate hot ember from rust: burnt ember #C8461B has r-g = 130 and
    ember glow #E8703A has r-g = 120, while dry rust #8A6A50 is r-g = 32 and grimy umber
    #4A423B is r-g = 7. An earlier `r > b + 15` test marked the whole rusted hull as ember
    and protected every needle, so the pass silently did nothing.
    """
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    return ((r - g) >= EMBER_RG) & (r >= 120)


def pale_mask(rgb: np.ndarray) -> np.ndarray:
    darkest = rgb.min(axis=2).astype(np.int16)
    brightest = np.maximum(rgb.max(axis=2).astype(np.int16), 1)
    return (darkest >= BRIGHT) & (darkest / brightest >= NEUTRAL)


def clean(path: Path, apply: bool) -> dict:
    im = Image.open(path).convert("RGBA")
    arr = np.asarray(im).copy()
    rgb = arr[..., :3]
    alpha = arr[..., 3]
    lum = luminance(rgb)

    pale = pale_mask(rgb) & (alpha > 0)
    protected = ndi.binary_dilation(warm_mask(rgb), iterations=WARM_R)
    target = pale & ~protected
    anchor = (alpha >= 250) & (lum < DARK_ANCHOR) & ~protected
    if not target.any() or not anchor.any():
        return {"file": path.name, "recoloured": 0, "pale_before": int(pale.sum()),
                "pale_after": int(pale.sum()), "note": "nothing to do"}

    # Exact nearest-anchor lookup (EDT indices), so a needle takes the colour of the hull
    # pixel it is closest to - the same rule as defringe_edges.py, on a different set.
    indices = ndi.distance_transform_edt(~anchor, return_distances=False, return_indices=True)
    nearest = rgb[indices[0], indices[1]]
    before_lum = float(lum[target].mean())
    rgb[target] = nearest[target]
    after_lum = float(luminance(arr[..., :3])[target].mean())

    if apply:
        BACKUP.mkdir(parents=True, exist_ok=True)
        dest = BACKUP / f"{path.parent.name}__{path.name}"
        if not dest.exists():
            shutil.copy2(path, dest)
        Image.fromarray(arr, "RGBA").save(path)

    new_pale = pale_mask(arr[..., :3]) & (alpha > 0)
    return {"file": path.name, "recoloured": int(target.sum()),
            "pale_before": int(pale.sum()), "pale_after": int(new_pale.sum()),
            "protected_px": int((pale & protected).sum()),
            "target_lum_before": round(before_lum, 1), "target_lum_after": round(after_lum, 1),
            "visible_pale_before": int((pale & (alpha >= 64)).sum()),
            "visible_pale_after": int((new_pale & (alpha >= 64)).sum())}


def main() -> int:
    args = sys.argv[1:]
    apply = "--apply" in args
    argv = [a for a in args if not a.startswith("--")]
    targets = [(Path(t) if Path(t).is_file() else ASSETS / t) for t in (argv or TARGETS)]
    if not argv:
        targets = [Path(t).resolve() for t in TARGETS]
    rows = []
    print(f"{'recolour':>9} {'paleB':>7} {'paleA':>7} {'visB':>7} {'visA':>7} "
          f"{'lumB':>6} {'lumA':>6}  file")
    for path in targets:
        if not path.is_file():
            print(f"{'MISSING':>9}  {path}")
            continue
        row = clean(path, apply)
        rows.append(row)
        row["path"] = str(path)
        print(f"{row['recoloured']:>9} {row['pale_before']:>7} {row['pale_after']:>7} "
              f"{row.get('visible_pale_before', 0):>7} {row.get('visible_pale_after', 0):>7} "
              f"{row.get('target_lum_before', float('nan')):>6.1f} "
              f"{row.get('target_lum_after', float('nan')):>6.1f}  {path}")
    REPORT.write_text(json.dumps({"applied": apply, "bright": BRIGHT, "neutral": NEUTRAL,
                                  "warm_radius": WARM_R, "rows": rows}, indent=1),
                      encoding="utf-8")
    print(f"\n{'APPLIED' if apply else 'DRY RUN'}: {len(rows)} files; pale pixels take the "
          f"nearest hull colour, alpha untouched, ember-adjacent pixels protected")
    print("next: py -3.14 staging/phase_d/defringe_edges.py --apply <same paths>")
    print(f"wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
