extends Node2D
## F2 probe (weapon FX & audio wave): what a landed hit draws and sounds like, measured
## rather than eyeballed - one line per event, each with the cue that went out, the
## shipped sheet it drew from and the frame rate, blend mode and world size that sheet
## reads at.
##
## Contract: brief `.agents/gen/weapon_fx_wave_task.md` (worker F2), FX_SPEC sections
## 0/1.4/1.5/7.1/7.2/7.3, AUDIO_SPEC section 8, ASSET_WIRING_HANDOFF sections 1.1/1.2/3.
##
## Rules the probe obeys, verbatim from the brief: deterministic and headless, driven
## through the shipped seams (`configure`, the projectile's own hit doors), and a bounded
## run that quits itself.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_f2_weapon_fx.tscn --quit-after 600
## Signal: the `[F2]` lines; the last is `[F2] done`.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[F2]"
const AUDIO_SERVICE: StringName = &"AudioManager"
const HIT_POINT := Vector2(400.0, 300.0)
const SHOT_SPEED := 1000.0
const SHOT_DAMAGE := 10.0
const ROCK_UNITS := 100
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const PLAYER_HULL: StringName = &"ship_vanguard"


## A hull that answers the pinned sink with a pool a hit can empty.
class StubHull extends Node2D:
	var shield := 0.0

	func shield_up() -> bool:
		return shield > 0.0

	func take_damage(amount: float, bypass_shield: bool = false, _ctx: Dictionary = {}) -> void:
		if not bypass_shield and shield > 0.0:
			shield = maxf(shield - amount, 0.0)

	func impact_body() -> RigidBody2D:
		return null


var _stage: Node2D = null
var _audio: Node = null


func _ready() -> void:
	var packed := load(GameScene.resource_path) as PackedScene
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	_stage = Node2D.new()
	_stage.name = &"F2Stage"
	add_child(_stage)
	_audio = get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	print("%s world=%s audio=%s" % [TAG, scene != null, _audio != null])

	_event_rock()
	_event_hull()
	_event_shield()
	_event_shield_break()
	_event_railgun()
	_event_hull_death()
	_event_player_death()
	_event_detonation()
	_event_shot_down()
	_event_low_hull()
	_cues()
	print("%s done" % TAG)
	get_tree().quit(0)


## A weapon hit on a rock: AUDIO_SPEC S4's own rock row.
func _event_rock() -> void:
	_clear()
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = "Rock"
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	_stage.add_child(rock)
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_rock", rock, HIT_POINT)
	_line(&"rock", "target=asteroid")


## A weapon hit on an unshielded hull: S4's five-take hull foley.
func _event_hull() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	_stage.add_child(hull)
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_line(&"hull", "target=hull shield=down")


## A hit a shield absorbs: S5's transient, S6's held bed and FX_SPEC 1.5's ring.
func _event_shield() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	hull.shield = 100.0
	_stage.add_child(hull)
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_line(&"shield", "target=hull shield=up bed=%s" % _bed())


## The hit that empties the pool: the shatter and the bed going out with it.
func _event_shield_break() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	hull.shield = 5.0
	_stage.add_child(hull)
	_shot(ProjectileScript.KIND_BOLT, 40.0).call(&"_hit_body", hull, HIT_POINT)
	_line(&"shield_break", "target=hull shield=0 bed=%s" % _bed())


## The railgun's slug (FX_SPEC 7.2's arc) against a hull, beside the bolt control.
func _event_railgun() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	_stage.add_child(hull)
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_line(&"bolt_hit", "kind=bolt control=no-arc")
	_clear_sheets()
	_shot(ProjectileScript.KIND_SLUG).call(&"_hit_body", hull, HIT_POINT)
	_line(&"railgun_hit", "kind=slug")


## An NPC hull's death: FX_SPEC 1.4's explosion, the secondary burst and the blast cue.
func _event_hull_death() -> void:
	_clear()
	var npc := NpcShipScript.new() as Node2D
	npc.name = "Npc"
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"sprite_path": NPC_SPRITE}
	)
	_stage.add_child(npc)
	npc.global_position = HIT_POINT
	npc.call(&"take_damage", 1000000.0, true)
	_line(&"npc_death", "archetype=%s at=%s" % [NPC_ARCHETYPE, HIT_POINT])


## The player hull's death, through the shipped scene and the state's own `died`.
func _event_player_death() -> void:
	_clear()
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
	var ship := PlayerShipScene.instantiate() as Node2D
	ship.name = "ProbeShip"
	_stage.add_child(ship)
	ship.global_position = HIT_POINT
	ship.call(
		&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT)
	)
	state.call(&"set_hull", 0.0)
	_line(&"player_death", "hull=0 at=%s" % HIT_POINT)


## A rocket's own detonation: the same explosion and blast as a death.
func _event_detonation() -> void:
	_clear()
	_shot(ProjectileScript.KIND_ROCKET).call(&"_detonate", HIT_POINT)
	_line(&"detonation", "kind=rocket")


## F1's open item 11: a rocket killed in flight (the shooter's shot flies on).
func _event_shot_down() -> void:
	_clear()
	var victim := _shot(ProjectileScript.KIND_ROCKET)
	var shooter := _shot(ProjectileScript.KIND_BOLT)
	shooter.call(&"_shot_down", victim, HIT_POINT)
	_line(&"shot_down", "kind=rocket victim=%s" % is_instance_valid(victim))


## FX_SPEC 7.1/7.3's low-hull damage state, on both hull kinds.
func _event_low_hull() -> void:
	_clear()
	var npc := NpcShipScript.new() as Node2D
	npc.name = "Npc"
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"sprite_path": NPC_SPRITE}
	)
	_stage.add_child(npc)
	npc.global_position = HIT_POINT
	npc.call(&"set_hull", float(npc.call(&"hull_max")) * 0.2)
	_line(&"low_hull", "hull_fraction=0.20", false)
	_report_plume(npc)


## Every wired cue and the shipped file it resolves to, read through the manager's own
## lookup (audio cannot be heard headless).
func _cues() -> void:
	if _audio == null:
		print("%s cues audio=MISSING" % TAG)
		return
	var cues: Array[StringName] = [
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_ROCK),
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_HULL),
		ProjectileScript.impact_cue_of(ProjectileScript.IMPACT_KIND_SHIELD),
		ProjectileScript.SHIELD_LOOP_CUE,
		ProjectileScript.BLAST_CUE,
	]
	var pairs: Array[String] = []
	for cue: StringName in cues:
		pairs.append("%s->%s" % [cue, _audio.call(&"cue_path", cue)])
	print("%s cues %s" % [TAG, " ".join(pairs)])


## --- Fixtures and readers -------------------------------------------------


func _shot(kind: StringName, damage: float = SHOT_DAMAGE) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.call(
		&"configure",
		{&"kind": kind, &"speed": SHOT_SPEED, &"direction": Vector2.RIGHT, &"damage": damage}
	)
	_stage.add_child(shot)
	shot.global_position = Vector2(100.0, 100.0)
	return shot


## One event's line: the cue the SFX bus was handed, the pool (or plain file) it landed
## on, and every sheet the hit left behind, measured off the nodes themselves. An event
## FX_SPEC pairs no cue with (the low-hull plume) prints `cue=none` rather than the
## previous event's leftover.
func _line(event: StringName, note: String, has_cue := true) -> void:
	var cue := &""
	var path := ""
	var pool := &""
	if has_cue and _audio != null and _audio.has_method(&"last_sfx"):
		cue = StringName(_audio.call(&"last_sfx"))
		path = String(_audio.call(&"cue_path", cue))
		pool = _pool_of(cue)
	print("%s event=%s cue=%s pool=%s path=%s %s" % [
		TAG, event, "none" if cue.is_empty() else cue, "none" if pool.is_empty() else pool, path, note
	])
	for child: Node in _stage.get_children():
		_report_sheet(child)


## The pool cue that owns a played take ("" for a plain file), so "a pooled row played"
## is measured rather than assumed.
func _pool_of(take: StringName) -> StringName:
	for cue: Variant in AudioScript.CUE_POOLS:
		var takes: Array = AudioScript.CUE_POOLS[cue].get(&"takes", [])
		if takes.has(take):
			return StringName(cue)
	return &""


func _bed() -> StringName:
	if _audio == null or not _audio.has_method(&"current_loop"):
		return &""
	return StringName(_audio.call(&"current_loop"))


func _report_sheet(node: Node) -> void:
	var visual := node as Node2D
	var texture := _texture_of(node)
	if visual == null or texture == null:
		return
	var sheet := ""
	var region := Rect2()
	var frames := 1
	var fps := 0.0
	var loop := false
	if visual is Sprite2D:
		var still := (visual as Sprite2D).texture
		if still is AtlasTexture:
			sheet = (still as AtlasTexture).atlas.resource_path
			region = (still as AtlasTexture).region
	if visual is AnimatedSprite2D:
		var animated := visual as AnimatedSprite2D
		var first := animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0) as AtlasTexture
		if first != null:
			sheet = first.atlas.resource_path
			region = first.region
		frames = animated.sprite_frames.get_frame_count(FxScript.ANIMATION)
		fps = animated.sprite_frames.get_animation_speed(FxScript.ANIMATION)
		loop = animated.sprite_frames.get_animation_loop(FxScript.ANIMATION)
	var material := visual.material as CanvasItemMaterial
	var additive := material != null and material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	## The row's own read (the first frame's region at the sheet's declared scale), not
	## the live scale: the ripple is spawned collapsed and grows (FX_SPEC section 1.5).
	## A negative scale component is reported as its magnitude - a Godot sheet never
	## reads at a negative length.
	var row := _row_of(sheet)
	var full := FxScript.scale_for(
		row.get(&"source", region.size) as Vector2, float(row.get(&"world", 0.0))
	)
	var read := region.size * full
	print(
		"%s   sheet=%s frames=%d fps=%.0f loop=%s additive=%s read=%.0fx%.0f scale=%.4f at=%s"
		% [
			TAG,
			sheet,
			frames,
			fps,
			loop,
			additive,
			absf(read.x),
			absf(read.y),
			visual.scale.x,
			visual.global_position,
		]
	)


## The FEEDBACK row drawn from a sheet path, so the probe reports the table's own read.
func _row_of(sheet: String) -> Dictionary:
	for name: Variant in ProjectileScript.FEEDBACK:
		var row: Dictionary = ProjectileScript.FEEDBACK[name]
		if String(row.get(&"texture", "")) == sheet:
			return row
	return {}


func _report_plume(hull: Node2D) -> void:
	var plume := hull.get_node_or_null(NodePath(ProjectileScript.PLUME_NODE)) as GPUParticles2D
	if plume == null:
		print("%s   plume=MISSING" % TAG)
		return
	var material := plume.material as CanvasItemMaterial
	var additive := material != null and material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	var atlas := plume.texture as AtlasTexture
	var sheet := atlas.atlas.resource_path if atlas != null and atlas.atlas != null else ""
	var process := plume.process_material as ParticleProcessMaterial
	var small := Vector2.ZERO
	var large := Vector2.ZERO
	if process != null and atlas != null:
		small = atlas.region.size * process.scale_min
		large = atlas.region.size * process.scale_max
	print(
		"%s   plume=%s sheet=%s amount=%d lifetime=%.1f emitting=%s additive=%s local=%s puff=%.0fx%.0f..%.0fx%.0f"
		% [
			TAG,
			plume.name,
			sheet,
			plume.amount,
			plume.lifetime,
			plume.emitting,
			additive,
			plume.local_coords,
			small.x,
			small.y,
			large.x,
			large.y,
		]
	)


func _texture_of(node: Node) -> Texture2D:
	var sprite := node as Sprite2D
	if sprite != null:
		return sprite.texture
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		if animated.sprite_frames.has_animation(FxScript.ANIMATION):
			return animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
	return null


func _clear_sheets() -> void:
	for child: Node in _stage.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			child.free()


func _clear() -> void:
	for shot: Node in get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		if is_instance_valid(shot):
			shot.free()
	if _audio != null and _audio.has_method(&"stop_loop"):
		_audio.call(&"stop_loop", 0.0)
	for child: Node in _stage.get_children():
		if is_instance_valid(child):
			child.free()
