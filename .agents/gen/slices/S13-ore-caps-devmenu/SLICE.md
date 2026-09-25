---
slice: S13
phase: P4
lane: code
status: active
gate_baseline: "812/0"
---

# S13 — Ore caps, mining batteries, dev tuning

## Goal
Shooting rocks can never out-earn mining (the owner's two ticked rules ship),
N mining lasers mine N× faster instead of one, and the owner tunes every ore
constant live from an F1 overlay.

## In scope
- `GUN_BURST_SHARE` 0.10 cap on gun-cracked realisation (01 §5.6, owner-ticked 2026-09-25)
- `FRAGMENT_CORE_SHARE` 0.25 reserve variant (02 §5.1 Rule A, owner-ticked 2026-09-25)
- Multiple `w_mining` batteries stacking (owner tick 2026-09-25)
- The dev tuning overlay (F1) with sliders over every ore constant (owner ask 2026-09-25)
- `DOCK_RING_RADIUS` 120 → 175 (D11's owner tick, 2026-09-25)
- `game/ore_tuning.gd` — the one live balance surface

## Out of scope
- Rule B entirely (size spread, veins, field budget, ⅓-of-hold, T4 curve — DEFERRED 2026-09-25)
- Any yield, price or rate change beyond the two ticked shares
- Shipped UI/menus (`ui/station/**`, `ui/screens/**`, `ui/hud/**`, MENU_FLOW)
- `18_engine_spec.md` (owner-locked; the proposed wording lands in R1's report)
- The profile and any live `user://` write outside `user://dev_tuning.cfg`

## Acceptance criteria
- [ ] AC1 — a gun-attributed shatter realises ≤ `GUN_BURST_SHARE` × that rock's
      `_bore_ore` in pickups (float credit per field, whole units only); probe:
      gun legs' delivered ≤ 0.10 × Σ `_bore_ore` + 1 (S12's 0.714 per-rock row
      moves to ≤ 0.10)
- [ ] AC2 — a cleave conserves the budget: no fresh roll; children's Σ yield ==
      the parent's reserve (`FRAGMENT_CORE_SHARE` × `_bore_ore`, split); the
      fully mined family realises ≤ root `_bore_ore` + 1 (S12's 4.0× row → ≈1.0×)
- [ ] AC3 — N fitted `w_mining` (N = 1, 2, 3) deliver ≈N× extraction units/s
      (probe-measured, ±20 %); no single-instance state remains; no double-pay
- [ ] AC4 — the dev overlay toggles on F1 (raw keycode; **no `project.godot`
      change**), sliders write `OreTuning` live, Save/Reset manage
      `user://dev_tuning.cfg` (read only when the overlay opens — never at boot),
      TUNED badge when any field ≠ default; gate byte-identical on a store
      carrying that file
- [ ] AC5 — `DOCK_RING_RADIUS` == 175.0, one constant read by the dock trigger,
      the spawn placement and the ring draw; `test_d11_station`'s radius row 120→175
- [ ] AC6 — anti-drift: `OreTuning` defaults == the owner files' consts (asserted)
- [ ] AC7 — gate grows only by the new suites' rows plus the listed moved rows,
      twice on scratch stores; `verify --baseline s13_start` clean

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S13-B1 | `vajb-orbit/game/,vajb-orbit/tests/` | `S13_BRIEF.md` |
| S13-B2 | `vajb-orbit/ui/dev/,vajb-orbit/tests/test_s13_devmenu.gd` | `S13_BRIEF.md` |
| S13-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S13_BRIEF.md` |
| S13-F1 | union of B1+B2 sets + `docs/CONTRACTS.md` | `S13_BRIEF.md` |

## References
- `docs/gameplay/01_economy_core.md` §5.6 + `docs/gameplay/02_minerals.md` §5.1
  Rule A (the ticked rules and their reversals)
- `docs/CONTRACTS.md` §5 lines 345-375 (R1 owns the two changed sentences)
- `slices/S12-ore-budget/` reports (the measured baseline these rows move from)

## Carries forward
- Gate row counts and LOW ids are read from the files at write time (L167's lesson)
