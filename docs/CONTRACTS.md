# CONTRACTS.md — living interface contract

**Status: v0.1 (engine wave 1 + engine slice 0, 2026-09-21).** This file is the single source of pinned interfaces
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

Code defensively: `InputMap.has_action(&"warp")` / `&"interact"` /
`&"consume_fuel_cell"` guards — the actions land in `project.godot` after the
wave, never hand-edit the file. **Measured 2026-09-21 (M6 re-review):** all three
are in the map — `interact` F, `warp` H, `consume_fuel_cell` **R** (keycodes 70 /
72 / 82) — and `cargo_toggle` still C (keycode 67). The hull-side caller landed
with the fixer pass, so a real R key event reaches
`PlayerState.consume_fuel_cell` exactly once per press (M4 finding F5 closed).

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
```

`fit_ids` is the launched fit's module ids (`ShipFit.fitted_ids`), the W-slot gate
for the mining laser; it is defaulted, so `setup(stats, state)` still resolves.
The four seams are how slice 2's weapons, detonations and the §3.4 speed fantasy
reach the body without touching the node tree.

**Body (slice 0, ruling 8).** `HullBody` is a `RigidBody2D` (layer 2, mask 1 = the
rock layer, `gravity_scale = 0.0`, `contact_monitor = true`,
`max_contacts_reported = 4`, `can_sleep = false`, `linear_damp_mode` /
`angular_damp_mode` = REPLACE). The body owns momentum and the live transform; the
ship node mirrors it (`_sync_hull_transform`), so the sprite, the camera and the
laser stay with the hull. Thrust is `mass × the class acceleration`
(`max_speed / accel_time`), the brake is `BRAKE_MULT ×` that, the coast is
`max_speed / coast_time` with `linear_damp = 1 / coast_time`, and torque is
`inertia × (alpha + angular_damp × omega)` with `inertia = m·r²/2` and
`angular_damp = 1 / turn_spinup` — all derived from §13, nothing retuned.
Body-body contacts past `COLLISION_MIN_DV` charge `Impact.collision_damage(ship
mass, peer mass, closing speed)` to the player through `PlayerState.damage`, and
offer the peer's half to `apply_collision_damage(amount)` when the peer has it.

Flight (ENGINE_SPEC §3): WASD throttle/turn (S = reverse thrust + active brake at
`BRAKE_MULT` 1.8), angular spin-up/damping, linear coasting — constants arrive via
`ShipStats`, no literals in movement code. Autopilot: LMB on empty space sets a
move target, arrive steering (slow-down radius 240 u, arrive radius 40 u), the
same physics; **any** thrust/turn input cancels it, firing does not. Boosters:
`boost` = afterburner (+60 %, 3 s, 8 s cooldown) reading `ShipStats.boosters`;
blink/fold (`b_fold`) is recognised as data and inert.

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
eject_velocity() -> Vector2      # linear_velocity × 1.2, read before the free (slice 0)
world_radius() -> float          # the collision circle's radius
signal cracked                   # bare, unchanged: the field binds the rock itself
```

The body (slice 0, ruling 8): mass = `ROCK_MASS_MULT` 4 × the §13 `hull_mass` of
`ROCK_MASS_REFERENCE` `ship_miner` = 560 t, `linear_damp` 3.71 with REPLACE mode,
`gravity_scale` 0, `can_sleep = false`, layer 1 / mask 0 (so rocks do not collide
with each other). The size class is a look *and* the cleaving class:
`FRAGMENT_SPLIT` L (2,3) → M, M (2,2) → S, `PICKUP_BURST` (1,2) for an S, ejection
`× 1.2` inside a ±15° cone, fragment mineral **and tier** inherited from the parent
with the yield re-rolled through the 02 §5 path (the §13 row and §12 item 12 are
law; §6's "re-rolled tier" parenthetical is not representable, since a mineral
fixes its tier). `AsteroidField` does the spawning on `cracked`, so fragments are
field members from birth and count toward `rocks()`/`is_depleted()`.

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
they move into the scene. `set_speedometer`/`set_lock_progress` remain slice-2 W5
scope and are deliberately **not** documented here.

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

## §9 Universal test gate

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200
```

Expected: `[SUMMARY] passed=78 failed=0`, exit 0, no `SCRIPT ERROR`. A wave is
done = gate green + the worker added tests for their slice. The suite held **53**
tests through engine wave 1; engine slice 0 adds `tests/test_engine2_pools.gd`
(**16**) and `tests/test_engine2_cleaving.gd` (**9**), so the total is **78** and
the count to read is the measured one with zero failures — never a stale total.
**Measured 2026-09-21 (M6 re-review, three runs): `passed=78 failed=0`, exit 0, no
`SCRIPT ERROR`.** The wave's one red was `test_p1_profile.gd:204`, the wave-1
assertion that a write persists `save_version 2`; it now expects **3**, the value
slice 0's mandated bump writes, and that single line is the file's only change
(M4 finding F1, fixed). **Known trap:** headless `--check-only --script` cannot
resolve autoload singletons — never use it as a gate; use scene runs or `load()`
probes.

## §10 Changelog

- **v0 (2026-09-18)** — seeded from the engine wave-1 pinned interfaces
  (evidence: `.agents/gen/engine_wave1_w1_report.md`) +
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
