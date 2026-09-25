# S14_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort high`. Run order **B1 → R1 → (F1 only on
HIGH/MED)**. `$VAJB_WORKSPACE` resolves from `crushrc`. Every `crush run` is
launched with `run_in_background: true` and **waited on** (`job_output`,
`wait: true`) before the next step or the end of the session — the coder skill's
"Worker lifecycle" section is the law.

**Before the first dispatch** (S14 and S15 share one pre-dispatch commit; both
snapshots precede it, both tags sit on it):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s14_start \
  && python3 staging/verify_wave.py snapshot --name s15_start \
  && git add docs/gameplay/02_minerals.md docs/gameplay/09_ship_slots_modules.md \
       docs/design/STATION_HUB.md .agents/gen/slices/S14-debris-splits \
       .agents/gen/slices/S15-battery-cap .agents/gen/dispatch_coder.md \
       .agents/gen/_state/WAVEBOARD.md \
  && git commit -m "docs: the debris-split asteroid ladder and the five-by-four battery cap" \
  && git tag s14_start && git tag s15_start
```

## S14-B1 — the debris splits

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S14-debris-splits/S14-B1_report.md' \
     crush run "You are worker S14-B1 on the Vajb Orbit workspace, wave S14. Read .agents/gen/slices/S14-debris-splits/S14_BRIEF.md end to end — its section 2's rules 1-6 bind every line you write — then SLICE.md, then docs/gameplay/02_minerals.md section 5.2 and section 5.1 Rule A by range. Task: (1) add SIZE_XL to vajb-orbit/game/asteroid.gd and the two OreTuning fields exactly as pinned (split_mix and spawn_size_weights; keys are the integer size classes, no preload of game/ from ore_tuning.gd). (2) Replace FRAGMENT_SPLIT and _fragment_size with the pinned child roll: at a shatter, per child kind in split_mix[parent], roll the count on the field's own seeded rng and spawn that many children, strictly smaller than the parent. (3) Keep S13's conservation untouched: a mining shatter's children share the parent reserve across the whole mixed child set via _unit_shares, a gun shatter's children carry no ore, nothing re-rolls — the family realises at most the root's _bore_ore plus 1 however the dice fall. (4) Size-first look roll: _spawn_rock rolls the size from spawn_size_weights, then a look uniformly inside that size; LOOK_TEXTURES gains one row of 3 entries reusing the L silhouettes, LOOK_WIDTHS gains 180.0 (02 section 5.2). (5) Tests: pre-grep section 3's rows and report each before editing; move only the listed rows; add tests/test_s14_splits.gd proving AC1-AC5 (a seeded 200-shatter distribution table, the M-to-S and S-never rules, the conservation re-measurement, the 1000-roll spawn mix within 3 percent, the 180 u XL width) plus the anti-drift assertion that the OreTuning defaults equal the pinned table. Report .agents/gen/slices/S14-debris-splits/S14-B1_report.md (120 lines max): pre-grep table, per-AC measured numbers, gate SUMMARY before and after, every deviation. No project.godot, no docs, no ui, no autoload writes; shell edits forbidden; every Godot run bounded with --quit-after on its own XDG_DATA_HOME scratch store; never write the profile." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s14_b1.log 2>&1
```

## S14-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S14-debris-splits/S14-R1_review.md' \
     crush run "You are worker S14-R1, the mandatory reviewer of wave S14 (brief .agents/gen/slices/S14-debris-splits/S14_BRIEF.md; diff findings against docs/gameplay/02_minerals.md section 5.2 and section 5.1 Rule A — never against the brief). Re-measure everything yourself (W8 method): AC1 the 200-shatter seeded distribution (children only smaller kinds, counts inside the ranges, no child at or above its parent), AC2 the M-to-S and S-never rules, AC3 conservation across the mixed chain (a fully mined family at or below root _bore_ore plus 1; grep _rolled_yield call sites and prove no shatter-side roll survives), AC4 the 1000-roll spawn mix within 3 percent of 40/32/20/8, AC5 the XL width row, AC6 gate twice on scratch stores plus staging/verify_wave.py verify --baseline s14_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md docs/gameplay/04_refinery.md docs/design/ ui/ addons/ --tests --expect-reports .agents/gen/slices/S14-debris-splits/S14-B1_report.md .agents/gen/slices/S14-debris-splits/S14-R1_review.md (the parallel S15 lane's touched files are attributed, never reverted). Diff the moved rows against SLICE.md section 3's list — an unlisted row changed is HIGH. Write .agents/gen/slices/S14-debris-splits/S14-R1_review.md (REVIEW template, 150 lines max), findings S14-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time; CONTRACTS section 9/10 next free rows read at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s14_r1.log 2>&1
```

## S14-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S14-debris-splits/' \
     crush run "You are worker S14-F1, the fixer of wave S14 (brief .agents/gen/slices/S14-debris-splits/S14_BRIEF.md; review .agents/gen/slices/S14-debris-splits/S14-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on scratch stores and report .agents/gen/slices/S14-debris-splits/S14-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s14_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
