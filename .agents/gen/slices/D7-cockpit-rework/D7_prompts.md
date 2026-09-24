# D7_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (the S5/D6 precedent). Run
from the workspace root. Reports: `slices/D7-cockpit-rework/<WorkerID>_report.md`,
review `D7-R1_review.md`. Gate/probe convention: `source ~/.profile && godot
--headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`
with `XDG_DATA_HOME` on a fresh scratch dir (T-93) — every probe/gate. Editor
reimports only in quiet windows (S6 parallel); one editor session.

**Run order: A0 → (owner approves review sheet) → A0b → C1 → C2 → C3 → R1 → (F1
only on HIGH/MED).** C1 before C2/C3 (C1 owns `hud.gd`'s column removal; C3 = the
status modal restyle per Mockup C, shares `ui/hud/`, runs after C1).

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name d7_start && git add -A && git commit -m "Record the pre-wave state before the cockpit rework wave"
```

## D7-A0 — art batch: panel family + armory console (STOP after the review sheet)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/" crush run "You are worker D7-A0 on the Vajb Orbit workspace (wave D7, brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md — read it fully, then docs/design/UI_CHROME_ASSETS_SPEC.md §12 and §1, docs/design/UI_SPEC.md §3.7/§3.9/§3.10 as amended 2026-09-24, docs/design/ASSET_NAMING_SPEC.md §12). Task: the FIVE §12 runs exactly as prompted there (style-block.txt preamble verbatim; the cockpit panel, the gauge face re-cut, the armory console, the 2-cell armory plates panel, and the status console) through the Phase G lane (2K runs; the §12 per-run prompts are the law, invent nothing). Panel order is law: render, panels.py --detect to find every object, cut each, key each, trim — never key a panel holding more than one object, cells in the driver is the authority. The armory rects are measured from armory_panel.gd's own constants at 2x and reported, never invented. Pass §12's QC (ink containment at or above 95 percent; ui_cockpit_panel at 928x512, ui_gauge_face at 240x240 and ui_status_panel at 1440x1040; every well measured against the §3.7/§3.8/§3.10 bay rects at 2x) before shipping anything — a well-bearing render that misses re-renders once, then falls back to the D6-authored route (ui_authored.py shapes over a painted plate) and you report the route either way. Ship the six masters to vajb-orbit/assets/ui/ under the §12 names with panel provenance under vajb-orbit/assets/icons/, write the generation log beside the family, build the review sheet showing every master at its logical box and 2x, and STOP for owner approval — do not start code work. Report .agents/gen/slices/D7-cockpit-rework/D7-A0_report.md with run ids, per-file boxes, well measurements and the QC table. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-A0b — ship reconcile + reimport (after the owner approves the sheet)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/" crush run "You are worker D7-A0 phase b on the Vajb Orbit workspace (wave D7, brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md; your phase-a report .agents/gen/slices/D7-cockpit-rework/D7-A0_report.md). The owner approved the review sheet. Task: reconcile the shipped masters against UI_CHROME_ASSETS_SPEC §12's names and boxes, unify import settings on the new files (mipmaps on, lossless, 3D detection off), trigger the editor reimport in a quiet window (one editor session; filesystem_manage reimport when the editor is open, otherwise a headless --import after touching the sources), and append the final boxes + import state to your report. No new art, no code." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-C1 — cluster rework + digit fix + compass dedup + battery readout + old-HUD removal

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/hud/,vajb-orbit/tests/" crush run "You are worker D7-C1 on the Vajb Orbit workspace (wave D7, brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md — read it fully, then docs/design/UI_SPEC.md §3.6/§3.7 as amended 2026-09-24 and §3.9, docs/CONTRACTS.md §7/§18). Task: the UI_SPEC §3.7 D7 amendment exactly. (1) Digit fit law: every ui_seg_* sprite drawn fill-fitted to its 20x36 cell on a 22 px pitch — the overlap cure — with test_d7_cockpit.gd asserting drawn glyph rects pairwise disjoint and inside their rows. (2) The cluster remounts on ui_cockpit_panel (928x512 master fill-fit to the 464x256 box, no nine-slice; interior 400x192, band 32; bays 126/104/156, 7 px gutters) with gauge/compass/rows in the panel's wells; ui_readout_glass and ui_cockpit_frame leave the cluster. (3) Compass dedup: the dial's heading tick is RETIRED (§3.6 amendment) and ui_gauge_face v2 (8-tick speed scale) replaces the old face; the compass bay (ui_compass_rose + HDG row) is the one heading instrument; compass()/compass_heading()/readouts() survive. (4) Battery readout in the left bay foot: Label B1 · CANNON (12 px text_dim) + AMMO row (34 label + 4 cells, clamp 0..9999, blanks) on the existing ammo feed, rack ordinal resolved by the corrected tables. (5) The old HUD column dies: §3.1 crest bars, §3.2 AmmoPanel, §3.4 cargo block removed from the flight HUD; every §7 frozen method keeps its signature and stays callable. Tests: add ONLY tests/test_d7_cockpit.gd (the groups the brief names); adjust ONLY the heading-tick rows of tests/test_engine2_hud.gd (report each row you touch — the §3.6 amendment is the authority) and the compass rows of tests/test_d6_cluster.gd; nothing else moves. Re-run the full gate twice on scratch stores (XDG_DATA_HOME) and report .agents/gen/slices/D7-cockpit-rework/D7-C1_report.md with measured numbers and every test row you changed. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-C2 — ARMORY cockpit restyle (surface only, after C1)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/,vajb-orbit/tests/" crush run "You are worker D7-C2 on the Vajb Orbit workspace (wave D7, brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md — read it fully, then docs/design/UI_SPEC.md §3.10 and §3.9/§3.1, docs/design/STATION_HUB.md §5.11's restyle block + §12.4). Task: the ARMORY battery window on the §3.9 instrument language, surface only — the pane's transactions, drag-drop behaviour, refusal-writes-nothing rule and the status_requested/refresh_profile/focus_primary contract are untouched (09 §11 + CONTRACTS §17 stay the seams). Mount the pane on ui_armory_console (2x the pane's measured content rect — measure it from armory_panel.gd's own constants and report it, invent nothing) with the three groups in recessed wells; each rack B1..B7 on ui_armory_rack_plate with the W cells as machined slot recesses; INVENTORY/AMMUNITION rows on ui_armory_row_plate (nine-slice, flat bands only); the SALVO line gains a 3-cell ui_seg_* readout (proposed seconds x10: 0.73 s reads 073, Label SALVO s; if that format cannot hold the real figures, report the numbers and fall back to the plain Label — invent no format). Danger/refusal states reuse §3.1/§3.1b row treatments; digits never recolour; no baked text. Add ONLY tests/test_d7_armory.gd (the groups the brief names: transactions byte-behave, drag-drop ordering intact, plates mount at the measured rects, SALVO cells render the cycle figure, danger rows). No other test moves. Re-run the full gate twice on scratch stores (XDG_DATA_HOME) and report .agents/gen/slices/D7-cockpit-rework/D7-C2_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-C3 — ship status modal restyle (Mockup C; after C1)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/hud/,vajb-orbit/tests/" crush run "You are worker D7-C3 on the Vajb Orbit workspace (wave D7, brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md — read it fully, then docs/design/UI_SPEC.md §3.8 as amended 2026-09-24 (the Mockup C block) and §3.9/§3.1). Task: restyle ui/hud/ship_status_screen.gd onto the §3.9 instrument language exactly per the Mockup C block — ui_status_panel console backing (master 2x the 720x520 box, no nine-slice), left well (24,60)-(300,428) with the hull side render aspect-fit and the damaged-cut swap rule unchanged, code-drawn bone-ringed ember hardpoint markers over the render, right well (316,60)-(696,348) with the slot grid (5x3 cells 60x74 on a 72x88 pitch, W1..W5 ref Labels, fitted module glyph plates) on the shipyard plate recipe, footer strip (24,444)-(696,494) with HULL/SHLD/PWR cur-max Labels using the fitting panel's own power arithmetic (cite the reused expression), title Label + icon_close box. BEHAVIOUR IS UNTOUCHED: toggle guard, InputMap.has_action, Esc stays Pause-only, the no-write proof, the read-only fits — every test_d6_status.gd row stays byte-green. Add ONLY tests/test_d7_status.gd (the Mockup C surface groups the brief names). Re-run the full gate twice on scratch stores (XDG_DATA_HOME) and report .agents/gen/slices/D7-cockpit-rework/D7-C3_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-R1 — mandatory review (after C1–C2 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker D7-R1, the mandatory reviewer of wave D7 (brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md; diff findings against docs/design/UI_SPEC.md §3.6/§3.7 as amended 2026-09-24, §3.9/§3.10 and docs/design/UI_CHROME_ASSETS_SPEC.md §12 — never against the brief). Re-measure everything yourself: the digit fit law (drawn glyph rects pairwise disjoint, inside their rows, fill-fitted to 20x36); the dial draws NO heading tick and the compass bay maps 0..359; no glass/screen surface remains in the cluster or the armory window and every widget sits in a painted panel well at the pinned rects; the old HUD column is absent and HULL/SHLD/AMMO read from the cluster; the armory transactions byte-behave (refusals write nothing, drag-drop order intact — the test_p2b*/test_s5_* rows byte-green unmodified); test_engine2_hud.gd's §3.6 rows byte-green EXCEPT the heading-tick rows the §3.6 amendment retires (git diff must show no other edits to that file). Digit QC is not re-run (the ui_seg_* family is not re-cut) — instead verify the family's md5s are unmoved since D6. No frozen file moved and no balance number moved (staging/verify_wave.py verify --baseline d7_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md --tests); gate twice on scratch stores (XDG_DATA_HOME). Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/D7-cockpit-rework/D7-R1_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md (next free ids). Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D7-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/,vajb-orbit/ui/hud/,vajb-orbit/ui/station/,vajb-orbit/tests/" crush run "You are worker D7-F1, the fixer of wave D7 (brief .agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md; review .agents/gen/slices/D7-cockpit-rework/D7-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no balance changes. Re-run the gate twice on scratch stores (XDG_DATA_HOME) and report .agents/gen/slices/D7-cockpit-rework/D7-F1_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
