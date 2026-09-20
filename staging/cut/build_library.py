"""Build the asset library's own index: one described record per file, and a readable catalogue.

The point of this file is that a future agent must never have to guess what an asset is. Every
record carries what the picture actually shows (read off the render by a vision model, verified
by eye against the pixels: the names in this library do lie, see `name_issue`), what it is made
of (pixels, bytes, alpha share, md5), where it came from (the sheet it was cut from, its panel
number, the job and prompt that rendered that sheet), and who already uses it (the docs and the
code that name it).

It is a generator, not a document: `asset-library/_library.json` and `asset-library/INDEX.md`
are both written from the same pass, so a rename or a re-cut is reflected by re-running it
rather than by hand-editing anything.

Sources joined per file:
  _vision.json            what the picture shows (subject, kind, detail, objects, flat_bg)
  _sheets.json            for a raw sheet: family, grid, panel order, plate flag
  _cuts_manifest.json     for a sprite: its sheet, its panel, its source box
  _originals_manifest.json  the job, model, stamp and prompt that rendered the sheet
  _vocabulary.json        the doc files and code paths that cite the name

Usage:
    py -3.14 staging/cut/build_library.py              # write _library.json and INDEX.md
    py -3.14 staging/cut/build_library.py --check      # report only, write nothing
    py -3.14 staging/cut/build_library.py --json-only  # skip INDEX.md
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
RAW = LIBRARY / "raw"
CUT = LIBRARY / "cut"
PROJECT_ASSETS = WORKSPACE / "vajb-orbit" / "assets"

OUT_JSON = LIBRARY / "_library.json"
OUT_MD = LIBRARY / "INDEX.md"

# family prefix -> the folder the file ships in. Mirrors ASSET_CATALOG.md's own six folders.
FAMILY_FOLDER = {
    "ship": "ships", "livery": "ships",
    "icon": "icons",
    "env": "env",
    "ui": "ui", "logo": "ui", "panel": "ui",
    "fx": "fx",
}
# Sub-containers inside icons, so a look-up can be narrowed without reading every row.
ICON_GROUP = (
    ("mineral", "minerals and ore"), ("ingot", "refined ingots"), ("cargo", "cargo and hold"),
    ("contract", "contract and mission"), ("map", "starmap and markers"),
    ("booster", "boosters and consumables"), ("equip", "equipment and modules"),
    ("module", "ship modules"), ("ammo", "ammunition"), ("weapon", "weapons"),
    ("insignia", "faction insignia"), ("status", "status and state"),
    ("service", "station services"), ("slot", "slot frames"),
    ("zoom", "view controls"), ("credits", "currency"), ("hud", "hud glyphs"),
)
DERIVED_RE = re.compile(r"_(16|48|96|192)$|@2x$")
PLACEHOLDER_RE = re.compile(r"_sheet_\d+x\d+_\d{8}_\d{6}(__p\d+)?$")
TWIN_RE = re.compile(r"__\d{8}-\d{6}$")
SLUG_RE = re.compile(r"^\d+-frame|^[a-z0-9]+(-[a-z0-9]+){4,}")
PHASE_RE = re.compile(r"^(f\d|p\d)_")

# Renders that contradict their own brief. Every entry here was looked at, on a contact sheet,
# against a prompt that forbade exactly what the render contains: the `flare` model honoured the
# style block and ignored these negative lists, so six "tileable layer" runs returned starships
# and three isolated-effect runs returned a ship or a ship with an effect around it. Nothing is
# inferred here, and nothing is added without a look, because a rename will act on this list.
CONTENT_MISMATCH = {
    "raw/seamless-tileable-starfield-layer-a-fla.png":
        "brief asked for sparse star points with no objects at all; rendered a combat starship",
    "raw/seamless-tileable-void-haze-layer-soft.png":
        "brief asked for soft haze with no objects; rendered a fleet with a capital ship",
    "raw/seamless-tileable-foreground-dust-layer.png":
        "brief asked for fine dust motes; rendered a large damaged spaceship",
    "raw/seamless-tileable-void-haze-texture-abs.png":
        "brief asked for abstract noise and named spaceships as forbidden; rendered a battlecruiser",
    "raw/deep-space-nebula-veil-a-single-square.png":
        "brief asked for a painterly wash; rendered a fleet of dark warships",
    "raw/full-screen-vignette-burnt-ember-c8461.png":
        "brief asked for an empty-centred edge vignette; rendered a battleship wreathed in ember",
    "raw/single-thin-horizontal-ember-streak-bur.png":
        "brief asked for one thin ember streak; rendered a whole spaceship with an engine trail",
    "raw/small-radial-ember-glow-orb-soft-radial.png":
        "brief asked for a compact radial glow; rendered a heavy industrial spaceship",
    "raw/ui-bar-caps-and-ui-minimap-bezel-one-pa.png":
        "one cell asked for bar caps, the other for a minimap bezel; the caps came out as two "
        "separate objects that were cut as one sprite",
}


def load(name: str) -> dict:
    path = LIBRARY / name
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def measure(path: Path) -> dict:
    """Pixels, bytes, mode, transparency share and md5, read from the file itself."""
    with Image.open(path) as image:
        image.load()
        px = list(image.size)
        mode = image.mode
        alpha_pct = None
        if mode in ("RGBA", "LA") or (mode == "P" and "transparency" in image.info):
            band = image.convert("RGBA").getchannel("A")
            small = band.resize((min(256, band.width), min(256, band.height)))
            alpha_pct = round(float((np.asarray(small) == 0).mean() * 100), 1)
    data = path.read_bytes()
    return {"px": px, "bytes": len(data), "mode": mode, "alpha_pct": alpha_pct,
            "md5": hashlib.md5(data).hexdigest()}


def icon_group(stem: str) -> str | None:
    if not stem.startswith("icon_"):
        return None
    for prefix, _meaning in ICON_GROUP:
        if stem.startswith(f"icon_{prefix}"):
            return prefix
    return "other"


def describe(role: str, family: str, stem: str, v: dict, panel: dict | None) -> str:
    """One sentence an agent can match a need against, built only from what was observed."""
    kind = v.get("kind") or family
    subject = v.get("subject") or v.get("sheet_subject") or stem.replace("_", " ")
    detail = v.get("detail") or ""
    if role in ("sheet", "sheet-keyed"):
        objects = v.get("objects") or []
        shape = (f"{len(objects)} objects" if len(objects) > 1 else "one object")
        head = f"Source sheet holding {shape}: {subject}"
        if detail:
            head += f", {detail}"
        head += "."
        if len(objects) > 1:
            head += f" In reading order: {'; '.join(objects)}."
        return head
    head = f"{kind} asset: {subject}"
    if detail:
        head += f", {detail}"
    head += "."
    if panel:
        head += (f" Cut from {panel['sheet']} panel {panel['panel']} of {panel['of']}"
                 f" ({panel['grid'][0]}x{panel['grid'][1]} grid).")
    if role == "plate":
        head += " Whole-frame plate, not a sprite: it has no object and no background to key."
    return head

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--json-only", action="store_true")
    args = parser.parse_args()

    vision = load("_vision.json").get("files", {})
    sheets = load("_sheets.json").get("sheets", [])
    cuts = load("_cuts_manifest.json")
    originals = load("_originals_manifest.json")
    vocabulary = load("_vocabulary.json")
    if isinstance(originals, dict):
        originals = originals.get("runs", [])

    # raw path -> sheet plan entry, and raw path -> the run that rendered it
    plan = {e["raw"]: e for e in sheets}
    run_of: dict[str, dict] = {}
    for run in originals:
        for f in run.get("files") or []:
            name = f.get("name", "")
            if name.endswith("__raw.png"):
                run_of[f"raw/{name.replace('__raw.png', '.png')}"] = run
    # per sprite: the panel it was cut from, and whether its sheet is a whole-frame plate
    panel_of: dict[str, dict] = {}
    plate_names: set[str] = set()
    for entry in (cuts.get("sheets") or []):
        grid = entry.get("grid") or [1, 1]
        sprites = entry.get("sprites") or []
        if entry.get("plate"):
            name = entry.get("plate_name")
            if name:
                plate_names.add(name)
                panel_of[name] = {
                    "sheet": entry.get("raw"), "panel": 1, "of": 1,
                    "grid": entry.get("grid") or [1, 1], "whole_frame": True,
                }
            continue
        for i, sprite in enumerate(sprites, 1):
            panel_of[sprite.get("name", "")] = {
                "sheet": entry.get("raw"), "panel": i, "of": len(sprites), "grid": grid,
                "row": sprite.get("row"), "col": sprite.get("col"),
                "source_box": sprite.get("source_box"),
                "source_size": sprite.get("source_size"),
                "pieces": sprite.get("pieces"),
            }

    docs = vocabulary.get("docs", {})
    catalog = vocabulary.get("catalog", {})
    code = vocabulary.get("code", {})

    # What already sits in the Godot project under the same name. The prune kept the `fx`
    # family on purpose, so for 19 assets there are two copies playing different roles: the
    # project's is the full 2048 frame, this library's is a re-cut cropped to the object.
    shipped: dict[str, dict] = {}
    if PROJECT_ASSETS.is_dir():
        for path in PROJECT_ASSETS.rglob("*.png"):
            rel = str(path.relative_to(PROJECT_ASSETS)).replace("\\", "/")
            shipped[rel] = measure(path)
    code_by_name: dict[str, list[str]] = collections.defaultdict(list)
    for path, refs in code.items():
        for ref in refs:
            stem = Path(ref).stem
            code_by_name[stem].append(path)
            code_by_name[DERIVED_RE.sub("", stem)].append(path)

    assets: dict[str, dict] = {}
    issues: dict[str, list[str]] = {k: [] for k in
                                    ("placeholder", "twin", "slug", "phase-prefix",
                                     "content-mismatch", "derived-name")}

    def record(rel: str, role: str) -> dict:
        path = LIBRARY / rel
        stem = path.stem
        family = stem.split("_")[0]
        if family not in FAMILY_FOLDER:
            family = "unknown"
        v = vision.get(rel, {})
        panel = panel_of.get(stem) if role in ("sprite", "plate") else None
        if role in ("sheet", "sheet-keyed"):
            entry = plan.get(rel) or {}
            v = dict(v)
            v.setdefault("kind", entry.get("family"))
        name_issue = None
        if PLACEHOLDER_RE.search(stem):
            name_issue = "placeholder"
        elif SLUG_RE.match(stem):
            name_issue = "slug"
        elif TWIN_RE.search(stem):
            name_issue = "twin"
        elif PHASE_RE.match(stem):
            name_issue = "phase-prefix"
        elif DERIVED_RE.search(stem):
            # a derived name is fine on its own, but this library holds masters only
            name_issue = "derived-name"
        if rel in CONTENT_MISMATCH:
            # Only where a render was actually looked at and contradicted its own brief. A
            # guess from the wording is not good enough to put in an index a rename obeys.
            name_issue = "content-mismatch"
        if name_issue:
            issues[name_issue].append(rel)

        folder = FAMILY_FOLDER.get(family, "")
        root = "cut" if role in ("sprite", "plate") else "raw"
        under = path.parent.relative_to(LIBRARY / root).as_posix()
        if under != ".":
            folder = under  # the tree the rename filed it under is the truth
        project_folder = folder.split("/")[0] or FAMILY_FOLDER.get(family, "")
        run = run_of.get((panel or {}).get("sheet") or rel)
        measured = measure(path)
        rec = {
            "name": stem,
            "path": rel,
            "role": role,
            "family": family,
            "folder": folder,
            "icon_group": icon_group(stem),
            "kind": v.get("kind"),
            "subject": v.get("subject") or v.get("sheet_subject"),
            "detail": v.get("detail"),
            "description": describe(role, family, stem, v, panel),
            "objects": v.get("objects"),
            "panels_seen": v.get("panels"),
            "flat_bg": v.get("flat_bg"),
            "measured": measured,
            "keyed": measured["alpha_pct"] is not None,
            "needs_keying": (role == "sprite" and measured["alpha_pct"] is None
                             and family in ("ship", "env", "ui", "icon", "logo", "panel")),
            "content_mismatch": CONTENT_MISMATCH.get(rel),
            "cut_from": panel,
            "ship_to": (f"vajb-orbit/assets/{project_folder}/{stem}.png" if project_folder else None),
            "requested": ({
                "job_id": run.get("job_id"), "model": run.get("model"),
                "stamp": run.get("stamp"), "run_key": run.get("run_key"),
                "prompt": (run.get("prompt") or "")[:600],
            } if run else None),
            "referenced_by": {
                "docs": sorted(docs.get(stem, {}).get("files", [])),
                "catalog_folder": catalog.get(f"{stem}.png"),
                "code": sorted(set(code_by_name.get(stem, []))),
            },
            "name_issue": name_issue,
            "rename_to": None,
        }
        rec["search_terms"] = sorted(set(filter(None, (
            [family, rec["kind"] or "", folder, rec["icon_group"] or ""]
            + stem.split("_")
            + (rec["subject"] or "").split()
            + ((v.get("detail") or "").split())
        ))))
        already = shipped.get(f"{project_folder}/{stem}.png") \
            if project_folder and role in ("sprite", "plate") else None
        rec["in_project"] = ({
            "path": f"vajb-orbit/assets/{project_folder}/{stem}.png",
            "px": already["px"], "bytes": already["bytes"],
            "same_bytes": already["md5"] == measured["md5"],
            "note": ("already imported in the Godot project"
                     + ("" if already["md5"] == measured["md5"]
                        else ", this library copy differs from it")),
        } if already else None)
        return rec

    for path in sorted(CUT.rglob("*.png")):
        rel = path.relative_to(LIBRARY).as_posix()
        assets[rel] = record(rel, "plate" if path.stem in plate_names else "sprite")
    for path in sorted(RAW.rglob("*.png")):
        rel = path.relative_to(LIBRARY).as_posix()
        assets[rel] = record(rel, "sheet-keyed" if path.stem.endswith("__keyed") else "sheet")

    by_md5: dict[str, list[str]] = collections.defaultdict(list)
    for rel, rec in assets.items():
        by_md5[rec["measured"]["md5"]].append(rel)
    duplicates = [sorted(v) for v in by_md5.values() if len(v) > 1]

    families = collections.Counter(r["family"] for r in assets.values())
    roles = collections.Counter(r["role"] for r in assets.values())
    payload = {
        "generated": datetime.now().isoformat(timespec="seconds"),
        "note": ("One record per file in asset-library/cut and asset-library/raw. `description` "
                 "is what the picture shows, read off the render by a vision model and verified "
                 "by eye; `name_issue` is non-null when the file name cannot be trusted. "
                 "Regenerate with staging/cut/build_library.py, never hand-edit."),
        "counts": {"files": len(assets), "roles": dict(roles), "families": dict(families),
                   "duplicate_groups": len(duplicates),
                   "name_issues": {k: len(v) for k, v in issues.items()}},
        "folders": FAMILY_FOLDER,
        "icon_groups": dict(ICON_GROUP),
        "totals": {
            "cut_bytes": sum(r["measured"]["bytes"] for k, r in assets.items() if k.startswith("cut/")),
            "raw_bytes": sum(r["measured"]["bytes"] for k, r in assets.items() if k.startswith("raw/")),
        },
        "duplicate_groups": duplicates,
        "name_issues": issues,
        "assets": assets,
    }

    print(f"files indexed        : {len(assets)}")
    print(f"roles                : {dict(roles)}")
    print(f"families             : {dict(families.most_common())}")
    print(f"duplicate groups     : {len(duplicates)}")
    for key, value in issues.items():
        print(f"name issue {key:<18}: {len(value)}")
    if args.check:
        return

    OUT_JSON.write_text(json.dumps(payload, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {OUT_JSON.relative_to(WORKSPACE)}")
    if args.json_only:
        return
    write_index(payload)
    print(f"wrote {OUT_MD.relative_to(WORKSPACE)}")


def write_index(payload: dict) -> None:
    assets = payload["assets"]
    issues = payload["name_issues"]
    lines: list[str] = []
    add = lines.append
    add("# Vajb Orbit asset index")
    add("")
    add(f"**Generated:** {payload['generated']} by `staging/cut/build_library.py`. "
        "Regenerate, never hand-edit.")
    add("")
    add("One row per file. `what it is` is read off the picture itself, so it is the column to "
        "trust when a name and a description disagree; `name issue` says when they do.")
    add("")
    add(f"**Files:** {payload['counts']['files']} "
        f"({', '.join(f'{v} {k}' for k, v in payload['counts']['roles'].items())}). "
        f"**Data:** {payload['totals']['cut_bytes'] / 1e6:.0f} MB in cut, "
        f"{payload['totals']['raw_bytes'] / 1e6:.0f} MB in raw. "
        f"Every line is also in `_library.json`, which is what code should read.")
    add("")
    add("## How to use this index")
    add("")
    add("1. Find the row whose `what it is` matches your need, in the folder you want.")
    add("2. Read `role` before you use it: a `sprite` is a cut object, a `plate` is a "
        "whole-frame layer with no object to key, a `sheet` is provenance and must never ship.")
    add("3. Replace a name that has a `name issue`; every one of those is listed in "
        "`_library.json` under `name_issues`.")
    add("")
    for folder in ("ships", "icons", "env", "ui", "fx", ""):
        rows = [r for r in assets.values() if r["folder"] == folder and r["path"].startswith("cut/")]
        if not rows:
            continue
        title = folder or "unfiled"
        add(f"## {title} - {len(rows)} file(s)")
        add("")
        if folder == "icons":
            for prefix, meaning in ICON_GROUP:
                group = sorted((r for r in rows if r["icon_group"] == prefix),
                               key=lambda r: r["name"])
                if not group:
                    continue
                add(f"### {prefix} - {meaning} ({len(group)})")
                add("")
                add("| File | px | a | what it is | name issue |")
                add("|---|---|---|---|---|")
                for r in group:
                    add(row(r))
                add("")
        else:
            add("| File | px | a | what it is | name issue |")
            add("|---|---|---|---|---|")
            for r in sorted(rows, key=lambda r: r["name"]):
                add(row(r))
            add("")
    add("## raw sheets - provenance only, never ship these")
    add("")
    add("| File | px | a | what it is | name issue |")
    add("|---|---|---|---|---|")
    for r in sorted((r for r in assets.values() if r["path"].startswith("raw/")),
                    key=lambda r: r["name"]):
        add(row(r))
    add("")
    add("## Files whose name cannot be trusted")
    add("")
    for key, label in (("placeholder", "Placeholder name: `<family>_sheet_NxM_<stamp>[__pNN]`"),
                       ("twin", "Second render colliding with a live name"),
                       ("slug", "The generator's own filename"),
                       ("phase-prefix", "Phase prefix, not a family"),
                       ("content-mismatch", "The name's subject does not match the picture"),
                       ("derived-name", "A derived name, not a master")):
        entries = issues.get(key) or []
        if not entries:
            continue
        add(f"**{label}** - {len(entries)}")
        add("")
        for rel in sorted(entries):
            rec = assets[rel]
            add(f"- `{rec['name']}` - {rec['description']}")
        add("")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def row(r: dict) -> str:
    px = r["measured"]["px"]
    alpha = "-" if r["measured"]["alpha_pct"] is None else f"{r['measured']['alpha_pct']:.0f}%"
    desc = r["description"].replace("|", "/")
    issue = r["name_issue"] or ""
    return (f"| `{r['name']}` | {px[0]}x{px[1]} | {alpha} | {desc} | {issue} |")


if __name__ == "__main__":
    main()
