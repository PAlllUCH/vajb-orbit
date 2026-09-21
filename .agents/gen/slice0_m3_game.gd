extends Node
## Slice 0, M3 probe C (throwaway; its source is archived under .agents/gen/ after the
## run and can be dropped back into res://tools/ to re-measure).
##
## Measures the two `game.gd` halves of M3's acceptance end to end: the launch
## handshake that seeds the persisted tank, the pool push into the HUD's section 3.1b
## bars, and filing the tank with the damage report on dock.
##
## The shipped `game.tscn` cannot load while the graphics lane's asset re-path is in
## flight (its three `env_stars_layer*.png` ext_resources are unresolvable), and
## `game.gd` itself cannot compile while `sector.gd`'s `env_station.png` preload is
## stale. So this probe builds the same node shape by hand (Node2D "Game" + Camera2D
## child) and runs the SHIPPED game.gd through a one-line-patched copy of its source:
## the unresolvable `const SectorScript := preload("res://game/sector.gd")` becomes an
## inline stub with the same four method signatures. The substitution is printed
## below, the copy is deleted again in `_finish`, and nothing under `assets/` is
## touched. A [FAIL] line means the acceptance did not land.

const ProfileScript := preload("res://autoload/player_profile.gd")
const Fit := preload("res://game/ship_fit.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const GAME_SOURCE := "res://game/game.gd"
const GAME_COPY := "res://tools/_probe_s0m3_game_copy.gd"
const SCRATCH_PROFILE := "user://_probe_s0m3_game_profile.cfg"

const SECTOR_PRELOAD := "const SectorScript := preload(\"res://game/sector.gd\")"
const SECTOR_STUB := "class SectorScript extends Node2D:\n\tfunc populate(_row: Dictionary) -> Vector2:\n\t\treturn Vector2.ZERO\n\n\n\tfunc blips() -> Array[Dictionary]:\n\t\treturn []\n\n\n\tfunc has_station() -> bool:\n\t\treturn true\n\n\n\tfunc dock_zone_contains(_position: Vector2) -> bool:\n\t\treturn false\n"

const STORED_HULL := 700
const STORED_SHIELD := 400
const STORED_FUEL := 80

var _ok := 0
var _fail := 0
var _profile: Node = null
var _game: Node2D = null
var _state: PlayerState = null
var _ship_id: StringName = &""


func _ready() -> void:
	_watch()
	_run()


func _watch() -> void:
	await get_tree().create_timer(60.0).timeout
	print("WATCHDOG: probe C did not finish in 60 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_ok += 1
	else:
		_fail += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _run() -> void:
	print("=== slice0 M3 probe C: launch seeding, the pool push and the dock report ===")
	_profile = get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		_check("profile autoload is reachable", false, "no /root/PlayerProfile")
		_finish()
		return
	_profile.save_path = SCRATCH_PROFILE
	_ship_id = StringName(_profile.call(&"active_ship"))
	_profile.call(&"set_vitals", _ship_id, STORED_HULL, STORED_SHIELD, STORED_FUEL)
	if not _prepare_copy():
		_finish()
		return
	await _boot_game()
	_launch()
	_pool_push()
	_dock_report()
	_finish()


func _prepare_copy() -> bool:
	var source := FileAccess.get_file_as_string(GAME_SOURCE)
	if source.is_empty() or not source.contains(SECTOR_PRELOAD):
		_check("the shipped game.gd carries the sector preload to stub", false, SECTOR_PRELOAD)
		return false
	print("substitution: %s -> an inline SectorScript stub (populate/blips/has_station/dock_zone_contains)" % SECTOR_PRELOAD)
	var patched := source.replace(SECTOR_PRELOAD, SECTOR_STUB)
	var file := FileAccess.open(GAME_COPY, FileAccess.WRITE)
	if file == null:
		_check("the patched copy is written", false, GAME_COPY)
		return false
	file.store_string(patched)
	file.close()
	var script := load(GAME_COPY) as GDScript
	_check("copy a: the patched copy compiles", script != null, GAME_COPY)
	return script != null


func _boot_game() -> void:
	var script := load(GAME_COPY) as GDScript
	_game = Node2D.new()
	_game.name = "Game"
	var camera := Camera2D.new()
	camera.name = "Camera"
	_game.add_child(camera)
	_game.set_script(script)
	add_child(_game)
	await get_tree().process_frame
	await get_tree().process_frame
	_state = _game.get(&"_state") as PlayerState
	_check("copy b: the game node boots on the unmodified code path", _state != null, "_state")
	var stats: ShipStats = _game.get(&"_stats") as ShipStats
	_check(
		"boot a: the ship scene resolved and launched",
		_game.get(&"_ship") != null,
		"ship=%s" % _game.get(&"_ship"),
	)
	_check(
		"boot b: the pools took their maxima from the launch snapshot (section 9)",
		_state != null and stats != null
			and is_equal_approx(_state.fuel_max, stats.fuel_max)
			and is_equal_approx(_state.energy_max, stats.energy_max)
			and _state.fuel_max > 0.0,
		"state fuel_max=%s energy_max=%s | stats fuel_max=%s energy_max=%s" % [
			_state.fuel_max, _state.energy_max, stats.fuel_max, stats.energy_max,
		],
	)
	_check(
		"boot c: the HUD instantiated with the section 3.1b API",
		_hud() != null and _hud().has_method(&"set_pool") and _hud().has_method(&"set_emergency"),
		"hud=%s" % _hud(),
	)


func _launch() -> void:
	if _state == null:
		_check("launch: the game node carries a PlayerState", false, "no _state")
		return
	_check(
		"launch a: the filed tank seeds the launch pool (Fuel persists)",
		is_equal_approx(_state.fuel, float(STORED_FUEL)),
		"fuel=%s filed=%d" % [_state.fuel, STORED_FUEL],
	)
	_check(
		"launch b: Energy recomputes at launch instead of being seeded (section 12 item 13)",
		is_equal_approx(_state.energy, _state.energy_max),
		"energy=%s/%s" % [_state.energy, _state.energy_max],
	)
	_check(
		"launch c: the damage report still seeds hull and shield",
		is_equal_approx(_state.hull, float(STORED_HULL))
			and is_equal_approx(_state.shield, float(STORED_SHIELD)),
		"hull=%s shield=%s" % [_state.hull, _state.shield],
	)
	var fuel_value := _value("FuelBlock")
	_check(
		"launch d: the HUD's Fuel bar reads the seeded tank",
		fuel_value != null and fuel_value.text == "%d/%d" % [STORED_FUEL, int(round(_state.fuel_max))],
		fuel_value.text if fuel_value != null else "missing",
	)


func _pool_push() -> void:
	var stats: ShipStats = _game.get(&"_stats") as ShipStats
	_state.set_fuel(20.0)
	_state.set_energy(35.0)
	_game.call(&"_push_pools")
	var fuel_value := _value("FuelBlock")
	var energy_value := _value("EnergyBlock")
	_check(
		"push a: the game's pool push reaches both section 3.1b readouts",
		fuel_value != null and energy_value != null
			and fuel_value.text == "20/%d" % int(round(stats.fuel_max))
			and energy_value.text == "35/%d" % int(round(stats.energy_max)),
		"%s | %s" % [energy_value.text, fuel_value.text],
	)
	_state.set_fuel(0.0)
	_game.call(&"_push_pools")
	_check(
		"push b: an empty tank raises the banner through the game's push",
		_banner() != null and _banner().visible,
		"banner=%s visible=%s" % [_banner(), _banner().visible if _banner() != null else "missing"],
	)
	_state.set_fuel(20.0)
	_game.call(&"_push_pools")
	_check(
		"push c: refilling hides it again",
		_banner() != null and not _banner().visible,
		"visible=%s" % (_banner().visible if _banner() != null else "missing"),
	)


func _dock_report() -> void:
	if _state == null:
		_check("dock: the game node carries a PlayerState", false, "no _state")
		return
	_state.set_fuel(64.0)
	_game.call(&"_file_damage_report")
	var record: Dictionary = _profile.call(&"vitals_of", _ship_id)
	_check(
		"dock a: docking files the live tank with the damage report",
		int(record.get("fuel", -1)) == int(round(_state.fuel))
			and int(record.get("hull", -1)) == int(_state.hull)
			and int(record.get("shield", -1)) == int(_state.shield),
		"%s vs fuel=%s" % [record, _state.fuel],
	)
	_profile.call(&"flush")
	var on_disk := ConfigFile.new()
	var loaded: bool = on_disk.load(SCRATCH_PROFILE) == OK
	var vitals: Dictionary = on_disk.get_value("profile", "vitals", {})
	var entry: Dictionary = vitals.get(String(_ship_id), {})
	_check(
		"dock b: the filed tank lands in the save v3 file",
		loaded
			and int(on_disk.get_value("profile", "save_version", 0)) == 3
			and int(entry.get("fuel", -1)) == int(round(_state.fuel)),
		"version=%d entry=%s" % [int(on_disk.get_value("profile", "save_version", 0)), entry],
	)


func _hud() -> Control:
	if _game == null:
		return null
	for child: Node in _game.get_children():
		if child.has_method(&"set_pool"):
			return child as Control
	return null


func _bar(block: String) -> ProgressBar:
	var hud := _hud()
	if hud == null:
		return null
	return hud.get_node_or_null(
		NodePath("CanvasLayer/TopLeft/Blocks/%s/%sBarRow/%sBar" % [block, block, block])
	) as ProgressBar


func _value(block: String) -> Label:
	var hud := _hud()
	if hud == null:
		return null
	return hud.get_node_or_null(
		NodePath("CanvasLayer/TopLeft/Blocks/%s/%sHeader/%sValue" % [block, block, block])
	) as Label


func _banner() -> Label:
	var hud := _hud()
	if hud == null:
		return null
	return hud.get_node_or_null(NodePath("CanvasLayer/TopLeft/Blocks/EmergencyBanner")) as Label


func _finish() -> void:
	if _game != null and is_instance_valid(_game):
		_game.free()
	if _profile != null and is_instance_valid(_profile):
		_profile.call(&"set_vitals", _ship_id, STORED_HULL, STORED_SHIELD, STORED_FUEL)
		_profile.call(&"flush")
		_profile.save_path = ProfileScript.SAVE_FILE
		_profile.call(&"reload")
	for path: String in [SCRATCH_PROFILE, GAME_COPY, GAME_COPY + ".uid"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
