extends Node
## S8-Q0 evidence probe (part 1): reproduce the QA's H1 / H2 / M4 on HEAD, in memory,
## with the shipped scenes and the borrowed `PlayerProfile` autoload.
##
## It builds the QA's own fit shape through the profile (Standard Drive + Cannon MkI +
## Railgun + Mining Laser, plus the Light Shield and Light Plate the M4 numbers need),
## launches the real `game.tscn`, and prints - for the same launch - the briefing total
## the LAUNCH panel computes, the store's `ammo_*` packs and hold units, the per-slot
## `_seed_ammo` readers, the live `PlayerState.ammo`, the HUD's pushed W cells, the Ship
## Status pane's own rows and footer, the resolved maxima `ShipFit.resolve` yields, the
## station hull row, and the Repairs pane's own denominators.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_s8_q0_launch.tscn \
##         --quit-after 3600 --fixed-fps 60
## Signal: the [S8Q0] lines; the last line is `[S8Q0] done`.
##
## Probe hygiene: the read-only evidence pass borrows the profile and repoints `save_path`
## at a scratch file (L17). Run under a scratch `XDG_DATA_HOME` so not even that scratch
## touches the owner's store.

const FitData := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/station_catalog.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const RepairsPanelScene := preload("res://ui/station/repairs_panel.tscn")

const SCRATCH_PROFILE := "user://probe_s8_q0_launch.cfg"
const TAG := "[S8Q0]"
const HULL: StringName = &"ship_vanguard"
## The QA's own filed vitals (`profile.cfg`, 2026-09-24): the hull full at the resolved
## 1250, the shield at the resolved 800.
const QA_VITALS: Dictionary = {
	"ship_vanguard": {"hull": 1250, "shield": 800, "fuel": 110},
}

## The QA's fit shape: Standard Drive (e_std), Cannon MkI, Railgun, Mining Laser, with the
## Light Shield and Light Plate the QA's `1250 / 800` rations need.
const QA_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_cannon", "w_railgun", "w_mining"],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}
## The shipped P2-A baseline fit (one laser), for the seed-path control.
const STD_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_laser"],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}
## The live profile's own fit at the QA's reading (three cannon cells), kept as the third
## control because the H2 symptom (a duplicated family) is a three-cell shape.
const TRIPLE_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_cannon", "w_cannon", "w_cannon"],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_vitals: Dictionary = {}
var _previous_market: Dictionary = {}
var _previous_batteries: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("%s FAIL no PlayerProfile autoload" % TAG)
		get_tree().quit(1)
		return
	_borrow()
	print("%s probe=s8_q0_launch hull=%s" % [TAG, HULL])
	_dump_axis()
	_build_bag()
	_scan("qa_fit", QA_FIT)
	_scan("standard_fit", STD_FIT)
	_scan("triple_cannon", TRIPLE_FIT)
	_scan_drained_cannon()
	_scan_cells("two_cannon_no_racks", ["w_cannon", "w_cannon", ""], {})
	_scan_cells("armour_in_w_cell", ["w_cannon", "w_cannon", "h_plate_light"], {})
	_scan_cells("qa_fit_migrated_racks", ["w_cannon", "w_railgun", "w_mining"], {"ship_vanguard": [[0], [1], [2]]})
	_scan_cells("qa_fit_one_rack", ["w_cannon", "w_railgun", "w_mining"], {"ship_vanguard": [[0, 1]]})
	_scan_cells("tool_first", ["w_mining", "w_laser", ""], {})
	_scan_cells("tool_middle", ["w_cannon", "w_mining", "w_laser"], {})
	await _fire_case()
	_hand_back()
	print("%s done" % TAG)
	get_tree().quit(0)


## ---------------------------------------------------------------------------
## The scenarios
## ---------------------------------------------------------------------------


func _build_bag() -> void:
	## One instance per module the QA's fit uses, so the fit stores instance ids the way a
	## played account does and every base-id bridge is exercised.
	_profile.call(&"set_modules", {})
	var bag: Dictionary = {}
	var counter := 0
	for base: StringName in [&"e_std", &"w_cannon", &"w_railgun", &"w_mining", &"s_light", &"h_plate_light", &"w_laser"]:
		counter += 1
		var id := "mod_%04d" % counter
		bag[id] = {
			"base_id": String(base),
			"count": 1,
			"instance_id": id,
			"prefixes": [],
			"rarity": "common",
			"suffixes": [],
		}
	_profile.call(&"set_modules", bag)
	_profile.set(&"_active_ship", HULL)


func _install(fit: Dictionary) -> void:
	_profile.call(&"set_fit", HULL, fit)
	## Reset the packs and the hold to the shipped fresh-account state (the S5 default:
	## every family at `DEFAULT_AMMO`), so each scenario starts from the same store.
	var packs: Dictionary = {}
	for weapon: StringName in _ammo_families():
		packs[String(weapon)] = 300
	_profile.set(&"_ammo", packs)
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_profile.set(&"_vitals", QA_VITALS.duplicate(true))
	_profile.set(
		&"_market",
		{"demand": {}, "stock": {}, "queue": {}, "trend": {}, "last_band": 0}
	)


## One scenario: install the fit, launch the shipped scene, print every reading the QA's
## H1 / H2 / M4 quote.
func _scan(label: String, fit: Dictionary) -> void:
	print("%s --- scenario %s weapons=%s ---" % [TAG, label, str(fit[&"weapons"])])
	_install(fit)
	_dump_store("pre-launch")
	_dump_briefing()
	var scene := _open()
	var state: Variant = scene.get(&"_state")
	print("%s launch_fit      = %s" % [TAG, str(scene.get(&"_launch_fit"))])
	print("%s state.weapons   = %s" % [TAG, str(state.weapons)])
	print("%s state.ammo      = %s max=%s" % [TAG, str(state.ammo), str(state.ammo_max)])
	print("%s ammo_seed       = %s" % [TAG, str(scene.get(&"_ammo_seed"))])
	print("%s state.hull_max  = %.1f shield_max = %.1f" % [TAG, state.hull_max, state.shield_max])
	var cells: Array = scene.call(&"_hull_slot_cells")
	print("%s hud W cells     = %s" % [TAG, _cells_text(cells)])
	_dump_status(scene)
	_dump_maxima(fit)
	_dump_repairs()
	print("%s store after     = %s" % [TAG, _store_text()])
	_drop(scene)


## The drained-pack case: the fit is the QA's, but the cannon pack is empty and the hold
## carries none of its cargo - the state in which the QA saw `Cannon MkI 0/300`.
func _scan_drained_cannon() -> void:
	print("%s --- scenario drained_cannon (the QA's flight reading) ---" % TAG)
	_install(QA_FIT)
	var packs: Dictionary = _profile.get(&"_ammo")
	packs["cannon"] = 0
	_profile.set(&"_ammo", packs)
	_dump_store("pre-launch")
	_dump_briefing()
	var scene := _open()
	var state: Variant = scene.get(&"_state")
	print("%s state.weapons   = %s" % [TAG, str(state.weapons)])
	print("%s state.ammo      = %s max=%s" % [TAG, str(state.ammo), str(state.ammo_max)])
	print("%s ammo_seed       = %s" % [TAG, str(scene.get(&"_ammo_seed"))])
	_dump_status(scene)
	print("%s store after     = %s" % [TAG, _store_text()])
	_drop(scene)


## The cell-level diff for the QA's H2: the fit's own W cells, the HUD's pushed cells and
## the Ship Status rows, for one fit + one rack record. Nothing else is printed.
func _scan_cells(label: String, weapons: Array, batteries: Dictionary) -> void:
	print("%s --- cells %s weapons=%s batteries=%s ---" % [TAG, label, str(weapons), str(batteries)])
	var fit := QA_FIT.duplicate(true)
	fit[&"weapons"] = weapons
	_install(fit)
	_profile.set(&"_batteries", batteries)
	var scene := _open()
	print("%s launch_fit      = %s" % [TAG, str(scene.get(&"_launch_fit")[&"weapons"])])
	print("%s state.weapons   = %s" % [TAG, str(scene.get(&"_state").weapons)])
	print("%s hud W cells     = %s" % [TAG, _cells_text(scene.call(&"_hull_slot_cells"))])
	var status: Variant = (scene.get(&"_hud") as Node).get(&"_status")
	var parts: Array[String] = []
	for row: Dictionary in status.call(&"module_rows"):
		parts.append(String(row[&"text"]))
	print("%s status rows    = %s" % [TAG, " | ".join(parts)])
	_drop(scene)


## Does a projectile leave once the fitted slot holds rounds? Two runs: the cannon alone
## with its pack drained, then the same slot corrected through `PlayerState.set_ammo` (what
## a stocked launch seeds).
func _fire_case() -> void:
	print("%s --- scenario fire (drained cannon slot vs loaded cannon slot) ---" % TAG)
	var fit := QA_FIT.duplicate(true)
	fit[&"weapons"] = ["w_cannon", "", ""]
	_install(fit)
	var packs: Dictionary = _profile.get(&"_ammo")
	packs["cannon"] = 0
	_profile.set(&"_ammo", packs)
	var scene := _open()
	var state: Variant = scene.get(&"_state")
	var guns: Node2D = scene.get(&"_guns")
	var ship: Node2D = scene.get_node_or_null(NodePath("PlayerShip"))
	if guns == null or ship == null:
		print("%s fire FAIL guns=%s ship=%s" % [TAG, str(guns != null), str(ship != null)])
		_drop(scene)
		return
	if not guns.shot_fired.is_connected(_on_shot):
		guns.shot_fired.connect(_on_shot)
	if not guns.dry_fired.is_connected(_on_dry):
		guns.dry_fired.connect(_on_dry)
	guns.call(&"set_aim_point", ship.global_position + Vector2(0.0, 300.0))
	print(
		"%s slot0=%s ammo=%d dry_reason=%s"
		% [TAG, str(state.weapons[0]), int(state.ammo[0]), str(guns.call(&"dry_reason"))]
	)
	var dry := await _fire(guns, 60)
	print(
		"%s dry    shots=%d dry=%d projectiles=%d ammo=%s"
		% [TAG, dry[0], dry[1], dry[2], str(state.ammo)]
	)
	state.set_ammo(0, 300)
	await get_tree().physics_frame
	var loaded := await _fire(guns, 60)
	print(
		"%s loaded shots=%d dry=%d projectiles=%d ammo=%s"
		% [TAG, loaded[0], loaded[1], loaded[2], str(state.ammo)]
	)
	_drop(scene)

	## The QA's own fit with the cannon drained: which slot the one rack actually spends.
	print("%s --- scenario fire (QA fit, cannon drained, railgun stocked) ---" % TAG)
	_install(QA_FIT)
	var mixed_packs: Dictionary = _profile.get(&"_ammo")
	mixed_packs["cannon"] = 0
	_profile.set(&"_ammo", mixed_packs)
	var mixed := _open()
	var mixed_state: Variant = mixed.get(&"_state")
	var mixed_guns: Node2D = mixed.get(&"_guns")
	var mixed_ship: Node2D = mixed.get_node_or_null(NodePath("PlayerShip"))
	if mixed_guns != null and mixed_ship != null:
		if not mixed_guns.shot_fired.is_connected(_on_shot):
			mixed_guns.shot_fired.connect(_on_shot)
		if not mixed_guns.dry_fired.is_connected(_on_dry):
			mixed_guns.dry_fired.connect(_on_dry)
		mixed_guns.call(&"set_aim_point", mixed_ship.global_position + Vector2(0.0, 300.0))
		var row := await _fire(mixed_guns, 60)
		print(
			"%s qa     shots=%d dry=%d projectiles=%d ammo=%s"
			% [TAG, row[0], row[1], row[2], str(mixed_state.ammo)]
		)
	_drop(mixed)


var _shots := 0
var _dries := 0


func _on_shot(_id: StringName) -> void:
	_shots += 1


func _on_dry(_id: StringName) -> void:
	_dries += 1


func _fire(guns: Node2D, frames: int) -> Array:
	_shots = 0
	_dries = 0
	guns.call(&"set_firing", true)
	for _frame in frames:
		await get_tree().physics_frame
	guns.call(&"set_firing", false)
	return [
		_shots,
		_dries,
		get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP).size(),
	]


## ---------------------------------------------------------------------------
## The readings
## ---------------------------------------------------------------------------


func _dump_axis() -> void:
	var mapping: Array[String] = []
	for id: StringName in [&"w_laser", &"w_cannon", &"w_railgun", &"w_mining", &"w_mine", &"w_plasma"]:
		mapping.append("%s->%s" % [id, WeaponsScript.weapon_id(id)])
	print("%s module->family %s" % [TAG, ", ".join(mapping)])
	print(
		"%s AMMO_PACKS ids=%s state.WEAPONS=%s GROUPS_MAX=%d"
		% [
			TAG,
			str(Catalog.ammo_item_ids()),
			str(preload("res://game/player_state.gd").WEAPONS),
			WeaponsScript.GROUPS_MAX,
		]
	)


func _ammo_families() -> Array[StringName]:
	var ids: Array[StringName] = []
	for pack: Dictionary in Catalog.AMMO_PACKS:
		ids.append(StringName(pack[&"id"]))
	return ids


func _dump_store(prefix: String) -> void:
	var parts: Array[String] = []
	for pack: Dictionary in Catalog.AMMO_PACKS:
		var id := StringName(pack[&"id"])
		parts.append(
			"%s=%d(max %d,hold %d)"
			% [id, int(_profile.call(&"ammo_of", id)), int(_profile.call(&"ammo_max", id)), int(_profile.call(&"ammo_units", id))]
		)
	print("%s %s store %s" % [TAG, prefix, ", ".join(parts)])


func _store_text() -> String:
	var parts: Array[String] = []
	for pack: Dictionary in Catalog.AMMO_PACKS:
		var id := StringName(pack[&"id"])
		parts.append("%s=%d" % [id, int(_profile.call(&"ammo_of", id))])
	return ", ".join(parts)


## The LAUNCH panel's own briefing arithmetic, transcribed from the panel (its private
## `_ammo_total` / `_weapon_count` read `Catalog.AMMO_PACKS` and `profile.ammo_of`).
func _dump_briefing() -> void:
	var total := 0
	for pack: Dictionary in Catalog.AMMO_PACKS:
		total += int(_profile.call(&"ammo_of", pack[&"id"]))
	print(
		"%s briefing AMMUNITION %s ROUNDS ACROSS %d WEAPONS"
		% [TAG, _format_int(total), Catalog.AMMO_PACKS.size()]
	)


func _dump_status(scene: Node2D) -> void:
	var hud: Variant = scene.get(&"_hud")
	if hud == null:
		print("%s status FAIL no HUD" % TAG)
		return
	var status: Variant = hud.get(&"_status")
	if status == null:
		print("%s status FAIL no status screen" % TAG)
		return
	var rows: Array = status.call(&"module_rows")
	var parts: Array[String] = []
	for row: Dictionary in rows:
		parts.append(String(row[&"text"]))
	print("%s status rows    = %s" % [TAG, " | ".join(parts)])
	print("%s status footer  = %s" % [TAG, str(status.call(&"footer_lines"))])


func _dump_maxima(fit: Dictionary) -> void:
	var stats: ShipStats = FitData.resolve(HULL, _base_fit(fit), _profile.call(&"affix_summary", HULL))
	var ship: Dictionary = Catalog.ship(HULL)
	print(
		"%s maxima resolve hull=%.0f shield=%.0f | station_catalog hull=%s shield=%s"
		% [
			TAG,
			stats.hull_max if stats != null else -1.0,
			stats.shield_max if stats != null else -1.0,
			str(ship.get(&"hull", -1)),
			str(ship.get(&"shield", -1)),
		]
	)


func _dump_repairs() -> void:
	var panel := RepairsPanelScene.instantiate() as Control
	add_child(panel)
	var values: Dictionary = panel.get(&"_values")
	var parts: Array[String] = []
	for key: StringName in [&"hull", &"shield", &"missing"]:
		var label: Label = values.get(key)
		parts.append("%s=%s" % [key, label.text if label != null else "?"])
	print("%s repairs pane    = %s" % [TAG, ", ".join(parts)])
	remove_child(panel)
	panel.free()


func _base_fit(fit: Dictionary) -> Dictionary:
	var translated: Variant = _profile.call(&"base_fit", fit)
	return translated if translated is Dictionary else fit


func _cells_text(cells: Array) -> String:
	var parts: Array[String] = []
	for cell: Dictionary in cells:
		parts.append(
			"{%d:%s B%d pos %d}"
			% [
				int(cell[&"index"]),
				StringName(cell[&"module"]) if bool(cell[&"fitted"]) else "-",
				int(cell[&"battery"]),
				int(cell[&"position"]),
			]
		)
	return "[%s]" % ", ".join(parts)


func _format_int(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		out = text[index] + out
		count += 1
		if count % 3 == 0 and index > 0:
			out = " " + out
	return out


## ---------------------------------------------------------------------------
## The borrowed profile
## ---------------------------------------------------------------------------


func _borrow() -> void:
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_modules = _profile.call(&"modules")
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_vitals = (_profile.get(&"_vitals") as Dictionary).duplicate(true)
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove(SCRATCH_PROFILE)


func _hand_back() -> void:
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_vitals", _previous_vitals)
	_profile.set(&"_market", _previous_market)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_remove(SCRATCH_PROFILE)
	print("%s scratch removed=%s" % [TAG, str(not FileAccess.file_exists(SCRATCH_PROFILE))])


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _open() -> Node2D:
	var scene := (load("res://game/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(scene)
	return scene


func _drop(scene: Node2D) -> void:
	if scene != null and is_instance_valid(scene):
		remove_child(scene)
		scene.free()
