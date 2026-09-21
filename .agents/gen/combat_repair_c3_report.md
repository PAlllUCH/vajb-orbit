# C3 — flight decay measurement (combat/collision repair wave, 2026-09-21)

**Worker:** C3 (measurement only — nothing retuned). **Owner ruling executed:** 2
("the flight drag/inertia is retuned now"; measured before and after).
**Law read:** `.agents/gen/combat_repair_wave_task.md`,
`.agents/gen/owner_playtest_findings_20260921.md`, `docs/CONTRACTS.md` §4/§9/§9.8
territory, `docs/gameplay/18_engine_spec.md` §3.2/§13, `AGENTS.md`.

**Deliverables (all new, all inside `vajb-orbit/tests/`):**

| File | What it is |
|---|---|
| `vajb-orbit/tests/probe_c3_flight_decay.gd` | the deterministic decay probe (4 cases) |
| `vajb-orbit/tests/probe_c3_flight_decay.tscn` | the probe's scene — a bare `Node` root, as `probe_w5_lint.tscn` is |
| `vajb-orbit/tests/test_engine_c3_flight_decay.gd` | 3-test gate suite pinning the *construction* of the decay (not the values) |
| `.agents/gen/combat_repair_c3_probe.txt` | the raw probe log this report quotes, kept on disk for C6 to re-diff |

`probe_c3_flight_decay.gd.uid` / `test_engine_c3_flight_decay.gd.uid` are the
editor-generated sidecars the rest of `tests/` carries; they were written by Godot,
not by hand.

**Nothing was retuned. No asset, theme, `project.godot`, `addons/**` or `docs/**` file
was touched.** No §13 row moved.

---

## 1. The headline: the two numbers a retune must beat

Shipped launch (`game.gd:HULL_ID_DEFAULT` = `ship_vanguard` with
`ShipFit.STANDARD_FIT`), throttle released at full cruise:

> **time to 10 % of the release speed: `t10 = 1.890 s`**
> **distance carried after release: `430.32 u`** (to `|v| ≤ 1 u/s`; `425.62 u` at the
> 10 % crossing)

Both come off the same 0.1 s sample grid as the curve below. `t10` is a linear
crossing between the two samples that bracket 10 %, so it is not a grid artifact;
`1.890 = 0.9 × 2.100` exactly, the class `coast_time`.

## 2. Every case, with the derived comparison

| case | hull | v_release (u/s) | **t10 (s)** | dist @10 % (u) | **t_stop (s)** | **dist carried (u)** | samples |
|---|---|---:|---:|---:|---:|---:|---:|
| `shipped_base` | `ship_vanguard` | 406.600 | **1.890** | 425.62 | 2.100 | **430.32** | 22 |
| `fighter_base` | `ship_fighter` | 427.500 | 1.512 | 358.58 | 1.700 | 362.67 | 18 |
| `shipped_afterburner` | `ship_vanguard` + burn | 650.560 | 3.024 | 1086.71 | 3.400 | 1098.36 | 35 |
| `shipped_afterburner_burn_lit` (control) | same, burn held at release | 650.560 | 3.024 | 1086.71 | 3.400 | 1098.36 | 35 |

Derived from the snapshot's own ratios (the probe prints these as `[C3] derived`), not
measured: brake `max_speed / coast_time` = **193.619 u/s²**, damp `1 / coast_time` =
**0.476190 /s**, accel leg `max_speed / accel_time` = **161.349 u/s²** for the shipped
hull; **254.464 u/s²** / **0.595238 /s** for the Fighter.

Measured against the derived ramp: `t10` and `t_stop` agree to the grid
(1.890 / 2.100 both cases), the carried distance is **+0.79 %** over the straight-line
figure (430.32 measured vs 426.93 derived for the shipped hull) — that residual is the
body's damp integration at the tail, and it is the only place the envelope departs from
the first-order law.

**Accelerate legs** (the probe logs these too, because a retune must not lengthen them):
shipped hull **2.550 s** to 406.6 u/s (derived 2.520 s), Fighter **2.100 s** to 427.5
(derived 2.100 s), afterburner **4.050 s** to 650.56 (derived 4.030 s). Each is within
one to two 1/60 s frames of `accel_time`, the difference being the probe's 0.5 u/s
cruise tolerance.

## 3. The shipped curve (the deliverable, verbatim from the probe)

`shipped_base` — Vanguard + standard fit, `t` measured from the release frame, `speed`
= `|v|`, `s` = distance along the release heading, `drift` = `| |Δp| − s |` (0.000 in
every sample, i.e. the measured axis is the motion axis):

```text
 t (s)   speed (u/s)   s (u)     drift
 0.000   406.600        0.000    0.000
 0.100   387.238       39.853    0.000
 0.200   367.876       77.770    0.000
 0.300   348.514      113.751    0.000
 0.400   329.152      147.796    0.000
 0.500   309.790      179.904    0.000
 0.600   290.428      210.077    0.000
 0.700   271.066      238.313    0.000
 0.800   251.704      264.613    0.000
 0.900   232.342      288.976    0.000
 1.000   212.980      311.404    0.000
 1.100   193.618      331.895    0.000
 1.200   174.257      350.450    0.000
 1.300   154.895      367.069    0.000
 1.400   135.533      381.752    0.000
 1.500   116.171      394.498    0.000
 1.600    96.809      405.309    0.000
 1.700    77.447      414.183    0.000
 1.800    58.085      421.121    0.000
 1.900    38.723      426.122    0.000
 2.000    19.361      429.188    0.000
 2.100     0.000      430.317    0.000
```

The step is a constant **19.3618 u/s per 0.1 s = 193.618 u/s²** — the class coast rate
to six figures — and the last sample lands on exactly `0.000`, not on a negative
overshoot. `[C3] result case=shipped_base v_release=406.600 t10=1.890 dist10=425.62
t_stop=2.100 dist_stop=430.32 samples=22 monotone=true`.

`shipped_afterburner` (identical to the control, see §5), every 0.2 s for brevity — the
full 35-sample curve is in `.agents/gen/combat_repair_c3_probe.txt`:

```text
 t (s)   speed (u/s)   s (u)
 0.000   650.560        0.000
 0.200   611.836      126.562
 0.400   573.112      245.380
 0.600   534.388      356.453
 0.800   495.664      459.780
 1.000   456.940      555.364
 1.200   418.216      643.202
 1.400   379.492      723.295
 1.600   340.768      795.644
 1.800   302.044      860.248
 2.000   263.320      917.107
 2.200   224.596      966.222
 2.400   185.873     1007.591
 2.600   147.149     1041.216
 2.800   108.425     1067.096
 3.000    69.701     1085.231
 3.200    30.977     1095.622
 3.400     0.000     1098.365
```

Same slope, **19.3618 u/s per 0.1 s**: the afterburner changes the speed the release
starts from (650.56 against 406.60, a factor of 1.60) and nothing about the brake. Its
carry is **1098.36 u — 2.55× the base carry** for one module line.

## 4. The law the numbers describe (why the owner feels "weird drag")

`game/player_ship.gd:318-338` on a manual release is the no-move-target branch:
`throttle = 0` → `desired_speed = 0`, and because `throttle` is zero `rate` stays at
`_coast_rate()`. `_step_speed` then asks the along-heading velocity to chase zero at
`max_speed / coast_time` (`:426-435`), and it compensates the body's `linear_damp` on
that axis, so the commanded ramp is not slowed by the damp. Two consequences, both
visible in the curve:

1. **The release is an active brake, not a coast.** Zero throttle does not mean "let
   inertia carry it": it means "brake at the class coast rate". There is no free-coast
   branch in the shipped law at all, and no exponential tail — the hull reaches exactly
   zero at `coast_time` (2.1 s shipped, 1.68 s Fighter).
2. **`coast_time` is the single free number in the release path.** It sets both the
   brake rate and the body's damp, so it also owns the *lateral* settle time
   (`1 / coast_time` is the damp on the axis the brake does not touch). A retune that
   shortens the forward carry with `coast_time` shortens the sideways settle with it.

The owner's "still goes forward for a second" is therefore 2.1 s and 430 u from full
cruise, and on the afterburner 3.4 s and 1098 u. Making the carry smaller means making
`t10` and the carried distance smaller than the numbers in §1 — that is the whole of
what a retune has to beat, and §2 gives it the same two figures for the fastest class
and for the burn.

The envelope is **mass-independent**: `_step_speed` applies `mass × (accel + damp ×
along)`, so the mass cancels in `a = force / m` (arithmetic from `:426-435` and
`:597-603`, not measured — the probe's two hulls differ in both mass and `coast_time`,
so they cannot isolate it).

## 5. The burn-lit control (why the afterburner case is measured twice)

`shipped_afterburner_burn_lit` releases the throttle at boosted cruise but keeps
`boost` held. Its curve is **identical, sample for sample** to
`shipped_afterburner` (t10 3.024, t_stop 3.400, dist_stop 1098.36). Reason: with the
throttle at zero, `desired_speed = 0` regardless of `_max_speed()`, and `rate` is
`_coast_rate()`, which is computed from `_stats.max_speed`, not from
`_max_speed() * boost_multiplier`. The burn's `duration` / `cooldown` therefore never
touch the decay; only the release speed it reaches does. The control is there so C5
does not chase a booster number for a drag fix.

## 6. Every constant that drives the decay, and where it lives

| Constant | Shipped value | Lives in | Kind | Role in the release decay |
|---|---|---|---|---|
| `ShipFit.HANDLING[<hull>].coast_time` | Vanguard 2.0 s → **2.1 s** resolved; Fighter 1.6 → 1.68 | `game/ship_fit.gd:141-214` | **§13 row** — "Handling per class", `18_engine_spec.md:511-521` | **the only free number in the path**: `1/coast_time` damp and `max_speed/coast_time` brake |
| `ShipFit.HANDLING[<hull>].max_speed` | Vanguard 428 → 406.6; Fighter 450 → 427.5 | same | **§13 row** | numerator of the brake rate, and the speed the release starts from |
| `ShipFit.HANDLING[<hull>].accel_time` | Vanguard 2.4 → 2.52 | same | **§13 row** | the accelerate leg only (`max_speed / accel_time`), not the decay |
| `ShipFit.HANDLING[<hull>].hull_mass` | Vanguard 110 t | same | **§13 row** | scales the force; cancels out of the envelope (mass-independent, §4) |
| `h_plate_light.speed_penalty` | −0.05 | `game/ship_fit.gd:274`, applied `:492-505` | 09 §3 **module data** (not a §13 row) | multiplies `coast_time` **and** `accel_time` by 1.05 — it is where 2.0 s becomes 2.1 s |
| `PlayerShip._linear_damp()` | `1/coast_time` = 0.476190 /s | `game/player_ship.gd:580-583` | derived, **no literal** | written to `RigidBody2D.linear_damp` by `_apply_rigid_body` (`:597-603`) |
| `HullBody.linear_damp_mode` / `angular_damp_mode` | 1 (REPLACE) | `game/player_ship.tscn:22-23` | physics contract (CONTRACTS §4) | makes the class damp *replace* the project default instead of adding to it |
| `PlayerShip._coast_rate()` | `max_speed/coast_time` = 193.619 u/s² | `game/player_ship.gd:561-564` | derived, **no literal** | the release brake rate — the slope of §3 |
| `PlayerShip._accel_rate()` | `max_speed/accel_time` = 161.349 u/s² | `:555-558` | derived | the accelerate leg |
| `PlayerShip._step_speed` damp compensation | `force = m × (accel + damp × along)` | `:426-435` | flight-model arithmetic, no tuneable number | makes the commanded ramp exact; without it the damp would soften the brake |
| `PlayerShip.BRAKE_MULT` | 1.8 | `game/player_ship.gd:91` | **§13 row** (`18_engine_spec.md:523`) | **not in the release path** — it multiplies only the S-thrust reverse brake (`:335`); a retune at zero throttle never reads it |
| `PlayerShip.SLOW_DOWN_RADIUS` / `ARRIVE_RADIUS` | 240 / 40 | `:92-93` | **§13 rows** (Autopilot row) | autopilot arrive steering only; a manual release has no move target |
| `PlayerShip.BOOST_FUEL` | 3.0 /s | `:102` | **§13 row** | gates whether the burn may *arm* (fuel through `try_spend_fuel`); does not shape the decay |
| `b_afterburner.boost_speed_mult` | 1.6 | `game/ship_fit.gd:314` | 09 §3 **module data** / CONTRACTS §4 ("+60 %, 3 s, 8 s") — not a §13 row | raises the release speed to 650.56 u/s (the 2.55× carry in §3) |
| `b_afterburner.duration` / `cooldown` | 3.0 / 8.0 | same line | module data | when the burn ends; **measured not to change the decay** (§5) |
| physics tick | 60 Hz (no override in `project.godot`) | engine default; probe logs `physics_hz=60` | engine setting | the step the ramp integrates on |
| `ShipFit.MAX_SPEED_SCALE`, `SPEED_FLOOR_RATIO`, `POOL_CEILING_MULT`, `UNRESOLVED_HULL_MASS` | 450.0 / 0.4 / 3.0 / 1.0 | `game/ship_fit.gd:26-28`, `game/player_ship.gd:125` | flight model's own numbers | **no role in the release path** (the handling table carries absolute rows; the clamps are unreachable from a release) |
| `DRAG` / `ACCELERATION` | 120 / 420 | **nowhere in the tree** — only `docs/design/IMPLEMENTATION_PLAN.md:410` | obsolete placeholder | **no role** |

### §13 rows versus the flight model's own feel numbers

- **§13 rows that drive the decay:** exactly one per class — `coast_time`
  (`18_engine_spec.md:511-521`, nine rows). `max_speed`, `accel_time` and `hull_mass`
  are §13 rows that feed it (the first two as ratio operands, the third as a
  cancelling factor).
- **§13 rows that do *not* drive it and must not be blamed by a retune:**
  `BRAKE_MULT` 1.8, `SLOW_DOWN_RADIUS` 240, `ARRIVE_RADIUS` 40, `BOOST_FUEL` 3.0, the
  world/collision rows. A user-visible "weird drag" fix does not need any of them.
- **The flight model's own numbers (not §13 rows, and not free knobs either):**
  `_linear_damp()`, `_coast_rate()`, `_accel_rate()` and the damp compensation are all
  arithmetic on the snapshot. The only literal constants of the flight model near the
  path are `MAX_SPEED_SCALE` (450.0), `SPEED_FLOOR_RATIO` (0.4), `POOL_CEILING_MULT`
  (3.0) and `UNRESOLVED_HULL_MASS` (1.0); none is read by a release. CONTRACTS §4's
  "constants arrive via `ShipStats`, no literals in movement code" therefore holds on
  this path, and `test_engine_c3_flight_decay.gd` now checks it by ratio.
- **Module data (09 §3 — a third category, neither §13 nor flight-model feel):**
  `h_plate_light.speed_penalty` (−0.05, which is what makes the shipped `coast_time`
  2.1 s rather than 2.0 s) and the three `b_afterburner` numbers.
- **The brief's `DRAG` 120 / `ACCELERATION` 420 pair no longer exists.** It is the
  rejected placeholder of `IMPLEMENTATION_PLAN.md:410` ("`DRAG` 260 → 120 and
  `ACCELERATION` 520 → 420"), written before the slice-0 migration replaced the hybrid
  integrator with a `RigidBody2D`. `grep -rn "DRAG\|ACCELERATION" vajb-orbit/` finds no
  such constant in any shipped script, and the probe prints
  `[C3] legacy case=… no_DRAG_no_ACCELERATION_in_tree=true` to make that explicit. The
  brief and the findings doc quote it as "the shipped pair"; the pair that actually
  ships is `coast_time` / `max_speed` / `accel_time` in the §13 handling column, read
  only through `ShipStats`.

## 7. Method, and why these numbers are trustworthy

- **The probe flies the shipped code.** It instantiates `game/player_ship.tscn`, calls
  the shipped `setup(stats, state, fitted_ids)` with `ShipFit.resolve` output (the same
  fixture `test_engine2_fixes.gd` and the W6/W7 probes use), and drives the throttle
  through the real action the game reads — `Input.action_press(&"thrust_forward")` /
  `Input.action_release` — so the release takes the same branch a key-up does. No
  private method is called to move the ship, no velocity is set by hand, and the first
  run's numbers were rejected by the probe itself until the fixture was right.
- **Determinism.** Run under `--fixed-fps 60`, one main-loop iteration is exactly one
  1/60 s physics step (`[C3] clock iterations=1400 physics_frames=1401`). Two
  consecutive runs are byte-identical on all 261 `[C3]` lines; the only differing line
  is `wall_ms`, which is wall clock. The 0.1 s grid is expressed in physics ticks
  relative to the release frame, so it is not wall-clock dependent.
- **Command (bounded, self-quitting; `--quit-after` is only the watchdog):**
  ```bash
  godot --headless --path vajb-orbit res://tests/probe_c3_flight_decay.tscn \
    --fixed-fps 60 --quit-after 6000
  ```
  Exit 0 only when all four cases reached cruise and came to the probe's stop line; a
  case that cannot accelerate is reported as `[C3] note case=… never reached …` and
  fails the run (this is what caught the two fixture bugs on the way in).
- **`Input` in a headless run.** CONTRACTS §9's fourth harness limit says a `--script`
  run cannot drive an action's state. This probe is a **scene** run, and the action
  state is real and observable: `[C3] input thrust_forward=true boost=true` and the
  accelerate leg reproduces `max_speed / accel_time` to six figures. That is a
  measured counter-example to the limit's scope, worth recording next to it.
- **Known imprecision, stated rather than hidden:** the accelerate leg's `t_accel_total`
  is the first tick on which the speed is within the 0.5 u/s cruise tolerance, so it can
  read up to two frames (0.033 s) long against the derived ratio (2.550 vs 2.520). The
  decay grid itself is exact — the measured slope equals the class coast rate to six
  figures and the last sample is exactly zero.
- **"Effectively stopped" is defined by the probe:** `STOP_SPEED = 1.0 u/s`, two
  hundredths of the §13 slowest contact floor (40 u/s), and `TEN_PERCENT = 0.10`. Both
  are probe constants (`probe_c3_flight_decay.gd`), not game numbers.
- **Warning ledger (`--headless --debug`, CONTRACTS §9's fifth form).** Both new scripts
  are warning-free. The run prints 22 warnings and every one of them is attributed by
  its `at: GDScript::reload (...)` line to files this worker did not touch:
  `res://game/weapons.gd` (19) and `res://game/projectile.gd` (3) — the shadowing
  warnings C2/C5 territory already carries, and consistent with `weapons.gd` being §9's
  documented positive control. Command:
  `godot --headless --debug --path vajb-orbit res://tests/probe_c3_flight_decay.tscn
  --fixed-fps 60 --quit-after 6000`.

## 8. Gate, and what this wave changed

| | before | after |
|---|---|---|
| `[SUMMARY]` | `passed=226 failed=0` (exit 0) | **`passed=229 failed=0`** (exit 0) |
| added | — | `test_engine_c3_flight_decay.gd` (**3**) |

Both runs: `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
--quit-after 1200`, no `SCRIPT ERROR`, no RID-leak line, every other suite's count
unchanged (`engine2_weapons` 29, `engine2_npc` 28, `engine2_damage` 20, `engine2_hud`
19, `engine2_fixes` 17, `engine2_pools` 16, `p1_market` 13, `engine2_wiring` 13,
`engine2_loot` 13, `p1_catalogues` 11, `engine2_cleaving` 9, `p1_profile` 9,
`ui_slot_layout` 7, `p1_refinery` 6, `p1_repairs` 5, `p1_pricing` 5, `p1_clock_log` 5,
`engine2_dock` 2).

**Deviation to flag, not to bury:** the brief's hard rule reads "grow the count; never
shrink it", the prompt reads "keep the gate green at its measured count". I read these
as consistent — green at the measured count, and the count grows by tests, never shrinks
— so I added three tests rather than only the probe. They pin the *construction* of the
decay, never its values, and `test_engine_c3_flight_decay.gd`'s header says so: every
assertion is a ratio off the snapshot (`body.linear_damp == 1/coast_time`,
`_coast_rate() == max_speed/coast_time`, the afterburner's own module numbers), so
**C5's retune of the §13 coast column moves the probe's curve without reddening this
file**. If the intent was a literal freeze at 226, delete that one file and the count
returns to 226 with everything else unchanged. If a retune is expected to be *pinned*
in the gate, that is C5's test to add (one line asserting the new `t10`/distance in a
probe-derived form), and it should take §1's numbers as the "before".

`probe_c3_flight_decay.tscn` / `.gd` are **not** part of the gate: `headless_runner.gd`
discovers `test_*.gd` only, so the probe is run explicitly, as the C6 reviewer will.

## 9. What C5 gets, and what it still has to decide

Facts, no recommendation:

1. Both numbers to beat, on the shipped launch: `t10` **1.890 s**, carry **430.32 u**
   (Fighter 1.512 s / 362.67 u; afterburner 3.024 s / 1098.36 u).
2. One §13 column moves the whole thing: `coast_time`, nine rows, and it moves the
   lateral settle with the forward carry because the body's damp is `1/coast_time`.
3. Nothing else in the release path is free: `BRAKE_MULT` and the two arrive radii are
   not read at zero throttle, the burn's numbers are not read either, and the damp
   compensation makes the ramp exact rather than soft — the curve is a straight line to
   zero, not an exponential, so a "keep more inertia, less carry" shape means changing
   the *law* (a coast branch with its own rate, or a two-segment ramp), not only the
   number.
4. The afterburner's carry is 2.55× the base carry and depends on one module line, so a
   `coast_time` change scales it in direct proportion.
5. The after-numbers this report's §1/§2 tables must be re-measured against: re-run the
   probe as in §7 on the same command and diff the `[C3] result` lines. The gate pin for
   whatever C5 ships is C5's to add.

## 10. Open items / notes for C6 and the close-out

- The probe writes nothing to `user://` and touches no profile or log path, so L17's
  save-path hygiene does not apply to it; it also adds no autoload and no scene-tree
  resource that outlives the run.
- The stale `DRAG`/`ACCELERATION` citation appears in the wave brief and in
  `owner_playtest_findings_20260921.md:84`. Those are doc-sheet lines outside my file
  set, so I left them; the doc tick that fixes them is the owner-locked pass's.
- `IMPLEMENTATION_PLAN.md:410` is itself a historical record (the "flight placeholder
  pass"); it should stay as written, and the correction belongs in the §13 tick's
  notes, not in a rewrite of that record.
