---
slice: S31
phase: P3
lane: code
status: active
gate_baseline: "1093/0"
---

# S31 — Shell fixes (the D20 fix wave: F1–F3 + F5)

## Goal
The owner's playtest notes 1–3 are cured: the exchange hold reads like the
marker board on one height, every armory browser control is reachable, and the
hover-inspect lingers and reads clearly — with the D20 LOW pack (T-118–T-123)
dying beside them.

## In scope
- F1 exchange parity — `UI_SPEC.md` §13.1 **N42–N44**
- F2 armory browser overflow — §13.1 **N45**
- F3 hover-inspect popup — §13.1 **N46–N47**
- F5 the D20 LOW pack (`LOW_BACKLOG.md` D20 block T-118–T-123)

## Out of scope
- The ARMORY two-mode rework (S32's; `STATION_HUB.md` §20) — N45 cures the overflow only
- `docs/`, `game/`, `autoload/`, `addons/`; input-map rows T-101/T-110 (orchestrator's godot-ai pass)

## Acceptance criteria
- [ ] AC1 — N42–N47 each shipped at its pinned value, or the deviation disclosed with its cause (`file:line` per pin)
- [ ] AC2 — at 1920×1080 every armory browser row control is inside the window (measured rects)
- [ ] AC3 — both exchange lists' scroll viewports share one first-row y and the hold title renders ≥ 180 px (measured)
- [ ] AC4 — the tooltip lingers 0.5 s after unhover (probe) and the gate ends green with every moved row disclosed

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S31-B1 | `vajb-orbit/ui, vajb-orbit/tests` | `S31_BRIEF.md` |
| S31-R1 | `vajb-orbit/tests, .agents/gen/slices/S31-shell-fixes/` | `S31_BRIEF.md` |
| S31-F1 | `vajb-orbit/ui, vajb-orbit/tests` | `S31_BRIEF.md` |

## References
- `docs/design/UI_SPEC.md` §13.1 (the pins), §11.1 A5.5/N24 (the layout law), §12.5 (the census), §5.1/§5.10 (the idioms N42/N47 borrow)
- `docs/design/STATION_HUB.md` §19 (the pane skeleton)
- `slices/D20-station-playtest/D20_synthesis.md` (the measured causes)

## Carries forward
- T-118–T-123 close here (T-122 deferred to S32, T-123 deferred — both disclosed). T-114's dead `_row_hint` helpers die if this wave touches those panes.
