"""Gather every generated original into `asset-library/<family>/`. Read-only on sources.

Each paid generation run left a timestamped folder holding its provenance
(`job.json`) plus the PNGs the generator returned. Those folders are spread over
`vajb-orbit/assets/<family>/` (Phase B/D/E) and `staging/phase_f/<family>/` (Phase F),
which makes the originals tedious to browse. This pass copies the whole-sheet
artifacts of every run into one flat, per-family folder:

    asset-library/ships/ship_bomber__raw.png     pristine 2K generator render, untouched RGB
    asset-library/ships/ship_bomber__keyed.png   the current local-matte sheet (RGBA)

`__raw.png` is the file to re-split from. `__keyed.png` is kept as a reference of what
the current pipeline produces, including the interior holes the local matte punches
(measured by staging/review/qc_alpha.py). The per-cell cuts are deliberately not
gathered: they already ship as the sprites in `vajb-orbit/assets/`.

Names are resolved in this order, most reliable first:
  1. the shipped assets the run produced (joined on `task_id`), reduced to their
     longest common prefix - so a four-view run becomes `ship_bomber`
  2. the run key in the owning wave driver's `RUNS` table, on an exact prompt match
  3. the generator's own filename slug, for runs whose table no longer exists

Usage:
    py -3.14 staging/review/gather_originals.py --list
    py -3.14 staging/review/gather_originals.py
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import importlib.util
import json
import os
import shutil
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
DEST_ROOT = WORKSPACE / "asset-library"
SOURCES = (WORKSPACE / "vajb-orbit" / "assets", WORKSPACE / "staging" / "phase_f")
FAMILIES = ("ships", "env", "fx", "ui", "icons")
DRIVERS = (
    ("phase_d", "staging/phase_d/wave1.py"),
    ("phase_e", "staging/phase_e/wave_e.py"),
    ("phase_f", "staging/phase_f/wave_f.py"),
)


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_tables() -> dict[str, list[tuple[str, str]]]:
    """Full prompt text -> [(phase, run key)], style-first runs included."""
    index: dict[str, list[tuple[str, str]]] = {}
    for tag, rel in DRIVERS:
        path = WORKSPACE / rel
        if not path.is_file():
            continue
        module = load_module(tag, path)
        style_path = getattr(module, "STYLE_FILE", None)
        style = style_path.read_text(encoding="utf-8").strip() if style_path else ""
        for key, spec in getattr(module, "RUNS", {}).items():
            subject = (spec.get("subject") or "").strip()
            if not subject:
                continue
            candidates = [f"{subject}\n{style}".strip(), subject]
            if spec.get("style_first") and style:
                candidates.insert(0, f"{style}\n{subject}".strip())
            for text in candidates:
                bucket = index.setdefault(text, [])
                if (tag, key) not in bucket:
                    bucket.append((tag, key))
    return index


def shipped_by_task() -> dict[str, list[str]]:
    """task_id -> shipped asset stems, built from the *.job.json sidecars."""
    index: dict[str, list[str]] = collections.defaultdict(list)
    for fam in FAMILIES:
        for sidecar in (WORKSPACE / "vajb-orbit" / "assets" / fam).glob("*.job.json"):
            try:
                payload = json.loads(sidecar.read_text(encoding="utf-8"))
            except ValueError:
                continue
            task = payload.get("task_id")
            if task:
                index[task].append(sidecar.name.removesuffix(".job.json").removesuffix(".png"))
    return index


def common_prefix(names: list[str]) -> str:
    """Longest shared prefix of the shipped stems, trimmed back to a word boundary.

    Returns "" when the produced names share nothing useful (a boss plus its livery, two
    unrelated UI pieces), so the caller can fall through to the run table.
    """
    if not names:
        return ""
    if len(names) == 1:
        return names[0]
    head = os.path.commonprefix(names).rstrip("_-")
    return head if len(head) >= 5 else ""


def tidy_slug(slug: str) -> str:
    """Strip the generator's trailing run counter from a filename slug."""
    return slug[:-2] if slug.endswith("-1") else slug


def find_runs() -> list[tuple[str, Path]]:
    out = []
    for base in SOURCES:
        for fam in FAMILIES:
            family_dir = base / fam
            if not family_dir.is_dir():
                continue
            for entry in sorted(family_dir.iterdir()):
                if entry.is_dir() and (entry / "job.json").is_file():
                    out.append((fam, entry))
    return out


def pick(run: Path) -> tuple[Path | None, Path | None]:
    pngs = sorted(run.glob("*.png"))
    raw = next((p for p in pngs if p.stem.endswith("-1")), None)
    keyed = next((p for p in pngs if p.stem.endswith(("-alpha", "-matte"))), None)
    if raw is None and pngs:
        raw = pngs[0]
    return raw, keyed


def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def image_size(path: Path) -> list[int] | None:
    if not path:
        return None
    from PIL import Image
    with Image.open(path) as im:
        return list(im.size)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="report the plan, copy nothing")
    args = ap.parse_args()

    prompts = run_tables()
    shipped = shipped_by_task()
    runs = find_runs()

    rows = []
    for fam, run in runs:
        payload = json.loads((run / "job.json").read_text(encoding="utf-8"))
        prompt = (payload.get("input", {}).get("prompt") or "").strip()
        task = payload.get("task_id", "")
        tables = prompts.get(prompt, [])
        produced = shipped.get(task, [])
        raw, keyed = pick(run)

        if produced:
            prefix = common_prefix(produced)
            name = prefix or (tables[0][1] if len(tables) == 1 else "")
            resolution = "shipped" if prefix else ("run_table" if name else "slug")
        elif len(tables) == 1:
            name, resolution = tables[0][1], "run_table"
        else:
            name, resolution = "", "slug"
        if not name:
            name = tidy_slug(raw.stem) if raw else run.name

        rows.append({
            "family": fam,
            "run_dir": run.relative_to(WORKSPACE).as_posix(),
            "stamp": run.name,
            "run_key": name,
            "resolution": resolution,
            "table_matches": [f"{t}:{k}" for t, k in tables],
            "produced": produced,
            "job_id": task,
            "model": payload.get("model", ""),
            "prompt": prompt,
            "raw": raw,
            "keyed": keyed,
            "raw_size": image_size(raw),
        })

    counts: dict[tuple[str, str], int] = collections.Counter(
        (r["family"], r["run_key"]) for r in rows
    )
    for r in rows:
        dup = counts[(r["family"], r["run_key"])] > 1
        stem = f"{r['run_key']}__{r['stamp']}" if dup else r["run_key"]
        r["raw_name"] = f"{stem}__raw.png"
        r["keyed_name"] = f"{stem}__keyed.png"

    # A run that shipped nothing but shares its prompt opening with a run that did is a
    # superseded attempt: it is in the project only as provenance, and browsing it wastes
    # the reviewer's time. Prompt *exact* matches are the regeneration case; note those too.
    groups: dict[str, list[dict]] = collections.defaultdict(list)
    for r in rows:
        groups[r["prompt"][:110]].append(r)
    for group in groups.values():
        shipped_runs = [g for g in group if g["produced"]]
        for r in group:
            if r["produced"] or not shipped_runs:
                continue
            winners = sorted({g["run_key"] for g in shipped_runs})
            r["superseded_by"] = winners if len(winners) > 1 else winners[0]
    for r in rows:
        r.setdefault("superseded_by", None)
    superseded = [r for r in rows if r["superseded_by"]]

    by_res = collections.Counter(r["resolution"] for r in rows)
    print(f"runs found: {len(rows)}")
    for kind in ("shipped", "run_table", "slug"):
        print(f"  named from {kind:10s}: {by_res.get(kind, 0)}")
    print(f"  ambiguous prompts : {len([r for r in rows if len(r['table_matches']) > 1])}")
    print(f"  superseded runs   : {len(superseded)}")
    print(f"  keyed sheet found : {len([r for r in rows if r['keyed']])}")
    per_fam = collections.Counter(r["family"] for r in rows)
    for fam in FAMILIES:
        print(f"  {fam:6s} {per_fam.get(fam, 0):3d} runs")
    if by_res.get("slug"):
        print("  slug-named runs:")
        for r in rows:
            if r["resolution"] == "slug":
                print(f"    {r['family']:6s} {r['raw_name']}")

    if args.list:
        print()
        for r in sorted(rows, key=lambda x: (x["family"], x["raw_name"])):
            print(f"  {r['family']:6s} {r['raw_name']:56s} {r['raw_size']}  <- {r['stamp']}")
        return

    manifest = []
    copied = 0
    for r in rows:
        dest_dir = DEST_ROOT / r["family"]
        dest_dir.mkdir(parents=True, exist_ok=True)
        entry = {
            "family": r["family"],
            "run_dir": r["run_dir"],
            "stamp": r["stamp"],
            "run_key": r["run_key"],
            "name_resolution": r["resolution"],
            "superseded_by": r["superseded_by"],
            "produced_assets": r["produced"],
            "job_id": r["job_id"],
            "model": r["model"],
            "prompt": r["prompt"],
            "files": [],
        }
        for role, src, dest_name in (
            ("raw", r["raw"], r["raw_name"]),
            ("keyed", r["keyed"], r["keyed_name"]),
        ):
            if not src:
                continue
            dest = dest_dir / dest_name
            shutil.copy2(src, dest)
            copied += 1
            entry["files"].append({
                "name": dest.name,
                "role": role,
                "source": src.relative_to(WORKSPACE).as_posix(),
                "bytes": dest.stat().st_size,
                "md5": md5(dest),
            })
        manifest.append(entry)

    dest_manifest = DEST_ROOT / "_originals_manifest.json"
    dest_manifest.write_text(json.dumps({
        "note": ("Gathered by staging/review/gather_originals.py. `raw` is the untouched 2K "
                 "generator render and is the file to re-split from; `keyed` is the current "
                 "local-matte sheet, kept for reference. Sources are left in place."),
        "root": DEST_ROOT.as_posix(),
        "runs": manifest,
    }, indent=2), encoding="utf-8")
    print(f"\ncopied {copied} files into {DEST_ROOT}")
    print(f"manifest -> {dest_manifest}")


if __name__ == "__main__":
    main()
