# D8_prompts.md — dispatch lines (item 10, in-flight HUD visibility)

Model for every worker: `opencode-go/mimo-v2.6-flash` (the designer lane's
D11 pick, owner 2026-09-24) on `--reasoning-effort medium`. Run order
**B1 → R1 → (F1 only on HIGH/MED)**. `$VAJB_WORKSPACE` resolves from `crushrc`.
Every `crush run` is launched with `run_in_background: true` and **waited on**
(`job_output`, `wait: true`) — the designer skill's "Worker lifecycle" section
is the law.

**Before the first dispatch:**

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d8hud_start \
  && git add .agents/gen/slices/D8-hud-visibility .agents/gen/dispatch_designer.md \
       .agents/gen/_state/WAVEBOARD.md \
  && git commit -m "docs: brief the in-flight HUD visibility wave" \
  && git tag d8hud_start
```

## D8-B1 — the HUD visibility pass

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/tests/,vajb-orbit/tools/,.agents/gen/slices/D8-hud-visibility/D8-B1_report.md' \
     crush run "You are worker D8-B1 on the Vajb Orbit workspace, wave D8 item 10. Read .agents/gen/slices/D8-hud-visibility/D8_BRIEF.md end to end — its section 1's five rules bind every line you write — then SLICE.md, then the in-flight HUD rows of .agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md (they name the offenders and bind this brief where it is silent). Task: (1) build the top-left content block from readouts the HUD already holds (your choice, justified; no state item may disappear or lose its update path); (2) add a minimap legend naming exactly the blip kinds minimap.gd draws, inside the HUD chrome; (3) fix every 1080p glyph/text offender to at least 12 px cap height at its source, without per-node overrides escaping ui_scale; (4) tests/test_d8_hud_visibility.gd proving AC1-AC4 including the untouched-cockpit guard. Pre-grep and report every row you touch; an unlisted row changed is a HIGH finding at review. Report .agents/gen/slices/D8-hud-visibility/D8-B1_report.md (120 lines max): the composition justification, the legend kinds table, the glyph before/after pixel table, the pre-grep table, gate SUMMARY before and after, every deviation bucket-tagged. Never touch ui/station, game, autoload, project.godot, docs or addons — report a bucket-2 need and stop at the boundary. Shell edits forbidden; every Godot run bounded with --quit-after on its own XDG_DATA_HOME scratch store." \
     -m opencode-go/mimo-v2.6-flash --reasoning-effort medium --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_b1.log 2>&1
```

## D8-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,.agents/gen/slices/D8-hud-visibility/D8-R1_review.md' \
     crush run "You are worker D8-R1, the mandatory reviewer of wave D8 item 10 (brief .agents/gen/slices/D8-hud-visibility/D8_BRIEF.md; diff findings against the QA rows of .agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md and the brief's section 1 — never against the report). Re-measure everything yourself: AC1 the top-left block (the named readouts resolve live; every old state item still updates; nothing invented), AC2 the legend (it names exactly minimap.gd's draw kinds), AC3 the glyph floor (re-measure the pixels at 1920x1080 yourself), AC4 the untouched cockpit and suites (git diff scoped to ui/hud plus the named test files), AC5 staging/verify_wave.py verify --baseline d8hud_start --forbidden vajb-orbit/project.godot docs/ vajb-orbit/game/ vajb-orbit/autoload/ vajb-orbit/ui/station/ addons/ --tests --expect-reports .agents/gen/slices/D8-hud-visibility/D8-B1_report.md .agents/gen/slices/D8-hud-visibility/D8-R1_review.md (the S14/S15 lanes' touched files are attributed, never reverted). Diff the moved rows against the brief's section 2 list — an unlisted row changed is HIGH. Write .agents/gen/slices/D8-hud-visibility/D8-R1_review.md (REVIEW template, 150 lines max), findings D8-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix. Bounded probes only." \
     -m opencode-go/mimo-v2.6-flash --reasoning-effort medium --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_r1.log 2>&1
```

## D8-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/tests/,vajb-orbit/tools/,.agents/gen/slices/D8-hud-visibility/' \
     crush run "You are worker D8-F1, the fixer of wave D8 item 10 (brief .agents/gen/slices/D8-hud-visibility/D8_BRIEF.md; review .agents/gen/slices/D8-hud-visibility/D8-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no file outside your set. Re-run the gate twice on scratch stores and report .agents/gen/slices/D8-hud-visibility/D8-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m opencode-go/mimo-v2.6-flash --reasoning-effort medium --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits.
