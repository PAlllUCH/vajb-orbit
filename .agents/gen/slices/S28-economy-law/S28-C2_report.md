---
slice: S28
worker: S28-C2
model: "hyper/deepseek-v4.1-flash @ xhigh"
status: actionable
gate: "1196/0 (C1 + the s23 repair) -> 1202/0"
---

# S28-C2 report

## Result
A6–A8 landed: the battery law (`BATTERY_GAIN` 0.4 declared in the laser, the live
`OreTuning.battery_gain`, one arithmetic line in `extract_cycle`), the bloom cap
(6 rocks x 1.5 yield), the F1 overlay field, the four moved suites restated and
`tests/test_s28_events.gd` added (6 tests, green). Gate x2 on fresh scratch
stores: **1202 passed, 0 failed** twice (1196 + 6 new).

## Acceptance list answers
- **A6 — done.** `game/mining_laser.gd:42` declares `BATTERY_GAIN` 0.4 beside the
  cycle constants; `game/ore_tuning.gd:45` carries the live `battery_gain` with
  the S13 pattern (`reset_to_defaults:125`, `to_dict:160`, `from_dict:192-193`);
  `game/mining_laser.gd:244-245` is the one work line. 1/2/3/7 fitted modules
  deliver 1/1.4/1.8/3.4 work units per cycle, measured live
  (`tests/test_s28_events.gd:88-101`); `battery()` still reports the fitted count
  (`:93`); the floor is one channel and a fit without `w_mining` mounts no laser
  (`:131-152`). The overlay carries the field
  (`ui/dev/dev_tuning_menu.gd:88-95`, `:365-366`, `:407-408`).
- **A7 — done.** `game/poi.gd:92-93` is 6 / 1.5; the roll rounds as `roll_yield`
  does (`:588-590`, `roundi`); the 200 u trigger and `ORE_BLOOM_TIER_BONUS` 1 are
  untouched (`:69`, `:94`), asserted live (`tests/test_s28_events.gd:155-166`).
  `tests/test_s6_poi_loot.gd:421-448` restates the rows.
- **A8 — done.** `tests/test_s28_events.gd` asserts the battery law (the declared
  const, the live default, the four channel counts, the gain sensitivity, the
  floor) and the bloom cap (the constants, the trigger, the bonus, and a triggered
  spawn's count and 1.5x roll band), every figure read off the live surfaces.
- **A11 — done.** Every moved value is tabled below with its reversal and tick; the
  flagged item names its bucket.

## Deviations from SLICE.md
1. **`tools/r1_s13_ac3_replay.gd` still asserts the retired linear N (bucket 2 —
   outside `VAJB_WORKER_FILES`; `tools/` is R1's).** Its `:54` row is
   `absf(per_cycle - bank) <= 0.20 x bank`, so banks 2 and 3 now report FAIL while
   printing exactly the law's channels (1.4 / 1.8). It is not in the gate
   (`tools/` is not scanned), so the gate is clean; remedy in Follow-ups.
   Reversal: 01's L4 gain back to 1.0.
2. **The overlay's `battery_gain` control range is unpinned (bucket 1 — inside
   A6's pin).** Shipped `0.0..1.0`, step `0.05`, matching `work_per_unit`'s shape;
   1.0 is the reversal's own top. Reversal: any other range.
3. **Two test methods renamed to match the law (bucket 1).**
   `test_n_modules_deliver_n_times_the_units_per_cycle` ->
   `..._the_battery_gain_channels_per_cycle` and
   `test_ore_bloom_spawns_ten_rocks_a_tier_up_at_double_yield` ->
   `..._six_rocks_a_tier_up_at_the_capped_yield`. Same method counts (the gate
   arithmetic is unchanged), the names no longer lie.

## Moved values (reversal · tick)
| Value | Was -> now | Reversal | Tick |
|---|---|---|---|
| `mining_laser.gd:42` `BATTERY_GAIN` (new) | - -> 0.4 | - | M12 |
| `ore_tuning.gd:45` `battery_gain` default | - -> 0.4 | gain 1.0 (linear N) | M12 |
| `mining_laser.gd:244-245` cycle work | `work_per_unit x bank` -> `work_per_unit x (1 + gain x (bank - 1))` | gain 1.0 | M12 |
| effective channels 2/3/7 | 2 / 3 / 7 -> 1.4 / 1.8 / 3.4 | gain 1.0 | M12 |
| `poi.gd:92` `ORE_BLOOM_ROCKS` | 10 -> 6 | 10 | M13 |
| `poi.gd:93` `ORE_BLOOM_YIELD_MULT` | 2 -> 1.5 (int -> float; `:588` rounds with `roundi`) | 2 | M13 |
| `dev_tuning_menu.gd:88-95` overlay row | - -> a `battery_gain` slider | delete the row | M12 |
| `ore_tuning.gd:160`/`:192` Save/Load key | - -> `battery_gain` | delete the key | M12 |
| `test_s13_mining_batteries.gd:36-70` rows | N x -> the gain channels (live) | gain 1.0 | M12 |
| `test_s13_caps.gd:63`, `:80`, `:87`, `:92` rows | - -> the const row + the round-trip row | delete the rows | M12 |
| `test_s13_devmenu.gd:100`, `:143`, `:154`, `:415-416` rows | - -> the field row + the Save/Load key | delete the rows | M12 |
| `test_s6_poi_loot.gd:421-448` rows | 10 x 2 -> 6 x 1.5 | 10 x 2 | M13 |

## Evidence
- Gate x2 on fresh scratch stores, byte-identical replays:
  `XDG_DATA_HOME=/tmp/gate_c2_1` and `/tmp/gate_c2_2`,
  `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 3000` ->
  `[SUMMARY] passed=1202 failed=0` twice (logs `/tmp/gate_c2_run1.log`,
  `/tmp/gate_c2_run2.log`). Arithmetic: 1196 + 6 (the new suite) = 1202; the four
  moved suites only renamed methods, so they add none.
- `--suite=test_s28_events` -> `[SUMMARY] passed=6 failed=0`; the four moved suites
  together -> `[SUMMARY] passed=53 failed=0`.
- The flagged tool: `XDG_DATA_HOME=/tmp/c2_probe $GODOT_CONSOLE --headless --path
  "$VAJB_PROJ" --script res://tools/r1_s13_ac3_replay.gd` ->
  `[S13R1] bank=2 ... per_cycle=1.4000 ... FAIL bank2_scaling`,
  `bank=3 ... per_cycle=1.8000 ... FAIL bank3_scaling`, `done failures=2` — the
  printed per-cycle figures are the law's own channels.

## Files touched
- `game/ore_tuning.gd` — the `battery_gain` static var, its default, reset, and the
  to/from-dict pair
- `game/mining_laser.gd` — the `BATTERY_GAIN` const and the one gain-based work line
- `game/poi.gd` — the capped bloom constants and the rounded 1.5x roll
- `ui/dev/dev_tuning_menu.gd` — the `battery_gain` slider, its apply and its read
- `tests/test_s13_mining_batteries.gd` — the channel rows restated under the law
- `tests/test_s13_caps.gd` — the additive const/default row and the round-trip row
- `tests/test_s13_devmenu.gd` — the additive field row, the Save/Load key and the
  test's own reader
- `tests/test_s6_poi_loot.gd` — the bloom rows restated
- `tests/test_s28_events.gd` — new: the battery law and the bloom cap

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-point the two scaling rows to `1 + 0.4 x (N - 1)` (its own print already reads 1.4 / 1.8) | MED, bucket 2 | `tools/r1_s13_ac3_replay.gd:54` |
| Restate the CONTRACTS bloom sentence ("10 rocks, 2x yield") | doc pin (R1's) | `docs/CONTRACTS.md` (brief §10) |
