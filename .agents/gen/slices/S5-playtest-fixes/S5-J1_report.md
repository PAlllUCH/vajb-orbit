# S5-J1 report — commerce & hangar (the AUCTION's family tabs, the SHIPYARD as the hangar)

Worker `S5-J1` · wave `S5` · slice `S5-playtest-fixes` · 2026-09-23
Brief: `.agents/gen/slices/S5-playtest-fixes/S5_BRIEF.md`. Pin: `docs/CONTRACTS.md` §17 +
`docs/design/STATION_HUB.md` §5.11 (J0 dispositions read as the brief requires).

Deliverable: AC1 (auction family tabs over the same 6+10 draw) and AC2 (the shipyard becomes
the hangar) plus `vajb-orbit/tests/test_s5_commerce.gd`.

## 1. What changed, and where

| File | Change |
|---|---|
| `ui/station/auction_panel.gd` | `FAMILY_TABS` + `TAB_ALL` (`:80-95`), the tab strip builder and its own width fit (`:304-357`), `select_family` / `shown_hull_ids` / `shown_listing_ids` / `tab_button` (`:243-293`), the one visibility pass `_apply_family` (`:359-382`), the listings' payload gains its `slot` (`:671`), `focus_primary` skips a tab-hidden row (`:224-232`), `_rebuild` re-applies the current tab (`:580`) |
| `ui/station/auction_panel.tscn` | `%FamilyTabs` (an `HBoxContainer` between the pane header and the scroll, `:49`); `%HullsMargin` / `%ModulesMargin` gained `unique_name_in_owner` (`:66`, `:93`) |
| `ui/station/shipyard_panel.gd` | the hangar rework: owned-only rows (`_build_rows` `:256`, `_owned_roster` `:272`, `_build_row` `:296`), the row meta carries the class (`META_FORMAT` `:99`), `ACTIVE` badge only (`_refresh_rows` `:896`), `SET ACTIVE` / `IN SERVICE` footer (`_refresh_action` `:961`), `_preview_row` — selection writes nothing (`:998`), `_act` — the one `set_active_ship` write (`:1010`), `_sync_rows` rebuilds the rows when the owned roster moves (`refresh_profile` `:181-193`, `_sync_rows` `:196-203`), read-back helpers `row_of` / `listed_ids` / `selected_id` (`:226-241`); the buy path, the price block, `FOR SALE` / `LOCKED` / `OWNED` states, `ACTION_BUY`, `STATUS_BOUGHT`, `_affordable`, `_format_int` and the icon tint loop removed |
| `ui/station/shipyard_panel.tscn` | `ShipListCaption` → `OWNED HULLS` (`:61`), subtitle → `YOUR HULLS · N IN THE HANGAR · SIDE VIEWS ONLY` (`:40`), `PriceCaption` + `ShipPrice` removed, `ShipAction` labelled `SET ACTIVE` (`:154`) |
| `tests/test_s5_commerce.gd` | **new**, 7 tests (AC1 3, AC2 4) |
| `tests/test_ui_slot_layout.gd` | the shipyard list assertion moves to the owned roster (`:486-527`), `META_FORMAT` re-pinned (`:71`), `_owned_roster` helper (`:176`) |
| `tests/test_p2b_services.gd` | the unowned-hull read moves to the selection (`:402`), the owned-hull read re-seeds the roster through `refresh_profile(&"ships")` (`:429`) |
| `tests/probe_g3_shadow.gd` | one stale line number for the `_make_plate` signature: 321 → 842 (`:42`), because the hangar rework moved the file's lines; the check's text is unchanged |

No doc file changed (the pin set and §5.11 already carry every number J1 needed), no theme
file, no `project.godot`, no balance number.

## 2. AC1 — the family tabs are display grouping (measured)

The pane builds one plate per pin tab and **keeps all sixteen rows built in every tab**;
a tab only moves visibility.

- Tabs, in the pin's order and with the pin's slot keys, asserted against a transcribed
  `PIN_TABS` table (`test_s5_commerce.gd:303`): `HULLS · WEAPONS · DRIVES · SHIELDS ·
  ARMOUR · POWER · COMPUTERS · BOOSTERS · UTILITY · ALL`; `DRIVES` groups on `engine`
  (`ModuleData.SLOT_ALIASES` maps it to `engines` for `ShipFit`); the pane opens on `ALL`
  (the flat list = §5.11's own reversal).
- **Measured:** the strip's minimum width is **871.0 px** against §3.1's **1390 px** pane
  content box (printed as `[S5-COMMERCE] tab strip minimum width 871.0 px of 1390 px`), so
  the ten tabs fit the host at 1920x1080 with 519 px to spare.
- The tour (`test_the_tab_tour_leaves_the_draw_prices_and_restock_byte_identical`, `:356`),
  driven through each tab's own `pressed`, asserts after **every** tab:
  - `%HullRows` still holds **6** rows and `%ModuleRows` **10** (the draw's own 10 §2.1
    shape), and `hull_payloads()` / `module_payloads()` are deep-equal to the payloads read
    before the tour;
  - each of those 16 rows still renders S3's own arithmetic: the id, the price digits
    (`Auction.hull_rows` / `listing_rows`' `price`), the price caption (`WAS <n> CR` on the
    hot row, `CREDITS` / `LIST` otherwise), the `META` line, the `F LOT` tag, and `BUY` on
    every row (`_assert_s3_rendering`, `:468`) — 10 tabs x 16 rows;
  - `profile.auction` is **deep-equal** to the shelf read before the tour,
    `Auction.hot_id` is unchanged, `Auction.listing_ids` still lists 10, and the pane's
    `restock_text()` and `status_text()` are unchanged — no tab writes the shelf, the hot
    slot, the restock reading or the strip;
  - the grouping is exact: `shown_hull_ids()` / `shown_listing_ids()` equal the shelf rows
    filtered by the pin's own section + slot for that tab, and `%HullsMargin` shows only on
    `HULLS` / `ALL`;
  - focus never lands on a hidden row (`focus_primary` skips it), and entering the pane
    keeps the player's tab.
- The buy door is still the auction's: pressing a hull row charges that row's own price and
  adds the hull (`test_the_auction_keeps_the_hulls_buy_door`, `:539`).

## 3. AC2 — the hangar (measured)

- The list is the account's owned roster **in the catalogue's ladder order**, whatever order
  the hulls were bought in (`test_the_hangar_lists_the_owned_hulls_with_the_active_badge`,
  `:570`): with the Destroyer, Lancer and Delver owned (bought destroyer-first) the pane
  lists `[ship_fighter, ship_miner, ship_destroyer]`; a hull the account does not own has
  **no row** (`row_of` answers `null`); the `ACTIVE` badge is on the active hull only; the
  subtitle counts the roster; the footer reads `IN SERVICE` and is disabled.
- **Selecting writes nothing** (`test_selecting_previews_and_writes_nothing_the_footer_is_the_sole_commit`,
  `:616`). Pressing the Delver's row moves the preview (selection, side render =
  `station_catalog`'s own `preview`, the comparison's `SELECTED` / `ACTIVE` columns, the
  rebuilt fit grid with the hull's own columns and `SLOT LAYOUT · n CELLS · m ENGINES`
  caption, and the footer's `SET ACTIVE`, armed) and then measures: credits, `owned_ships`,
  `active_ship`, `fits`, `modules` and `auction` are all unchanged **and
  `profile_changed` emitted 0 times**.
- The footer is the sole commit: one press moves `active_ship`, emits **exactly one**
  `profile_changed(&"ships")`, costs no credit, buys nothing, refits nothing, reports
  `ACTIVE HULL IS NOW DELVER` on the shell strip, moves the badge, and closes the footer to
  `IN SERVICE`. A refused call (`_act` on the hull already in service) writes nothing and
  emits nothing.
- The retired half is measured on the files (`test_the_shipyard_carries_no_buy_path_and_no_price_block`,
  `:733`): the source reaches the profile only through `owned_ships` / `set_active_ship` /
  `fit_for` and carries no `buy_ship`, `ACTION_BUY`, `STATUS_BOUGHT`, `FOR SALE`, `LOCKED`
  or `can_afford`; the scene carries no `ShipPrice` / `PriceCaption` and does carry
  `SET ACTIVE`; the auction carries `buy_hull` and `FAMILY_TABS`.
- Geometry did not move (measured by `test_ui_slot_layout`, before vs after):
  the shipyard panel's combined minimum is **1278 x 1788 px both**, unchanged when a
  4096 px plate is pushed into the grid, against the 1920 px viewport; the only list reading
  that moved is the row count, **9 → 1** on the sandbox account (which owns one hull).

## 4. Gate

J2 was mid-edit in the shared working tree (`autoload/player_profile.gd` carried a duplicate
`buy_ammo`, so every suite that preloads it failed to parse), so the numbers below were
measured on a **mirror of the project** at
`.agents/gen/slices/S5-playtest-fixes/_scratch/mirror/` carrying J1's files with J2's five
in-flight files restored to `HEAD` — the same tree the orchestrator will gate at close-out,
minus J2/J3/J4. Both runs redirected `XDG_DATA_HOME` to a worker scratch dir.

| Run | Command | Result |
|---|---|---|
| pre-J1 baseline (mirror, J1 files at `HEAD`) | `godot --headless --path <mirror> res://tests/headless_runner.tscn --quit-after 1200` | **passed=524 failed=0** |
| J1, run 1 | same | **passed=531 failed=0** |
| J1, run 2 | same | **passed=531 failed=0** |

531 − 524 = **+7**, exactly the seven tests of `test_s5_commerce.gd`; no existing test was
lost, skipped or renamed away. Suites J1 touched, per suite:
`test_s3_auction` 11/0 (S3's own rows hold under the tabs), `test_p2b_services` 14/0,
`test_ui_slot_layout` 12/0, `test_s5_commerce` **7/0**, plus `test_p2b_fitting_panel` 27/0,
`test_p2a_launch_fit` 12/0, `test_p2a_ship_roster` 4/0, `test_ship_grids` 27/0 — all green.

**Live account untouched by J1's runs.** `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`
md5 `cb77a6e53404ce21d94f1a473f0593d2` and mtime `2026-09-23 22:41:34` are identical before
and after both gate runs (the suite harness borrows the autoload and hands it back, and the
runner's own sandbox is upstream of it).

**One reading on the shared tree, for the orchestrator (not a J1 result).** With J2's edits
in place as well (`vajb-orbit` working tree, `XDG_DATA_HOME` redirected): **passed=544
failed=1**, the single failure being
`test_p2b1_outfitting_panel.gd.test_ammo_purchase_charges_the_catalogue_price_and_greys_when_short`
("and added the pack's own rounds", `test_p2b1_outfitting_panel.gd:437`). That assertion
encodes the **pre-S5 pack delivery**, which J2's AC4 retires (10 §6.1: ammo rows deliver
cargo units, `units = rounds / 10`), and neither the file nor its pane is in J1's change
set (J1's edits are `auction_panel` / `shipyard_panel` / their scenes and the three test
files listed in §1). The brief's "tests that move" list names `test_p1_catalogues.gd` but
not this suite, so it needs an owner: J2's change broke it, J2's file set contains it.

**T-93 note for the orchestrator (not caused by this worker).** The live
`profile.cfg` and the live `economy_log.txt` both carry a write timestamp of
**2026-09-23 22:41:33/34**, i.e. *before* this worker's first Godot invocation (the first
J1 gate log closes at 23:01, and no J1 run has ever run without the `XDG_DATA_HOME`
redirect), so that write belongs to another session in the shared workspace — worth
identifying, because it landed on the live account while J2's tree could not be sandboxed
(`headless_runner: no PlayerProfile autoload to sandbox`).

## 5. Decisions taken inside the pin's silence (for the developer to pin or reverse)

The pin fixes the behaviour; these five points are construct/wording choices no document
names, and each is reversible in one place:

1. **The tab strip's plate.** The theme's `TabBar` item ships a font size and the three font
   colours but **no tab stylebox** (measured: `ui/theme/vajb_theme.tres:524-528` sets
   `TabBar/*` colours only; `tools/build_theme.gd:279-284` sets the five tab styleboxes on
   `TabContainer`, not `TabBar`), and a raw `TabBar` would draw Godot's built-in default
   tabs. So a tab is a base-`Button` `toggle_mode` plate (the pane rows' own theme item)
   with an inner 12/6 margin and a `StationValue` label, and the active tab takes
   `text_primary` against `text_dim` — the theme's own `TabBar` colour language.
   **Reversal:** one builder (`_build_family_tabs`) plus the strip's `HBoxContainer`.
2. **The entry tab is `ALL`** (the pinned reversal "the flat list"), and the tab survives
   pane re-entry (the shell re-enters on every module switch). **Reversal:** `_family`
   default + a reset in `enter_pane`.
3. **The `SELL MODULES` sub-list is shown on every tab.** It is the player's inventory, not
   part of the 6-hull + 10-listing draw the tabs group, and §5.11 groups "the shelf's rows"
   only. **Reversal:** one line in `_apply_family`.
4. **The hangar's row copy.** The class lives on the row's meta line (`<CLASS> CLASS · <n>
   HULL · <n> SLOTS`, `shipyard_panel.gd:99`) because §5.11 names "name, class, `ACTIVE`
   badge" and the pane has no class column; the caption reads `OWNED HULLS`, the subtitle
   `YOUR HULLS · N IN THE HANGAR · SIDE VIEWS ONLY`, the focused-row hint
   `ENTER PREVIEWS · <NAME> · <CLASS> CLASS`. **Reversal:** the constants and one scene
   string.
5. **The price block retired with the buy rows** (`PriceCaption` + `%ShipPrice` removed from
   the scene; no price is rendered in the hangar). §5.11 retires the buy rows and the build
   path is staged, so a price here would name a sale the pane cannot make. **Reversal:**
   §5.11's own ("the rows rejoin the shipyard from the auction verbatim").
6. **The pane title stays `SHIPYARD`** — the module label lives in `ui/screens/station.gd`'s
   `MODULE_LABELS`, which is J3's file this wave, and no pin asks for a rename (the owner's
   finding was about behaviour). J1 therefore did not touch `station.gd` at all.

## 6. Findings for R1 / the close-out (no code changed for these)

- **LOW candidate — the closed-wave probes that mount the shipyard.** `tests/probe_w3_services.gd`
  (`:246`, `:259`) iterates `%ShipList` expecting the catalogue's nine rows, and
  `tests/probe_r1_frames.gd` / `probe_w2_fitting.gd` / `probe_r1_fit_panes.gd` drive the
  pane's own fields (those still work). The probes are not the gate; J1 left their bodies
  alone (it only corrected one stale line number in `probe_g3_shadow.gd`), and a later wave
  that wants them re-runnable should move their list reads to the owned roster.
- **LOW candidate — a family with no rows renders an empty section.** A tab the shelf does
  not stock shows the `MODULES` caption + header with no rows under it. §5.11 gives no
  empty-state wording for a filtered family; J1 did not invent one (`EMPTY_MODULES` still
  covers the whole-shelf case).
- **Behaviour note for the shell.** A hull bought on the AUCTION now changes the SHIPYARD's
  row set while the pane exists; `_sync_rows` rebuilds it synchronously from inside the
  `profile_changed(&"ships")` handler. The row swallowed is never the one whose press is on
  the stack (only `%ShipAction` writes), and the same hazard is what the AUCTION pane solves
  with a queued rebuild — R1 may want the two panes' rule pinned as one sentence in §12.4.

## 7. Owner ticks owed

None new from J1: no balance number, no art path and no input-map row moved, and every
wording J1 chose is listed in §5 above for the developer to pin or reverse. Standing debt is
unchanged from the brief's list.
