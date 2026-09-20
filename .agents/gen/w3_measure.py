"""W3 measurement helper: byte size, LF/CRLF counts and md5 for the five slice
files. Kept next to the W3 report so the numbers in it can be re-derived.

    py -3.14 .agents/gen/w3_measure.py
"""

import hashlib
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "vajb-orbit")
FILES = [
    "game/asteroid.gd",
    "game/asteroid_field.gd",
    "game/pickup.gd",
    "game/mining_laser.gd",
    "game/mining_laser.tscn",
]


def main() -> None:
    for rel in FILES:
        path = os.path.join(ROOT, rel)
        data = open(path, "rb").read()
        lf = data.count(b"\n")
        crlf = data.count(b"\r\n")
        print(
            "%-28s %6d bytes  LF=%-4d CRLF=%-3d md5=%s"
            % (rel, len(data), lf, crlf, hashlib.md5(data).hexdigest().upper())
        )


if __name__ == "__main__":
    main()
