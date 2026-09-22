@tool
extends McpTestSuite
## Suite engine2_cleaving: engine slice 0's rock body (ruling 8), ruling 17's tiered
## cleaving (ENGINE_SPEC 6/13, 02 5) and the **owner's 2026-09-21 asteroid ruling** --
## "asteroids breaking effects (they should somehow explode, random fragments from 2 to
## 5 moving in random directions)":
##
##   * the split is a uniform random **2-5** on both cleaving tiers (one pair per tier,
##     `Asteroid.FRAGMENT_SPLIT`), replacing the fixed (2,3)/(2,2) rows;
##   * the ejection direction is **uniform over the full circle** -- the retired +-15
##     deg cone is `FRAGMENT_EJECT_CONE_DEG`'s own 360.0 -- and the speed is still the
##     parent's velocity x 1.2, which is now the **shape's half** only: CONTRACTS 14's
##     `FRAGMENT_OUTWARD_KICK` (150 u/s along the placement radial) rides on top of it,
##     so the rows below read the shape back out of the deployed velocity and assert the
##     deployed magnitude inside the additive bounds (S2.6-R2 / F3);
##   * **every depletion draws the break**: FX_SPEC 1.4's five-frame explosion at the
##     rock's own centre, scaled to the rock (1.2 x its collision diameter, clamped
##     96-224 u), S4's rock cue through the four-take pool row, and section 4.2 item 8's
##     blast on the neighbours the rock can reach;
##   * a Small still bursts 1-2 pickups (there is no tier below Small) and a yield-0
##     rock still cracks bare -- but it draws the break too, because the break is the
##     rock's death, not an ore event.
##
## The field is a detached `AsteroidField` (its rocks are real `RigidBody2D`s, so the
## body properties are measurable without a physics world) and the cleaving cases are
## field members spawned through `_new_rock` -- the only door to a rock with a chosen
## size class or a 0-unit roll, since a field's own roll is uniform over the nine looks.
## Every roll is seeded, so each number below is reproducible; the FX and the cue hang
## off the tree, so one test builds the field inside it. Nothing awaits a frame: the
## gate's runner calls test methods synchronously, so the timed measurements (a blast
## arriving over `EXPLOSION_WINDOW`) live in `tests/probe_rock_cleave.gd`.
##
## The `Pickup` leaf compiles as of 2026-09-21 (its pod path was repaired to
## `assets/env/pickup/`), so the Small's burst is asserted here rather than deferred:
## a detached field parents its pickups to itself (`_world_parent`'s fallback), which
## makes the burst's count readable without a scene.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const FxScript := preload("res://game/fx.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 7331
const ROCK_COUNT := 6
const EJECT_SPEED := 120.0
const EJECT_HEADING := 0.7
## The additive bounds below are measured on `float32`-backed velocities; this slack is far
## smaller than either term (measured overshoot at most 0.0001 u/s).
const ADDITIVE_SLACK := 0.01
const EXPLOSION_NAME := "explosion"
const EXPLOSION_FRAMES := 5
const PICKUP_SCRIPT := "res://game/pickup.gd"
const AUDIO_SERVICE: StringName = &"AudioManager"
const ROCK_CUE: StringName = &"sfx_impact_rock"
const ROCK_CUE_TAKES := 4
## The cue the two audio assertions seed the observable with: `AudioManager.last_sfx()`
## is one value, and the rock row cycles, so "the value changed" is not evidence that the
## break played anything. Seeding it with another shipped cue makes the replacement the
## proof (the `test_flight_beam_g2.gd` precedent).
const SEED_CUE: StringName = &"sfx_impact_hull"
## Enough uniform 2-5 rolls that "the count varies" is a statement about the mechanic
## rather than about the seed (40 rolls of a four-wide uniform land on one value with
## probability ~4e-24), and enough 360 deg rolls that a >90 deg deviation is certain.
const VARIETY_CLEAVES := 40
const DIRECTION_CLEAVES := 8

var _field: Node2D = null
var _root: Node2D = null


func suite_name() -> String:
	return "engine2_cleaving"


## One fixture root in the tree: only the cue test needs one, because
## `Projectile.play_impact` reaches the `AudioManager` autoload through its host's tree.
## Its host is the `PlayerProfile` autoload and not the tree root, because a suite's
## `suite_setup` runs while the root is still building its children and `add_child` on
## it is refused (the `test_weapon_fx_f2.gd` precedent).
func suite_setup(_ctx: Dictionary) -> void:
	_root = Node2D.new()
	_root.name = &"CleavingFixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear_fx()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func setup() -> void:
	_field = null


func teardown() -> void:
	_clear_fx()
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _audio() -> Node:
	var tree := _tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


## A detached field: no scene, no clock dependency (a crack only stamps
## `last_depleted_time` when the field empties).
func _field_with(count: int = ROCK_COUNT) -> Node2D:
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": FIELD_SEED,
	})
	return _field


## The same field, inside the tree, so its breaks can reach the audio service.
func _field_in_tree(count: int = ROCK_COUNT) -> Node2D:
	_field_with(count)
	_root.add_child(_field)
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


## Every explosion sprite a break has left: a detached field's effects hang off the
## field itself (`_world_parent`'s fallback) and an in-tree field's off the scene, so
## both roots are searched. Matched by class plus the name prefix, because a second
## sibling handed the same name is renamed by the engine (`explosion2`, ...).
func _explosions() -> Array[Node]:
	var out: Array[Node] = []
	var roots: Array[Node] = []
	var tree := _tree()
	if tree != null:
		roots.append(tree.root)
	if _root != null and is_instance_valid(_root):
		roots.append(_root)
	if _field != null and is_instance_valid(_field):
		roots.append(_field)
	for root: Node in roots:
		for node: Node in root.find_children("*", "AnimatedSprite2D", true, false):
			if String(node.name).begins_with(EXPLOSION_NAME) and not out.has(node):
				out.append(node)
	return out


## The one-shot explosions free themselves on `animation_finished`, which needs a
## frame; the suite runs synchronously, so teardown clears the ones still alive.
func _clear_fx() -> void:
	for node: Node in _explosions():
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()


func _pickups() -> Array[Node]:
	var out: Array[Node] = []
	if _field == null or not is_instance_valid(_field):
		return out
	for node: Node in _field.find_children("*", "Node2D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("pickup.gd"):
			out.append(node)
	return out


func _fragment_headings(fragments: Array[Node2D], heading: Vector2) -> Array[float]:
	var out: Array[float] = []
	for fragment: Node2D in fragments:
		out.append(rad_to_deg(heading.angle_to((fragment as RigidBody2D).linear_velocity)))
	return out


## §5's shape recovered from a fragment's deployed velocity: CONTRACTS 14's
## `FRAGMENT_OUTWARD_KICK` rides the fragment's own placement radial (rock centre to spawn
## point, the direction the field places it on), so taking that vector back out leaves
## exactly the rolled inherit `FRAGMENT_EJECT_CONE_DEG` owns.
func _shape_half(fragment: Node2D, origin: Vector2) -> Vector2:
	var radial := (fragment.global_position - origin).normalized()
	return (fragment as RigidBody2D).linear_velocity - radial * FieldScript.FRAGMENT_OUTWARD_KICK


func _widest_pair(headings: Array[float]) -> float:
	var widest := 0.0
	for a: float in headings:
		for b: float in headings:
			widest = maxf(widest, absf(wrapf(a - b, -180.0, 180.0)))
	return widest


## ---------------------------------------------------------------------------
## The body (ruling 8)
## ---------------------------------------------------------------------------


func test_rock_is_a_heavy_damped_rigid_body() -> void:
	var field := _field_with()
	var rock: Node2D = _rocks()[0]
	var body := rock as RigidBody2D
	assert_true(body != null, "the rock is a RigidBody2D")
	var reference_row: Dictionary = ShipFitScript.HANDLING[AsteroidScript.ROCK_MASS_REFERENCE]
	var want := float(reference_row[&"hull_mass"]) * AsteroidScript.ROCK_MASS_MULT
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
	_field_with()
	for rock: Node2D in _rocks():
		var look := int(rock.call(&"look_index"))
		var klass := int(rock.call(&"size_class"))
		assert_eq(klass, int(float(look) / float(AsteroidScript.LOOKS_PER_SIZE)),
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
	_field_with()
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
	_field_with()
	var rock := _member(AsteroidScript.SIZE_LARGE, 3, "Cracker")
	var cracks: Array[int] = []
	rock.connect(&"cracked", func() -> void: cracks.append(1))
	assert_eq(int(rock.call(&"apply_work", 3.0)), 3, "three cycles mine three units")
	assert_true(bool(rock.call(&"is_depleted")), "the rock is depleted")
	assert_eq(cracks.size(), 1, "cracked fires once")
	assert_eq(int(rock.call(&"apply_work", 1.0)), 0, "a depleted rock mines nothing more")
	assert_eq(cracks.size(), 1, "and cannot crack twice")


## ---------------------------------------------------------------------------
## Cleaving (ruling 17, as amended 2026-09-21)
## ---------------------------------------------------------------------------


## The amended split row as a constant, plus the two rows the ruling leaves alone: a
## Small still fragments into nothing (its cleave is the pickup burst) and the ejection
## speed is still the shipped 1.2 with a direction of the whole circle.
func test_the_split_table_is_the_amended_row() -> void:
	_field_with()
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_LARGE], Vector2i(2, 5),
		"L -> 2-5 M")
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_MEDIUM], Vector2i(2, 5),
		"M -> 2-5 S")
	assert_eq(AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_SMALL], Vector2i(0, 0),
		"S -> no rock fragments")
	assert_eq(AsteroidScript.PICKUP_BURST, Vector2i(1, 2), "S -> 1-2 pickups")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2),
		"ejection speed is the shipped x1.2")
	assert_true(is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0),
		"ejection direction is the full circle (the +-15 deg cone is retired)")


func test_large_cleaves_into_two_to_five_mediums() -> void:
	_field_with()
	var counts: Array[int] = []
	for index in 6:
		var parent := _member(AsteroidScript.SIZE_LARGE, 4, "Large%d" % index)
		var origin: Vector2 = (parent as Node2D).global_position
		var mineral := StringName(parent.get(&"mineral_id"))
		var velocity := Vector2(EJECT_SPEED, 0.0).rotated(EJECT_HEADING)
		(parent as RigidBody2D).linear_velocity = velocity
		var before := _live_ids()
		_deplete(parent)
		var fragments := _new_since(before)
		assert_true(fragments.size() >= 2 and fragments.size() <= 5,
			"a Large spawns 2-5 fragments, got %d" % fragments.size())
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
			var shape := _shape_half(fragment, origin)
			## The inherit, measured as §5's shape: the deployed velocity with the field's
			## radial kick taken back out is still `parent velocity x 1.2` exactly, so the
			## kick is additive and does not scale with the parent (F3's "stays measurable").
			assert_true(is_equal_approx(shape.length(),
				velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT),
				"the fragment still inherits x%s of the parent's speed, got %s"
				% [AsteroidScript.FRAGMENT_EJECT_MULT, shape.length()])
			## And the deployed magnitude sits inside the additive bounds: the two vectors
			## can only be as short as their difference and as long as their sum.
			var lowest := absf(velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT
				- FieldScript.FRAGMENT_OUTWARD_KICK)
			var highest := velocity.length() * AsteroidScript.FRAGMENT_EJECT_MULT \
				+ FieldScript.FRAGMENT_OUTWARD_KICK
			assert_true(ejected.length() >= lowest - ADDITIVE_SLACK
					and ejected.length() <= highest + ADDITIVE_SLACK,
				"the burst is the shape plus the kick, so its magnitude is %.3f..%.3f, got %.3f"
				% [lowest, highest, ejected.length()])
	assert_eq(counts.size(), 6, "six Large rocks were cracked")


func test_medium_cleaves_into_two_to_five_smalls() -> void:
	_field_with()
	var counts: Array[int] = []
	for index in 6:
		var parent := _member(AsteroidScript.SIZE_MEDIUM, 3, "Medium%d" % index)
		(parent as RigidBody2D).linear_velocity = Vector2(EJECT_SPEED, 0.0)
		var before := _live_ids()
		_deplete(parent)
		var fragments := _new_since(before)
		assert_true(fragments.size() >= 2 and fragments.size() <= 5,
			"a Medium spawns 2-5 fragments, got %d" % fragments.size())
		counts.append(fragments.size())
		for fragment: Node2D in fragments:
			assert_eq(int(fragment.call(&"size_class")), AsteroidScript.SIZE_SMALL,
				"a Medium's fragments are Small")
	assert_eq(counts.size(), 6, "six Medium rocks were cracked")


## The count is a *roll*, not a fixed row: over `VARIETY_CLEAVES` seeded cleaves the
## observed values must include at least two distinct counts, and all of them inside
## the amended 2-5 pair. A fixed row (the retired (2,3)/(2,2) shape) cannot do that.
func test_the_fragment_count_varies_inside_the_amended_bounds() -> void:
	_field_with()
	var seen: Dictionary = {}
	for index in VARIETY_CLEAVES:
		var size_class := AsteroidScript.SIZE_LARGE if index % 2 == 0 else AsteroidScript.SIZE_MEDIUM
		var parent := _member(size_class, 3, "Variety%d" % index)
		var before := _live_ids()
		_deplete(parent)
		seen[_new_since(before).size()] = true
	var counts: Array = seen.keys()
	counts.sort()
	var lowest: int = counts.min()
	var highest: int = counts.max()
	assert_true(lowest >= 2 and highest <= 5,
		"every roll sits inside 2-5, got %s" % [counts])
	assert_true(counts.size() >= 2,
		"the count is random, not a fixed row: %d distinct values over %d cleaves (%s)"
		% [counts.size(), VARIETY_CLEAVES, counts])


## The owner's "moving in random directions" as a measurement: with the cone retired a
## fragment can land more than 90 deg off its parent's heading (a +-15 deg cone cannot
## produce that), and two fragments of one cleave can land more than 90 deg apart. Both are
## read twice -- on the deployed velocity, which since §14 is the rolled shape **plus** the
## field's radial kick, and on the shape alone (the residual), which is the roll the cone
## constant owns -- so the kick cannot hide a narrowed cone.
func test_ejection_directions_are_uniform_over_the_full_circle() -> void:
	_field_with()
	var deviations: Array[float] = []
	var shapes: Array[float] = []
	var widest := 0.0
	var shape_widest := 0.0
	for index in DIRECTION_CLEAVES:
		var parent := _member(AsteroidScript.SIZE_LARGE, 4, "Spinner%d" % index)
		var origin: Vector2 = (parent as Node2D).global_position
		var heading := Vector2(EJECT_SPEED, 0.0).rotated(EJECT_HEADING)
		(parent as RigidBody2D).linear_velocity = heading
		var before := _live_ids()
		_deplete(parent)
		var fragments := _new_since(before)
		var deviations_here := _fragment_headings(fragments, heading)
		var shapes_here: Array[float] = []
		for fragment: Node2D in fragments:
			shapes_here.append(
				rad_to_deg(heading.angle_to(_shape_half(fragment, origin)))
			)
		for deviation: float in deviations_here:
			deviations.append(deviation)
		for deviation: float in shapes_here:
			shapes.append(deviation)
		widest = maxf(widest, _widest_pair(deviations_here))
		shape_widest = maxf(shape_widest, _widest_pair(shapes_here))
	var beyond: int = 0
	for deviation: float in deviations:
		if absf(deviation) > 90.0:
			beyond += 1
	assert_true(beyond > 0,
		"a fragment landed past 90 deg off the parent's heading (%d of %d, widest pair %.1f deg)"
		% [beyond, deviations.size(), widest])
	assert_true(widest > 90.0,
		"two fragments of one cleave landed %.1f deg apart" % widest)
	var shape_beyond: int = 0
	for deviation: float in shapes:
		if absf(deviation) > 90.0:
			shape_beyond += 1
	assert_true(shape_beyond > 0,
		"and the roll alone does too (%d of %d, widest pair %.1f deg): the kick rotates the"
		% [shape_beyond, shapes.size(), shape_widest]
		+ " 360 deg spread without narrowing it")
	assert_true(shape_widest > 90.0,
		"the rolled shape spreads a cleave %.1f deg, so the cone constant is still 360"
		% shape_widest)


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


## The break's explosion: FX_SPEC 1.4's five-frame sequence at the rock's own centre,
## read at `1.2 x the rock's collision diameter`, clamped 96-224 u.
func test_the_break_spawns_the_explosion_on_the_rock_centre_scaled_to_it() -> void:
	_field_with()
	var row: Dictionary = ProjectileScript.feedback_row(&"explosion")
	var source: Vector2 = row.get(&"source", Vector2.ZERO)
	var centre := Vector2(240.0, -80.0)
	var rock := _member(AsteroidScript.SIZE_LARGE, 4, "Exploding")
	rock.position = centre
	var diameter := 2.0 * float(rock.call(&"world_radius"))
	var before := _explosions().size()
	_deplete(rock)
	var spawned := _explosions()
	assert_eq(spawned.size(), before + 1, "one explosion sequence per break")
	var sprite := spawned[spawned.size() - 1] as AnimatedSprite2D
	assert_true(sprite != null, "the break draws FX_SPEC 1.4's sheet")
	if sprite == null:
		return
	assert_true(sprite.position.distance_to(centre) < 0.001,
		"the sequence sits on the rock's centre, got %s" % sprite.position)
	var want := clampf(diameter * ProjectileScript.ROCK_BREAK_WORLD_SCALE,
		ProjectileScript.ROCK_BREAK_WORLD_MIN, ProjectileScript.ROCK_BREAK_WORLD_MAX)
	assert_true(is_equal_approx(sprite.scale.x, want / maxf(source.x, source.y)),
		"scaled to %.2f world units (rock diameter %.2f), got scale %.6f"
		% [want, diameter, sprite.scale.x])
	assert_eq(sprite.sprite_frames.get_frame_count(FxScript.ANIMATION), EXPLOSION_FRAMES,
		"the shipped five-frame sequence")


## The pair's own ends, measured on the helper: a Small rock's 1.2 x read is under the
## row's 96 u floor (so it takes the floor rather than drawing a spark) and an oversized
## radius is capped at 224 u.
func test_the_rock_break_explosion_is_floored_and_capped() -> void:
	var field := _field_with()
	var row: Dictionary = ProjectileScript.feedback_row(&"explosion")
	var source: Vector2 = row.get(&"source", Vector2.ZERO)
	var longest := maxf(source.x, source.y)
	var small := _member(AsteroidScript.SIZE_SMALL, 4, "Tiny")
	var small_diameter := 2.0 * float(small.call(&"world_radius"))
	assert_true(small_diameter * ProjectileScript.ROCK_BREAK_WORLD_SCALE
			< ProjectileScript.ROCK_BREAK_WORLD_MIN,
		"a Small's 1.2 x read (%.2f u) is under the floor"
		% (small_diameter * ProjectileScript.ROCK_BREAK_WORLD_SCALE))
	var floored := ProjectileScript.spawn_rock_break(field, Vector2.ZERO, small_diameter)
	assert_true(floored != null and is_equal_approx(
			floored.scale.x, ProjectileScript.ROCK_BREAK_WORLD_MIN / longest),
		"and it draws at the row's own 96 u")
	var capped := ProjectileScript.spawn_rock_break(field, Vector2.ZERO, 4096.0)
	assert_true(capped != null and is_equal_approx(
			capped.scale.x, ProjectileScript.ROCK_BREAK_WORLD_MAX / longest),
		"an oversized radius is capped at 224 u")


## S4's rock cue, and the L53 pool row the break resolves it through: the four takes
## that had been on disk with no row are a round-robin now, so consecutive breaks do not
## repeat a take.
func test_the_break_plays_the_rock_cue_from_its_four_take_pool() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var takes: Array = AudioScript.CUE_POOLS[ROCK_CUE][&"takes"]
	assert_eq(takes.size(), ROCK_CUE_TAKES, "L53: the four rock takes are a row now")
	assert_eq(StringName(AudioScript.CUE_POOLS[ROCK_CUE][&"mode"]), &"round_robin",
		"and the row cycles, so a break does not repeat the last take")
	_field_in_tree()
	var rock := _member(AsteroidScript.SIZE_LARGE, 4, "Cued")
	audio.call(&"play_sfx", SEED_CUE)
	_deplete(rock)
	var played := StringName(audio.call(&"last_sfx"))
	assert_true(played != SEED_CUE, "the break played a cue (was %s, now %s)" % [SEED_CUE, played])
	assert_true(takes.has(played), "S4's rock takes: it played %s" % played)
	audio.call(&"play_pool", ROCK_CUE)
	assert_true(StringName(audio.call(&"last_sfx")) != played,
		"the next read of the row takes the next take (played %s)"
		% StringName(audio.call(&"last_sfx")))


func test_yield_zero_cracks_bare_and_still_draws_the_break() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var takes: Array = AudioScript.CUE_POOLS[ROCK_CUE][&"takes"]
	_field_in_tree()
	var bare := _member(AsteroidScript.SIZE_LARGE, 0, "Bare")
	var before := _live_ids()
	var fx_before := _explosions().size()
	audio.call(&"play_sfx", SEED_CUE)
	assert_eq(int(bare.get(&"yield_units")), 0, "it rolled no ore")
	assert_false(bool(bare.call(&"cleaves")), "and reports that it does not cleave")
	var cracks: Array[int] = []
	bare.connect(&"cracked", func() -> void: cracks.append(1))
	_deplete(bare)
	assert_eq(cracks.size(), 1, "it still cracks")
	assert_true(_new_since(before).size() == 0, "with no fragments")
	assert_true(_live_ids().size() == before.size() - 1,
		"and it is gone from the field: %d -> %d" % [before.size(), _live_ids().size()])
	assert_eq(_explosions().size(), fx_before + 1,
		"the break is the rock's death, not an ore event: it explodes all the same")
	var played := StringName(audio.call(&"last_sfx"))
	assert_true(played != SEED_CUE and takes.has(played),
		"and it plays the same break cue (%s)" % played)
	var yielded := _member(AsteroidScript.SIZE_LARGE, 4, "Yielded")
	assert_true(bool(yielded.call(&"cleaves")), "a rock that rolled ore does cleave")


## A Small's own end: no rock fragments, 1-2 pickups of its mineral, and the same break
## read every other rock gets.
func test_a_small_bursts_one_to_two_pickups() -> void:
	_field_with()
	var counts: Array[int] = []
	for index in 6:
		var small := _member(AsteroidScript.SIZE_SMALL, 4, "Small%d" % index)
		var before := _live_ids()
		var pickups_before := _pickups().size()
		var fx_before := _explosions().size()
		_deplete(small)
		assert_true(_new_since(before).size() == 0,
			"a Small spawns no rock fragments (there is no tier below it)")
		assert_eq(_explosions().size(), fx_before + 1, "and it draws the break too")
		counts.append(_pickups().size() - pickups_before)
		assert_true(counts[counts.size() - 1] >= 1 and counts[counts.size() - 1] <= 2,
			"a Small bursts 1-2 pickups, got %d" % counts[counts.size() - 1])
		for pickup: Node in _pickups():
			assert_eq(StringName(pickup.get(&"item_id")), _ore_id(),
				"the pickup carries the rock's mineral, got %s" % pickup.get(&"item_id"))
	assert_eq(counts.size(), 6, "six Small rocks were cracked")


## The ore item id a rock carrying `&"iron"` bursts: read from the catalogue the field
## itself rolls through (02 7.5's cargo identity), never hand-written here.
func _ore_id() -> StringName:
	return MineralCatalogScript.ore_id(&"iron")
