---
slice: S18
phase: P5
lane: code
status: draft
gate_baseline: "877/0"
---

# S18 — Armory rework (implementation of D13's ticks)

## Goal
The ARMORY pane renders as D13's chosen approach B: a landscape console at the
pinned 1392×610 host, five 2×2-cell rack bays with per-bay salvo ledges over
two wells (barrel inventory + ammunition pack cards), 13 px ink everywhere,
≥4.5:1 captions, and a layout that reflows at any window size (T1's condition).
The 13 D12-A0 audit findings stay cured.

## In scope
- `vajb-orbit/ui/station/armory_panel.gd` + `armory_style.gd` + the pane scene:
  layout rebuild per `slices/D13-armory-rework/D13-A0_report.md` (design of
  record + PROPOSED P1–P6, owner-ticked 2026-09-25).
- The console master re-render (landscape 1360×516 @2×, scripted from the
  mockup's painted-metal language; `staging/mockup/armory_mockup_v2.py` is the
  geometry + look reference the owner approved).
- Docs amendments for the ticked values (UI_SPEC §3.10 next amendment,
  STATION_HUB §5.11 next amendment) — the D13 wave's deferred boundary work.
- The S15 layout suite's re-derivation (its ink/pitch numbers move; see the
  brief's tests-that-move block).

## Out of scope
- Adopting the layout language across other panes (owner-deferred).
- Any §13/§16 transaction, CONTRACTS §17 seam or 09 §11/§12 data-law change.
- The EXCHANGE/other panes' pack art and wording.

## Worker file sets
| Worker | Files |
|---|---|
| S18-B1 (builder) | `vajb-orbit/ui/station/armory_panel.gd`, `vajb-orbit/ui/station/armory_style.gd`, `vajb-orbit/ui/station/armory_panel.tscn`, `vajb-orbit/assets/ui/ui_armory_console.png` (+ `staging/mockup/render_console_master.py`), `vajb-orbit/tests/test_s18_armory_rework.gd` (new), the moved suites `test_s15_armory_layout.gd`, `test_p2b1_outfitting_panel.gd`, `test_s10_armory_input.gd`, `test_d7_armory.gd`, `test_s15_battery_cap.gd`, `test_s11_describe.gd`, `test_s11_inspector.gd`, `docs/design/UI_SPEC.md` §3.10 amendment block, `docs/design/STATION_HUB.md` §5.11 amendment block, report `S18-B1_report.md` |
| S18-R1 (reviewer) | `S18-R1_review.md` + its own probes only |
| S18-F1 (fixer, only on HIGH/MED) | the files named by R1's findings |

## Gate law
877/0 at the start; the rework may only ADD rows (new suite) — never lose one.
