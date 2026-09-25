---
slice: S12
worker: S12-K0
model: "deepseek-flash"
status: informational
gate: "812/0 -> 812/0"
---

# S12-K0 report

## Result
`vajb-orbit/tests/probe_s12_field_budget.gd` measures six legs (LASER/GUN3/GUNMAX
× T1/T3) on the §4 pinned field: two runs byte-identical (md5 below), `done
failures=0`, exit 0, empty stderr. No production file, profile or live `user://`
was touched; the gate still reads `passed=812 failed=0`.

## How to run
```
XDG_DATA_HOME=/tmp/s12_k0_run1 $GODOT_CONSOLE --headless --path vajb-orbit \
  --quit-after 1200 --script res://tests/probe_s12_field_budget.gd
```

## Budget table

| tier | leg | barrels | Σ spawn yield | Σ delivered | out/in | rocks spawned | steps | seconds | shots/s |
|---|---|---|---|---|---|---|---|---|---|
| T1 | LASER | 1 | 42 | 171 | 4.071429 | 26 | 171 | 205.200000 | 0 |
| T1 | GUN3 | 3 | 42 | 25 | 0.595238 | 26 | 74 | 14.800000 | 5.000000 |
| T1 | GUNMAX | 7 | 42 | 25 | 0.595238 | 26 | 74 | 6.342857 | 11.666667 |
| T3 | LASER | 1 | 30 | 115 | 3.833333 | 26 | 115 | 138.000000 | 0 |
| T3 | GUN3 | 3 | 30 | 25 | 0.833333 | 26 | 55 | 11.000000 | 5.000000 |
| T3 | GUNMAX | 7 | 30 | 25 | 0.833333 | 26 | 55 | 4.714286 | 11.666667 |

Read: the laser realises ~4x the field's own spawn budget (fragments re-roll a
fresh yield, pre-amendment); a gun rack realises at most its own spawn budget and
**the same 25 units at 3 and 7 barrels** — rack size buys time, not ore.

## Evidence
Run 1 stdout (42 lines; run 2 is byte-identical) — the printed rows only:
```
[S12K0] const GUN_CHIP_RATE=0.100000 (WeaponsScript.GUN_CHIP_RATE)
[S12K0] const w_cannon module_id=w_cannon family_id=cannon shot_damage=27.000000 interval_of=0.600000 burst_on=0.350000 burst_off=0.250000
[S12K0] const id_gap raw_shot_damage(w_cannon)=0.000000 raw_interval_of(w_cannon)=0.000000 (module ids are not FAMILIES keys; weapons.gd:2437 weapon_id normalizes)
[S12K0] const WORK_PER_UNIT=1.000000 (AsteroidScript.WORK_PER_UNIT)
[S12K0] const MINE_CYCLE=1.200000 (MiningLaserScript.MINE_CYCLE)
[S12K0] const TIER_BASE_YIELD={ 1: 6, 2: 5, 3: 4, 4: 3 } YIELD_VARIANCE_MIN=0.500000 YIELD_VARIANCE_MAX=1.500000
[S12K0] const FRAGMENT_SPLIT={ 0: (0, 0), 1: (2, 5), 2: (2, 5) } PICKUP_BURST=(1, 2)
[S12K0] const ore_id(iron)=mineral_iron (MineralCatalogScript.ore_id)
[S12K0] const pickup_group=pickup pickup_item_field=item_id pickup_amount_field=amount
[S12K0] const hold ship_vanguard cargo=40 max_cargo=120 (ship_freighter)
[S12K0] const w_cells max=7 (ship_destroyer) GROUPS_MAX=7 agree=true
[S12K0] const untouched rocket interval_of(raw w_rocket)=0.000000 interval_of(rocket)=1.200000 mine interval_of(raw w_mine)=0.000000 interval_of(mine)=0.000000
[S12K0] field T1 seed=12061 rocks=6 tier_weights={ 1: 100 }
[S12K0] field T3 seed=12061 rocks=6 tier_weights={ 3: 100 }
[S12K0] LEG tier=T1 leg=LASER barrels=1 spawn_yield=42 delivered=171 out_in=4.071429 rocks_spawned=26 rocks_seen=26 steps=171 seconds=205.200000 shots_per_second=0.000000
[S12K0] ok   T1_LASER_spawn_nonzero - spawn_yield=42
[S12K0] ok   T1_LASER_spawned_count - children_seen=26 field._spawned=26
[S12K0] ok   T1_LASER_one_unit_per_cycle - delivered=171 steps=171
[S12K0] LEG tier=T1 leg=GUN3 barrels=3 spawn_yield=42 delivered=25 out_in=0.595238 rocks_spawned=26 rocks_seen=26 steps=74 seconds=14.800000 shots_per_second=5.000000
[S12K0] LEG tier=T1 leg=GUNMAX barrels=7 spawn_yield=42 delivered=25 out_in=0.595238 rocks_spawned=26 rocks_seen=26 steps=74 seconds=6.342857 shots_per_second=11.666667
[S12K0] LEG tier=T3 leg=LASER barrels=1 spawn_yield=30 delivered=115 out_in=3.833333 rocks_spawned=26 rocks_seen=26 steps=115 seconds=138.000000 shots_per_second=0.000000
[S12K0] LEG tier=T3 leg=GUN3 barrels=3 spawn_yield=30 delivered=25 out_in=0.833333 rocks_spawned=26 rocks_seen=26 steps=55 seconds=11.000000 shots_per_second=5.000000
[S12K0] LEG tier=T3 leg=GUNMAX barrels=7 spawn_yield=30 delivered=25 out_in=0.833333 rocks_spawned=26 rocks_seen=26 steps=55 seconds=4.714286 shots_per_second=11.666667
[S12K0] done failures=0
```
Byte-identity (run 1 vs run 2, `diff` exit 0), scratch stores `/tmp/s12_k0_run1`
and `/tmp/s12_k0_run2`:
```
d3d7c436059ce0b0f8300a4c008be208  run1.out
d3d7c436059ce0b0f8300a4c008be208  run2.out
```
Gate (own scratch store `/tmp/s12_k0_gate`), pre and post unchanged:
```
XDG_DATA_HOME=/tmp/s12_k0_gate $GODOT_CONSOLE --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=812 failed=0
```

## Deviations from SLICE.md / S12_BRIEF.md §4
- **§4's `shot_damage(&"w_cannon")` / `interval_of(&"w_cannon")` read 0.0.**
  `weapons.gd:2325-2329`'s `row_of` keys `FAMILIES` by *family* id; the module id
  is not a key, so the raw call returns `{}` (printed as the `id_gap` row). The
  brief's §3 intent (27 / 0.6) is reached through the owner's own normalizer,
  `WeaponsScript.weapon_id(&"w_cannon")` → `&"cannon"` (`weapons.gd:2437`); the
  probe reads through it and prints both readings. §4's table spelling is the
  open item for the planner (bucket 2).
- **Determinism needs a global seed.** The originals' look — hence the cleaving
  size class — rolls on the **global** RNG (`asteroid.gd:342-375`), not the
  field's seeded one. The probe calls `seed(FIELD_SEED)` before each `setup`, the
  caller duty `asteroid.gd:207-211` documents; without it the legs start from
  different rocks and two runs differ. Reversal is deleting that one call.
- **Gate reads 812/0, not the brief's 807/0.** `headless_runner.gd:14` globs
  `test_*` only, so `probe_s12_field_budget.gd` is not a gate row; the +5 is
  pre-existing in the working tree, outside this worker's two files. Reported,
  not fixed.

## Files touched
- `vajb-orbit/tests/probe_s12_field_budget.gd` — new standalone `--script` probe
- `.agents/gen/slices/S12-ore-budget/S12-K0_report.md` — this report

## Follow-ups
None raised. The §4 module-id spelling and the 812 baseline are report rows for
S12-R1/planner, not tickets.
