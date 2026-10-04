---
slice: S31
worker: S31-B1 (→ S31-R1 → S31-F1 if HIGH/MED)
role: coder
status: ready
tier: paid — roster owner-pinned: code `hyper/deepseek-v4.1-flash`, review `hyper/glm-5.3-flash`
---

# S31_BRIEF — shell fixes: exchange parity, armory browser, hover-inspect (2026-10-04)

## The law to read, in order
1. `docs/design/UI_SPEC.md` **§13.1** (pins N42–N47 — your only numbers) + **§11.1** A5.5/N24 (hover/focus mutate colour, `modulate`, `_draw` only — never size, position, or an in-flow `visible`)
2. `docs/design/STATION_HUB.md` **§19** (the pane skeleton) — by range
3. `slices/D20-station-playtest/D20_synthesis.md` §§1–2 (the measured causes; you re-derive values from code, not from prose)
4. `LOW_BACKLOG.md` D20 block (T-118–T-123 — F5's list; read-only for you, you fix the code)

## The owner's request (verbatim, 2026-10-03)
> 1. …make the "your hold" in exchange look the same and make sure that they are even = on same height…
> 2. in armory the "modules owned and buyable" shifts out of screen…
> 3. inspect time twice as long on hover, make it a bit clearer maybe to read?

Ticks T-124–T-126 decided at the owner's go 2026-10-04 (defaults taken). Gate baseline **1093/0**.

## Spec extract (verbatim — `UI_SPEC.md` §13.1; the Reversal column is the not-taken path)
| Pin | Law | Reversal |
|---|---|---|
| **N42** | both EXCHANGE lists render **one shared row builder** (the board's praised plate: 76 px row, icon 40, expand-fill title, meta line, value columns) and **one AUCTION-idiom column-header band** per list (§5.10's row: caption cells seated exactly over their value columns, values right-aligned). The captions are the row stacks' own words — hold `UNITS · CR EACH · CR NET`, board `INDEX · BAND · QUOTA`; the per-row caption stacks and `CAPTION_HELD`/`CAPTION_VALUE` are deleted (S28-A12's band superseded) | S28-A12's hold-only band + the per-row caption stacks as shipped |
| **N43** | the hold title column never renders below **180 px**: value columns rebalance to ≤ 60/64/80, and the hold list becomes an **N37 cluster** — no per-row `INSPECT` chip; one `INSPECT` `ActionInline` in the trade column acts on the focused/selected row (`disabled` + `text_dim` until one exists). Only if a row still starves the title may the hold box widen **500 → 560** (board 876 → 816) | the per-row chip + 70/80/100 + the 500 box |
| **N44** | both lists' scroll viewports begin on **one y** (identical caption → header → scroll stacks) and the outer boxes stay even at 635 px | the hold-only band's 26 px offset |
| **N45** | the armory browser row trims its title to a fixed **160 px ellipsis column** (port `exchange_panel.gd`'s trimming `_make_label`) and the browser half widens **490 → 620** (split 1262/490 → 1132/620). Acceptance: every row control lands inside the 1920×1080 window | untrimmed titles + the 490 half (the shipped overflow) |
| **N46** | the hover-inspect popup **lingers 0.5 s after the pointer leaves** (2× `TOOLTIP_DELAY` — T-124's A reading) and holds steady while the pointer crosses a row's children (re-arms only when the hovered row/cluster changes) | no linger; re-arm per child enter/exit |
| **N47** | the tooltip body renders `text_primary` (not bold; the INSPECT hint stays `text_dim`) and its `RichTextLabel` font is **15 px scoped to the tooltip node** (never the theme default), cap width **320 → 360** | the dim body at 13 px / 320 cap |

## Task
F1 = N42–N44 in `ui/station/exchange_panel.gd` + `.tscn`; F2 = N45 in `ui/station/armory_panel.gd` + `.tscn`; F3 = N46–N47 in `ui/screens/station.gd` + `ui/components/tooltip.gd`/`.tscn`; F5 = T-118 (tooltip pops on keyboard focus with no pointer — `station.gd:593-607`, `exchange_panel.gd:803-813`), T-119 (confirm-strip wrap orphan, `exchange_panel.tscn:148-152`), T-120 (tab strip cramp — fixed by N45's widen, reflow if still cramped), T-121 (pre-lit focus ring on the first OVERVIEW tile, `overview_panel.gd`). **T-122 = DEFERRED-TO-S32** (the Console band dies with the rework), **T-123 = DEFERRED** (verify at native res first). Keep every public seam other panes/tests call.

## Acceptance list (the report answers each with `file:line` / measured numbers)
1. N42 shipped: one row builder + one header band per list; caption stacks and `CAPTION_HELD`/`CAPTION_VALUE` gone.
2. N43 shipped: hold title ≥ 180 px (measured), cluster `INSPECT` in the trade column (`disabled` until focus/selection), no chip on hold rows.
3. N44 shipped: both scroll viewports' first rows on one y (measured); outer boxes even.
4. N45 shipped: every armory row control within the window at 1920×1080 (measured rects, longest-title row included).
5. N46 + N47 shipped: 0.5 s linger + steady across child churn; body `text_primary`, tooltip-scoped 15 px, 360 cap (cites).
6. F5: T-118/T-119/T-120/T-121 fixed (or disclosed why not); T-122 `DEFERRED-TO-S32`; T-123 `DEFERRED`.
7. Gate before/after `[SUMMARY]` lines; every moved test row disclosed (old → new + why); gate green.

## Hard constraints
- File set: `vajb-orbit/ui, vajb-orbit/tests` (hook-enforced). No `docs/`, `game/`, `autoload/`, `addons/`.
- A5.5/N24: hover/focus/selection mutate colour, `modulate`, `_draw` only. Never re-introduce in-flow hover blocks (§12.5's census).
- Never silently change a pin: an unimplementable number is disclosed at the closest value with its one-line reversal.
- Every Godot run bounded (`--quit-after`); never leave a background command.

## Tests that move
Panel-structure rows in `tests/test_s30_shell.gd`, `tests/test_p2b1_outfitting_panel.gd`, `tests/test_s20_chrome_unify.gd` and any exchange/tooltip rows. Moved rows are re-anchored and disclosed; new rows land for N42 (bands), N43 (title + cluster), N44 (equal y), N45 (row width), N46 (linger), N47 (font/cap). Gate counts move up; **failures stay 0**.

## Output contract
- Report: `slices/S31-shell-fixes/S31-B1_report.md` (≤120 lines, `_templates/REPORT.md` shape).
- Gate: `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 2>&1 | grep -E '\[SUMMARY\]|SCRIPT ERROR'` — before and after, ×2 fresh scratch after; always grep `[SUMMARY]` (it prints before Godot's exit-time leak errors).

## Run order
S31-B1 (`hyper/deepseek-v4.1-flash` @ xhigh) → S31-R1 (`hyper/glm-5.3-flash` @ max) → S31-F1 (same as B1) **only if the review leaves HIGH or MED**. Then close-out (gate ×2, `verify --baseline s31_start`, `docs_index`/`build_code_map` if moved, TICKS/WAVEBOARD/`MASTER_REPORT.md` §6, commit).

## Owner tick list
None open for this wave — T-124–T-126 decided at the go. (T-117, T-113 remain in `TICKS.md`, untouched here.)
