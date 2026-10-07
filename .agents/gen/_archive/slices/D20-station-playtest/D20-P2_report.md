---
slice: D20
worker: D20-P2
model: Crush (GLM)
status: informational
gate: n/a (playtest review; in-game observations only)
---

# D20-P2 report — in-game station playtest

Date 2026-10-04. Visual review (inline screenshots seen). Route actually run: boot → MAIN MENU →
station OVERVIEW (dock) → hover tooltip on tiles → EXCHANGE → ARMORY → TERMINAL drawer → AUCTION.
Game window 1920×1080 at desktop pos (793,196); all rects below are real pixels from
`get_ui_elements`. Limitation: `game_eval` only answered inside the first seconds after launch —
the idle game loop stalls when the window is unfocused (Wayland frame throttling), so pane
switching used rect-centre clicks and all numeric reads came from `get_ui_elements`; the
hover-delay number is code-read, not stopwatched in-game.

## Result

The shell-v2 layout holds up at 1920×1080: boot, menu, overview, terminal drawer and auction are
clean. Two HIGH player-visible faults: the exchange hold column truncates every row title to a
~28 px column, and the armory browser rows overflow their 478 px viewport with INSPECT chips
landing past the window edge. The owner's exchange/armory rework requests both measure out to
layout-minimum-width bugs, not restyle opinions.

## 1 EXCHANGE — board vs hold (owner note 1)

- HIGH - hold row titles truncated to a 28 px column ("RO…", "MIN…", "FLA…" seen at 1152) while board titles get 517 px - `TitleBox` rect 28×44 on every hold row (get_ui_elements); board `TitleBox` 517×44; cause: HOLD_CONTENT_WIDTH=500 cannot fit icon 40 + title + qty 70 + unit 80 + total 100 + INSPECT chip 96 + 5×12 separations + 24 margins, so the expand-fill title is starved - vajb-orbit/ui/station/exchange_panel.gd:68, exchange_panel.gd:539-553.
- MED - hold header band sits ~109 px right of the row value columns it captions (HeaderHeld x290 vs row Qty x181; same offset on all three columns) - the header's TitleGap is an expand-fill guess (138 px) that ignores the row's trailing INSPECT chip; same root cause as the truncation - vajb-orbit/ui/station/exchange_panel.gd:293-325.
- MED - hold and board are not "even": HoldScroll viewport y322..902 (580 tall) vs BoardScroll y296..902 (606) — the hold's list starts 26 px lower (its extra code-built header band + 8 px separation) while both bottoms align at 902 - rects from get_ui_elements; boxes built at exchange_panel.tscn:56-100, header inserted at exchange_panel.gd:323-325.
- LOW - double captioning: the hold carries a header band (HELD / CR EACH / VALUE) AND per-row caption stacks (UNITS / CR EACH / CR NET), with a vocabulary mismatch (HELD vs UNITS); the board has only per-row stacks - exchange_panel.gd:316-322, :539-541.
- LOW - ConfirmStrip wraps mid-value ("YOU GET" / "24" splits across lines) in the 360 px SALE column - exchange_panel.tscn:148-152 (autowrap), seen at 1152.
- What makes the board the owner's favourite: every row is one 76 px plate with icon + name + meta line + three value-over-caption stacks, 42 rows in a smooth scroll; the hold copies that row idiom but starves its title and adds a redundant, misaligned header on top.

## 2 ARMORY — overflow + module inventory (owner note 2)

- HIGH - "MODULES · OWNED & BUYABLE" rows overflow their viewport at rest (on open, no hover or scroll needed): BrowserScroll viewport is 478 px wide but each row's RowInner minimum is 542-620 px; on long-name rows the trailing INSPECT chip lands past the window edge (PROTON MISSILE LAUNCHER chip x1867..1963 and STATION VAULT ACCESS x1837..1933 on a 1920 window; TARGETING COMPUTER x1827..1923) — unreachable controls - rects from get_ui_elements; cause: `_make_label` (armory_panel.gd:1673-1678) has no ellipsis trim, so the row title at :3816 takes its full text width as minimum (exchange's `_make_label` trims, exchange_panel.gd:954-965).
- MED - the browser half is only 490 px of a 1768 px pane (Split 1262/490) while its rows need ~620 — the split starves the list the overflow lives in - armory_panel.tscn Split/BrowserHalf, rects above.
- LOW - family tab strip crams 8 tabs into 490 px (ALL tab is 23 px, UTILITY 42 px) - tabs at x1354..1815, get_ui_elements.
- Module (a) "select a cell → what it is → what I have that fits → select/drag fit": exists today as SlotCaption "SLOT LAYOUT · 23 CELLS · 3 ENGINES" grid + SelectionLine ("W1 · PLASMA COIL · OWNED ×0") + Rack1..Rack5 panels (260×192, cells EMPTY/READY) + BARREL INVENTORY (648×220 scroll) + AMMUNITION (648×220 scroll) + footer PWR 3/19 · FITTED 3/19 with INSPECT / REMOVE / BUY & FIT SELECTED; drag-to-fit and right-click-to-pull are live (hint line; DRAG_BROWSER at armory_panel.gd:262).
- Module (b) "battery configurations from fitted weapons": the R1..R5 racks ARE the batteries — battery = the identical weapon instances fitted across W cells, grouped, one trigger fires all (docs/gameplay/09_ship_slots_modules.md L555-581; hardcap BATTERY_CELLS_MAX=4 §12 L673-746); `battery_groups` derives B1..B5 in weapon_1..5 order (armory_panel.gd:1935-1948, :2011, :2557). No separate configuration module exists — the pieces (racks, PWR meter, per-row DRAW 0-3 counters) are present but merged into the one screen the owner wants split in two.

## 3 HOVER INSPECT — timing + legibility (owner note 3)

- Delay until the popup: TOOLTIP_DELAY = 0.25 s (vajb-orbit/ui/screens/station.gd:177), one-shot Timer created at :378-383 and restarted per hover target at :1095-1096; x2 touches one constant read at three sites (177, 381, 1096) → 0.5 s.
- How long it stays: no auto-hide — visible until mouse exit or pane switch (clear at station.gd:609-615, :1101-1104); visually confirmed persisting across frames on the OVERVIEW tile hover.
- Legibility: tooltip body renders at the theme's RichTextLabel 13 px (bold included; vajb-orbit/ui/theme/vajb_theme.tres:469-473) inside a 320 px cap (tooltip.gd:17 CAP_WIDTH, cursor offset (12,12), 8 px viewport clamp :18-19) with dim-grey body colour — unreadable at 640, small at 1152. Clearer = RichTextLabel font 13→15/16 and/or cap 320→360+.
- In-game timing verification NOT performed: game_eval was unavailable outside the launch window (unfocused-loop stall, see header); appearance verified visually, delay verified by code read only.

## 4 TERMINAL + AUCTION (owner notes 4-5) — verified, and why they work

- TERMINAL works: plate measures 362 px (DRAWER_SLIDE_WIDTH 362 / DRAWER_WIDTH 360, station.gd:132-133), slides over the body from the LEFT with scrim, 0.18 s in / 0.12 s out (station.gd:144-145, :851-853, :881); 7 module entries (274 px) + SESSION/LOG OUT; scrim press closes (:897-900); used it to navigate. Note: the brief says "right drawer" but the pin says left — UI_SPEC.md:1092 (N26) and :1140 pin "slides over the body from the left"/"anchored left"; build matches the pin, the brief wording is off.
- AUCTION reads clearly: one real header row per table (HULL / PRICE / ACTION, then SHOP / STATUS / ACTION for modules), right-aligned prices, OWNED / BUY / red LIMIT states, trailing INSPECT chips, family tab strip, 76 px rows. This header-row idiom is what the exchange restyle should borrow instead of per-row caption stacks.

## 5 CLEANUP SWEEP at 1920×1080

- LOW - the first overview tile (ARMORY) carries its orange focus ring on pane open before any pointer input (focus_primary) — reads as pre-highlight; harmless.
- LOW - save profile carried the earlier reviewer's session: credits read 64,560 then 64,772 across two boots with no play in between; contracts 0/3 — noted, no fault.
- No other visible faults: boot logo/bar, "ENTERING SPACE" loader, main menu bands, overview tiles/hull/contracts rows, footer hints and credits plaque all clean and readable.

## Fix list (ordered by impact)

1. Exchange hold column: raise HOLD_CONTENT_WIDTH 500→~608 (or rebalance row columns) so titles fit AND the header band aligns — exchange_panel.gd:68 + :293-325.
2. Armory browser rows: ellipsis-trim the title into a fixed column (port exchange's trimming `_make_label`) so RowInner ≤ 478 and every INSPECT chip lands inside the window — armory_panel.gd:1673-1678, :3816; optionally widen the Split's browser half.
3. Exchange evenness: give the hold and board the same top band (or neither) so both scroll viewports start at the same y — today 26 px apart — exchange_panel.tscn:56-100.
4. Tooltip legibility: RichTextLabel font_size 13→15/16, consider cap 320→360 — vajb_theme.tres:469-473, tooltip.gd:17.
5. Hover delay ×2: TOOLTIP_DELAY 0.25→0.5 — station.gd:177.
6. Exchange double captions: drop the per-row caption stacks once a trustworthy header band exists (or drop the band) — exchange_panel.gd:539-541.

## Acceptance list answers

1 — EXCHANGE compared (see §1): board = full 517 px titles + per-cell value/caption stacks in a clean scroll; hold = 28 px truncated titles, header band 109 px misaligned, list 26 px lower, double captions; root cause HOLD_CONTENT_WIDTH=500 at exchange_panel.gd:68.
2 — ARMORY overflow reproduced at rest on open (no hover/scroll): rows 542-620 px in a 478 px viewport, chips to x1963 > 1920 window; widget = the MODULES · OWNED & BUYABLE row's trailing INSPECT chip; cause armory_panel.gd:1673/:3816. Module (a) exists (slot grid + racks + inventories + drag-fit); (b) battery config has no separate module — battery = grouped identical weapons per doc 09 L555-581, B1..B5 racks at armory_panel.gd:1935.
3 — Hover: 0.25 s delay (station.gd:177), stays while hovered (no auto-hide); 13 px tooltip text in a 320 px cap; x2 = one constant → 0.5 s; in-game stopwatch skipped (game_eval blocked, see header).
4 — TERMINAL verified nice: 362 px slide-over drawer, 0.18/0.12 s, clean entries, scrim close.
5 — AUCTION verified all clear/readable: single header row + right-aligned prices + state chips — the idiom to borrow.
6 — Sweep: two LOW findings (overview focus ring on open; carried save state), nothing else visibly broken at 1920×1080.
