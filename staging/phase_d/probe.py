"""Local-only inspector/previewer for the Phase D masters. No API calls."""
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

OUT = Path(r"G:/Mój dysk/Projekty/Vajb Orbit/staging/phase_d/_preview")


def report(path):
    img = Image.open(path)
    px = img.convert("RGB")
    w, h = px.size
    corners = [px.getpixel((0, 0)), px.getpixel((w - 1, 0)), px.getpixel((0, h - 1)), px.getpixel((w - 1, h - 1))]
    sample = Counter(px.resize((128, 128)).getdata()).most_common(3)
    alpha = img.convert("RGBA").getchannel("A")
    hist = alpha.histogram()
    total = w * h
    print(f"{Path(path).name}: {img.size} {img.mode}")
    print(f"  corners: {['#%02X%02X%02X' % c for c in corners]}")
    print(f"  dominant: {[('#%02X%02X%02X' % c, n) for c, n in sample]}")
    print(f"  alpha: ==0 {100*hist[0]/total:.1f}%  <16 {100*sum(hist[:16])/total:.1f}%  ==255 {100*hist[255]/total:.1f}%")
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / (Path(path).stem[:44] + ".jpg")
    prev = img.convert("RGB").copy()
    prev.thumbnail((760, 760), Image.LANCZOS)
    prev.save(dest, quality=80)
    print(f"  preview: {dest}")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        report(arg)
