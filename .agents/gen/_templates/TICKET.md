---
ticket: T-30          # global counter; LOW_BACKLOG L1–L29 grandfather as T-1–T-29
severity: LOW         # HIGH | MED | LOW  (severity is the wave-blocking tier, set by the reviewer)
kind: CODE            # DOC | SPEC | CODE | HARNESS
lane: code            # code | design | docs — who owns it
status: open          # open | closed-in-<slice or wave>
---

> **Use when:** any bug, playtest finding, review LOW, or follow-up is filed.
> Copy to `_state/` as `T-##_short_name.md` and add one row to LOW_BACKLOG's
> table. The file is the detail; the LOW_BACKLOG row is the index. If the item
> is small enough to live entirely in its row, skip the file.

# T-30 — one-line title

## Symptom
What is wrong, observed (with the measurement that proves it, where one exists).

## Repro
Exact steps or command. "Not reproducible — owner report" is valid.

## Expected
What the spec/contract says should happen, with the anchor (`§`, CONTRACTS §n).

## Suspected owner
File(s) and the lane that owns them. "No owner yet" is valid — routing is the
developer's job at the next slice boundary.

## Disposition
The ruling or fix decision, and the closure evidence once closed. If carried
over from another ticket, cite it (`carries T-26`); closure is recorded in both.
