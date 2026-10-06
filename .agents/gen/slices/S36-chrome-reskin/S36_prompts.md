# S36 prompts — the chrome re-skin (2026-10-06)

Wave anatomy: docs (`UI_SPEC.md` §15 + §15.6 — done at the family round) →
snapshot + commit → S36-B1 → S36-R1 (mandatory) → S36-F1 **only** on HIGH/MED
→ close-out.

## 0. Before the first dispatch (the orchestrator runs this)

```bash
git add -A && git commit -m "$(cat <<'EOF'
Brief S36: wire the chrome family (swap map + the census suite)


💘 Generated with Crush




Assisted-by: Crush:xiaomi/mimo-v2.6-pro

EOF
)" && git tag s36_start && python3 staging/verify_wave.py snapshot --name s36_start
```

## S36-B1 — builder (the wiring + census suite)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/tools/,vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/' crush run "$(cat .agents/gen/slices/S36-chrome-reskin/S36-B1_body.txt)" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" > /tmp/S36-B1.log 2>&1
```

Launch with `run_in_background: true`, block on `job_output wait:true`. Wedged
past ~40 min: SIGKILL + re-dispatch with an inspect-partial-diff note.

## S36-R1 — reviewer (mandatory)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/' crush run "$(cat .agents/gen/slices/S36-chrome-reskin/S36-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/S36-R1.log 2>&1
```

## S36-F1 — fixer (ONLY if R1 leaves HIGH or MED)

Cut `S36-B1_body.txt` and append R1's fix list verbatim; same model, effort and
file set as S36-B1. Report: `S36-F1_report.md`.

## Close-out (the orchestrator)

1. Gate ×2 fresh scratch (grep `[SUMMARY]`) + `verify_wave.py verify
   --baseline s36_start`.
2. `python3 staging/build_code_map.py`; TICKS / WAVEBOARD / `MASTER_REPORT.md`
   §6 refresh; wave-boundary commit with the Crush/Assisted-by attribution.
3. Report the owner: the wiring count, the gate lines, the reviewer's findings
   by tier and any owner ticks.

## Handoff (if routed through a separate orchestrator session)

> Read `.agents/gen/dispatch_coder.md` and execute queue item 43 only — S36
> the chrome re-skin. Brief:
> `.agents/gen/slices/S36-chrome-reskin/S36_BRIEF.md`. Prompts:
> `.agents/gen/slices/S36-chrome-reskin/S36_prompts.md`. Snapshot + commit
> before the first dispatch, run S36-B1 → S36-R1, and the fixer only if the
> review leaves HIGH or MED. Stop before item 30 (S24). Close out per this
> file's close-out section, then report back: the wiring table's count, the
> measured margins, the gate lines, the reviewer's findings by tier, and the
> owner ticks.
