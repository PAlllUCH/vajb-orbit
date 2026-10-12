# S43_prompts — the wave's dispatch lines

Run before the first dispatch (the orchestrator, after S42's close-out):
`python3 staging/verify_wave.py snapshot --name s43_start` + wave-boundary
commit of S42.

## S43-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/armory_panel.tscn,vajb-orbit/tests/test_s43_armory_equipped.gd" crush run "You are worker S43-V0. Read .agents/gen/slices/S43-armory-equipped/S43-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S43-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S43-R0. Read .agents/gen/slices/S43-armory-equipped/S43-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed).
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s43_start --expect-reports
   .agents/gen/slices/S43-armory-equipped/S43-V0_report.md
   .agents/gen/slices/S43-armory-equipped/S43-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
