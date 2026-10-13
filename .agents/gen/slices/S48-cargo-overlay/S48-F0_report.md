---
slice: S48
worker: S48-F0
model: hyper/glm-5.3-flash
status: informational
gate: "1404/0 → 1409/0"
---

# S48-F0 report

## Result
A7's flight half is landed from `S48-V0_game_gd_patch.md` exactly: the layer-20
host, the one-driver poll rewrite, the ESC ladder's topmost step and the mirror
writer in `vajb-orbit/game/game.gd` (hunks 1–6, verbatim), plus the suite's five
flight rows in `tests/test_s48_cargo_overlay.gd`. Suite alone 13/13 (8 station +
5 flight); gate `python3 staging/gate.py --times 2` → `[SUMMARY] passed=1409
failed=0`, byte-identical across both runs (baseline 1404/0; the delta is the
five new rows).

## Acceptance list answers (the flight item, A7 item 6, plus the suite item 7)
6 — DONE — the seat is the game scene's own `CanvasLayer` at
    `GameScript.OVERLAY_LAYER` = 20 (`game.gd:54`, built by `_build_cargo_overlay`,
    `game.gd:2530-2541`), above the HUD's own layer 10 (`hud.tscn:35`), the
    overlay a child of that host, not of the HUD — pinned by
    `test_the_flight_seat_is_the_layer20_host_above_the_hud`.
    The poll (`game.gd:1704-1707`) is the one driver through `_set_cargo_open`
    (`game.gd:1712-1721`), which mirrors `_cargo_open` and drives the HUD's frozen
    setter (its panel stays latched hidden, `hud.gd:2229-2235`) — pinned by
    `test_the_poll_drives_the_overlay_and_the_mirror_stays_in_step` (open/closed
    beats, both mirrors, retired panel hidden, `CargoBlock` visible).
    ESC is the one topmost step before the map-deck step
    (`game.gd:1046-1050`) — pinned by
    `test_esc_closes_the_overlay_before_the_map_deck_step` (overlay closed,
    `map_deck_open()` still false). Nothing pauses — pinned by
    `test_the_overlay_pauses_nothing_in_flight` (`get_tree().paused` false, read
    off `Engine.get_main_loop()`, since the suite base is not a Node).
    The rows: the same overlay reads the same fixture hold and packs in flight
    (`LASER MKII · 120 ROUNDS` …) with the same title — pinned by
    `test_the_flight_overlay_reads_the_fixture_rows`.
7 — DONE — `tests/test_s48_cargo_overlay.gd` now pins items 1–6: 13 rows, all
    passing; the five flight rows drive the polls directly per the patch.

## Deviations from the patch
- Bucket-1 (test mechanics, mine): the flight rows press/call/release through a
  `_poll_cargo()` beat helper, and `setup()` normalizes entry state
  (`_settle_cargo`, `test_s48_cargo_overlay.gd:129,157-172`): a row that leaves
  the overlay open (the rows-row does) would otherwise make the next row's first
  press toggle it closed — measured as the one suite failure before the fix.
  Reversal: inline the press/call/release beats and order the rows by hand.
- Bucket-1: the HUD's `CargoBlock` is built in code (`hud.gd:1385-1412`) and
  carries no unique name, so the pin reaches it by path
  `CanvasLayer/TopLeft/Blocks/CargoBlock` instead of the patch's `%CargoBlock`
  shorthand; the asserted fact is the patch's (the block visible and untouched).
- None else: hunks 1–6 landed verbatim; no comment, number or name rewritten.

## Evidence
- Suite alone: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn ++ --suite=test_s48_cargo_overlay` →
  `[SUMMARY] passed=13 failed=0`.
- Gate: `python3 staging/gate.py --times 2` → run 1 and run 2 both
  `[SUMMARY] passed=1409 failed=0`, byte-identical; no SCRIPT ERROR lines.
- First suite run measured the ordering hazard above
  (`[FAIL] ... test_the_overlay_pauses_nothing_in_flight: the overlay is up`),
  fixed by the settle; the re-run is the 13/13 above.

## Files touched
- `vajb-orbit/game/game.gd` — hunks 1–6: the preload + `OVERLAY_LAYER` const, the
  seat vars, the `_ready` build call, the poll/`_set_cargo_open`/`_sync_cargo_overlay`
  rewrite, the ESC topmost step, `_build_cargo_overlay` beside `_on_cargo_toggled`.
- `vajb-orbit/tests/test_s48_cargo_overlay.gd` — the five flight rows, the game
  mount (once in `suite_setup`, freed in `suite_teardown`), the beat/settle
  helpers, the header comment amended to the landed state.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| None — the slice's A7–A9 list is fully landed and pinned; the review wave (R0) grades the complete deliverable next | — | — |
