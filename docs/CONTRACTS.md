# CONTRACTS.md — living interface contract

**Status: v1.3 (engine wave 1 + engine slices 0 and 2 + the combat/collision repair wave + the flight-feel & beam wave, re-reviewed 2026-09-21).** This file is the single source of pinned interfaces
between workers. Every worker brief says "code against CONTRACTS.md §n" instead of
re-pasting signatures; every review/fix wave owns updating it (additions and
amendments recorded at the bottom in the changelog). Never edit it mid-wave while
workers hold the same files — the orchestrator merges review-wave changes after a
wave closes. Numbers here are transcribed from `docs/gameplay/18_engine_spec.md`,
the gameplay docs,
and the wave-1 brief; deviations are reported, never invented.

Conventions and forbidden files are defined in `AGENTS.md` (§ Rules) and apply to
every agent; they are not restated here.

---

## §1 Input map (project settings)

| Action | Binding | Status |
|---|---|---|
| `interact` | F | new, engine wave 1; orchestrator-applied via godot-ai after the wave |
| `warp` | H | new, engine wave 1; orchestrator-applied via godot-ai after the wave |
| `mine` | E | existing |
| `boost` | existing | afterburner |
| `consume_fuel_cell` | R | new, engine slice 0 (§8.1, §11 of the engine spec); orchestrator-applied via godot-ai after the wave. **Owner ruling R3 (2026-09-21): the key is R, not §11's C** — C stays `cargo_toggle`, so §11's "C" is superseded |
| `countermeasure_chaff` / `countermeasure_flare` | **Z / X** | **applied** by the orchestrator via godot-ai after the wave (owner ruling **R5**, 2026-09-21): `countermeasure_chaff` **Z** (keycode 90), `countermeasure_flare` **X** (88). The code was already ready and guarded (`game.gd`'s `COUNTERMEASURE_ACTIONS`, both read behind `InputMap.has_action`); W6 finding F5 is closed |
| `strafe_left` / `strafe_right` | **A / D** | **shipped**: bound in the pre-wave commit `c37fbe3` and read by the flight-feel & beam wave (§4) — `strafe_left` keycode 65, `strafe_right` keycode 68. `turn_left` / `turn_right` keep their actions **and** their `REBINDABLE_ACTIONS` slots with `"events": []`, so a pad axis or a Controls-tab re-bind still turns; **A and D no longer turn** (owner ruling 2026-09-21, third round) |

Code defensively: `InputMap.has_action(&"warp")` / `&"interact"` /
`&"consume_fuel_cell"` guards — the actions land in `project.godot` after the
wave, never hand-edit the file. **Measured 2026-09-21 (M6 re-review):** all three
are in the map — `interact` F, `warp` H, `consume_fuel_cell` **R** (keycodes 70 /
72 / 82) — and `cargo_toggle` still C (keycode 67). The hull-side caller landed
with the fixer pass, so a real R key event reaches
`PlayerState.consume_fuel_cell` exactly once per press (M4 finding F5 closed).
**Measured 2026-09-21 (W8 re-review, slice 2):** the project input map holds **20
actions**; `countermeasure_chaff` **Z** (90) and `countermeasure_flare` **X** (88) are
there and loaded, `consume_fuel_cell` is still **R** (82) and `cargo_toggle` still
**C** (67) — `InputMap.event_is_action` for a C key event is false for
`consume_fuel_cell` and true for `cargo_toggle`, so ruling R3 holds on disk. All three
keys were then driven as **real key events in a running game** (through the editor's
input injection) and reached their spend: **Z** → `use_countermeasure(&"cm_chaff")`
(hold 1 → 0, exactly 3 ghosts in the `ghost_signature` group, `jamming()` true),
**X** → `use_countermeasure(&"cm_flare")` (hold 1 → 0, a live `CountermeasureFlare`
decoy at the signal), **R** → `PlayerState.consume_fuel_cell` (fuel 20 → 60, cooldown
10 s, hold 1 → 0).
**Measured 2026-09-21 (flight-feel & beam wave — G4 review, re-confirmed by the G5
fixer pass):** the map now holds **22 actions** (W8's 20 plus `strafe_left` /
`strafe_right`, added by commit `c37fbe3` before the wave landed), and the four
strafe/turn entries read `strafe_left` **A** (keycode 65), `strafe_right` **D** (68),
`turn_left` `"events": []`, `turn_right` `"events": []`. All four are read behind
`InputMap.has_action` guards in `player_ship.gd`, and `turn_left`/`turn_right` still
have exactly one reader each (`_manual_turn`, `player_ship.gd:429-432` — the only
reader in the project), so a re-bind or a pad deflection still turns.

## §2 ShipStats — `class_name ShipStats extends RefCounted`, `game/ship_stats.gd`

Typed fields exactly:

```gdscript
max_speed, accel_time, coast_time, turn_rate, turn_spinup: float
hull_mass: float                 # slice 0: the §13 class column, in tonnes
hull_max, shield_max, shield_regen, damage_mult: float
lock_range, scan_range, tractor_range, tractor_speed: float
tractor_streams: int
cargo_max: int
energy_max, energy_regen, fuel_max: float   # slice 0: base 100 / 5 / 200
boosters: Array[StringName]
```

`hull_mass` and the three pool fields are the engine slice 0 additions (§8.1).
Field order follows §9's list: `hull_mass` after `turn_spinup`, the pools after
`cargo_max`. No pre-slice-0 field moved, was retyped or was reordered — verified
by review probe A against the §13 table row by row.

## §3 ShipFit — `class_name ShipFit extends RefCounted`, `game/ship_fit.gd`

```gdscript
static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats
static STANDARD_FIT   # the 09 §7 standard fit (Vanguard): e_std, p_std, w_laser, s_light, h_plate_light
```

Resolver order (09 §5): hull base (08 §2) → flat module effects → multiplicative
effects (speed: armour → engine → booster-on-activation; damage: computers;
scanner/regen: best value) → clamps (speed ≥ 40 % hull base, pools ≤ 3× hull base).
The per-class handling table (ENGINE_SPEC §13) lives in W1's files as a typed
const — single owner, nobody duplicates it. Armour plating multiplies handling
times by `1 + |its speed penalty|`; shields-first vs bypass weapon families per
09 §3.1 `family` column; base shield regen 2/s.

## §4 PlayerShip — `game/player_ship.tscn` / `game/player_ship.gd`

Root `Node2D` named `PlayerShip`, group `&"player_ship"`, hull `Sprite2D` +
mining-laser child (W3's scene). API called by `game.gd`:

```gdscript
setup(stats: ShipStats, state: PlayerState, fit_ids: Array[StringName] = []) -> void
set_move_target(pos: Vector2) -> void
cancel_orders() -> void
warp_available() -> bool
signal damage_taken(amount: float)
# slice 0, additive (beyond the pin; the frozen set above is untouched):
velocity() -> Vector2
impact_body() -> RigidBody2D
apply_impulse(impulse: Vector2) -> void
apply_recoil(projectile_velocity: Vector2, projectile_mass: float) -> void
# the flight-feel & beam wave (2026-09-21, v1.3), additive beyond the pin:
set_aim_point(point: Vector2) -> void / clear_aim_point() -> void   # the probe seam
# S2.6 (2026-09-22), additive observability beyond the pin — the same shape as
# `boost_activations()`/`arc_count()`; `_physics_process` zeroes the recorder at the
# top of every step, so "no force was applied" is a reading and not an absence:
applied_force() -> Vector2    # the net central force this step's flight law applied
applied_torque() -> float     # the net torque this step's flight law applied
```

`fit_ids` is the launched fit's module ids (`ShipFit.fitted_ids`), the W-slot gate
for the mining laser; it is defaulted, so `setup(stats, state)` still resolves.
The seams above are how slice 2's weapons, detonations, the §3.4 speed fantasy and the
S2.6 review instruments reach the body without touching the node tree.

**Body (slice 0, ruling 8).** `HullBody` is a `RigidBody2D` (layer 2, mask 1 = the
rock layer, `gravity_scale = 0.0`, `contact_monitor = true`,
`max_contacts_reported = 4`, `can_sleep = false`, `linear_damp_mode` /
`angular_damp_mode` = REPLACE). The body owns momentum and the live transform; the
ship node mirrors it (`_sync_hull_transform`), so the sprite, the camera and the
laser stay with the hull. Thrust is `mass × the class acceleration`
(`max_speed / accel_time`), the brake is `BRAKE_MULT ×` that, the coast is
`max_speed / coast_time` with `linear_damp = 1 / coast_time`, and torque is
`inertia × (alpha + angular_damp × omega)` with `inertia = m·r²/2` and
`angular_damp = 1 / turn_spinup` — all derived from §13 **with two owner-sanctioned
exceptions, both owner rulings of 2026-09-21: `coast_time` is retuned ×0.50** (all
nine `ShipFit.HANDLING` rows; §13 itself is not ticked and still carries the
pre-retune column) **and `turn_rate` is retuned ×0.50** (the same nine rows; its own
before/after table and measurements are two paragraphs below, and it is the only
column the flight-feel & beam wave moved). Measured by the C3 flight-decay probe on
the shipped launch, whose resolved row is `§13 × 1.05` (the launched `h_plate_light`
penalty), so `coast_time` was 1.050 s: time to 10 % of the release speed
`1.890 → 0.945 s`, carried distance `430.32 → 216.85 u`, both accelerate legs
unchanged (`t_accel_total` 2.533 / 2.100 / 4.050 / 4.050). **Re-measured 2026-09-22
(S2.6 review, the `COAST_TIME_MULT 2.0` revert):** the resolved `coast_time` is back
at **2.100 s** on the same launch, time to 10 % of the release speed **1.890 s**
(`dist_10` **426.12 u**), and both accelerate legs ride `ACCEL_TIME_MULT 2.0`
(the `t_accel_total` rows × 2; per-class `t_90` 3.783 / 4.550 / 7.567 / 5.683 /
4.167 / 11.350 / 8.317 / 7.567 / 12.100 s). `ShipFit.HANDLING`'s literals are
**untouched** by the revert — the resolved times are the literals times the two
multipliers, so the revert is one constant, not a nine-row edit. The same column
also halves every NPC hull's coast and doubles its damp (it reaches them through
`ShipStats`), which is ruling 3's own "all nine rows", not drift. Reversal:
`ShipFit.COAST_TIME_MULT := 1.0` — §14's constant supersedes the older "multiply the
nine rows by 2.0" wording. Nothing else from §13 moved.
Body-body contacts past `COLLISION_MIN_DV` charge `Impact.collision_damage(ship
mass, peer mass, closing speed)` to the player through `PlayerState.damage`, and
offer the peer's half to `apply_collision_damage(amount)` when the peer has it.

**The turn retune (owner ruling 2026-09-21, third round).** `turn_rate` is the
**second** §13 column this project retunes ×0.50 — all nine `ShipFit.HANDLING`
rows, the same nine `coast_time` moved — and it is the **only** column the
flight-feel & beam wave moved. §13 is not ticked and still carries the pre-retune
column, so the owner's tick is still owed (the v1.3 changelog entry in §10 carries
the full tick list). Measured by G4's re-run of `probe_g1_flight_feel`
(`--fixed-fps 60`), which re-derives every row against §13's own column quoted as
a const:

| hull | §13 class | `turn_rate` before (= §13, = HEAD) | after | after °/s | ratio | `turn_spinup` |
|---|---|---:|---:|---:|---:|---:|
| ship_fighter | Fighter | 3.400 | 1.700 | 97.4 | 0.5000 | 0.40 |
| ship_vanguard | Cutter | 3.000 | 1.500 | 85.9 | 0.5000 | 0.50 |
| ship_miner | Miner | 2.000 | 1.000 | 57.3 | 0.5000 | 1.00 |
| ship_trader | Trader | 2.400 | 1.200 | 68.8 | 0.5000 | 0.70 |
| ship_corvette | Corvette | 3.200 | 1.600 | 91.7 | 0.5000 | 0.45 |
| ship_freighter | Hauler | 1.500 | 0.750 | 43.0 | 0.5000 | 1.40 |
| ship_gunship | Gunship | 1.900 | 0.950 | 54.4 | 0.5000 | 1.00 |
| ship_patrol | Frigate | 2.100 | 1.050 | 60.2 | 0.5000 | 0.90 |
| ship_destroyer | Destroyer | 1.600 | 0.800 | 45.8 | 0.5000 | 1.20 |

`turn_curve classes=9 mismatched=0 retune=x0.50`; the **row literals** — `max_speed`,
`accel_time`, `coast_time`, `turn_spinup`, `hull_mass` and the key set — are
byte-identical to HEAD (re-measured 2026-09-22, S2.6), while the **resolved** snapshot
is not: `accel_time` and `coast_time` carry `ACCEL_TIME_MULT`/`COAST_TIME_MULT` (§14)
and `max_speed` is the one column no multiplier touches. The column reaches **every
NPC hull** too (it arrives through `ShipStats`),
the same shape the retuned `coast_time` already has. The one pre-existing assertion
the ruling moved is `tests/test_combat_repair_c5.gd:288` (`turn_rate` 3.0 → 1.5,
with the ruling named inline); every other column of that test is still pinned.
Reversal: multiply the nine **`turn_rate`** rows by 2.0 and re-run
`probe_g1_flight_feel` — `turn_rate` carries **no** multiplier constant, so unlike
`coast_time` (whose §14 revert is `ShipFit.COAST_TIME_MULT`) this one is still a
literal edit; the two reversals must not be read as one.

Flight (ENGINE_SPEC §3; **the control scheme was amended 2026-09-21, third round —
this and the next three paragraphs are the shipped truth, and §3.1's "A/D turn" is
now the spec-side leftover the owner tick list names**): **W/S throttle** (S = reverse
thrust + active brake at `BRAKE_MULT` 1.8), **A/D strafe** (A left, D right:
`strafe_left` keycode 65 and `strafe_right` keycode 68 are in the project's input
map; `turn_left`/`turn_right` keep their actions and their slots with
`"events": []`, so a pad axis or a Controls-tab re-bind still turns),
angular spin-up/damping, linear coasting — constants arrive via `ShipStats`, no
literals in movement code.

**The nose follows the cursor with or without the throttle, and the heading holds
where the pilot is not aiming.** (Superseded 2026-09-22 by §14's
`STEER_WITHOUT_THROTTLE := true`; the older sentence — "the nose follows the cursor
while `thrust_forward` is held, and the heading holds when it is not" — **is** the
W-gate, and its reversal is that one condition.) `_manual_desired_turn(stick, turn)`
answers a deflected turn action first, then `_aim_turn()` **whether or not
`stick > 0.0`**. `_aim_turn` is the autopilot's own `_turn_toward` arrive steering, so
one law serves both the fly-to order and the cursor and there is no second steering
model to keep in step; `turn_rate` and `turn_spinup` still bound how fast the nose may
move. Its deadzone is the art-derived hull radius (the camera centres the hull, so
that is where the pointer rests at launch), not an invented constant — and **that
deadzone, not the throttle, is what holds a heading the pilot is not steering**. A
turn command is torque only (`_step_turn` applies `_apply_torque` and nothing else),
so a full 360° cursor turn at zero throttle is bounded by
`TURN_TRANSLATE_LEAK_MAX 5.0 u` (measured 2026-09-22 by `tests/probe_s2_6_flight.tscn`,
`--fixed-fps 60`: Vanguard `sweep_deg=360.600`, `displacement=0.000000`,
`peak_speed=0.000000`; Fighter `360.223`; Hauler `360.534` — each at its own class
`turn_rate`), and a mirrored pair mirrors exactly (`sweep_right=+321.925326°` against
`sweep_left=−321.925326°`, error `0.000000`). Measured (G4's re-run of
`probe_g1_flight_feel`): the peak turn rate is the class rate to three decimals on all
three launched cases — Vanguard `omega_peak=1.500 rate=1.500 ratio=1.000`, Fighter
`1.700/1.700 ratio=1.000`, Hauler `0.750/0.750 ratio=1.000` — and the re-derived
at-rest case sweeps `88.866°` to the cursor with `displacement=0.00000000`,
`peak_speed=0.00000000` and `leak_ok=true`. Reversal of the whole item:
`STEER_WITHOUT_THROTTLE := false`.

**The strafe is §13's own two rows and nothing else.** `_command_velocity(throttle,
lateral)` caps the stick at unit magnitude and scales it by the class `max_speed`,
and `_step_strafe` runs the **same** `_thrust_axis` chase that `_step_speed` runs on
the nose, on `_strafe_axis()` = `RIGHT.rotated(heading + PI/2)`, at `_accel_rate()`
(= `max_speed / accel_time`, pre-existing). No new balance number exists between the
§13 rows and the strafe: `grep -rn "STRAFE_FRACTION" vajb-orbit/` is empty, so the
one named constant G1 proposed was **not** added and its reversal path stays in
`.agents/gen/flight_beam_g1_report.md` §4. Measured by G4 on the shipped launch
(`h_plate_light`, so every ceiling is the §13 row × 1.05): Vanguard `t_90` 2.283 s
against a derived 2.268 s, lateral peak 368.414 of a 406.600 ceiling, 417.536 u of
travel that is 100 % lateral (forward travel −0.000 u) and heading drift
`0.00000000`; Fighter 1.900 s / 386.786 / 427.500; Hauler 5.683 s / 251.104 /
278.350; `right_is_right=true` on all three. **Re-measured 2026-09-22 (S2.6, the
`ACCEL_TIME_MULT` doubling):** a strafe's `t_90` is now `accel_time` × 0.9 × the
plating multiplier — Vanguard **4.550 s** (was 2.283), Fighter **3.783 s** (was
1.900), Hauler **11.350 s** (was 5.683) — with the lateral peaks and ceilings unmoved
(367.068 / 406.600, 385.088 / 427.500, 250.733 / 278.350) and `heading_delta=0.00000000`
on all three. `W+D` reaches the class ceiling
406.600, not √2 × it (575.019), so §3.4's `|v| / v_max` onset never leaves 1.0
(`track_deg=45.03`). **The strafe is thrust, so ruling 14's Emergency lock covers
it** — a dry tank strafes nowhere — while the cursor turn stays live.

Autopilot: LMB on empty space sets a move target, arrive steering (slow-down radius
240 u, arrive radius 40 u), the same physics; **any** throttle, strafe or turn input
cancels it, firing does not. Boosters: `boost` = afterburner (+60 %, 3 s, 8 s
cooldown) reading `ShipStats.boosters`; blink/fold (`b_fold`) is recognised as data
and inert.

**The reactor chain's hull side (slice 0, rulings 11/14) — the contract the fixer
and slice 2 code against:** the hull's `_physics_process` is the reactor's frame,
so it calls `PlayerState.tick(delta)` (refill + fuel-cell cooldown); the afterburner
burns `BOOST_FUEL` 3.0/s through `try_spend_fuel`, and both `boost` and the dash
burst spend through the same gate; under `PlayerState.emergency_mode` (fuel ≤ 0)
throttle input is ignored (drift-only, reaction-wheel turning stays live) and boost
dash are locked out. **Measured 2026-09-21 (M4, before the fixer pass):** none of
it was wired in `player_ship.gd` — thrust still accelerated at fuel 0 (203.6 u/s
in 1 s), boost engaged on an empty tank, a second of afterburner burned 0.0 fuel
and the pool refilled 0.0/s (M4 findings F2–F4). **Fixed and re-measured (M6
re-review):** at fuel 0 a full second of throttle yields 0.0 u/s while the same
throttle with fuel aboard still yields 203.57 u/s, the reaction wheels still turn
(3.4 rad/s) and an autopilot order cannot thrust either; one second of afterburner
burns 3.0 fuel and an empty tank refuses to arm (a tank that runs dry ends the
burn); spending 10 Energy refills 5.0/s, and 3.5/s under the ×0.7 emergency
penalty. `BOOST_FUEL` 3.0/s and `DASH_FUEL` 25 are declared in `player_ship.gd` —
the hull that spends them.

## §5 Combat/mining entities (slice 1 scope)

**Asteroid** — `class_name Asteroid extends RigidBody2D` (slice 0 changed the
base class from `StaticBody2D`), `game/asteroid.gd`:

```gdscript
setup(mineral_id: StringName, tier: int, yield_units: int, size_class := SIZE_ANY) -> void
apply_work(work: float) -> int   # units mined this call; WORK_PER_UNIT := 1.0
size_class() -> int              # SIZE_SMALL | SIZE_MEDIUM | SIZE_LARGE (slice 0)
cleaves() -> bool                # false when the rock rolled no ore (slice 0)
eject_velocity() -> Vector2      # the *shape's* half only: linear_velocity × 1.2, read
                                 #   before the free (slice 0). The radial half is the
                                 #   field's (FRAGMENT_OUTWARD_KICK, §14) — the rock does
                                 #   not know its fragments' spawn points.
world_radius() -> float          # the collision circle's radius
signal cracked                   # bare, unchanged: the field binds the rock itself
```

The body (slice 0, ruling 8; the mask corrected by the combat/collision repair wave,
2026-09-21): mass = `ROCK_MASS_MULT` 4 × the §13 `hull_mass` of `ROCK_MASS_REFERENCE`
`ship_miner` = 560 t, `linear_damp` 3.71 with REPLACE mode, `gravity_scale` 0,
`can_sleep = false`, **layer 1 / mask 2**. The mask names the *hull* layer, never the
rock's own: Godot pairs two bodies from both sides, and `mask 2 & layer 1 == 0` is what
keeps two rocks apart while the rock's mass now enters a ship contact. **The pre-wave
`mask 0` was the defect, not the guarantee:** with it the rock's inverse mass was
forced to 0 by the solver, so the ship's half landed while the rock's was dropped — C1
measured `v_peak = 0.000 u/s`, `pos_delta = 0.000 u`, both pools unchanged, and the
same ram on the shipped tree reads `v_peak 72.821` / `pos_delta 20.323` (C6's re-run);
a `mask 1` control still reads `0.000`, so the bit must be the hull's layer. The size
class is a look *and* the cleaving class: `FRAGMENT_SPLIT` is a **uniform 2–5 on both
cleaving tiers** (`(2,5)` L → M and M → S), `PICKUP_BURST` `(1,2)` for an S, and
ejection `× 1.2` in a **uniform 360°** direction (`FRAGMENT_EJECT_CONE_DEG` 360.0 —
the reversals are those two constants themselves: restore the fixed `(2,3)`/`(2,2)`
rows, or set the cone to `15.0`), fragment mineral **and tier** inherited from the
parent with the yield re-rolled through the 02 §5 path (the §13 row and §12 item 12
are law; §6's "re-rolled tier" parenthetical is not representable, since a mineral
fixes its tier). **Measured 2026-09-22 (S2.6's fragment burst):** the deployment is
**additive** — `AsteroidField._cleave` adds `FRAGMENT_OUTWARD_KICK 150.0` u/s (the
field's own constant, §14) along the placement radial, on top of the rolled shape, so
a stopped rock's fragments read radial `0.000 → 150.000` u/s (the owner's complaint)
while the `× 1.2` inherit is unchanged and still measurable as the residual
`deployed − radial × 150.0` (probe `tests/probe_s2_6_burst.gd`: `shape_ratio
1.199999669 .. 1.200000178` over 23 drifting fragments, and exactly `0.0` for a
stopped rock; over 200 seeded breaks: 681 fragments, lowest radial `149.520` u/s
against the 75.0 floor, all four quadrants populated, narrowest spread `122.165°`).
The RNG stream is untouched — the kick consumes no roll — so every seeded sequence
reads what it always read. Reversal of the kick: `FRAGMENT_OUTWARD_KICK := 0.0`.
Every depletion — a cleave, a Small's burst or a yield-0 crack —
also reads as the rock's **death**, not an ore event: FX_SPEC §1.4's explosion at the
rock's own centre scaled `clamp(1.2 × diameter, 96, 224) u` through
`Projectile.spawn_rock_break` (§7.3's one-shot wiring), S4's rock cue through the
four-take `sfx_impact_rock` row `CUE_POOLS` now carries, and
`Impact.apply_shockwave` on the bodies inside `I(d) ≥ MIN_SHOCKWAVE_IMPULSE` (about
63 u — §13's own floor, so no radius is invented here). `AsteroidField` does the
spawning on `cracked`, so fragments are field members from birth and count toward
`rocks()`/`is_depleted()`.

Rocks are solid to ships, block shots/beams, crack at yield 0. Gun work = 10 %
efficiency (slice-2 seam: expose `apply_work`, ship nothing else).

**MiningLaser** — `game/mining_laser.tscn`, child of PlayerShip:

```gdscript
bind(stats: ShipStats) -> void
set_active(active: bool) -> void
```

Trigger = hold `mine` (E). Beam reaches the asteroid under the cursor within
`MINE_LASER_RANGE := 220.0` u; every `MINE_CYCLE := 1.2` s of contact applies
1.0 work → one `Pickup` per unit. Beam visual: theme token (neutral/steel), no
hex literals. **AsteroidField**: 6..12 rocks per cluster (`FIELD_ROCKS_MIN..MAX`),
tracks `last_depleted_time`/`last_respawn_time` for the 02 §8 ×0.7 diminishing
window, exposes respawn for the Sector clock hook.

**Pickup** — `class_name Pickup extends Node2D`, `game/pickup.gd`:

```gdscript
setup(item_id: StringName, amount: int, is_credit_cache: bool) -> void
```

Lifetime 60 s; drifts toward the `&"player_ship"` member within `tractor_range`
(pull at `tractor_speed`; `u_salvage`/`u_tractor` base values are slice 4). On
arrival: `PlayerProfile.add_cargo` or credits API + `economy_log` line, then
`free()`. Hold full → keeps drifting.

## §6 Sector / SectorRegistry

**SectorRegistry** — `class_name SectorRegistry extends RefCounted`,
`game/sector_registry.gd`:

```gdscript
static SECTORS: Array[Dictionary]   # 7 rows per 11 §1 + §1.1 tier weights
# row shape: id, name, owner, tier_weights, backdrop_id, densities
static SECTOR_SIZE := Vector2(10_000, 10_000)  # lives here
```

**Sector** — `class_name Sector extends Node2D`, `game/sector.gd`:

```gdscript
populate(row: Dictionary) -> ...   # spawns the §8 set; documents how the player
                                   # spawn point (300 u off the dock ring) is exposed
blips() -> Array[Dictionary]       # {"pos": Vector2, "kind": StringName}
```

Blip kinds: `&"hostile"`, `&"neutral"` (one blip per asteroid field, not per
rock), `&"friendly"` (station); `&"self"` is game.gd's own. `populate` places
4–8 fields, the primary station + `DockZone` Area2D, and stub POI hooks (wreck/
anomaly/beacon arrays are slice 3 — keep the spawn table shape, spawn nothing).
Respawn bookkeeping uses the existing `WorldClock` autoload (17 §4 one-timer rule
— no second clock).

## §7 HUD — frozen API + wave-1 additions

Frozen (do not remove): `set_target`, `clear_target` (unused until slice 2).
Additions (W5 owns `ui/hud/hud.gd`/`hud.tscn`, W2 wires the calls):

```gdscript
set_prompt(text: String) -> void        # empty string hides
set_warp_channel(progress: float) -> void  # ≤ 0 hides
set_pool(kind: StringName, value: float, maximum: float) -> void   # slice 0
set_emergency(active: bool) -> void     # slice 0
```

Slice 0 additions (UI_SPEC §3.1b, engine spec §10): `kind` is `&"energy"` or
`&"fuel"`; an unknown kind is ignored rather than fatal. Energy fill `metal_light`
(turning `accent_danger` only while the emergency flag is up), Fuel fill
`metal_mid` turning `accent_danger` at ≤ 15 % (fill **and** readout), a
`EMERGENCY FLIGHT` banner above the blocks, both bars 260 × 14 with
`show_percentage = false`, every new node `MOUSE_FILTER_IGNORE`. The blocks are
built in code by `hud.gd:_build_pool_blocks()` (hud.tscn was not in the slice-0
worker set), idempotently and mirroring the scene's HullBlock pattern, so nothing
else may add an `EnergyBlock`/`FuelBlock` under `CanvasLayer/TopLeft/Blocks` until
they move into the scene.

**Slice 2 additions (engine spec §10, UI_SPEC §3.5/§3.6, W5 2026-09-21)** — all
additive, every frozen method above intact, `ui/hud/hud.tscn` byte-identical
(`hud.gd` builds the three widgets as inner classes, the same idiom as the pool
blocks; the documented "move them into the scene" follow-up stands):

```gdscript
set_lock_progress(progress: float) -> void   # §4.1's channel ring; ≤ 0 hides
set_speedometer(ratio: float, prograde: Vector2, heading: Vector2) -> void  # §3.6
hit_marker() -> void                         # §4.2 item 4; small, no numbers
# read-backs (the TargetReticle.state() precedent, so a probe can assert the HUD's own state):
lock_progress() / speedometer_ratio() -> float
lock_ring() / speedometer() / hit_marker_node() -> Control
target_info() -> Dictionary
```

`set_target_info`'s payload gains `in_range: bool` (the selected weapon's range vs
the distance) and `threat: StringName`. The dial is a 120 × 120 control with 10
segments, a cyan prograde needle and a white heading marker; `game.gd:_push_speedometer`
feeds the actual velocity as `prograde` and `Vector2.RIGHT.rotated(rotation)` as
`heading`. Two theme fallbacks are recorded rather than invented: §3.5's "Steel
Highlight" running arc uses `text_dim` and §3.6's `bone_text` marker uses
`text_primary`, because the shipped theme carries neither token and the theme is a
forbidden file. The §3.3 chaff-blip flicker (alpha 0.3–0.7 at 6 Hz) and §10's
`&"swarmer"` minimap sub-kind are **implemented** as of the 2026-09-21 fixer pass
(the fix for W6 finding F4, re-measured by W8): `KIND_SWARMER = &"swarmer"` is folded
into the hostile branch, so it is the very same `accent_danger` a `hostile` blip wears
(and the same radius); `KIND_GHOST = &"ghost"` is the neutral `text_dim` token with
**only** its alpha moved, by `ghost_alpha(now)` — a sine of the flicker's own clock
between `GHOST_ALPHA_MIN` 0.3 and `GHOST_ALPHA_MAX` 0.7 at `GHOST_FLICKER_HZ` 6.0,
repainted at `GHOST_DRAW_HZ` 12 and **only** while a ghost is on the feed
(`_sync_ghost_flicker`), so the map stays frame-free otherwise. No new theme item and
no hex literal was added; the pre-existing kinds did not move. `game.gd:_ghost_blips()`
feeds the `&"ghost"` blips from the component's own list, so the blip count and the 3 s
window cannot disagree. **No registry row pushes `&"swarmer"` today** — every hull
answers `hostile`/`neutral` through `NpcShip.blip_kind()`, which satisfies §8's class
rule; the sub-kind is supported and renders hostile-red if a row ever asks for it.

Blip kinds gain `&"friendly"`; cursor reticle drawn at the mouse position with
plain / in-range / out-of-range states (slice-1 scope: plain + mining states
only). The static `ESC · DOCK AT KEPLER-9` hint retires. Styling: existing theme
items only (`StationCaption`, `HudReadout`), no new theme items, no font-size
overrides, no hex literals.

## §8 Economy / state seams

- Only `PlayerProfile` mutates credits/cargo; every economy event logs via
  `game/economy_log.gd` to `user://economy_log.txt` (01 §7).
- Respawn/diminishing timers consume the one `WorldClock` autoload (17 §4).
- Docking: inside the station dock zone → `set_prompt("F · DOCK")`; `interact`
  files the damage report + routes `route_requested(&"loading", {destination: &"station"})`.
- Safe warp (ENGINE_SPEC §7): `warp` starts a 3 s channel pushing progress to
  `HUD.set_warp_channel`; gate `_enemy_engaged() -> bool` is trivially false in
  slice 1 (no NPCs) so slice 2 fills it; breaks on damage/aggro; on completion →
  dock route.
- **Services (slice 0).** `Repairs.refuel(profile, ship_id)` and
  `Repairs.recharge(profile, ship_id)` return
  `{ok, ship_id, fee, fuel_max|energy_max, reason?}` at `fee` 0, all-or-nothing
  like `repair()`. **Owner ruling 2026-09-21: refuel and recharge are free and
  instant station services; the spec carries no refuel CR rate and no worker may
  invent one.** Refusals use the same vocabulary as `repair()` plus
  `&"fuel_full"` and `&"no_service"`. `StationCatalog.SERVICES` (rows:
  `id`, `name`, `availability: &"all"`, `free`, `instant`, `description`; read
  via `service(id)`/`service_ids()`) carries the rows and **no price field**.
  The tank figure comes from `ShipFit.resolve(hull, STANDARD_FIT).fuel_max` — the
  same fit `game.gd` launches with. `recharge` files nothing: Energy is not
  persisted (§12 item 13 recomputes it at launch).
- **Fuel persistence (slice 0).** `PlayerProfile.set_vitals(ship_id, hull, shield,
  fuel := FUEL_UNFILED)` (-1 = leave the filed tank alone) and `vitals_of` return
  `{hull, shield, fuel?}`; a tank that actually moved emits
  `profile_changed &"fuel"`; hull/shield writes stay silent; `SAVE_VERSION := 3`
  with `MIN_READABLE_VERSION := 1`, and a v2 record reads back with **no** `fuel`
  key ("nothing filed", never an empty tank). `game.gd:_seed_vitals()` seeds a
  **filed** tank and lets `setup()` recompute Energy;
  `game.gd:_file_damage_report()` files hull, shield and fuel on dock;
  `game.gd:_push_pools()` pushes both pools and the emergency flag into the HUD at
  the existing 0.1 s cadence, behind `has_method` guards.
- **Ammo packs (slice-2 fix, pinned 2026-09-21).** `PlayerProfile.set_ammo(weapon_id:
  StringName, rounds: int) -> void` is the absolute writer the dock's pack report needs
  (§4.3 / 01 §6, W6 finding F2): an id outside `AMMO_MAX` is refused silently, the holding
  clamps at **0**, the write dirties the file and emits `profile_changed &"ammo"` **only**
  when the value actually moved, and — exactly like `buy_ammo`, which validates against
  `AMMO_MAX` but never clamps to it — no ceiling is applied beyond 0. `PlayerState.set_ammo(slot:
  int, value: int)` is a separate, **slot-indexed** writer (clamped to that slot's
  `ammo_max`); the two signatures must not be confused. `game.gd:_file_ammo_report` files
  `maxi(stored − fired, 0)` per pack on dock, and it is **not idempotent within one launch**
  — see §8.2's open finding.

## §8.1 Slice 0 — physics & fuel (pinned additions, 2026-09-21)

The migration wave's interfaces, in one place. `hull_mass`, the pools and every
number below are §13 rows (or §4.2/§4.4 prose) — nothing here is invented.

**`hull_mass`** — `ShipFit.HANDLING` is the §13 class column's single owner and
the only place the nine masses live: Fighter 80 · Cutter (`ship_vanguard`) 110 ·
Miner 140 · Trader 160 · Corvette 90 · Hauler (`ship_freighter`) 260 · Gunship 190
· Frigate (`ship_patrol`) 220 · Destroyer 300 (t). Armour plating multiplies it by
`1 + mass_add` (`h_composite` 0.10 → 121 t on the Cutter). It feeds the hull's
inertia, the collision formula, an impulse's effect and the rock reference mass.
A snapshot without it flies at `UNRESOLVED_HULL_MASS` 1.0 and says so once.

**Energy / fuel pools** — `PlayerState.energy` / `fuel` with
`energy_max` / `fuel_max` / `energy_regen` from the launch snapshot (base 100 /
200 / 5 per second, ceiling 3× base via 09 §5 step 4) and the signals
`energy_changed(current, maximum)` / `fuel_changed(current, maximum)` mirroring
the hull/shield pair. Constants: `FUEL_PER_ENERGY` 0.10, `EMERGENCY_REGEN_MULT`
0.7, `FUEL_CELL_ITEM` `&"fuel_cell"`, `FUEL_CELL_UNITS` 40.0,
`FUEL_CELL_COOLDOWN` 10.0.

```gdscript
try_spend_energy(amount: float) -> bool   # false when short; the slice-2 weapon gate
                                          # (amount 0 succeeds, negative refuses)
                                          # a success burns amount × FUEL_PER_ENERGY fuel
try_spend_fuel(amount: float) -> bool     # boost / dash burn; false when short
consume_fuel_cell() -> bool               # one fuel_cell → 40 fuel, 10 s cooldown,
                                          # false otherwise; no-op on a full tank
fuel_cell_ready() -> bool
emergency_mode: bool                      # read-only, exactly fuel <= 0
reactor_efficiency() -> float             # 0.7 under emergency, else 1.0
tick(delta: float) -> void                # refill at energy_regen × efficiency, then
                                          # the fuel-cell cooldown; a full pool gains 0
set_energy(v) / set_fuel(v)               # clamp + emit
damage(amount, bypass_shield := false, ctx := {})   # ctx accepted, no-op until slice 3
```

`BOOST_FUEL` 3.0/s and `DASH_FUEL` 25 are §13 rows. Their single shipping owner is
`PlayerShip` (`player_ship.gd`, beside `BRAKE_MULT` and the arrive radii) — the hull
that spends them through `try_spend_fuel` — while `tests/test_engine2_pools.gd` keeps
local fixtures carrying the same two values and `ShipFit` carries neither name. (M4
finding F3; closed by the fixer pass, re-measured by the M6 re-review.)

**`Impact`** — `class_name Impact extends RefCounted`, `game/impact.gd` (new in
slice 0). The §4.2 items 6–8 arithmetic and the §13 constants it is made of, in
one file: `COLLISION_FACTOR` 2.0e-5, `COLLISION_MIN_DV` 40.0,
`KNOCKBACK_FRACTION` 0.40, `EXPLOSION_P0` 4000.0, `EXPLOSION_WINDOW` 0.2.

```gdscript
static collision_damage(mass_a: float, mass_b: float, relative_velocity: float) -> float
    # 0.5 · reduced_mass · Δv² · COLLISION_FACTOR, 0 below COLLISION_MIN_DV;
    # a peer with no finite positive mass reads as immovable (the flat-wall case,
    # which is §16's worked example: 80 t at 450 u/s → 162)
static knockback(remaining_speed: float, projectile_mass: float) -> float
    # 0.40 · ½ · m · v², i.e. the energy share §4.2 item 7 names; the impulse that
    # carries it is sqrt(2·E·M) and stays at the hit site, which knows M
static recoil_impulse(projectile_mass: float, muzzle_speed: float) -> float
    # m · v, applied as an impulse opposite the muzzle (a shot leaves in one step)
static explosion_impulse(distance: float) -> float      # P₀ / (1 + d²)
static apply_shockwave(epicenter: Vector2, body, window: float) -> void
    # the outward impulse sliced over window × physics_ticks_per_second, so no
    # slice constant is invented; a body outside the tree or a sub-tick window
    # takes the whole impulse at once
```

`PlayerShip` calls `collision_damage` from its contact monitor, so a ram charges
the player through `PlayerState.damage` (shield first, §4.2 item 1) and the peer
through `apply_collision_damage(amount)` when it has that method; `apply_recoil` /
`apply_impulse` / `impact_body` / `velocity` are the push seams.

**Station services and persistence** — see the §8 bullets: `Repairs.refuel` /
`Repairs.recharge` (free, `fee` 0, owner ruling 2026-09-21),
`StationCatalog.SERVICES`, `set_vitals(…, fuel)` + `profile_changed &"fuel"` +
save v3, and `game.gd`'s pool push.

**Deliberately out of slice 0 (so the next wave does not re-litigate it):** the
dash's 400 u displacement and its 0.8 s invulnerability (`b_fold` is data-only:
`blink_distance` 400, `cooldown` 20 — the activation, the displacement and the
i-frame gate land with the booster work in `player_ship.gd`, not in the pools);
the mining laser's 5 E/s beam drain and the weapon draw rates 6/10/5 E/s (§14
slice 2 assigns the power-draw hooks to W1); the asset-family path sweep (the
graphics lane owns `vajb-orbit/assets/**`, environment-deferred).

## §8.2 Slice 2 — fight (pinned additions, 2026-09-21)

The wave's interfaces, in one place. Every number below is a §4.1/§13 row or a gameplay-doc
table row; the handful of values with **no** row are named as such and reported, never
presented as spec.

**`WeaponComponent`** — `class_name WeaponComponent extends Node2D`, `game/weapons.gd`
(new). Mounted by `PlayerShip` as a child named for `PlayerShip.WEAPONS_NODE` and reached by
`load()` (never by `class_name`, so a parallel lane's file cannot break the mount), exactly
like the mining laser; the mount is gated on the fit carrying a weapon module.

```gdscript
setup(stats: ShipStats, state: PlayerState) -> void
set_fitted(ids: Array[StringName]) -> void          # module ids and weapon ids both land
select_group(group: int) -> void                    # weapon_1..5; clamps to 1..5
selected_group() -> int / selected_weapon() -> StringName / fitted() / is_fitted(id)
set_firing(active: bool) / poll_input() / is_firing() -> bool   # the explicit trigger seam
dry_reason() -> StringName                          # &"" can fire; &"energy"/&"ammo"/&"none" cannot
set_lock_target(target: Node2D) / clear_lock_target() / lock_target() -> Node2D
set_aim_point(point: Vector2) / clear_aim_point()   # the probe/non-mouse aim seam
tick(delta: float) -> void                          # `_physics_process` is exactly this call
use_countermeasure(item_id: StringName) -> bool     # spends through PlayerProfile.remove_cargo
jamming() -> bool / ghosts() -> Array[Node2D] / flare() -> Node2D
signal shot_fired(weapon_id: StringName)            # once per released shot / per beam hold
signal dry_fired(weapon_id: StringName)             # once per trigger pull
signal locks_broken()                               # §4.6's chaff, for the lock's owner
signal countermeasure_used(item_id: StringName)
# statics — the family table's read-only door; this file stays its single owner:
static row_of(id) / weapon_ids() / family_of(id) / range_of(id) / dps_of(id)
static interval_of(id) / shot_damage(id) / ammo_slot(id) / weapon_id(value)
```

`FAMILIES` is the table (§4.1 + §13): laser 500/30 dps/6 E·s, plasma 450/70/10 with
`hull_bonus` 1.25, cannon 600/45/0 with a bolt at 1000 u/s and the 0.35 on / 0.25 off cycle,
railgun 800/60/0 with a slug at 1400 u/s, rocket 900/180 alpha/900 u/s/2.2 rad/s/1.2 s, mine
arm 2.0 s and trigger 60 u. Constants: `SHARED_PACK {&"railgun": &"cannon"}` (§4.3's shared
pack), `GUN_CHIP_RATE` 0.10 (§6 ruling 17), `CHAFF_WINDOW` 3.0, `CHAFF_GHOSTS` 3,
`FLARE_LURE` 450.0, `GROUPS_MAX` 5, the layers (rocks 1, hulls 2, shots bit 3) and the four
**unpinned** values `SHOT_MASS` 1.0, `HIT_RADIUS` 4.0, `KINETIC_INTERVAL` 0.6 and the mine's
alpha 180 — each a one-line tunable with its gap named in the file and the report (see §10's
v1 note).

**`Projectile`** — `class_name Projectile extends Area2D`, `game/projectile.gd` (new), built
entirely in code (no scene, no art).

```gdscript
configure(config: Dictionary) -> void   # kind (&"bolt"/&"slug"/&"rocket"/&"mine"), speed,
                                        # damage, bypass_shield, homing, target, turn_rate,
                                        # source + direction, range, arm, trigger, mass, chip
family() -> StringName / is_destructible() -> bool / hit_radius() -> float
damage_amount() / bypasses_shield() -> bool / velocity() -> Vector2 / source() -> Node2D
lock_target() -> Node2D / decoy() -> Node2D      # decoy = the live flare that lured it
retarget(lure: Node2D) -> void                   # §4.6's half
fizzle() -> void                                 # a weapon hit kills a rocket, §4.1
signal detonated(pos: Vector2, damage: float, bypass_shield: bool)
```

Kinetics fizzle at their row's range; a homing rocket follows the lock (a live flare
overrides it); a mine arms after 2 s and triggers on a hull of the `player_ship`/`npc_ship`
groups inside 60 u — never on its own source. Knockback and the `I(d)` blast ride
`impact.gd` (§4.2 items 7–8) and are never re-derived here.

**`Damage`** — `class_name Damage extends RefCounted`, `game/damage.gd` (new).

```gdscript
static apply(target, amount: float, bypass_shield := false, ctx := {}) -> void
static regen(state: PlayerState, delta: float, quiet_since: float) -> void
static bearing(target_position: Vector2, heading: float, source_position: Vector2) -> float
static context(target_position, heading, source_position, impulse := 0.0, family := &"") -> Dictionary
static ram(target: Node2D, peer_position: Vector2, mass_a: float, mass_b: float,
           closing_speed: float, family := FAMILY_COLLISION) -> float
static knockback(target: Node2D, projectile_mass: float, remaining_speed: float, origin: Vector2) -> float
static detonate(epicenter: Vector2, damage: float, bypass_shield: bool, bodies: Array, family := FAMILY_EXPLOSION) -> int
const REGEN_QUIET := 4.0                  # §4.2 item 2 / §13
const CTX_DIRECTION / CTX_IMPULSE / CTX_FAMILY
const FAMILY_COLLISION := &"collision" / FAMILY_EXPLOSION := &"explosion"
```

`apply` calls `take_damage(amount, bypass_shield, ctx)` when that method declares the third
parameter, else `take_damage(amount, bypass_shield)`, else `PlayerState.damage` — the three
sink shapes the wave pins. `direction` is `wrapf((source − target).angle() − heading, −PI,
PI)` (0 ahead, +PI/2 starboard, ±PI astern; slice 3 reads `absf(direction)`). **`impulse` is
deliberately untyped**: the pipeline's own helpers record the float `Impact` returns while a
weapon call site records the `Vector2` it pushed with; slice 3 reads `direction` only, so
nothing that ships depends on which shape a given call site used.

**`NpcShip` / `NpcBrain` / `NpcRegistry`** — `game/npc_ship.gd`, `game/npc_brain.gd`,
`game/npc_registry.gd` (new).

```gdscript
# NpcShip — group &"npc_ship", hull body layer 2 / mask 1 (so shots can see it)
setup(archetype: StringName, stats: ShipStats, hull_id: StringName, opts := {}) -> void
  # opts: OPT_HOME, OPT_SPACE_OWNER, OPT_ROUTE, OPT_SPRITE_PATH
take_damage(amount: float, bypass_shield := false, ctx := {}) / apply_collision_damage(amount)
despawn() -> void                          # the sector's recycle; no death flow
intent() -> Dictionary                     # state, waypoint, speed, fire, target_pos, los
engaged_with(node: Node) -> bool           # §7's safe-warp gate: Alert/Engage on that node
blip_kind() / archetype() / hull_id() / row() / faction() / space_owner() / home()
hull() / hull_max() / shield() / shield_max() / hull_fraction() / is_alive()
shield_up() -> bool                        # §4.1's shield reads; added 2026-09-21,
                                           # already pinned on PlayerShip (player_ship.gd:258)
state_name() / target() / heat_on_kill() / standing_on_kill() / art_ready()
impact_body() / velocity() / apply_impulse() / last_damage_ctx()
signal died(position: Vector2, archetype: StringName)
# NpcBrain — one state set for every archetype, no tree access (the LOS check is injected)
setup(archetype: StringName, row: Dictionary, home := Vector2.ZERO) -> void
set_line_of_sight(check: Callable) / set_home(pos) / set_route(points)
tick(delta: float, ctx: Dictionary) -> Dictionary
state() / state_name() / is_engaged() / target() / target_position()
aggro_radius() / scan_radius() / release_radius() / is_static() / request_despawn()
const IDLE/PATROL/SCAN/ALERT/ENGAGE/FLEE/RETURN/DESPAWN, AGGRO_COOLDOWN := 5.0,
      LEASH_RADIUS := 2500.0, the CTX_*/INTENT_* key names
# NpcRegistry — one owner for the per-sector shape and doc 13's rules
static NPCS: Array[Dictionary] / archetype(id) / has(id) / ids()
static spawns_for(sector_id) -> Array[Dictionary]   # per hull: archetype, hull_id, min, max,
                                                    # faction_id, sprite_path, group_kind
static density(id, sector_id) -> Vector2i / density_table(sector_id)
static is_hostile(row, contact, heat_tier, attacked) -> bool
static heat_tier(heat) / heat_min(tier) / tier_at_least(tier, floor)   # 13 §3's 20/50/80
static space_owner(sector_id) / sector_index(sector_id)
static sprite_path_for_hull(row, hull_id, owner) / sprite_path(row, owner)
const HOSTILE_BAND (S1 0-1 … S7 6-8), HOSTILE_FILL [pirate, swarmer],
      PATROL_PRESENCE (1,1) — a proposal, not a spec row — CONVOY_HAULER/ESCORT/ESCORTS,
      HEAT_TIERS, the KEY_* keys, BLIP_HOSTILE/BLIP_NEUTRAL
```

The registry's seven bands are §13's verbatim and are the single home of the counts
(pirate + swarmer sum to each band, patrols only in owned space, one convoy per inhabited
sector); `13_heat_bounty.md` §4 now carries a copy for the pointer chain.

**`LootTables`** — `class_name LootTables extends RefCounted`, `game/loot_tables.gd` (new),
pure data plus one roll.

```gdscript
static roll(kind: StringName, tier: int, random_seed: int = 0) -> Array[Dictionary]
static has(kind: StringName) -> bool
static cap_violations() -> Array[String] / uncatalogued_items() -> Array[StringName]
const TABLES (kind -> {band, lines}) / FIGHTER_LINES / FREIGHTER_LINES / CORVETTE_LINES / MAW_LINES
const CREDIT_ITEM := &"credits" / KEY_ITEM / KEY_AMOUNT / KEY_CACHE
```

`kind` is the 06 table's hull-band name (`fighter`, `swarmer`, `freighter`, `corvette`,
`maw`) — **not** the 18 §5 archetype name — and `&"swarmer"` points at the fighter lines
(ruling 24 / 06 §3.1's amendment), so the two cannot drift. Odds are independent per line
(the sums are 1.70/1.70/1.40/1.35/4.00, never 1.0), an empty payload is legal, one payload
dictionary is one `Pickup.setup(item_id, amount, is_credit_cache)` call, and `tier` is inert
in v1 (06 §7's sector scaling is "documented, not built"). The two countermeasures are the
only ids without an 03 catalogue row.

**Wiring (W5, in `game/game.gd` / `game/sector.gd` / `game/player_ship.gd`).**

```gdscript
# PlayerShip, additive beyond §4's pin:
take_damage(amount: float, bypass_shield := false, ctx := {}) -> void   # -> PlayerState.damage
shield_up() -> bool                                                     # §4.1's shield reads
const WEAPONS_NODE := &"WeaponComponent" / WEAPONS_SCRIPT := "res://game/weapons.gd"
# it also calls Damage.ram for a body-body contact (recording the item-5 context) and
# Damage.regen from its own _physics_process against its own damage-quiet timer.
# Sector, additive beyond §6's pin:
signal npc_spawned(ship: Node2D)   # raised per hull so game.gd binds `died` before the first shot
npcs() -> Array[Node2D]            # the live hulls; `spawn_plan()` carries the rolled counts
# game.gd (the scene that owns the wiring):
const LOCK_CHANNEL := 1.2 / PASSIVE_RADIUS := 1500.0 / WARP_CHANNEL := 3.0
const COUNTERMEASURE_ACTIONS (unbound — see §1) / TARGET_NEXT_ACTION := &"target_next"
const DROP_WINDOW := 300.0         # §2.7's 5-minute recovery window
const EVENT_AMMO / EVENT_DROP / EVENT_KILL   # this scene's additions to 01 §7's vocabulary
```

The lock is a 1.2 s line-of-sight channel (`LOCK_LOS_MASK` = rocks + hulls) that pushes
`set_lock_progress`, marks on completion and is cleared by ESC; Q (`target_next`) cycles the
passive radar's marks, which are **not** locks. `_enemy_engaged()` asks each hostile-classed
`npc_ship` whether it is in Alert/Engage on the player, and §7's 5 s damage half is ANDed in
`_warp_ready` through `PlayerShip.warp_available()`. Death: hull 0 → `died` → explosion +
`Impact.apply_shockwave` → the hold drops as pickups with `DROP_WINDOW` → respawn docked; the
wreck record itself is slice 4. The HUD's weapon slot is 0-based and `select_group` is
1-based (`game.gd:_select_weapon` adds 1) — the wave's only such offset.

**Standing rulings (2026-09-21 — recorded so no later wave re-litigates them):** (1)
refuel/recharge are free and instant and no CR rate exists anywhere; (2) the graphics lane
owns `vajb-orbit/assets/**` — a failure that is only a missing or moved asset path is
environment-deferred and is **not** a finding; (3) `consume_fuel_cell` is **R**,
`cargo_toggle` keeps C; (4) **no invented number** — a missing spec value is reported, never
guessed; (5) **R5** (slice 2): the two countermeasures ship on **Z** (chaff) and **X**
(flare) — §11 names neither, so these two bindings are the shipped truth and a spec-edit
item; (6) **R6** (slice 2): the mine's blast alpha **180** and the kinetics' **0.6 s**
cadence are **accepted** as the spec's own numbers — the next spec pass records them as
rows so their provenance stops being a borrowing, and **no later wave may flag them as
invented constants**. The item-5 combat context is unchanged by all of this: `impulse`
stays Variant-shaped (`Vector2` from a weapon call site, `float` from the `Impact`
helpers) and slice 3 reads `direction` only.

**The wave's one HIGH is CLOSED and re-verified (W8, 2026-09-21).** A shot's damage was
handed to the collider — for a hull its `HullBody`, a bare `RigidBody2D` with no
`take_damage` — so no weapon damaged a ship. The fixer added a private `_sink_for(target)`
to **both** delivery files (`weapons.gd:707`, `projectile.gd:529`), which returns a target
that answers for itself untouched and otherwise walks to the nearest ancestor in the
`player_ship`/`npc_ship` groups. Re-measured on the fixed tree: 1 s of laser at 300 u
drains the victim's shield **800 → 770** (its 30 dps in full, with the shooter's Energy
paid), a released cannon bolt crossing the same 300 u charges the hull **1250 → 1223**
(27 per bolt, shield untouched), the mine's 180 control still lands on the hull, and
plasma's `+25 %` reads the **ship's** `shield_up()` rather than the body's silence (70
drained while the shields hold, **87.5** once they are down). The reviewer's own probe
source, run byte-identically (`md5 a6778c82b270e2609c9c00fe38ac0e36`), reads
`ok=126 failed=0` where it read `ok=124 failed=2`.

**The wave's one open finding at the re-review (W8, MED, one line, NOT fixed here).**
`game.gd:_file_ammo_report` is **not idempotent within one launch**: it files
`live = seed − fired` against the launch's `_ammo_seed` and never re-seeds, so a second
call re-applies the same delta. Measured on the live scene: 300 → 297 → **294** with no
further firing. It is reachable because `_request_dock()` has no re-entry guard while
`Router.route()` awaits a **0.2 s** fade (`FADE_SECONDS`) before `change_scene_to_packed`,
so a second `interact` press inside the dock zone during that window files again. The
cure is one line at the end of the filing loop — `_ammo_seed[weapon_id] = live` — or a
`_docking` flag on `_request_dock`. The vitals half (`set_vitals`) is absolute and
idempotent; only the ammo half is affected, and the over-charge is bounded by the rounds
actually fired.

## §9 Universal test gate

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200
# host-resolved form (Linux; $GODOT_CONSOLE / $VAJB_PROJ resolve in no tool shell —
# run it as: `source ~/.profile && godot --headless --path vajb-orbit \
#   res://tests/headless_runner.tscn --quit-after 1200`)
```

Expected: **`[SUMMARY] passed=493 failed=0`**, exit 0 (measured twice on 2026-09-23 by the
S3 fixer pass — S3-K5 — with the canonical command below, the live `user://` byte-identical
before and after; **493 tests over 43 suites**). The S3 review before it read
**`passed=491 failed=0`** (measured twice the same day by S3-K4), and the difference is the
two regression tests that fix added for its one HIGH (`test_p2b1_outfitting_panel.gd:662`
and `:703`, the OUTFITTING strip's REMOVE against an instance-keyed cell). The wave before it
read **`passed=457 failed=0`** (measured twice on 2026-09-22, the S3 docs pass; 457 tests
over 40 suites), so the item-economy wave's own growth is `457 → 471 → 482 → 491 → 493`
(S3-K1's instance core and its two suites, S3-K2's AUCTION and its one, S3-K3's
seven-plus-two on FITTING and the shipyard, S3-K5's two on the strip). The reading between the
S2.6 wave's builder pass and its fixer pass was `passed=455 failed=2` — the two
assertions its hit-FX jitter moved, `tests/test_flight_beam_g2.gd:256-258` and
`tests/test_weapon_fx_f4.gd:138-140`, both pinning the contact FX exactly on the
resolved hit point; the fixer re-derived them (`:256-261`, `:138-143`) and
`passed=457 failed=0` has held since. **The gate is hermetic as of S2.6** (CONTRACTS
§14): the canonical command above runs against a scratch store the runner points
itself at, so it no longer needs an `XDG_DATA_HOME` wrapper and it no longer drifts
with the owner's live account — the one `SCRIPT ERROR` in the log is L61's
pre-existing line, now printed at `tests/test_weapon_fx_f4.gd:178`. The last green
reading before that was
`[SUMMARY] passed=437 failed=0` (measured on this host 2026-09-22 by the P2-B proper
fitting wave's fixer pass — the wave closed 389 → 402 → 420 → 431 → 437, with P2-B1's
weapon-fit wave (378 → 389), P2-A's slot-grid wave (311 → 372) and the rock-cleave wave
(372 → 378) before it),
exit 0. A wave is
done = gate green + the worker added tests for their slice. The suite held **53**
tests through engine wave 1; engine slice 0 added `tests/test_engine2_pools.gd`
(**16**) and `tests/test_engine2_cleaving.gd` (**9**), engine slice 2 added six
`tests/test_engine2_*.gd` suites — `weapons` (**29**), `npc` (**28**), `damage`
(**20**), `hud` (**19**), `loot` (**13**) and `wiring` (**13**) — the slice-2 fixer
pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
`tests/test_engine2_dock.gd` (**2**), the UI-chrome wave added
`tests/test_ui_slot_layout.gd` (**7**), and the combat/collision repair wave added
`tests/test_engine_c3_flight_decay.gd` (**3**) and `tests/test_combat_repair_c5.gd`
(**7**). **That paragraph is the history of how the total grew to the 236 the
combat/collision repair wave measured**; the count kept growing after it
(277 weapon-FX → 294 flight-feel/beam → 311 slice 2.5 → 372 P2-A → 378 rock cleave →
389 P2-B1 → 437 P2-B proper → 457 with S2.6, measured 2026-09-22 → **491 with S3**,
measured 2026-09-23 → **493 with S3's fixer pass**, measured 2026-09-23), so the number to
read is always the measured one with zero failures, never a stale total — and never the
236. Discovery is
automatic (`tests/headless_runner.gd` finds `test_*.gd`); no
registration file exists to edit. **Measured 2026-09-21 (W6 review, slice 2):
`passed=200 failed=0`, exit 0, no `SCRIPT ERROR`, no RID-leak line**, per suite
`engine2_cleaving 9 · engine2_damage 20 · engine2_hud 19 · engine2_loot 13 ·
engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 ·
p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
p1_refinery 6 · p1_repairs 5`. The one red of the slice-0 era
(`test_p1_profile.gd:204`, the save-version digit) stays fixed. **Measured again
2026-09-21 (W8 re-review, before the slot suite): `passed=217 failed=0`,
exit 0, no `SCRIPT ERROR`, no RID-leak line**, per suite `engine2_cleaving 9 ·
engine2_damage 20 · engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 ·
engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 ·
p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
p1_refinery 6 · p1_repairs 5`. **Measured 2026-09-21 (combat/collision repair
wave review — C6): `passed=236 failed=0`, exit 0, no `SCRIPT ERROR`**, per suite
`combat_repair_c5 7 · engine2_cleaving 9 · engine2_damage 20 · engine2_dock 2 ·
engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 ·
engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · engine_c3_flight_decay
3 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7` — the 18 pre-existing suites are
unchanged and the wave's 10 are C3's `tests/test_engine_c3_flight_decay.gd` (**3**)
and C5's `tests/test_combat_repair_c5.gd` (**7**). **Known trap:**
headless `--check-only --script` cannot resolve autoload singletons — never use it
as a gate; use scene runs or `load()` probes. **Second form of the same trap
(measured in the slice-2 review):** a `--script` probe must reach an autoload-touching
scene with `load()` after the first frame, never with `preload` — `preload`ing
`res://ui/hud/hud.tscn` fails to compile `hud.gd` with "Identifier not found:
SettingsManager", because an autoload's global identifier is only registered once the
SceneTree is up. **Third form, measured in the slice-2 re-review:** the same trap hits a
`const preload("res://game/game.gd")` written at the top of a probe — `game.gd:1231` names
the `Router` autoload, so the whole file fails to compile with "Identifier not found:
Router" *before* `_init` runs, and the failed compile is cached, which then poisons a later
`load("res://game/game.tscn")` (the scene instantiates without its script, so `_state` never
appears). Reach the flight scene with `load()`, never `preload`. **Fourth harness limit,
measured the same pass:** a `--script` run cannot exercise an `Input` action's state —
`Input.parse_input_event(Z)` leaves `is_action_pressed` false and the strength 0.0 there
(and in a live but *unfocused* game window it is unreliable), so a probe proves a binding
with `InputMap.event_is_action(event, action)` and the live key press itself is measured in
a running game through the editor's input injection. **Fifth harness limit, measured in the
UI-chrome wave (2026-09-21):** a headless run *can* observe warnings after all, which the
wave's D5 pass assumed it could not — `--headless --debug` attaches the local stdout
debugger and prints every `WARNING: ...` attributed as
`at: GDScript::reload (res://file:line)`, so a per-file lint ledger is buildable by loading
one file at a time between printed markers (`vajb-orbit/tests/probe_w5_lint.tscn` is the
reference implementation: zero warnings in all nine D5 files, 19 in the `weapons.gd`
positive control). Never record "verified by reading the source" while this one-command
ledger exists.

**Measured 2026-09-21 (flight-feel & beam wave — G4 review, re-confirmed by the G5
fixer pass): `passed=294 failed=0`, exit 0**, per suite `weapon_fx_f1 22 ·
weapon_fx_f2 13 · weapon_fx_f4 6 · combat_repair_c5 7 · engine2_cleaving 9 ·
engine2_damage 20 · engine2_dock 2 · engine2_fixes 17 · engine2_hud 19 ·
engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 ·
engine2_wiring 13 · engine_c3_flight_decay 3 · flight_beam_g2 5 · flight_feel_g1 12 ·
p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7` (26 suites; the three `weapon_fx_*`
ones were missing from the previously recorded per-suite list, which is why the
numbers above are read off the log rather than carried forward). The wave's whole
growth is **277 + 12 + 5 = 294**
(`test_flight_feel_g1` 12, `test_flight_beam_g2` 5) and nothing else moved: G4's HEAD
A/B, with the wave's eleven modified files stashed and its two new suites moved
aside, reads `passed=277 failed=0`. **The green run carries exactly one
`SCRIPT ERROR`, and it is pre-existing** — `Cannot call method 'call' on a
previously freed instance.` at `tests/test_weapon_fx_f4.gd:176`, where line 175's
`_clear()` frees the rig's `guns` node before line 176 calls it; the same block
appears in the HEAD A/B and the file is unmodified, while the test still passes and
the exit code is 0. It is `.agents/gen/_state/LOW_BACKLOG.md` L61, owed to that file's next
owner (move the `_hide_beam` call above the `_clear()`). So the number to read is
`passed=294 failed=0` with exit 0, and that one `SCRIPT ERROR` line is not evidence
of a regression until L61 is fixed. **The warning ledger's count**, from the §9
instrument (`probe_g4_lint.tscn` under `--headless --debug`): the wave's eleven
touched files went **37 sites → 0** and its seven new files **3 → 0** (G5's three
renames at `tests/test_flight_beam_g2.gd:51`, `tests/probe_g3_shadow.gd:134` and
`:139`), leaving **15 rows in five files no worker owned** — `game/npc_ship.gd` 4,
`game/npc_brain.gd` 4, `game/npc_registry.gd` 3, `game/asteroid.gd` 3 and
`ui/hud/minimap.gd` 1 (the positive control).

**Measured 2026-09-22 (S2.6 truth-and-feel — R6's review pass, the wave's own gate).**
Two direct runs **on the real `user://` path with the owner's live account present** read
`passed=455 failed=2` exit 1 **byte-identically**, a third run through
`staging/verify_wave.py verify --tests` fails the gate by its own `failed=0` criterion like
them, and a fourth run against a **mutated copy** on a scratch `XDG_DATA_HOME` reads the
identical `passed=455 failed=2` — so the counts no longer depend on the account (L90/L93
closed by CONTRACTS §14's runner sandbox). The live
`profile.cfg` (2089 B, md5 `df4dd91530a92398b3cff40573ed39af`) and the live
`economy_log.txt` (61429 B) were **byte-identical before and after every run**, with
`mtime` unmoved (`2026-09-22 20:58:52`) — the gate writes only its own
`user://_gate_scratch/` (`profile.cfg` 369 B, `economy_log.txt`) and never the account.
Per suite (40 suites, 457 tests): `combat_repair_c5 7 · engine2_cleaving 15 ·
engine2_damage 20 · engine2_dock 2 · engine2_fixes 17 · engine2_hud 19 ·
engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 ·
engine2_wiring 13 · engine_c3_flight_decay 3 · flight_beam_g2 5 · flight_feel_g1 12 ·
p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 11 ·
p1_refinery 6 · p1_repairs 5 · p2a_launch_fit 12 · p2a_lint_shadow 2 ·
p2a_profile_fits 11 · p2a_ship_roster 4 · p2b1_outfitting_panel 9 ·
p2b_fitting_panel 20 · p2b_retirement 16 · p2b_services 12 · s2_6_beam 4 ·
s2_6_blur 2 · s2_6_burst 4 · s2_6_flight 7 · s2_6_gate_hygiene 3 · ship_grids 27 ·
slice2_5_feel 17 · ui_slot_layout 12 · weapon_fx_f1 22 · weapon_fx_f2 13 ·
weapon_fx_f4 6`. The only `SCRIPT ERROR` in the run is L61's pre-existing
`test_weapon_fx_f4.gd:176` line, and the only other `ERROR` is the pre-existing
`Parameter "data.tree" is null.` from `weapons.gd:_world_parent` on a detached hull
(backtrace `_beam_plasma` at `test_combat_repair_c5.gd:357`, from
`test_plasma_bonus_stays_off_a_live_npc_shield` at `:202`; proven pre-existing with the
wave's three files reverted at HEAD). **`--suite=<name>` matches the file basename**, so
`--suite=s2_6_burst` selects
nothing and prints `passed=0 failed=0` exit 0 — the working form is
`--suite=test_s2_6_burst`, which reads `passed=4 failed=0` (L95).

## §11 P2 ship frames (2026-09-21)

Pinned before any code worker starts, so five parallel workers agree. Additive only:
every §2/§3/§7 pin above stays valid.

```gdscript
## game/ship_fit.gd — additive beyond §3's pin.
const SLOT_GRIDS: Dictionary          # hull_id -> Array[String], 08 §3.2's rows, equal length
const SLOT_TOKEN_KEYS: Dictionary     # "E" -> &"engines", "P" -> &"power", "W" -> &"weapons",
                                      # "S" -> &"shields", "H" -> &"armour", "C" -> &"computers",
                                      # "B" -> &"boosters", "U" -> &"utility"; "." is a gap
const FIT_SLOT_KEYS: Array[StringName]      # [engines, weapons, shields, armour, computers, boosters, utility, power]
                                            # — the iteration/display order (rule 3 keeps `fitted_ids`' own order)
const MANDATORY_SLOT_KEYS: Array[StringName]  # [engines, power] — 09 §4.1
const ENGINE_MULT_CEILING := 1.40            # 09 §3.7
const MOUNT_SPREAD := Vector2(0.34, 0.22)    # 09 §8, hull half-extent fraction
const STANDARD_FITS: Dictionary              # hull_id -> 09 §9's fit

static func grid_rows(hull_id: StringName) -> Array           # [] for an unknown hull
static func grid_size(hull_id: StringName) -> Vector2i        # (cols, rows); ZERO when unknown
static func grid_cells(hull_id: StringName) -> Array          # row-major, gaps included:
    # [{type: StringName ("" for a gap), token: String, index: int (-1 for a gap),
    #   col: int, row: int, gap: bool}]
static func grid_counts(hull_id: StringName) -> Dictionary    # all 8 FIT_SLOT_KEYS present, 0 when absent
static func slot_capacity(hull_id: StringName, slot_key: StringName) -> int
static func fit_legal(hull_id: StringName, fit: Dictionary) -> Dictionary
    # {legal: bool, overflow: {slot_key: int}, missing: Array[StringName],
    #  duplicates: Array[StringName], power: {out, draw, spare, legal}}
static func standard_fit(hull_id: StringName) -> Dictionary   # {} for an unknown hull
static func mount_offset(hull_id: StringName, slot_key: StringName, index: int) -> Vector2
    # the cell's normalised hull-local anchor, Vector2.ZERO when the cell does not exist
```

Rules the pin fixes, so no worker has to choose:

0. **`SLOT_GRIDS` is 08 §3.2's block with the cosmetic spaces removed** (the
   Cutter's rows are `.WW.`, `HSCB`, `HWU.`, `.EP.`), and W1's suite parses that
   fenced block out of `docs/gameplay/08_ship_classes.md` and compares it with the
   constant, so the document and the data cannot drift apart. Nine hulls, rows of
   equal length, tokens from `SLOT_TOKEN_KEYS` plus `.`.

1. **Fit shape.** `engines`, `weapons`, `shields`, `armour`, `computers`,
   `boosters`, `utility` are `Array` of module id (`""` = empty cell); `power` is
   one module id. Index = 09 §4.5's layout index (row-major within the type).
2. **Legacy compatibility.** `resolve(hull_id, fit)` accepts the old singular
   `engine` key (a `StringName` **or** an `Array`) and `STANDARD_FIT` resolves
   unchanged; when both `engines` and `engine` are present, `engines` wins.
3. **Resolution order** (`fitted_ids`) stays: `weapons, shields, armour,
   computers, boosters, utility` — then `engines`, then `power`. Weapon-group
   order must not move.
4. **Engine math** (09 §3.7): `speed_mult = min(1 + Σ(m − 1), ENGINE_MULT_CEILING)`,
   `turn_mult = 1 + Σ(m − 1)` (no ceiling). Applied once, after armour, before
   booster-on-activation. A single engine resolves to exactly today's number.
5. **`HULLS[hull][&"weapons"]` must equal `grid_counts(hull)[&"weapons"]`** for all
   nine player hulls — one value, two readers (`game.gd:_target_name`, the panels).
6. **NPC hulls are not in `SLOT_GRIDS`** (`ship_swarmer`, `ship_sibur`,
   `ship_turret_platform`, `ship_boss_maw`, `ship_sibelon`, `ship_apex`,
   `ship_interceptor`, `ship_bomber`, `ship_drone_swarm`, `ship_mine_layer`):
   `grid_rows`/`grid_cells` return empty, `grid_counts` returns the 8 keys at 0,
   `slot_capacity` 0, `standard_fit` `{}` — **no `push_error`, no warning**. NPCs
   do not fit modules and `game.gd:944` reads `HULLS` for them.

```gdscript
## game/module_catalog.gd — new file, class_name ModuleCatalog extends RefCounted.
const MODULES: Dictionary   # id -> {name, slot, draw, tier, cost, icon, effects}
static func module(id: StringName) -> Dictionary     # {} for an unknown id
static func icon_path(id: StringName) -> String
static func slot_of(id: StringName) -> StringName     # &"" for an unknown id
```

`MODULES` copies each row's `slot`/`draw`/`effects` **verbatim** from
`ShipFit.MODULES` (no number is invented) and adds `name`, `tier`, `cost` from
09 §3's tables plus `icon` per the rule below. `ShipFit` reads effects and draws
through `ModuleCatalog` and keeps `ShipFit.MODULES` indexable exactly as it is
today (`ShipFit.MODULES[id][&"effects"]`, read by `game/player_ship.gd:672`,
`tests/test_engine_c3_flight_decay.gd:57`, `tests/test_combat_repair_c5.gd:294`
and `tests/probe_c3_flight_decay.gd:398`). The catalogue is the one literal; the
alias is a `const` referencing it. If the engine refuses that const reference,
keep the literal in `ShipFit.MODULES` and have `ModuleCatalog.MODULES` reference
*it* instead — either direction is fine as long as **exactly one literal exists**,
and W1's report states which direction shipped and why.

Icon rule: `assets/icons/module/icon_module_<id>_48.png` for every id except the
five base weapons, which use `assets/icons/weapon/icon_weapon_<family>_48.png`
(`w_laser`→`laser`, `w_cannon`→`cannon`, `w_rocket`→`rocket`, `w_mine`→`mine`,
`w_plasma`→`plasma`).

**D2 amendment (2026-09-22, icon unification — owner-ruled):** the icon rule above
keeps its shape but changes extension and loses the size suffix. Every id draws
`assets/icons/module/icon_module_<id>.svg` (hand-authored SVG master, one per
symbol, imported at 192 px) except the five base weapons at
`assets/icons/weapon/icon_weapon_<family>.svg`. The `_48.png` raster bands are
deleted project-side for the whole SVG-side set; `tests/test_ship_grids.gd`'s
two-way agreement assert carries the new shape. Reversal: re-point back to the
raster masters, which are preserved in `asset-library/cut/`
(`.agents/gen/slices/D2-icon-unification/phase_c_manifest.json`; the cut tree and
its `_archive` zips live on the Windows mirror).

Name table (pin it in the catalogue; the six lineage rows keep doc 09's own words):

| id | name | id | name | id | name |
|---|---|---|---|---|---|
| `w_laser` | Laser MkII | `s_light` | Light Shield | `b_afterburner` | Afterburner |
| `w_cannon` | Cannon MkI | `s_heavy` | Heavy Shield | `b_fold` | Fold Drive |
| `w_rocket` | Rocket Pod | `s_ion` | Ion Shield | `u_cargo` | Cargo Expansion |
| `w_mine` | Mine Layer | `h_plate_light` | Light Plate | `u_salvage` | Salvage Tractor |
| `w_plasma` | Plasma Coil | `h_plate_heavy` | Heavy Plate | `u_refine` | Refinery Module |
| `w_railgun` | Railgun | `h_composite` | Composite Plate | `u_drones` | Repair Drone Bay |
| `w_mining` | Mining Laser | `c_target` | Targeting Computer | `u_tractor` | Tractor Array |
| `e_std` | Standard Drive | `c_scanner` | Deep Scanner | `u_holds` | Cargo Holds |
| `e_ion` | Ion Drive | `c_twin` | Twin Targeting | `p_std` | Standard Reactor |
| `e_vector` | Vector Drive | `c_ewar` | EWAR Suite | `p_mk2` | Reactor Mk2 |
| | | `c_nexus` | Nexus Computer | `p_core` | Reactor Core |

```gdscript
## autoload/player_profile.gd — additive beyond §8's pins.
func fit_for(ship_id: StringName) -> Dictionary   # slot_key -> Array[String] ("" = empty),
    # every type at its hull capacity, tail padded; {} only for an unknown hull id
func set_fit(ship_id: StringName, fit: Dictionary) -> bool
func set_fit_slot(ship_id: StringName, slot_key: StringName, index: int, module_id: StringName) -> bool
func clear_fit(ship_id: StringName) -> void
func base_module_id(entry: StringName) -> StringName   # instance id -> base id; the entry itself when unknown
func module_count(module_id: StringName) -> int
func add_module(module_id: StringName, count: int = 1) -> void
func take_module(module_id: StringName, count: int = 1) -> bool
```

- **Normalisation:** a v1–v3 file stores one string per slot type; `fit_for`
  returns it as a one-element array (padded to capacity) and never rewrites the
  file at load. Writes always persist the array shape. `SAVE_VERSION` 3 → 4,
  `MIN_READABLE_VERSION` stays 1, v1–v3 load clean.
- **Keys:** `_fits` is keyed by `String(ship_id)` in the shipped shape and its
  per-slot keys may be `String` or `StringName` (a loaded `ConfigFile` gives
  `String`). `fit_for`/`set_fit`/`set_fit_slot`/`clear_fit` accept a `StringName`
  hull id and a `StringName` slot key, read both spellings, and write the same
  spelling the file already used — `ShipFit._list_slot`'s tolerance is the model.
- **Signals:** `profile_changed(&"fits")` on a fit write, `&"modules"` on an
  inventory write. Both keys already exist.
- `base_module_id` resolves through the existing `_modules` dict (15 §6 instance
  shape) and returns its argument when the dict has no such instance — today's
  tests and fixtures store base ids directly and must keep working.

```gdscript
## game/player_state.gd — additive beyond §8's pin.
var weapons: Array[StringName]                  # the launched fit's weapon ids, W-slot order
func set_weapons(ids: Array[StringName]) -> void  # sizes ammo/ammo_max to ids, emits weapon_changed per slot
```

`const WEAPONS` stays (the five-family default a `PlayerState` built without a fit
still runs on) and `weapons` starts as its copy. `setup()`, `set_ammo` and
`game.gd:_seed_ammo`/`_file_ammo_report` read `weapons`, never `WEAPONS`. Ammo
stays **per family**: two fitted lasers draw both slots from the `laser` pack.

```gdscript
## ui/hud/hud.gd — additive beyond §7's pins.
func set_hull_slots(hull_id: StringName, cells: Array) -> void
    # cells: [{slot: &"weapons", index: int, module: StringName, icon: String,
    #          fitted: bool, selectable: bool}] — one per W cell, layout order
func hull_slots() -> Array          # read-back for probes
```

The weapon grid is rebuilt from `cells`: `columns = mini(cells.size(), 5)` (a
7-cell capital wraps to two rows), a cell whose `module` is empty draws the slot
glyph `icon_slot_w` dimmed, a fitted cell draws the module icon, `selectable` is
false for indices ≥ `GROUPS_MAX` (5, the input map's `weapon_1..5`). `bind`,
`_on_weapon_changed` and the ammo label path are unchanged: `weapon_changed`'s
`weapon_id` is still a family id.

```gdscript
## ui/components/slot_button.gd — additive.
func configure_cell(variation: StringName, icon: Texture2D, cell: Vector2,
                    icon_token: StringName = TOKEN_INACTIVE) -> void
```

`configure`'s signature and behaviour do not change; `configure_cell` sets an
explicit cell size, `ignore_texture_size = true`, no number.

Panel contracts (station):

- `ui/station/shipyard_panel.gd`/`.tscn`: `%HardpointSlots` becomes a
  **`GridContainer`** (`columns` = `ShipFit.grid_size(hull).x`), rebuilt per
  selection from `ShipFit.grid_cells(hull)`: a gap is an empty 48×48 `Control`
  with no plate; a slot cell is a 48 px `SlotButtonWeapon` plate carrying the
  slot glyph, `disabled` (it is a display). Caption
  `SLOT LAYOUT · %d CELLS · %d ENGINES` (`_hardpoint_caption`; `CELLS` = the
  hull's slot count, 08 §3's Total — gaps are not cells). `STAT_ROWS`
  becomes `hull, shield, cargo, engines, slots` (labels `HULL`, `SHIELD`,
  `CARGO`, `ENGINES`, `SLOT CELLS`), and the list-row meta
  (`META_FORMAT`, `:165`) becomes `"%d HULL · %d SLOTS"`.
- `ui/station/launch_panel.gd`: `BRIEF_ROWS` becomes
  `destination, hull_name, hull, shield, engines, hardpoints, slots, cargo, ammo`
  (labels `ENGINES`, `HARDPOINTS`, `SLOT CELLS`); the cargo plate strip and its
  five plates do not change.

## §12 P2-B1 weapon fit (2026-09-22)

Pinned before the wave's code workers start, so they agree. Additive only: every
§2/§3/§7/§8/§11 pin above stays valid.

```gdscript
## autoload/player_profile.gd — additive beyond P2-A's §11 pin.
func buy_module(module_id: StringName, cost: int) -> bool
    # 17 §5: refuse when unknown/insufficient (purchase_failed), else spend(cost),
    # add_module(module_id, 1), profile_changed(&"modules"), one EconomyLog line
```

Consumer rules (the `STATION_HUB.md` §5.1 amendment — the same six bullets are the
surface's contract there; every number in them is 09 §3.1's):

- The pane gains a `MODULES` caption and seven weapon rows above the ammo packs,
  one per module in 09 §3.1's table order (`w_laser` 900 first, then `w_cannon`
  1 200, `w_rocket` 2 400, `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200,
  `w_mining` 600 — seven rows since the P2-B1 close-out: `w_mining` is 09 §4
  item 7's mining laser and the launch-fit gate's mining swap needs its door, so
  the brief's §1 list is the row set; reversal is one constant, `MODULE_ROWS`),
  each row: 48 px module icon, name, `W SLOT · DRAW n` meta, the 09 §3.1 effect
  text (09 §4 item 7's own words for `w_mining`), PRICE, STATUS, ACTION.
- STATUS: `FITTED (Wk)` when installed on the active hull, `OWNED ×n` in the
  inventory, `FOR SALE` when affordable, `LOCKED` otherwise.
- ACTION per state: `BUY` (buy_module) → `INSTALL` (first empty W cell; none
  empty → the row offers SWAP, the displaced module returns to inventory) →
  `SWAP` → `REMOVE`.
- Above the rows, a **FITTED WEAPONS** strip: one line per W cell of the active
  hull — `W1 LASER MKII` / `W2 — EMPTY` — each fitted line carrying REMOVE; the
  strip reads `ShipFit.grid_cells` + `PlayerProfile.fit_for` and never mutates
  directly (panels request, the profile mutates — STATION_HUB §12.4).
- Refusals render in the footer strip the panel already owns
  (`status_requested`), never a dialog.
- Focus order: the fitted strip first, then the module rows, then the ammo rows
  (Tab order, STATION_HUB §10).

Rules the pin fixes, so no worker has to choose:

1. **Refusals are the existing vocabulary.** `buy_module` reuses
   `purchase_failed`'s reasons (`&"unknown_id"`, `&"insufficient_credits"`;
   STATION_HUB §12.4's mappings) and the log line is `EVENT_BUY_MODULE` or the
   nearest shipped event id — one line per purchase, 17 §5's transaction law
   (verify → charge → pay → emit → log, integers only).
2. **The panel only requests.** Every install, swap and remove goes through
   `PlayerProfile`'s `set_fit_slot`/`clear_fit` and every buy through
   `buy_module`; the panel mutates nothing itself (STATION_HUB §12.4).
3. **Every install and swap passes `ShipFit.fit_legal`** (P2-A's §11 pin) and
   nothing auto-removes on an illegal fit.
4. **The mandatory set is untouchable from this surface** — no engine and no
   reactor row exists on it (09 §4.1, §7).
5. **The two refusal wordings** are `STATION_HUB.md` §5.1's: the power overload's
   `13 / 11 PWR — OVER BY 2` (09 §2's over-by format) and
   `W SLOTS FULL — SWAP OR REMOVE FIRST`.
6. **No flight-side change.** A swapped weapon mounts as the new one on the next
   launch, because the launch already resolves the hull's fit; in-space refitting
   does not exist in v1 (09 §4.8).

## §13 P2-B proper fitting (2026-09-22)

Pinned before the wave's code workers start, so they agree. Additive only: every
§2/§3/§7/§8/§11/§12 pin above stays valid.

```gdscript
## autoload/player_profile.gd — additive beyond §12's pin.
const SAVE_VERSION := 5              # was 4; a v4 file still reads (MIN_READABLE_VERSION 1)
const LEGACY_UPGRADE_MODULES: Dictionary = {          # the six-row retirement table, 09's own
    &"upgrade_generator": &"p_mk2",   &"upgrade_shield": &"s_heavy",
    &"upgrade_engine":    &"e_ion",   &"upgrade_module": &"c_scanner",
    &"upgrade_extra":     &"u_cargo", &"upgrade_drone":  &"u_drones",
}
const EVENT_FIT_MODULE := "FIT_MODULE"   # the fitting transaction's own log id

func fit_module_at(ship_id: StringName, slot_key: StringName, index: int,
                   module_id: StringName) -> bool
    # The composed install. Refuses (false, no write) when: the hull is not one of
    # the nine; the slot key is not in FitData.FIT_SLOT_KEYS; the index is outside
    # 0 .. slot_capacity-1; module_count(module_id) == 0; or the candidate fit fails
    # ShipFit.fit_legal — the candidate being resolved_fit(ship_id) with that one
    # cell set to module_id (resolved_fit, below, is the fit the launch would fly,
    # so the pane's preview and this commit read one shape — R1's MED-1, cured by
    # F1 2026-09-22). On success, in this order: the displaced module (when the
    # cell was non-empty) returns with add_module; take_module(module_id, 1);
    # set_fit_slot(ship_id, slot_key, index, module_id); one Log.append(EVENT_FIT_MODULE,
    # module_id, 1, 0, credits) line; profile_changed(&"fits") and (&"modules").
func resolved_fit(ship_id: StringName) -> Dictionary
    # The fit the launch would fly: fit_for(ship_id) when that fit holds any module
    # at all, else ShipFit.standard_fit(ship_id) (game.gd's own launch fallback);
    # {} for an NPC hull, exactly as fit_for answers. The panes read it for display
    # and the two composed transactions use it as their candidate.
func clear_fit_slot(ship_id: StringName, slot_key: StringName, index: int) -> bool
    # The composed remove. Same guards, plus: a key in FitData.MANDATORY_SLOT_KEYS is
    # always refused (09 §4.1's mandatory set is never empty). The candidate is
    # resolved_fit(ship_id) with the cell emptied. The cell's module returns to
    # the inventory with add_module; the cell is written &""; one log line
    # (EVENT_FIT_MODULE with a negative qty is not used — use the module id, qty 1,
    # delta 0 and let the caller's footer carry the words); emits both keys.
func retire_legacy_upgrades() -> int
    # The v5 migration step, idempotent. For every id in the `upgrades` record whose
    # value is true: add_module(LEGACY_UPGRADE_MODULES[id], 1) and drop the record.
    # Returns how many were migrated (0 on a v5 file). Called from the load path when
    # the file's save_version < 5, after the record is read.
```

Rules the pin fixes, so no worker has to choose:

1. **The mandatory-key list is not re-declared.** `FitData.MANDATORY_SLOT_KEYS`
   (`game/ship_fit.gd:117`, `[&"engines", &"power"]`) is the one source, exactly as
   `FitData.FIT_SLOT_KEYS` already is at `player_profile.gd:456`.
2. **The migration is a one-way door.** A v4 file with all six upgrades installed loads as
   six inventory modules (one each) and no upgrade records; a v5 file has no `upgrades`
   record at all. `has_upgrade` / `installed_upgrades` / `install_upgrade` and the
   `upgrades` key are **removed** from the profile; a v1–v3 file still loads (it never had
   the key). Fixture: the wave's own test builds a v4 file with all six set and asserts the
   six modules afterwards and `retire_legacy_upgrades() == 0` on the second call.
3. **`fit_module_at` never half-writes.** Every refusal precedes every write; the
   displacement happens before the take, so a swap can never lose the displaced module.
4. **`clear_fit` stays as it is** (whole-fit reset, used by the seed and tests);
   `clear_fit_slot` is the pane's per-cell remove.
5. **The pane never mutates directly** (STATION_HUB §12.4): panels request, the profile
   mutates. The pane may only call the two composed APIs, `resolved_fit`, `fit_for`,
   `module_count`, `modules`, `ShipFit.*` and `Repairs.*`.
6. **Legality is previewed, not enforced twice.** The pane calls `ShipFit.fit_legal` on the
   candidate fit to colour the power meter and to gate the ACTION; the profile re-checks on
   commit. Both read the same function.

(The brief's rule list carries one duplicated "2."; §13 numbers the six rules 1–6 in reading
order with no text change.)

Consumer rules (the `STATION_HUB.md` §5.3 amendment — the same bullets are the surface's
contract there; every number in them is 08 §3.2's, 09 §8's or section 5.1's own):

- **Rail:** `Module.UPGRADES` becomes `Module.FITTING`; the label becomes `FITTING`; the
  entry keeps the retired entry's rail position, its icon path and its tint. The retired
  `ui/station/upgrades_panel.gd` and `.tscn` are deleted; nothing else in the rail moves.
- **Anatomy** — the §5.1 host-pane construct, two stacked sections:
  - **SLOT LAYOUT** — the active hull's grid, **the shipyard's own recipe** (`ShipFit.grid_cells`,
    `SlotButtonWeapon` 48 px plates, gaps as empty `Control`s, the type's slot glyph, the
    caption `SLOT LAYOUT · <n> CELLS · <m> ENGINES`). Unlike the shipyard's display, these
    cells are **selectable**: one selected at a time, `FOCUS_ALL`, the selected cell carrying
    the theme's focus ring; a cell's identity is its `slot_key` + `index` (09 §4.5's layout
    index). The recipe is shared with the shipyard (lift it into a helper both panes call, or
    duplicate it byte-equivalently) — the reviewer checks both grids render identically.
  - **OWNED MODULES** — one row per owned module **id** (aggregated by id), ordered by
    `ShipFit.FIT_SLOT_KEYS` then catalogue order: 48 px module icon, name, the meta
    `SLOT <TYPE> · DRAW <n>`, `OWNED ×<n>`, and ACTION.
- **ACTION per state:** `FIT` when a cell of the module's own type is selected and the
  module is legal there (calls `fit_module_at`); `SWAP` when that cell already holds another
  module (same call — the displaced one returns to the inventory); `SELECT A CELL`
  (disabled) when no cell is selected or the module's type has no selected cell.
- **The power meter** (footer strip, always visible): idle `PWR <Σ draws> / <out + power module>`;
  with a cell selected, the candidate's own line `PWR <Σ> / <out> · CANDIDATE <Σ'> / <out>`;
  when the candidate is over budget the same line renders in the danger colour and ends
  `— OVER BY <n>`. The numbers are `fit_legal`'s own `power` dictionary.
- **Hover / selection info (owner request 1):** the selected cell's line reads
  `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`; the shipyard's plates gain the same line
  on hover (`shipyard_panel.gd`), reading the selected hull's `fit_for` entry.
- **Refusals** (footer strip, never a dialog): `13 / 11 PWR — OVER BY 2` (09 §2's own
  format, already pinned), `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` (new this pass),
  and `REFUSED · FIT ILLEGAL` as the catch-all for a fit illegal for any other reason
  (L77's guard, now named here as the third pinned refusal). The footer is never blank.
- **Focus order:** the SLOT LAYOUT cells first (row-major), then the OWNED MODULES rows,
  then the pane's own footer, then the rail (STATION_HUB §10).
- **Empty states:** an account that owns no modules shows one disabled row
  `NO MODULES OWNED · BUY THEM IN OUTFITTING`; a hull with every cell filled and nothing
  selected shows the meter and the grid, no refusal.

LAUNCH's service rows (the `STATION_HUB.md` §5.4 amendment — owner request 4):

- §5.4's DECK CONTROL gains `REFUEL` and `RECHARGE` actions for the active hull, calling
  `Repairs.refuel(profile, active_ship)` / `Repairs.recharge(profile, active_ship)` and
  rendering the service's own result in the pane's status line (`fuel_max` / `energy_max`
  on success; the service's refusal reason otherwise). Free and instant — **no price column,
  no credits move** (14 §1's rate; `FREE_FEE` is 0).
- Already-full and no-damage-report states are the service's refusals, rendered, never
  hidden — the button stays pressable and the footer says why.

## §14 S2.6 truth-and-feel (2026-09-22)

- **Gate hermeticity (L90/L93).** `tests/headless_runner.gd` redirects the profile
  store to `user://_gate_scratch/profile.cfg` at runner boot **and** (a) creates the
  directory first (`DirAccess.make_dir_recursive_absolute` — `ConfigFile.save` into a
  missing dir fails `err=7` and `PlayerProfile._write_profile` silently drops the
  write), (b) resets the **in-memory** profile after repointing (`reset_to_defaults()`
  — the autoload loaded the live file before the runner's `_ready`), and (c) seeds a
  deterministic default profile. The four live-coupled tests (`test_engine2_dock.gd`
  ×2, `test_engine2_fixes.gd` ×1, `test_engine2_wiring.gd` ×1) build their own
  fixtures (their own fit with the weapons they name, or expectations derived from
  the launched fit) **and guard the slot index** (`_slot()` may answer −1 and
  GDScript's negative indexing silently reads the last pack). Acceptance (the
  load-bearing half): two consecutive gate runs with a mutated live profile present
  both read `passed=<total> failed=0` with identical counts; the live file's md5
  unchanged is a **secondary** check (measured: the file is rewritten — mtime moves —
  but content-identical). The sandbox is harness-side and host-independent.
- **Fragment burst** — `AsteroidField._cleave` (**the field** owns the fragments'
  spawn placement and velocity) adds `FRAGMENT_OUTWARD_KICK := 150.0` u/s: a
  fragment's velocity is §5's shape (`eject_velocity()` = `linear_velocity × 1.2`,
  uniform 360° roll) **plus** `FRAGMENT_OUTWARD_KICK` along the outward radial
  (rock centre → spawn point — exactly the placement direction `_cleave` already
  computes), so slow and stationary rocks burst visibly (owner: "when breaking
  asteroids they should move when exploding"). §5's `eject_velocity()` comment
  stays true as the shape's half; the radial lives beside the placement.
  Reversal: `0.0` = today exactly.
- **Beam feel** — `BEAM_SINK := 0.45` and `HIT_FX_JITTER_MULT := 0.35` (FX_SPEC
  §1.6's amendment): drawn beam lines end at `hit_point.lerp(body_centre, 0.45)`
  and contact FX scatter in a disc of `clamp(0.35 × collision radius, 8, 48) u`
  around the resolved hit. **The radius object:** rocks answer `world_radius()`
  (measured 24/42/66 u → jitter 8.4/14.7/23.1), hulls their
  `CollisionShape2D.radius` (30 u → 10.5); a destructible projectile has no radius
  and the 8 u floor binds there. The 48 u ceiling is inert for every shipped object.
  **The jitter readers are exactly three:** `spawn_chip_sparks` (weapon beams), the
  mining chip read closing L65 (`mining_laser.gd` beside `_play_chip`, the wiring
  `weapons.gd:641` already has), and `spawn_shield_ripple` — a beam on a bare hull
  spawns no sheet today and none is added. Reversal: both `0.0`.
- **Flight feel (owner rulings 2026-09-22 — four items riding this wave as R4/R5).**
  The HANDLING derivation in `game/ship_fit.gd` (today bare literals of the §13
  column) gains the multiplier pattern: `ACCEL_TIME_MULT := 2.0` on `accel_time`
  (a hull takes roughly double the time to reach 90 % of `max_speed`; owner: "the
  acceleration is too fast for ship, it shouldn't reach top speed that quickly")
  and `COAST_TIME_MULT := 2.0` on **today's** `coast_time` rows — the documented
  revert of the combat wave's ×0.50 drag retune, landing exactly on §13's own
  column (owner: "ship loses speed way too fast"). The revert is **forward-only**:
  lateral decay keeps today's time constant (`LATERAL_DAMP_MULT := 1.0` of today,
  applied as an explicit lateral drag), because the lateral damp *is* the outward
  skid in a turn (owner: "inertia works weird, like ship slides in one side") —
  forward carry grows, sideways slide does not. **Steering is throttle-independent**
  (`STEER_WITHOUT_THROTTLE := true`): the nose follows the cursor at zero throttle
  and a turn input applies torque only, so a 360° turn at rest displaces the hull ≤
  `TURN_TRANSLATE_LEAK_MAX := 5.0` u (owner: "when ship is pause trying to turn
  around moves it way too much forward, a ship in space should somewhat be able to
  do neutral turn"). This **supersedes §4's "the nose follows the cursor while
  `thrust_forward` is held, and the heading holds when it is not"** (reversal: the
  W-gate, one condition). AC6 is measured on the **cursor route at zero throttle**,
  never on a synthetic `turn_left` press (that route is torque-only today and would
  pass before any fix). Mirrored maneuvers must produce mirrored trajectories
  within 1 %. **Disclosure:** the two multipliers reach every NPC hull through
  `ShipStats` — NPCs accelerate slower and carry further; no NPC file is edited and
  `test_engine2_npc.gd` is where it may show. Reversals: the multipliers `1.0`;
  the bounds are bounds only.

## §15 S3 item economy — instances and the AUCTION (2026-09-22)

**Amended v0.7.3 (2026-09-22, the S3 docs pass — K0's seven HIGH findings).** The
first draft pinned seven functions and left the record, the shelf store, the buy
price, the fitted-instance round trip and the affix route undecided; every gap is
now a pinned value, a pinned shape, or a stated deferral, each with its reversal
(15 §9 carries the exclusive rows and the content numbers). **A worker implements
this text; only the developer session changes it.**

```gdscript
# PlayerProfile — additive. The §13 transactions keep their signatures and accept
# instance ids where they accepted module ids; only their bodies change.
const INSTANCE_ID_FORMAT := "mod_%04d"
add_instance(base_id: StringName, rarity: StringName, prefixes: Array, suffixes: Array) -> StringName
instance(id: StringName) -> Dictionary      # the record below; {} when absent
instances_of(base_id: StringName) -> Array  # ids held in the bag (count 1), creation order
roll_instance(base_id: StringName, source: StringName) -> StringName  # 15 §2/§9's tables, rolls + adds
roll_listing(base_id: StringName, source: StringName) -> Dictionary  # the shelf's mint: rolls + mints an id, does NOT enter the bag
buy_instance(id: StringName, cost: int) -> bool   # the shelf's listing, at the price it shows
sell_instance(id: StringName) -> bool             # base × rarity multiplier × 60 %
take_instance(id: StringName) -> bool             # 1 -> 0: fitting; the record survives
restore_instance(id: StringName) -> bool          # 0 -> 1: REMOVE/SWAP hands the same instance back
auction() -> Dictionary
set_auction(state: Dictionary) -> void
SAVE_VERSION := 6
```

- **The record** is `{instance_id, base_id, rarity, prefixes[], suffixes[], count}`
  under `modules: instance_id -> record` — 17 §3's shape, which is 15 §8's with the
  `count` every consumer already reads. `count` is **1 while the instance sits in
  the bag and 0 while it is fitted**; the record is never erased (15 §6's "never
  destroyed"), so `instance(id)` still answers a fitted module's affixes and
  `restore_instance` puts the *same* instance back (L80's cure). A `count`-0 record
  is invisible to `instances_of`, to every `OWNED ×<n>` aggregate and to
  `sell_instance`, which settles H4 and H5 without moving a §13 signature.
- **The two new keys.** `instance_counter: int` (mints `mod_%04d`, one per profile:
  every roll — inventory, drop, shelf listing — takes the next number) and the
  shelf, `auction: {last_band: int, hulls: Array[String], modules: Dictionary,
  hot: StringName}`, are top-level `[profile]` keys added to `_read_values` and to
  `_write_profile`'s fixed list. The shelf is **not** a `market` sub-key:
  `_normalise_market` rebuilds that dictionary from `MARKET_KEYS` and would drop a
  stranger on load.
- **The shelf.** `auction.modules` holds the 10 module **listings** as ordinary
  instance records keyed by their minted id (the rolled name and price are visible
  on the shelf — 15 §8's "hunting the good roll"); `auction.hulls` holds the 6 hull
  ids and `auction.hot` the one discounted listing id. `buy_instance(id, cost)`
  charges the price the row shows and **moves** the record from the shelf into
  `modules` at `count: 1`; the hull side stays `buy_ship(id, cost)`. A restock
  draws a fresh shelf and discards the unbought listings (their ids are spent, the
  counter never rewinds).
- **Prices.** `base × 15 §1's rarity multiplier`, the hot slot's −20 % applied
  after, exactly as STATION_HUB §5.10 renders it; no catalogue cost moves. Every
  09/15 cost is a multiple of 100, so ×1.6/×2.6/×60 % need no rounding rule. Sell
  is `base × rarity × 60 %` with **no suffix term** (15 §6 verbatim).
- **Affixes are stored, named, priced and displayed in S3; applying them to flight
  stats is not.** The pin's own arithmetic is base-id: a fit cell stores the
  `instance_id` and `resolved_fit` / `fit_legal` read through
  `instance()[&"base_id"]`. So the composed transactions and the three panels
  translate cells through `base_module_id` **before** judging a fit, which is what
  stops `fit_legal` scoring an instance as draw 0 (K0 H6). 15 §7's two-line stat
  block (base stats + one affix line each) is K3's display surface. The
  affix-application wave — `game.gd`'s fit→flight bridge and the weapon-stat
  families (`weapons.gd`/`ship_stats.gd`) — is **staged, owner tick**; it is the
  reason no S3 worker set contains those files.
- **The F lot.** `AUCTION_FACTION_LOTS_INTERIM := true`: one listing per shelf is
  one of 15 §5's three exclusives, rolled at its Magic+ floor with the two legal
  rarities split **85 % Magic / 15 % Rare** (15 §2's own 30:5 auction ratio
  renormalised over the two rarities that are legal for an exclusive), carrying the
  `F LOT` tag. The exclusives' catalogue rows — which did not exist anywhere before
  this pass — are 15 §9.
- **The restock footer** renders `NEXT RESTOCK <m:ss>` from `WorldClock.now()` and
  `BAND_SECONDS` **at pane entry**; the clock has no remaining-time accessor and
  its own header forbids a per-consumer Timer, so the line is a reading, not a
  countdown.
- **Refusals** gain no wording (§13's three + 09 §2's `<n> NEEDED`), but the AUCTION
  owns its footer strip the way FITTING does: the shell's `station.gd` copy prices
  by catalogue id and would read `0 NEEDED` for an instance.
- **Save v6 migration:** each v5 `{base_id, count}` record becomes `count` **Common**
  instances, idempotently (the P2-B flag-day pattern). Reversal: restore the v5
  saver; v6→v5 is lossy (collapses to base ids, drops affixes).
- **OUTFITTING's seven weapon rows retire** (10 §2.4) and `test_ship_grids.gd`'s
  32-row catalogue assertions grow with 15 §9's three rows. `PlayerProfile.buy_module`
  and `ModuleCatalog` (§12) remain the price source and the migration table's home
  and gain no new UI callers.
- **The rotation's home is `game/auction.gd`** (`class_name Auction`), added by the wave
  and recorded here after K4's review (it was missing from this block — the same bucket-2
  gap as `roll_listing`, LOW-14/`L120`): `evaluate_shelf` (lazy, `WorldClock.bands_between`),
  `draw_shelf`/`draw_tier`/`tier_pool`/`exclusive_ids`, `hull_rows`/`listing_rows`/`sell_rows`,
  `buy_hull`/`buy_listing`/`sell_row`, `hot_price`/`sell_price`/`meta_of`/`rolled_name`/
  `rarity_token`/`rarity_fallback` and `next_restock_seconds`/`restock_text`. It mirrors
  `game/exchange.gd`'s split (statics over a profile's state, prices only from
  `ModuleCatalog`) and **owns no state of its own** — the shelf lives in the profile's
  `auction` key. `Auction.rolled_name` is the single 15 §7 name builder; FITTING and the
  shipyard call it rather than carrying a second grammar. Reversal: inline the statics into
  the panel.

## §16 S4 weapon batteries (2026-09-22)

```gdscript
# PlayerProfile — bulk wrappers over the §13 composed transactions. Loops over
# cells; a failed cell rolls the batch back to its starting fit.
fit_battery(ship_id: StringName, base_id: StringName, indices: Array) -> bool
clear_battery(ship_id: StringName, base_id: StringName) -> bool
# WeaponComponent — the volley seam
fitted() -> Array                 # unchanged, per barrel
battery(base_id: StringName) -> Array   # this battery's W indices
```

- Battery = identical instances across W cells grouped by `base_id` (09 §10); the
  fit shape is unchanged (§13 — one instance per cell). One trigger per battery:
  one round per barrel, per-barrel damage, `BATTERY_STRUM_MS := 40` per-barrel
  release offset (reversal 0 = simultaneous).

## §10 Changelog

- **v0 (2026-09-18)** — seeded from the engine wave-1 pinned interfaces
  (the wave-1 reports were consolidated into `.agents/gen/MASTER_REPORT.md`
  on 2026-09-21) +
  `docs/gameplay/18_engine_spec.md`
  §2/§3/§7/§9/§13. Slices 2–4 (combat,
  travel, integration) append their sections here at their review gates.
- **v0.1 (2026-09-21, engine slice 0 review — M4, the wave's only CONTRACTS
  writer)** — added §8.1 (slice 0's pinned additions: `hull_mass`, the energy/fuel
  pools, `try_spend_energy`/`try_spend_fuel`/`consume_fuel_cell`, the `Impact`
  helpers, `Repairs.refuel`/`recharge`, fuel persistence and save v3) and the
  `consume_fuel_cell` row in §1; extended §2 (the four new `ShipStats` fields), §4
  (`HullBody` is a `RigidBody2D`, the defaulted `fit_ids`, the four additive push
  seams, the reactor chain's hull-side contract), §5 (`Asteroid extends
  RigidBody2D`, `setup`'s defaulted `size_class`, the new read-only queries, the
  cleaving and rock-body contract), §7 (`set_pool`/`set_emergency`) and §8
  (services, fuel persistence, the pool push). §9's expected count is corrected
  from a stale `passed=53` to the suite's real **78** tests, with the review's
  measured `77/1` and its cause recorded next to it.
- **Two owner rulings of 2026-09-21, recorded here so no later wave re-litigates
  them:** (1) **refuel and recharge are FREE and instant station services**; the
  refuel CR rate is not a spec number and **no worker may invent one** (the ruling
  is also in `docs/gameplay/14_station_services.md` §1 and
  `docs/design/IMPLEMENTATION_PLAN.md` §9.9; the superseded "CR per fuel point"
  wording still standing inside the owner-locked `18_engine_spec.md` §4.4/§12
  item 8 is a documentation defect for the next owner-gated spec pass, not a
  licence to charge). (2) **the graphics lane owns `vajb-orbit/assets/**` and its
  naming re-layout is mid-flight**: a failure that is only a missing or moved asset
  path is environment-deferred until the designer ships, is **not** a code finding,
  and no fixer may sweep asset paths outside its own file set.
- **Reviewer-pinned hooks (not new numbers, spec-derived):** the hull's
  `_physics_process` calls `PlayerState.tick(delta)` and the afterburner burns
  `BOOST_FUEL` through `try_spend_fuel`, with `emergency_mode` gating throttle and
  boost — rulings 11/14 as §4.4 states them. Measured unwired on 2026-09-21
  (M4 findings F2–F4); the fixer pass owns them in `game/player_ship.gd`.
- **v0.1.1 (2026-09-21, engine slice 0 re-review — M6)** — records the fixer pass's
  outcome against the pins above. §1's `consume_fuel_cell` row moves to **R** (owner
  ruling R3; §11's C is superseded, `cargo_toggle` keeps C) and its measured note
  now reads the three landed bindings and the hull-side caller; §4's reactor-chain
  note carries the before/after measurements instead of "not wired yet"; §8.1 names
  `PlayerShip` as the single owner of `BOOST_FUEL`/`DASH_FUEL`; §9's expected gate
  is the measured `passed=78 failed=0`. **No pinned signature changed** — the fixes
  are additive (`_thrust_locked`, `_step_reactor`, `_update_fuel_cell`,
  `_burn_boost_fuel` and the two consts are private/new surface; `setup`,
  `set_move_target`, `cancel_orders`, `warp_available` and every `PlayerState`
  signature are untouched), and the one test edit is the save-version digit.
- **v1 (2026-09-21, engine slice 2 review — W6, the wave's only CONTRACTS writer)** —
  added **§8.2** (the whole slice-2 interface: `WeaponComponent`/`FAMILIES`,
  `Projectile.configure` and its seams, `Damage`'s two doors and three push helpers,
  `NpcShip`/`NpcBrain`/`NpcRegistry`, `LootTables`, the wiring consts and the four
  standing owner rulings), extended **§1** (the two unbound countermeasure actions),
  **§7** (the HUD's slice-2 API, the payload's `in_range`/`threat`, the read-backs,
  the two theme fallbacks, the two unmet §10/§3.3 minimap items) and **§9** (the gate
  total is the **measured 200**, with the six new `engine2_*` suites broken out and
  the `preload`-vs-`load()` probe trap recorded). **No pinned signature changed and no
  frozen method was removed** — the wave is additive on every file it touched
  (`git diff --stat e2ab64d`: `game.gd` +900, `hud.gd` +463, `sector.gd` +143,
  `player_ship.gd` +136, `player_state.gd` +21 insertions; `hud.tscn` and
  `project.godot` byte-identical), and the one test edit of the slice-0 era stands.
  **One HIGH is open and pinned here rather than left implicit:** no weapon damages a
  real ship, because a hull's collider is its bare `HullBody` and neither `_deliver`
  resolves an owner. The four **values this wave had to choose** (mine alpha 180,
  kinetic cadence 0.6 s, projectile mass 1.0, hit radius 4.0, plus the chaff drift and
  the flare's "while something chases it" lifetime) are recorded in §8.2 as unpinned
  and two of them (mine alpha, kinetic cadence) are player-facing balance numbers
  awaiting an owner tick. Full evidence and every other finding:
  `.agents/gen/slice2_review_report.md`; LOW items: `.agents/gen/_state/LOW_BACKLOG.md`
  L19–L29.
- **v1.1 (2026-09-21, engine slice 2 re-review — W8, this wave's only CONTRACTS
  writer)** — records the fixer pass's outcome and the state the wave closes in.
  **§1**: the two countermeasure actions move from *unbound* to **applied (Z / X)**, with
  the measured 20-action map, the keycode checks (C is `cargo_toggle`, not the fuel cell)
  and the three live key events that reached their spends written next to them. **§7**:
  the §3.3 ghost flicker and the §10 `&"swarmer"` sub-kind move from *not implemented* to
  **implemented**, with the theme-token and flicker-curve readings and the note that no
  registry row pushes `&"swarmer"` yet. **§8.2**: the four standing rulings gain **R5**
  (Z/X are the shipped countermeasure keys) and **R6** (the mine's 180 alpha and the
  kinetics' 0.6 s cadence are accepted spec numbers, not invented constants); the open
  HIGH is replaced by its **closed** record with the re-measured figures (laser 800 → 770,
  bolt 1250 → 1223, mine 180 control, plasma 70 / 87.5), and the one finding the re-review
  leaves open is pinned beside it: `_file_ammo_report` is **not idempotent within one
  launch** (300 → 297 → 294, reachable through `_request_dock`'s missing re-entry guard
  around `Router.route()`'s 0.2 s fade; cure: `_ammo_seed[weapon_id] = live` after the
  write, or a `_docking` flag). **§9**: the expected total is the **measured 217** with
  `engine2_fixes` (17) broken out, and the `preload`/autoload trap gains its third and
  fourth forms (`Router` in `game.gd`, and the fact that a `--script` run cannot drive
  `Input`'s action state at all). **No pinned signature changed and no frozen method was
  removed** — the fixer's three edits are additive (`_sink_for` private in each delivery
  file, the before-shield-rule sink in `_beam_apply`, `PlayerProfile.set_ammo` a new
  writer, the minimap's two kinds) and `hud.tscn`, `project.godot`, the theme and
  `addons/` are untouched. Every one of W6's findings is accounted for: F1 verified fixed
  by the reviewer's own probe (`ok=126 failed=0`) and W8's independent probe, F2 and F4 by
  W8's probe, F3/F5–F11 recorded where W6 left them (F9 and F11 are now closed by the doc
  pass: 06's prose reads 2.15 / 28.375 / 11.83 %, 2.30, 1.50 and 6.375 with the 1025 floor
  and the 1584.75 mean, and `11_galactic_map.md` §3 cites `18_engine_spec §13`). Evidence:
  the probe and boot-gate logs behind this entry were consolidated into
  `.agents/gen/MASTER_REPORT.md` (2026-09-21 cleanup); the surviving reports are
  `.agents/gen/slice2_review_report.md` and `.agents/gen/slice2_w8_report.md`;
  the fixer's own record is `.agents/gen/slice2_w7_report.md`.
- **v1.2 (2026-09-21, combat/collision repair wave — C7, this wave's only CONTRACTS
  writer)** — records the wave, its one retune and the four contradictions the C6
  review found in this file (`.agents/gen/combat_repair_c6_report.md` §9, finding
  MED-2; the changelog itself was backlog **L37**). **The wave** (brief
  `.agents/gen/combat_repair_wave_task.md`; owner rulings of 2026-09-21, both rounds):
  a rock is now damageable. `Asteroid` carries **layer 1 / mask 2** (the mask names the
  *hull* layer, so the rock's mass enters a ship contact while `mask & layer == 0`
  still keeps two rocks apart — the pre-wave `mask 0` was C1's measured defect, not a
  guarantee), and it implements `apply_collision_damage(amount)` (the §4 ram name,
  now reachable: C1 measures the rock's half at `v_peak 72.821`, `pos_delta 20.323`
  against `0.000 / 0.000` before). A shot or a ram chips a rock through
  `WeaponComponent.GUN_CHIP_RATE` 0.10, the single owner; the owner's second-round
  re-scope rejected a second damage→work constant, so **no new feel number was
  invented** and the only constant the game-side diff adds is the layer bit. `NpcShip`
  gains the `shield_up() -> bool` reader the weapon side already consumed, which fixes
  plasma landing its +25 % on live shields (measured `87.500` on a 600-shield hull
  before, the family's own `70.000` after). **No pinned signature was renamed,
  retyped, reordered or removed** — the whole `vajb-orbit/game/` diff adds four
  definitions (`COLLISION_MASK := 2`, the `weapons.gd` preload, `apply_collision_damage`,
  `shield_up`). **The one retune:** `coast_time` ×0.50 on all nine `ShipFit.HANDLING`
  rows (owner ruling; second-round ruling 3 specifies it), measured on the shipped
  launch as `t10 1.890 → 0.945 s` and carry `430.32 → 216.85 u` with both accelerate
  legs unchanged; it also halves every NPC hull's coast and doubles its damp through
  `ShipStats` (inside the ruling's "all nine rows"), and ruling 3's "≈ 108 u" carry is
  2× low — measured 216.85 u. **§13 is not ticked:** the spec still carries the
  pre-retune column, and both its tick and the new chaff/kinetic feel numbers remain
  the owner's. **The four corrections** the C6 review required, all in this entry's
  wave: §4's body pin said "nothing retuned" and now records the exception with its
  evidence; §5's rock body pin said "layer 1 / mask 0" and now reads **layer 1 /
  mask 2**; §8.2's `NpcShip` list was missing `shield_up() -> bool`; §9's expected
  gate said `passed=226` and now reads the measured **236** with the wave's 10 tests
  broken out. Evidence: `.agents/gen/combat_repair_c6_report.md` (the review) and
  `.agents/gen/combat_repair_c{1,2,3,5}_report.md`, with every raw log under
  `.agents/gen/c6/`; the wave's LOW block is `.agents/gen/_state/LOW_BACKLOG.md` L38–L47.
- **v1.3 (2026-09-21, flight-feel & beam wave — its review pass: G4's review plus this
  G5 fixer, the wave's only CONTRACTS writer)** — records the four shipped behaviours
  the wave left undocumented (review finding **MED-1**,
  `.agents/gen/flight_beam_g4_report.md` §11) and clears the three shadowing sites its
  own new files added (**MED-2**, same report §9). **The wave** (brief
  `.agents/gen/flight_beam_wave_task.md`; owner rulings of 2026-09-21, third round,
  evidence `.agents/gen/owner_playtest_findings_20260921.md`; worker reports
  `.agents/gen/flight_beam_g{1,2,3}_report.md`). **§4** now pins the shipped control
  scheme and the two new handling behaviours with G4's measurements: W/S throttle,
  **A/D strafe** (keycodes 65/68 bound; `turn_left`/`turn_right` keep their actions
  and their slots with `"events": []`, so a pad axis or a Controls-tab re-bind still
  turns), **the nose follows the cursor while `thrust_forward` is held and the heading
  holds when it is not** (`_manual_desired_turn` answers a deflected turn action
  first, then `_aim_turn` — the autopilot's own arrive steering — then `0.0`; the peak
  turn rate equals the class rate to three decimals on all three launched cases and a
  released stick leaves drift `0.00000000`), **the strafe derived from §13's own two
  rows** (`max_speed` + `accel_time` through `_accel_rate`; the one named constant G1
  proposed, `STRAFE_FRACTION`, is **not** in the tree), and the **`turn_rate` ×0.50
  retune** with its nine-row before/after table — the project's second retuned §13
  column after `coast_time`, and the same shape: it reaches every NPC hull through
  `ShipStats`. §4's additive API gains the `set_aim_point`/`clear_aim_point` probe
  seam. **§8.2**'s two stale parameter-name pins are corrected to the shipped truth
  (`set_fitted(ids)`, `retarget(lure)`; the G4 report's list also named
  `feedback_row(name)` and `spawn_sheet(parent, name)`, which this file never pinned,
  so those two had nothing to correct). **§9**'s expected gate moves to the measured
  **294** with the wave's 17 tests broken out, its HEAD A/B (`277`) recorded beside
  it, the pre-existing `tests/test_weapon_fx_f4.gd:176` `SCRIPT ERROR` named rather
  than assumed away, and the warning ledger's before/after counts added. **No pinned
  signature was renamed or removed and no frozen method was dropped** — the whole
  `vajb-orbit/` diff is additive (`weapons.gd` +3 definitions, `projectile.gd` +1,
  `player_ship.gd` +11, `REBINDABLE_ACTIONS` 17 → 19 with nothing dropped); `FAMILIES`,
  `IMPACT_CUES`, every weapon scalar, `ShipFit.HANDLING`'s other five columns,
  `project.godot`, the theme and `addons/` are byte-identical to HEAD. The wave's one
  pre-existing test edit is `tests/test_combat_repair_c5.gd:288` (`turn_rate` 3.0 →
  1.5, with the ruling named inline) and every other column of that test is still
  pinned. Evidence: `.agents/gen/flight_beam_g4_report.md` (the review) and
  `.agents/gen/flight_beam_g5_report.md` (the fixer pass, with every before/after
  command); the wave's LOW block is `.agents/gen/_state/LOW_BACKLOG.md` L48–L61.
- **Owner tick list this v1.3 entry defers** (every file below is owner-locked, so no
  worker may edit it — these are spec-side leftovers, recorded here only):
  1. `docs/gameplay/18_engine_spec.md:67` reads `**A/D** turn.`; the shipped map is
     **A/D strafe**, so §3.1's line needs the owner's amendment to match §4 above.
  2. `docs/gameplay/18_engine_spec.md:389` — §11's "Everything else stays:
     thrust/turn/fire/boost/mine/cargo/weapon_1..5/Q" bullet still names `turn` as a
     bound control and does not mention the two strafe actions. (§11's
     `consume_fuel_cell` = C is separately superseded by ruling R3, already recorded
     in §1.)
  3. `docs/gameplay/18_engine_spec.md` §13's handling table — the `turn_rate` column
     still carries the pre-retune values (the before/after table is §4 above). The
     same tick is still owed for `coast_time` from the combat/collision repair wave,
     and **S2.6's two multipliers ride the same pass**: §13's `accel_time` and
     `coast_time` columns are the *literals* the wave's `ACCEL_TIME_MULT`/`COAST_TIME_MULT`
     multiply (§14), so an owner ticking the resolved values should tick the two
     constants with them. One §13 pass closes all four.
  4. `docs/design/IMPLEMENTATION_PLAN.md:231` — the frozen input-map row reads
     `turn_left` (A) · `turn_right` (D); the shipped truth is `strafe_left` (A) ·
     `strafe_right` (D), and the two entries sit at positions 5 and 6 of
     `REBINDABLE_ACTIONS`. (LOW-1: `settings_manager.gd:34-36`'s "Orders 18 and 19"
     comment says the same thing wrongly and is a comment-only fix.)
- **v0.2 (2026-09-21, P2-A slot-frames wave — D0, the wave's only CONTRACTS writer)** —
  added **§11** above (the P2 ship frames pin), transcribed verbatim from
  `.agents/gen/p2a_slot_frames_wave_task.md` §3: `ShipFit`'s `SLOT_GRIDS`,
  `SLOT_TOKEN_KEYS`, `FIT_SLOT_KEYS`, `MANDATORY_SLOT_KEYS`,
  `ENGINE_MULT_CEILING` 1.40, `MOUNT_SPREAD` (0.34, 0.22), `STANDARD_FITS`,
  `grid_rows`/`grid_size`/`grid_cells`/`grid_counts`/`slot_capacity`/`fit_legal`/
  `standard_fit`/`mount_offset`; the new `ModuleCatalog` (32 rows + the name table +
  the icon rule); `PlayerProfile`'s `fit_for`/`set_fit`/`set_fit_slot`/`clear_fit`/
  `base_module_id`/`module_count`/`add_module`/`take_module`; `PlayerState`'s
  `weapons`/`set_weapons`; the HUD's `set_hull_slots`/`hull_slots`; and
  `SlotButton.configure_cell`, plus the two station panel contracts. **No pinned
  signature changed and no frozen method was dropped** — the wave is additive on
  every file it touches: `resolve` keeps accepting the legacy singular `engine` key
  (`engines` wins when both are present), `fitted_ids`' order still starts with
  `weapons`, `STANDARD_FIT` resolves unchanged, and `HULLS`/`HANDLING` stay valid.
  **Every number in §11 is transcribed** — 08 §3/§3.1/§3.2's counts, bands and
  matrices, 09 §1–§9's slot types, power rules, engine arithmetic, fit rules,
  resolution order, deliveries and per-hull standard fits, 09 §3.7's 1.40 ceiling,
  09 §8's one `MOUNT_SPREAD` pair — and this wave adds none. **Pinned tests that
  move (both named in the brief's §5, nothing else):** `tests/test_ui_slot_layout.gd`'s
  three pinned sections (the shipyard strip and the HUD's weapon cells are read from
  the selected or active hull's matrix through `ShipFit`, so `HARDPOINT_CELLS := 7`
  and the five-cell HUD count stop being literals) and `tests/test_p1_profile.gd:204`
  (`save_version` 3 → 4, `MIN_READABLE_VERSION` stays 1). **§9's expected total is
  the gate's own measured figure with zero failures** — this entry records no
  carried-forward count, because the wave's own suites are what move it; this pass
  measured the pre-wave tree on 2026-09-21 as `passed=311 failed=0`, exit 0, with
  the one pre-existing `tests/test_weapon_fx_f4.gd:176` `SCRIPT ERROR` (§9, L61)
  still in place, and that is the baseline the wave's suites grow from. The three
  items this wave defers: `weapon_6`/`weapon_7` in the input map (an owner
  `project.godot` edit, so a 7-W hull's cells 6–7 ship `selectable: false`),
  mount-anchor consumption in flight (the feel wave's; the data and
  `ShipFit.mount_offset` land here) and the fitting panel itself (wave P2-B).
  Evidence: `.agents/gen/p2a_d0_report.md` (this doc pass) plus the wave's worker
  reports `p2a_w{1,2,3,4,5}_report.md`, the review `.agents/gen/p2a_r1_report.md`
  and the brief `.agents/gen/p2a_slot_frames_wave_task.md`.
- **v1.4 (2026-09-22, rock-cleave wave — its review A2, whose authored text the
  wave's fixer A3 landed)** — the owner's 2026-09-21 asteroid ruling ("asteroid
  breaking effects (they should somehow explode, random fragments from 2 to 5 moving
  in random directions)") is now what **§5** states, closing the review's one MED
  (`.agents/gen/rock_cleave_a2_report.md` §6). §5's cleaving sentence was three
  clauses out of date: it still read the retired fixed split rows and the retired
  ejection cone, and it was silent about the break read the ruling adds. It now reads
  the shipped constants with their shipped values — `FRAGMENT_SPLIT` a **uniform**
  2–5 on both cleaving tiers, ejection `× 1.2` in a **uniform 360°** direction, and
  every depletion (a cleave, a Small's burst or a yield-0 crack) also drawing FX_SPEC
  §1.4's explosion at the rock's own centre scaled `clamp(1.2 × diameter, 96, 224) u`,
  playing S4's rock cue through the new four-take `sfx_impact_rock` `CUE_POOLS` row, and
  applying `Impact.apply_shockwave` on the bodies inside
  `I(d) ≥ MIN_SHOCKWAVE_IMPULSE` — and it names the two reversals (the constants
  themselves: the fixed rows, or a `15.0` cone). **No pinned signature changed**: the
  fix is one paragraph of §5 plus this entry, and `vajb-orbit/` is untouched by it. The
  wave's gate is the measured `passed=378 failed=0`, exit 0, on a pre-wave tree
  measured at **372** — the whole growth is `test_engine2_cleaving` 9 → 15, which is
  A1's and not this pass's. The retired cleaving rows in the owner-locked
  `docs/gameplay/18_engine_spec.md` §6/§13/**§15** stay the owner's tick. Evidence:
  `.agents/gen/rock_cleave_a3_report.md` (this fix, with every before/after command)
  and the re-runnable guard `.agents/gen/rock_cleave_a3_check.sh` — 12 checks proving
  the retired statements are gone and every value §5 now names equals the constant its
  owner declares.
- **v0.3 (2026-09-22, P2-B1 weapon-fit wave — D0, the wave's only CONTRACTS writer)** —
  added **§12** above (the P2-B1 weapon-fit pin), transcribed from
  `.agents/gen/p2b1_weapon_fit_wave_task.md` §3: `PlayerProfile.buy_module(module_id,
  cost)` and the six consumer rules (the MODULES rows in 09 §3.1's table order with their
  frozen costs and `W SLOT · DRAW n` meta, the STATUS and ACTION state machine, the
  `FITTED WEAPONS` strip, the refusals in the panel's own footer strip, and the focus
  order), plus six rules the pin fixes and the note that both refusal wordings live in
  `STATION_HUB.md` §5.1. **The six consumer bullets are byte-for-byte the brief's, in both
  §12 and `STATION_HUB.md` §5.1** (the brief's own parenthetical says §5.1 is the surface's
  amendment and this section is the pin, so the same text is the pin's copy of the
  surface's contract); §5.1 additionally gains the FITTED WEAPONS/MODULES amendment block,
  the brief's two refusal wordings (`13 / 11 PWR — OVER BY 2` — 09 §2's over-by format —
  and `W SLOTS FULL — SWAP OR REMOVE FIRST`), its §2 payload line and §7.1's art-map row
  for the module icons. `docs/gameplay/10_ship_acquisition.md` §6 and
  `docs/gameplay/09_ship_slots_modules.md` §4.8 gain the dated interim note: OUTFITTING
  sells the six weapon modules until the AUCTION module of 10 §2 exists, and those rows
  retire into it then (10 §5's precedent for the legacy upgrade rows). **No pinned
  signature changed and no frozen method was dropped** — this pass is `docs/**` only, and
  W1/W2's additive code follows the pin. **No number is this pass's:** every cost (900,
  1 200, 2 400, 1 800, 4 800, 5 200, 600), every draw, both refusal wordings and the row
  order are 09 §3.1's (600 being 09 §4 item 7's `w_mining` cost) or the brief's
  transcription of them. **§9's expected total is the wave's own to move** (W1/W2 add
  tests, R1 measures it): this pass measured the pre-wave tree on 2026-09-22 as
  `passed=378 failed=0`, exit 0 — the same figure rock cleave closed at — and records no
  post-wave count. **Resolved at the P2-B1 close-out (R1's MED-2, closed by F1):**
  §3's first bullet says "six weapon rows" and then lists **seven** ids (`w_laser` 900,
  `w_cannon` 1 200, `w_rocket` 2 400, `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200,
  `w_mining` 600), while 09 §3.1's table has six rows and `w_mining` is 09 §4 item 7; the
  brief's §1 names a different six for the shop (`w_cannon`, `w_mining`, `w_rocket`,
  `w_mine`, `w_plasma`, `w_railgun`). The row set shipped as **seven** — the six of
  09 §3.1 plus `w_mining` — because the wave's own §1 deliverable names `w_mining` 600
  purchasable and the launch-fit gate's mining swap (symptom 2) needs the door; W2 had
  shipped the §3 reading, R1 tiered it MED-2, F1 landed the seventh row (reversal: drop
  the id from `MODULE_ROWS`). Evidence: `.agents/gen/p2b1_d0_report.md` (the verbatim
  proof and the line index), `.agents/gen/p2b1_r1_report.md` (MED-2) and
  `.agents/gen/p2b1_f1_report.md` (the fix, with before/after).
- **v0.4 (2026-09-22, P2-B1 close-out — the orchestrator's review-wave merge)** — closes the
  wave's two MED findings and records the contract as shipped. **MED-1** (R1): an unaffordable
  module purchase rendered `REFUSED · NOT ENOUGH CREDITS · 0 NEEDED` because
  `ui/screens/station.gd`'s `_entry`/`_entry_cost` chain resolved only the ammo packs, the
  ships and the upgrades; F1 added `ModuleCatalog.module(id)` as the fourth link, so a module
  refusal now names its catalogue cost (`5 200 NEEDED` for `w_railgun`) with no new string.
  **MED-2** (R1): the MODULES row set is **seven** — 09 §3.1's six plus `w_mining` (09 §4
  item 7's 600) — so the mining laser, the launch-fit gate's symptom 2, has a door; §12's row
  bullet above and `STATION_HUB.md` §5.1 carry seven, and the reversal is one constant
  (`MODULE_ROWS`). The wave's measured gate is **389** (378 → 387 → 389) and §9 above carries
  that figure. **No pinned signature changed** — R1's own audit tools
  (`vajb-orbit/tools/r1_p2b1_signature_audit.py`, `r1_p2b1_format_law.py`) re-measured after F1:
  25 signatures, drift 0; 21 byte checks, 0 failures. Findings left open and parked:
  `.agents/gen/_state/LOW_BACKLOG.md` L76–L84 (the pane's stale subtitle/tag, the third refusal
  wording, the ACTION precedence tick, the seam's price trust, the base-id hand-back, the
  `set_fit` seed, probe housekeeping and the 48/40 px icon tension; plus D0's two stale
  cross-references).
- **v0.5 (2026-09-22, P2-B proper fitting wave — D0, the wave's only CONTRACTS writer)** —
  added **§13** above, transcribed from `.agents/gen/p2b_proper_wave_task.md` §3:
  `SAVE_VERSION` 5, `LEGACY_UPGRADE_MODULES` (the six-row retirement table),
  `EVENT_FIT_MODULE`, `fit_module_at`, `clear_fit_slot`, `retire_legacy_upgrades`, the six
  rules, §3.2's pane contract and §3.3's LAUNCH service rows. It also records the wave's
  surface work in the docs it owns: `STATION_HUB.md` §5.3 is rewritten as **FITTING** (§3.2
  verbatim, the rail swap, the retirement and its reversal), §5.4 gains the `REFUEL` /
  `RECHARGE` rows (§3.3), §5.2 gains the plates' hover line, §7.1 records the reused icon,
  and the retired surface's references are cleared out of sections 1–12; `09_ship_slots_modules.md`
  §4 gains items 9–13 (the composed install and remove, the never-emptied mandatory cell,
  legality previewed and re-checked, the pane's request-only rule, the legacy retirement),
  §7 names **FITTING** as the fitting surface, and §4 item 8's interim note points at it;
  `10_ship_acquisition.md` §6's interim note names FITTING as the install surface beside
  OUTFITTING's shop; `15_module_affixes.md` §6 gains the dated note that affixes are the
  **next** wave and this one's fitting inventory aggregates by id. **Two drifts recorded
  rather than invented:** the wave prompts name a `FIT_MANDATORY_KEYS` constant, which
  §13's rule 1 verbatim resolves (the mandatory-key list is **not** re-declared;
  `FitData.MANDATORY_SLOT_KEYS`, `game/ship_fit.gd:117`, is the one source) — no such
  constant is pinned here and none may ship; and the brief's rule list carries one
  duplicated "2.", so §13 numbers the six rules 1–6 in reading order with no text change.
  **No pinned signature changed and no frozen method was dropped** — this pass is `docs/**`
  only, W1/W2/W3's additive code follows §13. **No number is this pass's:** every cost,
  draw, capacity, cell count and refusal wording is 09's, 08 §3.2's, 12's, the pin's own or
  the brief's transcription of them. **§9's expected total is the wave's own to move**
  (R1 measures the final count after the worker suites land; the close-out writes it into
  §9): the pre-wave gate stands at the P2-B1 close-out's recorded **389**
  (`passed=389 failed=0`, the gate 389 commit `1f794cc` §9 records), and this documentation
  pass records no post-wave count of its own.
  Evidence: `.agents/gen/p2b_proper_d0_report.md` (this pass, with the exact line per
  pinned item) plus the brief `.agents/gen/p2b_proper_wave_task.md`.
- **v0.6 (2026-09-22, P2-B proper close-out — the orchestrator's review-wave merge)** —
  corrects §13 to the reviewed code and closes the wave's two MED findings. R1 left no HIGH
  and two MED; F1 cured both: **MED-1** (§13's candidate sentence, above) now reads
  `resolved_fit(ship_id)`, the fit the launch would fly, so the pane's preview and the
  profile's commit agree on a hull with no stored fit — `resolved_fit` is added to the pin
  and to rule 5's allowed-call list; **MED-2** was one line in the pane (a refusal's footer
  line no longer outlives the successful action that follows it) and needs no pin text.
  §9 above carries the wave's measured **437** (389 → 402 → 420 → 431 → 437). Findings left
  open and parked: `.agents/gen/_state/LOW_BACKLOG.md` L85–L92 (the module's-slot-type check, the
  empty-cell remove refusal, the retired Phase C mockup's own UPGRADES rows, the signature
  audit's two-line blind spot, 09 §3.8's generator-lineage sentence, three data-dependent
  test assumptions against a live profile, the nondeterministic exit-time leak lines and the
  carried-forward harness items), plus F1's measured residual (a bare hull's delivered
  mandatory cell still offers REMOVE and refuses with the pinned wording — W2's disclosed
  reading, ticked at the close-out).
- **v0.7 (2026-09-22, designer planning pass for S2.6 / S3 / S4 — landed docs-first
  ahead of the waves)** — added **§14** (gate hermeticity: the runner sandboxes the
  profile store and the four live-coupled engine2 tests build their own fixtures;
  `FRAGMENT_OUTWARD_KICK 150.0`; `BEAM_SINK 0.45` / `HIT_FX_JITTER_MULT 0.35`, with
  L65 closing in the same pass), **§15** (the instance record `mod_%04d`, save v6 and
  its Common-migration, the roll timing, the AUCTION surface and its faction-lot
  interim) and **§16** (weapon batteries: N barrels keep N W mounts, one row and one
  trigger per battery, `BATTERY_STRUM_MS 40`). Every number's reversal is in its
  section; the owner tick list is the wave briefs' owner-ticks section. §9's measured
  figure stays **437** (green on a sandboxed `user://` 2026-09-22; the 433/4 against
  the live save is L93 — the gate is not hermetic until §14 lands).
- **v0.7.1 (2026-09-22, same planning pass — the owner's four flight rulings)** —
  §14 gains the flight-feel block (`ACCEL_TIME_MULT 2.0`, `COAST_TIME_MULT 2.0`
  reverting the combat wave's drag retune onto §13's own column, the neutral-turn
  leak bound `TURN_TRANSLATE_LEAK_MAX 5.0 u`, the mirror-symmetry acceptance) and
  FX_SPEC §5 gains the blur exclusion (the player hull stays sharp). All four ride
  wave S2.6 as builders R4/R5; the owner-locked §13 tick list grows by the two
  multipliers.
- **v0.7.2 (2026-09-22, S2.6 truth-and-feel review — R6, this wave's only CONTRACTS
  writer)** — records the measured pass: **§9's expected figure moves 437 → 455/2**
  (457 tests over 40 suites; the two rows the hit-FX jitter moved are named, with
  `passed=457 failed=0` as the post-fix reading), the gate's **hermeticity is measured
  three times on the real `user://` path with the owner's live account byte-identical
  and `mtime`-unmoved**, the per-suite census is replaced with the log's own, and the
  `--suite=` basename trap (L95) is written down. §4's stale `coast_time` sentences,
  its two reversal wordings and the `thrust_forward`-gated steering sentence are
  re-pointed at §14's constants (**`turn_rate` keeps a literal reversal — it has no
  multiplier; the two reversals are not one**), the strafe `t_90` rows are re-derived
  (2.283/1.900/5.683 → 4.550/3.783/11.350 s) and the two observability seams
  (`applied_force()`/`applied_torque()`) are recorded as additive. §5's
  `eject_velocity()` comment now says it is the shape's half, with the field's
  `FRAGMENT_OUTWARD_KICK` as the radial, and the additive measurement is quoted.
  Every number here was re-measured by R6 — the five builders' probes re-run
  byte-identically, the GPU blur probe re-run (`HULL_EXCLUDED max=0.000000
  HULL_CONTROL max=1.000000 background mean=0.029085`), and
  `staging/verify_wave.py verify --baseline s26_start --forbidden
  vajb-orbit/project.godot` clean on frozen files (no `project.godot`,
  `18_engine_spec.md`, `08_ship_slots_modules.md`, `assets/`, `addons/` or theme file
  moved). Findings: `.agents/gen/slices/S2.6-truth-and-feel/S2.6-R6_review.md`;
  LOW rows `L94`+ in `.agents/gen/_state/LOW_BACKLOG.md`.
- **v0.7.3 (2026-09-22, the S3 item-economy docs pass — the developer session,
  answering K0's seven HIGH findings before any builder ran)** — **§15 is re-pinned**
  (the record gains `count` with the 1-in-the-bag/0-fitted meaning, the two new
  top-level keys `instance_counter`/`auction` with the shelf's shape, the buy price
  parameter, `take_instance`/`restore_instance` as the fitted-instance round trip,
  and the "affixes are displayed in S3, applied in a staged wave" rule that keeps
  every S3 worker set free of `game.gd`/`weapons.gd`). **§9's expected figure moves
  455/2 → 457/0** (the S2.6 fixer pass landed; measured twice this pass on a scratch
  store, `passed=457 failed=0` exit 0, the pre-existing L61 `SCRIPT ERROR` now
  printing at `test_weapon_fx_f4.gd:178`). The content numbers the auction cannot
  work without — the three faction exclusives' catalogue rows, the F lot's 85/15
  Magic/Rare split, and the ten suffixes' "stored and displayed, not yet applied"
  rule — live in `15_module_affixes.md` §9, dated and reversed there. No base price,
  roll weight or §3.1 stat moved; `project.godot`, `18_engine_spec.md`, `assets/`
  and `addons/` are untouched by this pass. Findings: `.agents/gen/slices/S3-
  module-affixes/S3-K0_report.md`.
- **v0.7.4 (2026-09-23, the S3 item-economy review — S3-K4, this wave's only
  CONTRACTS writer)** — **§9's expected figure moves 457/0 → 491/0** (measured twice
  this pass on the hermetic runner, `passed=491 failed=0` exit 0, 43 suites; the wave's
  growth is `457 → 471 → 482 → 491`, and the single `SCRIPT ERROR` in the log is still
  L61's line at `tests/test_weapon_fx_f4.gd:178`). **Measured notes for §15's
  implementers, none of them a pin change:** (1) the shipped profile surface is §15's
  block **plus `roll_listing(base_id, source) -> Dictionary`**, the shelf's mint — a
  listing is rolled and priced on the shelf without entering the bag, and the counter
  moves for it (CONTRACTS §15's own "every roll … takes the next number"); §15's block
  lists no such member and `game/auction.gd` has no pinned surface, so **adding either
  to §15 is bucket 2 — the developer session's**, recorded here instead of edited
  there. (2) `instances_of`'s "creation order" is the **store's key order**, which a
  `user://` ConfigFile round trip sorts ascending (measured: a nested Dictionary written
  `[w_laser, u_refine, s_light, mod_0001]` reads back `[mod_0001, s_light, u_refine,
  w_laser]`, while Arrays keep their order) — the two orders coincide below
  `mod_10000`, so the mint-order reading holds for every account this wave can make.
  (3) The AUCTION's three `rarity_*` theme tokens (`rarity_common` = the default label
  colour, `rarity_magic` `#565C63`, `rarity_rare` `#E8703A`) are the wave's only theme
  change and `STATION_HUB.md` §8 carries them. (4) No base price, roll weight,
  multiplier or 09 §3.1 stat moved: `module_catalog.gd` gained 444 lines and lost three
  comment lines since `ff2375c`, and `project.godot`, `18_engine_spec.md`,
  `09/12/14`, `assets/`, `addons/` and `game/ship_fit.gd` are byte-identical to that
  commit. (5) The wave's one HIGH (OUTFITTING's FITTED WEAPONS strip REMOVE destroys a
  fitted instance and duplicates its base unit — measured; the fix is the composed
  `clear_fit_slot`) and its per-criterion verdicts are
  `.agents/gen/slices/S3-module-affixes/S3-K4_review.md`; the new LOW rows are `L107`+
  in `.agents/gen/_state/LOW_BACKLOG.md`.
- **v0.7.5 (2026-09-23, the S3 fixer pass — S3-K5, the wave's second CONTRACTS writer)** —
  **§9's expected figure moves 491/0 → 493/0** (measured twice this pass with §9's own
  canonical command, `passed=493 failed=0` exit 0, the live `profile.cfg` md5
  `9182b34f…` byte-identical before and after both runs). The pass fixed the review's one
  HIGH at its named site and nothing else: `ui/station/outfitting_panel.gd:664`
  `remove_module` now calls the composed `PlayerProfile.clear_fit_slot(hull, WEAPON_SLOT,
  index)` in place of its raw `set_fit_slot(…, &"")` + `add_module(base_id, 1)`, so the
  FITTED WEAPONS strip's REMOVE banks the entry the cell holds as itself — `_bank_entry` →
  `restore_instance` for a fitted instance (CONTRACTS §15's "never destroyed, never
  duplicated"), `add_module` for a base-keyed cell, exactly as before. **No §15 member, no
  §13 signature, no price, no roll weight and no 09 §3.1 stat moved**, no affix reaches a
  flight stat, and the review's "no MED" stands: its LOW rows are untouched by this pass.
  Two regression tests were added at the defect's own surface
  (`tests/test_p2b1_outfitting_panel.gd:662` the fitted instance comes back as itself with
  its rarity and affix rows; `:703` a base-keyed unit of the same base is not incremented),
  both **red on the pre-fix panel** and green after it (measured: `passed=9 failed=2` on
  the pre-fix file, `passed=11 failed=0` on the fixed one). Report:
  `.agents/gen/slices/S3-module-affixes/S3-K5_report.md`.
