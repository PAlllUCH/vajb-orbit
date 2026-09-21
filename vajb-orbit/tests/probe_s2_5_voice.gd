extends Node2D
## S2's focused audio probe: whether a held bed's voice is actually playing a stream.
##
## `AudioManager.sounding_loops()` / `bed_state()` report a bed from the cue table alone,
## so a bed can be "sounding" on paper while its `AudioStreamPlayer` has no stream at all.
## The three arms below separate the mechanism:
##   A - the mining beam's bed, started the pre-wave way: `play_loop(cue)` and nothing else;
##   B - `play_loop(THRUSTER_CUE)` on its own (no per-frame shaping);
##   C - `hold_thruster_bed(...)`, which is `play_loop` plus `_shape_bed` in the same frame.
##
## Run:
##   ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_voice.tscn \
##     --fixed-fps 60 --quit-after 900

const AudioScript := preload("res://autoload/audio_manager.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const TAG := "[S2V]"
const THRUSTER_CUE: StringName = &"sfx_ship_engine_01"
const SHIELD_BED: StringName = &"sfx_impact_shield_loop"
const BEAM_BED: StringName = &"sfx_mining_beam"
const OTHER_LOOP: StringName = &"sfx_ship_engine_02_loop"


func _ready() -> void:
	var audio := _audio()
	if audio == null:
		print("%s audio=missing" % TAG)
		get_tree().quit()
		return
	print("%s HEADS cue_engine=%s cue_beam=%s" % [TAG, audio.call(&"cue_path", THRUSTER_CUE), audio.call(&"cue_path", BEAM_BED)])
	await _arm(audio, BEAM_BED, "A_beam_play_loop_only")
	await _arm(audio, THRUSTER_CUE, "B_thruster_play_loop_only")
	await _arm(audio, OTHER_LOOP, "B2_other_loop_play_loop_only")
	await _shaped_arm(audio)
	await _steal_arm(audio)
	await _death_arm(audio)
	await _full_house_arm(audio)
	print("%s done" % TAG)
	get_tree().quit()


func _audio() -> Node:
	return get_tree().root.get_node_or_null(NodePath(&"AudioManager"))


func _clear(audio: Node) -> void:
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)
	audio.call(&"stop_bed", OTHER_LOOP)
	audio.call(&"stop_thruster_bed")
	for i in 6:
		await get_tree().process_frame


## `play_loop` and then nothing else - the shape every pre-wave bed call has.
func _arm(audio: Node, cue: StringName, label: String) -> void:
	await _clear(audio)
	var foreground: StringName = audio.call(&"play_loop", cue)
	var index := _index(audio, cue)
	print(
		"%s ARM %s cue=%s play_loop_returned=%s index=%d sounding=%s"
		% [TAG, label, cue, foreground, index, str((audio.call(&"sounding_loops") as Array).has(cue))]
	)
	for frame: int in [1, 2, 3, 10, 30, 90]:
		while _frames < frame:
			_frames += 1
			await get_tree().process_frame
		_report(audio, cue, label, frame)
	_frames = 0


## `hold_thruster_bed`: the shipping route, re-asked on every frame the ship holds it.
func _shaped_arm(audio: Node) -> void:
	await _clear(audio)
	var held: bool = audio.call(&"hold_thruster_bed", 0.5, true)
	var index := _index(audio, THRUSTER_CUE)
	var state: Dictionary = audio.call(&"bed_state", THRUSTER_CUE)
	print(
		"%s ARM C_hold_thruster_bed held=%s index=%d reported_sounding=%s pitch=%.4f volume_db=%.4f"
		% [
			TAG,
			held,
			index,
			str(bool(state[&"sounding"])),
			float(state[&"pitch_scale"]),
			float(state[&"volume_db"]),
		]
	)
	for frame: int in [1, 2, 3, 10, 30, 90]:
		while _frames < frame:
			_frames += 1
			await get_tree().process_frame
		audio.call(&"hold_thruster_bed", 0.5, true)
		_report(audio, THRUSTER_CUE, "C_hold_thruster_bed", frame)
	_frames = 0
	audio.call(&"stop_thruster_bed")


## What the shipping order does to a voice another bed was using: the thruster bed asks
## for a voice while the beam's bed holds one.
func _steal_arm(audio: Node) -> void:
	await _clear(audio)
	audio.call(&"play_loop", BEAM_BED)
	for i in 3:
		await get_tree().process_frame
	var beam_index := _index(audio, BEAM_BED)
	_report(audio, BEAM_BED, "D_beam_before_the_ask", 0)
	audio.call(&"hold_thruster_bed", 0.5, true)
	for i in 30:
		await get_tree().process_frame
	var thruster_index := _index(audio, THRUSTER_CUE)
	print(
		"%s ARM D_steal beam_index=%d thruster_index=%d beds=[%s]"
		% [TAG, beam_index, thruster_index, _names(audio.call(&"sounding_loops") as Array)]
	)
	_report(audio, THRUSTER_CUE, "D_thruster_after_the_ask", 0)
	audio.call(&"stop_thruster_bed")
	audio.call(&"stop_bed", BEAM_BED)


var _frames := 0


func _report(audio: Node, cue: StringName, label: String, frame: int) -> void:
	var index := _index(audio, cue)
	if index < 0:
		print("%s ARM %s frame=%d cue=gone" % [TAG, label, frame])
		return
	var players: Array = audio.get(&"_loop_players")
	var player := players[index] as AudioStreamPlayer
	print(
		"%s ARM %s frame=%d index=%d playing=%s stream=%s volume_db=%.4f pitch=%.4f"
		% [
			TAG,
			label,
			frame,
			index,
			str(player.playing),
			"<none>" if player.stream == null else player.stream.resource_path,
			player.volume_db,
			player.pitch_scale,
		]
	)


func _index(audio: Node, cue: StringName) -> int:
	var cues: Array = audio.get(&"_loop_cues")
	for index in cues.size():
		if StringName(cues[index]) == cue:
			return index
	return -1


func _names(values: Array) -> String:
	var out: PackedStringArray = []
	for value: Variant in values:
		out.append(String(value))
	return ", ".join(out)

## A wreck does not thrust: one hull, its bed held, then killed - the shipped path.
func _death_arm(audio: Node) -> void:
	await _clear(audio)
	var ship_scene := load("res://game/player_ship.tscn") as PackedScene
	var fit: Dictionary = ShipFitScript.STANDARD_FIT.duplicate(true)
	var stats: Variant = ShipFitScript.resolve(&"ship_vanguard", fit)
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.setup()
	state.hull = stats.hull_max
	var holder := Node2D.new()
	add_child(holder)
	var ship: Variant = ship_scene.instantiate()
	holder.add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	ship.call(&"set_speed_ratio", 0.8)
	Input.action_press(&"thrust_forward")
	for i in 4:
		await get_tree().physics_frame
	print(
		"%s ARM E_before_death sounding=%s beds=[%s] trails=%d"
		% [
			TAG,
			str((audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE)),
			_names(audio.call(&"sounding_loops") as Array),
			(ship.call(&"thruster_trails") as Array).size(),
		]
	)
	state.damage(state.hull + 1.0, true)
	## The shipped order: the hull's own handler releases first (it runs off `hull_changed`),
	## then `game.gd:_switch_ship_off()` stops the wreck's physics so nothing re-asks.
	ship.set_physics_process(false)
	Input.action_release(&"thrust_forward")
	for i in 6:
		await get_tree().physics_frame
	var trails := 0
	for child: Node in ship.get_children():
		if child is GPUParticles2D and String(child.name).begins_with("ThrusterTrail"):
			trails += 1
	print(
		"%s ARM E_after_death sounding=%s beds=[%s] trail_children=%d"
		% [
			TAG,
			str((audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE)),
			_names(audio.call(&"sounding_loops") as Array),
			trails,
		]
	)
	holder.queue_free()
	await get_tree().process_frame

## What `hold_thruster_bed` reports when every voice is held: the doc says "returns whether
## the bed is sounding", the code returns whether it is *held*.
func _full_house_arm(audio: Node) -> void:
	await _clear(audio)
	audio.call(&"play_loop", SHIELD_BED)
	audio.call(&"play_loop", BEAM_BED)
	audio.call(&"play_loop", OTHER_LOOP)
	var held: bool = audio.call(&"hold_thruster_bed", 0.5, true)
	var state: Dictionary = audio.call(&"bed_state", THRUSTER_CUE)
	print(
		"%s ARM F_full_house returned=%s bed_state_sounding=%s beds=[%s] cue_in_voice_table=%s"
		% [
			TAG,
			str(held),
			str(bool(state[&"sounding"])),
			_names(audio.call(&"sounding_loops") as Array),
			str(_index(audio, THRUSTER_CUE) >= 0),
		]
	)
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)
	audio.call(&"stop_bed", OTHER_LOOP)
	audio.call(&"stop_thruster_bed")
