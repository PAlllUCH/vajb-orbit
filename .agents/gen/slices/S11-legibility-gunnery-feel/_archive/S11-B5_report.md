---
worker: S11-B5
slice: S11
role: coder (continuation — the wave's tests and probes)
tree: f5f1fcf (the wave's builders) + this worker's five files; the live tree also carried B2/B6's uncommitted continuation edits at report time
gate: "791/0 twice on the wave tree with only this worker's files (f5f1fcf + tests); the live tree reads 806/1 twice, its one failure B2's module_catalog row"
live_store: "never written — every run under a fresh XDG_DATA_HOME=$(mktemp -d)"
---

# S11-B5 — the rows the ticked constants reach

## Result

| # | row | where |
|---|---|---|
| 1 | the four beam/kinetic `range` rows assert `WeaponScript.NEAR_INFINITE_RANGE` plus one pin of the const to `30000.0`; `rocket` 900.0 unmoved | `tests/test_engine2_weapons.gd:140-147` |
| 2 | `coast_time` fixture follows `ShipFit.COAST_TIME_MULT` | `tests/test_s7_affixes.gd:71` |
| 3 | the two ring rows follow `ShipFit.COAST_TIME_MULT` instead of a second literal | `tests/test_s7_affixes.gd:365`, `:375` |
| 4 | `S2.6` probe: `LATERAL_DAMP_MULT` key list → `ANGULAR_DAMP_MULT`, split prose retired | `tests/probe_s2_6_flight.gd:3-5`, `:45`, `:295`, `:299-303` |
| 5 | `G1` probe: release-translation prose corrected to §23.5's one-vector chase | `tests/probe_g1_flight_feel.gd:290-297` |
| 6 | `C3` probe: **untouched** — failure pre-dates the wave (verdict below) | `tests/probe_c3_flight_decay.gd` |

## Gate lines (fresh scratch store each)

| run | tree | line |
|---|---|---|
| 1 | f5f1fcf + this worker's five files (`/tmp/s11_head`) | `[SUMMARY] passed=791 failed=0` (exit 0) |
| 2 | same, second scratch store | `[SUMMARY] passed=791 failed=0` (exit 0) |
| 3 | same, final files (comment fix) | `[SUMMARY] passed=791 failed=0` (exit 0) |
| 4 | the live tree at report time (B2/B6 uncommitted continuation edits present) | `[SUMMARY] passed=806 failed=1` |
| 5 | same, second scratch store | `[SUMMARY] passed=806 failed=1` |

Runs 4/5 are byte-identical on the fail list; the one failure is
`test_ship_grids.gd.test_module_catalog_carries_the_pinned_rows: w_laser carries exactly
name/slot/draw/tier/cost/icon/effects` — the `description` key the §23.2 worker adds, a file
outside this worker's set and outside the rows §23.6 names for B5. 791 = 775 (S10) + B1's 13
+ B4's 3; B5 adds no row, so the 788/3 B4 measured becomes 791/0 once its three rows move.
The live tree's 806 is that 791 plus B2/B6's 15 concurrent rows.

Scoped proof (single run, scratch store): `--suite=test_engine2_weapons --suite=test_s7_affixes`
→ `[SUMMARY] passed=63 failed=0` (exit 0).

## Rows moved (before → after)

| file:line | before | after |
|---|---|---|
| `test_engine2_weapons.gd:141-144` | `range_of(laser/plasma/cannon/railgun)` = `500.0 / 450.0 / 600.0 / 800.0` | `WeaponScript.NEAR_INFINITE_RANGE` (one shared literal) |
| `test_engine2_weapons.gd:141` | — | new pin `NEAR_INFINITE_RANGE == 30000.0` |
| `test_engine2_weapons.gd:145` | `rocket` = `900.0` | unchanged |
| `test_s7_affixes.gd:71` | `"coast_time": 2.1` | `ShipFit.COAST_TIME_MULT * 1.05` (resolves 2.625) |
| `test_s7_affixes.gd:365` | `1.0 * 2.0` | `1.0 * ShipFit.COAST_TIME_MULT` |
| `test_s7_affixes.gd:375` | `1.0 * 2.0 * 1.01` | `1.0 * ShipFit.COAST_TIME_MULT * 1.01` |
| `test_s7_affixes.gd:67-68` | prose "coast x2.0" | prose "coast x COAST_TIME_MULT, 2.5 since 23.5's T1" |

No bound was weakened: the four range rows moved *up* to the pin, the three coast rows read
the pin itself, and every other assertion in both suites is byte-identical (`accel_time` still
`2.4 * 2.0`, rocket still literal `900.0`).

## Probes

`probe_s2_6_flight.gd` (re-run after the edit, bounded, fresh scratch): `[S26F] done
failures=0`; constants row was `... LATERAL_DAMP_MULT=1.0 ...`, now `... COAST_TIME_MULT=2.5,
ANGULAR_DAMP_MULT=0.5 ...`. The section-2 decay rows already print the new truth (vanguard
axial `t_10 1.150` = lateral `1.150`, `damp_forward == damp_lateral`); the edit corrects the
key list and the prose that still called the lateral axis a separate drag.

`probe_g1_flight_feel.gd` (re-run): `[G1] done failures=0`, `turn_curve mismatched=0`.
Measured before/after against the 4c19812 worktree: `release_omega` **unmoved**
(vanguard 0.413, freighter 0.750), so T2 does not move this probe's rows; the rows that moved
are the release leg's `displacement` (vanguard 46.9901 → 36.7425, freighter 40.0604 →
13.2517) and `speed_at_reach` (8.9169 → 0.0000, 2.4042 → 0.0000), owned by §23.5's release
chase. The edit says that instead of "the turn's own coast".

`probe_c3_flight_decay.gd`: byte-untouched (`git status` clean on it).

## Probe-ownership verdict — `probe_c3_flight_decay` is **not this wave's**

Recipe: `git worktree add --detach /tmp/s11_base 4c19812`, a `.godot/global_script_class_cache.cfg`
copy plus read-only `assets`/`imported`/`shader_cache` binds so the worktree's environment
matches the live one, then the probe under `XDG_DATA_HOME=$(mktemp -d) --fixed-fps 60
--quit-after 30000`. A second worktree at `f5f1fcf` was run the same way as the environment
control.

| run | tree | line |
|---|---|---|
| live HEAD | f5f1fcf | `[C3] done cases=4 failures=4` (top speed 83.312 / 346.793) |
| worktree | f5f1fcf (env control) | `[C3] done cases=4 failures=4` (83.312 / 346.793 — byte-matches live) |
| worktree | **4c19812 (pre-dispatch)** | `[C3] done cases=4 failures=4` (147.236 / 73.081) |

All four cases on every tree die in the *accelerate* leg (`never reached <cruise> u/s; not
measured`, `MAX_ACCEL_SECONDS` = 30.0 at `probe_c3_flight_decay.gd:56`); no wave file
(`weapons.gd`, `ship_fit.gd`, `player_ship.gd`) is on that leg's path. The failure is present
at the baseline, so the file stays untouched and is reported, not fixed.

**Observation for R1 (bucket 2, not a fix):** the accelerate leg's measured top speed differs
between the two trees (vanguard 147.236 → 83.312, fighter 73.081 → 346.793) while the failure
mode is identical and the probe never reaches cruise on either. §23.6's tests-that-move list
does not explain that delta; it is flagged, not absorbed. `probe_c3_flight_decay.gd` does not
pin either number (it only prints them), so nothing here needed a re-derivation.

## Hygiene

Every Godot run was bounded (`--quit-after`) under a fresh `XDG_DATA_HOME=$(mktemp -d)`, stdout
to a log; no background command survived; no `git add`; `docs/**`, `game/**`, the briefs and
the other workers' files were not written. Files touched: `tests/test_engine2_weapons.gd`,
`tests/test_s7_affixes.gd`, `tests/probe_s2_6_flight.gd`, `tests/probe_g1_flight_feel.gd` and
this report. The live store was never opened by any run. The two scratch worktrees are
removed at close (`git worktree prune`).

## Reversals

- `test_engine2_weapons.gd:141-147`: restore the four literals `500.0 / 450.0 / 600.0 / 800.0`,
  drop the const pin.
- `test_s7_affixes.gd:71,365,375`: `ShipFit.COAST_TIME_MULT` back to the literal `2.0` (the
  fixture to `2.1`); their comments back to "coast x2.0".
- both probes: comment-only edits; no reversal needed for behaviour.
- nothing to reverse in `probe_c3_flight_decay.gd` (untouched).
