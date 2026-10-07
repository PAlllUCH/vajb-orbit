#!/usr/bin/env python3
"""D21-G2-F1: alpha-floor normalization on the 7 veiled chrome cuts (R1 F3).
Per pixel: alpha >= 200 -> 255; alpha < 200 byte-identical; RGB untouched.
Files edited in place at their landed stems; pre-fix bytes backed up first.
Verify: re-open each saved file and re-run R1's alpha-bucket probe.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
UI = WS / "vajb-orbit/assets/ui"
BK = WS / "asset-library/_prekey_backup/chrome_veil_prefix_2026-10-05"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUT = SLICE / "D21-G2-F1_evidence.json"
R1_EV5 = SLICE / "D21-G2-R1_evidence5.json"

NAMES = ["ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png",
         "ui_slot_inventory_normal.png", "ui_minimap_bezel.png",
         "ui_panel_frame.png", "ui_bar_caps.png", "ui_inline_chip.png"]
SLOTS = NAMES[:3]


def buckets(img):
    h = img.getchannel("A").histogram()
    tot = sum(h)
    return {"a0_pct": round(100.0 * h[0] / tot, 2),
            "a1_49": round(100.0 * sum(h[1:50]) / tot, 2),
            "a50_199": round(100.0 * sum(h[50:200]) / tot, 2),
            "a200_249": round(100.0 * sum(h[200:250]) / tot, 2),
            "a250_255": round(100.0 * sum(h[250:]) / tot, 2)}


def close(a, b, tol=0.05):
    return all(abs(a[k] - b[k]) <= tol for k in a)


lut = [255 if v >= 200 else v for v in range(256)]
r1 = json.loads(R1_EV5.read_text())["alpha_buckets"]
EV = {"files": {}, "c8_corners": {}, "reversal": str(BK)}
BK.mkdir(parents=True, exist_ok=True)

for name in NAMES:
    p = UI / name
    pre_bytes = p.read_bytes()
    img = Image.open(p)
    assert img.format == "PNG" and img.mode == "RGBA", (name, img.format, img.mode)
    rgba = img.convert("RGBA")
    before = buckets(rgba)
    if not close(before, r1[name]):
        EV["files"][name] = {"ABORT": "pre-fix buckets disagree with R1 evidence5",
                             "before": before, "r1": r1[name]}
        continue
    (BK / name).write_bytes(pre_bytes)
    a_before = rgba.getchannel("A")
    a_after = a_before.point(lut)
    fixed = rgba.copy()
    fixed.putalpha(a_after)

    # guard 1: RGB channels byte-identical
    for ch, bi, fi in zip("RGB", rgba.split(), fixed.split()):
        assert ImageChops.difference(bi, fi).getextrema() == (0, 0), (name, ch)
    # guard 2: per-pixel alpha rule (a<200 identical, a>=200 -> 255)
    bad_fringe = bad_floor = 0
    for b, f in zip(a_before.getdata(), a_after.getdata()):
        if b < 200:
            bad_fringe += f != b
        else:
            bad_floor += f != 255
    assert bad_fringe == 0 and bad_floor == 0, (name, bad_fringe, bad_floor)

    fixed.save(p, format="PNG")
    post = buckets(Image.open(p).convert("RGBA"))
    exp = dict(before)
    exp["a250_255"] = round(before["a250_255"] + before["a200_249"], 2)
    exp["a200_249"] = 0.0
    EV["files"][name] = {
        "size": list(img.size), "mode": img.mode,
        "md5_before": hashlib.md5(pre_bytes).hexdigest(),
        "md5_after": hashlib.md5(p.read_bytes()).hexdigest(),
        "before": before, "after": post,
        "expected_after": exp,
        "matches_expected": close(post, exp, tol=0.06),
        "matches_R1_before": close(before, r1[name]),
        "rgb_untouched": True, "alpha_rule_violations": 0}

    if name in SLOTS:
        w, h = img.size
        a2 = Image.open(p).convert("RGBA").getchannel("A")
        px_b, px_a = a_before.load(), a2.load()
        corners = {}
        for cx, cy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
            ring = [px_b[x, y] for x in range(max(0, cx - 1), min(w, cx + 2))
                    for y in range(max(0, cy - 1), min(h, cy + 2))]
            ring_a = [px_a[x, y] for x in range(max(0, cx - 1), min(w, cx + 2))
                      for y in range(max(0, cy - 1), min(h, cy + 2))]
            corners[f"({cx},{cy})"] = {"before_3x3": ring, "after_3x3": ring_a}
        soft_b = sum(1 for v in a_before.getdata() if 0 < v < 200)
        soft_a = sum(1 for v in a2.getdata() if 0 < v < 200)
        opaque = a2.point(lambda v: 255 if v == 255 else 0)
        EV["c8_corners"][name] = {
            "corners": corners,
            "sub200_px_before": soft_b, "sub200_px_after": soft_a,
            "sub200_unchanged": soft_a == soft_b,
            "opaque_bbox_after": opaque.getbbox(),
            "canvas": [w, h]}

OUT.write_text(json.dumps(EV, indent=1))
print(json.dumps(EV, indent=1))
