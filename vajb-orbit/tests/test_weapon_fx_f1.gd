@tool
extends McpTestSuite
## Suite weapon_fx_f1: the fire-and-travel feedback of the weapon FX & audio wave
## (brief `.agents/gen/weapon_fx_wave_task.md`, worker F1) - the shot's own sprite,
## the muzzle flash, the instant families' engine-drawn beam and the family fire cue
## through `AudioManager`'s pools, plus the mining shaft's beam bed.
##
## Everything here is synchronous: the gate's runner calls a test method and never
## awaits a frame (`headless_runner.gd`), so nothing asserts on a timer, a tween or a
## physics step. Audio cannot be heard headless, so a cue that went out is read from
## `AudioManager.last_sfx()` or from the plan `play_pool` returns, and every
## `res://assets/` path is resolved before the node that reads it is asserted on.
##
## Contract: docs/design/FX_SPEC.md sections 0 (void-black/additive), 1.1 (the bolt
## sheet), 1.2 (the four-frame flash at 20 FPS), 1.6 (the engine-drawn beam) and 7.3
## (one-shot sheets free themselves); docs/design/AUDIO_SPEC.md section 8's cue table
## and section 4.1's variant rules; docs/design/ASSET_WIRING_HANDOFF.md sections
## 1.1/1.2 (the pools and their ranges) and 3 (consumer rules).

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FxScript := preload("res://game/fx.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const MiningLaserScene := preload("res://game/mining_laser.tscn")
const AudioScript := preload("res://autoload/audio_manager.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const LASER_POOL: StringName = &"sfx_weapon_laser"
const CANNON_POOL: StringName = &"sfx_weapon_cannon"
const ROCKET_POOL: StringName = &"sfx_weapon_rocket"

const BOLT_SHEET := "res://assets/fx/fx_laser_bolt.png"
const TRAIL_SHEET := "res://assets/fx/fx_missile_trail.png"
const MINE_SHEET := "res://assets/fx/fx_ember_pulse.png"
const FLASH_FRAME_ONE := "res://assets/fx/fx_muzzle_flash_f1.png"
const BEAM_BED_PATH := "res://assets/audio/sfx/sfx_mining_beam_01.ogg"

const FLASH_FRAMES := 4
const TRAIL_FRAMES := 4
const FLASH_FPS := 20.0
const BOLT_LENGTH := 64.0
const SLUG_LENGTH := 96.0
const AIM_DISTANCE := 300.0
const WARHEAD_DELAY := 0.08
const TOLERANCE := 0.001
const ADD := CanvasItemMaterial.BLEND_MODE_ADD

## The two seams `weapons.gd` reaches for on its host (`apply_recoil`, `impact_body`).
## A probe fixture, not a hull: nothing here simulates.
class StubHull extends Node2D:
	var recoil := Vector2.ZERO

	func apply_recoil(velocity: Vector2, _mass: float) -> void:
		recoil += velocity

	func impact_body() -> RigidBody2D:
		return null

	func velocity() -> Vector2:
		return Vector2.ZERO


var _root: Node2D = null


func suite_name() -> String:
	return "weapon_fx_f1"


func suite_setup(_ctx: Dictionary) -> void:
	_root = Node2D.new()
	_root.name = &"F1Fixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear_world()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func setup() -> void:
	_clear_world()


func teardown() -> void:
	## A released shot is a world object and the mining bed outlives a fixture; the
	## fixture owns neither, so both are cleared between tests.
	_clear_world()


## --- The shot's sprite (FX_SPEC sections 0/1.1, Phase G's trail sheet) ----


func test_the_bolt_kind_draws_the_bolt_sheets_thin_cut() -> void:
	var shot := _staged_shot(ProjectileScript.KIND_BOLT)
	var visual := _sprite_of(shot)
	assert_true(visual != null, "the bolt kind draws a sprite")
	if visual == null:
		return
	var atlas := visual.texture as AtlasTexture
	assert_true(atlas != null, "the sprite is a region of a shipped 2K master")
	if atlas == null:
		return
	assert_eq(atlas.atlas.resource_path, BOLT_SHEET, "FX_SPEC 1.1's bolt sheet")
	assert_eq(atlas.region, ProjectileScript.SHEETS[&"bolt"][&"region"], "the sheet's thin object")
	_assert_additive(visual)
	assert_true(
		_near(visual.scale.x * atlas.region.size.x, BOLT_LENGTH),
		"the light bolt reads the spec's 64 units"
	)


func test_the_slug_kind_draws_the_bolt_sheets_other_cut() -> void:
	var shot := _staged_shot(ProjectileScript.KIND_SLUG)
	var visual := _sprite_of(shot)
	if visual == null:
		assert_true(false, "the slug kind draws a sprite")
		return
	var atlas := visual.texture as AtlasTexture
	if atlas == null:
		assert_true(false, "the slug sprite is a sheet region")
		return
	assert_eq(atlas.atlas.resource_path, BOLT_SHEET, "the same sheet, the heavier read")
	assert_eq(atlas.region, ProjectileScript.SHEETS[&"slug"][&"region"], "the sheet's thick object")
	assert_ne(atlas.region, ProjectileScript.SHEETS[&"bolt"][&"region"], "the two kinds differ")
	_assert_additive(visual)
	assert_true(
		_near(visual.scale.x * atlas.region.size.x, SLUG_LENGTH),
		"the medium bolt reads the spec's 96 units"
	)


func test_the_homing_kind_animates_the_missile_trail() -> void:
	var shot := _staged_shot(ProjectileScript.KIND_ROCKET)
	var visual := _sprite_of(shot) as AnimatedSprite2D
	assert_true(visual != null, "the seeker flies on the trail sheet")
	if visual == null:
		return
	var frames := visual.sprite_frames
	assert_eq(frames.get_frame_count(FxScript.ANIMATION), TRAIL_FRAMES, "the sheet's four frames")
	assert_true(
		frames.get_animation_loop(FxScript.ANIMATION),
		"the exhaust loops for as long as the rocket flies"
	)
	_assert_additive(visual)
	var first := frames.get_frame_texture(FxScript.ANIMATION, 0) as AtlasTexture
	assert_true(first != null, "each trail frame is a region of the master")
	if first != null:
		assert_eq(first.atlas.resource_path, TRAIL_SHEET, "the Phase G trail sheet")


func test_the_mine_kind_is_one_additive_frame() -> void:
	var shot := _staged_shot(ProjectileScript.KIND_MINE)
	var visual := _sprite_of(shot)
	if visual == null:
		assert_true(false, "the deployable draws a body")
		return
	var atlas := visual.texture as AtlasTexture
	if atlas == null:
		assert_true(false, "the mine sprite is a sheet region")
		return
	assert_eq(atlas.atlas.resource_path, MINE_SHEET, "an ember body, drawn from the shipped art")
	_assert_additive(visual)
	assert_true(_near(visual.rotation, 0.0), "a mine has no bearing to carry")


func test_the_sprite_carries_the_shots_bearing() -> void:
	var shot := _staged_shot(ProjectileScript.KIND_BOLT, Vector2.UP)
	var visual := _sprite_of(shot)
	assert_true(visual != null, "the bolt draws")
	if visual != null:
		assert_true(
			_near(visual.rotation, Vector2.UP.angle()),
			"the sheet points right, so the sprite turns with the travel"
		)


## --- The muzzle flash (FX_SPEC section 1.2) -------------------------------


func test_the_muzzle_flash_is_the_four_frame_sheet() -> void:
	var guns := _fire_once(&"cannon")
	var flash := _flash_of(guns)
	assert_true(flash != null, "a released shot spawns the muzzle flash")
	if flash == null:
		return
	var frames := flash.sprite_frames
	assert_eq(frames.get_frame_count(FxScript.ANIMATION), FLASH_FRAMES, "section 1.2's four frames")
	assert_true(
		_near(frames.get_animation_speed(FxScript.ANIMATION), FLASH_FPS),
		"the spec's 20 FPS (0.2 s)"
	)
	assert_false(frames.get_animation_loop(FxScript.ANIMATION), "the flash plays once")
	assert_false(flash.centered, "the frame's own mouth, not its middle, sits on the muzzle")
	_assert_additive(flash)
	var first := frames.get_frame_texture(FxScript.ANIMATION, 0)
	assert_true(first != null, "frame 1 is the pre-cut export")
	if first != null:
		assert_eq(first.resource_path, FLASH_FRAME_ONE, "the shipped frame 1")


func test_the_muzzle_flash_frees_itself_when_it_ends() -> void:
	var guns := _fire_once(&"cannon")
	var flash := _flash_of(guns)
	assert_true(flash != null, "the flash is up")
	if flash == null:
		return
	assert_true(
		flash.get_signal_connection_list(&"animation_finished").size() > 0,
		"FX_SPEC 7.3: the flash owns its own lifetime"
	)
	flash.emit_signal(&"animation_finished")
	assert_true(flash.is_queued_for_deletion(), "and frees on the last frame")


func test_the_muzzle_flash_rides_the_muzzle_and_the_aim() -> void:
	var rig := _rig([&"cannon"])
	var guns: Node2D = rig[&"guns"]
	guns.call(&"set_aim_point", guns.global_position + Vector2(0.0, -AIM_DISTANCE))
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.016)
	var flash := _flash_of(guns)
	assert_true(flash != null, "the flash is up")
	if flash == null:
		return
	assert_true(
		_near(flash.rotation, Vector2.UP.angle() - guns.global_rotation),
		"the flash points down the aim, in the mount's own space"
	)
	assert_true(flash.position.x < 0.0, "the barrel art sits behind the muzzle")


## --- The instant families' beam (FX_SPEC section 1.6) ---------------------


func test_the_instant_families_draw_an_engine_side_beam() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.016)
	var halo := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D
	var core := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[1])) as Line2D
	assert_true(halo != null and core != null, "section 1.6: the shaft is engine-drawn")
	if halo == null or core == null:
		return
	assert_true(halo.visible and core.visible, "a held trigger draws the shaft")
	assert_eq(halo.points.size(), 2, "the shaft runs from the muzzle to its reach")
	assert_true(
		_near(halo.points[1].length(), AIM_DISTANCE),
		"the shaft ends at the aim point inside the weapon's range"
	)
	assert_true(halo.width > core.width, "a wide dim halo under a thin bright core")
	_assert_additive(halo)


func test_the_beam_goes_out_when_the_trigger_is_released() -> void:
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.016)
	var halo := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D
	assert_true(halo != null and halo.visible, "the shaft is up while firing")
	guns.call(&"set_firing", false)
	guns.call(&"tick", 0.016)
	if halo != null:
		assert_false(halo.visible, "releasing the trigger puts the shaft out")


## --- The family fire cue (AUDIO_SPEC section 8, handoff section 1.2) ------


func test_the_cannon_fires_the_cannon_pools_first_tier() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_fire_once(&"cannon")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		&"sfx_weapon_cannon_01",
		"the cannon is S2's tier 1"
	)


func test_the_railgun_fires_the_cannon_pools_second_tier() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_fire_once(&"railgun")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		&"sfx_weapon_cannon_02_medium",
		"the heavier kinetic takes the heavier take"
	)


func test_the_energy_families_fire_the_laser_pool() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	for weapon_id: StringName in [&"laser", &"plasma"]:
		_fire_once(weapon_id)
		var played := StringName(audio.call(&"last_sfx"))
		assert_true(
			AudioScript.CUE_POOLS[LASER_POOL][&"takes"].has(played),
			"%s plays a take of S1's laser pool (played %s)" % [weapon_id, played]
		)


func test_the_rocket_fires_the_launch_layer() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_fire_once(&"rocket")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		&"sfx_weapon_rocket_01",
		"S3's launch layer goes out first"
	)


func test_the_mine_drops_with_no_cue() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_fire_once(&"cannon")
	var before := StringName(audio.call(&"last_sfx"))
	_fire_once(&"mine")
	assert_eq(WeaponScript.fire_cue_of(&"mine"), &"", "AUDIO_SPEC 8 states no deployable cue")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		before,
		"so the mine's drop leaves the last cue alone"
	)


func test_the_fire_cue_table_is_the_handoffs_pools() -> void:
	assert_eq(WeaponScript.fire_cue_of(&"laser"), LASER_POOL, "S1 for the light energy weapon")
	assert_eq(WeaponScript.fire_cue_of(&"plasma"), LASER_POOL, "S1's medium tier too")
	assert_eq(WeaponScript.fire_cue_of(&"cannon"), CANNON_POOL, "S2 for the kinetic cannon")
	assert_eq(WeaponScript.fire_cue_of(&"railgun"), CANNON_POOL, "and for the railgun")
	assert_eq(WeaponScript.fire_cue_of(&"rocket"), ROCKET_POOL, "S3 for the rocket")
	assert_eq(WeaponScript.fire_take_of(&"cannon"), 0, "the cannon fires tier 1")
	assert_eq(WeaponScript.fire_take_of(&"railgun"), 1, "the railgun tier 2")
	assert_eq(WeaponScript.fire_take_of(&"laser"), -1, "an energy family leaves it to the round-robin")


## --- The pools' own behaviour (the API that gap needed) -------------------


func test_the_laser_pool_round_robins_its_takes_within_the_specs_ranges() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var takes: Array = AudioScript.CUE_POOLS[LASER_POOL][&"takes"]
	assert_eq(takes.size(), 4, "takes 01 to 04")
	var heard: Array[StringName] = []
	for index in takes.size():
		var plan: Dictionary = audio.call(&"play_pool", LASER_POOL, -1)
		if plan.is_empty():
			assert_true(false, "take %d resolved" % index)
			return
		heard.append(StringName(plan[&"take"]))
		assert_true(
			plan[&"pitch"] >= 1.0 - AudioScript.CUE_POOLS[LASER_POOL][&"pitch"]
			and plan[&"pitch"] <= 1.0 + AudioScript.CUE_POOLS[LASER_POOL][&"pitch"],
			"pitch within +/-10 %% (%.4f)" % float(plan[&"pitch"])
		)
		assert_true(
			plan[&"volume_db"] >= -3.0 and plan[&"volume_db"] <= 0.0,
			"volume between -3 and 0 dB (%.2f)" % float(plan[&"volume_db"])
		)
	for index in takes.size():
		assert_eq(heard[index], StringName(takes[index]), "take %d in order" % index)


func test_the_pool_reaches_every_cannon_tier() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var takes: Array = AudioScript.CUE_POOLS[CANNON_POOL][&"takes"]
	assert_eq(takes.size(), 3, "S2 ships three lengths")
	for index in takes.size():
		var plan: Dictionary = audio.call(&"play_pool", CANNON_POOL, index)
		if plan.is_empty():
			assert_true(false, "tier %d resolved" % index)
			return
		assert_eq(StringName(plan[&"take"]), StringName(takes[index]), "tier index picks the take")
	var clamped: Dictionary = audio.call(&"play_pool", CANNON_POOL, 99)
	assert_eq(clamped.get(&"take_index", -1), takes.size() - 1, "an out-of-range tier clamps")


func test_the_rocket_pool_layers_the_warhead_eighty_milliseconds_later() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var plan: Dictionary = audio.call(&"play_pool", ROCKET_POOL, -1)
	assert_true(not plan.is_empty(), "the rocket's cue resolves")
	if plan.is_empty():
		return
	assert_eq(StringName(plan[&"take"]), &"sfx_weapon_rocket_01", "the launch layer")
	var layers: Array = plan.get(&"layers", [])
	assert_eq(layers.size(), 1, "one layer follows the launch")
	if layers.size() != 1:
		return
	assert_eq(StringName(layers[0][&"take"]), &"sfx_weapon_rocket_02_warhead", "the warhead")
	assert_true(_near(float(layers[0][&"delay"]), WARHEAD_DELAY), "at +80 ms")


func test_a_cue_without_a_pool_still_plays_through_play_sfx() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_false(bool(audio.call(&"has_pool", &"sfx_mining_chip_01")), "a plain cue owns no pool")
	var plan: Dictionary = audio.call(&"play_pool", &"sfx_mining_chip_01", -1)
	assert_true(plan.is_empty(), "a plain cue plans nothing")
	assert_eq(
		StringName(audio.call(&"last_sfx")),
		&"sfx_mining_chip_01",
		"and plays as it always did"
	)


## --- The mining shaft's bed (AUDIO_SPEC S7) ------------------------------


func test_the_mining_shaft_plays_the_beam_bed_and_stops_with_it() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_eq(MiningLaserScript.CHIP_CUE, &"sfx_mining_chip_01", "S8's chip transient is unchanged")
	assert_eq(MiningLaserScript.BEAM_LOOP_CUE, &"sfx_mining_beam", "S7's bed")
	assert_eq(
		String(audio.call(&"cue_path", MiningLaserScript.BEAM_LOOP_CUE)),
		BEAM_BED_PATH,
		"the bed resolves through the manager's own lookup"
	)
	var laser := MiningLaserScene.instantiate() as Node2D
	assert_true(laser != null, "the mining laser scene loads")
	if laser == null:
		return
	_root.add_child(laser)
	laser.call(&"_draw_beam")
	assert_eq(
		StringName(audio.call(&"current_loop")),
		MiningLaserScript.BEAM_LOOP_CUE,
		"a shaft on a rock starts the bed"
	)
	laser.call(&"_extinguish")
	assert_eq(StringName(audio.call(&"current_loop")), &"", "and puts it out with the shaft")
	laser.free()


## --- Every wired path resolves (handoff section 4) ------------------------


func test_every_wired_sheet_and_cue_resolves() -> void:
	for kind: StringName in ProjectileScript.SHEETS:
		var row: Dictionary = ProjectileScript.SHEETS[kind]
		var path := String(row.get(&"texture", ""))
		assert_true(ResourceLoader.exists(path), "%s's sheet is on disk (%s)" % [kind, path])
		var texture := load(path) as Texture2D
		if texture == null:
			assert_true(false, "%s's sheet loads" % kind)
			continue
		var size := texture.get_size()
		if row.has(&"region"):
			var region: Rect2 = row[&"region"]
			assert_true(
				region.end.x <= size.x and region.end.y <= size.y,
				"%s's region is inside its sheet" % kind
			)
		for frame: Variant in row.get(&"regions", []):
			var rect := frame as Rect2
			assert_true(
				rect.end.x <= size.x and rect.end.y <= size.y,
				"%s's frame region is inside its sheet" % kind
			)
	for path: String in WeaponScript.FLASH_FRAMES:
		assert_true(ResourceLoader.exists(path), "%s is on disk" % path)
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	for cue: Variant in AudioScript.CUE_POOLS:
		var takes: Array = AudioScript.CUE_POOLS[cue].get(&"takes", [])
		assert_true(not takes.is_empty(), "%s has takes" % cue)
		for take: Variant in takes:
			assert_true(
				String(audio.call(&"cue_path", StringName(take))) != "",
				"cue %s resolves" % take
			)
	for cue: StringName in [LASER_POOL, CANNON_POOL, ROCKET_POOL]:
		assert_true(
			String(audio.call(&"cue_path", cue)) != "",
			"the %s cue resolves" % cue
		)


## --- Fixtures -------------------------------------------------------------


## A mounted `WeaponComponent`: a stub host, a live `PlayerState` (a full Energy pool
## and 300 rounds per slot) and the fit under test, aimed `AIM_DISTANCE` to starboard.
func _rig(weapon_ids: Array) -> Dictionary:
	var hull := StubHull.new()
	hull.name = &"StubHull"
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


## One trigger frame on a fresh rig - a release for a travelling family, the beam's
## opening frame for an instant one.
func _fire_once(weapon_id: StringName) -> Node2D:
	var guns: Node2D = _rig([weapon_id])[&"guns"]
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.016)
	return guns


## A configured shot of `kind`, built the way `weapons.gd` builds one (configure, add,
## place) and cleared with the suite.
func _staged_shot(kind: StringName, direction: Vector2 = Vector2.RIGHT) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.call(
		&"configure",
		{&"kind": kind, &"speed": 1000.0, &"direction": direction, &"damage": 10.0}
	)
	_root.add_child(shot)
	shot.global_position = Vector2(500.0, 500.0)
	return shot


func _sprite_of(shot: Node2D) -> Node2D:
	if shot == null:
		return null
	return shot.get_node_or_null(NodePath(ProjectileScript.VISUAL_NODE)) as Node2D


## The flash is the muzzle's only animated child.
func _flash_of(guns: Node) -> AnimatedSprite2D:
	for child: Node in guns.get_children():
		var sprite := child as AnimatedSprite2D
		if sprite != null:
			return sprite
	return null


func _assert_additive(node: CanvasItem) -> void:
	var material := node.material as CanvasItemMaterial
	assert_true(material != null, "an fx sheet carries its own canvas material")
	if material == null:
		return
	assert_eq(
		material.blend_mode,
		ADD,
		"FX_SPEC section 0: RGB on void black is drawn additively"
	)


func _clear_world() -> void:
	var tree := _tree()
	if tree != null:
		for shot: Node in tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
			if is_instance_valid(shot):
				shot.free()
	var audio := _audio()
	if audio != null and audio.has_method(&"stop_loop"):
		audio.call(&"stop_loop", 0.0)


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


func _near(measured: float, expected: float, tolerance: float = TOLERANCE) -> bool:
	return absf(measured - expected) <= tolerance
