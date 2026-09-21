extends Node
## C3 flight-decay probe — the measurement half of the owner's "weird drag" ruling
## (2026-09-21). It flies the *shipped* player hull and flight code, releases the
## throttle through the real `Input` action the game reads, and logs the whole decay
## envelope: speed and distance carried, one sample per 0.1 s, until the hull is
## effectively stopped. Nothing is retuned here; C5 retunes with these numbers.
##
## Run (bounded, headless, no editor):
##   godot --headless --path vajb-orbit res://tests/probe_c3_flight_decay.tscn \
##     --fixed-fps 60 --quit-after 12000
##
## `--fixed-fps 60` is load-bearing: it disables real-time synchronisation, so one
## main-loop iteration is exactly one 1/60 s physics step and the 0.1 s sample grid
## is reproducible run to run. Without it the physics clock is driven by wall time
## and a bounded run can truncate the simulation. The probe self-quits and prints
## `[C3] done`; `--quit-after` is the watchdog.
##
## The probe exercises the release path the owner described: `thrust_forward` is
## held until the hull is at its cruise speed, then released. In `player_ship.gd`
## that is the no-move-target branch — `throttle = 0` so `desired_speed = 0` and
## `rate = _coast_rate()` — and the decay that follows is `_step_speed` braking the
## velocity along the heading down at the class coast rate while the body's own
## `linear_damp` is compensated for on that axis.
##
## Signal lines: `[C3] engine|config|curve|result|derived|legacy|note|done`.
## Exit code 0 only when every case measured a real accelerate -> release -> decay
## cycle (reached cruise, and came to the probe's "stopped" line).

const SHIP_SCENE := preload("res://game/player_ship.tscn")
const SHIP_SCRIPT := preload("res://game/player_ship.gd")
const FIT := preload("res://game/ship_fit.gd")
const STATE_SCRIPT := preload("res://game/player_state.gd")

## The shipped launch: `game.gd:HULL_ID_DEFAULT` = `ship_vanguard` with
## `ShipFit.STANDARD_FIT` (09 section 7). The Fighter rides along as the fastest
## class in the section 13 handling column, so the column's own spread is visible.
const HULL_SHIPPED: StringName = &"ship_vanguard"
const HULL_FASTEST: StringName = &"ship_fighter"

## The only implemented booster (09 section 3.5 / CONTRACTS section 4):
## `boost_speed_mult` 1.6, `duration` 3.0 s, `cooldown` 8.0 s.
const BOOSTER: StringName = &"b_afterburner"

const THRUST: StringName = &"thrust_forward"
const BOOST: StringName = &"boost"

const SAMPLE_TICKS := 6
const SAMPLE_SECONDS := 0.1
## "Effectively stopped" for the distance-carried figure: section 13's slowest
## contact floor is 40 u/s, so 1 u/s is well below anything the game can act on and
## what remains after the ramp is measurement tail.
const STOP_SPEED := 1.0
const TEN_PERCENT := 0.10

const CRUISE_TOLERANCE := 0.5
const MAX_ACCEL_SECONDS := 30.0
## section 13's heaviest coast row is the Hauler's 5.2 s (x1.05 plating = 5.46 s);
## 12 s is double the worst case and still bounds a broken run.
const MAX_DECAY_SECONDS := 12.0

## One row per measured envelope. `boost` lights the afterburner at cruise;
## `release_boost` decides whether the burn is also released at the release frame
## (the last row holds it, which is the control proving the burn only raises the
## starting speed and does not drive the decay).
const CASES: Array[Dictionary] = [
	{
		&"id": "shipped_base",
		&"hull": HULL_SHIPPED,
		&"boost": false,
		&"release_boost": false,
		&"note": "the shipped launch, throttle released at cruise",
	},
	{
		&"id": "fighter_base",
		&"hull": HULL_FASTEST,
		&"boost": false,
		&"release_boost": false,
		&"note": "the fastest class in the section 13 column, same release",
	},
	{
		&"id": "shipped_afterburner",
		&"hull": HULL_SHIPPED,
		&"boost": true,
		&"release_boost": true,
		&"note": "burn lit at cruise, then thrust and burn released",
	},
	{
		&"id": "shipped_afterburner_burn_lit",
		&"hull": HULL_SHIPPED,
		&"boost": true,
		&"release_boost": false,
		&"note": "burn lit at cruise, thrust released, burn still held (control)",
	},
]

var _failures := 0
var _ticks := 0


func _ready() -> void:
	print(
		"[C3] engine=%s physics_hz=%d max_fps=%d"
		% [
			Engine.get_version_info().get(&"string", "?"),
			Engine.physics_ticks_per_second,
			Engine.max_fps,
		]
	)
	print("[C3] cmdline=%s" % " ".join(OS.get_cmdline_args()))
	print(
		"[C3] input thrust_forward=%s boost=%s"
		% [InputMap.has_action(THRUST), InputMap.has_action(BOOST)]
	)
	## One warm-up frame before the first case: a hull added from `_ready` enters the tree
	## between physics steps, one added from inside a physics callback enters during one,
	## and the two do not put their first processed frame on the same tick. Waiting here
	## makes every case enter the tree the same way, so the 0.1 s sample grid is exact for
	## all of them (not counted in `_ticks`: no case depends on it).
	await get_tree().physics_frame
	for row: Dictionary in CASES:
		if not await _run_case(row):
			_failures += 1
	_release_all()
	print(
		"[C3] clock iterations=%d physics_frames=%d wall_ms=%d"
		% [Engine.get_process_frames(), Engine.get_physics_frames(), Time.get_ticks_msec()]
	)
	print("[C3] done cases=%d failures=%d" % [CASES.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _run_case(row: Dictionary) -> bool:
	var case_id: String = row[&"id"]
	var hull_id: StringName = row[&"hull"]
	var fit := _fit_for(row)
	var stats: Variant = FIT.resolve(hull_id, fit)
	if stats == null:
		print("[C3] note case=%s resolve(%s) returned null" % [case_id, hull_id])
		return false

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
		print("[C3] note case=%s player_ship.tscn failed to instantiate" % case_id)
		return false
	add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.setup(stats, state, FIT.fitted_ids(fit))
	if ship.get_script() != SHIP_SCRIPT:
		print("[C3] note case=%s instantiated node does not carry player_ship.gd" % case_id)
		return false

	var base_max_speed: float = stats.max_speed
	var coast_rate: float = base_max_speed / stats.coast_time
	print(
		"[C3] config case=%s hull=%s hull_mass=%.1f max_speed=%.3f accel_time=%.3f coast_time=%.3f damp_1_over_coast=%.6f accel_rate=%.3f coast_rate=%.3f boost=%s note=%s"
		% [
			case_id,
			hull_id,
			stats.hull_mass,
			base_max_speed,
			stats.accel_time,
			stats.coast_time,
			1.0 / stats.coast_time,
			base_max_speed / stats.accel_time,
			coast_rate,
			row[&"boost"],
			row[&"note"],
		]
	)
	_print_legacy(case_id, row)

	## Accelerate on the real action the game reads. `Input.action_press` sets the
	## action's state directly (the `Input.parse_input_event` route is documented as
	## inert in a headless run, CONTRACTS section 9's fourth harness limit).
	var boost_mult := 1.0
	if row[&"boost"]:
		boost_mult = _boost_mult()
	var cruise := base_max_speed
	var boosted_cruise := base_max_speed * boost_mult
	var accel_budget := int(MAX_ACCEL_SECONDS * Engine.physics_ticks_per_second)
	Input.action_press(THRUST)
	var accel_start := _ticks
	var reached := await _hold_until(ship, cruise, accel_budget, case_id, "base", accel_start)
	if row[&"boost"] and reached:
		## Light the burn at cruise, not from a standstill: `duration` is 3.0 s and a
		## burn lit at 0 u/s expires before the hull reaches the boosted cruise
		## (2.1 s of base acceleration already eats most of it).
		Input.action_press(BOOST)
		var burn_start := _ticks
		reached = await _hold_until(ship, boosted_cruise, accel_budget, case_id, "boost", burn_start)
	if not reached:
		_release_all()
		print(
			"[C3] note case=%s never reached %.3f u/s (top speed %.3f); not measured"
			% [case_id, boosted_cruise, ship.velocity().length()]
		)
		return false
	print(
		"[C3] phase case=%s t_accel_total=%.3f speed=%.3f (the accelerate leg a retune must not lengthen)"
		% [case_id, float(_ticks - accel_start) / Engine.physics_ticks_per_second, ship.velocity().length()]
	)

	var body: RigidBody2D = ship.impact_body()
	var forward := Vector2.RIGHT.rotated(body.global_rotation)
	var release_position: Vector2 = ship.global_position
	var release_speed: float = ship.velocity().length()

	## THE RELEASE: the throttle action goes up, exactly as the owner's key-up does.
	Input.action_release(THRUST)
	if row[&"release_boost"]:
		Input.action_release(BOOST)

	var release_tick := _ticks
	var samples: Array[Dictionary] = []
	var release_sample := _sample(0.0, ship, release_position, forward)
	samples.append(release_sample)
	_log_sample(case_id, release_sample)
	var budget := int(MAX_DECAY_SECONDS / SAMPLE_SECONDS)
	for k: int in range(1, budget + 1):
		var target_tick := release_tick + k * SAMPLE_TICKS
		while _ticks < target_tick:
			await get_tree().physics_frame
			_ticks += 1
		var sample := _sample(k * SAMPLE_SECONDS, ship, release_position, forward)
		samples.append(sample)
		_log_sample(case_id, sample)
		if float(sample[&"speed"]) <= STOP_SPEED:
			break

	var summary := _summarize(case_id, release_speed, coast_rate, samples)
	_print_summary(summary)
	_release_all()
	## The hull stays in the tree for the life of the probe: it has no thrust left
	## and the probe's tree holds nothing on its collision mask, so it cannot
	## influence a later case. Freeing it while a physics signal is being delivered
	## would be the only risk, and there is nothing to gain from taking it.
	return bool(summary[&"valid"])


## Hold the hull until its speed is within CRUISE_TOLERANCE of `target`, or the
## budget runs out. Returns whether the target was reached. The accelerate leg is
## logged on the same 0.1 s grid as the decay, so the probe covers the whole cycle
## the owner described (press, hold, release) and not only its tail.
func _hold_until(
	ship: Variant, target: float, budget: int, case_id: String, phase: String, start_tick: int
) -> bool:
	var deadline := start_tick + budget
	while _ticks < deadline:
		if ship.velocity().length() >= target - CRUISE_TOLERANCE:
			return true
		await get_tree().physics_frame
		_ticks += 1
		if (_ticks - start_tick) % SAMPLE_TICKS == 0:
			print(
				"[C3] accel case=%s phase=%s t=%.3f speed=%.3f"
				% [
					case_id,
					phase,
					float(_ticks - start_tick) / Engine.physics_ticks_per_second,
					ship.velocity().length(),
				]
			)
	return ship.velocity().length() >= target - CRUISE_TOLERANCE


func _sample(t: float, ship: Variant, origin: Vector2, forward: Vector2) -> Dictionary:
	var velocity: Vector2 = ship.velocity()
	var offset: Vector2 = ship.global_position - origin
	var along := velocity.dot(forward)
	var carried := offset.dot(forward)
	return {
		&"t": t,
		&"speed": velocity.length(),
		&"along": along,
		&"s": carried,
		&"drift": absf(offset.length() - carried),
	}


func _log_sample(case_id: String, sample: Dictionary) -> void:
	print(
		"[C3] curve case=%s t=%.3f speed=%.3f along=%.3f s=%.3f drift=%.3f"
		% [
			case_id,
			sample[&"t"],
			sample[&"speed"],
			sample[&"along"],
			sample[&"s"],
			sample[&"drift"],
		]
	)


## The two numbers a retune must beat, plus the class figures they are compared
## against. `t10`/`dist10` are read off the 0.1 s samples with a linear crossing
## between the two that bracket 10 % of the release speed; `t_stop`/`dist_stop` are
## the first sample at or below STOP_SPEED.
func _summarize(
	case_id: String, release_speed: float, coast_rate: float, samples: Array[Dictionary]
) -> Dictionary:
	var ten := release_speed * TEN_PERCENT
	var t10 := -1.0
	var dist10 := -1.0
	var t_stop := -1.0
	var dist_stop := -1.0
	for index: int in range(samples.size()):
		var sample := samples[index]
		if t10 < 0.0 and float(sample[&"speed"]) <= ten:
			if index > 0:
				var before: Dictionary = samples[index - 1]
				var span := float(before[&"speed"]) - float(sample[&"speed"])
				var fraction := (
					0.0 if is_zero_approx(span) else (float(before[&"speed"]) - ten) / span
				)
				t10 = float(before[&"t"]) + fraction * (float(sample[&"t"]) - float(before[&"t"]))
				dist10 = float(before[&"s"]) + fraction * (float(sample[&"s"]) - float(before[&"s"]))
			else:
				t10 = float(sample[&"t"])
				dist10 = float(sample[&"s"])
		if t_stop < 0.0 and float(sample[&"speed"]) <= STOP_SPEED:
			t_stop = float(sample[&"t"])
			dist_stop = float(sample[&"s"])
	## The derived envelope: the class ramp `max_speed / coast_time` applied from the
	## release speed. A measured curve that tracks it is the shipped law; a curve
	## that does not is a probe bug.
	var ideal_t_stop := release_speed / coast_rate
	var ideal_t10 := ideal_t_stop * (1.0 - TEN_PERCENT)
	var ideal_dist := 0.5 * release_speed * ideal_t_stop
	var monotone := true
	for index: int in range(1, samples.size()):
		if float(samples[index][&"speed"]) > float(samples[index - 1][&"speed"]) + 0.001:
			monotone = false
			break
	return {
		&"case": case_id,
		&"v_release": release_speed,
		&"t10": t10,
		&"dist10": dist10,
		&"t_stop": t_stop,
		&"dist_stop": dist_stop,
		&"samples": samples.size(),
		&"ideal_t_stop": ideal_t_stop,
		&"ideal_t10": ideal_t10,
		&"ideal_dist": ideal_dist,
		&"monotone": monotone,
		&"valid": t10 > 0.0 and t_stop > 0.0 and monotone,
	}


func _print_summary(summary: Dictionary) -> void:
	print(
		"[C3] result case=%s v_release=%.3f t10=%.3f dist10=%.2f t_stop=%.3f dist_stop=%.2f samples=%d monotone=%s"
		% [
			summary[&"case"],
			summary[&"v_release"],
			summary[&"t10"],
			summary[&"dist10"],
			summary[&"t_stop"],
			summary[&"dist_stop"],
			summary[&"samples"],
			summary[&"monotone"],
		]
	)
	print(
		"[C3] derived case=%s ideal_t10=%.3f ideal_t_stop=%.3f ideal_dist=%.2f"
		% [
			summary[&"case"],
			summary[&"ideal_t10"],
			summary[&"ideal_t_stop"],
			summary[&"ideal_dist"],
		]
	)


## `docs/design/IMPLEMENTATION_PLAN.md:410` names a placeholder `DRAG` 120 /
## `ACCELERATION` 420 pair, and the wave brief quotes it as the shipped pair. Neither
## constant exists in the tree: the slice-0 migration to the physics body replaced
## both with the section 13 handling column. Print the substitution so a reader
## holding the old pair can see what drives the decay instead.
func _print_legacy(case_id: String, row: Dictionary) -> void:
	print(
		"[C3] legacy case=%s no_DRAG_no_ACCELERATION_in_tree=true obsolete_pair=DRAG:120,ACCELERATION:420 replaced_by=coast_time(1/coast_time damp + max_speed/coast_time brake),accel_time(max_speed/accel_time) boost=%s"
		% [case_id, row[&"boost"]]
	)


func _boost_mult() -> float:
	var effects: Dictionary = FIT.MODULES[BOOSTER][&"effects"]
	return float(effects[&"boost_speed_mult"])


func _fit_for(row: Dictionary) -> Dictionary:
	var fit: Dictionary = FIT.STANDARD_FIT.duplicate(true)
	if row[&"boost"]:
		fit[&"boosters"] = [BOOSTER]
	return fit


func _release_all() -> void:
	Input.action_release(THRUST)
	Input.action_release(BOOST)
