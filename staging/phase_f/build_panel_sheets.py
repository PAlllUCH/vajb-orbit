"""Phase F review extras - no generation, existing chrome only.

1. One review sheet per station panel (SERVICES / EXCHANGE / REFINERY / AUCTION /
   SHIPYARD), proving the shipped `ui_panel_frame.png` nine-patch carries the
   station hub's panel sizes (STATION_HUB.md section 3.1, UI_SPEC.md 5.3) without
   rivet bleed into the edge bands or a broken corner.
2. The four-tier cargo tint table (16_art_design_brief P2, ICONS_SPEC 8.6) applied
   to the flat ore/container stencils, on the panel black background the HUD uses.

Output: staging/phase_f/_preview/<name>.png
Run:    py -3.14 staging/phase_f/build_panel_sheets.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
OUT = ROOT / "staging" / "phase_f" / "_preview"

FRAME = ASSETS / "ui" / "ui_panel_frame.png"
FRAME_MARGIN = 32

BG = (17, 24, 35)
BOX = (42, 49, 60)
HDR = (223, 226, 230)
NOTE = (138, 147, 160)
INK = (201, 205, 210)
ACCENT = (245, 246, 248)

FONT_DIR = "C:/Windows/Fonts"


def font(name, size):
    try:
        return ImageFont.truetype(f"{FONT_DIR}/{name}", size)
    except OSError:
        return ImageFont.load_default(size)


F_TITLE = font("consolab.ttf", 24)
F_LEG = font("consola.ttf", 14)
F_LBL = font("consola.ttf", 12)

# name -> (host width, host height) measured in STATION_HUB.md section 3.1
PANELS = {
    "services": (1497, 858, "SERVICES - the service deck rail entry / panel host"),
    "exchange": (1497, 858, "EXCHANGE - module host panel"),
    "refinery": (1497, 858, "REFINERY - module host panel"),
    "auction": (1497, 858, "AUCTION - module host panel"),
    "shipyard": (1497, 858, "SHIPYARD - module host panel"),
}

SIZES = {
    "Module rail": (361, 858),
    "Preview frame": (652, 580),
    "Credits housing": (187, 124),
    "Leave dialog": (520, 240),
}

TIERS = [
    ("T1", "#565C63", "Steel Highlight"),
    ("T2", "#8D939B", "Ash Text (bright steel)"),
    ("T3", "#8A6A50", "Dry Rust"),
    ("T4", "#6E5B4A", "Rusted Ochre (ember-adjacent)"),
]


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def nine_patch(src, width, height, margin=FRAME_MARGIN):
    """Compose src as a nine-patch at width x height, engine STRETCH semantics."""
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    m = margin
    sw, sh = src.size
    corners = {
        (0, 0): (0, 0, m, m),
        (width - m, 0): (sw - m, 0, sw, m),
        (0, height - m): (0, sh - m, m, sh),
        (width - m, height - m): (sw - m, sh - m, sw, sh),
    }
    for pos, box in corners.items():
        out.paste(src.crop(box), pos)
    bands = [
        ((m, 0, sw - m, m), (m, 0, width - m, m)),
        ((m, sh - m, sw - m, sh), (m, height - m, width - m, height)),
        ((0, m, m, sh - m), (0, m, m, height - m)),
        ((sw - m, m, sw, sh - m), (width - m, m, width, height - m)),
        ((m, m, sw - m, sh - m), (m, m, width - m, height - m)),
    ]
    for src_box, dst_box in bands:
        w = max(1, dst_box[2] - dst_box[0])
        h = max(1, dst_box[3] - dst_box[1])
        out.paste(src.crop(src_box).resize((w, h), Image.LANCZOS), (dst_box[0], dst_box[1]))
    return out


def zoom(img, box, factor):
    crop = img.crop(box)
    return crop.resize((crop.width * factor, crop.height * factor), Image.NEAREST)


def panel_sheet(name, size, label):
    width, height = size
    src = Image.open(FRAME).convert("RGBA")
    chrome = nine_patch(src, width, height)

    pad = 24
    col_gap = 24
    zoom_px = 220
    canvas_w = pad * 3 + width + zoom_px * 2 + col_gap
    canvas_h = max(height, 460) + 150
    canvas = Image.new("RGBA", (canvas_w, canvas_h), BG + (255,))
    draw = ImageDraw.Draw(canvas)

    draw.text((pad, 16), f"Vajb Orbit - station panel chrome: {name.upper()}", font=F_TITLE, fill=HDR)
    draw.text((pad, 50), f"{label}  |  chrome: res://assets/ui/ui_panel_frame.png (96x96, 32 px frame, "
                         f"nine-patch)  |  target {width}x{height}", font=F_LEG, fill=NOTE)

    cx, cy = pad, 84
    draw.rectangle((cx - 1, cy - 1, cx + width + 1, cy + height + 1), outline=BOX)
    canvas.alpha_composite(chrome, (cx, cy))

    # the engine inset the coding pass has to live with (STATION_HUB 3.4)
    inner = FRAME_MARGIN + 1
    draw.rectangle((cx + inner, cy + inner, cx + width - inner, cy + height - inner),
                   outline=(70, 78, 90))
    draw.text((cx + inner + 6, cy + inner + 4), f"content inset {inner} px", font=F_LBL, fill=NOTE)

    # zoom column: the four corners and the two edge bands, cropped to the corner /
    # band only (32 px of source), so a bleed shows up as non-uniform band pixels
    zx = cx + width + col_gap
    zooms = [
        ("top-left corner 4x", (0, 0, 32, 32)),
        ("top edge band 4x (uniform left to right)", (32, 0, 64, 32)),
        ("bottom-left corner 4x", (0, 64, 32, 96)),
        ("left edge band 4x (uniform top to bottom)", (0, 32, 32, 64)),
    ]
    for i, (text, box) in enumerate(zooms):
        ox = zx + (i % 2) * (zoom_px + 12)
        oy = cy + (i // 2) * 260
        draw.text((ox, oy), text, font=F_LBL, fill=NOTE)
        tile = zoom(src, box, 4)
        canvas.alpha_composite(tile, (ox, oy + 16))
        draw.rectangle((ox - 1, oy + 15, ox + tile.width + 1, oy + 17 + tile.height), outline=BOX)

    # other consumers of the same chrome, one row
    by = cy + height + 26
    bx = pad
    for label_, (w, h) in SIZES.items():
        small = nine_patch(src, w, h)
        draw.text((bx, by - 16), f"{label_} {w}x{h}", font=F_LBL, fill=NOTE)
        canvas.alpha_composite(small, (bx, by))
        bx += w + 20

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"panel_{name}.png"
    canvas.convert("RGB").save(path)
    print(f"{path.name}: {canvas_w}x{canvas_h}")
    return path


def tint_sheet():
    arts = [
        ("icon_cargo_ore_48", Image.open(ASSETS / "icons/tint/icon_cargo_ore_48.png").convert("RGBA")),
        ("icon_cargo_container_48", Image.open(ASSETS / "icons/tint/icon_cargo_container_48.png").convert("RGBA")),
    ]
    cell = 300
    pad = 24
    row_h = cell + 46
    canvas_w = pad + cell + pad + len(TIERS) * (cell + pad)
    canvas_h = 84 + 2 * row_h + pad
    canvas = Image.new("RGBA", (canvas_w, canvas_h), BG + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 16), "Vajb Orbit - cargo glyph tier tints (16_art_design_brief P2 / ICONS_SPEC 8.6)",
              font=F_TITLE, fill=HDR)
    draw.text((pad, 50), "steel -> bright steel -> ochre -> ember-adjacent. The accent pair #C8461B / #E8703A is "
                         "never used: the tint is a palette modulate over the white stencil.",
              font=F_LEG, fill=NOTE)

    for col, (tier, hexv, palette_name) in enumerate(TIERS):
        hx = pad + cell + pad + col * (cell + pad)
        draw.text((hx, 84), f"{tier}  {hexv}  {palette_name}", font=F_LEG, fill=INK)

    for row, (name, art) in enumerate(arts):
        y = 108 + row * row_h
        draw.text((pad + 6, y + 8), name, font=F_LEG, fill=NOTE)
        draw.text((pad + 6, y + 28), f"slot art, native 48", font=F_LBL, fill=NOTE)
        for col, (_tier, hexv, _p) in enumerate(TIERS):
            hx = pad + cell + pad + col * (cell + pad)
            slot = 96
            # a HUD slot plate behind the tinted glyph, on panel black
            draw.rectangle((hx, y, hx + cell // 2 - 8, y + cell // 2 - 8), fill=(21, 24, 29))
            draw.rectangle((hx, y + cell // 2, hx + cell // 2 - 8, y + cell - 8), fill=(21, 24, 29))
            for idx, scale in enumerate((48, 16)):
                bx = hx
                by = y + idx * (cell // 2)
                plate = cell // 2 - 8
                tinted = Image.new("RGBA", (scale, scale), hex_rgb(hexv) + (0,))
                small = art.resize((scale, scale), Image.LANCZOS)
                tinted.putalpha(small.getchannel("A"))
                canvas.alpha_composite(tinted, (bx + (plate - scale) // 2, by + (plate - scale) // 2))
                draw.rectangle((bx, by, bx + plate, by + plate), outline=BOX)
                draw.text((bx + plate + 8, by + plate // 2 - 8), f"{scale} px", font=F_LBL, fill=NOTE)
            _ = slot

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "tier_tints.png"
    canvas.convert("RGB").save(path)
    print(f"{path.name}: {canvas_w}x{canvas_h}")
    return path


def main():
    for name, (w, h, label) in PANELS.items():
        panel_sheet(name, (w, h), label)
    tint_sheet()


if __name__ == "__main__":
    main()
