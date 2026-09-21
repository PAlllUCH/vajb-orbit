# G1 — flight feel: cursor steering, A/D strafe, the turn retune

Worker: **G1** (coder — flight feel), brief `.agents/gen/flight_beam_wave_task.md`.
Owner rulings executed: 1 (nose follows the cursor while `thrust_forward` is held),
2 (A/D strafe), 3 (`turn_rate` x 0.50), the `REBINDABLE_ACTIONS` half of the Controls tab.
Evidence directory: `.agents/gen/_g1/` (all timestamps 17:19–17:27, one session).

## 1. What changed, file by file

| File | Change |
|---|---|
| `vajb-orbit/game/ship_fit.gd` | the nine `HANDLING` `turn_rate` rows x 0.50, with the ruling and the reversal path documented above the table |
| `vajb-orbit/game/player_ship.gd` | cursor steering while `thrust_forward` is held (`_manual_desired_turn` → `_aim_turn` → `_turn_toward`), A/D strafe (`_manual_strafe`, `_command_velocity`, `_strafe_axis`, `_step_strafe`), `_step_speed`'s axis thrust factored into `_thrust_axis` so both axes share one law, the aim-point seam (`set_aim_point` / `clear_aim_point`) |
| `vajb-orbit/autoload/settings_manager.gd` | `strafe_left` / `strafe_right` appended to `REBINDABLE_ACTIONS` (17 → 19 entries) |
| `vajb-orbit/tests/test_flight_feel_g1.gd` | **new**, 12 tests (the suite pinned below) |
| `vajb-orbit/tests/probe_g1_flight_feel.gd` + `.tscn` | **new**, the timed measurement probe |
| `vajb-orbit/tests/probe_g1_lint.gd` + `.tscn` | **new**, the `--debug` warning ledger for the three files above |
| `vajb-orbit/tests/test_combat_repair_c5.gd` | **one line**: C5's `turn_rate is still 3.0` pin is asserted at its retuned 1.5, with the ruling that moved it named inline (see §6) |

Untouched, deliberately: `project.godot` (both strafe actions were already there and bound —
measured below), `assets/**`, theme, `addons/**`, `docs/**`, and every file outside the
worker set. No file was added to `STRAFE_LEFT`/`STRAFE_RIGHT`'s reader that could shadow the
existing turn actions: `turn_left` / `turn_right` keep their reader and their
`REBINDABLE_ACTIONS` slots.

## 2. Ruling 3 — the turn curve, before and after

The owner's ruling is "all nine `ship_fit.gd` `turn_rate` rows x 0.50". The probe re-derives
the table against the section 13 column quoted as a const (the owner-locked table, so the
assertion is about the ruling and not a copy of the shipped number):

| Class | `turn_rate` before (rad/s) | after (rad/s) | after (°/s) | ratio | `turn_spinup` | derived `t_90` at rate |
|---|---:|---:|---:|---:|---:|---:|
| Fighter | 3.4 | 1.7 | 97.4 | 0.5000 | 0.4 | 0.924 s |
| Vanguard (shipped) | 3.0 | 1.5 | 85.9 | 0.5000 | 0.5 | 1.047 s |
| Miner | 2.0 | 1.0 | 57.3 | 0.5000 | 1.0 | 1.571 s |
| Trader | 2.4 | 1.2 | 68.8 | 0.5000 | 0.7 | 1.309 s |
| Corvette | 3.2 | 1.6 | 91.7 | 0.5000 | 0.45 | 0.982 s |
| Hauler | 1.5 | 0.75 | 43.0 | 0.5000 | 1.4 | 2.094 s |
| Gunship | 1.9 | 0.95 | 54.4 | 0.5000 | 1.0 | 1.653 s |
| Frigate | 2.1 | 1.05 | 60.2 | 0.5000 | 0.9 | 1.496 s |
| Destroyer | 1.6 | 0.8 | 45.8 | 0.5000 | 1.2 | 1.963 s |

`[G1] turn_curve classes=9 mismatched=0 retune=x0.50`. **Vanguard 3.0 → 1.5 rad/s
(172°/s → 86°/s), exactly as the brief's example.** No other column of any row moved: the
suite asserts all six columns of all nine rows against the wave-start table, plus the key
set, plus that the snapshot carries `turn_rate` unscaled (`turn_rate` is a rate and takes no
plating multiplier) while `turn_spinup` keeps its `h1_plate_light` x 1.05.

Two consequences to record, both intended:
- The retuned rows reach the **nine NPC hulls** too (they fly `ShipStats`), so NPCs also turn
  at half rate — the same, already-accepted shape as the retuned `coast_time`.
- §13's table itself is **not** touched (owner-locked). The owner's tick is still pending;
  this report is the before/after table §13's amend needs.

## 3. Ruling 1 — the nose follows the cursor, the heading holds

Mechanism: the autopilot's `_order_turn` was factored into `_turn_toward(point)`
(bearing error, clamped to one radian of full deflection, x the class `turn_rate`), so a
fly-to order and the cursor share **one** bearing law. `_aim_turn()` adds only a deadzone
the size of the hull's own art-derived radius (`_hull_radius`, 60.0 u on the shipped hull),
because the camera centres the hull and the pointer rests on it at launch — inside that
radius there is no bearing to chase. `_manual_desired_turn(stick, turn)` is the gate: a
deflected turn action answers first, then the cursor while the raw throttle is positive,
else exactly `0.0`.

Every number arrives from the class: `_step_turn` is untouched, so the nose spins up at
`turn_rate / turn_spinup` and saturates at `turn_rate`. Measured on the shipped hull and the
two ends of the column (probe, `--fixed-fps 60`, 90° aim re-placed on the hull each frame so
the bearing is constant while the hull flies):

| Case | start error | price bound `(error−tol)/rate` | measured `t_reach` | peak ω | ω / rate |
|---|---:|---:|---:|---:|---:|
| Vanguard | 1.5708 rad | 1.034 s | 3.217 s | 1.500 | **1.000** |
| Fighter | 1.5708 rad | 0.912 s | 2.817 s | 1.700 | **1.000** |
| Hauler | 1.5708 rad | 2.068 s | 6.683 s | 0.750 | **1.000** |

`t_reach` is the first frame inside 0.02 rad (1.15°); it is far above the price bound because
the arrival law is proportional below one radian of error, so the last degrees are
asymptotic — the class rate is a ceiling, never an arrival time. **The peak turn rate equals
the class rate to three decimals in all three cases**, which is the ruling's own claim.

Heading hold (throttle released mid-turn, cursor still 90° off the bow):

| Case | ω at release | time to ω ≤ 0.01 | class `turn_spinup` | heading after that | nose stopped short of the bearing |
|---|---:|---:|---:|---|---:|
| Vanguard | 0.414 rad/s | 0.150 s | 0.525 s | **held, drift 0.0000000** | 0.2417 rad (13.8°) |
| Hauler | 0.750 rad/s | 1.467 s | 1.470 s | **held, drift 0.0000000** | 0.4458 rad (25.5°) |

and the control — no input at all, cursor 90° off the bow, 4 s:
`heading_drift=0.00000000 speed=0.00000000 held=true`.

So: **released, nothing commands a turn**, the nose spins down over its class spin-up (the
§3.2 angular inertia, unchanged) and then stops dead on its own bearing, short of the
cursor. Holding W brings the nose onto the cursor over the class's own turn curve.

## 4. Ruling 2 — A/D strafe, and its derivation

**The derivation, in full: the strafe invents no number.** The stick is one 2-D vector in the
hull's frame (x = nose, y = right side); it is capped at unit magnitude and scaled by the
class's own `max_speed` (§13's own row), and each axis then chases its component through the
**same** chase law the nose already uses, at the class's own acceleration
`max_speed / accel_time`. Both numbers are §13 rows the class already flies by:

```
commanded lateral speed  = strafe * max_speed          # the class's own ceiling
lateral acceleration     = max_speed / accel_time      # the class's own accel rate
```

With `v = a·t` until the target, the hull reaches 90 % of its lateral ceiling in
**0.9 x `accel_time`** — a derived, checkable prediction, and the probe measures it:

| Class | lateral ceiling = `max_speed` | accel = `max_speed/accel_time` | derived `t_90` (0.9 x accel_time) | measured `t_90` | forward speed peak | forward displacement | heading drift | sideways travel |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Vanguard | 406.600 u/s | 161.349 u/s² | 2.268 s | **2.283 s** | 0.000 | −0.000 u | 0.0000000 | 417.5 u |
| Fighter | 427.500 u/s | 203.571 u/s² | 1.890 s | **1.900 s** | 0.000 | −0.000 u | 0.0000000 | 364.2 u |
| Hauler | 278.350 u/s | 44.183 u/s² | 5.670 s | **5.683 s** | 0.000 | −0.000 u | 0.0000000 | 711.5 u |

(Ceilings are the resolved `max_speed`: the shipped fit's `h_plate_light` costs 5 %.)

- **Strafe moves the hull laterally and not forward**: forward speed peak and forward
  displacement are both 0.000 in all three classes, the travel is 100 % along the right
  vector, and the heading does not move by a radian's worth of noise (no steering without
  `thrust_forward`, which is ruling 1's other half).
- **W+D** (cursor straight ahead so the nose holds): `speed_peak = 406.600` = the class
  ceiling exactly, against `575.019` (sqrt(2) x ceiling) for the unclamped case, track
  **45.03°**, heading drift 0.000771 rad — the owner's "WA/WD strafe and rotate", with the
  nose on the cursor and the track 45° off it, and section 3.4's `|v| / v_max` onset never
  leaving 1.0.
- Release: `_step_strafe` returns when no strafe is commanded, so the axis goes back to the
  body's own damp and the sideways velocity settles over the class's coast time, exactly as
  a hit's push does (CONTRACTS §4's "the damp still owns the lateral velocity" holds).
- Emergency Flight Mode (ruling 14): the strafe is thrust, so it is locked with the
  throttle; the *turn* is not, so the cursor steering stays live for a dry tank.

### The one named value I am *proposing* (not added)

I added **no** constant: the strafe's strength is `max_speed` and `accel_time` only. Its
visible consequence is that a full-deflection strafe reaches the same speed as a full
throttle (both are `max_speed`), which is the literal reading of "derived from the class's
own rows". If the owner wants a weaker sideways thrust, the one named value to add is:

```gdscript
## ENGINE_SPEC section 3.2 amendment, owner tick: how much of the class ceiling the
## sideways thrusters command. 1.0 today (the strafe is the drive turned 90 degrees).
const STRAFE_FRACTION := 0.5
```

applied as `Vector2(throttle, lateral * STRAFE_FRACTION)` in `_command_velocity`.
**Reversal path: delete the constant and the multiply** — no other call site reads it, and
the suite's `_command_velocity(0, 1) == (0, max_speed)` pin is the one assertion that would
move with it (it is written against `max_speed`, so it would need the fraction applied).

The only other judgement call is the aim deadzone, and it takes **no** new number: it is
`_hull_radius()`, the art-derived half-length the hull's collision circle already carries
(60.0 u shipped), used because a bearing to a point inside one's own hull is meaningless.

## 5. Tests and gate

**Gate (universal, `tests/headless_runner.tscn`, `--quit-after 1200`):**

| Run | Result | Log |
|---|---|---|
| wave-start baseline, before any G1 edit | `[SUMMARY] passed=277 failed=0`, exit 0 | `.agents/gen/_g1/gate_before.log` |
| after the G1 change | `[SUMMARY] passed=289 failed=0`, exit 0 | `.agents/gen/_g1/gate_after.log` |
| the twelve new tests alone | `passed=12 failed=0`, exit 0 | `.agents/gen/_g1/gate_g1.log` |
| C5's suite (the one test file the ruling touches) | `passed=7 failed=0` | `.agents/gen/_g1/gate_scoped.log` |

**277 → 289, +12, nothing shrunk, no test weakened.** The suite
`tests/test_flight_feel_g1.gd` carries one test per command (12):

1. `test_the_turn_column_is_the_retuned_half_of_the_wave_start_rows`
2. `test_no_other_handling_number_moved`
3. `test_the_retuned_turn_rate_reaches_the_hull_through_the_snapshot`
4. `test_the_bearing_law_is_proportional_then_saturated_at_the_class_rate`
5. `test_the_fly_to_order_still_uses_the_same_bearing_law`
6. `test_the_aim_deadzone_is_the_hull_radius_and_no_new_number`
7. `test_the_manual_turn_is_the_cursor_only_while_thrust_is_held`
8. `test_the_shipped_map_strafes_on_a_and_d_and_keeps_the_turn_actions`
9. `test_the_command_is_lateral_and_ceiling_clamped_with_no_invented_fraction`
10. `test_the_strafe_reader_needs_no_launch_snapshot`
11. `test_the_two_strafe_actions_are_rebindable_and_the_old_set_survives`
12. `test_the_strafe_binding_round_trips_through_the_settings_manager`

The suite is synchronous (no frame is awaited — the C3 split): it pins the *construction*
(the retuned column, the bearing law, the gate, the strafe's derivation, the Controls tab)
while `tests/probe_g1_flight_feel.tscn` measures the *motion*. The four behaviours the brief
names are each covered on both sides: cursor bearing (suite 4/5/6 + probe `cursor_*`),
heading hold (suite 7 + probe `hold_*`/`hold_at_rest`), strafe lateral-not-forward
(suite 9/10 + probe `strafe_*`), no other handling number moved (suite 1/2/3).

**Probe** — `godot --headless --path vajb-orbit res://tests/probe_g1_flight_feel.tscn
--fixed-fps 60 --quit-after 20000` → `[G1] done failures=0`, exit 0
(`.agents/gen/_g1/probe_after.log`). Re-run for determinism: every `[G1]` line byte-identical
except the `wall_ms` stamp on the closing `clock` line (`physics_frames=1981`,
`iterations=1980` identical), the same output shape C3's probe has.

**Warning ledger** — `godot --headless --debug --path vajb-orbit
res://tests/probe_g1_lint.tscn --quit-after 600` (`.agents/gen/_g1/lint_g1_after.log`):
`player_ship.gd`, `ship_fit.gd` and `settings_manager.gd` each load with **zero warning
lines**. The harness is proven live in the same run by the positive control
(`ui/hud/minimap.gd` emits its `world_radius` shadowing warning); `autoload/world_clock.gd`
is clean as the negative control. (G2's sweep has since cleared `weapons.gd`, so minimap is
the control that still fires.)

## 6. Deviations, judgements and open items

1. **One C5 assertion updated** (`tests/test_combat_repair_c5.gd:288`): it pinned
   `turn_rate` at 3.0 as part of "the coast retune moved nothing else". Ruling 3 makes that
   false; the line now asserts 1.5 and names the ruling that moved it, so the file still
   proves the coast retune's blast radius. Nothing was deleted to hide a failure — the
   turn column is asserted in full, per class, by the new suite.
2. **No `project.godot` edit was needed**: measured, `strafe_left` A (65) and `strafe_right`
   D (68) are in the map and loaded, `turn_left` / `turn_right` are present with no events.
   The suite asserts the actions exist; it does not assert the keycodes, so the owner's own
   re-binds (which land in `user://inputs.cfg`) cannot red it.
3. **`turn_left` / `turn_right` keep working** and keep priority over the cursor when a pad
   or a Controls-tab re-bind deflects them; the brief asked for every existing action's
   behaviour to survive, and the suite exercises all six flight actions.
4. **Pre-existing, not G1's**: `tests/test_weapon_fx_f4.gd:176` logs `SCRIPT ERROR: Cannot
   call method 'call' on a previously freed instance` in the *pre-wave* baseline log as well
   as after (the test still passes). Flagged for G4/LOW, not touched.
5. **Parallel-lane note for the close-out gate**: G2 was mid-edit in this same worktree while
   I ran. `gate_after.log` (17:26, `passed=289 failed=0`) is my green run; a later re-run at
   17:27 shows G2's in-flight laser-pool change carrying count 294 and one red in **G2's own**
   `test_weapon_fx_f1.gd` (`take 0 in order`). No G1 file is implicated — the twelve G1 tests
   pass in that run too. The wave gate is the orchestrator's to re-run when the lanes settle.
6. **Not touched and not mine to touch**: `ui/screens/settings.gd` needs no change for the
   Controls tab — it labels an action as `STRAFE LEFT` / `STRAFE RIGHT` from the action name
   and shows `UNBOUND` where there is no key, so the two new rows render from the
   `REBINDABLE_ACTIONS` change alone.
7. The `wall_ms` stamp on the probe's closing line makes a byte-for-byte `diff` of two probe
   runs differ on one line; every measurement is identical. C3's probe has the same shape.

## 7. Reversal paths (one line each)

- **Turn back to the old rate**: multiply the nine `ship_fit.gd` `HANDLING` `turn_rate` rows
  by 2.0 and re-run `tests/probe_g1_flight_feel.tscn`; re-quote
  `WAVE_START_HANDLING`'s `turn_rate` in the suite (it is the pre-retune column) and
  `test_combat_repair_c5.gd:288`'s 1.5 → 3.0.
- **Drop the cursor steering**: `_manual_desired_turn` returns `turn * _stats.turn_rate`
  instead of `_aim_turn()` (one branch); the autopilot is untouched either way.
- **Drop the strafe**: delete `_step_strafe`'s call and the two `REBINDABLE_ACTIONS` entries;
  the two input-map actions can stay bound and inert.
- **Weaken the strafe**: add `STRAFE_FRACTION` as described in §4.
