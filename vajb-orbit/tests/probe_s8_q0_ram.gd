extends Node2D
## S8-Q0 evidence probe (part 2): M1 - what a real rock ram does to the engine's physics
## state, and O3 - what a real player-to-NPC ram delivers.
##
## Deterministic headless scene, no window and no `Input`: the shipped `PlayerShip` (its
## shipped `HullBody` contact monitor) is driven at a fixed velocity into, in turn, a real
## `Asteroid` inside a real `AsteroidField` and a real `NpcShip`, and the engine is asked
## what happened. Every "Can't change this state while flushing queries" line lands on
## stderr; the caller counts them.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_s8_q0_ram.tscn \
##         --quit-after 6000 --fixed-fps 60 2>/tmp/s8q0_ram.err
## Signal: the [S8Q0R] lines; the last line is `[S8Q0R] done`.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const ImpactScript := preload("res://game/impact.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")

const TAG := "[S8Q0R]"
const HULL: StringName = &"ship_vanguard"
const APPROACH_SPEED := 450.0
const START_GAP := 400.0
const APPROACH_BUDGET := 400
const SETTLE_FRAMES := 90

var _case := ""
var _frames := 0
var _contact_seen := false
var _driver := Vector2.ZERO
var _ship: Node2D = null
var _state: Resource = null
var _body: RigidBody2D = null
var _target: Node2D = null
var _field: Node2D = null


func _ready() -> void:
	await get_tree().process_frame
	print("%s probe=s8_q0_ram ticks=%d speed=%.1f" % [TAG, Engine.physics_ticks_per_second, APPROACH_SPEED])
	await _ram_rock()
	await _ram_npc()
	print("%s done" % TAG)
	get_tree().quit(0)


func _physics_process(_delta: float) -> void:
	if _body == null or _driver == Vector2.ZERO:
		return
	_frames += 1
	if not _contact_seen:
		_body.linear_velocity = _driver
	else:
		_driver = Vector2.ZERO


## ---------------------------------------------------------------------------
## M1: a ram that cracks a rock inside the contact callback
## ---------------------------------------------------------------------------


func _ram_rock() -> void:
	_case = "rock_ram"
	_field = FieldScript.new() as Node2D
	_field.name = "Field"
	add_child(_field)
	seed(20260924)
	## A medium rock with 2 units: the ram's own offer (see the C1 measurement, ~186 damage
	## -> 18.6 work) empties it on the contact frame, so the field's cleave path runs.
	var rock: RigidBody2D = _field.call(&"_new_rock", "Rock1", &"iron", 1, 2, AsteroidScript.SIZE_MEDIUM)
	rock.global_position = Vector2.ZERO
	await get_tree().physics_frame
	print(
		"%s %s rock radius=%.3f mass=%.1f units=%d size_class=%d"
		% [
			TAG,
			_case,
			float(rock.call(&"world_radius")),
			rock.mass,
			int(rock.get(&"yield_units")),
			int(rock.call(&"size_class")),
		]
	)
	_spawn_ship(Vector2.ZERO - Vector2(START_GAP, 0.0))
	_driver = Vector2(APPROACH_SPEED, 0.0)
	await _drive(APPROACH_BUDGET)
	await _settle(SETTLE_FRAMES)
	var fragments := 0
	for node: Node in _field.get_children():
		if String(node.name).begins_with("Fragment"):
			fragments += 1
	print(
		"%s %s contact=%s frame=%d fragments=%d rock_count=%d"
		% [TAG, _case, str(_contact_seen), _frames, fragments, int(_field.call(&"rock_count"))]
	)
	_teardown()


## ---------------------------------------------------------------------------
## O3: a player-to-NPC ram
## ---------------------------------------------------------------------------


func _ram_npc() -> void:
	_case = "npc_ram"
	var npc: Node2D = NpcShipScript.new() as Node2D
	npc.name = "Npc"
	add_child(npc)
	npc.global_position = Vector2.ZERO
	_target = npc
	npc.call(
		&"setup",
		&"pirate",
		ShipFitScript.resolve(&"ship_fighter", ShipFitScript.standard_fit(&"ship_fighter")),
		&"ship_fighter"
	)
	var npc_body := npc.get_node_or_null(NodePath("HullBody")) as RigidBody2D
	## The brain patrols, so the target would leave the approach line: the probe stops the
	## NPC's own tick and parks it at the origin, which is the deterministic fixture the
	## ram needs (the brain is not what O3 measures).
	npc.set_physics_process(false)
	npc.global_position = Vector2.ZERO
	if npc_body != null:
		npc_body.global_position = Vector2.ZERO
		npc_body.linear_velocity = Vector2.ZERO
	await get_tree().physics_frame
	print(
		"%s %s npc hull=%.1f shield=%.1f mass=%.1f shape_r=%.2f | player mass=%.1f"
		% [
			TAG,
			_case,
			float(npc.call(&"hull")),
			float(npc.call(&"shield")),
			npc_body.mass if npc_body != null else -1.0,
			_radius(npc_body),
			_spawn_ship_mass(),
		]
	)
	await _ram_pass(npc, npc_body, 1, "shipped_mask")
	await _ram_pass(npc, npc_body, 3, "mask_incl_layer2")
	_teardown()


## One ram pass at one player-hull collision mask. `mask` 1 is the shipped value (the
## hull's default, rock layer only); 3 adds the hull layer, which is what the player and
## the NPC would need for a hull-to-hull contact to resolve at all.
func _ram_pass(npc: Node2D, npc_body: RigidBody2D, mask: int, label: String) -> void:
	var hull_before := float(npc.call(&"hull"))
	var shield_before := float(npc.call(&"shield"))
	_spawn_ship(Vector2.ZERO - Vector2(START_GAP, 0.0))
	_body.collision_mask = mask
	var mass_a := _body.mass
	var mass_b := npc_body.mass if npc_body != null else INF
	var player_shield_before := float(_state.get(&"shield"))
	print(
		"%s %s pass=%s player mask=%d layer=%d npc layer=%d mask=%d"
		% [
			TAG,
			_case,
			label,
			_body.collision_mask,
			_body.collision_layer,
			npc_body.collision_layer,
			npc_body.collision_mask,
		]
	)
	_driver = Vector2(APPROACH_SPEED, 0.0)
	await _drive(APPROACH_BUDGET)
	await _settle(SETTLE_FRAMES)
	var offer := ImpactScript.collision_damage(mass_a, mass_b, APPROACH_SPEED)
	print(
		"%s %s pass=%s contact=%s frame=%d | mass_a=%.1f mass_b=%.1f dv=%.1f offer=%.4f"
		% [TAG, _case, label, str(_contact_seen), _frames, mass_a, mass_b, APPROACH_SPEED, offer]
	)
	print(
		"%s %s pass=%s hull %.1f->%.1f shield %.1f->%.1f | delivered_hull=%.4f delivered_shield=%.4f"
		% [
			TAG,
			_case,
			label,
			hull_before,
			float(npc.call(&"hull")),
			shield_before,
			float(npc.call(&"shield")),
			hull_before - float(npc.call(&"hull")),
			shield_before - float(npc.call(&"shield")),
		]
	)
	print(
		"%s %s pass=%s player shield %.1f->%.1f (own half=%.4f, damage_mult=%.2f)"
		% [
			TAG,
			_case,
			label,
			player_shield_before,
			float(_state.get(&"shield")),
			player_shield_before - float(_state.get(&"shield")),
			_player_damage_mult(),
		]
	)


func _spawn_ship_mass() -> float:
	return ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT).hull_mass


func _player_damage_mult() -> float:
	if _ship != null and _ship.has_method(&"_damage_scale"):
		return float(_ship.call(&"_damage_scale"))
	return -1.0


## ---------------------------------------------------------------------------
## Harness
## ---------------------------------------------------------------------------


func _spawn_ship(at: Vector2) -> void:
	_state = PlayerStateScript.new()
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	_state.set(&"hull_max", stats.hull_max)
	_state.set(&"shield_max", stats.shield_max)
	_state.set(&"cargo_max", stats.cargo_max)
	_state.set(&"energy_max", stats.energy_max)
	_state.set(&"energy_regen", stats.energy_regen)
	_state.set(&"fuel_max", stats.fuel_max)
	_state.set(&"shield_regen", stats.shield_regen)
	_state.call(&"setup")
	_ship = PlayerShipScene.instantiate() as Node2D
	add_child(_ship)
	_ship.call(&"setup", stats, _state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_ship.global_position = at
	_body = _ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE)) as RigidBody2D
	if _body != null and not _body.body_entered.is_connected(_on_body_entered):
		_body.body_entered.connect(_on_body_entered)
	_frames = 0
	_contact_seen = false
	_driver = Vector2.ZERO


func _on_body_entered(other: Node) -> void:
	if _contact_seen:
		return
	_contact_seen = true
	print("%s %s CONTACT with %s at frame %d" % [TAG, _case, String(other.name), _frames])


func _drive(budget: int) -> void:
	for _index in budget:
		await get_tree().physics_frame
		if _contact_seen:
			return


func _settle(frames: int) -> void:
	for _index in frames:
		await get_tree().physics_frame


func _teardown() -> void:
	_driver = Vector2.ZERO
	for node: Node in [_ship, _field, _target]:
		if node != null and is_instance_valid(node):
			remove_child(node)
			node.free()
	_ship = null
	_field = null
	_target = null


func _read(node: Node, method: StringName) -> Variant:
	if node != null and node.has_method(method):
		return node.call(method)
	return null


func _radius(body: RigidBody2D) -> float:
	if body == null:
		return -1.0
	for child: Node in body.get_children():
		var shape := child as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			return (shape.shape as CircleShape2D).radius
	return -1.0
