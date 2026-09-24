---
slice: D7
phase: P2
lane: design
status: draft
gate_baseline: "608/0 (CONTRACTS §9, measured at D6 close-out 2026-09-24)"
---

> Copy of `_templates/SLICE.md`, filled 2026-09-24 by the design-lane planner.

# D7 — Cockpit rework + battery window

## Goal
The flight cockpit reads as one analog instrument cluster on a painted metal
panel (no glass/screen surfaces, no duplicate compass, no glyph overlap, no old
HUD column), and the ARMORY's gun battery selection window wears the same
instrument language — with every transaction and seam unchanged.

## In scope
- UI_SPEC §3.7 rework + §3.6 heading-tick retirement + §3.9/§3.10 (the new pins)
  and **§3.8's restyle** (the Mockup C approval 2026-09-24 reverses its staging)
- `vajb-orbit/ui/hud/**` (cluster, `hud.gd` column removal, `ship_status_screen.gd`
  restyle), `vajb-orbit/ui/station/armory_panel.gd` surface only
- The UI_CHROME §12 art batch (**five runs**: `ui_cockpit_panel`, `ui_gauge_face`
  re-cut, `ui_armory_console`, `ui_armory_rack_plate`, `ui_armory_row_plate`,
  `ui_status_panel`)

## Out of scope
- Any transaction/seam change in 09 §11, CONTRACTS §17, `game/**`, `autoload/**`
- Cargo/fitted-modules readouts beyond their §3.8 home; per-module damage
- Minimap (§3.3), target reticle (§3.5), theme `vajb_theme.tres`, `project.godot`

## Acceptance criteria
- [ ] AC1 — digit glyph rects pairwise disjoint and inside their rows (probe)
- [ ] AC2 — one heading instrument only: the dial draws no heading tick; compass + HDG row carry 0..359
- [ ] AC3 — no glass/screen surface in the cluster or the armory window; every widget mounts in a painted panel well (probe of the mounted rects)
- [ ] AC4 — the old HUD column (§3.1 crest bars, §3.2 AmmoPanel, §3.4 cargo block) is absent from the flight HUD; HULL/SHLD/AMMO read from the cluster
- [ ] AC5 — armory transactions unchanged: same `fit_into_rack` refusals write nothing (the existing `test_p2b*`/`test_s5_*` rows stay green unmodified)
- [ ] AC6 — `test_engine2_hud.gd`'s §3.6 rows byte-green except the heading-tick rows the UI_SPEC §3.6 amendment retires

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D7-A0 / A0b | `staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/` | `D7_BRIEF.md` |
| D7-C1 | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `D7_BRIEF.md` |
| D7-C2 | `vajb-orbit/ui/station/,vajb-orbit/tests/` | `D7_BRIEF.md` |
| D7-C3 | `vajb-orbit/ui/hud/,vajb-orbit/tests/` (after C1) | `D7_BRIEF.md` |
| D7-R1 / F1 | `vajb-orbit/tests/,vajb-orbit/tools/` / union of A0–C3 | `D7_BRIEF.md` |
