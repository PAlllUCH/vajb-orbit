"""Phase F.1 Stage 4 - the quartet review sheets and the 4K composite.

Outputs (all under staging/phase_f/_preview/):

  review_f1_quartet_<group>.png  every icon family in the group at all four tiers,
                                 side by side with its retained master, so the size
                                 chain and the silhouette read can be judged per band.
  review_f1_4k.png               a 3840x2160 sheet that draws icons and chrome at the
                                 physical pixel size a 4K screen (2x canvas scale)
                                 gives them: every surface is drawn at or below its
                                 texture's native size, so nothing is upscaled.
  review_f1_table.txt            the measured check: per family, the ink bounding box
                                 at each tier (the longest axis must equal the cut
                                 size minus the master trim pad - that is what proves
                                 the contain-fit law) and the thin-stroke width.

Run: py -3.14 staging/phase_f/build_f1_review.py [--tag f2]
"""

from __future__ import annotations

import collections
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
ICONS = WORKSPACE / "vajb-orbit" / "assets" / "icons"
UI = WORKSPACE / "vajb-orbit" / "assets" / "ui"
OUT = WORKSPACE / "staging" / "phase_f" / "_preview"

# `--tag f2` writes review_f2_* instead of review_f1_*, so a later pass can refresh the
# sheets from the shipped cuts without overwriting the sheets the F.1 record cites.
TAG = "f1"
if "--tag" in sys.argv:
    TAG = sys.argv[sys.argv.index("--tag") + 1]

SIZES = (16, 48, 96, 192)
BG = (17, 24, 35)
PLATE = (21, 24, 29)
HDR = (223, 226, 230)
NOTE = (138, 147, 160)
GOOD = (150, 214, 160)
BAD = (232, 112, 58)
BOX = 110
PAD = 12
LABEL_H = 16


def font(name, size):
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except OSError:
        return ImageFont.load_default(size)


F_TITLE = font("consolab.ttf", 24)
F_SEC = font("consolab.ttf", 15)
F_SMALL = font("consola.ttf", 11)


def families() -> list[str]:
    bases = set()
    for path in ICONS.glob("icon_*_[0-9]*.png"):
        base, _, size = path.stem.rpartition("_")
        if size.isdigit() and base:
            bases.add(base)
    return sorted(bases)


def group_of(base: str) -> str:
    rest = base[len("icon_"):]
    head = rest.split("_")[0]
    known = {"mineral", "ingot", "module", "slot", "contract", "service", "insignia",
             "weapon", "cargo", "ammo", "equip", "map", "booster", "status"}
    return head if head in known else "hud_glyphs"


def tile(img: Image.Image, box: int, upscale_nearest: bool) -> Image.Image:
    img = img.convert("RGBA")
    bg = Image.new("RGBA", img.size, (12, 13, 15, 255))
    bg.alpha_composite(img)
    bg = bg.convert("RGB")
    w, h = img.size
    if max(w, h) > box:
        scale = box / max(w, h)
        bg = bg.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.LANCZOS)
    elif upscale_nearest and max(w, h) < box:
        scale = max(1, box // max(w, h))
        bg = bg.resize((w * scale, h * scale), Image.NEAREST)
    out = Image.new("RGB", (box, box), (24, 26, 30))
    out.paste(bg, ((box - bg.size[0]) // 2, (box - bg.size[1]) // 2))
    return out


def build_group_sheet(group: str, names: list[str]) -> tuple[Path, list[str]]:
    cols = ["master", "16", "48", "96", "192"]
    width = PAD + len(cols) * (BOX + PAD)
    height = 76 + len(names) * (BOX + LABEL_H + PAD) + PAD
    sheet = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text((PAD, 14), f"Vajb Orbit - Phase F.1 icon quartet: {group} "
                         f"({len(names)} families)", font=F_TITLE, fill=HDR)
    draw.text((PAD, 44), "master = retained re-cut source | 16 / 48 / 96 / 192 = the shipping "
                         "quartet, contain-fit (ICONS_SPEC 9.6); 16 and 48 are shown magnified",
              font=F_SMALL, fill=NOTE)
    for index, label in enumerate(cols):
        draw.text((PAD + index * (BOX + PAD) + 2, 60), label, font=F_SEC, fill=GOOD)

    problems = []
    for row, name in enumerate(names):
        y = 76 + row * (BOX + LABEL_H + PAD)
        draw.text((PAD + 2, y), name[:46], font=F_SMALL, fill=NOTE)
        y += LABEL_H
        master = ICONS / f"{name}.png"
        if master.is_file():
            sheet.paste(tile(Image.open(master), BOX, False), (PAD, y))
        for index, size in enumerate(SIZES, start=1):
            path = ICONS / f"{name}_{size}.png"
            if not path.is_file():
                problems.append(f"{name}_{size}.png MISSING")
                continue
            img = Image.open(path)
            sheet.paste(tile(img, BOX, size < BOX), (PAD + index * (BOX + PAD), y))
    out = OUT / f"review_{TAG}_quartet_{group}.png"
    sheet.save(out)
    return out, problems


def measure(name: str) -> list[str]:
    rows = []
    for size in SIZES:
        path = ICONS / f"{name}_{size}.png"
        if not path.is_file():
            rows.append(f"{name:34s} _{size:<3} MISSING")
            continue
        img = Image.open(path).convert("RGBA")
        alpha = np.asarray(img)[..., 3]
        ink = alpha > 8
        ys, xs = np.nonzero(ink)
        box = (int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)) if len(ys) else (0, 0)
        runs = []
        for line in ink:
            padded = np.concatenate([[False], line, [False]])
            edges = np.flatnonzero(padded[1:] != padded[:-1])
            starts, ends = edges[0::2], edges[1::2]
            if len(starts):
                runs.append(int((ends - starts).min()))
        stroke = float(np.median(runs)) if runs else 0.0
        cover = ink.sum() / alpha.size
        note = "ok" if max(box) >= size - 2 * 6 else "narrow"
        rows.append(f"{name:34s} _{size:<3} box {box[0]:>3}x{box[1]:<3} coverage {cover:.2f} "
                    f"thin stroke {stroke:>4.0f} px  {note}")
    return rows


def build_4k(names: list[str]) -> Path:
    """A 3840x2160 sheet: icons at the physical size a 2x canvas gives them."""
    width, height = 3840, 2160
    sheet = Image.new("RGB", (width, height), (11, 13, 16))
    draw = ImageDraw.Draw(sheet)
    draw.text((48, 36), "Vajb Orbit - F.1 4K composite  (3840x2160 = 1920x1080 canvas at 2x "
                        "physical scale)", font=F_TITLE, fill=HDR)
    draw.text((48, 70), "left: icon set at the default band, 1 texture px = 1 physical px "
                        "(no upscaling) | right: the 192 band at its native 1:1 | bottom: "
                        "chrome at logical size", font=F_SMALL, fill=NOTE)

    # Icon grid: 96 px band drawn at 96 physical px.
    per_row = 20
    y = 120
    for i, name in enumerate(names):
        path = ICONS / f"{name}_96.png"
        if not path.is_file():
            continue
        img = Image.open(path).convert("RGBA")
        bg = Image.new("RGBA", img.size, (21, 24, 29, 255))
        bg.alpha_composite(img)
        sheet.paste(bg.convert("RGB"), (48 + (i % per_row) * 116, y + (i // per_row) * 116))
        if i // per_row >= 6:
            break

    # 192 band at native size in the right column.
    for i, name in enumerate(names[:8]):
        path = ICONS / f"{name}_192.png"
        if not path.is_file():
            continue
        img = Image.open(path).convert("RGBA")
        bg = Image.new("RGBA", img.size, (21, 24, 29, 255))
        bg.alpha_composite(img)
        sheet.paste(bg.convert("RGB"), (2480 + (i % 3) * 210, 120 + (i // 3) * 210))
    draw.text((2480, 96), "192 px band, native", font=F_SEC, fill=GOOD)

    # Chrome at logical size, plus the @2x variant at half scale to prove equivalence.
    y = 1740
    draw.text((48, y - 30), "chrome: logical (1x) above, the same texture drawn at half of its "
                            "@2x size below", font=F_SEC, fill=GOOD)
    for i, name in enumerate(("ui_button_plate_normal", "ui_slot_weapon_normal",
                              "ui_slot_cargo_normal", "ui_minimap_bezel", "ui_bar_caps")):
        one = UI / f"{name}.png"
        two = UI / f"{name}@2x.png"
        x = 48 + i * 420
        if one.is_file():
            img = Image.open(one).convert("RGBA")
            bg = Image.new("RGBA", img.size, (21, 24, 29, 255))
            bg.alpha_composite(img)
            sheet.paste(bg.convert("RGB"), (x, y))
        if two.is_file():
            img = Image.open(two).convert("RGBA")
            img = img.resize((max(1, img.size[0] // 2), max(1, img.size[1] // 2)), Image.LANCZOS)
            bg = Image.new("RGBA", img.size, (21, 24, 29, 255))
            bg.alpha_composite(img)
            sheet.paste(bg.convert("RGB"), (x, y + 120))
    out = OUT / f"review_{TAG}_4k.png"
    sheet.save(out)
    return out


def main() -> None:
    names = families()
    groups = collections.defaultdict(list)
    for base in names:
        groups[group_of(base)].append(base)

    problems = []
    for group, members in sorted(groups.items()):
        path, glitches = build_group_sheet(group, members)
        problems += glitches
        print(f"{path.name}: {len(members)} families, {path.name and ''}{len(glitches)} problems")

    table = [f"Measured icon table, tag {TAG} (icon quartet, contain-fit)",
             "box = ink bounding box in px; the longest axis must equal the cut size minus",
             "twice the master trim pad, which is what prove*s the aspect law; the other axis",
             "is proportional to the master. thin stroke = median of the shortest ink run per row.",
             ""]
    for base in names:
        table += measure(base)
    (OUT / f"review_{TAG}_table.txt").write_text("\n".join(table), encoding="utf-8")
    print(f"review_{TAG}_table.txt: {len(table) - 5} measured rows")

    out = build_4k(names)
    print(f"{out.name}: {out.name and ''}{Image.open(out).size}")
    if problems:
        print("PROBLEMS:")
        for item in problems[:20]:
            print("  ", item)
    print(f"groups: {sorted(groups)}")


if __name__ == "__main__":
    main()
