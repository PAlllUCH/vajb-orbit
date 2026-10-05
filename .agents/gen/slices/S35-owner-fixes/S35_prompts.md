# S35_prompts — dispatch blocks (S35 runs parallel with D21-G1 generation + D22-P1 integrity; disjoint file sets)

All run with `VAJB_SLIM=1`. Prompt bodies live beside this file.

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot --name s35_start
git add .agents/gen/slices/S35-owner-fixes .agents/gen/slices/D21-chrome-family .agents/gen/slices/D22-screen-integrity docs
git commit   # "Brief S35 + D22 + G1: owner fix round, integrity review, chrome batch"
git tag s35_start
```

## S35-B1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S35-B1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/tests/' crush run "$(cat .agents/gen/slices/S35-owner-fixes/S35-B1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S35-B1.log 2>&1
```

## S35-R1 — `hyper/glm-5.3-flash` @ max → `S35-R1_review.md`

Only after B1's report exists.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,.agents/gen/slices/S35-owner-fixes/' crush run "$(cat .agents/gen/slices/S35-owner-fixes/S35-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/S35-R1.log 2>&1
```

## S35-F1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S35-F1_report.md`

**Only if the review leaves HIGH or MED.** Body is cut from B1's with the
review's fix list appended.

## Close-out (orchestrator)

Gate ×2 fresh scratch → `verify_wave.py verify --baseline s35_start` →
`staging/build_code_map.py` → TICKS refresh → WAVEBOARD row +
`MASTER_REPORT.md` §6 → wave commit. (The chrome build wave is **S36**.)
