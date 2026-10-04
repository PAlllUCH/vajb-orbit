---
slice: S32
worker: S32-F1
model: hyper/deepseek-v4.1-flash
status: fixer
gate: "1110/0 (was 1110/0; no count moved)"
---

# S32-F1 report — the F1 HIGH cure + F2/F3/F4

## Cured items

- **S32-B1/F1 (HIGH) — cured.** The BATTERY CONFIG console **stretches to the mode host**
  and the five racks are **full-width rows** stacked top-down (the designer ruling, P36
  amendment, escalation bucket 2). `armory_panel.tscn:90,234,239,256,263,270` (ModeHost /
  ConsoleHost / Console are containers; `BodyBox` = `RackRows` + `WellsRow`);
  `armory_panel.gd:1193` `_lay` pins the console to `%ModeHost` and flushes its body;
  `armory_panel.gd:2121` `_build_rack` gives each row `EXPAND_FILL` + `rack_row_height`;
  `armory_style.gd:216,229,248,260,274,300` re-derive the band/rows/cells/ledge/wells.
  Effect: T-122's dead space is gone — the console is the mode host's own box (1392x447 at
  the pinned host, 1920x917 at the suite's window) instead of the pinned 1360x516 at the
  host's top-left. Reversal (the ruling's): R1's option (a) — centre the 1360x516 console
  and restore the old rect rows.
- **S32-B1/F2 (LOW) — cured.** `armory_panel.gd:984` `set_mode` no longer calls `_lay()`:
  the switch is `_apply_mode()` (pure visibility) + the UI cue only; the newly-visible
  console re-sorts through the container tree and `RackRows.sort_children` → `_lay_bays`.
- **S32-B1/F3 (LOW) — cured by revert.** `armory_panel.tscn:354` `MeterLabel` is back to
  `StationValue` (the shipped variation the builder had silently changed to
  `StationCaption`); no test pins it, gate green.
- **S32-B1/F4 (LOW) — cured.** `test_s32_armory_modes.gd` containment row now measures the
  row's own **scroll viewport** (`_assert_rows_scroll_contained`) instead of raw window
  rects: each row fits its viewport's width and rides the `ScrollContainer`, so the
  vertical overflow scrolls and stays reachable (the reviewer's own finding).

## Re-anchored test rows (old -> new + why)

Geometry moved to the P36 model: console 1360x516 -> the mode host (1392x447 at the pinned
host); rack band 1328x192 -> 1392x349; bay 260x192 five-across -> rack row 1392x65 stacked
on a 6 px gap; cell 117x52 (2x2 at (10,34)) -> 221x45 (4-across at (210,10)); ledge
(10,150)+240x34 -> (1122,0)+270x65; wells 648x220 -> 680x92.

- `test_d7_armory.gd::test_the_pane_mounts_on_the_painted_console_plate`: `block_size` and
  `plate.size` CONSOLE -> MODE_HOST (the console is the host now).
- `test_d7_armory.gd::test_the_two_console_wells_hold_the_empty_and_summary_blocks`: wells
  WELL_LEFT/RIGHT (console-space) -> the new pane-space halves; `empty.position`
  `WELL_LEFT.pos - CONSOLE_ORIGIN` -> `Vector2.ZERO`; `racks.position` (16,38) -> (0,0);
  `racks.size` (1328,192) -> (1392,349).
- `test_d7_armory.gd::test_the_bays_draw_five_across_the_band` (name kept): five-across ->
  five stacked full-width rows; `row.size` BAY -> RACK_ROW; `rows.custom_minimum_size`
  (1328,192) -> (0,0).
- `test_d7_armory.gd::test_the_cells_are_the_2x2_rack_on_the_bay` -> renamed
  `test_the_cells_are_the_four_across_the_rack_row`: `cell_columns` 2 -> 4, `cell_rows`
  2 -> 1; the four cell rects (117x52 at (10,34) diagonal) -> (221x45) one gap right each.
- `test_d7_armory.gd::test_the_salvo_strip_renders_the_cycle_figure`: strip (10,150)+
  240x34 -> (1122,0)+270x65; caption (78,11) -> (78,26.5); drum y 1.0 -> 16.5.
- `test_d7_armory.gd::test_a_user_tres_restyles_and_relayouts_with_no_code_edit`:
  `band_height`/`bay_gap` -> `rack_gap`/`rack_row_height`; the band/cell derivation and the
  shipped restore re-anchored to the row model.
- `test_d7_armory.gd::test_the_style_extends_cockpit_style_with_the_pinned_metrics`:
  `cell_columns` 2 -> 4.
- `test_s15_armory_layout.gd::test_the_console_and_the_bays_are_the_derived_geometry`:
  `block_size`/`plate.size` CONSOLE -> MODE_HOST; bays five-across -> stacked rows;
  cells/ledge/drums re-anchored as above.
- `test_s15_armory_layout.gd::test_the_pane_draws_five_bays_across_one_band`: five-across ->
  five full-width rows (each spans the console, one row-gap apart); band -> (1392,349).
- `test_s18_armory_rework.gd::test_every_rect_derives_from_the_host_at_the_three_proofs`:
  the old law ("the geometry never moves with the host") -> the new one ("the console and
  every row span the host's width; the wells band sits at its foot"), because P36 makes the
  console the host's own box.
- `test_s18_armory_rework.gd::test_the_chrome_layer_paints_under_every_text_and_control`:
  chrome `< RackRows index` -> chrome `< BodyBox index` (the rows now live inside the
  console's body box).
- `test_s10_armory_input.gd::test_a_real_named_plate_drag_commits_the_swap`: chip
  (117x52) -> (221x45).
- `test_s10_armory_input.gd::test_a_bay_click_and_the_keys_move_the_selection`:
  `_bay_centre` = the row centre -> the row's head-block corner (a full-width row's centre
  now falls on a cell); message reworded.
- `test_s32_armory_modes.gd::test_every_row_control_lands_inside_the_window`: raw window
  rects -> the row's scroll viewport (F4).

## Left uncured (why)

- **S32-B1/F5, S32-B1/F6 (LOW)** — the FITS HERE/BUYABLE no-selection fallbacks and the new
  `_summary_hint` coordinate code inside the retained console idiom. Out of scope per the
  brief ("leave the remaining LOW findings to the backlog"); both carry reversal paths in
  the S32-B1 report.

## Notes

- `_lay` shows the hidden BATTERY CONFIG mode for one pass and restores it
  (`armory_panel.gd:1206-1218`): Godot does not sort a hidden container, so this is what
  keeps `block_size()`/`bay_rects()`/`well_rects()` correct in the landing mode (the draw
  happens after the frame). Reversal: read the console geometry only while its mode shows.
- All profile writes still ride the public doors; no new profile shape.

## Gate

- `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` (fresh scratch, x2)
- RUN 1: `[SUMMARY] passed=1110 failed=0`
- RUN 2: `[SUMMARY] passed=1110 failed=0`

## Files touched

- `vajb-orbit/ui/station/armory_panel.gd`, `armory_panel.tscn`, `armory_style.gd`
- `vajb-orbit/tests/test_d7_armory.gd`, `test_s15_armory_layout.gd`,
  `test_s18_armory_rework.gd`, `test_s10_armory_input.gd`, `test_s32_armory_modes.gd`
