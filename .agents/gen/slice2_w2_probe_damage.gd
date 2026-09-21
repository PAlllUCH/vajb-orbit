extends SceneTree
## slice-2 W2 probe: the damage pipeline of ENGINE_SPEC section 4.2, measured on the
## shipped tree -- a real `PlayerShip` scene on its own `RigidBody2D` body, a real
## `PlayerState`, and real rigid bodies inside the physics tree.
##
##   A  the front door: shield-first absorb, bypass, and the item-5 context round trip
##   B  item 5's `direction`: the four arcs slice 3 will read, through the pipeline
##   C  item 2's shield regeneration: the 4 s quiet window, stepped frame by frame, and
##      the hull's own quiet timer
##   D  item 6: the hull's shipped contact handler against `impact.gd`'s own figure
##   E  item 7: the knockback impulse through the hull's own push seam
##   F  item 8: a real body's velocity after `Impact.apply_shockwave`'s window
##   G  the shipped-tree gaps this pass cannot close from its file set (reported, not
##      asserted): where the pipeline is still unwired
##
## Re-run from the workspace root (the probe lives in `vajb-orbit/tools/`):
##
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_s2w2_damage.gd
##   --quit-after 900 > .agents/gen/_dispatch/slice2_w2_probe.log 2>&1
##
## Archived copy: `.agents/gen/slice2_w2_probe_damage.gd`.

const DamageScript := preload("res://game/damage.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")

const HULL_ID: StringName = &"ship_vanguard"
const STEP := 1.0 / 60.0

## Fixtures. `PEER_MASS` 560 t is CONTRACTS 8.1's rock reference mass (4 x the Miner's
## 140 t); the projectile mass is the probe's own, because a projectile's mass lives in
## slice 2 W1's weapon table and this pass has no value to read; the peer's closing speed
## and the ram's geometry are chosen to sit well above `Impact.COLLISION_MIN_DV` 40.
const PEER_MASS := 560.0
const PEER_OFFSET := Vector2(400.0, 0.0)
const PEER_CLOSING := 100.0
const FIXTURE_MASS := 1.0
const MUZZLE_SPEED := 1000.0
const IMPACT_POINT_OFFSET := Vector2(-40.0, 0.0)
const BLAST_DAMAGE := 180.0
const BLAST_ROCK_DISTANCE := 5.0

var _ok := 0
var _failed := 0
var _blocked := 0
var _gaps := 0

## The hull's quiet timer at launch (`WARP_DAMAGE_QUIET`, section 7): captured before any
## hit of this probe touches the ship, because the first hit resets it.
var _launch_quiet := 0.0

var _stats: ShipStats = null
var _state: PlayerState = null
var _ship: Node2D = null
var _peer: RigidBody2D = null
var _rock: RigidBody2D = null
var _sink: Node2D = null


## A sink the detonation can charge: a hull at a position, with the hit method the
## pipeline calls and no body of its own (so it is charged and not pushed).
class Target extends Node2D:
	var hits: int = 0
	var amount: float = 0.0
	var ctx: Dictionary = {}

	func take_damage(hit: float, _bypass_shield: bool, context := {}) -> void:
		hits += 1
		amount = hit
		ctx = context


func _init() -> void:
	print("=== W2 probe: the damage pipeline (ENGINE_SPEC section 4.2 items 1-8) ===")
	await process_frame
	if not _setup():
		_finish()
		return
	_report_absorb_and_context()
	_report_bearing()
	await _report_regen_window()
	_report_ram()
	_report_knockback()
	await _report_explosion()
	_report_gaps()
	_finish()


## The launched hull of the standard fit, the live state game.gd would hand it, and the
## ship scene on its own body. Every failure here is blocked, not failed: a scene that
## cannot instantiate is the asset-path fallout the slice-0 ruling defers.
func _setup() -> bool:
	_stats = ShipFitScript.resolve(HULL_ID, ShipFitScript.STANDARD_FIT)
	if _stats == null:
		_block("setup", "ShipFit.resolve(%s, STANDARD_FIT) returned null" % HULL_ID)
		return false
	_state = PlayerStateScript.new()
	_state.hull_max = _stats.hull_max
	_state.shield_max = _stats.shield_max
	_state.shield_regen = _stats.shield_regen
	_state.setup()
	_ship = PlayerShipScene.instantiate() as Node2D
	if _ship == null:
		_block("setup", "res://game/player_ship.tscn did not instantiate")
		return false
	root.add_child(_ship)
	## The pinned `setup` takes a typed `Array[StringName]`; an untyped `[]` is refused by
	## its signature, so the empty fit is spelled with its type.
	var fit_ids: Array[StringName] = []
	_ship.call(&"setup", _stats, _state, fit_ids)
	if _ship.call(&"impact_body") == null:
		_block("setup", "the hull has no rigid body (HullBody missing from the scene)")
		return false
	print(
		"setup: %s, hull_max %s, shield_max %s, shield_regen %s/s, hull_mass %s t"
		% [HULL_ID, _state.hull_max, _state.shield_max, _state.shield_regen, _stats.hull_mass]
	)
	_launch_quiet = float(_ship.get(&"_damage_quiet"))
	return true


## A: section 4.2 items 1 and 5 on the live state.
func _report_absorb_and_context() -> void:
	_state.set_shield(_state.shield_max)
	var hull_before := _state.hull
	DamageScript.apply(_state, _state.shield_max + 100.0, false, _hit_from(Vector2.DOWN))
	_check("item 1: a live shield absorbs the whole hit with no carry-over",
		_state.shield == 0.0 and _state.hull == hull_before,
		"hit %s -> shield %s, hull %s (was %s)"
		% [_state.shield_max + 100.0, _state.shield, _state.hull, hull_before])

	_state.set_shield(_state.shield_max)
	DamageScript.apply(_state, 250.0, true, _hit_from(Vector2.RIGHT))
	_check("item 1: a bypassing hit lands on the hull and leaves the shield",
		is_equal_approx(_state.hull, hull_before - 250.0) and _state.shield == _state.shield_max,
		"hull %s (was %s), shield %s" % [_state.hull, hull_before, _state.shield])

	var ctx: Dictionary = DamageScript.context(
		_ship.global_position, _ship.global_rotation, _ship.global_position + Vector2.DOWN * 500.0,
		1234.5, &"kinetic"
	)
	DamageScript.apply(_state, 10.0, false, ctx)
	var recorded := _state.last_damage_ctx()
	_check("item 5: direction, impulse and family ride the pipeline into PlayerState",
		recorded.size() == 3
		and is_equal_approx(float(recorded.get(&"direction", 0.0)), float(ctx[&"direction"]))
		and is_equal_approx(float(recorded.get(&"impulse", 0.0)), 1234.5)
		and recorded.get(&"family", &"") == &"kinetic",
		"recorded %s" % recorded)


## B: the sign convention of item 5's `direction`, read the way slice 3 will read it:
## one hit per arc, applied through the pipeline, and the context PlayerState recorded.
func _report_bearing() -> void:
	var origin := _ship.global_position
	var heading := _ship.global_rotation
	var prow := _bearing_from(origin + Vector2.RIGHT.rotated(heading) * 500.0)
	var starboard := _bearing_from(origin + Vector2.DOWN.rotated(heading) * 500.0)
	var port := _bearing_from(origin + Vector2.UP.rotated(heading) * 500.0)
	var stern := _bearing_from(origin - Vector2.RIGHT.rotated(heading) * 500.0)
	_check(
		"item 5: prow 0, starboard +PI/2, port -PI/2, stern +/-PI (read off last_damage_ctx)",
		is_equal_approx(prow, 0.0)
		and is_equal_approx(starboard, PI / 2.0)
		and is_equal_approx(port, -PI / 2.0)
		and is_equal_approx(absf(stern), PI),
		"prow %.4f, starboard %.4f, port %.4f, stern %.4f (PI %.4f)"
		% [prow, starboard, port, stern, PI]
	)
	var turned := DamageScript.bearing(
		origin, heading + TAU * 12.0, origin + Vector2.DOWN.rotated(heading) * 500.0
	)
	_check("item 5: the bearing wraps, it does not accumulate over turns",
		is_equal_approx(turned, starboard), "%.4f after 12 extra turns" % turned)


## C: section 4.2 item 2 -- the 4 s quiet window and the resolved rate, stepped one frame
## at a time, plus the hull's own quiet timer (the one a W5 wiring would hand `regen`).
func _report_regen_window() -> void:
	_state.shield_regen = _stats.shield_regen
	_state.set_shield(100.0)
	var start := _state.shield
	var quiet := 0.0
	var window_frames := int((DamageScript.REGEN_QUIET - 0.5) / STEP)
	for _frame in window_frames:
		quiet += STEP
		DamageScript.regen(_state, STEP, quiet)
	_check("item 2: inside the 4 s window nothing regenerates",
		_state.shield == start,
		"%d frames of quiet time (%s s), shield %s" % [window_frames, quiet, _state.shield])

	DamageScript.regen(_state, 1.0, DamageScript.REGEN_QUIET - 0.001)
	_check("item 2: the window is a floor, not a coincidence",
		_state.shield == start, "a hair under REGEN_QUIET left it at %s" % _state.shield)

	var gain_frames := 60
	for frame in gain_frames:
		DamageScript.regen(_state, STEP, DamageScript.REGEN_QUIET + float(frame + 1) * STEP)
	var gained := _state.shield - start
	_check("item 2: one second past the window adds the state's own rate",
		is_equal_approx(gained, _stats.shield_regen),
		"gained %s over one second, rate %s/s (base 2 + s_light 4)" % [gained, _stats.shield_regen])

	var quiet_at_launch := _launch_quiet
	for _frame in 20:
		await physics_frame
	var quiet_before := float(_ship.get(&"_damage_quiet"))
	DamageScript.apply(_state, 1.0, false, {})
	var quiet_after_hit := float(_ship.get(&"_damage_quiet"))
	for _frame in 3:
		await physics_frame
	var quiet_climbing := float(_ship.get(&"_damage_quiet"))
	_check("item 2: the hull's own quiet timer (launched at WARP_DAMAGE_QUIET) resets on a hit and climbs per frame",
		quiet_at_launch >= DamageScript.REGEN_QUIET
		and quiet_before > 0.0
		and quiet_after_hit == 0.0
		and quiet_climbing > 0.0,
		"launched at %s, %s after 20 frames, %s after a hit, %s three frames later"
		% [quiet_at_launch, quiet_before, quiet_after_hit, quiet_climbing])


## D: item 6. The shipped contact handler is driven directly -- the solver's own contact
## is not reproducible headless -- and compared against `impact.gd`'s figure for the
## closing speed the hull itself carried into the step.
##
## The closing speed is set on the *peer*, not on the hull: a peer's velocity is nobody
## else's business, so the figure is the same at the moment of the call however many
## physics steps the harness runs between awaits.
func _report_ram() -> void:
	_peer = _body(PEER_MASS)
	var settled_at := Engine.get_physics_frames()
	await physics_frame
	var settle_steps := Engine.get_physics_frames() - settled_at
	_peer.global_position = _ship.global_position + PEER_OFFSET
	_peer.linear_velocity = Vector2(-PEER_CLOSING, 0.0)
	var carried: Vector2 = _ship.get(&"_last_velocity")
	var closing := maxf(
		(carried - _peer.linear_velocity).dot((_peer.global_position - _ship.global_position).normalized()),
		0.0
	)
	print(
		"ram fixture: hull at rest carrying %s, peer %s u away closing at %s u/s (%s physics steps across the settle await)"
		% [carried, PEER_OFFSET.length(), closing, settle_steps]
	)
	var expected := ImpactScript.collision_damage(_stats.hull_mass, PEER_MASS, closing)
	_state.set_shield(_state.shield_max)
	var before := _state.shield
	_ship.call(&"_on_hull_body_entered", _peer)
	var charged := before - _state.shield
	_check("item 6: the hull's shipped contact handler charges impact.gd's own figure",
		is_equal_approx(closing, PEER_CLOSING) and is_equal_approx(charged, expected),
		"charged %s, impact.gd %s (reduced mass %s t vs %s t at %s u/s)"
		% [charged, expected, _stats.hull_mass, PEER_MASS, closing])

	_state.set_shield(_state.shield_max)
	var sink := _target()
	var via_pipeline := DamageScript.ram(
		sink, _peer.global_position, _stats.hull_mass, PEER_MASS, closing
	)
	_check("item 6: the pipeline's ram entry charges a hull that publishes take_damage",
		is_equal_approx(via_pipeline, expected)
		and sink.hits == 1
		and is_equal_approx(sink.amount, expected)
		and sink.ctx.get(DamageScript.CTX_FAMILY, &"") == DamageScript.FAMILY_COLLISION
		and is_equal_approx(
			float(sink.ctx.get(DamageScript.CTX_DIRECTION, 0.0)),
			DamageScript.bearing(sink.global_position, sink.global_rotation, _peer.global_position)
		)
		and is_equal_approx(float(sink.ctx.get(DamageScript.CTX_IMPULSE, 0.0)), 0.0),
		"ram %s, sink hits %d for %s, ctx %s" % [via_pipeline, sink.hits, sink.amount, sink.ctx])


## E: item 7. `Impact.knockback`'s energy share, the `sqrt(2 * E * M)` impulse it implies
## for the hull's own mass, and where it lands.
func _report_knockback() -> void:
	var body: RigidBody2D = _ship.call(&"impact_body")
	body.linear_velocity = Vector2.ZERO
	var impact_point := _ship.global_position + IMPACT_POINT_OFFSET
	var energy := ImpactScript.knockback(MUZZLE_SPEED, FIXTURE_MASS)
	var expected := sqrt(2.0 * energy * _stats.hull_mass)
	var impulse := DamageScript.knockback(_ship, FIXTURE_MASS, MUZZLE_SPEED, impact_point)
	## The hull's cached velocity only syncs with the physics step, so the reading is
	## taken off the physics server: the impulse itself lands immediately.
	var pushed: Vector2 = PhysicsServer2D.body_get_state(
		body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY
	)
	_check("item 7: the knockback impulse is sqrt(2 * E * M) and reaches the hull's push seam",
		is_equal_approx(impulse, expected) and is_equal_approx(pushed.length(), expected / _stats.hull_mass),
		"impulse %s (expected %s), body gained %s u/s (expected %s)"
		% [impulse, expected, pushed.length(), expected / _stats.hull_mass])
	_check("item 7: the push travels away from the impact point",
		pushed.x > 0.0, "impact point %s behind the hull, body velocity %s" % [IMPACT_POINT_OFFSET, pushed])


## F: item 8. A real body's velocity after the blast front's window, against
## `Impact.explosion_impulse(d) / mass`.
func _report_explosion() -> void:
	_rock = _body(PEER_MASS)
	var epicenter := _ship.global_position + Vector2(0.0, 400.0)
	_rock.global_position = epicenter + Vector2(BLAST_ROCK_DISTANCE, 0.0)
	_rock.linear_velocity = Vector2.ZERO
	_sink = _target()
	_sink.global_position = epicenter + Vector2(0.0, 20.0)
	## A body's mass properties settle with the space, so the fixture waits a frame before
	## the blast: an impulse applied on the frame a body enters is charged at unit mass.
	await physics_frame
	await physics_frame

	var distance := _rock.global_position.distance_to(epicenter)
	var momentum := ImpactScript.explosion_impulse(distance)
	var charged := DamageScript.detonate(epicenter, BLAST_DAMAGE, true, [_rock, _sink], &"missile")
	var window_frames := int(ImpactScript.EXPLOSION_WINDOW * float(Engine.physics_ticks_per_second)) + 8
	for _frame in window_frames:
		await physics_frame
	_check("item 8: the blast pushes a rigid body with P0/(1+d^2) over its window",
		is_equal_approx(_rock.linear_velocity.length(), momentum / PEER_MASS),
		"rock at %s u: momentum %s, gained %s u/s (expected %s), damping 0"
		% [distance, momentum, _rock.linear_velocity.length(), momentum / PEER_MASS])
	_check("item 8: the hulls the blast reaches are charged, the rock is only pushed",
		charged == 1 and _sink.hits == 1 and is_equal_approx(_sink.amount, BLAST_DAMAGE),
		"charged %d of 2 entries, sink hits %d for %s" % [charged, _sink.hits, _sink.amount])
	_check("item 8: the recorded impulse is the momentum the shockwave applied",
		is_equal_approx(
			float(_sink.ctx.get(DamageScript.CTX_IMPULSE, 0.0)),
			ImpactScript.explosion_impulse(_sink.global_position.distance_to(epicenter))
		) and _sink.ctx.get(DamageScript.CTX_FAMILY, &"") == &"missile",
		"ctx %s" % _sink.ctx)


## G: what the shipped tree still owes the pipeline, measured rather than assumed. These
## are reported (never asserted green) because every one of them is a file outside this
## pass's set: the fix is one line each, in player_ship.gd and game.gd (W5).
func _report_gaps() -> void:
	var quiet_now := float(_ship.get(&"_damage_quiet"))
	_state.set_shield(_state.shield_max)
	var to_ship := DamageScript.ram(
		_ship, _peer.global_position, _stats.hull_mass, PEER_MASS, PEER_CLOSING
	)
	_gap(
		"PlayerShip publishes no take_damage, so the pipeline reaches the player hull only "
		+ "through PlayerState.damage (its fallback) until the pinned forwarding method lands",
		"has_method(take_damage) %s; Damage.ram(_ship, ...) computed %s and the shield stayed %s"
		% [_ship.has_method(&"take_damage"), to_ship, _state.shield]
	)
	_gap(
		"the hull's shipped ram charges PlayerState.damage without a context: one "
		+ "Damage.context(...) argument in _on_hull_body_entered fills it",
		"last ctx after the ram: %s" % _ram_ctx()
	)
	var bare := PlayerStateScript.new()
	bare.setup()
	_gap(
		"an unseeded PlayerState regenerates at the section 4.2 base, not the fit's rate: "
		+ "game.gd's _apply_ship_maxima owes a shield_regen seed beside energy_regen",
		"default %s/s vs the standard fit's %s/s" % [bare.shield_regen, _stats.shield_regen]
	)
	_gap(
		"nothing in the shipped tree calls Damage.regen yet, so shield regeneration is "
		+ "inert in game until player_ship.gd's _physics_process calls it with its own "
		+ "_damage_quiet",
		"the timer exists and climbs: %s" % quiet_now
	)


## The context the ram left behind, read without disturbing it.
func _ram_ctx() -> Dictionary:
	_state.set_shield(_state.shield_max)
	_ship.call(&"_on_hull_body_entered", _peer)
	return _state.last_damage_ctx()


func _hit_from(offset: Vector2) -> Dictionary:
	return DamageScript.context(
		_ship.global_position, _ship.global_rotation, _ship.global_position + offset * 500.0, 0.0, &"energy"
	)


func _bearing_from(source_position: Vector2) -> float:
	DamageScript.apply(_state, 1.0, true, DamageScript.context(
		_ship.global_position, _ship.global_rotation, source_position, 0.0, &"energy"
	))
	return float(_state.last_damage_ctx().get(&"direction", 0.0))


## A rigid body this probe can push: no gravity, no damping, never asleep, and on no
## collision layer, so the solver never generates a contact of its own while it is here.
## The collision shape is what gives the body its mass properties: a shapeless body is
## charged at unit mass until the space has updated it (measured, see the report).
func _body(mass: float) -> RigidBody2D:
	var body := RigidBody2D.new()
	body.mass = mass
	body.gravity_scale = 0.0
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	body.linear_damp = 0.0
	body.can_sleep = false
	body.collision_layer = 0
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0
	shape.shape = circle
	body.add_child(shape)
	root.add_child(body)
	return body


## A hull the pipeline can charge and the blast can reach: a position, a heading and the
## pinned hit method, with no body of its own.
func _target() -> Target:
	var target := Target.new()
	target.name = &"ProbeTarget"
	root.add_child(target)
	return target


func _finish() -> void:
	for node: Node in [_ship, _peer, _rock, _sink]:
		if node != null and is_instance_valid(node):
			root.remove_child(node)
			node.free()
	print("[SUMMARY] ok=%d failed=%d blocked=%d gaps=%d" % [_ok, _failed, _blocked, _gaps])
	quit(1 if _failed > 0 else 0)


func _block(label: String, detail: String) -> void:
	_blocked += 1
	print("[BLOCK] %s | %s" % [label, detail])


## A measured shortfall in the shipped tree. Counted and printed as its own kind so the
## summary's ok/failed pair stays a truth table of the pipeline itself.
func _gap(label: String, detail: String) -> void:
	_gaps += 1
	print("[GAP]  %s | %s" % [label, detail])


func _check(label: String, passed: bool, detail: String = "") -> void:
	var suffix := "" if detail.is_empty() else " | " + detail
	if passed:
		_ok += 1
		print("[OK]   %s%s" % [label, suffix])
	else:
		_failed += 1
		print("[FAIL] %s%s" % [label, suffix])
