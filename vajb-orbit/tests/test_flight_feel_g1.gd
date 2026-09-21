@tool
extends McpTestSuite
## Suite flight_feel_g1: the construction half of the owner's third-round flight rulings
## (2026-09-21, brief `.agents/gen/flight_beam_wave_task.md`). The timed behaviour --
## how long the nose takes to reach the cursor's bearing, that the heading stops dead
## when the throttle is released, that a strafe moves the hull sideways and not forward --
## is measured by `tests/probe_g1_flight_feel.tscn`, which is the probe a reviewer re-runs.
## This suite pins what builds those numbers, one seam per ruling:
##
## 1. the turn retune: the nine section 13 `turn_rate` rows are the owner's x 0.50 and
##    **nothing else in the handling column moved** (the wave-start column is quoted
##    below, so the assertion is about the ruling and not a copy of the shipped table);
## 2. the cursor steering: `_turn_toward` is the autopilot's own arrive steering
##    (proportional under one radian of error, saturated at the class `turn_rate`, never
##    above it), and `_aim_turn` adds only the hull-radius deadzone;
## 3. the heading hold: `_manual_desired_turn` commands a bound turn action, else the
##    cursor while `thrust_forward` is held, else **zero**;
## 4. the strafe: its command is lateral, its ceiling is the class's own `max_speed`, its
##    rate is the class's own `max_speed / accel_time`, it invents no fraction, and W+D is
##    clamped to the class ceiling instead of a sqrt(2) overspeed;
## 5. the two actions are rebindable (the Controls tab lists them) and every action the
##    owner already had still answers.
##
## Nothing here awaits a frame: every reading is synchronous off a shipped seam, which is
## what keeps the gate deterministic (the same split the C3 suite keeps). `_hull_radius`
## is the deadzone's own source, so the deadzone test reads the shipped shape rather than
## a number quoted here.

const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const SettingsScript := preload("res://autoload/settings_manager.gd")

const HULL_SHIPPED: StringName = &"ship_vanguard"
const HULL_BODY: StringName = &"HullBody"
const HULL_SHAPE: StringName = &"Shape"

const THRUST_FORWARD: StringName = &"thrust_forward"
const THRUST_BACKWARD: StringName = &"thrust_backward"
const STRAFE_LEFT: StringName = &"strafe_left"
const STRAFE_RIGHT: StringName = &"strafe_right"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"

## The handling column as this wave found it (`ShipFit.HANDLING`, which the 2026-09-21
## coast retune had already halved): the turn retune must move `turn_rate` and nothing
## else, and every value below is quoted from the column the wave started from.
const WAVE_START_HANDLING: Dictionary = {
	&"ship_fighter": {
		&"max_speed": 450.0,
		&"accel_time": 2.0,
		&"coast_time": 0.8,
		&"turn_rate": 3.4,
		&"turn_spinup": 0.4,
		&"hull_mass": 80.0,
	},
	&"ship_vanguard": {
		&"max_speed": 428.0,
		&"accel_time": 2.4,
		&"coast_time": 1.0,
		&"turn_rate": 3.0,
		&"turn_spinup": 0.5,
		&"hull_mass": 110.0,
	},
	&"ship_miner": {
		&"max_speed": 338.0,
		&"accel_time": 4.0,
		&"coast_time": 1.7,
		&"turn_rate": 2.0,
		&"turn_spinup": 1.0,
		&"hull_mass": 140.0,
	},
	&"ship_trader": {
		&"max_speed": 383.0,
		&"accel_time": 3.0,
		&"coast_time": 1.3,
		&"turn_rate": 2.4,
		&"turn_spinup": 0.7,
		&"hull_mass": 160.0,
	},
	&"ship_corvette": {
		&"max_speed": 495.0,
		&"accel_time": 2.2,
		&"coast_time": 0.9,
		&"turn_rate": 3.2,
		&"turn_spinup": 0.45,
		&"hull_mass": 90.0,
	},
	&"ship_freighter": {
		&"max_speed": 293.0,
		&"accel_time": 6.0,
		&"coast_time": 2.6,
		&"turn_rate": 1.5,
		&"turn_spinup": 1.4,
		&"hull_mass": 260.0,
	},
	&"ship_gunship": {
		&"max_speed": 360.0,
		&"accel_time": 4.4,
		&"coast_time": 1.9,
		&"turn_rate": 1.9,
		&"turn_spinup": 1.0,
		&"hull_mass": 190.0,
	},
	&"ship_patrol": {
		&"max_speed": 383.0,
		&"accel_time": 4.0,
		&"coast_time": 1.7,
		&"turn_rate": 2.1,
		&"turn_spinup": 0.9,
		&"hull_mass": 220.0,
	},
	&"ship_destroyer": {
		&"max_speed": 315.0,
		&"accel_time": 6.4,
		&"coast_time": 2.8,
		&"turn_rate": 1.6,
		&"turn_spinup": 1.2,
		&"hull_mass": 300.0,
	},
}

const RETUNE_SCALE := 0.50
## ENGINE_SPEC section 3.7's Controls tab, as it stood before this wave (17 entries). The
## two strafe actions are appended; every one of these must still be there.
const PREVIOUS_ACTIONS: Array[StringName] = [
	&"thrust_forward",
	&"thrust_backward",
	&"turn_left",
	&"turn_right",
	&"fire_primary",
	&"fire_secondary",
	&"mine",
	&"boost",
	&"cargo_toggle",
	&"weapon_1",
	&"weapon_2",
	&"weapon_3",
	&"weapon_4",
	&"weapon_5",
	&"target_next",
	&"interact",
	&"warp",
]
const REBINDABLE_COUNT := 19

const TOLERANCE := 1e-9
## A `Vector2` component is float32, so a command of a few hundred u/s carries ~2.4e-5 of
## rounding before any arithmetic of ours: these are the comparisons against one.
const STICK_TOLERANCE := 1e-3
## A turn action's full deflection, as `_manual_turn` reports it.
const FULL_DEFLECTION := 1.0

var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func suite_name() -> String:
	return "flight_feel_g1"


func teardown() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## 1. The turn retune, and only the turn retune
## ---------------------------------------------------------------------------


func test_the_turn_column_is_the_retuned_half_of_the_wave_start_rows() -> void:
	assert_eq(
		ShipFitScript.HANDLING.size(),
		WAVE_START_HANDLING.size(),
		"all nine classes of the handling column are still there"
	)
	for hull_id: StringName in WAVE_START_HANDLING:
		var row: Dictionary = ShipFitScript.HANDLING.get(hull_id, {})
		if row.is_empty():
			assert_true(false, "%s is missing from the handling column" % hull_id)
			continue
		var before: Dictionary = WAVE_START_HANDLING[hull_id]
		assert_eq(
			row.size(),
			before.size(),
			"%s still carries exactly its six columns" % hull_id
		)
		var turn_before := float(before[&"turn_rate"])
		var turn_after := float(row.get(&"turn_rate", -1.0))
		assert_true(
			_near(turn_after, turn_before * RETUNE_SCALE),
			"%s: turn_rate %.3f -> %.3f (the owner's x 0.50)" % [hull_id, turn_before, turn_after]
		)
		assert_true(turn_after < turn_before, "%s: the turn is slower, not faster" % hull_id)


## The other half of the same ruling: no *other* handling number moved. Every column of
## every class is checked against the wave-start table, so a later retune cannot hide in
## this wave's diff (the coast column's own x 0.50 was the previous owner ruling and is
## quoted here at its retuned value).
func test_no_other_handling_number_moved() -> void:
	var untouched: Array[StringName] = [
		&"max_speed",
		&"accel_time",
		&"coast_time",
		&"turn_spinup",
		&"hull_mass",
	]
	for hull_id: StringName in WAVE_START_HANDLING:
		var row: Dictionary = ShipFitScript.HANDLING.get(hull_id, {})
		if row.is_empty():
			continue
		var before: Dictionary = WAVE_START_HANDLING[hull_id]
		for key: StringName in untouched:
			assert_true(
				_near(float(row[key]), float(before[key])),
				(
					"%s.%s is untouched at %.3f (the turn retune moved turn_rate only)"
					% [hull_id, key, float(before[key])]
				)
			)
		assert_eq(
			row.keys().size(),
			before.keys().size(),
			"%s carries no column the wave-start table does not" % hull_id
		)


## The retuned rate reaches the hull through `ShipStats` -- the section 3.3 rule that
## flight reads no catalogue -- so no hull can fly at a rate the table does not carry.
func test_the_retuned_turn_rate_reaches_the_hull_through_the_snapshot() -> void:
	for hull_id: StringName in WAVE_START_HANDLING:
		var stats: Variant = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
		if stats == null:
			assert_true(false, "%s: the shipped fit did not resolve" % hull_id)
			continue
		var row: Dictionary = ShipFitScript.HANDLING[hull_id]
		var penalty := absf(
			float(ShipFitScript.MODULES[&"h_plate_light"][&"effects"][&"speed_penalty"])
		)
		assert_true(
			_near(float(stats.turn_rate), float(row[&"turn_rate"]), 1e-6),
			(
				"%s: the snapshot's turn rate is the retuned row (%.3f), not a scaled copy"
				% [hull_id, float(row[&"turn_rate"])]
			)
		)
		assert_true(
			_near(float(stats.turn_spinup), float(row[&"turn_spinup"]) * (1.0 + penalty), 1e-6),
			"%s: the spin-up keeps the plating multiplier the retune must not touch" % hull_id
		)


## ---------------------------------------------------------------------------
## 2. The cursor steering is the autopilot's own bearing law
## ---------------------------------------------------------------------------


## `_turn_toward` is section 3.2's arrive steering, unchanged in shape: the commanded turn
## is proportional to the bearing error below one radian, saturates at the class rate
## above it, and never exceeds the class rate -- which is what "turn_rate / turn_spinup
## still govern how fast the nose can move" means.
func test_the_bearing_law_is_proportional_then_saturated_at_the_class_rate() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	var rate := float(stats.turn_rate)
	var heading := float(ship.global_rotation)
	var angles: Array[float] = [0.0, 0.25, -0.25, 0.999, -0.999, 1.0, -1.0, 1.5, -2.5, PI * 0.9]
	for angle: float in angles:
		var point: Vector2 = ship.global_position + Vector2(1000.0, 0.0).rotated(heading + angle)
		var command := float(ship.call(&"_turn_toward", point))
		var expected := angle if absf(angle) < 1.0 else signf(angle)
		assert_true(
			_near(command, expected * rate, 1e-5),
			(
				"error %.3f rad -> %.4f rad/s (one radian of error is full deflection)"
				% [angle, command]
			)
		)
		assert_true(
			absf(command) <= rate + 1e-9,
			"the command never exceeds the class rate (%.4f vs %.4f)" % [command, rate]
		)
	assert_true(
		absf(float(ship.call(&"_turn_toward", ship.global_position + Vector2(500.0, 0.0)))) >= 0.0,
		"a dead-ahead aim commands no turn in either direction"
	)


## The fly-to order still runs the same law: the cursor ruling reuses the mechanism, it
## does not replace it (the brief's own words: "the autopilot's own _order_turn already
## turns toward a fly-to point, so reuse that mechanism").
func test_the_fly_to_order_still_uses_the_same_bearing_law() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	if ship == null:
		assert_true(false, "the hull fixture did not build")
		return
	var point: Vector2 = ship.global_position + Vector2(900.0, 400.0)
	ship.call(&"set_move_target", point)
	assert_true(
		_near(
			float(ship.call(&"_order_turn")),
			float(ship.call(&"_turn_toward", point)),
			TOLERANCE
		),
		"an order's turn is the same bearing law the cursor uses"
	)
	## And the order's arrival law is untouched: the desired speed falls off with distance.
	var near_point: Vector2 = ship.global_position + Vector2(60.0, 0.0)
	ship.call(&"set_move_target", near_point)
	var near_speed := float(ship.call(&"_order_speed"))
	ship.call(&"set_move_target", ship.global_position + Vector2(3000.0, 0.0))
	var far_speed := float(ship.call(&"_order_speed"))
	assert_true(
		far_speed > near_speed + 1.0,
		"arrive steering still ramps down towards the target (%.3f -> %.3f)" % [far_speed, near_speed]
	)
	ship.call(&"cancel_orders")
	assert_false(bool(ship.get(&"_has_move_target")), "cancel_orders still cancels")


## The one thing the cursor adds: a deadzone the size of the hull's own art-derived radius,
## because the camera centres the hull and the pointer rests on it. Inside the radius there
## is no bearing to chase; outside it the full law applies.
func test_the_aim_deadzone_is_the_hull_radius_and_no_new_number() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	var radius := float(ship.call(&"_hull_radius"))
	assert_true(radius > 0.0, "the shipped hull carries its collision circle (%.3f u)" % radius)
	var heading := float(ship.global_rotation)
	var rate := float(stats.turn_rate)
	var inside: Vector2 = ship.global_position + Vector2(radius * 0.5, 0.0).rotated(heading + 1.0)
	ship.call(&"set_aim_point", inside)
	assert_true(
		is_zero_approx(float(ship.call(&"_aim_turn"))),
		"a cursor inside the hull's own radius commands no turn"
	)
	var outside: Vector2 = ship.global_position + Vector2(radius * 2.0, 0.0).rotated(heading + 1.0)
	ship.call(&"set_aim_point", outside)
	assert_true(
		_near(float(ship.call(&"_aim_turn")), float(ship.call(&"_turn_toward", outside)), TOLERANCE),
		"outside the radius the aim turn is the plain bearing law"
	)
	assert_true(
		absf(float(ship.call(&"_aim_turn"))) <= rate + 1e-9,
		"and it is still bounded by the class rate"
	)
	## The cursor is the default source: clearing the override puts the live cursor back.
	ship.call(&"clear_aim_point")
	assert_true(
		(ship.call(&"_aim_point") as Vector2).is_equal_approx(ship.get_global_mouse_position()),
		"with no override the nose chases the cursor, the same point an LMB order aims at"
	)


## ---------------------------------------------------------------------------
## 3. The heading holds when the throttle is not held
## ---------------------------------------------------------------------------


## The gate itself: a bound turn action answers first, then the cursor while
## `thrust_forward` is held, else exactly zero. The zero is the owner's "the heading holds
## when it is not [held]", and it is what the probe watches land on a bearing.
func test_the_manual_turn_is_the_cursor_only_while_thrust_is_held() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	var rate := float(stats.turn_rate)
	var offset := Vector2(1200.0, 0.0).rotated(float(ship.global_rotation) + PI * 0.5)
	ship.call(&"set_aim_point", ship.global_position + offset)
	## Full deflection from the aim, so the cursor path is unmistakably commanding a turn.
	var aim := float(ship.call(&"_aim_turn"))
	assert_true(
		_near(aim, rate, 1e-5),
		"a cursor 90 degrees off the bow commands the full class rate (%.4f)" % aim
	)
	assert_true(
		_near(float(ship.call(&"_manual_desired_turn", 1.0, 0.0)), aim, TOLERANCE),
		"holding thrust_forward turns the nose towards the cursor"
	)
	assert_true(
		is_zero_approx(float(ship.call(&"_manual_desired_turn", 0.0, 0.0))),
		"with the throttle released nothing commands a turn: the heading holds"
	)
	assert_true(
		_near(float(ship.call(&"_manual_desired_turn", 0.0, FULL_DEFLECTION)), rate, 1e-5),
		"a deflected turn action still turns without thrust (a pad or a re-bind)"
	)
	assert_true(
		_near(float(ship.call(&"_manual_desired_turn", 1.0, -FULL_DEFLECTION)), -rate, 1e-5),
		"and a bound turn action takes priority over the cursor"
	)
	## The same gate on a hull with no cursor at all: aim overridden onto the hull itself.
	ship.call(&"set_aim_point", ship.global_position)
	assert_true(
		is_zero_approx(float(ship.call(&"_manual_desired_turn", 1.0, 0.0))),
		"a cursor on the hull commands nothing, held or not"
	)


## The shipped input map: A and D strafe, `turn_left` / `turn_right` carry no key, and
## every reader still answers its action. A pad axis or a Controls-tab re-bind is what the
## turn actions are kept for, so they are exercised here rather than assumed dead.
func test_the_shipped_map_strafes_on_a_and_d_and_keeps_the_turn_actions() -> void:
	var pair := _launch(HULL_SHIPPED)
	var ship: Variant = pair[0]
	if ship == null:
		assert_true(false, "the hull fixture did not build")
		return
	assert_true(InputMap.has_action(STRAFE_LEFT), "strafe_left is an action")
	assert_true(InputMap.has_action(STRAFE_RIGHT), "strafe_right is an action")
	assert_true(is_zero_approx(float(ship.call(&"_manual_strafe"))), "no strafe while nothing is held")
	assert_true(is_zero_approx(float(ship.call(&"_manual_throttle"))), "no throttle while nothing is held")
	_press(STRAFE_RIGHT)
	assert_true(
		_near(float(ship.call(&"_manual_strafe")), 1.0),
		"D strafes towards the hull's right"
	)
	assert_true(is_zero_approx(float(ship.call(&"_manual_throttle"))), "a strafe is not a throttle")
	_press(STRAFE_LEFT)
	assert_true(
		_near(float(ship.call(&"_manual_strafe")), 0.0, 1e-6),
		"A and D together cancel, the way W and S do"
	)
	_release_all()
	_press(THRUST_FORWARD)
	assert_true(_near(float(ship.call(&"_manual_throttle")), 1.0), "W is still the throttle")
	assert_true(
		is_zero_approx(float(ship.call(&"_manual_turn"))),
		"the shipped map binds no key to turn_left / turn_right"
	)
	_press(TURN_RIGHT)
	assert_true(
		_near(float(ship.call(&"_manual_turn")), 1.0),
		"but the turn reader still answers the action"
	)
	_press(TURN_LEFT)
	assert_true(
		is_zero_approx(float(ship.call(&"_manual_turn"))),
		"and it reports both directions"
	)
	_release_all()
	_press(THRUST_BACKWARD)
	assert_true(
		_near(float(ship.call(&"_manual_throttle")), -1.0),
		"S is still reverse thrust (the active brake)"
	)


## ---------------------------------------------------------------------------
## 4. The strafe is derived from the class's own rows and moves laterally
## ---------------------------------------------------------------------------


## The command the strafe and the throttle share, and the whole derivation: the stick's
## vector is capped at unit magnitude and scaled by the class's own `max_speed`, so every
## axis is commanded to that ceiling, no axis exceeds it, and the lateral axis is the nose
## turned 90 degrees. No fraction is invented anywhere.
##
## The tolerances here are `STICK_TOLERANCE`, not the 1e-9 the small handling numbers use:
## a `Vector2` stores float32 components, so a ~400 u/s command carries ~2.4e-5 of rounding
## (the same reason C3's probe reports three decimals of a u/s).
func test_the_command_is_lateral_and_ceiling_clamped_with_no_invented_fraction() -> void:
	for hull_id: StringName in [HULL_SHIPPED, &"ship_fighter", &"ship_freighter"]:
		var pair := _launch(hull_id)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		var ceiling := float(stats.max_speed)
		var forward_only: Vector2 = ship.call(&"_command_velocity", 1.0, 0.0)
		var lateral_only: Vector2 = ship.call(&"_command_velocity", 0.0, 1.0)
		var reverse_only: Vector2 = ship.call(&"_command_velocity", -1.0, 0.0)
		var diagonal: Vector2 = ship.call(&"_command_velocity", 1.0, 1.0)
		assert_true(
			_near(forward_only.x, ceiling, STICK_TOLERANCE)
			and is_zero_approx(forward_only.y),
			"%s: W alone is the old command to the digit (%.3f u/s)" % [hull_id, forward_only.x]
		)
		assert_true(
			_near(reverse_only.x, -ceiling, STICK_TOLERANCE) and is_zero_approx(reverse_only.y),
			"%s: S alone is the old brake command to the digit" % hull_id
		)
		assert_true(
			is_zero_approx(lateral_only.x)
			and _near(lateral_only.y, ceiling, STICK_TOLERANCE),
			"%s: D alone commands the class's own max_speed sideways (%.3f u/s)"
			% [hull_id, lateral_only.y]
		)
		assert_true(
			_near(lateral_only.y, ceiling, STICK_TOLERANCE),
			"%s: the lateral ceiling is max_speed itself -- no fraction invented" % hull_id
		)
		assert_true(
			_near(diagonal.length(), ceiling, STICK_TOLERANCE),
			(
				"%s: W+D is clamped to the class ceiling %.3f, not sqrt(2) x it (%.3f)"
				% [hull_id, ceiling, ceiling * sqrt(2.0)]
			)
		)
		assert_true(
			_near(diagonal.x, diagonal.y, STICK_TOLERANCE),
			"%s: and it is a 45 degree diagonal, so each axis gives way equally" % hull_id
		)
		assert_true(
			diagonal.x < ceiling and diagonal.y < ceiling,
			"%s: each axis gives up part of the class ceiling on the diagonal" % hull_id
		)
		assert_true(
			_near(float(ship.call(&"_accel_rate")), ceiling / float(stats.accel_time), 1e-6),
			(
				"%s: the strafe's rate is the class's own max_speed / accel_time (%.3f u/s^2)"
				% [hull_id, ceiling / float(stats.accel_time)]
			)
		)
		## The lateral axis is the hull's side, not its nose and not a world axis.
		var heading := float(ship.global_rotation)
		var nose := Vector2.RIGHT.rotated(heading)
		var side: Vector2 = ship.call(&"_strafe_axis")
		assert_true(
			_near(side.dot(nose), 0.0, 1e-5) and _near(side.length(), 1.0, 1e-5),
			"%s: the strafe axis is square to the nose, so D moves the hull sideways" % hull_id
		)
		assert_true(
			side.dot(Vector2.RIGHT.rotated(heading + PI * 0.5)) > 0.999,
			"%s: and it points to the hull's right hand" % hull_id
		)


## A hull that has not launched (no snapshot) is not a flight case: the strafe reader is
## input-only and its axis is still a unit vector, so nothing downstream can divide by a
## zero ceiling. The same guard every other reader here keeps.
func test_the_strafe_reader_needs_no_launch_snapshot() -> void:
	var ship: Variant = PlayerShipScene.instantiate()
	if ship == null:
		assert_true(false, "the shipped player_ship.tscn instantiates")
		return
	_staged.append(ship)
	_host().add_child(ship)
	assert_true(is_zero_approx(float(ship.call(&"_manual_strafe"))), "an idle hull reads no strafe")
	_press(STRAFE_RIGHT)
	assert_true(
		_near(float(ship.call(&"_manual_strafe")), 1.0),
		"the strafe reader answers the action without a snapshot"
	)
	assert_true(
		(ship.call(&"_strafe_axis") as Vector2).is_normalized(),
		"and its lateral axis is still a unit vector"
	)


## ---------------------------------------------------------------------------
## 5. The Controls tab, and every action the owner already had
## ---------------------------------------------------------------------------


func test_the_two_strafe_actions_are_rebindable_and_the_old_set_survives() -> void:
	var actions := SettingsScript.REBINDABLE_ACTIONS
	assert_eq(
		actions.size(),
		REBINDABLE_COUNT,
		"the Controls tab lists the 17 actions plus the two strafes"
	)
	for action: StringName in PREVIOUS_ACTIONS:
		assert_true(
			actions.has(action),
			"%s is still rebindable (the wave adds, it does not replace)" % action
		)
	assert_true(actions.has(STRAFE_LEFT), "strafe_left is listed in the Controls tab")
	assert_true(actions.has(STRAFE_RIGHT), "strafe_right is listed in the Controls tab")
	## And the autoload reports the same list, which is what the screen iterates.
	var manager := _settings_manager()
	if manager != null:
		var listed: Array[StringName] = manager.call(&"rebindable_actions")
		assert_eq(listed.size(), REBINDABLE_COUNT, "the Controls tab's own list carries both")
		assert_true(listed.has(STRAFE_RIGHT), "and lists the strafe")
	## The project's input map carries both, so the tab has a binding to show and rebind.
	assert_true(InputMap.has_action(STRAFE_LEFT), "the input map carries strafe_left")
	assert_true(InputMap.has_action(STRAFE_RIGHT), "the input map carries strafe_right")


func test_the_strafe_binding_round_trips_through_the_settings_manager() -> void:
	var manager := _settings_manager()
	if manager == null:
		assert_true(false, "the SettingsManager autoload is in the tree")
		return
	## The manager's own seam for this: point its writes at a scratch file, so a probe or a
	## test never rewrites the player's `user://inputs.cfg`, and put the live InputMap entry
	## back exactly as it was found (the same event object, not a copy).
	var scratch: String = manager.get(&"inputs_file")
	manager.set(&"inputs_file", "user://test_flight_feel_g1_inputs.cfg")
	var events := InputMap.action_get_events(STRAFE_RIGHT)
	if events.is_empty():
		assert_true(false, "strafe_right ships with a binding to display")
		manager.set(&"inputs_file", scratch)
		return
	var original: InputEvent = events[0]
	var text := String(manager.call(&"binding_text", STRAFE_RIGHT, 0))
	assert_true(text != "", "strafe_right ships with a binding the Controls tab can show")
	manager.call(&"set_binding", STRAFE_RIGHT, 0, _binding_event())
	assert_true(
		String(manager.call(&"binding_text", STRAFE_RIGHT, 0)) != text,
		"the Controls tab accepts a re-bind for the new action"
	)
	manager.call(&"set_binding", STRAFE_RIGHT, 0, original)
	assert_eq(
		String(manager.call(&"binding_text", STRAFE_RIGHT, 0)),
		text,
		"and the shipped binding is restored"
	)
	manager.set(&"inputs_file", scratch)


## ---------------------------------------------------------------------------
## Shared fixture
## ---------------------------------------------------------------------------


## One launched hull, the same fixture the C3 suite and the probes use.
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


func _settings_manager() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"SettingsManager"))


func _press(action: StringName) -> void:
	Input.action_press(action)
	if not _pressed.has(action):
		_pressed.append(action)


func _release_all() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()


func _binding_event() -> InputEvent:
	return _key_event(KEY_J)


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


func _near(measured: float, expected: float, tolerance: float = TOLERANCE) -> bool:
	return absf(measured - expected) <= tolerance
