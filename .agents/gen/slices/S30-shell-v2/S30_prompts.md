# S30_prompts.md — dispatch lines (one per worker; run in the brief's order)

Models (owner routing 2026-10-03): code **`hyper/deepseek-v4.1-flash`**, review
**`hyper/glm-5.3-flash`** — the fixer rides its lane's model. Every run at the
provider's max reasoning effort — measured enums (2026-10-04):
`hyper/deepseek-v4.1-flash` = low|high|**xhigh** (use `xhigh`);
`xiaomi/mimo-v2.6-pro` = low|medium|high (use `high`);
`hyper/glm-5.3-flash` accepts `max`. Nothing heavier without asking the owner.
Run order **B1 → B2 → R1 → (F1 only on HIGH/MED)**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched with an inspect-partial-diff instruction;
re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s30_start \
  && git tag s30_start
```

## S30-B1 — the popup layer, the census, the one skeleton (A1–A6)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B1_report.md' \
     crush run "You are worker S30-B1 on the Vajb Orbit workspace, wave S30 (station shell v2 build). Read .agents/gen/slices/S30-shell-v2/S30_BRIEF.md end to end - its section 4's pins and rules bind every line you write - then SLICE.md. Task: land A1-A6 exactly (brief section 5). A1: the N27 hover tooltip and the N28 INSPECT modal to UI_SPEC section 12.2/12.3 anatomy (size-to-content in min 420 / max 720, the viewport clamp rule, the INSPECT hint line), wired to the existing inspect_requested chain (P21) - rows carry the inline INSPECT chip, grid cells route through the cluster chip (N28's amendment note). A2: cure the section 12.5 census ROW BY ROW (all 15 rows, each to its named cure) including shipyard_panel.gd:703-733, the fitting twin at :1469-1491, the grid-rebuild class (shipyard_panel.gd:508-527, armory_panel.gd:2906-2935, fitting_panel.gd:484) and the four tooltip_text writes (armory_panel.gd:1968,2029,3139,3645). A3: the one skeleton on every pane per STATION_HUB section 19's conformance rows (PaneHeader / content split / the section 8 P2 cluster / the shared footer hint). A4: A5.5 held everywhere in ui/ - hover, focus and selection mutate colour, modulate and _draw only. A5: tests - test_s11_inspector.gd retargeted to the popup sinks, plus new rows for tooltip show/hide/delay, modal open/ESC/queue and a hover-never-moves probe (pane geometry equal across a hover). A6: run the headless gate twice on fresh scratch XDG_DATA_HOME stores (res://tests/headless_runner.tscn --quit-after 1200), disclose every moved gate row, and write .agents/gen/slices/S30-shell-v2/S30-B1_report.md (REPORT template, 120 lines max) answering A1-A6 with file:line cites. Docs read-only; project.godot untouched; Tokens only, no new art; motion <= 0.2 s TRANS_CUBIC EASE_OUT, overlays only; any number not derivable from the law ships PROPOSED with a reversal in the report. R-S30-1 and R-S30-2 are your only new pins (the 272 px drawer content box and the first-class map_filters door on player_profile.gd read by map_deck.gd:496-534)." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s30_b1.log 2>&1
```

## S30-B2 — the shell, the TERMINAL drawer, OVERVIEW (A1–A6; after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B2_report.md' \
     crush run "You are worker S30-B2 on the Vajb Orbit workspace, wave S30 (station shell v2 build; B1's popup layer and census are already landed - read its report first). Read .agents/gen/slices/S30-shell-v2/S30_BRIEF.md end to end - its section 4's pins and rules bind every line you write - then SLICE.md. Task: land A1-A6 exactly (brief section 5). A1: the shell re-lay per STATION_HUB section 18 P15 (header = the section 11 N25 TERMINAL button + station identity line + credits housing; body = one pane at full body width; footer status strip) and DELETE the ModuleRail and the Inspector band (station.tscn:214, station.gd:150-151,273-301) per section 18's supersession ledger. A2: the TERMINAL drawer per UI_SPEC section 12.1 + N26 + P16 - 360 px overlay with the 5.2 scrim above it, entry plates on R-S30-1's 272 px content box (x 68..340), 0.18 s in / 0.12 s out TRANS_CUBIC EASE_OUT, the focus order, and P19's topmost-first ui_cancel where every step is one operation. A3: the OVERVIEW landing pane per section 19.1/19.2 + P17/P18 - identity block on the section 15 treatment, the 3x2 department tiles (min 300x140) that navigate on press, the active-hull + repair summary with REPAIR deep-linking to SHIPYARD, the U2 services rows (CONTRACTS / INSURANCE / VAULTS), one flavour line. A4: P20 cycling (PageUp/PageDown + pad shoulders wrap the six panes from anywhere), LOG OUT's confirm flow unchanged, and raw-key fallbacks for the new actions (TERMINAL toggle, station_inspect, station_prev_module / station_next_module) - InputMap registration happens at close-out, project.godot is outside your set. A5: tests - drawer open/close/ESC/entry-navigation rows, OVERVIEW tile navigation + landing-on-dock rows, the cycling wrap row; move test_s29_station_panels and test_s21_stability boot rows and DISCLOSE each; restore the L18/L122 clock rows' equality with a frozen-clock fixture (T-105's ruling, never back to '> before'). A6: run the headless gate twice on fresh scratch XDG_DATA_HOME stores, disclose every moved row (an unlisted move is a review HIGH), and write .agents/gen/slices/S30-shell-v2/S30-B2_report.md (REPORT template, 120 lines max) answering A1-A6 with file:line cites. Docs read-only; Tokens only, no new art (reuse shipped icons for tiles and entries); motion <= 0.2 s TRANS_CUBIC EASE_OUT, overlays only; the three-plate clusters derive their seat from section 8 tokens + section 19.3 arithmetic and the arithmetic is reported (any widened box ships PROPOSED with a reversal and a fresh P id)." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s30_b2.log 2>&1
```

## S30-R1 — mandatory review (after B2 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/S30-R1_review.md' \
     crush run "You are worker S30-R1, the mandatory reviewer of wave S30 (brief .agents/gen/slices/S30-shell-v2/S30_BRIEF.md; law UI_SPEC.md section 11/12 and STATION_HUB.md section 18/19 - diff against those and the d19 wireframes, never against the builders' reports). Grade B1's A1-A6 and B2's A1-A6 first, re-measuring yourself: A5.5 by the hover-never-moves probe on every pane (a node that moves is HIGH), the census by opening each named handler and hunting one class beyond it (a violation missing from section 12.5 is MED), the skeleton by measuring each pane's PaneHeader / content split / cluster / footer origins (a pane off the shared grid is MED), the drawer and modal against 12.1/12.3's anatomy and motion values, OVERVIEW against 19.1/19.2 block by block, and the band/rail deletion (a surviving node is HIGH). Re-run the gate yourself twice on fresh scratch stores; every moved row must appear in a builder's disclosure list (an unlisted move is HIGH) and tests moved without a replacement row is HIGH. Update docs/CONTRACTS.md section 9's gate figure and section 10's changelog at the next free rows read at write time. Write .agents/gen/slices/S30-shell-v2/S30-R1_review.md (REVIEW template, 150 lines max), findings S30-B1/F## or S30-B2/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s30_r1.log 2>&1
```

## S30-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/' \
     crush run "You are worker S30-F1, the fixer of wave S30 (brief .agents/gen/slices/S30-shell-v2/S30_BRIEF.md; review .agents/gen/slices/S30-shell-v2/S30-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed (R-S30-1/2 stay). Re-run the gate twice on fresh scratch XDG_DATA_HOME stores and report .agents/gen/slices/S30-shell-v2/S30-F1_report.md with a finding-by-finding disposition and both gate lines (120 lines max)." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s30_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 36 only — S30 station shell v2 build. Brief: .agents/gen/slices/S30-shell-v2/S30_BRIEF.md. Prompts: .agents/gen/slices/S30-shell-v2/S30_prompts.md. Snapshot + commit before the first dispatch, run B1 → B2 → R1, and the fixer only if the review leaves HIGH or MED. Close out per the brief's close-out section (gate ×2, verify_wave.py verify --baseline s30_start, the input-map rows, the docs cite batch + CONTRACTS §9 figure, TICKS.md refresh, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, each builder's per-acceptance numbers, the reviewer's findings by tier, and what remains on TICKS.md.
```
