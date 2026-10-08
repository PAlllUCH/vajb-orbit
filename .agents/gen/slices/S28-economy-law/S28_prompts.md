# S28_prompts.md — dispatch lines (one per worker; run in the brief's order)

**Models (the owner's 2026-10-03 roster, as S24 ran it):** builders run
`hyper/deepseek-v4.1-flash` at `--reasoning-effort xhigh` (that route's top
rung; its ladder is low/high/xhigh, not max); the reviewer runs
`hyper/glm-5.3-flash` at `--reasoning-effort max`. `deepseek/deepseek-flash`
is the same model on the DeepSeek route if the Hyper quota throttles — say so
before switching.

Run order **C1 → C2 → R1 → (F1 only on HIGH/MED)**. C1 and C2 are
file-disjoint but run in order (one live session; the gate is global). Launch
each with `run_in_background: true` and **wait on it** (`job_output`,
`wait: true`); a wedged worker (0 sockets, frozen I/O) is killed with python
SIGKILL — wrapper AND inner pid — then re-dispatched; re-check `git status`
and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s28_start \
  && git tag s28_start
```

## S28-C1 — the value table and the fee law (A1–A5)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/mineral_catalog.gd,vajb-orbit/game/refinery.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/tests/test_p1_catalogues.gd,vajb-orbit/tests/test_p1_pricing.gd,vajb-orbit/tests/test_p1_refinery.gd,vajb-orbit/tests/test_s34_refinery_queue.gd,vajb-orbit/tests/probe_s34_review.gd,vajb-orbit/tests/test_s28_econ.gd,.agents/gen/slices/S28-economy-law/S28-C1_report.md' \
     crush run "You are worker S28-C1 on the Vajb Orbit workspace, wave S28 universal cost law, builder 1 of 2. Read .agents/gen/slices/S28-economy-law/S28_BRIEF.md end to end, then SLICE.md, then the 2026-10-08 S28 blocks in docs/gameplay/01_economy_core.md, 02_minerals.md, 04_refinery.md and 05_exchange.md - they are the law; the superseded sections they amend are context only. Task: land A1, A2, A3 and A4 exactly. A1: write the 20-row value table of 02's 2026-10-08 block into game/mineral_catalog.gd - T1's ten value cells byte-identical to the shipped rows, T2 to T4 ore and ingot exactly as tabled (ingot equals round of ore times 3.6), names, descriptions, icons and tiers untouched. A2: the exchange keeps its one pricing family - nothing else may restate a price; the restated 05 section 10 example rows must come out of the live catalogue arithmetic. A3: the fee law of 04 section 8 into game/refinery.gd - a conversion_fee(mineral_id) helper reading max of 15 and ingot times 80 over 1000 with integer truncation, fee_for gaining the mineral id as its first parameter, the multiplier and the whole-credit truncation behaving exactly as shipped so u_refine halves after the floor (iron 15 becomes 7, not 7.5). A4: re-point the four refinery_panel.gd fee call sites to the new signature; the panel still hardcodes no price and no duration. Docs are read-only. Update the moved test rows - test_p1_catalogues value rows, test_p1_pricing gold and krilium demand rows plus the sale_quote and exchange_price figures, test_s34_refinery_queue duration rows (gold 26 seconds, krilium stays 60, iron and copper stay 10) - and keep test_p1_refinery green untouched: its sealed line 192 row must not move. probe_s34_review figures re-derive. New suite tests/test_s28_econ.gd asserting the derivation from the live catalogue: tier ore means 22.6, 45.2, 90.4, 180.8 within one percent, the times-3.6 law, the full fee column, the monotone board, and the SC model rows (belt hold about 1330 gross within ten percent, T4 hold about 8000 within ten percent). Run the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S28-economy-law/S28-C1_report.md from the REPORT template, 120 lines maximum, answering A1 to A5 with cites and tabling every moved value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_c1.log 2>&1
```

## S28-C2 — the battery law and the bloom cap (A6–A8)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/ore_tuning.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/ui/dev/dev_tuning_menu.gd,vajb-orbit/game/poi.gd,vajb-orbit/tests/test_s13_caps.gd,vajb-orbit/tests/test_s13_mining_batteries.gd,vajb-orbit/tests/test_s13_devmenu.gd,vajb-orbit/tests/test_s6_poi_loot.gd,vajb-orbit/tests/test_s28_events.gd,.agents/gen/slices/S28-economy-law/S28-C2_report.md' \
     crush run "You are worker S28-C2 on the Vajb Orbit workspace, wave S28 universal cost law, builder 2 of 2, running after builder 1 - the value table and the fee law are already in; re-derive nothing, read the live catalogue. Read .agents/gen/slices/S28-economy-law/S28_BRIEF.md end to end, then SLICE.md, then the 2026-10-08 S28 blocks in docs/gameplay/01_economy_core.md and 11_galactic_map.md. Task: land A6, A7 and A8 exactly. A6: the battery law - game/mining_laser.gd gains the declared constant BATTERY_GAIN 0.4 beside its cycle constants, extract_cycle's work line becomes work_per_unit times (1 plus gain times bank minus 1), game/ore_tuning.gd carries battery_gain as a live static var with the S13 anti-drift pattern - the declared const, the default, reset_to_defaults, to_dict and from_dict - and battery() keeps reporting the fitted count while only the work arithmetic moves; the floor stays one channel and a fit without w_mining still mounts no laser. The F1 overlay carries the new field (ui/dev/dev_tuning_menu.gd). A7: the ore bloom cap - poi.gd ORE_BLOOM_ROCKS 10 becomes 6 and ORE_BLOOM_YIELD_MULT 2 becomes 1.5 (the roll rounds as roll_yield does), the 200 u trigger and the T plus 1 tier bonus untouched. A8: new suite tests/test_s28_events.gd asserting the battery law (1, 2, 3 and 7 fitted modules deliver 1, 1.4, 1.8 and 3.4 work units per cycle) and the bloom constants from the live surfaces. Update the moved rows - test_s13_mining_batteries work rows, test_s13_caps additive default row, test_s13_devmenu additive field row and Save/Load key, test_s6_poi_loot bloom rows. Docs are read-only. Run the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S28-economy-law/S28-C2_report.md from the REPORT template, 120 lines maximum, answering A6 to A8 with cites and tabling every moved value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_c2.log 2>&1
```

## S28-R1 — mandatory review (after C1 and C2 report)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S28-economy-law/S28-R1_review.md' \
     crush run "You are worker S28-R1, the mandatory reviewer of wave S28 - brief .agents/gen/slices/S28-economy-law/S28_BRIEF.md. Diff findings against the brief's section 5 extracts and the 2026-10-08 S28 blocks they cite, never against the builders' reports. Grade A1 to A11 first, re-measuring yourself on fresh scratch stores with a byte-identical replay. Check the 20 rows against 02's table cell by cell and that T1's ten cells show no diff; check the fee column across all twenty minerals including the floor binding through silver and the u_refine truncation (iron 7, krilium 32); check the four panel call sites and that the panel hardcodes no number; check the battery law at 1, 2, 3 and 7 fitted modules and that battery() still reports the fitted count; check the bloom constants and the trigger; check that test_p1_refinery is green untouched and the sealed line 192 row did not move. Look for the seams the builders leave unwired by measurement, never by trust - any fee path still reading the retired flat constant, any call site still on the old signature, any demand row the catalogue no longer reproduces. An unlisted gate row that moved, a pinned value that moved, or a read site still on the old arithmetic is HIGH. Update docs/CONTRACTS.md: a new section pinning this wave's interface - the fee door with its floor and permille, the battery law, the bloom constants, the value-table pointer to 02's block - plus the section 9 measured block and the section 10 changelog entry, at the next free rows read at write time. Write slices/S28-economy-law/S28-R1_review.md from the REVIEW template, 150 lines maximum, findings S28-C1 or S28-C2 with F numbers, a tier and one evidence line each, and LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_r1.log 2>&1
```

## S28-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S28-economy-law/' \
     crush run "You are worker S28-F1, the fixer of wave S28 - brief .agents/gen/slices/S28-economy-law/S28_BRIEF.md, review .agents/gen/slices/S28-economy-law/S28-R1_review.md. Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and write slices/S28-economy-law/S28-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_f1.log 2>&1
```
