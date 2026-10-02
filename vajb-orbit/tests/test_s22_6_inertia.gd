extends McpTestSuite
## Suite s22_6_inertia: wave S22.6's magnitude tick (owner-ticked 2026-09-30), one row
## per acceptance item. The wave moves exactly three constants -- `ShipFit.COAST_TIME_MULT`
## 2.5 -> 5.0 (18 §13's Hull release coast row; CONTRACTS §22 T1 / §23.5 T1) and the rock
## pair `Asteroid.LINEAR_DAMP` 3.71 -> 0.35 with the new `FRAGMENT_LINEAR_DAMP` 0.25
## (18 §13's Rock drift damping row) -- and touches nothing else.
##
##   AC1 - the release coast: 5.0, the nine rows land on 4.0-14.0 s, and the shipped
##         Vanguard's envelope is the class's own `max_speed / coast_time` ramp;
##   AC2 - §23.5's acceptance still holds at the new rate: a released forward+strafe keeps
##         its bearing inside 5° to a tenth of the release, on one line;
##   AC3 - the two rock damps reach the bodies they own (a field spawn 0.35, a cleave child
##         and a splinter 0.25, all `DAMP_MODE_REPLACE`) and the row's targets measure out;
##   AC4 - a rock at rest is at rest, and a rammed rock's carry moves from its own width to
##         hundreds of units;
##   AC5 - no other gameplay number moved (each with its reader);
##   AC6 - the shipped constants match the pinned rows, reversals included;
##   AC7 - the by-name readers survive: the identities `test_engine2_cleaving.gd:267`,
##         `test_s7_affixes.gd:72,366,376` and the probes read are unchanged.
##
## The runner never awaits a frame (a coroutine's tail would be skipped), so the two ship
## rows drive the shipped `_physics_process` one tick at a time and integrate the force it
## applied through the hull's `applied_force()` seam -- the `test_s11_flight_stop.gd`
## pattern, with the engine's own damp-then-force integration. The rock rows model the
## physics server's discrete linear damp, `v *= 1 - damp * delta`, then `x += v * delta`,
## which `tests/probe_s22_6_inertia.tscn` measures frame by frame against the real bodies:
## the model reproduces every probe reading to the printed decimal (kick 150 u/s at 0.35:
## 105.595 u/s after one second, 397.69 u to the 10 u/s line, 424.65 u total).

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const HULL: StringName = &"ship_vanguard"
const PLATE: StringName = &"h_plate_light"
const THRUST_FORWARD: StringName = &"thrust_forward"
const STRAFE_RIGHT: StringName = &"strafe_right"

## CONTRACTS §23.5's recorded reading at the 2.5 constant (the S22 row): a Vanguard
## released at 200 u/s reads t_10 = 1.150 s. AC1 asks for the new reading against it.
const S22_RECORDED_T10 := 1.150
const SIGNAL_SPEED := 200.0
## The acceptance's window ends at a tenth of the release speed (§23.5's own fraction).
const RELEASE_FRACTION := 0.1
## The stop lands on the resolved coast time inside this many 60 Hz ticks.
const STOP_TICKS := 2
## The envelope assertions: 2 % covers the 60 Hz sampling grid and the float32 body.
const ENVELOPE_TOLERANCE := 0.02
const CRUISE_TOLERANCE := 0.002
const DIRECTION_HOLD_MAX_DEGREES := 5.0
const CROSS_FORCE_SHARE := 1e-4
const AIM_DISTANCE := 4000.0
const SETTLE_BUDGET := 40.0
const REST_SECONDS := 6.0
const CRUISE_BUDGET_FACTOR := 2.0
const BUDGET_SLACK_FRAMES := 60.0

## The rock row's own targets (18 §13, verbatim): a 150 u/s kick reads ~106 u/s after one
## second and carries ~429 u, a child ~600 u, and the worst ram's 409 u/s settles in ~10.6 s.
const KICK_SPEED := 150.0
const RAM_HANDOFF_SPEED := 409.0
const KICK_TARGET_SPEED_1S := 106.0
const KICK_TARGET_CARRY := 429.0
const CHILD_TARGET_CARRY := 600.0
const RAM_TARGET_SETTLE := 10.6
## The superseded derivation's own constant (18 §13: "Supersedes the 3.71"), the before row.
const SUPERSEDED_LINEAR_DAMP := 3.71
## "Settled" for the model: the superseded ceiling line and a near-zero tail.
const SETTLE_CEILING := 10.0
const SETTLE_FLOOR := 0.5

## The wave-start handling column: every row field AC5 must find untouched.
const WAVE_START_HANDLING: Dictionary = {
	&"ship_fighter": {
		&"max_speed": 450.0, &"accel_time": 2.0, &"coast_time": 0.8,
		&"turn_rate": 1.7, &"turn_spinup": 0.4, &"hull_mass": 80.0,
	},
	&"ship_vanguard": {
		&"max_speed": 428.0, &"accel_time": 2.4, &"coast_time": 1.0,
		&"turn_rate": 1.5, &"turn_spinup": 0.5, &"hull_mass": 110.0,
	},
	&"ship_miner": {
		&"max_speed": 338.0, &"accel_time": 4.0, &"coast_time": 1.7,
		&"turn_rate": 1.0, &"turn_spinup": 1.0, &"hull_mass": 140.0,
	},
	&"ship_trader": {
		&"max_speed": 383.0, &"accel_time": 3.0, &"coast_time": 1.3,
		&"turn_rate": 1.2, &"turn_spinup": 0.7, &"hull_mass": 160.0,
	},
	&"ship_corvette": {
		&"max_speed": 495.0, &"accel_time": 2.2, &"coast_time": 0.9,
		&"turn_rate": 1.6, &"turn_spinup": 0.45, &"hull_mass": 90.0,
	},
	&"ship_freighter": {
		&"max_speed": 293.0, &"accel_time": 6.0, &"coast_time": 2.6,
		&"turn_rate": 0.75, &"turn_spinup": 1.4, &"hull_mass": 260.0,
	},
	&"ship_gunship": {
		&"max_speed": 360.0, &"accel_time": 4.4, &"coast_time": 1.9,
		&"turn_rate": 0.95, &"turn_spinup": 1.0, &"hull_mass": 190.0,
	},
	&"ship_patrol": {
		&"max_speed": 383.0, &"accel_time": 4.0, &"coast_time": 1.7,
		&"turn_rate": 1.05, &"turn_spinup": 0.9, &"hull_mass": 220.0,
	},
	&"ship_destroyer": {
		&"max_speed": 315.0, &"accel_time": 6.4, &"coast_time": 2.8,
		&"turn_rate": 0.8, &"turn_spinup": 1.2, &"hull_mass": 300.0,
	},
}

## S14's split table, the anti-drift yardstick `test_s14_splits.gd` pins (kept so AC5's
## "the split table" row has a second copy it cannot drift from).
const PINNED_SPLIT_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}

const FIELD_SEED := 22601

var _staged: Array[Node] = []
var _fields: Array[Node] = []
var _pressed: Array[StringName] = []
var _dt := 1.0 / 60.0


func suite_name() -> String:
	return "s22_6_inertia"


func setup() -> void:
	_dt = 1.0 / float(Engine.physics_ticks_per_second)


func teardown() -> void:
	_release_all()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()
	for field: Node in _fields:
		if is_instance_valid(field) and not field.is_queued_for_deletion():
			field.free()
	_fields.clear()
	## A case that tuned the ore surface must not leak into the next suite.
	OreTuningScript.reset_to_defaults()


## ---------------------------------------------------------------------------
## AC1 - the release coast: 5.0, the nine rows, the Vanguard's measured envelope
## ---------------------------------------------------------------------------


func test_ac1_the_release_coast_is_five_seconds_and_lands_on_the_rows_envelope() -> void:
	assert_true(
		is_equal_approx(ShipFitScript.COAST_TIME_MULT, 5.0),
		"S22.6's tick: COAST_TIME_MULT is 5.0 (was 2.5)"
	)
	var penalty := absf(float(ShipFitScript.MODULES[PLATE][&"effects"][&"speed_penalty"]))
	var plating := 1.0 + penalty
	var unplated: Array[String] = []
	for raw_key: Variant in ShipFitScript.HANDLING.keys():
		var hull_id := StringName(raw_key)
		var row: Dictionary = ShipFitScript.HANDLING[hull_id]
		var resolved := float(row[&"coast_time"]) * ShipFitScript.COAST_TIME_MULT
		assert_true(
			resolved >= 4.0 and resolved <= 14.0,
			"%s: the row resolves to %.2f s inside 4.0-14.0" % [hull_id, resolved]
		)
		var stats: Variant = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
		assert_true(
			_near(float(stats.coast_time), resolved, 1e-6),
			"%s: the resolved coast is the row x 5.0 (plating pays in mass since S22.7)" % hull_id
		)
		assert_true(
			_near(float(stats.hull_mass), float(row[&"hull_mass"]) * plating, 1e-6),
			"%s: and the plate's ponderous half rides the mass (x%.2f)" % [hull_id, plating]
		)
		unplated.append("%s=%.2f" % [String(hull_id).trim_prefix("ship_"), resolved])
	print("[S226] AC1 rows %s" % " ".join(unplated))

	var pair := _launch(HULL)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the Vanguard fixture did not build")
		return
	var coast := float(stats.coast_time)
	var ceiling := float(stats.max_speed)
	## S22.7's mass law: the release ramp rides the resolved coast time scaled by
	## the fit's own mass ratio (fitted/base) -- the plate's ponderous half is
	## mass now, and the heavier fit coasts proportionally further.
	var body: RigidBody2D = ship.call(&"impact_body")
	var coast_ramp := coast * float(body.mass) / float(stats.base_mass)
	var at_ceiling := _released_envelope(ship, Vector2(ceiling, 0.0))
	var derived_t_10 := 0.9 * coast_ramp
	assert_true(
		_near(float(at_ceiling[&"t_10"]), derived_t_10, ENVELOPE_TOLERANCE * coast_ramp),
		(
			"released at the ceiling %.1f u/s the tenth point is 0.9 x coast_time x fitted/base = %.3f s (measured %.3f)"
			% [ceiling, derived_t_10, at_ceiling[&"t_10"]]
		)
	)
	assert_true(
		absf(float(at_ceiling[&"t_stop"]) - coast_ramp) <= float(STOP_TICKS) * _dt,
		"the stop lands on the mass-scaled coast time %.3f s (measured %.3f)" % [coast_ramp, at_ceiling[&"t_stop"]]
	)
	var derived_carry := 0.5 * ceiling * coast_ramp
	assert_true(
		_near(float(at_ceiling[&"carry"]), derived_carry, ENVELOPE_TOLERANCE * derived_carry),
		(
			"the carried distance is 0.5 x v0 x coast_time x fitted/base = %.2f u (measured %.2f)"
			% [derived_carry, at_ceiling[&"carry"]]
		)
	)
	var from_200 := _released_envelope(ship, Vector2(SIGNAL_SPEED, 0.0))
	var ratio := float(from_200[&"t_10"]) / S22_RECORDED_T10
	assert_true(
		ratio >= 1.9 and ratio <= 2.1,
		(
			"a 200 u/s release's t_10 %.3f s is ~2x S22's recorded %.3f s (x %.3f)"
			% [from_200[&"t_10"], S22_RECORDED_T10, ratio]
		)
	)
	print(
		(
			"[S226] AC1 vanguard v0=%.2f coast=%.3f t_10=%.3f derived=%.3f t_stop=%.3f "
			+ "carry=%.2f derived=%.2f | at200 t_10=%.3f (S22 %.3f, x%.2f)"
		)
		% [
			ceiling,
			coast,
			at_ceiling[&"t_10"],
			derived_t_10,
			at_ceiling[&"t_stop"],
			at_ceiling[&"carry"],
			derived_carry,
			from_200[&"t_10"],
			S22_RECORDED_T10,
			ratio,
		]
	)
	print(
		"[S226] AC1 row_of_record 0.8 x 5.0 = 4.0 s at 427.5 u/s -> 855 u (plating lifts the shipped pair to 4.2 s / ~894 u)"
	)


## ---------------------------------------------------------------------------
## AC2 - §23.5's acceptance at the new rate: one stop, one line
## ---------------------------------------------------------------------------


func test_ac2_the_released_forward_strafe_holds_its_bearing_to_the_tenth() -> void:
	var pair := _launch(HULL)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the Vanguard fixture did not build")
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	var mass := float(body.mass)
	var damp := float(body.linear_damp)
	var ceiling := float(stats.max_speed)
	var position: Vector2 = body.global_position
	var velocity := Vector2.ZERO
	## 1. The commanded diagonal W+D: the stick clamps to the ceiling, so the release
	##    speed is the class's own ceiling and each axis half of it.
	_press(THRUST_FORWARD)
	_press(STRAFE_RIGHT)
	var cruised := false
	var cruise_budget := int(float(stats.accel_time) * CRUISE_BUDGET_FACTOR / _dt + BUDGET_SLACK_FRAMES)
	for i: int in range(cruise_budget):
		velocity = _tick(ship, body, position, velocity, mass, damp)
		position += velocity * _dt
		if i > 1 and velocity.length() >= ceiling * (1.0 - CRUISE_TOLERANCE):
			cruised = true
			break
	_release_all()
	if not cruised:
		assert_true(false, "the commanded diagonal never reached %.1f u/s" % ceiling)
		return
	var release_speed := velocity.length()
	var release_bearing := velocity.angle()
	## 2. The release: no input at all, so the whole velocity is what decays.
	var max_drift := 0.0
	var max_cross := 0.0
	var t_10 := -1.0
	var elapsed := 0.0
	for _i: int in range(int(SETTLE_BUDGET / _dt)):
		var force := _drive(ship, body, position, velocity)
		if velocity.length_squared() > 0.0 and force.length_squared() > 0.0:
			max_cross = maxf(max_cross, absf(force.normalized().cross(velocity.normalized())))
		velocity = _integrate(velocity, force, mass, damp)
		position += velocity * _dt
		elapsed += _dt
		max_drift = maxf(
			max_drift, absf(rad_to_deg(wrapf(velocity.angle() - release_bearing, -PI, PI)))
		)
		if velocity.length() <= RELEASE_FRACTION * release_speed:
			t_10 = elapsed
			break
	## The derived tenth point (S22.7's mass law): the whole velocity ramps to
	## zero at the class coast rate scaled by the fit's mass ratio, so the tenth
	## is `0.9 x (v_release / max_speed) x coast_time x fitted/base`.
	var derived := (
		0.9
		* (release_speed / ceiling)
		* float(stats.coast_time)
		* mass / float(stats.base_mass)
	)
	print(
		(
			"[S226] AC2 v_release=%.3f drift=%.6f deg cross_share=%.9f t_10=%.4f derived=%.4f coast=%.3f"
			% [
				release_speed,
				max_drift,
				max_cross,
				t_10,
				derived,
				float(stats.coast_time),
			]
		)
	)
	assert_true(
		t_10 > 0.0,
		"the release reached the tenth of %.1f u/s inside the budget" % release_speed
	)
	assert_true(
		max_drift <= DIRECTION_HOLD_MAX_DEGREES,
		(
			"the bearing holds within %.0f degrees while the speed falls to a tenth (measured %.6f)"
			% [DIRECTION_HOLD_MAX_DEGREES, max_drift]
		)
	)
	assert_true(
		max_cross <= CROSS_FORCE_SHARE,
		"the decay force is antiparallel to the velocity on every tick (%.9f)" % max_cross
	)
	assert_true(
		_near(t_10, derived, ENVELOPE_TOLERANCE * derived),
		"the two components decay as one line: t_10 %.4f against the derived %.4f" % [t_10, derived]
	)


## ---------------------------------------------------------------------------
## AC3 - the two rock damps, their bodies, and the row's targets
## ---------------------------------------------------------------------------


func test_ac3_the_two_rock_damps_reach_field_children_and_splinters() -> void:
	assert_true(
		is_equal_approx(AsteroidScript.LINEAR_DAMP, 0.35),
		"18 §13's Rock drift row: a field rock's LINEAR_DAMP is 0.35 (was 3.71)"
	)
	assert_true(
		is_equal_approx(AsteroidScript.FRAGMENT_LINEAR_DAMP, 0.25),
		"and FRAGMENT_LINEAR_DAMP is 0.25 for a cleave child and a splinter"
	)
	assert_true(
		is_equal_approx(AsteroidScript.DRIFT_SPEED_CEILING, SETTLE_CEILING),
		"the superseded 10 u/s ceiling stays in the file as the record (18 §13)"
	)
	var field := _solo_field()
	var rock := _member(field, AsteroidScript.SIZE_MEDIUM, 2, "Original")
	assert_true(
		_near(float(rock.linear_damp), AsteroidScript.LINEAR_DAMP, 1e-6),
		"a field spawn carries LINEAR_DAMP"
	)
	assert_eq(
		rock.linear_damp_mode,
		RigidBody2D.DAMP_MODE_REPLACE,
		"and the mode still replaces the project default"
	)
	var parent := _member(field, AsteroidScript.SIZE_LARGE, 4, "Parent")
	var before: Array[Node2D] = field.call(&"rocks") as Array[Node2D]
	parent.call(&"apply_work", 9999.0)
	var children: Array[Node2D] = []
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(candidate):
			children.append(candidate)
	assert_true(children.size() >= 1, "the L parent cleaved into children")
	for child: Node2D in children:
		assert_true(
			_near(float(child.linear_damp), AsteroidScript.FRAGMENT_LINEAR_DAMP, 1e-6),
			(
				"the cleave child %s carries FRAGMENT_LINEAR_DAMP (got %.4f)"
				% [child.name, child.linear_damp]
			)
		)
		assert_eq(
			(child as RigidBody2D).linear_damp_mode,
			RigidBody2D.DAMP_MODE_REPLACE,
			"and the debris damp replaces too"
		)
	var shedder := _member(field, AsteroidScript.SIZE_LARGE, 4, "Shedder")
	var before_splinter: Array[Node2D] = field.call(&"rocks") as Array[Node2D]
	field.call(&"_spawn_splinter", shedder)
	var splinters: Array[Node2D] = []
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before_splinter.has(candidate):
			splinters.append(candidate)
	assert_true(splinters.size() == 1, "the splinter path spawned one S body")
	if splinters.size() == 1:
		assert_true(
			_near(float(splinters[0].linear_damp), AsteroidScript.FRAGMENT_LINEAR_DAMP, 1e-6),
			"the S22.5 splinter carries FRAGMENT_LINEAR_DAMP (got %.4f)" % splinters[0].linear_damp
		)
	var kick := _drift_model(KICK_SPEED, float(AsteroidScript.LINEAR_DAMP))
	var child := _drift_model(KICK_SPEED, float(AsteroidScript.FRAGMENT_LINEAR_DAMP))
	assert_true(
		_near(float(kick[&"speed_1s"]), KICK_TARGET_SPEED_1S, 1.0),
		"a 150 u/s kick reads ~106 u/s after one second (measured %.3f)" % kick[&"speed_1s"]
	)
	assert_true(
		_near(float(kick[&"carry_total"]), KICK_TARGET_CARRY, ENVELOPE_TOLERANCE * KICK_TARGET_CARRY),
		"and carries ~429 u before settling (measured %.2f)" % kick[&"carry_total"]
	)
	assert_true(
		_near(float(child[&"carry_total"]), CHILD_TARGET_CARRY, ENVELOPE_TOLERANCE * CHILD_TARGET_CARRY),
		"a cleave child on 0.25 carries ~600 u (measured %.2f)" % child[&"carry_total"]
	)
	print(
		(
			"[S226] AC3 children=%d splinters=%d kick v1s=%.3f carry_10=%.2f carry=%.2f "
			+ "child v1s=%.3f carry_10=%.2f carry=%.2f (real-frame twin: probe_s22_6_inertia)"
		)
		% [
			children.size(),
			splinters.size(),
			kick[&"speed_1s"],
			kick[&"carry_10"],
			kick[&"carry_total"],
			child[&"speed_1s"],
			child[&"carry_10"],
			child[&"carry_total"],
		]
	)


## ---------------------------------------------------------------------------
## AC4 - a rock at rest is at rest; a rammed rock carries its own width no longer
## ---------------------------------------------------------------------------


func test_ac4_a_rock_at_rest_stays_and_a_ram_carries_ten_times_further() -> void:
	var field := _solo_field()
	var rock := _member(field, AsteroidScript.SIZE_MEDIUM, 2, "Rest")
	assert_true(is_zero_approx(float(rock.gravity_scale)), "space: no gravity pulls it")
	assert_true(not rock.can_sleep, "and it can always answer a contact")
	var rest := _drift_model(0.0, float(AsteroidScript.LINEAR_DAMP))
	assert_true(
		is_zero_approx(float(rest[&"carry_total"])),
		(
			"a rock at rest moves %.6f u in %.0f s -- the damp law has rest as its fixed point"
			% [rest[&"carry_total"], REST_SECONDS]
		)
	)
	var shipped := _drift_model(RAM_HANDOFF_SPEED, float(AsteroidScript.LINEAR_DAMP))
	var superseded := _drift_model(RAM_HANDOFF_SPEED, SUPERSEDED_LINEAR_DAMP)
	var ratio := float(shipped[&"carry_total"]) / maxf(float(superseded[&"carry_total"]), 1e-9)
	assert_true(
		ratio >= 10.0,
		(
			"a 409 u/s hand-off carries %.2f u against %.2f u at the superseded 3.71 (x %.2f)"
			% [shipped[&"carry_total"], superseded[&"carry_total"], ratio]
		)
	)
	assert_true(
		_near(
			float(shipped[&"t_10"]),
			log(RAM_HANDOFF_SPEED / SETTLE_CEILING) / float(AsteroidScript.LINEAR_DAMP),
			ENVELOPE_TOLERANCE * RAM_TARGET_SETTLE
		),
		"and settles to the 10 u/s line in ~10.6 s (measured %.3f)" % shipped[&"t_10"]
	)
	print(
		(
			"[S226] AC4 rest_moved=%.6f s=%.1f | ram v0=%.0f shipped carry_10=%.2f carry=%.2f "
			+ "t_10=%.3f | superseded carry_10=%.2f carry=%.2f t_10=%.3f ratio=x%.2f"
		)
		% [
			rest[&"carry_total"],
			REST_SECONDS,
			RAM_HANDOFF_SPEED,
			shipped[&"carry_10"],
			shipped[&"carry_total"],
			shipped[&"t_10"],
			superseded[&"carry_10"],
			superseded[&"carry_total"],
			superseded[&"t_10"],
			ratio,
		]
	)


## ---------------------------------------------------------------------------
## AC5 - no other gameplay number moved
## ---------------------------------------------------------------------------


func test_ac5_no_other_gameplay_number_moved() -> void:
	for raw_key: Variant in WAVE_START_HANDLING.keys():
		var hull_id := StringName(raw_key)
		var row: Dictionary = ShipFitScript.HANDLING.get(hull_id, {})
		var before: Dictionary = WAVE_START_HANDLING[hull_id]
		for key: StringName in before.keys():
			assert_true(
				is_equal_approx(float(row.get(key, -1.0)), float(before[key])),
				"%s.%s is the wave-start %s (got %s)" % [hull_id, key, before[key], row.get(key, "?")]
			)
	assert_true(is_equal_approx(ShipFitScript.ACCEL_TIME_MULT, 2.0), "ACCEL_TIME_MULT 2.0 (resolve)")
	assert_true(is_equal_approx(ShipFitScript.LATERAL_DAMP_MULT, 1.0), "LATERAL_DAMP_MULT 1.0 (retired)")
	assert_true(is_equal_approx(ShipFitScript.ANGULAR_DAMP_MULT, 0.5), "ANGULAR_DAMP_MULT 0.5 (_angular_damp)")
	assert_true(is_equal_approx(PlayerShipScript.BRAKE_MULT, 1.8), "BRAKE_MULT 1.8 (the S-thrust rate)")
	assert_true(is_equal_approx(AsteroidScript.WORK_PER_UNIT, 1.0), "WORK_PER_UNIT 1.0 (_accumulate)")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2), "FRAGMENT_EJECT_MULT 1.2 (eject_velocity)")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0), "the eject cone 360 (the field's roll)")
	assert_true(
		is_equal_approx(AsteroidScript.ROCK_MASS_DENSITY * 42.0 * 42.0, 560.0),
		"the M class anchors the density law at 560 t (ROCK_MASS_DENSITY x 42^2, _configure_body)"
	)
	assert_true(is_equal_approx(FieldScript.FRAGMENT_OUTWARD_KICK, 50.0), "FRAGMENT_OUTWARD_KICK 50, the 2026-10-01 fix round's ÷3 (_deploy_debris)")
	assert_true(is_equal_approx(FieldScript.FRAGMENT_ANGLE_JITTER, 0.25), "FRAGMENT_ANGLE_JITTER 0.25 (_cleave)")
	assert_true(is_equal_approx(OreTuningScript.gun_chip_rate, 0.10), "gun_chip_rate 0.10 (the gun door)")
	assert_true(is_equal_approx(OreTuningScript.work_per_unit, 1.0), "OreTuning work_per_unit 1.0 (_accumulate)")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, 0.25), "fragment_core_share 0.25 (setup)")
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10), "gun_burst_share 0.10 (_cleave)")
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_SPLIT_MIX), "the S14 split table is pinned")
	print(
		(
			"[S226] AC5 untouched max_speed/accel_time/turn_rate/turn_spinup/hull_mass (9 rows), "
			+ "BRAKE_MULT=1.8 ANGULAR_DAMP_MULT=0.5 gun_chip_rate=0.10 work_per_unit=1.0 "
			+ "split_mix=pinned"
		)
	)


## ---------------------------------------------------------------------------
## AC6 - the shipped constants against the pinned rows and their reversals
## ---------------------------------------------------------------------------


func test_ac6_the_shipped_constants_match_the_pinned_rows() -> void:
	var rows := [
		[&"COAST_TIME_MULT", float(ShipFitScript.COAST_TIME_MULT), 5.0, 2.5],
		[&"LINEAR_DAMP", float(AsteroidScript.LINEAR_DAMP), 0.35, 3.71],
		[&"FRAGMENT_LINEAR_DAMP", float(AsteroidScript.FRAGMENT_LINEAR_DAMP), 0.25, 3.71],
	]
	for row: Array in rows:
		assert_true(
			is_equal_approx(float(row[1]), float(row[2])),
			"%s ships 18 §13's %.2f (got %.4f)" % [row[0], row[2], row[1]]
		)
		assert_false(
			is_equal_approx(float(row[2]), float(row[3])),
			"%s carries its reversal %.2f, a real change" % [row[0], row[3]]
		)
	print(
		"[S226] AC6 coast=5.0 (rev 2.5) linear_damp=0.35 (rev 3.71) fragment_damp=0.25 (rev 3.71)"
	)


## ---------------------------------------------------------------------------
## AC7 - the rows that read a constant by name survive untouched
## ---------------------------------------------------------------------------


func test_ac7_the_by_name_readers_see_the_same_law() -> void:
	var field := _solo_field()
	var rock := _member(field, AsteroidScript.SIZE_MEDIUM, 2, "ByName")
	assert_true(
		_near(float(rock.linear_damp), AsteroidScript.LINEAR_DAMP, 1e-6),
		"test_engine2_cleaving.gd:267 compares a field rock's damp to Asteroid.LINEAR_DAMP -- same law"
	)
	var parent := _member(field, AsteroidScript.SIZE_LARGE, 4, "ProbeFix")
	var before: Array[Node2D] = field.call(&"rocks") as Array[Node2D]
	parent.call(&"apply_work", 9999.0)
	var marked := 0
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if before.has(candidate):
			continue
		assert_true(
			_near(float(candidate.linear_damp), AsteroidScript.FRAGMENT_LINEAR_DAMP, 1e-6),
			"every cleave child follows FRAGMENT_LINEAR_DAMP, not a copy of it (got %.4f)" % candidate.linear_damp
		)
		marked += 1
	assert_true(marked >= 1, "the debris identity is exercised (%d children)" % marked)
	var split_mix: Dictionary = AsteroidScript.FRAGMENT_SPLIT
	assert_eq(
		split_mix[AsteroidScript.SIZE_MEDIUM],
		Vector2i(2, 5),
		"the retired FRAGMENT_SPLIT row the frozen rock probes read is untouched"
	)
	var vanguard: Variant = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	assert_true(
		_near(
			float(vanguard.coast_time),
			float(ShipFitScript.HANDLING[&"ship_vanguard"][&"coast_time"])
			* ShipFitScript.COAST_TIME_MULT,
			1e-6
		),
		"test_s7_affixes.gd:72,366,376 read COAST_TIME_MULT by name -- the identity holds"
	)
	print(
		(
			"[S226] AC7 by_name linear_damp=%.4f fragment_damp=%.4f children=%d "
			+ "(test_engine2_cleaving:267, test_s7_affixes:72/366/376, the probes)"
		)
		% [rock.linear_damp, AsteroidScript.FRAGMENT_LINEAR_DAMP, marked]
	)


## ---------------------------------------------------------------------------
## Fixtures and the two models
## ---------------------------------------------------------------------------


## The physics server's discrete linear damp, one tick at a time: `v *= 1 - damp * dt` then
## `x += v * dt` -- the order `probe_s22_6_inertia` measures against the live bodies (the
## kick's 105.595 u/s after one second reproduces the probe's own decimal).
func _drift_model(v0: float, damp: float) -> Dictionary:
	var v := v0
	var x := 0.0
	var t := 0.0
	var speed_1s := -1.0
	var t_10 := -1.0
	var carry_10 := -1.0
	var budget := REST_SECONDS * 10.0 + 60.0
	while t < budget:
		v = v * (1.0 - damp * _dt)
		x += v * _dt
		t += _dt
		if speed_1s < 0.0 and t >= 1.0 - _dt * 0.5:
			speed_1s = v
		if t_10 < 0.0 and v <= SETTLE_CEILING and v0 > SETTLE_CEILING:
			t_10 = t
			carry_10 = x
		if v <= SETTLE_FLOOR:
			break
	return {
		&"speed_1s": maxf(speed_1s, 0.0),
		&"t_10": maxf(t_10, 0.0),
		&"carry_10": maxf(carry_10, 0.0),
		&"carry_total": x,
	}


## The whole-velocity release envelope, driven through the shipped law: one
## `_physics_process` per tick with the body's state set, the force it applied read off
## `applied_force()`, then the engine's own integration -- damp first, then the force.
func _released_envelope(ship: Variant, release_velocity: Vector2) -> Dictionary:
	var body: RigidBody2D = ship.call(&"impact_body")
	var mass := float(body.mass)
	var damp := float(body.linear_damp)
	var position: Vector2 = body.global_position
	var velocity := release_velocity
	var start := velocity.length()
	var travelled := 0.0
	var t := 0.0
	var t_10 := -1.0
	var dist_10 := -1.0
	var t_stop := -1.0
	while t < SETTLE_BUDGET:
		var force := _drive(ship, body, position, velocity)
		velocity = _integrate(velocity, force, mass, damp)
		position += velocity * _dt
		travelled += velocity.length() * _dt
		t += _dt
		if t_10 < 0.0 and velocity.length() <= RELEASE_FRACTION * start:
			t_10 = t
			dist_10 = travelled
		if velocity.length() <= SETTLE_FLOOR:
			t_stop = t
			break
	return {
		&"t_10": t_10,
		&"dist_10": dist_10,
		&"t_stop": t_stop,
		&"carry": travelled,
	}


## One driven step of the whole law: the body's state is set, the aim pinned dead ahead,
## the shipped `_physics_process` runs for one tick and the force it applied is returned.
func _drive(ship: Variant, body: RigidBody2D, position: Vector2, velocity: Vector2) -> Vector2:
	body.global_rotation = 0.0
	body.angular_velocity = 0.0
	body.linear_velocity = velocity
	body.global_position = position
	ship.call(&"set_aim_point", position + Vector2.RIGHT * AIM_DISTANCE)
	ship.call(&"_physics_process", _dt)
	return ship.call(&"applied_force")


func _tick(
	ship: Variant, body: RigidBody2D, position: Vector2, velocity: Vector2, mass: float, damp: float
) -> Vector2:
	return _integrate(velocity, _drive(ship, body, position, velocity), mass, damp)


## The engine's linear integration, as `probe_s2_6_flight` pins it: the damp is the
## `1 / (1 + damp * delta)` form, applied before the step's force.
func _integrate(velocity: Vector2, force: Vector2, mass: float, damp: float) -> Vector2:
	var out := velocity * (1.0 / (1.0 + damp * _dt))
	out += force / mass * _dt
	return out


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
	var host := _host()
	host.add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_staged.append(ship)
	return [ship, stats]


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the runner
## scene during `_ready` (the `test_s11_flight_stop.gd` host).
func _host() -> Node:
	var root := (Engine.get_main_loop() as SceneTree).root
	var profile := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return profile if profile != null else root


## A field with its own generation rocks freed, so a case's fixtures are the only rocks.
func _solo_field(seed_value: int = FIELD_SEED) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {&"tier_weights": {1: 100}, &"rocks": 1, &"seed": seed_value})
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		rock.free()
	_fields.append(field)
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


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
