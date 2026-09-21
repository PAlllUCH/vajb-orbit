extends Node
## G4 (reviewer) A/B probe for the wave's three beam behaviours: the same measurements on
## HEAD's code and on the wave's, so "the shaft stops at what it hit", "a rock chip reads"
## and "a held beam's feedback repeats" are measured, not argued.
##
## It reads only APIs that exist on both sides of the wave (`range_of`, `set_firing`,
## `tick`, `_beam_core`, `_beam_target`, the audio service's `last_sfx`), so it parses and
## runs unchanged before and after. No cue name is hard-coded: the probe prints whatever
## the audio service was last handed.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_g4_beam_head.tscn --quit-after 600
## Signal: the [G4-AB] lines; the last is [G4-AB] done.

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const FRAME := 0.05
const FAR_AIM := 10000.0
const ROCK_DISTANCE := 480.0
const ROCK_RADIUS := 20.0

var _root: Node2D = null


func _ready() -> void:
	await get_tree().process_frame
	_root = Node2D.new()
	_root.name = &"G4ABRoot"
	add_child(_root)
	await _endpoint()
	await _rock_read()
	_held()
	print("[G4-AB] done")
	get_tree().quit(0)


## 1. The shaft's endpoint: a rock 480 u away, the aim 10 000 u away, the range 500 u.
func _endpoint() -> void:
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var rock := _rock(ROCK_DISTANCE)
	await get_tree().physics_frame
	await get_tree().physics_frame
	guns.call(&"set_firing", true)
	guns.call(&"tick", FRAME)
	var resolved: Dictionary = guns.call(&"_beam_target", Vector2.ZERO, Vector2(500.0, 0.0))
	print("[G4-AB] rock d=%.0f r=%.0f shaft_endpoint=%.3f resolved_hit=%.3f" % [
		ROCK_DISTANCE, ROCK_RADIUS, _endpoint_at(guns),
		(resolved.get(&"point", Vector2.ZERO) as Vector2).length(),
	])
	guns.call(&"set_firing", false)
	guns.call(&"tick", FRAME)
	_clear_fx()
	rig[&"hull"].free()
	var rig_miss := _rig(300.0)
	var guns_miss: Node2D = rig_miss[&"guns"]
	guns_miss.call(&"set_firing", true)
	guns_miss.call(&"tick", FRAME)
	print("[G4-AB] miss aim=300 shaft_endpoint=%.3f" % _endpoint_at(guns_miss))
	guns_miss.call(&"set_firing", false)
	guns_miss.call(&"tick", FRAME)
	_clear_fx()
	rig_miss[&"hull"].free()


## 2. A rock chip: the cue the audio service was handed and the effect nodes drawn.
func _rock_read() -> void:
	_clear_audio_marker()
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var rock := _rock(200.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	guns.call(&"set_firing", true)
	guns.call(&"tick", FRAME)
	print("[G4-AB] rock chip first frame: last_sfx=%s fx_nodes_on_rock=%d" % [
		_last_sfx(), _fx_nodes()
	])
	guns.call(&"set_firing", false)
	guns.call(&"tick", FRAME)
	_clear_fx()
	rig[&"hull"].free()


## 3. A held beam's fire feedback: flashes and the pinned `shot_fired` over 1.0 s.
func _held() -> void:
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var holds := [0]
	guns.connect(&"shot_fired", func(_weapon: StringName) -> void: holds[0] += 1)
	guns.call(&"set_firing", true)
	var frames := 20
	var first := -1
	var previous := 0
	var spawns := 0
	for frame in frames:
		guns.call(&"tick", FRAME)
		var live := _flashes(guns)
		if live > previous:
			spawns += live - previous
			if first < 0:
				first = frame
		previous = live
	print("[G4-AB] held %.2f s: flashes=%d spawns=%d first_spawn_frame=%d emissions=%d" % [
		float(frames) * FRAME, _flashes(guns), spawns, first, holds[0]
	])
	guns.call(&"set_firing", false)
	for _frame in 5:
		guns.call(&"tick", FRAME)
	print("[G4-AB] released: flashes=%d emissions=%d" % [_flashes(guns), holds[0]])
	rig[&"hull"].free()


## --- readers ---------------------------------------------------------------


func _endpoint_at(guns: Node2D) -> float:
	var core := guns.get(&"_beam_core") as Line2D
	if core == null or core.points.size() < 2:
		return -1.0
	return core.points[1].length()


func _flashes(guns: Node2D) -> int:
	var count := 0
	for child: Node in guns.get_children():
		if child is AnimatedSprite2D:
			count += 1
	return count


## Every effect node drawn under the fixture root - a chip burst hangs on the rock's
## parent, which is this root.
func _fx_nodes() -> int:
	var count := 0
	for child: Node in _root.get_children():
		if child is AnimatedSprite2D:
			count += 1
	return count


func _clear_fx() -> void:
	for child: Node in _root.get_children():
		if child is AnimatedSprite2D:
			child.free()


func _last_sfx() -> StringName:
	var audio := _audio()
	if audio == null or not audio.has_method(&"last_sfx"):
		return &"<no-audio>"
	return StringName(audio.call(&"last_sfx"))


func _clear_audio_marker() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.set(&"_last_sfx", &"")


func _audio() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("AudioManager")


## --- fixtures --------------------------------------------------------------


func _rig(aim_distance: float = FAR_AIM) -> Dictionary:
	var hull := Node2D.new()
	hull.name = &"G4ABHull"
	_root.add_child(hull)
	var guns := WeaponScript.new() as Node2D
	guns.name = &"WeaponComponent"
	hull.add_child(guns)
	var state: Variant = PlayerStateScript.new()
	state.call(&"setup")
	guns.call(&"setup", null, state)
	var fitted: Array[StringName] = [&"laser"]
	guns.call(&"set_fitted", fitted)
	guns.call(&"set_aim_point", guns.global_position + Vector2(aim_distance, 0.0))
	return {&"hull": hull, &"guns": guns, &"state": state}


func _rock(distance: float) -> StaticBody2D:
	var rock := StaticBody2D.new()
	rock.name = &"G4ABRock"
	rock.collision_layer = ProjectileScript.ROCK_LAYER_MASK
	rock.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ROCK_RADIUS
	shape.shape = circle
	rock.add_child(shape)
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_root.add_child(rock)
	rock.global_position = Vector2(distance, 0.0)
	return rock
