---
slice: S15
reviewer: S15-R1
verdict: blocked        # 3 HIGH remain (F1-F3)
gate: "852/0 -> 852/0 twice; 852/0 on a seeded pre-S15 store"
---

# S15-R1 review

Diff target is 09 `docs/gameplay/09_ship_slots_modules.md` §12 and `docs/design/STATION_HUB.md`
§5.11's 2026-09-25 amendment (never the brief). Every AC re-measured on the shipped tree by
this reviewer: `tools/r1_s15_ac_replay.gd` (own probe, direct profile), the plate measured
pixel by pixel off the PNG, and the gate run three times on scratch stores. Diff of the moved
test rows against `SLICE.md` §3's list: 4 unlisted rows changed, all disclosed by B1 — F1
(the explicit "Not moved" pair) is a new behaviour, F2 is §3's list being incomplete.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S15-B1/F1 | HIGH | `tests/test_d7_cockpit.gd:348-353` | **The explicit "Not moved" lamp rows changed**, and with them the band's meaning: `select_battery(7)` (now `> GROUPS_MAX`) is swallowed by `hud.gd:1574` before the band sees it, so the last lit lamp **stands** (`lit_rack == 5`) instead of clearing. AC5 says these rows stay green untouched; they do not. `ui/hud/` is outside both B1's and F1's file set, so the cure (forward-or-clear in `select_battery`, or a ratified redefinition of "out of range") is a bucket-2 escalation, not a code pass. | escalate (bucket 2) |
| S15-B1/F2 | HIGH | `tests/test_engine2_weapons.gd:283-286`; `tests/test_s5_batteries_v2.gd:363-371`; `tests/test_s10_armory_input.gd:372-374` | **Three more rows changed off §3's list**: the 6th-group clamp assert, the `WEAPON_ACTIONS` *size* row beside the listed `[6]` row, and the chip's drawn box (`40x44 -> 34x40`). All are forced by the pin (F2's own 1:1) and green, but §3 anchors none of them; reverting re-reds the gate. Remedy is a §3 amendment. | escalate (bucket 2) |
| S15-B1/F3 | HIGH | `autoload/player_profile.gd:1255-1258` | **A fitted weapon can be rackless.** The derived tail is only appended while `groups.size() < GROUPS_MAX`, so a record already holding 5 racks (or the AC3-clamped 7-group save) leaves every surplus fitted cell in **no** battery: my probe reads a 5-rack record with a 7-cell fit covering `[0,1,2,3,4]` of 7, and the play path reproduces it (five batteries over six barrels, then FITTING fills the seventh cell → groups `[[0,1,2,3],[],[4],[],[5]]`, cell 6 covered by nobody). The read's own contract (`player_profile.gd:1211-1213`, pinned by `test_s4_batteries.gd:361-362`) says a fitted weapon is never unfireable, and AC2 says the 7-cell hull composes. Bucket 1: F1's file set can fix it (fold the surplus into a rack with room, or keep appending while any rack has space). | S15-F1 |
| S15-B1/F4 | MED | `ui/station/armory_style.gd:186-196` | **The tail bay is not full-width.** STATION_HUB §5.11's amendment says five bays "flowing 4+1 **with the tail bay full-width**"; `bay_rect` returns `bay_size` for every index, so B5 draws at the normal 97x91 in column 0 of row 2. B1's own follow-up marks it LOW/design, but it is a pin's word. | S15-F1 |
| S15-B1/F5 | LOW | `ui/station/armory_panel.gd:_position_head` | The bay's `B<n>`/`(i)` head and empty-bay cue sit at drawn y 8..56 while the plate's ink starts at row 49 — the head still prints above the plate's own edge (F1's cue half). → `L208` | — |
| S15-B1/F6 | LOW | `tests/test_d7_armory.gd:15-17,406`; `test_p2b1_outfitting_panel.gd:647`; `test_engine2_weapons.gd:254`; `test_s5_batteries_v2.gd:345` | Five kept function names now lie about what they measure (`..._4_3_bay_grid...`, `..._seven_drop_zones...`, `..._weapon_1_7`, `..._is_seven_across...`, `..._without_a_key`). Docs corrected, names not. → `L209` | — |
| S15-B1/F7 | LOW | `ui/hud/hud.gd:61-70,1251` | The three HUD tables and the `_active_slot` clamp stay at seven entries; the tail is unreachable only because `select_battery` refuses ordinals past 5 (`:1574`) and `_select_weapon` refuses too (`game.gd:2028`). Two writers of "5" now exist (`GROUPS_MAX` and the tables' effective bound). → `L210` | — |
| S15-B1/F8 | LOW | `vajb-orbit/tests/test_s15_battery_cap.gd`, `test_s15_armory_layout.gd`, `tools/r1_s15_*.gd` | The wave's new `.gd` files ship with no `.uid` (the L205 class: the headless gate never writes one). → `L211` | wave close-out |

## AC re-measurement (W8 — the reviewer's own numbers)
- **AC1** `weapons.gd` `GROUPS_MAX=5`, `BATTERY_CELLS_MAX=4`, `armory_panel.gd RACK_COUNT=5`
  (`PanelScript.RACK_COUNT == GROUPS_MAX`). The six refusals — 6-rack write, 5-cell write,
  `fit_into_rack` into a full rack, move-append that would grow one, plus the armory pane's
  `can_drop`/`drop` — all answer false and leave `user://` **bytes identical**; positive
  controls (a swap into a full rack, an install into a rack with room) accept.
- **AC2** Empty-record Obliterator composes exactly `[[0,1,2,3],[4,5,6]]`, hull capacity 7,
  every cell once. `test_p2a_launch_fit` (the moved 4+3 ordinal row) and `test_s8_launch_ammo`
  (rack-ordinal-in-barrel-position) pass 12/0 and 8/0. **F3's gap measured here.**
- **AC3** A real v7 file with `[[0]..[6]]` loads as `[[0],[1],[2],[3],[4]]`, order preserved,
  credits 4321 and the 7-cell fit untouched; a second reload is inert; an over-long rack
  `[[0,1,2,3,4],[5],[6]]` clamps to `[[0,1,2,3],[5],[6]]` with the surplus cell re-derived
  (`[...,[4]]`). The seeded store's file is **not rewritten** by the load (mtime unmoved).
- **AC4** Measured off the shipped PNG myself: canvas 194x182, ink bbox cols **7..186**, rows
  **49..132** (180x84); dark-run centres **45.0 / 79.0 / 114.5 / 148.0**, pitch **34.33** (the
  art's ~34.5). The shipped style's drawn slots (`slot_origin` 14,31 -> drawn 28,62; 34x40) sit
  at centres 45 / 79.5 / 114 / 148.5 inside the bar; the ledge (drawn y 104..112) and the three
  drums (drawn y 113..133, **bottom row 132 = the bar's own last row**) are enclosed by the ink.
  The pre-S15 block (40x44 at (10,38), pitch 44) measures outside it — F1 reproduced. Five bays
  4+1, labels `B1..B5` + hints `(1)..(5)`, `bay_row_count(5) == 2`.
- **AC5** `lamp_count == RACK_COUNT == GROUPS_MAX == 5`; rack 1..5 lights lamp 1..5 and marks
  bay 1..5 1:1 (`test_s15_armory_layout` AC5 row). `test_d7_cockpit` 18/0 — but see F1.
- **AC6** Gate `[SUMMARY] passed=852 failed=0` three times: fresh `/tmp/s15r1_gateA`, fresh
  `/tmp/s15r1_gateC`, and `/tmp/s15r1_gateB` seeded with a v7 seven-group store (identical
  count, zero `[FAIL]`). Growth `834 -> 852` = S15's 9 (5 cap + 4 layout) + the parallel S14
  lane's 9 (`test_s14_splits.gd`), attributed, never reverted. `verify --baseline s15_start`
  with the mandated forbidden list: `"problems": []`.

## Unlisted-row diff (against `SLICE.md` §3)
Listed and changed as specified: `test_engine2_weapons.gd:265`, `test_s4_batteries.gd:616`,
`test_s5_batteries_v2.gd:347,371`, `test_p2b1_outfitting_panel.gd:650`, `test_d7_armory.gd`
grid/slot/drum/style rows, `test_p2a_launch_fit.gd:340-373`, both S12 probes. Listed and
**not** changed (rows are symbolic, still green): `test_ui_slot_layout.gd:240,251,726-730,
767-807`, `test_s8_launch_ammo.gd:424`. Unlisted and changed: F1 + F2 (four rows).

## Verified fixes
None (no fixer pass ran).

## Gate
`834/0` (baseline) -> `852/0` -> `852/0`; seeded pre-S15 store `852/0`. Negative control: the
same gate against a scratch store carrying a divergent `user://dev_tuning.cfg` was not needed
(no gate row reads the record), so the store was exercised directly with the seeder above.
