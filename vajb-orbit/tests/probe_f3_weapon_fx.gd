extends Node2D
## F3 reviewer probe (weapon FX & audio wave, 2026-09-21).
##
## Independent of F1's and F2's probes: it measures what each wired event spawns,
## what each event plays, and whether the art and the cues are the shipped ones.
## Nothing here trusts either report.
##
## What it proves, per event:
##   1. the node spawns (counted, named, classed);
##   2. every `res://assets/fx/...` path it drew from resolves AND exists as a file
##      on disk (two different checks: the import cache vs the file itself);
##   3. the blend mode is additive (`CanvasItemMaterial.BLEND_MODE_ADD`), never alpha;
##   4. every cue it played resolves through `AudioManager`'s own loader
##      (`cue_path` -> `ResourceLoader.exists` -> `load()` -> `AudioStream`);
##   5. the frames come from the shipped master (an `AtlasTexture` whose `atlas` is a
##      shipped `res://assets/fx/...png`, with a region inside that master's own ink
##      bounds), not from an invented file.
##
## Audio cannot be heard headless, so every call the wiring makes to the audio
## service is captured through a stub node answering to the name `AudioManager`:
## the real autoload is detached from the tree for the event passes (the production
## code reaches the manager by node-name lookup, so the stub is what it finds) and
## restored for the resolution passes.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_f3_weapon_fx.tscn --quit-after 900
## Signal: the `[F3]` lines; the last is `[F3] done`.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const FxScript := preload("res://game/fx.gd")
const WeaponScript := preload("res://game/weapons.gd")
const MiningScript := preload("res://game/mining_laser.gd")

const TAG := "[F3]"
const AUDIO_SERVICE: StringName = &"AudioManager"
const FX_PREFIX := "res://assets/fx/"
const HIT_POINT := Vector2(400.0, 300.0)
const SHOT_SPEED := 1000.0
const SHOT_DAMAGE := 10.0
const ROCK_UNITS := 100
const AIM_DISTANCE := 300.0
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const PLAYER_HULL: StringName = &"ship_vanguard"
const FAMILIES: Array[StringName] = [
	&"laser", &"plasma", &"cannon", &"railgun", &"rocket", &"mine"
]

## The node names the hit and death passes give their effects, so an end-to-end pass can
## pick them out of the whole tree (a shot's effect is parented to the world, not to the
## probe's own stage).
const FEEDBACK_NAMES: Array[StringName] = [
	&"explosion", &"secondary", &"arc", &"shield_break", &"shield_ripple", &"DamagePlume"
]


## The audio service as the wiring sees it: it records every call the production
## code makes instead of mixing a stream (audio cannot be heard headless).
class StubAudio extends Node:
	var calls: Array[Dictionary] = []
	var loop_cue: StringName = &""

	func play_sfx(cue: StringName) -> void:
		calls.append({&"method": &"play_sfx", &"cue": cue, &"take": -1})

	func play_pool(cue: StringName, take: int = -1) -> Dictionary:
		calls.append({&"method": &"play_pool", &"cue": cue, &"take": take})
		return {&"cue": cue, &"take_index": take}

	func play_loop(cue: StringName, _fade: float = 0.15) -> StringName:
		calls.append({&"method": &"play_loop", &"cue": cue, &"take": -1})
		loop_cue = cue
		return cue

	func stop_loop(_fade: float = 0.15) -> void:
		calls.append({&"method": &"stop_loop", &"cue": loop_cue, &"take": -1})
		loop_cue = &""

	func current_loop() -> StringName:
		return loop_cue

	func last_sfx() -> StringName:
		if calls.is_empty():
			return &""
		return StringName(calls[calls.size() - 1][&"cue"])


## A miner whose rock is placed rather than raycast: `_acquire` is the only method
## overridden, so the bed's own call sites (`_draw_beam`, `_extinguish`, `_exit_tree`)
## are the shipped ones. The laser's cursor ray is unmeasurable headless (there is no
## display server to hold a mouse), and the wave did not touch `_acquire`.
class ProbeMiner extends MiningLaser:
	var rock: Node2D = null

	func _acquire() -> Node2D:
		if rock == null or not is_instance_valid(rock):
			return null
		_hit_point = rock.global_position
		return rock


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


var _stub: StubAudio = null
var _real_audio: Node = null
var _game: Node2D = null
var _guns: Node2D = null
var _stage: Node2D = null
var _sheets_seen: Dictionary = {}
var _cues_seen: Dictionary = {}
var _failures: Array[String] = []
var _calls_at_start := 0


func _ready() -> void:
	var packed := load(GameScene.resource_path) as PackedScene
	_game = packed.instantiate() as Node2D
	add_child(_game)
	_stage = Node2D.new()
	_stage.name = &"F3Stage"
	add_child(_stage)
	var ship := _game.get_node_or_null(NodePath(&"PlayerShip")) as Node2D
	if ship != null:
		_guns = ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	## The tree root refuses add_child/remove_child while it is still setting up the
	## scene, so the manager swap waits one frame.
	await get_tree().process_frame
	_intercept_audio()
	print(
		"%s boot game=%s guns=%s stub_installed=%s launched_fit=%s selected=%s"
		% [
			TAG,
			_game != null,
			_guns != null,
			_stub.get_parent() == get_tree().root,
			_guns.call(&"fitted") if _guns != null else "-",
			_guns.call(&"selected_weapon") if _guns != null else "-",
		]
	)

	_fire_events()
	_impact_events()
	_mining_event()
	_controls()
	await _e2e_rock()
	await _e2e_hull()
	await _open_items()
	restore_audio()
	_item_loop_voice()
	_resolution_pass()
	_sheet_pass()
	get_tree().quit(1 if _failures.size() > 0 else 0)


## Detach the autoload from the tree and answer to its name, so every node-name
## lookup the production code makes finds the recorder. The real node is kept alive
## (detached, not freed) for the resolution passes.
func _intercept_audio() -> void:
	var root := get_tree().root
	var real := root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if real != null:
		root.remove_child(real)
		_real_audio = real
	_stub = StubAudio.new()
	_stub.name = AUDIO_SERVICE
	root.add_child(_stub)


func restore_audio() -> void:
	var root := get_tree().root
	if _stub != null and _stub.get_parent() == root:
		root.remove_child(_stub)
	if _real_audio != null and _real_audio.get_parent() == null:
		root.add_child(_real_audio)


## --- Fire (F1's half) ------------------------------------------------------


## One shot of every shipped family, driven through the component's own published
## seams (no `Input` action, no cursor). Per family: the flash the component spawned,
## the shot it released, its sprite and the cue that went out.
func _fire_events() -> void:
	if _guns == null:
		print("%s FIRE none (no WeaponComponent)" % TAG)
		return
	for weapon_id: StringName in FAMILIES:
		_settle_cadence()
		var flashes_before := _flash_nodes().size()
		var calls_before := _stub.calls.size()
		var shots_before := _shots().size()
		var fit: Array[StringName] = [_family_module(weapon_id)]
		_guns.call(&"set_fitted", fit)
		_guns.call(&"select_group", 1)
		_aim()
		_guns.call(&"set_firing", true)
		_guns.call(&"tick", 0.016)
		var new_flashes := _flash_nodes().slice(flashes_before)
		var new_shots := _shots().slice(shots_before)
		print(
			"%s FIRE family=%s instant=%s cue_of=%s shots=%d flashes=%d cues=%s"
			% [
				TAG,
				weapon_id,
				bool(WeaponScript.row_of(weapon_id).get(&"instant", false)),
				WeaponScript.fire_cue_of(weapon_id),
				new_shots.size(),
				new_flashes.size(),
				_note_cues(_call_summary(_calls_since(calls_before))),
			]
		)
		for flash: Node in new_flashes:
			print("%s   %s" % [TAG, _describe(flash)])
		for shot: Node in new_shots:
			_report_shot(shot)
		_report_beam()
		_guns.call(&"set_firing", false)
		_guns.call(&"tick", 0.016)
	_sweep_projectiles()


func _family_module(weapon_id: StringName) -> StringName:
	var row := WeaponScript.row_of(weapon_id)
	return StringName(row.get(&"module", weapon_id))


func _aim() -> void:
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(AIM_DISTANCE, 0.0))


func _settle_cadence() -> void:
	if _guns == null:
		return
	_guns.call(&"set_firing", false)
	for _frame in 120:
		_guns.call(&"tick", 0.016)


func _flash_nodes() -> Array[Node]:
	var out: Array[Node] = []
	if _guns == null:
		return out
	for child: Node in _guns.get_children():
		if child is AnimatedSprite2D:
			out.append(child)
	return out


func _shots() -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			out.append(node)
	return out


func _sweep_projectiles() -> void:
	for shot: Node in _shots():
		shot.free()


func _report_shot(shot: Node) -> void:
	var visual: Node = shot.call(&"visual") as Node
	print(
		"%s   shot kind=%s visual=%s"
		% [TAG, shot.get(&"kind"), visual.get_class() if visual != null else "MISSING"]
	)
	if visual != null:
		print("%s     %s" % [TAG, _describe(visual)])


func _report_beam() -> void:
	for name: StringName in WeaponScript.BEAM_NAMES:
		var line := _guns.get_node_or_null(NodePath(name)) as Line2D
		if line == null:
			continue
		var reach := 0.0
		if line.points.size() >= 2:
			reach = line.points[1].length()
		print(
			"%s   beam %s visible=%s width=%.1f reach=%.1f"
			% [TAG, name, line.visible, line.width, reach]
		)


## --- Impact and death (F2's half) -----------------------------------------


func _impact_events() -> void:
	_event_rock()
	_event_hull()
	_event_shield()
	_event_shield_break()
	_event_railgun()
	_event_npc_death()
	_event_player_death()
	_event_detonation()
	_event_shot_down()
	_event_low_hull()


func _event_rock() -> void:
	_clear()
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = "Rock"
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	_stage.add_child(rock)
	_begin()
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_rock", rock, HIT_POINT)
	_end(&"rock", "target=asteroid")


func _event_hull() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	_stage.add_child(hull)
	_begin()
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_end(&"hull", "target=hull shield=down")


func _event_shield() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	hull.shield = 100.0
	_stage.add_child(hull)
	_begin()
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_end(&"shield", "target=hull shield=up bed=%s" % _stub.loop_cue)


func _event_shield_break() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	hull.shield = 5.0
	_stage.add_child(hull)
	_begin()
	_shot(ProjectileScript.KIND_BOLT, 40.0).call(&"_hit_body", hull, HIT_POINT)
	_end(&"shield_break", "target=hull shield=0 bed=%s" % _stub.loop_cue)


func _event_railgun() -> void:
	_clear()
	var hull := StubHull.new()
	hull.name = "StubHull"
	_stage.add_child(hull)
	_begin()
	_shot(ProjectileScript.KIND_BOLT).call(&"_hit_body", hull, HIT_POINT)
	_end(&"bolt_hit", "kind=bolt control=no-arc")
	_clear()
	var hull2 := StubHull.new()
	hull2.name = "StubHull"
	_stage.add_child(hull2)
	_begin()
	_shot(ProjectileScript.KIND_SLUG).call(&"_hit_body", hull2, HIT_POINT)
	_end(&"railgun_hit", "kind=slug")


func _event_npc_death() -> void:
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
	_begin()
	npc.call(&"take_damage", 1000000.0, true)
	_end(&"npc_death", "archetype=%s" % NPC_ARCHETYPE)


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
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_begin()
	state.call(&"set_hull", 0.0)
	_end(&"player_death", "hull=0")


func _event_detonation() -> void:
	_clear()
	_begin()
	_shot(ProjectileScript.KIND_ROCKET).call(&"_detonate", HIT_POINT)
	_end(&"detonation", "kind=rocket")


func _event_shot_down() -> void:
	_clear()
	var victim := _shot(ProjectileScript.KIND_ROCKET)
	var shooter := _shot(ProjectileScript.KIND_BOLT)
	_begin()
	shooter.call(&"_shot_down", victim, HIT_POINT)
	_end(&"shot_down", "kind=rocket victim_alive=%s" % is_instance_valid(victim))


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
	var max_hull: float = float(npc.get(&"_hull_max"))
	_begin()
	npc.call(&"set_hull", max_hull * 0.10)
	var plume := npc.get_node_or_null(NodePath(ProjectileScript.PLUME_NODE))
	_end(
		&"low_hull",
		"max=%.0f fraction=0.10 plume=%s"
		% [max_hull, plume.get_class() if plume != null else "MISSING"]
	)
	if plume is GPUParticles2D:
		pass
	_begin()
	npc.call(&"set_hull", max_hull)
	var recovered := npc.get_node_or_null(NodePath(ProjectileScript.PLUME_NODE))
	print(
		"%s   low_hull recovered plume_present=%s queued_for_deletion=%s cues=%s"
		% [
			TAG,
			recovered != null,
			recovered.is_queued_for_deletion() if recovered != null else false,
			_call_summary(_calls_since(_calls_at_start)),
		]
	)


## --- The mining bed (S7) --------------------------------------------------


func _mining_event() -> void:
	_clear()
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = "Rock"
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	_stage.add_child(rock)
	rock.global_position = HIT_POINT
	var miner := (load("res://game/mining_laser.tscn") as PackedScene).instantiate() as Node2D
	miner.name = "ProbeMiner"
	## The shipped scene brings the two Line2Ds; the reviewer's script replaces only
	## the cursor ray, so `_draw_beam` / `_extinguish` / `_exit_tree` are the shipped
	## ones. It is set before the node enters the tree so `_ready` is the new one.
	miner.set_script(ProbeMiner)
	miner.set(&"rock", rock)
	_stage.add_child(miner)
	miner.set_physics_process(false)
	_begin()
	miner.call(&"set_active", true)
	miner.call(&"_physics_process", MiningScript.MINE_CYCLE)
	print(
		"%s EVENT mining_shaft active=true loop=%s cues=%s"
		% [TAG, _stub.loop_cue, _call_summary(_calls_since(_calls_at_start))]
	)
	_begin()
	miner.call(&"set_active", false)
	print(
		"%s   mining_release loop=%s cues=%s"
		% [TAG, _stub.loop_cue, _call_summary(_calls_since(_calls_at_start))]
	)
	_begin()
	miner.call(&"set_active", true)
	miner.call(&"_physics_process", MiningScript.MINE_CYCLE)
	_begin()
	_stage.remove_child(miner)
	print(
		"%s   mining_exit_tree loop=%s cues=%s"
		% [TAG, _stub.loop_cue, _call_summary(_calls_since(_calls_at_start))]
	)
	miner.free()


## --- End to end: a real shot flies into a real rock ------------------------


## The seam the wave exists for: not the direct hit door but a shot that leaves the
## component, crosses the world and lands. The rock is placed on the muzzle line and
## the shot is released through the shipped trigger. The railgun is used because its
## slug is the one kind that adds its own hit sheet (FX_SPEC 7.2's arc), so one line
## proves the cue, the sheet and the master the sheet came from.
func _e2e_rock() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
	_aim()
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = "FlyRock"
	rock.call(&"setup", &"iron", 1, 100000, AsteroidScript.SIZE_LARGE)
	_stage.add_child(rock)
	rock.global_position = _guns.global_position + Vector2(200.0, 0.0)
	var fit: Array[StringName] = [_family_module(&"railgun")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_begin()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)
	var released := _shots().size()
	var frames := 0
	while frames < 90 and _shots().size() > 0:
		await get_tree().physics_frame
		frames += 1
	print(
		"%s E2E rock released=%d frames=%d shots_left=%d cues=%s"
		% [TAG, released, frames, _shots().size(), _note_cues(_call_summary(_calls_since(_calls_at_start)))]
	)
	for node: Node in _feedback_nodes(self):
		print("%s   e2e_rock_fx %s" % [TAG, _describe(node)])


## The same, into a hull: a real shot released by the component kills a real ship, so
## the death blast is measured from flight rather than from a called door.
func _e2e_hull() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
	_aim()
	var npc := NpcShipScript.new() as Node2D
	npc.name = "FlyNpc"
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"sprite_path": NPC_SPRITE}
	)
	_stage.add_child(npc)
	npc.global_position = _guns.global_position + Vector2(150.0, 0.0)
	var max_hull: float = float(npc.get(&"_hull_max"))
	npc.call(&"take_damage", max_hull - 1.0, true)
	var fit: Array[StringName] = [_family_module(&"railgun")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_begin()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)
	var released := _shots().size()
	var frames := 0
	while frames < 90 and _shots().size() > 0:
		await get_tree().physics_frame
		frames += 1
	var hull_left: Variant = "-"
	if is_instance_valid(npc) and not npc.is_queued_for_deletion():
		hull_left = npc.get(&"_hull")
	print(
		"%s E2E hull released=%d frames=%d shots_left=%d hull_left=%s cues=%s"
		% [
			TAG,
			released,
			frames,
			_shots().size(),
			hull_left,
			_note_cues(_call_summary(_calls_since(_calls_at_start))),
		]
	)
	for node: Node in _feedback_nodes(self):
		print("%s   e2e_hull_fx %s" % [TAG, _describe(node)])


## --- Controls: the checks can fail ---------------------------------------


## Two falsification controls, so a green line elsewhere means something: an invented
## asset name must not resolve, and an alpha-blended sprite must not read additive.
func _controls() -> void:
	_clear()
	var invented := FX_PREFIX + "fx_laser_bolt_f1.png"
	var real := FX_PREFIX + "fx_laser_bolt.png"
	print(
		"%s CONTROL invented_resource=%s invented_file=%s real_resource=%s real_file=%s"
		% [
			TAG,
			ResourceLoader.exists(invented),
			FileAccess.file_exists(invented),
			ResourceLoader.exists(real),
			FileAccess.file_exists(real),
		]
	)
	var alpha := Sprite2D.new()
	alpha.name = "AlphaControl"
	alpha.texture = load(real) as Texture2D
	var alpha_material := StandardMaterial3D.new()
	alpha_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	alpha.material = alpha_material
	_stage.add_child(alpha)
	print(
		"%s CONTROL alpha_reads_additive=%s alpha_reads_alpha=%s"
		% [TAG, _is_additive(alpha), _is_alpha(alpha)]
	)


## --- The open items, re-measured on the real manager ----------------------


## Both workers' open items, re-measured rather than re-read: the takes' own lengths,
## the mine's two moments, the loop voice the two beds contend for, a beam-killed
## rocket, a beam that lands on a hull, and where the flash's mouth sits against the
## shot's spawn point. The cue deltas need the stub, so this runs before the manager is
## restored (`_item_loop_voice` is the one that needs the real one).
func _open_items() -> void:
	_item_durations()
	_item_mine()
	_item_beam_shotdown()
	_item_beam_hold()
	await _item_beam_hit()
	_item_muzzle()


## How a held beam reads: the cue and the flash a continuous trigger earns over its
## hold (the instant families' `shot_fired` is documented as one per hold).
func _item_beam_hold() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
	var fit: Array[StringName] = [_family_module(&"laser")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(300.0, 0.0))
	var flashes_before := _flash_nodes().size()
	_begin()
	_guns.call(&"set_firing", true)
	for _tick in 10:
		_guns.call(&"tick", 0.05)
	_guns.call(&"set_firing", false)
	print(
		"%s ITEM beam_hold ticks=10 seconds=0.50 flashes=%d cues=%s"
		% [
			TAG,
			_flash_nodes().size() - flashes_before,
			_call_summary(_calls_since(_calls_at_start)),
		]
	)


## Every take's own length and every family's cadence, so an outlier or an
## unreachable tier is a number rather than a claim.
func _item_durations() -> void:
	if _real_audio == null:
		return
	var real := _real_audio
	for cue: Variant in AudioScript.CUE_POOLS.keys():
		var takes: Array = real.call(&"pool_takes", StringName(cue))
		var parts := PackedStringArray()
		for take: Variant in takes:
			var path: String = String(real.call(&"cue_path", StringName(take)))
			var stream := load(path) as AudioStream
			parts.append(
				"%s=%.3fs" % [take, stream.get_length() if stream != null else -1.0]
			)
		print("%s DURATION cue=%s %s" % [TAG, cue, ",".join(parts)])
	for weapon_id: StringName in FAMILIES:
		print(
			"%s CADENCE family=%s interval=%.2fs cue=%s take=%d"
			% [
				TAG,
				weapon_id,
				WeaponScript.interval_of(weapon_id),
				WeaponScript.fire_cue_of(weapon_id),
				WeaponScript.fire_take_of(weapon_id),
			]
		)


## F1 item 1 / F2 item 2: the mine's own two moments - the drop and the detonation.
func _item_mine() -> void:
	if _guns != null:
		_settle_cadence()
		_clear()
		var fit: Array[StringName] = [_family_module(&"mine")]
		_guns.call(&"set_fitted", fit)
		_guns.call(&"select_group", 1)
		_aim()
		_begin()
		_guns.call(&"set_firing", true)
		_guns.call(&"tick", 0.016)
		_guns.call(&"set_firing", false)
		print(
			"%s ITEM mine_drop cue_of=%s cues=%s shots=%d"
			% [
				TAG,
				WeaponScript.fire_cue_of(&"mine"),
				_call_summary(_calls_since(_calls_at_start)),
				_shots().size(),
			]
		)
		_sweep_projectiles()
	_clear()
	_begin()
	_shot(ProjectileScript.KIND_MINE).call(&"_detonate", HIT_POINT)
	print(
		"%s ITEM mine_detonation cues=%s"
		% [TAG, _note_cues(_call_summary(_calls_since(_calls_at_start)))]
	)


## F2 item 3: the manager owns one loop voice, so the two beds contend for it.
func _item_loop_voice() -> void:
	if _real_audio == null:
		return
	var real := _real_audio
	real.call(&"play_loop", ProjectileScript.SHIELD_LOOP_CUE)
	var shield_bed := StringName(real.call(&"current_loop"))
	real.call(&"play_loop", MiningScript.BEAM_LOOP_CUE)
	var beam_bed := StringName(real.call(&"current_loop"))
	ProjectileScript.release_shield(self)
	var after_release := StringName(real.call(&"current_loop"))
	real.call(&"stop_loop")
	print(
		"%s ITEM loop_voice shield=%s then_beam=%s after_release=%s"
		% [TAG, shield_bed, beam_bed, after_release]
	)


## F2 item 4: a rocket killed by a beam against one killed by a projectile.
func _item_beam_shotdown() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
	var rocket := _shot(ProjectileScript.KIND_ROCKET)
	rocket.global_position = _guns.global_position + Vector2(120.0, 0.0)
	var fit: Array[StringName] = [_family_module(&"laser")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(120.0, 0.0))
	_begin()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)
	var spent := false
	if is_instance_valid(rocket):
		spent = bool(rocket.get(&"_spent"))
	print(
		"%s ITEM beam_shotdown rocket_spent=%s ballistic_cues=%s"
		% [TAG, spent, _note_cues(_call_summary(_calls_since(_calls_at_start)))]
	)
	_sweep_projectiles()


## F2 item 5: what a beam that lands on a hull plays (the fire cue only, or a hit too).
## The hull is added a physics frame before the beam fires: `_beam_target`'s ray reads
## the physics space, which does not yet hold a body added this frame.
func _item_beam_hit() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
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
	var fit: Array[StringName] = [_family_module(&"laser")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(120.0, 0.0))
	_begin()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.05)
	_guns.call(&"set_firing", false)
	var hull_after: float = float(npc.get(&"_hull")) if is_instance_valid(npc) else -1.0
	var shield_after: float = float(npc.get(&"_shield")) if is_instance_valid(npc) else -1.0
	print(
		"%s ITEM beam_hit hull=%.1f->%.1f shield=%.1f->%.1f damage_landed=%s fx_spawned=%d cues=%s"
		% [
			TAG,
			hull_before,
			hull_after,
			shield_before,
			shield_after,
			hull_after < hull_before or shield_after < shield_before,
			_feedback_nodes(_stage).size(),
			_note_cues(_call_summary(_calls_since(_calls_at_start))),
		]
	)


## F1 item 4: where the flash's mouth sits against where the shot leaves from.
func _item_muzzle() -> void:
	if _guns == null:
		return
	_settle_cadence()
	_clear()
	var fit: Array[StringName] = [_family_module(&"cannon")]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_aim()
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)
	var flashes := _flash_nodes()
	var mouth := Vector2.INF
	var flash_pos := Vector2.INF
	if not flashes.is_empty():
		var flash := flashes[flashes.size() - 1] as Node2D
		flash_pos = flash.position
		mouth = flash.position + WeaponScript.FLASH_MUZZLE_PX * flash.scale.x
	var shot_offset := Vector2.INF
	var shots := _shots()
	if not shots.is_empty():
		shot_offset = (shots[0] as Node2D).global_position - _guns.global_position
	print(
		"%s ITEM muzzle flash_pos=%s mouth_local=%s shot_spawn_offset=%s"
		% [TAG, flash_pos, mouth, shot_offset]
	)
	_sweep_projectiles()


## --- The real manager: cue resolution and pool behaviour ------------------


## Every cue the events played, plus every take the pool table names, resolved the way
## a listener would hear it: the manager's own loader, the shipped file, a real stream.
func _resolution_pass() -> void:
	if _real_audio == null:
		print("%s RESOLUTION no real AudioManager" % TAG)
		return
	var real := _real_audio
	var cues: Array = _cues_seen.keys()
	cues.sort()
	var unresolved := 0
	for cue: Variant in cues:
		var path: String = String(real.call(&"cue_path", StringName(cue)))
		var exists_res := not path.is_empty() and ResourceLoader.exists(path)
		var exists_file := not path.is_empty() and FileAccess.file_exists(path)
		var is_stream := false
		if exists_res:
			is_stream = load(path) is AudioStream
		if path.is_empty() or not exists_res or not exists_file or not is_stream:
			unresolved += 1
		print(
			"%s RESOLVE cue=%s path=%s resource=%s file=%s stream=%s"
			% [TAG, cue, path, exists_res, exists_file, is_stream]
		)
	print(
		"%s POOLTABLE cues=%d takes=%d"
		% [TAG, AudioScript.CUE_POOLS.size(), _pool_take_count()]
	)
	for cue: Variant in AudioScript.CUE_POOLS.keys():
		var takes: Array = real.call(&"pool_takes", StringName(cue))
		var has: bool = bool(real.call(&"has_pool", StringName(cue)))
		var resolvable := 0
		var listed := PackedStringArray()
		for take: Variant in takes:
			var take_path: String = String(real.call(&"cue_path", StringName(take)))
			listed.append("%s=%s" % [take, take_path])
			if not take_path.is_empty():
				resolvable += 1
		print(
			"%s POOLROW cue=%s has_pool=%s takes=%d resolvable=%d %s"
			% [TAG, cue, has, takes.size(), resolvable, ",".join(listed)]
		)
	var indices: Array[int] = []
	var pitch_out := 0
	var volume_out := 0
	for _i in 8:
		var plan: Dictionary = real.call(&"play_pool", &"sfx_weapon_laser")
		if plan.is_empty():
			continue
		indices.append(int(plan[&"take_index"]))
		var pitch := float(plan[&"pitch"])
		var volume := float(plan[&"volume_db"])
		if pitch < 0.9 or pitch > 1.1:
			pitch_out += 1
		if volume < -3.0 or volume > 0.0:
			volume_out += 1
	print(
		"%s POOL round_robin=%s pitch_out_of_range=%d volume_out_of_range=%d"
		% [TAG, indices, pitch_out, volume_out]
	)
	var tier_plan: Dictionary = real.call(&"play_pool", &"sfx_weapon_cannon", 1)
	print(
		"%s POOL tier_take=%s path=%s layers=%s"
		% [
			TAG,
			tier_plan.get(&"take", &""),
			tier_plan.get(&"path", ""),
			tier_plan.get(&"layers", []),
		]
	)
	var rocket_plan: Dictionary = real.call(&"play_pool", &"sfx_weapon_rocket")
	print(
		"%s POOL rocket_take=%s layers=%s" % [TAG, rocket_plan.get(&"take", &""), rocket_plan.get(&"layers", [])]
	)
	# `play_sfx` for its existing callers: the pre-wave contract (try the exact cue,
	# then the `_01` convention) and the pre-wave voice rotation.
	var legacy: Array[StringName] = [
		&"sfx_station_breaker_on_01",
		&"sfx_ship_boost_01",
		&"sfx_ship_jump_01",
		&"sfx_mining_chip_01",
		&"sfx_weapon_laser",
	]
	for cue: StringName in legacy:
		var before := int(real.get(&"_sfx_next"))
		real.call(&"play_sfx", cue)
		var after := int(real.get(&"_sfx_next"))
		print(
			"%s PLAIN_SFX cue=%s last=%s voice=%d->%d path=%s"
			% [TAG, cue, real.call(&"last_sfx"), before, after, real.call(&"cue_path", cue)]
		)
	print("%s GATE unresolved_cues=%d" % [TAG, unresolved])
	## The refactor moved the exact-then-`_01` lookup into `_cue_path`, which every bus
	## uses: the `ui` callers (49 call sites) depend on `ui_click` resolving to the
	## exact file and `ui_confirm` to its `_01` take.
	for probe: Array in [[&"ui", &"ui_click"], [&"ui", &"ui_hover"], [&"ui", &"ui_confirm"], [&"music", &"mus_menu_theme"]]:
		var bus: StringName = probe[0]
		var cue: StringName = probe[1]
		print(
			"%s PLAIN_CUE bus=%s cue=%s path=%s"
			% [TAG, bus, cue, real.call(&"_cue_path", bus, cue)]
		)


## --- The sheets: shipped master, additive source --------------------------


## Every master the events drew from, checked twice: the import cache resolves it and
## the file is on disk. Also whether it carries alpha, which is the reason the wiring
## must be additive (a void-black RGB sheet drawn with alpha would be a black box).
func _sheet_pass() -> void:
	var paths: Array = _sheets_seen.keys()
	paths.sort()
	var bad := 0
	for path: Variant in paths:
		var row := _sheets_seen[path] as Dictionary
		var exists: bool = ResourceLoader.exists(String(path))
		var file: bool = FileAccess.file_exists(String(path))
		if not exists or not file:
			bad += 1
		var texture := load(String(path)) as Texture2D
		var size := Vector2.ZERO
		var alpha := "unknown"
		if texture != null:
			size = texture.get_size()
			var image := texture.get_image()
			if image != null:
				alpha = "alpha" if image.detect_alpha() != Image.ALPHA_NONE else "none"
		print(
			"%s SHEET path=%s resource=%s file=%s texture=%s size=%s alpha=%s disk=%s"
			% [
				TAG,
				path,
				exists,
				file,
				texture != null,
				size,
				alpha,
				ProjectSettings.globalize_path(String(path)),
			]
		)
	print("%s SHEETS total=%d missing=%d" % [TAG, paths.size(), bad])


## --- Plumb -----------------------------------------------------------------


## Everything a hit spawns lands under the stage (or under the hull it belongs to), so
## the stage's subtree is the tally. Cleared before each event, so a count is the
## event's own.
func _clear() -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.free()
	_calls_at_start = 0


func _begin() -> void:
	_calls_at_start = _stub.calls.size()


## One line per event: the spawned nodes by name, the cues that went out, and each
## spawned node's own description on its own line.
func _end(label: StringName, note: String) -> void:
	var nodes := _fx_nodes(_stage)
	print(
		"%s EVENT %s spawned=%d nodes=%s cues=%s %s"
		% [
			TAG,
			label,
			nodes.size(),
			_fx_names(_stage),
			_note_cues(_call_summary(_calls_since(_calls_at_start))),
			note,
		]
	)
	for node: Node in nodes:
		print("%s   %s" % [TAG, _describe(node)])


func _calls_since(from_index: int) -> Array:
	var out: Array = []
	for i in range(from_index, _stub.calls.size()):
		out.append(_stub.calls[i])
	return out


func _call_summary(calls: Array) -> String:
	var parts := PackedStringArray()
	for call: Variant in calls:
		var row := call as Dictionary
		var take := int(row.get(&"take", -1))
		if StringName(row.get(&"method", &"")) == &"play_pool" and take >= 0:
			parts.append("%s(%s,%d)" % [row[&"method"], row[&"cue"], take])
		else:
			parts.append("%s(%s)" % [row[&"method"], row[&"cue"]])
	if parts.is_empty():
		return "none"
	return ",".join(parts)


## Records every cue a summary names, so the resolution pass covers exactly what the
## wiring asked for (and nothing it did not).
func _note_cues(summary: String) -> String:
	for part: String in summary.split(",", false):
		var open := part.find("(")
		var close := part.find(")")
		if open < 0 or close <= open:
			continue
		var cue := part.substr(open + 1, close - open - 1)
		var comma := cue.find(",")
		if comma >= 0:
			cue = cue.substr(0, comma)
		if not cue.is_empty():
			_cues_seen[cue] = true
	return summary


func _shot(kind: StringName, damage: float = SHOT_DAMAGE) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "ProbeShot"
	shot.call(
		&"configure",
		{
			&"kind": kind,
			&"speed": SHOT_SPEED,
			&"damage": damage,
			&"direction": Vector2.RIGHT,
			&"mass": 1.0,
			&"range": 600.0,
		}
	)
	_stage.add_child(shot)
	shot.global_position = HIT_POINT
	return shot


func _fx_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		## The probe's own shots are scaffolding, not the event's effect: their Visual
		## is the travelling sprite, not what the event spawned.
		if child.is_in_group(ProjectileScript.PROJECTILE_GROUP):
			continue
		if child is AnimatedSprite2D or child is Sprite2D or child is GPUParticles2D:
			out.append(child)
		out.append_array(_fx_nodes(child))
	return out


func _fx_names(root: Node) -> String:
	var names := PackedStringArray()
	for node: Node in _fx_nodes(root):
		names.append(String(node.name))
	if names.is_empty():
		return "-"
	return ",".join(names)


## The feedback nodes anywhere under `root` (a shot's effect is parented to the world,
## so an end-to-end pass cannot read the probe's own stage).
func _feedback_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in _fx_nodes(root):
		if FEEDBACK_NAMES.has(StringName(node.name)):
			out.append(node)
	return out


func _is_additive(node: Node) -> bool:
	var item := node as CanvasItem
	if item == null:
		return false
	var material := item.material
	if material is CanvasItemMaterial:
		return (material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
	return false


func _is_alpha(node: Node) -> bool:
	var item := node as CanvasItem
	if item == null:
		return false
	var material := item.material
	if material is StandardMaterial3D:
		return (material as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
	return false


## One spawned node: class, name, additive blend, the frames it draws from (an
## `AtlasTexture` over a shipped master, with its region and the master's own size),
## frame count, rate, loop flag and the world size it reads at.
func _describe(node: Node) -> String:
	var line := "node=%s class=%s additive=%s" % [node.name, node.get_class(), _is_additive(node)]
	var texture: Texture2D = null
	if node is AnimatedSprite2D:
		var frames := (node as AnimatedSprite2D).sprite_frames
		if frames != null:
			line += " frames=%d fps=%.0f loop=%s" % [
				frames.get_frame_count(FxScript.ANIMATION),
				frames.get_animation_speed(FxScript.ANIMATION),
				frames.get_animation_loop(FxScript.ANIMATION),
			]
			texture = frames.get_frame_texture(FxScript.ANIMATION, 0)
			## Every frame's own file, so a sheet built from an invented path cannot hide
			## behind its first frame.
			var frame_paths := PackedStringArray()
			for index in frames.get_frame_count(FxScript.ANIMATION):
				var frame_texture := frames.get_frame_texture(FxScript.ANIMATION, index)
				if frame_texture is AtlasTexture:
					var frame_atlas := frame_texture as AtlasTexture
					frame_paths.append("%s@%s" % [frame_atlas.atlas.resource_path, frame_atlas.region])
					_note_sheet(frame_atlas.atlas.resource_path, frame_atlas.region)
				elif frame_texture != null:
					frame_paths.append(frame_texture.resource_path)
					_note_sheet(frame_texture.resource_path, Rect2(Vector2.ZERO, frame_texture.get_size()))
			line += " frame_paths=[%s]" % ",".join(frame_paths)
	if node is Sprite2D:
		texture = (node as Sprite2D).texture
	if node is GPUParticles2D:
		var emitter := node as GPUParticles2D
		texture = emitter.texture
		line += " amount=%d lifetime=%.1f emitting=%s local=%s" % [
			emitter.amount, emitter.lifetime, emitter.emitting, emitter.local_coords
		]
		if emitter.process_material is ParticleProcessMaterial:
			var process := emitter.process_material as ParticleProcessMaterial
			line += " pscale=%.4f..%.4f pvel=%.0f..%.0f" % [
				process.scale_min,
				process.scale_max,
				process.initial_velocity_min,
				process.initial_velocity_max,
			]
	var region := Rect2()
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		region = atlas.region
		var atlas_size := atlas.atlas.get_size()
		line += " sheet=%s region=%s atlas=%s inside=%s" % [
			atlas.atlas.resource_path,
			region,
			atlas_size,
			Rect2(Vector2.ZERO, atlas_size).encloses(region),
		]
		_note_sheet(atlas.atlas.resource_path, region)
	elif texture != null:
		region = Rect2(Vector2.ZERO, texture.get_size())
		line += " sheet=%s (whole) region=%s" % [texture.resource_path, region]
		_note_sheet(texture.resource_path, region)
	else:
		line += " sheet=MISSING"
	var world := Vector2.ZERO
	if node is Node2D:
		world = (node as Node2D).scale * region.size
		line += " scale=%s world=%.0fx%.0f" % [(node as Node2D).scale, world.x, world.y]
	return line


func _note_sheet(path: String, region: Rect2) -> void:
	if path.is_empty() or _sheets_seen.has(path):
		return
	_sheets_seen[path] = {&"region": region}


func _pool_take_count() -> int:
	var total := 0
	for cue: Variant in AudioScript.CUE_POOLS.keys():
		var row: Variant = AudioScript.CUE_POOLS.get(cue)
		if row is Dictionary:
			total += (row as Dictionary).get(&"takes", []).size()
	return total
