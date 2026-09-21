# C2 report — the weapon measurement (combat/collision repair wave)

Worker **C2** (`VAJB_WORKER_FILES=vajb-orbit/tests/,vajb-orbit/tools/`). Brief:
`.agents/gen/combat_repair_wave_task.md`. Evidence base:
`.agents/gen/owner_playtest_findings_20260921.md`, `docs/CONTRACTS.md` §4/§8.2,
ENGINE_SPEC §4.1/§4.2/§4.3/§4.4/§6/§13.

**Nothing was fixed.** Two files were added (a probe scene + its script), nothing else
was touched: no game code, no assets, no theme, no `project.godot`, no `addons/**`, no
`docs/**`. No constant was changed, so there is no reversal path to record.

## Verdict in four lines

1. **All five v1 families fire and land on both targets** — every group's firing path
   works; nothing in the trigger, energy, ammo, delivery or travel code is broken.
2. **A shot at a rock is not a no-op for beams or projectiles.** The rock is chipped at
   the 10 % rate and *cracks* (measured: a 5-unit rock is destroyed by one laser hold).
   The only rock no-op among the five families is the **mine**.
3. **The rock's missing sink name is `take_damage`** (with `damage` as the pipeline's
   fallback): `Damage._hit_method` returns `&""` for a rock, and both
   `weapons.gd:_deliver` and `Damage.apply` then return silently — but no shipped beam or
   projectile path reaches that seam, because both branch on the rock group first.
4. **The launch installs one weapon, not the five the launch panel reports** — and no
   mining laser at all. Groups 2–5 are *unfitted*, not broken.

Findings and their proposed severity are at the end (tiering is C6's job).

## The probe

| | |
|---|---|
| scene | `vajb-orbit/tests/probe_c2_weapons.tscn` |
| script | `vajb-orbit/tests/probe_c2_weapons.gd` |
| evidence logs | `.agents/gen/c2_probe_paced.log`, `.agents/gen/c2_probe_fixedfps.log` (byte-identical) |

```sh
# canonical (real-time paced, ~80 s)
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000
# same bytes in ~1 s (the physics delta is 1/60 either way)
~/.local/bin/godot --headless --fixed-fps 60 --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000
```

Determinism, measured: two consecutive paced runs are byte-identical, and the paced
run is byte-identical to the `--fixed-fps 60` run (`diff` of both logs is empty; the two
kept logs are exactly that pair). The probe ends itself at
`[C2] done stepped_frames=4920`, well inside `--quit-after 12000`, with no `SCRIPT ERROR`
line and no leak report.

### How the trigger and the clock were driven

* `WeaponComponent.set_firing(true/false)` — the component's own external trigger. Every
  case logs `external_trigger=true`, read back from `_external_trigger` after the trigger
  is set, which proves `_sample_trigger` never reached `Input` for that case. The
  `fire_primary` action exists in the project (`input_action_present=true`) and is never
  read.
* `WeaponComponent.set_aim_point(target.global_position)` — the additive aim seam, so the
  cursor (`get_global_mouse_position`) is never consulted.
* Stepping: the component is a child of a stub hull, so its own `_physics_process` calls
  `tick(1/60)`; the probe awaits `get_tree().physics_frame` a counted number of times
  (`ENV ... physics_ticks=60 physics_delta=0.016667`). Projectiles fly on the same clock.
* Headless: `ENV display=headless`. No window, no editor, no live run.
* The one autoload this probe reads is `PlayerProfile`, and only through `ammo_of()`
  (read-only) to reproduce the launch panel's own total. `save_path` is never repointed, so
  the L17 hygiene rule (stop/flush the 0.5 s debounce before restoring it) has nothing to
  undo here; nothing is written and nothing is dirtied.

### Fixtures

* **Host**: a stub `Node2D` with `apply_recoil(velocity, mass)` (the shipping `_host()`
  shape), with the real `WeaponComponent` as its child.
* **NPC hull**: `NpcShip`, archetype `pirate`, hull `ship_fighter`, its own art
  (`assets/ships/ship_fighter_side.png`), stats from `ShipFit.resolve(ship_fighter,
  STANDARD_FIT)` → **hull 950.0 / shield 600.0**, body on layer 2, `HullBody.freeze=true`
  so the target cannot drift while the pools are measured.
* **Shields-down variant**: the *same* stats object with `shield_max = 0.0` handed to both
  the component and the hull, so the shield pool is inert (no regen can re-fill it) and
  the hull is the only pool left. This is what makes the plasma bonus measurable.
* **Rock**: `Asteroid`, mineral `iron`, Medium look, layer 1, mask 0, group `asteroid`
  (all measured), `freeze=true`. Matrix rocks carry 100 units so no case empties its own
  fixture; the crack case uses a 5-unit rock on purpose.
* **Controls**: a layer-1 body that publishes `take_damage` (`sink_body`) and a layer-1
  body that publishes nothing (`bare_body`), so "the shot never arrived" is separable from
  "the shot arrived and the sink was missing".

## Raw numbers

### 1. NPC hull, shields up (950 hull / 600 shield, `ship_fighter` + `STANDARD_FIT`)

| family | frames | shots | hull Δ | shield Δ | row: bypass | row expectation | measured vs row |
|---|---|---|---|---|---|---|---|
| laser | 60 (1 s) | 1 hold | **+0.000** | **−30.000** | no | 30 dps × 1 s = 30.000 | exact |
| plasma | 60 (1 s) | 1 hold | **+0.000** | **−87.500** | no | 70 dps × 1 s = 70.000 | **+25 % (see F1)** |
| cannon | 180 (3 s) | 5 | **−135.000** | **+0.000** | yes | 5 × 27.000 = 135.000 | exact |
| railgun | 180 (3 s) | 5 | **−180.000** | **+0.000** | yes | 5 × 36.000 = 180.000 | exact |
| rocket | 300 (5 s) | 5 (4 landed, 1 in flight) | **−720.000** | **+0.000** | yes | 4 × 180.000 = 720.000 | exact |
| mine | 150 (2.5 s) | 1 | **−180.000** | **+0.000** | yes | 180 alpha | exact |

`bypass_shield` follows the family rows exactly: energy (laser, plasma) lands on the
shield first and leaves the hull untouched; kinetic (cannon, railgun), missile (rocket)
and deployable (mine) land on the hull with the shield pool at 600.000 throughout.
Every case logged `dry_before="" dry_after="" dry_events=0`.

### 2. NPC hull, shield pool inert (`shield_max = 0.0`)

| family | hull Δ | shield Δ |
|---|---|---|
| laser | **−30.000** | 0.000 (pool 0 → 0) |
| plasma | **−87.500** (= 70 × 1.25) | 0.000 |
| cannon | **−135.000** | 0.000 |
| railgun | **−180.000** | 0.000 |
| rocket | **−720.000** | 0.000 |
| mine | **−180.000** | 0.000 |

The §4.1 plasma row ("+25 % to hull **once shields are down**") is exact here. The same
87.500 in table 1 is the anomaly.

### 3. Rock (Asteroid `iron`, 100 units, group `asteroid`, layer 1)

`work_credited` = units extracted + the residual left in `apply_work`'s accumulator
(`apply_work` converts whole units the moment they are reached, so a raw `work` delta
read alone under-reports: cannon shows work 0.000 → 0.500 with 13 units extracted).

| family | frames | shots | units extracted | work credited | expected (§6: 10 % of the hit) | rock state |
|---|---|---|---|---|---|---|
| laser | 60 | 1 hold | 3 | **3.000** | 30 × 0.1 × 1 s = 3.000 | alive |
| plasma | 60 | 1 hold | 7 | **7.000** | 70 × 0.1 × 1 s = 7.000 | alive |
| cannon | 180 | 5 | 13 | **13.500** | 5 × 27 × 0.1 = 13.500 | alive |
| railgun | 180 | 5 | 18 | **18.000** | 5 × 36 × 0.1 = 18.000 | alive |
| rocket | 300 | 5 | 90 | **90.000** | 5 × 180 × 0.1 = 90.000 | alive |
| mine | 150 | 1 | 0 | **0.000** | — | alive, mine unspent |

**Every family but the mine damages a rock, and each credited figure is exactly the
10 % chip of its own row.** The mine's row: `projectiles=1` (the dropped mine still
sitting there, never consumed) and 0.000 work on the rock.

### 4. Rock taken to the crack (5-unit rock, 180 frames)

| family | result |
|---|---|
| laser | `units 5 -> 0`, rock **FREED**, `cracked=true` |
| cannon | `units 5 -> 0`, rock **FREED**, `cracked=true` |

So the shipped paths do not merely chip a rock, they **destroy** it: "I cannot shoot
asteroids" is not a missing damage route on the weapon side.

### 5. `dry_reason()` per family

| family | drained resource | `dry_reason()` | shots | `dry_fired` events | damage landed while dry |
|---|---|---|---|---|---|
| laser | energy (pool 0) | `energy` | 0 | 1 (`laser`) | 0.000 / 0.000 |
| plasma | energy (pool 0) | `energy` | 0 | 1 (`plasma`) | 0.000 / 0.000 |
| cannon | ammo slot 1 = 0 | `ammo` | 0 | 1 (`cannon`) | 0.000 / 0.000 |
| railgun | ammo slot 1 = 0 (shares the cannon pack) | `ammo` | 0 | 1 (`railgun`) | 0.000 / 0.000 |
| rocket | ammo slot 2 = 0 | `ammo` | 0 | 1 (`rocket`) | 0.000 / 0.000 |
| mine | ammo slot 3 = 0 | `ammo` | 0 | 1 (`mine`) | 0.000 / 0.000 |

Signal counts per 60-frame hold are the shipped contract: one `dry_fired` per pull (not
per frame), carrying the family id, and no `shot_fired`. A family with a full pack
reports `dry_reason=""` (tables 1–3). `dry_reason()` is therefore a reliable "empty, not
broken" discriminator — and `none` is the third state, meaning *no weapon selected* (see
the launch fit below).

### 6. Controls: the same geometry with and without a sink

| control | frames | hits | damage taken | reading |
|---|---|---|---|---|
| layer-1 body + `take_damage`, laser | 120 | 120 | **60.000** (= 30 × 2 s) | the beam delivers per frame |
| layer-1 body + `take_damage`, cannon | 120 | 4 | **108.000** (= 4 × 27) | the bolt delivers per shot |
| layer-1 body, no sink, laser | 120 | — | nothing moved (`speed 0.000 -> 0.000`, `pos 200.0 -> 200.0`) | nothing to observe for a beam |
| layer-1 body, no sink, cannon | 120 | — | **`speed 0.000 -> 527.312`, `pos 200.0 -> 1249.7`** | the bolt **arrived** (knockback applied) and dealt nothing |

The last row is the isolated no-op at scene level: same layer, same ray, same geometry as
the rock, one difference — no sink method.

### 7. The sink seam itself, called directly

| call | measured result |
|---|---|
| `Damage.apply(npc, 100.0, false)` | shield 600.000 → 500.000 (−100.000) |
| `Damage.apply(rock, 100.0, false)` | work 0.000 → 0.000, units 100 → 100 (**silent no-op**) |
| `Damage.apply(sink_body, 100.0, false)` | taken 0.000 → 100.000 |
| `Damage.apply(bare_body, 100.0, false)` | nothing |
| `weapons._deliver(rock, 100.0, false, kinetic)` | work 0.000 → 0.000, units 100 → 100 (**silent no-op**) |
| `weapons._deliver(sink_body, 100.0, false, kinetic)` | taken 100.000 → 200.000 |
| `weapons._deliver(bare_body, 100.0, false, kinetic)` | nothing |
| `weapons._shield_up(npc)` / `_shield_up(shield_reader)` | **false** / **true** |

Method surface, measured on the live instances:

```
[C2] SINK npc  take_damage=true  damage=false apply_work=false shield_up=false
[C2] SINK rock take_damage=false damage=false apply_work=true  shield_up=false
[C2] TARGET npc  hull_max=950.0 shield_max=600.0 layer=2
[C2] TARGET rock group=true layer=1 mask=0 work=0.000 yield=100
```

**The exact no-op path, per family (target = a real rock):**

| family | shipped path | result |
|---|---|---|
| laser, plasma | `weapons.gd:_fire_beam` → `_apply_beam` (weapons.gd:489) → the `asteroid`-group branch (weapons.gd:496) → `Asteroid.apply_work(amount × GUN_CHIP_RATE)` | chip, then depletion/crack |
| cannon, railgun, rocket | `projectile.gd:_resolve` (372) → `_is_rock` (674) → `_hit_rock` (390) → `apply_work(damage × chip)` | chip (the rocket also detonates) |
| mine | `projectile.gd:_step_mine` (421) → `_mine_victim` (437) scans only the `player_ship` / `npc_ship` groups; a mine never sweeps bodies | **nothing: 0.000 work, mine unspent** |
| any caller that reaches a sink directly | `weapons.gd:_deliver` (675) / `Damage.apply` (`damage.gd:90`) → `Damage._hit_method` (`damage.gd:337`) → `&""` | **silent no-op** |

**Sink name the rock is missing: `take_damage`** (the pinned name; `damage` is the
pipeline's fallback and is also absent). The rock publishes `apply_work` only
(`game/asteroid.gd:202`), which is why `Damage._hit_method` answers `&""` — its own
comment names the rock as the no-op case. What the shipped beam and projectile paths do
instead is branch on the group *before* the sink is ever resolved.

### 8. The launch fit

```
[C2] LAUNCH-PANEL packs=5 ids=[laser, cannon, rocket, mine, plasma] player_state_ammo_default=300
[C2] LAUNCH-PANEL profile_holdings=["laser=300", "cannon=300", "rocket=300", "mine=300", "plasma=300"] total=1500
[C2] LAUNCH-FIT ShipFit.STANDARD_FIT ids=[w_laser, s_light, h_plate_light, e_std, p_std]
[C2] LAUNCH-FIT mining_gate module=w_mining in_standard_fit=false in_five_weapon_fit=false
[C2] LAUNCH-FIT fitted_after_filter=[laser] groups=5
[C2] LAUNCH-FIT shipped group=1 selected="laser"  dry_reason=""
[C2] LAUNCH-FIT shipped group=2 selected=""       dry_reason="none"
[C2] LAUNCH-FIT shipped group=3 selected=""       dry_reason="none"
[C2] LAUNCH-FIT shipped group=4 selected=""       dry_reason="none"
[C2] LAUNCH-FIT shipped group=5 selected=""       dry_reason="none"
[C2] LAUNCH-FIT state rounds_per_slot=[300, 300, 300, 300, 300] total=1500 energy=100.0
```

The launch panel's own line, reproduced from its sources (`StationCatalog.AMMO_PACKS`,
`ui/station/launch_panel.gd:81`/`:391`/`:398`, live `PlayerProfile`): **5 weapons,
1500 rounds** (300 a pack). `game.gd:341` installs
`ShipFit.fitted_ids(ShipFit.STANDARD_FIT)` (`ship_fit.gd:385`), whose weapon half is
`[w_laser]` — so the component's own filter leaves `fitted() == ["laser"]` and groups 2–5
select nothing (`dry_reason "none"`, the "empty group" state, not `energy`/`ammo`).

Fired group by group with **the five-weapon fit** (the panel's promise, 300 rounds a
slot = 1500):

| group | weapon | `dry_before` | shots | hull Δ | shield Δ | verdict |
|---|---|---|---|---|---|---|
| 1 | laser | `""` | 1 | +0.000 | −30.000 | fires |
| 2 | cannon | `""` | 5 | −135.000 | +0.000 | fires |
| 3 | rocket | `""` | 5 | −720.000 | +0.000 | fires |
| 4 | mine | `""` | 1 | −180.000 | +0.000 | fires |
| 5 | plasma | `""` | 1 | +0.000 | −87.500 | fires |

Every group fires: **the empty groups at launch are unfitted, not broken.**

What the shipping hull mounts (real `player_ship.tscn` + the pinned `setup` handshake):

| fit | `MiningLaser` child | `WeaponComponent` child | `guns.fitted()` |
|---|---|---|---|
| `STANDARD_FIT` (what launches today) | **false** | true | `[laser]` |
| `STANDARD_FIT` + `w_mining` | **true** | true | `[laser]` |
| five-weapon fit | **false** | true | `[laser, cannon, rocket, mine, plasma]` |
| five-weapon fit + `w_mining` | **true** | true | five |

and then, on that shipping hull with the five-weapon fit, **group 1 fired at a real rock
through the same external trigger**:

```
[C2] MOUNT-FIRE ship=player_ship.tscn fit=five_weapon_fit+w_mining group=1 weapon=laser rock_units=5->0 rock_freed=true
```

The matrix's rock row and this row agree, so the stub host is not the difference: the
shipping mount, the shipping hull and a real rock produce the same result as the matrix
(5-unit rock destroyed).

## Findings (measured; nothing fixed; tiers for C6)

### C2-F1 — plasma's +25 % bonus fires against **live shields** on any hull whose shield the weapon cannot read *(candidate HIGH)*

* Measured: 1 s of plasma on a 600-shield NPC removes **87.500** shield = `70 dps × 1.25`;
  the laser's own control removes exactly 30.000. §4.1's row says plasma is "+25 % **to
  hull** once shields are down", and `weapons.gd:509`'s own comment claims the gate stops
  the family from out-damaging its row.
* Mechanism, measured: `weapons._shield_up(npc) = false` while
  `_shield_up(shield_reader) = true`. `NpcShip` publishes `hull()` / `shield()` methods
  (`npc_ship.gd:767`, `:775`) but **no `shield_up()`** and no `shield` / `state`
  property, and `weapons.gd:_shield_up` (652) reads only those three. `PlayerShip` does
  publish `shield_up()` (`player_ship.gd:258`), so the same weapon is gated correctly
  against the player and not against any NPC.
* Consequence: plasma out-damages its §13 row by 25 % against every NPC in the game,
  shield pool included.
* Files that would have to change: `game/weapons.gd` or `game/npc_ship.gd` — both outside
  my file set. Two reversal-shaped options for C5: publish `shield_up()` on `NpcShip`
  (mirroring `player_ship.gd:258`), or have `_apply_beam` read the pool through a single
  narrow accessor. Either way the *number* does not move; only which pool the multiplier
  is allowed to touch does.

### C2-F2 — the brief's premise for ruling 1 does not reproduce *(candidate HIGH for the plan, not for the code)*

* Ruling 1 / finding B read: "`game/asteroid.gd` exposes `apply_work(amount)` and no
  `take_damage`, so `weapons.gd:_deliver` returns silently and a shot at a rock does
  nothing". The first half is true (measured); the conclusion is **not**: no shipped beam
  or projectile path reaches `_deliver` with a rock. `_apply_beam` branches on the
  `asteroid` group first (`weapons.gd:496`) and `_hit_rock` does the same for projectiles
  (`projectile.gd:372`/`:390`), both calling `apply_work` at the **already-shipped**
  10 % rate. Measured: 3.000 / 7.000 / 13.500 / 18.000 / 90.000 work credited, unit
  depletion, and a 5-unit rock **destroyed** by a laser hold, by a cannon burst, and by
  the real `player_ship.tscn` mount firing group 1 (MOUNT-FIRE line above).
* The damage→work constant ruling 1 wants already exists and is already pinned:
  `WeaponComponent.GUN_CHIP_RATE = 0.10` (`weapons.gd:137`, §6/ruling 17) with
  `Asteroid.WORK_PER_UNIT = 1.0` (`asteroid.gd:45`). Measured ratio across all five
  families: exactly 0.10. If the owner still wants a *separate* weapon→rock conversion,
  it would be a second constant layered on the first, and the measured effect of changing
  it is one line: credited work per second = `dps × rate`.
* **Ask for the orchestrator/owner before C5 spends a pass**: re-scope ruling 1. The
  measurements point at two other explanations for the owner's report, both measured here
  — the mine never touching a rock (table 3), and the mining laser (the `E` key, the
  rock-facing trigger) not being mounted at launch (C2-F3).

### C2-F3 — the launch installs one weapon and no mining laser *(candidate HIGH)*

* Measured: the panel's line says 5 weapons / 1500 rounds, and the profile agrees
  (300 + 300 + 300 + 300 + 300 = **1500**); `game.gd:341` installs a fit whose weapon half
  is `[w_laser]`, the component's `fitted()` is `["laser"]`, groups 2–5 read
  `dry_reason="none"`, and the hull mounts **no `MiningLaser`** node.
* The mining laser is gated on `w_mining` (`player_ship.gd:692-693`) and that module is in
  neither `STANDARD_FIT` nor the five-weapon module list. With the launch fit, "shoot a
  rock with `E`" has no node at all — the best surviving explanation for the owner's
  "I cannot shoot asteroids" after these measurements, and a *wiring* finding (unfitted
  group), not a broken firing path.
* Everything needed to call it is in this report: the five-weapon fit fires all five
  groups; adding `w_mining` mounts the laser (`true` in the mount table). Which fit the
  launch installs is a `game.gd` / `ship_fit.gd` decision — outside my file set.

### C2-F4 — `interval_of(mine)` reads 0.600, a kinetic default on a deployable *(candidate MED)*

* Measured: `interval_of` = 0.000 (laser), 0.000 (plasma), 0.600 (cannon), 0.600
  (railgun), 1.200 (rocket), **0.600 (mine)**. The mine's row states neither an interval
  nor a burst cycle, so `weapons.gd:1033` falls through to `KINETIC_INTERVAL` (0.6);
  `edge` makes the mine one-per-pull so nothing breaks today, but the number is not a
  spec row. `weapons.gd` is outside my file set.

### C2-F5 — rocket timing, recorded so nobody re-derives the 720 *(INFO)*

* 5 s of fire at a 200 u target releases **5** rockets; **4** land (4 × 180 = 720) and the
  5th is still in flight at the window's end (`projectiles=1`). Cannon and railgun
  release 5 and land all 5 in the same window. Recoil calls match the releases
  (cannon 5, railgun 5, rocket 5, laser 0, plasma 0, mine 0), which is §4.2 item 7
  behaving per row.

## What this does **not** cover

* **The live cursor aim.** The probe fixes the aim with `set_aim_point`, so an aiming
  defect (`get_global_mouse_position`, the reticle, the beam's origin) is invisible here.
  If the owner's "cannot shoot asteroids" is an aim problem rather than an unfitted
  weapon, this probe cannot see it; a follow-up would have to drive the cursor seam.
* Collision/ram (C1), flight decay (C3), the mining laser's own beam/cycle, FX and
  feedback (slice 2.5), and whether a live game *shows* any of this to the player (there
  are no damage numbers).
* No tests were added: the wave's test-per-fix belongs to the fix pass (C5); this probe is
  measurement-only by the brief, and it is deliberately not named `test_*` so the gate
  cannot pick it up.

## Gate

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
# -> [SUMMARY] passed=229 failed=0   (log: .agents/gen/c2_gate_after.log)
```

Before my probe landed the same command read `passed=226 failed=0`. My probe contributes
**0** tests (`grep -c probe_c2` in the gate log is 0 — it is not discovered); the +3 is
C3's new `test_engine_c3_flight_decay.gd`, which landed in parallel in this same
workspace. Count grew, nothing shrank, no test was edited.

## Files

* added: `vajb-orbit/tests/probe_c2_weapons.gd`, `vajb-orbit/tests/probe_c2_weapons.tscn`
  (the engine also wrote `probe_c2_weapons.gd.uid`, as it does for the other probes)
* evidence: `.agents/gen/c2_probe_paced.log`, `.agents/gen/c2_probe_fixedfps.log`
  (byte-identical), `.agents/gen/c2_gate_after.log`
* not touched: game code, assets, theme, `project.godot`, `addons/**`, `docs/**`,
  `contracts`, `WAVEBOARD`
