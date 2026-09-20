"""Build the sheet plan: one entry per raw render, saying how many panels it holds,
in what reading order, and what each panel is called.

Inputs (all read-only):
  asset-library/_originals_manifest.json  one entry per generation run: stamp, run key,
                                          the exact prompt, the asset names it produced
  asset-library/_deleted_manifest.json    every shipped sprite with the raw sheet it
                                          was cut from
  staging/cut/spec_runs.json              grid + ordered cut names recovered from the
                                          deleted Phase D/E/F drivers (git history)

Output:
  asset-library/_sheets.json

The plan is intent only. It carries the grid, the panel order and the names; the
cutter resolves the actual pixel boxes and records what it did in
asset-library/_cuts_manifest.json.

Usage:
    py -3.14 staging/cut/build_plan.py
"""
from __future__ import annotations

import json
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
SPECS = Path(__file__).resolve().parent / "spec_runs.json"
PLAN = LIBRARY / "_sheets.json"

FAMILIES = ("ships", "env", "ui", "icons", "fx")

# Every cut carries the prefix of the family it belongs to, so a flat cut/ folder still
# says what each file is.
PREFIX = {"ships": "ship", "env": "env", "ui": "ui", "icons": "icon", "fx": "fx"}

# Cell order of the 2x2 ship rotation sheets. wave1.py's SHEET_GRID constant states it
# verbatim: top-left front, top-right three-quarter, bottom-left side, bottom-right back.
SHIP_ROTATION = ("front", "three_quarter", "side", "back")
# Cell order of the 2x2 slot plates, from the ui_slot_* prompts: top-left normal,
# top-right hover, bottom-left pressed, bottom-right disabled.
SLOT_STATES = ("normal", "hover", "pressed", "disabled")

# Sheets whose layout is not recoverable from a spec or a name suffix. Each entry is
# (cols, rows, ordered names, why).
BESPOKE = {
    "20260917-183047": (
        3,
        3,
        [f"env_asteroid_{size}{i}" for size in ("L", "M", "S") for i in (1, 2, 3)],
        "prompt rows: row 1 three large, row 2 three medium, row 3 three small, "
        "left to right; names carry the L/M/S size and a per-row index",
    ),
    "20260917-183655": (
        2,
        1,
        ["ui_bar_caps", "ui_minimap_bezel"],
        "prompt: two groups on one row, bar end caps left, minimap bezel right",
    ),
    # The three Phase B icon atlases. They shipped as whole sheets, so their cells have no
    # shipped name of their own to be read back, but ICONS_SPEC section 5 names every glyph
    # and section 7 sanctions the twenty output names; without these entries those twenty
    # icons the UI asks for have no sprite at all.
    "20260917-183245": (
        2,
        3,
        ["icon_weapon_laser", "icon_weapon_cannon", "icon_weapon_rocket",
         "icon_weapon_mine", "icon_weapon_plasma"],
        "ICONS_SPEC 5 panel 1 weapons: 2x3, laser, cannon, rocket, mine, plasma, last cell blank",
    ),
    "20260917-183446": (
        2,
        3,
        ["icon_cargo_ore", "icon_cargo_crate", "icon_cargo_container",
         "icon_cargo_fuel_cell", "icon_cargo_salvage", "icon_cargo_data_core"],
        "ICONS_SPEC 5 panel 2 cargo: 2x3, ore, crate, container, fuel cell, salvage, data core",
    ),
    "20260917-183722": (
        3,
        3,
        ["icon_gear", "icon_close", "icon_zoom_plus", "icon_zoom_minus", "icon_credits",
         "icon_shield", "icon_hull", "icon_ammo", "icon_logout"],
        "ICONS_SPEC 5 panel 3 glyphs: 3x3, gear, close, zoom plus, zoom minus, credits, "
        "shield, hull, ammo, logout",
    ),
}

WORD_NUMBERS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
}

# A sheet is a *plate* when it is a whole-frame layer rather than an object on a
# background: a backdrop, a tiling layer, a menu or loading screen, or a full-frame
# vignette. Plates are copied whole -- cropping or centring them would break the layer --
# while everything else is cut out as a sprite and centred.
PLATE_RE = re.compile(
    r"seamless|tileable|tiling|backdrop|background plate|full[- ]frame|full screen|wallpaper"
    r"|nebula veil|vignette|menu background|loading screen|sector backdrop", re.I)

# Whole-frame layers whose prompts never say so: the two wide menu/loading vistas read as
# scenes, and a shipped `panel_*` asset is a sheet in its own right rather than one object.
PLATE_NAMES = {"env_menu_bg", "env_loading_bg"}

# Phrases that mean "this sheet is a whole-frame layer". A prompt that rules one out
# ("no backdrop", "no vignette") must not count, so each match is checked for a negation in
# front of it.
NEGATION_RE = re.compile(r"\b(no|not|never|without|avoid)\b[^.]{0,12}$", re.I)

GRID_RE = re.compile(r"(\d+)\s*(?:x|by)\s*(\d+)\s*(?:grid|rotation sheet|grid panel)", re.I)
COLROW_RE = re.compile(r"(\w+)\s+columns?,\s*(\w+)\s+rows?", re.I)
FRAME_RE = re.compile(r"(\d+)[- ]frame", re.I)


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def reads_as_plate(prompt: str, mode: str | None, names: list[str]) -> tuple[bool, str]:
    """Whether a sheet is a whole-frame layer rather than an object on a background."""
    if mode == "single_full":
        return True, "the recovered spec says single_full"
    if names and names[0] in PLATE_NAMES:
        return True, "it is a shipped background plate"
    if len(names) == 1 and names[0].startswith("panel_"):
        return True, "it is a shipped panel asset with no named cells"
    for match in PLATE_RE.finditer(prompt):
        if NEGATION_RE.search(prompt[:match.start()]):
            continue
        return True, f"the prompt says {match.group(0)!r}"
    return False, ""


def raw_index() -> list[str]:
    """Every gathered raw sheet, as stems, from the flat raw/ folder."""
    folder = LIBRARY / "raw"
    return sorted(p.stem for p in folder.glob("*.png")) if folder.is_dir() else []


def raw_for_run(run, stems: list[str]) -> str | None:
    """Match a run to its raw sheet.

    Prefix matching alone is ambiguous (`ship_vanguard` also prefixes
    `ship_vanguard_damaged` and `ship_vanguard_mmo`), so an exact run-key match wins
    first, then a stem carrying the stamp, and only a lone candidate is accepted
    without either.
    """
    key = run["run_key"]
    candidates = [stem for stem in stems if stem.startswith(key)]
    if key in candidates:
        return key
    stamped = [stem for stem in candidates if run["stamp"] in stem]
    if len(stamped) == 1:
        return stamped[0]
    if len(candidates) == 1:
        return candidates[0]
    return None


def sprite_names(deleted) -> dict[str, list[str]]:
    """raw stem -> the shipped sprites that were cut from it."""
    out: dict[str, list[str]] = {}
    for entry in deleted["files"]:
        raw, name = entry.get("raw"), entry["path"].rsplit("/", 1)[-1]
        if not raw or not name.endswith(".png"):
            continue
        stem = raw.rsplit("/", 1)[-1].removesuffix(".png").removesuffix("__raw")
        out.setdefault(stem, []).append(name[: -len(".png")])
    return out


def infer_grid(prompt: str) -> tuple[int, int] | None:
    """[cols, rows] as the project writes it: `AxB` is A columns by B rows, and an
    explicit `(two columns, three rows)` clause always wins -- the prompts use both
    readings of `2x3`, so the parenthetical is the only safe source."""
    colrow = COLROW_RE.search(prompt)
    if colrow:
        left, right = colrow.group(1).lower(), colrow.group(2).lower()
        cols = WORD_NUMBERS.get(left) or (int(left) if left.isdigit() else None)
        rows = WORD_NUMBERS.get(right) or (int(right) if right.isdigit() else None)
        if cols and rows:
            return cols, rows
    grid = GRID_RE.search(prompt)
    if grid:
        return int(grid.group(1)), int(grid.group(2))
    frames = FRAME_RE.search(prompt)
    if frames:
        return int(frames.group(1)), 1
    return None


def spec_names(spec) -> list[str]:
    """The ordered names a recovered spec produces: its cuts, or its single output."""
    return list(spec.get("cuts") or ([spec["out"]] if spec.get("out") else []))


def spec_lookup(specs) -> dict[frozenset, list]:
    """Index the recovered specs by the set of names they produce."""
    index: dict[frozenset, list] = {}
    for key, spec in specs["sheets"].items():
        names = spec_names(spec)
        if not names:
            continue
        index.setdefault(frozenset(names), []).append((key, spec, names))
    return index


def classify(names: list[str]):
    """Sheet kinds whose panel order is fixed by a name suffix on a shared stem.

    One extra `<stem>_panel` name is accepted alongside the panels: it is the sheet's
    own panel master, which ships as the whole sheet rather than as a cell.
    """
    for order, kind in ((SHIP_ROTATION, "ship rotation"), (SLOT_STATES, "slot state")):
        for master in (None, "panel"):
            wanted = set(order) | ({master} if master else set())
            stems, suffixes = set(), set()
            for name in names:
                suffix = next((s for s in wanted if name.endswith("_" + s)), None)
                if suffix is None:
                    stems = set()
                    break
                stems.add(name[: -(len(suffix) + 1)])
                suffixes.add(suffix)
            if len(stems) != 1 or suffixes != wanted:
                continue
            stem = stems.pop()
            extra = [f"{stem}_{master}"] if master else []
            return 2, 2, [f"{stem}_{s}" for s in order], extra, kind
    return None


def resolve_grid(spec, cuts: list[str], prompt: str) -> tuple[int, int]:
    """A spec may declare no grid -- those sheets were split by connected component.

    None of them is a single shape per cell, so the prompt's own grid clause is the
    fallback, and a one-row strip is the last resort.
    """
    if spec.get("grid"):
        return tuple(spec["grid"])
    if len(cuts) == 1:
        return 1, 1
    return infer_grid(prompt) or (len(cuts), 1)


def resolve_names(sheets: list[dict]) -> list[tuple]:
    """Give every output name exactly one owner, and stamp the sheets that lose.

    Two runs can render the same asset (a Phase B plate that a Phase F pass redrew). The
    run whose panel was actually shipped owns the plain name; the other sheet still gets
    cut, under `<name>__<stamp>`, so the render stays browsable without overwriting.
    """
    owner: dict[str, str] = {}
    stamps: dict[str, str] = {}
    for sheet in sorted(sheets, key=lambda item: item["stamp"]):
        for name in sheet["cuts"] + sheet["master"]:
            if name in sheet["shipped"]:
                # Several runs can ship the same name (a Phase B glyph redrawn in Phase F).
                # The newest render is the one the project held, so it keeps the plain name.
                owner[name] = sheet["raw"]
                stamps[name] = sheet["stamp"]

    clashes = []
    for sheet in sheets:
        cuts, superseded = [], []
        for name in sheet["cuts"]:
            holder = owner.get(name)
            if holder and holder != sheet["raw"]:
                renamed = f"{name}__{sheet['stamp']}"
                superseded.append({"name": name, "cut_as": renamed, "superseded_by": holder})
                cuts.append(renamed)
            else:
                cuts.append(name)
        sheet["cuts"] = cuts
        if superseded:
            sheet["superseded"] = superseded

    seen: dict[str, str] = {}
    for sheet in sheets:
        for name in sheet["cuts"] + sheet["master"]:
            if name in seen:
                clashes.append((name, seen[name], sheet["raw"]))
            seen[name] = sheet["raw"]
    return clashes


def build() -> dict:
    runs = load(LIBRARY / "_originals_manifest.json")["runs"]
    deleted = load(LIBRARY / "_deleted_manifest.json")
    specs = load(SPECS)
    raws = raw_index()
    by_raw = sprite_names(deleted)
    spec_index = spec_lookup(specs)

    sheets, problems = [], []
    for run in runs:
        name = raw_for_run(run, raws)
        if name is None:
            problems.append((run["family"], run["stamp"], run["run_key"], "no raw sheet on disk"))
            continue

        shipped = sorted(set(by_raw.get(name, [])))
        produced = sorted(set(run["produced_assets"]))
        names = shipped or produced
        if shipped and produced and not set(shipped) <= set(produced):
            problems.append((run["family"], run["stamp"], run["run_key"],
                             f"attributed sprites not in the run's produced list: "
                             f"{sorted(set(shipped) - set(produced))}"))

        entry = {
            "family": run["family"],
            "stamp": run["stamp"],
            "run_key": run["run_key"],
            "raw": f"raw/{name}.png",
            "produced": produced,
            "shipped": shipped,
            "master": [],
            "planned_grid": None,
        }

        match = spec_index.get(frozenset(names))
        bespoke = BESPOKE.get(run["stamp"])
        ordering = classify(names)
        if match and len({tuple(m[1].get("grid") or ()) for m in match}) == 1:
            key, spec, spec_cuts = match[0]
            grid = resolve_grid(spec, spec_cuts, run["prompt"])
            entry.update(grid=list(grid), cuts=spec_cuts,
                         mode=spec["mode"] or ("single" if len(spec_cuts) == 1 else "panel"),
                         plan_from=f"spec {key} (recovered)")
        elif bespoke:
            cols, rows, cuts, why = bespoke
            entry.update(grid=[cols, rows], cuts=cuts, mode="panel", plan_from=why)
        elif ordering:
            cols, rows, cuts, master, kind = ordering
            entry.update(grid=[cols, rows], cuts=cuts, master=master, mode="panel",
                         plan_from=f"name suffix ({kind})")
        elif not names:
            grid = infer_grid(run["prompt"]) or (1, 1)
            cols, rows = grid
            slug = f'{PREFIX[run["family"]]}_sheet_{cols}x{rows}_{run["stamp"].replace("-", "_")}'
            cuts = ([slug] if cols * rows == 1
                    else [f"{slug}__p{index:02d}" for index in range(1, cols * rows + 1)])
            entry.update(grid=[cols, rows], cuts=cuts, mode="panel",
                         plan_from="prompt grid, unnamed sheet - panels are numbered only",
                         unnamed=True)
        elif len(names) == 1:
            entry.update(grid=[1, 1], cuts=list(names), mode="single",
                         plan_from="single-panel sheet")
        else:
            grid = infer_grid(run["prompt"]) or (1, len(names))
            entry.update(grid=list(grid), cuts=list(names), mode="panel",
                         plan_from="prompt grid, names in the run's produced order")
            problems.append((run["family"], run["stamp"], run["run_key"],
                             f"grid from the prompt only: {grid}, {len(names)} names"))

        # Judged on the plan's own cells, not on what shipped: an atlas whose cells are now
        # named is no longer a plate, however it was shipped.
        entry["plate"], entry["plate_because"] = reads_as_plate(
            run["prompt"] or "", match[0][1].get("mode") if match else None, entry["cuts"])
        if entry["plate"] and len(entry["cuts"]) > 1:
            problems.append((run["family"], run["stamp"], run["run_key"],
                             "reads as a whole-frame plate but the plan splits it into panels"))

        cols, rows = entry["grid"]
        if cols * rows < len(entry["cuts"]):
            problems.append((run["family"], run["stamp"], run["run_key"],
                             f"grid {cols}x{rows} holds {cols * rows} cells but the plan "
                             f"names {len(entry['cuts'])} panels"))
        entry["planned_grid"] = list(entry["grid"])
        entry["name_count"] = len(entry["cuts"])
        sheets.append(entry)

    sheets.sort(key=lambda s: (s["family"], s["raw"]))
    clashes = resolve_names(sheets)
    for name, first, second in clashes:
        problems.append((second.split("/")[0], "", "", f"duplicate output name {name} (also {first})"))
    plan = {
        "note": (
            "One entry per gathered raw sheet. `grid` is [cols, rows]; `cuts` is the panel "
            "order, left to right then top to bottom. `mode` single means one panel, nothing "
            "to split. `master` names ship as the whole sheet. `plan_from` records where the "
            "layout came from; `superseded` records a panel renamed because another sheet "
            "owns the plain name. Panels are cut at their boundaries only: no background "
            "keying, no trimming."
        ),
        "counts": {
            "sheets": len(sheets),
            "panels": sum(s["name_count"] for s in sheets),
            "by_family": {f: sum(1 for s in sheets if s["family"] == f) for f in FAMILIES},
        },
        "sheets": sheets,
    }
    PLAN.write_text(json.dumps(plan, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return plan, problems


def main() -> int:
    plan, problems = build()
    counts = plan["counts"]
    print(f"sheets {counts['sheets']}  panels {counts['panels']}  {counts['by_family']}")
    print(f"wrote {PLAN}")
    if problems:
        print(f"\n{len(problems)} sheet(s) need a look:")
        for family, stamp, key, why in problems:
            print(f"  {family:6} {stamp} {key[:44]:44} {why}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
