#!/usr/bin/env python3
"""Validate D2 Phase B SVG masters against the SVG source rule.

Hard errors: wrong root/viewBox, strokes, opacity < 1, forbidden elements
(text, image, gradients, filters, style), colours outside the sanctioned set,
more than two distinct colours, ember outside EMBER-OK files, implicit black.
Warnings: coordinates off the .5 grid, geometry outside the 0..96 canvas.

    python3 staging/d2/validate_svg.py [file.svg ...]   # default: staging/d2/svg/
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_worker_prompts import EMBER_OK  # noqa: E402

SVG_NS = "http://www.w3.org/2000/svg"
STEEL = {"#c9cdd2", "#8d939b", "#565c63", "#3a3f46", "#2b2f35", "#232629"}
EMBER = {"#c8461b", "#e8703a"}
ALLOWED = STEEL | EMBER
FORBIDDEN_TAGS = {"text", "image", "lineargradient", "radialgradient", "filter",
                  "style", "script", "marker", "mask", "foreignobject"}
FORBIDDEN_ATTRS = {"stroke", "stroke-width", "stroke-linecap", "stroke-linejoin",
                   "stroke-dasharray", "stroke-opacity", "filter", "style", "href"}

NUM_RE = re.compile(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?")


def check_file(path):
    errors, warnings = [], []
    name = os.path.basename(path)[:-4]
    try:
        root = ET.parse(path).getroot()
    except Exception as exc:
        return [f"XML does not parse: {exc}"], []

    tag = root.tag.split("}")[-1].lower()
    if tag != "svg":
        errors.append(f"root element is <{tag}>, expected <svg>")
    if root.get("viewBox") != "0 0 96 96":
        errors.append(f"viewBox is {root.get('viewBox')!r}, expected '0 0 96 96'")
    for attr in ("width", "height"):
        if root.get(attr) != "96":
            warnings.append(f"root {attr} is {root.get(attr)!r}, expected '96'")

    fills, nums = set(), []

    def walk(el, inherited):
        t = el.tag.split("}")[-1].lower()
        if t in FORBIDDEN_TAGS:
            errors.append(f"forbidden element <{t}>")
        for k, v in el.attrib.items():
            kl = k.split("}")[-1].lower()
            if kl in FORBIDDEN_ATTRS:
                errors.append(f"forbidden attribute {kl}={v!r} on <{t}>")
            if kl in ("opacity", "fill-opacity", "stroke-opacity"):
                try:
                    if float(v) < 1.0:
                        errors.append(f"opacity below 1 on <{t}>: {kl}={v}")
                except ValueError:
                    errors.append(f"unparseable {kl}={v!r} on <{t}>")
            if kl == "fill":
                if v.strip().lower() != "none":
                    fills.add(v.strip().lower())
            if kl == "d":
                nums.extend(float(x) for x in NUM_RE.findall(v))
        fill_here = el.attrib.get("fill", inherited)
        if fill_here is None and t in ("path", "rect", "circle", "ellipse", "polygon"):
            errors.append(f"<{t}> has no fill and no inherited fill (implicit black)")
        for child in el:
            walk(child, fill_here)

    walk(root, None)

    for f in sorted(fills):
        if f not in ALLOWED:
            errors.append(f"colour {f} outside the sanctioned set")
        if f in EMBER and name not in EMBER_OK:
            errors.append(f"ember colour {f} in a steel-only symbol")
    if len(fills) > 2:
        errors.append(f"{len(fills)} distinct colours, at most 2 allowed: {sorted(fills)}")

    offgrid = [x for x in nums if abs(x * 2 - round(x * 2)) > 1e-6]
    if offgrid:
        warnings.append(f"{len(offgrid)} path numbers off the .5 grid (e.g. {offgrid[:4]})")
    outside = [x for x in nums if x < -0.5 or x > 96.5]
    if outside:
        warnings.append(f"{len(outside)} path numbers outside the 0..96 canvas")
    return errors, warnings


def main():
    args = sys.argv[1:]
    if args:
        files = args
    else:
        d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")
        files = sorted(os.path.join(d, f) for f in os.listdir(d) if f.endswith(".svg"))
    bad = 0
    for path in files:
        errors, warnings = check_file(path)
        status = "FAIL" if errors else ("warn" if warnings else "PASS")
        if errors:
            bad += 1
        print(f"{status:4s} {os.path.basename(path)}")
        for e in errors:
            print(f"       ERROR {e}")
        for w in warnings:
            print(f"       warn  {w}")
    print(f"\n{len(files) - bad}/{len(files)} pass, {bad} fail")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
