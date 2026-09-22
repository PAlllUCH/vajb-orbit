@tool
extends McpTestSuite
## Suite s2_6_beam: the beam's own feel - FX_SPEC section 1.6's 2026-09-22 amendment and
## the mining shaft's own chip read (L65). Slice S2.6's AC3 (the drawn beam ends at the
## pinned sink and the contact FX scatter inside the pinned disc) and AC4 (the mining beam
## plays the chip sparks).
##
## Two numbers, both from CONTRACTS section 14 and FX_SPEC section 1.6's amendment:
## `BEAM_SINK 0.45` (the drawn shaft ends `hit_point.lerp(body_centre, 0.45)`) and
## `HIT_FX_JITTER_MULT 0.35` (the contact FX spawn at a uniform random point in a disc of
## `clamp(0.35 x collision radius, 8, 48)` u around the resolved hit, the radius being the
## target's own). Both are drawn-line/effect-position only: the resolved contact, the
## damage and the pickups never move, which is measured here too.
##
## Everything is synchronous - the runner never awaits a frame - so the beam is driven the
## way the sibling suites drive it: `_apply_beam` (the branch `_fire_beam` calls once the
## ray has resolved) for the contact reads, `tick` for a full fire frame, and the mining
## shaft's own seams (`_draw_beam`, `_apply_cycle`) with the target planted exactly where
## `_acquire`'s ray would plant it. A physics ray cannot see a body added in the same frame
## headless, which is why the ray itself is not this suite's route.
##
## Contract: docs/CONTRACTS.md section 14 (the beam bullet), docs/design/FX_SPEC.md
## section 1.6 + its 2026-09-22 amendment, `.agents/gen/_state/LOW_BACKLOG.md` L65.

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FxScript := preload("res://game/fx.gd")

const MINING_SCENE := "res://game/mining_laser.tscn"
const AUDIO_SERVICE: StringName = &"AudioManager"
## The chip sparks' own master, as the effect row names it: the row draws the **cut frame**
## (`fx_mining_beam_f1.png`), so a match by master path has to name that file and not the
## sheet it was cut from.
const CHIP_SHEET := "res://assets/fx/fx_mining_beam_f1.png"
const RIPPLE_SHEET := "res://assets/fx/fx_shield_ripple_f1.png"
const EXPLOSION_SHEET := "res://assets/fx/fx_explosion_f1.png"
const PICKUP_SCRIPT := "res://game/pickup.gd"

## The group a hull's sink is reached through (`WeaponComponent.SHIP_GROUPS`), so both the
## bare collider a ray hands back and the ship that takes the damage are in the fixture.
const SHIP_GROUP: StringName = &"npc_ship"

const AIM_DISTANCE := 300.0
const BEAM_FRAME := 0.016

## The beam's per-contact rate guard, so one read happens per call: the frame handed to
## `_apply_beam` is the guard's own interval. Kept here and asserted against the shipped
## constant, so the sample count cannot drift from the code it is sampling.
const READ_FRAME := 0.25

## The rocket's own distance off the ray's line: inside `Projectile.HIT_RADIUS` (4 u, or
## `_rocket_on_segment` would not find it) and off-axis, which is what makes the sink
## measurable - on the line the resolved point *is* the body's centre, and a sink there
## moves nothing.
const SINK_OFFSET := 3.0

## The scatter sample count per target. With a uniform disc, `P(no sample of 60 reaches
## 80 % of the radius)` is 0.64^60 = 1e-12, so the "the disc is really used" row cannot
## flake; the mean's own standard error is 0.030 x radius against a 0.12 x radius band.
const SAMPLES := 60

const TOLERANCE := 0.001


## A hull that answers the pinned sink the way a hull does, with a pool a hit can empty.
## `hull_taken` counts only what reached the hull, so a shield that absorbed a hit leaves it
## at zero - which is also the measurement that the new scatter changed nothing about the
## damage.
class StubHull extends Node2D:
	var shield := 0.0
	var hull_taken := 0.0
	var calls := 0

	func shield_up() -> bool:
		return shield > 0.0

	func take_damage(amount: float, bypass_shield: bool = false, _ctx: Dictionary = {}) -> void:
		calls += 1
		if not bypass_shield and shield > 0.0:
			shield = maxf(shield - amount, 0.0)
			return
		hull_taken += amount

	func apply_recoil(_velocity: Vector2, _mass: float) -> void:
		pass

	func impact_body() -> RigidBody2D:
		return null

	func velocity() -> Vector2:
		return Vector2.ZERO


var _root: Node2D = null

## The audio manager's shared round-robin cursors, captured before a test touches them and
## put back when the suite ends: `_fire_beam` plays the laser pool, and a cursor left
## advanced would move `test_weapon_fx_f1`'s "take 0 in order" row under a suite that has
## nothing to do with it. `test_flight_beam_g2`'s own cure, for the same reason.
var _pool_state: Dictionary = {}
var _had_pool_state := false


func suite_name() -> String:
	return "s2_6_beam"


func suite_setup(_ctx: Dictionary) -> void:
	_snapshot_pools()
	_root = Node2D.new()
	_root.name = &"S26BeamFixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear()
	_clear_loops()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	_restore_pools()


func setup() -> void:
	_clear()
	_clear_loops()


## ---------------------------------------------------------------------------
## 1. The drawn beams end at the pinned sink (AC3, the line half)
## ---------------------------------------------------------------------------


func test_both_drawn_beams_end_at_the_pinned_sink() -> void:
	assert_eq(WeaponScript.BEAM_SINK, 0.45, "the pinned sink is 0.45 of the way to the centre")
	assert_eq(
		MiningLaserScript.BEAM_SINK,
		WeaponScript.BEAM_SINK,
		"and the mining shaft sinks by the same number, so the two beams read alike"
	)
	_assert_weapon_beam_sinks()
	_assert_mining_beam_sinks()


## The weapon beam on the one route that resolves a target without a physics frame: a
## destructible shot on the segment. The rocket sits off the ray's line, so the resolved
## point and the body's centre differ by exactly `SINK_OFFSET` u - and the line has to end
## `BEAM_SINK` of that distance in, while the kill's blast stays where the ray landed.
func _assert_weapon_beam_sinks() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var rocket := _staged_rocket(guns, Vector2(60.0, SINK_OFFSET))
	var centre := rocket.global_position
	## The point the ray resolves for a shot: the closest point of the segment (the beam
	## runs along +x from the muzzle), which is what the blast must stay on.
	var resolved := Vector2(60.0, 0.0)
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	guns.call(&"set_firing", false)
	var core := _beam_line(guns)
	assert_eq(core.points.size(), 2, "the shaft runs from the muzzle to its drawn end")
	if core.points.size() != 2:
		return
	var drawn := core.points[1]
	var expected := resolved.lerp(centre, WeaponScript.BEAM_SINK)
	assert_true(
		_near(drawn.distance_to(centre), expected.distance_to(centre), TOLERANCE),
		"the drawn end is the resolved point pulled 45 %% towards the body's centre "
		+ "(drawn %.3f u out, expected %.3f u)" % [drawn.distance_to(centre), SINK_OFFSET * 0.55]
	)
	assert_true(
		_near(drawn.x, resolved.x, TOLERANCE),
		"a sink does not slide the shaft along the ray (x %.3f, the ray's own %.3f)"
		% [drawn.x, resolved.x]
	)
	assert_true(
		drawn.distance_to(centre) < resolved.distance_to(centre),
		"and it is strictly deeper into the object than the surface point was"
	)
	## The other half of the pin: what is drawn moved, what was resolved did not.
	var blasts := _fx_nodes_from(EXPLOSION_SHEET)
	assert_eq(blasts.size(), 1, "the shot down rocket takes section 1.4's blast")
	if blasts.is_empty():
		return
	assert_true(
		_near((blasts[0] as Node2D).global_position.distance_to(resolved), 0.0, TOLERANCE),
		"and the blast stays on the point the ray resolved, not on the drawn end"
	)


## The mining shaft, driven at the seam `_physics_process` reaches once a rock is under the
## cursor (`_draw_beam`, with `_target`/`_hit_point` planted as `_acquire` plants them). The
## rock is Large, so its own 66 u radius is what the sink is measured against.
func _assert_mining_beam_sinks() -> void:
	var laser := _laser()
	var rock := _rock(AsteroidScript.SIZE_LARGE, Vector2(200.0, 0.0), 20)
	var radius := float(rock.call(&"world_radius"))
	assert_true(_near(radius, 66.0, TOLERANCE), "the Large look's own collision radius (%.1f)" % radius)
	var contact := rock.global_position + Vector2(radius, 0.0)
	laser.set(&"_target", rock)
	laser.set(&"_hit_point", contact)
	laser.call(&"_draw_beam")
	var core := _beam_line(laser)
	assert_eq(core.points.size(), 2, "the shaft runs from the muzzle to its drawn end")
	if core.points.size() != 2:
		return
	var drawn := laser.to_global(core.points[1])
	var expected := contact.lerp(rock.global_position, MiningLaserScript.BEAM_SINK)
	assert_true(
		_near(drawn.distance_to(expected), 0.0, TOLERANCE),
		"the mining shaft's drawn end is the resolved contact pulled 45 %% towards the rock"
	)
	assert_true(
		_near(drawn.distance_to(rock.global_position), radius * (1.0 - MiningLaserScript.BEAM_SINK)),
		"so it stops %.1f u short of the rock's centre, where the rim was %.1f u out"
		% [drawn.distance_to(rock.global_position), radius]
	)
	assert_true(
		_near((laser.call(&"target_position") as Vector2).distance_to(contact), 0.0, TOLERANCE),
		"while the contact the reticle reads is still the point the ray resolved"
	)


## ---------------------------------------------------------------------------
## 2. The contact FX scatter inside the pinned disc (AC3, the effect half)
## ---------------------------------------------------------------------------


func test_the_contact_fx_scatters_in_the_pinned_disc_of_the_targets_own_radius() -> void:
	assert_eq(READ_FRAME, WeaponScript.BEAM_HIT_INTERVAL, "one read per guard interval")
	_assert_pinned_disc_arithmetic()
	_assert_radius_sources()
	## The gun's own rock read, one burst per frame the rate guard opens.
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var state: Variant = rig[&"state"]
	var small := _rock(AsteroidScript.SIZE_SMALL, Vector2(0.0, 120.0), 10000)
	_assert_scatters_in(_chip_offsets(guns, state, small), 8.4, "a Small rock's 24 u body")
	var large := _rock(AsteroidScript.SIZE_LARGE, Vector2(0.0, -400.0), 10000)
	_assert_scatters_in(_chip_offsets(guns, state, large), 23.1, "a Large rock's 66 u body")


## The amendment's own arithmetic, off the shipped constants: the derivation numbers its
## table names (8.4 / 14.7 / 23.1 / 10.5), the floor, and the ceiling that only a body
## larger than anything shipped could reach.
func _assert_pinned_disc_arithmetic() -> void:
	assert_eq(WeaponScript.HIT_FX_JITTER_MULT, 0.35, "the pinned multiplier")
	assert_eq(MiningLaserScript.HIT_FX_JITTER_MULT, 0.35, "shared with the mining shaft")
	assert_eq(WeaponScript.HIT_FX_JITTER_MIN, 8.0, "the pinned floor")
	assert_eq(WeaponScript.HIT_FX_JITTER_MAX, 48.0, "the pinned ceiling")
	assert_eq(MiningLaserScript.HIT_FX_JITTER_MIN, 8.0, "the mining shaft's floor")
	assert_eq(MiningLaserScript.HIT_FX_JITTER_MAX, 48.0, "and its ceiling")
	assert_true(_near(_disc(24.0), 8.4), "a Small rock's 24 u radius gives the pin's 8.4 u")
	assert_true(_near(_disc(42.0), 14.7), "a Medium's 42 u gives 14.7 u")
	assert_true(_near(_disc(66.0), 23.1), "a Large's 66 u gives 23.1 u")
	assert_true(_near(_disc(30.0), 10.5), "a hull's 30 u collider gives 10.5 u")
	assert_true(_near(_disc(0.0), 8.0), "a radius-less target lands on the 8 u floor")
	assert_true(
		_near(_disc(ProjectileScript.HIT_RADIUS), 8.0),
		"and so does a destructible shot's own 4 u detection circle, far below the floor"
	)
	assert_true(_near(_disc(200.0), 48.0), "the ceiling is where the disc stops growing")


## The radius the disc is measured from, read off the shipped objects themselves.
func _assert_radius_sources() -> void:
	var small := _rock(AsteroidScript.SIZE_SMALL, Vector2(400.0, 400.0), 5)
	var medium := _rock(AsteroidScript.SIZE_MEDIUM, Vector2(500.0, 400.0), 5)
	var large := _rock(AsteroidScript.SIZE_LARGE, Vector2(600.0, 400.0), 5)
	assert_true(_near(_radius(small), 24.0), "a Small rock answers its own world_radius() (24 u)")
	assert_true(_near(_radius(medium), 42.0), "a Medium answers its own 42 u")
	assert_true(_near(_radius(large), 66.0), "a Large answers its own 66 u")
	var hull := _hull(100.0)
	assert_true(
		_near(_radius(hull[&"ship"]), 30.0),
		"a hull's radius is its CollisionShape2D's own figure (30 u), read through the sink"
	)
	assert_true(
		_near(_radius(hull[&"body"]), 30.0),
		"and the bare collider a ray hands back reads the same figure"
	)
	var bare := _hull(100.0, 0.0)
	assert_true(
		_near(_radius(bare[&"ship"]), 0.0),
		"a hull whose art is missing carries no shape, and the floor is what binds it"
	)
	var shot := _staged_rocket(_rig([&"laser"])[&"guns"], Vector2(60.0, 0.0))
	assert_true(
		_near(_radius(shot), ProjectileScript.HIT_RADIUS),
		"a destructible shot carries no radius but its own 4 u detection circle"
	)


## ---------------------------------------------------------------------------
## 3. A bare hull draws no sheet; the shield ring is the third reader
## ---------------------------------------------------------------------------


func test_a_bare_hull_draws_no_sheet_and_the_shield_ring_scatters() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var state: Variant = rig[&"state"]
	## F7 / the amendment: a beam on a bare hull spawns no sheet at all, and this wave adds
	## none - so the readers that do fire are the chip sparks and the ring, exactly three
	## call sites between them.
	var bare := _hull(0.0)
	_beam_hit(guns, state, bare[&"body"], (bare[&"body"] as Node2D).global_position)
	assert_eq(_fx_nodes_from(RIPPLE_SHEET).size(), 0, "a beam on a bare hull draws no shield ring")
	assert_eq(
		_fx_nodes_from(CHIP_SHEET).size(), 0, "and no chip burst, because a hull is not a rock"
	)
	assert_eq(
		(audio.call(&"sounding_loops") as Array).size(),
		0,
		"with no bed left sounding under a shield that was never up"
	)
	assert_true(
		not (bare[&"ship"] as StubHull).shield_up(),
		"the read really was an unshielded one (the hull pool, not the shield's)"
	)
	## The ring itself, the third reader, scattering inside the hull's own 10.5 u disc.
	var guarded := _hull(10000.0)
	_assert_scatters_in(_ripple_offsets(guns, state, guarded[&"body"]), 10.5, "a 30 u hull")
	assert_true(
		(guarded[&"ship"] as StubHull).shield < 10000.0,
		"the sampled hits were absorbed by the shield, not carried to the hull"
	)
	## A hull with no collider at all - the shape a stub fixture has, and an NPC whose art
	## is missing - takes the pin's 8 u floor rather than a smaller disc.
	var floored := _hull(10000.0, 0.0)
	_assert_scatters_in(_ripple_offsets(guns, state, floored[&"body"]), 8.0, "a radius-less hull")


## ---------------------------------------------------------------------------
## 4. The mining shaft's own chip read (AC4, L65)
## ---------------------------------------------------------------------------


func test_the_mining_beam_draws_the_chip_sparks_on_its_own_chip() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_eq(
		WeaponScript.CHIP_CUE,
		MiningLaserScript.CHIP_CUE,
		"the shaft and a gun play the same S8 take, so the cue and the burst are one event"
	)
	var laser := _laser()
	var rock := _rock(AsteroidScript.SIZE_MEDIUM, Vector2(120.0, 0.0), 20)
	var contact := rock.global_position + Vector2(float(rock.call(&"world_radius")), 0.0)
	laser.set(&"_target", rock)
	laser.set(&"_hit_point", contact)
	var pickups_before := _pickups()
	laser.call(&"_apply_cycle")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		MiningLaserScript.CHIP_CUE,
		"a completed extraction cycle plays S8's chip transient (it drew nothing before L65)"
	)
	assert_eq(int(rock.get(&"yield_units")), 19, "the cycle mined its one unit")
	var drawn := _fx_nodes_from(CHIP_SHEET)
	assert_eq(drawn.size(), 1, "and draws section 1.6's chip-sparks burst beside it")
	if drawn.is_empty():
		return
	var burst := drawn[0] as Node2D
	assert_true(
		burst.get_parent() == _root,
		"the burst hangs on the contact's own world node, not on the shaft that fired it"
	)
	assert_true(
		burst.global_position.distance_to(contact) <= _disc(42.0) + TOLERANCE,
		"inside the Medium rock's own %.1f u disc (measured %.3f u)"
		% [_disc(42.0), burst.global_position.distance_to(contact)]
	)
	## One chip event, one burst: the second cycle is the second chip, not a per-frame read.
	laser.call(&"_apply_cycle")
	assert_eq(
		_fx_nodes_from(CHIP_SHEET).size(), 2, "a second cycle draws a second burst, never two"
	)
	assert_eq(int(rock.get(&"yield_units")), 18, "and mines its second unit")
	## The other half of the pin: only the effect scattered. The ore still lands on the
	## point the ray resolved.
	var fresh: Array[Node] = []
	for pickup: Node in _pickups():
		if not pickups_before.has(pickup):
			fresh.append(pickup)
	assert_eq(fresh.size(), 2, "two cycles yield two pickups")
	for pickup: Node in fresh:
		assert_true(
			_near((pickup as Node2D).global_position.distance_to(contact), 0.0, TOLERANCE),
			"and every pickup sits on the resolved contact, never on the scattered effect"
		)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A mounted `WeaponComponent` under a stub hull: a live `PlayerState` and the fit under
## test, aimed `AIM_DISTANCE` to starboard (the rig the F1/F4 suites use).
func _rig(weapon_ids: Array) -> Dictionary:
	var hull := StubHull.new()
	hull.name = &"RigHull"
	_root.add_child(hull)
	var guns := WeaponScript.new() as Node2D
	guns.name = &"WeaponComponent"
	hull.add_child(guns)
	var state: Variant = PlayerStateScript.new()
	state.call(&"setup")
	guns.call(&"setup", null, state)
	var ids: Array[StringName] = []
	for id: Variant in weapon_ids:
		ids.append(StringName(id))
	guns.call(&"set_fitted", ids)
	guns.call(&"set_aim_point", guns.global_position + Vector2(AIM_DISTANCE, 0.0))
	return {&"hull": hull, &"guns": guns, &"state": state}


## The shipped mining shaft, mounted in the fixture.
func _laser() -> Node2D:
	var packed := load(MINING_SCENE) as PackedScene
	assert_true(packed != null, "the mining laser's scene loads")
	if packed == null:
		return null
	var laser := packed.instantiate() as Node2D
	laser.name = &"MiningLaser"
	_root.add_child(laser)
	laser.global_position = Vector2.ZERO
	return laser


## A real rock of an exact class: `setup` builds the look its own size rolls, so the
## collision radius is the shipped 24/42/66 u and not an invented figure. `units` is high in
## the sampling fixtures so the chip work cannot deplete the rock mid-run.
func _rock(size_class: int, at: Vector2, units: int) -> Node2D:
	var rock := AsteroidScript.new() as Node2D
	rock.name = &"Rock"
	rock.call(&"setup", &"iron", 1, units, size_class)
	_root.add_child(rock)
	rock.global_position = at
	return rock


## A hull the way a ray hands it back: the **body** is the collider and the ship above it
## answers the damage (`player_ship.tscn`'s `HullBody` under `PlayerShip`). `radius` 0.0
## leaves the body without a shape, which is the radius-less target the floor binds.
func _hull(shield: float, radius := 30.0) -> Dictionary:
	var ship := StubHull.new()
	ship.name = &"BeamTarget"
	ship.shield = shield
	ship.add_to_group(SHIP_GROUP)
	_root.add_child(ship)
	ship.global_position = Vector2(120.0, 0.0)
	var body := Node2D.new()
	body.name = &"HullBody"
	ship.add_child(body)
	if radius > 0.0:
		var circle := CircleShape2D.new()
		circle.radius = radius
		var shape := CollisionShape2D.new()
		shape.name = &"Shape"
		shape.shape = circle
		body.add_child(shape)
	return {&"ship": ship, &"body": body}


## A rocket of the shooter's own making, `offset` u from the muzzle (`_rocket_on_segment`
## finds it by distance to the segment, so it must stay inside `HIT_RADIUS` of the ray).
func _staged_rocket(guns: Node2D, offset: Vector2) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "BeamRocket"
	shot.call(
		&"configure",
		{&"kind": ProjectileScript.KIND_ROCKET, &"speed": 0.0, &"damage": 180.0, &"mass": 1.0}
	)
	_root.add_child(shot)
	shot.global_position = guns.global_position + offset
	return shot


## ---------------------------------------------------------------------------
## The readers
## ---------------------------------------------------------------------------


## The disc the amendment pins for one collision radius. Read off the shipped constants, so
## the arithmetic that turns a rock's 24 u body into 8.4 u is this suite's own derivation
## rather than a number copied out of the docs.
func _disc(radius: float) -> float:
	return clampf(
		WeaponScript.HIT_FX_JITTER_MULT * radius,
		WeaponScript.HIT_FX_JITTER_MIN,
		WeaponScript.HIT_FX_JITTER_MAX
	)


func _radius(target: Object) -> float:
	return ProjectileScript.collision_radius(target)


## One frame of the beam's rock branch, called where `_fire_beam` calls it: the family's own
## row, the collider a ray would have resolved and the point it resolved. The pool is topped
## up first - the beam's Energy draw is the F1/F2 suites' measurement, not this one's, and a
## drained pool would read as "the reader drew nothing".
func _beam_hit(
	guns: Node2D, state: Variant, collider: Object, point: Vector2, delta := READ_FRAME
) -> void:
	state.set(&"energy", state.get(&"energy_max"))
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), collider, point, delta)


## The gun's rock chip, sampled: `SAMPLES` reads at a rock's own rim, each one's burst
## measured against the contact it was drawn at.
func _chip_offsets(guns: Node2D, state: Variant, rock: Node2D) -> Array[float]:
	var contact := rock.global_position + Vector2(float(rock.call(&"world_radius")), 0.0)
	return _sample(contact, func() -> void: _beam_hit(guns, state, rock, contact))


## The shield ring, the third reader, sampled the same way on a shielded hull.
func _ripple_offsets(guns: Node2D, state: Variant, body: Node2D) -> Array[float]:
	var contact := body.global_position + Vector2(30.0, 0.0)
	return _sample(contact, func() -> void: _beam_hit(guns, state, body, contact), RIPPLE_SHEET)


## `SAMPLES` reads, each one's own effect measured from the contact it was read at.
func _sample(contact: Vector2, read: Callable, sheet := CHIP_SHEET) -> Array[float]:
	var offsets: Array[float] = []
	for _index: int in SAMPLES:
		var before := _fx_nodes_from(sheet).size()
		read.call()
		var nodes := _fx_nodes_from(sheet)
		if nodes.size() <= before:
			continue
		var newest := nodes[nodes.size() - 1] as Node2D
		offsets.append(newest.global_position.distance_to(contact))
	return offsets


## The acceptance the pin states, measured: every read draws its effect, every effect lands
## inside the disc, the disc is really used, and the distances are spread through it rather
## than crowded on its rim (a uniform disc's mean is 2/3 of the radius; a rim-only sample
## would read 1.0 and one that skipped the area weight 0.5).
func _assert_scatters_in(offsets: Array[float], disc: float, what: String) -> void:
	assert_eq(offsets.size(), SAMPLES, "every read draws its own effect (%s)" % what)
	if offsets.size() != SAMPLES:
		return
	var peak := 0.0
	var total := 0.0
	for offset: float in offsets:
		peak = maxf(peak, offset)
		total += offset
		assert_true(
			offset <= disc + TOLERANCE,
			"every effect lands inside the %.1f u disc (%s read %.3f u)" % [disc, what, offset]
		)
	assert_true(
		peak >= 0.8 * disc,
		"and the disc is really used: the furthest of %d reads reached %.1f of %.1f u (%s)"
		% [SAMPLES, peak, disc, what]
	)
	var mean := total / float(offsets.size())
	assert_true(
		mean >= 0.55 * disc and mean <= 0.79 * disc,
		"spread through the disc, not crowded on its rim: mean %.2f of %.1f u (%s)"
		% [mean, disc, what]
	)


## Every effect node in the fixture drawing from `sheet`. A node's name is not its identity:
## two siblings cannot share one, so a second burst arrives renamed (`@chip@2`) and a count
## by name would miss it.
func _fx_nodes_from(sheet: String) -> Array[Node]:
	var out: Array[Node] = []
	if _root == null or not is_instance_valid(_root):
		return out
	for child: Node in _root.get_children():
		if _sheet_of(child) == sheet:
			out.append(child)
	return out


## The master a drawn node reads from (an `AtlasTexture` over a shipped sheet), or "" for a
## node that draws nothing.
func _sheet_of(node: Node) -> String:
	var sprite := node as Sprite2D
	if sprite != null:
		return _master_of(sprite.texture)
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		if animated.sprite_frames.has_animation(FxScript.ANIMATION):
			return _master_of(animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0))
	return ""


func _master_of(texture: Texture2D) -> String:
	if texture == null:
		return ""
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return atlas.atlas.resource_path if atlas.atlas != null else ""
	return texture.resource_path


## The shaft's own core line, the thin bright one under the halo.
func _beam_line(node: Node) -> Line2D:
	var core := node.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[1])) as Line2D
	assert_true(core != null, "the shaft's own core line is drawn")
	return core


## The pickups in the running scene: the shaft parents them to the world, not to the
## fixture, so they outlive the rock the way 02 section 7.1 asks. Counted by script, not by
## name - two pickups on one contact cannot share a name, so the second arrives renamed
## (`@Pickup@2`) and a name match would miss exactly the one this suite wants.
func _pickups() -> Array[Node]:
	var out: Array[Node] = []
	var world := _world_parent()
	if world == null:
		return out
	for child: Node in world.get_children():
		var script := child.get_script() as GDScript
		if script != null and script.resource_path == PICKUP_SCRIPT:
			out.append(child)
	return out


func _world_parent() -> Node:
	var tree := _tree()
	if tree == null:
		return null
	var scene := tree.current_scene
	return scene if scene != null else tree.root


func _near(measured: float, expected: float, tolerance := TOLERANCE) -> bool:
	return absf(measured - expected) <= tolerance


## The shared pool cursors, as found.
func _snapshot_pools() -> void:
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_state = true
	_pool_state = (cursors as Dictionary).duplicate()


## Put them back. `Object.get` hands back the live dictionary, so it is restored in place.
func _restore_pools() -> void:
	if not _had_pool_state:
		return
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_state, true)
	_pool_state = {}
	_had_pool_state = false


## A clean fixture: no leftover effects and no leftover shots (a shot of another test's
## would be a target on the beam's segment).
func _clear() -> void:
	var tree := _tree()
	if tree != null:
		for shot: Node in tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
			if is_instance_valid(shot):
				shot.free()
	if _root == null or not is_instance_valid(_root):
		return
	for child: Node in _root.get_children():
		if is_instance_valid(child):
			child.free()


## Put every bed out, by name: a bed left sounding would make the next test's reading one of
## this one's leftovers.
func _clear_loops() -> void:
	var audio := _audio()
	if audio == null or not audio.has_method(&"sounding_loops"):
		return
	for cue: Variant in (audio.call(&"sounding_loops") as Array).duplicate():
		audio.call(&"stop_loop", 0.0, StringName(cue))


func _audio() -> Node:
	var tree := _tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root
