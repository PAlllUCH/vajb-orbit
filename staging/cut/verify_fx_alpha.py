"""Ask a vision model whether an FX alpha cut is clean: holes, clipping, lost artwork.

The numeric QC in `qc_fx_alpha.py` measures boxes and interiors; this is the human-shaped
read that catches what a number cannot - "the smoke reads right", "there is a bite out of
the plume". One image per file, two labelled panels: the pre-key render on void black, and
the keyed cut over **magenta**, because a transparent background and a black one look
identical on a black panel while magenta shows at once where the matte cut.

Model choice is the library's own measured one (`tag_vision.py`: `deepseek-chat` is the model
that answers from the image; `deepseek-v4-pro` drops it, `deepseek-v4-flash` truncates). The
key comes from the Crush config's `providers.deepseek.api_key`, resolved per host.

Usage:
    py -3.14 staging/cut/verify_fx_alpha.py --scope staging/cut/_fx_key
    py -3.14 staging/cut/verify_fx_alpha.py --pairs src.png keyed.png
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import tag_vision as tv  # noqa: E402  - the key resolution and the API call live there

ROOT = Path(__file__).resolve().parents[2]
ANSWER = ROOT / "staging" / "cut" / "_fx_verify.json"
SIDE = 420
QUALITY = 88

PROMPT = """You are checking a game effect sprite that was cut out of its background.

The image has two panels, left to right:
  LEFT  "BEFORE" - the original render on its flat black background.
  RIGHT "AFTER"  - the same effect after a background-removal cut, placed on MAGENTA.
                   Every magenta pixel is transparent in the finished PNG.

Answer only about the RIGHT panel, comparing it against the LEFT one. Magenta is NOT part of
the artwork. A soft glow fading to magenta at its edge is correct.

Reply with one JSON object on the first line, then at most 15 words of note. Nothing else:

{{"subject": "<3 to 6 lowercase words, what the effect is>", \
"outline_intact": <true if no part of the effect is cut off or missing>, \
"holes": <number of magenta gaps that are fully enclosed INSIDE the effect's body>, \
"holes_where": "<short phrase, or empty>", \
"background_clear": <true if the flat black background is now fully magenta with no black \
box left behind>, \
"artifact": "<short phrase for any grey fringe, halo or smear, or empty>", \
"verdict": "<pass|fail>"}}"""


def panel(source: Image.Image, keyed: Image.Image) -> tuple[Image.Image, list[int]]:
    """Two labelled panels cropped to the effect, sized for a vision read."""
    ink = source.convert("L")
    import numpy as np
    gray = np.asarray(ink).astype(np.float32)
    ring = np.concatenate([gray[:16].ravel(), gray[-16:].ravel(),
                           gray[:, :16].ravel(), gray[:, -16:].ravel()])
    mask = np.abs(gray - float(np.median(ring))) > 14
    alpha = np.asarray(keyed.convert("RGBA").getchannel("A")) > 8
    both = mask | alpha
    rows = np.where(both.any(axis=1))[0]
    cols = np.where(both.any(axis=0))[0]
    box = [0, 0, source.width, source.height]
    if len(rows) and len(cols):
        pad = 40
        box = [max(0, int(cols[0]) - pad), max(0, int(rows[0]) - pad),
               min(source.width, int(cols[-1]) + pad), min(source.height, int(rows[-1]) + pad)]
    left = source.convert("RGB").crop(box)
    right = Image.new("RGB", (box[2] - box[0], box[3] - box[1]), (255, 0, 255))
    cut = keyed.convert("RGBA").crop(box)
    right.paste(cut, (0, 0), cut)   # the alpha is the mask: without it PIL drops it and the
                                    # panel just shows the pre-key black background again
    ratio = min(SIDE / left.width, SIDE / left.height, 1.0)
    size = (max(1, int(left.width * ratio)), max(1, int(left.height * ratio)))
    left = left.resize(size, Image.LANCZOS)
    right = right.resize(size, Image.LANCZOS)
    head = 22
    sheet = Image.new("RGB", (size[0] * 2 + 6, size[1] + head), (16, 16, 16))
    sheet.paste(left, (0, head))
    sheet.paste(right, (size[0] + 6, head))
    draw = ImageDraw.Draw(sheet)
    draw.text((4, 6), "BEFORE (void black)", fill=(220, 220, 220))
    draw.text((size[0] + 10, 6), "AFTER (magenta = transparent)", fill=(220, 220, 220))
    return sheet, box


def encode(image: Image.Image) -> str:
    buffer = io.BytesIO()
    image.save(buffer, "JPEG", quality=QUALITY)
    return base64.b64encode(buffer.getvalue()).decode()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", default="")
    parser.add_argument("--out", default="staging/cut/_fx_review")
    parser.add_argument("--pairs", nargs="*", default=[])
    parser.add_argument("--repeat", type=int, default=2,
                        help="reads per file; the majority verdict wins (a vision verdict on a "
                             "full-frame effect is not deterministic - the vignette read FAIL "
                             "once and PASS on both re-reads at k=1)")
    args = parser.parse_args()

    pairs: list[tuple[Path, Path]] = []
    if args.scope:
        for keyed in sorted(Path(args.scope).glob("*-keyed.png")):
            source = keyed.with_name(keyed.name.replace("-keyed.png", ".png"))
            if source.exists():
                pairs.append((source, keyed))
    for index in range(0, len(args.pairs) - 1, 2):
        pairs.append((Path(args.pairs[index]), Path(args.pairs[index + 1])))
    if not pairs:
        print("nothing to verify: pass --scope <dir> or --pairs src.png keyed.png")
        return 1

    key = tv.api_key()
    print(f"verify_fx_alpha: {len(pairs)} file(s), model {tv.MODEL}")
    answers = {}
    for source_path, keyed_path in pairs:
        source = Image.open(source_path).convert("RGB")
        keyed = Image.open(keyed_path).convert("RGBA")
        sheet, box = panel(source, keyed)
        out = Path(args.out) / f"{source_path.stem}_verify.jpg"
        out.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(out, quality=QUALITY)
        reads = []
        payload = encode(sheet)
        for _ in range(max(1, args.repeat)):
            one = tv.ask(key, PROMPT, payload)
            one.pop("_usage", None)
            reads.append(one)
        passes = sum(1 for r in reads if str(r.get("verdict", "")).lower() == "pass")
        answer = dict(reads[0])
        answer["verdict"] = "pass" if passes * 2 > len(reads) else "fail"
        answer["_reads"] = [r.get("verdict") for r in reads]
        answers[source_path.stem] = {"box": box, "image": str(out), **answer}
        verdict = str(answer.get("verdict", "?")).upper()
        print(f"  {source_path.stem:28s} {verdict:5s} "
              f"outline={answer.get('outline_intact')} holes={answer.get('holes')} "
              f"clear={answer.get('background_clear')} "
              f"artifact={answer.get('artifact')!r} :: {answer.get('note') or answer.get('_raw') or answer.get('_error')}")
    ANSWER.write_text(json.dumps(answers, indent=1, ensure_ascii=False), encoding="utf-8")
    fails = [n for n, a in answers.items() if str(a.get("verdict", "")).lower() != "pass"]
    print(f"verify_fx_alpha: {len(answers) - len(fails)} pass, {len(fails)} fail -> {ANSWER}")
    return 0 if not fails else 2


if __name__ == "__main__":
    raise SystemExit(main())
