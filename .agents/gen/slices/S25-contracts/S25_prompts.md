# S25_prompts.md — dispatch lines (one per worker; run in the brief's order)

**Models (the owner's 2026-10-03 roster, as S24/S28 ran them):** builders run
`hyper/deepseek-v4.1-flash` at `--reasoning-effort xhigh` (that route's top
rung; its ladder is low/high/xhigh, not max); the reviewer runs
`hyper/glm-5.3-flash` at `--reasoning-effort max`. `deepseek/deepseek-flash`
is the same model on the DeepSeek route if the Hyper quota throttles — say so
before switching.

Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch each with
`run_in_background: true` and **wait on it** (`job_output`, `wait: true`); a
wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s25_start \
  && git tag s25_start
```

## S25-B1 — the contracts board (A1–A8)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/contract_registry.gd,vajb-orbit/game/contract_registry.gd.uid,vajb-orbit/game/game.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/refinery.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/station/contracts_panel.gd,vajb-orbit/ui/station/contracts_panel.gd.uid,vajb-orbit/ui/station/contracts_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/test_s25_contracts.gd,.agents/gen/slices/S25-contracts/S25-B1_report.md' \
     crush run "You are worker S25-B1 on the Vajb Orbit workspace, wave S25 contracts board, builder. Read .agents/gen/slices/S25-contracts/S25_BRIEF.md end to end - its section 4's six rules bind every line you write - then SLICE.md, then the law in the brief's section 1 order: docs/gameplay/14_station_services.md section 2 and section 6 by range plus the 2026-09-27 P3 block and the 2026-10-08 S28 block (the payout scaling), docs/design/STATION_HUB.md section 15.2 (the CONTRACTS panel spec, U3 to U8) and section 5.2 (the confirm dialog), docs/design/UI_SPEC.md sections 12 to 15 and STATION_HUB.md sections 19 to 21 by range (shell v2), docs/gameplay/12_factions.md section 3 and section 4.1 plus its 2026-10-08 S24 block, docs/CODE_MAP.md by range. Task: land A1 to A8 exactly. A1: game/contract_registry.gd generates seeded 6-row boards on the 20-minute world clock with Haul/Hunt/Gather/Escort live, faction ties and sector-appropriate objectives, Expedition as the seam row S26 flips. A2: rewards pay the section 2 row at the target sector's tier per the S28 table - Hunt 800, 1100, 2200, 4400; Escort 1200, 1600, 3300, 6500; Haul's flat 300, 400, 800, 1600 plus spot times 1.25 read from exchange.gd's sale_quote; Gather times 1.4 - with 12 section 3's demand bias, Known's plus 5 percent hook, rounded to 100 CR and the rounding proven by probe. A3: Shunned and Outlaw see the U8 empty state, Champion sees the standing-order row, max 3 active with the U6 counter and chip. A4: real escrow - accept reserves the goods off the manifest, cancel returns them for exactly 100 CR, a double-completion probe pays once. A5: the escort loop per section 6 - the convoy spawns at the accepting station with Hauler stats and 50 percent visible cargo pods and 1 to 2 fighters, flies the fixed route at freighter speed, eats the corridor-midpoint ambush, win pays at the destination, loss costs minus 5 standing and the pirates keep the loot. A6: active contracts survive a dock/launch cycle and a restart; a dead escort cannot resurrect. A7: the CONTRACTS panel per STATION_HUB section 15.2 in ui/station/contracts_panel.gd wired into the SERVICES deck of ui/screens/station.gd in place of the MODULE OFFLINE placeholder at line 940, both U8 empty states verbatim, every new value tabled with reversal and tick id. A8: riders - ui/station/launch_panel.gd line 53 reads the docked sector's own name instead of the mockup-era HELIOS DRIFT, and game/refinery.gd lines 129 to 130's stale fee example is corrected to the live derivation, comment only, no behaviour change. The seams at game/station_registry.gd lines 417 and 423 and the exchange accessors are read-only - never redefine them. Docs and existing panels' layouts do not move. New suite vajb-orbit/tests/test_s25_contracts.gd with one row per acceptance item; run the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S25-contracts/S25-B1_report.md from the REPORT template, 120 lines maximum, answering A1 to A8 with cites and tabling every moved value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_b1.log 2>&1
```

## S25-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S25-contracts/S25-R1_review.md' \
     crush run "You are worker S25-R1, the mandatory reviewer of wave S25 (brief .agents/gen/slices/S25-contracts/S25_BRIEF.md; diff findings against its section 5 extract - 14 section 2 and 6 plus the 2026-10-08 S28 block are law - never against B1's report). Grade A1 to A8 first, re-measuring yourself on scratch stores: the seeded board shape (6 rows, faction ties, sector-appropriate objectives), each reward row's arithmetic at its target sector's tier incl. the S28 scaling table, the round-to-100-CR rule, the demand bias and Known's plus 5 percent, the gates (Shunned and Outlaw see the U8 empty state, Champion's standing-order row, max-3 with the U6 counter and chip), the escrow lifecycle end to end incl. the double-completion probe paying once and the 100 CR cancel, a full escort run both outcomes (win pays at the destination; loss reads minus 5 standing and no payout) with the ambush firing at the corridor midpoint, persistence through dock/launch and restart, and the deck against STATION_HUB section 15.2's U3 to U8 rows incl. the placeholder replaced at station.gd line 940 and the two empty states verbatim. Diff moved gate rows against the brief's section 8 list; an unlisted row moved or a pinned value that moved is HIGH. A reward number not in 14 section 2 plus the S28 block is HIGH. Check the riders: launch_panel.gd line 53 reads the docked sector's name; refinery.gd lines 129 to 130 changed comment-only. Update docs/CONTRACTS.md section 9 and 10 at the next free rows read at write time. Write slices/S25-contracts/S25-R1_review.md (REVIEW template, 150 lines max), findings S25-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_r1.log 2>&1
```

## S25-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/contract_registry.gd,vajb-orbit/game/contract_registry.gd.uid,vajb-orbit/game/game.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/refinery.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/station/contracts_panel.gd,vajb-orbit/ui/station/contracts_panel.gd.uid,vajb-orbit/ui/station/contracts_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/test_s25_contracts.gd,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S25-contracts/' \
     crush run "You are worker S25-F1, the fixer of wave S25 (brief .agents/gen/slices/S25-contracts/S25_BRIEF.md - read it for the pinned law; review .agents/gen/slices/S25-contracts/S25-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S25-contracts/S25-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 31 only — S25 contracts board. Brief: .agents/gen/slices/S25-contracts/S25_BRIEF.md. Prompts: .agents/gen/slices/S25-contracts/S25_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 32. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s25_start, build_code_map.py, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
