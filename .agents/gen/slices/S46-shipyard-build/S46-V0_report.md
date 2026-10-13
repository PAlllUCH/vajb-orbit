---
slice: S46
worker: S46-V0
model: hyper/glm-5.3-flash
status: actionable
gate: "1379/0 → 1387/0"
---

# S46-V0 report

## Result
P54's build view is shipped: the SHIPYARD BUILD mode is now the AUCTION house style —
a `HULLS` shelf (10 §3.1's nine recipe rows) then a `MODULES` shelf carrying its staged
caption, each hull row a `Button` + container children rendering the materials bill as
materials (one `<n>× <name>` run per material, family glyph 24 at its own cut,
`<held>/<needed>` from `cargo_qty`), the labour line as the only CR figure, the
`READY` / `MISSING <n>× <material>` chip, and the `BUILD` ActionInline rightmost; the
row press opens the N28 bill sheet, the chip opens the A4 door (6) confirm through the
S25 seam with A6's verbatim shipyard wording. `BUILD_HULL_FORMAT` /
`BUILD_MODULE_FORMAT` are retired. Gate: before `[SUMMARY] passed=1379 failed=0`
(the dispatch's baseline), after `[SUMMARY] passed=1387 failed=0` (the new suite's 8
rows; no other suite moved). `staging/check_wiring.py`: every hard reference resolves.

## Acceptance list answers
1 — `%BuildList` carries `SectionHulls` (`SectionHeader` "HULLS") → the P40 column band
(`HULL · MATERIALS · LABOUR · STATE` + the unnamed chip seat) → the nine rows in
`HULL_RECIPES` order → `SectionModules` ("MODULES") → `ModulesStaged`
(`StationCaption`, the pinned caption) → slack — `shipyard_panel.gd:_fill_build_view`
(:1690) + `_add_build_section_header`/`_add_build_header_band`/`_add_modules_staged_caption`;
pinned by `tests/test_s46_shipyard_build.gd` row 1.
2 — `_build_hull_row` (:1795): `Button` 76 high wearing C4 `ui_row_strip`, children
`RowInner/RowBox/{TitleBox, MaterialsBox, LabourBox, State, BuildChip}`; title = the
catalogue name with N45 trim, meta = the hangar `META_FORMAT` (`CORVETTE CLASS · 1300
HULL · 13 SLOTS`); runs per `_make_build_run` (`60× TUNGSTEN ORE` + glyph 24
`STRETCH_KEEP_ASPECT_CENTERED` + `0/60` from `cargo_qty`); labour value `9 450` +
`CR LABOUR` caption; chip per `_make_build_state_cell`/`_strip_chip_box` (`armory_chip_bg`
+ 1 px `metal_mid`); BUILD chip 96×32 C3, `FOCUS_NONE`. Rows 2–3 of the suite.
3 — `_on_build_row_pressed` (:1990) emits `sheet_requested` with
`_build_sheet_payload`: name + `MATERIALS · <runs>\nLABOUR · 9 450 CR`, no
price/owned keys (N35); suite row 4.
4 — `confirm_requested` signal (:66); `_on_build_chip_pressed` (:2009) emits
`{id, kind, title CONFIRM PURCHASE, body, OK, CANCEL, action queue_build}`; the shell
wires it at `station.gd:1289-1290` and answers through `confirm_action`
(`station.gd:594-599`), whose CANCEL path returns focus (`station.gd:600`);
`confirm_action` (:2032) runs `Shipyard.queue_job` unchanged — the suite drives the
confirmed commit (materials + 9 450 left the account, job queued, `QUEUED · SPEARHEAD`)
and the still-possible refusal (`BUILD REFUSED · MISSING MATERIALS OR CREDITS`, danger).
Suite row 5.
5 — Both formats deleted from the script (`get_script_constant_map()` asserts absence);
a walk of every label in `%BuildList` finds no "TO BUY"/"TO BUILD" and exactly nine
"CR LABOUR" captions — the labour line is the only CR figure. Suite row 6.
6 — `game/shipyard.gd` untouched (byte-stable, no edit); queue/scrap views keep their
S27 wordings (`NO BUILD IN PROGRESS · ONE BUILD AT A TIME (10 §3.3)`, the scrap row
`VANGUARD · 1290 CR OF MATERIALS`), and the model-level law re-proven on a throwaway
profile: commit at queue, one build at a time, full refund on cancel, one session then
collect grants the hull. Suite row 7.
7 — T-175 rider: the pane subtitle already renders through `StationCaption`
(`shipyard_panel.tscn:37-42`, the S41 cure) — already-shipped; **no `PORT`/`STBD`
labels exist anywhere in the shipped panel** (grep over .gd/.tscn finds none — the
surface T-175's row names is not in today's pane), so there was nothing to re-point.
Suite row 8 pins the subtitle's variation.
8 — `tests/test_s46_shipyard_build.gd`: 8 rows, one per item 1–6 plus the T-175 row;
8/0 in the scoped run and inside the full gate.

## Deviations from SLICE.md
- **The confirm body's `<NAME>` reads the class word** ("CORVETTE"), not the catalogue
  ship name ("SPEARHEAD"): A6's shipyard worked example is pinned verbatim
  (`…BUILD CORVETTE FOR 60× TUNGSTEN ORE …`) while the hull's catalogue `name` is
  "Spearhead"; the value is still a catalogue read (`ShipFit.HULLS` `ship_class`,
  never hardcoded). The row title itself stays the catalogue name (the hangar/AUCTION
  idiom). Reversal: point `BUILD_CONFIRM_BODY`'s first `%s` at `_ship_name` and the
  suite's expected string — one line each.
- `_make_inner`'s inner box is named `RowBox` inside `_build_hull_row` (not in the
  shared helper) so the hangar rows' node tree stays byte-stable; the build rows'
  node grammar matches the craft row's.
- `_add_slack` gained an optional `parent` parameter (default keeps the hangar
  target) so the build list can carry its own slack; the hangar call is unchanged.
- The scrap path's press handler is now `_on_scrap_row_pressed(id)` and
  `_build_action_row(text, id)` lost its always-`&"scrap"` kind parameter — the scrap
  view's rendered bytes are unchanged (suite row 7 asserts the wording).

## Evidence
- `timeout 280 $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn -- --suite=test_s46_shipyard_build --quit-after
  1200` → `[SUMMARY] passed=8 failed=0`, no SCRIPT ERROR lines.
- `timeout 280 python3 staging/gate.py --times 1` → `[GATE] run 1: ok - [SUMMARY]
  passed=1387 failed=0` (the wrapper's own SCRIPT ERROR scan: none).
- `python3 staging/check_wiring.py` → `check_wiring: 1582 hard refs, 989 advisory
  refs / every hard reference resolves`.

## Files touched
- `vajb-orbit/ui/station/shipyard_panel.gd` — the build view rebuilt (P54 shelf
  idiom, the confirm seam, the retired CR formats and list price read).
- `vajb-orbit/tests/test_s46_shipyard_build.gd` — new suite (8 rows).
- `vajb-orbit/ui/station/shipyard_panel.tscn` — untouched: the shipped
  BuildView/BuildScroll/BuildList/BuildFooter nodes carry the new view as-is (the
  sections are script-built, the S27 pattern).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The MODULES shelf ships its staged caption while `Shipyard.buildable_modules()` / `module_recipe()` already carry real recipes (S27 landed them; `test_s27_catalog.gd:426-448`) — the rows are one pass away at the module-catalogue wave; the pin names this staging, so the row is the wave's own work item, not a defect. | follow-up | `shipyard_panel.gd` `_fill_build_view` / `_add_modules_staged_caption` |
