---
slice: S24
worker: S24-F1
model: deepseek-v4.1-flash (hyper)
status: actionable
gate: "1185/0 → 1186/0 (twice, fresh scratch stores, exit 0)"
---

# S24-F1 report

## Result
F1 is closed: the shell's refusal strip prices through the registry's one reader, so at any
non-Neutral band its `%s NEEDED` figure is the number the pane that triggered
`purchase_failed` charged. Nothing else moved — the two LOWs are untouched (F2 → T-152,
F3 → T-153), no cost path was edited, no pinned value changed. `passed=1186 failed=0` twice,
exit 0; 1185 → 1186 is exactly the one new row this fix needed.

## Finding-by-finding disposition

- **F1 (HIGH) — fixed.** `ui/screens/station.gd:1328-1348`. `_entry_cost` now takes the
  catalogue's own `cost` as its input and hands it to `StationRegistry.apply_price` when a
  place is docked, with the docked row from `StationRegistry.docked_station(_profile())` and
  the band from the new `_station_standing(station)` (the row faction's `standing_of`, 0 with
  no profile or no accessor — the shape `armory_panel.gd:3056-3063` already uses). The tech
  step gets the entry's own id **only when `ModuleCatalog.module(id)` resolves**, so a module
  copy equals `armory_panel._module_price` (band + 12 §5's −15 %) while a pack and a hull take
  the band alone — exactly the inputs `Catalog.ammo_pack_price` / `Catalog.ship_price` and
  `Auction.buy_hull` charge with. An empty station row returns the catalogue number
  unchanged, so the station-less copy is the shipped one. Reversal: restore the one-line body
  `return int(_entry(id).get(&"cost", 0))` and drop `_station_standing`.
- **F2 (LOW) — not fixed, per instruction.** `ui/station/launch_panel.gd:53`'s
  `OPEN SPACE · HELIOS DRIFT` string is untouched; ticketed as T-152.
- **F3 (LOW) — not fixed, per instruction.** `game/auction.gd:421`'s tier clamp is untouched;
  ticketed as T-153.

## Acceptance list delta

- **A6 — pass, no longer "with F1".** The one price read site outside the law is inside it:
  the shell copy is now a registry read, so the report's own claim holds with no exception.
  Cite: `ui/screens/station.gd:1332-1338`.
- **A2 — unchanged and re-measured green.** Every A2 figure (repair 692 → 761/657/623, the
  pack 120 → 132/114/108, the hull 9000 → 9900/8550/8100, the additive 3900, the commission
  27/36) reads the same; this fix moved a display step only. No pinned value was touched.
- A1/A3/A4/A5 — not touched by this pass.

## What the fix does and does not change

- **Changes:** the text of `_refusal_text(REASON_INSUFFICIENT, id)` when a place is docked —
  the only reader of `_entry_cost`.
- **Does not change:** any charge. `PlayerProfile.buy_ammo`/`buy_module`/`buy_ship` take the
  price from their caller as before, and no pane's price read was edited. The brief's rule 7
  (catalogue list → band → the hot row's −20 % last) is untouched.

## Evidence

- Gate, twice on fresh scratch stores, final tree, exit 0 each:
  `[SUMMARY] passed=1186 failed=0` / `[SUMMARY] passed=1186 failed=0`
  (`XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`).
- Count: 1185 → 1186 is one row; `test_s24_world.gd` carries 19 `func test_` (18 + the new
  one) and no other suite's row count moved.
- New row: `test_s24_world.gd:test_the_refusal_strip_prices_through_the_registry` — docked at
  `s2_primary` with `concord` Shunned, the strip reads 132 for `laser` (the armory's
  `ammo_pack_price`), the armory's own `_module_price(&"h_composite")` figure for a module, and
  the auction's `ship_price(&"ship_fighter")` for a hull; a bare shell reads the catalogue's
  own 120.
- Negative control (the fix reverted to the one-liner in a scratch copy, then restored
  byte-identically, md5 `bc7636c94f37196da0af8bcdc516c498`):
  `[FAIL] test_s24_world.gd.test_the_refusal_strip_prices_through_the_registry: a pack's copy
  is the station price the armory charged` → `[SUMMARY] passed=18 failed=1`. The row measures
  the fix, not the fixture.
- Station-less copy still proves the shipped behaviour: `test_p2b1_outfitting_panel.gd:611-647`
  (`_refusal_text` for `laser`/`railgun`/`lancer` and the `0 NEEDED` instance row) passes
  unmodified — that shell has no profile in the tree, so `docked_station(null)` is empty.

## Files touched

- `vajb-orbit/ui/screens/station.gd` — `_entry_cost` routes through `StationRegistry.apply_price`;
  new `_station_standing(station)`; the `_entry` docstring split (entry vs price step).
- `vajb-orbit/tests/test_s24_world.gd` — one new row (`test_the_refusal_strip_prices_through_the_registry`)
  plus the `_digits_only` / `_refusal_cost` helpers it reads.

## Deviations from SLICE.md / the brief

- The brief's §7 file set for S24-F1 covers `vajb-orbit/tests/`; the new row lives in B1's
  suite (the wave's own A2 home) rather than a new file, so the wave adds no third suite.
- The added row moves the gate count by one. Bucket 2 (a pin) is untouched — no pinned number,
  no `VAJB_WORKER_FILES` set and no `docs/` text changed; the count is recorded here and in
  the close-out.

## Follow-ups

- F2 → ticketed as T-152; F3 → ticketed as T-153 (both already in `LOW_BACKLOG.md`, no new
  rows owed by this pass).
