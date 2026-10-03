# S28_prompts.md — dispatch lines (coder lane; run in the brief's order)

Models (owner, 2026-10-03): B1/F1 = `hyper/qwen3.8-flash` @ high; R1 =
`hyper/glm-5.3-flash` @ high. Launch with `run_in_background: true` and
**wait on each** (`job_output`, `wait: true`); a wedged worker is killed
with SIGKILL (wrapper AND inner pid) and re-dispatched; re-check `git
status` and the report file after any kill. Bound every game run with
`--quit-after`; redirect probe output to logs you read.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s28_start \
  && git tag s28_start
```

The gate (run it twice, fresh scratch; `$GODOT_CONSOLE` resolves from
crushrc — `~/.local/bin/godot` on this host, `godot` on PATH works too):

```bash
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
```

## S28-B1 — the chrome quick-fix wave (A1–A16)

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S28-station-chrome/' \
     crush run "You are worker S28-B1, the coder of wave S28 (station chrome quick fixes). Read .agents/gen/slices/S28-station-chrome/S28_BRIEF.md end to end - its section 4's four rules bind every change - then SLICE.md, then the law: docs/design/UI_SPEC.md section 8 (P1-P3), docs/design/STATION_HUB.md section 16 P6, and UI_SPEC section 3.10 A5.1-A5.4. SCOPE GUARD: touch only the panels S29 does not rewrite - refinery, exchange, auction, the LAUNCH panel, the station shell, settings, menus. The armory, fitting, shipyard and repairs bodies are untouchable (S29 rewrites them); the only armory/shipyard-adjacent change allowed is none. Implement the brief's A1-A16 exactly: A1 the inspector band clears on module switch (STATION_HUB 16 P6's S28 half - the shell clears and re-anchors the band on every module switch and on unhover-with-no-selection, through the existing inspector signal, station.tscn:214 and station.gd:150-151); A2 CONTROLS bindings deconflicted - one binding per action per key, Q no longer triple-bound, E no longer double, TURN LEFT and TURN RIGHT gain defaults or fold behind an advanced row (pick one route, disclose it); A3 the LAUNCH confirm strip shows arm and confirm copy, never the raw NO_DAMAGE_REPORT token - the Repairs reason token API stays; A4 shield single source - the shipyard comparison and the launch briefing read one stat, disclose which figure won and why; A5 plural grammar via a count-aware helper; A6 dev-speak strings become player copy or leave player panels; A7 DevTuningMenu gated to debug builds only (OS.is_debug_build, game/game.gd:39 preload) so release builds never instantiate it; A8 credits box fixed width, no reflow on balance change; A9 integer origins - floor row and content origins after the 105 percent UI scale; A10 SELL ALL RAW disables at zero raw stacks; A11 the exchange stepper defaults to 1 and the primary button carries the quantity; A12 the holdings table gains HELD, CAP and VALUE headers; A13 the auction shelf tag reads the live count in the 5 OF 20 ON SHELF RESTOCK 20:00 form; A14 the quit dialog gets state-neutral copy on the top-level menu; A15 the splash progress line one step brighter; A16 UI_SPEC section 8 P1-P3 on the surviving panels - every action button on the two 360x56 Pressables tokens or the 96x32 inline chip, action clusters at the P2 placement (HBox at the foot of the action column, 16 px gutter, primary rightmost), and the one focus language (the 1 px accent_danger_bright ring from section 6) everywhere including settings. Containers and anchors only, never coordinates; no new art, no new hue; no doc edits. Run the gate twice on fresh scratch and record both [SUMMARY] lines; zero failures is the law. Disclose every moved test row with its suite and line - the brief's section 8 names the expected movers (test_p1_repairs, test_p2b_services, test_s5_ammo_cargo, test_s11_inspector, test_s3_auction, test_s13_devmenu, plus any suite pinning a rewritten string). Report slices/S28-station-chrome/S28-B1_report.md (REPORT template, 120 lines max) answering A1-A16 each with a cite." \
     -m hyper/qwen3.8-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_b1.log 2>&1
```

## S28-R1 — review

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S28-station-chrome/S28-R1_review.md' \
     crush run "You are worker S28-R1, the reviewer of wave S28 (brief .agents/gen/slices/S28-station-chrome/S28_BRIEF.md; review against the brief's section 5 extract, UI_SPEC section 8, STATION_HUB section 16 P6 and A5.1-A5.4 - never against B1's report). Grade A1-A16 first: each fix really lands and really follows its law (a coordinate layout is HIGH; a button off the two tokens is HIGH; a touched armory, fitting, shipyard or repairs body file is HIGH - S29 owns them); the inspector clear covers every module switch and unhover path; the bindings really deconflict Q and E and give TURN LEFT and TURN RIGHT a lawful route; the shield reads one source with the winning figure disclosed; DevTuningMenu never instantiates in release; the gate ran twice with zero failures (re-run it yourself once on fresh scratch and record the [SUMMARY]); every moved test row is disclosed with suite and line - an undisclosed moved row is MED; no file outside the declared set moved (docs and assets: untouched, HIGH). Write slices/S28-station-chrome/S28-R1_review.md (REVIEW template, 150 lines max), findings S28-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix B1's deliverables." \
     -m hyper/glm-5.3-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s28_r1.log 2>&1
```

## S28-F1 — fixer (only if the review leaves HIGH or MED)

Same command shape as B1 with the worker id S28-F1, the review's finding
list pasted in, `-m hyper/qwen3.8-flash --reasoning-effort high`, report
appended as a fixer note to `S28-B1_report.md`. Gate twice again.

Never end the session while a worker is in flight; read each worker's
report file when its process exits (the logs are narration only).
