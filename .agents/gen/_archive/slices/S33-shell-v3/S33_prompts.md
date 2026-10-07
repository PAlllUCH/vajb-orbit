# S33_prompts — dispatch blocks (S33 runs beside D21 — disjoint file sets — and strictly before S34)

All three run with `VAJB_SLIM=1`. Prompt bodies live beside this file
(`S33-B1_body.txt`, `S33-R1_body.txt`; `S33-F1_body.txt` is cut from B1's at
need).

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot --name s33_start
git add .agents/gen/slices/S33-shell-v3
git commit   # part of the D21+S33+S34 brief commit
git tag s33_start
```

## S33-B1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S33-B1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/tests/' crush run "$(cat .agents/gen/slices/S33-shell-v3/S33-B1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S33-B1.log 2>&1
```

Run in background, block on `job_output wait:true`. Wedged past ~40 min:
SIGKILL the wrapper + inner pid, re-dispatch with an inspect-partial-diff note.

## S33-R1 — `hyper/glm-5.3-flash` @ max → `S33-R1_review.md`

Only after B1's report exists.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,.agents/gen/slices/S33-shell-v3/' crush run "$(cat .agents/gen/slices/S33-shell-v3/S33-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/S33-R1.log 2>&1
```

## S33-F1 — `hyper/deepseek-v4.1-flash` @ xhigh → `S33-F1_report.md`

**Only if the review leaves HIGH or MED.** Body is cut from B1's with the
review's fix list appended.

## Close-out (orchestrator)

Gate ×2 fresh scratch → `verify_wave.py verify --baseline s33_start` →
`staging/build_code_map.py` → TICKS (T-130 closes; T-132 leaves on decision or
defaults) → WAVEBOARD row + `MASTER_REPORT.md` §6 → wave commit. Then S34.
