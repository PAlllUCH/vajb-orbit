# D14 — ARMORY chrome composition: the information for the designer session

**Read this with the owner, then brainstorm. No worker dispatch yet.** Everything
below is measured; the code paths are cited so nothing has to be taken on trust.
Companion: `SLICE.md` (scope) and `_evidence/` (the captures).

## 1. Why this slice exists

The owner, 2026-09-26, after playing the S20 build of the ARMORY:

> "look how clean auction and shipyard are done i want all to look this clean."

and the standing rule he set the same day:

> "we always should use anchors and relative positioning." — his reason: *"when
> i dispatch each agent it generates different outcome"* (each worker freestyles
> the layout, so the same brief lands differently). The law has to be mechanical
> enough that two workers cannot diverge.

So this slice has two jobs: (a) make the ARMORY read like the two clean panes,
(b) write the *mechanism* into the docs so the idiom is not re-invented per wave.

## 2. What "clean" is, mechanically — the sibling panes

AUCTION and SHIPYARD are **pure container trees over theme styleboxes**. No
`_draw()` chrome, no `position`/`size` arithmetic for anything that must sit
inside art:

- `ui/station/auction_panel.gd:752-760` — a row is a `Button` with
  `custom_minimum_size`; its children are `HBoxContainer`/`VBoxContainer`/
  `MarginContainer` built in script (`:769-786`, `:789-800`); the chrome is the
  theme's Button plate.
- `ui/station/shipyard_panel.tscn:74-115` — the only framed surface is
  `PreviewFrame` (`PanelContainer` + `theme_type_variation = &"PanelRaised"`) with
  a `MarginContainer` child, then a `VBoxContainer`; the image is centred by
  `CenterContainer`.
- `ui/station/auction_panel.tscn` / `shipyard_panel.tscn` — every panel is
  `VBoxContainer` → `HBoxContainer`/`ScrollContainer` → `MarginContainer` →
  content. Sizes come from `custom_minimum_size` + size flags, never from
  coordinates.

**Consequences that matter here:** the container sizes the content; the stylebox
draws the chrome; a child can only land under the chrome's band if someone sets a
negative offset by hand. Overlap becomes inexpressible rather than checked.

## 3. What the ARMORY does instead — and where it shows

The pane computes every rect in code and paints its chrome in one `_draw` pass
over those rects:

- `ui/station/armory_style.gd:220-322` — the rect derivations (`bay_rect`,
  `bay_cell_rect`, `ledge_rect`, `well_half_rect`, `item_rect`) that the tests
  pin (P6: every rect derives from the host rect).
- `ui/station/armory_panel.gd:573-660` — `ConsolePanels`: one node, one `_draw`,
  painting the bay/well frames (`_frame`), the cell plates (`_slot`), the salvo
  ledges (`_plate`) and the cell recesses (`_recess`).
- `armory_panel.gd:1120-1200` — `_position_drop_cells`, `_lay_inventory`,
  `_lay_cards`: hand-placed children inside those rects.

Two coordinate systems (the arithmetic rects and the art) share no knowledge, so
a collision can only be found by looking. The owner found them.

### The measured defects

Chrome assets, at their real sizes (facts, not opinions):

| Asset | px | How the theme uses it | The problem |
|---|---|---|---|
| `ui_panel_frame.png` | 96×96 | `tools/build_theme.gd:504-514`: texture margins **32 px**, expand 1 px, **no content margins**; drawn on `PanelRaised`/`PanelContainer` | The metal band is the outer 32 px; the middle stretches. Only fits surfaces comfortably larger than 2×32 px per axis |
| `ui_slot_weapon_normal.png` | 48×48 | `build_theme.gd:419-427` registers it as a plain `StyleBoxTexture` (no margins); `SlotButton` draws it with `ignore_texture_size` (stretch) | It carries a **painted pistol silhouette** in its centre — a state hint, not a neutral plate |
| `ui_button_plate_normal.png` | 280×56 | `build_theme.gd:358-364` registers it as a plain `StyleBoxTexture` (no margins) | A wide bar with an end bolt each side; stretched into a 24×24 chip it smears |

The pinned geometry it is drawn over (UI_SPEC §3.10 A3, owner-ticked):

| Surface | Size at the 1392×610 host | Content that must sit inside |
|---|---|---|
| console | 1360×516 at (16,68) | bays band 1328×192; wells band 1328×220 |
| bay card | 260×192 | head 34 tall; cells 2×2 **117×52**, gap 6, margin **10**; ledge 240×34 at bay-y **150** |
| well half | 648×220 | caption + 2×3 grid of **320×68** items, gap 8 |
| pack/inventory card | 320×68 | 6 text lines + 24 px icon + BUY chip |

Resulting collisions (all visible in `_evidence/`):

- **Bay card vs frame:** the frame's 32 px band leaves a 196×128 opening; the
  cell block is 240 px wide → the DROP HERE tiles **overhang the frame by 22 px
  per side**, and the head (y 0–34) and the ledge (y 150–184) sit **inside** the
  top/bottom bands.
- **Card vs frame:** 68 px tall, bands 32+32 = 64 → the frame's inner lip crosses
  the text lines (see `armory_cards_1to1.png`).
- **Cell vs slot plate:** 117×52 ÷ 48×48 = a 2.44× horizontal stretch → the
  painted pistol smears across every cell (`armory_bay_1to1.png`).
- **`✕` chip vs button plate:** written 24×24, laid out 24×29 (the plate's own
  minimum); the 280 px bar squeezes into it (row L236).
- **Wells half vs frame:** 648×220 → opening 584×156 → **this one is correct**;
  it is the shape of surface the frame was cut for.

## 4. The horn the designer must resolve

The frame's band (32 px) is **larger than the bay's own content margins are
allowed to be** (10 px). Amendment 3 froze those margins; the art cannot honour
them. Either the small surfaces stop wearing that asset, or a small-surface
variant of the family has to exist, or A3's inner numbers get re-derived from the
art. Those are design decisions; the code follows.

## 5. Agenda (work these through, then come back with ticks)

- **Q1 — chrome per surface size.** Proposal: a nine-slice asset may only dress a
  surface that is **≥ 3× its patch margin in both axes** (i.e. the band plus real
  content room); everything smaller wears the theme's flat language instead
  (`_flat()` at `build_theme.gd:450-457`: 1 px Tokens border, no band). Under that
  rule: `ui_panel_frame` on the two wells halves and the pane floor, everywhere
  else flat Tokens boxes. Confirm or better it.
- **Q2 — does the family need a small frame variant?** If the bays and cards
  should still read as "framed chrome", that is a new asset (a ~48–64 px plate
  with a 10–12 px patch, cut from the same metal language). The owner decides
  whether to spend a generation on it or accept flat boxes there.
- **Q3 — what is an armory cell?** Options: (a) a machined recess only (the S18
  look the owner liked); (b) the slot plate at its own 48×48, drawn 1:1 (centred,
  or left with the name to its right); (c) a new slot *frame* asset with no baked
  silhouette, so it can dress a 117×52 cell. Note A4.2 currently pins "slot
  chrome" on the cells; FITTING's own slots draw it at 48×48.
- **Q4 — which A3 numbers stay law.** If the inner layout becomes container-driven
  (margins, `custom_minimum_size`, gaps), say which of the pinned numbers are the
  *look* the owner ticked (cells 2×2, five bays, one wells band, 13 px ink, the
  ledge) and which are free to become consequences of the art. A number that
  stays law keeps its test row; a number that moves needs its old→new recorded.
- **Q5 — the cards and rows.** Confirm the pack/inventory row as the AUCTION row
  shape (Button + plate + container children) with its element order fixed
  (icon, name, price, `<rounds> ROUNDS PER PACK`, `HELD … - HOLD … UNITS`,
  §5.1 state line, BUY); state what chrome it wears at 320×68.
- **Q6 — the law text.** For UI_SPEC §3.10 Amendment 5, as *mechanism* so workers
  cannot diverge: (i) layout is containers + anchors, `custom_minimum_size` and
  size flags, never coordinates; (ii) a surface's chrome is a theme stylebox or
  its own node, never a `_draw` pass over content; (iii) chrome is chosen by the
  asset's cut size (Q1's rule); (iv) content insets come from the stylebox's own
  `content_margin_*`; (v) any code-drawn mark must be drawn *within* its own
  child rect, anchored to it, never over a sibling's.

## 6. Deliverables from the designer session

1. `docs/design/UI_SPEC.md` §3.10 **Amendment 5**: the per-surface chrome table
   (surface → asset/stylebox → content inset) and the Q6 law, every number with
   its reversal.
2. A revised armory band in `staging/mockup/armory_mockup_v2.py` if Q4 moves any
   number (the mockup's `_b`/`_b_wide`/`_b_tall` proofs must still pass).
3. The owner tick list for the coder wave that follows (nothing implements before
   the ticks).

## 7. Constraints that do not move

- 13 px ink floor, no `font_size` overrides in the pane; captions ≥ 4.5:1.
- Hex lives only in `tools/build_theme.gd`; the pane's palette resolves from
  `Tokens/armory_*` (`ArmoryStyle.resolve_theme`).
- The §5.1 four stock states, the P5 wording, the salvo ledge (tick T5 = keep),
  the `inspect_requested(title, body, danger)` seam and §23.1's inspector pin.
- Bay chip wording already ruled: `▲ AT CAP` when the battery holds all four
  cells (S20 close-out; the pack card keeps §5.1's `OVER CAP` = over the advisory
  ceiling).
- Gate starts **895/0**; rows may only be added; every moved row's old→new goes in
  the report. The coder wave must not share `vajb-orbit/tests/` or
  `vajb-orbit/tools/` with S19 while S19 is live.

## 8. Evidence index

- `_evidence/armory_live_1920x1080.png` — the pane as the owner sees it.
- `_evidence/armory_bay_1to1.png` — the bay band, 1:1 (frame band, tile overhang,
  smeared slot plate, ledge).
- `_evidence/armory_cards_1to1.png` — the pack cards, 1:1 (frame lip across text).
- `_evidence/chrome_assets_1to1.png` — `ui_panel_frame`, `ui_slot_weapon_normal`,
  `ui_button_plate_normal` at native size.
- `_evidence/slot_plate_4x.png` — the slot plate at 4× (the baked pistol).
