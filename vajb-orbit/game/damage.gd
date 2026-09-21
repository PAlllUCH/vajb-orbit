class_name Damage
extends RefCounted
## The combat damage pipeline of ENGINE_SPEC section 4.2: the absorb rule and the shield
## regeneration of item 1/2, the item-5 hit context (`direction` / `impulse` / `family`)
## and the item 6-8 push physics, in one file. Nothing here re-derives a push formula --
## `impact.gd` owns that arithmetic (slice 0) and this class only calls it.
##
## The two pinned doors:
##   `apply(target, amount, bypass_shield, ctx)` -- one hit, charged through the target's
##     own `take_damage`, with the item-5 context riding along.
##   `regen(state, delta, quiet_since)` -- one frame of shield regeneration, called by
##     the pool's owner from its `_physics_process`.
##
## The three section 4.2 push seams -- `ram` (item 6), `knockback` (item 7) and
## `detonate` (item 8) -- call `impact.gd` for the arithmetic and hand the result to the
## target's own push seam (`PlayerShip.apply_impulse`, or the rigid body itself when the
## body carries no ship), so collision, knockback and explosion impulses keep one owner.
##
## Feedback is not this file's business: section 4.2 item 4 puts the shield flare / hull
## sparks and the reticle's hit marker on the HUD, and v1 ships no floating numbers.
##
## Contract: ENGINE_SPEC section 4.2 (items 1-8) and section 13 (the shield-regen and
## push-physics rows); CONTRACTS sections 3, 4 and 8.1; the slice-2 brief's pinned
## interface item 4.

## The push-physics arithmetic (section 4.2 items 6-8), reached through a preload rather
## than through its global class name: the house pattern for a cross-file reach in this
## project, and the one that cannot depend on the editor having rescanned the class table
## (`player_ship.gd` reaches `impact.gd` the same way). Its own constants --
## COLLISION_MIN_DV, EXPLOSION_WINDOW and the rest -- are read off the class, never
## restated here.
const IMPACT := preload("res://game/impact.gd")

## ENGINE_SPEC section 4.2 item 2 / section 13 "Shield regen": regeneration resumes this
## long after the last incoming damage. The rate itself is not this file's constant --
## `ShipFit` resolves it into `ShipStats.shield_regen` and `PlayerState` carries the
## resolved figure (base 2/s plus the fitted S module's `regen_add`), exactly as the
## reactor's `energy_regen` works.
const REGEN_QUIET := 4.0

## Section 4.2 item 5's context keys, named once so no call site spells a string. A call
## site may add keys of its own (the pipeline passes the dictionary through untouched).
const CTX_DIRECTION: StringName = &"direction"
const CTX_IMPULSE: StringName = &"impulse"
const CTX_FAMILY: StringName = &"family"

## The two `family` values the pipeline itself owns. Section 4.1's family table (owned by
## `weapons.gd`) names the *weapon* families, and neither a body-body ram nor a blast has
## a weapon behind it, so the pipeline names its own two sources rather than borrowing a
## weapon family the hit did not come from. Slice 3's quadrants read `direction` only.
const FAMILY_COLLISION: StringName = &"collision"
const FAMILY_EXPLOSION: StringName = &"explosion"

const TAKE_DAMAGE: StringName = &"take_damage"

## The sink method `PlayerState` publishes its absorb rule under. The pinned interface
## is `take_damage`; a hull forwards to this one, and the pipeline accepts either so a
## `PlayerState` handed straight to it (a probe, a unit test, a caller with no ship node)
## takes the hit instead of silently dropping it. It is a fallback, not a second
## interface: `take_damage` always wins when a target has both.
const SINK_DAMAGE: StringName = &"damage"

const APPLY_IMPULSE: StringName = &"apply_impulse"
const IMPACT_BODY: StringName = &"impact_body"

## How many parameters a sink's hit method must declare to be handed the item-5 context
## (amount, bypass_shield, ctx).
const CONTEXT_ARGS := 3

## Which sinks take the third argument, keyed by their script and then by the method.
## The wave pins two forms -- `take_damage(amount, bypass_shield, ctx)` carries the context
## and `take_damage(amount, bypass_shield)` does not -- so the pipeline asks its target
## instead of forcing one form on the other. One introspection per script, then a
## dictionary lookup per hit: a hull takes hits every frame and the method list is long.
static var _context_sinks: Dictionary = {}


## ENGINE_SPEC section 4.2 items 1 and 5: one hit. The target implements
## `take_damage(amount, bypass_shield, ctx)`; `PlayerShip` routes that into
## `PlayerState.damage`, which keeps the wave-1 verified shield-first absorb with no
## carry-over (item 1: a live shield takes the whole hit and the hull is untouched), and
## `NpcShip` mirrors it. A sink whose hit method declares only the two leading parameters
## is called the two-argument way, so both pinned forms work.
##
## `ctx` is the item-5 context -- `direction` (the bearing of the hit relative to the
## target's heading, see `bearing`), `impulse` (a force the caller has *already* applied)
## and `family` -- and it is passed through untouched: the pipeline applies nothing here,
## it only delivers the hit and its context. A null target, a target with no hit method
## and a non-positive amount are silent no-ops.
static func apply(target, amount: float, bypass_shield := false, ctx := {}) -> void:
	if amount <= 0.0 or not (target is Object):
		return
	var sink := target as Object
	if not is_instance_valid(sink):
		return
	var method := _hit_method(sink)
	if method.is_empty():
		return
	if _wants_context(sink, method):
		sink.call(method, amount, bypass_shield, ctx)
		return
	sink.call(method, amount, bypass_shield)


## ENGINE_SPEC section 4.2 item 2 / section 13: one frame of the shield's regeneration,
## at the rate the state carries (`PlayerState.shield_regen`, the base 2/s plus the
## fitted S module's `regen_add`), and only after `REGEN_QUIET` 4 s without incoming
## damage. `quiet_since` is the owner's own quiet timer -- seconds since the last hit
## that landed on this state -- so the timer keeps its single owner and this helper stays
## a pure frame step.
##
## A full shield, a zero rate and a still-angry hull are all no-ops, and the pool only
## ever moves up: `set_shield` clamps and announces the change on the existing
## `shield_changed` signal, so the HUD and the ship's warp-damage gate see regen exactly
## as they saw it before this call existed.
static func regen(state: PlayerState, delta: float, quiet_since: float) -> void:
	if state == null or delta <= 0.0:
		return
	if quiet_since < REGEN_QUIET:
		return
	if state.shield_regen <= 0.0 or state.shield >= state.shield_max:
		return
	state.set_shield(state.shield + state.shield_regen * delta)


## Section 4.2 item 5's `direction`: the bearing of the hit's origin relative to the
## target's heading, in radians over [-PI, PI] -- 0.0 dead ahead, +PI/2 off the target's
## right flank, +/-PI astern. Godot's own angle convention (0 = +X, positive clockwise on
## screen) with the heading subtracted, so quadrant reading is a comparison and not a
## trigonometry exercise.
##
## The wrap is the point: slice 3's quadrants (section 4.5, the prow/stern/port/starboard
## arcs and the 160 degree stern vulnerability) compare this one signed number, so it may
## not grow with the hull's turn count. The range is half-open at +PI, so a hit dead
## astern reads -PI (the closed end); a quadrant comparison reads `absf(direction)`.
static func bearing(target_position: Vector2, heading: float, source_position: Vector2) -> float:
	return wrapf((source_position - target_position).angle() - heading, -PI, PI)


## The item-5 context of one hit, built here so no call site invents a key or a sign.
## `impulse` is momentum the caller has *already* applied (section 4.2 item 5) -- recorded,
## never applied by this call -- and it is passed through as it arrives: the pipeline's own
## helpers hand it the figure `Impact` returns (impulse-units, a float), while a weapon
## call site that pushed the target itself has the vector it applied and may record that
## (the wave's weapons/projectile delivery does). Slice 3 reads `direction` only, so the
## key's shape is informational and this door does not force one on the other.
##
## `family` is the weapon family from section 4.1's table (`weapons.gd` owns those names)
## or one of this file's two pipeline families.
static func context(
	target_position: Vector2,
	heading: float,
	source_position: Vector2,
	impulse: Variant = 0.0,
	family: StringName = &""
) -> Dictionary:
	return {
		CTX_DIRECTION: bearing(target_position, heading, source_position),
		CTX_IMPULSE: impulse,
		CTX_FAMILY: family,
	}


## Section 4.2 item 6, ruling 15: one side's half of a body-body impact. The damage is
## `impact.gd`'s reduced-mass form (never restated here) and the contact's own geometry
## supplies the context -- `direction` is the peer's bearing relative to this hull's
## heading -- so a hit's quarter is on the record from the first ram.
##
## The charge is shield-first (`bypass_shield` false), which is the shipped contact
## rule: slice 0's hull monitor charges the player through `PlayerState.damage` and the
## shield absorbs a ram like any other hit (item 1). `impulse` is recorded as 0.0 because
## the contact's push is the solver's own -- two bodies' velocities are resolved by the
## physics step -- so the pipeline has no momentum of its own to report. The peer's half
## is the caller's business (`PlayerShip` offers it to a peer that carries
## `apply_collision_damage`).
##
## Returns the damage charged: 0.0 below `Impact.COLLISION_MIN_DV`, on a null target and
## on a target that cannot take a hit.
static func ram(
	target: Node2D,
	peer_position: Vector2,
	mass_a: float,
	mass_b: float,
	closing_speed: float,
	family: StringName = FAMILY_COLLISION
) -> float:
	if target == null:
		return 0.0
	var amount := IMPACT.collision_damage(mass_a, mass_b, closing_speed)
	if amount <= 0.0:
		return 0.0
	apply(
		target,
		amount,
		false,
		context(target.global_position, target.global_rotation, peer_position, 0.0, family)
	)
	return amount


## Section 4.2 item 7, ruling 16: a hit transfers `KNOCKBACK_FRACTION` of the
## projectile's remaining kinetic energy to the target along the impact line. The energy
## is `impact.gd`'s (`Impact.knockback`); the impulse that carries it into a hull of mass
## M is `sqrt(2 * E * M)` (CONTRACTS section 8.1), which needs the target's own mass and
## therefore lives at the hit site rather than inside `Impact`.
##
## The push leaves through the target's own seam -- `PlayerShip.apply_impulse` when the
## target publishes one, else the rigid body itself -- directed away from `origin` (the
## impact point), in one step like every other impulse in the pipeline. Returns the
## magnitude applied (0.0 for a massless target, a target with nothing to push, or a hit
## with no remaining speed); the caller records that figure as the `impulse` key of the
## context it hands to `apply`:
##
##     var impulse := Damage.knockback(ship, projectile_mass, speed, hit_point)
##     Damage.apply(ship, amount, bypass, Damage.context(
##         ship.global_position, ship.global_rotation, hit_point, impulse, family))
static func knockback(
	target: Node2D,
	projectile_mass: float,
	remaining_speed: float,
	origin: Vector2
) -> float:
	if target == null:
		return 0.0
	var body := _push_body(target)
	if body == null:
		return 0.0
	var mass := body.mass
	var energy := IMPACT.knockback(remaining_speed, projectile_mass)
	if energy <= 0.0 or mass <= 0.0:
		return 0.0
	var impulse := sqrt(2.0 * energy * mass)
	if impulse <= 0.0:
		return 0.0
	var outward := _away(target.global_position, origin)
	if outward.is_zero_approx():
		return 0.0
	_push(target, body, outward * impulse)
	return impulse


## Section 4.2 item 8, ruling 16: one detonation, over `bodies` -- the rigid bodies and
## hulls the blast reaches. Finding them is the caller's business (the curve itself is
## the range, and `Impact` owns no scene query). Every entry is pushed with
## `Impact.apply_shockwave`, the blast front sliced across `Impact.EXPLOSION_WINDOW`, and
## every entry that can take a hit is charged `damage` with its own context: `direction`
## is the epicentre's bearing relative to that hull's heading and `impulse` is the
## momentum the shockwave just applied, `Impact.explosion_impulse(distance)` -- "a force
## already applied by the caller", recorded rather than applied twice.
##
## `bypass_shield` is the detonating family's own rule (section 4.1: a rocket's or a
## mine's blast lands on the hull) and the caller reads it off its weapon table; the
## pipeline does not decide it. A body with no `take_damage` -- a rock -- is pushed and
## not chipped: section 4.2 item 8 gives the blast an impulse, and section 6's chip rate
## is gun work.
##
## Returns the number of entries charged with damage (pushed entries are not counted).
static func detonate(
	epicenter: Vector2,
	damage: float,
	bypass_shield: bool,
	bodies: Array,
	family: StringName = FAMILY_EXPLOSION
) -> int:
	var charged := 0
	for entry in bodies:
		if not (entry is Object) or not is_instance_valid(entry):
			continue
		var node := entry as Node2D
		var body := _push_body(entry)
		if body != null:
			IMPACT.apply_shockwave(epicenter, body, IMPACT.EXPLOSION_WINDOW)
		if node == null or damage <= 0.0 or not _can_take_damage(entry):
			continue
		var ctx := context(
			node.global_position,
			node.global_rotation,
			epicenter,
			IMPACT.explosion_impulse(node.global_position.distance_to(epicenter)),
			family
		)
		apply(entry, damage, bypass_shield, ctx)
		charged += 1
	return charged


## The body an impulse lands on: a hull's own rigid body through the pinned
## `impact_body()` seam, or the entry itself when it is already a rigid body (a rock).
## Null for an entry with neither, which is the "nothing to push" case.
static func _push_body(entry: Variant) -> RigidBody2D:
	if not (entry is Object) or not is_instance_valid(entry):
		return null
	var body := entry as RigidBody2D
	if body != null:
		return body
	var owner := entry as Object
	if not owner.has_method(IMPACT_BODY):
		return null
	var returned: Variant = owner.call(IMPACT_BODY)
	if not (returned is RigidBody2D):
		return null
	return returned as RigidBody2D


## One impulse to one target, through the seam it publishes: `apply_impulse` (the pinned
## `PlayerShip` push seams) when it has one, else the body directly. A hull's seam exists
## so the ship can keep its own books, not to gate the physics.
static func _push(target: Variant, body: RigidBody2D, impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return
	if target is Object and (target as Object).has_method(APPLY_IMPULSE):
		(target as Object).call(APPLY_IMPULSE, impulse)
		return
	if body != null and is_instance_valid(body):
		body.apply_central_impulse(impulse)


## The outward direction of a push: away from the impact point. A target sitting exactly
## on it has no outward direction, and the caller drops that impulse rather than picking a
## direction for it.
static func _away(target_position: Vector2, origin: Vector2) -> Vector2:
	var offset := target_position - origin
	if offset.is_zero_approx():
		return Vector2.ZERO
	return offset.normalized()


static func _can_take_damage(target: Variant) -> bool:
	if not (target is Object):
		return false
	return not _hit_method(target as Object).is_empty()


## The method a hit lands on: the pinned `take_damage` when the sink publishes one, else
## `PlayerState`'s own `damage`. Empty for a sink with neither (a rock, a peer that only
## takes `apply_collision_damage`), which is the no-op case.
static func _hit_method(sink: Object) -> StringName:
	if sink.has_method(TAKE_DAMAGE):
		return TAKE_DAMAGE
	if sink.has_method(SINK_DAMAGE):
		return SINK_DAMAGE
	return &""


## Whether a sink wants the item-5 context: the number of parameters its hit method
## declares decides, and the answer is cached per script and method (the introspection
## walks the whole method list, and a hull takes hits every frame).
static func _wants_context(sink: Object, method: StringName) -> bool:
	var script: Script = sink.get_script()
	var per_method: Dictionary = {}
	if script != null:
		var cached: Variant = _context_sinks.get(script)
		if cached is Dictionary:
			per_method = cached
			if per_method.has(method):
				return bool(per_method[method])
	var wanted := _declared_args(sink, method) >= CONTEXT_ARGS
	if script != null:
		per_method[method] = wanted
		_context_sinks[script] = per_method
	return wanted


## How many parameters a sink's method of that name declares. The widest declaration wins,
## so a class that lists an override and its base's method is read as the override's.
static func _declared_args(sink: Object, method: StringName) -> int:
	var wanted := 0
	for entry: Dictionary in sink.get_method_list():
		if entry.get("name", "") != String(method):
			continue
		var args: Variant = entry.get("args", [])
		if args is Array:
			wanted = maxi(wanted, (args as Array).size())
	return wanted
