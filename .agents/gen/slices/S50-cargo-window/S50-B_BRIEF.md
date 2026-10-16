# S50-B — the moveable cargo window + the shell HOLD chip (review, read-only)

You are worker S50-B, a code reviewer. This is a READ-ONLY audit: you write
nothing except your report file.

## Goal
Review the A22/A23 implementation at the current working tree (the armory
restore, the moveable overlay, the shell chip) for container/geometry and
logic defects. The earlier S50-A report (same folder) graded the previous
round; this one grades the delta.

## Files
- `vajb-orbit/ui/dialogs/cargo_overlay.gd` + `.tscn` — the moveable window:
  `_center_panel`, `_clamp_panel`, `_on_title_row_input` (the drag), the CLOSE
  chip, the `CargoCenter` type change (CenterContainer → Control). Check: the
  drag event math (press offset, motion ride), the clamp's edge cases (a panel
  taller/wider than its viewport, zero-size states), `reset_size()` semantics
  vs the A15 law (720 wide / the 80 % cap), the title row's mouse filters (the
  chips must keep their own presses, the dimmer must still close), the flight
  plane riding the same scene.
- `vajb-orbit/ui/screens/station.gd` + `.tscn` — the HOLD chip: the
  InspectColumn restructure (does the header's 76 px band still hold two 32 px
  chips + 8 separation without growing?), `_on_hold_pressed` → `_toggle_cargo`
  (the guards), any station reads broken by InspectButton's reparent.
- `vajb-orbit/ui/station/armory_panel.gd` + `.tscn` — the restore: orphaned
  references to the removed pages/window (`LeftTabs`, `PageHold`,
  `_cargo_window`, `Summary`), the equipped block's flags back at
  expand/no-floor, the stack order grid → cell info → equipped.
- The tests that moved: `tests/test_s43_armory_equipped.gd` (the p49 rows back
  on the pre-split law, the A21 armory row retired), `tests/test_s30_shell.gd`
  (the new A22 row), `tests/test_s48_cargo_overlay.gd` (the new A23 row).

## The law
`docs/design/UI_SPEC.md` §20.2 (A22/A23) and §20.1's surviving pins (A21.2's
launch seat stands). Range-read by the generated index at the top.

## Findings format
One line per finding:
`F## | file:line | HIGH|MED|LOW | <what breaks and when> | <suggested fix>`
Severity: HIGH = a reachable break (a crash, a stuck window, an escape); MED =
latent under plausible states; LOW = style-law drift.

## Acceptance list (answer each, one line)
1. Can the drag handler strand the window outside the viewport (any press/motion
   sequence, any window size)?
2. Does the clamp hold when the panel is bigger than its viewport (small game
   windows)?
3. Do the SORT/CLOSE chips keep their own presses while the title row drags?
4. Does the flight plane (the same scene) behave — its host Control and layer?
5. Does the header column hold two 32 px chips inside the 76 px band, and does
   the INSPECT toggle still work after the reparent?
6. Any orphaned armory references (nodes, consts, vars, tests) that the restore
   left behind?

## Report
Write `.agents/gen/slices/S50-cargo-window/S50-B_REPORT.md`, ≤120 lines:
Result (2-3 lines), Acceptance answers (numbered, cite file:line), Findings
(the F## lines), Open questions, Evidence.
