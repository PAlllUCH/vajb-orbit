@tool
extends McpTestSuite
## Suite s22_7_ships: the ships half of the mass physics wave (S22.7, owner ticks
## 2026-09-30 / 2026-10-01) -- one row per acceptance criterion, every figure measured
## and printed:
##
## - AC1 `ShipStats.base_mass` is the class row's `hull_mass`, read before any module
##   multiplication, and the derived `engine_thrust` is `base_mass x max_speed /
##   accel_time` on the resolved rates (18 section 3.2's mass law);
## - AC2 the forces are the class's, the inertia is the fit's: the shipped Vanguard's
##   release envelope is the S22.6 record to the tick (t_10 4.733 s, the stop on the
##   5.25 s coast), and an `h_composite` fit measures ~9 % slower to accelerate while
##   its coast carries ~10 % further;
## - AC3 plating's ponderous half is mass: light x1.05, composite x1.10 x 1.10 =
##   x1.21, the three handling times stay the class rows, the max_speed cut unchanged;
## - AC4 fuel is thrust's receipt: the boost burns section 13's eight-rate table
##   (the unfitted Vanguard 3.0 exactly) and the dash spends 25 x base_mass / 110,
##   with `fuel_max` the flat 200 (M5 kept flat);
## - AC5 section 23.5's acceptance stands at the new law: released from a commanded
##   forward+strafe at cruise, the bearing holds within 5 degrees to a tenth of the
##   release speed, one stop, one line.
##
## The suite plays the physics server the way `test_s11_flight_stop.gd` does (the
## headless runner never awaits a frame): the shipped `_physics_process` is driven one
## tick at a time and the force it applied is read off the hull's own
## `applied_force()` seam, integrated the way the engine does -- the damp first
## (`1 / (1 + damp * delta)`), then the force with that damp compensated inside it.
## Nothing here rolls an RNG: the fixtures are deterministic.

const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const THRUST_FORWARD: StringName = &"thrust_forward"
const STRAFE_RIGHT: StringName = &"strafe_right"
const HULL_SHIPPED: StringName = &"ship_vanguard"

## Section 13's BOOST_FUEL row (amended 2026-09-30): the eight per-second rates the
## mass law's burn formula must land on, to the row's own two decimals.
const BOOST_RATES: Dictionary = {
	&"ship_fighter": 2.75,
	&"ship_corvette": 3.10,
	&"ship_miner": 1.81,
	&"ship_trader": 3.12,
	&"ship_gunship": 2.38,
	&"ship_patrol": 3.22,
	&"ship_freighter": 1.94,
	&"ship_destroyer": 2.26,
}
## Section 13's DASH_FUEL row: 25 x mass / 110 t -- fighter 18.2, destroyer 68.2.
const DASH_EXPECTATIONS: Dictionary = {
	&"ship_fighter": 18.2,
	&"ship_destroyer": 68.2,
}

const TOLERANCE := 1e-6
const RATE_TOLERANCE := 0.005
## The release envelope's sampling grid: 60 Hz ticks and float32 velocities, the same
## slack `test_s22_6_inertia.gd`'s envelope rows keep.
const ENVELOPE_TOLERANCE := 0.02
const STOP_TICKS := 2
## The S22.6 probe's plated Vanguard record (18 section 13's COAST_TIME_MULT row):
## the figures the byte-identity claim names.
const S226_T10 := 4.733
const S226_CARRY := 1063.94

const DIRECTION_HOLD_MAX_DEGREES := 5.0
const RELEASE_SPEED_FRACTION := 0.1
const CROSS_FORCE_SHARE := 1e-4
const CRUISE_TOLERANCE := 0.002

const AIM_DISTANCE := 4000.0
const CRUISE_BUDGET_FACTOR := 2.0
const RELEASE_BUDGET_FACTOR := 2.0
const BUDGET_SLACK_SECONDS := 1.0

var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func suite_name() -> String:
	return "s22_7_ships"


func teardown() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## AC1 - base_mass is the class column, engine_thrust is derived once
## ---------------------------------------------------------------------------


func test_ac1_base_mass_is_the_class_column_and_thrust_is_derived() -> void:
	var reference: float = ShipFitScript.engine_thrust_reference()
	var checked := 0
	for raw_key: Variant in ShipFitScript.HANDLING.keys():
		var hull_id := StringName(raw_key)
		var row: Dictionary = ShipFitScript.HANDLING[hull_id]
		var unfitted: Variant = ShipFitScript.resolve(hull_id, {})
		if unfitted == null:
			assert_true(false, "%s: the empty fit did not resolve" % hull_id)
			continue
		## The class row's own mass, read before any module multiplication -- at an
		## unfitted hull base = fitted, all nine classes.
		assert_true(
			is_equal_approx(float(unfitted.base_mass), float(row[&"hull_mass"])),
			"%s: base_mass is the class column (%.1f t)" % [hull_id, float(unfitted.base_mass)]
		)
		assert_true(
			is_equal_approx(float(unfitted.hull_mass), float(unfitted.base_mass)),
			"%s: and at an unfitted hull base_mass == hull_mass" % hull_id
		)
		## The derived thrust, on the resolved rates (accel_time already carries
		## ACCEL_TIME_MULT 2.0).
		assert_true(
			is_equal_approx(
				float(unfitted.engine_thrust),
				float(unfitted.base_mass) * float(unfitted.max_speed) / float(unfitted.accel_time)
			),
			"%s: engine_thrust is base_mass x max_speed / accel_time (resolved)" % hull_id
		)
		## The armour pass moves the resolved mass only; the class column behind it
		## never moves.
		var plated: Variant = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
		if plated == null:
			assert_true(false, "%s: the standard fit did not resolve" % hull_id)
			continue
		assert_true(
			is_equal_approx(float(plated.base_mass), float(row[&"hull_mass"])),
			"%s: the plated resolve keeps base_mass on the class column" % hull_id
		)
		checked += 1
	assert_eq(checked, ShipFitScript.HANDLING.size(), "all nine classes measured")
	## The fuel row's anchor: the Vanguard's own class-row thrust, derived from the
	## section 13 literals and the resolve's own multiplier -- no new literal.
	assert_true(
		is_equal_approx(reference, 110.0 * 428.0 / (2.4 * ShipFitScript.ACCEL_TIME_MULT)),
		"the BOOST_FUEL anchor is the Vanguard's class-row thrust (%.3f)" % reference
	)
	print("[S227] AC1 reference_thrust=%.3f (Vanguard class rows)" % reference)


## ---------------------------------------------------------------------------
## AC2 - the forces are the class's, the inertia is the fit's
## ---------------------------------------------------------------------------


## The shipped (standard-fit, plated) Vanguard's release envelope, measured end to
## end: the tenth point lands on the S22.6 record's 4.733 s to the tick grid and the
## stop on the resolved-effective 5.25 s coast, so every shipped figure stands. The
## mass law trades the plate's old time multiplier for the same factor on the mass:
## the drive is the class rate x base/fitted -- the same ramp to the digit here,
## because the plate's two factors are equal (x1.05).
func test_ac2_the_shipped_vanguards_release_envelope_is_the_s226_record() -> void:
	var pair := _launch(HULL_SHIPPED, ShipFitScript.STANDARD_FIT)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the Vanguard fixture did not build")
		return
	var body: RigidBody2D = ship.impact_body()
	var ceiling := float(stats.max_speed)
	var mass_ratio := float(body.mass) / float(stats.base_mass)
	var envelope := _released_envelope(ship, Vector2(ceiling, 0.0))
	var t_10 := float(envelope[&"t_10"])
	var t_stop := float(envelope[&"t_stop"])
	var carry := float(envelope[&"carry"])
	var derived_t10 := 0.9 * float(stats.coast_time) * mass_ratio
	var derived_carry := 0.5 * ceiling * float(stats.coast_time) * mass_ratio
	print(
		"[S227] AC2 shipped vanguard v0=%.2f t_10=%.4f (S22.6 %.3f) t_stop=%.3f carry=%.2f (S22.6 %.2f)"
		% [ceiling, t_10, S226_T10, t_stop, carry, S226_CARRY]
	)
	assert_true(
		absf(t_10 - S226_T10) <= float(STOP_TICKS) / 60.0,
		"the shipped Vanguard's t_10 is the S22.6 record to the tick grid (%.4f s)" % t_10
	)
	assert_true(
		_near(t_10, derived_t10, ENVELOPE_TOLERANCE * derived_t10),
		"and it is the derived 0.9 x coast_time x fitted/base (%.4f s)" % derived_t10
	)
	assert_true(
		absf(t_stop - derived_t10 / 0.9) <= float(STOP_TICKS) / 60.0,
		"the stop lands on the mass-scaled coast (%.3f s)" % t_stop
	)
	assert_true(
		_near(carry, S226_CARRY, 0.01 * S226_CARRY),
		"the carried distance is the S22.6 record's %.2f u (measured %.2f)" % [S226_CARRY, carry]
	)
	assert_true(
		_near(carry, derived_carry, ENVELOPE_TOLERANCE * derived_carry),
		"and it is the derived 0.5 x v0 x coast_time x fitted/base (%.2f u)" % derived_carry
	)


## The `h_composite` fit (penalty -0.10 and `mass_add` 0.10, stacked in the one mass
## channel) against the same fit's pre-S22.7 resolve, derived from the same rows:
## the acceleration is ~9 % slower (x1.10 -> x1.21 on the effective chase) and the
## coast carries ~10 % further (the effective coast 6.05 s against 5.5 s).
func test_ac2_an_h_composite_fit_measures_the_mass_laws_ponderous_half() -> void:
	var composite_fit: Dictionary = {
		&"engines": [&"e_std"], &"power": &"p_std", &"armour": [&"h_composite"]
	}
	var pair := _launch(HULL_SHIPPED, composite_fit)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the composite fixture did not build")
		return
	var body: RigidBody2D = ship.impact_body()
	var ceiling := float(stats.max_speed)
	var base := float(stats.base_mass)
	var fitted := float(body.mass)
	## The pre-S22.7 resolve of the same fit put the penalty half on the three
	## times (x1.10) and left the mass_add on a mass the forces cancelled.
	var old_accel_rate := ceiling / (float(stats.accel_time) * 1.10)
	var ramp_time := _ramp_time(ship, 0.9 * ceiling)
	assert_true(ramp_time > 0.0, "the commanded ramp reached nine tenths of the ceiling")
	var new_accel_rate := (0.9 * ceiling) / ramp_time
	var old_coast_carry := 0.5 * ceiling * (float(stats.coast_time) * 1.10)
	var envelope := _released_envelope(ship, Vector2(ceiling, 0.0))
	var new_coast_carry := float(envelope[&"carry"])
	var accel_ratio := new_accel_rate / old_accel_rate
	var carry_ratio := new_coast_carry / old_coast_carry
	print(
		(
			"[S227] AC2 composite mass=%.1f (base %.1f) accel=%.3f u/s^2 (old %.3f, x%.4f) "
			+ "carry=%.2f u (old %.2f, x%.4f)"
		)
		% [
			fitted, base, new_accel_rate, old_accel_rate, accel_ratio,
			new_coast_carry, old_coast_carry, carry_ratio,
		]
	)
	assert_true(
		is_equal_approx(fitted, base * 1.21),
		"the composite fit resolves mass x1.21 (penalty and mass_add stacked)"
	)
	assert_true(
		absf(accel_ratio - (1.10 / 1.21)) <= 0.01,
		"the composite fit accelerates about 9 percent slower than the old double read (x%.4f)" % accel_ratio
	)
	assert_true(
		is_equal_approx(fitted / base, 1.21),
		"and the effective chase is the class rate scaled by base/fitted"
	)
	assert_true(
		absf(carry_ratio - 1.21 / 1.10) <= 0.01,
		"its coast carries about 10 percent further than the old resolve (x%.4f)" % carry_ratio
	)


## ---------------------------------------------------------------------------
## AC3 - plating's ponderous half is mass
## ---------------------------------------------------------------------------


func test_ac3_plating_pays_once_in_mass_and_the_times_stay_class() -> void:
	var light: Variant = ShipFitScript.resolve(HULL_SHIPPED, {
		&"engines": [&"e_std"], &"power": &"p_std", &"armour": [&"h_plate_light"]
	})
	assert_true(light != null, "the light plate resolves")
	if light != null:
		assert_true(
			is_equal_approx(float(light.hull_mass), 110.0 * 1.05),
			"h_plate_light resolves mass x1.05 (%.2f t)" % float(light.hull_mass)
		)
		assert_true(is_equal_approx(float(light.accel_time), 2.4 * 2.0), "the class accelerate leg")
		assert_true(
			is_equal_approx(float(light.coast_time), 1.0 * ShipFitScript.COAST_TIME_MULT),
			"the class coast"
		)
		assert_true(is_equal_approx(float(light.turn_spinup), 0.5), "and the class spin-up")
		assert_true(
			is_equal_approx(float(light.max_speed), 428.0 * 0.95),
			"the max_speed cut is byte-identical (x0.95)"
		)
	var composite: Variant = ShipFitScript.resolve(HULL_SHIPPED, {
		&"engines": [&"e_std"], &"power": &"p_std", &"armour": [&"h_composite"]
	})
	assert_true(composite != null, "the composite plate resolves")
	if composite != null:
		assert_true(
			is_equal_approx(float(composite.hull_mass), 110.0 * 1.21),
			"h_composite resolves mass x1.21 (%.2f t)" % float(composite.hull_mass)
		)
		assert_true(
			is_equal_approx(float(composite.accel_time), 2.4 * 2.0),
			"and the three handling times stay the class rows"
		)


## ---------------------------------------------------------------------------
## AC4 - fuel is thrust's receipt
## ---------------------------------------------------------------------------


func test_ac4_the_boost_burns_the_eight_rate_table_and_the_vanguard_exactly() -> void:
	var reference: float = ShipFitScript.engine_thrust_reference()
	var table := ""
	for hull_id: StringName in BOOST_RATES:
		var ship_pair := _launch(hull_id, {})
		var ship: Variant = ship_pair[0]
		if ship == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		var burn := float(ship.call(&"_boost_burn_rate"))
		table += "%s=%.3f " % [String(hull_id).trim_prefix("ship_"), burn]
		assert_true(
			absf(burn - float(BOOST_RATES[hull_id])) <= RATE_TOLERANCE,
			"%s: the boost burn is section 13's rate (%.2f/s, got %.4f)"
			% [hull_id, float(BOOST_RATES[hull_id]), burn]
		)
	var vanguard_burn_pair := _launch(HULL_SHIPPED, {})
	var vanguard_ship: Variant = vanguard_burn_pair[0]
	assert_true(
		vanguard_ship != null and is_equal_approx(float(vanguard_ship.call(&"_boost_burn_rate")), 3.0),
		"the unfitted Vanguard's burn anchors the row at exactly 3.0/s"
	)
	print("[S227] AC4 boost rates %s| vanguard=3.000 (anchor, thrust %.3f)" % [table, reference])
	assert_true(
		is_equal_approx(reference, 110.0 * 428.0 / (2.4 * ShipFitScript.ACCEL_TIME_MULT)),
		"and the anchor is the Vanguard's own class-row thrust"
	)


## The live gate: one second of afterburner on the unfitted Vanguard spends exactly
## 3.0 fuel, and the dash's receipt is 25 x base_mass / 110 on the two section 13 rows.
func test_ac4_the_live_burn_and_the_dash_receipt() -> void:
	var pair := _launch(HULL_SHIPPED, {})
	var ship: Variant = pair[0]
	var state: Variant = pair[2]
	if ship == null or state == null:
		assert_true(false, "the Vanguard fixture did not build")
		return
	assert_true(bool(ship.call(&"_burn_boost_fuel", 1.0)), "a full tank pays for a second")
	assert_true(
		is_equal_approx(float(state.fuel), 197.0),
		"one second of afterburner burns exactly BOOST_FUEL_REF 3.0 (got %.4f)" % float(state.fuel)
	)
	assert_eq(float(state.fuel_max), 200.0, "fuel_max stays the flat 200 (M5 kept flat)")
	for hull_id: StringName in DASH_EXPECTATIONS:
		var dash_pair := _launch(hull_id, {})
		var dash_ship: Variant = dash_pair[0]
		if dash_ship == null:
			assert_true(false, "%s: the dash fixture did not build" % hull_id)
			continue
		var dash := float(dash_ship.call(&"_dash_fuel"))
		assert_true(
			absf(dash - float(DASH_EXPECTATIONS[hull_id])) <= 0.05,
			"%s: the dash spends 25 x base_mass / 110 (%.1f, got %.4f)"
			% [hull_id, float(DASH_EXPECTATIONS[hull_id]), dash]
		)
		print("[S227] AC4 dash %s=%.4f" % [hull_id, dash])
	## And a plated composite launch cannot move the flat pool either.
	var composite: Variant = ShipFitScript.resolve(HULL_SHIPPED, {
		&"engines": [&"e_std"], &"power": &"p_std", &"armour": [&"h_composite"]
	})
	assert_true(
		composite != null and is_equal_approx(float(composite.fuel_max), 200.0),
		"the composite fit's fuel_max is still the flat 200"
	)


## ---------------------------------------------------------------------------
## AC5 - section 23.5's acceptance at the new law
## ---------------------------------------------------------------------------


## Released from a commanded forward+strafe at cruise, the bearing of travel holds
## within the pinned 5 degrees while the speed falls to a tenth, on the derived
## `0.9 x coast_time x fitted/base` ramp: one stop, one line. Measured on the shipped
## launch and on the composite fit -- the mass law's own worst case for the release.
func test_ac5_the_released_forward_strafe_holds_its_bearing_to_the_tenth() -> void:
	var composite_fit: Dictionary = {
		&"engines": [&"e_std"], &"power": &"p_std", &"armour": [&"h_composite"]
	}
	for launch_fit: Dictionary in [ShipFitScript.STANDARD_FIT, composite_fit]:
		var pair := _launch(HULL_SHIPPED, launch_fit)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "the hull fixture did not build")
			return
		var body: RigidBody2D = ship.impact_body()
		var dt := 1.0 / float(Engine.physics_ticks_per_second)
		var mass := float(body.mass)
		var damp := float(body.linear_damp)
		var heading := float(body.global_rotation)
		var position := Vector2.ZERO
		var velocity := Vector2.ZERO
		var ceiling := float(stats.max_speed)
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
		assert_true(cruised, "the commanded diagonal reached the class ceiling")
		if not cruised:
			return
		var release_bearing := velocity.angle()
		var max_drift := 0.0
		var max_cross := 0.0
		var tenth_time := -1.0
		var elapsed := 0.0
		var release_budget := int(
			float(stats.coast_time) * RELEASE_BUDGET_FACTOR * 60.0 + BUDGET_SLACK_SECONDS * 60.0
		)
		for i: int in range(release_budget):
			var force: Vector2 = _drive(ship, body, heading, position, velocity, dt)
			if velocity.length_squared() > 0.0 and force.length_squared() > 0.0:
				max_cross = maxf(
					max_cross, absf(force.normalized().cross(velocity.normalized()))
				)
			velocity = _integrate(velocity, force, mass, damp, dt)
			position += velocity * dt
			elapsed += dt
			max_drift = maxf(
				max_drift, absf(rad_to_deg(wrapf(velocity.angle() - release_bearing, -PI, PI)))
			)
			if velocity.length() <= RELEASE_SPEED_FRACTION * release_speed:
				tenth_time = elapsed
				break
		var derived := (
			0.9
			* (release_speed / ceiling)
			* float(stats.coast_time)
			* mass / float(stats.base_mass)
		)
		print(
			"[S227] AC5 stop v_release=%.3f drift=%.6f deg cross=%.9f t_tenth=%.4f derived=%.4f coast=%.4f"
			% [release_speed, max_drift, max_cross, tenth_time, derived, float(stats.coast_time)]
		)
		assert_true(
			max_drift <= DIRECTION_HOLD_MAX_DEGREES,
			"the bearing holds within 5 degrees to the tenth (measured %.4f)" % max_drift
		)
		assert_true(
			max_cross <= CROSS_FORCE_SHARE,
			"the release force stays antiparallel to the velocity (%.9f)" % max_cross
		)
		assert_true(
			_near(tenth_time, derived, ENVELOPE_TOLERANCE * derived),
			"one stop on the derived ramp (%.4f against %.4f s)" % [tenth_time, derived]
		)


## ---------------------------------------------------------------------------
## Helpers (the s2_6/s11 fixture shape: the runner never awaits a frame)
## ---------------------------------------------------------------------------


func _launch(hull_id: StringName, fit: Dictionary) -> Array:
	var stats: Variant = ShipFitScript.resolve(hull_id, fit)
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
	ship.global_position = Vector2.ZERO
	ship.global_rotation = 0.0
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return [ship, stats, state]


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the
## runner scene during `_ready` (see `test_engine2_fixes.gd`).
func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _drive(
	ship: Variant, body: RigidBody2D, heading: float, position: Vector2,
	velocity: Vector2, delta: float
) -> Vector2:
	body.global_rotation = heading
	body.angular_velocity = 0.0
	body.linear_velocity = velocity
	body.global_position = position
	ship.set_aim_point(body.global_position + Vector2.RIGHT.rotated(heading) * AIM_DISTANCE)
	ship.call(&"_physics_process", delta)
	return ship.call(&"applied_force")


func _tick(
	ship: Variant, body: RigidBody2D, heading: float, position: Vector2,
	velocity: Vector2, delta: float, mass: float
) -> Vector2:
	var force := _drive(ship, body, heading, position, velocity, delta)
	return _integrate(velocity, force, mass, float(body.linear_damp), delta)


func _integrate(
	velocity: Vector2, force: Vector2, mass: float, damp: float, delta: float
) -> Vector2:
	var out := velocity * (1.0 / (1.0 + damp * delta))
	out += force / mass * delta
	return out


## One released decay from `v0` along +x: the tenth point, the stop and the carried
## distance, integrated the way the engine orders the damp against the force.
func _released_envelope(ship: Variant, v0: Vector2) -> Dictionary:
	var body: RigidBody2D = ship.impact_body()
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var mass := float(body.mass)
	var damp := float(body.linear_damp)
	var heading := float(body.global_rotation)
	var position := Vector2.ZERO
	var velocity := v0
	var t_10 := -1.0
	var t_stop := -1.0
	var carry := 0.0
	var elapsed := 0.0
	var budget := int(30.0 * 60.0)
	for i: int in range(budget):
		var force: Vector2 = _drive(ship, body, heading, position, velocity, dt)
		velocity = _integrate(velocity, force, mass, damp, dt)
		position += velocity * dt
		elapsed += dt
		carry += velocity.length() * dt
		if t_10 < 0.0 and velocity.length() <= RELEASE_SPEED_FRACTION * v0.length():
			t_10 = elapsed
		if velocity.length() <= 1.0:
			t_stop = elapsed
			break
	return {&"t_10": t_10, &"t_stop": t_stop, &"carry": carry}


## The commanded ramp's time from rest to `target` speed along +x, integrated the
## same way (the composite AC2 row's acceleration figure).
func _ramp_time(ship: Variant, target: float) -> float:
	var body: RigidBody2D = ship.impact_body()
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var mass := float(body.mass)
	var damp := float(body.linear_damp)
	var heading := float(body.global_rotation)
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	_press(THRUST_FORWARD)
	var elapsed := 0.0
	var budget := int(30.0 * 60.0)
	for i: int in range(budget):
		var force: Vector2 = _drive(ship, body, heading, position, velocity, dt)
		velocity = _integrate(velocity, force, mass, damp, dt)
		position += velocity * dt
		elapsed += dt
		if velocity.length() >= target:
			_release_all()
			return elapsed
	_release_all()
	return -1.0


func _near(value: float, expected: float, tolerance: float) -> bool:
	return absf(value - expected) <= tolerance


func _press(action: StringName) -> void:
	Input.action_press(action)
	if not _pressed.has(action):
		_pressed.append(action)


func _release_all() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
