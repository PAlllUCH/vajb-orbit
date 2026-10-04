---
slice: D19
phase: P3
lane: design
status: active
gate_baseline: "1074/0"
---

> **Use when:** the designer opens the D19 slice. Owner-approved 2026-10-03 (the
> shell-v2 ruling + routing).

# D19 — Station shell v2 (drawer, overview, popups)

## Goal
After D19 the shell-v2 law is wireframe-grade: the TERMINAL drawer, the OVERVIEW
pane, the tooltip/INSPECT-modal pair and the one panel skeleton are specified to
measurement level, with every A5.5 violation in the shipped UI named, so S30 can
code against a closed spec with no worker-invented numbers.

## In scope
- `UI_SPEC.md` §12 (design detail for N24–N30) and `STATION_HUB.md` §19 (design
  detail for P15–P21) — the deliverable sections, next free numbers at write time
- Three wireframes in `staging/mockup/` (shell+drawer, overview, popup layer)
- The A5.5 defect census and the supersession ledger (brief §5 A4/A5)
- The staged art-needs list (prompts + price estimate only — nothing generated)

## Out of scope
- Any file under `vajb-orbit/` (no code, no scenes, no tests)
- Art generation, keying or import (the pipeline law runs only after the owner
  approves a review sheet — `STATION_HUB.md` §18's art-budget block)
- `docs/gameplay/18_engine_spec.md` (owner-locked)
- The map deck (`UI_SPEC.md` §9/§10) and every flight HUD surface
- Ticket work (T-94–T-106 ride untouched)

## Acceptance criteria
- [ ] AC1–AC6 — the numbered acceptance list in §5; the report answers each with cites

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D19-A1 | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/D19-A1_report.md` | `D19_BRIEF.md` |
| D19-R1 | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,vajb-orbit/ui/,.agents/gen/slices/D19-station-shell-v2/D19-R1_review.md` | `D19_BRIEF.md` |
| D19-F1 | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/` | `D19_BRIEF.md` + `D19-R1_review.md` |
