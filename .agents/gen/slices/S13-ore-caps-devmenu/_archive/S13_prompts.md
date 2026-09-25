# S13_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort high`. Run order **B1 → B2 → R1 → (F1 only on
HIGH/MED)**. Every line sets `VAJB_SLIM=1` and `VAJB_WORKER_FILES` to that
worker's own set plus its report path. `$VAJB_WORKSPACE` resolves from
`crushrc`; substitute the workspace root if your shell has not sourced it.

**Before the first dispatch** (this stages only this wave's files; any other
dirty file belongs to another lane and is left alone):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s13_start \
  && git add docs/gameplay/01_economy_core.md docs/gameplay/02_minerals.md \
       .agents/gen/slices/S13-ore-caps-devmenu .agents/gen/dispatch_coder.md \
       .agents/gen/_state/WAVEBOARD.md \
  && git commit -m "docs: tick the ore caps and defer the rock-scale questions" \
  && git tag s13_start
```

## S13-B1 — the game side: caps, reserve split, mining batteries, ring 175

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S13-ore-caps-devmenu/S13-B1_report.md' \
     crush run "You are worker S13-B1 on the Vajb Orbit workspace, wave S13. Read .agents/gen/slices/S13-ore-caps-devmenu/S13_BRIEF.md end to end — its section 2's rules 1-5 and 7 bind every line you write — then SLICE.md, then docs/gameplay/01_economy_core.md section 5.6 and docs/gameplay/02_minerals.md section 5.1 Rule A by range. Task, in order: (1) create vajb-orbit/game/ore_tuning.gd exactly the pinned interface (section 2 code block — defaults equal the owner files' declared consts). (2) Implement the setup split, the shatter attribution and the reserve rules (rules 2-3): extraction realises only extractable; a mining-attributed shatter pays the full reserve (Small as pickups, M/L by children whose summed yield equals the parent reserve, split across FRAGMENT_SPLIT counts, no fresh roll, compounding down the cascade); a gun-attributed shatter pays at most OreTuning.gun_burst_share times _bore_ore, excess reserve burns; payouts carry float credit per field and pay whole pickup units only. (3) Multi-mining (rule 5): N fitted w_mining modules deliver N times the work per cycle — the named suspects are player_ship.gd:208, player_ship.gd:1289-1291 and mining_laser.gd's single _cycle; document your route and never double-pay. (4) Ring (rule 7): game/sector.gd:73 DOCK_RING_RADIUS becomes 175.0. (5) Repoint live arithmetic to OreTuning (rule 1: the consts stay declared; no circular preload). (6) Tests: pre-grep section 3's rows and report each before editing; move only the listed rows, add tests/test_s13_caps.gd (rules 2-4, AC1/AC2/AC6) and tests/test_s13_mining_batteries.gd (AC3, probe-measured 1x/2x/3x within 20 percent); keep test_engine2_cleaving.gd:302,332-338 and test_combat_repair_c5.gd green untouched. Report .agents/gen/slices/S13-ore-caps-devmenu/S13-B1_report.md (template REPORT.md, 120 lines max): the pre-grep table, per-AC measured values (the gun legs' delivered over sum _bore_ore, the family realisation factor that S12 measured at 4.0, the N-scaling rates), the gate SUMMARY before and after, every deviation. No project.godot, no ui/ writes, no docs/ writes, shell edits forbidden; every Godot run bounded with --quit-after on its own XDG_DATA_HOME scratch store." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s13_b1.log 2>&1
```

## S13-B2 — the dev overlay (after B1 ships ore_tuning.gd)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/dev/,vajb-orbit/tests/test_s13_devmenu.gd,.agents/gen/slices/S13-ore-caps-devmenu/S13-B2_report.md' \
     crush run "You are worker S13-B2 on the Vajb Orbit workspace, wave S13. Read .agents/gen/slices/S13-ore-caps-devmenu/S13_BRIEF.md end to end — section 2's rule 6 is your contract — then SLICE.md, then vajb-orbit/game/ore_tuning.gd (B1 just shipped it; it is the API, invent nothing beside it). Task: build the developer tuning overlay. (1) vajb-orbit/ui/dev/dev_tuning_menu.gd (+ scene if you need one): a CanvasLayer overlay toggled by raw KEY_F1 in _unhandled_key_input — NO project.godot edit, no InputMap action. On open it loads and applies user://dev_tuning.cfg if present; a Save button writes it; a Reset button calls OreTuning.reset_to_defaults() and deletes the file; a TUNED badge shows while any field differs from default. Sliders cover every OreTuning field (gun_burst_share 0..1, fragment_core_share 0..1, gun_chip_rate 0..0.5, mine_cycle 0.2..3.0, work_per_unit 0.25..4.0, tier_base_yield four int sliders 1..12, yield_variance_min/max 0..2, pickup_burst x/y 0..6) with live apply and the current value printed. The overlay never pauses the game and touches no shipped UI file. (2) tests/test_s13_devmenu.gd: the overlay toggles on the keypress, sliders write OreTuning, save/load round-trips, reset restores defaults and removes the file, and the gate-hermeticity guard — the file is never read at boot, so default-path behaviour is unchanged on a store carrying it (AC4). Report .agents/gen/slices/S13-ore-caps-devmenu/S13-B2_report.md (120 lines max) with the control table, the per-AC proof and the gate SUMMARY before and after. No game/ writes beyond reading ore_tuning.gd, no project.godot, no docs/, shell edits forbidden, every Godot run bounded on its own scratch store." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s13_b2.log 2>&1
```

## S13-R1 — mandatory review (after B2 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S13-ore-caps-devmenu/S13-R1_review.md' \
     crush run "You are worker S13-R1, the mandatory reviewer of wave S13 (brief .agents/gen/slices/S13-ore-caps-devmenu/S13_BRIEF.md; diff findings against docs/gameplay/01_economy_core.md section 5.6 + docs/gameplay/02_minerals.md section 5.1 Rule A and CONTRACTS section 5 — never against the brief). Re-measure everything yourself (W8's method): AC1 the gun cap (a seeded field worked by 3 cannons: delivered pickups <= 0.10 x sum _bore_ore + 1; S12's 0.714 per-rock row moved to <= 0.10), AC2 budget conservation (a fully mined cascade realises <= root _bore_ore + 1; no fresh roll anywhere in _cleave — grep for _rolled_yield call sites and prove the only remaining rolls are setup-side), AC3 N-scaling (1/2/3 mining modules within 20 percent of N x; no double-pay: total realised never exceeds the budget), AC4 the overlay (raw KEY_F1, no project.godot diff — git diff must show none; user://dev_tuning.cfg read only on open; the gate byte-identical with that file present on the store), AC5 the radius (175.0 at sector.gd:73 and all three readers), AC6 the anti-drift assertions green, AC7 gate twice on scratch stores and verify_wave.py verify --baseline s13_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md docs/gameplay/04_refinery.md docs/design/ ui/station/ ui/screens/ ui/hud/ --tests --expect-reports .agents/gen/slices/S13-ore-caps-devmenu/S13-B1_report.md .agents/gen/slices/S13-ore-caps-devmenu/S13-B2_report.md .agents/gen/slices/S13-ore-caps-devmenu/S13-R1_review.md. Grep the moved rows against SLICE.md section 3's list — any row outside it changed is HIGH. Write .agents/gen/slices/S13-ore-caps-devmenu/S13-R1_review.md (REVIEW template, 150 lines max), findings as S13-B1/F## or S13-B2/F## with a tier and one evidence line each, LOW rows appended to .agents/gen/_state/LOW_BACKLOG.md at the next free ids read at write time (never deleting a row). You own three docs writes: CONTRACTS section 5's two sentences (line 350's fragment re-roll becomes the reserve split; line 374's gun-work sentence names the GUN_BURST_SHARE cap) and CONTRACTS section 9/10's next free rows read at write time; plus a PROPOSED-WORDING block in your review for the owner-locked 18_engine_spec.md section 6/section 13/section 17 sentences that the caps contradict (quote each old sentence and your proposed replacement — you may not edit that file). Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s13_r1.log 2>&1
```

## S13-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/dev/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S13-ore-caps-devmenu/' \
     crush run "You are worker S13-F1, the fixer of wave S13 (brief .agents/gen/slices/S13-ore-caps-devmenu/S13_BRIEF.md; review .agents/gen/slices/S13-ore-caps-devmenu/S13-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed, no file outside your set. Re-run the gate twice on scratch stores and report .agents/gen/slices/S13-ore-caps-devmenu/S13-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s13_f1.log 2>&1
```

`crush run` prints only narration into these logs; poll with `pgrep -af 'worker
S13-'` and read each report when its process exits. Never end the session while
a worker is in flight.
