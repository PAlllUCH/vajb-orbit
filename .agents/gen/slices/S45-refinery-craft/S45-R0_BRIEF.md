---
slice: S45
reviewer: S45-R0
role: reviewer
status: draft
tier: paid
---

# S45-R0 — review the refinery wave (V0 + W0)

**Dispatches only after S45-W0 lands.** Status moves `draft → ready` then.

## Context (read in this order)
1. `.agents/gen/slices/S45-refinery-craft/S45-V0_BRIEF.md` and `S45-W0_BRIEF.md`
   — grade both acceptance lists first (pass | drift | unanswered, with a
   cite); grade the disclosed route reading (the shell confirm seam) as in
   S43's review.
2. `docs/gameplay/04_refinery.md` §9 (R9–R12), §7 (the model); §23.5/§23.6 in
   `docs/design/STATION_HUB.md`; `docs/gameplay/07_crafting.md` §6 (C1–C10);
   `docs/design/UI_SPEC.md` §17 (A4/A6), §3.10, §16.1.
3. `S45-V0_report.md`, `S45-W0_report.md` — the answers; an unanswered item is
   HIGH by rule.
4. The deliverables: `refinery_panel.gd/.tscn`, `game/refinery.gd`,
   `game/crafting_catalog.gd`, `tests/test_s45_refinery.gd`,
   `tests/test_s45_craft.gd`.

## Task
Review both halves as one wave. Check specifically:
- The model's pinned rows stand: `test_p1_refinery.gd`'s sealed row and every
  `test_s34_refinery.gd` premise — the wave may add, never weaken.
- LOAD ALL moves whole stacks only, caps at 60 with overflow staying in the
  hold, no credits move; the status wordings are §5.6-family verbatim.
- The machine strip reads the model (`jobs`/counts), never a parallel state;
  the countdown ticks 1 Hz; chips carry label + frame (never colour alone).
- The four-plate cluster: `QUEUE` rightmost primary, 4×360 + 3×16 = 1 408;
  `QUEUE ALL`/`CANCEL` stay mid-column; T-181's words unchanged.
- The UPGRADE and CRAFT doors: A6's exact wording, catalogue-derived
  name/bill/fee; OK runs the shipped transaction; CANCEL returns focus; no
  `message` at a door; no dialog at `QUEUE` (A4's explicit out).
- The craft catalog: fees 2 500/3 000/2 800/4 000, inputs per §6.3, no
  computed price in any panel, the output effects in 09 §3's language; the
  scrap derivation 50 % round-down.
- The craft transaction: all-or-nothing, the shipped module-grant seam,
  refusal naming the missing input.
- No coordinates, no new hex; the gate count re-run matches
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` against the wave-start commit names only the six
  brief files; anything outside is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S45-refinery-craft/S45-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S45-R0. Read .agents/gen/slices/S45-refinery-craft/S45-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
