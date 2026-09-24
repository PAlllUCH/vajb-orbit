# D6_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (the S5 precedent; swap to a
designer-roster model for M0 only if the owner wants a design eye on the sheet).
Run from the workspace root. Reports: `slices/D6-cockpit-instruments/<WorkerID>_report.md`,
review `D6-R1_review.md`. Gate/probe convention: `source ~/.profile && godot --headless
--path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` — and **every
probe/gate runs against a scratch store** (`XDG_DATA_HOME` or repointed `save_path`;
T-93 class). Editor reimports only in quiet windows between the parallel S5 lane's
gate runs; one editor session.

**Run order: M0a → (owner approves review sheet) → M0b → M1 → M2 → R1 → (F1 only on
HIGH/MED).** M1 before M2 (shared `hud.gd`).

**Parallel with coder item 11 (S5):** this wave's write set is disjoint from S5's
(`ui/hud/**`, `assets/ui/**`, `assets/icons/**` provenance, `staging/**`,
`asset-library/**`, `tests/test_d6_*.gd`). Touch nothing else.

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name d6_start && git add -A && git commit -m "Record the pre-wave state before the cockpit instruments wave"
```

## D6-M0a — sprite generation, cuts, digit QC, review sheet (STOP after the sheet)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/" crush run "You are worker D6-M0 on the Vajb Orbit workspace (wave D6, brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md — read it fully, then docs/design/UI_CHROME_ASSETS_SPEC.md §11 and §1, docs/design/ASSET_NAMING_SPEC.md §11). Task: generate the four panels of UI_CHROME §11 exactly as prompted there (style-block.txt preamble verbatim; the instrument 2x2 panel, the frame+glass 2-cell panel, and the two 3x2 seven-segment panels panel_sevenseg_a/b) through the Phase G lane (2K runs; the §11 per-run prompts are the law, invent nothing). Then the pipeline order is law: render, panels.py --detect to find every object, cut each, key each, trim — never key a panel holding more than one object, and cells in the driver is the authority. Ship the 18 masters to vajb-orbit/assets/ui/ under the §11 names with panel provenance files under vajb-orbit/assets/icons/, and pass AC5's digit QC (lit-ink containment at or above 95 percent inside ui_seg_blank's ghost boxes, ink-share ordering blank smallest then 1 then up through 8) before shipping anything — a digit that mangles twice falls back to hand-authored SVG segments rasterised into the same names, and you report the route either way. Build the review sheet showing all 18 masters at their logical boxes and 2x, write your generation log beside the family, and STOP at the review sheet for owner approval — do not start code work. Report .agents/gen/slices/D6-cockpit-instruments/D6-M0_report.md with the run ids, per-file boxes, alpha/ink measurements and the QC table. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D6-M0b — ship confirmation + reimport (after the owner approves the sheet)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/" crush run "You are worker D6-M0 phase b on the Vajb Orbit workspace (wave D6, brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md; your phase-a report .agents/gen/slices/D6-cockpit-instruments/D6-M0_report.md). The owner approved the review sheet. Task: reconcile the shipped masters against UI_CHROME_ASSETS_SPEC §11's table (18 files, exact names, masters at 2x their logical boxes), unify import settings on the new files (mipmaps on, lossless, 3D detection off), trigger the editor reimport in a quiet window (one editor session; filesystem_manage reimport when the editor is open, otherwise a headless --import after touching the sources), and append the final boxes + import state to .agents/gen/slices/D6-cockpit-instruments/D6-M0_report.md. No new art, no code." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D6-M1 — instrument cluster (after M0b)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/hud/,vajb-orbit/tests/" crush run "You are worker D6-M1 on the Vajb Orbit workspace (wave D6, brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md — read it fully, then docs/design/UI_SPEC.md §3.7 and §3.6/§3.1/§3.1b, docs/CONTRACTS.md §18 and §7). Task: the cockpit instrument cluster exactly as UI_SPEC §3.7 pins, built in code in the §7 inner-widget idiom (hud.tscn stays untouched). (1) The §3.6 Speedometer contract survives BYTE-IDENTICAL — test_engine2_hud.gd:188-237 must stay green unmodified: same 120x120 box, SEGMENTS 10, SWEEP 1.5pi, OVERDRIVE 0.9, same filled_segments/overdrive_segment/needle_colour semantics; only the _draw surface gains the ui_gauge_face/ui_gauge_needle sprites under the marks while the segment fill, prograde needle and heading tick stay code-drawn in theme tokens. (2) The compass: ui_compass_rose rotating minus the heading angle under a fixed ui_compass_lubber, HDG row 0..359, no cardinal letters. (3) The five readout rows on ui_readout_glass with ui_seg_* digit cells per §3.7's digit semantics (spd = prograde length u/s 3 cells clamp 999, hull/shield = points 4 cells clamp 9999, fuel/energy = percent 3 cells plus the percent cell, leading blanks never zeros) and the danger-row rules verbatim (labels and 1 px frames only — digits never recolour). Read-backs per CONTRACTS §18: cockpit(), compass(), compass_heading(), readouts() returning the clamped ints. ZERO new feeds — derive everything from set_speedometer, set_pool and the hull/shield handlers. Add ONLY tests/test_d6_cluster.gd covering the readouts map with clamps and padding, every danger-row rule, the overdrive strict boundary at exactly 0.9, compass rotation and heading mapping, and the §3.6 rows re-asserted through the cluster. Report .agents/gen/slices/D6-cockpit-instruments/D6-M1_report.md with measured numbers. Hard rules in the brief apply; scratch stores only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D6-M2 — ship status screen (after M1)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/hud/,vajb-orbit/tests/" crush run "You are worker D6-M2 on the Vajb Orbit workspace (wave D6, brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md — read it fully, then docs/design/UI_SPEC.md §3.8, docs/CONTRACTS.md §18/§17/§13). Task: the ship status screen exactly as UI_SPEC §3.8 pins — a HUD-internal 720x520 centred modal on ui_cockpit_frame, hidden by default and while docked, toggled by &\"ship_status\" behind InputMap.has_action (the project.godot row is orchestrator-applied at close-out; never touch project.godot). Left: the active hull's side render at 320 px swapping to the _damaged_side.png cut by exactly ui/station/repairs_panel.gd's suffix rule (intact when no damaged cut exists), plus code-drawn hardpoint markers behind ShipFit.HARDPOINTS.has(hull_id) — never write that table, never block on it. Right: the slot grid on the shipyard plate recipe with each fitted module's glyph and cell ref from resolved_fit plus set_hull_slots cells; names from ModuleCatalog. Footer: HULL/SHLD cur over max and POWER draw over capacity using the fitting panel's own power arithmetic — cite the reused expression in your report, invent no formula. Close via the toggle or the icon_close button; Esc stays Pause-only. The screen READS and writes nothing to the profile. Add ONLY tests/test_d6_status.gd: the toggle guard with no input row present, fit and grid rendering from a seeded scratch profile, the damaged-side swap both branches, and a no-write proof (profile bytes identical before and after opening). Report .agents/gen/slices/D6-cockpit-instruments/D6-M2_report.md with measured numbers. Hard rules in the brief apply; scratch stores only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D6-R1 — mandatory review (after M1–M2 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker D6-R1, the mandatory reviewer of wave D6 (brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md; diff findings against docs/design/UI_SPEC.md §3.7/§3.8 and docs/CONTRACTS.md §18 — never against the brief). Re-measure everything yourself: test_engine2_hud.gd:188-237 byte-green UNMODIFIED (git diff must show zero edits to that file's expectations); the readouts map probed against seeded pool states including clamps, blank padding and maximum 0; every danger-row rule and the overdrive strict boundary; compass rotation direction and the 0..359 mapping; the status screen's toggle guard with the input row absent, both damaged-side branches, the slot-grid cell refs against a seeded resolved_fit, the power arithmetic agreeing with the fitting panel's own numbers, and the no-write proof. Digit QC independently re-run (AC5's containment and ink-share ordering) on the shipped masters. No frozen file moved and no balance number moved (staging/verify_wave.py verify --baseline d6_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md --tests); gate twice on scratch stores. Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/D6-cockpit-instruments/D6-R1_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md (next free ids). Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## D6-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/,vajb-orbit/ui/hud/,vajb-orbit/tests/" crush run "You are worker D6-F1, the fixer of wave D6 (brief .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md; review .agents/gen/slices/D6-cockpit-instruments/D6-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no balance changes. Re-run the gate twice on scratch stores and report .agents/gen/slices/D6-cockpit-instruments/D6-F1_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
