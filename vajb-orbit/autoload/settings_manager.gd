extends Node
## Persistent user settings and input bindings.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.5 and 3.6.

signal setting_changed(section: StringName, key: StringName, value: Variant)

const Paths := preload("res://ui/paths.gd")

const SECTION_GRAPHICS: StringName = &"graphics"
const SECTION_AUDIO: StringName = &"audio"
const SECTION_INTERFACE: StringName = &"interface"
const INPUT_SECTION := "input"

const SAVE_DEBOUNCE_SECONDS := 0.5
const RENDER_SCALE_MIN := 0.5
const RENDER_SCALE_MAX := 2.0
const UI_SCALE_MIN := 0.85
const UI_SCALE_MAX := 1.5
const HUD_OPACITY_MIN := 0.4
const HUD_OPACITY_MAX := 1.0

const MODE_WINDOWED := 0
const MODE_FULLSCREEN := 1
const MODE_BORDERLESS := 2

const DEFAULT_RESOLUTION := Vector2i(1920, 1080)

## Contract section 3.7 order, extended by the ENGINE_SPEC section 11 amendments
## (`interact` = F, `warp` = H) that `docs/design/PROJECT_SETTINGS_PATCH.md` section 2
## appends as orders 16 and 17, so the Controls tab lists the same 17 actions the
## project should apply. Each entry is guarded by `InputMap.has_action` at every read,
## so the list leads the input map without depending on it.
const REBINDABLE_ACTIONS: Array[StringName] = [
	&"thrust_forward",
	&"thrust_backward",
	&"turn_left",
	&"turn_right",
	&"fire_primary",
	&"fire_secondary",
	&"mine",
	&"boost",
	&"cargo_toggle",
	&"weapon_1",
	&"weapon_2",
	&"weapon_3",
	&"weapon_4",
	&"weapon_5",
	&"target_next",
	&"interact",
	&"warp",
]

const BUS_BY_KEY: Dictionary = {
	&"master": &"Master",
	&"music": &"Music",
	&"sfx": &"SFX",
	&"ui": &"UI",
}

const MOUSE_BUTTON_NAMES := [
	"MOUSE LEFT", "MOUSE RIGHT", "MOUSE MIDDLE",
	"WHEEL UP", "WHEEL DOWN", "MOUSE X1", "MOUSE X2",
]
const JOY_BUTTON_NAMES := [
	"PAD A", "PAD B", "PAD X", "PAD Y",
	"PAD LB", "PAD RB", "PAD LT", "PAD RT",
	"PAD BACK", "PAD START", "PAD L3", "PAD R3",
	"PAD UP", "PAD DOWN", "PAD LEFT", "PAD RIGHT",
]
const JOY_AXIS_NAMES := ["LX", "LY", "RX", "RY", "LT", "RT"]

## Overridable so tools can round-trip against a scratch file.
var settings_file: String = Paths.SETTINGS_FILE
var inputs_file: String = Paths.INPUTS_FILE

var _config := ConfigFile.new()
var _default_events: Dictionary = {}
var _save_timer: Timer
var _dirty := false

var _defaults: Dictionary = {
	SECTION_GRAPHICS: {
		&"resolution": DEFAULT_RESOLUTION,
		&"display_mode": MODE_WINDOWED,
		&"vsync": true,
		&"render_scale": 1.0,
		&"effects_quality": 2,
	},
	SECTION_AUDIO: {
		&"master": db_to_linear(0.0),
		&"music": db_to_linear(-8.0),
		&"sfx": db_to_linear(-6.0),
		&"ui": db_to_linear(-10.0),
	},
	SECTION_INTERFACE: {
		&"ui_scale": 1.0,
		&"hud_opacity": 1.0,
	},
}


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.name = &"SaveDebounce"
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE_SECONDS
	_save_timer.timeout.connect(_write_settings)
	add_child(_save_timer)

	_load_settings()
	_capture_default_events()
	_load_inputs()
	_apply_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		flush()


func get_value(section: StringName, key: StringName, default: Variant = null) -> Variant:
	if _config.has_section_key(String(section), String(key)):
		return _config.get_value(String(section), String(key))
	if default != null:
		return default
	return _default(section, key)


func set_value(section: StringName, key: StringName, value: Variant) -> void:
	if get_value(section, key) == value:
		return
	_config.set_value(String(section), String(key), value)
	_apply(section, key, value)
	_dirty = true
	if _save_timer != null:
		_save_timer.start()
	else:
		_write_settings()
	setting_changed.emit(section, key, value)


func flush() -> void:
	if _save_timer != null:
		_save_timer.stop()
	_write_settings()


func rebindable_actions() -> Array[StringName]:
	return REBINDABLE_ACTIONS.duplicate()


func binding_text(action: StringName, index: int) -> String:
	if not InputMap.has_action(action):
		return ""
	var events := InputMap.action_get_events(action)
	if index < 0 or index >= events.size():
		return ""
	return event_text(events[index])


func set_binding(action: StringName, index: int, event: InputEvent) -> void:
	if index < 0 or event == null or not REBINDABLE_ACTIONS.has(action):
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var events := InputMap.action_get_events(action)
	if index < events.size():
		events[index] = event
	else:
		events.append(event)
	_write_action(action, events)
	save_inputs()


func reset_all_inputs() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var restored: Array[InputEvent] = []
		for event: InputEvent in _default_events.get(action, []):
			restored.append(event.duplicate())
		_write_action(action, restored)
	save_inputs()


func save_inputs() -> void:
	var config := ConfigFile.new()
	for action: StringName in REBINDABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var encoded: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			encoded.append(_event_to_dict(event))
		config.set_value(INPUT_SECTION, String(action), encoded)
	var err := config.save(inputs_file)
	if err != OK:
		push_warning("SettingsManager: could not write %s (error %d)" % [inputs_file, err])


func ui_scale() -> float:
	return clampf(float(get_value(SECTION_INTERFACE, &"ui_scale")), UI_SCALE_MIN, UI_SCALE_MAX)


func event_text(event: InputEvent) -> String:
	if event == null:
		return ""
	if event is InputEventKey:
		var key := event as InputEventKey
		var code: Key = key.physical_keycode if key.physical_keycode != 0 else key.keycode
		return _modifier_prefix(key.ctrl_pressed, key.alt_pressed, key.shift_pressed, key.meta_pressed) \
			+ OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		var index := int(mouse.button_index)
		var label: String = MOUSE_BUTTON_NAMES[index] if index < MOUSE_BUTTON_NAMES.size() else "MOUSE"
		return _modifier_prefix(mouse.ctrl_pressed, mouse.alt_pressed, mouse.shift_pressed, mouse.meta_pressed) + label
	if event is InputEventJoypadButton:
		var pad := event as InputEventJoypadButton
		var index := int(pad.button_index)
		var label: String = JOY_BUTTON_NAMES[index] if index < JOY_BUTTON_NAMES.size() else "PAD %d" % index
		return label
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var index := int(motion.axis)
		var label: String = JOY_AXIS_NAMES[index] if index < JOY_AXIS_NAMES.size() else "AXIS %d" % index
		return "%s%s" % [label, "+" if motion.axis_value >= 0.0 else "-"]
	return event.as_text()


func _default(section: StringName, key: StringName) -> Variant:
	var keys: Dictionary = _defaults.get(section, {})
	return keys.get(key)


func _apply_all() -> void:
	for section: StringName in _defaults:
		var keys: Dictionary = _defaults[section]
		for key: StringName in keys:
			_apply(section, key, get_value(section, key))


func _apply(section: StringName, key: StringName, value: Variant) -> void:
	match section:
		SECTION_GRAPHICS:
			_apply_graphics(key, value)
		SECTION_AUDIO:
			_apply_audio(key, value)


func _apply_graphics(key: StringName, value: Variant) -> void:
	if not is_inside_tree():
		return
	var window := get_window()
	if window == null:
		return
	match key:
		&"resolution":
			window.size = _clamp_resolution(value)
		&"display_mode":
			match clampi(int(value), MODE_WINDOWED, MODE_BORDERLESS):
				MODE_FULLSCREEN:
					window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
				MODE_BORDERLESS:
					window.mode = Window.MODE_FULLSCREEN
				_:
					window.mode = Window.MODE_WINDOWED
		&"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED
			)
		&"render_scale":
			window.content_scale_factor = clampf(float(value), RENDER_SCALE_MIN, RENDER_SCALE_MAX)
		&"effects_quality":
			pass


func _apply_audio(key: StringName, value: Variant) -> void:
	var bus: StringName = BUS_BY_KEY.get(key, &"")
	if bus == &"":
		return
	var audio := _service(&"AudioManager")
	if audio == null or not audio.has_method(&"set_bus_linear"):
		return
	audio.call(&"set_bus_linear", bus, clampf(float(value), 0.0, 1.0))


func _clamp_resolution(value: Variant) -> Vector2i:
	var resolution: Vector2i = value if value is Vector2i else DEFAULT_RESOLUTION
	return Vector2i(maxi(resolution.x, 640), maxi(resolution.y, 360))


func _load_settings() -> void:
	if _config.load(settings_file) != OK:
		_config = ConfigFile.new()


func _write_settings() -> void:
	if not _dirty:
		return
	var err := _config.save(settings_file)
	if err != OK:
		push_warning("SettingsManager: could not write %s (error %d)" % [settings_file, err])
		return
	_dirty = false


func _capture_default_events() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		_default_events[action] = InputMap.action_get_events(action)


func _load_inputs() -> void:
	var config := ConfigFile.new()
	if config.load(inputs_file) != OK or not config.has_section(INPUT_SECTION):
		return
	for action: StringName in REBINDABLE_ACTIONS:
		if not config.has_section_key(INPUT_SECTION, String(action)):
			continue
		var decoded: Array[InputEvent] = []
		for data: Variant in config.get_value(INPUT_SECTION, String(action), []):
			var event := _dict_to_event(data)
			if event != null:
				decoded.append(event)
		if decoded.is_empty():
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_write_action(action, decoded)


func _write_action(action: StringName, events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event: InputEvent in events:
		if event != null:
			InputMap.action_add_event(action, event)


func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {
			"type": "key",
			"keycode": int(key.keycode),
			"physical_keycode": int(key.physical_keycode),
			"unicode": int(key.unicode),
			"ctrl": key.ctrl_pressed,
			"alt": key.alt_pressed,
			"shift": key.shift_pressed,
			"meta": key.meta_pressed,
		}
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		return {
			"type": "mouse",
			"button": int(mouse.button_index),
			"ctrl": mouse.ctrl_pressed,
			"alt": mouse.alt_pressed,
			"shift": mouse.shift_pressed,
			"meta": mouse.meta_pressed,
		}
	if event is InputEventJoypadButton:
		var pad := event as InputEventJoypadButton
		return {"type": "joy_button", "button": int(pad.button_index)}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {"type": "joy_axis", "axis": int(motion.axis), "axis_value": motion.axis_value}
	return {}


func _dict_to_event(data: Variant) -> InputEvent:
	if not data is Dictionary:
		return null
	var source: Dictionary = data
	match String(source.get("type", "")):
		"key":
			var key := InputEventKey.new()
			var keycode: Key = source.get("keycode", 0)
			var physical: Key = source.get("physical_keycode", 0)
			key.keycode = keycode
			key.physical_keycode = physical
			key.unicode = int(source.get("unicode", 0))
			key.ctrl_pressed = bool(source.get("ctrl", false))
			key.alt_pressed = bool(source.get("alt", false))
			key.shift_pressed = bool(source.get("shift", false))
			key.meta_pressed = bool(source.get("meta", false))
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			var button: MouseButton = int(source.get("button", 1)) as MouseButton
			mouse.button_index = button
			mouse.ctrl_pressed = bool(source.get("ctrl", false))
			mouse.alt_pressed = bool(source.get("alt", false))
			mouse.shift_pressed = bool(source.get("shift", false))
			mouse.meta_pressed = bool(source.get("meta", false))
			return mouse
		"joy_button":
			var pad := InputEventJoypadButton.new()
			var pad_button: JoyButton = int(source.get("button", 0)) as JoyButton
			pad.button_index = pad_button
			return pad
		"joy_axis":
			var motion := InputEventJoypadMotion.new()
			var axis: JoyAxis = int(source.get("axis", 0)) as JoyAxis
			motion.axis = axis
			motion.axis_value = float(source.get("axis_value", 1.0))
			return motion
	return null


func _modifier_prefix(ctrl: bool, alt: bool, shift: bool, meta: bool) -> String:
	var parts: PackedStringArray = []
	if ctrl:
		parts.append("Ctrl")
	if alt:
		parts.append("Alt")
	if shift:
		parts.append("Shift")
	if meta:
		parts.append("Meta")
	if parts.is_empty():
		return ""
	return "+".join(parts) + "+"


func _service(service_name: StringName) -> Node:
	## Autoload names are not resolvable identifiers until the project patch lands
	## (project.godot is applied by the orchestrator), so services are looked up by name.
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(service_name))
