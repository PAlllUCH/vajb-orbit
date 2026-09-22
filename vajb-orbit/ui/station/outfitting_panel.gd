extends VBoxContainer
## OUTFITTING module panel: the FITTED WEAPONS strip and the MODULES section (the six
## weapon modules of 09 section 3.1 plus 09 section 4 item 7's mining laser, the seventh
## weapon slot id) above one row per StationCatalog.AMMO_PACKS entry,
## held and capped from PlayerProfile. Contract: docs/design/STATION_HUB.md sections 5.1,
## 5.6, 10 and 12, docs/design/STATION_SPEC.md sections 2.3 and 6, docs/CONTRACTS.md
## section 12 and docs/gameplay/09_ship_slots_modules.md sections 1, 2, 3.1, 4 and 9.
##
## The station shell loads this scene into its host, so the panel never routes, never
## writes the profile and never draws the credits readout: it emits status_requested up
## and reads StationCatalog / PlayerProfile / ModuleCatalog / ShipFit down. Every later
## module panel copies this shape (STATION_HUB section 12.4).
##
## The MODULES section is a request surface, never a store (STATION_HUB section 12.4,
## CONTRACTS section 12 rule 2): BUY is `PlayerProfile.buy_module` with the catalogue's
## own price, INSTALL and SWAP are `set_fit_slot` behind `ShipFit.fit_legal`, and REMOVE
## is `set_fit_slot(..., "")` plus `add_module`. Every fit write is preceded by
## `_seed_fit`, because a hull the account holds no fit for would otherwise be
## materialised from nothing and lose 09 section 7's mandatory set. A refused fit writes
## nothing and renders in the footer strip the panel owns (`status_requested`), never a
## dialog, and nothing auto-removes (09 section 2, CONTRACTS section 12 rule 3).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

const ROW_HEIGHT := 76.0
const COL_ICON := 40.0
const COL_HELD := 130.0
const COL_PRICE := 110.0
const COL_TAG := 160.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
## Fix Wave 1 W2.2: _header_cells() and a row's own grid declare the same five columns in
## the same order, so the header can be re-fitted from a live row instead of repeating the
## declared widths (see _fit_header).
const GRID_CELLS: Array[StringName] = [&"Icon", &"TitleBox", &"Held", &"Price", &"Status"]
## The MODULES rows' own grid, in their own column order (STATION_HUB section 5.1's
## amendment): the same Icon/TitleBox/Price/Status cells plus the effect text and the
## ACTION word, so one `_fit_section` pass fits both headers.
const MODULE_GRID_CELLS: Array[StringName] = [
	&"Icon", &"TitleBox", &"Effect", &"Price", &"Status", &"Action"
]
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
const SUBTITLE := "AMMUNITION AND CONSUMABLES · %d PACKS IN THE CATALOGUE"
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
const STATUS_BOUGHT := "PURCHASED · %s · +%d ROUNDS"

## --------------------------------------------------------------- modules (P2-B1)
## The MODULES section and the FITTED WEAPONS strip (STATION_HUB section 5.1's
## amendment, transcribed from the wave brief's section 3; every number below is 09
## section 3.1's or 09 section 9's).

## 09 section 3.1's WEAPONS table, in its own row order, plus 09 section 4 item 7's mining
## laser as its seventh row: every weapon-slot id the catalogue ships has a row here, which
## is what gives `w_mining` a door (P2-B1 F1, R1's MED-2). `w_mining` has no section 3.1 row
## of its own; its tier, draw and 600 CR cost are 09 section 4 item 7's.
const MODULE_ROWS: Array[StringName] = [
	&"w_laser",
	&"w_cannon",
	&"w_rocket",
	&"w_mine",
	&"w_plasma",
	&"w_railgun",
	&"w_mining",
]

## 09 section 3.1's Effect column, verbatim, plus 09 section 4 item 7's mining laser, whose
## words are 09 section 3.1's own family / shield-rule note (family tool, shield rule rocks
## only) and item 7's W slot sentence: the catalogue carries the ids, the slot, the draw and
## the cost, and this prose lives only in the document, so it is transcribed here and
## `tests/test_p2b1_outfitting_panel.gd` parses the table back out of
## docs/gameplay/09_ship_slots_modules.md and compares, so the two cannot drift.
const EFFECT_TEXT: Dictionary = {
	&"w_laser": "laser hardpoint, 30 DPS, uses Laser Cells",
	&"w_cannon": "kinetic hardpoint, 45 DPS burst, Cannon Shells",
	&"w_rocket": "rocket pod, high alpha, Rocket rounds",
	&"w_mine": "mine layer, area denial, Mine Rack",
	&"w_plasma": "plasma lance, 70 DPS, melts armour, Plasma Cells",
	&"w_railgun": "railgun, 60 DPS",
	&"w_mining": "mining laser, tool family, rocks only; occupies a W slot",
}

const WEAPON_SLOT: StringName = &"weapons"
const COL_MODULE_ICON := 48.0
const COL_EFFECT := 300.0
const COL_ACTION := 160.0
const STRIP_LINE_HEIGHT := 48.0
## The row the strip's REMOVE plate takes its width from, so the strip's control column
## and the rows' ACTION column are one column.
const STRIP_REMOVE := "REMOVE"
## 09 section 4 item 5's layout index of the cell a SWAP displaces: the wave's INSTALL
## targets the first empty W cell (brief section 7 item 3, no slot picker in this wave),
## so SWAP takes the same first cell rather than a second rule.
const SWAP_INDEX := 0

const HEADER_MODULE := "MODULE"
const HEADER_EFFECT := "EFFECT"
const HEADER_ACTION := "ACTION"
const META_DRAW := "W SLOT · DRAW %d"

## STATION_HUB section 5.1's four STATUS states and four ACTION states.
const STATUS_FITTED := "FITTED (W%d)"
const STATUS_OWNED := "OWNED ×%d"
const STATUS_FOR_SALE := "FOR SALE"
const STATUS_LOCKED := "LOCKED"
const ACTION_BUY: StringName = &"BUY"
const ACTION_INSTALL: StringName = &"INSTALL"
const ACTION_SWAP: StringName = &"SWAP"
const ACTION_REMOVE: StringName = &"REMOVE"

## The strip's two line shapes, verbatim from STATION_HUB section 5.1 (`W1 LASER MKII` /
## `W2 — EMPTY`).
const STRIP_LINE := "W%d %s"
const STRIP_EMPTY := "— EMPTY"

## STATION_HUB section 5.1's two refusal wordings (owner tick 2 of the wave brief). The
## overload line is 09 section 2's own over-by format: the sum of the candidate fit's
## non-engine draws, the hull's output plus its power module, and the difference.
const REFUSAL_OVERLOAD := "%d / %d PWR — OVER BY %d"
const REFUSAL_SLOTS_FULL := "W SLOTS FULL — SWAP OR REMOVE FIRST"
## Unreachable from this surface's own writes (a W cell is written in place, the mandatory
## set is untouched and 09 section 4 item 4 guards engines and computers, not weapons), so
## it is the guard for a fit that arrived already illegal rather than a fifth state.
const REFUSAL_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"

const STATUS_MODULE_HINT := "ENTER %s · %s · %s CREDITS"
const STATUS_MODULE_BOUGHT := "PURCHASED · %s · %s CREDITS"
const STATUS_INSTALLED := "INSTALLED · %s · W%d"
const STATUS_SWAPPED := "SWAPPED · %s · %s BACK IN INVENTORY"
const STATUS_REMOVED := "REMOVED · %s · BACK IN INVENTORY"

## Audit anomaly C16: these three catalogue icons are flat Phase B glyphs (mean RGB about
## 40, 44, 47) that read as near-black shapes on the row chrome, so the row draws the
## derived icons/tint/ stencil moderated with Tokens/text_primary instead. Every other
## catalogue icon is painted and is drawn at full colour.
const FLAT_GLYPH_ICONS: Array[String] = [
	"res://assets/icons/weapon/icon_weapon_cannon_48.png",
	"res://assets/icons/weapon/icon_weapon_mine_48.png",
	"res://assets/icons/weapon/icon_weapon_plasma_48.png",
]
const TINT_DIR := "res://assets/icons/tint/"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _header: HBoxContainer = %OutfittingHeader
@onready var _scroll: ScrollContainer = %OutfittingScroll
@onready var _rows: VBoxContainer = %OutfittingRows
@onready var _strip: VBoxContainer = %FittedStrip
@onready var _module_header: HBoxContainer = %ModulesHeader
@onready var _module_rows: VBoxContainer = %ModuleRows

var _payloads: Array[Dictionary] = []
var _module_payloads: Array[Dictionary] = []
var _strip_lines: Array[Dictionary] = []
## The two header/rows pairs (`{header, margin, rows, cells, queued, retries}`), so the
## ammo header and the module header are fitted by the same pass instead of two copies of
## it. Built by `_connect_layout`, which runs before the row builders that fill them.
var _ammo_section: Dictionary = {}
var _module_section: Dictionary = {}
var _sections: Array[Dictionary] = []
var _selected_row: Button = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	_connect_layout()
	_build_header()
	_build_rows()
	_build_module_header()
	_build_module_rows()
	_build_strip()
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


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4 plus the wave brief's section 3: &"credits" moves every
	## price and tag, &"ammo" the held counts, &"fits" the fitted strip and every module
	## state, &"modules" the inventory side of the same, and &"ships" the active hull both
	## of them are read from (a hull switch changes the strip's cell count). Every other
	## key belongs to another panel. Nothing here rebuilds a node: the profile emits
	## mid-handler and the row whose press started it is still on the stack.
	if key == &"credits" or key == &"modules" or key == &"fits" or key == &"ships":
		_refresh_module_rows()
	if key == &"fits" or key == &"ships":
		_refresh_strip()
	if key == &"credits" or key == &"ammo":
		_refresh_rows()


func focus_primary() -> void:
	## STATION_HUB section 5.1's focus order: the fitted strip first, then the module rows,
	## then the ammo rows.
	for line: Dictionary in _strip_lines:
		var remove: Button = line[&"remove"]
		if remove.visible and not remove.disabled:
			remove.grab_focus()
			return
	for payload: Dictionary in _module_payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return


func _apply_tokens() -> void:
	for payload: Dictionary in _payloads:
		_apply_icon_token(payload)
	for payload: Dictionary in _module_payloads:
		_apply_icon_token(payload)


func _apply_icon_token(payload: Dictionary) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon != null and bool(payload[&"tinted"]):
		var tint: Color = _token(&"text_primary")
		tint.a = ROW_ICON_IDLE_ALPHA
		icon.modulate = tint


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_header() -> void:
	_subtitle.text = SUBTITLE % Catalog.AMMO_PACKS.size()
	_tag.text = TAG_LIST_PREFIX + TAG_LIST_SEPARATOR.join(_id_list())
	for cell: Dictionary in _header_cells():
		_header.add_child(_make_header_cell(cell))


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
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = not complete
	var box := _make_inner(row)
	var icon := _make_icon(String(pack.get(&"icon", "")))
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, ROUNDS_CAPTION % rounds, complete))
	var held := _make_cell(box, COL_HELD, "", "", "Held")
	var price := _make_cell(box, COL_PRICE, "", PRICE_CAPTION, "Price")
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	_connect_cells(box, _ammo_section)
	var payload := {
		&"id": pack_id,
		&"name": name_text,
		&"rounds": rounds,
		&"cost": cost,
		&"complete": complete,
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(String(pack.get(&"icon", ""))),
		&"held": held[0],
		&"held_caption": held[1],
		&"price": price[0],
		&"tag": tag[0],
	}
	if complete:
		row.pressed.connect(_on_row_pressed.bind(payload))
		row.focus_entered.connect(_on_row_focused.bind(row, payload))
		row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
		row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_rows.add_child(row)
	return payload


func _make_title_box(name_text: String, meta_text: String, complete: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text if complete else TAG_UNAVAILABLE)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(&"StationCaption", meta_text if complete else META_INCOMPLETE)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _make_cell(parent: HBoxContainer, width: float, value_text: String, caption_text: String, cell_name: String) -> Array[Label]:
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
	var base := _token(&"text_primary") if tinted else Color.WHITE
	base.a = ROW_ICON_IDLE_ALPHA
	icon.modulate = base
	return icon


func _is_flat_glyph(icon_path: String) -> bool:
	return FLAT_GLYPH_ICONS.has(icon_path)


func _icon_source(icon_path: String) -> String:
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
	## Fix Wave 1 W2.2, kept for both column headers. A header cannot trust its declared
	## column widths: a caption that outgrows its column (HELD / MAX over capacity is 143 px
	## against the declared 130) widens that cell, so any event that can move the rows'
	## columns queues a re-fit of that header onto its own rows' box.
	##
	## The margins are the scene's own 12 px and are no longer measured: both headers now sit
	## in the scrolling body directly above their own rows, so the header's MarginContainer
	## and the rows' `RowInner` have the same left and right inset by construction. Measuring
	## them would feed the margin back into the body's minimum width and with it the rows'
	## box, which is a growth loop rather than a fit (measured: 927 -> 939 -> 951 px per
	## pass with a measured trailing margin).
	_sections.clear()
	_ammo_section = _make_section(_header, _rows, GRID_CELLS)
	_module_section = _make_section(_module_header, _module_rows, MODULE_GRID_CELLS)
	_sections.append(_ammo_section)
	_sections.append(_module_section)
	_scroll.resized.connect(_queue_header_fit)
	_scroll.get_v_scroll_bar().visibility_changed.connect(_queue_header_fit)
	for section: Dictionary in _sections:
		var header: HBoxContainer = section[&"header"]
		var rows: VBoxContainer = section[&"rows"]
		rows.resized.connect(_queue_section_fit.bind(section))
		## The header is its own layout: a fitted cell that changed the header's own size
		## must settle it once more, and the fit is idempotent, so this converges in one pass.
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
		## The cell's own minimum, not its laid-out width: a minimum is content driven and
		## settles in the same frame, so the header cannot be fitted from a grid that is
		## halfway through its own re-sort (the declared widths stay the floor through the
		## cell's own custom_minimum_size and the expand cell takes the remainder twice).
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
	## A cell that outgrows its declared column (the HELD caption over capacity is 143 px
	## against the declared 130) resizes itself, so that header is re-fitted from whichever
	## cell changed shape, whatever wrote its text.
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
		## purchase_failed; the row only marks its own price cell (section 5.6).
		_pulse(payload[&"price"] as Label)
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_BOUGHT % [String(payload[&"name"]).to_upper(), int(payload[&"rounds"])], false
	)


func _refresh_rows() -> void:
	for payload: Dictionary in _payloads:
		_refresh_row(payload)
	_queue_header_fit()


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
		return
	var profile := _profile()
	var affordable := profile == null or bool(profile.call(&"can_afford", int(payload[&"cost"])))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	price.text = _format_int(int(payload[&"cost"]))
	var pack_id: StringName = payload[&"id"]
	var held_rounds := 0
	var capacity := 0
	if profile != null:
		held_rounds = int(profile.call(&"ammo_of", pack_id))
		capacity = int(profile.call(&"ammo_max", pack_id))
	held.text = HELD_FORMAT % [held_rounds, capacity]
	if held_rounds <= 0:
		tag.text = TAG_EMPTY
		caption.text = META_NO_ROUNDS
	elif held_rounds > capacity:
		tag.text = TAG_OVER_CAP
		caption.text = META_ADVISORY
	elif held_rounds == capacity:
		tag.text = TAG_AT_CAP
		caption.text = META_NO_CAP
	else:
		tag.text = TAG_IN_STOCK
		caption.text = META_BELOW_CAPACITY


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## ------------------------------------------------------------------ the strip


func _build_strip() -> void:
	## One line per W cell of the widest hull the game ships, so a hull switch changes which
	## lines are shown rather than the node set: the profile emits profile_changed from
	## inside the handler that started it, and a rebuild there would free the REMOVE plate
	## whose press is still on the stack.
	_strip_lines.clear()
	for index in _max_weapon_cells():
		var line := HBoxContainer.new()
		line.name = "W%d" % (index + 1)
		line.custom_minimum_size = Vector2(0.0, STRIP_LINE_HEIGHT)
		line.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
		var text := _make_label(&"StationValue", "")
		text.name = "Text"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(text)
		var remove := Button.new()
		remove.name = "Remove"
		remove.theme_type_variation = &"StationButton"
		remove.focus_mode = Control.FOCUS_ALL
		remove.text = STRIP_REMOVE
		remove.custom_minimum_size = Vector2(COL_ACTION, STRIP_LINE_HEIGHT)
		remove.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		remove.pressed.connect(_on_strip_remove.bind(index))
		line.add_child(remove)
		_strip.add_child(line)
		_strip_lines.append({&"index": index, &"line": line, &"text": text, &"remove": remove})


## The widest W grid of the nine player hulls, read from 08 section 3.2's matrices through
## `ShipFit` rather than from 09 section 1's "1-7, per class" as a literal.
static func _max_weapon_cells() -> int:
	var most := 0
	for hull: StringName in ShipFit.HULLS:
		most = maxi(most, ShipFit.slot_capacity(hull, WEAPON_SLOT))
	return most


func _refresh_strip() -> void:
	var profile := _profile()
	var cells := _weapon_cells(profile)
	for line: Dictionary in _strip_lines:
		var index := int(line[&"index"])
		var text: Label = line[&"text"]
		var remove: Button = line[&"remove"]
		var shown := index < cells.size()
		(line[&"line"] as Control).visible = shown
		if not shown:
			remove.visible = false
			remove.disabled = true
			continue
		var module_id := _base_id(profile, StringName(cells[index]))
		## Every *fitted* line carries REMOVE; an empty cell is a read-only line
		## (STATION_HUB section 5.1).
		remove.visible = module_id != &""
		remove.disabled = module_id == &""
		if module_id == &"":
			text.text = STRIP_LINE % [index + 1, STRIP_EMPTY]
		else:
			text.text = STRIP_LINE % [index + 1, _module_name(module_id)]


## ------------------------------------------------------------------ the modules


func _build_module_header() -> void:
	for cell: Dictionary in _module_header_cells():
		_module_header.add_child(_make_header_cell(cell))


func _module_header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_MODULE_ICON, &"expand": false},
		{&"text": HEADER_MODULE, &"width": 0.0, &"expand": true},
		{&"text": HEADER_EFFECT, &"width": COL_EFFECT, &"expand": false},
		{&"text": HEADER_PRICE, &"width": COL_PRICE, &"expand": false},
		{&"text": HEADER_STATUS, &"width": COL_TAG, &"expand": false},
		{&"text": HEADER_ACTION, &"width": COL_ACTION, &"expand": false},
	]


func _build_module_rows() -> void:
	_module_payloads.clear()
	for module_id: StringName in MODULE_ROWS:
		_module_payloads.append(_build_module_row(module_id))


func _build_module_row(module_id: StringName) -> Dictionary:
	var module_row := ModuleCatalog.module(module_id)
	var name_text := String(module_row.get(&"name", ""))
	var cost := int(module_row.get(&"cost", 0))
	var draw := int(module_row.get(&"draw", 0))
	var icon_path := String(module_row.get(&"icon", ""))
	var complete := module_id != &"" and not name_text.is_empty() and cost >= 0
	var row := Button.new()
	row.name = "Module%s" % String(module_id).trim_prefix("w_").to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = not complete
	row.set_meta(&"id", module_id)
	var box := _make_inner(row)
	var icon := _make_icon(icon_path, COL_MODULE_ICON)
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, META_DRAW % draw, complete))
	var effect := _make_cell(box, COL_EFFECT, "", HEADER_EFFECT, "Effect")
	var price := _make_cell(box, COL_PRICE, "", PRICE_CAPTION, "Price")
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	var action := _make_cell(box, COL_ACTION, "", "", "Action")
	if complete:
		effect[0].text = String(EFFECT_TEXT.get(module_id, ""))
		effect[0].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_connect_cells(box, _module_section)
	var payload := {
		&"id": module_id,
		&"name": name_text,
		&"cost": cost,
		&"draw": draw,
		&"complete": complete,
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"price": price[0],
		&"tag": tag[0],
		&"action": action[0],
	}
	if complete:
		row.pressed.connect(_on_module_pressed.bind(payload))
		row.focus_entered.connect(_on_module_focused.bind(row, payload))
		row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
		row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_module_rows.add_child(row)
	return payload


## The MODULES rows' ids in render order: the row set, read back for probes and tests.
func module_row_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for payload: Dictionary in _module_payloads:
		ids.append(payload[&"id"])
	return ids


func _on_module_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	var module_id: StringName = payload[&"id"]
	match module_action(module_id):
		ACTION_BUY:
			buy_module(module_id)
		ACTION_INSTALL:
			install_module(module_id)
		ACTION_SWAP:
			swap_module(module_id)
		ACTION_REMOVE:
			remove_module(fit_index_of(module_id))


func _on_module_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	status_requested.emit(
		STATUS_MODULE_HINT
		% [
			String(module_action(payload[&"id"])),
			String(payload[&"name"]).to_upper(),
			_format_int(int(payload[&"cost"])),
		],
		false
	)


func _on_strip_remove(index: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	remove_module(index)


## --------------------------------------------------------------- the state machine


## STATION_HUB section 5.1's ACTION chain, one state per row: BUY while the account holds
## none, INSTALL while a W cell is empty (09 section 4 item 4 lets a weapon repeat, so a
## fitted module is installed a second time rather than pinned to REMOVE), SWAP once no cell
## is empty, and REMOVE for a module that is already on the hull of a full grid - the last
## state of the pin's chain, where taking the module off is the only thing left to do. A
## fitted module is removable from the strip's own line whatever the grid holds.
func module_action(module_id: StringName) -> StringName:
	var profile := _profile()
	if profile == null or module_id == &"":
		return &""
	var owned := int(profile.call(&"module_count", module_id))
	if _first_empty_cell(profile) >= 0:
		return ACTION_INSTALL if owned > 0 else ACTION_BUY
	if fit_index_of(module_id) >= 0:
		return ACTION_REMOVE
	return ACTION_SWAP if owned > 0 else ACTION_BUY


## The W cell (09 section 4 item 5's layout index) the module is fitted in on the active
## hull, -1 when it is not fitted. The fit stores a module *instance* id and the row's id
## is a catalogue base id, so the two are compared through `base_module_id`.
func fit_index_of(module_id: StringName) -> int:
	var profile := _profile()
	if profile == null or module_id == &"":
		return -1
	var cells := _weapon_cells(profile)
	for index in cells.size():
		if _base_id(profile, StringName(cells[index])) == module_id:
			return index
	return -1


## The MODULES rows' STATUS and ACTION for one module, in one place, so the label and the
## press cannot disagree.
func _module_state(profile: ProfileScript, module_id: StringName) -> Dictionary:
	var index := fit_index_of(module_id)
	var owned := 0
	var affordable := true
	if profile != null:
		owned = int(profile.call(&"module_count", module_id))
		var cost := int(ModuleCatalog.module(module_id).get(&"cost", 0))
		affordable = bool(profile.call(&"can_afford", cost))
	var status := STATUS_LOCKED
	if index >= 0:
		status = STATUS_FITTED % (index + 1)
	elif owned > 0:
		status = STATUS_OWNED % owned
	elif affordable:
		status = STATUS_FOR_SALE
	return {&"status": status, &"action": module_action(module_id)}


## ---------------------------------------------------------------- the four actions


## BUY: the profile's own `buy_module` with the catalogue's price (CONTRACTS section 12;
## the panel invents no price and the seam decides). A refusal is the shell's
## `purchase_failed` render, so the row only marks its price cell.
func buy_module(module_id: StringName) -> bool:
	var profile := _profile()
	var row := ModuleCatalog.module(module_id)
	if profile == null or row.is_empty():
		return false
	var cost := int(row[&"cost"])
	if not bool(profile.call(&"buy_module", module_id, cost)):
		_pulse(_price_label(module_id))
		return false
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_MODULE_BOUGHT % [_module_name(module_id), _format_int(cost)], false
	)
	return true


## INSTALL: the first empty W cell. 09 section 4's legality is checked on the candidate fit
## first, so a refusal writes nothing and the module never leaves the inventory; no empty
## cell is the pin's `W SLOTS FULL` refusal rather than a silent no-op.
func install_module(module_id: StringName) -> bool:
	var profile := _profile()
	if profile == null or ModuleCatalog.slot_of(module_id) != WEAPON_SLOT:
		return false
	var hull := _active_hull(profile)
	var cells := _weapon_cells(profile)
	var index := cells.find("")
	if index < 0:
		return _refuse(REFUSAL_SLOTS_FULL)
	if int(profile.call(&"module_count", module_id)) <= 0:
		return false
	var legal := ShipFit.fit_legal(hull, _candidate_fit(profile, cells, index, module_id))
	if not bool(legal.get(&"legal", false)):
		return _refuse_fit(legal)
	_seed_fit(profile, hull)
	profile.call(&"take_module", module_id, 1)
	if not bool(profile.call(&"set_fit_slot", hull, WEAPON_SLOT, index, module_id)):
		profile.call(&"add_module", module_id, 1)
		return false
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_INSTALLED % [_module_name(module_id), index + 1], false)
	return true


## SWAP: the same write into a cell that is already full, with the displaced module handed
## back to the inventory - never destroyed (09 section 4 item 8). `SWAP_INDEX` is the first
## W cell, the same "first" rule INSTALL uses.
func swap_module(module_id: StringName, index: int = SWAP_INDEX) -> bool:
	var profile := _profile()
	if profile == null or ModuleCatalog.slot_of(module_id) != WEAPON_SLOT:
		return false
	var hull := _active_hull(profile)
	var cells := _weapon_cells(profile)
	if index < 0 or index >= cells.size():
		return false
	var displaced := StringName(cells[index])
	if displaced == module_id or int(profile.call(&"module_count", module_id)) <= 0:
		return false
	var legal := ShipFit.fit_legal(hull, _candidate_fit(profile, cells, index, module_id))
	if not bool(legal.get(&"legal", false)):
		return _refuse_fit(legal)
	_seed_fit(profile, hull)
	profile.call(&"take_module", module_id, 1)
	if not bool(profile.call(&"set_fit_slot", hull, WEAPON_SLOT, index, module_id)):
		profile.call(&"add_module", module_id, 1)
		return false
	var returned := _base_id(profile, displaced)
	if returned != &"":
		profile.call(&"add_module", returned, 1)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_SWAPPED % [_module_name(module_id), _module_name(returned)], false
	)
	return true


## REMOVE: the cell is emptied and the module goes back to the inventory (09 section 4 item
## 8, 10 section 6). The write comes first, so a cell that could not be written hands
## nothing back.
func remove_module(index: int) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	var cells := _weapon_cells(profile)
	if index < 0 or index >= cells.size():
		return false
	var module_id := _base_id(profile, StringName(cells[index]))
	if module_id == &"":
		return false
	_seed_fit(profile, hull)
	if not bool(profile.call(&"set_fit_slot", hull, WEAPON_SLOT, index, &"")):
		return false
	profile.call(&"add_module", module_id, 1)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_REMOVED % _module_name(module_id), false)
	return true


## The overload line is 09 section 2's own format over the candidate fit's arithmetic
## (`Σ draws / output — over by`), rendered in the footer strip with the danger colour and
## the denied cue; nothing is written and nothing auto-removes.
func _refuse_fit(legal: Dictionary) -> bool:
	var power: Dictionary = legal.get(&"power", {})
	if not bool(power.get(&"legal", false)):
		var draw := int(power.get(&"draw", 0))
		var out := int(power.get(&"out", 0))
		return _refuse(REFUSAL_OVERLOAD % [draw, out, draw - out])
	return _refuse(REFUSAL_FIT_ILLEGAL)


func _refuse(message: String) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(message, true)
	return false


## ------------------------------------------------------------- the fit the panel reads


## The fit the panel shows and writes against: the account's own when it holds one, else
## 09 section 9's `ShipFit.standard_fit` - the same resolution `game.gd:_launch_fit_for`
## launches with, so the strip cannot promise a cell the launch would not fly.
func _resolved_fit(profile: ProfileScript, hull: StringName) -> Dictionary:
	if profile != null and hull != &"":
		var stored: Dictionary = profile.call(&"fit_for", hull)
		if _holds_a_module(stored):
			return stored
	return ShipFit.standard_fit(hull)


## Materialise the fit the launch already flies. `PlayerProfile.set_fit_slot` writes one
## cell of the hull's *stored* fit, and a hull the account holds no fit for is normalised
## from nothing - so the first write would otherwise leave the hull with that one cell and
## no 09 section 7 mandatory set, which cannot launch. The seed writes the same fit the
## resolution above reads, so the two agree; nothing else in the panel writes a whole fit.
func _seed_fit(profile: ProfileScript, hull: StringName) -> void:
	var stored: Dictionary = profile.call(&"fit_for", hull)
	if _holds_a_module(stored):
		return
	var standard := ShipFit.standard_fit(hull)
	if standard.is_empty():
		return
	profile.call(&"set_fit", hull, standard)


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


## The resolved fit with one W cell rewritten: the fit `ShipFit.fit_legal` judges before
## anything is written.
func _candidate_fit(
	profile: ProfileScript, cells: Array, index: int, module_id: StringName
) -> Dictionary:
	var fit: Dictionary = _resolved_fit(profile, _active_hull(profile)).duplicate(true)
	var updated: Array = []
	for cell: Variant in cells:
		updated.append(String(cell))
	updated[index] = String(module_id)
	fit[WEAPON_SLOT] = updated
	return fit


func _first_empty_cell(profile: ProfileScript) -> int:
	return _weapon_cells(profile).find("")


func _active_hull(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


func _module_name(module_id: StringName) -> String:
	var name_text := String(ModuleCatalog.module(module_id).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(module_id).to_upper()


func _price_label(module_id: StringName) -> Label:
	for payload: Dictionary in _module_payloads:
		if payload[&"id"] == module_id:
			return payload[&"price"]
	return null


## ------------------------------------------------------------------- the refresh


func _refresh_all() -> void:
	_refresh_rows()
	_refresh_module_rows()
	_refresh_strip()


func _refresh_module_rows() -> void:
	var profile := _profile()
	for payload: Dictionary in _module_payloads:
		_refresh_module_row(payload, profile)


func _refresh_module_row(payload: Dictionary, profile: ProfileScript) -> void:
	var price: Label = payload[&"price"]
	var tag: Label = payload[&"tag"]
	var action: Label = payload[&"action"]
	if not bool(payload[&"complete"]):
		price.text = ""
		price.remove_theme_color_override(&"font_color")
		tag.text = TAG_UNAVAILABLE
		action.text = ""
		return
	var cost := int(payload[&"cost"])
	var affordable := profile == null or bool(profile.call(&"can_afford", cost))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	price.text = _format_int(cost)
	var state := _module_state(profile, payload[&"id"])
	tag.text = String(state[&"status"])
	action.text = String(state[&"action"])


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
