---
slice: S44
worker: S44-V0
model: hyper/glm-5.3-flash
status: informational
gate: "1351/0 → 1358/0"
---

# S44-V0 report

## Result
The EXCHANGE bulk sell ships per P53 mapped to the live tree: every hold row leads a
24×24 CheckChip (bare 1 px `metal_mid` frame unchecked, `metal_light` + a code-drawn
`text_primary` check mark checked — T-190), the `YOUR HOLD` band carries the MARK ALL /
CLEAR pair, the TradeBox carries the marked read under the ConfirmStrip, and the foot's
`ActionsRow` gains `SELL MARKED` (360×56) between the trio and `SELL`, selling every
marked stack through the shipped per-stack `sell()`. The single-sale arm, the foot trio's
seats and `game/exchange.gd` (read-only, untouched) are exactly as shipped. New suite
`tests/test_s44_exchange_bulk.gd`: 7 rows, all passing. Gate `--times 1`:
`[SUMMARY] passed=1351 failed=0` before → `[SUMMARY] passed=1358 failed=0` after
(1351 + the suite's 7; zero failures both ends, no SCRIPT ERROR lines).

## Acceptance list answers
1. — Every hold row leads the CheckChip: `Button` 24×24, `toggle_mode`, `FOCUS_NONE`,
   no text/icon (no font glyph, §5.8's tofu finding); unchecked = flat `StyleBoxFlat`,
   `draw_center=false`, 1 px `metal_mid` border; checked steps the border to
   `metal_light` and the `CheckMark` child (own rect, full-rect preset inset 5,
   A5.2(iii)) draws the polyline in `text_primary` —
   `exchange_panel.gd` `_make_check_chip`/`_style_check_chip`/`CheckMark` class
   (file end), built in `_build_hold_row`; pinned by suite row 1.
2. — The chip toggles the bulk set (`_on_check_toggled` → `_marked`), the row press
   keeps the shipped arm: `row.pressed` → `_on_row_pressed`/`_select` unchanged
   (stepper arms at 1, `CONFIRM_FORMAT` strip, SELL sells one unit — proven by a real
   press in suite row 2, credits and cargo measured).
3. — The `YOUR HOLD` band carries MARK ALL / CLEAR (`CaptionPair` `HBoxContainer`
   anchored inside the caption label, chips 96×32 with `ChromeFamily.apply_chip`,
   the P2 pair idiom); `_set_marked_all` flips every chip with no row rebuilt (suite
   row 3 asserts row identity survives, the A5.5 content-swap law); both disable on an
   empty hold.
4. — The read sits under `ConfirmStrip` (`%MarkedStrip`, `StationValue`, the T-119
   two-line cure), worded `MARKED <n STACKS> — GROSS <g> · FEE <f>` / `YOU GET <p>`
   with `_format_int` grouping; sums `_marked_quotes` = `_quote` per marked stack (its
   own held qty, market re-evaluated inside quote — no new pricing); empty set hides
   it — suite row 4 pins wording, sums and the hide.
5. — `SellMarkedButton` 360×56 `StationButton` sits in `PaneFoot/ActionsRow` between
   `CANCEL` and `SELL`; `exchange_panel.tscn:253-260` new, the three existing plates
   byte-identical (see Deviations); disabled at an empty set — suite row 5 pins the
   child order `SellAllButton, CancelButton, SellMarkedButton, SellButton`, sizes,
   variation and the disabled idiom.
6. — `_on_sell_marked_pressed` runs `_marked_ids()` in hold order, `sell(profile, id,
   held, now, null, quoted_gross_of_that_stack)` per stack (the shown-figure law per
   stack, CONTRACTS §21 M3); the first refused stack stops the run with
   `REFUSED · <STACK> · <§5.6 reason>` and the sold stacks stay sold; successes log
   through `Exchange._log_sale` (suite row 6 counts the economy log's own `SELL` lines)
   and one `SOLD MARKED · <n> STACKS · +<paid> CR` status line.
7. — No per-row SELL/INSPECT plate returns: `_build_hold_row` adds only the chip; the
   trade column's single INSPECT toggle keeps its seat (`_inspect_mode` untouched).
8. — Suite rows 1–6 map one-to-one onto items 1–6 (row 2 covers both the set toggle
   and the untouched arm); this report answers each with a cite.

## Deviations from SLICE.md
- **Seat mapping, disclosed (bucket 1, brief's own mapping):** the live foot order is
  `SELL ALL RAW · CANCEL · SELL` (`exchange_panel.tscn:201-223` pre-wave), so "between
  `SELL` and `SELL ALL RAW`" seats `SELL MARKED` immediately before `SELL` — the pin's
  own adjacency ("directly beneath `SELL`") honoured, the trio's seats untouched.
  Reversal: move the node one seat up (between `SELL ALL RAW` and `CANCEL`).
- **The caption band keeps N44's shape.** The first cut wrapped `HoldCaption` in an
  `HBoxContainer` — the full gate then failed S5's `test_n44_the_lists_start_on_one_y`
  (`test_s5_ammo_cargo.gd:713`, "the hold box is caption -> scroll", child 0 must be a
  `Label`), a pin outside this worker's file set. Cure: the caption label stays the
  hold box's leading child and the pair rides inside it (`CaptionPair`, anchors
  TOP_RIGHT, the band raised to 32 px via `custom_minimum_size`), which satisfies both
  pins. Reversal: the wrapper form (and re-point the S5 row in a later wave).
- **The marked read is two-line** (`... FEE <f>\nYOU GET <p>`), mirroring the shipped
  `CONFIRM_FORMAT`'s T-119 cure in the same 360 px box; the pin's wording tokens all
  ride, order preserved. Reversal: single line (it wraps mid-figure).
- **`_reason_text`'s head reused:** the marked refusal composes
  `"REFUSED · <name> · " + reason_text.trim_prefix("REFUSED · ")` so §5.6's wording is
  not duplicated (`REFUSED · GOLD INGOT · PICK AT LEAST ONE UNIT`). Reversal: name last.

## Evidence
- Suite alone: `--suite=test_s44_exchange_bulk` → `[SUMMARY] passed=7 failed=0`, exit 0.
- Full gate: `python3 staging/gate.py --times 1` → before `[SUMMARY] passed=1351
  failed=0`, after `[SUMMARY] passed=1358 failed=0` (first cut failed 1 — the S5 N44
  row above — cured before this run; no SCRIPT ERROR lines in either log).
- `staging/check_wiring.py` → "every hard reference resolves" (1561 hard refs).
- S44+S5 co-run → `[SUMMARY] passed=30 failed=0` (the collision regression pair).

## Files touched
- `vajb-orbit/ui/station/exchange_panel.gd` — the CheckChip/CheckMark build + styling,
  the marked set (`_marked`, `_marked_quotes`), the caption pair wiring, the marked
  read (`_refresh_marked`), the marked run (`_on_sell_marked_pressed`), band lead,
  prune/restore on rebuild.
- `vajb-orbit/ui/station/exchange_panel.tscn` — `CaptionPair` + the two chips inside
  `HoldCaption` (band 32 px), `MarkedStrip` under `ConfirmStrip`,
  `SellMarkedButton` in `ActionsRow`.
- `vajb-orbit/tests/test_s44_exchange_bulk.gd` — new, 7 rows.

## Follow-ups
None. (One observation, not owed: `_refresh_marked` re-quotes the marked stacks on
every trade refresh — the same per-row quote idiom `_refresh_hold` already ships, one
row per marked stack.)
