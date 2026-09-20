extends Node
## W6 review probe, archived re-runnable form (engine wave 1). Copy both files to
## res://tools/_probe_w6_review.gd and res://tools/_probe_w6_review.tscn and run:
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
##     --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_w6_review.tscn
## Scene run, not a --script run (game.gd's Router reference does not compile in a
## custom main loop). Quits explicitly, so it cannot hang.
##
## Re-measures: the section 13 constants, flight handling on the shipped
## player_ship.tscn, the mining work model and the shipped MiningLaser cycle,
## pickup tractor/collection/hold-full/lifetime, the seven sector spawn counts,
## and the five cross-worker seams. A [FAIL] line means the seam is broken.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const LaserScene := preload("res://game/mining_laser.tscn")
const LaserScript := preload("res://game/mining_laser.gd")
const PickupScript := preload("res://game/pickup.gd")
const Catalog := preload("res://game/station_catalog.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")
const GameScript := preload("res://game/game.gd")

const SCRATCH_PROFILE := "user://_w6_probe_profile.cfg"
const SCRATCH_LOG := "user://_w6_probe_log.txt"

var _checks := 0
var _fails := 0
var _game: Node = null


func _ready() -> void:
	_watchdog()
	_run()


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG: probe did not finish in 90 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _step() -> void:
	await get_tree().process_frame


func _run() -> void:
	var profile := get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	if profile != null:
		profile.set(&"save_path", SCRATCH_PROFILE)
	EconomyLogScript.log_path = SCRATCH_LOG

	_constants()
	_handling()
	await _mining()
	await _pickups(profile)
	await _spawns()
	await _seams(profile)
	await _hud_wiring()

	print("=== w6 review probe: checks %d, failures %d ===" % [_checks, _fails])
	for path: String in [SCRATCH_PROFILE, SCRATCH_LOG]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	get_tree().quit(1 if _fails > 0 else 0)


func _constants() -> void:
	print("--- ENGINE_SPEC section 13 constants as shipped ---")
	print("BRAKE_MULT=%s SLOW_DOWN=%s ARRIVE=%s WARP_QUIET=%s MINE_CYCLE=%s LASER_RANGE=%s" % [
		PlayerShipScript.BRAKE_MULT, PlayerShipScript.SLOW_DOWN_RADIUS,
		PlayerShipScript.ARRIVE_RADIUS, PlayerShipScript.WARP_DAMAGE_QUIET,
		LaserScript.MINE_CYCLE, LaserScript.MINE_LASER_RANGE,
	])
	print("PICKUP lifetime=%s tractor=%s/%s | SECTOR_SIZE=%s WARP_CHANNEL=%s" % [
		PickupScript.LIFETIME, PickupScript.TRACTOR_RANGE, PickupScript.TRACTOR_SPEED,
		Registry.SECTOR_SIZE, GameScript.WARP_CHANNEL,
	])
	_check(
		"section 13 globals",
		PlayerShipScript.BRAKE_MULT == 1.8 and PlayerShipScript.SLOW_DOWN_RADIUS == 240.0
			and PlayerShipScript.ARRIVE_RADIUS == 40.0 and LaserScript.MINE_CYCLE == 1.2
			and LaserScript.MINE_LASER_RANGE == 220.0 and PickupScript.LIFETIME == 60.0
			and PickupScript.TRACTOR_RANGE == 120.0 and PickupScript.TRACTOR_SPEED == 90.0
			and Registry.SECTOR_SIZE == Vector2(10000.0, 10000.0)
			and GameScript.WARP_CHANNEL == 3.0,
		"all match section 13",
	)


func _handling() -> void:
	print("--- handling (shipped player_ship.tscn, vanguard standard fit, manual 120 Hz) ---")
	var stats: ShipStats = ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT)
	var dt := 1.0 / 120.0
	var state: PlayerState = PlayerStateScript.new()
	state.setup()
	print("stats max_speed=%s accel=%s coast=%s turn=%s spinup=%s" % [
		stats.max_speed, stats.accel_time, stats.coast_time, stats.turn_rate, stats.turn_spinup,
	])
	_check(
		"resolved vanguard handling = section 13 + the plate multiplier",
		is_equal_approx(stats.max_speed, 406.6) and is_equal_approx(stats.accel_time, 2.52)
			and is_equal_approx(stats.coast_time, 2.1) and is_equal_approx(stats.turn_rate, 3.0)
			and is_equal_approx(stats.turn_spinup, 0.525),
		"406.6/2.52/2.1/3.0/0.525 expected",
	)
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	ship.call(&"setup", stats, state)
	Input.action_press(&"thrust_forward")
	var accel := _steps(ship, dt, 1200, func(s: Node2D) -> bool:
		return absf(float(s.get(&"_speed")) - stats.max_speed) < 0.5)
	Input.action_release(&"thrust_forward")
	_check("accel time", absf(accel - stats.accel_time) <= dt * 1.5, "measured=%s" % accel)
	var coast := _steps(ship, dt, 1200, func(s: Node2D) -> bool:
		return is_zero_approx(float(s.get(&"_speed"))))
	_check("coast time", absf(coast - stats.coast_time) <= dt * 1.5, "measured=%s" % coast)
	Input.action_press(&"thrust_forward")
	_steps(ship, dt, 1200, func(s: Node2D) -> bool:
		return absf(float(s.get(&"_speed"))) > 400.0)
	Input.action_release(&"thrust_forward")
	Input.action_press(&"thrust_backward")
	var brake := _steps(ship, dt, 1200, func(s: Node2D) -> bool:
		return float(s.get(&"_speed")) <= 0.0)
	Input.action_release(&"thrust_backward")
	_check(
		"brake time = accel_time / BRAKE_MULT",
		absf(brake - stats.accel_time / PlayerShipScript.BRAKE_MULT) <= dt * 2.0,
		"measured=%s expected=%s" % [brake, stats.accel_time / PlayerShipScript.BRAKE_MULT],
	)
	Input.action_press(&"turn_right")
	var spin := _steps(ship, dt, 1200, func(s: Node2D) -> bool:
		return absf(float(s.get(&"_turn_speed"))) >= stats.turn_rate * 0.99)
	Input.action_release(&"turn_right")
	_check("turn spin-up", absf(spin - stats.turn_spinup) <= dt * 2.0, "measured=%s" % spin)
	var autopilot: Node2D = PlayerShipScene.instantiate() as Node2D
	autopilot.call(&"setup", stats, state)
	autopilot.call(&"set_move_target", Vector2(1200.0, 0.0))
	_steps(autopilot, dt, 3000, func(s: Node2D) -> bool:
		return not bool(s.get(&"_has_move_target")))
	_check(
		"autopilot arrives inside ARRIVE_RADIUS",
		autopilot.global_position.distance_to(Vector2(1200.0, 0.0)) <= PlayerShipScript.ARRIVE_RADIUS,
		"distance=%s" % autopilot.global_position.distance_to(Vector2(1200.0, 0.0)),
	)
	var bodies := 0
	for node: Node in _descendants(PlayerShipScene.instantiate()):
		if node is CollisionObject2D:
			bodies += 1
	_check("player_ship.tscn has no collision body", bodies == 0, "bodies=%d" % bodies)


func _steps(ship: Node2D, dt: float, max_steps: int, done: Callable) -> float:
	for step in max_steps:
		ship.call(&"_physics_process", dt)
		if bool(done.call(ship)):
			return float(step + 1) * dt
	return -1.0


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out


func _mining() -> void:
	print("--- mining: work model + shipped laser cycle ---")
	var field: Node2D = FieldScript.new() as Node2D
	add_child(field)
	await _step()
	field.call(&"setup", {&"tier_weights": {1: 100}, &"rocks": 6, &"seed": 4242})
	await _step()
	var rocks: Array = field.call(&"rocks")
	_check("field 6..12 rocks", rocks.size() >= 6 and rocks.size() <= 12, "rocks=%d" % rocks.size())
	var rock: Node2D = rocks[0]
	var units := int(rock.get(&"yield_units"))
	var mined := 0
	for _unit in units:
		mined += int(rock.call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
	_check("N cycles = N units", mined == units, "yield=%d mined=%d" % [units, mined])
	var gun := 0
	for _hit in 10:
		gun += int((rocks[1] as Node2D).call(&"apply_work", 0.1))
	_check("ten 0.1 hits = 1 unit (10 % gun rate)", gun == 1, "units=%d" % gun)

	var laser: Node2D = LaserScene.instantiate() as Node2D
	add_child(laser)
	await _step()
	laser.set_physics_process(false)
	laser.call(&"bind", ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT))
	var target: Node2D = null
	var acquired := false
	for _attempt in 3:
		if target != null and is_instance_valid(target):
			target.queue_free()
		await _step()
		var cursor: Vector2 = laser.get_global_mouse_position()
		laser.global_position = cursor + Vector2(60.0, 0.0)
		target = AsteroidScript.new() as Node2D
		add_child(target)
		await _step()
		target.call(&"setup", &"iron", 1, 3)
		target.global_position = cursor
		await get_tree().physics_frame
		await get_tree().physics_frame
		laser.call(&"set_active", true)
		laser.call(&"_physics_process", 1.0 / 120.0)
		if bool(laser.call(&"has_target")):
			acquired = true
			break
	laser.call(&"set_active", false)
	laser.call(&"set_active", true)
	var at_11 := -1
	var at_13 := -1
	var elapsed := 0.0
	for _step_index in 180:
		laser.call(&"_physics_process", 1.0 / 120.0)
		elapsed += 1.0 / 120.0
		var count := 0
		for child: Node in get_children():
			if child.name.begins_with("Pickup"):
				count += 1
		if at_11 < 0 and elapsed >= 1.1:
			at_11 = count
		if at_13 < 0 and elapsed >= 1.3:
			at_13 = count
			break
	print("laser acquired=%s ; pickups at 1.1 s = %d, at 1.3 s = %d" % [acquired, at_11, at_13])
	_check("MINE_CYCLE 1.2 s -> one unit and one pickup after, none before",
		acquired and at_11 == 0 and at_13 == 1, "1.1s=%d 1.3s=%d" % [at_11, at_13])
	laser.call(&"set_active", false)
	target.queue_free()
	laser.queue_free()
	field.queue_free()
	for child: Node in get_children():
		if child.name.begins_with("Pickup"):
			child.queue_free()
	await _step()


func _pickups(profile: Node) -> void:
	print("--- pickup: tractor, collection, hold-full, lifetime ---")
	var active: StringName = profile.call(&"active_ship")
	var hold := int(Catalog.ship(active).get(&"cargo", -1))
	print("active_ship=%s ; StationCatalog hold=%s ; ShipStats hold=%s" % [
		active, hold, ShipFit.HULLS.get(active, {}).get(&"cargo", -1),
	])
	var player := Node2D.new()
	player.name = "FakePlayer"
	add_child(player)
	player.add_to_group(&"player_ship")
	await _step()
	var pulled := _pickup(&"credits", 5, true, Vector2(110.0, 0.0))
	for _frame in 30:
		pulled.call(&"_physics_process", 1.0 / 60.0)
	_check("tractor pull 90 u/s (45 u in 30 frames)", absf(110.0 - pulled.global_position.x - 45.0) < 0.01,
		"travelled=%s" % (110.0 - pulled.global_position.x))
	pulled.queue_free()
	var credits := int(profile.call(&"credits"))
	var cache := _pickup(&"credits", 250, true, Vector2(10.0, 0.0))
	cache.call(&"_physics_process", 1.0 / 60.0)
	_check("cache pays through add_credits", int(profile.call(&"credits")) == credits + 250,
		"%d -> %d" % [credits, int(profile.call(&"credits"))])
	_free_room(profile, hold, 1)
	var before := int(profile.call(&"cargo_qty", &"mineral_iron"))
	var ore := _pickup(&"mineral_iron", 1, false, Vector2(30.0, 0.0))
	for _frame in 14:
		ore.call(&"_physics_process", 1.0 / 60.0)
	_check("ore goes through add_cargo", int(profile.call(&"cargo_qty", &"mineral_iron")) == before + 1,
		"%d -> %d" % [before, int(profile.call(&"cargo_qty", &"mineral_iron"))])
	if is_instance_valid(ore):
		ore.queue_free()
	var aged := _pickup(&"mineral_iron", 1, false, Vector2(600.0, 0.0))
	aged.set(&"_age", PickupScript.LIFETIME - 0.001)
	aged.call(&"_physics_process", 0.01)
	await _step()
	_check("pickup despawns at 60 s", not is_instance_valid(aged), "valid=%s" % is_instance_valid(aged))
	var held := _total(profile)
	if hold > 0 and held < hold:
		profile.call(&"add_cargo", &"mineral_iron", hold - held)
	var full_before := _total(profile)
	var blocked := _pickup(&"mineral_iron", 1, false, Vector2(30.0, 30.0))
	for _frame in 30:
		blocked.call(&"_physics_process", 1.0 / 60.0)
	_check("hold full -> pickup drifts, not pulled or collected",
		hold > 0 and _total(profile) == full_before and blocked.global_position == Vector2(30.0, 30.0),
		"total %d -> %d, pos %s" % [full_before, _total(profile), blocked.global_position])
	blocked.queue_free()
	player.queue_free()
	var added := _total(profile) - (full_before - (hold - full_before))
	if added > 0:
		profile.call(&"remove_cargo", &"mineral_iron", added)
	await _step()


func _pickup(item: StringName, amount: int, cache: bool, at: Vector2) -> Node2D:
	var pickup := PickupScript.new() as Node2D
	pickup.set_physics_process(false)
	add_child(pickup)
	pickup.call(&"setup", item, amount, cache)
	pickup.global_position = at
	return pickup


func _total(profile: Node) -> int:
	var out := 0
	var items: Dictionary = profile.call(&"cargo_items")
	for quantity: Variant in items.values():
		out += int(quantity)
	return out


func _free_room(profile: Node, hold: int, free: int) -> void:
	if hold <= 0:
		return
	var excess := _total(profile) + free - hold
	if excess <= 0:
		return
	var items: Dictionary = profile.call(&"cargo_items")
	var keys: Array = items.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(items[a]) > int(items[b]))
	var removed := 0
	for key: Variant in keys:
		if removed >= excess:
			break
		var take: int = mini(excess - removed, int(items[key]))
		if bool(profile.call(&"remove_cargo", StringName(key), take)):
			removed += take


func _spawns() -> void:
	print("--- sector spawn counts (all 7 rows, one seed each) ---")
	_check("registry rows", Registry.SECTORS.size() == 7, "rows=%d" % Registry.SECTORS.size())
	for index in Registry.SECTORS.size():
		var row: Dictionary = Registry.SECTORS[index]
		var sector: Node2D = SectorScript.new() as Node2D
		add_child(sector)
		await _step()
		sector.call(&"populate", row, 12345 + index * 7919)
		await _step()
		var fields := int(sector.call(&"field_count"))
		var rocks := 0
		var bad := false
		for field: Node2D in sector.call(&"fields"):
			var count := int(field.call(&"rock_count"))
			rocks += count
			if count < 6 or count > 12:
				bad = true
		var stations := 1 if bool(sector.call(&"has_station")) else 0
		var blips: Array = sector.call(&"blips")
		print("%s fields=%d rocks=%d blips=%d station=%s" % [
			row.get(&"id", &"?"), fields, rocks, blips.size(), bool(sector.call(&"has_station")),
		])
		_check("%s fields 4..8 / rocks 6..12 each" % row.get(&"id", &"?"),
			fields >= 4 and fields <= 8 and not bad, "fields=%d rocks=%d" % [fields, rocks])
		_check("%s blips = fields + station" % row.get(&"id", &"?"),
			blips.size() == fields + stations, "blips=%d" % blips.size())
		sector.queue_free()
		await _step()
	print("--- live game scene ---")
	_game = (load("res://game/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	await _step()
	await _step()
	var sector: Node = _game.get(&"_sector")
	var ship: Node = _game.get(&"_ship")
	_check("game scene boots with a populated sector and a ship",
		sector != null and ship != null and int(sector.call(&"field_count")) >= 4,
		"sector=%s ship=%s" % [sector, ship])


func _seams(profile: Node) -> void:
	print("--- seam 1: cargo fill (profile -> PlayerState.set_cargo_used) ---")
	var state: PlayerState = _game.get(&"_state")
	var hud: Control = _game.get(&"_hud")
	var ship: Node2D = _game.get(&"_ship")
	var footer: Label = hud.find_child("CargoFooterLabel", true, false) as Label
	var active: StringName = profile.call(&"active_ship")
	var hold := int(Catalog.ship(active).get(&"cargo", -1))
	_free_room(profile, hold, 10)
	var before := _total(profile)
	profile.call(&"add_cargo", &"mineral_iron", 3)
	await _step()
	await _step()
	print("profile cargo %d -> %d ; PlayerState.cargo_used=%d ; HUD footer=%s" % [
		before, _total(profile), state.cargo_used, footer.text,
	])
	_check("seam 1: profile cargo reaches PlayerState",
		state.cargo_used == _total(profile),
		"profile=%d state=%d footer=%s" % [_total(profile), state.cargo_used, footer.text])
	var live_before := _total(profile)
	var live: Node2D = PickupScript.new() as Node2D
	live.set_physics_process(false)
	_game.add_child(live)
	live.call(&"setup", &"mineral_iron", 2, false)
	live.global_position = ship.global_position
	live.call(&"_physics_process", 1.0 / 60.0)
	await _step()
	_check("seam 1 (end to end): a collected pickup never moves the HUD readout",
		_total(profile) > live_before and state.cargo_used == 0,
		"profile=%d state=%d" % [_total(profile), state.cargo_used])

	print("--- seam 2: reticle state push ---")
	var pusher := _game.has_method(&"_push_reticle_state") or _game.has_method(&"set_reticle_state")
	var laser: Node2D = ship.get_node_or_null(NodePath("MiningLaser")) as Node2D
	var reticle: Control = hud.get(&"_reticle")
	var state_live := -1
	if laser != null and reticle != null:
		var cursor: Vector2 = laser.get_global_mouse_position()
		var dir: Vector2 = (cursor - laser.global_position).normalized()
		var rock: Node2D = AsteroidScript.new() as Node2D
		_game.add_child(rock)
		rock.call(&"setup", &"iron", 1, 3)
		rock.global_position = laser.global_position + (dir if dir != Vector2.ZERO else Vector2.RIGHT) * 100.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		laser.call(&"set_active", true)
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		state_live = int(reticle.call(&"state"))
		print("laser active=%s has_target=%s ; reticle state=%d (0=PLAIN)" % [
			laser.call(&"is_active"), laser.call(&"has_target"), state_live,
		])
		laser.call(&"set_active", false)
		rock.queue_free()
	_check("seam 2: something pushes the mining reticle state",
		pusher and state_live == 1, "pusher=%s live_state=%d" % [pusher, state_live])

	print("--- seam 3: rock collision ---")
	var collider := PlayerShipScene.instantiate() as Node2D
	var hull_state: PlayerState = PlayerStateScript.new()
	hull_state.setup()
	collider.call(&"setup", ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT), hull_state)
	var obstacle: Node2D = AsteroidScript.new() as Node2D
	add_child(obstacle)
	await _step()
	obstacle.call(&"setup", &"iron", 1, 3)
	obstacle.global_position = Vector2(200.0, 0.0)
	var radius := float(obstacle.call(&"world_radius"))
	Input.action_press(&"thrust_forward")
	for _step_index in 400:
		collider.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(&"thrust_forward")
	var bodies := 0
	for node: Node in _descendants(collider):
		if node is CollisionObject2D:
			bodies += 1
	print("rock radius=%s ; ship end x=%s ; ship collision bodies=%d" % [
		radius, collider.global_position.x, bodies,
	])
	_check("seam 3: the ship is stopped by a rock (section 6)",
		collider.global_position.x < 200.0 + radius and bodies > 0,
		"end x=%s rock near surface=%s bodies=%d" % [
			collider.global_position.x, 200.0 - radius, bodies,
		])
	collider.queue_free()
	obstacle.queue_free()
	await _step()

	print("--- seam 4: PlayerState.damage ---")
	var args := -1
	for entry: Dictionary in PlayerStateScript.new().get_method_list():
		if entry.get("name", "") == "damage":
			args = (entry.get("args", []) as Array).size()
	var probe_state: PlayerState = PlayerStateScript.new()
	probe_state.setup()
	probe_state.set_hull(500.0)
	probe_state.set_shield(100.0)
	probe_state.damage(150.0)
	print("damage() args=%d ; after damage(150) with shield=100: hull=%s shield=%s" % [
		args, probe_state.hull, probe_state.shield,
	])
	_check("seam 4: damage(amount, bypass_shield), shield absorbs first",
		args >= 2 and is_equal_approx(probe_state.shield, 0.0)
			and is_equal_approx(probe_state.hull, 500.0),
		"args=%d hull=%s shield=%s" % [args, probe_state.hull, probe_state.shield])

	print("--- seam 5: REBINDABLE_ACTIONS vs PROJECT_SETTINGS_PATCH section 2 ---")
	var settings := get_tree().root.get_node_or_null(NodePath("SettingsManager"))
	var rebindable := 0
	if settings != null and settings.has_method(&"rebindable_actions"):
		rebindable = settings.call(&"rebindable_actions").size()
	print("rebindable_actions=%d ; InputMap interact=%s warp=%s ; patch lists 17" % [
		rebindable, InputMap.has_action(&"interact"), InputMap.has_action(&"warp"),
	])
	_check("seam 5: REBINDABLE_ACTIONS tracks the 17-action patch",
		rebindable == 17 and InputMap.has_action(&"interact") and InputMap.has_action(&"warp"),
		"rebindable=%d interact=%s warp=%s" % [
			rebindable, InputMap.has_action(&"interact"), InputMap.has_action(&"warp"),
		])

	print("--- the pickup hold source vs ShipStats ---")
	var mismatches := 0
	for hull_id: StringName in ShipFit.HULLS.keys():
		var stats_cargo := int(ShipFit.HULLS[hull_id].get(&"cargo", 0))
		var catalog_cargo := int(Catalog.ship(hull_id).get(&"cargo", -1))
		if catalog_cargo != stats_cargo:
			mismatches += 1
			print("  %s: ShipFit=%d StationCatalog=%s" % [hull_id, stats_cargo, catalog_cargo])
	print("hulls where the two hold sources disagree: %d of %d" % [
		mismatches, ShipFit.HULLS.size(),
	])
	var player_node: Node2D = get_tree().get_first_node_in_group(&"player_ship") as Node2D
	if player_node != null:
		var original: StringName = profile.call(&"active_ship")
		_free_room(profile, 200, 5)
		profile.set(&"_active_ship", &"ship_miner")
		var miner_before := _total(profile)
		var miner_pickup := _spawn_pickup_direct(&"mineral_iron", player_node.global_position)
		for _frame in 5:
			miner_pickup.call(&"_physics_process", 1.0 / 60.0)
		print("active_ship=ship_miner: pickup collected=%s (cargo %d -> %d) ; ShipStats hold=55 StationCatalog=missing" % [
			_total(profile) > miner_before, miner_before, _total(profile),
		])
		profile.set(&"_active_ship", original)
		if is_instance_valid(miner_pickup):
			miner_pickup.queue_free()
	print("--- mining laser vs the fitted w_mining module ---")
	print("standard fit lists w_mining=%s ; ship mounts MiningLaser=%s" % [
		(ShipFit.STANDARD_FIT.get(&"weapons", []) as Array).has(&"w_mining"),
		ship.get_node_or_null(NodePath("MiningLaser")) != null,
	])


func _spawn_pickup_direct(item: StringName, at: Vector2) -> Node2D:
	var pickup := PickupScript.new() as Node2D
	pickup.set_physics_process(false)
	_game.add_child(pickup)
	pickup.call(&"setup", item, 1, false)
	pickup.global_position = at
	return pickup


func _hud_wiring() -> void:
	print("--- HUD wiring in the live game scene ---")
	var hud: Control = _game.get(&"_hud")
	var ship: Node2D = _game.get(&"_ship")
	var prompt: Label = hud.find_child("PromptLabel", true, false) as Label
	var warp_block: Control = hud.find_child("WarpBlock", true, false) as Control
	var away := ship.global_position
	ship.global_position = Vector2(600.0, 420.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var away_visible := prompt.visible
	var away_text := prompt.text
	ship.global_position = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	var inside_visible := prompt.visible
	var inside_text := prompt.text
	print("prompt away [%s '%s'] inside [%s '%s']" % [
		away_visible, away_text, inside_visible, inside_text,
	])
	_check("dock prompt only inside the dock zone",
		not away_visible and away_text == "" and inside_visible and inside_text == "F · DOCK",
		"away [%s '%s'] inside [%s '%s']" % [away_visible, away_text, inside_visible, inside_text])
	ship.global_position = away
	await get_tree().physics_frame
	_game.call(&"_start_warp")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var warp_visible := warp_block.visible
	_game.call(&"_cancel_warp")
	await get_tree().physics_frame
	_check("warp bar shows while channelling and hides on cancel",
		warp_visible and not warp_block.visible,
		"channelling=%s after cancel=%s" % [warp_visible, warp_block.visible])
	var esc := 0
	for label: Node in hud.find_children("*", "Label", true, false):
		if "ESC" in (label as Label).text:
			esc += 1
	_check("the static ESC dock hint is retired", esc == 0, "labels=%d" % esc)
