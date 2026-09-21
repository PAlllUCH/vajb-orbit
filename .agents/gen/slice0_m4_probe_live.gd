extends Node
## slice-0 M4 review probe B: the shipped hull's live physics - the flat-wall
## collision figure and, above all, whether the reactor chain is actually wired into
## the flight (ruling 14's Emergency Flight Mode and section 4.4's burn/refill).
##
## Input is driven through Input.action_press, which headless honours, so the probe
## presses the real thrust/boost actions the hull reads rather than calling a private
## method. Scene run (a --script main loop cannot step a RigidBody2D).
##
## Re-run:
##   "..._console.exe" --headless --path <proj> res://tools/_probe_s0m4_live.tscn --quit-after 2400

const PlayerShipScene := preload("res://game/player_ship.tscn")
const StateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const HULL_ID: StringName = &"ship_fighter"
const WALL_X := 700.0
const WALL_HALF := 10.0
const SHIP_RADIUS := 30.0
const IMPACT_SPEED := 450.0
const BOOST_FIT := {
	&"engine": &"e_std",
	&"power": &"p_std",
	&"weapons": [&"w_mining"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
	&"computers": [],
	&"boosters": [&"b_afterburner"],
	&"utility": [],
}

var _ok := 0
var _failed := 0
var _state: PlayerState = null
var _ship: Node2D = null
var _damage_events: Array[float] = []


func _ready() -> void:
	_watchdog()
	_run()


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	print("WATCHDOG: probe did not finish")
	get_tree().quit(2)


func _check(label: String, passed: bool, detail: String) -> void:
	if passed:
		_ok += 1
		print("[OK]   %s | %s" % [label, detail])
	else:
		_failed += 1
		print("[FAIL] %s | %s" % [label, detail])


func _ticks(seconds: float) -> void:
	for _i in int(round(seconds * float(Engine.physics_ticks_per_second))):
		await get_tree().physics_frame


func _body() -> RigidBody2D:
	return _ship.call(&"impact_body") as RigidBody2D


func _speed() -> float:
	var body := _body()
	return body.linear_velocity.dot(Vector2.RIGHT.rotated(body.global_rotation))


func _place(pos: Vector2) -> void:
	var body := _body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.global_position = pos
	body.global_rotation = 0.0
	_ship.call(&"cancel_orders")
	await get_tree().physics_frame


func _release_all() -> void:
	for action: StringName in [&"thrust_forward", &"thrust_backward", &"turn_left",
		&"turn_right", &"boost", &"mine"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _run() -> void:
	print("=== slice0 M4 probe B: live hull, collision, reactor wiring ===")
	var world := Node2D.new()
	add_child(world)
	_ship = PlayerShipScene.instantiate()
	world.add_child(_ship)
	var fit_ids: Array[StringName] = ShipFitScript.fitted_ids(BOOST_FIT)
	var stats: ShipStats = ShipFitScript.resolve(HULL_ID, BOOST_FIT)
	_state = StateScript.new()
	_state.hull_max = stats.hull_max
	_state.shield_max = stats.shield_max
	_state.cargo_max = stats.cargo_max
	_state.setup()
	_ship.call(&"setup", stats, _state, fit_ids)
	_ship.connect(&"damage_taken", func(amount: float) -> void: _damage_events.append(amount))
	await _ticks(0.2)
	_check("setup: the shipped hull flies with the resolved snapshot",
		stats != null and stats.hull_mass == 80.0 and is_equal_approx(stats.max_speed, 427.5),
		"mass=%s max_speed=%s" % [stats.hull_mass, stats.max_speed])

	await _report_flight()
	await _report_collision()
	await _report_reactor()
	_release_all()
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## The brief's flight acceptance, re-measured on the review's own probe.
func _report_flight() -> void:
	await _place(Vector2(0.0, 0.0))
	Input.action_press(&"thrust_forward", 1.0)
	var reached := 0.0
	var reached_at := 0.0
	var elapsed := 0.0
	var max_seen := 0.0
	while elapsed < 4.0:
		await get_tree().physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
		var v := _speed()
		max_seen = maxf(max_seen, v)
		if reached == 0.0 and v >= 0.99 * 427.5:
			reached = v
			reached_at = elapsed
	Input.action_release(&"thrust_forward")
	_check("flight: throttle reaches the class max speed within accel_time (+-10 %)",
		reached_at > 0.0 and reached_at <= 2.0 * 1.1,
		"reached %s u/s at t=%s s (class accel_time 2.0 s, peak %s)" % [reached, reached_at, max_seen])
	await _ticks(0.1)
	var holding := _speed()
	_check("flight: it holds the maximum rather than sailing past it",
		holding <= 450.0, "%s u/s (want <= 450)" % holding)
	## Autopilot: a move order 400 u ahead arrives inside ARRIVE_RADIUS.
	await _place(Vector2(0.0, 0.0))
	_ship.call(&"set_move_target", Vector2(400.0, 0.0))
	var closest := 100000.0
	elapsed = 0.0
	while elapsed < 8.0:
		await get_tree().physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
		closest = minf(closest, _ship.global_position.distance_to(Vector2(400.0, 0.0)))
		if closest <= 40.0:
			break
	_check("flight: the autopilot arrives inside ARRIVE_RADIUS",
		closest <= 40.0, "closest %s u (radius 40)" % closest)


## Section 16's worked example, live on the shipped scene: a 450 u/s flat-wall hit.
func _report_collision() -> void:
	var wall := StaticBody2D.new()
	## Layer 1 is the rock layer the hull's own mask watches (player_ship.tscn:
	## layer 2 / mask 1), so the pair collides from the ship's side.
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_HALF * 2.0, 400.0)
	shape.shape = rect
	wall.add_child(shape)
	wall.global_position = Vector2(WALL_X, 0.0)
	add_child(wall)
	await _place(Vector2(WALL_X - WALL_HALF - SHIP_RADIUS - 40.0, 0.0))
	_state.set_shield(0.0)
	var hull_before := _state.hull
	_damage_events.clear()
	var approach := 0.0
	_body().linear_velocity = Vector2(IMPACT_SPEED, 0.0)
	var waited := 0.0
	while _damage_events.is_empty() and waited < 2.0:
		approach = _speed()
		await get_tree().physics_frame
		waited += 1.0 / float(Engine.physics_ticks_per_second)
	var dealt := hull_before - _state.hull
	var want := 0.5 * 80.0 * approach * approach * 2.0e-5
	_check("collision: a flat-wall hit at the measured speed deals the reduced-mass figure",
		not _damage_events.is_empty() and absf(dealt - want) <= 0.1 * want,
		"approach %s u/s -> hull %s -> %s (dealt %s, formula %s, section 16 wants 162 at 450)"
		% [approach, hull_before, _state.hull, dealt, want])
	var reported := _damage_events[0] if not _damage_events.is_empty() else -1.0
	_check("collision: damage_taken reports the same amount",
		is_equal_approx(reported, dealt), "signal=%s hull delta=%s" % [reported, dealt])
	wall.queue_free()
	await _ticks(0.1)


## The reactor chain in the shipped game: does anything burn the tank, lock the
## controls at fuel 0, or refill the buffer?
func _report_reactor() -> void:
	await _place(Vector2(0.0, 0.0))
	## (1) Thrust under Emergency Flight Mode (ruling 14: thrust is ignored).
	_state.set_fuel(0.0)
	var start := _state.fuel
	Input.action_press(&"thrust_forward", 1.0)
	await _ticks(1.0)
	var gained := absf(_speed())
	Input.action_release(&"thrust_forward")
	_check("emergency: at fuel 0 the hull ignores thrust (ruling 14)",
		gained < 1.0, "fuel=%s, speed after 1 s of full throttle = %s u/s (want 0)" % [start, gained])

	## (2) Boost under Emergency Flight Mode: locked out, and it must not burn a tank
	##     that has nothing in it.
	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	_ship.set(&"_boost_remaining", 0.0)
	_ship.set(&"_boost_cooldown", 0.0)
	Input.action_press(&"boost", 1.0)
	await _ticks(0.5)
	var engaged_at_zero := float(_ship.get(&"_boost_remaining"))
	Input.action_release(&"boost")
	_check("emergency: at fuel 0 the afterburner is locked out (ruling 14)",
		engaged_at_zero <= 0.0,
		"boost_remaining=%s s after pressing boost with an empty tank" % engaged_at_zero)

	## (3) Boost with a full tank: section 13 says the afterburner burns 3.0 Fuel/s.
	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(200.0)
	_ship.set(&"_boost_remaining", 0.0)
	_ship.set(&"_boost_cooldown", 0.0)
	var fuel_before := _state.fuel
	Input.action_press(&"boost", 1.0)
	await _ticks(1.0)
	Input.action_release(&"boost")
	var burned := fuel_before - _state.fuel
	_check("boost: a second of afterburner burns BOOST_FUEL 3.0 (section 13)",
		is_equal_approx(burned, 3.0),
		"fuel %s -> %s (burned %s, spec 3.0)" % [fuel_before, _state.fuel, burned])
	_check("boost: the afterburner itself did engage (the burn is the only thing missing)",
		float(_ship.get(&"_boost_remaining")) > 0.0 or burned > 0.0,
		"boost_remaining=%s" % _ship.get(&"_boost_remaining"))

	## (4) The reactor refill: spend 10 Energy, then let a second of physics run.
	##     section 4.4: the reactor refills at energy_regen (5/s) once energy is spent.
	_state.set_energy(_state.energy_max)
	_state.set_fuel(200.0)
	var energy_before := _state.energy
	var toll_before := _state.fuel
	_state.try_spend_energy(10.0)
	var after_spend := _state.energy
	_check("reactor: spending 10 Energy burns FUEL_PER_ENERGY 0.10 per point",
		is_equal_approx(toll_before - _state.fuel, 1.0),
		"fuel %s -> %s while energy %s -> %s" % [toll_before, _state.fuel,
		energy_before, after_spend])
	await _ticks(1.0)
	var refill := _state.energy - after_spend
	_check("reactor: a spent buffer refills at energy_regen 5/s in the shipped hull",
		is_equal_approx(refill, 5.0),
		"energy %s -> %s after 1 s (refill %s, spec 5.0; reactor_efficiency %s)"
		% [after_spend, _state.energy, refill, _state.reactor_efficiency()])

	## (5) Section 11's `consume_fuel_cell` = C, the only door to the fuel cell.
	_check("input: the consume_fuel_cell action (C) exists in the input map (section 11)",
		InputMap.has_action(&"consume_fuel_cell"),
		"InputMap.has_action('consume_fuel_cell') = %s"
		% InputMap.has_action(&"consume_fuel_cell"))
