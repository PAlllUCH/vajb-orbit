# D23-R1 — station panel design audit

**Worker:** D23-R1, visual / UI designer. **Mode: VISUAL** — all ten renders at
`/tmp/vajb_review/` were viewed (downscaled to 1200 px JPEG per the brief, plus
three full-res right-edge crops for the scroll-affordance check); every finding
below was then verified against the panel source before it was filed. Contrast
numbers are S40's, referenced, never re-derived.

## A1 — per-deck composition

| Deck | Focal point | Hierarchy / grouping | Biggest visual problem |
|---|---|---|---|
| OVERVIEW (`overview_panel.gd`) | the 3×2 department tile grid — correct focal choice | Reads in the right order (identity → tiles → hull → services), but the deck lies: the identity block repeats the shell header's name plate ~200 px below it (`overview_panel.gd:162-200` vs `station.gd:737-744`), and the stack scrolls (§19.1's own arithmetic, ~776 min in a 633 split) so INSURANCE and VAULTS — two of the three deep-link rows — are cut by the fold with no visible scroll cue. | The fold amputates the services block after one row while the shell shows no scrollbar; the deck's navigation promise (P26) is half off-screen. **F1.** |
| ARMORY · FIT CELLS (`armory_panel.tscn`) | the browser list, right sector — correct | Right sector is exemplary: tabs → `FITS W1 - W9` → MODULE/STATE/COST band → rows, one rhythm. Left sector is top-heavy: `FitLeftBox` carries `size_flags_vertical = 0` (`armory_panel.tscn:108`), so the roofed box hugs the grid + CELL INFO at the top and the lower half of the sector is raw BG-1 backdrop down to the PWR meter. | Half the left sector has no roof and no content — the eye lands on the torpedo art before it finds the grid. **F2.** |
| ARMORY · BATTERY CONFIG (`armory_panel.gd`) | the B1–B5 rack stack, left — correct | Racks read well (label, count, READY, cells, SALVO meter). But the right list wears the browser's shared band `[BAND_STATE, BAND_COST]` (`armory_panel.gd:158-159`, built at `:3890`) while battery rows show fit states in both columns: STATE `FIT`/`STORED`, COST column `FITTED`/`OWNED ×n` (`READ_FITTED`, `:331`; `OWNED_FORMAT`, `:328`). A header that says COST over a column of ownership words. | The COST header mislabels its column, and the two columns double-report the same state. **F3.** Also two caption-only empty plates squat at the sector's fold (`EMPTY CELLS - 0`, `:164`; the PANE_HINT_BATTERY block, `:115`) reading as unfinished panels. **F4.** |
| REFINERY (`refinery_panel.gd`) | the mineral list, left — correct | Rows are chunky and legible. But hold-ore rows and loaded input rows are appended to the *same* VBox with no divider or sub-header (`_build_row` → `_hold_rows` for both, `refinery_panel.gd:442`; only the `LOADED` tag at `:424` distinguishes). The centre column (stepper + totals) floats label-and-value pairs straight on BG-2. | The held-vs-loaded grouping is illegible — two different states of ore read as one undivided list. **F5.** The disabled stepper `−`/`+` (48×48, `refinery_panel.tscn:120-140`) and the QUEUE row vanish into ghost plates (see F7). |
| EXCHANGE (`exchange_panel.tscn`) | the market board, centre — correct | Three-column split reads cleanly; both lists carry the shared band idiom; the hold list's roofed empty region below three rows is honest. The SALE column is a narrow (~230 px) form with one stepper and one quote line, then ~450 px of dead backdrop — a two-dense/one-empty imbalance. | The trade column under-fills its sector against two dense lists; the eye has nowhere to rest on the right. **F6.** |
| AUCTION (`auction_panel.tscn`) | the HULLS shelf — correct, the yardstick | Tabs → HULLS caption → band → six even rows: the cleanest deck on the screen. But with ALL selected, the fold falls exactly after the MODULES caption + its column band, orphaning a header with zero rows (§5.10's two shelf sections in one `AuctionScroll`, `auction_panel.tscn:59`). | An orphaned section header at the fold — the deck reads as if MODULES is empty. **F8.** |
| SHIPYARD (`shipyard_panel.tscn`) | the hull preview, centre — correct | Hangar view: list → preview → comparison table is a sound read order. The comparison stack (`StatsBox`, `:153`, a ScrollContainer) runs to the pane's bottom edge — the ACTIVE HULL / HULL / SHIELD rows sit on the frame with no hint the column scrolls. The sprite is ~150 px in a ~560 px frame; the void dwarfs the subject. | Right column's last rows land on the pane edge with no scroll affordance (F9), and the preview under-uses its frame (F10). |
| LAUNCH (`launch_panel.tscn`) | the LAUNCH plate, bottom-right ember ring — correct | The bay art carries the middle, the ship frame anchors the right. The briefing column floats label-over-value pairs straight on BG-4 (S40 Finding 4, T-174 — referenced, not re-filed); composition makes it worse because the values sit over the busiest art (cables, reels). | The foot band carries three competing caption sources: the pane footer (`ARM ONCE · LAUNCH TWICE · 3 s TO UNDOCK`, `launch_panel.tscn:153`), the brief note (`launch_panel.gd:155`), and the live confirm line (`:157`) — two static flavour lines flank the one line that matters during the 3 s arm window. **F11.** |
| SERVICES / CONTRACTS (`contracts_panel.gd`) | the board rows — correct | Board band + rows are disciplined; the ACTIVE CONTRACTS column is where the trouble is: each card stacks head + escrow lines + the `CANCEL - 100 CR FEE` chip into a `ROW_HEIGHT` card (`_build_active_card`, `contracts_panel.gd:320-375`), so the chip crowds the reward figure. The hint line is written twice on the deck (F12) and the pane's lower half is dead. | The active-card chip crowding reads as a layout accident at 1080p. **F13.** |

## A2 — the layout law (A5.2)

- **The ARMORY's coordinate layout** — `armory_style.gd:207-348` (console/band/
  rack/cell/ledge/well rect arithmetic) and every `_position_*`-style assignment
  in `armory_panel.gd:1391-1593` — is the one coordinate-driven panel on the
  screen. This is the deferral UI_SPEC §3.10 A5.4 already records ("converting
  the pane's remaining `_position_*` coordinates to that container tree"),
  so it is **flagged once here and not re-filed as new**; visually it costs the
  deck nothing today, but it is the only panel where a second worker cannot
  reproduce the layout, which is the exact failure the owner ruled A5.2 for.
- **No new T-160-class defect found.** Every `size_flags_vertical = 3` in the
  deck `.tscn` files sits on a container or an intended full-height frame
  (`launch_panel.tscn:111` HullFrame, `shipyard_panel.tscn:112` PreviewFrame —
  correct full-height plates). `shipyard_panel.tscn:243` (`QueueBody`, a Label
  at v=3) stretches harmlessly inside its scroll. The one flag that *does*
  work against the design is `FitLeftBox`'s `size_flags_vertical = 0`
  (`armory_panel.tscn:108`) — **F2**.
- No panel draws chrome over content in a `_draw` pass: the armory's `_draw`
  uses (`armory_panel.gd:438-848`) all draw recesses, plates and edge bevels
  inside their own cell/child rects — A5.2(iii)-legal. `overview_panel.gd:694-700`
  draws the faction ramp inside the identity block's own rect — legal.

## A3 — the token law

Clean. Every hex literal in the station UI lives in `tools/build_theme.gd`
(verified by grep over all ten panel `.gd` files and `station.gd`: no `Color("#…")`,
no raw RGB constructors outside token lookups; all `add_theme_color_override`
calls route through `_token`/`style.colour` — e.g. `exchange_panel.gd:677-682`,
`armory_panel.gd:2100-2104`). Two literal notes:

- `ui/screens/station.gd:531` — the confirm dialog's title sets
  `font_size 18` inline instead of a theme size token.
- `ui/screens/station.gd:982` — `GRAIN_IDLE_ALPHA` modulate alpha; legal
  (modulate-only, A5.5), noted for completeness, not a finding.

## A4 — consistency across panels

- **Action clusters differ in scale without a reason.** The shell pins the
  cluster at 360×56 `StationButton`s right-aligned in the foot band
  (§19.3, §8 P1) — exchange honours it (`exchange_panel.tscn:196-218`), but
  REFINERY's actions are a scattered mid-column cluster (QUEUE ALL / CANCEL /
  QUEUE 1 over LOAD / COLLECT ALL, `refinery_panel.tscn`) and ARMORY's pair
  sits right but at browser-row height, not in the foot band. Three decks,
  three action geographies. **F14.**
- **Four switch languages on one screen:** the armory's centred mode chips,
  the auction/armory family chip row, the shipyard's large HANGAR/BUILD/QUEUE/
  SCRAP plates, the services' full-width segment tabs. Mode vs filter vs
  service are different semantics, so the *count* is defensible — but the
  shipyard plates and the services segments share no visual DNA with the chip
  family (no shared height, corner or ink treatment). **F15 (LOW).**
- **Everything else holds:** pane headers (icon + title + subtitle at the same
  x/y), the AUCTION-idiom column band on exchange/refinery/armory/shipyard,
  row heights (~40 px armory/exchange, ~46 px refinery — within family rhythm),
  the footer hint slot, empty states (`NO JOBS QUEUED`, `LOAD ORE TO START A
  JOB`) and the shell bands are one voice across all eight decks.

## A5 — affordances

- **Selection is the screen's best affordance:** the 1 px ember ring marks the
  selected row/cell identically on auction (Lancer), exchange (Iron Ore),
  refinery (Iron) and the armory grid — unmistakable, and the only accent use,
  per STYLE_BIBLE §1.3. **A7 strength.**
- **Disabled reads as ghost, not as disabled** (**F7**, MED): the theme's
  disabled state is a flat `metal_dark`/`metal_dark` plate with `text_dim` ink
  (`build_theme.gd:317`, `:342`), and on the refinery render the `−`/`+`
  steppers and QUEUE row nearly vanish — the player cannot tell "cannot press"
  from "not there". S40's staged-row finding (1.61:1) is the same mechanism at
  the row scale; this is the control scale, filed separately.
- **Scroll affordance is effectively invisible** (**F9**, MED): the themed
  scrollbar is a thin `metal_mid` track with a `metal_light` grabber
  (`build_theme.gd:415-416`); on the full-res crops of the OVERVIEW, AUCTION
  and ARMORY browser right edges no grabber reads at 1080p, yet all three
  lists have content below the fold. A list that scrolls must show it.
- Hover states (glyph brighten, row bevel) and the two state channels
  (colour + bevel, A5.5/N24-legal) are consistent; the tab selected state
  (ember text + underline) is clear on both chip rows.
- The hover tooltip can cover the pane header when a top row is hovered
  (`tooltip.gd:117-127` clamps to the viewport, not below the header band)
  — **F16 (LOW)**: add a one-line flip guard against the 163 px header band
  in `_place`.

## A6 — findings table

| ID | Tier | Where | Evidence | Concrete change |
|---|---|---|---|---|
| F1 | HIGH | `overview_panel.tscn:34` / `overview_panel.gd:330-336` | INSURANCE + VAULTS rows below the fold, no visible scroll cue (render + full-res crop) | Give `BlockScroll`'s stack a bottom `size_flags_vertical = 3` spacer so services sit flush at the fold, and raise the scrollbar grabber to `metal_light` full-height with `metal_dark` track (token change in `build_theme.gd:415-416`) — or shorten the identity block by one line so all three service rows fit unscrolled |
| F2 | MED | `armory_panel.tscn:108` | `FitLeftBox` v=0 leaves the left sector's lower half raw BG-1 | Set `FitLeftBox` `size_flags_vertical = 3` (CellInfoBlock already v=3 and absorbs the slack); containers-only, no geometry number moves |
| F3 | MED | `armory_panel.gd:158-159, 3890` | Battery rows show `FITTED`/`OWNED ×n` under a COST header | In battery mode build the band as `STATE` / `HELD` (new const beside `BAND_COST`); the shared band builder takes the pair as an argument already |
| F4 | LOW | `armory_panel.gd:115, 164` | Two caption-only empty plates at the battery fold read as unfinished panels | Collapse each to its caption line height (`custom_minimum_size.y = 22`, the empty-cell line's own size) instead of a plated box; hide nothing (A5.5) |
| F5 | MED | `refinery_panel.gd:442` | Held and loaded ore share one VBox with no divider | Insert one `SectionHeader` row (`IN INPUT`) before the first loaded row, or give loaded rows the `chip_danger_bg`-free `ledge_bg` plate — one token-level distinction, colour not the only channel (the LOADED tag stays) |
| F6 | LOW | `exchange_panel.tscn` SALE column | ~450 px of dead backdrop under the quote line | Move the footer hint `THE STATION BUYS · IT DOES NOT SELL` into the SALE column's lower half as a `FlavourText` block, or let the quote strip `size_flags_vertical = 3` so the readout centres in the column |
| F7 | MED | `build_theme.gd:317, 342` | Disabled = `metal_dark` plate + `text_dim` ink; refinery steppers vanish | Give the disabled stylebox a 1 px `metal_mid` border (one line in the `_flat()` call) so a disabled control keeps a visible plate edge; ink change is S40's A1 territory, not re-filed |
| F8 | MED | `auction_panel.tscn:59` / auction shelf build | MODULES caption + band orphaned at the fold | Move the shelf section captions (HULLS / MODULES) into fixed chrome above `AuctionScroll` — the armory's `FITS W1 - W9` pattern — so the fold can only cut rows, never a header |
| F9 | MED | `build_theme.gd:415-416`; all scrolls | Scrollbar track/grabber do not read on any render at 1080p | Grabber `metal_light` → `text_meta`, track gets a 1 px `metal_dark` border, minimum grabber height 48 px (theme-only change, every deck benefits) |
| F10 | LOW | `shipyard_panel.gd` preview fit | ~150 px sprite centred in a ~560×430 frame | Scale the preview to a fixed fraction of `PreviewFrame` (e.g. `custom_minimum_size` = 60 % of the box, `STRETCH_KEEP_ASPECT_CENTERED`) so the hull owns the frame |
| F11 | LOW | `launch_panel.tscn:153`, `launch_panel.gd:155, 157` | Three caption sources compete in the foot region | Drop `BRIEF_NOTE` into the briefing column's last row (it is cargo commentary, not foot-band text) and keep the foot band to footer + confirm line |
| F12 | LOW | `contracts_panel.tscn:121` + `station.gd:1176` | `ONE SERVICE AT A TIME · ESC BACK` renders twice on the deck | Delete the shell's `SERVICES_HINT` line (the pane's own `%PaneHint` already carries it) — one source of the words |
| F13 | MED | `contracts_panel.gd:320-375` | Active card: CANCEL chip crowds the reward/escrow stack in `ROW_HEIGHT` | Widen active cards to two stack rows (head + one action row carrying escrow summary + CANCEL right-aligned) — container children only |
| F14 | MED | `refinery_panel.tscn` action block; `armory_panel.gd` actions | Three action geographies vs the shell's pinned right-aligned foot cluster | REFINERY: move QUEUE/LOAD/COLLECT into the `PaneFoot` cluster (P1 sizes, `REFINE N` primary rightmost); ARMORY: same foot-band home on both modes |
| F15 | LOW | `shipyard_panel.tscn:73-99`, `contracts_panel.tscn` tabs | Switch languages share no visual family | Give the shipyard plates and the services segments the chip row's height (32) and ink treatment; keep the counts |
| F16 | LOW | `tooltip.gd:117-127` | Tooltip may cover the pane header band on top-row hovers | In `_place`, flip below the cursor when `pos.y < 163` (the header band bottom) before the viewport clamp |

## A7 — what already works

1. **The ember-ring selection language.** One accent colour, one meaning, the
   same 1 px ring on every deck's selected row, cell and armed LAUNCH plate.
   The player learns "orange outline = this is the one" once and it holds
   everywhere — exactly STYLE_BIBLE §1.3's discipline doing compositional work.
2. **The AUCTION-idiom column-header band.** Caption cells seated exactly over
   their right-aligned value columns, reused on EXCHANGE, REFINERY, ARMORY and
   the SHIPYARD comparison table. It is the single biggest reason the dense
   decks read as tables rather than text walls.
3. **The one skeleton.** Header band / pane frame / foot band, with every pane
   opening icon + title + subtitle at the same anchor and the footer hint in
   the same slot. Eight decks feel like one screen because the bones never
   move; the per-deck variations above are fittings, not fractures.
