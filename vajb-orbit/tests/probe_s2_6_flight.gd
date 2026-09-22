extends Node
## S2.6 flight-feel probe — R4's measurement half of the owner's 2026-09-22 rulings
## (`CONTRACTS.md` section 14's flight block). The four flight numbers under test are
## `ACCEL_TIME_MULT`, `COAST_TIME_MULT`, `LATERAL_DAMP_MULT` and `STEER_WITHOUT_THROTTLE`;
## this probe flies the *shipped* hull and flight code and logs what they do, so the
## wave's before/after table is a measurement and not a re-derivation.
##
## Run (bounded, headless, no editor):
##   godot --headless --path vajb-orbit res://tests/probe_s2_6_flight.tscn \
##     --fixed-fps 60 --quit-after 30000
##
## The probe self-quits and prints `[S26F] done`; `--quit-after` is the watchdog and every
## loop in the file carries its own hard iteration bound (L82). `--fixed-fps 60` disables
## real-time synchronisation, so one main-loop iteration is exactly one 1/60 s physics step
## and the sample grid is reproducible run to run (the C3 probe's own convention).
##
## The same probe runs against a pre-change tree: it reads the four constants through
## `get_script_constant_map`, so a tree that does not carry them (the wave's before) prints
## `constants=... absent` and still measures, and a tree that does prints their values.
##
## Cases, one signal line per measurement:
##   `constants`      — the ruling constants, as the tree carries them
##   `ramp`           — throttle held, aim dead ahead: t_90, t_full, the derived 0.9 x accel_time
##   `coast`          — throttle released at cruise: t_10, carried distance, per class
##   `decay`          — a pure axial / pure lateral release: the two decay laws, measured
##   `neutral_turn`   — the CURSOR route at zero throttle: swept heading, displacement, speed
##   `throttled_turn` — the same turn with the throttle held: the forward lurch the owner
##                      complains about, and the sideways (skid) component at the lean's end
##   `mirror`         — the neutral turn left against the same turn right, mirrored within 1 %
##   `damp`           — Godot's own linear-damp integration, measured (diagnostic)
##
## Signal lines: `[S26F] engine|constants|ramp|coast|decay|neutral_turn|throttled_turn|mirror|damp|note|done`.

const SHIP_SCENE := preload("res://game/player_ship.tscn")
const FIT := preload("res://game/ship_fit.gd")
const STATE_SCRIPT := preload("res://game/player_state.gd")

const THRUST: StringName = &"thrust_forward"

## The ruling's constants, read through the script's own constant map so a pre-change tree
## (which carries none of them) is measured rather than refused.
const RULING_CONSTANTS: Array[StringName] = [
	&"ACCEL_TIME_MULT",
	&"COAST_TIME_MULT",
	&"LATERAL_DAMP_MULT",
	&"STEER_WITHOUT_THROTTLE",
	&"TURN_TRANSLATE_LEAK_MAX",
]

## Every class of section 13's handling column: the ramp and the two decays are cheap
## enough to measure on all nine, which is what "per class" means in the report.
const CLASSES: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_corvette",
	&"ship_freighter",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]

## The two ends of the turn curve plus the shipped launch, for the turn cases.
const TURN_CLASSES: Array[StringName] = [&"ship_fighter", &"ship_vanguard", &"ship_freighter"]

const SAMPLE_TICKS := 12
const AIM_DISTANCE := 4000.0
const CRUISE_TOLERANCE := 0.5
const TEN_PERCENT := 0.10
const NINETY_PERCENT := 0.90
const STOP_SPEED := 1.0
## The axial release starts here, well below every class ceiling and well above the
## 1 u/s "stopped" line, so both decays are measured on the same envelope.
const RELEASE_SPEED := 200.0

const MAX_RAMP_SECONDS := 40.0
const MAX_COAST_SECONDS := 24.0
## The slowest class turns at 0.75 rad/s = 8.4 s per revolution; 30 s is over three
## revolutions of slack and still bounds a broken run.
const MAX_TURN_SECONDS := 30.0
const LEAN_SECONDS := 1.5
## The mirror pair runs for half the full-turn budget, which is over the 90 degrees both
## sides need to show a signed asymmetry.
const MIRROR_SECONDS := 4.0

var _failures := 0
var _ticks := 0
var _ships: Array[Node] = []


func _ready() -> void:
	print(
		"[S26F] engine=%s physics_hz=%d max_fps=%d"
		% [
			Engine.get_version_info().get(&"string", "?"),
			Engine.physics_ticks_per_second,
			Engine.max_fps,
		]
	)
	print("[S26F] cmdline=%s" % " ".join(OS.get_cmdline_args()))
	print("[S26F] input thrust_forward=%s" % str(InputMap.has_action(THRUST)))
	_print_constants()
	await _measure_damp_formula()
	## A warm-up frame before the first case (the C3 probe's reason): a hull added from
	## `_ready` enters the tree between physics steps, one added from inside a callback
	## enters during one, and the two do not put their first processed frame on the same tick.
	await get_tree().physics_frame

	for hull_id: StringName in CLASSES:
		if not await _case_ramp_and_coast(hull_id):
			_failures += 1
		if not await _case_axial_decay(hull_id, false):
			_failures += 1
		if not await _case_axial_decay(hull_id, true):
			_failures += 1
	for hull_id: StringName in TURN_CLASSES:
		if not await _case_neutral_turn(hull_id):
			_failures += 1
		if not await _case_throttled_turn(hull_id):
			_failures += 1
	if not await _case_mirror(&"ship_vanguard"):
		_failures += 1

	_release_all()
	_free_ships()
	print(
		"[S26F] clock iterations=%d physics_frames=%d wall_ms=%d"
		% [Engine.get_process_frames(), Engine.get_physics_frames(), Time.get_ticks_msec()]
	)
	print("[S26F] done failures=%d" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


## ---------------------------------------------------------------------------
## 0. What this tree carries, and how Godot integrates a damp
## ---------------------------------------------------------------------------


func _print_constants() -> void:
	## `get_script_constant_map` is a `Script` method, and a `preload` handle reads as the
	## class itself in GDScript -- so the receiver is typed `Script` on purpose here.
	var script_object: Script = FIT
	var constants: Dictionary = script_object.get_script_constant_map()
	var parts: Array[String] = []
	var missing := 0
	for name: StringName in RULING_CONSTANTS:
		if constants.has(name):
			parts.append("%s=%s" % [name, str(constants[name])])
		else:
			parts.append("%s=absent" % name)
			missing += 1
	print("[S26F] constants %s missing=%d" % [", ".join(parts), missing])


## Godot's own damp integration, measured rather than assumed: a body at a known velocity
## with a known `linear_damp`, one physics step, and the ratio back. It is diagnostic -- the
## ratio is neither the reciprocal nor the subtractive form to the digit, which is why the
## gate suite integrates the *force* alone and measures its neutral turn from rest, where
## every damp term is multiplied by zero velocity and the two integrations agree exactly.
func _measure_damp_formula() -> void:
	var body := RigidBody2D.new()
	body.gravity_scale = 0.0
	body.mass = 1.0
	body.linear_damp = 3.0
	body.can_sleep = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	body.add_child(shape)
	add_child(body)
	await get_tree().physics_frame
	body.linear_velocity = Vector2(100.0, 0.0)
	var v0 := body.linear_velocity.x
	await get_tree().physics_frame
	await get_tree().physics_frame
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	print(
		"[S26F] damp v0=%.3f v1=%.3f ratio=%.8f reciprocal=%.8f subtractive=%.8f dt=%.6f"
		% [
			v0,
			body.linear_velocity.x,
			body.linear_velocity.x / v0,
			1.0 / (1.0 + 3.0 * dt),
			1.0 - 3.0 * dt,
			dt,
		]
	)
	body.queue_free()


## ---------------------------------------------------------------------------
## 1. The ramp, and the release that follows it
## ---------------------------------------------------------------------------


## Hold the throttle with the aim pinned dead ahead — the cursor route then commands no
## turn (the bearing error is zero), so this is a straight-line ramp whatever
## `STEER_WITHOUT_THROTTLE` says — and measure when the hull passes 90 % and 100 % of its
## own `max_speed`, then release and measure the coast envelope.
func _case_ramp_and_coast(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[S26F] note case=ramp_%s the hull fixture did not build" % hull_id)
		return false
	var case_id := "ramp_%s" % hull_id
	var cruise: float = stats.max_speed
	var accel_rate: float = cruise / stats.accel_time
	print(
		"[S26F] ramp hull=%s accel_time=%.4f coast_time=%.4f accel_rate=%.4f coast_rate=%.4f max_speed=%.3f damp_forward=%.6f damp_lateral=%.6f"
		% [
			hull_id,
			stats.accel_time,
			stats.coast_time,
			accel_rate,
			cruise / stats.coast_time,
			cruise,
			_reading(ship, &"_linear_damp"),
			_reading(ship, &"_lateral_damp"),
		]
	)
	Input.action_press(THRUST)
	var budget := int(MAX_RAMP_SECONDS * Engine.physics_ticks_per_second)
	var t_90 := -1.0
	var t_full := -1.0
	var start := _ticks
	var origin: Vector2 = ship.global_position
	for i: int in range(budget + 1):
		_pin_aim(ship)
		await get_tree().physics_frame
		_ticks += 1
		var speed := float(ship.velocity().length())
		var t := float(_ticks - start) / Engine.physics_ticks_per_second
		if (i % SAMPLE_TICKS) == 0:
			print("[S26F] curve case=ramp_%s t=%.3f speed=%.3f" % [hull_id, t, speed])
		if t_90 < 0.0 and speed >= NINETY_PERCENT * cruise:
			t_90 = t
		if t_full < 0.0 and speed >= cruise - CRUISE_TOLERANCE:
			t_full = t
			break
	if t_full < 0.0:
		_release_all()
		print(
			"[S26F] note case=%s never reached %.3f u/s (top speed %.3f); coast not measured"
			% [case_id, cruise, ship.velocity().length()]
		)
		return false
	var released_at: Vector2 = ship.global_position
	_release_all()
	print(
		"[S26F] ramp_result hull=%s t_90=%.3f t_full=%.3f derived_t_90=%.3f ratio_to_derived=%.4f accel_distance=%.2f"
		% [
			hull_id,
			t_90,
			t_full,
			NINETY_PERCENT * stats.accel_time,
			t_90 / (NINETY_PERCENT * stats.accel_time),
			(released_at - origin).length(),
		]
	)

	## The release: the throttle is already released, the aim is still pinned dead ahead,
	## and the coast is `_step_speed(0, _coast_rate())` braking the velocity along the nose.
	var decay_budget := int(MAX_COAST_SECONDS * Engine.physics_ticks_per_second)
	var v_release := float(ship.velocity().length())
	var t_10 := -1.0
	var dist_10 := 0.0
	var t_stop := -1.0
	var stop_start := _ticks
	for i: int in range(decay_budget + 1):
		_pin_aim(ship)
		await get_tree().physics_frame
		_ticks += 1
		var speed := float(ship.velocity().length())
		var t := float(_ticks - stop_start) / Engine.physics_ticks_per_second
		if (i % SAMPLE_TICKS) == 0:
			print("[S26F] curve case=coast_%s t=%.3f speed=%.3f" % [hull_id, t, speed])
		if t_10 < 0.0 and speed <= TEN_PERCENT * v_release:
			t_10 = t
			dist_10 = (ship.global_position - released_at).length()
		if t_stop < 0.0 and speed <= STOP_SPEED:
			t_stop = t
			break
	print(
		"[S26F] coast hull=%s v_release=%.3f t_10=%.3f dist_10=%.2f t_stop=%.3f derived_t_10=%.3f"
		% [hull_id, v_release, t_10, dist_10, t_stop, NINETY_PERCENT * stats.coast_time]
	)
	return t_10 >= 0.0


## ---------------------------------------------------------------------------
## 2. The two axial decays: forward carry against sideways skid
## ---------------------------------------------------------------------------


## Nothing is pressed at all. The hull is given `RELEASE_SPEED` along one body axis and
## left alone, so its decay is the shipped law's own: along the nose it is the commanded
## coast (`_step_speed(0, _coast_rate())`, the class's `max_speed / coast_time`), across the
## nose it is the body's damp plus the explicit lateral drag. The two time constants are
## what `COAST_TIME_MULT` / `LATERAL_DAMP_MULT` decide.
func _case_axial_decay(hull_id: StringName, lateral: bool) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[S26F] note case=decay_%s the hull fixture did not build" % hull_id)
		return false
	var axis_name := "lateral" if lateral else "axial"
	var body: RigidBody2D = ship.impact_body()
	var heading := float(body.global_rotation)
	var axis := Vector2.RIGHT.rotated(heading + (PI * 0.5 if lateral else 0.0))
	body.linear_velocity = axis * RELEASE_SPEED
	body.angular_velocity = 0.0
	var origin: Vector2 = body.global_position
	var budget := int(MAX_COAST_SECONDS * Engine.physics_ticks_per_second)
	var t_10 := -1.0
	var dist_10 := 0.0
	var t_stop := -1.0
	for i: int in range(budget + 1):
		_pin_aim(ship)
		await get_tree().physics_frame
		_ticks += 1
		var velocity: Vector2 = body.linear_velocity
		var speed := velocity.length()
		var t := float(i) / Engine.physics_ticks_per_second
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[S26F] curve case=decay_%s_%s t=%.3f along=%.3f speed=%.3f"
				% [hull_id, axis_name, t, velocity.dot(axis), speed]
			)
		if t_10 < 0.0 and speed <= TEN_PERCENT * RELEASE_SPEED:
			t_10 = t
			dist_10 = (body.global_position - origin).length()
		if t_stop < 0.0 and speed <= STOP_SPEED:
			t_stop = t
			break
	print(
		"[S26F] decay hull=%s axis=%s v0=%.1f t_10=%.3f dist_10=%.2f t_stop=%.3f damp_forward=%.6f damp_lateral=%.6f"
		% [
			hull_id,
			axis_name,
			RELEASE_SPEED,
			t_10,
			dist_10,
			t_stop,
			_reading(ship, &"_linear_damp"),
			_reading(ship, &"_lateral_damp"),
		]
	)
	return t_10 >= 0.0


## ---------------------------------------------------------------------------
## 3. The neutral turn at zero throttle, on the cursor route
## ---------------------------------------------------------------------------


## The owner's complaint, measured on the route they have: no key is pressed at all, and
## the cursor is held 90 degrees off the bow (re-placed on the hull every frame, so the
## bearing the nose chases stays constant). A hull that turns neutrally sweeps a full
## revolution without translating; `TURN_TRANSLATE_LEAK_MAX` is the bound on the
## displacement. This case is the acceptance's own route — a synthetic `turn_left` press
## applies torque only in every tree, including the broken one, and proves nothing.
func _case_neutral_turn(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[S26F] note case=neutral_%s the hull fixture did not build" % hull_id)
		return false
	var body: RigidBody2D = ship.impact_body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	var origin: Vector2 = body.global_position
	var budget := int(MAX_TURN_SECONDS * Engine.physics_ticks_per_second)
	var sweep := 0.0
	var previous := float(body.global_rotation)
	var peak_speed := 0.0
	var displacement := 0.0
	var seconds := -1.0
	for i: int in range(budget + 1):
		ship.set_aim_point(ship.global_position + _off_bow(body, PI * 0.5))
		await get_tree().physics_frame
		_ticks += 1
		var heading := float(body.global_rotation)
		sweep += absf(wrapf(heading - previous, -PI, PI))
		previous = heading
		peak_speed = maxf(peak_speed, float(body.linear_velocity.length()))
		displacement = (body.global_position - origin).length()
		if (i % SAMPLE_TICKS) == 0:
			print(
				"[S26F] curve case=neutral_%s t=%.3f sweep_deg=%.2f disp=%.4f speed=%.3f omega=%.3f"
				% [
					hull_id,
					float(i) / Engine.physics_ticks_per_second,
					rad_to_deg(sweep),
					displacement,
					body.linear_velocity.length(),
					body.angular_velocity,
				]
			)
		if sweep >= TAU:
			seconds = float(i) / Engine.physics_ticks_per_second
			break
	print(
		"[S26F] neutral_turn hull=%s sweep_deg=%.3f revolution_s=%.3f displacement=%.6f peak_speed=%.6f turn_rate=%.3f"
		% [hull_id, rad_to_deg(sweep), seconds, displacement, peak_speed, stats.turn_rate]
	)
	return true


## ---------------------------------------------------------------------------
## 4. The same turn with the throttle held: the forward lurch, and the sideways skid
## ---------------------------------------------------------------------------


## The pilot's workaround in the broken tree (`W` held, because the cursor route needs it)
## and the flight the owner complained about: "when ship is pause trying to turn around
## moves it way too much forward". The displacement is read in the hull's start frame, so
## "forward" is the direction the pilot was facing; the lateral velocity is read in the
## hull's own frame at the end of the lean, so the sign says whether the hull skids *out* of
## the turn (positive on the hull's right when turning right) and the magnitude says how far.
func _case_throttled_turn(hull_id: StringName) -> bool:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	var stats: Variant = launched[1]
	if ship == null or stats == null:
		print("[S26F] note case=throttled_%s the hull fixture did not build" % hull_id)
		return false
	var body: RigidBody2D = ship.impact_body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	var origin: Vector2 = body.global_position
	var start_heading := float(body.global_rotation)
	## Right-hand turn: the cursor sits 90 degrees to the hull's right.
	var offset := Vector2(AIM_DISTANCE, 0.0).rotated(PI * 0.5)
	var lean_budget := int(LEAN_SECONDS * Engine.physics_ticks_per_second)
	Input.action_press(THRUST)
	for i: int in range(lean_budget):
		ship.set_aim_point(ship.global_position + offset)
		await get_tree().physics_frame
		_ticks += 1
	_release_all()
	var swept := absf(wrapf(float(body.global_rotation) - start_heading, -PI, PI))
	var displacement: Vector2 = body.global_position - origin
	var nose := Vector2.RIGHT.rotated(float(body.global_rotation))
	var side := Vector2.RIGHT.rotated(float(body.global_rotation) + PI * 0.5)
	var forward_disp := displacement.dot(Vector2.RIGHT.rotated(start_heading))
	var lateral_disp := displacement.dot(Vector2.RIGHT.rotated(start_heading + PI * 0.5))
	var lateral_v := body.linear_velocity.dot(side)
	print(
		"[S26F] throttled_turn hull=%s t=%.3f swept_deg=%.3f forward_disp=%.3f lateral_disp=%.3f speed=%.3f forward_v=%.3f lateral_v=%.3f skid_out=%s"
		% [
			hull_id,
			LEAN_SECONDS,
			rad_to_deg(swept),
			forward_disp,
			lateral_disp,
			body.linear_velocity.length(),
			body.linear_velocity.dot(nose),
			lateral_v,
			str(lateral_v > 0.0),
		]
	)
	return true


## ---------------------------------------------------------------------------
## 5. Mirrored maneuvers
## ---------------------------------------------------------------------------


## The same neutral turn, once to the right and once to the left: the swept heading and the
## displacement of one must be the other's mirror within one percent. A single-sided force
## anywhere in the turn path shows up here and nowhere else.
func _case_mirror(hull_id: StringName) -> bool:
	var right := await _mirror_run(hull_id, 1.0)
	var left := await _mirror_run(hull_id, -1.0)
	if right.is_empty() or left.is_empty():
		print("[S26F] note case=mirror the hull fixture did not build")
		return false
	var sweep_error := _relative_error(absf(float(right[&"sweep"])), absf(float(left[&"sweep"])))
	var distance_error := _relative_error(
		float(right[&"distance"]), float(left[&"distance"])
	)
	var ok := sweep_error <= 0.01 and distance_error <= 0.01
	print(
		"[S26F] mirror hull=%s sweep_right_deg=%.6f sweep_left_deg=%.6f sweep_error=%.6f distance_right=%.6f distance_left=%.6f distance_error=%.6f mirrored=%s"
		% [
			hull_id,
			rad_to_deg(float(right[&"sweep"])),
			rad_to_deg(float(left[&"sweep"])),
			sweep_error,
			float(right[&"distance"]),
			float(left[&"distance"]),
			distance_error,
			str(ok),
		]
	)
	return ok


func _mirror_run(hull_id: StringName, sign: float) -> Dictionary:
	var launched := _launch(hull_id)
	var ship: Variant = launched[0]
	if ship == null:
		return {}
	var body: RigidBody2D = ship.impact_body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	var origin: Vector2 = body.global_position
	var budget := int(MIRROR_SECONDS * Engine.physics_ticks_per_second)
	var sweep := 0.0
	var previous := float(body.global_rotation)
	for i: int in range(budget):
		ship.set_aim_point(ship.global_position + _off_bow(body, PI * 0.5 * sign))
		await get_tree().physics_frame
		_ticks += 1
		var heading := float(body.global_rotation)
		sweep += wrapf(heading - previous, -PI, PI)
		previous = heading
	var displacement: Vector2 = body.global_position - origin
	return {
		&"sweep": sweep,
		&"distance": displacement.length(),
	}


## A ratio of the difference to the larger of the two, with the zero case defined as 0
## (two dead-still turns are mirrored exactly, and dividing by zero is not the way to say so).
func _relative_error(a: float, b: float) -> float:
	var scale := maxf(a, b)
	if is_zero_approx(scale):
		return 0.0
	return absf(a - b) / scale


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## One float off a shipped seam, answered as 0.0 when the tree does not carry it: the four
## ruling constants and the lateral-damp seam are exactly what the *before* tree lacks, and
## the probe's job is to measure that tree too rather than refuse it.
func _reading(ship: Variant, method: StringName) -> float:
	if not ship.has_method(method):
		return 0.0
	return float(ship.call(method))


## The aim point pinned dead ahead (the hull's own nose at `AIM_DISTANCE`), which commands
## no turn: the bearing error is zero, so the ramp and the coasts are straight lines in both
## trees (the cursor route is throttle-gated in the before tree, and a dead-ahead pin is
## inside nobody's deadzone).
func _pin_aim(ship: Variant) -> void:
	var body: RigidBody2D = ship.impact_body()
	ship.set_aim_point(ship.global_position + _off_bow(body, 0.0))


## A point `angle` radians off the hull's *current* bow, in world space: re-placing this
## every frame is a pilot steering into a turn (a fixed world offset would be a bearing to
## arrive at, which is the G1 probe's cursor case and not the neutral turn's).
func _off_bow(body: RigidBody2D, angle: float) -> Vector2:
	return Vector2.RIGHT.rotated(float(body.global_rotation) + angle) * AIM_DISTANCE


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
	_ships.append(ship)
	return [ship, stats]


func _release_all() -> void:
	Input.action_release(THRUST)


func _free_ships() -> void:
	for ship: Node in _ships:
		if is_instance_valid(ship) and not ship.is_queued_for_deletion():
			var parent := ship.get_parent()
			if parent != null:
				parent.remove_child(ship)
			ship.free()
	_ships.clear()
