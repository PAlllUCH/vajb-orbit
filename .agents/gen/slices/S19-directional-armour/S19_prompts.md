# S19_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort max`. Run order **B1 → R1 → (F1 only on
HIGH/MED)**. `$VAJB_WORKSPACE` resolves from `crushrc`. Every `crush run` is
launched with `run_in_background: true` and **waited on** (`job_output`,
`wait: true`) before the next step or the end of the session. If a worker
wedges (0 sockets, frozen `/proc/<pid>/io`, ~0 CPU-sec), kill it with python
SIGKILL — the wrapper AND the inner `bin/crush run` pid — then re-dispatch;
re-check `git status` and the report file after any kill.

**Before the first dispatch** (the five-piece is already committed; this
takes the baseline and the evidence tag):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s19_start \
  && git tag s19_start
```

## S19-B1 — the quadrants, the malfunctions, the readouts

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/player_state.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/repairs.gd,vajb-orbit/ui/station/repairs_panel.gd,vajb-orbit/ui/hud/ship_status_screen.gd,vajb-orbit/tests/,.agents/gen/slices/S19-directional-armour/S19-B1_report.md' \
     crush run "You are worker S19-B1 on the Vajb Orbit workspace, wave S19 (directional armour and breach malfunctions, ruling 23). Read .agents/gen/slices/S19-directional-armour/S19_BRIEF.md end to end — its section 2's five rules bind every line you write — then SLICE.md, then docs/gameplay/09_ship_slots_modules.md section 3.3's 2026-09-26 amendment (the pin) and docs/gameplay/01_economy_core.md section 6's 2026-09-26 amendment. Task: (1) The pinned design exactly — in vajb-orbit/game/player_state.gd four armour pools of hull_max/4 (P1) fed by set_hull's proportional redistribution (hull == sum(pools) is an invariant, death flow and every signal unchanged); damage(amount, bypass_shield, ctx) routes by ctx.direction (signed [-PI,PI] per damage.gd's bearing, which stands byte-identical — damage.gd, npc_ship.gd, npc_brain.gd and weapons.gd are forbidden files you never open for writing) into prow |d| <= pi/4, stern |d| >= 3pi/4, starboard pi/4 < d < 3pi/4, port the mirror (P2), a missing or zero direction reading 0.0 dead ahead = prow = x1.0 so every direction-less hit keeps today's numbers; |d| >= 5pi/9 (the pinned 160-degree rear arc) multiplies the incoming amount x1.6 before the shield-first absorb (P3), the shield keeps its no-carry-over rule and the routed pool takes the rest with an emptying hit's remainder spilling evenly over the other three (P6). In vajb-orbit/game/player_ship.gd the breach malfunctions are derived state (pool at 0 runs its effect, pool above 0 ends it, no flags): stern breach = RCS drift, a random-sign torque of 15% of the hull's max turn torque through _apply_torque every 2.0 s (P4); prow breach = engine flicker, 15% of thrust application ticks ignore the thrust, joining the thrust-ignore gate the Emergency Flight Mode uses, the roll seeded/injectable for deterministic tests; port/starboard breach = the turn rate toward the breached side clipped to x0.5 (P5). In vajb-orbit/game/repairs.gd repair() restores all four pools to hull_max/4 (01 section 6's fee law unchanged); vajb-orbit/ui/station/repairs_panel.gd's _build_report_rows gains four per-quadrant lines; vajb-orbit/ui/hud/ship_status_screen.gd appends four pool rows (P8, P7 = player-side only, NpcShip hulls stay flat). Every new const is named in the P1-P8 list with its value and one-line reversal; no other tunable appears. (2) Tests: pre-grep section 3's candidate rows and report every one's route and verdict BEFORE editing — no existing row moves; any row that must change is a bucket-2 pause you report, never edit. Add tests/test_s19_quadrants.gd proving SLICE.md's AC1-AC6 with seeded RNG and scratch stores (expected values re-derived in the suite): AC1 routing at each arc's interior and both boundary angles plus the direction-less default; AC2 x1.6 inside/outside the 160-degree arc and before the shield; AC3 pool absorb and spill arithmetic with hull == sum after every step and died firing once; AC4 each malfunction with its seeded roll, the 2.0 s drift cadence, and the derived-clear on repair; AC5 the repair restore plus the fee law rows staying green and both readouts listing four entries without moving an existing row; AC6 the const table and the four forbidden files byte-identical. (3) Run the gate twice on fresh XDG_DATA_HOME scratch stores (never boot the live profile) before/after, bounded with --quit-after. Report .agents/gen/slices/S19-directional-armour/S19-B1_report.md (REPORT template, 120 lines max): the pre-grep table, per-AC measured values, the P1-P8 const table with reversals, both [SUMMARY] lines, every deviation. Docs and numbers are read-only: a value you disagree with is reported, never edited." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s19_b1.log 2>&1
```

## S19-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S19-directional-armour/S19-R1_review.md' \
     crush run "You are worker S19-R1, the mandatory reviewer of wave S19 (brief .agents/gen/slices/S19-directional-armour/S19_BRIEF.md; diff findings against docs/gameplay/09_ship_slots_modules.md section 3.3's 2026-09-26 amendment — never against the brief). Re-measure everything yourself (W8 method, seeded rolls, scratch stores): AC1 routing at interior and boundary angles plus the direction-less default; AC2 the x1.6 inside/outside the 160-degree arc, applied before the shield; AC3 the absorb/spill arithmetic with hull == sum(pools) after every step and one died emit; AC4 each breach malfunction with its seeded roll, the 2.0 s drift cadence through _apply_torque, and the derived-clear when the pool lifts above 0; AC5 the repair restore with the 01 section 6 fee rows unchanged and the two four-entry readouts append-only; AC6 the P1-P8 const table and damage.gd, npc_ship.gd, npc_brain.gd, weapons.gd byte-identical (grep their hashes). Diff the moved gate rows against SLICE.md section 3's list — an unlisted row changed is HIGH, and any damage number that moved for a direction-less or out-of-arc hit is HIGH. Update docs/CONTRACTS.md section 8.1 (the PlayerState additions: pools, routing, breach readers) and section 18 (the status screen rows) plus section 9/10 at the next free rows read at write time. Write .agents/gen/slices/S19-directional-armour/S19-R1_review.md (REVIEW template, 150 lines max), findings S19-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s19_r1.log 2>&1
```

## S19-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S19-directional-armour/' \
     crush run "You are worker S19-F1, the fixer of wave S19 (brief .agents/gen/slices/S19-directional-armour/S19_BRIEF.md; review .agents/gen/slices/S19-directional-armour/S19-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed; damage.gd, npc_ship.gd, npc_brain.gd and weapons.gd stay byte-identical. Re-run the gate twice on scratch stores and report .agents/gen/slices/S19-directional-armour/S19-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s19_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
