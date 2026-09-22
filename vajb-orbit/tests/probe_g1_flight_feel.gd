extends Node
## G1 flight-feel probe -- the measurement half of the owner's third-round rulings
## (2026-09-21, brief `.agents/gen/flight_beam_wave_task.md`). It flies the *shipped*
## hull and the shipped flight code and measures four things the rulings name:
##
## 1. **the nose follows the cursor while `thrust_forward` is held**, and it reaches the
##    cursor's bearing at the class's own `turn_rate` / `turn_spinup` (no faster than the
##    class can deliver, and it does arrive);
## 2. **the heading holds when `thrust_forward` is not held** -- released mid-turn the
##    nose spins down over the class's spin-up and then stops dead on its own bearing,
##    and with no input at all a cursor off the bow turns nothing;
## 3. **A/D strafe the hull sideways**: the lateral velocity chases the class's own
##    `max_speed` at the class's own `max_speed / accel_time`, while the forward axis and
##    the heading stay where they were -- and W+D is a 45 degree track at the class
##    maximum, not a sqrt(2) overspeed;
## 4. **the turn curve before and after** the owner's x 0.50 retune, all nine classes.
##
## Run (bounded, headless, no editor):
##   godot --headless --path vajb-orbit res://tests/probe_g1_flight_feel.tscn \
##     --fixed-fps 60 --quit-after 20000
##
## `--fixed-fps 60` is load-bearing for the same reason C3's probe needs it: it disables
## real-time synchronisation, so one main-loop iteration is exactly one 1/60 s physics
## step and the tick counts below are reproducible run to run. The probe self-quits and
## prints `[G1] done`; `--quit-after` is the watchdog.
##
## The cursor itself cannot be driven headless (CONTRACTS section 9: `parse_input_event`
## is inert and an unfocused window is unreliable), so the hull is handed the aim point
## through `PlayerShip.set_aim_point`, the additive seam the weapon component already
## carries. That is the same mechanism the game uses for a mouse: `_aim_turn` reads
## `_aim_point()` and nothing else.
##
## Signal lines: `[G1] engine|config|turn|curve|result|span|derived|note|done`.
## Exit code 0 only when every case measured what the ruling claims.

const SHIP_SCENE := preload("res://game/player_ship.tscn")
const SHIP_SCRIPT := preload("res://game/player_ship.gd")
const FIT := preload("res://game/ship_fit.gd")
const STATE_SCRIPT := preload("res://game/player_state.gd")

const THRUST: StringName = &"thrust_forward"
const STRAFE_RIGHT: StringName = &"strafe_right"
const STRAFE_LEFT: StringName = &"strafe_left"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"

## The shipped launch (`game.gd:HULL_ID_DEFAULT` = `ship_vanguard` + `ShipFit.STANDARD_FIT`)
## plus the fastest and the heaviest classes of section 13's handling column, so the two
## ends of the turn curve are both measured and not only the middle.
const HULL_SHIPPED: StringName = &"ship_vanguard"
const HULL_FASTEST: StringName = &"ship_fighter"
const HULL_HEAVIEST: StringName = &"ship_freighter"

## Section 13's turn column *before* the flight-feel retune, quoted from
## `docs/gameplay/18_engine_spec.md` "Handling per class" (the owner-locked table): the
## after must be exactly half of these, which is what makes the table below a statement
## about the ruling rather than a copy of the shipped number.
const SECTION_13_TURN: Dictionary = {
	&"ship_fighter": 3.4,
	&"ship_vanguard": 3.0,
	&"ship_miner": 2.0,
	&"ship_trader": 2.4,
	&"ship_corvette": 3.2,
	&"ship_freighter": 1.5,
	&"ship_gunship": 1.9,
	&"ship_patrol": 2.1,
	&"ship_destroyer": 1.6,
}
const RETUNE_SCALE := 0.50

const SAMPLE_TICKS := 6
const SAMPLE_SECONDS := 0.1

## The aim point is placed this far from the hull and re-placed every frame, so the
## *bearing* the nose chases is constant while the hull moves under it.
const AIM_DISTANCE := 4000.0
## "Reached the bearing" for the measured arrival: 0.02 rad = 1.15 degrees.
const BEARING_TOLERANCE := 0.02
## The arrive-steering law scales the commanded turn with the error, so the last degrees
## are asymptotic; this is the arrival's own tolerance band, not the class's.
const STOP_OMEGA := 0.01
const TURN_HOLD_SECONDS := 1.5
const HOLD_SECONDS := 4.0
## How long a turn that is already under way gets to close its remaining bearing after the
## throttle is released: the arrive law's tail is asymptotic, so the heaviest class needs
## more than HOLD_SECONDS for its last two degrees.
const RELEASE_ARRIVAL_SECONDS := 8.0
const MAX_TURN_SECONDS := 24.0
## The strafe's own budget: the slowest class needs 90 % of its `accel_time` (12.6 s with the
## 2026-09-22 `ACCEL_TIME_MULT`, so 11.34 s) and this is that with slack.
const MAX_STRAFE_SECONDS := 16.0
const CRUISE_TOLERANCE := 0.05
const RATE_SLACK := 1.05
const HEADING_TOLERANCE := 1e-6
const FORWARD_DRIFT_TOLERANCE := 2.0

var _failures := 0
var _ticks := 0


func _ready() -> void:
	print(
		"[G1] engine=%s physics_hz=%d max_fps=%d"
		% [
			Engine.get_version_info().get(&"string", "?"),
			Engine.physics_ticks_per_second,
			Engine.max_fps,
		]
	)
	print("[G1] cmdline=%s" % " ".join(OS.get_cmdline_args()))
	print(
		"[G1] input thrust_forward=%s strafe_left=%s strafe_right=%s turn_left=%s turn_right=%s"
		% [
			InputMap.has_action(THRUST),
			InputMap.has_action(STRAFE_LEFT),
			InputMap.has_action(STRAFE_RIGHT),
			InputMap.has_action(TURN_LEFT),
			InputMap.has_action(TURN_RIGHT),
		]
	)
	## A warm-up frame before the first case, for C3's reason: a hull added from `_ready`
	## enters the tree between physics steps, one added from inside a callback enters
	## during one, and the two do not put their first processed frame on the same tick.
	await get_tree().physics_frame

	_print_turn_table()

	for hull_id: StringName in [HULL_SHIPPED, HULL_FASTEST, HULL_HEAVIEST]:
		if not await _case_cursor_turn(hull_id):
			_failures += 1
	for hull_id: StringName in [HULL_SHIPPED, HULL_HEAVIEST]:
		if not await _case_neutral_turn_after_release(hull_id):
			_failures += 1
	if not await _case_neutral_turn_at_rest():
		_failures += 1
	for hull_id: StringName in [HULL_SHIPPED, HULL_FASTEST, HULL_HEAVIEST]:
		if not await _case_strafe(hull_id):
			_failures += 1
	if not await _case_strafe_with_thrust():
		_failures += 1

	_release_all()
	print(
		"[G1] clock iterations=%d physics_frames=%d wall_ms=%d"
		% [Engine.get_process_frames(), Engine.get_physics_frames(), Time.get_ticks_msec()]
	)
	print("[G1] done failures=%d" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


## ---------------------------------------------------------------------------
## 4. The turn curve, before and after
## ---------------------------------------------------------------------------


## The owner's x 0.50 retune, class by class: the shipped column against the section 13
## column quoted above, with the derived "how long a 90 degree turn takes at this rate"
## (`(PI / 2) / rate`, the pure rate half; the spin-up adds its own ramp on top, which is
## what the cursor-turn cases measure end to end).
func _print_turn_table() -> void:
	print("[G1] turn retune=x%.2f classes=%d" % [RETUNE_SCALE, SECTION_13_TURN.size()])
	var mismatches := 0
	for raw_key: Variant in SECTION_13_TURN.keys():
		var hull_id := StringName(raw_key)
		var before := float(SECTION_13_TURN[hull_id])
		var row: Dictionary = FIT.HANDLING.get(hull_id, {})
		if row.is_empty():
			print("[G1] note hull=%s missing from the handling column" % hull_id)
			mismatches += 1
			continue
		var after := float(row[&"turn_rate"])
		var spinup := float(row[&"turn_spinup"])
		if absf(after - before * RETUNE_SCALE) > 1e-9:
			mismatches += 1
		print(
			"[G1] turn hull=%s before=%.3f after=%.3f after_deg_s=%.1f ratio=%.4f spinup=%.2f t_90_pure=%.3f"
			% [
				hull_id,
				before,
				after,
				rad_to_deg(after),
				after / before,
				spinup,
				(PI * 0.5) / after,
			]
		)
	print(
		"[G1] turn_curve classes=%d mismatched=%d retune=x%.2f"
		% [SECTION_13_TURN.size(), mismatches, RETUNE_SCALE]
	)
	if mismatches > 0:
		_failures += 1


## ---------------------------------------------------------------------------
## 1. The nose follows the cursor bearing at the class's own rate
## ---------------------------------------------------------------------------


## Hold `thrust_forward` with the aim point 90 degrees off the bow and re-placed on the
## hull every frame (a constant *bearing*, not a constant world point), and measure the
## arrival: the error the nose started with, the time it took to come inside
## BEARING_TOLERANCE, the peak turn rate it used, and the class's own bound on that time
## (`(start_error - tolerance) / turn_rate`, because no hull can consume a bearing faster
## than its rate allows).
func _case_cursor_turn(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[G1] note case=cursor_%s the hull fixture did not build" % hull_id)
		return false
	var case_id := "cursor_%s" % hull_id
	var rate: float = stats.turn_rate
	var spinup: float = stats.turn_spinup
	var offset := Vector2(AIM_DISTANCE, 0.0).rotated(PI * 0.5)
	var target := offset.angle()
	var start_error := absf(wrapf(target - 0.0, -PI, PI))
	print(
		"[G1] config case=%s hull=%s turn_rate=%.3f spinup=%.3f aim=%.1fdeg start_error=%.4f"
		% [case_id, hull_id, rate, spinup, rad_to_deg(target), start_error]
	)
	print(
		"[G1] derived case=%s t_class_min=%.3f (start_error - tolerance) / turn_rate"
		% [case_id, (start_error - BEARING_TOLERANCE) / rate]
	)

	Input.action_press(THRUST)
	var budget := int(MAX_TURN_SECONDS * Engine.physics_ticks_per_second)
	var t_reach := -1.0
	var omega_peak := 0.0
	var error := start_error
	var start := _ticks
	for i: int in range(budget + 1):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
		error = absf(wrapf(target - float(ship.global_rotation), -PI, PI))
		omega_peak = maxf(omega_peak, absf(float(ship.impact_body().angular_velocity)))
		var t := float(_ticks - start) / Engine.physics_ticks_per_second
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=%s t=%.3f error=%.4f omega=%.3f speed=%.3f"
				% [case_id, t, error, ship.impact_body().angular_velocity, ship.velocity().length()]
			)
		if t_reach < 0.0 and error <= BEARING_TOLERANCE:
			t_reach = t
			break
	_release_all()

	var t_class_min := (start_error - BEARING_TOLERANCE) / rate
	var rate_ok := omega_peak <= rate * RATE_SLACK
	var arrived := t_reach >= 0.0
	var bound_ok := arrived and t_reach >= t_class_min * (1.0 - 0.05)
	print(
		"[G1] result case=%s t_reach=%.3f t_class_min=%.3f omega_peak=%.3f rate=%.3f ratio=%.3f arrived=%s rate_ok=%s bound_ok=%s"
		% [
			case_id,
			t_reach,
			t_class_min,
			omega_peak,
			rate,
			omega_peak / rate,
			arrived,
			rate_ok,
			bound_ok,
		]
	)
	print(
		"[G1] derived case=%s t_90_at_rate=%.3f spinup=%.3f t_90_with_spinup_upper=%.3f"
		% [case_id, (PI * 0.5) / rate, spinup, (PI * 0.5) / rate + spinup]
	)
	return arrived and rate_ok and bound_ok


## ---------------------------------------------------------------------------
## 2. The cursor steers with the throttle released too (the 2026-09-22 ruling)
## ---------------------------------------------------------------------------


## The two cases under this heading were written against the third-round ruling ("the heading
## holds when `thrust_forward` is not held"), which the 2026-09-22 steering ruling supersedes
## (CONTRACTS section 14, `STEER_WITHOUT_THROTTLE`): the cursor now steers with the throttle
## released too, so a released throttle no longer stops a turn. Both are re-derived around
## that -- and the acceptance the ruling owes is the neutral turn, which
## `tests/probe_s2_6_flight.tscn` measures over a full 360 degrees and
## `tests/test_s2_6_flight.gd` pins in the gate.


## Turn for TURN_HOLD_SECONDS, then release the throttle with the cursor still off the bow
## and watch the nose: under the 2026-09-22 ruling the cursor stays live at zero throttle,
## so the turn no longer stops dead -- the nose carries on to the bearing. This case measures
## that (an arrival within the class's own bound), and reports the translation the turn's own
## coast produced alongside it; the bound on a turn's translation belongs to a turn from rest
## and is measured there.
func _case_neutral_turn_after_release(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[G1] note case=turn_after_release_%s the hull fixture did not build" % hull_id)
		return false
	var case_id := "turn_after_release_%s" % hull_id
	var rate: float = stats.turn_rate
	var offset := Vector2(AIM_DISTANCE, 0.0).rotated(PI * 0.5)
	var target := offset.angle()

	Input.action_press(THRUST)
	await _hold_turning(ship, offset, TURN_HOLD_SECONDS, case_id)
	Input.action_release(THRUST)

	var release_heading := float(ship.global_rotation)
	var release_omega := absf(float(ship.impact_body().angular_velocity))
	var release_position: Vector2 = ship.global_position
	var start_error := absf(wrapf(target - release_heading, -PI, PI))
	var t_reach := -1.0
	var heading_last := release_heading
	var displacement := 0.0
	var speed_last := 0.0
	var elapsed := 0.0
	## The arrival's tail is asymptotic (the arrive law scales with the remaining error), so
	## the heaviest class needs more than HOLD_SECONDS to close its last two degrees; the
	## budget is doubled rather than the tolerance widened, and it is still a hard bound.
	var budget := int(RELEASE_ARRIVAL_SECONDS * Engine.physics_ticks_per_second)
	var start := _ticks
	for i: int in range(budget + 1):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
		elapsed = float(_ticks - start) / Engine.physics_ticks_per_second
		heading_last = float(ship.global_rotation)
		speed_last = float(ship.velocity().length())
		displacement = (ship.global_position - release_position).length()
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=%s t=%.3f error=%.4f omega=%.3f speed=%.3f disp=%.4f"
				% [
					case_id,
					elapsed,
					absf(wrapf(target - heading_last, -PI, PI)),
					ship.impact_body().angular_velocity,
					speed_last,
					displacement,
				]
			)
		if absf(wrapf(target - heading_last, -PI, PI)) <= BEARING_TOLERANCE:
			t_reach = elapsed
			break
	_release_all()

	## The class's own floor on the arrival: no hull can consume a bearing faster than its
	## `turn_rate` allows, and the release adds no thrust to the turn.
	var t_class_min := (start_error - BEARING_TOLERANCE) / rate
	var arrived := t_reach >= 0.0
	var bound_ok := arrived and t_reach >= t_class_min * (1.0 - 0.05)
	print(
		"[G1] result case=%s release_omega=%.3f release_error=%.4f t_reach=%.3f t_class_min=%.3f displacement=%.4f speed_at_reach=%.4f arrived=%s bound_ok=%s"
		% [
			case_id,
			release_omega,
			start_error,
			t_reach,
			t_class_min,
			displacement,
			speed_last,
			arrived,
			bound_ok,
		]
	)
	return bound_ok


## The neutral turn at rest -- the case this file used to run as a heading-hold control,
## re-derived to the owner's own complaint ("when ship is pause trying to turn around moves
## it way too much forward, a ship in space should somewhat be able to do neutral turn"):
## nothing is pressed at all, the cursor sits 90 degrees off the bow, and the nose must come
## about to it while the hull stays exactly where it was parked. `TURN_TRANSLATE_LEAK_MAX`
## (CONTRACTS section 14) is the bound on the displacement.
func _case_neutral_turn_at_rest() -> bool:
	var launched := _launch(HULL_SHIPPED)
	var ship: Variant = launched[0]
	if ship == null:
		print("[G1] note case=neutral_at_rest the hull fixture did not build")
		return false
	var offset := Vector2(AIM_DISTANCE, 0.0).rotated(PI * 0.5)
	var target := offset.angle()
	var origin: Vector2 = ship.global_position
	var start_heading := float(ship.global_rotation)
	var budget := int(HOLD_SECONDS * Engine.physics_ticks_per_second)
	var peak_speed := 0.0
	var displacement := 0.0
	var error := absf(wrapf(target - start_heading, -PI, PI))
	for i: int in range(budget + 1):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
		error = absf(wrapf(target - float(ship.global_rotation), -PI, PI))
		peak_speed = maxf(peak_speed, float(ship.velocity().length()))
		displacement = (ship.global_position - origin).length()
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=neutral_at_rest t=%.3f error=%.4f speed=%.3f disp=%.4f"
				% [
					float(i) / Engine.physics_ticks_per_second,
					error,
					ship.velocity().length(),
					displacement,
				]
			)
		if error <= BEARING_TOLERANCE:
			break
	var swept := absf(wrapf(float(ship.global_rotation) - start_heading, -PI, PI))
	var arrived := error <= BEARING_TOLERANCE
	var leak_ok := displacement <= SHIP_SCRIPT.TURN_TRANSLATE_LEAK_MAX
	var still := peak_speed <= HEADING_TOLERANCE
	print(
		"[G1] result case=neutral_at_rest thrust_held=false cursor_off_bow=%.1fdeg swept_deg=%.3f displacement=%.8f peak_speed=%.8f leak_max=%.1f arrived=%s leak_ok=%s still=%s"
		% [
			rad_to_deg(offset.angle()),
			rad_to_deg(swept),
			displacement,
			peak_speed,
			SHIP_SCRIPT.TURN_TRANSLATE_LEAK_MAX,
			arrived,
			leak_ok,
			still,
		]
	)
	return arrived and leak_ok and still


## ---------------------------------------------------------------------------
## 3. A/D strafe the hull sideways, derived from the class's own rows
## ---------------------------------------------------------------------------


## Hold `strafe_right` alone: the lateral velocity chases the class's own `max_speed` at
## the class's own `max_speed / accel_time`, so it reaches 90 % of the lateral ceiling in
## 90 % of `accel_time` (the chase is linear until the target), while the forward axis, the
## heading and the forward displacement all stay where they were.
func _case_strafe(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[G1] note case=strafe_%s the hull fixture did not build" % hull_id)
		return false
	var case_id := "strafe_%s" % hull_id
	var ceiling: float = stats.max_speed
	var accel_theory: float = ceiling / stats.accel_time
	print(
		"[G1] config case=%s hull=%s max_speed=%.3f accel_time=%.3f accel_rate=%.3f turn_rate=%.3f"
		% [case_id, hull_id, ceiling, stats.accel_time, accel_theory, stats.turn_rate]
	)
	print(
		"[G1] derived case=%s lateral_ceiling=%.3f (the class's own max_speed, no fraction invented) accel=%.3f (max_speed / accel_time) t_full=%.3f t_90=%.3f"
		% [case_id, ceiling, accel_theory, stats.accel_time, stats.accel_time * 0.9]
	)

	var origin: Vector2 = ship.global_position
	var heading_0 := float(ship.global_rotation)
	Input.action_press(STRAFE_RIGHT)
	var budget := int(MAX_STRAFE_SECONDS * Engine.physics_ticks_per_second)
	var t_90 := -1.0
	var lateral_peak := 0.0
	var forward_peak := 0.0
	var start := _ticks
	for i: int in range(budget + 1):
		## The aim is pinned dead ahead for the same reason the other cases place it: since the
		## 2026-09-22 ruling the cursor steers at zero throttle too, so an unpinned aim (a
		## headless cursor, which sits wherever the viewport says) turns this case into a
		## turn-and-strafe. Pinning it dead ahead is what a pilot pressing only D has -- the
		## pointer resting on the hull -- and it is what isolates the strafe law here. It is
		## placed off the *body's* position (the ship node mirrors it one step late, and a
		## 367 u/s strafe would otherwise present the pin with a 6 u/frame bearing error).
		var body: RigidBody2D = ship.impact_body()
		ship.set_aim_point(
			body.global_position + Vector2.RIGHT.rotated(heading_0) * AIM_DISTANCE
		)
		await get_tree().physics_frame
		_ticks += 1
		var t := float(_ticks - start) / Engine.physics_ticks_per_second
		var forward := Vector2.RIGHT.rotated(float(ship.global_rotation))
		var right := Vector2.RIGHT.rotated(float(ship.global_rotation) + PI * 0.5)
		var velocity: Vector2 = ship.velocity()
		var lateral := velocity.dot(right)
		var along := velocity.dot(forward)
		lateral_peak = maxf(lateral_peak, lateral)
		forward_peak = maxf(forward_peak, absf(along))
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=%s t=%.3f lateral=%.3f forward=%.3f s_lateral=%.3f s_forward=%.3f heading_delta=%.8f"
				% [
					case_id,
					t,
					lateral,
					along,
					(ship.global_position - origin).dot(right),
					(ship.global_position - origin).dot(forward),
					float(ship.global_rotation) - heading_0,
				]
			)
		if t_90 < 0.0 and lateral >= ceiling * 0.9:
			t_90 = t
			break
	_release_all()

	var offset: Vector2 = ship.global_position - origin
	var forward_end := Vector2.RIGHT.rotated(heading_0)
	var s_forward := offset.dot(forward_end)
	var s_lateral := offset.dot(Vector2.RIGHT.rotated(heading_0 + PI * 0.5))
	var heading_delta := absf(float(ship.global_rotation) - heading_0)
	var lateral_ok := t_90 >= 0.0 and absf(t_90 - stats.accel_time * 0.9) <= 0.15
	var forward_ok := forward_peak <= ceiling * CRUISE_TOLERANCE
	var drift_ok := absf(s_forward) <= FORWARD_DRIFT_TOLERANCE
	var heading_ok := heading_delta <= HEADING_TOLERANCE
	var direction_ok := s_lateral > 0.0
	print(
		"[G1] result case=%s t_90=%.3f lateral_peak=%.3f lateral_ceiling=%.3f lateral_ok=%s forward_peak=%.3f forward_ok=%s s_lateral=%.3f s_forward=%.3f drift_ok=%s heading_delta=%.8f heading_ok=%s right_is_right=%s"
		% [
			case_id,
			t_90,
			lateral_peak,
			ceiling,
			lateral_ok,
			forward_peak,
			forward_ok,
			s_lateral,
			s_forward,
			drift_ok,
			heading_delta,
			heading_ok,
			direction_ok,
		]
	)
	return lateral_ok and forward_ok and drift_ok and heading_ok and direction_ok


## W+D at once, with the cursor straight ahead: the nose holds its heading (the cursor
## steering steers to the aim while the strafe pushes sideways) and the track is a 45
## degree diagonal at the class's own `max_speed` -- the clamped vector the strafe's
## derivation shares with the throttle, not a sqrt(2) overspeed.
func _case_strafe_with_thrust() -> bool:
	var launched := _launch(HULL_SHIPPED)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[G1] note case=strafe_with_thrust the hull fixture did not build")
		return false
	var case_id := "strafe_with_thrust"
	var ceiling: float = stats.max_speed
	var offset := Vector2(AIM_DISTANCE, 0.0)
	var heading_0 := float(ship.global_rotation)

	Input.action_press(THRUST)
	Input.action_press(STRAFE_RIGHT)
	var budget := int(MAX_STRAFE_SECONDS * Engine.physics_ticks_per_second)
	var speed_peak := 0.0
	var track_peak := 0.0
	var start := _ticks
	for i: int in range(budget + 1):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
		var t := float(_ticks - start) / Engine.physics_ticks_per_second
		var forward := Vector2.RIGHT.rotated(float(ship.global_rotation))
		var velocity: Vector2 = ship.velocity()
		var speed := velocity.length()
		var track := rad_to_deg(absf(wrapf(velocity.angle() - float(ship.global_rotation), -PI, PI)))
		speed_peak = maxf(speed_peak, speed)
		if speed > ceiling * 0.9:
			track_peak = maxf(track_peak, track)
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=%s t=%.3f speed=%.3f track_deg=%.2f heading_delta=%.6f forward_axis=%.2f"
				% [case_id, t, speed, track, float(ship.global_rotation) - heading_0, forward.angle()]
			)
		if speed >= ceiling - 1.0:
			break
	_release_all()

	var heading_delta := absf(float(ship.global_rotation) - heading_0)
	var speed_ok := speed_peak <= ceiling * (1.0 + 0.02)
	var track_ok := track_peak >= 40.0 and track_peak <= 50.0
	var heading_ok := heading_delta <= 0.05
	print(
		"[G1] result case=%s speed_peak=%.3f ceiling=%.3f sqrt2_ceiling=%.3f speed_ok=%s track_deg=%.2f track_ok=%s heading_delta=%.6f heading_ok=%s"
		% [
			case_id,
			speed_peak,
			ceiling,
			ceiling * sqrt(2.0),
			speed_ok,
			track_peak,
			track_ok,
			heading_delta,
			heading_ok,
		]
	)
	return speed_ok and track_ok and heading_ok


## ---------------------------------------------------------------------------
## Shared fixture and harness
## ---------------------------------------------------------------------------


## One launched hull, the fixture the C3 probe uses: the resolved fit, a throwaway
## `PlayerState` seeded from it, then the shipped `PlayerShip.setup` (which is where
## `_apply_rigid_body` writes the damp, the mass and the inertia).
func _launch(hull_id: StringName) -> Array:
	var stats: Variant = FIT.resolve(hull_id, FIT.STANDARD_FIT)
	if stats == null:
		return [null, null]
	var state: Variant = STATE_SCRIPT.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship: Variant = SHIP_SCENE.instantiate()
	if ship == null:
		return [null, null]
	add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.global_rotation = 0.0
	ship.setup(stats, state, FIT.fitted_ids(FIT.STANDARD_FIT))
	return [ship, stats]


## Hold the throttle with the cursor off the bow for `seconds`, re-placing the aim point on
## the hull every frame so the bearing the nose chases stays constant while it flies.
func _hold_turning(ship: Variant, offset: Vector2, seconds: float, case_id: String) -> void:
	var budget := int(seconds * Engine.physics_ticks_per_second)
	for i: int in range(budget):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[G1] curve case=%s t=%.3f error=%.4f omega=%.3f speed=%.3f"
				% [
					case_id,
					float(i) / Engine.physics_ticks_per_second,
					absf(wrapf(offset.angle() - float(ship.global_rotation), -PI, PI)),
					ship.impact_body().angular_velocity,
					ship.velocity().length(),
				]
			)


func _release_all() -> void:
	Input.action_release(THRUST)
	Input.action_release(STRAFE_RIGHT)
	Input.action_release(STRAFE_LEFT)
