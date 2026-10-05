# D22_prompts — dispatch block (runs parallel with S35-B1 + D21-G1; review-only)

Runs with `VAJB_SLIM=1` (headless probes — no editor bridge needed).

## D22-P1 — `hyper/deepseek-v4.1-flash` @ xhigh → `D22-P1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,.agents/gen/slices/D22-screen-integrity/' crush run "$(cat .agents/gen/slices/D22-screen-integrity/D22-P1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/D22-P1.log 2>&1
```

## Close-out (orchestrator)

Findings tiered into `TICKS.md`/`LOW_BACKLOG.md`; the recap goes to
`MASTER_REPORT.md` §6 at the round's close. No gate rows move (report-only).
