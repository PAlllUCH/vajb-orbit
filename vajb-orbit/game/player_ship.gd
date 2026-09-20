class_name PlayerShip
extends Node2D
## The player's hull: hybrid flight (ENGINE_SPEC section 3.1), mass-scaled
## inertia with the arrive-steering autopilot (section 3.2), the booster seam,
## the mining-laser mount (W3's scene, mounted only when the resolved fit spends a
## W slot on `w_mining`) and the rock collision body (section 6).
## Flight reads *only* the ShipStats snapshot ShipFit resolves (section 3.3):
## the per-class handling column and the booster activation numbers stay in
## ship_fit.gd, so no flight number is duplicated here. The constants that do
## live here are the section 13 values that belong to no class and to no module
## (brake multiplier, arrive-steering radii) plus the section 7 warp quiet time.
## Contract: ENGINE_SPEC sections 3, 6, 7, 9, 13; engine-wave-1 brief section W2.

## Raised when the live pools lose points (hull or shield). The warp channel
## breaks on damage (ENGINE_SPEC section 7); game.gd listens to this instead of
## re-deriving "was that regen?" from the PlayerState signals.
signal damage_taken(amount: float)

const MINING_LASER_NODE: StringName = &"MiningLaser"
const MINING_LASER_SCENE := "res://game/mining_laser.tscn"

## 09 section 4.5 (the owner's mining-laser rule) and ENGINE_SPEC section 4.3/6:
## the mining laser is the `w_mining` tool that occupies a **W slot**, Tier I,
## draw 1. Buying the ability with a gun slot is the whole Delver/Fighter
## trade-off, so the module is the gate: a fit without it has spent no W slot and
## carries no laser and no trigger.
const MINING_MODULE: StringName = &"w_mining"

## ENGINE_SPEC section 6, "Rocks are solid: ships collide with them". The scene's
## `HullBody` (a CharacterBody2D at local zero) carries the ship's own physics layer
## and masks only the rock layer (Asteroid.COLLISION_LAYER), so rocks stop flight and
## no unrelated body can. Its CircleShape2D radius is the hull's half-length: the
## shipped sprite's 905 px at this scene's 0.0663 hull scale is 60.0 u long, the same
## art-derived basis asteroid.gd's LOOK_WIDTHS reads. A circle is rotation-invariant
## and the long axis dominates, so a side-on stop leaves ~17 u of gap to the sprite's
## edge. Reversal is one node in the scene.
const HULL_BODY_NODE: StringName = &"HullBody"

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

var _stats: ShipStats = null
var _state: PlayerState = null
var _body: CharacterBody2D = null
var _laser: Node = null
var _laser_active := false
var _fit_ids: Array[StringName] = []

var _heading := 0.0
var _speed := 0.0
var _turn_speed := 0.0

var _move_target := Vector2.ZERO
var _has_move_target := false

var _boost_remaining := 0.0
var _boost_cooldown := 0.0

var _damage_quiet := WARP_DAMAGE_QUIET
var _last_hull := 0.0
var _last_shield := 0.0
var _vitals_seeded := false


func _ready() -> void:
	add_to_group(&"player_ship")
	_body = get_node_or_null(NodePath(HULL_BODY_NODE)) as CharacterBody2D
	_sync_mining_laser()


## Launch handshake (pinned interface): the resolved snapshot plus the scene's
## live pools. Safe to call again on a hull swap; the old state is released.
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


func _physics_process(delta: float) -> void:
	_update_boosters(delta)
	_update_mining_laser()
	_damage_quiet += delta
	if _stats == null:
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
		if absf(desired_speed) > absf(_speed):
			rate = _accel_rate()
	else:
		desired_turn = turn * _stats.turn_rate
		desired_speed = throttle * _max_speed()
		if not is_zero_approx(throttle):
			rate = _accel_rate() * (BRAKE_MULT if throttle < 0.0 else 1.0)
	_step_turn(desired_turn, delta)
	_step_speed(desired_speed, rate, delta)
	_advance(delta)


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
	var error := wrapf(bearing - _heading, -PI, PI)
	return clampf(error, -1.0, 1.0) * _stats.turn_rate


## Arrive steering: the desired speed falls from the class maximum to zero across
## SLOW_DOWN_RADIUS and reaches zero at ARRIVE_RADIUS, so the autopilot stops in
## the ring instead of coasting through it. A target behind the bow holds speed
## at zero while the ship comes about (no reverse thrust in autopilot).
func _order_speed() -> float:
	var to_target := _move_target - global_position
	var error := wrapf(to_target.angle() - _heading, -PI, PI)
	if absf(error) > PI * 0.5:
		return 0.0
	var fraction := clampf((to_target.length() - ARRIVE_RADIUS) / SLOW_DOWN_RADIUS, 0.0, 1.0)
	return _max_speed() * fraction


## Angular inertia: the turn rate spins up over `turn_spinup` and damps down the
## same way (section 3.2).
func _step_turn(desired_turn: float, delta: float) -> void:
	if _stats.turn_spinup > 0.0:
		var step := _stats.turn_rate / _stats.turn_spinup * delta
		_turn_speed = move_toward(_turn_speed, desired_turn, step)
	else:
		_turn_speed = desired_turn
	_heading = wrapf(_heading + _turn_speed * delta, -PI, PI)
	rotation = _heading


## Linear inertia: speed chases the target at `rate`, which is the class accel
## rate under thrust, BRAKE_MULT times that under S, and the coast rate with no
## input (section 3.2).
func _step_speed(desired_speed: float, rate: float, delta: float) -> void:
	_speed = move_toward(_speed, desired_speed, rate * delta)


## Linear motion. Rocks are solid (ENGINE_SPEC section 6), so the step goes through
## the hull's collision body when there is one: the body takes the motion, the travel
## it was allowed is applied to the ship and the body is put back at local zero (the
## ship owns the transform, the body only owns the shape). Momentum is untouched, so
## a blocked step costs the ship nothing but the distance, and turning away then
## thrusting leaves a rock. A ship outside the tree, or a scene without the body,
## moves exactly as it did before.
func _advance(delta: float) -> void:
	var motion := Vector2.RIGHT.rotated(_heading) * _speed * delta
	if _body == null or not is_inside_tree():
		position += motion
		return
	var travelled := motion
	var collision := _body.move_and_collide(motion)
	if collision != null:
		travelled -= collision.get_remainder()
	position += travelled
	_body.position = Vector2.ZERO


func _accel_rate() -> float:
	if _stats.accel_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.accel_time


func _coast_rate() -> float:
	if _stats.coast_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.coast_time


func _max_speed() -> float:
	return _stats.max_speed * _boost_multiplier()


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
