# S22_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` on `--reasoning-effort max`.
Run order **B1 → B2 → B3 → R1 → (F1 only on HIGH/MED)**, strictly sequential —
the three builders share `hud.gd`, `weapons.gd`, `projectile.gd` and
`npc_ship.gd`, so **two of them must never hold a file at once**. Every
`crush run` is launched with `run_in_background: true` and **waited on**
(`job_output`, `wait: true`).
If a worker wedges (0 sockets, frozen I/O, ~0 CPU-sec), kill it with python
SIGKILL — wrapper AND inner `bin/crush run` pid — then re-dispatch; re-check
`git status` and the report file after any kill. Bound every Godot run with
`--quit-after` (an unbounded `--script` run wedged a worker for 28 minutes on
2026-09-29).

**Before the first dispatch** (the amended five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s22_start \
  && git tag s22_start
```

## S22-B1 — the feedback seams (A1–A4, A8, A12, A13)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S22-feel-and-juice/S22-B1_report.md' \
     crush run "You are worker S22-B1 on the Vajb Orbit workspace, wave S22 (feel, juice and balance) - the FIRST of three builders. Read .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md end to end (section 4's six rules bind every line, and section 6's A4/A8/A13 are VERIFY-ONLY: measure them, never rewrite them), then SLICE.md and slices/D15-flight-feedback/D15-A1_report.md (the owner-ticked sheet - section 11 of the brief is the ruling of record). Task, A1-A4 + A8 + A12 + A13: (A1) add one hit_landed(target, amount) signal on the delivery seam (game/weapons.gd _deliver, components publish, HUD consumes) so the marker at ui/hud/hud.gd:581 fires for ANY hull, and retire the marked-target pool-drop poll in game/game.gd (_target_pools_seen); (A2) each contact handler (player_ship.gd ~1147-1210, npc_ship.gd ~546-600) plays sfx_impact_hull / sfx_impact_rock and spawns one contact spark at the contact point; (A3) the muzzle flash anchors at the nose per tick T-feel-4 (FLASH_MUZZLE_PX / ShipFit hardpoints) while shots still spawn at the pinned point; (A12) a tool-module slot's HUD label reads its ModuleCatalog name (hud.gd _refresh_weapon); then the verify rows: (A4) the mining chip burst already ships at mining_laser.gd:214-225 and (A8) the low-hull arcs already run at the ticked random 1.6-2.6 s cadence (player_ship.gd:207-213, 1787-1810) and (A13) every FX-2 pin already matches projectile.gd - for each, run a probe and report the measured value with a file:line cite; a value found OFF its ticked value is a bucket-2 report, not a licence to edit. Feedback stays cosmetic (rule 1): no gameplay number moves. New suite tests/test_s22_feedback.gd (one row per AC); headless gate twice on fresh scratch XDG_DATA_HOME stores, record both [SUMMARY] lines. Report slices/S22-feel-and-juice/S22-B1_report.md (REPORT template, 120 lines max) answering A1-A4/A8/A12/A13 item by item with cites, naming the owner rulings implemented, and listing every deviation." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_b1.log 2>&1
```

## S22-B2 — the HUD feed and the audio pass (A5–A7, A14)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/assets/audio/,vajb-orbit/tests/,.agents/gen/slices/S22-feel-and-juice/S22-B2_report.md' \
     crush run "You are worker S22-B2 on the Vajb Orbit workspace, wave S22 - the SECOND of three builders, running after S22-B1 (its report is slices/S22-feel-and-juice/S22-B1_report.md; B1 owns the hit marker, the ram/contact feedback, the muzzle anchor and the HUD ammo label - do not re-open them). Read .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md end to end (section 4's six rules bind every line), then SLICE.md, slices/D15-flight-feedback/D15-A1_report.md (the ticked sheet) and docs/design/AUDIO_SPEC.md section 4.1 + the section 8.6 amendment (AUDIO-1/2/3, owner-ticked). Task, A5-A7 + A14: (A5) ui/hud/hud.gd's _push_status pushes the four real pools through ui/hud/ship_status_screen.gd:843 set_quadrants every status update, so a breached quadrant reads its real pool in flight (the repairs panel's fallback stays disclosed); (A6) AUDIO_SPEC section 4.1's EXACTLY three anti-flam rules enforce in play_pool (autoload/audio_manager.gd:352) - 30 ms minimum between triggers of one cue, per-pool caps weapons 4 / impacts 6 / mining 1 / UI 2 with excess dropped-not-queued, and skip the last used variant when N > 2 - no fourth rule; (A7) source ONE CC0 mechanical deploy cue via the assetmcp tools (search, licence-check, download; no CC-BY/OGA-BY), save it as vajb-orbit/assets/audio/sfx/sfx_weapon_mine_drop_01.ogg (<= 0.5 s, take 2-3 if the pack carries them), add its row to vajb-orbit/assets/audio/generation_log_audio.md and the project's CREDITS/manifest, and wire it in game/weapons.gd FIRE_CUES as the mine family's release cue (the detonation keeps sfx_weapon_explosion); (A14) drop sfx_weapon_laser_04 from CUE_POOLS[&'sfx_weapon_laser'][&'takes'] (the round-robin runs 01-03, skip-last still applies at N = 3). New suite tests/test_s22_audio.gd (seeded probes: a 20 ms double-trigger, a 5th weapon voice refused, the take list after the drop) and CUE_POOLS coexistence: leave B1's and B3's rows alone. Headless gate twice on fresh scratch XDG_DATA_HOME stores, record both [SUMMARY] lines. Report slices/S22-feel-and-juice/S22-B2_report.md (REPORT template, 120 lines max) answering A5-A7 + A14 item by item with cites, stating the sourced cue's licence, source URL and measured duration, and listing every deviation. Note for you: the S19 byte-seal row in tests/test_s19_quadrants.gd is RED by design from S22-B1 (brief amendment 6) because that file's pins cover weapons.gd and npc_ship.gd - do not edit the yardstick, S22-B3 re-pins it from the finished tree." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_b2.log 2>&1
```

## S22-B3 — the flight and balance rows (A9–A11)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S22-feel-and-juice/S22-B3_report.md' \
     crush run "You are worker S22-B3 on the Vajb Orbit workspace, wave S22 - the THIRD and last builder, running after S22-B1 and S22-B2 (their reports are beside yours in slices/S22-feel-and-juice/). Read .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md end to end (section 4's six rules bind every line; rule 4: every feel row ships at its TICKED value, section 11 is the ruling of record), then SLICE.md, slices/D15-flight-feedback/D15-A1_report.md and docs/gameplay/18_engine_spec.md section 13's new Rocket fuze row. Task, A9-A11: (A9) the ticked flight rows - SEEKER_FUSE := 80.0 u proxy detonation AND SEEKER_FUSE_S := 6.0 s flight fuze in game/projectile.gd (ticks T-feel-1/1b; the 409 u minimum turn radius is why the proxy alone cannot catch an abeam lock), plus the NPC midline drag mirrored into game/npc_ship.gd as its own _step_lateral_drag twin (tick T-feel-2: this DELIBERATELY moves one NPC flight number, the skid settling ~2x faster; CONTRACTS section 14 carries the disclosure); T-feel-3's ramp and CONTRACTS section 22's T3 strike are already landed in docs - verify and cite, do not re-edit; (A10) Repairs.fee()/repair() (game/repairs.gd:62-120) resolve the same ShipFit.resolve hull_max/shield_max pair the panes print (R-S22-1, tick M4) so the fee and the pane rows read ONE figure; (A11) R-S22-2's PROPORTIONAL spill in game/player_state.gd:337 _charge_quadrant - the remainder re-offers proportional to remaining capacity until landed or every pool is full, so a 400 hit on [200,100,0,0] lands 300 and kills while hull == sum(pools) holds exactly (R-S22-3's stance and R-S22-4's per-cell magazine disposition are DISPOSITIONS: table them, code nothing). damage.gd stays byte-identical. New suite tests/test_s22_balance.gd (one row per AC, including the 400-hit spill arithmetic and the fuse's two thresholds); headless gate twice on fresh scratch XDG_DATA_HOME stores, record both [SUMMARY] lines. Report slices/S22-feel-and-juice/S22-B3_report.md (REPORT template, 120 lines max) answering A9-A11 item by item with cites, a row-by-row table of each feel value as shipped against its ticked value with its reversal, every deviation, and the re-pinned S19 byte-seal strings: tests/test_s19_quadrants.gd:94-105's weapons.gd and npc_ship.gd hashes must be re-pinned ONCE from the finished tree, with the sha256sum output quoted in your report, because you are the wave's LAST editor of those files (brief amendment 6, the S21 rule - the row is deliberately red until you do it, and it must be GREEN when you finish)." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_b3.log 2>&1
```

## S22-R1 — mandatory review (after all three builders report)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S22-feel-and-juice/S22-R1_review.md' \
     crush run "You are worker S22-R1, the mandatory reviewer of wave S22 (brief .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md; the builders' reports S22-B1/B2/B3_report.md are claims, never evidence, and slices/D15-flight-feedback/D15-A1_report.md is the owner-ticked sheet the wave implements). Grade A1-A14 first, RE-MEASURING yourself on scratch stores (schedule every Godot run with --quit-after): hit_landed fires on every family incl. NPC hits and any hull marks (with the old pool-drop poll gone); the contact cue + spark geometry at the contact point; the muzzle offset at the nose while the shot's spawn is unmoved; the mining burst (A4) and the arc cadence (A8) and every FX-2 pin (A13) MEASURED against its ticked value - these three are verify-only rows, so report the shipped number and grade the claim's equality, not a change; the quadrant feed through a real breach; the three anti-flam rules at their exact thresholds (20 ms double-trigger, a 5th weapon voice); the mine cue's CC0 licence, source and duration rows; the take list after AUDIO-3's drop; each A9/A11 feel value as shipped against its tick (a value that moved WITHOUT a tick is HIGH); R-S22-1's figure equality across the fee and both pane rows; the 400-hit spill arithmetic with hull == sum(pools); the module-name HUD label. Verify damage.gd byte-identical (hash) and every pre-flight doc edit (CONTRACTS section 22's struck T3, section 23.5's ramp row, section 14's NPC-brake disclosure, 18 section 13's Rocket fuze row) intact. Diff moved gate rows against section 8's list; an unlisted row moved is HIGH, but note section 8 EXPECTS the NPC skid row (T-feel-2), one test_s19_quadrants spill row and one test_engine2_wiring marker row to move, and expects the S19 byte-seal to be GREEN again (B3 re-pinned it - verify the re-pin equals the finished tree's hashes). Update CONTRACTS section 9's gate figure and section 10's changelog at the next free rows read at write time; LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Orchestrator notes: a benign _power_arithmetic WARNING with a backtrace at headless_runner.gd:163 prints twice in every run (scratch and live alike - not a live coupling, not your finding), and the three new suites are the only expected gate growth. Never fix code. Write slices/S22-feel-and-juice/S22-R1_review.md (REVIEW template, 150 lines max), findings S22-Bn/F## with tier and one evidence line each. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_r1.log 2>&1
```

## S22-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/assets/audio/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S22-feel-and-juice/' \
     crush run "You are worker S22-F1, the fixer of wave S22 (brief .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md; review .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed (section 11's ticked values are the owner's and are not yours to move - a finding that asks you to change one is a bucket-2/3 report, not a fix); damage.gd stays byte-identical. Bound every Godot run with --quit-after. Re-run the gate twice on fresh scratch stores and report slices/S22-feel-and-juice/S22-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s22_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 28 only — S22 feel, juice & balance. Brief: .agents/gen/slices/S22-feel-and-juice/S22_BRIEF.md. Prompts: .agents/gen/slices/S22-feel-and-juice/S22_prompts.md. Snapshot + commit before the first dispatch, run B1 → B2 → B3 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 29. Close out per the brief's close-out section (audio reimport, gate re-run, verify_wave.py verify --baseline s22_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, each builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
