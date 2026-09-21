# Engine slice 0 — M5 fix report (physics & fuel)

Worker **M5**, the fixer. Date **2026-09-21**. Engine Godot 4.7.2, headless only,
every run bounded and its stdout logged and read. File set as dispatched:
`vajb-orbit/tests/test_p1_profile.gd`, `vajb-orbit/game/player_ship.gd`,
`vajb-orbit/game/ship_fit.gd`, `vajb-orbit/tools/` — **`ship_fit.gd` was not
touched** (see D2), nothing outside the set was written.

**Verdict: all five findings M4 assigned to this pass are fixed and measured. The
universal gate reads `passed=78 failed=0` (exit 0), the review's own failing probe
goes `ok=9 failed=4` → `ok=13 failed=0`, and M1's flight acceptance still reads
44 checks / 0 failures.** No number was invented: every fix implements a §13 row or a
§4.4/§11/§12 ruling, cited per finding below.

| Tier | Finding | State |
|---|---|---|
| HIGH | F1 (gate red on the v2 save assertion) | **fixed**, gate green |
| MED | F2 (emergency mode ignores thrust) | **fixed**, 203.57 → 0.0 u/s |
| MED | F3 (afterburner burn + arm lockout + constant owner) | **fixed**, 0.0 → 3.0 Fuel/s |
| MED | F4 (`PlayerState.tick` had no caller) | **fixed**, 0.0 → 5.0 Energy/s |
| MED | F5 (no caller for `consume_fuel_cell`) | **fixed**, C fires once per press |
| MED | F6 (probe hook gap) | **closed by the dispatch's file set** — verified below |
| MED | F7 (superseded refuel wording in the spec) | **owner item, untouched** |
| — | the C key's `cargo_toggle`/`consume_fuel_cell` contradiction | **owner item, untouched** |

---

## 1. Files changed (md5 first 12; byte sizes measured)

| File | Before | After | Lines | vs the review |
|---|---:|---:|---:|---|
| `vajb-orbit/game/player_ship.gd` | 26 093 B · `de16ff6528a0` | **30 880 B · `3c40642034d6`** | 650 → 740 | before-state hash is M4's published hash |
| `vajb-orbit/tests/test_p1_profile.gd` | 14 440 B · `af4e6f305ab1` | **14 440 B · `6a9e4fa06977`** | 405 → 405 | one line, digit-for-digit (size unchanged) |
| `vajb-orbit/game/ship_fit.gd` | 17 979 B · `4f0f19662ecd` | **unchanged** | 618 | byte-identical to M4's measurement |
| `vajb-orbit/game/player_state.gd` | 10 753 B · `187fc58df09f` | **unchanged** | 280 | read only (F4/F5's other halves already existed) |
| `docs/CONTRACTS.md` | 22 762 B | **unchanged** | 401 | M4/M6 own it — see §6 handoffs |

The before-state of the hull is not recoverable from git (the wave is uncommitted;
HEAD is the *pre-slice-0* snapshot), so it was **rebuilt** by reversing this pass's
edits and proven exact against the review's published hash:

```
$ py -3.14 .agents/gen/_m5_rebuild_before.py
bytes: 26093
lines: 650
md5: de16ff6528a0bc5e5553955cdb63f72a
want bytes 26093, want md5 de16ff6528a0...
```

That file was installed as `vajb-orbit/game/player_ship.gd`, probed, and replaced by
the fixed version (md5 `3c40642034d667f52a44d47d1740f238`, backed up at
`.agents/gen/_m5_fixed_player_ship.gd`). Both the before and the after log below
therefore come from **one identical probe** against two files that differ only by
this pass's diff.

## 2. Findings fixed

### F1 — HIGH: the universal gate's stale v2 assertion (`tests/test_p1_profile.gd:204`)

**Spec section implemented: §12 item 13** (the save-schema bump to v3 that slice 0
mandates). One line, expectation and message only, nothing else in the test:

```gdscript
assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 3, "writes always persist v3")
```

| Measurement | Before | After |
|---|---|---|
| Universal gate | `passed=77 failed=1` (M4; `[FAIL] test_p1_profile.gd.test_v2_round_trip_for_every_key`) | **`passed=78 failed=0`** |
| Exit code | 1 | **0** |

The line is the only assertion in the file that names a persisted version as a fixed
number; `:99` (the fixture writes v1) and `:142` (`still a v1 file on disk`) are the
migration test's own fixture and are untouched.

### F2 — MED: Emergency Flight Mode ignores thrust (ruling 14)

**Spec sections implemented: §13 "Emergency mode | thrust locked, boost/dash locked,
reactor ×0.7", §4.4, ruling 14.** In `game/player_ship.gd`:

- new `_thrust_locked()` — `_state != null and _state.emergency_mode`, the pinned
  getter, no new state;
- `_physics_process` still samples the **raw** stick (`stick`), because the stick is
  what cancels an autopilot order (§3.1) and the reaction wheels keep answering it;
  only the commanded thrust is gated: `var throttle := 0.0 if _thrust_locked() else stick`;
- the autopilot's `desired_speed` is zeroed by the same gate, so an order steers and
  coasts instead of accelerating (see D1).

| Measurement (fuel 0) | Before | After |
|---|---|---|
| 1 s of full throttle, forward speed | **203.571319580078 u/s** | **0.0 u/s** |
| 1 s of a 400 u autopilot order, forward speed | *(not separated before the fix)* | **0.0 u/s** |
| same order with a full tank (the control) | — | **203.571319580078 u/s** |
| turn input, \|angular velocity\| after 0.5 s | — | **3.39999985694885 rad/s** (wheels live) |

### F3 — MED: the afterburner neither burned fuel nor refused to arm

**Spec sections implemented: §13 `BOOST_FUEL` 3.0/s and `DASH_FUEL` 25, ruling 11
(the toll), ruling 14 (the lockout).** In `game/player_ship.gd`:

- `BOOST_FUEL := 3.0` and `DASH_FUEL := 25.0` are declared **once**, in the hull, next
  to the other §13 global rows (`BRAKE_MULT`, the arrive radii) — the owner M4 named
  as its alternative to `ShipFit`'s `b_afterburner` row (D2);
- `_burn_boost_fuel(delta)` spends `BOOST_FUEL * delta` through
  `PlayerState.try_spend_fuel` — the one gate boost and the dash share;
- the burn is charged **before** the afterburner lights, so an empty tank refuses to
  arm it and the arm frame pays its own share: a lit afterburner has burned for every
  frame it ran;
- while `_boost_remaining > 0` each frame is charged, and a failed charge ends the burn
  instead of burning on credit.

| Measurement | Before | After |
|---|---|---|
| Fuel burned by 1 s of afterburner on a full tank | **0.0** | **3.00000000000068** (spec 3.0) |
| `_boost_remaining` after pressing boost on an empty tank for 0.5 s | **2.51666666666667 s armed** | **0.0 s** (refused) |
| Tank that runs dry mid-burn (fuel 0.05, 0.3 s of boost) | — | fuel **0.0**, `_boost_remaining` **0.0** |
| `PlayerShip.BOOST_FUEL` / `DASH_FUEL` | absent from shipping code | **3.0 / 25.0**, and `ShipFit` carries neither name |

### F4 — MED: the reactor never refilled (no `tick` caller)

**Spec sections implemented: §4.4 (the 5/s refill, the ×0.7 penalty and the fuel-cell
cooldown), the contract M4 pinned in CONTRACTS §4 and §8.1.** New `_step_reactor(delta)`
called from `_physics_process`, before the stats/body guard so the reactor advances
even on a frame with nothing else to do:

```gdscript
func _step_reactor(delta: float) -> void:
	if _state == null:
		return
	_state.tick(delta)
```

| Measurement | Before | After |
|---|---|---|
| Energy after spending 10 and running 1 s of physics | **90.0 → 90.0** (refill 0.0) | **90.0 → 94.9999999999997** (refill 4.99999999999972, spec 5.0) |
| Shipping callers of `PlayerState.tick` | none | **one** (`player_ship.gd:694`); the tests call it directly themselves |

### F5 — MED: `consume_fuel_cell` was unreachable

**Spec sections implemented: §11 (the `consume_fuel_cell` action) and ruling 13 (one
`fuel_cell` → `FUEL_CELL_UNITS` fuel, 10 s cooldown).** New `_update_fuel_cell()` from
the hull's physics step, polled the way every other one-shot action in the shipped game
is read (`game.gd` uses `Input.is_action_just_pressed` the same way) and guarded, so a
build without the binding is still safe:

```gdscript
	if not InputMap.has_action(FUEL_CELL_ACTION):
		return
	if not Input.is_action_just_pressed(FUEL_CELL_ACTION):
		return
	_state.consume_fuel_cell()
```

| Measurement | Before | After |
|---|---|---|
| `InputMap.has_action("consume_fuel_cell")` | `false` (M4) / true after the orchestrator's `project.godot` edit | **true**, bound to `InputEventKey: keycode=67 (C)` |
| Hull calls to `PlayerState.consume_fuel_cell` on one C press | **0** (no caller in shipping code) | **1** |
| Held C for 4 physics frames | — | **still 1** (an edge, not a per-frame poll) |
| A second press | — | **2** |

The conversion itself (40 fuel, 10 s cooldown, cargo spent through `PlayerProfile`) is
already covered by `tests/test_engine2_pools.gd` (in the gate) and M2's pools probe
(`ok=31 failed=0`, re-run by M4); the half that was missing — the hull-side caller — is
what the witness measures. The probe deliberately **does not** drive the shipped
conversion, because that spends a `fuel_cell` from the live `PlayerProfile` record
(M4's D3 leaked one `fuel` key into `user://profile.cfg` and had to repair it).

### F6 — MED: the probe hook gap (harness, not code)

**Closed by this dispatch's file set.** `vajb-orbit/tools/` was in `VAJB_WORKER_FILES`,
so `_probe_s0m5_reactor.gd`, `_probe_s0m5_reactor.tscn` and `_probe_s0m5_witness.gd`
were created with the `write` tool, **not** through the shell — no hook denial. The M4
probe and M1's flight probe were restored by byte copy from `.agents/gen/` (they are
archived there), not because of a denial. `tools/` ends at the wave's invariant:

```
tools now: ['build_theme.gd', 'build_theme.gd.uid', 'derive_icon_tints.gd', 'derive_icon_tints.gd.uid', 'desktop.ini']
```

Probe sources are archived for re-runs at `.agents/gen/slice0_m5_probe_reactor.{gd,tscn}`
and `.agents/gen/slice0_m5_probe_witness.gd`; M4's probe stays at
`.agents/gen/slice0_m4_probe_live.{gd,tscn}`; M1's at
`.agents/gen/slice0_m1_probe_source.{gd,tscn}` (drop back into `res://tools/` as
`_probe_s0m1_flight.{gd,tscn}`, `_probe_s0m4_live.{gd,tscn}` — the scene files name
those exact paths).

## 3. Evidence (commands, logs, results)

All commands are the brief's bounded headless form, stdout redirected to a log that was
read; nothing was left in the background.

| Run | Command target | Result | Log |
|---|---|---|---|
| Before-state proof | `py -3.14 .agents/gen/_m5_rebuild_before.py` | 26 093 B, md5 `de16ff6528a0bc5e5553955cdb63f72a` = M4's | `.agents/gen/_m5_before_player_ship.gd` |
| Review probe, **before** | `res://tools/_probe_s0m4_live.tscn --quit-after 2400` | **`ok=9 failed=4`**, exit 1 | `.agents/gen/slice0_m5_probe_live_before.txt` |
| Review probe, **after** | same | **`ok=13 failed=0`**, exit 0 | `.agents/gen/slice0_m5_probe_live_after.txt` |
| M5 probe (F3/F5 + F2's reach) | `res://tools/_probe_s0m5_reactor.tscn --quit-after 2400` | **`ok=11 failed=0`**, exit 0 | `.agents/gen/slice0_m5_probe_reactor.txt` |
| M1 flight acceptance, re-run | `res://tools/_probe_s0m1_flight.tscn --quit-after 20000` | **44 checks, 0 failures**, exit 0 | `.agents/gen/slice0_m5_probe_m1_flight.txt` |
| Universal gate (mid) | `res://tests/headless_runner.tscn --quit-after 1200` | **`passed=78 failed=0`**, exit 0 | `.agents/gen/slice0_m5_testgate.txt` |
| Universal gate (final, frozen tree) | same | **`passed=78 failed=0`**, exit 0 | `.agents/gen/slice0_m5_testgate_final.txt` |
| Boot gate, game | `res://game/game.tscn --quit-after 600` | exit 0; only the pre-existing `invalid UID` warnings (every text path resolves), **no script error** | `.agents/gen/slice0_m5_boot_game.txt` |

### 3.1 The review's probe, verbatim, before and after

```
                                                    BEFORE                          AFTER
emergency: at fuel 0 the hull ignores thrust   FAIL 203.571319580078 u/s      OK 0.0 u/s
emergency: at fuel 0 the afterburner locks out FAIL boost_remaining=2.51666…    OK boost_remaining=0.0
boost: 1 s of afterburner burns BOOST_FUEL 3.0 FAIL fuel 200.0 -> 200.0 (0.0)   OK 200.0 -> 196.999999999999 (3.00000000000068)
reactor: a spent buffer refills at 5/s         FAIL energy 90.0 -> 90.0 (0.0)    OK 90.0 -> 94.9999999999997 (4.99999999999972)
input: consume_fuel_cell (C) is in the map     OK (the orchestrator's edit)      OK
SUMMARY                                        ok=9 failed=4 (exit 1)            ok=13 failed=0 (exit 0)
```

M4 recorded `ok=8 failed=5`; the one-check difference is its fifth failure — the input
action itself, which the orchestrator has since added. Every other line reproduces
M4's numbers exactly, so the before/after pair is measured on the review's own probe,
not on a re-invention of it. The four flight and collision checks are identical in both
logs (max 424.106689453125 u/s at 2.08333333333333 s, the flat-wall figure
144.196558395699 = formula, autopilot closest 39.9171447753906 u), i.e. the fixes moved
the reactor chain and **nothing** else.

### 3.2 M5's own probe (`ok=11 failed=0`)

```
[OK] owner: the hull declares section 13's afterburner burn (BOOST_FUEL 3.0) | PlayerShip.BOOST_FUEL = 3.0
[OK] owner: the hull declares section 13's fold/dash cost (DASH_FUEL 25) | PlayerShip.DASH_FUEL = 25.0
[OK] owner: ShipFit duplicates neither name (exactly one owner)
[OK] input: consume_fuel_cell is in the input map | [InputEventKey: keycode=67 (C), mods=none …]
[OK] fuel cell: the C key reaches PlayerState.consume_fuel_cell through the hull | calls 0 -> 1 over one 4-frame press
[OK] fuel cell: a held key spends once, not once per frame (it is an edge) | still 1 calls after holding 4 frames
[OK] fuel cell: a second press spends again | calls = 2 after two presses
[OK] emergency: the reaction wheels still turn the hull at fuel 0 | |angular_velocity| = 3.39999985694885 rad/s
[OK] emergency: an autopilot order cannot thrust either at fuel 0 | speed = 0.0 u/s
[OK] emergency: the same order does thrust with fuel aboard (the control) | peak 203.571319580078 u/s
[OK] boost: a tank that runs dry ends the burn instead of burning on credit | fuel 0.05 -> 0.0, boost_remaining = 0.0
[SUMMARY] ok=11 failed=0
```

The press is injected the way a real key behaves — the action is put down in the probe
root's `_physics_process` (the root joins the physics-process group before the hull,
which is instantiated in `_ready`) for four frames and released on the fifth — so the
hull's `is_action_just_pressed` sees exactly one edge. A press that landed a frame late
would read as zero calls and fail the check, so the check is also a proof the injection
reaches the frame it claims to.

## 4. Acceptance

- **Universal gate green with zero failures**: `passed=78 failed=0`, exit 0, measured
  twice (mid-pass and on the frozen tree). The suite is 78 tests.
- **The four hull-side behaviours fixed with before and after numbers**: §3.1 above.
- **Per-finding spec section and measurement**: §2 above, one row per finding.

## 5. Deviations and judgement calls

- **D1 — the F2 gate also covers the autopilot's commanded speed.** M4's fix text named
  "the throttle sample"; §13's row says thrust is **locked** and the autopilot is the
  second thrust source, so `desired_speed` is zeroed by the same predicate. The raw
  stick is still sampled so that manual input keeps cancelling an order (§3.1) and
  turning is untouched (measured: 3.4 rad/s at fuel 0). No number was added; the
  measurement for both sources is in §2/F2.
- **D2 — the constants' owner is the hull, not `ShipFit`'s `b_afterburner` row** (M4
  offered both). Reasons: §13 lists `BOOST_FUEL`/`DASH_FUEL` as *global* calibration
  rows, not module effects; the sole consumer is the hull's booster loop; and
  `ShipFit`'s own header declares it "data, not logic". Consequence: `ship_fit.gd` is
  byte-identical to M4's measurement (17 979 B, `4f0f19662ecd`) — no risk was taken in
  the fit's resolution path. `DASH_FUEL` is declared with no consumer yet because the
  dash's activation/displacement is slice 4 by CONTRACTS §8.1; the row has its single
  owner and the dash will spend through the same gate.
- **D3 — a hull with no reactor keeps the old booster behaviour.** `_burn_boost_fuel`
  returns true when `_state == null` (a scene smoke test before `setup`), the same
  tolerance `_manual_throttle` shows for a missing input action. Both cases M4 measured
  (an empty tank and a funded tank) go through `try_spend_fuel`.
- **D4 — the C key is polled, not handled in `_unhandled_input`.** Polling matches the
  house convention for one-shot actions (`game.gd:273/287/324/420/427` all read
  `Input.is_action_just_pressed` inside a frame) and cannot be swallowed by a Control —
  which matters here because C is also bound to `cargo_toggle` (§11 vs the P1 patch
  table). That contradiction is the owner's and was **not** touched.
- **D5 — probe hygiene learned from M4's D3.** No probe of this pass touched
  `user://profile.cfg`: the fuel-cell caller is measured with a witness state, so no
  `fuel_cell` is spent and no debounced write can leak (verified: the final gate run and
  the boot gate both leave the record alone; `docs/CONTRACTS.md` §8.1's conversion
  assertions stay covered by the suite).
- **D6 — M1's flight probe needs a bigger bound than the wave's stock `--quit-after
  2400`.** At 2400 the engine quit the probe at 29 checks with no summary; re-run at
  `--quit-after 20000` it finished 44/0. Nothing to fix in the probe, but the next
  worker re-running it should use a bound ≥ 20000 (or read the summary line as the
  completion proof).
- **D7 — the boot gate's asset warnings are pre-existing and environment-deferred.**
  `game.tscn` and `player_ship.tscn` each emit `invalid UID … using text path instead`;
  every text path resolves, no script error appears, exit 0. `assets/**` was not touched
  (owner ruling: the graphics lane owns the tree; the paths still awaiting it are listed
  in `.agents/gen/asset_path_fallout.md`).

## 6. Handed to M6 (the re-review) — items outside this pass's file set

1. **`docs/CONTRACTS.md` §4's measured note is now stale**: "none of that is wired yet
   in `player_ship.gd` — thrust still accelerates at fuel 0 (203.6 u/s in 1 s), boost
   engages on an empty tank, a second of afterburner burns 0.0 fuel and the pool refills
   0.0/s (M4 findings F2–F4)" should become the after numbers in §3.1 above. M4's brief
   makes CONTRACTS the reviewer's pen, so it is not in this pass's set.
2. **`docs/CONTRACTS.md` §8.1's line** "`BOOST_FUEL` 3.0/s and `DASH_FUEL` 25 have **no
   shipping-code owner yet**" is false as of this pass; the owner is `PlayerShip`
   (`player_ship.gd:81-82`), measured by M5's probe.
3. **`docs/CONTRACTS.md` §9's expected count** is 78; the measured value today is
   `passed=78 failed=0`.
4. **F7 and the C-key contradiction stay open on the owner's desk** (§11 vs the P1 patch
   table). No worker may rebind C; `project.godot` was not touched by this pass.
5. **`tests/test_engine2_pools.gd` keeps its own `BOOST_FUEL_PER_SECOND` 3.0 /
   `DASH_FUEL` 25 consts.** That file is in no fixer's set; M4's tiering treats a test's
   local fixture consts as not a shipping owner, and the gate proves the two agree
   (3.0/25 in both).
