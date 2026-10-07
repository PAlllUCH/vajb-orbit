# S16_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort high`. Run order **B1 → R1 → (F1 only on
HIGH/MED)**. `$VAJB_WORKSPACE` resolves from `crushrc`. Every `crush run` is
launched with `run_in_background: true` and **waited on** (`job_output`,
`wait: true`) before the next step or the end of the session — the coder
skill's "Worker lifecycle" section is the law. If a worker wedges (0 sockets,
frozen `/proc/<pid>/io`, ~0 CPU-sec), kill it with python SIGKILL — the
wrapper AND the inner `bin/crush run` pid — then re-dispatch; re-check
`git status` and the report file after any kill.

**Before the first dispatch** (the five-piece is already committed; this
takes the baseline and the evidence tag):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s16_start \
  && git tag s16_start
```

## S16-B1 — the fragment re-split

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/asteroid.gd,vajb-orbit/game/asteroid_field.gd,vajb-orbit/tests/,.agents/gen/slices/S16-fragment-resplit/S16-B1_report.md' \
     crush run "You are worker S16-B1 on the Vajb Orbit workspace, wave S16 (fragment re-splits). Read .agents/gen/slices/S16-fragment-resplit/S16_BRIEF.md end to end — its section 2's rules 1-6 bind every line you write — then SLICE.md, then docs/gameplay/02_minerals.md section 5.2 ter, section 5.2 and section 5.1 Rule A by range. Task: (1) the pinned marker in vajb-orbit/game/asteroid.gd exactly (_cleave_child, mark_cleave_child, and cleaves returning _bore_ore > 0.0 or _cleave_child; originals stay unmarked — no caller outside the cleave may mark) and mark every fragment _cleave builds in vajb-orbit/game/asteroid_field.gd immediately after the _new_rock call. (2) No other arithmetic changes: split_mix, _unit_shares, the gun cap, the ejection and the burst stay untouched; a 0-bore fragment pays nothing at every shatter (if any path can reach a burst with owed > 0 on a 0-bore fragment, report it as a finding — do not fix). (3) Tests: pre-grep section 3's candidate suites and report every row that could change under debris re-splitting BEFORE editing — no existing gate row moves; any row that must change is a bucket-2 pause you report, never edit. Add tests/test_s16_resplits.gd proving SLICE.md's AC1-AC6 (seeded on the field's own rng, S14's suite as the pattern): AC1 a gun shatter's L/M/S children cleave per their own class into strictly smaller children, the chain reaching S and stopping; AC2 every shatter in a shot chain pays 0 units and no pickup spawns from owed 0; AC3 conservation both routes (a fully shot family realises at most GUN_BURST_SHARE x root bore + 1; a fully mined family stays at root bore plus/minus 1 — re-derive S14's AC3 fixture in your own suite, do not edit test_s14_splits.gd); AC4 a yield-0 original built through the field still cleaves into nothing (ruling 17); AC5 every chain terminates and a fully shot XL leaves no live family rock; AC6 the gate summary. Report .agents/gen/slices/S16-fragment-resplit/S16-B1_report.md (120 lines max): pre-grep table, per-AC measured numbers, gate SUMMARY before and after, every deviation. No project.godot, no docs, no ui, no addons, no autoload, no ore_tuning.gd writes; shell edits forbidden; every Godot run bounded with --quit-after on its own XDG_DATA_HOME scratch store; never write the profile." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s16_b1.log 2>&1
```

## S16-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S16-fragment-resplit/S16-R1_review.md' \
     crush run "You are worker S16-R1, the mandatory reviewer of wave S16 (brief .agents/gen/slices/S16-fragment-resplit/S16_BRIEF.md; diff findings against docs/gameplay/02_minerals.md section 5.2 ter and section 5.1 Rule A — never against the brief). Re-measure everything yourself (W8 method): AC1 a seeded shot XL's children cleave per their own class, strictly smaller, chain ending at S; AC2 zero units paid and zero pickups through a whole shot chain (grep _pay_burst call sites and prove owed <= 0 on every 0-bore shatter); AC3 conservation both routes — a fully shot family at or below GUN_BURST_SHARE x root bore + 1 and a fully mined family at root bore plus/minus 1 (S14's own AC3 row must be untouched and green; grep _rolled_yield call sites and prove no shatter-side roll survives); AC4 a yield-0 original still cleaves into nothing; AC5 every chain terminates, no live rock behind a fully shot XL; AC6 gate twice on fresh scratch stores plus staging/verify_wave.py verify --baseline s16_start --forbidden vajb-orbit/project.godot docs/ vajb-orbit/ui/ vajb-orbit/addons/ vajb-orbit/autoload/ vajb-orbit/game/ore_tuning.gd --tests --expect-reports .agents/gen/slices/S16-fragment-resplit/S16-B1_report.md .agents/gen/slices/S16-fragment-resplit/S16-R1_review.md. Diff the moved rows against SLICE.md section 3's list — an unlisted row changed is HIGH. Write .agents/gen/slices/S16-fragment-resplit/S16-R1_review.md (REVIEW template, 150 lines max), findings S16-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time; CONTRACTS section 9/10 (and section 5's cleaves sentence) at the next free rows read at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s16_r1.log 2>&1
```

## S16-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S16-fragment-resplit/' \
     crush run "You are worker S16-F1, the fixer of wave S16 (brief .agents/gen/slices/S16-fragment-resplit/S16_BRIEF.md; review .agents/gen/slices/S16-fragment-resplit/S16-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on scratch stores and report .agents/gen/slices/S16-fragment-resplit/S16-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s16_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
