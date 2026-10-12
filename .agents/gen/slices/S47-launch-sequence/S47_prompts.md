# S47_prompts — the wave's dispatch lines

Run before the first dispatch (the orchestrator, after S46's close-out):
`python3 staging/verify_wave.py snapshot --name s47_start` + wave-boundary
commit of S46.

## Orchestrator prep before the builder (not a worker)
1. Source the raw Kenney takes (CC0, via assetmcp; the Kenney Impact Sounds
   and Sci-Fi Sounds packs) into `asset-library/raw/` with manifest rows.
2. Extend `staging/audio/build_audio.py`'s table with S27/S28 rows; build
   (`uv` venv with `imageio-ffmpeg`, `numpy`, `soundfile`), then
   `staging/audio/set_loop_flags.py`, then the reimport (editor open →
   `filesystem_manage reimport`; editor closed → headless `--editor --quit`).
3. Record the derivation + provenance in
   `vajb-orbit/assets/audio/generation_log_audio.md`; regenerate
   `docs/design/ASSET_CATALOG.md` (`staging/phase_d/build_catalog.py`).
4. Flip this slice's briefs `draft → ready`.

## S47-V0 (builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/station/launch_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/test_s47_launch_sequence.gd" crush run "You are worker S47-V0. Read .agents/gen/slices/S47-launch-sequence/S47-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## S47-R0 (reviewer — after the builder)
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S47-R0. Read .agents/gen/slices/S47-launch-sequence/S47-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```

## Close-out (orchestrator, not a worker)
1. Developer bucket-2 re-cuts of any premise rows the wave obsoleted
   (disclosed); TICKS: T-174/T-185 closed, T-188 re-presented (docs).
2. `python3 staging/gate.py --times 2` → byte-identical, zero SCRIPT ERROR.
3. `python3 staging/verify_wave.py verify --baseline s47_start --expect-reports
   .agents/gen/slices/S47-launch-sequence/S47-V0_report.md
   .agents/gen/slices/S47-launch-sequence/S47-R0_review.md --forbidden docs`
4. `python3 staging/build_code_map.py`
5. WAVEBOARD + TICKS + LOW_BACKLOG refresh; wave-boundary commit.
