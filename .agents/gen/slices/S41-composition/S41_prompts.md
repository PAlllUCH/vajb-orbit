# S41_prompts.md — dispatch lines (four builders in parallel, then the review)

**Models (the project's standing code-lane roster):** builders run
`hyper/deepseek-v4.1-flash` at `--reasoning-effort xhigh` (that route's top rung;
its ladder is `low`/`high`/`xhigh`, not `max`). The reviewer runs
`hyper/glm-5.3-flash` at `--reasoning-effort high` — it is both the standing code
reviewer and the standing visual/UI auditor, and this wave's review is **code +
visual**.

Run order **B1 ‖ B2 ‖ B3 ‖ B4 (parallel, disjoint file sets) → R1 → (F1 only on
HIGH/MED)**. Launch each with `run_in_background: true` and wait on it
(`job_output`, `wait: true`). A worker that idles with no headless process
running and a frozen log is wedged — kill the shell **and** the `crush run`
process, then re-dispatch; if a worker's long command must be redirected to a log
it reads, say so explicitly in the prompt (S27-R2 and D23-R1 both needed this).

**Before the first dispatch** (the brief is committed; S27 must have closed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s41_start \
  && git tag s41_start
```

## The four builders

Each prompt lives in a scratch file (kept out of the repo) and the worker's only
declared write is its report plus its own suite. Run all four, then wait.

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile
for w in b1 b2 b3 b4; do
  case $w in
    b1) files='vajb-orbit/tools/build_theme.gd,vajb-orbit/ui/theme/vajb_theme.tres,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/components/tooltip.gd,vajb-orbit/tests/test_s41_shell.gd,.agents/gen/slices/S41-composition/S41-B1_report.md';;
    b2) files='vajb-orbit/ui/station/overview_panel.tscn,vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/ui/station/exchange_panel.tscn,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/tests/test_s41_panels_a.gd,.agents/gen/slices/S41-composition/S41-B2_report.md';;
    b3) files='vajb-orbit/ui/station/armory_panel.tscn,vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/armory_style.gd,vajb-orbit/tests/test_s41_armory.gd,.agents/gen/slices/S41-composition/S41-B3_report.md';;
    b4) files='vajb-orbit/ui/station/refinery_panel.tscn,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/launch_panel.tscn,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/station/contracts_panel.tscn,vajb-orbit/ui/station/contracts_panel.gd,vajb-orbit/ui/station/shipyard_panel.tscn,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/tests/test_s41_panels_b.gd,.agents/gen/slices/S41-composition/S41-B4_report.md';;
  esac
  VAJB_SLIM=1 VAJB_WORKER_FILES="$files" \
    crush run "$(cat /tmp/s41_${w}_prompt.txt)" \
    -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
    > "/tmp/s41_${w}.log" 2>&1 &
done
wait
```

## S41-R1 — the review (after all four builders report)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S41-composition/S41-R1_review.md' \
     crush run "$(cat /tmp/s41_r1_prompt.txt)" \
     -m hyper/glm-5.3-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s41_r1.log 2>&1
```

## S41-F1 — the fixer (only if R1 leaves HIGH or MED)

Dispatch with the union of every builder's file set plus
`vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S41-composition/`, on
`hyper/deepseek-v4.1-flash` @ xhigh, reading the review and fixing only its
HIGH/MED at their named `file:line`.

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 38 only — S41 the composition pass. Brief: .agents/gen/slices/S41-composition/S41_BRIEF.md. Prompts: .agents/gen/slices/S41-composition/S41_prompts.md. Source audit: .agents/gen/slices/D23-panel-audit/D23-R1_audit.md. Snapshot + commit before the first dispatch, run B1 ‖ B2 ‖ B3 ‖ B4 in parallel, then R1, and the fixer only if the review leaves HIGH or MED. Close out per the brief's close-out section (gate ×2, verify_wave.py verify --baseline s41_start, the re-render + visual re-check, build_code_map.py, the ticket rows, WAVEBOARD/TICKS/MASTER_REPORT, wave-boundary commit), then report back: the measured gate count, each builder's per-finding disposition, the reviewer's findings by tier, and the PROPOSED tokens awaiting the owner.
```
