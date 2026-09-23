extends VBoxContainer
## SHIPYARD module panel: the hangar. The list holds **owned hulls only** -- one row per
## owned ship, its name, its class and the `ACTIVE` badge -- and selecting a row **previews**
## it (side render, comparison stats, its own fit grid) without writing anything; the
## footer `SET ACTIVE` button is the sole commit. Buying a hull happens on the AUCTION's
## shelf only (10 section 2.1). Every value is a StationCatalog, PlayerProfile, ShipFit or
## ModuleCatalog read. Contract: docs/design/STATION_HUB.md sections 5.2 (incl. the
## 2026-09-21 P2-A, 2026-09-22 P2-B and 2026-09-23 S5 amendments), 5.6, 5.11, 7.2 and 12,
## docs/design/STATION_SPEC.md sections 2.4 and 6, docs/gameplay/10_ship_acquisition.md
## sections 2.4 and 6.1, CONTRACTS sections 11 and 17.
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
## writes the profile except through the one `set_active_ship` the footer commits, and never
## draws the credits readout: it emits status_requested up and reads StationCatalog /
## PlayerProfile down (STATION_HUB section 12.4).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
## 15 section 7's naming grammar has one builder (`Auction.rolled_name`); the hover line and
## the stat block below the grid call it rather than growing a second copy (K2's deviation 7).
const AuctionScript := preload("res://game/auction.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

const ROW_HEIGHT := 76.0
const COL_TAG := 130.0
const COL_STAT := 110.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
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
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s.svg"

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

const SUBTITLE := "YOUR HULLS · %d IN THE HANGAR · SIDE VIEWS ONLY"
const TAG_ACTIVE_HULL := "ACTIVE HULL %s"
## Section 5.11's row: the name, the class and the `ACTIVE` badge, no icon (none ships).
## The class is `ShipFit.HULLS`' own `ship_class` column, the value the AUCTION's hull rows
## render as `%s CLASS` too.
const META_FORMAT := "%s CLASS · %d HULL · %d SLOTS"
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
## The stat block the S3 amendment adds under the grid while a filled cell is hovered: 15
## section 7's two-line block (the base module's catalogue stats plus one line per rolled
## affix), built in script so the frozen scene file needs no new node.
const HOVER_BLOCK_SEPARATOR := "\n"
const HOVER_STAT_JOIN := " · "
const HOVER_BASE_FORMAT := "BASE DRAW %d"
const HOVER_ADD_SUFFIX := " ADD"
const HOVER_MULT_SUFFIX := " MULT"
const HOVER_MULTIPLIER := "×"
## `power` is one id, not a set of cells (CONTRACTS section 11 rule 1).
const POWER_SLOT: StringName = &"power"
const PRICE_ZERO := "0"

const STATE_ACTIVE := "ACTIVE"

const ACTION_IN_SERVICE := "IN SERVICE"
## The footer's one commit and the pane's only write (section 5.11: "the footer SET ACTIVE
## is the sole commit"; CONTRACTS section 17).
const ACTION_SET_ACTIVE := "SET ACTIVE"

const PREVIEW_EMPTY := "NO HULL IN THE CRADLE"
const EMPTY_HULLS := "NO HULLS OWNED"
const STATUS_HINT := "ENTER PREVIEWS · %s · %s CLASS"
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
@onready var _action: Button = %ShipAction

var _payloads: Array[Dictionary] = []
var _stat_cells: Dictionary = {}
var _selected_id: StringName = &""
var _selected_row: Button = null
var _native_preview := Vector2.ZERO
var _tweens: Array[Tween] = []
## The hovered cell's stat block label, built in script under the grid.
var _hover_block: Label = null


func _ready() -> void:
	_build_comparison()
	_build_layout_grid()
	_build_rows()
	_mount_hover_block()
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
	## STATION_HUB section 12.4: &"credits" moves the tags and the action label, &"ships"
	## moves the owned list, the active hull and the comparison column. The list is the
	## **owned** roster now (section 5.11), so a hull bought on the AUCTION makes this pane
	## rebuild its rows - and the profile emits from inside `buy_ship`/`set_active_ship`, so
	## the rebuild is a fresh row set rather than an edit of the rows a press may still have
	## on the stack (the AUCTION pane's own rule).
	if key == &"credits" or key == &"ships":
		if not _sync_rows():
			_refresh_all()


## Rebuilds the rows when the account's owned roster moved since they were built, and
## answers whether it did. The roster is compared in the catalogue's ladder order, so a
## purchase order (or a re-set of the same account) never reads as a change.
func _sync_rows() -> bool:
	var roster := _owned_roster(_profile())
	if roster == _built_ids():
		return false
	_build_rows()
	_refresh_all()
	return true


## The ids of the rows the pane currently carries, in render order.
func _built_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for payload: Dictionary in _payloads:
		ids.append(payload[&"id"])
	return ids


func focus_primary() -> void:
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _action.disabled:
		_action.grab_focus()


## The row that carries one owned hull, or null for a hull the account does not own (the
## hangar lists no row for it). Read back for probes and tests, the way the AUCTION pane's
## `row_of` is.
func row_of(ship_id: StringName) -> Button:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == ship_id:
			return payload[&"row"]
	return null


## The ids of the hangar's rows, in render order.
func listed_ids() -> Array[StringName]:
	return _built_ids()


## The hull the preview is showing.
func selected_id() -> StringName:
	return _selected_id


func _apply_tokens() -> void:
	_pane_icon.modulate = _token(&"text_primary")


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## Section 5.11's hangar list: one row per **owned** hull, in the catalogue's ladder order
## so the list reads the same ladder the AUCTION's shelf does. No row ships for a hull the
## account does not own -- the buy door is the AUCTION's (10 sections 2.1, 6.1).
func _build_rows() -> void:
	_clear(_list)
	_payloads.clear()
	var profile := _profile()
	var roster := _owned_roster(profile)
	_subtitle.text = SUBTITLE % roster.size()
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if roster.has(ship_id):
			_payloads.append(_build_row(ship))
	if _payloads.is_empty():
		_list.add_child(_empty_row())
	_add_slack()


## The account's owned hulls in the catalogue's own ladder order.
func _owned_roster(profile: ProfileScript) -> Array[StringName]:
	var roster: Array[StringName] = []
	var owned := _owned_ids(profile)
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if owned.has(ship_id):
			roster.append(ship_id)
	return roster


func _clear(rows: VBoxContainer) -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()


func _empty_row() -> Label:
	var label := _make_label(&"StationCaption", EMPTY_HULLS)
	label.name = "EmptyRow"
	label.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build_row(ship: Dictionary) -> Dictionary:
	var ship_id: StringName = ship.get(&"id", &"")
	var name_text := String(ship.get(&"name", ""))
	var hull: Dictionary = ShipFit.HULLS.get(ship_id, {})
	var meta := META_FORMAT % [
		String(hull.get(&"ship_class", "")).to_upper(),
		int(ship.get(&"hull", 0)),
		_slot_cell_count(ship_id),
	]
	var row := Button.new()
	row.name = "Ship%s" % String(ship_id).trim_prefix("ship_").to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", ship_id)
	var box := _make_inner(row)
	box.add_child(_make_title_box(name_text, meta))
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	var payload := {
		&"id": ship_id,
		&"name": name_text,
		&"row": row,
		&"icon": null,
		&"tag": tag[0],
	}
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	_list.add_child(row)
	return payload


func _make_title_box(name_text: String, meta: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
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
	_clear_hover_block()
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
##
## STATION_HUB section 5.3's S3 amendment: where the cell holds an instance, the name is 15
## section 7's **full rolled name** (the shared builder) and the `OWNED ×<n>` tail counts the
## base id's held instances, summed over the bag's own keys.
func hover_line(cell: Dictionary) -> String:
	if bool(cell.get(&"gap", false)):
		return ""
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var entry := _hover_entry(cell)
	if entry == &"":
		return HOVER_FORMAT % [String(cell.get(&"token", "")), index + 1, HOVER_EMPTY, 0]
	var profile := _profile()
	var base := _base_id(profile, entry)
	return HOVER_FORMAT % [
		String(cell.get(&"token", "")),
		index + 1,
		_hover_name(profile, base, entry),
		_owned_total(profile, base),
	]


## The entry the hovered cell holds, `&""` for an empty cell and a gap: the same read the line
## and the block share, so the two can never describe two different cells.
func _hover_entry(cell: Dictionary) -> StringName:
	if bool(cell.get(&"gap", false)):
		return &""
	var profile := _profile()
	if profile == null:
		return &""
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var read := &"fit_for"
	if _owned_ids(profile).has(_selected_id):
		read = &"resolved_fit"
	return _fit_cell_module(profile.call(read, _selected_id), slot_key, index)


## One module entry's display name: 15 section 7's rolled name through the shared builder when
## the bag carries the record, the catalogue's own name otherwise.
func _hover_name(profile: ProfileScript, base_id: StringName, entry: StringName) -> String:
	var record := _instance_record(profile, entry)
	if not record.is_empty():
		var rolled := String(AuctionScript.rolled_name(record))
		if not rolled.is_empty():
			return rolled
	var name_text := String(ModuleCatalog.module(base_id).get(&"name", ""))
	return name_text if not name_text.is_empty() else String(base_id)


## The record behind one inventory id, `{}` for an id the bag does not carry (a delivered
## module in 09 section 9's standard fit, for one).
func _instance_record(profile: ProfileScript, entry: StringName) -> Dictionary:
	if profile == null or entry == &"":
		return {}
	var record: Variant = profile.call(&"instance", entry)
	if record is Dictionary:
		return record
	return {}


## The base id's held instances, summed over the bag's own keys through `base_module_id`:
## `module_count(base_id)` answers one record's count and reads 0 for an instance-keyed bag
## (K1's measured note), so the aggregate is the sum here, exactly as the FITTING pane sums it.
func _owned_total(profile: ProfileScript, base_id: StringName) -> int:
	var total := 0
	if profile == null or base_id == &"":
		return total
	for key: Variant in profile.call(&"modules"):
		var entry := StringName(str(key))
		var held := int(profile.call(&"module_count", entry))
		if held <= 0:
			continue
		if StringName(profile.call(&"base_module_id", entry)) == base_id:
			total += held
	return total


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
## ------------------------------------------------------- the hover stat block (15 section 7)
##
## STATION_HUB section 5.3's S3 amendment: a plate that holds an instance shows the rolled name
## in the hover line and the pane adds the instance's stat block - the base module's catalogue
## stats plus one line per rolled affix - under the grid. The block is a reading (nothing here
## reaches a flight stat: 15 section 9.3) and it is built in script, so the frozen scene file
## carries no new node. The formatter is `fitting_panel.gd`'s, byte-equivalently: both panes
## print the same block, and a shared `ui/station/` helper is a file outside this worker's set
## (K2's deviation 6 records the same shape for the header-fit machinery).
func _mount_hover_block() -> void:
	if _hover_block != null and is_instance_valid(_hover_block):
		return
	var label := Label.new()
	label.name = "HoverStatBlock"
	label.theme_type_variation = &"StationCaption"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	_hover_block = label
	_stats.add_child(label)
	_stats.move_child(label, _hardpoints.get_index() + 1)


## The block for one grid cell: empty and hidden for a gap, an empty cell and an entry the
## catalogue cannot name; otherwise the base line plus one line per affix.
func _refresh_hover_block(cell: Dictionary) -> void:
	if _hover_block == null or not is_instance_valid(_hover_block):
		return
	var text := ""
	var entry := _hover_entry(cell)
	if entry != &"":
		text = _stat_block_of(_profile(), entry)
	_hover_block.text = text
	_hover_block.visible = not text.is_empty()


func _clear_hover_block() -> void:
	if _hover_block != null and is_instance_valid(_hover_block):
		_hover_block.text = ""
		_hover_block.visible = false


## The block's own text, read back for probes and tests.
func hover_block_text() -> String:
	return "" if _hover_block == null else _hover_block.text


func _stat_block_of(profile: ProfileScript, entry: StringName) -> String:
	if entry == &"":
		return ""
	var base := _base_id(profile, entry)
	var module_row := ModuleCatalog.module(base)
	if module_row.is_empty():
		return ""
	var lines := PackedStringArray([_base_stats_line(module_row)])
	for line: String in _affix_lines(_instance_record(profile, entry)):
		lines.append(line)
	return HOVER_BLOCK_SEPARATOR.join(lines)


## 15 section 7's first line: the catalogue's own draw and every `effects` entry.
func _base_stats_line(module_row: Dictionary) -> String:
	var parts := PackedStringArray([HOVER_BASE_FORMAT % int(module_row.get(&"draw", 0))])
	var effects: Dictionary = module_row.get(&"effects", {})
	for key: Variant in effects:
		parts.append(stat_line(StringName(str(key)), float(effects[key])))
	return HOVER_STAT_JOIN.join(parts)


## 15 section 7's second line onward: one line per rolled affix, in the record's own order.
func _affix_lines(record: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if record.is_empty():
		return lines
	for raw: Variant in _rows_of(record.get("prefixes")):
		var id := StringName(str(_row_id_of(raw)))
		var prefix: Variant = ModuleCatalog.PREFIXES.get(id, null)
		if not prefix is Dictionary:
			continue
		var row: Dictionary = prefix
		var value := 0.0
		if raw is Dictionary:
			value = float((raw as Dictionary).get("value", 0.0))
		lines.append(
			String(row.get(&"name", String(id))).to_upper()
			+ HOVER_STAT_JOIN
			+ stat_line(
				StringName(str(row.get(&"stat", &""))), value, StringName(str(row.get(&"unit", &"")))
			)
		)
	for raw: Variant in _rows_of(record.get("suffixes")):
		var id := StringName(str(_row_id_of(raw)))
		var suffix: Variant = ModuleCatalog.SUFFIXES.get(id, null)
		if not suffix is Dictionary:
			continue
		var row: Dictionary = suffix
		lines.append(
			String(row.get(&"name", "of " + String(id))).to_upper()
			+ HOVER_STAT_JOIN
			+ String(row.get(&"perk", ""))
		)
	return lines


## One stat as its display line, `fitting_panel.stat_line`'s own rule: the catalogue's key as
## the label and the value in 15 section 3's unit column, or the unit the magnitude implies.
static func stat_line(
	stat_key: StringName, value: float, unit: StringName = &""
) -> String:
	var key := String(stat_key)
	if key.ends_with("_mult") or key.ends_with("_multiplier"):
		return "%s %s%s" % [stat_label(stat_key), HOVER_MULTIPLIER, String.num(value, 2)]
	var text := ""
	match String(unit):
		"percent":
			text = signed_percent(value)
		"points":
			text = "%+d pp" % int(roundf(value * 100.0))
		"units":
			text = signed_number(value)
		_:
			text = signed_percent(value) if absf(value) < 1.0 else signed_number(value)
	return "%s %s" % [stat_label(stat_key), text]


static func stat_label(stat_key: StringName) -> String:
	var words := String(stat_key).to_upper().replace("_", " ")
	for suffix: String in [HOVER_ADD_SUFFIX, HOVER_MULT_SUFFIX, " MULTIPLIER"]:
		if words.ends_with(suffix):
			return words.substr(0, words.length() - suffix.length())
	return words


static func signed_percent(value: float) -> String:
	return "%+d %%" % int(roundf(value * 100.0))


static func signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % int(roundf(value))
	return "%+.2f" % value


func _rows_of(raw: Variant) -> Array:
	return raw as Array if raw is Array else []


func _row_id_of(raw: Variant) -> String:
	if raw is Dictionary:
		return str((raw as Dictionary).get("id", ""))
	if raw is String or raw is StringName:
		return String(raw)
	return ""


## Hovering a plate publishes its line on the channel every hint in this pane uses
## (`status_requested`), and fills the pane's own stat block under the grid; leaving it puts the
## selected hull's own hint back and clears the block, so neither keeps a line for a cell the
## pointer has left.
func _on_plate_hovered(cell: Dictionary) -> void:
	status_requested.emit(hover_line(cell), false)
	_refresh_hover_block(cell)


func _on_plate_unhovered() -> void:
	_clear_hover_block()
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
	if _selected_id == &"" or not _owned_ids(profile).has(_selected_id):
		_selected_id = _default_selection(profile)
	_refresh_rows(profile)
	_refresh_preview(profile)
	_refresh_action(profile)


## Section 5.11's row: the `ACTIVE` badge on the hull the account flies, nothing on any
## other row (every row is an owned hull, so `FOR SALE` and `LOCKED` retired with the buy
## rows).
func _refresh_rows(profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	_tag.text = TAG_ACTIVE_HULL % _ship_name(active_id)
	for payload: Dictionary in _payloads:
		var tag: Label = payload[&"tag"]
		tag.text = STATE_ACTIVE if payload[&"id"] == active_id else ""


func _refresh_preview(profile: ProfileScript) -> void:
	var ship := Catalog.ship(_selected_id)
	if ship.is_empty():
		_preview_image.texture = null
		_native_preview = Vector2.ZERO
		_preview_image.custom_minimum_size = Vector2.ZERO
		_preview_name.text = PREVIEW_EMPTY
		_preview_caption.text = ""
		_refresh_comparison({}, profile)
		_set_layout_grid(&"")
		return
	var texture := load(String(ship.get(&"preview", ""))) as Texture2D
	_preview_image.texture = texture
	_native_preview = texture.get_size() if texture != null else Vector2.ZERO
	_preview_name.text = String(ship.get(&"name", String(_selected_id)))
	_preview_caption.text = String(ship.get(&"description", ""))
	_update_preview_size()
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


## The footer's one action: `SET ACTIVE` for an owned hull that is not the active one,
## `IN SERVICE` (disabled) for the active one, and disabled with `SET ACTIVE` when no hull
## is owned at all. It is the pane's sole commit (section 5.11); selecting never reaches it.
func _refresh_action(profile: ProfileScript) -> void:
	_action.text = ACTION_SET_ACTIVE
	if _selected_id == &"" or not _owned_ids(profile).has(_selected_id):
		_action.disabled = true
		return
	_action.disabled = _selected_id == _active_id(profile)
	if _action.disabled:
		_action.text = ACTION_IN_SERVICE


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_preview_row(payload)


## Selecting a row previews it and writes nothing (section 5.11: "selecting a row previews
## ... and writes nothing; the footer SET ACTIVE is the sole commit"). The press is the
## row's `pressed`, the focus is the ring - both go through `_preview_row`.
func _on_row_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_preview_row(payload)


func _on_action_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_act(_selected_id)


## The selection itself: the previewed hull moves, the three preview readers move with it,
## and the hint names the hull now previewed. Nothing here touches the profile.
func _preview_row(payload: Dictionary) -> void:
	var profile := _profile()
	_selected_id = payload[&"id"]
	_refresh_preview(profile)
	_refresh_action(profile)
	status_requested.emit(_row_hint(payload), false)


## The pane's one write: `set_active_ship` for the previewed hull, which the profile
## refuses for a hull the account does not own or already flies (it announces that itself,
## section 5.6). A refusal writes nothing and leaves the selection where it was; the refusals
## the pane can see are the ones its own footer state already prevents.
func _act(ship_id: StringName) -> void:
	var profile := _profile()
	if profile == null:
		return
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return
	if not bool(profile.call(&"set_active_ship", ship_id)):
		_pulse(_action)
		_refresh_all()
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_ACTIVE % _ship_name(ship_id), false)
	_refresh_all()


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		String(ShipFit.HULLS.get(payload[&"id"], {}).get(&"ship_class", "")).to_upper(),
	]


## The hull the preview opens on: the active hull when the account owns it, else the first
## owned hull of the ladder, else nothing (an account that owns no hull at all).
func _default_selection(profile: ProfileScript) -> StringName:
	var active_id := _active_id(profile)
	if _owned_ids(profile).has(active_id):
		return active_id
	var roster := _owned_roster(profile)
	return roster[0] if not roster.is_empty() else &""


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
