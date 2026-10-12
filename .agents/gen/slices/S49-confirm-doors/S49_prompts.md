# S49_prompts — the wave's dispatch lines

Run before the first dispatch (the orchestrator, after S48's close-out):
`python3 staging/verify_wave.py snapshot --name s49_start` + wave-boundary
commit of S48. Docs-first rider at the same boundary: UI_SPEC §17 gains
T-186's craft-door worked example (`ARE YOU SURE YOU WANT TO CRAFT REACTOR MK3
FOR 2× MECHANICAL COMPONENTS · 1× POWER CELL · 6× COBALT INGOT + 2 500 CR
LABOUR?`) — the developer's own one-line edit, disclosed.

## S49-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/insurance_panel.gd,vajb-orbit/ui/station/vaults_panel.gd,vajb-orbit/tests/test_s49_confirm_doors.gd" crush run "You are worker S49-V0. Read .agents/gen/slices/S49-confirm-doors/S49-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S49-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S49-R0. Read .agents/gen/slices/S49-confirm-doors/S49-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed); TICKS: T-186 closed by the docs-first amendment.
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s49_start --expect-reports
   .agents/gen/slices/S49-confirm-doors/S49-V0_report.md
   .agents/gen/slices/S49-confirm-doors/S49-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
