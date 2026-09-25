# S15_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane) on
`--reasoning-effort high`. Run order **B1 → R1 → (F1 only on HIGH/MED)**.
`$VAJB_WORKSPACE` resolves from `crushrc`. Every `crush run` is launched with
`run_in_background: true` and **waited on** (`job_output`, `wait: true`) before
the next step or the end of the session — the coder skill's "Worker lifecycle"
section is the law.

**Before the first dispatch:** S15 shares S14's pre-dispatch block (both
snapshots, one commit, both tags) — it lives in
`slices/S14-debris-splits/S14_prompts.md` and already stages this slice folder
and the two docs this wave amends through its pin.

## S15-B1 — the hardcap and the armory rework

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/autoload/,vajb-orbit/ui/station/,vajb-orbit/tests/,.agents/gen/slices/S15-battery-cap/S15-B1_report.md' \
     crush run "You are worker S15-B1 on the Vajb Orbit workspace, wave S15. Read .agents/gen/slices/S15-battery-cap/S15_BRIEF.md end to end — its section 2's rules 1-4 bind every line you write — then SLICE.md, then docs/gameplay/09_ship_slots_modules.md section 12 and docs/design/STATION_HUB.md section 5.11's 2026-09-25 amendment by range. Task: (1) the hardcap — game/weapons.gd GROUPS_MAX becomes 5 with a new BATTERY_CELLS_MAX := 4 beside it; composing a 6th battery or a 5th cell in one refuses through the existing transaction shape and writes nothing (the armory drop zones and the fitting panel rack drops both enforce it). (2) The profile clamp — autoload/player_profile.gd clamps to 5 groups times 4 cells on load, cell order preserved; prove the gate is byte-identical on a scratch store carrying an old 7-group save. (3) The armory — five bays flowing 4+1 (RACK_COUNT already reads GROUPS_MAX), labels B1..B5 aligned 1:1 with the cockpit's five lamps (rack i lights lamp i through _select_weapon; weapon_6/weapon_7 become inert, never edit project.godot). (4) The plate-fit correction (brief rule 4): lay the bay's slots, ledge and SALVO drums against ui_armory_rack_plate's ink (canvas 194x182, ink rows 49..132, drawn slot pitch about 34.5 px) or re-render the plate to fill the canvas — pick one route and measure it; the approved look is staging/mockup/out/armory_mockup.png bay 1. (5) Tests: pre-grep section 3's rows and report each before editing; move only the listed rows; add tests/test_s15_battery_cap.gd (AC1-AC3, the refusal-is-silent proof) and tests/test_s15_armory_layout.gd (AC4-AC5 with the measured ink rows before and after); keep test_d7_cockpit.gd's lamp rows green untouched. Report .agents/gen/slices/S15-battery-cap/S15-B1_report.md (120 lines max): pre-grep table, per-AC measured values, gate SUMMARY before and after, every deviation and which plate-fit route you took. No project.godot, no docs, no ui/hud, no ui/screens writes; shell edits forbidden; every Godot run bounded with --quit-after on its own XDG_DATA_HOME scratch store." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s15_b1.log 2>&1
```

## S15-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S15-battery-cap/S15-R1_review.md' \
     crush run "You are worker S15-R1, the mandatory reviewer of wave S15 (brief .agents/gen/slices/S15-battery-cap/S15_BRIEF.md; diff findings against docs/gameplay/09_ship_slots_modules.md section 12 and docs/design/STATION_HUB.md section 5.11's amendment — never against the brief). Re-measure everything yourself (W8 method): AC1 the cap (a 6th battery and a 5th cell both refuse silently — the profile bytes are identical after each attempt), AC2 the 7-cell hull composes 4+3 with launch and ammo read-back intact and the hull W-cell rows unmoved, AC3 the clamp (an old 7-group save loads to 5x4 with cell order preserved; the gate byte-identical on such a store), AC4 the armory (5 bays 4+1, B1..B5 labels, slot block inside ink rows 49..132 at about 34.5 px pitch plus or minus 2, drums bottom-aligned to the ink edge — re-measure the plate yourself from the PNG), AC5 the 1:1 lamp alignment (rack i lights lamp i; test_d7_cockpit rows green untouched), AC6 gate twice on scratch stores plus staging/verify_wave.py verify --baseline s15_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/15_module_affixes.md docs/gameplay/04_refinery.md docs/design/ ui/hud/ ui/screens/ addons/ --tests --expect-reports .agents/gen/slices/S15-battery-cap/S15-B1_report.md .agents/gen/slices/S15-battery-cap/S15-R1_review.md (the parallel S14 lane's touched files are attributed, never reverted). Diff the moved rows against SLICE.md section 3's list — an unlisted row changed is HIGH. Write .agents/gen/slices/S15-battery-cap/S15-R1_review.md (REVIEW template, 150 lines max), findings S15-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time; CONTRACTS section 9/10 next free rows read at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s15_r1.log 2>&1
```

## S15-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/autoload/,vajb-orbit/ui/station/,vajb-orbit/ui/hud/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S15-battery-cap/' \
     crush run "You are worker S15-F1, the fixer of wave S15 (brief .agents/gen/slices/S15-battery-cap/S15_BRIEF.md — its section 3's ratified-rows note binds you; review .agents/gen/slices/S15-battery-cap/S15-R1_review.md). Fix ONLY the HIGH and MED findings. F1 at its root in ui/hud/hud.gd — a refused rack ordinal 6 or 7 must clear the active lamp instead of leaving the last one lit — and tests/test_d7_cockpit.gd:348-353 return to their original pre-S15 form (git diff shows the builder's change; the developer session granted ui/hud for this root fix). F2 needs no code: the rows are ratified in the brief's section 3, disposition them as closed-by-ratification. F3 vajb-orbit/autoload/player_profile.gd:1255-1258 — the derived tail must cover every fitted cell so no weapon is ever rackless, so a 7-cell hull composes 4+3 covering all seven cells. F4 vajb-orbit/ui/station/armory_style.gd:186-196 — the tail bay draws full-width per docs/design/STATION_HUB.md section 5.11's amendment. Adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on scratch stores and report .agents/gen/slices/S15-battery-cap/S15-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s15_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
