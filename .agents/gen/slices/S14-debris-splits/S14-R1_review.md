---
slice: S14
reviewer: S14-R1
verdict: blocked (HIGH remains)
gate: "834/0 -> 852/0 (twice, fresh scratch stores)"
---

# S14-R1 review

Diff targets: `docs/gameplay/02_minerals.md` **§5.2** (the S14 pin) and **§5.1
Rule A**. Every AC was re-measured on the shipped worktree by this review's own
probe (`vajb-orbit/tools/r1_s14_ac_replay.gd`, `failures=0`) plus a replay of the
four rock probes; nothing is taken from B1's report. The moved rows were diffed
against **brief §3's** list (`SLICE.md` carries no tests-that-move section — its
third section is Out of scope — so the list the brief §7 names as "§3's list" is
the brief's own).

**2 HIGH / 1 MED / 6 LOW (L202–L207).** Both HIGHs are the §3 row list being
incomplete, not wrong behaviour: no AC is off its number and no shipped rule is
contradicted. Each one's remedy is a bucket-2 amendment to §3's list — a fixer must
**not** revert them, because the §2 pins make the old rows false.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S14-B1/F1 | HIGH | `tests/test_engine2_cleaving.gd:453-486` | A row moved off §3's list: `test_the_fragment_count_varies_inside_the_amended_bounds` moves its bounds `2-5` to L `3-7` / M `1-3` and splits the seen-set per class; §3 lists only the `FRAGMENT_SPLIT` const pins (`:332-338`) and the L→M / M→S rows. Changing it was forced (left as-is it is a red **gate** row) and B1 disclosed it, so the defect is §3's list, not the edit. Bucket 2. | designer — amend §3's list; no F1 code pass |
| S14-B1/F2 | HIGH | `tests/probe_rock_cleave_a2.gd:280-372` | The COUNT block's four rows (`count_*_bounds` / `_all_values` / `_uniform` / `_size`) and the new `_total_span` helper are off §3's list, which anchors only `:670-671` and `:696-699`; the old rows assert the retired one-kind `2-5` rule, so they had to move. Disclosed by B1, `failures=0` on replay. Bucket 2. | designer — extend §3's list to the COUNT rows; no F1 code pass |
| S14-B1/F3 | MED | `tests/test_engine2_cleaving.gd:291-292` | `test_size_class_follows_the_look_row` still asserts `klass <= SIZE_LARGE` ("inside the three rows"). Since S14 a spawned rock rolls XL at 8 %, so this live gate row passes only because the fixture's seed rolls none — a reseed turns the gate red. Not on §3's list, so B1 correctly left it untouched. Bucket 2. | developer/designer — §3's list, then the row in the next wave |
| S14-B1/F4 | LOW | `tests/probe_rock_cleave.gd:215-230` | Frozen A1 probe now reports **2** failures against 02 §5.2 — `count_Large_size` ("one tier down") and `count_Medium_bounds` ("inside 2-5") — replayed here as `[RC] done failures=2`; its CONST rows (`:174-185`) still pass on the retained `FRAGMENT_SPLIT`. Not in §3, so left; the probe is not in the gate. | → `L202` |
| S14-B1/F5 | LOW | `game/ore_tuning.gd:186-189` | `_span`'s comment says an unusable value is "rejected for an inverted range", but it returns `Vector2i.ZERO`, which `from_dict`'s `pair.x >= 0 and pair.y >= pair.x` accepts as a `0-0` range: a garbage row lands as a present zero-count kind, never dropped. Harmless (rolls nothing) but the comment claims the opposite. | → `L203` |
| S14-B1/F6 | LOW | `tests/probe_s12_field_budget.gd:96-101`, `probe_s12_rock_rate.gd:116-120,384` | Evidence/helper, not asserted rows: the `FRAGMENT_SPLIT` print is renamed `retired_…`, the live `split_mix`/`spawn_size_weights` print is added, and `_size_name` gains the XL case. All inside the two listed files; noted so the §3 amendment in F2 also covers them. | → `L204` |
| S14-B1/F7 | LOW | `vajb-orbit/tests/` | `tests/test_s14_splits.gd.uid` does not exist (B1's own note); the editor's next scan writes it, so the wave-boundary commit must pick it up. | → `L205` |
| S14-B1/F8 | LOW | `staging/verify_wave.py:144` | `--forbidden` is exact-string membership, so the mandated directory entries (`docs/design/`, `ui/`, `addons/`) can never match a changed path; the guard on those three trees is unenforced by the tool. Verified by hand instead: no `docs/design/`, `addons/` or `project.godot` path in the diff, and the two `vajb-orbit/ui/station/*` files are the S15 lane's. | → `L206` |
| S14-B1/F9 | LOW | `tests/test_s14_splits.gd:41-44,257-270` | AC4 passes with **0.5 pp** of headroom: **M** reads **0.3450** against the 0.32 pin at 1000 seeded rolls (+2.50 pp of the 3 pp bound; S is -2.40 pp, XL -0.80, L +0.70). The bound is met and the roll is deterministic, but any later shift of the field's RNG stream (a new roll before `_roll_size`, a re-seed) can cross it without any behaviour changing. | → `L207` |

## AC re-measurement (own probe + probe replays, all on the shipped tree)

- **AC1** 200 seeded XL shatters: **1708** children, mean **8.540**; L **1-3** (min 1, mean 2.090), M **2-4** (min 2, mean 2.930), S **2-5** (min 2, mean 3.520); **0** of 1708 children at or above XL, **0** per-kind counts outside the rolled ranges, totals 5-12 in 8 distinct values. Worst per-kind chi-square **2.47** against uniform over its own range (limit 16.27) — each kind's count is its own independent roll, not a derived share.
- **AC2** 60 L + 60 M shatters: **0** children at or above their parent, **0** per-kind counts outside the rows; L totals `{3:8, 4:17, 5:17, 6:13, 7:5}` and M totals `{1:23, 2:21, 3:16}` — both bands fully covered. 60 Small shatters spawn **0** fragments and pay **79** pickup units.
- **AC3** `_rolled_yield` has exactly one caller, `asteroid_field.gd:237` inside `_roll_rocks` (setup); `_cleave` hands each fragment `float(units)` as its bore (`:446-453`), so **no shatter-side roll exists**. Fully mined families, bore **32.0**: realised **32** for XL, L and M parents over 4 seeds (12 rows), every one inside `[bore - 1, bore + 1]` and the **+1 slack never used**. Rule B stays deferred: `SIZE_YIELD_MULT` is absent tree-wide; `FIELD_ROCKS_MIN/MAX` and `tier_weights` are untouched by the diff.
- **AC4** 1000 seeded rolls on the field's own rng: S **376 (0.3760)** vs 0.40, M **345 (0.3450)** vs 0.32, L **207 (0.2070)** vs 0.20, XL **72 (0.0720)** vs 0.08; worst deviation **0.0250 ≤ 0.03**. 40 real builds (240 spawned rocks) landed S 100 / M 75 / L 49 / XL 16.
- **AC5** `LOOK_TEXTURES` = 12 (XL row 9-11), `LOOK_WIDTHS[9..11]` = **180.0** beside L's 132.0, each XL texture identical to its L silhouette; 24 seeded draws covered looks **9/10/11** and every drawn sprite measured **180.0 u** at its drawn scale.
- **Anti-drift (rule 6)** the live `split_mix` and `spawn_size_weights` str-equal this review's own transcription of 02 §5.2, not the brief's. Rule 1's exception is met: `FRAGMENT_SPLIT` is kept **and is still read** by `probe_rock_cleave.gd:174-185` plus the probes' CONST prints, while `_fragment_size` is deleted with **0** references.

## Moved-row audit (brief §3)

`git diff` touches S14's three code files and six test/probe files (one of them
new). Every change resolves to a §3 entry except F1 and F2 (both disclosed).
Listed and verified: the
`FRAGMENT_SPLIT` const pins → the live table (row renamed, row count unchanged);
the L→M and M→S rows → the mixed sets (renamed); `test_s13_caps.gd:178`'s
`children.size() >= 2` → `>= 1`, its conservation rows untouched; A2's INHERIT
rows (`:670-671, 696-699` pre-edit) with the parent moved Medium→Large so the
mixed set is what is measured; the two S12 probes' cascade rows. The "not moved"
set is byte-untouched: `test_s2_6_burst.gd`, `test_combat_repair_c5.gd`,
`test_engine2_cleaving.gd:302` (chip arithmetic) and every other S13 gate row.
`test_engine2_cleaving` (15) and `test_s13_caps` (10) have identical `func test_`
counts at HEAD and in the tree, so the renames added no row.

## Gate

- Baseline `834/0` (`s14_start`). Measured **`[SUMMARY] passed=852 failed=0`**
  twice on fresh scratch stores (`/tmp/s14_r1_gate1`, `/tmp/s14_r1_gate2`), exit 0,
  0 `[FAIL]` lines, identical counts.
- Growth `834 → 852` = **+18**: `test_s14_splits`' **9** (S14, AC1-AC6) + the
  parallel **S15 lane's** 5 `test_s15_battery_cap` + 4 `test_s15_armory_layout`.
  S15's rows and their `weapon_1..5` / `GROUPS_MAX` edits are attributed, never
  reverted; `w_cells`' row in `probe_s12_field_budget.gd` is theirs too.
- `staging/verify_wave.py verify --baseline s14_start --forbidden … --tests
  --expect-reports …` → `"problems": []`. The tool's exact-match `--forbidden`
  caveat is F8/L206.
- Probe replays on the shipped tree: A2 `failures=0` (`COUNT Large total=3-7
  {3x32, 4x62, 5x108, 6x68, 7x30} | kind 1 chi2=0.26 | kind 0 chi2=2.94`, `Medium
  1-3 chi2=2.16`, `INHERIT cleaves=30 n=149 classes=[1,0] child_bore` all 1.0),
  `[S12K0] done failures=0`, `[S12K1] done failures=0`, frozen `[RC] done
  failures=2` (F4). Live `profile.cfg` md5 `5fabc1b9…` byte-identical before and
  after every run (all runs on scratch `XDG_DATA_HOME` stores).
