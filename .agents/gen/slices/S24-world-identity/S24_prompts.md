# S24_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` on `--reasoning-effort max`.
Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s24_start \
  && git tag s24_start
```

## S24-B1 — world identity (A1–A5)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S24-world-identity/S24-B1_report.md' \
     crush run "You are worker S24-B1 on the Vajb Orbit workspace, wave S24 (world identity: stations, factions, nebula). Read .agents/gen/slices/S24-world-identity/S24_BRIEF.md end to end - its section 4's five rules bind every line you write - then SLICE.md. Task: land A1-A5 exactly. A1: the nine docking places become entities carrying their R-S24-1 names and character, their faction's 14 section 1/8 service matrix (outposts get the three-service subset), and their owner's 12 section 2/3 multipliers (Meridian commission 1.5 percent, the three demand flavours, the section 5 minus-15-percent tech discounts, the shelf bias hook) behind one station accessor; panel layout does not move (rule 1). A2: every 12 section 4.1 band effect live and probed (dock refusal at -51 with the two-axis rule intact, Shunned prices and the contracts_visible seam, Known's hot-slot x1.5 and the +5 percent pay hook, Trusted's -5 percent and reserved slot, Champion's -10 percent and the x0.8 insurance hook). A3: per-sector hostile bands per R-S24-2 (HOSTILE_FILL becomes per-sector; densities stay 13 section 4's; hunters stay heat-driven). A4: nebula per R-S24-3 (0-2 clouds per sector; inside: radar and lock x0.5 and a 15 percent hull tint; probe both range values). A5: the accessor contract and the S25/S26 seams documented in the report. The P3-block rows in docs 14/13/11 are the only new values (ticks W1-W3 default PROPOSED). Docs and autoload/ are read-only. New suite tests/test_s24_world.gd (one row per AC); headless gate twice on fresh scratch XDG_DATA_HOME stores, both [SUMMARY] lines recorded. Report slices/S24-world-identity/S24-B1_report.md (REPORT template, 120 lines max) answering A1-A5 with cites." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_b1.log 2>&1
```

## S24-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S24-world-identity/S24-R1_review.md' \
     crush run "You are worker S24-R1, the mandatory reviewer of wave S24 (brief .agents/gen/slices/S24-world-identity/S24_BRIEF.md; diff findings against its section 5 extract and the 2026-09-27 P3 blocks, never against B1's report). Grade A1-A5 first, re-measuring yourself on scratch stores (W8's byte-identical replay): each of the nine stations' name/faction/services/multipliers against 14 section 1/8 and 12 section 2/3 (probe the 1.5 percent Meridian commission and the missing Choir insurance), every band effect in both directions (a -51 standing refused at dock while a clean-heat Outlaw buys a gate ticket), each sector's hostile band roll with 13 section 4's densities intact, and the nebula ranges inside/outside a cloud. Diff moved gate rows against section 8's list; an unlisted row moved or a pinned value that moved is HIGH. A price or service that moved without its P3 row is HIGH. Update docs/CONTRACTS.md section 9/10 at the next free rows read at write time. Write slices/S24-world-identity/S24-R1_review.md (REVIEW template, 150 lines max), findings S24-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_r1.log 2>&1
```

## S24-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S24-world-identity/' \
     crush run "You are worker S24-F1, the fixer of wave S24 (brief .agents/gen/slices/S24-world-identity/S24_BRIEF.md; review .agents/gen/slices/S24-world-identity/S24-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S24-world-identity/S24-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 30 only — S24 world identity. Brief: .agents/gen/slices/S24-world-identity/S24_BRIEF.md. Prompts: .agents/gen/slices/S24-world-identity/S24_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 31. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s24_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
