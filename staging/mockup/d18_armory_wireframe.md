# D18-A1 mockup — the merged ARMORY panel (wireframe)

Design law: `docs/design/STATION_HUB.md` §16 P4 + §17 (this wave's detail) +
`UI_SPEC.md` §8 (P1–P3) and §3.10 A5.1–A5.4. One pane, D13 approach B
landscape split (STATION_HUB.md:996-997). Wireframe, not a rendered plate.

## The pane (SERVICES → ARMORY; FITTING folds in — P4/P7)

`PaneHeader` (icon + `ARMORY`) / content split / P2 action cluster / shared
footer hint — the P7 template. Left: the ship grid **exactly as FITTING ships
it**. Right: the inventory browser (`custom_minimum_size (420, 0)` — §15
spine's PROPOSED column).

```
+====================================+==============================================+
||  SLOT LAYOUT · 8 CELLS · 2 ENGINES||  MODULES · OWNED & BUYABLE            [ALL ×] || [1]
||  +------------------------------+ ||  [WEAPONS][DRIVES][SHIELDS][ARMOUR][POWER]   || [2]
||  | [w][w][e]   grid: 48 px      | ||  [COMPUTERS][BOOSTERS][UTILITY][ALL]         ||
||  | [e][s][u]   plates, glyph    | ||  +----------------------------------------+  ||
||  |      inset 6, sep 4          | ||  | [i] Thruster Mk II   OWNED ×2  [BUY]  |  || [3]
||  +------------------------------+ ||  +----------------------------------------+  ||
||  (hover a cell → the inspector)  ||  | [i] Hyperdrive   12 000 CR    [BUY]  |  || [3]
||                                  ||  +----------------------------------------+  ||
||  PWR 4 / 12 · CANDIDATE 6 / 12   ||  | [i] ...        (auction row idiom,   |  ||
||                                  ||  |                76 tall, RowInner 12/8)|  ||
|+----------------------------------+---------------------------------------------+|
||  [ REMOVE ]                  [ BUY & FIT SELECTED ]        status: DROP REFUSED— || [4][5]
||                                HYPERDRIVE FITS NO WEAPONS CELL · W1 flashes ENGINE  ||
+==============================================================================+||[6]
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | left ship grid: 48 px `SlotButtonWeapon` plates, gap = empty 48×48 `Control`, slot glyph inset 6, separation 4, caption `SLOT LAYOUT · %d CELLS · %d ENGINES`, footer power meter `PWR %d / %d` (+ `· CANDIDATE %d / %d`) | A5.4 `Bay cell` (machined recess + glyph at 1:1) | `icon_slot_*.svg` 96 masters (ASSET_CATALOG.md:394-401); FITTING's own numbers, `fitting_panel.gd:18-70,148-149` | P4 |
| 2 | filter-tab strip (toggle plates) | A5.4-2 (theme cite, no asset) | the auction's family tabs minus `HULLS` (hulls are not module rows): `WEAPONS · DRIVES · SHIELDS · ARMOUR · POWER · COMPUTERS · BOOSTERS · UTILITY · ALL`, `auction_panel.gd:93-104` | P4, P8 |
| 3 | browser rows: owned (`OWNED ×n`) and buyable (`<price> CR`), every row **draggable**, row-corner BUY | A5.4-4 data row + P1 `ActionInline` 96×32 flat chip (theme `Button`, no asset) | auction row idiom (`A5.4` row shape Q5; STATION_HUB.md:177-178); `item_icon` glyph 24 | P4 |
| 4 | action cluster: `REMOVE` (ActionSecondary) + `BUY & FIT` (ActionPrimary) | §8 P1/P2 | `ui_button_plate_*` (ASSET_CATALOG.md:435-438, cut 280×56) 360×56, primary rightmost | P1, P2, P14 |
| 5 | status line (refusals, confirmations) | the shell's own footer strip | `station.gd` `_status_label` | P9 |
| 6 | cell slot-caption flash on a refused drop | label + state, never colour alone | the cell's own caption, 0.5 s (**P10**; reversal 0.25 s) | P9, P10 |

## Drag-and-drop law (P4)

- Cells accept drops **filtered by slot** (a cell's family is its identity,
  `fitting_panel.gd:74-93`); engines drag like any family.
- A **wrong-slot drop is refused**: the status line says so —
  `DROP REFUSED — <MODULE> FITS NO <SLOT> CELL` (**P9**; reversal: the bare
  `DROP REFUSED`) — and the cell flashes its slot caption (**P10**). Never a
  colour change alone.
- A drop of an **owned** module into a legal cell fits it (swap law: the
  displaced module, if any, returns to the hold).
- A drop of an **unowned** row into a legal cell **buys-then-fits** (one flow,
  one press): credits are checked first; a shortfall refuses with the status
  line (`REFUSED · NOT ENOUGH CREDITS · <n> NEEDED` — the shipped refusal
  wording, `auction_panel.gd:160`).
- `BUY` on a browser row (row corner) buys into the **next free legal cell**,
  or the **selected cell** if one is selected; `BUY & FIT SELECTED` (P2
  cluster) does the same for the focused row. Confirm wording:
  `FITTED · <MODULE>` (**P11**; reversal: silent fit).

## Hover — one chain

Rows, cells and tabs all describe through the existing inspector chain
(`inspect_requested` → `InspectorTitle`/`InspectorBody`,
`station.tscn:214`, `station.gd:150-151`, `tests/test_s11_inspector.gd:140-233`);
the pane adds no second description surface (P6 governs the band's lifecycle).
