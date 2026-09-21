extends Node
## G4 (reviewer) beam probe: the three beam claims of the flight-feel/beam wave measured
## from outside the worker's own suite, on a live physics space.
##
## Why a separate probe: `test_flight_beam_g2.gd` drives `_apply_beam` directly, so its
## "shaft stops on the resolved point" case is staged through the rocket/destructible
## route (G2's own harness note: `_beam_target`'s physics ray cannot see a body added in
## the same frame). This probe puts a real `StaticBody2D` rock in the space, awaits two
## physics frames, and fires the public trigger (`set_firing` + `tick`), so the whole
## `_fire_beam` path runs - ray, resolution, draw - at several distances and on a miss.
##
## Measures:
##   1. the drawn shaft's endpoint against a rock at 120 / 250 / 480 u and on a miss
##      (aim 10 000 u -> the weapon's own 500 u reach; aim 300 u -> 300 u);
##   2. the rock read: S8's chip cue (`AudioManager.last_sfx()`), the chip-sparks burst
##      node, its frame count and FPS, the per-frame chip work and the read cadence;
##   3. the held beam's fire feedback: flash count and `shot_fired` emissions over 2 s of
##      held fire, the cadence in seconds, and that a release stops it;
##   4. the beam's Energy draw (unchanged: the laser row's own 6 E/s).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_g4_beam.tscn --quit-after 1200
## Signal: the [G4-BEAM] lines; the last line is [G4-BEAM] done failures=N.

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FxScript := preload("res://game/fx.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

const BEAM_FRAME := 0.05
const FINAL_DELTA := 0.02
const FAR_AIM := 10000.0
const NEAR_AIM := 300.0
const ROCK_RADIUS := 20.0
const MINING_SHEET := "res://assets/fx/fx_mining_beam.png"

var _root: Node2D = null
var _failures := 0


func _ready() -> void:
	await get_tree().process_frame
	_root = Node2D.new()
	_root.name = &"G4BeamRoot"
	add_child(_root)
	await _endpoints()
	await _rock_read()
	_held_feedback()
	await _held_real_frames()
	print("[G4-BEAM] done failures=%d" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


## --- 1. the shaft's endpoint ------------------------------------------------


func _endpoints() -> void:
	print("[G4-BEAM] laser row range=%.1f dps=%.1f draw=%.1f" % [
		WeaponScript.range_of(&"laser"),
		WeaponScript.dps_of(&"laser"),
		float(WeaponScript.row_of(&"laser").get(&"draw", 0.0)),
	])
	for distance: float in [120.0, 250.0, 480.0]:
		var rig := _rig()
		var guns: Node2D = rig[&"guns"]
		var rock := _rock(distance)
		await get_tree().physics_frame
		await get_tree().physics_frame
		guns.call(&"set_firing", true)
		guns.call(&"tick", BEAM_FRAME)
		var endpoint := _beam_endpoint(guns)
		var resolved := _resolved(guns)
		## The ray stops on the shape's surface, so the expected stop is d - r.
		var expected := distance - ROCK_RADIUS
		_check(
			_near(endpoint, expected, 1.0),
			"hit d=%.0f endpoint=%.3f expected=%.3f resolved=%.3f" % [
				distance, endpoint, expected, resolved
			]
		)
		guns.call(&"set_firing", false)
		guns.call(&"tick", BEAM_FRAME)
		rock.free()
		rig[&"hull"].free()
	## A miss keeps the weapon's own reach, and the reach is the range, not the aim.
	var rig_miss := _rig()
	var guns_miss: Node2D = rig_miss[&"guns"]
	guns_miss.call(&"set_firing", true)
	guns_miss.call(&"tick", BEAM_FRAME)
	var far_endpoint := _beam_endpoint(guns_miss)
	_check(
		_near(far_endpoint, WeaponScript.range_of(&"laser"), 0.5),
		"miss (aim %.0f) endpoint=%.3f reach=%.1f" % [
			FAR_AIM, far_endpoint, WeaponScript.range_of(&"laser")
		]
	)
	guns_miss.call(&"set_firing", false)
	guns_miss.call(&"tick", BEAM_FRAME)
	rig_miss[&"hull"].free()
	var rig_near := _rig(NEAR_AIM)
	var guns_near: Node2D = rig_near[&"guns"]
	guns_near.call(&"set_firing", true)
	guns_near.call(&"tick", BEAM_FRAME)
	var near_endpoint := _beam_endpoint(guns_near)
	_check(
		_near(near_endpoint, NEAR_AIM, 0.5),
		"miss inside the range (aim %.0f) endpoint=%.3f" % [NEAR_AIM, near_endpoint]
	)
	guns_near.call(&"set_firing", false)
	guns_near.call(&"tick", BEAM_FRAME)
	rig_near[&"hull"].free()
	_clear_fx()


## The endpoint phase left one burst per hit behind (no frame passes in this probe, so
## `Fx.play_once` cannot free its own node): the chip count below is its own.
func _clear_fx() -> void:
	for child: Node in _root.get_children():
		if child is AnimatedSprite2D:
			child.free()


## --- 2. a rock's read: the cue, the burst, the work, the cadence -----------


func _rock_read() -> void:
	var audio := _audio()
	_check(audio != null, "the AudioManager autoload is live")
	if audio == null:
		return
	_check(
		WeaponScript.CHIP_CUE == MiningLaserScript.CHIP_CUE,
		"the chip cue is the mining laser's own take (%s)" % WeaponScript.CHIP_CUE
	)
	_check(
		ProjectileScript.ROCK_GROUP == AsteroidScript.ROCK_GROUP,
		"the branch reads the shipped rock group"
	)
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var rock := _rock(200.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	print("[G4-BEAM] rock first frame cue=%s bursts=%d work=%.4f endpoint=%.3f" % [
		audio.call(&"last_sfx"), _bursts().size(), rock.work, _beam_endpoint(guns)
	])
	_check(
		StringName(audio.call(&"last_sfx")) == WeaponScript.CHIP_CUE,
		"a laser chipping a rock plays S8's chip cue"
	)
	var first := _bursts()
	_check(first.size() == 1, "and draws one chip-sparks burst on contact")
	if not first.is_empty():
		var sprite := first[0] as AnimatedSprite2D
		var frames := sprite.sprite_frames if sprite != null else null
		_check(
			frames != null
			and frames.get_frame_count(FxScript.ANIMATION) == 4
			and _near(frames.get_animation_speed(FxScript.ANIMATION), 20.0),
			"the burst is FX_SPEC 1.6's 4-frame sheet at 20 FPS"
		)
		_check(
			sprite != null and sprite.material is CanvasItemMaterial
			and (sprite.material as CanvasItemMaterial).blend_mode
			== CanvasItemMaterial.BLEND_MODE_ADD,
			"drawn additively, like every other FX sheet"
		)
	_check(
		_near(rock.work, 30.0 * BEAM_FRAME * WeaponScript.GUN_CHIP_RATE),
		"the first frame's chip work is dps x delta x %.2f = %.4f" % [
			WeaponScript.GUN_CHIP_RATE, rock.work
		]
	)
	## 1.25 s of held fire on the same contact: one read on contact, then one per
	## BEAM_HIT_INTERVAL - the hull branch's own cadence.
	var frames := 24
	for _frame in frames:
		guns.call(&"tick", BEAM_FRAME)
	var total := _bursts().size()
	print("[G4-BEAM] rock %.2f s held: bursts=%d work=%.4f" % [
		float(frames + 1) * BEAM_FRAME, total, rock.work
	])
	var expected := 1 + int(floor(float(frames) * BEAM_FRAME / WeaponScript.BEAM_HIT_INTERVAL))
	_check(total == expected, "reads=%d expected=%d (one on contact, then per %.2f s)" % [
		total, expected, WeaponScript.BEAM_HIT_INTERVAL
	])
	_check(
		_near(rock.work, 30.0 * float(frames + 1) * BEAM_FRAME * WeaponScript.GUN_CHIP_RATE),
		"the chip work stays dps x time x %.2f (%.4f)" % [
			WeaponScript.GUN_CHIP_RATE, rock.work
		]
	)
	## Energy: the laser's own draw, unchanged by the chip read.
	var before: float = float(rig[&"state"].get(&"energy"))
	guns.call(&"tick", BEAM_FRAME)
	var after: float = float(rig[&"state"].get(&"energy"))
	print("[G4-BEAM] energy draw per frame=%.4f over %.2f s frame (row draw=%.1f)" % [
		before - after, BEAM_FRAME, float(WeaponScript.row_of(&"laser").get(&"draw", 0.0))
	])
	_check(
		_near(before - after, 6.0 * BEAM_FRAME, 0.0001),
		"the beam spends the row's own 6 E/s"
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)
	rock.free()
	rig[&"hull"].free()


## --- 3. the held beam's fire feedback --------------------------------------


func _held_feedback() -> void:
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var holds := [0]
	guns.connect(&"shot_fired", func(_weapon: StringName) -> void: holds[0] += 1)
	print("[G4-BEAM] flash cycle declared FLASH_SECONDS=%.4f frames=%d fps=%.1f" % [
		WeaponScript.FLASH_SECONDS,
		WeaponScript.FLASH_FRAMES.size(),
		WeaponScript.FLASH_FPS,
	])
	_check(
		_near(WeaponScript.FLASH_SECONDS, float(WeaponScript.FLASH_FRAMES.size()) / WeaponScript.FLASH_FPS),
		"the repeat cycle is the flash sheet's own 4/20 s"
	)
	var frames := 100
	var spawns: Array[int] = []
	var previous := 0
	guns.call(&"set_firing", true)
	for frame in frames:
		guns.call(&"tick", FINAL_DELTA)
		var count := _flash_count(guns)
		if count > previous:
			spawns.append(frame)
			previous = count
	var held_for := float(frames) * FINAL_DELTA
	print("[G4-BEAM] held %.2f s: flashes=%d at frames=%s emissions=%d" % [
		held_for, _flash_count(guns), str(spawns), holds[0]
	])
	_check(holds[0] == 1, "shot_fired stays one emission per hold")
	## The opening flash is frame 0; a replay lands every FLASH_SECONDS after it, so a
	## window of `frames` ticks (0 .. frames-1) holds the opening one plus the replays
	## that fall inside it.
	var cycles := int(floor(float(frames - 1) * FINAL_DELTA / WeaponScript.FLASH_SECONDS))
	print("[G4-BEAM] expected flashes=%d (1 opening + %d replays in %.2f s)" % [
		1 + cycles, cycles, float(frames - 1) * FINAL_DELTA
	])
	_check(
		_flash_count(guns) == 1 + cycles,
		"the feedback repeats for the whole hold: %d flashes at %.2f s a cycle" % [
			_flash_count(guns), WeaponScript.FLASH_SECONDS
		]
	)
	## The cadence is the declared cycle, frame by frame.
	var cadence_ok := true
	for index in spawns.size():
		var expected_frame := index * int(round(WeaponScript.FLASH_SECONDS / FINAL_DELTA))
		if spawns[index] != expected_frame:
			cadence_ok = false
	_check(cadence_ok, "each replay lands one cycle later (frames=%s)" % str(spawns))
	## Release: the feedback stops and does not come back on its own.
	var at_release := _flash_count(guns)
	guns.call(&"set_firing", false)
	for _frame in 50:
		guns.call(&"tick", FINAL_DELTA)
	print("[G4-BEAM] released 1.00 s: flashes=%d (at release %d) emissions=%d" % [
		_flash_count(guns), at_release, holds[0]
	])
	_check(
		_flash_count(guns) == at_release,
		"a released trigger stops the feedback"
	)
	_check(holds[0] == 1, "and emits nothing more")
	rig[&"hull"].free()


## --- 4. the same loop under real frames (does it leak?) ---------------------


## The frame-less loop above proves the cadence; this proves the loop's lifetime on the
## engine's own clock: the flash is a one-shot freed by its own animation, so a real
## frame run must hold at most one or two live flashes and settle back to zero after
## release. A monotonic child count would be the leak a "loop" invites.
func _held_real_frames() -> void:
	var rig := _rig()
	var guns: Node2D = rig[&"guns"]
	var spawns := 0
	var max_live := 0
	var previous := 0
	guns.call(&"set_firing", true)
	var frames := 72
	for _frame in frames:
		await get_tree().physics_frame
		var live := _flash_count(guns)
		if live > previous:
			spawns += live - previous
		previous = live
		max_live = maxi(max_live, live)
	print("[G4-BEAM] real frames %.2f s held: spawns=%d max_live=%d last_live=%d" % [
		float(frames) / 60.0, spawns, max_live, _flash_count(guns)
	])
	var expected := 1 + int(floor((float(frames) / 60.0 - 0.2) / WeaponScript.FLASH_SECONDS))
	_check(
		spawns >= expected - 1 and spawns <= expected + 1,
		"the flash replays about %d times over %.2f s of held fire (spawns=%d)" % [
			expected, float(frames) / 60.0, spawns
		]
	)
	_check(max_live <= 2, "no more than two flashes are alive at once (max=%d)" % max_live)
	guns.call(&"set_firing", false)
	for _frame in 40:
		await get_tree().physics_frame
	print("[G4-BEAM] 0.67 s after release: live_flashes=%d beam_visible=%s" % [
		_flash_count(guns), str((guns.get(&"_beam_halo") as Line2D).visible)
	])
	_check(_flash_count(guns) == 0, "the loop's flashes are all gone after release")
	_check(
		not (guns.get(&"_beam_halo") as Line2D).visible
		and not (guns.get(&"_beam_core") as Line2D).visible,
		"and the shaft is hidden"
	)
	rig[&"hull"].free()


## --- Fixtures --------------------------------------------------------------

func _rig(aim_distance: float = FAR_AIM) -> Dictionary:
	var hull := Node2D.new()
	hull.name = &"G4Hull"
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


## A real body on the rock layer, so `_beam_target`'s ray can resolve it.
func _rock(distance: float) -> StaticBody2D:
	var rock := RockBody.new()
	rock.name = &"G4Rock"
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


class RockBody extends StaticBody2D:
	var work := 0.0

	func apply_work(amount: float) -> void:
		work += amount


## The drawn shaft's end, in the component's own space (the component sits at the
## rig's origin, so this is the world x it stopped at).
func _beam_endpoint(guns: Node2D) -> float:
	var core := guns.get(&"_beam_core") as Line2D
	if core == null or core.points.size() < 2:
		return -1.0
	return core.points[1].length()


## What `_beam_target` resolves for the same frame's segment, for the comparison.
func _resolved(guns: Node2D) -> float:
	var aim: Vector2 = Vector2(FAR_AIM, 0.0)
	var reach := minf(aim.length(), WeaponScript.range_of(&"laser"))
	var target: Dictionary = guns.call(&"_beam_target", Vector2.ZERO, Vector2(reach, 0.0))
	if target.is_empty():
		return -1.0
	return (target[&"point"] as Vector2).length()


## Every effect node in the fixture drawing from the mining sheet. A second burst of the
## same hold arrives renamed (`@chip@2`; two siblings cannot share one name), so the
## counter reads the master each node draws from, not its name.
func _bursts() -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in _root.get_children():
		if not (child is AnimatedSprite2D):
			continue
		var sprite := child as AnimatedSprite2D
		if sprite.sprite_frames == null:
			continue
		if sprite.sprite_frames.get_frame_count(FxScript.ANIMATION) == 0:
			continue
		var texture := sprite.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
		if texture is AtlasTexture and (texture as AtlasTexture).atlas != null:
			if (texture as AtlasTexture).atlas.resource_path == MINING_SHEET:
				out.append(child)
	return out


func _flash_count(guns: Node2D) -> int:
	var count := 0
	for child: Node in guns.get_children():
		if child is AnimatedSprite2D:
			count += 1
	return count


func _audio() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("AudioManager")


func _near(a: float, b: float, tolerance: float = 0.001) -> bool:
	return absf(a - b) <= tolerance


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[G4-BEAM] OK   %s" % message)
		return
	_failures += 1
	print("[G4-BEAM] FAIL %s" % message)
