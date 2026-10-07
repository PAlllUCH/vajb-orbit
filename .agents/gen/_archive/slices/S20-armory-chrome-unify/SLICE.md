---
slice: S20
phase: P3
lane: code
status: active
gate_baseline: "887/0"
---

# S20 — ARMORY chrome unification & the shell inspector pin

## Goal
The ARMORY pane wears the game's §5.3 chrome family like every other station
panel (the owner's "unify it to the rest of game (chromes)"), and hovering
descriptions never reflow the station shell again (the inspector stops growing
under the cursor). The D13 layout the owner likes survives byte-identical.

## In scope
- `docs/design/UI_SPEC.md` §3.10 **Amendment 4** (A4.1–A4.5) — the chrome
  mapping, the Tokens palette, the L227 contrast cure, the shell inspector pin.
- The armory pane's surfaces (`armory_panel.gd`, `armory_style.gd`) and the
  station shell inspector (`station.tscn`, `station.gd`).

## Out of scope
- Any Amendment 3 geometry change (the layout is owner-ticked; a moved number
  is HIGH).
- Adopting the armory's layout language across the rest of the game (owner
  2026-09-25: deferred).
- The seven-seg salvo ledge look (tick T5 is the only way it changes).
- New art or paid generation calls (the chrome family already ships).

## Acceptance criteria
- [ ] AC1 — no `ui_armory_console` reference remains in the pane's code; the
      bay cards / wells halves / pack + row plates read as the sibling panels'
      `ui_panel_frame` chrome (probe: the pane in a running game).
- [ ] AC2 — the 2×2 cells carry `ui_slot_weapon_*` chrome; `BUY`/`✕` wear
      `StationButton`/`ui_button_plate_*`; state chips are §3.1/3.1b
      label + 1 px frame in Tokens tones.
- [ ] AC3 — zero hex literals outside `tools/build_theme.gd` in the touched
      files; `ArmoryStyle` resolves its palette from the theme and the
      `armory_style_user.tres` override path still works.
- [ ] AC4 — the `OVER CAP` label measures ≥ 4.5:1 on its fill (L227 closed,
      asserted in the test).
- [ ] AC5 — the shell inspector height is identical for hover content `""`,
      1 line, 2 lines and 3+ lines, and the ModuleHost rect is unchanged
      across `inspect_requested` emissions.
- [ ] AC6 — every Amendment 3 geometry pin comes out unchanged (old→new
      listed per row) and the gate is 887/0 + rows only, twice hermetic.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S20-B1 | `vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/armory_style.gd,vajb-orbit/ui/screens/station.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tools/build_theme.gd,vajb-orbit/ui/theme/,vajb-orbit/tests/,docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,docs/design/ASSET_CATALOG.md,.agents/gen/slices/S20-armory-chrome-unify/S20-B1_report.md` | `S20_BRIEF.md` |
| S20-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S20-armory-chrome-unify/S20-R1_review.md` | `S20_BRIEF.md` |
| S20-F1 | `vajb-orbit/ui/station/,vajb-orbit/ui/screens/,vajb-orbit/tools/,vajb-orbit/ui/theme/,vajb-orbit/tests/,docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,docs/design/ASSET_CATALOG.md,.agents/gen/slices/S20-armory-chrome-unify/` | `S20_BRIEF.md` |
