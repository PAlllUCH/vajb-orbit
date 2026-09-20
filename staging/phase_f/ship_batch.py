"""Phase F shipping step - staging -> vajb-orbit/assets, after the review sheet approval.

Copies the approved consumer PNGs (and their job.json manifests) from
staging/phase_f/<family>/ into vajb-orbit/assets/<family>/ and drops the family
generation log next to them. Panel masters and raw run folders stay in staging as
provenance and never enter assets/ (see ASSET_CATALOG.md's provenance appendix).

`--only a.png,b.png` ships just those files (plus their `.job.json`), which is how the
F.1 integrity pass lands single regenerated assets without re-shipping the families it
did not touch.

Usage:
    py -3.14 staging/phase_f/ship_batch.py --list          # what would ship
    py -3.14 staging/phase_f/ship_batch.py icons env fx ships
    py -3.14 staging/phase_f/ship_batch.py icons --only icon_shield.png
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "staging" / "phase_f"
ASSETS = ROOT / "vajb-orbit" / "assets"
FAMILIES = ("ships", "icons", "env", "ui", "fx")

# Never shipped: panel masters (provenance only), chrome masters (a `-master` file keeps the
# 2K source of a logical-size chrome texture out of assets/, where the logical file has to
# stay the consumer size) and the -matte/-cut intermediates.
SKIP_PREFIXES = ("panel_",)
SKIP_SUBSTRINGS = ("-alpha", "-matte", "-cut", "-trim", "-keyed", "-master")


def ship_files(family: str) -> list[Path]:
    src_dir = STAGE / family
    if not src_dir.is_dir():
        return []
    out = []
    for path in sorted(src_dir.iterdir()):
        if not path.is_file():
            continue
        if path.name.startswith(SKIP_PREFIXES) or "generation_log" in path.name:
            continue
        if any(s in path.stem for s in SKIP_SUBSTRINGS):
            continue
        if path.suffix not in (".png", ".json"):
            continue
        out.append(path)
    return out


def stale(path: Path, dest_dir: Path) -> str | None:
    """Reject a staged file that the shipped file has already superseded.

    The F.1/F.2 passes re-cut icons straight into `assets/` (`recut_quartet.py`), so the
    Phase F staging copies of those cuts have different bytes and older mtimes than what
    ships. A wide `ship_batch.py icons` would silently revert 159 of them to the pre-F.1
    geometry. A staged file older than its shipped counterpart with different bytes is
    therefore refused unless `--allow-stale` says the regression is intended.
    """
    if path.suffix != ".png":
        return None
    shipped = dest_dir / path.name
    if not shipped.is_file():
        return None
    if path.stat().st_mtime >= shipped.stat().st_mtime:
        return None
    if path.read_bytes() == shipped.read_bytes():
        return None
    return (f"{path.name} (staged {path.stat().st_size} B is older than the shipped "
            f"{shipped.stat().st_size} B and differs)")


def main() -> None:
    argv = sys.argv[1:]
    dry = "--list" in argv
    allow_stale = "--allow-stale" in argv
    only = set()
    if "--only" in argv:
        index = argv.index("--only") + 1
        only = {n.strip()[:-4] if n.strip().endswith(".png") else n.strip()
                for n in argv[index].split(",") if n.strip()}
        argv = argv[:index - 1] + argv[index + 1:]
    args = [a for a in argv if not a.startswith("--")]
    families = args or list(FAMILIES)
    total = 0
    stale_total = 0
    for family in families:
        files = ship_files(family)
        if only:
            files = [p for p in files
                     if p.name[: -len(".job.json")] in only or p.stem in only]
        dest_dir = ASSETS / family
        dest_dir.mkdir(parents=True, exist_ok=True)
        stale_hits = [s for s in (stale(p, dest_dir) for p in files) if s]
        if stale_hits:
            stale_total += len(stale_hits)
            print(f"{family}: {len(stale_hits)} staged file(s) are SUPERSEDED by the shipped "
                  f"bytes - refusing to ship them (re-cut from the masters, or pass "
                  f"--allow-stale):")
            for hit in stale_hits[:8]:
                print(f"    {hit}")
            if len(stale_hits) > 8:
                print(f"    ... {len(stale_hits) - 8} more")
            if not allow_stale:
                files = [p for p in files
                         if not any(h.startswith(p.name + " ") for h in stale_hits)]
        pngs = [p for p in files if p.suffix == ".png"]
        print(f"{family}: {len(pngs)} PNG ({len(files) - len(pngs)} job.json) -> {dest_dir}")
        if dry:
            for p in pngs[:6]:
                print(f"    {p.name}")
            if len(pngs) > 6:
                print(f"    ... {len(pngs) - 6} more")
            total += len(pngs)
            continue
        for path in files:
            shutil.copy2(path, dest_dir / path.name)
        log = STAGE / family / "generation_log_phase_f.md"
        if log.is_file():
            shutil.copy2(log, dest_dir / log.name)
        total += len(pngs)
    print(f"{'would ship' if dry else 'shipped'} {total} PNGs"
          + (f"; {stale_total} stale file(s) held back" if stale_total else ""))
    if stale_total and not allow_stale:
        sys.exit(2)


if __name__ == "__main__":
    main()
