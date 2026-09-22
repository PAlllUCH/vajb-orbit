@tool
extends McpTestSuite
## Suite weapon_fx_f4: the fixes the review wave's findings asked for (worker F4,
## `.agents/gen/weapon_fx_f3_report.md`) - the beam's own hit read and its held bed (H1),
## the one-shot pool's same-take voice rule (M1), the loop beds' own voices (M2) and the
## rocket a beam shoots down (M3).
##
## Everything here is synchronous: the gate's runner calls a test method and never awaits
## a frame, so nothing asserts on a timer, a tween or a physics step. A cue that went out
## is read from `AudioManager.last_sfx()` or from what the manager reports is sounding
## (`sounding_loops()`, `voice_takes()`), because audio cannot be heard headless.
##
## Contract: docs/design/AUDIO_SPEC.md section 4.1 (the steal rule and the voice caps),
## section 4.2 (composite cues are sibling loop layers) and section 8's cue table;
## docs/design/FX_SPEC.md section 1.5 (the shield ring); docs/gameplay/18_engine_spec.md
## section 4.1 (the beam's per-frame damage, the rocket's one-hit death).

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FxScript := preload("res://game/fx.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const MiningScript := preload("res://game/mining_laser.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const HULL_POOL: StringName = &"sfx_impact_hull"
const SHIELD_POOL: StringName = &"sfx_impact_shield_hit"
const CANNON_POOL: StringName = &"sfx_weapon_cannon"
const BLAST_POOL: StringName = &"sfx_weapon_explosion"

const RIPPLE_SHEET := "res://assets/fx/fx_shield_ripple_f1.png"
const EXPLOSION_SHEET := "res://assets/fx/fx_explosion_f1.png"
const EXPLOSION_FRAMES := 5

## Two more shipped looping takes, so the beds' voice count can be filled in a test.
const ENGINE_BED: StringName = &"sfx_ship_engine"
const BOILER_BED: StringName = &"sfx_station_boiler_loop"
const SPARE_BED: StringName = &"sfx_ship_engine_02_loop"

const AIM_DISTANCE := 300.0
const BEAM_FRAME := 0.05
const SHIELD_POOL_DEEP := 10000.0
const JITTER_TOLERANCE := 0.001
const MIX := CanvasItemMaterial.BLEND_MODE_MIX


## A hull that answers the pinned sink the way a hull does, with a pool a hit can empty.
## `hull_taken` counts only what reached the hull, so a shield that absorbed a hit leaves
## it at zero - which is also the measurement that the beam's new read changed nothing
## about the damage.
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


func suite_name() -> String:
	return "weapon_fx_f4"


func suite_setup(_ctx: Dictionary) -> void:
	_root = Node2D.new()
	_root.name = &"F4Fixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear()
	_clear_loops()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func setup() -> void:
	_clear()
	_clear_loops()


func teardown() -> void:
	_clear()
	_clear_loops()


## --- H1: the beam's hit reads (AUDIO_SPEC S4/S5, FX_SPEC section 1.5) ------


func test_a_beam_that_lands_on_a_hull_plays_the_impact_cue_and_the_ring() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	## Shields down: S4's hull foley and nothing else.
	var hull := _stub_hull(0.0)
	_beam_frame(guns, hull)
	assert_true(
		String(audio.call(&"last_sfx")).begins_with(String(HULL_POOL)),
		"a beam that lands on a bare hull plays the hull pool (it played nothing before)"
	)
	assert_true(_near(hull.hull_taken, 1.5), "30 dps over a 0.05 s frame, unchanged")
	assert_eq(_fx_nodes_from(RIPPLE_SHEET).size(), 0, "a bare hull draws no ring")
	## Shields up: S5's shield pool, FX_SPEC section 1.5's ring, and S6's bed.
	var guarded := _stub_hull(100.0)
	_beam_frame(guns, guarded)
	assert_true(
		String(audio.call(&"last_sfx")).begins_with(String(SHIELD_POOL)),
		"a hit the shield absorbs reads as the shield"
	)
	var rings := _fx_nodes_from(RIPPLE_SHEET)
	assert_eq(rings.size(), 1, "and draws section 1.5's ring at the contact")
	if rings.is_empty():
		return
	var ring := rings[0]
	_assert_alpha(ring)
	assert_true(
		(ring as Node2D).global_position.distance_to(guarded.global_position)
			<= WeaponScript.HIT_FX_JITTER_MIN + JITTER_TOLERANCE,
		"the ring sits inside the pinned disc of the point the beam reached"
	)
	assert_true(
		_near((ring as Node2D).scale.x, 0.0),
		"and starts collapsed, growing to 1.5x (%.3f)" % (ring as Node2D).scale.x
	)
	assert_eq(
		StringName(audio.call(&"current_loop")),
		ProjectileScript.SHIELD_LOOP_CUE,
		"a shield that holds keeps S6's bed up, like a landed shot"
	)
	assert_true(_near(guarded.shield, 98.5), "the shield took the frame's damage")
	assert_true(_near(guarded.hull_taken, 0.0), "and the hull took none of it")


func test_a_held_beam_reads_one_hit_per_contact_interval() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var hull := _stub_hull(SHIELD_POOL_DEEP)
	for _frame in 10:
		_beam_frame(guns, hull)
	assert_eq(
		_fx_nodes_from(RIPPLE_SHEET).size(),
		2,
		"one read on the first frame of contact and one after BEAM_HIT_INTERVAL, not one per frame"
	)
	## A new contact is not the old contact's clock: it reads at once.
	var other := _stub_hull(SHIELD_POOL_DEEP)
	_beam_frame(guns, other)
	assert_eq(_fx_nodes_from(RIPPLE_SHEET).size(), 3, "a fresh contact reads on its own first frame")
	## And a fresh hold on a hull already read is fresh again: the release clears contact.
	_clear()
	guns.call(&"_hide_beam")
	_beam_frame(guns, hull)
	assert_eq(_fx_nodes_from(RIPPLE_SHEET).size(), 1, "a new hold reads from its own first frame")


func test_a_held_beam_plays_a_bed_and_puts_it_out_with_the_beam() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_eq(
		WeaponScript.BEAM_BED_CUE,
		MiningScript.BEAM_LOOP_CUE,
		"the library's one energy-emission loop is the bed a held beam rides"
	)
	assert_true(
		String(audio.call(&"cue_path", WeaponScript.BEAM_BED_CUE)) != "",
		"and it resolves through the manager's own lookup"
	)
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	assert_true(
		_sounding(audio).has(WeaponScript.BEAM_BED_CUE),
		"a held beam sounds its bed over the whole hold"
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)
	assert_false(
		_sounding(audio).has(WeaponScript.BEAM_BED_CUE),
		"and puts it out with the beam"
	)
	## The release while another bed holds the foreground: an impact hum outranks a held
	## tool's bed in `current_loop()`, so a guarded stop alone cannot reach the beam's own
	## bed (measured; this is what the manager's cue-scoped `stop_bed` is for).
	audio.call(&"play_loop", ProjectileScript.SHIELD_LOOP_CUE)
	guns.call(&"set_firing", true)
	guns.call(&"tick", BEAM_FRAME)
	assert_eq(_sounding(audio).size(), 2, "the beam's bed and the impact hum sound together")
	assert_eq(
		StringName(audio.call(&"current_loop")),
		ProjectileScript.SHIELD_LOOP_CUE,
		"the impact hum is the foreground bed"
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", BEAM_FRAME)
	assert_false(
		_sounding(audio).has(WeaponScript.BEAM_BED_CUE),
		"the beam's bed still goes out"
	)
	assert_true(
		_sounding(audio).has(ProjectileScript.SHIELD_LOOP_CUE),
		"and the hum it does not own stays up"
	)


## --- M1: the one-shot pool's own voice (AUDIO_SPEC section 4.1) -----------


func test_a_repeated_take_re_uses_its_own_voice() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var cannon_take := StringName(AudioScript.CUE_POOLS[CANNON_POOL][&"takes"][0])
	audio.call(&"play_pool", CANNON_POOL, 0)
	audio.call(&"play_pool", CANNON_POOL, 0)
	var owned := _voices_of(audio, cannon_take)
	assert_eq(owned.size(), 1, "a take owns one voice")
	## Six shots over a 0.60 s cadence against a 3.46 s take: the take re-triggers itself
	## instead of stacking into the four voices.
	for _shot in 4:
		audio.call(&"play_pool", CANNON_POOL, 0)
	assert_eq(_voices_of(audio, cannon_take), owned, "six shots still hold that one voice")
	var blast_take := StringName(AudioScript.CUE_POOLS[BLAST_POOL][&"takes"][0])
	audio.call(&"play_pool", BLAST_POOL, 0)
	var blast_voices := _voices_of(audio, blast_take)
	assert_eq(blast_voices.size(), 1, "another cue has a voice of its own")
	assert_false(blast_voices.has(owned[0]), "which is not the cannon's")
	assert_eq(_voices_of(audio, cannon_take), owned, "so the burst cut nothing but itself")


## --- M2: the two world beds (AUDIO_SPEC section 4.2) ----------------------


func test_the_two_world_beds_sound_at_once() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_true(
		String(audio.call(&"cue_path", ProjectileScript.SHIELD_LOOP_CUE)) != "",
		"S6's bed resolves"
	)
	audio.call(&"play_loop", ProjectileScript.SHIELD_LOOP_CUE)
	audio.call(&"play_loop", MiningScript.BEAM_LOOP_CUE)
	assert_eq(
		_sounding(audio),
		[ProjectileScript.SHIELD_LOOP_CUE, MiningScript.BEAM_LOOP_CUE],
		"a miner who takes a shielded hit hears both beds (one voice used to silence one)"
	)
	assert_eq(
		StringName(audio.call(&"current_loop")),
		ProjectileScript.SHIELD_LOOP_CUE,
		"the impact read keeps the foreground"
	)
	## The shield's own release path: only the bed the shield started goes out.
	ProjectileScript.release_shield(_root)
	assert_eq(
		_sounding(audio),
		[MiningScript.BEAM_LOOP_CUE],
		"the shield's release leaves the shaft's bed sounding"
	)
	assert_eq(
		StringName(audio.call(&"current_loop")),
		MiningScript.BEAM_LOOP_CUE,
		"and the shaft takes the foreground"
	)
	## Every voice busy: a peer's bed is dropped rather than thrashing a voice.
	audio.call(&"play_loop", ENGINE_BED)
	audio.call(&"play_loop", BOILER_BED)
	assert_eq(_sounding(audio).size(), 3, "three beds hold the three voices")
	audio.call(&"play_loop", SPARE_BED)
	assert_false(_sounding(audio).has(SPARE_BED), "a peer's bed is dropped, not queued")


## --- M3: the rocket a beam shoots down ------------------------------------


func test_a_rocket_shot_down_by_a_beam_takes_the_blast() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rig := _rig([&"laser"])
	var guns: Node2D = rig[&"guns"]
	var rocket := _staged_rocket(guns)
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.016)
	guns.call(&"set_firing", false)
	assert_true(bool(rocket.get(&"_spent")), "the beam kills the rocket on its segment")
	assert_true(
		String(audio.call(&"last_sfx")).begins_with("sfx_weapon_explosion"),
		"and the kill takes the blast cue the projectile route plays"
	)
	var bursts := _fx_nodes_from(EXPLOSION_SHEET)
	assert_eq(bursts.size(), 1, "with the explosion sheet that route draws")
	if bursts.is_empty():
		return
	var burst := bursts[0]
	_assert_alpha(burst)
	var frames := (burst as AnimatedSprite2D).sprite_frames
	assert_true(frames != null, "the burst is an animation")
	if frames != null:
		assert_eq(
			frames.get_frame_count(FxScript.ANIMATION),
			EXPLOSION_FRAMES,
			"section 1.4's five-frame sheet"
		)


## --- Fixtures -------------------------------------------------------------


## A mounted `WeaponComponent` under a stub hull: a live `PlayerState` and the fit under
## test, aimed `AIM_DISTANCE` to starboard (the rig F1's suite uses).
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


## A hull in the fixture, the shape `_beam_target`'s ray hands `_apply_beam`.
func _stub_hull(shield: float) -> StubHull:
	var hull := StubHull.new()
	hull.name = &"BeamTarget"
	hull.shield = shield
	_root.add_child(hull)
	hull.global_position = Vector2(120.0, 0.0)
	return hull


## One frame of the beam's hull branch, called where `_fire_beam` calls it: the family's
## own row and the collider the ray would return.
func _beam_frame(guns: Node2D, hull: Node2D, delta: float = BEAM_FRAME) -> void:
	guns.call(
		&"_apply_beam",
		&"laser",
		WeaponScript.row_of(&"laser"),
		hull,
		hull.global_position,
		delta
	)


## A rocket of the shooter's own making, on the beam's segment (`_rocket_on_segment`
## finds it by distance to the segment, so it must be inside `HIT_RADIUS` of the ray).
func _staged_rocket(guns: Node2D) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "BeamRocket"
	shot.call(
		&"configure",
		{&"kind": ProjectileScript.KIND_ROCKET, &"speed": 0.0, &"damage": 180.0, &"mass": 1.0}
	)
	_root.add_child(shot)
	shot.global_position = guns.global_position + Vector2(60.0, 0.0)
	return shot


## --- Readers --------------------------------------------------------------


## What the manager reports is sounding, whatever its own type is.
func _sounding(audio: Node) -> Array:
	return audio.call(&"sounding_loops") as Array


## The voice indices a pooled take currently holds.
func _voices_of(audio: Node, take: StringName) -> Array:
	var out: Array = []
	var takes: Array = audio.call(&"voice_takes") as Array
	for index in takes.size():
		if StringName(takes[index]) == take:
			out.append(index)
	return out


## Every effect node in the fixture drawing from `sheet`. The node's own name is not its
## identity: two siblings cannot share one, so a second ripple of the same hold arrives
## renamed (`@shield_ripple@2`) and a count by name would miss it.
func _fx_nodes_from(sheet: String) -> Array[Node]:
	var out: Array[Node] = []
	if _root == null or not is_instance_valid(_root):
		return out
	for child: Node in _root.get_children():
		if _sheet_of(child) == sheet:
			out.append(child)
	return out


## The master a drawn node reads from (an `AtlasTexture` over a shipped sheet); "" for a
## node that draws nothing.
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

## A clean fixture: no leftover effect nodes and no leftover shots (a shot of another
## test's would be a target on the beam's segment).
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


## Put every bed out, by name: a bed left sounding would make the next test's
## `sounding_loops()` a reading of this one's leftovers.
func _clear_loops() -> void:
	var audio := _audio()
	if audio == null or not audio.has_method(&"sounding_loops"):
		return
	for cue: Variant in _sounding(audio).duplicate():
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


func _near(measured: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(measured - expected) <= tolerance
