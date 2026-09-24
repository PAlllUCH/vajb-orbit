"""D7-R1 independent AC5 re-measurement of the twelve `ui_seg_*` glyph-only cells.

Pillow only (no numpy/scipy on this host), reimplementing the verdict logic of
`staging/phase_g/qc_seg_digits.py` so the reviewer's numbers do not come from a re-run of the
worker's own tool. Run: `python3 vajb-orbit/tools/d7r1_ac5_seg.py`.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location(
    "seg_geometry", ROOT / "staging/phase_g/seg_geometry.py"
)
seg_geometry = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(seg_geometry)

LIT_THRESHOLD = 120.0
DILATE_PX = 2
CONTAINMENT_MIN = 0.95
CELLS = [f"ui_seg_{i}" for i in range(10)] + ["ui_seg_pct", "ui_seg_blank"]
DIR = ROOT / "vajb-orbit" / "assets" / "ui"

SEGMENTS = {f"ui_seg_{k}": len(v.split(",")) for k, v in seg_geometry.DIGIT_SEGMENTS.items()}
SEGMENTS["ui_seg_pct"] = len(seg_geometry.PCT_SEGMENTS.split(","))


def lum(p) -> float:
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def mask_alpha(im):
    a = im.getchannel("A")
    return [[a.getpixel((x, y)) > 8 for x in range(im.width)] for y in range(im.height)]


def band(im, lo, hi=None):
    out = []
    for y in range(im.height):
        row = []
        for x in range(im.width):
            v = lum(im.getpixel((x, y)))
            row.append(v >= lo and (hi is None or v < hi))
        out.append(row)
    return out


def and_m(a, b):
    return [[a[y][x] and b[y][x] for x in range(len(a[0]))] for y in range(len(a))]


def inset(w, h):
    ix, iy = max(2, w // 12), max(2, h // 14)
    return [[(iy <= y < h - iy) and (ix <= x < w - ix) for x in range(w)] for y in range(h)]


def bin_open(m, size=2):
    h, w = len(m), len(m[0])
    def erode(mm):
        return [[
            all(
                (0 <= y + dy < h and 0 <= x + dx < w and mm[y + dy][x + dx])
                for dy in range(size) for dx in range(size)
            )
            for x in range(w)
        ] for y in range(h)]
    def dilate(mm):
        return [[
            any(
                (0 <= y - dy < h and 0 <= x - dx < w and mm[y - dy][x - dx])
                for dy in range(size) for dx in range(size)
            )
            for x in range(w)
        ] for y in range(h)]
    return dilate(erode(m))


def pct(vals, p):
    s = sorted(vals)
    if not s:
        return 0.0
    k = (len(s) - 1) * p / 100.0
    f = int(k)
    c = min(f + 1, len(s) - 1)
    return s[f] + (s[c] - s[f]) * (k - f)


def ghost_region(blank):
    w, h = blank.width, blank.height
    inside = and_m(mask_alpha(blank), inset(w, h))
    lums = [lum(blank.getpixel((x, y))) for y in range(h) for x in range(w) if inside[y][x]]
    face, unlit = pct(lums, 20), pct(lums, 80)
    thr = (face + unlit) / 2.0
    ceiling = min(LIT_THRESHOLD, unlit + 12.0)
    ghost = bin_open(and_m(inside, band(blank, thr, ceiling)), 2)
    if sum(1 for r in ghost for v in r if v) < 40:
        field, src = (0, 0, w, h), "plate inner area"
    else:
        xs = [x for y in range(h) for x in range(w) if ghost[y][x]]
        ys = [y for y in range(h) for x in range(w) if ghost[y][x]]
        field, src = (min(xs), min(ys), max(xs) + 1, max(ys) + 1), "ghost ink"
    region = [[False] * w for _ in range(h)]
    boxes = []
    for name, (l, t, r, b) in seg_geometry.lattice(field).items():
        l, t = max(0, int(l) - DILATE_PX), max(0, int(t) - DILATE_PX)
        r, b = min(w, int(round(r)) + DILATE_PX), min(h, int(round(b)) + DILATE_PX)
        if r <= l or b <= t:
            continue
        boxes.append((name, l, t, r, b))
        for y in range(t, b):
            for x in range(l, r):
                region[y][x] = True
    return and_m(region, mask_alpha(blank)), boxes, src, field, face, unlit, thr


def measure(im, region):
    w, h = im.width, im.height
    plate = mask_alpha(im)
    plate_px = sum(1 for r in plate for v in r if v)
    lit = and_m(and_m(plate, inset(w, h)), band(im, LIT_THRESHOLD))
    lit_px = sum(1 for r in lit for v in r if v)
    inside = sum(1 for y in range(h) for x in range(w) if lit[y][x] and region[y][x])
    cont = (inside / lit_px) if lit_px else 1.0
    return plate_px, lit_px, (lit_px / plate_px if plate_px else 0.0), cont


def main() -> int:
    imgs = {n: Image.open(DIR / f"{n}.png").convert("RGBA") for n in CELLS}
    region, boxes, src, field, face, unlit, thr = ghost_region(imgs["ui_seg_blank"])
    print(f"reference blank: {len(boxes)} ghost boxes ({src}) field={field} "
          f"face={face:.1f} unlit={unlit:.1f} thr={thr:.1f}")
    print(f"{'cell':16s} {'size':>8s} {'trans%':>7s} {'plate':>6s} {'lit':>6s} "
          f"{'share':>8s} {'cont':>8s} verdict")
    shares = {}
    conts = {}
    for n in CELLS:
        im = imgs[n]
        tp = 100.0 * (
            1 - sum(1 for r in mask_alpha(im) for v in r if v) / (im.width * im.height)
        )
        plate_px, lit_px, share, cont = measure(im, region)
        shares[n], conts[n] = share, cont
        print(f"{n:16s} {im.width}x{im.height:<4d} {tp:7.2f} {plate_px:6d} {lit_px:6d} "
              f"{share:8.4f} {cont:8.4f} {'PASS' if cont >= CONTAINMENT_MIN else 'FAIL'}")
    digits = [f"ui_seg_{i}" for i in range(10)]
    literal_seq = [shares[f"ui_seg_{i}"] for i in range(1, 9)]
    literal_ok = all(literal_seq[i] <= literal_seq[i + 1] + 1e-9 for i in range(len(literal_seq) - 1))
    inversions = [
        f"{a}({SEGMENTS[a]}) > {b}({SEGMENTS[b]})"
        for a in digits for b in digits
        if SEGMENTS[a] < SEGMENTS[b] and shares[a] > shares[b] + 1e-9
    ]
    blank_min = shares["ui_seg_blank"] <= min(shares.values()) + 1e-9
    one_min = shares["ui_seg_1"] <= min(shares[d] for d in digits) + 1e-9
    eight_max = shares["ui_seg_8"] >= max(shares[d] for d in digits) - 1e-9
    cont_ok = all(v >= CONTAINMENT_MIN for v in conts.values())
    print("")
    print(f"containment >= 95% every cell: {'PASS' if cont_ok else 'FAIL'}")
    print(f"blank smallest: {'PASS' if blank_min else 'FAIL'} "
          f"(blank {shares['ui_seg_blank']:.4f}, next {sorted(shares.values())[1]:.4f})")
    print(f"1 smallest digit: {'PASS' if one_min else 'FAIL'} (1 {shares['ui_seg_1']:.4f})")
    print(f"8 largest digit: {'PASS' if eight_max else 'FAIL'} (8 {shares['ui_seg_8']:.4f})")
    print(f"no by-segment inversions: {'PASS' if not inversions else 'FAIL ' + str(inversions)}")
    print(f"literal 1<=..<=8: {'holds' if literal_ok else 'does not hold'}")
    print(f"AC5 verdict: {'PASS' if (cont_ok and blank_min and one_min and eight_max and not inversions) else 'FAIL'}")
    print("")
    for n in ("ui_seg_0", "ui_seg_8", "ui_seg_blank", "ui_seg_pct"):
        im = imgs[n]
        cols = {}
        for y in range(im.height):
            for x in range(im.width):
                p = im.getpixel((x, y))
                if p[3] > 200:
                    cols[(p[0], p[1], p[2])] = cols.get((p[0], p[1], p[2]), 0) + 1
        print(f"opaque palette {n}: {sorted(cols.items(), key=lambda kv: -kv[1])[:4]}")
    return 0 if (cont_ok and blank_min and one_min and eight_max and not inversions) else 1


if __name__ == "__main__":
    raise SystemExit(main())
