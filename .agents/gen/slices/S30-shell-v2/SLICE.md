---
slice: S30
phase: P3
lane: code
status: active
gate_baseline: "1074/0"
---

> **Use when:** the developer opens the S30 slice. Owner go 2026-10-03 ("assume
> default if not chosen. proceed with coder").

# S30 — Station shell v2 build

## Goal
After S30 the station is the shell-v2 design: the TERMINAL drawer replaces the
module rail, OVERVIEW lands on dock, hover/INSPECT popups replace the bottom
inspector band, every pane shares one skeleton and the A5.5 census is cured —
the layout never moves under the cursor.

## In scope
- `vajb-orbit/ui/` (shell `screens/station.*`, the eight `station/` panes, new
  drawer/tooltip/modal components), `vajb-orbit/autoload/player_profile.gd`
  (R-S30-2 only), `vajb-orbit/tests/`
- Law: `UI_SPEC.md` §11/§12 (A5.5, N24–N41), `STATION_HUB.md` §18/§19
  (P15–P31), the `staging/mockup/d19_*` wireframes, the §12.5 census row by row

## Out of scope
- `docs/` (read-only for builders; cite drift is reported), `project.godot`
  (input rows register at close-out via the sanctioned writer — code rides
  raw-key fallbacks meanwhile)
- Art generation (Tokens only, N29; A6's staged sprites ride a later art pass
  behind an owner-approved sheet)
- Flight HUD (`ui/hud/` except `map_deck.gd`'s R-S30-2 persistence door),
  `18_engine_spec.md`, tickets T-94–T-97/L267 (close-out docs pass)

## Acceptance criteria
- [ ] B1 A1–A6 and B2 A1–A6 — the numbered lists in `D19_BRIEF.md`'s successor
  §5 here; reports answer each with cites; the reviewer grades that list first

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S30-B1 | `vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B1_report.md` | `S30_BRIEF.md` |
| S30-B2 | `vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B2_report.md` | `S30_BRIEF.md` |
| S30-R1 | `vajb-orbit/ui/,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/S30-R1_review.md` | `S30_BRIEF.md` |
| S30-F1 | `vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/` | `S30_BRIEF.md` + `S30-R1_review.md` |
