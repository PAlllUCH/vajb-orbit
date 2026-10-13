---
slice: S43
reviewer: S43-R0
verdict: passed-with-followups
gate: "1347/3 (builder, on 1350 rows) → 1350/0 (R0 repeat after the developer's three re-cuts)"
---

# S43-R0 review

Method: the brief's pins read by range (STATION_HUB §23.4 P49; UI_SPEC §17 A4–A6,
§3.10 A5.1–A5.5, §16.1; 09 §8), the full diff read hunk by hunk, the seam read at
its S25 home, every report cite re-opened, the gate re-run. Nothing fixed.

## Acceptance list

1 — pass — EquippedBlock is FitLeftStack's third block after CellInfoBlock
    (`armory_panel.tscn:193-216`, order proven by test:266-271); caption
    `EQUIPPED — %d/%d` on `StationCaption` (tscn:199-203; `armory_panel.gd:173`,
    written at :2224), counts = fitted vs `_cells.size()` re-derived independently
    in the test (:276-290).
2 — pass — rows walk `_cells` (row-major, gaps excluded at build,
    `armory_panel.gd:3483-3512`) skipping empty entries (:2209-2215); cell id
    reuses CELL_INFO_ID's leading pair via `CELL_ID_FORMAT` (:147-150,
    :2333-2335); name is the catalogue's own (`_module_name`, :3296-3299); one
    stat line from `ModuleData.module(base).effects` through the `stat_line`
    idiom's byte-twin (`_effect_line`/`_stat_line` :2339-2365; constants :173-176
    = `fitting_panel.gd:145-149`; `signed_percent`/`signed_number` bodies match
    `fitting_panel.gd:1665-1670`) — no second table; glyph 24 at its own cut
    (`_make_icon(…, 24)`, :1886-1900, keep-aspect-centred). Test :293-339 pins
    the full walk, both variations, the glyph and four stat shapes.
3 — pass — `_apply_flat_chrome`: `item_bg` fill + 1 px `metal_mid` border, radius 0
    (:2319-2331); RowInner inset 6 (:2237-2242); `EquippedScroll` own
    ScrollContainer, horizontal disabled, expand-fill (tscn:205-209); CellInfoBlock
    releases the slack (tscn diff 3→0). Test :342-386 pins all six facts.
4 — pass — row press → `select_cell` (:2293-2297) → `_select`; the grid and CELL
    INFO follow, and the reverse direction mirrors via `_apply_equipped_selection`
    called from `_select` (:3619) and `clear_selection` (:3656). Test :392-417
    proves both directions plus the pressed states on row and plate.
5 — pass — the block rides `FitCells`; `_apply_mode` hides the root in BATTERY
    CONFIG (:1073-1074); no mode branch in `_sync_equipped`. Test :420-434.
6 — pass — `_on_buy_pressed` → `_request_buy_confirm` (:4626-4641); body =
    `BUY_CONFIRM_BODY` with the catalogue row's name and `_format_int(price)` at
    press (:4017-4031); OK → `confirm_action` → `_buy_into_cell` unchanged
    (:4034-4052, `_fit_entry_at` re-checks credits → `STATUS_SHORTFALL` strip,
    :394/:3167 — never a dialog); CANCEL returns focus via the seam
    (`station.gd:584-602`). Test :440-511 (charge-before-answer, confirmed charge
    + fit, refusal strip).
7 — pass — `_on_row_pressed` opens the door with `AMMO_CONFIRM_NAME` (pack row's
    own name + rounds) and the card's press-time `cost`
    (`Catalog.ammo_pack_price`, :1766; §5.8's clock); OK → `_purchase_ammo`, the
    unchanged transaction (:4057-4085); refusal = pulse + §3.1b danger frame, the
    shell hears `purchase_failed`. Test :514-580 (wording, charge, refusal, frame).
8 — pass — `tests/test_s43_armory_equipped.gd`: 9 tests pinning items 1–7 (item 4
    covers both directions in one test), `[SUMMARY] passed=9 failed=0` inside the
    gate; the report answers every item with a cite, all cites re-opened accurate.

## The disclosed route reading (graded)

pass — the seam is faithful to A5's normative content. The shell's overlay is the
§5.2 dialog this surface family already owns (build `station.gd:501-559`; answer
:566-581; wire :1288-1290), it carries the payload's OK/CANCEL verbatim, ESC →
CANCEL is its own (`_handle_cancel`, :1841-1846), focus returns on answer
(:584-601), and no `message` appears at either door. A5's own reversal (a second
bespoke dialog scene) is honoured by routing through the seam. Recorded, not a
finding: focus returns to the active pane, not the pressed control — the seam's
shipped S25 shape, which the reading discloses as "the seam's own"; N39's
control-level reading belongs to S25's record, not this wave.

Recorded on item 2: P49's verbatim example (`+400 POOL · REGEN 5/S`) is the doc
column's shape; the brief's acceptance list pinned the `stat_line` idiom as the
renderer and the build obeys the brief (`SHIELD +200 · REGEN +4`, `SPEED ×1.0`).
The idiom is the brief's own reading; not drift.

## The three developer re-cuts (graded)

pass — all three answer the confirm door without weakening their original
assertion; each now additionally asserts the door semantics (press charges
nothing).
- `test_p2b1_outfitting_panel.gd:484-506` — watches `confirm_requested`, asserts
  the press charges nothing + the A6 wording + `ACTION_BUY_AMMO`, then
  `confirm_action` restores the original charge/units assertions verbatim.
- `test_s32_armory_modes.gd:417-424` — press charges nothing; `confirm_action`
  charges the catalogue price and still fits `e_ion` (original assertions kept).
- `test_s32_armory_modes.gd:761-768` — same shape through the public-doors row.

## File set

`git diff --name-only`: the brief's three deliverables (builder's set, clean) plus
`test_p2b1_outfitting_panel.gd`, `test_s32_armory_modes.gd` and the brief file
itself — all the developer's own disclosed post-landing acts (the re-cuts the
builder's Follow-ups row queued, and the process-law amendment). No HIGH; the
brief's own mechanism ("the developer re-cuts") is what produced them.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | `armory_panel.gd:3938-3956`, `:4012-4015` | A4's criterion still has two doorless module-acquisition presses in this pane: the buyable row's own press (`_on_browser_pressed` → `_flow_row_into_cell`, `owned=false` buys at :3950-3956) and the foot cluster `BUY & FIT`/`BUY & FIT SELECTED` (tscn:284 → `_on_buy_fit_pressed`). The brief pinned only the row-corner BUY (its measured facts name `_on_buy_pressed`); widening the door list is bucket 2/3 — developer/owner ruling: in this slice or in the A4 door-list wave | developer (escalate; a fixer cannot widen a brief's scope) |
| F2 | LOW | `S43-V0_report.md:49-51`, frontmatter | The suite-count parenthetical sums to 10 ("4 two incl. the reverse direction") but the suite has 9 tests (item 4 is one test covering both directions); the frontmatter's status line ("re-cut before slice close") is now stale after the developer's re-cuts | developer (bookkeeping at close-out) |
| F3 | LOW | `armory_panel.gd:2324-2331` | `_apply_flat_chrome` re-registers the theme's own hover/pressed/disabled/focus boxes as overrides — a visual no-op (the states already come from the theme); harmless dead code | — (ticket at close-out) |

## Verified fixes

None — no fixer pass ran (no HIGH; F1 escalates to the developer, F2/F3 are LOW).

## Gate

- Builder's own run (report): `[GATE] run 1: FAIL - [SUMMARY] passed=1347 failed=3`
  on 1350 rows — the three moved-premise rows, zero SCRIPT ERROR lines; baseline
  arithmetic checks out (post-S42 tree 1341 + this slice's 9 = 1350).
- After the developer's three re-cuts, this review's repeat
  (`python3 staging/gate.py --times 1`, log `/tmp/s43_r0_gate.txt`):
  `[GATE] run 1: ok - [SUMMARY] passed=1350 failed=0`, exit 0 — matches the
  tree's stated 1350/0.
