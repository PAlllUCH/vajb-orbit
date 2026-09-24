"""The seven-segment geometry the D6 digit family is authored and measured against.

One source of truth for both halves of the AC5 fallback: `seg_svg_digits.py` rasterises the
segment layer from this lattice, and `qc_seg_digits.py` measures containment against the same
boxes. Keeping the geometry in one module is what makes the measurement honest - the QC cannot
drift from the art it checks.

`UI_CHROME_ASSETS_SPEC` section 11: cells are 20x36 logical, 48x88 master, lit segments Bone
`#C9CDD2`, unlit segments Panel Steel `#2A2E35`, ghost outline present in every cell.
"""
from __future__ import annotations

BOX = (48, 88)
SS = 4                       # supersample factor for the rasterised segment layer
LIT = "#C9CDD2"              # STYLE_BIBLE bone text
UNLIT = "#2A2E35"            # STYLE_BIBLE panel steel

DIGIT_SEGMENTS = {
    "0": "a,b,c,d,e,f",
    "1": "b,c",
    "2": "a,b,g,e,d",
    "3": "a,b,g,c,d",
    "4": "f,g,b,c",
    "5": "a,f,g,c,d",
    "6": "a,f,g,e,c,d",
    "7": "a,b,c",
    "8": "a,b,c,d,e,f,g",
    "9": "a,b,c,d,f,g",
}
## The percent cell in seven-segment strokes: the upper-left and lower-right marks read as the two
## dots and the middle bar as the stroke between them. No diagonal exists on a seven-segment face,
## which is why the generated slash could not pass containment. The set is deliberately not a
## digit: the first pass shipped `a,f,g,c,d`, which is exactly the digit 5.
PCT_SEGMENTS = "f,g,c"


def lattice(field: tuple[float, float, float, float]) -> dict[str, tuple[float, float, float, float]]:
    """The seven segment rectangles on a 3x3 lattice over `field` (left, top, right, bottom)."""
    x0, y0, x1, y1 = field
    width, height = x1 - x0, y1 - y0
    tx = max(2.0, 0.20 * width)       # vertical bar thickness
    ty = max(2.0, 0.15 * height)      # horizontal bar thickness
    gap = max(2.0, 0.09 * min(width, height))
    xm0, xm1 = x0 + tx + gap, x1 - tx - gap
    mid = y0 + height / 2.0
    return {
        "a": (xm0, y0, xm1, y0 + ty),
        "b": (xm1, y0 + ty + gap, x1, mid - gap / 2),
        "c": (xm1, mid + gap / 2, x1, y1 - ty - gap),
        "d": (xm0, y1 - ty, xm1, y1),
        "e": (x0, mid + gap / 2, x0 + tx, y1 - ty - gap),
        "f": (x0, y0 + ty + gap, x0 + tx, mid - gap / 2),
        "g": (xm0, mid - ty / 2, xm1, mid + ty / 2),
    }
