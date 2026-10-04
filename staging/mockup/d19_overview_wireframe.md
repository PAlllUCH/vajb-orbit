# D19-A1 mockup — the OVERVIEW pane (wireframe)

Design law: `docs/design/STATION_HUB.md` §18 P18 + §19 (this wave's detail) +
`docs/design/UI_SPEC.md` §3.10 A5.1–A5.5 and §8. Wireframe, not a rendered
plate: sizes schematic, ruled numbers in the law blocks (§19.1–§19.4). The pane
wears the P7 skeleton — `PaneHeader` / content split / action cluster / shared
footer hint — and its split carries P18's five blocks.

```
+==========================================================================+
|| [o] OVERVIEW                                                       [1] ||
||                                                                          ||
|| +--------------------------------------------------------------------+  ||
|| | (o) HALCYON ANCHORAGE                                     [2]      |  ||
|| | forge-grey bastion, the full menu                                  |  ||
|| +--------------------------------------------------------------------+  ||
|| | +----------------+ +--------------------------+ +----------------+|  ||
|| | | [w] ARMORY     | | [o] REFINERY             | | [c] EXCHANGE   ||  ||
|| | | BUY, FIT AND.. | | 3 ORE = 1 INGOT          | | SELL YOUR HOLD ||  ||
|| | +----------------+ +--------------------------+ +----------------+|  | [3]
|| | | [c] AUCTION    | | [h] SHIPYARD             | | [r] LAUNCH     ||  ||
|| | | HOUSE SHELF .. | |HULLS, MODULES AND REPAIRS| | BRIEF, CARGO.. ||  ||
|| | +----------------> +--------------------------> +---------------->|  ||
|| +--------------------------------------------------------------------+  ||
|| | ACTIVE HULL                                       [ REPAIR > ]    |  | [4][5]
|| | LANCER — LIGHT FIGHTER CLASS · 1000 HULL · 8 SLOTS                  |  ||
|| | HULL 200 / 1000 · SHIELD 300 / 600 · CARGO 35 / 40                 |  ||
|| | REPAIR AVAILABLE · 500 CR                                           |  ||
|| +--------------------------------------------------------------------+  ||
|| | [ic] CONTRACTS        ACTIVE CONTRACTS 2/3            [ OPEN > ]   |  | [6]
|| | [ic] INSURANCE        INSURED · COVERS ONE LOSS       [ OPEN > ]   |  ||
|| | [ic] VAULTS           THIS VAULT — 12 / 40 UNITS      [ OPEN > ]   |  ||
|| +--------------------------------------------------------------------+  ||
|| | THE DOCK CLAMPS ARE CHEAP. THE AMMUNITION IS NOT.            [7]   |  ||
||+------------------------------------------------------------------------+|
|| PICK A TILE TO CHANGE DECKS                                        [8]  ||
+==========================================================================+
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | `PaneHeader` — glyph 40 + `StationPanelTitle` 20 at the shared x 129 | none (type) | §19.3's skeleton row | P28, P31 |
| 2 | identity block — §15.5's name plate stretched to block width | A5.4-1 (flat Tokens box, faction ramp) | §19.1 row 1; §15.5 (U17/W3) | P18 |
| 3 | department tiles — `GridContainer` 3 columns, min 300×140, row-major drawer order; glyph 48 + `SectionHeader` 16 + one caption line + a chevron mark | theme `panel_raised` flat bevel (UI_SPEC §2.1 — the `ui_panel_frame` band is barred in-pane, A5.1/Q1) | §19.2; glyphs = `MODULE_ICONS` (`station.gd:91-98`) until the staged tile masters (§19.7) | P18, P23 |
| 4 | active-hull + repair block — caption, name + meta, the labelled pairs, the repair summary | A5.4-3 caption + fixed label/value cells | `shipyard_panel.gd:74-84`, `repairs_panel.gd:50,52` | P18, P24 |
| 5 | `REPAIR >` — §8 `ActionInline`, deep-links to SHIPYARD (active hull selected, `REPAIR` focused) | flat chip | P18's own words (`REPAIR →`); the arrow is a drawn chevron mark | P24, P30 |
| 6 | services rows — §3.1's 76-tall row idiom (icon 24 + name + right-aligned readout + `OPEN >`) | A5.4-4 flat `item_bg` + 1 px `metal_mid` | `icon_service_insurance/vault.svg` (ASSET_CATALOG.md:392-393), `icon_contract_haul.svg` interim (P25); readouts U6/U10/U16 | P25, P26 |
| 7 | flavour line | A5.4-3 caption idiom | verbatim in §19.5 (P27) | P27 |
| 8 | foot band — hint left (N24's 18 px reserved slot) + the cluster right (empty here, band kept) | `StationCaption` 13 | §19.3's skeleton rows | P28, P29 |

Overflow law (P22): the block stack sits in a vertical `ScrollContainer` — the
minima sum ≈ 776 against the split's 633 at 16:9/21:9 — and fits unscrolled at
4:3, where §3.3 gives the body 360 px more.
