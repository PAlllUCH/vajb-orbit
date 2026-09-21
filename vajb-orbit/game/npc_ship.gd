class_name NpcShip
extends Node2D
## One NPC hull: a `RigidBody2D` flying on the same physics law and the same `ShipStats`
## snapshot as the player (ENGINE_SPEC section 2 decision 1 and section 5's "same physics
## for NPC and player"), driven by an `NpcBrain` intent instead of by input.
##
## **Built in code, not in a scene.** W3's file set is three scripts, so this hull builds
## its own `HullBody` (a `RigidBody2D` at local zero) and its own `Hull` sprite under the
## node's namesakes, mirroring `player_ship.tscn`'s tree and its physics contract exactly:
## layer 2, mask 1 (the rock layer, `Asteroid.COLLISION_LAYER`), no gravity, REPLACE-mode
## damping, `can_sleep` false and a contact monitor so a ram resolves like the player's.
## An archetype whose `static` row says so (the station turret) is frozen instead: it is
## bolted where it was spawned and still answerable to a hit.
##
## **The flight law is `PlayerShip`'s, derived from the same owners.** Thrust is
## `mass x the class acceleration` (`max_speed / accel_time`), the coast is
## `1 / coast_time`, the turn torque is `inertia x (alpha + angular_damp x omega)` with
## `inertia = m r^2 / 2` and `angular_damp = 1 / turn_spinup`; the arrive-steering radii
## are read off `PlayerShip` (`SLOW_DOWN_RADIUS`, `ARRIVE_RADIUS`) rather than restated,
## so no section 13 row gains a second home. The derivation itself is the one duplication
## this file carries - `player_ship.gd` is not in W3's file set, so the maths could not be
## extracted into a shared owner - and the W3 report hands that extraction over as a
## cleanup rather than leaving it unstated.
##
## **Damage.** `take_damage(amount, bypass_shield, ctx)` mirrors the pinned sink contract
## (brief item 4, `damage.gd`): shield first with no carry-over, the item-5 context
## recorded, hull 0 fires `died`. `apply_collision_damage` is the door the player's own
## contact monitor already offers a peer (section 4.2 item 6), so a ram this hull is one
## side of lands here. The death flow beyond the signal - loot roll, heat, the wreck - is
## the wiring's (section 7; W5 owns `game.gd`).
##
## Contract: docs/gameplay/18_engine_spec.md sections 2, 4.2, 5, 7, 8 and 13;
## docs/CONTRACTS.md sections 4 and 8.1; docs/gameplay/13; the slice-2 brief's pinned
## interface item 5.

## Raised when the hull is destroyed (pinned interface item 5): the wreck site, the loot
## roll and the heat charge are the wiring's, and the position is read before the hull
## leaves the tree. A despawn is NOT a death and never raises this.
signal died(position: Vector2, archetype: StringName)

## Sibling scripts are reached through preloads rather than through their global class
## names (the house pattern `player_ship.gd` and `damage.gd` both use): a `class_name`
## resolves only once the editor has rescanned the project, which a wave being written
## cannot count on.
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const BrainScript := preload("res://game/npc_brain.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const IMPACT := preload("res://game/impact.gd")

const GROUP: StringName = &"npc_ship"
const PLAYER_GROUP: StringName = &"player_ship"

const HULL_NODE: StringName = &"Hull"
const BODY_NODE: StringName = &"HullBody"
const SHAPE_NODE: StringName = &"Shape"

## The ship layer convention of the shipped tree (`player_ship.tscn`: the hull body is
## layer 2 and masks only the rock layer), so ships are solid to rocks and to nothing
## else - which is also why an NPC may carry a contact monitor without double-charging a
## ram: two ship bodies never pair, so a rock is the only thing this monitor can report.
const HULL_LAYER := 2
const HULL_MASK: int = AsteroidScript.COLLISION_LAYER

## The shipped art scale (the player's hull sprite draws at this scale in
## `player_ship.tscn`, and `sector.gd` draws the station at it too). The hull circle's
## radius is derived from it and the sprite's own size - half the longest axis, the basis
## `player_ship.gd` documents for its own 30 u circle - so no per-class radius is
## invented. A hull whose art is missing gets no circle at all rather than a guessed
## one: nothing about the behaviour depends on it.
const HULL_SCALE := 0.0663

## Section 4.2 item 2 / section 13: shield regeneration resumes this long after the last
## hit. `damage.gd` (slice 2's pipeline) owns the same row for the player-side path and
## it is read from there when the file is present - see `_resolve_regen_quiet` - so the
## two cannot drift while this hull still runs if the pipeline has not landed.
const REGEN_QUIET_FALLBACK := 4.0
const DAMAGE_SCRIPT := "res://game/damage.gd"
const REGEN_QUIET_NAME := "REGEN_QUIET"

## The context keys this hull fills for the brain and the intent keys it reads back.
const CTX_POS: StringName = &"pos"
const CTX_HULL_FRACTION: StringName = &"hull_fraction"
const CTX_HOME: StringName = &"home"
const CTX_HEAT_TIER: StringName = &"heat_tier"
const CTX_CONTACTS: StringName = &"contacts"
const CTX_ATTACKED: StringName = &"attacked"

## Setup options (all optional, additive beyond the pinned three-argument `setup`).
const OPT_HOME: StringName = &"home"
const OPT_SPACE_OWNER: StringName = &"space_owner"
const OPT_ROUTE: StringName = &"route"
const OPT_SPRITE_PATH: StringName = &"sprite_path"

## The profile service the heat tier is read from (doc 13 section 3). Anchored at the
## tree root, the same lookup `player_state.gd` uses; a hull outside a tree reads Clean.
const PROFILE_SERVICE: StringName = &"PlayerProfile"

## How often the player's heat tier is re-read. An implementation cadence, not a game
## value: nothing in the brain depends on reading it on any particular frame.
const HEAT_POLL_SECONDS := 0.5

var _archetype: StringName = &""
var _hull_id: StringName = &""
var _row: Dictionary = {}
var _stats: ShipStats = null
var _brain: RefCounted = null
var _space_owner: StringName = &""
var _home := Vector2.ZERO
var _route: Array[Vector2] = []

var _body: RigidBody2D = null
var _hull_node: Sprite2D = null
var _shape: CollisionShape2D = null
var _art_ready := false
var _built := false
var _override_sprite := ""

var _hull := 0.0
var _hull_max := 0.0
var _shield := 0.0
var _shield_max := 0.0
var _regen_quiet := REGEN_QUIET_FALLBACK
var _damage_quiet := REGEN_QUIET_FALLBACK

## The last hit's item-5 context (section 4.2 item 5): accepted and recorded, a no-op
## until slice 3's quadrants read the direction.
var _last_damage_ctx: Dictionary = {}

## Whether this hull has been hit since its last aggro ended: section 5's turret aggros
## "on attack", and the flag clears when the brain's aggro does.
var _attacked := false
var _engaged_last := false

## The last intent the brain produced, kept for the wiring (the fire flag has no consumer
## yet - see the brain's file doc).
var _intent: Dictionary = {}

var _heat_tier := NpcRegistryScript.HEAT_CLEAN
var _heat_clock := 0.0

## The velocity carried into the physics step that resolved a contact (section 4.2
## item 6's closing speed, exactly as `player_ship.gd` reads it).
var _last_velocity := Vector2.ZERO

var _done := false


func _ready() -> void:
	add_to_group(GROUP)
	_build()
	_regen_quiet = _resolve_regen_quiet()


## Launch handshake (pinned interface item 5, with the additive `opts` bag): the
## archetype whose row drives the behaviour, the resolved `ShipStats` snapshot the flight
## law reads (null is legal - the static rows have no class row, see `npc_registry.gd`)
## and the hull id whose art the sprite draws.
##
## `opts`: `home` (the spawn POI the leash is measured from), `space_owner` (the faction
## whose heat and livery apply), `route` (doc 11 section 3's fixed convoy route) and
## `sprite_path` (an explicit override for a probe or a placeholder).
func setup(
	archetype: StringName, stats: ShipStats, hull_id: StringName, opts: Dictionary = {}
) -> void:
	_archetype = archetype
	_hull_id = hull_id
	_row = NpcRegistryScript.archetype(archetype)
	if _row.is_empty():
		push_warning(
			"Unknown NPC archetype '%s': flying with an empty row (no aggro, no loot)."
			% archetype
		)
	_stats = stats
	_space_owner = StringName(opts.get(OPT_SPACE_OWNER, &""))
	_home = _as_vector(opts.get(OPT_HOME, global_position))
	_route.clear()
	var route: Variant = opts.get(OPT_ROUTE, [])
	if route is Array:
		_route.assign(route)
	_apply_vitals()
	_build()
	_build_brain(String(opts.get(OPT_SPRITE_PATH, "")))
	_apply_art()
	_apply_rigid_body()
	if _stats == null:
		push_warning(
			"NPC '%s' (%s): no ShipStats snapshot, so the hull has no pools to charge and "
			% [_archetype, _hull_id]
			+ "no class handling; it holds position and dies on its first hit. 08 section 5 "
			+ "gives this hull no class row (W3 report)."
		)


func _build() -> void:
	if _built:
		return
	_built = true
	_hull_node = Sprite2D.new()
	_hull_node.name = HULL_NODE
	_hull_node.scale = Vector2(HULL_SCALE, HULL_SCALE)
	add_child(_hull_node)
	_body = RigidBody2D.new()
	_body.name = BODY_NODE
	_body.collision_layer = HULL_LAYER
	_body.collision_mask = HULL_MASK
	_body.gravity_scale = 0.0
	_body.contact_monitor = true
	_body.max_contacts_reported = 4
	_body.can_sleep = false
	_body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	_body.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	add_child(_body)
	_body.body_entered.connect(_on_body_entered)
	_shape = CollisionShape2D.new()
	_shape.name = SHAPE_NODE
	_body.add_child(_shape)
	_apply_art()


## The hull's sprite and its collision circle, both art-derived: the row's swap-ready
## path (`npc_registry.sprite_path_for_hull`: livery first, plain hull second, the hull
## id's own file when the row flies another hull such as a convoy escort), or the
## caller's override.
## Nothing here gates behaviour: a missing file leaves `art_ready` false and the hull
## without a shape rather than inventing a radius (environment-deferred, brief ruling 2).
func _apply_art() -> void:
	if _hull_node == null:
		return
	if _archetype == &"" and _override_sprite.is_empty():
		return
	var path := _sprite_path()
	if path.is_empty():
		_warn_missing_art("")
		return
	var texture := load(path) as Texture2D
	if texture == null:
		_warn_missing_art(path)
		return
	_hull_node.texture = texture
	_art_ready = true
	var circle := CircleShape2D.new()
	circle.radius = _art_radius(texture)
	_shape.shape = circle


## The row's path for this hull, or the hull id's own file, or a caller override. The
## hull-art rule (which of the two names a spawn draws) and the livery fallback both live
## in the registry, so a spawn row and its ship cannot disagree about the file.
func _sprite_path() -> String:
	if not _override_sprite.is_empty():
		return _override_sprite
	if _archetype == &"":
		return ""
	return NpcRegistryScript.sprite_path_for_hull(_row, _hull_id, _space_owner)


func _art_radius(texture: Texture2D) -> float:
	var longest := maxf(float(texture.get_width()), float(texture.get_height()))
	return longest * HULL_SCALE * 0.5


func _warn_missing_art(path: String) -> void:
	push_warning(
		"NPC '%s': no art at '%s'; the hull flies and fights without a collision circle."
		% [_archetype, path]
	)


func _build_brain(override_sprite: String) -> void:
	_override_sprite = override_sprite
	if _row.is_empty():
		return
	_brain = BrainScript.new()
	_brain.call(&"setup", _archetype, _row, _home)
	## Section 5's LOS check, the shipping one: the brain never touches the tree, so the
	## ray that answers "does a rock block this line" is installed here.
	_brain.call(&"set_line_of_sight", Callable(self, &"_line_of_sight"))
	if not _route.is_empty():
		_brain.call(&"set_route", _route)


## The two pools the sink contract needs, from the launch snapshot (section 9: the
## snapshot is the hull's own numbers).
func _apply_vitals() -> void:
	_hull_max = _stats.hull_max if _stats != null else 0.0
	_shield_max = _stats.shield_max if _stats != null else 0.0
	_hull = _hull_max
	_shield = _shield_max


## The body's numbers, all from the snapshot: mass, the inertia its radius implies and
## the class's two damp rates. A static row freezes its body in place (the station
## turret: "static, high damage").
func _apply_rigid_body() -> void:
	if _body == null:
		return
	if _stats == null:
		_body.freeze = true
		return
	_body.mass = _stats.hull_mass if _stats.hull_mass > 0.0 else PlayerShip.UNRESOLVED_HULL_MASS
	_body.inertia = _angular_inertia()
	_body.linear_damp = _linear_damp()
	_body.angular_damp = _angular_damp()
	_body.freeze = bool(_row.get(NpcRegistryScript.KEY_STATIC, false))
	_last_velocity = _body.linear_velocity


## --- Damage (brief item 4's sink contract) ----------------------------------------


## One hit. Shield first with no carry-over while the shield lives (section 4.2 item 1),
## so an oversized energy hit leaves the hull untouched; `bypass_shield` is section 4.1's
## kinetic/missile rule. `ctx` is section 4.2 item 5's context - recorded, never applied
## - and the third parameter is what `damage.gd`'s pipeline hands a sink that declares it.
func take_damage(amount: float, bypass_shield: bool = false, ctx: Dictionary = {}) -> void:
	if _done or _hull <= 0.0:
		return
	_last_damage_ctx = ctx
	_damage_quiet = 0.0
	_attacked = true
	if amount <= 0.0:
		return
	if _hull_max <= 0.0:
		## No snapshot means no structure: the hull has no pool to charge, so it cannot
		## absorb the hit and dies on the first one. Announced once in `setup` (the turret
		## platform is the row this happens to - 08 section 5 gives it no class row).
		_die()
		return
	if not bypass_shield and _shield > 0.0:
		set_shield(_shield - amount)
		return
	set_hull(_hull - amount)


## The other half of a body-body impact (section 4.2 item 6): `PlayerShip`'s contact
## monitor charges its own side and offers this same figure to the peer through this
## method, which is the shape slice 0 published for a rock and for a hull.
func apply_collision_damage(amount: float) -> void:
	take_damage(amount)


func set_shield(value: float) -> void:
	_shield = clampf(value, 0.0, _shield_max)


func set_hull(value: float) -> void:
	var was_alive := _hull > 0.0
	_hull = clampf(value, 0.0, _hull_max)
	if was_alive and _hull <= 0.0:
		_die()


## Section 7's death, minus the wiring: the signal goes up with what the wiring needs
## (where and what), then the hull leaves the tree - deferred, so every listener runs on
## a live node. Loot, heat, the wreck and the 5-minute recovery window are `game.gd`'s.
func _die() -> void:
	if _done:
		return
	died.emit(global_position, _archetype)
	despawn()


## The external recycle (section 5's spawn model: the sector populates on entry and
## re-rolls on the 20-minute clock). A despawn is not a kill: no `died`, no loot, no heat.
##
## In a tree the hull joins the SceneTree's delete queue (deferred, so every listener on
## `died` runs on a live node). Outside one - a probe or a unit test that built a hull
## with no scene - there is no such queue, so the free is deferred on the global message
## queue instead and the hull stays valid for the rest of the frame either way.
func despawn() -> void:
	if _done:
		return
	_done = true
	if is_inside_tree():
		queue_free()
		return
	call_deferred(&"free")


## --- The frame -------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if _done:
		return
	_sync_hull_transform()
	_steer_frame(delta)
	_damage_quiet += delta
	if _shield < _shield_max and _damage_quiet >= _regen_quiet and _stats != null:
		set_shield(_shield + _stats.shield_regen * delta)
	_last_velocity = _body.linear_velocity if _body != null else Vector2.ZERO


## One brain frame: gather what the brain reads, tick it, apply what it decided. A hull
## with no archetype row or no brain holds position and does nothing, which is what a
## probe that only wanted a body gets.
func _steer_frame(delta: float) -> void:
	if _body == null:
		return
	_heat_clock += delta
	if _heat_clock >= HEAT_POLL_SECONDS:
		_heat_clock = 0.0
		_heat_tier = _read_heat_tier()
	if _brain == null:
		return
	var engaged := bool(_brain.call(&"is_engaged"))
	if _engaged_last and not engaged:
		_attacked = false
	_engaged_last = engaged
	var ctx := {
		CTX_POS: global_position,
		CTX_HULL_FRACTION: hull_fraction(),
		CTX_HOME: _home,
		CTX_HEAT_TIER: _heat_tier,
		CTX_CONTACTS: _contacts(),
		CTX_ATTACKED: _attacked,
	}
	_intent = _brain.call(&"tick", delta, ctx)
	if bool(_intent.get(BrainScript.INTENT_DESPAWN, false)):
		despawn()
		return
	_apply_intent(
		_as_vector(_intent.get(BrainScript.INTENT_WAYPOINT, global_position)),
		float(_intent.get(BrainScript.INTENT_SPEED, 0.0)),
		delta
	)


## Fly the intent: the arrive steering of section 3.1/3.2, at the class's own rates. A
## static row (the turret) and a null snapshot never move the body.
func _apply_intent(waypoint: Vector2, speed: float, delta: float) -> void:
	if _stats == null or _body == null:
		return
	if bool(_row.get(NpcRegistryScript.KEY_STATIC, false)):
		return
	if speed <= 0.0:
		_step_turn(0.0, delta)
		_step_speed(0.0, _coast_rate(), delta)
		return
	_step_turn(_order_turn(waypoint), delta)
	_step_speed(_order_speed(waypoint, speed), _accel_rate(), delta)


## Arrive steering, exactly as the player's autopilot: the desired heading is the bearing
## to the waypoint as a fraction of the class turn rate (one radian of error is full
## deflection), and the desired speed ramps from the intent's fraction to zero across
## `SLOW_DOWN_RADIUS`, reaching zero at `ARRIVE_RADIUS`. Both radii are the section 13
## autopilot rows, read off their single owner (`PlayerShip`).
func _order_turn(waypoint: Vector2) -> float:
	var bearing := (waypoint - global_position).angle()
	var error := wrapf(bearing - _heading(), -PI, PI)
	return clampf(error, -1.0, 1.0) * _stats.turn_rate


func _order_speed(waypoint: Vector2, speed: float) -> float:
	var to_target := waypoint - global_position
	var error := wrapf(to_target.angle() - _heading(), -PI, PI)
	if absf(error) > PI * 0.5:
		return 0.0
	var fraction := clampf(
		(to_target.length() - PlayerShip.ARRIVE_RADIUS) / PlayerShip.SLOW_DOWN_RADIUS, 0.0, 1.0
	)
	return _max_speed() * speed * fraction


## The turn, on the body: the rate is asked to spin up to `desired_turn` at the class's
## own spin-up rate and the torque is that angular acceleration times the hull's inertia,
## with the body's damp compensated for so the class number is the spin-up rather than
## the spin-up minus drag. Ported from `PlayerShip._step_turn` unchanged.
func _step_turn(desired_turn: float, delta: float) -> void:
	if _body == null or delta <= 0.0:
		return
	var spin_rate := _spin_rate()
	var omega := _body.angular_velocity
	var alpha := clampf((desired_turn - omega) / delta, -spin_rate, spin_rate)
	var torque := _angular_inertia() * (alpha + _angular_damp() * omega)
	if is_zero_approx(torque):
		return
	_body.apply_torque(torque)


## The thrust, on the body's velocity along its heading, with the class damp compensated
## for on that axis so throttle reaches `max_speed` over `accel_time`. The damp still owns
## the lateral degree of freedom, so a pushed hull slides and settles. Ported from
## `PlayerShip._step_speed` unchanged; an NPC never commands reverse thrust.
func _step_speed(desired_speed: float, rate: float, delta: float) -> void:
	if _body == null or delta <= 0.0:
		return
	var forward := Vector2.RIGHT.rotated(_heading())
	var along := _body.linear_velocity.dot(forward)
	var accel := clampf((desired_speed - along) / delta, -rate, rate)
	var force := _hull_mass() * (accel + _linear_damp() * along)
	if is_zero_approx(force):
		return
	_body.apply_central_force(forward * force)


## The body owns the live transform and this node mirrors it, so the sprite stays with
## the hull and the body's local transform returns to zero (the player's own division of
## labour, `PlayerShip._sync_hull_transform`).
func _sync_hull_transform() -> void:
	if _body == null or not is_inside_tree():
		return
	global_position = _body.global_position
	global_rotation = _body.global_rotation
	_body.position = Vector2.ZERO
	_body.rotation = 0.0


## Section 4.2 item 6 on the NPC's side: a contact past `COLLISION_MIN_DV` charges the
## kinetic damage `impact.gd` owns, shield-first, and offers the same figure to the peer.
## The closing speed is the velocity carried into the step (`_last_velocity`), measured
## along the line between the centres.
func _on_body_entered(other: Node) -> void:
	if other == null or _done:
		return
	var damage := IMPACT.collision_damage(
		_hull_mass(), _peer_mass(other), _closing_speed(other)
	)
	if damage <= 0.0:
		return
	take_damage(damage)
	if other.has_method(&"apply_collision_damage"):
		other.call(&"apply_collision_damage", damage)


func _closing_speed(other: Node) -> float:
	var relative := _last_velocity - _peer_velocity(other)
	if relative.is_zero_approx():
		return 0.0
	var direction := relative.normalized()
	var other_node := other as Node2D
	if other_node != null:
		var offset := other_node.global_position - global_position
		if offset.length_squared() > 0.0001:
			direction = offset.normalized()
	return maxf(relative.dot(direction), 0.0)


func _peer_mass(other: Node) -> float:
	var rigid := other as RigidBody2D
	return rigid.mass if rigid != null else INF


func _peer_velocity(other: Node) -> Vector2:
	var rigid := other as RigidBody2D
	return rigid.linear_velocity if rigid != null else Vector2.ZERO


## Section 5's LOS check, the shipping half: a physics ray over the rock layer
## (`Asteroid.COLLISION_LAYER`), so a rock between the hull and its contact blocks the
## line exactly as the spec requires. Installed into the brain at setup.
func _line_of_sight(from: Vector2, to: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var world := get_world_2d()
	if world == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(from, to, HULL_MASK)
	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty()


## --- Contacts ---------------------------------------------------------------------


## The live contacts the brain reads: the player's hull and every other living NPC hull,
## each with the fields the registry's hostility rule needs. A hull's own archetype and
## hostility are published by the other ship, so no registry scan happens per contact.
func _contacts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node: Node in tree.get_nodes_in_group(PLAYER_GROUP):
		var player := node as Node2D
		if player != null and is_instance_valid(player):
			out.append(_contact(player, true, NpcRegistryScript.HOSTILITY_NONE, &""))
	for node: Node in tree.get_nodes_in_group(GROUP):
		if node == self:
			continue
		var other := node as Node2D
		if other == null or not is_instance_valid(other):
			continue
		if other.has_method(&"is_alive") and not bool(other.call(&"is_alive")):
			continue
		out.append(
			_contact(
				other,
				false,
				_call_name(other, &"hostility", NpcRegistryScript.HOSTILITY_NONE),
				_call_name(other, &"archetype", &"")
			)
		)
	return out


func _contact(
	node: Node2D, is_player: bool, hostility: StringName, contact_archetype: StringName
) -> Dictionary:
	return {
		&"node": node,
		CTX_POS: node.global_position,
		&"velocity": _body_velocity(node),
		&"is_player": is_player,
		&"archetype": contact_archetype,
		&"hostility": hostility,
	}


func _body_velocity(node: Node2D) -> Vector2:
	if node.has_method(&"velocity"):
		return _as_vector(node.call(&"velocity"))
	var rigid := node as RigidBody2D
	return rigid.linear_velocity if rigid != null else Vector2.ZERO


func _call_name(node: Node, method: StringName, fallback: StringName) -> StringName:
	if not node.has_method(method):
		return fallback
	return StringName(node.call(method))


## Doc 13 section 3's tier for the player's heat in this space: the local faction's heat
## where the sector is owned, and the worst of the player's heats where it is not. Read
## only - `PlayerProfile` stays the only mutator (17 section 5).
func _read_heat_tier() -> StringName:
	var profile := _profile()
	if profile == null or not profile.has_method(&"heat"):
		return NpcRegistryScript.HEAT_CLEAN
	var table: Dictionary = profile.call(&"heat")
	if table.is_empty():
		return NpcRegistryScript.HEAT_CLEAN
	var heat := 0
	if _space_owner != &"":
		heat = int(table.get(String(_space_owner), 0))
	else:
		for faction: Variant in table:
			heat = maxi(heat, int(table[faction]))
	return NpcRegistryScript.heat_tier(heat)


func _profile() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	var root := (loop as SceneTree).root
	if root == null:
		return null
	return root.get_node_or_null(NodePath(PROFILE_SERVICE))


## Section 4.2 item 2's quiet window, read from the pipeline's own owner when it is
## present: `damage.gd` is a sibling of this wave's, so the read is guarded (a tree
## without the pipeline still flies) and the fallback carries the same section 13 row.
func _resolve_regen_quiet() -> float:
	var script := load(DAMAGE_SCRIPT) as Script
	if script == null:
		return REGEN_QUIET_FALLBACK
	var consts: Dictionary = script.get_script_constant_map()
	if consts.has(REGEN_QUIET_NAME):
		return float(consts[REGEN_QUIET_NAME])
	return REGEN_QUIET_FALLBACK


## --- The hull's own numbers (all from the snapshot) -------------------------------


func _hull_mass() -> float:
	if _stats == null or _stats.hull_mass <= 0.0:
		return PlayerShip.UNRESOLVED_HULL_MASS
	return _stats.hull_mass


func _hull_radius() -> float:
	if _shape == null or not (_shape.shape is CircleShape2D):
		return 0.0
	return (_shape.shape as CircleShape2D).radius


func _angular_inertia() -> float:
	var radius := _hull_radius()
	if radius <= 0.0:
		return 0.0
	return 0.5 * _hull_mass() * radius * radius


func _accel_rate() -> float:
	if _stats == null or _stats.accel_time <= 0.0:
		return _stats.max_speed if _stats != null else 0.0
	return _stats.max_speed / _stats.accel_time


func _coast_rate() -> float:
	if _stats == null or _stats.coast_time <= 0.0:
		return _stats.max_speed if _stats != null else 0.0
	return _stats.max_speed / _stats.coast_time


func _spin_rate() -> float:
	if _stats == null or _stats.turn_spinup <= 0.0:
		return _stats.turn_rate if _stats != null else 0.0
	return _stats.turn_rate / _stats.turn_spinup


func _linear_damp() -> float:
	if _stats == null or _stats.coast_time <= 0.0:
		return 0.0
	return 1.0 / _stats.coast_time


func _angular_damp() -> float:
	if _stats == null or _stats.turn_spinup <= 0.0:
		return 0.0
	return 1.0 / _stats.turn_spinup


func _max_speed() -> float:
	return _stats.max_speed if _stats != null else 0.0


func _heading() -> float:
	if _body != null:
		return _body.global_rotation
	return global_rotation


## --- The published API (the wiring's side of the hull) ----------------------------


func archetype() -> StringName:
	return _archetype


func hull_id() -> StringName:
	return _hull_id


func row() -> Dictionary:
	return _row


## Section 5's behaviour class, published so a contact's own rule can be read without a
## registry scan (a patrol defends against any hull that attacks anything).
func hostility() -> StringName:
	return StringName(_row.get(NpcRegistryScript.KEY_HOSTILITY, NpcRegistryScript.HOSTILITY_NONE))


## Section 8's minimap class: hostile (pirates, swarmers, hunters) or neutral (convoys).
func blip_kind() -> StringName:
	return StringName(_row.get(NpcRegistryScript.KEY_BLIP_KIND, NpcRegistryScript.BLIP_HOSTILE))


## The faction this hull flies for in its space, resolved at setup.
func faction() -> StringName:
	return NpcRegistryScript.resolve_faction(_row, _space_owner)


func space_owner() -> StringName:
	return _space_owner


func home() -> Vector2:
	return _home


func hull() -> float:
	return _hull


func hull_max() -> float:
	return _hull_max


func shield() -> float:
	return _shield


func shield_max() -> float:
	return _shield_max


func hull_fraction() -> float:
	if _hull_max <= 0.0:
		return 0.0
	return _hull / _hull_max


func is_alive() -> bool:
	return not _done and _hull > 0.0


## Doc 13 section 2's heat for this kill (a pirate costs the local faction nothing and
## returns 3, a trader costs 15, a patrol or turret 25) and doc 13 section 4's standing
## gain. Read off the victim by the wiring on `died`.
func heat_on_kill() -> int:
	return int(_row.get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))


func standing_on_kill() -> int:
	return int(_row.get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))


## The brain's state name (section 5's set) and the live target, which is what the
## safe-warp gate asks (section 7: "no hostile in Alert or Engage targeting the player").
func state_name() -> StringName:
	if _brain == null:
		return &""
	return StringName(_brain.call(&"state_name"))


func target() -> Node2D:
	if _brain == null:
		return null
	return _brain.call(&"target") as Node2D


func engaged_with(node: Node) -> bool:
	if node == null or _brain == null or _done:
		return false
	if not bool(_brain.call(&"is_engaged")):
		return false
	return target() == node


## The last intent the brain produced (state, waypoint, speed, fire): the fire flag has
## no consumer until NPC armament exists (see the report), and the wiring reads the rest.
func intent() -> Dictionary:
	return _intent


func art_ready() -> bool:
	return _art_ready


## The push seams `damage.gd` and the weapon code reach a hull through (the pinned
## `PlayerShip` names, mirrored: `impact.gd`'s blast and the knockback both land here).
func impact_body() -> RigidBody2D:
	return _body


func velocity() -> Vector2:
	return _body.linear_velocity if _body != null else Vector2.ZERO


func apply_impulse(impulse: Vector2) -> void:
	if _body == null or impulse.is_zero_approx() or _done:
		return
	_body.apply_central_impulse(impulse)


## The most recent hit's item-5 context, for a probe or the slice-3 quadrants.
func last_damage_ctx() -> Dictionary:
	return _last_damage_ctx.duplicate()


func _as_vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is Vector2i:
		return Vector2(value as Vector2i)
	return Vector2.ZERO
