---
slice: S31
reviewer: S31-R1
model: hyper/glm-5.3-flash
subject: S31-B1
verdict: pass
---

# S31-R1 review — S31-shell-fixes (S31-B1)

## Re-measurement (independent, not the report's numbers)

- Gate ×2 on fresh scratch (`XDG_DATA_HOME=$(mktemp -d)`, `--quit-after 1200`): both runs
  `[SUMMARY] passed=1099 failed=0`. Baseline 1093/0 → 1099/0 confirmed.
- Probe `vajb-orbit/tests/probe_s31_review_shell.gd` (SceneTree script, mounts the real
  `station.tscn` under the shipped theme at 1920×1080, switches to the EXCHANGE and ARMORY
  panes, measures laid-out rects; left in place as evidence). All RESULT lines OK:
  - `n43_title_width hold_title_w=242.0 (>=180)` — hold TitleBox rendered width in-shell.
  - `n44_one_y hold_first_row_y=321.0 board_first_row_y=321.0 hold_scroll_y=296.0 board_scroll_y=296.0`
  - `n44_boxes_even hold_h=635.0 board_h=635.0` — the pin's 635 px exactly.
  - `n42_band_seats band_xs=[395,467,543] row_xs=[395,467,543]` — hold band cells seat
    exactly over the row's Qty/Unit/Total columns.
  - `n42_board_band_seats band_xs=[1186,1278,1350] row_xs=[1186,1278,1350]` — the mineral
    band seats exactly over the mineral row's Price/Demand/Trend columns.
  - `n43_cluster per_row_chip_absent=true cluster_present=true`.
  - `n43_exchange_widths hold=560.0 board=816.0 board_rows_w=804.0` — the board landed at
    the pin's own 816 px companion value; no column clips.
  - `n45_rows_in_window min_left=1225.0 max_right=1833.0 past_window=0 past_scroll_viewport=0`
    (scroll viewport right edge 1844; every browser-row control inside both).
  - `n45_title_column title_col=160.0 row_min=566.0` (566 ≤ 620).
  - `t120_tab_strip tabs_min=490.0 (<=620) tab_widths=[62,63,62,63,63,71,62,63,63]` — the
    ALL tab renders 63 px (its minimum is 23 px but the 620 strip expands it); T-120 cured.
  - `n46_linger_timer wait_time=0.500 one_shot=true`.
  - `n47_tooltip font=15 cap=360.0 body_primary=true hint_dim=true`.
- A5.5 sweep: read every hunk of the wave diff. Hover/focus/selection paths touch only
  `set_pressed_no_signal` (theme state), icon `modulate:a` tweens, `disabled` swaps and
  `inspect_requested` emits; the tooltip is popup-layer. No size, position or in-flow
  `visible` mutation was introduced; the §12.5 census stays cured. `_build_inspect_cluster`
  runs at build time, not on a state change. `_focus_active_panel`'s OVERVIEW early return
  (station.gd:1100) removes a `grab_focus`; it adds none.

## Acceptance list grades

1. **N42 — PASS.** One shared `_build_row_plate` serves both lists
   (`exchange_panel.gd:957`; called from `_build_board_row` and `_build_hold_row`); hold
   band rides inside its scroll (`:486`); per-row caption stacks deleted (`_make_value`
   returns the value Label alone); `CAPTION_HELD`/`CAPTION_VALUE` deleted. Deviation on
   band count disclosed (F1 below) and the bands measurably seat.
2. **N43 — PASS.** Columns 60/64/80 (`:56-58`); title 242 px measured ≥ 180; the 500→560
   widen is the pin's own remedy clause, correctly exercised; board at the pin's 816;
   cluster `INSPECT` in the trade column, `disabled` until a row arms
   (`:629-636`, `:668-669`); no per-row chip.
3. **N44 — PASS.** Both viewports begin on one y (321.0 = 321.0; scrolls 296.0 = 296.0);
   outer boxes even at 635 px = 635 px.
4. **N45 — PASS.** BrowserHalf 620 (`armory_panel.tscn:104`); fixed 160 px ellipsis title
   column with a right-keeping slack sibling (`armory_panel.gd:3815-3840`, trimming
   `_make_label` ported `:1675-1684`); every row control inside 1920×1080 and inside the
   scroll viewport.
5. **N46 + N47 — PASS.** Linger 0.5 s one-shot (`station.gd:180`, timer built `:388-394`);
   empty emit lingers, same-target payload cancels the linger and never re-arms the appear
   delay, different target re-arms (`:1137-1150`); body `text_primary` not bold, INSPECT
   hint stays `text_dim` (`tooltip.gd:103-108`); 15 px node-scoped via per-face font-size
   overrides (`:82-89`); cap 360 (`:18`, `.tscn` min 360).
6. **F5 — PASS.** T-118: `_pointer_over` guard on focus *and* press in both panels
   (`exchange_panel.gd:826-846,840-844`; `armory_panel.gd:3894-3933`). T-119: total on its
   own line (`exchange_panel.gd:126`). T-120: cured by the widen (tabs 62–71 px measured).
   T-121: OVERVIEW landing leaves focus unset (`station.gd:1098-1102`). T-122
   DEFERRED-TO-S32 and T-123 DEFERRED exactly as the brief assigns; LOW_BACKLOG untouched
   (close-out's job).
7. **Gate + disclosure — PASS.** 1099/0 reproduced twice. Moved rows verified in the diff:
   `test_the_sale_column_ships_the_s28_chrome_law` re-pathed to
   `HoldScroll/HoldRows/HoldHeader/HoldHeaderRow` with UNITS/CR EACH/CR NET;
   `test_the_shell_shows_the_hover_tooltip_and_clears_it` now asserts the linger then
   `_on_linger_timeout`. All six promised new rows landed (`test_n42/n43/n44` in
   test_s5_ammo_cargo.gd, `test_n45` in test_s29_station_panels.gd, `test_n46/n47` in
   test_s11_inspector.gd). Grep of test_s30_shell.gd, test_p2b1_outfitting_panel.gd and
   test_s20_chrome_unify.gd for the changed structures: no matches — the "none moved"
   claim holds. Change set confined to `vajb-orbit/ui` + `vajb-orbit/tests`.

## Pin table

| Pin | Grade | Basis |
|---|---|---|
| N42 | met (disclosed deviation) | shared plate + per-book bands; seating measured exact |
| N43 | met | 60/64/80, title 242 ≥ 180, cluster chip, board 816 |
| N44 | met | one y (321.0), boxes 635/635 |
| N45 | met | 620 half, 160 ellipsis column, rows in-window |
| N46 | met | 0.5 s linger, steady across child churn |
| N47 | met | text_primary body, 15 px node-scoped, 360 cap |

## Findings

- S31-B1/F1 — LOW — the board wears **two** column-header bands (one per book) where the
  pin's letter says one per list; a single band cannot seat over the two column sets, and
  the deviation is disclosed with its reversal (`exchange_panel.gd:359-371`); the mineral
  band measurably seats over its rows. No action; the reversal path is documented.
- S31-B1/F2 — LOW — the report's hold-title number (232 px) does not reproduce in the
  shell context (242 px measured); both clear the 180 px pin and the widen stays justified.
  No action.
- S31-B1/F3 — LOW — `VAJB_WORKER_FILES` directory entries without a trailing slash make
  the worker-file hook deny every edit (`.crush/hooks/enforce_worker_files.py:50-51`); the
  worker stayed inside its file set via a scripted applier. Process/tooling defect, not a
  design defect — carry to LOW_BACKLOG at close-out (the report's follow-up).
- S31-B1/F4 — LOW — the T-118 pointer guard ships on the exchange hold rows and the armory
  browser rows only; the remaining focus-driven tooltip sites (armory slot cells, shipyard,
  launch) still pop on keyboard focus, as the report's own follow-up states. Pre-existing
  scope, no S31 pin names them; LOW_BACKLOG candidate.

## Verdict

**Pass.** No HIGH or MED findings; S31-F1 is not dispatched. Per the brief's run order the
wave proceeds to close-out (gate ×2 already re-measured here, `verify --baseline s31_start`,
WAVEBOARD/MASTER_REPORT §6, wave-boundary commit), carrying F1–F4 as LOW backlog
candidates. Probe left for the fixer/record: `vajb-orbit/tests/probe_s31_review_shell.gd`
(log of the measured run: `RESULT`/`DIAG` lines on stdout, exit 0).
