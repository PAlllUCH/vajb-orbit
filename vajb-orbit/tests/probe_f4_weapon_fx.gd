extends Node2D
## F4 probe (weapon FX & audio wave, the one-pass fixer, 2026-09-21).
##
## It measures the four findings the review wave raised (`.agents/gen/weapon_fx_f3_report.md`)
## on the shipped code, with the reviewer's own probe re-run beside it for the lines that
## probe already prints. F3's probe measures the wiring through an audio stub; this one
## measures what the *manager itself* reports it is doing (which beds are sounding, which
## voice holds which take), because the two fixes M1 and M2 are about the manager's own
## bookkeeping and F3's stub cannot see them.
##
## What each line proves:
##   BED / LOOPS   - the beds that are sounding at once, and which one is in the foreground;
##   PEAK / VOICES - how many voices one cue's burst occupies, and which take each holds;
##   BEAM HIT      - the cue, the ring and the shield bed a beam's hull hit produces, and
##                   that the read is rate-gated per contact (one per BEAM_HIT_INTERVAL);
##   BEAM BED      - the bed a held beam rides and its release;
##   SHOTDOWN      - the cue and the sheet a beam-killed rocket takes;
##   CONTROL       - two falsification checks (an invented bed resolves nowhere; a peer bed
##                   is dropped when every voice is busy).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_f4_weapon_fx.tscn --quit-after 900
## Signal: the `[F4]` lines; the last is `[F4] done`.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const WeaponScript := preload("res://game/weapons.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")

const TAG := "[F4]"
const AUDIO_SERVICE: StringName = &"AudioManager"
const AIM_DISTANCE := 300.0
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const RIPPLE_SHEET := "res://assets/fx/fx_shield_ripple.png"
const EXPLOSION_SHEET := "res://assets/fx/fx_explosion.png"
const CANNON_POOL: StringName = &"sfx_weapon_cannon"
const BLAST_POOL: StringName = &"sfx_weapon_explosion"
const LASER_POOL: StringName = &"sfx_weapon_laser"
const BELOW_BED: StringName = &"sfx_ship_engine"
const SPARE_BED: StringName = &"sfx_ship_engine_02_loop"
const INVENTED_BED: StringName = &"sfx_weapon_beam_loop"
const HOLD_FRAMES := 10
const FRAME := 0.05


## A service with the pre-fix surface: the four loop calls and no cue-scoped stop. It is
## the shape F3's own probe installs, so the fallback the wiring keeps for such a service
## can be measured rather than assumed.
class LegacyAudio extends Node:
	var calls: Array[Dictionary] = []
	var loop_cue: StringName = &""

	func play_sfx(cue: StringName) -> void:
		calls.append({&"method": &"play_sfx", &"cue": cue})

	func play_pool(cue: StringName, take: int = -1) -> Dictionary:
		calls.append({&"method": &"play_pool", &"cue": cue, &"take": take})
		return {&"cue": cue, &"take_index": take}

	func play_loop(cue: StringName, _fade: float = 0.15) -> StringName:
		calls.append({&"method": &"play_loop", &"cue": cue})
		loop_cue = cue
		return cue

	func stop_loop(_fade: float = 0.15) -> void:
		calls.append({&"method": &"stop_loop", &"cue": loop_cue})
		loop_cue = &""

	func current_loop() -> StringName:
		return loop_cue

	func last_sfx() -> StringName:
		return StringName(calls[calls.size() - 1][&"cue"]) if not calls.is_empty() else &""


var _game: Node2D = null
var _guns: Node2D = null
var _stage: Node2D = null
var _audio: Node = null
var _failures: Array[String] = []


func _ready() -> void:
	var packed := load(GameScene.resource_path) as PackedScene
	_game = packed.instantiate() as Node2D
	add_child(_game)
	_stage = Node2D.new()
	_stage.name = &"F4Stage"
	add_child(_stage)
	var ship := _game.get_node_or_null(NodePath(&"PlayerShip")) as Node2D
	if ship != null:
		_guns = ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	await get_tree().process_frame
	_audio = get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	print(
		"%s boot game=%s guns=%s audio=%s launched_fit=%s"
		% [
			TAG,
			_game != null,
			_guns != null,
			_audio != null,
			_guns.call(&"fitted") if _guns != null else "-",
		]
	)
	if _audio == null or _guns == null:
		_check("boot", false, "the game scene, its WeaponComponent and the manager are live")
		get_tree().quit(1)
		return
	_bed_events()
	_voice_events()
	await _beam_events()
	await _shotdown_event()
	_controls()
	_legacy_surface()
	print("%s done failures=%d" % [TAG, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


## --- The pre-fix service surface -------------------------------------------


## F3's probe installs its own audio stub, which has the four loop calls and no
## cue-scoped stop. The wiring keeps a guarded fallback for exactly that surface, and this
## is the only place it can be measured: the stub records what it is handed. The fallback
## can only reach the bed when that bed is the one a pre-fix service would call current, so
## the beam is aimed where it touches nothing (an impact hum in front of it is the case
## that needs `stop_bed`, measured above).
func _legacy_surface() -> void:
	var root := get_tree().root
	var stub := LegacyAudio.new()
	stub.name = AUDIO_SERVICE
	if _audio != null and _audio.get_parent() == root:
		root.remove_child(_audio)
	root.add_child(stub)
	_guns.call(&"set_aim_point", _guns.global_position - Vector2(0.0, AIM_DISTANCE))
	## A release frame first, so the hold below is the component's own trigger edge (the
	## shot-down pass above left the trigger down).
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", FRAME)
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", FRAME)
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", FRAME)
	var asked := false
	var stopped := false
	for call: Dictionary in stub.calls:
		if StringName(call[&"method"]) == &"play_loop" and StringName(call[&"cue"]) == WeaponScript.BEAM_BED_CUE:
			asked = true
		if StringName(call[&"method"]) == &"stop_loop" and StringName(call[&"cue"]) == WeaponScript.BEAM_BED_CUE:
			stopped = true
	print(
		"%s LOCAL legacy_surface is_stub=%s asked_bed=%s stopped_bed=%s calls=%s"
		% [TAG, _audio.get_parent() != root, asked, stopped, stub.calls]
	)
	_check("legacy_bed_ask", asked, "a service without `stop_bed` still gets the bed asked for")
	_check("legacy_bed_stop", stopped, "and the guarded fallback still puts it out")


## --- M2: the beds ----------------------------------------------------------


## The reported case: a miner who takes a shielded hit. Both beds are asked for, one after
## the other, exactly as `mining_laser._draw_beam` and `projectile.hold_shield` do it.
func _bed_events() -> void:
	stop_beds()
	_audio.call(&"play_loop", ProjectileScript.SHIELD_LOOP_CUE)
	print(
		"%s LOCAL bed ask=shield sounding=%s current=%s"
		% [TAG, _sounding(), _audio.call(&"current_loop")]
	)
	_audio.call(&"play_loop", &"sfx_mining_beam")
	print(
		"%s LOCAL bed ask=shaft sounding=%s current=%s"
		% [TAG, _sounding(), _audio.call(&"current_loop")]
	)
	_check("beds", _sounding().size() == 2, "a shield hit during a shaft hold leaves both beds sounding")
	ProjectileScript.release_shield(self)
	print(
		"%s LOCAL bed release=shield sounding=%s current=%s"
		% [TAG, _sounding(), _audio.call(&"current_loop")]
	)
	_check(
		"bed_release",
		_sounding() == [&"sfx_mining_beam"],
		"the shield's own release leaves the shaft bed sounding"
	)
	_audio.call(&"stop_loop")
	print("%s LOCAL bed stop=current sounding=%s" % [TAG, _sounding()])
	_check("bed_stop", _sounding().is_empty(), "the current bed goes out on its own release")
	stop_beds()


## --- M1: the one-shot voices -----------------------------------------------


## The reported case: a cannon burst whose cue (3.460 s) outlives its cadence (0.600 s).
## Six shots are asked for; the pool reports which take each of its four voices holds.
func _voice_events() -> void:
	if not _audio.has_method(&"voice_takes"):
		_check("voices_api", false, "the manager reports its one-shot voices")
		return
	_audio.call(&"play_pool", CANNON_POOL, 0)
	for _shot in 5:
		_audio.call(&"play_pool", CANNON_POOL, 0)
	var after_burst: Array = _audio.call(&"voice_takes")
	print("%s LOCAL burst=6 shots=%s voices=%s" % [TAG, CANNON_POOL, after_burst])
	var cannon_voices := 0
	for take: Variant in after_burst:
		if String(take).begins_with("sfx_weapon_cannon"):
			cannon_voices += 1
	_check("burst", cannon_voices == 1, "a six-shot burst holds one voice, not the whole pool")
	_audio.call(&"play_pool", BLAST_POOL, 0)
	var after_blast: Array = _audio.call(&"voice_takes")
	print("%s LOCAL burst+blast voices=%s" % [TAG, after_blast])
	var kept := 0
	for take: Variant in after_blast:
		if String(take).begins_with("sfx_weapon_cannon"):
			kept += 1
	_check("blast", kept == 1, "another cue's voice does not displace the burst's own")


## --- H1: the beam's hit read and its bed -----------------------------------


## A beam held on a real hull for half a second, measured on the manager: the cue, the ring
## and the bed, plus how many reads the contact earns. The hull is a shipping NPC, added a
## physics frame before the beam fires (`_beam_target`'s ray reads the physics space).
func _beam_events() -> void:
	stop_beds()
	var npc := NpcShipScript.new() as Node2D
	npc.name = "BeamNpc"
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"sprite_path": NPC_SPRITE}
	)
	_stage.add_child(npc)
	npc.global_position = _guns.global_position + Vector2(120.0, 0.0)
	await get_tree().physics_frame
	var hull_before: float = float(npc.get(&"_hull"))
	var shield_before: float = float(npc.get(&"_shield"))
	var fit: Array[StringName] = [&"w_laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(120.0, 0.0))
	_clear_fx()
	_guns.call(&"set_firing", true)
	for _frame in HOLD_FRAMES:
		_guns.call(&"tick", FRAME)
	var reads := _fx_from(RIPPLE_SHEET).size()
	print(
		(
			"%s LOCAL beam_hold seconds=%.2f cue=%s bed=%s reads=%d rings=%s"
			+ " hull=%.1f->%.1f shield=%.1f->%.1f"
		)
		% [
			TAG,
			HOLD_FRAMES * FRAME,
			_audio.call(&"last_sfx"),
			_sounding(),
			reads,
			_fx_names(RIPPLE_SHEET),
			hull_before,
			float(npc.get(&"_hull")),
			shield_before,
			float(npc.get(&"_shield")),
		]
	)
	_check("beam_bed", _sounding().has(WeaponScript.BEAM_BED_CUE), "a held beam rides its own bed")
	_check("beam_reads", reads == 2, "half a second of contact earns two reads, not ten")
	_check(
		"beam_cue",
		String(_audio.call(&"last_sfx")).begins_with("sfx_impact_shield_hit"),
		"a beam into a shield reads as the shield"
	)
	_check(
		"beam_shield",
		float(npc.get(&"_shield")) < shield_before,
		"and the frame's damage still lands (1.5 per 0.05 s at 30 dps)"
	)
	_clear_fx()
	# A second hold on the same hull: the contact is cleared by the release, so it reads
	# from its own first frame again rather than waiting out the old clock.
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", FRAME)
	print("%s LOCAL beam_release bed=%s" % [TAG, _sounding()])
	_check(
		"beam_release",
		not _sounding().has(WeaponScript.BEAM_BED_CUE),
		"releasing the trigger puts the beam's own bed out, not the hum it does not own"
	)
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", FRAME)
	print(
		"%s LOCAL beam_rehold reads=%d bed=%s"
		% [TAG, _fx_from(RIPPLE_SHEET).size(), _sounding()]
	)
	_check("beam_rehold", _fx_from(RIPPLE_SHEET).size() == 1, "a new hold reads on its first frame")
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", FRAME)
	stop_beds()


## --- M3: the rocket a beam shoots down -------------------------------------


## A rocket on the beam's own segment: the kill must read like the projectile route's.
func _shotdown_event() -> void:
	_clear_fx()
	_sweep_shots()
	var rocket := ProjectileScript.new() as Node2D
	rocket.name = "BeamRocket"
	rocket.call(
		&"configure",
		{&"kind": ProjectileScript.KIND_ROCKET, &"speed": 0.0, &"damage": 180.0, &"mass": 1.0}
	)
	_stage.add_child(rocket)
	rocket.global_position = _guns.global_position + Vector2(60.0, 0.0)
	var calls_before := String(_audio.call(&"last_sfx"))
	var fit: Array[StringName] = [&"w_laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(AIM_DISTANCE, 0.0))
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)
	var spent := bool(rocket.get(&"_spent")) if is_instance_valid(rocket) else false
	print(
		"%s LOCAL shotdown rocket_spent=%s before=%s cue=%s sheets=%s"
		% [TAG, spent, calls_before, _audio.call(&"last_sfx"), _fx_names(EXPLOSION_SHEET)]
	)
	_check("shotdown", spent, "the beam kills a rocket on its segment")
	_check(
		"shotdown_cue",
		String(_audio.call(&"last_sfx")).begins_with("sfx_weapon_explosion"),
		"and the kill takes the blast cue the projectile route plays"
	)
	_check(
		"shotdown_sheet",
		not _fx_from(EXPLOSION_SHEET).is_empty(),
		"with the explosion sheet that route draws"
	)
	_sweep_shots()


## --- Controls: the checks can fail -----------------------------------------


func _controls() -> void:
	stop_beds()
	print(
		"%s CONTROL invented_bed_path=%s real_bed_path=%s"
		% [
			TAG,
			_audio.call(&"cue_path", INVENTED_BED),
			_audio.call(&"cue_path", WeaponScript.BEAM_BED_CUE),
		]
	)
	_audio.call(&"play_loop", INVENTED_BED)
	_check("invented_bed", _sounding().is_empty(), "a bed whose file does not exist sounds nothing")
	_audio.call(&"play_loop", ProjectileScript.SHIELD_LOOP_CUE)
	_audio.call(&"play_loop", &"sfx_mining_beam")
	_audio.call(&"play_loop", BELOW_BED)
	var before_peer := _sounding()
	_audio.call(&"play_loop", SPARE_BED)
	var after_peer := _sounding()
	print(
		"%s CONTROL voices_busy=%d before_peer_ask=%s after_peer_ask=%s"
		% [TAG, before_peer.size(), before_peer, after_peer]
	)
	_check("peer_dropped", not after_peer.has(SPARE_BED), "a peer bed is dropped, not queued")
	stop_beds()
	_check("beds_clear", _sounding().is_empty(), "the probe leaves no bed sounding")


## --- Plumb -----------------------------------------------------------------


func _check(label: String, ok: bool, note: String) -> void:
	print("%s CHECK %s=%s %s" % [TAG, label, ok, note])
	if not ok:
		_failures.append(label)


func _sounding() -> Array:
	return _audio.call(&"sounding_loops") as Array


func stop_beds() -> void:
	if _audio == null or not _audio.has_method(&"sounding_loops"):
		return
	for cue: Variant in _sounding().duplicate():
		_audio.call(&"stop_loop", 0.0, StringName(cue))


## The effect nodes drawing from `sheet` under the stage. The node's name is not its
## identity: siblings cannot share one, so a second ring of the same hold is renamed
## (`@shield_ripple@2`) and a count by name would miss it.
func _fx_from(sheet: String) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in _fx_nodes(_stage):
		var texture := _texture_of(node)
		if texture is AtlasTexture:
			var atlas := texture as AtlasTexture
			if atlas.atlas != null and atlas.atlas.resource_path == sheet:
				out.append(node)
	return out


func _fx_names(sheet: String) -> String:
	var names := PackedStringArray()
	for node: Node in _fx_from(sheet):
		names.append("%s@%s" % [node.name, _is_additive(node)])
	return ",".join(names) if not names.is_empty() else "-"


func _fx_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		if child.is_in_group(ProjectileScript.PROJECTILE_GROUP):
			continue
		if child is AnimatedSprite2D or child is Sprite2D or child is GPUParticles2D:
			out.append(child)
		out.append_array(_fx_nodes(child))
	return out


func _texture_of(node: Node) -> Texture2D:
	var sprite := node as Sprite2D
	if sprite != null:
		return sprite.texture
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		if animated.sprite_frames.has_animation(&"default"):
			return animated.sprite_frames.get_frame_texture(&"default", 0)
	return null


func _is_additive(node: Node) -> bool:
	var item := node as CanvasItem
	if item == null:
		return false
	var material := item.material
	if material is CanvasItemMaterial:
		return (material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	return false


func _clear_fx() -> void:
	for child: Node in _stage.get_children():
		if child.is_in_group(ProjectileScript.PROJECTILE_GROUP):
			continue
		if child is AnimatedSprite2D or child is Sprite2D or child is GPUParticles2D:
			child.free()


func _sweep_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		if is_instance_valid(shot):
			shot.free()
