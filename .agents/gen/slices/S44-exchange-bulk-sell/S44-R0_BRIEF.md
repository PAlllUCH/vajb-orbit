---
slice: S44
reviewer: S44-R0
role: reviewer
status: ready
tier: paid
---

# S44-R0 — review the EXCHANGE bulk sell

## Context (read in this order)
1. `.agents/gen/slices/S44-exchange-bulk-sell/S44-V0_BRIEF.md` — grade its
   eight acceptance items first (pass | drift | unanswered, with a cite);
   grade the disclosed seat mapping (is the foot-row seat faithful to P53's
   intent: foot trio untouched, SELL MARKED a 56 px secondary, marked read in
   the TradeBox?).
2. `docs/design/STATION_HUB.md` §23.7 (P53) + §5.8/§5.6; `docs/design/UI_SPEC.md`
   §3.10 A5.1–A5.5 (A5.2(iii) especially), §16.1.
3. `.agents/gen/slices/S44-exchange-bulk-sell/S44-V0_report.md`.
4. The deliverables: `exchange_panel.gd`, `exchange_panel.tscn`,
   `tests/test_s44_exchange_bulk.gd`.
5. `vajb-orbit/game/exchange.gd` — verify it is byte-identical to the baseline
   (`git diff --stat vajb-orbit/game/exchange.gd` must be empty).

## Task
Note: the developer also re-cuts moved-premise rows after the build (the S43
precedent); if the tree's gate shows failures outside the brief's three files,
verify each is a moved premise, not a regression, and grade it.

## Task
Review: acceptance items, then the diff against the pins. Check specifically:
- No new pricing path: the marked read and SELL MARKED derive every figure
  from `Exchange.quote` at press time; no cached total survives a refresh.
- The single-sale arm is untouched (the stepper, `SELL`, `SELL ALL RAW`'s
  raw-only law, `CANCEL`); the foot trio's seats/sizes are byte-identical in
  the tscn.
- The check mark is code-drawn in its own child rect (`text_primary`), no font
  glyph, no colour-only state; unchecked is the bare `metal_mid` frame.
- MARK ALL/CLEAR cannot reflow the row stack (A5.5 content-swap law).
- Refusals surface on §5.6's strip with the stack named; a refused run stops.
- No coordinates, no new hex; the gate count re-run matches
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's three files; anything outside
  is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S44-exchange-bulk-sell/S44-R0_review.md` (≤150 lines,
  from `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S44-R0. Read .agents/gen/slices/S44-exchange-bulk-sell/S44-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
