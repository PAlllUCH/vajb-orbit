---
slice: S46
reviewer: S46-R0
role: reviewer
status: ready
tier: paid
---

# S46-R0 — review the shipyard build view

## Context (read in this order)
1. `.agents/gen/slices/S46-shipyard-build/S46-V0_BRIEF.md` — grade its eight
   acceptance items first (pass | drift | unanswered, with a cite); grade the
   disclosed readings (the shell confirm seam; the staged MODULES caption
   despite S27's recipes being live).
2. `docs/design/STATION_HUB.md` §23.8 (P54), §5.10, §5.6;
   `docs/gameplay/10_ship_acquisition.md` §3.1/§3.3/§3.5;
   `docs/design/UI_SPEC.md` §17 (A4/A6), §3.10, §16.1, §12.3.
3. `.agents/gen/slices/S46-shipyard-build/S46-V0_report.md`.
4. The deliverables: `shipyard_panel.gd`, `shipyard_panel.tscn`,
   `tests/test_s46_shipyard_build.gd`.
5. `vajb-orbit/game/shipyard.gd` — verify byte-identical to the baseline
   (`git diff --stat vajb-orbit/game/shipyard.gd` must be empty).

## Task
Review: acceptance items, then the diff against the pins. Check specifically:
- The economics never moved: no CR build figure in the build view; labour is
  the only CR; the recipes read `HULL_RECIPES` live (no parallel table).
- `<held>/<needed>` reads `cargo_qty` only; the MISSING chip names the first
  missing material in recipe order; READY/MISSING carry label + frame.
- The confirm wording is A6's exact shape with catalogue names; OK runs
  `queue_job` (committed at queue time, refunded on cancel — untouched);
  CANCEL returns focus.
- The queue/scrap/hangar views and the four mode plates are untouched
  (diff-prove the tscn rows outside the build view).
- The staged MODULES caption is verbatim; no module rows were over-delivered.
- No coordinates, no new hex; the gate count re-run matches
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's three files; anything outside
  is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S46-shipyard-build/S46-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S46-R0. Read .agents/gen/slices/S46-shipyard-build/S46-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
