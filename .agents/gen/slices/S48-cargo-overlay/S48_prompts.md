# S48_prompts — the wave's dispatch lines

Run before the first dispatch (the orchestrator, after S47's close-out):
`python3 staging/verify_wave.py snapshot --name s48_start` + wave-boundary
commit of S47.

## S48-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/dialogs/cargo_overlay.gd,vajb-orbit/ui/dialogs/cargo_overlay.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/test_s48_cargo_overlay.gd" crush run "You are worker S48-V0. Read .agents/gen/slices/S48-cargo-overlay/S48-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S48-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S48-R0. Read .agents/gen/slices/S48-cargo-overlay/S48-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed).
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s48_start --expect-reports
   .agents/gen/slices/S48-cargo-overlay/S48-V0_report.md
   .agents/gen/slices/S48-cargo-overlay/S48-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
