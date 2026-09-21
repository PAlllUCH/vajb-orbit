# P1i report — EXCHANGE station panel (STATION_HUB §5.8, doc 05)

Deliverables, exactly two new files, nothing else touched:

1. `vajb-orbit/ui/station/exchange_panel.tscn` (183 lines) — root `VBoxContainer`
   `Exchange` (sep 12, no theme baked): `PaneHeader` (icon, `EXCHANGE`,
   `MINERALS AND SURPLUS`, tag `TWO BOOKS · 20 MINERALS · 18 COMPONENTS`),
   `ExchangeBody` = `HoldBox` (`HoldScroll` → `HoldRows`) | `MarketBoard`
   (`BoardScroll` → `BoardRows`) | `TradeBox`, `PaneFooter`
   `THE STATION BUYS · IT NEVER SELLS IN V1`. Unique names per §5.8.
2. `vajb-orbit/ui/station/exchange_panel.gd` (974 lines) — rows, board, quote strip,
   three actions, panel contract (`status_requested`, `refresh_profile`,
   `focus_primary`, `disarm`).

No `.uid` sidecars were produced (the editor generates them on first import; the sibling
panels of this wave are in the same state). Probe files, their scene, the two scratch
diagnostics and `user://p1i_probe_*` are deleted.

## Commands and observed output

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1i.tscn --quit-after 300
```
EXIT=0; 99 `[P1i] PASS`; 0 `FAIL`; 0 `SCRIPT ERROR`; `[P1i] all 99 checks passed` +
`PROBE OK`. Clock pinned via `WorldClock.set_override(1789000000)` so no band re-rolls
mid-run.

```
...exe --headless --path <proj> res://ui/screens/station.tscn --quit-after 300
```
EXIT=0, no SCRIPT ERROR, only the two exit-time messages
`WARNING: 4 ObjectDB instances were leaked` / `ERROR: 2 resources still in use`. Those
are pre-existing shell/audio-bus facts: the same figures appear with the panel absent,
and the panel instantiated alone exits clean.

```
...exe --headless --path <proj> res://tests/headless_runner.tscn
```
`[SUMMARY] passed=25 failed=3`; the 3 are parse errors **inside**
`tests/test_p1_market.gd`, `tests/test_p1_profile.gd`, `tests/test_p1_repairs.gd`
(`Cannot infer the type of "profile" variable`) — files I did not write, unrelated to
this panel, left alone per the brief.

## Probe assertions (99, all PASS)

Setup/step 1: autoload reachable; `save_path` → `user://p1i_probe_profile.cfg` and
`EconomyLog.log_path` → `user://p1i_probe_log.txt`, both before any mutation; seed =
iron ore 10, gold ingot 3, scrap 50. Step 2: panel instantiated by the shell, rail entry
`ExchangeEntry` exists, pressing it makes `Exchange` the visible module.
Step 3: **3 hold rows**; **38 board rows**; board in catalogue order (`BoardIngotIron` …
`BoardCompOre3`, 20 minerals then 18 components); hold order
`mineral_iron, ingot_gold, comp_scrap_1`; first board row `IRON` / meta `INGOT` /
demand `1.0x` / trend `STEADY`; first component `TORN PLATING` / `SURPLUS` /
`40 / 40` / `SALVAGE` / grade `I`; hold icons are the derived tint stencil
(`…/tint/icon_cargo_container_48.png`) moderated with `TIER_TINTS[3]` at alpha 0.72,
board components with `GRADE_TINTS[1]`. Price truth: gold `UNIT` `387` ==
`Exchange.exchange_price(&"ingot_gold", demand)`; `TOTAL` `1 161` == `quote.paid`;
confirm strip `SELL 3 INGOT_GOLD — GROSS 1 185 · FEE 24 · YOU GET 1 161` == the same
`Exchange.quote` byte for byte; stepper defaults to the whole stack (`3 UNITS`).
Step 4: sale paid `+1161` (== quote); stack gone; `hold rows 2`; strip
`SOLD · 3 INGOT_GOLD · +1 161 CR`; gold demand cooled exactly `0.03`.
Step 5: iron stepper `10 UNITS`; sale paid `+170` (== quote); stack gone; strip
`SOLD · 10 MINERAL_IRON · +170 CR`; iron demand `1.00 → 0.90` (**−0.10**); board re-read
price `57` and demand `0.9x` from the cooled state.
Step 6: the 50-unit surplus quote splits `sellable=40 / queued=10`; stepper `50 UNITS`;
credits grew `+430` (the 40-unit quote only); strip `STOCK FULL · 10 UNITS QUEUED`;
stack gone; market `stock=0 queue=10`; board reads `0 / 40`.
Step 7: refilled hold (copper ore 4, scrap_2 2, copper ingot 5) = 3 rows; `SELL ALL RAW`
paid `+122` (== both single quotes); ore and component sold; **ingot stayed at 5**; strip
`SOLD ALL RAW · 2 STACKS · +122 CR`; one row left.
Step 8: stepper `5 → +4 stays 5` (clamps at held) `→ −8 stays 1` (clamps at 1) and the
strip requotes `SELL 1 INGOT_COPPER …`; `CANCEL` clears selection + stepper and disables
SELL; `disarm()` true then false; `focus_primary()` lands on the first hold row; a
`&"credits"` refresh leaves the armed sale untouched (`5 UNITS`, same strip); an external
`add_cargo`/`remove_cargo` rebuilds the hold rows without the panel being told; a
**partial sale** of 2 of 5 pays the 2-unit quote `+144`, leaves 3 in the hold, strip
`SOLD · 2 INGOT_COPPER · +144 CR`; the last stack sells to 0; the empty hold draws the
`HOLD EMPTY` caption row, title `HOLD EMPTY`, SELL / SELL ALL RAW / CANCEL disabled;
pressing SELL and SELL ALL RAW anyway refuses `REFUSED · HOLD EMPTY` (danger).
Step 9: a second boot with an empty hold draws `HOLD EMPTY`, an inert trade column, all
38 board rows, no SCRIPT ERROR.

## Measured geometry evidence (headless 1920×1080, EXCHANGE visible)

| Box | Measured |
|---|---|
| station / `HostMargin` / pane box | 1920×1080 / 1480×879 / 1440×839 |
| `ExchangeBody` | 1440×749 (combined minimum 1016×436) |
| hold / market / trade (and their scrolls) | **500** / **548** / **360**, scrolls 500×718 / 548×718 |
| one row | hold 498×76, board 536×76 (a row's minimum is 2 px: a Button is not a Container, so row children never propagate a minimum) |
| value cells | hold 70/80/100, board 80/60/95, family 130 |
| row furniture | 12/8 inner margins + 40 icon + 4 × 12 gaps = **112 px** |
| fixed content per row | hold **362 in 498**, board **347 in 536** (component rows 382) |
| last value cell vs column edge | hold x 915 ≤ 928, board x 1469 ≤ 1492 |
| title block | hold **136**, board mineral rows **189** (widest component rows ~154) |
| controls | stepper 48×48, SELL 360×88, SELL ALL RAW / CANCEL 360×56 |
**Deviation from §5.8's column widths — the one thing a reviewer must weigh.** §5.8
carries the §12.3 OUTFITTING widths into this panel: QTY 130 / UNIT 110 / TOTAL 160 and
PRICE 110 / DEMAND 130 / TREND 160 / STOCK 110 / FAMILY 130 / GRADE 160. With 112 px of
furniture that is a **512 px** fixed row in *both* columns: 512 + 16 + 512 + 16 + 360 =
1416 px fits the 1440 px pane box, but leaves **24 px for both title blocks** (12 px
each) — the row names, which are catalogue data, would be invisible. Independently, the
hold column's §5.8 floor of 340 px cannot seat a 512 px row: its QTY/UNIT/TOTAL cells
would be laid out past the column edge, over the market board. Measured name widths under
the shipped theme (`StationValue`, 18 px): `MAW CANNON CHAMBER` 222, `DREADNOUGHT SLAG`
188, `NEODYMIUM INGOT` 176, `GOLD INGOT` 112, `IRON ORE` 76; values: `1 354 800` 82,
`COOLING` 83, `ELECTRONICS` 119, `40 / 40` 58, `1.6x` 36. The shipped columns are the
measured sizes (round numbers above the measured text), `FAMILY` keeps §5.8's 130 exactly
(`ELECTRONICS` = 119), the hold column is raised to 500 by the scroll's content width
(`HoldBox` keeps `custom_minimum_size (340, 0)` in the scene), the board takes the slack
(548), and row titles use `OVERRUN_TRIM_ELLIPSIS` so a long name can never spill over the
next cell. 22 of the 78 catalogue names exceed the hold's 136 px (13 exceed the board's
component 154); the selected item's full name is still shown in the trade column.
Amendments to consider: adopt the measured columns, fold `QTY` into the title meta to win
back 142 px, or widen the pane.

## Other reviewer notes

- **Ingot quote and the `&"credits"` refresh.** The board quotes each mineral's ingot form
  (`exchange_price(ingot_id, demand)`, meta `INGOT`), because 05 §2 and §3 publish a mineral
  price that way and demand is per mineral, not per form; ore appears in the hold whenever
  the player carries it. The exchange never sells to the player, so `&"credits"` carries no
  affordability to grey: it re-reads the board cells and the quote strip and must never
  disarm a pending sale (asserted).
- **Refusal copy.** `unknown_item` → `NOT FOR SALE`, `invalid_qty` → `PICK AT LEAST ONE
  UNIT`, `insufficient_cargo` → `NOT ENOUGH IN THE HOLD` (unreachable through the UI, the
  stepper is clamped to the held quantity), nothing sellable → `REFUSED · HOLD EMPTY`;
  `SELL ALL RAW` holding only ingots says `REFUSED · NO RAW STACK TO SELL`.
- **Stepper / audio.** The stepper stays enabled at both bounds and clamps; `disarm()`
  returns true only when it cleared something. **No Timer**: `Exchange.evaluate_market`
  runs in `_ready` and inside every quote/sale; `Clock` is preloaded as a script, never the
  autoload node. Cues: CLICK on row select and each action button, CONFIRM on a sale,
  DENIED on a refusal, SCROLL on stepper ticks and both scroll containers.
- **`user://profile.cfg`.** The probe provably never writes it (mtime + sha256 identical
  across the final run; `save_path` is redirected first). Disclosure: one deleted scratch
  diagnostic stood the panel up standalone **without** redirecting `save_path`, so the
  entry evaluation stamped `market.last_band` plus a component stock table into the
  owner's profile at 11:50:53 — exactly what the game writes on its first station entry.
  A bare `station.tscn` run does not write the file.
