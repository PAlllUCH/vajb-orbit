# S32_prompts — dispatch blocks (run strictly in order; S32 runs only after S31 closes — both rewrite `ui/station/`)

All three run with `VAJB_SLIM=1`. Prompt bodies live beside this file
(`S32-B1_body.txt`, `S32-R1_body.txt`, `S32-F1_body.txt`).

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot --name s32_start
git add .agents/gen/slices/S32-armory-modules
git commit   # "Brief S32: the ARMORY two-module rework"
git tag s32_start
```

## S32-B1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S32-B1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui,vajb-orbit/tests' crush run "$(cat .agents/gen/slices/S32-armory-modules/S32-B1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S32-B1.log 2>&1
```

Run in background, block on `job_output wait:true`. Wedged past ~40 min: SIGKILL
the wrapper + inner pid, re-dispatch with an inspect-partial-diff note.

## S32-R1 — `hyper/glm-5.3-flash` @ max → `S32-R1_review.md`

Only after B1's report exists.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests,.agents/gen/slices/S32-armory-modules/' crush run "$(cat .agents/gen/slices/S32-armory-modules/S32-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/S32-R1.log 2>&1
```

## S32-F1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S32-F1_report.md`

**Only if the review leaves HIGH or MED.**

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui,vajb-orbit/tests' crush run "$(cat .agents/gen/slices/S32-armory-modules/S32-F1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S32-F1.log 2>&1
```

## Close-out (orchestrator)

Gate ×2 fresh scratch → `verify_wave.py verify --baseline s32_start` →
`staging/build_code_map.py` → TICKS.md (T-122 closes; T-118–T-123 rows leave as
they close) → WAVEBOARD §Queued row + `MASTER_REPORT.md` §6 recap →
wave-boundary commit.
