extends "res://ui/station/station_panel.gd"
##
## **Split (CODE_AUDIT 2026-10-19 P2):** this file is the pane's declaration half - the
## constants, widget classes, `@onready` nodes, state and the token/caption helpers. The
## behavior half is `ui/station/armory_panel.gd`, which extends this file; the scene still
## attaches that script. Reversal: concatenate the two bodies and restore the single
## `armory_panel.gd` (the pre-split history holds every line).
## ARMORY (the OUTFITTING pane renamed, STATION_HUB section 5.11's 2026-09-23 S5
## amendment) as **UI_SPEC section 3.10 Amendment 3 (the D13 rework, wave S18)** rules its
## layout: the **landscape console 1360x516** at the pinned (452,214)+1392x610 host, five
## **2x2-cell** bays across the top, and one wells band below - the barrel inventory left,
## the ammunition pack cards right. The console's rect is **derived from the host rect at
## runtime (P6)**: no pane rect is a constant, so the pane reflows at every window size
## (`ArmoryStyle.console_rect`).
##
## **Amendment 4 (2026-09-26, wave S20) rules the surface.** The scripted console master
## retires from the pane (the file stays on disk; the **module host's own panel frame is
## the pane's outer edge**), the bay cards, wells halves and pack/row plates wear the
## theme's **`ui_panel_frame`** nine-patch (A4.1), the bay cells the **`ui_slot_weapon_*`**
## slot chrome (A4.2), `BUY`/`X` the **`StationButton`** plates, and every palette field
## resolves from the theme's `Tokens/armory_*` (`ArmoryStyle.resolve_theme`, A4.3).
##
##   - **BAYS** - racks `B1..B5`, one drop zone per `weapon_1..5` key (09 section 11,
##     CONTRACTS section 17; 09 section 12's 5x4 hardcap). A rack holds the W cells that
##     fire together; each bay draws four slot-chrome cells (A4.2), prints the full barrel
##     name at 13 px on a fitted cell and `DROP HERE` on an empty one, and carries its
##     salvo readout on the ledge (`ui_seg_*` hundredths of a second beside `SALVO s`)
##     and its `READY` / `AT CAP` state chip on the head. Dragging an inventory weapon
##     onto a bay installs it into the rack's next free W cell through the profile's
##     composed `fit_into_rack` (the section 13/16 transactions: `fit_legal` and the
##     mandatory set are checked before the first write, a refusal writes nothing). A
##     barrel drags within/between racks to re-order and swap; the `x` on a fitted cell
##     (or a right-click, the chrome's own hint) returns it to the inventory.
##   - **BARREL INVENTORY** - one row per owned weapon **id** (aggregated, catalogue
##     order) in the wells band's left half, each one a drag source.
##   - **AMMUNITION** - one card per `StationCatalog.AMMO_PACKS` entry in the right half
##     (two columns of three), buying **cargo units** (`units = rounds /
##     ROUNDS_PER_CARGO_UNIT`) through `PlayerProfile.buy_ammo`; the card carries the
##     worded held line (P5: `HELD 60 ROUNDS - HOLD 30 UNITS`) and the section 5.1 state
##     tag and state line.
##
## **Surface only** (section 3.10): the pane's signals, transactions, drag-drop behaviour
## and the refusal-writes-nothing rule are untouched - every seam and number of STATION_HUB
## section 5.11, 09 section 11/12 and CONTRACTS section 17 survives. Every colour, layout
## metric and asset path comes from `ArmoryStyle` (`ui/station/armory_style.gd`), which
## extends `CockpitStyle` (section 3.9 rule 5): one palette, one asset idiom, and a user
## `.tres` restyles and relayouts the pane with no code edit. **No font size is overridden**
## (HIGH-1's cure): every label reads its size from a theme variation registered in
## `Router.FONT_SIZE_ITEMS` (13 px `StationCaption` throughout, the title 20).
##
## The panel never writes the store directly (STATION_HUB section 12.4): it calls the
## profile's composed APIs, `fit_for`/`resolved_fit`/`instances_of`/`battery_groups`/
## `free_weapon_cell` and `ShipFit.*`, and reports every refusal through its footer.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal inspect_requested(title: String, body: String, danger: bool) the inspector
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const StyleScript := preload("res://ui/station/armory_style.gd")

const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
## 12's 2026-10-08 V1/V2 block: the one owner of the station's price factor, read by
## the pack cards' `Catalog.ammo_pack_price`.
const StationRegistryScript := preload("res://game/station_registry.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
## CONTRACTS section 23.1: emitted when the pointer lands on or leaves a catalogue row
## (an ammunition card, an owned-weapon row or a fitted barrel). `title` is the row's
## identity line, `body` its catalogue description - a fitted barrel's carries a second
## line with its salvo/dps facts (P4) - and `danger` colours the title. `title == ""`
## clears the shell's inspector block.
signal inspect_requested(title: String, body: String, danger: bool)
## S30 (UI_SPEC section 12.3, N28/P21): the explicit sink. A row's own INSPECT chip (or
## `station_inspect` on the focused row / cell) publishes the sheet's payload here.
signal sheet_requested(payload: Dictionary)
## S25's own seam (UI_SPEC section 17 A5): the pane publishes a purchase's confirm dialog
## and the shell answers through `confirm_action` - the overlay belongs to the screen, the
## pane never owns a modal. The focus return and the ESC-to-CANCEL are the seam's own.
signal confirm_requested(payload: Dictionary)

## The three refusal wordings, byte-equivalent to `ui/station/fitting_panel.gd:147-149`
## (CONTRACTS section 16 rule 9, the L116 precedent): ARMORY may not preload the pane
## whose constants are the pin's single home, so it declares its own twins. The overload
## line takes `fit_legal`'s own power numbers; the mandatory wording is **unreachable for
## a W cell** (`FitData.MANDATORY_SLOT_KEYS` is `[engines, power]`, game/ship_fit.gd:117)
## and is carried for the set's completeness only, so no test may assert it through a
## rack. The fourth line is the P2-B1 strip's own `W SLOTS FULL - SWAP OR REMOVE FIRST`,
## kept for the states it names: every W cell of the hull already holds a barrel, and --
## since S15's hardcap -- one battery's four cells are all taken (09 section 12).
const REFUSAL_OVERLOAD := "%d / %d PWR — OVER BY %d"
const REFUSAL_MANDATORY := "MANDATORY CELL — SWAP ONLY, NEVER EMPTY"
const REFUSAL_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"
const REFUSAL_W_SLOTS_FULL := "W SLOTS FULL — SWAP OR REMOVE FIRST"
const REFUSAL_NO_WEAPONS := "NO WEAPONS IN THE INVENTORY"
const STATUS_INSTALLED := "INSTALLED · %s · %s"
const STATUS_MOVED := "MOVED · %s · %s"
const STATUS_REMOVED := "REMOVED · %s · BACK IN INVENTORY"

## The pane's own chrome, in the D13 mockup's words (the chrome line and the caption
## line). The subtitle counts the racks the pane draws (`GROUPS_MAX`, `game/weapons.gd`)
## and the packs the catalogue carries, so neither figure can go stale.
const SUBTITLE := "BATTERY RACKS AND AMMUNITION - %d RACKS - %d PACKS - HOLD %d/%d"
## P38's own subtitle, the FIT CELLS twin of `SUBTITLE` (the same shape: the mode's subject +
## its two live counts). The subject is the cell grid and the equipment list; the counts are
## the active hull's fit cells and the module bases the bag owns. **PROPOSED (S35-F1,
## 2026-10-05)** - the D22-P1/F01 cure; reversal: hide `%PaneSubtitle` in FIT CELLS instead.
const SUBTITLE_FIT := "FIT CELLS AND EQUIPMENT - %d CELLS - %d MODULES"
## The pane hint is per mode (STATION_HUB section 20.1 P32; the shipped line is kept for
## FIT CELLS, the rack-regroup line for BATTERY CONFIG). Swapping the text of one fixed
## label is a content swap in a pinned box (N31's legal set), never a layout mutation.
const PANE_HINT := "DRAG TO FIT - RIGHT-CLICK TO PULL - 1-5 SELECT RACK"
const PANE_HINT_FIT := "DRAG TO FIT - RIGHT-CLICK TO PULL - 1-5 SELECT RACK"
## P40: the hint line updates per mode **and** selection - a selected cell turns the list into
## the fit flow, so the line says so.
const PANE_HINT_FIT_CELL := "PRESS OR DRAG A ROW TO FIT THE CELL - RIGHT-CLICK PULLS A BARREL"
const PANE_HINT_BATTERY := "DRAG BETWEEN RACKS TO REGROUP - 1-5 SELECT RACK"
const TAG_LIST_PREFIX := "IDS "
const TAG_LIST_SEPARATOR := " · "

## ------------------------------------------------- the two modes (P32, STATION_HUB 20.1)
## The ARMORY is one pane with two full-screen modes behind a two-entry switch in the
## header band. Exactly one mode root is visible at a time and the switch is a pure
## visibility operation (A5.5/N24: no size, no position, no in-flow rebuild).
##
## F14 (D23-R1, MED): the action pair rides the pane's own foot band (`PaneFoot`, the
## skeleton's 56 px band - UI_SPEC section 8 P2, STATION_HUB section 19.3) on **both** modes,
## so the cluster keeps one place on the whole deck. The mode roots keep the pane's full
## height (`offset_bottom` 68 = the band 56 + the pane root's own 12 px gutter in
## `armory_panel.tscn`), and each mode reserves that band under its list with a 56 px slot
## (`FitFoot`, `EqFoot`) so no row ever scrolls in behind the pair. `ModeHost` is a plain
## `Control` (not a `MarginContainer`) so those anchors and offsets are the mode roots' own.
const MODE_FIT: StringName = &"fit"
const MODE_BATTERY: StringName = &"battery"
const MODE_FIT_LABEL := "FIT CELLS"
const MODE_BATTERY_LABEL := "BATTERY CONFIG"

## ---------------------------------------------------- the CELL INFO block (P33, item 1)
## The one-line SelectionLine retires into a real block: the cell's identity (id + family
## word), its power draw, the fitted module (or EMPTY) and a proactive legality line built
## from the pane's own refusal strings (lines above).
const CELL_INFO_CAPTION := "CELL INFO"
## The cell's own id composition (`W3`/`S1`/`E2`): the token plus the 1-based layout
## index. CELL_INFO_ID spells the full CELL INFO line from it, so the grid's info line
## and the EQUIPPED rows never spell one cell two ways.
const CELL_ID_FORMAT := "%s%d"
const CELL_INFO_ID := CELL_ID_FORMAT + " · %s CELL"
const CELL_INFO_POWER := "POWER DRAW %d · PWR %d / %d"
const CELL_INFO_FITTED := "FITTED · %s"
const CELL_INFO_FITTED_EMPTY := "EMPTY"
const CELL_INFO_LEGAL_OK := "LEGAL · THIS CELL FITS"
const CELL_INFO_SELECT := "SELECT A CELL FOR ITS FACTS AND ITS FITS"

## ------------------------------------------------- the EQUIPPED block (P49, STATION_HUB 23.4)
## The left sector's third block, under CELL INFO: the caption's fitted/total counts and
## one row per fitted module in the grid's own cell order, each carrying the cell id, the
## module's name, one stat line (the catalogue's `effects` through the stat_line idiom)
## and the family glyph 24. A row's press is the grid's own selection (`select_cell`) and
## BATTERY CONFIG never shows the list (the block rides FitCells; the racks are the
## weapons' view, P34).
const EQUIPPED_CAPTION := "EQUIPPED — %d/%d"
## The A5.3 inventory row's own numbers (UI_SPEC section 3.10 A5.3/A5.4): the 6 px
## content inset, the 24 px family glyph at its own cut, and the row's id and stat
## columns. The row's minimum height is the glyph plus the inset pair.
const EQUIPPED_ROW_INSET := 6.0
const EQUIPPED_ICON := 24.0
const EQUIPPED_ROW_HEIGHT := 36.0
const EQUIPPED_ID_COLUMN := 36.0
const EQUIPPED_STAT_COLUMN := 150.0
## The stat line idiom's own separators and suffix rules (`fitting_panel.gd:144-150`).
const STAT_JOIN := " · "
const STAT_ADD_SUFFIX := " ADD"
const STAT_MULT_SUFFIX := " MULT"
const MULTIPLIER_PREFIX := "×"

## ------------------------------------------------------- the buy doors (UI_SPEC section 17)
## A6's wording law: the title, the owner's own sentence upper-cased to the house caption
## law, and the button pair the shell's dialog opens with. The name and the price come
## from the owning catalogue row at press time, never hardcoded; the pack's name carries
## its rounds (`LASER CELLS (300 ROUNDS)`).
const BUY_CONFIRM_TITLE := "CONFIRM PURCHASE"
const BUY_CONFIRM_BODY := "ARE YOU SURE YOU WANT TO BUY %s FOR %s CREDITS?"
const BUY_CONFIRM_OK := "OK"
const BUY_CONFIRM_CANCEL := "CANCEL"
const AMMO_CONFIRM_NAME := "%s (%d ROUNDS)"
const ACTION_BUY_AMMO: StringName = &"buy_ammo"

## ----------------------------------------- the one equipment list (P38, its two states)
## The right sector of FIT CELLS is ONE list in two states. With no cell selected it browses
## everything the profile owns (rows tagged `FIT` when the active hull carries a cell of the
## module's family, `STORED` otherwise). With a cell selected it lists the owned candidates
## for that cell (`OWNED`, select-to-fit and drag-to-fit), each row carrying the legality
## line the CELL INFO block speaks (the refusal strings above, wired proactively). A26
## (2026-10-16): the buyable half retires — the armory sells no equipment (10 §6.2).
const TAG_FIT := "FIT"
const TAG_STORED := "STORED"
const TAG_OWNED := "OWNED"
const LIST_CAPTION_BROWSE := "OWNED EQUIPMENT - %d"
const LIST_CAPTION_CELL := "FITS %s%d - %d"
const LIST_EMPTY_BROWSE := "NOTHING OWNED TO SHOW"
const LIST_EMPTY_CELL := "NOTHING FITS THIS CELL"
## The one AUCTION-idiom column-header band each list wears (P40): the row stacks' own words,
## seated over their columns (the module's title, its state tag and its cost/owned figure).
const BAND_MODULE := "MODULE"
const BAND_STATE := "STATE"
const BAND_COST := "COST"
## F3 (D23-R1, MED): BATTERY CONFIG's rows print fit states in both value columns (`FITTED`
## / `OWNED x n` - `READ_FITTED`, `OWNED_FORMAT`), so the browser's `COST` header mislabels
## its column and the two columns double-report the same state. The battery band reads its
## own second word; the builder takes the pair as an argument already.
const BAND_HELD := "HELD"
const BAND_TAG_COLUMN := 96.0
const BAND_COST_COLUMN := 130.0
## A18: the ammunition row's own held column (the P5 worded line's seat; the
## band's HELD caption reads the same width).
const BAND_HELD_COLUMN := 200.0
## A rack's empty hull W cell reads read-only (09 section 10's idiom): `W<n> — EMPTY`.
const EMPTY_CELL_FORMAT := "W%d — EMPTY"
const EMPTY_CELLS_CAPTION := "EMPTY CELLS - %d"
## A18: the ammunition rows are the shared menu's own full-width rows - the
## P38 browser row's container grammar at the pack's own content. The row
## keeps the card's four text lines' content (the P5 worded held line rides
## its own column) at the shared row height.
const AMMO_ROW_HEIGHT := 76.0

## ------------------------------------------- the shared right menu (P39a, S35)
## Both modes' right sector render ONE shared menu component (P39a): identical categories,
## rows, band and trim. `MENU_TABS` is the one category set (the P39 EQ container's
## AMMUNITION + the P38 browser's families), and the modes differ only in the row actions and
## the FIT CELLS socket filter. The S33 EQ container merges into this menu.
const EQ_TAB_AMMO: StringName = &"ammo"
## The two sectors of each mode are equal (P38/P39): one gutter between them, A5 tokens.
const SECTOR_GUTTER := 16

## The rack column (09 section 11/12): `B1..B5`, one drop zone per `weapon_1..5` key.
const WEAPON_SLOT: StringName = &"weapons"
const POWER_SLOT: StringName = &"power"
const RACK_COUNT: int = WeaponComponent.GROUPS_MAX
const RACK_LABEL := "B%d"
const RACK_KEY := "(%d)"
const RACK_ACTION := "weapon_%d"
## The empty cell's cue (T4) and the bay's state chip (T7, owner-ruled 2026-09-26): the
## chip states `READY`, or `AT CAP` when the battery holds the hardcap's four cells -
## shape (chevron) plus label, never colour alone. `AT CAP` is the literal wording
## (UI_SPEC section 3.10 Amendment 5): the pack card's `OVER CAP` is the *other* state
## (over the advisory hold ceiling), and the two must not share a word.
const RACK_INSTALL_CUE := "DROP HERE"
const RACK_READY := "READY"
const RACK_STATE_AT_CAP := "AT CAP"
const RACK_SALVO := "SALVO %.1f s"
const BARREL_TEXT := "W%d %s"
const BARREL_CLOSE := "✕"
const INVENTORY_TEXT := "%s  ×%d"
const AMMO_CAPTION := "AMMUNITION - %d PACKS"

## The SALVO drum's approved figure (Mockup A, owner "Looks good" 2026-09-24; T8 keeps
## it): the cycle in **hundredths of a second**, zero-padded (`073` = 0.73 s). A cycle
## of 0 s has no figure and reads blanks. **Four cells since S22.8** (the cadence
## split): the heavy tier's cooldowns read 10.00-15.00 s, so the drum carries up to
## 99.99 s.
const SALVO_MAX := 9999

## The pack card's own lines (P5, MED-1/2's cures): the worded held line, the price's
## unit word (the section 5.1 `CREDITS` caption became the `CR` word beside the number),
## and the `BUY` chip.
const HELD_FORMAT := "HELD %d ROUNDS - HOLD %d UNITS"
const PRICE_FORMAT := "%s CR"
const ROUNDS_CAPTION := "%d ROUNDS PER PACK"
const BUY_CHIP := "BUY"
const TAG_EMPTY := "EMPTY"
const TAG_IN_STOCK := "IN STOCK"
const TAG_AT_CAP := "AT CAP"
const TAG_OVER_CAP := "OVER CAP"
const TAG_UNAVAILABLE := "STOCK UNAVAILABLE"
const META_NO_ROUNDS := "NO ROUNDS HELD"
const META_ADVISORY := "CAPACITY IS ADVISORY"
const META_NO_CAP := "NO PURCHASE CAP"
const META_BELOW_CAPACITY := "BELOW CAPACITY"
const META_INCOMPLETE := "CATALOGUE ENTRY INCOMPLETE"
const UNAVAILABLE_VALUE := "0"
const STATUS_HINT := "ENTER BUY · %s · %s CREDITS"

## CONTRACTS section 23.1: the inspector's own identity line - the same name and price
## phrase as `STATUS_HINT`, joined by the pane's own separator, with the leading key-hint
## verb dropped so the always-visible title is the row, not the action.
const INSPECT_TITLE_FORMAT := "%s · %s CREDITS"
## The fitted barrel's inspector body: the catalogue description, then a facts line
## (P4/MED-3). The salvo figure is the family's own cycle (`WeaponComponent.interval_of`),
## `INSTANT` for the beam families that state none.
const INSPECT_STATS := "SALVO %s · DPS %.1f /s · FITTED IN %s W%d"
const STATS_INSTANT := "INSTANT"
const STATUS_BOUGHT := "PURCHASED · %s · +%d ROUNDS"

## A row's inner padding, in drawn pixels (the plates carry the chrome, not the margins).
const ROW_TEXT_INSET := 6.0
## The drag payloads (`_get_drag_data` / `_can_drop_data` / `_drop_data`):
## an inventory row carries its base id, a barrel its address in the racks.
const DRAG_INVENTORY: StringName = &"inventory"
const DRAG_BARREL: StringName = &"barrel"
const DRAG_KEY_KIND: StringName = &"kind"
const DRAG_KEY_BASE: StringName = &"base"
const DRAG_KEY_RACK: StringName = &"rack"
const DRAG_KEY_POSITION: StringName = &"position"
## A drop on the rack's own body rather than on one of its cells (the install route).
const DROP_RACK_BODY := -1

const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

## ------------------------------------------------- the S29 merged surfaces (P4, P8-P14)
## STATION_HUB section 16 P4 and section 17.1: FITTING folds in as the pane's left half
## (the ship grid on `fitting_panel.gd:18-70,148-149`'s own numbers) and the right half is
## the shared menu - the AUCTION's family-tab strip minus `HULLS` (a hull is not a
## module row and fits no cell; D18-A1's judgment, reversal: ship the tab disabled) over
## owned + buyable module rows in the auction row idiom. P39a (S35): the SAME strip is the
## one category set both modes render, with `AMMUNITION` (the P39 EQ container's own
## category) leading. A26: the browser's module rows are the profile's owned stock —
## the `& BUYABLE` half of P8's caption retires with the buy rows (10 §6.2).
const TAB_ALL: StringName = &"all"
const MENU_TABS: Array[Dictionary] = [
	{&"id": &"ammo", &"label": "AMMUNITION", &"slot": &""},
	{&"id": &"weapons", &"label": "WEAPONS", &"slot": &"weapons"},
	{&"id": &"drives", &"label": "DRIVES", &"slot": &"engine"},
	{&"id": &"shields", &"label": "SHIELDS", &"slot": &"shields"},
	{&"id": &"armour", &"label": "ARMOUR", &"slot": &"armour"},
	{&"id": &"power", &"label": "POWER", &"slot": &"power"},
	{&"id": &"computers", &"label": "COMPUTERS", &"slot": &"computers"},
	{&"id": &"boosters", &"label": "BOOSTERS", &"slot": &"boosters"},
	{&"id": &"utility", &"label": "UTILITY", &"slot": &"utility"},
	{&"id": &"all", &"label": "ALL", &"slot": &""},
]
const TAB_MIN_SIZE := Vector2(0.0, 32.0)
## P8 (section 17.5): the browser caption. Reversal: `OWNED MODULES` (the fitting label).
const BROWSER_CAPTION := "MODULES · OWNED"
const BROWSER_META_FORMAT := "SLOT %s · DRAW %d"
const BROWSER_ROW_HEIGHT := 76.0
const BROWSER_ICON := 24.0
const COL_OWNED := 130.0
## N45: the browser row's fixed 160 px ellipsis title column.
const BROWSER_TITLE_COLUMN := 160.0
## P1 (UI_SPEC section 8): the row-corner BUY is an `ActionInline` 96x32 flat chip.
const ACTION_INLINE := Vector2(96.0, 32.0)
## S30-F1 (F7, N37): the INSPECT chip's own box - UI_SPEC section 8's `ActionInline` 96x32.
## The hand-positioned ammo cards and inventory rows reserve this trailing cell.
const CHIP_WIDTH := 96.0
const CHIP_HEIGHT := 32.0
## The ship grid's own recipe (FITTING's numbers, section 17.1's own cite): 48 px
## `SlotButtonWeapon` plates, gaps as empty 48 x 48 Controls, the glyph inset 6, the
## `SLOT LAYOUT` caption. The meter's preview word is A7's CANDIDATE rename (D17-P1:
## "CANDIDATE uses an undefined term"); PROPOSED `IF FITTED`, reversal: `CANDIDATE`.
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
const PLATE_ICON_INSET := 6.0
const HARDPOINT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"
const SLOT_KEY_ALIASES: Dictionary = {&"engine": &"engines"}
const METER_IDLE := "PWR %d / %d"
const METER_PREVIEW := "PWR %d / %d · IF FITTED %d / %d"
const METER_OVER := " — OVER BY %d"
const SELECTION_FORMAT := "%s%d · %s · OWNED ×%d"
const CELL_EMPTY := "EMPTY"
const ACTION_SELECT: StringName = &"SELECT A CELL"
const ACTION_FIT: StringName = &"FIT"
const ACTION_SWAP: StringName = &"SWAP"
const OWNED_FORMAT := "OWNED ×%d"
## P38: a browse row whose base is fitted but holds no bag spare reads its fitted state
## instead of a price (`FITTED`), never `0 CR`.
const READ_FITTED := "FITTED"
## P9/P10/P11/P14 (section 17.5): the wrong-slot refusal line, the 0.5 s slot-caption
## flash (label + state, never a colour alone), the fit confirmation and the cluster
## primary's own label (`SELECTED` appended when a cell is selected).
const REFUSAL_DROP := "DROP REFUSED — %s FITS NO %s CELL"
const SLOT_FLASH_SECONDS := 0.5
const STATUS_FITTED := "FITTED · %s"
const ACTION_REMOVE := "REMOVE"
## A26 (2026-10-16): the cluster fits a held entry — buying is the AUCTION's door,
## so P14's `BUY & FIT` reads plain `FIT` (`SELECTED` appended when a cell is selected).
const ACTION_FIT_CLUSTER := "FIT"
const ACTION_FIT_CLUSTER_SELECTED := "FIT SELECTED"
const DRAG_BROWSER: StringName = &"browser"
const DRAG_KEY_ENTRY: StringName = &"entry"

## Audit anomaly C16: these three catalogue icons are flat Phase B glyphs (mean RGB about
## 40, 44, 47) that read as near-black shapes on the row chrome, so the row draws the
## derived icons/tint/ stencil moderated with Tokens/text_primary instead. Every other
## catalogue icon is painted and is drawn at full colour.
const FLAT_GLYPH_ICONS: Array[String] = [
	"res://assets/icons/weapon/icon_weapon_cannon.svg",
	"res://assets/icons/weapon/icon_weapon_mine.svg",
	"res://assets/icons/weapon/icon_weapon_plasma.svg",
]
const TINT_DIR := "res://assets/icons/tint/"

## The style roles this surface asks for, in section 1's own vocabulary (the style is the
## only colour store: section 3.9 rule 5).
const ROLE_TEXT_PRIMARY: StringName = &"text_primary"
const ROLE_DANGER: StringName = &"accent_danger"
const ROLE_DANGER_BRIGHT: StringName = &"accent_danger_bright"
const ROLE_METAL_LIGHT: StringName = &"metal_light"
const ROLE_METAL_MID: StringName = &"metal_mid"
const ROLE_METAL_DARK: StringName = &"metal_dark"
const ROLE_BONE: StringName = &"bone"
const ROLE_CAPTION: StringName = &"caption"
const ROLE_BAY_BG: StringName = &"bay_bg"
const ROLE_CELL_BG: StringName = &"cell_bg"
const ROLE_LEDGE_BG: StringName = &"ledge_bg"
const ROLE_ITEM_BG: StringName = &"item_bg"
const ROLE_CHIP_BG: StringName = &"chip_bg"
const ROLE_CHIP_DANGER_BG: StringName = &"chip_danger_bg"
const ROLE_FIT_LINE: StringName = &"fit_line"


## One barrel cell's name plate: the drag source of a barrel (S5, 09 section 11). The
## payload is its address in the racks, so a drop knows what is being moved without
## reading the tree it may be about to rebuild. Its own ink is transparent - the cell
## prints the full name on two 13 px labels (T3, HIGH-5's cure) while `text` stays the
## identity every read-back and tooltip uses.
class BarrelName extends Button:
	var armory: Control = null
	var rack := 0
	## The barrel's index in its rack's chip list ("position" is `Control`'s own).
	var slot := 0

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_barrel", rack, slot)

	func _ready() -> void:
		clip_text = true

	func _gui_input(event: InputEvent) -> void:
		if armory == null:
			return
		if not (event is InputEventMouseButton):
			return
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
			armory.call(&"remove_barrel", rack, slot)
			accept_event()


## One fitted cell: the drag source (the name plate), the visible name block, the `x` and
## a drop zone of its own - dropping a barrel **on** another barrel is the swap (09
## section 11's between-rack swap). The `x` in the top-right corner and a right-click
## anywhere on the cell are the two remove routes (both call `remove_barrel`).
class BarrelCell extends HBoxContainer:
	var armory: Control = null
	var rack := 0
	var slot := 0

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_barrel", rack, slot)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, slot, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, slot, data)

	func _gui_input(event: InputEvent) -> void:
		if armory == null:
			return
		if not (event is InputEventMouseButton):
			return
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
			armory.call(&"remove_barrel", rack, slot)
			accept_event()

	func _draw() -> void:
		if armory == null:
			return
		var style: Resource = armory.call(&"style")
		if style == null:
			return
		## The decorative ember fit line: a fitted cell is already marked by its own name
		## (T7's rule - no state is carried by colour alone).
		draw_line(
			Vector2(8.0, size.y - 6.0), Vector2(size.x - 8.0, size.y - 6.0),
			style.colour(ROLE_FIT_LINE), 2.0
		)
## One empty cell: the `DROP HERE` cue and the drop zone that installs a dragged
## inventory weapon into the rack's next free W cell (the body-drop route).
class DropCell extends Control:
	var armory: Control = null
	var rack := 0
	var slot := 0

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, DROP_RACK_BODY, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, DROP_RACK_BODY, data)


## One rack: the `B<n>` label, its key hint, its state chip, its fitted cells and the
## drop zones that install a dragged inventory weapon. A press on the bay is the mouse
## half of the selection seam (STATION_HUB section 5.11's five selectable bays): it moves
## the section 3.2 ember frame and writes nothing.
class RackRow extends PanelContainer:
	var armory: Control = null
	var rack := 0

	func _gui_input(event: InputEvent) -> void:
		if not event.is_pressed():
			return
		if not (event is InputEventMouseButton):
			return
		if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
			return
		if armory != null:
			armory.call(&"set_selected_rack", rack)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, -1, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, -1, data)


## One ship-grid cell (P4's left half): selectable (`FOCUS_ALL`, the one focus ring), a
## drop target filtered by slot and the owner of the slot caption that flashes 0.5 s on a
## refused drop (P10). The empty cell draws its dim glyph and no cue text at all (A7: the
## `DROP HERE` ghosts never land on the merged panels).
class SlotCell extends Button:
	var armory: Control = null
	var cell: Dictionary = {}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"cell_can_drop", cell, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"cell_drop", cell, data)


## One browser row: the auction row idiom (a `Button` carrying its own children), the
## drag source of every fit flow and a hover emitter for the shared inspector. The
## row-corner BUY is the P1 `ActionInline` chip nested in the row.
class BrowserRow extends Button:
	var armory: Control = null
	var payload: Dictionary = {}

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_browser", payload)


## A chip: the rounded plate, its border and - for the AT CAP state - the chevron that
## makes the state a shape as well as a label (T7, HIGH-3's cure).
class ChipPlate extends Control:
	var style: Resource = null
	var danger := false
	var chevron := false

	func configure(new_style: Resource, is_danger: bool, has_chevron: bool) -> void:
		style = new_style
		danger = is_danger
		chevron = has_chevron
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if style == null:
			return
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_CHIP_DANGER_BG if danger else ROLE_CHIP_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER_BRIGHT if danger else ROLE_METAL_MID),
			false, style.frame_width
		)
		if chevron:
			var height: float = minf(size.y - 8.0, 12.0)
			var top := (size.y - height) * 0.5
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(6.0, top + height),
					Vector2(11.0, top),
					Vector2(16.0, top + height),
				]),
				style.colour(ROLE_DANGER_BRIGHT)
			)


## One rack bay's code-drawn marks: the section 3.2 ember frame when this bay is the
## selected rack (the fitted cells are marked by their own names, T7).
class BayMarks extends Control:
	var style: Resource = null
	var filled: Array[int] = []
	var selected: bool = false

	func configure(new_style: Resource, new_filled: Array[int], is_selected: bool) -> void:
		style = new_style
		filled = new_filled
		selected = is_selected
		queue_redraw()

	func marked_cells() -> Array[int]:
		return filled

	func is_selected() -> bool:
		return selected

	func _draw() -> void:
		if style == null or not selected:
			return
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER_BRIGHT),
			false,
			style.selected_frame_width
		)


## One rack bay's SALVO strip: the engraved ledge, the four `ui_seg_*` drum cells and
## the 13 px `SALVO s` caption beside them (T8: no hidden head line - the digits and the
## label are adjacent).
class SalvoStrip extends Control:
	var style: Resource = null
	var _caption: Label = null
	var _cells: Array[TextureRect] = []
	var _seg: Array[Texture2D] = []
	var _blank: Texture2D = null
	var _shown: Array = []
	var _figure: int = -1

	func configure(new_style: Resource, segments: Array[Texture2D], blank: Texture2D) -> void:
		style = new_style
		_seg = segments
		_blank = blank
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _caption == null:
			_caption = Label.new()
			_caption.name = "Caption"
			_caption.theme_type_variation = &"StationCaption"
			_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_caption)
		_caption.text = style.salvo_caption
		_caption.add_theme_color_override(&"font_color", style.colour(ROLE_CAPTION))
		var ledge := Rect2(Vector2.ZERO, size)
		_caption.position = style.salvo_caption_pos(ledge) - Vector2(0.0, 6.0)
		var cells: int = style.salvo_cells
		while _cells.size() > cells:
			var removed: TextureRect = _cells.pop_back()
			remove_child(removed)
			removed.queue_free()
		while _cells.size() < cells:
			var cell := TextureRect.new()
			cell.name = "Salvo%d" % _cells.size()
			cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell.stretch_mode = TextureRect.STRETCH_SCALE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell)
			_cells.append(cell)
		for index: int in _cells.size():
			var rect: Rect2 = style.salvo_cell_rect(index, ledge)
			_cells[index].position = rect.position
			_cells[index].size = rect.size
		set_figure(_figure)
		queue_redraw()

	## The cycle figure in hundredths of a second, -1 for a rack with no travelling member
	## (blanks, never a zero figure that would read as 0.00 s).
	func set_figure(figure: int) -> void:
		_figure = figure
		_shown = _format(figure)
		for index: int in _cells.size():
			var digit: int = _shown[index]
			var cut: Texture2D = _blank
			if digit >= 0 and digit < _seg.size():
				cut = _seg[digit]
			_cells[index].texture = cut

	## The digits as drawn: 0..9 per cell, -1 for a blank.
	func cells() -> Array:
		return _shown.duplicate()

	func figure() -> int:
		return _figure

	## The four cells' own text, `"073"` style, for a probe that wants the readout.
	func figure_text() -> String:
		var text := ""
		for digit: int in _shown:
			text += "-" if digit < 0 else str(digit)
		return text

	func cell_nodes() -> Array[TextureRect]:
		return _cells

	func caption_node() -> Label:
		return _caption

	func _format(figure: int) -> Array:
		var out: Array = []
		for index: int in maxi(style.salvo_cells, 0):
			out.append(-1)
		if figure < 0:
			return out
		var text := str(clampi(figure, 0, SALVO_MAX))
		var count: int = mini(text.length(), out.size())
		var offset: int = out.size() - count
		## Mockup A's approved figure is zero-padded (`073` = 0.73 s), not blank-padded:
		## a cadence reads as a three-digit drum figure.
		for index: int in offset:
			out[index] = 0
		for index: int in count:
			out[offset + index] = text.substr(text.length() - count + index, 1).to_int()
		return out

	func _draw() -> void:
		if style == null:
			return
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_LEDGE_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size), style.colour(ROLE_METAL_MID), false, style.frame_width
		)
		for index: int in _cells.size():
			var rect := Rect2(_cells[index].position, _cells[index].size)
			draw_rect(rect, style.colour(ROLE_CELL_BG), true)


## One row's plate: the theme's `ui_panel_frame` nine-patch (A4.1, `PanelRaised`) with the
## section 3.1/3.1b danger frame over it when the row is in a danger state. Without the
## theme box the row's recorded recess tone returns (the palette's own reversal path).
class RowPlate extends Control:
	const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
	var style: Resource = null
	var _danger: bool = false

	func configure(new_style: Resource) -> void:
		style = new_style
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	## The danger treatment: a 1 px code-drawn frame in `accent_danger` - the digits
	## themselves never recolour (section 3.7's own rule, reused here verbatim).
	func set_danger(danger: bool) -> void:
		if _danger == danger:
			return
		_danger = danger
		queue_redraw()

	func danger() -> bool:
		return _danger

	func _draw() -> void:
		if style == null:
			return
		## S36 (UI_SPEC section 15.1/15.4-3): the 320x68 pack/inventory card wears C4
		## `ui_row_strip` at the measured nine-slice margins scaled to the card's own drawn
		## rect (F1, S36-F1; the card sits inside C4's 320-1765 x 64-84 band).
		var plate: StyleBox = ChromeFamily.stylebox("C4", size)
		if plate != null:
			draw_style_box(plate, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER if _danger else ROLE_METAL_MID),
			false, style.frame_width
		)


## The console's own chrome, one node and one `_draw` pass, over the host's panel and
## under every interactive one. **Amendment 4 amended by Amendment 5 (owner-ruled
## 2026-09-26):** every inner surface (the two wells halves, the five bay cards, the cells,
## the ledges) wears the flat Tokens language (A5.1: no frame inside the console - the
## pane's outer edge is the module host's own `PanelRaised`), every bay cell keeps its
## machined recess and draws the `ui_slot_weapon_*` slot plate at its own 48x48 centred
## (never stretched), and the salvo ledges keep their code-drawn band (A4.5).
class ConsolePanels extends Control:
	var style: Resource = null
	var bays: Array[Rect2] = []
	var cells: Array[Rect2] = []
	var ledges: Array[Rect2] = []
	var wells: Array[Rect2] = []
	## The theme's own chrome, read fresh on every configure so a theme re-band moves this
	## pane with every sibling panel: the weapon slot's own 48x48 plate texture (drawn at
	## its own size, A5.1). The cards and halves need no asset - A5.1's flat Tokens box.
	var slot_plate: Texture2D = null

	func configure(
		new_style: Resource,
		new_bays: Array[Rect2],
		new_cells: Array[Rect2],
		new_ledges: Array[Rect2],
		new_wells: Array[Rect2]
	) -> void:
		style = new_style
		bays = new_bays
		cells = new_cells
		ledges = new_ledges
		wells = new_wells
		slot_plate = _slot_texture()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if style == null:
			return
		## A5.1/A5.3: every inner surface is the flat Tokens box - the two well halves and
		## the five bay cards (a bay is 260x192: the frame's 32 px band would leave a
		## 196x128 opening for 240 px of cells, so it is not drawn inside this console).
		## S36-F1 (A4, F3): the live bays are 876x116, outside every class band (C5 is the
		## fixed 260x192 card), so they keep the flat pre-swap plate - reported as
		## new-plate candidates.
		for rect: Rect2 in wells:
			_plate(rect, ROLE_BAY_BG, 8)
		for rect: Rect2 in bays:
			_plate(rect, ROLE_BAY_BG, 8)
		for rect: Rect2 in cells:
			_slot(rect)
		for rect: Rect2 in ledges:
			_plate(rect, ROLE_LEDGE_BG, 6)

	## The slot family's own normal plate, whatever the theme's variation holds (a
	## `StyleBoxTexture` normally): A5.1 draws it at the size it was cut for, never
	## stretched to a cell's box.
	func _slot_texture() -> Texture2D:
		var box := get_theme_stylebox(&"normal", &"SlotButtonWeapon") as StyleBoxTexture
		return box.texture if box != null else null

	## The slot plate's own rect inside a cell: centred, at the plate's own size (A5.1 -
	## the drawn rect never reaches the cell's box). The one place that arithmetic lives.
	static func slot_plate_rect(cell: Rect2, plate: Texture2D) -> Rect2:
		if plate == null:
			return cell
		return Rect2(cell.position + (cell.size - plate.get_size()) * 0.5, plate.get_size())

	## A4.2 amended by A5.1/A5.3: the cell keeps the machined recess and wears the
	## family's slot plate **at its own 48x48** centred - never stretched to the cell's
	## 117x52 box, which would smear the painted silhouette across it (the S20 defect).
	func _slot(rect: Rect2) -> void:
		_recess(rect)
		if slot_plate == null:
			return
		draw_texture(slot_plate, slot_plate_rect(rect, slot_plate).position)

	## A raised band: the fill plus a 1 px border.
	func _plate(rect: Rect2, role: StringName, radius: int) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(role)
		box.corner_radius_top_left = radius
		box.corner_radius_top_right = radius
		box.corner_radius_bottom_left = radius
		box.corner_radius_bottom_right = radius
		draw_style_box(box, rect)
		draw_rect(rect, style.colour(ROLE_METAL_MID), false, style.frame_width)

	## A machined cell recess: the dark fill plus the two edge tones (top/left shadow,
	## bottom/right catch light) - the mockup's recess language, code-drawn.
	func _recess(rect: Rect2) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_CELL_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, rect)
		var width: float = style.frame_width
		var dark: Color = style.colour(ROLE_METAL_DARK)
		var light: Color = style.colour(ROLE_METAL_LIGHT)
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), dark, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), dark, width, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, light, width, true)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, light, width, true)


@onready var _console: Control = %Console
## The scene's own nine-slice slot for the console master; **its texture is cleared at
## build** (A4.1: the master retires from the pane).
@onready var _plate: NinePatchRect = %ConsolePlate
@onready var _title: Label = %PaneTitle
@onready var _subtitle: Label = %PaneSubtitle
@onready var _hint: Label = %PaneHint
@onready var _tag: Label = %PanelTag
@onready var _mode_fit: Button = %ModeFitCells
@onready var _mode_battery: Button = %ModeBatteryConfig
@onready var _fit_cells: Control = %FitCells
@onready var _battery_config: Control = %BatteryConfig
## P39a (S35): the ONE shared menu component. It is reparented between the two modes' right
## sectors on a mode switch (a command, never a hover/focus/selection state) so both modes
## render the identical subtree - categories, rows, band and trim.
@onready var _menu_sector: Control = %MenuSector
@onready var _fit_right: Control = %FitRight
@onready var _eq_sector: Control = %EqSector
@onready var _rack_rows: VBoxContainer = %RackRows
@onready var _empty_margin: Control = %EmptyMargin
@onready var _empty_caption: Label = %EmptyCaption
@onready var _empty_scroll: ScrollContainer = %EmptyScroll
@onready var _empty_rows: VBoxContainer = %EmptyRows
@onready var _summary_margin: Control = %SummaryMargin
@onready var _summary_caption: Label = %SummaryCaption
@onready var _summary_hint: Label = %SummaryHint
@onready var _slot_caption: Label = %SlotCaption
@onready var _grid: GridContainer = %SlotLayoutGrid
@onready var _meter: Label = %MeterLabel
@onready var _cell_info_id: Label = %CellInfoId
@onready var _cell_info_power: Label = %CellInfoPower
@onready var _cell_info_fitted: Label = %CellInfoFitted
@onready var _cell_info_legal: Label = %CellInfoLegal
@onready var _equipped_block: VBoxContainer = %EquippedBlock
@onready var _equipped_caption: Label = %EquippedCaption
@onready var _equipped_scroll: ScrollContainer = %EquippedScroll
@onready var _equipped_rows: VBoxContainer = %EquippedRows
@onready var _tabs: HBoxContainer = %FamilyTabs
@onready var _browser_caption: Label = %BrowserCaption
@onready var _browser_band: HBoxContainer = %BrowserBand
@onready var _browser_scroll: ScrollContainer = %BrowserScroll
@onready var _browser_rows: VBoxContainer = %BrowserRows
@onready var _remove_button: Button = %RemoveButton
@onready var _buy_fit_button: Button = %BuyFitButton

## The style in force (`ArmoryStyle`, a `CockpitStyle`): every colour, metric and asset
## path on this surface comes from here (section 3.9 rule 5).
var _style: Resource = null
## The console's chrome layer (the bays' and wells' frames, the cells' slot chrome and
## the salvo ledges); the code-drawn recess below is the fallback for a theme-less frame.
var _chrome: Control = null
## The twelve `ui_seg_*` cuts, shared by every bay's SALVO strip.
var _seg: Array[Texture2D] = []
var _seg_blank: Texture2D = null

var _payloads: Array[Dictionary] = []
## The rack chips the current frame drew, for the read-back (`rack_rows()`) and for
## `focus_primary`'s walk. Rebuilt on every refresh: a rack's shape is player-composed, so
## it is not a fixed node set, and a freed chip is released with `queue_free` so the plate
## whose `_drop_data` started the write is still alive while that write finishes.
var _rack_views: Array[Dictionary] = []
var _selected_row: Button = null
## S30: the payload `station_inspect` (N34) inspects - the focused row or cell - and the
## P2 cluster's own INSPECT chip (N37).
var _focused_payload: Dictionary = {}
## The selected rack (0-based), the bay that wears the section 3.2 ember frame - the same
## rack ordinal the cluster's lamp lights. It follows focus and never writes anything.
var _selected_rack: int = 0

## The merged grid (P4's left half): the cells (`{type, token, index, node, caption}`),
## the selected cell's identity and the entry the meter previews (`fitting_panel.gd`'s own
## shapes, so the fit arithmetic ports cell for cell).
var _cells: Array[Dictionary] = []
var _selected: Dictionary = {}
## The equipped rows (P49): one payload per built row, the block's own read of the fit.
var _equipped: Array[Dictionary] = []
var _candidate: StringName = &""
var _grid_hull: StringName = &""
var _line_override := ""
var _line_danger := false
## The browser: one payload per built row, the tab in force and the focused row (the one
## the cluster's `FIT` acts on).
var _browser_payloads: Array[Dictionary] = []
var _browser_tab: StringName = &"all"
var _browser_focused: Dictionary = {}
var _browser_signature: Array[String] = []
var _grid_tweens: Array[Tween] = []
## The mode in force (P32). Exactly one of `_fit_cells` / `_battery_config` is visible.
var _mode: StringName = MODE_FIT


## The mode in force, `MODE_FIT` by default.
func mode() -> StringName:
	return _mode


## P40: the one hint label's text follows the mode and the selection (a content swap in a
## pinned box, N31's legal set - never a layout mutation).
func _update_hint() -> void:
	if _hint == null:
		return
	if _mode == MODE_BATTERY:
		_hint.text = PANE_HINT_BATTERY
	elif _selected.is_empty():
		_hint.text = PANE_HINT_FIT
	else:
		_hint.text = PANE_HINT_FIT_CELL


## S39 (T-170): the hold's used units, the profile's own cargo summed - the ammo
## subtitle's live "how many slots do I have" figure. The owner: "how do i know that i
## have 5 slots while buying ammo and how many slots and ammo i have left?"
func _cargo_used(profile: ProfileScript) -> int:
	if profile == null:
		return 0
	var raw: Variant = profile.call(&"cargo_items")
	if not raw is Dictionary:
		return 0
	var used := 0
	for key: Variant in (raw as Dictionary):
		used += int((raw as Dictionary)[key])
	return used


## The active hull's hold capacity, from the same resolved snapshot the flight hold reads
## (`ShipStats.cargo_max`), so the armory and the HUD cannot disagree about the total.
func _hold_capacity(profile: ProfileScript) -> int:
	if profile == null:
		return 0
	return profile.cargo_capacity()


## The active hull's fit cells, summed over `ShipFit.FIT_SLOT_KEYS` (one POWER cell, the
## `slot_capacity` elsewhere) - the FIT CELLS subtitle's first live count.
func _cell_total() -> int:
	var profile := _profile()
	if profile == null:
		return 0
	var hull := _active_hull(profile)
	var total := 0
	for slot_key: StringName in ShipFit.FIT_SLOT_KEYS:
		total += 1 if slot_key == POWER_SLOT else ShipFit.slot_capacity(hull, slot_key)
	return total


## The focus order: the racks' barrels first (rack order, each chip's own plate), then
## the inventory rows - the pane's one action source - then the ammunition rows, then the
## pane's own footer and the rail (STATION_HUB section 10).
## The focus order: the SLOT LAYOUT cells first (row-major, STATION_HUB section 17.1:
## "the cells stay selectable and keep the one focus ring"), then the browser rows, then
## the racks' barrels, then the ammunition rows (STATION_HUB section 10).
func focus_primary() -> void:
	for payload: Dictionary in _cells:
		var plate := payload[&"node"] as Button
		if plate != null and is_instance_valid(plate) and not plate.disabled:
			plate.grab_focus()
			return
	for payload: Dictionary in _browser_payloads:
		var row := payload[&"row"] as Button
		if row != null and is_instance_valid(row) and not row.disabled:
			row.grab_focus()
			return
	for view: Dictionary in _rack_views:
		for barrel: Dictionary in view[&"barrels"]:
			var control := barrel[&"name"] as Button
			if control != null and control.visible and not control.disabled:
				control.grab_focus()
				return
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return


## The style in force (section 3.9 rule 5's read-back).
func style() -> Resource:
	return _style


## The selected rack (0-based) whose bay wears the ember frame.
func selected_rack() -> int:
	return _selected_rack


## Fill a child control to its parent's rect (the pane's own children are positioned by
## the layout pass, but the chrome panel is a pure fill).
static func _stretch(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _apply_tokens() -> void:
	for payload: Dictionary in _payloads:
		_apply_icon_token(payload)


func _apply_icon_token(payload: Dictionary) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon != null and bool(payload[&"tinted"]):
		var tint: Color = _token(ROLE_TEXT_PRIMARY)
		tint.a = ROW_ICON_IDLE_ALPHA
		icon.modulate = tint


## One colour, from the style's palette (section 3.9 rule 5: this pane keeps no colour of
## its own). The theme is the fallback for the frame between the scene loading and the
## style being installed, the same silent fallback the D6 surfaces had.
func _token(token: StringName) -> Color:
	if _style != null:
		return _style.colour(token)
	return UiTokensScript.colour(self, token)


## A caption label: the pane's one 13 px label idiom (the `StationCaption` variation,
## registered in `Router.FONT_SIZE_ITEMS`, with an ink role override).
func _make_caption(text: String, role: StringName = ROLE_CAPTION) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StationCaption"
	label.text = text
	label.add_theme_color_override(&"font_color", _token(role))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
