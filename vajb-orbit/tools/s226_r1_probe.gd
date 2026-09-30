extends Node2D
## S22.6-R1's independent replay (the reviewer re-measures; it never reads the
## builder's numbers). Every yardstick below is transcribed from the owner-ticked
## number source -- `docs/gameplay/18_engine_spec.md` §13's two new rows -- and from
## the docs the wave binds: `docs/CONTRACTS.md` §22 T1 / §23.5 T1 (the ticked value
## and its reversal), 18 §13's handling table (nine rows, plus the S2.6/G1 retune
## halves the code carries) and 02 §5.2/§5.3 (the untouched ore rows).
##
##   XDG_DATA_HOME=/tmp/s226r1/xdg_probe "$GODOT_CONSOLE" --headless \
##     --path "$VAJB_PROJ" res://tools/s226_r1_probe.tscn --fixed-fps 60 --quit-after 12000
##
## Self-quitting (bounded loops with hard budgets, L82); one `[S226R1]` line per
## case; `failures=` in the last line decides the exit code.
##
## Cases:
##   pins        the ticked constants vs §13/CONTRACTS, and every constant the wave
##               must not move vs its doc pin (AC5/AC6)
##   rows9       the nine resolved (unplated) coast times (AC1)
##   curve       a shipped Vanguard ramped to cruise then released: the velocity
##               curve against a straight line and against an exponential (AC1)
##   release200  a 200 u/s hand-off's t_10 (AC1, second reading)
##   one_line    released from a commanded forward+strafe: bearing hold (AC2)
##   rest        a field rock at rest over 6 s (AC4)
##   kick        a rock handed the fragment kick's 150 u/s (AC3)
##   child       a real cleave child's damp and carry (AC3)
##   splinter    a real splinter body's damp (AC3)
##   ram         the 409 u/s hand-off, shipped damp against the superseded 3.71 (AC4)

const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TAG := "[S226R1]"
const THRUST: StringName = &"thrust_forward"
const STRAFE: StringName = &"strafe_right"
const AIM_DISTANCE := 4000.0

## 18 §13's Hull release coast row: 5.0; the nine rows resolve 4.0-14.0 s unplated.
const PIN_COAST_MULT := 5.0
const PIN_ROW_TIMES: Dictionary = {
	&"ship_fighter": 4.0,
	&"ship_vanguard": 5.0,
	&"ship_miner": 8.5,
	&"ship_trader": 6.5,
	&"ship_corvette": 4.5,
	&"ship_freighter": 13.0,
	&"ship_gunship": 9.5,
	&"ship_patrol": 8.5,
	&"ship_destroyer": 14.0,
}
## 18 §13's Rock drift damping row: 0.35 field / 0.25 debris, both REPLACE, 10 u/s
## kept as the superseded ceiling.
const PIN_LINEAR_DAMP := 0.35
const PIN_FRAGMENT_DAMP := 0.25
const PIN_CEILING := 10.0
## The row's worked figures (targets, not constants): 150 u/s kick -> ~106 u/s at
## 1 s / ~429 u carry; child ~600 u; the 409 u/s hand-off settles in ~10.6 s.
const KICK_SPEED := 150.0
const RAM_HANDOFF := 409.0
const ROW_SPEED_1S := 106.0
const ROW_KICK_CARRY := 429.0
const ROW_CHILD_CARRY := 600.0
const ROW_RAM_SETTLE := 10.6
const SUPERSEDED_DAMP := 3.71

## The constants the wave must NOT move (AC5), each against its doc pin.
const PIN_ACCEL_MULT := 2.0
const PIN_LATERAL_MULT := 1.0
const PIN_ANGULAR_MULT := 0.5
const PIN_BRAKE_MULT := 1.8
const PIN_OUTWARD_KICK := 150.0
const PIN_ANGLE_JITTER := 0.25
const PIN_EJECT_MULT := 1.2
const PIN_EJECT_CONE := 360.0
const PIN_ROCK_MASS_MULT := 4.0
const PIN_WORK_PER_UNIT := 1.0
## 18 §13's handling table x 0.5 on the two columns the owner retunes (coast time,
## turn rate) -- the rows `ship_fit.gd` carries, read from the doc's table.
const PIN_HANDLING: Dictionary = {
	&"ship_fighter": {&"max_speed": 450.0, &"accel_time": 2.0, &"coast_time": 0.8, &"turn_rate": 1.7, &"turn_spinup": 0.4, &"hull_mass": 80.0},
	&"ship_vanguard": {&"max_speed": 428.0, &"accel_time": 2.4, &"coast_time": 1.0, &"turn_rate": 1.5, &"turn_spinup": 0.5, &"hull_mass": 110.0},
	&"ship_miner": {&"max_speed": 338.0, &"accel_time": 4.0, &"coast_time": 1.7, &"turn_rate": 1.0, &"turn_spinup": 1.0, &"hull_mass": 140.0},
	&"ship_trader": {&"max_speed": 383.0, &"accel_time": 3.0, &"coast_time": 1.3, &"turn_rate": 1.2, &"turn_spinup": 0.7, &"hull_mass": 160.0},
	&"ship_corvette": {&"max_speed": 495.0, &"accel_time": 2.2, &"coast_time": 0.9, &"turn_rate": 1.6, &"turn_spinup": 0.45, &"hull_mass": 90.0},
	&"ship_freighter": {&"max_speed": 293.0, &"accel_time": 6.0, &"coast_time": 2.6, &"turn_rate": 0.75, &"turn_spinup": 1.4, &"hull_mass": 260.0},
	&"ship_gunship": {&"max_speed": 360.0, &"accel_time": 4.4, &"coast_time": 1.9, &"turn_rate": 0.95, &"turn_spinup": 1.0, &"hull_mass": 190.0},
	&"ship_patrol": {&"max_speed": 383.0, &"accel_time": 4.0, &"coast_time": 1.7, &"turn_rate": 1.05, &"turn_spinup": 0.9, &"hull_mass": 220.0},
	&"ship_destroyer": {&"max_speed": 315.0, &"accel_time": 6.4, &"coast_time": 2.8, &"turn_rate": 0.8, &"turn_spinup": 1.2, &"hull_mass": 300.0},
}
## 02 §5.2/§5.3's ore rows, transcribed.
const PIN_SPLIT_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
const PIN_SPAWN_WEIGHTS: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}
const PIN_GUN_CHIP := 0.10
const PIN_CORE_SHARE := 0.25
const PIN_BURST_SHARE := 0.10
const PIN_MINE_CYCLE := 1.2
const PIN_TOUGHNESS := Vector2(0.80, 1.60)
const PIN_SIZE_MULT: Dictionary = {0: 1.5, 1: 2.5, 2: 4.0, 3: 6.0}
const PIN_FRAGMENT_WORK: Dictionary = {0: 2.0, 1: 3.0, 2: 4.5}
const PIN_SPLINTER := 0.25
const PIN_SPLINTER_INTERVAL := 0.5

## Reading bands: 2 % for the modelled numbers, wider where the row itself says
## "~" (the row's targets are continuous-form figures sampled at 60 Hz).
const TOL := 0.02
const ROW_TOL := 0.03
const REST_SECONDS := 6.0
const SETTLE_FLOOR := 0.5

var _failures: Array[String] = []
var _ships: Array[Node] = []
var _field: Node2D = null


func _ready() -> void:
	await get_tree().physics_frame
	_case_pins()
	_case_rows()
	await _case_curve(&"ship_vanguard")
	await _case_release_200()
	await _case_one_line(&"ship_vanguard")
	_free_ships()
	await _case_rest()
	await _case_kick()
	await _case_child()
	await _case_splinter()
	await _case_ram()
	if _field != null and is_instance_valid(_field):
		_field.free()
	print("%s done failures=%d" % [TAG, _failures.size()])
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _check(ok: bool, label: String, detail: String) -> void:
	if not ok:
		_failures.append(label)


## ---------------------------------------------------------------------------
## AC6/AC5: the ticked constants and every constant the wave must not move
## ---------------------------------------------------------------------------


func _case_pins() -> void:
	var coast_mult := float(ShipFitScript.COAST_TIME_MULT)
	var linear := float(AsteroidScript.LINEAR_DAMP)
	var fragment := float(AsteroidScript.FRAGMENT_LINEAR_DAMP)
	var ceiling := float(AsteroidScript.DRIFT_SPEED_CEILING)
	print(
		"%s pins coast_mult=%.4f linear_damp=%.4f fragment_damp=%.4f ceiling=%.4f"
		% [TAG, coast_mult, linear, fragment, ceiling]
	)
	_check(is_equal_approx(coast_mult, PIN_COAST_MULT), "pins.coast_mult", "")
	_check(is_equal_approx(linear, PIN_LINEAR_DAMP), "pins.linear", "")
	_check(is_equal_approx(fragment, PIN_FRAGMENT_DAMP), "pins.fragment", "")
	_check(is_equal_approx(ceiling, PIN_CEILING), "pins.ceiling", "")

	var untouched := [
		is_equal_approx(float(ShipFitScript.ACCEL_TIME_MULT), PIN_ACCEL_MULT),
		is_equal_approx(float(ShipFitScript.LATERAL_DAMP_MULT), PIN_LATERAL_MULT),
		is_equal_approx(float(ShipFitScript.ANGULAR_DAMP_MULT), PIN_ANGULAR_MULT),
		is_equal_approx(float(PlayerShipScript.BRAKE_MULT), PIN_BRAKE_MULT),
		is_equal_approx(float(AsteroidScript.WORK_PER_UNIT), PIN_WORK_PER_UNIT),
		is_equal_approx(float(AsteroidScript.ROCK_MASS_MULT), PIN_ROCK_MASS_MULT),
		is_equal_approx(float(AsteroidScript.FRAGMENT_EJECT_MULT), PIN_EJECT_MULT),
		is_equal_approx(float(AsteroidScript.FRAGMENT_EJECT_CONE_DEG), PIN_EJECT_CONE),
		is_equal_approx(float(FieldScript.FRAGMENT_OUTWARD_KICK), PIN_OUTWARD_KICK),
		is_equal_approx(float(FieldScript.FRAGMENT_ANGLE_JITTER), PIN_ANGLE_JITTER),
	]
	var handlings_ok := true
	for hull: StringName in PIN_HANDLING:
		var row: Dictionary = ShipFitScript.HANDLING.get(hull, {})
		for key: StringName in PIN_HANDLING[hull]:
			if not is_equal_approx(float(row.get(key, -1.0)), float(PIN_HANDLING[hull][key])):
				handlings_ok = false
	var split_ok := str(OreTuningScript.split_mix) == str(PIN_SPLIT_MIX)
	var ore_ok := (
		is_equal_approx(float(OreTuningScript.gun_chip_rate), PIN_GUN_CHIP)
		and is_equal_approx(float(OreTuningScript.fragment_core_share), PIN_CORE_SHARE)
		and is_equal_approx(float(OreTuningScript.gun_burst_share), PIN_BURST_SHARE)
		and is_equal_approx(float(OreTuningScript.mine_cycle), PIN_MINE_CYCLE)
		and is_equal_approx(float(OreTuningScript.work_per_unit), PIN_WORK_PER_UNIT)
		and is_equal_approx(float(OreTuningScript.toughness_min), PIN_TOUGHNESS.x)
		and is_equal_approx(float(OreTuningScript.toughness_max), PIN_TOUGHNESS.y)
		and str(OreTuningScript.size_toughness_mult) == str(PIN_SIZE_MULT)
		and str(OreTuningScript.fragment_work) == str(PIN_FRAGMENT_WORK)
		and is_equal_approx(float(OreTuningScript.splinter_chance), PIN_SPLINTER)
		and is_equal_approx(float(OreTuningScript.splinter_interval), PIN_SPLINTER_INTERVAL)
		and str(OreTuningScript.spawn_size_weights) == str(PIN_SPAWN_WEIGHTS)
	)
	var untouched_ok := true
	for value: bool in untouched:
		if not value:
			untouched_ok = false
	print(
		"%s pins untouched ok=%s handlings9=%s split_mix=%s ore=%s"
		% [TAG, str(untouched_ok), str(handlings_ok), str(split_ok), str(ore_ok)]
	)
	_check(untouched_ok, "pins.untouched", "")
	_check(handlings_ok, "pins.handlings", "")
	_check(split_ok and ore_ok, "pins.ore", "")


## AC1 first half: the nine resolved unplated rows.
func _case_rows() -> void:
	var parts: Array[String] = []
	var ok := true
	for hull: StringName in PIN_ROW_TIMES:
		var stats: Variant = ShipFitScript.resolve(hull, {})
		var resolved := float(stats.coast_time) if stats != null else -1.0
		parts.append("%s=%.2f" % [String(hull).replace("ship_", ""), resolved])
		if not is_equal_approx(resolved, float(PIN_ROW_TIMES[hull])):
			ok = false
	print("%s rows9 coast_unplated=%s" % [TAG, ",".join(parts)])
	_check(ok, "rows9", "")
	var vanguard: Variant = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	var fighter: Variant = ShipFitScript.resolve(&"ship_fighter", ShipFitScript.STANDARD_FIT)
	print(
		"%s rows9 shipped vanguard max=%.2f coast=%.4f damp=%.6f | fighter max=%.2f coast=%.4f"
		% [
			TAG,
			float(vanguard.max_speed),
			float(vanguard.coast_time),
			1.0 / float(vanguard.coast_time),
			float(fighter.max_speed),
			float(fighter.coast_time),
		]
	)


## ---------------------------------------------------------------------------
## AC1: the release curve on the shipped Vanguard -- a straight line to zero
## ---------------------------------------------------------------------------


func _case_curve(hull_id: StringName) -> void:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		_check(false, "curve.fixture", "")
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	var ceiling := float(stats.max_speed)
	var coast := float(stats.coast_time)
	var rate := ceiling / coast
	Input.action_press(THRUST)
	var cruised := false
	for _i: int in range(int((float(stats.accel_time) * 2.0 + 2.0) * 60.0)):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		if body.linear_velocity.length() >= ceiling * (1.0 - 0.002):
			cruised = true
			break
	Input.action_release(THRUST)
	if not cruised:
		_check(false, "curve.never_cruised", "")
		_free_ships()
		return
	var v0 := body.linear_velocity.length()
	var start := body.global_position
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var t := 0.0
	var t_10 := -1.0
	var dist_10 := -1.0
	var t_stop := -1.0
	var max_lin := 0.0
	var max_exp := 0.0
	var carry := 0.0
	for _i: int in range(int((coast * 2.5 + 1.0) * 60.0)):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		t += dt
		var speed := body.linear_velocity.length()
		if speed > 0.5:
			max_lin = maxf(max_lin, absf(speed - (v0 - rate * t)))
			max_exp = maxf(max_exp, absf(speed - v0 * exp(-t / coast)))
		if t_10 < 0.0 and speed <= 0.1 * v0:
			t_10 = t
			dist_10 = (body.global_position - start).length()
		if speed <= SETTLE_FLOOR:
			t_stop = t
			carry = (body.global_position - start).length()
			break
	## The stop must be a stop: one more second of frames, no residual drift.
	var before_extra := body.global_position
	for _i: int in range(60):
		_pin_aim(ship, body)
		await get_tree().physics_frame
	var residual := (body.global_position - before_extra).length()
	var derived_t_10 := 0.9 * v0 / rate
	var derived_carry := 0.5 * v0 * coast
	print(
		(
			"%s curve hull=%s v0=%.3f rate=%.4f max_lin_dev=%.4f max_exp_dev=%.4f "
			+ "t_10=%.4f derived_t_10=%.4f dist_10=%.2f t_stop=%.4f carry=%.2f "
			+ "derived_carry=%.2f residual=%.6f"
		)
		% [
			TAG,
			hull_id,
			v0,
			rate,
			max_lin,
			max_exp,
			t_10,
			derived_t_10,
			dist_10,
			t_stop,
			carry,
			derived_carry,
			residual,
		]
	)
	_check(t_10 > 0.0 and _rel(t_10, derived_t_10) <= TOL, "curve.t10", "")
	_check(_rel(t_stop, coast) <= TOL, "curve.tstop", "")
	_check(_rel(carry, derived_carry) <= TOL, "curve.carry", "")
	_check(max_lin <= 0.05, "curve.straight", "")
	_check(max_exp >= 20.0, "curve.not_exponential", "")
	_check(residual <= 0.01, "curve.no_residual_drift", "")
	_free_ships()


## AC1 second reading: a 200 u/s hand-off on the same shipped hull.
func _case_release_200() -> void:
	var launched := _launch(&"ship_vanguard")
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		_check(false, "release200.fixture", "")
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	var coast := float(stats.coast_time)
	var rate := float(stats.max_speed) / coast
	body.linear_velocity = Vector2(200.0, 0.0)
	var t := 0.0
	var t_10 := -1.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for _i: int in range(int((coast * 1.5 + 1.0) * 60.0)):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		t += dt
		if body.linear_velocity.length() <= 20.0:
			t_10 = t
			break
	var derived := 0.9 * 200.0 / rate
	print(
		"%s release200 v0=200.0 coast=%.4f t_10=%.4f derived=%.4f ratio_vs_1.150=%.3f"
		% [TAG, coast, t_10, derived, t_10 / 1.150]
	)
	_check(t_10 > 0.0 and _rel(t_10, derived) <= TOL, "release200.t10", "")
	_check(t_10 / 1.150 >= 1.9 and t_10 / 1.150 <= 2.2, "release200.double", "")
	_free_ships()


## ---------------------------------------------------------------------------
## AC2: the 23.5 acceptance at the new rate, on real frames
## ---------------------------------------------------------------------------


func _case_one_line(hull_id: StringName) -> void:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		_check(false, "one_line.fixture", "")
		return
	var body: RigidBody2D = ship.call(&"impact_body")
	var ceiling := float(stats.max_speed)
	Input.action_press(THRUST)
	Input.action_press(STRAFE)
	var cruised := false
	for _i: int in range(int((float(stats.accel_time) * 2.0 + 2.0) * 60.0)):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		if body.linear_velocity.length() >= ceiling * (1.0 - 0.002):
			cruised = true
			break
	Input.action_release(THRUST)
	Input.action_release(STRAFE)
	if not cruised:
		_check(false, "one_line.never_cruised", "")
		_free_ships()
		return
	var v_release := body.linear_velocity.length()
	var bearing := body.linear_velocity.angle()
	var drift := 0.0
	var t := 0.0
	var t_10 := -1.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for _i: int in range(int((float(stats.coast_time) * 2.0 + 1.0) * 60.0)):
		_pin_aim(ship, body)
		await get_tree().physics_frame
		t += dt
		var velocity := body.linear_velocity
		if velocity.length_squared() > 0.0:
			drift = maxf(drift, absf(rad_to_deg(wrapf(velocity.angle() - bearing, -PI, PI))))
		if velocity.length() <= 0.1 * v_release:
			t_10 = t
			break
	var derived := 0.9 * v_release / (ceiling / float(stats.coast_time))
	print(
		"%s one_line v_release=%.3f max_drift=%.6f deg t_10=%.4f derived=%.4f"
		% [TAG, v_release, drift, t_10, derived]
	)
	_check(t_10 > 0.0, "one_line.crossed", "")
	_check(drift <= 5.0, "one_line.bearing", "")
	_check(t_10 > 0.0 and _rel(t_10, derived) <= 0.03, "one_line.t10", "")
	_free_ships()


## ---------------------------------------------------------------------------
## AC3/AC4: the rock drift damping
## ---------------------------------------------------------------------------


func _case_rest() -> void:
	var rock := _spawn_rock("R1Rest", AsteroidScript.SIZE_MEDIUM, 2)
	if rock == null:
		_check(false, "rest.fixture", "")
		return
	rock.global_position = Vector2(5000.0, -500.0)
	var start := rock.global_position
	for _i: int in range(int(REST_SECONDS * 60.0)):
		await get_tree().physics_frame
	var moved := (rock.global_position - start).length()
	print(
		"%s rest moved=%.6f speed=%.6f damp=%.4f mode=%d"
		% [
			TAG,
			moved,
			rock.linear_velocity.length(),
			rock.linear_damp,
			rock.linear_damp_mode,
		]
	)
	_check(moved <= 0.001 and rock.linear_velocity.length() <= 0.001, "rest.still", "")
	_check(is_equal_approx(rock.linear_damp, PIN_LINEAR_DAMP), "rest.damp", "")
	_check(rock.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE, "rest.mode", "")


func _case_kick() -> void:
	var rock := _spawn_rock("R1Kick", AsteroidScript.SIZE_MEDIUM, 2)
	if rock == null:
		_check(false, "kick.fixture", "")
		return
	rock.global_position = Vector2(5000.0, -1500.0)
	rock.linear_velocity = Vector2(KICK_SPEED, 0.0)
	var envelope := await _drift_envelope(rock)
	print(
		(
			"%s kick damp=%.4f speed_1s=%.3f carry_ceiling=%.2f t_ceiling=%.4f "
			+ "carry_total=%.2f"
		)
		% [
			TAG,
			rock.linear_damp,
			envelope[&"speed_1s"],
			envelope[&"carry_10"],
			envelope[&"t_10"],
			envelope[&"carry_total"],
		]
	)
	_check(_rel(float(envelope[&"speed_1s"]), ROW_SPEED_1S) <= ROW_TOL, "kick.speed_1s", "")
	_check(_rel(float(envelope[&"carry_total"]), ROW_KICK_CARRY) <= ROW_TOL, "kick.carry", "")


func _case_child() -> void:
	var field := _field_node()
	if field == null:
		_check(false, "child.fixture", "")
		return
	var parent: RigidBody2D = field.call(&"_new_rock", "R1Parent", &"iron", 1, 2, AsteroidScript.SIZE_LARGE)
	parent.global_position = Vector2(5000.0, -2500.0)
	var before: Array = (field.call(&"rocks") as Array).duplicate()
	parent.call(&"apply_work", 9999.0)
	var child: RigidBody2D = null
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(candidate) and candidate is RigidBody2D and is_instance_valid(candidate):
			child = candidate as RigidBody2D
			break
	if child == null:
		_check(false, "child.none", "")
		return
	var v0 := child.linear_velocity.length()
	var envelope := await _drift_envelope(child)
	print(
		"%s child damp=%.4f mode=%d v0=%.3f speed_1s=%.3f carry_total=%.2f"
		% [
			TAG,
			child.linear_damp,
			child.linear_damp_mode,
			v0,
			envelope[&"speed_1s"],
			envelope[&"carry_total"],
		]
	)
	_check(is_equal_approx(child.linear_damp, PIN_FRAGMENT_DAMP), "child.damp", "")
	_check(child.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE, "child.mode", "")
	_check(_rel(float(envelope[&"carry_total"]), ROW_CHILD_CARRY) <= ROW_TOL, "child.carry", "")


func _case_splinter() -> void:
	var field := _field_node()
	if field == null:
		_check(false, "splinter.fixture", "")
		return
	var parent: RigidBody2D = field.call(&"_new_rock", "R1SParent", &"iron", 1, 2, AsteroidScript.SIZE_LARGE)
	parent.global_position = Vector2(5000.0, -3500.0)
	var before: Array = (field.call(&"rocks") as Array).duplicate()
	field.call(&"_spawn_splinter", parent)
	var splinter: RigidBody2D = null
	for candidate: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(candidate) and candidate is RigidBody2D and is_instance_valid(candidate):
			splinter = candidate as RigidBody2D
			break
	if splinter == null:
		_check(false, "splinter.none", "")
		return
	print(
		"%s splinter damp=%.4f mode=%d size=%d v0=%.3f"
		% [
			TAG,
			splinter.linear_damp,
			splinter.linear_damp_mode,
			int(splinter.call(&"size_class")),
			splinter.linear_velocity.length(),
		]
	)
	_check(is_equal_approx(splinter.linear_damp, PIN_FRAGMENT_DAMP), "splinter.damp", "")
	_check(splinter.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE, "splinter.mode", "")


## AC4 second half: the worst ram's 409 u/s hand-off at the shipped damp against the
## superseded 3.71 (a fixture parameter, not a constant edit).
func _case_ram() -> void:
	var carries: Array[float] = []
	var settles: Array[float] = []
	for damp: float in [PIN_LINEAR_DAMP, SUPERSEDED_DAMP]:
		var rock := _spawn_rock("R1Ram%d" % int(damp * 100.0), AsteroidScript.SIZE_MEDIUM, 2)
		if rock == null:
			_check(false, "ram.fixture", "")
			return
		rock.linear_damp = damp
		rock.global_position = Vector2(5000.0, -4500.0 - 800.0 * float(carries.size()))
		rock.linear_velocity = Vector2(RAM_HANDOFF, 0.0)
		var envelope := await _drift_envelope(rock)
		carries.append(float(envelope[&"carry_total"]))
		settles.append(float(envelope[&"t_10"]))
		print(
			"%s ram damp=%.4f speed_1s=%.3f carry_ceiling=%.2f t_ceiling=%.4f carry_total=%.2f"
			% [
				TAG,
				damp,
				envelope[&"speed_1s"],
				envelope[&"carry_10"],
				envelope[&"t_10"],
				envelope[&"carry_total"],
			]
		)
	if carries.size() == 2:
		var ratio := carries[0] / maxf(carries[1], 1e-6)
		print(
			"%s ram ratio shipped/superseded=%.3f t_settle=%.3f derived=%.3f"
			% [TAG, ratio, settles[0], ROW_RAM_SETTLE]
		)
		_check(ratio >= 9.0, "ram.ratio", "")
		_check(_rel(settles[0], ROW_RAM_SETTLE) <= 0.15, "ram.settle", "")
	_check(
		_rel(carries[0], RAM_HANDOFF / PIN_LINEAR_DAMP) <= 0.05 if carries.size() == 2 else false,
		"ram.shipped_carry",
		""
	)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _spawn_rock(node_name: String, size_class: int, units: int) -> RigidBody2D:
	var field := _field_node()
	if field == null:
		return null
	var rock: RigidBody2D = field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)
	return rock


func _field_node() -> Node2D:
	if _field == null or not is_instance_valid(_field):
		_field = FieldScript.new() as Node2D
		_field.name = "R1Field"
		add_child(_field)
		_field.call(&"setup", {&"rocks": 1, &"seed": 22630})
		for generated: Node2D in _field.call(&"rocks") as Array[Node2D]:
			generated.free()
	return _field


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
	ship.global_position = Vector2(-3000.0, 0.0)
	ship.global_rotation = 0.0
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_ships.append(ship)
	return [ship, stats]


func _pin_aim(ship: Variant, body: RigidBody2D) -> void:
	ship.call(
		&"set_aim_point",
		ship.global_position + Vector2.RIGHT.rotated(float(body.global_rotation)) * AIM_DISTANCE
	)


func _free_ships() -> void:
	for ship: Node in _ships:
		if is_instance_valid(ship) and not ship.is_queued_for_deletion():
			ship.get_parent().remove_child(ship)
			ship.free()
	_ships.clear()


## The frame-by-frame drift envelope: speed at one second, the carried distance at
## the superseded 10 u/s ceiling, its time, and the total carry to the settle floor.
func _drift_envelope(rock: RigidBody2D) -> Dictionary:
	var start: Vector2 = rock.global_position
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var t := 0.0
	var speed_1s := -1.0
	var t_10 := -1.0
	var carry_10 := -1.0
	for _i: int in range(int(30.0 * 60.0)):
		await get_tree().physics_frame
		t += dt
		var speed := rock.linear_velocity.length()
		if speed_1s < 0.0 and t >= 1.0:
			speed_1s = speed
		if t_10 < 0.0 and speed <= PIN_CEILING:
			t_10 = t
			carry_10 = (rock.global_position - start).length()
		if speed <= SETTLE_FLOOR:
			break
	return {
		&"speed_1s": speed_1s,
		&"t_10": t_10,
		&"carry_10": carry_10,
		&"carry_total": (rock.global_position - start).length(),
	}


func _rel(a: float, b: float) -> float:
	if is_zero_approx(b):
		return 0.0 if is_zero_approx(a) else 1.0
	return absf(a - b) / absf(b)
