---
slice: S2.5
worker: S2.5-V0
model: ""             # what actually ran
status: informational # informational | actionable (Follow-ups MUST be ticketed before slice close)
gate: ""              # e.g. "219/0 → 235/0"
---

> **Use when:** a worker finishes its task. Copy to the slice folder as
> `<WorkerID>_report.md`. Exception-based: if nothing deviated and nothing is
> owed, Result + gate numbers are enough — keep it under one page.

# S2.5-V0 report

## Result
2–3 lines: what now works, measured (gate numbers, probe counts).

## Deviations from SLICE.md
Every place the shipped work differs from the SPEC or made a judgment call on
an unpinned value. Format: what, why, the one-line reversal if the owner
disagrees. "None" is a valid answer.

## Evidence
The commands run and their decisive outputs (gate summary, probe lines, log
excerpts). Enough for a reviewer to re-verify without re-deriving.

## Files touched
- `game/x.gd` — one phrase per file on what changed

## Follow-ups
Each row becomes a `T-###` ticket in LOW_BACKLOG at slice close; after ticketing,
this section says "ticketed as T-30, T-31" and nothing else.
| Item | Kind | Where |
|---|---|---|
