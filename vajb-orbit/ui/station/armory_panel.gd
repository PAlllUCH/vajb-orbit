extends Control
## ARMORY (the OUTFITTING pane renamed, STATION_HUB section 5.11's 2026-09-23 S5
## amendment): **battery composition by drag and drop** (09 section 11, CONTRACTS
## section 17) above the ammunition rows - now on the cockpit instrument language
## (UI_SPEC section 3.9 / section 3.10, wave D7).
##
## Three groups, in render order, each one in a recessed well of the painted console:
##
##   - **BATTERY RACKS** - racks `B1..B7`, one drop zone per `weapon_1..7` key, drawn as
##     Mockup A's **4+3 grid** of bolted bay plates (`ui_armory_rack_plate`), each bay
##     carrying its four **W cells as machined slot recesses** and a **SALVO strip** of
##     three `ui_seg_*` cells (seconds x 100, `073` = 0.73 s - the approved Mockup A
##     figure; the brief's own "seconds x10" cannot hold the approved example, see the
##     report). A rack holds the W cells that fire together; dragging an inventory weapon
##     onto a rack installs it into the rack's **next free W cell** through the profile's
##     composed `fit_into_rack` (the section 13/16 transactions: `fit_legal` and the
##     mandatory set are checked before the first write, and a refusal writes nothing at
##     all). A rack may hold mixed kinds: the salvo's rate is the slowest member's cycle.
##     Dragging a barrel within a rack re-orders it; onto another rack (or another barrel)
##     it moves or swaps; the `x` returns a barrel to the inventory.
##   - **INVENTORY** - one row per owned weapon **id** (aggregated, catalogue order), each
##     one a drag source on a brushed row plate.
##   - **AMMUNITION** - one card per `StationCatalog.AMMO_PACKS` entry (three across, the
##     six packs in two rows), buying **cargo units** (`units = rounds /
##     ROUNDS_PER_CARGO_UNIT`) through `PlayerProfile.buy_ammo`.
##
## **Surface only** (section 3.10): the pane's signals, transactions, drag-drop behaviour
## and the refusal-writes-nothing rule are untouched - every seam and number of STATION_HUB
## section 5.11, 09 section 11 and CONTRACTS section 17 survives. Every colour, layout
## metric and asset path comes from `ArmoryStyle` (`ui/station/armory_style.gd`), which
## extends `CockpitStyle` (section 3.9 rule 5): one palette, one asset idiom, and a user
## `.tres` restyles and relayouts the pane with no code edit.
##
## The panel never writes the store directly (STATION_HUB section 12.4): it calls the
## profile's composed APIs, `fit_for`/`resolved_fit`/`instances_of`/`battery_groups`/
## `free_weapon_cell` and `ShipFit.*`, and reports every refusal through its footer.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const StyleScript := preload("res://ui/station/armory_style.gd")

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

## The header strip's own columns (the S5 row anatomy, kept for the fit pass and the
## header's own declaration; the ammunition cards carry their figures inline now).
const COL_ICON := 40.0
const COL_HELD := 130.0
const COL_PRICE := 110.0
const COL_TAG := 160.0
const COL_ACTION := 160.0

## The ammunition card's own grid (three across, Mockup A's own three boxes): the well is
## 406 logical wide, so three cards fill it with `ROW_GAP` between them.
const AMMO_COLUMNS := 3
## A row's inner padding, in drawn pixels (the plates carry the chrome, not the margins).
const ROW_INNER_MARGIN := Vector2i(6, 4)
const COLUMN_SEPARATION := 6
const CELL_SEPARATION := 1
## The rows' own type sizes (the instrument language's compact bands; section 3.10 cuts the
## ammunition row to 32 and the inventory row to 22).
const AMMO_TITLE_FONT_SIZE := 12
const AMMO_META_FONT_SIZE := 11
const INVENTORY_NAME_FONT_SIZE := 13
const INVENTORY_TAG_FONT_SIZE := 11
## The ammunition card's right column, in drawn pixels.
const AMMO_VALUE_COLUMN := 96.0
## The two ammunition rows' five declared columns, in order. `_header_cells()` and a row's
## own grid declare the same list, so the header can be re-fitted from a live row
## instead of repeating the declared widths (see `_fit_section`).
const GRID_CELLS: Array[StringName] = [&"Icon", &"TitleBox", &"Held", &"Price", &"Status"]
## Frames the header fit retries while its host has not laid the rows out yet.
const HEADER_FIT_RETRIES := 8
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const HEADER_PACK := "PACK"
const HEADER_HELD := "HELD / MAX"
const HEADER_PRICE := "PRICE"
const HEADER_STATUS := "STATUS"
const PRICE_CAPTION := "CREDITS"
const ROUNDS_CAPTION := "%d ROUNDS PER PACK"
## The subtitle counts the packs the catalogue carries and the racks the pane draws
## (`GROUPS_MAX`, `game/weapons.gd`), so neither figure can go stale.
const SUBTITLE := "BATTERY RACKS AND AMMUNITION · %d PACKS · %d RACKS"
const TAG_LIST_PREFIX := "IDS "
const TAG_LIST_SEPARATOR := " · "

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
const HELD_FORMAT := "%d / %d"
const UNAVAILABLE_VALUE := "0 / 0"
const STATUS_HINT := "ENTER BUY · %s · %s CREDITS"
## The purchase line stays the pinned P2-B1 wording, including its rounds: the pack's
## own `rounds` is what the player bought, and the units it arrived as are visible in
## the row's HELD cell on the same frame.
const STATUS_BOUGHT := "PURCHASED · %s · +%d ROUNDS"

## The rack column (09 section 11, CONTRACTS section 17): `B1..B7`, one drop zone per
## `weapon_1..7` key, drawn in the input map's own order. `WeaponComponent.GROUPS_MAX`
## is the whole number, so a grown group count grows the rack strip with it.
const WEAPON_SLOT: StringName = &"weapons"
## The one scalar slot type (09 section 4.5 rule 1): `_with_cell` keeps the shape for
## it although a W rack never touches it.
const POWER_SLOT: StringName = &"power"
const RACK_COUNT: int = WeaponComponent.GROUPS_MAX
const RACK_LABEL := "B%d"
## The bay's own `B<n>` plate width and its key hint (`(1)` .. `(7)`, Mockup A's own
## keyboard legend at the bay's top-right).
const RACK_LABEL_WIDTH := 40.0
const RACK_KEY := "(%d)"
const RACK_INSTALL_CUE := "DROP A WEAPON FROM THE INVENTORY HERE"
const RACK_SALVO := "SALVO %.1f s"
## The SALVO drum's approved figure (Mockup A, owner "Looks good" 2026-09-24): the cycle
## in **hundredths of a second**, three cells, zero-padded (`073` = 0.73 s). A cycle of
## 0 s has no figure and reads blanks; the pane's own state line (RACK_SALVO / RACK_READY)
## still answers through `rack_rows()`.
const SALVO_MAX := 999
const SALVO_DIGITS := 3
## A rack with no travelling member states `READY` instead of a cadence: an instant family
## (the laser) has no cycle of its own to gate a salvo on.
const RACK_READY := "READY"
const BARREL_TEXT := "W%d %s"
const BARREL_CLOSE := "✕"
const INVENTORY_EMPTY := "NO WEAPONS IN THE INVENTORY · BUY THEM IN THE AUCTION"
const INVENTORY_TEXT := "%s  ×%d"
const INVENTORY_META := "W SLOT · DRAW %d"
## The two drag payloads (`_get_drag_data` / `_can_drop_data` / `_drop_data`):
## an inventory row carries its base id, a barrel its address in the racks.
const DRAG_INVENTORY: StringName = &"inventory"
const DRAG_BARREL: StringName = &"barrel"
const DRAG_KEY_KIND: StringName = &"kind"
const DRAG_KEY_BASE: StringName = &"base"
const DRAG_KEY_RACK: StringName = &"rack"
const DRAG_KEY_POSITION: StringName = &"position"
## A drop on the rack's own body rather than on one of its barrels (the install route).
const DROP_RACK_BODY := -1

## The three refusal wordings, byte-equivalent to `ui/station/fitting_panel.gd:147-149`
## (CONTRACTS section 16 rule 9, the L116 precedent): ARMORY may not preload the pane
## whose constants are the pin's single home, so it declares its own twins. The overload
## line takes `fit_legal`'s own power numbers; the mandatory wording is **unreachable for
## a W cell** (`FitData.MANDATORY_SLOT_KEYS` is `[engines, power]`, game/ship_fit.gd:117)
## and is carried for the set's completeness only, so no test may assert it through a
## rack. The fourth line is the P2-B1 strip's own `W SLOTS FULL — SWAP OR REMOVE FIRST`,
## kept for the state it names: every W cell of the hull already holds a barrel.
const REFUSAL_OVERLOAD := "%d / %d PWR — OVER BY %d"
const REFUSAL_MANDATORY := "MANDATORY CELL — SWAP ONLY, NEVER EMPTY"
const REFUSAL_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"
const REFUSAL_W_SLOTS_FULL := "W SLOTS FULL — SWAP OR REMOVE FIRST"
const REFUSAL_NO_WEAPONS := "NO WEAPONS IN THE INVENTORY"
## The three successes: S5 pins the refusals, not the success lines, so these are this
## pane's own copy, one constant each. Reversal: one constant.
const STATUS_INSTALLED := "INSTALLED · %s · %s"
const STATUS_MOVED := "MOVED · %s · %s"
const STATUS_REMOVED := "REMOVED · %s · BACK IN INVENTORY"

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
const ROLE_TEXT_DIM: StringName = &"text_dim"
const ROLE_DANGER: StringName = &"accent_danger"
const ROLE_DANGER_BRIGHT: StringName = &"accent_danger_bright"
const ROLE_METAL_LIGHT: StringName = &"metal_light"
const ROLE_METAL_DARK: StringName = &"metal_dark"
const ROLE_VOID: StringName = &"void_base"
const ROLE_PANEL_STEEL: StringName = &"panel_steel"


## One barrel chip's name plate: the drag source of a barrel (S5, 09 section 11). The
## payload is its address in the racks, so a drop knows what is being moved without
## reading the tree it may be about to rebuild. Its ink is transparent - Mockup A draws a
## fitted cell as a machined block inside its slot, and the name lives on in `text` (the
## existing suites read it) and in the tooltip.
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


## One barrel chip: the name plate over its `x`, and a drop zone of its own - dropping a
## barrel **on** another barrel is the swap (09 section 11's between-rack swap). Mockup A
## keeps the chip inside its machined W-cell recess.
class BarrelCell extends HBoxContainer:
	var armory: Control = null
	var rack := 0
	var slot := 0


	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, slot, data))


	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, slot, data)


## One rack: the `B<n>` label, its key hint, its state line, its barrels and the drop zone
## that installs a dragged inventory weapon into the rack's next free W cell. Laid out as
## Mockup A's bay: the plate strip over the well, the four W-cell recesses, the engraved
## ledge and the SALVO strip beneath it.
class RackRow extends PanelContainer:
	var armory: Control = null
	var rack := 0


	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, -1, data))


	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, -1, data)


## One inventory row: a drag source carrying its base id, drawn from the catalogue and
## the bag. Its own `pressed` does nothing - the row is a handle, not an action.
class InventoryRow extends Button:
	var armory: Control = null
	var base_id: StringName = &""


	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_inventory", base_id)


## The console's own wells (section 3.9 rule 4: state and chrome are code-drawn over the
## painted plate): the three recesses and one bay card per rack, in the style's tokens.
class ConsoleWells extends Control:
	var style: Resource = null
	var regions: Array[Rect2] = []
	var bays: Array[Rect2] = []


	func configure(new_style: Resource, new_regions: Array[Rect2], new_bays: Array[Rect2]) -> void:
		style = new_style
		regions = new_regions
		bays = new_bays
		queue_redraw()


	func well_rects() -> Array[Rect2]:
		return regions


	func bay_rects() -> Array[Rect2]:
		return bays


	func _draw() -> void:
		if style == null:
			return
		for rect: Rect2 in regions:
			_recess(rect)
		for rect: Rect2 in bays:
			_recess(rect)


	func _recess(rect: Rect2) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_VOID)
		box.corner_radius_top_left = int(style.drawn(4.0))
		box.corner_radius_top_right = int(style.drawn(4.0))
		box.corner_radius_bottom_left = int(style.drawn(4.0))
		box.corner_radius_bottom_right = int(style.drawn(4.0))
		draw_style_box(box, rect)
		var width: float = style.drawn(style.frame_width)
		var dark: Color = style.colour(ROLE_METAL_DARK)
		var light: Color = style.colour(ROLE_METAL_LIGHT)
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), dark, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), dark, width, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, light, width, true)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, light, width, true)


## One rack bay's code-drawn marks: the machined block of every fitted W cell (Mockup A
## draws a block inside each occupied slot recess, 20 x 24 inside the 40 x 44 recess) and
## the section 3.2 ember frame when this bay is the selected rack.
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
		if style == null:
			return
		for index: int in filled:
			var slot: Rect2 = style.drawn_rect(style.slot_rect(index))
			var inset := Rect2(
				slot.position + style.drawn_vector(Vector2(10.0, 10.0)),
				style.drawn_vector(Vector2(20.0, 24.0))
			)
			draw_rect(inset, style.colour(ROLE_METAL_LIGHT), true)
		if selected:
			draw_rect(
				Rect2(Vector2.ZERO, size),
				style.colour(ROLE_DANGER_BRIGHT),
				false,
				style.drawn(style.selected_frame_width)
			)


## One rack bay's SALVO strip: the engraved ledge, the three `ui_seg_*` drum cells and the
## pinned 12 px `SALVO s` caption (section 3.9 rule 3: no baked text, engine Labels and
## drum cells only).
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
			_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_caption)
		_caption.text = style.salvo_caption
		_caption.add_theme_font_size_override(&"font_size", style.salvo_caption_font_size)
		_caption.add_theme_color_override(&"font_color", style.colour(ROLE_TEXT_DIM))
		_caption.position = style.drawn_vector(style.salvo_caption_origin)
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
			var rect: Rect2 = style.drawn_rect(style.salvo_cell_rect(index))
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


	## The three cells' own text, `"073"` style, for a probe that wants the readout.
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
		var ledge := Rect2(
			style.drawn_vector(Vector2(4.0, style.ledge_offset)),
			style.drawn_vector(Vector2(size.x / style.art_scale - 8.0, 4.0))
		)
		draw_rect(ledge, style.colour(ROLE_METAL_DARK), true)
		draw_line(
			Vector2(ledge.position.x, ledge.end.y), ledge.end,
			style.colour(ROLE_METAL_LIGHT), style.drawn(style.frame_width), true
		)
		for index: int in _cells.size():
			var rect := Rect2(_cells[index].position, _cells[index].size)
			draw_rect(rect, style.colour(ROLE_VOID), true)


## One row's plate: a nine-slice of the brushed strip (flat bands only, section 3.10), with
## the section 3.1/3.1b danger frame code-drawn over it when the row is in a danger state.
class RowPlate extends Control:
	var style: Resource = null
	var _plate: NinePatchRect = null
	var _danger: bool = false


	func configure(new_style: Resource) -> void:
		style = new_style
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _plate == null:
			_plate = NinePatchRect.new()
			_plate.name = "Plate"
			_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_plate)
		_plate.texture = style.texture(style.row_plate_path)
		var sides: Array[float] = style.row_plate_sides()
		_plate.patch_margin_left = int(sides[0])
		_plate.patch_margin_top = int(sides[1])
		_plate.patch_margin_right = int(sides[2])
		_plate.patch_margin_bottom = int(sides[3])
		_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		queue_redraw()


	## The danger treatment: a 1 px (logical) code-drawn frame in `accent_danger` - the
	## digits themselves never recolour (section 3.7's own rule, reused here verbatim).
	func set_danger(danger: bool) -> void:
		if _danger == danger:
			return
		_danger = danger
		queue_redraw()


	func danger() -> bool:
		return _danger


	func plate_node() -> NinePatchRect:
		return _plate


	func _draw() -> void:
		if style == null or not _danger:
			return
		draw_rect(
			Rect2(Vector2.ZERO, size), style.colour(ROLE_DANGER), false,
			style.drawn(style.frame_width)
		)


@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _header: HBoxContainer = %ArmoryHeader
@onready var _scroll: ScrollContainer = %ArmoryScroll
@onready var _body: Control = %ArmoryBody
@onready var _plate: TextureRect = %ConsolePlate
@onready var _rows: VBoxContainer = %ArmoryRows
@onready var _rack_rows: VBoxContainer = %RackRows
@onready var _inventory_rows: VBoxContainer = %InventoryRows
@onready var _racks_margin: Control = %RacksMargin
@onready var _inventory_margin: Control = %InventoryMargin
@onready var _ammo_margin: Control = %AmmoMargin

## The style in force (`ArmoryStyle`, a `CockpitStyle`): every colour, metric and asset
## path on this surface comes from here (section 3.9 rule 5).
var _style: Resource = null
## The console's code-drawn wells and bay cards.
var _wells: ConsoleWells = null
## The twelve `ui_seg_*` cuts, shared by every bay's SALVO strip.
var _seg: Array[Texture2D] = []
var _seg_blank: Texture2D = null

var _payloads: Array[Dictionary] = []
## The rack chips and inventory rows the current frame drew, for the read-backs
## (`rack_rows()` / `inventory_rows()`) and for `focus_primary`'s walk. Both are
## rebuilt on every refresh: a rack's shape is player-composed, so it is not a fixed
## node set, and a freed chip is released with `queue_free` so the plate whose
## `_drop_data` started the write is still alive while that write finishes.
var _rack_views: Array[Dictionary] = []
var _inventory_views: Array[Dictionary] = []
## The header/rows pair (`{header, rows, cells, queued, retries}`) the fit pass drives.
## Built by `_connect_layout`, which runs before the row builder that fills it.
var _ammo_section: Dictionary = {}
var _sections: Array[Dictionary] = []
var _selected_row: Button = null
var _tweens: Array[Tween] = []
## The selected rack (0-based), the bay that wears the section 3.2 ember frame - the same
## rack ordinal the cluster's lamp lights. It follows focus and never writes anything.
var _selected_rack: int = 0


func _ready() -> void:
	_connect_layout()
	_build_header()
	_build_console()
	_build_rows()
	_build_racks()
	_build_inventory()
	_apply_tokens()
	_connect_scroll()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_queue_header_fit()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


## STATION_HUB section 12.4 plus 09 section 11: `&"credits"` moves every price and tag,
## `&"ammo"` and `&"cargo"` the held figures (an ammo purchase moves both), and the racks
## and the inventory follow `&"fits"` (the fit a rack's cells live in), `&"modules"` (the
## bag its `OWNED ×<n>` figure and every drag spend from), `&"ships"` (the active hull's W
## cells) and `&"batteries"` (a rack write's own signal).
func refresh_profile(key: StringName) -> void:
	if key == &"credits" or key == &"ammo" or key == &"cargo":
		_refresh_rows()
	if key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_racks()
	if key == &"modules" or key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_inventory()


## The focus order: the racks' barrels first (rack order, each chip's own plate), then
## the inventory rows - the pane's one action source - then the ammunition rows, then the
## pane's own footer and the rail (STATION_HUB section 10).
func focus_primary() -> void:
	for view: Dictionary in _rack_views:
		for barrel: Dictionary in view[&"barrels"]:
			var control := barrel[&"name"] as Button
			if control != null and control.visible and not control.disabled:
				control.grab_focus()
				return
	for view: Dictionary in _inventory_views:
		var row := view[&"row"] as Button
		if row != null and row.visible and not row.disabled:
			row.grab_focus()
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


## ------------------------------------------------------------------ the console


## Mount the painted plate and the console's own geometry: the block is the style's
## `canvas * art_scale` (Mockup A's own canvas, exactly half the shipped master), the three
## wells and the bay grid are the style's pinned rects, and the group boxes fill them.
func _build_console() -> void:
	if _style == null:
		_style = StyleScript.load_style()
	_seg.clear()
	for digit: int in 10:
		_seg.append(_style.texture(_style.seg_path(str(digit))))
	_seg_blank = _style.texture(_style.seg_path(_style.seg_blank_cell))
	_wells = ConsoleWells.new()
	_wells.name = "ConsoleWells"
	_wells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_wells)
	_body.move_child(_wells, 1)
	_rack_rows.sort_children.connect(_lay_bays)
	_rows.sort_children.connect(_lay_ammo)
	_ammo_margin.resized.connect(_lay_groups)
	_racks_margin.resized.connect(_lay_groups)
	_inventory_margin.resized.connect(_lay_groups)
	for box: Control in [_racks_margin, _inventory_margin, _ammo_margin]:
		for holder: Node in box.get_children():
			var stack := holder as Container
			if stack != null and stack.has_signal(&"sort_children"):
				stack.sort_children.connect(_position_group.bind(box))
	_apply_style()


## Re-read the style into every part of the console: the block, the plate, the wells, the
## group boxes and the bay grid. Called once at build and again on a restyle.
func _apply_style() -> void:
	if _style == null:
		return
	if _plate != null:
		_plate.texture = _style.texture(_style.console_path)
		_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_apply_tokens()
	_lay_groups()
	_lay_bays()
	_lay_ammo()


## The three group boxes, in the style's well order (racks, inventory, ammunition): each
## one carries its caption band above its well, and a group that outgrows its pinned well
## pushes the ones below it down (`group_rect`'s own arithmetic).
func _lay_groups() -> void:
	if _style == null or _racks_margin == null:
		return
	var heights := _group_content_heights()
	var offset := 0.0
	var boxes: Array[Control] = [_racks_margin, _inventory_margin, _ammo_margin]
	var regions: Array[Rect2] = []
	for index: int in boxes.size():
		var rect: Rect2 = _dr(_style.group_rect(index, heights[index], offset))
		boxes[index].position = rect.position
		boxes[index].size = rect.size
		_size_captions(boxes[index], rect.size.x)
		_position_group(boxes[index])
		regions.append(_dr(_style.drawn_well(index, heights[index], offset)))
		offset += _d(_style.growth(index, heights[index]))
	var bottom: float = boxes[boxes.size() - 1].position.y + boxes[boxes.size() - 1].size.y
	var block := Vector2(_style.block_size().x, bottom + _d(_style.block_foot))
	_body.custom_minimum_size = block
	_body.size = block
	if _wells != null:
		_wells.size = block
		_wells.configure(_style, regions, _bay_rects())


## Every group's caption occupies exactly the style's caption band, so the container that
## stacks caption-over-rows puts the rows at the well's own top edge (and the bay grid's
## offsets, which are measured from the well, land where the code-drawn recesses are).
func _size_captions(box: Control, width: float) -> void:
	var band: float = _d(_style.caption_band)
	for child: Node in box.get_children():
		var caption := child as Label
		if caption != null and not caption.name.begins_with("Armory"):
			caption.custom_minimum_size = Vector2(width, band)


## The rows container of one group, at the well's own inner origin: each group's box stacks
## its caption over its rows (`VBoxContainer`), so that stacking is corrected here on every
## sort - the rows start at the well's inset and the caption band, which is where the
## code-drawn wells and the bay grid measure from.
func _position_group(box: Control) -> void:
	if _style == null or box == null:
		return
	var inset: float = _d(_style.bay_origin.x)
	var band: float = _d(_style.caption_band)
	for holder: Node in box.get_children():
		var stack := holder as Control
		if stack == null:
			continue
		for child: Node in stack.get_children():
			var rows := child as Control
			if rows == null or rows is Label:
				continue
			rows.position = Vector2(inset, band)


## Each group's own content height, in logical units: the racks' bay grid, the inventory
## rows and the ammunition cards.
func _group_content_heights() -> Array[float]:
	var bays: float = _style.bay_grid_height(_rack_rows.get_child_count())
	var inventory: float = _style.rows_height(_inventory_views.size(), _style.inventory_row_height)
	var packs: int = _payloads.size()
	var columns: int = maxi(AMMO_COLUMNS, 1)
	var pack_rows: int = int(ceil(float(packs) / float(columns))) if packs > 0 else 0
	var ammo: float = _style.rows_height(pack_rows, _style.ammo_row_height)
	return [bays, inventory, ammo]


## The seven bays' rects, in the style's 4+3 grid (drawn pixels).
func _bay_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for index in _rack_views.size():
		out.append(_dr(_style.bay_rect(index)))
	return out


## Lay the rack bays out as Mockup A's 4+3 grid. The container is a `VBoxContainer` by the
## existing suites' own contract (`%RackRows` is cast to one and read by child index), so
## its own stacking is corrected here on every sort - the positions are exact before any
## layout pass, which is what lets a headless suite read them.
func _lay_bays() -> void:
	if _style == null or _rack_rows == null:
		return
	var cell: Vector2 = _style.drawn_vector(_style.bay_size)
	var columns: int = maxi(_style.bay_columns, 1)
	var gap: float = _d(_style.bay_gap)
	var index := 0
	for child: Node in _rack_rows.get_children():
		var control := child as Control
		if control == null:
			continue
		var column: int = index % columns
		var row: int = floori(float(index) / float(columns))
		control.position = Vector2(column * (cell.x + gap), row * (cell.y + gap))
		## The container's own minimum is the sum of its children's, so the bays declare
		## none of their own: their drawn rect is set outright (a VBox cannot stack a 4+3
		## grid, and a stacked minimum would grow the whole console).
		control.custom_minimum_size = Vector2.ONE
		control.size = cell
		index += 1
	var rows: int = _style.bay_row_count(index)
	_rack_rows.custom_minimum_size = Vector2(
		float(columns) * cell.x + float(maxi(columns - 1, 0)) * gap,
		float(rows) * cell.y + float(maxi(rows - 1, 0)) * gap
	)
	_rack_rows.size = _rack_rows.custom_minimum_size
	for child: Node in _rack_rows.get_children():
		var bay := child as Control
		if bay == null:
			continue
		_position_head(bay.get_node_or_null(^"Box/Head") as Container)
		_position_slots(bay.get_node_or_null(^"Box/Barrels") as Container)
		var salvo := bay.get_node_or_null(^"Box/Salvo") as Control
		if salvo != null:
			salvo.position = Vector2.ZERO
			salvo.size = cell
	if _wells != null:
		_wells.configure(_style, _wells.well_rects(), _bay_rects())


## Lay the ammunition cards out three across (Mockup A's own three boxes), correcting the
## container's own stacking the same way the rack grid does.
func _lay_ammo() -> void:
	if _style == null or _rows == null:
		return
	var cell := Vector2(
		(_d(_style.ammo_well.size.x) - float(maxi(AMMO_COLUMNS - 1, 0)) * _d(_style.row_gap))
			/ float(maxi(AMMO_COLUMNS, 1)),
		_d(_style.ammo_row_height)
	)
	var gap: float = _d(_style.row_gap)
	var index := 0
	for child: Node in _rows.get_children():
		var control := child as Control
		if control == null:
			continue
		var column: int = index % AMMO_COLUMNS
		var row: int = floori(float(index) / float(AMMO_COLUMNS))
		control.position = Vector2(column * (cell.x + gap), row * (cell.y + gap))
		control.custom_minimum_size = Vector2.ONE
		control.size = cell
		index += 1
	var rows: int = int(ceil(float(index) / float(maxi(AMMO_COLUMNS, 1))))
	_rows.custom_minimum_size = Vector2(
		float(AMMO_COLUMNS) * cell.x + float(maxi(AMMO_COLUMNS - 1, 0)) * gap,
		float(rows) * cell.y + float(maxi(rows - 1, 0)) * gap
	)
	_rows.size = _rows.custom_minimum_size


## A logical length in drawn pixels.
func _d(value: float) -> float:
	return _style.drawn(value) if _style != null else value


## A logical rect in drawn pixels.
func _dr(rect: Rect2) -> Rect2:
	return _style.drawn_rect(rect) if _style != null else rect


## ------------------------------------------------------------------ the token lookup


func _apply_tokens() -> void:
	for payload: Dictionary in _payloads:
		_apply_icon_token(payload)
	for view: Dictionary in _inventory_views:
		_apply_icon_token(view)


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


## ------------------------------------------------------------------ the ammo rows


func _build_header() -> void:
	_subtitle.text = SUBTITLE % [Catalog.AMMO_PACKS.size(), RACK_COUNT]
	_tag.text = TAG_LIST_PREFIX + TAG_LIST_SEPARATOR.join(_id_list())
	for cell: Dictionary in _header_cells():
		_header.add_child(_make_header_cell(cell))
	## Mockup A carries no column header: the ammunition cards state their own figures, so
	## the S5 column strip is kept for its contract and reads nothing.
	_header.visible = false


func _id_list() -> PackedStringArray:
	var ids := PackedStringArray()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		ids.append(String(pack.get(&"id", &"")))
	return ids


func _header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": HEADER_PACK, &"width": 0.0, &"expand": true},
		{&"text": HEADER_HELD, &"width": COL_HELD, &"expand": false},
		{&"text": HEADER_PRICE, &"width": COL_PRICE, &"expand": false},
		{&"text": HEADER_STATUS, &"width": COL_TAG, &"expand": false},
	]


func _make_header_cell(cell: Dictionary) -> Control:
	if String(cell[&"text"]).is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(float(cell[&"width"]), 0.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer
	var label := Label.new()
	label.theme_type_variation = &"SectionHeader"
	label.text = String(cell[&"text"])
	label.custom_minimum_size = Vector2(float(cell[&"width"]), 0.0)
	label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if bool(cell[&"expand"]) else Control.SIZE_FILL
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_rows() -> void:
	_payloads.clear()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		_payloads.append(_build_row(pack))
	_add_slack()
	_lay_ammo()


## One ammunition **card** (section 3.10's 32 px row, three across in the well): the pack's
## name, its rounds, its price, the hold's units and the state tag, on a brushed row plate.
## Every cell the S5 suites read is still built here - the Held cell's `Caption` carries the
## state line, the Price cell's the `CREDITS` caption, and the Status cell's tag.
func _build_row(pack: Dictionary) -> Dictionary:
	var pack_id: StringName = pack.get(&"id", &"")
	var name_text := String(pack.get(&"name", ""))
	var rounds := int(pack.get(&"rounds", 0))
	var cost := int(pack.get(&"cost", 0))
	var complete := pack_id != &"" and not name_text.is_empty() and rounds > 0
	var row := Button.new()
	row.name = "Ammo%s" % String(pack_id).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = not complete
	row.clip_contents = true
	var frame := RowPlate.new()
	frame.name = "RowPlate"
	row.add_child(frame)
	var box := _make_inner(row)
	var icon := _make_icon(String(pack.get(&"icon", "")), _d(32.0))
	if icon != null:
		box.add_child(icon)
	var left := VBoxContainer.new()
	left.name = "CardText"
	left.add_theme_constant_override(&"separation", CELL_SEPARATION)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(left)
	left.add_child(_make_title_box(
		name_text, ROUNDS_CAPTION % rounds, complete, AMMO_TITLE_FONT_SIZE,
		AMMO_META_FONT_SIZE
	))
	var tag := _make_cell(left, 0.0, "", "", "Status")
	(tag[1] as Label).visible = false
	var price := _make_cell(box, _d(AMMO_VALUE_COLUMN), "", PRICE_CAPTION, "Price")
	var held := _make_cell(box, 0.0, "", "", "Held")
	for cell: Array in [price, held]:
		cell[0].add_theme_font_size_override(&"font_size", AMMO_TITLE_FONT_SIZE)
		cell[1].add_theme_font_size_override(&"font_size", AMMO_META_FONT_SIZE)
	_connect_cells(box, _ammo_section)
	var payload := {
		&"id": pack_id,
		&"name": name_text,
		&"rounds": rounds,
		&"cost": cost,
		&"complete": complete,
		&"row": row,
		&"plate": frame,
		&"icon": icon,
		&"tinted": _is_flat_glyph(String(pack.get(&"icon", ""))),
		&"held": held[0],
		&"held_caption": held[1],
		&"price": price[0],
		&"price_caption": price[1],
		&"tag": tag[0],
	}
	if complete:
		row.pressed.connect(_on_row_pressed.bind(payload))
		row.focus_entered.connect(_on_row_focused.bind(row, payload))
		row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
		row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_rows.add_child(row)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.configure(_style)
	return payload


func _make_title_box(
	name_text: String, meta_text: String, complete: bool, title_size: float = 0.0,
	meta_size: float = 0.0
) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text if complete else TAG_UNAVAILABLE)
	title.name = "Title"
	if title_size > 0.0:
		title.add_theme_font_size_override(&"font_size", int(title_size))
	box.add_child(title)
	var meta := _make_label(&"StationCaption", meta_text if complete else META_INCOMPLETE)
	meta.name = "Meta"
	if meta_size > 0.0:
		meta.add_theme_font_size_override(&"font_size", int(meta_size))
	box.add_child(meta)
	return box


func _make_cell(
	parent: Container, width: float, value_text: String, caption_text: String, cell_name: String
) -> Array[Label]:
	var box := VBoxContainer.new()
	box.name = cell_name
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	parent.add_child(box)
	var value := _make_label(&"StationValue", value_text)
	value.name = "Value"
	box.add_child(value)
	var caption := _make_label(&"StationCaption", caption_text)
	caption.name = "Caption"
	box.add_child(caption)
	var out: Array[Label] = [value, caption]
	return out


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_inner(button: Button) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_top", ROW_INNER_MARGIN.y)
	inner.add_theme_constant_override(&"margin_right", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_bottom", ROW_INNER_MARGIN.y)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(icon_path: String, cell: float = COL_ICON) -> TextureRect:
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


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_child(slack)


func _connect_scroll() -> void:
	## The scroll cue has no other home: the station shell owns no list of its own.
	if _scroll.has_signal(&"scroll_started"):
		_scroll.connect(&"scroll_started", _on_scroll_started)


func _connect_layout() -> void:
	## A header cannot trust its declared column widths: a caption that outgrows its
	## column widens that cell, so any event that can move the rows' columns queues a
	## re-fit of that header onto its own rows' box.
	_sections.clear()
	_ammo_section = _make_section(_header, _rows, GRID_CELLS)
	_sections.append(_ammo_section)
	_scroll.resized.connect(_queue_header_fit)
	_scroll.get_v_scroll_bar().visibility_changed.connect(_queue_header_fit)
	for section: Dictionary in _sections:
		var header: HBoxContainer = section[&"header"]
		var ammo_rows: VBoxContainer = section[&"rows"]
		ammo_rows.resized.connect(_queue_section_fit.bind(section))
		header.resized.connect(_queue_section_fit.bind(section))


func _make_section(
	header: HBoxContainer, rows: VBoxContainer, cells: Array[StringName]
) -> Dictionary:
	return {
		&"header": header,
		&"rows": rows,
		&"cells": cells,
		&"queued": false,
		&"retries": 0,
	}


func _queue_header_fit() -> void:
	for section: Dictionary in _sections:
		_queue_section_fit(section)


func _queue_section_fit(section: Dictionary) -> void:
	if bool(section[&"queued"]):
		return
	section[&"queued"] = true
	_fit_section.call_deferred(section)


func _fit_section(section: Dictionary) -> void:
	## The header takes its box from the first row's grid and then takes each declared
	## column's width from the matching row cell, so a header caption's left edge is the
	## value label's left edge in every state. A panel built before its host has laid it out
	## re-queues a few frames and then leaves it to the layout signals above.
	section[&"queued"] = false
	var header: HBoxContainer = section[&"header"]
	var cells: Array[StringName] = section[&"cells"]
	var grid := _row_grid(section[&"rows"])
	if grid == null or grid.size.x <= 0.0 or size.x <= 0.0:
		if int(section[&"retries"]) < HEADER_FIT_RETRIES:
			section[&"retries"] = int(section[&"retries"]) + 1
			_queue_section_fit(section)
		return
	section[&"retries"] = 0
	var columns := mini(header.get_child_count(), cells.size())
	for index in columns:
		var head := header.get_child(index) as Control
		var cell := grid.get_node_or_null(NodePath(cells[index])) as Control
		if head == null or cell == null:
			continue
		if not is_equal_approx(
			head.custom_minimum_size.x, cell.get_combined_minimum_size().x
		):
			head.custom_minimum_size.x = cell.get_combined_minimum_size().x


func _row_grid(rows: VBoxContainer) -> HBoxContainer:
	for child: Node in rows.get_children():
		var row := child as Button
		if row == null:
			continue
		var inner := row.get_node_or_null(^"RowInner") as MarginContainer
		if inner == null:
			continue
		return inner.get_child(0) as HBoxContainer
	return null


func _connect_cells(box: HBoxContainer, section: Dictionary) -> void:
	var cells: Array[StringName] = section[&"cells"]
	for cell_name: StringName in cells:
		var cell := box.get_node_or_null(NodePath(cell_name)) as Control
		if cell != null:
			cell.resized.connect(_queue_section_fit.bind(section))


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	status_requested.emit(_row_hint(payload), false)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


func _on_row_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
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


func _refresh_rows() -> void:
	for payload: Dictionary in _payloads:
		_refresh_row(payload)
	_queue_header_fit()


## One ammunition row, in the S5 model (10 section 6.1): the purchase delivers **cargo
## units**, so `HELD` is the hold's own unit count for the family and `MAX` the unit
## equivalent of its advisory `ammo_max`. The four state lines follow the same two
## figures, so a row that has bought nothing yet reads EMPTY even while the magazine a
## previous launch loaded still holds rounds - which is exactly what the player is
## about to buy.
func _refresh_row(payload: Dictionary) -> void:
	var price: Label = payload[&"price"]
	var tag: Label = payload[&"tag"]
	var held: Label = payload[&"held"]
	var caption: Label = payload[&"held_caption"]
	if not bool(payload[&"complete"]):
		held.text = UNAVAILABLE_VALUE
		caption.text = META_INCOMPLETE
		tag.text = TAG_UNAVAILABLE
		price.text = ""
		price.remove_theme_color_override(&"font_color")
		_style_danger(payload, true)
		return
	var profile := _profile()
	var affordable := profile == null or bool(profile.call(&"can_afford", int(payload[&"cost"])))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(ROLE_DANGER))
	price.text = _format_int(int(payload[&"cost"]))
	var pack_id: StringName = payload[&"id"]
	var held_units := 0
	var capacity := 0
	if profile != null:
		held_units = int(profile.call(&"ammo_units", pack_id))
		capacity = _unit_cap(profile, pack_id)
	held.text = HELD_FORMAT % [held_units, capacity]
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


## The section 3.1/3.1b row treatment on one ammunition card: the code-drawn frame, and the
## state label in the danger role (its own text never recoloured by the load).
func _style_danger(payload: Dictionary, danger: bool) -> void:
	var plate: RowPlate = payload.get(&"plate", null)
	if plate != null:
		plate.set_danger(danger)
	var tag: Label = payload.get(&"tag", null)
	if tag == null:
		return
	if danger:
		tag.add_theme_color_override(&"font_color", _token(ROLE_DANGER))
	else:
		tag.remove_theme_color_override(&"font_color")


## The `MAX` figure of one ammunition row: the family's advisory `ammo_max` expressed in
## cargo units, rounded **up** like the purchase's own unit arithmetic
## (`PlayerProfile._ammo_units_for`), so a family whose ceiling is not a multiple of
## `ROUNDS_PER_CARGO_UNIT` still shows the smallest number of units that reaches it.
## Never 0: the caption would read `0 / 0` for a family the catalogue ships.
func _unit_cap(profile: ProfileScript, pack_id: StringName) -> int:
	var rounds := int(profile.call(&"ammo_max", pack_id))
	var per_unit := maxi(1, int(Catalog.ROUNDS_PER_CARGO_UNIT))
	return maxi(1, ceili(float(rounds) / float(per_unit)))


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## --------------------------------------------------------------------- the racks


func _build_racks() -> void:
	_refresh_racks()


func _build_inventory() -> void:
	_refresh_inventory()


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
## `battery_groups` derives them (`B1..B7`, in `weapon_1..7` order), each rack as a bay
## plate - `B<n>` and its key hint at the top, the four W-cell recesses, the engraved ledge
## and the SALVO strip with the rack's own cycle figure (seconds x 100, the slowest
## member's cycle: 09 section 11).
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
	_lay_bays()
	_lay_groups()


func _build_rack(rack: int, refs: Array, cells: Array) -> Dictionary:
	var row := RackRow.new()
	row.name = "Rack%d" % (rack + 1)
	row.armory = self
	row.rack = rack
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.clip_contents = false
	var box := PanelContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var plate := TextureRect.new()
	plate.name = "BayPlate"
	plate.texture = _style.texture(_style.rack_plate_path) if _style != null else null
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(plate)
	var marks := BayMarks.new()
	marks.name = "BayMarks"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(marks)
	var head := HBoxContainer.new()
	head.name = "Head"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.add_child(head)
	var label := _make_label(&"SectionHeader", RACK_LABEL % (rack + 1))
	label.name = "Label"
	label.custom_minimum_size = Vector2(RACK_LABEL_WIDTH, 0.0)
	label.add_theme_font_size_override(&"font_size", 14)
	head.add_child(label)
	var key := _make_label(&"StationCaption", RACK_KEY % (rack + 1))
	key.name = "Key"
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.add_theme_font_size_override(&"font_size", 11)
	head.add_child(key)
	var state := _make_label(&"StationCaption", "")
	state.name = "State"
	state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(state)
	var hint := _make_label(&"StationCaption", RACK_INSTALL_CUE)
	hint.name = "Hint"
	## The cue lives over the empty slot row: one clipped 9 px line inside a 194 px bay, so
	## it never grows the bay's own minimum height (an autowrap label's minimum size is its
	## height at one character per line - measured at 669 px here, which pushed the bay to
	## 673 and the whole strip with it).
	hint.clip_text = true
	hint.add_theme_font_size_override(&"font_size", 9)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(hint)
	var barrels := HBoxContainer.new()
	barrels.name = "Barrels"
	barrels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barrels.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.add_child(barrels)
	var strip := SalvoStrip.new()
	strip.name = "Salvo"
	box.add_child(strip)
	var views: Array[Dictionary] = []
	for index in refs.size():
		views.append(_build_barrel(rack, index, int(refs[index]), cells, barrels))
	var cycle := _rack_cycle(refs, cells)
	state.text = RACK_SALVO % cycle if cycle > 0.0 else RACK_READY
	state.visible = not refs.is_empty()
	## The head's own state line is the S5 contract (the suites read its text and its
	## visibility) while Mockup A's SALVO strip is the visible readout: its ink is
	## transparent, so the bay shows one cadence, not two.
	state.modulate.a = 0.0
	hint.visible = refs.is_empty()
	_rack_rows.add_child(row)
	if not head.sort_children.is_connected(_position_head.bind(head)):
		head.sort_children.connect(_position_head.bind(head))
	if not barrels.sort_children.is_connected(_position_slots.bind(barrels)):
		barrels.sort_children.connect(_position_slots.bind(barrels))
	_position_head(head)
	_position_slots(barrels)
	var view := {
		&"rack": rack,
		&"row": row,
		&"label": label.text,
		&"state": state,
		&"hint": hint,
		&"barrels": views,
		&"cells": _rack_cell_list(refs),
		&"marks": marks,
		&"strip": strip,
		&"figure": _salvo_figure(cycle),
	}
	_style_bay(view)
	return view


## One barrel chip: the drag source (the name plate) and the `x` that returns the barrel
## to the inventory. Both bind the barrel's **address** (rack, slot) as the rack stands
## now, because the whole rack is redrawn by the next profile change. Mockup A draws a
## fitted cell as the machined block in its slot, so the chips ride the slot recesses and
## their names stay readable through the read-back and the drag data.
func _build_barrel(
	rack: int, slot: int, cell: int, cells: Array, parent: HBoxContainer
) -> Dictionary:
	var chip := BarrelCell.new()
	chip.name = "Barrel%d" % (slot + 1)
	chip.armory = self
	chip.rack = rack
	chip.slot = slot
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.add_theme_constant_override(&"separation", CELL_SEPARATION)
	var entry := StringName(String(cells[cell])) if cell >= 0 and cell < cells.size() else &""
	var name_button := BarrelName.new()
	name_button.name = "Name"
	name_button.armory = self
	name_button.rack = rack
	name_button.slot = slot
	name_button.theme_type_variation = &"StationButton"
	name_button.focus_mode = Control.FOCUS_ALL
	name_button.text = BARREL_TEXT % [cell + 1, _module_name(_base_id(_profile(), entry))]
	name_button.custom_minimum_size = Vector2.ZERO
	name_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	name_button.tooltip_text = name_button.text
	name_button.add_theme_color_override(&"font_color", Color(0, 0, 0, 0))
	name_button.add_theme_font_size_override(&"font_size", 11)
	chip.add_child(name_button)
	var close := Button.new()
	close.name = "Close"
	close.theme_type_variation = &"StationButton"
	close.focus_mode = Control.FOCUS_ALL
	close.text = BARREL_CLOSE
	close.clip_text = true
	close.custom_minimum_size = Vector2.ZERO
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.add_theme_font_size_override(&"font_size", 11)
	close.pressed.connect(_on_remove_barrel.bind(rack, slot))
	chip.add_child(close)
	chip.clip_contents = true
	parent.add_child(chip)
	name_button.focus_entered.connect(_on_barrel_focused.bind(rack))
	return {&"cell": cell, &"name": name_button, &"close": close}


## Focus on a barrel makes its rack the selected bay (the section 3.2 ember frame).
func _on_barrel_focused(rack: int) -> void:
	set_selected_rack(rack)


## One bay's own children, at the mockup's own offsets: `B<n>` and its key hint along the
## top, the drop cue over the empty slot row, and the `x` in its slot's corner. The bay's
## containers are `HBoxContainer`s by the existing suites' contract (they read `Head`'s
## labels and `Barrels`' chips by name), so their own row layout is corrected here on every
## sort - the positions are exact before any layout pass, which is what lets a headless
## suite read them.
func _position_head(head: Container) -> void:
	if _style == null or head == null:
		return
	var cell: Vector2 = _style.drawn_vector(_style.bay_size)
	var label := head.get_node_or_null(^"Label") as Control
	if label != null:
		label.position = Vector2(_d(10.0), _d(4.0))
		label.size = Vector2(_d(40.0), _d(24.0))
	var key := head.get_node_or_null(^"Key") as Control
	if key != null:
		key.position = Vector2(cell.x - _d(44.0), _d(4.0))
		key.size = Vector2(_d(36.0), _d(24.0))
	var hint := head.get_node_or_null(^"Hint") as Control
	if hint != null:
		hint.position = Vector2(_d(10.0), _d(20.0))
		hint.size = Vector2(cell.x - _d(20.0), _d(44.0))
	var state := head.get_node_or_null(^"State") as Control
	if state != null:
		state.position = Vector2(_d(10.0), _d(20.0))
		state.size = Vector2(cell.x - _d(20.0), _d(16.0))


## One bay's barrel chips, each inside its own machined W-cell recess, with the `x` in the
## slot's corner (the name's own ink is transparent: the block inside the recess is what
## Mockup A draws for a fitted cell).
func _position_slots(barrels: Container) -> void:
	if _style == null or barrels == null:
		return
	var index := 0
	for child: Node in barrels.get_children():
		var chip := child as Control
		if chip == null:
			continue
		var slot: Rect2 = _dr(_style.slot_rect(index))
		chip.position = slot.position
		chip.size = slot.size
		var name_button := chip.get_node_or_null(^"Name") as Control
		if name_button != null:
			name_button.position = Vector2.ZERO
			name_button.size = Vector2(slot.size.x, slot.size.y - _d(14.0))
		var close := chip.get_node_or_null(^"Close") as Control
		if close != null:
			close.position = Vector2(slot.size.x - _d(14.0), 0.0)
			close.size = Vector2(_d(14.0), _d(14.0))
		index += 1


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
func _rack_cycle(refs: Array, cells: Array) -> float:
	var cycle := 0.0
	for ref: Variant in refs:
		var cell := int(ref)
		if cell < 0 or cell >= cells.size():
			continue
		var family := WeaponComponent.weapon_id(StringName(String(cells[cell])))
		if family == &"":
			continue
		cycle = maxf(cycle, WeaponComponent.interval_of(family))
	return cycle


## The approved figure (Mockup A: `073` = 0.73 s): the cycle in **hundredths** of a second,
## three cells, zero-padded. 0 s has no figure and reads blanks.
func _salvo_figure(cycle: float) -> int:
	if cycle <= 0.0:
		return -1
	return clampi(int(round(cycle * 100.0)), 0, SALVO_MAX)


## One bay's own marks and its SALVO strip: the fitted cells' blocks, the ember frame when
## the bay is selected, and the cycle figure.
func _style_bay(view: Dictionary) -> void:
	var marks: BayMarks = view.get(&"marks", null)
	if marks != null:
		var filled: Array[int] = []
		for ref: Variant in view[&"cells"]:
			filled.append(int(ref))
		marks.configure(_style, filled, int(view[&"rack"]) == _selected_rack)
	var strip: SalvoStrip = view.get(&"strip", null)
	if strip != null:
		strip.configure(_style, _seg, _seg_blank)
		strip.set_figure(int(view[&"figure"]))


## The inventory: one row per owned weapon id, in catalogue order, each one a drag
## source. `OWNED ×n` is `PlayerProfile.instances_of(base_id)` - the number of cells one
## install can pair - which is the same figure S4's strip showed.
func _refresh_inventory() -> void:
	_clear(_inventory_rows)
	_inventory_views.clear()
	var rows := inventory_rows()
	if rows.is_empty():
		var empty := _make_label(&"StationCaption", INVENTORY_EMPTY)
		empty.name = "Empty"
		empty.add_theme_font_size_override(&"font_size", 12)
		_inventory_rows.add_child(empty)
		_lay_groups()
		return
	for entry: Dictionary in rows:
		_build_inventory_row(entry)
	_lay_groups()


func _build_inventory_row(entry: Dictionary) -> Dictionary:
	var base_id: StringName = entry[&"base"]
	var row := InventoryRow.new()
	row.name = "Owned%s" % String(base_id).to_pascal_case()
	row.armory = self
	row.base_id = base_id
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, _d(_style.inventory_row_height))
	row.size = Vector2(_d(_style.inventory_well.size.x), _d(_style.inventory_row_height))
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var frame := RowPlate.new()
	frame.name = "RowPlate"
	row.add_child(frame)
	var box := _make_inner(row)
	var icon_path := ModuleData.icon_path(base_id)
	var icon := _make_icon(icon_path, _d(_style.inventory_icon.x))
	if icon != null:
		icon.custom_minimum_size = _style.drawn_vector(_style.inventory_icon)
		box.add_child(icon)
	var name_label := _make_label(&"StationValue", String(entry[&"name"]))
	name_label.name = "Name"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override(&"font_size", INVENTORY_NAME_FONT_SIZE)
	box.add_child(name_label)
	var cell := _make_cell(box, 0.0, INVENTORY_TEXT % ["OWNED", int(entry[&"owned"])], "", "Status")
	cell[0].add_theme_font_size_override(&"font_size", INVENTORY_TAG_FONT_SIZE)
	cell[1].visible = false
	cell[0].size_flags_horizontal = Control.SIZE_SHRINK_END
	var view := {
		&"base": base_id,
		&"name": String(entry[&"name"]),
		&"owned": int(entry[&"owned"]),
		&"draw": int(entry[&"draw"]),
		&"row": row,
		&"plate": frame,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"status": cell[0],
	}
	_inventory_rows.add_child(row)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.configure(_style)
	_inventory_views.append(view)
	return view


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


## Every drawn rack as `{rack, label, state, hint, barrels, cells, figure}` - `barrels` is
## one `{cell, name, close}` per barrel chip and `cells` the rack's W-cell indices in its
## own order. Probes and suites read the racks through this rather than walking the tree.
func rack_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for view: Dictionary in _rack_views:
		var barrels: Array = []
		for barrel: Dictionary in view[&"barrels"]:
			barrels.append({
				&"cell": int(barrel[&"cell"]),
				&"text": (barrel[&"name"] as Button).text,
			})
		rows.append({
			&"rack": int(view[&"rack"]),
			&"label": String(view[&"label"]),
			&"state": (view[&"state"] as Label).text,
			&"cells": view[&"cells"],
			&"barrels": barrels,
			&"figure": int(view[&"figure"]),
		})
	return rows


## One bay's SALVO readout as the pane drew it: the strip's three cells (`-1` = blank) and
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


## One bay's code-drawn marks (the fitted cells' blocks and the selected frame).
func bay_marks(rack: int) -> BayMarks:
	if rack < 0 or rack >= _rack_views.size():
		return null
	return _rack_views[rack][&"marks"]


## Every bay's rect as drawn (the section 3.10 4+3 grid, in the console's own space).
func bay_rects() -> Array[Rect2]:
	return _bay_rects()


## The three wells as drawn (the section 3.10 Mockup A rects).
func well_rects() -> Array[Rect2]:
	return _wells.well_rects() if _wells != null else []


## The console block's own size as drawn.
func block_size() -> Vector2:
	return _body.custom_minimum_size


## The inventory rows as drawn, in order, `{base, name, owned, draw, text}`.
func inventory_view_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for view: Dictionary in _inventory_views:
		rows.append({
			&"base": view[&"base"],
			&"name": view[&"name"],
			&"owned": int(view[&"owned"]),
			&"draw": int(view[&"draw"]),
			&"text": (view[&"status"] as Label).text,
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


## ------------------------------------------------------------------ the rack actions


## Install one inventory weapon into one rack's next free W cell (09 section 11): the
## profile's composed `fit_into_rack`, which pairs the next in-bag instance of the base
## into the cell and records the cell in the rack, atomically over the fit, the bag and
## the record. Refused, writing nothing, when the rack is outside `B1..B7`, the bag holds
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
## address that holds no barrel, a target rack outside `B1..B7`, or the same address.
func move_barrel(
	from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	if not _can_move(hull, from_rack, from_position, to_rack, to_position):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	if not bool(
		profile.call(&"move_rack_cell", hull, from_rack, from_position, to_rack, to_position)
	):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	status_requested.emit(
		STATUS_MOVED % [
			_rack_barrel_name(profile, from_rack, from_position), RACK_LABEL % (to_rack + 1)
		],
		false
	)
	return true


## The `x`: the barrel returns to the inventory and its cell is emptied
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
## rack must be inside `B1..B7`, the target slot must not be negative and the two addresses
## must differ. Pure reads - a move writes no fit, so there is nothing else to judge.
func _can_move(
	hull: StringName, from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	if hull == &"" or to_rack < 0 or to_rack >= RACK_COUNT or to_position < 0:
		return false
	if from_rack == to_rack and from_position == to_position:
		return false
	return _rack_cell_at(from_rack, from_position) >= 0


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
	_refresh_inventory()


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
