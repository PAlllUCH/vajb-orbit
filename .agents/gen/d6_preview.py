"""Scratch preview for D6: composite before/after insignia over a dark backdrop."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
BACKUP = HERE.parents[1] / "staging" / "phase_d" / "_fringe_backup"
CURRENT = HERE.parents[1] / "vajb-orbit" / "assets" / "ui"
OUT = HERE / "previews" / "d6_insignia_fringe.jpg"
BACKDROP = (13, 17, 23)
THUMB = 200
GAP = 12

FILES = ["ui_insignia_neutral.png", "ui_insignia_mic.png", "ui_insignia_ven.png", "ui_insignia_mmo.png"]


def composite(path: Path) -> Image.Image:
    arr = np.array(Image.open(path).convert("RGBA")).astype(np.float64)
    alpha = arr[..., 3:4] / 255.0
    bg = np.array(BACKDROP, dtype=np.float64)
    flat = arr[..., :3] * alpha + bg * (1.0 - alpha)
    ys, xs = np.where(arr[..., 3] > 0)
    crop = Image.fromarray(flat[ys.min():ys.max() + 1, xs.min():xs.max() + 1].astype(np.uint8), "RGB")
    scale = THUMB / max(crop.width, crop.height)
    return crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.LANCZOS)


def main() -> None:
    rows = []
    for name in FILES:
        pair = [composite(BACKUP / name), composite(CURRENT / name)]
        width = sum(p.width for p in pair) + GAP
        height = max(p.height for p in pair)
        row = Image.new("RGB", (width, height), BACKDROP)
        x = 0
        for p in pair:
            row.paste(p, (x, 0))
            x += p.width + GAP
        rows.append(row)
    width = max(r.width for r in rows)
    sheet = Image.new("RGB", (width, sum(r.height for r in rows) + GAP * (len(rows) - 1)), BACKDROP)
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + GAP
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT, quality=88)
    print(f"wrote {OUT} {sheet.width}x{sheet.height} left=before right=after")


if __name__ == "__main__":
    main()
