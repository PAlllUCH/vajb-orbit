# S45_prompts — the wave's dispatch lines (two sequential builders, one reviewer)

Run before the first dispatch (the orchestrator, after S44's close-out):
`python3 staging/verify_wave.py snapshot --name s45_start` + wave-boundary
commit of S44.

## S45-V0 (builder 1 — the panel controls + the refinery model seam)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/refinery_panel.tscn,vajb-orbit/game/refinery.gd,vajb-orbit/tests/test_s45_refinery.gd" crush run "You are worker S45-V0. Read .agents/gen/slices/S45-refinery-craft/S45-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S45-W0 (builder 2 — the CRAFT model + list; only after V0's report is read)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/refinery_panel.tscn,vajb-orbit/game/crafting_catalog.gd,vajb-orbit/tests/test_s45_craft.gd" crush run "You are worker S45-W0. Read .agents/gen/slices/S45-refinery-craft/S45-W0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S45-R0 (reviewer — after W0)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S45-R0. Read .agents/gen/slices/S45-refinery-craft/S45-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed); TICKS: T-175's REFINERY rows verified/closed.
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s45_start --expect-reports
   .agents/gen/slices/S45-refinery-craft/S45-V0_report.md
   .agents/gen/slices/S45-refinery-craft/S45-W0_report.md
   .agents/gen/slices/S45-refinery-craft/S45-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
