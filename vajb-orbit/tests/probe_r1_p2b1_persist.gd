extends Node
## P2-B1 R1 review probe: do the panel's own writes survive a save / reload round trip?
##
## W1's probe measured `buy_module`'s persistence and W2's probe measured the panel's
## in-memory round trip; neither re-reads the file after a panel-driven INSTALL / SWAP /
## REMOVE. This probe drives the shipped pane and, after every step, flushes the store,
## re-reads the scratch file with `ConfigFile` (printing `save_version` and the two
## sections verbatim) and reloads the profile through `reload()` to compare the live state
## with the filed one.
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_persist.tscn
##
## Hygiene (L17): `save_path` is repointed at a scratch file before the first mutation,
## every field the pane can write is snapshotted and handed back, the store is flushed
## while the scratch path is still in place, and both scratch files are removed - so the
## owner's `user://profile.cfg` is never written.

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_persist.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_persist.log"
const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const START_CREDITS := 20000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _strip: VBoxContainer = null
var _module_rows: VBoxContainer = null
var _saved: Dictionary = {}
var _log_path_before := ""
var _signals: Array[String] = []
var _status: Array[String] = []


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1p] FAILED: the PlayerProfile autoload is the pane's store")
		get_tree().quit()
		return
	_borrow()
	_seed()
	_mount()
	_step_1_install()
	_step_2_swap()
	_step_3_remove()
	_step_4_log()
	_restore()
	print("[r1p] == done ==")
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
	_host.name = "R1PersistHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920, 1080)
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


func _on_changed(key: StringName) -> void:
	_signals.append(String(key))


func _on_status(message: String, danger: bool) -> void:
	_status.append("%s/danger=%s" % [message, str(danger)])


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------------------------ read-backs


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


func _press(module_id: StringName) -> void:
	var row := _row(module_id)
	if row == null:
		print("[r1p] press %s: no row" % module_id)
		return
	row.pressed.emit()


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


func _strip_texts() -> PackedStringArray:
	var lines := PackedStringArray()
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _inventory() -> String:
	var parts := PackedStringArray()
	for id: StringName in [
		&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_railgun"
	]:
		var held := int(_profile.call(&"module_count", id))
		if held > 0:
			parts.append("%s:%d" % [id, held])
	return "[" + " ".join(parts) + "]"


func _state(label: String) -> void:
	print("[r1p] %s | credits=%d cells=%s inv=%s" % [
		label, int(_profile.call(&"credits")), str(_cells()), _inventory()
	])
	print("[r1p]   strip=%s" % str(_strip_texts()))


## The filed record, read straight out of the scratch file, not from the profile.
func _filed(label: String) -> void:
	var config := ConfigFile.new()
	var err := config.load(SCRATCH)
	if err != OK:
		print("[r1p] %s: the scratch file did not load (error %d)" % [label, err])
		return
	print("[r1p] %s: save_version=%s" % [
		label, str(config.get_value("profile", "save_version", "<none>"))
	])
	print("[r1p]   filed fits=%s" % str(config.get_value("profile", "fits", {})))
	print("[r1p]   filed modules=%s" % str(config.get_value("profile", "modules", {})))
	print("[r1p]   filed credits=%s" % str(config.get_value("profile", "credits", "<none>")))


## Save, re-read the file, reload the profile and re-render the pane from the reloaded
## state (a reload emits nothing, so the pane is told the keys by hand).
func _round_trip(label: String) -> void:
	_profile.call(&"flush")
	_filed(label)
	_profile.call(&"reload")
	_panel.call(&"refresh_profile", &"fits")
	_panel.call(&"refresh_profile", &"modules")
	_panel.call(&"refresh_profile", &"credits")
	print("[r1p] %s: reloaded credits=%d cells=%s inv=%s legal=%s" % [
		label,
		int(_profile.call(&"credits")),
		str(_cells()),
		_inventory(),
		str(FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"legal"]),
	])
	print("[r1p]   strip after reload=%s" % str(_strip_texts()))
	var statuses := PackedStringArray()
	for id: StringName in _panel.call(&"module_row_ids"):
		statuses.append("%s %s/%s" % [id, _cell(id, "Status"), _cell(id, "Action")])
	print("[r1p]   rows after reload=%s" % str(statuses))


## ------------------------------------------------------------------ the steps


func _step_1_install() -> void:
	print("[r1p] == 1. BUY + INSTALL w_cannon through the pane ==")
	_state("start")
	var ok := bool(_panel.call(&"buy_module", &"w_cannon"))
	print("[r1p]   panel.buy_module(w_cannon) = %s (catalogue cost %d)" % [
		str(ok), int(ModuleData.module(&"w_cannon").get(&"cost", -1))
	])
	_press(&"w_cannon")
	var footer := _status[_status.size() - 1] if not _status.is_empty() else "<none>"
	print("[r1p]   pressed the w_cannon row: footer=%s" % footer)
	_state("after BUY + INSTALL")
	_round_trip("after BUY + INSTALL")


func _step_2_swap() -> void:
	print("[r1p] == 2. fill the grid, then SWAP w_mine into W1 ==")
	_panel.call(&"buy_module", &"w_rocket")
	_press(&"w_rocket")
	_state("after BUY + INSTALL w_rocket (grid full)")
	_panel.call(&"buy_module", &"w_mine")
	_press(&"w_mine")
	var footer := _status[_status.size() - 1] if not _status.is_empty() else "<none>"
	print("[r1p]   pressed w_mine (action=%s): footer=%s" % [
		str(_panel.call(&"module_action", &"w_mine")), footer
	])
	_state("after BUY + SWAP w_mine into W1")
	_round_trip("after SWAP")


func _step_3_remove() -> void:
	print("[r1p] == 3. the strip's REMOVE on W1, then W2 ==")
	var line := _strip.get_child(0) as HBoxContainer
	var remove := line.get_node_or_null(^"Remove") as Button
	print("[r1p]   strip W1 REMOVE visible=%s disabled=%s" % [
		str(remove.visible), str(remove.disabled)
	])
	remove.pressed.emit()
	_state("after the strip REMOVE of W1")
	var line2 := _strip.get_child(1) as HBoxContainer
	var remove2 := line2.get_node_or_null(^"Remove") as Button
	remove2.pressed.emit()
	_state("after the strip REMOVE of W2")
	_round_trip("after both REMOVEs")


func _step_4_log() -> void:
	print("[r1p] == 4. the economy log after the whole sequence ==")
	var lines := PackedStringArray()
	var file := FileAccess.open(LOG_SCRATCH, FileAccess.READ)
	if file != null:
		for line: String in file.get_as_text().split("\n"):
			if not line.strip_edges().is_empty():
				lines.append(line.strip_edges())
		file.close()
	print("[r1p] log lines=%d" % lines.size())
	for line: String in lines:
		print("[r1p]   %s" % line)
	print("[r1p] signal keys seen=%s" % str(_signals))
