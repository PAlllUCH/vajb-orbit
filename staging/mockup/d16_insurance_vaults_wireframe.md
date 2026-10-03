# D16-A1 mockup — INSURANCE and VAULTS panels (wireframe)

Design law: `docs/design/STATION_HUB.md` §15.3/§15.4 + `docs/design/UI_SPEC.md`
§7 (A5.4 rows). Content = `docs/gameplay/14_station_services.md` §3/§4/§1/§8
verbatim (premiums, rules and character lines are the pin's own). Wireframes,
not rendered plates (design-only wave). Sizes schematic.

## INSURANCE panel (SERVICES → INSURANCE)

```
+=========================================================+=========================================+
|  HULL CLASS                PREMIUM PER LAUNCH           |  POLICY                                 | [1]
|  +---------------------------------------------------+ |  +-------------------------------------+|
|  | FIGHTER                            200            | |  | [UNINSURED]                         || [2]
|  | CUTTER                     [YOUR CLASS] 250        | |  +-------------------------------------+|
|  | DELVER / TRADER / CORVETTE             300         | |  THE PAYOUT COVERS ONE LOSS · THE      |
|  | HAULER / GUNSHIP                       400         | |  POLICY DOES NOT RENEW MID-FLIGHT      | [3]
|  | FRIGATE                                500         | |                                        |
|  | DESTROYER                              700         | |  [MERCY AVAILABLE]                     | [4]
|  +---------------------------------------------------+ |  mercy clause: if you have no other     |
|  Champion standing multiplies the premium ×0.8         |  |  hull, the Concord reissues a bare    |
|                                                       |  |  Fighter — once per profile           |
|                                                       |  +-------------------------------------+
|                                                       |  | UNINSURED LOSS: HULL AND ALL        | | [5]
|                                                       |  | INSTALLED MODULES ARE GONE          | |
|                                                       |  +-------------------------------------+
|                                                       |  [INSURE LAUNCHES]                      | [6]
|                                                       |  PREMIUM 250 CR PER LAUNCH · CHARGED    |
|                                                       |  AT LAUNCH                              |
+=========================================================+=========================================+
```

## VAULTS panel (SERVICES → VAULTS)

```
+================================================================================================+
|  TIER ROWS                                                     (band one, full-width rows)     |
|  +---------------------------------------------------+ +-------------------------------------+|
|  | TIER 1 · +20 UNITS · 500 CR              [RENT]   | | TIER 2 · +20 UNITS · 1 200 CR  [···]||
|  +---------------------------------------------------+ +-------------------------------------+|
|  | TIER 3 · +20 UNITS · 2 400 CR              [···]   |   totals 40 / 60 / 80 units (PROPOSED)|
|  +---------------------------------------------------+ +-------------------------------------+|
+================================================================================================+
|  YOUR HOLD                     |  VAULT CONTENTS [NOT CARGO]                       12 / 40 UNITS | [7][8][9]
|  +-----------------------------+  +----------------------------------------------------------+ |
|  | 60× mineral_cobalt ore      |  | 40× ingot_titanium                                       | |
|  | 12× comp_scrap_3            |  |  8× mineral_cobalt ore                                   | |
|  | 40× ingot_titanium          |  |                                                          | |
|  +-----------------------------+  +----------------------------------------------------------+ |
|  [DEPOSIT]                       [WITHDRAW]                                                    | [9]
|  DEPOSITS AND WITHDRAWALS ARE FREE                                                              |
|  VAULT CONTENTS DO NOT COUNT AGAINST CARGO ON LAUNCH                                            | [8]
|  CONTENTS PERSIST PER-STATION — THE VAULT IS FURNITURE, NOT A POCKET                             |
+================================================================================================+
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | premium rows (six, 14 §3's table verbatim; `YOUR CLASS` chip on the player's row) + `Champion standing multiplies the premium ×0.8` note | A5.4-4 flat Tokens `item_bg` + 1 px `metal_mid` | theme `StationCaption`; 14 §3:60-70 | U9 |
| 2 | policy state chips `UNINSURED` → `INSURED · COVERS ONE LOSS` → `PAID OUT · POLICY SPENT` | A5.4 `State chips` (label + 1 px frame) | theme `chip_bg`; 14 §3:74-75 | U10 |
| 3 | one-death line (pin words) | theme `StationCaption` | 14 §3:74-75 | U10 |
| 4 | mercy chips `MERCY AVAILABLE` / `MERCY USED` + the pin's mercy sentence | A5.4 `State chips` | 14 §3:78-80, §9:150 | U11 |
| 5 | loss warning danger row (1 px `accent_danger` frame — a loss alert, ember legal) | §3.1/§3.1b danger row | 14 §3:71-73 | U12 |
| 6 | `INSURE LAUNCHES` / `CANCEL POLICY` toggle + `PREMIUM %d CR PER LAUNCH · CHARGED AT LAUNCH` | A5.4 `Pressables` + `StationValue` | `ui_button_plate_*` (ASSET_CATALOG.md:437); 14 §3:57 | U13 |
| 7 | tier rows `TIER n · +20 UNITS · %d CR` + `RENT`/`OWNED` (totals **PROPOSED** 40/60/80, reversal 20/40/60) | A5.4-4 + `Pressables` | 14 §4:85-87 | U14 |
| 8 | `NOT CARGO` chip + the two pin captions under the contents split | A5.4 `State chips` | 14 §4:92-94 | U15 |
| 9 | contents split `YOUR HOLD` / `VAULT CONTENTS` (`ItemList`s) + `DEPOSIT` / `WITHDRAW` + `THIS VAULT — %d / %d UNITS` | A5.4-5 lists + `Pressables` | §3.1 `CargoList` idiom; 14 §4:90-93 | U15, U16 |

## State variants (same chrome, different state)

```
MERIDIAN STATION (U14): tier rows read 625 / 1 500 / 3 000 (derived ×1.25) and
carry the pin's line under them:
  "Meridian's stations rent 40-unit vaults and the rental tiers cost 25 % more
   (they know what a vault is worth)."                       (14 §4:88-89 verbatim)

CHOIR STATION (U2): the INSURANCE strip button is disabled and the reason
caption under the strip reads: "the Choir does not believe in accidents" (14 §1).
OUTPOST (U2/U16): insurance reason: "fly to a capital" (14 §8); vault tiers 2/3
grey with caption "tier 1 only — this is an outpost".

ONE-DEATH STATES (U10), left to right, all label + frame, never colour alone:
  [UNINSURED]  ->  [INSURED · COVERS ONE LOSS]  ->  [PAID OUT · POLICY SPENT]
MERCY STATES (U11): [MERCY AVAILABLE] / [MERCY USED] — once per profile.
```
