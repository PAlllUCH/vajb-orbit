extends Node
## W3 evidence probe: the shipyard's slot-plate hover line and LAUNCH's two station service rows,
## measured in memory with the shipped scenes and theme. No shipped file is written and the
## owner's profile is borrowed and handed back (the suite `test_p2b_services`'s own hygiene), so
## the probe is re-runnable byte-identically.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_w3_services.tscn --quit-after 600
## Signal: the [W3-SHIPYARD] / [W3-LAUNCH] lines; the last line is [W3-SERVICES] done.

const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const RepairsService := preload("res://game/repairs.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://probe_w3_services.cfg"

const HULL: StringName = &"ship_vanguard"
const UNOWNED: StringName = &"ship_fighter"
const LASER: StringName = &"w_laser"
const LASERS := 3

var _profile: Node = null
var _host: Control = null
var _shipyard: Control = null
var _launch: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _entered := 0
var _exited := 0
var _saved: Dictionary = {}


func _ready() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[W3-SERVICES] no PlayerProfile autoload; aborting")
		get_tree().quit(2)
		return
	_borrow()
	_seed()
	_host = Control.new()
	_host.name = "W3Host"
	_host.theme = ThemeRes
	_host.size = Vector2(1280.0, 900.0)
	tree.root.get_node(NodePath(&"PlayerProfile")).add_child(_host)
	await get_tree().process_frame
	_shipyard = _mount(ShipyardScene)
	_launch = _mount(LaunchScene)
	await get_tree().process_frame
	_probe_plates()
	await _probe_real_hover()
	_probe_unowned_hull()
	_probe_deck_control()
	_probe_refuel()
	_probe_recharge()
	_probe_refusals()
	_return()
	print("[W3-SERVICES] done")
	get_tree().quit(0)


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
	_delete_file(PROFILE_PATH)


func _return() -> void:
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", _saved[&"ship"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.set(&"_vitals", _saved[&"vitals"])
	_profile.call(&"flush")
	_profile.set(&"save_path", _saved[&"path"])
	_delete_file(PROFILE_PATH)


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _seed() -> void:
	_profile.set(&"_credits", int(Catalog.ship(HULL).get(&"cost", 0)))
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_owned_ships", [HULL] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_vitals", {})
	_profile.set(&"_modules", {
		String(LASER): {"base_id": String(LASER), "count": LASERS}
	})
	_profile.call(&"set_fit", HULL, ShipFit.standard_fit(HULL))


func _mount(scene: PackedScene) -> Control:
	var panel := scene.instantiate() as Control
	_host.add_child(panel)
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	panel.connect(&"status_requested", _on_status)
	return panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _last() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _cell(slot_key: StringName, index: int) -> Dictionary:
	for cell: Dictionary in ShipFit.grid_cells(StringName(_shipyard.get(&"_selected_id"))):
		if bool(cell[&"gap"]):
			continue
		if StringName(cell[&"type"]) == slot_key and int(cell[&"index"]) == index:
			return cell
	return {}


func _plate(token: String, index: int) -> Control:
	return _shipyard.get_node("%HardpointSlots").get_node_or_null(
		NodePath("Slot%s%02d" % [token, index])
	) as Control


func _hover(cell: Dictionary) -> String:
	return String(_shipyard.call(&"hover_line", cell))


func _module_name(module_id: StringName) -> String:
	return String(ModuleData.module(module_id).get(&"name", "")).to_upper()


## The enum names, so the log says `MOUSE_FILTER_STOP` rather than `0`.
func _filter_name(value: int) -> String:
	match value:
		Control.MOUSE_FILTER_STOP:
			return "MOUSE_FILTER_STOP"
		Control.MOUSE_FILTER_PASS:
			return "MOUSE_FILTER_PASS"
		Control.MOUSE_FILTER_IGNORE:
			return "MOUSE_FILTER_IGNORE"
	return "?"


func _focus_name(value: int) -> String:
	match value:
		Control.FOCUS_NONE:
			return "FOCUS_NONE"
		Control.FOCUS_CLICK:
			return "FOCUS_CLICK"
		Control.FOCUS_ALL:
			return "FOCUS_ALL"
	return "?"


## The plates' own geometry and the line each one carries, before any pointer arrives.
func _probe_plates() -> void:
	var grid := _shipyard.get_node("%HardpointSlots") as GridContainer
	var caption := _shipyard.get_node("%HardpointCaption") as Label
	print("[W3-SHIPYARD] hull=%s grid columns=%d cells=%d h_sep=%d v_sep=%d caption=%s" % [
		_shipyard.get(&"_selected_id"),
		grid.columns,
		grid.get_child_count(),
		grid.get_theme_constant(&"h_separation"),
		grid.get_theme_constant(&"v_separation"),
		caption.text,
	])
	for token: String in ["W", "P", "E"]:
		var plate := _plate(token, 0)
		if plate == null:
			continue
		var glyph := plate.get_node_or_null(^"Icon") as TextureRect
		print("[W3-SHIPYARD] plate %s%02d size=%s disabled=%s focus_mode=%d (%s) mouse_filter=%d (%s) variation=%s art=%s inset=%s glyph=%s" % [
			token, 0,
			plate.custom_minimum_size,
			plate.disabled,
			plate.focus_mode,
			_focus_name(plate.focus_mode),
			plate.mouse_filter,
			_filter_name(plate.mouse_filter),
			plate.theme_type_variation,
			plate.texture_normal.resource_path if plate.texture_normal != null else "<none>",
			glyph.offset_left if glyph != null else -1.0,
			glyph.texture.resource_path if glyph != null and glyph.texture != null else "<none>",
		])
	print("[W3-SHIPYARD] line W1=%s" % _hover(_cell(&"weapons", 0)))
	print("[W3-SHIPYARD] line W2=%s" % _hover(_cell(&"weapons", 1)))
	print("[W3-SHIPYARD] line P1=%s" % _hover(_cell(&"power", 0)))
	print("[W3-SHIPYARD] line E1=%s" % _hover(_cell(&"engines", 0)))
	print("[W3-SHIPYARD] owned: %s x%d, %s x%d (module_count)" % [
		_module_name(LASER), int(_profile.call(&"module_count", LASER)),
		_module_name(&"p_std"), int(_profile.call(&"module_count", &"p_std")),
	])


## A real pointer, not a hand-emitted signal: an `InputEventMouseMotion` pushed through the
## viewport over the plate's own centre, then one outside it again. This is the measurement that
## proves a disabled plate with the filter set to STOP actually reports a hover.
func _probe_real_hover() -> void:
	var plate := _plate("W", 0)
	plate.mouse_entered.connect(func() -> void: _entered += 1)
	plate.mouse_exited.connect(func() -> void: _exited += 1)
	var point := plate.get_global_rect().get_center()
	_push_pointer(point)
	await get_tree().process_frame
	print("[W3-SHIPYARD] pushed pointer at %s: entered=%d exited=%d status=%s" % [
		point, _entered, _exited, _last()
	])
	var outside := Vector2(4.0, 4.0)
	_push_pointer(outside)
	await get_tree().process_frame
	print("[W3-SHIPYARD] pushed pointer at %s: entered=%d exited=%d status=%s" % [
		outside, _entered, _exited, _last()
	])


func _push_pointer(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	get_viewport().push_input(event)


## A hull the account does not own: every cell reads EMPTY, because `fit_for` answers the
## all-empty shape for it.
func _probe_unowned_hull() -> void:
	print("[W3-SHIPYARD] owns %s: %s" % [UNOWNED, _profile.call(&"owned_ships")])
	for child: Node in (_shipyard.get_node("%ShipList") as VBoxContainer).get_children():
		var row := child as Button
		if row == null or StringName(row.get_meta(&"id", &"")) != UNOWNED:
			continue
		row.grab_focus()
		break
	print("[W3-SHIPYARD] after focusing %s: selected=%s fit_for=%s" % [
		UNOWNED, _shipyard.get(&"_selected_id"), _profile.call(&"fit_for", UNOWNED)
	])
	var cell := _cell(&"weapons", 0)
	print("[W3-SHIPYARD] unowned hull line W1=%s (gap=%s)" % [
		_hover(cell), _hover({&"gap": true, &"token": "W", &"index": 0})
	])
	for child: Node in (_shipyard.get_node("%ShipList") as VBoxContainer).get_children():
		var row := child as Button
		if row == null or StringName(row.get_meta(&"id", &"")) != HULL:
			continue
		row.grab_focus()
		break
	print("[W3-SHIPYARD] back on %s: line W1=%s" % [HULL, _hover(_cell(&"weapons", 0))])


## DECK CONTROL's box: what the two buttons are, where they sit and what the strip reads before
## any service is asked for.
func _probe_deck_control() -> void:
	var launch_button := _launch.get_node("%LaunchButton") as Button
	var box := launch_button.get_parent()
	print("[W3-LAUNCH] deck control children: %s" % [_child_names(box)])
	for id: StringName in [&"refuel", &"recharge"]:
		var service: Dictionary = Catalog.service(id)
		print("[W3-LAUNCH] catalogue service %s = %s (free=%s instant=%s)" % [
			id, service.get(&"name"), service.get(&"free"), service.get(&"instant")
		])
	for button: Button in [_launch.call(&"refuel_button"), _launch.call(&"recharge_button")]:
		print("[W3-LAUNCH] button %s text=%s min=%s variation=%s focus=%d parent=%s" % [
			button.name, button.text, button.custom_minimum_size,
			button.theme_type_variation, button.focus_mode, button.get_parent().name
		])
	print("[W3-LAUNCH] idle strip=%s" % (_launch.get_node("%ConfirmStrip") as Label).text)
	print("[W3-LAUNCH] FREE_FEE=%d hull max=%d fuel pool=%d energy pool=%d" % [
		RepairsService.FREE_FEE,
		int(Catalog.ship(HULL).get(&"hull", 0)),
		_pool(false), _pool(true),
	])


func _child_names(box: Node) -> String:
	var names: Array[String] = []
	for child: Node in box.get_children():
		names.append("%d:%s" % [child.get_index(), child.name])
	return ", ".join(names)


func _pool(energy: bool) -> int:
	var stats: ShipStats = ShipFit.resolve(HULL, ShipFit.STANDARD_FIT)
	if stats == null:
		return 0
	return maxi(0, int(round(stats.energy_max if energy else stats.fuel_max)))


func _file_report(fuel: int) -> void:
	var ship := Catalog.ship(HULL)
	_profile.call(&"set_vitals", HULL, int(ship.get(&"hull", 0)), int(ship.get(&"shield", 0)), fuel)


func _fuel() -> int:
	return int(_profile.call(&"vitals_of", HULL).get(&"fuel", -1))


## The refuel path twice over: the service's own result dictionary, and the pane's own strip and
## colour for the same call. Credits are printed on both sides of every call.
func _probe_refuel() -> void:
	_file_report(0)
	var credits := int(_profile.call(&"credits"))
	var direct: Dictionary = RepairsService.refuel(_profile, HULL)
	print("[W3-LAUNCH] refuel direct result=%s credits %d -> %d fuel -> %d" % [
		direct, credits, int(_profile.call(&"credits")), _fuel()
	])
	_file_report(0)
	_status.clear()
	_danger.clear()
	(_launch.call(&"refuel_button") as Button).pressed.emit()
	print("[W3-LAUNCH] refuel pane strip=%s danger=%s credits=%d fuel=%d" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		int(_profile.call(&"credits")),
		_fuel(),
	])
	print("[W3-LAUNCH] refuel signal: %s danger=%s" % [_last(), _danger[_danger.size() - 1]])


func _probe_recharge() -> void:
	_file_report(_pool(false))
	var credits := int(_profile.call(&"credits"))
	var fuel := _fuel()
	var direct: Dictionary = RepairsService.recharge(_profile, HULL)
	print("[W3-LAUNCH] recharge direct result=%s credits %d -> %d fuel %d -> %d" % [
		direct, credits, int(_profile.call(&"credits")), fuel, _fuel()
	])
	_status.clear()
	_danger.clear()
	(_launch.call(&"recharge_button") as Button).pressed.emit()
	print("[W3-LAUNCH] recharge pane strip=%s danger=%s credits=%d fuel=%d" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		int(_profile.call(&"credits")),
		_fuel(),
	])


## The service's refusals, rendered: a full tank, then a hull with no filed report.
func _probe_refusals() -> void:
	_file_report(_pool(false))
	var credits := int(_profile.call(&"credits"))
	print("[W3-LAUNCH] full tank direct result=%s" % RepairsService.refuel(_profile, HULL))
	_status.clear()
	_danger.clear()
	(_launch.call(&"refuel_button") as Button).pressed.emit()
	print("[W3-LAUNCH] full tank pane strip=%s danger=%s credits=%d fuel=%d button_disabled=%s" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
		int(_profile.call(&"credits")),
		_fuel(),
		(_launch.call(&"refuel_button") as Button).disabled,
	])
	print("[W3-LAUNCH] full tank signal danger=%s" % _danger[_danger.size() - 1])
	print("[W3-LAUNCH] credits across every call: %d -> %d" % [
		credits, int(_profile.call(&"credits"))
	])
	_profile.set(&"_vitals", {})
	_status.clear()
	_danger.clear()
	(_launch.call(&"refuel_button") as Button).pressed.emit()
	print("[W3-LAUNCH] no report direct result=%s" % RepairsService.refuel(_profile, HULL))
	print("[W3-LAUNCH] no report pane strip=%s danger=%s" % [
		(_launch.get_node("%ConfirmStrip") as Label).text,
		(_launch.get_node("%ConfirmStrip") as Label).has_theme_color_override(&"font_color"),
	])
	print("[W3-SERVICES] danger colour on the strip: %s" % (
		(_launch.get_node("%ConfirmStrip") as Label).get_theme_color(&"font_color")
	))
	print("[W3-SERVICES] Tokens/accent_danger = %s" % (
		_launch.get_theme_color(&"accent_danger", &"Tokens")
	))
