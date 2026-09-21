@tool
extends McpTestSuite
## Suite weapon_fx_f2: the hit's other half of the weapon FX & audio wave (brief
## `.agents/gen/weapon_fx_wave_task.md`, worker F2) - the impact cue per target kind,
## the shield's ring, break and held bed, the railgun's arc, a hull's death blast and
## the low-hull plume. Every sheet is spawned through F1's `game/fx.gd` (read-only) and
## every cue goes through `AudioManager`'s pool route.
##
## Like F1's suite this is synchronous: the gate's runner calls a test method and never
## awaits a frame (`headless_runner.gd`), so nothing asserts on a timer, a tween step or
## a physics frame. Audio cannot be heard headless, so a cue that went out is read from
## `AudioManager.last_sfx()` - or `current_loop()` for the shield's held bed - and every
## `res://assets/` path is resolved before the node that reads it is asserted on.
##
## Contract: FX_SPEC sections 1.4 (the five-frame explosion at 15 FPS), 1.5 (the ripple,
## 0 -> 1.5x over 0.3 s), 7.1/7.2/7.3 (the shield shatter, the arc, the plume and the
## one-shot lifetime); AUDIO_SPEC section 8's cue table and section 4.1's variant rules;
## ASSET_WIRING_HANDOFF.md sections 1.1/1.2 (the cue table and the variant pools) and 3
## (consumer rules). The 2026-09-21 re-cut put every effect on its own per-frame RGBA
## files and gave each frame its own alpha, so the rows name `fx_<effect>_fN.png` and
## every sheet is blended with that alpha (`.agents/gen/slice2_5_s3_report.md` section 3).

const ProjectileScript := preload("res://game/projectile.gd")
const FxScript := preload("res://game/fx.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const HULL_POOL: StringName = &"sfx_impact_hull"
const ROCK_POOL: StringName = &"sfx_impact_rock"
const SHIELD_POOL: StringName = &"sfx_impact_shield_hit"
const BLAST_POOL: StringName = &"sfx_weapon_explosion"

const EXPLOSION_SHEET := "res://assets/fx/fx_explosion_f1.png"
const SECONDARY_SHEET := "res://assets/fx/fx_secondary_explosion_f1.png"
const ARC_SHEET := "res://assets/fx/fx_arc_spark_f1.png"
const RIPPLE_SHEET := "res://assets/fx/fx_shield_ripple_f1.png"
const BREAK_SHEET := "res://assets/fx/fx_shield_break_f1.png"
const PLUME_SHEET := "res://assets/fx/fx_smoke_plume_f1.png"

const EXPLOSION_FRAMES := 5
const ARC_FRAMES := 4
const EXPLOSION_FPS := 15.0
const SHOT_SPEED := 1000.0
const SHOT_DAMAGE := 10.0
const HIT_POINT := Vector2(120.0, 80.0)
const ROCK_UNITS := 100
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const PLAYER_HULL: StringName = &"ship_vanguard"
const ADD := CanvasItemMaterial.BLEND_MODE_ADD
const MIX := CanvasItemMaterial.BLEND_MODE_MIX
const TOLERANCE := 0.001


## A target that answers the pinned sink the way a hull does, with a pool a hit can
## empty. `hull_taken` counts only what reached the hull, so a shield that absorbed the
## hit leaves it at zero - which is also the measurement that the cue changed nothing
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

	func impact_body() -> RigidBody2D:
		return null


var _root: Node2D = null


func suite_name() -> String:
	return "weapon_fx_f2"


func suite_setup(_ctx: Dictionary) -> void:
	_root = Node2D.new()
	_root.name = &"F2Fixture"
	_fixture_host().add_child(_root)


func suite_teardown() -> void:
	_clear_world()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func setup() -> void:
	_clear_world()


func teardown() -> void:
	_clear_world()


## --- The impact cue per target kind (AUDIO_SPEC S4/S5) --------------------


func test_the_impact_cue_table_is_the_handoffs_rows() -> void:
	assert_eq(
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_ROCK),
		&"sfx_impact_rock",
		"S4's asteroid impact"
	)
	assert_eq(
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_HULL),
		HULL_POOL,
		"S4's hull impact, the five-take foley pool"
	)
	assert_eq(
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_SHIELD),
		SHIELD_POOL,
		"S5's shield hit, whose cue resolves to take 01"
	)
	assert_eq(ProjectileScript.SHIELD_LOOP_CUE, &"sfx_impact_shield_loop", "S6's shield-up bed")
	assert_eq(ProjectileScript.BLAST_CUE, BLAST_POOL, "S3's warhead bang fills the blasts")


func test_a_hit_on_a_rock_plays_the_rock_cue() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rock := _rock()
	var shot := _shot(ProjectileScript.KIND_BOLT)
	shot.call(&"_hit_rock", rock, HIT_POINT)
	## The cue is S4's rock cue and since 2026-09-21 it resolves through its own pool row
	## (the rock-cleave wave's L53 fix: the four takes that sat on disk with no row), so
	## what comes back is a take of that row rather than the bare cue name.
	assert_true(
		AudioScript.CUE_POOLS[ROCK_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"a weapon hit on a rock is its own sound, one of S4's four rock takes (played %s)"
		% StringName(audio.call(&"last_sfx"))
	)
	assert_true(_sheet_up(ARC_SHEET) == null, "and a bolt arcs nowhere")


func test_a_hit_on_an_unshielded_hull_plays_the_hull_pool() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var hull := _stub()
	var shot := _shot(ProjectileScript.KIND_BOLT)
	shot.call(&"_hit_body", hull, HIT_POINT)
	assert_true(
		AudioScript.CUE_POOLS[HULL_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"a hull hit takes one of S4's five takes (played %s)"
		% StringName(audio.call(&"last_sfx"))
	)
	assert_true(
		_near(hull.hull_taken, SHOT_DAMAGE),
		"the wiring drew a cue and moved no damage (%.3f)" % hull.hull_taken
	)
	assert_true(_sheet_up(RIPPLE_SHEET) == null, "an unshielded hit draws no shield ring")


## --- The shield: the ring, the bed and the break (FX_SPEC 1.5/7.1) --------


func test_a_shielded_hit_plays_the_shield_pool_and_holds_the_bed() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var hull := _stub(100.0)
	var shot := _shot(ProjectileScript.KIND_BOLT)
	shot.call(&"_hit_body", hull, HIT_POINT)
	assert_true(
		AudioScript.CUE_POOLS[SHIELD_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"an absorbed hit takes one of S5's nine takes (played %s)"
		% StringName(audio.call(&"last_sfx"))
	)
	assert_true(_near(hull.hull_taken, 0.0), "the shield took it with no carry-over")
	assert_eq(
		StringName(audio.call(&"current_loop")),
		ProjectileScript.SHIELD_LOOP_CUE,
		"S6's bed holds while the shield does"
	)


func test_the_shield_ring_draws_at_the_hit_and_starts_collapsed() -> void:
	var hull := _stub(100.0)
	var shot := _shot(ProjectileScript.KIND_BOLT)
	shot.call(&"_hit_body", hull, HIT_POINT)
	var ring := _sheet_up(RIPPLE_SHEET)
	assert_true(ring != null, "FX_SPEC 1.5's ripple is drawn on the shielded hit")
	if ring == null:
		return
	_assert_alpha(ring)
	var atlas := _sheet_texture(ring) as AtlasTexture
	assert_true(atlas != null, "the ring is a region of the shipped master")
	if atlas != null:
		assert_eq(atlas.region, ProjectileScript.FEEDBACK[&"ripple"][&"region"], "the measured object")
	assert_true(
		_near((ring as Node2D).global_position.distance_to(HIT_POINT), 0.0),
		"the spec's ring sits at the contact point"
	)
	assert_true(
		_near((ring as Node2D).scale.x, 0.0),
		"section 1.5: it starts collapsed and grows to 1.5x (%.3f)" % (ring as Node2D).scale.x
	)


func test_the_shield_bed_goes_out_when_the_shield_breaks() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var hull := _stub(20.0)
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	assert_eq(
		StringName(audio.call(&"current_loop")),
		ProjectileScript.SHIELD_LOOP_CUE,
		"the bed is up while the shield holds"
	)
	_shot(ProjectileScript.KIND_BOLT, 30.0).call(&"_hit_body", hull, HIT_POINT)
	assert_true(_near(hull.shield, 0.0), "the second hit empties the pool")
	assert_eq(
		StringName(audio.call(&"current_loop")),
		&"",
		"and the bed goes out with it (no shield holds it any more)"
	)
	assert_true(
		_sheet_up(BREAK_SHEET) != null,
		"ASSET_EXPANSION_SPEC 7's shatter is drawn on the collapse"
	)


## --- The railgun's own signature (FX_SPEC 7.2) ----------------------------


func test_the_railguns_slug_arcs_on_its_hit() -> void:
	var hull := _stub()
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	assert_true(_sheet_up(ARC_SHEET) == null, "the light bolt hits without an arc")
	_shot(ProjectileScript.KIND_SLUG).call(&"_hit_body", hull, HIT_POINT)
	var arc := _sheet_up(ARC_SHEET)
	assert_true(arc != null, "the railgun's slug is the heavy kinetic, so its hit arcs")
	if arc == null:
		return
	_assert_alpha(arc)
	var animated := arc as AnimatedSprite2D
	assert_true(animated != null, "the arc is the four-frame sheet")
	if animated != null:
		assert_eq(
			animated.sprite_frames.get_frame_count(FxScript.ANIMATION),
			ARC_FRAMES,
			"section 7.2's four frames"
		)


## --- A hull's death (FX_SPEC 1.4 + the secondary burst) -------------------


func test_a_hull_death_draws_the_explosion_the_secondary_and_the_blast() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var npc := _npc()
	npc.call(&"take_damage", 1000000.0, true)
	var blast := _sheet_up(EXPLOSION_SHEET)
	assert_true(blast != null, "FX_SPEC 1.4's five-frame explosion is drawn on the death")
	assert_true(
		_sheet_up(SECONDARY_SHEET) != null,
		"ASSET_EXPANSION_SPEC 7's secondary burst is drawn with it"
	)
	assert_true(
		AudioScript.CUE_POOLS[BLAST_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"the blast cue is S3's own pool (played %s)" % StringName(audio.call(&"last_sfx"))
	)
	if blast == null:
		return
	_assert_alpha(blast)
	var animated := blast as AnimatedSprite2D
	assert_true(animated != null, "the explosion is the animated sheet")
	if animated == null:
		return
	assert_eq(
		animated.sprite_frames.get_frame_count(FxScript.ANIMATION),
		EXPLOSION_FRAMES,
		"the spec's five frames"
	)
	assert_true(
		_near(animated.sprite_frames.get_animation_speed(FxScript.ANIMATION), EXPLOSION_FPS),
		"at the spec's 15 FPS"
	)
	assert_false(
		animated.sprite_frames.get_animation_loop(FxScript.ANIMATION),
		"and it plays once"
	)


func test_the_players_hull_dies_with_the_same_blast() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var state := _player_state()
	var ship := _player_ship(state)
	assert_true(_sheet_up(EXPLOSION_SHEET) == null, "a whole hull has not blown up yet")
	state.call(&"set_hull", 0.0)
	assert_true(_sheet_up(EXPLOSION_SHEET) != null, "the player's death draws the explosion")
	assert_true(_sheet_up(SECONDARY_SHEET) != null, "and the secondary burst")
	assert_true(
		AudioScript.CUE_POOLS[BLAST_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"and sounds the blast cue"
	)
	assert_true(ship != null, "the fixture built the shipped scene")


func test_a_detonation_draws_the_blast() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var rocket := _shot(ProjectileScript.KIND_ROCKET)
	rocket.call(&"_detonate", HIT_POINT)
	assert_true(
		_sheet_up(EXPLOSION_SHEET) != null,
		"FX_SPEC 1.4 pairs its explosion with S3's detonations too"
	)
	assert_true(
		AudioScript.CUE_POOLS[BLAST_POOL][&"takes"].has(StringName(audio.call(&"last_sfx"))),
		"and the blast goes out (played %s)" % StringName(audio.call(&"last_sfx"))
	)


## --- The low-hull damage state (FX_SPEC 7.1/7.3) ---------------------------


func test_a_hull_below_a_quarter_trails_the_plume() -> void:
	var npc := _npc()
	var whole := float(npc.call(&"hull_max"))
	assert_true(
		npc.get_node_or_null(NodePath(ProjectileScript.PLUME_NODE)) == null,
		"a whole hull carries no plume"
	)
	npc.call(&"set_hull", whole * (ProjectileScript.LOW_HULL_FRACTION - 0.05))
	var plume := npc.get_node_or_null(NodePath(ProjectileScript.PLUME_NODE)) as GPUParticles2D
	assert_true(plume != null, "FX_SPEC 7.1: below a quarter hull the ship trails smoke")
	if plume == null:
		return
	assert_true(plume.emitting, "the emitter is live")
	_assert_alpha(plume)
	var atlas := plume.texture as AtlasTexture
	assert_true(
		atlas != null and atlas.atlas != null and atlas.atlas.resource_path == PLUME_SHEET,
		"drawn from the plume's own re-cut frame"
	)
	var row: Dictionary = ProjectileScript.FEEDBACK[&"plume"]
	var base := FxScript.scale_for(row[&"source"] as Vector2, float(row[&"world"]))
	var process := plume.process_material as ParticleProcessMaterial
	assert_true(process != null, "a particle emitter needs its process material")
	if process != null:
		assert_true(
			_near(process.scale_max, base * ProjectileScript.PLUME_SCALE_MAX, 0.0001),
			"a puff reads the row's own 40 units, not the master's 1580 pixels (%.4f)"
			% process.scale_max
		)
	npc.call(&"set_hull", whole)
	assert_true(plume.is_queued_for_deletion(), "climbing back above the line drops it")


func test_the_players_own_low_hull_trails_the_plume() -> void:
	var state := _player_state()
	_player_ship(state)
	assert_true(
		_root.get_node_or_null(NodePath(&"PlayerShip/DamagePlume")) == null,
		"a whole player hull carries no plume"
	)
	state.call(&"set_hull", float(state.get(&"hull_max")) * 0.2)
	var plume := _root.get_node_or_null(NodePath(&"PlayerShip/DamagePlume")) as GPUParticles2D
	assert_true(plume != null, "the player's own damage state is the same plume")
	if plume == null:
		return
	_assert_alpha(plume)


## --- Every wired path resolves (handoff section 4) ------------------------


func test_every_wired_sheet_region_and_cue_resolves() -> void:
	for name: Variant in ProjectileScript.FEEDBACK:
		var row: Dictionary = ProjectileScript.FEEDBACK[name]
		var paths: Variant = row.get(&"frames", [])
		assert_true(
			paths is Array and not (paths as Array).is_empty(), "%s names its frames" % name
		)
		for path: Variant in paths:
			assert_true(
				ResourceLoader.exists(String(path)),
				"%s's frame is on disk (%s)" % [name, String(path)]
			)
			var texture := load(String(path)) as Texture2D
			if texture == null:
				assert_true(false, "%s's frame loads" % name)
				continue
			var size := texture.get_size()
			if row.has(&"region"):
				var region: Rect2 = row[&"region"]
				assert_true(
					region.end.x <= size.x and region.end.y <= size.y,
					"%s's region is inside its own frame" % name
				)
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	for kind: Variant in [
		ProjectileScript.IMPACT_KIND_ROCK,
		ProjectileScript.IMPACT_KIND_HULL,
		ProjectileScript.IMPACT_KIND_SHIELD,
	]:
		var cue := ProjectileScript.impact_cue_of(StringName(kind))
		assert_true(
			String(audio.call(&"cue_path", cue)) != "",
			"the %s impact cue resolves" % kind
		)
	for cue: StringName in [ProjectileScript.SHIELD_LOOP_CUE, ProjectileScript.BLAST_CUE]:
		assert_true(
			String(audio.call(&"cue_path", cue)) != "",
			"the %s cue resolves" % cue
		)
	for pool: StringName in [HULL_POOL, SHIELD_POOL, BLAST_POOL]:
		var takes: Array = AudioScript.CUE_POOLS[pool].get(&"takes", [])
		assert_true(not takes.is_empty(), "%s has takes" % pool)
		for take: Variant in takes:
			assert_true(
				String(audio.call(&"cue_path", StringName(take))) != "",
				"take %s resolves" % take
			)


## --- Fixtures -------------------------------------------------------------


## A shot built the way `weapons.gd` builds one (configure, add, place).
func _shot(kind: StringName, damage: float = SHOT_DAMAGE) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.call(
		&"configure",
		{&"kind": kind, &"speed": SHOT_SPEED, &"direction": Vector2.RIGHT, &"damage": damage}
	)
	_root.add_child(shot)
	shot.global_position = Vector2(100.0, 100.0)
	return shot


## A Medium ore rock, the fixture `probe_c2_weapons.gd` uses.
func _rock() -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = "Rock"
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	_root.add_child(rock)
	return rock


## A hull that answers the pinned sink with an optional shield pool.
func _stub(shield := 0.0) -> StubHull:
	var hull := StubHull.new()
	hull.name = "StubHull"
	hull.shield = shield
	_root.add_child(hull)
	return hull


## The shipping NPC hull (`probe_c2_weapons.gd`'s target), so its pools and its death
## route are the game's own.
func _npc() -> Node2D:
	var npc := NpcShipScript.new() as Node2D
	npc.name = "Npc"
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"sprite_path": NPC_SPRITE}
	)
	_root.add_child(npc)
	return npc


## The shipped player hull and a full `PlayerState`, wired the way `game.gd` wires them.
func _player_ship(state: Object) -> Node2D:
	var ship := PlayerShipScene.instantiate() as Node2D
	_root.add_child(ship)
	ship.call(
		&"setup",
		ShipFitScript.resolve(PLAYER_HULL, ShipFitScript.STANDARD_FIT),
		state,
		ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT)
	)
	return ship


func _player_state() -> Object:
	var stats: Variant = ShipFitScript.resolve(PLAYER_HULL, ShipFitScript.STANDARD_FIT)
	var state: Variant = PlayerStateScript.new()
	state.set(&"hull_max", stats.hull_max)
	state.set(&"shield_max", stats.shield_max)
	state.set(&"cargo_max", stats.cargo_max)
	state.set(&"energy_max", stats.energy_max)
	state.set(&"energy_regen", stats.energy_regen)
	state.set(&"fuel_max", stats.fuel_max)
	state.set(&"shield_regen", stats.shield_regen)
	state.call(&"setup")
	return state


## --- Readers --------------------------------------------------------------


## The fixture node drawn from `sheet`, or null. A sheet is found by its own pixels, so
## a hit that draws nothing is a null rather than an absence nobody checked.
func _sheet_up(sheet: String) -> Node:
	for node: Node in _root.get_children():
		if _drawn_from(_sheet_texture(node), sheet):
			return node
	return null


## Whether a drawn texture is the named frame: the frame itself (a sequence row draws its
## frames whole) or the frame an `AtlasTexture` reads its region from (a one-frame row
## cuts its frame to the art's own ink box).
func _drawn_from(texture: Texture2D, sheet: String) -> bool:
	if texture == null:
		return false
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return atlas.atlas != null and atlas.atlas.resource_path == sheet
	return texture.resource_path == sheet


func _sheet_texture(node: Node) -> Texture2D:
	var sprite := node as Sprite2D
	if sprite != null:
		return sprite.texture
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		if animated.sprite_frames.has_animation(FxScript.ANIMATION):
			return animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
	return null


func _assert_additive(node: CanvasItem) -> void:
	var material := node.material as CanvasItemMaterial
	assert_true(material != null, "an fx sheet carries its own canvas material")
	if material == null:
		return
	assert_eq(
		material.blend_mode,
		ADD,
		"the engine-drawn beam's halo is not a sheet and keeps its own blend"
	)


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


func _clear_world() -> void:
	var tree := _tree()
	if tree != null:
		for shot: Node in tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
			if is_instance_valid(shot):
				shot.free()
	var audio := _audio()
	if audio != null and audio.has_method(&"stop_loop"):
		audio.call(&"stop_loop", 0.0)
	if _root == null or not is_instance_valid(_root):
		return
	for child: Node in _root.get_children():
		if is_instance_valid(child):
			child.free()


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
