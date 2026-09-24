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
booster_cooldown_mult: float = 1.0          # §20 (S7): Spry's aggregate, 1.0 unfitted
```

`hull_mass` and the three pool fields are the engine slice 0 additions (§8.1).
Field order follows §9's list: `hull_mass` after `turn_spinup`, the pools after
`cargo_max`. No pre-slice-0 field moved, was retyped or was reordered — verified
by review probe A against the §13 table row by row.

## §3 ShipFit — `class_name ShipFit extends RefCounted`, `game/ship_fit.gd`

```gdscript
static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats
    # §20 (S7) adds ONE optional third parameter: affixes: Dictionary = {}.
    # Every existing caller stays valid and byte-identical with {} or no third
    # argument; §11 rule 2's two-argument reading below is the pre-S7 form.
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

Expected (S7, 2026-09-24): **`[SUMMARY] passed=753 failed=0`**, exit 0. The S7 review
(S7-R1) measured **753** twice on two fresh scratch stores (identical counts) plus once
inside `staging/verify_wave.py verify --baseline s7_start … --tests`, which reads
`problems: []` with **no forbidden hit at all**; the live store's pair
`profile.cfg` md5 `b10c3f568b4e9767394291e97c154e36` / `economy_log.txt` md5
`13a2517626897c7e7babafcc7e39a923` was byte-identical before and after a full run (its
13:37 rewrite predates the review and is not this wave's — no S7 run touches the live
path). **Growth `711 → 753`**: the `s7_start` snapshot (`faa24ad`) carried **711** rows
(S6's 674 + D7's in-flight 37, measured by counting `test_*` methods in a worktree at
that commit), D7's wave-boundary close-out added **1** more (`test_d6_status.gd` 16 → 17,
measured by a per-suite count diff — D7's row, attributed, never absorbed), and the
wave's three suites add **41** (`test_s7_affixes.gd` **15** K1 → 727,
`test_s7_weapon_affixes.gd` **19** K2 → 746, `test_s7_suffixes.gd` **7** K3 → 753). No
pre-existing suite's count moved; the one existing-test edit is the ratified
`test_s3_instances.gd` Ledger fixture (§20's test-law block). The green run's one
`SCRIPT ERROR` is L61's pre-existing `test_weapon_fx_f4.gd:178`.
Previous expected (D7, 2026-09-24): **`[SUMMARY] passed=727 failed=0`**, exit 0. The D7
fixer measured **727** twice on two fresh scratch stores (identical row sets).
Growth **608 → 674** (S6) **→ 727** = +18 `test_d7_cockpit.gd` + 8
`test_d7_status.gd` + 11 `test_d7_armory.gd` + the §3.1b bars row renamed and
extended + S7's `test_s7_affixes.gd` rows landing in parallel (+15 at F1's
measure). The live `profile.cfg` md5 `b32fdb7b9c68e132e76d0771660f916b` is stable
across every close-out run (its 11:49 rewrite is D7-C2's recorded station-shell
screenshot flush, `economy_log.txt` byte-identical). Cross-lane caveat: the
close-out runs with S7's **uncommitted** `game/` mid-edit state in the tree read
`passed=740 failed=5` twice, identical — all five are S7's (four
`test_s7_weapon_affixes.gd` rows + `test_weapon_fx_f1.gd`'s round-robin row
through their `weapons.gd`/`projectile.gd` edits), zero in D7's write set; S7's
close-out re-measures on its settled tree.
Previous expected (S6, 2026-09-24): **`[SUMMARY] passed=674 failed=0`**, exit 0. The S6 review
(S6-R1) measured **674** four times on four scratch stores, identical counts, with the
live `user://profile.cfg` md5 `06f5660a4f884c5d799311287721f78f` and
`economy_log.txt` md5 `ca40fe2c0ab3bd0f2047723a2d737d9a` unmoved. **674 tests over
53 suites** (608 + 66): `test_s6_travel.gd` **18**, `test_s6_poi_loot.gd` **25**,
`test_s6_heat.gd` **23**; the three S6-related pre-existing suites hold at
`test_engine2_loot.gd` **13**, `test_engine2_npc.gd` **28**, `test_p1_profile.gd`
**11**. Measured history: K1 **626** (608 + 18, with `test_engine2_wiring.gd`'s one
derived minimap-feed row corrected), K2 **651** (+25), K3 **674** (+23). The green
run's error lines are the pre-existing ones (the detached-hull `data.tree` line below,
L61's `test_weapon_fx_f4.gd:178` freed `guns`, and the benign 12-resources-at-exit
warning). **Cross-lane caveat:** `staging/verify_wave.py verify --baseline s6_start
--forbidden vajb-orbit/project.godot …` exits 1 on that one hit, which is **D6's**
`ef0e06f` `ship_status` write landed after the `s6_start` snapshot, not an S6 edit
(LOW row `L157`).
Previous expected (D6, 2026-09-24): **`[SUMMARY] passed=608 failed=0`**, exit 0. The D6
close-out measured **608** twice on two scratch stores, identical counts, with the
live `user://profile.cfg` md5 `03203d60ff2f4a66479121b1708faf8a` and the
`_gate_scratch` copy `c674ff4694186b981035294482c6bf99` unmoved. **608 tests over
51 suites** (578 + 30): `test_d6_cluster.gd` **14** and `test_d6_status.gd` **16**
(M2's 15 + F1's damaged-branch marker test). Measured history: M1 **592** (578 +
14), M2 **607** four runs, M1b **607** twice (the owner's 4-digit SPD amendment
swapped test rows, no count change), R1 **607** three runs before the fixer, F1
**608** twice (R1-MED-1's cure adds the 16th status test). Cross-lane caveat (not
D6's write set): later runs against the tree while the S6 builders' uncommitted
`game/` edits advanced read **607/1** and one hard fail at the pre-existing L61
leak lines (`test_weapon_fx_f4.gd:178`'s freed `guns`,
`test_slice2_5_feel.gd:203`'s freed tween) — S6's close-out re-measures on its
settled tree.
Previous expected (S5, 2026-09-24): **`[SUMMARY] passed=578 failed=0`**, exit 0. S5-R1 measured **577**
three times on three scratch stores before the fixer pass; the close-out measured **578** four
times on four scratch stores (R1's figure **+1** — the row F1's R1-MED-2 cure added), identical
counts; **578 tests over 49 suites**, the live `user://profile.cfg` md5 `539de5b7af59c77b6bffc477413161da` unmoved. The four S5
suites are `test_s5_commerce.gd` **7**, `test_s5_ammo_cargo.gd` **14**, `test_s5_batteries_v2.gd`
**12** and `test_s5_hardpoints.gd` **11** (44 new), with `test_engine2_weapons.gd` 44 → **48**,
`test_s4_batteries.gd` 16 → **19**, `test_p2b1_outfitting_panel.gd` 11 → **13** and
`test_p2b_services.gd` 12 → **14**. The green run's error lines are the pre-existing ones
(L61's `test_weapon_fx_f4.gd:178`, the detached-hull `data.tree` line below, and
`test_p1_clock_log.gd`'s own unwritable-path backtrace).
Previous expected (S4): **`[SUMMARY] passed=524 failed=0`**, exit 0 (measured **twice** on 2026-09-23 by the S4
fixer pass — S4-H4 — with the canonical command below, identical both runs; **524 tests over 44
suites**, with the live `user://` byte-identical before and after both runs: `profile.cfg` md5
`3e6ee8d7e7145c4e37bbd8dc90f62f9b`, `economy_log.txt` md5
`eef2929404d1b3b2a4f30565e7b183b2`). The S4 review's own five-run reading was **521** with the live
pair untouched either (S4-H3; §10's v0.8.1), and H4's fix clears the HIGH that reading was blocked
on, so the figure above is the wave's. **S4's growth is `493 → 508 → 521 → 524`**: H1's battery
suite (`test_s4_batteries.gd`, **15** new) and H2's volley (`test_engine2_weapons.gd` **29 → 42**),
with `test_p2b1_outfitting_panel.gd` (**11**, its per-cell strip tests re-read as battery rows)
and `test_engine2_wiring.gd` (**13**, its `fitted()` assertion rewritten per barrel with a bite
check) unchanged in count; H4's fix then added `test_engine2_weapons.gd` **42 → 44** (the held
pull's stream, and the mine's one release per pull) and `test_s4_batteries.gd` **15 → 16** (a
refused bulk action leaves no stored fit). The S4 evidence lines that vary run to run are the
strum's own (`[s4-weapons] volley: releases at […]; ceiling 40, pack 30 -> 27`) — the per-barrel
offsets are drawn from `WeaponComponent._strum_rng` per pull (measured spans 5–27 ms inside the
40 ms ceiling, the lead barrel on the pull's own frame) — and, since H4, the held pull's
(`[s4-weapons] held pull: 15 shots = 5 windows x 3 barrels, releases at […] frames`, stable
across five runs); every other S4 evidence line re-runs byte-identically (`[s4-batteries] mixed
fit rows=["battery w_laser [0, 2]", "battery w_cannon [1]"]`, `overload line=11 / 8 PWR — OVER BY
3`, `fixed strip: 7 rows, 253 nodes (36 per row)`).
The S4 review's verdict was **blocked** on a sustained trigger firing one salvo and then nothing
for every travelling family, contradicting §16 rule 4's own sentence (`.agents/gen/slices/
S4-weapon-batteries/S4-H3_review.md` F1); **H4's fix clears it**, and the fix's own reading is
§10's v0.8.2 (a 3.0 s pull: **15** shots, five three-barrel salvos, where the review measured
**3**). Before it, S3's close-out read
**`passed=493 failed=0`** (measured twice on 2026-09-23 by the
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
   unchanged; when both `engines` and `engine` are present, `engines` wins. §20 (S7)
   adds the optional third `affixes` parameter — the two-argument form above is
   unchanged, and no caller of either arity breaks.
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
                                     # §15 raised it to 6 (autoload/player_profile.gd:54 — the
                                     # tree's live value, measured 2026-09-23); this block keeps
                                     # the digit §13 shipped and is not the number to build against.
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

## §16 S4 weapon batteries (2026-09-22, rewritten 2026-09-23 as v0.8.0)

**Amended 2026-09-23 by the developer session before the wave's builders started.** H0's
drift check (`slices/S4-weapon-batteries/S4-H0_report.md` F1–F9) measured that the v0.7.4
seal could not be built as written: it called `fitted()` "unchanged, **per barrel**" while
`set_fitted` drops duplicates (`game/weapons.gd:369`) and `tick` fires one weapon (`:520`);
it asked `battery()` for "W indices" from a component that is handed a flat id list with no
cell indices; it assumed a per-barrel ammo slot where the tree has **one pack per family**
(`game/player_state.gd:84-89`); and it left the batch's pairing rule, rollback scope and
refusal copy unnamed. The rules below answer all four; each carries its reversal. No new
gameplay number is introduced — `BATTERY_STRUM_MS := 40` and the barrel-count law are 09 §10's.

```gdscript
# PlayerProfile — bulk wrappers over the §13 composed transactions (autoload/player_profile.gd)
fit_battery(ship_id: StringName, base_id: StringName, indices: Array) -> bool
clear_battery(ship_id: StringName, base_id: StringName) -> bool
# WeaponComponent — the volley seam (game/weapons.gd)
const BATTERY_STRUM_MS := 40            # per-barrel release offset ceiling, ms; reversal: 0
fitted() -> Array                       # one entry per barrel, fit order, duplicates kept
battery_ids() -> Array                  # the distinct weapon ids in fitted(), first-barrel order
battery(base_id: StringName) -> Array   # that battery's barrel positions in fitted()
```

Rules the pin fixes, so no worker has to choose:

`fitted()` and `battery_ids()` keep the shipped typed return `Array[StringName]` (as `fitted()`
already was): a typed Array is an Array, so every caller named in §8.2 and `_state.weapons` read
it unchanged, and widening a shipped return type for no consumer is not the trade (H2 deviation
8; reversal: strip the annotation).

1. **`fitted()` is per barrel and keeps duplicates.** The `_fitted.has(id)` guard at
   `game/weapons.gd:369` is removed; `weapon_id` still drops an unknown or foreign id and
   `ShipFit.fitted_ids`' order (`game/ship_fit.gd:481-489`, one entry per non-empty cell,
   weapons first) is preserved, so three fitted lasers read `[laser, laser, laser]`.
   **Reversal:** restore the guard — the strip and the volley then read one group per family
   again, and `battery()` answers at most one position per base.
2. **Groups address batteries, not barrels.** `battery_ids()` is the distinct ids in
   `fitted()` in first-barrel order; `select_group(g)` selects `battery_ids()[g - 1]`
   (clamped `1 .. GROUPS_MAX` as today), and `selected_weapon()` returns that id, `&""` past
   the end. On a fit of distinct families this list is element-for-element today's `fitted()`,
   so every existing group, cadence and dry-state test reads the same.
   **Measured interaction, recorded not changed (H2 follow-up):** the HUD's W-slot buttons map a
   **cell** index to a group (`game/game.gd:1358-1359` calls `select_group(slot + 1)`), and the
   two index spaces now differ — on a hull whose W row holds fewer batteries than cells (a
   duplicated fit collapses barrels into one battery) the trailing slots select nothing, and a
   battery need not sit at its own cell's slot. That was already true of duplicated fits before
   S4 (they collapsed to one group); the wave does not move the HUD.
3. **`battery(base_id)` returns barrel positions in `fitted()` — not cell indices** —
   ascending, normalised through `weapon_id` (so `&"w_laser"` and `&"laser"` answer the same
   list), and `[]` for a base with no firing family (`w_mining`: the strip still groups by base
   id, so its row exists with no trigger behind it). The pane's `W1·W2·W3` labels are the
   hull's own W-cell indices and must be read from the pane's cell list, never from
   `battery()`: the two coincide while every W cell holds a firing module, and a family-less
   cell shifts the component's positions (measured: `[w_mining, w_laser]` → `fitted()` =
   `[laser]`, `battery(&"w_laser")` = `[0]`, while that laser is cell index 1). **Reversal:**
   one accessor; a cell-index-carrying `set_fitted` would change a caller shape and is not
   needed by any consumer today.
   **Superseded in part (2026-09-23, S5 — §17):** composed batteries store and answer
   **cell refs** (09 §4.5's addressing), and a barrel's mount is `weapon_mounts[cell_ref]`
   (J4); this rule's positions-in-`fitted()` reading is the S4 same-kind world's.
   **Reversal:** this rule as written.
4. **The volley.** On the pull's rising edge the component arms the selected battery: for each
   position in `battery(selected_weapon())` a release offset is drawn uniformly in
   `[0, BATTERY_STRUM_MS]` ms. Each `tick(delta)` releases every armed barrel whose offset has
   elapsed **and whose own cadence timer is ready** — the single `_shot_timer` becomes one
   timer per barrel, so three cannons deliver three shots per burst window instead of one and
   a sustained pull is a stream of salvos, not one burst. A released travelling barrel spawns
   its own shot, charges **one round** from its family's pack through `ammo_slot`, applies its
   own recoil and emits `shot_fired`; a released instant (beam) barrel opens its own beam.
   A barrel the family's own rules refuse (empty pack, a pool that cannot pay, the burst
   window closed) is dry (`dry_fired`) and never holds the rest of the battery back.
   **As built (2026-09-23, measured by H2, extended by H3's F1 and its H4 cure), six readings this
   rule left open — each is the shipped behaviour, not a drift:**
   - **The volley's clock is the battery's own *smallest* draw**, so the lead barrel releases on
     the pull's own frame and the barrels behind it release as their own offsets elapse (measured
     spans `[1, 9, 15]`, `[1, 3, 12]`, `[1, 32, 38]` ms). A literal reading of "offset from the
     pull" would delay even a **one-barrel** battery up to 40 ms, which makes four pinned
     one-frame feedback readings in `test_weapon_fx_f1.gd` (`:242-243`, `:261-262`, `:281-282`,
     `:559-560`) coin flips. **Reversal:** measure every offset from the pull — one line, and
     those four readings become "within 40 ms".
   - **A held travelling battery re-arms on the frame its whole salvo has released, and never
     before.** That is what makes rule 4's own "a sustained pull is a stream of salvos" true (H3's
     F1: the first build armed on the rising edge only and fired **one** salvo — measured 3 shots
     in 3.0 s; the cure fires **15**, five salvos at the family's cadence). The per-barrel cadence
     timers are what stagger and gate the stream. **Two carve-outs:** a beam battery is never
     re-armed (its barrels open once and keep drawing), and a travelling **`edge`** row keeps one
     release per pull — the mine, 09 §3.1's drop, whose pre-wave guard is `_fire_projectile`'s own
     `edge` read (`git show f3b0d24:vajb-orbit/game/weapons.gd:601-603`).
     **Reversal:** arm on the rising edge only — the pre-fix behaviour, which is H3's F1.
   - **A group switched mid-hold arms the battery it switched to** (today's component fires the
     newly selected group at once; without this the trigger would go silent until released).
     **Reversal:** keep the arming to the rising edge and let a mid-hold switch fall silent.
   - **A travelling barrel its pack refuses is disarmed for its salvo and re-armed by the next
     arm** — so while the pack stays empty it retries each frame, and `dry_fired` still reads
     **once per pull** because `_dry_noted` is reset on the rising edge only (measured: a pack of
     1 with three cannons gives one shot and one dry read). The observation the first wording
     carried ("one dry read per pull") stands; its *disarm scope* was the salvo, not the pull.
     **Reversal:** hold the barrel disarmed until the trigger is released.
   - **A closed burst window or an unready cadence timer keeps the barrel armed** rather than
     reading it dry, and that arm-retry is now load-bearing: it is what keeps a salvo unspent
     while one of its barrels waits on its cadence. Today `_burst_phase` resets to 0 on a pull,
     so the window case itself is unreachable. **Reversal:** consume the arm and read it dry.
   - **A beam battery draws one shaft and makes one contact read per frame** (one muzzle, one aim
     point); the frame's damage and chip work are summed over the paid barrels and delivered in
     one call, so the impact cue is not machine-gunned. **Reversal:** one `_apply_beam` per paid
     barrel.
5. **Ammo is per family, one pack per family, and the volley charges it per barrel.** Measured:
   `WeaponScript.ammo_slot` resolves the family's index in `PlayerState.WEAPONS`
   (`game/weapons.gd:1519-1526`) and the tree says so in words
   (`game/player_state.gd:84-89`, `game/game.gd:1247-1249`), so a 3-barrel laser volley spends
   **three** rounds from the `laser` pack per release. Nothing about the ammo shape changes;
   the per-trigger delta is simply multiplied by the barrel count (see §10's v0.8.0 note for
   the knock-on to `_file_ammo_report`).
6. **Energy families.** The strum is a *release* offset and a beam has no single release, so
   it delays the barrel's **opening frame**; once open, every barrel keeps drawing its
   family's `draw x delta` per frame while the trigger is held, and a pool that cannot pay a
   barrel's frame makes that barrel dry for that frame while the barrels before it keep
   drawing (measured: 3 lasers cost 1.800 Energy and deal 9.000 in a 0.1 s frame; a pool that
   **covers** two draws — `cost * 2.0`, the float the comparison itself uses, which is what
   `test_engine2_weapons.gd` sets — pays two barrels and reads the third dry **once**, while a
   pool set to exactly `1.200` pays one, because `6.0 * 0.1` is `0.60000000000000009`; that barrel
   stays open, so a pool that refills keeps drawing. L123 records the float nuance). No
   partial-volley abort state exists.
7. **`fit_battery(ship_id, base_id, indices)`** — the batch install over §13's
   `fit_module_at`, and **which instance lands in which cell is pinned**: for each index in
   ascending order the batch takes the **next unused instance** of `base_id` from
   `PlayerProfile.instances_of(base_id)` (`autoload/player_profile.gd:487-500`, creation
   order) and calls
   `fit_module_at(ship_id, &"weapons", index, instance_id)`. A base the bag does not carry at
   `count` 1 — a fitted instance is out of the bag — answers `[]`, so the batch has fewer
   instances than cells and refuses the surplus cells.
   `indices` are the hull's W-cell layout indices (`0 .. slot_capacity - 1`, §13's own space).
   The first guard that fails answers `false` writing nothing: a hull outside the nine or a
   W-less hull, an index outside capacity, a **repeated index** (one cell is one barrel — the
   conservative reading, reversal: dedupe), an **empty index list**, a bag that cannot cover
   the list (measured over the nine player hulls: every one carries at least one `W` cell, so
   the W-less branch is defensive), or a cell whose `fit_module_at` refuses.
   **The batch is atomic over the fit *and* the bag**: it snapshots `fit_for(ship_id)` and
   `modules()` before the first cell and, on any refusal, restores both through the public
   `set_fit` / `set_modules` (`:710`, `:341`) — a literal fit-only rollback would leave a
   restored cell's instance stranded at `count` 0 (the L80 class, §15). A hull that held **no
   stored fit** before the batch is returned to that state rather than given an all-empty one
   (the shipped `_restore_fit_and_bag` calls `clear_fit` for that branch; measured H1 deviation
   6 — `fit_for` hides the difference but `fits()` and the save file would not). It answers true
   only when every index was fitted, and logs one §13 line per fitted cell because its own calls
   do.
8. **`clear_battery(ship_id, base_id)`** — empties exactly the cells of that hull whose stored
   entry resolves through `base_module_id` to `base_id`, one `clear_fit_slot` per cell, with
   §7's snapshot-and-restore atomicity. A hull that holds no such cell — and any hull outside
   the nine — answers `false` writing nothing, so the pane renders a refusal rather than a
   silent success. A refused cell rolls the whole batch back, so a battery is never half-banked.
9. **The refusal copy has one home and the strip duplicates it byte-equivalently.** The three
   §13 wordings live in `ui/station/fitting_panel.gd:147-149`
   (`REFUSAL_OVERLOAD` = the format `"%d / %d PWR — OVER BY %d"` — rendered `13 / 11 PWR — OVER
   BY 2`, 09 §2's own over-by line — `REFUSAL_MANDATORY` = `MANDATORY CELL — SWAP ONLY, NEVER
   EMPTY`, `REFUSAL_FIT_ILLEGAL` = `REFUSED · FIT ILLEGAL`)
   — a file in no S4 worker's set — so OUTFITTING declares **its own three constants with those
   exact literals**, the precedent L116 recorded for byte-equivalent twins. The strip's footer
   renders `REFUSAL_OVERLOAD` with `fit_legal`'s own `power` numbers when the candidate is over
   budget (`13 / 11 PWR — OVER BY 2`) and `REFUSAL_FIT_ILLEGAL` otherwise. The mandatory
   wording is **unreachable for a W battery** (measured: `FitData.MANDATORY_SLOT_KEYS` is
   `[&"engines", &"power"]`, `game/ship_fit.gd:117`), so the pane keeps the constant for the
   set's completeness and no test may assert it through a battery.
   **Reversal:** lift the three literals into one shared `ui/station/` constant file when a
   later wave owns all three panes.
10. **The strip keeps its fixed node set.** `_build_strip` pre-builds `_max_weapon_cells()` rows
    and shows/hides by index **because the profile emits `profile_changed` from inside the
    handler that started it** (`ui/station/outfitting_panel.gd:147-148`), so a rebuild would
    free a plate whose press is still on the stack. The grouped strip keeps that invariant: at
    most one battery row per W cell plus one read-only line per **empty** W cell is never more
    than `_max_weapon_cells()`, and rows are rewritten by text/visibility/`disabled`, never
    rebuilt. **Reversal:** one rebuild path (and the freed-plate bug it causes).

## §17 S5 playtest fixes (2026-09-23) — commerce, consumables, batteries v2, hardpoints

```gdscript
# --- commerce & hangar (J1) ---
# auction_panel.gd — family tabs HULLS · WEAPONS · DRIVES · SHIELDS · ARMOUR · POWER ·
#   COMPUTERS · BOOSTERS · UTILITY · ALL over the same 6+10 draw (display grouping only)
# shipyard_panel.gd — owned hulls only; selection PREVIEWS and writes nothing;
#   the footer SET ACTIVE is the sole commit (the existing active-ship write)

# --- consumables (J2) ---
# cargo items: &"ammo_laser" &"ammo_cannon" &"ammo_rocket" &"ammo_mine" &"ammo_plasma"
#   &"ammo_railgun"; ROUNDS_PER_CARGO_UNIT := 10   (reversal: 1)
# railgun pack (owner 2026-09-23): rounds 150, cost 360, AMMO_MAX 150 — 2× the cannon
#   pack's cost, half its rounds and half its ammo_max (cannon: 300 / 180 / 300)
# the ammo rows deliver to cargo (units = rounds / 10); at launch each fitted weapon's
#   pack auto-fills from cargo of its family up to ammo_max and the drawn units leave
#   the hold; EXCHANGE buys units from the hold at 60 % of the per-unit list; fuel cells
#   are delisted everywhere (measured: no sale surface carries one)

# --- batteries v2 (J3) ---
batteries: Dictionary   # {ship_id: Array[Array[cell_ref]]}; SAVE_VERSION := 7
                        # v6→v7 migration: group fitted weapons by base_id, cells ascending
# a battery = player-composed MIXED group of W cells (any weapon kinds); ARMORY racks
#   B1..B7 = drop zones for weapon_1..7; drags install/swap through the §13/§16
#   transactions (refusals write nothing); the label OUTFITTING → ARMORY (owner-ratified 2026-09-23)
const GROUPS_MAX := 7   # was 5; weapon_6/weapon_7 bound to digits 6/7 (orchestrator-applied)
# salvo gate: one trigger releases every armed barrel (strum 0..40 ms) and the battery's
#   next salvo waits for max(members' cadence) — "the rof will be limited by the slowest
#   weapon". Dry/empty rules stay per barrel (§16 rule 4's carve-outs stand).

# --- hardpoints & gunnery (J4) — 09 §8's no-table rule SUPERSEDED, 09 §11 is the law ---
ShipFit.HARDPOINTS: Dictionary  # {ship_id: {thrusters: {rear, front, left, right: Array[Vector2]},
                                #            weapon_mounts: [{pos: Vector2, facing: float}…]}}
                                # W cell i binds weapon_mounts[i]; values measured off the
                                # renders into 09 §11's table by J4 (its deliverable)
                                # a hull without a map falls back to the §8 derivation
# flight FX: thrust at rear anchors, brake/retro at front, strafe at the side's anchors
#   (the thruster_anchors() seam resolves to HARDPOINTS)
# tracking: each barrel rotates toward the aim at its own 09 §3.1 track_dps
#   (proposed: laser 180, mining 150, cannon 120, railgun 100, plasma 75, rocket 60,
#   mine fixed); a released travelling shot flies along the barrel's CURRENT FACING from
#   its mount; a beam barrel sweeps and connects only within TRACK_TOLERANCE := 5.0 deg.
#   Reversal: TRACK_MULT := 0 = instant aim (today).
```

**J0 dispositions (owner-ratified 2026-09-23, before the J1 despatch).** The J0 docs pass
(`.agents/gen/slices/S5-playtest-fixes/S5-J0_report.md`) found ten contradictions in this pin
set; the owner ruled, and the blocks above are read as follows:

- **Railgun ammo is its own pack** (owner ruling 2026-09-23): rounds **150**, cost **360**,
  profile `ammo_max` **150** — twice the cannon pack's cost, half its rounds and half its
  `AMMO_MAX` (cannon: 300 / 180 / 300). Its icon is
  `res://assets/icons/module/icon_module_w_railgun.svg`. **Reversal:** delete the row.
- **The `ammo_*` cargo id maps to its family by prefix** — `&"ammo_laser"` ⇄ `laser`; the
  profile's `ammo_of`/`ammo_max`/`set_ammo` stay family-keyed. **Reversal:** one constant.
- **EXCHANGE buys `ammo_*` cargo units from the hold at 60 % of the per-unit list:**
  `list_unit = roundi(ROUNDS_PER_CARGO_UNIT * pack.cost / pack.rounds)`;
  `sale = roundi(0.6 * list_unit)` — laser 2, cannon 4, rocket 24, mine 30, plasma 38,
  railgun 14 CR/unit. The arithmetic lives in `game/exchange.gd`. **Reversal:**
  `AMMO_SELL_PERCENT := 1.0`.
- **The ARMORY keeps its ammunition rows**, buying cargo units (units = rounds / 10) through
  the hold; §5.11's "leave this pane" is the **pack model** leaving, never the rows (nothing
  else buys ammo — EXCHANGE only buys). **Reversal:** the pre-S5 pack route.
- **The AUCTION's `DRIVES` tab keys on `engine`** (the catalogue's slot key; `engines` is a
  prefix row, not a module). **Reversal:** one constant.
- **`GROUPS_MAX := 7` grows its three consumers in this wave:** `game/game.gd`'s
  `WEAPON_ACTIONS` and the HUD's `WEAPON_IDS`/`WEAPON_LABELS`/`WEAPON_ICONS` grow to seven,
  and the HUD's W-slot buttons address **battery ordinals 1..7** (`weapon_1..7`) instead of
  W cells (`game/game.gd:1358-1359` today maps a cell index). The railgun/mining icons reuse
  `assets/icons/module/icon_module_w_railgun.svg` and `_w_mining.svg`. **Reversal:** the
  five-entry tables and the cell-index call.
- **The shipyard row carries no icon** (owner ruling 2026-09-23): §5.11's "48 px class icon"
  is dropped — no class icons ship. **Reversal:** restore the phrase with the art.
- **§16 rules 2/3 read through this section:** composed batteries answer **cell refs**, a
  barrel's mount is `weapon_mounts[cell_ref]` (J4). **Reversal:** the rules as written.
- **The HUD's `set_hull_slots` payload carries each cell's `position`** — the barrel slot
  `PlayerState.ammo` indexes (`-1` for an empty cell) — beside `battery` (the rack ordinal);
  F1's R1-MED-1 cure, with the pre-S5 fallback kept. **Reversal:** drop the field.

## §18 D6 cockpit instruments (2026-09-23) — cluster + ship status screen

Landed docs-first (UI_SPEC §3.7/§3.8, UI_CHROME_ASSETS_SPEC §11, ASSET_NAMING_SPEC
§11 carry the numbers). Additive to §7: **every frozen method survives as-is, and
no new feed is introduced** — the cluster derives everything HUD already receives.

```gdscript
# ui/hud/cockpit_cluster.gd — class_name CockpitCluster extends Control (new file,
# built in code by hud.gd in the §7 inner-widget idiom; hud.tscn stays untouched).
# Read-backs (the probe precedent):
#   cockpit() / compass() -> Control
#   compass_heading() -> float        # 0..359 as drawn
#   readouts() -> Dictionary          # {spd, hull, shield, fuel_pct, energy_pct},
#                                     # each the clamped int the digits show
# §3.6's Speedometer contract survives BYTE-IDENTICAL
# (test_engine2_hud.gd:188-237 unmodified): SEGMENTS 10, SWEEP 1.5*pi, OVERDRIVE
# 0.9, 120x120, filled_segments(), overdrive_segment(), needle_colour(). Only its
# _draw surface changes: painted ui_gauge_face/ui_gauge_needle sprites under the
# marks; the segment fill, prograde needle and heading tick stay code-drawn in
# their theme tokens (textures stay palette-neutral, §3.2's precedent).
#
# ui/hud/ship_status_screen.gd — class_name ShipStatusScreen extends Control (new).
# Toggled by &"ship_status" behind InputMap.has_action (the project.godot row is
# orchestrator-applied at close-out — workers never touch project.godot).
# Reads only: resolved_fit + set_hull_slots cells, ModuleCatalog names, the fitting
# panel's own power arithmetic (cited, never re-invented), the repairs-panel
# damaged-side suffix rule, and ShipFit.HARDPOINTS markers behind
# ShipFit.HARDPOINTS.has(hull_id). Writes nothing.
```

Digit semantics (UI_SPEC §3.7 is the law): SPD = `int(round(prograde.length()))`
u/s 4 cells clamp 9999 (owner amendment 2026-09-24 — "in the cockpit if all clocks
are 4 digits make the speed 4 digits as well"; was 3 cells clamp 999, reversal to
that); HULL/SHLD = `int(round(current))` points 4 cells clamp
9999; FUEL/ENRG = `int(round(100 × value / maximum))` clamp 0..100, 3 cells + the
`%` cell; HDG 0..359. Leading blanks (`ui_seg_blank`), never zeros; `maximum == 0`
reads 0. Danger rows reuse §3.1/§3.1b as row treatments (label + 1 px script-drawn
frame — digits never recolour); overdrive is `ratio > 0.9` strict.

**§18 interface catch-up (2026-09-24, wave D7 as built — UI_SPEC §3.7's Mockup v7
block is the law where this section lags):** the compass bay and the HDG row are
gone (owner: "we ditch the compass entirely"); `compass()` returns null and
`compass_heading()` 0.0 (stubs — signatures frozen), and `readouts()` returns
`{spd, hull, shield, ammo}` (spd 4 cells clamp 0..9999 per the earlier
amendment; hull/shield points 4 cells; ammo = the active rack's loaded rounds,
4 cells clamp 0..9999; the `fuel_pct`/`energy_pct` keys retire — the FUEL/ENRG
value dials carry them). The cluster = gauge + `B1..B5` battery lamps (the
`weapon_1..5` selection) + two value dials + four drum rows, all on
`CockpitStyle` (UI_SPEC §3.9 rule 5: `ui/hud/cockpit_style.gd` + the
`cockpit_style_user.tres` override). The old column and the §3.1b pool bars are
retired (`set_pool`/`set_emergency` signatures unchanged). `ship_status_screen`
keeps its seams (toggle behind `InputMap.has_action`, read-only fits) on the
Mockup C surface; the armory keeps every 09 §11/§17 transaction on the Mockup A
surface (SALVO cells render centiseconds: 0.73 s reads `073`).

## §19 S6 travel + RPG P3 (2026-09-24) — gates, corridors, POIs, scanner, heat, loot

Pinned additions carry the docs' own numbers (11 §5, 13 §7, 06 §8 amendments,
2026-09-24). Engine §14 slice 3's deliverable line is the wave; the §14
"hunters in slice 4" note is **superseded** for the hunter part by the owner's
item-12 grouping (P3 = heat + hunters) — bosses/arena hooks stay slice 4.
Every seam below is additive; nothing frozen moves.

```gdscript
# game/sector_registry.gd — additive beyond §6's pin:
#   SECTORS row gains: neighbours: Array[int], gate_links: Array[int] (1-2-3-4-5-6-7
#   spine, 11 §2.3), corridors: Array[Dictionary]  # [{dest, edge_rect}]
#   static GATE_FEE_BASE := 150, GATE_FEE_PER_SECTOR := 100 (11 §2.1)
#   static CORRIDOR_DEPTH := 600.0        # proposed, reversal 400.0 (11 §5)
#   static DERELICT_SCAN_RANGE := 300.0   # proposed, reversal scan_range (11 §5)
#   static RIFT_DRAIN := 12.0             # proposed, reversal 6.0 (11 §5)
#   static ANOMALY_WEIGHTS_RIFT_DOUBLED := [&"sector_6"]   # the Hollows (11 §3.2)

# game/gate.gd — new file (engine §14's name), class_name Gate extends Area2D:
#   setup(dest_sector: int) -> void
#   fee_for(heat_tier: StringName) -> int   # floor((150 + 100·d) × want × lawless);
#       want 1.5 at Wanted only, lawless 2.0 into sector 7, else 1.0 (11 §5)
#   jump(profile, heat_tier) -> int         # 0 ok / -1 refused (Outlaw) / -2 funds;
#       charges via PlayerProfile, 2 s charge-up, then the loading transition

# game/corridor.gd — new file, class_name Corridor extends Area2D:
#   setup(dest_sector: int, edge: Rect2) -> void
#   hold_progress() -> float                # 0..1 over 15 s presence (11 §2.2);
#       resets on zone exit, NOT on hull damage (11 §5 tick 2)

# game/poi.gd — new file, class_name Poi extends Node2D (derelict/anomaly/beacon):
#   setup(kind: StringName, row: Dictionary) -> void
#   scan(player) -> int                     # 0 ok / -1 refused (out of range or
#       no scanner) / -2 interrupted (left range or hull hit); derelicts: 5 s
#       interruptible channel (11 §3.1); roll 0.40 cache / 0.35 data core
#       (03 comp_elec + DATA_CORE_CREDITS 120 CR, proposed, reversal 60) /
#       0.25 magic module (15 §5); one-shot per respawn cycle
#   trigger(player) -> void                 # anomalies at 200 u (11 §3.2): ore_bloom
#       (T+1 cluster, 10 rocks, 2× yield) / grave_cache (3–5 pickups, one grade up)
#       / void_rift (RIFT_DRAIN shield/s inside; 1 exotic: T4 ore, or magic+ module
#       at 0.10); despawns, respawns on the sector clock (17 §4)

# game/loot_tables.gd — the slice-2 file, extended additively (17 §2's name):
#   static TABLES: Dictionary   # shipped (five kinds incl. swarmer) — restate nothing
#   static HUNTER_EXTRA: Array[Dictionary]   # 06 §8's comp_elec table (owner tick 8)
#   static WRECK_PICKUP_LIFETIME := 90.0     # 06 §4; the wreck site's own despawn
#   roll_band(kind: StringName, random_seed := 0) -> Array[Dictionary]   # NEW:
#       the kill's band roll — delegates to the shipped roll(kind, tier, seed),
#       whose shape stays byte-identical (one entry per line, amount = randi_range,
#       caches last and distinct: 06 §2.3 as shipped and test-pinned)
#   roll_hunter_extra(band: int, random_seed := 0) -> Array[Dictionary]  # NEW:
#       06 §8's HUNTER_EXTRA rows, grade-capped by band, rolled in addition

# game/sector.gd — additive beyond §6's pin (scanner reveal lives here, engine §14):
#   blips() gains gate/beacon/ders/anomalies entries per 11 §5's mapping; soft fog:
#   a POI blip appears once scanned or beacon-revealed; gates and stations always
#   appear. WorldClock remains the only respawn clock (17 §4).

# autoload/player_profile.gd — additive:
#   pay_bounty(faction_id: StringName) -> bool   # fine = heat × 25 CR (13 §2);
#       all-or-nothing per 17 §5; one BOUNTY economy-log line; zeroes that heat

# game/game.gd — the wiring owner (one owner, 17 §2): the kill path is the real
#   seam `_on_npc_died` (NpcShip.died; projectile.gd:_shot_down is the rocket
#   intercept, not a hull kill) — it calls LootTables.roll_band + roll_hunter_extra
#   and spawns the wreck site (WRECK_PICKUP_LIFETIME 90 s, 06 §4); heat only with a
#   witness in WITNESS_RANGE 900.0 (= ShipFit.BASE_SCAN_RANGE, 13 §7); sector
#   transitions go through the `loading` route (game.gd:on_route reads PARAM_SECTOR)
#   and file the vitals first (`_file_damage_report`), so hull/shield/fuel/ammo
#   persist across the scene reload (11 §2.3: fields/pickups reset, hold/hull/heat
#   persist). One prompt-line priority owner: `_update_dock_prompt` currently writes
#   the line every frame, so gate/scan/cache readouts need a priority arbiter.
```

Rules that fix every ambiguity: **no `ui/hud/**` writes in this wave** — the
gate prompt, scan readout and cache feed line all ride the frozen `set_prompt`
seam (§7); hunter waves spawn per-faction per 13 §3 (Concord hunts Concord's
outlaws only); `heat_on_kill()`'s existing −3/+15/+25 values are the gains
table and are not re-derived; Outlaw dock/gate refusals charge nothing and
write nothing; every refusal path leaves the profile byte-identical (S4's
rules 7/8 precedent).

**K0 dispositions (owner-ratified 2026-09-24, applied before the builders).** The
drift pass (`.agents/gen/slices/S6-travel/S6-K0_report.md`) found the following;
each cure is binding on this wave:

- **Fee worked row corrected:** the multiplicative composition gives
  `floor(250 × 1.5 × 2) = 750` for an adjacent jump into sector 7 at Wanted.
  The `562` the brief and K1/R1's prompts carried is `floor(250 × 2.25)`, the
  **additive reversal's** figure, and is not this build's number.
- **`roll(band)` was a phantom:** `game/loot_tables.gd` shipped in slice 2 with
  `roll(kind, tier, seed)` pinned by `tests/test_engine2_loot.gd`. The band roll
  is **additive** (`roll_band` / `roll_hunter_extra`), the shipped shape stays
  byte-identical, and **no existing test count moves** (06 §8's "one pickup per
  unit" wording is corrected to the shipped stack shape: one entry per line,
  `amount = randi_range`; reversal: per-unit, which would move two
  `test_engine2_loot.gd` rows and is out of scope).
- **`ShipFit.BASE_SCAN_RANGE`** is the constant's owner (`game/ship_fit.gd:40`);
  `ShipStats` carries only the per-instance `scan_range`.
- **Decay rides a game-side play-time accumulator** (`game.gd`'s own tick, a float
  in seconds; −1 per 60 s of play, floored at 0). No Timer node, and `WorldClock`
  stays the station-band clock with its five consumers (17 §2/§4 unchanged).
- **Heat is clamped 0–100** per faction on gain (13 §2's bound, unimplemented
  today).
- **Two refusal axes, each from its own doc:** the **gate** refusal reads the heat
  tier (`NpcRegistry.heat_tier() == &"outlaw"`, 13 §3 / 11 §2.3); the **dock**
  refusal reads standing (`PlayerProfile.standing() <= -51`, 12 §4.1). Both write
  nothing.
- **Hunter row flips:** `game/npc_registry.gd`'s hunter row moves off
  `SEAM_SLICE_4`; `KEY_TIER` stays 1 (test-pinned) and the tick-6 hull map lives
  in `KEY_MEMBERS`; `KEY_AGGRO_RADIUS := 900.0` (proposed — the pirate fighter
  band's own radius; reversal 1200.0) with `KEY_SCAN_RADIUS` the same.
- **`game/heat.gd` is dropped from the worker set** — heat logic lives on the
  existing files (`player_profile.gd`, `npc_registry.gd`, `game.gd`); the file has
  no pin and no interface.
- **The bounty surface ships:** `ui/station/launch_panel.gd` +
  `game/station_catalog.gd` join K3's set (owner-ratified set growth), the row
  appearing for the docked station's faction when its heat > 0.
- **Quadrants deferred:** 18_engine_spec §4.5/§15's "slice 3 turns quadrants on"
  is superseded for this wave (owner call) — directional armour moves to slice 4;
  `test_engine2_pools.gd`'s `ctx` row holds unmodified.
- **The `sibelon` is superseded** (owner call): ruling 24's slice-3 anomaly entity
  gives way to 11 §3.2's three kinds; the registry row stays parked and unspawned.
- **Wreck-site blip** rides the existing `&"neutral"` kind (no new blip kind; the
  HUD is frozen).
- **The stale `SECTOR_NAME := "Helios Drift"` label** (`game/game.gd:89`) is
  replaced by the registry row's name on spawn and on transition.
- **The three seam hooks the brief named (`_on_kill`, `_transition`, `_poi_table`)
  do not exist** and were never in this section; the real seams are
  `game.gd:_on_npc_died`, `game.gd:on_route` + `route_requested(&"loading", …)`
  and `sector.gd:populate`.

**K1 dispositions (orchestrator-ratified 2026-09-24, after the travel core
landed).** Measured by K1 (`.agents/gen/slices/S6-travel/S6-K1_report.md`,
`626/0`, re-measured by the orchestrator on a scratch store):

- **One existing row moved, ratified:** `tests/test_engine2_wiring.gd`'s
  minimap-feed assertion now derives the friendly count from the sector's own
  `gates()` (the station plus one per gate link), because 11 §5 maps gates to
  `friendly`. K2's beacon/derelict/anomaly blips move the same row again —
  derive, never hard-code. This is the only existing row the wave touches.
- **Three placement values reported, not invented:** `sector.gd:GATE_RING_RADIUS`
  `900.0` u, `gate.gd:RING_SCALE` `0.25` and `gate.gd:TRIGGER_RADIUS` `200.0` u
  (11 §2.1 quantifies none of them; reversal: one edit each). Owner ticks.
- **Route notes (bucket 1, no pin moves):** the three POI constants
  (`DERELICT_SCAN_RANGE` / `RIFT_DRAIN` / `ANOMALY_WEIGHTS_RIFT_DOUBLED`) live in
  `sector_registry.gd` so K2 reads them rather than minting a second home; a
  sector crossing arms `game.gd`'s `_transit_destination` static so the reload
  seeds the ammo packs from the filed store instead of re-drawing the hold
  (AC4's hold byte-equal); sector 7's ring is placed by the same formula as every
  other sector and the player seats on the destination's own spawn point (no
  arrival-point rule exists in the docs).

**K2 dispositions (orchestrator-ratified 2026-09-24, after POIs + loot landed).**
Measured by K2 (`.agents/gen/slices/S6-travel/S6-K2_report.md`, `651/0`,
re-measured by the orchestrator on a scratch store; the derelict roll
`0.3991/0.3488/0.2521`, Hollows rift `0.4995` vs `0.3374` normal, hunter extra
`0.4978/0.2501/0.0984`, every haul inside 06 §6's ±5 %, the wreck site whole to
89.9 s and freed at 90):

- **The wiring row moved again, ratified:** the minimap feed's friendly count now
  derives `gates + beacons + 1` (beacons are nav aids, 11 §3/§2.2). Same
  assertion count, derived expectation.
- **Soft-fog reading (route):** a beacon always shows (it is the thing that
  reveals); derelicts and anomalies stay fogged until scanned or revealed.
  Reversal: start beacons fogged too (one line in `Poi.setup`).
- **Route notes (bucket 1, no pin moves):** the derelict channel starts on
  proximity (no press-to-scan prompt exists in the pin); the scanner is read off
  `PlayerProfile.resolved_fit` (any computers module with `scanner_add > 0`),
  because `PlayerShip` publishes no fit accessor — reversal: a `PlayerShip`
  accessor; a beacon needs no scanner; a hull hit breaks the channel through
  `_on_ship_damage_taken`; the wreck site is `Poi.KIND_WRECK` inside the one new
  POI file (reversal: its own file); the site holds its pickups' `_age` at zero
  while it lives so the 90 s window outlives `Pickup.LIFETIME`'s 60 s (reversal: a
  `lifetime` argument on `Pickup.setup`); the rift drain goes through
  `PlayerShip.take_damage` (shield-first, the only shipped sink).
- **Reward content the docs left open (reported; owner ticks):** the data core's
  item `comp_elec_1`; the cache `comp_scrap_1` ×1–3; the module base id uniform
  over `ModuleCatalog.MODULES` minus the three faction exclusives; the sector band
  `ceil(n / 2)` clamped 1..4; the ore-bloom radius 320 u with 0.25 jitter. Each
  reversal is one edit (K2 report §3.6).

**K3 dispositions (orchestrator-ratified 2026-09-24, after heat + hunters
landed).** Measured by K3 (`.agents/gen/slices/S6-travel/S6-K3_report.md`,
`674/0`, re-measured by the orchestrator on a scratch store):

- **Only crimes need a witness (route):** positive heat is gated on a witness and
  carries `WITNESS_EXTRA`; a negative `heat_on_kill` (the pirate −3) lands
  unconditionally. Reversal: one `if` in `_on_npc_died`.
- **The victim is excluded from its own witness scan (route, a measured defect
  cure):** `NpcShip._die` raises `died` before `despawn()`, so without the
  identity skip every neutral/patrol kill would witness itself. Reversal: drop
  the skip.
- **`NpcShip._read_heat_tier` reads the worst heat for a factionless hull
  (route, a pre-existing defect cure):** a convoy's space owner resolved to the
  literal `none`/`unaligned`, so 13 §5's trader panic could never fire. No
  existing test moved. Reversal: restore the `!= &""` predicate.
- **Route notes (bucket 1):** the bounty row toggles `visible` on one `ServiceRow`
  (node count unchanged, `test_p2b_services.gd` holds); `PlayerProfile.docked_faction`
  is a transient, non-persisted carrier for the pane (no save key, no version
  move); a hunter wing is re-homed on the player at `HUNTER_SPAWN_RADIUS` **600.0**
  u (proposed, no doc source; reversal: the sector's own field anchor) so it
  hunts; the witness LOS is measured through the hull's own injected verdict
  because the headless runner's suites run before the first physics step (no body
  is in the broadphase; `space_flush_queries` does not exist in 4.7.2).
- **Copy choices reported (owner ticks):** `DOCK REFUSED — OUTLAW` (mirrors the
  gate's line; reversal: delete the rung), `PAY BOUNTY (n CR)` /
  `BOUNTY PAID · n CR` / `REFUSED · NOT ENOUGH CREDITS` / `NO BOUNTY DUE` (one
  format string each).
- **Staged:** the station turret (13 §7 tick 7) — re-measured: the station has no
  damage sink, the turret archetype is `SPAWN_STATION` with no consumer.

## §20 S7 affix application (2026-09-24) — the staged wave of 15 §9.3, slice 4's affix half

**Docs-first (developer session, 2026-09-24). A worker implements this text; only the
developer session changes it.** Wave S7 (coder item 13) applies the instances S3
stores to flight. Everything derives from 15 §1/§3/§4 and 09 §5 unless marked
*proposed* (reversal named). Whole-block reversal: consumers read no affixes and the
tree is byte-identical to pre-S7 — S3's record/naming/pricing/display (§15) is
untouched. Owner ticks for this wave: `S7_BRIEF.md` §Owner ticks.

### The aggregation law

- **Prefix values are the stored rows** — `prefixes: [{id, value}]` with values as S3
  rolled them (measured: fractions; `frugal`/`lightened`/`spry` store their band
  **negative**, `game/module_catalog.gd:156-204`). Never re-rolled, never re-derived;
  `ModuleCatalog.prefix_value(prefix_id, tier)` (`module_catalog.gd:725`) is the band
  reader S3 already owns.
- **A percent/points affix modifies its own instance's contribution to its `stat`** —
  15 §1's "the baseline every affix modifies" is the module's own catalogue stat.
  Instances then combine by that stat's own 09 §5 rule (flat sum / best value /
  summed delta). `units`-unit affixes (`deep_hold`) add their value.
- **Which shape carries which rule (K0 F1; corrected by K1's D1):** only a rule that
  never multiplies an instance's **own** stat reads the aggregate keys — Deep-hold
  (its units are added, not scaled) and Spry (`1 + Σ` over fitted boosters, and `spry`
  only rolls on boosters). Every rule written `own × (1 + Σown)` or `own += …` —
  Sturdy, Vigilant, Wideband, Surefire, Tempered, Lightened — reads
  `affixes[&"instances"]` and computes each instance's own figure from its row's
  `base_id` + `prefixes`, because the aggregate cannot say which instance carries the
  prefix. Sturdy's own counter-example is the proof: `s_light`'s 200-pool Sturdy 0.10
  beside `s_heavy`'s 400-pool Sturdy 0.15 adds **+80**, not `0.25 × 600 = +150`; K1's
  suite asserts both numbers.
- **A suffix is a per-instance flag** (`suffixes: [id]`,
  `game/module_catalog.gd:219-250`): one instance carrying it applies the perk once;
  two instances do not double it (*proposed*; reversal: per instance). An instance
  answers while fitted (`count` 0, §15).
- **Every application lands before `_clamp`** (`game/ship_fit.gd:1014-1027`): 09 §5's
  step-4 clamps (speed ≥ 40 % hull base, pools ≤ 3× hull base) hold with every affix
  at its band maximum.

### The seams

```gdscript
# game/affixes.gd — NEW file (the wave's one new owner, 17 §2), class_name Affixes:
#   summary(profile, ship_id) -> Dictionary
#       # over every fitted instance of resolved_fit(ship_id) (all FIT_SLOT_KEYS):
#       #   {prefix_id: summed_magnitude,       # ship-level aggregate, stored signs
#       #    &"suffixes": Array[StringName],    # one entry per perk, once
#       #    &"instances": Array[Dictionary]}   # one row per fitted instance, in
#       #        # FIT_SLOT_KEYS order then cell order:
#       #        # {&"slot": StringName, &"index": int, &"base_id": StringName,
#       #        #  &"prefixes": Array[{id, value}], &"suffixes": Array[StringName]}
#       # magnitudes carry 15 §3's own signs (frugal -0.15 stays negative); {} when
#       # no fit. `instances` is what makes the per-instance law expressible at all
#       # (K0 F1): a summed magnitude alone cannot say *which* instance carries the
#       # prefix, and Σ(vᵢ × ownᵢ) ≠ Σvᵢ × Σownᵢ.
#   has_suffix(data: Dictionary, id: StringName) -> bool
#       # K1's D5: the parameter is named `data`, not `summary` — a parameter named
#       # after the class's own `summary` function raises SHADOWED_VARIABLE. GDScript
#       # has no named arguments, so the rename touches no caller.

# autoload/player_profile.gd — additive:
#   affix_summary(ship_id: StringName) -> Dictionary   # Affixes.summary(self, ship_id)

# game/ship_fit.gd — ONE optional parameter; every existing caller unchanged and
# byte-identical with {} or no third argument:
static func resolve(hull_id: StringName, fit: Dictionary, affixes: Dictionary = {}) -> ShipStats

# game/ship_stats.gd — §2 amended by one additive field (the slice-0 pattern):
booster_cooldown_mult: float = 1.0     # Spry's aggregate; 1.0 when no booster affix

# game/player_state.gd — additive (the set_weapons handshake's sibling):
weapon_affixes: Array[Dictionary]      # one {keen, rapid, frugal} magnitude dict per
    # entry of `weapons`, same order and same empty-cell skipping (file doc :84-96)
set_weapon_affixes(per_cell: Array[Dictionary]) -> void   # sized with _resize_ammo
affix_flags: Array[StringName]         # the fitted instances' suffix flags, launch-time
set_affix_flags(flags: Array[StringName]) -> void   # the game.gd handshake sets both
ammo_frac: Array[float]                # Frugal's per-cell fractional round bank

# game/auction.gd — the sell price gains ONE optional parameter:
static func sell_price(base_id: StringName, rarity: StringName, suffixes: Array = []) -> int
#   x1.25 when suffixes contains "ledger". K0 measured THREE production sites of the
#   `base x rarity x 60 %` figure (F5) and K3 landed the term in this one function
#   (K3's D1), with each site passing the record's own suffix list:
#     - Auction.sell_price:625 (this function -- the term's ONE home; K0's "no
#       production caller" reading was pre-S7 and is superseded by K3's D3)
#     - Auction.sell_row:763 (the transaction's quoted price)
#     - PlayerProfile.sell_instance:730 (the payout -- credits move there)
#   plus the pane's displayed sell price at Auction._sell_row:592, which shows the
#   same figure the payout pays. `ModuleCatalog.sell_price` keeps its two-argument
#   signature (it is in no S7 file set).
```

### Prefixes — where each one lands (15 §3's rows; measured `module_catalog.gd:127-211`)

| prefix | slot/stat | application (inside `resolve` unless named) |
|---|---|---|
| Sturdy | shields/`shield_add` | flat step: `shield_max += Σ(own shield_add × value)` |
| Vigilant | shields/`regen_add` | per instance `own × (1 + Σown)`; `_apply_shields` keeps the **best** instance (09 §5's best value), then `BASE_SHIELD_REGEN +` it |
| Keen | weapons/`damage_add` | **per barrel**: that cell's shot damage `× (1 + Σown)` at shot composition — NOT in `resolve` |
| Rapid | weapons/`fire_rate_mult` | per barrel: release interval `÷ (1 + Σown)` (rate ×1.08…1.16) |
| Frugal | weapons/`ammo_mult` | per barrel: per-shot round cost `× (1 + Σown)` (negative → cheaper) through `ammo_frac`'s fractional bank; an integer round leaves only when the bank crosses 1; the bank is flight-state — seeded empty at launch, ≤1 round/cell unfiled at dock (reported, not persisted) |
| Lightened | armour/`speed_penalty` | the instance's own penalty `+= abs(Σown)`, clamped so the effective penalty never crosses 0 into a bonus (band −4/6/8 pp; *proposed* sign-flip reading of 15 §3's "(multiplicative) −4/6/8 pp"; reversal: `penalty × (1 + Σown)`); the armour loop's speed **and** mass terms follow the adjusted penalty |
| Tempered | engines/`speed_mult` | the instance's own delta `(own − 1) × (1 + Σown)` joins `_apply_speed`'s summed engine delta — inside `ENGINE_MULT_CEILING` 1.40 as part of the sum |
| Overflowing | power/`power_add` | **STAGED** (owner tick; the budget is frozen — Rules below) |
| Wideband | computers/`scanner_add` | per instance `own × (1 + Σown)`; `_apply_computers` keeps the **best**; `lock_range` follows `scan_range` untouched (`ship_fit.gd:614`) |
| Surefire | computers/`damage_add` | per instance `own × (1 + Σown)`; computers still **sum** (09 §3.4) → `damage_mult = 1 + Σ` |
| Spry | boosters/`cooldown_mult` | ship-level: `booster_cooldown_mult = 1 + Σown over fitted booster instances`; `player_ship.gd:1124` becomes `cooldown × _stats.booster_cooldown_mult` |
| Deep-hold | utility/`cargo_add` | flat step: `cargo_max += Σ(value)` units, added to the instance's own `cargo_add` |

### Suffixes — five land, five stage

| suffix | this wave | seam |
|---|---|---|
| Whale (+50 hull) | **apply** | `resolve` flat step, before `_clamp` |
| Embers (10 % of damage dealt → shield) | **apply** | both deliveries, after the `damage_mult` product: `weapons.gd:_deliver` (`:1774`) and `projectile.gd:_deliver` (`:885`). The predicate is measured (K0 F7): the sink `_sink_for` resolved is an **NPC hull** — `sink.is_in_group(&"npc_ship")` (`weapons.gd:_sink_for:1806-1817` walks `SHIP_GROUPS` `:348` = `[player_ship, npc_ship]`; `projectile.gd:_sink_for:912-922` walks the same two) — so a rock (`Asteroid`, group `&"asteroid"`, answers no damage method) and the player's own hull are excluded. Heal `PlayerState.shield = min(shield + 0.10 × dealt, shield_max)`. The `embers` flag rides `PlayerState.affix_flags` (set in the launch handshake) and the shot's `configure` dict; the beam path reads `_state` directly, the projectile path heals through an additive `PlayerShip.heal_from_damage(dealt) -> void` on its `_source` (no-op with no state) |
| Leeches (kills restore 5 % hull) | **apply** | `game.gd:_on_npc_died` (`:2032`): heal `0.05 × hull_max` on the deaths the handler already credits (K0 reports whether killer identity is knowable and gates if it is not) |
| Cartograph (POIs revealed) | **apply** | sector entry in `game.gd`: if the summary carries it, call the shipped `Sector.reveal_pois()` (`sector.gd:335`, the beacon's own call) once after populate |
| Ledger (sell +25 %) | **apply** | the `suffixes` parameter above, at all three production sites (F5) — **supersedes §15's "no suffix term" line** (dated here; reversal: drop the term). Exact integer: `base × rarity × 60 % × 1.25` stays integral for every 09/15 cost (per 100 CR the three products are 60 / 96 / 156, all ÷4; 900-cost Common 540 → 675) |
| Silence (2× detect time) | **STAGED** | 13 §3 pins **no** detection-time mechanic (measured: aggro is distance, `game/npc_brain.gd:421-427`) — an owner call whether one exists at all |
| Vault (spill −50 %) | **STAGED** | no cargo-spill-on-death system exists in the tree (measured) |
| of the Choir / of the Concord / of the Ports | **STAGED** | no faction station or arena can roll them (15 §4/§5; 12 §5 unshipped) — caller-less like 15 §9.3's own rows |

### Rules that fix every ambiguity

- **`damage_mult` becomes real (measured defect):** `ShipStats.damage_mult` has no
  consumer today — the computers' `damage_add` (09 §3.4/§5) resolves and is then
  inert. S7 wires the one delivery multiplier: every player-origin damage amount
  passes `× damage_mult` **exactly once** before the sink call. K0 measured the five
  sites (F2, F12, F12b), and they are the law:
  1. `weapons.gd:_deliver` (`:1774`) — the beam's frame damage (`_apply_beam` `:1258`
     is its only caller) and every hull sink it reaches;
  2. `weapons.gd:1233` — the beam's rock chip (`apply_work(amount * GUN_CHIP_RATE)`);
  3. `projectile.gd:_deliver` (`:885`) — every bolt/slug/rocket/mine hull sink
     (`_hit_body:785`, `_detonate:843`). This is a **second, independent delivery** in
     a file no S7 set owned before K0 measured it: `game/projectile.gd` is K2's.
     The projectile reads no stats — `weapons.gd:_spawn_shot` (`:1177`) stores the
     launch's multiplier (and the `embers` flag) in the shot's `configure` dict, so
     the product lands once per delivered amount with no new accessor;
  4. `projectile.gd:758` — the projectile's rock chip (`apply_work(damage * chip)`);
  5. `player_ship.gd:929` — the **ram** (`_on_hull_body_entered` → the peer's
     `apply_collision_damage`). It is a player-origin damage amount on a path K0
     measured, so the pin's own "any parallel player-damage path" covers it; reversal
     is dropping that one product, and it is named on the owner tick list.
  The multiplier is read **null-tolerantly** (K0 F3: eight gate suites hand
  `Weapons.setup` a null stats argument or never call it; the shipped convention is
  `weapons.gd:1665,1677`) — a null stats resolves to 1.0, never a crash.
  `mining_laser.gd` carries **no damage amount at all** (`:199` calls `apply_work`
  with `WORK_PER_UNIT` 1.0), so the tick's "mining TTK moves" can only mean the two
  gun-chip sites above; that is the reading, and it is not a defect.
  *Owner tick:* it applies to every sink the player damages, rocks/mining included,
  **and the ram** (reversal: ship sinks only, or drop site 5).
- **Keen stays per barrel (owner tick):** each released barrel reads **its own cell's**
  `weapon_affixes[i]`; a battery whose cell 2 is Keen gains it on barrel 2 only.
  Reversal: fold Keen into `damage_mult` (one function, ship-wide).
- **Frugal's bank, and L90 underneath it (K0 F10):** the bank (`ammo_frac`) is per
  `PlayerState.weapons` slot — flight state, seeded empty at every launch/seed point,
  never persisted; the **pack** is the family's, spent through the shipped
  `_consume_ammo`. K2 states both in its report. The shipped `ammo_slot`
  (`weapons.gd:2201-2208`) resolves a family's index in the **const**
  `PlayerState.WEAPONS:35`, not in the live fit-order `weapons` array, so a live pack
  can be addressed past its own length (LOW **L90**); K2 routes around it or fixes it
  (bucket 1, L90 is not this wave's pin) and reports which.
- **Leeches' gate (K0 F6):** killer identity is **not knowable** — `NpcShip._die`
  emits `died(position, archetype)` only, `take_damage` records no source, and
  `NpcShip._on_body_entered` lets an NPC die to a rock or a peer. So the perk fires on
  the deaths the handler already credits (every `died` that reaches `_on_npc_died`),
  exactly as this pin's fallback says; a player-only reading would need attacker
  plumbing in `npc_ship.gd`, a file in no S7 set.
- **The per-cell arrays align by construction:** `set_weapons` and
  `set_weapon_affixes` walk the same fitted list with the same empty-cell skipping.
  K0 measured the three facts that make this buildable (F8/F9/F11):
  - the walk's source must be the profile's **raw** fit (`fit_for`/`resolved_fit`,
    instance ids), not `_launch_fit` — `game.gd:_profile_fit:456-480` maps every cell
    through `base_module_id`, so `_launch_fit` holds no instance identity;
  - `weapon_affixes[i]` is indexed like `PlayerState.weapons[i]` (a slot per fitted
    non-empty W cell, `game.gd:_hull_slot_cells:1919-1944`), while `WeaponsComponent`
    barrels are `fitted_ids(fit)` order with family-less/foreign ids dropped
    (`weapons.gd:498-518`, §16 rule 3's recorded divergence) — so the barrel→slot map
    is K2's to build from `_weapon_barrel_positions:644-660` and `_hull_slot_cells`;
  - the beam's per-family aggregation (`_fire_beam_battery:1073-1142`, `paid[weapon]`
    is a **count**) loses the barrel identity Keen needs: the weight becomes
    `Σᵢ(1 + keenᵢ)` instead of `count`, which is byte-identical when no cell is affixed
    (`test_engine2_weapons.gd:600-615` pins `dps × delta × 3`).
  A worker who cannot align barrel index ↔ cell reports instead of guessing (bucket 1).
- **Empty defaults are byte-identical:** no summary, `{}` into `resolve`, `[]` into
  `set_weapon_affixes` — every pre-S7 number, fixture and standard fit resolves
  exactly as before (`STANDARD_FIT` carries no instances).
- **Overflowing is staged because §6 freezes the budget:** "power draw never changes
  with rarity — affixes bend the good stats, never the budget"; `+output` *is* the
  budget, `fit_legal`/`power_budget` take no profile (frozen §12/§13 signatures), and
  the panels that would render it belong to the parallel D7 lane. *Owner tick:*
  staged, or re-emit as `energy_max` (reversal: one row in `resolve`'s flat step).
- **No `ui/**`, `assets/**`, `staging/**` or `docs/` writes by builders** — D7 holds
  those until it closes; a display that "needs" a widget is a report, not a write.
- **Test law:** the wave's suites are `tests/test_s7_affixes.gd` (K1),
  `tests/test_s7_weapon_affixes.gd` (K2), `tests/test_s7_suffixes.gd` (K3) — new
  prefixes only. No existing suite **count** moves. K0 measured the tests-that-move
  list (F3/F4) and it is dispositioned here:
  - **One assertion flips, for Ledger:** `tests/test_s3_instances.gd:520-546`
    (`test_sell_instance_pays_the_base_times_the_rarity_share`) mints a Rare laser
    carrying `["ledger"]` and asserts the un-suffixed payout. The fixture's suffix
    list becomes `[]` (the row keeps proving the plain payout) and the Ledger row —
    the same sale at ×1.25 — is K3's own suite. K3 owns that edit.
  - **Everything else holds** under the two guards K0 measured: the multiplier is
    null-tolerant (F3), and no gate suite fits a computer (`STANDARD_FIT` carries none,
    `ship_fit.gd:516-559` → `damage_mult == 1.0`), so every exact-amount assertion
    listed in `S7-K0_report.md` §3 stays green.
  A builder who believes a further existing row must change reports it; it does not
  edit it.

### K0 dispositions (orchestrator, 2026-09-24, pre-K1)

`S7-K0_report.md`'s 17 findings, triaged on the escalation ladder. Bucket 2 items were
applied to this section, the brief, the prompts and `17_coder_handoff.md` §2 in one
commit before any builder ran; bucket 1 items are the workers' to decide and report;
the one owner-facing addition rides the tick list.

| finding | disposition |
|---|---|
| F1 — the summary shape cannot express the per-instance law | **applied above:** `summary` gains `&"instances"`, and the aggregation law names which shape carries which rule. |
| F2 — `projectile.gd:_deliver` is a second delivery in no set | **applied:** `game/projectile.gd` joins K2's `VAJB_WORKER_FILES`; the multiplier rides the shot's `configure` dict. |
| F4 — one existing assertion flips (Ledger) | **applied:** the tests-that-move list above; K3 edits `test_s3_instances.gd`'s fixture. |
| F5 — the Ledger term as pinned pays nobody | **applied:** all three production sites named, plus the pane's displayed row. |
| F13/F14/F15 — stale counts, the false `_profile()` sentence, §2/§3/§11 rule 2 text, the missing 17 §2 row | **applied:** §2's field list and §3's/§11 rule 2's `resolve` signature carry §20's cross-reference; `17_coder_handoff.md` §2 gains the `game/affixes.gd` row; the brief's counts are corrected to K0's measured 3 production / 36 test call sites. |
| F12b — is a ram "player-origin damage"? | **applied:** site 5 above — it is, on the pin's own "any parallel player-damage path" text; reversal is dropping that product, and the reading is named on the owner tick list (tick 6). |
| F3, F6, F7, F8, F9, F10, F11, F12, F16 | **bucket 1, recorded above as the law's own detail:** null-tolerant multiplier, Leeches' credit gate, Embers' `npc_ship` predicate, the barrel↔slot map, the raw-fit walk, Frugal's bank over L90, the beam's weighted `paid` weight, the two chip sites, and the stored-value convention (a stored `0.0` stays inert; ids convert explicitly). |
| F17 — a live game session wrote the live store during K0's pass | **harness note:** the close-out's "live store unchanged" claim is scoped to the S7 runs; the editor's own running game (D7's lane) writes it, so the figure is recorded with that attribution (L149's class). |

### K1 dispositions (orchestrator, 2026-09-24, after K1 landed 726/0)

K1 measured **726/0** twice (the tree carried **711** rows before its suite — S6's 674
plus D7's in-flight 37, `test_d7_cockpit.gd` 18 / `test_d7_armory.gd` 11 /
`test_d7_status.gd` 8 — so D7's growth is attributed, never absorbed). Its seven
judgment calls are dispositioned here; nothing was reverted.

| call | disposition |
|---|---|
| D1 — the aggregation-law bullet listed Sturdy as aggregate-readable while its own counter-example pins the per-instance sum | **this section's own error, corrected above:** only Deep-hold and Spry read the aggregate keys; K1's per-instance reading is the law and its suite asserts both numbers. |
| D5 — the pinned `has_suffix(summary, …)` parameter name costs one `SHADOWED_VARIABLE` warning | **applied:** the pin names the parameter `data`; K2 renames it in `game/affixes.gd` (a parameter rename, no caller changes — GDScript has no named arguments) and that file is in K2's set for that one edit. |
| D3 — `instances` rows align to `fitted_ids` by `base_id` | **accepted as a handoff:** K2 passes the base-id fit (`_launch_fit`) as `resolve`'s `fit`, which production already does; named in K2's prompt. |
| D2 — Deep-hold and Spry read the aggregate, the other five read rows | **accepted** (the corrected split above). |
| D4 — a cell whose id `instance()` answers is a fitted instance whatever its `count` | **accepted:** a real fit is `count` 0 and a base-keyed record with no affixes contributes nothing either way; R1 may tier it. |
| D6 — `Affixes` depends on `ShipFit` one way only (no mutual global-class reference) | **accepted** (a cyclic reference risk, and the duplicated key literals are named in both files). |
| D7 — the two pool-clamp rows ride a hand-built over-capacity summary | **accepted:** no legal fit reaches 09 §5's 3× ceilings, so the fixture is the only way to prove the clamp lands after the affixes; the suite says so. |

### K2 dispositions (orchestrator, 2026-09-24, after K2 landed 746/0)

K2 measured **746/0** three times (727 rows before its suite — K1's 726 plus one row
D7's lane added and closed in its wave-boundary commit `12278d2` — plus its own 19).
D7 closed at 13:06 the same day, so its §9/§10 pass (changelog **v0.16**, expected
`passed=727`) precedes this wave's; S7's close-out writes **v0.17** on top of it.

| call | disposition |
|---|---|
| D1 — L90 is **routed around, not fixed**: Frugal's spend/gate resolves the barrel's live slot only for a barrel whose Frugal magnitude is non-zero | **accepted** (bucket 1): a global `ammo_slot` fix would change a launched same-family battery's total rounds — a gameplay change outside this pin. L90 stays open as a LOW row with this route-around recorded against it. |
| D2/D3 — the bank is `ammo_frac[slot]` (per cell, flight state, re-seeded at both seed points); the pack is `ammo[slot]`; ≤1 round/cell unfiled at dock | **accepted as stated**, exactly §20's own reading. |
| D4 — Keen applies at shot composition on **both** paths (beam weight `Σ(1+keen)`, travelling barrel's own shot damage) | **accepted:** §20's Keen row says "at shot composition", which covers every released barrel. |
| D5 — the chip order is `amount × GUN_CHIP_RATE × damage_mult` | **accepted** (the product commutes; the order keeps the rock's work a fixed fraction of the delivered damage). |
| D6 — `EMBERS_FRACTION` is spelled in both `weapons.gd` and `player_ship.gd` | **accepted and reported:** the pin routes the two deliveries differently on purpose; both constants are documented in both files. |
| D7 — the launch summary lives in one var, `_launch_summary`, resolved once in `_resolve_stats` | **accepted as the handoff K3 reads** (or K3 re-calls `profile.affix_summary`, one line). |
| D8 — `_slot_of_barrel` walks `PlayerState.weapons` counting firing-family entries | **accepted:** it is K0 F8's map, derived from shipped data, and the family-less `w_mining` drop keeps the two counts aligned by construction. |

### K3 dispositions (orchestrator, 2026-09-24, after K3 landed 753/0)

K3 measured **753/0** twice (746 + its own 7), and the one existing-test edit is the
one this section's test-law block ratifies (`test_s3_instances.gd`'s fixture suffix
list → `[]`; its assertions untouched and green).

| call | disposition |
|---|---|
| D1 — the Ledger term lives in `Auction.sell_price`, the delegate the pin names, with the three production sites calling it | **accepted and written into the block above:** one function, three callers, one literal; `ModuleCatalog.sell_price` keeps its two-argument signature (it is in no S7 file set). |
| D2 — `PlayerProfile.sell_instance` gained one one-way preload edge on `game/auction.gd` | **accepted:** the payout must read the figure the pane shows, and the edge is one-way (`auction.gd` preloads nothing of the profile). |
| D3 — §20's "`Auction.sell_price` … no production caller" is stale | **applied:** the block above is corrected; K0's reading was pre-S7 and is now superseded by the shipped callers. |
| D4 — Leeches sits after `_spawn_kill_loot`, inside the handler's credited path | **accepted:** with no profile service the handler credits nothing, so the perk pays nothing; the suite proves the gate by asserting the credit and the heal in the same call. |
| D5 — `_spawn_sector`'s trailing `return` became an `else` | **accepted:** one call site after both entry branches, and the `return` was the function's last statement. |
| D6 — the staged set is asserted as the five staged suffix ids | **accepted:** the brief's "staged four" counted the four staged *items* (Overflowing plus the three suffix groups), and a superset assertion cannot be wrong about which were meant. |
| D7 — the Leeches/Cartograph fixtures fit a real instance through `fit_module_at` | **accepted:** the flag reaches `_launch_summary` by the shipped path, so the suite proves the integration, not just the arithmetic. |

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
- **v0.8.0 (2026-09-23, the S4 weapon-batteries docs pass — the developer session, answering
  H0's four HIGH and five MED findings before a builder started).** §16 is **rewritten**: the
  "v0.7.4 round" it shipped carried four unbuildable or self-contradictory statements, all
  measured at `file:line` in `slices/S4-weapon-batteries/S4-H0_report.md`. (1) *HIGH F1 —
  `fitted() # unchanged, per barrel`.* Today's `set_fitted` drops duplicates
  (`game/weapons.gd:369`) and `tick` fires one weapon (`:520`), so "unchanged" and "per
  barrel" cannot both hold; §16 rule 1 removes the guard (per barrel, duplicates kept) and
  rule 2 makes groups address **batteries** (`battery_ids()`, new) so every existing group
  test reads the same list. (2) *HIGH F2 — "this battery's W indices".* `WeaponComponent` is
  handed `ShipFit.fitted_ids`' flat id list (`game/player_ship.gd:1205-1206`), which carries
  no cell indices and drops family-less modules, so §16 rule 3 pins `battery()` to **barrel
  positions in `fitted()`** and states that the pane's `W1·W2·W3` labels are its own cell
  indices (measured divergence: `[w_mining, w_laser]`). (3) *HIGH F3 — "the ammo slot each
  barrel already owns".* Ammo is keyed by **family** (`game/weapons.gd:1519-1526`,
  `game/player_state.gd:84-89`), so §16 rule 5 pins one round per barrel out of the family's
  one pack (a 3-barrel laser volley spends three). (4) *HIGH F4 — STATION_HUB §5.1 vs §5.10.*
  The strip's anatomy is §5.1's and §5.1 was never amended for batteries; the designer
  session's §5.1 block is rewritten in the same pass (battery rows + the empty cells' own
  read-only lines, the row order and the ±actions' focus order). **MEDs pinned in the same
  rewrite:** rule 7 names the instance pairing (`instances_of` order, ascending cells) and
  makes the rollback atomic over **the fit and the bag** (F5/F6); rule 9 gives the refusal
  copy one home and sanctions the byte-equivalent duplicate (F7) and records the mandatory
  wording as unreachable for a W battery (F8); rule 10 keeps the strip's fixed node set
  (F15b); rule 6 pins the energy families' volley (F14); rules 3 and 5 reconcile `w_mining`
  (F15c). **Also fixed in this pass:** §13's stale `const SAVE_VERSION := 5` line now reads 6
  with the date it moved (F12), and `S4_BRIEF.md` v2 carries the corrected measure-first
  answer, the corrected `module_action` citation (F11), the corrected "the strip aggregates by
  `base_id`" claim (F10) and the repaired tests-that-move list (F9 adds
  `test_engine2_wiring.gd`, whose dedupe assertion turns red the moment `fitted()` keeps
  duplicates). **Nothing else moved:** no price, damage, cadence or ammo value, no fit shape,
  and the gate's floor is S3's measured `493/0`.
- **v0.8.1 (2026-09-23, the S4 mandatory review — S4-H3, the wave's only CONTRACTS writer
  this pass).** Records what the review measured against §16's own rules, so the rebuilt
  wave's next reader has the numbers beside the pin. **Verified as built** (every one
  re-measured, the builders' suites read as claims only; probe sources and logs archived as
  text in `slices/S4-weapon-batteries/_review_probes/`): rule 1's per-barrel `fitted()`
  (3 lasers → 3 entries, a mixed fit in fit order, the tool and the typo still dropped);
  rule 2's `battery_ids()` (first-barrel order, `[laser, cannon, rocket]` for five barrels of
  three families) and `select_group`'s clamp (3 lasers → group 1 `laser`, 2 and 3 `&""`);
  rule 3's barrel positions **and its divergence measured end to end**
  (`ShipFit.fitted_ids(["w_mining", "w_laser", ""]) = [w_mining, w_laser]` → the component
  reads `fitted() = [laser]`, `battery(&"w_laser") = [0]`, while that laser is W-cell index 1)
  — the strip's own labels come from `_weapon_cells` and read `W1·W3` for cells `[0, 2]`;
  rules 7–8's rollback **byte-compared on both branches** (Vanguard: 2 `FIT_MODULE` lines
  committed before the refusal, `fit_for` and `modules()` byte-identical after, no instance
  stranded below `count` 1; Corvette with **no stored fit**: 3 lines committed and `fits()`
  `[] → []`, the `clear_fit` branch); rule 4's volley arithmetic (3 cannons, pack 30 → 27, each
  shot `shot_damage(cannon)` 27.0, releases inside the 40 ms ceiling, the dry barrel read once
  per pull); rule 5's one pack per family; rule 6's per-barrel Energy frame (3 lasers at
  `delta` 0.1 → 1.800 Energy and 9.000 damage in **one** `_deliver`); rule 9's copy (the three
  literals byte-equal to `fitting_panel.gd:147-149`; **`13 / 11 PWR — OVER BY 2` renders through
  a battery** — reachable on exactly one hull, `ship_gunship` with 3 railguns + 2 rockets, whose
  reachable illegal set is `12/11/1 … 15/11/4`; the Vanguard can only reach `9/8/1 … 12/8/4`,
  which is why H1 measured `11 / 8 PWR — OVER BY 3`; no test asserts the mandatory wording
  through a battery); rule 10's fixed set (7 rows, **253 nodes, 36 per row**, unchanged across a
  re-grouping write and a hull switch). **AC3/L78's surviving half:** the expander reveals every
  cell with its own enabled REMOVE — pressing the third of three empties exactly W3 — and the
  empty-cell lines carry every control node hidden and disabled, so they are read-only.
  **Two deviations pinned here, both for S4-H4:** **(HIGH)** a sustained trigger fires **one
  salvo and then nothing** for every travelling family, which contradicts rule 4's own second
  half ("a sustained pull is a stream of salvos, not one burst") and removes the pre-S4 stream
  (`_arm_battery` is reached only on the rising edge, `game/weapons.gd:612`, or a mid-hold group
  switch, `:627`, and `_armed_weapon` is only cleared on release, `:672`; measured: one pull held
  3.0 s → 3 shots then 2 976 frames with none); and **(MED)** a refused bulk action leaves a
  stored fit behind on a hull that had none, because the pane's `_seed_fit`
  (`outfitting_panel.gd:1089/1112/1134`) runs before `_batch_refusal` (measured: fresh
  `ship_fighter`, no stored fit → `SWAP ALL` refused with the catch-all and `fits()` gains it).
  The finding tiers, file:line evidence and the seven LOW rows (`L123`–`L129`) are
  `slices/S4-weapon-batteries/S4-H3_review.md`. **Nothing else moved:** no price, damage,
  cadence, ammo or fit-shape value, no frozen file (`verify_wave.py verify --baseline s4_start
  --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests` → `problems: []`),
  and the live `user://` pair byte-identical before and after every probe and every gate run.
- **v0.8.2 (2026-09-23, the S4 fixer pass — S4-H4).** Records the two findings v0.8.1 left for a
  fixer, what the fix is, and what it was measured against. **§16 is untouched**: its rules and its
  as-built bullets are the developer session's, and the one inaccuracy this fix creates in them is
  reported in `.agents/gen/slices/S4-weapon-batteries/S4-H4_report.md` instead of edited here.
  **(HIGH, the review's F1 — a held trigger fires one salvo and then nothing.)** Rule 4's "a
  sustained pull is a stream of salvos, not one burst" was false as built: `_arm_battery` was
  reached only on the pull's rising edge or on a mid-hold group switch, so once the first salvo had
  released every `_armed[position]` was `-1.0` and `_release_battery`'s first guard skipped every
  barrel — the per-barrel cadence timers gated nothing after it, and the pre-S4 stream (the single
  `_shot_timer`, `f3b0d24:vajb-orbit/game/weapons.gd:527`, `:601-617`) was gone. **The fix:**
  `tick` arms the battery again on the frame its whole salvo has released (`_salvo_spent`) and for
  as long as the trigger is held, so each barrel fires again as soon as its **own cadence timer**
  allows — one timer per barrel is now what gates the stream. Two families keep one release per
  pull: a travelling `edge` row (the mine, 09 §3.1's drop, which the pre-S4 `_fire_projectile` read
  from the same flag) and a beam battery, whose open barrels keep drawing while the trigger is held
  and so have no salvo to repeat. **Measured** (the review's own stream probe re-run; source and
  log archived in the slice folder): one pull held 3.0 s → **15 shots = 5 salvos x 3 barrels**,
  ~0.6 s apart, where the review measured **3 shots and then ~2 976 frames with none**; a mine held
  3.0 s → **1 shot**; 25 x 100 ms pulses → 24 (23 pre-fix). The regression test bites: on the
  pre-fix component `test_a_held_pull_streams_a_salvo_per_barrel_cadence` reads `3 shots = 5
  windows x 3 barrels` and fails.
  **(MED, the review's F2 — a refused bulk action left a stored fit on a hull that had none.)** The
  pane's `_seed_fit` ran before the refusal preview *and* before the profile call, so a refusal
  wrote the hull's standard fit into `_fits` and the batch's own rollback — which restores to the
  state the batch started from — could not undo it. **The fix:** the preview runs first and the
  seed second, and a seed a refusal made pointless is dropped again (`_unseed_fit`), so a refused
  action writes nothing at all. **The review's alternative cure ("`_seed_fit` is redundant for all
  four of its callers") was measured and is wrong, so it was not taken**: the composed **clear**
  transactions read the module they hand back out of the hull's *stored* fit
  (`clear_fit_slot`, `autoload/player_profile.gd:911-913`), so a hull that has never been written
  refuses a REMOVE of the modules the strip is showing it — which is what the seed is for, and what
  `tests/test_p2b1_outfitting_panel.gd:679` pins (a fresh hull's REMOVE ALL empties its battery and
  banks the module). Only the refusal path changed. The regression test also bites: on the pre-fix
  pane `test_a_refused_bulk_action_leaves_no_stored_fit` fails on "the refusal left the hull
  holding no stored fit".
  **Nothing else moved:** no pinned number, no price, damage, cadence, ammo or fit-shape value, and
  no frozen file; the gate is **`passed=524 failed=0`** twice (S4's 521 plus H4's three tests), the
  live `user://` pair byte-identical before and after both runs and after the probe, and every S4
  evidence line other than the strum's and the held pull's re-runs byte-identically. The fixer's
  probe is `vajb-orbit/tests/probe_s4h4_stream.gd` (a `--script` SceneTree probe, so it is run
  under a scratch `XDG_DATA_HOME` per T-93; its text and log are archived in the slice folder).
- **v0.9 (2026-09-23, the playtest fix wave S5 — landed docs-first from the owner's ten
  findings)** — added **§17**: the auction's family tabs and the shipyard's hangar rework
  (hulls bought on the auction only, select = preview, `SET ACTIVE` commits), ammunition
  as cargo (`ammo_*`, `ROUNDS_PER_CARGO_UNIT 10`, auto-load at launch, EXCHANGE sells at
  60 %, fuel cells delisted), **batteries v2** (player-composed mixed groups on the
  renamed `ARMORY` racks `B1..B7`, `GROUPS_MAX 7`, the salvo gate = the slowest member's
  cycle, save v7) and **hardpoints + gunnery** (`ShipFit.HARDPOINTS` per hull measured
  off the renders — 09 §8's no-table rule superseded by 09 §11 — and per-barrel
  `track_dps` tracking with shots flying along the barrel's current facing). Superseded
  in passing: 09 §10's identical-only battery rule and S4's per-barrel independent
  cadence. Owner ticks ride the S5 brief (the `ARMORY` label, `ROUNDS_PER_CARGO_UNIT`,
  fire-along-facing vs hold-until-aligned, the `track_dps` taste table).
- **v0.10 (2026-09-23, the cockpit instruments wave D6 — landed docs-first from the
  owner's NMS-style request)** — added **§18**: the bottom-left instrument cluster
  (sprite speed gauge + sprite compass + five seven-segment readout rows
  SPD/HULL/SHLD/FUEL %/ENRG %) and the `ship_status`-toggled ship layout screen.
  The wave is display-only: zero new sim feeds (speed/heading ride `set_speedometer`,
  the four pools ride the existing handlers), the §3.6 gauge contract survives
  byte-identical, and per-module damage stays staged (no sim model exists). Owner
  ticks ride the D6 brief (the NMS palette reading, placement/size, hull/shield
  points vs %, the `ship_status` key, scheduling a module-damage model).
- **v0.12 (2026-09-24, the travel wave S6 — landed docs-first, amended by the
  K0 dispositions before the first builder ran)** — added **§19**:
  jump gates + fee composition, border corridors, POIs (derelicts/anomalies/
  beacons) with the scanner's soft fog, sector transitions via `loading`, heat
  enforcement + bounty payment + hunter wings, and the loot roll + wreck sites.
  Superseded in passing: §14's "hunters in slice 4" note (the owner's item-12
  grouping wins), 01 §5.2's travel ceiling (0–250 → 0–500 CR), 18_engine_spec
  §4.5/§15's quadrant turn-on (deferred to slice 4 by owner call) and ruling 24's
  `sibelon` (11 §3.2's three kinds win). Owner ticks ride
  the S6 brief (fee multiplier composition, corridor depth/interrupt rules,
  derelict scan range, rift drain, the bounty surface, the hunter hull map,
  the station turret, the hunter extra table).
  **Renumbered from v0.11** — S5-R1's entry had already claimed v0.11 in
  `db4dbcd`; this entry was the later write (`0070215`) and takes v0.12. Its
  §19 carries the K0 dispositions block (fee row 750, the additive
  `roll_band`/`roll_hunter_extra`, `ShipFit.BASE_SCAN_RANGE`, the decay
  accumulator, the 0–100 clamp, the two refusal axes, the hunter row flip,
  `heat.gd` dropped, the bounty surface's set growth, quadrants deferred, the
  `sibelon` superseded, the wreck blip kind and the real seam names).
- **v0.11 (2026-09-24, the S5 playtest-fix review — S5-R1, the wave's only CONTRACTS
  writer)** — records the wave's measured gate (**`passed=577 failed=0`**, three runs on
  three scratch stores, 49 suites, the live profile byte-identical) and the review's two
  **MED** findings against the pinned behaviour (both display/test-side; nothing in the
  sim moved): (1) the HUD's ammo/label readout resolves a selected **rack ordinal** into
  `PlayerState.ammo`, which is indexed by **barrel position** (`hud.gd:1122,1128`,
  `player_state.gd:99`), so a mixed or reordered rack shows another family's pack
  (measured: a rack of cannon+rocket reads the laser pack `111`), and keyboard `weapon_N`
  names `WEAPON_IDS[N-1]` rather than the rack's own family; (2) `test_s5_batteries_v2.gd`
  looks its HUD up as `HUD` while the scene node is `Hud` (`:45`, `:844`), so its four
  pushed-cell assertions (`:847-851`) never run — the same lookup everywhere else in the
  tree is `Hud`. The review's independent probe re-measured the pinned rules green: the
  mixed cannon+rocket rack streams at `max(cadence)` (gaps 73/72 frames at 1/60), tracking
  is per-barrel (laser 90°, rocket 30° after a 90° swing + 0.5 s), the beam cone is 5°,
  the six ammo list/sale pairs are `4/2 6/4 40/24 50/30 64/38 24/14`, the auto-load is once
  per family (30 units → 300 rounds, hold 0, a second call draws nothing), and the v7
  migration is idempotent, memory-only at load and persisted by the next write. J0's F0
  harness finding is cured (`.crush/hooks/enforce_worker_files.py` now strips the Linux
  workspace root); J0's F9 (`DRIVES` on the catalogue's `engine` key) is implemented and
  measures 3 stocked module rows. LOW rows run **L130–L140**.
- **v0.13 (2026-09-24, wave D6 close-out — the cockpit instruments wave, this
  wave's only CONTRACTS writer)** — §9 gains the D6 expected **`passed=608 failed=0`**
  (608 tests over 51 suites) with its measured history and the S6 cross-lane
  caveat. §18's digit-semantics mirror is amended by the owner's mid-wave ruling
  (SPD **4 cells clamp 9999** — "in the cockpit if all clocks are 4 digits make the
  speed 4 digits as well"; UI_SPEC §3.7 carries the law and its amendment text).
  The `ship_status` input row is applied to `project.godot` by the orchestrator at
  close-out (key **U**, the `weapon_6`/`weapon_7` precedent). D6-R1 leaves no HIGH;
  R1-MED-1 (hardpoint-marker render-space mismatch, 11 markers 133.67/64.57 px off
  the hull) is cured by F1 with a blind-test fix; R1-MED-2 (pinned 396×190 content
  vs the pinned 340×152 frame interior) is a bucket-2 pin decision routed to the
  owner. LOW rows run **L141–L149** (L142 retired by F1's cure).
- **v0.14 (2026-09-24, wave S6 review — S6-R1, the wave's only CONTRACTS writer,
  sequenced after D6's v0.13)** — §9 gains the S6 expected **`passed=674 failed=0`**
  (674 tests over 53 suites, four runs on four scratch stores, the live store pair
  byte-stable) with the K1/K2/K3 growth history and the `s6_start` cross-lane
  forbidden-hit attribution. The review leaves **no HIGH and no MED**: the three
  builders' suites (18/25/23) are green and non-tautological, the K1↔K2↔K3 seam joins
  re-measure under an independent scene probe (the transition re-populates travel +
  POIs and keeps hold/hull/heat; a real hull killed through `_on_npc_died` leaves a
  wreck site and files heat only with a witness; the destination's rings fee their own
  links), and the shipped `roll(kind, tier, seed)` is byte-identical (the wave's only
  existing test edit is `test_engine2_wiring.gd`'s derived minimap-feed row). LOW rows
  run **L150–L157**: the scene-scoped decay clock (13 §2's "anywhere" loses the minute
  in progress per crossing, <1 point, the pin's own shape), the rift's module exotic
  granted to the bag rather than spawned at the heart (11 §3.2), the uninterruptible
  paid gate jump (`Gate.cancel_jump` is dead code), the missing short-funds gate
  readout, a stale `_transit_destination` after an interrupted crossing, the gate's
  inert layer-1 `Area2D`, two doc/citation drifts (12 §4.1's superseded gate-refusal
  cell, 13 §7's `npc_registry.gd:208` → `:220`) and the `s6_start` baseline note.
- **v0.15 (2026-09-24, wave S7 docs-first — the affix-application pin, this wave's
  only pre-dispatch CONTRACTS writer)** — §20 added: the `affix_summary` bridge,
  `ShipFit.resolve`'s one optional `affixes` parameter, `ShipStats.booster_cooldown_mult`,
  `PlayerState.weapon_affixes`/`set_weapon_affixes`/`affix_flags`/`set_affix_flags`/
  `ammo_frac`, `Auction.sell_price`'s
  optional `suffixes`, the twelve-row prefix application table, and five of §4's ten
  suffixes applied (Whale, Embers, Leeches, Cartograph, Ledger) with five staged
  (Overflowing — §6 freezes the budget; Silence — 13 §3 pins no detection-time
  mechanic; Vault — no spill system; the three faction rows — no faction station can
  roll them). §20 also wires the measured-inert `ShipStats.damage_mult` into the one
  player-damage delivery (09 §3.4/§5 pinned it live) and supersedes §15's "no suffix
  term" line for `of the Ledger`. S3's owner tick 6 ("schedule or park") is answered
  by the owner's 2026-09-24 dispatch instruction ("prepare for new batch and wave of
  workers"); reversal: park the wave. §9's expected figure grows at close-out (writer
  S7-R1, **sequenced after D7's §9/§10 pass**); LOW ids continue at **L158+** (next
  free ticket **T-94**). **Amended the same day, pre-K1,** by §20's "K0 dispositions"
  block (K0's 17 findings): the summary carries one row per fitted instance, the
  multiplier's five delivery sites and `game/projectile.gd` join the pin and K2's file
  set, the Ledger term names all three production sell sites, the ram takes the
  multiplier, and the one existing assertion the term flips is ratified as an edit.
- **v0.16 (2026-09-24, wave D7 close-out — the cockpit rework + battery window,
  this wave's only CONTRACTS writer)** — §9 gains the D7 expected
  **`passed=727 failed=0`** (two scratch-store runs; the S7 cross-lane caveat
  names all five transient failures). §18 gains the as-built interface catch-up
  (compass/HDG gone, `readouts()` = {spd, hull, shield, ammo}, CockpitStyle,
  pool bars retired). The wave ships the owner-approved mockup set (cluster v7,
  battery window, game context, ship status) as built: 23 art masters (the
  glyph-only `ui_seg_*` family, three flat console plates at their ruled
  aspects, gauge face, armory plates), `CockpitStyle` (palette/layout/assets + a
  user `.tres` override), the v7 cluster, the Mockup A armory surface and the
  Mockup C status surface. Review: 1 HIGH (the status render-box clamp + its
  blind test) and 1 MED (the armory console aspect — ruled in UI_SPEC §3.10
  Amendment 2 and closed as measured) both cured by D7-F1/D7-A2; 5 LOW rows
  **L158–L162**. UI_SPEC carries the day's owner rulings with reversals: the
  compass ditch (two FUEL/ENRG dials), the full-height readout well, the
  battery lamps, the §3.1b bars retirement, the SALVO centisecond format and
  the §3.9 rule-5 modifiability contract.
- **v0.17 (2026-09-24, wave S7 review — S7-R1, the wave's only CONTRACTS writer,
  sequenced after D7's v0.16)** — §9 gains the S7 expected **`passed=753 failed=0`**
  (twice on fresh scratch stores plus once inside the verifier; `problems: []`, no
  forbidden hit) with the measured `711 → 753` attribution (D7's `faa24ad` baseline of
  711 = S6's 674 + D7's in-flight 37, D7's close-out `+1`, S7's three suites `+41`) and
  the live-store pair recorded with the note that its 13:37 rewrite is not this wave's.
  **The review leaves no HIGH and no MED.** Everything §20 pins was re-measured against
  the tree with the reviewer's own probes (130 checks, 0 failures) and a pre-wave
  worktree A/B: the summary's stored signs, one row per instance and once-per-perk
  flags; all twelve prefix rows worked, including the K0 F1 counter-example (+80, never
  +150) and the same-base duplicate alignment; 09 §5's three clamps with the affixes in
  place (speed floor 180.0, pool 3000 → 2700, hull 7250 → 6600, engine sum 1.418 →
  1.40); `{}`/no-third-argument **byte-identical** to the `faa24ad` tree across the nine
  standard fits and five hand-built ones; per-barrel Keen/Rapid isolation and Frugal's
  `floor(20 × 0.85) = 17`; `damage_mult` exactly once at all five sites with a value
  that would be wrong if it landed twice (35.7075, not 41.063625) and 1.0 with no
  computer or with a null snapshot; Spry's 8.0 → 6.8; Embers NPC-only on both
  deliveries (the delivered amount, 23.0), Leeches' credited kill (1050 → 1112.5),
  Cartograph's one `reveal_pois` (0 fogged), Ledger's 540 → 675 at the displayed row,
  the quote and the payout (and integral over every catalogue row); the staged five
  byte-identical in resolve and price; the launch's barrel→slot alignment through a
  real `game.tscn` (a family-less `w_mining` cell in front of a Keen laser still reads
  slot 1); and no pin drift (§15/§16 byte-identical to `faa24ad`; §11's only change is
  §20's additive cross-reference). Five LOW rows are **L163–L167** (the five new
  `position` shadowing warnings in `game/weapons.gd`, 29 → 34; `EMBERS_FRACTION` spelled
  in two files; the pane's idle 60 % copy beside a Ledger row at 75 %; the Ledger
  line's integer-division warning; and the brief's `L158+`/`v0.16` ids that D7 had
  already consumed, rebased here to `L163+`/`v0.17`). The five owner ticks S7 owes
  (§20) stand unchanged, with the readings this pass measured beside them.
