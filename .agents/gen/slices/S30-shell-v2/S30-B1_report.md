---
slice: S30
worker: S30-B1
model: hyper/deepseek-v4.1-flash
status: actionable
gate: "1074/0 → 1079/0"
---

# S30-B1 report

## Result
The station's popup layer ships: N27's hover tooltip and N28's INSPECT sheet are real
scenes, wired to the existing `inspect_requested` chain (P21) with the band retired as a
sink. The UI_SPEC §12.5 census is cured row by row; the six rail panes carry the one
skeleton (PaneHeader / content split / §8 P2 cluster / shared foot hint); the R-S30-2
`map_filters` door is live. Gate **1074/0 → 1079/0**, twice on fresh `XDG_DATA_HOME`
stores.

## Acceptance list answers
- **A1 — DONE.** N27 `ui/components/tooltip.{gd,tscn}` (`PanelContainer` + BBCode
  `RichTextLabel`, 320 px cap `:21`, 0.25 s delay `:23`, cursor +12/12 `:22`, flip-then-
  clamp `_place` `:105-118`, `MOUSE_FILTER_IGNORE` `:39`, hint line `INSPECT` `:24,:96`).
  N28 `ui/components/inspect_sheet.{gd,tscn}` (§5.2 tree, min 420 / max 720 `:24-25`,
  80 %-viewport scroll `:151-158`, the six rows `:120-140`, N35 formats `:44-47`, ESC via
  `close()` `:76`). Shell wiring `ui/screens/station.gd`: `_build_popups` `:290`,
  hover sink `_on_panel_inspect` `:652`, `_show_hover_tooltip` `:315`, `_on_panel_sheet`/
  `open_sheet` `:339-353`, `_inspect_focused` (N34 `E` / pad X) `:263,277,357`, ESC step
  `_handle_cancel` `:806`. Chips: `ui/components/inspect_chip.gd`; one per row in SHIPYARD
  `shipyard_panel.gd:384`, FITTING `fitting_panel.gd:861,934`, ARMORY browser rows
  `armory_panel.gd:3824`, REFINERY `refinery_panel.gd:341`, EXCHANGE `exchange_panel.gd:553`,
  AUCTION `auction_panel.gd:705,760,809`. Cluster chips (N37): ARMORY's P2 cluster
  `armory_panel.gd:2932,2936` (dimmed until a cell is selected), SHIPYARD under the grid
  `shipyard_panel.gd:757-766` (dimmed until a filled cell is hovered).
- **A2 — DONE, row by row** (cites are the census rows): 1 DELETE→TOOLTIP
  `shipyard_panel.gd:703-739` (block nodes deleted, `_hover_block_text` + `_tooltip_body`);
  2 the fitting twin `fitting_panel.gd:1469-1491` (node deleted, `_stat_block_text`);
  3 RESERVED SLOT `shipyard_panel.gd:735-739` (`PREVIEW_BOX` 240×180, `_update_preview_size`
  deleted); 4 RESERVED SLOT — the foot band's h3 hint cell cannot reflow (the band's width
  is the pane's, not the label's); 5 RETROFIT `menu_button.gd:54,160-185` (`_glow.modulate.a`);
  6 DELETE→TOOLTIP — the sink is retargeted; the band *nodes* stay for B2 (seam law, §4
  rule 2); 7 DELETE→TOOLTIP — every listed `status_requested.emit(_row_hint…)` and
  `tooltip_text` write is gone (`shipyard_panel.gd:862,1110`, `refinery_panel.gd:558-565`,
  `repairs_panel.gd:288`, `exchange_panel.gd:802`, `auction_panel.gd:1053`,
  `armory_panel.gd:1695,1968,2029,3139,3645`), each routed to the chain instead;
  8–15 ALREADY LEGAL — untouched; 16 RETROFIT `armory_panel.gd:3122-3140` (`_sync_grid`
  leaves `_refresh_footer`; it rides `_refresh_all`/`refresh_profile`), `fitting_panel.gd`
  and `shipyard_panel.gd`'s rebuilds are command-only.
- **A3 — DONE for the six rail panes + FITTING.** `PaneHeader` min (0,40) and a
  `PaneFoot` HBox min (0,56) holding the shared hint (h3, bottom-aligned) + the §8 P2
  cluster (h0, rightmost): `shipyard_panel.tscn:11,160-175`, `refinery_panel.tscn:11,187-205`,
  `exchange_panel.tscn:11,158-176`, `launch_panel.tscn:11,143-155`, `fitting_panel.tscn:11`,
  `auction_panel.tscn:11,147` (its cluster is empty by pin §19.4), `armory_panel.tscn:17`.
- **A4 — DONE for every censused site.** The reviewer's probe is a gate row:
  `tests/test_s11_inspector.gd::test_a_hover_never_moves_a_pane` compares the pane's full
  descendant geometry before/during/after a hover.
- **A5 — DONE.** `test_s11_inspector.gd` retargeted to the popup sinks (8 new rows:
  tooltip show/clear/delay, sheet open/rows/ESC/queue, `station_inspect`, hover-never-moves);
  `test_s20_chrome_unify.gd:482`, `test_s29_station_panels.gd:239,324`,
  `test_p2b_services.gd:477,537,577`, `test_p2b1_outfitting_panel.gd:714`,
  `test_p2b_fitting_panel.gd:1081,1417`, `test_s5_ammo_cargo.gd:594` retargeted to the
  chain / the moved cluster path.
- **A6 — DONE.** Two fresh-store runs, both `[SUMMARY] passed=1079 failed=0`.

## Deviations from SLICE.md (bucket-1 judgements, each with its reversal)
1. **The band nodes stay** (`station.tscn:215-243`). The seam law (§4 rule 2) gives the
   band's *deletion* to B2; B1 retargets the sink only, so the census row 6 cure is the
   sink, not the node. Reversal: delete them here.
2. **The INSPECT chip is focusable**, so it joins each pane's focus walk (fitting's two
   order rows moved: `test_p2b_fitting_panel.gd:1417,1081`). N28's trigger list needs
   "`ui_accept` on the focused chip", so the chip cannot be `FOCUS_NONE`. Reversal:
   `FOCUS_NONE` + pointer/`station_inspect` only.
3. **ARMORY's hand-positioned rows carry no inline chip** (the ammo cards and the
   inventory rows are laid out by `_position_card` / `_position_inventory_item`, not a
   container). They are inspected through `station_inspect` on the focused row and the
   cluster chip; their container-built browser rows do carry one (`armory_panel.gd:3720`).
   Reversal: add positioned chips with A5.2(i)'s deferred positioning pass.
4. **ARMORY keeps `ActionsRow` as a direct child** (no `PaneFoot` wrap): two suites read
   the cluster's path (`test_s5_ammo_cargo.gd:594`) and T5 retires the armory's footer
   caption (`test_s18_armory_rework.gd:424`), so its foot band rides the A5.2(i) pass.
   Reversal: wrap it and retarget both rows.
5. **LAUNCH and EXCHANGE's board rows carry no chip** — LAUNCH's rows are routes/services
   with no catalogue item (its own `inspect_requested` doc says it emits nothing), and
   EXCHANGE's board rows are display-only (`FOCUS_NONE` + `MOUSE_FILTER_IGNORE`).
   Reversal: add chips once those rows become items.
6. **`PREVIEW_BOX` = 240×180** is PROPOSED (no doc derives it): 08 §3's side-view envelope
   at the shipped 0.70 preview scale. Reversal: the deleted per-selection write.
7. **The armory's §19.4 foot hint** is its shipped `MeterLabel` line; T5's retired footer
   caption stands. Reversal: a `PaneFooter` label + retarget the two T5 rows.
8. **`R-S30-2` implemented**: `player_profile.gd:1885-1906` (`map_filters` /
   `set_map_filters`) + `ui/hud/map_deck.gd:513-541` read/write it. `R-S30-1` (the 272 px
   drawer box) is **B2's** (the drawer is B2's build); not touched here.

## Evidence
- `XDG_DATA_HOME=/tmp/s30b1-f1 godot --headless --path $VAJB_PROJ
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=1079 failed=0`
- the same on `/tmp/s30b1-f2` → `[SUMMARY] passed=1079 failed=0`
- `--suite=test_s29_map_deck` → `passed=16 failed=0` (R-S30-2 keeps the deck's persistence)
- `--check-only` on all twelve touched scripts → no parse errors
## Files touched
- `ui/components/tooltip.gd` / `.tscn` — new N27 tooltip
- `ui/components/inspect_sheet.gd` / `.tscn` — new N28 sheet
- `ui/components/inspect_chip.gd` — new N37 chip
- `ui/components/menu_button.gd` — census row 5 retrofit (glow alpha)
- `ui/screens/station.gd` — the popup layer, the sinks, `station_inspect`, ESC step
- `ui/station/shipyard_panel.gd` / `.tscn` — census 1/3/7/16, chips, cluster chip, skeleton
- `ui/station/fitting_panel.gd` / `.tscn` — census 2/7, chips, skeleton header
- `ui/station/armory_panel.gd` / `.tscn` — census 7/16, browser chip, cluster chip, header
- `ui/station/refinery_panel.gd` / `exchange_panel.gd` / `auction_panel.gd` (+ `.tscn`) — census 7, chips, skeleton
- `ui/station/launch_panel.gd` / `.tscn` — skeleton (cluster re-seat), foot hint
- `autoload/player_profile.gd` — R-S30-2's `map_filters` door
- `ui/hud/map_deck.gd` — reads/writes the door
- `tests/test_s11_inspector.gd` + 7 retargeted suites (see A5)

## Follow-ups| Item | Kind | Where |
|---|---|---|
| ARMORY ammo-card / inventory-row inline chips + its `PaneFoot` band | deferred (A5.2(i) positioning pass) | `armory_panel.gd` `_position_card` / `_position_inventory_item` |
| `R-S30-1`'s 272 px drawer content box | B2 | `ui/screens/station.tscn` drawer |
| a pre-existing defect: `test_s5_batteries_v2.gd:336` looks for `PaneTitle` at the pane root and errors instead of asserting | test bug (not mine) | `test_s5_batteries_v2.gd:336` |
