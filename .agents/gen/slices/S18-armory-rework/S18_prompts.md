# S18_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort max`. Run order **B1 → R1 → (F1 only on
HIGH/MED)**. Every `crush run` is launched with `run_in_background: true` and
**waited on** (`job_output`, `wait: true`) before the next step or the end of
the session. If a worker wedges (0 sockets, frozen `/proc/<pid>/io`, ~0
CPU-sec), kill it with python SIGKILL — the wrapper AND the inner
`bin/crush run` pid — then re-dispatch; re-check `git status` and the report
file after any kill. Worker runs are bounded (`--quit-after` on every Godot
run); nothing may be left in the background.

**Before the first dispatch** (the five-piece is already committed; this takes
the baseline and the evidence tag):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s18_start \
  && git tag s18_start
```

## S18-B1 — rebuild the ARMORY pane (approach B)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/station/,vajb-orbit/assets/ui/ui_armory_console.png,staging/mockup/,vajb-orbit/tests/,docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,.agents/gen/slices/S18-armory-rework/' \
     crush run "You are worker S18-B1 on the Vajb Orbit workspace, wave S18 (the ARMORY rework IMPLEMENTATION — D13's design is owner-ticked and is the law). Read .agents/gen/slices/S18-armory-rework/S18_BRIEF.md end to end (it binds your file set, the pinned interfaces and the tests that move), then .agents/gen/slices/D13-armory-rework/D13-A0_report.md (the design of record: approach B by section, PROPOSED P1-P6 with reversals, the owner tick answers 2026-09-25), then staging/mockup/armory_mockup_v2.py and its out/ mockups (the owner-approved look and geometry; _b_wide/_b_tall show the reflow the tick T1 condition requires). Build: (1) the landscape console 1360x516 at the pinned (452,214)+1392x610 host (P1) with a scripted deterministic master (staging/mockup/render_console_master.py, the mockup's brushed/bevel/bolt language at 2x = 2720x1072; no paid calls, byte-identical re-render required); rack/row plates retire, bays/cells/ledges/rows/chips are code-drawn treatments. (2) Layout B: five bays B1..B5 each 2x2 cells (P3) carrying the full barrel name at 13 px on the recess (T3) and DROP HERE on empty cells (T4), per-bay salvo ledge with seven-seg digits + SALVO s adjacent (T8); wells band = barrel inventory rows (drag sources) left, ammunition pack cards (P2) right with P5 unit wording (HELD 60 ROUNDS - HOLD 30 UNITS). (3) Ink and states: 13 px floor everywhere registered in Router.FONT_SIZE_ITEMS (cures HIGH-1's 12 escaping overrides), captions on the light ramp >= 4.5:1 (HIGH-2), READY / chevron OVER CAP chip on the bay head, shape + label never colour alone (T7); the pane footer caption dies, the inspector carries 2-3 body lines through the existing inspect_requested seam (P4/T5). (4) P6/T1 condition: no absolute pane rects — derive every rect from the host rect (anchors/containers) and verify at 1280x720, 2560x1080 and 1280x1024 in a STANDALONE run (window/resolution changes are inert in a project_run game — AGENTS.md gap, backlog row L222), against the three canvas proofs. (5) Data law: 5 batteries x 4 cells, pack cards, salvo readouts, the 13/16 transactions and CONTRACTS 17 seams unchanged — a dropped datum is HIGH. (6) Docs: the ticked values land as dated amendment blocks in UI_SPEC 3.10 and STATION_HUB 5.11, each with its reversal path; never touch 18_engine_spec.md. Tests: re-derive test_s15_armory_layout.gd's pinned ink-fit numbers (INK Rect2(7,49,180,84), INK_ROWS (49,132), SLOT_PITCH 34.5, master 194x182 at :38-44 — superseded by P3) and re-pin them to the new geometry, update the structure assertions in test_p2b1_outfitting_panel.gd, test_s10_armory_input.gd, test_d7_armory.gd, test_s15_battery_cap.gd, test_s11_describe.gd, test_s11_inspector.gd without weakening what they assert, and add test_s18_armory_rework.gd gating the D13 floors (13 px ink, >= 4.5:1 captions, P5 wording, P6 derivation). Gate law: starts 877/0, add rows never lose one; every moved test number with its old and new value goes in your report. Bound every Godot run with --quit-after; leave no command in the background. Report .agents/gen/slices/S18-armory-rework/S18-B1_report.md (REPORT template, 120 lines max)." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s18_b1.log 2>&1
```

## S18-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,staging/mockup/,.agents/gen/slices/S18-armory-rework/,staging/verify_wave.py' \
     crush run "You are worker S18-R1, the mandatory reviewer of wave S18 (brief .agents/gen/slices/S18-armory-rework/S18_BRIEF.md; design law .agents/gen/slices/D13-armory-rework/D13-A0_report.md; diff findings against the CONTRACTS and the owner ticks 2026-09-25 (T1 y with the all-resolutions condition, T2 = B, T3-T8 y), never against taste). Re-derive everything yourself: run the gate twice hermetic and require 877+added/0 with no lost row; re-render the console master and require byte-identical output; measure the pane in a running game (13 px ink floor, captions >= 4.5:1 computed from the drawn colours, P5 wording present, state never colour alone); verify the P6 derivation claim at 1280x720, 2560x1080 and 1280x1024 in a standalone run and compare against staging/mockup/out/armory_mockup_v2_b{,_wide,_tall}.png; check the data model survived (5 x 4 batteries, pack cards with every 13/16 transaction datum, salvo readouts, CONTRACTS 17 seams) — a dropped datum is HIGH; check every moved test number is reported with old and new value and the suite assertions were not weakened; check the docs amendment blocks carry their reversal paths. Write .agents/gen/slices/S18-armory-rework/S18-R1_review.md (REVIEW template, 150 lines max), findings S18-B1/F## with tier and one evidence line each. Never fix code yourself; bounded runs only; leave no command in the background." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s18_r1.log 2>&1
```

## S18-F1 — fixer (only if R1 leaves HIGH or MED)

Dispatched from R1's findings with the same file set R1 names per finding; the
fixer's report is `S18-F1_report.md` and the gate line must re-stand.
