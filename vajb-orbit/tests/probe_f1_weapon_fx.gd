extends Node2D
## F1 probe (weapon FX & audio wave): what a shot of each shipped family draws and
## sounds like in the real `game.tscn`, measured rather than eyeballed.
##
## Contract: brief `.agents/gen/weapon_fx_wave_task.md` (worker F1), FX_SPEC sections
## 0/1.1/1.2/1.6/7.3, AUDIO_SPEC section 8, ASSET_WIRING_HANDOFF sections 1.1/1.2.
##
## Rules the probe obeys, verbatim from the brief: deterministic and headless
## (`--headless`), the component's own published seams (`set_firing`, `set_aim_point`)
## so no `Input` action and no cursor is read, and a bounded run that quits itself.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_f1_weapon_fx.tscn --quit-after 600
## Signal: the `[F1]` lines; the last is `[F1] done`.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const WeaponScript := preload("res://game/weapons.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[F1]"
const AIM_DISTANCE := 300.0
const AUDIO_SERVICE: StringName = &"AudioManager"

var _scene: Node2D = null
var _guns: Node2D = null
var _audio: Node = null
var _families: Array[StringName] = [
	&"laser", &"plasma", &"cannon", &"railgun", &"rocket", &"mine"
]


func _ready() -> void:
	var packed := load(GameScene.resource_path) as PackedScene
	_scene = packed.instantiate() as Node2D
	add_child(_scene)
	var ship := _scene.get_node_or_null(NodePath(&"PlayerShip")) as Node2D
	_guns = ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	_audio = get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	print("%s ship=%s weapons=%s audio=%s" % [TAG, ship != null, _guns != null, _audio != null])
	if _guns == null:
		print("%s done (no WeaponComponent - nothing to measure)" % TAG)
		get_tree().quit(0)
		return
	_aim()
	for weapon_id: StringName in _families:
		_fire(weapon_id)
	print("%s done" % TAG)
	get_tree().quit(0)


## The previous family's shot cadence gates the next one (the cannon's 0.6 s burst
## cycle and the rocket's 1.2 s interval are the longest of them), so the probe releases the trigger and steps a full
## interval before the next family: without this the second and later families measure
## the first family's timer, not their own wiring.
func _settle_cadence() -> void:
	_guns.call(&"set_firing", false)
	for _frame in 120:
		_guns.call(&"tick", 0.016)


func _aim() -> void:
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(AIM_DISTANCE, 0.0))


func _fire(weapon_id: StringName) -> void:
	_clear_shots()
	_settle_cadence()
	var fit: Array[StringName] = [_family_module(weapon_id)]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_aim()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	var audio_cue := &""
	if _audio != null and _audio.has_method(&"last_sfx"):
		audio_cue = StringName(_audio.call(&"last_sfx"))
	print(
		"%s family=%s fitted=%s instant=%s shots=%d flash=%s cue=%s"
		% [
			TAG,
			weapon_id,
			_guns.call(&"selected_weapon"),
			WeaponScript.row_of(weapon_id).get(&"instant", false),
			_shots().size(),
			_flash_report(),
			audio_cue,
		]
	)
	for shot: Node2D in _shots():
		_report_shot(shot)
	_report_beam()
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", 0.016)


## The family table is keyed by weapon id, the fit by module id; `set_fitted`
## normalizes one to the other, so the module is read back off the row.
func _family_module(weapon_id: StringName) -> StringName:
	var row := WeaponScript.row_of(weapon_id)
	return StringName(row.get(&"module", weapon_id))


func _shots() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		var shot := node as Node2D
		if shot != null and is_instance_valid(shot) and not shot.is_queued_for_deletion():
			out.append(shot)
	return out


func _clear_shots() -> void:
	for shot: Node2D in _shots():
		shot.free()


func _report_shot(shot: Node2D) -> void:
	var visual := shot.get_node_or_null(NodePath(ProjectileScript.VISUAL_NODE)) as Node2D
	var sheet := ""
	var region := Rect2()
	var additive := false
	var world := Vector2.ZERO
	var animated := visual is AnimatedSprite2D
	if visual is Sprite2D:
		var texture := (visual as Sprite2D).texture
		if texture is AtlasTexture:
			sheet = (texture as AtlasTexture).atlas.resource_path
			region = (texture as AtlasTexture).region
		elif texture != null:
			sheet = texture.resource_path
	if visual is AnimatedSprite2D:
		var frames := (visual as AnimatedSprite2D).sprite_frames
		var first := frames.get_frame_texture(FxScript.ANIMATION, 0) as AtlasTexture
		if first != null:
			sheet = first.atlas.resource_path
			region = first.region
	var material: CanvasItemMaterial = null
	if visual != null:
		material = visual.material as CanvasItemMaterial
	if material != null:
		additive = material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	if visual != null:
		world = visual.scale * region.size
	print(
		"%s   shot kind=%s visual=%s animated=%s sheet=%s region=%s world=%.0fx%.0f additive=%s rot=%.3f"
		% [
			TAG,
			shot.get(&"kind"),
			visual.get_class() if visual != null else "MISSING",
			animated,
			sheet,
			region,
			world.x,
			world.y,
			additive,
			visual.rotation if visual != null else 0.0,
		]
	)


## Every flash the muzzle is holding (a shot's flash lives 0.2 s of real time, and the
## probe runs no frames, so earlier families' flashes are still up).
func _flash_report() -> String:
	var flashes: Array[AnimatedSprite2D] = []
	for child: Node in _guns.get_children():
		var flash := child as AnimatedSprite2D
		if flash != null:
			flashes.append(flash)
	if flashes.is_empty():
		return "none"
	var newest := flashes[flashes.size() - 1]
	var frames := newest.sprite_frames
	var material := newest.material as CanvasItemMaterial
	var additive := material != null and material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	return (
		"x%d %dframes@%.0ffps loop=%s additive=%s centered=%s"
		% [
			flashes.size(),
			frames.get_frame_count(FxScript.ANIMATION),
			frames.get_animation_speed(FxScript.ANIMATION),
			frames.get_animation_loop(FxScript.ANIMATION),
			additive,
			newest.centered,
		]
	)


func _report_beam() -> void:
	for name: StringName in WeaponScript.BEAM_NAMES:
		var line := _guns.get_node_or_null(NodePath(name)) as Line2D
		if line == null:
			continue
		var reach := 0.0
		if line.points.size() >= 2:
			reach = line.points[1].length()
		print(
			"%s   beam %s visible=%s width=%.1f reach=%.1f" % [TAG, name, line.visible, line.width, reach]
		)
