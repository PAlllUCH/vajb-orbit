"""Measure whether the object in each keyed sprite sits on the centre of its canvas.

A cut sprite is supposed to have its object centred, and the cutter did that on the ink it could
see at cut time. Once the background is keyed away, the honest measure is the alpha bounding box:
where the visible object really is. This tool reports the offset between that box's centre and the
canvas centre for every sprite, flags the ones that are off by more than a tolerance, and (with
`--apply`) shifts the pixels so the box centre lands on the canvas centre. Nothing is guessed:
the shift is the measured offset, recorded per file in `_keying/center_shifts.json`.

Frames and bezels are reported like anything else: a symmetric frame measures centred because its
own box IS the canvas.

Usage:
    py -3.14 staging/cut/center_check.py --report            # table + summary + worst list
    py -3.14 staging/cut/center_check.py --report --scope ui # narrow it
    py -3.14 staging/cut/center_check.py --apply             # shift the off-centre ones
    py -3.14 staging/cut/center_check.py --apply --tolerance 2
"""
from __future__ import annotations

import argparse
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
KEYING = LIBRARY / "_keying"
REVIEW = LIBRARY / "_review"
REPORT = KEYING / "center_report.json"
SHIFTS = KEYING / "center_shifts.json"
LIMIT_BYTES = 200_000


def scope_paths(scope: str) -> list[Path]:
    cut = LIBRARY / "cut"
    if scope == "all":
        return sorted(cut.rglob("*.png"))
    return sorted((cut / scope).rglob("*.png"))


def measure(path: Path) -> dict | None:
    image = Image.open(path)
    if image.mode != "RGBA":
        return None
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    rows = np.flatnonzero(alpha.max(axis=1))
    cols = np.flatnonzero(alpha.max(axis=0))
    if rows.size == 0 or cols.size == 0:
        return {"empty": True}
    top, bottom = int(rows[0]), int(rows[-1])
    left, right = int(cols[0]), int(cols[-1])
    width, height = image.size
    centre_x = (left + right) / 2.0
    centre_y = (top + bottom) / 2.0
    offset_x = centre_x - (width - 1) / 2.0
    offset_y = centre_y - (height - 1) / 2.0
    return {
        "px": [width, height],
        "box": [left, top, right, bottom],
        "box_size": [right - left + 1, bottom - top + 1],
        "offset": [round(offset_x, 2), round(offset_y, 2)],
        "offset_px": [int(round(offset_x)), int(round(offset_y))],
        "centre_margin": [round(left / width, 3), round(top / height, 3),
                          round((width - 1 - right) / width, 3),
                          round((height - 1 - bottom) / height, 3)],
        "subject_pct": round(float((alpha > 0).mean()) * 100, 2),
    }


def build_sheet(entries: list[tuple[Path, dict]], out: Path, tile: int = 220, cols: int = 5) -> Path:
    rows = max(1, (len(entries) + cols - 1) // cols)
    canvas = Image.new("RGB", (cols * (tile + 10), rows * (tile + 16)), (18, 18, 22))
    draw = ImageDraw.Draw(canvas)
    for index, (path, record) in enumerate(entries):
        column, row = index % cols, index // cols
        x0 = column * (tile + 10) + 3
        y0 = row * (tile + 16) + 14
        cell = Image.new("RGBA", (tile, tile), (70, 72, 78, 255))
        thumb = Image.open(path).convert("RGBA").copy()
        thumb.thumbnail((tile, tile), Image.LANCZOS)
        cell.alpha_composite(thumb, ((tile - thumb.width) // 2, (tile - thumb.height) // 2))
        draw.line([(x0 + tile // 2, y0), (x0 + tile // 2, y0 + tile)], fill=(255, 90, 90), width=1)
        draw.line([(x0, y0 + tile // 2), (x0 + tile, y0 + tile // 2)], fill=(255, 90, 90), width=1)
        if not record.get("empty"):
            box = record["box"]
            scale = tile / max(record["px"])
            pad_x = (tile - record["px"][0] * scale) / 2
            pad_y = (tile - record["px"][1] * scale) / 2
            draw.rectangle([x0 + pad_x + box[0] * scale, y0 + pad_y + box[1] * scale,
                            x0 + pad_x + box[2] * scale, y0 + pad_y + box[3] * scale],
                           outline=(90, 220, 120))
        canvas.paste(cell.convert("RGB"), (x0, y0))
        draw.text((x0 + 2, y0 - 12), f"{path.stem[:34]}", fill=(225, 225, 225))
        if not record.get("empty"):
            off = record["offset_px"]
            draw.text((x0 + 2, y0 + tile - 12), f"off {off[0]:+d},{off[1]:+d}", fill=(255, 210, 120))
    buffer = io.BytesIO()
    working = canvas
    for _ in range(6):
        buffer = io.BytesIO()
        working.save(buffer, "JPEG", quality=76)
        if buffer.tell() <= LIMIT_BYTES:
            break
        working = working.resize((int(working.width * 0.85), int(working.height * 0.85)),
                                 Image.LANCZOS)
    out.write_bytes(buffer.getvalue())
    return out


def cmd_report(scope: str, tolerance: float, worst: int) -> None:
    rows = []
    for path in scope_paths(scope):
        record = measure(path)
        if record is None:
            continue
        rows.append((path, record))
    off = [(p, r) for p, r in rows
           if not r.get("empty")
           and (abs(r["offset"][0]) > tolerance or abs(r["offset"][1]) > tolerance)]
    empty = [p for p, r in rows if r.get("empty")]
    offsets = np.array([r["offset"] for _p, r in rows if not r.get("empty")])
    KEYING.mkdir(exist_ok=True)
    payload = {
        "scope": scope,
        "tolerance_px": tolerance,
        "sprites": len(rows),
        "centred": len(rows) - len(off) - len(empty),
        "off_centre": len(off),
        "empty_alpha": len(empty),
        "mean_offset": [round(float(offsets[:, 0].mean()), 2), round(float(offsets[:, 1].mean()), 2)],
        "max_offset": [round(float(np.abs(offsets[:, 0]).max()), 2),
                       round(float(np.abs(offsets[:, 1]).max()), 2)],
        "worst": sorted(
            [{"name": p.stem, "offset": r["offset"], "photo": str(p.relative_to(LIBRARY))}
             for p, r in off],
            key=lambda item: max(abs(item["offset"][0]), abs(item["offset"][1])), reverse=True)[:worst],
        "all": {p.stem: r for p, r in rows},
    }
    REPORT.write_text(json.dumps(payload, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"centering report ({scope}): {len(rows)} keyed sprites")
    print(f"  centred within {tolerance} px : {payload['centred']}")
    print(f"  off centre                 : {len(off)}")
    print(f"  empty alpha (needs a look) : {len(empty)}")
    print(f"  mean offset {payload['mean_offset']}  max {payload['max_offset']}")
    for item in payload["worst"][:25]:
        print(f"    {item['name']:38s} {item['offset']}")
    if off:
        worst_entries = [(LIBRARY / item["photo"],
                          next(r for p, r in rows if p.stem == item["name"])) for item in payload["worst"][:30]]
        sheet = build_sheet(worst_entries, REVIEW / f"peek_centers_{scope}.jpg")
        print(f"  worst-30 sheet -> {sheet.relative_to(LIBRARY)}")
    print(f"  full table -> {REPORT.relative_to(LIBRARY)}")


def cmd_apply(scope: str, tolerance: float) -> None:
    """Shift each off-centre object so its alpha box centre lands on the canvas centre.

    The shift is the NEGATIVE of the measured offset: an object measured 199 px above the
    canvas centre must move 199 px down. Applying the offset itself moves it further away and
    clips the far edge, so every write is re-measured and rolled back if the offset grew.
    """
    shifts_path = SHIFTS
    shifts = json.loads(shifts_path.read_text(encoding="utf-8")) if shifts_path.exists() else {}
    moved = 0
    rejected = 0
    for path in scope_paths(scope):
        record = measure(path)
        if record is None or record.get("empty"):
            continue
        dx, dy = -record["offset_px"][0], -record["offset_px"][1]
        if abs(dx) <= tolerance and abs(dy) <= tolerance:
            continue
        image = Image.open(path)
        if image.mode != "RGBA":
            continue
        alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
        rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
        height, width = alpha.shape
        shifted_alpha = np.zeros_like(alpha)
        shifted_rgb = np.zeros_like(rgb)
        src_x0, dst_x0 = (0, dx) if dx >= 0 else (-dx, 0)
        src_y0, dst_y0 = (0, dy) if dy >= 0 else (-dy, 0)
        span_x = width - abs(dx)
        span_y = height - abs(dy)
        if span_x <= 0 or span_y <= 0:
            continue
        shifted_alpha[dst_y0:dst_y0 + span_y, dst_x0:dst_x0 + span_x] = \
            alpha[src_y0:src_y0 + span_y, src_x0:src_x0 + span_x]
        shifted_rgb[dst_y0:dst_y0 + span_y, dst_x0:dst_x0 + span_x] = \
            rgb[src_y0:src_y0 + span_y, src_x0:src_x0 + span_x]
        out = np.dstack([shifted_rgb, shifted_alpha])
        before = np.asarray(image)
        Image.fromarray(out, "RGBA").save(path)
        after = measure(path)
        if after is None or after.get("empty") or (
                abs(after["offset"][0]) > abs(record["offset"][0]) + tolerance
                or abs(after["offset"][1]) > abs(record["offset"][1]) + tolerance):
            Image.fromarray(before, "RGBA").save(path)  # put the original bytes back
            rejected += 1
            continue
        shifts[str(path.relative_to(LIBRARY)).replace("\\", "/")] = {
            "was": record["offset"], "shift": [dx, dy], "px": [width, height]}
        moved += 1
    shifts_path.write_text(json.dumps(shifts, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"recentred {moved} sprite(s); {rejected} rejected and rolled back; "
          f"shifts in _keying/center_shifts.json")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--scope", default="all", help="all | ships | icons | env | ui | icons/alt ...")
    parser.add_argument("--tolerance", type=float, default=1.5)
    parser.add_argument("--worst", type=int, default=30)
    args = parser.parse_args()
    if args.apply:
        cmd_apply(args.scope, args.tolerance)
    elif args.report:
        cmd_report(args.scope, args.tolerance, args.worst)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
