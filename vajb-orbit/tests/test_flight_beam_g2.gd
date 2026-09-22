@tool
extends McpTestSuite
## Suite flight_beam_g2: the beam polish of the flight-feel & beam wave (brief
## `.agents/gen/flight_beam_wave_task.md`, worker G2) - the shaft stopping on the point
## its ray resolved, the cue and the chip-sparks burst a gun chipping a rock gets, and
## the held beam's fire feedback repeating for as long as the trigger is held.
##
## Everything here is synchronous: the gate's runner calls a test method and never awaits
## a frame (`headless_runner.gd`), so nothing asserts on a timer, a tween or a physics
## step. Two consequences the fixtures respect:
##
##  * `_beam_target`'s physics ray cannot see a body added this frame (measured: the ray
##    is empty for a collider born in the same frame), so the resolved-hit case is driven
##    through the other half of `_beam_target` - a destructible shot on the segment, the
##    route `test_weapon_fx_f4.gd` uses - which yields a real `point` to stop the shaft on.
##  * a spawned sheet never reaches its `animation_finished` while no frame passes, so a
##    count of live effect nodes is a count of what the code asked for, not of what a
##    clock has retired.
##
## Contract: docs/design/FX_SPEC.md section 1.2 (the flash, "4 frames at 20 FPS = 0.2 s
## total, one-shot, no loop"), section 1.6 (the engine-drawn beam and the chip sparks,
## "4-frame mini sheet at 20 FPS = 0.2 s, one-shot per S8 chip event"), line 138 (the
## chip sheet's file name); the re-cut frames carry their own alpha, so the chip burst
## is blended with it (`.agents/gen/slice2_5_s3_report.md` section 3);
## docs/design/AUDIO_SPEC.md section 8's S8 chip transient; docs/CONTRACTS.md section 4
## (`shot_fired`: "once per released shot / per beam hold").

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FxScript := preload("res://game/fx.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const FLASH_FRAME_ONE := "res://assets/fx/fx_muzzle_flash_f1.png"
const MINING_SHEET := "res://assets/fx/fx_mining_beam_f1.png"

const CHIP_FRAMES := 4
const CHIP_FPS := 20.0
const BEAM_FRAME := 0.05
const AIM_DISTANCE := 300.0
const ROCKET_DISTANCE := 60.0
const ROCK_DISTANCE := 120.0
const JITTER_TOLERANCE := 0.001
const MIX := CanvasItemMaterial.BLEND_MODE_MIX

## The two seams `weapons.gd` reaches for on its host (`apply_recoil`, `impact_body`).
## A probe fixture, not a hull: nothing here simulates.
class StubHull extends Node2D:
	var recoil := Vector2.ZERO

	func apply_recoil(recoil_velocity: Vector2, _mass: float) -> void:
		recoil += recoil_velocity

	func impact_body() -> RigidBody2D:
		return null

	func velocity() -> Vector2:
		return Vector2.ZERO


## The rock half of `_apply_beam`: a node in the shipped rock's own group carrying the
## shipped rock's own `apply_work`, recording what the beam offered it. No physics: the
## branch is called directly, the way `test_weapon_fx_f4.gd` calls the hull branch.
class StubRock extends Node2D:
	var work := 0.0
	var calls := 0

	func apply_work(amount: float) -> int:
		calls += 1
		work += amount
		return 0


var _root: Node2D = null

## The audio service's pool cursors, snapshotted in `suite_setup` and put back in
## `suite_teardown`. `AudioManager` is an autoload shared by every suite, and this suite
## fires beams - each of which plays its family's cue through the round-robin pool and so
## advances a cursor another suite reads (`test_weapon_fx_f1.gd` asserts the laser pool
## cycles from take 0). A suite that fires has to leave that cursor where it found it, so
## its own reads are not another test's state.
var _pool_state: Dictionary = {}
var _had_pool_state := false


func suite_name() -> String:
	return "flight_beam_g2"


func suite_setup(_ctx: Dictionary) -> void:
	_snapshot_pools()
	_root = Node2D.new()
	_root.name = &"G2Fixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	_restore_pools()


func setup() -> void:
	_clear()


func teardown() -> void:
	_clear()


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


## Put them back. `Object.get` hands the live dictionary, so it is restored in place.
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


## --- W2: the shaft stops on the point it resolved (FX_SPEC section 1.6) ----


## A miss keeps the weapon's own reach: the shaft is still drawn to the aim point, which
## is the half of the old behaviour the owner asked to keep.
func test_a_shot_that_hits_nothing_still_draws_the_weapons_own_reach() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	var halo := _beam_line(guns)
	assert_true(halo != null, "the instant family draws its shaft")
	if halo == null:
		return
	assert_eq(halo.points.size(), 2, "the shaft runs from the muzzle to its reach")
	assert_true(
		_near(halo.points[1].length(), AIM_DISTANCE),
		"the shaft ends at the aim point inside the weapon's range (%.1f)"
		% halo.points[1].length()
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)


## A resolved hit stops the shaft where the target is, so the beam no longer runs through
## what it hit to the aim point behind it (the owner's third-round finding W2).
func test_the_shaft_stops_on_the_point_its_ray_resolved() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var rocket := _staged_rocket(guns, ROCKET_DISTANCE)
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	var halo := _beam_line(guns)
	assert_true(halo != null, "the instant family draws its shaft")
	if halo == null:
		return
	assert_true(rocket != null, "the fixture put a destructible shot on the segment")
	assert_true(
		_near(halo.points[1].x, ROCKET_DISTANCE),
		"the shaft ends on the target's own point (%.1f)" % halo.points[1].x
	)
	assert_true(
		halo.points[1].length() < AIM_DISTANCE,
		"and not on the aim point behind it (%.1f)" % halo.points[1].length()
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)


## --- W3: a gun chipping a rock reads like the shaft does -------------------


func test_a_laser_chipping_a_rock_plays_the_chip_cue_and_the_burst() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_eq(
		WeaponScript.CHIP_CUE,
		MiningLaserScript.CHIP_CUE,
		"the chip cue is the mining laser's own S8 take, so the two cannot drift"
	)
	assert_eq(
		AsteroidScript.ROCK_GROUP,
		ProjectileScript.ROCK_GROUP,
		"and the group the branch reads is the shipped rock's own"
	)
	assert_true(
		String(audio.call(&"cue_path", WeaponScript.CHIP_CUE)) != "",
		"S8's take resolves through the manager's own lookup"
	)
	assert_true(
		ProjectileScript.FEEDBACK.has(&"chip"),
		"FX_SPEC section 1.6's chip sparks are a row of the effect table"
	)
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var rock := _stub_rock(Vector2(ROCK_DISTANCE, 0.0))
	## The first frame of contact: S8's cue, section 1.6's burst, and the chip work the
	## branch already applied - which this wave must not have moved.
	_beam_frame(guns, rock)
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		WeaponScript.CHIP_CUE,
		"a laser chipping a rock plays the chip cue (it played nothing before)"
	)
	assert_true(
		_near(rock.work, 30.0 * BEAM_FRAME * WeaponScript.GUN_CHIP_RATE),
		"the chip work is the row's dps x delta x the 10 %% rate, unchanged (%.4f)" % rock.work
	)
	var bursts := _fx_nodes_from(MINING_SHEET)
	assert_eq(bursts.size(), 1, "and draws FX_SPEC section 1.6's chip-sparks burst")
	if bursts.is_empty():
		return
	var burst := bursts[0]
	_assert_alpha(burst)
	var sprite := burst as AnimatedSprite2D
	assert_true(sprite != null, "the burst is an animation")
	if sprite != null and sprite.sprite_frames != null:
		var frames := sprite.sprite_frames
		assert_eq(
			frames.get_frame_count(FxScript.ANIMATION),
			CHIP_FRAMES,
			"section 1.6's four-frame mini sheet"
		)
		assert_true(
			_near(frames.get_animation_speed(FxScript.ANIMATION), CHIP_FPS),
			"at the spec's own 20 FPS"
		)
		assert_false(
			frames.get_animation_loop(FxScript.ANIMATION),
			"one-shot per S8 chip event"
		)
	assert_true(
		(burst as Node2D).global_position.distance_to(rock.global_position)
			<= WeaponScript.HIT_FX_JITTER_MIN + JITTER_TOLERANCE,
		"the burst sits inside the pinned disc of the point the beam reached"
	)


func test_a_held_beams_rock_chip_reads_on_hulls_own_contact_guard() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var rock := _stub_rock(Vector2(ROCK_DISTANCE, 0.0))
	_beam_frame(guns, rock)
	assert_eq(_fx_nodes_from(MINING_SHEET).size(), 1, "the first frame of contact chips")
	## A frame the guard holds back plays neither the cue nor the burst: seed the cue
	## observable with something else and watch it survive the frame.
	var seeded := &"sfx_impact_rock"
	audio.call(&"play_sfx", seeded)
	_beam_frame(guns, rock)
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		seeded,
		"a frame the guard holds back plays no chip cue"
	)
	assert_eq(
		_fx_nodes_from(MINING_SHEET).size(),
		1,
		"and draws no second burst"
	)
	for _frame in 8:
		_beam_frame(guns, rock)
	assert_eq(
		_fx_nodes_from(MINING_SHEET).size(),
		2,
		"one chip on the first frame of contact and one after BEAM_HIT_INTERVAL, not one per frame"
	)
	## A fresh contact is not the old contact's clock: it chips at once.
	var other := _stub_rock(Vector2(-ROCK_DISTANCE, 0.0))
	_beam_frame(guns, other)
	assert_eq(
		_fx_nodes_from(MINING_SHEET).size(),
		3,
		"a fresh rock chips on its own first frame"
	)


## --- W4: a held beam's fire feedback repeats ------------------------------


func test_a_held_beams_feedback_repeats_for_as_long_as_the_trigger_is_held() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var holds := [0]
	guns.connect(&"shot_fired", func(_weapon: StringName) -> void: holds[0] += 1)
	assert_true(
		_near(
			WeaponScript.FLASH_SECONDS,
			float(WeaponScript.FLASH_FRAMES.size()) / WeaponScript.FLASH_FPS
		),
		"the repeat cycle is the flash sheet's own: 4 frames at 20 FPS, not a new number"
	)
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	assert_eq(_flash_count(guns), 1, "the hold opens with the one flash it always had")
	## Four frames of 0.05 s is one 0.2 s cycle: the feedback has come round again.
	for _frame in 3:
		guns.call(&"tick", BEAM_FRAME)
	assert_eq(
		_flash_count(guns),
		2,
		"and comes round again a cycle later, instead of one flash per release"
	)
	assert_eq(holds[0], 1, "shot_fired stays one per hold: only the feedback repeats")
	## Two more cycles: the feedback keeps pace with the hold.
	for _frame in 8:
		guns.call(&"tick", BEAM_FRAME)
	assert_eq(_flash_count(guns), 4, "the feedback keeps pace with the hold")
	assert_eq(holds[0], 1, "and the pinned signal still announces the hold once")
	## Release: the feedback stops with the beam.
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)
	var after_release := _flash_count(guns)
	for _frame in 8:
		guns.call(&"tick", BEAM_FRAME)
	assert_eq(_flash_count(guns), after_release, "a released trigger stops the feedback")
	## A second pull opens its own loop from its own opening flash.
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	assert_eq(
		_flash_count(guns),
		after_release + 1,
		"a new hold opens with its own flash"
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)


## --- Fixtures -------------------------------------------------------------


## A mounted `WeaponComponent` under a stub hull: a live `PlayerState` and the fit under
## test, aimed `AIM_DISTANCE` to starboard (the rig the F1/F4 suites use).
func _rig(ids: Array) -> Dictionary:
	var hull := StubHull.new()
	hull.name = &"G2Hull"
	_root.add_child(hull)
	var guns := WeaponScript.new() as Node2D
	guns.name = &"WeaponComponent"
	hull.add_child(guns)
	var state: Variant = PlayerStateScript.new()
	state.call(&"setup")
	guns.call(&"setup", null, state)
	var fitted: Array[StringName] = []
	for id: Variant in ids:
		fitted.append(StringName(id))
	guns.call(&"set_fitted", fitted)
	guns.call(&"set_aim_point", guns.global_position + Vector2(AIM_DISTANCE, 0.0))
	return {&"hull": hull, &"guns": guns, &"state": state}


## The rock the beam's other branch reads: the shipped group and the shipped method.
func _stub_rock(at: Vector2) -> StubRock:
	var rock := StubRock.new()
	rock.name = &"G2Rock"
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_root.add_child(rock)
	rock.global_position = at
	return rock


## One frame of the beam's rock branch, called where `_fire_beam` calls it: the family's
## own row and the collider the ray would have resolved.
func _beam_frame(guns: Node2D, collider: Node2D, delta: float = BEAM_FRAME) -> void:
	guns.call(
		&"_apply_beam",
		&"laser",
		WeaponScript.row_of(&"laser"),
		collider,
		collider.global_position,
		delta
	)


## A rocket of the shooter's own making, on the beam's segment at `distance`: a
## destructible shot is the one target kind `_beam_target` resolves without a physics
## frame (`_rocket_on_segment` measures distance to the segment, not an overlap).
func _staged_rocket(guns: Node2D, distance: float) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "BeamRocket"
	shot.call(
		&"configure",
		{&"kind": ProjectileScript.KIND_ROCKET, &"speed": 0.0, &"damage": 180.0, &"mass": 1.0}
	)
	_root.add_child(shot)
	shot.global_position = guns.global_position + Vector2(distance, 0.0)
	return shot


## --- Readers --------------------------------------------------------------


## The engine-drawn shaft's halo line, the wide dim one under the core.
func _beam_line(guns: Node) -> Line2D:
	return guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D


## The muzzle flashes up on the mount right now. The flash's own node name is not its
## identity (a second one of the same hold arrives renamed), so they are counted by the
## sheet they draw from.
func _flash_count(guns: Node) -> int:
	var count := 0
	for child: Node in guns.get_children():
		var sprite := child as AnimatedSprite2D
		if sprite != null and _sheet_of(sprite) == FLASH_FRAME_ONE:
			count += 1
	return count


## Every effect node in the fixture drawing from `sheet` (a hit's effect hangs from the
## world node the thing that was hit lives in).
func _fx_nodes_from(sheet: String) -> Array[Node]:
	var out: Array[Node] = []
	if _root == null or not is_instance_valid(_root):
		return out
	for child: Node in _root.get_children():
		if _sheet_of(child) == sheet:
			out.append(child)
	return out


func _sheet_of(node: Node) -> String:
	var texture := _texture_of(node)
	if texture == null:
		return ""
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return atlas.atlas.resource_path if atlas.atlas != null else ""
	return texture.resource_path


func _texture_of(node: Node) -> Texture2D:
	var sprite := node as Sprite2D
	if sprite != null:
		return sprite.texture
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		if animated.sprite_frames.has_animation(FxScript.ANIMATION):
			return animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
	return null


## The re-cut sheets carry their own alpha, so every one of them is blended with it (the
## owner's 2026-09-21 ruling; FX_SPEC section 0.1's carve-out was the same rule for the
## four effects that were keyed first).
func _assert_alpha(node: CanvasItem) -> void:
	var material := node.material as CanvasItemMaterial
	assert_true(material != null, "an fx sheet carries its own canvas material")
	if material == null:
		return
	assert_eq(
		material.blend_mode,
		MIX,
		"the sheet's own alpha is the blend: no black box, no additive blow-out"
	)

## A clean fixture between tests. A live rocket is a target on the beam's segment, so
## shots are cleared with the rest - but the weapons under test are not shots, so the
## fixture's own children are cleared first and the shots after.
func _clear() -> void:
	if _root == null or not is_instance_valid(_root):
		return
	for child: Node in _root.get_children():
		if is_instance_valid(child):
			child.free()
	var tree := _tree()
	if tree == null:
		return
	for shot: Node in tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		if is_instance_valid(shot):
			shot.free()


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


func _near(measured: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(measured - expected) <= tolerance
