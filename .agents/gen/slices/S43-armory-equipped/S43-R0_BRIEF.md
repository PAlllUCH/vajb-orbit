---
slice: S43
reviewer: S43-R0
role: reviewer
status: ready
tier: paid
---

# S43-R0 — review the armory EQUIPPED list + its buy doors

## Context (read in this order)
1. `.agents/gen/slices/S43-armory-equipped/S43-V0_BRIEF.md` — grade its eight
   acceptance items first (pass | drift | unanswered, with a cite); the
   "disclosed route reading" section is itself graded (is the shell-seam route
   faithful to A5's normative content: a §5.2 confirm dialog, OK/CANCEL,
   focus return, never `message`?).
2. `docs/design/STATION_HUB.md` §23.4 (P49) and `docs/design/UI_SPEC.md` §17
   (A4–A6) — the pins you diff against.
3. `.agents/gen/slices/S43-armory-equipped/S43-V0_report.md` — the answers;
   an unanswered item is HIGH by rule.
4. The deliverables: `armory_panel.gd`, `armory_panel.tscn`,
   `tests/test_s43_armory_equipped.gd`.
5. UI_SPEC §3.10 A5.1–A5.5, §16.1 — the composition/ink law.

## Task
Review the build: acceptance items first, then the whole diff against the
pins. Check specifically:
- The equipped rows' order is the SLOT LAYOUT grid's own order (09 §8
  row-major), not an independent sort.
- The stat line derives from the catalogue (`effects` via the `stat_line`
  idiom), never a second table.
- The row press and the grid press land in one selection (`select_cell`);
  CELL INFO follows.
- The buy doors word exactly A6's strings with the catalogue's own name/price
  at press time; OK runs the shipped transaction (which can still refuse via
  §5.6's strip); CANCEL returns focus; no `message` at a door.
- No coordinates, no new hex, no `_draw` over content; the glyph sits at its
  own 24 cut.
- The gate count in the report matches a run you repeat yourself
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's three files; anything outside
  is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S43-armory-equipped/S43-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S43-R0. Read .agents/gen/slices/S43-armory-equipped/S43-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
