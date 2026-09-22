extends Node
## P2-B1 R1 review probe, second pass: the states the first pass could not reach in one
## sequence, each measured on the shipped pane behind the shell's own wiring.
##
##   1. the full-cells refusal with a genuinely full W grid, byte-compared with
##      STATION_HUB section 5.1's own line, and the same state's SWAP;
##   2. install calls the pin's ACTION chain never makes (nothing owned, a module with
##      no row, an empty cell, an id outside the weapon slot);
##   3. a hull with no stored fit (the destroyer, 7 W cells): the seed and its legality;
##   4. the standard-fit fallback: clear_fit and the strip;
##   5. a module *instance* id in the fit (15 section 6) and what REMOVE hands back;
##   6. the seam's price trust (`buy_module(id, wrong_cost)`);
##   7. profile_changed driving the rows, wired and unwired.
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_edge.tscn

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_edge.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_edge.log"
const DOC_HUB := "res://../docs/design/STATION_HUB.md"

const VANGUARD: StringName = &"ship_vanguard"
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const START_CREDITS := 40000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _strip: VBoxContainer = null
var _module_rows: VBoxContainer = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _signals: Array[String] = []
var _saved: Dictionary = {}
var _log_path_before := ""


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1b] FAILED: no PlayerProfile autoload")
		get_tree().quit()
		return
	_borrow()
	_seed()
	_mount()
	_s1_full_cells()
	_s2_chain_gaps()
	_s3_bare_hull()
	_s4_fallback()
	_s5_instance()
	_s6_price_trust()
	_s7_refresh()
	_restore()
	print("[r1b] == done ==")
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
	_profile.connect(&"profile_changed", _on_changed)


func _seed() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _mount() -> void:
	_host = Control.new()
	_host.name = "R1bHost"
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
	_danger.append(danger)


func _on_changed(key: StringName) -> void:
	_signals.append(String(key))


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _quoted(path: String, marker: String) -> String:
	for raw: String in FileAccess.get_file_as_string(path).split("\n"):
		if raw.find(marker) == -1:
			continue
		var open := raw.find("`")
		var close := raw.find("`", open + 1)
		if open >= 0 and close > open:
			return raw.substr(open + 1, close - open - 1)
	return ""


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


func _action(module_id: StringName) -> String:
	return String(_panel.call(&"module_action", module_id))


func _strip_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _owned(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _credits() -> int:
	return int(_profile.call(&"credits"))


func _fit(hull: StringName) -> Dictionary:
	return _profile.call(&"fit_for", hull)


func _watch() -> int:
	return _status.size()


func _since(mark: int) -> String:
	var out := PackedStringArray()
	for index in range(mark, _status.size()):
		out.append("%s/danger=%s" % [_status[index], str(_danger[index])])
	return str(out)


func _reset_fits() -> void:
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_panel.call(&"refresh_profile", &"fits")


## ------------------------------------------------ 1. the full-cells refusal


func _s1_full_cells() -> void:
	print("[r1b] == 1. the full-cells refusal, grid genuinely full ==")
	_reset_fits()
	## Fill all three Vanguard W cells legally: three one-draw weapons plus the light
	## shield is 5 of the hull's 8 power.
	for id: StringName in [&"w_laser", &"w_cannon", &"w_mine"]:
		_panel.call(&"buy_module", id)
		_panel.call(&"install_module", id)
	print("[r1b] cells=%s strip=%s" % [str(_fit(VANGUARD)[WEAPON_SLOT]), str(_strip_lines())])
	print("[r1b] slot_capacity=%d ; fit_legal=%s" % [
		FitData.slot_capacity(VANGUARD, WEAPON_SLOT),
		str(FitData.fit_legal(VANGUARD, _fit(VANGUARD))[&"legal"])
	])
	_panel.call(&"buy_module", &"w_plasma")
	var mark := _watch()
	var owned_before := _owned(&"w_plasma")
	var cells_before := str(_fit(VANGUARD)[WEAPON_SLOT])
	var credits_before := _credits()
	print("[r1b] w_plasma action with a full grid and one owned=%s" % _action(&"w_plasma"))
	print("[r1b] install_module(w_plasma) = %s" % str(_panel.call(&"install_module", &"w_plasma")))
	print("[r1b] footer emitted=%s" % _since(mark))
	var hub_line := _quoted(DOC_HUB, "W SLOTS FULL")
	print("[r1b] STATION_HUB 5.1's own line='%s' ; rendered='%s' ; equal=%s" % [
		hub_line, _status[_status.size() - 1] if _status.size() > 0 else "<none>",
		str((_status[_status.size() - 1] if _status.size() > 0 else "") == hub_line),
	])
	print("[r1b] nothing written: cells unchanged=%s owned unchanged=%s credits unchanged=%s" % [
		str(str(_fit(VANGUARD)[WEAPON_SLOT]) == cells_before),
		str(_owned(&"w_plasma") == owned_before),
		str(_credits() == credits_before),
	])
	## The same state's SWAP, through the row's own press.
	mark = _watch()
	print("[r1b] press the w_plasma row (action=%s)" % _action(&"w_plasma"))
	_row(&"w_plasma").pressed.emit()
	print("[r1b] after SWAP: cells=%s strip=%s footer=%s" % [
		str(_fit(VANGUARD)[WEAPON_SLOT]), str(_strip_lines()), _since(mark)
	])
	print("[r1b] the displaced module came back: w_laser owned=%d" % _owned(&"w_laser"))


## ------------------------------------------------ 2. the chain's own gaps


func _s2_chain_gaps() -> void:
	print("[r1b] == 2. install calls the pin's ACTION chain never makes ==")
	_reset_fits()
	## (a) nothing owned, an empty cell exists.
	var mark := _watch()
	print("[r1b] install_module(w_railgun) with none owned = %s | footer=%s | cells=%s" % [
		str(_panel.call(&"install_module", &"w_railgun")), _since(mark), str(_fit(VANGUARD)[WEAPON_SLOT])
	])
	## (b) a weapon module with no row on this surface.
	_panel.call(&"buy_module", &"w_mining")
	mark = _watch()
	print("[r1b] w_mining owned=%d ; panel.install_module(w_mining) = %s | footer=%s | cells=%s" % [
		_owned(&"w_mining"), str(_panel.call(&"install_module", &"w_mining")), _since(mark),
		str(_fit(VANGUARD)[WEAPON_SLOT])
	])
	print("[r1b]   strip=%s ; fit_legal=%s" % [
		str(_strip_lines()), str(FitData.fit_legal(VANGUARD, _fit(VANGUARD))[&"legal"])
	])
	print("[r1b]   (the mining laser can be fitted, but never bought from a row)")
	## (c) a module id whose slot is not weapons.
	mark = _watch()
	print("[r1b] install_module(s_light) = %s | swap_module(s_light, 0) = %s | footer=%s" % [
		str(_panel.call(&"install_module", &"s_light")),
		str(_panel.call(&"swap_module", &"s_light", 0)),
		_since(mark),
	])
	## (d) an out-of-range index.
	mark = _watch()
	print("[r1b] swap_module(w_cannon, 9) = %s | remove_module(9) = %s | remove_module(-1) = %s | footer=%s" % [
		str(_panel.call(&"swap_module", &"w_cannon", 9)),
		str(_panel.call(&"remove_module", 9)),
		str(_panel.call(&"remove_module", -1)),
		_since(mark),
	])
	## (e) an empty cell.
	mark = _watch()
	print("[r1b] remove_module(2) (empty cell) = %s | footer=%s" % [
		str(_panel.call(&"remove_module", 2)), _since(mark)
	])


## ------------------------------------------------ 3. a hull with no stored fit


func _s3_bare_hull() -> void:
	print("[r1b] == 3. a hull with no stored fit (the destroyer, 7 W cells) ==")
	_reset_fits()
	_profile.set(&"_credits", 60000)
	_profile.call(&"buy_ship", DESTROYER, 1000)
	_profile.call(&"set_active_ship", DESTROYER)
	_panel.call(&"refresh_profile", &"ships")
	print("[r1b] destroyer stored fit before any write=%s" % str(_fit(DESTROYER)))
	print("[r1b] strip (the standard-fit fallback)=%s" % str(_strip_lines()))
	print("[r1b] install_module(w_cannon) with none owned=%s | action=%s" % [
		str(_panel.call(&"install_module", &"w_cannon")), _action(&"w_cannon")
	])
	_panel.call(&"buy_module", &"w_cannon")
	print("[r1b] after BUY: action=%s" % _action(&"w_cannon"))
	print("[r1b] install_module(w_cannon) = %s" % str(_panel.call(&"install_module", &"w_cannon")))
	var fit := _fit(DESTROYER)
	var legal := FitData.fit_legal(DESTROYER, fit)
	print("[r1b] after INSTALL: weapons=%s engines=%s power=%s strip=%s" % [
		str(fit[WEAPON_SLOT]), str(fit[&"engines"]), str(fit[&"power"]), str(_strip_lines())
	])
	print("[r1b] fit_legal legal=%s missing=%s overflow=%s power=%s" % [
		str(legal[&"legal"]), str(legal[&"missing"]), str(legal[&"overflow"]), str(legal[&"power"])
	])
	var standard: Dictionary = FitData.standard_fit(DESTROYER)
	var same_keys := true
	for key: StringName in [&"engines", &"power", &"shields", &"armour", &"computers", &"boosters", &"utility"]:
		if str(fit[key]) != str(standard[key]):
			same_keys = false
	print("[r1b] every type but weapons matches 09 section 9's standard fit=%s (%s vs %s)" % [
		str(same_keys), str(fit[&"engines"]), str(standard[&"engines"])
	])
	_profile.call(&"set_active_ship", VANGUARD)
	_panel.call(&"refresh_profile", &"ships")


## ------------------------------------------------ 4. the standard-fit fallback


func _s4_fallback() -> void:
	print("[r1b] == 4. the standard-fit fallback (`clear_fit`) ==")
	_reset_fits()
	_panel.call(&"buy_module", &"w_railgun")
	_panel.call(&"install_module", &"w_railgun")
	print("[r1b] after INSTALL w_railgun: cells=%s strip=%s status='%s' action='%s'" % [
		str(_fit(VANGUARD)[WEAPON_SLOT]), str(_strip_lines()),
		_cell(&"w_railgun", "Status"), _action(&"w_railgun")
	])
	_profile.call(&"clear_fit", VANGUARD)
	_panel.call(&"refresh_profile", &"fits")
	print("[r1b] after clear_fit: cells=%s strip=%s" % [
		str(_fit(VANGUARD)[WEAPON_SLOT]), str(_strip_lines())
	])
	print("[r1b]   w_railgun status='%s' action='%s' ; w_laser status='%s' action='%s'" % [
		_cell(&"w_railgun", "Status"), _action(&"w_railgun"),
		_cell(&"w_laser", "Status"), _action(&"w_laser")
	])
	print("[r1b]   fit_legal of the cleared (all-empty) stored fit=%s" % str(
		FitData.fit_legal(VANGUARD, _fit(VANGUARD))[&"legal"]
	))


## ------------------------------------------------ 5. an instance id in the fit


func _s5_instance() -> void:
	print("[r1b] == 5. a module instance id in the fit (15 section 6) ==")
	_reset_fits()
	var records: Dictionary = {
		"mod_0007": {&"base_id": "w_cannon", &"count": 1, &"rarity": "rare"},
	}
	_profile.set(&"_modules", records)
	_profile.call(&"set_fit", VANGUARD, {
		&"weapons": ["mod_0007", "", ""],
		&"engines": ["e_std"],
		&"power": "p_std",
	})
	_panel.call(&"refresh_profile", &"fits")
	print("[r1b] stored fit weapons=%s" % str(_fit(VANGUARD)[WEAPON_SLOT]))
	print("[r1b] strip=%s" % str(_strip_lines()))
	print("[r1b] w_cannon status='%s' action='%s'" % [_cell(&"w_cannon", "Status"), _action(&"w_cannon")])
	_panel.call(&"remove_module", 0)
	print("[r1b] after REMOVE of the instance cell: weapons=%s modules=%s" % [
		str(_fit(VANGUARD)[WEAPON_SLOT]), str(_profile.call(&"modules"))
	])


## ------------------------------------------------ 6. the seam's price trust


func _s6_price_trust() -> void:
	print("[r1b] == 6. the seam charges what the caller passes ==")
	_reset_fits()
	var before := _credits()
	print("[r1b] catalogue cost(w_railgun)=%d ; panel.buy_module charges the catalogue's own price" % int(
		ModuleData.module(&"w_railgun").get(&"cost", -1)
	))
	print("[r1b] profile.buy_module(w_railgun, 1) = %s | credits %d -> %d | owned=%d" % [
		str(_profile.call(&"buy_module", &"w_railgun", 1)), before, _credits(), _owned(&"w_railgun")
	])
	_profile.call(&"take_module", &"w_railgun", _owned(&"w_railgun"))


## ------------------------------------------------ 7. the refresh keys


func _s7_refresh() -> void:
	print("[r1b] == 7. profile_changed driving the rows ==")
	_reset_fits()
	print("[r1b] wired: w_cannon status before='%s'" % _cell(&"w_cannon", "Status"))
	_profile.call(&"add_module", &"w_cannon", 1)
	print("[r1b] wired: after profile.add_module(w_cannon) status='%s' action='%s'" % [
		_cell(&"w_cannon", "Status"), _action(&"w_cannon")
	])
	_profile.disconnect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_profile.call(&"add_module", &"w_cannon", 1)
	print("[r1b] unwired: after a second add_module status='%s' (stale = the signal is the refresh)" % _cell(&"w_cannon", "Status"))
	print("[r1b] unwired: after profile.set_fit_slot(...) the strip=%s" % str(_strip_lines()))
	_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, &"w_rocket")
	print("[r1b] unwired: stored cells=%s but strip=%s" % [
		str(_fit(VANGUARD)[WEAPON_SLOT]), str(_strip_lines())
	])
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.call(&"refresh_profile", &"fits")
	print("[r1b] re-connected: strip=%s" % str(_strip_lines()))
	print("[r1b] signal keys seen across the probe=%s" % str(_signals))
