---
slice: S2.5
worker: S2.5-V0        # full worker ID — one letter per slice, see ID law
role: coder            # coder | designer | reviewer
status: ready          # draft | ready (owner-reviewed) | dispatched | done
tier: free             # pinned by the owner in review; coder picks models within it
---

> **Use when:** the developer prepares a dispatch. Copy to the slice folder as
> `<WorkerID>_BRIEF.md`. The owner reviews/edits, then pastes the paste block
> into the coder/designer session. Everything the worker needs must be either
> in this file or reachable by a path it names — no chat-only context.

# S2.5-V0 — one-line task title

## Context (worker reads in this order)
1. `slices/S2.5-feel/SLICE.md` — §In scope + your row in Worker file sets
2. `docs/CONTRACTS.md` §n — pinned interfaces (paste the section if it is short)
3. Anything else, by exact path

## Task
What this worker builds, in prose. Include the interfaces this code must
integrate with (names, signatures) — workers cannot infer them.

## Hard constraints
- File set: `game/x.gd, ui/y.tscn` (dispatch sets `VAJB_WORKER_FILES` to exactly this)
- Do not touch: docs, other workers' files, `addons/`
- Shell edits are forbidden (hook gap) — use edit tools only
- Every run bounded: `--quit-after` on Godot runs, self-quitting probes

## Output contract
- Report: `slices/S2.5-feel/S2.5-V0_report.md` (from `_templates/REPORT.md`)
- Gate: run the universal test gate; record before/after `[SUMMARY]` in the report
- Never leave a command in the background

## Model guidance
Tier `free` is pinned. Within it, pick the cheapest suitable model per task and
state the choice in the report. Split tasks that outgrow the tier; do not
escalate silently.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="game/x.gd,ui/y.tscn" crush run "<full prompt — paste the Task,
constraints and output contract here as prose>" -m <provider>/<model> --cwd "$VAJB_WORKSPACE"
```

`VAJB_SLIM=1` is not optional. It drops both MCP servers and the 75 unused skill
descriptions from the worker's context, which is ~48k tokens of the ~69k a
fresh session otherwise costs before it reads anything (measured 2026-09-24; the
guards and the re-measure recipe are in `crushrc`'s header). A worker edits files
and runs the headless gate, so it needs neither the editor bridge nor the asset
library.
