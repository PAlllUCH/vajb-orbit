@tool
extends McpTestSuite
## Suite engine2_cleaving: engine slice 0's rock body (ruling 8) and ruling 17's
## tiered cleaving (ENGINE_SPEC 6/13, 02 5).
##
## The field is a detached `AsteroidField` (its rocks are real `RigidBody2D`s, so
## the body properties are measurable without a physics world), and the cleaving
## cases are field members spawned through `_new_rock` -- the only door to a rock
## with a chosen size class or a 0-unit roll, since a field's own roll is uniform
## over the nine looks. Nothing awaits a frame: the gate's runner calls test
## methods synchronously, so the timed drift measurement lives in
## `tools/_probe_s0m2_rocks.gd` instead.
##
## A Small's crack reaches for the `Pickup` leaf, which does not compile in this
## workspace (the naming re-layout left its own `env_pickup_ore_pod` path stale,
## see the M2 report's blocker). The suite therefore covers the Small's
## *no-fragments* half and leaves the burst's 1-2 pickups to the probe, which
## reports it as blocked rather than inventing an assertion the workspace cannot
## satisfy.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 7331
const ROCK_COUNT := 6
const EJECT_SPEED := 120.0
const EJECT_HEADING := 0.7

var _field: Node2D = null


func suite_name() -> String:
	return "engine2_cleaving"


func setup() -> void:
	_field = null


func teardown() -> void:
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


## A detached field: no scene, no clock dependency (a crack only stamps
## `last_depleted_time` when the field empties).
func _field_with(count: int = ROCK_COUNT) -> Node2D:
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": FIELD_SEED,
	})
	return _field


func _rocks() -> Array[Node2D]:
	return _field.call(&"rocks") as Array[Node2D]


func _live_ids() -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in _rocks():
		out.append(rock.get_instance_id())
	return out


func _new_since(before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _rocks():
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## A field member of a chosen size class and unit count.
func _member(size_class: int, units: int, node_name: String = "Probe") -> Node2D:
	return _field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


## Deplete through the rock's own arithmetic, with WORK_PER_UNIT as the floor so a
## 0-unit rock is handed the positive work that cracks it.
func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(float(int(rock.get(&"yield_units"))),
		AsteroidScript.WORK_PER_UNIT))


## ---------------------------------------------------------------------------
## The body (ruling 8)
## ---------------------------------------------------------------------------


func test_rock_is_a_heavy_damped_rigid_body() -> void:
	var field := _field_with()
	var rock: Node2D = _rocks()[0]
	var body := rock as RigidBody2D
	assert_true(body != null, "the rock is a RigidBody2D")
	var reference: Dictionary = ShipFitScript.HANDLING[AsteroidScript.ROCK_MASS_REFERENCE]
	var want := float(reference[&"hull_mass"]) * AsteroidScript.ROCK_MASS_MULT
	assert_eq(body.mass, want, "mass = ROCK_MASS_MULT x the reference class hull_mass")
	assert_eq(body.gravity_scale, 0.0, "gravity is off in space")
	assert_true(is_equal_approx(body.linear_damp, AsteroidScript.LINEAR_DAMP),
		"the derived linear damp, got %s" % body.linear_damp)
	assert_eq(body.linear_damp_mode, RigidBody2D.DAMP_MODE_REPLACE,
		"the project's default damp must not be added on top")
	assert_false(body.can_sleep, "a rock never sleeps (contacts must answer)")
	assert_eq(body.collision_layer, AsteroidScript.COLLISION_LAYER, "rock layer")
	## The rock's mask is the hull layer, and it must be: Godot pairs two bodies from both
	## sides, and a body whose mask misses the peer's layer is solved with a forced-zero
	## inverse mass (C1 measured a rock handed 0.000 u/s and moved 0.000 u by a 450 u/s
	## ram). "Rocks mask nothing" was half of the engine rule; `mask 2 & layer 1 = 0` is
	## what still keeps two rocks apart.
	assert_eq(body.collision_mask, AsteroidScript.COLLISION_MASK, "the rock masks the hull layer")
	assert_eq(
		AsteroidScript.COLLISION_MASK & AsteroidScript.COLLISION_LAYER,
		0,
		"and nothing else: two rocks are both layer 1, so rocks do not collide with rocks"
	)
	assert_gt(float(rock.call(&"world_radius")), 0.0, "the shape follows the sprite")
	assert_eq(field.call(&"rock_count"), ROCK_COUNT, "the field rolled its rocks")


func test_size_class_follows_the_look_row() -> void:
	var field := _field_with()
	for rock: Node2D in _rocks():
		var look := int(rock.call(&"look_index"))
		var klass := int(rock.call(&"size_class"))
		assert_eq(klass, look / AsteroidScript.LOOKS_PER_SIZE,
			"look %d is row %d" % [look, klass])
		assert_true(klass >= AsteroidScript.SIZE_SMALL and klass <= AsteroidScript.SIZE_LARGE,
			"a rolled class stays inside the three rows")
	for size_class in [AsteroidScript.SIZE_SMALL, AsteroidScript.SIZE_MEDIUM,
			AsteroidScript.SIZE_LARGE]:
		var pinned := _member(size_class, 3, "Pinned%d" % size_class)
		assert_eq(int(pinned.call(&"size_class")), size_class,
			"a pinned size class lands in its own row")


## ---------------------------------------------------------------------------
## The chip arithmetic (untouched by slice 0)
## ---------------------------------------------------------------------------


func test_apply_work_arithmetic_is_unchanged() -> void:
	var field := _field_with()
	var rock := _member(AsteroidScript.SIZE_SMALL, 6, "Worker")
	assert_eq(int(rock.get(&"yield_units")), 6, "the roll is carried")
	var mined := 0
	for _hit in 10:
		mined += int(rock.call(&"apply_work", 0.1))
	assert_eq(mined, 1, "ten 0.1 hits mine exactly one unit (the 10 % chip rate)")
	assert_eq(int(rock.get(&"yield_units")), 5, "one unit left the rock")
	assert_true(absf(float(rock.get(&"work"))) < AsteroidScript.WORK_EPSILON,
		"the fractional remainder is forgiven, not rounded away")
	assert_eq(int(rock.call(&"apply_work", 0.0)), 0, "zero work mines nothing")
	assert_eq(int(rock.get(&"yield_units")), 5, "and takes nothing")


func test_depletion_emits_cracked_once() -> void:
	var field := _field_with()
	var rock := _member(AsteroidScript.SIZE_LARGE, 3, "Cracker")
	var cracks: Array[int] = []
	rock.connect(&"cracked", func() -> void: cracks.append(1))
	assert_eq(int(rock.call(&"apply_work", 3.0)), 3, "three cycles mine three units")
	assert_true(bool(rock.call(&"is_depleted")), "the rock is depleted")
	assert_eq(cracks.size(), 1, "cracked fires once")
	assert_eq(int(rock.call(&"apply_work", 1.0)), 0, "a depleted rock mines nothing more")
	assert_eq(cracks.size(), 1, "and cannot crack twice")


## ---------------------------------------------------------------------------
## Cleaving (ruling 17)
## ---------------------------------------------------------------------------


func test_large_cleaves_into_two_or_three_mediums() -> void:
	var field := _field_with()
	var counts: Array[int] = []
	for index in 6:
		var parent := _member(AsteroidScript.SIZE_LARGE, 4, "Large%d" % index)
		var mineral := StringName(parent.get(&"mineral_id"))
		var velocity := Vector2(EJECT_SPEED, 0.0).rotated(EJECT_HEADING)
		(parent as RigidBody2D).linear_velocity = velocity
		var before := _live_ids()
		_deplete(parent)
		var fragments := _new_since(before)
		assert_true(fragments.size() >= 2 and fragments.size() <= 3,
			"a Large spawns 2-3 fragments, got %d" % fragments.size())
		counts.append(fragments.size())
		for fragment: Node2D in fragments:
			assert_eq(int(fragment.call(&"size_class")), AsteroidScript.SIZE_MEDIUM,
				"a Large's fragments are Medium")
			assert_eq(StringName(fragment.get(&"mineral_id")), mineral,
				"the fragment inherits the parent's mineral")
			assert_true(int(fragment.get(&"yield_units")) >= 1,
				"the fragment's yield is re-rolled (02 5), got %d"
				% int(fragment.get(&"yield_units")))
			var ejected := (fragment as RigidBody2D).linear_velocity
			assert_true(is_equal_approx(ejected.length(),
				velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT),
				"the fragment ejects at x%s, got %s" % [AsteroidScript.FRAGMENT_EJECT_MULT,
				ejected.length()])
			var deviation := absf(rad_to_deg(velocity.angle_to(ejected)))
			assert_true(deviation <= AsteroidScript.FRAGMENT_EJECT_CONE_DEG + 0.0001,
				"the eject stays inside the +-%s deg cone, got %s"
				% [AsteroidScript.FRAGMENT_EJECT_CONE_DEG, deviation])
	assert_eq(counts.size(), 6, "six Large rocks were cracked")


func test_medium_cleaves_into_two_smalls() -> void:
	var field := _field_with()
	var parent := _member(AsteroidScript.SIZE_MEDIUM, 3, "Medium")
	(parent as RigidBody2D).linear_velocity = Vector2(EJECT_SPEED, 0.0)
	var before := _live_ids()
	_deplete(parent)
	var fragments := _new_since(before)
	assert_eq(fragments.size(), 2, "a Medium spawns exactly 2 fragments")
	for fragment: Node2D in fragments:
		assert_eq(int(fragment.call(&"size_class")), AsteroidScript.SIZE_SMALL,
			"a Medium's fragments are Small")


func test_fragments_join_the_same_field() -> void:
	var field := _field_with()
	var parent := _member(AsteroidScript.SIZE_LARGE, 4, "Joiner")
	var before := _live_ids()
	_deplete(parent)
	var fragments := _new_since(before)
	assert_true(_live_ids().size() == before.size() - 1 + fragments.size(),
		"the parent left and its fragments arrived: %d -> %d with %d fragment(s)"
		% [before.size(), _live_ids().size(), fragments.size()])
	assert_false(bool(field.call(&"is_depleted")),
		"a field holding live fragments is not depleted")


## 13's cleaving table, verbatim. The Small's own end-to-end crack is measured in
## `tools/_probe_s0m2_rocks.gd` instead of here: cracking a Small reaches for the
## `Pickup` leaf, which does not compile in this workspace (`pickup.gd` still
## preloads the flat `assets/env/env_pickup_ore_pod.png` the naming re-layout moved
## into `env/pickup/`), and even asking whether that leaf compiles prints its parse
## errors into the gate log, which CONTRACTS section 9 forbids. The probe reports
## that half as blocked, with the one-line fix.
func test_cleaving_split_table_matches_section_13() -> void:
	_field_with()
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_LARGE], Vector2i(2, 3),
		"L -> 2-3 M")
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_MEDIUM], Vector2i(2, 2),
		"M -> 2 S")
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_SMALL], Vector2i(0, 0),
		"S -> no rock fragments")
	assert_eq(AsteroidScript.PICKUP_BURST, Vector2i(1, 2), "S -> 1-2 pickups")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2)
		and is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 15.0),
		"ejection: x1.2 +-15 deg")


func test_yield_zero_cracks_bare() -> void:
	var field := _field_with()
	var bare := _member(AsteroidScript.SIZE_LARGE, 0, "Bare")
	var before := _live_ids()
	assert_eq(int(bare.get(&"yield_units")), 0, "it rolled no ore")
	assert_false(bool(bare.call(&"cleaves")), "and reports that it does not cleave")
	var cracks: Array[int] = []
	bare.connect(&"cracked", func() -> void: cracks.append(1))
	_deplete(bare)
	assert_eq(cracks.size(), 1, "it still cracks")
	assert_true(_new_since(before).size() == 0, "with no fragments")
	assert_true(_live_ids().size() == before.size() - 1,
		"and it is gone from the field: %d -> %d" % [before.size(), _live_ids().size()])
	var yielded := _member(AsteroidScript.SIZE_LARGE, 4, "Yielded")
	assert_true(bool(yielded.call(&"cleaves")), "a rock that rolled ore does cleave")
