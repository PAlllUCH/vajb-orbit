---
slice: S14
worker: S14-B1
model: deepseek-flash
status: informational
gate: "834/0 (dispatch) -> 830/4 (mine reverted) -> 839/4 (mine applied)"
---

# S14-B1 report

## Result
Four size classes ship: `SIZE_XL` 3 beside the existing three, the L child set is now a
rolled mix read from `OreTuning.split_mix` (`XL -> L 1-3, M 2-4, S 2-5`; `L -> M 1-3,
S 2-4`; `M -> S 1-3`; `S -> none`), the field spawns sizes from
`OreTuning.spawn_size_weights` (S 40 / M 32 / L 20 / XL 8), and XL draws the L
silhouettes at 180 u. S13's conservation is intact: a fully mined XL family of bore 32.0
realised 32 (42 steps, 17 rocks). `tests/test_s14_splits.gd` adds 9 rows, all green.

## Pre-grep of §3's rows (line numbers are the pre-edit revision)
| §3 row | Where | Status |
|---|---|---|
| `FRAGMENT_SPLIT` const pins | `test_engine2_cleaving.gd:338,340,342` (fn `:336-348`) | moved -> asserts `OreTuning.split_mix` (row renamed `test_the_split_table_is_the_s14_mix`) |
| child-size rows "L->M, M->S" | same file `:351-400`, `:403-418` | moved -> `test_a_large_cleaves_into_a_mixed_m_and_s_set`, `test_a_medium_cleaves_into_one_to_three_smalls` |
| `_fragment_size` rows | `asteroid_field.gd:432` (def), call `:410` | deleted (no reader) |
| s13 reserve-split-across-count | `test_s13_caps.gd:174` (`children.size() >= 2`) | moved -> `>= 1`; conservation rows `:197-213` untouched and green |
| a2 child yield band | `probe_rock_cleave_a2.gd:670-671, 696-699` | moved; the INHERIT parent is now a Large so the mixed set is what is measured |
| s12 cascade rows | `probe_s12_field_budget.gd:96-97`; `probe_s12_rock_rate.gd:111-112, 363-371` | moved (CONST prints the live table; `_size_name` gained XL) |
| new suite | `tests/test_s14_splits.gd` | added, 9 rows |
| not moved, verified green | `test_s2_6_burst.gd` (ejection rows), `test_combat_repair_c5.gd`, `test_engine2_cleaving.gd:302` (chip arithmetic), all other S13 rows | unchanged |

**Beyond §3's literal list, changed because §2's pins made the row false** (flagged for R1):
`test_engine2_cleaving.gd:424-441` (the count-bounds row: L is now 3-7, M 1-3);
`probe_rock_cleave_a2.gd:257-305` (the COUNT block: the total is a convolution, so the
chi-square is now per kind) plus its CONST print; `probe_s12_*`'s `_size_name` XL case.
Rows left **untouched** although stale: `test_engine2_cleaving.gd:287` ("inside the three
rows" - passes only because seed 7331 rolls no XL there), and the frozen A1 probe
`probe_rock_cleave.gd` (2 stale failures, below).

## Per-AC measured
| AC | Measurement |
|---|---|
| AC1 | 200 seeded XL shatters: 1708 children, mean 8.540; L 1-3 (mean 2.090), M 2-4 (2.930), S 2-5 (3.520); totals `{5x3, 6x21, 7x37, 8x39, 9x39, 10x35, 11x17, 12x9}`; no child at or above its parent; every kind's floor held in all 200 |
| AC2 | A2 probe, 300 cleaves each: M -> only S, totals 1-3; L -> only M and S, totals 3-7; 40/40 Smalls spawn no rock fragments (their cleave is the pickup burst) |
| AC3 | XL root, bore 32.0 -> family realised 32, 42 steps, 17 rocks, 0 pickups; `<= bore + 1` and `>= bore - 1` |
| AC4 | 1000 seeded rolls on the field's own RNG: S 376 (37.6 % vs 40), M 345 (34.5 vs 32), L 207 (20.7 vs 20), XL 72 (7.2 vs 8); worst deviation 2.4 pp against the 3 pp bound |
| AC5 | 3 XL looks (indices 9-11), each `LOOK_WIDTHS` 180.0 and each reusing its L texture; 24 drawn XL rocks all landed inside the row and measured 180.0 u at the drawn scale, covering all 3 looks (`seed(14161)` pins the stream) |
| anti-drift | `str(split_mix)`/`str(spawn_size_weights)` equal the pinned tables, through `reset_to_defaults` and a snapshot round-trip; keys are the four `SIZE_*` classes; every child kind is strictly below its parent |

## Gate
- dispatch baseline (before the S15 lane's edits landed): `[SUMMARY] passed=834 failed=0`.
- "before" for this slice (my files reverted, S15's in-flight tree): `passed=830 failed=4`.
- "after": three runs on fresh scratch stores, the S15 lane landing rows between them,
  gave `839/4`, `842/6` and `844/5` (they added `test_s15_battery_cap.gd` and then a
  mid-write `test_s15_armory_layout.gd`). Delta = **+9 rows = `test_s14_splits`' 9
  methods**, 0 new failures; `test_engine2_cleaving` and `test_s13_caps` keep their row
  counts (renames only), and the `[S14]` lines were byte-identical in all runs.
- Every remaining failure is S15's: `test_d7_armory.gd.test_the_w_cells_are_the_machined_slot_recesses`,
  `test_d7_cockpit.gd.test_exactly_the_selected_rack_is_lit`,
  `test_engine2_weapons.gd.test_a_six_weapon_fit_is_kept_whole`,
  `test_s10_armory_input.gd.test_a_real_named_plate_drag_commits_the_swap`,
  `test_s15_battery_cap.gd.*`, `test_s15_armory_layout.gd` (GROUPS_MAX 5->7 / armory rack
  rows). Never reverted.
- Filtered, twice on fresh scratch stores:
  `--suite=test_engine2_cleaving --suite=test_s13_caps --suite=test_s14_splits` ->
  `passed=34 failed=0` both times, byte-identical `[S14]` lines.

## Evidence (commands)
```bash
# gate; my suites, twice
XDG_DATA_HOME=<scratch> $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
... headless_runner.tscn --quit-after 600 -- --suite=test_engine2_cleaving --suite=test_s13_caps --suite=test_s14_splits
# probes (each with its own XDG_DATA_HOME)
... res://tests/probe_rock_cleave_a2.tscn --quit-after 1800          # [A2] done failures=0
... --script res://tests/probe_s12_field_budget.gd                   # [S12K0] done failures=0
... --script res://tests/probe_s12_rock_rate.gd                      # [S12K1] done failures=0
... --script res://tools/r1_s13_ac3_replay.gd                        # [S13R1] done failures=0
... res://tests/probe_rock_cleave.tscn --quit-after 1800             # [RC] done failures=2 (frozen, below)
```
Probe figures: A2 COUNT `Large total=3-7 {3x32,4x62,5x108,6x68,7x30} | kind 1 rolls 1-3
chi2=0.26 | kind 0 rolls 2-4 chi2=2.94`, `Medium total=1-3 {1x94,2x94,3x112} chi2=2.16`;
A2 INHERIT `cleaves=30 n=149 classes=[1, 0] child_bore` all 1.0 (30/30 conserved);
S12K0 LASER `out_in` 0.976744 (T1) / 1.000000 (T3), gun legs 0.093023 / 0.068966;
S12K1 LASER 42 units / GUN3 4 / GUNMAX 4 from a 43-unit T1 field.

## Files touched
- `game/asteroid.gd` — `SIZE_XL`, XL look row (3 L textures, 180 u), retired `FRAGMENT_SPLIT` documented, `_roll_look` upper bound `SIZE_XL`, docs.
- `game/ore_tuning.gd` — `split_mix` + `spawn_size_weights` (pinned defaults), `reset_to_defaults`, `to_dict`, `from_dict` + a `_span` count-range normaliser.
- `game/asteroid_field.gd` — `_roll_size` (spawn mix), `_cleave` rolls the mixed child set and splits the reserve across all of it, `_roll_children` added, `_fragment_size` deleted.
- `tests/test_s14_splits.gd` — new, 9 rows (AC1-AC5 + anti-drift + overlay round-trip).
- `tests/test_engine2_cleaving.gd` — 3 cleaving rows moved/renamed, `OreTuning` preloaded.
- `tests/test_s13_caps.gd` — the one child-count row (conservation rows untouched).
- `tests/probe_rock_cleave_a2.gd`, `tests/probe_s12_rock_rate.gd`, `tests/probe_s12_field_budget.gd` — cascade rows follow the mixed set + the live table.

## Deviations
1. `_roll_look`'s guard was `size_class > SIZE_LARGE`, so `SIZE_XL` fell into the `SIZE_ANY` uniform branch (measured: an "XL" rock drew look 3). Bound is now `SIZE_XL`, which rule 3 requires. Reversal: one token.
2. `FRAGMENT_SPLIT` is **kept** (documented retired) rather than deleted: frozen rows in
   `probe_rock_cleave.gd`, `probe_rock_cleave_a2.gd`'s CONST block and both `probe_s12_*`
   still read it, and §3 does not list them. `_fragment_size` had no reader and is gone.
3. Three `test_engine2_cleaving` rows are **renamed**, not just re-asserted (their names asserted the retired one-kind rule).
4. Rows moved beyond §3's literal list: see the pre-grep note above (4 rows across 4 files).
5. `reset_to_defaults` re-types both pinned literals (the S13 `tier_base_yield` pattern); the anti-drift row and the snapshot round-trip both cover the second copy.
6. Rule 5's overlay **sliders for the two new fields are skipped** (allowed): the fields ride Save/Load only, and the TUNED badge reads them through `to_dict`.
7. The before/after gate pair was measured while the S15 lane was editing `game/`, `ui/` and `tests/`; their rows are attributed above and never reverted. `probe_s12_field_budget.gd` carries one of their rows (the `w_cells` agreement) beside mine.
8. Restoring my files around that measurement used `cp` from an md5-verified backup plus `git checkout --` on my paths only; no shell tool edited file content, and the restored md5s match the edit-tool output exactly.
9. AC4's worst deviation is 2.4 pp of the 3 pp bound (S 37.6 % vs 40). It is deterministic (seeded), but any later shift of the field RNG stream moves it.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `probe_rock_cleave.gd` (frozen A1) now reports `count_Large_size` + `count_Medium_bounds` FAIL against the S14 mix; not in §3's moved list, left untouched | LOW | `tests/probe_rock_cleave.gd:215-230` |
| `test_size_class_follows_the_look_row` still asserts "inside the three rows"; passes only because its seed rolls no XL | LOW | `tests/test_engine2_cleaving.gd:287` |
| No dev-overlay sliders for `split_mix` / `spawn_size_weights` (rule 5 permits skipping) | optional | `ui/dev/dev_tuning_menu.gd` |
| `tests/test_s14_splits.gd.uid` does not exist yet; the editor's next scan generates it, so the wave commit should pick it up | housekeeping | `vajb-orbit/tests/` |
