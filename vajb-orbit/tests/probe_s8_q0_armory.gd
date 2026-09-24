extends Node
## S8-Q0 evidence probe (part 4): O1/O2 - does the ARMORY's drag actually commit a weapon
## group, driven through the panel's own three handlers (`_get_drag_data`'s payload builders
## `drag_inventory` / `drag_barrel`, `_can_drop_data`'s `can_drop`, `_drop_data`'s `drop`)?
##
## Also prints the surfaces that can assign a group today, and the group a drag lands
## (`PlayerProfile.battery_groups`) before and after.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_s8_q0_armory.tscn --quit-after 1200
## Signal: the [S8Q0A] lines; the last line is `[S8Q0A] done`.

const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const FittingScript := preload("res://ui/station/fitting_panel.gd")

const SCRATCH_PROFILE := "user://probe_s8_q0_armory.cfg"
const TAG := "[S8Q0A]"
const HULL: StringName = &"ship_vanguard"
const DROP_RACK_BODY := -1

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("%s FAIL no PlayerProfile autoload" % TAG)
		get_tree().quit(1)
		return
	_borrow()
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_fits", {})
	_profile.set(&"_batteries", {})
	_profile.call(&"set_fit", HULL, {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["", "", ""],
		&"shields": [],
		&"armour": [],
	})
	_profile.call(&"set_modules", {
		"mod_0001": _record("mod_0001", "w_laser", 1),
		"mod_0002": _record("mod_0002", "w_cannon", 1),
		"e_std": _record("e_std", "e_std", 1),
	})
	print("%s fitting drag handlers: %s" % [TAG, _fitting_handlers()])
	print("%s groups before = %s" % [TAG, str(_profile.call(&"battery_groups", HULL))])
	var panel := ArmoryScene.instantiate() as Control
	add_child(panel)
	await get_tree().process_frame
	print("%s armory hull = %s racks drawn = %d" % [TAG, panel.call(&"_active_hull", _profile), (panel.get(&"_rack_views") as Array).size()])

	## The inventory -> rack install: the drag the owner says "doesnt do anything".
	var payload: Dictionary = panel.call(&"drag_inventory", &"w_laser")
	print("%s drag_inventory(w_laser) = %s" % [TAG, str(payload)])
	print("%s can_drop(rack 0, body) = %s" % [TAG, str(panel.call(&"can_drop", 0, DROP_RACK_BODY, payload))])
	print("%s drop(rack 0, body)    = %s" % [TAG, str(panel.call(&"drop", 0, DROP_RACK_BODY, payload))])
	print("%s groups after install = %s" % [TAG, str(_profile.call(&"battery_groups", HULL))])
	print("%s stored batteries     = %s" % [TAG, str(_profile.call(&"batteries"))])
	print("%s fit.weapons          = %s" % [TAG, str(_profile.call(&"fit_for", HULL)[&"weapons"])])

	## A second barrel, so the barrel-move drag has somewhere to go.
	var payload2: Dictionary = panel.call(&"drag_inventory", &"w_cannon")
	panel.call(&"drop", 1, DROP_RACK_BODY, payload2)
	panel.call(&"refresh_profile", &"batteries")
	print("%s after cannon to B2   = %s" % [TAG, str(_profile.call(&"battery_groups", HULL))])
	var barrel: Dictionary = panel.call(&"drag_barrel", 1, 0)
	print("%s drag_barrel(B2, pos 0) = %s" % [TAG, str(barrel)])
	print("%s can_drop(rack 0, body) = %s" % [TAG, str(panel.call(&"can_drop", 0, DROP_RACK_BODY, barrel))])
	print("%s drop(rack 0, body)    = %s" % [TAG, str(panel.call(&"drop", 0, DROP_RACK_BODY, barrel))])
	print("%s groups after move    = %s" % [TAG, str(_profile.call(&"battery_groups", HULL))])
	print("%s stored batteries     = %s" % [TAG, str(_profile.call(&"batteries"))])

	remove_child(panel)
	panel.free()
	_hand_back()
	print("%s done" % TAG)
	get_tree().quit(0)


## The drag entry points `ui/station/fitting_panel.gd` declares, read off the shipped file's
## own script listing so "the FITTING pane has no drag code" is a measurement, not a claim.
func _fitting_handlers() -> String:
	## The script's **own** method list (`Script.get_script_method_list`), not
	## `Object.get_method_list`: the latter also reports `Control`'s engine-inherited
	## virtuals, so it cannot tell an override from a base class method.
	var script: Script = FittingScript
	var found: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var name_text := String(method.get("name", ""))
		if name_text in ["_get_drag_data", "_can_drop_data", "_drop_data"]:
			found.append(name_text)
	return "[%s]" % ", ".join(found)


func _record(id: String, base: String, count: int) -> Dictionary:
	return {
		"base_id": base,
		"count": count,
		"instance_id": id,
		"prefixes": [],
		"rarity": "common",
		"suffixes": [],
	}


func _borrow() -> void:
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove(SCRATCH_PROFILE)


func _hand_back() -> void:
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_remove(SCRATCH_PROFILE)
	print("%s scratch removed=%s" % [TAG, str(not FileAccess.file_exists(SCRATCH_PROFILE))])


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
