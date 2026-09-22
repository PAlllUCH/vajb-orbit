extends VBoxContainer
## SHIPYARD module panel: the hull list, the large side-view preview, the comparison table
## against the active hull, the price and the BUY / SET ACTIVE action. Every value is a
## StationCatalog, PlayerProfile, ShipFit or ModuleCatalog read. Contract:
## docs/design/STATION_HUB.md sections 5.2 (incl. the 2026-09-21 P2-A and 2026-09-22
## amendments), 5.6, 7.2 and 12, docs/design/STATION_SPEC.md sections 2.4 and 6,
## CONTRACTS section 11.
##
## The slot layout grid (`%HardpointSlots`) is rebuilt per selection from the selected
## hull's own 08 section 3.2 matrix: one cell per matrix cell, `columns` = the matrix
## width, a gap an empty cell and a slot cell a disabled 48 px plate carrying that type's
## slot glyph. The caption and the ENGINES / SLOT CELLS rows read `ShipFit` for the same
## hull, so the whole stat column moves with the selection and no count is restated here.
## A plate also answers the pointer: hovering one publishes the fitting surface's own line
## (`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`) into the shell's strip, read from the
## selected hull's `fit_for` entry and `module_count` - the grid stays a display, and the
## plate's size, glyph, separation and caption do not move for it (section 5.2's amendment).
##
## The station shell loads this scene into its host, so the panel never routes, never
## writes the profile and never draws the credits readout: it emits status_requested up
## and reads StationCatalog / PlayerProfile down (STATION_HUB section 12.4).
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
const COL_TAG := 130.0
const COL_STAT := 110.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
## ui/components/slot_button.tscn insets its glyph 6 px inside the 48 px plate; the
## layout grid reuses that one number rather than inventing a second inset.
const PLATE_ICON_INSET := 6.0

## 09 section 1's slot glyph per slot-type key. The glyph files are named by the
## document's own stems (`icon_slot_engine`, `icon_slot_power`, `icon_slot_w`, ...),
## which are not the API's key names, so the mapping is stated once here.
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
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s_48.png"

const PREVIEW_SCALE := 0.70
const PREVIEW_MAX_WIDTH := 480.0

## CONTRACTS section 11: `hull`, `shield` and `cargo` are catalogue fields; `engines`
## and `slots` are the hull's 08 section 3 counts, read through `ShipFit` (see
## `_stat_value`). No catalogue row carries them.
const STAT_ROWS: Array[Dictionary] = [
	{&"key": &"hull", &"label": "HULL"},
	{&"key": &"shield", &"label": "SHIELD"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"engines", &"label": "ENGINES"},
	{&"key": &"slots", &"label": "SLOT CELLS"},
]
const COMPARISON_CAPTION := "COMPARISON"
const COMPARISON_SELECTED := "SELECTED"
const COMPARISON_ACTIVE := "ACTIVE"

const SUBTITLE := "BUY AND SWITCH HULLS · %d IN THE CRADLE · SIDE VIEWS ONLY"
const TAG_ACTIVE_HULL := "ACTIVE HULL %s"
const META_FORMAT := "%d HULL · %d SLOTS"
## CONTRACTS section 11's caption: the hull's slot count (08 section 3's Total, gaps
## excluded) and its ENGINE count. The node is still `%HardpointCaption`.
const HARDPOINT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"
## STATION_HUB section 5.2's 2026-09-22 amendment (owner request 1): a slot plate reads the
## fitting surface's own line on hover, `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`,
## resolved from the selected hull's `fit_for` entry and the account's `module_count`. The grid
## stays a display - the plate is still disabled, carries no focus ring and mutates nothing -
## and the plate's size, its glyph, its separation and the caption above do not move.
const HOVER_FORMAT := "%s%d · %s · OWNED ×%d"
const HOVER_EMPTY := "EMPTY"
## `power` is one id, not a set of cells (CONTRACTS section 11 rule 1).
const POWER_SLOT: StringName = &"power"
const PRICE_ZERO := "0"

const STATE_ACTIVE := "ACTIVE"
const STATE_OWNED := "OWNED"
const STATE_FOR_SALE := "FOR SALE"
const STATE_LOCKED := "LOCKED"
const STOCK_UNAVAILABLE := "STOCK UNAVAILABLE"

const ACTION_IN_SERVICE := "IN SERVICE"
const ACTION_SET_ACTIVE := "SET ACTIVE"
const ACTION_BUY := "BUY"

const PREVIEW_EMPTY := "NO HULL IN THE CRADLE"
const STATUS_HINT := "ENTER SELECT · %s · %s CREDITS"
const STATUS_BOUGHT := "PURCHASED · %s · NOT ACTIVE UNTIL YOU SET IT"
const STATUS_ACTIVE := "ACTIVE HULL IS NOW %s"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _list: VBoxContainer = %ShipList
@onready var _preview_caption: Label = %PreviewCaption
@onready var _preview_center: CenterContainer = %PreviewCenter
@onready var _preview_image: TextureRect = %PreviewImage
@onready var _preview_name: Label = %PreviewName
@onready var _stats: VBoxContainer = %ShipStats
@onready var _hardpoint_caption: Label = %HardpointCaption
@onready var _hardpoints: GridContainer = %HardpointSlots
@onready var _price: Label = %ShipPrice
@onready var _action: Button = %ShipAction

var _payloads: Array[Dictionary] = []
var _stat_cells: Dictionary = {}
var _selected_id: StringName = &""
var _selected_row: Button = null
var _native_preview := Vector2.ZERO
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_comparison()
	_build_layout_grid()
	_build_rows()
	_apply_tokens()
	_preview_center.resized.connect(_update_preview_size)
	_action.pressed.connect(_on_action_pressed)
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_refresh_plate_textures()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"credits" moves every price, tag and the action label,
	## &"ships" moves the owned list, the active hull and the comparison column.
	if key == &"credits" or key == &"ships":
		_refresh_all()


func focus_primary() -> void:
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _action.disabled:
		_action.grab_focus()


func _apply_tokens() -> void:
	var ink: Color = _token(&"text_primary")
	_pane_icon.modulate = ink
	for payload: Dictionary in _payloads:
		var icon: TextureRect = payload[&"icon"]
		if icon != null:
			var tint := ink
			tint.a = ROW_ICON_IDLE_ALPHA
			icon.modulate = tint


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_rows() -> void:
	_subtitle.text = SUBTITLE % Catalog.SHIPS.size()
	_payloads.clear()
	for ship: Dictionary in Catalog.SHIPS:
		_payloads.append(_build_row(ship))
	_add_slack()


func _build_row(ship: Dictionary) -> Dictionary:
	var ship_id: StringName = ship.get(&"id", &"")
	var name_text := String(ship.get(&"name", ""))
	var complete := ship_id != &"" and not name_text.is_empty()
	var meta := META_FORMAT % [int(ship.get(&"hull", 0)), _slot_cell_count(ship_id)]
	var row := Button.new()
	row.name = "Ship%s" % String(ship_id).trim_prefix("ship_").to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = not complete
	row.set_meta(&"id", ship_id)
	var box := _make_inner(row)
	box.add_child(_make_title_box(name_text, meta, complete))
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	var payload := {
		&"id": ship_id,
		&"name": name_text,
		&"cost": int(ship.get(&"cost", 0)),
		&"complete": complete,
		&"row": row,
		&"icon": null,
		&"tag": tag[0],
	}
	if complete:
		row.pressed.connect(_on_row_pressed.bind(payload))
		row.focus_entered.connect(_on_row_focused.bind(row, payload))
	_list.add_child(row)
	return payload


func _make_title_box(name_text: String, meta: String, complete: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text if complete else STOCK_UNAVAILABLE)
	title.name = "Title"
	box.add_child(title)
	var meta_label := _make_label(&"StationCaption", meta)
	meta_label.name = "Meta"
	box.add_child(meta_label)
	return box


func _make_cell(
	parent: HBoxContainer, width: float, value_text: String, caption_text: String, cell_name: String
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


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(slack)


func _build_comparison() -> void:
	var header := HBoxContainer.new()
	header.name = "ComparisonHeader"
	header.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	_stats.add_child(header)
	for cell: Dictionary in [
		{&"text": COMPARISON_CAPTION, &"width": 0.0, &"expand": true},
		{&"text": COMPARISON_SELECTED, &"width": COL_STAT, &"expand": false},
		{&"text": COMPARISON_ACTIVE, &"width": COL_STAT, &"expand": false},
	]:
		header.add_child(_make_header_cell(cell))
	for row: Dictionary in STAT_ROWS:
		var line := HBoxContainer.new()
		line.name = "Stat%s" % String(row[&"key"]).to_pascal_case()
		line.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
		_stats.add_child(line)
		var caption := _make_label(&"StationCaption", String(row[&"label"]))
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		var selected := _make_stat_value(line)
		var active := _make_stat_value(line)
		active.add_theme_color_override(&"font_color", _token(&"text_dim"))
		_stat_cells[row[&"key"]] = [selected, active]


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


func _make_stat_value(parent: HBoxContainer) -> Label:
	var label := _make_label(&"StationValue", PRICE_ZERO)
	label.custom_minimum_size = Vector2(COL_STAT, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
	return label


## The grid's separations are set here rather than per rebuild, so one constant drives
## both axes (a GridContainer's `separation` is BoxContainer-only; the HBox the strip
## used to be carried it). The cells themselves come from `_set_layout_grid`.
func _build_layout_grid() -> void:
	_hardpoints.add_theme_constant_override(&"h_separation", PLATE_SEPARATION)
	_hardpoints.add_theme_constant_override(&"v_separation", PLATE_SEPARATION)


## CONTRACTS section 11: one cell per 08 section 3.2 matrix cell of `hull_id`, row-major
## (`ShipFit.grid_cells` order), `columns` = the matrix width. A gap is an empty 48 x 48
## `Control` with no plate; a slot cell is a disabled plate carrying its type's slot
## glyph. The caption reads the same hull, so it can never describe a previous one.
func _set_layout_grid(hull_id: StringName) -> void:
	for child: Node in _hardpoints.get_children():
		_hardpoints.remove_child(child)
		child.queue_free()
	var cells: Array = ShipFit.grid_cells(hull_id)
	if cells.is_empty():
		_hardpoints.columns = 1
		_hardpoint_caption.text = ""
		return
	_hardpoints.columns = ShipFit.grid_size(hull_id).x
	var slot_cells := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			_hardpoints.add_child(_make_gap_cell())
		else:
			_make_slot_cell(cell)
			slot_cells += 1
	var engines := int(ShipFit.grid_counts(hull_id).get(&"engines", 0))
	_hardpoint_caption.text = HARDPOINT_CAPTION % [slot_cells, engines]


func _make_gap_cell() -> Control:
	var cell := Control.new()
	cell.name = "Gap"
	cell.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


## Display cell for one non-gap matrix cell: the 48 px disabled plate plus its type's slot
## glyph, wired to the section 5.2 amendment's hover line. `_make_plate` parents it (it always
## has), so the caller adds nothing.
func _make_slot_cell(cell: Dictionary) -> void:
	var plate := _make_plate(_hardpoints, PLATE_VARIATION, PLATE_SIZE)
	plate.name = "Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])]
	plate.disabled = true
	# The plate stays a display - disabled, no focus ring, no mutation - but it answers the
	# pointer, which is what the section 5.2 amendment's hover line needs (`_make_plate` leaves
	# the filter at IGNORE, and a filter that ignores the mouse never reports a hover).
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	plate.mouse_entered.connect(_on_plate_hovered.bind(cell))
	plate.mouse_exited.connect(_on_plate_unhovered)
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.custom_minimum_size = Vector2(PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = _slot_glyph(StringName(cell[&"type"]))
	glyph.modulate = _token(&"text_dim")
	plate.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = PLATE_ICON_INSET
	glyph.offset_top = PLATE_ICON_INSET
	glyph.offset_right = -PLATE_ICON_INSET
	glyph.offset_bottom = -PLATE_ICON_INSET


## 09 section 1's shipped slot glyph for a slot-type key: `icon_slot_<stem>_48.png`.
## Null for a type with no glyph (never one of the eight), so the cell then draws its
## plate alone rather than an error.
func _slot_glyph(slot_key: StringName) -> Texture2D:
	var stem := String(SLOT_GLYPHS.get(slot_key, ""))
	if stem.is_empty():
		return null
	var path := SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The hover line for one grid cell (STATION_HUB section 5.2's 2026-09-22 amendment): the
## cell's own type token and layout index, the selected hull's module in that cell - or the
## pin's `EMPTY` - and how many of it the account holds. A hull the account owns reads the fit
## the launch would fly (`resolved_fit`, the profile's own fallback: the stored fit when it
## holds a module, else 09 section 9's `ShipFit.standard_fit`), so the line agrees with the
## FITTING pane's preview and with the ship this hull would launch as; a hull it does not own
## keeps reading `fit_for`, whose all-empty shape answers `EMPTY` for every cell. An instance
## id resolves through the profile's own `base_module_id` bridge, the way the fitting pane
## names its modules; `&""` for a gap, which carries no plate to hover.
func hover_line(cell: Dictionary) -> String:
	if bool(cell.get(&"gap", false)):
		return ""
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var profile := _profile()
	var module_id := &""
	if profile != null:
		var read := &"fit_for"
		if _owned_ids(profile).has(_selected_id):
			read = &"resolved_fit"
		module_id = _fit_cell_module(profile.call(read, _selected_id), slot_key, index)
	if module_id == &"":
		return HOVER_FORMAT % [String(cell.get(&"token", "")), index + 1, HOVER_EMPTY, 0]
	var base := _base_id(profile, module_id)
	var owned := 0
	if profile != null:
		owned = int(profile.call(&"module_count", base))
	return HOVER_FORMAT % [String(cell.get(&"token", "")), index + 1, _module_name(base), owned]


## The module id one fit cell holds, `&""` for an empty cell and for an index the hull does not
## carry. POWER is one id rather than a set of cells (CONTRACTS section 11 rule 1), so it is
## read as a single value; every other type is the layout-indexed array 09 section 4.5
## describes.
func _fit_cell_module(fit: Dictionary, slot_key: StringName, index: int) -> StringName:
	if slot_key == POWER_SLOT:
		var single: Variant = fit.get(slot_key, fit.get(String(slot_key), ""))
		return StringName(String(single)) if single != null else &""
	var raw: Variant = fit.get(slot_key, fit.get(String(slot_key), []))
	if not raw is Array:
		return &""
	var cells: Array = raw as Array
	if index < 0 or index >= cells.size():
		return &""
	return StringName(String(cells[index]))


## The fit stores a module *instance* id (15 section 6) and the catalogue reads base ids, so
## every id the line names goes through the profile's own bridge.
func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


## The catalogue's own name for a module, in this pane's upper case; an id the catalogue cannot
## name reads as the id itself rather than as a blank line.
func _module_name(module_id: StringName) -> String:
	var name_text := String(ModuleCatalog.module(module_id).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(module_id).to_upper()


## Hovering a plate publishes its line on the channel every hint in this pane uses
## (`status_requested`); leaving it puts the selected hull's own hint back, so the shell's strip
## never keeps a line for a cell the pointer has left.
func _on_plate_hovered(cell: Dictionary) -> void:
	status_requested.emit(hover_line(cell), false)


func _on_plate_unhovered() -> void:
	var payload := _payload(_selected_id)
	if not payload.is_empty():
		status_requested.emit(_row_hint(payload), false)


func _payload(ship_id: StringName) -> Dictionary:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == ship_id:
			return payload
	return {}


## How many non-gap cells the hull carries, which is 08 section 3's Total: every value
## of `ShipFit.grid_counts` (gaps are not counted by the grid at all) summed.
func _slot_cell_count(hull_id: StringName) -> int:
	var total := 0
	for count: Variant in ShipFit.grid_counts(hull_id).values():
		total += int(count)
	return total


## One comparison cell's number: the catalogue's own field, or the hull's 08 section 3
## count for `engines`/`slots` (which no catalogue row carries).
func _stat_value(ship: Dictionary, ship_id: StringName, key: StringName) -> int:
	if key == &"engines":
		return int(ShipFit.grid_counts(ship_id).get(&"engines", 0))
	if key == &"slots":
		return _slot_cell_count(ship_id)
	return int(ship.get(key, 0))


func _make_plate(parent: GridContainer, variation: StringName, plate_size: float) -> TextureButton:
	# ui/components/slot_button.gd copies the theme plate textures onto the node, because a
	# TextureButton has no stylebox items, so SlotButtonWeapon/styles/* is never read by the
	# engine on a bare theme_type_variation. The panel repeats that lookup (the mockup's own
	# construct) so the grid also renders without instancing the HUD component.
	var plate := TextureButton.new()
	plate.theme_type_variation = variation
	plate.ignore_texture_size = true
	plate.custom_minimum_size = Vector2(plate_size, plate_size)
	plate.focus_mode = Control.FOCUS_NONE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(plate)
	_apply_plate_textures(plate)
	return plate


func _apply_plate_textures(plate: TextureButton) -> void:
	var variation: StringName = plate.theme_type_variation
	plate.texture_normal = _plate_texture(variation, &"normal")
	plate.texture_hover = _plate_texture(variation, &"hover")
	plate.texture_pressed = _plate_texture(variation, &"pressed")
	plate.texture_disabled = _plate_texture(variation, &"disabled")


func _plate_texture(variation: StringName, state: StringName) -> Texture2D:
	if not has_theme_stylebox(state, variation):
		return null
	var box := get_theme_stylebox(state, variation)
	if box is StyleBoxTexture:
		return (box as StyleBoxTexture).texture
	return null


func _refresh_plate_textures() -> void:
	# A gap cell is a bare Control, so the cast filters it out; the plates re-copy the
	# theme's four plate textures on every theme change, as before.
	for child: Node in _hardpoints.get_children():
		var plate := child as TextureButton
		if plate != null:
			_apply_plate_textures(plate)


func _refresh_all() -> void:
	var profile := _profile()
	if _selected_id == &"" or Catalog.ship(_selected_id).is_empty():
		_selected_id = _default_selection(profile)
	_refresh_rows(profile)
	_refresh_preview(profile)
	_refresh_action(profile)


func _refresh_rows(profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	var owned := _owned_ids(profile)
	_tag.text = TAG_ACTIVE_HULL % _ship_name(active_id)
	for payload: Dictionary in _payloads:
		var tag: Label = payload[&"tag"]
		var affordable := _affordable(profile, int(payload[&"cost"]))
		if payload[&"id"] == active_id:
			tag.text = STATE_ACTIVE
		elif owned.has(payload[&"id"]):
			tag.text = STATE_OWNED
		elif affordable:
			tag.text = STATE_FOR_SALE
		else:
			tag.text = STATE_LOCKED


func _refresh_preview(profile: ProfileScript) -> void:
	var ship := Catalog.ship(_selected_id)
	if ship.is_empty():
		_preview_image.texture = null
		_native_preview = Vector2.ZERO
		_preview_image.custom_minimum_size = Vector2.ZERO
		_preview_name.text = PREVIEW_EMPTY
		_preview_caption.text = ""
		_price.text = PRICE_ZERO
		_price.remove_theme_color_override(&"font_color")
		_refresh_comparison({}, profile)
		_set_layout_grid(&"")
		return
	var texture := load(String(ship.get(&"preview", ""))) as Texture2D
	_preview_image.texture = texture
	_native_preview = texture.get_size() if texture != null else Vector2.ZERO
	_preview_name.text = String(ship.get(&"name", String(_selected_id)))
	_preview_caption.text = String(ship.get(&"description", ""))
	_update_preview_size()
	var cost := int(ship.get(&"cost", 0))
	_price.text = _format_int(cost)
	if _affordable(profile, cost):
		_price.remove_theme_color_override(&"font_color")
	else:
		_price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	_refresh_comparison(ship, profile)
	_set_layout_grid(_selected_id)


func _update_preview_size() -> void:
	var target := _native_preview * PREVIEW_SCALE
	if target.x > PREVIEW_MAX_WIDTH:
		target *= PREVIEW_MAX_WIDTH / target.x
	var box := _preview_center.size
	if box.x > 1.0 and target.x > box.x:
		target *= box.x / target.x
	if box.y > 1.0 and target.y > box.y:
		target *= box.y / target.y
	if not _preview_image.custom_minimum_size.is_equal_approx(target):
		_preview_image.custom_minimum_size = target


func _refresh_comparison(ship: Dictionary, profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	var active := Catalog.ship(active_id)
	for stat: Dictionary in STAT_ROWS:
		var cells: Array = _stat_cells.get(stat[&"key"], [])
		if cells.size() < 2:
			continue
		var key: StringName = stat[&"key"]
		var selected_value := _stat_value(ship, _selected_id, key)
		var active_value := _stat_value(active, active_id, key)
		var selected_label: Label = cells[0]
		var active_label: Label = cells[1]
		selected_label.text = str(selected_value)
		active_label.text = str(active_value)
		if selected_value < active_value:
			selected_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
		else:
			selected_label.remove_theme_color_override(&"font_color")


func _refresh_action(profile: ProfileScript) -> void:
	var ship := Catalog.ship(_selected_id)
	if ship.is_empty():
		_action.text = ACTION_BUY
		_action.disabled = true
		return
	if _selected_id == _active_id(profile):
		_action.text = ACTION_IN_SERVICE
		_action.disabled = true
	elif _owned_ids(profile).has(_selected_id):
		_action.text = ACTION_SET_ACTIVE
		_action.disabled = false
	else:
		_action.text = ACTION_BUY
		_action.disabled = false


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	var profile := _profile()
	_selected_id = payload[&"id"]
	_refresh_preview(profile)
	_refresh_action(profile)
	status_requested.emit(_row_hint(payload), false)


func _on_row_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_selected_id = payload[&"id"]
	_act(payload[&"id"])


func _on_action_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_act(_selected_id)


func _act(ship_id: StringName) -> void:
	## The hint and the price colour never decide a purchase: buy_ship and set_active_ship
	## do, and a refusal is announced by the shell from purchase_failed (section 5.6).
	var profile := _profile()
	if profile == null:
		return
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return
	var name_text := String(ship.get(&"name", String(ship_id))).to_upper()
	var bought := false
	if _owned_ids(profile).has(ship_id):
		if bool(profile.call(&"set_active_ship", ship_id)):
			AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
			status_requested.emit(STATUS_ACTIVE % name_text, false)
			return
	else:
		bought = bool(profile.call(&"buy_ship", ship_id, int(ship.get(&"cost", 0))))
		if bought:
			AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
			status_requested.emit(STATUS_BOUGHT % name_text, false)
			return
	_pulse(_price)
	_refresh_all()


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


func _default_selection(profile: ProfileScript) -> StringName:
	var active_id := _active_id(profile)
	if not Catalog.ship(active_id).is_empty():
		return active_id
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if ship_id != &"":
			return ship_id
	return &""


func _ship_name(ship_id: StringName) -> String:
	## The tag and the action copy name the hull the way the catalogue does, and fall back to
	## the id itself when the catalogue cannot resolve it.
	var ship := Catalog.ship(ship_id)
	return String(ship.get(&"name", String(ship_id))).to_upper()


func _active_id(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _owned_ids(profile: ProfileScript) -> Array:
	if profile == null:
		return []
	return profile.call(&"owned_ships")


func _affordable(profile: ProfileScript, cost: int) -> bool:
	return profile == null or bool(profile.call(&"can_afford", cost))


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
