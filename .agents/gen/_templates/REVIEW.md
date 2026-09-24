---
slice: S2.5
reviewer: S2.5-R0     # the review wave's worker ID
verdict: clean        # clean | blocked (HIGH remains) | passed-with-followups
gate: ""              # before → after
---

> **Use when:** a review wave runs. Copy to the slice folder as
> `<ReviewerID>_review.md`. Diff findings against `docs/CONTRACTS.md`, never
> against the brief. Tiering per WAVEBOARD: HIGH blocks, MED gets one fixer
> pass, LOW moves to LOW_BACKLOG as `T-###`.
>
> **Hard cap: 150 lines.** One row per finding, one line of evidence each (the
> probe output or the `file:line`), no pasted source and no pasted logs. Read
> `docs/CONTRACTS.md` by section — its index gives the line range; never in
> full.

# S2.5-R0 review

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | | | |
| F2 | MED | | | |
| F3 | LOW | | → ticketed as `T-##`, not fixed here | — |

## Verified fixes
After the fixer pass, one line per finding: `F1 — fixed, verified by <probe/gate/check>`.

## Gate
`[SUMMARY]` before and after, and any negative control that was run.
