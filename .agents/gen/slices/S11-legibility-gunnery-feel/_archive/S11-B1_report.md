---
slice: S11
worker: S11-B1
model: ""             # the orchestrator records the slug that actually ran
status: informational
gate: "775/0 → 13/0 (test_s11_inspector alone); full gate 782/6, all six B3/B4's in-flight suites"
---

# S11-B1 report — station inspector (CONTRACTS §23.1)

## Result

The station has an inspector block and every item pane feeds it. `inspect_requested`
is declared on all eight panes (`ui/station/*_panel.gd`) and emitted by the six item
panes on hover-in, hover-out (`title == ""`) and selection; the shell adds
`Layout/Page/Inspector` immediately above the status strip with the pinned nodes and
`Tokens/text_primary` body override; `StationCatalog.describe` resolves a `mod_*`
instance through its base and appends its rolled affix perks, `StationCatalog.group_int`
is the one digit-grouping copy and `station.gd:_format_int` delegates to it.

`tests/test_s11_inspector.gd` is green `passed=13 failed=0` (B1's half; B2 owns the
credits half of the same file). Every station-related suite together is `236/0`.

## Deviations from SLICE.md / the pin (judgment calls, each with a reversal)

1. **`describe` follows the pin's source list exactly**: `ModuleCatalog.MODULES`,
   `SHIPS`, `AMMO_PACKS`, `SERVICES` (`game/station_catalog.gd:364`). A row one of those
   tables does not carry therefore answers `""` — so a REFINERY ore row and an EXCHANGE
   mineral/component hold row get a title and an empty body. The pin's four sources are
   read literally; widening to `MineralCatalog`/`ComponentCatalog` (whose rows do carry
   `description`) is a §23.1 change, so it is a report, not an edit.
   Reversal: add the two catalogues to `_description_of`'s list.
2. **An `ammo_*` cargo id resolves to its pack** (`game/station_catalog.gd:369`), so
   EXCHANGE's ammo hold row reads the pack's own prose. The pin names "the ammo rows";
   the cargo id is that row's id in the pane, and the mapped text is the pack's own
   `description`. Reversal: drop the `ammo_pack(ammo_family(id))` row.
3. **The title is the pane's existing hint string**, reused verbatim (`_row_hint`,
   `BARREL_TEXT`, `STATUS_READY`) rather than a new `"%s · %s CREDITS"`. The pin says
   "never a new format string if the pane already prints one"; those hints are the
   pane's own name+price wording and no status string is reworded (only emitted to a
   second surface). Reversal: strip the leading verb per pane.
4. **The block stays mounted with empty text on `title == ""`** rather than hiding, so
   the page does not reflow under a moving pointer. The pin says "clears the block" and
   "the page pays ≈3 caption lines of pane height". Reversal: set `Inspector.visible`.
5. **`INSPECTOR_BODY_MAX_LINES := 2` lives in `ui/screens/station.gd:129`** (the pin's
   code block is labelled `station.tscn`, which carries no consts); the scene carries the
   same `max_lines_visible` and `_apply_tokens` re-applies the const
   (`ui/screens/station.gd:250`). Reversal: delete the const and keep the scene value.
6. **`danger` is the row's own unavailability**, currently only ARMORY's incomplete ammo
   card (`ui/station/armory_panel.gd:1451`); every other catalogue row is actionable and
   passes `false`. Reversal: pass `false` there too.

## Evidence

- Gate, scratch store:
  `XDG_DATA_HOME=$(mktemp -d) timeout 900 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`
  → `[SUMMARY] passed=782 failed=6`. **None of the six is S11-B1's**: every one is a
  B3/B4 sheet whose code landed in the shared tree without its re-derived test row —
  `test_engine2_weapons.gd.test_ranges_are_the_section_13_row: laser 500`,
  `test_engine_c3_flight_decay.gd` (angular damp), two `test_s2_6_flight.gd` rows and two
  `test_s7_affixes.gd` rows (coast 2.5 vs 2.0). The count moved 784→782 between two runs
  as B4's edits landed, so the live number is volatile mid-wave.
- B1's own suite: `-- --suite=test_s11_inspector` → `[SUMMARY] passed=13 failed=0`.
- Regression scope, all 18 station-touching suites (d6_status, d7_armory, p2a_ship_roster,
  p2b1_o/panel, p2b_fitting/retirement/services, s10_armory_input, s11_inspector,
  s3_auction, s4_batteries, s5_ammo/batteries_v2/commerce, s6_heat, s8_launch/qa,
  ui_slot_layout) → `[SUMMARY] passed=236 failed=0`.
- Pinned declaration: `rg -n 'signal inspect_requested' vajb-orbit/ui/station/*_panel.gd`
  → exactly eight hits, one per pane.
- Emit sites (hover-in/out and selection): armory
  `ui/station/armory_panel.gd:1312,1316,1330,1651,1655,1863,1867`; shipyard
  `ui/station/shipyard_panel.gd:984,991,1027`; exchange `ui/station/exchange_panel.gd:714,723,727`;
  auction `ui/station/auction_panel.gd:976,993,997`; refinery
  `ui/station/refinery_panel.gd:560,567,571`; fitting
  `ui/station/fitting_panel.gd:1109,1124,1155,1173`.
- Block: `ui/screens/station.tscn:214` (`Inspector`), `:230` (`InspectorTitle`),
  `:236` (`InspectorBody`, `SectionHeader` + the `text_primary` literal + `autowrap_mode 3`
  + `max_lines_visible 2`); handler `ui/screens/station.gd:454`, wiring `:323`.

## Files touched

- `game/station_catalog.gd` — `describe`, `group_int`, the base/row/affix readers.
- `ui/screens/station.tscn` — the `Inspector` block above the status strip.
- `ui/screens/station.gd` — the const, the pane wiring, `_on_panel_inspect`, token
  re-application, `_format_int` delegates to `group_int`.
- `ui/station/armory_panel.gd`, `shipyard_panel.gd`, `exchange_panel.gd`,
  `auction_panel.gd`, `refinery_panel.gd`, `fitting_panel.gd` — the signal plus the
  hover-in/hover-out/selection emits.
- `ui/station/repairs_panel.gd`, `launch_panel.gd` — the signal, never emitted.
- `tests/test_s11_inspector.gd` — new suite (B1 half; B2 appends the credits half).

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| REFINERY/EXCHANGE mineral+component rows carry no inspector body under §23.1's four sources | pin question for R1/owner | `game/station_catalog.gd:364` |
| The block's clear semantics (empty text vs hidden) and the title's leading verb are planner-taste, unpinned | notice | `ui/screens/station.gd:454`, `ui/station/armory_panel.gd:1447` |
