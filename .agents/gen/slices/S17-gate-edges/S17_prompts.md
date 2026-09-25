# S17_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (coder lane, owner ruling
2026-09-24) on `--reasoning-effort high`. Run order **B1 → R1 → (F1 only on
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
  && python3 staging/verify_wave.py snapshot --name s17_start \
  && git tag s17_start
```

## S17-B1 — the edge placement

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/sector.gd,vajb-orbit/tests/,.agents/gen/slices/S17-gate-edges/S17-B1_report.md' \
     crush run "You are worker S17-B1 on the Vajb Orbit workspace, wave S17 (jump gates to sector edges). Read .agents/gen/slices/S17-gate-edges/S17_BRIEF.md end to end — its section 2's five rules bind every line you write — then SLICE.md, then docs/gameplay/11_galactic_map.md section 6 (the pin) and sections 2.1/2.2/5 by range. Task: (1) the pinned placement in vajb-orbit/game/sector.gd exactly — _add_gate's position line becomes centre + bearing * _edge_reach(bearing) with a new private _edge_reach helper (per-axis half-minus-FIELD_EDGE_MARGIN over abs component, minimum of the two axes, zero-component guarded); GATE_RING_RADIUS retires with its comment; _gate_bearing, the beacon block, _spawn_pois, gates, the minimap mapping and populate stay byte-identical; vajb-orbit/game/gate.gd and vajb-orbit/game/sector_registry.gd are forbidden files you never open for writing. (2) Tests: pre-grep section 3's candidate rows and report every one's route and verdict BEFORE editing — no existing gate row moves; any row that must change is a bucket-2 pause you report, never edit. Add tests/test_s17_gate_edges.gd proving SLICE.md's AC1-AC6 on seeded registry sectors (S14's suite as the pattern; expected positions re-derived in the suite, never by calling the field's helper): AC1 every gate on its link's bearing at the 800 u border inset (cardinal spine: plus/minus 4200 on the link axis); AC2 no gate's 200 u trigger circle enters a corridor band's interior (tangent allowed, 600+200=800) and every gate inside the arena; AC3 one beacon per gate at the byte-identical formula, inside the arena, inside the link's corridor band; AC4 same gates — count equals gate_links size, names and destinations unchanged across all seven registry rows; AC5 the wiring blip row stays green with friendly blips at the new positions; AC6 the gate summary (GATE_RING_RADIUS gone, FIELD_EDGE_MARGIN 800 and BEACON_GATE_OFFSET 300 unchanged, the two forbidden files byte-identical). (3) Run the gate twice on fresh scratch stores before and after (XDG_DATA_HOME from mktemp, --quit-after 1200): baseline 866/0, after = 866 plus your new rows, zero failures, no other suite's count moved. Report .agents/gen/slices/S17-gate-edges/S17-B1_report.md (REPORT template, 120 lines max): the pre-grep table, per-AC measured values, the gate before/after, every deviation." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s17_b1.log 2>&1
```

## S17-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S17-gate-edges/S17-R1_review.md' \
     crush run "You are worker S17-R1, the mandatory reviewer of wave S17 (brief .agents/gen/slices/S17-gate-edges/S17_BRIEF.md; diff findings against docs/gameplay/11_galactic_map.md section 6 — never against the brief). Re-measure everything yourself (W8 method): AC1 placement on seeded sectors with independently re-derived expected positions; AC2 trigger-versus-band clearance, interiors disjoint, tangent allowed; AC3 beacons at the byte-identical formula, in-arena, in-band; AC4 same gates across all seven rows; AC5 the wiring blip row; AC6 gate twice on fresh scratch stores plus staging/verify_wave.py verify --baseline s17_start --forbidden vajb-orbit/project.godot docs/ vajb-orbit/ui/ vajb-orbit/addons/ vajb-orbit/autoload/ vajb-orbit/game/gate.gd vajb-orbit/game/sector_registry.gd --tests --expect-reports .agents/gen/slices/S17-gate-edges/S17-B1_report.md .agents/gen/slices/S17-gate-edges/S17-R1_review.md. Grep that _add_gate is the only placement change in sector.gd (no caller of _gate_bearing, no beacon edit, no populate edit) and that gate.gd and sector_registry.gd are byte-identical. Diff the moved rows against SLICE.md section 3's list — an unlisted row changed is HIGH. Update docs/CONTRACTS.md section 19's placement paragraph (the 900 u ring value is retired; report the live placement values, not invented ones) and section 9/10 at the next free rows read at write time. Write .agents/gen/slices/S17-gate-edges/S17-R1_review.md (REVIEW template, 150 lines max), findings S17-B1/F## with tier and one evidence line each, LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s17_r1.log 2>&1
```

## S17-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S17-gate-edges/' \
     crush run "You are worker S17-F1, the fixer of wave S17 (brief .agents/gen/slices/S17-gate-edges/S17_BRIEF.md; review .agents/gen/slices/S17-gate-edges/S17-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed; gate.gd and sector_registry.gd stay byte-identical. Re-run the gate twice on scratch stores and report .agents/gen/slices/S17-gate-edges/S17-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s17_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
