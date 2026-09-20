extends VBoxContainer
## UPGRADES module panel: one row per StationCatalog.UPGRADES entry, installed state read
## from PlayerProfile. Contract: docs/design/STATION_HUB.md sections 5.3, 5.6 and 12,
## docs/design/STATION_SPEC.md sections 2.5 and 6.
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
const COL_ICON := 40.0
const COL_EFFECT := 300.0
const COL_PRICE := 110.0
const COL_TAG := 160.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const HEADER_UPGRADE := "UPGRADE"
const HEADER_EFFECT := "EFFECT"
const HEADER_PRICE := "PRICE"
const HEADER_STATUS := "STATUS"
const PRICE_CAPTION := "CREDITS"
const SLOT_CAPTION := "SLOT %s"
const SUBTITLE := "PERMANENT REFITS · %d SLOTS · ONE UPGRADE PER SLOT"
const TAG_FILLED := "%d / %d SLOTS FILLED"
const FOOTER_DEFAULT := "INSTALLING CHARGES CREDITS AND IS PERMANENT FOR V1"
const FOOTER_COMPLETE := "EVERY SLOT IS FILLED · NO UNINSTALL API IN V1"

const EFFECT_JOIN := " · "
const EFFECT_FORMAT := "%s +%d%%"
const EFFECT_PERCENT := 100.0
const EFFECT_NONE := "NO EFFECT DATA"

const EFFECT_LABELS: Dictionary = {
	&"shield_regen": "SHIELD REGEN",
	&"energy_regen": "ENERGY REGEN",
	&"shield_max": "SHIELD MAX",
	&"speed": "SPEED",
	&"scanner_range": "SCANNER RANGE",
	&"cargo_max": "CARGO MAX",
	&"hull_repair_rate": "HULL REPAIR",
}

const TAG_INSTALLED := "INSTALLED"
const TAG_AVAILABLE := "AVAILABLE"
const TAG_LOCKED := "LOCKED"
const TAG_UNAVAILABLE := "STOCK UNAVAILABLE"
const META_INCOMPLETE := "CATALOGUE ENTRY INCOMPLETE"

const STATUS_HINT := "ENTER INSTALL · %s · %s CREDITS"
const STATUS_INSTALLED := "INSTALLED · %s · PERMANENT FOR V1"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _header: HBoxContainer = %UpgradesHeader
@onready var _scroll: ScrollContainer = %UpgradesScroll
@onready var _rows: VBoxContainer = %UpgradeRows
@onready var _footer: Label = %PaneFooter

var _payloads: Array[Dictionary] = []
var _selected_row: Button = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_header()
	_build_rows()
	_apply_tokens()
	_connect_scroll()
	_refresh_rows()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"credits" moves every price and tag, &"upgrades" decides
	## which rows are INSTALLED. Every other key belongs to another panel.
	if key == &"credits" or key == &"upgrades":
		_refresh_rows()


func focus_primary() -> void:
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return


func _apply_tokens() -> void:
	for payload: Dictionary in _payloads:
		var icon: TextureRect = payload[&"icon"]
		if icon != null:
			icon.modulate = Color(1.0, 1.0, 1.0, ROW_ICON_IDLE_ALPHA)


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_header() -> void:
	_subtitle.text = SUBTITLE % Catalog.UPGRADES.size()
	for cell: Dictionary in _header_cells():
		_header.add_child(_make_header_cell(cell))


func _header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": HEADER_UPGRADE, &"width": 0.0, &"expand": true},
		{&"text": HEADER_EFFECT, &"width": COL_EFFECT, &"expand": false},
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
	for upgrade: Dictionary in Catalog.UPGRADES:
		_payloads.append(_build_row(upgrade))
	_add_slack()


func _build_row(upgrade: Dictionary) -> Dictionary:
	var upgrade_id: StringName = upgrade.get(&"id", &"")
	var name_text := String(upgrade.get(&"name", ""))
	var cost := int(upgrade.get(&"cost", 0))
	var complete := upgrade_id != &"" and not name_text.is_empty() and cost >= 0
	var row := Button.new()
	row.name = "Upgrade%s" % String(upgrade_id).trim_prefix("upgrade_").to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = not complete
	row.set_meta(&"id", upgrade_id)
	var box := _make_inner(row)
	var icon := _make_icon(String(upgrade.get(&"icon", "")))
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, String(upgrade.get(&"slot", &"")), complete))
	var effect := _make_cell(box, COL_EFFECT, "", HEADER_EFFECT, "Effect")
	var price := _make_cell(box, COL_PRICE, "", PRICE_CAPTION, "Price")
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	if complete:
		effect[0].text = _effect_text(upgrade.get(&"effect", {}))
		effect[0].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var payload := {
		&"id": upgrade_id,
		&"name": name_text,
		&"cost": cost,
		&"complete": complete,
		&"row": row,
		&"icon": icon,
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


func _make_title_box(name_text: String, slot: StringName, complete: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text if complete else TAG_UNAVAILABLE)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(
		&"StationCaption",
		SLOT_CAPTION % String(slot).to_upper() if complete else META_INCOMPLETE
	)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _effect_text(effect: Variant) -> String:
	if not effect is Dictionary or (effect as Dictionary).is_empty():
		return EFFECT_NONE
	var parts := PackedStringArray()
	for key: Variant in (effect as Dictionary):
		var effect_key := StringName(str(key))
		var label := String(EFFECT_LABELS.get(effect_key, String(effect_key).to_upper()))
		var fraction := float((effect as Dictionary)[key])
		parts.append(EFFECT_FORMAT % [label, roundi(fraction * EFFECT_PERCENT)])
	return EFFECT_JOIN.join(parts)


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


func _make_icon(icon_path: String) -> TextureRect:
	if icon_path.is_empty():
		return null
	## The six equipment glyphs are painted RGBA art (STATION_HUB section 7.1 lists them
	## untinted and drawn at full colour), unlike the three flat Phase B glyphs the
	## OUTFITTING rows have to tint (ASSET_AUDIT anomaly C16).
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(icon_path)
	icon.modulate = Color(1.0, 1.0, 1.0, ROW_ICON_IDLE_ALPHA)
	return icon


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_child(slack)


func _connect_scroll() -> void:
	if _scroll.has_signal(&"scroll_started"):
		_scroll.connect(&"scroll_started", _on_scroll_started)


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
	var installed := bool(
		profile.call(&"install_upgrade", payload[&"id"], int(payload[&"cost"]))
	)
	if not installed:
		## The refusal text and the denied cue belong to the shell, which hears
		## purchase_failed; the row only marks its own price cell (section 5.6).
		_pulse(payload[&"price"] as Label)
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_INSTALLED % String(payload[&"name"]).to_upper(), false)


func _refresh_rows() -> void:
	var profile := _profile()
	var installed_count := 0
	if profile != null:
		installed_count = int(profile.call(&"installed_upgrades").size())
	_tag.text = TAG_FILLED % [installed_count, Catalog.UPGRADES.size()]
	_footer.text = FOOTER_COMPLETE if installed_count >= Catalog.UPGRADES.size() else FOOTER_DEFAULT
	for payload: Dictionary in _payloads:
		_refresh_row(payload, profile)


func _refresh_row(payload: Dictionary, profile: ProfileScript) -> void:
	var price: Label = payload[&"price"]
	var tag: Label = payload[&"tag"]
	if not bool(payload[&"complete"]):
		price.text = ""
		price.remove_theme_color_override(&"font_color")
		tag.text = TAG_UNAVAILABLE
		return
	var cost := int(payload[&"cost"])
	var affordable := profile == null or bool(profile.call(&"can_afford", cost))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	price.text = _format_int(cost)
	if profile != null and bool(profile.call(&"has_upgrade", payload[&"id"])):
		tag.text = TAG_INSTALLED
	elif affordable:
		tag.text = TAG_AVAILABLE
	else:
		tag.text = TAG_LOCKED


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


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
