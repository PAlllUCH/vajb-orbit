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
2. `docs/CONTRACTS.md` — **only your sections, by range.** Its top carries a
   generated index with each §'s line numbers; locate the heading with
   `rg -n '^## §' docs/CONTRACTS.md` and read that range (`view --offset … --limit …`),
   or paste the section here if it is short. Never read the file whole: it is
   ~3,200 lines and ~80k tokens against ~2-3k for one section.
3. `docs/CODE_MAP.md` — what lies where: scenes, scripts, wiring (by range)
4. Anything else, by exact path — again by range if the file is long

## Spec extract (the pinned law, verbatim)
The exact §text the deliverable must satisfy, pasted here by the orchestrator
with its source cite (`doc §N`) above each block. A requirement not extracted
here is not binding on the worker, so extract everything the acceptance list
below grades; the worker never hunts the big specs for its law.

## Task
What this worker builds, in prose. Include the interfaces this code must
integrate with (names, signatures) — workers cannot infer them.

## Acceptance list
Numbered, derived from the spec extract above, one item per requirement. The
report answers every item with its cite (`§…` / `file:line`) or marks it
`NOT DONE`; the reviewer grades this list first, the source spec second. An
unanswered item means the deliverable is not done. A designer deliverable also
names the owner rulings it implements (escalation-ladder bucket 3).

## Hard constraints
- File set: `game/x.gd, ui/y.tscn` (dispatch sets `VAJB_WORKER_FILES` to exactly this)
- Do not touch: docs, other workers' files, `addons/`
- Shell edits are forbidden (hook gap) — use edit tools only
- Every run bounded: `--quit-after` on Godot runs, self-quitting probes

## Output contract
- Report: `slices/S2.5-feel/S2.5-V0_report.md` (from `_templates/REPORT.md`)
- The report answers the acceptance list item by item, each with its cite
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
