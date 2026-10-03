---
slice: D18
phase: P3
lane: design
status: active
gate_baseline: "n/a (design only)"
---

# D18 — Map deck & station panel consolidation design

## Goal
The design law for the owner's 2026-10-03 overhaul ruling: the flight map
deck (expand, pan, zoom, filters, pin navigation, hyperdrive jump) and the
folded station panels (ARMORY+FITTING, SHIPYARD+REPAIRS), as wireframes and
per-panel specs on the already-pinned numbers. S29 implements.

## In scope
- The map deck spec + wireframes on UI_SPEC §9's N1–N6 pins
- The merged ARMORY and merged SHIPYARD panel specs + wireframes on
  STATION_HUB §16's P4/P5 pins (drag-and-drop, slot filter tabs,
  hover-describe, equipped items on hull, repair block)
- The inspector lifecycle + panel template + six-entry rail detail (P6/P7)
- The N/P tick sheet presentation detail (every wording + reversal)

## Out of scope
- Code (S28/S29 implement); docs/gameplay, CONTRACTS, 18_engine_spec
- New art (owner 2026-09-27); the B2-1 hover-plate pick (owner-gated)
- The mechanical chrome fixes (S28's brief owns them)

## Acceptance criteria
- [ ] A1–A6 of `D18_BRIEF.md` §6, each answerable with a cite

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Model |
|---|---|---|
| D18-A1 | `docs/design/, staging/mockup/, .agents/gen/slices/D18-map-panels/` | `hyper/glm-5.3` @ high |
| D18-R1 | `docs/design/, .agents/gen/slices/D18-map-panels/D18-R1_review.md` | `hyper/glm-5.3-flash` @ high |

## References
- `docs/design/UI_SPEC.md` §8/§9 · `docs/design/STATION_HUB.md` §16 (the pins)
- `docs/gameplay/10_ship_acquisition.md` 2026-10-03 block (the N5 content pin)
- `D16_UserInput.md` (the owner's ruling, verbatim) · the D17 playtest reports

## Carries forward
- S29's brief cites this report as its design law; the tick sheet rides the
  owner's next ruling round.
