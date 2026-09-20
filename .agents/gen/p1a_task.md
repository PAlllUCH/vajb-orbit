# P1a task — mineral + component catalogues (docs 02, 03, 11 §1.1)

Worker: coder. Wave: P1 economy core. Deliverables, exactly two new files:

1. `vajb-orbit/game/mineral_catalog.gd`
2. `vajb-orbit/game/component_catalog.gd`

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`addons/`, `project.godot`, docs, theme, or any existing script.

## Read first

- `docs/gameplay/02_minerals.md` — all. §2 tables are the exact values. §3 is
  the key contract. §5 is the generation data. §6 is the v1 icon plan.
- `docs/gameplay/11_galactic_map.md` — §1.1 ONLY. It **supersedes 02 §5's
  abstract sector ranges** with a per-sector table. Use the §1.1 table.
- `docs/gameplay/03_components.md` — §3 tables (18 components), §4 keys, §4.1
  icons.
- `docs/design/ICONS_SPEC.md` — §8.6 tint table only.
- `vajb-orbit/game/station_catalog.gd` — the style contract: data-only
  `class_name` + `RefCounted`, `const` typed arrays of dictionaries, static
  lookups, `_find` / `_ids` helper shape, header comment citing the doc.

## Rules

- Numbers and ids come only from the docs. Never invent, never "fix" a value.
  If a doc value looks wrong, report it in your report; do not change it.
- GDScript 4 typed style, tabs for indentation, house header comment.
- Descriptions: one line, grimdark STYLE_BIBLE voice; the docs' "Character"
  column is the content source, rewritten as a single sentence. No cutesy
  fantasy wording (Voidglass and Emberite stay sci-fi-exotic).
- `Color("#RRGGBB")` in a `const` must be verified to parse; if const folding
  rejects it, use `Color(r, g, b)` float form and note it.

## Contract — `game/mineral_catalog.gd`

`class_name MineralCatalog extends RefCounted`.

`const MINERALS: Array[Dictionary]` — 20 entries in the doc's order
(T1 iron, copper, chromium, silicon, aluminium; T2 titanium, nickel, cobalt,
tungsten, silver; T3 gold, platinum, neodymium, iridium, osmium; T4 palladium,
cerulite, emberite, voidglass, krillum). Per-entry keys exactly:

- `&"id"` — the base mineral id (e.g. `&"iron"`, `&"voidglass"`). Item ids are
  derived per 02 §1: ore `mineral_<id>`, ingot `ingot_<id>`.
- `&"name"`, `&"tier"` (1–4), `&"ore_value"`, `&"ingot_value"` (int),
  `&"ore_units"` (1), `&"ingot_units"` (1), `&"description"`,
  `&"icon_ore"` (String), `&"icon_ingot"` (String).

v1 icons per 02 §6: every `icon_ore` is
`res://assets/icons/icon_cargo_ore_48.png`, every `icon_ingot` is
`res://assets/icons/icon_cargo_container_48.png`. Tier tint is engine-side;
expose it as data:

`const TIER_TINTS: Dictionary` — `{1: #565C63, 2: #8D939B, 3: #8A6A50,
4: #6E5B4A}` per ICONS_SPEC §8.6.

Generation data (02 §5 as amended by 11 §1.1):

- `const SECTOR_TIER_MIX: Dictionary` — sector int -> Dictionary of
  tier -> weight int: 1 `{1:100}`; 2 `{1:55, 2:45}`; 3 `{1:20, 2:80}`;
  4 `{2:60, 3:40}`; 5 `{2:35, 3:65}`; 6 `{3:55, 4:45}`; 7 `{3:40, 4:60}`.
- `const TIER_BASE_YIELD: Dictionary` — `{1: 6, 2: 5, 3: 4, 4: 3}`.
- `const YIELD_VARIANCE_MIN := 0.5` / `YIELD_VARIANCE_MAX := 1.5`.

Static helpers:

- `static func mineral(id: StringName) -> Dictionary` — {} when unknown.
- `static func mineral_ids() -> Array[StringName]`.
- `static func tier_minerals(tier: int) -> Array[Dictionary]`.
- `static func ore_id(mineral_id: StringName) -> StringName` — `iron` ->
  `mineral_iron`; `&""` for unknown.
- `static func ingot_id(mineral_id: StringName) -> StringName` — `iron` ->
  `ingot_iron`; `&""` for unknown.
- `static func mineral_id_of_item(item_id: StringName) -> StringName` —
  accepts any of `iron` / `mineral_iron` / `ingot_iron`, returns `iron`;
  `&""` when unknown.
- `static func entry_for_item(item_id: StringName) -> Dictionary` — the row
  for either item state; {} when unknown.
- `static func is_ore(item_id: StringName) -> bool`,
  `static func is_ingot(item_id: StringName) -> bool`.
- `static func sector_mix(sector: int) -> Dictionary` — clamped to 1..7,
  outside range returns {} .
- Generation rolls (02 §5), deterministic through the passed rng:
  - `static func roll_tier(sector: int, rng: RandomNumberGenerator) -> int`
    — weighted pick from `SECTOR_TIER_MIX`, sectors 1..7; 0 when the sector
    has no mix. Actual asteroid spawning is a later phase; this file only
    owns the data and the rolls.
  - `static func roll_mineral(tier: int, rng: RandomNumberGenerator) -> Dictionary`
    — uniform within the tier, returns the row ({} for an empty tier).
  - `static func roll_yield(tier: int, rng: RandomNumberGenerator) -> int` —
    `maxi(1, roundi(base * rng.randf_range(YIELD_VARIANCE_MIN, YIELD_VARIANCE_MAX)))`.

Header comment: cite docs 02 + 11 §1.1; note that spawning/mining flow is P3.

## Contract — `game/component_catalog.gd`

`class_name ComponentCatalog extends RefCounted`.

`const COMPONENTS: Array[Dictionary]` — 18 entries, doc order per family
(salvage, mech, elec, weap, pow, ore_grade; grade 1–3 within each). Keys:
`&"id"`, `&"name"`, `&"family"` (StringName: `&"salvage"`, `&"mech"`,
`&"elec"`, `&"weap"`, `&"pow"`, `&"ore_grade"`), `&"grade"` (1–3),
`&"value"` (int), `&"units"` (1), `&"description"`, `&"icon"` (String).

Icons per 03 §4.1:
salvage -> `res://assets/icons/icon_cargo_salvage_48.png`;
mech -> `.../icon_cargo_crate_48.png`; elec -> `.../icon_cargo_data_core_48.png`;
weap -> `.../icon_cargo_container_48.png`; pow ->
`.../icon_cargo_fuel_cell_48.png`; ore_grade -> `.../icon_cargo_ore_48.png`.

`const GRADE_TINTS: Dictionary` — `{1: #565C63, 2: #8D939B, 3: #8A6A50}`
(03 §4.1: I steel, II gunmetal-bright, III ochre; reconciled with ICONS_SPEC
§8.6's sanctioned hexes; never the ember accent).

Static helpers: `component(id) -> Dictionary` ({} unknown),
`component_ids() -> Array[StringName]`, `family_components(family) ->
Array[Dictionary]`, `grade_components(grade: int) -> Array[Dictionary]`.

## Parse gate (required, after each file and once at the end)

Create a probe scene `res://tools/_probe_p1a.tscn` + `_probe_p1a.gd` that in
`_ready()` preloads both scripts and asserts: 20 minerals, 18 components, all
20 ore ids and ingot ids resolve, tints/tables non-empty; prints
`PROBE OK`; then `get_tree().quit()`. Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1a.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, stdout has no
`SCRIPT ERROR`. Do NOT use `--check-only --script` (known false negatives).
Delete `_probe_p1a.gd`, `_probe_p1a.tscn` and any `.uid` sidecars they got
before you finish.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14` for text work.
- The bash tool strips `$` before PowerShell sees it — write PowerShell with
  no `$`.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1a_report.md`: deliverables table, exact commands run with
observed output, probe results, every doc value you could not reproduce, and
anything a reviewer should look at. Under 120 lines.
