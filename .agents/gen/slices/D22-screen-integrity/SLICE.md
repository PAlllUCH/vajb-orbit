---
slice: D22
phase: P3
lane: design
status: draft
gate_baseline: ""     # review-only: gate read, no rows moved by the wave itself
---

> The owner's 2026-10-05 instruction: "in pararell spawn reviewer on deepseek
> 4.1 flash x-high to check for integrity of screens in game".

# D22 — Screen integrity review (review-only)

## Goal
One measured integrity pass over every screen of the game: mounts clean,
nothing escapes the window, no content is hidden or empty, words/theme intact.

## In scope
- Main menu + boot/loading + settings; the station shell (header, drawer,
  OVERVIEW + all six panes incl. ARMORY's two modes and the REFINERY queue);
  the map deck; the flight HUD; the popup pair (inspect/sheet); dialogs +
  tooltips.
- Probe scripts under `vajb-orbit/tests/` (evidence, left in the tree).

## Out of scope
- Production code, docs, tickets (report-only).
- The S35 wave's two live files (`armory_panel.*`, `exchange_panel.*`) judged
  mid-flight — settled state only (see the brief's concurrency note).

## Acceptance criteria
- [ ] AC1 — every screen row carries mount / containment / words+theme verdicts
  with measured evidence
- [ ] AC2 — every defect is numbered `D22-P1/F##` with tier + `file:line`
- [ ] AC3 — the verdict + fixer item list (if blocked) is explicit

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D22-P1 | `vajb-orbit/tests/,.agents/gen/slices/D22-screen-integrity/` | `D22-P1_body.txt` |

## References
- `docs/design/STATION_HUB.md` §15–§21, `docs/design/UI_SPEC.md` §3/§8/§11–§15
- `docs/design/MENU_FLOW.md`, `docs/CODE_MAP.md` (what lies where)

## Carries forward
- Findings become tickets/owner calls at the close-out per the tiering law.
