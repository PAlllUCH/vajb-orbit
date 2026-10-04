# D20 — orchestrator synthesis: the owner's playtest + two live game reviews (2026-10-04)

Sources: `D20-P1_report.md` (`xiaomi/mimo-v2.6-pro` @ high) and
`D20-P2_report.md` (`hyper/glm-5.3-flash` @ max), same brief, back-to-back on
the live editor at 1920×1080, one game window and one shared save profile (both
reports flag the carried session state; informational). Gate n/a — review only,
no code changed (live gate 1093/0 from S30's close). Tiers: HIGH breaks a loop ·
MED player-visible · LOW polish. Where the reviewers tier differently I take my
grade and name both.

## 0. The owner's five notes against the build

| Note | Verdict | Evidence |
|---|---|---|
| 1. "your hold" should read like the marker board, both even on one height | **Confirmed defect cluster** (both): hold titles starve to 28 px ("RO…"), its header band sits ~109 px off its own columns, its list starts 26 px lower — outer boxes are ALREADY even (both 635 px at y267) | `exchange_panel.gd:68, 293-325, 539-553` |
| 2. armory "modules owned and buyable" shifts out of screen | **Confirmed HIGH** (both), at rest on open: rows need 542–620 px in a 478 px viewport; long-name rows push their INSPECT chip past the 1920 px window (x to 1963) — unreachable controls | `armory_panel.gd:1673-1678, :3780-3830`; split 1262/490 `armory_panel.tscn` |
| 3. inspect twice as long on hover, clearer to read | Measured: 0.25 s appear (`station.gd:177`), visible while hovered, no dwell; body 13 px `text_dim #6b7484`, 320 px cap. "Twice as long" has two readings — **T-124**. Legibility fix agreed (both) | `station.gd:177`, `tooltip.gd:17, 83-95`, `vajb_theme.tres:469-473` |
| 4. terminal works nice | **Verified** (both): one decision per row, scrim over the body band only, 0.18/0.12 s slide | `station.gd:132-145, 390-400` |
| 5. auction all clear, readable | **Verified** (both): one real column-header row per table, right-aligned prices, one-word states — the idiom the exchange restyle must borrow | `auction_panel.gd` section headers |

Correction to my own brief: it called TERMINAL a "right drawer". The pin says
**left** (UI_SPEC `:1092` N26 "slides over the body from the left"; §12.1 `:1140`
"anchored left") and the build matches the pin (362 px slide incl. frame bands
vs 360 content). P2 checked the pin and caught my wording; P1 graded against it.
No defect.

## 1. Cross-confirmed (both reviewers)

- **HIGH — armory browser overflow** (note 2). Row inner minimum 542–620 px
  (icon 24 + untrimmed title 118–202 + Read 130 + BUY 96 + INSPECT 96 +
  separators) in a 478 px row / 490 px `BrowserScroll`. Three real
  contributors: the fixed cell + chip widths (P1, `armory_panel.gd:3780-3830`),
  the missing ellipsis trim in `_make_label` (`:1673-1678`; exchange's `_make_label`
  trims — `exchange_panel.gd:954-965`), and the starved split (1262/490, P2).
- **HIGH (P2) / MED (P1) — exchange hold cluster** (note 1). One root cause:
  `HOLD_CONTENT_WIDTH=500` (`exchange_panel.gd:68`) cannot seat icon 40 + title
  + 3 fixed cells (70/80/100) + the 96×32 INSPECT chip + separators, so the
  expand-fill title gets 28 px; the header band (`:293-325`) mirrors three value
  columns and never re-derives the chip offset (+96+12), and its captions
  (HELD / CR EACH / VALUE, `:109-110, :317`) contradict the rows'
  (UNITS / CR EACH / CR NET, `:102-104, :539-541`). The 26 px row-start offset is
  the hold-only header band + gap (`:293`; tscn `:56-100`). I grade the
  truncation **HIGH** — a two-letter title makes the row unidentifiable.
- **MED — tooltip legibility** (note 3). Body and the INSPECT hint share
  `text_dim #6b7484` (the weakest read in the shell; unreadable at 640) at the
  theme's 13 px RichTextLabel in a 320 px cap (`tooltip.gd:83-95, :17`,
  `vajb_theme.tres:469-473`).
- **MED (P1) — armory below-the-fold lists** (feeds note 2's split): `BodyScroll`
  is a 264 px viewport over 516 px content, so BARREL INVENTORY and AMMUNITION
  hide below the fold on open (`armory_panel.gd:1008`).

## 2. Single-reviewer findings (all LOW)

- P1: the tooltip also pops on keyboard focus with no pointer near it, while
  anchoring at the OS cursor (`station.gd:593-607`,
  `exchange_panel.gd:803-813`) → T-118.
- P1: the confirm strip wraps and orphans the total in the 360 px TradeBox
  (`exchange_panel.tscn:148-152`) → T-119.
- P1: the board has no column-header band at all — fold into F1's idiom choice.
- P1: the armory Console plate leaves ~330 px dead space → T-122.
- P1: the main-menu InsigniaBadge glyph is unverifiable at 640 → T-123.
- P2: the family tab strip crams 8 tabs into 490 px (ALL tab 23 px) → T-120.
- P2: the first OVERVIEW tile carries its focus ring on pane open → T-121.

## 3. The rework asks — what exists today (grounding for the wave)

- **Armory module (a) "select cell → what it is → what fits → select/drag fit":**
  exists = the 23-cell SLOT LAYOUT grid + one-line `SelectionLine`
  ("W1 · PLASMA COIL · OWNED ×0"), the family-tab browser (owned + buyable),
  drag-to-fit / right-click pull / keys 1–5, BUY & FIT SELECTED, REMOVE, BARREL
  INVENTORY. Missing = a real per-cell info block (refusal strings exist unused
  at `armory_panel.gd:86-90`) and a candidate list filtered to the selected cell
  (the browser filters by family only).
- **Armory module (b) "battery configurations based on fitted weapons":** a
  **battery** is the player-composed rack of W-cell weapons under one trigger;
  Batteries v2 allows mixed groups, hardcap 5 racks × 4 cells
  (`docs/gameplay/09_ship_slots_modules.md` §10–§12, L555-746;
  `player_profile.gd:1178-1353` `fit_battery`/`clear_battery`/`battery_groups`/
  `set_battery_groups`; volley strum `weapons.gd:277`). The R1..R5 rack strip IS
  that surface (`armory_panel.gd:1935-1948`) but is welded to the bottom of the
  one screen, inside the fold, and exposes no grouping/salvo editing beyond
  fit/unfit.

## 4. Fix plan (proposed split; on the owner's go)

- **F1 — exchange parity** (quick): title room (rebalance the cells or widen the
  hold column 500 → ~608), one header idiom on both lists (AUCTION's single
  column-header row), both lists' first rows on one height, caption vocabulary
  unified to one set of words. `exchange_panel.gd:68, 293-325, 539-553`.
- **F2 — armory overflow** (quick): ellipsis-trim titles (port exchange's
  `_make_label`), rebalance Read/BUY/INSPECT widths, widen the browser half —
  every row's INSPECT lands inside the window.
- **F3 — inspect popup** (quick): the ×2 per **T-124** + legibility (body/hint
  one step above `text_dim`; 13 → 15 px scoped to the tooltip, not the theme
  default; cap 320 → 360). Designer-picked values; reversal = the current trio.
- **F4 — armory 2-module rework** (its own wave: design then build): module A =
  the cell-fit screen (per-cell info block + candidate list filtered to the
  selected cell + select/drag fit); module B = the battery-config screen (the
  rack strip promoted to a full surface + grouping edit through
  `set_battery_groups` + SALVO/cycle readout). Shape per **T-125**, scope per
  **T-126**.
- **F5 — LOW pack:** T-118–T-123 ride the same wave's fixer.

## 5. Owner ticks (mirrored in `TICKS.md`)

- **T-124 — note 3's reading.** A: "twice as long" = total readable time → keep
  while hovered + linger 0.5 s (2× 0.25) after the pointer leaves, and hold the
  popup steady across hover churn inside one row. B: "twice as long" = double
  the appear delay (0.25 → 0.5 s). **Default if silent: A** — today the tooltip
  is cursor-anchored and dismisses/re-arms as the pointer crosses a row's
  children, which is what makes it feel brief. Reversal: B.
- **T-125 — the armory split's shape.** Two full-screen modes under ARMORY
  ("FIT CELLS" / "BATTERY CONFIG", one visible at a time) vs two panes on one
  screen. **Default if silent: two modes** (the owner's "not all on 1 screen").
  Reversal: two panes.
- **T-126 — the battery module's scope.** Rack regrouping (a real
  `set_battery_groups` editor) + SALVO/cycle readout only vs also loadout
  presets (saved battery sets). **Default if silent: regroup + readout only**.
  Reversal: add presets.
