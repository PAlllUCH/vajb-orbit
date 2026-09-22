extends SceneTree
## S2.6-R2's evidence probe: CONTRACTS §14's "Fragment burst", re-measurable by hand.
##
##   XDG_DATA_HOME=/tmp/s26_R2 godot --headless --path vajb-orbit \
##     --script res://tests/probe_s2_6_burst.gd
##
## One `[S26R2]` line per row, the last is `[S26R2] done failures=N` (exit 1 if any). Nothing
## awaits a frame and no scene is needed: a detached `AsteroidField` builds real
## `RigidBody2D` rocks without a physics world, and every break's velocity is set rather than
## simulated. Every seed is fixed, so two runs print byte-identical rows.
##
## The four things it measures, in the order the pin composes them:
##   PIN      - the constant §14 pins, and the rock's §5 half untouched;
##   STOPPED  - a rock the player stopped: the whole deployed velocity is the kick, and with
##              the kick taken back out the fragment reads the pre-§14 0.0 (the owner's
##              complaint, and this probe's control);
##   SWEEP    - AC2: 200 seeded breaks of a near-stationary rock, the lowest radial component,
##              the deployed-speed band, the per-cleave spread and the quadrant coverage;
##   SHAPE    - the same breaks with a drifting parent: the rolled shape recovered by
##              subtracting the kick (× 1.2 exactly, uniform over the full circle) and the
##              deployed magnitude inside the additive bounds.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")

const TAG := "[S26R2]"
const KICK := 150.0
const HALF_KICK := 0.5 * KICK
const SPEED_EPSILON := 0.01
const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 7331
const FIELD_ROCKS := 6
const NEAR_STATIONARY := 0.4
const DRIFT_SPEED := 120.0
const DRIFT_HEADING := 0.7
const SWEEP_BREAKS := 200
const SHAPE_CLEAVES := 8
const ORIGIN := Vector2(240.0, -80.0)

var _failures: Array[String] = []
var _field: Node2D = null


func _init() -> void:
	_pin()
	_stopped()
	_sweep()
	_shape_rows()
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


## §14's constant, and the rock's half of the pin: the field adds the radial, `eject_velocity()`
## still answers `linear_velocity × 1.2` alone.
func _pin() -> void:
	_check(
		"pin_kick",
		is_equal_approx(FieldScript.FRAGMENT_OUTWARD_KICK, KICK),
		"field kick=%.1f u/s" % FieldScript.FRAGMENT_OUTWARD_KICK
	)
	var field := _field_with(FIELD_SEED)
	var rock: Node2D = field.call(
		&"_new_rock", "Pin", &"iron", 1, 4, AsteroidScript.SIZE_LARGE
	)
	var heading := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	(rock as RigidBody2D).linear_velocity = heading
	var shape: Vector2 = rock.call(&"eject_velocity")
	_check(
		"pin_shape_half",
		shape.is_equal_approx(heading * AsteroidScript.FRAGMENT_EJECT_MULT),
		"eject_velocity()=%s for a parent at %s (mult %.2f, cone %.1f deg)"
			% [shape, heading, AsteroidScript.FRAGMENT_EJECT_MULT,
			AsteroidScript.FRAGMENT_EJECT_CONE_DEG]
	)
	field.free()


## The owner's rock: stopped. Every fragment's velocity is the kick along its own placement
## radial, and the residual -- the deployed velocity with the kick subtracted -- is the 0.0
## the pre-§14 tree ejected, which is what makes the residual a control rather than algebra.
func _stopped() -> void:
	_field_with(FIELD_SEED)
	var fragments := _break_member("Stopped", Vector2.ZERO)
	var residual_max := 0.0
	var radial_error := 0.0
	var speed_error := 0.0
	for fragment: Node2D in fragments:
		var deployed := (fragment as RigidBody2D).linear_velocity
		var radial := (fragment.global_position - ORIGIN).normalized()
		residual_max = maxf(residual_max, (deployed - radial * KICK).length())
		radial_error = maxf(radial_error, absf(deployed.dot(radial) - KICK))
		speed_error = maxf(speed_error, absf(deployed.length() - KICK))
	print("%s STOPPED fragments=%d residual_max=%.6f radial_error_max=%.6f speed_error_max=%.6f"
		% [TAG, fragments.size(), residual_max, radial_error, speed_error])
	_check(
		"stopped_is_the_kick",
		fragments.size() >= 2
			and residual_max <= SPEED_EPSILON
			and radial_error <= SPEED_EPSILON
			and speed_error <= SPEED_EPSILON,
		"a stopped rock's %d fragments are the kick alone, all of it radial" % fragments.size()
	)


## AC2 over 200 distinct seeded breaks of a near-stationary rock.
func _sweep() -> void:
	var velocity := Vector2(NEAR_STATIONARY, 0.0).rotated(DRIFT_HEADING)
	var shape := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
	var lowest := INF
	var slowest := INF
	var fastest := 0.0
	var total := 0
	var narrowest := INF
	var narrowest_cleave := -1
	var quadrants: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
	for index in SWEEP_BREAKS:
		var field := _field_with(FIELD_SEED + index)
		var angles: Array[float] = []
		for fragment: Node2D in _break_member("Sweep%d" % index, velocity):
			var radial := (fragment.global_position - ORIGIN).normalized()
			var deployed := (fragment as RigidBody2D).linear_velocity
			lowest = minf(lowest, deployed.dot(radial))
			slowest = minf(slowest, deployed.length())
			fastest = maxf(fastest, deployed.length())
			angles.append(rad_to_deg(radial.angle()))
			var quadrant := int(floor(fposmod(radial.angle(), TAU) / (TAU / 4.0)))
			quadrants[quadrant] = int(quadrants[quadrant]) + 1
			total += 1
		var widest := _widest(angles)
		if widest < narrowest:
			narrowest = widest
			narrowest_cleave = index
		field.free()
	print("%s SWEEP breaks=%d fragments=%d radial_min=%.3f floor=%.3f speed=%.3f..%.3f (shape %.3f)"
		% [TAG, SWEEP_BREAKS, total, lowest, HALF_KICK, slowest, fastest, shape])
	print("%s SWEEP spread_min=%.3f deg (cleave %d) quadrants=%s"
		% [TAG, narrowest, narrowest_cleave, str(quadrants)])
	_check(
		"ac2_radial_floor",
		lowest > HALF_KICK and total > 2 * SWEEP_BREAKS,
		"AC2 holds over %d fragments: the lowest radial component is %.3f u/s" % [total, lowest]
	)
	_check(
		"ac2_kick_band",
		slowest >= KICK - shape - SPEED_EPSILON and fastest <= KICK + shape + SPEED_EPSILON,
		"a near-stationary rock's burst is the kick +- the %.3f u/s shape it carries" % shape
	)
	_check(
		"ac2_spread",
		narrowest > 90.0 and int(quadrants[0]) > 0 and int(quadrants[1]) > 0
			and int(quadrants[2]) > 0 and int(quadrants[3]) > 0,
		"every direction still leaves: the narrowest cleave spans %.3f deg and all four"
			% narrowest + " quadrants are populated"
	)


## The shape's half, read back out of a drifting rock's burst: `× 1.2` exactly and uniform
## over the full circle, with the deployed magnitude inside the additive bounds.
func _shape_rows() -> void:
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	var shape := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
	var ratio_low := INF
	var ratio_high := 0.0
	var deployed_low := INF
	var deployed_high := 0.0
	var raw_beyond := 0
	var shape_beyond := 0
	var widest_raw := 0.0
	var widest_shape := 0.0
	var total := 0
	for index in SHAPE_CLEAVES:
		var field := _field_with(FIELD_SEED + index)
		var raw_here: Array[float] = []
		var shape_here: Array[float] = []
		for fragment: Node2D in _break_member("Shape%d" % index, velocity):
			var radial := (fragment.global_position - ORIGIN).normalized()
			var deployed := (fragment as RigidBody2D).linear_velocity
			var residual := deployed - radial * KICK
			var ratio := residual.length() / velocity.length()
			ratio_low = minf(ratio_low, ratio)
			ratio_high = maxf(ratio_high, ratio)
			deployed_low = minf(deployed_low, deployed.length())
			deployed_high = maxf(deployed_high, deployed.length())
			var raw_deviation := rad_to_deg(velocity.angle_to(deployed))
			var shape_deviation := rad_to_deg(velocity.angle_to(residual))
			raw_here.append(raw_deviation)
			shape_here.append(shape_deviation)
			if absf(raw_deviation) > 90.0:
				raw_beyond += 1
			if absf(shape_deviation) > 90.0:
				shape_beyond += 1
			total += 1
		widest_raw = maxf(widest_raw, _widest(raw_here))
		widest_shape = maxf(widest_shape, _widest(shape_here))
		field.free()
	print("%s SHAPE parent=%.1f fragments=%d shape_ratio=%.9f..%.9f (want %.4f)"
		% [TAG, velocity.length(), total, ratio_low, ratio_high,
		AsteroidScript.FRAGMENT_EJECT_MULT])
	print("%s SHAPE deployed=%.3f..%.3f bounds=%.3f..%.3f spread=%.3f"
		% [TAG, deployed_low, deployed_high, absf(shape - KICK), shape + KICK,
		deployed_high - deployed_low])
	print("%s SHAPE dir raw_beyond90=%d/%d raw_widest=%.3f shape_beyond90=%d/%d shape_widest=%.3f"
		% [TAG, raw_beyond, total, widest_raw, shape_beyond, total, widest_shape])
	_check(
		"shape_is_x1_2",
		is_equal_approx(ratio_low, AsteroidScript.FRAGMENT_EJECT_MULT)
			and is_equal_approx(ratio_high, AsteroidScript.FRAGMENT_EJECT_MULT),
		"the residual is the parent's velocity x %s for all %d fragments"
			% [AsteroidScript.FRAGMENT_EJECT_MULT, total]
	)
	_check(
		"deployed_inside_bounds",
		deployed_low >= absf(shape - KICK) - SPEED_EPSILON
			and deployed_high <= shape + KICK + SPEED_EPSILON
			and deployed_low < KICK and deployed_high > KICK,
		"the burst is shape + kick: %.3f..%.3f inside %.3f..%.3f"
			% [deployed_low, deployed_high, absf(shape - KICK), shape + KICK]
	)
	_check(
		"roll_is_the_full_circle",
		shape_beyond > 0 and widest_shape > 90.0 and raw_beyond > 0 and widest_raw > 90.0,
		"the rolled shape alone still spans %.3f deg (raw %.3f)" % [widest_shape, widest_raw]
	)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _field_with(seed_value: int, count: int = FIELD_ROCKS) -> Node2D:
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": seed_value,
	})
	return _field


func _break_member(node_name: String, velocity: Vector2) -> Array[Node2D]:
	var rock: Node2D = _field.call(
		&"_new_rock", node_name, &"iron", 1, 4, AsteroidScript.SIZE_LARGE
	)
	rock.position = ORIGIN
	(rock as RigidBody2D).linear_velocity = velocity
	var before: Array[int] = []
	for node: Node2D in _field.call(&"rocks"):
		before.append(node.get_instance_id())
	rock.call(&"apply_work", maxf(
		float(int(rock.get(&"yield_units"))), AsteroidScript.WORK_PER_UNIT
	))
	var out: Array[Node2D] = []
	for node: Node2D in _field.call(&"rocks"):
		if not before.has(node.get_instance_id()):
			out.append(node)
	return out


func _widest(values: Array[float]) -> float:
	var widest := 0.0
	for a: float in values:
		for b: float in values:
			widest = maxf(widest, absf(wrapf(a - b, -180.0, 180.0)))
	return widest


func _check(label: String, ok: bool, note: String) -> void:
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", label, note])
	if not ok:
		_failures.append(label)
