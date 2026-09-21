@tool
extends McpTestSuite
## Suite engine2_damage: engine slice 2's damage pipeline (ENGINE_SPEC section 4.2 items
## 1-8) -- the two pinned doors (`Damage.apply`, `Damage.regen`), the item-5 hit context
## and the item 6-8 push routing through `impact.gd`.
##
## Pure logic where the rule is logic: the sinks are throwaway inner classes (the wave
## pins both arities of the hit method, and a real `PlayerState` is the third), the
## shield numbers are a throwaway `PlayerState`, and nothing awaits a frame. The timed
## half -- the same 4 s window stepped frame by frame on a real hull, and an impulse
## landing on a body inside the tree -- lives in `tools/_probe_s2w2_damage.gd`.
##
## Nothing here is a new number: the expected damage is `Impact.collision_damage`'s own
## return, the expected impulse is the `sqrt(2 * E * M)` CONTRACTS section 8.1 names, and
## the rates are the section 4.2/13 ones (`ShipFit` resolves the module's half).

const DamageScript := preload("res://game/damage.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")

const HULL_MAX := 1000.0
const SHIELD_MAX := 600.0
const FRAMES_PER_SECOND := 60

## Section 13 "Shield regen": base 2/s plus the fitted S module's value.
const BASE_SHIELD_REGEN := 2.0
const S_LIGHT_REGEN_ADD := 4.0

var _state: PlayerState = null
var _nodes: Array[Node] = []


## The three-argument sink the wave pins for a ship hull: the hit, its bypass flag and the
## item-5 context. A `PlayerState` is the other three-argument sink (its method is named
## `damage`), so the suite measures both spellings.
class ContextSink extends RefCounted:
	var calls: int = 0
	var amount: float = 0.0
	var bypass: bool = false
	var ctx: Dictionary = {}

	func take_damage(hit: float, bypass_shield: bool, context := {}) -> void:
		calls += 1
		amount = hit
		bypass = bypass_shield
		ctx = context


## The wave's other pin -- `NpcShip.take_damage(amount, bypass_shield)`, which declares no
## context parameter at all -- so the suite proves the two-argument call still lands.
class TwoArgSink extends RefCounted:
	var calls: int = 0
	var amount: float = 0.0
	var bypass: bool = false

	func take_damage(hit: float, bypass_shield: bool) -> void:
		calls += 1
		amount = hit
		bypass = bypass_shield


## A hull for the push seams: a transform the item-5 context reads, the `impact_body()`
## seam for its mass, the `apply_impulse` seam for knockback, and a hit method so a ram is
## observable the way a real hull's would be.
class Hull extends Node2D:
	var body: RigidBody2D = null
	var impulses: Array[Vector2] = []
	var hits: int = 0
	var amount: float = 0.0
	var bypass: bool = false
	var ctx: Dictionary = {}

	func impact_body() -> RigidBody2D:
		return body

	func apply_impulse(impulse: Vector2) -> void:
		impulses.append(impulse)

	func take_damage(hit: float, bypass_shield: bool, context := {}) -> void:
		hits += 1
		amount = hit
		bypass = bypass_shield
		ctx = context


func suite_name() -> String:
	return "engine2_damage"


func setup() -> void:
	_state = PlayerStateScript.new()
	_state.hull_max = HULL_MAX
	_state.shield_max = SHIELD_MAX
	_state.setup()
	_nodes.clear()


func teardown() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	_state = null


## ---------------------------------------------------------------------------
## The front door (section 4.2 items 1 and 5)
## ---------------------------------------------------------------------------


func test_apply_delivers_an_item5_context_to_a_hull_sink() -> void:
	var sink := ContextSink.new()
	var ctx: Dictionary = DamageScript.context(
		Vector2(100.0, 0.0), 0.0, Vector2(100.0, -50.0), 0.0, &"kinetic"
	)
	DamageScript.apply(sink, 42.0, true, ctx)
	assert_eq(sink.calls, 1, "one hit reached the sink")
	assert_eq(sink.amount, 42.0, "the amount rode along")
	assert_true(sink.bypass, "the bypass flag rode along")
	assert_eq(sink.ctx.get(DamageScript.CTX_FAMILY), &"kinetic", "the family rode along")
	assert_true(
		is_equal_approx(float(sink.ctx.get(DamageScript.CTX_DIRECTION, 0.0)), -PI / 2.0),
		"an attacker on -Y is -PI/2 off a heading of 0, got %s"
		% sink.ctx.get(DamageScript.CTX_DIRECTION)
	)


func test_apply_still_lands_on_a_two_argument_sink() -> void:
	var sink := TwoArgSink.new()
	DamageScript.apply(sink, 17.5, false, {DamageScript.CTX_FAMILY: &"energy"})
	assert_eq(sink.calls, 1, "the two-argument form is called, not refused")
	assert_eq(sink.amount, 17.5, "its amount is the hit's")


func test_apply_reaches_a_player_state_through_its_own_method() -> void:
	var ctx: Dictionary = DamageScript.context(Vector2.ZERO, 0.0, Vector2(-40.0, 0.0), 0.0, &"missile")
	DamageScript.apply(_state, 90.0, false, ctx)
	assert_eq(_state.shield, SHIELD_MAX - 90.0, "PlayerState.damage took the hit")
	assert_true(
		is_equal_approx(absf(float(_state.last_damage_ctx().get(DamageScript.CTX_DIRECTION, 0.0))), PI),
		"the context's direction is recorded (a hit from astern reads -PI), got %s"
		% _state.last_damage_ctx().get(DamageScript.CTX_DIRECTION)
	)


func test_apply_ignores_sinks_that_cannot_be_hit() -> void:
	var rock: RigidBody2D = _keep(RigidBody2D.new()) as RigidBody2D
	DamageScript.apply(rock, 50.0, false, {})
	DamageScript.apply(null, 50.0, false, {})
	DamageScript.apply("not a sink", 50.0, false, {})
	DamageScript.apply([1, 2, 3], 50.0, false, {})
	assert_true(
		rock.linear_velocity.is_zero_approx(),
		"a body with no hit method takes neither damage nor an impulse from the damage door"
	)
	DamageScript.apply(_state, 0.0, false, {})
	DamageScript.apply(_state, -5.0, false, {})
	assert_eq(_state.shield, SHIELD_MAX, "a non-positive amount is not a hit")


## ---------------------------------------------------------------------------
## The item-5 context itself
## ---------------------------------------------------------------------------


func test_bearing_reads_the_four_arcs_slice_three_will_use() -> void:
	var origin := Vector2(100.0, 100.0)
	assert_true(
		is_equal_approx(DamageScript.bearing(origin, 0.0, origin + Vector2(10.0, 0.0)), 0.0),
		"a hit from straight ahead is 0"
	)
	assert_true(
		is_equal_approx(DamageScript.bearing(origin, 0.0, origin + Vector2(0.0, 10.0)), PI / 2.0),
		"a hit from the starboard flank is +PI/2"
	)
	assert_true(
		is_equal_approx(DamageScript.bearing(origin, 0.0, origin + Vector2(0.0, -10.0)), -PI / 2.0),
		"a hit from the port flank is -PI/2"
	)
	assert_true(
		is_equal_approx(absf(DamageScript.bearing(origin, 0.0, origin + Vector2(-10.0, 0.0))), PI),
		"a hit from astern is +/-PI"
	)
	## The heading moves with the hull: the same attacker becomes a stern hit once the
	## ship has turned to face away from it.
	assert_true(
		is_equal_approx(absf(DamageScript.bearing(origin, PI, origin + Vector2(10.0, 0.0))), PI),
		"a heading of PI turns the same attacker into a stern hit"
	)
	## Wrapped, not accumulating: 10 full turns report the same arc as none.
	var turned := DamageScript.bearing(origin, 0.0, origin + Vector2(10.0, 10.0))
	assert_true(
		is_equal_approx(turned, DamageScript.bearing(origin, TAU * 10.0, origin + Vector2(10.0, 10.0))),
		"the bearing wraps over a turn count"
	)


func test_context_carries_the_three_item5_keys() -> void:
	var ctx: Dictionary = DamageScript.context(Vector2(10.0, 10.0), 0.0, Vector2(30.0, 10.0), 512.0)
	assert_true(ctx.has(DamageScript.CTX_DIRECTION), "direction is present")
	assert_true(ctx.has(DamageScript.CTX_IMPULSE), "impulse is present")
	assert_true(ctx.has(DamageScript.CTX_FAMILY), "family is present")
	assert_eq(ctx.get(DamageScript.CTX_IMPULSE), 512.0, "the caller's own impulse is recorded")
	assert_eq(ctx.get(DamageScript.CTX_FAMILY), &"", "an unnamed family is empty, not guessed")
	assert_eq(ctx.size(), 3, "three keys, no more")


## A call site that pushed the target itself has the vector it applied; the pipeline
## records whichever figure it is handed rather than making one shape wrong.
func test_context_records_a_vector_impulse_verbatim() -> void:
	var push := Vector2(120.0, -40.0)
	var ctx: Dictionary = DamageScript.context(Vector2.ZERO, 0.0, Vector2(50.0, 0.0), push, &"kinetic")
	assert_eq(ctx.get(DamageScript.CTX_IMPULSE), push, "the vector survives the round trip")


## ---------------------------------------------------------------------------
## The item 6-8 push seams (all three through impact.gd)
## ---------------------------------------------------------------------------


func test_ram_charges_impact_collision_damage_and_records_the_bearing() -> void:
	var hull := _hull(110.0)
	hull.global_position = Vector2.ZERO
	var peer := Vector2(-64.0, 64.0)
	var expected := ImpactScript.collision_damage(110.0, 560.0, 450.0)
	assert_true(expected > 0.0, "the fixture is above COLLISION_MIN_DV 40")
	var charged := DamageScript.ram(hull, peer, 110.0, 560.0, 450.0)
	assert_eq(charged, expected, "the ram charged impact.gd's own reduced-mass figure")
	assert_eq(hull.hits, 1, "the hull took the hit")
	assert_eq(hull.amount, expected, "and the same amount")
	assert_false(hull.bypass, "a ram is shield-first (section 4.2 item 1)")
	assert_eq(hull.ctx.get(DamageScript.CTX_FAMILY), DamageScript.FAMILY_COLLISION, "the ram names its own family")
	assert_true(
		is_equal_approx(
			float(hull.ctx.get(DamageScript.CTX_DIRECTION, 0.0)),
			DamageScript.bearing(Vector2.ZERO, 0.0, peer)
		),
		"the peer's bearing is on the record"
	)
	assert_eq(hull.ctx.get(DamageScript.CTX_IMPULSE), 0.0, "the contact's push is the solver's, not the pipeline's")


func test_ram_is_free_below_the_collision_floor() -> void:
	var hull := _hull(110.0)
	var charged := DamageScript.ram(hull, Vector2(-10.0, 0.0), 110.0, 560.0, 39.0)
	assert_eq(charged, 0.0, "below COLLISION_MIN_DV 40 a contact is free")
	assert_eq(hull.hits, 0, "and the hull is not touched")


func test_knockback_pushes_the_pinned_energy_share() -> void:
	var hull := _hull(110.0)
	hull.global_position = Vector2.ZERO
	var energy := ImpactScript.knockback(1000.0, 1.0)
	assert_true(energy > 0.0, "the fixture carries kinetic energy")
	var expected := sqrt(2.0 * energy * 110.0)
	var impulse := DamageScript.knockback(hull, 1.0, 1000.0, Vector2(-10.0, 0.0))
	assert_true(is_equal_approx(impulse, expected), "the impulse is sqrt(2 * E * M), got %s" % impulse)
	assert_eq(hull.impulses.size(), 1, "the hull's own push seam took it")
	assert_true(
		is_equal_approx(hull.impulses[0].length(), expected),
		"the seam's momentum is the same figure, got %s" % hull.impulses[0].length()
	)
	assert_true(
		hull.impulses[0].x > 0.0 and is_zero_approx(hull.impulses[0].y),
		"and it travels away from the impact point, got %s" % hull.impulses[0]
	)


func test_knockback_needs_something_to_push() -> void:
	var bare: Node2D = _keep(Node2D.new()) as Node2D
	assert_eq(DamageScript.knockback(bare, 1.0, 1000.0, Vector2(-10.0, 0.0)), 0.0,
		"a target with no body and no push seam takes no impulse")
	var hull := _hull(110.0)
	assert_eq(DamageScript.knockback(hull, 1.0, 0.0, Vector2(-10.0, 0.0)), 0.0,
		"a shot with no remaining speed transfers no energy")
	assert_eq(hull.impulses.size(), 0, "nothing was pushed")


func test_detonate_charges_the_hulls_and_pushes_the_bodies() -> void:
	var epicenter := Vector2.ZERO
	var hull := _hull(110.0)
	hull.global_position = Vector2(30.0, 40.0)
	var rock: RigidBody2D = _keep(RigidBody2D.new()) as RigidBody2D
	var charged := DamageScript.detonate(epicenter, 180.0, true, [hull, rock], &"missile")
	assert_eq(charged, 1, "the hull is charged, the rock is not (a blast pushes rocks, it does not chip them)")
	assert_eq(hull.hits, 1, "the hull took the blast")
	assert_eq(hull.amount, 180.0, "a detonation's damage is flat across the blast")
	assert_true(hull.bypass, "the detonating family's own shield rule is passed through")
	assert_eq(hull.ctx.get(DamageScript.CTX_FAMILY), &"missile", "the weapon's family is on the record")
	assert_true(
		is_equal_approx(
			float(hull.ctx.get(DamageScript.CTX_IMPULSE, 0.0)),
			ImpactScript.explosion_impulse(hull.global_position.distance_to(epicenter))
		),
		"the recorded impulse is impact.gd's P0/(1+d^2), got %s" % hull.ctx.get(DamageScript.CTX_IMPULSE)
	)


## ---------------------------------------------------------------------------
## The absorb rule and the shield rate (section 4.2 items 1 and 2)
## ---------------------------------------------------------------------------


func test_a_live_shield_absorbs_whole_and_nothing_carries_over() -> void:
	_state.set_shield(100.0)
	DamageScript.apply(_state, 250.0, false, {})
	assert_eq(_state.shield, 0.0, "the shield is drained by the whole hit")
	assert_eq(_state.hull, HULL_MAX, "and no carry-over reaches the hull")


func test_a_bypassing_hit_lands_on_the_hull() -> void:
	DamageScript.apply(_state, 250.0, true, {})
	assert_eq(_state.hull, HULL_MAX - 250.0, "kinetics/missiles land on the hull")
	assert_eq(_state.shield, SHIELD_MAX, "and leave the shield alone")


func test_a_default_player_state_regenerates_at_the_section_42_base() -> void:
	assert_eq(_state.shield_regen, BASE_SHIELD_REGEN, "PlayerState carries the base 2/s by default")


func test_the_standard_fit_resolves_the_base_plus_the_module() -> void:
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	assert_eq(stats.shield_regen, BASE_SHIELD_REGEN + S_LIGHT_REGEN_ADD,
		"the standard fit's s_light adds its 4/s to the 2/s base")
	var heavier: ShipStats = ShipFitScript.resolve(&"ship_vanguard", {
		&"engine": &"e_std", &"power": &"p_std", &"weapons": [], &"shields": [&"s_ion"],
		&"armour": [], &"computers": [], &"boosters": [], &"utility": [],
	})
	assert_eq(heavier.shield_regen, BASE_SHIELD_REGEN + 9.0, "s_ion resolves to 11/s")


func test_regen_waits_out_the_four_second_quiet_window() -> void:
	_state.set_shield(100.0)
	DamageScript.regen(_state, 1.0, 3.9)
	assert_eq(_state.shield, 100.0, "inside the window nothing regenerates")
	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET)
	assert_eq(_state.shield, 100.0 + BASE_SHIELD_REGEN,
		"at REGEN_QUIET 4 s one second of base regen lands")


func test_regen_spends_the_states_own_rate() -> void:
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	_state.shield_regen = stats.shield_regen
	_state.set_shield(100.0)
	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET)
	assert_eq(_state.shield, 100.0 + stats.shield_regen,
		"a fitted s_light regenerates 6/s, got %s" % (_state.shield - 100.0))


func test_regen_stops_at_the_ceiling_and_ignores_a_dead_state() -> void:
	_state.set_shield(SHIELD_MAX - 1.0)
	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET)
	assert_eq(_state.shield, SHIELD_MAX, "set_shield clamps at the ceiling")
	var full := _state.shield
	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET)
	assert_eq(_state.shield, full, "a full shield is not re-announced")
	DamageScript.regen(null, 1.0, DamageScript.REGEN_QUIET)
	DamageScript.regen(_state, 0.0, DamageScript.REGEN_QUIET)
	_state.shield_regen = 0.0
	_state.set_shield(50.0)
	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET)
	assert_eq(_state.shield, 50.0, "a zero rate regenerates nothing")


## Fresh shield each frame: the regeneration announces itself on `shield_changed`, so a
## frame-stepped run is measurable through the signal count as well as the pool.
func test_regen_frames_add_up_to_the_same_rate() -> void:
	_state.shield_regen = BASE_SHIELD_REGEN + S_LIGHT_REGEN_ADD
	_state.set_shield(100.0)
	for _frame in FRAMES_PER_SECOND:
		DamageScript.regen(_state, 1.0 / float(FRAMES_PER_SECOND), DamageScript.REGEN_QUIET)
	assert_true(
		is_equal_approx(_state.shield, 100.0 + _state.shield_regen),
		"60 frames of 1/60 s add one second of the rate, got %s" % (_state.shield - 100.0)
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## A hull whose body carries the section 13 class mass, so the impulse maths has the same
## mass a real Cutter would hand it.
func _hull(mass: float) -> Hull:
	var hull: Hull = _keep(Hull.new()) as Hull
	var body: RigidBody2D = _keep(RigidBody2D.new()) as RigidBody2D
	body.mass = mass
	hull.body = body
	return hull


## Register a node for this suite's own `teardown` to free. The headless runner calls
## `setup`/`teardown` per test but not the base class's `_free_tracked`, so `track()`
## would leave every body and hull in the gate log as an RID/instance leak.
func _keep(node: Node) -> Node:
	_nodes.append(node)
	return node
