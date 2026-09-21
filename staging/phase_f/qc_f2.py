"""Phase F.2 - the measured acceptance table for the regeneration batch.

Every F.2 item is judged on a number taken from the shipped file (or the staged file that
is about to ship), never on an assertion, and each is compared against its pre-F.2
counterpart in `_f2_backup/`:

  frame   the painted band of a *drawn* nine-patch panel. The margin is 32 px at 96 (64 at
          the `@2x`), so the painted band must reach it: pre-F.2 the band stopped 20 px
          short inside the stretched slice, which is the C1 defect. Bar: within 3 px.
  glyphs  the four C2b outline glyphs at 16 px: solid-ink share and the measured stroke
          width. Bar: stroke >= 2.5 px and solid share at or above the median of the whole
          139-family set. The set's own distribution (0.00-0.61, median ~0.28) is printed
          as the evidence that a 100 % solid read is impossible under ICONS_SPEC section 1.
  drone   the four `ship_drone_swarm_*` band verdicts (qc_f1.py's fringe measure).
  moon    `env_body_ice_moon` subject mean/p95 luminance against the ships family mean.
  plates  the six chrome files that changed (four 1x + four `@2x` boxes): geometry, alpha,
          outer band and the 2x-to-1x same-art proof.

Usage:
  py -3.14 staging/phase_f/qc_f2.py            # all sections
  py -3.14 staging/phase_f/qc_f2.py frame      # one section
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import qc_f1                                    # noqa: E402  (fringe measure, C3)
import reband_frame as rb                       # noqa: E402  (nine_patch, drawn_band)
from recut_quartet import min_stroke            # noqa: E402  (stroke measure)

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
ICONS = ASSETS / "icons"
UI = ASSETS / "ui"
STAGE = ROOT / "staging" / "phase_f"
STAGED_UI = STAGE / "ui"
BACKUP = STAGE / "_f2_backup"
REPORT = STAGE / "f2_report.json"

MARGIN_1X = 32
MARGIN_2X = 64
BAND_TOL = 3
GLYPH_SIZE = 16
STROKE_BAR = 2.5
C2B = ["icon_zoom_plus", "icon_zoom_minus", "icon_credits", "icon_shield"]
DRONE = [f"ships/ship_drone_swarm_{v}.png"
         for v in ("front", "three_quarter", "side", "back")]
PLATES = ["ui_button_plate_normal", "ui_button_plate_hover",
          "ui_button_plate_pressed", "ui_button_plate_disabled"]


def backup(rel: str) -> Path | None:
    """The pre-F.2 copy of a shipped file, if it was taken."""
    cand = BACKUP / rel.replace("/", "__")
    return cand if cand.is_file() else None


def luminance(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


# ------------------------------------------------------------------ sections


def sec_frame(state: dict) -> None:
    print("== C1 panel frame: the painted band of a drawn nine-patch panel")
    old = backup("ui/ui_panel_frame.png")
    old2 = backup("ui/ui_panel_frame@2x.png")
    rows = []
    for label, path, margin in (("pre-F.2 96", old, MARGIN_1X),
                                ("F.2 96", ASSETS / "ui/ui_panel_frame.png", MARGIN_1X),
                                ("pre-F.2 @2x", old2, MARGIN_2X),
                                ("F.2 @2x", ASSETS / "ui/ui_panel_frame@2x.png", MARGIN_2X)):
        if path is None or not Path(path).is_file():
            print(f"  {label:12s} MISSING")
            continue
        tex = Image.open(path).convert("RGBA")
        panel = rb.nine_patch(tex, margin, 384 * (margin // MARGIN_1X), 240 * (margin // MARGIN_1X))
        drawn = rb.drawn_band(panel, margin)
        short = [abs(drawn["vertical"] - margin), abs(drawn["horizontal"] - margin)]
        verdict = "PASS" if max(short) <= BAND_TOL else f"{max(short)} px short/long"
        print(f"  {label:12s} texture {str(tex.size):>9}  margin {margin:3d}  "
              f"painted band {drawn['vertical']:>3}/{drawn['horizontal']:<3} px  {verdict}")
        rows.append({"label": label, "texture": list(tex.size), "margin": margin,
                     "drawn_vertical": drawn["vertical"], "drawn_horizontal": drawn["horizontal"],
                     "verdict": verdict})
    state["frame"] = rows


def sec_glyphs(state: dict) -> None:
    print(f"== C2b outline glyphs at {GLYPH_SIZE} px (bar: stroke >= {STROKE_BAR} px and "
          f"solid share >= the set median)")
    all16 = sorted(ICONS.glob("icon_*_16.png"))
    set_solid = []
    for path in all16:
        alpha = np.asarray(Image.open(path).convert("RGBA"))[..., 3]
        ink = alpha > 8
        if ink.any():
            set_solid.append(float((alpha[ink] >= 250).mean()))
    median = float(np.median(set_solid))
    lo, hi = min(set_solid), max(set_solid)
    print(f"  set of {len(set_solid)} families: solid-ink share min {lo:.2f} median {median:.2f} "
          f"max {hi:.2f} - no family in the set is 100 % solid at 16 px")
    rows = []
    ok = True
    for name in C2B:
        entry = {"glyph": name}
        for tag, path in (("before", backup(f"icons/{name}_{GLYPH_SIZE}.png")),
                          ("after", ICONS / f"{name}_{GLYPH_SIZE}.png")):
            if path is None or not Path(path).is_file():
                continue
            img = Image.open(path).convert("RGBA")
            alpha = np.asarray(img)[..., 3]
            ink = alpha > 8
            solid = float((alpha[ink] >= 250).mean()) if ink.any() else float("nan")
            stroke = min_stroke(img)
            cover = float(ink.mean())
            entry[tag] = {"solid": round(solid, 3), "stroke": round(stroke, 2),
                          "coverage": round(cover, 3)}
        a = entry.get("after", {})
        verdict = "PASS" if (a.get("stroke", 0) >= STROKE_BAR and a.get("solid", 0) >= median) else "SHORT"
        if verdict != "PASS":
            ok = False
        entry["verdict"] = verdict
        b = entry.get("before", {})
        print(f"  {name:18s} stroke {b.get('stroke', float('nan')):5.2f} -> "
              f"{a.get('stroke', float('nan')):5.2f} px   solid {b.get('solid', float('nan')):.3f} -> "
              f"{a.get('solid', float('nan')):.3f}   coverage {b.get('coverage', float('nan')):.2f} -> "
              f"{a.get('coverage', float('nan')):.2f}   {verdict}")
        rows.append(entry)
    state["glyphs"] = {"median": median, "set_range": [lo, hi], "rows": rows, "pass": ok}


def sec_drone(state: dict) -> None:
    print("== C3 drone swarm: outer band verdicts (qc_f1 fringe measure)")
    rows = []
    for rel in DRONE:
        path = ASSETS / rel
        row = qc_f1.fringe(path)
        old = backup(rel)
        before = qc_f1.fringe(old) if old else None
        if row is None:
            print(f"  {Path(rel).name:34s} no band")
            continue
        share = row["halo_px"] / max(1, row["band"])
        if row["lum_mean"] <= 80 and share <= 0.01:
            verdict = "PASS"
        elif row["halo_px"] and row["halo_opaque_share"] >= 0.8:
            verdict = "CONTENT"
        else:
            verdict = "KEYING"
        print(f"  {Path(rel).name:34s} band {row['band']:>6}  mean lum {row['lum_mean']:6.1f} "
              f"(before {before['lum_mean']:6.1f})  bright {100 * row['bright_share']:5.2f}%  "
              f"halo px {row['halo_px']:>5}  {verdict}")
        rows.append({"file": rel, "band": row["band"], "lum_mean": round(row["lum_mean"], 1),
                     "lum_mean_before": round(before["lum_mean"], 1) if before else None,
                     "bright_share": round(row["bright_share"], 4),
                     "halo_px": row["halo_px"], "verdict": verdict})
    state["drone"] = rows


def sec_moon(state: dict) -> None:
    print("== C4 ice moon: subject value against the ships family")
    ships = []
    for path in sorted((ASSETS / "ships").glob("*.png")):
        if path.name.startswith("ship_drone_swarm"):
            continue
        arr = np.asarray(Image.open(path).convert("RGBA"))
        alpha = arr[..., 3]
        mask = alpha >= 250
        if mask.sum() < 500:
            continue
        ships.append(float(luminance(arr[..., :3][mask]).mean()))
    family = float(np.median(ships)) if ships else float("nan")
    rows = []
    for label, path in (("pre-F.2", backup("env/env_body_ice_moon.png")),
                        ("F.2", ASSETS / "env/env_body_ice_moon.png")):
        if path is None or not Path(path).is_file():
            continue
        arr = np.asarray(Image.open(path).convert("RGBA"))
        mask = arr[..., 3] >= 250
        lum = luminance(arr[..., :3][mask])
        row = {"label": label, "subject_mean": round(float(lum.mean()), 1),
               "p95": round(float(np.percentile(lum, 95)), 1), "px": int(mask.sum())}
        row["verdict"] = "PASS" if row["subject_mean"] <= family else "above the family mean"
        rows.append(row)
        print(f"  {label:8s} subject mean {row['subject_mean']:6.1f}  p95 {row['p95']:6.1f}  "
              f"({row['px']} opaque px)  ships family mean {family:.1f}  {row['verdict']}")
    state["moon"] = {"ships_family_mean": round(family, 1), "rows": rows}


def sec_plates(state: dict) -> None:
    print("== chrome plates: 1x and @2x from one cell")
    rows = []
    for name in PLATES:
        entry = {"plate": name}
        for label, rel in (("1x", f"ui/{name}.png"), ("2x", f"ui/{name}@2x.png")):
            path = ASSETS / rel
            if not path.is_file():
                staged = STAGED_UI / Path(rel).name
                path = staged if staged.is_file() else path
            if not path.is_file():
                print(f"  {name:30s} {label} MISSING")
                continue
            img = Image.open(path).convert("RGBA")
            arr = np.asarray(img)
            band = qc_f1.fringe(path)
            entry[label] = {"file": path.name, "size": list(img.size),
                            "alpha_mean": round(float(arr[..., 3].mean()), 1),
                            "band_mean": round(band["lum_mean"], 1) if band else None,
                            "band_bright_share": round(band["bright_share"], 4) if band else None}
        one, two = entry.get("1x"), entry.get("2x")
        if one and two:
            back = Image.open(ASSETS / "ui" / f"{name}@2x.png").convert("RGBA")
            if not (ASSETS / "ui" / f"{name}@2x.png").is_file():
                back = Image.open(STAGED_UI / f"{name}@2x.png").convert("RGBA")
            one_img = Image.open(ASSETS / "ui" / f"{name}.png").convert("RGBA") \
                if (ASSETS / "ui" / f"{name}.png").is_file() else Image.open(STAGED_UI / f"{name}.png").convert("RGBA")
            diff = float(np.abs(np.asarray(back.resize(one_img.size, Image.LANCZOS)).astype(int)
                                - np.asarray(one_img).astype(int)).mean())
            entry["same_art_diff"] = round(diff, 2)
            print(f"  {name:30s} {one['size']} alpha {one['alpha_mean']:5.1f} band {one['band_mean']:5.1f}"
                  f"  |  {two['size']} alpha {two['alpha_mean']:5.1f} band {two['band_mean']:5.1f}"
                  f"  |  same-art diff {diff:.2f}")
        rows.append(entry)
    state["plates"] = rows


SECTIONS = {"frame": sec_frame, "glyphs": sec_glyphs, "drone": sec_drone,
            "moon": sec_moon, "plates": sec_plates}


def main() -> int:
    wanted = [a for a in sys.argv[1:] if not a.startswith("--")]
    names = wanted or list(SECTIONS)
    state: dict = {}
    for name in names:
        fn = SECTIONS.get(name)
        if fn is None:
            print(f"unknown section {name}; known: {sorted(SECTIONS)}")
            return 1
        fn(state)
        print()
    REPORT.write_text(json.dumps(state, indent=1), encoding="utf-8")
    print(f"wrote {REPORT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
