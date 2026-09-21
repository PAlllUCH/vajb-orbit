class_name PlayerShip
extends Node2D
## The player's hull: hybrid flight on a real physics body (ENGINE_SPEC section 3.1
## and ruling 8), mass-scaled inertia with the arrive-steering autopilot (section
## 3.2), the booster seam, the mining-laser mount (W3's scene, mounted only when the
## resolved fit spends a W slot on `w_mining`) and the rock collision body (section 6).
## Flight reads *only* the ShipStats snapshot ShipFit resolves (section 3.3): the
## per-class handling column and the booster activation numbers stay in ship_fit.gd,
## so no flight number is duplicated here. The constants that do live here are the
## section 13 values that belong to no class and to no module (brake multiplier,
## arrive-steering radii) plus the section 7 warp quiet time.
## Contract: ENGINE_SPEC sections 3, 4.2 (items 6-8, ruling 16's push physics), 6, 7,
## 9, 13; engine-wave-1 brief section W2; slice-0 brief pinned interface item 1.

## Raised when the live pools lose points (hull or shield). The warp channel
## breaks on damage (ENGINE_SPEC section 7); game.gd listens to this instead of
## re-deriving "was that regen?" from the PlayerState signals. Collision damage rides
## the same channel (section 4.2 item 6).
signal damage_taken(amount: float)

const MINING_LASER_NODE: StringName = &"MiningLaser"
const MINING_LASER_SCENE := "res://game/mining_laser.tscn"

## 09 section 4.5 (the owner's mining-laser rule) and ENGINE_SPEC section 4.3/6:
## the mining laser is the `w_mining` tool that occupies a **W slot**, Tier I,
## draw 1. Buying the ability with a gun slot is the whole Delver/Fighter
## trade-off, so the module is the gate: a fit without it has spent no W slot and
## carries no laser and no trigger.
const MINING_MODULE: StringName = &"w_mining"

## ENGINE_SPEC section 6, "Rocks are solid: ships collide with them" + ruling 8.
## The scene's `HullBody` (a RigidBody2D at local zero) carries the ship's own physics
## layer and masks only the rock layer (Asteroid.COLLISION_LAYER), so rocks stop the
## hull and no unrelated body can; its CircleShape2D radius is the hull's half-length:
## the shipped sprite's 905 px at this scene's 0.0663 hull scale is 60.0 u long, the
## same art-derived basis asteroid.gd's LOOK_WIDTHS reads. A circle is
## rotation-invariant and the long axis dominates, so a side-on stop leaves ~17 u of
## gap to the sprite's edge. The body owns the live transform and the momentum; this
## node mirrors it (see `_sync_hull_transform`), so the sprite, the mining laser and
## the camera riding this node stay with the hull.
const HULL_BODY_NODE: StringName = &"HullBody"
const HULL_SHAPE_NODE: StringName = &"Shape"

const THRUST_FORWARD: StringName = &"thrust_forward"
const THRUST_BACKWARD: StringName = &"thrust_backward"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"
const BOOST_ACTION: StringName = &"boost"
const MINE_ACTION: StringName = &"mine"

## 09 section 3.5 boosters. `b_afterburner` is v1's only implemented booster;
## `b_fold` is expected in a fit (ShipFit carries it as data) and its 400 u blink
## is slice 4, so a fitted fold module is recognised and deliberately inert.
const BOOSTER_AFTERBURNER: StringName = &"b_afterburner"

## ENGINE_SPEC section 13: BRAKE_MULT (S-thrust versus coast) and the autopilot
## arrive-steering radii. These are global calibration, not a ShipStats field.
const BRAKE_MULT := 1.8
const SLOW_DOWN_RADIUS := 240.0
const ARRIVE_RADIUS := 40.0

## ENGINE_SPEC section 7: safe warp is available after 5 s without a hit.
const WARP_DAMAGE_QUIET := 5.0

## The push-physics arithmetic of section 4.2 items 6-8 (`impact.gd`), reached through
## a preload rather than through its global class name: a `class_name` only resolves
## once the editor has rescanned the project, which a headless worker cannot count on
## while the wave is still being written (game.gd reaches this very file the same way).
const IMPACT := preload("res://game/impact.gd")

## Mass used when the launch snapshot carries no `hull_mass`: the section 13 class
## column is M2's field on ShipStats, and the migration stands on its own until it is
## there (the hull flies either way, because the flight maths is mass-independent, see
## `_step_speed`; but collision damage and every impulse are charged per mass, so a
## missing field is announced in `setup` rather than flown at a wrong weight).
const UNRESOLVED_HULL_MASS := 1.0

var _stats: ShipStats = null
var _state: PlayerState = null
var _body: RigidBody2D = null
var _laser: Node = null
var _laser_active := false
var _fit_ids: Array[StringName] = []

var _move_target := Vector2.ZERO
var _has_move_target := false

var _boost_remaining := 0.0
var _boost_cooldown := 0.0

var _damage_quiet := WARP_DAMAGE_QUIET
var _last_hull := 0.0
var _last_shield := 0.0
var _vitals_seeded := false

## The velocity the hull carried *into* the current physics step. Contact monitor
## events arrive after the solver has already spent the approach speed, so this is the
## pre-impact velocity `_on_hull_body_entered` charges damage from (section 4.2 item 6).
var _last_velocity := Vector2.ZERO


func _ready() -> void:
	add_to_group(&"player_ship")
	_body = get_node_or_null(NodePath(HULL_BODY_NODE)) as RigidBody2D
	if _body != null:
		_body.body_entered.connect(_on_hull_body_entered)
	_sync_mining_laser()


## Launch handshake (pinned interface): the resolved snapshot plus the scene's
## live pools. Safe to call again on a hull swap; the old state is released and the
## rigid body is re-sized for the new hull.
##
## `fit_ids` is the launched fit's module ids (`ShipFit.fitted_ids`, additive
## beyond the pin, defaulting to an empty fit): the W-slot gate for the mining
## laser (09 section 4.5). The 09 section 7 standard fit carries no `w_mining`, so
## a ship launched without that module mounts no laser and `E` mines nothing until
## it is fitted.
func setup(stats: ShipStats, state: PlayerState, fit_ids: Array[StringName] = []) -> void:
	_stats = stats
	_release_state()
	_state = state
	_fit_ids = fit_ids.duplicate()
	_apply_rigid_body()
	_sync_mining_laser()
	if _state == null:
		return
	_last_hull = _state.hull
	_last_shield = _state.shield
	_vitals_seeded = true
	_state.hull_changed.connect(_on_hull_changed)
	_state.shield_changed.connect(_on_shield_changed)


## Autopilot order (ENGINE_SPEC section 3.1). `pos` is a global position,
## normally the cursor's world point. Firing does not cancel an order; thrust or
## turn input does.
func set_move_target(pos: Vector2) -> void:
	_move_target = pos
	_has_move_target = true


func cancel_orders() -> void:
	_has_move_target = false


## Safe-warp state query for game.gd's gate (ENGINE_SPEC section 7): the hull is
## alive and nothing has hit it for WARP_DAMAGE_QUIET. Whether a station exists
## in the sector and whether a hostile is engaged are the sector's and game.gd's
## halves of the same gate.
func warp_available() -> bool:
	if _stats == null or _state == null:
		return false
	if _state.hull <= 0.0:
		return false
	return _damage_quiet >= WARP_DAMAGE_QUIET


func has_booster(id: StringName) -> bool:
	return _stats != null and _stats.boosters.has(id)


## The live hold this hull flies with (ENGINE_SPEC section 9: PlayerState's maxima
## come from the launch snapshot). The pickup's hold-full gate reads it, so the gate
## and the HUD cargo bar agree on one capacity for every hull, including the five the
## station catalogue does not sell. Falls back to the snapshot before `setup` runs.
func cargo_max() -> int:
	if _state != null and _state.cargo_max > 0:
		return _state.cargo_max
	if _stats != null and _stats.cargo_max > 0:
		return _stats.cargo_max
	return 0


## The hull's live velocity vector, momentum and all (ruling 18's speed fantasy reads
## |v| / v_max off it, and slice 2's gunnery reads it for lead and for hit
## resolution). Empty until the scene's body exists.
func velocity() -> Vector2:
	if _body != null:
		return _body.linear_velocity
	return Vector2.ZERO


## The hull's rigid body (pinned seam, additive beyond the flight API): push-physics
## callers work on bodies, not on ships: `Impact.apply_shockwave` takes one, and
## slice 2's detonations walk hulls and rocks. Null before the scene is ready.
func impact_body() -> RigidBody2D:
	return _body


## Generic push (section 4.2 items 7/8): knockback from a hit and the edge of a blast
## both arrive as an impulse, so both land here and neither needs to know about the
## body. Instant, like every other impulse in the pipeline.
func apply_impulse(impulse: Vector2) -> void:
	if _body == null or impulse.is_zero_approx():
		return
	_body.apply_central_impulse(impulse)


## Section 4.2 item 7, the shooter's half: a shot pushes the hull back with
## `projectile_mass * muzzle_velocity` opposite the muzzle. Slice 2's weapons call
## this with the shot they just spawned (the barrel's direction is the projectile's
## own velocity), so the recoil seam exists before the first gun; the mining laser is
## a tool and fires nothing.
func apply_recoil(projectile_velocity: Vector2, projectile_mass: float) -> void:
	if _body == null or projectile_velocity.is_zero_approx():
		return
	var instant := IMPACT.recoil_impulse(projectile_mass, projectile_velocity.length())
	if instant <= 0.0:
		return
	_body.apply_central_impulse(-projectile_velocity.normalized() * instant)


## The hull's heading, in the physics body's own frame (the ship mirrors the body, so
## the node's rotation is only a copy). Steering reads it, the thrust axis is it.
func _heading() -> float:
	if _body != null:
		return _body.global_rotation
	return global_rotation


func _physics_process(delta: float) -> void:
	_sync_hull_transform()
	_update_boosters(delta)
	_update_mining_laser()
	_damage_quiet += delta
	if _stats == null or _body == null:
		return

	var throttle := _manual_throttle()
	var turn := _manual_turn()
	if _has_move_target and (not is_zero_approx(throttle) or not is_zero_approx(turn)):
		cancel_orders()
	if _has_move_target and global_position.distance_to(_move_target) <= ARRIVE_RADIUS:
		cancel_orders()

	var desired_turn := 0.0
	var desired_speed := 0.0
	var rate := _coast_rate()
	if _has_move_target:
		desired_turn = _order_turn()
		desired_speed = _order_speed()
		if absf(desired_speed) > absf(_velocity_along_heading()):
			rate = _accel_rate()
	else:
		desired_turn = turn * _stats.turn_rate
		desired_speed = throttle * _max_speed()
		if not is_zero_approx(throttle):
			rate = _accel_rate() * (BRAKE_MULT if throttle < 0.0 else 1.0)
	_step_turn(desired_turn, delta)
	_step_speed(desired_speed, rate, delta)
	_last_velocity = _body.linear_velocity


## LMB on empty space orders a fly-to (section 3.1). Slice 2 splits this into
## "click a hostile hull to lock it"; with no NPCs there is no hostile pick yet.
func _unhandled_input(event: InputEvent) -> void:
	if _stats == null:
		return
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	set_move_target(get_global_mouse_position())


func _manual_throttle() -> float:
	if not InputMap.has_action(THRUST_FORWARD) or not InputMap.has_action(THRUST_BACKWARD):
		return 0.0
	return (
		Input.get_action_strength(THRUST_FORWARD) - Input.get_action_strength(THRUST_BACKWARD)
	)


func _manual_turn() -> float:
	if not InputMap.has_action(TURN_RIGHT) or not InputMap.has_action(TURN_LEFT):
		return 0.0
	return Input.get_action_strength(TURN_RIGHT) - Input.get_action_strength(TURN_LEFT)


## Arrive steering: the desired heading is the bearing to the order, expressed as
## a fraction of the class turn rate (one radian of error is full deflection).
## The turn model spins up to it, so heavy hulls arc and overshoot (section 3.2).
func _order_turn() -> float:
	var bearing := (_move_target - global_position).angle()
	var error := wrapf(bearing - _heading(), -PI, PI)
	return clampf(error, -1.0, 1.0) * _stats.turn_rate


## Arrive steering: the desired speed falls from the class maximum to zero across
## SLOW_DOWN_RADIUS and reaches zero at ARRIVE_RADIUS, so the autopilot stops in
## the ring instead of coasting through it. A target behind the bow holds speed
## at zero while the ship comes about (no reverse thrust in autopilot).
func _order_speed() -> float:
	var to_target := _move_target - global_position
	var error := wrapf(to_target.angle() - _heading(), -PI, PI)
	if absf(error) > PI * 0.5:
		return 0.0
	var fraction := clampf((to_target.length() - ARRIVE_RADIUS) / SLOW_DOWN_RADIUS, 0.0, 1.0)
	return _max_speed() * fraction


## Angular inertia, on the body: the turn rate is asked to spin up to `desired_turn`
## at the class's own rate (turn_rate / turn_spinup, section 3.2) and the torque is
## that angular acceleration times the hull's inertia, so the same class number means
## the same spin-up on every hull however heavy it is. The body's angular damp is
## compensated for, so the spin-up is the class rate and not the class rate minus
## drag; `apply_torque` is a global torque and positive is clockwise, which is the
## same sign the turn actions and the old `_heading` integration used.
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


## Linear motion, on the body's velocity (ruling 8: thrust is `mass x acceleration`,
## and the acceleration is the class's own). The velocity *along the heading* is asked
## to chase `desired_speed` at `rate` (the same move_toward the hybrid model always
## used, now expressed as the acceleration it implies), so throttle reaches max_speed
## over accel_time, S brakes at BRAKE_MULT times that, and the autopilot's arrive
## ramp obeys the same law. The body's linear damp is compensated for along that axis,
## so the chase is the class rate rather than the class rate minus drag; the damp
## still owns the *lateral* velocity, the degree of freedom real physics adds (a hit
## or a blast pushes the hull sideways and it settles over coast_time).
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


## The body owns the hull's live transform and this node mirrors it: the sprite, the
## mining laser and the camera hang off this node, so the mirror is what keeps them
## with the hull. The body's local transform then returns to zero, which leaves its
## *global* transform exactly where the physics step put it: the same division of
## labour the hybrid model's body used (the ship owns the scene transform, the body
## owns the shape), now with a body that carries the momentum as well.
func _sync_hull_transform() -> void:
	if _body == null or not is_inside_tree():
		return
	global_position = _body.global_position
	global_rotation = _body.global_rotation
	_body.position = Vector2.ZERO
	_body.rotation = 0.0


## Ruling 15 / section 4.2 item 6: a body-body impact past COLLISION_MIN_DV deals
## kinetic damage to both sides out of the reduced-mass form. The closing speed is the
## one the hull carried *into* the step that resolved the contact (`_last_velocity`),
## measured along the line between the two centres; a peer that does not yield comes
## back as an infinite mass from `_peer_mass`, which is the flat-wall case of the
## section 16 worked example.
##
## The player's half lands on `PlayerState.damage`, so the shield absorbs it like any
## other hit (section 4.2 item 1) and `damage_taken` rides the same channel; the
## peer's half is offered to `apply_collision_damage` when the peer has one (M2's
## rocks take it; a wall or a station has no hull to charge).
func _on_hull_body_entered(other: Node) -> void:
	if _state == null or other == null:
		return
	var damage := IMPACT.collision_damage(
		_hull_mass(), _peer_mass(other), _closing_speed(other)
	)
	if damage <= 0.0:
		return
	_state.damage(damage)
	if other.has_method(&"apply_collision_damage"):
		other.call(&"apply_collision_damage", damage)


## The closing speed of a contact: the relative velocity project on the line between
## the two centres, floored at zero so a separating pair charges nothing. A peer with
## no usable offset (its centre on ours) falls back to the relative velocity's own
## direction, which is the head-on reading of the same number.
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


## The hull's mass: section 13's per-class column, resolved into the snapshot by
## ShipFit. Read dynamically so the migration does not depend on M2's field landing
## first; a snapshot without it is announced once in `setup` (see
## UNRESOLVED_HULL_MASS) rather than flown at a silent, wrong weight.
func _hull_mass() -> float:
	if _stats == null:
		return UNRESOLVED_HULL_MASS
	var mass: Variant = _stats.get(&"hull_mass")
	if (mass is float or mass is int) and float(mass) > 0.0:
		return float(mass)
	return UNRESOLVED_HULL_MASS


## A peer that carries no simulated mass of its own (a wall, a station, anything that
## is not a rigid body) is immovable, which the reduced mass reads as an infinite
## mass.
func _peer_mass(other: Node) -> float:
	var rigid := other as RigidBody2D
	if rigid == null:
		return INF
	return rigid.mass


func _peer_velocity(other: Node) -> Vector2:
	var rigid := other as RigidBody2D
	if rigid != null:
		return rigid.linear_velocity
	return Vector2.ZERO


## The hull's radius, read off the scene's own collision shape (the art-derived
## half-length). Used only to size the body's inertia, once per launch.
func _hull_radius() -> float:
	if _body == null:
		return 0.0
	var shape := _body.get_node_or_null(NodePath(HULL_SHAPE_NODE)) as CollisionShape2D
	if shape == null or not (shape.shape is CircleShape2D):
		return 0.0
	return (shape.shape as CircleShape2D).radius


## The body's inertia is set rather than left automatic so the torque maths has one
## known number: `m * r^2 / 2` is the circle's own moment (Godot computes exactly this
## for a CircleShape2D), so the turn torque stays mass-scaled and no hull needs a
## number of its own. A scene without a hull circle leaves the body automatic.
func _angular_inertia() -> float:
	var radius := _hull_radius()
	if radius <= 0.0:
		return 0.0
	return 0.5 * _hull_mass() * radius * radius


## ENGINE_SPEC section 13's handling column, as the accelerations ruling 8 turns into
## forces. The engine arithmetic is the hybrid model's own (max_speed / accel_time,
## max_speed / coast_time, turn_rate / turn_spinup), so nothing is retuned: the
## section 3.2 times stay the shipped times.
func _accel_rate() -> float:
	if _stats.accel_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.accel_time


func _coast_rate() -> float:
	if _stats.coast_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.coast_time


func _spin_rate() -> float:
	if _stats.turn_spinup <= 0.0:
		return _stats.turn_rate
	return _stats.turn_rate / _stats.turn_spinup


## Coast decay, sized from coast_time: 1 / coast_time is the decay rate, so a hull
## with nothing commanded loses most of its speed over its class's coast_time (the
## hybrid model's linear ramp reached zero there; a real damper arrives with an
## exponential tail instead, and both envelopes are measured in the migration probe).
## The commanded coast (throttle released, autopilot ramping down) still reaches
## zero at coast_time, because that deceleration is the class's own coast rate and the
## damp is compensated for along the thrust axis (`_step_speed`).
func _linear_damp() -> float:
	if _stats == null or _stats.coast_time <= 0.0:
		return 0.0
	return 1.0 / _stats.coast_time


## The same sizing for the angular axis, from turn_spinup: a spinning hull with
## nothing commanded loses its turn rate over its class's spin-up time.
func _angular_damp() -> float:
	if _stats == null or _stats.turn_spinup <= 0.0:
		return 0.0
	return 1.0 / _stats.turn_spinup


## Hand the launch snapshot's mass and the class's damp to the body. The scene carries
## only the physics *contract* (contact monitor, no sleep, no gravity, damp modes);
## every number here comes from the snapshot, so no class value lives in two places.
func _apply_rigid_body() -> void:
	if _body == null:
		return
	_body.mass = _hull_mass()
	_body.inertia = _angular_inertia()
	_body.linear_damp = _linear_damp()
	_body.angular_damp = _angular_damp()
	_last_velocity = _body.linear_velocity
	if _stats != null and _hull_mass() <= UNRESOLVED_HULL_MASS:
		push_warning(
			"PlayerShip: ShipStats carries no hull_mass for this hull; flying at the "
			+ "unit mass (collision damage and impulses are charged per mass)."
		)


func _max_speed() -> float:
	return _stats.max_speed * _boost_multiplier()


## The hull's speed along its own nose, which is the axis the thrust law works on.
func _velocity_along_heading() -> float:
	if _body == null:
		return 0.0
	return _body.linear_velocity.dot(Vector2.RIGHT.rotated(_heading()))


## Boosters (section 3.2, 09 section 3.5): the fitted ids arrive in ShipStats and
## their activation numbers are ShipFit's module data, so nothing is duplicated
## here. The fold-blink seam is `has_booster`: a fit carrying `b_fold` activates
## nothing in v1 (its movement lands with slice 4).
func _update_boosters(delta: float) -> void:
	if _boost_cooldown > 0.0:
		_boost_cooldown = maxf(_boost_cooldown - delta, 0.0)
	if _boost_remaining > 0.0:
		_boost_remaining = maxf(_boost_remaining - delta, 0.0)
	if _boost_remaining > 0.0 or _boost_cooldown > 0.0:
		return
	if not has_booster(BOOSTER_AFTERBURNER):
		return
	if not InputMap.has_action(BOOST_ACTION) or not Input.is_action_pressed(BOOST_ACTION):
		return
	var effect := _booster_effect(BOOSTER_AFTERBURNER)
	_boost_remaining = float(effect.get(&"duration", 0.0))
	_boost_cooldown = float(effect.get(&"cooldown", 0.0))


func _boost_multiplier() -> float:
	if _boost_remaining <= 0.0:
		return 1.0
	return float(_booster_effect(BOOSTER_AFTERBURNER).get(&"boost_speed_mult", 1.0))


func _booster_effect(id: StringName) -> Dictionary:
	var module: Dictionary = ShipFit.MODULES.get(id, {})
	var effects: Variant = module.get(&"effects", {})
	if effects is Dictionary:
		return effects
	var empty: Dictionary = {}
	return empty


## 09 section 4.5 / ENGINE_SPEC section 4.3: the W slot buys the tool, so the mount
## follows the resolved fit. A fit without `w_mining` carries no laser node at all
## (game.gd's reticle push and the trigger both read `_laser` being absent), and a
## later hull swap to a fit without the module releases the node again.
func _sync_mining_laser() -> void:
	if not _has_mining_module():
		_release_mining_laser()
		return
	_mount_mining_laser()
	_bind_laser()


func _has_mining_module() -> bool:
	return _fit_ids.has(MINING_MODULE)


func _release_mining_laser() -> void:
	if _laser == null:
		return
	_laser_active = false
	remove_child(_laser)
	_laser.queue_free()
	_laser = null


## The laser scene is W3's; it is mounted by guarded path, the same convention
## game.gd uses for the HUD, so this scene loads before W3's file lands.
func _mount_mining_laser() -> void:
	if _laser != null:
		return
	var existing := get_node_or_null(NodePath(MINING_LASER_NODE))
	if existing != null and not existing.is_queued_for_deletion():
		_laser = existing
		return
	if not ResourceLoader.exists(MINING_LASER_SCENE):
		return
	var packed := load(MINING_LASER_SCENE) as PackedScene
	if packed == null:
		return
	_laser = packed.instantiate()
	_laser.name = MINING_LASER_NODE
	add_child(_laser)


func _bind_laser() -> void:
	if _laser == null or _stats == null:
		return
	if _laser.has_method(&"bind"):
		_laser.call(&"bind", _stats)


## Hold `mine` (E) to fire the mining laser (ENGINE_SPEC section 4.3). The laser
## owns its range, cycle and targeting; the ship only holds the trigger. The W-slot
## gate is repeated here so a laser node authored into the scene cannot be fired by
## a fit that does not carry `w_mining`.
func _update_mining_laser() -> void:
	if not _has_mining_module() or _laser == null or not _laser.has_method(&"set_active"):
		return
	var active := InputMap.has_action(MINE_ACTION) and Input.is_action_pressed(MINE_ACTION)
	if active == _laser_active:
		return
	_laser_active = active
	_laser.call(&"set_active", active)


func _release_state() -> void:
	if _state == null:
		return
	if _state.hull_changed.is_connected(_on_hull_changed):
		_state.hull_changed.disconnect(_on_hull_changed)
	if _state.shield_changed.is_connected(_on_shield_changed):
		_state.shield_changed.disconnect(_on_shield_changed)


func _on_hull_changed(current: float, _maximum: float) -> void:
	_note_vitals(_last_hull, current)
	_last_hull = current


func _on_shield_changed(current: float, _maximum: float) -> void:
	_note_vitals(_last_shield, current)
	_last_shield = current


## Regen raises a pool; only a decrease is damage (section 4.2's regen delay
## lands in slice 2, and the check keeps the warp channel from breaking on it).
func _note_vitals(previous: float, current: float) -> void:
	if not _vitals_seeded or current >= previous:
		return
	_damage_quiet = 0.0
	damage_taken.emit(previous - current)
