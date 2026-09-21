"""Contact sheets for the Phase G lane, small enough for the 200 KB image viewer.

One page per family by default: every cut of a run, labelled with its file name and its trimmed
size, on a checkerboard so alpha is visible. `--sheet <path>` adds the full render behind the
cuts, which is how a 2x2 rotation sheet is checked for orientation before anything ships.

Usage:
    py -3.14 staging/phase_g/build_review.py                      # every family
    py -3.14 staging/phase_g/build_review.py --family ships --only ship_swarmer
    py -3.14 staging/phase_g/build_review.py --sheet <render.png>
"""
from __future__ import annotations

import argparse
import io
from pathlib import Path

from PIL import Image, ImageDraw

import wave_g

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_g"
REVIEW = STAGE / "_review"
FAMILIES = ("ships", "fx")


def checker(size: tuple[int, int], step: int = 16) -> Image.Image:
    img = Image.new("RGB", size, (46, 46, 50))
    draw = ImageDraw.Draw(img)
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2 == 0:
                draw.rectangle([x, y, x + step - 1, y + step - 1], fill=(62, 62, 68))
    return img


def build(family: str, only: str = "", cell: int = 256, cols: int = 4) -> Path | None:
    retired = {run_id for run_id, spec in wave_g.RUNS.items() if spec.get("ships") is False}
    paths = sorted(p for p in (STAGE / family).glob("*.png")
                   if not p.stem.endswith("-keyed") and p.stem not in retired
                   and (not only or only in p.stem))
    if not paths:
        print(f"{family}: nothing to review")
        return None
    rows = (len(paths) + cols - 1) // cols
    sheet = checker((cols * cell, rows * cell))
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(paths):
        img = Image.open(path).convert("RGBA")
        img.thumbnail((cell - 18, cell - 30), Image.LANCZOS)
        col, row = index % cols, index // cols
        x = col * cell + (cell - img.size[0]) // 2
        y = row * cell + 20 + (cell - 20 - img.size[1]) // 2
        sheet.paste(img, (x, y), img)
        original = Image.open(path).size
        draw.text((col * cell + 4, row * cell + 4), f"{path.stem}  {original[0]}x{original[1]}",
                  fill=(205, 205, 210))
    REVIEW.mkdir(parents=True, exist_ok=True)
    out = REVIEW / f"g_{family}{'_' + only if only else ''}.jpg"
    ## Sizes are measured in memory, not with `stat`: this mount's stat lags a fresh write, which
    ## made the first version of this loop miss a 204 KB page entirely.
    def encoded(image: Image.Image, quality: int) -> bytes:
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=quality)
        return buffer.getvalue()

    payload = encoded(sheet, 74)
    for quality in (82, 74, 66, 58, 50):
        payload = encoded(sheet, quality)
        if len(payload) <= 195_000:
            break
    while len(payload) > 195_000 and sheet.size[0] > 320:
        ## The image viewer refuses a decode past ~200 KB; shrink rather than fail on a big page.
        sheet = sheet.resize((int(sheet.size[0] * 0.85), int(sheet.size[1] * 0.85)), Image.LANCZOS)
        payload = encoded(sheet, 74)
    out.write_bytes(payload)
    print(f"{out.relative_to(ROOT)}  {sheet.size}  {len(payload) / 1000:.0f} KB  "
          f"{len(paths)} file(s)")
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--family", default="")
    parser.add_argument("--only", default="")
    parser.add_argument("--sheet", default="")
    args = parser.parse_args()
    for family in ([args.family] if args.family else FAMILIES):
        build(family, args.only)
    if args.sheet:
        render = Path(args.sheet)
        if render.is_file():
            img = Image.open(render).convert("RGB")
            img.thumbnail((560, 560), Image.LANCZOS)
            out = REVIEW / f"g_render_{render.stem[:40]}.jpg"
            img.save(out, quality=74)
            print(f"{out.relative_to(ROOT)}  {img.size}  {out.stat().st_size / 1000:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
