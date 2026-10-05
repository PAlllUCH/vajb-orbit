---
slice: S33
worker: S33-F1
model: "hyper/deepseek-v4.1-flash"
status: informational
gate: "1118/0 → 1121/0"
---

# S33-F1 report

## Result
S33-R1's two HIGH and two MED findings are cured: the browse list now sources bag units UNION
fitted bases (a fitted-only base lists, tagged `FIT`, reading `FITTED`), the pane hint follows the
selection, and the two rows/assertions that died undisclosed are restored. Gate `passed=1121
failed=0` on three fresh-scratch runs (was 1118/0; +3 new rows).

## Fix-list answers
- **F1 — DONE.** `_equip_rows` browse branch iterates the union and keeps a fitted base with no bag
  spare (`armory_panel.gd:4105-4123`); a fitted-only `FIT` row reads `READ_FITTED` instead of a
  price (`armory_panel.gd:339`, `:4387-4396`). Fitted-only → `FIT`/`FITTED`; bag-only →
  `STORED`/`OWNED ×n`; both → `FIT`/`OWNED ×n`; the family-tab filter stands.
- **F2 — DONE.** `_update_hint()` now runs at the end of `_select` (`armory_panel.gd:3275`) and
  `clear_selection` (`:3309`); content swap only, N31-legal.
- **F3 — DONE.** `test_the_mode_switch_shows_exactly_one_mode` restored verbatim from
  `git show HEAD:vajb-orbit/tests/test_s32_armory_modes.gd:127` at `test_s32_armory_modes.gd:132`.
- **F4 — DONE.** The "an empty cell reads EMPTY" assertion restored inside the CELL INFO row
  (`test_s32_armory_modes.gd:224-228`).
- **F6 ride-along — DONE.** Stale comment at `armory_panel.gd:3707` reworded. F5's three
  deviations untouched.

## Added test rows
- `test_a_fitted_only_module_still_lists_in_the_browse_state` (`test_s32_armory_modes.gd:273`) —
  the standard fit's `w_laser` lists with `FIT`/`FITTED` with an empty bag; adding 2 spares flips
  the read to `OWNED ×2`.
- `test_the_hint_line_follows_the_mode_and_the_selection` (`:301`) — idle `PANE_HINT_FIT` → select
  → `PANE_HINT_FIT_CELL` → clear → `PANE_HINT_FIT` → mode swap → `PANE_HINT_BATTERY`.

## Rows touched as a consequence of F1 (old → new → why)
- `test_s29_station_panels.gd` `test_the_browser_caption_and_the_tab_strip_minus_hulls`:
  `LIST_CAPTION_BROWSE % 0` → `% rows.get_child_count()` — a clean vanguard now lists its fitted
  bases, so the count is no longer 0.
- `test_d7_armory.gd` `test_the_two_console_wells_hold_the_empty_and_summary_blocks`:
  `LIST_CAPTION_BROWSE % 0` → `% list_rows.get_child_count()` — same cause.
- `test_d7_armory.gd` `test_the_items_ride_the_code_drawn_plate`: the "one empty-state line" block
  → "lists the ship's fitted equipment", and the cannon row is now found by node name (not
  `child(0)`) because fitted bases precede it. Same cause.
- `test_p2b1_outfitting_panel.gd` `test_the_module_rows_return_as_the_p4_inventory_browser`:
  `LIST_CAPTION_BROWSE % 0` → `% list_rows.get_child_count()` — same cause.
- `test_p2b1_outfitting_panel.gd` `test_the_inventory_lists_the_owned_weapon_ids`: the
  "no weapons owned: one empty-state line" block → a non-empty fitted-equipment assertion. Same
  cause; the row's subject (`inventory_rows()`, bag-only) is unchanged.

## Deviations
None. No pin, number or wording in `docs/` was changed. `LIST_EMPTY_BROWSE` is now reachable only
with no standard fit and an empty bag, so its direct assertion moved out of the p2b1 row (the
constant still ships).

## Evidence
- Gate (before, from `S33-R1_review.md:12`): `[SUMMARY] passed=1118 failed=0`.
- Gate (code-only, before the dependent test rows moved): `[SUMMARY] passed=1116 failed=5` — the
  five rows listed above, plus two `SCRIPT ERROR ... 'text' on a base object of type 'Nil'` from
  the two empty-state blocks reading `child(0) as Label`.
- Gate (final, `XDG_DATA_HOME=$(mktemp -d)`, three fresh-scratch runs):
  `[SUMMARY] passed=1121 failed=0` ×3, zero `SCRIPT ERROR` / `[FAIL]`.

## Files touched
- `vajb-orbit/ui/station/armory_panel.gd` — F1 union source + `READ_FITTED`; F2 hint refresh; F6 comment.
- `vajb-orbit/tests/test_s32_armory_modes.gd` — F3/F4 restored, F1/F2 added, header note.
- `vajb-orbit/tests/test_s29_station_panels.gd` — caption row re-derived (F1 consequence).
- `vajb-orbit/tests/test_d7_armory.gd` — caption + items rows re-derived (F1 consequence).
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — caption + inventory rows re-derived (F1 consequence).
