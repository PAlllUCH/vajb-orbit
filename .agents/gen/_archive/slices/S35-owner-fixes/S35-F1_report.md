---
slice: S35
worker: S35-F1
model: hyper/deepseek-v4.1-flash @ xhigh
status: informational
gate: "1136/0 → 1138/0 (×2 fresh scratch)"
---

# S35-F1 report — the fix round: the FIT CELLS subtitle + two gate rows

## Result
Three items cured, nothing else. D22-P1/F01 (MED): the ARMORY `%PaneSubtitle` now
follows the mode (`_update_subtitle`), so FIT CELLS reads its own wording, never
the battery descriptor. The two cheap S35-R1 gate gaps are closed with two new
rows in `test_s32_armory_modes.gd`. Gate **1136/0 → 1138/0**, both runs fresh.

## Acceptance list answers (the fix list, item by item)
1 — **F01 (MED) — DONE.** `_subtitle.text` is set per mode by `_update_subtitle`
(`armory_panel.gd:1032`): FIT CELLS reads `SUBTITLE_FIT` (`:103`)
`"FIT CELLS AND EQUIPMENT - %d CELLS - %d MODULES"` with two live counts
(`_cell_total` `:1043`, `_owned_module_total` `:1055`), BATTERY CONFIG keeps
`SUBTITLE`. Called from `_apply_style` (`:1258`), `_apply_mode` (`:1012`) and
`refresh_profile` (`:1084`, so the counts stay live). PROPOSED wording + reversal
below. A5.5/N24: a mode command sets text in a pinned box (N31's legal set); no
hover/focus path reaches it.
2 — **S35-R1/F2 (LOW) — DONE.** New row `test_a_battery_menu_row_drags_the_rack_route`
(`test_s32_armory_modes.gd:788`) pins `drag_browser`'s battery branch
(`armory_panel.gd:3740`) → `DRAG_INVENTORY` + `drop` → `install_weapon` persist
through the rack door.
3 — **S35-R1/F3 (LOW) — DONE.** New row `test_mode_actions_intact_through_the_public_doors`
(`test_s32_armory_modes.gd:721`) pins FIT CELLS fit / drag / BUY + BATTERY CONFIG
drag persist — brief §7's promised new row.

## Deviations / PROPOSED wording
- **PROPOSED (S35-F1, 2026-10-05):** FIT CELLS subtitle
  `"FIT CELLS AND EQUIPMENT - %d CELLS - %d MODULES"` — the mode's subject (cell
  grid + equipment list) in `SUBTITLE`'s exact shape; the two counts are the
  active hull's fit cells and the module bases the bag owns. **Reversal:** hide
  `%PaneSubtitle` in FIT CELLS instead (D22-P1/F01's own alternative), or any
  other subject/count pair. The wording is marked PROPOSED in the code comment
  (`armory_panel.gd:101-104`).
- No pin changed silently. `SUBTITLE`, `PANE_HINT*`, the mode labels, the pinned
  interfaces and every other constant are untouched.

## Evidence
Gate, fresh scratch each run (`XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot
--headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`):
- before: `[SUMMARY] passed=1136 failed=0`
- after: `[SUMMARY] passed=1138 failed=0`; again `[SUMMARY] passed=1138 failed=0`
- zero `SCRIPT ERROR` in every run.

F01 probe `vajb-orbit/tests/probe_s35_f1_subtitle.tscn` (+ `.gd`, left as
evidence; run headless the same way, `--quit-after 300`): `[f1] failures=0`,
4 checks, decisive prints:
`fit subtitle='FIT CELLS AND EQUIPMENT - 11 CELLS - 0 MODULES'` and
`battery subtitle='BATTERY RACKS AND AMMUNITION - 5 RACKS - 8 PACKS'`.

F2/F3 are gate rows inside the 1138 count (the +2 over the 1136 baseline).

## Files touched
- `vajb-orbit/ui/station/armory_panel.gd` — `SUBTITLE_FIT` const (`:103`),
  `_update_subtitle`/`_cell_total`/`_owned_module_total` (`:1032`/`:1043`/`:1055`);
  `_apply_style`/`_apply_mode`/`refresh_profile` call it.
- `vajb-orbit/tests/test_s32_armory_modes.gd` — two new rows (F3 `:721`, F2 `:788`).
- `vajb-orbit/tests/probe_s35_f1_subtitle.gd` + `.tscn` — F01 evidence probe (new).

## Follow-ups
None.
