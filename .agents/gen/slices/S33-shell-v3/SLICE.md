---
slice: S33
phase: P3
lane: code
status: draft
gate_baseline: "1110/0"   # the universal gate count this slice starts from
---

> Filled from `_templates/SLICE.md` at the owner's 2026-10-05 notes.

# S33 — Shell v3: ARMORY two sectors + the exchange sell cluster

## Goal
The armory's "FITS HERE" clutter dies: each ARMORY mode is two equal sectors
(overview left, equipment right with select-to-filter), BATTERY CONFIG gains
its EQ container, and the exchange sells by quantity with one SELL button.

## In scope
- FIT CELLS two sectors + the two-state equipment list — `STATION_HUB.md` §21.1 P38
- BATTERY CONFIG two sectors + the EQ container — §21.1 P39
- Row law + containment — §21.1 P40
- The exchange sell cluster — `UI_SPEC.md` §14.1 N48/N49

## Out of scope
- New chrome art (D21/S35 own the family; panels keep today's plates)
- OVERVIEW tiles (N50/N51 superseded pre-dispatch)
- The refinery (S34), `game/` and `autoload/` (not in the file set)

## Acceptance criteria
- [ ] AC1–AC7 = `S33_BRIEF.md` §4's acceptance list (sector equality, the two
  states, the EQ container, no dead blocks, SELL wording, SELL UNITS semantics,
  row law + gate)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S33-B1 | `vajb-orbit/ui/,vajb-orbit/tests/` | `S33_BRIEF.md` |
| S33-R1 | `vajb-orbit/tests/,.agents/gen/slices/S33-shell-v3/` | `S33_BRIEF.md` (acceptance list) |
| S33-F1 | as B1 (only if HIGH/MED) | `S33_BRIEF.md` |

## References
- `docs/design/STATION_HUB.md` §20–§21, `docs/design/UI_SPEC.md` §13–§14
- `docs/gameplay/09_ship_slots_modules.md` §10–§12
- `slices/D20-station-playtest/D20_synthesis.md` §3

## Carries forward
- Tick **T-132** (the note-2 reading). **T-130** closes here (P38 defines the
  no-selection semantics).
