---
slice: S33
worker: S33-B1
model: hyper/deepseek-v4.1-flash @ xhigh
status: actionable
gate: "1110/0 → 1118/0"
---

# S33-B1 report — shell v3: ARMORY two sectors + the exchange sell cluster

## Result
Both ARMORY modes now split into two equal sectors (probe: 688/688 at the
pinned 1392×610 host) — FIT CELLS left = grid + CELL INFO, right = ONE list in
two states; BATTERY CONFIG left = the racks, right = the EQ container. The
exchange commit button reads `SELL` in every state with a `SELL UNITS` selector
beneath it. Gate `1110/0 → 1118/0`, twice on fresh scratch.

## Acceptance list answers
1 — two equal sectors, measured 688/688 (`%FitLeft`/`%FitRight`); grid +
   CELL INFO are `FitLeft`'s children — `armory_panel.tscn:97-190`;
   `test_s32_armory_modes.gd:test_fit_cells_is_two_equal_sectors`.
2 — browse = owned rows tagged `FIT` (fitted on the hull) / `STORED` (bag only),
   no cell fit; selected = `OWNED`-that-fits first then `BUYABLE`-that-fits, each
   with its legality line and BUY + INSPECT — `armory_panel.gd:_equip_rows`,
   `:3852-3924`; `test_…:test_the_list_browses…`, `:test_the_selected_list…`.
3 — two equal sectors (688/688, `%BatterySectors`); racks full-height less P34's
   92 px wells band (`%RackRows` 688×459), drag persists through
   `set_battery_groups` (profile probe); EQ container tabs + count rows +
   INSPECT — `armory_panel.gd:_build_eq`, `:3900-4090`;
   `test_…:test_battery_config_is_two_equal_sectors`, `:test_the_eq_container…`.
4 — no `FITS HERE` / `BUYABLE THAT FITS` wide block and no P36 foot band:
   scene grep + `%FootBand`/`%InventoryRows`/`%InventoryCaption` all null —
   `test_…:test_no_fits_here_or_buyable_wide_block_and_no_foot_band`.
5 — N48: `_sell.text = SELL_WORD` unconditionally (`exchange_panel.gd:687-690`);
   the strip keeps `CONFIRM_FORMAT`'s count —
   `test_s5_ammo_cargo.gd:test_n48_the_commit_button_reads_sell_in_every_state`.
6 — N49: `StepperRow → SellUnitsRow → InspectCluster → PaneFoot` (child order);
   bounds 1..row units, disabled + `text_dim` without a selection; a SELL press
   moves exactly `_sell_units` — `test_s5_ammo_cargo.gd:test_n49_…` (both rows).
7 — both lists wear a band (`%BrowserBand`/`%EqBand`) and the 160 px trim; every
   row control inside the 1920×1080 viewport (scroll-viewport containment);
   gate green ×2 — `test_…:test_every_list_wears_its_band…`,
   `:test_every_row_control_lands_inside_the_window`.

## Deviations from SLICE.md
- **`FIT`/`STORED` reading.** P38's browse tags are read as *fitted on the active
  hull* (`FIT`) vs *owned, not fitted* (`STORED`): the Vanguard carries every
  family, so a family-usability reading would make `STORED` unreachable. Why: a
  live, meaningful tag. Reversal: `FIT` = the hull has a cell of the module's
  family (`armory_panel.gd:_fitted_bases` → a family set).
- **The exchange's unit-number selector is display-only.** The pin names it
  "buy quantity, as shipped" and gives the sale to the new `SELL UNITS` selector;
  this surface has no buy, so `_step`/`_step_value` now carries no sale. Why: the
  pin's exact stack. Reversal: fold both onto one stepper (the pre-S33 shape).
- **Sector gutter 16 px.** A5 tokens name no gutter; §19.3's `PaneBox` uses 12,
  the sibling EXCHANGE body 16 — 16 chosen for parity with the panes beside it.
  Reversal: `armory_panel.gd:SECTOR_GUTTER := 12`.
- **BATTERY CONFIG's left sector keeps P34's wells band** (empty cells +
  summary) at its foot, so the rack band is full-height less that 92 px band.
  Why: P41 keeps §20's P34. Reversal: drop the wells band, racks fill 557.
- **The legality line reads the OK wording on every listed row.** The list is
  pre-filtered to fitting rows (the pin's "owned-that-fits / buyable-that-fits"),
  so `_row_legality` resolves to `LEGAL · THIS CELL FITS`; the refusal strings
  are wired for the rows the filter drops. Reversal: list near-miss rows with
  their refusal as the proactive hint.
- **EQ node names.** The EQ AMMUNITION list keeps `%AmmoMargin` / `%AmmoCaption` /
  `%ArmoryRows` so the shipped pack-card suites keep reading the same nodes.

## Evidence
- Gate (before): `[SUMMARY] passed=1110 failed=0`.
- Gate (after, fresh scratch ×2): `[SUMMARY] passed=1118 failed=0` twice; zero
  `SCRIPT ERROR` lines. Re-run: `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot
  --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`.
- Probe at the 1392×610 host: `modehost=(1392,557)`, `left=(688,493)`,
  `right=(688,493)`, `block_size=(688,557)`, `battery_sectors=(1392,557)`,
  `racksector=(688,557)`, `eqsector=(688,557)`, `bay_rects[0]=(0,53) 688×87`,
  `wells=[(0,518) 328×92, (360,518) 328×92]`, `armory_rows_children=8`.

## Files touched
- `vajb-orbit/ui/station/armory_panel.tscn` — two-sector tree per mode, EQ
  container, `FitFoot`; FITS HERE / BUYABLE blocks and `FootBand` deleted.
- `vajb-orbit/ui/station/armory_panel.gd` — one two-state list, EQ container,
  bands, per-selection hint, sector-sized console; FITS HERE code retired.
- `vajb-orbit/ui/station/exchange_panel.tscn` — `SellUnitsCaption` + `SellUnitsRow`.
- `vajb-orbit/ui/station/exchange_panel.gd` — N48 wording, N49 selector + bounds.
- `vajb-orbit/tests/test_s32_armory_modes.gd` — rewritten to P38–P41.
- `vajb-orbit/tests/test_s5_ammo_cargo.gd` — SELL row restated, 3 N48/N49 rows.
- `vajb-orbit/tests/test_d7_armory.gd` — geometry constants + 4 rows re-anchored.
- `vajb-orbit/tests/test_s15_armory_layout.gd` — constants + 2 rows.
- `vajb-orbit/tests/test_s18_armory_rework.gd` — 1 row (`block_size` → sector).
- `vajb-orbit/tests/test_s10_armory_input.gd` — 1 row (chip size 45×67).
- `vajb-orbit/tests/test_s29_station_panels.gd` — 3 rows (caption, N45 block, hyperdrive).
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — 2 rows (browse list + caption).

## Moved test rows (old → new → why)
- `test_d7`: `MODE_HOST (1392,447)` → `RACK_SECTOR (688,557)`; `RACK_ROW
  (1392,65)` → `(688,87)`; `CELL (221,45)` → `(45,67)`; `LEDGE_ORIGIN x 1122` →
  418; drum top `16.5` → `27.5`; `WELL (680,92)` → `(328,92)` at y 408 → 518;
  card children `(328,0)/(656,0)` → stacked `(0,74)/(0,148)`; `%InventoryCaption`
  → `%BrowserCaption`; `%AmmoMargin` parent `FootBand` → `EqSector`; row-width row
  → sector width. Why: the console rides a half-width sector now.
- `test_s15`: `block_size`/plate `MODE_HOST` → `RACK_SECTOR`; `bays_band` arg
  `MODE_HOST` → `RACK_SECTOR`; drum top 16.5 → 27.5. Same why.
- `test_s18`: `console.x == host.x` → `(host.x − 16)/2`; base `(1392,447)` →
  `(688,557)`. Same why.
- `test_s10`: chip `(221,45)` → `(45,67)`. Same why.
- `test_s29`: caption `MODULES · OWNED & BUYABLE` → `LIST_CAPTION_BROWSE % 0`;
  `ModeHost/FitCells/BuyableBlock` → `…/FitSectors/FitRight`; hyperdrive row now
  selects an engine cell (buyables only appear with a cell). Why: P38.
- `test_p2b1`: `%InventoryRows`/`%InventoryCaption` → `%BrowserRows` /
  `%BrowserCaption`; scene grep `BUYABLE` → `BrowserCaption`. Why: P38.
- `test_s5_ammo_cargo`: `SELL 1 UNIT` → `SELL` (+ `_sell_value` `1 UNIT`). Why: N48.
- **Not moved (verified still green):** `test_s5_batteries_v2`, `test_s11_inspector`,
  `test_s20_chrome_unify`, `test_s30_shell` — they read node paths/ids, not rects.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The exchange unit-number selector carries no action (display-only); confirm with the owner whether it should fold into `SELL UNITS` | taste | `exchange_panel.gd:_step` |
| The `FIT`/`STORED` reading (fitted vs hull-usable) is a judgment; T-132's sibling | taste | `armory_panel.gd:_fitted_bases` |
