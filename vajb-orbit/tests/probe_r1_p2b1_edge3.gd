extends Node
## P2-B1 R1 review probe, fourth pass: the two remaining read-offs.
##
##   1. what the strip renders for a fitted *instance* id once its inventory record is
##      gone (the state INSTALL's own `take_module` produces), after a fit-key refresh;
##   2. the pane's stale copy: the subtitle and the panel tag still describe an
##      ammunition-only surface (W2 report finding 11.6).
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_edge3.tscn

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Log := preload("res://game/economy_log.gd")
const FitData := preload("res://game/ship_fit.gd")

const SCRATCH := "user://probe_r1_p2b1_edge3.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_edge3.log"
const VANGUARD: StringName = &"ship_vanguard"

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _saved: Dictionary = {}
var _log_path_before := ""


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1d] FAILED: no PlayerProfile autoload")
		get_tree().quit()
		return
	_borrow()
	_mount()
	_d1_instance_refresh()
	_d2_stale_copy()
	_restore()
	print("[r1d] == done ==")
	get_tree().quit()


func _borrow() -> void:
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"owned": _profile.call(&"owned_ships"),
		&"fits": _profile.call(&"fits"),
		&"modules": _profile.call(&"modules"),
	}
	_log_path_before = String(Log.log_path)
	Log.log_path = LOG_SCRATCH
	_remove(LOG_SCRATCH)
	_profile.set(&"save_path", SCRATCH)
	_remove(SCRATCH)
	_profile.set(&"_credits", 40000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", [VANGUARD] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _mount() -> void:
	_host = Control.new()
	_host.name = "R1dHost"
	_host.theme = ThemeRes
	_host.size = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))


func _restore() -> void:
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", StringName(_saved[&"ship"]))
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_saved[&"path"]))
	_remove(SCRATCH)
	_remove(LOG_SCRATCH)
	Log.log_path = _log_path_before


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _strip_lines() -> PackedStringArray:
	var strip := _panel.get_node("%FittedStrip") as VBoxContainer
	var lines := PackedStringArray()
	for index in strip.get_child_count():
		var line := strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _row(module_id: StringName) -> Button:
	var rows := _panel.get_node("%ModuleRows") as VBoxContainer
	for child: Node in rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _cell(module_id: StringName, cell_name: String) -> String:
	var row := _row(module_id)
	if row == null:
		return "<no row>"
	var box := row.find_child(cell_name, true, false) as Control
	if box == null:
		return "<no cell>"
	var value := box.get_node_or_null(^"Value") as Label
	return value.text if value != null else "<no value>"


func _d1_instance_refresh() -> void:
	print("[r1d] == 1. a fitted instance id with no inventory record, after a fit-key refresh ==")
	_profile.set(&"_modules", {"mod_0007": {&"base_id": "w_cannon", &"count": 1, &"rarity": "rare"}})
	_profile.call(&"set_fit", VANGUARD, {
		&"weapons": ["mod_0007", "", ""],
		&"engines": ["e_std"],
		&"power": "p_std",
	})
	_panel.call(&"refresh_profile", &"fits")
	print("[r1d] record present: strip=%s" % str(_strip_lines()))
	print("[r1d]   w_cannon status='%s' fit_index_of=%d" % [
		_cell(&"w_cannon", "Status"), int(_panel.call(&"fit_index_of", &"w_cannon"))
	])
	_profile.call(&"take_module", &"mod_0007", 1)
	_panel.call(&"refresh_profile", &"fits")
	print("[r1d] record gone:   strip=%s" % str(_strip_lines()))
	print("[r1d]   w_cannon status='%s' fit_index_of=%d action='%s'" % [
		_cell(&"w_cannon", "Status"), int(_panel.call(&"fit_index_of", &"w_cannon")),
		String(_panel.call(&"module_action", &"w_cannon"))
	])
	print("[r1d]   base_module_id(mod_0007)=%s (the record is gone)" % String(
		_profile.call(&"base_module_id", &"mod_0007")
	))
	## The contrast: a *base* id fitted and taken (the shipped flow) still resolves.
	_profile.set(&"_modules", {})
	_profile.call(&"set_fit", VANGUARD, {
		&"weapons": ["w_cannon", "", ""],
		&"engines": ["e_std"],
		&"power": "p_std",
	})
	_profile.call(&"take_module", &"w_cannon", 1)
	_panel.call(&"refresh_profile", &"fits")
	print("[r1d] a base id in the same state: strip=%s ; w_cannon status='%s' fit_index_of=%d" % [
		str(_strip_lines()), _cell(&"w_cannon", "Status"), int(_panel.call(&"fit_index_of", &"w_cannon"))
	])


func _d2_stale_copy() -> void:
	print("[r1d] == 2. the pane's stale copy (W2 finding 11.6) ==")
	print("[r1d] PaneSubtitle='%s'" % String((_panel.get_node("%PaneSubtitle") as Label).text))
	print("[r1d] PanelTag='%s'" % String((_panel.get_node("%PanelTag") as Label).text))
	print("[r1d] the pane's module rows=%s" % str(_panel.call(&"module_row_ids")))
	var ammo := _panel.get_node("%OutfittingRows") as VBoxContainer
	print("[r1d] ammo rows in the same pane=%d" % ammo.get_child_count())
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
