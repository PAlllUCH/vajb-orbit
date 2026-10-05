# S36 proposal — the chrome re-skin: keep-list + swap map (2026-10-05)

Owner's ruling, verbatim: "keep the chromes from main menu, terminal side
panel, CANCEL, SELL buttons, all the ones that are native not stretched look
good. rest is up to you or worker you spawn, suggest then we will work with
it." — the criterion is the owner's own: **every surface whose chrome is
native (drawn at its own aspect) keeps it; only the stretched surfaces move
onto the generated family** (16/16 aspect-verified renders,
`asset-library/_review/chrome_family_2026-10-05.png`, `D21-G1_report.md`).

## The keep-list (named by the owner + everything native)

| Surface | Status |
|---|---|
| Main menu buttons + its backdrop chrome | **keep** (owner) |
| TERMINAL side panel (drawer surface + its entries as one unit) | **keep** (owner) |
| `CANCEL` / `SELL` pressables (P1/P2 plates at their own size) | **keep** (owner) |
| `ui_cockpit_panel` / `ui_status_panel` faces | keep (aspect-matched, D21-A1/F1) |
| `ui_slot_*` faces (48/40 square controls) | keep (square at square use) |
| HUD bar caps + minimap bezel (fixed-size) | keep |
| Shell backdrop `ui_backdrop_hangar` (full-bleed cover-fit) | keep |
| Dialog frames whose plate matches their use | keep (per-census check) |

## The swap-map (stretched surfaces → the generated class plates)

| Surface family | Class plate | Notes |
|---|---|---|
| OVERVIEW tiles (~567×140 drawn) | C1 `ui_tile_slab` | crop-to-master at the drawn aspect |
| Data/service row strips (exchange, board, armory lists, settings) | C4 `ui_row_strip` | band h 320–1765 |
| Armory console face + rack bay cards | C6 + C5 | C6 orders the 4K master |
| Inline chips beyond the keep-list (`INSPECT`, mode switch, MAX/0) | C3 `ui_inline_chip` | |
| Action bars beyond the keep-list (`BUY`, `REPAIR`, `QUEUE…`) | C2 `ui_action_bar` | SELL/CANCEL stay native |
| Tooltip frame | C7 `ui_tooltip_frame` | the 360 cap is N47's |
| Pane frames (9-slice, 96×96 masters) | C12 `ui_panel_frame` | reversal: keep the shipped frame |
| Station pane backdrops (new layer, 1765×753 cover-fit) | BG-1 ARMORY · BG-2 REFINERY · BG-3 EXCHANGE+AUCTION · BG-4 SHIPYARD+LAUNCH+OVERVIEW | additive — conflicts with nothing |
| Drawer entry plate | C9 `ui_drawer_entry` (272×56, T-135) | **held as spare** while the terminal side panel stays native |

C2/C8/C11/C12 renders returned opaque — the free local key fallback keys them
at the cut stage (G1's follow-up; no re-run owed).

## Open calls (owner's eye)

1. Drawer entries: stay with the terminal side panel (default) or swap to the
   C9 plate at 272×56?
2. `MENU_TABS` reads `POWER` (S35-B1: supersedes the EQ's `PWR/FUEL RODS`) —
   keep the word or restore `PWR/FUEL RODS`?
3. The exchange TradeBox grows 360 → 393 px for the MAX/0 chips (measured) —
   accept or shrink the chips?
4. State variants (≤ 6 runs, ≤ $0.30) stay un-purchased until cut-stage QC
   says modulate cannot carry hover/pressed.

## The two waves

1. **D21-G2 (cut/key/center)** — `hyper/glm-5.3-flash` @ max (the owner's
   image-lane assignment): crop-to-master per §13.1's uniform rule, key the
   four opaque plates, `center_check --apply`, margins measured per §15.3,
   into `vajb-orbit/assets/ui/` under the §13.4 stems + a contact sheet for
   the owner's eye before wiring.
2. **S36 (wire)** — `hyper/deepseek-v4.1-flash` @ xhigh: `StyleBoxTexture`
   per class with the §15.3 margins, the BG-1..4 backdrop nodes, the
   keep-list untouched, plus a chrome-census regression suite (per-class
   aspect at use + no-smear bands). R1 (`hyper/glm-5.3-flash` @ max)
   re-measures; F1 only on HIGH/MED.

Reversal for the whole pass: the keep-list grows to "keep everything shipped"
and the family retires (the renders stay in `asset-library/raw/`).
