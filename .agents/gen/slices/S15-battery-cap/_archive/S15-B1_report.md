---
slice: S15
worker: S15-B1
model: "deepseek-flash (crush session)"
status: actionable
gate: "834/0 -> 852/0"
---

# S15-B1 report

## Result
The hardcap is live: `GROUPS_MAX` 5 + `BATTERY_CELLS_MAX` 4 (`game/weapons.gd`), every
composition path refuses a 6th battery / 5th cell writing nothing, an old 7-group save
loads clamped 5x4 in cell order, and the ARMORY draws five bays (4+1, `B1..B5`) whose
slots, ledge and drums sit on `ui_armory_rack_plate`'s own ink (rows 49..132, 34.5 px
drawn pitch). Gate `[SUMMARY] passed=852 failed=0`, twice on fresh scratch stores.

## Pre-grep of section 3's rows (before -> after)
| Row | Before | After |
|---|---|---|
| `test_engine2_weapons.gd:264-267` | `GROUPS_MAX == 7` | `== 5` |
| `test_s4_batteries.gd:615-616` | `RACK_COUNT/GROUPS_MAX == 7` | `== 5` |
| `test_s5_batteries_v2.gd:346-347` | `GROUPS_MAX == 7` | `== 5` |
| `test_s5_batteries_v2.gd:371` | `WEAPON_ACTIONS[6] == weapon_7` | `[4] == weapon_5` |
| `test_p2b1_outfitting_panel.gd:647-670` | `RACK_COUNT == 7` | `== 5` |
| `test_d7_armory.gd:85` | `RACK_COUNT := 7` | `:= 5` |
| `test_d7_armory.gd:392` | symbolic | untouched |
| `test_d7_armory.gd:394-400` | B1/B4/B5/B7 grid | B1/B4/B5, B5 closes 4+1 |
| `test_d7_armory.gd:427-452` | 40x44 @ (10,38) p44 | 34x40 @ (28,62) p34.5 |
| `test_d7_armory.gd:468-523` | caption (10,112) | (133,113); drums 34x20 |
| `test_d7_armory.gd:771-797` | slot 20x22 / salvo 20x36 | 17x20 / 17x10 |
| `test_p2a_launch_fit.gd:340-358` | `index < GROUPS_MAX` | 4+3 ordinals |
| `test_s10_armory_input.gd:454-473`, `test_ui_slot_layout.gd:240,251,726-730,767-807`, `test_s8_launch_ammo.gd:424` | `GROUPS_MAX`-bounded, symbolic | unchanged |
| `probe_s12_field_budget.gd:110-112`, `probe_s12_rock_rate.gd:120-122` | `max == GROUPS_MAX` | `max <= 20` ceiling |
| `test_d7_cockpit.gd` lamp rows | `lit_rack == 0` for rack 7 | **changed - deviation 2** |

## Per-AC measured values
- **AC1** `GROUPS_MAX 5`, `BATTERY_CELLS_MAX 4`, `RACK_COUNT 5`. Refused, each leaving the
  snapshot (record + fit + bag) byte-identical: 6 racks; a 5-cell rack; `fit_into_rack`
  into a 4-cell rack with W5 free and a stocked bag; a move that would grow a 4-cell rack;
  the pane's `can_drop`/`drop` + footer `W SLOTS FULL — SWAP OR REMOVE FIRST`. Controls
  accepted: a 4-cell rack, a swap into a 4-cell rack, an install into a rack with room.
- **AC2** Obliterator (`slot_capacity == 7`) with no record composes
  `[[0,1,2,3],[4,5,6]]` (4+3), every cell claimed once, W-cell count 7 unchanged; the
  launch/HUD read-back moves the same 4+3 (ordinals `[1,1,1,1,2,2,2]`).
- **AC3** 7-group file `[[0]..[6]]` -> stored `[[0],[1],[2],[3],[4]]`, order preserved;
  credits 4321, the 7-cell fit and a second reload untouched; the flush persists the
  clamped record. Over-long rack `[[0,1,2,3,4],[5],[6]]` -> `[[0,1,2,3],[5],[6]]` and the
  surplus cell 4 re-derives into `[[0,1,2,3],[5],[6],[4]]` (never lost).
- **AC4** Ink measured off the shipped texture (194x182): rows 49..132, cols 7..186.
  Slots 34x40 drawn, centres 45/79.5/114/148.5 = the art's (45/79/114/148) within 2 px,
  pitch 34.5; ledge 8..186 @ y 104..112; drums 34x20 @ y 113..133, bottom-most row 132 =
  the bar's last row. The pre-S15 block (40x44 @ (10,38), pitch 44) measures **outside**
  the ink (F1 reproduced). Five bays 4+1, `B1..B5`, hints `(1)..(5)`, `bay_row_count(5)=2`.
- **AC5** `lamp_count 5 == RACK_COUNT 5 == GROUPS_MAX 5`; for rack 1..5
  `select_battery(i)` lights lamp i and `set_selected_rack(i-1)` marks bay i; ordinal 6
  lights nothing new and marks no bay.

## Deviations from SLICE.md
1. **Plate-fit route = ink layout** (not a re-render): `vajb-orbit/assets/` is outside
   `VAJB_WORKER_FILES`, so re-rendering the plate was unavailable; the marks moved onto the
   plate's ink as measured above. The slot is **34** drawn, not the 29 of the first pass:
   with a 29 px slot the `x`'s 28 px `StationButton` theme minimum plus the 1 px separation
   left the barrel name plate **zero width** (the D7/S10 dead drag target); 34 is the
   narrowest slot that keeps a hittable name. Reversal: the pre-S15 metrics quoted in
   `test_s15_armory_layout.gd`.
2. **`test_d7_cockpit.gd:348-353` (the "Not moved" lamp rows) had to change** - bucket 2,
   needs developer/designer ratification. `select_battery(7)` is now refused by
   `hud.gd:1574`'s own `GROUPS_MAX` guard *before* the band sees it, so the last lit lamp
   stands (`lit_rack == 5`) instead of clearing. `ui/hud/` is outside this worker's file
   set; the alternative (forwarding the ordinal to `set_active_rack` even out of range) is
   the owner's call.
3. **Other unlisted rows, forced by the same pins**: `test_engine2_weapons.gd:283` + doc (a
   6th group clamps to the 5th); `test_s5_batteries_v2.gd:365-368` (the `WEAPON_ACTIONS`
   **size** row beside the listed `[6]` row); `test_s10_armory_input.gd:372` (the chip's
   drawn box 40x44 -> 34x40).
4. `game/game.gd`'s `WEAPON_ACTIONS` trimmed to five (the listed `[6]` row only means
   something if index 6 is gone); `weapon_6`/`weapon_7` stay in `project.godot` (untouched)
   and are read by nothing. The HUD's three 7-entry lookup tables stay 7 (hud.gd out of
   scope; the tail is unreachable).
5. A move refuses only when it would **grow** a battery past four: a swap onto an occupied
   position stays legal (`player_profile.gd` `move_rack_cell`, the pane's `_can_move`),
   which is what the S5 move rows measure.
6. Five stale test **function names** (`test_groups_max_is_seven_...`, `..._weapon_1_7`,
   `..._seven_drop_zones...`, `..._4_3_bay_grid...`, `..._last_two_cells...`) are kept:
   renaming them is unlisted churn; their doc comments were corrected.

## Evidence
```bash
XDG_DATA_HOME=/tmp/s15b1_run4 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s15_battery_cap
#   -> passed=5 failed=0   (--suite=test_s15_armory_layout -> passed=4 failed=0)
# gate at session start: passed=834 failed=0; .../s15b1_gate5 + gate6: 852/0 twice
```
+18 rows since 834: **9 are S15-B1's** (5 cap + 4 layout) and **9 are the parallel S14
lane's** `tests/test_s14_splits.gd` (attributed, untouched). The gate's exit leak warning
rises 16 objects/8 resources -> 32/12: `--verbose` shows the extra instances are the
`AudioStreamOggVorbis` playback of `ui_confirm_01.ogg`, the cue a successful drop plays -
no node leak.

## Files touched
- `game/weapons.gd` - `GROUPS_MAX` 5, new `BATTERY_CELLS_MAX` 4, docs
- `autoload/player_profile.gd` - clamp on load/normalise/migration, per-battery guards in
  `set_battery_groups`/`fit_into_rack`/`move_rack_cell`, chunked derived tail
- `game/game.gd` - `WEAPON_ACTIONS` five
- `ui/station/armory_style.gd` - the ink-fitted bay metrics, 4+1 grid docs
- `ui/station/armory_panel.gd` - rack-cap refusals (`_rack_cells_of` + previews), centred
  fitted-cell block, `B1..B5` docs
- `tests/test_s15_battery_cap.gd` (new, 5 rows), `tests/test_s15_armory_layout.gd` (new,
  4 rows), plus the rows in `test_engine2_weapons.gd`, `test_s4_batteries.gd`,
  `test_s5_batteries_v2.gd`, `test_p2b1_outfitting_panel.gd`, `test_d7_armory.gd`,
  `test_d7_cockpit.gd`, `test_s10_armory_input.gd`, `test_p2a_launch_fit.gd`,
  `probe_s12_field_budget.gd`, `probe_s12_rock_rate.gd`

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The cockpit lamp rows' new meaning (deviation 2) needs ratification, or a `hud.gd` one-liner | pin - bucket 2 | `tests/test_d7_cockpit.gd:348-353` |
| The bay's `B<n>`/`(i)` head still prints above the plate's ink edge (F1's cue half) | LOW | `armory_panel.gd:_position_head` |
| The ARMORY's "tail bay full-width" (STATION_HUB 5.11) draws at the normal bay size | LOW/design | `armory_style.gd:bay_rect` |
