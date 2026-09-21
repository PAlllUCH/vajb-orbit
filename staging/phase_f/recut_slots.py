"""Phase G recovery - re-cut the slot plates from their recovered source cells.

The 2026-09-21 cut redesign pulled `ui_slot_{weapon,cargo,inventory}_*` into
`vajb-orbit/assets/ui/` as whole sheet cells (880x876 / 873x864 / 882x870, ~90 %
transparent, the interior silhouette only): the paid matte had keyed the dark slot
plate out along with the white sheet background, so the plate is absent from the alpha
of every shipped file. The shipyard hardpoints, the launch panel's cargo slots and the
HUD slot buttons consume these at native size and the layout breaks.

Nothing is regenerated here. The recipe is the one Phase F.1 already proved
(`chrome_2x.py --check`: mean absolute channel error 0.0 against the shipped files), and
both the source cells and the F.1 `@2x` cuts were recovered bit-exact from Godot's
import cache by `recover_ctex.py`:

    chrome_2x.SIMPLE            name -> (source cell, logical box, @2x box)
    chrome_2x.content_crop      alpha bounding box, no pad  <- the G6 "content cropped"
    resize to the box, LANCZOS  the chrome convention: an exact resize, never contain-fit

Two numbers are printed per file and neither is an assertion:

    @2x vs cache   the derived `@2x` against the F.1 `@2x` recovered from the cache
                   (`chrome_2x.proven()`: byte-exact, or <=4 levels worst / <=0.1 mean).
                   Matching it is what proves the recovered cell is the cell F.1 used,
                   and therefore that the 1x cut from the same cell is the F.1 1x.
    1x vs @2x/2    the F.2 same-art check: the logical file against its own `@2x` halved.

Usage:
  py -3.14 staging/phase_f/recut_slots.py                  # dry run, prints the table
  py -3.14 staging/phase_f/recut_slots.py --apply          # writes staging/phase_f/ui/
  py -3.14 staging/phase_f/recut_slots.py --backup --apply # restore point, run first
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

import chrome_2x  # noqa: E402  - the recipe and its source map live there
import recover_ctex  # noqa: E402

ASSETS = ROOT / "vajb-orbit" / "assets"
UI = ASSETS / "ui"
STAGE = ROOT / "staging" / "phase_f"
CELLS = STAGE / "_recover" / "ui_slots"
OUT = STAGE / "ui"
REPORT = STAGE / "recut_slots_report.json"
BACKUP = STAGE / "_recover" / "_shipped_before"


def recovered_cell(source: str) -> Image.Image:
    """`chrome_2x` names its sources as `<run-stamp>/<file>.png`; the recovery pass
    files them flat, so only the basename is looked up here."""
    path = CELLS / Path(source).name
    if not path.is_file():
        raise SystemExit(f"missing recovered cell {path.relative_to(ROOT)} - run "
                         f"recover_ctex.py --get {Path(source).name} first")
    return Image.open(path).convert("RGBA")


def cached_at2x(name: str, cache: dict[str, recover_ctex.Ctex]) -> Image.Image | None:
    ctex = cache.get(f"{name}@2x.png")
    return recover_ctex.decode(ctex) if ctex else None


def diff(a: Image.Image, b: Image.Image) -> tuple[bool, float, int]:
    left, right = np.asarray(a).astype(int), np.asarray(b).astype(int)
    if left.shape != right.shape:
        return (False, float("nan"), -1)
    delta = np.abs(left - right)
    return (bool(np.array_equal(left, right)), float(delta.mean()), int(delta.max()))


def snapshot(names: list[str], apply: bool) -> list[dict]:
    """Pre-shipping restore point, same shape as `f2_backup.py`: first run wins, so a
    re-run after a partial ship cannot overwrite the true pre-recovery bytes."""
    taken: list[dict] = []
    for name in names:
        for source in (UI / f"{name}.png", UI / f"{name}.png.import"):
            if not source.is_file():
                continue
            target = BACKUP / source.name
            if target.exists():
                continue
            taken.append({"file": str(source.relative_to(ROOT)),
                          "bytes": source.stat().st_size,
                          "md5": recover_ctex.digest(Image.open(source))
                          if source.suffix == ".png" else None,
                          "backup": str(target.relative_to(ROOT))})
            if apply:
                BACKUP.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.read_bytes())
    return taken


def alpha_stats(image: Image.Image) -> dict:
    alpha = np.asarray(image.convert("RGBA"))[..., 3]
    ys, xs = np.nonzero(alpha > 0)
    core = np.nonzero(alpha >= 128)
    return {
        "alpha_mean": round(float(alpha.mean()), 1),
        "alpha_255_share": round(float((alpha == 255).mean()), 4),
        "ink_box": (None if not len(ys) else
                    [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]),
        "core_box": (None if not len(core[0]) else
                     [int(core[1].min()), int(core[0].min()),
                      int(core[1].max()) + 1, int(core[0].max()) + 1]),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--backup", action="store_true",
                    help="snapshot the shipped files this batch overwrites")
    args = ap.parse_args()

    slots = {name: spec for name, spec in sorted(chrome_2x.SIMPLE.items())
             if name.startswith("ui_slot_")}
    if not slots:
        raise SystemExit("chrome_2x.SIMPLE lists no ui_slot_* entries")
    cache = {ctex.source: ctex for ctex in recover_ctex.inventory()}

    if args.backup:
        taken = snapshot(list(slots), args.apply)
        for entry in taken:
            print(f"{'backed up' if args.apply else 'would back up':12s} "
                  f"{entry['file']} ({entry['bytes']} B)")
        held = sum(1 for name in slots if (UI / f"{name}.png").is_file()) - len(
            [e for e in taken if e["file"].endswith(".png")])
        print(f"\n{'BACKED UP' if args.apply else 'DRY RUN'}: {len(taken)} file(s) into "
              f"{BACKUP.relative_to(ROOT)}; {held} shipped PNG(s) already snapshotted or "
              f"absent")
        return 0

    print(f"{'file':28s} {'cell':>11} {'1x':>8} {'@2x':>8}  {'@2x vs cache':>22} "
          f"{'1x vs @2x/2':>12}  shipped")
    rows = []
    failures = 0
    for name, (source, box1, box2) in slots.items():
        cell = recovered_cell(source)
        cropped = chrome_2x.content_crop(cell)
        one = cropped.resize(box1, Image.LANCZOS)
        two = cropped.resize(box2, Image.LANCZOS)

        reference = cached_at2x(name, cache)
        exact, mean, worst = diff(two, reference) if reference is not None else (False,
                                                                                float("nan"), -1)
        proven = reference is not None and chrome_2x.proven(exact, mean, worst)
        halves = one.resize(box2, Image.LANCZOS)
        _, mean_same, _ = diff(halves, two)

        shipped = UI / f"{name}.png"
        shipped_note = "absent"
        if shipped.is_file():
            current = Image.open(shipped).convert("RGBA")
            _, mean_regression, _ = diff(one, current.resize(box1, Image.LANCZOS))
            shipped_note = (f"{current.size[0]}x{current.size[1]} "
                            f"({mean_regression:.1f} off the F.1 cut)")
        if not proven:
            failures += 1
        print(f"{name:28s} {str(cell.size):>11} {str(one.size):>8} {str(two.size):>8}  "
              f"{'exact' if exact else f'mean {mean:.4f} max {worst}':>22} "
              f"{mean_same:>12.4f}  {shipped_note}")

        rows.append({
            "file": name,
            "source_cell": source,
            "source_cell_size": list(cell.size),
            "cropped_box": list(cropped.size),
            "logical": list(box1),
            "at2x": list(box2),
            "at2x_vs_cache": {"exact": exact, "mean_abs_diff": round(mean, 4),
                              "max_abs_diff": worst, "proven": bool(proven)},
            "one_x_vs_at2x_halved_mean_abs_diff": round(mean_same, 4),
            "one_x_alpha": alpha_stats(one),
            "at2x_alpha": alpha_stats(two),
            "shipped_before": shipped_note,
            "md5": {"one_x": recover_ctex.digest(one), "at2x": recover_ctex.digest(two)},
        })
        if args.apply:
            OUT.mkdir(parents=True, exist_ok=True)
            one.save(OUT / f"{name}.png")
            two.save(OUT / f"{name}@2x.png")

    report = {"applied": args.apply, "families": len(slots),
              "at2x_proven_against_cache": len(slots) - failures, "rows": rows}
    REPORT.write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(f"\n{'APPLIED' if args.apply else 'DRY RUN'}: {len(slots)} families, "
          f"{len(slots) - failures} @2x proven against the cache, {failures} unproven")
    if args.apply:
        print(f"wrote {len(slots) * 2} files to {OUT.relative_to(ROOT)}")
    print(f"wrote {REPORT.relative_to(ROOT)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
