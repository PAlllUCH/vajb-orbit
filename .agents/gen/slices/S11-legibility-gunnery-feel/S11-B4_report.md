---
worker: S11-B4
slice: S11
role: coder
tree: 4c19812 + the wave's uncommitted builder edits (B1's station/UI set, B3's weapons.gd, this set)
gate: "`[SUMMARY] passed=788 failed=3` — twice, fresh `XDG_DATA_HOME=$(mktemp -d)` scratch each (both runs byte-identical on the fail list)"
live_store: "profile.cfg md5 eb750728e6dbd9cbe944e32c96307c87 before and after both gate runs (unmoved)"
---

# S11-B4 — one-vector inertia (T1/T2), the 5 deg acceptance, and three out-of-set rows

## What shipped

| # | deliverable | where |
|---|---|---|
| 1 | `_lateral_damp()` returns `_linear_damp()` — one rate on both axes | `game/player_ship.gd:1130` |
| 2 | `_lateral_extra_damp()` derives to exactly 0.0 and `_step_lateral_drag` is inert; both kept in place for the reversal | `game/player_ship.gd:1139`, `:915` |
| 3 | `COAST_TIME_MULT` 2.0 -> 2.5 (T1); `LATERAL_DAMP_MULT` retired in place (still 1.0, unread, doc says so) | `game/ship_fit.gd:526-527`, read at `:628` |
| 4 | `ANGULAR_DAMP_MULT := 0.5` (T2), read as that multiplier over `turn_spinup` | `game/ship_fit.gd:528`, `game/player_ship.gd:1150` |
| 5 | the release chase: nothing commanded -> the whole velocity chases zero along its own line | `game/player_ship.gd:873` + gate `:857` + call site `:649` |
| 6 | the acceptance suite (3 methods) and T3 implemented nowhere | `tests/test_s11_flight_stop.gd`; `game/ship_fit.gd:518-522` |

## Measured: the acceptance (CONTRACTS §23.5, `SLICE.md` AC6)

Gate-log rows from `test_s11_flight_stop.gd` (present in both gate runs):

| hull | v_release | bearing drift | force cross share | ticks | t_tenth | derived `0.9 x coast x v/vmax` |
|---|---|---|---|---|---|---|
| vanguard | 406.616 | 0.000000 deg | 0.000000000 | 143 | 2.3833 s | 2.3626 s |
| fighter | 426.987 | 0.000000 deg | 0.000000000 | 114 | 1.9000 s | 1.8877 s |
| freighter | 277.972 | 0.000000 deg | 0.000000000 | 369 | 6.1500 s | 6.1342 s |

Bound 5.0 deg at `tests/test_s11_flight_stop.gd:48`, window ends at 0.1x release (`:50`), drift
sampled every tick and asserted, not only at the window's end. The drift and the cross share are
exactly zero because the release force is `axis * force` with the velocity's own unit vector:
nothing can act across the line of travel.

Real frames, the existing probe (`probe_s2_6_flight.tscn`, bounded `--quit-after 30000`, scratch
store, `[S26F] done failures=0`, `wall_ms=12424`): the axial and the lateral releases now read
**identical** on all nine hulls — vanguard axial `t_10 1.150 dist_10 126.41` = lateral
(`damp_forward = damp_lateral = 0.380952`), fighter `0.883` both, freighter `4.400` both — and the
coast from cruise is T1's own envelope (vanguard `t_10 2.367` against the derived `2.363`).
`[S26F] mirror ... mirrored=true`, sweep error and distance error `0.000000`.

The wave's own hazard (S11-R1's brief): the commanded strafe is untouched — `[S11FS] strafe`
reads 367.717 u/s (vanguard) and 386.101 u/s (fighter) of sideways speed after 90 % of
`accel_time`, i.e. the class-rate chase survives the one damp (`test_s11_flight_stop.gd:223`).

## Every numeric row moved

| file:line | was | now |
|---|---|---|
| `tests/test_s2_6_flight.gd:118` | `COAST_TIME_MULT == 2.0` | `2.5`; `LATERAL_DAMP_MULT == 1.0` kept as the retired constant; new `ANGULAR_DAMP_MULT == 0.5` at `:129` |
| `tests/test_s2_6_flight.gd:214` (was `test_the_forward_carry_reverts_and_the_sideways_decay_does_not`) | forward `1/coast_time`, sideways twice that, `extra > 0` | one rate: `sideways == forward`, `is_zero_approx(extra)`, body damp `== forward` at `DAMP_MODE_REPLACE`, plus the T2 angular pair |
| `tests/test_s2_6_flight.gd:466` section 2 | released skid dragged at `-mass x extra x v` | released velocity chases zero on its own line at the class coast rate, net of the one damp, with no cross component and `extra` 0 |
| `tests/test_engine_c3_flight_decay.gd:101` | `angular_damp == 1/turn_spinup` | `ANGULAR_DAMP_MULT/turn_spinup` (and the header row at `:11`) |
| `tests/test_engine_c3_flight_decay.gd:57-62` | prose "x 2.0, section 13's column" | the 2.5 tick, cited to §23.5 |
| `tests/test_flight_feel_g1.gd` | — | **no numeric row pinned a moved constant**: its `WAVE_START_HANDLING` rows are the raw (unmultiplied) table and its `_accel_rate` row is derived. `--suite=test_flight_feel_g1` green in both gate runs; the file is byte-unchanged |

## The route (escalation bucket 1 — code route inside a pinned acceptance)

The pin's named edit (one damp) is necessary but **not sufficient** for §23.5's acceptance. The
released nose still rode the *commanded* coast ramp (`_step_speed(0, _coast_rate())`,
`game/player_ship.gd:656`) while the side rode the damp, so a combined release still swung: the
nose reaches zero at `0.707 x coast_time` while the side's tail runs on, which places the bearing
45 deg off at the 0.1x point (arithmetic from the two terms; the model is anchored on the probe's
own `0.9 x coast_time` axial ramp). §14's 23.5 amendment states the behaviour the acceptance
measures — *"a released forward+strafe decays as a single velocity vector"* — so the release now
runs the same `_thrust_axis` chase on the velocity's own direction, gated by `_is_released` to a
full release (no throttle, no strafe, no order) so that no commanded axis, no autopilot order and
no commanded strafe is touched. Pure axial numbers are mathematically unchanged, because there the
axis *is* the velocity. **Reversal: delete `_step_release`, the branch at `:649` and `_is_released`;
the pre-23.5 `_lateral_damp` body plus the kept `_step_lateral_drag` then own the sideways axis
again.** Cost, for R1 to weigh against the pin's literal wording: a released *sideways* velocity
now stops on the class coast ramp (200 u/s release: vanguard `t_10 1.150 s`) instead of riding the
damp tail. The axial envelope, T1's number and the commanded-strafe chase are untouched.

## Findings

- **Bucket 2 — the tests-that-move list omits `tests/test_s7_affixes.gd` and this worker's set
  excludes it.** Ticking T1 turns three of its rows red (2 tests): `:71` `"coast_time": 2.1` (wants
  `2.625`, i.e. `1.0 x COAST_TIME_MULT x 1.05` — the gate log prints the resolved 2.625), `:365`
  `1.0 * 2.0` and `:375` `1.0 * 2.0 * 1.01` (both want `x ShipFitScript.COAST_TIME_MULT`). This is
  the only part of the 3-failure gate that this worker's change owns; a continuation or fixer with
  that file in its set closes it. No bound weakens — the rows move to the ticked constant.
- **Bucket 2 — the probes.** §23.5's tests-that-move list assigns `probe_s2_6_flight`,
  `probe_g1_flight_feel` and `probe_c3_flight_decay` to B4, but B4's `VAJB_WORKER_FILES` does not
  carry them, so their re-derivation is reported, not done. States measured today (bounded runs,
  scratch stores): `probe_s2_6_flight` itself green (`failures=0`) but its printed split rows moved
  (lateral == axial everywhere; the lateral `t_10` 2.383 -> 1.150 s at v0 200) and its prose still
  describes the retired lateral drag (`probe_s2_6_flight.gd:295-353`, the `LATERAL_DAMP_MULT` key
  list at `:45`); `probe_g1_flight_feel` green (`failures=0`, `turn_curve mismatched=0`) but its
  spin-down rows move with T2 (`probe_g1_flight_feel.gd:290-360`); `probe_c3_flight_decay` reports
  `cases=4 failures=4` — **not this worker's**: all four die in the *accelerate* leg ("never reached
  406.600 u/s; top speed 83.312"), a commanded ramp no file of this wave touches (no economy/reactor
  file appears in the wave's diff), so it reads as stale before the wave; flagged for R1.
- **Not mine, already reported by S11-B3**: `[FAIL] test_engine2_weapons.gd.test_ranges_are_the_
  section_13_row: laser 500` (`tests/test_engine2_weapons.gd:141-145`, §23.4's row).
- The acceptance's real-frame witness for a *combined* release does not exist yet (no probe flies
  one); the new suite's integration is the S2.6 model the probes themselves pin, so a probe case
  belongs with whoever gets the probes.

## Gate arithmetic and hygiene

775 (S10 close) + B1's 13 (`test_s11_inspector`) + this worker's 3 = 791 = 788 passed + 3 failed,
both runs identical. Every Godot run was bounded (`--quit-after`), under a fresh
`XDG_DATA_HOME=$(mktemp -d)`, stdout redirected to a log; no background command; no edit to
`docs/**`, `assets/**`, `staging/**`, `game/sector.gd`, `game/station_scene.gd` or anything under
`slices/D11-station-scene/`; `git add` never run. Files touched, all inside the dispatch's set:
`game/player_ship.gd`, `game/ship_fit.gd`, `tests/test_s2_6_flight.gd`,
`tests/test_engine_c3_flight_decay.gd`, `tests/test_s11_flight_stop.gd` (new). `test_flight_feel_g1.gd`
unchanged (no row moved).

## What I could not measure

No live editor session (nothing here needs godot-ai). T2's feel row — a released turn keeping its
rotation about twice as long — is asserted at the hull seam, not flown: its probe is outside this
set. The live store never moved, so there is no movement to attribute.
