---
slice: S5
worker: S5-J2
model: "deepseek/deepseek-v4-flash"
status: actionable    # the ARMORY rows' HELD figure is J3's move (one red, reported)
gate: "524/0 → 544/1 (twice, identical; the one failure is J3's surface move; live profile md5 unchanged)"
---

# S5-J2 report — ammunition becomes cargo

## Result

Ammunition is a cargo commodity exactly as CONTRACTS §17 / 10 §6.1 pin it: six cargo items
(`ammo_laser` … `ammo_railgun`) counted in units of `ROUNDS_PER_CARGO_UNIT := 10`, the ARMORY
rows buy **units into the hold** instead of into a magazine, the launch auto-loads each fitted
family's pack from the hold once (whole units leave the hold, never in flight), the EXCHANGE
buys units at 60 % of the per-unit list beside the minerals, and the fuel-cell delist is
asserted (J0 measured nothing to change) while a `fuel_cell` stack still burns on `R`.

Gate, this machine, twice on two separate scratch stores
(`XDG_DATA_HOME=/tmp/s5j2_scratch{A,B}`), live `user://` untouched:

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=544 failed=1        (run 1 and run 2, identical)
```

The one failure is `test_p2b1_outfitting_panel.gd:437` — the ARMORY pane's own row count, which
is **J3's surface move** (below). New suite alone: `--suite=test_s5_ammo_cargo` → `passed=14
failed=0`. Arithmetic of the count: `524` (baseline) `+ 14` (this suite) `+ 7` (J1's
`test_s5_commerce.gd`, which landed in the tree during this dispatch) `= 545` tests `= 544
passed + 1 failed`.

## The pinned model, and the five decisions taken inside it

`buy_ammo(family, rounds, cost)` now charges the pack's own price and delivers
`rounds / 10` **units** of the family's `ammo_*` cargo item; it writes no pack. The pack store
becomes the **magazine**: `load_ammo_from_hold(family)` tops it up from the hold's units up to
the family's `ammo_max` and answers what it now holds, and `game.gd:_seed_ammo` calls it once
per fitted family (a Lancer's two lasers load one pack, both slots read it) before seeding
`PlayerState`. Every decision below is inside the pinned acceptance (escalation bucket 1) and
names its one-line reversal:

1. **Top-up, not set.** The pack is *filled up to* the ceiling, never lowered, and the leftover
   magazine from the last sortie is kept; the shipped dock report (`set_ammo`, filed fired
   deltas) stays meaningful because the pack it files into is the same magazine the next launch
   tops up. Reversal: replace the `pack + drawn * ROUNDS_PER_CARGO_UNIT` add with an assignment.
2. **The ceiling is the profile's per-family `AMMO_MAX`** (the pin names `ammo_max 150` for the
   railgun). Reversal: read `PlayerState.AMMO_DEFAULT` (300 for every family) instead.
3. **Units round up** (`ceil`), because a unit is indivisible: buying 5 rounds buys one unit, and
   a top-up's last unit may overshoot the ceiling by up to 9 rounds, which the pack's clamp
   spends (measured below). Reversal: floor, which leaves a magazine up to 9 rounds short.
4. **The auto-load writes the pack through `set_ammo`**, so the live slot always equals the
   store (`test_engine2_wiring.gd:293` still holds) and the ARMORY/LAUNCH readers see the load.
   Reversal: seed `PlayerState` from the returned figure without the write.
5. **The exchange's own commission applies to an ammo sale** (05 §5; the pane's confirm strip
   already prints GROSS/FEE/PAID), so `sale = roundi(0.6 * list_unit)` is the *unit price* the
   pin states and the payout is `gross - fee`. Measured: a whole 30-unit laser pack pays 50 of
   its 60 gross, the 10 CR floor taking the rest. Reversal: skip `commission_for` for
   `KIND_AMMO`, and the payout becomes the pinned 60 % exactly.

## Measured numbers (all from `tests/test_s5_ammo_cargo.gd`)

Per-unit list and sale, derived by `roundi(10 * cost / rounds)` and `roundi(0.6 * list)`: laser
300/120 → 4 → **2**; cannon 300/180 → 6 → **4**; rocket 60/240 → 40 → **24**; mine 40/200 → 50 →
**30**; plasma 50/320 → 64 → **38**; railgun 150/360 → 24 → **14**. All twelve match CONTRACTS
§17's figures exactly; `exchange_price` reads the sale at any demand (there is no demand index on
the third book), `baseline_of` reads the list, and `is_sellable` is true for all six and false
for `fuel_cell`.

Purchase: each of the six packs buys its own unit count (30, 30, 6, 4, 5, 15) for its own price,
the hold is keyed by the prefixed id, **the pack store does not move**, and two buys stack (60
laser units after two). Refusals (no credits, an unknown family, zero rounds, the fuel cell)
charge nothing, deliver nothing and open no seventh pack or cargo id.

Auto-load, on the shipped flight scene: laser 100 + 30 units held → **300 loaded, 20 units
drawn, 10 left**; cannon 0 + 12 units → **120 loaded, 0 left**; twin lasers (pack 0, 30 units) →
**300/300, 0 left** (a per-slot draw would have left slot 2 empty — the measured once-per-family
check); cannon 295 + 1 unit → **300 loaded, 0 left** (the ≤9-round clamp); rocket 300 (above its
100 ceiling) + 10 units → **no draw, hold intact**; rocket 90 + 10 units → **100 loaded, 9 left**.
In flight the hold never moves: firing dry files the pack to 0 with the hold unchanged, the next
launch with an empty hold loads 0, and with 3 units loads 30. Finding 7's slot half: the 10 units
left in the hold read **`cargo_used` 10** on the launch's own mirror (one unit is one slot).

Sale: 30 laser units → gross 60, fee 10, **paid 50**, hold emptied to 0 units, credits +50, and
`market()` **byte-identical** before and after (the third book moves no demand, stock or queue).
A 31-unit sale against 30 held refuses `insufficient_cargo` and moves nothing; an unknown id
refuses `unknown_item`; `sell_all` (SELL ALL RAW, 05 §6) leaves the ammunition alone.

Surfaces: the shipped EXCHANGE pane draws the ammo rows after the minerals and components, in
pack order, with the pack's own name and `AMMO` meta (`LASER CELLS` 30 units @ 2 → 50 CR;
`RAILGUN SLUGS` 4 @ 14 → 46 CR) and no row for an unheld family. The delist sweep found no
`fuel_cell` in `AMMO_PACKS`, `SHIPS`, `MODULES`, the minerals/ingots or the components (the only
"Fuel Cell" in the tree is `comp_pow_1`, a different id), the exchange prices it 0, and an
existing stack still burns on `R` (fuel 100 → 140, hold 2 → 1). The countermeasure packs are
staged out, measured as the pack set being exactly the six pinned ids.

## Files touched

- `game/station_catalog.gd` — `ROUNDS_PER_CARGO_UNIT`, `AMMO_PREFIX`, the railgun pack row
  (150 / 360 / module glyph), and `ammo_item_id` / `ammo_family` / `ammo_item_ids` /
  `ammo_pack_units` / `ammo_unit_cost`.
- `autoload/player_profile.gd` — `AMMO_MAX` gains the railgun (150); `buy_ammo` delivers cargo
  units and logs `BUY_AMMO`; new `ammo_item_id`, `ammo_units`, `load_ammo_from_hold`,
  `_ammo_units_for`.
- `game/exchange.gd` — the third book: `KIND_AMMO`, `AMMO_SELL_PERCENT := 0.6`, `is_ammo`,
  `ammo_list_unit`, `ammo_unit_price`, and the `baseline_of` / `exchange_price` / `is_sellable` /
  `_quote_from` / `_apply_trade` branches.
- `game/game.gd` — `_seed_ammo` auto-loads per family once (`_auto_load_ammo`); the dock filing's
  comment re-stated; nothing else in the launch/dock seam moved.
- `ui/station/exchange_panel.gd` — the hold lists the ammo units after the components, with the
  pack's icon/name and the `AMMO` meta word.
- `tests/test_p1_profile.gd` — one count moved (below).
- `tests/test_s5_ammo_cargo.gd` — new, 14 tests (AC4a–AC4d).
- **Set members left untouched, deliberately:** `game/module_catalog.gd` (the railgun module row
  and its `icon_module_w_railgun.svg` already resolve; `WEAPON_ICON_FAMILIES` stays five),
  `game/component_catalog.gd` (an ammo unit is not a component: no grade, no family, no surplus
  quota — the six rows are `StationCatalog.AMMO_PACKS`), and
  `ui/station/exchange_panel.tscn` (the pane builds every row in code, so no scene edit was owed).

## Tests that move

- `tests/test_p1_profile.gd:91` — **moved by this worker** (bucket 1: test mechanics inside a
  pinned acceptance). `Profile.AMMO_MAX.size()` 5 → 6, because §17's owner-ratified sixth
  family *is* the sixth `AMMO_MAX` row; each family's pack default still reads `DEFAULT_AMMO`.
  Nothing else in the suite moved.
- `tests/test_p2b1_outfitting_panel.gd:437` — **left for J3**, which owns the ARMORY pane and the
  row counts ("counts move with the surface" in the brief). `assert_eq(_held(&"rocket"), 300 +
  rounds, "and added the pack's own rounds")` is false by design now: the buy adds **6 units to
  the hold** and the pack stays 300. J3 resolves it one of two ways, both inside its set: the
  pane's HELD cell moves to `ammo_units(family)` (and the suite's `_held()` helper follows), or
  the pane keeps showing the magazine and that single assertion becomes
  `_held(&"rocket") == 300` plus a `cargo_qty(&"ammo_rocket") == 6` line.
- Measured **still green, no edit owed** (the brief expected these to move): `test_p2a_launch_fit`'s
  two pack tests (an empty hold draws nothing, so the pack store read is unchanged), 
  `test_engine2_wiring.gd:293` (the launch writes the pack it loaded, so the invariant holds),
  `test_s2_6_gate_hygiene.gd:147` (every family still opens at `DEFAULT_AMMO`).
- `tests/test_p1_catalogues.gd` — **not moved**, and the brief's line about it is read as already
  satisfied elsewhere: there is no "cargo catalogue" data table (the hold is a plain dictionary),
  so the six `ammo_*` rows are pinned by `test_s5_ammo_cargo.gd` instead of by a p1 assertion.

## Reported, not changed (bucket 2/3)

- **The LAUNCH pane's ordnance summary reads the pack store, not the hold**
  (`ui/station/launch_panel.gd:523-533 _ammo_total`/`_weapon_count`, outside every S5 set). It
  now summarises **6** weapons instead of 5 (6 × 300 = 1800 rounds on a fresh account vs 1500),
  and it shows the last load rather than the units the player is about to fly with. Owner call:
  a one-file follow-up, not a J2 edit.
- **A fresh account's magazine starts above its own ceiling for four families.** `DEFAULT_AMMO`
  is 300 while `AMMO_MAX` is rocket/mine/plasma 100 and railgun 150, so the auto-load's
  "up to `ammo_max`" never draws for them until they are fired below their ceiling, and it never
  *lowers* them (decision 1). This is the shipped pre-S5 shape (`DEFAULT_AMMO` is untouched
  here); reversal if the owner wants the magazine to start at its ceiling:
  `_ammo[family] = mini(DEFAULT_AMMO, AMMO_MAX[family])` in `_apply_defaults`/`_read_values`,
  a four-family default change outside this pin.
- **The `_ammo` store's name is now a lie for buyers**: it is the magazine a launch loads, not
  something a purchase grows. It is the pinned reading (`ammo_max`/`ammo_of` stay family-keyed),
  and the ARMORY pane's HELD display is J3's to move.

## Evidence

```bash
cd "$VAJB_WORKSPACE"
VAJB_WORKER_FILES="vajb-orbit/game/module_catalog.gd,vajb-orbit/game/game.gd,vajb-orbit/game/exchange.gd,\
vajb-orbit/game/component_catalog.gd,vajb-orbit/game/station_catalog.gd,vajb-orbit/autoload/player_profile.gd,\
vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/exchange_panel.tscn,vajb-orbit/tests/"
# suite only (scratch store):
XDG_DATA_HOME=/tmp/s5j2_scratchA godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s5_ammo_cargo
[SUMMARY] passed=14 failed=0
# full gate, twice, two scratch stores (identical):
XDG_DATA_HOME=/tmp/s5j2_scratch{A,B} godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200
[FAIL] test_p2b1_outfitting_panel.gd.test_ammo_purchase_charges_the_catalogue_price_and_greys_when_short: and added the pack's own rounds
[SUMMARY] passed=544 failed=1        # both runs
# the live account, before and after every run:
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"
cb77a6e53404ce21d94f1a473f0593d2    # identical before the first run and after the last
# parse checks on the five shipped files (no parse error; the two "Identifier not found"
# lines are `--check-only` not resolving autoloads and are pre-existing):
godot --headless --path vajb-orbit --check-only --script res://autoload/player_profile.gd
godot --headless --path vajb-orbit --check-only --script res://game/station_catalog.gd
godot --headless --path vajb-orbit --check-only --script res://game/exchange.gd
```

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The ARMORY rows' HELD figure still reads the magazine; one suite assertion is red until it moves | J3 (surface) | `ui/station/outfitting_panel.gd`, `tests/test_p2b1_outfitting_panel.gd:437` |
| LAUNCH's ordnance summary reads the pack store (and now counts six weapons) | LOW / owner call | `ui/station/launch_panel.gd:523-533` |
| A fresh account's magazine exceeds its family ceiling for four families | LOW / owner call | `autoload/player_profile.gd:157-168` |
