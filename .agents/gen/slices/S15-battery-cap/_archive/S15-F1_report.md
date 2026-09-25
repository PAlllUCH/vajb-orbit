---
slice: S15
worker: S15-F1
model: "deepseek-flash (crush session)"
status: informational
gate: "852/0 -> 852/0 (fresh scratch stores)"
---

# S15-F1 report

## Result
All three HIGH and the one MED are closed. **F1**: a refused rack ordinal 6/7 (or 0) now
reaches the band and clears the active lamp (`ui/hud/hud.gd:1575-1582`), and
`tests/test_d7_cockpit.gd:348-353` is restored **byte-identical** to its pre-S15 form
(`git diff` on that file: empty). **F3**: the derived tail folds every fitted cell the
`GROUPS_MAX` cap leaves no new rack for into the first rack with a free cell
(`autoload/player_profile.gd:1256-1268`), so no weapon is rackless. **F4**: the armory's
tail bay B5 draws full-width (`ui/station/armory_style.gd:189-208` + the panel honouring
it). **F2** is a §3 list gap, closed by ratification, no code. Gate
`[SUMMARY] passed=852 failed=0` twice on fresh scratch stores. No LOW item touched.

## Finding-by-finding disposition
| ID | Tier | Disposition |
|---|---|---|
| S15-B1/F1 | HIGH | **Fixed (root).** `select_battery`'s refusal branch now forwards the ordinal to `_cockpit.set_active_rack(battery)` before returning; the band's own contract (`cockpit_cluster.gd:362-368`) clears the lamp for an ordinal outside its five. No pinned value moved. |
| S15-B1/F2 | HIGH | **Closed by ratification, no code.** The three rows sit on brief §3's list retroactively ("Ratified at review 2026-09-25"); reverting them would re-red the gate. Nothing written. |
| S15-B1/F3 | HIGH | **Fixed (root).** Chunk-append the tail as before, then fold the pending cells into the first rack with a free cell (first-fit, cell order preserved, `<= BATTERY_CELLS_MAX`). Both probe gaps (the 5-rack record and the play-path FITTING fill) now cover all seven cells. |
| S15-B1/F4 | MED | **Fixed.** `bay_rect(index, count)` gives the last bay of a partial row the full row width (`bay_row_width()` = `columns*97 + 3*4` logical = 400); the panel sizes the drawn row from its own bay rect, and `_position_head` spans that width, so the row, its recess and its drop zone all follow, not just the `bay_rects()` read-back. |
| S15-B1/F5-F8 | LOW | Untouched (out of this pass's scope, per instruction). |

## Tests adjusted (only where a fix changed what is proven)
- `tests/test_d7_cockpit.gd:348-353` - restored to the original pre-S15 text; the file now
  has **zero** diff against HEAD.
- `tests/test_s15_armory_layout.gd:361-365` - this new S15 row had codified the broken
  behaviour ("the last lit lamp stands"); now asserts `lit_rack == 0` for ordinal 6.
- `tests/test_s15_battery_cap.gd:258-279` (AC3) - the derived read of a clamped 7-group
  save is now `[[0,5,6],[1],[2],[3],[4]]` (was `[[0],[1],[2],[3],[4]]`, i.e. cells 5/6
  rackless); the stored clamp row is unchanged.
- `tests/test_d7_armory.gd:73-79,405-420` - new `TAIL_BAY` const; B5's rect and the drawn
  row size assert the full width.
- `tests/test_s15_armory_layout.gd:287-316` - the grid loop's `want` is the full row width
  for the tail bay.

## Evidence
```bash
XDG_DATA_HOME=/tmp/s15f1_gateA $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200   # -> [SUMMARY] passed=852 failed=0
XDG_DATA_HOME=/tmp/s15f1_gateB $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200   # -> [SUMMARY] passed=852 failed=0
```
Two fresh scratch stores, identical count, zero `[FAIL]`, zero `[SKIP]`. Relevant suites
all green: `test_s15_battery_cap` (5/0), `test_s15_armory_layout` (4/0), `test_d7_armory`,
`test_d7_cockpit` (incl. `test_exactly_the_selected_rack_is_lit`).

F3 on the reviewer's own probe:
```bash
XDG_DATA_HOME=/tmp/s15f1_probe $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  --script res://tools/r1_s15_ac_replay.gd
# ac2_five_rack_invariant - covers [0,1,2,3,4,5,6] of 7  (racks=[[0,5,6],[1],[2],[3],[4]])
# ac2_play_invariant      - covers [0,1,2,3,4,5,6]       (groups=[[0,1,2,3],[6],[4],[],[5]])
# 39 ok / 1 fail (see Follow-ups)
```

## Files touched
- `vajb-orbit/ui/hud/hud.gd` - refusal forwards the ordinal to the band (F1)
- `vajb-orbit/autoload/player_profile.gd` - derived-tail fold so no fitted cell is
  rackless (F3)
- `vajb-orbit/ui/station/armory_style.gd` - `bay_rect(index, count)` + `bay_row_width()`,
  the tail bay full-width (F4)
- `vajb-orbit/ui/station/armory_panel.gd` - `_bay_rects` passes the count, `_lay_bays`
  sizes each drawn row/salvo from its bay rect, `_position_head` spans the bay width (F4)
- `vajb-orbit/tests/test_d7_cockpit.gd` - restored to pre-S15 (F1)
- `vajb-orbit/tests/test_s15_armory_layout.gd`, `test_s15_battery_cap.gd`,
  `test_d7_armory.gd` - the rows above

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| R1 probe row `ac1_record_still_five` reads `[[0,6],[1],[2],[3],[5]]`: it encoded the pre-F3 rackless tail (its own AC2 coverage checks now pass). Reviewer owns re-baselining it. | review | `tools/r1_s15_ac_replay.gd:127-131` |
| Close-out §8's `--forbidden ... ui/hud/ ...` list must drop `ui/hud/`: brief §3 records the developer session's bucket-2 grant of `ui/hud/` to S15-F1 for this root fix. | close-out | `S15_BRIEF.md` §3 / §8 |
| With the tail bay wide (`bay_rect`), its plate fills the wider box and stretches, while the slots/marks keep their fixed art offsets, so B5's marks no longer land on the (stretched) drawn recesses. The pin only asks for the full-width bay; whether the plate should stay master-sized (anchored) or the slots spread is a design call. | LOW/design | `armory_style.gd:slot_rect`, `armory_panel.gd:_lay_bays` |
