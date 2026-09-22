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
##      component ≥ 0.5 × the kick, the deployed speed inside the kick ± the shape, the
##      per-cleave spread past 90° and all four quadrants covered;
##   3. the **zero-kick control**: subtracting the pinned radial from a fragment's velocity
##      reconstructs the pre-wave ejection exactly -- `× 1.2` of the parent's speed, in the
##      rolled direction -- so the inherit stays measurable with the kick on top (it is not
##      measurable by deleting the assertion), and a **stopped** rock's residual reads
##      exactly 0.0 -- the pre-kick ejection the owner complained about;
##   4. the two halves add: the deployed magnitude of a drifting rock's fragment sits inside
##      `|shape − kick| .. shape + kick`, which only holds if the kick is a separate vector
##      and the shape is unchanged.
##
## Nothing awaits a frame: a detached field needs no physics world for any of this (the
## fragments are real `RigidBody2D`s and their velocity is set, not simulated), and the
## breaks' FX and cue are the cleaving suite's rows. A subclass cannot zero the constant --
## GDScript refuses to redeclare a parent's member (measured: `Parse Error: The member
## "FRAGMENT_OUTWARD_KICK" already exists in parent class AsteroidField`), which is why the
## control in test 3 is the exact arithmetic residual rather than a second build.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")

const KICK := 150.0
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
const DRIFT_SPEED := 120.0
const DRIFT_HEADING := 0.7
## 200 distinct seeded breaks: one field seed each, so the sweep covers the whole 2-5 count
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
		"the field's kick is §14's 150.0 u/s, got %s" % FieldScript.FRAGMENT_OUTWARD_KICK)
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
## with at least half the kick of outward speed, its deployed speed is the kick to within
## the (tiny) shape it also carries, and the burst still leaves in every direction.
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
	assert_true(slowest >= KICK - shape - SPEED_EPSILON
			and fastest <= KICK + shape + SPEED_EPSILON,
		"a near-stationary rock's burst is the kick +- the %.3f u/s shape it carries: %.3f .. %.3f" % [shape, slowest, fastest])
	assert_gt(narrowest, 90.0,
		"the burst still leaves in every direction: the narrowest cleave spans %.3f deg (cleave %d)" % [narrowest, narrowest_cleave])
	for quadrant: int in [0, 1, 2, 3]:
		assert_gt(int(quadrants[quadrant]), 0,
			"a fragment left in quadrant %d, which holds %d of %d (%s)" % [quadrant, int(quadrants[quadrant]), total, str(quadrants)])


## ---------------------------------------------------------------------------
## The zero-kick control (F3: the inherit stays measurable)
## ---------------------------------------------------------------------------


## The control, run as arithmetic because the pin is a `const` (see the header): take the
## pinned radial back out of a fragment's velocity and what is left must be §5's shape
## exactly -- `× 1.2` of the parent's speed, rolled over the full circle. The stopped case is
## the same subtraction on a rock the owner would recognise, and there the residual is
## exactly 0.0 (measured before §14: its fragments read radial 0.000), so the measurement is
## sensitive to the kick and not to the arithmetic.
func test_the_zero_kick_residual_isolates_the_x1_2_inherit() -> void:
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	var shape := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
	var deviation_low := INF
	var deviation_high := -INF
	var widest := 0.0
	var residuals := 0
	var beyond := 0
	for index in DIRECTION_CLEAVES:
		var field := _field_with(FIELD_SEED + index)
		var here: Array[float] = []
		for fragment: Node2D in _break_member("Residual%d" % index, velocity):
			var residual := _residual(fragment)
			assert_true(is_equal_approx(residual.length(), shape),
				"the residual is the parent's velocity x %s: %.6f against %.6f" % [AsteroidScript.FRAGMENT_EJECT_MULT, residual.length(), shape])
			var deviation := rad_to_deg(velocity.angle_to(residual))
			here.append(deviation)
			deviation_low = minf(deviation_low, deviation)
			deviation_high = maxf(deviation_high, deviation)
			if absf(deviation) > 90.0:
				beyond += 1
			residuals += 1
		widest = maxf(widest, _widest(here))
		field.free()
	assert_gt(residuals, 0, "the control measured at least one fragment")
	assert_true(deviation_low < 0.0 and deviation_high > 0.0,
		"the rolled shape still lands on both sides of the parent's heading: %.3f .. %.3f deg" % [deviation_low, deviation_high])
	assert_gt(beyond, 0,
		"and past 90 deg off it (%d of %d), which a +-15 deg cone cannot produce" % [beyond, residuals])
	assert_gt(widest, 90.0,
		"two residual headings of one cleave are %.3f deg apart" % widest)
	_field_with(FIELD_SEED)
	var fragments := _break_member("Stopped", Vector2.ZERO)
	assert_true(fragments.size() >= 2,
		"the stopped break left a roll of fragments to read, got %d" % fragments.size())
	for fragment: Node2D in fragments:
		var residual := _residual(fragment)
		assert_true(residual.length() <= SPEED_EPSILON,
			"with the kick subtracted a stopped rock's fragment reads the pre-kick 0.0: %s"
			% residual)
		var deployed := (fragment as RigidBody2D).linear_velocity
		assert_true(is_equal_approx(deployed.length(), KICK),
			"and the deployed velocity is the kick alone: %.6f u/s" % deployed.length())
		assert_true(is_equal_approx(deployed.dot(_radial(fragment)), KICK),
			"all of it radial, measured %.6f u/s" % deployed.dot(_radial(fragment)))


## ---------------------------------------------------------------------------
## The two halves add
## ---------------------------------------------------------------------------


## A drifting parent's fragment carries both terms, so its magnitude sits inside the
## additive bounds `|shape − kick| .. shape + kick` -- the bound only holds if the deployed
## velocity is `shape + kick` as separate vectors, and a shape that had absorbed the kick
## (or a kick scaled by the parent's speed) leaves it.
func test_the_burst_is_additive_on_the_rolled_shape() -> void:
	var velocity := Vector2(DRIFT_SPEED, 0.0).rotated(DRIFT_HEADING)
	var shape := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
	var lowest := INF
	var highest := 0.0
	var total := 0
	for index in DIRECTION_CLEAVES:
		var field := _field_with(FIELD_SEED + index)
		for fragment: Node2D in _break_member("Additive%d" % index, velocity):
			var deployed := (fragment as RigidBody2D).linear_velocity.length()
			lowest = minf(lowest, deployed)
			highest = maxf(highest, deployed)
			total += 1
		field.free()
	assert_gt(total, 0, "the additive sample measured at least one fragment")
	assert_true(lowest >= absf(shape - KICK),
		"no fragment falls under |shape - kick| = %.3f u/s, lowest %.3f" % [absf(shape - KICK), lowest])
	assert_true(highest <= shape + KICK,
		"none passes shape + kick = %.3f u/s, highest %.3f" % [shape + KICK, highest])
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
func _break_member(node_name: String, velocity: Vector2) -> Array[Node2D]:
	var rock: Node2D = _field.call(
		&"_new_rock", node_name, &"iron", 1, 4, AsteroidScript.SIZE_LARGE
	)
	rock.position = ORIGIN
	(rock as RigidBody2D).linear_velocity = velocity
	var before := _live_ids()
	rock.call(&"apply_work", maxf(
		float(int(rock.get(&"yield_units"))), AsteroidScript.WORK_PER_UNIT
	))
	return _new_since(before)


## The fragment's own placement radial: rock centre to spawn point, the direction §14's
## kick rides.
func _radial(fragment: Node2D) -> Vector2:
	return (fragment.global_position - ORIGIN).normalized()


## §5's shape, recovered: the deployed velocity with the pinned kick taken back out.
func _residual(fragment: Node2D) -> Vector2:
	return (fragment as RigidBody2D).linear_velocity - _radial(fragment) * KICK


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
