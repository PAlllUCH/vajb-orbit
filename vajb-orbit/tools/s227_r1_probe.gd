extends SceneTree
## S22.7-R1's own reviewer probe (NOT a gate suite — never counted by the runner).
## Two modes, picked from the first user arg (`-- ships` / `-- rocks`); every figure
## prints, every check reports into the `fails` counter, exit carries the verdict.
## Run headless and bounded:
##   godot --headless --path "$VAJB_PROJ" --script res://tools/s227_r1_probe.gd -- ships
##   godot --headless --path "$VAJB_PROJ" --script res://tools/s227_r1_probe.gd -- rocks

const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const BOOST_FUEL_REF := 3.0
const DASH_FUEL_REF := 25.0
const DASH_REF_MASS := 110.0
const MARGIN := 8.0
const KICK := 150.0
const SPAWN_ROCKS := 12
const SWEEP := 24
const ORIGIN := Vector2(-1600.0, 940.0)
const CLASS_MASS_WANT := {0: 183.0, 1: 560.0, 2: 1383.0, 3: 2571.0}
const TIER_WEIGHTS := {1: 40, 2: 32, 3: 20, 4: 8}

var fails := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := "ships" if args.is_empty() else String(args[0])
	if mode == "ships":
		_ships()
	else:
		_rocks()
	print("[R1P] mode=%s fails=%d" % [mode, fails])
	quit(1 if fails > 0 else 0)


## ---------------------------------------------------------------- ships ----

func _ships() -> void:
	var keys: Array = ShipFitScript.HANDLING.keys()
	keys.sort()
	var ref: float = ShipFitScript.engine_thrust_reference()
	print("[R1P] thrust_ref=%.4f" % ref)
	for id: StringName in keys:
		var row_mass := float(ShipFitScript.HANDLING[id][&"hull_mass"])
		var s: Variant = ShipFitScript.resolve(id, {})
		if s == null:
			print("[R1P] FAIL resolve %s" % id)
			fails += 1
			continue
		var ok := is_equal_approx(s.base_mass, row_mass) and is_equal_approx(s.hull_mass, s.base_mass)
		if not ok:
			fails += 1
		print("[R1P] AC1 %s row=%.3f base=%.3f fitted=%.3f fuel_max=%.1f ok=%s" % [
			id, row_mass, s.base_mass, s.hull_mass, s.fuel_max, ok,
		])
		var burn: float = BOOST_FUEL_REF * float(s.engine_thrust) / ref
		var dash: float = DASH_FUEL_REF * float(s.base_mass) / DASH_REF_MASS
		print("[R1P] AC4 %s burn=%.4f/s dash=%.4f thrust=%.3f" % [id, burn, dash, s.engine_thrust])
	# the plate fits on the Vanguard: mass factor and the three times
	var base: Variant = ShipFitScript.resolve(&"ship_vanguard", {})
	var light: Variant = ShipFitScript.resolve(&"ship_vanguard", {&"armour": [&"h_plate_light"]})
	var comp: Variant = ShipFitScript.resolve(&"ship_vanguard", {&"armour": [&"h_composite"]})
	for pair: Array in [["light", light, 1.05], ["composite", comp, 1.21]]:
		var s: Variant = pair[1]
		var mass_factor: float = s.hull_mass / base.hull_mass
		var ok := is_equal_approx(mass_factor, float(pair[2]))
		var times_ok := (
			is_equal_approx(s.accel_time, base.accel_time)
			and is_equal_approx(s.coast_time, base.coast_time)
			and is_equal_approx(s.turn_spinup, base.turn_spinup)
		)
		if not (ok and times_ok):
			fails += 1
		print("[R1P] AC3 %s mass=x%.4f (want x%.2f) times_ok=%s t=%.4f/%.4f/%.4f max_speed=%.2f" % [
			pair[0], mass_factor, float(pair[2]), times_ok,
			s.accel_time, s.coast_time, s.turn_spinup, s.max_speed,
		])
	# the multipliers and the untouched flight constants
	for pair: Array in [
		["ACCEL_TIME_MULT", ShipFitScript.ACCEL_TIME_MULT, 2.0],
		["COAST_TIME_MULT", ShipFitScript.COAST_TIME_MULT, 5.0],
		["ANGULAR_DAMP_MULT", ShipFitScript.ANGULAR_DAMP_MULT, 0.5],
		["LATERAL_DAMP_MULT", ShipFitScript.LATERAL_DAMP_MULT, 1.0],
	]:
		if not is_equal_approx(float(pair[1]), float(pair[2])):
			fails += 1
		print("[R1P] AC9 %s=%s" % [pair[0], pair[1]])
	print("[R1P] AC9 engine_thrust_reference()=%.6f" % ShipFitScript.engine_thrust_reference())


## ---------------------------------------------------------------- rocks ----

func _rocks() -> void:
	var density: float = AsteroidScript.ROCK_MASS_DENSITY
	print("[R1P] AC6 density=%.9f (M anchor %.4f)" % [density, density * 42.0 * 42.0])
	for class_id: int in [0, 1, 2, 3]:
		var rock := AsteroidScript.new() as RigidBody2D
		rock.call(&"setup", &"iron", 1, 4, class_id)
		var radius := float(rock.call(&"world_radius"))
		var want := float(CLASS_MASS_WANT[class_id])
		var off := 100.0 * (rock.mass - want) / want
		if absf(rock.mass - want) > 0.10 * want or not is_equal_approx(rock.mass, density * radius * radius):
			fails += 1
		print("[R1P] AC6 class %d r=%.1f mass=%.3f t (want %.0f, %+.2f%%) mask=%d monitor=%s sleep=%s" % [
			class_id, radius, rock.mass, want, off, rock.collision_mask,
			rock.contact_monitor, rock.can_sleep,
		])
		rock.free()
	if AsteroidScript.COLLISION_MASK != 3 or AsteroidScript.COLLISION_LAYER != 1:
		fails += 1
	print("[R1P] AC7 layer=%d mask=%d margin=%.1f retries(unpinned)=%s" % [
		AsteroidScript.COLLISION_LAYER, AsteroidScript.COLLISION_MASK,
		FieldScript.PLACEMENT_MARGIN, str(FieldScript.PLACEMENT_RETRIES),
	])
	# a 12-rock spawn on my own seed: every pair clear, layout reproducible
	var field_a := _field_with(7717)
	var rocks: Array[Node2D] = field_a.call(&"rocks")
	_check_pairs(rocks, "12-rock spawn")
	var field_b := _field_with(7717)
	var again: Array[Node2D] = field_b.call(&"rocks")
	var same := again.size() == rocks.size()
	if same:
		for i: int in rocks.size():
			same = same and (rocks[i] as Node2D).position.is_equal_approx((again[i] as Node2D).position)
	if not same:
		fails += 1
	print("[R1P] AC7 seeded rebuild identical: %s" % same)
	field_a.free()
	field_b.free()
	for class_id: int in [1, 2, 3]:
		for seed_step: int in 8:
			var cfield := _field_with(4200 + 16 * class_id + seed_step)
			var brood := _cleave_brood(cfield, class_id)
			if brood.size() >= 2:
				_check_pairs(brood, "class-%d cleave seed +%d" % [class_id, seed_step])
			cfield.free()
	# split speeds from rest: jitter band x mass weight, per class bucket
	var buckets: Dictionary = {0: [], 1: [], 2: []}
	var splinter_factors: Array[float] = []
	for index: int in SWEEP:
		for class_id: int in [1, 2, 3]:
			var bfield := _field_with(9000 + 31 * index + class_id)
			var brood := _cleave_brood(bfield, class_id)
			for child: Node2D in brood:
				_record_child(child, buckets)
			bfield.free()
		var sfield := _field_with(61000 + index)
		var shed := _splinter(sfield)
		for child: Node2D in shed:
			splinter_factors.append(_factor(child))
		sfield.free()
	_check_band(buckets)
	var s_mean := 0.0
	for f: float in splinter_factors:
		s_mean += f
	s_mean /= maxf(float(splinter_factors.size()), 1.0)
	print("[R1P] AC8 S splinter n=%d factor %.3f..%.3f mean %.4f (weight %.4f) speeds %.1f..%.1f u/s" % [
		splinter_factors.size(), splinter_factors.min() if not splinter_factors.is_empty() else 0.0,
		splinter_factors.max() if not splinter_factors.is_empty() else 0.0, s_mean,
		_weight_of_mass(AsteroidScript.ROCK_MASS_DENSITY * 24.0 * 24.0),
		(splinter_factors.min() if not splinter_factors.is_empty() else 0.0) * KICK,
		(splinter_factors.max() if not splinter_factors.is_empty() else 0.0) * KICK,
	])
	# the untouched constants, each against its reader
	for pair: Array in [
		["FRAGMENT_EJECT_MULT", AsteroidScript.FRAGMENT_EJECT_MULT, 1.2],
		["FRAGMENT_EJECT_CONE_DEG", AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0],
		["FRAGMENT_OUTWARD_KICK", FieldScript.FRAGMENT_OUTWARD_KICK, 150.0],
		["FRAGMENT_ANGLE_JITTER", FieldScript.FRAGMENT_ANGLE_JITTER, 0.25],
		["LINEAR_DAMP", AsteroidScript.LINEAR_DAMP, 0.35],
		["FRAGMENT_LINEAR_DAMP", AsteroidScript.FRAGMENT_LINEAR_DAMP, 0.25],
		["gun_chip_rate", OreTuningScript.gun_chip_rate, 0.10],
		["fragment_core_share", OreTuningScript.fragment_core_share, 0.25],
		["gun_burst_share", OreTuningScript.gun_burst_share, 0.10],
		["mine_cycle", OreTuningScript.mine_cycle, 1.2],
		["toughness_min", OreTuningScript.toughness_min, 0.80],
		["toughness_max", OreTuningScript.toughness_max, 1.60],
	]:
		if not is_equal_approx(float(pair[1]), float(pair[2])):
			fails += 1
		print("[R1P] AC9 %s=%s" % [pair[0], pair[1]])
	print("[R1P] AC9 split_mix=%s" % str(OreTuningScript.split_mix))
	print("[R1P] AC9 spawn_size_weights=%s" % str(OreTuningScript.spawn_size_weights))


func _record_child(child: Node2D, buckets: Dictionary) -> void:
	var kind := int(child.call(&"size_class"))
	var radial := (child.global_position - ORIGIN).normalized()
	var body := child as RigidBody2D
	var speed := body.linear_velocity.length()
	var w := _weight_of_mass(body.mass)
	var cross: float = absf(body.linear_velocity.cross(radial))
	var inside := speed >= AsteroidScript.FRAGMENT_SPEED_JITTER.x * w * KICK - 0.01 \
		and speed <= AsteroidScript.FRAGMENT_SPEED_JITTER.y * w * KICK + 0.01
	if not inside or (speed > 0.0 and cross / speed > 0.00001):
		fails += 1
		print("[R1P] FAIL child class=%d speed=%.3f w=%.4f cross-share=%.9f" % [kind, speed, w, cross / maxf(speed, 0.001)])
	if buckets.has(kind):
		var bucket: Array = buckets[kind]
		bucket.append(speed / KICK)


func _check_band(buckets: Dictionary) -> void:
	var want_w := {0: _weight_of_mass(AsteroidScript.ROCK_MASS_DENSITY * 24.0 * 24.0), 1: 1.0, 2: _weight_of_mass(AsteroidScript.ROCK_MASS_DENSITY * 66.0 * 66.0)}
	for kind: int in buckets.keys():
		var factors: Array = buckets[kind]
		if factors.is_empty():
			fails += 1
			print("[R1P] FAIL class %d measured no children" % kind)
			continue
		var mean := 0.0
		for f: float in factors:
			mean += f
		mean /= factors.size()
		var w := float(want_w[kind])
		print("[R1P] AC8 class %d n=%d factor %.3f..%.3f mean %.4f (weight %.4f) speeds %.1f..%.1f u/s" % [
			kind, factors.size(), factors.min(), factors.max(), mean, w,
			float(factors.min()) * KICK, float(factors.max()) * KICK,
		])
		if kind == 1 and not (float(factors.min()) * KICK >= 105.0 - 0.01 and float(factors.max()) * KICK <= 195.0 + 0.01):
			fails += 1


func _weight_of_mass(mass: float) -> float:
	return pow(AsteroidScript.ROCK_MASS_M / mass, AsteroidScript.FRAGMENT_MASS_SPEED_EXP)


func _factor(child: Node2D) -> float:
	return (child as RigidBody2D).linear_velocity.length() / KICK


func _field_with(seed_value: int) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {&"tier_weights": TIER_WEIGHTS, &"rocks": SPAWN_ROCKS, &"seed": seed_value})
	return field


func _live_ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _new_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks"):
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


func _cleave_brood(field: Node2D, size_class: int) -> Array[Node2D]:
	var parent: Node2D = field.call(&"_new_rock", "R1P%d" % size_class, &"iron", 1, 4, size_class)
	parent.position = ORIGIN
	(parent as RigidBody2D).linear_velocity = Vector2.ZERO
	var before := _live_ids(field)
	var amount := float(int(parent.get(&"yield_units")))
	if amount <= 0.0:
		amount = 1.0
	parent.call(&"apply_work", maxf(amount, AsteroidScript.WORK_PER_UNIT))
	return _new_since(field, before)


func _splinter(field: Node2D) -> Array[Node2D]:
	var host: Node2D = field.call(&"_new_rock", "R1PS", &"iron", 1, 4, AsteroidScript.SIZE_XL)
	host.position = ORIGIN
	(host as RigidBody2D).linear_velocity = Vector2.ZERO
	var before := _live_ids(field)
	field.call(&"_spawn_splinter", host)
	return _new_since(field, before)


func _check_pairs(rocks: Array[Node2D], label: String) -> void:
	var tightest := INF
	var pairs := 0
	for i: int in rocks.size():
		for j: int in range(i + 1, rocks.size()):
			pairs += 1
			var a := rocks[i] as Node2D
			var b := rocks[j] as Node2D
			var clearance := a.position.distance_to(b.position) \
				- float(a.call(&"world_radius")) - float(b.call(&"world_radius"))
			tightest = minf(tightest, clearance)
			if clearance < MARGIN - 0.0001:
				fails += 1
				print("[R1P] FAIL %s rocks %d/%d clearance %.3f" % [label, i, j, clearance])
	print("[R1P] AC7 %s: %d pairs, tightest clearance %.3f u (margin %.1f)" % [label, pairs, tightest, MARGIN])
