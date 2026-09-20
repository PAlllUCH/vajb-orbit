# P1fix report — P1 review fixes applied

Scope: `.agents/gen/p1fix_task.md`, findings taken from `.agents/gen/p1r_report.md`. No MCP tool,
no editor run, console binary + `--headless` only. Files touched: exactly the ones named by the
task, plus the mandated throwaway probes (created, run, deleted) and this report.

## Applied

| Fix | File:line | What changed |
|---|---|---|
| F1 | `game/game.gd:16,97,217-232` | `ShipCatalog` preload, `_apply_ship_maxima()` called in `_ready()` before `_state.setup()`: `StationCatalog.ship(active_ship)` sets `hull_max`/`shield_max`/`cargo_max` when the row is non-empty and each value positive; unknown ship / missing profile keeps the `PlayerState` defaults silently. `_seed_vitals()` and `_file_damage_report()` untouched. |
| F2 | `game/exchange.gd:254-257` (`sell`), `292-295` (`sell_all`) | Re-read `profile.market()` immediately before the trade deltas and apply them to that fresh copy; the emit order (verify → take → pay → market → log) and the quote-time pricing are unchanged. In `sell_all` the fresh copy is also what the next line quotes against, so a later line no longer prices off pre-sale stock. |
| F3 | `ui/station/repairs_panel.gd:57,72,82,210-215` | `FOOTER_FORMAT` built at runtime from `Repairs.HULL_CR_PER_POINTS` / `SHIELD_CR_PER_POINTS`; `%PaneFooter` is now an owned node. The `.tscn` literal stays as the pre-`_ready` default (not in the allowed file list). |
| F4 | `ui/station/exchange_panel.gd:109,325-328,363-367`; `game/exchange.gd:86-89` | Mineral board rows keep their meta label and refresh it to `<baseline> CR · <demand>x` (`Exchange.baseline_of` on the row's ingot id, `Exchange.demand_of`); `PRICE` stays the net unit price. `unit_gross`'s comment now states it is the 05 §2 gross helper kept for the pricing family and tests. |
| F5 | `ui/station/refinery_panel.gd:151-163`, `ui/station/exchange_panel.gd:189-197` | REFINE ALL fallback now checks `.disabled`; the exchange's `focus_primary` already checked rows and SELL ALL (comment added to name the contract). Nothing grabs when nothing enabled can, so the shell's rail fallback runs. |
| F6 | `autoload/world_clock.gd:38`, `game/refinery.gd:55` | `@warning_ignore("integer_division")` at the two deliberate int/int divisions. No other site was annotated. |
| F7 | `tests/test_p1_profile.gd:58-91` | The fresh-defaults test now calls `reload()` on a file-less profile and asserts STATION_SPEC §2.8: 10000 CR, one owned ship `ship_vanguard`, active `ship_vanguard`, empty upgrades, empty cargo, 300 rounds for each of the five `AMMO_MAX` weapons, plus the P1 keys at their defaults. |
| F8 | `game/mineral_catalog.gd:5-12,31-260` (40 paths), `ui/station/refinery_panel.gd:86-90,393-407`, `ui/station/exchange_panel.gd:70,325,454,844-875`, `tests/test_p1_catalogues.gd:148-171` | Every `icon_ore` → `icon_mineral_<id>_48.png`, every `icon_ingot` → `icon_ingot_<id>_48.png`; the catalogue header records §8.1's "retire the 02 §6 fallback" and keeps `TIER_TINTS` as the absent-glyph fallback. Both panels draw a dedicated glyph untinted and reserve the `tint/` stencil + tier tint for the generic fallback; components keep `GRADE_TINTS`; the board prices the ingot (`icon_ingot`). New catalogue test asserts both paths and `ResourceLoader.exists` for all 40. |

F8 detail worth knowing: `tools/derive_icon_tints.gd` writes a `tint/` stencil for **every** icon,
dedicated family included (20 ore + 20 ingot stencils exist), so stencil existence cannot tell the
two families apart. The panels therefore detect a dedicated glyph by its file-name prefix
(`icon_mineral_` / `icon_ingot_`), which is the naming ICONS_SPEC §8.1 fixes.

## Evidence

- Gate: `[SUMMARY] passed=53 failed=0`, exit 0, no `SCRIPT ERROR`. The only stderr noise is the
  deliberate `EconomyLog: could not open user://p1l_missing_dir_do_not_create/...` warning from
  `test_p1_clock_log.gd:test_unwritable_log_path_is_survivable`.
- Boots (`--quit-after 300`): `res://ui/screens/station.tscn` exit 0 and `res://game/game.tscn`
  exit 0, neither with a `SCRIPT ERROR`. The station run also prints the known pre-existing
  `4 ObjectDB instances were leaked` / `2 resources still in use`, traced by
  `.agents/gen/leak_verbose.log` to the station ambience `amb_station_room_01.ogg`.
- F1 probe (deleted): `[PROBE-SUMMARY] passed=25 failed=0` — vanguard 1000/600/40, fighter
  700/400/25, an over-max vitals record clamped to 700/400, an under-max record kept at 300/120,
  and an id the catalogue does not know falling back to the defaults.
- F4/F8.2 probe (deleted): `[PROBE-SUMMARY] passed=10 failed=0` — board meta `65 CR · 1.0x` with
  `PRICE` `64`, board and hold icons `icon_ingot_iron_48.png` / `icon_mineral_iron_48.png` at ink
  `(1,1,1,0.72)`, refinery row the same, and `comp_scrap_1` keeping the grade tint
  `(0.3373,0.3608,0.3882,0.72)` on the `tint/` stencil.
- F2 regression test is real: with `state = profile.market()` removed from `sell`, the suite fails
  with "the re-entrant evaluation's stamp survives the sale" (12/13); restored, 13/13.
- No suite touched `user://profile.cfg` or `user://economy_log.txt` (no `economy_log.txt` exists at
  all). The owner's `profile.cfg` is intact and is not the probe fixture (credits 600, upgrades
  installed, a drifted book): its `last_band` advanced from P1i's 1789727439 to 1789730287 because
  the required station boot entry evaluates the market, which is documented station-entry behaviour.
  The probes' own `user://test_p1fix_probe.cfg` was deleted.

## Not fixed (out of the task's list)

p1r findings 2 (7 hex literals in game code), 6/7/8/9 (05 §2 aside, 04 §5 ratio, 05 §8 API names,
05 §2 "real time") and 10 (rail LOG OUT confirm), 11 (delete the `_mockup_station` pair), 15
(refinery empty-state footer vs §5.7) are doc-only or outside the named files, so the task's hard
rule left them alone. 17 is a reachability note, not a defect. Nothing in F1-F8 was skipped.

## For the re-reviewer

1. `game.gd` now takes maxima from the active hull while `Repairs.fee` takes them from
   `StationCatalog` independently; both read the same row, so they agree by construction, but a
   future installed-module effect on `hull_max` would have to be applied in both places.
2. In `sell_all`, each line's deltas now land on, and the next line prices against, the market as
   consumed by the earlier lines (before: one pre-sale snapshot). Bulk surplus quota can no longer
   oversell. The demand base inside `_apply_trade` is still the quote-time `result[&"demand"]`,
   which is what the task specified.
3. F4 deliberately duplicates demand on a mineral row (meta `65 CR · 1.0x` beside the INDEX cell
   `1.0x`); that is 05 §2's "current price next to the baseline" read literally. If the duplicate
   is unwanted, dropping the INDEX cell needs a STATION_HUB §5.8 amendment, not a code edit.
4. F8's family test is a file-name prefix. A dedicated glyph shipped under another name (or a
   generic name reused for a mineral) would be tinted again; the prefix lists in both panels and
   the catalogue header are the single place to change. `ui/screens/station.gd:73` and
   `ui/hud/hud.gd:36-38` still hardcode generic `tint/icon_cargo_*` stencils by design (outside the
   F8 scope) and still resolve.
5. F3 leaves the literal in `repairs_panel.tscn:119` as the pre-`_ready` default; the runtime
   caption is now the constants' owner. Removing the scene copy would be a `.tscn` edit the task
   did not allow.
6. `world_clock.gd` / `refinery.gd` annotations are placed directly above the returning statement;
   a Godot reformat must keep that adjacency or the warning returns.
