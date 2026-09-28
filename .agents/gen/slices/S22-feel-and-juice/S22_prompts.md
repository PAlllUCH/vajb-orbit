# S22_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` on `--reasoning-effort max`.
Run order **B1 → R1 → (F1 only on HIGH/MED)**. Every `crush run` is launched
with `run_in_background: true` and **waited on** (`job_output`, `wait: true`).
If a worker wedges (0 sockets, frozen I/O, ~0 CPU-sec), kill it with python
SIGKILL — wrapper AND inner `bin/crush run` pid — then re-dispatch; re-check
`git status` and the report file after any kill.

**Before the first dispatch** (the five-piece is committed; D15's tick sheet
exists):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s22_start \
  && git tag s22_start
```

## S22-B1 — the feel, juice & balance pass (A1–A12)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/assets/audio/,vajb-orbit/tests/,.agents/gen/slices/S22-feel-and-juice/S22-B1_report.md' \
     crush run "You are worker S22-B1 on the Vajb Orbit workspace, wave S22 (feel, juice and balance). Read .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md and slices/D15-flight-feedback/D15-A1_report.md (the ticked feel rows; where it is silent use the brief's section 11 defaults). Task: land A1-A12 exactly: the hit_landed signal and universal hit marker (A1), ram cue + contact spark (A2), muzzle flash at the nose (A3), the mining chip burst (A4), the HUD's set_quadrants production feed (A5), AUDIO_SPEC section 4.1's three anti-flam rules in play_pool (A6), a CC0 mine_drop cue sourced through assetmcp with manifest + CREDITS rows (A7), the low-hull arc emitter at the ticked interval (A8), the ticked feel rows L25/L39/L103/L182 and CONTRACTS section 22's T3 disposition (A9), R-S22-1's one repair figure (A10), R-S22-2's damage-conserving proportional spill plus R-S22-3/4 dispositions (A11), and the module-name HUD label with the summary table (A12). The named PROPOSED rows in the 2026-09-27 P3 blocks of docs 01 and 09 are the only balance values you may write; feedback stays cosmetic (rule 1). damage.gd and docs/ are read-only. New suite tests/test_s22_feel.gd (one row per AC); headless gate twice on fresh scratch XDG_DATA_HOME stores, record both [SUMMARY] lines. Report slices/S22-feel-and-juice/S22-B1_report.md (REPORT template, 120 lines max) answering A1-A12 item by item with cites and naming the owner rulings implemented." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_b1.log 2>&1
```

## S22-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S22-feel-and-juice/S22-R1_review.md' \
     crush run "You are worker S22-R1, the mandatory reviewer of wave S22 (brief .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md; diff findings against the brief's section 5 extract plus slices/D15-flight-feedback/D15-A1_report.md's ticked rows, never against B1's report). Grade A1-A12 first, re-measuring yourself (seeded probes on scratch stores, W8's byte-identical replay): hit_landed on every family incl. NPC hits, the contact spark and cue, the flash offset, the mining burst, the quadrant feed through a real breach, the three anti-flam rules at their exact thresholds (20 ms double-trigger, a 5th weapon voice), the mine cue's CC0 license rows, the arc interval, each feel row's as-shipped value against its ticked value (a value that moved without a tick is HIGH), R-S22-1's figure equality across both panes, the 400-hit spill arithmetic with hull == sum(pools), and the HUD label. Diff moved gate rows against section 8's list; an unlisted row moved or any pinned number that moved is HIGH. Verify damage.gd byte-identical (hash). Strike CONTRACTS section 22's T3 row if the ticked disposition says so and land the ticked feel values in sections 22/23 (with the section 23.5 wording correction); update section 9/10 at the next free rows read at write time. Write slices/S22-feel-and-juice/S22-R1_review.md (REVIEW template, 150 lines max), findings S22-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_r1.log 2>&1
```

## S22-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/assets/audio/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S22-feel-and-juice/' \
     crush run "You are worker S22-F1, the fixer of wave S22 (brief .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md; review .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed; damage.gd stays byte-identical. Re-run the gate twice on fresh scratch stores and report slices/S22-feel-and-juice/S22-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 28 only — S22 feel, juice & balance. Brief: .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md. Prompts: .agents/gen/slices/S22-feel-and-juice/S22_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 29. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s22_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
