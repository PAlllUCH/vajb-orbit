# S39_BRIEF — flight feel, hostile fire and cargo (owner playtest #2)

**Wave:** S39 · **Lane:** code · **Gate baseline:** 1258/0 (`s26_start` was
1258/0; S39's own tag is `s39_start`).
**Slice folder:** `.agents/gen/slices/S39-flight-feel/`.
**Carries:** T-164–T-170 (all seven filed 2026-10-10).

## 1. The law to read, in order
1. `AGENTS.md` (agent rules, slice/folder law, the designer-lane format).
2. `docs/CONTRACTS.md` §10 (changelog), §14 (runner sandbox), §20 (ship-stat
   affixes) — range-read only.
3. `docs/gameplay/18_engine_spec.md` §3.2 (inertia model), §4.2 items 6–8 (push
   physics), §5 (NPC archetypes) — **owner-locked; read, never edit**.
4. `.agents/gen/_state/WAVEBOARD.md` §Queued row 1.

## 2. The owner's request (verbatim, 2026-10-10)
> 1. enemies dont shoot back
> 2. when reversing (flying forward and turning around) it takes forever. thrust
>    in different direction should be faster maybe?
> 3. i want a default behaviour of afterburner and other thrust based segment to
>    increase temporary thrust. this way it can be used to make faster turns
> 4. i think that afterburner and other mods should be on top of standard boost
>    to speed while pressing shift
> 5. the auto-pathing needs rework. when convoy goes from S1 to S2 jump gate
>    (contract) even a slightest change in its course (asteroid, ship) makes ip
>    unable to return to path
> 6. the hitting of ships with equipment throws them way too much like they dont
>    have their own inertia, they move like ragdolls
> 7. i cannot see my current cargo while in flight, and i cannot see it in
>    "Armory" or anywhere else on the ship. how do i know that i have 5 slots
>    while buying ammo and how many slots and ammo i have left?

## 3. What is already measured (with `file:line`)
- **Enemies fire nothing.** `npc_brain.gd:25` ("It fires nothing: `fire` is an
  intent for a hull that carries a weapon") and `npc_ship.gd:149,1054` ("the fire
  flag has no consumer"). `_intent()` already sets `INTENT_FIRE` in ENGAGE
  (`npc_brain.gd:319`). No NPC archetype row carries a weapon family; the bosses'
  `BOSS_HULLS[*].weapons` counts (`npc_registry.gd:206`) are read by nothing.
- **Reversal = 2 × accel_time.** `_thrust_axis` (`player_ship.gd:1199`) chases
  `desired_speed` along the nose at `rate = max_speed / accel_time`
  (`_accel_rate`, `:1527`), clamped `[-rate, rate]`. Turning 180° and holding W
  drives the along-heading velocity from `+max` to `+max` the other way, through
  `-max` — two ramps.
- **Boost is a ceiling only.** `_max_speed()` = `max_speed * _boost_multiplier()`
  (`:1618`), and `_boost_multiplier()` (`:1705`) returns the afterburner's
  `boost_speed_mult` only while `_boost_remaining > 0`. Nothing scales
  `_accel_rate()` or the turn.
- **Shift is the afterburner, or nothing.** `_update_boosters` (`:1633`) returns
  unless `has_booster(BOOSTER_AFTERBURNER)` (`:1646`); the `boost` action
  (`project.godot:68`, Shift) has no baseline effect.
- **Convoy route stalls.** `_patrol_waypoint` (`npc_brain.gd:358`) advances
  `_route_index` only inside `PlayerShip.ARRIVE_RADIUS` (40 u, `player_ship.gd:136`);
  `_order_speed` (`npc_ship.gd:547`) returns 0 when `abs(error) > PI * 0.5`, so a
  hull whose next leg is behind it stops thrusting and turns at the freighter's
  own slow rate. A freighter's turn radius exceeds 40 u, so a deflection makes it
  miss the ring, stall and never advance the leg.
- **Knockback throws.** `Impact.KNOCKBACK_FRACTION = 0.40` (`impact.gd:31`);
  `projectile.gd:857` applies `sqrt(2 * share * target_mass)` — a Δv of
  `speed * sqrt(0.4 * shot_mass / target_mass)` with `SHOT_MASS = 1.0`
  (`weapons.gd:283`).
- **Cargo is hidden.** `_retire_old_column()` (`hud.gd:1653`) hides
  `_cargo_toggle` and `_cargo_panel` (`hud.gd:1664`); the cells are generic icons
  tinted by index (`hud.gd:1621,1816`) and never carry the hold's contents.
  `PlayerProfile.cargo_items()` (`player_profile.gd:610`) is the read.

## 4. Pinned interfaces (do not change)
- `ShipStats` field list (`ship_stats.gd`) — the resolved flight snapshot.
- `PlayerShip` public seams: `applied_force()`, `applied_torque()`,
  `apply_impulse()`, `apply_recoil()`, `velocity()`, `boost_activations()`,
  `set_speed_ratio()`, `speed_ratio()`.
- `NpcShip` public seams: `setup(...)`, `take_damage(...)`, `apply_impulse()`,
  `intent()`, `state_name()`.
- `Impact` statics: `collision_damage`, `knockback`, `recoil_impulse`,
  `explosion_impulse`, `apply_shockwave`.
- `Hud` frozen API (`UI_SPEC.md` §7) — every method keeps its signature; a
  restored readout is additive.
- `Projectile.configure(cfg)` keys.

## 5. The rules that fix every ambiguity
- **R1 — Docs first, then code, then tests.** New numbers land in the owning doc
  as a dated block with each value's reversal before any code.
- **R2 — A pinned number that moves is PROPOSED, with its reversal stated.** No
  worker chooses a value silently.
- **R3 — Signal up, call down** (the Layer Cake rule).
- **R4 — A layout effect is out of a synchronous gate's reach; pin the *flag*
  (T-160's precedent) and measure the effect off a rendered frame.**
- **R5 — Single-source a decision so a probe reads what ships** (S26-F4's lesson).
- **R6 — The `fire` consumer must not fire on a neutral hull.**

## 6. Spec extract (the exact text the deliverable must satisfy)
- 18 §5: "**Idle → Patrol/Scan → Alert (LOS check, rocks block) → Engage (hold
  preferred range, strafe)**"; the archetype table's Pirate row: "engages
  anything in radius"; Patrol: "attacks Outlaws (80+) and defends faction ships".
- 18 §3.2: "**Linear inertia.** Velocity chases `throttle × max_speed` with the
  class's `accel_time`"; "**Boosters** (B slot, 09 §3.5): afterburner via the
  existing `boost` action (+60 % speed 3 s, 8 s cooldown, burns fuel while
  active — §4.4)".
- 18 §4.2 item 7: "a hit transfers `KNOCKBACK_FRACTION` of the projectile's
  remaining kinetic energy to the target along the impact line".
- 18 §5: Trader/convoy: "flies fixed route; flees from Suspect+".

## 7. Acceptance list (graded item by item by the reviewer)
1. A1 — an engaged hostile fires at its target; a neutral convoy does not
   (T-164).
2. A2 — a reversal changes the velocity sign in < 2 × `accel_time` (T-165).
3. A3 — a lit boost raises the commanded accel rate, not only `max_speed`
   (T-166).
4. A4 — with no afterburner fitted, Shift raises speed (T-167).
5. A5 — a deflected convoy hull re-acquires its leg and reaches the gate (T-168).
6. A6 — a shot's knockback Δv is below the pre-wave figure (T-169).
7. A7 — the hold's contents and `used/max` render in flight and in the armory
   (T-170).

## 8. Tests that move (and why)
- `tests/test_slice2_5_feel.gd` — boost activation/fuel rows: the baseline Shift
  boost changes what a Shift press does (A4).
- `tests/test_s22_7_ships.gd` — the afterburner fuel row: the burn may split
  between the baseline boost and the afterburner (A3/A4).
- `tests/test_engine*_weapons.gd`, `tests/probe_c2_weapons.gd` — knockback figures
  (A6).
- `tests/test_s25_contracts.gd` / convoy rows — route advance (A5).
- New suite `tests/test_s39_feel.gd` for A1–A7; `test_wiring_map.gd`'s preload
  scan may flip if a probe is added mid-run (S26-R1's lesson) — use `load()` of a
  `const` path in any probe.

## 9. Hard rules
- Never edit `docs/gameplay/18_engine_spec.md` (owner-locked) or
  `vajb-orbit/addons/`; never hand-edit `project.godot` except documented keys.
- Bound every Godot run with `--quit-after`; never leave a command in the
  background.
- No `call(&"<variable>")` false-green: scan a new suite with `rg 'call\(&"_'` and
  confirm each name is a real method.
- The gate must be green (0 failures) and run twice on fresh scratch stores.

## 10. Close-out
Gate ×2 hermetic; `staging/verify_wave.py verify --baseline s39_start
--forbidden vajb-orbit/project.godot docs/ vajb-orbit/addons/ --tests`;
`staging/build_code_map.py`; CONTRACTS §10 (and a §29 wave section if a new
interface lands); the owning doc's own dated block for every new number
(`18_engine_spec.md` is owner-locked — the numbers go to `docs/CONTRACTS.md` §29
and the wave's recap, and the owner is asked to fold them into 18);
WAVEBOARD/TICKS/LOW_BACKLOG (next free ticket **T-171**); `MASTER_REPORT.md` §6
recap (anchor on the previous entry's tail, verify additions-only); wave-boundary
commit with the Crush attribution.

## 11. Owner tick list
- [ ] T-164–T-170 are riders on S39 (filed 2026-10-10).
- [ ] The PROPOSED values (reversal-assist multiplier, boost thrust share,
  baseline Shift boost, knockback share) are ratified or re-cut by the owner.
