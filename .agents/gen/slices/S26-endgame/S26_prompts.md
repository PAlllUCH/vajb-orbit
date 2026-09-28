# S26_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` on `--reasoning-effort max`.
Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s26_start \
  && git tag s26_start
```

## S26-B1 — bosses, arenas, insurance, vaults (A1–A7)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S26-endgame/S26-B1_report.md' \
     crush run "You are worker S26-B1 on the Vajb Orbit workspace, wave S26 (endgame: bosses, arenas, insurance, vaults). Read .agents/gen/slices/S26-endgame/S26_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md. Task: land A1-A7 exactly against docs/gameplay/14_station_services.md sections 3/4/5 and 06 section 3.4 (the pin - invent nothing outside R-S26-1 and the E2 roam rows): The Boneyard and The Pyre as lit barricaded ring zones with nav pylons (A1), the arena contract loop (Expedition seam from slices/S25-contracts/S25-B1_report.md flips live: accept at the faction desk, 60 s entry window, fight, payout at return win or lose, one run per boss per 20-minute clock, last-hit kill credit only) (A2), the bosses live at the R-S26-1 hull rows with 15k + magic roll / 40k + guaranteed rare and The Maw roaming S7 at the E2 rows rolling 06 section 3.4 exactly incl. the 1025 CR floor (A3), death persistence - the wreck and its window survive the death-to-respawn route and the player respawns docked at the last station visited (A4), insurance per section 3 (premiums charged at launch, one-death policy, the verbatim payout flow, Champion x0.8 via S24's hook, no Choir insurance, the mercy clause once per profile) (A5), vaults per section 4 (one per station, tiers 500/1200/2400, Meridian 40-unit at +25 percent, contents persistent and excluded from launch cargo, u_vault adds +20 everywhere) (A6), and the summary table (A7). Boss and arena visuals use only shipped renders and existing scene parts (no art). Docs read-only. New suite tests/test_s26_endgame.gd (one row per AC); headless gate twice on fresh scratch XDG_DATA_HOME stores, both [SUMMARY] lines recorded. Report slices/S26-endgame/S26-B1_report.md (REPORT template, 120 lines max) answering A1-A7 with cites." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_b1.log 2>&1
```

## S26-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S26-endgame/S26-R1_review.md' \
     crush run "You are worker S26-R1, the mandatory reviewer of wave S26 (brief .agents/gen/slices/S26-endgame/S26_BRIEF.md; diff findings against its section 5 extract - 14 sections 3/4/5 and 06 section 3.4 are law - never against B1's report). Grade A1-A7 first, re-measuring yourself on scratch stores (W8's byte-identical replay, seeded rolls): both arena rings and the full contract loop both outcomes, the cooldown and last-hit credit (a drone kill must not pay), each boss's fit against R-S26-1 and its reward row (the magic/rare rolls per 15 section 5), The Maw's table over 20k seeded rolls (EV within the suite's bound, the 1025 CR floor proven), the wreck surviving the death route with a post-respawn pickup, the insurance premium table and the one-death and mercy-once semantics (probe a second total loss), and the vault tiers/Meridian/u_vault arithmetic plus the not-on-launch-cargo rule. Diff moved gate rows against section 8's list; an unlisted row moved or a pinned value that moved is HIGH. A reward or premium not in the pin is HIGH. Update docs/CONTRACTS.md section 9/10 at the next free rows read at write time. Write slices/S26-endgame/S26-R1_review.md (REVIEW template, 150 lines max), findings S26-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_r1.log 2>&1
```

## S26-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S26-endgame/' \
     crush run "You are worker S26-F1, the fixer of wave S26 (brief .agents/gen/slices/S26-endgame/S26_BRIEF.md; review .agents/gen/slices/S26-endgame/S26-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S26-endgame/S26-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 32 only — S26 bosses, arenas, insurance, vaults. Brief: .agents/gen/slices/S26-endgame/S26_BRIEF.md. Prompts: .agents/gen/slices/S26-endgame/S26_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 33. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s26_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
