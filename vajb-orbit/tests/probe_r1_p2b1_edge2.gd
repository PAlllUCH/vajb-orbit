extends Node
## P2-B1 R1 review probe, third pass: the three checks the first two passes left open.
##
##   1. the focus order of STATION_HUB section 5.1 (strip, then module rows, then ammo);
##   2. a fitted *instance* id whose inventory record INSTALL's own `take_module` removed
##      (15 section 6): can the panel still resolve it to its base id?
##   3. 09 section 2's power arithmetic: `sum(draws) <= hull power_out + power module`,
##      measured by swapping `p_std` for `p_mk2` and re-running the same candidate.
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_edge2.tscn

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_edge2.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_edge2.log"
const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _strip: VBoxContainer = null
var _module_rows: VBoxContainer = null
var _status: Array[String] = []
var _saved: Dictionary = {}
var _log_path_before := ""


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1c] FAILED: no PlayerProfile autoload")
		get_tree().quit()
		return
	_borrow()
	_mount()
	_c1_focus()
	_c2_instance()
	_c3_power_arithmetic()
	_restore()
	print("[r1c] == done ==")
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
	_host.name = "R1cHost"
	_host.theme = ThemeRes
	_host.size = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	_strip = _panel.get_node("%FittedStrip") as VBoxContainer
	_module_rows = _panel.get_node("%ModuleRows") as VBoxContainer


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


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _row(module_id: StringName) -> Button:
	for child: Node in _module_rows.get_children():
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


func _strip_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _focus_name() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null:
		return "<none>"
	return "%s/%s" % [owner.get_parent().name, owner.name]


## ------------------------------------------------------------ 1. the focus order


func _c1_focus() -> void:
	print("[r1c] == 1. the focus order (STATION_HUB 5.1: strip, module rows, ammo) ==")
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_panel.call(&"refresh_profile", &"fits")
	_panel.call(&"focus_primary")
	print("[r1c] with the standard fit (W1 fitted): focus owner=%s" % _focus_name())
	_panel.call(&"remove_module", 0)
	_panel.call(&"focus_primary")
	print("[r1c] with every W cell empty: focus owner=%s (row=%s)" % [
		_focus_name(), _row(&"w_laser").get_meta(&"id", &"")
	])
	print("[r1c] the strip's first line is still the strip's own, REMOVE hidden=%s" % str(
		((_strip.get_child(0) as HBoxContainer).get_node_or_null(^"Remove") as Button).visible
	))
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	_panel.call(&"refresh_profile", &"fits")


## ---------------------------------------------- 2. an instance id taken by INSTALL


func _c2_instance() -> void:
	print("[r1c] == 2. a fitted instance id whose inventory record INSTALL's take_module removed ==")
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {"mod_0007": {&"base_id": "w_cannon", &"count": 1, &"rarity": "rare"}})
	_profile.call(&"set_fit", VANGUARD, {
		&"weapons": ["mod_0007", "", ""],
		&"engines": ["e_std"],
		&"power": "p_std",
	})
	_panel.call(&"refresh_profile", &"fits")
	print("[r1c] while the record exists: modules=%s" % str(_profile.call(&"modules")))
	print("[r1c]   strip=%s ; w_cannon status='%s' action='%s' ; fit_index_of=%d" % [
		str(_strip_lines()), _cell(&"w_cannon", "Status"), String(_panel.call(&"module_action", &"w_cannon")),
		int(_panel.call(&"fit_index_of", &"w_cannon"))
	])
	## What INSTALL does before it writes the cell: the instance leaves the inventory.
	var taken := bool(_profile.call(&"take_module", &"mod_0007", 1))
	print("[r1c] take_module(mod_0007, 1) = %s ; modules=%s" % [str(taken), str(_profile.call(&"modules"))])
	_panel.call(&"refresh_profile", &"modules")
	print("[r1c] after the take: strip=%s" % str(_strip_lines()))
	print("[r1c]   w_cannon status='%s' action='%s' ; fit_index_of=%d" % [
		_cell(&"w_cannon", "Status"), String(_panel.call(&"module_action", &"w_cannon")),
		int(_panel.call(&"fit_index_of", &"w_cannon"))
	])
	var before := _status.size()
	print("[r1c]   the strip's REMOVE on W1: %s" % str(
		(_strip.get_child(0) as HBoxContainer).get_node_or_null(^"Remove") is Button
	))
	var removed := bool(_panel.call(&"remove_module", 0))
	print("[r1c]   remove_module(0) = %s | footer=%s | modules=%s" % [
		str(removed),
		str(_status.slice(before)) if _status.size() > before else "[]",
		str(_profile.call(&"modules"))
	])


## ------------------------------------- 3. 09 section 2's own power arithmetic


func _c3_power_arithmetic() -> void:
	print("[r1c] == 3. 09 section 2: sum(draws) <= hull power_out + power module ==")
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 40000)
	_panel.call(&"refresh_profile", &"fits")
	print("[r1c] Vanguard power_out=%d ; p_std effect=%s ; p_mk2 effect=%s" % [
		int(FitData.HULLS[VANGUARD][&"power_out"]),
		str(ModuleData.module(&"p_std").get(&"effects", {})),
		str(ModuleData.module(&"p_mk2").get(&"effects", {})),
	])
	## Three plasma coils (3 draws each) plus the standard fit's light shield: 11 > 8.
	var candidate := {
		&"weapons": ["w_plasma", "w_plasma", "w_plasma"],
		&"shields": ["s_light"],
		&"engines": ["e_std"],
		&"power": "p_std",
	}
	var legal_std := FitData.fit_legal(VANGUARD, candidate)
	print("[r1c] three plasma + light shield with p_std: power=%s legal=%s" % [
		str(legal_std[&"power"]), str(legal_std[&"legal"])
	])
	candidate[&"power"] = "p_mk2"
	var legal_mk2 := FitData.fit_legal(VANGUARD, candidate)
	print("[r1c] the same fit with p_mk2 (+2 output): power=%s legal=%s" % [
		str(legal_mk2[&"power"]), str(legal_mk2[&"legal"])
	])
	## And through the pane: with p_mk2 stored, the third plasma installs.
	_profile.call(&"set_fit", VANGUARD, {
		&"weapons": ["w_plasma", "w_plasma", ""],
		&"shields": ["s_light"],
		&"engines": ["e_std"],
		&"power": "p_mk2",
	})
	_profile.call(&"add_module", &"w_plasma", 1)
	_panel.call(&"refresh_profile", &"fits")
	var before := _status.size()
	print("[r1c] install the third plasma with p_mk2: %s | footer=%s" % [
		str(_panel.call(&"install_module", &"w_plasma")),
		str(_status.slice(before)) if _status.size() > before else "[]"
	])
	print("[r1c] cells=%s fit_legal=%s" % [
		str(_profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]),
		str(FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"legal"])
	])
