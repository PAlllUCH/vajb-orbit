---
slice: S44
reviewer: S44-R0
verdict: passed-with-followups
gate: "1351/0 → 1358/0 (re-run matches the tree: 1358/0)"
---

# S44-R0 review

Read in the brief's order: the V0 brief's acceptance list first, the pinned law
(STATION_HUB §23.7/§5.8/§5.6, UI_SPEC §3.10 A5.1–A5.5, §16.1, §13.1 N44), the
report, then the three deliverables and the read-only seam. One live probe was
run for the two numbers the gate is blind to (N44's one-y; the row title's N43
floor); it mounted the shipped panel on a scratch store at 1920×1080 and read
the tree's own geometry (`[S44R0]` lines below).

## Acceptance list

1 — pass — suite row 1 (`test_s44_exchange_bulk.gd:120-158`): the chip is the row box's
    first child, 24×24, `toggle_mode`, `FOCUS_NONE`, no text and no icon (no font glyph,
    §5.8's tofu finding); unchecked = flat box, `draw_center=false`, 1 px `metal_mid`;
    checked steps the frame to `metal_light` and back; the `CheckMark` child (offset_left
    5, `anchor_right` 1, `MOUSE_FILTER_IGNORE`) carries `_token(&"text_primary")` (T-190)
    and draws nothing unchecked — `exchange_panel.gd:1277-1310` (`_make_check_chip`,
    `_style_check_chip`), the polyline at `:1573-1585`, wired in `_build_hold_row`
    `:616-627`. State rides frame + mark, never colour alone.
2 — pass — suite row 2 (`:164-204`): the chip toggle moves `_marked` both ways; the row
    press arms INGOT at one unit, the confirm strip reads `SELL 1 GOLD INGOT …`, a real
    SELL press pays credits and takes exactly one unit, and neither the set nor the chip
    moved. The single-sale arm's code has no hunks (`_select`, `_on_sell_pressed`,
    `_set_sell_units`, the stepper consts are untouched in the diff); SELL ALL RAW's
    raw-only law and CANCEL are equally untouched.
3 — pass — suite row 3 (`:210-271`): the pair rides inside the caption Label, which stays
    the hold box's leading child (N44's caption→scroll shape), 96×32 chips wearing C3 chip
    chrome; MARK ALL marks 3/3 and CLEAR empties with row count and row identity asserted
    — no rebuild, no reflow (A5.5 content-swap law); both disable on an empty hold.
4 — pass — suite row 4 (`:277-303`) + probe: the read sits under the ConfirmStrip
    (`exchange_panel.tscn:206-210`), worded `MARKED 2 STACKS — GROSS … · FEE …` /
    `YOU GET …` with the shipped grouped digits, summed from `_quote` per marked stack
    (each its own held qty; the market re-evaluates inside `Exchange.quote`, the one price
    read); an empty set hides it. The two-line form is the disclosed T-119 cure the same
    360 px box already ships for `CONFIRM_FORMAT`; the pin's tokens all ride in order.
5 — pass — suite row 5 (`:309-337`): child order `SellAllButton, CancelButton,
    SellMarkedButton, SellButton`, every plate 360×56 `StationButton`, separation 16;
    disabled at an empty set, wakes on a mark (A5.4-2's idiom). The trio's tscn nodes are
    byte-identical (the diff only adds the new node); measured x: 0 / 376 / 752 / 1128 —
    SELL ALL RAW and CANCEL keep their exact derived seats, SELL's derived seat shifts
    +376 because the row gains a sibling ahead of it (owned by the disclosed mapping;
    4×360 + 3×16 = 1 488 ≤ 1 765, §19.3's foot band).
6 — pass — suite rows 6–7 (`:343-399`): the press pays exactly the read's summed figures
    through the shipped per-stack `sell()` with the shown-figure override (the same idiom
    `_on_sell_pressed` ships, `exchange_panel.gd:999-1001` vs `:901-903`), cargo zeroes,
    one `SOLD MARKED · 3 STACKS · +… CR` line, the economy log carries all three stacks'
    `SELL` lines; the refused run stops at the ingot with `REFUSED · GOLD INGOT · PICK AT
    LEAST ONE UNIT` on the danger strip (§5.6's `_deny` cue + pulse, `:1070-1075`), the
    sold stack stays sold, the unrun stack keeps its mark.
7 — pass — the diff adds only the CheckChip to the row build; no per-row SELL/INSPECT
    plate returns; the trade column's single INSPECT toggle keeps its seat (`_inspect_*`
    has no hunks).
8 — pass — the suite's 7 rows map onto items 1–6 (row 2 covers item 2's two halves, row 7
    the refusal half of item 6), and every report answer carries a cite.

## The disclosed seat mapping (brief context 1)

Faithful, on the three asks: (a) foot trio untouched — the tscn trio nodes are
byte-identical, sizes and the 16 px gutter unchanged, SELL ALL RAW/CANCEL keep their
exact seats, and SELL's +376 derived-seat shift is the container's unavoidable response
to an inserted sibling, which the mapping itself declared with its arithmetic; (b) SELL
MARKED is a 56 px secondary (360×56 `StationButton`, the §5.8 secondary height), seated
immediately before SELL — the pin's "directly beneath `SELL`" adjacency rendered in the
horizontal row, the one-seat-up alternative recorded as the reversal; (c) the marked
read is in the TradeBox under the ConfirmStrip. Bucket 1 as filed; no pin edit needed.

## The caption-band re-seat (N44/S5 coherence)

Half-true — F1. The structural half holds: the caption Label stays the hold box's leading
child (S5's `test_n44_the_lists_start_on_one_y` shape rows pass; the pair rides inside
it, anchored TOP_RIGHT). But the re-seat raises only the hold band: a bare `SectionHeader`
measures 21 px natural, the hold caption is forced to 32, and the live scrolls diverge —
`HoldScroll y=40.0 h=194.0 | BoardScroll y=29.0 h=205.0` (probe on the shipped theme).
Pre-wave both captions sat at 21, so the wave introduced the 11 px drift; N44's "both
lists' scroll viewports begin on one y" is broken by the very delta that pin closed. The
report's "satisfies both pins" claim is true only where the S5 row can see.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | exchange_panel.tscn:62-67 vs :114-117 | N44's one-y broken by 11 px: `HoldCaption` gains `custom_minimum_size (0, 32)` while `BoardCaption` keeps its 21 px natural height (HoldScroll y=40 vs BoardScroll y=29, probe). The 32 px band is required — the 32 px ActionInline pair cannot seat in a 21 px band — so the cure is to raise `BoardCaption` to the same min (the stacks become identical again, one-y restores); centre the caption text in the taller band while there | fixer pass (same file set) |
| F2 | LOW | tests/test_s5_ammo_cargo.gd:702-728 | The S5 N44 row pins the stacks' shape, not the y's — an 11 px viewport drift ships green (this wave is the proof). Strengthen the row to assert both scrolls' y equality; outside this wave's file set | → ticketed `T-196`, not fixed here |
| F3 | LOW | exchange_panel.gd:824-831 (`_refresh_marked`) | The empty-set hide toggles an in-flow node's `visible` on a selection state — N24's letter. Measured blast radius: the only sibling below is the empty `TradeTail` spacer (tscn:213-215), nothing content-bearing reflows, and the brief's own item 4 pinned the hide; record the reserved-slot carve-out (or keep the strip present with empty text) | → ticketed `T-197`, not fixed here |

Also verified, no finding: the band's `CheckGap` lead (36 = chip 24 + separation 12,
`exchange_panel.gd:349-356`) mirrors the row's own lead, so N42's captions stay seated
over their value columns; the N43 title floor holds with the new lead (measured row title
width 196 ≥ 180; the 560 px hold content width is the pin's own remedy, `:76-77,225`); no
cached total survives a refresh (`_marked_quotes` is cleared and re-quoted on every
`_refresh_marked`, and every `_rebuild_hold` call site is followed by `_refresh_trade`
within the same call — `:228-233, :252-257, :1060-1062`); no new pricing path (the read
and the press only sum/pass `Exchange.quote` outputs); no coordinates beyond the
sanctioned anchors + min sizes, no new hex (token reads only).

## Verified fixes

None yet — first review. F1 goes to the fixer pass; F2/F3 go to `LOW_BACKLOG`.

## Gate

- Tree at review: `[SUMMARY] passed=1358 failed=0` (`python3 staging/gate.py --times 1`,
  exit 0, zero SCRIPT ERROR lines) — matches the report's after-count; 1351 + the suite's
  7 rows holds. No moved-premise failures appeared, so the brief's re-cut note had
  nothing to grade.
- Negative control: the probe's unseeded runs read `hold payloads=0` with no rows built —
  the measurements above are the live tree's own state, not fixture echoes; the probe
  also reproduced the read end-to-end (`MARKED 1 STACK — GROSS 432 · FEE 10 | YOU GET
  422`, quotes keyed `[&"mineral_iron"]`).
- File-set law: `git diff --name-only` on code names exactly the brief's three files (the
  two brief-file edits are the developer's own task-note/failsafe paperwork, not worker
  code); `git diff --stat vajb-orbit/game/exchange.gd` is empty — the read-only seam held.
