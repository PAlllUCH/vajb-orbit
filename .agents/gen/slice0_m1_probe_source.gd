extends Node
## Slice 0, M1 probe (throwaway; its source is archived under .agents/gen/ after the
## run and can be dropped back into res://tools/ to re-measure).
## Scene run, not a --script run: a custom main loop cannot resolve autoloads, and the
## flown hull is a real RigidBody2D that only the engine's own physics step moves.
## Quits explicitly and carries a watchdog, so it cannot hang.
##
## Measures M1's acceptance from the slice-0 brief: throttle reaches the section 13
## max speed within accel_time +-10 %, coast decay lands within coast_time, the brake
## stops shorter than a coast, the autopilot arrives inside ARRIVE_RADIUS, a 450 u/s
## flat-wall impact deals 162 +-10 % hull damage (the section 16 worked example) and a
## shot's recoil pushes the hull back. A [FAIL] line means the acceptance did not land.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ImpactScript := preload("res://game/impact.gd")

const HULL_ID: StringName = &"ship_fighter"
const WALL_X := 700.0
const WALL_HALF := 10.0
const SHIP_RADIUS := 30.0
const FIGHTER_MASS := 80.0
const RECOIL_MASS := 1.0
const RECOIL_SPEED := 1000.0
const PROBE_MASS := 10.0
const PROBE_DISTANCE := 10.0
const EPICENTER := Vector2(2000.0, 0.0)

var _checks := 0
var _fails := 0
var _root: Node2D = null
var _ship: Node2D = null
var _state: PlayerState = null
var _stats: ShipStats = null
var _damage_events: Array[float] = []


func _ready() -> void:
	_watchdog()
	_run()


func _watchdog() -> void:
	await get_tree().create_timer(120.0).timeout
	print("WATCHDOG: probe did not finish in 120 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _ticks(seconds: float) -> void:
	for _i in int(round(seconds * float(Engine.physics_ticks_per_second))):
		await get_tree().physics_frame


func _body() -> RigidBody2D:
	return _ship.call(&"impact_body") as RigidBody2D


## Speed along the nose, which is the axis the thrust law works on.
func _speed() -> float:
	var body := _body()
	return body.linear_velocity.dot(Vector2.RIGHT.rotated(body.global_rotation))


func _place(pos: Vector2, heading: float = 0.0) -> void:
	var body := _body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.global_position = pos
	body.global_rotation = heading
	_ship.call(&"cancel_orders")
	await get_tree().physics_frame


func _on_damage_taken(amount: float) -> void:
	_damage_events.append(amount)


func _run() -> void:
	print("=== slice0 M1 probe: rigid-body flight + Impact helpers ===")
	_constants()
	_helpers()
	await _scene_contract()
	await _gravity()
	await _flight()
	await _turn()
	await _classes()
	await _autopilot()
	await _collision()
	await _recoil()
	await _shockwave()
	await _api()
	print("=== slice0 M1 probe: checks %d, failures %d ===" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


## 18_engine_spec section 13, collision/recoil/explosion rows.
func _constants() -> void:
	print("--- Impact constants (18_engine_spec section 13) ---")
	print("COLLISION_FACTOR=%s COLLISION_MIN_DV=%s KNOCKBACK_FRACTION=%s EXPLOSION_P0=%s EXPLOSION_WINDOW=%s" % [
		ImpactScript.COLLISION_FACTOR, ImpactScript.COLLISION_MIN_DV,
		ImpactScript.KNOCKBACK_FRACTION, ImpactScript.EXPLOSION_P0,
		ImpactScript.EXPLOSION_WINDOW,
	])
	_check("constants: transcribed exactly from section 13",
		is_equal_approx(ImpactScript.COLLISION_FACTOR, 2.0e-5)
		and is_equal_approx(ImpactScript.COLLISION_MIN_DV, 40.0)
		and is_equal_approx(ImpactScript.KNOCKBACK_FRACTION, 0.40)
		and is_equal_approx(ImpactScript.EXPLOSION_P0, 4000.0)
		and is_equal_approx(ImpactScript.EXPLOSION_WINDOW, 0.2),
		"see the printed row above")


## The helpers themselves, against section 4.2 items 6-8 and section 16.
func _helpers() -> void:
	print("--- Impact helpers ---")
	var wall := ImpactScript.collision_damage(FIGHTER_MASS, INF, 450.0)
	_check("collision a: the section 16 worked example (80 t, 450 u/s, flat wall) = 162",
		is_equal_approx(wall, 162.0), "got %s" % wall)
	var bump := ImpactScript.collision_damage(FIGHTER_MASS, INF, 39.0)
	_check("collision b: below COLLISION_MIN_DV (40 u/s) a contact costs nothing",
		bump == 0.0, "dv=39 -> %s" % bump)
	var both := ImpactScript.collision_damage(500.0, 200.0, 450.0)
	var swapped := ImpactScript.collision_damage(200.0, 500.0, 450.0)
	_check("collision c: the reduced mass is symmetric between two moving hulls",
		both > 0.0 and is_equal_approx(both, swapped), "a=500,b=200 -> %s ; swapped %s" % [both, swapped])
	var knock := ImpactScript.knockback(100.0, 2.0)
	_check("knockback: 40 % of the projectile's remaining KE",
		is_equal_approx(knock, 0.40 * 0.5 * 2.0 * 100.0 * 100.0), "got %s (want 4000)" % knock)
	var recoil := ImpactScript.recoil_impulse(RECOIL_MASS, RECOIL_SPEED)
	_check("recoil: projectile_mass * muzzle_velocity",
		is_equal_approx(recoil, 1000.0), "1 kg at 1000 u/s -> %s impulse-units" % recoil)
	var near := ImpactScript.explosion_impulse(0.0)
	var far := ImpactScript.explosion_impulse(10.0)
	_check("explosion: I(d) = P0 / (1 + d^2)",
		is_equal_approx(near, 4000.0) and is_equal_approx(far, 4000.0 / 101.0),
		"d=0 -> %s ; d=10 -> %s" % [near, far])


## The shipped scene's body (slice-0 brief pinned item 1).
func _scene_contract() -> void:
	print("--- the shipped player_ship.tscn body ---")
	_root = Node2D.new()
	add_child(_root)
	_stats = ShipFit.resolve(HULL_ID, {})
	if _stats == null:
		_check("scene: ShipFit.resolve(ship_fighter, {})", false, "returned null")
		return
	var resolved_mass := float(_stats.get(&"hull_mass"))
	if resolved_mass <= 0.0:
		_stats.set(&"hull_mass", FIGHTER_MASS)
		print("NOTE: ShipFit.resolve left hull_mass at 0 (M2's resolve half has not landed); "
			+ "the probe sets section 13's Fighter mass %s t itself so the section 16 example is measurable." % FIGHTER_MASS)
	_state = PlayerStateScript.new()
	_state.hull_max = _stats.hull_max
	_state.shield_max = _stats.shield_max
	_state.setup()
	_ship = PlayerShipScene.instantiate() as Node2D
	_root.add_child(_ship)
	var empty_fit: Array[StringName] = []
	_ship.call(&"setup", _stats, _state, empty_fit)
	_ship.damage_taken.connect(_on_damage_taken)
	await get_tree().physics_frame
	var body := _body()
	var shape := body.get_node_or_null(NodePath(PlayerShipScript.HULL_SHAPE_NODE)) as CollisionShape2D
	var radius := 0.0
	if shape != null and shape.shape is CircleShape2D:
		radius = (shape.shape as CircleShape2D).radius
	print("body class=%s layer=%d mask=%d radius=%s mass=%s inertia=%s gravity_scale=%s contact_monitor=%s max_contacts=%d can_sleep=%s" % [
		body.get_class(), body.collision_layer, body.collision_mask, radius, body.mass,
		body.inertia, body.gravity_scale, body.contact_monitor, body.max_contacts_reported,
		body.can_sleep,
	])
	print("linear_damp=%s (1/coast_time=%s) ; angular_damp=%s (1/turn_spinup=%s) ; damp modes=%s/%s" % [
		body.linear_damp, 1.0 / _stats.coast_time, body.angular_damp,
		1.0 / _stats.turn_spinup, body.linear_damp_mode, body.angular_damp_mode,
	])
	_check("scene a: the hull body is a RigidBody2D on the ship layer, masking rocks",
		body is RigidBody2D and body.collision_layer == 2 and body.collision_mask == 1,
		"layer=%d mask=%d" % [body.collision_layer, body.collision_mask])
	_check("scene b: the shape is still the hull circle (half-length)",
		is_equal_approx(radius, SHIP_RADIUS), "radius=%s" % radius)
	_check("scene c: contact monitor on, 4 contacts reported, never sleeps",
		body.contact_monitor and body.max_contacts_reported == 4 and not body.can_sleep,
		"monitor=%s max=%d sleep=%s" % [body.contact_monitor, body.max_contacts_reported, body.can_sleep])
	_check("scene d: mass and inertia come from the snapshot",
		is_equal_approx(body.mass, FIGHTER_MASS)
		and is_equal_approx(body.inertia, 0.5 * FIGHTER_MASS * SHIP_RADIUS * SHIP_RADIUS),
		"mass=%s inertia=%s (m*r^2/2 = %s)" % [
			body.mass, body.inertia, 0.5 * FIGHTER_MASS * SHIP_RADIUS * SHIP_RADIUS,
		])
	_check("scene e: the section 13 damp, with the project default replaced",
		is_equal_approx(body.linear_damp, 1.0 / _stats.coast_time)
		and is_equal_approx(body.angular_damp, 1.0 / _stats.turn_spinup)
		and body.linear_damp_mode == 1 and body.angular_damp_mode == 1,
		"linear=%s angular=%s modes=%s/%s" % [
			body.linear_damp, body.angular_damp, body.linear_damp_mode, body.angular_damp_mode,
		])
	_check("scene f: gravity is off for a space hull",
		is_zero_approx(body.gravity_scale), "gravity_scale=%s" % body.gravity_scale)
	_check("scene g: the frozen group is still declared",
		_ship.is_in_group(&"player_ship"), "groups=%s" % [_ship.get_groups()])


## Ruling 8: a real body in a space sim must not fall.
func _gravity() -> void:
	print("--- gravity ---")
	print("project defaults: gravity=%s vector=%s linear_damp=%s angular_damp=%s" % [
		ProjectSettings.get_setting("physics/2d/default_gravity", 0.0),
		ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2.ZERO),
		ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.0),
		ProjectSettings.get_setting("physics/2d/default_angular_damp", 0.0),
	])
	await _place(Vector2.ZERO)
	var before := _ship.global_position
	await _ticks(1.0)
	var moved := _ship.global_position.distance_to(before)
	var drift := _body().linear_velocity.length()
	_check("gravity: the hull does not fall and does not creep",
		moved < 0.01 and drift < 0.01,
		"moved %s u, drift %s u/s over 1 s" % [moved, drift])


## Section 3.2's accel/coast/brake times, now derived as forces.
func _flight() -> void:
	print("--- flight (section 3.2 feel, by derivation) ---")
	var target: float = _stats.max_speed
	await _place(Vector2.ZERO)
	Input.action_press(&"thrust_forward")
	var accel_ticks := 0
	var reached := -1.0
	var peak := 0.0
	while accel_ticks < 400:
		await get_tree().physics_frame
		accel_ticks += 1
		var speed := _speed()
		peak = maxf(peak, speed)
		if speed >= target * 0.99:
			reached = float(accel_ticks) / float(Engine.physics_ticks_per_second)
			break
	_check("accel a: throttle reaches max speed within accel_time +-10 %",
		reached > 0.0 and absf(reached - _stats.accel_time) <= 0.10 * _stats.accel_time,
		"reached %s u/s at t=%s s (accel_time %s s)" % [target, reached, _stats.accel_time])
	await _ticks(1.0)
	var held := _speed()
	_check("accel b: it holds at the class maximum, no overshoot",
		absf(held - target) <= 0.01 * target and peak <= target * 1.01,
		"held %s u/s after 1 s more, peak %s u/s" % [held, peak])
	Input.action_release(&"thrust_forward")

	var coast_from := _ship.global_position
	var coast_started := _speed()
	var coast_ticks := 0
	var decayed := -1.0
	while coast_ticks < 400:
		await get_tree().physics_frame
		coast_ticks += 1
		if _speed() <= target * 0.05:
			decayed = float(coast_ticks) / float(Engine.physics_ticks_per_second)
			break
	var coast_distance := _ship.global_position.distance_to(coast_from)
	var coast_rate := coast_started * coast_started / (2.0 * maxf(coast_distance, 0.001))
	_check("coast a: the decay lands within coast_time +-10 %",
		decayed > 0.0 and absf(decayed - _stats.coast_time) <= 0.10 * _stats.coast_time,
		"fell to 5 %% of max at t=%s s (coast_time %s s)" % [decayed, _stats.coast_time])
	_check("coast b: the deceleration is the class's own (max_speed / coast_time)",
		absf(coast_rate - _stats.max_speed / _stats.coast_time) <= 0.10 * (_stats.max_speed / _stats.coast_time),
		"implied %s u/s^2 over %s u (class %s u/s^2)" % [
			coast_rate, coast_distance, _stats.max_speed / _stats.coast_time,
		])

	await _place(Vector2.ZERO)
	Input.action_press(&"thrust_forward")
	await _ticks(_stats.accel_time + 0.5)
	Input.action_release(&"thrust_forward")
	var brake_from := _ship.global_position
	var brake_started := _speed()
	Input.action_press(&"thrust_backward")
	var brake_ticks := 0
	while brake_ticks < 400 and _speed() > 0.0:
		await get_tree().physics_frame
		brake_ticks += 1
	var brake_distance := _ship.global_position.distance_to(brake_from)
	Input.action_release(&"thrust_backward")
	var accel_rate: float = _stats.max_speed / _stats.accel_time
	var brake_rate := brake_started * brake_started / (2.0 * maxf(brake_distance, 0.001))
	_check("brake a: S stops the hull shorter than a coast",
		brake_distance < coast_distance,
		"brake %s u from %s u/s vs coast %s u" % [brake_distance, brake_started, coast_distance])
	_check("brake b: the brake rate is BRAKE_MULT 1.8 x the class accel (+-10 %)",
		absf(brake_rate - PlayerShipScript.BRAKE_MULT * accel_rate) <= 0.10 * (PlayerShipScript.BRAKE_MULT * accel_rate),
		"implied %s u/s^2 (1.8 x %s = %s)" % [brake_rate, accel_rate, PlayerShipScript.BRAKE_MULT * accel_rate])

	## The damp the brief sizes from coast_time owns the lateral axis, the degree of
	## freedom the rigid body adds: a sideways push is not thrustable, so it decays.
	await _place(Vector2.ZERO)
	var mass := _body().mass
	_body().apply_central_impulse(Vector2(0.0, mass * 100.0))
	await get_tree().physics_frame
	var lateral_from := absf(_body().linear_velocity.y)
	await _ticks(_stats.coast_time)
	var lateral_to := absf(_body().linear_velocity.y)
	var ratio := lateral_to / maxf(lateral_from, 0.001)
	_check("damp: a sideways push decays with the coast_time time constant",
		absf(ratio - exp(-1.0)) <= 0.10 * exp(-1.0),
		"lateral %s -> %s u/s over %s s (ratio %s, 1/e %s)" % [
			lateral_from, lateral_to, _stats.coast_time, ratio, exp(-1.0),
		])


## Section 3.2's angular inertia, by derivation. The turn rate is asked to spin up to
## the class rate over turn_spinup (turn_rate / turn_spinup of angular acceleration),
## and the hull it is asked of is heavier than the old scalar model could know.
func _turn() -> void:
	print("--- angular inertia (section 3.2) ---")
	await _place(Vector2.ZERO)
	var before := _ship.global_position
	Input.action_press(&"turn_right")
	var ticks := 0
	var spun := -1.0
	var peak := 0.0
	while ticks < 300:
		await get_tree().physics_frame
		ticks += 1
		var omega := absf(_body().angular_velocity)
		peak = maxf(peak, omega)
		if omega >= _stats.turn_rate * 0.99:
			spun = float(ticks) / float(Engine.physics_ticks_per_second)
			break
	Input.action_release(&"turn_right")
	var drift := _ship.global_position.distance_to(before)
	_check("turn a: the rate spins up over turn_spinup (+-10 %)",
		spun > 0.0 and absf(spun - _stats.turn_spinup) <= 0.10 * _stats.turn_spinup,
		"reached %s rad/s at t=%s s (turn_spinup %s s)" % [
			_stats.turn_rate, spun, _stats.turn_spinup,
		])
	_check("turn b: it stops at the class turn rate, no overshoot",
		peak <= _stats.turn_rate * 1.01,
		"peak %s rad/s (class %s rad/s)" % [peak, _stats.turn_rate])
	_check("turn c: turning does not translate the hull",
		drift < 0.5, "moved %s u in %s rad of turn" % [drift, absf(_body().global_rotation)])
	await _ticks(1.0)
	var damped := absf(_body().angular_velocity)
	_check("turn d: releasing the key damps the spin back to a stop",
		damped < _stats.turn_rate * 0.1, "%s rad/s one second after release" % damped)
	## The ship node mirrors the body, which is what keeps the sprite, the mining laser
	## and the camera with the hull.
	var offset := _ship.global_position.distance_to(_body().global_position)
	var skew := absf(wrapf(_ship.global_rotation - _body().global_rotation, -PI, PI))
	_check("mirror: the node rides the body's transform",
		offset < 0.001 and skew < 0.001,
		"offset %s u, rotation skew %s rad" % [offset, skew])


## Ruling 8 in numbers: the same class law asked of a heavier hull. The Destroyer's
## section 13 column (315 u/s over 6.4 s) is a 49.2 u/s^2 acceleration, so its 300 t
## hull is owed a proportionally larger force for the same feel.
func _classes() -> void:
	print("--- the force is mass-scaled (ruling 8) ---")
	var heavy: ShipStats = ShipFit.resolve(&"ship_destroyer", {})
	var state := PlayerStateScript.new()
	state.hull_max = heavy.hull_max
	state.shield_max = heavy.shield_max
	state.setup()
	var ship := PlayerShipScene.instantiate() as Node2D
	_root.add_child(ship)
	var empty_fit: Array[StringName] = []
	ship.call(&"setup", heavy, state, empty_fit)
	var body := ship.call(&"impact_body") as RigidBody2D
	body.global_position = Vector2(5000.0, 5000.0)
	await get_tree().physics_frame
	Input.action_press(&"thrust_forward")
	await _ticks(1.0)
	Input.action_release(&"thrust_forward")
	var speed := body.linear_velocity.dot(Vector2.RIGHT.rotated(body.global_rotation))
	var want: float = heavy.max_speed / heavy.accel_time
	_check("class: the Destroyer's 300 t hull accelerates at its own class rate",
		absf(speed - want) <= 0.10 * want,
		"mass %s t, %s u/s after 1 s (class accel %s u/s^2), vs the Fighter's 80 t / 225 u/s^2" % [
			body.mass, speed, want,
		])
	ship.queue_free()
	await get_tree().physics_frame


## Section 3.1/3.2: the autopilot obeys the same physics.
func _autopilot() -> void:
	print("--- autopilot arrive steering ---")
	await _place(Vector2.ZERO)
	var order := Vector2(600.0, 0.0)
	_ship.call(&"set_move_target", order)
	var closest := 1.0e9
	var ticks := 0
	while ticks < 900:
		await get_tree().physics_frame
		ticks += 1
		closest = minf(closest, _ship.global_position.distance_to(order))
		if not bool(_ship.get(&"_has_move_target")):
			break
	var cancelled := not bool(_ship.get(&"_has_move_target"))
	var arrived := float(ticks) / float(Engine.physics_ticks_per_second)
	_check("autopilot a: the order arrives inside ARRIVE_RADIUS",
		cancelled and closest <= PlayerShipScript.ARRIVE_RADIUS,
		"closest %s u at t=%s s (ARRIVE_RADIUS %s, SLOW_DOWN_RADIUS %s)" % [
			closest, arrived, PlayerShipScript.ARRIVE_RADIUS, PlayerShipScript.SLOW_DOWN_RADIUS,
		])
	await _ticks(4.0)
	var rest := _ship.global_position.distance_to(order)
	var rest_speed := _body().linear_velocity.length()
	_check("autopilot b: the hull then settles instead of sailing past",
		rest_speed < 1.0 and rest < PlayerShipScript.SLOW_DOWN_RADIUS,
		"resting %s u from the order at %s u/s" % [rest, rest_speed])
	_ship.call(&"set_move_target", Vector2(4000.0, 0.0))
	await get_tree().physics_frame
	Input.action_press(&"thrust_forward")
	await get_tree().physics_frame
	Input.action_release(&"thrust_forward")
	_check("autopilot c: manual thrust cancels the order",
		not bool(_ship.get(&"_has_move_target")), "has_move_target=%s" % _ship.get(&"_has_move_target"))


## Section 4.2 item 6 / section 16's worked example, flown into a flat wall.
func _collision() -> void:
	print("--- flat-wall impact (section 4.2 item 6, section 16 example) ---")
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(WALL_HALF * 2.0, 400.0)
	shape.shape = box
	wall.add_child(shape)
	wall.collision_layer = 1
	wall.collision_mask = 0
	_root.add_child(wall)
	wall.global_position = Vector2(WALL_X, 0.0)
	await get_tree().physics_frame
	_state.set_hull(_state.hull_max)
	_state.set_shield(0.0)
	_damage_events.clear()
	await _place(Vector2.ZERO)
	var hull_before := _state.hull
	var contact_x := WALL_X - SHIP_RADIUS - WALL_HALF
	var impact := 0.0
	var stalled := 0
	var ticks := 0
	Input.action_press(&"thrust_forward")
	while ticks < 600 and stalled < 3:
		await get_tree().physics_frame
		ticks += 1
		impact = maxf(impact, _speed())
		if _ship.global_position.x >= contact_x - 1.0:
			stalled += 1
		else:
			stalled = 0
	Input.action_release(&"thrust_forward")
	var dealt := hull_before - _state.hull
	var stopped := _ship.global_position.x
	print("impact %s u/s ; hull %s -> %s ; stopped at x=%s (contact x=%s) ; damage_taken=%s" % [
		impact, hull_before, _state.hull, stopped, contact_x, _damage_events,
	])
	_check("collision a: a 450 u/s flat-wall hit deals 162 +-10 % hull damage",
		absf(dealt - 162.0) <= 16.2,
		"dealt %s (want 162) at an impact speed of %s u/s" % [dealt, impact])
	_check("collision b: damage_taken announces the same wound",
		_damage_events.size() == 1 and absf(_damage_events[0] - dealt) < 0.01,
		"events=%s" % [_damage_events])
	_check("collision c: the wall is solid and the hull stops at its face",
		absf(stopped - contact_x) <= 1.0, "stopped %s vs contact %s" % [stopped, contact_x])


## Section 4.2 item 7, the shooter's half.
func _recoil() -> void:
	print("--- recoil (section 4.2 item 7) ---")
	await _place(Vector2.ZERO)
	## The controller is paused for the kick's own reading: the impulse lands
	## instantly, while the class's coast law starts arresting the drift next frame.
	_ship.set_physics_process(false)
	_ship.call(&"apply_recoil", Vector2(RECOIL_SPEED, 0.0), RECOIL_MASS)
	await get_tree().physics_frame
	var kicked := _speed()
	_ship.set_physics_process(true)
	await _ticks(0.5)
	var settled := _speed()
	var expected := -ImpactScript.recoil_impulse(RECOIL_MASS, RECOIL_SPEED) / _body().mass
	print("recoil: %s u/s immediately, %s u/s after 0.5 s (expected impulse -%s u/s on %s t)" % [
		kicked, settled, absf(expected), _body().mass,
	])
	_check("recoil a: a shot pushes the hull back by projectile_mass * muzzle_velocity / mass",
		kicked < 0.0 and absf(kicked - expected) <= 0.05 * absf(expected) + 0.01,
		"kicked %s u/s, expected %s u/s" % [kicked, expected])
	_check("recoil b: the class's own coast law then arrests the drift",
		absf(settled) < absf(kicked) and absf(settled) < 1.0,
		"%s -> %s u/s" % [kicked, settled])


## Section 4.2 item 8: the impulse curve, delivered across EXPLOSION_WINDOW.
func _shockwave() -> void:
	print("--- explosion pressure (section 4.2 item 8, EXPLOSION_WINDOW 0.2 s) ---")
	var target := RigidBody2D.new()
	target.mass = PROBE_MASS
	target.gravity_scale = 0.0
	target.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	target.linear_damp = 0.0
	target.can_sleep = false
	_root.add_child(target)
	target.global_position = EPICENTER + Vector2(PROBE_DISTANCE, 0.0)
	await get_tree().physics_frame
	ImpactScript.apply_shockwave(EPICENTER, target, ImpactScript.EXPLOSION_WINDOW)
	await _ticks(ImpactScript.EXPLOSION_WINDOW * 0.5)
	var halfway := target.linear_velocity.length()
	await _ticks(ImpactScript.EXPLOSION_WINDOW * 0.5 + 0.1)
	var total := target.linear_velocity.length()
	var expected := ImpactScript.explosion_impulse(PROBE_DISTANCE) / PROBE_MASS
	print("I(%s u) = %s impulse-units ; expected dv %s u/s ; at half the window %s ; after it %s" % [
		PROBE_DISTANCE, ImpactScript.explosion_impulse(PROBE_DISTANCE), expected, halfway, total,
	])
	_check("shockwave a: the momentum delivered is I(d) / mass",
		absf(total - expected) <= 0.05 * expected, "got %s u/s, expected %s u/s" % [total, expected])
	_check("shockwave b: it arrives across the window, not in one blow",
		halfway > 0.2 * total and halfway < 0.9 * total,
		"half-window %s u/s of %s u/s" % [halfway, total])
	_check("shockwave c: the push is outward",
		target.linear_velocity.x > 0.0, "velocity=%s" % target.linear_velocity)


## The frozen API of pinned item 1 plus this worker's additive seams.
func _api() -> void:
	print("--- frozen API of pinned item 1 ---")
	var frozen: Array[StringName] = [
		&"setup", &"set_move_target", &"cancel_orders", &"warp_available", &"cargo_max", &"has_booster",
	]
	var missing: Array[StringName] = []
	for method: StringName in frozen:
		if not _ship.has_method(method):
			missing.append(method)
	_check("api a: every frozen method is still there", missing.is_empty(), "missing=%s" % [missing])
	_check("api b: the damage_taken signal is still declared",
		_ship.has_signal(&"damage_taken"), "signals=%s" % [_ship.get_signal_list().map(func(entry: Dictionary) -> String: return str(entry.get("name")))])
	var additive: Array[StringName] = [&"velocity", &"impact_body", &"apply_impulse", &"apply_recoil", &"cargo_max"]
	var absent: Array[StringName] = []
	for method: StringName in additive:
		if not _ship.has_method(method):
			absent.append(method)
	_check("api c: the additive push seams exist (velocity / impact_body / apply_impulse / apply_recoil)",
		absent.is_empty(), "missing=%s" % [absent])
	var mining_fit: Array[StringName] = [&"w_mining"]
	_ship.call(&"setup", _stats, _state, mining_fit)
	await get_tree().physics_frame
	var laser := _ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	_check("api d: the w_mining mount seam still mounts the laser",
		laser != null and laser.has_method(&"bind") and laser.has_method(&"set_active"),
		"laser=%s" % laser)
	var empty_fit: Array[StringName] = []
	_ship.call(&"setup", _stats, _state, empty_fit)
	await get_tree().physics_frame
	_check("api e: a fit without the module still releases it",
		_ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE)) == null,
		"laser=%s" % _ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE)))
