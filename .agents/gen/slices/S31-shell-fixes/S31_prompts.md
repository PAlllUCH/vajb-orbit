# S31_prompts — dispatch blocks (run strictly in order)

All three run with `VAJB_SLIM=1` (code wave: no editor bridge needed). Prompt
bodies live beside this file (`S31-B1_body.txt`, `S31-R1_body.txt`,
`S31-F1_body.txt`). Gate baseline 1093/0.

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot --name s31_start
git add docs/design/UI_SPEC.md docs/design/STATION_HUB.md .agents/gen/slices/S31-shell-fixes .agents/gen/slices/S32-armory-modules
git commit   # "Brief S31+S32: pin the D20 fixes and the armory rework"
git tag s31_start
```

## S31-B1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S31-B1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui,vajb-orbit/tests' crush run "$(cat .agents/gen/slices/S31-shell-fixes/S31-B1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S31-B1.log 2>&1
```

Run in background, block on `job_output wait:true`. Wedged past ~40 min: SIGKILL
the wrapper + inner pid, re-dispatch with an inspect-partial-diff note.

## S31-R1 — `hyper/glm-5.3-flash` @ max → `S31-R1_review.md`

Only after B1's report exists.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests,.agents/gen/slices/S31-shell-fixes/' crush run "$(cat .agents/gen/slices/S31-shell-fixes/S31-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/S31-R1.log 2>&1
```

## S31-F1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S31-F1_report.md`

**Only if the review leaves HIGH or MED.**

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui,vajb-orbit/tests' crush run "$(cat .agents/gen/slices/S31-shell-fixes/S31-F1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S31-F1.log 2>&1
```

## Close-out (orchestrator)

Gate ×2 fresh scratch → `verify_wave.py verify --baseline s31_start` →
`staging/build_code_map.py` if files moved → TICKS.md (T-118–T-123 rows leave
as they close) → WAVEBOARD §Queued row + `MASTER_REPORT.md` §6 recap →
wave-boundary commit.
