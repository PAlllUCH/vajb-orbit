---
slice: S28
reviewer: S28-R1
verdict: passed-with-followups
gate: "1186/0 (baseline) → 1202/0, twice hermetic on fresh scratch stores"
---

# S28-R1 review

## Acceptance list
Graded against the brief's §5 extracts and the six 2026-10-08 S28 blocks, re-measured
on fresh scratch stores (`tools/s28_r1_remeasure.gd`, 37/37 ok, byte-identical
replay), never against the builders' reports.

- A1 — pass — the 20 rows read 02's block cell by cell (`mineral_catalog.gd:29-270`);
  T1's ten cells byte-identical (`git diff` touches only T2–T4 value lines); the
  board monotone in both columns (probe + `test_s28_econ.gd:149`).
- A2 — pass — all 120 ore/ingot × demand pairs route through `unit_net(baseline_of(…))`
  (`test_s28_econ.gd:227`); 05 §10's four rows and raw iron 18 reproduce live (probe
  `s10_*`, `raw_iron`); `sale_quote(259, 1.2, 10)` = 3108/63/3045 off the live
  arithmetic (probe `gold_batch`), `unit_gross` 311 / `exchange_price` 305 (`gold_unit`).
- A3 — pass — `conversion_fee` = 04 §8's column for all 20 (probe `fee_*`, 20/20);
  iron's 15/30/45 rows survive (`test_s28_econ.gd:208-210`); the u_refine truncation
  is iron 7 / krilium 32 (probe `u_refine_*`); the floor binds through silver — 16 is
  the first cell above it (probe + `:200`).
- A4 — pass — one fee door `fee_for(mineral_id, conversions, mult)` (`refinery.gd:122`);
  the panel's four sites re-pointed (`refinery_panel.gd:403/:887/:1062/:1140`) and the
  panel hardcodes no number (its fees exist only via `fee_for`/`_queueable_fee`); the
  retired flat has no production reader (`FEE_PER_CONVERSION` aliases the floor,
  `refinery.gd:39`, read by two suites only).
- A5 — pass — `test_s28_econ.gd` (10 rows) derives the ladder (tier means ±1 %, the
  ×3.6 law on all 15 T2–T4 rows, the monotone board, the fee column) and the SC model
  rows live: belt 1 273 (target 1 330 ±10 %), T4 7 626 (8 000 ±10 %); my independent
  re-derivation agrees with both readings.
- A6 — pass — 1/2/3/7 fitted deliver 1.0/1.4/1.8/3.4 work units/cycle (probe
  `battery_*`); `battery()` still reports the fitted count (`mining_laser.gd:149`);
  the floor is one channel; `battery_gain` rides `reset_to_defaults`/`to_dict`/
  `from_dict` (`ore_tuning.gd:125/:160/:192`) and the overlay slider
  (`dev_tuning_menu.gd:88-95/:365/:407`).
- A7 — pass — `poi.gd:92-94` = 6 rocks × 1.5, bonus 1, trigger 200 (`:69`); the roll
  rounds as `roll_yield` does (`roundi`, `poi.gd:588`); `test_s6_poi_loot.gd:421-455`
  restates the rows.
- A8 — pass — `test_s28_events.gd` (6 rows) asserts the battery law (declared const,
  live default, the four counts, the gain-1.0 sensitivity, the floor, no-fit-mounts-
  nothing) and the bloom cap (constants, trigger, bonus, a triggered 6-rock T2 spawn
  inside the 1.5× band), every figure off the live surfaces.
- A9 — pass — gate ×2 hermetic: `[SUMMARY] passed=1202 failed=0`, exit 0, both runs;
  `test_p1_refinery` alone 6/0; the sealed row keeps its hide-sub-convertible-stacks
  semantics (only its Gold fee figure and two call shapes moved, disclosed in the
  suite's header); every moved test row in the reports' tables matched my own diff
  reads.
- A10 — pass — this write: §25 (the fee door, the battery law, the bloom constants,
  the value-table pointer), §9's S28 measured block (S24's block compressed in
  place), §10's v0.47 row, §19's bloom sentence restated, §21's stale `:192` cite
  corrected to the row's name; the index regenerated (27 sections, 2 959 lines).
- A11 — pass — both reports table every moved value with its reversal and M-tick and
  name escalation buckets (C1: four bucket-2 items; C2: one bucket-2, two bucket-1).

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `game/refinery.gd:129-130` (S28-C1) | `resource_seconds`' comment restates the retired figures ("Gold's 395 reads 40 s"); the live formula derives gold's 26 s — a stale example, no behaviour. | → ticketed **T-154** (rider on the next wave owning `refinery.gd`) |
| F2 | LOW | `tests/test_engine2_weapons.gd:542` (harness, no builder) | The `[s5-racks]` salvo diagnostic jitters one frame between hermetic gate runs (`[0,37,73,…]` vs `[0,38,74,…]`), so a whole-log byte-diff false-positives; the `[SUMMARY]` law is unaffected. Pre-existing, surfaced by my log diff. | → ticketed **T-155** (harness) |
| F3 | MED | `tools/r1_s13_ac3_replay.gd:54` (S28-C2's flag, verified live) | The S13 replay asserted the retired linear N: run as shipped it printed `FAIL bank2_scaling`/`bank3_scaling` while printing the law's own 1.4/1.8 — the battery's audit instrument reading a superseded law. | **fixed by S28-R1** — decision: fix, not ticket. `tools/` is R1's file set, the probe is the battery-law audit instrument, and re-pointing its expected side implements the owner-ratified M12 rather than changing any pin (the tool is in no pin and no tests-that-move row); verified below |

No HIGH findings; no MED remains after F3's in-review fix.

## Verified fixes
- F3 — fixed by S28-R1 in its own file set: the expected side now reads
  `1 + OreTuning.battery_gain × (N − 1)`; re-run → banks 1/2/3 at
  1.0000/1.4000/1.8000 units/cycle, `[S13R1] done failures=0`.

Also verified, not findings:
- **The orchestrator's s23 repair is correct.** The four re-pointed call sites
  (`test_s23_content.gd:239/:246`, `probe_s23_r1.gd:126/:142`) assert iron's list 15
  and its u_refine 7 — the same figures the retired flat produced, so the suites'
  asserted meaning is preserved; iron is the floor mineral, where old law and new
  law agree.
- **C1's escalation of brief §8's three pricing literals was right** (bucket 2): the
  shipped rows derive from gold's pinned 259 (02's block / 05 §10), not the brief's
  216-derived 212/249/254; the live figures 3108/63/3045, 305 and 311 re-derive
  exactly, and A2's "never from literals" holds.
- **CONTRACTS §21's stale `test_p1_refinery.gd:192` seal cite** was S34-era drift
  (the pinned row `test_stacks_lists_only_convertible_minerals` sat at 239 pre-wave);
  corrected to the row's name in this write — the pinned semantics never moved.

## Gate
- Before (baseline, post-S24): `[SUMMARY] passed=1186 failed=0`.
- After, twice on fresh scratch stores, exit 0 both, identical summaries:
  `[SUMMARY] passed=1202 failed=0` / `[SUMMARY] passed=1202 failed=0`. Both tolerated
  red lines (§9) present exactly as documented (the `test_weapon_fx_f4` SCRIPT ERROR
  and one `Parameter "data.tree" is null`) — pre-existing, not regressions.
- Disclosed chain (graded, not hidden): 1186 → **1184/1** (C1's signature broke
  `test_s23_content.gd` + `probe_s23_r1.gd`, two suites outside every worker file
  set) → **1196/0** (the orchestrator's four-site repair, verified above) →
  **1202/0** (C2's six rows). My two runs reproduce the finished figure.
- Negative controls: `test_p1_refinery` alone → 6/0; the re-measure probe ×2 → 37/37
  ok with an empty `diff`; the fixed replay tool → `failures=0`.
