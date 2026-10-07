---
slice: S32
worker: S32-B1
model: hyper/deepseek-v4.1-flash
status: informational
gate: "1099/0 → 1110/0"
---

# S32-B1 report

## Result
`ui/station/armory_panel.{gd,tscn}` now ship two full-screen modes behind the header switch:
FIT CELLS (cell grid + CELL INFO + FITS HERE + BUYABLE THAT FITS) and BATTERY CONFIG (B1–B5
racks + read-only empty W cells), with AMMUNITION + the PWR meter in one shared foot band.
Gate 1099/0 → 1110/0 (the +11 are the new suite's rows); no moved row lost a count.

## Acceptance list answers
1 — P32: two modes + the switch, exactly one visible — `set_mode`/`_apply_mode`
(armory_panel.gd:982-1006) toggle `%FitCells`/`%BatteryConfig` visibility only; probe
`test_the_mode_switch_shows_exactly_one_mode`.
2 — P33: CELL INFO complete for the selected cell — `_refresh_cell_info` (:2050) writes
id+family, draw/PWR, fitted-or-EMPTY and the legality line (`_cell_legality` :2088); FITS HERE
= exactly the legal owned candidates (`_fits_here_rows` :2449, family + `fit_legal`), probed
against a re-derived expectation; select-to-fit (`_on_fits_here_pressed` :2554) and drag-to-fit
(`cell_drop` :3880) both land in W2; BUYABLE filters to the cell (`_browser_ids` :3961) and BUY
buys-then-fits.
3 — P34: B1–B5 racks over fitted weapons — the console's bays, kept; a drag between racks
persists through the record (`move_rack_cell` → `set_battery_groups`, probed by `battery_groups`);
`W<n> — EMPTY` read-only Labels (`_refresh_empty_cells` :2028); SALVO meter + `battery_cycle` =
the slowest member (rocket 12.0 s → figure 1200).
4 — P35: no preset/save UI — grep row `test_no_preset_or_save_surface_ships` (script + scene clean).
5 — P36: AMMUNITION + PWR in the shared `%FootBand` on both modes; no `%BodyScroll` —
`test_the_foot_band_is_shared_by_both_modes`.
6 — P37: every row control inside 1920×1080 — `test_every_row_control_lands_inside_the_window`
(all weapon modules owned, longest names included; FITS HERE + BUYABLE rows within x 0..1920).
7 — Gate: 1099/0 before → 1110/0 after, ×2 fresh scratch; moved rows disclosed below.

## Deviations from SLICE.md
- Modes are container-based (A5.2(i)); BATTERY CONFIG keeps the pinned console geometry (P6,
  1360×516) because d7/s15/s18/s20 pin `block_size()`/`bay_rects()`/`well_rects()`. The console's
  wells are reused for the empty-cell list + summary, so no wells block is dead. Reversal: rebuild
  the racks as full-width rows and re-anchor those four suites.
- The console sits at its host's top-left, so BATTERY CONFIG leaves unused area right/below it.
  P36's "dead space dies" is implemented as the BodyScroll removal; the rect is retained for the
  pinned tests. Reversal: centre/stretch the console and re-anchor the rect rows.
- FITS HERE falls back to the pane's owned-weapon list (`inventory_rows()`) with no cell selected,
  so the mode is never blank and `inventory_rows()` (s21) stays unchanged; with a cell selected it
  is the family+`fit_legal` candidate set (P33). Reversal: always require a selection.
- BUYABLE narrows to the cell only when one is selected (the tab filter alone otherwise), keeping
  `module_row_ids()`'s shipped tab behaviour (s29). Reversal: always require a selection.
- `W<n> — EMPTY` rows are the hull's empty W cells (a separate read-only list), not a rack's
  unfilled slots (which carry no W index); 09 §10's own idiom. Reversal: label the rack's slots.
- The drag writes through the shipped `move_rack_cell`, which commits via `set_battery_groups`
  (player_profile.gd:1548) — the pin's "writes set_battery_groups" is satisfied transitively.
  Reversal: call `set_battery_groups` directly from the pane.
- The em dash is kept in `EMPTY_CELL_FORMAT` (the pin's own `W<n> — EMPTY`, matching the shipped
  refusal strings' `—`). Reversal: use " - ".

## Evidence
- Before: `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=1099 failed=0`.
- After (×2 fresh scratch): same command → `[SUMMARY] passed=1110 failed=0` twice.
- Scoped: `... -- --suite=test_s32_armory_modes` → `[SUMMARY] passed=11 failed=0`.

## Moved test rows (old → new + why)
- `test_d7_armory.gd::test_the_two_wells_mount_at_the_pinned_halves` → renamed
  `test_the_two_console_wells_hold_the_empty_and_summary_blocks` (P34/P36: the wells hold the
  empty/summary blocks; FITS HERE + AMMUNITION moved out).
- `test_d7_armory.gd::test_the_pane_mounts_on_the_painted_console_plate`: the plate's BodyScroll
  ancestor → `ConsoleHost` (P36 removed the fold).
- `test_d7_armory.gd::test_the_items_ride_the_code_drawn_plate`: the ammo 2×3 grid positions → the
  foot band's one horizontal row (P36); the FITS HERE row box → full-width × 76 (P37).
- `test_s18_armory_rework.gd::test_the_chrome_layer_paints_under_every_text_and_control`: the
  console children `%InventoryMargin`/`%AmmoMargin` → `%EmptyMargin`/`%SummaryMargin` (P34/P36).
- `test_p2b1_outfitting_panel.gd::test_the_module_rows_return_as_the_p4_inventory_browser`: the
  caption texts + the scene `MODULES` word → the new `OWNED WEAPONS`/`BUYABLE` captions (P33).
- `test_s29_station_panels.gd::test_n45_the_browser_half_and_the_title_column`: `Split/BrowserHalf`
  (620) → `ModeHost/FitCells/BuyableBlock` full-width (P37); the 160 px title column kept.
- `test_s10_armory_input.gd::setup`: now enters BATTERY CONFIG before driving the racks (P32/P34:
  the racks are that mode's content).
- `test_s29_station_panels.gd::test_the_cluster_is_the_p1_pair_with_the_primary_rightmost`:
  unchanged (the buttons were restored to 360×56 in the foot band).
- Named by the brief but NOT moved (their seams survived): `test_s5_batteries_v2.gd`,
  `test_s20_chrome_unify.gd`, `test_s30_shell.gd`.

## Files touched
- `vajb-orbit/ui/station/armory_panel.gd` — two modes, CELL INFO, FITS HERE/BUYABLE, empty-cell
  rows, shared foot band, mode switch.
- `vajb-orbit/ui/station/armory_panel.tscn` — the two-mode container tree + header switch + foot
  band; BodyScroll/wells inventory/ammo removed.
- `vajb-orbit/tests/test_s32_armory_modes.gd` — new 11-row acceptance suite.
- `vajb-orbit/tests/test_d7_armory.gd`, `test_s18_armory_rework.gd`, `test_p2b1_outfitting_panel.gd`,
  `test_s29_station_panels.gd`, `test_s10_armory_input.gd` — re-anchored rows (above).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| BATTERY CONFIG leaves unused space around the retained 1360×516 console | taste | `armory_panel.gd` `_lay` |
| FITS HERE's no-selection fallback is the owned-weapon list, not P33's strict per-cell list | judgment | `armory_panel.gd` `_fits_here_rows` |
