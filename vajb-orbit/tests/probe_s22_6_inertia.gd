extends Node2D
## S22.6 evidence probe: the inertia tick measured on real frames, headless.
##
## The suite (`tests/test_s22_6_inertia.gd`) pins the law and the arithmetic; this probe
## asks the physics server what the shipped bodies actually do, so the report's before/after
## table is a measurement and not a re-derivation. Two kinds of body, per the wave's two
## rows:
##   * the shipped `PlayerShip` (its `HullBody`), ramped to cruise and released -- the hull
##     release coast (18 §13's Hull release coast row);
##   * a real `AsteroidField` rock, a real cleave child and a real splinter -- the rock
##     drift damping row.
##
## Run (bounded, headless, no editor):
##   godot --headless --path vajb-orbit res://tests/probe_s22_6_inertia.tscn \
##     --fixed-fps 60 --quit-after 6000
##
## `--fixed-fps 60` disables real-time synchronisation (the S2.6 probe's convention), so one
## main-loop iteration is exactly one 1/60 s physics step and every sample grid is
## reproducible. The probe self-quits and prints `[S226I] done`; `--quit-after` is the
## watchdog and every loop carries its own hard iteration bound (L82).
##
## Cases, one `[S226I] <case>` line per reading:
##   `constants`     -- the wave's constants as the tree carries them
##   `coast`         -- throttle held to cruise, then released: t_10, dist_10, t_stop
##   `release200`    -- a Vanguard handed 200 u/s at zero throttle: the AC1 second reading
##   `rock_rest`     -- a field rock at rest for 6 s: displacement and final speed
##   `rock_kick`     -- a field rock at the fragment kick's 150 u/s: speed at 1 s, carry
##   `rock_child`    -- a real cleave child at its born kick: speed at 1 s, carry
##   `rock_ram`      -- the worst ram's 409 u/s hand-off, shipped damp against the
##                      superseded 3.71: the carried distance before/after
##   `done`

const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")

const TAG := "[S226I]"
const THRUST: StringName = &"thrust_forward"
const HULLS: Array[StringName] = [&"ship_vanguard", &"ship_fighter"]
const AIM_DISTANCE := 4000.0

## The ACs' own readings: the fragment kick, the ram hand-off, the superseded ceiling
## (`AsteroidScript.DRIFT_SPEED_CEILING` is still 10 u/s in the file as the superseded
## target, so the probe reads it rather than repeating it), the hull's 200 u/s release.
const KICK_SPEED := 150.0
const RAM_HANDOFF_SPEED := 409.0
const SIGNAL_SPEED := 200.0
## 18 §13's Rock drift row: "Supersedes the 3.71 derived for DRIFT_SPEED_CEILING". The
## before-row is the superseded constant, written here as the row's own reference.
const SUPERSEDED_LINEAR_DAMP := 3.71
## A rock is a fixed point of the damp law; the AC4 rest window is 5 s, measured over 6.
const REST_SECONDS := 6.0
## "Settled": the superseded ceiling (the file's own target) and a near-zero tail.
const SETTLE_FLOOR := 0.5
const SAMPLES_PER_SECOND := 60
const CRUISE_TOLERANCE := 1e-4

var _field_node: Node2D = null
var _rocks: Array[Node2D] = []
var _ships: Array[Node] = []


func _ready() -> void:
	await get_tree().physics_frame
	_print_constants()
	for hull_id: StringName in HULLS:
		await _case_coast(hull_id)
	await _case_release_200()
	await _case_rock_rest()
	await _case_rock_kick()
	await _case_rock_child()
	await _case_rock_ram()
	_free_ships()
	print("%s done" % TAG)
	get_tree().quit(0)


## The wave's constants, read through the scripts' own constant maps so a pre-change tree
## prints `absent` instead of refusing.
func _print_constants() -> void:
	print(
		"%s constants coast_mult=%s linear_damp=%s fragment_damp=%s ceiling=%s outward_kick=%s"
		% [
			TAG,
			_constant(ShipFitScript, &"COAST_TIME_MULT"),
			_constant(AsteroidScript, &"LINEAR_DAMP"),
			_constant(AsteroidScript, &"FRAGMENT_LINEAR_DAMP"),
			_constant(AsteroidScript, &"DRIFT_SPEED_CEILING"),
			_constant(FieldScript, &"FRAGMENT_OUTWARD_KICK"),
		]
	)


func _constant(script: GDScript, name: StringName) -> String:
	var map: Dictionary = script.get_script_constant_map()
	if not map.has(name):
		return "absent"
	return "%.4f" % float(map[name])


## ---------------------------------------------------------------------------
## 1. The hull release coast (18 §13's Hull release coast row)
## ---------------------------------------------------------------------------


## Hold the throttle with the aim pinned dead ahead until the hull reaches its own
## `max_speed`, release, and measure the coast envelope against the class's own coast_time.
func _case_coast(hull_id: StringName) -> void:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("%s note case=coast_%s the hull fixture did not build" % [TAG, hull_id])
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	var cruise := float(stats.max_speed)
	var budget := int(60.0 * (float(stats.accel_time) * 2.0 + 1.0))
	Input.action_press(THRUST)
	var cruised := false
	var release_velocity := Vector2.ZERO
	var released_at := Vector2.ZERO
	for _i: int in range(budget):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		if body.linear_velocity.length() >= cruise * (1.0 - CRUISE_TOLERANCE):
			cruised = true
			release_velocity = body.linear_velocity
			break
	Input.action_release(THRUST)
	if not cruised:
		print("%s note case=coast_%s never reached %.3f u/s" % [TAG, hull_id, cruise])
		return
	released_at = body.global_position
	var v_release := release_velocity.length()
	var heading := release_velocity.normalized()
	var envelope := await _coast_envelope(ship, body, heading, v_release, float(stats.coast_time))
	var carried := (body.global_position - released_at).length()
	print(
		(
			"%s coast hull=%s v_release=%.3f coast_time=%.3f derived_t_10=%.3f t_10=%.3f "
			+ "dist_10=%.2f t_stop=%.3f carried=%.2f derived_carry=%.2f"
		)
		% [
			TAG,
			hull_id,
			v_release,
			float(stats.coast_time),
			0.9 * v_release / (cruise / float(stats.coast_time)),
			envelope[&"t_10"],
			envelope[&"dist_10"],
			envelope[&"t_stop"],
			carried,
			0.5 * v_release * float(stats.coast_time),
		]
	)


## A released Vanguard handed 200 u/s with no command held: the release law brakes the whole
## velocity, so this is the AC1 second reading (S22 measured 1.150 s at the 2.5 constant).
func _case_release_200() -> void:
	var launched := _launch(&"ship_vanguard")
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("%s note case=release200 the hull fixture did not build" % TAG)
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	body.linear_velocity = Vector2(SIGNAL_SPEED, 0.0)
	var envelope := await _coast_envelope(ship, body, Vector2.RIGHT, SIGNAL_SPEED, float(stats.coast_time))
	print(
		"%s release200 hull=ship_vanguard v0=%.1f coast_time=%.3f derived_t_10=%.3f t_10=%.3f dist_10=%.2f t_stop=%.3f"
		% [
			TAG,
			SIGNAL_SPEED,
			float(stats.coast_time),
			0.9 * SIGNAL_SPEED / (float(stats.max_speed) / float(stats.coast_time)),
			envelope[&"t_10"],
			envelope[&"dist_10"],
			envelope[&"t_stop"],
		]
	)


## Sample the release frame by frame until the hull is stopped. Returns t_10 (speed at a
## tenth of the release), dist_10, t_stop (speed at the settle floor) and the last speed.
func _coast_envelope(
	ship: Variant, body: RigidBody2D, heading: Vector2, v_release: float, coast_time: float
) -> Dictionary:
	var budget := int(60.0 * (coast_time * 3.0 + 1.0))
	var elapsed := 0.0
	var start := body.global_position
	var t_10 := -1.0
	var dist_10 := -1.0
	var t_stop := -1.0
	var last := v_release
	for _i: int in range(budget):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
		last = body.linear_velocity.length()
		var dist := (body.global_position - start).length()
		if t_10 < 0.0 and last <= 0.1 * v_release:
			t_10 = elapsed
			dist_10 = dist
		if last <= SETTLE_FLOOR:
			t_stop = elapsed
			break
	return {
		&"t_10": t_10,
		&"dist_10": dist_10,
		&"t_stop": t_stop,
		&"last": last,
	}


## ---------------------------------------------------------------------------
## 2. The rock drift damping (18 §13's Rock drift damping row)
## ---------------------------------------------------------------------------


## AC4, first half: a field rock at rest must stay at rest -- no gravity, no drift.
func _case_rock_rest() -> void:
	var rock := _spawn_rock(&"Rest", AsteroidScript.SIZE_MEDIUM, 2)
	if rock == null:
		return
	rock.global_position = Vector2(4000.0, 0.0)
	var start: Vector2 = rock.global_position
	var budget := int(REST_SECONDS * SAMPLES_PER_SECOND)
	for _i: int in range(budget):
		await get_tree().physics_frame
	print(
		"%s rock_rest damp=%.4f seconds=%.1f moved=%.6f final_speed=%.6f"
		% [TAG, rock.linear_damp, REST_SECONDS, (rock.global_position - start).length(), rock.linear_velocity.length()]
	)


## AC3: a real field rock handed the fragment kick's 150 u/s.
func _case_rock_kick() -> void:
	var rock := _spawn_rock(&"Kick", AsteroidScript.SIZE_MEDIUM, 2)
	if rock == null:
		return
	rock.global_position = Vector2(4000.0, 600.0)
	rock.linear_velocity = Vector2(KICK_SPEED, 0.0)
	var envelope := await _drift_envelope(rock)
	print(
		(
			"%s rock_kick damp=%.4f v0=%.1f speed_1s=%.3f carry_10=%.2f t_10=%.3f "
			+ "carry_total=%.2f t_stop=%.3f"
		)
		% [
			TAG,
			rock.linear_damp,
			KICK_SPEED,
			envelope[&"speed_1s"],
			envelope[&"carry_10"],
			envelope[&"t_10"],
			envelope[&"carry_total"],
			envelope[&"t_stop"],
		]
	)


## AC3: a real cleave child -- born of the field's own `_cleave` with the outward kick on it
## -- measured from its birth frame. Its born speed is the fragment kick along the radial:
## the parent is at rest, so the inherit half of `eject_velocity()` is zero.
func _case_rock_child() -> void:
	var field := _field()
	if field == null:
		return
	var parent := _spawn_rock(&"Cleave", AsteroidScript.SIZE_LARGE, 4)
	if parent == null:
		return
	parent.global_position = Vector2(4000.0, 1200.0)
	var before: Array[Node2D] = (field.call(&"rocks") as Array[Node2D]).duplicate()
	parent.call(&"apply_work", 9999.0)
	var child: RigidBody2D = null
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(candidate) and candidate is RigidBody2D and _live(candidate):
			child = candidate as RigidBody2D
			break
	if child == null:
		print("%s note case=rock_child the cleave produced no child" % TAG)
		return
	var v0 := child.linear_velocity.length()
	var envelope := await _drift_envelope(child)
	print(
		(
			"%s rock_child damp=%.4f v0=%.3f speed_1s=%.3f carry_10=%.2f t_10=%.3f "
			+ "carry_total=%.2f t_stop=%.3f"
		)
		% [
			TAG,
			child.linear_damp,
			v0,
			envelope[&"speed_1s"],
			envelope[&"carry_10"],
			envelope[&"t_10"],
			envelope[&"carry_total"],
			envelope[&"t_stop"],
		]
	)


## AC4, second half: the worst ram's 409 u/s hand-off, shipped damp against the superseded
## 3.71 -- the before/after carried distance. The hand-off itself is unchanged (rule 4).
func _case_rock_ram() -> void:
	for damp: float in [AsteroidScript.LINEAR_DAMP, SUPERSEDED_LINEAR_DAMP]:
		var label := "shipped" if is_equal_approx(damp, AsteroidScript.LINEAR_DAMP) else "superseded"
		var rock := _spawn_rock("Ram_%s" % label, AsteroidScript.SIZE_MEDIUM, 2)
		if rock == null:
			continue
		rock.linear_damp = damp
		rock.global_position = Vector2(4000.0, 1800.0 + 600.0 * float(_rocks.size()))
		rock.linear_velocity = Vector2(RAM_HANDOFF_SPEED, 0.0)
		var envelope := await _drift_envelope(rock)
		print(
			"%s rock_ram row=%s damp=%.4f v0=%.1f speed_1s=%.3f carry_10=%.2f t_10=%.3f carry_total=%.2f"
			% [
				TAG,
				label,
				damp,
				RAM_HANDOFF_SPEED,
				envelope[&"speed_1s"],
				envelope[&"carry_10"],
				envelope[&"t_10"],
				envelope[&"carry_total"],
			]
		)


## Frame-by-frame drift of one rock: its speed at one second, the carried distance until the
## superseded 10 u/s ceiling and until the settle floor, and the total carry.
func _drift_envelope(rock: RigidBody2D) -> Dictionary:
	var start: Vector2 = rock.global_position
	var budget := int(SAMPLES_PER_SECOND * 60.0)
	var elapsed := 0.0
	var speed_1s := -1.0
	var t_10 := -1.0
	var carry_10 := -1.0
	var t_stop := -1.0
	for _i: int in range(budget):
		await get_tree().physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
		var speed := rock.linear_velocity.length()
		if speed_1s < 0.0 and elapsed >= 1.0:
			speed_1s = speed
		if t_10 < 0.0 and speed <= float(AsteroidScript.DRIFT_SPEED_CEILING):
			t_10 = elapsed
			carry_10 = (rock.global_position - start).length()
		if speed <= SETTLE_FLOOR:
			t_stop = elapsed
			break
	return {
		&"speed_1s": speed_1s,
		&"t_10": t_10,
		&"carry_10": carry_10,
		&"carry_total": (rock.global_position - start).length(),
		&"t_stop": t_stop,
	}


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A rock of the field's own construction path (the shipped `_new_rock`), parented to the
## field so the cleave/splinter paths resolve exactly as in a sector.
func _spawn_rock(node_name: String, size_class: int, units: int) -> RigidBody2D:
	var field := _field()
	if field == null:
		return null
	var rock: RigidBody2D = field.call(
		&"_new_rock", node_name, &"iron", 1, units, size_class
	)
	_rocks.append(rock)
	return rock


## A rock that outlived the frame it was born on (a fragment freed by its own cascade).
func _live(rock: Node2D) -> bool:
	return is_instance_valid(rock) and not rock.is_queued_for_deletion()


func _field() -> Node2D:
	if _field_node == null:
		_field_node = FieldScript.new() as Node2D
		_field_node.name = "ProbeField"
		add_child(_field_node)
		_field_node.call(&"setup", {&"rocks": 1, &"seed": 20260930})
		## The generation rocks are measured by the suite; here only the fixtures are.
		for generated: Node2D in _field_node.call(&"rocks") as Array[Node2D]:
			generated.free()
	return _field_node


func _launch(hull_id: StringName) -> Array:
	var stats: Variant = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
	if stats == null:
		return [null, null]
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship: Variant = PlayerShipScene.instantiate()
	if ship == null:
		return [null, null]
	add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.global_rotation = 0.0
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_ships.append(ship)
	return [ship, stats]


## The aim pinned dead ahead each frame: the cursor route then commands no turn, so the
## release is the pure coast the row names.
func _pin_aim(ship: Variant, body: RigidBody2D) -> void:
	ship.call(
		&"set_aim_point",
		ship.global_position + Vector2.RIGHT.rotated(float(body.global_rotation)) * AIM_DISTANCE
	)


func _free_ships() -> void:
	for ship: Node in _ships:
		if is_instance_valid(ship) and not ship.is_queued_for_deletion():
			var parent := ship.get_parent()
			if parent != null:
				parent.remove_child(ship)
			ship.free()
	_ships.clear()
