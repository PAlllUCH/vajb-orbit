# Button / panel background candidates — the item-1 search record (2026-10-05)

Owner ask verbatim: "in overview. lets look for new backgrounds for the
buttons. these ones dont look good. search in the assets first." Follow-up
ruling the same day: "The problem is that the panels used are stretched out of
proportion. we can run a full redesign with different aspect ratios … this
would unify the panels in all the game" — regenerate ALL UI panels, style
anchors `ui_cockpit_panel`, `panel_cockpit`, `panel_armory(_plates)`,
`panel_status`, the main-menu chromes; different aspect ratios "respected
always"; a few unique backgrounds for the station panels; scope = whole game.

## What the search found (asset-library/INDEX.md + the project's `assets/ui/`)

Complete button state sets (the only ones in the library):

| File (`vajb-orbit/assets/ui/`) | True pixels | Aspect | Library description |
|---|---|---|---|
| `ui_button_plate_normal.png` | 280×56 | 5:1 bar | "metal button plate, weathered riveted dark metal bar" (panel_button_plates 1/4) |
| `ui_button_plate_hover.png` | 280×56 | 5:1 | "rusted metal horizontal bar" (2/4) |
| `ui_button_plate_pressed.png` | 280×56 | 5:1 | "pressed dark metal plate" (3/4) |
| `ui_button_plate_disabled.png` | 280×56 | 5:1 | "wide rusty metal bar" (4/4) |

Measured with `file` (2026-10-05) — the shipped plates are true 5:1 bars; the
ASSET_CATALOG 280×56 record is right and `INDEX.md:122-125`'s 1041×1087 is
the library-side cut before downscale. So the fault the owner diagnosed is
**use-aspect mismatch**: a 5:1 bar stretched into the 15:7 tile (`TILE_MIN`
300×140, `overview_panel.gd:48`) smears its rivets and bevel. The same
measurement set: `ui_cockpit_panel` 928×512, `ui_armory_console` 2720×1032
(= the 1360×516 console at @2×), `ui_status_panel` 1440×1040,
`ui_armory_row_plate` 192×64, `ui_armory_rack_plate` 194×182,
`ui_cockpit_frame` 192×192, `ui_panel_frame` 96×96.

Other chrome in play (already shipped): `ui_armory_console`,
`ui_armory_rack_plate`, `ui_armory_row_plate`, `ui_status_panel`,
`ui_cockpit_frame`, `ui_cockpit_panel`, `ui_panel_frame`,
`ui_bar_caps(+alt)`, `ui_minimap_bezel`, `ui_slot_{cargo,inventory,weapon}` ×
4 states (square — the one family whose aspect matches its use),
`ui_backdrop_{hangar,login,starmap}`, `ui_gauge_face`, `ui_compass_*`,
`logo_vajb_orbit`, `ui_readout_glass` (per UI_CHROME_ASSETS_SPEC §11).

Style anchors the owner named → resolution: `ui_cockpit_panel`,
`ui_cockpit_frame`, `ui_armory_console`, `ui_armory_rack_plate`,
`ui_armory_row_plate`, `ui_status_panel` all resolve to the files above and
are documented in `docs/design/UI_CHROME_ASSETS_SPEC.md` §11–§12 (waves
D6/D7, with prompt recipes + the ≥95 % ink-box QC law); `panel_cockpit`,
`panel_armory(_plates)`, `panel_status` name **source sheets** in the
library's own words (`panel_status` = INDEX:289 "metal icon status game
sheet"); the "main menu chromes" = the nine-patch family (UI_SPEC §5) +
`ui_backdrop_login`/`ui_panel_frame`. D21-A1 confirms each anchor's record in
the `UI_CHROME_ASSETS_SPEC.md` amendment; anything unresolved gets the two
nearest candidates on the owner's review sheet.

## Verdict

The tiles' fault is proportion, not art: 5:1 bars stretched into 15:7 tiles
(and square frames stretched into whatever needs them) smear every rivet —
"stretched out of proportion" exactly. Nine-slice can only save the middle
band (UI_SPEC §14 N51). The owner's ruling — regenerate the whole family at
true per-class aspects — is the correct fix and the unifier; the
`ui_button_plate_*` set stays the documented fallback (N50/N51 superseded
pre-dispatch, UI_SPEC §14's closing note). Waves: **D21** (family spec +
generation prompts) → owner review sheet → **S35** (re-skin every panel).
