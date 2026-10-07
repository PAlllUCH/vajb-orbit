#!/usr/bin/env python3
"""D21-G2-R1 probe 6: C7 recon (both sides composited over grey) + alpha buckets
for every landed cut vs the shipped backup convention."""
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
RAW = WS / "asset-library/raw/chrome-family"
UI = WS / "vajb-orbit/assets/ui"
BK = WS / "asset-library/_prekey_backup/chrome_family_2026-10-05"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-R1_evidence5.json"
EV = {}


def over_grey(img):
    bg = Image.new("RGBA", img.size, (96, 102, 108, 255))
    return Image.alpha_composite(bg, img.convert("RGBA")).convert("RGB")


raw7 = Image.open(RAW / "20261005-202052" / "grimdark-painted-sci-fi-semi-realistic-1.png").convert("RGBA")
rec7 = over_grey(raw7.resize((720, 480), Image.LANCZOS))
landed7 = Image.open(UI / "ui_tooltip_frame.png").convert("RGBA")
a2 = rec7.resize((160, 107), Image.BICUBIC)
best = None
for dx in range(-5, 6):
    for dy in range(-5, 6):
        base = Image.new("RGB", landed7.size, (96, 102, 108))
        base.paste(landed7, (dx, dy), landed7)
        b2 = base.resize((160, 107), Image.BICUBIC)
        dd = ImageChops.difference(a2, b2)
        st = ImageStat.Stat(dd)
        mean = sum(st.mean) / len(st.mean)
        if best is None or mean < best[0]:
            mx = max(e[1] for e in dd.getextrema())
            best = (mean, mx, dx, dy)
EV["c7_recon_composited"] = {"mean": round(best[0], 2), "max": round(best[1], 1),
                             "shift": [best[2], best[3]]}

EV["alpha_buckets"] = {}
NAMES = ["ui_inline_chip.png", "ui_row_strip.png", "ui_rack_bay_card.png",
         "ui_armory_console.png", "ui_tooltip_frame.png", "ui_bar_caps.png",
         "ui_minimap_bezel.png", "ui_panel_frame.png",
         "ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
         "ui_slot_inventory_normal.png"]
for name in NAMES:
    h = Image.open(UI / name).convert("RGBA").getchannel("A").histogram()
    tot = sum(h)
    EV["alpha_buckets"][name] = {
        "a0_pct": round(100.0 * h[0] / tot, 2),
        "a1_49": round(100.0 * sum(h[1:50]) / tot, 2),
        "a50_199": round(100.0 * sum(h[50:200]) / tot, 2),
        "a200_249": round(100.0 * sum(h[200:250]) / tot, 2),
        "a250_255": round(100.0 * sum(h[250:]) / tot, 2)}
for name in ("ui_bar_caps.png", "ui_panel_frame.png", "ui_minimap_bezel.png",
             "ui_slot_weapon_normal.png"):
    h = Image.open(BK / name).convert("RGBA").getchannel("A").histogram()
    tot = sum(h)
    EV["alpha_buckets"]["SHIPPED " + name] = {
        "a0_pct": round(100.0 * h[0] / tot, 2),
        "a1_49": round(100.0 * sum(h[1:50]) / tot, 2),
        "a50_199": round(100.0 * sum(h[50:200]) / tot, 2),
        "a200_249": round(100.0 * sum(h[200:250]) / tot, 2),
        "a250_255": round(100.0 * sum(h[250:]) / tot, 2)}

OUT.write_text(json.dumps(EV, indent=1))
print(json.dumps(EV, indent=1))
