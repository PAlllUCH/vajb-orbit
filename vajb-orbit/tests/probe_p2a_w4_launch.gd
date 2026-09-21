extends Node
## P2-A W4 evidence probe: launch every player hull off the shipped `PlayerProfile`
## autoload and print the numbers the wave's report quotes - the resolved fit, the live
## weapon slots, the seeded packs, the engine set's arithmetic, the HUD's cell payload
## and the mount anchors - so each one can be re-measured by hand.
##
##   ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_p2a_w4_launch.tscn
##
## Self-quitting and bounded: it prints and calls `quit()` in `_ready`, so no frame is
## awaited and the caller never waits on the process. The profile is borrowed (its four
## launch-facing fields snapshotted and handed back, its `save_path` repointed at a
## scratch file for the whole run) and the scratch file is removed at the end, so the
## owner's `user://profile.cfg` is never written (probe hygiene L17).

const GameScene := preload("res://game/game.tscn")
const FitData := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/module_catalog.gd")
const WeaponsScript := preload("res://game/weapons.gd")

const SCRATCH_PROFILE := "user://probe_p2a_w4_launch.cfg"
const TAG := "[w4]"
const HULLS: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_corvette",
	&"ship_freighter",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]
## The three engine sets 09 section 3.7's arithmetic is measured on, launched on the
## Mule's three cells rather than resolved by hand.
const ENGINE_SETS: Array[Array] = [
	[&"e_std"],
	[&"e_std", &"e_ion"],
	[&"e_std", &"e_ion", &"e_vector"],
	[&"e_vector", &"e_vector"],
]

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("%s FAIL the PlayerProfile autoload is the launch's store" % TAG)
		get_tree().quit(1)
		return
	_borrow()
	print("%s probe=p2a_w4_launch hulls=%d" % [TAG, HULLS.size()])
	_dump_axis()
	_scan_standard_fits()
	_scan_engine_sets()
	_scan_stored_fit()
	_scan_tool_cell()
	_dump_owner_gate()
	_hand_back()
	get_tree().quit(0)


## ---------------------------------------------------------------------------
## The launch itself
## ---------------------------------------------------------------------------


## Launch one hull on one stored fit (an empty dictionary means "no fit stored") and
## return the live scene. Every reading below comes off this scene.
func _launch(hull_id: StringName, fit: Dictionary) -> Node2D:
	_install(hull_id, fit)
	return _open()


## Write the profile the launch reads. The scene never writes it; the probe does, so
## each scan starts from a known store.
func _install(hull_id: StringName, fit: Dictionary) -> void:
	_profile.set(&"_active_ship", hull_id)
	if fit.is_empty():
		_profile.set(&"_fits", {})
	else:
		_profile.call(&"set_fit", hull_id, fit)


## Instantiate the shipped flight scene under this probe, which runs its whole launch
## handshake synchronously.
func _open() -> Node2D:
	var scene := (load("res://game/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(scene)
	return scene


func _drop(scene: Node2D) -> void:
	if scene != null and is_instance_valid(scene):
		remove_child(scene)
		scene.free()


## One line per hull on the shipped standard-fit fallback: the grid's E/W counts, the
## fit's weapon ids, the live slots, the seeded packs and the resolved engine figures.
func _scan_standard_fits() -> void:
	print("%s --- the standard-fit fallback, hull by hull ---" % TAG)
	for hull: StringName in HULLS:
		var scene := _launch(hull, {})
		var state: Variant = scene.get(&"_state")
		var stats: Variant = scene.get(&"_stats")
		var fit: Dictionary = scene.get(&"_launch_fit")
		var handling: Dictionary = FitData.HANDLING[hull]
		var size := FitData.grid_size(hull)
		print(
			(
				"%s %-15s grid=%dx%d E=%d W=%d | fit.weapons=%s | slots=%s ammo=%s"
				+ " | engines=%s | speed=%.4f (base %.1f) turn=%.4f | anchors=%d"
			)
			% [
				TAG,
				hull,
				size.x,
				size.y,
				FitData.slot_capacity(hull, &"engines"),
				FitData.slot_capacity(hull, &"weapons"),
				str(fit.get(&"weapons", [])),
				str(state.weapons),
				str(state.ammo),
				str(fit.get(&"engines", [])),
				stats.max_speed,
				float(handling[&"max_speed"]),
				stats.turn_rate,
				(_ship_of(scene).call(&"thruster_anchors") as Array).size(),
			]
		)
		var cells: Array = scene.call(&"_hull_slot_cells")
		var selectable := 0
		for cell: Dictionary in cells:
			if bool(cell[&"selectable"]):
				selectable += 1
		print(
			"%s   HUD cells=%d selectable=%d payload=%s"
			% [TAG, cells.size(), selectable, _cells_text(cells)]
		)
		_drop(scene)


## 09 section 3.7's set arithmetic, launched on the Mule's three engine cells: the
## summed speed multiplier, its 1.40 ceiling and the unclamped turn multiplier, with the
## pre-amendment product quoted beside each row.
func _scan_engine_sets() -> void:
	var hull: StringName = &"ship_freighter"
	var handling: Dictionary = FitData.HANDLING[hull]
	var base_speed := float(handling[&"max_speed"])
	var base_turn := float(handling[&"turn_rate"])
	print(
		"%s --- the engine set on %s (base speed %.1f, base turn %.4f) ---"
		% [TAG, hull, base_speed, base_turn]
	)
	for engines: Array in ENGINE_SETS:
		var fit := {&"engines": engines, &"power": "p_std"}
		var scene := _launch(hull, fit)
		var stats: Variant = scene.get(&"_stats")
		var sum := 0.0
		var product := 1.0
		var turn := 1.0
		for id: Variant in engines:
			var row: Dictionary = FitData.MODULES[StringName(id)]
			var speed_mult := float((row[&"effects"] as Dictionary).get(&"speed_mult", 1.0))
			sum += speed_mult - 1.0
			product *= speed_mult
			turn += float((row[&"effects"] as Dictionary).get(&"turn_mult", 1.0)) - 1.0
		print(
			(
				"%s %-34s sum=%.4f product=%.4f | launched speed=%.4f (x%.4f)"
				+ " turn=%.4f (x%.4f) | legal=%s"
			)
			% [
				TAG,
				str(engines),
				1.0 + sum,
				product,
				stats.max_speed,
				stats.max_speed / base_speed,
				stats.turn_rate,
				stats.turn_rate / base_turn,
				str(FitData.fit_legal(hull, fit)[&"legal"]),
			]
		)
		_drop(scene)


## The profile's own fit, read and never written: an inventory instance id is mapped to
## its base id for the resolver while the store keeps the instance id, and the HUD's
## cells carry the module's catalogue icon.
func _scan_stored_fit() -> void:
	var hull: StringName = &"ship_vanguard"
	_profile.call(&"set_modules", {"mod_0007": {"base_id": "w_cannon", "count": 1}})
	var fit := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["mod_0007", "w_laser", "w_rocket"],
		&"shields": ["s_light"],
	}
	print("%s --- a stored fit with an instance id ---" % TAG)
	_install(hull, fit)
	var stored_before: Dictionary = _profile.call(&"fits")
	print("%s stored fit    = %s" % [TAG, str(stored_before)])
	var scene := _open()
	var state: Variant = scene.get(&"_state")
	var cells: Array = scene.call(&"_hull_slot_cells")
	print("%s launched fit  = %s" % [TAG, str(scene.get(&"_launch_fit"))])
	print("%s live slots    = %s ammo=%s" % [TAG, str(state.weapons), str(state.ammo)])
	print("%s HUD payload   = %s" % [TAG, _cells_text(cells)])
	print(
		"%s icon(w_laser)=%s exists=%s"
		% [
			TAG,
			Catalog.icon_path(&"w_laser"),
			str(ResourceLoader.exists(Catalog.icon_path(&"w_laser"))),
		]
	)
	print(
		"%s store after launch unchanged=%s (instance id still stored=%s)"
		% [
			TAG,
			str(_profile.call(&"fits") == stored_before),
			str(_profile.call(&"fit_for", hull)[&"weapons"][0]),
		]
	)
	_drop(scene)


## A W cell that is a tool rather than a gun (`w_mining`, 09 section 4.5): the fit
## carries it, the HUD's cell carries its module, and the live slot list carries the
## empty family `Weapons.weapon_id` answers for it - measured so the report can state
## the seam instead of claiming a gun.
func _scan_tool_cell() -> void:
	var hull: StringName = &"ship_miner"
	var fit := {
		&"engines": ["e_std", "e_std"],
		&"power": "p_std",
		&"weapons": ["w_mining", "w_laser"],
	}
	var scene := _launch(hull, fit)
	var state: Variant = scene.get(&"_state")
	var ship: Node2D = _ship_of(scene)
	print("%s --- a W cell that is the mining tool ---" % TAG)
	print(
		"%s fit.weapons=%s live slots=%s ammo=%s mounts_laser=%s"
		% [
			TAG,
			str(scene.get(&"_launch_fit")[&"weapons"]),
			str(state.weapons),
			str(state.ammo),
			str((ship.call(&"_has_mining_module") if ship.has_method(&"_has_mining_module") else false)),
		]
	)
	_drop(scene)


## The owner's launch-fit gate, measured: the hull it reports, the weapon ids it
## actually mounts and the rounds those packs hold.
func _dump_owner_gate() -> void:
	print("%s --- the owner gate's two symptoms ---" % TAG)
	var scene := _launch(&"ship_fighter", {})
	var state: Variant = scene.get(&"_state")
	var rounds := 0
	for value: int in state.ammo:
		rounds += value
	print(
		"%s active hull=ship_fighter mounted=%s slots=%d total_rounds=%d (was five families / 1500)"
		% [TAG, str(state.weapons), state.ammo.size(), rounds]
	)
	_drop(scene)


## ---------------------------------------------------------------------------
## Supporting readings
## ---------------------------------------------------------------------------


## The module-id -> family bridge and the catalogue's icon rule, printed once so the
## mapping the launch relies on is visible beside the numbers it produced.
func _dump_axis() -> void:
	var mapping: Array[String] = []
	for id: StringName in [&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_mining"]:
		mapping.append("%s->%s" % [id, WeaponsScript.weapon_id(id)])
	print("%s module->family %s" % [TAG, ", ".join(mapping)])
	print("%s GROUPS_MAX=%d" % [TAG, WeaponsScript.GROUPS_MAX])


func _cells_text(cells: Array) -> String:
	var parts: Array[String] = []
	for cell: Dictionary in cells:
		parts.append(
			"{%d:%s%s}"
			% [
				int(cell[&"index"]),
				StringName(cell[&"module"]) if bool(cell[&"fitted"]) else "-",
				"" if bool(cell[&"selectable"]) else "!",
			]
		)
	return "[%s]" % ", ".join(parts)


func _ship_of(scene: Node2D) -> Node2D:
	return scene.get_node_or_null(NodePath("PlayerShip")) as Node2D


## ---------------------------------------------------------------------------
## The borrowed profile (the suite's discipline, one snapshot for the whole run)
## ---------------------------------------------------------------------------


func _borrow() -> void:
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_modules = _profile.call(&"modules")
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove(SCRATCH_PROFILE)


func _hand_back() -> void:
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_remove(SCRATCH_PROFILE)
	print("%s scratch removed=%s" % [TAG, str(not FileAccess.file_exists(SCRATCH_PROFILE))])


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
