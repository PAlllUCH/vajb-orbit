# CONTRACTS.md — living interface contract

**Status: v1.2 (engine wave 1 + engine slices 0 and 2 + the combat/collision repair wave, re-reviewed 2026-09-21).** This file is the single source of pinned interfaces
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
`angular_damp = 1 / turn_spinup` — all derived from §13 **with one owner-sanctioned
exception: `coast_time` is retuned ×0.50** (all nine `ShipFit.HANDLING` rows, owner
ruling of 2026-09-21; §13 itself is not ticked and still carries the pre-retune
column). Measured by the C3 flight-decay probe on the shipped launch, whose resolved
row is `§13 × 1.05` (the launched `h_plate_light` penalty), so `coast_time` is
1.050 s: time to 10 % of the release speed `1.890 → 0.945 s`, carried distance
`430.32 → 216.85 u`, and both accelerate legs unchanged (`t_accel_total` 2.533 / 2.100
/ 4.050 / 4.050). The same column also halves every NPC hull's coast and doubles its
damp (it reaches them through `ShipStats`), which is ruling 3's own "all nine rows",
not drift. Reversal: multiply the nine rows by 2.0 and re-run the probe. Nothing else
from §13 moved.
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
class is a look *and* the cleaving class:
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
set_fitted(weapon_ids: Array[StringName]) -> void   # module ids and weapon ids both land
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
retarget(decoy: Node2D) -> void                  # §4.6's half
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
```

Expected: `[SUMMARY] passed=236 failed=0` (re-measured on this host 2026-09-21),
exit 0, no `SCRIPT ERROR`. A wave is
done = gate green + the worker added tests for their slice. The suite held **53**
tests through engine wave 1; engine slice 0 added `tests/test_engine2_pools.gd`
(**16**) and `tests/test_engine2_cleaving.gd` (**9**), engine slice 2 added six
`tests/test_engine2_*.gd` suites — `weapons` (**29**), `npc` (**28**), `damage`
(**20**), `hud` (**19**), `loot` (**13**) and `wiring` (**13**) — the slice-2 fixer
pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
`tests/test_engine2_dock.gd` (**2**), the UI-chrome wave added
`tests/test_ui_slot_layout.gd` (**7**), and the combat/collision repair wave added
`tests/test_engine_c3_flight_decay.gd` (**3**) and `tests/test_combat_repair_c5.gd`
(**7**), so the total is **236** (the 226 measured before the repair wave, plus its
10) and the count
to read is the measured one with zero failures, never a stale total. Discovery is
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
  `.agents/gen/slice2_review_report.md`; LOW items: `.agents/gen/LOW_BACKLOG.md`
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
  `.agents/gen/c6/`; the wave's LOW block is `.agents/gen/LOW_BACKLOG.md` L38–L47.
