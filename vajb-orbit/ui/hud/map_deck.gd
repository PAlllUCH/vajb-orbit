class_name MapDeck
extends PanelContainer
## S29 A1/A2 (UI_SPEC.md section 9 N1-N6 and section 10 N7-N23): the map deck and the
## navigation pin. One `PanelContainer` on A5.4's `Pane outer edge` chrome
## (`PanelRaised` = `ui_panel_frame`, band 32) centred at 80 % of the viewport (N1's
## anchors 0.1..0.9 - relative positioning, never coordinates), holding one HBox: the
## map viewport (the compact map's own classes and drawing law, `minimap.gd`) beside
## the filter column (`custom_minimum_size (240, 0)`, PROPOSED per section 10), and a
## caption-strip foot (A5.4-3) carrying the zoom read (N8), the hint (N9) and the N5
## reads (N11-N13). Toggle paths are M (N1), the compact footer's EXPAND button (hud.gd)
## and ESC (game.gd's `ui_cancel` poll).
##
## The pin law (the fixer's, UI_SPEC.md section 10): a press that hit-tests the pin is a
## remove candidate and never a place or move; the pin is placed at press-down and never
## follows the cursor; a held move past N14's 8 px threshold is a pan; a short press
## issues the existing autopilot order (`set_move_target`, `player_ship.gd:419`) and a
## short press on the pin removes it and cancels orders (`cancel_orders`,
## `player_ship.gd:433`); hold LMB >= 0.5 s is the hyperdrive jump (N4/N5), armed from
## press-down on a fresh pin and on the existing pin alike.
##
## Composition is A5.1-A5.4 throughout: containers + anchors, chrome by the per-surface
## rows (Pane outer edge / A5.4-2 service-strip rows / A5.4-3 caption strip), code-drawn
## marks only inside their own child rects, shipped chrome and Tokens only.

signal pin_changed(pin: Variant)
signal autopilot_to(pos: Vector2)
signal autopilot_cancel()
signal jump_requested(pos: Vector2)
signal filters_changed(state: Dictionary)

const MinimapScript := preload("res://ui/hud/minimap.gd")

const PANE_VARIATION: StringName = &"PanelRaised"
## D8-H3's pinned 12 px cap floor (`test_d8_hud_visibility.gd`'s FONT_FLOOR_TABLE,
## first-match `*` = 12 px over every HUD Label) rules both wireframe label cites out
## of the deck: `StationCaption` 13 measures 9.00 px cap and `StationValue` 18
## measures 11.574 px (Rajdhani's 643/1000 cap). Every deck label takes the HUD's own
## `HudReadout` 18 (12.42 px, the variation the compact footer's `SectorLabel` wears);
## the A5.4-2 row shape (Button + inner margin + label/state line) is unchanged.
## Reversal: relax the floor row and return to the wireframe's StationValue/13 cites.
const ROW_VARIATION: StringName = &"HudReadout"
const CAPTION_VARIATION: StringName = &"HudReadout"
const HEADER_VARIATION: StringName = &"HudReadout"
const TOKEN_TEXT_DIM: StringName = &"text_dim"

## N1's three routes: the `map_toggle` action (the `project.godot` row is
## orchestrator-applied at close-out - the `ship_status` precedent, `hud.gd:883`) and a
## raw M while the project carries no row, so N1's key works before the row lands.
const MAP_TOGGLE_ACTION: StringName = &"map_toggle"

## A5.4's pane rule Q1: the `ui_panel_frame` band is 32-33 px, so pane content sits at
## the pane row's side inset (HostMargin 20 + console inset 16 = 36) inside it.
const PANE_MARGIN := 36
## The filter column's `custom_minimum_size (240, 0)` (section 10, PROPOSED; reversal
## `(180, 0)`) and the A5.4-2 row height `min (0, 56)`.
const FILTER_MIN_WIDTH := 240.0
const ROW_MIN_HEIGHT := 56.0
## The auction tab idiom's inner margin (`auction_panel.gd:103`), which keeps a row's
## label off its bevel.
const ROW_INNER := Vector2i(12, 6)
## The compact footer's own button idiom (36x36, `hud.tscn:409-431`).
const BUTTON_SIZE := 32.0 + 4.0

const FILTERS_CAPTION := "MAP FILTERS"
const ZOOM_FORMAT := "ZOOM %d%%"
const HINT_TEXT := "DRAG PAN · WHEEL ZOOM · CLICK PIN · HOLD JUMP"

## N2's 64 px arrow steps and N14's 8 px press->drag threshold.
const ARROW_STEP_PX := 64.0
const DRAG_THRESHOLD_PX := 8.0
## N4's hold (0.5 s), the tick's own number.
const HOLD_SECONDS := 0.5

## N3's per-profile persistence: the eight toggles ride the existing `PlayerProfile`
## save (`user://profile.cfg`). **S30's R-S30-2 (T-102's default): the profile now owns a
## first-class `map_filters` door** (`player_profile.gd`), so this file no longer borrows
## the private `_config` (the S29-B1 borrow is retired). Reversal: keep the borrow.
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const ROLE_NONE := 0
const ROLE_PLACE := 1
const ROLE_REMOVE := 2

var _map: Control = null
var _filter_column: VBoxContainer = null
var _filter_states: Dictionary = {}
var _jump_read: Label = null
var _zoom_read: Label = null
var _hint_read: Label = null

var _pressing := false
var _press_role := ROLE_NONE
var _press_from := Vector2.ZERO
var _press_time := 0.0
var _dragging := false
var _hold_fired := false


func _ready() -> void:
	theme_type_variation = PANE_VARIATION
	## N1's 80 % centred pane: anchors are the viewport's own fractions, so the pane
	## keeps its share at every resolution (A5.2(i) - containers + anchors, and here the
	## anchors themselves carry the relative size).
	anchor_left = 0.1
	anchor_top = 0.1
	anchor_right = 0.9
	anchor_bottom = 0.9
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_load_filters()
	_build()
	_map.set_filters(_filter_states)


func _input(event: InputEvent) -> void:
	if _is_map_toggle(event):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	## N2's arrow panning runs in `_input` on purpose: it must outrank the focus
	## navigation a focused filter row would otherwise give the same keys.
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var step := Vector2.ZERO
	if key.keycode == KEY_LEFT:
		step.x = -ARROW_STEP_PX
	elif key.keycode == KEY_RIGHT:
		step.x = ARROW_STEP_PX
	elif key.keycode == KEY_UP:
		step.y = -ARROW_STEP_PX
	elif key.keycode == KEY_DOWN:
		step.y = ARROW_STEP_PX
	if step != Vector2.ZERO:
		_map.call(&"pan_by_pixels", step)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _pressing or _dragging or _hold_fired:
		return
	_press_time += maxf(delta, 0.0)
	if _press_time < HOLD_SECONDS:
		return
	_hold_fired = true
	var pin: Variant = _map.call(&"pin")
	## N4: armed from press-down, on a fresh pin and on the existing pin alike.
	if pin != null:
		jump_requested.emit(pin as Vector2)


## --- public seam (hud.gd, game.gd, tests) ------------------------------------------


func set_open(open: bool) -> void:
	visible = open
	if not open:
		_reset_press()


func is_open() -> bool:
	return visible


func toggle() -> void:
	set_open(not visible)


## The S29-F1 designer ruling: section 9.9's cancel and section 10's pin-remove are
## one operation - the ESC-open path clears the pin with the order it cancels, so the
## deck never reopens on an orderless pin. Reversal: the game stops calling this and
## the two are separate operations again.
func clear_pin() -> void:
	_set_pin(null)


func map_view() -> Control:
	return _map


func filter_state(toggle_id: StringName) -> bool:
	return bool(_filter_states.get(toggle_id, true))


func filter_states() -> Dictionary:
	return _filter_states.duplicate()


func set_filter(toggle_id: StringName, on: bool) -> void:
	if _filter_states.get(toggle_id, true) == on:
		return
	_filter_states[toggle_id] = on
	var state_label := _state_label(toggle_id)
	if state_label != null:
		_apply_filter_state(state_label, on)
	_map.call(&"set_filters", _filter_states)
	_save_filters()
	filters_changed.emit(_filter_states.duplicate())


## N11-N13's read line (the wording arrives whole from `game.gd`'s machine, so the
## ticks' spellings have exactly one home).
func set_jump_read(text: String) -> void:
	if _jump_read != null:
		_jump_read.text = text


func jump_read_text() -> String:
	return "" if _jump_read == null else _jump_read.text


func zoom_read_text() -> String:
	return "" if _zoom_read == null else _zoom_read.text


## --- composition (A5.1-A5.4: containers + anchors, never coordinates) ---------------


func _build() -> void:
	var margin := MarginContainer.new()
	margin.name = &"PaneMargin"
	margin.add_theme_constant_override(&"margin_left", PANE_MARGIN)
	margin.add_theme_constant_override(&"margin_top", PANE_MARGIN)
	margin.add_theme_constant_override(&"margin_right", PANE_MARGIN)
	margin.add_theme_constant_override(&"margin_bottom", PANE_MARGIN)
	add_child(margin)

	var body := VBoxContainer.new()
	body.name = &"DeckBody"
	body.add_theme_constant_override(&"separation", 8)
	margin.add_child(body)

	var columns := HBoxContainer.new()
	columns.name = &"DeckColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 12)
	body.add_child(columns)

	_map = MinimapScript.new()
	_map.name = &"DeckMap"
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.call(&"set_pin_labels_visible", true)
	columns.add_child(_map)
	(_map as Control).gui_input.connect(_on_map_gui_input)

	_filter_column = VBoxContainer.new()
	_filter_column.name = &"FilterColumn"
	_filter_column.custom_minimum_size = Vector2(FILTER_MIN_WIDTH, 0.0)
	_filter_column.add_theme_constant_override(&"separation", 4)
	columns.add_child(_filter_column)
	_build_filter_rows()

	body.add_child(_build_foot())
	_update_zoom_read()


func _build_filter_rows() -> void:
	var caption := Label.new()
	caption.name = &"FiltersHeader"
	caption.theme_type_variation = HEADER_VARIATION
	caption.text = FILTERS_CAPTION
	_filter_column.add_child(caption)
	for row: Dictionary in MinimapScript.toggle_rows():
		var toggle_id := StringName(str(row[&"id"]))
		var button := Button.new()
		button.name = &"Filter_%s" % String(toggle_id)
		button.toggle_mode = true
		button.button_pressed = filter_state(toggle_id)
		button.custom_minimum_size = Vector2(0.0, ROW_MIN_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inner := MarginContainer.new()
		inner.name = &"RowInner"
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_constant_override(&"margin_left", ROW_INNER.x)
		inner.add_theme_constant_override(&"margin_top", ROW_INNER.y)
		inner.add_theme_constant_override(&"margin_right", ROW_INNER.x)
		inner.add_theme_constant_override(&"margin_bottom", ROW_INNER.y)
		button.add_child(inner)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var line := HBoxContainer.new()
		line.name = &"RowLine"
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(line)
		var name_label := Label.new()
		name_label.name = &"Name"
		name_label.theme_type_variation = ROW_VARIATION
		name_label.text = String(row[&"label"])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(name_label)
		var state_label := Label.new()
		state_label.name = &"State"
		state_label.theme_type_variation = ROW_VARIATION
		state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(state_label)
		_apply_filter_state(state_label, button.button_pressed)
		button.toggled.connect(_on_filter_toggled.bind(toggle_id))
		_filter_column.add_child(button)


func _build_foot() -> HBoxContainer:
	var foot := HBoxContainer.new()
	foot.name = &"DeckFoot"
	foot.add_theme_constant_override(&"separation", 8)
	_jump_read = _caption_label(&"JumpReadCaption")
	foot.add_child(_jump_read)
	var spacer := Control.new()
	spacer.name = &"FootSpacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	_zoom_read = _caption_label(&"ZoomReadCaption")
	foot.add_child(_zoom_read)
	_hint_read = _caption_label(&"HintCaption")
	_hint_read.text = HINT_TEXT
	foot.add_child(_hint_read)
	foot.add_child(_foot_button(&"ZoomMinus", DeckMark.MODE_MINUS, _on_deck_zoom.bind(1.0 / MinimapScript.ZOOM_STEP)))
	foot.add_child(_foot_button(&"ZoomPlus", DeckMark.MODE_PLUS, _on_deck_zoom.bind(MinimapScript.ZOOM_STEP)))
	foot.add_child(_foot_button(&"ExpandToggle", DeckMark.MODE_EXPAND, toggle))
	return foot


func _caption_label(label_name: StringName) -> Label:
	var label := Label.new()
	label.name = label_name
	label.theme_type_variation = CAPTION_VARIATION
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _foot_button(button_name: StringName, mode: int, handler: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.name = button_name
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var mark := DeckMark.new()
	mark.name = &"Mark"
	mark.mode = mode
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(handler)
	return button


## --- filters (N3, N19, N20, N23) ----------------------------------------------------


func _on_filter_toggled(on: bool, toggle_id: StringName) -> void:
	set_filter(toggle_id, on)


func _state_label(toggle_id: StringName) -> Label:
	var button := _filter_column.get_node_or_null(NodePath("Filter_%s" % String(toggle_id))) as Button
	if button == null:
		return null
	return button.get_node_or_null(NodePath("RowInner/RowLine/State")) as Label


## Label + state, never colour alone (N3): the ON/OFF word is the reading and the
## `text_dim` seat is its secondary cue.
func _apply_filter_state(state_label: Label, on: bool) -> void:
	state_label.text = "ON" if on else "OFF"
	if on:
		state_label.remove_theme_color_override(&"font_color")
	else:
		state_label.add_theme_color_override(&"font_color", _token(TOKEN_TEXT_DIM))


func _token(token: StringName) -> Color:
	if has_theme_color(token, &"Tokens"):
		return get_theme_color(token, &"Tokens")
	return Color.WHITE


## --- the pin machine (N4, the fixer's precedence law) --------------------------------


func _on_map_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_begin_press(button.position)
			else:
				_end_press()
			_map.call(&"accept_event")
			return
		if button.pressed:
			var factor := 0.0
			if button.button_index == MOUSE_BUTTON_WHEEL_UP:
				factor = MinimapScript.ZOOM_STEP
			elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				factor = 1.0 / MinimapScript.ZOOM_STEP
			if factor > 0.0:
				_on_map_zoom(factor, button.position)
				_map.call(&"accept_event")
			return
	var motion := event as InputEventMouseMotion
	if motion == null or not _pressing:
		return
	## N14: a press only counts as a drag past the 8 px threshold, and a held move that
	## far is a pan (N2) - never a pin move and never a hold-jump.
	if not _dragging and _press_from.distance_to(motion.position) > DRAG_THRESHOLD_PX:
		_dragging = true
	if _dragging:
		_map.call(&"pan_by_pixels", -motion.relative)
		_map.call(&"accept_event")


func _begin_press(local: Vector2) -> void:
	_pressing = true
	_press_from = local
	_press_time = 0.0
	_dragging = false
	_hold_fired = false
	set_process(true)
	## The fixer's precedence law: hit-testing the pin first makes a press on it a
	## remove candidate and never a place or move.
	if bool(_map.call(&"pin_hit_test", local)):
		_press_role = ROLE_REMOVE
		return
	_press_role = ROLE_PLACE
	## Placed at press-down and never follows the cursor: the pan that may follow leaves
	## the pin where it was placed (section 10).
	_set_pin(_map.call(&"world_at", local))


func _end_press() -> void:
	if not _pressing:
		return
	var was_dragging := _dragging
	var fired := _hold_fired
	var role := _press_role
	_reset_press()
	## A pan is a pan (the release of a drag issues no order) and a fired hold already
	## jumped (N4); what is left is N4's short press, "release < 0.5 s".
	if was_dragging or fired:
		return
	if role == ROLE_REMOVE:
		_set_pin(null)
		autopilot_cancel.emit()
	elif role == ROLE_PLACE:
		var pin: Variant = _map.call(&"pin")
		if pin != null:
			autopilot_to.emit(pin as Vector2)


func _reset_press() -> void:
	_pressing = false
	_press_role = ROLE_NONE
	_dragging = false
	_hold_fired = false
	_press_time = 0.0
	set_process(false)


func _set_pin(world: Variant) -> void:
	_map.call(&"set_pin", world)
	pin_changed.emit(_map.call(&"pin"))


func _on_map_zoom(factor: float, local: Vector2) -> void:
	_map.call(&"zoom_at", local, factor)
	_update_zoom_read()


func _on_deck_zoom(factor: float) -> void:
	_on_map_zoom(factor, (_map as Control).size * 0.5)


func _update_zoom_read() -> void:
	if _zoom_read == null:
		return
	_zoom_read.text = ZOOM_FORMAT % int(round(float(_map.call(&"view_zoom")) * 100.0))


func _is_map_toggle(event: InputEvent) -> bool:
	if InputMap.has_action(MAP_TOGGLE_ACTION):
		return event.is_action_pressed(MAP_TOGGLE_ACTION)
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.keycode == KEY_M


## --- N3's per-profile persistence (the existing PlayerProfile save) -----------------


func _profile() -> Node:
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null or not service.has_method(&"credits"):
		return null
	return service


## S30's **R-S30-2** (T-102's default): the deck reads and writes the profile's public
## `map_filters` door instead of borrowing its private `_config` (the profile owns the
## save shape; the deck owns only the on-screen states).
func _load_filters() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"map_filters"):
		return
	var stored: Variant = profile.call(&"map_filters")
	if not (stored is Dictionary):
		return
	var loaded := {}
	for key: Variant in (stored as Dictionary):
		loaded[StringName(str(key))] = bool((stored as Dictionary)[key])
	_filter_states = loaded


func _save_filters() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"set_map_filters"):
		return
	## String keys, the profile's own `_keys_to_strings` idiom, so the save file's
	## dictionary round-trips (`_load_filters` re-names the keys on the way in).
	var stored := {}
	for key: Variant in _filter_states:
		stored[String(StringName(str(key)))] = bool(_filter_states[key])
	profile.call(&"set_map_filters", stored)
	## The deck's own write is immediate (the retired `save()` call): a filter toggle is a
	## discrete command, not a per-frame edit worth debouncing.
	profile.call(&"save")


## The deck foot's code-drawn marks (A5.2(iii), the compact footer's `ZoomMark` idiom):
## +/- bars and an expand corner-bracket pair, drawn inside their own child rect.
class DeckMark extends Control:
	const MODE_MINUS := 0
	const MODE_PLUS := 1
	const MODE_EXPAND := 2
	const BAR_LENGTH := 14.0
	const BAR_THICKNESS := 3.0
	const BRACKET_ARM := 5.0
	const BRACKET_THICKNESS := 2.0
	const BRACKET_INSET := 6.0

	var mode: int = MODE_MINUS


	func _draw() -> void:
		var centre := size * 0.5
		if mode == MODE_EXPAND:
			_bracket(centre, -1.0)
			_bracket(centre, 1.0)
			return
		draw_rect(
			Rect2(centre - Vector2(BAR_LENGTH, BAR_THICKNESS) * 0.5, Vector2(BAR_LENGTH, BAR_THICKNESS)),
			Color.WHITE
		)
		if mode == MODE_PLUS:
			draw_rect(
				Rect2(centre - Vector2(BAR_THICKNESS, BAR_LENGTH) * 0.5, Vector2(BAR_THICKNESS, BAR_LENGTH)),
				Color.WHITE
			)


	func _bracket(centre: Vector2, sign: float) -> void:
		var corner := centre + Vector2(BRACKET_INSET, BRACKET_INSET) * sign
		draw_rect(
			Rect2(
				Vector2(
					minf(corner.x, corner.x - BRACKET_ARM * sign),
					minf(corner.y, corner.y - BRACKET_THICKNESS * sign)
				),
				Vector2(BRACKET_ARM, BRACKET_THICKNESS)
			),
			Color.WHITE
		)
		draw_rect(
			Rect2(
				Vector2(
					minf(corner.x, corner.x - BRACKET_THICKNESS * sign),
					minf(corner.y, corner.y - BRACKET_ARM * sign)
				),
				Vector2(BRACKET_THICKNESS, BRACKET_ARM)
			),
			Color.WHITE
		)
