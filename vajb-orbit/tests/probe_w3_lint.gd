extends Node
## W3 (UI-chrome wave, defect D5) lint re-read probe.
##
##   godot --headless --path vajb-orbit res://tests/probe_w3_lint.tscn --quit-after 600
##
## D5 was "one lint pass over the GDScript warnings the 2026-09-21 playtest
## session recorded". A GDScript warning is only printed when a script debugger
## is attached, so a headless run cannot observe one directly; the probe instead
## checks the two things the fix is defined as:
##
##   1. compile -- every touched script is loaded fresh from disk
##      (CACHE_MODE_IGNORE), so a parse error introduced by the pass fails here;
##   2. construct -- the exact source line each editor warning named no longer
##      holds the construct that warning describes, and none of the retired
##      declarations survives anywhere in a touched file.
##
## Exit code is 1 when any check fails, so a shell gate can read it. Not part of
## the universal gate: the runner in headless_runner.gd discovers `test_*.gd`
## only, and this file is deliberately `probe_*`.

const TOUCHED: Array[String] = [
	"res://autoload/settings_manager.gd",
	"res://autoload/audio_manager.gd",
	"res://autoload/router.gd",
	"res://autoload/dialog_manager.gd",
	"res://autoload/player_profile.gd",
	"res://ui/screen.gd",
	"res://ui/screens/station.gd",
	"res://ui/station/refinery_panel.gd",
	"res://game/exchange.gd",
]

## `line` is 1-based, as the editor's warning rows and the report both are.
const LINE_CHECKS: Array[Dictionary] = [
	# INT_AS_ENUM_WITHOUT_CAST (settings_manager.gd 391 / 400 / 405)
	{&"path": "res://autoload/settings_manager.gd", &"line": 391, &"must": "as MouseButton"},
	{&"path": "res://autoload/settings_manager.gd", &"line": 400, &"must": "as JoyButton"},
	{&"path": "res://autoload/settings_manager.gd", &"line": 405, &"must": "as JoyAxis"},
	# SHADOWED_VARIABLE_BASE_CLASS: the autoload helper's parameter `name` vs Node.name
	{&"path": "res://autoload/settings_manager.gd", &"line": 427, &"must": "_service(service_name"},
	{&"path": "res://autoload/audio_manager.gd", &"line": 249, &"must": "_service(service_name"},
	{&"path": "res://autoload/dialog_manager.gd", &"line": 111, &"must": "_service(service_name"},
	# SHADOWED_VARIABLE: player_profile.gd 576 (`var name`) and 735 (iterator `name`)
	{&"path": "res://autoload/player_profile.gd", &"line": 576, &"must": "var entry_name := StringName("},
	{&"path": "res://autoload/player_profile.gd", &"line": 735, &"must": "for entry_name: StringName in names:"},
	# SHADOWED_VARIABLE: router.gd parameters `route` vs the method `route()` (83-264)
	{&"path": "res://autoload/router.gd", &"line": 83, &"must": "func route(route_name: StringName"},
	{&"path": "res://autoload/router.gd", &"line": 111, &"must": "func push_overlay(route_name: StringName"},
	{&"path": "res://autoload/router.gd", &"line": 235, &"must": "func _on_route_requested(route_name: StringName"},
	{&"path": "res://autoload/router.gd", &"line": 239, &"must": "func _on_overlay_requested(route_name: StringName"},
	{&"path": "res://autoload/router.gd", &"line": 264, &"must": "func _find_overlay(route_name: StringName"},
	# SHADOWED_VARIABLE_BASE_CLASS: router.gd 284 (`var owner`) and 336 (`_service(name)`)
	{&"path": "res://autoload/router.gd", &"line": 284, &"must": "var focus_owner := viewport.gui_get_focus_owner()"},
	{&"path": "res://autoload/router.gd", &"line": 336, &"must": "_service(service_name"},
	# UNUSED_SIGNAL: the three Screen intent signals stay, each waived and documented
	{&"path": "res://ui/screen.gd", &"line": 14, &"must": "@warning_ignore(\"unused_signal\")"},
	{&"path": "res://ui/screen.gd", &"line": 15, &"must": "signal route_requested(route: StringName, params: Dictionary)"},
	{&"path": "res://ui/screen.gd", &"line": 16, &"must": "@warning_ignore(\"unused_signal\")"},
	{&"path": "res://ui/screen.gd", &"line": 17, &"must": "signal overlay_requested(route: StringName, params: Dictionary)"},
	{&"path": "res://ui/screen.gd", &"line": 18, &"must": "@warning_ignore(\"unused_signal\")"},
	{&"path": "res://ui/screen.gd", &"line": 19, &"must": "signal overlay_close_requested"},
	# SHADOWED_VARIABLE_BASE_CLASS: station.gd 348 (`size` vs Control.size) and 407 (`var owner`)
	{&"path": "res://ui/screens/station.gd", &"line": 348, &"must": "func _make_icon(icon_path: String, tinted: bool, icon_size: float)"},
	{&"path": "res://ui/screens/station.gd", &"line": 407, &"must": "var focus_owner := get_viewport().gui_get_focus_owner()"},
	# unused parameter: refinery_panel.gd 533
	{&"path": "res://ui/station/refinery_panel.gd", &"line": 533, &"must": "func _on_row_focused(_row: Button, payload: Dictionary)"},
	# SHADOWED_GLOBAL_IDENTIFIER: exchange.gd 45 / 46
	{&"path": "res://game/exchange.gd", &"line": 45, &"must": "const MineralCatalogScript := preload("},
	{&"path": "res://game/exchange.gd", &"line": 46, &"must": "const ComponentCatalogScript := preload("},
]

## The retired declarations, asserted absent from every touched file: a stale
## copy of any of these is the warning coming back.
const ABSENCE_CHECKS: Array[Dictionary] = [
	{&"path": "res://autoload/settings_manager.gd", &"text": "func _service(name:"},
	{&"path": "res://autoload/audio_manager.gd", &"text": "func _service(name:"},
	{&"path": "res://autoload/dialog_manager.gd", &"text": "func _service(name:"},
	{&"path": "res://autoload/router.gd", &"text": "func route(route:"},
	{&"path": "res://autoload/router.gd", &"text": "func push_overlay(route:"},
	{&"path": "res://autoload/router.gd", &"text": "_on_route_requested(route:"},
	{&"path": "res://autoload/router.gd", &"text": "_on_overlay_requested(route:"},
	{&"path": "res://autoload/router.gd", &"text": "_find_overlay(route:"},
	{&"path": "res://autoload/router.gd", &"text": "func _service(name:"},
	{&"path": "res://autoload/router.gd", &"text": "var owner := viewport.gui_get_focus_owner()"},
	{&"path": "res://autoload/player_profile.gd", &"text": "var name := StringName("},
	{&"path": "res://autoload/player_profile.gd", &"text": "for name: StringName in names:"},
	{&"path": "res://ui/screens/station.gd", &"text": "tinted: bool, size: float"},
	{&"path": "res://ui/screens/station.gd", &"text": "var owner := get_viewport().gui_get_focus_owner()"},
	{&"path": "res://ui/station/refinery_panel.gd", &"text": "func _on_row_focused(row: Button"},
	{&"path": "res://game/exchange.gd", &"text": "const MineralCatalog := preload("},
	{&"path": "res://game/exchange.gd", &"text": "const ComponentCatalog := preload("},
]

var _passed := 0
var _failed := 0


func _ready() -> void:
	_check_compile()
	_check_lines()
	_check_absence()
	_check_enum_casts()
	print("[W3] passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## The three INT_AS_ENUM_WITHOUT_CAST sites are the only D5 edits with any
## semantic surface, and no gate suite drives SettingsManager, so the cast is
## measured here instead of argued: `_dict_to_event` must still return the event
## the dictionary describes, enum fields included.
func _check_enum_casts() -> void:
	var settings := get_node_or_null(^"/root/SettingsManager")
	if settings == null:
		_fail("SettingsManager autoload missing")
		return
	_expect_mouse(settings, {"type": "mouse", "button": 2, "ctrl": true}, MOUSE_BUTTON_RIGHT, true)
	_expect_mouse(settings, {"type": "mouse"}, MOUSE_BUTTON_LEFT, false)
	_expect_joy_button(settings, {"type": "joy_button", "button": 1}, JOY_BUTTON_B)
	_expect_joy_axis(settings, {"type": "joy_axis", "axis": 3, "axis_value": -1.0}, JOY_AXIS_RIGHT_Y, -1.0)


func _expect_mouse(settings: Node, data: Dictionary, button: MouseButton, ctrl: bool) -> void:
	var event: Variant = settings.call(&"_dict_to_event", data)
	if not event is InputEventMouseButton:
		_fail("mouse %s -> %s" % [data, event])
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index == button and mouse.ctrl_pressed == ctrl:
		_pass("mouse %s -> button %d ctrl %s" % [data, button, ctrl])
	else:
		_fail("mouse %s -> button %d ctrl %s" % [data, mouse.button_index, mouse.ctrl_pressed])


func _expect_joy_button(settings: Node, data: Dictionary, button: JoyButton) -> void:
	var event: Variant = settings.call(&"_dict_to_event", data)
	if not event is InputEventJoypadButton:
		_fail("joy_button %s -> %s" % [data, event])
		return
	var pad := event as InputEventJoypadButton
	if pad.button_index == button:
		_pass("joy_button %s -> button %d" % [data, button])
	else:
		_fail("joy_button %s -> button %d" % [data, pad.button_index])


func _expect_joy_axis(settings: Node, data: Dictionary, axis: JoyAxis, value: float) -> void:
	var event: Variant = settings.call(&"_dict_to_event", data)
	if not event is InputEventJoypadMotion:
		_fail("joy_axis %s -> %s" % [data, event])
		return
	var motion := event as InputEventJoypadMotion
	if motion.axis == axis and is_equal_approx(motion.axis_value, value):
		_pass("joy_axis %s -> axis %d value %s" % [data, axis, value])
	else:
		_fail("joy_axis %s -> axis %d value %s" % [data, motion.axis, motion.axis_value])


func _check_compile() -> void:
	for path: String in TOUCHED:
		var script: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script is GDScript and (script as GDScript).can_instantiate():
			_pass("compile %s" % path)
		else:
			_fail("compile %s" % path)


func _check_lines() -> void:
	for check: Dictionary in LINE_CHECKS:
		var path: String = check[&"path"]
		var lines := _lines(path)
		var wanted: int = int(check[&"line"])
		if lines.size() < wanted:
			_fail("%s:%d missing (file has %d lines)" % [path, wanted, lines.size()])
			continue
		var text: String = lines[wanted - 1]
		if text.contains(str(check[&"must"])):
			_pass("%s:%d holds %s" % [path, wanted, check[&"must"]])
		else:
			_fail("%s:%d is '%s' (wanted %s)" % [path, wanted, text.strip_edges(), check[&"must"]])


func _check_absence() -> void:
	for check: Dictionary in ABSENCE_CHECKS:
		var path: String = check[&"path"]
		var needle: String = str(check[&"text"])
		var body := FileAccess.get_file_as_string(path)
		if body.contains(needle):
			_fail("%s still contains '%s'" % [path, needle])
		else:
			_pass("%s free of '%s'" % [path, needle])


func _lines(path: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(path).split("\n")


func _pass(label: String) -> void:
	_passed += 1
	print("[W3-PASS] %s" % label)


func _fail(label: String) -> void:
	_failed += 1
	print("[W3-FAIL] %s" % label)
