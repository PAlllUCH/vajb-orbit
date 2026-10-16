# S50-B — the moveable cargo window + the shell HOLD chip (report)

## Result
The A22/A23 delta holds its law: the armory restore is clean (no split, no embedded
window, the equipped block back at expand/no-floor in the P49 order), the HOLD chip
rides the header column through the C step's own guard ladder on every module, and
the overlay is a real moveable window — centered on open at A15's 720/80 % geometry,
the title row the drag handle, the chips and dimmer keeping their own presses, the
flight seat untouched. Three MED findings survive, all in the drag/clamp's edge
states: a viewport narrower than the 720 panel, a viewport resized while open, and a
close mid-drag arming a stale drag. No HIGH.

## Acceptance answers
1. No — the window cannot be stranded outside the viewport: every drag motion ends
   in `_clamp_panel()` (cargo_overlay.gd:326-327) and every `open()` re-centers then
   clamps (:692-695). Three reachable states still degrade it, none of them an
   escape: viewport < 720 wide pins the panel at (0,0) with its right edge
   unreachable (F01), a window resize while open leaves a stale oversized panel
   pinned (F02), and a close mid-drag arms a stale drag that hover-teleports the
   reopened window (F3) — every path stays clamp-bounded inside.
2. No — the clamp holds only while the panel fits. `max_pos = (view - size).max(ZERO)`
   (cargo_overlay.gd:700-701) collapses to (0,0) when the panel exceeds the viewport,
   pinning it and hiding the overflow: width does below a 720-wide canvas (F01);
   height only after an unre-fit resize (F02) — a fresh `_fit()` keeps the panel at
   ≈ view·0.8 tall (the cap counts margin + insets, :682-684), so it can never
   out-height its viewport on its own.
3. Yes — the SORT and CLOSE chips are STOP Buttons inside the title row
   (cargo_overlay.tscn:75-88), so their presses are consumed before the row's
   `gui_input` sees them; the title Label ignores (Label's default), so the drag
   works through it; wheel is excluded by the LEFT-button check
   (cargo_overlay.gd:321); Godot's press capture delivers the ride and the release
   to the row, so a drag ending over a chip cannot click it.
4. Yes — the flight plane rides the same scene unchanged: a direct child of the
   layer-20 `CargoOverlayLayer` (game.gd:2562-2572), full-rect on an identity
   CanvasLayer, so the drag's viewport-space math (`event.global_position` vs
   `_panel.position`) holds; the C/ESC ladder and the HUD mirror are untouched
   (game.gd:1054-1057, 1713-1740).
5. Yes — the column is 32 + 8 + 32 = 72 px against the header's 76 px band
   (station.tscn:73-102), so the band does not grow; the INSPECT toggle survives the
   reparent through `%InspectButton` (unique_name_in_owner kept, station.tscn:91;
   wiring station.gd:274, 496, 1023-1056) and the ESC ladder is unchanged
   (station.gd:2081-2098).
6. No orphans — armory_panel.gd/.tscn carry no `LeftTabs`/`PageHold`/
   `_cargo_window`/`Summary` reads; the left stack is grid → CELL INFO → EQUIPPED
   with the equipped block and its scroll back at expand and no floor
   (armory_panel.tscn:130-216); the launch's `_cargo_window` (launch_panel.gd:199)
   is the surviving A21.2 seat, not an orphan; s43 carries no A21 rows and no test
   reads the split or an armory window.

## Findings
F01 | vajb-orbit/ui/dialogs/cargo_overlay.gd:698-701 (+ _fit 679-684) | MED | with the viewport narrower than the 720 panel — reachable: project.godot:30-35 sets no window minimum and `canvas_items`+`expand` lets the visible canvas shrink under 720 (e.g. a ≈ 600 px-wide window) — `max_pos` collapses to (0,0), the clamp pins the panel there, and the right edge (the AMOUNT column and every DISPOSE chip) is unreachable and cannot be panned back by the drag | floor the panel width to the viewport in `_fit()` (`minf(PANEL_WIDTH, view.x - PANEL_MARGIN*2 - inset.x)`; A15's 420 floor already names the low end) or make the clamp two-sided so an oversized panel can pan — pin-adjacent (it reshapes A15's fixed 720 in a reachable state, bucket 2)
F02 | vajb-orbit/ui/dialogs/cargo_overlay.gd:167-171 | MED | no re-fit on a viewport resize while open: `_notification` handles only THEME_CHANGED, so the scroll's 80 % cap and the panel's size stay stale after the window shrinks — the panel out-grows the viewport, the clamp pins it at (0,0), and the bottom rows are unreachable until some incidental re-fit (tab, sort, dispose, profile change); recovery is CLOSE + reopen | handle NOTIFICATION_RESIZED (the full-rect root fires it on a window resize) → `_fit()`, which already re-clamps and re-measures (bucket 1)
F03 | vajb-orbit/ui/dialogs/cargo_overlay.gd:320-327 (+ close 199-204) | MED | `_dragging` survives `close()`: C mid-drag (flight polls `cargo_toggle` every frame; the station's ESC ladder fires during a gui drag) closes the overlay while the flag stays armed, so after the next `open()` the first mouse motion over the title row teleports the panel to `cursor + the stale press offset` without any button held (self-heals on the next press+release over the row) | reset `_dragging = false` in `close()` (and in `open()`), and/or gate the motion branch on `event.button_mask & MOUSE_BUTTON_MASK_LEFT` (bucket 1)
F04 | vajb-orbit/ui/screens/station.tscn:98-102 | LOW | the HOLD chip lacks the `size_flags_vertical = 4` the header's other two chips carry (:83, :94); inside the VBox the slot equals the 32 px minimum so it renders identically today, but it drifts from the header's own button idiom the A22 pin names | add the flag for idiom parity (bucket 1)

## Open questions
- cargo_summary.gd:249 (and the A21 pin it mirrors) still justifies the
  `CargoWindow` root name by "the armory's window cannot collide" — the armory seat
  retired with A22; the law text is owner-locked, the comment is its echo. Sweep at
  close-out or fold into the next law amendment.
- The gate evidence below is one pass; the run-to-run byte-identity proof is still
  the close-out's `--times 2` owe.

## Evidence
- Read end to end: the brief; UI_SPEC §18 (A7-A17) and §20/20.1/20.2 by range; the
  nine files listed; game.gd's flight seat (:2562-2572, :1713-1740) and station.gd's
  cancel ladder (:2081-2105); project.godot:30-35.
- Gate: `python3 staging/gate.py --times 1` → `[SUMMARY] passed=1430 failed=0`
  (the three moved suites ride in it).
- Delta shape: `git diff --stat` — armory −71/−64 lines (A19 block + A21.3 split
  gone), overlay +47, station +9/+12, tests +24/+61/−87+retired rows.
- Drag mechanics: Godot's viewport captures the press target, so motion and release
  keep arriving at the title row while the button is held (the ride and the release
  both land, cargo_overlay.gd:320-327); `CURSOR_DRAG` = 6 in 4.7's enum, matching
  the scene's `mouse_default_cursor_shape = 6` and the s48 assertion.
- reset_size() vs A15: `_fit()` runs before `_center_panel()` in `open()`
  (:190-192), so the scroll's `custom_minimum_size.y` already carries the cap when
  `reset_size()` snaps the panel to its combined minimum — the centered geometry is
  exactly 720 × (0.8·view) with no dependence on stale layout.
