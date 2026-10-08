---
phase: P2
title: RPG docs 08/09/10
status: active        # draft | active | closed
slices: [S3, S4]      # slice IDs listed under this phase
---

> **Use when:** a phase opens. Copy to `phases/<P##>-<slug>/PHASE.md`. This is a
> manifest and index only — work lives in slice folders; this file never grows a
> work log. Slices and the exit criteria are checkbox lists: tick a box at
> close-out, never rewrite history.

# P2 — RPG docs 08/09/10

## Goal
2 lines: what this phase delivers and which owner requirements drive it.

## Slices (one checkbox per slice — tick at close-out)

- [ ] **S3 — example-slug.** 1-line deliverable. `slices/S03-example-slug/` ·
      runs after: — · baseline `s3_start`
- [ ] **S4 — example-slug-2.** 1-line deliverable. `slices/S04-example-slug-2/`
      · runs after: S3 · baseline `post-S3`

## Wave checklist (applies to every slice above)

- [ ] Docs first — the owning doc amended with the real numbers, each carrying
      its reversal path
- [ ] Five-piece handoff re-cut against the current shell (`BRIEF` + `prompts`)
- [ ] `verify_wave.py snapshot` + commit before the first dispatch
- [ ] Builders run → mandatory review → fixer only if the review leaves HIGH/MED
- [ ] Close-out: gate ×2 hermetic, `verify --baseline`, CONTRACTS §9/§10,
      WAVEBOARD + TICKS refresh, wave-boundary commit

## Exit criteria
- [ ] Every slice `done` (findings tiered, briefs archived)
- [ ] `docs/CONTRACTS.md` updated by the closing review wave
- [ ] Phase summary: 1 page here — what shipped, what carries forward

## Carries forward
- Tickets routed to the next phase (IDs only — detail lives in the ticket)
