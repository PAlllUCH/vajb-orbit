# D18-A1 mockup — the merged SHIPYARD panel (wireframe)

Design law: `docs/design/STATION_HUB.md` §16 P5 + §17 (this wave's detail) +
`UI_SPEC.md` §8 (P1–P3) and §3.10 A5.1–A5.4. One pane, §15's layout spine
(list half + 420 right column). Wireframe, not a rendered plate.

## The pane (SERVICES → SHIPYARD; REPAIRS folds in — P5/P7)

```
+====================================+=========================================+
||  YOUR HULLS · 3 IN THE HANGAR     ||  [ side render, PREVIEW_FRAME ]       || [1]
||  +------------------------------+ ||                                        ||
||  | CRUISER-X   ACTIVE           | ||  SELECTED  CRUISER-X                  || [2]
||  | 2-CLASS · 800 HULL · 9 SLOTS | ||  -------------------------------------||
||  +------------------------------+ ||  HULL      800   (ACTIVE  650)        || [3]
||  | GUNNER    2-CLASS · 650 HULL | ||  SHIELD    150   (ACTIVE  150)        ||
||  |           · 7 SLOTS          | ||  CARGO     120   (ACTIVE   90)        ||
||  +------------------------------+ ||  ENGINES     2   (ACTIVE    2)        ||
||  | SCOUT      1-CLASS · 400 HULL| ||  SLOT CELLS 9   (ACTIVE    7)        ||
||  |           · 5 SLOTS          | ||                                        ||
||  +------------------------------+ ||  INSTALLED MODULES                    || [4]
||                                    ||  +-----------------------------------+ ||
||                                    ||  | [w][w][e][e][s][u][·][·][·]      | || [5]
||                                    ||  +-----------------------------------+ ||
||                                    ||   (48 px plates; hover → inspector)   ||
||                                    ||  -------------------------------------||
||                                    ||  ACTIVE HULL  CRUISER-X              || [6]
||                                    ||  HULL      800 / 800      NOMINAL    ||
||                                    ||  SHIELD    150 / 150      NOMINAL    ||
||                                    ||  PROW      200 / 200      NOMINAL    ||
||                                    ||  STERN     200 / 200      NOMINAL    ||
||                                    ||  PORT      160 / 200      40        ||
||                                    ||  STBD      200 / 200      NOMINAL    ||
|+====================================+--------------------------------------+|
||  REPAIR AVAILABLE · 240 CR (footer line — the fee, never a body row)       ||
||                          [ SET ACTIVE ]                     [ REPAIR ]     || [7][8]
+==============================================================================+
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | hull list rows (name, `ACTIVE` badge, `<class> CLASS · <hull> · <slots>` meta) | A5.4-4 data row (76 tall, `RowInner` 12/8) | SHIPYARD's own rows, `META_FORMAT` `shipyard_panel.gd:135`; STATION_HUB.md:177-178 | P5 |
| 2 | side render + name plate | the pane's own `PreviewFrame` (SHIPYARD's one framed surface) | `shipyard_panel.tscn:74-115` (UI_SPEC.md:626-628) | P5 |
| 3 | **labelled** stat pairs + comparison block (`SELECTED` vs `ACTIVE`, ladder order) | A5.4-3 caption + flat value columns | `STAT_ROWS` `shipyard_panel.gd:106` (HULL/SHIELD/CARGO/ENGINES/SLOT CELLS); comparison = the catalogue's ladder order | P5 |
| 4 | `INSTALLED MODULES` caption under the comparison | A5.4-3 caption strip | theme `SectionHeader` 16 / `StationCaption` 13 | P12 |
| 5 | the selected hull's installed modules: the slot-layout grid, filled plates named on hover (`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`) | A5.4 `Bay cell` (glyph at 1:1) | `icon_slot_*.svg` (ASSET_CATALOG.md:394-401); `shipyard_panel.gd` plates/glyphs + `HOVER_FORMAT :144` | P5 |
| 6 | damage table: `ACTIVE HULL`/`HULL`/`SHIELD` + the four armour quadrants, `NOMINAL` for intact systems, **no MISSING/FEE rows in the body** | A5.4-4 data row, intact value `text_dim` (label + state, never colour alone) | `repairs_panel.gd:74-89` (REPORT_ROWS minus `missing`/`fee`); quadrant order 09 §3.3 P2 | P5, P13 |
| 7 | repair footer line (the fee lives here) + `REPAIR AVAILABLE · <n> CR` / `ALL SYSTEMS NOMINAL` | A5.4-3 caption strip | `repairs_panel.gd:50,52` (both wordings ship today) | P5 |
| 8 | `REPAIR` primary (+ `SET ACTIVE` secondary for a non-active selection) | §8 P1/P2 — ActionPrimary/Secondary 360×56, primary rightmost | `ui_button_plate_*` (ASSET_CATALOG.md:435-438) | P1, P2 |

When every row reads `NOMINAL`, `REPAIR` is `button_disabled` + `text_dim`
(A5.4-2's unavailable idiom — label + state) and the footer reads
`ALL SYSTEMS NOMINAL`.

## Hover — one chain

Hull rows, installed-module plates and damage rows all describe through the
existing inspector chain (`inspect_requested`, `station.tscn:214`,
`station.gd:150-151`, `tests/test_s11_inspector.gd:140-233`); damage-row
payloads add one line of `Repairs` context (what the pool is and its max).
When idle (nothing hovered, nothing selected), SHIPYARD fills the band with
its own summary — the active hull's name and its worst pool (P6).
