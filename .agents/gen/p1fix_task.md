# P1fix task — apply the P1 review fixes (report `.agents/gen/p1r_report.md`)

Worker: coder. Wave: P1 economy core, fix pass. Re-read
`.agents/gen/p1r_report.md` (the reviewer's findings) and the files named
below, then apply exactly these fixes. Do not redesign, do not refactor
beyond the listed items. Do not use MCP tools. Do not run the editor. Always
use the console binary with `--headless` (NEVER the GUI binary; a previous
worker hung that way).

## F1 (major) — ship maxima in `game/game.gd`

`PlayerState` pools currently stay the Vanguard's for every hull. In
`_ready()`, before `_state.setup()`: resolve
`StationCatalog.ship(profile.active_ship())` and, when the row is non-empty
and its `hull` / `shield` / `cargo` are positive, set `_state.hull_max`,
`_state.shield_max`, `_state.cargo_max` from it. Unknown ship or missing
profile -> keep today's defaults, no warning needed. `_seed_vitals()` then
clamps against the real maxima as it already does. `_file_damage_report()`
keeps filing `int(_state.hull)` / `int(_state.shield)` (already clamped by
`set_hull`/`set_shield`).

Probe (redirect the autoload profile's `save_path` first): with the active
ship `ship_fighter`, instantiating `res://game/game.tscn` under a probe node
yields `hull_max == 700`, `shield_max == 400`, `cargo_max == 25`; with the
default `ship_vanguard` it yields 1000 / 600 / 40; a seeded `vitals` record
is clamped to the real maxima. Delete the probe when done.

## F2 (minor) — exchange re-entrancy (`game/exchange.gd`)

`sell` (and the inner path used by `sell_all`) stash `profile.market()`, then
emit `profile_changed` from `remove_cargo`/`add_credits`; a re-entrant
listener that calls `Exchange.quote` can mint a newer market snapshot, which
the outer call then overwrites. Fix: re-read `profile.market()` immediately
before applying the trade deltas and applying `set_market` (apply the deltas
to the FRESH copy); pricing still uses the values read at quote time. Keep
the transaction order (verify -> take -> pay -> log) untouched.

Regression test in `tests/test_p1_market.gd`: connect a listener to the
profile's `profile_changed` that calls `Exch.quote(...)` re-entrantly during
a 10-unit mineral sale; assert the stored demand afterwards is exactly the
pre-sale demand minus 0.10 and credits/cargo match the quote.

## F3 — repairs footer (`ui/station/repairs_panel.gd`)

Build the footer caption from `Repairs.HULL_CR_PER_POINTS` /
`Repairs.SHIELD_CR_PER_POINTS` at runtime instead of literal copy.

## F4 — baseline on the board (`ui/station/exchange_panel.gd`)

Per 05 §2 ("the current price next to the baseline"): the mineral board row's
meta caption shows `<baseline> CR · <demand>x` (baseline via
`Exchange.baseline_of` on the row's ingot id, demand via
`Exchange.demand_of`); `PRICE` stays the net unit price. Update the
`unit_gross` header comment in `exchange.gd` to say it is the 05 §2 gross
helper kept for the pricing family and tests (not dead code; the board shows
baseline and demand separately).

## F5 — focus on disabled controls

`focus_primary()` must not leave the ring on a disabled button. Check
`.disabled` before `grab_focus()` in: `refinery_panel.gd` (the REFINE ALL
fallback branch), `exchange_panel.gd` (the SELL ALL RAW fallback), and
`repairs_panel.gd` (REPAIR). If nothing enabled can take focus, return
without grabbing so the shell's rail fallback runs.

## F6 — integer-division warnings

Add `@warning_ignore("integer_division")` at the deliberate int/int divisions
that trip the warning: `autoload/world_clock.gd` (`bands_between`) and
`game/refinery.gd` (the conversion math, where the warning fires). Only where
it actually fires.

## F7 — profile test gap (`tests/test_p1_profile.gd`)

The fresh-defaults test asserts an uninitialised instance's field defaults.
Call `reload()` on a fresh instance whose file does not exist and assert
STATION_SPEC §2.8: credits 10000, owned ships `[ship_vanguard]`, active
`ship_vanguard`, ammo 300 for each of the five weapons, cargo empty, plus
the new keys at defaults.

## F8 — wire the Phase F mineral icons (data edit, sanctioned by ICONS_SPEC §8.1)

The dedicated glyphs are now in the project (all 20 + 20 verified on disk):
`res://assets/icons/icon_mineral_<id>_48.png` and
`res://assets/icons/icon_ingot_<id>_48.png` (`<id>` = the catalogue base id,
`krilium` included).

1. `game/mineral_catalog.gd`: point every `icon_ore` at
   `icon_mineral_<id>_48.png` and every `icon_ingot` at
   `icon_ingot_<id>_48.png`. Update the header comment: ICONS_SPEC §8.1
   "retire the 02 §6 fallback"; `TIER_TINTS` stays as the fallback for a
   mineral whose dedicated glyph is ever absent (and is no longer applied to
   dedicated glyphs).
2. `ui/station/refinery_panel.gd` and `ui/station/exchange_panel.gd`:
   dedicated glyphs render **untinted** (they are per-mineral art); keep the
   tier-tint path only for the generic stencil fallback (refinery already
   branches this way; make the exchange's hold and board rows branch the
   same). Exchange board rows use the row's `icon_ingot` (the board publishes
   the ingot price). Component icons keep `GRADE_TINTS` (no component glyphs
   exist yet). No other panel change.
3. `tests/test_p1_catalogues.gd`: update icon assertions to the new paths and
   assert `ResourceLoader.exists` for all 40 (adjust whatever it asserts
   today; keep the component icon assertions unchanged).

## Hard rules

- Only touch the files named above (plus this fix's report).
- Re-run the full gate when done:
  `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200`
  -> `[SUMMARY] passed=<all> failed=0`, exit 0, no `SCRIPT ERROR`.
- Also boot `res://ui/screens/station.tscn` and `res://game/game.tscn`
  headless (`--quit-after 300`): exit 0, no `SCRIPT ERROR` (proves the new
  icon paths load).
- Suites must never touch `user://profile.cfg` or `user://economy_log.txt`.

## Report

Write `.agents/gen/p1fix_report.md`: per-fix file:line summary, the gate
output line, the two boot runs, which findings you did NOT fix and why
(if any), and anything a re-reviewer should check. Under 120 lines.
