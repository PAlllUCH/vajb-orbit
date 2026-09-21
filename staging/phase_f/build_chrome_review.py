"""Phase G recovery - the R7 owner review sheet.

Every tile is the engine's own sampling, not an artist's impression:

  A  button plates   the theme's `StyleBoxTexture` stretches the whole texture into a
                     350x70 plate (measured 2026-09-21: the shipped cell renders its
                     plate 287.1 x 8.6 px, 90 % transparent). Shipped above, staged 1x
                     and @2x below.
  B  bar caps        the engine crops `(0,0,20,14)` and `(22,0,20,14)` from the texture.
                     Both windows are shown, from the shipped file and from the staged one.
  C  bezel + frame   the nine-patch textures at their logical box (200x200 and 96x96),
                     shipped against staged, with the F.2 band record beside them.
  D  logo            the frozen `AtlasTexture` crop `Rect2(44,707,1961,615)` drawn at the
                     560x176 the menu gives it, from the shipped file and from the staged
                     2048x2048 lockup.
  E  backdrop plates the four recovered 2048x1152 plates, as candidates for the station
                     panels (queue item 4) - a proposal, nothing here is staged to ship.

Usage: py -3.14 staging/phase_f/build_chrome_review.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_slot_review import BAD, DIM, GOOD, INK, VOID, font, on_void  # noqa: E402

STAGE = ROOT / "staging" / "phase_f"
SHIPPED = ROOT / "vajb-orbit" / "assets" / "ui"
STAGED = STAGE / "ui"
REC = STAGE / "_recover" / "ui_chrome"
OUT = STAGE / "_preview"
STATES = ("normal", "hover", "pressed", "disabled")
WIDTH = 2500   # every section is built on the widest sheet, so no caption is clipped


def plate_at(path: Path, size: tuple[int, int]) -> Image.Image:
    return on_void(Image.open(path).convert("RGBA").resize(size, Image.LANCZOS))


def nine_patch_box(anchor: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    """Godot draws a nine-patch by cutting the corners and stretching the edges and
    centre; the drawn result is what a screenshot of the panel shows, and it is what
    makes a 3 px band on a 200 px frame visible."""
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    width, height = anchor.size
    margin = min(margin, width // 2, height // 2)
    inner_out = (size[0] - 2 * margin, size[1] - 2 * margin)
    inner_src = (width - 2 * margin, height - 2 * margin)
    corners = ((0, 0), (width - margin, 0), (0, height - margin),
               (width - margin, height - margin))
    targets = ((0, 0), (size[0] - margin, 0), (0, size[1] - margin),
               (size[0] - margin, size[1] - margin))
    for source, target in zip(corners, targets):
        out.paste(anchor.crop((*source, source[0] + margin, source[1] + margin)),
                  target)
    for source_x, target_x in ((margin, margin), (width - 2 * margin,
                                                  size[0] - 2 * margin)):
        edge = anchor.crop((source_x, 0, source_x + inner_src[0], margin))
        out.paste(edge.resize((inner_out[0], margin), Image.LANCZOS),
                  (target_x, 0))
        edge = anchor.crop((source_x, height - margin, source_x + inner_src[0], height))
        out.paste(edge.resize((inner_out[0], margin), Image.LANCZOS),
                  (target_x, size[1] - margin))
    for source_y, target_y in ((margin, margin), (height - 2 * margin,
                                                  size[1] - 2 * margin)):
        edge = anchor.crop((0, source_y, margin, source_y + inner_src[1]))
        out.paste(edge.resize((margin, inner_out[1]), Image.LANCZOS),
                  (0, target_y))
        edge = anchor.crop((width - margin, source_y, width, source_y + inner_src[1]))
        out.paste(edge.resize((margin, inner_out[1]), Image.LANCZOS),
                  (size[0] - margin, target_y))
    out.paste(anchor.crop((margin, margin, width - margin, height - margin))
              .resize(inner_out, Image.LANCZOS), (margin, margin))
    return on_void(out)


def crop_window(path: Path, rect: tuple[int, int, int, int],
                size: tuple[int, int]) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    x, y, w, h = rect
    region = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    region.paste(image.crop((x, y, min(image.width, x + w), min(image.height, y + h))),
                 (0, 0))
    return on_void(region.resize(size, Image.LANCZOS))


def section_a() -> Image.Image:
    tile = (420, 84)
    header = 74
    sheet = Image.new("RGB", (WIDTH, header + 4 * 176), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "A  menu button plates: the theme stretches the texture into a "
                        "350x70 plate", font=font(25), fill=INK)
    draw.text((20, 44), f"shipped {json.loads((STAGE / 'recut_chrome_report.json').read_text(encoding='utf-8'))['rows'][0]['file']} "
                        f"cell 1041x1087 -> plate paints 287x9 px; staged 280x56 and "
                        f"560x112 drawn into the same plate",
              font=font(15), fill=DIM)
    y = header
    for state in STATES:
        name = f"ui_button_plate_{state}"
        views = [("shipped 1041x1087", crop_whole(SHIPPED / f"{name}.png", tile)),
                 ("staged 280x56", plate_at(STAGED / f"{name}.png", tile)),
                 ("staged @2x 560x112", plate_at(STAGED / f"{name}@2x.png", tile))]
        for column, (label, view) in enumerate(views):
            x = 20 + column * (tile[0] + 20)
            sheet.paste(view, (x, y))
            draw.text((x, y + tile[1] + 4), f"{state}  {label}", font=font(15),
                      fill=BAD if column == 0 else GOOD)
        y += tile[1] + 36
    return sheet


def crop_whole(path: Path, size: tuple[int, int]) -> Image.Image:
    return plate_at(path, size)


def section_b() -> Image.Image:
    header = 74
    rows = [
        ("ui_bar_caps  window (0,0,20,14) and (22,0,20,14)",
         lambda source: crop_window(source / "ui_bar_caps.png", (0, 0, 20, 14), (240, 168))
         .crop((0, 0, 240, 168))),
        ("ui_minimap_bezel  nine-patch 200x200, 16 px margins",
         lambda source: nine_patch_box(Image.open(source / "ui_minimap_bezel.png")
                                       .convert("RGBA"), (300, 300), 16)),
        ("ui_panel_frame  nine-patch 96x96, 32 px band",
         lambda source: nine_patch_box(Image.open(source / "ui_panel_frame.png")
                                       .convert("RGBA"), (300, 300), 32)),
    ]
    sheet = Image.new("RGB", (WIDTH, header + 3 * 366), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "B  chrome the engine samples directly: shipped (left) against "
                        "staged (right)", font=font(25), fill=INK)
    draw.text((20, 44), "drawn as the consumer draws it - the actual crop window, and the "
                        "actual nine-patch stretch", font=font(15), fill=DIM)
    y = header
    for label, render in rows:
        for column, (source, tone) in enumerate(((SHIPPED, BAD), (STAGED, GOOD))):
            view = render(source)
            x = 20 + column * 340
            sheet.paste(view, (x, y))
            draw.rectangle([x - 1, y - 1, x + view.width, y + view.height], outline=tone)
        draw.text((20, y + 306), label, font=font(16), fill=INK)
        y += 366
    return sheet


def section_c() -> Image.Image:
    header = 74
    display = (560, 176)
    sheet = Image.new("RGB", (WIDTH, header + display[1] + 120), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "C  wordmark: the frozen AtlasTexture crop Rect2(44,707,1961,615) "
                        "drawn at 560x176", font=font(25), fill=INK)
    draw.text((20, 44), "left: the file in assets/ today (2170x823 - the crop looks past "
                        "its bottom edge); right: the staged 2048x2048 lockup",
              font=font(15), fill=DIM)
    for column, (path, label, tone) in enumerate(
            ((SHIPPED / "logo_vajb_orbit.png", "shipped 2170x823", BAD),
             (STAGED / "logo_vajb_orbit.png", "staged 2048x2048", GOOD))):
        view = crop_window(path, (44, 707, 1961, 615), display)
        x = 20 + column * (display[0] + 30)
        sheet.paste(view, (x, header))
        draw.rectangle([x - 1, header - 1, x + display[0], header + display[1]],
                       outline=tone)
        draw.text((x, header + display[1] + 6), label, font=font(16), fill=tone)
    draw.text((20, header + display[1] + 34),
              "staged ink box 56,719..1993,1310 - the imprint IMPLEMENTATION_PLAN line 46 "
              "records (2048x2048, Rect2i(56,719,1937,591))", font=font(15), fill=DIM)
    return sheet


def section_d() -> Image.Image:
    header = 74
    plates = sorted((REC / "_plates").glob("*.png"))
    width = 396
    sheet = Image.new("RGB", (WIDTH, header + int(width * 9 / 16) + 60), VOID)
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 12), "D  station-panel backdrop candidates recovered from the cache "
                        "(queue item 4 - proposal only)", font=font(25), fill=INK)
    draw.text((20, 44), "2032x1152-class plates the cache still holds; nothing here is "
                        "staged or shipped", font=font(15), fill=DIM)
    height = int(width * 9 / 16)
    for index, path in enumerate(plates):
        view = Image.open(path).convert("RGB").resize((width, height), Image.LANCZOS)
        x = 20 + index * (width + 16)
        sheet.paste(view, (x, header))
        draw.rectangle([x - 1, header - 1, x + width, header + height], outline=DIM)
        draw.text((x, header + height + 6), path.name[:46], font=font(14), fill=INK)
    return sheet


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sections = [section_a(), section_b(), section_c(), section_d()]
    height = sum(s.height + 24 for s in sections)
    sheet = Image.new("RGB", (WIDTH, height), VOID)
    y = 0
    for section in sections:
        sheet.paste(section, (0, y))
        y += section.height + 24
    sheet.save(OUT / "review_chrome.png")
    print(f"wrote {OUT / 'review_chrome.png'} {sheet.size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
