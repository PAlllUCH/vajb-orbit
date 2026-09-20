"""Phase F.1 Stage 1 probe: confirm the legacy panel cell -> icon name mapping.

The five Phase B panels (panel_weapons/cargo/glyphs) are the only re-cut sources
for the 20 legacy icon families, so the cell that maps to each name must be
proven, not assumed. Renders, per panel, the grid cells (with their reading
order index) next to the shipped 48 px cuts, so a human can confirm the pairing
that `recut_quartet.py` relies on.

Free, local, read-only. Writes staging/phase_f/_preview/legacy_cells_<panel>.png
and prints the maximum mask-IoU pairing found.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ASSETS = WORKSPACE / "vajb-orbit" / "assets" / "icons"
PREVIEW = WORKSPACE / "staging" / "phase_f" / "_preview"

PANELS = {
    "panel_weapons": dict(grid=(2, 3), names=[
        "icon_weapon_laser", "icon_weapon_cannon", "icon_weapon_rocket",
        "icon_weapon_mine", "icon_weapon_plasma", None]),
    "panel_cargo": dict(grid=(2, 3), names=[
        "icon_cargo_ore", "icon_cargo_crate", "icon_cargo_container",
        "icon_cargo_fuel_cell", "icon_cargo_salvage", "icon_cargo_data_core"]),
    "panel_glyphs": dict(grid=(3, 3), names=[
        "icon_gear", "icon_close", "icon_zoom_plus", "icon_zoom_minus",
        "icon_credits", "icon_shield", "icon_hull", "icon_ammo", "icon_logout"]),
}

BOX = 128
PAD = 6


def keyed(cell):
    """White background -> alpha; the panels are black-on-white flat glyphs."""
    arr = np.asarray(cell.convert("RGB")).astype("int16")
    dist = np.max(255 - arr, axis=2)
    alpha = np.clip(dist, 0, 255).astype("uint8")
    rgb = np.zeros(alpha.shape + (3,), "uint8")
    rgb[...] = 0x23
    return Image.fromarray(np.dstack([rgb, alpha]), "RGBA")


def bbox_of(img, thr=8, pad=10):
    mask = np.asarray(img)[:, :, 3] > thr
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        return None
    return (max(0, xs.min() - pad), max(0, ys.min() - pad),
            min(img.size[0], xs.max() + 1 + pad), min(img.size[1], ys.max() + 1 + pad))


def fit(img, box, nearest=False):
    img = img.convert("RGBA")
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    bg.alpha_composite(img)
    bg = bg.convert("RGB")
    bg.thumbnail((box, box), Image.LANCZOS)
    tile = Image.new("RGB", (box, box), (255, 255, 255))
    tile.paste(bg, ((box - bg.size[0]) // 2, (box - bg.size[1]) // 2))
    return tile


def main():
    for panel, spec in PANELS.items():
        cols, rows = spec["grid"]
        names = spec["names"]
        src = Image.open(ASSETS / f"{panel}.png").convert("RGB")
        w, h = src.size
        cells = []
        for row in range(rows):
            for col in range(cols):
                cells.append(src.crop((round(col * w / cols), round(row * h / rows),
                                       round((col + 1) * w / cols), round((row + 1) * h / rows))))
        sheet = Image.new("RGB", (PAD + len(cells) * (BOX + PAD), PAD + 3 * (BOX + 18 + PAD)), (24, 26, 30))
        draw = ImageDraw.Draw(sheet)
        for i, cell in enumerate(cells):
            x = PAD + i * (BOX + PAD)
            draw.text((x + 2, 4), f"cell {i + 1:02d}", fill=(210, 214, 219))
            sheet.paste(fit(cell, BOX), (x, 22))
        rowa = 22 + BOX + 18 + PAD
        for i, name in enumerate(names):
            x = PAD + i * (BOX + PAD)
            draw.text((x + 2, rowa - 16), (name or "(empty)")[:22], fill=(200, 205, 210))
            if name is None:
                continue
            shipped = Image.open(ASSETS / f"{name}_48.png").convert("RGBA")
            sheet.paste(fit(shipped, BOX, nearest=True), (x, rowa))
        rowb = rowa + BOX + 18 + PAD
        draw.text((PAD + 2, rowb - 16), "expected cell, white-keyed + trim(pad 10), 48 px", fill=(200, 205, 210))
        for i, name in enumerate(names):
            if name is None:
                continue
            k = keyed(cells[i])
            bb = bbox_of(k)
            if bb is None:
                continue
            cut = k.crop(bb).resize((48, 48), Image.LANCZOS)
            sheet.paste(fit(cut, BOX, nearest=True), (PAD + i * (BOX + PAD), rowb))
        PREVIEW.mkdir(parents=True, exist_ok=True)
        out = PREVIEW / f"legacy_cells_{panel}.png"
        sheet.save(out)

        # IoU pairing matrix: which cell each shipped cut actually resembles most.
        print(f"\n== {panel} {spec['grid']}  {out.name}")
        for i, name in enumerate(names):
            if name is None:
                continue
            sh = np.asarray(Image.open(ASSETS / f"{name}_48.png").convert("RGBA"))[:, :, 3] > 128
            scores = []
            for j, cell in enumerate(cells):
                k = keyed(cell)
                bb = bbox_of(k)
                if bb is None:
                    scores.append(0.0)
                    continue
                shrunk = k.crop(bb).resize((48, 48), Image.LANCZOS)
                m = np.asarray(shrunk)[:, :, 3] > 128
                scores.append(float((m & sh).sum() / max(1, (m | sh).sum())))
            order = sorted(range(len(scores)), key=lambda k_: -scores[k_])
            expected = i + 1
            flag = "OK " if order[0] == i else "?? "
            print(f"   {flag}{name:26s} expected cell {expected:2d}"
                  f"  best {[(k + 1, round(scores[k], 3)) for k in order[:3]]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
