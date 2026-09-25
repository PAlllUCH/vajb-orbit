---
slice: S12
reviewer: S12-R1
verdict: passed-with-followups
gate: "807/0 at baseline commit 1d6b739; 812/0 on the s12_start working tree"
---

# S12-R1 review — the two ore-budget probes

Reviewed by re-measurement, never by the reports: both probes replay
byte-identically on a detached worktree at the baseline commit, every constant
§4 names was re-read from its owner file by grep, the mirror sites were diffed
against production line by line, and the AC4 grep was re-run. **No
`probe_s12_r1_constants.gd` was created** — the owner files were read directly,
so no second runtime reading was needed.

## Replay (W8 method)
Detached worktree `/tmp/s12_r1_base` at `1d6b739` (the HEAD when `s12_start`
was snapshotted), both probes copied in, `assets`/`.godot` symlinked from the
live tree, a separate scratch `XDG_DATA_HOME` per run:

| probe | runs | md5 (both runs) | the report's md5 | pasted lines matched |
|---|---|---|---|---|
| `probe_s12_field_budget.gd` | 2 | `d3d7c436059ce0b0f8300a4c008be208` | identical | 24/24 verbatim |
| `probe_s12_rock_rate.gd` | 2 | `acec9e7cbd03a0d61361eb72f3493272` | identical | 34/34 verbatim |

Run-pair `diff`: exit 0, empty stderr, `done failures=0`, exit 0. Every line the
reports paste appears verbatim in the replay. **Zero byte differences — no HIGH
from step 1.**

## Constants re-read from the owner (step 2)
| §4 need | owner read (grepped) | probe printed | agree |
|---|---|---|---|
| chip rate | `weapons.gd:216` 0.10 | 0.100000 / 0.10 | ✓ |
| bolt damage | `weapons.gd:124,127-128` dps 45 × (0.35+0.25) | 27.0 | ✓ |
| cadence + burst | `weapons.gd:2395-2407` | 0.600, burst 0.35/0.25 | ✓ |
| work per unit | `asteroid.gd:56` 1.0 | 1.000000 / 1.0 | ✓ |
| mine cycle | `mining_laser.gd:34` 1.2 | 1.200000 / 1.200 | ✓ |
| tier base yield | `mineral_catalog.gd:281-286` 6/5/4/3 | `{1:6,2:5,3:4,4:3}` | ✓ |
| yield variance | `mineral_catalog.gd:288-289` 0.5 / 1.5 | 0.500 / 1.500 | ✓ |
| fragment split | `asteroid.gd:107-111` (0,0)(2,5)(2,5) | same | ✓ |
| pickup burst | `asteroid.gd:112` (1,2) | (1,2) | ✓ |
| ore id | `mineral_catalog.gd:18,308-311` prefix `mineral_` | `mineral_iron` | ✓ |
| group / pickup fields | `asteroid_field.gd:106`; `pickup.gd:53,54,69` | pickup / item_id / amount | ✓ |
| a hold | `ship_fit.gd:310-319` vanguard cargo 40 | 40 | ✓ |
| max cargo | `ship_fit.gd:346-355` freighter 120 | 120 | ✓ |
| W cells | `ship_fit.gd:373-382` destroyer 7 | 7; `GROUPS_MAX` 7 `agree=true` | ✓ |
| rocket / mine | `weapons.gd:149` 1.2; `w_mine` edge | 1.200 / 0.000 | ✓ |

## The mirror (step 3)
- `mining_laser.gd:195-202` ↔ K0:164-166, K1:172-173,296-299: the same
  `apply_work(WORK_PER_UNIT)` call, the same owner constant, one delivery per
  returned unit, `elapsed += MINE_CYCLE`. No drift.
- `projectile.gd:769-773` ↔ K0:168-169, K1:174-175,284-285: production applies
  `damage * chip * damage_mult` = `shot_damage × GUN_CHIP_RATE × 1.0` for a
  stock cannon (`weapons.gd:1219,1232,1237`); the probes apply the same product
  and discard the return. No drift.
- `asteroid_field.gd:400-420` ↔ K0:172-173,203-209, K1:182-183,311-316: the
  Small-end burst spawns `PICKUP_BURST` (1-2) pickups of `amount` 1 in group
  `pickup`; the probes sum exactly those children. No drift.
- Cadence checked beyond the brief: `weapons.gd:872-915,1067-1071` gates a
  cannon barrel to one release per `interval_of` (0.6 = its own burst cycle), so
  `barrels / interval_of` is the shipped rate, not an assumption.

## AC4 grep (step 4)
Zero hits for `user://`, `FileAccess`, `DirAccess`, `ResourceSaver` or `open()`
in either probe. Numeric hits, none forbidden:
- `FIELD_ROCKS := 6` (K0:41, K1:44) — §4's pinned literal, duplicating
  `FIELD_ROCKS_MIN` (`asteroid_field.gd:67`) with no assertion → F2/L191.
- `GUN3_BARRELS := 3` (K1:56) and `_run_leg(…, "GUN3", 3, …)` (K0:130) — the
  pinned leg's barrel count, not an owner number.
- `FIELD_SEED := 12061` and `{3: 100}` (K0:48) — the pinned field config.
No `0.10`, `1.2`, `45`, `0.6`, `40`, `27` or a 6/5/4/3 table is re-declared.

## The arithmetic (step 5)
| doc claim | recomputed from the probes' own numbers | verdict |
|---|---|---|
| 3 cannons ≈ 13.5 u/s depletion (`01 §5.6:193`) | 3/0.6 = 5 shots/s; 27×0.10 = 2.7 chip; 5×2.7 = **13.500** (K1 `depletion_work_per_s=13.500000`) | HOLDS exactly |
| laser 0.83 u/s (`01 §5.6:194`) | `1/MINE_CYCLE` = 1/1.2 = **0.833333** (K1 `units_per_s=0.833333`) | HOLDS exactly |
| T1 Large ≈16.75 rocks, ≈100 units from its own 6 (`01 §5.6:178-179,188-189`) | printed split mean 3.5, base 6 → 1+3.5+12.25 = **16.75 rocks**; 6×16.75 = **100.5 units** | HOLDS by derivation; no probe isolates a Large (F4/L194) |
| shooting "≈2.5 u/s delivered" (`01 §5.6:197`) | GUN3 **1.689** u/s, GUNMAX **3.941** u/s; holds 23.680 s / 10.149 s | number FAILS (no leg reads ≈2.5); direction holds → F5/L195 |

The proposed invariant is not met by the shipped tree, as expected: per rock
mining:gunning = **6.840×** (< the proposed 10× floor) and the gun realises
**0.714×** a rock's own yield. The docs present both as proposals, so this is
the measurement the ticks need, not a docs error.

## The number tables (the wave deliverable)
T1, seed 12061, 6 rocks → 26 rocks spawned (1 L / 4 M / 1 S):

| leg | barrels | Σ spawn yield | Σ delivered | out/in | units/s | units/rock* | depletion work/s | seconds | steps |
|---|---|---|---|---|---|---|---|---|---|
| LASER | 1 | 42 | 171 | 4.071 | 0.833 | 6.577 | 0.833 | 205.200 | 171 |
| GUN3 | 3 | 42 | 25 | 0.595 | 1.689 | 0.962 | 13.500 | 14.800 | 74 |
| GUNMAX | 7 | 42 | 25 | 0.595 | 3.941 | 0.962 | 31.500 | 6.343 | 74 |

T3, seed 12061, 6 rocks: Σ spawn yield 30; LASER 115 units / 3.833 / 138.000 s;
GUN3 25 / 0.833 / 11.000 s; GUNMAX 25 / 0.833 / 4.714 s.

One rock, `rocks()[0]` = iron T1 MEDIUM, own yield 7:

| row | units | units / own yield | seconds |
|---|---|---|---|
| LASER_OWN (body alone) | 7 | 1.000 | 8.400 |
| LASER_FAMILY (whole cascade) | 28 | 4.000 | 33.600 |
| GUN3_FAMILY | 5 | 0.714 | 2.400 |
| GUNMAX_FAMILY | 5 | 0.714 | 1.029 |

Hold fill: vanguard 40 → LASER 48.000 s, GUN3 23.680 s, GUNMAX 10.149 s;
freighter 120 → 144.000 / 71.040 / 30.446 s. *units/rock divides by rocks
**spawned** (26), not the field's 6 originals — F2/L192. Reproduced from the
reviewer's own replay (`d3d7…` / `acec…`), not copied from the reports.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S12-K0/F1 | MED | brief §5/§7, AC3; `S12-K0_report.md` §Deviations | The pinned baseline gate is wrong. `s12_start.json` already carries `tests/test_d11_station.gd` (6051 B), so the snapshotted tree reads **812/0**; a detached worktree at `1d6b739` (which lacks that untracked file) reads **807/0**. Both measured, no gate row moved by the probes. Bucket 2. | docs pass |
| S12-K1/F1 | MED | brief §4 table; `S12-K1_report.md` §Deviations | §4 names `WeaponsScript.shot_damage(&"w_cannon")` / `interval_of(&"w_cannon")`, but `row_of` keys `FAMILIES` by family id (`weapons.gd:2325`), so the raw call reads 0.0. The probes route through `weapon_id` and print both readings — correct; the pin's spelling is not callable as written. Bucket 2. | docs pass |
| S12-K0/F2 | LOW | `probe_s12_field_budget.gd:41`; `probe_s12_rock_rate.gd:44` | `FIELD_ROCKS := 6` re-states `FIELD_ROCKS_MIN` (`asteroid_field.gd:67`) with no assertion they agree; §4 sanctions the literal, but the pinned "field's own minimum" drifts if the owner moves. | → L191 |
| S12-K1/F2 | LOW | `probe_s12_rock_rate.gd:197,388-392` | `units_per_rock` divides by rocks **spawned** (26, fragments included), not the field's 6 originals (28.5 u/rock); the table reads "units/rock" beside `rocks_spawned=26`. | → L192 |
| S12-K1/F3 | LOW | `probe_s12_rock_rate.gd:219-224,381-385` | `RATIO GUN3_vs_LASER rate=0.493x` is `laser/gun` (mining:gunning); a log reader takes GUN3 as the slower when GUN3 delivers **2.03×** the laser's u/s. | → L193 |
| S12-K1/F4 | LOW | `probe_s12_rock_rate.gd:243-261` | Neither probe isolates a fully worked T1 **Large**; the single-rock row works `rocks()[0]`, a MEDIUM (28/7 = 4.0×). The docs' 16.75×/≈100 headline stays derivation-only. | → L194 |
| S12-K1/F5 | LOW | `docs/gameplay/01_economy_core.md:197` | "≈2.5 units/s delivered" is not reproduced by either leg (1.689 / 3.941); the ordering claim holds, the number needs a retext at close-out. | → L195 |
| S12-K0/F3 | LOW | `SLICE.md:61` vs `S12_BRIEF.md:148` | SLICE.md names R1's artifact `probe_s12_r1_replay.gd`; the brief and the dispatch name `probe_s12_r1_constants.gd`. | → L196 |
| S12-K0/F4 | LOW | `probe_s12_field_budget.gd:175` | The probe asserts `children_seen == field._spawned` — a duck-typed read of a private field; works today, drifts silently if `asteroid_field.gd` renames it. | → L197 |

## Verified fixes
None — no fixer pass is warranted: zero HIGH, and both MEDs are bucket-2 docs
pins (§6 limits a probe fixer to probe files, so a fixer could not touch them).

## Gate / scope (step 6)
| tree | command | result |
|---|---|---|
| baseline commit `1d6b739` (detached worktree, no D11 test) | `headless_runner.tscn --quit-after 1200` | `passed=807 failed=0` |
| `s12_start` working tree / HEAD `b83ea09` | same | `passed=812 failed=0` |

`staging/verify_wave.py verify --baseline s12_start` with the brief §8
`--forbidden` list and both `--expect-reports`: **`problems: []`** — no forbidden
game file modified. `git status --short` shows S12's only additions are the two
probes + their `.uid` sidecars and the two reports; no `game/**`, `ui/**`,
`docs/**` or `addons/**` change belongs to S12. There is no "probe commit": the
probes are untracked in the working tree, so the only reproducible baseline is
the `s12_start` snapshot at `1d6b739` (gate 807/0, measured above).

## Acceptance
AC1 ✓ (K0's rows, two runs identical, `done failures=0`), AC2 ✓ (K1's rate
table, two runs identical), AC4 ✓ (grep clean, every number read from its
owner), AC5 ✓ (byte-identical replay on the detached worktree, ratio table
published above). AC3 ✓ in substance — no gate row moved and read-only — but its
literal 807 belongs to the commit tree, not the snapshotted tree (F1).
