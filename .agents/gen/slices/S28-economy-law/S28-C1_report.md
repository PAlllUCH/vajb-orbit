---
slice: S28
worker: S28-C1
model: "hyper/deepseek-v4.1-flash @ xhigh"
status: actionable
gate: "1186/0 (post-S24) -> 1184/1"
---

# S28-C1 report

## Result
A1–A5 landed: 02's 20-row value table, 04 §8's value-relative fee behind one door
(`conversion_fee` + `fee_for(mineral_id, …)`), the four panel call sites re-pointed,
the moved rows restated and `tests/test_s28_econ.gd` added (10 tests, green). Gate
×2 on fresh scratch stores: **1184 passed, 1 failed**, the failure a suite outside
this worker's file set (Deviation 2, bucket 2).

## Acceptance list answers
- **A1 — done.** 20 rows as 02's 2026-10-08 table (`game/mineral_catalog.gd:29-270`);
  T1's ten cells byte-identical (diff of the ten value lines vs `HEAD` is empty);
  board monotone across tiers, asserted live (`tests/test_s28_econ.gd:149`).
- **A2 — done.** `exchange.gd` was already one family (`baseline_of` reads the
  catalogue) and nothing restates a price: `test_s28_econ.gd:227` proves all 120
  ore/ingot × demand pairs route through `unit_net(baseline_of(…))`; `:252`
  reproduces 05 §10's rows off the live baselines.
- **A3 — done.** `game/refinery.gd:109` = `max(15, ingot × 80 / 1000)`, integer
  truncation; the column is asserted per mineral (`test_s28_econ.gd:170`), iron's
  15/30/45 rows and the `u_refine` halves (iron 7, krilium 32) at `:207`.
- **A4 — done.** `fee_for(mineral_id, conversions, mult)` is the only fee door
  (`game/refinery.gd:122`); its three internal callers (`:166`, `:252`, `:302`) and
  the panel's four (`ui/station/refinery_panel.gd:403`, `:887`, `:1062`, `:1140`)
  re-point. The panel hardcodes no price or duration: `rg '\b(15|20|26|40|60|259|
  395|65)\b' ui/station/refinery_panel.gd` returns only layout constants and `_mmss`'s 60.
- **A5 — done.** `tests/test_s28_econ.gd` asserts the doubling tier means against
  22.6/45.2/90.4/180.8 and 81.4/163/326/652 within 1 %, the within-tier multiplier
  ladder, `ingot = round(ore × 3.6)` on all 15 T2–T4 rows, the monotone board, the
  fee column and the two SC model rows, every figure computed live.
- **A11 — done.** Every moved value is tabled below with its reversal and tick; the
  flagged items name their bucket.

## Deviations from SLICE.md
1. **`test_p1_refinery.gd` could not stay untouched (bucket 2 — pinned tests list).**
   The law re-prices a Gold conversion 15 → 20 and re-signs the fee door, and this
   suite asserts both: gold fee rows `:148`, `:151`, `:254`, the combined batch
   `:206`/`:214`/`:222` (45 → 55), and the two old-shape calls `:266-267` (now
   `fee_for(&"iron", …)`). The sealed row
   (`test_stacks_lists_only_convertible_minerals`; the docs' `:192` is its pre-S34
   line) keeps its hide-sub-convertible-stacks semantics; only those six figures and
   two call shapes moved. Reversal: 04 §8's flat 15 restores every row.
2. **`tests/test_s23_content.gd` and `tests/probe_s23_r1.gd` call the retired
   signature and are outside `VAJB_WORKER_FILES` (bucket 2 — the pinned file set).**
   The suite no longer loads: `Parse Error: Too few arguments for "fee_for()" call.
   Expected at least 2 but received 1.` (`test_s23_content.gd:239`) and `Invalid
   argument for "fee_for()" function: argument 1 should be "StringName" but is
   "int".` (`:246`). No signature satisfies both the pin and these calls (the second
   passes the multiplier positionally), so the file set needs widening — remedy in
   Follow-ups. The probe's `:126`/`:142` are the same shape and are not in the gate.
3. **Brief §8's three `test_p1_pricing.gd` figures contradict the pinned baseline
   (bucket 2 — pinned numbers).** §8 gives `sale_quote` 395→**212**,
   `exchange_price(gold, 1.2)` 465→**249**, `unit_gross` 474→**254**; those follow
   from a baseline of 216 (gold's *raw 3-ore* total), while 02's block and 05 §10 pin
   gold's ingot at **259** (the brief's own §5 extracts). A2 requires the live
   arithmetic, so the rows ship as `sale_quote(259, 1.2, 10)` = 3 108 gross / 63 fee /
   3 045 paid, `exchange_price(ingot_gold, 1.2)` = 305, `unit_gross(259, 1.2)` = 311.
   Reversal: the brief's literals (they fail against the live catalogue).
4. **The panel's footer legend (bucket 1 — inside A4's pin, string unpinned).**
   `ui/station/refinery_panel.gd:86` printed the flat `FEE_PER_CONVERSION`, which with
   a value-relative fee is a restated price; it now prints `_queueable_fee()`, the live
   combined charge of the QUEUE ALL button it labels (`"%d ORE = 1 INGOT · FEE %d CR
   QUEUED"`). Reversal: the old string plus `RefineryModule.FEE_PER_CONVERSION`.
5. **The SC model's shape (bucket 1 — inside A5's pin, model unpinned).** A full
   40-unit hold = 13 conversions (`01` §5.1), read at the exchange's net unit price at
   demand 1.0 less the fee those conversions paid at their tier's mean (`01`'s SC is "a
   40-cargo hull, net of sinks"); the belt reads the S1–S3 mix of `11` §1.1. Measured
   belt **1 273** (target 1 330, −4.3 %) and T4 **7 626** (8 000, −4.7 %), i.e. 1.16 ×
   SC(1) and 1.27 × SC(4). Reversal: a gross reading (belt 1 495 would miss the band).
6. `FEE_PER_CONVERSION` survives as an alias of `FEE_FLOOR` (`game/refinery.gd:39`)
   because `test_p1_refinery.gd:269` reads it; the flat `FEE_PER_UNIT` is retired
   (`rg FEE_PER_UNIT` is empty).

## Moved values (reversal · tick)
| Value | Was → now | Reversal | Tick |
|---|---|---|---|
| T2–T4 ore / ingot, 15 rows (`mineral_catalog.gd:29-270`) | 45/162 … 600/2160 → 36/130 … 224/806 | 02 §2's table | M8 |
| fee per conversion (`refinery.gd:109`) | flat 15 → 15 / 15.2 / 25.6 / 51.4 by tier mean | flat 15 | M9 |
| `u_refine`'s half of a fee | 7.5 → 7 (iron); krilium 32 | flat 15 | M9 |
| gold duration (`test_s34_refinery_queue.gd:99`, `probe_s34_review.gd:118`) | 40 s → 26 s (krilium 60, iron/copper 10) | 02 §2's table | derived |
| 05 §10 net rows (`test_p1_pricing.gd:23-27`) | 387/232/619 · 159/95/254 · 2117/1270/3387 → 254/152/406 · 127/76/204 · 790/474/1264 | 05 §3's table | M8 |
| gold batch / unit gross / unit net (`test_p1_pricing.gd:77-81`, `:134`) | 4740/95/4645 · 474 · 465 → 3108/63/3045 · 311 · 305 | 05 §3's table | M8 |
| gold fee rows (`test_p1_refinery.gd:148`,`:151`,`:206`,`:214`,`:222`,`:254`) | 30 · 30 · 45 · 45 · −45 · 15 → 40 · 40 · 55 · 55 · −55 · 20 | flat 15 | M9 |
| gold fee rows (`test_s34_refinery_queue.gd:154`,`:159`, `probe_s34_review.gd:249`) | 30 → 40 | flat 15 | M9 |
| QUEUE ALL combined fee (`probe_s34_review.gd:174-176`) | 60 → 65 | flat 15 | M9 |
| probe countdown pin (`probe_s34_review.gd:344`) | `begins_with("01:")` → live `2 × resource_seconds(gold)` | the old pin | derived |

## Evidence
- Gate ×2 on fresh scratch stores, byte-identical replays: `XDG_DATA_HOME=/tmp/gate_f1`
  and `/tmp/gate_f2`, `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 3000` → `[SUMMARY] passed=1184
  failed=1` twice, the failure `[FAIL] test_s23_content.gd: script cannot be
  instantiated (parse error…)`. Arithmetic: 1186 − 12 (the blocked suite's methods)
  + 10 (the new suite) = 1184.
- `tests/test_s28_econ.gd` alone → `passed=10 failed=0`; the six moved suites
  together (p1_catalogues, p1_pricing, p1_refinery, s34_refinery_queue, p1_market,
  s28_econ) → `passed=56 failed=0`; `probe_s34_review.tscn --quit-after 600` →
  `[S34R] PASS 0`.
- T1 byte-identity: `git show HEAD:vajb-orbit/game/mineral_catalog.gd | rg
  '^\t\t&"(ore|ingot)_value":' | head -10` vs the working tree read → diff empty.

## Files touched
- `game/mineral_catalog.gd` — the 15 T2–T4 rows' value cells; header cites 02's block
- `game/refinery.gd` — `FEE_FLOOR`/`FEE_VALUE_PERMILLE`, `conversion_fee`, the re-signed `fee_for`, three callers, `FEE_PER_UNIT` retired
- `ui/station/refinery_panel.gd` — four fee call sites, the footer legend
- `tests/test_p1_catalogues.gd`, `test_p1_pricing.gd`, `test_p1_refinery.gd`, `test_s34_refinery_queue.gd`, `probe_s34_review.gd` — the moved rows above; `tests/test_s28_econ.gd` — new

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-point the two old-signature call sites so the gate returns to 0 failed (exact remedy: `fee_for(&"iron", 1)`, `fee_for(&"iron", 1, mult)`, and `fee_for(&"iron", 2)` / `fee_for(&"iron", 2, mult)` in the probe — every expected figure survives) | HIGH, bucket 2 | `tests/test_s23_content.gd:239`,`:246`; `tests/probe_s23_r1.gd:126`,`:142` |
| Re-seal the `test_stacks_lists_only_convertible_minerals` row at its new Gold figure (semantics intact) | doc pin | `docs/gameplay/04_refinery.md:173` |
| Correct brief §8's three `test_p1_pricing.gd` literals to the live arithmetic | doc pin | `S28_BRIEF.md:197-199` |
