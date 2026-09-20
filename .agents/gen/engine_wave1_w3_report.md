# Engine wave 1 — W3 report (asteroids, mining, pickups)

Worker: W3. Status: **done**. Deliverables: exactly the five files named in
`.agents/gen/engine_wave1_task.md` §W3, nothing else touched. The brief's pinned
interfaces 4, 5 and 6 are implemented as written, plus the W4 handoff that the
parallel `game/sector.gd` actually calls (discovered mid-run, §3.4 below).

Everything below is measured, not asserted. Every probe is deleted; its raw output
is kept next to this report (`w3_*_probe.txt`) so W6 can re-run the same gates
(§8) or re-read the numbers without a Godot process.

---

## 1. Files created (measured)

New files, so "before" is absent. Sizes/line endings/md5 from
`py -3.14 .agents/gen/w3_measure.py` (kept for re-derivation).

| File | Bytes | Lines | CRLF | md5 |
|---|---:|---:|---:|---|
| `vajb-orbit/game/asteroid.gd` | 5 834 | 155 | 0 | `36493D5C7D7BD7470796E87B8C10D4C1` |
| `vajb-orbit/game/asteroid_field.gd` | 8 686 | 229 | 0 | `6A299942EDD699974F04D4AFD20C5DDD` |
| `vajb-orbit/game/pickup.gd` | 6 775 | 166 | 0 | `91594EA0A15010821F24BE489FD189EC` |
| `vajb-orbit/game/mining_laser.gd` | 8 428 | 257 | 0 | `792305ECD1AB50CBEEDC78D483AFD6FF` |
| `vajb-orbit/game/mining_laser.tscn` | 333 | 14 | 0 | `AE7437E276EEC22A543DC2813DE695A5` |

Total 30 056 bytes, 821 lines, all LF (the repo's convention). No existing file
was edited: `game.gd`, `game/player_ship.*`, `game/sector*.gd`, `ui/`,
`project.godot`, `docs/`, `assets/` and `addons/` are untouched by this worker.
`tools/` is back to `build_theme.gd` + `derive_icon_tints.gd` (+ `.uid`), and W4's
own two probes are left for W4 to clean (§8).

## 2. Interfaces as shipped (for the W6 aggregation checklist)

| Pinned item | As shipped | Evidence |
|---|---|---|
| 4. `Asteroid` — `class_name Asteroid extends StaticBody2D`, `setup(mineral_id: StringName, tier: int, yield_units: int)`, `apply_work(work: float) -> int` (units this call, `WORK_PER_UNIT := 1.0`), `signal cracked`; solid, blocks beams, cracks at 0 | exactly; plus `is_depleted()`, `look_index()`, `world_radius()`, `mineral_id`/`tier`/`yield_units`/`work` public, group `&"asteroid"`, physics layer 1 | A §4, B §3 |
| 5. `MiningLaser` — `game/mining_laser.tscn` child of `PlayerShip`, `bind(stats: ShipStats)`, `set_active(active: bool)`, hold `mine` to fire, beam 220 u, 1.2 s → 1 unit → 1 `Pickup`, no ammo | exactly; root node `MiningLaser`; `beam`/`BeamCore` `Line2D`s; plus read-only `is_active()`, `has_target()`, `target_position()` for W5's reticle | B §2–§5, D §2 |
| 6. `Pickup` — `class_name Pickup extends Node2D`, `setup(item_id: StringName, amount: int, is_credit_cache: bool)`, 60 s, tractor 120 u at 90 u/s, collect through `PlayerProfile` + `economy_log`, hold-full keeps drifting, frees itself | exactly; group `&"pickup"`; ore `item_id` is the **ore item id** the economy reads (`mineral_iron`), and a bare catalogue mineral id (`iron`) is normalised to it at collection | C §1–§4 |
| W4 handoff (not pinned in the brief) | `setup(config: Dictionary)` with `{&"tier_weights", &"rocks", &"seed"}`, `is_depleted() -> bool`, `respawn(now := -1) -> bool` | D §1 |

Extra, additive API is listed in §3.4; nothing pinned was renamed, widened or
dropped.

## 3. What was implemented, with its spec source

### 3.1 `game/asteroid.gd` (155 lines)

- **Spec:** ENGINE_SPEC §6 ("rocks are solid: ships collide with them, they block
  shots and beams"; "any weapon applies work at 10 %"), §13 (`MINE_CYCLE` 1.2 s),
  §15 ("N cycles on a rock spawn N ore pickups; gun work accumulates at 10 %;
  cracks at yield 0"); 02 §5/§7.
- **Work, not damage.** `apply_work` accumulates *fractional* work and converts to
  whole units at `WORK_PER_UNIT` (`work += amount; while yield > 0 and work >=
  1.0: …`). That single path serves both §6 rates: the laser applies 1.0 per
  cycle, a weapon applies `dps * 0.1 * delta` per hit. `WORK_EPSILON := 0.0001`
  exists because ten `0.1` hits land on 0.9999999999999999 in binary floats, and
  §6's "10 %" is exact by intent, not an eleventh hit (measured: 10 hits → exactly
  1 unit).
- **Solid and blocking.** `collision_layer = 1`, `collision_mask = 0`; the laser
  masks layer 1, so rocks block the beam among themselves and the nearest rock on
  the cursor line wins. A ship becomes solid against rocks by masking layer 1 (the
  ship's own layer is W2's choice).
- **Crack.** `yield_units` 0 → `cracked.emit()` once, then `queue_free()`.
- **Look.** The nine shipped Phase B sprites (`env_asteroid_{S,M,L}{1,2,3}.png`,
  ENVIRONMENT_SPEC §4's three tiers × three silhouettes, ASSET_CATALOG `rgba`)
  are preloaded; each rock rolls one uniformly and is scaled to its tier's target
  width. The collider is a `CircleShape2D` on the sprite's shorter side.
- No `_process`, no `get_node`, no colour literal, no print.

### 3.2 `game/asteroid_field.gd` (229 lines)

- **Spec:** ENGINE_SPEC §8 ("4–8 asteroid fields (6–12 rocks each) … fields
  re-roll on the single 20-minute `WorldClock`"), §13; 02 §5 (rolls), §7, §8
  (depletion, respawn, the ×0.7 window); 11 §1.1 (the per-sector tier weights);
  17 §4 (one accumulator, no Timers).
- **Rolls.** Tier from the weights the caller hands in (11 §1.1, the same
  accumulate order as `MineralCatalog.roll_tier`), mineral from
  `MineralCatalog.roll_mineral(tier, rng)`, yield from
  `MineralCatalog.roll_yield(tier, rng)` — no roll arithmetic is duplicated except
  the weights-keyed tier draw, which the catalogue cannot do (it is sector-keyed).
- **`FIELD_ROCKS_MIN/MAX = 6/12`** as the brief names them: a handed-in count is
  clamped into that band; a missing one is rolled from it.
- **Cluster.** Even angular slots at a jittered radius inside `FIELD_RADIUS` 400 u,
  so 6–12 rocks cannot stack without a separation pass.
- **The clock is read, never owned.** No `Timer`; `respawn()` re-rolls and stamps
  `last_respawn_time`; `last_depleted_time` is stamped when the last rock cracks.
  Both are WorldClock seconds (the sector band's own basis, so the window survives
  a process restart).

### 3.3 `game/pickup.gd` (165 lines)

- **Spec:** ENGINE_SPEC §6 ("tractor range/speed base values in §13; uncollected
  pickups despawn after 60 s"; "hold full: further pickups drift, no auto-sell, no
  jettison"), §13 (60 s / 120 u / 90 u/s), §15; 02 §7 (tractoring, despawn,
  hold-full, per-mineral cargo identity), §7.5/§1.2 (cargo keys, one unit of
  weight per item); 01 §7 (log every economy event); 17 §5 rule 2 (only
  `PlayerProfile` mutates credits/cargo).
- **Motion.** Outside `TRACTOR_RANGE` the pickup is left alone; inside it, it is
  pulled at `TRACTOR_SPEED` and collected at `ARRIVAL_RADIUS` 16 u.
- **Hold-full.** With no room, the pickup is neither pulled nor collected — it
  drifts until its 60 s lifetime ends (02 §7.3). The hold gate is an **ore rule
  only**: a credit cache is not cargo, so a full hold does not block it
  (ENGINE_SPEC §6, "credit caches pay on pickup"). That was a bug found by probe C
  and fixed before this report. The gate also sits *behind* the range check, so a
  field of distant pickups costs no profile read per frame; both edits are
  behaviour-neutral for everything the probes cover, and B/C were re-run after
them (§5).
- **Economy handoff.** Ore: `PlayerProfile.add_cargo(<ore item id>, n)` + one
  `MINE` log line. Credits: the profile's credit API + one `CACHE` log line. Then
  `queue_free()`.
- **Visual.** `env_pickup_ore_pod.png` (ASSET_CATALOG Phase D "world pickup: ore
  container"), drawn 20 u across; credit caches reuse it (no dedicated prop
  exists — art gap, §8.4).

### 3.4 `game/mining_laser.gd` + `mining_laser.tscn` (257 + 14 lines)

- **Spec:** ENGINE_SPEC §6 (cursor-aimed beam, 220 u, one ore unit per 1.2 s of
  contact, one floating pickup of that rock's mineral), §4.3 (`E` fires it, no
  ammo), §13, §15; 02 §7.1; brief §W3 item 3.
- **Trigger is `set_active`.** `game/player_ship.gd` (W2) holds the `mine` action
  and calls `set_active` on the key's edges ("the laser owns its range, cycle and
  targeting; the ship only holds the trigger"), so this file never reads input.
  Losing the target or releasing the key drops the accumulated cycle (02 §7.1's
  cycle is contact time) — measured in probe B §5.
- **Targeting.** A physics ray from the hull toward the cursor, capped at
  `MINE_LASER_RANGE`, masked to the rock layer, with the player ship's bodies
  excluded by RID. The hit point is the pickups' spawn point.
- **Beam.** Two theme-coloured `Line2D`s (3 px `metal_light` at α 0.45 over 1 px
  `text_dim` at α 0.9), normal alpha blending, no hex literals, hidden whenever
  the trigger is off or nothing is targeted.
- **Audio.** One `sfx_mining_chip_01` per extracted unit through
  `AudioManager.play_sfx`.

## 4. Pinches W3 hit against the parallel workers (all documented, none re-designed)

1. **W4's `setup(config)` shape.** `game/sector.gd` was already on disk when this
   worker started, calling `field.setup({&"tier_weights", &"rocks", &"seed"})` and
   then `is_depleted()`/`respawn()` per elapsed band. The field implements exactly
   those names and payload rather than a `populate(row)` of its own invention, and
   probe D re-verifies the pair end to end (8 fields, 70 rocks, 0 bare markers).
2. **W2's trigger.** `player_ship.gd` was also on disk; its `_mount_mining_laser`
   (guarded path), `_bind_laser` (`bind`), `_update_mining_laser` (`set_active`)
   and node name `MiningLaser` are what this scene provides. Probe D mounts the
   real `player_ship.tscn` and confirms the child arrives with W3's script.
3. **`_world_parent()`.** Pickups must not inherit the ship's transform, so they
   are parented to `get_tree().current_scene` (falling back to the tree root in a
   probe that never changed scene) — the same "world space" idiom game.gd's scene
   root gives.
4. **Additive API** (W5/W6 read this): `Asteroid.is_depleted()`,
   `Asteroid.look_index()`, `Asteroid.world_radius()`;
   `AsteroidField.rocks()/rock_count()/rocks_per_cycle()/tier_weights()/
   diminishing_active()/is_depleted()/respawn()`; `MiningLaser.is_active()/
   has_target()/target_position()`; `Pickup`'s public `item_id`/`amount`/
   `is_credit_cache`; groups `&"asteroid"` and `&"pickup"`.

## 5. Commands run, with output

All runs use the console binary the brief names, with the editor left open and no
`--editor` reimport:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  --script res://tools/_probe_w3_<name>.gd
```

| # | Command | Result | Output file |
|---|---|---|---|
| 1 | probe A `_probe_w3_field.gd` | exit 0, `=== checks 604, failures 0 ===` | `w3_field_probe.txt` |
| 2 | probe B `_probe_w3_laser.gd` | exit 0, `=== checks 36, failures 0 ===` | `w3_laser_probe.txt` |
| 3 | probe C `_probe_w3_pickup.gd` | exit 0, `=== checks 20, failures 0 ===` | `w3_pickup_probe.txt` |
| 4 | probe D `_probe_w3_sector_seam.gd` | exit 0, `=== checks 202, failures 0 ===` | `w3_sector_seam_probe.txt` |
| 5 | `res://tests/headless_runner.tscn` (existing suite) | exit 0, `[SUMMARY] passed=53 failed=0` | `w3_p1_regression.txt` |
| 6 | `--quit-after 120 res://game/player_ship.tscn` | exit 0, no error or warning line | `w3_boot_player_ship.txt` |
| 7 | `--quit-after 180 res://game/game.tscn` | exit 0, no error or warning line | `w3_boot_game.txt` |
| 8 | `--check-only --script res://game/asteroid.gd` and `…/mining_laser.gd` | exit 0, no warning (these two reference no autoload, so the brief's known trap does not apply) | inline |
| 9 | `filesystem_manage(op="scan")` (godot-ai, editor left open) | `scan_completed: true`, `global_class_count: 79` — `Asteroid`, `AsteroidField`, `MiningLaser`, `Pickup` are in `global_script_class_cache.cfg` | inline |
| 10 | `lsp_diagnostics` on all four scripts | empty for all four — the documented unreliability of the `gdscript` LSP here; not treated as a gate | inline |

862 probe assertions, 0 failures; 53/53 of the existing P1 suite still green.

**Re-run status of the logs.** Probes B and C were re-run after the last code
change (the credit-cache gate fix and the gate reordering described in §3.3), so
those two logs match the shipped bytes exactly. Probes A and D never instantiate
or drive a `Pickup` (A preloads the script only, D exercises the field and the
ship mount), so their logs predate that change and their assertions are
unaffected by it; the file sizes and md5s in §1 are the final ones.

## 6. Acceptance evidence (measurements)

### 6.1 Probe A — generation, work model, respawn window (604 checks)

- **Population, all seven registry rows** (`rocks: 9`, seeded): every rock resolves
  a catalogue mineral whose tier matches its `tier`, every yield sits inside
  02 §5's `base × 0.5…1.5` band, every rock is inside the 400 u cluster radius,
  carries a collider and joins the `asteroid` group.
- **Tier weights over 360 rocks per sector** (11 §1.1) — measured vs expected:
  s1 100.0/100 · s2 51.1/55 and 48.9/45 · s3 16.4/20 and 83.6/80 · s4 57.8/60 and
  42.2/40 · s5 32.5/35 and 67.5/65 · s6 51.1/55 and 48.9/45 · s7 36.7/40 and
  63.3/60. `T3`/`T4` never appear where the weights forbid them and vice versa.
- **Default count** (no `rocks` handed in): twelve fields rolled
  `[6, 6, 8, 11, 8, 10, 8, 7, 7, 12, 12, 10]` — inside 6…12 and a roll, not a
  constant.
- **Work model:** an 8-unit rock took exactly 8 cycles of 1.0 (residual work
  `0.000000`), reported depleted, and yielded nothing afterwards; the same rock set
  answered `apply_work(0.1)` ten times with exactly 1 unit; the `cracked` signal
  fired exactly once at yield 0 and the rock left the live set (6 → 4 across the
  probe's two cracks).
- **Depletion:** `is_depleted()` true only after the last rock cracked, and
  `last_depleted_time` moved from 0 to the pinned `WorldClock` stamp `1000000`.
  A live field refuses `respawn()`.
- **02 §8 ×0.7:** a virgin T2 field rolls `[7, 4, 6, 5, 7, 5, 4, 3, 7, 6, 6, 3]`
  (full 3…8 band; the set exceeds the ×0.7 ceiling of 5). The same seed respawned
  at stamp `NOW+1200` rolls `[3, 3, 2, 2, 3, 4, 2, 2, 5, 5, 4, 4]` — every value
  inside the ×0.7 band 2…5, i.e. the multiplier is applied to the roll and the
  full-value ceiling is unreachable on a respawn. The rock count is restored and
  `last_depleted_time` is kept.
- **Window query:** `diminishing_active` true at the stamp, true at stamp+299,
  false at stamp+300; a virgin field is never inside the window.
- **Malformed config** (no weights): one warning, no rock, no crash (the defensive
  path only — W4 always passes the registry table).

### 6.2 Probe B — the laser on the real runtime path (36 checks)

Run with the tree driving `_physics_process` (real deltas, real frame timing), the
ship 200 u from the target so the spawned pickups land outside tractor range:

- **Targeting:** ship `(-200, 0)`, cursor world `(0, 0)`, and the rock on that
  line is the target, hit on its near surface `(-38.78, 0)` for a rock of radius
  38.8 u (the sprite look rolls on the global RNG, so the radius differs run to
  run — 42.0 u in an earlier run; the assertion is on the hit point being inside
  the target's own silhouette). The 60 u decoy off the line and the 300 u rock
  past `MINE_LASER_RANGE` were never targeted.
- **Beam:** `points = [(0,0), (161.2,0)]` (two points), halo width 3 px
  `(0.2392, 0.2745, 0.3294, 0.45)` and core width 1 px
  `(0.4196, 0.4549, 0.5176, 0.9)` — the theme's `metal_light` and `text_dim`,
  alpha < 1 (no glow), read from `ui/theme/vajb_theme.tres`.
- **Cycle:** 150 ms of contact mined nothing; after 1 350 ms the yield dropped by
  exactly 1 and exactly 1 pickup existed; after 2 700 ms 2 units and 2 pickups;
  after the third window (4 050 ms of contact) the rock had cracked — 3 cycles,
  3 pickups, all `item_id = mineral_iron`, all `is_credit_cache = false`.
- **Crack:** the laser's target is `null` and the beam is hidden on the next
  frame.
- **Rate on a fresh rock:** 0 units at 150 ms, 0 at 850 ms, 1 at 2 200 ms — the
  unit lands only after a full `MINE_CYCLE`.
- **Release:** `set_active(false)` clears the active flag, drops the target, hides
  the beam and the core, and zeroes the accumulator.

### 6.3 Probe C — tractor, collection, hold-full, lifetime, log (20 checks)

Physics-frame driven (in a headless loop the engine's physics clock runs well
behind the wall clock, so distances are predicted from the frames actually
stepped):

- **Constants:** `LIFETIME 60.0 s | TRACTOR_RANGE 120 u | TRACTOR_SPEED 90 u/s |
  ARRIVAL_RADIUS 16 u`; the Vanguard's catalogue hold is 40 units (02 §1.2).
- **Gate:** the 300 u pickup did not move (`(300.0, 0.0)`, drifted 0.00 u) and was
  not collected.
- **Pull:** the 110 u pickup travelled **45.0 u in 30 physics frames**, exactly the
  1.5 u/frame (90 u/s) that `TRACTOR_SPEED` predicts.
- **Collection:** the 30 u ore pickup was collected, hold 0 → 1 — through
  `PlayerProfile.add_cargo`. The 250-credit cache was collected with no cargo
  movement, credits `10000 → 10250` — through the profile's credit API.
- **Lifetime:** a pickup forced to `_age 59.95` was freed before the next check.
- **Hold-full boundary:** parked at 39 of 40, a further pickup at 30 u *was*
  collected (hold → 40 of 40); with the hold exactly full, a new pickup spawned at
  `(30, 30)` was still alive and **still at (30.0, 30.0)** after 30 frames — not
  pulled, not collected (02 §7.3).
- **01 §7 log** (three lines, one per event, in order):

```
2026-09-18T14:37:27, MINE, mineral_iron, 1, +0, 10000
2026-09-18T14:37:27, CACHE, credits, 250, +250, 10250
2026-09-18T14:37:28, MINE, mineral_iron, 1, +0, 10250
```

The probe drove the real `PlayerProfile` autoload with `save_path` repointed at
`user://test_w3_pickup_profile.cfg` and `EconomyLog.log_path` at
`user://test_w3_pickup_log.txt`; both are deleted at the end, so
`user://profile.cfg` and `user://economy_log.txt` are never touched (the same
fixture the P1 suites use).

### 6.4 Probe D — the two cross-worker seams (202 checks)

- **W4's sector:** `Sector.populate(sector_1 row, seed)` returned the spawn point
  `(0.0, 420.0)`, made **8 fields**, all of them real `AsteroidField`s (**0 bare
  markers**), **70 rocks** total, every field in 6…12, every field holding the
  row's `tier_weights`, every rock in the `asteroid` group with a collider.
  `blips()` = 9 `{friendly 1, neutral 8}` — one blip per field plus the station,
  no per-rock blips. `refresh_clock()` at the same stamp consumed 0 bands, and no
  fresh field reported depleted.
- **W2's mount:** the real `player_ship.tscn` ran one frame and its children were
  `["Hull", "MiningLaser"]`; the mounted child's script is
  `res://game/mining_laser.gd` and it accepted `bind()` and `set_active(true/false)`.

### 6.5 Regression and boot

- The existing headless suite is unchanged and green: `[SUMMARY] passed=53
  failed=0`.
- `res://game/player_ship.tscn` ran 120 frames and `res://game/game.tscn` (W2's
  rewired scene, with the sector, the ship and this laser in the tree) ran 180
  frames — both with an empty stdout besides the engine banner and the
  `godot_ai` game-helper line: no error, no warning, no leftover print.

## 7. Deviations, with the spec text they deviate from

Each item states what the docs say, what was shipped, why, and how to reverse it.
Nothing was silently re-designed; no number was invented as a gameplay value.

1. **Beam colour is neutral steel, not ember.** `FX_SPEC §1.6` fixes the mining
   beam as "a thin burnt ember `#C8461B` line with ember glow `#E8703A` edge". The
   W3 brief item 3 says the opposite ("theme-coloured Line2D/`_draw`, ember accent
   reserved for danger states (ICONS_SPEC §1) — mining beam uses a neutral/steel
   token"), and `STYLE_BIBLE §4` permits emission only in ember plus its sanctioned
   exceptions. Shipped: `metal_light` + `text_dim` tokens from the generated theme,
   plain alpha blending. **Reversal:** two token constants in `mining_laser.gd`.
2. **No chip-spark texture at the contact point.** `FX_SPEC §1.6` specifies a
   four-frame chip-spark burst from `fx_mining_beam.png` (20 FPS, one-shot per chip
   event). `ASSET_AUDIT.md` item 12 records that sheet as a 1×4 strip whose ink sits
   only in the vertical middle half — a plain `hframes = 4` slice is ~75 % empty per
   frame and the per-frame geometry is not documented anywhere. Slice 1 draws no
   spark texture at all and records this as a wiring/art gap rather than guessing a
   crop.
3. **No crack visual.** No shipped FX is catalogued for rock destruction
   (`fx_explosion.png` is "ship / hostile destruction", a 2×3 sheet with an
   explicit empty cell). Yield 0 emits `cracked` and despawns, so a later pass can
   attach a burst without touching this code. Art gap.
4. **02 §8's ×0.7 window is applied at the roll, not per rock.** 02 §8 says "any
   asteroid mined in a field within 5 minutes of its last respawn rolls yield at
   ×0.7" and its implementation note is `now - last_respawn_time < 300 000`.
   Shipped: `respawn()` stamps `last_respawn_time` and the new rocks roll at ×0.7
   while that stamp is inside the window (probe A proves the multiplier and the
   300 s window query). Consequence: a virgin field always rolls full yield and a
   respawned field always rolls at ×0.7, which is 01 §5.5's intent ("mine the same
   rock forever" must not pay) and makes the rule deterministic and testable, but
   the window cannot be "partly elapsed" because the rocks roll at the stamp.
   **Reversal / alternatives for the owner:** stamp after the roll (respawned
   fields full value), or carry the multiplier into extraction instead of the roll.
   Flagged as the wave's one genuine spec ambiguity.
5. **`respawn()` has no second timer.** ENGINE_SPEC §8 makes the 20-minute
   `WorldClock` band the re-roll cadence, and W4's `Sector` calls `respawn()` only
   when a band has elapsed **and** the field reports depleted — so this file keeps
   `last_depleted_time` for 02 §8's bookkeeping but does not gate on it. A
   seconds-based `>= 1200` guard would have doubled the wait to ≈40 minutes for a
   field depleted late in a band (the band boundary is up to 20 minutes away, and a
   refused call is not retried until the next one). Reversal: one condition in
   `respawn()`.
6. **Hold capacity comes from the catalogue, not `ShipStats`.** The pinned
   `Pickup.setup(item_id, amount, is_credit_cache)` carries no capacity and
   `PlayerShip` exposes no state accessor, so the hold limit is read as
   `StationCatalog.ship(profile.active_ship()).cargo` — 09 §5's re-expression of
   the frozen `cargo` column, the same value `game.gd` seeds
   `PlayerState.cargo_max` from, and 40 = 40 for the standard fit. When slice 4's
   `u_cargo`/`u_holds` land, this needs a `bind(stats)` seam (one line) or a
   `PlayerShip` accessor. Open point.
7. **Tractor figures are constants, not stats.** §13's base 120 u / 90 u/s as
   constants: `u_salvage` (2× range and speed) and `u_tractor` (+1 stream) are
   slice 4 and need the same seam.
8. **Rock size table (48 / 84 / 132 u) and pickup sizing (20 u pod, 16 u arrival
   radius).** No spec number exists for either. The rock widths are derived from the
   measured hull scale (the 905 px `ship_vanguard_side.png` at game.tscn's 0.0663 is
   60.0 u), so the three tiers read at 0.8 / 1.4 / 2.2 hull lengths; both are single
   constants with a one-edit reversal, recorded as the phase's visual values.
9. **"Pick ONE existing rock sprite" read as the shipped family.** The brief's item
   1 says to pick one existing asteroid sprite. Shipped: the nine Phase B rocks
   (three tiers × three silhouettes, ENVIRONMENT_SPEC §4) rolled per rock, because
   the family exists precisely to give a field silhouette variety and using it adds
   no art. The Phase E set (`env_asteroid_b1..b6`, "doubles field variety") is
   untouched — available if a later pass wants more.
10. **No idle drift for an out-of-range pickup.** 02 §7 calls them "floating" and
    §7.3 says hold-full pickups "drift", but no speed is specified; a pickup at rest
    holds station until the tractor gate opens. Inventing a drift speed would have
    been a number with no source.
11. **Audio: one chip cue, no beam bed.** `sfx_mining_chip_01` per extracted unit,
    not a 01–04 round-robin: `sfx_mining_chip_04.ogg` is the 20.9 s outlier
    `ASSET_AUDIT.md` item 8 warns about. `sfx_mining_beam_01.ogg` is imported
    `loop = true`, and `AudioManager.play_sfx` hands cues to a one-shot voice pool,
    so a beam bed needs its own start/stop handling — left to a later audio pass
    rather than silently looping a 5 s bed forever.
12. **Probe harness facts worth knowing for W6's re-runs** (not shipped behaviour):
    a node's `set_physics_process(false)` issued from a `SceneTree._initialize()`
    reads back `false` immediately but is `true` by the next frame, so probes here
    drive the tree's real `_physics_process` and predict distances from
    `Engine.get_physics_frames()`; and in a headless `--script` loop the physics
    clock advances at roughly 0.4× wall time. Also, `get_global_mouse_position()`
    errors with a null viewport during `_initialize()` — the probes read the cursor
    on the first frame instead, which is where the laser sees it in a game too.

## 8. Open points and handoffs

1. **HUD cargo fill is W2's half of the mining loop (highest-value item here).**
   The pickups write ore into `PlayerProfile` (02 §7.5, 17 §5 rule 2), and
   `game/player_ship.gd`/`game.gd` seed `PlayerState.cargo_max` from `ShipStats` —
   but nothing currently mirrors the profile's cargo *total* into
   `PlayerState.set_cargo_used()`, which is the only channel the HUD reads
   (§3.9). Until game.gd sums `PlayerProfile.cargo_items()` into the state, the
   HUD cargo bar will not move while mining even though the hold fills. W3 cannot
   close this: the pickup never sees a `PlayerState`, and cargo ownership is the
   profile's.
2. Slice 4 seams named above: `u_salvage`/`u_tractor` (tractor range, speed,
   streams) and `u_cargo`/`u_holds` (hold capacity) need a
   `Pickup.bind(stats: ShipStats)` seam or a `PlayerShip` accessor.
3. Slice 2's gun hook is deliberately absent beyond `Asteroid.apply_work`:
   a weapon calling `apply_work(dps * 0.1 * delta)` gets §6's 10 % rate with no
   change here (probe A measures the accumulation).
4. Art gaps: a rock-crack FX, a credit-cache prop, and a decision on the
   `fx_mining_beam.png` chip-spark crop (§7.2, §7.3).
5. The `Sector` blip feed does not include pickups — 11 §3's blip classes have no
   pickup entry, so this is per spec, noted only so it is not read as an omission.
6. **Editor-side observation, no W3 file involved:** the open editor's error log
   holds a parse error at `res://ui/station/exchange_panel.gd:319`
   (`Function "_icon_tint()" not found in base self`), while that file (mtime
   13:34, untouched this wave) defines `_icon_tint` at line 869 — it reads as a
   stale incremental-reload artifact rather than a real break; also W2's
   `tools/_probe_w2_game.gd` has StringName→NodePath parse errors and
   `assets/icons/tint/icon_ingot_platinum_192.png` fails to open its `.ctex`.
   Flagged for the orchestrator/W6; none of the four W3 scripts appears in that
   log, and both scene boots (§5 rows 6–7) are clean.
7. The four probe scripts are deleted, with their `.uid` sidecars, as the brief
   requires; `tools/` holds only `build_theme.gd`, `derive_icon_tints.gd` and W4's
   two in-flight probes. W6 can recreate any probe from §5–§6 (each assertion is
   stated with its expected value) or ask for the same file set again.
