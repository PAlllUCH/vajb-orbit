"""D4c crop helper: zoom a region of a frame into a PNG for eyeballing.

Usage: py -3.14 d4c_crop.py <frame.png> <x0> <y0> <x1> <y1> <zoom> <out.png>
"""

import sys

from PIL import Image


def main():
    frame, x0, y0, x1, y1, zoom, out = sys.argv[1:8]
    image = Image.open(frame).convert("RGB")
    box = (int(x0), int(y0), int(x1), int(y1))
    crop = image.crop(box)
    factor = int(zoom)
    crop = crop.resize((crop.width * factor, crop.height * factor), Image.NEAREST)
    crop.save(out)
    print("crop", box, "of", image.size, "->", out, crop.size)


main()
