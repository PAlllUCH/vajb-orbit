# D16-A1 mockup — CONTRACTS panel (wireframe)

Design law: `docs/design/STATION_HUB.md` §15.2 + `docs/design/UI_SPEC.md` §7
(A5.4 rows). Composition = A5.2 (containers/anchors only, no coordinates);
content = `docs/gameplay/14_station_services.md` §2 verbatim (examples and
reward shapes are the pin's own lines). Wireframes, not rendered plates: the
wave is design-only (no render script). Sizes schematic; ruled numbers live in
the law blocks.

## The pane (SERVICES → CONTRACTS), module host content box

```
+=========================================================+=========================================+
|  TYPE     OBJECTIVE                  REWARD     FACTION |  ACTIVE CONTRACTS 2/3                   | [1]
|  THE BOARD PAYS OVER THE EXCHANGE'S BUY PRICE — GOODS   |  +-------------------------------------+|
|  LOCK INTO ESCROW AT ACCEPT · CANCEL FEE 100 CR         |  | [H] HAUL                            || [5]
|  +---------------------------------------------------+ |  | 40× ingot_titanium to S4 outpost    ||
|  | [H] HAUL  40× ingot_titanium to S4 outpost        | |  | spot ×1.25 + 300 CR · +2 standing   ||
|  |           spot ×1.25 + 300 CR · +2 st   (C) [ACCEPT] |  | ESCROW — RESERVED FROM YOUR HOLD    || [6]
|  +---------------------------------------------------+ |  | 40× ingot_titanium · RESERVED       ||
|  | [Hu] HUNT  Destroy 5 pirates in S2                | |  |              [CANCEL · 100 CR FEE] || [7]
|  |            800 CR + loot as normal · +1 st/kill (M)[ACCEPT] +-------------------------------------+|
|  +---------------------------------------------------+ |  | [E] ESCORT                          ||
|  | [G] GATHER 20× mineral_cobalt ore (raw)           | |  | Protect convoy 7 to S4 gate         ||
|  |            ×1.4 ore value · +2 st       (C) [ACCEPT] |  | 1 200 CR · +5 standing              ||
|  +---------------------------------------------------+ |  |  NO ESCROW (hunts/escorts lock none)|| [6]
|  | [E] ESCORT Protect convoy 7 to S4 gate            | |  |              [CANCEL · 100 CR FEE] ||
|  |            1 200 CR · +5 standing       (M)[ACCEPT] |  +-------------------------------------+|
|  +---------------------------------------------------+ |                                         |
|  | [H] HAUL  40× ingot_titanium to S4 outpost        | |                                         |
|  |           spot ×1.25 + 300 CR · +2 st   (C) [ACCEPT] |                                         |
|  +---------------------------------------------------+ |                                         |
|  | [X] EXPEDITION  arena contract                    | |                                         |
|  |             arena payout · +3 standing  (Ch) ·····| |                                         | [4]
|  |   [STAGED]  arenas arrive with S26                | |                                         |
|  +---------------------------------------------------+ |                                         |
+=========================================================+=========================================+
```

(`(C)`/`(M)`/`(Ch)` stand for the 24 px faction glyph + name cell; icons `[H]`
`[Hu]` `[G]` `[E]` `[X]` are the five `icon_contract_*` masters at 24.)

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | header strip `TYPE`/`OBJECTIVE`/`REWARD`/`FACTION` + the over-exchange/escrow/fee note | A5.4-3 caption strip | theme `SectionHeader` 16 / `StationCaption` 13; 14 §2:47-49 | U3 |
| 2 | board rows (76 tall, `RowInner` 12/8; type icon + name, objective verbatim, reward right-aligned 220, faction glyph 24 + name 130) | A5.4-4 flat Tokens `item_bg` + 1 px `metal_mid` | `icon_contract_*.svg` (ASSET_CATALOG.md:293-297), `icon_insignia_*` (:332-334); 14 §2 type table | — |
| 3 | `ACCEPT` pressable per open row | A5.4 `Pressables` | `ui_button_plate_*` (ASSET_CATALOG.md:437) | U4 |
| 4 | Expedition row: whole row `button_disabled`/`text_dim`, chip `STAGED`, caption `arenas arrive with S26` | A5.4-4 + `State chips` | `icon_contract_expedition.svg` (:294) at `text_dim`; 14 §2 + R-S25-1 seam | U7 |
| 5 | active-contract card: row anatomy + escrow readout `ESCROW — RESERVED FROM YOUR HOLD` + one `… · RESERVED` line per locked stack | A5.4-4 | 14 §2:48-49 | U5 |
| 6 | hunts/escorts lock nothing — the card says so in `StationCaption` (no escrow line) | theme caption | 14 §2 (escrow applies to goods) | U5 |
| 7 | `CANCEL · 100 CR FEE` — the fee at the decision point | A5.4 `Pressables` | `ui_button_plate_*`; 14 §2:49 | U4 |

## State variants (same chrome, different state)

```
MAX 3 (U6): every [ACCEPT] becomes disabled + chip:        CONFIRM (U4, §5.2 dialog idiom):
+---------------------------------------------------+     +------------------------------------+
| [G] GATHER 20× mineral_cobalt ore (raw)           |     | CANCEL THIS CONTRACT?              |
|            ×1.4 ore value · +2 st   (C) [········]|     | — 100 CR FEE · THE RESERVED        |
|            [MAX 3 ACTIVE]                          |     |   GOODS UNLOCK.                    |
+---------------------------------------------------+     |            [CANCEL]  [CONFIRM]     |
counter on the right column head reads ACTIVE CONTRACTS 3/3 +------------------------------------+

EMPTY BOARD (U8): one StationCaption on the empty list:
  "NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK"
  standing-gated instead: "REDEMPTION MUST PRECEDE EMPLOYMENT"   (14 §2:50-51 verbatim)
```

Every hover text routes through the A4.4 shell inspector pin (constant-height
inspector, two body lines max).
