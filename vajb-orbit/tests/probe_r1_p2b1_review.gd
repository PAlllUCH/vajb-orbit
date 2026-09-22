extends Node
## P2-B1 R1 review probe (written by R1 for this review pass, independent of W2's
## `probe_p2b1_panel_fit.gd`). It mounts the shipped OUTFITTING pane behind the shell's own
## wiring and re-measures the wave's claims from outside the wave:
##
##   A. the row table against 09 section 3.1 parsed out of the document (id, draw, cost,
##      effect prose, `W SLOT · DRAW n` meta, PRICE cell);
##   B. the acquisition door: which catalogue weapon ids the surface can actually sell;
##   C. the STATUS / ACTION state machine of STATION_HUB section 5.1;
##   D. the buy -> install -> swap -> remove round trip, cell by cell;
##   E. every refusal, with its exact wording (09 section 2's and STATION_HUB 5.1's own
##      lines parsed out of the documents), the danger flag and what was written;
##   F. the mandatory engine / reactor set;
##   G. 17 section 5's transaction law (one log line per buy, none on a refusal);
##   H. the fitted strip across hulls;
##   I. the shell's own refusal copy for a module id (`station.gd:_refusal_text`).
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn
##
## The pane reads `/root/PlayerProfile`, so the probe borrows the shipped autoload exactly
## as W2's probe does: `save_path` is repointed at a scratch file before the first
## mutation, every field the pane can write is snapshotted and handed back, the store is
## flushed while the scratch path is still in place, and the scratch file is removed.

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const PanelScript := preload("res://ui/station/outfitting_panel.gd")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_review.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_review.log"
const DOC_09 := "res://../docs/gameplay/09_ship_slots_modules.md"
const DOC_HUB := "res://../docs/design/STATION_HUB.md"

const VANGUARD: StringName = &"ship_vanguard"
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const START_CREDITS := 20000
## 09 section 3.1's table plus 09 section 4 item 7's mining laser: every weapon module 09 ships.
const WEAPON_IDS: Array[StringName] = [
	&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_railgun", &"w_mining",
]

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
var _watchdog := 0


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1] FAILED: the PlayerProfile autoload is the pane's store")
		get_tree().quit()
		return
	_borrow()
	_seed()
	_mount()
	_section_a_row_table()
	_section_b_door()
	_section_c_state_machine()
	_section_d_round_trip()
	_section_e_refusals()
	_section_f_mandatory()
	_section_g_transaction_law()
	_section_h_strip()
	_section_i_shell_copy()
	_restore()
	print("[r1] == done ==")
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
	## The shell's own wiring (`ui/screens/station.gd`): every panel is told about every
	## key, and a panel never refreshes itself.
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


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Every loop in this probe is bounded: a stale cell, a refused write or a signal that
## never arrives must not wedge the run.
func _tick(limit: int) -> void:
	_watchdog += 1
	if _watchdog > limit:
		print("[r1] WATCHDOG: loop cap %d hit" % limit)


## ------------------------------------------------- 09 section 3.1, out of the document


## Every row of 09 section 3.1's WEAPONS table, parsed here by R1 rather than read from
## W2's suite: id, draw, cost (the document's thousands space removed) and effect prose.
func _doc_table() -> Dictionary:
	var ids := PackedStringArray()
	var rows: Dictionary = {}
	var inside := false
	for raw: String in FileAccess.get_file_as_string(DOC_09).split("\n"):
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
		if id_text.is_empty() or id_text == "Module" or id_text.replace("-", "").is_empty():
			continue
		ids.append(id_text)
		rows[id_text] = {
			&"draw": int(String(cells[2]).strip_edges()),
			&"cost": int(String(cells[6]).strip_edges().replace(" ", "").replace("\u00a0", "")),
			&"effect": String(cells[5]).strip_edges(),
		}
	return {&"ids": ids, &"rows": rows}


## The first backticked string on the first line carrying `marker` (09 section 2's own
## overload example and STATION_HUB 5.1's own full-cells line live that way).
func _quoted(path: String, marker: String) -> String:
	for raw: String in FileAccess.get_file_as_string(path).split("\n"):
		if raw.find(marker) == -1:
			continue
		var open := raw.find("`")
		var close := raw.find("`", open + 1)
		if open >= 0 and close > open:
			return raw.substr(open + 1, close - open - 1)
	return ""


## --------------------------------------------------------------- pane read-backs


func _row(module_id: StringName) -> Button:
	for child: Node in _module_rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _row_ids() -> Array[StringName]:
	return _panel.call(&"module_row_ids")


func _cell(module_id: StringName, cell_name: String) -> String:
	var row := _row(module_id)
	if row == null:
		return "<no row>"
	var box := row.find_child(cell_name, true, false) as Control
	if box == null:
		return "<no cell>"
	var value := box.get_node_or_null(^"Value") as Label
	return value.text if value != null else "<no value>"


func _title(module_id: StringName) -> String:
	var row := _row(module_id)
	if row == null:
		return "<no row>"
	var label := row.find_child("Title", true, false) as Label
	return label.text if label != null else "<no title>"


func _meta(module_id: StringName) -> String:
	var row := _row(module_id)
	if row == null:
		return "<no row>"
	var label := row.find_child("Meta", true, false) as Label
	return label.text if label != null else "<no meta>"


func _press(module_id: StringName) -> void:
	var row := _row(module_id)
	if row == null:
		print("[r1]   press %s: NO ROW (the surface has no door for it)" % module_id)
		return
	row.pressed.emit()


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


func _strip_remove(index: int) -> void:
	var line := _strip.get_child(index) as HBoxContainer
	if line == null:
		print("[r1]   strip line %d: absent" % index)
		return
	var button := line.get_node_or_null(^"Remove") as Button
	if button == null or not button.visible or button.disabled:
		print("[r1]   strip REMOVE on %s: not reachable" % line.name)
		return
	button.pressed.emit()


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


func _owned(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _credits() -> int:
	return int(_profile.call(&"credits"))


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


func _last_log_line() -> String:
	var last := "<none>"
	var file := FileAccess.open(LOG_SCRATCH, FileAccess.READ)
	if file == null:
		return last
	for line: String in file.get_as_text().split("\n"):
		if not line.strip_edges().is_empty():
			last = line.strip_edges()
	file.close()
	return last


func _inventory() -> String:
	var parts := PackedStringArray()
	for id: StringName in WEAPON_IDS:
		if _owned(id) > 0:
			parts.append("%s:%d" % [id, _owned(id)])
	return "[" + " ".join(parts) + "]"


func _step(label: String) -> void:
	print("[r1]   %s | credits=%d cells=%s inv=%s" % [
		label, _credits(), str(_cells()), _inventory()
	])
	print("[r1]     strip=%s" % str(_strip_lines()))


func _buy(module_id: StringName) -> bool:
	var before := _credits()
	var lines := _log_lines()
	var ok := bool(_panel.call(&"buy_module", module_id))
	print("[r1]   buy_module(%s, %d) = %s | credits %d -> %d | log %d -> %d | owned=%d" % [
		module_id,
		int(ModuleData.module(module_id).get(&"cost", -1)),
		str(ok),
		before,
		_credits(),
		lines,
		_log_lines(),
		_owned(module_id),
	])
	return ok


## Empty every filled W cell of the Vanguard, one write per cell, bounded.
func _empty_grid() -> void:
	for attempt in 6:
		_tick(24)
		var cells := _cells()
		var target := -1
		for index in cells.size():
			if StringName(cells[index]) != &"":
				target = index
				break
		if target < 0:
			return
		_panel.call(&"remove_module", target)


## ------------------------------------------------------- A. the row table


func _section_a_row_table() -> void:
	print("[r1] == A. the MODULES row table against 09 section 3.1 ==")
	var doc := _doc_table()
	var doc_ids: PackedStringArray = doc[&"ids"]
	var doc_rows: Dictionary = doc[&"rows"]
	print("[r1] 09 section 3.1 table rows=%d ids=%s" % [doc_ids.size(), str(doc_ids)])
	var pane_ids := _row_ids()
	print("[r1] pane rows=%d ids=%s" % [pane_ids.size(), str(pane_ids)])
	var bad := PackedStringArray()
	for id_text: String in doc_ids:
		var id := StringName(id_text)
		var expected: Dictionary = doc_rows[id_text]
		var catalogue := ModuleData.module(id)
		if pane_ids.find(id) == -1:
			bad.append("%s: no pane row" % id)
			continue
		if int(catalogue.get(&"cost", -1)) != int(expected[&"cost"]):
			bad.append("%s catalogue cost %d != doc %d" % [id, int(catalogue.get(&"cost", -1)), int(expected[&"cost"])])
		if int(catalogue.get(&"draw", -1)) != int(expected[&"draw"]):
			bad.append("%s catalogue draw %d != doc %d" % [id, int(catalogue.get(&"draw", -1)), int(expected[&"draw"])])
		if _cell(id, "Price").replace(" ", "") != str(expected[&"cost"]):
			bad.append("%s PRICE cell '%s' != %d" % [id, _cell(id, "Price"), int(expected[&"cost"])])
		if _cell(id, "Effect") != String(expected[&"effect"]):
			bad.append("%s EFFECT cell '%s'" % [id, _cell(id, "Effect")])
		if _meta(id) != "W SLOT · DRAW %d" % int(expected[&"draw"]):
			bad.append("%s meta '%s'" % [id, _meta(id)])
	print("[r1] per-row check (cost, draw, PRICE, EFFECT, meta): %s" % ("ALL MATCH" if bad.is_empty() else str(bad)))
	for id_text: String in doc_ids:
		var id := StringName(id_text)
		print("[r1]   %s | doc draw=%d cost=%d | catalogue draw=%d cost=%d | name='%s' | meta='%s' | price='%s' | status='%s' | action='%s' | effect='%s'" % [
			id,
			int(doc_rows[id_text][&"draw"]), int(doc_rows[id_text][&"cost"]),
			int(ModuleData.module(id).get(&"draw", -1)), int(ModuleData.module(id).get(&"cost", -1)),
			_title(id), _meta(id), _cell(id, "Price"),
			_cell(id, "Status"), _cell(id, "Action"), _cell(id, "Effect"),
		])
	var extra := PackedStringArray()
	for id: StringName in pane_ids:
		if doc_ids.find(String(id)) == -1:
			extra.append(String(id))
	print("[r1] pane rows outside 09 section 3.1's table=%s" % str(extra))
	var header := _panel.get_node("%ModulesHeader") as HBoxContainer
	var heads := PackedStringArray()
	for child: Node in header.get_children():
		var label := child.find_child("Caption", true, false) as Label
		heads.append(label.text if label != null else (child as Control).name)
	print("[r1] MODULES header cells=%s" % str(heads))
	var captions := PackedStringArray()
	for index in _panel.get_child_count():
		var label := _panel.get_child(index) as Label
		if label != null:
			captions.append(label.text)
	print("[r1] pane-level labels=%s" % str(captions))


## -------------------------------------------- B. the door for every weapon module


func _section_b_door() -> void:
	print("[r1] == B. can the surface sell each weapon module 09 ships? ==")
	var weapon_ids := PackedStringArray()
	for id: StringName in ModuleData.MODULES:
		if ModuleData.slot_of(id) == WEAPON_SLOT:
			weapon_ids.append(String(id))
	print("[r1] catalogue weapon-slot ids=%d %s" % [weapon_ids.size(), str(weapon_ids)])
	var no_row := PackedStringArray()
	for id: StringName in WEAPON_IDS:
		var row := _row(id)
		var pressable := row != null and not row.disabled
		if not pressable:
			no_row.append(String(id))
		print("[r1]   %s: catalogue cost=%d draw=%d | row=%s pressable=%s | status='%s' action='%s'" % [
			id,
			int(ModuleData.module(id).get(&"cost", -1)),
			int(ModuleData.module(id).get(&"draw", -1)),
			str(row != null),
			str(pressable),
			_cell(id, "Status"),
			_action(id),
		])
	print("[r1] weapon ids with no pressable row: %s" % str(no_row))
	if not no_row.is_empty():
		_signals.clear()
		var before := _log_lines()
		var closed := StringName(no_row[0])
		var ok := bool(_panel.call(&"buy_module", closed))
		print("[r1] the closed door's own seam: panel.buy_module(%s) = %s | log %d -> %d | signals=%s | owned=%d" % [
			closed, str(ok), before, _log_lines(), str(_signals), _owned(closed)
		])
		_profile.call(&"take_module", closed, _owned(closed))


## ------------------------------------------------------ C. the state machine


func _section_c_state_machine() -> void:
	print("[r1] == C. the STATUS / ACTION state machine of STATION_HUB 5.1 ==")
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", START_CREDITS)
	_panel.call(&"refresh_profile", &"fits")
	print("[r1] C0 fresh account, nothing owned, empty cells exist")
	for id: StringName in WEAPON_IDS:
		if _row(id) == null:
			continue
		print("[r1]   %s: status='%s' action='%s'" % [id, _cell(id, "Status"), _cell(id, "Action")])
	print("[r1] C1 the standard fit's laser is fitted on W1")
	print("[r1]   w_laser: status='%s' action='%s'" % [_cell(&"w_laser", "Status"), _cell(&"w_laser", "Action")])
	_buy(&"w_cannon")
	print("[r1] C2 after a buy, none fitted, an empty cell exists")
	print("[r1]   w_cannon: status='%s' action='%s'" % [_cell(&"w_cannon", "Status"), _cell(&"w_cannon", "Action")])
	_buy(&"w_cannon")
	print("[r1] C3 two owned (OWNED x n), an empty cell exists")
	print("[r1]   w_cannon: status='%s' action='%s'" % [_cell(&"w_cannon", "Status"), _cell(&"w_cannon", "Action")])
	_press(&"w_cannon")
	_step("C4 after INSTALL (a second cannon on W2)")
	print("[r1]   w_cannon: status='%s' action='%s'" % [_cell(&"w_cannon", "Status"), _cell(&"w_cannon", "Action")])
	_buy(&"w_rocket")
	_press(&"w_rocket")
	print("[r1] C5 every W cell full, credits=%d" % _credits())
	print("[r1]   w_railgun: status='%s' action='%s'" % [_cell(&"w_railgun", "Status"), _cell(&"w_railgun", "Action")])
	print("[r1]   w_cannon (fitted, full grid): status='%s' action='%s'" % [_cell(&"w_cannon", "Status"), _cell(&"w_cannon", "Action")])
	_buy(&"w_railgun")
	print("[r1] C6 full grid, railgun owned, not fitted")
	print("[r1]   w_railgun: status='%s' action='%s'" % [_cell(&"w_railgun", "Status"), _cell(&"w_railgun", "Action")])
	print("[r1] C7 unaffordable, nothing owned -> LOCKED")
	_profile.set(&"_credits", 10)
	_panel.call(&"refresh_profile", &"credits")
	print("[r1]   w_plasma: status='%s' action='%s' price='%s'" % [
		_cell(&"w_plasma", "Status"), _cell(&"w_plasma", "Action"), _cell(&"w_plasma", "Price")
	])
	print("[r1] C8 grid full, module fitted -> REMOVE")
	print("[r1]   w_rocket: status='%s' action='%s'" % [_cell(&"w_rocket", "Status"), _cell(&"w_rocket", "Action")])
	print("[r1] C9 an empty cell exists and the module is fitted (09 section 4 item 4 lets a weapon repeat)")
	_panel.call(&"remove_module", 0)
	print("[r1]   w_rocket: status='%s' action='%s'" % [_cell(&"w_rocket", "Status"), _cell(&"w_rocket", "Action")])


## ------------------------------------------------------------- D. the round trip


func _section_d_round_trip() -> void:
	print("[r1] == D. buy / install / swap / remove, cell by cell ==")
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", START_CREDITS)
	_panel.call(&"refresh_profile", &"fits")
	_step("D0 start (standard fit: W1 w_laser)")
	_buy(&"w_cannon")
	_press(&"w_cannon")
	_step("D1 after BUY + INSTALL w_cannon (first empty W cell = W2)")
	_buy(&"w_mine")
	_press(&"w_mine")
	_step("D2 after BUY + INSTALL w_mine (first empty = W3, grid now full)")
	print("[r1]   w_cannon action with a full grid and one owned=%s (the pin's SWAP)" % _action(&"w_cannon"))
	_buy(&"w_rocket")
	print("[r1]   w_rocket action with a full grid and one owned=%s" % _action(&"w_rocket"))
	_press(&"w_rocket")
	_step("D3 after BUY + SWAP w_rocket into W1 (the displaced module must come back)")
	_strip_remove(0)
	_step("D4 after the strip's REMOVE on W1")
	_strip_remove(1)
	_step("D5 after the strip's REMOVE on W2")
	print("[r1]   credits spent=%d" % (START_CREDITS - _credits()))
	print("[r1]   w_laser back in the inventory=%d" % _owned(&"w_laser"))
	print("[r1]   the mandatory set after the round trip: engines=%s power=%s" % [
		str(_profile.call(&"fit_for", VANGUARD)[&"engines"]), str(_profile.call(&"fit_for", VANGUARD)[&"power"])
	])
	print("[r1]   fit_legal after the round trip=%s" % str(FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"legal"]))


## ---------------------------------------------------------------- E. refusals


func _section_e_refusals() -> void:
	print("[r1] == E. every refusal, with its exact wording ==")
	_profile.set(&"_credits", START_CREDITS)
	_panel.call(&"refresh_profile", &"credits")
	print("[r1] E1 unknown id through the surface's own entry point")
	var before := _credits()
	var lines := _log_lines()
	_failed.clear()
	print("[r1]   panel.buy_module(w_not_a_module) = %s | credits %d -> %d | log %d -> %d | purchase_failed=%s" % [
		str(_panel.call(&"buy_module", &"w_not_a_module")), before, _credits(), lines, _log_lines(), str(_failed)
	])
	print("[r1] E2 insufficient credits, from the row's own press")
	_profile.set(&"_credits", 500)
	_panel.call(&"refresh_profile", &"credits")
	_failed.clear()
	_press(&"w_railgun")
	print("[r1]   pressed w_railgun with 500 CR: status='%s' danger=%s purchase_failed=%s credits=%d owned=%d" % [
		_last_status(), str(_last_danger()), str(_failed), _credits(), _owned(&"w_railgun")
	])
	print("[r1]   the row's own status/action: '%s' / '%s'" % [_cell(&"w_railgun", "Status"), _cell(&"w_railgun", "Action")])
	print("[r1] E3 the power overload, through the pane's own install path")
	_profile.set(&"_credits", 40000)
	_panel.call(&"refresh_profile", &"credits")
	_empty_grid()
	_step("E3a grid emptied")
	_buy(&"w_plasma")
	_press(&"w_plasma")
	_step("E3b after INSTALL w_plasma into W1")
	_buy(&"w_plasma")
	_press(&"w_plasma")
	_step("E3c after INSTALL w_plasma into W2")
	print("[r1]   the live fit's power arithmetic=%s" % str(
		FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"power"]
	))
	_buy(&"w_plasma")
	print("[r1]   w_plasma action with an empty W3 and one owned=%s" % _action(&"w_plasma"))
	_failed.clear()
	var overload_ok := bool(_panel.call(&"install_module", &"w_plasma"))
	print("[r1]   install_module(w_plasma) = %s | footer='%s' danger=%s purchase_failed=%s" % [
		str(overload_ok), _last_status(), str(_last_danger()), str(_failed)
	])
	var cells_before := str(_cells())
	var owned_before := _owned(&"w_plasma")
	var credits_before := _credits()
	print("[r1]   09 section 2's own example=%s" % _quoted(DOC_09, "PWR — OVER BY"))
	print("[r1]   the pane's own format applied to it='%s' equal=%s" % [
		PanelScript.REFUSAL_OVERLOAD % [13, 11, 2],
		str((PanelScript.REFUSAL_OVERLOAD % [13, 11, 2]) == _quoted(DOC_09, "PWR — OVER BY")),
	])
	_step("E3d after the refused overload (nothing auto-removes)")
	print("[r1]   cells unchanged=%s | module still owned=%s | credits unchanged=%s" % [
		str(str(_cells()) == cells_before), str(_owned(&"w_plasma") == owned_before),
		str(_credits() == credits_before)
	])
	print("[r1] E4 the full-cells refusal (STATION_HUB 5.1's own line)")
	_buy(&"w_mine")
	print("[r1]   w_mine action on the full grid with one owned=%s" % _action(&"w_mine"))
	_failed.clear()
	var full_ok := bool(_panel.call(&"install_module", &"w_mine"))
	print("[r1]   install_module(w_mine) = %s | footer='%s' danger=%s" % [
		str(full_ok), _last_status(), str(_last_danger())
	])
	print("[r1]   STATION_HUB 5.1's own line=%s equal=%s" % [
		_quoted(DOC_HUB, "W SLOTS FULL"), str(_last_status() == _quoted(DOC_HUB, "W SLOTS FULL"))
	])
	print("[r1] E5 a fit that arrives already illegal (written through the profile's API)")
	_profile.call(&"set_fit", VANGUARD, {&"weapons": ["w_laser"]})
	_panel.call(&"refresh_profile", &"fits")
	var partial := FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))
	print("[r1]   stored fit legal=%s missing=%s overflow=%s power=%s" % [
		str(partial[&"legal"]), str(partial[&"missing"]), str(partial[&"overflow"]), str(partial[&"power"])
	])
	_buy(&"w_railgun")
	print("[r1]   w_railgun action=%s" % _action(&"w_railgun"))
	if _action(&"w_railgun") == &"INSTALL":
		_press(&"w_railgun")
	print("[r1]   install into that fit: footer='%s' danger=%s" % [_last_status(), str(_last_danger())])
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	_panel.call(&"refresh_profile", &"fits")


## -------------------------------------------------------- F. the mandatory set


func _section_f_mandatory() -> void:
	print("[r1] == F. the mandatory engine / reactor set ==")
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	_panel.call(&"refresh_profile", &"fits")
	var rows := _row_ids()
	var non_weapon := PackedStringArray()
	for id: StringName in rows:
		if ModuleData.slot_of(id) != WEAPON_SLOT:
			non_weapon.append(String(id))
	print("[r1] rows whose slot is not weapons=%s" % str(non_weapon))
	var engine_ids := PackedStringArray()
	var power_ids := PackedStringArray()
	for id: StringName in ModuleData.MODULES:
		var slot := ModuleData.slot_of(id)
		if slot == &"engines" or slot == &"engine":
			engine_ids.append(String(id))
		if slot == &"power":
			power_ids.append(String(id))
	print("[r1] catalogue engine ids=%s power ids=%s" % [str(engine_ids), str(power_ids)])
	var fit_before := str(_profile.call(&"fit_for", VANGUARD))
	_status.clear()
	print("[r1] install_module(e_std)=%s install_module(p_mk2)=%s swap_module(p_std,0)=%s swap_module(e_ion,0)=%s remove_module(0)=%s" % [
		str(_panel.call(&"install_module", &"e_std")),
		str(_panel.call(&"install_module", &"p_mk2")),
		str(_panel.call(&"swap_module", &"p_std", 0)),
		str(_panel.call(&"swap_module", &"e_ion", 0)),
		str(_panel.call(&"remove_module", 0)),
	])
	print("[r1] footer lines emitted by those calls=%s" % str(_status))
	print("[r1] fit unchanged=%s" % str(str(_profile.call(&"fit_for", VANGUARD)) == fit_before))
	print("[r1]   fit=%s" % str(_profile.call(&"fit_for", VANGUARD)))
	var strip_texts := _strip_lines()
	var strip_ok := true
	for text: String in strip_texts:
		if text.to_lower().find("engine") != -1 or text.to_lower().find("reactor") != -1:
			strip_ok = false
	print("[r1] strip lines are W cells only=%s strip=%s" % [str(strip_ok), str(strip_texts)])
	print("[r1] the mandatory set after the whole probe: engines=%s power=%s missing=%s overflow=%s" % [
		str(_profile.call(&"fit_for", VANGUARD)[&"engines"]),
		str(_profile.call(&"fit_for", VANGUARD)[&"power"]),
		str(FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"missing"]),
		str(FitData.fit_legal(VANGUARD, _profile.call(&"fit_for", VANGUARD))[&"overflow"]),
	])


## -------------------------------------------- G. 17 section 5's transaction law


func _section_g_transaction_law() -> void:
	print("[r1] == G. 17 section 5 (one log line per buy, none on a refusal) ==")
	_profile.set(&"_credits", 10000)
	_panel.call(&"refresh_profile", &"credits")
	var lines := _log_lines()
	_signals.clear()
	var ok := _buy(&"w_railgun")
	print("[r1]   paid buy: ok=%s log %d -> %d signals=%s" % [str(ok), lines, _log_lines(), str(_signals)])
	print("[r1]   the log line's own fields: %s" % _last_log_line())
	lines = _log_lines()
	_signals.clear()
	_profile.set(&"_credits", 10)
	_panel.call(&"refresh_profile", &"credits")
	var refused := _buy(&"w_railgun")
	print("[r1]   refused buy: ok=%s log %d -> %d signals=%s credits=%d" % [
		str(refused), lines, _log_lines(), str(_signals), _credits()
	])
	print("[r1]   a zero-cost buy (the seam trusts the caller's price):")
	_profile.set(&"_credits", 10)
	var zero_lines := _log_lines()
	_signals.clear()
	var zero := bool(_profile.call(&"buy_module", &"w_mine", 0))
	print("[r1]   buy_module(w_mine, 0) = %s | credits=%d | log %d -> %d | signals=%s | owned=%d" % [
		str(zero), _credits(), zero_lines, _log_lines(), str(_signals), _owned(&"w_mine")
	])
	_profile.call(&"take_module", &"w_mine", _owned(&"w_mine"))


## ------------------------------------------------------------- H. the strip


func _section_h_strip() -> void:
	print("[r1] == H. the fitted strip across hulls ==")
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	_profile.set(&"_active_ship", VANGUARD)
	_panel.call(&"refresh_profile", &"ships")
	var most := 0
	for hull: StringName in FitData.HULLS:
		most = maxi(most, FitData.slot_capacity(hull, WEAPON_SLOT))
	print("[r1] widest W grid of the nine player hulls=%d ; strip lines built=%d" % [
		most, _strip.get_child_count()
	])
	var visible := 0
	for index in _strip.get_child_count():
		if (_strip.get_child(index) as Control).visible:
			visible += 1
	print("[r1] Vanguard W cells=%d visible lines=%d %s" % [
		FitData.slot_capacity(VANGUARD, WEAPON_SLOT), visible, str(_strip_lines())
	])
	var line := _strip.get_child(1) as HBoxContainer
	var remove := line.get_node_or_null(^"Remove") as Button
	print("[r1] an EMPTY line's REMOVE: visible=%s disabled=%s" % [str(remove.visible), str(remove.disabled)])
	var line0 := _strip.get_child(0) as HBoxContainer
	var remove0 := line0.get_node_or_null(^"Remove") as Button
	print("[r1] a FITTED line's REMOVE: visible=%s disabled=%s" % [str(remove0.visible), str(remove0.disabled)])
	_profile.set(&"_credits", 60000)
	_profile.call(&"buy_ship", DESTROYER, 1000)
	_profile.call(&"set_active_ship", DESTROYER)
	_panel.call(&"refresh_profile", &"ships")
	var shown := 0
	for index in _strip.get_child_count():
		if (_strip.get_child(index) as Control).visible:
			shown += 1
	print("[r1] destroyer: W cells=%d visible lines=%d %s" % [
		FitData.slot_capacity(DESTROYER, WEAPON_SLOT), shown, str(_strip_lines())
	])
	print("[r1] destroyer fit=%s" % str(_profile.call(&"fit_for", DESTROYER)))
	_profile.call(&"set_active_ship", VANGUARD)
	_panel.call(&"refresh_profile", &"ships")


## ------------------------------------------- I. the shell's copy for a module id


func _section_i_shell_copy() -> void:
	print("[r1] == I. the shell's own refusal copy for a module id (station.gd) ==")
	var shell: Node = StationScript.new()
	print("[r1] station.gd _entry_cost(w_railgun)=%d (a module is not an ammo pack, a ship or an upgrade)" % int(
		shell.call(&"_entry_cost", &"w_railgun")
	))
	print("[r1] station.gd _refusal_text(insufficient_credits, w_railgun)='%s'" % String(
		shell.call(&"_refusal_text", &"insufficient_credits", &"w_railgun")
	))
	print("[r1] station.gd _refusal_text(insufficient_credits, laser)='%s' (the ammo pack, for contrast)" % String(
		shell.call(&"_refusal_text", &"insufficient_credits", &"laser")
	))
	shell.free()
