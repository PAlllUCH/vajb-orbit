# D21-G2 prompts — the chrome cut/key/land run (2026-10-05)

Wave anatomy: docs (`UI_SPEC.md` §15.5 + this five-piece) → snapshot + commit →
D21-G2 → D21-G2-R1 (mandatory) → D21-G2-F1 **only** on HIGH/MED → close-out →
the owner's eyeball on the cut contact sheet (S36's entry gate).

## 0. Before the first dispatch (the orchestrator runs this)

```bash
git add -A && git commit -m "$(cat <<'EOF'
Brief D21-G2: the chrome cut/key/land run (the owner's four S36 calls decided)


💘 Generated with Crush




Assisted-by: Crush:xiaomi/mimo-v2.6-pro

EOF
)" && git tag g2_start && python3 staging/verify_wave.py snapshot --name g2_start
```

## D21-G2 — builder (the cut/key/land driver)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='asset-library/,vajb-orbit/assets/ui/,.agents/gen/slices/D21-chrome-family/' crush run "$(cat .agents/gen/slices/D21-chrome-family/D21-G2_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/D21-G2.log 2>&1
```

Launch with `run_in_background: true`, then block on `job_output wait:true`.
Wedged past ~40 min: SIGKILL + re-dispatch with an inspect-partial-diff note.

## D21-G2-R1 — reviewer (mandatory)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile && VAJB_SLIM=1 VAJB_WORKER_FILES='asset-library/,.agents/gen/slices/D21-chrome-family/' crush run "$(cat .agents/gen/slices/D21-chrome-family/D21-G2-R1_body.txt)" -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" > /tmp/D21-G2-R1.log 2>&1
```

## D21-G2-F1 — fixer (ONLY if R1 leaves HIGH or MED)

Cut `D21-G2_body.txt` and append R1's fix list verbatim; same model, effort and
file set as D21-G2. Report: `D21-G2-F1_report.md`.

## Close-out (the orchestrator)

1. Reimport the landed PNGs via godot-ai `filesystem_manage` op `reimport`
   (editor writes are refused while the game plays — it is not playing).
2. `python3 staging/phase_d/build_catalog.py` — regenerate
   `docs/design/ASSET_CATALOG.md`.
3. Gate ×2 fresh scratch (always grep `[SUMMARY]`; asset lane — expect no row
   move) + `python3 staging/verify_wave.py verify --baseline g2_start`.
4. `python3 staging/build_code_map.py`; TICKS / WAVEBOARD / `MASTER_REPORT.md`
   §6 refresh; wave-boundary commit with the Crush/Assisted-by attribution.
5. Hand the owner `asset-library/_review/chrome_family_cuts_2026-10-05.png` —
   his eyeball gates S36.

## Handoff (if this wave is routed through a separate orchestrator session)

> Read `.agents/gen/dispatch_coder.md` and execute queue item 42 only — D21-G2
> the chrome cut/key/land run. Brief:
> `.agents/gen/slices/D21-chrome-family/D21-G2_BRIEF.md`. Prompts:
> `.agents/gen/slices/D21-chrome-family/D21-G2_prompts.md`. Snapshot + commit
> before the first dispatch, run D21-G2 → D21-G2-R1, and the fixer only if the
> review leaves HIGH or MED. Stop before item 43 (S36 waits for the owner's
> eyeball on the cut contact sheet). Close out per the brief's close-out
> section (gate re-run ×2, verify_wave.py verify --baseline g2_start,
> WAVEBOARD update, wave-boundary commit), then report back: the landed class
> table, the measured margins, the reviewer's findings by tier, the variant
> spend, and the owner ticks.
