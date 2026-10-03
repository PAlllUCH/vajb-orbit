---
slice: S29
phase: P3
lane: code
status: active
gate_baseline: "1038/0 (post-S28, 2026-10-03)"
---

# S29 — Panel consolidation + the map deck (implements D18's law)

## Goal
The buildable half of the owner's 2026-10-03 overhaul: the flight map deck
with pin navigation and the hyperdrive, and the folded station panels
(ARMORY+FITTING, SHIPYARD+REPAIRS, rail 8→6) — exactly per UI_SPEC §9/§10 and
STATION_HUB §16/§17.

## In scope
- The map deck, the pin, the blip classes, the hyperdrive module row (B1)
- Both panel merges, the six-entry rail, the inspector fills, the template (B2)
- The D17 leftovers inside the merged panels (ghosts, toasts, tooltips,
  comparison deltas, dead band, scroll affordances, button P1–P3)

## Out of scope
- New art (the B2-1 hover pick, arrival FX, the flight-scale sprite); docs;
  the surviving panels' internals (S28 already shipped them)

## Acceptance criteria
- [ ] A1–A8 of `S29_BRIEF.md` §6, each verifiable in the gate or by probe
- [ ] Gate zero failures, twice on fresh scratch

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Model |
|---|---|---|
| S29-B1 | `vajb-orbit/ui/hud/, vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S29-consolidation/` | `hyper/glm-5.3` @ high |
| S29-B2 | `vajb-orbit/ui/screens/, vajb-orbit/ui/station/, vajb-orbit/tests/, .agents/gen/slices/S29-consolidation/` | `hyper/glm-5.3` @ high |
| S29-R1 | same union + review file | `hyper/glm-5.3-flash` @ high |

## References
- `docs/design/UI_SPEC.md` §9/§10 (N1–N23) · `docs/design/STATION_HUB.md` §16/§17 (P4–P14)
- `docs/gameplay/10_ship_acquisition.md` 2026-10-03 block (R-S29-1)
- `slices/D18-map-panels/` (report + wireframes — the design of record)

## Carries forward
- B2-1 hover-plate pick (owner); arrival FX + flight-scale sprite (art budget);
  T-94–T-99 ride their owners.
