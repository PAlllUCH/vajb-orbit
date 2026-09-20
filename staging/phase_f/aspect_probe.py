"""Phase F.1 Stage 1 probe: is the shipped cut method aspect-correct?

The shipped pipeline (`wave_f.trim_to` -> `Image.resize((size, size))`) trims a
glyph to its alpha bounding box and then stretches that non-square box into a
square cut. This script renders a side-by-side proof for the worst offenders:
master (natural aspect), shipped square cut, and an aspect-preserving
contain-fit alternative, each nearest-upscaled 8x so the difference is visible.

Free, local, read-only. Writes staging/phase_f/_preview/aspect_probe.png.
"""

from pathlib import Path

from PIL import Image, ImageDraw

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets" / "icons"
PREVIEW = WORKSPACE / "staging" / "phase_f" / "_preview"

CASES = [
    "icon_module_w_railgun",
    "icon_ammo_laser",
    "icon_module_w_mining",
    "icon_module_h_plate_heavy",
    "icon_status_drained",
    "icon_contract_haul",
]
CELL = 200
ZOOM = 8


def contain(img, size):
    copy = img.copy()
    copy.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(copy, ((size - copy.size[0]) // 2, (size - copy.size[1]) // 2))
    return canvas


def on_white(img, size):
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    bg.alpha_composite(img)
    return bg.convert("RGB").resize((size, size), Image.NEAREST)


def main():
    rows = len(CASES)
    pad = 6
    label_h = 18
    cell = CELL
    width = pad + 3 * (cell + pad)
    height = pad + rows * (cell + label_h + pad)
    sheet = Image.new("RGB", (width, height), (24, 26, 30))
    draw = ImageDraw.Draw(sheet)

    for col, title in enumerate(("master (natural)", "shipped square cut", "contain-fit")):
        draw.text((pad + col * (cell + pad) + 4, 4), title, fill=(210, 214, 219))

    for row, name in enumerate(CASES):
        master = Image.open(ASSETS / f"{name}.png").convert("RGBA")
        shipped = Image.open(ASSETS / f"{name}_48.png").convert("RGBA")
        alt = contain(master, 48)
        y = pad + label_h + row * (cell + label_h + pad)
        draw.text((pad + 4, y - 14),
                  f"{name}  master {master.size[0]}x{master.size[1]}  "
                  f"ratio {master.size[0] / master.size[1]:.2f}",
                  fill=(200, 205, 210))
        for col, img in enumerate((master, shipped, alt)):
            x = pad + col * (cell + pad)
            sheet.paste(on_white(img, cell), (x, y))

    PREVIEW.mkdir(parents=True, exist_ok=True)
    out = PREVIEW / "aspect_probe.png"
    sheet.save(out)
    print(f"wrote {out} {sheet.size}")


if __name__ == "__main__":
    main()
