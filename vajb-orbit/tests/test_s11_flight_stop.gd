@tool
extends McpTestSuite
## Suite s11_flight_stop: the acceptance half of CONTRACTS section 23.5's one-vector inertia
## (owner ruling 2026-09-24, item 18): *"released from a commanded forward+strafe at cruise,
## the hull's velocity direction holds within 5 degrees of its release bearing while the
## speed falls to 0.1x of release ... the two components decay together, one stop, one
## line"*.
##
## The suite plays the physics server, the same split `test_s2_6_flight.gd` keeps and for the
## same reason (the headless runner never awaits a frame): the shipped `_physics_process` is
## driven one tick at a time, the force it applied is read off the hull's own
## `applied_force()` seam, and the suite integrates that force *and* the body's own
## `linear_damp` the way the engine does -- the damp first (`1 / (1 + damp * delta)`, the
## form `probe_s2_6_flight` pins in its own engine-arithmetic case), then the force the law
## applied with that damp already compensated inside it, which is what makes a chased axis
## travel at the class rate rather than the class rate minus drag.
##
## Three readings per hull:
##   1. the commanded diagonal (W+D) really reaches the class ceiling: the stick is clamped
##      to `max_speed`, so the release speed is the class's own ceiling and each axis half
##      of it;
##   2. released, the bearing of travel never leaves the 5 degree window around the release
##      bearing, sampled on every tick until the speed is a tenth of the release speed, and
##      the force during that decay is antiparallel to the velocity on every tick -- one
##      vector, one line;
##   3. the time to the tenth is the derived `0.9 x coast_time x (v_release / max_speed)`,
##      scaled by the fit's own mass ratio (S22.7: the forces are the class's, applied
##      against the fitted mass) -- the class's own coast rate applied to the whole
##      velocity: one stop.
##
## A fourth test holds the wave's own hazard (S11-R1's brief names it): the release branch
## must not slow a *commanded* strafe, which still reaches 90 % of the class ceiling in
## 90 % of `accel_time`, because `_is_released` is false while any axis is commanded.

const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const THRUST_FORWARD: StringName = &"thrust_forward"
const STRAFE_RIGHT: StringName = &"strafe_right"
## The hull the owner's launches carry (the S2.6/G1/C3 fixture), plus the two extremes of
## the handling column so the acceptance is measured on more than one class of decay.
const HULL_SHIPPED: StringName = &"ship_vanguard"
const HULL_FASTEST: StringName = &"ship_fighter"
const HULL_HEAVIEST: StringName = &"ship_freighter"

## The acceptance's own bound, in degrees: the bearing of travel may not leave this window
## around the release bearing, on any tick of the decay to a tenth of the release speed.
const DIRECTION_HOLD_MAX_DEGREES := 5.0
## Where the measured window ends: a tenth of the release speed.
const RELEASE_SPEED_FRACTION := 0.1
## The released velocity ramps to zero at the class's own coast rate, so the tenth point sits
## at `0.9 x coast_time x (v_release / max_speed)`. Three percent covers the 60 Hz sampling
## grid and the engine's own order of the damp against the force (measured to better than
## one percent by `probe_s2_6_flight`'s axial release, which reports the derived
## `0.9 x coast_time` against its own).
const TENTH_TIME_TOLERANCE := 0.03
## The cruise the release starts from: the class ceiling within this fraction, so a chase that
## never arrived is reported as such rather than measured. The chase is a saturated ramp that
## lands exactly on its target, so the band is narrow.
const CRUISE_TOLERANCE := 0.002
## The second law the release must not disturb: from rest a commanded strafe reaches this
## fraction of the class ceiling in this fraction of `accel_time`, less this slack for the
## sampling grid and the damp-order term.
const STRAFE_ARRIVAL_FRACTION := 0.9
const STRAFE_ARRIVAL_SLACK := 0.02
## The body's own `linear_damp` is a float32 (`real_t`), the value `_linear_damp()` returns is
## float64: the two differ by that rounding alone, so the body-carried readings use this.
const BODY_DAMP_TOLERANCE := 1e-6
## How much of the force may lie across the velocity during the release: the force is
## `axis * force` with the axis the velocity's own unit vector, so only float32 rounding.
const CROSS_FORCE_SHARE := 1e-4

const AIM_DISTANCE := 4000.0
## The cruise ramp takes `accel_time` seconds and the release decays over at most
## `coast_time`; both budgets are generous multiples with a second of slack, and a case that
## runs out reports itself rather than hanging (L82).
const CRUISE_BUDGET_FACTOR := 2.0
const RELEASE_BUDGET_FACTOR := 2.0
const BUDGET_SLACK_SECONDS := 1.0

var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func suite_name() -> String:
	return "s11_flight_stop"


func teardown() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## 1. The owner's complaint, measured: one stop on the release line
## ---------------------------------------------------------------------------


## Released from a commanded forward+strafe at cruise, the velocity's direction holds
## within the pinned 5 degrees of the release bearing while the speed falls to a tenth of
## release -- on every hull, sampled every tick, with the window's end asserted so a hull
## that never decayed cannot pass. The time to the tenth is the derived coast ramp, which is
## what "one stop" means in numbers.
func test_the_released_hull_holds_its_release_bearing_to_the_tenth() -> void:
	for hull_id: StringName in [HULL_SHIPPED, HULL_FASTEST, HULL_HEAVIEST]:
		var measured := _measure_release(hull_id)
		if measured.is_empty() or not bool(measured[&"cruised"]):
			assert_true(false, "%s: the commanded diagonal never reached the class ceiling" % hull_id)
			continue
		var release_speed := float(measured[&"release_speed"])
		var drift := float(measured[&"max_drift_degrees"])
		var crossed := bool(measured[&"crossed_tenth"])
		var tenth_time := float(measured[&"tenth_time"])
		var derived_tenth := float(measured[&"derived_tenth"])
		print(
			(
				"[S11FS] stop hull=%s v_release=%.3f drift=%.6f deg cross_share=%.9f sampled=%d t_tenth=%.4f derived=%.4f coast_time=%.4f"
				% [
					hull_id,
					release_speed,
					drift,
					float(measured[&"max_cross_share"]),
					int(measured[&"release_ticks"]),
					tenth_time,
					derived_tenth,
					float(measured[&"coast_time"]),
				]
			)
		)
		assert_true(
			crossed,
			"%s: the released velocity did reach a tenth of its release speed" % hull_id
		)
		assert_true(
			drift <= DIRECTION_HOLD_MAX_DEGREES,
			(
				"%s: the bearing of travel stays inside %.1f degrees of the release bearing (measured %.4f)"
				% [hull_id, DIRECTION_HOLD_MAX_DEGREES, drift]
			)
		)
		assert_true(
			float(measured[&"max_cross_share"]) <= CROSS_FORCE_SHARE,
			(
				"%s: the release force is antiparallel to the velocity on every tick (largest cross share %.9f)"
				% [hull_id, float(measured[&"max_cross_share"])]
			)
		)
		assert_true(
			_relative(tenth_time, derived_tenth) <= TENTH_TIME_TOLERANCE,
			(
				"%s: the tenth point is the derived 0.9 x coast_time x v_release / max_speed (%.4f against %.4f s)"
				% [hull_id, tenth_time, derived_tenth]
			)
		)
		assert_true(
			_relative(release_speed, float(measured[&"max_speed"])) <= CRUISE_TOLERANCE,
			(
				"%s: the release really happened at the class ceiling (%.3f of %.3f u/s)"
				% [hull_id, release_speed, float(measured[&"max_speed"])]
			)
		)


## The pin the acceptance stands on, read off the shipped hull: one rate owns both axes, and
## the explicit lateral drag that used to hold the sideways axis apart is exactly zero (its
## body is kept and inert: `_step_lateral_drag` returns on the guard).
func test_the_one_damp_is_the_only_linear_decay_the_hull_carries() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	var body: RigidBody2D = ship.impact_body()
	var forward := float(ship.call(&"_linear_damp"))
	var sideways := float(ship.call(&"_lateral_damp"))
	var extra := float(ship.call(&"_lateral_extra_damp"))
	assert_true(
		_near(forward, 1.0 / float(stats.coast_time), 1e-9),
		"the body's damp is 1 / coast_time (%.6f)" % forward
	)
	assert_true(
		_near(sideways, forward, 1e-9),
		"the sideways damp is the same number, one rate on both axes (%.6f)" % sideways
	)
	assert_true(
		is_zero_approx(extra),
		"the explicit lateral drag is 0.0, so `_step_lateral_drag` is inert (%.9f)" % extra
	)
	assert_true(
		_near(body.linear_damp, forward, BODY_DAMP_TOLERANCE),
		"and the body carries the one damp the engine integrates"
	)
	assert_true(
		is_equal_approx(ShipFitScript.ANGULAR_DAMP_MULT, 0.5),
		"the angular damp multiplier is the pinned 0.5 (23.5's T2)"
	)
	assert_true(
		_near(
			float(ship.call(&"_angular_damp")),
			ShipFitScript.ANGULAR_DAMP_MULT / float(stats.turn_spinup),
			1e-9
		),
		"the released turn's damp is ANGULAR_DAMP_MULT / turn_spinup"
	)


## ---------------------------------------------------------------------------
## 2. The wave's own hazard: the commanded strafe keeps its class-rate chase
## ---------------------------------------------------------------------------


## A commanded strafe is *not* a release, so the per-axis law owns it and the chase is the
## class's own `max_speed / accel_time` with the one damp compensated: from rest, D reaches
## 90 % of the class ceiling in 90 % of `accel_time`. A one-vector fix that unified the decay
## by letting the release branch (or a counter-force) eat the commanded axis would pass the
## stop test above and fail here.
func test_a_commanded_strafe_still_reaches_the_class_ceiling_at_the_class_rate() -> void:
	for hull_id: StringName in [HULL_SHIPPED, HULL_FASTEST]:
		var pair := _launch(hull_id)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		var body: RigidBody2D = ship.impact_body()
		var dt := 1.0 / float(Engine.physics_ticks_per_second)
		var mass := float(body.mass)
		## S22.7's mass law: the launch fit's plate pays in mass, so the chase is
		## the class rate scaled by base/fitted and the mass-scaled window is what
		## 90 % of `accel_time` means on the fitted hull.
		var mass_ratio := mass / float(stats.base_mass)
		var heading := float(body.global_rotation)
		var position := Vector2.ZERO
		var velocity := Vector2.ZERO
		var side := Vector2.RIGHT.rotated(heading + PI * 0.5)
		var ceiling := float(stats.max_speed)
		var steps := int(STRAFE_ARRIVAL_FRACTION * float(stats.accel_time) * mass_ratio * 60.0)
		_press(STRAFE_RIGHT)
		for i: int in range(steps):
			velocity = _tick(ship, body, heading, position, velocity, dt, mass)
			position += velocity * dt
		_release_all()
		var sideways_speed := absf(velocity.dot(side))
		print(
			"[S11FS] strafe hull=%s sideways=%.3f ceiling=%.3f after=%.3f s"
			% [hull_id, sideways_speed, ceiling, float(steps) / 60.0]
		)
		assert_true(
			velocity.dot(side) > 0.0,
			"%s: D still pushes the hull towards its right" % hull_id
		)
		assert_true(
			sideways_speed >= STRAFE_ARRIVAL_FRACTION * ceiling * (1.0 - STRAFE_ARRIVAL_SLACK),
			(
				"%s: the commanded strafe reaches %.0f %% of the class ceiling in %.0f %% of accel_time (%.3f of %.3f u/s)"
				% [
					hull_id,
					STRAFE_ARRIVAL_FRACTION * 100.0,
					STRAFE_ARRIVAL_FRACTION * 100.0,
					sideways_speed,
					ceiling,
				]
			)
		)
		assert_true(
			absf(velocity.dot(Vector2.RIGHT.rotated(heading))) <= CROSS_FORCE_SHARE * ceiling,
			"%s: and the strafe is lateral, so nothing was added along the nose" % hull_id
		)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## One released decay, flown from a commanded diagonal: press W+D, ramp to the class
## ceiling, release, then keep ticking the law with the suite integrating. Returns the
## release speed, the largest bearing drift inside the window that ends at a tenth of the
## release speed, the largest share of the force lying across the velocity, and the time to
## that tenth against its own derivation.
func _measure_release(hull_id: StringName) -> Dictionary:
	var pair := _launch(hull_id)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		return {}
	var body: RigidBody2D = ship.impact_body()
	if body == null:
		return {}
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var mass := float(body.mass)
	var damp := float(body.linear_damp)
	var heading := float(body.global_rotation)
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var ceiling := float(stats.max_speed)

	## 1. The commanded forward+strafe, from rest to the class ceiling. The command clamps
	##    the stick to `_max_speed`, so both axes chase half of the ceiling and the vector
	##    arrives at the ceiling itself.
	_press(THRUST_FORWARD)
	_press(STRAFE_RIGHT)
	var cruise_budget := int(float(stats.accel_time) * CRUISE_BUDGET_FACTOR * 60.0 + 60.0)
	var release_speed := 0.0
	var cruised := false
	for i: int in range(cruise_budget):
		velocity = _tick(ship, body, heading, position, velocity, dt, mass)
		position += velocity * dt
		if i > 1 and velocity.length() >= ceiling * (1.0 - CRUISE_TOLERANCE):
			release_speed = velocity.length()
			cruised = true
			break
	_release_all()
	if not cruised:
		return {&"cruised": false, &"hull": hull_id}

	## 2. The release: no input at all for the rest of the case, so `_is_released` is true
	##    and the whole velocity is what decays.
	var release_bearing := velocity.angle()
	var max_drift := 0.0
	var max_cross := 0.0
	var tenth_time := -1.0
	var release_ticks := 0
	var release_budget := int(
		float(stats.coast_time) * RELEASE_BUDGET_FACTOR * 60.0 + BUDGET_SLACK_SECONDS * 60.0
	)
	var elapsed := 0.0
	for i: int in range(release_budget):
		var force: Vector2 = _drive(ship, body, heading, position, velocity, dt)
		if velocity.length_squared() > 0.0 and force.length_squared() > 0.0:
			max_cross = maxf(
				max_cross, absf(force.normalized().cross(velocity.normalized()))
			)
		velocity = _integrate(velocity, force, mass, damp, dt)
		position += velocity * dt
		elapsed += dt
		release_ticks += 1
		var speed := velocity.length()
		max_drift = maxf(
			max_drift,
			absf(rad_to_deg(wrapf(velocity.angle() - release_bearing, -PI, PI)))
		)
		if speed <= RELEASE_SPEED_FRACTION * release_speed:
			tenth_time = elapsed
			break

	## The derived tenth point: the whole velocity ramps to zero at the class's own coast
	## rate scaled by the fit's mass ratio (S22.7: the forces are the class's, applied
	## against the fitted mass), so the tenth is
	## `0.9 x (v_release / max_speed) x coast_time x fitted/base`.
	var derived := (
		(1.0 - RELEASE_SPEED_FRACTION)
		* (release_speed / ceiling)
		* float(stats.coast_time)
		* mass / float(stats.base_mass)
	)
	return {
		&"cruised": true,
		&"hull": hull_id,
		&"release_speed": release_speed,
		&"max_speed": ceiling,
		&"coast_time": float(stats.coast_time),
		&"max_drift_degrees": max_drift,
		&"max_cross_share": max_cross,
		&"tenth_time": tenth_time,
		&"crossed_tenth": tenth_time > 0.0,
		&"derived_tenth": derived,
		&"release_ticks": release_ticks,
	}


## One driven step of the whole law: the body's state is set, the aim is pinned dead ahead
## (so the nose never turns and the axes stay fixed), the shipped `_physics_process` runs for
## one tick and the force it applied is read back. Returns that force.
func _drive(
	ship: Variant,
	body: RigidBody2D,
	heading: float,
	position: Vector2,
	velocity: Vector2,
	delta: float
) -> Vector2:
	body.global_rotation = heading
	body.angular_velocity = 0.0
	body.linear_velocity = velocity
	body.global_position = position
	ship.set_aim_point(body.global_position + Vector2.RIGHT.rotated(heading) * AIM_DISTANCE)
	ship.call(&"_physics_process", delta)
	return ship.call(&"applied_force")


## The same step, with the engine's own integration folded in: the body's damp first, then
## the force the law applied with that damp compensated inside it. Returns the new velocity.
func _tick(
	ship: Variant,
	body: RigidBody2D,
	heading: float,
	position: Vector2,
	velocity: Vector2,
	delta: float,
	mass: float
) -> Vector2:
	var force := _drive(ship, body, heading, position, velocity, delta)
	return _integrate(velocity, force, mass, float(body.linear_damp), delta)


## The engine's linear integration, as `probe_s2_6_flight` pins it: the damp is the
## `1 / (1 + damp * delta)` form, applied before the step's force.
func _integrate(
	velocity: Vector2, force: Vector2, mass: float, damp: float, delta: float
) -> Vector2:
	var out := velocity * (1.0 / (1.0 + damp * delta))
	out += force / mass * delta
	return out


## One launched hull, the fixture the S2.6/C3/G1 suites use.
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
	_host().add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_staged.append(ship)
	return [ship, stats]


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the runner
## scene during `_ready` (see `test_engine2_fixes.gd`).
func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _press(action: StringName) -> void:
	Input.action_press(action)
	if not _pressed.has(action):
		_pressed.append(action)


func _release_all() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()


func _near(measured: float, expected: float, tolerance: float = 1e-9) -> bool:
	return absf(measured - expected) <= tolerance


## The difference between two readings relative to the larger of them, with two zeros
## defined as equal (the S2.6 suite's own reading).
func _relative(a: float, b: float) -> float:
	var scale := maxf(absf(a), absf(b))
	if is_zero_approx(scale):
		return 0.0
	return absf(a - b) / scale
