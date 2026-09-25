---
slice: S13
worker: S13-B1
model: "deepseek-flash"
status: informational
gate: "812/0 → 826/0"
---

# S13-B1 report

## Result
`game/ore_tuning.gd` ships as the one live balance surface (defaults = the owner
files' consts, asserted). The setup split, the mining/gun shatter attribution, the
reserve rules and N-module mining batteries are in, `DOCK_RING_RADIUS` is 175.0.
Gate **812/0 → 826/0**, twice on fresh scratch stores; the +14 are the two new
suites' rows, no moved row added a row. Both S12 probes and the A2/A1 cleave
probes report `failures=0`.

## Pre-grep of SLICE.md §3 (read before editing each)
| Row | Before edit | Action |
|---|---|---|
| `test_engine2_cleaving.gd:365-367` | `fragment.yield_units >= 1` ("re-rolled (02 5)") | moved → Σ children `_bore_ore` == parent reserve ±0.5, no roll |
| `test_engine2_cleaving.gd:620-621` | per-crack pickups 1-2 | still green **unchanged** (a 1.333 reserve pays 1,1,2,2,2,2) |
| `probe_rock_cleave_a2.gd:244-249` | `PICKUP_BURST (1,2)` + `EJECT_MULT 1.2` | still green **unchanged** (consts untouched) |
| `probe_rock_cleave_a2.gd:670-671` | `lo/hi` = tier band × variance | removed (no re-roll exists) |
| `probe_rock_cleave_a2.gd:696-699` | `inherit_yield_rerolled` in band 3-9 | moved → `inherit_reserve_split_no_reroll`, 30/30 cleaves conserved |
| `probe_s12_field_budget.gd:176-199` | `spawn_yield` = Σ `yield_units`; `delivered == steps`; gun via `apply_work` | moved → `spawn_bore` = Σ `_bore_ore`; `extracted <= steps`; budget-conserved + gun-capped checks |
| `probe_s12_rock_rate.gd` cascade rows | `root_yield`; `units_over_yield_in`; check `own delivered == yield_in` | moved → `root_bore`; `units_over_bore`; family-conserved + gun-capped checks |
| `test_d11_station.gd` radius row | radius 120.0, contains 119 / not 121 | moved → 175.0, contains 174 / not 176 |
| New `tests/test_s13_caps.gd` | — | added (10 rows) |
| New `tests/test_s13_mining_batteries.gd` | — | added (4 rows) |
| Not moved: `engine2_cleaving.gd:302,332-338`, `test_combat_repair_c5.gd`, `test_s2_6_burst.gd`, `test_p1_catalogues.gd`, `test_s6_poi_loot.gd` | green | untouched |

## Per-AC measurements
- **AC1 (gun cap).** S12K0 `spawn_bore` rows: T1 GUN3/GUNMAX delivered **4 of 42 =
  0.0952**; T3 GUN3/GUNMAX **3 of 30 = 0.1000** (were 0.595 / 0.833). S12K1
  single-rock: GUN3/GUNMAX_FAMILY **0 units / bore 7.0 = 0.000×** (was 0.714×).
  The gun shatter pays at most `gun_burst_share × _bore_ore`; a per-rock cap of
  0.7 floors to 0 whole pickups.
- **AC2 (budget conserved).** S12K1 LASER_FAMILY **7 units / bore 7.0 = 1.000×**
  (S12 measured **4.000×**); LASER_OWN 5 = its extractable. S12K0 LASER out/in
  **T1 0.976, T3 1.000** (were 4.071 / 3.833). `_cleave` calls no `_rolled_yield`
  (only `setup`-side rolls remain); children's Σ `_bore_ore` == the parent reserve.
- **AC3 (N batteries).** `test_n_modules_deliver_n_times_the_units_per_cycle`
  measured **1.000 / 2.000 / 3.000 units per cycle** for N = 1/2/3 (0 % off N×;
  tolerance 20 %), i.e. **0.833 / 1.667 / 2.500 u/s** at `mine_cycle` 1.2. The rock
  loses exactly the delivered units, never the reserve.
- **AC5 (ring).** `sector.gd:73` = `175.0`; `:188`, `:234`, `:554` read the one const;
  `test_d11_station`'s rows updated.
- **AC6 (anti-drift).** `test_ore_tuning_defaults_are_the_owner_files_consts` asserts
  each of the 9 defaults equals its const; `reset_to_defaults` / `to_dict` /
  `from_dict` round-trip.
- **AC7.** Gate `[SUMMARY] passed=826 failed=0` twice, stores
  `/tmp/s13_b1_gate_final1` and `/tmp/s13_b1_gate_final2`; baseline `812/0`
  (`/tmp/s13_b1_gate_before`).

## Deviations from S13_BRIEF.md §2
1. **`setup`'s third argument is the extractable half, and `_bore_ore` is derived**
   (`units / (1 − share)`) unless the caller passes the new optional `bore`. Reason:
   `test_combat_repair_c5.gd` (frozen) and `engine2_cleaving.gd:295-319` require
   `setup(…, N)` to leave `yield_units == N`, and the docs equate `yield_units` with
   the extractable. The field and `_cleave` pass the exact roll as `bore`. Reversal:
   make `setup` take the roll and floor the extractable (c5 then moves — bucket 2).
2. **The reserve handoff is a carrier handoff.** A mining M/L shatter gives the
   children the reserve as their own whole-unit yield (`_bore_ore == yield_units`,
   reserve 0), so Σ children yield == the reserve and the family realises exactly the
   root `_bore_ore` (1.000×). The alternative (each child carves its own 25 %) loses
   sub-unit ore to integer rounding on a T1 reserve (1.67 split 2-5 ways has no whole
   extractable) and under-realises to ~0.75×; AC2 asks ~1.0×. Reversal: each child
   takes a float share/carve as in the doc's float model.
3. **A gun-attributed M/L shatter still leaves physical fragments, but they carry no
   ore** (`_bore_ore` 0) — the excess reserve burns (02 §5.1), and this is what stops
   the gun compounding a payout through the cascade; a mining shatter is the only one
   that hands ore down.
4. **`OreTuning.pickup_burst` is carried but not read by the payout**: rule 3's float
   credit supersedes "a Small bursts a rolled 1-2" (the payout is `floor(credit)`
   whole units). It stays a field (overlay slider + AC6), and `_pay_burst` says so.
5. **`test_d11_station.gd:90-92` moved with the radius row 81** (119→174, 121→176):
   both old points sit inside a 175 ring, so the same test's geometry had to follow
   the one constant.
6. **`poi.gd`'s ore bloom keeps passing `roll × 2` as the extractable** (a five-arg
   `setup` call): `test_s6_poi_loot.gd:431-433` (frozen) asserts `yield_units % 2 == 0`,
   so the bloom doubles the extractable, not the derived bore. No poi.gd edit.
7. **`test_weapon_fx_f4.gd:178`'s `SCRIPT ERROR … previously freed instance` is
   pre-existing.** Verified by stashing this worker's `game/`+`tests/` and re-running:
   the baseline prints the identical error at the identical line. Not introduced here.

## Evidence
```
gate before /tmp/s13_b1_gate_before:  [SUMMARY] passed=812 failed=0
gate after  /tmp/s13_b1_gate_final{1,2}: [SUMMARY] passed=826 failed=0  (twice)
probe_s12_field_budget.gd /tmp/s13_b1_p2:
  [S12K0] LEG tier=T1 leg=LASER spawn_bore=42 delivered=41 out_in=0.976190 …
  [S12K0] LEG tier=T1 leg=GUN3  spawn_bore=42 delivered=4  out_in=0.095238 …
  [S12K0] LEG tier=T3 leg=LASER spawn_bore=30 delivered=30 out_in=1.000000 …
  done failures=0
probe_s12_rock_rate.gd /tmp/s13_b1_p3:
  [S12K1] ROCK LEG LASER_FAMILY units=7 … units_over_bore=1.000x
  [S12K1] ROCK LEG GUN3_FAMILY  units=0 … units_over_bore=0.000x
  done failures=0
probe_rock_cleave_a2.tscn /tmp/s13_b1_a2c: INHERIT 30/30 conserved; done failures=0
gate rows: test_s13_caps.gd ×10 PASS, test_s13_mining_batteries.gd ×4 PASS
```

## Files touched
- new `game/ore_tuning.gd`; new `tests/test_s13_caps.gd`, `tests/test_s13_mining_batteries.gd` (+ `.uid` sidecars, untracked)
- `game/asteroid.gd` (split/attribution), `game/asteroid_field.gd` (reserve handoff, credit payout, no re-roll)
- `game/mining_laser.gd` (N channels), `game/player_ship.gd` (module count), `game/sector.gd` (175.0)
- `game/weapons.gd`, `game/projectile.gd` (gun door), `game/mineral_catalog.gd` (live `roll_yield`)
- moved rows: `test_engine2_cleaving.gd`, `test_d11_station.gd`, `probe_s12_field_budget.gd`, `probe_s12_rock_rate.gd`, `probe_rock_cleave_a2.gd`

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `pickup_burst` is a live slider with no live reader under the credit rule | LOW | `game/ore_tuning.gd`, `game/asteroid_field.gd:_pay_burst` |
| The carrier handoff vs the doc's "each child carves 25 %" is a reading worth a ruling | LOW | this report §Deviations 2 |
