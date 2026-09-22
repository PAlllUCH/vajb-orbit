extends Node
## P2-B1 W2 evidence probe: mount the shipped OUTFITTING panel and drive the MODULES
## section and the FITTED WEAPONS strip end to end (STATION_HUB section 5.1's amendment,
## CONTRACTS section 12, wave brief P2-B1 section 3), printing every number the wave
## report cites.
##
##   godot --headless --path vajb-orbit res://tests/probe_p2b1_panel_fit.tscn
##
## The panel reads `/root/PlayerProfile`, so the probe borrows the shipped autoload the way
## `tests/test_p2a_launch_fit.gd` does: its `save_path` is repointed at a scratch file
## before the first mutation, the fields the panel can write are snapshotted and handed
## back at the end, and the store is flushed while the scratch path is still in place, so
## the owner's `user://profile.cfg` is never written (probe hygiene L17).

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const SCRATCH := "user://probe_p2b1_panel_fit.cfg"
const BARE_SCRATCH := "user://probe_p2b1_panel_fit_bare.cfg"
const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const START_CREDITS := 10000
const OVERLOAD_CREDITS := 5000
const FULL_CELL_CREDITS := 2000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _strip: VBoxContainer = null
var _rows: VBoxContainer = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _saved: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[probe] FAILED: the PlayerProfile autoload is the panel's store")
		get_tree().quit()
		return
	_seed_evidence()
	_borrow()
	_seed()
	_mount()
	_row_set()
	_print_strip("start")
	_round_trip()
	_refusals()
	_restore()
	get_tree().quit()


## Why `_seed_fit` exists, measured rather than argued: a bare `set_fit_slot` on a hull the
## account holds no fit for normalises the stored fit from nothing, so the cell write is
## all the hull would then have - no 09 section 7 mandatory set, and an illegal fit.
func _seed_evidence() -> void:
	var bare: Node = load("res://autoload/player_profile.gd").new()
	bare.set(&"save_path", BARE_SCRATCH)
	bare.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, &"w_cannon")
	var fit: Dictionary = bare.call(&"fit_for", VANGUARD)
	var legal: Dictionary = FitData.fit_legal(VANGUARD, fit)
	print("[probe] bare set_fit_slot(weapons, 1, w_cannon) on a hull with no fit:")
	print("[probe]   engines=%s power=%s weapons=%s" % [
		str(fit.get(&"engines", [])), str(fit.get(&"power", "")), str(fit.get(&"weapons", []))
	])
	print("[probe]   fit_legal: legal=%s missing=%s" % [str(legal[&"legal"]), str(legal[&"missing"])])
	bare.free()
	_remove(BARE_SCRATCH)


func _borrow() -> void:
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"owned": _profile.call(&"owned_ships"),
		&"fits": _profile.call(&"fits"),
		&"modules": _profile.call(&"modules"),
	}
	_profile.set(&"save_path", SCRATCH)
	_remove(SCRATCH)


func _seed() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _restore() -> void:
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", StringName(_saved[&"ship"]))
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_saved[&"path"]))
	_remove(SCRATCH)


func _mount() -> void:
	_host = Control.new()
	_host.name = "ProbeHost"
	_host.theme = ThemeRes
	## The station shell sizes the pane, so the probe gives its host a real frame: a
	## zero-size host never settles the two column headers' fit.
	_host.size = _viewport_size()
	add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	## The shell's own wiring (ui/screens/station.gd:_on_profile_changed): every panel is
	## told about every key, and the panel never refreshes itself.
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	_strip = _panel.get_node("%FittedStrip") as VBoxContainer
	_rows = _panel.get_node("%ModuleRows") as VBoxContainer


func _viewport_size() -> Vector2:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(width, height)


func _row_set() -> void:
	var ids: Array[StringName] = _panel.call(&"module_row_ids")
	var parts := PackedStringArray()
	for id: StringName in ids:
		var row := ModuleData.module(id)
		parts.append("%s=%d/draw%d" % [id, int(row[&"cost"]), int(row[&"draw"])])
	print("[probe] MODULES rows=%d %s" % [ids.size(), " ".join(parts)])
	var weapons := 0
	for id: StringName in ModuleData.MODULES:
		if String(ModuleData.slot_of(id)) == "weapons":
			weapons += 1
	print("[probe] catalogue weapon ids=%d (the row set is 09 section 3.1's table)" % weapons)


func _round_trip() -> void:
	print("[probe] -- buy / install / swap / remove round trip --")
	_step("start")
	_buy(&"w_cannon")
	_press(&"w_cannon")
	_step("after BUY + INSTALL w_cannon")
	_buy(&"w_rocket")
	_press(&"w_rocket")
	_step("after BUY + INSTALL w_rocket (every W cell full)")
	_buy(&"w_mine")
	_press(&"w_mine")
	_step("after BUY + SWAP w_mine into W1")
	_strip_remove(0)
	_step("after strip REMOVE of W1")
	_strip_remove(1)
	_step("after strip REMOVE of W2")


func _refusals() -> void:
	print("[probe] -- refusals --")
	_profile.call(&"add_credits", OVERLOAD_CREDITS)
	_buy(&"w_plasma")
	_press(&"w_plasma")
	_step("after INSTALL w_plasma into W1")
	_buy(&"w_plasma")
	_press(&"w_plasma")
	_step("after the refused INSTALL w_plasma")
	print("[probe] overload refusal=%s danger=%s" % [_last_status(), str(_last_danger())])
	_profile.call(&"add_credits", FULL_CELL_CREDITS)
	_buy(&"w_mine")
	_press(&"w_mine")
	_step("after INSTALL w_mine (every W cell full)")
	print("[probe] w_mine action with a full grid = %s" % _action(&"w_mine"))
	var installed := bool(_panel.call(&"install_module", &"w_mine"))
	print("[probe] install_module(w_mine) with no empty cell = %s" % str(installed))
	print("[probe] full-cells refusal=%s danger=%s" % [_last_status(), str(_last_danger())])
	_step("after the full-cells refusal")
	_press(&"w_mine")
	_step("after the row REMOVE of w_mine")
	print("[probe] mandatory set: engines=%s power=%s" % [
		str(_stored_fit().get(&"engines", [])), str(_stored_fit().get(&"power", ""))
	])
	print("[probe] fit_legal missing=%s" % str(
		FitData.fit_legal(VANGUARD, _stored_fit())[&"missing"]
	))


## One line per step: the balance, the panel's own strip lines, the inventory counts the
## rows show, and the footer message the step left behind.
func _step(label: String) -> void:
	var inventory := PackedStringArray()
	for id: StringName in _panel.call(&"module_row_ids"):
		var count := int(_profile.call(&"module_count", id))
		if count > 0:
			inventory.append("%s:%d" % [id, count])
	print("[probe] %s: credits=%d inv=[%s]" % [
		label, int(_profile.call(&"credits")), " ".join(inventory)
	])
	print("[probe]   strip=[%s]" % " | ".join(_strip_lines()))


func _print_strip(label: String) -> void:
	print("[probe] FITTED WEAPONS (%s): [%s]" % [label, " | ".join(_strip_lines())])
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var remove := line.get_node_or_null(^"Remove") as Button
		print("[probe]   %s remove visible=%s" % [
			line.name, str(remove != null and remove.visible)
		])


func _strip_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _buy(module_id: StringName) -> void:
	print("[probe] buy_module(%s, %d) = %s" % [
		module_id,
		int(ModuleData.module(module_id)[&"cost"]),
		str(_panel.call(&"buy_module", module_id)),
	])


func _press(module_id: StringName) -> void:
	print("[probe] press %s row (action=%s)" % [module_id, _action(module_id)])
	_row(module_id).pressed.emit()


func _strip_remove(index: int) -> void:
	var line := _strip.get_child(index) as HBoxContainer
	var remove := line.get_node(^"Remove") as Button
	print("[probe] press strip REMOVE on %s" % line.name)
	remove.pressed.emit()


func _action(module_id: StringName) -> String:
	return String(_panel.call(&"module_action", module_id))


func _row(module_id: StringName) -> Button:
	for child: Node in _rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _stored_fit() -> Dictionary:
	return _profile.call(&"fit_for", VANGUARD)


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
