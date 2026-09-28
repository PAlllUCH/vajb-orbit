# S21_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort max`. Run order **B1 → B2 → B3 → R1 → (F1
only on HIGH/MED)** — three builders since the 2026-09-28 amendment
(`S21_BRIEF.md` §7): one region each, strictly sequential, each starting from
its predecessor's tree. `$VAJB_WORKSPACE` resolves from `crushrc`. Every
`crush run` is launched with `run_in_background: true` and **waited on**
(`job_output`, `wait: true`) before the next step or the end of the session. If
a worker wedges (0 sockets, frozen `/proc/<pid>/io`, ~0 CPU-sec), kill it with
python SIGKILL — the wrapper AND the inner `bin/crush run` pid — then
re-dispatch; re-check `git status` and the report file after any kill.

**Before the first dispatch** (the five-piece and the amendment are committed;
this takes the baseline and the evidence tag):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s21_start \
  && git tag s21_start
```

## S21-B1 — the hull and the flight scene (A1, A2, A3, A4b, A9a, A9b)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S21-stability-fixes/S21-B1_report.md' \
     crush run "You are worker S21-B1, the first of three builders on the Vajb Orbit workspace, wave S21 - stability and playtest fixes. Read .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md section 7. Your acceptance subset is A1, A2, A3, A4b, A9a, A9b; the regions you own and nobody else edits are game/game.gd, game/player_ship.gd, game/npc_ship.gd, game/pickup.gd and game/gate.gd. Land: A1, the real death state - from died until the respawn route lands the hull takes no input, applies no force or torque and its contact monitor charges nothing, and the explosion then wreck order is exactly the engine spec section 7 order, proven by a probe over the death frames; A2, the five-minute wreck window surviving a sector transition and the respawn route with DROP_WINDOW 300 s carried through the Pickup.setup lifetime seam, proven with a fake-clock probe; A3, ship-vs-ship contacts resolving, with engine spec section 2.1 row 15 charged to both sides exactly once per impact - the heavier side, tie broken by the initiator, charges both halves so the pair can never double-charge - and rocks and other bodies unchanged; A4b, the stale _transit_destination cleared in _exit_tree or when the route target is not the game scene, proven by arming the flag and interrupting the crossing; A9a, the heat-decay accumulator made static beside that flag so a scene rebuild keeps the minute in progress; A9b, cancel_jump called on zone exit, damage and death, plus the GATE REFUSED - NOT ENOUGH CR rung in the same prompt ladder that carries the Outlaw line. Everything else restores the behaviour the cited docs already pin. Do not touch game/damage.gd, any doc, or another builder's region - if you find a defect outside your regions, report it and leave it. Create tests/test_s21_stability.gd with one row per item of your subset, run the headless gate once on a fresh scratch XDG_DATA_HOME store and record the exact [SUMMARY] line. Report .agents/gen/slices/S21-stability-fixes/S21-B1_report.md from the REPORT template, 120 lines max, answering A1, A2, A3, A4b, A9a and A9b item by item with file:line cites, the gate line, and every new const with its value and reversal." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s21_b1.log 2>&1
```

## S21-B2 — the account and the station (A4a, A5, A6, A7, A8)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S21-stability-fixes/S21-B2_report.md' \
     crush run "You are worker S21-B2, the second builder on the Vajb Orbit workspace, wave S21 - stability and playtest fixes. Read .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md section 7. Your acceptance subset is A4a, A5, A6, A7, A8; the regions you own and nobody else edits are ui/screens/station.gd, ui/station/auction_panel.gd, ui/station/launch_panel.gd, ui/station/outfitting_panel.gd, autoload/player_profile.gd, game/exchange.gd and the three engine2 suites tests/test_engine2_dock.gd, tests/test_engine2_fixes.gd and tests/test_engine2_wiring.gd. S21-B1 has already landed the death state, the wreck window, crash damage, the route flag, the heat accumulator and the gate cancel in game/game.gd, player_ship.gd, npc_ship.gd, pickup.gd and gate.gd - read their report at .agents/gen/slices/S21-stability-fixes/S21-B1_report.md before you start and do not re-edit those regions. Land: A4a, booting the station writes nothing to user:// - the market normalises at dock and the AUCTION shelf rolls at pane switch rather than at build - proven by a profile md5 before and after a boot-only run on a scratch store; A5, the four hermetic fixtures build their own fit and read slot order from _state.weapons so the gate reports one count on live and scratch user://; A6, one bag accessor law - either module_count sums instances or every caller reads instances_of, pick one, state it in the report and keep test_p2b1_outfitting_panel.gd green - with a fitted instance whose bag record is gone still rendering one battery row through the _base_id fallback; A7, R-S21-1 and R-S21-2 as the docs 01 block writes them, ammunition sales paying roundi 0.02 times gross with no 10 CR floor and launch auto-load splitting the last pack unit's round remainder, plus LAUNCH's summary reading the hold's units and counting the fit's real weapons; A8, R-S21-3, the owned hull row rendering disabled with an OWNED plate. The PROPOSED rows in docs 01 and 10's 2026-09-27 blocks are the only new values; everything else restores the cited pinned behaviour. Do not touch game/damage.gd, any doc, or another builder's region - if you find a defect outside your regions, report it and leave it. Append one row per item of your subset to tests/test_s21_stability.gd, run the headless gate once on a fresh scratch XDG_DATA_HOME store and record the exact [SUMMARY] line. Report .agents/gen/slices/S21-stability-fixes/S21-B2_report.md from the REPORT template, 120 lines max, answering A4a, A5, A6, A7 and A8 item by item with file:line cites, the accessor law you chose, the gate line, and every new const with its value and reversal." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s21_b2.log 2>&1
```

## S21-B3 — world bodies, pane copy and the harness (A9c, A9d, A10, A11)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S21-stability-fixes/S21-B3_report.md' \
     crush run "You are worker S21-B3, the third and last builder on the Vajb Orbit workspace, wave S21 - stability and playtest fixes. Read .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md section 7, then the reports of S21-B1 and S21-B2 in the same folder so you know what already moved. Your acceptance subset is A9c, A9d, A10, A11; the regions you own and nobody else edits are game/asteroid_field.gd, game/asteroid.gd, ui/station/armory_panel.gd, tests/test_weapon_fx_f4.gd and tests/test_s19_quadrants.gd. Land: A9c, AsteroidField.respawn threading its now argument into the yield roll that currently reads Clock.now directly, and Asteroid.setup clearing _cleave_child with its other resets; A9d, the armory between-rack move line reading the moved barrel's name before the record write so it can never print an empty name; A10, the test_weapon_fx_f4 held-beam row re-ordered so its final assertion runs on a live rig - prove the row executes with one temporary value flip and then revert the flip - plus one assert row in test_s19_quadrants.gd pinning PlayerState.CTX_DIRECTION equal to Damage.CTX_DIRECTION; A11, the summary table of every new const in the wave with its value and its reversal path, the proof that game/damage.gd is byte-identical - grep its hash - and the proof that no gate row outside the brief's section 8 list moved. Then run the whole tests/test_s21_stability.gd suite plus the full headless gate once on a fresh scratch XDG_DATA_HOME store and record the exact [SUMMARY] line. Do not touch game/damage.gd, any doc, or another builder's region - if you find a defect outside your regions, report it and leave it. Report .agents/gen/slices/S21-stability-fixes/S21-B3_report.md from the REPORT template, 120 lines max, answering A9c, A9d, A10 and A11 item by item with file:line cites, the value-flip evidence, the whole-suite result and the gate line." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s21_b3.log 2>&1
```

## S21-R1 — mandatory review (after B1, B2 and B3 report)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S21-stability-fixes/S21-R1_review.md' \
     crush run "You are worker S21-R1, the mandatory reviewer of wave S21 (brief .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md; diff findings against the brief's section 5 spec extract and the 2026-09-27 P3 doc blocks, never against the three builders' reports, which are .agents/gen/slices/S21-stability-fixes/S21-B1_report.md, S21-B2_report.md and S21-B3_report.md). Grade the acceptance list A1-A11 first, re-measuring every item yourself (seeded probes on scratch stores, W8's byte-identical replay method): the death-frame inertness, the 300 s wreck window across a transition, exactly-once crash damage with no double-charge, profile md5 before and after a boot-only run, one gate count on live and scratch user://, the bag accessor's instance and stacked cases, the R-S21 rows' arithmetic (a 2 CR ammo sale, a 295-round reload), the world-sim fixes, and the value-flip proof for the f4 row. Diff the moved gate rows against section 8's list - an unlisted row moved is HIGH, and any pinned number that moved is HIGH. Verify damage.gd is byte-identical (grep its hash). Update docs/CONTRACTS.md section 9 (gate figure) and section 10 (changelog) at the next free rows read at write time. Write .agents/gen/slices/S21-stability-fixes/S21-R1_review.md (REVIEW template, 150 lines max), findings S21-B1/F##, S21-B2/F## and S21-B3/F## with tier and one evidence line each, LOW rows appended at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only, all under scratch XDG_DATA_HOME (L229)." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s21_r1.log 2>&1
```

## S21-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S21-stability-fixes/' \
     crush run "You are worker S21-F1, the fixer of wave S21 (brief .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md; review .agents/gen/slices/S21-stability-fixes/S21-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed; game/damage.gd stays byte-identical. Re-run the gate twice on fresh scratch stores and report .agents/gen/slices/S21-stability-fixes/S21-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s21_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 27 only — S21 stability & playtest fixes. Brief: .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md. Prompts: .agents/gen/slices/S21-stability-fixes/S21_prompts.md. Snapshot + commit before the first dispatch, run B1 → B2 → B3 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 28. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s21_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builders' per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
