# A1 — rock cleave: the owner's asteroid ruling, implemented and measured

Wave: `rock_cleave` (brief `.agents/gen/rock_cleave_wave_task.md`, law read in the order
the brief fixes). Worker A1, coder. Date 2026-09-21, host Linux
(`/home/kamil-paluszkiewicz/VajbOrbit`), engine `4.7.2.stable.official.ed1daf0bf`.

Owner ruling executed, verbatim: *"asteroids breaking effects (they should somehow
explode, random fragments from 2 to 5 moving in random directions)"*.

Law cited: `docs/gameplay/18_engine_spec.md` **§6** ("Asteroids — tiered cleaving
(ruling 17)" and "**Rocks are solid**", owner-locked) and **§13**'s "**Cleaving (ruling
17)**" rows (`Fragment split` / `Ejection` / `Fragment mineral`); `docs/gameplay/
02_minerals.md` **§5** (the mineral roll, the yield roll and the per-tier weights) and
**§8** (respawn, the ×0.7 window and "respawn re-rolls minerals and yields"); `docs/design/
FX_SPEC.md` **§1.4** (the five-frame explosion) and **§7.3** (one-shot sheets are
`AnimatedSprite2D`, `loop = false`, `animation_finished → queue_free`); `docs/CONTRACTS.md`
**§5** (the pinned `Asteroid`/`AsteroidField` signatures) and **§9** (the gate).

---

## 1. The four changes, exactly as the brief's table pins them

| # | Brief's change | What shipped | Where |
|---|---|---|---|
| 1 | Fragment count **uniform random 2–5 per cleaving tier** (Large → 2–5 Medium, Medium → 2–5 Small) | `FRAGMENT_SPLIT = {S: (0,0), M: (2,5), L: (2,5)}`; the field rolls `rng.randi_range(split.x, split.y)` | `game/asteroid.gd:107-112`, `game/asteroid_field.gd:334-346` |
| 2 | Ejection direction **uniform over the full circle**; speed still `linear_velocity × 1.2` | `FRAGMENT_EJECT_CONE_DEG` 15.0 → **360.0** (the field rotates the parent velocity by `randf_range(-cone, +cone)`, so 360° is the whole circle and one swap restores the cone); `FRAGMENT_EJECT_MULT` unchanged at 1.2 | `game/asteroid.gd:116/124`, `game/asteroid_field.gd:366-369` |
| 3 | **The break explodes**: one `fx_explosion` sequence at the rock's centre, rock-scaled, + one cue (+ the shipped shockwave helper on nearby bodies) | `Projectile.spawn_rock_break(parent, centre, 2 × world_radius())` → FX_SPEC §1.4's five frames via `spawn_sheet`'s new optional `world`; `Projectile.play_impact(self, IMPACT_KIND_ROCK)` → `play_pool(&"sfx_impact_rock")`; `Impact.apply_shockwave` on the field's rocks and the tree's hull bodies | `game/asteroid_field.gd:279-321`, `game/projectile.gd:428-430, 1248-1268, 1291-1297` |
| 4 | A Small keeps bursting **1–2 pickups**; a yield-0 rock still cracks/despawns **without fragments** but **does** play the break | `_cleave` unchanged in shape (Small → `_spawn_pickup_burst`, `cleaves() == false` → nothing); `_break_read` runs **before** `_cleave` in `_on_rock_cracked`, so *every* depletion reads as a break | `game/asteroid_field.gd:256-268, 334-338` |

Plus the audio row the brief orders: `CUE_POOLS` gains **`&"sfx_impact_rock"`** —
`round_robin` over the four takes that already sat on disk with no row (L53),
`pitch 0.0`, `volume_db [0.0, 0.0]`, exactly the `sfx_impact_hull` sibling's shape
(`autoload/audio_manager.gd:125-144`).

Numbers used, and none invented. `2..5` (both tiers), `360.0`, `1.2`, `96..224 u`,
`play_pool(&"sfx_impact_rock")` are the brief's own §1 table (its "proposed" rows, the
owner's to tune). `world_radius()` and the four takes are shipped values. The only new
names are the brief's named constants, each with its reversal in the code:

```gdscript
# game/projectile.gd — the one optional scale override, as a named constant trio
const ROCK_BREAK_WORLD_SCALE := 1.2
const ROCK_BREAK_WORLD_MIN := 96.0     # the FEEDBACK explosion row's own `world`
const ROCK_BREAK_WORLD_MAX := 224.0    # above the largest look's 132 u x 1.2 = 158.4 u
```

Reversals: restore the two retired `FRAGMENT_SPLIT` rows; `FRAGMENT_EJECT_CONE_DEG`
→ `15.0`; delete the `ROCK_BREAK_*` trio (or set the clamp to the row's 96 u) and the
`CUE_POOLS` row (the cue falls back to `play_sfx`, take 01, as before).

**Untouched, verified by the diff:** every mining/balance number (`WORK_PER_UNIT`,
`WORK_EPSILON` 0.0001, `MINE_CYCLE` 1.2 s, the 10 % gun chip, `ROCK_MASS_MULT` 4 ×
`ship_miner`, `LINEAR_DAMP` 3.71, `DRIFT_SPEED_CEILING` 10), 02 §5's two rolls and the
fragment inheritance path (`mineral_id`/`tier` inherited, `_rolled_yield(tier)` re-rolled),
02 §8's bookkeeping (`last_depleted_time`, `last_respawn_time`, `respawn`, `diminishing_
active`, `DIMINISHING_WINDOW_SECONDS`, `DIMINISHING_YIELD_MULT`), CONTRACTS §5's pinned
signatures (`setup`, `apply_work`, `size_class`, `cleaves`, `eject_velocity`,
`world_radius`, `signal cracked`; `AsteroidField.setup/is_depleted/respawn`), and §13's
collision/recoil/explosion terms (`COLLISION_FACTOR`, `COLLISION_MIN_DV`,
`KNOCKBACK_FRACTION`, `EXPLOSION_P0` 4 000, `EXPLOSION_WINDOW` 0.2 — read, never
re-declared).

---

## 2. Gate

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

- **Measured before this wave, at HEAD `8d189bf`: `passed=372 failed=0`, exit 0** (re-measured
  with all six of this wave's files stashed, in the same session). The brief
  says 311 (the slice-2.5 close); the tree at HEAD measures **372**, so 372 is the number
  that moves. (CONTRACTS §9: "the count to read is the measured one with zero failures,
  never a stale total".)
- **Measured after: `passed=378 failed=0`, exit 0**, i.e. **+6**, the whole growth the
  cleaving suite (`test_engine2_cleaving`, 9 → 15 tests). No other suite's count moved.
  Per-suite counts and the before/after lines are recorded in
  `.agents/gen/rock_cleave_a1_gate.txt`.
- The two exit-time counters (`ObjectDB instances were leaked`, `resources still in use`)
  are **not** a signal here: unchanged code reads 84/36 in one run and 18/8 in another, this
  wave's tree reads 34/2, and every run is exit 0 with the same summary.

Only two non-`[PASS]` lines in the green run, both pre-existing and both proven so:

- `ERROR: Parameter "data.tree" is null.` from `weapons.gd:1329 _world_parent` on a detached
  bow in `test_combat_repair_c5.gd`. **Proof:** with all six of this wave's files stashed,
  `-- --suite=test_combat_repair_c5` still prints the identical line at the identical
  position (`passed=7 failed=0`).
- `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.` at
  `tests/test_weapon_fx_f4.gd:176` — LOW_BACKLOG **L61**, recorded as pre-existing by the
  flight-feel wave; the file is untouched here.

---

## 3. The deterministic probe, raw

`vajb-orbit/tests/probe_rock_cleave.gd` + `.tscn` (scene run, so the `AudioManager` autoload
is reachable), one field seeded `20260921`. Log kept beside this report:
`.agents/gen/rock_cleave_a1_probe.txt`.

```bash
godot --headless --path vajb-orbit res://tests/probe_rock_cleave.tscn --quit-after 900
```

```text
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[RC] boot audio=true pickup_leaf=true rocks=6
[RC] SPLIT L=(2, 5) M=(2, 5) S=(0, 0) pickup=(1, 2) eject_mult=1.20 cone=360.0
[RC] ok   split_rows - both cleaving tiers 2-5, a Small still fragments into nothing
[RC] ok   eject_constants - x1.2 speed, full-circle direction
[RC] COUNT Large rolls=[4, 2, 4, 3, 4, 4, 4, 4] min=2 max=4 tiers_landed_in=1 landed=[1]
[RC] ok   count_Large_bounds - every Large cleave rolled inside 2-5
[RC] ok   count_Large_variety - the count varies roll to roll (seen 2..4 over 8 cleaves)
[RC] ok   count_Large_size - a Large's fragments are one tier down
[RC] COUNT Medium rolls=[5, 4, 3, 4, 4, 4, 2, 3] min=2 max=5 tiers_landed_in=1 landed=[0]
[RC] ok   count_Medium_bounds - every Medium cleave rolled inside 2-5
[RC] ok   count_Medium_variety - the count varies roll to roll (seen 2..5 over 8 cleaves)
[RC] ok   count_Medium_size - a Medium's fragments are one tier down
[RC] DIR deviations_deg=[-6.255, 25.124, -75.346, 140.673, -33.178, 19.816, 108.772, 38.404, 85.695, -54.437, 175.57, -99.089, -76.718, 44.241, 76.794, -174.393, 123.014, -166.488, -112.738, 13.746, 165.2, 86.157, 100.553, 60.892, 25.6, 40.543, 53.454]
[RC] DIR widest_pair=179.766 deg (cleave 5: [163.121419116939, -126.380547495877, -72.6310568413784, 53.8534427185714, -154.69323888871]) past_15=25 of 27 past_90=10
[RC] SPEED ratio_min=1.2000 ratio_max=1.2000 fragments=27
[RC] ok   direction_full_circle - a fragment lands more than 90 deg off the parent's heading: the +-15 deg cone cannot produce one
[RC] ok   direction_pair_spread - two fragments of one cleave landed 179.8 deg apart (cleave 5)
[RC] ok   eject_speed - every fragment ejects at the parent's velocity x 1.2
[RC] FX large radius=66.0000 diameter=132.0000 expected_world=158.4000 sprite=true at=(240.0, -80.0) scale=0.175221 row=(world 96.0, source (904.0, 776.0)), sprite_frames=5 alive_names=["explosion", "explosion2", "explosion3", "explosion4", "explosion5", "explosion6", "explosion7", "explosion8", "explosion9", "explosion10", "explosion11", "explosion12", "explosion13", "explosion14", "explosion15", "explosion16", "explosion17", "explosion18", "explosion19", "explosion20", "explosion21", "explosion22", "explosion23", "explosion24", "explosion25"]
[RC] ok   fx_spawn - one explosion sprite per break (24 -> 25)
[RC] ok   fx_centre - the sequence sits on the rock's centre (240.0, -80.0)
[RC] ok   fx_scale - scaled to 158.40 world units (row source (904.0, 776.0))
[RC] CUE played=sfx_impact_rock_01 (before sfx_impact_rock_04) pool_takes=[&"sfx_impact_rock_01", &"sfx_impact_rock_02", &"sfx_impact_rock_03", &"sfx_impact_rock_04"] mode=round_robin in_pool=true row_pitch=0.0 volume=[0.0, 0.0]
[RC] ok   cue_pool_row - L53's four takes are a round-robin row
[RC] ok   cue_plays - the break played a take from that row
[RC] CUE round_robin=["sfx_impact_rock_01", "sfx_impact_rock_02", "sfx_impact_rock_03", "sfx_impact_rock_04", "sfx_impact_rock_01"]
[RC] ok   cue_rotates - consecutive reads of the row do not repeat the previous take
[RC] FX small diameter=48.0000 raw_1.2x=57.6000 expected_world=96.0000 scale=0.106195
[RC] ok   fx_scale_floor - a Small's break takes the row's own 96 u floor (its raw 1.2x read is 57.60 u)
[RC] BARE cleaves=false fragments=0 fx=26->27 cue=sfx_impact_rock_03 (was sfx_impact_rock_02) live=96->95
[RC] ok   bare_no_fragments - a yield-0 rock cleaves into nothing
[RC] ok   bare_break_read - but it still explodes and still plays the break cue
[RC] BURST pickups_per_small=[1, 1, 1, 2, 2, 1]
[RC] ok   pickup_burst - a Small bursts 1-2 pickups of its mineral
[RC] BLAST offset=20.0 curve=9.9751 window=0.2 velocity 0.000000 -> 0.254471 dv_x=0.254471
[RC] ok   blast_shoves_neighbour - the neighbour 20 u away was pushed outward by the break
[RC] done failures=0
WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 2 resources still in use at exit (run with `--verbose` for details).
   at: clear (core/io/resource.cpp:822)
```

Readings, each against the brief's measurement list:

- **count bounds, both tiers**: `rolls=[4,2,4,3,4,4,4,4]` (Large, min 2 / max 4) and
  `[5,4,3,4,4,4,2,3]` (Medium, min 2 / max 5) — every roll inside 2–5, and both lists vary
  (proof that the row is a roll and not a constant). `landed=[1]` / `[0]` is the tier each
  tier's fragments landed in: Large → Medium, Medium → Small.
- **direction spread**: 27 fragments, deviations from the parent heading spread over the
  full circle (`-174.4° … +175.6°`), **25 of 27 past the retired ±15°** and 10 past 90°; the
  widest single cleave pairs `163.1°` with `-154.7°`, i.e. **179.8° apart** — a ±15° cone
  cannot produce either number.
- **speed multiplier**: `ratio_min = ratio_max = 1.2000` over 27 fragments.
- **FX spawn**: one `AnimatedSprite2D` per break, on the rock's centre `(240, -80)`, scaled
  `0.175221 = 158.4 / 904` — the rock's own diameter 132 u × 1.2, i.e. **not** the hull-sized
  96 u; the sprite carries FX_SPEC §1.4's **5 frames**. The `alive_names` list is the engine's
  own sibling renaming (`explosion`, `explosion2`, …) recorded so the reader can see why the
  probe matches by prefix.
- **the floor's own case**: a Small's diameter 48 u × 1.2 = 57.6 u is under the row's 96 u,
  so its break draws at `96/904 = 0.106195` — the clamp, not a spark.
- **the cue**: played `sfx_impact_rock_01`, a take of the four-take `round_robin` row, and
  five consecutive reads walk `01 → 02 → 03 → 04 → 01`: the L53 row is live and does not
  repeat the previous take.
- **yield-0 path**: `cleaves=false`, `fragments=0`, live 96 → 95 (it left), and the break
  still fired (`fx=26→27`, cue `_02 → _03`).
- **pickup burst**: 1, 1, 1, 2, 2, 1 pickups over six Smalls — inside 1–2, and the pickup
  leaf itself compiles (`pickup_leaf=true`: it was repaired to
  `assets/env/pickup/env_pickup_ore_pod.png`, so the burst is no longer "blocked").
- **bonus, the blast**: a Medium rock 20 u away moves `0.000000 → 0.254471 u/s` outward
  during `EXPLOSION_WINDOW` (0.2 s) — `Impact.apply_shockwave` on the curve's own
  `I(20) = 9.9751` impulse-units, no new constant.

---

## 4. Tests

`vajb-orbit/tests/test_engine2_cleaving.gd` — **9 → 15** (the brief's sanctioned move):

| Test | State |
|---|---|
| `test_rock_is_a_heavy_damped_rigid_body` | kept verbatim (ruling 8 untouched) |
| `test_size_class_follows_the_look_row` | kept (integer division made explicit) |
| `test_apply_work_arithmetic_is_unchanged` | kept verbatim (the 10 % chip rate) |
| `test_depletion_emits_cracked_once` | kept verbatim |
| `test_the_split_table_is_the_amended_row` | **updated**: L `(2,5)`, M `(2,5)`, S `(0,0)`, pickups `(1,2)`, mult 1.2, cone **360.0** |
| `test_large_cleaves_into_two_to_five_mediums` | **updated**: bounds 2–5 (was exactly 2–3); keeps mineral inheritance, the re-rolled yield, the ×1.2 ejection and Medium-ness |
| `test_medium_cleaves_into_two_to_five_smalls` | **updated**: bounds 2–5 (was exactly 2), fragments are Small |
| `test_the_fragment_count_varies_inside_the_amended_bounds` | **new**: 40 seeded cleaves, ≥2 distinct counts all inside 2–5 (a fixed row cannot pass) |
| `test_ejection_directions_are_uniform_over_the_full_circle` | **new**: a deviation past 90° and a within-cleave pair past 90° |
| `test_fragments_join_the_same_field` | kept verbatim |
| `test_the_break_spawns_the_explosion_on_the_rock_centre_scaled_to_it` | **new**: one sheet per break, on the centre, at `1.2 × diameter`, 5 frames |
| `test_the_rock_break_explosion_is_floored_and_capped` | **new**: the 96 u floor and the 224 u ceiling |
| `test_the_break_plays_the_rock_cue_from_its_four_take_pool` | **new**: the row (4 takes, round-robin), the break plays a take, the next read moves on |
| `test_yield_zero_cracks_bare_and_still_draws_the_break` | **updated**: now also asserts the FX and the cue (ruling 17's bare crack + the death read) |
| `test_a_small_bursts_one_to_two_pickups` | **new**: no fragments, 1–2 pickups carrying the rock's ore id, break drawn |

The cue assertions seed `AudioManager.last_sfx()` with another shipped cue first
(`play_sfx(&"sfx_impact_hull")`), because the row cycles and "the value changed" is not
evidence on its own (`test_flight_beam_g2.gd`'s precedent).

**One assertion outside this suite moved, and it had to**: `tests/test_weapon_fx_f2.gd:144`
asserted `last_sfx() == &"sfx_impact_rock"` after a gun hit on a rock. With the L53 row in
place that call now resolves *through* the pool, so the cue's name is a take
(`sfx_impact_rock_0N`). The assertion became the same membership form the suite already uses
for the hull and shield pools (`CUE_POOLS[ROCK_POOL][&"takes"].has(...)`) — strictly stronger
than "the bare cue name" was, and the only way to have both the four takes and the old
assertion. Flagged for A2 as a deliberate, brief-mandated move.

The suite's fixture host is the `PlayerProfile` autoload, not the tree root: a suite's
`suite_setup` runs while the root is still building children and `add_child` on it is
refused ("Parent node is busy setting up children") — the `test_weapon_fx_f2.gd` arrangement.

---

## 5. The warning ledger (CONTRACTS §9's instrument)

`vajb-orbit/tests/probe_rock_cleave_lint.gd` + `.tscn` (same harness as `probe_g4_lint.gd`:
one file per marker block, `CACHE_MODE_IGNORE`, attribution read off the `at:` line), with
`--only=` so a pre-existence A/B is measurable.

```bash
godot --headless --debug --path vajb-orbit res://tests/probe_rock_cleave_lint.tscn --quit-after 900
```

| File | Warnings |
|---|---|
| `game/asteroid.gd` | **3** — `size_class` parameter shadow at :220/:329/:350 |
| `game/asteroid_field.gd` | **0** |
| `game/projectile.gd` | **3** — `source`/`scale`/`material` shadow at :1443/:1447/:1709 |
| `autoload/audio_manager.gd` | **0** |
| `tests/test_engine2_cleaving.gd` | **0** (the wave's own rewrite; it had 13 rows before this pass) |
| `tests/test_weapon_fx_f2.gd` | 0 rows of its own (the block shows `npc_registry.gd`/`npc_brain.gd`/`npc_ship.gd` rows, which its dependencies drag in) |
| `tests/probe_rock_cleave.gd` | **0** |

**Every remaining row is pre-existing, proven by A/B, not asserted:**
`git stash push -- vajb-orbit/game/projectile.gd vajb-orbit/game/asteroid.gd` then
`-- --only=res://game/projectile.gd --only=res://game/asteroid.gd` reads the **same six
rows** at HEAD's line numbers (`projectile.gd:1408/1412/1674`, `asteroid.gd:197/305/326`;
this wave's +35 and +23 lines shift them to the 1443/1447/1709 and 220/329/350 lines above).
`asteroid.gd`'s three are CONTRACTS §9's own G4 record ("`game/asteroid.gd` 3"), and its
`size_class` parameter name is CONTRACTS §5's pinned signature, so it is **not** renamed
here. The stash was popped immediately (verified by `git status`).

---

## 6. Deviations, decisions and open items

1. **`_world_parent()` gained an `is_inside_tree()` guard** (`asteroid_field.gd:442`, and
   `_blast_targets` likewise). Before this wave the only caller was the pickup burst, which
   a detached field never reached in the gate; the break read now reaches it on *every*
   depletion, and `get_tree()` on a node with no tree prints
   `ERROR: Parameter "data.tree" is null.` into the gate log — CONTRACTS §9 forbids that.
   The guard changes no in-tree behaviour (the fallback was already `self`).
2. **The blast's target set** is the field's own live rocks plus the tree's
   `&"player_ship"` / `&"npc_ship"` members walked to their physics body through
   `impact_body` (both shipped hulls expose it), exactly as `game.gd`'s wreck blast walks to
   the player's. The gate is `Projectile.MIN_SHOCKWAVE_IMPULSE` — the floor
   `projectile.gd`'s own blast query already stops at (~63 u) — so a distant hull is skipped
   rather than handed a tween of zero impulses. **No radius constant was invented.**
3. **`CONTRACTS.md` §5's cleaving sentence is now stale** ("`FRAGMENT_SPLIT` L (2,3) → M,
   M (2,2) → S … ejection `× 1.2` inside a ±15° cone"). The brief makes the §1 table law and
   `docs/` off-limits to this worker; the living contract's update belongs to the review
   wave. Same for `18_engine_spec.md` §6/§13/§15 — **the owner's tick is owed** (§6's
   "2–3 Medium / 2 Small / ±15° cone" wording and §13's two cleaving rows).
4. **Proposed rows for the owner to tune** (the brief's table, shipped as proposed):
   `FRAGMENT_SPLIT` (2,5) both tiers · `FRAGMENT_EJECT_CONE_DEG` 360.0 ·
   `ROCK_BREAK_WORLD_SCALE/MIN/MAX` 1.2/96/224 · the cue `play_pool(&"sfx_impact_rock")`.
5. **AUDIO_SPEC §4.2's S4 layer recipe is not expressible** in this manager: the spec asks a
   foley at pitch **0.60–0.85** plus a sub-thump at pitch 0.5, −9 dB, and the pool's `pitch`
   is a ± spread around 1.0 with one voice per cue. The four takes therefore ship as
   imported, mirroring the `sfx_impact_hull` row, and the deviation is recorded in the row's
   own comment. Reported, not silently smoothed over.
6. **The brief's gate number (311) is stale**; HEAD measured **372**. Recorded above.
7. **Not touched, by rule**: `assets/**`, the theme, `project.godot`, `addons/**`, `docs/**`.
   `git diff --stat` is exactly the six files named in §7 plus the four new files under
   `tests/`.

---

## 7. Files

```
vajb-orbit/game/asteroid.gd                 |  38 ++-  the amended rows + the two constants
vajb-orbit/game/asteroid_field.gd           | 128 ++-- the break read, the blast, the guarded world parent
vajb-orbit/game/projectile.gd               |  39 ++  the optional world override + spawn_rock_break
vajb-orbit/autoload/audio_manager.gd        |  20 ++  the sfx_impact_rock pool row (L53)
vajb-orbit/tests/test_engine2_cleaving.gd   | 427 ++-- 9 -> 15 tests
vajb-orbit/tests/test_weapon_fx_f2.gd       |  12 +- the rock cue assertion, pool membership
vajb-orbit/tests/probe_rock_cleave.gd|.tscn        new  the deterministic probe
vajb-orbit/tests/probe_rock_cleave_lint.gd|.tscn   new  the warning ledger
.agents/gen/rock_cleave_a1_probe.txt               new  the probe's raw log
```

Close-out for the orchestrator: gate `passed=378 failed=0`; the reports for
`verify_wave.py verify --baseline rock_cleave_start --expect-reports` are this file, the
probe log and (after A2) `rock_cleave_a2_report.md`.
