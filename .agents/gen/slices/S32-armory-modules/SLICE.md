---
slice: S32
phase: P3
lane: code
status: active
gate_baseline: "TBD — S31's close count (started 1093/0)"
---

# S32 — ARMORY two-module rework (the D20 fix wave: F4)

## Goal
ARMORY becomes two full-screen modes — FIT CELLS (select a cell, learn it, see
what fits, select/drag to fit) and BATTERY CONFIG (compose weapon batteries from
the fitted weapons) — with AMMUNITION/PWR in a shared foot band and no list ever
starved to a half-column again.

## In scope
- `STATION_HUB.md` §20.1 **P32–P37** (the mode split, both modes' blocks, the foot band)
- `UI_SPEC.md` §13.1 **N45**'s trim law on every row (P37) + §11.1 A5.5/N24
- T-122's dead space (the Console band dies here) — closed at this wave

## Out of scope
- Loadout presets (P35 — owner ruling T-126)
- `game/`, `autoload/`, `addons/`, `docs/` — the battery writes go through the
  existing profile doors (`fit_battery`/`set_battery_groups`/`set_fit`) only
- Exchange, tooltip, shell bands (S31's)

## Acceptance criteria
- [ ] AC1 — two modes + switch, exactly one visible at a time (probe)
- [ ] AC2 — FIT CELLS: CELL INFO block per selected cell; FITS HERE lists exactly the legal owned candidates (probe vs `fit_legal`); select-to-fit and drag-to-fit both work; BUYABLE THAT FITS filters and buys
- [ ] AC3 — BATTERY CONFIG: B1–B5 racks over fitted weapons; drag between racks persists through `set_battery_groups` (probe the profile after a move); `W<n> — EMPTY` read-only rows; SALVO meters + `battery_cycle` per rack
- [ ] AC4 — no preset/save UI anywhere (grep); AMMUNITION + PWR in the foot band on both modes; every row's controls inside 1920×1080 (measured)
- [ ] AC5 — gate green with every moved row disclosed

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S32-B1 | `vajb-orbit/ui, vajb-orbit/tests` | `S32_BRIEF.md` |
| S32-R1 | `vajb-orbit/tests, .agents/gen/slices/S32-armory-modules/` | `S32_BRIEF.md` |
| S32-F1 | `vajb-orbit/ui, vajb-orbit/tests` | `S32_BRIEF.md` |

## References
- `docs/design/STATION_HUB.md` §20.1 (the pins), §19 (the skeleton)
- `docs/design/UI_SPEC.md` §13.1 N45 + §11.1 A5.5/N24, §3.10 Amendment 5 (the ARMORY worked example), §8 (the buttons)
- `docs/gameplay/09_ship_slots_modules.md` §10–§12 (L555-746 — battery law)
- `slices/D20-station-playtest/D20_synthesis.md` §3 (grounding)

## Carries forward
- T-122 closes here (the Console band dies with the rework). T-114's armory `_row_hint` dies with the pane rewrite. N45's overflow is cured structurally (P37).
