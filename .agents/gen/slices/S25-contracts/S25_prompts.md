# S25_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` on `--reasoning-effort max`.
Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s25_start \
  && git tag s25_start
```

## S25-B1 — the contracts board (A1–A7)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S25-contracts/S25-B1_report.md' \
     crush run "You are worker S25-B1 on the Vajb Orbit workspace, wave S25 (the contracts board). Read .agents/gen/slices/S25-contracts/S25_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md. Task: land A1-A7 exactly against docs/gameplay/14_station_services.md section 2 and section 6 (the pin - invent no reward number): game/contract_registry.gd generating seeded 6-row boards on the 20-minute world clock with Haul/Hunt/Gather/Escort live and Expedition as the seam row S26 flips (A1), the four reward rows exactly with faction demand biases and Known's +5 percent hook (A2), the standing gates and Champion's standing-order row and max-3 (A3), real escrow with the 100 CR cancel and a proven single-pay delivery (A4), the escort loop per section 6 - convoy at the accepting station, Hauler stats, 50 percent visible cargo pods, fixed route at freighter speed, corridor-midpoint ambush, win pays at the destination and loss costs -5 standing (A5), persistence through dock/launch and restart (A6), and the CONTRACTS panel per slices/D16-station-ui/D16-A1_report.md's spec (fallback: the auction row idiom under UI_SPEC section 3.10 A5) with the summary table (A7). R-S25-1 (board size 6, Expedition staged) is the only new value. Docs and existing panels' layouts do not move. New suite tests/test_s25_contracts.gd (one row per AC); headless gate twice on fresh scratch XDG_DATA_HOME stores, both [SUMMARY] lines recorded. Report slices/S25-contracts/S25-B1_report.md (REPORT template, 120 lines max) answering A1-A7 with cites." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_b1.log 2>&1
```

## S25-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S25-contracts/S25-R1_review.md' \
     crush run "You are worker S25-R1, the mandatory reviewer of wave S25 (brief .agents/gen/slices/S25-contracts/S25_BRIEF.md; diff findings against its section 5 extract - 14 section 2/6 is law - never against B1's report). Grade A1-A7 first, re-measuring yourself on scratch stores (W8's byte-identical replay, seeded boards): the seeded board shape (6 rows, faction ties), each reward row's arithmetic incl. the demand bias and Known's +5 percent, the gates (Shunned/Outlaw empty, Champion's standing-order row, max-3), the escrow lifecycle end to end incl. the double-completion probe paying once and the 100 CR cancel, and a full escort run both outcomes (win pays at the destination; loss reads -5 standing and no payout) with the ambush firing at the corridor midpoint. Diff moved gate rows against section 8's list; an unlisted row moved or a pinned value that moved is HIGH. A reward number not in 14 section 2 is HIGH. Update docs/CONTRACTS.md section 9/10 at the next free rows read at write time. Write slices/S25-contracts/S25-R1_review.md (REVIEW template, 150 lines max), findings S25-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_r1.log 2>&1
```

## S25-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S25-contracts/' \
     crush run "You are worker S25-F1, the fixer of wave S25 (brief .agents/gen/slices/S25-contracts/S25_BRIEF.md; review .agents/gen/slices/S25-contracts/S25-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S25-contracts/S25-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s25_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 31 only — S25 contracts board. Brief: .agents/gen/slices/S25-contracts/S25_BRIEF.md. Prompts: .agents/gen/slices/S25-contracts/S25_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 32. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s25_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
