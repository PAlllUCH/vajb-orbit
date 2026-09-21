"""Phase G recovery - pull a texture back out of Godot's import cache.

Why this exists: the 2026-09-21 cut redesign deleted the pre-09-21 sources and every
`@2x` cut from `vajb-orbit/assets/`, and this repo is text-only (`*.png` is gitignored),
so no commit can restore them. The editor's import cache is the only surviving copy:
`.godot/imported/<source>-<hash>.ctex` is a `GST2` blob whose payload is the imported
image encoded as lossless WebP, so the pixels come back exactly - not a re-render.

Measured on this box (2026-09-21): 3698 `.ctex` files, 286 of them with no source file
on disk (`--orphans`), including all 12 `ui_slot_*@2x.png`, the four
`ui_button_plate_*@2x.png`, `ui_minimap_bezel@2x.png`, `ui_panel_frame@2x.png` and the
raw 2K sheets of the logo, panel frame, bar caps and backdrops.

The cache is a cache: Godot may prune it, and it holds the file *as imported* (its mip
chain), not the file itself. So this tool is read-only on `.godot/`, refuses any output
path inside `vajb-orbit/assets/`, and writes recovered images into staging only.

GST2 layout as measured here (little-endian):
    4  u32 version (=1)          20  u32 mipmap limit (0xFFFFFFFF = unlimited)
    8  u32 width                 44  u32 mip levels - 1
   12  u32 height                48  u32 Image::Format (4 = RGB8, 5 = RGBA8)
   16  u32 format flags          52  u32 first payload size
   24..40 five words whose low bits carry the WebP variant; recorded raw
   56  first `RIFF` payload, then one per mip level

Usage:
  py -3.14 staging/phase_f/recover_ctex.py --list [--orphans]
  py -3.14 staging/phase_f/recover_ctex.py --inventory
  py -3.14 staging/phase_f/recover_ctex.py --get <source-name.png> [--out DIR] [--mip N]
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "vajb-orbit" / "assets"
IMPORTED = ROOT / "vajb-orbit" / ".godot" / "imported"
STAGE = ROOT / "staging" / "phase_f"
REPORT = STAGE / "recover_ctex_report.json"

MAGIC = b"GST2"
FORMATS = {0: "L8", 1: "LA8", 2: "R8", 3: "RG8", 4: "RGB8", 5: "RGBA8"}
CTEX_NAME = re.compile(r"^(?P<source>.+)-(?P<hash>[0-9a-f]{32})\.ctex$")


@dataclass
class Ctex:
    path: Path
    source: str
    hash: str
    width: int
    height: int
    image_format: int
    mip_levels: int
    format_flags: int
    blobs: list[bytes] = field(default_factory=list)

    @property
    def format_name(self) -> str:
        return FORMATS.get(self.image_format, f"?{self.image_format}")


def parse(path: Path) -> Ctex:
    data = path.read_bytes()
    if data[:4] != MAGIC:
        raise ValueError(f"{path} is not a GST2 blob (starts {data[:4]!r})")
    version, width, height, format_flags, _limit, _w24, _w28, _w32, _w36, _w40 = \
        struct.unpack_from("<10I", data, 4)
    if version != 1:
        raise ValueError(f"{path} is GST2 version {version}, this reader knows 1")
    image_format, _pad, _first_size = struct.unpack_from("<3I", data, 48)
    mip_levels = struct.unpack_from("<I", data, 44)[0] + 1
    blobs: list[bytes] = []
    at = data.find(b"RIFF", 32)
    while at >= 0 and at + 8 <= len(data):
        size = struct.unpack_from("<I", data, at + 4)[0]
        blobs.append(data[at:at + 8 + size])
        at = data.find(b"RIFF", at + 8 + size)
    if not blobs:
        raise ValueError(f"{path} holds no RIFF/WebP payload")
    match = CTEX_NAME.match(path.name)
    return Ctex(path=path, source=match.group("source") if match else path.stem,
                hash=match.group("hash") if match else "", width=width, height=height,
                image_format=image_format, mip_levels=mip_levels,
                format_flags=format_flags, blobs=blobs)


def decode(ctex: Ctex, mip: int = 0) -> Image.Image:
    """Mip 0 is the imported image at full size; higher mips are its halves."""
    if mip >= len(ctex.blobs):
        raise ValueError(f"{ctex.source} has {len(ctex.blobs)} mip level(s), no mip {mip}")
    image = Image.open(io.BytesIO(ctex.blobs[mip]))
    image.load()
    return image


def digest(image: Image.Image) -> str:
    return hashlib.md5(image.tobytes()).hexdigest()


def sources_on_disk() -> set[str]:
    return {path.name for path in ASSETS.rglob("*") if path.is_file()}


def inventory() -> list[Ctex]:
    found: list[Ctex] = []
    for path in sorted(IMPORTED.glob("*.ctex")):
        try:
            found.append(parse(path))
        except ValueError:
            continue
    return found


def write_png(image: Image.Image, out_dir: Path, name: str) -> Path:
    out_dir = out_dir.resolve()
    if out_dir == ASSETS.resolve() or ASSETS.resolve() in out_dir.parents:
        raise SystemExit(f"refusing to write into the project's assets/: {out_dir}")
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / name
    image.save(target)
    return target


def row(ctex: Ctex, on_disk: set[str]) -> dict:
    full = decode(ctex)
    return {
        "source": ctex.source,
        "ctex": str(ctex.path.relative_to(ROOT)),
        "hash": ctex.hash,
        "size": [ctex.width, ctex.height],
        "format": ctex.format_name,
        "mip_levels": ctex.mip_levels,
        "decoded_size": list(full.size),
        "decoded_mode": full.mode,
        "decoded_md5": digest(full),
        "ctex_bytes": ctex.path.stat().st_size,
        "source_exists": ctex.source in on_disk,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="print the cache inventory")
    ap.add_argument("--orphans", action="store_true", help="list only sources gone")
    ap.add_argument("--inventory", action="store_true", help="write the JSON report")
    ap.add_argument("--get", action="append", nargs="+", default=[],
                    help="recover source names (one or more, repeatable)")
    ap.add_argument("--out", default="staging/phase_f/_recover")
    ap.add_argument("--mip", type=int, default=0)
    args = ap.parse_args()

    cache = inventory()
    on_disk = sources_on_disk()
    by_source: dict[str, list[Ctex]] = {}
    for ctex in cache:
        by_source.setdefault(ctex.source, []).append(ctex)

    if args.list or args.orphans:
        wanted = [c for c in cache if c.source not in on_disk] if args.orphans else cache
        for ctex in wanted:
            dup = " (duplicate)" if len(by_source[ctex.source]) > 1 else ""
            print(f"{ctex.source:64s} {ctex.width:>5}x{ctex.height:<5} "
                  f"{ctex.format_name:6s} mips={ctex.mip_levels:<2} "
                  f"{ctex.path.stat().st_size / 1024:>8.0f} KB{dup}")
        gone = sum(1 for c in cache if c.source not in on_disk)
        print(f"\n{len(cache)} cached textures, {gone} with no source file on disk")

    if args.inventory:
        rows = [row(c, on_disk) for c in cache]
        report = {"blobs": len(cache),
                  "orphans": sum(1 for r in rows if not r["source_exists"]),
                  "duplicate_sources": sorted(s for s, v in by_source.items()
                                              if len(v) > 1),
                  "rows": rows}
        REPORT.write_text(json.dumps(report, indent=1), encoding="utf-8")
        print(f"wrote {REPORT.relative_to(ROOT)} ({len(rows)} rows)")

    if args.get:
        out_dir = Path(args.out)
        if not out_dir.is_absolute():
            out_dir = ROOT / out_dir
        provenance: list[dict] = []
        for name in [n for group in args.get for n in group]:
            matches = by_source.get(name, [])
            if not matches:
                print(f"MISS {name}: no such source in the cache")
                continue
            ctex = max(matches, key=lambda c: c.path.stat().st_size)
            if len(matches) > 1:
                print(f"WARN {name}: {len(matches)} cached versions, took the largest "
                      f"({ctex.hash}, {ctex.path.stat().st_size} B)")
            image = decode(ctex, args.mip)
            if args.mip >= ctex.mip_levels:
                print(f"WARN {name}: no mip {args.mip}, showing mip 0 size")
            path = write_png(image, out_dir, name)
            sidecar = ctex.path.with_suffix(".md5")
            source_md5 = None
            if sidecar.is_file():
                found = re.search(r'source_md5="([0-9a-f]{32})"',
                                  sidecar.read_text(encoding="utf-8"))
                source_md5 = found.group(1) if found else None
            provenance.append({
                "recovered": str(path.relative_to(ROOT)),
                "ctex": str(ctex.path.relative_to(ROOT)),
                "ctex_hash": ctex.hash,
                "source_file": ctex.source,
                "source_md5": source_md5,
                "size": list(image.size),
                "mode": image.mode,
                "md5": digest(image),
                "mip_levels": ctex.mip_levels,
                "format": ctex.format_name,
                "ctex_bytes": ctex.path.stat().st_size,
                "mip": args.mip,
            })
            print(f"{name:52s} {image.size} {image.mode} md5={digest(image)} -> "
                  f"{path.relative_to(ROOT)}")
        if provenance:
            record = out_dir / "provenance.json"
            merged = json.loads(record.read_text(encoding="utf-8")) if record.is_file() else []
            seen = {(e["recovered"], e["mip"]) for e in merged}
            merged += [e for e in provenance if (e["recovered"], e["mip"]) not in seen]
            record.write_text(json.dumps(merged, indent=1), encoding="utf-8")
            print(f"wrote {record.relative_to(ROOT)} ({len(merged)} records)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
