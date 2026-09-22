@tool
extends McpTestSuite
## Suite s2_6_flight: the construction half of the flight rulings (CONTRACTS section 14,
## owner 2026-09-22). The *timed* halves -- the accelerate leg, the release envelope, the
## revolution of a neutral turn, the sideways skid -- are measured by
## `tests/probe_s2_6_flight.tscn`, which a reviewer re-runs; this suite pins the laws those
## numbers are built from, one seam per ruling:
##
## 1. the multiplier pattern: `ACCEL_TIME_MULT` 2.0 on `accel_time` (and `max_speed` never
##    moves -- the ceiling is the loaded ceiling), `COAST_TIME_MULT` 2.0 on today's
##    `coast_time` rows (the documented revert of the combat wave's x 0.50, landing on
##    section 13's own column), `LATERAL_DAMP_MULT` 1.0 read as an explicit lateral drag;
## 2. the ramp: per class, the derived `t_90 = 0.9 x accel_time` doubles (>= 1.8 x the
##    wave-start row's own), which is AC5;
## 3. the decay split: forward is `1 / coast_time`, sideways is today's damp
##    (`COAST_TIME_MULT / coast_time` at `LATERAL_DAMP_MULT` 1.0), and the strafe axis
##    compensates the *sideways* one so a commanded strafe is not eaten by the new drag;
## 4. the steering: the cursor answers at zero throttle (`STEER_WITHOUT_THROTTLE`), a
##    deflected turn action still answers first, and a cursor resting on the hull still
##    holds the heading;
## 5. AC6: a full 360 degree cursor turn at zero throttle applies torque and **no central
##    force**, so the hull's displacement stays inside `TURN_TRANSLATE_LEAK_MAX` -- and a
##    manoeuvre is the mirror of itself steered the other way, within one percent.
##
## Nothing here awaits a frame: the headless runner calls a test method synchronously, so
## the suite drives `PlayerShip._physics_process` itself and reads the force the law applied
## through the hull's own `applied_force()` / `applied_torque()` seam (the same shape of
## observability accessor as `boost_activations`). The engine integrates a body only across
## a frame, so the suite sums the displacement itself; at a zero-throttle turn from rest
## every term of the law is multiplied by a zero velocity, which is why the two integrations
## agree exactly there (the probe measures the same acceptance through real frames).

const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const HULL_SHIPPED: StringName = &"ship_vanguard"
const PLATE: StringName = &"h_plate_light"
const THRUST_FORWARD: StringName = &"thrust_forward"
const STRAFE_LEFT: StringName = &"strafe_left"
const STRAFE_RIGHT: StringName = &"strafe_right"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"

## The handling column as this wave found it: the rows of `ShipFit.HANDLING`, which the two
## rulings act on through their multipliers. Quoted here so every assertion below is about
## the ruling rather than a copy of the shipped table.
const TODAY_HANDLING: Dictionary = {
	&"ship_fighter": {&"max_speed": 450.0, &"accel_time": 2.0, &"coast_time": 0.8},
	&"ship_vanguard": {&"max_speed": 428.0, &"accel_time": 2.4, &"coast_time": 1.0},
	&"ship_miner": {&"max_speed": 338.0, &"accel_time": 4.0, &"coast_time": 1.7},
	&"ship_trader": {&"max_speed": 383.0, &"accel_time": 3.0, &"coast_time": 1.3},
	&"ship_corvette": {&"max_speed": 495.0, &"accel_time": 2.2, &"coast_time": 0.9},
	&"ship_freighter": {&"max_speed": 293.0, &"accel_time": 6.0, &"coast_time": 2.6},
	&"ship_gunship": {&"max_speed": 360.0, &"accel_time": 4.4, &"coast_time": 1.9},
	&"ship_patrol": {&"max_speed": 383.0, &"accel_time": 4.0, &"coast_time": 1.7},
	&"ship_destroyer": {&"max_speed": 315.0, &"accel_time": 6.4, &"coast_time": 2.8},
}

## AC5's floor: the accelerate leg has to grow by at least 1.8 x. The pinned
## `ACCEL_TIME_MULT` is 2.0, so the measured ratio sits on top of the floor with the
## sampling grid's own slack to spare.
const RAMP_GROWTH_FLOOR := 1.8

## One revolution of the slowest class is 8.4 s; the budget is roughly double that, and the
## loop bails out on it rather than spinning forever on a broken tree (L82).
const NEUTRAL_TURN_BUDGET := 20.0
const MIRROR_TOLERANCE := 0.01
const AIM_DISTANCE := 4000.0
## One second of strafing, the mirror pair's own bounded manoeuvre.
const LEAN_SECONDS := 1.0
## A turn faster than one radian of bearing error commands the class's full `turn_rate`, so
## a cursor 90 degrees off the bow is always a saturated command.
const QUARTER_TURN := PI * 0.5
const TOLERANCE := 1e-6
## Float32 lives in every `Vector2` the body carries, so a force comparison against a
## derived figure of a few thousand newtons carries ~2.4e-5 of rounding per component.
const FORCE_TOLERANCE := 1e-2

## A `Vector2` stores float32 components, so a velocity set along one axis carries about
## 1e-7 of rounding into the other -- and a chase law amplifies that by `1 / delta` (the same
## reason G1's suite keeps a 1e-3 stick tolerance). A "nothing on this axis" reading is
## therefore compared against a share of the force's own magnitude, not against zero.
const AXIS_SHARE := 1e-5

var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func suite_name() -> String:
	return "s2_6_flight"


func teardown() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## 1. The multipliers, and the ceiling they never touch
## ---------------------------------------------------------------------------


func test_the_ruling_multipliers_are_the_pinned_constants() -> void:
	assert_true(
		is_equal_approx(ShipFitScript.ACCEL_TIME_MULT, 2.0),
		"the accelerate leg's multiplier is 2.0"
	)
	assert_true(
		is_equal_approx(ShipFitScript.COAST_TIME_MULT, 2.0),
		"the release's multiplier is 2.0 (today's rows x 2.0 = section 13's column)"
	)
	assert_true(
		is_equal_approx(ShipFitScript.LATERAL_DAMP_MULT, 1.0),
		"the sideways decay keeps today's damp exactly (the split's own multiplier)"
	)
	assert_true(
		PlayerShipScript.STEER_WITHOUT_THROTTLE,
		"the cursor steers without the throttle (the W-gate is the reversal, not the shipped law)"
	)
	assert_true(
		is_equal_approx(PlayerShipScript.TURN_TRANSLATE_LEAK_MAX, 5.0),
		"the neutral turn's displacement bound is the pinned 5.0 u"
	)


## AC5's construction half, per class: the *resolved* accelerate leg is today's row times
## `ACCEL_TIME_MULT` times the fit's own plating multiplier, and the hull's ceiling is
## untouched by it -- which is what makes the derived time to 90 % of `max_speed` grow by
## the multiplier and nothing else. Measured end to end by `probe_s2_6_flight.tscn`
## (Vanguard t_90 2.283 -> 4.550 s, ratio 1.99; every class within 1 % of the multiplier).
func test_the_accelerate_leg_doubles_per_class_and_the_ceiling_never_moves() -> void:
	var speed_penalty := float(ShipFitScript.MODULES[PLATE][&"effects"][&"speed_penalty"])
	## Plating pays twice (09 section 3.3): a speed *penalty* on the ceiling and a
	## multiplier on the handling times.
	var plating := 1.0 + absf(speed_penalty)
	var checked := 0
	for hull_id: StringName in TODAY_HANDLING:
		var row: Dictionary = TODAY_HANDLING[hull_id]
		var stats: Variant = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
		if stats == null:
			assert_true(false, "%s: the shipped fit did not resolve" % hull_id)
			continue
		var handling: Dictionary = ShipFitScript.HANDLING[hull_id]
		assert_true(
			_near(float(handling[&"accel_time"]), float(row[&"accel_time"])),
			"%s: the row itself is still today's accelerate leg (the multiplier is the seam)" % hull_id
		)
		assert_true(
			_near(
				float(stats.accel_time),
				float(row[&"accel_time"]) * ShipFitScript.ACCEL_TIME_MULT * plating,
				TOLERANCE
			),
			(
				"%s: the resolved accelerate leg is the row x %.2f x the plating multiplier (got %.4f)"
				% [hull_id, ShipFitScript.ACCEL_TIME_MULT, float(stats.accel_time)]
			)
		)
		assert_true(
			_near(float(stats.max_speed), float(row[&"max_speed"]) * (1.0 + speed_penalty), TOLERANCE),
			(
				"%s: max_speed never moves -- the ceiling is the row x the plating penalty (got %.3f)"
				% [hull_id, float(stats.max_speed)]
			)
		)
		## The two times the ramp is derived from, with the ruling applied on one side only:
		## t_90 is 90 % of the accelerate leg (the chase is a linear ramp at
		## `max_speed / accel_time`), so its ratio is the multiplier's own -- the plating
		## multiplier is on both sides and cancels.
		var before := 0.9 * float(row[&"accel_time"]) * plating
		var after := 0.9 * float(stats.accel_time)
		var growth := after / before
		assert_true(
			growth >= RAMP_GROWTH_FLOOR - TOLERANCE,
			"%s: t_90 grows x %.4f, at or above the %.1f floor" % [hull_id, growth, RAMP_GROWTH_FLOOR]
		)
		assert_true(
			_near(growth, ShipFitScript.ACCEL_TIME_MULT, 1e-9),
			"%s: and the growth is the multiplier itself, not a second number" % hull_id
		)
		checked += 1
	assert_eq(checked, TODAY_HANDLING.size(), "every class of the handling column was measured")


## The forward/lateral split (CONTRACTS section 14's `LATERAL_DAMP_MULT`), per class:
## - the resolved `coast_time` is today's row back on section 13's column
##   (`COAST_TIME_MULT`), and the body damps at `1 / coast_time` -- the *forward* decay;
## - the sideways decay is today's damp, unchanged: `COAST_TIME_MULT x LATERAL_DAMP_MULT`
##   over the resolved time, which is exactly the wave-start `1 / today's coast_time`;
## - the explicit lateral drag is the difference between the two, and it is a drag, not a
##   counter-force: the sideways velocity is what it multiplies.
## Measured by the probe: the lateral release's t_10 is identical before and after
## (Vanguard 2.383 s both runs) while the axial release's doubles (0.917 vs 0.450 s).
func test_the_forward_carry_reverts_and_the_sideways_decay_does_not() -> void:
	var penalty := absf(float(ShipFitScript.MODULES[PLATE][&"effects"][&"speed_penalty"]))
	var plating := 1.0 + penalty
	for hull_id: StringName in TODAY_HANDLING:
		var row: Dictionary = TODAY_HANDLING[hull_id]
		var pair := _launch(hull_id)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		assert_true(
			_near(
				float(stats.coast_time),
				float(row[&"coast_time"]) * ShipFitScript.COAST_TIME_MULT * plating,
				TOLERANCE
			),
			(
				"%s: the resolved coast time is today's row x %.2f x the plating multiplier (got %.4f)"
				% [hull_id, ShipFitScript.COAST_TIME_MULT, float(stats.coast_time)]
			)
		)
		var forward := float(ship.call(&"_linear_damp"))
		var sideways := float(ship.call(&"_lateral_damp"))
		var extra := float(ship.call(&"_lateral_extra_damp"))
		assert_true(
			_near(forward, 1.0 / float(stats.coast_time), TOLERANCE),
			"%s: the body's own damp is 1 / coast_time, the forward carry" % hull_id
		)
		var today_damp := 1.0 / (float(row[&"coast_time"]) * plating)
		assert_true(
			_near(sideways, today_damp * ShipFitScript.LATERAL_DAMP_MULT, TOLERANCE),
			(
				"%s: the sideways decay is today's damp (%.6f), whatever the forward revert did (got %.6f)"
				% [hull_id, today_damp, sideways]
			)
		)
		assert_true(
			sideways > forward,
			("%s: the sideways axis decays faster than the forward one, which is the split" % hull_id)
		)
		assert_true(
			_near(sideways / forward, ShipFitScript.COAST_TIME_MULT / ShipFitScript.LATERAL_DAMP_MULT, 1e-9),
			"%s: the two decays differ by the ruling's own ratio, not by a second constant" % hull_id
		)
		assert_true(
			_near(extra, sideways - forward, TOLERANCE) and extra > 0.0,
			(
				"%s: the explicit lateral drag is the difference between the two (%.6f)"
				% [hull_id, extra]
			)
		)
		## The body carries the forward damp (the engine's own axis-agnostic drag), so the
		## drag the ruling adds is the only sideways term left over.
		var body: RigidBody2D = ship.impact_body()
		assert_true(
			_near(body.linear_damp, forward, TOLERANCE),
			"%s: the body damps at the forward rate" % hull_id
		)
		assert_eq(
			body.linear_damp_mode,
			RigidBody2D.DAMP_MODE_REPLACE,
			"%s: and still replaces the project default rather than adding to it" % hull_id
		)


## ---------------------------------------------------------------------------
## 2. The steering ruling: the cursor answers at zero throttle
## ---------------------------------------------------------------------------


## The route itself (F2's cure). At zero throttle, with the cursor 90 degrees off the bow,
## the hull's commanded turn is the cursor's own bearing law -- at HEAD this returned 0.0
## and the only way to turn was to hold `thrust_forward`, which is what pushed the parked
## hull forward. A deflected turn action still answers first (a pad axis or a re-bind), and
## a cursor resting on the hull -- where the camera's centre puts it -- still holds the
## heading through the deadzone, which is why the ruling does not make the nose wander.
func test_the_cursor_steers_at_zero_throttle() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	for side: float in [1.0, -1.0]:
		var point: Vector2 = (
			ship.global_position
			+ Vector2(AIM_DISTANCE, 0.0).rotated(float(ship.global_rotation) + QUARTER_TURN * side)
		)
		ship.call(&"set_aim_point", point)
		var aim := float(ship.call(&"_aim_turn"))
		assert_true(
			_near(absf(aim), float(stats.turn_rate), 1e-5),
			(
				"a cursor 90 degrees off the bow commands the full class rate with no throttle (%.4f)"
				% aim
			)
		)
		assert_true(
			_near(float(ship.call(&"_manual_desired_turn", 0.0, 0.0)), aim, TOLERANCE),
			"and the manual turn is that aim turn with the throttle at zero (the W-gate is gone)"
		)
		assert_true(
			_near(float(ship.call(&"_manual_desired_turn", 1.0, 0.0)), aim, TOLERANCE),
			"holding the throttle commands the same turn, not a different one"
		)
		assert_true(
			_near(float(ship.call(&"_manual_desired_turn", 0.0, side)), float(stats.turn_rate) * side, 1e-5),
			"a deflected turn action still answers first, without any throttle at all"
		)
	## The deadzone: a cursor on the hull commands nothing, which is what holds a heading the
	## pilot is not steering.
	ship.call(&"set_aim_point", ship.global_position)
	assert_true(
		is_zero_approx(float(ship.call(&"_manual_desired_turn", 0.0, 0.0))),
		"a cursor resting on the hull holds the heading with the throttle released"
	)
	assert_true(
		is_zero_approx(float(ship.call(&"_aim_turn"))),
		"and that is the aim law's own hull-radius deadzone, not the throttle"
	)
	## The throttle is what the ruling decoupled: with the throttle at zero the *thrust* is
	## zero, so the turn is torque on its own.
	assert_true(
		(ship.call(&"_command_velocity", 0.0, 0.0) as Vector2).is_zero_approx(),
		"a zeroed stick commands a zero velocity, which is what makes the turn torque-only"
	)


## ---------------------------------------------------------------------------
## 3. AC6: the neutral turn, torque only
## ---------------------------------------------------------------------------


## A full 360 degree cursor turn at zero throttle, on the route the owner has: the suite
## imposes the turn (the heading advances at the class's own `turn_rate`, which is the rate
## the law settles at) and the cursor is re-placed 90 degrees off the bow every frame, so the
## law commands the turn on every step. What is *measured* is the law's own reaction: the
## central force and the torque it hands the body. Torque only means the force is zero on
## every step, and the hull the engine would integrate therefore never moves -- the probe
## reads 0.000000 u of displacement over 360.6 degrees through real frames.
func test_a_neutral_turn_applies_torque_only_and_does_not_translate() -> void:
	for hull_id: StringName in [HULL_SHIPPED, &"ship_fighter", &"ship_freighter"]:
		var pair := _launch(hull_id)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		for direction: float in [1.0, -1.0]:
			var flown := _fly_neutral_turn(ship, stats, direction)
			assert_true(
				float(flown[&"sweep"]) >= TAU,
				(
					"%s: the imposed turn really was a full revolution (%.1f degrees over %d steps)"
					% [hull_id, rad_to_deg(float(flown[&"sweep"])), int(flown[&"steps"])]
				)
			)
			assert_true(
				float(flown[&"torque"]) > 0.0,
				"%s: the law answered the turn with torque on the way round" % hull_id
			)
			assert_true(
				is_zero_approx(float(flown[&"max_force"])),
				(
					"%s: no central force was applied on any step of the turn (largest %.9f N)"
					% [hull_id, float(flown[&"max_force"])]
				)
			)
			assert_true(
				float(flown[&"displacement"]) <= PlayerShipScript.TURN_TRANSLATE_LEAK_MAX,
				(
					"%s: the summed displacement %.6f u is inside the pinned %.1f u"
					% [hull_id, float(flown[&"displacement"]), PlayerShipScript.TURN_TRANSLATE_LEAK_MAX]
				)
			)
			assert_true(
				is_zero_approx(float(flown[&"speed"])),
				"%s: and the hull's speed never left zero (%.9f u/s)" % [hull_id, float(flown[&"speed"])]
			)


## The mirrored manoeuvre half of AC6: the same turn steered the other way, and a commanded
## strafe pair, must be each other's mirror within one percent. The neutral turn's own pair
## is symmetric by construction (both sides apply no force at all); the strafe pair is the
## non-vacuous one -- it applies a real lateral force, and a single-sided term anywhere in
## the thrust path (the new lateral drag included) shows up here and nowhere else.
func test_mirrored_maneuvers_mirror_within_one_percent() -> void:
	for hull_id: StringName in [HULL_SHIPPED, &"ship_fighter"]:
		var pair := _launch(hull_id)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		var right := _fly_neutral_turn(ship, stats, 1.0)
		var left := _fly_neutral_turn(ship, stats, -1.0)
		assert_true(
			_relative(float(right[&"sweep"]), float(left[&"sweep"])) <= MIRROR_TOLERANCE,
			"%s: both neutral turns sweep the same arc" % hull_id
		)
		assert_true(
			_relative(float(right[&"displacement"]), float(left[&"displacement"])) <= MIRROR_TOLERANCE,
			"%s: and displace the hull equally (both zero)" % hull_id
		)
		assert_true(
			_relative(float(right[&"torque"]), float(left[&"torque"])) <= MIRROR_TOLERANCE,
			"%s: the torque histories mirror (%.3f against %.3f)" % [hull_id, right[&"torque"], left[&"torque"]]
		)
		## The commanded pair: D for a second, then A for a second, from rest. The forces the
		## law applies at each step have to be exact mirrors of one another, and the
		## trajectories they build (the suite's own integration of the same forces) have to be
		## mirror images.
		var strafe_right := _fly_strafe(ship, stats, 1.0)
		var strafe_left := _fly_strafe(ship, stats, -1.0)
		assert_true(
			float(strafe_right[&"max_force"]) > 0.0 and float(strafe_left[&"max_force"]) > 0.0,
			"%s: the mirrored strafes really did apply force (%.3f / %.3f N)"
			% [hull_id, strafe_right[&"max_force"], strafe_left[&"max_force"]]
		)
		assert_true(
			_relative(float(strafe_right[&"max_force"]), float(strafe_left[&"max_force"]))
			<= MIRROR_TOLERANCE,
			"%s: the mirrored strafes push equally hard" % hull_id
		)
		assert_true(
			_relative(float(strafe_right[&"distance"]), float(strafe_left[&"distance"]))
			<= MIRROR_TOLERANCE,
			(
				"%s: and travel the same distance sideways (%.4f against %.4f u)"
				% [hull_id, strafe_right[&"distance"], strafe_left[&"distance"]]
			)
		)


## ---------------------------------------------------------------------------
## 4. The axis laws, at the force seam
## ---------------------------------------------------------------------------


## What each axis' chase law hands the body, read off `applied_force()` -- the split's
## construction, and the proof that the new lateral drag is compensated rather than masked:
## - a commanded strafe compensates the *sideways* damp, so a hull still reaches its class
##   ceiling sideways in 90 % of `accel_time` (the probe's G1 sibling measures the arrival);
## - the released sideways velocity is dragged down by the explicit lateral drag alone, at
##   today's rate, with no counter-force opposing the velocity's own direction.
func test_each_axis_compensates_its_own_damp() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	var body: RigidBody2D = ship.impact_body()
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var mass := float(body.mass)
	var nose := Vector2.RIGHT.rotated(float(body.global_rotation))
	var side := Vector2.RIGHT.rotated(float(body.global_rotation) + QUARTER_TURN)
	var forward_damp := float(ship.call(&"_linear_damp"))
	var sideways_damp := float(ship.call(&"_lateral_damp"))
	var extra := float(ship.call(&"_lateral_extra_damp"))
	var rate := float(ship.call(&"_accel_rate"))

	## 1. A commanded strafe, at a nonzero sideways velocity: the force is the sideways
	##    chase with *that* axis' total damp compensated, plus the explicit drag (the two
	##    are applied in the same step and the seam records their sum). What has to hold is
	##    the engine's own arithmetic: the drag the law adds and the body damp the engine
	##    applies cancel, leaving the chase at the class rate.
	_press(STRAFE_RIGHT)
	var sideways_velocity := 40.0
	body.linear_velocity = side * sideways_velocity
	_drive(ship, dt)
	var strafe_force: Vector2 = ship.call(&"applied_force")
	_release_all()
	var chase := clampf(
		(float(stats.max_speed) - sideways_velocity) / dt, -rate, rate
	)
	var expected_sum := mass * (chase + sideways_damp * sideways_velocity - extra * sideways_velocity)
	assert_true(
		strafe_force.dot(side) > 0.0,
		"the strafe pushes towards the hull's right (%.3f N)" % strafe_force.dot(side)
	)
	assert_true(
		_near(strafe_force.dot(side), expected_sum, FORCE_TOLERANCE),
		(
			"and the step's whole sideways force is the chase plus the drag (%.3f against a derived %.3f N)"
			% [strafe_force.dot(side), expected_sum]
		)
	)
	## The reading that matters: net of the body's own damp -- which the engine applies to the
	## velocity too -- the strafe accelerates at the class's own rate, so a commanded strafe
	## still reaches the class ceiling in 90 % of `accel_time`.
	assert_true(
		_near(
			strafe_force.dot(side) / mass - forward_damp * sideways_velocity,
			chase,
			FORCE_TOLERANCE
		),
		"net of the body damp the chase is the class rate (%.3f u/s^2)" % chase
	)
	assert_true(
		absf(strafe_force.dot(nose)) <= AXIS_SHARE * strafe_force.length(),
		(
			"the strafe is lateral: nothing along the nose (%.6f N of %.1f)"
			% [strafe_force.dot(nose), strafe_force.length()]
		)
	)

	## 2. Released, the same sideways velocity is dragged down by the explicit lateral drag,
	##    which is the difference between the two decays and nothing else.
	body.linear_velocity = side * sideways_velocity
	_drive(ship, dt)
	var drag: Vector2 = ship.call(&"applied_force")
	assert_true(
		_near(drag.dot(side), -mass * extra * sideways_velocity, FORCE_TOLERANCE),
		(
			"a released skid is dragged at the ruling's own rate (%.3f against a derived %.3f N)"
			% [drag.dot(side), -mass * extra * sideways_velocity]
		)
	)
	assert_true(
		drag.dot(side) < 0.0,
		"and the drag opposes the sideways velocity itself, so it is not a counter-force"
	)

	## 3. The nose axis is unchanged by the split: the released forward carry brakes at the
	##    class coast rate, and the forward damp (not the sideways one) is what is
	##    compensated inside the chase.
	var forward_velocity := 100.0
	body.linear_velocity = nose * forward_velocity
	_drive(ship, dt)
	var forward_force: Vector2 = ship.call(&"applied_force")
	var coast_rate := float(stats.max_speed) / float(stats.coast_time)
	assert_true(
		_near(
			forward_force.dot(nose),
			mass * clampf(-forward_velocity / dt, -coast_rate, coast_rate) + mass * forward_damp * forward_velocity,
			FORCE_TOLERANCE
		),
		"the nose axis rides the forward damp and the coast rate (%.3f N)" % forward_force.dot(nose)
	)
	assert_true(
		absf(forward_force.dot(side)) <= AXIS_SHARE * forward_force.length(),
		"and a pure forward velocity is not dragged sideways"
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## One step of the law, with the suite playing the physics server: the hull's state is set,
## the shipped `_physics_process` runs for one frame, and the force and torque it applied are
## read back through the hull's own seam. Nothing here awaits a frame (the runner never does)
## and nothing about the law is re-implemented: the suite only decides the state to feed it.
func _drive(ship: Variant, delta: float) -> void:
	ship.call(&"_physics_process", delta)


## The neutral turn, flown by the law: the heading advances at the class's own `turn_rate`
## (the law's own bound, so the turn is one the hull could really perform), the cursor is kept
## 90 degrees off the bow and re-placed every frame, and the force/torque the law applies are
## accumulated. The displacement is the suite's own integration of that force -- the engine
## integrates a body only across a frame, and the probe reads the same acceptance through real
## frames.
func _fly_neutral_turn(ship: Variant, stats: Variant, direction: float) -> Dictionary:
	var body: RigidBody2D = ship.impact_body()
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var rate := float(stats.turn_rate)
	var budget := int(NEUTRAL_TURN_BUDGET * Engine.physics_ticks_per_second)
	var heading := float(body.global_rotation)
	var sweep := 0.0
	var velocity := Vector2.ZERO
	var position := Vector2.ZERO
	var max_force := 0.0
	var torque_total := 0.0
	var steps := 0
	while sweep < TAU and steps < budget:
		body.global_rotation = heading
		body.angular_velocity = direction * rate
		body.linear_velocity = velocity
		body.global_position = position
		ship.set_aim_point(
			ship.global_position + Vector2.RIGHT.rotated(heading + QUARTER_TURN * direction) * AIM_DISTANCE
		)
		_drive(ship, dt)
		var force: Vector2 = ship.call(&"applied_force")
		var torque := float(ship.call(&"applied_torque"))
		max_force = maxf(max_force, force.length())
		torque_total += absf(torque)
		velocity += force / float(body.mass) * dt
		position += velocity * dt
		heading += direction * rate * dt
		sweep += rate * dt
		steps += 1
	return {
		&"sweep": sweep,
		&"displacement": position.length(),
		&"speed": velocity.length(),
		&"max_force": max_force,
		&"torque": torque_total,
		&"steps": steps,
	}


## A commanded strafe, one second of it, flown the same way: the lateral force the law
## applies is what makes the manoeuvre, and the suite integrates it so the two directions can
## be compared as trajectories and not only as forces.
func _fly_strafe(ship: Variant, stats: Variant, direction: float) -> Dictionary:
	var body: RigidBody2D = ship.impact_body()
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var budget := int(LEAN_SECONDS * Engine.physics_ticks_per_second)
	var heading := float(body.global_rotation)
	var velocity := Vector2.ZERO
	var position := Vector2.ZERO
	var peak_force := 0.0
	_press(STRAFE_RIGHT if direction > 0.0 else STRAFE_LEFT)
	for i: int in range(budget):
		body.global_rotation = heading
		body.angular_velocity = 0.0
		body.linear_velocity = velocity
		body.global_position = position
		ship.set_aim_point(ship.global_position + Vector2.RIGHT.rotated(heading) * AIM_DISTANCE)
		_drive(ship, dt)
		var force: Vector2 = ship.call(&"applied_force")
		peak_force = maxf(peak_force, force.length())
		velocity += force / float(body.mass) * dt
		position += velocity * dt
	_release_all()
	return {
		&"max_force": peak_force,
		&"distance": position.length(),
		&"speed": velocity.length(),
	}


## One launched hull, the fixture the G1 and C3 suites use.
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


func _near(measured: float, expected: float, tolerance: float = TOLERANCE) -> bool:
	return absf(measured - expected) <= tolerance


## The difference between two readings relative to the larger of them, with two zeros
## defined as mirrored exactly (a neutral turn really does displace nothing on both sides,
## and dividing by zero is not the way to say so).
func _relative(a: float, b: float) -> float:
	var scale := maxf(absf(a), absf(b))
	if is_zero_approx(scale):
		return 0.0
	return absf(a - b) / scale
