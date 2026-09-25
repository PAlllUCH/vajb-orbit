---
slice: S12
worker: S12-K1
model: "deepseek-flash"
status: informational
gate: "812/0 -> 812/0"
---

# S12-K1 report

## Result
`vajb-orbit/tests/probe_s12_rock_rate.gd` measures delivered ore per second and per
rock for LASER / GUN3 / GUNMAX on the §4 pinned T1 field: two runs byte-identical
(md5 below), `done failures=0`, exit 0. No production file, profile or live
`user://` was touched; the gate reads `passed=812 failed=0`.

## How to run
```
XDG_DATA_HOME=/tmp/s12_k1_run1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" --script res://tests/probe_s12_rock_rate.gd
```

## Rate table (T1, seed 12061, 6 rocks; 26 rocks spawned; ratio = LASER/leg)
| leg | barrels | delivered | units/s | units/rock | seconds | depletion work/s | steps | mining:gunning rate | per rock |
|---|---|---|---|---|---|---|---|---|---|
| LASER | 1 | 171 | 0.833333 | 6.576923 | 205.200 | 0.833333 | 171 | 1.000 | 1.000 |
| GUN3 | 3 | 25 | 1.689189 | 0.961538 | 14.800 | 13.500000 | 74 | **0.493** | **6.840** |
| GUNMAX | 7 | 25 | 3.941441 | 0.961538 | 6.343 | 31.500000 | 74 | **0.211** | **6.840** |

Read: the laser extracts 0.833 u/s and realises 6.58 u per rock; a gun rack
*delivers* 0.96 u per rock and buys only time — GUN3 and GUNMAX deliver the
identical 25 units from 74 shots, so the rate ratio falls 0.49 → 0.21 while the
per-rock ratio stays 6.84. Hold fill (40 / 120 units): 48.0 / 144.0 s, 23.7 / 71.0, 10.1 / 30.4.

## Single-rock row (seed 12061, `rocks()[0]`: iron T1 MEDIUM, `yield_in=7`)
| row | units | seconds | units / yield_in | scope |
|---|---|---|---|---|
| LASER_OWN | 7 | 8.400 | 1.000 | the rock body alone (01 §5.6 invariant 1) |
| LASER_FAMILY | 28 | 33.600 | **4.000** | the whole cascade it cleaves into |
| GUN3_FAMILY | 5 | 2.400 | **0.714** | burst pickups from the cascade's Small end |
| GUNMAX_FAMILY | 5 | 1.029 | **0.714** | same 5 units; rack size buys time only |

Read against 01 §5.6: the shipped laser realises 100 % of the rock's own yield, but
its cascade re-rolls to 4.0x (invariant 3's minting, shipped); the shipped gun
realises 5/7 = 71 % of that rock's **own** yield — 7x above the proposed
`GUN_BURST_SHARE` 0.10 — so the tree fails invariant 1's 10x floor (per-field 6.84x,
per-rock 1.4x). Where §5.6 is a depletion claim it is confirmed exactly: laser
0.833 u/s (doc 0.83), GUN3 13.500 work/s (doc ≈13.5).

## Evidence
Run 1 stdout, the `[S12K1]` rows only (34 rows):
```
[S12K1] probe=rock_rate field tier_weights={ 1: 100 } rocks=6 seed=12061
[S12K1] CONST GUN_CHIP_RATE=0.10 src=game/weapons.gd
[S12K1] CONST module=w_cannon WeaponsScript.weapon_id(module)=cannon row_of(module)_empty=true (the family table is keyed by family id)
[S12K1] CONST shot_damage(cannon)=27.0 interval_of(cannon)=0.600 burst_on=0.350 burst_off=0.250 burst_sum=0.600
[S12K1] CONST shots_per_second=barrels/interval_of(cannon) GUN3(3)=5.000/s GUNMAX(7)=11.667/s
[S12K1] CONST WORK_PER_UNIT=1.0 src=game/asteroid.gd
[S12K1] CONST MINE_CYCLE=1.200 src=game/mining_laser.gd
[S12K1] CONST TIER_BASE_YIELD={ 1: 6, 2: 5, 3: 4, 4: 3 } YIELD_VARIANCE=0.5..1.5 src=game/mineral_catalog.gd
[S12K1] CONST FRAGMENT_SPLIT={ 0: (0, 0), 1: (2, 5), 2: (2, 5) } PICKUP_BURST=(1, 2) src=game/asteroid.gd
[S12K1] CONST ore_id(iron)=mineral_iron src=MineralCatalog.ore_id
[S12K1] CONST pickup_group=pickup item_prop=item_id amount_prop=amount src=FieldScript.PICKUP_GROUP+Pickup
[S12K1] CONST vanguard_cargo=40 max_cargo_over_HULLS=120 (ship_freighter) src=ShipFit.HULLS
[S12K1] CONST hull_max_weapons=7 (ship_destroyer) WeaponsScript.GROUPS_MAX=7 agree=true
[S12K1] CONST interval_of rocket=1.200 mine=0.000 (printed, never modelled)
[S12K1] LEG LASER barrels=1 delivered=171 seconds=205.200 units_per_s=0.833333 units_per_rock=6.576923 depletion_work_per_s=0.833333 rocks_spawned=26 steps=171 pickups=25 bound=none
[S12K1] ok   leg_LASER_complete - LASER emptied the field in 171 steps / 205.200 s (bound none)
[S12K1] LEG GUN3 barrels=3 delivered=25 seconds=14.800 units_per_s=1.689189 units_per_rock=0.961538 depletion_work_per_s=13.500000 rocks_spawned=26 steps=74 pickups=25 bound=none
[S12K1] ok   leg_GUN3_complete - GUN3 emptied the field in 74 steps / 14.800 s (bound none)
[S12K1] LEG GUNMAX barrels=7 delivered=25 seconds=6.343 units_per_s=3.941441 units_per_rock=0.961538 depletion_work_per_s=31.500000 rocks_spawned=26 steps=74 pickups=25 bound=none
[S12K1] ok   leg_GUNMAX_complete - GUNMAX emptied the field in 74 steps / 6.343 s (bound none)
[S12K1] SEED fingerprint=7/MEDIUM/1/iron;7/MEDIUM/1/chromium;4/LARGE/1/iron;8/MEDIUM/1/silicon;7/SMALL/1/chromium;9/MEDIUM/1/silicon
[S12K1] ok   leg_same_seeded_field - all 3 legs start from the identical seeded field
[S12K1] RATIO GUN3_vs_LASER rate=0.493x per_rock=6.840x (mining 0.833333 u/s / 6.576923 u per rock vs gunning 1.689189 u/s / 0.961538 u per rock)
[S12K1] RATIO GUNMAX_vs_LASER rate=0.211x per_rock=6.840x (mining 0.833333 u/s / 6.576923 u per rock vs gunning 3.941441 u/s / 0.961538 u per rock)
[S12K1] HOLD fill_seconds LASER vanguard=40 -> 48.000 max_cargo=120 (ship_freighter) -> 144.000
[S12K1] HOLD fill_seconds GUN3 vanguard=40 -> 23.680 max_cargo=120 (ship_freighter) -> 71.040
[S12K1] HOLD fill_seconds GUNMAX vanguard=40 -> 10.149 max_cargo=120 (ship_freighter) -> 30.446
[S12K1] ROCK seed=12061 index=1 mineral=iron tier=1 size=MEDIUM yield_in=7
[S12K1] ROCK LEG LASER_OWN units=7 seconds=8.400 shots=7 field_rocks_spawned=9 pickups=0 units_over_yield_in=1.000x
[S12K1] ROCK LEG LASER_FAMILY units=28 seconds=33.600 shots=28 field_rocks_spawned=9 pickups=5 units_over_yield_in=4.000x
[S12K1] ROCK LEG GUN3_FAMILY units=5 seconds=2.400 shots=12 field_rocks_spawned=9 pickups=5 units_over_yield_in=0.714x
[S12K1] ROCK LEG GUNMAX_FAMILY units=5 seconds=1.029 shots=12 field_rocks_spawned=9 pickups=5 units_over_yield_in=0.714x
[S12K1] ok   rock_laser_realises_own_yield - the laser realises the rock's own 7 units in 8.400 s
[S12K1] done failures=0
```
Run 2 is byte-identical; both runs, banner included, hash the same (`diff` exit 0,
scratch stores `/tmp/s12_k1_run1` and `/tmp/s12_k1_run2`):
```
acec9e7cbd03a0d61361eb72f3493272  run1.out
acec9e7cbd03a0d61361eb72f3493272  run2.out
```
Gate (own scratch store `/tmp/s12_k1_gate`), `[SUMMARY]` line only:
```
XDG_DATA_HOME=/tmp/s12_k1_gate $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=812 failed=0
```
Cross-check: the T1 LASER 171 / GUN 25 / 26 rocks / 6.343 s rows match S12-K0's budget probe exactly.

## Deviations from S12_BRIEF.md §4
- **§4's `shot_damage(&"w_cannon")` / `interval_of(&"w_cannon")` read 0.0.**
  `weapons.gd:2325-2329` keys `FAMILIES` by *family* id, so the module id returns
  `{}`. The probe resolves it through the owner's own `WeaponsScript.weapon_id()`
  (`weapons.gd:2437-2442`) and prints both readings; §3's 27 / 0.6 intent is
  reached. §4's spelling is the planner's open item (bucket 2).
- **Determinism needs a global seed.** The originals' look — hence the cleaving
  size class — rolls on the **global** RNG (`asteroid.gd:371-375`, cf. its note at
  `:207-211`), not the field's seeded one. The probe calls `seed(FIELD_SEED)`
  before each `setup`; without it the legs start from different rocks.
- **Gate reads 812/0, not the brief's 807/0.** `headless_runner.gd:14` globs
  `test_*` only, so this probe is not a gate row. The +5 rows are
  `test_d11_station.gd`, an untracked D11 suite (diffed against the S11 closure
  log); pre-existing, outside this worker's files.

## Files touched
- `vajb-orbit/tests/probe_s12_rock_rate.gd` — new standalone `--script` probe
- `.agents/gen/slices/S12-ore-budget/S12-K1_report.md` — this report

## Follow-ups
None raised: the §4 module-id spelling, the global-seed requirement and the 812 baseline are report rows for S12-R1 and the planner, not tickets.
