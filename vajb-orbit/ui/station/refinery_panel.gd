extends VBoxContainer
## REFINERY module panel: one row per mineral with ore to convert, the conversion
## stepper, the batch totals and the two action buttons. Contract:
## docs/design/STATION_HUB.md sections 3.1, 5.6, 5.7 and 12.3/12.4,
## docs/gameplay/04_refinery.md section 5.
##
## The station shell loads this scene into its host, so the panel never routes and never
## writes the profile: it emits status_requested up, reads Refinery / MineralCatalog /
## PlayerProfile down, and every printed number is a Refinery or MineralCatalog read
## (04 section 5: the panel hardcodes no price).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     ui_cancel step 2 / CANCEL
##
## Selection is arming (04 section 5: a stepper is not a transaction, only the two action
## buttons are): a row takes the selection on focus or press, the stepper spans
## 1..Refinery.convertible(id) and every stepper tick only rewrites the totals.
##
## Refinery.refine() emits profile_changed(&"cargo") / (&"credits") from inside the
## transaction, so the shell forwards a refresh into this panel while its own button
## handler is still on the stack. A rebuild there would free the row the signal chain is
## walking, so a &"cargo" refresh seen mid-transaction is deferred to one rebuild right
## after the call returns, and the handler captures its name / count / fee first.

const TOKENS_TYPE: StringName = &"Tokens"

const RefineryModule := preload("res://game/refinery.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

const ROW_HEIGHT := 76.0
const COL_ICON := 40.0
const COL_ORE := 130.0
const COL_INGOTS := 110.0
const COL_FEE := 160.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09

## STATION_HUB section 12.3 fixes the RefineBox geometry (box 360, stepper plates 48,
## totals value column 220): those are static rects, so they live in the scene file as the
## one source and are not mirrored here. Fix Wave 1 W2.3 raised all three action buttons
## to one height: REFINE N keeps section 5.7's 88 px primary height (the LaunchButton
## height) and the two secondary plates are 88 px in the scene as well, so the column no
## longer stacks an 88 px plate over two 56 px ones. The width is already shared: all three
## are children of RefineBox, a VBoxContainer. All three heights stay scene values and no
## code mirrors them (W6-3).
const STEPPER_MIN := 1

const HEADER_MINERAL := "MINERAL"
const HEADER_ORE := "ORE"
const HEADER_INGOTS := "INGOTS"
const HEADER_FEE := "FEE"
const TAG_FORMAT := "%d STACKS · %d CONVERSIONS READY"
const TAG_EMPTY := "NO CONVERTIBLE STACKS"
const SELECTED_NONE := "NO STACK SELECTED"
const STEPPER_FORMAT := "%d CONVERSIONS"
const STEPPER_IDLE := "0 CONVERSIONS"
const ORE_HELD_FORMAT := "%d ORE HELD"
const FEE_FORMAT := "%s CR"
const ZERO_TEXT := "0"
const REFINE_FORMAT := "REFINE %d"
const EMPTY_ROW := "NO ORE TO REFINE"
const FOOTER_FORMAT := "%d ORE = 1 INGOT · FEE %d CR PER CONVERSION"
const FOOTER_EMPTY := "BRING RAW ORE FROM THE BELT"

## Status strip copy (STATION_HUB section 5.7 wording, section 5.6 the refusal shape). The
## fee text always comes from Refinery.fee_for, never from the module's `fee` field, which
## is 0 on a refusal because nothing was charged.
const STATUS_READY := "READY · %s · %d CONVERSIONS · %s FEE"
const STATUS_REFINED := "REFINED · %s · %d INGOTS · %s CR FEE"
const STATUS_REFINED_ALL := "REFINED · ALL ORE · %d INGOTS · %s CR FEE"
const STATUS_REFUSED_CREDITS := "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"
const STATUS_REFUSED_ORE := "REFUSED · NOT ENOUGH ORE · %s NEEDED"
const STATUS_REFUSED_COUNT := "REFUSED · NO CONVERSIONS SELECTED"
const STATUS_REFUSED_EMPTY := "REFUSED · NO ORE TO REFINE"
const STATUS_REFUSED_UNKNOWN := "REFUSED · UNKNOWN MINERAL"
const STATUS_IDLE := "REFINERY IDLE · SELECT A STACK"

const TINT_DIR := "res://assets/icons/tint/"
## ICONS_SPEC §8.1 names the dedicated ore glyphs `icon_mineral_<id>_48.png`. A mineral that
## carries one is drawn with that art as it is: the file name is the one signal that tells a
## dedicated glyph apart from the generic fallback, because `derive_icon_tints` writes a
## tint/ stencil for every icon in the set, dedicated family included.
const DEDICATED_ICON_PREFIX := "icon_mineral_"

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _tag: Label = %PanelTag
@onready var _header: HBoxContainer = %RefineryHeader
@onready var _scroll: ScrollContainer = %RefineryScroll
@onready var _rows: VBoxContainer = %RefineryRows
@onready var _selected_name: Label = %SelectedName
@onready var _stepper_less: Button = %StepperLess
@onready var _stepper_value: Label = %StepperValue
@onready var _stepper_more: Button = %StepperMore
@onready var _ore_in: Label = %OreInValue
@onready var _ingots_out: Label = %IngotsOutValue
@onready var _fee_value: Label = %FeeValue
@onready var _refine_button: Button = %RefineButton
@onready var _refine_all_button: Button = %RefineAllButton
@onready var _cancel_button: Button = %CancelButton
@onready var _footer: Label = %PaneFooter

var _payloads: Array[Dictionary] = []
var _selected_id: StringName = &""
var _selected_row: Button = null
var _stepper: int = STEPPER_MIN
var _stepper_max: int = STEPPER_MIN
var _transaction := false
var _rebuild_pending := false
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_header()
	_build_rows()
	_apply_tokens()
	_wire_controls()
	_connect_scroll()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"cargo" rebuilds the table (a stack that falls below 3
	## ore leaves it), &"credits" only moves the affordability colour. Every other key
	## belongs to another panel.
	if key == &"cargo":
		if _transaction:
			_rebuild_pending = true
			return
		_build_rows()
	elif key == &"credits":
		_refresh_affordability()


func focus_primary() -> void:
	## A disabled control must not take the ring: when nothing enabled can, the panel
	## returns without grabbing and the shell's rail fallback runs (station.gd:401-410).
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _refine_button.disabled:
		_refine_button.grab_focus()
		return
	if not _refine_all_button.disabled:
		_refine_all_button.grab_focus()


func disarm() -> bool:
	## ui_cancel step 2 (STATION_HUB section 2) and the CANCEL button: the selection is
	## the only thing this panel arms, so clearing it is the whole disarm.
	if _selected_id == &"":
		return false
	_clear_selection()
	return true


func _wire_controls() -> void:
	_stepper_less.pressed.connect(_on_stepper_pressed.bind(-1))
	_stepper_more.pressed.connect(_on_stepper_pressed.bind(1))
	_refine_button.pressed.connect(_on_refine_pressed)
	_refine_all_button.pressed.connect(_on_refine_all_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func _connect_scroll() -> void:
	if _scroll.has_signal(&"scroll_started"):
		_scroll.connect(&"scroll_started", _on_scroll_started)


func _apply_tokens() -> void:
	_pane_icon.modulate = _token(&"text_primary")
	for payload: Dictionary in _payloads:
		var icon: TextureRect = payload[&"icon"]
		if icon != null:
			icon.modulate = payload[&"tint"]


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_header() -> void:
	for cell: Dictionary in _header_cells():
		_header.add_child(_make_header_cell(cell))


func _header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": HEADER_MINERAL, &"width": 0.0, &"expand": true},
		{&"text": HEADER_ORE, &"width": COL_ORE, &"expand": false},
		{&"text": HEADER_INGOTS, &"width": COL_INGOTS, &"expand": false},
		{&"text": HEADER_FEE, &"width": COL_FEE, &"expand": false},
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
	## Every row is rebuilt, because the row set is the stack set: RowInner is created
	## again rather than refreshed in place, so a conversion that left less than 3 ore
	## removes its row here and nowhere else (04 section 2).
	_clear_rows()
	_selected_row = null
	var stacks := _stacks()
	if stacks.is_empty():
		_selected_id = &""
		_stepper = STEPPER_MIN
		_stepper_max = STEPPER_MIN
		_build_empty_row()
	else:
		for stack: Dictionary in stacks:
			_payloads.append(_build_row(stack))
		_add_slack()
		_reselect()
	_rebuild_pending = false
	_refresh_tag()
	_refresh_footer()
	_refresh_box()
	_refresh_affordability()


func _clear_rows() -> void:
	_payloads.clear()
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()


func _build_empty_row() -> void:
	var row := Button.new()
	row.name = "EmptyRow"
	row.disabled = true
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	var box := _make_inner(row)
	var label := Label.new()
	label.name = "EmptyCaption"
	label.theme_type_variation = &"StationCaption"
	label.text = EMPTY_ROW
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	_rows.add_child(row)


func _build_row(stack: Dictionary) -> Dictionary:
	var mineral_id: StringName = stack.get(&"mineral_id", &"")
	var entry: Dictionary = stack.get(&"entry", {})
	var name_text := String(entry.get(&"name", String(mineral_id)))
	var ore_qty := int(stack.get(&"ore_qty", 0))
	var conversions := int(stack.get(&"conversions", 0))
	var fee := int(stack.get(&"fee", 0))
	var row := Button.new()
	row.name = "Ore%s" % String(mineral_id).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", mineral_id)
	var box := _make_inner(row)
	var icon := _make_icon(entry)
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, ore_qty))
	var ore := _make_value_cell(box, COL_ORE, "Ore")
	ore.text = _format_int(ore_qty)
	var ingots := _make_value_cell(box, COL_INGOTS, "Ingots")
	ingots.text = _format_int(conversions)
	var fee_cell := _make_value_cell(box, COL_FEE, "Fee")
	fee_cell.text = FEE_FORMAT % _format_int(fee)
	var payload := {
		&"id": mineral_id,
		&"name": name_text,
		&"entry": entry,
		&"ore": ore_qty,
		&"conversions": conversions,
		&"fee": fee,
		&"row": row,
		&"icon": icon,
		&"tint": _icon_tint(entry),
		&"fee_value": fee_cell,
	}
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_rows.add_child(row)
	return payload


func _make_title_box(name_text: String, ore_qty: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(&"StationCaption", ORE_HELD_FORMAT % ore_qty)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _make_value_cell(parent: HBoxContainer, width: float, cell_name: String) -> Label:
	var label := _make_label(&"StationValue", "")
	label.name = cell_name
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(label)
	return label


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


func _make_icon(entry: Dictionary) -> TextureRect:
	var icon_path := _icon_source(entry)
	if icon_path.is_empty():
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(icon_path)
	icon.modulate = _icon_tint(entry)
	return icon


func _icon_source(entry: Dictionary) -> String:
	## All icon families are single-colour silhouettes, so the white tint/ stencil is the
	## render source whenever one exists; the dedicated Phase F ore glyph (ICONS_SPEC §8.1)
	## then takes neutral state ink and the generic 02 §6 fallback its tier tint. The master
	## path is the last resort for art without a derived stencil.
	var icon_path := String(entry.get(&"icon_ore", ""))
	if icon_path.is_empty():
		return ""
	var stencil := TINT_DIR + icon_path.get_file()
	if stencil != icon_path and ResourceLoader.exists(stencil):
		return stencil
	return icon_path


func _icon_tint(entry: Dictionary) -> Color:
	var ink: Color = Color.WHITE
	var source := _icon_source(entry)
	if source.begins_with(TINT_DIR):
		if source.get_file().begins_with(DEDICATED_ICON_PREFIX):
			ink = _token(&"text_primary")
		else:
			var raw: Variant = Catalog.TIER_TINTS.get(int(entry.get(&"tier", 0)))
			if raw is Color:
				ink = raw
	ink.a = ROW_ICON_IDLE_ALPHA
	return ink


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_child(slack)


func _reselect() -> void:
	## A rebuild keeps the selection when that mineral still has a convertible stack
	## (Refinery.refine of a partial batch), and clears it when the stack is gone.
	if _selected_id == &"":
		return
	for payload: Dictionary in _payloads:
		if payload[&"id"] == _selected_id:
			_arm(payload, false)
			return
	_selected_id = &""
	_stepper = STEPPER_MIN
	_stepper_max = STEPPER_MIN


func _arm(payload: Dictionary, cue: bool) -> void:
	var row: Button = payload[&"row"]
	if row == _selected_row and _selected_id == payload[&"id"]:
		return
	if cue:
		AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_selected_id = payload[&"id"]
	_stepper_max = maxi(STEPPER_MIN, int(payload[&"conversions"]))
	_stepper = _stepper_max
	_refresh_box()
	_refresh_affordability()


func _clear_selection() -> void:
	if _selected_row != null and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = null
	_selected_id = &""
	_stepper = STEPPER_MIN
	_stepper_max = STEPPER_MIN
	_refresh_box()
	_refresh_affordability()


func _refresh_box() -> void:
	var armed := _selected_id != &""
	if armed:
		_selected_name.text = _selected_name_text().to_upper()
		_stepper_value.text = STEPPER_FORMAT % _stepper
	else:
		_selected_name.text = SELECTED_NONE
		_stepper_value.text = STEPPER_IDLE
	_refine_button.text = REFINE_FORMAT % _stepper
	_stepper_less.disabled = not armed or _stepper <= STEPPER_MIN
	_stepper_more.disabled = not armed or _stepper >= _stepper_max
	_refine_button.disabled = not armed
	_refine_all_button.disabled = _payloads.is_empty()
	_cancel_button.disabled = not armed
	_ore_in.text = _format_int(_stepper * RefineryModule.ORE_PER_INGOT) if armed else ZERO_TEXT
	_ingots_out.text = _format_int(_stepper) if armed else ZERO_TEXT
	_fee_value.text = FEE_FORMAT % _format_int(_selected_fee() if armed else 0)


func _refresh_affordability() -> void:
	## STATION_HUB section 5.6 channel 1 is presentation only: the price is red when the
	## balance cannot cover it and the profile still decides the outcome on the press.
	var profile := _profile()
	var armed := _selected_id != &""
	_colour_fee(_fee_value, profile, _selected_fee() if armed else 0)
	for payload: Dictionary in _payloads:
		var cell: Label = payload[&"fee_value"]
		_colour_fee(cell, profile, int(payload[&"fee"]))


func _colour_fee(cell: Label, profile: ProfileScript, fee: int) -> void:
	if profile != null and not bool(profile.call(&"can_afford", fee)):
		cell.add_theme_color_override(&"font_color", _token(&"accent_danger"))
		return
	cell.remove_theme_color_override(&"font_color")


func _refresh_tag() -> void:
	var stacks := _stacks()
	if stacks.is_empty():
		_tag.text = TAG_EMPTY
		return
	var conversions := 0
	for stack: Dictionary in stacks:
		conversions += int(stack.get(&"conversions", 0))
	_tag.text = TAG_FORMAT % [stacks.size(), conversions]


func _refresh_footer() -> void:
	if _payloads.is_empty():
		_footer.text = FOOTER_EMPTY
		return
	_footer.text = FOOTER_FORMAT % [
		RefineryModule.ORE_PER_INGOT,
		RefineryModule.FEE_PER_CONVERSION,
	]


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	_arm(payload, true)
	status_requested.emit(
		STATUS_READY % [
			String(payload[&"name"]).to_upper(),
			int(payload[&"conversions"]),
			_format_int(int(payload[&"fee"])),
		],
		false,
	)


func _on_row_pressed(payload: Dictionary) -> void:
	## Focus selects first on a mouse or keyboard entry, so the press only cues and arms
	## when it actually moves the selection.
	_arm(payload, true)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


func _on_stepper_pressed(step: int) -> void:
	if _selected_id == &"":
		return
	var next := clampi(_stepper + step, STEPPER_MIN, _stepper_max)
	if next == _stepper:
		return
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)
	_stepper = next
	_refresh_box()
	_refresh_affordability()


func _on_cancel_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if disarm():
		status_requested.emit(STATUS_IDLE, false)


func _on_refine_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null or _selected_id == &"":
		return
	## Captured before the call: Refinery.refine emits profile_changed while it runs, and
	## the deferred rebuild below may clear the selection out from under this handler.
	var mineral_id := _selected_id
	var name_text := _selected_name_text()
	var conversions := _stepper
	var fee := RefineryModule.fee_for(conversions)
	_transaction = true
	var result: Dictionary = RefineryModule.refine(profile, mineral_id, conversions)
	_transaction = false
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		_finish_rebuild()
		status_requested.emit(
			STATUS_REFINED % [name_text.to_upper(), conversions, _format_int(fee)], false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_finish_rebuild()
	status_requested.emit(_refusal_text(result.get(&"reason", &""), fee, conversions), true)


func _on_refine_all_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	var stacks := _stacks()
	if stacks.is_empty():
		AudioManager.play_ui(AudioManager.UiCue.DENIED)
		status_requested.emit(STATUS_REFUSED_EMPTY, true)
		return
	## One fee for the whole batch (04 section 2), summed from the same stacks the rows
	## were drawn from, so the quoted fee matches the table the player is looking at.
	var fee := 0
	for stack: Dictionary in stacks:
		fee += int(stack.get(&"fee", 0))
	_transaction = true
	var result: Dictionary = RefineryModule.refine_all(profile)
	_transaction = false
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		_finish_rebuild()
		status_requested.emit(
			STATUS_REFINED_ALL % [int(result.get(&"ingots", 0)), _format_int(fee)], false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_finish_rebuild()
	status_requested.emit(
		_refusal_text(result.get(&"reason", &""), fee, int(result.get(&"conversions", 0))), true
	)


func _finish_rebuild() -> void:
	## Called straight after a transaction returns, so the panel is never left waiting on a
	## rebuild that a signal already asked for.
	_transaction = false
	if not _rebuild_pending:
		return
	_rebuild_pending = false
	_build_rows()


func _refusal_text(reason: Variant, fee: int, conversions: int) -> String:
	var key := StringName(reason)
	if key == &"insufficient_credits":
		return STATUS_REFUSED_CREDITS % _format_int(fee)
	if key == &"insufficient_ore":
		return STATUS_REFUSED_ORE % _format_int(conversions * RefineryModule.ORE_PER_INGOT)
	if key == &"invalid_count":
		return STATUS_REFUSED_COUNT
	if key == &"nothing_to_refine":
		return STATUS_REFUSED_EMPTY
	return STATUS_REFUSED_UNKNOWN


func _selected_fee() -> int:
	return RefineryModule.fee_for(_stepper)


func _selected_name_text() -> String:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == _selected_id:
			return String(payload[&"name"])
	return ""


func _stacks() -> Array[Dictionary]:
	var profile := _profile()
	if profile == null:
		var none: Array[Dictionary] = []
		return none
	return RefineryModule.stacks(profile)


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
