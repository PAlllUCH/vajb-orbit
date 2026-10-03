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

## S28's A2 (D17-P1/D17-P2 CONTROLS): the two flight-stick actions the project ships with
## no keys at all. They fold behind an ADVANCED row so a fresh profile never opens on two
## UNBOUND lines at the top of the tab; the fold is display-only - both actions stay
## rebindable through the same list the manager owns. Reversal: drop the fold and every
## action ships a row like before.
const ADVANCED_ACTIONS: Array[StringName] = [&"turn_left", &"turn_right"]
const ADVANCED_LABEL := "ADVANCED (STICK ACTIONS)"

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
var _advanced_visible := false
var _advanced_toggle: Button = null


func _ready() -> void:
	_load_persisted_controls()
	_build_rebind_rows()
	_connect_signals()
	_apply_focus_language()
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
		if not _advanced_visible and ADVANCED_ACTIONS.has(action):
			continue
		_add_rebind_row(action)
	_wire_rebind_focus()
	_ensure_advanced_toggle()
	_scan_conflicts()


## Rebuilds the row list when the fold opens or closes, without leaking the old rows.
func _rebuild_rebind_rows() -> void:
	for row: HBoxContainer in _rows:
		if is_instance_valid(row):
			_rebind_rows.remove_child(row)
			row.queue_free()
	_rows.clear()
	_rows_by_action.clear()
	_conflict_actions.clear()
	_listening_row = null
	_listening_action = &""
	_listening_index = -1
	_build_rebind_rows()


## The ADVANCED row itself: one toggle button under the list, focus-linked like a row.
func _ensure_advanced_toggle() -> void:
	if _advanced_toggle == null:
		_advanced_toggle = Button.new()
		_advanced_toggle.name = &"AdvancedToggle"
		_advanced_toggle.toggle_mode = true
		_advanced_toggle.text = ADVANCED_LABEL
	var host := _rebind_scroll.get_parent()
	if _advanced_toggle.get_parent() != host:
		host.add_child(_advanced_toggle)
		host.move_child(_advanced_toggle, _rebind_scroll.get_index() + 1)
	_advanced_toggle.set_pressed_no_signal(_advanced_visible)
	if not _advanced_toggle.pressed.is_connected(_on_advanced_pressed):
		_advanced_toggle.pressed.connect(_on_advanced_pressed)


func _on_advanced_pressed() -> void:
	_advanced_visible = not _advanced_visible
	_rebuild_rebind_rows()


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
	## A2 (D17-P1: "CONTROLS ships conflicting bindings without warning"): one binding
	## per key, enforced at the map. A captured key is **stolen** from every other
	## rebindable action, so a Q can never ride three actions again; the write goes
	## through the manager's own `save_inputs`, the same persistence every rebind uses.
	_steal_binding(action, String(SettingsManager.event_text(captured)))
	_refresh_bindings()
	_scan_conflicts()
	var row: Variant = _rows_by_action.get(action)
	if row != null:
		(row as HBoxContainer).call(&"focus_button", index)


## A2: the steal half of "one binding per action per key" - the same key event, by its
## display text (the manager's own identity for a binding), leaves every other action.
func _steal_binding(action: StringName, text: String) -> void:
	if text.is_empty():
		return
	var moved := false
	for other: StringName in SettingsManager.rebindable_actions():
		if other == action or not InputMap.has_action(other):
			continue
		for event: InputEvent in InputMap.action_get_events(other):
			if String(SettingsManager.event_text(event)) == text:
				InputMap.action_erase_event(other, event)
				moved = true
	if moved:
		SettingsManager.save_inputs()


## A2: every visible binding is read once at build (and after every commit), so a profile
## that already carries a duplicated key shows it on the existing conflict highlight
## instead of shipping it silently (the D17-P1 "without warning" half).
func _scan_conflicts() -> void:
	_clear_conflicts()
	var owners: Dictionary = {}
	for action: StringName in SettingsManager.rebindable_actions():
		for slot in BINDING_SLOTS:
			var text := _raw_binding_text(action, slot)
			if text.is_empty():
				continue
			var holders: Array = owners.get(text, [])
			if holders.has(action):
				break
			holders.append(action)
			owners[text] = holders
	for holders: Variant in owners.values():
		if (holders as Array).size() > 1:
			for holder: Variant in holders as Array:
				_highlight(holder as StringName)


func _clear_conflicts() -> void:
	for action: StringName in _conflict_actions:
		_set_row_conflict(action, false)
	_conflict_actions.clear()


func _highlight(action: StringName) -> void:
	_conflict_actions.append(action)
	_set_row_conflict(action, true)


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


## S28's A16 (UI_SPEC section 8 P3): one focus language on this overlay too - the 1 px
## `accent_danger_bright` ring of section 6, the same box `tools/build_theme.gd` registers
## for `Button`. The sliders were the one family that drew the fallback default-theme ring;
## the separate settings focus look is retired here, in code, without touching the
## generated theme file.
func _apply_focus_language() -> void:
	var ring := _focus_ring()
	if ring == null:
		return
	for slider: HSlider in [
		_render_scale_slider, _master_slider, _music_slider, _sfx_slider, _ui_slider,
		_ui_scale_slider, _hud_opacity_slider,
	]:
		slider.add_theme_stylebox_override(&"focus", ring)


## The section 6 ring, mirrored from the theme's own `_focus_box()` (an accent box whose
## centre is not drawn is a 1 px frame). Null when the token cannot resolve, so the
## control keeps whatever the theme gives it.
func _focus_ring() -> StyleBoxFlat:
	if not has_theme_color(&"accent_danger_bright", &"Tokens"):
		return null
	var accent := get_theme_color(&"accent_danger_bright", &"Tokens")
	var box := StyleBoxFlat.new()
	box.bg_color = accent
	box.border_color = accent
	box.set_border_width_all(1)
	box.set_corner_radius_all(0)
	box.draw_center = false
	return box


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
