extends Node
## Engine wave 1, W7 fix probe (throwaway; archived under .agents/gen/ after the run).
## Scene run, not a --script run (game.gd references the Router autoload, which a
## custom main loop cannot resolve). Quits explicitly, so it cannot hang.
##
## Measures the six fixes: H1 (profile cargo -> PlayerState -> HUD), H2 (rock
## collision), H3 (damage bypass_shield + shield absorption), H4 (mining reticle
## state), M1 (one hold source) and M2 (REBINDABLE_ACTIONS). A [FAIL] line means the
## fix did not land.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")
const PickupScript := preload("res://game/pickup.gd")
const Catalog := preload("res://game/station_catalog.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")
const TargetReticleScript := preload("res://ui/hud/target_reticle.gd")

const SCRATCH_PROFILE := "user://_w7_probe_profile.cfg"
const SCRATCH_LOG := "user://_w7_probe_log.txt"

const SHIP_RADIUS := 30.0
const SHIP_GROUP: StringName = &"player_ship"

var _checks := 0
var _fails := 0
var _game: Node = null
var _profile: Node = null
var _cargo_snapshot: Dictionary = {}


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
	_profile = get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	if _profile != null:
		_profile.set(&"save_path", SCRATCH_PROFILE)
		_cargo_snapshot = _profile.call(&"cargo_items")
	EconomyLogScript.log_path = SCRATCH_LOG

	_damage()
	await _collision()
	await _game_scene()
	_restore_cargo()
	_settings()

	print("=== w7 fix probe: checks %d, failures %d ===" % [_checks, _fails])
	## The profile flushes its debounced write at exit, which would recreate the
	## scratch file after this cleanup. Nothing here is worth persisting and the
	## owner's own file was never the write target, so the dirty flag and the
	## debounce are cleared first.
	if _profile != null:
		var timer := _profile.get(&"_save_timer") as Timer
		if timer != null:
			timer.stop()
		_profile.set(&"_dirty", false)
	for path: String in [SCRATCH_PROFILE, SCRATCH_LOG]:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			print("cleanup %s -> error %d" % [absolute, DirAccess.remove_absolute(absolute)])
	get_tree().quit(1 if _fails > 0 else 0)


## H3 - ENGINE_SPEC section 4.2 item 1 / section 15 ("energy is fully absorbed by a
## live shield (no carry-over); kinetic damage ignores shields").
func _damage() -> void:
	print("--- H3: PlayerState.damage(amount, bypass_shield) ---")
	var state: PlayerState = PlayerStateScript.new()
	state.setup()
	var args := -1
	for entry: Dictionary in state.get_method_list():
		if entry.get("name", "") == "damage":
			args = (entry.get("args", []) as Array).size()
	var shields: Array[Vector2] = []
	var hulls: Array[Vector2] = []
	state.shield_changed.connect(func(current: float, maximum: float) -> void:
		shields.append(Vector2(current, maximum)))
	state.hull_changed.connect(func(current: float, maximum: float) -> void:
		hulls.append(Vector2(current, maximum)))

	state.set_hull(500.0)
	state.set_shield(100.0)
	shields.clear()
	hulls.clear()
	state.damage(150.0)
	print("damage() args=%d ; shield 100, damage(150) -> hull=%s shield=%s ; events shield=%d hull=%d" % [
		args, state.hull, state.shield, shields.size(), hulls.size(),
	])
	_check("H3 a: a live shield absorbs, no carry-over",
		args >= 2 and is_equal_approx(state.shield, 0.0) and is_equal_approx(state.hull, 500.0),
		"args=%d hull=%s shield=%s" % [args, state.hull, state.shield])
	_check("H3 a: the absorbed hit is still announced on the HUD channel",
		shields.size() == 1 and hulls.is_empty(),
		"shield events=%d hull events=%d" % [shields.size(), hulls.size()])
	state.damage(50.0)
	_check("H3 b: with the shield down the hull takes it",
		is_equal_approx(state.hull, 450.0) and is_equal_approx(state.shield, 0.0),
		"hull=%s shield=%s" % [state.hull, state.shield])
	state.set_hull(500.0)
	state.set_shield(100.0)
	state.damage(150.0, true)
	_check("H3 c: bypass_shield reaches the hull and leaves the shield",
		is_equal_approx(state.hull, 350.0) and is_equal_approx(state.shield, 100.0),
		"hull=%s shield=%s" % [state.hull, state.shield])
	state.set_hull(500.0)
	state.set_shield(100.0)
	state.damage(40.0)
	_check("H3 d: a partial hit leaves the shield standing, hull untouched",
		is_equal_approx(state.shield, 60.0) and is_equal_approx(state.hull, 500.0),
		"hull=%s shield=%s" % [state.hull, state.shield])
	state.damage(0.0)
	state.damage(-5.0)
	_check("H3 e: a non-positive amount is still a no-op",
		is_equal_approx(state.hull, 500.0) and is_equal_approx(state.shield, 60.0),
		"hull=%s shield=%s" % [state.hull, state.shield])


## H2 - ENGINE_SPEC section 6: "Rocks are solid: ships collide with them".
func _collision() -> void:
	print("--- H2: rock collision on the shipped player_ship.tscn ---")
	var stats: ShipStats = ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT)
	var state: PlayerState = PlayerStateScript.new()
	state.setup()
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	ship.set_physics_process(false)
	ship.call(&"setup", stats, state)
	add_child(ship)
	await get_tree().physics_frame
	var bodies := 0
	for node: Node in _descendants(ship):
		if node is CollisionObject2D:
			bodies += 1
	var body := ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE)) as CharacterBody2D
	var radius := 0.0
	if body != null:
		var shape := body.get_node_or_null(NodePath("Shape")) as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			radius = (shape.shape as CircleShape2D).radius
	print("collision bodies=%d ; body=%s layer=%s mask=%s radius=%s" % [
		bodies, PlayerShipScript.HULL_BODY_NODE,
		body.collision_layer if body != null else -1,
		body.collision_mask if body != null else -1,
		radius,
	])
	_check("H2 a: the ship carries exactly one collision body, on its own layer",
		bodies == 1 and body != null and body.collision_layer == 2 and body.collision_mask == 1,
		"bodies=%d layer=%s mask=%s" % [
			bodies, body.collision_layer if body != null else -1,
			body.collision_mask if body != null else -1,
		])
	_check("H2 b: the body's shape is the hull circle",
		is_equal_approx(radius, SHIP_RADIUS), "radius=%s" % radius)

	var rock: Node2D = AsteroidScript.new() as Node2D
	add_child(rock)
	await _step()
	rock.call(&"setup", &"iron", 1, 3)
	rock.global_position = Vector2(200.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rock_radius := float(rock.call(&"world_radius"))
	Input.action_press(&"thrust_forward")
	for _step_index in 400:
		ship.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(&"thrust_forward")
	var stop_x := ship.global_position.x
	var contact_x := 200.0 - rock_radius - radius
	print("rock radius=%s ; ship stopped at x=%s ; contact at x=%s" % [
		rock_radius, stop_x, contact_x,
	])
	_check("H2 c: the rock stops the ship at the rock's surface",
		stop_x > 50.0 and stop_x <= contact_x + 1.0 and stop_x >= contact_x - 5.0,
		"stopped=%s contact=%s" % [stop_x, contact_x])

	## Negative control: the same thrust, the same rock, a ship that is not in the
	## tree (so its body is not in the physics space) - it must pass straight through,
	## which is what the pre-fix scene did in the live game.
	var ghost_state: PlayerState = PlayerStateScript.new()
	ghost_state.setup()
	var ghost: Node2D = PlayerShipScene.instantiate() as Node2D
	ghost.call(&"setup", stats, ghost_state)
	Input.action_press(&"thrust_forward")
	for _step_index in 400:
		ghost.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(&"thrust_forward")
	print("negative control (not in tree): end x=%s (rock at 200)" % ghost.global_position.x)
	_check("H2 d: without the body in the space the same run passes through",
		ghost.global_position.x > 200.0 + rock_radius, "end x=%s" % ghost.global_position.x)
	ghost.free()
	ship.queue_free()
	rock.queue_free()
	await _step()
	await _spawn_clearance()


## H2's one behavioural risk: now that rocks are solid, a shipped spawn that starts
## inside a rock would wedge the ship. Measured over all seven registry rows.
func _spawn_clearance() -> void:
	print("--- H2 f: the shipped spawns are clear of rocks ---")
	var clearance := INF
	var sectors := 0
	for row: Dictionary in Registry.SECTORS:
		var sector: Node2D = SectorScript.new() as Node2D
		add_child(sector)
		await _step()
		var spawn: Vector2 = sector.call(&"populate", row, 20260918 + sectors * 131)
		await _step()
		var rocks := 0
		for field: Node2D in sector.call(&"fields"):
			for rock: Node2D in field.call(&"rocks"):
				rocks += 1
				clearance = minf(
					clearance,
					spawn.distance_to(rock.global_position) - float(rock.call(&"world_radius")),
				)
		sectors += 1
		print("  %s rocks=%d spawn=%s" % [row.get(&"id", &"?"), rocks, spawn])
		sector.queue_free()
		await _step()
	print("closest rock surface to a spawn across %d sectors: %s u" % [sectors, clearance])
	_check("H2 f: no shipped spawn starts inside a rock",
		clearance > SHIP_RADIUS, "clearance=%s radius=%s" % [clearance, SHIP_RADIUS])


## H1, H4 and the M1 end-to-end cases, on the live flight scene.
func _game_scene() -> void:
	print("--- live game.tscn ---")
	_game = (load("res://game/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	await _step()
	await _step()
	var state: PlayerState = _game.get(&"_state")
	var hud: Control = _game.get(&"_hud")
	var ship: Node2D = _game.get(&"_ship")
	var laser: Node2D = _game.get(&"_laser")
	var reticle: Control = hud.get(&"_reticle")
	var footer: Label = hud.find_child("CargoFooterLabel", true, false) as Label
	var hold := int(ship.call(&"cargo_max"))
	print("ship hold=%d ; PlayerState.cargo_max=%d ; HUD footer=%s ; laser=%s reticle=%s" % [
		hold, state.cargo_max, footer.text, laser, reticle,
	])
	_check("M1 a: the ship's hold, PlayerState and the HUD agree at boot",
		hold == state.cargo_max and hold > 0
			and footer.text == "CARGO %d/%d" % [state.cargo_used, state.cargo_max],
		"hold=%d state=%d footer=%s" % [hold, state.cargo_max, footer.text])

	print("--- H1: profile cargo -> PlayerState -> HUD ---")
	_free_room(hold, 6)
	var total := _total()
	state.set_cargo_used(0)
	_game.call(&"_refresh_hud")
	_check("H1 a: the 0.1 s HUD refresh mirrors the profile manifest",
		state.cargo_used == total and footer.text == "CARGO %d/%d" % [total, state.cargo_max],
		"profile=%d state=%d footer=%s" % [total, state.cargo_used, footer.text])
	_free_room(hold, 3)
	var before := _total()
	_profile.call(&"add_cargo", &"mineral_iron", 3)
	_check("H1 b: a profile cargo change mirrors with no frame in between",
		state.cargo_used == _total() and _total() == before + 3,
		"profile %d -> %d state=%d" % [before, _total(), state.cargo_used])
	_check("H1 c: the cargo readout follows on the same call",
		footer.text == "CARGO %d/%d" % [state.cargo_used, state.cargo_max],
		"footer=%s" % footer.text)
	var filled := _filled_cells(hud)
	print("cargo cells filled=%d of %d" % [filled, state.cargo_max])
	_check("H1 d: the cargo cells fill with the mirrored count",
		filled == state.cargo_used, "filled=%d used=%d" % [filled, state.cargo_used])

	## Headroom first: the owner's profile is live in this process and a parallel editor
	## session may have left it near full, which would make this measure the hold-full
	## gate instead of the collection path.
	_free_room(hold, 5)
	var end_before := _total()
	var live: Node2D = PickupScript.new() as Node2D
	live.set_physics_process(false)
	_game.add_child(live)
	live.call(&"setup", &"mineral_iron", 2, false)
	live.global_position = ship.global_position
	live.call(&"_physics_process", 1.0 / 60.0)
	_check("H1 e: a collected pickup moves the readout immediately",
		_total() == end_before + 2 and state.cargo_used == _total()
			and footer.text == "CARGO %d/%d" % [state.cargo_used, state.cargo_max],
		"profile %d -> %d state=%d footer=%s" % [
			end_before, _total(), state.cargo_used, footer.text,
		])
	if is_instance_valid(live):
		live.queue_free()
	await _step()

	print("--- M1: a hull the station catalogue does not sell still collects ---")
	var missing := 0
	for hull_id: StringName in ShipFit.HULLS.keys():
		if int(Catalog.ship(hull_id).get(&"cargo", -1)) != int(ShipFit.HULLS[hull_id].get(&"cargo", 0)):
			missing += 1
	print("hulls whose ShipFit hold differs from the station catalogue: %d of %d" % [
		missing, ShipFit.HULLS.size(),
	])
	var original: StringName = _profile.call(&"active_ship")
	_profile.set(&"_active_ship", &"ship_miner")
	_free_room(hold, 4)
	var miner_before := _total()
	var miner_pickup := _spawn_pickup(&"mineral_iron", ship.global_position)
	## One step at a time and stop at the first change: a collected pickup is only
	## queued for deletion, so driving on would let the same node collect again.
	for _frame in 5:
		miner_pickup.call(&"_physics_process", 1.0 / 60.0)
		if _total() > miner_before:
			break
	print("active_ship=ship_miner (StationCatalog hold=%s) ; collected=%s (cargo %d -> %d)" % [
		Catalog.ship(&"ship_miner").get(&"cargo", "missing"), _total() == miner_before + 1,
		miner_before, _total(),
	])
	_check("M1 b: the miner hull collects with the catalogue row missing",
		missing > 0 and _total() == miner_before + 1,
		"catalog=%s cargo %d -> %d" % [
			Catalog.ship(&"ship_miner").get(&"cargo", "missing"), miner_before, _total(),
		])
	_profile.set(&"_active_ship", original)
	if is_instance_valid(miner_pickup):
		miner_pickup.queue_free()

	## The fallback reader: a group member with no `cargo_max()` (a probe's stand-in)
	## resolves the hold from ShipFit for the profile's active hull. The live ship is
	## taken out of the group for this one, so the stand-in is the first member.
	var stand_in: Node2D = Node2D.new()
	stand_in.position = Vector2(1000.0, 1000.0)
	add_child(stand_in)
	stand_in.add_to_group(SHIP_GROUP)
	ship.remove_from_group(SHIP_GROUP)
	await _step()
	_free_room(hold, 2)
	var stand_before := _total()
	var stand_pickup := _spawn_pickup(&"mineral_iron", stand_in.global_position + Vector2(10.0, 0.0))
	for _frame in 3:
		stand_pickup.call(&"_physics_process", 1.0 / 60.0)
		if _total() > stand_before:
			break
	var stand_collected := _total() == stand_before + 1
	var fallback_hold := int(stand_pickup.call(&"_ship_hold", stand_in))
	_profile.set(&"_active_ship", &"ship_miner")
	var miner_fallback := int(stand_pickup.call(&"_ship_hold", stand_in))
	_profile.set(&"_active_ship", original)
	ship.add_to_group(SHIP_GROUP)
	print("stand-in hold=%s (ShipFit %s) ; ship_miner stand-in hold=%s (ShipFit %s) ; collected=%s" % [
		fallback_hold, ShipFit.HULLS[original].get(&"cargo"), miner_fallback,
		ShipFit.HULLS[&"ship_miner"].get(&"cargo"), stand_collected,
	])
	_check("M1 c: a stand-in without the accessor falls back to the ShipFit hold",
		stand_collected and fallback_hold == int(ShipFit.HULLS[original].get(&"cargo", 0))
			and miner_fallback == int(ShipFit.HULLS[&"ship_miner"].get(&"cargo", 0)),
		"hold=%d miner=%d collected=%s" % [fallback_hold, miner_fallback, stand_collected])
	stand_pickup.queue_free()
	stand_in.queue_free()
	await _step()

	print("--- M1: the hold-full gate uses that same hold ---")
	_fill_to(hold)
	_game.call(&"_refresh_hud")
	var full_before := _total()
	var full_footer := footer.text
	var full_alert := footer.has_theme_color_override(&"font_color")
	var blocked := _spawn_pickup(&"mineral_iron", ship.global_position + Vector2(30.0, 30.0))
	var blocked_range := blocked.global_position.distance_to(ship.global_position)
	for _frame in 30:
		blocked.call(&"_physics_process", 1.0 / 60.0)
	print("hold=%d fill=%d range=%s ; footer='%s' danger=%s ; blocked pickup position=%s" % [
		hold, full_before, blocked_range, full_footer, full_alert, blocked.global_position,
	])
	_check("M1 d: a full hold leaves an in-range pickup drifting",
		blocked_range <= PickupScript.TRACTOR_RANGE and _total() == full_before
			and blocked.global_position == ship.global_position + Vector2(30.0, 30.0),
		"range=%s fill %d -> %d pos=%s" % [
			blocked_range, full_before, _total(), blocked.global_position,
		])
	_check("H1 f: the hold-full HUD state is live at the same fill",
		full_footer == "CARGO %d/%d" % [hold, hold] and full_alert,
		"footer='%s' danger=%s" % [full_footer, full_alert])
	blocked.queue_free()
	await _step()
	_empty_hold()
	_game.call(&"_refresh_hud")
	_check("H1 f: emptying the hold clears the alert again",
		not footer.has_theme_color_override(&"font_color"),
		"footer='%s'" % footer.text)

	print("--- H2 e: what the ship's mask can see in the live scene ---")
	var rocks := 0
	var non_rocks := 0
	var areas := 0
	for node: Node in _descendants(_game):
		var collider := node as CollisionObject2D
		if collider == null or collider.collision_layer != 1:
			continue
		if collider is Area2D:
			areas += 1
		elif collider.is_in_group(AsteroidScript.ROCK_GROUP):
			rocks += 1
		else:
			non_rocks += 1
	print("layer-1 objects in the live scene: %d rock bodies, %d other bodies, %d areas" % [
		rocks, non_rocks, areas,
	])
	_check("H2 e: every physics body on the rock layer is an asteroid",
		rocks > 0 and non_rocks == 0, "rocks=%d other=%d areas=%d" % [rocks, non_rocks, areas])

	print("--- H4: the mining reticle state ---")
	var state_rest := int(reticle.call(&"state"))
	var rock: Node2D = AsteroidScript.new() as Node2D
	_game.add_child(rock)
	await _step()
	rock.call(&"setup", &"iron", 1, 3)
	var cursor: Vector2 = laser.get_global_mouse_position()
	var direction := cursor - laser.global_position
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	rock.global_position = laser.global_position + direction.normalized() * 100.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	laser.call(&"set_active", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var in_range := int(reticle.call(&"state"))
	var acquired := bool(laser.call(&"has_target"))
	print("reticle at rest=%d ; laser active=%s has_target=%s -> state=%d (1=IN_RANGE)" % [
		state_rest, laser.call(&"is_active"), acquired, in_range,
	])
	_check("H4 a: an active beam with a rock under the cursor reads IN_RANGE",
		state_rest == TargetReticleScript.State.PLAIN and acquired
			and in_range == TargetReticleScript.State.IN_RANGE,
		"rest=%d acquired=%s state=%d" % [state_rest, acquired, in_range])
	rock.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var out_of_range := int(reticle.call(&"state"))
	print("laser active, no rock -> has_target=%s state=%d (2=OUT_OF_RANGE)" % [
		laser.call(&"has_target"), out_of_range,
	])
	_check("H4 b: an active beam with nothing under it reads OUT_OF_RANGE",
		out_of_range == TargetReticleScript.State.OUT_OF_RANGE, "state=%d" % out_of_range)
	laser.call(&"set_active", false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var released := int(reticle.call(&"state"))
	_check("H4 c: releasing the trigger returns the reticle to PLAIN",
		released == TargetReticleScript.State.PLAIN, "state=%d" % released)

	print("--- the input guards hold with interact/warp still unapplied ---")
	var prompt: Label = hud.find_child("PromptLabel", true, false) as Label
	var away := ship.global_position
	ship.global_position = away + Vector2(900.0, 900.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var away_visible := prompt.visible
	ship.global_position = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("dock prompt away [%s] inside [%s '%s'] ; interact=%s warp=%s" % [
		away_visible, prompt.visible, prompt.text,
		InputMap.has_action(&"interact"), InputMap.has_action(&"warp"),
	])
	_check("the dock prompt still works while the actions are unapplied",
		not away_visible and prompt.visible and prompt.text == "F · DOCK",
		"away=%s inside=[%s '%s']" % [away_visible, prompt.visible, prompt.text])
	ship.global_position = away
	await get_tree().physics_frame


## M2 - the code half: the const tracks PROJECT_SETTINGS_PATCH section 2's 17 rows.
func _settings() -> void:
	print("--- M2: SettingsManager.REBINDABLE_ACTIONS ---")
	var settings := get_tree().root.get_node_or_null(NodePath("SettingsManager"))
	if settings == null:
		_check("M2 a: SettingsManager is available", false, "autoload missing")
		return
	var actions: Array = settings.call(&"rebindable_actions")
	var expected: Array[StringName] = [
		&"thrust_forward", &"thrust_backward", &"turn_left", &"turn_right",
		&"fire_primary", &"fire_secondary", &"mine", &"boost", &"cargo_toggle",
		&"weapon_1", &"weapon_2", &"weapon_3", &"weapon_4", &"weapon_5",
		&"target_next", &"interact", &"warp",
	]
	var same := actions.size() == expected.size()
	if same:
		for index in expected.size():
			if StringName(actions[index]) != expected[index]:
				same = false
				break
	var tail: Array = []
	if actions.size() >= 17:
		tail = [actions[15], actions[16]]
	print("rebindable_actions=%d ; tail=%s ; binding_text(interact,0)='%s'" % [
		actions.size(), tail, settings.call(&"binding_text", &"interact", 0),
	])
	_check("M2 a: exactly 17 actions in the patch order", same, "size=%d" % actions.size())
	_check("M2 b: the two new rows read as unbound while the map lacks them",
		String(settings.call(&"binding_text", &"interact", 0)).is_empty()
			and String(settings.call(&"binding_text", &"warp", 0)).is_empty()
			and not InputMap.has_action(&"interact") and not InputMap.has_action(&"warp"),
		"interact=%s warp=%s" % [
			InputMap.has_action(&"interact"), InputMap.has_action(&"warp"),
		])


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out


func _filled_cells(hud: Control) -> int:
	var filled := 0
	var cells: Array = hud.get(&"_cargo_cells")
	for cell: Node in cells:
		if StringName(cell.get(&"_icon_token")) == &"text_primary":
			filled += 1
	return filled


func _total() -> int:
	var out := 0
	var items: Dictionary = _profile.call(&"cargo_items")
	for quantity: Variant in items.values():
		out += int(quantity)
	return out


func _spawn_pickup(item: StringName, at: Vector2) -> Node2D:
	var pickup := PickupScript.new() as Node2D
	pickup.set_physics_process(false)
	add_child(pickup)
	pickup.call(&"setup", item, 1, false)
	pickup.global_position = at
	return pickup


func _free_room(hold: int, free: int) -> void:
	var excess := _total() + free - hold
	if excess <= 0:
		return
	var items: Dictionary = _profile.call(&"cargo_items")
	var keys: Array = items.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(items[a]) > int(items[b]))
	var removed := 0
	for key: Variant in keys:
		if removed >= excess:
			break
		var take: int = mini(excess - removed, int(items[key]))
		if bool(_profile.call(&"remove_cargo", StringName(key), take)):
			removed += take


func _fill_to(hold: int) -> void:
	var shortfall := hold - _total()
	if shortfall > 0:
		_profile.call(&"add_cargo", &"mineral_iron", shortfall)


func _empty_hold() -> void:
	var items: Dictionary = _profile.call(&"cargo_items")
	for key: Variant in items.keys():
		_profile.call(&"remove_cargo", StringName(key), int(items[key]))


## Leaves the in-memory manifest exactly as the owner's profile had it. The scratch
## save_path means nothing was ever written to user://profile.cfg either way.
func _restore_cargo() -> void:
	if _profile == null:
		return
	_empty_hold()
	for key: Variant in _cargo_snapshot.keys():
		_profile.call(&"add_cargo", StringName(key), int(_cargo_snapshot[key]))
	print("profile cargo restored: %d units in %d stacks" % [
		_total(), int(_cargo_snapshot.size()),
	])
