---
slice: S28
worker: S28-B1
model: hyper/qwen3.8-flash @ high
status: actionable
gate: "1031/0 -> 1038/0 (two fresh-scratch runs, 2026-10-03)"
---

# S28-B1 report — station chrome quick fixes

## Result
A1-A16 shipped on the survivors (refinery, exchange, auction, LAUNCH, shell,
settings, menus); armory/fitting/shipyard/repairs bodies untouched. Gate
`passed=1038 failed=0` twice on fresh scratch; 1031 baseline + 7 added rows.

## Acceptance list answers
- **A1** band clears on switch (`_clear_inspector()` in `_select_module`,
  `station.gd:473,532`) and a non-host pane's publish is dropped
  (`station.gd:385` bind, `521-523` guard). Pins: `test_s11_inspector.gd:316,328`.
- **A2** route = fold + steal + scan (no default keys: project.godot is outside
  the file set and AGENTS.md bars hand-editing it). Measured: the shipped map
  binds Q once (`target_next`) and E once (`mine`) - the playtest's duplicates
  are the persisted-profile case. A commit steals the key from every other
  action and persists via `save_inputs` (`settings.gd:314`); duplicates existing
  at build are flagged (`settings.gd:332`), the flag reads as words not colour
  (`settings_rebind_row.gd:86-88`); TURN LEFT/RIGHT fold behind ADVANCED
  (`settings.gd:37,188`). Pin: `test_flight_feel_g1.gd:662`.
- **A3** `ConfirmStrip` belongs to the arming copy: service/bounty reports go to
  the shell's status line only and the strip re-anchors (`launch_panel.gd:504-514`);
  refusals read as play copy, unmapped tokens de-underscore, never ride raw
  (`REFUSAL_COPY` `launch_panel.gd:155`, `_refusal_copy:516`). `Repairs.REASON_*`
  API untouched. Pins: `test_p2b_services.gd:660,675`.
- **A4** winning figure = **400**, the catalogue hull row's `shield`
  (`station_catalog.gd:112`) - read by the launch briefing (`launch_panel.gd:561`)
  and the shipyard comparison (`shipyard_panel.gd:843-848`, read-only). No
  shipyard path renders 450; it is the Fighter's `max_speed` - the 640 misread.
  Guard: `test_p2b_services.gd:709` pins both readers to one number.
- **A5** `StationCatalog.plural()` (`station_catalog.gd:377`), S8's
  `1 CONVERSION` law generalised. Applied: launch stacks/weapons
  (`launch_panel.gd:132-134,144`), exchange units/stacks
  (`exchange_panel.gd:628,738-749`), refinery tag/ingots
  (`refinery_panel.gd:69,91-92,541-544,645-651,675-680`), auction subtitle
  (`auction_panel.gd:137,603`). Shipyard `%d ENGINES` rides S29.
- **A6** "IT NEVER SELLS IN V1" → "THE STATION BUYS · IT DOES NOT SELL"
  (`exchange_panel.tscn`); `BRIEF_NOTE` → "CARGO AS THE HOLD FILES IT · BUY AND
  SELL AT THE EXCHANGE" (`launch_panel.gd:144`); "REFINERY ALL" → "REFINE ALL"
  (`refinery_panel.tscn`). "SHIP VIEWER ONLY" is the shipyard's `SIDE VIEWS
  ONLY` subtitle (untouchable); `MINE BACK` was a 640 read of the catalogue's
  "Mine Rack" - no typo ships.
- **A7** `game.gd:392` mounts DevTuningMenu only under `OS.is_debug_build()`.
  Pin: `test_s13_devmenu.gd:337`.
- **A8** credits value reserves a font-measured nine-digit width, right-aligned
  (`station.gd:282-291`, `station.tscn` CreditsValue) - no corner reflow.
- **A9** inspector pin floors (`station.gd:313` `_lines_height`), LAUNCH hull
  plate floors (`launch_panel.gd:802`). Console/AmmoScroll/HullImage(shipyard)
  fractionals live in the S29 bodies - deferred, disclosed.
- **A10** SELL ALL RAW disables unless a raw stack lists
  (`exchange_panel.gd:507` `_has_raw`, wired at `_refresh_trade`). Pin:
  `test_s5_ammo_cargo.gd:558`.
- **A11** stepper arms at 1 on selection (`exchange_panel.gd::_select`, was the
  05 §6 whole-stack default - owner reversal ships) and the primary carries it
  ("SELL 1 UNIT", `exchange_panel.gd:633`). Pin in the same row.
- **A12** holdings header band HELD / CR EACH / VALUE mirroring the row grid
  (`exchange_panel.gd:287`, consts at `105`). Judgement: no per-item cap column
  exists (the quota pair rides the board, captioned QUOTA), so "CAP" ships as
  CR EACH - one-word reversal if the owner meant otherwise.
- **A13** shelf tag = live `n OF 20 ON SHELF · NEXT RESTOCK m:ss`
  (`auction_panel.gd:143,590-602`; capacity `MODULE_SLOTS+STOCK_SLOTS`, both
  halves reads - the no-write boot rule holds); the F-lot note stays on the
  tagged row. Pin: `test_s3_auction.gd:888`.
- **A14** quit body → state-neutral "Progress is saved." (`quit_confirm.tscn`);
  the dialog is only ever opened from the top-level menu (`main_menu.gd:156,208`).
- **A15** boot fill one step up the ash ramp, `metal_light` → `text_dim`
  (`boot.gd:55`), no new hue. The "(13 px StationCaption)" parenthetical matches
  no boot node - the splash line is MAIN_MENU_V2 §17.1's 2 px bar; it took the
  brightening. MAIN_MENU_V2's `metal_light` row now stale (docs not mine).
- **A16** all survivor action buttons on the 360×56 Pressables plate (SELL/
  SELL ALL RAW/CANCEL, REFINE/REFINE ALL/CANCEL, LAUNCH/REFUEL/RECHARGE - the
  88 px primaries retire); clusters are P2 rows: `ActionsRow` HBox, 16 px
  gutter, primary rightmost, panel foot above the footer band
  (`exchange_panel.tscn`, `refinery_panel.tscn`, `launch_panel.tscn` +
  `_build_service_rows` inserting at 1/2). BOUNTY keeps DECK CONTROL's column
  (a fourth 360 plate overflows the pane; not a §8-named action). AUCTION ships
  no action buttons (rows are the data-row idiom; BUY/SELL are cells) and the
  96×32 chip has no survivor host (ammo BUY is armory) - nothing moved. Rail
  272×56 stays (§8's exclusion); leave-confirm stays §5 dialog chrome; stepper
  ± stay (spinners, absent from §8's six measured sizes). P3: settings' sliders
  were the only family drawing a fallback ring - they take the §6 1 px
  `accent_danger_bright` box in code (`settings.gd:448-473`, no .tres drift);
  everything else already drew the one ring; menus keep the tick bar (§8's own
  clause). Pins: `test_s5_ammo_cargo.gd:558`, `test_p2b_services.gd:686`.

## Moved test rows
- `test_p2b_services.gd:634,648,660,675` — strip assertions → status capture +
  strip-keeps-arm-copy (A3); `:686-701` — cluster row / 360×56 / rightmost (A16).
- `test_s8_launch_ammo.gd:177-188,316-322` — AMMO_FORMAT expectations through
  `Catalog.plural` (A5).
- `test_s11_inspector.gd:299` — re-anchors to module 0 first (shared mount).
- Expected but NOT moved: `test_p1_repairs.gd:128,139`, `test_s5_ammo_cargo.gd:509`
  pin the reason-token / `sell_all` APIs, which the brief keeps.

## Evidence
```
XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=1038 failed=0   # run 1 (/tmp/s28_final1.log); run 2 (/tmp/s28_final2.log) identical, zero FAIL lines
```

## Files touched
`ui/screens/station.gd|tscn`, `settings.gd`, `settings_rebind_row.gd`,
`boot.gd`, `quit_confirm.tscn`, `ui/station/{exchange,refinery,launch}_panel.gd|tscn`,
`auction_panel.gd`, `game/game.gd`, `game/station_catalog.gd`; tests: s11, p2b,
s8_launch_ammo, s13, s3, g1, s5_ammo_cargo.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| MAIN_MENU_V2 §17.1 fill / MENU_FLOW §5 hangar body stale | doc amendment | A14/A15 |
| STATION_HUB §5.4 "pane's own status line" now shell-strip-only | doc amendment | A3 |
| Armory/shipyard fractionals, `%d ENGINES`, ammo BUY chip | rides S29 | A5/A9/A16 |
| A12 header word if a cap column was meant | owner tick | exchange header |
