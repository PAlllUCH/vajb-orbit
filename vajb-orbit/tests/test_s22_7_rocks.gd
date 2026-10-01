@tool
extends McpTestSuite
## Suite s22_7_rocks: the rocks half of the mass physics wave (S22.7, owner ticks
## 2026-09-30 / 2026-10-01) -- one row per acceptance criterion, every figure measured
## and printed:
##
## - AC6 the rock's mass follows its size: `mass = ROCK_MASS_DENSITY x r^2` off the
##   built radius, the M class anchoring the density at 560 t (18 §13's Rock mass row:
##   S 183 / M 560 / L 1 383 / XL 2 571 t at the shipped look widths 48/84/132/180 u);
## - AC7 rocks meet rocks (mask 3) as a nudge, not a fight (no monitor, no sleep
##   change), and the minimum-separation pass (margin 8 u) keeps every 12-rock spawn
##   and every cleave's siblings clear, deterministically on the field's seeded RNG;
## - AC8 the split speed is random and mass-weighted: a resting rock's children leave
##   along their own radial at the per-child jitter (0.7-1.3) x the weight
##   `(m_M/m_child)^0.5` -- 105-195 u/s at weight 1.0, an S splinter ~1.75x the kick,
##   an L child ~0.64x;
## - AC9 no other gameplay number moved: the ejection shape (x1.2, 360 deg, kick 150),
##   both rock damps, the S22.5 ore tables and the flight multipliers, each against
##   its reader.
##
## Nothing awaits a frame: the fields are detached (the `test_engine2_cleaving.gd`
## idiom), every roll is seeded, so each number below is reproducible.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 20261001
const FIELD_ROCKS := 12
const SPAWN_ROCKS := 6
## §13's Rock mass row: the four class radii (the shipped look widths' halves) and the
## masses the density law must land on, within the row's own ±10 % reading.
const CLASS_RADII: Dictionary = {0: 24.0, 1: 42.0, 2: 66.0, 3: 90.0}
const CLASS_MASSES: Dictionary = {0: 183.0, 1: 560.0, 2: 1383.0, 3: 2571.0}
const MASS_TOLERANCE := 0.10
## §13's Ejection row as amended: the jitter band, the exponent and the base kick the
## per-child speed is judged against.
const KICK: float = 150.0
const SPEED_EPSILON := 0.01
## The mean-factor slack on the jitter's own mean of 1.0 (a uniform band's standard
## error over ~24 rolls is ~0.04 of the weight; the slack is ~2.5 sigma).
const MEAN_SLACK := 0.15
const CLEAVE_SWEEP := 24
## The member rock's own centre (the `test_s2_6_burst.gd` idiom: members are built
## unplaced, so every fragment's spawn direction is read against this origin).
const ORIGIN := Vector2(240.0, -80.0)

var _field: Node2D = null


func suite_name() -> String:
	return "s22_7_rocks"


func setup() -> void:
	_field = null


func teardown() -> void:
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


## ---------------------------------------------------------------------------
## AC6 - the rock's mass follows its size
## ---------------------------------------------------------------------------


func test_ac6_rock_mass_is_the_density_law() -> void:
	var density: float = AsteroidScript.ROCK_MASS_DENSITY
	assert_true(
		is_equal_approx(density * 42.0 * 42.0, 560.0),
		"the density anchors the M class at 560 t (560 / 42^2 = %.9f)" % density
	)
	for class_id: int in [0, 1, 2, 3]:
		var rock := AsteroidScript.new() as RigidBody2D
		rock.call(&"setup", &"iron", 1, 4, class_id)
		var radius := float(rock.call(&"world_radius"))
		var want: float = CLASS_MASSES[class_id]
		assert_true(
			is_equal_approx(radius, float(CLASS_RADII[class_id])),
			"class %d builds its §13 radius %.1f u, got %.3f" % [class_id, CLASS_RADII[class_id], radius]
		)
		assert_true(
			is_equal_approx(rock.mass, density * radius * radius),
			"class %d: mass is the density x the built radius squared" % class_id
		)
		assert_true(
			absf(rock.mass - want) <= MASS_TOLERANCE * want,
			"class %d measures %.3f t, within 10%% of §13's %.0f t" % [class_id, rock.mass, want]
		)
		print(
			"[S227B2] AC6 class %d radius=%.1f mass=%.3f t (§13 %.0f t, %.2f%% off)"
			% [class_id, radius, rock.mass, want, 100.0 * (rock.mass - want) / want]
		)
		rock.free()


## ---------------------------------------------------------------------------
## AC7 - rocks meet rocks, placement never interpenetrates
## ---------------------------------------------------------------------------


func test_ac7_rocks_meet_rocks_and_placement_stays_clear() -> void:
	assert_eq(AsteroidScript.COLLISION_MASK, 3, "the mask is §13's 3 (rocks meet rocks)")
	assert_eq(
		AsteroidScript.COLLISION_MASK & AsteroidScript.COLLISION_LAYER,
		AsteroidScript.COLLISION_LAYER,
		"the mask covers the rock's own layer"
	)
	var fresh := AsteroidScript.new() as RigidBody2D
	assert_false(fresh.contact_monitor, "a rock ships no contact monitor (R2: a nudge, not a fight)")
	fresh.call(&"setup", &"iron", 1, 4, AsteroidScript.SIZE_MEDIUM)
	assert_false(fresh.can_sleep, "can_sleep stays false (contacts must answer)")
	assert_eq(fresh.collision_layer, 1, "rock layer 1")
	assert_eq(fresh.collision_mask, 3, "rock mask 3")
	fresh.free()

	var field := _field_with(FIELD_ROCKS, FIELD_SEED)
	var rocks: Array[Node2D] = field.call(&"rocks")
	assert_eq(rocks.size(), FIELD_ROCKS, "the field rolled its 12 rocks")
	_assert_pairwise_clear(rocks, "the 12-rock spawn")
	print("[S227B2] AC7 12-rock spawn: all %d pairs >= r_i + r_j + %.1f" % [
		FIELD_ROCKS * (FIELD_ROCKS - 1) / 2, FieldScript.PLACEMENT_MARGIN
	])

	var twin := _field_with(FIELD_ROCKS, FIELD_SEED)
	var twins: Array[Node2D] = twin.call(&"rocks")
	assert_eq(twins.size(), rocks.size(), "the twin field rolled the same count")
	for index: int in rocks.size():
		assert_true(
			(rocks[index] as Node2D).position.is_equal_approx((twins[index] as Node2D).position),
			"rock %d sits where the seed put it (%s)" % [index, (rocks[index] as Node2D).position]
		)

	for parent_class: int in [AsteroidScript.SIZE_MEDIUM, AsteroidScript.SIZE_LARGE, AsteroidScript.SIZE_XL]:
		var brood := _cleave_brood(parent_class, FIELD_SEED + parent_class)
		assert_true(brood.size() >= 2, "the class-%d parent left a brood to read" % parent_class)
		_assert_pairwise_clear(brood, "the class-%d cleave" % parent_class)
		var gaps := _min_gap(brood)
		print(
			"[S227B2] AC7 class %d cleave: %d siblings, tightest gap %.3f u (margin %.1f)"
			% [parent_class, brood.size(), gaps, FieldScript.PLACEMENT_MARGIN]
		)


## ---------------------------------------------------------------------------
## AC8 - the split speed is random and mass-weighted
## ---------------------------------------------------------------------------


func test_ac8_the_split_speed_is_random_and_mass_weighted() -> void:
	var speeds: Dictionary = {0: [], 1: [], 2: []}
	for index in CLEAVE_SWEEP:
		var field := _field_with(SPAWN_ROCKS, FIELD_SEED + index)
		var parent: Node2D = field.call(
			&"_new_rock", "Rest%d" % index, &"iron", 1, 4, AsteroidScript.SIZE_XL
		)
		parent.position = ORIGIN
		(parent as RigidBody2D).linear_velocity = Vector2.ZERO
		var before := _live_ids()
		_deplete(parent)
		for fragment: Node2D in _new_since(before):
			var body := fragment as RigidBody2D
			var kind := int(fragment.call(&"size_class"))
			var radial := ((fragment as Node2D).global_position - ORIGIN).normalized()
			assert_true(
				absf(body.linear_velocity.cross(radial)) <= 0.0001,
				"a resting rock's child leaves along its own radial"
			)
			var w := _weight(fragment)
			var speed := body.linear_velocity.length()
			assert_true(
				speed >= AsteroidScript.FRAGMENT_SPEED_JITTER.x * w * KICK - SPEED_EPSILON
					and speed <= AsteroidScript.FRAGMENT_SPEED_JITTER.y * w * KICK + SPEED_EPSILON,
				"the child's speed is the jitter band x its weight %.4f: %.3f u/s" % [w, speed]
			)
			var bucket: Array = speeds[kind]
			bucket.append(speed / KICK)
		field.free()
	var expectations: Dictionary = {0: "~1.75x the kick", 1: "the §13 span's own weight", 2: "~0.64x the kick"}
	for kind: int in speeds.keys():
		var factors: Array = speeds[kind]
		assert_gt(factors.size(), 0, "the sweep measured class-%d children" % kind)
		var mean := 0.0
		for factor: float in factors:
			mean += factor
		mean /= factors.size()
		var w_expected := _class_weight(kind)
		assert_true(
			absf(mean - w_expected) <= MEAN_SLACK,
			"class %d's mean factor %.4f is its weight %.4f x the jitter's mean 1.0" % [kind, mean, w_expected]
		)
		var observed_low: float = factors.min()
		var observed_high: float = factors.max()
		print(
			"[S227B2] AC8 class %d: n=%d factor %.3f..%.3f (mean %.4f, weight %.4f, %s), speeds %.1f..%.1f u/s"
			% [kind, factors.size(), observed_low, observed_high, mean, w_expected,
			expectations[kind], observed_low * KICK, observed_high * KICK]
		)
	## The M children carry the weight the row names (m_M / m_M = 1.0): their span IS
	## §13's 105-195 u/s.
	var m_factors: Array = speeds[1]
	assert_true(
		m_factors.min() * KICK >= 105.0 - SPEED_EPSILON and m_factors.max() * KICK <= 195.0 + SPEED_EPSILON,
		"the weight-1.0 children span §13's 105-195 u/s (%.1f..%.1f measured)"
			% [m_factors.min() * KICK, m_factors.max() * KICK]
	)
	## The splinter path rides the same carrier: a resting rock's S splinter at the
	## S class's own weight (~1.75x the kick).
	var splinter_factors: Array[float] = []
	for index in CLEAVE_SWEEP:
		var field := _field_with(SPAWN_ROCKS, FIELD_SEED + 100 + index)
		var host: Node2D = field.call(
			&"_new_rock", "Host%d" % index, &"iron", 1, 4, AsteroidScript.SIZE_XL
		)
		host.position = ORIGIN
		(host as RigidBody2D).linear_velocity = Vector2.ZERO
		var before := _live_ids()
		field.call(&"_spawn_splinter", host)
		for splinter: Node2D in _new_since(before):
			var speed := (splinter as RigidBody2D).linear_velocity.length()
			var w := _weight(splinter)
			assert_eq(
				int(splinter.call(&"size_class")), AsteroidScript.SIZE_SMALL,
				"the shed splinter is an S"
			)
			assert_true(
				speed >= AsteroidScript.FRAGMENT_SPEED_JITTER.x * w * KICK - SPEED_EPSILON
					and speed <= AsteroidScript.FRAGMENT_SPEED_JITTER.y * w * KICK + SPEED_EPSILON,
				"the splinter's speed is the jitter band x its weight %.4f: %.3f u/s" % [w, speed]
			)
			splinter_factors.append(speed / KICK)
		field.free()
	assert_gt(splinter_factors.size(), 0, "the sweep shed at least one splinter")
	var s_mean := 0.0
	for factor: float in splinter_factors:
		s_mean += factor
	s_mean /= splinter_factors.size()
	print(
		"[S227B2] AC8 S splinter: n=%d factor %.3f..%.3f (mean %.4f, weight %.4f), speeds %.1f..%.1f u/s"
		% [splinter_factors.size(), splinter_factors.min(), splinter_factors.max(), s_mean,
		_class_weight(AsteroidScript.SIZE_SMALL),
		splinter_factors.min() * KICK, splinter_factors.max() * KICK]
	)


## ---------------------------------------------------------------------------
## AC9 - no other gameplay number moved
## ---------------------------------------------------------------------------


func test_ac9_no_other_gameplay_number_moved() -> void:
	## The ejection shape and its readers (`Asteroid.eject_velocity`, the field's roll).
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2), "FRAGMENT_EJECT_MULT 1.2 (eject_velocity)")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0), "FRAGMENT_EJECT_CONE_DEG 360 (the field's roll)")
	assert_true(is_equal_approx(FieldScript.FRAGMENT_OUTWARD_KICK, 150.0), "FRAGMENT_OUTWARD_KICK 150 (_deploy_debris)")
	assert_true(is_equal_approx(FieldScript.FRAGMENT_ANGLE_JITTER, 0.25), "FRAGMENT_ANGLE_JITTER 0.25 (_cleave)")
	## Both rock damps (18 §13's Rock drift damping row) and the retired flat pair,
	## intact as the SUPERSEDED record with no live reader.
	assert_true(is_equal_approx(AsteroidScript.LINEAR_DAMP, 0.35), "LINEAR_DAMP 0.35 (_configure_body)")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_LINEAR_DAMP, 0.25), "FRAGMENT_LINEAR_DAMP 0.25 (apply_fragment_damp)")
	assert_true(is_equal_approx(AsteroidScript.ROCK_MASS_MULT, 4.0), "the SUPERSEDED ROCK_MASS_MULT 4.0, unchanged as the record")
	assert_true(String(AsteroidScript.ROCK_MASS_REFERENCE) == "ship_miner", "the SUPERSEDED ROCK_MASS_REFERENCE, unchanged as the record")
	## The S22.5 ore rules (the gun door, the splits, the rolls) -- `OreTuning` untouched.
	assert_true(is_equal_approx(OreTuningScript.gun_chip_rate, 0.10), "gun_chip_rate 0.10 (the gun door)")
	assert_true(is_equal_approx(OreTuningScript.work_per_unit, 1.0), "work_per_unit 1.0 (_accumulate)")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, 0.25), "fragment_core_share 0.25 (setup)")
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10), "gun_burst_share 0.10 (_cleave)")
	assert_true(is_equal_approx(OreTuningScript.mine_cycle, 1.2), "mine_cycle 1.2 (the laser)")
	assert_true(is_equal_approx(OreTuningScript.toughness_min, 0.80), "toughness_min 0.80 (the roll)")
	assert_true(is_equal_approx(OreTuningScript.toughness_max, 1.60), "toughness_max 1.60 (the roll)")
	assert_true(
		str(OreTuningScript.split_mix)
			== str({3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)}, 2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)}, 1: {0: Vector2i(1, 3)}, 0: {}}),
		"the S14 split_mix table is pinned"
	)
	assert_true(
		str(OreTuningScript.spawn_size_weights) == str({0: 40, 1: 32, 2: 20, 3: 8}),
		"the S14 spawn_size_weights are pinned"
	)
	## The flight multipliers (B1's half of the wave) -- untouched by the rocks half.
	assert_true(is_equal_approx(ShipFitScript.ACCEL_TIME_MULT, 2.0), "ACCEL_TIME_MULT 2.0 (the resolve)")
	assert_true(is_equal_approx(ShipFitScript.COAST_TIME_MULT, 5.0), "COAST_TIME_MULT 5.0 (the resolve)")
	assert_true(is_equal_approx(ShipFitScript.LATERAL_DAMP_MULT, 1.0), "LATERAL_DAMP_MULT 1.0 (the drag)")
	assert_true(is_equal_approx(ShipFitScript.ANGULAR_DAMP_MULT, 0.5), "ANGULAR_DAMP_MULT 0.5 (_angular_damp)")
	assert_true(is_equal_approx(PlayerShipScript.BRAKE_MULT, 1.8), "BRAKE_MULT 1.8 (the S-thrust rate)")
	print("[S227B2] AC9 every untouched number read against its reader, all pinned")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _field_with(count: int, seed_value: int) -> Node2D:
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": seed_value,
	})
	return _field


func _live_ids() -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in _field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _new_since(before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _field.call(&"rocks"):
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## Deplete through the rock's own arithmetic (the mining door), the cleaving suite's
## idiom: the reserve is what the field hands the children.
func _deplete(rock: Node2D) -> void:
	var amount := float(int(rock.get(&"yield_units")))
	if amount <= 0.0:
		amount = 1.0
	rock.call(&"apply_work", maxf(amount, AsteroidScript.WORK_PER_UNIT))


## One seeded cleave of a class-`size_class` member at `ORIGIN`, at rest: the brood it
## leaves behind (the parent is gone).
func _cleave_brood(size_class: int, seed_value: int) -> Array[Node2D]:
	var field := _field_with(SPAWN_ROCKS, seed_value)
	var parent: Node2D = field.call(
		&"_new_rock", "Cleave%d" % size_class, &"iron", 1, 4, size_class
	)
	parent.position = ORIGIN
	(parent as RigidBody2D).linear_velocity = Vector2.ZERO
	var before := _live_ids()
	_deplete(parent)
	return _new_since(before)


## The tightest centre-to-centre clearance over every pair, against the pass's own
## margin -- the AC7 invariant, asserted pair by pair.
func _assert_pairwise_clear(rocks: Array[Node2D], label: String) -> void:
	var margin: float = FieldScript.PLACEMENT_MARGIN
	var tightest := INF
	for i: int in rocks.size():
		for j: int in range(i + 1, rocks.size()):
			var a := rocks[i] as Node2D
			var b := rocks[j] as Node2D
			var clearance := a.position.distance_to(b.position) \
				- float(a.call(&"world_radius")) - float(b.call(&"world_radius"))
			tightest = minf(tightest, clearance)
			assert_true(
				clearance >= margin - 0.0001,
				"%s: rocks %d and %d keep %.3f u of clearance (margin %.1f)" % [label, i, j, clearance, margin]
			)


func _min_gap(rocks: Array[Node2D]) -> float:
	var tightest := INF
	for i: int in rocks.size():
		for j: int in range(i + 1, rocks.size()):
			var a := rocks[i] as Node2D
			var b := rocks[j] as Node2D
			tightest = minf(
				tightest,
				a.position.distance_to(b.position)
					- float(a.call(&"world_radius")) - float(b.call(&"world_radius"))
			)
	return tightest


## The amended ejection row's mass weight, read off a body's own mass.
func _weight(fragment: Node2D) -> float:
	return pow(
		AsteroidScript.ROCK_MASS_M / (fragment as RigidBody2D).mass,
		AsteroidScript.FRAGMENT_MASS_SPEED_EXP
	)


## The same weight for a size class, measured off a fixture rock of that class -- the
## printed bands are the law's own numbers, not re-literals.
func _class_weight(size_class: int) -> float:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, 4, size_class)
	var w := _weight(rock)
	rock.free()
	return w
