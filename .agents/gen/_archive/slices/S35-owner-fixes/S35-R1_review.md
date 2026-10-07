---
slice: S35
worker: S35-R1
reviewed: S35-B1
model: hyper/glm-5.3-flash @ max
status: pass
gate: "1136/0 ×2 fresh scratch (re-measured)"
---

# S35-R1 review — the owner's fix round: one sell selector, preview clear, one shared menu

## Method

Re-measured, not trusted. Gate run twice on fresh scratch
(`XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit
res://tests/headless_runner.tscn --quit-after 1200`): `[SUMMARY] passed=1136
failed=0`, exit 0, zero `SCRIPT ERROR`, **both runs**. Independent probe
`vajb-orbit/tests/probe_s35_review.gd` (+ `.tscn`, left as evidence; run
headless the same way): 38 checks, `failures=0`. Change set read in full
(`git diff HEAD`: 2 production pairs + 8 test files + 2 probes, +449/−563).
Spec basis: UI_SPEC §14 (N49 amended 2026-10-05), §11.1 N24, §12.5 N31,
§3.10 A5; STATION_HUB §21.1 P38a/P39a.

## Acceptance list (graded first)

| # | Pin | Grade | Evidence (re-measured) |
|---|---|---|---|
| 1 | One quantity control; MAX fills, 0 empties, bounds 0..row units | **pass** | probe e1/e2: TradeBox holds exactly one stepper row, `StepperRow` absent; e5 floor 0, e6 ceiling 5/5; e8 0-chip empties + SELL disables; e9 MAX fills + SELL wakes; code `exchange_panel.gd:741` (`clampi(value, 0, maxi(0, held))`), chips `:753-763` |
| 2 | SELL moves exactly the selector; disabled at 0 / no selection; no second selector | **pass** | probe e10/e11: press on `%SellButton` moved cargo 5→2 and paid (+44 CR, quoted gross 54); e7 disabled with no selection; `:690` (`not armed or _sell_units <= 0`); e4 grep + scene: no `StepperRow`/`_set_step` anywhere |
| 3 | Click-away clears selection + preview; hint idles | **pass** | probe b5–b8: empty-chrome press clears `_selected`, `_candidate`, CELL INFO → `CELL_INFO_SELECT`, hint → `PANE_HINT_FIT`; b9 idempotent; b11 a press outside the pane's rect does nothing. Routing `armory_panel.gd:1110-1124`, `_clear_away` `:1137-1151` |
| 4 | ONE shared menu in both modes; identical categories; single builder | **pass** | probe a3/a4/a6: `%MenuSector` reparents FitRight↔EqSector on `set_mode` — the same subtree; a5 identical 10-label set both modes (AMMUNITION leads); a7 grep: `_build_eq`/`_refresh_eq` gone, exactly one `func _build_browser(` (`armory_panel.gd:3783`) |
| 5 | Mode behavior intact through the public doors | **pass** | probe c2 row press fits (bag 2→1, `fit_for` W1 = laser); c3 FIT drag = `DRAG_BROWSER`; c4 BATTERY weapon row = `DRAG_INVENTORY` (`:3696`); c5/c6 `install_weapon` persists into the rack record. Gate rows `test_a_owned_row_fits_by_press_and_by_drag`, `test_buy_on_a_buyable_row_buys_then_fits`, `test_a_rack_drag_persists_through_the_battery_record` all green (see F2) |
| 6 | Gate ×2 + every moved row disclosed | **pass** | gate 1136/0 ×2 above; every moved row in the report's table verified in the diffs (all 11 rows + 2 probes moved exactly as named); the 4 promised new rows landed (`test_n49_the_max_and_zero_quick_buttons`, `test_n49_no_second_units_selector`, `test_p38a_click_away_clears_the_selection_and_preview`, `test_p39a_one_shared_menu_in_both_modes`) — +4 = 1132→1136 exactly (1132 corroborated by WAVEBOARD's S34 close) |

## Pin table (graded second)

| Pin | Verdict |
|---|---|
| N49-amended (one `SELL UNITS` selector, min 0, MAX/0 chips, SELL disabled at 0/no selection, the S33 duplicate dies) | **met** — the P2 `ActionInline` chips are plain theme Buttons at the pinned 96×32 (`exchange_panel.tscn`), beside the stepper; `_quoted`/`_confirm_strip` correctly idle at 0 (`:694-695`) |
| P38a (press outside every socket and row clears selection + preview) | **met** — empty-chrome routing only: controls consume their presses before `_unhandled_input`; the pane-rect guard keeps shell clicks out; a press is a command (N31), so the `_refresh_browser` rebuild it triggers is legal |
| P39a (one shared menu component; modes differ only in row actions + the FIT CELLS socket filter) | **met** — one subtree reparented on the mode switch (`:996-998`); the socket filter is FIT-only (`_equip_rows` `cell_filter`, `:3850`); BATTERY stays a flat browse list whatever the grid selection is |
| A5.5/N24 (no hover/focus/selection mutation of size/position/visible/tree) | **met** — the only tree mutation in the diff is the mode-switch reparent (a command); the added scene lines carry no state-path mutation; hover paths untouched |
| §3.10 A5 (containers + anchors, never coordinates) | **met** — `%MenuSector` is a VBoxContainer under `FitRight`; `EqSector` stays an empty VBoxContainer host; the chips size by `custom_minimum_size`; no new `_position_*` code |

## Findings

- **S35-B1/F1 · LOW** — the report's trade-column measure reads 393/57 px; the headless
  re-measure reads **392/56** (`measure trade_min=392.0 row_min=392.0 value_min=56.0`;
  the scene's `TradeBox` min stays 360, the growth is child-derived). Substance verified:
  the row seats both 96 px chips with no clip and lands inside 1920 (probe e12/e13).
  Report-accuracy nit only.
- **S35-B1/F2 · LOW** — BATTERY CONFIG's new menu-row drag route
  (`drag_browser`'s battery branch, `armory_panel.gd:3696`) has **no gate row** pinning it:
  acceptance 5 is answered with `test_a_rack_drag_persists_through_the_battery_record`,
  which exercises `drag_barrel`, not the new route. True this pass (probe c4/c5), but a
  future regression there cannot fail the gate. Suggest a one-row follow-up: battery-mode
  `drag_browser` returns `DRAG_INVENTORY` and `drop` persists it.
- **S35-B1/F3 · LOW** — brief §7 promised a **new** row "mode actions intact"; none was
  added — the item is answered by the three unchanged rows plus the probe. Coverage is
  real, the promised new-row list is unfulfilled literally.
- **S35-B1/F4 · LOW (owner taste, disclosed)** — `POWER` supersedes P39's `PWR/FUEL RODS`
  and the landing category is `ALL`, not AMMUNITION; both are B1's disclosed deviations
  with reversals, consequences of P39a's "identical categories". Owner confirms or
  reverses; nothing for a fixer.

B1's own follow-up rows (stale `probe_s32_review`/`probe_s33_review` reading retired
nodes — confirmed, they are the only files left naming `%ArmoryRows`/`%EqTabs`) are
acknowledged hygiene outside this wave's file set; no new finding.

## Verdict

**pass** — no HIGH, no MED; no fixer dispatch. All six acceptance items re-measured
green, every pin met, the disclosure duty complete. Evidence probes left in place:
`vajb-orbit/tests/probe_s35_review.gd` + `probe_s35_review.tscn`
(`[r35] failures=0`, 38 checks).
