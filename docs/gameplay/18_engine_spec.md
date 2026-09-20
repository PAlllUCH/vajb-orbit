# Vajb Orbit — Engine Spec (flight, combat, mining, NPCs, sectors)

**Status:** design locked by the owner 2026-09-18; ready to slice into coder waves.
**Location note:** the owner moved the coder-facing copy into `docs/gameplay/` as
**doc 18** on 2026-09-20; the workspace root keeps only `AGENTS.md` (all other
root `.md` files moved into `docs/` or were absorbed by this spec). The batch-2
playtest list is `19_testing_notes.md`.
**How to use:** coders read §1–§2, then their slice in §14, numbers in §13,
amendments in §12. Docs 01–17 stay the source of truth for every number they
already own; this spec only adds what the engine needs.

---

## 1. The engine in one breath

Launch → fly (hybrid controls, mass-scaled inertia) → mine rocks, fight or
avoid NPCs, collect pickups → dock at a station, or safe-warp home when
nothing is engaged. Death docks you (14 §3). Everything the station loop
does with ore, components and credits gains its source here.

## 2. Decisions locked this session (owner rulings)

| # | Decision |
|---|----------|
| 1 | **Controls: hybrid.** WASD always available; clicking empty space sets a fly-to order that any manual input cancels. Mass-scaled inertia — "the heavier the ship the more noticeable". |
| 2 | **Weapons: families × cursor aim.** All guns fire toward the cursor; the lock only marks (HUD, rocket homing). Energy = instant, shields-first. Kinetics = travelling bolts, bypass shields. Rockets = homing, destructible, flight time. Mines = dropped. |
| 3 | **Exit: hardcore + safe warp.** While an enemy is engaged there is no escape button — fly to a station or gate. Safe warp only when no enemy is engaged: a few-second channel with an animation, landing docked at the current sector's station; no station in the sector → no warp. |
| 4 | **Sectors: same size, different identities.** One arena size for all; they differ by backdrop/palette, owning faction, resource tier mix (11 §1.1), enemy mix and density, hazards. |
| 5 | **NPCs: six archetypes** on one shared brain (pirate, patrol, trader/convoy, hunter wing, station turret, boss). |
| 6 | **Mining: laser primary, guns secondary.** Regular weapons can also break rocks, at 10 % efficiency vs the mining laser. |
| 7 | **Death: cargo drops.** Cargo spawns as pickups at the wreck with a 5-minute recovery window; hull/fit follow 14 §3 insurance. |

### 2.1 Owner rulings 2026-09-20 (physics & visuals brainstorm)

Second session of rulings, from the owner's `PHYSICS_SPEC.md`/`GRAPHICS_IDEAS.md`
drafts (both absorbed into this spec, STYLE_BIBLE, FX_SPEC and UI_SPEC — the
root copies are deleted once these sections landed). Rows amend decisions 1–7
where they overlap; §12 carries the doc amendments, §13 the numbers.

| # | Decision |
|---|----------|
| 8 | **Physics body: real.** The hull migrates to a `RigidBody2D`-based simulation (thrust forces, torque, mass). Migration is its own wave and runs **before slice 2** (§14 slice 0). The §3.2 inertia semantics (accel/coast/turn-spinup feel, autopilot obeying the same physics) are preserved by deriving forces from mass × acceleration — no teleporting, no second movement system. |
| 9 | **Dash = fold.** The `b_fold` module IS the doc's Hyperdrive Dash: 400 u displacement, burns **25 fuel** per burst, grants **0.8 s invulnerability** during the dash, 20 s cooldown stands. Afterburner keeps its locked +60 %/3 s/8 s shape and gains a fuel burn. |
| 10 | **Dual pools.** Energy = rechargeable buffer (weapons, mining, active systems). Fuel = consumable reserve (boost, dash). Both live in `PlayerState`, both show on the HUD. |
| 11 | **Fuel bill: burn on demand.** Fuel only drains while energy is being *spent* (the reactor converts fuel→energy at a fixed toll) and on boost/dash direct burn. Coasting and idling are free. Travel is cheap; combat eats the tank. |
| 12 | **Weapon draw split.** Only energy weapons drain Energy; guns use ammo packs; rockets use missile packs; the mining laser is energy-based and drains Energy while beaming. |
| 13 | **Refuel both ways.** Stations sell fuel for CR (14 amendment) and `fuel_cell` cargo items convert to tank fuel in flight — the emergency jerry can. |
| 14 | **Emergency Flight Mode, as harsh as written.** Fuel 0 → boost and dash locked out, reactor runs at ×0.7 efficiency, thrust disabled: drift-only flight, reaction-wheel turning only. |
| 15 | **Crash damage, always.** Every body-body impact past a low threshold deals kinetic damage to both sides: `damage = 0.5 · mass · Δv² · factor`. |
| 16 | **Push physics, all of it.** Recoil on every shot, impact knockback (40 % of remaining kinetic energy), explosion shockwaves with `I(d) = P₀ / (1 + d²)` over a 0.2 s window. |
| 17 | **Asteroid cleaving + mining.** Depleted rocks split L→2–3 M→2 S; smalls burst into resource pickups. Guns *chip* rocks toward depletion but never extract ore — the mining laser keeps the extraction monopoly. |
| 18 | **Speed fantasy, full package.** Screen-space directional motion blur, camera pull-back and counter-velocity dust streaks all key off the velocity ratio at ≥ 70 % max speed (FX_SPEC §5). |
| 19 | **Radial speedometer.** The HUD gains a 10-segment radial speed dial with a cyan prograde needle (actual velocity) and a white heading marker (facing) — the hybrid-flight readability widget (UI_SPEC §3.6). |
| 20 | **Damage visuals, all three.** Hull < 25 % spawns trailing smoke + arc sparks; shield hits flash a hex ripple; shield to 0 fires a one-shot glass-shatter burst. |
| 21 | **Timed lock.** Locks need 1.2 s of uninterrupted line of sight; passive radar auto-tags signatures within 1 500 u. |
| 22 | **Countermeasures in slice 2.** Chaff breaks locks with ghost signatures for 3 s; flares lure heat-seeking rockets; the rocket family is the first seeker. |
| 23 | **Directional armor, full quadrants in slice 3.** Four armor quadrants (prow/stern/port/starboard), rear-arc hits ×1.6, breach malfunctions (RCS drift, engine flicker). The damage pipeline carries `direction` from slice 2 so the retrofit is data-only (§4.5). |
| 24 | **Aliens: all three families.** Swarmer/Sibelon/Apex palettes are sanctioned art (STYLE_BIBLE §2.5); slice 2 ships **human pirates AND alien swarmers** as the first hostiles; Sibelon is slice-3, the Apex boss slice-4. |
| 25 | **Nebulae, full effect.** Gas clouds tint hulls and degrade radar/lock while inside — environmental cover (§8). |
| 26 | **Speed numbers: the brainstorm doc is law.** The §13 handling table gains the doc's speed/turn-rate columns mapped onto the nine 08 classes; the mapping needs the owner's tick before slice-0 tests bake it (§13 speed table v2, §16). |

## 3. Flight

### 3.1 Control scheme (hybrid)

- **W/S** throttle (S = reverse thrust, which doubles as the active brake),
  **A/D** turn.
- **LMB on empty space** = fly-to order (autopilot). **LMB on a hostile hull**
  = start the lock channel (timed, §4.1). **Q** (`target_next`) cycles locks. **ESC** cancels the order and
  the lock (this retires the current ESC-docks-anywhere placeholder).
- **Firing does not cancel** a fly-to order; any thrust/turn input does.
- **`interact` (F)** answers world prompts: dock at a station, confirm a gate
  jump.
- Camera: smooth follow + mouse-wheel zoom 0.70–1.50 (already shipped).

### 3.2 Inertia model (mass-scaled — the owner's core flight wish)

- **Linear inertia.** Velocity chases `throttle × max_speed` with the class's
  `accel_time`; with no input, speed decays over `coast_time` (heavy classes
  glide noticeably, light ones settle fast). S-thrust brakes at
  `BRAKE_MULT ×` the acceleration rate, so stopping hard costs attention.
- **Angular inertia.** Turn rate spins up over `turn_spinup` and damps down
  the same way — heavy hulls arc into turns and overshoot, light hulls snap.
- **The autopilot obeys the same physics.** Arrive steering: desired speed
  scales down with distance (slow-down radius), thrust and brake use the same
  accel/coast model. No teleporting, no second movement system.
- **Boosters** (B slot, 09 §3.5): afterburner via the existing `boost` action
  (+60 % speed 3 s, 8 s cooldown, burns fuel while active — §4.4);
  **fold = Hyperdrive Dash** (ruling 9): a 400 u displacement burst that burns
  25 fuel and grants 0.8 s invulnerability, 20 s cooldown, with a charge FX.
- **Mass sources.** Hull class (handling table, §13) + armour plating, which
  multiplies handling times by `1 + |its speed penalty|` on top of its 09 §3.3
  speed cost (plating = slow *and* ponderous). Engines buy it back: `e_ion`
  ×1.15 speed, `e_vector` ×1.25 speed / ×1.20 turn.

### 3.3 Stats source

Flight reads **only** the `ShipStats` resolved by `ShipFit` (§9). No catalogue
reads, no formula soup in movement code.

### 3.4 Speed fantasy (visual flight feedback, ruling 18)

- **Onset:** every element scales on `speed_ratio = |v| / v_max`, active from
  0.70 (`FX_BLUR_ONSET`).
- **Motion blur:** screen-space `ColorRect` shader on a `CanvasLayer`;
  `blur_strength` clamps 0.1 at cruise → 0.8 during a dash; `blur_direction =
  v / |v|`; chromatic aberration scales with strength. Shader + inputs are
  specced in FX_SPEC §5.
- **Camera pull-back:** the flight camera's zoom is multiplied by
  `lerp(1.0, 0.82, (speed_ratio − 0.7) / 0.3)` — it stacks with the wheel zoom,
  never replaces it.
- **Dust streaks:** a subtle `GPUParticles2D` on the camera emits micro
  streaks opposite the velocity vector while `speed_ratio` is high — the
  immediate "I am moving" read.
- All of it is *feedback*, not physics: zero gameplay numbers live here.

## 4. Combat

### 4.1 Weapon families (amends 09 §3.1: it gains `family` + `shield rule`)

| Module | Family | Aim | Travel | Shield rule | Notes |
|--------|--------|-----|--------|-------------|-------|
| `w_laser` | energy | cursor | instant | shields first; no hull damage while shield > 0 | 30 DPS |
| `w_plasma` | energy | cursor | instant | shields first | 70 DPS; +25 % to hull once shields are down ("melts armour") |
| `w_cannon` | kinetic | cursor | bolt 1000 u/s | **bypasses shields** → hull | 45 DPS, burst cycle (0.35 s on / 0.25 s off) |
| `w_railgun` | kinetic | cursor | slug 1400 u/s | bypasses shields → hull | 60 DPS; 09's "ignores 50 % armour" line is **retired** (armour is hull points, there is nothing to ignore — see §12) |
| `w_rocket` | missile | lock + cursor launch | homing, 2.2 rad/s turn, 900 u/s | bypasses shields → hull | 180 alpha per rocket, 1.2 s interval; **destructible in flight** (any weapon hit kills it) |
| `w_mine` | deployable | drop | static | bypasses shields → hull | arms after 2 s; proximity trigger 60 u |
| `w_mining` | tool | cursor | beam | rocks only | see §6 |

- Energy shots resolve instantly at the cursor's ray point (circle hit test),
  capped at the weapon's range.
- Kinetics travel and fizzle at max range; leading the target is the skill.
- Rockets require a lock to home; without a lock they dumb-fire at the cursor.
- **Power draw (ruling 12):** energy weapons drain Energy per second of fire
  and the mining laser while its beam is on (rates in §13); cannons/railguns
  spend the gun ammo pack, rockets the missile pack, mines their own pack —
  all per §4.3. Kinetic weapons drain no Energy.
- **Lock is marking only, and timed (ruling 21):** clicking a hostile inside
  lock range starts a `LOCK_CHANNEL` (1.2 s) line-of-sight channel — rocks and
  hulls block it — shown as a progress ring on the reticle; the lock lands
  when the channel completes. Passive radar auto-tags signatures within
  `PASSIVE_RADIUS` (1 500 u). Lock range = the scanner's range (§9), which
  gives `c_scanner` a combat job. Countermeasures: §4.6.

### 4.2 Damage pipeline

1. `damage(amount, bypass_shield)` extends `PlayerState.damage` (§12
   amendment): if not bypass and `shield > 0`, the shield absorbs up to its
   current value with **no carry-over**; otherwise hull takes it.
2. Shield regen: base **2/s**, S modules add per 09 §3.2 (`s_light` +4,
   `s_heavy` +5, `s_ion` +9); regen resumes after **4 s** without incoming
   damage.
3. Hull ≤ 0 → death flow (§7).
4. Feedback: shield flare vs hull sparks distinguish the family that hit you;
   hit markers on the reticle; no floating numbers in v1.
5. **Direction & impulse context (rulings 15/16/23):** the damage call gains
   an optional context — `damage(amount, bypass_shield := false, ctx := {})`
   where `ctx` carries `direction` (impact bearing relative to the target's
   heading), `impulse` (a force already applied by the caller) and `family`.
   Slice 2 populates it everywhere damage is dealt; slice 3's quadrants (§4.5)
   read only the `direction` key — the retrofit is data-only.
6. **Collision damage (ruling 15):** a body-body impact applies
   `damage = 0.5 · mass_a · mass_b/(mass_a+mass_b) · Δv² · COLLISION_FACTOR`
   to both sides (§13; the reduced-mass form keeps the formula symmetric),
   with a `COLLISION_MIN_DV` floor so light bumps stay free.
7. **Recoil & knockback (ruling 16):** firing applies
   `Recoil_Force = projectile_mass · muzzle_velocity` opposite the muzzle;
   a hit transfers 40 % of the projectile's remaining kinetic energy to the
   target along the impact line (`KNOCKBACK_FRACTION`).
8. **Explosion pressure (ruling 16):** every detonation applies
   `I(d) = P₀ / (1 + d²)` as an outward impulse over `EXPLOSION_WINDOW`
   (0.2 s) to every rigid body in range — the shockwave is physics, the
   AnimatedSprite2D bloom is only its face.

### 4.3 Ammo

- Per-weapon packs stay profile-owned (`profile_changed &"ammo"`); `PlayerState`
  seeds at launch and **files the shot deltas back on dock** (same pattern as
  vitals, 01 §6). Railgun shares the cannon pack in v1 (09 §3.1 note).
- `weapon_1..5` selects a group; **Space** (`fire_primary`) fires it; `E`
  (`mine`) fires the mining laser whenever it is fitted, convenience only.
- Mining laser spends no ammo. Empty pack = dry-fire feedback, no shot.

### 4.4 Energy & fuel — the reactor chain (rulings 10–14)

Two pools, one chain. The **reactor** converts Fuel into Energy at a fixed
exhaustion-less ratio; high-thrust maneuvers bypass the buffer and burn Fuel
directly.

- **Pools (PlayerState, seeded at launch, persisted — §12 item 13):**
  `energy` (max from `ShipStats.energy_max`, base 100) and `fuel` (max from
  `ShipStats.fuel_max`, base 200). Signals `energy_changed`/`fuel_changed`
  mirror the hull/shield pair.
- **Regen:** the reactor refills Energy at `energy_regen` (base 5/s) whenever
  energy was spent — no idle draw, no free regen while nothing runs.
- **The fuel toll (ruling 11):** every 1 point of Energy spent burns
  `FUEL_PER_ENERGY` (initial 0.10) Fuel from the tank through the reactor.
  Boost burns `BOOST_FUEL` (3.0/s) directly while active; the dash burns
  `DASH_FUEL` (25) per burst. Coasting and idling burn nothing.
- **Weapon draw (ruling 12):** `w_laser` 6 E/s, `w_plasma` 10 E/s of fire;
  the mining laser 5 E/s while beamed; kinetics/rockets/mines draw nothing
  (they spend packs). All initial — §13, playtest-tunable.
- **Emergency Flight Mode (ruling 14, as harsh as written):** fuel at 0 →
  boost and dash lock out, thrust input is ignored (drift-only), turning via
  reaction wheels only, and the reactor runs at ×0.7 — `energy_regen` is
  multiplied by the penalty. The HUD banner fires (§10). Burning a fuel cell
  ends the mode immediately.
- **Refuel (ruling 13):** docking files the fuel report with the damage
  report (01 §6 pattern); the station's **refuel** service buys missing fuel
  for CR (rate in §13, 14 amendment); **recharge** tops the Energy pool
  instantly at a nominal fee. In flight, the `consume_fuel_cell` action (C,
  §11) converts one `fuel_cell` cargo item into `FUEL_CELL_UNITS` (40) tank
  fuel, 10 s cooldown.

### 4.5 Directional armor & malfunctions (ruling 23 — slice 3 scope)

- The hull divides into four quadrants — prow, stern, port, starboard — each
  with its own armor pool fed by the fit's plating. The §4.2 item-5 `ctx`
  routes each hit by `direction` from slice 2; slice 3 turns it on.
- **Stern vulnerability:** damage taken from the rear arc (160°) is ×1.6.
- **Breach malfunctions:** when a quadrant's armor reaches 0: **RCS drift**
  (random rotational torque every 2 s) from a stern breach, **engine
  flicker** (15 % chance to ignore a thrust input) from a prow breach;
  port/starboard breaches clip the turn rate on that side until repaired.
- Repairs panel gains per-quadrant lines once the pools exist (14 pointer).

### 4.6 Countermeasures (ruling 22 — slice 2 scope)

- **`cm_chaff`:** one-shot item; on use spawns 3 ghost signatures drifting
  from the ship for `CHAFF_WINDOW` (3.0 s). Active locks break immediately
  and cannot re-acquire the real hull while ghosts live; the minimap shows
  the ghosts as flickering dim blips (§10).
- **`cm_flare`:** one-shot item; lures seeker projectiles — any homing
  rocket inside `FLARE_LURE` (450 u) retargets the flare and detonates on it.
- Both enter the 06 loot tables (W0 transcription) and the station shops in
  a later P pass; slice 2 ships the mechanic + loot, not the shop UI.
- The rocket (`w_rocket`) is the first heat-seeker: its §4.1 homing runs on
  the lock target, and a live flare overrides that target.

## 5. NPCs — six archetypes, one brain

One `NpcBrain` state set for all hulls: **Idle → Patrol/Scan → Alert (LOS
check, rocks block) → Engage (hold preferred range, strafe) → Flee → Return/
Despawn**. Leash radius to the spawn POI; aggro clears when the player leaves
the radius for `AGGRO_COOLDOWN` (which enables the safe warp).

| Archetype | Faction | Behaviour | On death |
|-----------|---------|-----------|----------|
| Pirate | none | guards asteroid fields/wrecks; engages anything in radius; flees below 30 % hull | 06 tables; killing = −3 heat, +1 standing in the local faction's space (13 §4) |
| Patrol | sector owner | ignores Clean players; scans Suspect+ (20+) on sight; attacks Outlaws (80+) and defends faction ships | no loot; killing = +25 heat, witness rule (13 §2/§5) |
| Trader / convoy | none | flies fixed route; flees from Suspect+; convoy = 1 hauler + 1–2 fighter escorts | 06 freighter table + visible cargo pods; killing = +15 heat if witnessed |
| Hunter wing | faction | spawns on Wanted (50+) at the player's next sector entry; 2–3 hulls tuned to the player's fit value (13 §6); Outlaw = perma-tail, respawn 60 s | 06 band + `comp_elec`-weighted extras (13 §3) |
| Station turret | station owner | static, high damage; meanest at Choir stations; aggro on attack | +25 heat; turret aggro until scan range clears |
| Boss | arena | scripted, physical location, contract-gated (14 §5); P4/slice 4 | 14 §5 payouts |

- **Spawn model (v1):** the sector populates on entry from `sector_registry`
  densities; local respawn happens on the 20-minute clock. No off-screen
  simulation, no roaming drifter management.
- **Aliens join in slice 2 (ruling 24):** the `swarmer` archetype ships on
  alien hulls (STYLE_BIBLE §2.5 palettes, chitin-green bioluminescence) with
  pirate-like behaviour — it reuses the one brain, hostile to everything.
  The `sibelon` (anomaly entity, slice 3) and the `apex` leviathan boss
  (slice 4) are coded as seams and shipped empty. Alien art is the graphics
  designer's current lane; W3 wires sprite paths swap-ready and runs on
  placeholder art until the alien sheets land — the behaviour probes never
  gate on art.
- Traders flee on the `flee` state, pirates on the hull threshold — both make
  "letting a witness live" a real decision (13 §5).

## 6. Mining

- **Mining laser** (`w_mining`, W slot, 09 §4.5): cursor-aimed beam, range
  220 u. Each `MINE_CYCLE` (1.2 s) on a rock converts 1 ore unit → spawns a
  **floating pickup** of that rock's mineral (02 §7).
- **Guns on rocks (ruling 17):** weapons apply work at **10 %** of their
  DPS-equivalent rate toward rock *depletion* only — they chip, crack and can
  cleave a depleted rock, but **never extract an ore unit**; the mining
  laser's MINE_CYCLE keeps the extraction monopoly. No heat, no standing
  effects (rocks are not ships).
- **Rocks are solid:** ships collide with them, they block shots and beams
  (cover, §5) and take chip work from any hit.
- **Asteroids — tiered cleaving (ruling 17):** on depletion, a Large rock
  spawns 2–3 Medium fragments, a Medium 2 Small, and a Small bursts into
  1–2 resource pickups of its mineral (02 §5 mineral per fragment — the
  children inherit a re-rolled tier); fragments eject at
  `current_velocity × 1.2` plus a random ±15° cone. A yield-0 rock still
  cracks and despawns without fragments. Field respawn 20 min + the ×0.7
  diminishing window (02 §8) is unchanged; fragments belong to the same
  field count.
- **Pickups:** tractor range/speed base values in §13; `u_salvage` doubles
  range and speed, `u_tractor` adds +1 pickup stream; uncollected pickups
  despawn after 60 s (02 §7).
- **Hold full:** further pickups drift, no auto-sell, no jettison (02 §7);
  HUD shows the full state.
- **Cargo identity:** per-mineral via `PlayerProfile.add_cargo` (02 §7.5).
  Loot from kills uses 06 tables; credit caches pay on pickup and log per
  01 §7.

## 7. Exit, death, travel

- **Docking:** fly into the station's dock zone → prompt `F` → loading
  screen → station (files the damage report **and the fuel report**, 01 §6;
  seeds vitals on next launch — unchanged).
- **Gates:** enter the ring → confirm prompt with the fee (11 §2.1) → 2 s
  charge FX → loading → destination gate.
- **Corridors:** hold course inside the marked zone for 15 s → transition
  (11 §2.2). Pirates ambush here more often (spawn bias).
- **Safe warp:** available only when **no hostile is engaged** — no hostile
  in Alert/Engage targeting the player **and** no damage taken in the last
  5 s. Channel `WARP_CHANNEL` = 3 s with a charge FX; breaks on damage or new
  aggro. Completion → docked at the current sector's station. No station in
  the sector → the action reports unavailable (S7 stays hardcore).
- **Death:** hull 0 → explosion → the wreck spawns with cargo pickups (5-min
  recovery window; see §2.7), then the 14 §3 flow: respawn docked at the last
  station visited, insurance decides what comes back, mercy clause once per
  profile, heat persists.

## 8. Sectors and spawns

- **One arena size** for all sectors (§13 `SECTOR_SIZE`), same layout budget:
  fields, wrecks, anomalies, beacons, gates, station(s) near centre. Sectors
  are differentiated by **backdrop/palette, owner, tier mix (11 §1.1),
  enemy mix/density, hazards** — never by size.
- **On entry, spawn:** 4–8 asteroid fields (6–12 rocks each), 1–3 wreck fields
  (3–6 hulks + 1 scannable derelict), 1–2 anomalies, nav beacons (1/corridor +
  1/gate), 1 primary station + 0–1 outpost, pirates per 13 §4 density,
  patrols in faction space, 1 convoy per inhabited sector, the sector's gates
  and corridors.
- **Respawn:** POIs and fields re-roll on the single 20-minute `WorldClock`
  (17 §4); derelicts and anomalies are one-shot per cycle (11 §3.1/§3.2).
- **Minimap:** blip classes grow to friendly (stations, gates, beacons) /
  neutral (derelicts, convoys, scanned anomalies) / hostile (pirates,
  hunters, **swarmers**); soft fog per 11 §3.3 — nothing hidden that matters,
  unexplored sectors show only stations and gates. Chaff ghosts render as a
  dim flicker kind (§4.6).
- **Nebula gas clouds (ruling 25):** 0–2 per sector as a hazard; a
  desaturated blue-grey/teal wash that tints hulls passing through and
  degrades radar and lock channels inside — passive tags inside a cloud
  refresh slowly and a lock channel cannot complete while its LOS crosses
  the cloud. One per-sector registry flag + a cloud POI; the fog visuals
  follow STYLE_BIBLE §7.2 (no new palette).

## 9. Upgrades interface — `ShipFit` / `ShipStats`

- `game/ship_fit.gd` (`class_name ShipFit`, planned in 17 §2) lands **with
  slice 1 in reduced form**: `resolve(hull_id, fit) -> ShipStats` implementing
  the 09 §5 resolution order. v1 fit = the 09 §7 standard fit; P2 later adds
  the fitting UI and full catalogue — the interface does not change.
- `ShipStats` fields: `max_speed`, `accel_time`, `coast_time`, `turn_rate`,
  `turn_spinup`, `hull_mass`, `hull_max`, `shield_max`, `shield_regen`,
  `damage_mult`, `lock_range`, `scan_range`, `tractor_range`, `tractor_speed`,
  `tractor_streams`, `cargo_max`, `energy_max`, `energy_regen`, `fuel_max`,
  `boosters` (ids). Mass and the power pools enter with slice 0; hull mass
  feeds inertia and the collision formula, and is a §13 class column.
- `game.gd`/`player_ship.gd` apply the snapshot at launch: `PlayerState`
  maxima come from it, so armour/engines/computers are felt from the first
  module swap — the whole point of the upgrade layer.

## 10. HUD / UX additions (amendments to IMPLEMENTATION_PLAN §3.10)

- `set_prompt(text)` — dock/gate/interact prompt strip.
- `set_warp_channel(progress)` — warp bar (empty hides).
- Blip kinds: add `&"friendly"`; POI subkinds as data on the blip dict.
- Target window: range state (in/out per selected weapon) added to the
  `set_target_info` payload.
- Reticle: cursor reticle with in-range/out-of-range/hostile states; small
  hit markers (no floating damage numbers in v1).
- `set_pool(kind, value, max)` — the Energy and Fuel bars (UI_SPEC §3.1b):
  same ProgressBar pattern as hull/shield; Energy fill `metal_light` (the
  buffer is not a danger state), Fuel fill `metal_mid` turning
  `accent_danger` at ≤ 15 %, with the Emergency Flight Mode banner state
  (`set_emergency(active)`).
- `set_speedometer(ratio, prograde, heading)` — the 10-segment radial dial
  (UI_SPEC §3.6): cyan prograde needle = actual velocity, white heading
  marker = facing. The needle is the HUD's single sanctioned cyan (a
  navigation read, not danger — STYLE_BIBLE §3 amendment records it).
- `set_lock_progress(progress)` — the lock-channel ring on the reticle
  (empty hides; §4.1).
- Minimap blip kinds gain `&"swarmer"` (hostile) and `&"ghost"` (chaff,
  dim flicker).

## 11. Input map amendments (IMPLEMENTATION_PLAN §3.7)

- Add: **`interact` = F** (dock/gate prompts), **`warp` = H** (safe warp),
  **`consume_fuel_cell` = C** (emergency refuel, §4.4).
- `ui_cancel` (ESC) leaves the input map as is but its in-game meaning
  changes to *cancel order + lock*; ESC docking is retired by decision #3.
- Everything else stays: thrust/turn/fire/boost/mine/cargo/weapon_1..5/Q.

## 12. Amendments to existing docs (docs-first, apply before code)

1. `08_ship_classes.md` §2: hull table gains a **handling column** (§13 table
   is the source; 08 references it).
2. `09_ship_slots_modules.md` §3.1: weapon table gains **family + shield
   rule** (per §4.1 here); the railgun's "ignores 50 % armour" is retired
   (§4.1 note).
3. `09_ship_slots_modules.md` §3.2: base shield regen 2/s named here so the
   no-module case works.
4. `IMPLEMENTATION_PLAN.md`: new §9.9 (engine wave) recording decisions 1–7,
   the §3.7/§3.9/§3.10 amendments above, and the retirement of the ESC-dock
   placeholder + `MOCK_*` constants.
5. `game/player_state.gd`: `damage(amount, bypass_shield := false)` per §4.2
   (HUD signals unchanged).
6. `11_galactic_map.md` §1: note the one-arena-size rule (decision #4); the
   per-sector tier table stays authoritative.
7. `09_ship_slots_modules.md` §3.1: the weapon table gains a **power** column
   (energy draw rates per §4.4; kinetics/rockets stay pack-fed, §4.3
   unchanged) and §3.5's booster rows gain their fuel burns (afterburner
   BOOST_FUEL while active; fold = the dash, DASH_FUEL per burst).
8. `14_station_services.md` §2: the services menu gains **refuel** (CR per
   fuel point, §13) and **recharge** (instant Energy top-up) rows.
9. `06_loot_drops.md`: the countermeasure items `cm_chaff` and
   `cm_flare` enter the pirate tables (§4.6; names follow 03 components).
10. `11_galactic_map.md` §1 hazard column: nebula gas cloud rows (§8); the
    radar-degradation rule is that section's transcribe.
11. `08_ship_classes.md` §2: the speed anchor line is replaced by the
    §13 **speed table v2** reference once the owner ticks the mapped values
    (§16 item 1).
12. `02_minerals.md` is untouched — cleaving fragments inherit the parent
    rock's mineral roll; no new loot table.
13. `autoload/player_profile.gd`: vitals gain `fuel` (Energy recomputes at
    launch; Fuel persists), the `profile_changed` key `&"fuel"`, and the
    save-schema bump per the P1 migration pattern (save v3).

`19_testing_notes.md` batch-2 fixes are independent of all of the above and
can land before or in parallel.

## 13. Calibration table (initial values — playtest-tunable, single source)

**World**

| Value | Initial |
|-------|---------|
| `SECTOR_SIZE` | 10 000 × 10 000 u; station near centre; player spawns 300 u off the dock ring |
| Speed scale | `max_speed = hull % (08 §2) × 450 u/s` — replaced by **speed table v2** below once the owner ticks it |
| Camera zoom | 0.70–1.50 (shipped); speed pull-back multiplies it (§3.4) |
| Minimap radius | 800–6 400, step 800 (shipped) |
| Autopilot | slow-down radius 240 u, arrive radius 40 u |
| Pickup lifetime | 60 s; tractor 120 u range, 90 u/s pull |
| `MINE_CYCLE` | 1.2 s per ore unit; mining laser range 220 u; gun chip rate 10 % (depletion only, ruling 17) |
| `FX_BLUR_ONSET` | 0.70 of v_max; blur 0.1 → 0.8; camera pull to ×0.82 (§3.4) |

**Speed table v2 (ruling 26 — owner tick pending, §16 item 1)**

The brainstorm doc's four archetype rows mapped onto the nine 08 classes.
Doc-sourced numbers are exact; interpolations are marked ◇ and need the
owner's tick before slice-0 tests bake them.

| Class | Doc row | Max speed (u/s) | Turn rate (°/s → rad/s) |
|-------|---------|------:|------:|
| Fighter | Interceptor | 850 | 180 → 3.14 |
| Corvette | Corvette | 600 | 90 → 1.57 |
| Cutter | interpolated | 700 △ | 135 → 2.36 △ |
| Miner | interpolated | 380 △ | 45 → 0.79 △ |
| Trader | Freighter | 280 | 15 → 0.26 |
| Hauler | Freighter | 280 | 15 → 0.26 |
| Gunship | Battleship | 350 | 30 → 0.52 |
| Frigate | interpolated | 450 △ | 60 → 1.05 △ |
| Destroyer | Battleship | 350 | 30 → 0.52 |

△ = interpolation between doc rows (no doc row exists for that hull role).
Accel/coast/turn-spinup columns of the current table are unchanged; only the
max-speed and turn-rate columns are replaced, and `hull_mass` joins the table
(proposed, tunable): Fighter 80 · Cutter 110 · Miner 140 · Trader 160 ·
Corvette 90 · Hauler 260 · Gunship 190 · Frigate 220 · Destroyer 300 (t).

**Energy & fuel (rulings 10–14)**

| Value | Initial |
|-------|---------|
| `energy_max` base / `fuel_max` base | 100 / 200 (doc §1) |
| `energy_regen` (reactor refill) | 5/s (doc `recharge_rate`) |
| `FUEL_PER_ENERGY` | 0.10 fuel per 1 Energy spent |
| `BOOST_FUEL` | 3.0/s while afterburner runs |
| `DASH_FUEL` | 25 per fold/dash burst (doc) |
| `FUEL_CELL_UNITS` | 40 fuel per `fuel_cell` item, 10 s cooldown |
| Emergency mode | thrust locked, boost/dash locked, reactor ×0.7 |
| Weapon draw | laser 6 E/s · plasma 10 E/s · mining 5 E/s · kinetics 0 |

**Collision, recoil, explosions (rulings 15/16)**

| Value | Initial |
|-------|---------|
| `COLLISION_FACTOR` | 2.0e-5 (worked example §16 item 3) |
| `COLLISION_MIN_DV` | 40 u/s — slower contacts cost nothing |
| `KNOCKBACK_FRACTION` | 0.40 of the projectile's remaining KE |
| `EXPLOSION_P0` | 4 000 impulse-units at the epicenter (ship death) |
| `EXPLOSION_WINDOW` | 0.2 s outward impulse |

**Cleaving (ruling 17)**

| Value | Initial |
|-------|---------|
| Fragment split | L → 2–3 M · M → 2 S · S → 1–2 pickups |
| Ejection | `current_velocity × 1.2` + random ±15° cone |
| Fragment mineral | parent's mineral, re-rolled yield (02 §5 path) |

**Lock & countermeasures (rulings 21/22)**

| Value | Initial |
|-------|---------|
| `LOCK_CHANNEL` | 1.2 s uninterrupted LOS |
| `PASSIVE_RADIUS` | 1 500 u auto-tag |
| `CHAFF_WINDOW` / ghost count | 3.0 s / 3 signatures |
| `FLARE_LURE` | 450 u retarget radius |

**Handling per class** (08 classes; plating multiplies times by
`1 + |speed penalty|`; engines per §3.2)

| Class | Max speed (u/s) | Accel time (s) | Coast time (s) | Turn rate (rad/s) | Turn spin-up (s) |
|-------|------:|------:|------:|------:|------:|
| Fighter | 450 | 2.0 | 1.6 | 3.4 | 0.4 |
| Cutter | 428 | 2.4 | 2.0 | 3.0 | 0.5 |
| Miner | 338 | 4.0 | 3.4 | 2.0 | 1.0 |
| Trader | 383 | 3.0 | 2.6 | 2.4 | 0.7 |
| Corvette | 495 | 2.2 | 1.8 | 3.2 | 0.45 |
| Hauler | 293 | 6.0 | 5.2 | 1.5 | 1.4 |
| Gunship | 360 | 4.4 | 3.8 | 1.9 | 1.0 |
| Frigate | 383 | 4.0 | 3.4 | 2.1 | 0.9 |
| Destroyer | 315 | 6.4 | 5.6 | 1.6 | 1.2 |

`BRAKE_MULT` = 1.8 (S-thrust vs coast).

**Combat**

| Value | Initial |
|-------|---------|
| Weapon ranges (u) | laser 500 · plasma 450 · cannon 600 · railgun 800 · rocket 900 (lock range 900) |
| Rocket | 180 alpha, 1.2 s interval, 2.2 rad/s homing, 900 u/s, one hit kills it |
| Mine | arm 2 s, trigger 60 u |
| Shield regen | base 2/s + module values; resumes 4 s after last hit |
| Aggro radii | pirate 900 · patrol scan 1 000 · turret 750 · flee at 30 % hull · leash 2 500 |
| `AGGRO_COOLDOWN` | 5 s (aggro clears; warp becomes available) |
| `WARP_CHANNEL` | 3 s |

**NPC counts per sector** (13 §4 density shape): S1 0–1 · S2 1–2 · S3 2–3 ·
S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8, patrols only in owned space, one convoy
per inhabited sector.

## 14. Build slices (each is a shippable coder wave)

**Slice 1 — Fly and mine.** Deliverable: fly a sector with rocks, mine, collect,
dock, warp; HUD/UX pass. New files (one owner each):
`game/ship_stats.gd`, `game/ship_fit.gd` (reduced form, 09 §7 fit),
`game/player_ship.gd` (hybrid input, inertia, autopilot, boosters; extracts
movement from `game.gd`), `game/asteroid.gd`, `game/asteroid_field.gd`,
`game/mining_laser.gd`, `game/pickup.gd`, `game/sector_registry.gd` (7 rows,
11 §1), `game/sector.gd` (spawn set on entry + clock respawns). `game.gd`
keeps routing/HUD wiring and delegates. Retires: `MOCK_*` constants, ESC
docking. HUD: reticle, prompt strip, warp bar, blip kinds.

**Slice 0 — Physics & fuel (migration wave; runs before slice 2).**
Deliverable: the hull flies on real physics and runs on the reactor chain, so
slice 2 codes on top unchanged. Files: `game/impact.gd` (collision damage,
recoil/knockback/explosion impulse helpers), `game/player_ship.gd` (HullBody
becomes a `RigidBody2D`; thrust forces = mass × class acceleration, torque
mass-scaled — the §3.2 accel/coast/spin-up feel is preserved by derivation,
not retuned; contact-monitor collision damage; recoil caller),
`game/asteroid.gd` (static rock → rigid body with heavy mass + damp so fields
drift slow), `game/asteroid_field.gd` (spawn wiring only), plus the
**tiered cleaving** (fragment spawn on depletion, §6) and the **energy/fuel
pools** — `ShipStats`/`ShipFit` gain `hull_mass`/`energy_max`/`energy_regen`/
`fuel_max`, `PlayerState` gains the pools + `try_spend_energy` + emergency
mode, `impact.gd` wires §4.2 items 6–8. Station side: `repairs.gd` gains the
refuel/recharge services (§12 item 8), `autoload/player_profile.gd` persists
fuel (save v3), HUD gains `set_pool`/`set_emergency`. Speed table v2 bakes in
only after the owner's tick (§16 item 1).

**Slice 2 — Fight.** Deliverable: pirates/patrols/traders live, weapons fire,
damage, loot, death. New files: `game/weapons.gd` (families/firing/ammo),
`game/projectile.gd` (bolt/missile/mine), `game/damage.gd` (pipeline),
`game/npc_registry.gd`, `game/npc_ship.gd`, `game/npc_brain.gd`,
`game/loot_tables.gd` (06). PlayerState + HUD amendments per §12/§10.
**2026-09-20 amendments:** W1's families carry the power-draw hooks
(`PlayerState.try_spend_energy`, §4.4) and the rocket is the first seeker
(§4.6); W2's pipeline lands the `ctx` parameter and calls `impact.gd` for
collision/knockback/explosions (§4.2 items 5–8); W3 ships **human pirates AND
alien swarmers** (one brain, sprite paths swap-ready); W4's tables include
`cm_chaff`/`cm_flare`; W5 wires the pools bars, the radial speedometer, the
lock ring and the ghost blips (§10).

**Slice 2.5 — Feel (brief written after slice-2 reports).** Deliverable: the
speed fantasy and damage states on top of slice 2's signals — motion blur
shader + camera pull-back + dust (§3.4), damage smoke/ripple/shatter (FX_SPEC
§6), dash charge FX. No new gameplay systems; every number already in §13.

**Slice 3 — Travel.** Deliverable: gates, corridors, POIs, scanner, sector
transitions via `loading`. New files: `game/gate.gd`, `game/corridor.gd`,
`game/poi.gd` (derelict/anomaly/beacon), scanner reveal logic in
`sector.gd`.

**Slice 4 — Integration.** Deliverable: hunters (13 §3 Wanted wings), bosses/
arena hooks (14 §5), full `ShipFit` consumption once P2's fitting UI lands,
affix effects (15) flowing into `ShipStats`.

Per-slice verification follows `IMPLEMENTATION_PLAN.md` §6 (headless editor
import, boot check, probe-script pattern), and the theme/asset rules of
AGENTS.md stay in force (editor writes refused while the game plays).

## 15. Test checklist (headless-assertable)

- **ShipFit:** the 09 §7 standard fit resolves to exactly the arithmetic
  implied by 08 §2 + 09 §3/§7 (hull, shield, speed, turn, regen); plating and
  engine multipliers apply in the 09 §5 order.
- **Flight:** autopilot arrives within `ARRIVE_RADIUS` and cancels on manual
  input; brake shortens stopping distance vs coast; per-class times reproduce
  §13 within tolerance.
- **Damage:** energy is fully absorbed by a live shield (no carry-over);
  kinetic damage ignores shields; regen delay is respected; the `ctx`
  parameter is accepted everywhere and no-op until slice 3 turns quadrants on.
- **Power (slice 0):** spending 10 Energy burns 1 Fuel; boost burns 3/s;
  a dash consumes 25 and grants 0.8 s i-frames; fuel 0 → emergency (thrust
  ignored, reactor ×0.7); a fuel cell refills 40 and ends the mode.
- **Collision:** a Δv above the floor damages both bodies by the
  reduced-mass formula; below it, nothing.
- **Impulse/explosion:** knockback transfers 40 % of remaining KE; the
  shockwave impulse follows `I(d)` within the 0.2 s window.
- **Cleaving:** a depleted Large spawns 2–3 Medium fragments ejecting at
  ×1.2 velocity ±15°; a depleted Small bursts 1–2 pickups; yield-0 rocks
  still despawn bare.
- **Lock:** the channel completes at 1.2 s of clean LOS, breaks on a rock or
  hull crossing, and chaff ghosts block re-acquisition for 3 s; flares
  retarget a live seeker within 450 u.
- **Mining:** N cycles on a rock spawn N ore pickups; gun chip accumulates at
  10 % toward depletion and zero toward ore; cracks at yield 0; hold-full
  leaves pickups drifting.
- **NPC brain:** aggro → engage → flee transitions at the §13 thresholds;
  leash/despawn; LOS blocked by a rock fixture.
- **Warp:** blocked while engaged, breaks on damage mid-channel, lands docked;
  unavailable with no station in sector.
- **Loot:** expected values per 06 §6 (±5 %), credit caches log to
  `economy_log` (01 §7).
- **No mock residue:** `MOCK_*` constants gone; ESC no longer docks.

## 16. Open items

1. **Speed table v2 owner tick (ruling 26):** the mapped nine-class table in
   §13 carries the doc's four archetype rows exactly where they match and
   marks the interpolations △ — the owner ticks the △ rows (or remaps) before
   slice-0 tests bake the numbers.
2. **Proposed-initial constants:** `FUEL_PER_ENERGY` 0.10,
   `COLLISION_FACTOR` 2.0e-5, `COLLISION_MIN_DV` 40, `EXPLOSION_P0` 4 000,
   weapon draw rates (6/10/5 E/s) are this spec's proposals, not the
   brainstorm doc's — §13 marks all of it playtest-tunable. Worked check:
   a Fighter (80 t) flat-wall impact at 450 u/s ⇒
   0.5 · 80 · 450² · 2.0e-5 = 162 damage (≈ a quarter of hull) — plausibly
   harsh at full throttle, gentle at half.
3. **Alien art gate:** swarmers ship in slice 2 on placeholder art with
   swap-ready sprite paths; the visual pass follows the graphics designer's
   alien sheets (STYLE_BIBLE §2.5). Behaviour probes never gate on art.
4. **Afterburner multiplier:** the owner's locked +60 %/3 s/8 s stands; the
   brainstorm doc's 2.5× boost multiplier is **not** adopted — the fold/dash
   carries the doc's fuel-and-i-frame numbers instead.
5. Bosses/arena contracts (14 §5) and hunters are slice-4 hooks; their tuning
   waits for the P2 fit economy to exist.
6. The railgun wording retirement (§4.1) and the base shield-regen number
   (§4.2) are engine-spec additions — flag to the owner if either should be
   re-tuned instead.
7. Crafting (07) untouched by the engine.
