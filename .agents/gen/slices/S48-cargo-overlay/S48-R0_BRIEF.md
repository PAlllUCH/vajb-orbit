---
slice: S48
reviewer: S48-R0
role: reviewer
status: ready
tier: paid
---

# S48-R0 — review the C-key Cargo overlay

## Context (read in this order)
1. `.agents/gen/slices/S48-cargo-overlay/S48-V0_BRIEF.md` — grade its seven
   acceptance items first (pass | drift | unanswered, with a cite).
2. `docs/design/UI_SPEC.md` §18 (A7–A9), §12.2/§12.3, §3.10, §16.1;
   `docs/design/STATION_HUB.md` §23.2.
3. `.agents/gen/slices/S48-cargo-overlay/S48-V0_report.md`.
4. The deliverables: `ui/dialogs/cargo_overlay.gd/.tscn` (new),
   `station.gd`, `game.gd`, `tests/test_s48_cargo_overlay.gd`.
5. `git diff` for the two touched screens — every hunk outside the cargo seam
   is a finding.

## Task
Review: acceptance items, then the diff against the pins. Check specifically:
- One surface, both planes — no second bespoke scene; the flight overlay sits
  on layer 20, above the HUD (10), below nothing it shouldn't.
- The read-only law: no priced row, no quote, no transaction, no write to the
  profile; every figure from `cargo_items`/`cargo_qty`/`ammo_of`.
- The five groups exactly as A9 names them; `comp_pow_*` never double-counts
  under COMPONENTS; empty groups render `NONE HELD`.
- The ESC ladders: station — the cargo close is P19's topmost step and the
  Router-overlay guard is intact; flight — the close is the one step before
  the map-deck step; C toggles both planes; focus returns to the trigger.
- The HUD: `CargoBlock` untouched and visible; the retired panel still hidden;
  the `_cargo_open` mirror in step.
- The envelope ≤ 0.2 s; no coordinates, no new hex; the gate count re-run
  matches (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's five files; anything outside
  is HIGH regardless of quality.

## Output contract
- `.agents/gen/slices/S48-cargo-overlay/S48-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S48-R0. Read .agents/gen/slices/S48-cargo-overlay/S48-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
