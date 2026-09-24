"""Author the three D6 masters the generator could not deliver, and rebuild the frame.

`UI_CHROME_ASSETS_SPEC` section 11 names four panels of eighteen cells. Measured 2026-09-24 (three
renders of the instrument panel: tasks fcadff98, f72d6e47, 001cb6bb; three of the frame pair:
e29c22b4, 8f5907f6, 942c2af1):

* the needle is always painted ONTO the dial face, never beside it, so no render yields a
  `ui_gauge_needle` object (the face is cleaned by `gauge_clean.py`);
* the frame and the glass are always fused into one bezel-and-screen object, so no render yields a
  separate `ui_readout_glass`.

Section 11's own fallback for a cell that mangles twice is the D2 route - hand-authored vector art
rasterised into the same file names - and that is what this script does for those two cells. Both
are flat display furniture in the fixed palette, so authoring them costs the family nothing:

* `ui_gauge_needle` 16x192: one slim tapered needle, pivot at its base, neutral steel (steel
  highlight `#565C63` lit face, gunmetal dark `#2B2F35` shadow face, ash text `#8D939B` edge
  catch), per section 11.
* `ui_readout_glass` 272x380: one soft dark plate with a chamfered edge, a panel steel border and a
  faint inner glow along its top edge, per section 11.

`ui_cockpit_frame` is rebuilt from the render: the bezel is there, so the nine-slice recipe (one
band width, painted band equal to the nine-slice margin) is applied to it exactly as
`staging/phase_f/reband_frame.py` applies it to the Phase F frame - 192 px with a 64 px band.

Usage:
    uv run --with pillow --with numpy --with scipy --with cairosvg python3 staging/phase_g/ui_authored.py
"""
from __future__ import annotations

from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = wave_g.STAGE
UI = STAGE / "ui"
SVG_DIR = UI / "_svg"
MASTERS = UI / "_masters"
FRAME_SOURCE = UI / "ui_cockpit_frame.png"
FRAME_BOX = 192
FRAME_BAND = FRAME_BOX // 3            # 64 px, section 11's table
SS = 4

# STYLE_BIBLE section 2 / UI_CHROME section 1.3, the only colours either piece may use.
PANEL_BLACK = "#15181D"
PANEL_STEEL = "#2A2E35"
GUNMETAL_DARK = "#2B2F35"
GUNMETAL_MID = "#3A3F46"
IRON_BLACK = "#232629"
STEEL_HIGHLIGHT = "#565C63"
ASH_TEXT = "#8D939B"

NEEDLE_SVG = f"""<svg xmlns="http://www.w3.org/2000/svg" width="16" height="192"
 viewBox="0 0 16 192">
  <g>
    <polygon points="5.1,186 3.3,72 6.4,12 8,4.5 9.6,12 12.7,72 10.9,186"
             fill="{STEEL_HIGHLIGHT}"/>
    <polygon points="8,4.5 9.6,12 12.7,72 10.9,186 8,186" fill="{GUNMETAL_DARK}"/>
    <polygon points="5.1,186 3.3,72 6.4,12 7.1,10 6.2,74 6.6,186" fill="{ASH_TEXT}"/>
    <polygon points="10.2,186 12.7,72 9.6,12 8.8,10 9.9,74 9.2,186" fill="{IRON_BLACK}"/>
    <circle cx="8" cy="185" r="3.6" fill="{GUNMETAL_MID}"/>
    <circle cx="8" cy="185" r="3.6" fill="none" stroke="{IRON_BLACK}" stroke-width="0.8"/>
    <circle cx="7.2" cy="184.2" r="1.1" fill="{ASH_TEXT}"/>
  </g>
</svg>
"""

GLASS_SVG = f"""<svg xmlns="http://www.w3.org/2000/svg" width="272" height="380"
 viewBox="0 0 272 380">
  <defs>
    <linearGradient id="body" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GUNMETAL_DARK}"/>
      <stop offset="0.16" stop-color="{PANEL_BLACK}"/>
      <stop offset="0.78" stop-color="{PANEL_BLACK}"/>
      <stop offset="1" stop-color="{IRON_BLACK}"/>
    </linearGradient>
    <linearGradient id="glow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GUNMETAL_MID}" stop-opacity="0.85"/>
      <stop offset="0.35" stop-color="{GUNMETAL_DARK}" stop-opacity="0.35"/>
      <stop offset="1" stop-color="{PANEL_BLACK}" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <polygon points="10,0 262,0 272,10 272,370 262,380 10,380 0,370 0,10"
           fill="url(#body)" stroke="{PANEL_STEEL}" stroke-width="1"/>
  <polygon points="4,3 268,3 268,16 4,16" fill="url(#glow)"/>
  <line x1="6" y1="2.5" x2="266" y2="2.5" stroke="{STEEL_HIGHLIGHT}" stroke-width="1"
        stroke-opacity="0.75"/>
  <line x1="4" y1="20" x2="268" y2="20" stroke="{PANEL_STEEL}" stroke-width="1"
        stroke-opacity="0.45"/>
</svg>
"""


def render_svg(svg: str, name: str, box: tuple[int, int]) -> Image.Image:
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    path = SVG_DIR / f"{name}.svg"
    path.write_text(svg, encoding="utf-8")
    import io
    png = cairosvg.svg2png(url=str(path), output_width=box[0] * SS, output_height=box[1] * SS)
    return Image.open(io.BytesIO(png)).convert("RGBA").resize(box, Image.LANCZOS)


def build_frame() -> tuple[Image.Image, dict]:
    import sys
    sys.path.insert(0, str(ROOT / "staging" / "phase_f"))
    import reband_frame
    source = Image.open(FRAME_SOURCE).convert("RGBA")
    master, box = reband_frame.opaque_crop(source)
    measured = reband_frame.measure_band(master)
    band = int(round(measured["mean"]))
    span = min(master.size)
    print(f"frame cut {source.size} -> opaque crop {master.size} (box {box})")
    print(f"  painted band per edge {measured['edges']} mean {measured['mean']:.1f} px "
          f"({100.0 * measured['mean'] / span:.1f} % of the span), "
          f"spread {100.0 * measured['spread']:.1f} %")
    if not (reband_frame.BAND_MIN_FRAC * span <= band <= reband_frame.BAND_MAX_FRAC * span):
        print(f"  REFUSED: band {band} px outside "
              f"{reband_frame.BAND_MIN_FRAC:.0%}-{reband_frame.BAND_MAX_FRAC:.0%} of the span")
        raise SystemExit(1)
    out = reband_frame.rebuild(master, band, FRAME_BOX)
    ## The render fused the frame and the glass into one object, so the master's interior is glass
    ## with a lit top edge. Section 2's recipe (and section 11's frame row) calls for an empty dark
    ## interior - the nine-patch centre is a panel black fill, so the frame reads as a bezel at every
    ## size instead of carrying one screen's highlight into a stretched block.
    centre = Image.new("RGBA", (FRAME_BOX - 2 * FRAME_BAND, FRAME_BOX - 2 * FRAME_BAND),
                       tuple(int(PANEL_BLACK[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    out.paste(centre, (FRAME_BAND, FRAME_BAND))
    drawn = reband_frame.drawn_band(out, FRAME_BAND)
    print(f"  rebuilt {FRAME_BOX}x{FRAME_BOX} at a {FRAME_BAND} px band; drawn band "
          f"vertical {drawn['vertical']} horizontal {drawn['horizontal']} (margin {FRAME_BAND})")
    return out, {"measured_band_px": measured["mean"],
                 "measured_band_pct": 100.0 * measured["mean"] / span,
                 "rebuilt_band_px": FRAME_BAND, "drawn": drawn, "edges": measured["edges"],
                 "spread": measured["spread"],
                 "centre": f"flat panel black {PANEL_BLACK} (section 2 recipe)"}


def main() -> int:
    if not FRAME_SOURCE.is_file():
        print(f"missing {FRAME_SOURCE}")
        return 1
    MASTERS.mkdir(parents=True, exist_ok=True)

    frame, frame_detail = build_frame()
    frame.save(MASTERS / "ui_cockpit_frame.png")
    report = {"ui_cockpit_frame": {"route": "nine-slice rebuild (reband_frame.py)",
                                   "box": [FRAME_BOX, FRAME_BOX], "frame": frame_detail}}

    needle = render_svg(NEEDLE_SVG, "ui_gauge_needle", (16, 192))
    needle.save(MASTERS / "ui_gauge_needle.png")
    report["ui_gauge_needle"] = {"route": "authored SVG (D2 route)", "box": [16, 192]}

    glass = render_svg(GLASS_SVG, "ui_readout_glass", (272, 380))
    glass.save(MASTERS / "ui_readout_glass.png")
    report["ui_readout_glass"] = {"route": "authored SVG (D2 route)", "box": [272, 380]}

    for name, box in (("ui_cockpit_frame", (FRAME_BOX, FRAME_BOX)),
                      ("ui_gauge_needle", (16, 192)), ("ui_readout_glass", (272, 380))):
        img = Image.open(MASTERS / f"{name}.png")
        print(f"  {name} {img.size} mode {img.mode}")
        if img.size != box:
            print(f"  WRONG BOX for {name}: {img.size} != {box}")
            return 1

    import json
    (UI / "authored_report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
