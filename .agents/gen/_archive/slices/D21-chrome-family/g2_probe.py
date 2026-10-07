"""D21-G2 probe: measure the 16 chrome-family renders before any cutting.

Per render: size, mode, alpha-0 share, ink bbox at alpha thresholds 16/64/128,
and for the opaque four the border-strip colour (the background-strip key's
input). Data only - no writes outside the slice folder.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

WS = Path(__file__).resolve().parents[4]
RAW = WS / "asset-library" / "raw" / "chrome-family"

RUNS = {
    "C1": "20261005-201427", "C2": "20261005-201500", "C3": "20261005-201604",
    "C4": "20261005-201632", "C5": "20261005-201700", "C6": "20261005-201732",
    "C7": "20261005-202052", "C8": "20261005-202141", "C9": "20261005-202203",
    "C10": "20261005-202312", "C11": "20261005-202401", "C12": "20261005-202444",
    "BG-1": "20261005-202512", "BG-2": "20261005-202550",
    "BG-3": "20261005-202617", "BG-4": "20261005-203106",
}
FILE = "grimdark-painted-sci-fi-semi-realistic-1.png"


def bbox_at(alpha_img: Image.Image, threshold: int):
    hard = alpha_img.point(lambda a: 255 if a >= threshold else 0)
    return hard.getbbox()


def border_color(img: Image.Image, band: int = 24) -> dict:
    rgb = img.convert("RGB")
    w, h = rgb.size
    strips = [rgb.crop((0, 0, w, band)), rgb.crop((0, h - band, w, h)),
              rgb.crop((0, 0, band, h)), rgb.crop((w - band, 0, w, h))]
    counts: dict[tuple, int] = {}
    total = 0
    for s in strips:
        for px in s.getdata():
            counts[px] = counts.get(px, 0) + 1
            total += 1
    # median per channel from the pooled border sample
    rs = sorted(c[0] for c in counts for _ in range(counts[c]))
    gs = sorted(c[1] for c in counts for _ in range(counts[c]))
    bs = sorted(c[2] for c in counts for _ in range(counts[c]))
    mid = total // 2
    # cheap quantile: walk the sorted channel lists
    med = (rs[mid], gs[mid], bs[mid])
    # dominant exact colour + share within tolerance 12
    dom = max(counts.items(), key=lambda kv: kv[1])[0]
    near = sum(n for c, n in counts.items()
               if abs(c[0] - dom[0]) <= 12 and abs(c[1] - dom[1]) <= 12
               and abs(c[2] - dom[2]) <= 12)
    return {"median_rgb": med, "dominant_rgb": dom,
            "dominant_share": round(near / total, 3)}


out = {}
for rid, dir_name in RUNS.items():
    path = RAW / dir_name / FILE
    img = Image.open(path)
    rec = {"dir": dir_name, "size": img.size, "mode": img.mode}
    if img.mode == "RGBA":
        alpha = img.getchannel("A")
        hist = alpha.histogram()
        total = img.size[0] * img.size[1]
        rec["alpha0_share"] = round(hist[0] / total, 4)
        rec["alpha_le16"] = round(sum(hist[:17]) / total, 4)
        for t in (16, 64, 128):
            rec[f"bbox_ge{t}"] = bbox_at(alpha, t)
    else:
        rec["border"] = border_color(img)
    out[rid] = rec
    print(json.dumps({rid: rec}))

(WS / ".agents/gen/slices/D21-chrome-family/g2_probe.json").write_text(
    json.dumps(out, indent=1), encoding="utf-8")
print("wrote g2_probe.json")