# D20_prompts — dispatch blocks (run strictly in order)

**No `VAJB_SLIM` on either dispatch** — playtest needs the godot-ai editor
bridge (`VAJB_SLIM=1` strips both MCP servers). D17 precedent. The prompt body
lives once in `D20_prompt_body.txt` (P1 variant); the P2 dispatch swaps the ID
via `sed 's/D20-P1/D20-P2/g'` (the body names D20-P1 only as the author ID and
the report path).

## Before the first dispatch (orchestrator)

```bash
python3 staging/verify_wave.py snapshot
git add .agents/gen/slices/D20-station-playtest
git commit   # "Brief D20: two in-game playtest reviews of the station shell"
git tag d20_start
```

## D20-P1 — `xiaomi/mimo-v2.6-pro` @ high → `D20-P1_report.md`

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_WORKER_FILES='.agents/gen/slices/D20-station-playtest/' crush run "$(cat .agents/gen/slices/D20-station-playtest/D20_prompt_body.txt)" -m xiaomi/mimo-v2.6-pro --reasoning-effort high --cwd "$VAJB_WORKSPACE" > /tmp/D20-P1.log 2>&1
```

Run in background, then block on `job_output wait:true`. Wedged past ~30 min:
SIGKILL the wrapper + inner pid, re-dispatch with an inspect-partial-diff note.

## D20-P2 — `hyper/glm-5.3-flash` @ max → `D20-P2_report.md`

Dispatch only after P1's report exists (one game window, shared save profile).

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_WORKER_FILES='.agents/gen/slices/D20-station-playtest/' crush run "$(sed 's/D20-P1/D20-P2/g' .agents/gen/slices/D20-station-playtest/D20_prompt_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/D20-P2.log 2>&1
```

Same background + `job_output wait:true` pattern. Then: `D20_synthesis.md`,
`TICKS.md` refresh, WAVEBOARD + `MASTER_REPORT.md` §6, wave-boundary commit
(`verify_wave.py verify --baseline d20_start` if any files moved; review-only,
so expected clean).
