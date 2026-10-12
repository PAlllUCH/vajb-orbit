# S44_prompts — the wave's dispatch lines

Run before the first dispatch (the orchestrator, after S43's close-out):
`python3 staging/verify_wave.py snapshot --name s44_start` + wave-boundary
commit of S43. Docs-first rider done at the same boundary: STATION_HUB §23.7
gains T-190's one-line ink amendment (`text_primary` mark) — the developer's
own edit, disclosed in the wave report.

## S44-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/exchange_panel.tscn,vajb-orbit/tests/test_s44_exchange_bulk.gd" crush run "You are worker S44-V0. Read .agents/gen/slices/S44-exchange-bulk-sell/S44-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S44-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S44-R0. Read .agents/gen/slices/S44-exchange-bulk-sell/S44-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed); TICKS: T-175's EXCHANGE row verified/closed, T-190 closed by
   the docs-first amendment.
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s44_start --expect-reports
   .agents/gen/slices/S44-exchange-bulk-sell/S44-V0_report.md
   .agents/gen/slices/S44-exchange-bulk-sell/S44-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
