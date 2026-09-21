class_name Projectile
extends Area2D
## One shot in flight: ENGINE_SPEC section 4.1's four travelling families (bolt,
## slug, rocket, mine) plus section 4.2 items 7/8's push physics at the hit site.
##
## Built entirely in code by `configure(config)` (the slice-2 brief's pinned key
## set), so there is no scene file and no art: the visual pass is slice 2.5's and
## W3's (FX_SPEC section 7), and nothing here touches `assets/`.
##
## Contract: ENGINE_SPEC sections 4.1 (families, travel, shield rule, "kinetics
## fizzle at max range", "rockets require a lock to home, without a lock they
## dumb-fire", "mines arm after 2 s, proximity trigger 60 u", "rockets are
## destructible, any weapon hit kills them"), 4.2 items 7-8 (recoil is the
## shooter's half and lives on the hull; knockback and the blast wave are the hit
## site's), 6 (guns on rocks: 10 % of the DPS-equivalent rate, depletion only,
## ruling 17), 4.6 (a flare decoy retargets a homing rocket: `retarget` is this
## file's half), 13 (ranges, speeds, rocket/mine rows); docs/CONTRACTS.md sections
## 4/5/8.1 (the `Impact` helpers, the `&"npc_ship"` group); the slice-2 brief's
## pinned interface item 3.
##
## Damage leaves through the pinned target seam - `take_damage(amount,
## bypass_shield, ctx)` when the target takes the context, else
## `take_damage(amount, bypass_shield)`, else `PlayerState.damage(amount,
## bypass_shield, ctx)` - so a hit lands on whatever the pipeline's owners ship
## (W2's `Damage.apply` calls the same method on the same targets).
##
## Layers. Rocks are layer 1 (`Asteroid.COLLISION_LAYER`), the player hull is
## layer 2 (`player_ship.tscn`'s `HullBody`); projectiles own bit 3 so a shot can
## find a rocket without seeing rocks or hulls. A hull on another layer is
## invisible to shots, so slice-2's NPC hulls must share layer 2 (reported).

signal detonated(pos: Vector2, damage: float, bypass_shield: bool)

const ImpactScript := preload("res://game/impact.gd")

const KIND_BOLT: StringName = &"bolt"
const KIND_SLUG: StringName = &"slug"
const KIND_ROCKET: StringName = &"rocket"
const KIND_MINE: StringName = &"mine"

## Section 4.2 item 5's `family` key, derived from the kind rather than passed in:
## the family table's single owner is `weapons.gd`, and it configures a kind.
const KIND_FAMILIES: Dictionary = {
	&"bolt": &"kinetic",
	&"slug": &"kinetic",
	&"rocket": &"missile",
	&"mine": &"deployable",
}

## A rocket is the warhead a weapon can shoot down (section 4.1); a bolt, slug and
## mine are not named as destructible, so only this kind answers true.
const DESTRUCTIBLE_KINDS: Array[StringName] = [&"rocket"]

const ROCK_GROUP: StringName = &"asteroid"
const PLAYER_GROUP: StringName = &"player_ship"
const NPC_GROUP: StringName = &"npc_ship"
const PROJECTILE_GROUP: StringName = &"projectile"

const PROJECTILE_LAYER := 4
const ROCK_LAYER_MASK := 1
const HULL_LAYER_MASK := 2
const TARGET_MASK := ROCK_LAYER_MASK | HULL_LAYER_MASK

## The shape's own radius: how close a shot must pass a body to touch it, and how
## close a shot must come to a decoy to detonate on it. No spec value exists for a
## projectile's cross-section, so this is a detection radius, reported as such;
## the render size is slice 2.5's and does not read it.
const HIT_RADIUS := 4.0

## Section 4.2 item 7's terms: the shooter's recoil is `mass x muzzle_speed` and a
## hit's knockback is 40 % of `0.5 x mass x speed^2`. Section 13 pins neither a
## projectile's mass nor any of the six weapons' projectile weight, so every shot
## carries this mass and the term is a one-line tunable (reported).
const DEFAULT_MASS := 1.0

const SHAPE_NODE: StringName = &"Shape"

## Blast range: `I(d) = P0 / (1 + d^2)` is its own range (impact.gd's reading of
## section 4.2 item 8), so the query radius is where the impulse falls to one
## unit-impulse - about 63 u, the floor below which a push is not worth applying.
const MIN_SHOCKWAVE_IMPULSE := 1.0
const MAX_SHOCKWAVE_BODIES := 32

var kind: StringName = KIND_BOLT
var speed := 0.0
var damage := 0.0
var bypass_shield := false
var homing := false
var turn_rate := 0.0
var mass := DEFAULT_MASS
## Flight limit: the shot fizzles once it has travelled this far (0 = no limit).
var max_range := 0.0
## The mine's two rows: arm after `arm_time` seconds, trigger inside
## `trigger_radius` of a hull's centre.
var arm_time := 0.0
var trigger_radius := 0.0
## Guns on rocks (section 6, ruling 17): the fraction of a landed hit's damage that
## becomes depletion work. The rate itself is `weapons.gd`'s (the family table's
## owner) and arrives in `configure`.
var chip := 0.0

var _velocity := Vector2.ZERO
var _lock_target: Node2D = null
var _decoy: Node2D = null
var _source: Node2D = null
var _shape: CollisionShape2D = null
var _travelled := 0.0
var _armed := false
var _arm_clock := 0.0
var _spent := false

## Whether a target's `take_damage` takes section 4.2 item 5's context, cached per
## target class (the answer is a property of the script, not the instance).
var _ctx_arity: Dictionary = {}


## The pinned configuration entry point. Every pinned key is read here - `kind`,
## `speed`, `damage`, `bypass_shield`, `homing`, `target`, `turn_rate`, `source` -
## plus five additive keys the projectile cannot derive on its own: `direction`
## (the muzzle's aim, which a cursor-only design would put in the weapon and a
## second caller such as an NPC could not reproduce), `range` (the fizzle
## distance), `arm`/`trigger` (the mine rows), `mass` (section 4.2 item 7's term)
## and `chip` (section 6's 10 %). Keys are normalized to `StringName`, so a caller
## passing plain strings still lands.
##
## Call order: `configure` first, then `add_child`, then the spawner's
## `global_position`. Both orders work (`_ready` only needs the shape, and the
## collision exceptions are applied again at the end of `configure` when the node
## is already in the tree).
func configure(config: Dictionary) -> void:
	var cfg := {}
	for key: Variant in config:
		cfg[StringName(key)] = config[key]
	kind = StringName(cfg.get(&"kind", KIND_BOLT))
	speed = maxf(_number(cfg.get(&"speed")), 0.0)
	damage = maxf(_number(cfg.get(&"damage")), 0.0)
	bypass_shield = bool(cfg.get(&"bypass_shield", false))
	homing = bool(cfg.get(&"homing", false))
	turn_rate = maxf(_number(cfg.get(&"turn_rate")), 0.0)
	mass = maxf(_number(cfg.get(&"mass"), DEFAULT_MASS), 0.0)
	max_range = maxf(_number(cfg.get(&"range")), 0.0)
	arm_time = maxf(_number(cfg.get(&"arm")), 0.0)
	trigger_radius = maxf(_number(cfg.get(&"trigger")), 0.0)
	chip = clampf(_number(cfg.get(&"chip")), 0.0, 1.0)
	var aim: Variant = cfg.get(&"direction")
	_velocity = Vector2.ZERO
	if aim is Vector2 and not (aim as Vector2).is_zero_approx():
		_velocity = (aim as Vector2).normalized() * speed
	var target: Variant = cfg.get(&"target")
	if target is Node2D:
		_lock_target = target as Node2D
	var source: Variant = cfg.get(&"source")
	if source is Node2D:
		_source = source as Node2D
	_sync_shape()


func _ready() -> void:
	add_to_group(PROJECTILE_GROUP)
	_sync_shape()


## Flight. A travelling shot sweeps for what is in front of it this frame (a ray,
## not an overlap event, so the impact point is exact and the blast lands where the
## hull was hit); a mine sits still and watches for a hull.
func _physics_process(delta: float) -> void:
	if _spent or delta <= 0.0:
		return
	if kind == KIND_MINE:
		_step_mine(delta)
		return
	_step_flight(delta)


## --- The public seams the weapons and the countermeasures read -------------


func family() -> StringName:
	return StringName(KIND_FAMILIES.get(kind, &"kinetic"))


## Section 4.1: "destroyed in flight (any weapon hit kills it)". Only a rocket.
func is_destructible() -> bool:
	return DESTRUCTIBLE_KINDS.has(kind)


func hit_radius() -> float:
	return HIT_RADIUS


func damage_amount() -> float:
	return damage


func bypasses_shield() -> bool:
	return bypass_shield


func lock_target() -> Node2D:
	return _lock_target


## The decoy a flare pulled this shot onto (section 4.6), null when none is live.
func decoy() -> Node2D:
	return _decoy


## The live flight vector: the shot's speed and bearing, which a probe measures for
## section 4.1's travel rows and a trail renderer reads for its orientation.
func velocity() -> Vector2:
	return _velocity


## Who fired the shot. A beam's segment test reads it so it cannot shoot down its
## own rockets.
func source() -> Node2D:
	return _source


## Section 4.6's half that belongs here: a live flare overrides the lock target,
## so the shot keeps flying (and keeps turning) at the decoy instead. Harmless on
## a non-seeker: a mine and a ballistic shot are not homing, so the override is
## stored and never read.
func retarget(decoy: Node2D) -> void:
	if decoy == null or not is_instance_valid(decoy):
		return
	_decoy = decoy


## A weapon hit on a destructible shot (section 4.1). No detonation: the warhead is
## destroyed, not fired.
func fizzle() -> void:
	_consume()


## The shot leaves the world: it fizzled at its range, struck a body, or was shot
## down. One door, so `_spent` can never be left behind.
func _consume() -> void:
	if _spent:
		return
	_spent = true
	queue_free()


## --- Flight ---------------------------------------------------------------


func _step_flight(delta: float) -> void:
	_drive(delta)
	if _velocity.is_zero_approx():
		return
	var from := global_position
	var to := from + _velocity * delta
	var hit := _nearest(from, to)
	if hit.is_empty():
		global_position = to
		_travelled += from.distance_to(to)
		if _reaches_decoy(to, delta):
			return
		if max_range > 0.0 and _travelled >= max_range:
			fizzle()
		return
	_resolve(hit)


## Section 4.1: "homing, 2.2 rad/s turn" toward the lock target, and section 4.6:
## "a live flare overrides that target". Without either, the shot keeps its muzzle
## bearing - the dumb-fire the same row names.
func _drive(delta: float) -> void:
	if not homing or turn_rate <= 0.0 or speed <= 0.0:
		return
	var target := _homing_target()
	if target == null:
		return
	var bearing := (target.global_position - global_position).angle()
	var error := wrapf(bearing - _velocity.angle(), -PI, PI)
	var step := turn_rate * delta
	if absf(error) > step:
		_velocity = _velocity.rotated(signf(error) * step)
	else:
		_velocity = _velocity.rotated(error)
	if not is_zero_approx(_velocity.length()):
		_velocity = _velocity.normalized() * speed


## The decoy while it lives, else the lock target while it is valid (section 4.6:
## "a live flare overrides that target").
func _homing_target() -> Node2D:
	if _decoy != null and is_instance_valid(_decoy):
		return _decoy
	if _lock_target != null and is_instance_valid(_lock_target):
		return _lock_target
	return null


## A decoy is not a physics body, so the sweep cannot find it: a shot that has
## arrived at one detonates on the spot. "Arrived" is this frame's own travel, so
## no separate proximity radius is invented.
func _reaches_decoy(to: Vector2, delta: float) -> bool:
	var decoy := _homing_target()
	if decoy == null or decoy is CollisionObject2D:
		return false
	var reach := maxf(_velocity.length() * delta, HIT_RADIUS)
	if to.distance_to(decoy.global_position) > reach:
		return false
	_detonate(to)
	return true


## The nearest thing on this frame's segment: a body (rock or hull) or a
## destructible shot. Both queries exclude the shot itself and its source's bodies.
func _nearest(from: Vector2, to: Vector2) -> Dictionary:
	var best := _sweep_bodies(from, to)
	var shot := _sweep_projectiles(from, to)
	if shot.is_empty():
		return best
	if best.is_empty():
		return shot
	return shot if float(shot[&"distance"]) < float(best[&"distance"]) else best


func _sweep_bodies(from: Vector2, to: Vector2) -> Dictionary:
	var space := _space()
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, TARGET_MASK, _exclusions())
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return _hit_of(space.intersect_ray(query), from, false)


## A rocket dies to any weapon hit, so a shot looks for destructible shots on the
## same segment. A rocket does not shoot down rockets: the warhead's job is the
## hull it was aimed at.
func _sweep_projectiles(from: Vector2, to: Vector2) -> Dictionary:
	if is_destructible():
		return {}
	var space := _space()
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, PROJECTILE_LAYER, _exclusions())
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return {}
	if not _is_destructible_shot(hit.get("collider")):
		return {}
	return _hit_of(hit, from, true)


func _hit_of(hit: Dictionary, from: Vector2, is_shot: bool) -> Dictionary:
	if hit.is_empty():
		return {}
	var point: Vector2 = hit.get("position", from)
	return {
		&"point": point,
		&"collider": hit.get("collider"),
		&"distance": from.distance_to(point),
		&"projectile": is_shot,
	}


## Nothing survives the frame it lands: every kind either fizzles or detonates.
func _resolve(hit: Dictionary) -> void:
	var collider: Variant = hit[&"collider"]
	var point: Vector2 = hit[&"point"]
	if bool(hit[&"projectile"]):
		_shot_down(collider, point)
		return
	global_position = point
	if _is_rock(collider):
		_hit_rock(collider, point)
		return
	_hit_body(collider, point)


## A weapon hit on a rocket (section 4.1). The shooter's shot keeps flying - the
## kill is not a hit on the world.
func _shot_down(collider: Variant, point: Vector2) -> void:
	if not _is_destructible_shot(collider):
		return
	(collider as Node).call(&"fizzle")
	global_position = point + _velocity.normalized() * HIT_RADIUS


## Section 6, ruling 17: a gun's work on a rock is `10 %` of its DPS-equivalent
## rate, depletion only. The units `apply_work` returns are delivered pickups the
## mining laser owns; a chip never extracts, so the return is discarded.
func _hit_rock(rock: Node, point: Vector2) -> void:
	if chip > 0.0 and rock.has_method(&"apply_work"):
		rock.call(&"apply_work", damage * chip)
	if _is_explosive():
		_detonate(point)
		return
	_consume()


## Section 4.2 item 7: a hit transfers `KNOCKBACK_FRACTION` of the shot's remaining
## kinetic energy along the impact line. `Impact.knockback` gives the share; the
## impulse that carries it is `sqrt(2 x E x M)`, which this site can compute
## because it knows both the shot's mass and the target's.
func _hit_body(target: Node, point: Vector2) -> void:
	var share := ImpactScript.knockback(_velocity.length(), mass)
	var impulse := Vector2.ZERO
	var target_mass := _mass_of(target)
	if share > 0.0 and target_mass > 0.0:
		impulse = _velocity.normalized() * sqrt(2.0 * share * target_mass)
		_apply_push(target, impulse)
	_deliver(target, damage, bypass_shield, point, impulse)
	if _is_explosive():
		_detonate(point)
		return
	_consume()


## Section 4.1's trigger: a mine detonates on a hull inside its radius. The blast
## damages the hull that triggered it and pushes every rigid body in range with
## section 4.2 item 8's curve; the spec pins no blast-damage falloff, so none is
## invented.
func _step_mine(delta: float) -> void:
	if not _armed:
		_arm_clock += delta
		if _arm_clock >= arm_time:
			_armed = true
		return
	var victim := _mine_victim()
	if victim == null:
		return
	_detonate(global_position, victim)


## "Proximity trigger 60 u": a hull's centre inside the radius. Hulls are found by
## their groups (the player's and W3's `&"npc_ship"`), so the trigger does not
## depend on a collision layer; the ship that dropped the mine is not a trigger
## (a mine that armed under its own layer would be unusable).
func _mine_victim() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_distance := trigger_radius
	for group: StringName in [PLAYER_GROUP, NPC_GROUP]:
		for node: Node in tree.get_nodes_in_group(group):
			var candidate := node as Node2D
			if candidate == null or _is_source(candidate):
				continue
			var distance := candidate.global_position.distance_to(global_position)
			if distance <= best_distance:
				best_distance = distance
				best = candidate
	return best


## Section 4.2 item 8: "every detonation applies I(d) = P0 / (1 + d^2) as an
## outward impulse over EXPLOSION_WINDOW to every rigid body in range". The push
## itself is `Impact.apply_shockwave` (slice 0's helper, never reimplemented here).
func _detonate(at: Vector2, victim: Node2D = null) -> void:
	if _spent:
		return
	_spent = true
	if victim != null and damage > 0.0:
		_deliver(victim, damage, bypass_shield, at, Vector2.ZERO)
	_push_bodies(at)
	detonated.emit(at, damage, bypass_shield)
	queue_free()


func _push_bodies(at: Vector2) -> void:
	var space := _space()
	if space == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = _shockwave_radius()
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = TARGET_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for result: Dictionary in space.intersect_shape(query, MAX_SHOCKWAVE_BODIES):
		var body: Variant = result.get("collider")
		if body is RigidBody2D:
			ImpactScript.apply_shockwave(at, body, ImpactScript.EXPLOSION_WINDOW)


## The `I(d)` curve's own range: `P0 / (1 + d^2)` reaches
## `MIN_SHOCKWAVE_IMPULSE` at `d = sqrt(P0 / MIN - 1)`, so no new radius is
## invented - the curve says where a push stops mattering.
func _shockwave_radius() -> float:
	return sqrt(maxf(ImpactScript.EXPLOSION_P0 / MIN_SHOCKWAVE_IMPULSE - 1.0, 0.0))


## --- Damage delivery ------------------------------------------------------


## The pinned target seam (brief pinned interface item 4, W2's pipeline): the
## target owns `take_damage(amount, bypass_shield, ctx)`; a two-argument
## `take_damage` also lands (the context is dropped, arity-detected), and
## `PlayerState.damage` is the resource-level fallback. `ctx` is section 4.2 item
## 5's combat context, populated on every hit this file deals.
func _deliver(
	target: Object, amount: float, bypass: bool, point: Vector2, impulse: Vector2
) -> void:
	if amount <= 0.0:
		return
	target = _sink_for(target)
	if target == null:
		return
	if target.has_method(&"take_damage"):
		if _takes_ctx(target, &"take_damage"):
			target.call(&"take_damage", amount, bypass, _ctx(target, point, impulse))
		else:
			target.call(&"take_damage", amount, bypass)
		return
	if target.has_method(&"damage"):
		if _takes_ctx(target, &"damage"):
			target.call(&"damage", amount, bypass, _ctx(target, point, impulse))
		else:
			target.call(&"damage", amount, bypass)


## The ship behind a physics collider, so a shot that strikes a hull's own body is
## still dealt to the hull (section 4.1: the damage belongs to the ship; the collider
## is a `HullBody` with no damage method, measured). The walk is `game.gd:_hull_of`'s:
## the target itself once it answers for damage, else its nearest ancestor in the
## player / NPC ship groups. Anything else - a rock, a decoy, a probe fixture - is
## returned unchanged, so every existing caller keeps its behaviour.
func _sink_for(target: Object) -> Object:
	if target == null:
		return null
	if target.has_method(&"take_damage") or target.has_method(&"damage"):
		return target
	var cursor := target as Node
	while cursor != null:
		if cursor.is_in_group(PLAYER_GROUP) or cursor.is_in_group(NPC_GROUP):
			return cursor
		cursor = cursor.get_parent()
	return target


func _ctx(target: Object, point: Vector2, impulse: Vector2) -> Dictionary:
	return {
		&"direction": _impact_bearing(target, point),
		&"impulse": impulse,
		&"family": family(),
	}


## Section 4.2 item 5: `direction` is the impact bearing relative to the target's
## heading, which is what slice 3's prow/stern/port/starboard quadrants read.
func _impact_bearing(target: Object, point: Vector2) -> float:
	var node := target as Node2D
	if node == null:
		return 0.0
	return wrapf((point - node.global_position).angle() - node.global_rotation, -PI, PI)


## Whether a method takes the context. The answer belongs to the class, not the
## instance, so it is cached per script and a stream of shots pays for one
## `get_method_list` per target class.
func _takes_ctx(target: Object, method: StringName) -> bool:
	var key: Variant = target.get_script()
	if key == null:
		key = target.get_class()
	if _ctx_arity.has(key):
		return bool(_ctx_arity[key])
	var count := 0
	for entry: Dictionary in target.get_method_list():
		if StringName(entry.get("name", "")) == method:
			count = (entry.get("args", []) as Array).size()
			break
	var takes := count >= 3
	_ctx_arity[key] = takes
	return takes


## --- Push helpers ---------------------------------------------------------


func _apply_push(target: Object, impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return
	if target.has_method(&"apply_impulse"):
		target.call(&"apply_impulse", impulse)
		return
	var rigid := target as RigidBody2D
	if rigid != null:
		rigid.apply_central_impulse(impulse)


## The hit's mass, in the same tonnes the section 13 class column uses: a rigid
## body's own mass, or the body a ship hull exposes through `impact_body`. A target
## with no readable mass takes no push (there is nothing to push).
func _mass_of(target: Object) -> float:
	var rigid := target as RigidBody2D
	if rigid != null:
		return rigid.mass
	if target.has_method(&"impact_body"):
		var body: Variant = target.call(&"impact_body")
		if body is RigidBody2D:
			return (body as RigidBody2D).mass
	return 0.0


## --- Collision plumbing ---------------------------------------------------


func _space() -> PhysicsDirectSpaceState2D:
	if not is_inside_tree():
		return null
	var world := get_world_2d()
	if world == null:
		return null
	return world.direct_space_state


func _sync_shape() -> void:
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = SHAPE_NODE
		add_child(_shape)
	var circle := _shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		_shape.shape = circle
	circle.radius = HIT_RADIUS
	collision_layer = PROJECTILE_LAYER
	collision_mask = PROJECTILE_LAYER
	monitoring = true
	monitorable = true


## The shot must not touch the hull that fired it, and an `Area2D` has no collision
## exceptions (`PhysicsBody2D` owns those), so the area's mask is the projectile
## layer alone: the source's hull never overlaps it, and the two sweep queries
## exclude the source's bodies by RID instead.
func _exclusions() -> Array[RID]:
	var out: Array[RID] = [get_rid()]
	for body: CollisionObject2D in _source_bodies():
		if not out.has(body.get_rid()):
			out.append(body.get_rid())
	return out


## Every collision object in the source's subtree, without a `get_node` walk: the
## hull's own bodies are the shot's launch platform and nothing else in the tree is.
func _source_bodies() -> Array[CollisionObject2D]:
	var out: Array[CollisionObject2D] = []
	if _source == null or not is_instance_valid(_source):
		return out
	var stack: Array[Node] = [_source]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var body := node as CollisionObject2D
		if body != null:
			out.append(body)
		for child: Node in node.get_children():
			stack.append(child)
	return out


func _is_source(node: Node) -> bool:
	if _source == null or not is_instance_valid(_source):
		return false
	var cursor := node
	while cursor != null:
		if cursor == _source:
			return true
		cursor = cursor.get_parent()
	return false


func _is_rock(collider: Variant) -> bool:
	var node := collider as Node
	return node != null and node.is_in_group(ROCK_GROUP)


func _is_destructible_shot(collider: Variant) -> bool:
	var node := collider as Node
	if node == null or node == self:
		return false
	if not node.has_method(&"is_destructible"):
		return false
	return bool(node.call(&"is_destructible"))


func _is_explosive() -> bool:
	return kind == KIND_ROCKET or kind == KIND_MINE


func _number(value: Variant, fallback: float = 0.0) -> float:
	if value is float or value is int:
		return float(value)
	return fallback
