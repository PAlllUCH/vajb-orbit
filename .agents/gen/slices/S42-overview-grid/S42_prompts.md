# S42_prompts — the wave's dispatch lines (the owner never pastes these)

Run before the first dispatch (already done 2026-10-12, commit cbbc673):
`python3 staging/verify_wave.py snapshot --name s42_start`.

## S42-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/ui/station/overview_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/test_s42_overview_grid.gd" crush run "You are worker S42-V0. Read .agents/gen/slices/S42-overview-grid/S42-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S42-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S42-R0. Read .agents/gen/slices/S42-overview-grid/S42-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts: `tests/test_s30_shell.gd` (the six-tile block row
   + the service-rows name row), `tests/test_s40_legibility.gd` (the A3 glyph
   row's tinted branch), `tests/test_s41_panels_a.gd` (the F1 fold row) —
   re-pointed at the landed tree, disclosed.
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s42_start --expect-reports
   .agents/gen/slices/S42-overview-grid/S42-V0_report.md .agents/gen/slices/S42-overview-grid/S42-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
