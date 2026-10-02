@tool
extends McpTestSuite
## Suite s2_6_burst: CONTRACTS §14's "Fragment burst" -- the owner's "when breaking
## asteroids they should move when exploding", measured as AC2.
##
## The defect it cures is measured in the field, not in the rock: `AsteroidField._cleave`
## gives every fragment `eject_velocity()` (the §5 shape: the parent's velocity × 1.2,
## rolled over `FRAGMENT_EJECT_CONE_DEG`), so a rock at rest ejects at **0.0** and a slow
## one crawls. Measured before this change: a resting Large rock's four fragments all read
## radial component 0.000 u/s. §14 adds `FRAGMENT_OUTWARD_KICK` on top of that shape, along
## the **placement radial** the field already computes (rock centre → spawn point), so the
## burst is visible exactly where the fragment appears and a drifting rock keeps its
## inherited component untouched.
##
## What each test pins:
##   1. the pin's own shape -- one field-side constant, and the rock's §5 half untouched
##      (`eject_velocity()` is still exactly `linear_velocity × 1.2`);
##   2. **AC2**: 200 seeded breaks of a near-stationary rock, every fragment's radial
##      component ≥ 0.5 × the kick, the deployed speed inside the S22.7-amended band
##      (the scaled kick ± the shape: the per-child jitter × the mass weight), the
##      per-cleave spread past 90° and all four quadrants covered;
##   3. the **stopped-rock control**: S22.7 scales the whole vector per child, so the
##      pre-S22.7 residual no longer isolates the inherit; what stays exact is that a
##      **stopped** rock's fragment deploys exactly along its placement radial at the
##      weighted-jitter speed -- §13's 35-65 u/s span at weight 1.0 (the 2026-10-01
##      fix round's ÷3) -- while the **core** (02 §5.6, fix round 2) stays at the
##      centre, speedless;
##   4. the two halves add: the deployed magnitude of a drifting rock's fragment sits
##      inside the scaled `|shape − kick| .. shape + kick`, which only holds if the
##      kick is a separate vector scaled together with the shape.
##
## Nothing awaits a frame: a detached field needs no physics world for any of this (the
## fragments are real `RigidBody2D`s and their velocity is set, not simulated), and the
## breaks' FX and cue are the cleaving suite's rows. A subclass cannot zero the constant --
## GDScript refuses to redeclare a parent's member (measured: `Parse Error: The member
## "FRAGMENT_OUTWARD_KICK" already exists in parent class AsteroidField`).
##
## The 2026-10-01 fix round 2 (02 §5.6) adds the core layer: the largest kind's first
## child stays at the parent's centre on the shape's half alone, so every row below
## exempts the `Core*` body from the flyer measurements and pins its own law.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

## §14's kick, as the 2026-10-01 fix round cut it (02 §5.5 tick F1: 150 → 50, the
## owner's ÷3 on both band ends; the jitter band is untouched).
const KICK := 50.0
## AC2's floor: half the kick. A fragment that fails it is barely moving outward.
const HALF_KICK := 0.5 * KICK
## The band the two additive terms must land inside is measured on `float32`-backed
## velocities, so the bounds carry a slack far smaller than either term (measured overshoot:
## 0.0000-0.0001 u/s against a 0.48 u/s shape).
const SPEED_EPSILON := 0.01
const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 7331
const FIELD_ROCKS := 6
## The owner's case, made measurable: a rock that is nearly stopped. Its shape is
## 0.4 × 1.2 = 0.48 u/s, so the burst it deploys is the kick to within half a unit -- and
## before §14 it ejected at 0.48 u/s, which is the "they should move" complaint.
const NEAR_STATIONARY := 0.4
## The drifting parent's shape is 25 × 1.2 = 30 u/s, under the amended 50 u/s kick, so
## the additive roll still straddles the kick (the two-halves row below).
const DRIFT_SPEED := 25.0
const DRIFT_HEADING := 0.7
## 200 distinct seeded breaks: one field seed each, so the sweep covers the whole 3-7 count
## roll and the whole placement ring rather than one sequence repeated 200 times.
const SWEEP_BREAKS := 200
const DIRECTION_CLEAVES := 8
## The member rock's own centre. Members are built by `_new_rock` and are not placed, so
## every fragment's spawn direction is read against this explicit origin.
const ORIGIN := Vector2(240.0, -80.0)

var _field: Node2D = null


func suite_name() -> String:
	return "s2_6_burst"


func setup() -> void:
	_field = null


func teardown() -> void:
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


## ---------------------------------------------------------------------------
## The pin
## ---------------------------------------------------------------------------


## §14's kick is one constant and it lives in the field; the rock's §5 half is untouched,
## which is what "additive on top of §5's shape" means in code.
func test_the_kick_is_one_field_side_constant_on_top_of_the_shape() -> void:
	assert_true(is_equal_approx(FieldScript.FRAGMENT_OUTWARD_KICK, KICK),
		"the field's kick is the amended 50.0 u/s (02 §5.5's ÷3), got %s" % FieldScript.FRAGMENT_OUTWARD_KICK)
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2),
		"§5's ejection multiplier is untouched, got %s" % AsteroidScript.FRAGMENT_EJECT_MULT)
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0),
		"§5's roll is still the full circle, got %s" % AsteroidScript.FRAGMENT_EJECT_CONE_DEG)
	var field := _field_with(FIELD_SEED)
	var rock: Node2D = field.call(
		&"_new_rock", "Shape", &"iron", 1, 4, AsteroidScript.SIZE_LARGE
	)
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	(rock as RigidBody2D).linear_velocity = velocity
	var shape: Vector2 = rock.call(&"eject_velocity")
	assert_true(shape.is_equal_approx(velocity * AsteroidScript.FRAGMENT_EJECT_MULT),
		"the rock's eject_velocity is the shape alone: %s for a parent at %s" % [shape, velocity])


## ---------------------------------------------------------------------------
## AC2 -- the burst
## ---------------------------------------------------------------------------


## 200 seeded breaks of a near-stationary rock: every fragment leaves along its own radial
## with at least half the kick of outward speed, its deployed speed is the S22.7-amended
## whole vector (the kick +- the tiny shape, scaled by the per-child jitter x the mass
## weight), and the burst still leaves in every direction.
func test_every_fragment_moves_outward_from_the_rock_centre() -> void:
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
			if String(fragment.name).begins_with("Core"):
				continue
			var outward := _radial(fragment)
			var deployed := (fragment as RigidBody2D).linear_velocity
			lowest = minf(lowest, deployed.dot(outward))
			slowest = minf(slowest, deployed.length())
			fastest = maxf(fastest, deployed.length())
			angles.append(rad_to_deg(outward.angle()))
			var quadrant := int(floor(fposmod(outward.angle(), TAU) / (TAU / 4.0)))
			quadrants[quadrant] = int(quadrants[quadrant]) + 1
			total += 1
		var widest := _widest(angles)
		if widest < narrowest:
			narrowest = widest
			narrowest_cleave = index
		field.free()
	assert_gt(total, 2 * SWEEP_BREAKS,
		"every break spawned fragments: %d over %d breaks" % [total, SWEEP_BREAKS])
	assert_gt(lowest, HALF_KICK,
		"AC2: the lowest radial component is %.3f u/s over %d fragments, against the %.1f floor" % [lowest, total, HALF_KICK])
	## The amended ejection row (S22.7): the whole vector -- the shape plus the kick --
	## scales by the per-child jitter x the mass weight, read per fragment off its own
	## body (a Large's children: M at weight 1.0, S at weight 1.75 -- splinters fly).
	for index in SWEEP_BREAKS:
		var field := _field_with(FIELD_SEED + index)
		for fragment: Node2D in _break_member("SweepCheck%d" % index, velocity):
			if String(fragment.name).begins_with("Core"):
				continue
			var w := _weight(fragment)
			var speed := (fragment as RigidBody2D).linear_velocity.length()
			assert_true(
				speed >= (KICK - shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.x * w - SPEED_EPSILON
					and speed <= (KICK + shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.y * w + SPEED_EPSILON,
				"the burst is the scaled kick for weight %.3f: got %.3f u/s" % [w, speed]
			)
		field.free()
	print(
		"[S26B] AC2 sweep slowest=%.3f fastest=%.3f (scaled band M %.3f..%.3f, S %.3f..%.3f)" % [
			slowest, fastest,
			(KICK - shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.x,
			(KICK + shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.y,
			(KICK - shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.x * _class_weight(AsteroidScript.SIZE_SMALL),
			(KICK + shape) * AsteroidScript.FRAGMENT_SPEED_JITTER.y * _class_weight(AsteroidScript.SIZE_SMALL),
		]
	)
	assert_gt(narrowest, 90.0,
		"the burst still leaves in every direction: the narrowest cleave spans %.3f deg (cleave %d)" % [narrowest, narrowest_cleave])
	for quadrant: int in [0, 1, 2, 3]:
		assert_gt(int(quadrants[quadrant]), 0,
			"a fragment left in quadrant %d, which holds %d of %d (%s)" % [quadrant, int(quadrants[quadrant]), total, str(quadrants)])


## ---------------------------------------------------------------------------
## The zero-kick control (F3: the inherit stays measurable)
## ---------------------------------------------------------------------------


## The control, run as arithmetic because the pin is a `const` (see the header). S22.7
## scales the WHOLE ejection vector per child (the jitter x the mass weight), so the
## pre-S22.7 residual -- taking the unscaled kick back out -- no longer isolates the
## inherit. What the law still pins exactly is the owner's own stopped case: the whole
## vector is the scaled kick alone, so every fragment deploys exactly along its
## placement radial, at the weighted-jitter speed (the §13 span: 35-65 u/s at weight
## 1.0, 61.25-113.75 at the S splinter's 1.75) -- measured, not prose. The drifting
## parent's directions still land on both sides of the heading and past 90 deg, which
## a +-15 deg cone cannot produce.
func test_the_stopped_rock_deploys_the_weighted_kick_radially() -> void:
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	var deviation_low := INF
	var deviation_high := -INF
	var widest := 0.0
	var readings := 0
	var beyond := 0
	for index in DIRECTION_CLEAVES:
		var field := _field_with(FIELD_SEED + index)
		var here: Array[float] = []
		for fragment: Node2D in _break_member("Residual%d" % index, velocity):
			var deviation := rad_to_deg(velocity.angle_to((fragment as RigidBody2D).linear_velocity))
			here.append(deviation)
			deviation_low = minf(deviation_low, deviation)
			deviation_high = maxf(deviation_high, deviation)
			if absf(deviation) > 90.0:
				beyond += 1
			readings += 1
		widest = maxf(widest, _widest(here))
		field.free()
	assert_gt(readings, 0, "the control measured at least one fragment")
	assert_true(deviation_low < 0.0 and deviation_high > 0.0,
		"the deployed burst still lands on both sides of the parent's heading: %.3f .. %.3f deg" % [deviation_low, deviation_high])
	assert_gt(beyond, 0,
		"and past 90 deg off it (%d of %d), which a +-15 deg cone cannot produce" % [beyond, readings])
	assert_gt(widest, 90.0,
		"two deployed headings of one cleave are %.3f deg apart" % widest)
	_field_with(FIELD_SEED)
	var fragments := _break_member("Stopped", Vector2.ZERO)
	assert_true(fragments.size() >= 2,
		"the stopped break left a roll of fragments to read, got %d" % fragments.size())
	var slowest := INF
	var fastest := 0.0
	for fragment: Node2D in fragments:
		if String(fragment.name).begins_with("Core"):
			## The core layer (02 §5.6): it stays at the parent's centre, and a
			## stopped parent leaves it speedless -- the shape's half alone.
			assert_true(
				(fragment as Node2D).global_position.is_equal_approx(ORIGIN)
					and (fragment as RigidBody2D).linear_velocity.length() < SPEED_EPSILON,
				"the stopped rock's core stays at the centre, speedless"
			)
			continue
		var deployed := (fragment as RigidBody2D).linear_velocity
		var radial := _radial(fragment)
		var w := _weight(fragment)
		## Exactly radial: the scaled whole vector has no second term to rotate it.
		assert_true(is_equal_approx(deployed.dot(radial), deployed.length()),
			"all of it radial, measured %.6f u/s" % deployed.dot(radial))
		var span := AsteroidScript.FRAGMENT_SPEED_JITTER
		assert_true(
			deployed.length() >= span.x * w * KICK - SPEED_EPSILON
				and deployed.length() <= span.y * w * KICK + SPEED_EPSILON,
			"the deployed speed is the weighted-jitter kick (weight %.3f): %.3f u/s" % [w, deployed.length()]
		)
		slowest = minf(slowest, deployed.length())
		fastest = maxf(fastest, deployed.length())
	var span := AsteroidScript.FRAGMENT_SPEED_JITTER
	print(
		"[S26B] stopped rock's burst %.3f..%.3f u/s over %d fragments (the law: %.1f..%.1f at weight 1.0, %.1f..%.1f at the S weight 1.75)"
		% [slowest, fastest, fragments.size(),
		span.x * KICK, span.y * KICK,
		span.x * KICK * _class_weight(AsteroidScript.SIZE_SMALL),
		span.y * KICK * _class_weight(AsteroidScript.SIZE_SMALL)]
	)


## ---------------------------------------------------------------------------
## The two halves add
## ---------------------------------------------------------------------------


## A drifting parent's fragment carries both terms, so its magnitude sits inside the
## additive bounds `|shape − kick| .. shape + kick` scaled by the S22.7 per-child
## whole-vector factor (the jitter x the mass weight, read off the fragment's own
## body) -- the bound only holds if the deployed velocity is the scaled `shape + kick`,
## and a shape that had absorbed the kick (or a kick outside the scale) leaves it.
func test_the_burst_is_additive_on_the_rolled_shape() -> void:
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	var shape := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
	var lowest := INF
	var highest := 0.0
	var total := 0
	for index in DIRECTION_CLEAVES:
		var field := _field_with(FIELD_SEED + index)
		for fragment: Node2D in _break_member("Additive%d" % index, velocity):
			if String(fragment.name).begins_with("Core"):
				continue
			var w := _weight(fragment)
			var deployed := (fragment as RigidBody2D).linear_velocity.length()
			assert_true(
				deployed >= absf(shape - KICK) * AsteroidScript.FRAGMENT_SPEED_JITTER.x * w - SPEED_EPSILON,
				"no fragment falls under the scaled |shape - kick| = %.3f u/s, got %.3f"
					% [absf(shape - KICK) * AsteroidScript.FRAGMENT_SPEED_JITTER.x * w, deployed]
			)
			assert_true(
				deployed <= (shape + KICK) * AsteroidScript.FRAGMENT_SPEED_JITTER.y * w + SPEED_EPSILON,
				"none passes the scaled shape + kick = %.3f u/s, got %.3f"
					% [(shape + KICK) * AsteroidScript.FRAGMENT_SPEED_JITTER.y * w, deployed]
			)
			lowest = minf(lowest, deployed)
			highest = maxf(highest, deployed)
			total += 1
		field.free()
	assert_gt(total, 0, "the additive sample measured at least one fragment")
	assert_true(lowest < KICK and highest > KICK,
		"the roll still spreads the burst around the kick: %.3f .. %.3f u/s" % [lowest, highest])
	assert_gt(highest - lowest, 90.0,
		"the two terms interfere over %.3f u/s of spread, so neither is a constant addition" % (highest - lowest))


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## A detached field with one seeded RNG sequence per break (the same door the cleaving
## suite uses: `_new_rock` is the only way to a chosen size class, and `setup`'s `&"seed"`
## only seeds when it is non-zero).
func _field_with(seed_value: int, count: int = FIELD_ROCKS) -> Node2D:
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": seed_value,
	})
	return _field


## Cracks a field member of the cleaving tier and hands back what it left behind.
## The 2026-10-01 fix round (02 §5.5): the crack goes through the gun door at the
## reference hit -- chip work `SPLIT_IMPACT_REFERENCE x gun_chip_rate` -- so the
## field's impact factor reads exactly 1.0 and the rows below measure the ejection
## shape at its neutral anchor. The A4 splinter sheds are suppressed for the loop
## (a shed joins `rocks`); the chance is restored before the helper returns.
func _break_member(node_name: String, velocity: Vector2) -> Array[Node2D]:
	var rock: Node2D = _field.call(
		&"_new_rock", node_name, &"iron", 1, 4, AsteroidScript.SIZE_LARGE
	)
	rock.position = ORIGIN
	(rock as RigidBody2D).linear_velocity = velocity
	var before := _live_ids()
	var chance := OreTuningScript.splinter_chance
	OreTuningScript.splinter_chance = 0.0
	var chip: float = AsteroidScript.SPLIT_IMPACT_REFERENCE * OreTuningScript.gun_chip_rate
	for _attempt in 256:
		if not is_instance_valid(rock) or bool(rock.call(&"is_depleted")):
			break
		rock.call(&"apply_gun_work", chip)
	OreTuningScript.splinter_chance = chance
	return _new_since(before)


## The fragment's own placement radial: rock centre to spawn point, the direction §14's
## kick rides.
func _radial(fragment: Node2D) -> Vector2:
	return (fragment.global_position - ORIGIN).normalized()


## The amended ejection row's mass weight (S22.7), read off a fragment's own body.
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


func _widest(values: Array[float]) -> float:
	var widest := 0.0
	for a: float in values:
		for b: float in values:
			widest = maxf(widest, absf(wrapf(a - b, -180.0, 180.0)))
	return widest
