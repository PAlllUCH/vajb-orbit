# D8_prompts.md — dispatch lines (item 10, in-flight HUD visibility)

Model for every worker: `opencode-go/mimo-v2.6-pro` on `--reasoning-effort low`
(owner rule 2026-09-25: design runs on 2.6 Pro only. Measured the same day:
`medium` stalls on long worker loops and one big worker stalled even at `low`
after 30 min of exploration — hence **the split** (owner's choice 2026-09-25):
three tiny workers, one pick each, sequential because they share the one test
file. If a Pro worker goes quiet >15 min with no new narration: health-check
sockets + `/proc/<pid>/io`, then SIGKILL via python3 — this shell has no `kill`
builtin — and re-dispatch.) Run order **H2 → H4 (hide, coder model) → H3 → R1 →
(F1 only on HIGH/MED)**.

**Before the first dispatch** (done 2026-09-25, tag `d8hud_start`, commit
`73f4aad`). Each worker below keeps its prompt small on purpose: the prompt is
the spec; do not send workers reading long documents.

## D8-H1 — RETIRED 2026-09-25 (owner: "its already in the cockpit")

The top-left block is dead: hull/shield state is already live in the cockpit
cluster (the QA row predates D6/D7), and nothing may duplicate it. The first
dispatch attempt (one monolithic B1) and this pick's worker were killed without
deliverables; the quadrant may stay empty.

## D8-H2 — the minimap legend and its two glyphs (after H1)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/minimap.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/tests/test_d8_hud_visibility.gd,.agents/gen/slices/D8-hud-visibility/D8-H2_report.md' \
     crush run "You are worker D8-H2 on the Vajb Orbit workspace, wave D8 item 10. Small focused task; this prompt is the spec. The QA finding you answer, verbatim: Minimap shows blips and a corridor circle with no legend; two small glyphs at its bottom-right are unreadable at 1080p. Task: (1) add a minimap legend that names exactly the blip kinds minimap.gd draws — read minimap.gd's draw code and name nothing that does not exist — placed inside the minimap bezel, each legend glyph and label at least 12 px cap height at 1920x1080; (2) fix the two bottom-right glyphs (the minimap's zoom icons) to at least 12 px cap height at 1080p by sizing/placement in code. Append rows to tests/test_d8_hud_visibility.gd (it exists from H1) proving the legend names each draw kind and both glyphs measure at least 12 px. Run the universal gate once on its own scratch store, bounded, and record the SUMMARY. Write .agents/gen/slices/D8-hud-visibility/D8-H2_report.md under 40 lines: the legend kind table, the glyph before/after pixel measurements, the gate line. Touch only your file set; shell edits forbidden; never write the profile or a live user://." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_h2.log 2>&1
```

## D8-H4 — hide the top-left hull/shield (owner 2026-09-25; after H2, before H3)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/tests/test_d8_hud_visibility.gd,.agents/gen/slices/D8-hud-visibility/D8-H4_report.md' \
     crush run "You are worker D8-H4 on the Vajb Orbit workspace, wave D8 item 10. Tiny focused task; this prompt is the spec. Owner 2026-09-25, verbatim: hide shield and hull in top left corner. The game currently shows hull and shield readouts top-left, duplicating the cockpit cluster (its SPD/HULL/SHLD/AMMO seven-segment and FUEL/ENRG gauges). Task: hide the top-left hull and shield display (hud.tscn/hud.gd TopLeft/Blocks HullBlock/ShieldBlock) so the top-left quadrant is empty. If EnergyBlock/FuelBlock also render the cockpit's FUEL/ENRG data top-left, hide them too under the same no-duplication rule and say so. Add one row to tests/test_d8_hud_visibility.gd (create the file if it does not exist yet) asserting the top-left blocks are not visible at runtime. Run the universal gate once on its own XDG_DATA_HOME scratch store, bounded with --quit-after, and record the SUMMARY line. Write .agents/gen/slices/D8-hud-visibility/D8-H4_report.md under 30 lines: what was hidden, the gate line. Touch only your file set; shell edits forbidden; never write the profile or a live user://." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_h4.log 2>&1
```

## D8-H3 — the 1080p glyph floor sweep (after H4)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/tests/test_d8_hud_visibility.gd,.agents/gen/slices/D8-hud-visibility/D8-H3_report.md' \
     crush run "You are worker D8-H3 on the Vajb Orbit workspace, wave D8 item 10. Small focused task; this prompt is the spec. Task: sweep every HUD text and glyph to a 12 px cap-height floor at 1920x1080 (H2 already handled the minimap legend and zoom icons — skip those). Find the offenders by measuring, fix each at its source (font size constants, theme overrides, or per-node overrides — a per-node override must not escape ui_scale), and do not restyle or re-theme anything: sizing only. Append to tests/test_d8_hud_visibility.gd one table-driven measurement row covering the HUD's Labels and TextureRects so a regression fails the gate. Run the universal gate once on its own scratch store, bounded, and record the SUMMARY. Write .agents/gen/slices/D8-hud-visibility/D8-H3_report.md under 40 lines: the offender table with before/after pixel measurements, the gate line. Touch only your file set; shell edits forbidden; never write the profile or a live user://." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_h3.log 2>&1
```

## D8-R1 — mandatory review (after H3 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,.agents/gen/slices/D8-hud-visibility/D8-R1_review.md' \
     crush run "You are worker D8-R1, the mandatory reviewer of wave D8 item 10 (the three QA rows and the brief's section 1 in .agents/gen/slices/D8-hud-visibility/D8_BRIEF.md are the law; the three reports are claims to verify, never sources). Re-measure everything yourself: the top-left quadrant staying empty with no HUD element duplicating the
cockpit cluster's readouts (the retired AC1), the minimap legend naming exactly minimap.gd's draw kinds, the 12 px cap-height floor re-measured at 1920x1080 across the HUD, no state item lost, test_d7_cockpit untouched (git diff scoped to ui/hud plus tests/test_d8_hud_visibility.gd), and staging/verify_wave.py verify --baseline d8hud_start --forbidden vajb-orbit/project.godot docs/ vajb-orbit/game/ vajb-orbit/autoload/ vajb-orbit/ui/station/ addons/ --tests --expect-reports .agents/gen/slices/D8-hud-visibility/D8-H1_report.md .agents/gen/slices/D8-hud-visibility/D8-H2_report.md .agents/gen/slices/D8-hud-visibility/D8-H3_report.md (other lanes' touched files are attributed, never reverted). Write .agents/gen/slices/D8-hud-visibility/D8-R1_review.md under 120 lines, findings D8-H1/F## or D8-H2/F## or D8-H3/F## with a tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix. Bounded probes only." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_r1.log 2>&1
```

## D8-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/tests/,vajb-orbit/tools/,.agents/gen/slices/D8-hud-visibility/' \
     crush run "You are worker D8-F1, the fixer of wave D8 item 10 (review .agents/gen/slices/D8-hud-visibility/D8-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors. Re-run the gate twice on scratch stores and report .agents/gen/slices/D8-hud-visibility/D8-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d8hud_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
