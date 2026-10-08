---
slice: S36
slug: chrome-reskin
title: The chrome re-skin — wire the true-aspect family
lane: coder
phase: P3
status: live (2026-10-06)
---

# S36 — the chrome re-skin

Owner's law (2026-10-05/06): the one true-aspect chrome family replaces every
stretched surface; the keep-list of native surfaces is untouched; the four hard
classes ship the owner-picked rail look (`UI_SPEC.md` §15.6, review sheet
`asset-library/_review/CHROME_REVIEW_2026-10-05.jpg`).

## In scope

Wire the swap map (`slices/D21-chrome-family/S36_proposal.md` + `UI_SPEC.md`
§15.6's scope line): C1/C2/C3/C4/C5/C6/C7/C9/C12 + BG-1..4 across the station
panes, the OVERVIEW tiles and the exchange tooltip; plus the chrome-census
regression suite.

## Out of scope

The keep-list surfaces (main menu chromes, TERMINAL drawer surface, CANCEL/
SELL pressables, cockpit/status faces, `ui_slot_*` faces, HUD bar caps, minimap
bezel, `ui_backdrop_hangar`, matching dialog frames); gameplay code; docs
(report bucket-2 findings, never edit); asset regeneration (the cuts land as
they are).

## Worker file sets

| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S36-B1 | `vajb-orbit/ui/,vajb-orbit/tools/,vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/` | `S36_BRIEF.md` |
| S36-R1 | `vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/` | `S36_BRIEF.md` (review sections) |
| S36-F1 | same as S36-B1 | R1's fix list (only on HIGH/MED) |

## Tests that move

None. The 2026-10-06 round proved `test_s20` AC2 and `test_d8`'s 12 px floor
guard the keep-list — they stand byte-unchanged. The new
`test_s36_chrome_census.gd` only ADDS rows (gate 1138 → 1138 + N).
