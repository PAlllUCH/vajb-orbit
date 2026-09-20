import struct
from pathlib import Path

base = Path(r"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit/.godot/imported")
files = [
    "ship_interceptor_side.png-7a6f7c6fbdf2a5b8d3d1b39a410292dc.ctex",
    "ship_vanguard_side.png-6fdecd49c28f33b84eca2cc9d8c2834d.ctex",
    "icon_zoom_plus_96.png-f351c9322c9e851ab1b4918a5d4607e7.ctex",
    "icon_zoom_plus_48.png-89f98bd93a7702128c3828ee8a04c0d2.ctex",
]

HAS_MIPMAPS = 1 << 23

for name in files:
    data = (base / name).read_bytes()
    magic = data[0:4].decode("ascii", "replace")
    words = struct.unpack_from("<8I", data, 4)
    width, height, fmt = words[1], words[2], words[3]
    print(f"{name}")
    print(f"  magic={magic} width={width} height={height} format=0x{fmt:08X} "
          f"has_mipmaps_bit={bool(fmt & HAS_MIPMAPS)} header_words={words} bytes={len(data)}")
