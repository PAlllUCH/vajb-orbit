"""D21-G2 probe 2: border-strip colours of the four opaque renders + shipped
swap-target conventions (size, mode, alpha layout)."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

WS = Path(__file__).resolve().parents[4]
RAW = WS / "asset-library" / "raw" / "chrome-family"
UI = WS / "vajb-orbit" / "assets" / "ui"

OPAQUE = {"C2": "20261005-201500", "C8": "20261005-202141",
          "C11": "20261005-202401", "C12": "20261005-202444"}
FILE = "grimdark-painted-sci-fi-semi-realistic-1.png"
SHIPPED = ["ui_armory_console.png", "ui_slot_weapon_normal.png",
           "ui_slot_cargo_normal.png", "ui_slot_inventory_normal.png",
           "ui_bar_caps.png", "ui_minimap_bezel.png", "ui_panel_frame.png",
           "ui_backdrop_hangar.png"]


def border_stats(img: Image.Image, band: int = 24) -> dict:
    rgb = img.convert("RGB")
    w, h = rgb.size
    strips = [rgb.crop((0, 0, w, band)), rgb.crop((0, h - band, w, h)),
              rgb.crop((0, 0, band, h)), rgb.crop((w - band, 0, w, h))]
    px = []
    for s in strips:
        px.extend(s.get_flattened_data() if hasattr(s, "get_flattened_data")
                  else list(s.getdata()))
    rs = sorted(p[0] for p in px)
    gs = sorted(p[1] for p in px)
    bs = sorted(p[2] for p in px)
    mid = len(px) // 2
    med = (rs[mid], gs[mid], bs[mid])
    p90 = (rs[int(len(px) * 0.9)], gs[int(len(px) * 0.9)], bs[int(len(px) * 0.9)])
    p99 = (rs[int(len(px) * 0.99)], gs[int(len(px) * 0.99)], bs[int(len(px) * 0.99)])
    corners = [rgb.getpixel((2, 2)), rgb.getpixel((w - 3, 2)),
               rgb.getpixel((2, h - 3)), rgb.getpixel((w - 3, h - 3))]
    return {"median": med, "p90": p90, "p99": p99, "corners": corners}


out = {}
for rid, d in OPAQUE.items():
    img = Image.open(RAW / d / FILE)
    out[rid] = {"size": img.size, "border": border_stats(img)}
    print(rid, json.dumps(out[rid]))

out["shipped"] = {}
for name in SHIPPED:
    p = UI / name
    img = Image.open(p)
    rec = {"size": img.size, "mode": img.mode}
    if img.mode == "RGBA":
        a = img.getchannel("A")
        hist = a.histogram()
        total = img.size[0] * img.size[1]
        rec["alpha0"] = round(hist[0] / total, 3)
        rec["alpha255"] = round(hist[255] / total, 3)
        # alpha profile: centre row/col opacity (interior hole check)
        w, h = img.size
        centre = [a.getpixel((x, h // 2)) for x in (w // 4, w // 2, 3 * w // 4)]
        rec["centre_alpha"] = centre
        rec["bbox"] = a.point(lambda v: 255 if v > 8 else 0).getbbox()
    out["shipped"][name] = rec
    print(name, json.dumps(rec))

(WS / ".agents/gen/slices/D21-chrome-family/g2_probe2.json").write_text(
    json.dumps(out, indent=1, default=str), encoding="utf-8")
print("wrote g2_probe2.json")