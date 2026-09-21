# C5 report — the four defects fixed, and the retune applied

**Worker C5** (brief `.agents/gen/combat_repair_wave_task.md`, worker table row C5;
owner rulings 1-4 of the second round, `.agents/gen/owner_playtest_findings_20260921.md`
§"Owner rulings, second round"). Evidence base: C1's ram probe, C2's weapon probe and
C3's decay probe, described in `.agents/gen/combat_repair_c1_report.md`,
`combat_repair_c2_report.md` and `combat_repair_c3_report.md`.

**Scope, and what was not done.** Four defects fixed exactly as scoped, plus the
owner's drag retune. **No second damage-to-work constant** (ruling 2 re-scoped it away:
the ram rides the shipped `GUN_CHIP_RATE`). **The launch fit is untouched** (ruling 1:
the owner judges it in a playtest; `game.gd` and `ship_fit.gd`'s `STANDARD_FIT` are
unchanged, so the launch still installs `[w_laser]`). No asset, no theme, no
`project.godot`, no `addons/**`, no `docs/**`, no `docs/gameplay/18_engine_spec.md`.
`§13` is the owner's file, so the per-class table below is handed over, not written in.

## 1. Verdict, first

| # | Defect | Fix | Measured after |
|---|---|---|---|
| 1 | the rock's collision half (`asteroid.gd:194`, `collision_mask = 0`) | `Asteroid.COLLISION_MASK := 2` (the hull layer), written by `setup` | C1's probe, S1 SHIPPED: the rock takes **`v_peak = 72.821 u/s`, `pos_delta = 20.323 u`** where it took `0.000 / 0.000` before. S2b (mask 1) and the bare-mask-0 control still read `0.000` |
| 2 | the rock's ram sink (the peer's half, offered at `186.179`) | `Asteroid.apply_collision_damage(amount)` → `apply_work(amount × GUN_CHIP_RATE)` | the same ram now credits **18.618 work** and takes **18 ore units** off the rock (`yield 100 -> 82`, work `0.0 -> 0.6179104477612`); a second constant was **not** added |
| 3 | plasma's +25 % through a live shield (C2-F1) | `NpcShip.shield_up()` published, mirroring `player_ship.gd:258` | C2's probe: `_shield_up(npc)` `false -> true`; 1 s of plasma on a live 600 shield **87.500 -> 70.000** (the family's own row); the shields-down case is unchanged at **87.500 on the hull** |
| 4 | the mine's borrowed kinetic cadence (C2-F4) | `interval_of`'s fallback gated on the row's family | C2's probe: `TABLE id=mine interval=0.600 -> 0.000`; cannon/railgun stay 0.600, the rocket 1.200, the instants 0.000, and the mine's damage is still its own `alpha` |
| 5 | the owner's drag retune (ruling 3) | all nine `coast_time` rows × 0.50 (`ship_fit.gd`) | C3's probe: Vanguard `t10 1.890 s -> 0.945 s`, carry `430.32 u -> 216.85 u`; the accelerate legs are unchanged |

Gate: **`[SUMMARY] passed=236 failed=0`** (exit 0), from the wave's 226 baseline plus
C3's 3 and this pass's 7.

## 2. The four fixes, with the probe line that proves each one

All three probes were re-run after the fixes on the commands C1/C2/C3 documented;
every after-log is on disk and each probe re-ran byte-identically against itself
(`diff` empty; C3's log carries a wall-clock field, so its diff is taken with that one
line excluded, exactly as C3 did it):

| Probe | Command | After-log |
|---|---|---|
| C1 ram | `godot --headless --path vajb-orbit res://tests/probe_c1_ram.tscn --quit-after 100000` | `.agents/gen/combat_repair_c5_c1_after.log` |
| C2 weapons | `godot --headless --fixed-fps 60 --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000` | `.agents/gen/combat_repair_c5_c2_after.log` |
| C3 decay | `godot --headless --path vajb-orbit res://tests/probe_c3_flight_decay.tscn --fixed-fps 60 --quit-after 6000` | `.agents/gen/combat_repair_c5_c3_after.log` |

### Fix 1 — the rock's collision half

`game/asteroid.gd`: new `COLLISION_MASK := 2` beside `COLLISION_LAYER` (:64), written
by `setup` (:207). The doc block above it now records why: Godot pairs two bodies from
both sides, `interacts_with` (either mask) decides the pair exists and `collides_with`
(this body's mask ∩ the peer's layer) decides whose mass is in the solve, so a mask of
0 forced the rock's inverse mass to 0. The mask names the hull layer (`HullBody` is
layer 2 / mask 1) and **not** the rock's own, because two rocks are both layer 1 and
`mask 2 & layer 1 = 0` is what still keeps rocks apart.

C1's probe, same scenario, before and after:

```text
before  [C1-RAM] S1 SHIPPED rock layer=1 mask=0 ...
        [C1-RAM] S1 SHIPPED rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
        [C1-RAM] S1 SHIPPED ship body end: pos=(-71.700, 0.000) travelled=328.300 v=(0.000, 0.000)
after   [C1-RAM] S1 SHIPPED kind=asteroid driven=true rock layer=1 mask=2 mass=560.0 damp=3.710 radius=42.00
        [C1-RAM] S1 SHIPPED rock: v_at_contact=(0.000, 0.000) v_peak=72.821 v_final=(0.037, 0.000) pos_delta=(20.323, 0.000) |d|=20.323
        [C1-RAM] S1 SHIPPED post f46   gap=  70.83 ship_v=(  72.82,   0.00) rock_v=(  72.82,   0.00)
        [C1-RAM] S1 SHIPPED post f53   gap=  72.79 ship_v=(  27.64,   0.00) rock_v=(  46.58,   0.00)
        [C1-RAM] S1 SHIPPED ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
```

The rock now takes the contact at the inelastic common velocity and keeps it longer
than the ship does, because it rides `LINEAR_DAMP` 3.71 against the hull's 0.952, so
the pair separates after f46 and the gap grows (`70.83 -> 72.79`). **The ship's half is
unchanged to the digit: `shield -186.179`**, which is the property that matters for
drift. The three controls that must stay inert do:

```text
after   [C1-RAM] S2b MASK1  rock: v_peak=0.000 pos_delta=0.000   (a non-zero mask is not enough)
after   [C1-RAM] C1 CONTROL rock: v_peak=0.000 pos_delta=0.000   (a bare RigidBody2D, mask 0)
after   [C1-RAM] S2 MASK2   rock: v_peak=72.821 pos_delta=20.323 (identical to S1: the shipped mask is the corrected one)
```

C1's S6 after-numbers were `v_peak = 73.351`, `pos_delta = 21.056` at `gap = 64.93`;
this pass reads `72.821 / 20.323` at `gap = 67.35`. **The shift is the retune, not the
mask**: the hull's damp doubled (`0.476 -> 0.952`, printed on every scenario's `hull
body` line), so the same driven step carries the hull slightly less far and the contact
happens 2.42 u later. Both the mask and the retune are in these numbers.

### Fix 2 — the rock's ram sink, through the one chip-rate owner

`game/asteroid.gd`: `apply_collision_damage(amount) -> void` (:238) calls
`apply_work(amount * WeaponsScript.GUN_CHIP_RATE)` (:239). `WeaponsScript` is a
`preload("res://game/weapons.gd")` (:77, the house pattern: a `class_name` global only
resolves after an editor scan). **No new number exists**: the conversion *is*
`WeaponComponent.GUN_CHIP_RATE` 0.10 (`weapons.gd:137`, §6 ruling 17), so a ram and a
shot cannot drift apart, and the amount is whatever the hull's own pipeline offered.

```text
after   [C1-RAM] S1 SHIPPED rock sinks: apply_collision_damage=true take_damage=false damage=false apply_work=true
after   [C1-RAM] S1 SHIPPED rock pools: yield 100 -> 82, work 0.0 -> 0.6179104477612, sink_hits=<no sink> sink_total=<no sink>
after   [C1-RAM] S6 FIXED  rock pools: yield 100 -> 100, work 0.0 -> 0.0, sink_hits=1 sink_total=186.179104477612
```

`18 × WORK_PER_UNIT + 0.6179104477612 = 18.6179104477612 = 186.179104477612 × 0.10`,
exact. S6 (C1's stub sink) still records the offer at `186.179` and stays at 0.000 work,
which is the separation between "the offer exists" and "the rock converts it".

**One consequence the owner should see (it is the ruling's arithmetic, measured):** a
full-speed ram credits 18.618 work, so a rock rolled with **fewer than 19 units cracks**
on one hard ram, exactly as gunfire would crack it. The gate test measures it: an 8-unit
rock + `apply_collision_damage(186.179)` → `yield_units 0`, `cracked` once. If that is
too strong for a ram, the single knob is `GUN_CHIP_RATE` itself (one line, and it moves
guns and rams together); a ram-only rate would be the second constant the owner rejected.

`npc_ship.gd:523-524` offers the same half from an NPC's contact, so an NPC ram now
chips a rock through this same method. That path is not probe-measured; it is the same
call site the player uses.

### Fix 3 — plasma's bonus against a live NPC shield (C2-F1)

`game/npc_ship.gd`: new `shield_up()` (:787) mirroring `player_ship.gd:258`
(`return _shield > 0.0`). C2's mechanism was that `_shield_up` reads a `shield_up()`
method, a `shield` property or a `state` property, and `NpcShip` publishes only
`hull()`/`shield()` *methods*, so every NPC read as shields-down. Publishing the reader
on the hull fixes the reading for every weapon and every NPC at once, and it is what the
player hull already does.

C2's probe, the four lines that move (and only those four):

```text
before  [C2] SINK npc take_damage=true damage=false apply_work=false shield_up=false
after   [C2] SINK npc take_damage=true damage=false apply_work=false shield_up=true
before  [C2] SEAM weapons._shield_up(npc)=false _shield_up(shield_reader)=true (the plasma bonus gate)
after   [C2] SEAM weapons._shield_up(npc)=true _shield_up(shield_reader)=true (the plasma bonus gate)
before  [C2] CASE target=npc shield=up weapon=plasma ... shield=600.000->512.500 (d=-87.500 of 600.000)
after   [C2] CASE target=npc shield=up weapon=plasma ... shield=600.000->530.000 (d=-70.000 of 600.000)
before  [C2] LAUNCH-FIRE group=5 weapon=plasma dry_before="" shots=1 hull_d=+0.000 shield_d=-87.500
after   [C2] LAUNCH-FIRE group=5 weapon=plasma dry_before="" shots=1 hull_d=+0.000 shield_d=-70.000
```

The shields-down row is deliberately unchanged, and it is what proves the bonus still
exists rather than having been switched off:

```text
before/after [C2] CASE target=npc shield=down weapon=plasma ... hull=950.000->862.500 (d=-87.500) shield=0.000->0.000
```

`-87.500 = 70 × 1.25` (§4.1's "+25 % to hull once shields are down") now lands only
where the row says it should. The number never moved; which pool it may touch did.

### Fix 4 — the cadence fallback is family-aware (C2-F4)

`game/weapons.gd`: `interval_of`'s last line is now
`if family_of(weapon_id) == &"kinetic": return KINETIC_INTERVAL` / `return 0.0`
(:1050-1052). `KINETIC_INTERVAL` 0.6 is the cannon's burst cycle, i.e. a *kinetic* row's
own shape, so only a kinetic row may borrow it; a family that states no cadence and is
not kinetic has none. No cadence was invented for the mine.

```text
before  [C2] TABLE id=mine shot_damage=180.000 interval=0.600 chip=0.100 ammo_slot=3
after   [C2] TABLE id=mine shot_damage=180.000 interval=0.000 chip=0.100 ammo_slot=3
unchanged [C2] TABLE id=cannon interval=0.600 ; id=railgun interval=0.600 ; id=rocket interval=1.200
unchanged [C2] TABLE id=laser interval=0.000 ; id=plasma interval=0.000
```

`shot_damage(mine)` is still `alpha` 180, so the fallback never reaches the mine's
damage; the only behaviour change is that the mine's `_shot_timer` is 0 instead of a
borrowed 0.6 s. The mine is `edge`, one per trigger pull, so nothing new fires per pull
and the probe's dry matrix still reads `DRY weapon=mine drained=ammo slot=3`.

## 3. The retune (ruling 3): nine `coast_time` rows × 0.50

`game/ship_fit.gd`, `HANDLING`, the one column the release path reads; the doc block
above the table records the ruling, the measured effect and the reversal
(:142-151). The comment there and in the report's table are the only record: §13 stays
the owner's file.

### The per-class table for the owner's §13 tick

`coast_time` is the §13 row itself; the two figures after it are what the C3 probe
measures (or, for the seven classes the probe does not fly, what the same linear law
derives from the row: `t10 = 0.9 × coast_time`, `carry = 0.5 × max_speed × coast_time`,
both after the launch fit's `h_plate_light` ×1.05 on the time and its ×0.95 on the
speed). The probe-derived row is marked.

| Class | `coast_time` §13 | after | resolved (×1.05) | v_release | t10 before → after | carry before → after |
|---|---|---:|---:|---:|---:|---:|
| Fighter | 1.6 | **0.8** | 1.680 → 0.840 | 427.5 | **1.512 → 0.756** | **362.67 → 183.13** |
| Cutter (Vanguard) | 2.0 | **1.0** | 2.100 → 1.050 | 406.6 | **1.890 → 0.945** | **430.32 → 216.85** |
| Miner | 3.4 | **1.7** | 3.570 → 1.785 | 321.1 | 3.213 → 1.607 | 573.16 → 286.58 |
| Trader | 2.6 | **1.3** | 2.730 → 1.365 | 363.8 | 2.457 → 1.229 | 496.66 → 248.33 |
| Corvette | 1.8 | **0.9** | 1.890 → 0.945 | 470.2 | 1.701 → 0.851 | 444.39 → 222.19 |
| Hauler | 5.2 | **2.6** | 5.460 → 2.730 | 278.3 | 4.914 → 2.457 | 759.90 → 379.95 |
| Gunship | 3.8 | **1.9** | 3.990 → 1.995 | 342.0 | 3.591 → 1.795 | 682.29 → 341.14 |
| Frigate | 3.4 | **1.7** | 3.570 → 1.785 | 363.8 | 3.213 → 1.607 | 649.47 → 324.74 |
| Destroyer | 5.6 | **2.8** | 5.880 → 2.940 | 299.2 | 5.292 → 2.646 | 879.79 → 439.90 |

The first two rows are the probe's own measurements (Vanguard `shipped_base`,
Fighter `fighter_base`); the other seven are the same law read off their §13 rows, i.e.
derived, not measured, and are left unmarked in the table so the two groups are told
apart by this sentence alone. The afterburner case is measured too: Vanguard + burn
`t10 3.024 → 1.512 s`, carry `1098.36 → 551.90 u`; the burn-held control is identical,
sample for sample, as C3 showed it must be.

**A discrepancy to settle before the tick.** Ruling 3 predicts the Vanguard's carry as
"≈ 108 u". Measured, it is **216.85 u** (`dist10` 213.90 u) — half of 430.32, not a
quarter. The ramp is linear in `coast_time` (`d = ½ v · coast_time`), so ×0.50 on the
time is exactly ×0.50 on the carry; the probe's own `derived` line agrees
(`ideal_dist 426.93 → 213.47`). The 108 u figure looks like a ×0.25 reading and is 2×
low against the shipped model. Nothing was tuned to reach it: the ruling's `coast_time`
×0.50 was applied as written, and this is what it measures.

### What the retune did not touch, and what it moved that is not a §13 row

- **Every other §13 handling figure is byte-identical**: `max_speed`, `accel_time`,
  `turn_rate`, `turn_spinup`, `hull_mass` for all nine classes (asserted in the gate).
- **The accelerate legs are unchanged**, measured: the probe's `accel` samples are the
  same to 1 ulp and the derived rates are the same (Vanguard `161.349 u/s²`, Fighter
  `203.571`, afterburner `4.030 s` to 650.56) — the owner's complaint was the release,
  and the release is the only thing that moved.
- **Not touched, and not to be blamed**: `BRAKE_MULT` 1.8, `SLOW_DOWN_RADIUS` 240,
  `ARRIVE_RADIUS` 40, `BOOST_FUEL` 3.0, the afterburner's `1.6 / 3 s / 8 s`, the
  `COLLISION_MIN_DV` 40 floor, `COLLISION_FACTOR` 2.0e-5, `MINE_CYCLE`, the class mass
  column. The body's `linear_damp` moved because it *is* `1 / coast_time`: `0.476 →
  0.952 /s` for the launched Vanguard, which also halves the lateral settle time. That
  is the same ruling, not a second tune.
- **The two numbers in the brief were already stale** and C3 reported it: `DRAG` 120 /
  `ACCELERATION` 420 live nowhere in the tree; the shipped pair is
  `coast_time`/`max_speed`/`accel_time`. This pass did not touch either.
- **A side effect worth one line in a playtest**: C1's undriven-ram scenario can no
  longer reach its rock. S5 COAST, released at 450 u/s 400 u from the rock, now ends
  `NO CONTACT in 300 frames: min gap=143.06 ... travelled=256.936` (it used to close and
  contact at 272.171 u/s). `450² / (2 × 387.238) = 261 u` of carry against a 400 u gap:
  the retune is exactly why. The probe was left as it is, because that line *is* the
  retune's own measurement.

## 4. Every changed constant, with its reversal path

| File | What changed | Before → after | Reversal |
|---|---|---|---|
| `game/asteroid.gd:64` | **new** `COLLISION_MASK := 2` (the hull layer) | none → 2 | delete the const and restore `collision_mask = 0` at :207 |
| `game/asteroid.gd:207` | `setup` writes the mask | `collision_mask = 0` → `= COLLISION_MASK` | as above (one line) |
| `game/asteroid.gd:77` | **new** `WeaponsScript` preload (the chip rate's owner) | none | delete it with `apply_collision_damage` |
| `game/asteroid.gd:238-239` | **new** `apply_collision_damage(amount)` | absent → `apply_work(amount × GUN_CHIP_RATE)` | delete the method; the rock's ram half is dropped again (C1's S1 `sink_hits=<no sink>`) |
| `game/npc_ship.gd:787` | **new** `shield_up()` | absent → `_shield > 0.0` | delete the method; `_shield_up(npc)` returns false again and plasma out-damages its row by 25 % against every NPC |
| `game/weapons.gd:1050-1052` | `interval_of`'s fallback | unconditional `KINETIC_INTERVAL` → gated on `family_of == &"kinetic"`, else `0.0` | delete the two lines for `return KINETIC_INTERVAL` (the mine reads 0.600 again) |
| `game/ship_fit.gd:157-221` | nine `coast_time` rows | `1.6/2.0/3.4/2.6/1.8/5.2/3.8/3.4/5.6` → `0.8/1.0/1.7/1.3/0.9/2.6/1.9/1.7/2.8` | multiply the nine rows by 2.0 and re-run the C3 probe |
| `game/ship_fit.gd:142-151` | the doc block recording the ruling | - | documentation only |
| `tests/test_combat_repair_c5.gd` | **new** suite, 351 lines, 7 tests (one per fix, two for the plasma gate's two readings) | - | delete the file; the gate returns to 229 |
| `tests/test_engine2_cleaving.gd:113-122` | the stale mask assertion | asserted the defect (`mask == 0`) | see §6 |

**No new tunable number was introduced.** The only new numeric constant is
`Asteroid.COLLISION_MASK` (a layer bit, not a feel number), and it is asserted equal to
the hull's own layer read off `player_ship.tscn`, so it cannot drift from the scene.

## 5. Gate

| | before this pass | after |
|---|---|---|
| `[SUMMARY]` | `passed=229 failed=0` (C1/C2/C3's own runs) | **`passed=236 failed=0`** (exit 0, `.agents/gen/c5_gate_after.log`) |
| added | - | `test_combat_repair_c5.gd` (**7**) |

Command: `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
--quit-after 1200`. The gate log has **0 `SCRIPT ERROR`** and one `WARNING`, the
pre-existing `EconomyLog: could not open user://p1l_missing_dir_do_not_create/...` line
from the P1 suite. The C1 probe re-run under `--debug` prints 25 warnings, the same 25
C1 measured before the wave (19 `weapons.gd`, 3 `projectile.gd`, 3 `asteroid.gd`), and
the three attributed to `asteroid.gd` are the pre-existing `size_class` shadowing
warnings in functions this pass did not touch. LSP diagnostics are clean for all four
edited game scripts and the new suite.

The seven tests, one per fix:

| Test | What it pins |
|---|---|
| `test_the_rock_masks_the_hull_layer_so_a_ram_pair_is_two_way` | the mask equals the `HullBody`'s layer read off the scene, both directions of `collides_with` hold, and `mask & layer == 0` (rocks still pass through each other) |
| `test_the_rock_takes_its_half_of_a_ram_through_the_shipped_gun_chip_rate` | the ram's credit is `amount × GUN_CHIP_RATE` to 1e-9, equal to the same amount through `apply_work`, and 18 units leave a 100-unit rock |
| `test_a_ram_reaches_the_crack_path_the_guns_use` | an 8-unit rock cracks on one full-speed ram, `cracked` once |
| `test_plasma_bonus_stays_off_a_live_npc_shield` | 1 s of plasma through the real `_apply_beam`/`_deliver`/`NpcShip.take_damage` path removes exactly 70.000 and 0.000 hull |
| `test_plasma_bonus_lands_once_the_npc_shield_pool_is_down` | the same hold with an inert pool removes exactly 87.500 of hull |
| `test_the_interval_fallback_is_family_aware` | the mine 0.000, cannon/railgun 0.600, rocket 1.200, laser 0.000, and the mine's damage is its `alpha` |
| `test_the_coast_column_is_the_retuned_half_of_the_section_13_rows` | all nine rows are the §13 pre-retune value × 0.50, the rest of the Vanguard's row is untouched, and the launched hull resolves to 1.05 s (the plating multiplier still rides on the retuned row) |

## 6. Deviations to disclose (probe and stale-pin changes, all inside `vajb-orbit/tests/`)

Three test-side lines changed. They are fixture or pin updates required *by* the fixes,
not fixes being hidden, and each is the only change to its file:

1. **`tests/probe_c1_ram.gd:284`**: the fixture's rock now carries **100 units, not 8**
   (one line + a comment). The fix gives the rock the sink it was missing, so the same
   450 u/s ram now credits 18.618 work and an 8-unit fixture would `crack` and
   `queue_free` on the contact frame, deleting the very rock the post-contact trace is
   measuring. 100 units is what C2's probe already carries for the same reason. The
   crack path itself is measured by the new gate suite instead. **This is why the C1
   probe's `yield` reads `100 -> 82` in the after-log where C1's log read `8 -> 8`.**
2. **`tests/probe_c2_weapons.gd:738`**: the dry matrix's choice of which resource to
   empty is now the row's own `instant` flag instead of `interval_of(...) <= 0.0`. The
   two agreed for all five v1 families *until* fix 4 made the mine's interval 0.0, at
   which point the old test would have emptied the mine's Energy (which it does not
   spend) and reported a fire where C2 measured a dry-fire. The flag is what actually
   selects `_fire_beam` against `_fire_projectile`, so the matrix stays about the
   family's resource. Measured effect: none — the mine's row is unchanged from C2's log
   (`DRY weapon=mine drained=ammo slot=3 dry_reason="ammo"`).
3. **`tests/test_engine2_cleaving.gd:113`**: the old assertion
   `assert_eq(body.collision_mask, 0, "rocks mask nothing (the ship masks them)")`
   asserted the defect C1 measured. It is replaced by the corrected contract (the mask
   is the hull layer, and `mask & layer == 0` keeps rocks apart) with a comment naming
   C1. **No other expectation in that suite changed** and nothing was edited to hide a
   failure: the suite is green on the corrected contract.

The only pre-existing gate failure this pass saw was that assertion, and it was fixed by
updating the pin to the ruled contract, not by relaxing it.

## 7. Files

- changed: `vajb-orbit/game/asteroid.gd`, `vajb-orbit/game/weapons.gd`,
  `vajb-orbit/game/npc_ship.gd`, `vajb-orbit/game/ship_fit.gd`,
  `vajb-orbit/tests/test_engine2_cleaving.gd` (the stale pin, §6),
  `vajb-orbit/tests/probe_c1_ram.gd` (fixture yield, §6),
  `vajb-orbit/tests/probe_c2_weapons.gd` (dry matrix, §6)
- added: `vajb-orbit/tests/test_combat_repair_c5.gd`
- evidence: `.agents/gen/c5_gate_after.log`,
  `.agents/gen/combat_repair_c5_c1_after.log`,
  `.agents/gen/combat_repair_c5_c2_after.log`,
  `.agents/gen/combat_repair_c5_c3_after.log`
- not touched: `vajb-orbit/game/player_ship.gd`, `vajb-orbit/game/projectile.gd`,
  `vajb-orbit/game/impact.gd`, `vajb-orbit/game/game.gd`, assets, the theme,
  `project.godot`, `addons/**`, `docs/**`, `CONTRACTS.md`, `WAVEBOARD.md`

## 8. Left for the owner (and open to C6)

1. **The §13 tick**: the nine `coast_time` rows now read `0.8 / 1.0 / 1.7 / 1.3 / 0.9 /
   2.6 / 1.9 / 1.7 / 2.8`; §3's table is the before/after the owner asked for. The
   "≈ 108 u" carry in ruling 3 is 2× low against the measured 216.85 u.
2. **The ram's cleave strength**: one hard ram = 18.618 work, so a rock under 19 units
   cracks on it. `GUN_CHIP_RATE` 0.10 is the single knob (it moves guns and rams
   together, by the owner's own ruling 2).
3. **C2-F3 (the launch fit) is untouched by instruction**: the launch still installs
   `[w_laser]` and no mining laser; C2's measurement of the panel's five-weapon promise
   stays the owner's open gate.
4. **C6's diff targets**: the C1 probe's after-log differs from `combat_repair_c1_ram.log`
   only in the ways §2/§3 spell out (the mask, the sink's `yield`/`work`, the halved
   damp, the S5 no-contact line, and the frame-45 gap that the damp moved); the C2
   after-log differs in exactly six lines (the mine's `interval`, the NPC's `shield_up`,
   the rock's `mask`, the shields-up plasma CASE, the SEAM line and the launch-fit
   plasma row); the C3 after-log differs in the retuned
   config/curve/result lines plus a 1 ulp accel sample.
