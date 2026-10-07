# D17-P1 — in-game playtest review (2026-10-03)

Ran the live build through godot-ai: boot → main menu → settings → station hub (all 7
modules) → launch → flight. Screenshots at 640 (two at 1152 for text verification). No
files touched but this report. Tiers: HIGH breaks a loop, MED a player-visible fault,
LOW polish. Every line carries a cite (screenshot described by timestamped capture in
this session; no screenshot files were written to disk) or a file/line.

## Boot / splash

- LOW — splash holds ~4 s with no skip; per MENU_FLOW §3.1 that is as specified, but the progress line under the logo is barely visible at 640. Fix: brighten the preflight progress line one step.

## Main menu

- MED — hover affordance is still the static rectangular ember border (known B2-1, reconfirmed live). Fix: owner pick pending; nothing to do until then.
- MED — keyboard focus and hover are nearly indistinguishable: focus shows only as the lit tick bar, hover shows only as the plate border; Down-arrow focus looked "off" until the footer readout changed. Fix: give the focused plate a shared visible state (e.g. same ember rim as hover).
- OK — Enter activates the focused verb (OPTIONS opened via injected Enter); the batch-2 note "Enter did not register" did not reproduce.

## Settings

- MED — CONTROLS ships conflicting bindings without warning: Q is listed for STRAFE LEFT, PITCH and TARGET NEXT (I row plus a second TARGET NEXT row bound to Q); E doubles as STRAFE RIGHT and PITCH. Fix: one binding per action per key, or a conflict highlight.
- LOW — AUDIO tab shows a row labelled "SIP 0%" — unclear/placeholder label (read at 640; verify at native res). Fix: rename or remove.
- OK — GENERAL / AUDIO / INTERFACE rows are sparse but aligned; BACK returns to the menu.

## Station hub — shared chrome

- MED — the bottom inspector bar keeps the previous module's hover text after switching modules (Lancer's ship stats still shown after opening REFINERY). Fix: clear or re-anchor the inspector on module switch.
- LOW — footer hint strip is consistent and correct on every module ("ARROWS MOVE · ENTER CONFIRM · TAB RAIL · PGUP/PGDN MODULE · ESC BACK"). No fix needed.
- MED — "TAB RAIL / ENTER CONFIRM" is not delivered: a scene search found only one focusable BaseButton in the station scene; the rail entries are custom Controls, so the keyboard path the footer promises cannot exist. Fix: give rail entries and module buttons focus_mode + pressed handling.

## ARMORY

- MED — all empty hardpoint cells render a "DROP HERE" ghost label (13 of 15 cells on boot state); the screen reads unfinished. Fix: dim outline slots with no text.
- LOW — barrel-inventory panel has a large dead area under its 2 rows. Fix: shrink the panel to content.
- LOW — ammo card status chips mix states ("IN STOCK" next to "HELD 0/40" and BUY; "BELOW CAPACITY" on an empty item). Fix: derive the chip from held/cap only.

## EXCHANGE

- MED — YOUR HOLDINGS table has no column headers (three bare number columns per row); values are unreadable without a legend. Fix: add HELD / CAP / VALUE headers.
- LOW — holdings label "MINE BACK" reads like a typo for MINE PACK (640-res read; verify). Fix: confirm and rename.
- OK — market board rows (IRON/COPPER/CHROMIUM/SILICON/ALUMINIUM/TITANIUM with trend + state) aligned and consistent.

## AUCTION

- OK — hover drives the inspector: the bottom bar shows the hovered ship's stats while hovering a listing (matches the D16 intent).
- MED — after BUY the listing flips to OWNED but the bottom inspector goes blank; the only feedback is the one-line status text. Fix: keep the bought ship's stats in the inspector.
- LOW — filter tabs (WEAPONS…UTILITY) not exercised beyond the default ALL view.

## SHIPYARD

- MED — hull list rows pack two unlabeled stats per row ("VANGUARD 0/304 · HULL 2/305" pattern); meaning is guesswork. Fix: label the stat pair or move to columns.
- LOW — after SET ACTIVE the comparison panel shows identical numbers in both columns (comparing the hull to itself); reads empty rather than "current". Fix: hide the panel or show "IN SERVICE".

## FITTING

- MED — interaction model is unclear: owned-module rows show "SELECT A CELL" with no visible cell-selection affordance; FIT / SWAP / SELECT A CELL appear inconsistently across rows; REMOVE is permanently visible while disabled. Fix: one consistent affordance (select cell → fit) with the disabled state greyed out entirely.
- LOW — slot-grid icons carry no labels and "PWR 3 / 6 · CANDIDATE 1 / 6" uses an undefined term. Fix: tooltip on cells; rename CANDIDATE.

## REPAIRS

- MED — the damage report lists MISSING and FEE as damage categories with value "NOT REPORTED"; a fee cannot be "reported" and both rows read unfinished. Fix: drop them from the report body, keep fee in the footer line.
- OK — ship-section rows (PROW/STERN/PORT/STBD) and the disabled REPAIR button with "NO DAMAGE REPORT" are coherent when undamaged.

## LAUNCH

- MED — the 3 s double-press confirm could not be completed through any injected input path: mouse double-click exceeded the window (tool latency), and frame-timed ui_accept on a focused LaunchButton did not confirm; only emitting the button's pressed signal directly launched the ship. Injection latency may be at fault (same caveat as B2-4) — verify by hand. Fix: widen the window to 5 s and add a keyboard path.
- OK — flight briefing reflects state: after fitting the laser it showed "595 ROUNDS ACROSS 1 WEAPONS" (was "0 ROUNDS ACROSS 0").
- LOW — could not verify REFUEL/RECHARGE feedback; the click that was meant to refuel read as a launch arm in the status line.

## Flight

- HIGH — no way home: after ~20 s of flight the minimap shows only SELF, target_next finds nothing, ESC does nothing, and there is no station marker or off-map indicator. The ship is lost with no in-HUD recovery (I had to read node positions through the debugger: player (1584, −19252), station (0,0) — 19.3k px apart). Fix: station/off-map edge arrows + a dock hint when in dock-zone range.
- MED — initial turn response is nearly dead: held turn yields ~0.02 rad/s for the first seconds and builds up slowly; a 180° turn costs roughly a minute of holding. Fix: raise base angular acceleration.
- LOW — firing the laser produced no visible projectile or beam in the frames checked (may fall between frames; verify by hand).
- OK — thrust, coast inertia, speed/hull/shield/ammo gauges, minimap legend (SELF/HOSTILE/FRIENDLY/SWARMER/GHOST) and region name (Halcyon Reach) all present and coherent.

## Route log

Did: boot → splash → main menu (hover + keyboard focus + Enter) → settings (all 4 tabs) →
PLAY → station hub → ARMORY (bought Mine Stock, status confirmed) → EXCHANGE (read;
holdings + market) → AUCTION (bought Courier, 21,000 CR; hover-stats verified) → SHIPYARD
(read; SET ACTIVE Lancer → "IN SERVICE") → REFINERY (empty-state read) → REPAIRS (read) →
FITTING (fitted Laser Midi into a cell, then removed it) → LAUNCH (briefing verified; arm
worked, confirm needed a direct pressed-signal emit) → flight (thrust, fire primary,
target_next onto a hostile "Warder" with HULL/SHIELD/NOT IN RANGE panel, ~25 s flight).
Two game_eval compile errors parked the game in a debugger break mid-run; both times the
run was stopped and relaunched (state persisted; purchases intact).
Could not reach: asteroid mining or asteroid contact (all six fields far outside
navigable range given the flight findings), docking back, and the post-return module
re-open — blocked by the HIGH navigation finding above. Game stopped afterwards; only the
pre-existing editor process and MCP plumbing remain (no game process).
