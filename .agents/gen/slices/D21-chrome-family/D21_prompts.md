# D21_prompts — dispatch blocks (D21 runs beside coder 39 / S33 — disjoint file sets)

Both run with `VAJB_SLIM=1`. Prompt bodies live beside this file
(`D21-A1_body.txt`, `D21-R1_body.txt`; `D21-F1_body.txt` is cut from A1's at
need).

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot --name d21_start
git add .agents/gen/slices/D21-chrome-family docs/design docs/gameplay/04_refinery.md
git commit   # "Brief D21+S33+S34: the chrome family, armory two-sector, refinery queue"
git tag d21_start
```

## D21-A1 — `xiaomi/mimo-v2.6-pro` @ high → `D21-A1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,staging/mockup/' crush run "$(cat .agents/gen/slices/D21-chrome-family/D21-A1_body.txt)" -m xiaomi/mimo-v2.6-pro --reasoning-effort high --cwd "$VAJB_WORKSPACE" > /tmp/D21-A1.log 2>&1
```

Run in background, block on `job_output wait:true`. Wedged past ~40 min:
SIGKILL the wrapper + inner pid, re-dispatch with an inspect-partial-diff note.

## D21-R1 — `hyper/glm-5.3-flash` @ max → `D21-R1_review.md`

Only after A1's report exists.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,.agents/gen/slices/D21-chrome-family/' crush run "$(cat .agents/gen/slices/D21-chrome-family/D21-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/D21-R1.log 2>&1
```

## D21-F1 — `xiaomi/mimo-v2.6-pro` @ high → `D21-F1_report.md`

**Only if the review leaves HIGH or MED.** Body is cut from A1's with the
review's fix list appended.

## Close-out (orchestrator)

`verify_wave.py verify --baseline d21_start` → `staging/docs_index.py` →
TICKS refresh (T-131 leaves when the owner rules) → `MASTER_REPORT.md` §6
recap → wave commit. Gate n/a (docs only). Then the generation batch
(`$KIE_GENERATE`, per the brief §3 cost) → contact sheet → the owner's pick
before any S35 dispatch.
