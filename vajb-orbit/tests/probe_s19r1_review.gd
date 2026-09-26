extends Node
## S19-R1's independent re-measurement (W8 method: the reviewer re-derives every number
## from 09 section 3.3's 2026-09-26 amendment and 01 section 6's, never from the builder's
## report or its suite). Bounded, self-quitting, scratch store only (L229/T-93):
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
##     res://tests/probe_s19r1_review.tscn --quit-after 600
##
## Prints `[S19R1]` lines, exits 0 when every check holds, 1 otherwise. It writes no file
## and mounts no station.

const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const ShipFitScript := preload("res://game/ship_fit.gd")
const RepairsScript := preload("res://game/repairs.gd")
const RepairsPanelScene := preload("res://ui/station/repairs_panel.tscn")
const StatusScreenScript := preload("res://ui/hud/ship_status_screen.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const TAG := "[S19R1]"
const HULL: StringName = &"ship_vanguard"
const HULL_MAX := 1000.0
const SHIELD_MAX := 600.0
const QUARTER := 250.0
const SEED := 20260926
const DRIFT_FRAME := 0.25
const EPSILON := 0.0001
const SCRATCH_PROFILE := "user://probe_s19r1_profile.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const HEAD_COPY := "/tmp/s19base_proj"
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser"],
	&"shields": [&"s_light"],
	&"armour": [],
}

var _checks := 0
var _fails: Array[String] = []
var _pane_host: Control = null
var _profile: Node = null
var _saved: Dictionary = {}
var _died_count := 0
var _hull_events := 0
var _absorbed_events := 0


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	_pane_host = Control.new()
	_pane_host.name = "S19R1Host"
	_pane_host.theme = ThemeRes
	_pane_host.size = Vector2(1920.0, 1080.0)
	add_child(_pane_host)
	print("%s probe start engine=%s scratch=%s" % [
		TAG, Engine.get_version_info()["string"], OS.get_environment("XDG_DATA_HOME")
	])
	_ac1_routing()
	_ac2_rear_arc()
	_ac3_pools()
	_ac4_malfunctions()
	_ac5_repairs_and_readouts()
	_ac6_consts_and_seal()
	_summary()


## ------------------------------------------------------------------- AC1 / AC2


## The arc map, re-derived from the amendment text: prow |d| <= 45 deg, stern
## |d| >= 135 deg, starboard the positive quarter between, port the mirror.
func _expected_quadrant(direction: float) -> StringName:
	var magnitude := absf(direction)
	if magnitude <= PI / 4.0:
		return &"prow"
	if magnitude >= 3.0 * PI / 4.0:
		return &"stern"
	return &"starboard" if direction > 0.0 else &"port"


## The amendment's rear-arc test: the 160 degree arc is a half-width of 100 degrees.
func _expected_multiplier(direction: float) -> float:
	return 1.6 if absf(direction) >= PI * 5.0 / 9.0 else 1.0


func _fresh_state() -> PlayerState:
	var state: PlayerState = PlayerStateScript.new()
	state.hull_max = HULL_MAX
	state.shield_max = SHIELD_MAX
	state.setup()
	return state


func _ctx(direction: float) -> Dictionary:
	return {PlayerStateScript.CTX_DIRECTION: direction}


func _ac1_routing() -> void:
	var steps := 1440
	var mismatches := 0
	var first := ""
	for index: int in steps + 1:
		var direction := -PI + float(index) * (2.0 * PI / float(steps))
		var want := _expected_quadrant(direction)
		var got: StringName = PlayerStateScript.quadrant_for(direction)
		if got != want:
			mismatches += 1
			if first == "":
				first = "d=%.6f got=%s want=%s" % [direction, got, want]
	_check("grid_arc_map", mismatches == 0,
		"%d bearings, %d mismatches %s" % [steps + 1, mismatches, first])
	## The boundaries, named, plus the end-to-end route through `damage`.
	var cases: Array = [
		[0.0, &"prow"], [PI / 4.0, &"prow"], [-PI / 4.0, &"prow"],
		[PI / 4.0 + EPSILON, &"starboard"], [PI / 2.0, &"starboard"],
		[3.0 * PI / 4.0 - EPSILON, &"starboard"], [3.0 * PI / 4.0, &"stern"],
		[PI, &"stern"], [-PI, &"stern"], [-3.0 * PI / 4.0, &"stern"],
		[-3.0 * PI / 4.0 + EPSILON, &"port"], [-PI / 2.0, &"port"],
		[-PI / 4.0 - EPSILON, &"port"],
	]
	var route_fail := 0
	for case: Array in cases:
		var direction: float = case[0]
		var want: StringName = case[1]
		var state := _fresh_state()
		state.damage(40.0, true, _ctx(direction))
		var landed := 40.0 * _expected_multiplier(direction)
		for quadrant: StringName in PlayerStateScript.QUADRANTS:
			var expect := QUARTER - (landed if quadrant == want else 0.0)
			if not is_equal_approx(state.pool_of(quadrant), expect):
				route_fail += 1
		if not is_equal_approx(state.hull, HULL_MAX - landed):
			route_fail += 1
	print("%s boundaries: 0->%s(%.1f) pi/4->%s(%.1f) pi/2->%s(%.1f) 3pi/4->%s(%.1f) "
		% [TAG, _expected_quadrant(0.0), 40.0 * _expected_multiplier(0.0),
			_expected_quadrant(PI / 4.0), 40.0 * _expected_multiplier(PI / 4.0),
			_expected_quadrant(PI / 2.0), 40.0 * _expected_multiplier(PI / 2.0),
			_expected_quadrant(3.0 * PI / 4.0), 40.0 * _expected_multiplier(3.0 * PI / 4.0)]
		+ " pi->%s(%.1f) -pi/4->%s(%.1f) -3pi/4->%s(%.1f)" % [
			_expected_quadrant(PI), 40.0 * _expected_multiplier(PI),
			_expected_quadrant(-PI / 4.0), 40.0 * _expected_multiplier(-PI / 4.0),
			_expected_quadrant(-3.0 * PI / 4.0), 40.0 * _expected_multiplier(-3.0 * PI / 4.0)])
	_check("boundary_and_route", route_fail == 0,
		"%d boundary cases, %d wrong" % [cases.size(), route_fail])
	## The direction-less default (P2 rule 2): a missing, zero, null or non-numeric
	## direction is 0.0 -> prow -> x1.0, and a standing shield takes exactly the amount.
	var shapes: Array = [{}, _ctx(0.0), {PlayerStateScript.CTX_DIRECTION: null},
		{PlayerStateScript.CTX_DIRECTION: &"stern"}]
	var default_fail := 0
	for shape: Variant in shapes:
		var state := _fresh_state()
		state.set_shield(0.0)
		state.damage(100.0, false, shape)
		if not is_equal_approx(state.pool_of(&"prow"), QUARTER - 100.0):
			default_fail += 1
		if not is_equal_approx(state.hull, HULL_MAX - 100.0):
			default_fail += 1
		for other: StringName in [&"stern", &"port", &"starboard"]:
			if not is_equal_approx(state.pool_of(other), QUARTER):
				default_fail += 1
	var shielded := _fresh_state()
	shielded.damage(100.0, false, {})
	if not is_equal_approx(shielded.shield, SHIELD_MAX - 100.0) \
			or not is_equal_approx(shielded.hull, HULL_MAX):
		default_fail += 1
	_check("direction_less_default", default_fail == 0, "%d shapes: prow -100, hull -100"
		% shapes.size())


func _ac2_rear_arc() -> void:
	var inside_fail := 0
	for direction: float in [PI * 5.0 / 9.0, PI, -PI, 3.0 * PI / 4.0, -3.0 * PI / 4.0]:
		var state := _fresh_state()
		state.damage(100.0, false, _ctx(direction))
		if not is_equal_approx(state.shield, SHIELD_MAX - 160.0) \
				or not is_equal_approx(state.hull, HULL_MAX):
			inside_fail += 1
	_check("rear_arc_inside_shield", inside_fail == 0, "5 bearings, shield -160, hull intact")
	var outside_fail := 0
	for direction: float in [PI * 5.0 / 9.0 - 0.001, PI / 4.0, 0.0, -PI / 4.0, -PI / 2.0]:
		var state := _fresh_state()
		state.damage(100.0, false, _ctx(direction))
		if not is_equal_approx(state.shield, SHIELD_MAX - 100.0):
			outside_fail += 1
	_check("rear_arc_outside_shield", outside_fail == 0, "5 bearings, shield -100")
	## Applied BEFORE the absorb: 62.5 x 1.6 = 100 empties a 100 point shield whole and
	## the hull is untouched; a hull-side multiplier would have left 37.5 shield.
	var point := _fresh_state()
	point.set_shield(100.0)
	point.damage(62.5, false, _ctx(-PI))
	_check("mult_before_absorb", is_equal_approx(point.shield, 0.0)
		and is_equal_approx(point.hull, HULL_MAX),
		"62.5@-PI against a 100 shield -> shield %.3f hull %.3f"
			% [point.shield, point.hull])
	## The routed pool takes the multiplied figure; the overshoot over a standing shield
	## is still lost (no carry-over, section 4.2 item 1) and no pool moves.
	var open := _fresh_state()
	open.set_shield(0.0)
	open.damage(100.0, false, _ctx(PI))
	var overshoot := _fresh_state()
	overshoot.set_shield(40.0)
	overshoot.damage(100.0, false, _ctx(PI))
	_check("rear_pool_and_no_carry_over",
		is_equal_approx(open.pool_of(&"stern"), QUARTER - 160.0)
		and is_equal_approx(overshoot.shield, 0.0)
		and is_equal_approx(overshoot.hull, HULL_MAX)
		and is_equal_approx(overshoot.pool_of(&"stern"), QUARTER),
		"open stern %.3f; 40-shield overshoot hull %.3f pool %.3f" % [
			open.pool_of(&"stern"), overshoot.hull, overshoot.pool_of(&"stern")])


## ------------------------------------------------------------------- AC3


func _ac3_pools() -> void:
	var fresh := _fresh_state()
	var split_ok := true
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		split_ok = split_ok and is_equal_approx(fresh.pool_of(quadrant), QUARTER)
	_check("pools_split_quarter", split_ok and is_equal_approx(fresh.hull, HULL_MAX),
		"4 x %.1f, hull %.1f" % [fresh.pool_of(&"prow"), fresh.hull])
	## Spill: 400 onto a full prow -> prow 0, the other three 200 each (share (400-250)/3).
	var spill := _fresh_state()
	spill.set_shield(0.0)
	spill.damage(400.0, false, _ctx(0.0))
	var spill_ok := is_equal_approx(spill.pool_of(&"prow"), 0.0)
	for other: StringName in [&"stern", &"port", &"starboard"]:
		spill_ok = spill_ok and is_equal_approx(spill.pool_of(other), 200.0)
	spill_ok = spill_ok and is_equal_approx(spill.hull, 600.0)
	_check("spill_even", spill_ok, "400@0: %s hull %.3f" % [str(_pools(spill)), spill.hull])
	## A second emptying hit with the prow already at 0: share 300/3 = 100 each.
	spill.damage(300.0, false, _ctx(0.0))
	var second_ok := is_equal_approx(spill.hull, 300.0)
	for other: StringName in [&"stern", &"port", &"starboard"]:
		second_ok = second_ok and is_equal_approx(spill.pool_of(other), 100.0)
	_check("spill_on_breach", second_ok,
		"300@0 with the prow at 0: %s hull %.3f" % [str(_pools(spill)), spill.hull])
	## Overkill: the pools stop at 0, the hull at 0, nothing negative.
	var clamped := _fresh_state()
	clamped.set_shield(0.0)
	clamped.damage(5000.0, false, _ctx(0.0))
	_check("overkill_zero", is_equal_approx(clamped.hull, 0.0) and is_equal_approx(
		clamped.pool_of(&"stern"), 0.0),
		"5000@0 -> hull %.3f stern %.3f" % [clamped.hull, clamped.pool_of(&"stern")])
	## A distribution the even split cannot fill: [200,100,0,0] takes a 400 hit to
	## hull 33.33, not to 0 -- the clamped third of the remainder is not re-offered.
	var thin := _fresh_state()
	thin.set_shield(0.0)
	thin.set(&"armour_prow", 200.0)
	thin.set(&"armour_stern", 100.0)
	thin.set(&"armour_port", 0.0)
	thin.set(&"armour_starboard", 0.0)
	thin.set(&"hull", 300.0)
	thin.damage(400.0, false, _ctx(0.0))
	print("%s thin distribution: 400@0 over [200,100,0,0] -> %s hull %.3f (landed %.3f of 400)"
		% [TAG, str(_pools(thin)), thin.hull, 300.0 - thin.hull])
	## The sum invariant through a seeded mixed sequence, re-checked after every step.
	_check("sum_through_sequence", _sequence_sums(), "40 seeded hits, sum re-derived each step")
	## Signals and death, counted.
	var died := _fresh_state()
	_died_count = 0
	_hull_events = 0
	died.died.connect(_on_died)
	died.hull_changed.connect(_on_hull_changed)
	died.set_shield(0.0)
	died.damage(HULL_MAX + 500.0, true, {})
	var after_first := _died_count
	var events_first := _hull_events
	died.damage(50.0, true, {})
	_check("died_once", after_first == 1 and _died_count == 1 and events_first == 1
		and _hull_events == 2,
		"overkill: died %d then %d; hull_changed %d then %d"
			% [after_first, _died_count, events_first, _hull_events])
	var absorbed := _fresh_state()
	_absorbed_events = 0
	absorbed.hull_changed.connect(_on_absorbed)
	absorbed.damage(100.0, false, {})
	_check("shield_absorbs_hull_silent", _absorbed_events == 0
		and is_equal_approx(absorbed.shield, SHIELD_MAX - 100.0),
		"shield %.3f, hull emits %d" % [absorbed.shield, _absorbed_events])


func _on_died() -> void:
	_died_count += 1


func _on_hull_changed(_current: float, _maximum: float) -> void:
	_hull_events += 1


func _on_absorbed(_current: float, _maximum: float) -> void:
	_absorbed_events += 1


func _pools(state: PlayerState) -> Array:
	var values: Array = []
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		values.append(snappedf(state.pool_of(quadrant), 0.001))
	return values


func _sequence_sums() -> bool:
	var state := _fresh_state()
	var rng := RandomNumberGenerator.new()
	rng.seed = 190926
	for step: int in 40:
		state.damage(
			rng.randf_range(1.0, 900.0),
			rng.randf() < 0.5,
			_ctx(rng.randf_range(-PI, PI))
		)
		var total := 0.0
		for quadrant: StringName in PlayerStateScript.QUADRANTS:
			var pool := state.pool_of(quadrant)
			if pool < 0.0 or pool > HULL_MAX:
				return false
			total += pool
		if not is_equal_approx(total, state.hull):
			print("%s sum broken at step %d: %.9f vs %.9f" % [TAG, step, total, state.hull])
			return false
		if state.hull > HULL_MAX:
			return false
	return true


## ------------------------------------------------------------------- AC4


func _ship(state: PlayerState, at: Vector2) -> Node2D:
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var ship := PlayerShipScene.instantiate() as Node2D
	_pane_host.add_child(ship)
	ship.global_position = at
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	ship.call(&"set_aim_point", at)
	return ship


## The hull's own inertia and the class's spin rate, read off the body the ship built
## (0.5 * m * r^2 from the collision circle) rather than from `_angular_inertia`.
func _peak(ship: Node2D) -> float:
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var body := ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE)) as RigidBody2D
	var radius := 0.0
	if body != null:
		for child: Node in body.get_children():
			var shape := child as CollisionShape2D
			if shape != null and shape.shape is CircleShape2D:
				radius = (shape.shape as CircleShape2D).radius
	var inertia := 0.5 * float(stats.hull_mass) * radius * radius
	return inertia * (float(stats.turn_rate) / float(stats.turn_spinup))


func _reset_spin(ship: Node2D) -> void:
	var body := ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE)) as RigidBody2D
	if body != null:
		body.angular_velocity = 0.0


func _breach(state: PlayerState, quadrant: StringName) -> void:
	match quadrant:
		&"prow":
			state.damage(QUARTER, true, _ctx(0.0))
		&"stern":
			state.damage(QUARTER / 1.6, true, _ctx(PI))
		&"port":
			state.damage(QUARTER, true, _ctx(-PI / 2.0))
		&"starboard":
			state.damage(QUARTER, true, _ctx(PI / 2.0))
	if not state.breached(quadrant):
		_fail("fixture", "the %s fixture did not breach" % quadrant)


func _ac4_malfunctions() -> void:
	## A fresh hull: no drift on the cadence, no swallow on live thrust.
	var quiet := _ship(_fresh_state(), Vector2(240.0, 0.0))
	var quiet_torque := 0.0
	for frame: int in 16:
		quiet.call(&"_physics_process", DRIFT_FRAME)
		quiet_torque = maxf(quiet_torque, absf(float(quiet.call(&"applied_torque"))))
	Input.action_press(&"thrust_forward")
	var quiet_zero := 0
	for frame: int in 60:
		quiet.call(&"_physics_process", 1.0 / 60.0)
		if (quiet.call(&"applied_force") as Vector2).is_zero_approx():
			quiet_zero += 1
	Input.action_release(&"thrust_forward")
	_check("fresh_hull_quiet", is_zero_approx(quiet_torque) and quiet_zero == 0
		and int(quiet.call(&"flicker_ignores")) == 0,
		"16 frames torque %.6f; 60 thrust ticks, %d force-dead, %d ignored"
			% [quiet_torque, quiet_zero, int(quiet.call(&"flicker_ignores"))])
	## Drift: seeded, on the 2.0 s cadence, through `_apply_torque`, silent before.
	var state := _fresh_state()
	_breach(state, &"stern")
	var ship := _ship(state, Vector2(120.0, -40.0))
	var peak := _peak(ship)
	var live_peak := float(ship.call(&"_angular_inertia")) * float(ship.call(&"_spin_rate"))
	_check("peak_re_derivation", is_equal_approx(peak, live_peak),
		"0.5*m*r^2*spin = %.6f vs the hull's %.6f" % [peak, live_peak])
	ship.call(&"seed_breach_rolls", SEED)
	var twin := RandomNumberGenerator.new()
	twin.seed = SEED
	var early := 0
	for frame: int in 7:
		ship.call(&"_physics_process", DRIFT_FRAME)
		if not is_zero_approx(float(ship.call(&"applied_torque"))):
			early += 1
	var drifts: Array[float] = []
	var signs_ok := true
	for index: int in 3:
		ship.call(&"_physics_process", DRIFT_FRAME)
		var torque := float(ship.call(&"applied_torque"))
		var want_sign := -1.0 if twin.randf() < 0.5 else 1.0
		drifts.append(snappedf(torque, 0.000001))
		signs_ok = signs_ok and is_equal_approx(signf(torque), want_sign)
		for quiet_frame: int in 7:
			ship.call(&"_physics_process", DRIFT_FRAME)
			if not is_zero_approx(float(ship.call(&"applied_torque"))):
				early += 1
	var magnitude_ok := true
	for torque: float in drifts:
		magnitude_ok = magnitude_ok and is_equal_approx(absf(torque), 0.15 * peak)
	_check("drift_cadence_and_sign", early == 0 and magnitude_ok and signs_ok,
		"peak %.6f (15 %% = %.6f); three 2.0 s drifts %s; off-cadence torques %d"
			% [peak, 0.15 * peak, str(drifts), early])
	## Derived clear, route A: the pool lifted by a direct write (no repair call).
	state.set(&"armour_stern", 62.5)
	var lifted := 0.0
	for frame: int in 16:
		ship.call(&"_physics_process", DRIFT_FRAME)
		lifted = maxf(lifted, absf(float(ship.call(&"applied_torque"))))
	_check("drift_ends_when_pool_lifted", is_zero_approx(lifted),
		"16 frames after armour_stern = 62.5, torque %.6f" % lifted)
	## ...and the clock restarts: a re-breach waits a full 2.0 s again.
	state.set(&"armour_stern", 0.0)
	var resumed := 0
	for frame: int in 7:
		ship.call(&"_physics_process", DRIFT_FRAME)
		if not is_zero_approx(float(ship.call(&"applied_torque"))):
			resumed += 1
	ship.call(&"_physics_process", DRIFT_FRAME)
	_check("drift_clock_resets", resumed == 0
		and not is_zero_approx(float(ship.call(&"applied_torque"))),
		"7 quiet frames then %.6f at 2.0 s"
			% float(ship.call(&"applied_torque")))
	## Flicker: the seeded share of thrust ticks, the idle stick, and the strafe gate.
	var prow := _fresh_state()
	_breach(prow, &"prow")
	var flicker_ship := _ship(prow, Vector2(0.0, 160.0))
	flicker_ship.call(&"seed_breach_rolls", SEED)
	var flicker_twin := RandomNumberGenerator.new()
	flicker_twin.seed = SEED
	for frame: int in 5:
		flicker_ship.call(&"_physics_process", 1.0 / 60.0)
	var idle_before := int(flicker_ship.call(&"flicker_ignores"))
	Input.action_press(&"thrust_forward")
	var expected := 0
	var observed := 0
	for frame: int in 200:
		flicker_ship.call(&"_physics_process", 1.0 / 60.0)
		if (flicker_ship.call(&"applied_force") as Vector2).is_zero_approx():
			observed += 1
		if flicker_twin.randf() < 0.15:
			expected += 1
	Input.action_release(&"thrust_forward")
	var ignored := int(flicker_ship.call(&"flicker_ignores"))
	_check("flicker_seeded_share",
		idle_before == 0 and expected > 0 and ignored == expected and observed == expected,
		"seed %d: idle %d, twin %d, ignored %d, force-dead %d of 200"
			% [SEED, idle_before, expected, ignored, observed])
	var strafing := _fresh_state()
	_breach(strafing, &"prow")
	var strafe_ship := _ship(strafing, Vector2(0.0, -160.0))
	strafe_ship.call(&"seed_breach_rolls", SEED)
	Input.action_press(&"strafe_left")
	for frame: int in 60:
		strafe_ship.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(&"strafe_left")
	_check("flicker_covers_strafe", int(strafe_ship.call(&"flicker_ignores")) > 0,
		"60 strafe ticks, %d swallowed" % int(strafe_ship.call(&"flicker_ignores")))
	## Turn clip: x0.5 towards a breached flank, the class's own rate away, and a stern
	## or prow breach leaves the turn alone. Each measurement starts from zero spin.
	var healthy := _ship(_fresh_state(), Vector2.ZERO)
	var starboard_state := _fresh_state()
	_breach(starboard_state, &"starboard")
	var starboard := _ship(starboard_state, Vector2.ZERO)
	var port_state := _fresh_state()
	_breach(port_state, &"port")
	var port := _ship(port_state, Vector2.ZERO)
	var stern_state := _fresh_state()
	_breach(stern_state, &"stern")
	var stern := _ship(stern_state, Vector2.ZERO)
	var right := _turn(healthy, &"turn_right")
	var left := _turn(healthy, &"turn_left")
	var starboard_right := _turn(starboard, &"turn_right")
	var starboard_left := _turn(starboard, &"turn_left")
	var port_left := _turn(port, &"turn_left")
	var port_right := _turn(port, &"turn_right")
	var stern_right := _turn(stern, &"turn_right")
	var stern_left := _turn(stern, &"turn_left")
	_check("turn_clip_towards_breach",
		is_equal_approx(starboard_right, right * 0.5)
		and is_equal_approx(starboard_left, left)
		and is_equal_approx(port_left, left * 0.5)
		and is_equal_approx(port_right, right),
		"healthy %.4f/%.4f; starboard breach %.4f/%.4f; port breach %.4f/%.4f"
			% [right, left, starboard_right, starboard_left, port_left, port_right])
	_check("turn_untouched_by_stern_breach",
		is_equal_approx(stern_right, right) and is_equal_approx(stern_left, left),
		"stern breach %.4f/%.4f (healthy %.4f/%.4f)"
			% [stern_right, stern_left, right, left])
	## Derived clear, route B: `setup()` (a repair's relaunch seed) ends both effects.
	var both := _fresh_state()
	_breach(both, &"stern")
	_breach(both, &"prow")
	var cleared := _ship(both, Vector2(-120.0, 0.0))
	cleared.call(&"seed_breach_rolls", SEED)
	var fired := false
	for frame: int in 8:
		cleared.call(&"_physics_process", DRIFT_FRAME)
		fired = fired or not is_zero_approx(float(cleared.call(&"applied_torque")))
	both.setup()
	var after := 0.0
	for frame: int in 16:
		cleared.call(&"_physics_process", DRIFT_FRAME)
		after = maxf(after, absf(float(cleared.call(&"applied_torque"))))
	Input.action_press(&"thrust_forward")
	for frame: int in 40:
		cleared.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(&"thrust_forward")
	_check("setup_clears_derived_breach", fired and is_zero_approx(after)
		and int(cleared.call(&"flicker_ignores")) == 0,
		"drift fired=%s, after setup torque %.6f, ignores %d"
			% [str(fired), after, int(cleared.call(&"flicker_ignores"))])


func _turn(ship: Node2D, action: StringName) -> float:
	_reset_spin(ship)
	Input.action_press(action)
	ship.call(&"_physics_process", 1.0 / 60.0)
	var torque := float(ship.call(&"applied_torque"))
	Input.action_release(action)
	return torque


## ------------------------------------------------------------------- AC5


func _ac5_repairs_and_readouts() -> void:
	## 01 section 6's fee arithmetic, re-derived: 20 % hull / 50 % shield on the
	## Vanguard (1000/600) is (800/2) + (300/3) = 500 CR, the doc's own example.
	var profile := ProfileScript.new()
	profile.save_path = SCRATCH_PROFILE
	profile.set_vitals(HULL, 200, 300)
	var fee := int(RepairsScript.fee(profile, HULL))
	_check("fee_law_doc_example", fee == 500, "200/300 on 1000/600 -> %d CR" % fee)
	var exempt := ProfileScript.new()
	exempt.save_path = SCRATCH_PROFILE
	exempt.set_vitals(HULL, 1000, 560)
	_check("fee_shield_alone_exempt", int(RepairsScript.fee(exempt, HULL)) == 0,
		"full hull, 93 %% shield -> %d CR" % int(RepairsScript.fee(exempt, HULL)))
	var repaired: Dictionary = RepairsScript.repair(profile, HULL)
	var pools: Array = repaired.get(&"pools", [])
	var pools_ok := pools.size() == 4
	for value: float in pools:
		pools_ok = pools_ok and is_equal_approx(value, QUARTER)
	var vitals: Dictionary = profile.call(&"vitals_of", HULL)
	_check("repair_restore_and_pools", bool(repaired.get(&"ok", false))
		and int(repaired.get(&"fee", 0)) == 500 and profile.credits() == 9500
		and int(vitals.get(&"hull", 0)) == 1000 and int(vitals.get(&"shield", 0)) == 600
		and pools_ok,
		"fee %d, credits %d, hull %s, pools %s" % [
			int(repaired.get(&"fee", -1)), profile.credits(),
			str(vitals.get(&"hull")), str(pools)])
	## The panel: the shipped five rows at their own arithmetic, then the four lines.
	_install_profile()
	var panel := RepairsPanelScene.instantiate() as Control
	_pane_host.add_child(panel)
	var values: Dictionary = panel.get(&"_values")
	var shipped: Array[String] = []
	for key: StringName in [&"hull_name", &"hull", &"shield", &"missing", &"fee"]:
		shipped.append("%s=%s" % [key, _panel_text(values, key)])
	var lines: Array[String] = []
	for key: StringName in [&"prow", &"stern", &"port", &"starboard"]:
		lines.append("%s=%s" % [key, _panel_text(values, key)])
	print("%s panel: %s | %s | rows=%d" % [
		TAG, ", ".join(shipped), ", ".join(lines), values.size()])
	var stats: ShipStats = ShipFitScript.resolve(HULL, FIXTURE_FIT)
	var hull_max := int(round(stats.hull_max))
	var shield_max := int(round(stats.shield_max))
	var panel_ok := values.size() == 9 \
		and _panel_text(values, &"hull") == "200 / %d" % hull_max \
		and _panel_text(values, &"shield") == "300 / %d" % shield_max \
		and _panel_text(values, &"missing") == "%d HULL · %d SHIELD" % [
			hull_max - 200, shield_max - 300] \
		and _panel_text(values, &"fee") == "500 CR"
	var line_ok := true
	for key: StringName in [&"prow", &"stern", &"port", &"starboard"]:
		line_ok = line_ok and _panel_text(values, key) == "50 / 250"
	_check("panel_rows", panel_ok and line_ok, "9 rows, four lines at '50 / 250'")
	## The status screen: four pool rows, and the fit/footer rows unmoved.
	var screen := StatusScreenScript.new() as Control
	_pane_host.add_child(screen)
	screen.call(&"set_hull", HULL)
	screen.call(&"set_hull_slots", [])
	screen.call(&"set_pools", 812.0, HULL_MAX, 240.0, SHIELD_MAX)
	var fit_rows: Array = screen.call(&"module_rows")
	var footer_before: Dictionary = screen.call(&"footer_lines")
	var fallback: Array = screen.call(&"pool_rows")
	var fallback_text := "" if fallback.is_empty() else String(fallback[0].get(&"text"))
	screen.call(&"set_quadrants", 100.0, 120.0, 130.0, 140.0)
	var rows: Array = screen.call(&"pool_rows")
	var texts: Array[String] = []
	for row: Dictionary in rows:
		texts.append(String(row.get(&"text")))
	var footer_after: Dictionary = screen.call(&"footer_lines")
	_check("status_rows_append_only",
		fallback.size() == 4 and fallback_text == "PROW 203 / 250"
		and texts == ["PROW 100 / 250", "STERN 120 / 250", "PORT 130 / 250", "STBD 140 / 250"]
		and (screen.call(&"module_rows") as Array).size() == fit_rows.size()
		and String(footer_before.get(&"hull", "")) == String(footer_after.get(&"hull", "")),
		"fallback '%s'; fed %s; fit rows %d -> %d; footer '%s'" % [
			fallback_text, str(texts), fit_rows.size(),
			(screen.call(&"module_rows") as Array).size(),
			String(footer_after.get(&"hull", ""))])
	panel.free()
	screen.free()
	_restore_profile()


func _panel_text(values: Dictionary, key: StringName) -> String:
	var label: Label = values.get(key)
	return "" if label == null else String(label.text)


func _install_profile() -> void:
	if _profile == null or not _saved.is_empty():
		return
	_saved = {
		&"active": _profile.call(&"active_ship"),
		&"credits": int(_profile.call(&"credits")),
		&"fits": _profile.call(&"fits"),
		&"vitals": _profile.call(&"vitals_of", HULL),
		&"save_path": _profile.get(&"save_path"),
	}
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_credits", 10000)
	_profile.call(&"set_fit", HULL, FIXTURE_FIT)
	_profile.call(&"set_vitals", HULL, 200, 300)


func _restore_profile() -> void:
	if _profile == null or _saved.is_empty():
		return
	_profile.set(&"save_path", _saved[&"save_path"])
	_profile.set(&"_active_ship", _saved[&"active"])
	_profile.set(&"_credits", _saved[&"credits"])
	if _saved[&"fits"] is Dictionary:
		_profile.call(&"set_fits", _saved[&"fits"])
	var vitals: Variant = _saved[&"vitals"]
	if vitals is Dictionary and not (vitals as Dictionary).is_empty():
		var record: Dictionary = vitals
		_profile.call(&"set_vitals", HULL, int(record.get("hull", 0)),
			int(record.get("shield", 0)))
	_saved = {}


## ------------------------------------------------------------------- AC6


func _ac6_consts_and_seal() -> void:
	var expected := {
		"QUADRANT_COUNT": PlayerStateScript.QUADRANT_COUNT == 4,
		"PROW_ARC": is_equal_approx(PlayerStateScript.PROW_ARC, PI / 4.0),
		"REAR_ARC": is_equal_approx(PlayerStateScript.REAR_ARC, 3.0 * PI / 4.0),
		"STERN_VULN_ARC": is_equal_approx(PlayerStateScript.STERN_VULN_ARC, PI * 5.0 / 9.0),
		"STERN_DAMAGE_MULT": is_equal_approx(PlayerStateScript.STERN_DAMAGE_MULT, 1.6),
		"BREACH_DRIFT_FRACTION": is_equal_approx(PlayerShipScript.BREACH_DRIFT_FRACTION, 0.15),
		"BREACH_DRIFT_INTERVAL": is_equal_approx(PlayerShipScript.BREACH_DRIFT_INTERVAL, 2.0),
		"BREACH_TURN_CLIP": is_equal_approx(PlayerShipScript.BREACH_TURN_CLIP, 0.5),
		"BREACH_FLICKER_CHANCE": is_equal_approx(PlayerShipScript.BREACH_FLICKER_CHANCE, 0.15),
	}
	var wrong: Array[String] = []
	for name: String in expected:
		if not bool(expected[name]):
			wrong.append(name)
	_check("const_table", wrong.is_empty(), "9 values read; wrong: %s" % str(wrong))
	var hashes := {
		"res://game/damage.gd": "5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269",
		"res://game/npc_ship.gd": "de8596b161dda9edbaef8e39f36c460303b4902d48cdacdbf64b1979c91981be",
		"res://game/npc_brain.gd": "e39440bf410b535c50f924208290e54dc8085eea52731890b778a4ad3fbe5d22",
		"res://game/weapons.gd": "fcdc549f0b0b3c6a3523e79af2b4797472f65b380f88b9771837b3b6497f8279",
	}
	var moved: Array[String] = []
	for path: String in hashes:
		var live := FileAccess.get_sha256(path)
		if live != hashes[path]:
			moved.append("%s=%s" % [path, live])
	_check("forbidden_seal", moved.is_empty(),
		"4 files re-hashed at runtime; moved: %s" % str(moved))
	## The fee law as text, against the HEAD copy of the same file (the append-only
	## claim measured as text, not as a re-run).
	if DirAccess.dir_exists_absolute(HEAD_COPY):
		_check("fee_function_identical",
			_file_region(HEAD_COPY + "/game/repairs.gd", "static func fee(")
			== _file_region("res://game/repairs.gd", "static func fee("),
			"`Repairs.fee` text vs the HEAD copy at %s" % HEAD_COPY)
		## REPORT_ROWS is append-only: every HEAD line must survive as a prefix line of
		## the live table, in place and unchanged.
		var head_rows := _file_region(HEAD_COPY + "/ui/station/repairs_panel.gd",
			"const REPORT_ROWS")
		var live_rows := _file_region("res://ui/station/repairs_panel.gd", "const REPORT_ROWS")
		var missing: Array[String] = []
		for line: String in head_rows.split("\n"):
			if line.strip_edges() != "" and not live_rows.contains(line):
				missing.append(line.strip_edges())
		_check("report_rows_append_only", missing.is_empty(),
			"HEAD rows missing from the live table: %s" % str(missing))
	else:
		print("%s text checks skipped (no HEAD copy at %s)" % [TAG, HEAD_COPY])


func _file_region(path: String, opener: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	var start := text.find(opener)
	if start < 0:
		return ""
	var finish := text.find("\n\n\n", start)
	return text.substr(start, (finish - start) if finish > start else text.length() - start)


## ------------------------------------------------------------------- harness


func _check(name: String, ok: bool, detail: String) -> void:
	_checks += 1
	if ok:
		print("%s ok %s -- %s" % [TAG, name, detail])
	else:
		_fail(name, detail)


func _fail(name: String, detail: String) -> void:
	_fails.append("%s: %s" % [name, detail])
	print("%s FAIL %s -- %s" % [TAG, name, detail])


func _summary() -> void:
	print("%s SUMMARY checks=%d failed=%d %s" % [
		TAG, _checks, _fails.size(), str(_fails)])
	get_tree().quit(1 if _fails.size() > 0 else 0)
