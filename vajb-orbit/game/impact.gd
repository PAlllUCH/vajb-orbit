class_name Impact
extends RefCounted
## Push physics: the arithmetic of ENGINE_SPEC section 4.2 items 6-8 (rulings 15/16)
## in one place (body-body collision damage, a shot's recoil, a hit's knockback and
## a detonation's shockwave), with the section 13 constants they are made of.
##
## Single owner for those numbers: callers pass masses, velocities and distances in
## and get a damage figure or an impulse back. Nothing here reads a node, a scene or
## a catalogue, so the helpers are equally usable by the player hull, slice 2's
## weapons and projectile code, and a headless probe.
##
## Units. Mass is the section 13 hull-mass column (tonnes read as the simulation's
## own unit), distance is world units and time is seconds, so an acceleration is
## units/s^2, a force is mass * units/s^2 and an impulse is mass * units/s (the
## "impulse-units" of EXPLOSION_P0). COLLISION_FACTOR is the section 16 worked
## example's own factor: a Fighter (80 t) into a flat wall at 450 u/s is
## 0.5 * 80 * 450^2 * 2.0e-5 = 162 damage, about a quarter of its 700 hull.
##
## Contract: ENGINE_SPEC section 4.2 items 6-8, section 13 (collision, recoil and
## explosion rows), section 15 (the collision / impulse / explosion checks) and the
## slice-0 brief's pinned interface item 4.

## ENGINE_SPEC section 13: the collision-damage scale, and the closing speed below
## which a contact is free: light bumps (docking, nudging a rock) cost nothing.
const COLLISION_FACTOR := 2.0e-5
const COLLISION_MIN_DV := 40.0

## ENGINE_SPEC section 13: the share of a hit's remaining kinetic energy that reaches
## the target (section 4.2 item 7), the detonation pressure at the epicenter, and the
## window the blast front takes to deliver it (section 4.2 item 8).
const KNOCKBACK_FRACTION := 0.40
const EXPLOSION_P0 := 4000.0
const EXPLOSION_WINDOW := 0.2


## ENGINE_SPEC section 4.2 item 6, ruling 15: an impact deals
## `0.5 * mass_a * mass_b/(mass_a + mass_b) * dv^2 * COLLISION_FACTOR` to **both**
## sides. The reduced mass is what makes that one number: it is symmetric, so
## swapping the arguments changes nothing, and it degrades to `0.5 * mass_a` for a
## peer that does not yield (see `_reduced_mass`), which is the flat-wall case the
## section 16 worked example computes.
##
## Returns 0 below COLLISION_MIN_DV or when either side carries no mass at all.
static func collision_damage(mass_a: float, mass_b: float, relative_velocity: float) -> float:
	var dv := absf(relative_velocity)
	if dv < COLLISION_MIN_DV:
		return 0.0
	var reduced := _reduced_mass(mass_a, mass_b)
	if reduced <= 0.0:
		return 0.0
	return 0.5 * reduced * dv * dv * COLLISION_FACTOR


## ENGINE_SPEC section 4.2 item 7, section 13 (`KNOCKBACK_FRACTION` = 0.40 of the
## projectile's remaining kinetic energy): the share of the hit a target receives
## along the impact line. The caller applies it: the impulse that carries `E` of
## energy into a hull of mass `M` is `sqrt(2 * E * M)`, which needs the target's own
## mass and therefore stays with the hit site, which knows both bodies.
static func knockback(remaining_speed: float, projectile_mass: float) -> float:
	var speed := absf(remaining_speed)
	return KNOCKBACK_FRACTION * 0.5 * maxf(projectile_mass, 0.0) * speed * speed


## ENGINE_SPEC section 4.2 item 7, the shooter's half: firing applies
## `projectile_mass * muzzle_velocity` opposite the muzzle. The doc names it a force;
## a shot leaves in a single physics step, so the same magnitude lands as an impulse
## (`PlayerShip.apply_recoil` / `RigidBody2D.apply_central_impulse`). Returns the
## magnitude; the caller owns the direction, which is the muzzle's.
static func recoil_impulse(projectile_mass: float, muzzle_speed: float) -> float:
	return maxf(projectile_mass, 0.0) * absf(muzzle_speed)


## ENGINE_SPEC section 4.2 item 8, section 13: `I(d) = P0 / (1 + d^2)`
## "impulse-units" at distance `d`: EXPLOSION_P0 at the epicenter, falling with the
## square (half at d = 1 u, a percent at d = 10 u, gone by a few hull lengths), so
## the curve itself is the range and no radius constant is needed.
static func explosion_impulse(distance: float) -> float:
	var d := absf(distance)
	return EXPLOSION_P0 / (1.0 + d * d)


## ENGINE_SPEC section 4.2 item 8, ruling 16: push `body` away from `epicenter` with
## `explosion_impulse(distance)` of momentum, delivered **across** `window` seconds
## rather than in one blow: a blast front is a pressure over EXPLOSION_WINDOW, which
## is why the momentum is sliced over the window's physics ticks instead of being
## handed over as a single kick. Callers: slice 2's detonations, ship deaths and
## slice 0's cleaving (they pass `RigidBody2D` hulls/rocks and, for the player,
## `PlayerShip.impact_body`).
##
## A body outside the tree (no tween to host the slices), a non-positive window or a
## window shorter than one tick takes the whole impulse at once; a body sitting
## exactly on the epicenter has no outward direction and is left alone.
static func apply_shockwave(epicenter: Vector2, body, window: float) -> void:
	var rigid := body as RigidBody2D
	if rigid == null:
		return
	var offset := rigid.global_position - epicenter
	if offset.is_zero_approx():
		return
	var impulse := explosion_impulse(offset.length())
	if impulse <= 0.0:
		return
	var momentum := offset.normalized() * impulse
	var ticks := int(roundf(window * float(Engine.physics_ticks_per_second)))
	if ticks <= 1 or not rigid.is_inside_tree():
		rigid.apply_central_impulse(momentum)
		return
	var slice := momentum / float(ticks)
	var interval := window / float(ticks)
	var push := func() -> void:
		rigid.apply_central_impulse(slice)
	var tween := rigid.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for _tick in ticks:
		tween.tween_callback(push)
		tween.tween_interval(interval)


## The reduced mass `mass_a * mass_b / (mass_a + mass_b)`, with the immovable case
## folded in: a peer that carries no mass of its own (a wall, a station, any
## collision object that is not a rigid body, which the ship reports as INF) behaves
## as an infinite mass, so the reduced mass is the moving side alone. `mass_b = 0`
## counts as immovable too (Godot refuses a zero-mass rigid body, so a zero means
## "this peer is not simulated", not "this peer weighs nothing"); swapping the
## arguments therefore can only change the answer between two simulated bodies,
## where it cancels.
static func _reduced_mass(mass_a: float, mass_b: float) -> float:
	var a := maxf(mass_a, 0.0)
	if a <= 0.0 or not is_finite(a):
		return 0.0
	if not is_finite(mass_b) or mass_b <= 0.0:
		return a
	return a * mass_b / (a + mass_b)
