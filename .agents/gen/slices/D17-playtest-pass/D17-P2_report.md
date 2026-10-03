# D17-P2 — in-game playtest report (slice D17-playtest-pass)

Live playtest via godot-ai MCP, 2026-10-03. Findings come from runs 10-11 (runs 7-9 were harness warm-up: two of my own bad game_eval scripts tripped debugger breaks and forced relaunches). Game stopped clean at the end, no process left. No file changed except this report.
Tiers: HIGH blocks or breaks a loop; MED a player-noticed confusion or layout fault; LOW polish. Fix = one-line remedy.
Cites: "shot N" = editor_screenshot source=game at 640, taken in order: 1 main menu; 2-3 settings GRAPHICS; 4 settings AUDIO; 5 settings INTERFACE; 6 settings CONTROLS; 7 quit dialog; 8-15 station ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, FITTING, REPAIRS, LAUNCH; 16-18 flight (launch frame, post-action frame, dock-hint frame). "measured" = get_ui_elements / game_eval rect or text read of the named node, re-derivable in one call.

## Main menu (shots 1, 7)
- LOW | shot 7 | verb hover is still the static ember square border the owner vetoed in B2-1 (EXIT plate while hovered) | fix: move the hover to the tick band or animate the halo, per the pending owner pick.
- LOW | shot 7 | quit dialog copy "You are docked in the Hangar. Progress is saved." plays on the top-level menu where the pilot never entered a hangar | fix: state-neutral copy ("Progress is saved." alone).

## Settings overlay (shots 2-6)
- LOW | shots 2-5 | GRAPHICS/AUDIO/INTERFACE carry 2-5 rows in a full-screen panel, bottom ~70 percent empty | fix: size the panel to content or add section framing.
- LOW | shot 2 | Settings focus style is an ember box + red value text while the main menu focus style is a glow plate; two focus languages across screens | fix: one focus style token used by every screen.
- LOW | shot 6, project.godot:143-150 | CONTROLS lists TURN LEFT / TURN RIGHT as bindable rows but both ship empty bindings, so two of the top rows read UNBOUND on a fresh profile | fix: give them default keys or hide unbound actions behind an "advanced" fold.

## Station chrome (shots 8-15)
- MED | shots 8-15, measured | action-button sizes are all over the station: ammo BUY 64x16, REMOVE 160x48, REFUEL/RECHARGE 174x56, SELL ALL RAW/CANCEL 360x56, SELL/LAUNCH 360x88, rail 272x56 | fix: two theme tokens (primary 360x88, secondary 360x56) applied everywhere.
- MED | shots 8 vs 10-13 | ARMORY pane header has no module icon and its title starts x=472; every other module uses icon + title at x=504 | fix: give ARMORY the same PaneHeader row as the rest.
- MED | shots 13-14, measured | REPAIRS and LAUNCH leave the shared Inspector band empty while every other module fills it | fix: fill it (active hull / launch summary) or hide the band there.
- LOW | measured (Console y=271.554, AmmoScroll rows y=556.678..., HullImage 190.4x88.09) | module content sits on fractional Y/X (105 percent UI scale plus unrounded offsets) so text renders on sub-pixels | fix: floor row origins to integers after scale.
- LOW | measured (CreditsPanel 186 -> 185 px wide after one 59-credit sale) | credits box reflows with the digit run, so the top-right corner jitters on every balance change | fix: fixed-width value label with tabular figures.
- LOW | shots 10, 14 | dev-speak in player copy: "IT NEVER SELLS IN V1", "NO SELL OR DEPOSIT FLOW IN V1", "SHIP VIEWER ONLY", "CARGO ITEM NAMES AND GLYPHS ARE DERIVED FROM THE ITEM ID" | fix: player copy or move to a dev note.

## ARMORY (shot 8)
- MED | shot 8, measured (AmmoLaser children) | ammo row children are hard-offset inside a plain Button (Title +38,1 / Meta +38,17 / Held +38,33 / Buy +250,49): Title/Meta rects overlap 2 px and Held overflows the row bottom 1.5 px, and this bypasses the A5 container law | fix: rebuild the row as HBox/VBox with explicit separations (UI_SPEC 3.10 A5).
- MED | shot 8 | the 64x16 BUY text in the row corner missed my center click and the click silently became a row select (Inspector updated, credits unmoved) with no feedback | fix: a full-row secondary button plus click feedback; route dead clicks to the action.
- LOW | measured (AmmoScroll content 293.99 in a 218.49 view) | pack row 4 (Proton/Flak) sits fully below the fold with no visible scroll affordance | fix: visible scrollbar or fit the 4 rows to the view.

## REFINERY (shot 9)
- MED | shot 9 | REFINERY says "NO STACK SELECTED" while the shared Inspector still shows "LASER CELLS - 120 CREDITS" as selected; the two panels contradict | fix: clear or sync the Inspector on module switch.

## EXCHANGE (shot 10)
- MED | shot 10, measured (SellAllButton.disabled=false) | "SELL ALL RAW" stays enabled with zero raw stacks in hold (SELL and CANCEL correctly disable when nothing is selected), so it is a dead action | fix: disable it when no raw stack matches.
- LOW | shot 10, measured (StepValue "30 UNITS") | the trade stepper defaults to the whole stack and the primary button just says SELL; one stray click dumps everything | fix: default the stepper to 1 and label the button with the quantity.

## AUCTION (shot 11)
- LOW | shot 11 | under the ALL filter the shelf shows 5 hulls while the tag reads "HARDWARE STOCKPILE - 20 MODELS"; nothing says the other 15 await the restock timer | fix: tag reads "5 OF 20 ON SHELF - RESTOCK 20:00".

## SHIPYARD (shot 12)
- LOW | shot 12 | comparison table shows SELECTED vs ACTIVE as two identical columns with no deltas when the active hull is compared to itself | fix: show + / - deltas, or swap the pair for a single "active" card in that case.
- LOW | shot 12 | "IN SERVICE" sits on a button-shaped plate but reads as a status, not an action | fix: render as a badge, or disable and rename to "ACTIVE".

## FITTING (shot 13)
- MED | shot 13, measured (ModuleRows 9 rows x 76 px in a 421 px view) | only 3 of 9 owned-module rows show (row 3 clipped at the fold) and there is no scroll affordance | fix: scrollbar hint, or compact rows to fit the viewport.
- MED | shot 13, measured (SelectionLine, MeterLabel) | the fit flow gives no confirmation or refusal: "SELECT A CELL" on Vector Drive then a click on engine cell left PWR at 1/6 and the footer reading "E1 - Standard Drive" (the cell's prior occupant) while the row advertises "Vector Drive" | fix: confirm fits in the footer/toast, refuse wrong-cell picks explicitly, and name the module the same in both places.
- LOW | measured (SlotCaption), shot 15 | count grammar: "SLOT LAYOUT - 8 CELLS - 1 ENGINES" and "591 ROUNDS ACROSS 1 WEAPONS" | fix: pluralize per count.

## REPAIRS (shot 14)
- MED | shot 14 | ~780 px of dead band between the damage table and REPAIR CONTROL; content uses only the outer thirds | fix: center the pair or let the table span the width.
- MED | shot 14 | intact systems read "NOT REPORTED", which sounds like missing data rather than "OK" | fix: "NOMINAL" (or "100%") for intact systems.
- LOW | shot 14 | "PRIMARY HULL" and "HULL" both appear as row labels with no stated difference | fix: rename ("SHIP HULL" vs "DOCK FRAME") or drop one.

## LAUNCH (shot 15)
- MED | measured (ConfirmStrip.text = "NO_DAMAGE_REPORT") | the strip under the LAUNCH button renders the raw token NO_DAMAGE_REPORT (underscores included) instead of the arm/confirm hint | fix: bind the strip to the confirm state copy ("PRESS TO ARM - SECOND PRESS CONFIRMS").
- MED | shot 12 vs measured (BriefShield "400") | LANCER shield disagrees across screens: SHIPYARD comparison shows 450 (shot 12, 640-read) while LAUNCH briefing shows SHIELD LIMIT 400 | fix: one ShipStats source for both panels (hand-verify the 450).
- LOW | measured (BriefCargo "40 / 25") | the CARGO row reads 40/25 (over its own limit) with no warning state | fix: flag over-limit rows in ember or clamp the copy.

## Flight (shots 16-18)
- MED (HIGH if reproducible by hand) | shot 18 | dock-back never completed from input within ~40 s: ESC arms the dock hint at the crosshair (shot 18) but no dock follows a 10 s hands-off window, and thrust + interact (F) did not reach the dock zone either | fix: verify the dock route autopilot end to end, or dock immediately when ESC is pressed inside the dock corridor; this also blocked my post-return route items.
- LOW | shots 16-17 | the gauge cluster reads 0/100/400/300 with tiny captions and did not visibly react to thrust, fire_primary (15 f) or mine (15 f) in the post frames (ammo may be dry after my sale) | fix: legible gauge labels and verified counters.
- LOW | measured (Game/DevTuningMenu/DevTuningPanel) | a DevTuningMenu ships inside the flight scene tree | fix: strip it from release scenes or hide behind a dev feature tag.
- LOW | shots 16-17 | flight-scale ship sprite still reads as an indistinct scribble (B2 backlog item, reconfirmed) | fix: the queued flight-scale ship cut.

## What passed (no fix needed)
- Keyboard parity: Tab moves focus with the footer readout tracking it, Enter/Space activate the focused button, Esc closes and restores prior focus (MENU_FLOW 4.2). Resolves the open 19_testing_notes item: Enter works; the old "did not register" was a press-only injection artifact (activation needs press + release).
- Quit dialog defaults focus to CANCEL (safe default) and Esc cancels it.
- Economy is exact and propagates: sold 30 Laser Cells (GROSS 60, FEE 1, YOU GET 59) -> credits 80 864 -> 80 923 measured, hold 4 -> 3 stacks, LAUNCH manifest "CARGO HOLD - 3 STACKS", "591 ROUNDS ACROSS 1 WEAPONS".
- Station chrome is coherent across the 7 modules (PaneHeader pattern, 16 px gutters, 32 px insets, shared footer hint line); REFINERY empty state + disabled refine trio and REPAIRS no-damage state are internally consistent.
- Game log (logs_read source=game) is clean for the whole route: zero errors or warnings.

## Route log
- Did: boot -> main menu -> Settings (GRAPHICS, AUDIO, INTERFACE, CONTROLS tabs) -> quit dialog -> PLAY -> ARMORY (buy click landed as row select), REFINERY (empty state; no ore exists to refine), EXCHANGE (stepper + SELL of 30 Laser Cells), AUCTION (selected the Lancer lot), SHIPYARD (row select), FITTING (SELECT A CELL mode + engine-cell pick), REPAIRS (nothing damaged, REPAIR correctly disabled), LAUNCH (2-press arm + confirm) -> flight (thrust ~2.7 s, fire_primary 15 f, mine 15 f, HUD + minimap read) -> dock attempts -> clean restart -> reopened REFINERY and ARMORY (both verified visible/hidden flips).
- Could not reach: dock-back from flight (finding above), so the two post-return module reopens ran from a fresh dock (run 11) instead of a return leg; REFINERY refine (no ore, exchange is sell-only in v1); SHIPYARD purchase (viewer only); CONTROLS rebind capture; audio/graphics setting changes (would alter the run); turning keys (turn_left/turn_right unbound); the ESC pause menu (ESC arms the dock route in flight).
- Harness notes for the next reviewer: injected clicks and keys need a full press + release pair; game_eval code must be a single unindented expression (any script error, including a parse error, parks the game in a debugger break and forces a relaunch).
