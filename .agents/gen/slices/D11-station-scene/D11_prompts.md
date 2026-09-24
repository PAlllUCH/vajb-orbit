# D11_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `opencode-go/deepseek-v4.1-flash` (the owner's standing
2026-09-24 order; fallback `deepseek/deepseek-v4-flash`). Run from the
workspace root. Reports: `slices/D11-station-scene/<WorkerID>_report.md`, review
`D11-R1_review.md`. Gate/probe convention: `source ~/.profile &&
XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit
res://tests/headless_runner.tscn --quit-after 1200` — **every probe/gate on a
scratch store**; live store md5s checked unchanged after; bounded probes only.

**Run order: A0 → OWNER APPROVAL → A1 → C1 → R1 → (F1 only on HIGH/MED).**

**Parallel with coder item 14 (S8):** you hold `assets/env/**`, `staging/**`,
`asset-library/**`, `game/sector.gd`, `game/station_scene.gd` (the owner's
grant) and `tests/test_d11_*`. S8 holds everything else in `game/`, the profile
and `tests/test_s8_*` — never touch its files. Mid-wave gate rows failing in
S8's files are cross-lane: attribute, never fix. No `ui/**`, no
`project.godot`, no `docs/` beyond this wave's own. CONTRACTS §9/§10 rows take
the next free changelog/LOW ids **read from the files at close-out** (L167's
lesson).

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name d11_start && git add -A && git commit -m "Record the pre-wave state before the station-scene rework"
```

## D11-A0 — mockup + render plan (HARD STOP for owner approval)

```bash
VAJB_WORKER_FILES="vajb-orbit/assets/env/**,staging/**,asset-library/**" crush run "You are worker D11-A0 on the Vajb Orbit workspace (wave D11, brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md — read it fully, then docs/design/ENVIRONMENT_SPEC.md §11 + §1.1/§6 + §8/§9 and docs/CONTRACTS.md §21's O6 row). Task: build the station-scene MOCKUP and the render plan, then STOP for the owner's approval — no paid renders, no wiring. (1) Write staging/mockup/station_mockup.py in the cockpit-mockup idiom (geometry + palette are the source of truth): today's footprint at STATION_SCALE (sector.gd:54-71, ~67.9 u half-extent) drawn to scale BESIDE the proposed hero at >= 2.2x, with the >= 6 static element kinds (docking arms, masts, gantry, window bands, plate spines, ember lamp runs) laid around it and the >= 3 moving element kinds' paths drawn (approach strobe positions, shuttle loop, crane slew arc) — output staging/mockup/out/station_mockup_v1.png + .jpg at 2x. (2) Write the element render plan: every file name from §11's proposed naming, its subject line (ENVIRONMENT vocabulary verbatim: welded platework, gunmetal mid/dark, grime, rust streaks, ember lamps the ONLY emissive), panel/cell plan (one object per panel for anything keyed; 2K where hero detail needs it), and the per-run credit estimate at 10 credits = $0.05 (target <= $1.50 total across A0+A1). (3) One review sheet staging/phase_g/_review/d11_mockup.png: mockup pair + the plan table as text baked in. (4) Report .agents/gen/slices/D11-station-scene/D11-A0_report.md with the sheet path, the proposed hero scale as a number (today's footprint x N), the element inventory and motion constants as proposed. THEN STOP — the owner approves the sheet before A1. Hard rules in the brief apply: no game/ writes, no docs/ writes, nothing rendered yet." -m opencode-go/deepseek-v4.1-flash --cwd "$VAJB_WORKSPACE"
```

## D11-A1 — renders → QC → ship (after the owner approves A0's sheet)

```bash
VAJB_WORKER_FILES="vajb-orbit/assets/env/**,staging/**,asset-library/**" crush run "You are worker D11-A1 on the Vajb Orbit workspace (wave D11, brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md — read it fully, then ENVIRONMENT_SPEC §11 + §8/§9; A0's approved sheet and plan are the law — implement them, invent nothing). Task: render and ship the approved element set. Panel order is law: render (flare, style source per §8's table, --post-only keying after) -> staging/phase_g/panels.py --detect -> cut each object -> key each (recraft only if the auto-key fails; QC via qc_fx_alpha-style containment checks) -> trim. Hero >= the approved scale floor; every element to §11's name; QC green on every file (containment, alpha > 10% where a cut sprite, negative list §9); the generation log beside the family (vajb-orbit/assets/env/generation_log_d11.md: prompt, job id, model, date, route); ship into vajb-orbit/assets/env/poi/ with import settings (mipmaps on, lossless, 3D detection off) and reimport via the editor only in a quiet window. If a render ignores its brief twice, re-prompt once and record the deviation — do not ship a violating file (§6's one-emissive rule is a hard QC line). Report .agents/gen/slices/D11-station-scene/D11-A1_report.md: per-file QC table, credits spent, deviations. No game/ or docs/ writes." -m opencode-go/deepseek-v4.1-flash --cwd "$VAJB_WORKSPACE"
```

## D11-C1 — the wiring (after A1 ships; holds the owner's game/ grant)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/sector.gd,vajb-orbit/game/station_scene.gd,vajb-orbit/tests/" crush run "You are worker D11-C1 on the Vajb Orbit workspace (wave D11, brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md — read it fully, then docs/design/ENVIRONMENT_SPEC.md §11's invariants and CONTRACTS §21 O6). You hold the owner's one-file-each grant: game/sector.gd (_spawn_station ONLY) and the new game/station_scene.gd. Task: (0) PRE-GREP first and report before editing: grep -rn 'STATION_SCALE|env_station|StationTexture|&\"station\"' vajb-orbit/tests/ — any row pinning the old single sprite or the old scale is listed in your report for ratification (report, never weaken); the group/DockZone test rows are the guard and must stay green untouched. (1) game/station_scene.gd: class_name StationScene extends Node2D; setup(hero, elements) builds the composed tree from the shipped textures (hero + the approved element set), joins &\"station\", and runs the three motion constants as named — STROBE_PERIOD 1.2, SHUTTLE_SPEED 30.0, SLEW_RATE 4.0 — in _process, no Timer nodes; constants at the top with their reversals in the doc comment (a constant set to its reversal's value makes that element stand still). (2) sector.gd:_spawn_station swaps the single Sprite2D for the StationScene at the same centre and the same &\"station\" group; the DockZone stays a SIBLING with its world-unit radius untouched (the :62-71 rule — do not reparent it under anything scaled). Everything else in sector.gd is untouched (git diff scoped). (3) Add ONLY tests/test_d11_station.gd: the composed tree draws (node count >= the element set, hero scale == the approved pin read from the scene, no bare single-sprite path), the group survives, the DockZone radius reads in world units as before, two-frame motion probe (strobes/shuttle/slew move under the constants; a reversal-valued constant stands still), and the S6 dock/blip rows' seams still answer (dock_zone_contains + blips on a minimal sector). Cross-lane: S8 runs parallel — its gate rows are attributed, never touched. Report .agents/gen/slices/D11-station-scene/D11-C1_report.md with the pre-grep results, the invariants' measured values and the gate line." -m opencode-go/deepseek-v4.1-flash --cwd "$VAJB_WORKSPACE"
```

## D11-R1 — mandatory review (after C1 reports)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker D11-R1, the mandatory reviewer of wave D11 (brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md; diff findings against ENVIRONMENT_SPEC §11 + §1.1/§6 and CONTRACTS §21's O6 — never against the brief). Re-measure everything yourself (W8's method): AC1 the owner's approval is the baseline (the approved sheet's pins are what you measure against — quote them); AC2 the shipped inventory (hero footprint ratio measured against the old ~67.9 u half-extent, >= 6 static kinds, >= 3 moving kinds, QC numbers re-run, generation log present, §9 negative list clean, §6 one-emissive rule proven by pixel/palette check); AC3 the invariants (group membership, DockZone world-unit radius with the sibling layout, centre, blips/dock behaviour — re-run test_s6's dock/blip rows); AC4 motion two-frame; AC5 git diff scoped to _spawn_station + the new file; AC6 gate twice on scratch stores with the S8 lane's rows attributed; AC7 every owner tick listed with its measured value. staging/verify_wave.py verify --baseline d11_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md docs/gameplay/04_refinery.md docs/design/ENVIRONMENT_SPEC.md --tests --expect-reports .agents/gen/slices/D11-station-scene/D11-A0_report.md .agents/gen/slices/D11-station-scene/D11-R1_review.md (CONTRACTS deliberately not forbidden — your own §9/§10 writes it). Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/D11-station-scene/D11-R1_review.md; append LOW rows at the NEXT FREE ids read from .agents/gen/_state/LOW_BACKLOG.md (L167's lesson — S8 runs parallel and may take ids first); CONTRACTS §9/§10 with the next free changelog row read from §10 itself, sequenced after S8's row (rebase, never revert). Never fix. Bounded probes only." -m opencode-go/deepseek-v4.1-flash --cwd "$VAJB_WORKSPACE"
```

## D11-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="vajb-orbit/assets/env/**,staging/**,asset-library/**,vajb-orbit/game/sector.gd,vajb-orbit/game/station_scene.gd,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker D11-F1, the fixer of wave D11 (brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md; review .agents/gen/slices/D11-station-scene/D11-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; re-render only what a finding proves violating (keep the approved sheet's pins); adjust tests only where a fix changes what is proven. No LOW items, no refactors, no S8 files, no pinned literal or invariant touched. Re-run the gate twice on scratch stores (S8's rows attributed) and report .agents/gen/slices/D11-station-scene/D11-F1_report.md with a finding-by-finding disposition and the gate lines." -m opencode-go/deepseek-v4.1-flash --cwd "$VAJB_WORKSPACE"
```
