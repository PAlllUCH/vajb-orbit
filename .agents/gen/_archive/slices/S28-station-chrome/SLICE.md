---
slice: S28
phase: P3
lane: code
status: active
gate_baseline: "1031/0 (post-auction-detour, 2026-10-03)"
---

# S28 — Station chrome quick-fix wave (the playtest pile)

## Goal
The mechanical half of the owner's 2026-10-03 ruling: every station/menu
defect from the D17 playtest reports that needs no design round — the stale
inspector band cure (P6's mechanical half), the CONTROLS bindings, the copy
and hygiene rows, and the button/focus unification (P1–P3) on the panels S29
does not rewrite.

## In scope
- The shell inspector clear-on-module-switch (STATION_HUB §16 P6, S28 half)
- CONTROLS tab: binding conflicts + TURN LEFT/RIGHT defaults
- Copy: `NO_DAMAGE_REPORT` strip, dev-speak strings, plural grammar, quit
  dialog, splash progress line, auction shelf tag, `MINE BACK`
- Mechanics: shield single source (450 vs 400), SELL ALL RAW disabled state,
  exchange stepper default, credits box width, sub-pixel origins
- Hygiene: DevTuningMenu gated out of release builds
- Button + focus unification (P1–P3) on refinery, exchange, auction, the
  LAUNCH panel, the shell action buttons and settings

## Out of scope
- The merged panels' internals (armory, fitting, shipyard, repairs bodies —
  S29 rewrites them with D18's law); the map deck (S29); new art; the B2-1
  hover-plate pick (owner-gated); docs

## Acceptance criteria
- [ ] A1–A16 of `S28_BRIEF.md` §6, each verifiable in the gate or by probe
- [ ] Gate zero failures, run twice on fresh scratch

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Model |
|---|---|---|
| S28-B1 | `vajb-orbit/ui/, vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S28-station-chrome/` | `hyper/qwen3.8-flash` @ high |
| S28-R1 | same + review file | `hyper/glm-5.3-flash` @ high |
| S28-F1 | same as B1 (only if HIGH/MED) | `hyper/qwen3.8-flash` @ high |

## References
- `docs/design/UI_SPEC.md` §8 (P1–P3) · `docs/design/STATION_HUB.md` §16 (P6)
- `.agents/gen/slices/D17-playtest-pass/` (P1, P2 reports + synthesis)
- `docs/CONTRACTS.md` §9/§10 (gate law)

## Carries forward
- L260 (the auction footer clock flake) stays with its harness owner; the
  B2-1 hover pick stays with the owner; the merged-panel pile rides S29.
