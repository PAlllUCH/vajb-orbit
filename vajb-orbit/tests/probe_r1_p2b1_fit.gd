extends Node
## P2-B1 R1 review probe (independent of W2's probe): mount the shipped OUTFITTING
## pane and re-measure the wave's own claims from the outside - the row table against
## 09 section 3.1 parsed out of the document, the buy / install / swap / remove round
## trip, every refusal with its exact wording, the mandatory set, the acquisition door
## every weapon module has, and 17 section 5's transaction law (one line per buy).
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_fit.tscn
##
## Borrows the shipped `PlayerProfile` autoload exactly as W2's probe does: `save_path`
## is repointed at a scratch file before the first mutation, every field the pane can
## write is snapshotted and handed back, the store is flushed while the scratch path is
## still in place, and the scratch file is removed - so the owner's `user://profile.cfg`
## is never written (probe hygiene L17).

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_fit.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_fit.log"
const DOC_09 := "res://../docs/gameplay/09_ship_slots_modules.md"
const DOC_HUB := "res://../docs/design/STATION_HUB.md"

const VANGUARD: StringName = &"ship_vanguard"
const LANCER: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const START_CREDITS := 20000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _strip: VBoxContainer = null
var _module_rows: VBoxContainer = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _signals: Array[String] = []
var _failed: Array[String] = []
var _saved: Dictionary = {}
var _log_path_before := ""


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1] FAILED: the PlayerProfile autoload is the pane's store")
		get_tree().quit()
		return
	_borrow()
	_seed()
	_mount()
	_row_table()
	_the_door()
	_round_trip()
	_refusals()
	_mandatory_set()
	_strip_across_hulls()
	_transaction_law()
	_restore()
	get_tree().quit()


## --------------------------------------------------------------- the harness


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
	_profile.connect(&"purchase_failed", _on_failed)


func _seed() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _mount() -> void:
	_host = Control.new()
	_host.name = "R1Host"
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


func _on_failed(reason: StringName, id: StringName) -> void:
	_failed.append("%s/%s" % [String(reason), String(id)])


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else "<none>"


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _log_lines() -> int:
	var count := 0
	var file := FileAccess.open(LOG_SCRATCH, FileAccess.READ)
	if file == null:
		return 0
	for line: String in file.get_as_text().split("\n"):
		if not line.strip_edges().is_empty():
			count += 1
	file.close()
	return count


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------- 09 section 3.1, out of the document


## Every backticked id of 09 section 3.1's WEAPONS table with its draw, cost and effect,
## parsed by R1 rather than read from W2's suite.
func _doc_table() -> Dictionary:
	var lines := FileAccess.get_file_as_string(DOC_09).split("\n")
	var ids := PackedStringArray()
	var rows: Dictionary = {}
	var inside := false
	for raw: String in lines:
		var line := raw.strip_edges()
		if line.begins_with("### 3.1 WEAPONS"):
			inside = true
			continue
		if inside and line.begins_with("#"):
			break
		if not inside or not line.begins_with("|"):
			continue
		var cells := line.split("|", false)
		if cells.size() != 7:
			continue
		var id_text := String(cells[0]).strip_edges().trim_prefix("`").trim_suffix("`")
		if id_text.is_empty() or id_text == "Module":
			continue
		if id_text.replace("-", "").is_empty():
			continue
		ids.append(id_text)
		rows[id_text] = {
			&"draw": int(String(cells[2]).strip_edges()),
			&"cost": int(
				String(cells[6]).strip_edges().replace(" ", "").replace("\u00a0", "")
			),
			&"effect": String(cells[5]).strip_edges(),
		}
	return {&"ids": ids, &"rows": rows}


## The first backticked string on a line carrying `marker` (the two refusal wordings and
## 09 section 2's own overload example live that way).
func _quoted(path: String, marker: String) -> String:
	for raw: String in FileAccess.get_file_as_string(path).split("\n"):
		if raw.find(marker) == -1:
			continue
		var open := raw.find("`")
		var close := raw.find("`", open + 1)
		if open >= 0 and close > open:
			return raw.substr(open + 1, close - open - 1)
	return ""


## The cell text of one module row: the `Value` label inside the named column box.
func _cell(module_id: StringName, cell_name: String) -> String:
	var row := _row(module_id)
	if row == null:
		return "<no row>"
	var box := row.find_child(cell_name, true, false) as Control
	if box == null:
		return "<no cell>"
	var value := box.get_node_or_null(^"Value") as Label
	return value.text if value != null else "<no value>"


func _row(module_id: StringName) -> Button:
	for child: Node in _module_rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _row_ids() -> Array[StringName]:
	return _panel.call(&"module_row_ids")


func _action(module_id: StringName) -> String:
	return String(_panel.call(&"module_action", module_id))


func _press(module_id: StringName) -> void:
	var row := _row(module_id)
	if row == null:
		print("[r1] press %s: NO ROW" % module_id)
		return
	row.pressed.emit()


func _strip_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for index in _strip.get_child_count():
		var line := _strip.get_child(index) as HBoxContainer
		if line == null or not line.visible:
			continue
		var text := line.get_node_or_null(^"Text") as Label
		lines.append(text.text if text != null else "")
	return lines


func _strip_remove(index: int) -> void:
	var line := _strip.get_child(index) as HBoxContainer
	var button := line.get_node_or_null(^"Remove") as Button
	if button == null or not button.visible:
		print("[r1] strip REMOVE on %s: not reachable" % line.name)
		return
	button.pressed.emit()


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


func _owned(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _credits() -> int:
	return int(_profile.call(&"credits"))


func _step(label: String) -> void:
	var inventory := PackedStringArray()
	for id: StringName in _row_ids():
		if _owned(id) > 0:
			inventory.append("%s:%d" % [id, _owned(id)])
	print("[r1] %s | credits=%d cells=%s inv=[%s]" % [
		label, _credits(), str(_cells()), " ".join(inventory)
	])
	print("[r1]   strip=%s" % str(_strip_lines()))


## ------------------------------------------------------------------ 1. the row table


func _row_table() -> void:
	print("[r1] == 1. the row table against 09 section 3.1 ==")
	var doc := _doc_table()
	var ids: PackedStringArray = doc[&"ids"]
	var rows: Dictionary = doc[&"rows"]
	print("[r1] 09 section 3.1's table rows=%d ids=%s" % [ids.size(), str(ids)])
	var panel_ids := _row_ids()
	print("[r1] pane rows=%d ids=%s" % [panel_ids.size(), str(panel_ids)])
	var mismatches := PackedStringArray()
	for id_text: String in ids:
		var id := StringName(id_text)
		var expected: Dictionary = rows[id_text]
		var catalogue := ModuleData.module(id)
		if panel_ids.find(id) == -1:
			mismatches.append("%s: no row" % id)
			continue
		if int(catalogue[&"cost"]) != int(expected[&"cost"]):
			mismatches.append("%s: cost %d != %d" % [id, catalogue[&"cost"], expected[&"cost"]])
		if int(catalogue[&"draw"]) != int(expected[&"draw"]):
			mismatches.append("%s: draw %d != %d" % [id, catalogue[&"draw"], expected[&"draw"]])
		if int(_cell(id, "Price").replace(" ", "")) != int(expected[&"cost"]):
			mismatches.append("%s: PRICE cell %s" % [id, _cell(id, "Price")])
		if _cell(id, "Effect") != String(expected[&"effect"]):
			mismatches.append("%s: EFFECT cell %s" % [id, _cell(id, "Effect")])
		var meta := "W SLOT · DRAW %d" % int(expected[&"draw"])
		var row := _row(id)
		var meta_label := row.find_child("Meta", true, false) as Label
		if meta_label == null or meta_label.text != meta:
			mismatches.append("%s: meta %s" % [id, str(meta_label)])
	print("[r1] every doc row's cost/draw/effect/meta matches the pane: %s" % str(mismatches.is_empty()))
	if not mismatches.is_empty():
		print("[r1]   mismatches=%s" % str(mismatches))
	## Every other row the pane renders, and the whole weapon-slot set, for the door test.
	var unknown := PackedStringArray()
	for id: StringName in panel_ids:
		if ids.find(String(id)) == -1:
			unknown.append(String(id))
	print("[r1] pane rows outside 09 section 3.1's table=%s" % str(unknown))
	var weapon_ids := PackedStringArray()
	for id: StringName in ModuleData.MODULES:
		if String(ModuleData.slot_of(id)) == "weapons":
			weapon_ids.append(String(id))
	print("[r1] catalogue weapon-slot ids=%d %s" % [weapon_ids.size(), str(weapon_ids)])


## ------------------------------------------- 2. the acquisition door of every W module


func _the_door() -> void:
	print("[r1] == 2. can the player obtain each weapon module? ==")
	for id_text: String in ["w_laser", "w_cannon", "w_rocket", "w_mine", "w_plasma", "w_railgun", "w_mining"]:
		var id := StringName(id_text)
		var row := _row(id)
		var owned := _owned(id)
		var pressable := row != null and not row.disabled
		print("[r1] %s: catalogue slot=%s cost=%d owned=%d row=%s pressable=%s action=%s" % [
			id,
			str(ModuleData.slot_of(id)),
			int(ModuleData.module(id).get(&"cost", -1)),
			owned,
			str(row != null),
			str(pressable),
			_action(id) if row != null else "-",
		])
	print("[r1] the panel's own buy seam for w_mining (no row, so unreachable by a press): %s" % str(
		bool(_panel.call(&"buy_module", &"w_mining"))
	))
	_step("after a direct panel.buy_module(w_mining)")
	## A direct buy through the surface method does put one in the inventory; put it back
	## so the round-trip section starts from the same account the wave's report describes.
	if _owned(&"w_mining") > 0:
		_profile.call(&"take_module", &"w_mining", _owned(&"w_mining"))


## ------------------------------------------------------------------ 3. the round trip


func _round_trip() -> void:
	print("[r1] == 3. buy / install / swap / remove (R1's own sequence) ==")
	_step("start")
	_buy("w_rocket")
	_press(&"w_rocket")
	_step("after BUY + INSTALL w_rocket (first empty W cell)")
	_buy("w_mine")
	_press(&"w_mine")
	_step("after BUY + INSTALL w_mine (grid full)")
	print("[r1] w_cannon action on a full grid, none owned = %s" % _action(&"w_cannon"))
	_buy("w_cannon")
	print("[r1] w_cannon action on a full grid, one owned = %s" % _action(&"w_cannon"))
	_press(&"w_cannon")
	_step("after BUY + SWAP w_cannon into W1")
	_strip_remove(0)
	_step("after strip REMOVE of W1")
	print("[r1] w_mine action with an empty cell and none owned = %s" % _action(&"w_mine"))
	_buy("w_cannon")
	_press(&"w_cannon")
	_step("after BUY + INSTALL w_cannon into W1 (grid full again)")
	print("[r1] w_mine action with a full grid and the module fitted = %s" % _action(&"w_mine"))
	_press(&"w_mine")
	_step("after the row REMOVE of w_mine")
	print("[r1] credits spent so far=%d (1200+2400+1800+1200 = 6600)" % (START_CREDITS - _credits()))


func _buy(module_id: String) -> void:
	var id := StringName(module_id)
	var before := _credits()
	var lines := _log_lines()
	var ok := bool(_panel.call(&"buy_module", id))
	print("[r1] buy_module(%s, %d) = %s | credits %d -> %d | log lines %d -> %d | owned=%d" % [
		id,
		int(ModuleData.module(id).get(&"cost", -1)),
		str(ok),
		before,
		_credits(),
		lines,
		_log_lines(),
		_owned(id),
	])


## ---------------------------------------------------------------------- 4. refusals


func _refusals() -> void:
	print("[r1] == 4. every refusal, with its wording ==")
	## (a) unknown id through the surface (no row exists for one).
	var before_credits := _credits()
	var unknown := bool(_panel.call(&"buy_module", &"w_not_a_module"))
	print("[r1] panel.buy_module(w_not_a_module) = %s | credits %d -> %d | profile failures=%s" % [
		str(unknown), before_credits, _credits(), str(_failed)
	])
	## (b) insufficient credits, from the row's own press.
	_profile.set(&"_credits", 500)
	_panel.call(&"refresh_profile", &"credits")
	_failed.clear()
	print("[r1] w_railgun status/action with 500 CR = %s / %s" % [
		_cell(&"w_railgun", "Status"), _cell(&"w_railgun", "Action")
	])
	print("[r1] press w_railgun (BUY) = %s | footer=%s | credits=%d | railgun=%d | failures=%s" % [
		str(_panel.call(&"buy_module", &"w_railgun")),
		_last_status(),
		_credits(),
		_owned(&"w_railgun"),
		str(_failed),
	])
	## (c) the power overload, on a grid with an empty cell: the pane's wording against
	## 09 section 2's own example.
	_profile.set(&"_credits", 30000)
	_panel.call(&"refresh_profile", &"credits")
	for index in range(_cells().size()):
		if String(_cells()[index]) == "":
			continue
		print("[r1] emptying W%d to build the overload candidate" % (index + 1))
		_panel.call(&"remove_module", index)
	_step("clean grid for the overload")
	_buy("w_plasma")
	_press(&"w_plasma")
	_step("after INSTALL w_plasma into W1")
	_buy("w_plasma")
	_press(&"w_plasma")
	_step("after INSTALL w_plasma into W2")
	_buy("w_plasma")
	_press(&"w_plasma")
	print("[r1] overload refusal=%s danger=%s" % [_last_status(), str(_last_danger())])
	_step("after the refused third plasma (W3 empty, nothing auto-removed)")
	var doc_overload := _quoted(DOC_09, "PWR — OVER BY")
	print("[r1] 09 section 2's own example=%s ; the pane's format applied to it=%s ; equal=%s" % [
		doc_overload,
		_panel.REFUSAL_OVERLOAD % [13, 11, 2],
		str((_panel.REFUSAL_OVERLOAD % [13, 11, 2]) == doc_overload),
	])
	## (d) the full-cells refusal, from the surface call the row's own ACTION never makes.
	_buy("w_mine")
	print("[r1] w_mine action on a full grid with one owned = %s" % _action(&"w_mine"))
	print("[r1] panel.install_module(w_mine) with no empty cell = %s | footer=%s | danger=%s" % [
		str(_panel.call(&"install_module", &"w_mine")), _last_status(), str(_last_danger())
	])
	_step("after the full-cells refusal")
	print("[r1] STATION_HUB 5.1's own line=%s ; equal=%s" % [
		_quoted(DOC_HUB, "W SLOTS FULL"),
		str(_last_status() == _quoted(DOC_HUB, "W SLOTS FULL")),
	])
	## (e) the third wording: a fit that arrives holding a module but missing its mandatory
	## set. Written through the profile's public API, not by the pane.
	var partial: Dictionary = {&"weapons": [String(&"w_laser")]}
	_profile.call(&"set_fit", VANGUARD, partial)
	var legal := FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))
	print("[r1] an externally written partial fit: legal=%s missing=%s power=%s" % [
		str(legal[&"legal"]), str(legal[&"missing"]), str(legal[&"power"])
	])
	print("[r1] w_railgun can still be bought; press INSTALL on that fit = %s | footer=%s" % [
		str(_panel.call(&"install_module", &"w_railgun")), _last_status()
	])
	print("[r1] (and the pane cannot repair it: every install is refused while the fit holds a module)")
	## Put a legal standard fit back for the sections below.
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	_panel.call(&"refresh_profile", &"fits")


## -------------------------------------------------------------- 5. the mandatory set


func _mandatory_set() -> void:
	print("[r1] == 5. the mandatory engine / reactor set ==")
	var rows := _row_ids()
	var engine_rows := PackedStringArray()
	for id: StringName in rows:
		if String(ModuleData.slot_of(id)) != "weapons":
			engine_rows.append(String(id))
	print("[r1] rows whose slot is not weapons=%s" % str(engine_rows))
	_status.clear()
	print("[r1] install_module(e_std) = %s | footer emitted=%s | engines=%s" % [
		str(_panel.call(&"install_module", &"e_std")),
		str(_status.size() > 0),
		str(_profile.call(&"fit_for", VANGUARD)[&"engines"]),
	])
	print("[r1] swap_module(p_std, 0) = %s | power=%s" % [
		str(_panel.call(&"swap_module", &"p_std", 0)),
		str(_profile.call(&"fit_for", VANGUARD)[&"power"]),
	])
	print("[r1] remove_module over every cell = %s" % str(
		[_panel.call(&"remove_module", 0), _panel.call(&"remove_module", 1), _panel.call(&"remove_module", 2)]
	))
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var legal := FitData.fit_legal(VANGUARD, fit)
	print("[r1] after the whole probe: engines=%s power=%s weapons=%s missing=%s duplicates=%s overflow=%s legal=%s" % [
		str(fit[&"engines"]), str(fit[&"power"]), str(fit[WEAPON_SLOT]),
		str(legal[&"missing"]), str(legal[&"duplicates"]), str(legal[&"overflow"]), str(legal[&"legal"]),
	])


## ------------------------------------------------ 6. the strip across other hulls


func _strip_across_hulls() -> void:
	print("[r1] == 6. the strip across hulls ==")
	var most := 0
	for hull: StringName in FitData.HULLS:
		most = maxi(most, FitData.slot_capacity(hull, WEAPON_SLOT))
	print("[r1] widest W grid of the nine player hulls=%d ; strip lines built=%d" % [
		most, _strip.get_child_count()
	])
	var shown := 0
	for index in _strip.get_child_count():
		if (_strip.get_child(index) as Control).visible:
			shown += 1
	print("[r1] Vanguard visible lines=%d %s" % [shown, str(_strip_lines())])
	_profile.call(&"buy_ship", LANCER, int(_profile.call(&"credits")))
	_profile.call(&"set_active_ship", LANCER)
	_panel.call(&"refresh_profile", &"ships")
	var shown_lancer := 0
	for index in _strip.get_child_count():
		if (_strip.get_child(index) as Control).visible:
			shown_lancer += 1
	print("[r1] Lancer visible lines=%d fit=%s" % [
		shown_lancer, str(_profile.call(&"fit_for", LANCER))
	])
	var empty_line := _strip.get_child(1) as HBoxContainer
	var remove := empty_line.get_node_or_null(^"Remove") as Button
	print("[r1] an empty line's REMOVE: visible=%s disabled=%s" % [
		str(remove.visible), str(remove.disabled)
	])
	_profile.call(&"set_active_ship", VANGUARD)
	_panel.call(&"refresh_profile", &"ships")


## ------------------------------------------------- 7. 17 section 5's transaction law


func _transaction_law() -> void:
	print("[r1] == 7. 17 section 5 (one log line per buy, none on a refusal) ==")
	_profile.set(&"_credits", 10000)
	_panel.call(&"refresh_profile", &"credits")
	var lines := _log_lines()
	_signals.clear()
	_panel.call(&"buy_module", &"w_cannon")
	print("[r1] a paid buy: log %d -> %d ; signals=%s ; credits=%d ; owned=%d" % [
		lines, _log_lines(), str(_signals), _credits(), _owned(&"w_cannon")
	])
	lines = _log_lines()
	_signals.clear()
	_profile.set(&"_credits", 10)
	_panel.call(&"refresh_profile", &"credits")
	_panel.call(&"buy_module", &"w_railgun")
	print("[r1] a refused buy: log %d -> %d ; signals=%s ; credits=%d ; owned=%d" % [
		lines, _log_lines(), str(_signals), _credits(), _owned(&"w_railgun")
	])
