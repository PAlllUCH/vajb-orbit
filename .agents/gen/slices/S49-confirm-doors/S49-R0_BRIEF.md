---
slice: S49
reviewer: S49-R0
role: reviewer
status: ready
tier: paid
---

# S49-R0 — review the A2 doors + the wording law

## Context (read in this order)
1. `.agents/gen/slices/S49-confirm-doors/S49-V0_BRIEF.md` — grade its seven
   acceptance items first (pass | drift | unanswered, with a cite); grade the
   boundary reading (in: auction hull + module listing, insurance opt-in,
   vault rent; out: QUEUE/REPAIR/PAY BOUNTY/CANCEL/LAUNCH/insurance-OFF).
2. `docs/design/UI_SPEC.md` §17 (A4/A5/A6) — the pins you diff against.
3. `.agents/gen/slices/S49-confirm-doors/S49-V0_report.md`.
4. The deliverables: `auction_panel.gd`, `insurance_panel.gd`,
   `vaults_panel.gd`, `tests/test_s49_confirm_doors.gd`.

## Task
Review: acceptance items, then the diff against the pins. Check specifically:
- Every dialog's name/price is derived from the owning catalogue at press
  time (no hardcoded string, no stale price, no recomputed premium).
- The transactions run unchanged after OK and can still refuse (§5.6's strip);
  CANCEL returns focus and moves nothing.
- The boundary holds: no dialog grew on any out surface (diff-prove the
  refinery/contracts/launch files untouched).
- The insurance OFF path and the per-launch charge are dialog-free.
- The worked-example rows assert exact strings.
- No coordinates, no new hex; the gate count re-run matches
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's four files; anything outside
  is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S49-confirm-doors/S49-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S49-R0. Read .agents/gen/slices/S49-confirm-doors/S49-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
