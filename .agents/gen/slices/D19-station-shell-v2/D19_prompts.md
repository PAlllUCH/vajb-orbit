# D19_prompts.md — dispatch lines (one per worker; run in the brief's order)

Models (owner routing 2026-10-03): design **`xiaomi/mimo-v2.6-pro`**, review
**`hyper/glm-5.3-flash`** — the fixer rides its lane's model. Every run at the
provider's **max** reasoning effort: mimo's enum is low/medium/high only
(`--reasoning-effort max` is rejected — measured 2026-10-03), so its runs carry
`--reasoning-effort high`, which is its max; hyper runs `max`, falling back to
`high` if rejected. Nothing heavier without asking the owner first.
Run order **A1 → R1 → (F1 only on HIGH/MED)**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d19_start \
  && git tag d19_start
```

## D19-A1 — shell-v2 design detail (A1–A6)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/D19-A1_report.md' \
     crush run "You are worker D19-A1 on the Vajb Orbit workspace, wave D19 (station shell v2: the TERMINAL drawer, the OVERVIEW pane, the popups). Read .agents/gen/slices/D19-station-shell-v2/D19_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md. Task: land A1-A6 exactly. A1: UI_SPEC.md section 12 (next free at write time) - shell-v2 design detail for N24-N30: the drawer (geometry on the 360 px rail width, entry plates, scrim, the 0.18/0.12 s motion, focus order, close paths), the N27 tooltip (5.1 content grammar + the INSPECT hint line, the viewport clamp rule, delay and cursor offset), the N28 INSPECT modal (sheet anatomy row by row, every trigger including the keyboard route, the size-to-content law inside min 420 / max 720), header and footer at the 3.1 measured-grid table idiom. A2: STATION_HUB.md section 19 - OVERVIEW's five blocks as grid rows (identity on the section 15 treatment, the 3x2 department tiles with full tile internals/focus/pressed, the active-hull + repair summary with the REPAIR deep-link to SHIPYARD, the CONTRACTS/INSURANCE/VAULTS services rows, one flavour line) plus the one skeleton measured once with per-pane conformance rows for all seven panes (OVERVIEW, ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH) - where each PaneHeader / content split / action cluster / footer sits and what each pane moves into its split. A3: three wireframes in staging/mockup/ (d19_shell_wireframe.md, d19_overview_wireframe.md, d19_popup_wireframe.md), the D18 wireframe idiom. A4: the A5.5 defect census over vajb-orbit/ui/ - every hover/focus/selection handler that violates the A5.5 law (colour/modulate/_draw only) with file:line and its named cure; shipyard_panel.gd:703-733 and the fitting twin must appear; the census is closed when S30 can cure from the list alone. A5: the supersession ledger - every docs/design/ sentence this wave re-points, old cite to new cite (the three in section 18's ledger plus anything else, e.g. section 2's rail wording). A6: the staged art-needs list - any sprite this shell wants with prompt draft, model, price estimate at 10 credits = 0.05 USD per 2K run, and pipeline route; staged only, generate nothing. A5.5 binds everything; every value not already pinned ships PROPOSED with a reversal and a fresh tick id continuing the series (N31+ in UI_SPEC, P22+ in STATION_HUB); the tone is N29 grimdark tokens, smooth overlay-only motion; no code files, no 18_engine_spec.md; a number you believe is wrong is reported, never changed. Report .agents/gen/slices/D19-station-shell-v2/D19-A1_report.md (REPORT template, 120 lines max) answering A1-A6 with cites." \
     -m xiaomi/mimo-v2.6-pro --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d19_a1.log 2>&1
```

## D19-R1 — mandatory review (after A1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,vajb-orbit/ui/,.agents/gen/slices/D19-station-shell-v2/D19-R1_review.md' \
     crush run "You are worker D19-R1, the mandatory reviewer of wave D19 (brief .agents/gen/slices/D19-station-shell-v2/D19_BRIEF.md; law UI_SPEC.md section 11 N24-N30 + A5.5 and STATION_HUB.md section 18 P15-P21 - diff against those, never against A1's report). Grade A1-A6 first, re-measuring yourself: the section 12/19 tables against the 3.1 idiom and every pinned value they restate (a value contradicted against its tick id is HIGH), the wireframes against the sections (a wireframe contradicting its own spec text is HIGH), the A4 census by opening the named handlers yourself and hunting one class beyond it (a handler that violates A5.5 and is missing from the census is MED), the A5 ledger by opening each old cite, the A6 list against the pipeline law (a generated file is HIGH - staging only). Check series discipline: fresh ids continue N31+/P22+ with reversals, no collision with the 09-series P-rows. Write .agents/gen/slices/D19-station-shell-v2/D19-R1_review.md (REVIEW template, 150 lines max), findings D19-A1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix anything. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/d19_r1.log 2>&1
```

## D19-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/' \
     crush run "You are worker D19-F1, the fixer of wave D19 (brief .agents/gen/slices/D19-station-shell-v2/D19_BRIEF.md; review .agents/gen/slices/D19-station-shell-v2/D19-R1_review.md). Fix ONLY the HIGH and MED findings at their named cite: section text, wireframes, the census, the ledger. No LOW items, no new PROPOSED rows except where a fix needs a value (then with reversal + next free id), no pinned value changed. Report .agents/gen/slices/D19-station-shell-v2/D19-F1_report.md with a finding-by-finding disposition (120 lines max)." \
     -m xiaomi/mimo-v2.6-pro --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d19_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_designer.md and execute queue item 19 only — D19 station shell v2 design. Brief: .agents/gen/slices/D19-station-shell-v2/D19_BRIEF.md. Prompts: .agents/gen/slices/D19-station-shell-v2/D19_prompts.md. Snapshot + commit before the first dispatch, run A1 → R1, and the fixer only if the review leaves HIGH or MED. Close out per the brief's close-out section (gate re-run at 1074/0, verify_wave.py verify --baseline d19_start, WAVEBOARD update, wave-boundary commit), then report back: the gate count, A1's per-acceptance numbers, R1's findings by tier, and the owner tick status. S30's five-piece (coder item 36) is the next action after close-out.
```
