extends Screen
## Settings overlay: GRAPHICS, AUDIO, CONTROLS and INTERFACE.
## Every value is read and written through SettingsManager, which owns applying it.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.6, 3.7 and 4.5; docs/design/UI_SPEC.md section 4.

const REBIND_ROW_SCENE: PackedScene = preload("res://ui/screens/settings_rebind_row.tscn")

const SECTION_GRAPHICS: StringName = &"graphics"
const SECTION_AUDIO: StringName = &"audio"
const SECTION_INTERFACE: StringName = &"interface"

const UNBOUND_TEXT := "UNBOUND"
const BINDING_SLOTS := 4

const RENDER_SCALE_MIN := 0.5
const RENDER_SCALE_MAX := 2.0
const UI_SCALE_MIN := 0.85
const UI_SCALE_MAX := 1.5
const HUD_OPACITY_MIN := 0.4
const HUD_OPACITY_MAX := 1.0

const FALLBACK_RESOLUTION := Vector2i(1920, 1080)
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const DISPLAY_MODES: Array[String] = ["WINDOWED", "FULLSCREEN", "BORDERLESS"]
const EFFECT_LEVELS: Array[String] = ["LOW", "MEDIUM", "HIGH"]

@onready var _back_button: Button = %BackButton
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _display_mode_option: OptionButton = %DisplayModeOption
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _render_scale_slider: HSlider = %RenderScaleSlider
@onready var _render_scale_readout: Label = %RenderScaleValue
@onready var _effects_option: OptionButton = %EffectsOption
@onready var _master_slider: HSlider = %MasterSlider
@onready var _master_readout: Label = %MasterValue
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_readout: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_readout: Label = %SfxValue
@onready var _ui_slider: HSlider = %UiSlider
@onready var _ui_readout: Label = %UiValue
@onready var _rebind_scroll: ScrollContainer = %RebindScroll
@onready var _rebind_rows: VBoxContainer = %RebindRows
@onready var _reset_all_button: Button = %ResetAllButton
@onready var _save_button: Button = %SaveButton
@onready var _ui_scale_slider: HSlider = %UiScaleSlider
@onready var _ui_scale_readout: Label = %UiScaleValue
@onready var _hud_opacity_slider: HSlider = %HudOpacitySlider
@onready var _hud_opacity_readout: Label = %HudOpacityValue

var _rows: Array[HBoxContainer] = []
var _rows_by_action: Dictionary = {}
var _conflict_actions: Array[StringName] = []
var _listening_row: HBoxContainer = null
var _listening_action: StringName = &""
var _listening_index := -1


func _ready() -> void:
	_load_persisted_controls()
	_build_rebind_rows()
	_connect_signals()
	_resolution_option.grab_focus()


func _input(event: InputEvent) -> void:
	if _listening_row == null:
		# MENU_FLOW section 3.12: Esc/B closes the overlay whenever no rebind row is
		# capturing input, so a keyboard user never has to tab to BACK.
		if event.is_action_pressed(&"ui_cancel"):
			_accept_event()
			overlay_close_requested.emit()
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_ESCAPE:
			_cancel_listen()
			_accept_event()
			return
		_commit_binding(key)
		return
	if event is InputEventJoypadButton:
		var pad := event as InputEventJoypadButton
		if pad.pressed:
			_commit_binding(pad)


func _load_persisted_controls() -> void:
	_fill_resolutions()
	_display_mode_option.clear()
	for mode: String in DISPLAY_MODES:
		_display_mode_option.add_item(mode)
	_display_mode_option.select(clampi(int(SettingsManager.get_value(SECTION_GRAPHICS, &"display_mode")), 0, DISPLAY_MODES.size() - 1))

	_vsync_check.button_pressed = bool(SettingsManager.get_value(SECTION_GRAPHICS, &"vsync"))

	var render_scale := clampf(float(SettingsManager.get_value(SECTION_GRAPHICS, &"render_scale")), RENDER_SCALE_MIN, RENDER_SCALE_MAX)
	_render_scale_slider.value = render_scale
	_render_scale_readout.text = _scale_text(render_scale)

	_effects_option.clear()
	for level: String in EFFECT_LEVELS:
		_effects_option.add_item(level)
	_effects_option.select(clampi(int(SettingsManager.get_value(SECTION_GRAPHICS, &"effects_quality")), 0, EFFECT_LEVELS.size() - 1))

	_load_audio(&"master", _master_slider, _master_readout)
	_load_audio(&"music", _music_slider, _music_readout)
	_load_audio(&"sfx", _sfx_slider, _sfx_readout)
	_load_audio(&"ui", _ui_slider, _ui_readout)

	var ui_scale := clampf(SettingsManager.ui_scale(), UI_SCALE_MIN, UI_SCALE_MAX)
	_ui_scale_slider.value = ui_scale
	_ui_scale_readout.text = _scale_text(ui_scale)

	var hud_opacity := clampf(float(SettingsManager.get_value(SECTION_INTERFACE, &"hud_opacity")), HUD_OPACITY_MIN, HUD_OPACITY_MAX)
	_hud_opacity_slider.value = hud_opacity
	_hud_opacity_readout.text = _percent_text(hud_opacity)


func _fill_resolutions() -> void:
	var options: Array[Vector2i] = RESOLUTIONS.duplicate()
	var display := _display_size()
	if display.x > 0 and display.y > 0 and not options.has(display):
		options.append(display)
	var raw: Variant = SettingsManager.get_value(SECTION_GRAPHICS, &"resolution")
	var stored: Vector2i = raw if raw is Vector2i else FALLBACK_RESOLUTION
	if not options.has(stored):
		options.append(stored)

	_resolution_option.clear()
	var selected := 0
	for index in options.size():
		var resolution: Vector2i = options[index]
		_resolution_option.add_item("%d x %d" % [resolution.x, resolution.y])
		_resolution_option.set_item_metadata(index, resolution)
		if resolution == stored:
			selected = index
	_resolution_option.select(selected)


func _display_size() -> Vector2i:
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


func _load_audio(key: StringName, slider: HSlider, readout: Label) -> void:
	var value := clampf(float(SettingsManager.get_value(SECTION_AUDIO, key)), 0.0, 1.0)
	slider.value = value
	readout.text = _percent_text(value)


func _connect_signals() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_display_mode_option.item_selected.connect(_on_display_mode_selected)
	_vsync_check.toggled.connect(_on_vsync_toggled)
	_render_scale_slider.value_changed.connect(_on_render_scale_changed)
	_effects_option.item_selected.connect(_on_effects_selected)
	_master_slider.value_changed.connect(_on_audio_changed.bind(&"master", _master_readout))
	_music_slider.value_changed.connect(_on_audio_changed.bind(&"music", _music_readout))
	_sfx_slider.value_changed.connect(_on_audio_changed.bind(&"sfx", _sfx_readout))
	_ui_slider.value_changed.connect(_on_audio_changed.bind(&"ui", _ui_readout))
	_reset_all_button.pressed.connect(_on_reset_all_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	_hud_opacity_slider.value_changed.connect(_on_hud_opacity_changed)


func _build_rebind_rows() -> void:
	for action: StringName in SettingsManager.rebindable_actions():
		_add_rebind_row(action)
	_wire_rebind_focus()


func _add_rebind_row(action: StringName) -> void:
	var row := REBIND_ROW_SCENE.instantiate() as HBoxContainer
	if row == null:
		return
	_rebind_rows.add_child(row)
	row.call(&"configure", action, _action_label(action), _button_text(action, 0), _button_text(action, 1))
	row.connect(&"binding_pressed", _on_binding_pressed)
	row.connect(&"reset_pressed", _on_row_reset_pressed)
	_rows.append(row)
	_rows_by_action[action] = row


func _wire_rebind_focus() -> void:
	for row: HBoxContainer in _rows:
		for control: Control in row.call(&"focus_controls"):
			control.focus_entered.connect(_on_rebind_focus_entered.bind(row))
	for index in maxi(_rows.size() - 1, 0):
		_link_vertical(_rows[index], _rows[index + 1])


func _link_vertical(upper: HBoxContainer, lower: HBoxContainer) -> void:
	# Rows are a grid: ui_up/ui_down keep the same button slot across rows, so the
	# ScrollContainer's ensure_control_visible always has a row to reveal.
	var upper_controls: Array = upper.call(&"focus_controls")
	var lower_controls: Array = lower.call(&"focus_controls")
	for slot in mini(upper_controls.size(), lower_controls.size()):
		var up: Control = upper_controls[slot]
		var down: Control = lower_controls[slot]
		if up == null or down == null:
			continue
		up.focus_neighbor_bottom = up.get_path_to(down)
		down.focus_neighbor_top = down.get_path_to(up)


func _refresh_bindings() -> void:
	for action: StringName in _rows_by_action:
		var row: HBoxContainer = _rows_by_action[action]
		row.call(&"set_binding_texts", _button_text(action, 0), _button_text(action, 1))


func _begin_listen(action: StringName, index: int) -> void:
	_cancel_listen()
	var row: Variant = _rows_by_action.get(action)
	if row == null:
		return
	_listening_row = row as HBoxContainer
	_listening_action = action
	_listening_index = index
	_listening_row.call(&"set_listening", index)


func _cancel_listen() -> void:
	if _listening_row != null and is_instance_valid(_listening_row):
		_listening_row.call(&"set_listening", -1)
	_listening_row = null
	_listening_action = &""
	_listening_index = -1


func _commit_binding(event: InputEvent) -> void:
	var action := _listening_action
	var index := _listening_index
	_cancel_listen()
	_accept_event()
	if action == &"" or index < 0:
		return
	var captured := event.duplicate() as InputEvent
	SettingsManager.set_binding(action, index, captured)
	_refresh_bindings()
	_apply_conflicts(action, SettingsManager.event_text(captured))
	var row: Variant = _rows_by_action.get(action)
	if row != null:
		(row as HBoxContainer).call(&"focus_button", index)


func _apply_conflicts(action: StringName, text: String) -> void:
	_clear_conflicts()
	if text.is_empty():
		return
	var others := _conflicting_actions(action, text)
	if others.is_empty():
		return
	_highlight(action)
	for other: StringName in others:
		_highlight(other)


func _clear_conflicts() -> void:
	for action: StringName in _conflict_actions:
		_set_row_conflict(action, false)
	_conflict_actions.clear()


func _highlight(action: StringName) -> void:
	_conflict_actions.append(action)
	_set_row_conflict(action, true)


func _conflicting_actions(excluded: StringName, text: String) -> Array[StringName]:
	var matches: Array[StringName] = []
	for action: StringName in SettingsManager.rebindable_actions():
		if action == excluded:
			continue
		for slot in BINDING_SLOTS:
			if _raw_binding_text(action, slot) == text:
				matches.append(action)
				break
	return matches


func _set_row_conflict(action: StringName, enabled: bool) -> void:
	var row: Variant = _rows_by_action.get(action)
	if row != null:
		(row as HBoxContainer).call(&"set_conflict", enabled)


func _on_back_pressed() -> void:
	overlay_close_requested.emit()


func _on_resolution_selected(index: int) -> void:
	var resolution: Variant = _resolution_option.get_item_metadata(index)
	if resolution is Vector2i:
		SettingsManager.set_value(SECTION_GRAPHICS, &"resolution", resolution)


func _on_display_mode_selected(index: int) -> void:
	SettingsManager.set_value(SECTION_GRAPHICS, &"display_mode", clampi(index, 0, DISPLAY_MODES.size() - 1))


func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.set_value(SECTION_GRAPHICS, &"vsync", enabled)


func _on_render_scale_changed(value: float) -> void:
	_render_scale_readout.text = _scale_text(value)
	SettingsManager.set_value(SECTION_GRAPHICS, &"render_scale", value)


func _on_effects_selected(index: int) -> void:
	SettingsManager.set_value(SECTION_GRAPHICS, &"effects_quality", clampi(index, 0, EFFECT_LEVELS.size() - 1))


func _on_audio_changed(value: float, key: StringName, readout: Label) -> void:
	readout.text = _percent_text(value)
	SettingsManager.set_value(SECTION_AUDIO, key, value)


func _on_ui_scale_changed(value: float) -> void:
	_ui_scale_readout.text = _scale_text(value)
	SettingsManager.set_value(SECTION_INTERFACE, &"ui_scale", value)


func _on_hud_opacity_changed(value: float) -> void:
	_hud_opacity_readout.text = _percent_text(value)
	SettingsManager.set_value(SECTION_INTERFACE, &"hud_opacity", value)


func _on_binding_pressed(action: StringName, index: int) -> void:
	if _listening_action == action and _listening_index == index:
		_cancel_listen()
		return
	_begin_listen(action, index)


func _on_row_reset_pressed(action: StringName) -> void:
	var defaults := _project_default_events(action)
	if defaults.is_empty():
		return
	_cancel_listen()
	_clear_conflicts()
	for index in defaults.size():
		SettingsManager.set_binding(action, index, defaults[index])
	_refresh_bindings()


func _on_reset_all_pressed() -> void:
	_cancel_listen()
	SettingsManager.reset_all_inputs()
	_clear_conflicts()
	_refresh_bindings()


func _on_save_pressed() -> void:
	SettingsManager.save_inputs()


func _on_rebind_focus_entered(row: Control) -> void:
	_rebind_scroll.ensure_control_visible(row)


## Per-action reset is not part of the frozen SettingsManager API, so the shipped
## defaults come from ProjectSettings and the write still goes through set_binding.
func _project_default_events(action: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	var setting: Variant = ProjectSettings.get_setting("input/" + String(action))
	if not setting is Dictionary:
		return events
	for data: Variant in (setting as Dictionary).get("events", []):
		if data is InputEvent:
			events.append((data as InputEvent).duplicate())
	return events


func _action_label(action: StringName) -> String:
	return String(action).to_upper().replace("_", " ")


func _raw_binding_text(action: StringName, index: int) -> String:
	return String(SettingsManager.binding_text(action, index))


func _button_text(action: StringName, index: int) -> String:
	var text := _raw_binding_text(action, index)
	return text if not text.is_empty() else UNBOUND_TEXT


func _percent_text(value: float) -> String:
	return "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)


func _scale_text(value: float) -> String:
	return "%.2fx" % value


func _accept_event() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
