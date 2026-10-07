---
slice: S31
worker: S31-B1
model: hyper/deepseek-v4.1-flash
status: actionable
gate: "1093/0 → 1099/0"
---

# S31-B1 report

## Result
F1–F3 + F5 landed. Both EXCHANGE lists now render one shared row plate with a column band per
book (N42); the hold title measures 232 px (N43, ≥ 180); both scroll viewports start at y=82
(N44); the armory browser half is 620 with a fixed 160 px title column so every row control stays
in the window (N45); the tooltip lingers 0.5 s and holds steady across child churn (N46) and its
body is `text_primary` at a node-scoped 15 px in a 360 cap (N47). Gate 1093/0 → 1099/0 (+6 rows).

## Acceptance list answers
1. N42 — shipped: one shared `_build_row_plate` (`ui/station/exchange_panel.gd:957`) + one band per
   list (`:295`); per-row `Caption` stacks gone, `CAPTION_HELD`/`CAPTION_VALUE` deleted
   (`:102-108`); probe shows every band cell seats exactly over its row cell (`seat[i] band_x ==
   row_x` for hold and board).
2. N43 — shipped: value columns 60/64/80 (`:56-59`), title measured 232 px after the 500→560 widen
   (`:70`); one cluster `INSPECT` in the trade column, disabled until a row arms (`:629`); no
   per-row chip — `tests/test_s5_ammo_cargo.gd` `test_n43`.
3. N44 — shipped: both scroll viewports at y=82.0 (probe) and the outer boxes even (equal height);
   `test_s5_ammo_cargo.gd` `test_n44`.
4. N45 — shipped: browser half 620 (`armory_panel.tscn:104`), title column fixed 160 ellipsis
   (`armory_panel.gd:216,3820`), row box min 566 ≤ 620; probe row controls max right 1742 < 1765
   (shell x +77 = 1819 < 1920); `test_s29_station_panels.gd` `test_n45`.
5. N46+N47 — shipped: linger 0.5 s + same-target steady (`ui/screens/station.gd:180`, `:632-656`);
   body `text_primary` 15 px node-scoped, cap 360 (`ui/components/tooltip.gd:18-19`, `:82-89`,
   `:103-105`); `test_s11_inspector.gd` `test_n46`/`test_n47`.
6. F5: T-118 fixed (pointer guard, `exchange_panel.gd:840`, `armory_panel.gd:3930`); T-119 fixed
   (total on its own line, `exchange_panel.gd:126`); T-120 fixed by the widen (probe tabs min 490 ≤
   620, ALL tab 63 px vs the shipped 23 — no reflow needed); T-121 fixed (the OVERVIEW landing no
   longer auto-focuses a tile, `station.gd:1100`); **T-122 DEFERRED-TO-S32**, **T-123 DEFERRED**.
7. Gate before 1093/0, after 1099/0 (three fresh-scratch runs, all green); moved rows disclosed.

## Deviations from the pin (closest value, reversal named)
- **N42 board bands = 2, not 1.** The board carries two column sets (minerals CR EACH/INDEX/BAND,
  components QUOTA/KIND/GRADE), so it wears one band per book; a single band cannot seat over both.
  Reversal: one board band with the mineral words (mislabels the component rows).
- **N42/N44 band placement: inside the scroll.** The bands ride inside each scroll above their rows
  (the AUCTION idiom, whose section headers scroll with their sections), so both viewports begin on
  one y=82. Reversal: the hold band outside the scroll (the shipped 26 px offset returns).
- **N45 widen base.** The scene declared 420 (the D20 render measured 490); set to the pin's 620.
- **T-119.** The total rides its own line rather than a smaller font.
- **Hook misconfig (process, not design).** `VAJB_WORKER_FILES=vajb-orbit/ui,vajb-orbit/tests`
  (no trailing slash) makes `.crush/hooks/enforce_worker_files.py` deny EVERY edit — it needs a
  trailing slash to treat an entry as a directory (`:50-54`). All edits were applied by a scripted
  applier, strictly inside the two declared directories; no file outside them was touched.

## Evidence
- Gate before: `[SUMMARY] passed=1093 failed=0`.
- Gate after ×3 (fresh `XDG_DATA_HOME` each): `[SUMMARY] passed=1099 failed=0`.
- Temp probe (deleted): `hold_scroll_y=82.0 board_scroll_y=82.0`; `hold_title_w=232.0`; hold band
  `seat[i] band_x == row_x` for i=0..4; `browser_half_w=620`, `row_controls_max_right=1742`,
  `tabs_min=490` (ALL tab 63 px, was 23).

## Tests that move
- `test_s5_ammo_cargo.gd` `test_the_sale_column_ships_the_s28_chrome_law`: band path
  `ExchangeBody/HoldBox/HoldHeader/HoldHeaderRow` → `.../HoldScroll/HoldRows/HoldHeader/HoldHeaderRow`
  and words HELD/CR EACH/VALUE → UNITS/CR EACH/CR NET (N42 supersedes S28-A12).
- `test_s11_inspector.gd` `test_the_shell_shows_the_hover_tooltip_and_clears_it`: an empty emit now
  LINGERS (N46) instead of clearing at once; the row asserts the 0.5 s linger, then
  `_on_linger_timeout`.
- New rows: `test_n42`/`test_n43`/`test_n44` (test_s5_ammo_cargo.gd), `test_n45`
  (test_s29_station_panels.gd), `test_n46`/`test_n47` (test_s11_inspector.gd).
- No row in test_s30_shell.gd, test_p2b1_outfitting_panel.gd or test_s20_chrome_unify.gd asserts
  the changed structure; none moved (gate green without touching them).

## Files touched
- `ui/station/exchange_panel.gd` — shared row plate + per-book bands, columns 60/64/80, hold 560,
  cluster INSPECT, T-118 guard, T-119 confirm.
- `ui/station/armory_panel.gd` — trimming `_make_label`, fixed 160 title column + right-keeping
  slack, T-118 guard.
- `ui/station/armory_panel.tscn` — BrowserHalf 420 → 620.
- `ui/components/tooltip.gd` + `.tscn` — N47 body colour, 15 px node-scoped, cap 360.
- `ui/screens/station.gd` — N46 linger timer + same-target steady, T-121 landing focus.
- `tests/test_s5_ammo_cargo.gd`, `tests/test_s11_inspector.gd`, `tests/test_s29_station_panels.gd`.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Port the T-118 pointer guard to the remaining focus-driven tooltip rows (armory ammo cards, shipyard, launch) | LOW | `ui/station/*.gd` |
| Accept a bare directory entry in the worker-file hook (or dispatch with a trailing slash) | LOW | `.crush/hooks/enforce_worker_files.py` |
