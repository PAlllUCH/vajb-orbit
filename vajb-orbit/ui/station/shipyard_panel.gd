extends VBoxContainer
## SHIPYARD module panel: the hull list, the large side-view preview, the comparison table
## against the active hull, the price and the BUY / SET ACTIVE action. Every value is a
## StationCatalog or PlayerProfile read. Contract: docs/design/STATION_HUB.md sections 5.2,
## 5.6, 7.2 and 12, docs/design/STATION_SPEC.md sections 2.4 and 6.
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

const HARDPOINT_PLATES := 7
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4

const PREVIEW_SCALE := 0.70
const PREVIEW_MAX_WIDTH := 480.0

const STAT_ROWS: Array[Dictionary] = [
	{&"key": &"hull", &"label": "HULL"},
	{&"key": &"shield", &"label": "SHIELD"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"hardpoints", &"label": "HARDPOINTS"},
]
const COMPARISON_CAPTION := "COMPARISON"
const COMPARISON_SELECTED := "SELECTED"
const COMPARISON_ACTIVE := "ACTIVE"

const SUBTITLE := "BUY AND SWITCH HULLS · %d IN THE CRADLE · SIDE VIEWS ONLY"
const TAG_ACTIVE_HULL := "ACTIVE HULL %s"
const META_FORMAT := "%d HULL · %d HP"
const HARDPOINT_CAPTION := "HARDPOINT PLATES · %d MAXIMUM"
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
@onready var _hardpoints: HBoxContainer = %HardpointSlots
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
	_build_hardpoints()
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
	var meta := META_FORMAT % [int(ship.get(&"hull", 0)), int(ship.get(&"hardpoints", 0))]
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


func _build_hardpoints() -> void:
	_hardpoint_caption.text = HARDPOINT_CAPTION % HARDPOINT_PLATES
	_hardpoints.add_theme_constant_override(&"separation", PLATE_SEPARATION)
	for index in HARDPOINT_PLATES:
		var plate := _make_plate(_hardpoints, PLATE_VARIATION, PLATE_SIZE)
		plate.name = "Hardpoint%02d" % (index + 1)
		plate.disabled = true


func _make_plate(parent: HBoxContainer, variation: StringName, plate_size: float) -> TextureButton:
	# ui/components/slot_button.gd copies the theme plate textures onto the node, because a
	# TextureButton has no stylebox items, so SlotButtonWeapon/styles/* is never read by the
	# engine on a bare theme_type_variation. The panel repeats that lookup (the mockup's own
	# construct) so the strip also renders without instancing the HUD component.
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
		_set_hardpoints(0)
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
	_set_hardpoints(int(ship.get(&"hardpoints", 0)))


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
	var active := Catalog.ship(_active_id(profile))
	for stat: Dictionary in STAT_ROWS:
		var cells: Array = _stat_cells.get(stat[&"key"], [])
		if cells.size() < 2:
			continue
		var selected_value := int(ship.get(stat[&"key"], 0))
		var active_value := int(active.get(stat[&"key"], 0))
		var selected_label: Label = cells[0]
		var active_label: Label = cells[1]
		selected_label.text = str(selected_value)
		active_label.text = str(active_value)
		if selected_value < active_value:
			selected_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
		else:
			selected_label.remove_theme_color_override(&"font_color")


func _set_hardpoints(count: int) -> void:
	for index in _hardpoints.get_child_count():
		var plate := _hardpoints.get_child(index) as TextureButton
		if plate != null:
			plate.disabled = index >= count


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
