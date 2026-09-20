# P1d task — minerals exchange module (docs 05, 01 §7, 03 §3)

Worker: coder. Wave: P1 economy core. Deliverable: exactly one new file:

`vajb-orbit/game/exchange.gd`

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`addons/`, `project.godot`, docs, or any existing script.

Depends on files that may land around the same time as this task (read them
if present; if a helper is missing, follow the contract below exactly and say
so in the report):
- `game/mineral_catalog.gd` — `class_name MineralCatalog`; `MINERALS` rows
  with `id` (base id like `iron`), `ore_value`, `ingot_value`, plus
  `ore_id()`, `ingot_id()`, `mineral_id_of_item()`, `is_ore()`, `is_ingot()`.
- `game/component_catalog.gd` — `class_name ComponentCatalog`; `COMPONENTS`
  rows with `id`, `grade`, `value`; `component()`.
- `autoload/world_clock.gd` — `bands_between(from, to) -> int`, static only.
- `game/economy_log.gd` — `EconomyLog.append(event, item, qty, delta, balance)`.
- `autoload/player_profile.gd` — v2: `market()` / `set_market(state)` with
  shape `{"demand": {mineral_id: float}, "stock": {component_id: int},
  "queue": {component_id: int}, "trend": {mineral_id: int},
  "last_band": int}`; cargo API `cargo_qty/cargo_items`; credits API
  `add_credits/spend/credits`.

## Read first

- `docs/gameplay/05_exchange.md` — ALL. §2, §3, §4, §5, §6, §8 are law.
- `docs/gameplay/01_economy_core.md` — §7 (transaction order + log).
- `docs/gameplay/03_components.md` — §3, §4.1 (grade quotas come from 05 §4:
  I 40, II 15, III 4).
- `docs/gameplay/17_coder_handoff.md` — §5 (transaction law).

## Contract

`class_name Exchange extends RefCounted`. Preload the modules above by path
(`const MineralCatalog := preload("res://game/mineral_catalog.gd")`, same for
the others; do NOT reference autoload names as bare identifiers). Header
comment cites 05 and records the two rounding bases (below).

Constants (05 §2/§4/§5):

- `const COMMISSION := 0.02`, `const COMMISSION_MIN := 10`
- `const DEMAND_MIN := 0.6`, `const DEMAND_MAX := 1.6`
- `const DEMAND_STEP := 0.15`, `const TRADE_IMPACT := 0.01`
- `const SURPLUS_DISCOUNT := 0.9`
- `const STOCK_QUOTA: Dictionary = {1: 40, 2: 15, 3: 4}`

### Pricing (the one pricing function family, 05 §8)

- `static func unit_net(baseline: int, demand: float) -> int` —
  `roundi(baseline * demand * (1.0 - COMMISSION))`. This reproduces the 05 §3
  table exactly.
- `static func unit_gross(baseline: int, demand: float) -> int` —
  `roundi(baseline * demand)`.
- `static func commission_for(gross: int) -> int` —
  `maxi(COMMISSION_MIN, ceili(gross * COMMISSION))` ("2 %, minimum 10 CR,
  rounded up", 05 §5).
- `static func sale_quote(baseline: int, demand: float, qty: int) -> Dictionary`
  — `{&"gross": roundi(baseline * demand * qty), &"fee": commission_for(gross),
  &"paid": maxi(0, gross - commission_for(gross))}`. This reproduces the 05 §5
  worked examples exactly.
- `static func component_unit_price(value: int) -> int` —
  `roundi(value * SURPLUS_DISCOUNT)` (05 §4).
- `static func exchange_price(item_id: StringName, demand: float) -> int` —
  the single public price read for UI: mineral ore/ingot ->
  `unit_net(baseline, demand)`; component -> `component_unit_price(value)`;
  `0` for anything unknown. **No other price computation may exist in UI code.**
- `static func baseline_of(item_id: StringName) -> int` — ore -> `ore_value`,
  ingot -> `ingot_value`, component -> `value`, else 0.
- `static func is_component(item_id: StringName) -> bool`,
  `static func is_sellable(item_id: StringName) -> bool`.
- `static func demand_of(profile: Node, mineral_id: StringName) -> float` —
  reads `profile.market()["demand"]`, defaults 1.0.

Rounding base note for the header: 05 §3's per-unit figures use `roundi` of
the net product (per-unit base); the 05 §5 worked examples use one
transaction-level gross with `ceil` commission (transaction base). They can
differ by a few credits on a batch; both are implemented and tested exactly
as written. The 05 §2 raw-ore example ("18 x 0.98 = 17") is inconsistent with
rounding (it is 17.64 -> 18 under both the table and this function) — report
it, do not special-case it.

### Market evaluation (the one clock, 05 §2/§4)

`static func evaluate_market(profile: Node, now: int,
rng: RandomNumberGenerator = null) -> int` — returns the number of bands
applied.

- Read `state := profile.market()`.
- `last := int(state["last_band"])`. If `last <= 0`: initialise
  `last_band = now`, fill every missing component stock with its quota,
  write back, return 0. (First evaluation ever = start state, no drift.)
- `bands := Clock.bands_between(last, now)`. If <= 0, still fill missing
  stock defaults, write back only if something changed, return `bands`.
- For each band (in order):
  1. **demand drift** (05 §2): per mineral id, `d = clampf(d +
     rng.randf_range(-DEMAND_STEP, DEMAND_STEP), DEMAND_MIN, DEMAND_MAX)`
     (when `rng` is null use the global RNG); store `trend[mineral_id] =
     int(signf(step))` (-1 / 0 / +1) — the glyph later reads the last band's
     step.
  2. **restock** (05 §4): per component, `stock = quota(grade)`.
  3. **queue flush** (05 §4): per component with `queue > 0`:
     `sold = mini(queue, stock)`; if `sold > 0`: `unit =
     component_unit_price(value)`, `gross = unit * sold`, `fee =
     commission_for(gross)`, `paid = gross - fee`; `profile.add_credits(paid)`;
     `stock -= sold`; `queue -= sold`; `EconomyLog.append("QUEUE_BUY",
     component_id, sold, +paid, profile.credits())`.
- Set `last_band = now`, `profile.set_market(state)`, return `bands`.

`static func quota_for(grade: int) -> int` — public helper (0 for unknown).

### Transactions

`static func quote(profile: Node, item_id: StringName, qty: int, now: int,
rng: RandomNumberGenerator = null) -> Dictionary` — evaluates the market,
then returns, without mutating cargo/credits:
`{&"ok": bool, &"reason": StringName, &"item": StringName, &"kind":
&"mineral"|&"component", &"qty": int, &"sellable": int, &"queued": int,
&"unit": int, &"gross": int, &"fee": int, &"paid": int, &"demand": float,
&"stock": int}` (`sellable`/`queued`/`stock` are component fields; minerals
report `sellable = qty`, `queued = 0`, `stock = 0`). Refusals: `invalid_qty`
(qty <= 0), `unknown_item`, `insufficient_cargo` (held < qty).

`static func sell(profile: Node, item_id: StringName, qty: int, now: int,
rng: RandomNumberGenerator = null) -> Dictionary` — full transaction; same
return shape as `quote` plus it mutates:

1. Evaluate market once, then build the quote (no second evaluation).
2. Verify per the quote; on failure return it unchanged and touch nothing.
3. **Take goods:** `profile.remove_cargo(item_id, qty)`; it must succeed
   (already verified). On false, return `insufficient_cargo` and stop.
4. **Pay:** mineral -> `profile.add_credits(paid)`; component ->
   `profile.add_credits(paid_for_sold)`; then update market state:
   - mineral: `demand = clampf(demand - TRADE_IMPACT * qty, DEMAND_MIN,
     DEMAND_MAX)` (05 §2), write back;
   - component: `stock -= sellable`, `queue += queued`, write back.
5. **Log** (01 §7 / 05 §8 format):
   - `EconomyLog.append("SELL", item_id, sold_qty, +paid, profile.credits())`
   - when `queued > 0`: `EconomyLog.append("QUEUE", item_id, queued, 0,
     profile.credits())`.
6. Return the filled quote.

Order is verify -> take -> pay -> log (17 §5). A component sale with
`sellable == 0` (stock empty) still takes the goods into the queue, pays 0,
and reports `queued = qty` — the 05 §4 queueing rule.

`static func sell_all(profile: Node, now: int, rng: RandomNumberGenerator =
null) -> Dictionary` — the 05 §6 SELL ALL RAW: evaluate once, then sell every
raw ore stack (`MineralCatalog.is_ore`) and every surplus-book component
(each per the `sell` rules) in one confirmed action. Ingots are NOT included.
Return `{&"ok": bool, &"paid": int, &"lines": Array[Dictionary],
&"skipped": Array[StringName]}` (`lines` = the per-item sale returns;
`skipped` = ids that refused; `ok` = no refusals).

`static func trend_word(trend: int) -> String` — `-1` -> `COOLING`, `0` ->
`STEADY`, else `HOT` (05 §6 glyph vocabulary, rendered as words; see the
STATION_HUB amendment 5.8).

## Constraints

- Integers for credits everywhere; floats only for demand.
- Never mutate `profile` state through anything but its public API.
- No `print()`; warnings via `push_warning`.
- Typed GDScript, tabs, house header.

## Parse gate (required)

Probe scene `res://tools/_probe_p1d.tscn` + `_probe_p1d.gd`. Because the
profile's real save is off limits, the probe uses an off-tree
`load("res://autoload/player_profile.gd").new()` with
`profile.save_path = "user://p1d_probe.cfg"` set before any mutation
(clean up the file at the end). Assert with printed evidence:

1. `unit_net`: Iron ingot 65 @ 1.0/0.6/1.6 -> 64/38/102; Titanium 162 ->
   159/95/254; Gold 395 -> 387/232/619; Krillum 2160 -> 2117/1270/3387.
2. `sale_quote(395, 1.2, 10)` -> gross 4740, fee 95, paid 4645.
   `sale_quote(component_unit_price(12) == 11, 1.0, 1)` -> gross 11, fee 10,
   paid 1.
3. `evaluate_market` with `WorldClock.set_override()`: first call stamps
   `last_band`; a second call 1200 s later applies exactly one drift step
   with every demand inside [0.6, 1.6]; a 3-band gap returns 3.
4. A seeded `RandomNumberGenerator` makes drift deterministic.
5. Sell flow: cargo `mineral_iron` 10, demand 1.0 -> sell 10 -> credits up by
   the quote's paid, cargo empty, demand drops by 0.10, one `SELL` line in
   `user://p1d_probe_log.txt` (`EconomyLog.log_path` override).
6. Component flow: cargo `comp_scrap_1` 50 with quota 40 -> sell 50 ->
   sellable 40, queued 10; after a band the queue pays out.
7. `sell_all` sells ore + components, skips ingots, returns totals.
8. Refusals: unknown item, invalid qty, insufficient cargo — cargo and
   credits untouched.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1d.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. Delete the probe files and any `.uid` sidecars
they got, and both probe files in `user://`, before you finish.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1d_report.md`: deliverables, exact commands + observed
output, every probe assertion with its result, deviations, and anything a
reviewer should look at. Under 120 lines.
