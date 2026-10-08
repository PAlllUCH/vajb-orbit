# S26_prompts.md — dispatch lines (one per worker; run in the brief's order)

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

**Before the first dispatch** (the five-piece is committed; S25 must have
closed — its report is the Expedition seam's shipped shape):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s26_start \
  && git tag s26_start
```

## S26-B1 — bosses, arenas, insurance, vaults (A1–A8)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/npc_registry.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/game.gd,vajb-orbit/game/contract_registry.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/insurance_panel.gd,vajb-orbit/ui/station/insurance_panel.gd.uid,vajb-orbit/ui/station/insurance_panel.tscn,vajb-orbit/ui/station/vaults_panel.gd,vajb-orbit/ui/station/vaults_panel.gd.uid,vajb-orbit/ui/station/vaults_panel.tscn,vajb-orbit/tests/test_s26_endgame.gd,.agents/gen/slices/S26-endgame/S26-B1_report.md' \
     crush run "You are worker S26-B1 on the Vajb Orbit workspace, wave S26 endgame - bosses, arenas, insurance, vaults - builder. Read .agents/gen/slices/S26-endgame/S26_BRIEF.md end to end - its section 4's six rules bind every line you write - then SLICE.md, then the law in the brief's section 1 order: docs/gameplay/14_station_services.md sections 3, 4 and 5 by range plus the 2026-10-08 S28 block (the boss payouts 6000 and 12000 per M10 and the premium law per M14), 06_loot_drops.md section 3.4 (the Maw table), 08_ship_classes.md's 2026-09-27 P3 block (R-S26-1), docs/design/STATION_HUB.md sections 15.3 and 15.4 (the INSURANCE and VAULTS panel specs) and section 5.2, docs/design/UI_SPEC.md sections 12 to 15 and STATION_HUB.md sections 19 to 21 by range (shell v2), slices/S25-contracts/S25-B1_report.md (the Expedition seam you flip live - if S25 has not closed, its brief section 6 A1 is the contract; re-verify the shipped shape first), docs/CODE_MAP.md by range. Task: land A1 to A8 exactly. A1: The Boneyard in S3 and The Pyre in S6 as lit barricaded ring zones with nav pylons visible at distance, built from existing scene parts, no art. A2: the arena contract loop - S25's Expedition seam row flips live (the U7 staged row un-greys), accept at the faction desk opens the arena with a 60 second entry window, the boss fight runs, payout lands at return-to-station win or lose, one run per boss per 20-minute clock per profile, kill credit is the player's last hit only - a drone or escort kill must not pay. A3: the bosses live at R-S26-1's hull rows - Boneyard gunship-tier times 2.5 with 5 weapons, Pyre frigate-tier times 2.5 with 4 weapons - paying 6000 CR plus the magic module roll and 12000 CR plus the guaranteed rare per S28's block, and The Maw roaming S7 at the E2 rows rolling 06 section 3.4 exactly over 20k seeded rolls with the 1025 CR floor proven. A4: death persistence - the wreck and its cargo window survive the death-to-respawn route (a probe collects from a pre-death wreck after respawn) and the player respawns docked at the last station visited. A5: insurance - the premium is 1.5 percent of the hull's list per class in the 135 to 1080 band per M14, charged at launch, covers exactly one loss, the payout flow verbatim (base hull of the tier's cheapest, hull and fit paid into the dock), Champion times 0.8 via station_registry.gd's insurance_multiplier seam, Choir stations sell none, the mercy clause reissues a bare Fighter exactly once per profile and a second total loss does not. A6: vaults - one per station, 20 units base, tiers 500, 1200, 2400, Meridian 40-unit at plus 25 percent, free deposits and withdrawals, contents persistent per station and excluded from launch cargo, u_vault adds plus 20 to every vault. A7: the INSURANCE and VAULTS panels per STATION_HUB sections 15.3 and 15.4 wired into the SERVICES deck beside S25's contracts strip in ui/screens/station.gd, shell-v2 idioms, no existing panel's layout moved. A8: every moved value tabled with reversal and tick id - the boss re-pricing cites M10, the premium cites M14. The seams at player_profile.gd lines 1926, 1938, 1949 and station_registry.gd line 423 are read-only - never redefine them. Docs read-only. New suite vajb-orbit/tests/test_s26_endgame.gd with one row per acceptance item; run the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S26-endgame/S26-B1_report.md from the REPORT template, 120 lines maximum, answering A1 to A8 with cites and tabling every moved value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_b1.log 2>&1
```

## S26-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S26-endgame/S26-R1_review.md' \
     crush run "You are worker S26-R1, the mandatory reviewer of wave S26 (brief .agents/gen/slices/S26-endgame/S26_BRIEF.md; diff findings against its section 5 extract - 14 sections 3, 4 and 5 plus the 2026-10-08 S28 block and 06 section 3.4 are law - never against B1's report). Grade A1 to A8 first, re-measuring yourself on scratch stores (W8's byte-identical replay, seeded rolls): both arena rings and the full contract loop both outcomes, the cooldown and last-hit credit (a drone kill must not pay), each boss's fit against R-S26-1 and its reward row - 6000 plus the magic roll and 12000 plus the guaranteed rare per M10, never the retired 15k/40k, The Maw's table over 20k seeded rolls (EV within the suite's bound, the 1025 CR floor proven), the wreck surviving the death route with a post-respawn pickup, the insurance premium at 1.5 percent of list per the 135 to 1080 band per M14 with the one-death and mercy-once semantics (probe a second total loss) and Champion times 0.8 through the seam, and the vault tiers, Meridian arithmetic, u_vault's plus-20 and the not-on-launch-cargo rule. Check the deck: the INSURANCE and VAULTS panels against STATION_HUB sections 15.3 and 15.4, wired beside S25's contracts strip. Diff moved gate rows against the brief's section 8 list; an unlisted row moved or a pinned value that moved is HIGH. A reward or premium not in the pin is HIGH. Update docs/CONTRACTS.md section 9 and 10 at the next free rows read at write time. Write slices/S26-endgame/S26-R1_review.md (REVIEW template, 150 lines max), findings S26-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_r1.log 2>&1
```

## S26-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/npc_registry.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/game.gd,vajb-orbit/game/contract_registry.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/insurance_panel.gd,vajb-orbit/ui/station/insurance_panel.gd.uid,vajb-orbit/ui/station/insurance_panel.tscn,vajb-orbit/ui/station/vaults_panel.gd,vajb-orbit/ui/station/vaults_panel.gd.uid,vajb-orbit/ui/station/vaults_panel.tscn,vajb-orbit/tests/test_s26_endgame.gd,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S26-endgame/' \
     crush run "You are worker S26-F1, the fixer of wave S26 (brief .agents/gen/slices/S26-endgame/S26_BRIEF.md - read it for the pinned law; review .agents/gen/slices/S26-endgame/S26-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S26-endgame/S26-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s26_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 32 only — S26 bosses, arenas, insurance, vaults. Brief: .agents/gen/slices/S26-endgame/S26_BRIEF.md. Prompts: .agents/gen/slices/S26-endgame/S26_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 33. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s26_start, build_code_map.py, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
