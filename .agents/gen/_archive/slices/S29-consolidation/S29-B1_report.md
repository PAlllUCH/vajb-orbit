---
slice: S29
worker: S29-B1
model: "mimo-v2.6-pro (re-dispatch; the first attempt died on provider credits mid-work)"
status: informational
gate: "1038/0 -> 1063/0 (x2, fresh scratch)"
---

# S29-B1 report

## Result
A1–A3 ship: the map deck (M / corner EXPAND / ESC), the filter column with per-profile
persistence, the N15–N22 classes with the N19/N20 rides, the N23 inert rule and the N6
always-on pair, the navigation pin (the fixer's precedence, press-down placement, 8 px pan
threshold, hold-to-jump) with the N5 machine's reads, and the `e_hyperdrive` row in the
catalogue + the auction SOURCE_ROLLS engine column. Gate x2 on fresh scratch:
`[SUMMARY] passed=1063 failed=0` both runs.

## Resume disclosure (the crashed attempt)
The re-dispatch found a partial diff in tree. **Kept**: `module_catalog.gd`'s
`e_hyperdrive` row + `ICON_REUSE` (checked verbatim against R-S29-1),
`player_ship.gd`'s `HYPERDRIVE_MODULE` + `has_hyperdrive`, `minimap.gd`'s KIND_* and pin
constants. **Redone**: `jump_to` — the partial version wrote `global_position` only, but
`_sync_hull_transform` (player_ship.gd:1271) mirrors body → node every physics step, so
that teleport snapped back one frame later; it now moves the solver's body and restores
the mirror's invariant (player_ship.gd:453). **Finished**: the deck, filters, pin machine,
the N5 machine, the corner button, both suites.

## Acceptance list answers
- **A1 — DONE** — N1 pane at anchors .1…9 (`PanelRaised`, `map_deck.gd:104`) with M and
  ESC (`map_deck.gd:124`, `game.gd:952`) and the corner EXPAND beside the shipped zoom
  pair (`hud.tscn:429`); N2 wheel zoom 25–400 % cursor-centred, 64 px arrows
  (`minimap.gd:317,326`; `map_deck.gd:69`); N3's eight toggles + `MAP FILTERS` caption
  (`minimap.gd:205`; `map_deck.gd:262`) persisted per profile (`map_deck.gd:521`);
  N15–N22 classes with N19/N20 rides, N23 inert and N6 exempt as one predicate
  (`minimap.gd:232,241`), anchored on the re-anchored station/gate emitters
  (`sector.gd:279,282`); deck chrome on the A5.4 Pane / A5.4-2 / A5.4-3 rows
  (`map_deck.gd:83-93,241-296`).
- **A2 — DONE** — press-down hit-tests the pin first (remove candidate, never a place or
  move, `map_deck.gd:419`); the pin is placed at press-down and a held move past the 8 px
  threshold is a pan (`map_deck.gd:70,399`); the short press issues the existing order
  (`player_ship.gd:428` via `game.gd:2345`) and the pin's remove calls `cancel_orders`
  (`game.gd:2352`); stick-cancel untouched (`player_ship.gd:848`); hold ≥ 0.5 s requests
  the jump (`map_deck.gd:150`) with `NO HYPERDRIVE INSTALLED` otherwise
  (`game.gd:2361`); N5 reads `HYPERDRIVE SPOOLING` / `JUMP COOLDOWN <t> s` / `JUMP READY`
  / `ARRIVED · <name>` (`game.gd:2421`); the compact map carries the bearing arrow and
  `DIST <n>` on its `SectorLabel` line (`minimap.gd:420`; `hud.gd:595`).
- **A3 — DONE** — `e_hyperdrive` carries R-S29-1 verbatim (tier 3, `engine`, 12 000 CR,
  draw 3; `module_catalog.gd:595`), rolls in the auction SOURCE_ROLLS engine column
  (`test_s29_hyperdrive.gd:110`) and reuses `e_vector`'s glyph (no new art,
  `test_s29_hyperdrive.gd:129`); the ARMORY browser listing stays B2's surface.
- **A8 — DONE** — gate x2 fresh scratch `passed=1063 failed=0`; every moved row below.

## Moved test rows (suite:line — the L264 disclosure)
- `test_s6_poi_loot.gd:581` — "the station, the gates and the beacons are the friendly
  blips" (`gates + beacons + 1`) → station/gate/friendly split. N15/N16 re-anchor.
- `test_d11_station.gd:98` — "the station blips friendly" → `&"station"`. N15.
- `test_engine2_wiring.gd:298` — the friendly count row → the same three-way split. N15/N16.
- `test_s17_gate_edges.gd:249-255` — "one friendly blip" → `&"gate"` filter + wording. N16.
- `test_ship_grids.gd:858` — "35 rows (09 section 3 + 15 section 9.1)" → 36 rows, with the
  R-S29-1 row added to the check table (`test_ship_grids.gd:98`). A3.
- NOT moved: `test_s3_auction.gd` (the brief §8 predicted it) — its pools partition derives
  every count (`test_s3_auction.gd:385-404`), so the new row moved no number.

## Deviations (what, why, reversal)
1. Label variations: the wireframe cites `StationCaption` 13 / `StationValue` 18, which
   measure 9.00 / 11.574 px cap against D8-H3's pinned 12 px floor (measured; the floor
   table sweeps every HUD label, `test_d8_hud_visibility.gd:478`). All deck and pin labels
   wear `HudReadout` 18 (12.42 px). Reversal: relax the floor row, return to the cites.
2. Zoom step: N2 pins only the 25–400 % clamp; the wheel notch / foot button step is
   ×1.25 (**PROPOSED**, `minimap.gd:326`). Reversal: any step — the clamp is the pin.
3. ESC seam (bucket 2 flag, ENGINE_SPEC §9.9 vs UI_SPEC N1): the press that closes the deck
   does not run §9.9's fly-to cancel (the pin's order must survive the map — its cancel
   routes are stick input, the pin's remove and arrival); the opening press keeps §9.9
   verbatim (`game.gd:952`). Reversal: restore `cancel_orders` on both presses — the pin
   flow then dies on every map close.
4. Pin remove calls `cancel_orders` per UI_SPEC §10's parenthetical; the d18 wireframe says
   "pin removed, order stays" — a contradiction inside the design of record, the later
   fixer text taken as law. Reversal: drop the `autopilot_cancel` emit (`map_deck.gd:443`).
5. A pan's release issues no order (N2/N14 classify the held move as a pan). Reversal:
   treat sub-0.5 s releases after a pan as clicks.
6. `ARRIVED · <name>` reads the sector display name — the flight scene's only name
   (`game.gd:2421`) — and the arrival re-centres the deck view (the wireframe's "blip
   re-centring"). Reversal: leave the player's pan where it is.
7. N3's persistence rides PlayerProfile's config store through dynamic get/set
   (`map_deck.gd:521`): the declared file set (ui/hud/, game/, tests/) carries no save
   door and `autoload/` sits outside it. Reversal: a first-class `map_filters` key in
   `player_profile.gd` — one file outside VAJB_WORKER_FILES, designer call (bucket 2).
8. Derived mechanism numbers (rule 1: reported, not pinned): pin hit box = 2× `PIN_RADIUS`
   (`minimap.gd:64`); pane inset 36 (A5.4's pane row + Q1, `map_deck.gd:66`). Fields, POIs
   and convoys keep their shipped feed kinds (`neutral`/`blip_kind`) — N23 leaves those
   toggles inert; only station/gate re-anchor (N15/N16 + "anchored on the new classes").

## Evidence
- `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`, twice, fresh scratch each:
  run 1 `[SUMMARY] passed=1063 failed=0`; run 2 `[SUMMARY] passed=1063 failed=0`.
- 1063 = the 1038/0 baseline + 25 new rows (`test_s29_map_deck.gd` 16,
  `test_s29_hyperdrive.gd` 9).
- Close-out note: the `map_toggle` `project.godot` row (M + rebinding) is
  orchestrator-applied at close-out — the `ship_status` precedent; M already works through
  the raw-key fallback (`map_deck.gd:336`).

## Files touched
- `vajb-orbit/ui/hud/map_deck.gd` — NEW: the deck pane, filter column, pin machine, input.
- `vajb-orbit/ui/hud/minimap.gd` — class table, filters, pin marks, the deck view law.
- `vajb-orbit/ui/hud/hud.tscn` / `hud.gd` — corner EXPAND button, deck build + wiring, pin reads.
- `vajb-orbit/game/game.gd` — the N5 machine + reads, the ESC route, HUD API rows.
- `vajb-orbit/game/player_ship.gd` — `jump_to` redone (body teleport, mirror invariant).
- `vajb-orbit/game/sector.gd` — station/gate blips re-anchored to the N15/N16 classes.
- `vajb-orbit/game/module_catalog.gd` — kept from the partial diff (row + icon reuse).
- `vajb-orbit/tests/test_s29_map_deck.gd`, `test_s29_hyperdrive.gd` — NEW suites.
- Moved-row edits: `test_s6_poi_loot.gd`, `test_d11_station.gd`, `test_engine2_wiring.gd`,
  `test_s17_gate_edges.gd`, `test_ship_grids.gd`.

## S29-F1 fixer note (2026-10-03)

Cured exactly the review's HIGH and MED; the LOWs F3–F9 ride as tickets T-100–T-106.

- **F1 (HIGH) cured** — the pin's two marks drew `Color.WHITE` because nothing ever
  assigned their colour. `PinDiamond.colour` and `EdgeArrow.colour` now take the pinned
  token `text_primary` (`PIN_COLOUR`, `minimap.gd:58`) at build time
  (`_build_pin_marks`, `minimap.gd:394,414`) and re-read it on theme changes
  (`_refresh_colors`, `minimap.gd:590-597`, alongside the other tokens). §10's diamond
  reads "in `text_primary` at 6 px (reversal `accent_ember`)" — the token is applied, the
  reversal is `accent_ember` if the owner ever re-pins. The class doc comment now tells
  the truth: the marks draw the deck's resolved token, they never read it themselves
  (`minimap.gd:608-612`).
- **F2 (MED) cured, designer ruling recorded** — bucket-1 reconciliation, no pin edited:
  **section 9.9's cancel and section 10's pin-remove are one operation.** When the
  ESC-open path cancels orders it also clears the pin, so the deck never reopens on an
  orderless pin. The one-line cure rides `game.gd:966-969` (`clear_map_pin` beside
  `cancel_orders`); the ruling and its reversal are recorded in the seam's doc comment
  (`game.gd:951-953`). The pin-clear needed the seam the deck did not expose, so two
  thin lines were added following the shipped idiom (`set_map_jump_read`/`map_recenter`):
  `map_deck.gd:182-186 clear_pin()` and `hud.gd:519-523 clear_map_pin()` — it rides
  `pin_changed`, so the compact map and the N4 caption clear with the deck's pin
  (`hud.gd:567-573`). A closing ESC still toggles alone: the order and the pin survive
  the map close (`game.gd:963-964`).
- **Files touched** — `vajb-orbit/ui/hud/minimap.gd`, `vajb-orbit/game/game.gd`,
  `vajb-orbit/ui/hud/map_deck.gd`, `vajb-orbit/ui/hud/hud.gd`. Nothing else moved; the
  LOW findings are untouched.
- **Gate** — two runs on fresh scratch (`XDG_DATA_HOME=$(mktemp -d)` each,
  `~/.local/bin/godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`):
  run 1 **`[SUMMARY] passed=1073 failed=0`** (`/tmp/s29_f1_gate1.log`),
  run 2 **`[SUMMARY] passed=1073 failed=0`** (`/tmp/s29_f1_gate2.log`). Zero failures.
