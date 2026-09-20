# P1i task — EXCHANGE station panel (STATION_HUB amendment 5.8, doc 05)

Worker: coder. Wave: P1 economy core, panels. Deliverables, exactly two new
files:

1. `vajb-orbit/ui/station/exchange_panel.tscn`
2. `vajb-orbit/ui/station/exchange_panel.gd`

Do not touch any other file (the shell already lists your panel in
`MODULE_FILES`; it loads it by name). No MCP tools. Do not run the editor. Do
not edit `addons/`, `project.godot`, docs, the theme, or any other script or
scene.

## Read first

- `docs/design/STATION_HUB.md` — §3.1 (measured grid), §5.8 (your spec),
  §5.6 (refusal path), §12.3/§12.4. Section 5.8 is the contract; do not invent
  measurements.
- `docs/gameplay/05_exchange.md` — §2 (demand), §3 (price table shape), §4
  (surplus book, quotas, queue), §5 (commission), §6 (trading flow), §8
  (implementation notes: one pricing function, one clock).
- `vajb-orbit/ui/station/outfitting_panel.tscn` + `.gd` — row anatomy,
  status strip, focus, helpers.
- `vajb-orbit/ui/station/shipyard_panel.tscn` + `.gd` — the three-column body
  (list / expand / stats column) you copy for
  `HoldBox` (min 340) / `MarketBoard` (expand) / `TradeBox` (min 360).
- `vajb-orbit/ui/station/launch_panel.tscn` + `.gd` — brief value rows and
  the 360 px deck control your `TradeBox` copies.
- `vajb-orbit/ui/screens/station.gd` — the panel duck-typed contract
  (`status_requested`, `refresh_profile`, `focus_primary`, optional
  `disarm`).
- `vajb-orbit/game/exchange.gd` — read-only contract:
  `evaluate_market(profile, now, rng)`, `exchange_price(id, demand)`,
  `quote(profile, id, qty, now)`, `sell(profile, id, qty, now)`,
  `sell_all(profile, now)`, `trend_word(trend)`, `demand_of(profile, id)`,
  `is_sellable(id)`, `is_component(id)`, `unit_net`, `component_unit_price`.
- `vajb-orbit/game/mineral_catalog.gd`, `game/component_catalog.gd` — board
  rows; `autoload/world_clock.gd` — call its **static** `now()` (preload the
  script, do not depend on the autoload node).

## Panel contract

- Root `VBoxContainer` named `Exchange`, separation 12, no theme baked.
  Unique names per §5.8: `PaneHeader` (`EXCHANGE`, subtitle
  `MINERALS AND SURPLUS`), `HoldBox` (`HoldScroll` → `HoldRows`),
  `MarketBoard` (`BoardScroll` → `BoardRows`), `TradeBox`, `PaneFooter`.
- Call `Exchange.evaluate_market(profile, Clock.now())` once in `_ready` and
  again before every quote/sale. Never create a Timer (17 §4).
- Hold rows (selectable, 76 px): icon 40 / title + meta (`ORE`, `INGOT`, or
  family label) / `QTY` 130 / `UNIT` 110 / `TOTAL` 160. Sources:
  `profile.cargo_items()` filtered by `Exchange.is_sellable`, minerals in
  catalogue order, then components in catalogue order. `UNIT` from
  `Exchange.exchange_price`; `TOTAL` from `Exchange.quote` (paid).
- Market rows (non-interactive, `focus_mode = NONE`, 76 px): 20 mineral rows
  (`PRICE` 110 / `DEMAND` 130 `"1.2x"` / `TREND` 160 = `Exchange.trend_word`)
  then 18 component rows (`STOCK` 110 `"12 / 15"` / `FAMILY` 130 / `GRADE`
  160). Icons tinted per tier/grade with the catalogue tint tables.
- `TradeBox`: caption `SALE`, selected title, stepper (`-` / `"<n> UNITS"` /
  `+`, 48 px buttons, 1..held, default all), `ConfirmStrip` (`StationValue`)
  reading `SELL <n> <ID> — GROSS <g> · FEE <f> · YOU GET <p>` from
  `Exchange.quote`, then `SELL` (88 px), `SELL ALL RAW` (56 px), `CANCEL`
  (56 px). Nothing computes a price outside `Exchange`.
- Actions: `SELL` -> `Exchange.sell(profile, id, n, Clock.now())`. Success:
  strip `SOLD · <n> <ID> · +<paid> CR`; queued case: `STOCK FULL · <n> UNITS
  QUEUED`; refresh hold rows, board stock, credits. `SELL ALL RAW` ->
  `Exchange.sell_all`; strip totals. Refusal -> §5.6 wording plus
  `REFUSED · HOLD EMPTY` when nothing is sellable.
- Empty hold: a single `HOLD EMPTY` caption row, `TradeBox` disabled. Footer:
  `THE STATION BUYS · IT NEVER SELLS IN V1`.
- `refresh_profile(key)`: rebuild hold rows on `&"cargo"`, refresh prices and
  affordability on `&"credits"`.
- `focus_primary()`: first hold row, else `SELL ALL RAW`.
- `disarm()`: clear the selection/stepper, return true when cleared.
- Audio: CLICK on row select, CONFIRM on sale, DENIED on refusal, SCROLL on
  stepper (mirror the existing panels). No new cues.

## Probe (required)

Probe scene `res://tools/_probe_p1i.tscn` + `_probe_p1i.gd` that boots
`res://ui/screens/station.tscn` headless:

1. Redirect `PlayerProfile.save_path` to `user://p1i_probe_profile.cfg` and
   `EconomyLog.log_path` to `user://p1i_probe_log.txt` **before** any
   mutation. Seed: `add_cargo(&"mineral_iron", 10)`,
   `add_cargo(&"ingot_gold", 3)`, `add_cargo(&"comp_scrap_1", 50)`.
2. Switch to EXCHANGE by emitting `pressed` on `ExchangeEntry`.
3. Assert: 3 hold rows; 38 board rows (20 + 18) in catalogue order; the gold
   ingot row's `UNIT` equals `Exchange.exchange_price(&"ingot_gold", demand)`
   and its confirm strip matches `Exchange.quote` exactly (gross, fee, paid).
4. Sell the 3 gold ingots: credits increase by the quote's paid, cargo stack
   gone, status strip carries `SOLD · ...`.
5. Sell the 10 iron ore: same checks, demand drops by 0.10 in the profile's
   market state.
6. Component queue: sell 50 `comp_scrap_1` -> strip shows `STOCK FULL · 10
   UNITS QUEUED`, credits increase by the 40-unit quote only.
7. `SELL ALL RAW` on a refilled hold: ore + components sell, ingots stay.
8. Stepper clamps at 1 and held; `CANCEL` clears the selection; empty hold
   shows the empty state and boots with no SCRIPT ERROR.
9. Print `PROBE OK`; quit. Delete probe files, their `.uid` sidecars, and
   `user://p1i_probe_*` before you finish. **Never** touch
   `user://profile.cfg`.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1i.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1i_report.md`: deliverables, commands + observed output,
every probe assertion with its result, measured geometry evidence, and
anything a reviewer should look at. Under 140 lines.
