extends Control
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

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
## A19: the CARGO HOLD block reads through the shared summary builder (the
## slots law's and the row grammar's single home).
const Summary := preload("res://ui/station/cargo_summary.gd")
## 12's 2026-10-08 V1/V2 block: the one owner of the station's price factor, read by
## `_module_price` and the pack cards' `Catalog.ammo_pack_price`.
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
const ACTION_BUY_MODULE: StringName = &"buy_module"
const ACTION_BUY_AMMO: StringName = &"buy_ammo"

## ----------------------------------------- the one equipment list (P38, its two states)
## The right sector of FIT CELLS is ONE list in two states. With no cell selected it browses
## everything the profile owns (rows tagged `FIT` when the active hull carries a cell of the
## module's family, `STORED` otherwise). With a cell selected it lists every possibility for
## that cell - the owned candidates first (`OWNED`, select-to-fit and drag-to-fit) then the
## catalogue's buyable ones (`BUYABLE`, BUY + INSPECT) - each row carrying the legality line
## the CELL INFO block speaks (the refusal strings above, wired proactively).
const TAG_FIT := "FIT"
const TAG_STORED := "STORED"
const TAG_OWNED := "OWNED"
const TAG_BUYABLE := "BUYABLE"
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
## category) leading.
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
const BROWSER_CAPTION := "MODULES · OWNED & BUYABLE"
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
const SLOT_GLYPHS: Dictionary = {
	&"engines": "engine",
	&"power": "power",
	&"weapons": "w",
	&"shields": "s",
	&"armour": "h",
	&"computers": "c",
	&"boosters": "b",
	&"utility": "u",
}
const SLOT_GLYPH_DIR := "res://assets/icons/slot/"
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s.svg"
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
const STATUS_SHORTFALL := "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"
const ACTION_REMOVE := "REMOVE"
const ACTION_BUY_FIT := "BUY & FIT"
const ACTION_BUY_FIT_SELECTED := "BUY & FIT SELECTED"
const DRAG_BROWSER: StringName = &"browser"
const DRAG_KEY_ENTRY: StringName = &"entry"
const DRAG_KEY_OWNED: StringName = &"owned"
const DRAG_KEY_PRICE: StringName = &"price"

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
## A19: the left column's CARGO HOLD block (code-built under the equipped
## block; the caption carries the overlay's own title words).
## A21.3: the left column's two pages (the owner's "two tabs if needed") —
## LAYOUT carries the slot grid + cell info, HOLD the equipped rows + the
## cargo window.
@onready var _left_tabs: HBoxContainer = %LeftTabs
@onready var _tab_layout: Button = %TabLayout
@onready var _tab_hold: Button = %TabHold
@onready var _page_layout: VBoxContainer = %PageLayout
@onready var _page_hold: VBoxContainer = %PageHold
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
var _tweens: Array[Tween] = []
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
## the cluster's `BUY & FIT` acts on).
var _browser_payloads: Array[Dictionary] = []
var _browser_tab: StringName = &"all"
var _browser_focused: Dictionary = {}
## A21: the left column's cargo window (built in `_build_cargo_preview`) —
## the C overlay's own window; the tab in force filters the rows.
var _cargo_window: Dictionary = {}
var _cargo_category: StringName = Summary.TAB_ALL
## A21.3: the page in force; the pane opens on LAYOUT exactly as before.
const LEFT_TAB_LAYOUT: StringName = &"layout"
const LEFT_TAB_HOLD: StringName = &"hold"
var _left_tab: StringName = LEFT_TAB_LAYOUT
var _browser_signature: Array[String] = []
var _grid_tweens: Array[Tween] = []
## The mode in force (P32). Exactly one of `_fit_cells` / `_battery_config` is visible.
var _mode: StringName = MODE_FIT


func _ready() -> void:
	_build_modes()
	_build_console()
	_build_racks()
	_build_empty_cells()
	_build_grid_surface()
	_build_browser()
	_build_left_tabs()
	_build_cargo_preview()
	_wire_actions()
	_apply_tokens()
	_connect_scroll()
	resized.connect(_lay)
	_lay()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_lay()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


## -------------------------------------------------------------- the two modes (P32)
##
## The two-entry switch (P2 `ActionInline` pair, UI_SPEC section 8) sits in the header band.
## `set_mode` is a pure visibility operation (A5.5/N24): it hides the other mode root and
## swaps the one hint label's text, never a size, a position or a tree shape.
func _build_modes() -> void:
	if _mode_fit != null:
		_mode_fit.text = MODE_FIT_LABEL
		## S36 (UI_SPEC section 15.1): the mode switch pair wears C3 `ui_inline_chip`.
		ChromeFamily.apply_chip(_mode_fit)
		_mode_fit.pressed.connect(set_mode.bind(MODE_FIT))
	if _mode_battery != null:
		_mode_battery.text = MODE_BATTERY_LABEL
		ChromeFamily.apply_chip(_mode_battery)
		_mode_battery.pressed.connect(set_mode.bind(MODE_BATTERY))
	_apply_mode()


## The mode in force, `MODE_FIT` by default.
func mode() -> StringName:
	return _mode


## Switch to one of the two modes. `MODE_FIT` and `MODE_BATTERY` are the only legal values;
## anything else is ignored. Exactly one mode root ends up visible.
func set_mode(wanted: StringName) -> void:
	if wanted != MODE_FIT and wanted != MODE_BATTERY:
		return
	if wanted == _mode:
		return
	_mode = wanted
	_apply_mode()
	## The shared menu's row source is mode-dependent (the FIT CELLS socket filter and its
	## two states vs BATTERY CONFIG's flat list): re-source it after the move.
	_refresh_browser()
	AudioManager.play_ui(AudioManager.UiCue.CLICK)


func _apply_mode() -> void:
	var fitting := _mode == MODE_FIT
	## P39a (S35): the ONE menu subtree follows the active mode's right sector. A mode switch
	## is a command, never a hover/focus/selection state, so A5.5/N24 is untouched.
	var host: Control = _fit_right if fitting else _eq_sector
	if _menu_sector != null and host != null and _menu_sector.get_parent() != host:
		_menu_sector.reparent(host, false)
		## F14: the host's own reserved slot (`EqFoot`) closes the sector, so the shared menu
		## opens it - a reparent appends, and the slot is the sector's last child.
		host.move_child(_menu_sector, 0)
	if _fit_cells != null:
		_fit_cells.visible = fitting
	if _battery_config != null:
		_battery_config.visible = not fitting
	if _mode_fit != null:
		_mode_fit.set_pressed_no_signal(fitting)
	if _mode_battery != null:
		_mode_battery.set_pressed_no_signal(not fitting)
	## F3: the one band's value-column words follow the mode (a content swap in the pinned
	## box, N31's legal set) - the shared menu is one subtree both modes render.
	if _browser_band != null:
		_build_list_band(
			_browser_band, _band_captions(), _band_widths(), BAND_MODULE
		)
	_update_subtitle()
	_update_hint()


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


## P38's own subtitle, swapped per mode the same way the hint is (a content swap in a pinned
## box, N31's legal set - never a layout mutation). A mode command may set the text; a hover or
## focus state may not (A5.5/N24).
func _update_subtitle() -> void:
	if _subtitle == null:
		return
	if _mode == MODE_BATTERY:
		var profile := _profile()
		_subtitle.text = SUBTITLE % [
			RACK_COUNT,
			Catalog.AMMO_PACKS.size(),
			_cargo_used(profile),
			_hold_capacity(profile),
		]
	else:
		_subtitle.text = SUBTITLE_FIT % [_cell_total(), _owned_module_total()]


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
	var hull := _active_hull(profile)
	return int(ShipFit.resolve(hull, _resolved_fit(profile, hull)).cargo_max)


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


## The module bases the bag owns at least one of - the FIT CELLS subtitle's second live count.
func _owned_module_total() -> int:
	var profile := _profile()
	if profile == null:
		return 0
	var total := 0
	for module_id: StringName in ModuleData.MODULES:
		if _owned_total(profile, module_id) > 0:
			total += 1
	return total


## STATION_HUB section 12.4 plus 09 section 11: `&"credits"` moves every price and tag,
## `&"ammo"` and `&"cargo"` the held figures (an ammo purchase moves both), and the racks
## and the inventory follow `&"fits"` (the fit a rack's cells live in), `&"modules"` (the
## bag its `OWNED ×<n>` figure and every drag spend from), `&"ships"` (the active hull's W
## cells) and `&"batteries"` (a rack write's own signal).
func refresh_profile(key: StringName) -> void:
	if key == &"credits" or key == &"ammo" or key == &"cargo":
		_refresh_rows()
		_refresh_browser()
		_refresh_cargo_preview()
	if key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_racks()
		_refresh_empty_cells()
	if key == &"modules" or key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_browser()
	if key == &"fits" or key == &"ships" or key == &"modules":
		_sync_grid(_active_hull(_profile()))
		_refresh_footer()
		_sync_equipped()
	_refresh_cell_info()
	_update_subtitle()


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


## Swap the whole style at runtime, from an `ArmoryStyle` resource: restyle and relayout
## with no code edit.
func set_style(new_style: Resource) -> void:
	if new_style == null:
		return
	_style = new_style
	_apply_style()


## Swap the style from a `.tres` path (`ArmoryStyle.ARMORY_USER_PATH` by default).
func set_style_file(path: String) -> void:
	set_style(StyleScript.load_style(path))


## The selected rack (0-based) whose bay wears the ember frame.
func selected_rack() -> int:
	return _selected_rack


## Mark one rack as the selected bay (nothing is written - the frame is presentation).
func set_selected_rack(rack: int) -> void:
	var wanted: int = rack if rack >= 0 and rack < _rack_views.size() else -1
	if wanted == _selected_rack:
		return
	_selected_rack = wanted
	for view: Dictionary in _rack_views:
		_style_bay(view)


## The keyboard half of the selection seam: the drawn `(1)`..`(5)` hints (`RACK_KEY`) are
## 09 section 11's own rack keys, so a digit moves the section 3.2 ember frame to that bay.
## Presentation only - `set_selected_rack` writes nothing.
func _unhandled_input(event: InputEvent) -> void:
	## P38a (STATION_HUB 21.1, S35): a pointer press on **empty chrome** - not consumed by
	## any socket or row - clears the selection and the preview. A press on any control is
	## consumed by that control before it can reach here, so this is empty-chrome routing
	## only. The pane's own rect guards it: a click elsewhere in the shell is not ours.
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			if not get_global_rect().has_point(button.global_position):
				return
			if _selected.is_empty() and _focused_payload.is_empty():
				return
			_clear_away()
			get_viewport().set_input_as_handled()
			return
	if not event.is_pressed() or event.is_echo():
		return
	for rack in RACK_COUNT:
		if event.is_action_pressed(RACK_ACTION % (rack + 1)):
			set_selected_rack(rack)
			get_viewport().set_input_as_handled()
			return


## P38a: the empty-chrome press. Clears the cell selection, the hovered preview (CELL INFO
## and the additive inspector block) and refreshes the hint - the right menu returns to its
## browse state. Idempotent: with nothing selected or previewed it writes nothing.
func _clear_away() -> void:
	var had_selection := not _selected.is_empty()
	var had_preview := not _focused_payload.is_empty()
	_selected = {}
	_candidate = &""
	_line_override = ""
	_line_danger = false
	_focused_payload = {}
	if had_selection or had_preview:
		inspect_requested.emit("", "", false)
	_apply_cell_selection()
	_refresh_footer()
	_refresh_browser()
	_refresh_cell_info()
	_update_hint()


## The pointer half of the remove gesture the chrome advertises (RIGHT-CLICK TO PULL): a
## right-button press over a fitted cell returns its barrel to the inventory. Read off
## the hovered control and its ancestors, so the cell's own children (the name plate, the
## `x`) do not have to re-implement it.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_RIGHT:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null and hovered != self:
		if hovered is BarrelCell:
			var cell := hovered as BarrelCell
			remove_barrel(cell.rack, cell.slot)
			accept_event()
			return
		hovered = hovered.get_parent_control()


## ------------------------------------------------------------------ the console


## Mount the console's own geometry: the console is the style's **derivation from the
## host rect** (P6), and the bay grid, the wells band and the item grids fill it.
func _build_console() -> void:
	if _style == null:
		_style = StyleScript.load_style()
	_seg.clear()
	for digit: int in 10:
		_seg.append(_style.texture(_style.seg_path(str(digit))))
	_seg_blank = _style.texture(_style.seg_path(_style.seg_blank_cell))
	_chrome = ConsolePanels.new()
	_chrome.name = "ConsolePanels"
	_console.add_child(_chrome)
	_console.move_child(_chrome, 1)
	_stretch(_chrome)
	## The bays live in a `VBoxContainer` whose own stacking the layout pass corrects on
	## every sort (the S5 suites read it by child index); the two scroll grids are plain
	## `Control`s, so nothing re-lays the cards and rows their own pass placed.
	_rack_rows.sort_children.connect(_lay_bays)
	_apply_style()


## Fill a child control to its parent's rect (the pane's own children are positioned by
## the layout pass, but the chrome panel is a pure fill).
static func _stretch(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Re-read the style into every part of the console: the chrome, the group boxes and the
## bay grid. Called once at build and again on a restyle.
func _apply_style() -> void:
	if _style == null or not is_node_ready():
		return
	## A4.1: the scripted console master retires from the pane - clearing the nine-slice's
	## texture is what unwires it (the master itself stays on disk; the module host's own
	## panel frame is the pane's outer edge now).
	_plate.texture = null
	_title.text = "ARMORY"
	_update_subtitle()
	_update_hint()
	_tag.text = TAG_LIST_PREFIX + TAG_LIST_SEPARATOR.join(_id_list())
	_apply_tokens()
	_lay()
	for view: Dictionary in _rack_views:
		_style_bay(view)
	for payload: Dictionary in _payloads:
		_refresh_row(payload)


## P38/P39's one layout entry. Each mode is two equal sectors (containers + relative sizing,
## A5): the console rides BATTERY CONFIG's left sector, the EQ container its right, and the
## two equipment lists are containers of their own sectors. The pane places only what sits
## *inside* a hand-derived box (a rack row's own children); the boxes themselves are the
## container's. The console is sized by its sector on the sort, so `block_size()`, `bay_rects()`
## and `well_rects()` read the sector's own box. Safe to call before the host has a size.
func _lay() -> void:
	if _style == null or not is_node_ready():
		return
	_flush_layout()
	## The console rides the BATTERY CONFIG mode, which is hidden while FIT CELLS shows, and
	## Godot does not sort a hidden container. Show it for this one layout pass (the draw
	## happens after the frame, so nothing flickers), let the sector sort size the console and
	## its body, then restore the mode's visibility. This keeps `block_size()`, `bay_rects()`
	## and `well_rects()` correct in the landing mode, where the suites read them.
	var was_hidden: bool = _battery_config != null and not _battery_config.visible
	if was_hidden:
		_battery_config.visible = true
	_flush_layout()
	_flush_console()
	if was_hidden:
		_battery_config.visible = false
	_lay_bays()
	_update_chrome()


## Sort the console's own body tree (the stacked rack rows and the wells band) after `_lay`
## pinned the console rect, so every row carries its container-given box before the pane
## places what sits inside it (a hidden mode is not sorted by the engine).
func _flush_console() -> void:
	var stack: Array[Node] = [_console]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Container:
			(node as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
		for child: Node in node.get_children():
			stack.append(child)


## The merged pane's container tree flushes its own sort here, so the synchronous pass a
## headless suite reads (and `_settle_layout` drives) leaves every child at its laid-out
## position before the first input lands - the pre-merge pane positioned by hand and the
## suites read the very same frame. P36: the console's own body is a container tree now
## (the stacked rack rows and the wells band), so it sorts like every other box.
func _flush_layout() -> void:
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Container:
			(node as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
		for child: Node in node.get_children():
			stack.append(child)


## A control's rect in the pane's own space (the suites read the pane's frame).
func _pane_rect(control: Control) -> Rect2:
	if control == null:
		return Rect2()
	return Rect2(control.get_global_rect().position - get_global_rect().position, control.size)


## Place every rack row's own children inside the row the container gave it (the row's head
## block, its four cells and its salvo ledge). The rows themselves are stacked full-width by
## `%RackRows`; only what sits inside a row is the pane's to place.
func _lay_bays() -> void:
	if _style == null or _rack_rows == null:
		return
	for child: Node in _rack_rows.get_children():
		var row := child as Control
		if row == null:
			continue
		_position_bay(row)
	_update_chrome()


## One bay's own children at the mockup's own offsets: the head's label, key and state
## chip along the top, the cells in their 2x2 grid and the ledge at the foot.
func _position_bay(bay: Control) -> void:
	if _style == null or bay == null:
		return
	var rect := Rect2(Vector2.ZERO, bay.size)
	_position_head(bay.get_node_or_null(^"Box/Head") as Control)
	_position_cells(bay.get_node_or_null(^"Box/Barrels") as Control)
	_position_drop_cells(bay.get_node_or_null(^"Box/Cells") as Control)
	var strip := bay.get_node_or_null(^"Box/Salvo") as SalvoStrip
	if strip != null:
		strip.position = _style.ledge_rect(rect).position
		strip.size = _style.ledge_rect(rect).size
		strip.configure(_style, _seg, _seg_blank)
		strip.set_figure(strip.figure())
	var marks := bay.get_node_or_null(^"Box/BayMarks") as BayMarks
	if marks != null:
		marks.position = Vector2.ZERO
		marks.size = bay.size
	var chip := bay.get_node_or_null(^"Box/Head/Chip") as Control
	if chip != null:
		chip.position = _style.head_chip_rect(rect).position
		chip.size = _style.head_chip_rect(rect).size


## One rack row's head, at the row's left: `B<n>` and its key hint beside it, the state chip
## with its label right-aligned in the head block. The head's own rect is the row's, so the
## offsets are row-relative; the containing box reflows its children on every sort, so the
## positions are re-applied here each time (the suites read the labels by name).
func _position_head(head: Control) -> void:
	if _style == null or head == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(head))
	var mid: float = maxf((bay.size.y - 18.0) * 0.5, 0.0)
	var label := head.get_node_or_null(^"Label") as Control
	if label != null:
		label.position = Vector2(_style.cell_margin, mid)
		label.size = Vector2(40.0, 18.0)
	var key := head.get_node_or_null(^"Key") as Control
	if key != null:
		key.position = Vector2(_style.cell_margin + 30.0, mid)
		key.size = Vector2(36.0, 18.0)
	var chip := head.get_node_or_null(^"Chip") as Control
	if chip != null:
		chip.position = _style.head_chip_rect(bay).position
		chip.size = _style.head_chip_rect(bay).size
	var state := head.get_node_or_null(^"State") as Control
	if state != null:
		var chip_box: Rect2 = _style.head_chip_rect(bay)
		state.position = chip_box.position + Vector2(16.0, (_style.head_chip.y - 18.0) * 0.5)
		state.size = Vector2(chip_box.size.x - 20.0, 18.0)


## One bay child's own bay size: the rect of the `RackRow` it lives in, walked up from the
## child, so a head or chip list laid out from its ancestor's rect can never read a stale
## or zero box (the intermediate containers fill the bay only after their own sort).
func _bay_size_of(control: Control) -> Vector2:
	var node: Node = control.get_parent()
	while node != null:
		if node is RackRow:
			return (node as Control).size
		node = node.get_parent()
	return Vector2.ZERO


## One bay's fitted chips, each inside its own slot-chrome cell, with the `x` in the
## cell's top-right corner.
##
## Both children clip their text, so a plain row gives each of them a **zero** width: the
## `x`'s own box is the top-right corner and the name plate takes the rest of the cell,
## which keeps both hit targets hittable through every layout pass (the D7/S10 lesson).
func _position_cells(barrels: Control) -> void:
	if _style == null or barrels == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(barrels))
	var index := 0
	for child: Node in barrels.get_children():
		var chip := child as Control
		if chip == null:
			continue
		## The grid slot is the cell's **position in the rack** (its own order), never its
		## W-cell index: a bay can hold W5..W7, and those indices must not address the grid.
		var cell: Rect2 = _style.bay_cell_rect(index, bay)
		chip.position = cell.position
		chip.size = cell.size
		_position_cell_children(chip)
		index += 1


## One chip's own children: the name plate over the whole cell but its bottom strip (the
## chip's own drag zone), the `x`'s box in the top-right corner, and the two name lines.
func _position_cell_children(chip: Control) -> void:
	var cell := Rect2(Vector2.ZERO, chip.size)
	var name_button := chip.get_node_or_null(^"Name") as Control
	if name_button != null:
		## The chip is a Container: the name plate takes every column the `x` does not
		## (EXPAND) and stops 10 px short of the cell's foot, which stays the chip's own
		## drag zone (a press there is the barrel drag the suites drive).
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		name_button.custom_minimum_size = Vector2(0.0, maxf(cell.size.y - 10.0, 0.0))
		name_button.position = Vector2.ZERO
		name_button.size = Vector2(maxf(cell.size.x - 24.0, 0.0), maxf(cell.size.y - 10.0, 0.0))
	var close := chip.get_node_or_null(^"Close") as Control
	if close != null:
		close.size_flags_horizontal = Control.SIZE_SHRINK_END
		close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		close.custom_minimum_size = Vector2(24.0, 24.0)
		close.position = Vector2(maxf(cell.size.x - 26.0, 0.0), 0.0)
		close.size = Vector2(24.0, 24.0)
	var plate := chip.get_node_or_null(^"Name") as Control
	var name_label := plate.get_node_or_null(^"NamePlate") as Control if plate != null else null
	var variant_label := plate.get_node_or_null(^"Variant") as Control if plate != null else null
	var has_variant := variant_label != null and not (variant_label as Label).text.is_empty()
	if name_label != null:
		var top: float = 4.0 if has_variant else (plate.size.y - 18.0) * 0.5
		name_label.position = Vector2(6.0, top)
		name_label.size = Vector2(maxf(cell.size.x - 24.0, 0.0), 18.0)
	if variant_label != null:
		variant_label.position = Vector2(6.0, 22.0)
		variant_label.size = Vector2(maxf(cell.size.x - 24.0, 0.0), 18.0)


## One bay's empty cells: the `DROP HERE` cue centred in each recess. Every pad sits in
## its **own** grid slot (the slot it was built for), never in its child order: the pads
## only exist for the empty slots, so counting them from zero would land the first cue on
## the fitted chip and leave the bay's last slot bare.
func _position_drop_cells(cells: Control) -> void:
	if _style == null or cells == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(cells))
	for child: Node in cells.get_children():
		var pad := child as DropCell
		if pad == null:
			continue
		var cell: Rect2 = _style.bay_cell_rect(pad.slot, bay)
		pad.position = cell.position
		pad.size = cell.size
		var cue := pad.get_node_or_null(^"Cue") as Control
		if cue != null:
			cue.position = Vector2.ZERO
			cue.size = cell.size



## Hand the console's chrome node the rects the style derives (all console-local): the
## bays (A4.1 frames), the wells halves (A4.1 frames), the four slot-chrome cells of every
## bay (A4.2) and the salvo ledges.
func _update_chrome() -> void:
	if _chrome == null or _style == null:
		return
	var console := Rect2(Vector2.ZERO, _console.size)
	var bays: Array[Rect2] = []
	var cells: Array[Rect2] = []
	var ledges: Array[Rect2] = []
	for index in _rack_rows.get_child_count():
		var bay: Rect2 = _style.bay_rect(index, console)
		bays.append(bay)
		for cell in 4:
			cells.append(_style.bay_cell_rect(cell, bay))
		ledges.append(_style.ledge_rect(bay))
	var wells: Array[Rect2] = []
	for half: Control in [_empty_margin, _summary_margin]:
		wells.append(_well_plate_rect(half, _console))
	_chrome.configure(_style, bays, cells, ledges, wells)


## F4 (D23-R1, LOW): a well half's plate is the half's own box capped at its **content
## block**, so a caption-only half draws a caption-high plate instead of a 92 px empty box
## (`get_combined_minimum_size` is the container's own answer - no hand number here). The
## half itself keeps the band's box: the layout pins read it, only the drawn plate collapses.
func _well_plate_rect(half: Control, console: Control) -> Rect2:
	if half == null or console == null:
		return Rect2()
	return Rect2(
		half.global_position - console.global_position,
		Vector2(half.size.x, minf(half.size.y, half.get_combined_minimum_size().y))
	)


## ------------------------------------------------------------------ the token lookup


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
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## A caption label: the pane's one 13 px label idiom (the `StationCaption` variation,
## registered in `Router.FONT_SIZE_ITEMS`, with an ink role override).
func _make_caption(text: String, role: StringName = ROLE_CAPTION) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StationCaption"
	label.text = text
	label.add_theme_color_override(&"font_color", _token(role))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## ------------------------------------------------------------------ the pack cards


func _id_list() -> PackedStringArray:
	var ids := PackedStringArray()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		ids.append(String(pack.get(&"id", &"")))
	return ids


## One ammunition **row** (A18, the owner's 2026-10-15 pass): the shared
## menu's own full-width container row at the pack's content - the P5 worded
## held line, the section 5.1 state chip and state line, and the `BUY` chip,
## on the row's C4 plate (`RowPlate` draws it at the row's own rect now, so
## the nine-slice no longer crushes at 320). Every cell the S5 suites read is
## still built here (`Title`, `Meta`, `Held`/`Value` + `Held`/`Caption`,
## `Price`/`Value`, `Status`/`Value`), so the state lines and figures keep
## one home.
func _build_card(pack: Dictionary) -> Dictionary:
	var pack_id: StringName = pack.get(&"id", &"")
	var name_text := String(pack.get(&"name", ""))
	var rounds := int(pack.get(&"rounds", 0))
	## V1 (12's 2026-10-08 block): the pack's price at this station, through the catalogue's
	## own station-aware reader, so the card, the buy chip and the charge read one number.
	var cost := Catalog.ammo_pack_price(pack_id, _docked_station(), _station_standing())
	var complete := pack_id != &"" and not name_text.is_empty() and rounds > 0
	var card := Button.new()
	card.name = "Ammo%s" % String(pack_id).to_pascal_case()
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.disabled = not complete
	## A18: the row spans the shared menu (the browser rows' own fill), 76 tall
	## like every other segment's rows.
	card.custom_minimum_size = Vector2(0.0, AMMO_ROW_HEIGHT)
	var frame := RowPlate.new()
	frame.name = "RowPlate"
	card.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_TEXT_INSET * 2.0)
	inner.add_theme_constant_override(&"margin_top", 8.0)
	inner.add_theme_constant_override(&"margin_right", ROW_TEXT_INSET * 2.0)
	inner.add_theme_constant_override(&"margin_bottom", 8.0)
	card.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var icon := _make_icon(String(pack.get(&"icon", "")), BROWSER_ICON)
	if icon != null:
		box.add_child(icon)
	else:
		var gap := Control.new()
		gap.name = "IconGap"
		gap.custom_minimum_size = Vector2(BROWSER_ICON, 0.0)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(gap)
	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override(&"separation", 2)
	## N45: the shared menu's own fixed title column - long names trim instead
	## of pushing the value columns past the window.
	title_box.custom_minimum_size = Vector2(BROWSER_TITLE_COLUMN, 0.0)
	title_box.size_flags_horizontal = Control.SIZE_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_box)
	## The C overlay's own read: the pack names print upper-case, so the
	## ammunition rows read like the module rows beside them.
	var title := _make_label(
		&"StationValue", (name_text if complete else TAG_UNAVAILABLE).to_upper(), true
	)
	title.name = "Title"
	title_box.add_child(title)
	var meta := _make_label(
		&"StationMeta", ROUNDS_CAPTION % rounds if complete else META_INCOMPLETE, true
	)
	meta.name = "Meta"
	title_box.add_child(meta)
	var slack := Control.new()
	slack.name = "TitleSlack"
	slack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(slack)
	var held_col := VBoxContainer.new()
	held_col.name = "HeldCol"
	held_col.add_theme_constant_override(&"separation", 2)
	held_col.custom_minimum_size = Vector2(BAND_HELD_COLUMN, 0.0)
	held_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	held_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(held_col)
	var held := VBoxContainer.new()
	held.name = "Held"
	held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_col.add_child(held)
	var held_value := _make_caption("")
	held_value.name = "Value"
	held_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	held.add_child(held_value)
	var held_caption := _make_caption("")
	held_caption.name = "Caption"
	held_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	held.add_child(held_caption)
	var status := ChipPlate.new()
	status.name = "Status"
	status.custom_minimum_size = Vector2(BAND_TAG_COLUMN, 22.0)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(status)
	var tag := _make_caption(TAG_EMPTY)
	tag.name = "Value"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status.add_child(tag)
	var price_col := VBoxContainer.new()
	price_col.name = "PriceCol"
	price_col.custom_minimum_size = Vector2(BAND_COST_COLUMN, 0.0)
	price_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price_col)
	var price := VBoxContainer.new()
	price.name = "Price"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_col.add_child(price)
	var price_value := _make_caption("")
	price_value.name = "Value"
	price_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.add_child(price_value)
	var buy := Button.new()
	buy.name = "Buy"
	## A18: the chip is the shared menu's own ActionInline press (the browser
	## rows' `BUY`), so the ammunition rows carry the segment's own action
	## language. Mouse-only (FOCUS_NONE): the row keeps the pane's focus order,
	## and a press on the chip buys through the same handler the row's own
	## press uses.
	buy.theme_type_variation = &"StationButton"
	buy.custom_minimum_size = ACTION_INLINE
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.focus_mode = Control.FOCUS_NONE
	buy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy.text = BUY_CHIP
	box.add_child(buy)
	var payload := {
		&"id": pack_id,
		&"name": name_text,
		&"rounds": rounds,
		&"cost": cost,
		&"complete": complete,
		&"row": card,
		&"plate": frame,
		&"icon": icon,
		&"tinted": _is_flat_glyph(String(pack.get(&"icon", ""))),
		&"title": title,
		&"meta": meta,
		&"held": held_value,
		&"held_caption": held_caption,
		&"price": price_value,
		&"tag": tag,
		&"status": status,
		&"buy": buy,
	}
	if complete:
		card.pressed.connect(_on_row_pressed.bind(payload))
		buy.pressed.connect(_on_row_pressed.bind(payload))
		card.focus_entered.connect(_on_row_focused.bind(card, payload))
		card.mouse_entered.connect(_on_row_hovered.bind(payload, true))
		card.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_browser_rows.add_child(card)
	frame.configure(_style)
	status.configure(_style, false, false)
	return payload


func _make_label(variation: StringName, text: String, trim := false) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if trim:
		## N45: a catalogue name squeezed into a fixed column trims with an ellipsis instead
		## of spilling past the branch (a Button is not a Container and does not clip).
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _make_icon(icon_path: String, cell: float) -> TextureRect:
	if icon_path.is_empty():
		return null
	var tinted := _is_flat_glyph(icon_path)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(cell, cell)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(_icon_source(icon_path))
	var base := _token(ROLE_TEXT_PRIMARY) if tinted else Color.WHITE
	base.a = ROW_ICON_IDLE_ALPHA
	icon.modulate = base
	return icon


func _is_flat_glyph(icon_path: String) -> bool:
	return FLAT_GLYPH_ICONS.has(icon_path)


func _icon_source(icon_path: String) -> String:
	if icon_path.ends_with(".svg"):
		return icon_path
	if not _is_flat_glyph(icon_path):
		return icon_path
	return TINT_DIR + icon_path.get_file()


func _connect_scroll() -> void:
	## The scroll cue has no other home: the station shell owns no list of its own.
	for scroll: ScrollContainer in [_browser_scroll, _equipped_scroll]:
		if scroll != null and scroll.has_signal(&"scroll_started"):
			scroll.connect(&"scroll_started", _on_scroll_started)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	_focused_payload = payload
	row.set_pressed_no_signal(true)
	_inspect_row(payload, true)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	_inspect_row(payload, hovered)


## S30 census row 7 (UI_SPEC section 12.5): the rack's salvo line describes through the
## existing `inspect_requested` chain (the N27 tooltip) instead of `tooltip_text`.
func _on_rack_inspected(line: String, hovered: bool) -> void:
	if not hovered:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(line, "", false)


## S30 census row 7: a grid cell's own naming line, published on the same chain.
func _on_cell_hovered(payload: Dictionary, hovered: bool) -> void:
	if not hovered:
		inspect_requested.emit("", "", false)
		return
	var profile := _profile()
	var fit := _resolved_fit(profile, _active_hull(profile))
	inspect_requested.emit(cell_tooltip(payload, profile, fit), "", false)
	var icon := payload.get(&"icon", null) as TextureRect
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


func _on_row_pressed(payload: Dictionary) -> void:
	if _inspect_mode:
		_emit_sheet(payload)
		return
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_inspect_row(payload, true)
	## UI_SPEC section 17 A4/A5: the pack purchase is a door - the confirm dialog opens
	## here and the confirmed answer runs `_purchase_ammo`, the transaction unchanged.
	_request_buy_confirm(
		AMMO_CONFIRM_NAME % [String(payload[&"name"]).to_upper(), int(payload[&"rounds"])],
		int(payload[&"cost"]), ACTION_BUY_AMMO, StringName(payload[&"id"])
	)


func _refresh_rows() -> void:
	for payload: Dictionary in _payloads:
		_refresh_row(payload)


## One ammunition card, in the S5 model (10 section 6.1): the purchase delivers **cargo
## units**, so the held line counts the hold's own units expressed in **rounds** (P5:
## `HELD 60 ROUNDS - HOLD 30 UNITS`) against the family's advisory unit ceiling. The four
## state lines follow the same two figures, so a card that has bought nothing yet reads
## EMPTY even while the magazine a previous launch loaded still holds rounds - which is
## exactly what the player is about to buy.
func _refresh_row(payload: Dictionary) -> void:
	if not is_node_ready():
		return
	var price: Label = payload[&"price"]
	var tag: Label = payload[&"tag"]
	var held: Label = payload[&"held"]
	var caption: Label = payload[&"held_caption"]
	if not bool(payload[&"complete"]):
		held.text = HELD_FORMAT % [0, 0]
		caption.text = META_INCOMPLETE
		tag.text = TAG_UNAVAILABLE
		price.text = PRICE_FORMAT % UNAVAILABLE_VALUE
		price.remove_theme_color_override(&"font_color")
		_style_danger(payload, true)
		return
	var profile := _profile()
	var affordable := profile == null or bool(profile.call(&"can_afford", int(payload[&"cost"])))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(ROLE_DANGER))
	price.text = PRICE_FORMAT % _format_int(int(payload[&"cost"]))
	var pack_id: StringName = payload[&"id"]
	var held_units := 0
	var capacity := 0
	if profile != null:
		held_units = int(profile.call(&"ammo_units", pack_id))
		capacity = _unit_cap(profile, pack_id)
	var rounds_held := held_units * maxi(1, int(Catalog.ROUNDS_PER_CARGO_UNIT))
	held.text = HELD_FORMAT % [rounds_held, capacity]
	var over_cap := false
	if held_units <= 0:
		tag.text = TAG_EMPTY
		caption.text = META_NO_ROUNDS
	elif held_units > capacity:
		tag.text = TAG_OVER_CAP
		caption.text = META_ADVISORY
		over_cap = true
	elif held_units == capacity:
		tag.text = TAG_AT_CAP
		caption.text = META_NO_CAP
	else:
		tag.text = TAG_IN_STOCK
		caption.text = META_BELOW_CAPACITY
	## Section 3.10: danger/refusal states reuse section 3.1/3.1b verbatim as row
	## treatments - the label plus a 1 px code-drawn frame; digits never recolour.
	_style_danger(payload, over_cap or not affordable)


## The section 3.1/3.1b row treatment on one ammunition card: the code-drawn frame, the
## state chip's own shape (the chevron when the state is the dangerous one) and the state
## label in the danger role (its own text never recoloured by the load).
func _style_danger(payload: Dictionary, danger: bool) -> void:
	var plate: RowPlate = payload.get(&"plate", null)
	if plate != null:
		plate.set_danger(danger)
	var tag: Label = payload.get(&"tag", null)
	var over_cap: bool = tag != null and tag.text == TAG_OVER_CAP
	var status: ChipPlate = payload.get(&"status", null)
	if status != null:
		status.configure(_style, danger, over_cap)
	if tag == null:
		return
	if danger:
		## A4.3/L227: the danger label is the bright ember. `accent_danger` can never clear
		## 4.5:1 on any fill (its ceiling is 4.38:1 against pure black); the bright pair
		## measures 4.86:1 on `chip_danger_bg`.
		tag.add_theme_color_override(&"font_color", _token(ROLE_DANGER_BRIGHT))
	else:
		tag.remove_theme_color_override(&"font_color")


## The `MAX` figure of one ammunition card: the family's advisory `ammo_max` expressed in
## cargo units, rounded **up** like the purchase's own unit arithmetic
## (`PlayerProfile._ammo_units_for`), so a family whose ceiling is not a multiple of
## `ROUNDS_PER_CARGO_UNIT` still shows the smallest number of units that reaches it.
## Never 0: the line would read `HOLD 0 UNITS` for a family the catalogue ships.
func _unit_cap(profile: ProfileScript, pack_id: StringName) -> int:
	var rounds := int(profile.call(&"ammo_max", pack_id))
	var per_unit := maxi(1, int(Catalog.ROUNDS_PER_CARGO_UNIT))
	return maxi(1, ceili(float(rounds) / float(per_unit)))


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## The row's identity for the inspector's title: its name and price phrase, the same
## values `_row_hint` prints, with the key-hint verb kept for the status strip alone.
func _row_title(payload: Dictionary) -> String:
	return INSPECT_TITLE_FORMAT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## CONTRACTS section 23.1: the inspector's additive hover surface. The row's own
## identity line is the title, the catalogue description is the body, and a row that is
## not buyable wears the danger colour. A leave clears both by handing the shell
## `title == ""`.
func _inspect_row(payload: Dictionary, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		_row_title(payload),
		Catalog.describe(StringName(payload[&"id"])),
		not bool(payload.get(&"complete", true))
	)


## --------------------------------------------------------------------- the racks


func _build_racks() -> void:
	_refresh_racks()


func _build_empty_cells() -> void:
	_refresh_empty_cells()


## BATTERY CONFIG's read-only empty-cell list (P34, 09 section 10's idiom): one
## `W<n> — EMPTY` line per hull W cell that holds no weapon. The racks above carry the
## fitted weapons; this list carries the cells no rack reaches.
func _refresh_empty_cells() -> void:
	if _empty_rows == null:
		return
	_clear(_empty_rows)
	var profile := _profile()
	var cells := _weapon_cells(profile) if profile != null else []
	var count := 0
	for index in cells.size():
		if StringName(String(cells[index])) != &"":
			continue
		var line := _make_caption(EMPTY_CELL_FORMAT % (index + 1), ROLE_CAPTION)
		line.name = "Empty%d" % (index + 1)
		line.custom_minimum_size = Vector2(0.0, 22.0)
		_empty_rows.add_child(line)
		count += 1
	if _empty_caption != null:
		_empty_caption.text = EMPTY_CELLS_CAPTION % count


## The CELL INFO block (P33, item 1): the selected cell's identity (id + family), its power
## draw, the fitted module (or EMPTY) and a proactive legality line built from the pane's
## own refusal strings. The block reads its select prompt with no selection.
func _refresh_cell_info() -> void:
	if _cell_info_id == null:
		return
	if _selected.is_empty():
		_cell_info_id.text = CELL_INFO_SELECT
		_cell_info_power.text = ""
		_cell_info_fitted.text = ""
		_cell_info_legal.text = ""
		return
	var profile := _profile()
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	var entry := _cell_module(fit, slot_key, index)
	var base := _base_id(profile, entry)
	_cell_info_id.text = CELL_INFO_ID % [
		String(_selected[&"token"]), index + 1, _slot_word(slot_key)
	]
	var power := _power_of(profile, hull, fit)
	var cell_draw := int(ModuleData.module(base).get(&"draw", 0)) if base != &"" else 0
	_cell_info_power.text = CELL_INFO_POWER % [
		cell_draw, int(power.get(&"draw", 0)), int(power.get(&"out", 0))
	]
	_cell_info_fitted.text = (
		CELL_INFO_FITTED_EMPTY if entry == &"" else CELL_INFO_FITTED % _module_name(base)
	)
	var legal := _cell_legality(profile, hull, fit, slot_key, index)
	_cell_info_legal.text = legal
	_cell_info_legal.add_theme_color_override(
		&"font_color",
		_token(ROLE_CAPTION if legal == CELL_INFO_LEGAL_OK else ROLE_DANGER_BRIGHT)
	)


## The selected cell's proactive legality hint (P33): the mandatory refusal for a mandatory
## cell, the read candidate's own refusal when one is being read, else the current fit's
## legality - every wording is a pinned refusal string, never a second vocabulary.
func _cell_legality(
	profile: ProfileScript, hull: StringName, fit: Dictionary,
	slot_key: StringName, index: int
) -> String:
	if ShipFit.MANDATORY_SLOT_KEYS.has(slot_key):
		return REFUSAL_MANDATORY
	if _candidate != &"" and _candidate_slot(profile, _candidate) == slot_key:
		var refusal := _cell_refusal(profile, hull, index, _candidate)
		return refusal if not refusal.is_empty() else CELL_INFO_LEGAL_OK
	var legal := ShipFit.fit_legal(hull, _base_fit(profile, fit))
	if bool(legal.get(&"legal", true)):
		return CELL_INFO_LEGAL_OK
	return _fit_refusal(legal)


## ------------------------------------------------- the EQUIPPED block (P49)


## The block's refresh: the caption's fitted/total counts, then one row per fitted
## module in the SLOT LAYOUT grid's own cell order (`_cells`, row-major). Empty cells
## are not listed. BATTERY CONFIG never reaches here - the block rides `FitCells`, so
## the racks stay the weapons' only list there (P34).
func _sync_equipped() -> void:
	if _equipped_rows == null:
		return
	_clear(_equipped_rows)
	_equipped.clear()
	var profile := _profile()
	var fit := _resolved_fit(profile, _active_hull(profile))
	var fitted := 0
	for cell: Dictionary in _cells:
		var entry := _cell_module(fit, StringName(cell[&"type"]), int(cell[&"index"]))
		if entry == &"":
			continue
		fitted += 1
		_equipped.append(_make_equipped_row(cell, profile, entry))
	if _equipped_caption != null:
		_equipped_caption.text = EQUIPPED_CAPTION % [fitted, _cells.size()]
	_apply_equipped_selection()


## One equipped row (the A5.3 inventory row's idiom: the flat Tokens box `item_bg` + the
## 1 px `metal_mid` border at the 6 px content inset, UI_SPEC section 3.10 A5.3/A5.4;
## the family glyph 24 leads in its own rect, A5.4-4). The row's press is the grid cell's
## own selection - one selection, two views - and CELL INFO follows it.
func _make_equipped_row(
	cell: Dictionary, profile: ProfileScript, entry: StringName
) -> Dictionary:
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var base := _base_id(profile, entry)
	var module_row := ModuleData.module(base)
	var row := Button.new()
	row.name = "Equipped%s%02d" % [String(cell[&"token"]), index + 1]
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, EQUIPPED_ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_flat_chrome(row)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", int(EQUIPPED_ROW_INSET))
	inner.add_theme_constant_override(&"margin_top", int(EQUIPPED_ROW_INSET))
	inner.add_theme_constant_override(&"margin_right", int(EQUIPPED_ROW_INSET))
	inner.add_theme_constant_override(&"margin_bottom", int(EQUIPPED_ROW_INSET))
	row.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var icon := _make_icon(String(module_row.get(&"icon", "")), EQUIPPED_ICON)
	if icon != null:
		box.add_child(icon)
	var id_label := _make_label(&"StationValue", _cell_id(cell))
	id_label.name = "CellId"
	id_label.custom_minimum_size = Vector2(EQUIPPED_ID_COLUMN, 0.0)
	id_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(id_label)
	var name_label := _make_label(&"StationValue", _module_name(base), true)
	name_label.name = "ModuleName"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(name_label)
	var stat_text := _effect_line(module_row)
	var stat_label := _make_label(&"StationMeta", stat_text, true)
	stat_label.name = "Stats"
	stat_label.custom_minimum_size = Vector2(EQUIPPED_STAT_COLUMN, 0.0)
	stat_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stat_label.visible = not stat_text.is_empty()
	box.add_child(stat_label)
	var payload := {
		&"cell": {
			&"type": slot_key,
			&"token": String(cell[&"token"]),
			&"index": index,
		},
		&"row": row,
		&"icon": icon,
		&"id": id_label,
		&"name": name_label,
		&"stats": stat_label,
	}
	row.pressed.connect(_on_equipped_pressed.bind(payload))
	row.mouse_entered.connect(_on_equipped_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_equipped_hovered.bind(payload, false))
	_equipped_rows.add_child(row)
	return payload


func _on_equipped_pressed(payload: Dictionary) -> void:
	var cell: Dictionary = payload[&"cell"]
	select_cell(StringName(cell[&"type"]), int(cell[&"index"]))


func _on_equipped_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon := payload.get(&"icon", null) as TextureRect
	if icon == null or not is_instance_valid(icon):
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


## The rows' own view of the one selection: pressed with the cell the grid holds, clear
## otherwise, so a selection made anywhere reads on both views (P49).
func _apply_equipped_selection() -> void:
	for payload: Dictionary in _equipped:
		var row := payload[&"row"] as Button
		if row != null and is_instance_valid(row):
			row.set_pressed_no_signal(_is_selected(payload[&"cell"]))


## The A5.3 inventory row's flat Tokens box on a pressable: the `item_bg` fill and the
## 1 px `metal_mid` border at rest (UI_SPEC section 3.10 A5.3/A5.4, the overview tile's
## own shape, P45); the theme's own state boxes stay above it (P45's states rule).
func _apply_flat_chrome(row: Button) -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = _token(ROLE_ITEM_BG)
	flat.border_color = _token(ROLE_METAL_MID)
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(0)
	row.add_theme_stylebox_override(&"normal", flat)
	for state: StringName in [&"hover", &"pressed", &"disabled", &"focus"]:
		var box := row.get_theme_stylebox(state, &"Button")
		if box != null:
			row.add_theme_stylebox_override(state, box)


## The cell's short id - CELL_INFO_ID's own leading pair (`W3`/`S1`/`E2`).
func _cell_id(cell: Dictionary) -> String:
	return CELL_ID_FORMAT % [String(cell[&"token"]), int(cell[&"index"]) + 1]


## The stat line's own vocabulary: the catalogue's `effects` dict through the stat_line
## idiom (`fitting_panel.gd:1634`'s own rule - the pane may not preload the fitting pane
## whose constants are the pin's single home, so the twins live here, as the refusal
## strings above do). A module with no effects (every weapon) carries no line.
static func _effect_line(module_row: Dictionary) -> String:
	var parts := PackedStringArray()
	var effects: Dictionary = module_row.get(&"effects", {})
	for key: Variant in effects:
		parts.append(_stat_line(StringName(str(key)), float(effects[key])))
	return STAT_JOIN.join(parts)


static func _stat_line(stat_key: StringName, value: float) -> String:
	var key := String(stat_key)
	if key.ends_with("_mult") or key.ends_with("_multiplier"):
		return "%s %s%s" % [_stat_label(stat_key), MULTIPLIER_PREFIX, String.num(value, 2)]
	var text := _signed_percent(value) if absf(value) < 1.0 else _signed_number(value)
	return "%s %s" % [_stat_label(stat_key), text]


static func _stat_label(stat_key: StringName) -> String:
	var words := String(stat_key).to_upper().replace("_", " ")
	for suffix: String in [STAT_ADD_SUFFIX, STAT_MULT_SUFFIX, " MULTIPLIER"]:
		if words.ends_with(suffix):
			return words.substr(0, words.length() - suffix.length())
	return words


static func _signed_percent(value: float) -> String:
	return "%+d %%" % int(roundf(value * 100.0))


static func _signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % int(roundf(value))
	return "%+.2f" % value


## Release one container's children at the end of the frame: the plate whose own
## `_drop_data` (or `pressed`) started the write that triggered this refresh is still on
## the stack, so it may not be freed under it (CONTRACTS section 16 rule 10's hazard,
## cured here by `queue_free` rather than by a fixed node set - a rack's shape is
## player-composed, so it has no fixed shaped to pre-build).
static func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Redraw every rack from the profile: the active hull's composed racks as
## `battery_groups` derives them (`B1..B5`, in `weapon_1..5` order), each rack as a bay -
## `B<n>` and its key hint on the head with the `READY`/`OVER CAP` chip, the four
## slot-chrome cells (the fitted ones named, the empty ones offering `DROP HERE`) and the
## ledge with the rack's own cycle figure (seconds x 100, the slowest member's cycle: 09
## section 11).
func _refresh_racks() -> void:
	_clear(_rack_rows)
	_rack_views.clear()
	var profile := _profile()
	if profile == null:
		_lay_bays()
		return
	var hull := _active_hull(profile)
	var groups: Array = profile.call(&"battery_groups", hull) if hull != &"" else []
	var cells := _weapon_cells(profile)
	for rack in RACK_COUNT:
		var refs: Array = groups[rack] if rack < groups.size() else []
		_rack_views.append(_build_rack(rack, refs, cells))
	_lay()


func _build_rack(rack: int, refs: Array, cells: Array) -> Dictionary:
	var row := RackRow.new()
	row.name = "Rack%d" % (rack + 1)
	row.armory = self
	row.rack = rack
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.clip_contents = false
	## P36: the racks are full-width rows - the container stacks them and gives each one the
	## whole console width (relative sizing, never a hand-placed rect).
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0.0, _style.rack_row_height if _style != null else 56.0)
	row.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var box := PanelContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	row.add_child(box)
	var marks := BayMarks.new()
	marks.name = "BayMarks"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(marks)
	## `Head` and `Barrels` are plain `Control`s: a container would re-stack their children
	## after the pane's own layout pass (the mockup's grid is not a box layout), so the
	## bay's rects are written once per pass and nothing moves them again.
	var head := Control.new()
	head.name = "Head"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var label := _make_caption(RACK_LABEL % (rack + 1), ROLE_BONE)
	label.name = "Label"
	head.add_child(label)
	var key := _make_caption(RACK_KEY % (rack + 1), ROLE_CAPTION)
	key.name = "Key"
	head.add_child(key)
	var chip := ChipPlate.new()
	chip.name = "Chip"
	head.add_child(chip)
	var state := _make_caption(RACK_READY, ROLE_CAPTION)
	state.name = "State"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(state)
	var cell_boxes := Control.new()
	cell_boxes.name = "Cells"
	cell_boxes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cell_boxes)
	var barrels := Control.new()
	barrels.name = "Barrels"
	barrels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(barrels)
	var strip := SalvoStrip.new()
	strip.name = "Salvo"
	box.add_child(strip)
	var views: Array[Dictionary] = []
	for index in refs.size():
		views.append(_build_barrel(rack, index, int(refs[index]), cells, barrels))
	## The empty cells fill the grid slots the fitted ones leave, in order.
	for slot in range(refs.size(), 4):
		_build_drop_cell(rack, slot, cell_boxes)
	var cycle := _rack_cycle(refs, cells)
	var state_text: String = RACK_STATE_AT_CAP if _rack_cells_count(refs) >= WeaponComponent.BATTERY_CELLS_MAX else RACK_READY
	state.text = state_text
	chip.configure(_style, state_text == RACK_STATE_AT_CAP, state_text == RACK_STATE_AT_CAP)
	state.add_theme_color_override(
		&"font_color",
		_token(ROLE_DANGER_BRIGHT if state_text == RACK_STATE_AT_CAP else ROLE_CAPTION)
	)
	var salvo_line: String = RACK_SALVO % cycle if cycle > 0.0 else RACK_READY
	## S30 census row 7: the salvo line rides the N27 tooltip now (no `tooltip_text`).
	row.mouse_entered.connect(_on_rack_inspected.bind(salvo_line, true))
	row.mouse_exited.connect(_on_rack_inspected.bind(salvo_line, false))
	_rack_rows.add_child(row)
	## The bay box (a `PanelContainer`) sizes its children to itself on every sort, and the
	## ledge follows its own resize: both re-enter the bay layout, so the strip, the head
	## and the cells end every pass where the style put them (the old pane's own lesson).
	if not box.sort_children.is_connected(_position_bay.bind(row)):
		box.sort_children.connect(_position_bay.bind(row))
	if not strip.resized.is_connected(_position_bay.bind(row)):
		strip.resized.connect(_position_bay.bind(row))
	_position_head(head)
	_position_cells(barrels)
	_position_bay(row)
	var view := {
		&"rack": rack,
		&"row": row,
		&"label": label.text,
		&"state": state,
		&"chip": chip,
		&"cells_node": cell_boxes,
		&"salvo": salvo_line,
		&"barrels": views,
		&"cells": _rack_cell_list(refs),
		&"marks": marks,
		&"strip": strip,
		&"figure": _salvo_figure(cycle),
	}
	_style_bay(view)
	return view


## The number of cells one rack's own record holds (09 section 12's hardcap read).
static func _rack_cells_count(refs: Array) -> int:
	return refs.size()


## One barrel chip: the drag source (the name plate), the visible name block on two 13 px
## lines (T3) and the `x` that returns the barrel to the inventory. Both bind the
## barrel's **address** (rack, slot) as the rack stands now, because the whole rack is
## redrawn by the next profile change.
func _build_barrel(
	rack: int, slot: int, cell: int, cells: Array, parent: Control
) -> Dictionary:
	var chip := BarrelCell.new()
	chip.name = "Barrel%d" % (slot + 1)
	chip.armory = self
	chip.rack = rack
	chip.slot = slot
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.clip_contents = true
	var entry := StringName(String(cells[cell])) if cell >= 0 and cell < cells.size() else &""
	var full_name := BARREL_TEXT % [cell + 1, _module_name(_base_id(_profile(), entry))]
	var name_button := BarrelName.new()
	name_button.name = "Name"
	name_button.armory = self
	name_button.rack = rack
	name_button.slot = slot
	name_button.theme_type_variation = &"StationButton"
	name_button.focus_mode = Control.FOCUS_ALL
	name_button.text = full_name
	name_button.custom_minimum_size = Vector2.ZERO
	name_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"
	]:
		name_button.add_theme_color_override(state, Color(0, 0, 0, 0))
	chip.add_child(name_button)
	## The two name lines live **inside the name plate**: a Button does not aggregate its
	## children's minimum sizes, so the visible name cannot grow the chip's own minimum and
	## push the bay past its drawn width (a Container would).
	var parts := _split_name(full_name)
	var name_label := _make_caption(parts[0], ROLE_BONE)
	name_label.name = "NamePlate"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_button.add_child(name_label)
	var variant_label := _make_caption(parts[1], ROLE_CAPTION)
	variant_label.name = "Variant"
	variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_button.add_child(variant_label)
	var close := Button.new()
	close.name = "Close"
	## A4.2: the `X` is a pressable chip and wears the `StationButton` plate (it was flat
	## under the bespoke language); its 24 px box keeps the S10 hit target.
	close.theme_type_variation = &"StationButton"
	close.focus_mode = Control.FOCUS_ALL
	close.text = BARREL_CLOSE
	close.clip_text = true
	close.custom_minimum_size = Vector2.ZERO
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.add_theme_color_override(&"font_color", _token(ROLE_CAPTION))
	close.pressed.connect(_on_remove_barrel.bind(rack, slot))
	chip.add_child(close)
	parent.add_child(chip)
	if not chip.sort_children.is_connected(_position_cell_children.bind(chip)):
		chip.sort_children.connect(_position_cell_children.bind(chip))
	_position_cell_children(chip)
	name_button.focus_entered.connect(_on_barrel_focused.bind(rack, cell, entry))
	chip.mouse_entered.connect(_on_barrel_inspected.bind(rack, cell, entry, true))
	chip.mouse_exited.connect(_on_barrel_inspected.bind(rack, cell, entry, false))
	return {&"cell": cell, &"name": name_button, &"close": close, &"text": full_name}


## The full barrel name on two 13 px lines: everything before the name's last word on the
## first line, that word (the variant) on the second - so the widest catalogue names
## (`MINE LAYER MKI`) stay inside a 117 px cell at 13 px. A single-word name reads on one
## line and the second label stays empty.
static func _split_name(full_name: String) -> Array[String]:
	var cut := full_name.rfind(" ")
	if cut <= 0:
		return [full_name, ""]
	return [full_name.substr(0, cut), full_name.substr(cut + 1)]


## One empty cell: the bare drop zone (the body-drop route). A7 - the `DROP HERE` ghost
## cue is gone; the empty cell reads as a dim recess with no text (D17-P1's own fix:
## "dim outline slots with no text"). `slot` is the grid position it fills, not a W-cell
## index.
func _build_drop_cell(rack: int, slot: int, parent: Control) -> void:
	var pad := DropCell.new()
	pad.name = "Cell%d" % (slot + 1)
	pad.armory = self
	pad.rack = rack
	pad.slot = slot
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(pad)


## Focus on a barrel makes its rack the selected bay (the section 3.2 ember frame) and
## publishes the barrel's own line to the inspector.
func _on_barrel_focused(rack: int, cell: int, entry: StringName) -> void:
	set_selected_rack(rack)
	_inspect_barrel(rack, cell, entry, true)


func _on_barrel_inspected(rack: int, cell: int, entry: StringName, hovered: bool) -> void:
	_inspect_barrel(rack, cell, entry, hovered)


## CONTRACTS section 23.1 plus P4: a fitted barrel's inspector line. The title reuses the
## chip's own `BARREL_TEXT` line (never a second format string) and the body carries two
## lines - the cell module's catalogue description, then its salvo/dps facts.
func _inspect_barrel(rack: int, cell: int, entry: StringName, shown: bool) -> void:
	if not shown or entry == &"":
		inspect_requested.emit("", "", false)
		return
	var base := _base_id(_profile(), entry)
	var title := BARREL_TEXT % [cell + 1, _module_name(base)]
	inspect_requested.emit(title, _barrel_body(base, rack, cell), false)


## The barrel's two-line inspector body: the catalogue description then the facts line
## (P4/MED-3). Both derive from the catalogue and the component's own tables.
func _barrel_body(base: StringName, rack: int, cell: int) -> String:
	var family := WeaponComponent.weapon_id(base)
	var cycle := WeaponComponent.interval_of(family)
	var salvo: String = STATS_INSTANT if cycle <= 0.0 else "%.2f s" % cycle
	var stats := INSPECT_STATS % [salvo, WeaponComponent.dps_of(family), RACK_LABEL % (rack + 1), cell + 1]
	var described := Catalog.describe(base)
	if described.is_empty():
		return stats
	return described + "\n" + stats


## One bay's own marks and its SALVO strip: the fitted cells (T7: the name marks a fitted
## cell), the ember frame when the bay is selected, and the cycle figure.
func _style_bay(view: Dictionary) -> void:
	var marks: BayMarks = view.get(&"marks", null)
	if marks != null:
		var filled: Array[int] = []
		for ref: Variant in view[&"cells"]:
			filled.append(int(ref))
		marks.configure(_style, filled, int(view[&"rack"]) == _selected_rack)
	var strip: SalvoStrip = view.get(&"strip", null)
	_position_bay(view[&"row"] as Control)
	if strip != null and view.has(&"figure"):
		strip.set_figure(int(view[&"figure"]))


## One rack's cells, as the pane's own read-back hands them out: the W-cell layout
## indices the rack holds, in its own order.
static func _rack_cell_list(refs: Array) -> Array:
	var cells: Array = []
	for ref: Variant in refs:
		cells.append(int(ref))
	return cells


## One rack's salvo gate, the same arithmetic the component fires on (`max` of its
## members' cadences, `WeaponComponent.interval_of`): the rack's slowest member. 0.0 for
## a rack with no travelling member, which reads READY.
##
## A cell holds whatever the fit stores - a base id for a delivered fit, a **rolled
## instance** (`mod_0002`) for a bought or dropped one - so the cell resolves to its
## catalogue base id first. `weapon_id` only strips a `w_` prefix and answers `""` for an
## instance (measured: `weapon_id("mod_0002")` is `""`), which left every instance-keyed
## rack's SALVO drum blank. A base-keyed cell resolves to itself.
func _rack_cycle(refs: Array, cells: Array) -> float:
	var cycle := 0.0
	var profile := _profile()
	for ref: Variant in refs:
		var cell := int(ref)
		if cell < 0 or cell >= cells.size():
			continue
		var base := _base_id(profile, StringName(String(cells[cell])))
		var family := WeaponComponent.weapon_id(base)
		if family == &"":
			continue
		cycle = maxf(cycle, WeaponComponent.interval_of(family))
	return cycle


## The approved figure (Mockup A: `073` = 0.73 s): the cycle in **hundredths** of a
## second, four cells, zero-padded. 0 s has no figure and reads blanks.
func _salvo_figure(cycle: float) -> int:
	if cycle <= 0.0:
		return -1
	return clampi(int(round(cycle * 100.0)), 0, SALVO_MAX)


## The owned candidates for the selected cell (P38's `OWNED` rows): the module's catalogue
## slot matches the cell's family and `fit_legal` accepts the candidate (the same
## `_cell_refusal` the fit flow judges with). `[]` with no cell selected. Public so a probe
## reads the same list the pane draws.
func fits_here_rows() -> Array[Dictionary]:
	return _fits_here_rows()


func _fits_here_rows() -> Array[Dictionary]:
	if _selected.is_empty():
		return []
	var profile := _profile()
	if profile == null:
		return []
	var hull := _active_hull(profile)
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	var rows: Array[Dictionary] = []
	for key: Variant in ModuleData.MODULES:
		var base_id := StringName(str(key))
		if _slot_key_of(base_id) != slot_key:
			continue
		var owned := _owned_total(profile, base_id)
		if owned <= 0:
			continue
		if not _cell_refusal(profile, hull, index, base_id).is_empty():
			continue
		rows.append({
			&"base": base_id,
			&"name": _module_name(base_id),
			&"owned": owned,
			&"draw": int(ModuleData.module(base_id).get(&"draw", 0)),
		})
	return rows


## The list caption (P38/P39a): the cell's own id and candidate count when a FIT CELLS cell
## is selected, the owned count otherwise (BATTERY CONFIG never shows the cell caption).
func _list_caption(count: int) -> String:
	if _mode != MODE_FIT or _selected.is_empty():
		return LIST_CAPTION_BROWSE % count
	return LIST_CAPTION_CELL % [
		String(_selected[&"token"]), int(_selected[&"index"]) + 1, count
	]


func _list_empty_text() -> String:
	return LIST_EMPTY_CELL if _mode == MODE_FIT and not _selected.is_empty() else LIST_EMPTY_BROWSE


## Select-to-fit (P38): an `OWNED` row's press fits the held instance into the selected cell
## (the same composed flow the buyable row uses). With no cell selected the press is inert -
## the browse state is a browse surface, not a fit flow.
func _on_equip_pressed(base_id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if _mode != MODE_FIT or _selected.is_empty():
		return
	_flow_row_into_cell({&"base": base_id, &"owned": true, &"price": 0})


## S32's own row-press door, kept as the one alias the older suites drive.
func _on_fits_here_pressed(base_id: StringName) -> void:
	_on_equip_pressed(base_id)


func _inspect_module(base_id: StringName, name_text: String, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(name_text, Catalog.describe(base_id), false)


## The owned weapon rows, in catalogue order: every `weapons` module of the catalogue
## the bag holds at least one instance of (`instances_of`, S4's own pairing count). The
## module table is the catalogue's own order, so no second list exists.
func inventory_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var profile := _profile()
	if profile == null:
		return rows
	for key: Variant in ModuleData.MODULES:
		var base_id := StringName(str(key))
		if ModuleData.fit_slot_of(base_id) != WEAPON_SLOT:
			continue
		var owned := (profile.call(&"instances_of", base_id) as Array).size()
		if owned <= 0:
			continue
		rows.append({
			&"base": base_id,
			&"name": _module_name(base_id),
			&"owned": owned,
			&"draw": int(ModuleData.module(base_id).get(&"draw", 0)),
		})
	return rows


## Every drawn rack as `{rack, label, state, salvo, barrels, cells, figure}` - `barrels`
## is one `{cell, name, close, text}` per fitted cell and `cells` the rack's W-cell
## indices in its own order. Probes and suites read the racks through this rather than
## walking the tree.
func rack_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for view: Dictionary in _rack_views:
		var barrels: Array = []
		for barrel: Dictionary in view[&"barrels"]:
			barrels.append({
				&"cell": int(barrel[&"cell"]),
				&"text": String(barrel[&"text"]),
			})
		rows.append({
			&"rack": int(view[&"rack"]),
			&"label": String(view[&"label"]),
			&"state": (view[&"state"] as Label).text,
			&"salvo": String(view[&"salvo"]),
			&"cells": view[&"cells"],
			&"barrels": barrels,
			&"figure": int(view[&"figure"]),
		})
	return rows


## One bay's SALVO readout as the pane drew it: the strip's four cells (`-1` = blank) and
## the figure it was handed (-1 for a rack with no travelling member).
func salvo_readout(rack: int) -> Dictionary:
	if rack < 0 or rack >= _rack_views.size():
		return {&"figure": -1, &"cells": []}
	var strip: SalvoStrip = _rack_views[rack][&"strip"]
	return {
		&"figure": int(_rack_views[rack][&"figure"]),
		&"cells": strip.cells() if strip != null else [],
		&"text": strip.figure_text() if strip != null else "",
	}


## One bay's code-drawn marks (the fitted cells and the selected frame).
func bay_marks(rack: int) -> BayMarks:
	if rack < 0 or rack >= _rack_views.size():
		return null
	return _rack_views[rack][&"marks"]


## Every rack row's rect as drawn (P36: the full-width rows stacked top-down), in the
## pane's own space. The rows follow the console, which follows the mode host.
func bay_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for view: Dictionary in _rack_views:
		var row := view.get(&"row") as Control
		if row != null:
			out.append(_pane_rect(row))
	return out


## The wells band's two halves as drawn (the read-only empty-cell list left, the mode's own
## summary right), in the pane's own space.
func well_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for margin: Control in [_empty_margin, _summary_margin]:
		if margin != null:
			out.append(_pane_rect(margin))
	return out


## The console's own size as drawn (P36: the console stretches to the mode host, so this is
## the host's own body box rather than the retired 1360x516 base).
func block_size() -> Vector2:
	return _console.size


## The inventory rows as drawn, in order, `{base, name, owned, draw, text}` - the browse
## state's own read-back: the owned weapons with their `OWNED ×<n>` figure.
func inventory_view_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in inventory_rows():
		rows.append({
			&"base": entry[&"base"],
			&"name": entry[&"name"],
			&"owned": int(entry[&"owned"]),
			&"draw": int(entry[&"draw"]),
			&"text": INVENTORY_TEXT % ["OWNED", int(entry[&"owned"])],
		})
	return rows


## ------------------------------------------------------------- the drag interface


## The payload an inventory row drags: its base id. `{}` (a drag the engine cancels, and
## a `null` return from `_get_drag_data`) for a base the bag holds none of.
func drag_inventory(base_id: StringName) -> Dictionary:
	var profile := _profile()
	if profile == null or base_id == &"":
		return {}
	if (profile.call(&"instances_of", base_id) as Array).is_empty():
		return {}
	return {DRAG_KEY_KIND: DRAG_INVENTORY, DRAG_KEY_BASE: base_id}


## The payload a barrel chip drags: its address in the racks.
func drag_barrel(rack: int, slot: int) -> Dictionary:
	if rack < 0 or rack >= _rack_views.size():
		return {}
	var refs: Array = _rack_views[rack][&"cells"]
	if slot < 0 or slot >= refs.size():
		return {}
	return {DRAG_KEY_KIND: DRAG_BARREL, DRAG_KEY_RACK: rack, DRAG_KEY_POSITION: slot}


## Whether one drop would be accepted, without writing anything: the pure half of
## `drop`, which is what `_can_drop_data` answers the engine with. `position` is
## `DROP_RACK_BODY` for a drop on the rack itself and a barrel's index for a drop on that
## barrel.
func can_drop(rack: int, slot: int, payload: Variant) -> bool:
	var data := _payload_of(payload)
	if data.is_empty():
		return false
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	if String(data[DRAG_KEY_KIND]) == String(DRAG_INVENTORY):
		## An inventory weapon installs into the rack's next free W cell: a drop on a
		## barrel has no meaning (a swap needs a barrel of the same kind to seat, and the
		## install route is the rack's own body).
		if slot != DROP_RACK_BODY:
			return false
		return _can_install(profile, hull, rack, StringName(data[DRAG_KEY_BASE]))
	if String(data[DRAG_KEY_KIND]) == String(DRAG_BARREL):
		var from_rack := int(data[DRAG_KEY_RACK])
		var from_position := int(data[DRAG_KEY_POSITION])
		## A drop on the rack's own body appends to the **target** rack (the same point
		## `drop` uses), so the preview and the write cannot disagree about the address.
		var to_slot := slot if slot != DROP_RACK_BODY else _rack_end(rack)
		return _can_move(hull, from_rack, from_position, rack, to_slot)
	return false


## Perform one drop: the writing half of the drag interface, exactly the action
## `can_drop` previewed. `false` (with the footer's refusal) when the drop is refused -
## and a refused drop writes nothing at all, fit, bag and rack record alike.
func drop(rack: int, slot: int, payload: Variant) -> bool:
	var data := _payload_of(payload)
	if data.is_empty():
		return false
	if String(data[DRAG_KEY_KIND]) == String(DRAG_INVENTORY):
		return install_weapon(rack, StringName(data[DRAG_KEY_BASE]))
	if String(data[DRAG_KEY_KIND]) == String(DRAG_BARREL):
		var from_rack := int(data[DRAG_KEY_RACK])
		var from_position := int(data[DRAG_KEY_POSITION])
		var to_slot := slot if slot != DROP_RACK_BODY else _rack_end(rack)
		return move_barrel(from_rack, from_position, rack, to_slot)
	return _refuse(REFUSAL_FIT_ILLEGAL)


## The payload dictionary of a drop, `{}` for anything that is not one of the two the
## pane hands out (the engine hands back whatever `_get_drag_data` returned, so this is
## the one place a malformed payload is rejected).
static func _payload_of(payload: Variant) -> Dictionary:
	if not payload is Dictionary:
		return {}
	var data: Dictionary = payload
	if not data.has(DRAG_KEY_KIND):
		return {}
	return data


## The last barrel position of one rack's chip list, the insert point of a drop on the
## rack's own body: the rack's own order, so a between-rack drag appends there and a
## within-rack drag lands past its last barrel (a no-op the profile's guards refuse,
## which is the honest reading - the rack's body is not a barrel to swap with).
func _rack_end(rack: int) -> int:
	if rack < 0 or rack >= _rack_views.size():
		return 0
	return (_rack_views[rack][&"cells"] as Array).size()


## One rack's own cell count, read from the profile's derived racks (the same list the
## pane draws), so the pane's preview and the profile's transaction measure the same
## thing. 0 for a rack the hull's record does not reach.
func _rack_cells_of(profile: ProfileScript, hull: StringName, rack: int) -> int:
	if profile == null or hull == &"" or rack < 0:
		return 0
	var groups: Array = profile.call(&"battery_groups", hull)
	if rack >= groups.size():
		return 0
	return (groups[rack] as Array).size()


## ------------------------------------------------------------------ the rack actions


## Install one inventory weapon into one rack's next free W cell (09 section 11): the
## profile's composed `fit_into_rack`, which pairs the next in-bag instance of the base
## into the cell and records the cell in the rack, atomically over the fit, the bag and
## the record. Refused, writing nothing, when the rack is outside `B1..B5`, the bag holds
## none of the base, every W cell is taken, or the candidate fit is illegal - the
## mandatory set and `fit_legal` are checked **before** the first write, here by the
## preview and again inside the transaction (CONTRACTS section 13 rule 6).
func install_weapon(rack: int, base_id: StringName) -> bool:
	var profile := _profile()
	if profile == null or base_id == &"":
		return false
	var hull := _active_hull(profile)
	var refusal := _install_refusal(profile, hull, rack, base_id)
	if not refusal.is_empty():
		return _refuse(refusal)
	var index := int(profile.call(&"free_weapon_cell", hull))
	## The seed materialises the fit the launch flies, so the transaction's own candidate
	## is the fit this pane drew; a refusal drops it again (`_seed_fit`'s own rule).
	var seeded := _seed_fit(profile, hull)
	if not bool(profile.call(&"fit_into_rack", hull, rack, index, base_id)):
		_unseed_fit(profile, hull, seeded)
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_INSTALLED % [_module_name(base_id), RACK_LABEL % (rack + 1)], false
	)
	return true


## Move one barrel within or between racks (09 section 11: "re-orders and swaps"). Pure
## record surgery in the profile (`move_rack_cell`): the cell keeps its barrel and gains a
## different trigger, so no fit and no bag write happens. Refused, writing nothing, for an
## address that holds no barrel, a target rack outside `B1..B5`, or the same address.
func move_barrel(
	from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	if not _can_move(hull, from_rack, from_position, to_rack, to_position):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	var name_text := _rack_barrel_name(profile, from_rack, from_position)
	if not bool(
		profile.call(&"move_rack_cell", hull, from_rack, from_position, to_rack, to_position)
	):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	status_requested.emit(STATUS_MOVED % [name_text, RACK_LABEL % (to_rack + 1)], false)
	return true


## The `x` (or the right-click): the barrel returns to the inventory and its cell is
## emptied
## (`clear_rack_cell`, the composed remove plus the record update). Refused, writing
## nothing, for an address that holds no barrel or a cell the mandatory set protects
## (unreachable for a W cell, measured: `FitData.MANDATORY_SLOT_KEYS` is
## `[engines, power]`).
func remove_barrel(rack: int, slot: int) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	var index := _rack_cell_at(rack, slot)
	if index < 0:
		return _refuse(REFUSAL_FIT_ILLEGAL)
	var name_text := _rack_barrel_name(profile, rack, slot)
	var seeded := _seed_fit(profile, hull)
	if not bool(profile.call(&"clear_rack_cell", hull, index)):
		_unseed_fit(profile, hull, seeded)
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_REMOVED % name_text, false)
	return true


func _on_remove_barrel(rack: int, slot: int) -> void:
	remove_barrel(rack, slot)


## One barrel chip's address -> its W-cell layout index, -1 for an address the drawn
## racks do not hold.
func _rack_cell_at(rack: int, slot: int) -> int:
	if rack < 0 or rack >= _rack_views.size():
		return -1
	var cells: Array = _rack_views[rack][&"cells"]
	if slot < 0 or slot >= cells.size():
		return -1
	return int(cells[slot])


## One barrel's display name, read from the address: the fits' own base name, `""` for an
## address that holds nothing.
func _rack_barrel_name(profile: ProfileScript, rack: int, slot: int) -> String:
	var index := _rack_cell_at(rack, slot)
	if index < 0:
		return ""
	return _module_name(_base_id(profile, StringName(String(_weapon_cells(profile)[index]))))


## The install's preview, without a write: `""` when the install would be accepted, else
## the pin's own refusal wording. Every guard the transaction makes is made here too, so
## the pane and the profile cannot disagree about a drop (CONTRACTS section 13 rule 6).
func _install_refusal(
	profile: ProfileScript, hull: StringName, rack: int, base_id: StringName
) -> String:
	if rack < 0 or rack >= RACK_COUNT:
		return REFUSAL_FIT_ILLEGAL
	if not _is_weapon_base(base_id):
		return REFUSAL_FIT_ILLEGAL
	## 09 section 12's hardcap: a battery holds `BATTERY_CELLS_MAX` cells, so a drop
	## onto a full rack is refused before the hull's own free cell is read (the profile's
	## `fit_into_rack` refuses it again inside the transaction).
	if _rack_cells_of(profile, hull, rack) >= WeaponComponent.BATTERY_CELLS_MAX:
		return REFUSAL_W_SLOTS_FULL
	if (profile.call(&"instances_of", base_id) as Array).is_empty():
		return REFUSAL_NO_WEAPONS
	var index := int(profile.call(&"free_weapon_cell", hull))
	if index < 0:
		return REFUSAL_W_SLOTS_FULL
	return _cell_refusal(profile, hull, index, base_id)


## Whether one install would be accepted: the boolean half of `_install_refusal`, which is
## what `can_drop` answers with.
func _can_install(
	profile: ProfileScript, hull: StringName, rack: int, base_id: StringName
) -> bool:
	return _install_refusal(profile, hull, rack, base_id).is_empty()


## Whether one barrel move would be accepted: the source must hold a barrel, the target
## rack must be inside `B1..B5`, the target slot must not be negative and the two
## addresses must differ. 09 section 12's four-cell cap refuses the move that would
## **grow** the target past it -- an append past its last barrel; a move onto an occupied
## position is the swap and leaves the target's length alone, so a swap into a four-cell
## battery stays legal. Pure reads - a move writes no fit, so there is nothing else to
## judge.
func _can_move(
	hull: StringName, from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	if hull == &"" or to_rack < 0 or to_rack >= RACK_COUNT or to_position < 0:
		return false
	if from_rack == to_rack and from_position == to_position:
		return false
	if _rack_cell_at(from_rack, from_position) < 0:
		return false
	if from_rack != to_rack:
		var target_cells := _rack_cells_of(_profile(), hull, to_rack)
		if to_position >= target_cells:
			return target_cells < WeaponComponent.BATTERY_CELLS_MAX
	return true


## The candidate's own legality, judged with the same `ShipFit.fit_legal` the profile
## re-checks on commit: the pin's overload line from `fit_legal`'s power block, or the
## catch-all. `""` when the candidate is legal.
func _cell_refusal(
	profile: ProfileScript, hull: StringName, index: int, entry: StringName
) -> String:
	var candidate := _with_cell(_resolved_fit(profile, hull), WEAPON_SLOT, index, entry)
	var legal := ShipFit.fit_legal(hull, _base_fit(profile, candidate))
	if bool(legal[&"legal"]):
		return ""
	return _fit_refusal(legal)


## The third pinned refusal's own test, byte-equivalent to the FITTING pane's: a fit
## illegal for a reason that is not the power budget has no finer wording than the
## catch-all (CONTRACTS section 16 rule 9).
func _fit_refusal(legal: Dictionary) -> String:
	var power: Dictionary = legal.get(&"power", {})
	if not bool(power.get(&"legal", true)):
		var draws := int(power.get(&"draw", 0))
		var out := int(power.get(&"out", 0))
		return REFUSAL_OVERLOAD % [draws, out, draws - out]
	return REFUSAL_FIT_ILLEGAL


## A refusal: the denied cue and the wording in this pane's footer - `status_requested`,
## never a dialog (STATION_HUB section 5.1).
func _refuse(message: String) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(message, true)
	return false


## ------------------------------------------------------------------- the fit reads


## A fit with every cell exchanged for the base catalogue id behind it, through the
## profile's own `base_fit` (CONTRACTS section 15): the shape `ShipFit` reads. Every
## legality judgement in this pane goes through it, because a fit cell holds an instance
## id.
func _base_fit(profile: ProfileScript, fit: Dictionary) -> Dictionary:
	if profile == null:
		return fit
	var translated: Variant = profile.call(&"base_fit", fit)
	return translated if translated is Dictionary else fit


## `fit` with one cell set, in `fit_for`'s own shape: the same composition the profile's
## own `_with_cell` makes, so a preview and its commit judge one candidate (CONTRACTS
## section 13).
static func _with_cell(
	fit: Dictionary, slot_key: StringName, index: int, module_id: StringName
) -> Dictionary:
	var out: Dictionary = fit.duplicate(true)
	if slot_key == POWER_SLOT:
		out[slot_key] = String(module_id)
		return out
	var cells: Array = out.get(slot_key, out.get(String(slot_key), []))
	while cells.size() <= index:
		cells.append("")
	cells[index] = String(module_id)
	out[slot_key] = cells
	return out


## The fit the panel shows and writes against: the account's own when it holds one, else
## 09 section 9's `ShipFit.standard_fit` - the same resolution `game.gd:_launch_fit_for`
## launches with, so a rack cannot promise a cell the launch would not fly.
func _resolved_fit(profile: ProfileScript, hull: StringName) -> Dictionary:
	if profile != null and hull != &"":
		var stored: Dictionary = profile.call(&"fit_for", hull)
		if _holds_a_module(stored):
			return stored
	return ShipFit.standard_fit(hull)


## Materialise the fit the launch already flies, for the transactions that need one
## written: the composed calls read the module they hand back out of the hull's *stored*
## fit, so a hull the account holds no fit for would refuse to empty the very cells this
## pane draws. The seed writes the same fit the resolution above reads, so the two agree;
## nothing else in the panel writes a whole fit.
##
## **Answers whether it wrote**, because a seed a refusal made pointless must be dropped
## again (`_unseed_fit`): a refused action has to leave the store exactly as it found it
## (CONTRACTS section 16 rules 7-8).
func _seed_fit(profile: ProfileScript, hull: StringName) -> bool:
	var stored: Dictionary = profile.call(&"fit_for", hull)
	if _holds_a_module(stored):
		return false
	var standard := ShipFit.standard_fit(hull)
	if standard.is_empty():
		return false
	profile.call(&"set_fit", hull, standard)
	return true


## Undo a seed whose transaction refused, so the hull is back to holding no stored fit
## and `fits()` reads exactly what it read before the action was taken.
static func _unseed_fit(profile: ProfileScript, hull: StringName, seeded: bool) -> void:
	if seeded:
		profile.call(&"clear_fit", hull)


## Whether a fit holds any module at all: the launch's own test, so an all-empty stored fit
## falls back to the standard fit on both sides.
static func _holds_a_module(fit: Dictionary) -> bool:
	for key: StringName in ShipFit.FIT_SLOT_KEYS:
		var raw: Variant = fit.get(key, fit.get(String(key), null))
		if raw is Array:
			for entry: Variant in raw as Array:
				if String(entry) != "":
					return true
		elif raw is String or raw is StringName:
			if String(raw) != "":
				return true
	return false


## The active hull's W cells, one entry per cell in 09 section 4 item 5's layout order.
## `ShipFit.grid_cells` names every W cell and its layout index and the fit the launch
## resolves supplies the module at that index (`""` for an empty cell, and `""` for a cell
## past the end of a short standard fit), so the list is exactly as long as the hull has W
## cells and an index in it is a cell. Instance ids are handed back as they are stored; the
## callers resolve them through `base_module_id`.
func _weapon_cells(profile: ProfileScript) -> Array:
	var hull := _active_hull(profile)
	var cells: Array = []
	var fitted: Array = []
	if profile != null and hull != &"":
		var raw: Variant = _resolved_fit(profile, hull).get(WEAPON_SLOT, [])
		if raw is Array:
			fitted = raw
	for cell: Dictionary in ShipFit.grid_cells(hull):
		if bool(cell[&"gap"]) or cell[&"type"] != WEAPON_SLOT:
			continue
		var index := int(cell[&"index"])
		cells.append(String(fitted[index]) if index >= 0 and index < fitted.size() else "")
	return cells


## Whether a base id is a weapon module (the rack record's own domain): the drag and the
## install both refuse anything else, so a utility module can never enter a rack.
static func _is_weapon_base(base_id: StringName) -> bool:
	return ModuleData.fit_slot_of(base_id) == WEAPON_SLOT


func _active_hull(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


func _module_name(module_id: StringName) -> String:
	var name_text := String(ModuleData.module(module_id).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(module_id).to_upper()


## ------------------------------------------------------------------- the refresh


func _refresh_all() -> void:
	_refresh_rows()
	_refresh_racks()
	_refresh_empty_cells()
	_sync_grid(_active_hull(_profile()))
	_refresh_browser()
	_refresh_footer()
	_refresh_cell_info()
	_sync_equipped()
	_refresh_cargo_preview()


## A21: the left column's cargo window — the C overlay's own window (the A15
## chrome, the tab strip, the uncapped scroll) expand-filling the HOLD page's
## space under the equipped block, so the rows can never run past the panel
## onto the footer again.
func _build_cargo_preview() -> void:
	if _page_hold == null:
		return
	_cargo_window = Summary.build_window(
		_page_hold, "CargoWindow", Callable(self, "_on_cargo_tab")
	)


func _on_cargo_tab(id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_cargo_category = id
	_refresh_cargo_preview()


## A21.3's page switch: one page at a time, the states riding the shared
## builder's own tab-state idiom.
func _build_left_tabs() -> void:
	_tab_layout.set_meta(&"tab", LEFT_TAB_LAYOUT)
	_tab_hold.set_meta(&"tab", LEFT_TAB_HOLD)
	_tab_layout.pressed.connect(_on_left_tab.bind(LEFT_TAB_LAYOUT))
	_tab_hold.pressed.connect(_on_left_tab.bind(LEFT_TAB_HOLD))
	_apply_left_tab()


func _on_left_tab(id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_left_tab = id
	_apply_left_tab()


func _apply_left_tab() -> void:
	_page_layout.visible = _left_tab == LEFT_TAB_LAYOUT
	_page_hold.visible = _left_tab == LEFT_TAB_HOLD
	Summary.apply_tab_states(_left_tabs, _left_tab, self)


func _refresh_cargo_preview() -> void:
	if _cargo_window.is_empty() or not is_node_ready():
		return
	Summary.populate_window(_cargo_window, _profile(), self, _cargo_category)


func _profile() -> ProfileScript:
	## Autoloads are children of /root; STATION_HUB section 12.4 names a bare
	## ^"PlayerProfile" path, which would resolve against this node instead, so the
	## lookup is anchored at the tree root the way router.gd anchors its services.
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		return null
	var profile: ProfileScript = service
	return profile


## The docked station's own row (14's 2026-10-08 block), empty when no place is filed.
func _docked_station() -> Dictionary:
	return StationRegistryScript.docked_station(_profile())


## The station faction's standing (12 section 4's -100..+100), the band the price factor
## reads. 0 - Neutral, the band's own baseline - when there is no place, no profile or no
## standing accessor.
func _station_standing() -> int:
	var station := _docked_station()
	if station.is_empty():
		return 0
	var profile := _profile()
	if profile == null or not profile.has_method(&"standing_of"):
		return 0
	return int(profile.call(&"standing_of", StringName(station.get(&"faction", &""))))


## V1+V2 (12's 2026-10-08 block): one module's list price at this station - the catalogue's
## own `cost` through the registry's one factor, so the band and the station faction's -15 %
## tech step (added to the band, never multiplied) are live on the row, the `BUY & FIT`
## chip and the charge alike: `_buy` hands this same figure to `PlayerProfile.buy_module`.
func _module_price(base_id: StringName) -> int:
	return StationRegistryScript.apply_price(
		int(ModuleData.module(base_id).get(&"cost", 0)),
		_docked_station(),
		_station_standing(),
		base_id,
	)


func _pulse(node: CanvasItem) -> void:
	if node == null:
		return
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped


## ================================================== the merged grid (P4's left half)
##
## STATION_HUB section 17.1: "Left: the ship grid exactly as FITTING ships it" - 48 px
## `SlotButtonWeapon` plates, gaps as empty Controls, the glyph inset 6, separations 4,
## the `SLOT LAYOUT` caption and the footer power meter on FITTING's own numbers
## (`fitting_panel.gd:18-70,148-149`). The cells stay selectable and drop-accepting;
## the fit arithmetic below ports `fitting_panel.gd`'s own (the composed calls are the
## profile's, CONTRACTS section 13).


func _build_grid_surface() -> void:
	_grid.add_theme_constant_override(&"h_separation", PLATE_SEPARATION)
	_grid.add_theme_constant_override(&"v_separation", PLATE_SEPARATION)


func _wire_actions() -> void:
	_remove_button.text = ACTION_REMOVE
	_remove_button.pressed.connect(_on_remove_pressed)
	_buy_fit_button.pressed.connect(_on_buy_fit_pressed)


## ------------------------------------------------- the INSPECT sheet (N28/N37, S30)
## N37 rev (owner 2026-10-07): the station's one INSPECT toggle. On, an item press (rack
## card, browser row, grid cell) opens the sheet instead of its normal action, and the
## per-row / per-cluster INSPECT chips are retired.
var _inspect_mode := false


func set_inspect_mode(on: bool) -> void:
	_inspect_mode = on


## N34's route: inspect the focused row, or the focused/selected grid cell.
func _emit_sheet(payload: Dictionary) -> void:
	var sheet := _sheet_payload(payload)
	if not sheet.is_empty():
		sheet_requested.emit(sheet)


## N34's route: inspect the focused row, or the focused/selected grid cell through the
## cluster chip (N37).
func inspect_focused() -> void:
	## N34: the selected grid cell first (its own module), then the focused row.
	if not _selected.is_empty():
		var cell := _cell_sheet_payload(_selected)
		if not cell.is_empty():
			sheet_requested.emit(cell)
			return
	if _focused_payload.is_empty():
		return
	_emit_sheet(_focused_payload)


## A grid cell's sheet: the module fitted there (N35's rows, where the cell holds one).
func _cell_sheet_payload(cell: Dictionary) -> Dictionary:
	var profile := _profile()
	var fit := _resolved_fit(profile, _active_hull(profile))
	var entry := _cell_module(fit, StringName(cell.get(&"type", &"")), int(cell.get(&"index", -1)))
	if entry == &"":
		return {}
	var base := _base_id(profile, entry)
	var module_row := ModuleData.module(base)
	return {
		&"name": String(module_row.get(&"name", String(base))).to_upper(),
		&"stats": Catalog.describe(base),
		&"family": String(module_row.get(&"slot", "")).to_upper(),
		&"owned": _owned_total(profile, base),
	}


## A row's sheet (UI_SPEC section 12.3, N35): the row's own name, the catalogue's
## description as the stat line, its slot family and its held count.
func _sheet_payload(payload: Dictionary) -> Dictionary:
	var base_id: StringName = payload.get(&"base", payload.get(&"id", &""))
	if base_id == &"":
		return {}
	var name_text := String(payload.get(&"name", ""))
	var module_row := ModuleData.module(base_id)
	if module_row.is_empty():
		return {&"name": name_text, &"stats": Catalog.describe(base_id)}
	return {
		&"name": name_text,
		&"stats": Catalog.describe(base_id),
		&"family": String(module_row.get(&"slot", "")).to_upper(),
		&"owned": _owned_total(_profile(), base_id),
	}


## Build (or keep) the SLOT LAYOUT grid for `hull` - a function of the hull's own matrix,
## rebuilt when that matrix changes. A refresh of the same hull keeps its cells and only
## re-applies the selection.
func _sync_grid(hull: StringName) -> void:
	if hull == _grid_hull and not _cells.is_empty():
		_apply_cell_selection()
		return
	_grid_hull = hull
	_cells.clear()
	_selected = {}
	_candidate = &""
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var cells: Array = ShipFit.grid_cells(hull)
	if cells.is_empty():
		_grid.columns = 1
		_slot_caption.text = ""
		return
	_grid.columns = ShipFit.grid_size(hull).x
	var slot_cells := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			var gap := Control.new()
			gap.name = "Gap"
			gap.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_grid.add_child(gap)
		else:
			_cells.append(_make_grid_cell(cell))
			slot_cells += 1
	var engines := int(ShipFit.grid_counts(hull).get(&"engines", 0))
	_slot_caption.text = HARDPOINT_CAPTION % [slot_cells, engines]


## One non-gap matrix cell: the 48 px plate, the type's glyph inset 6, the hidden slot
## caption that flashes 0.5 s on a refused drop (P10) and the cell's own naming line as
## its tooltip (A7's cell tooltips). The empty cell draws dim and carries no cue text.
func _make_grid_cell(cell: Dictionary) -> Dictionary:
	var slot_key: StringName = cell[&"type"]
	var plate := SlotCell.new()
	plate.name = "Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])]
	plate.armory = self
	plate.cell = {
		&"type": slot_key,
		&"token": String(cell[&"token"]),
		&"index": int(cell[&"index"]),
	}
	plate.theme_type_variation = PLATE_VARIATION
	plate.toggle_mode = true
	plate.focus_mode = Control.FOCUS_ALL
	plate.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_grid.add_child(plate)
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.custom_minimum_size = Vector2(
		PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0
	)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = _slot_glyph(slot_key)
	glyph.modulate = _token(&"text_dim")
	plate.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = PLATE_ICON_INSET
	glyph.offset_top = PLATE_ICON_INSET
	glyph.offset_right = -PLATE_ICON_INSET
	glyph.offset_bottom = -PLATE_ICON_INSET
	var caption := Label.new()
	caption.name = "SlotCaption"
	caption.theme_type_variation = &"StationCaption"
	caption.text = _slot_word(slot_key)
	caption.visible = false
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.cell[&"node"] = plate
	plate.cell[&"caption"] = caption
	var payload := plate.cell
	plate.pressed.connect(_on_cell_pressed.bind(payload))
	plate.focus_entered.connect(_on_cell_focused.bind(payload))
	## S30 census row 7: the cell's naming line describes through the N27 tooltip.
	plate.mouse_entered.connect(_on_cell_hovered.bind(payload, true))
	plate.mouse_exited.connect(_on_cell_hovered.bind(payload, false))
	return payload


## 09 section 1's shipped slot glyph for a slot-type key (`fitting_panel.gd:565-574`'s
## own table), null for a type with no glyph so the cell draws its plate alone.
func _slot_glyph(slot_key: StringName) -> Texture2D:
	var stem := String(SLOT_GLYPHS.get(slot_key, ""))
	if stem.is_empty():
		return null
	var path := SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The cell's own slot caption word (the label P10 flashes and the word P9's refusal
## names): the fit's own slot key in upper case, `WEAPONS` / `ENGINES` / `POWER` / ...
func _slot_word(slot_key: StringName) -> String:
	return String(slot_key).to_upper()


func _apply_cell_selection() -> void:
	for payload: Dictionary in _cells:
		var plate := payload[&"node"] as Button
		if plate == null or not is_instance_valid(plate):
			continue
		plate.set_pressed_no_signal(_is_selected(payload))


func _is_selected(payload: Dictionary) -> bool:
	return (
		not _selected.is_empty()
		and payload[&"type"] == _selected[&"type"]
		and int(payload[&"index"]) == int(_selected[&"index"])
	)


## One cell selected: the identity is kept, the meter's preview follows and the footer's
## line and the cluster's label move with it. A click and a focus move both arrive here.
func _select(payload: Dictionary, clicked: bool) -> void:
	if clicked:
		AudioManager.play_ui(AudioManager.UiCue.CLICK)
	else:
		AudioManager.play_ui(AudioManager.UiCue.HOVER)
	_selected = {
		&"type": payload[&"type"],
		&"token": payload[&"token"],
		&"index": int(payload[&"index"]),
	}
	_line_override = ""
	_line_danger = false
	_apply_cell_selection()
	_apply_equipped_selection()
	_refresh_footer()
	_refresh_browser()
	_refresh_cell_info()
	_update_hint()


func _on_cell_pressed(payload: Dictionary) -> void:
	if _inspect_mode:
		var cell := _cell_sheet_payload(payload)
		if not cell.is_empty():
			sheet_requested.emit(cell)
		return
	_select(payload, true)


func _on_cell_focused(payload: Dictionary) -> void:
	_focused_payload = payload
	_select(payload, false)


## Select one cell by its 09 section 4.5 identity, the keyboard's and a probe's door into
## the same selection a click makes. False when the active hull carries no such cell.
func select_cell(slot_key: StringName, index: int) -> bool:
	for payload: Dictionary in _cells:
		if payload[&"type"] == slot_key and int(payload[&"index"]) == index:
			_select(payload, false)
			return true
	return false


func clear_selection() -> void:
	_selected = {}
	_candidate = &""
	_line_override = ""
	_line_danger = false
	_apply_cell_selection()
	_apply_equipped_selection()
	_refresh_footer()
	_refresh_browser()
	_refresh_cell_info()
	_update_hint()


## The cell the pane has selected, `{type, token, index}`, or `{}` when nothing is.
func selected_cell() -> Dictionary:
	return _selected.duplicate()


## The active hull, the same source the grid, the caption, the fit and the meter read.
func active_hull() -> StringName:
	return _active_hull(_profile())


## The meter's own text, read back for probes and tests (the idle form without a selection
## and the `IF FITTED` preview with one).
func meter_text() -> String:
	return _meter.text


## The CELL INFO identity line's text, read back for probes and tests (P33: the one-line
## SelectionLine's replacement).
func footer_text() -> String:
	return _cell_info_id.text


## The browser's row ids in render order, read back for probes and tests.
func module_row_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for payload: Dictionary in _browser_payloads:
		ids.append(payload[&"base"])
	return ids


## The tab in force (`&"all"` by default), read back for probes and tests.
func active_tab() -> StringName:
	return _browser_tab


## Move the shared menu to one category (the keyboard's and a probe's door into the same
## move a tab press makes).
func select_tab(tab_id: StringName) -> void:
	for tab: Dictionary in MENU_TABS:
		if tab[&"id"] == tab_id:
			_browser_tab = tab_id
			_browser_signature.clear()
			_refresh_browser()
			return


## The base id's held units, summed over the bag's own keys (`OWNED ×<n>`'s own count).
func owned_total(base_id: StringName) -> int:
	return _owned_total(_profile(), base_id)


## ------------------------------------------------------------------ the fit arithmetic


func _refresh_footer() -> void:
	## S30 census row 16 (UI_SPEC section 12.5): the grid sync belongs to the hull-change
	## command (`_refresh_all` / `refresh_profile`); a hover or focus reaching the footer
	## must never rebuild the slot matrix. S30 census row 7: the cells' `tooltip_text`
	## writes are gone - their descriptions ride the N27 tooltip through the chain.
	var profile := _profile()
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	_meter.text = _meter_line(profile, hull, fit)
	if _meter_danger(profile, hull, fit):
		_meter.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	else:
		_meter.remove_theme_color_override(&"font_color")
	_remove_button.disabled = not can_remove()
	_buy_fit_button.text = (
		ACTION_BUY_FIT_SELECTED if not _selected.is_empty() else ACTION_BUY_FIT
	)
	_buy_fit_button.disabled = _browser_focused.is_empty()


## The meter as text: the fit the launch flies (`PWR <Σ> / <out>`) and, with a cell
## selected, the `IF FITTED` preview on the candidate's own arithmetic - every number is
## `fit_legal`'s `power` dictionary, never a second arithmetic (section 5.3's own rule).
func _meter_line(profile: ProfileScript, hull: StringName, fit: Dictionary) -> String:
	var power := _power_of(profile, hull, fit)
	var draws := int(power.get(&"draw", 0))
	var out := int(power.get(&"out", 0))
	if _selected.is_empty():
		return METER_IDLE % [draws, out]
	var candidate := _candidate_power(profile, hull, fit)
	var line := METER_PREVIEW % [
		draws, out, int(candidate.get(&"draw", 0)), int(candidate.get(&"out", 0))
	]
	if not bool(candidate.get(&"legal", true)):
		line += METER_OVER % (int(candidate.get(&"draw", 0)) - int(candidate.get(&"out", 0)))
	return line


func _meter_danger(profile: ProfileScript, hull: StringName, fit: Dictionary) -> bool:
	if _selected.is_empty():
		return false
	return not bool(_candidate_power(profile, hull, fit).get(&"legal", true))


## The candidate's arithmetic: the resolved fit with the selected cell set to the entry the
## player is reading (the hovered or focused browser row), the resolved fit itself when no
## such entry is being read or its slot is not the selected cell's.
func _candidate_power(profile: ProfileScript, hull: StringName, fit: Dictionary) -> Dictionary:
	if _selected.is_empty() or _candidate == &"":
		return _power_of(profile, hull, fit)
	var slot_key: StringName = _selected[&"type"]
	if _candidate_slot(profile, _candidate) != slot_key:
		return _power_of(profile, hull, fit)
	return _power_of(
		profile,
		hull,
		_with_cell(_resolved_fit(profile, hull), slot_key, int(_selected[&"index"]), _candidate)
	)


func _power_of(profile: ProfileScript, hull: StringName, fit: Dictionary) -> Dictionary:
	return ShipFit.fit_legal(hull, _base_fit(profile, fit)).get(&"power", {})


## One cell's own naming line - the CELL INFO block and the cell tooltip (A7) share it, so
## the two can never describe two different cells. (`cell_tooltip` is kept as the A7 seam.)
func cell_line(cell: Dictionary, profile: ProfileScript, fit: Dictionary) -> String:
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var entry := _cell_module(fit, slot_key, index)
	var base := _base_id(profile, entry)
	var owned := 0
	var name_text := CELL_EMPTY
	if base != &"":
		name_text = _module_name(base)
		owned = _owned_total(profile, base)
	return SELECTION_FORMAT % [String(cell[&"token"]), index + 1, name_text, owned]


func cell_tooltip(cell: Dictionary, profile: ProfileScript, fit: Dictionary) -> String:
	return cell_line(cell, profile, fit)


## The fit cell's module, `&""` for an empty cell and an index the hull does not carry.
## POWER is one id, not a set (CONTRACTS section 11 rule 1).
func _cell_module(fit: Dictionary, slot_key: StringName, index: int) -> StringName:
	if slot_key == POWER_SLOT:
		var single: Variant = fit.get(slot_key, fit.get(String(slot_key), ""))
		if single is Array:
			for entry: Variant in single as Array:
				if String(entry) != "":
					return StringName(String(entry))
			return &""
		return StringName(String(single)) if single != null else &""
	var raw: Variant = fit.get(slot_key, fit.get(String(slot_key), []))
	if not raw is Array:
		return &""
	var cells: Array = raw as Array
	if index < 0 or index >= cells.size():
		return &""
	return StringName(String(cells[index]))


## The catalogue's slot key of an entry in the fit's own spelling (`engine` -> `engines`).
func _slot_key_of(module_id: StringName) -> StringName:
	var slot: StringName = ModuleData.slot_of(module_id)
	return SLOT_KEY_ALIASES.get(slot, slot)


## An entry's own catalogue slot in the fit's spelling; instances translate to their base.
func _candidate_slot(profile: ProfileScript, entry: StringName) -> StringName:
	return _slot_key_of(_base_id(profile, entry))


## ------------------------------------------------------------- the two fit actions


## Whether the per-cell REMOVE is offered: a cell is selected and it holds a module.
func can_remove() -> bool:
	var profile := _profile()
	if profile == null or _selected.is_empty():
		return false
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	return _cell_module(fit, StringName(_selected[&"type"]), int(_selected[&"index"])) != &""


## The composed remove of the selected cell: `PlayerProfile.clear_fit_slot`. A mandatory
## cell (`ShipFit.MANDATORY_SLOT_KEYS`) is never emptied and answers the pin's wording.
func remove_selected() -> bool:
	var profile := _profile()
	if profile == null or _selected.is_empty():
		return false
	var hull := _active_hull(profile)
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	if ShipFit.MANDATORY_SLOT_KEYS.has(slot_key):
		return _refuse(REFUSAL_MANDATORY)
	var module_id := _cell_module(_resolved_fit(profile, hull), slot_key, index)
	if module_id == &"":
		return false
	if not bool(profile.call(&"clear_fit_slot", hull, slot_key, index)):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	_clear_notice()
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	return true


## The composed install of one entry into the selected cell (`PlayerProfile.fit_module_at`,
## the displaced module returns to the hold through the profile's own transaction). The
## candidate is judged with `ShipFit.fit_legal` first, so an illegal one is refused before
## anything is written (CONTRACTS section 13).
func install_module(module_id: StringName) -> bool:
	var profile := _profile()
	var cell := _row_target_cell(module_id)
	if profile == null or cell.is_empty():
		_notice(ACTION_SELECT, false)
		return false
	return _fit_entry_at(
		module_id, StringName(cell[&"type"]), int(cell[&"index"]), false, 0
	)


## The cell one entry's row acts on: the selected cell when it is of the entry's own
## catalogue slot, `{}` otherwise (the `SELECT A CELL` state).
func _row_target_cell(module_id: StringName) -> Dictionary:
	if _selected.is_empty() or module_id == &"":
		return {}
	if _candidate_slot(_profile(), module_id) != StringName(_selected[&"type"]):
		return {}
	return _selected


## The ACTION word one entry carries right now: `FIT` when the selected cell is of its own
## type and empty, `SWAP` when it already holds a module and `SELECT A CELL` otherwise.
func module_action(module_id: StringName) -> StringName:
	var profile := _profile()
	if profile == null or module_id == &"":
		return &""
	var cell := _row_target_cell(module_id)
	if cell.is_empty():
		return ACTION_SELECT
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	var occupant := _cell_module(fit, StringName(cell[&"type"]), int(cell[&"index"]))
	return ACTION_SWAP if occupant != &"" else ACTION_FIT


## The buy-into-cell one flow (P4): one press, credits checked first. An owned entry fits
## at once; an unowned row buys-then-fits (`PlayerProfile.buy_module` then the same
## composed install). A shortfall refuses through the shell's status line with the shipped
## wording; a legal fit confirms with P11's `FITTED · <MODULE>`.
func _fit_entry_at(
	entry: StringName, slot_key: StringName, index: int, buy: bool, price: int
) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	var base := _base_id(profile, entry)
	var candidate := _with_cell(_resolved_fit(profile, hull), slot_key, index, entry)
	var legal := ShipFit.fit_legal(hull, _base_fit(profile, candidate))
	if not bool(legal[&"legal"]):
		return _refuse(_fit_refusal(legal))
	if buy:
		if int(profile.call(&"credits")) < price:
			return _refuse(STATUS_SHORTFALL % _format_int(price))
		if not bool(profile.call(&"buy_module", base, price)):
			return false
	if not bool(profile.call(&"fit_module_at", hull, slot_key, index, entry)):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	_clear_notice()
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_FITTED % _module_name(base), false)
	return true


## The row's own fit-into-cell flow: an owned row fits its held entry, a buyable row
## buys-then-fits (P4's one flow). The target is the selected cell (a selected cell of
## another family refuses with P9's line and P10's flash) or the next free legal cell.
func _flow_row_into_cell(payload: Dictionary) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var base: StringName = payload.get(&"base", &"")
	var slot_key := _slot_key_of(base)
	var owned := bool(payload.get(&"owned", false))
	var entry: StringName = _row_entry(profile, base) if owned else base
	var target := _flow_target(slot_key, base, payload)
	if target.is_empty():
		return false
	return _fit_entry_at(
		entry, StringName(target[&"type"]), int(target[&"index"]), not owned,
		int(payload.get(&"price", 0))
	)


## The target cell of a flow: the selected cell when it is of the module's own family
## (a wrong-family selection refuses with words), else the next free legal cell, else a
## refusal (`REFUSED · FIT ILLEGAL` - the pin's catch-all).
func _flow_target(slot_key: StringName, base: StringName, payload: Dictionary) -> Dictionary:
	if not _selected.is_empty():
		if StringName(_selected[&"type"]) != slot_key:
			_refuse_drop(base, StringName(_selected[&"type"]), _selected_cell_payload())
			return {}
		return _selected
	var free := _next_free_cell(slot_key)
	if free.is_empty():
		_refuse(REFUSAL_FIT_ILLEGAL)
		return {}
	return free


## The first cell of one family that holds nothing, `{}` when the family is full.
func _next_free_cell(slot_key: StringName) -> Dictionary:
	var profile := _profile()
	var fit := _resolved_fit(profile, _active_hull(profile))
	for payload: Dictionary in _cells:
		if payload[&"type"] != slot_key:
			continue
		if _cell_module(fit, StringName(payload[&"type"]), int(payload[&"index"])) == &"":
			return payload
	return {}


## The selected cell's own grid payload (the drop-callback shape), or `{}` with none.
func _selected_cell_payload() -> Dictionary:
	for payload: Dictionary in _cells:
		if _is_selected(payload):
			return payload
	return {}


## The row-corner BUY and the cluster's `BUY & FIT` (P4/P14): always buys-then-fits into
## the selected cell or the next free legal cell, credits checked first.
func _buy_into_cell(payload: Dictionary) -> bool:
	if payload.is_empty():
		return false
	var base: StringName = payload.get(&"base", &"")
	var slot_key := _slot_key_of(base)
	var target := _flow_target(slot_key, base, payload)
	if target.is_empty():
		return false
	return _fit_entry_at(
		base, StringName(target[&"type"]), int(target[&"index"]), true,
		int(payload.get(&"price", 0))
	)


func _on_remove_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	remove_selected()


func _on_buy_fit_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	## UI_SPEC section 17 A4/A5 (S43-R0/F1's cure): the cluster always buys, so the press
	## is a door - the confirm opens and the confirmed answer runs the same buy-then-fit.
	if _browser_focused.is_empty():
		return
	_request_buy_confirm(
		String(_browser_focused.get(&"name", "")),
		int(_browser_focused.get(&"price", 0)),
		ACTION_BUY_MODULE,
		StringName(_browser_focused.get(&"base", &""))
	)


## ------------------------------------------- the buy-confirmation doors (UI_SPEC 17)


## The door's dialog request (A5/A6): the shell's section 5.2 overlay opens with the
## pinned wording, the name and the price quoted from the catalogue row the confirmed
## press will charge - the payload's own figures, at press time (section 5.8's clock).
func _request_buy_confirm(
	name_text: String, price: int, action: StringName, id: StringName
) -> void:
	confirm_requested.emit({
		&"id": id,
		&"title": BUY_CONFIRM_TITLE,
		&"body": BUY_CONFIRM_BODY % [name_text, _format_int(price)],
		&"confirm_text": BUY_CONFIRM_OK,
		&"cancel_text": BUY_CONFIRM_CANCEL,
		&"action": action,
	})


## The shell's answer to `confirm_requested` (the S25 seam's own contract): the one
## action pair this panel asks about. The confirmed press runs the transaction exactly
## as it always ran, so it can still refuse (section 5.6's strip wording, never a dialog).
func confirm_action(action: StringName, id: StringName) -> void:
	if action == ACTION_BUY_MODULE:
		_run_module_buy(id)
	elif action == ACTION_BUY_AMMO:
		_run_ammo_buy(id)


## The confirmed module buy: the row payload the press quoted, resolved by its base id.
func _run_module_buy(id: StringName) -> void:
	for payload: Dictionary in _browser_payloads:
		if StringName(payload[&"base"]) == id:
			_buy_into_cell(payload)
			return


## The confirmed ammo purchase: the card payload the press quoted, resolved by pack id.
func _run_ammo_buy(id: StringName) -> void:
	for payload: Dictionary in _payloads:
		if StringName(payload[&"id"]) == id:
			_purchase_ammo(payload)
			return


## The confirmed pack purchase - `_on_row_pressed`'s own transaction, unchanged.
func _purchase_ammo(payload: Dictionary) -> void:
	var profile := _profile()
	if profile == null:
		return
	var bought := bool(
		profile.call(
			&"buy_ammo", payload[&"id"], int(payload[&"rounds"]), int(payload[&"cost"])
		)
	)
	if not bought:
		## The refusal text and the denied cue belong to the shell, which hears
		## purchase_failed; the row only marks its own price cell (section 5.6) and
		## wears the section 3.1b danger frame.
		_pulse(payload[&"price"] as Label)
		_style_danger(payload, true)
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_BOUGHT % [String(payload[&"name"]).to_upper(), int(payload[&"rounds"])], false
	)


func _notice(message: String, danger: bool) -> void:
	_line_override = message
	_line_danger = danger
	status_requested.emit(message, danger)
	_refresh_footer()


func _clear_notice() -> void:
	_line_override = ""
	_line_danger = false
	_refresh_footer()


## ------------------------------------------------------- the drag-and-drop law (P4)


## One menu row's drag payload. In FIT CELLS it carries the fit data a grid-cell drop reads
## (its base id, the entry a fit would take and whether the bag holds it - a drop of an
## unowned row buys-then-fits). P39a: in BATTERY CONFIG an owned weapon row drags to a rack,
## so it carries the `DRAG_INVENTORY` payload the rack's own drop route accepts.
func drag_browser(payload: Dictionary) -> Dictionary:
	var profile := _profile()
	var base: StringName = payload.get(&"base", &"")
	if _mode == MODE_BATTERY and _slot_key_of(base) == WEAPON_SLOT and bool(payload.get(&"owned", false)):
		return drag_inventory(base)
	return {
		&"kind": DRAG_BROWSER,
		DRAG_KEY_BASE: base,
		DRAG_KEY_ENTRY: _row_entry(profile, base),
		DRAG_KEY_OWNED: bool(payload.get(&"owned", false)),
		DRAG_KEY_PRICE: int(payload.get(&"price", 0)),
	}


func _drag_payload_of(data: Variant) -> Dictionary:
	if data is Dictionary:
		var payload: Dictionary = data
		if payload.get(&"kind", &"") == DRAG_BROWSER:
			return payload
	return {}


## A browser row's drag and the list's own inventory drag both land on a grid cell
## (P33: drag-to-fit from the list); anything else is not this surface's.
func cell_can_drop(cell: Dictionary, data: Variant) -> bool:
	return not _drag_payload_of(data).is_empty() or not _payload_of(data).is_empty()


## A drop on one grid cell: a legal family fits (or buys-then-fits) the entry; a wrong-slot
## drop is refused by two signals together, never a colour alone (P9/P10): the shell's
## status line and the cell's own slot caption flashing 0.5 s.
func cell_drop(cell: Dictionary, data: Variant) -> void:
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var browser := _drag_payload_of(data)
	if not browser.is_empty():
		var base: StringName = browser.get(DRAG_KEY_BASE, &"")
		if _slot_key_of(base) != slot_key:
			_refuse_drop(base, slot_key, cell)
			return
		_fit_entry_at(
			browser.get(DRAG_KEY_ENTRY, base), slot_key, index,
			not bool(browser.get(DRAG_KEY_OWNED, false)),
			int(browser.get(DRAG_KEY_PRICE, 0))
		)
		return
	var inv := _payload_of(data)
	if String(inv.get(DRAG_KEY_KIND, "")) != String(DRAG_INVENTORY):
		return
	var base_id: StringName = inv.get(DRAG_KEY_BASE, &"")
	if _slot_key_of(base_id) != slot_key:
		_refuse_drop(base_id, slot_key, cell)
		return
	_fit_entry_at(_row_entry(_profile(), base_id), slot_key, index, false, 0)


## The wrong-slot refusal: P9's line in the shell's status strip and P10's 0.5 s slot
## caption flash on the cell itself - label plus state, never a colour alone.
func _refuse_drop(base: StringName, slot_key: StringName, cell: Dictionary) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(
		REFUSAL_DROP % [_module_name(base), _slot_word(slot_key)], true
	)
	_flash_slot_caption(cell)
	return false


## P10: the cell's own slot caption, shown for 0.5 s in the danger-bright token and hidden
## again (the caption text itself is the signal - the flash is a label, not a tint).
func _flash_slot_caption(cell: Dictionary) -> void:
	var caption := cell.get(&"caption", null) as Label
	if caption == null or not is_instance_valid(caption):
		return
	caption.visible = true
	caption.add_theme_color_override(&"font_color", _token(&"accent_danger_bright"))
	var tween := _make_tween()
	tween.tween_interval(SLOT_FLASH_SECONDS)
	tween.tween_callback(caption.hide)


## ================================================== the shared right menu (P39a, S35)
##
## ONE menu component both modes render (P39a): the category strip (`MENU_TABS`), the
## caption, the AUCTION-idiom band and the row list. The pane builds it once (`_build_browser`)
## and reparents the subtree between the two modes' right sectors (`_apply_mode`). The modes
## differ only in the row actions (fit/BUY vs drag-to-rack) and the FIT CELLS socket filter.


## The one category strip (`MENU_TABS`) over the one list, plus its AUCTION-idiom
## column-header band (P40). The single menu builder - both modes read this subtree.
func _build_browser() -> void:
	for tab: Dictionary in MENU_TABS:
		var button := Button.new()
		button.name = "Tab%s" % String(tab[&"id"]).to_pascal_case()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = TAB_MIN_SIZE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = String(tab[&"label"])
		button.set_meta(&"tab", StringName(tab[&"id"]))
		button.add_theme_color_override(
			&"font_color",
			_token(&"text_primary") if tab[&"id"] == _browser_tab else _token(&"text_dim")
		)
		button.pressed.connect(_on_tab_pressed.bind(StringName(tab[&"id"])))
		_tabs.add_child(button)
	_build_list_band(
		_browser_band, _band_captions(), _band_widths(), BAND_MODULE
	)


## F3 (D23-R1, MED): the one band's value-column words, per mode. FIT CELLS lists a state
## tag and a cost/owned read (`STATE` / `COST`); BATTERY CONFIG's rows print `FITTED` and
## `OWNED x n` in the same two columns, so its band reads `STATE` / `HELD`. The pair is a
## content swap in the one shared band (N31's legal set) - the band itself never moves.
func _band_captions() -> Array:
	## A18: the AMMUNITION tab's rows carry their own held column, so the band
	## seats a HELD caption over it before STATE/COST.
	if _browser_tab == EQ_TAB_AMMO:
		return [BAND_HELD, BAND_STATE, BAND_COST]
	return [BAND_STATE, BAND_HELD] if _mode == MODE_BATTERY else [BAND_STATE, BAND_COST]


## The value columns' own widths, paired with `_band_captions()`'s captions.
func _band_widths() -> Array:
	if _browser_tab == EQ_TAB_AMMO:
		return [BAND_HELD_COLUMN, BAND_TAG_COLUMN, BAND_COST_COLUMN]
	return [BAND_TAG_COLUMN, BAND_COST_COLUMN]


## One list's AUCTION-idiom column-header band (P40): a leading caption cell over the title
## column, then one caption cell seated over each value column at that column's own width.
func _build_list_band(
	band: HBoxContainer, captions: Array, widths: Array, leading: String
) -> void:
	if band == null:
		return
	for child: Node in band.get_children():
		band.remove_child(child)
		child.queue_free()
	var icon_gap := Control.new()
	icon_gap.name = "IconGap"
	icon_gap.custom_minimum_size = Vector2(BROWSER_ICON, 0.0)
	icon_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(icon_gap)
	var lead := _make_caption(leading, ROLE_CAPTION)
	lead.name = "HeaderLead"
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.add_child(lead)
	for index in captions.size():
		var cell := _make_caption(String(captions[index]), ROLE_CAPTION)
		cell.name = "Header%s" % String(captions[index]).to_pascal_case()
		cell.custom_minimum_size = Vector2(float(widths[index]), 0.0)
		band.add_child(cell)
	## Every browser row ends with the ACTION_INLINE chip cell (the ammo rows'
	## A18 `Buy`, the module rows' own), so the band carries the same trailing
	## cell and the captions seat over the columns instead of riding the chip's
	## 108 px (S50-A F04).
	var chip_gap := Control.new()
	chip_gap.name = "ChipGap"
	chip_gap.custom_minimum_size = Vector2(ACTION_INLINE.x, 0.0)
	chip_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(chip_gap)


func _on_tab_pressed(tab_id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	select_tab(tab_id)
	_apply_tab_states()


## The one list's rows in the state the pane is in (P38/P39a). With no cell selected it
## browses everything the profile owns (the tab's family) - the bag's units UNION the active
## hull's fitted bases, so a base owned only as a fitted instance still lists - tagged `FIT`
## when the hull carries a cell of that family and `STORED` otherwise. With a cell selected
## (FIT CELLS only - BATTERY CONFIG has no socket filter) it lists every possibility for that
## cell - the owned candidates first (`OWNED`, select-to-fit and drag-to-fit) then the
## catalogue's buyable ones (`BUYABLE`, BUY + INSPECT) - each row carrying the legality line
## the CELL INFO block speaks.
func _equip_rows(profile: ProfileScript) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if profile == null:
		return rows
	## P39a: the FIT CELLS socket filter is FIT CELLS' own; BATTERY CONFIG's menu is a flat
	## browse list whatever the grid selection happens to be.
	var cell_filter: bool = _mode == MODE_FIT and not _selected.is_empty()
	var hull := _active_hull(profile)
	var wanted := &""
	for tab: Dictionary in MENU_TABS:
		if tab[&"id"] == _browser_tab:
			wanted = StringName(tab[&"slot"])
	if not cell_filter:
		var fitted := _fitted_bases(profile, hull)
		for module_id: StringName in ModuleData.MODULES:
			if wanted != &"" and ModuleData.slot_of(module_id) != wanted:
				continue
			var owned := _owned_total(profile, module_id)
			var is_fitted := fitted.has(module_id)
			if owned <= 0 and not is_fitted:
				continue
			var tag: String = TAG_FIT if is_fitted else TAG_STORED
			rows.append(_equip_entry(module_id, tag, owned, 0, ""))
		if wanted == &"":
			for entry: StringName in _lost_entries(profile):
				rows.append(_equip_entry(entry, TAG_STORED, 0, 0, ""))
		return rows
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	for module_id: StringName in ModuleData.MODULES:
		if _slot_key_of(module_id) != slot_key:
			continue
		if _owned_total(profile, module_id) <= 0:
			continue
		if not _cell_refusal(profile, hull, index, module_id).is_empty():
			continue
		rows.append(_equip_entry(
			module_id, TAG_OWNED, _owned_total(profile, module_id), 0,
			_row_legality(profile, hull, index, module_id)
		))
	for module_id: StringName in ModuleData.MODULES:
		if _slot_key_of(module_id) != slot_key:
			continue
		if _owned_total(profile, module_id) > 0:
			continue
		if not _cell_refusal(profile, hull, index, module_id).is_empty():
			continue
		rows.append(_equip_entry(
			module_id, TAG_BUYABLE, 0, _module_price(module_id),
			_row_legality(profile, hull, index, module_id)
		))
	return rows


## One list row's shape, the one place the two states agree.
func _equip_entry(
	base_id: StringName, tag: String, owned: int, price: int, legal: String
) -> Dictionary:
	return {
		&"base": base_id,
		&"name": _module_name(base_id),
		&"tag": tag,
		&"owned": owned,
		&"price": price,
		&"legal": legal,
		&"slot": ModuleData.slot_of(base_id),
		&"draw": int(ModuleData.module(base_id).get(&"draw", 0)),
	}


## The active hull's fitted base ids - the set a `FIT` tag reads against (a browse row is
## `FIT` when the ship already carries that base, `STORED` when the bag holds it and the fit
## does not).
func _fitted_bases(profile: ProfileScript, hull: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var fit := _resolved_fit(profile, hull)
	for slot_key: StringName in ShipFit.FIT_SLOT_KEYS:
		var cells := 1 if slot_key == POWER_SLOT else ShipFit.slot_capacity(hull, slot_key)
		for index in cells:
			var entry := _cell_module(fit, slot_key, index)
			if entry == &"":
				continue
			var base := _base_id(profile, entry)
			if base != &"" and not out.has(base):
				out.append(base)
	return out


## One row's proactive legality line (P38): `LEGAL · THIS CELL FITS` when the cell takes it,
## else the pane's own refusal wording (`_cell_refusal`'s, the strings at the file's head).
func _row_legality(
	profile: ProfileScript, hull: StringName, index: int, base_id: StringName
) -> String:
	var refusal := _cell_refusal(profile, hull, index, base_id)
	return CELL_INFO_LEGAL_OK if refusal.is_empty() else refusal


## The fit's own cells whose module the bag can no longer resolve (a fitted instance whose
## record is gone) - each id listed once (`fitting_panel.gd:690-707`'s own law).
func _lost_entries(profile: ProfileScript) -> Array[StringName]:
	var lost: Array[StringName] = []
	if profile == null:
		return lost
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	for slot_key: StringName in ShipFit.FIT_SLOT_KEYS:
		var cells := 1 if slot_key == POWER_SLOT else ShipFit.slot_capacity(hull, slot_key)
		for index in cells:
			var entry := _cell_module(fit, slot_key, index)
			if entry == &"" or lost.has(entry):
				continue
			if _base_id(profile, entry) != entry:
				continue
			if not ModuleData.module(entry).is_empty():
				continue
			lost.append(entry)
	return lost


func _refresh_browser() -> void:
	var profile := _profile()
	_apply_tab_states()
	## P39a: the AMMUNITION category draws the shipped pack cards (its BUY route) in both
	## modes; every other category draws the shared equipment rows.
	var ammo := _browser_tab == EQ_TAB_AMMO
	var rows: Array[Dictionary] = []
	if not ammo:
		rows = _equip_rows(profile)
	var signature := _menu_signature(rows, ammo)
	if signature != _browser_signature:
		_browser_signature = signature
		_build_browser_rows(rows, profile, ammo)
	if _browser_caption != null:
		_browser_caption.text = _menu_caption(ammo, rows)
	if ammo:
		for payload: Dictionary in _payloads:
			_refresh_row(payload)
	else:
		for payload: Dictionary in _browser_payloads:
			_refresh_browser_row(payload, profile)


## The shared menu's rebuild signature: the mode, the category, the socket filter state and
## every row's identity (or every pack's id on the AMMUNITION category), so a refresh
## rebuilds only when the row set actually moves.
func _menu_signature(rows: Array[Dictionary], ammo: bool) -> Array[String]:
	var signature: Array[String] = ["mode:%s" % String(_mode), "tab:%s" % String(_browser_tab)]
	if ammo:
		for pack: Dictionary in Catalog.AMMO_PACKS:
			signature.append("pack:%s" % String(pack.get(&"id", &"")))
		return signature
	signature.append(
		"cell:%s:%d" % [String(_selected[&"type"]), int(_selected[&"index"])]
		if _mode == MODE_FIT and not _selected.is_empty()
		else "browse"
	)
	for entry: Dictionary in rows:
		signature.append("%s|%s|%d" % [
			String(entry[&"base"]), String(entry[&"tag"]), int(entry[&"owned"])
		])
	return signature


## The shared menu's caption: the AMMUNITION category counts its packs, every other category
## its rows (the FIT CELLS cell caption when a cell is selected).
func _menu_caption(ammo: bool, rows: Array[Dictionary]) -> String:
	if ammo:
		return AMMO_CAPTION % _payloads.size()
	return _list_caption(rows.size())


func _build_browser_rows(rows: Array[Dictionary], profile: ProfileScript, ammo: bool) -> void:
	_browser_payloads.clear()
	_payloads.clear()
	_browser_focused = {}
	for child: Node in _browser_rows.get_children():
		_browser_rows.remove_child(child)
		child.queue_free()
	if ammo:
		for pack: Dictionary in Catalog.AMMO_PACKS:
			_payloads.append(_build_card(pack))
		return
	if rows.is_empty():
		var empty := _make_caption(_list_empty_text())
		empty.name = "Empty"
		_browser_rows.add_child(empty)
		return
	for entry: Dictionary in rows:
		_browser_payloads.append(_build_browser_row(entry, profile))


## The active tab's plate reads `text_primary` and wears its pressed state; the rest read
## `text_dim` - the theme's own `TabBar` colour language (the auction's tab idiom).
func _apply_tab_states() -> void:
	for button: Node in _tabs.get_children():
		var tab_button := button as Button
		if tab_button == null:
			continue
		var active := StringName(tab_button.get_meta(&"tab", &"")) == _browser_tab
		tab_button.set_pressed_no_signal(active)
		tab_button.add_theme_color_override(
			&"font_color", _token(&"text_primary") if active else _token(&"text_dim")
		)


## One list row (the auction row idiom: 76 tall, `RowInner` 12/8): the module's icon, its
## name and `SLOT <TYPE> · DRAW <n>` meta, its proactive legality line, its state tag
## (`FIT`/`STORED`/`OWNED`/`BUYABLE`), its `OWNED ×n` / price read and - on a `BUYABLE` row -
## the row-corner BUY chip (P1's `ActionInline` 96x32). Every row is a drag source.
func _build_browser_row(entry: Dictionary, _profile_unused: ProfileScript) -> Dictionary:
	var base_id: StringName = entry[&"base"]
	var module_row := ModuleData.module(base_id)
	var name_text := String(entry[&"name"])
	if name_text.is_empty():
		name_text = String(base_id).to_upper()
	var tag_text := String(entry[&"tag"])
	var row := BrowserRow.new()
	row.name = "Module%s" % String(base_id).to_pascal_case()
	row.armory = self
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, BROWSER_ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## S36 (UI_SPEC section 15.1): the browser row wears C4 `ui_row_strip`.
	ChromeFamily.apply_row(row)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_TEXT_INSET * 2.0)
	inner.add_theme_constant_override(&"margin_top", 8.0)
	inner.add_theme_constant_override(&"margin_right", ROW_TEXT_INSET * 2.0)
	inner.add_theme_constant_override(&"margin_bottom", 8.0)
	row.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var icon := _make_icon(String(module_row.get(&"icon", "")), BROWSER_ICON)
	if icon != null:
		box.add_child(icon)
	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override(&"separation", 2)
	## N45: a fixed 160 px ellipsis column - long catalogue names trim instead of pushing the
	## BUY / INSPECT chips past the window.
	title_box.custom_minimum_size = Vector2(BROWSER_TITLE_COLUMN, 0.0)
	title_box.size_flags_horizontal = Control.SIZE_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_box)
	var title := _make_label(&"StationValue", name_text, true)
	title.name = "Title"
	title_box.add_child(title)
	var meta := _make_label(
		&"StationMeta",
		BROWSER_META_FORMAT % [
			String(module_row.get(&"slot", "")).to_upper(), int(module_row.get(&"draw", 0))
		],
		true
	)
	meta.name = "Meta"
	title_box.add_child(meta)
	## P38: the row's own proactive legality line (the CELL INFO block's own vocabulary).
	var legal := _make_label(&"StationMeta", String(entry[&"legal"]), true)
	legal.name = "Legal"
	title_box.add_child(legal)
	var slack := Control.new()
	slack.name = "TitleSlack"
	slack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(slack)
	var tag := _make_label(&"StationCaption", tag_text, true)
	tag.name = "Tag"
	tag.custom_minimum_size = Vector2(BAND_TAG_COLUMN, 0.0)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(tag)
	var read := _make_label(&"StationValue", "")
	read.name = "Read"
	read.custom_minimum_size = Vector2(COL_OWNED, 0.0)
	read.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(read)
	var buy: Button = null
	if tag_text == TAG_BUYABLE:
		buy = Button.new()
		buy.name = "Buy"
		buy.custom_minimum_size = ACTION_INLINE
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.focus_mode = Control.FOCUS_ALL
		buy.text = BUY_CHIP
		box.add_child(buy)
	var payload := {
		&"base": base_id,
		&"name": name_text,
		&"slot": StringName(module_row.get(&"slot", &"")),
		&"draw": int(module_row.get(&"draw", 0)),
		&"price": int(entry[&"price"]),
		&"tag": tag_text,
		&"legal": String(entry[&"legal"]),
		&"owned": int(entry[&"owned"]) > 0,
		&"row": row,
		&"read": read,
		&"tag_label": tag,
		&"legal_label": legal,
		&"buy": buy,
		&"icon": icon,
	}
	row.payload = payload
	row.pressed.connect(_on_browser_pressed.bind(payload))
	row.focus_entered.connect(_on_browser_focused.bind(row, payload))
	row.mouse_entered.connect(_on_browser_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_browser_hovered.bind(payload, false))
	if buy != null:
		buy.pressed.connect(_on_buy_pressed.bind(payload))
	_browser_rows.add_child(row)
	return payload


func _refresh_browser_row(payload: Dictionary, profile: ProfileScript) -> void:
	var base_id: StringName = payload[&"base"]
	var owned := _owned_total(profile, base_id)
	payload[&"owned"] = owned > 0
	var read: Label = payload[&"read"]
	if owned > 0:
		read.text = OWNED_FORMAT % owned
	elif String(payload[&"tag"]) == TAG_FIT:
		read.text = READ_FITTED
	else:
		read.text = PRICE_FORMAT % _format_int(int(payload[&"price"]))
	var legal: Label = payload[&"legal_label"]
	var legal_text := String(payload[&"legal"])
	legal.text = legal_text
	legal.add_theme_color_override(
		&"font_color",
		_token(ROLE_CAPTION if legal_text.is_empty() or legal_text == CELL_INFO_LEGAL_OK else ROLE_DANGER_BRIGHT)
	)


func _on_browser_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row := payload[&"row"] as Button
	if _inspect_mode:
		_emit_sheet(payload)
		return
	if row != null and is_instance_valid(row):
		row.set_pressed_no_signal(true)
	_browser_focused = payload
	var profile := _profile()
	_candidate = _row_entry(profile, StringName(payload[&"base"]))
	## T-118: a keyboard `ui_accept` press must not pop the popup at the OS cursor.
	if _pointer_over(row):
		_inspect_browser(payload, true)
	## P38/P39a: the browse state is a browse surface - a press only inspects it. With a FIT
	## CELLS cell selected the press is the select-to-fit flow; BATTERY CONFIG has no filter.
	if _mode != MODE_FIT or _selected.is_empty():
		return
	## UI_SPEC section 17 A4/A5 (S43-R0/F1's cure): a BUYABLE row's select-to-fit buys
	## as it fits, so the flow is a door - the confirm opens and the confirmed answer
	## runs the same buy-then-fit. An owned row fits a held instance and stays dialog-free.
	if not bool(payload.get(&"owned", false)):
		_request_buy_confirm(
			String(payload[&"name"]), int(payload[&"price"]),
			ACTION_BUY_MODULE, StringName(payload[&"base"])
		)
		return
	_flow_row_into_cell(payload)


func _on_buy_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_browser_focused = payload
	## T-118: only a pointer over the row publishes the hover line.
	if _pointer_over(payload[&"row"] as Button):
		_inspect_browser(payload, true)
	## UI_SPEC section 17 A4/A5: the browser's BUY is a door - the confirm dialog opens
	## here and the confirmed answer runs `_buy_into_cell`, the buy-then-fit unchanged.
	_request_buy_confirm(
		String(payload[&"name"]), int(payload[&"price"]),
		ACTION_BUY_MODULE, StringName(payload[&"base"])
	)


func _on_browser_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _browser_focused.get(&"row", null) != null and _browser_focused[&"row"] != row:
		var previous := _browser_focused[&"row"] as Button
		if previous != null and is_instance_valid(previous):
			previous.set_pressed_no_signal(false)
	_browser_focused = payload
	row.set_pressed_no_signal(true)
	var profile := _profile()
	_candidate = _row_entry(profile, StringName(payload[&"base"]))
	_refresh_footer()
	_refresh_cell_info()
	## T-118: the hover popup is the pointer's sink - a keyboard focus (Tab) must not pop it
	## at the OS cursor.
	if _pointer_over(row):
		_inspect_browser(payload, true)


## T-118: is the OS pointer inside the row's own rect? A keyboard-driven focus is not a hover.
func _pointer_over(row: Button) -> bool:
	if row == null or not is_instance_valid(row):
		return false
	return row.get_global_rect().has_point(row.get_global_mouse_position())


func _on_browser_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon := payload.get(&"icon", null) as TextureRect
	if icon != null and is_instance_valid(icon):
		var tween := _make_tween()
		tween.tween_property(
			icon, "modulate:a", 1.0 if hovered else ROW_ICON_IDLE_ALPHA, HOVER_SECONDS
		)
	var profile := _profile()
	_candidate = _row_entry(profile, StringName(payload[&"base"])) if hovered else &""
	_refresh_footer()
	_refresh_cell_info()
	_inspect_browser(payload, hovered)


## CONTRACTS section 23.1: the browser row's additive inspector line through the existing
## `describe()` chain (a leave clears the block with `title == ""`).
func _inspect_browser(payload: Dictionary, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		String(payload.get(&"name", "")),
		Catalog.describe(StringName(payload.get(&"base", &""))),
		false
	)


## ------------------------------------------------------- the bag reads (5.3's own)


## The bag's own unit sum per base id (`fitting_panel.gd:632-645`'s own accessor law).
func _bag_units(profile: ProfileScript) -> Dictionary:
	var counts: Dictionary = {}
	if profile == null:
		return counts
	for key: Variant in profile.call(&"modules"):
		var entry := StringName(str(key))
		var held := int(profile.call(&"module_count", entry))
		if held <= 0:
			continue
		var base := StringName(profile.call(&"base_module_id", entry))
		if ModuleData.module(base).is_empty():
			continue
		counts[base] = int(counts.get(base, 0)) + held
	return counts


func _owned_total(profile: ProfileScript, base_id: StringName) -> int:
	if base_id == &"":
		return 0
	return int(_bag_units(profile).get(base_id, 0))


## The entry one row's flow acts on: the base id's first held instance, in the bag's own
## order (`fitting_panel.gd:992-994`'s own rule), the base id itself for a base-keyed
## record.
func _row_entry(profile: ProfileScript, base_id: StringName) -> StringName:
	var ids: Array[StringName] = []
	if profile != null and base_id != &"":
		var raw: Variant = profile.call(&"instances_of", base_id)
		if raw is Array:
			for entry: Variant in raw as Array:
				ids.append(StringName(str(entry)))
	return ids[0] if not ids.is_empty() else base_id
