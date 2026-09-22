extends Node
## R1 evidence probe (P2-B proper review, part 2 of 2): the shipped station screen measured
## in memory with the shipped scenes and theme - the rail swap and the retirement's reach, the
## SLOT LAYOUT grid against the shipyard's own recipe, the power meter against
## `ShipFit.fit_legal`, the pane's pinned wordings, the per-cell install driven through a row's
## own `pressed`, the mandatory-cell refusal with its exact wording, the shipyard's hover line,
## and LAUNCH's two service rows including the full-tank refusal.
##
## The shipped `PlayerProfile` autoload is borrowed with `save_path` repointed at a scratch file
## and every written field handed back at the end (W2/W3's own hygiene, L17), so the owner's
## `user://profile.cfg` is never written. The economy log is not redirected (this probe calls no
## transaction that logs on the borrowed account).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600
## Signal: the [R1-PANES] lines; the last line is [R1-PANES] done.
##
## Self-bound: `FRAME_CAP` frames and a hard `LOOP_CAP` on every iteration (L82).

const PanelScene := preload("res://ui/station/fitting_panel.tscn")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const PanelScript := preload("res://ui/station/fitting_panel.gd")
const FitData := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const RepairsService := preload("res://game/repairs.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://probe_r1_fit_panes.cfg"
const FRAME_CAP := 600
const LOOP_CAP := 128
const FILE_CAP := 4000

## 08 section 3.2's matrices this probe measures: the Vanguard (`.WW.`, `HSCB`, `HWU.`, `.EP.`,
## 11 cells, 5 gaps) and the Lancer/`ship_fighter` (8 cells).
const HULL: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
const WEAPONS: StringName = &"weapons"
const ENGINES: StringName = &"engines"
const POWER: StringName = &"power"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const PLASMA: StringName = &"w_plasma"
const ION: StringName = &"e_ion"

## STATION_HUB section 5.3 / CONTRACTS section 13's pinned wordings, transcribed here from the
## pin (not read off the pane) so a drift in either direction shows up.
const PINNED: Dictionary = {
	"ACTION_FIT": "FIT",
	"ACTION_SWAP": "SWAP",
	"ACTION_SELECT": "SELECT A CELL",
	"METER_IDLE": "PWR %d / %d",
	"METER_CANDIDATE": "PWR %d / %d · CANDIDATE %d / %d",
	"METER_OVER": " — OVER BY %d",
	"REFUSAL_OVERLOAD": "%d / %d PWR — OVER BY %d",
	"REFUSAL_MANDATORY": "MANDATORY CELL — SWAP ONLY, NEVER EMPTY",
	"REFUSAL_FIT_ILLEGAL": "REFUSED · FIT ILLEGAL",
	"EMPTY_ROW": "NO MODULES OWNED · BUY THEM IN OUTFITTING",
	"SELECTION_FORMAT": "%s%d · %s · OWNED ×%d",
	"CELL_EMPTY": "EMPTY",
	"META_FORMAT": "SLOT %s · DRAW %d",
	"OWNED_FORMAT": "OWNED ×%d",
	"HARDPOINT_CAPTION": "SLOT LAYOUT · %d CELLS · %d ENGINES",
	"ACTIVE_HULL": "ACTIVE HULL %s",
	"OWNED_CAPTION": "OWNED MODULES",
}

## The retired surface's tokens. A live reference in any project script or scene is a finding;
## the pin and this probe are not under `res://`, so a hit is the tree's own.
const RETIRED_TOKENS: Array[String] = [
	"has_upgrade", "installed_upgrades", "install_upgrade",
	"Catalog.upgrade", "UPGRADES", "UPGRADE_SLOTS", "upgrades_panel", "upgrade_ids",
]

var _frames := 0
var _profile: Node = null
var _host: Control = null
var _saved: Dictionary = {}
var _status: Array[String] = []
var _danger: Array[bool] = []
var _panel: Control = null
var _shipyard: Control = null
var _launch: Control = null


func _ready() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[R1-PANES] no PlayerProfile autoload; aborting")
		get_tree().quit(2)
		return
	_borrow()
	_host = Control.new()
	_host.name = "R1Host"
	_host.theme = ThemeRes
	_host.size = Vector2(1440.0, 1000.0)
	_profile.add_child(_host)
	await get_tree().process_frame
	_panel = _mount(PanelScene, true) as Control
	_shipyard = _mount(ShipyardScene, false) as Control
	_launch = _mount(LaunchScene, true) as Control
	await get_tree().process_frame
	_probe_rail()
	await _probe_shell()
	_probe_grid()
	_probe_strings()
	_probe_meter()
	_probe_rows()
	_probe_pane_transactions()
	_probe_stale_refusal()
	_probe_unfit_hull()
	_probe_shipyard_hover()
	_probe_services()
	_probe_retired_tokens()
	_return()
	print("[R1-PANES] done")
	get_tree().quit(0)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames > FRAME_CAP:
		print("[R1-PANES] FRAME CAP %d reached; quitting" % FRAME_CAP)
		get_tree().quit(3)


## --------------------------------------------------------------------------- harness


func _borrow() -> void:
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"credits": int(_profile.call(&"credits")),
		&"fits": _profile.call(&"fits"),
		&"owned": _profile.call(&"owned_ships"),
		&"modules": _profile.call(&"modules"),
		&"vitals": _profile.get(&"_vitals"),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	_delete(PROFILE_PATH)


func _return() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", _saved[&"ship"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.set(&"_vitals", _saved[&"vitals"])
	_profile.call(&"flush")
	_profile.set(&"save_path", _saved[&"path"])
	_delete(PROFILE_PATH)


func _delete(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _seed(hull: StringName, modules: Dictionary, with_fit: bool) -> void:
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", [hull] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_vitals", {})
	_profile.set(&"_modules", _records(modules))
	if with_fit:
		_profile.call(&"set_fit", hull, FitData.standard_fit(hull))


func _records(modules: Dictionary) -> Dictionary:
	var records: Dictionary = {}
	for key: Variant in modules:
		records[String(key)] = {"base_id": String(key), "count": int(modules[key])}
	return records


func _mount(scene: PackedScene, connect_status: bool) -> Control:
	var panel := scene.instantiate() as Control
	_host.add_child(panel)
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	if connect_status and panel.has_signal(&"status_requested"):
		panel.connect(&"status_requested", _on_status)
	return panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _fit(hull: StringName) -> Dictionary:
	return _profile.call(&"fit_for", hull)


func _held(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _row(module_id: StringName) -> Button:
	for child: Node in (_panel.get_node("%ModuleRows") as VBoxContainer).get_children():
		var button := child as Button
		if button != null and StringName(button.get_meta(&"id", &"")) == module_id:
			return button
	return null


func _cell(slot_key: StringName, index: int) -> Dictionary:
	for cell: Dictionary in FitData.grid_cells(_panel.call(&"active_hull")):
		if bool(cell[&"gap"]):
			continue
		if StringName(cell[&"type"]) == slot_key and int(cell[&"index"]) == index:
			return cell
	return {}


## ------------------------------------------------------------------------- the rail


func _probe_rail() -> void:
	var modules: Array = StationScript.Module.keys()
	print("[R1-PANES] rail enum=%s (FITTING present=%s, UPGRADES present=%s)" % [
		modules, modules.has("FITTING"), modules.has("UPGRADES")
	])
	print("[R1-PANES] rail labels=%s" % [StationScript.MODULE_LABELS])
	print("[R1-PANES] rail files=%s" % [StationScript.MODULE_FILES])
	print("[R1-PANES] entry 4: label=%s file=%s icon=%s tinted=%s bed=%s" % [
		StationScript.MODULE_LABELS[4],
		StationScript.MODULE_FILES[4],
		StationScript.MODULE_ICONS[4],
		StationScript.MODULE_TINTED[4],
		StationScript.MODULE_BEDS[4],
	])
	print("[R1-PANES] retired files on disk: upgrades_panel.gd=%s .tscn=%s ; fitting pane: .gd=%s .tscn=%s" % [
		FileAccess.file_exists("res://ui/station/upgrades_panel.gd"),
		FileAccess.file_exists("res://ui/station/upgrades_panel.tscn"),
		FileAccess.file_exists("res://ui/station/fitting_panel.gd"),
		FileAccess.file_exists("res://ui/station/fitting_panel.tscn"),
	])
	var crate: RefCounted = Catalog.new()
	var constants: Dictionary = (crate.get_script() as Script).get_script_constant_map()
	print("[R1-PANES] StationCatalog constants: UPGRADES=%s UPGRADE_SLOTS=%s SHIPS=%s SERVICES=%s" % [
		constants.has("UPGRADES"), constants.has("UPGRADE_SLOTS"),
		constants.has("SHIPS"), constants.has("SERVICES"),
	])


## The assembled shell: the rail it builds, and which pane answered for the fifth entry.
func _probe_shell() -> void:
	var screen := StationScene.instantiate() as Control
	_host.add_child(screen)
	await get_tree().process_frame
	var buttons := screen.get_node("%ModuleButtons") as VBoxContainer
	var labels: Array[String] = []
	for child: Node in buttons.get_children():
		var label := _first_label(child)
		labels.append("%s=%s" % [child.name, label.text if label != null else "?"])
	print("[R1-PANES] shell rail entries: %s" % [labels])
	var host := screen.get_node("%HostMargin") as MarginContainer
	var panes: Array[String] = []
	for child: Node in host.get_children():
		panes.append(str(child.name))
	print("[R1-PANES] shell panes under HostMargin: %s" % [panes])
	print("[R1-PANES] shell has Fitting=%s Upgrades=%s" % [
		host.get_node_or_null(^"Fitting") != null, host.get_node_or_null(^"Upgrades") != null
	])
	screen.free()


func _first_label(node: Node) -> Label:
	for child: Node in node.get_children():
		var label := child as Label
		if label != null:
			return label
		var inner := _first_label(child)
		if inner != null:
			return inner
	return null


## ------------------------------------------------------------------------- the grid


func _probe_grid() -> void:
	_seed(HULL, {LASER: 1}, true)
	_panel.call(&"refresh_profile", &"fits")
	var grid := _panel.get_node("%SlotLayoutGrid") as GridContainer
	var cells: Array = FitData.grid_cells(HULL)
	var gaps := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			gaps += 1
	print("[R1-PANES] FITTING grid: cells=%d gaps=%d columns=%d h_sep=%d caption=%s" % [
		grid.get_child_count(), gaps, grid.columns,
		grid.get_theme_constant(&"h_separation"),
		(_panel.get_node("%SlotCaption") as Label).text,
	])
	_shipyard.call(&"refresh_profile", &"fits")
	var yard := _shipyard.get_node("%HardpointSlots") as GridContainer
	print("[R1-PANES] shipyard grid: cells=%d columns=%d h_sep=%d caption=%s" % [
		yard.get_child_count(), yard.columns,
		yard.get_theme_constant(&"h_separation"),
		(_shipyard.get_node("%HardpointCaption") as Label).text,
	])
	var same := 0
	var index := 0
	while index < mini(grid.get_child_count(), yard.get_child_count()) and index < LOOP_CAP:
		var mine := grid.get_child(index) as Control
		var theirs := yard.get_child(index) as Control
		if mine.custom_minimum_size == theirs.custom_minimum_size:
			same += 1
		index += 1
	print("[R1-PANES] the two grids agree on %d of %d cells' cell size" % [same, index])
	var first := _first_plate(grid)
	print("[R1-PANES] a FITTING cell: class=%s variation=%s focus=%d toggle=%s disabled=%s min=%s" % [
		first.get_class(), first.theme_type_variation, first.focus_mode,
		first.toggle_mode, first.disabled, first.custom_minimum_size,
	])
	var ring := first.get_theme_stylebox(&"focus")
	print("[R1-PANES] the cell's focus ring: %s" % _ring(ring))
	print("[R1-PANES] the grid's first child is a gap Control: %s" % (
		grid.get_child(0).get_class()
	))


func _first_plate(grid: GridContainer) -> Button:
	for child: Node in grid.get_children():
		var plate := child as Button
		if plate != null:
			return plate
	return null


func _ring(box: StyleBox) -> String:
	if box == null:
		return "<none>"
	if box is StyleBoxFlat:
		var flat := box as StyleBoxFlat
		return "%s border=%d colour=%s" % [
			box.get_class(), flat.border_width_left, flat.border_color
		]
	return box.get_class()


## ------------------------------------------------------------- the pin's own wordings


func _probe_strings() -> void:
	var constants: Dictionary = (_panel.get_script() as Script).get_script_constant_map()
	var mismatches: Array[String] = []
	var checked := 0
	for key: String in PINNED:
		checked += 1
		var shipped: Variant = constants.get(key, null)
		var pinned: Variant = PINNED[key]
		if shipped == null:
			mismatches.append("%s is missing" % key)
		elif String(shipped) != String(pinned):
			mismatches.append("%s shipped=%s pinned=%s" % [key, shipped, pinned])
	print("[R1-PANES] pinned wordings checked=%d mismatches=%d %s" % [
		checked, mismatches.size(), mismatches
	])
	print("[R1-PANES] the pane's own keys: %s" % [
		_shipped_subset(constants, ["REFUSAL_OVERLOAD", "REFUSAL_MANDATORY", "REFUSAL_FIT_ILLEGAL", "METER_OVER", "SELECTION_FORMAT", "HARDPOINT_CAPTION"])
	])


func _shipped_subset(constants: Dictionary, keys: Array) -> String:
	var out: Array[String] = []
	var index := 0
	while index < keys.size() and index < LOOP_CAP:
		out.append("%s=%s" % [keys[index], constants.get(keys[index], "<missing>")])
		index += 1
	return ", ".join(out)


## ------------------------------------------------------------------------- the meter


## The meter's three forms, each recomputed from `ShipFit.fit_legal`'s own `power` dictionary
## and compared with the pane's text: an independent arithmetic on the same source.
func _probe_meter() -> void:
	_seed(HULL, {CANNON: 1}, true)
	_panel.call(&"clear_selection")
	var power: Dictionary = FitData.fit_legal(HULL, _fit(HULL))[&"power"]
	var expected := String(PINNED["METER_IDLE"]) % [int(power[&"draw"]), int(power[&"out"])]
	print("[R1-PANES] idle: pane=%s fit_legal=%s expected=%s equal=%s" % [
		_panel.call(&"meter_text"), power, expected, _panel.call(&"meter_text") == expected
	])
	_panel.call(&"select_cell", WEAPONS, 1)
	var row := _row(CANNON)
	row.mouse_entered.emit()
	var candidate := _candidate_fit(_fit(HULL), WEAPONS, 1, CANNON)
	var candidate_power: Dictionary = FitData.fit_legal(HULL, candidate)[&"power"]
	var expected_candidate := String(PINNED["METER_CANDIDATE"]) % [
		int(power[&"draw"]), int(power[&"out"]),
		int(candidate_power[&"draw"]), int(candidate_power[&"out"]),
	]
	print("[R1-PANES] candidate: pane=%s fit_legal=%s expected=%s equal=%s" % [
		_panel.call(&"meter_text"), candidate_power, expected_candidate,
		_panel.call(&"meter_text") == expected_candidate
	])
	## The over-budget form: the Lancer's two W cells over 08 section 2's output of 6. The
	## first plasma is legal (6 of 6, 09 section 3.1's draw 3 against the delivered fit's 3),
	## the second takes the candidate to 8 - 09 section 2's own over-by-2 arithmetic.
	_seed(FIGHTER, {PLASMA: 2}, true)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", WEAPONS, 0)
	_row(PLASMA).pressed.emit()
	var after_first: Dictionary = _fit(FIGHTER)
	var installed_power: Dictionary = FitData.fit_legal(FIGHTER, after_first)[&"power"]
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", WEAPONS, 1)
	var plasma_row := _row(PLASMA)
	plasma_row.mouse_entered.emit()
	var over_candidate := _candidate_fit(after_first, WEAPONS, 1, PLASMA)
	var over_power: Dictionary = FitData.fit_legal(FIGHTER, over_candidate)[&"power"]
	var expected_over := (String(PINNED["METER_CANDIDATE"]) % [
		int(installed_power[&"draw"]), int(installed_power[&"out"]),
		int(over_power[&"draw"]), int(over_power[&"out"]),
	]) + (String(PINNED["METER_OVER"]) % (
		int(over_power[&"draw"]) - int(over_power[&"out"])
	))
	print("[R1-PANES] one plasma installed: weapons=%s power=%s" % [
		after_first.get(WEAPONS, []), installed_power
	])
	print("[R1-PANES] over budget: pane=%s expected=%s equal=%s danger_colour=%s" % [
		_panel.call(&"meter_text"), expected_over,
		_panel.call(&"meter_text") == expected_over,
		(_panel.get_node("%MeterLabel") as Label).has_theme_color_override(&"font_color"),
	])
	var danger := (_panel.get_node("%MeterLabel") as Label).get_theme_color(&"font_color")
	print("[R1-PANES] danger colour=%s Tokens/accent_danger=%s equal=%s" % [
		danger, _panel.get_theme_color(&"accent_danger", &"Tokens"),
		danger == _panel.get_theme_color(&"accent_danger", &"Tokens"),
	])
	_status.clear()
	_danger.clear()
	plasma_row.pressed.emit()
	print("[R1-PANES] the over-budget press refuses: footer=%s danger=%s strip=%s" % [
		_panel.call(&"footer_text"),
		(_panel.get_node("%SelectionLine") as Label).has_theme_color_override(&"font_color"),
		_last_status(),
	])
	print("[R1-PANES] the refused over-budget call wrote nothing: weapons=%s plasma=%d" % [
		_fit(FIGHTER).get(WEAPONS, []), _held(PLASMA)
	])


func _candidate_fit(fit: Dictionary, slot_key: StringName, index: int, module_id: StringName) -> Dictionary:
	var out := fit.duplicate(true)
	if slot_key == POWER:
		out[slot_key] = String(module_id)
		return out
	var cells: Array = out[slot_key]
	while cells.size() <= index:
		cells.append("")
	cells[index] = String(module_id)
	out[slot_key] = cells
	return out


## ------------------------------------------------------------------ the pane's actions


func _probe_pane_transactions() -> void:
	_seed(HULL, {LASER: 2, CANNON: 1}, true)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", WEAPONS, 1)
	var before: Array = _fit(HULL).get(WEAPONS, [])
	var action_cannon: StringName = _panel.call(&"module_action", CANNON)
	print("[R1-PANES] W2 selected (holds %s): cannon ACTION=%s laser ACTION=%s" % [
		before[1], action_cannon, _panel.call(&"module_action", LASER)
	])
	var row := _row(CANNON)
	row.pressed.emit()
	print("[R1-PANES] after the row press: weapons=%s (cell 0 untouched=%s) cannon=%d laser=%d" % [
		_fit(HULL).get(WEAPONS, []),
		(_fit(HULL).get(WEAPONS, []) as Array)[0] == before[0],
		_held(CANNON), _held(LASER),
	])
	print("[R1-PANES] the swapped-in cell reads %s; the selection survived as %s" % [
		_panel.call(&"footer_text"), _panel.call(&"selected_cell"),
	])
	## The swap the pin describes: the same call, the displaced module back in the inventory.
	_seed(HULL, {LASER: 2, CANNON: 1}, true)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", WEAPONS, 0)
	var lasers_before := _held(LASER)
	_row(CANNON).pressed.emit()
	print("[R1-PANES] swap into W1 (held a laser): weapons=%s laser %d -> %d cannon=%d" % [
		_fit(HULL).get(WEAPONS, []), lasers_before, _held(LASER), _held(CANNON)
	])
	## The mandatory cell: the pane's own wording, and the profile refusing underneath.
	_seed(HULL, {ION: 1}, true)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", ENGINES, 0)
	_status.clear()
	_danger.clear()
	var can := bool(_panel.call(&"can_remove"))
	var removed: bool = _panel.call(&"remove_selected")
	print("[R1-PANES] E1 selected (holds %s): can_remove=%s remove_selected=%s" % [
		(_fit(HULL).get(ENGINES, []) as Array)[0], can, removed
	])
	print("[R1-PANES] footer=%s danger=%s strip=%s engines=%s" % [
		_panel.call(&"footer_text"),
		(_panel.get_node("%SelectionLine") as Label).has_theme_color_override(&"font_color"),
		_last_status(), _fit(HULL).get(ENGINES, []),
	])
	var panel_engines_remove: bool = _profile.call(&"clear_fit_slot", HULL, ENGINES, 0)
	print("[R1-PANES] the profile underneath refuses it too: %s" % panel_engines_remove)
	## And REMOVE on an ordinary filled cell does empty it.
	_seed(HULL, {}, true)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", &"shields", 0)
	_row(LASER)
	var shield_gone: bool = _panel.call(&"remove_selected")
	print("[R1-PANES] REMOVE on the delivered shield: %s shields=%s s_light back=%d" % [
		shield_gone, _fit(HULL).get(&"shields", []), _held(&"s_light")
	])


## W2's own finding, re-measured: an account with no stored fit for the active hull.
func _probe_unfit_hull() -> void:
	_seed(FIGHTER, {LASER: 2}, false)
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", WEAPONS, 1)
	var stored: Dictionary = _fit(FIGHTER)
	var action: StringName = _panel.call(&"module_action", LASER)
	var meter: String = _panel.call(&"meter_text")
	var installed: bool = _panel.call(&"install_module", LASER)
	print("[R1-PANES] unfit hull: stored fit holds a module=%s action=%s meter=%s" % [
		_holds_a_module(stored), action, meter
	])
	print("[R1-PANES] unfit hull: install through the pane=%s footer=%s" % [
		installed, _panel.call(&"footer_text")
	])
	var direct_legal: Dictionary = FitData.fit_legal(FIGHTER, _fit(FIGHTER))
	print("[R1-PANES] unfit hull: the stored candidate fit_legal=%s" % direct_legal)
	print("[R1-PANES] unfit hull: stored=%s" % stored)


func _holds_a_module(fit: Dictionary) -> bool:
	for key: StringName in FitData.FIT_SLOT_KEYS:
		var raw: Variant = fit.get(key, fit.get(String(key), null))
		if raw is Array:
			for entry: Variant in raw as Array:
				if String(entry) != "":
					return true
		elif raw is String or raw is StringName:
			if String(raw) != "":
				return true
	return false


## ------------------------------------------------------------- the OWNED MODULES rows


## The pin's order: one row per owned module id, `ShipFit.FIT_SLOT_KEYS` first and catalogue
## order inside a group. R1 derives the expected list here from `ModuleCatalog`'s own row order
## and compares it with the pane's `module_row_ids()`.
func _probe_rows() -> void:
	_seed(HULL, {&"u_cargo": 2, LASER: 1, &"s_heavy": 1, CANNON: 1}, true)
	_panel.call(&"refresh_profile", &"modules")
	var shipped: Array = _panel.call(&"module_row_ids")
	var expected := _expected_rows({&"u_cargo": 2, LASER: 1, &"s_heavy": 1, CANNON: 1})
	print("[R1-PANES] rows: shipped=%s" % [str(shipped)])
	print("[R1-PANES] rows: expected=%s equal=%s" % [str(expected), str(shipped) == str(expected)])
	var first := _row(LASER)
	print("[R1-PANES] a row's cells: title=%s meta=%s owned=%s action=%s" % [
		_cell_text(first, "Title"), _cell_text(first, "Meta"),
		_cell_text(first, "Owned"), _cell_text(first, "Action"),
	])
	_seed(HULL, {}, true)
	_panel.call(&"refresh_profile", &"modules")
	var box := _panel.get_node("%ModuleRows") as VBoxContainer
	var only := box.get_child(0) as Button
	var text := _deep_label_text(only)
	print("[R1-PANES] empty state: rows=%d text=%s disabled=%s pinned=%s" % [
		box.get_child_count(), text, only.disabled,
		text == String(PINNED["EMPTY_ROW"]),
	])


func _expected_rows(owned: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	for slot_key: StringName in FitData.FIT_SLOT_KEYS:
		for module_id: Variant in ModuleData.MODULES:
			var key := StringName(module_id)
			if not owned.has(key):
				continue
			if _slot_of(key) == slot_key:
				out.append(key)
	return out


func _slot_of(module_id: StringName) -> StringName:
	var slot: StringName = ModuleData.slot_of(module_id)
	return &"engines" if slot == &"engine" else slot


func _label_of(node: Node, target: String) -> String:
	for child: Node in node.get_children():
		if child.name == target and child is Label:
			return (child as Label).text
		var found := _label_of(child, target)
		if not found.is_empty():
			return found
	return ""


## A row's `Title` / `Meta` Label, or the `Value` Label inside an `Owned` / `Action` cell.
func _cell_text(row: Button, cell_name: String) -> String:
	var direct := _label_of(row, cell_name)
	if not direct.is_empty():
		return direct
	var cell := _find_named(row, cell_name)
	if cell == null:
		return ""
	return _label_of(cell, "Value")


func _find_named(node: Node, target: String) -> Node:
	for child: Node in node.get_children():
		if child.name == target:
			return child
		var found := _find_named(child, target)
		if found != null:
			return found
	return null


func _deep_label_text(node: Node) -> String:
	var text := ""
	for child: Node in node.get_children():
		if child is Label:
			text += (child as Label).text
		text += _deep_label_text(child)
	return text


## Whether a refusal's line outlives the action that follows it on the same cell.
func _probe_stale_refusal() -> void:
	_seed(HULL, {ION: 1}, true)
	_panel.call(&"refresh_profile", &"fits")
	_panel.call(&"clear_selection")
	_panel.call(&"select_cell", ENGINES, 0)
	## A refused REMOVE on the mandatory engine cell, then a legal SWAP of that same cell -
	## no re-selection in between, so only the refusal's own lifetime is under test.
	var removed: bool = _panel.call(&"remove_selected")
	var refused := String(_panel.call(&"footer_text"))
	var swapped: bool = _panel.call(&"install_module", ION)
	print("[R1-PANES] refused REMOVE=%s footer=%s" % [removed, refused])
	print("[R1-PANES] then a legal swap on the same cell: ok=%s engines=%s" % [
		swapped, _fit(HULL).get(ENGINES, [])
	])
	print("[R1-PANES] footer now=%s (still the refusal=%s) meter=%s" % [
		_panel.call(&"footer_text"),
		_panel.call(&"footer_text") == refused,
		_panel.call(&"meter_text"),
	])
	_panel.call(&"clear_selection")
	print("[R1-PANES] after clear_selection footer=%s" % _panel.call(&"footer_text"))


## ------------------------------------------------------------- the shipyard's hover line


func _probe_shipyard_hover() -> void:
	_seed(HULL, {LASER: 3}, true)
	var line_fitted: String = _shipyard.call(&"hover_line", _yard_cell(WEAPONS, 0))
	var line_empty: String = _shipyard.call(&"hover_line", _yard_cell(WEAPONS, 1))
	var line_gap: String = _shipyard.call(&"hover_line", {"gap": true, "token": "W", "index": 0})
	print("[R1-PANES] hover fitted=%s" % line_fitted)
	print("[R1-PANES] hover empty=%s" % line_empty)
	print("[R1-PANES] hover gap=%s (a gap carries no line)" % line_gap)
	## The line is read live: a fit write shows on the next hover, with no refresh key.
	_profile.call(&"fit_module_at", HULL, WEAPONS, 1, LASER)
	var line_after: String = _shipyard.call(&"hover_line", _yard_cell(WEAPONS, 1))
	print("[R1-PANES] after a fit write, W2 hovers as %s" % line_after)
	## A hull the account does not own: `fit_for` answers all-empty, so every cell reads EMPTY.
	_seed(FIGHTER, {LASER: 3}, false)
	var unowned: String = _shipyard.call(&"hover_line", _yard_cell(WEAPONS, 0))
	print("[R1-PANES] a hull with no stored fit: %s" % unowned)


func _yard_cell(slot_key: StringName, index: int) -> Dictionary:
	for cell: Dictionary in FitData.grid_cells(StringName(_shipyard.get(&"_selected_id"))):
		if bool(cell[&"gap"]):
			continue
		if StringName(cell[&"type"]) == slot_key and int(cell[&"index"]) == index:
			return cell
	return {}


## ------------------------------------------------------------------------- the services


func _probe_services() -> void:
	_seed(HULL, {}, true)
	var fuel_pool := _pool(false)
	var energy_pool := _pool(true)
	print("[R1-PANES] FREE_FEE=%d fuel pool=%d energy pool=%d" % [
		RepairsService.FREE_FEE, fuel_pool, energy_pool
	])
	_file_report(0)
	var credits := int(_profile.call(&"credits"))
	_panel_set_fuel(0)
	_status.clear()
	_danger.clear()
	(_launch.call(&"refuel_button") as Button).pressed.emit()
	print("[R1-PANES] REFUEL: strip=%s danger=%s fuel=%d credits %d -> %d" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		_fuel(), credits, int(_profile.call(&"credits")),
	])
	print("[R1-PANES] REFUEL label=%s (catalogue name=%s)" % [
		(_launch.call(&"refuel_button") as Button).text,
		String(Catalog.service(&"refuel").get(&"name", "")),
	])
	_panel_set_fuel(fuel_pool)
	_status.clear()
	_danger.clear()
	(_launch.call(&"recharge_button") as Button).pressed.emit()
	print("[R1-PANES] RECHARGE: strip=%s danger=%s label=%s (catalogue name=%s)" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		(_launch.call(&"recharge_button") as Button).text,
		String(Catalog.service(&"recharge").get(&"name", "")),
	])
	## The full tank: the service's own refusal, rendered, button still pressable.
	_panel_set_fuel(fuel_pool)
	var credits_before := int(_profile.call(&"credits"))
	_status.clear()
	_danger.clear()
	(_launch.call(&"refuel_button") as Button).pressed.emit()
	print("[R1-PANES] full tank: strip=%s danger=%s credits %d -> %d fuel=%d disabled=%s" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		credits_before, int(_profile.call(&"credits")), _fuel(),
		(_launch.call(&"refuel_button") as Button).disabled,
	])
	var direct: Dictionary = RepairsService.refuel(_profile, HULL)
	print("[R1-PANES] the service's own full-tank result=%s" % direct)
	_profile.set(&"_vitals", {})
	_status.clear()
	_danger.clear()
	(_launch.call(&"recharge_button") as Button).pressed.emit()
	print("[R1-PANES] no report: strip=%s danger=%s" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
	])
	var deck := (_launch.get_node("%LaunchButton") as Button).get_parent()
	var names: Array[String] = []
	for child: Node in deck.get_children():
		names.append("%d:%s" % [child.get_index(), child.name])
	print("[R1-PANES] DECK CONTROL children: %s" % [names])


func _pool(energy: bool) -> int:
	var stats: ShipStats = FitData.resolve(HULL, FitData.STANDARD_FIT)
	if stats == null:
		return 0
	return maxi(0, int(round(stats.energy_max if energy else stats.fuel_max)))


func _file_report(fuel: int) -> void:
	var ship := Catalog.ship(HULL)
	_profile.call(&"set_vitals", HULL, int(ship.get(&"hull", 0)), int(ship.get(&"shield", 0)), fuel)


func _panel_set_fuel(value: int) -> void:
	_file_report(value)


func _fuel() -> int:
	return int(_profile.call(&"vitals_of", HULL).get(&"fuel", -1))


## ----------------------------------------------------- the retired surface, tree-wide


func _probe_retired_tokens() -> void:
	var hits: Array[String] = []
	var scanned := _scan("res://", hits, 0)
	print("[R1-PANES] retired-token scan: files=%d hits=%d" % [scanned, hits.size()])
	var index := 0
	while index < hits.size() and index < LOOP_CAP:
		print("[R1-PANES]   %s" % hits[index])
		index += 1


func _scan(path: String, hits: Array[String], count: int) -> int:
	var directory := DirAccess.open(path)
	if directory == null:
		return count
	directory.list_dir_begin()
	var name := directory.get_next()
	var guard := 0
	while not name.is_empty() and guard < FILE_CAP:
		guard += 1
		var full := path.path_join(name)
		if directory.current_is_dir():
			if name != "." and name != ".." and name != ".godot" and name != "addons":
				count = _scan(full, hits, count)
		elif name.ends_with(".gd") or name.ends_with(".tscn"):
			count += 1
			_scan_tokens(full, hits)
		name = directory.get_next()
	directory.list_dir_end()
	return count


func _scan_tokens(path: String, hits: Array[String]) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return
	var lines := text.split("\n")
	var line_number := 0
	var guard := 0
	while line_number < lines.size() and guard < FILE_CAP:
		guard += 1
		var line := lines[line_number]
		for token: String in RETIRED_TOKENS:
			if line.contains(token):
				hits.append("%s:%d %s" % [path, line_number + 1, token])
		line_number += 1
