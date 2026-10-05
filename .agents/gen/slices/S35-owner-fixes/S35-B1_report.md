---
slice: S35
worker: S35-B1
model: hyper/deepseek-v4.1-flash @ xhigh
status: actionable
gate: "1132/0 → 1136/0"
---

# S35-B1 report — the owner's fix round: one sell selector, preview clear, one shared menu

## Result
The EXCHANGE trade column carries ONE quantity control (the `SELL UNITS` stepper, min 0,
with `MAX`/`0` chips; the S33 duplicate selector is gone); an empty-chrome press in the
ARMORY clears the selection + preview; and both modes' right sector render ONE shared menu
subtree (reparented on the mode switch). Gate `1132/0 → 1136/0`, twice on fresh scratch.

## Acceptance list answers
1 — `_set_sell_units` clamps 0..row units (`exchange_panel.gd:736-741`); `MAX` fills,
   `0` empties (`:753-763`); `SELL` disabled at 0 (`:690`); probe both — `test_n49_the_max_and_zero_quick_buttons` (`test_s5_ammo_cargo.gd:806`).
2 — a SELL press moves exactly `_sell_units` (`:781-788`); disabled at 0/no selection
   (`:690`); no second selector — grep + scene probe, `test_n49_no_second_units_selector` (`test_s5_ammo_cargo.gd:835`).
3 — empty-chrome press clears the cell + hover preview, CELL INFO → select prompt, hint
   idle — `_clear_away` (`armory_panel.gd:1137`), `_unhandled_input` (`:1110`); probe `test_p38a_click_away_clears_the_selection_and_preview` (`test_s32_armory_modes.gd:574`).
4 — ONE menu subtree (`%MenuSector`) reparented FitRight↔EqSector on the mode switch
   (`armory_panel.gd:992-998`); one builder `_build_browser` (`:3783`), the EQ builders gone;
   identical `MENU_TABS` both modes — `test_p39a_one_shared_menu_in_both_modes` (`test_s32_armory_modes.gd:551`).
5 — FIT CELLS fit/drag/BUY intact (`test_a_owned_row_fits_by_press_and_by_drag`,
   `test_buy_on_a_buyable_row_buys_then_fits`); BATTERY drag persists through
   `set_battery_groups` (`test_a_rack_drag_persists_through_the_battery_record`).
6 — gate green ×2 (`passed=1136 failed=0`); every moved row disclosed below.

## Deviations from SLICE.md
- **`MENU_TABS` = the union** (AMMUNITION + the 8 families + ALL, 10 tabs; measured 569 px
  min ≤ the 688 px sector). `POWER` keeps the browser's label, so the EQ's `PWR/FUEL RODS`
  retires. Why: P39a "identical categories". Reversal: the browser 9-tab set, `PWR/FUEL RODS`.
- **Landing category is `ALL`** (the browser's), not AMMUNITION. Why: one set, one landing.
  Reversal: `_browser_tab = EQ_TAB_AMMO`.
- **The trade column's `TradeBox` grows 360 → 393 px** (measured) to seat the stepper plus the
  two pinned 96 px `ActionInline` chips; the `SellValue` reads 57 px, no clip. Reversal:
  shrink the chips / drop the stepper's expand-fill.
- **The menu is reparented on a mode switch** (a command, never a hover/focus/selection
  state — A5.5/N24 untouched). Reversal: two hand-built lookalikes (what P39a forbids).
- **BATTERY CONFIG's owned weapon rows drag as `DRAG_INVENTORY`** (the rack's drop route);
  a row press there inspects only (no cell to fit). Reversal: a flat `DRAG_BROWSER` payload.
- **AMMUNITION shows the shipped pack cards in both modes** (the EQ's own BUY route).

## Evidence
- Gate (before): `[SUMMARY] passed=1132 failed=0`.
- Gate (after, `XDG_DATA_HOME=$(mktemp -d)`, fresh scratch ×2): `[SUMMARY] passed=1136 failed=0`
  twice, zero `SCRIPT ERROR`. Re-run: `~/.local/bin/godot --headless --path vajb-orbit
  res://tests/headless_runner.tscn --quit-after 1200`.
- Probe (mode switch): `menu parent=FitRight` → after `set_mode(battery)` `parent=EqSector`,
  `eq_ancestor=true`, `mode=battery`.
- Probe (trade column): `trade_min=393.0 row_min=393.0 value_min=57.0 row_size=(393,48)`.

## Files touched
- `vajb-orbit/ui/station/exchange_panel.gd` — `SELL UNITS` min 0, MAX/0 chips, SELL disabled at 0; the `_step` selector retired.
- `vajb-orbit/ui/station/exchange_panel.tscn` — `StepperRow` deleted; `SellMaxButton`/`SellZeroButton` added.
- `vajb-orbit/ui/station/armory_panel.gd` — one shared menu (`MENU_TABS`, `_build_browser`, reparent); EQ builders retired; `_clear_away` empty-chrome routing.
- `vajb-orbit/ui/station/armory_panel.tscn` — `%MenuSector` wrapper; `EqSector` emptied.
- `vajb-orbit/tests/test_s5_ammo_cargo.gd` — N49 rows restated + 2 added (MAX/0, no-second-selector).
- `vajb-orbit/tests/test_s32_armory_modes.gd` — shared-menu rows + P39a/P38a added.
- `vajb-orbit/tests/test_d7_armory.gd`, `test_s29_station_panels.gd`, `test_p2b1_outfitting_panel.gd`, `test_s18_armory_rework.gd`, `test_s20_chrome_unify.gd`, `test_s11_inspector.gd` — node/tab re-anchors.
- `vajb-orbit/tests/probe_s20_review.gd`, `probe_s18r1_audit.gd` — node/tab re-anchors.

## Moved test rows (old → new → why)
- `test_s5_ammo_cargo` `test_the_sale_column_ships_the_s28_chrome_law`: `_step_value`
  `0/1 UNIT` + `_step == 1` → `_sell_value` + `_sell_units == 1`. Why: the duplicate selector died.
- `test_s5_ammo_cargo` `test_n49_the_sell_units_selector_bounds_and_the_stack_order`: floor
  `1` → `0`; the `_step_minus`-parent anchor → `_sell_units_row`; `StepperRow` absent. Why: N49-amended.
- `test_s32` `test_battery_config_is_two_equal_sectors`: `%ArmoryRows`→`%BrowserRows`,
  `%EqTabs`→`%FamilyTabs`. Why: P39a.
- `test_s32` `test_the_eq_container_lists_the_non_weapon_categories_with_counts` →
  `test_the_shared_menu_lists_ammunition_and_the_equipment_categories`: `%EqTabs`→`%FamilyTabs`,
  `%ArmoryRows`→`%BrowserRows`, `PWR/FUEL RODS`→`POWER`, `active_eq_tab`/`select_eq_tab`→
  `active_tab`/`select_tab`, landing AMMUNITION→ALL, `Count` `×n`→`Read` `OWNED ×n`,
  `%AmmoCaption`→`%BrowserCaption`. Why: P39a.
- `test_s32` `test_every_row_control_lands_inside_the_window`: `%ArmoryRows`/`%AmmoScroll`→
  `%BrowserRows`/`%BrowserScroll`. Why: P39a.
- `test_s32` `test_every_list_wears_its_band_and_the_160_px_trim`: `%EqBand`/`%ArmoryRows`/
  `EQ_BAND_*` → the shared band/rows. Why: P39a.
- `test_d7` `test_the_two_console_wells_hold_the_empty_and_summary_blocks`: `%AmmoCaption`
  caption + `%BrowserRows` parent `FitRight` + `%AmmoMargin` parent `EqSector` → `%BrowserCaption`
  + `%MenuSector` parent `FitRight`→`EqSector`. Why: P39a.
- `test_d7` `test_the_items_ride_the_code_drawn_plate` (+ `_ammo_card`): `%ArmoryRows`→
  `%BrowserRows`, EQ wording → shared menu; the browse half selects `ALL` first. Why: P39a.
- `test_s29` `test_the_browser_caption_and_the_tab_strip_minus_hulls`: 9 labels → 10
  (AMMUNITION leads). Why: P39a.
- `test_p2b1` `_ammo_rows`, `test_s18` P5 row, `test_s20` `_card`, `test_s11` `_ammo_payload`:
  `%ArmoryRows`→`%BrowserRows` + select the AMMUNITION tab. Why: P39a.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `probe_s32_review` / `probe_s33_review` still read the retired `%FootBand`/`%InventoryRows`/`%EqTabs` (already stale from S33); not gate-run | hygiene | `tests/probe_s32_review.gd`, `probe_s33_review.gd` |
| The `MENU_TABS` label `POWER` supersedes the EQ's `PWR/FUEL RODS`; owner's taste call | taste | `armory_panel.gd:MENU_TABS` |
