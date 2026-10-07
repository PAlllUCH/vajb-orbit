---
slice: S29
reviewer: S29-R1
verdict: blocked (one HIGH remains; otherwise pass)
gate: "1038/0 → 1073/0 (B1 ×2) → 1073/0 (B2 ×2); R1 fresh-scratch re-run [SUMMARY] passed=1073 failed=0"
---

# S29-R1 review

Graded against `S29_BRIEF.md` §5, `UI_SPEC.md` §9, §10 and §8, `STATION_HUB.md`
§16/§17 and §3.10 A5.1–A5.4 — never against the builders' reports. Every code
site was re-read from the working-tree diff, the law sections re-read by range,
and the gate re-run once on fresh scratch (`XDG_DATA_HOME=$(mktemp -d)`,
`~/.local/bin/godot`, log `/tmp/s29_r1_gate1.log`). The mid-wave provider switch
(glm-5.3 → xiaomi/mimo-v2.6-pro for the resume + B2) was discounted: the code is
graded, not the model.

## Acceptance list

- **A1** — pass — N1's 80 % pane rides anchors `.1….9` on `PanelRaised`
  (`ui_panel_frame`, `vajb_theme.tres:457-458`), no offsets (`map_deck.gd:107-114`);
  three toggle routes (M + raw fallback `map_deck.gd:486-490`, corner EXPAND
  `hud.tscn:429` 36×36, ESC `game.gd:947-956`); N2 wheel 25–400 % cursor-centred
  (`minimap.gd:326-336`, clamp `:69-70`) and 64 px arrows (`map_deck.gd:69,137-147`);
  N3's eight rows with ON/OFF label + state (`map_deck.gd:289-303,370-375`),
  persisted per profile (`map_deck.gd:505-534`); the §10 toggle→class table
  verbatim incl. N19's ghost and N20's swarmer rides (`minimap.gd:205-215`);
  N23 inert + N6 exempt as one predicate (`minimap.gd:241-249`), the station/gate
  emitters re-anchored (`sector.gd:279-283`); deck chrome on the A5.4 pane /
  A5.4-2 row / A5.4-3 foot rows (`map_deck.gd:222-324`); the D8-H3 12 px-floor
  label substitution is measured and disclosed, not invented.
- **A2** — pass on the fixer's three rows — press-down hit-tests the pin first and
  a hit is a remove candidate, never a place or move (`map_deck.gd:428-431`); the
  pin is placed at press-down and never follows the cursor — the pan leaves it
  (`map_deck.gd:432-434`, pan branch `:410-416`); held move past 8 px is a pan
  (`DRAG_THRESHOLD_PX = 8.0`, `:70,412`); short press orders the existing API
  (`game.gd:2341-2345` → `set_move_target`), remove cancels (`game.gd:2348-2352`);
  stick-cancel untouched (`player_ship.gd:848` region, no diff there); hold ≥ 0.5 s
  armed from press-down on fresh and existing pin alike (`map_deck.gd:150-160`);
  `NO HYPERDRIVE INSTALLED` under the pin (`game.gd:2361-2365`,
  `minimap.gd:358-366`); N11–N13 reads verbatim (`game.gd:139-145`); compact
  bearing arrow + `DIST <n>` on the SectorLabel line (`minimap.gd:407-449`;
  `hud.gd:1936-1941`). Findings F1/F2 below.
- **A3** — pass — `e_hyperdrive` carries R-S29-1 by figure: tier 3, slot `engine`,
  12 000 CR, draw 3, effects empty (`module_catalog.gd:593-602`); the clocks live
  flight-side at the same figures (`game.gd:133-134`: 1 s / 30 s, no fuel term);
  the AUCTION's engine column carries it through the tier pools the catalogue
  partition test already proves cover every non-exclusive row
  (`test_s3_auction.gd:385-404`), pinned new at `test_s29_hyperdrive.gd:110`;
  the glyph reuses `e_vector` (no new art).
- **A4** — pass — the split is containers end to end (`armory_panel.tscn`:
  `Split` HBox → `GridHalf` / `BrowserHalf` min 420, `SlotLayoutGrid`
  GridContainer, `BrowserScroll`); the grid keeps FITTING's own numbers (48 px
  `SlotButtonWeapon` plates, sep 4, glyph inset 6, `SLOT LAYOUT` caption,
  `armory_panel.gd:217-221`); the tab strip is the nine families minus HULLS
  (`:193-203`); every row drags (`BrowserRow._get_drag_data`, `:434-441`); drops
  filter by slot with the refusal as words + the 0.5 s caption flash, never colour
  alone (`cell_drop`/`_refuse_drop`/`_flash_slot_caption`, `:3482-3520`, P9/P10
  verbatim); the buy flow checks credits first (`_fit_entry_at`:
  fit_legal → credits → buy_module → fit_module_at, `:3328-3350`); hover routes
  through the existing `inspect_requested`/`Catalog.describe` chain
  (`:3774-3782`, the auction's own idiom).
- **A5** — pass — labelled stat pairs HULL/SHIELD/CARGO/ENGINES/SLOT CELLS
  (`shipyard_panel.gd:94-100`); the comparison block with the disclosed PROPOSED
  delta column (`:101-107`); the selected hull's installed modules under P12's
  caption (`INSTALLED_CAPTION :109`, the `%HardpointCaption` grid); the repair
  body is REPORT_ROWS minus `missing`/`fee` with `NOMINAL` in `text_dim`
  (`_build_repair_rows`/`_refresh_repair`, `:1226-1330`, P13); the fee lives only
  in the footer line via the shipped wordings (`:1335-1349`,
  `repairs_panel.gd:50-53`); `REPAIR` is the 360×56 primary rightmost, `SET
  ACTIVE` its secondary, all-nominal disabled + `text_dim`
  (`shipyard_panel.tscn:163-187`); hover on hull rows, plates and damage rows
  through the chain (`:1262-1270`).
- **A6** — pass — the rail folds 8 → 6 with the icons and beds moving together
  (`station.gd:67-101`: ARMORY keeps `icon_equip_module.png`, SHIPYARD
  `icon_hull.svg`); both merged panes keep exactly one `PaneHeader` and carry the
  P2 cluster as an HBox with the 16 px gutter and the primary rightmost
  (`armory_panel.tscn:209-233`, `shipyard_panel.tscn:164-187`); every action
  button is the 360×56 `StationButton` Pressables token (`vajb_theme.tres:499-508`
  = `ui_button_plate_*`), the row-corner BUY the 96×32 inline chip
  (`armory_panel.gd:212,3694-3700`); the P6 fills ship on both panes
  (`shipyard_panel.gd:1060-1071`, `launch_panel.gd:227-229`).
- **A7** — pass — no `DROP HERE` ghost is drawn on any empty cell
  (`_build_drop_cell` is the bare recess, `armory_panel.gd:2081-2092`; the moved
  rows in test_d7/test_p2b1/test_s18 now assert no cue); fit confirm `FITTED ·
  <MODULE>` (P11, `:249`) with the shipped refusal wordings; cell tooltips name
  the cell (`cell_tooltip`, `:3215,3139`) and the meter renames CANDIDATE →
  `IF FITTED` (`:236`); the comparison carries deltas (`+0` on self-compare);
  the REPAIRS dead band is resolved (one right-column stack + footer + cluster,
  no spacer rows in the tscn); scroll affordances are `BrowserScroll` and
  `BodyScroll` (A5.2 containers). Leftover dead code → F6.
- **A8** — pass — gate re-run on fresh scratch: `[SUMMARY] passed=1073 failed=0`
  (1409 log lines, the exit RID-leak warning is the benign one). Every moved test
  row in the diff is disclosed in the two reports with suite and line; I checked
  all nine moved suites' diffs against the disclosures and found no undisclosed
  row (`test_d11:98`, `test_engine2:295+`, `test_s6:579+`, `test_s17:246+`,
  `test_ship_grids:90,856+`, `test_d7`, `test_p2b1`, `test_s18`,
  `test_s11_describe/inspector`, `test_s20:430`, `test_p2b_fitting`,
  `test_s21:906+`). No file outside the declared union moved: the 26 modified
  paths all sit in `ui/hud/`, `game/`, `ui/screens/`, `ui/station/`, `tests/`;
  docs and `assets/` are untouched. (`staging/compare/` is Sep-25 litter and
  `D17-P3_report.md` is the D17 wave's file — neither is S29 output; the
  orchestrator should not sweep them into the wave commit.)

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S29-B1/F1 | HIGH | `ui/hud/minimap.gd:600-623` | The pin's two marks draw `Color.WHITE`: `PinDiamond.colour` and `EdgeArrow.colour` are never assigned (`_build_pin_marks`, `:389-412`, sets only radius/length), while §10 pins the diamond "in `text_primary` at 6 px" (reversal `accent_ember`) — `text_primary` is `#c9d1dc` (`vajb_theme.tres:560`), not white; the class's own doc comment claims the token. A pinned-value drift. | S29-F1 |
| S29-B1/F2 | MED | `game.gd:947-956` | The disclosed ESC seam leaves a desync: an ESC that opens the deck runs §9.9's `cancel_orders` but not the pin's removal, so the deck reopens showing a pin whose order is dead (double-ESC kills the order the player placed from the map). Bucket-2 flagged and the law is self-contradictory (§9.9 vs N1); needs the owner ruling plus the one-line cure (clear the pin when the ESC-open cancels, or do not cancel on open). | Owner via designer; fixer after the ruling |
| S29-B1/F3 | LOW | `map_deck.gd:321-323` | The deck foot ships ZoomMinus/ZoomPlus/ExpandToggle buttons; §10 pins the foot as the A5.4-3 caption strip carrying the zoom read, the hint and the N5 reads only, and N2's wheel + arrows plus N1's compact corner button already cover every path. | → ticketed T-100 |
| S29-B1/F4 | LOW | `project.godot` / `map_deck.gd:486-490` | The `map_toggle` input row is not in the tree (only `ship_status` is, `project.godot:161`); M works through the raw-key fallback, so the key is not rebindable until close-out lands the row the report promises. | → ticketed T-101 |
| S29-B1/F5 | LOW | `map_deck.gd:509,525` | N3's persistence reaches `PlayerProfile`'s private `_config` field through `get()` — disclosed deviation 7; the reversal (a first-class `map_filters` key on `player_profile.gd`) needs the designer because the file sits outside both worker sets. | → ticketed T-102 |
| S29-B2/F6 | LOW | `armory_panel.gd:111,362,1295,1886` | A7 removed the `DROP HERE` cue but left the dead `RACK_INSTALL_CUE` const and four stale doc rows describing it — the leftover should be gone entirely. | → ticketed T-103 |
| S29-B2/F7 | LOW | `armory_panel.gd:3645` | Browser rows carry a native tooltip of the full `Catalog.describe` body — §17.1's "the pane adds no second description surface"; the naming-line idiom (the cells' own tooltips) is the lawful form. | → ticketed T-104 |
| S29-B2/F8 | LOW | `test_s21_stability.gd:909-922` | The two L18/L122 band rows were weakened from `== ClockScript.now()` to `> before` (disclosed; the equality row raced the clock's tick) — the clock tie the rows pinned is gone; a frozen-clock fixture would restore it without the race. | → ticketed T-105 |
| S29-B2/F9 | LOW | `armory_panel.tscn` (`BodyScroll`), `armory_panel.gd:1044-1077` | The merged ARMORY keeps the D13 battery body (racks, barrel inventory, ammunition) below the P4 split — disclosed deviation 1; the strict P7 read is "nothing else", but no ruling retires §5.1's racks and dropping them would strand `buy_ammo`/`fit_into_rack`. The keep-or-retire call is the owner's tick. | → ticketed T-106 |

## Verified fixes

None — no fixer has run; F1 is the pass blocker.

## Gate

- B1 claimed 1038/0 → 1063/0 ×2 fresh scratch; B2 claimed 1073/0 ×2 fresh scratch.
- R1 re-run, fresh scratch (`XDG_DATA_HOME=$(mktemp -d)`), one pass:
  **`[SUMMARY] passed=1073 failed=0`** (35 new rows = 16 + 9 + 10 over the 1038
  baseline; the arithmetic checks).
