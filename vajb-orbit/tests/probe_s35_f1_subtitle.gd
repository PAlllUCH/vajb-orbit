extends Node
## S35-F1's evidence probe for D22-P1/F01: the ARMORY pane subtitle follows the mode (the FIT
## CELLS wording in FIT CELLS, the BATTERY CONFIG wording in BATTERY CONFIG). Headless run:
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
##     res://tests/probe_s35_f1_subtitle.tscn --quit-after 300
##
## Prints `[f1]` lines and quits 0. It writes nothing else and never boots the live profile.

const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const ArmoryScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const VANGUARD: StringName = &"ship_vanguard"
const WINDOW := Vector2(1920.0, 1080.0)

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _failures: Array[String] = []


func _ready() -> void:
	var watchdog := get_tree().create_timer(60.0)
	watchdog.timeout.connect(func() -> void:
		print("[f1] WATCHDOG quit")
		get_tree().quit(2)
	)
	_run.call_deferred()


func _run() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[f1] no PlayerProfile autoload")
		get_tree().quit(1)
		return
	_profile.set(&"save_path", "user://probe_s35_f1_subtitle.cfg")
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", [VANGUARD] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})
	get_window().size = Vector2i(int(WINDOW.x), int(WINDOW.y))
	_host = Control.new()
	_host.name = "S35F1Host"
	_host.theme = ThemeRes
	_host.size = WINDOW
	add_child(_host)
	_panel = ArmoryScene.instantiate() as Control
	_host.add_child(_panel)
	await get_tree().process_frame
	_panel.call(&"_lay")
	var subtitle := _panel.get_node(NodePath("%PaneSubtitle")) as Label
	var fit_text := String(subtitle.text)
	print("[f1] fit subtitle='%s'" % fit_text)
	_check(
		fit_text.begins_with("FIT CELLS AND EQUIPMENT")
			and fit_text.find("BATTERY RACKS") == -1,
		"F01 FIT CELLS reads its own subtitle, never the battery wording"
	)
	_check(
		fit_text == ArmoryScript.SUBTITLE_FIT % [
			int(_panel.call(&"_cell_total")), int(_panel.call(&"_owned_module_total"))
		],
		"F01 the FIT subtitle carries the two live counts (cells, owned modules)"
	)
	_panel.call(&"set_mode", ArmoryScript.MODE_BATTERY)
	_panel.call(&"_lay")
	var battery_text := String(subtitle.text)
	print("[f1] battery subtitle='%s'" % battery_text)
	_check(
		battery_text.begins_with("BATTERY RACKS AND AMMUNITION")
			and battery_text.find("FIT CELLS") == -1,
		"F01 BATTERY CONFIG reads the battery wording"
	)
	_panel.call(&"set_mode", ArmoryScript.MODE_FIT)
	_panel.call(&"_lay")
	_check(
		String(subtitle.text).begins_with("FIT CELLS AND EQUIPMENT"),
		"F01 the swap returns to the FIT CELLS wording"
	)
	print("[f1] failures=%d" % _failures.size())
	for line: String in _failures:
		print("[f1] FAIL %s" % line)
	print("[f1] DONE")
	get_tree().quit(0)


func _check(condition: bool, what: String) -> void:
	if not condition:
		_failures.append(what)
	print("[f1] %s %s" % ["ok  " if condition else "FAIL", what])
