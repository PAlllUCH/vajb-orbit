extends Node
## Runtime audio buses and cue hooks. Every cue is a silent no-op until its file exists.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.5 and 3.8, AUDIO_SPEC section 4.3.
## Music and ambience extend it: docs/design/THEME_AUDIO_EXTENSION.md section 4.

enum UiCue { CLICK, HOVER, CONFIRM, DENIED, SCROLL }

const Paths := preload("res://ui/paths.gd")

const CUE_DIRS: Dictionary = Paths.AUDIO_DIRS

const BUS_BY_KEY: Dictionary = {
	&"master": &"Master",
	&"music": &"Music",
	&"sfx": &"SFX",
	&"ui": &"UI",
}

const UI_CUE_NAMES: Dictionary = {
	UiCue.CLICK: &"ui_click",
	UiCue.HOVER: &"ui_hover",
	UiCue.CONFIRM: &"ui_confirm",
	UiCue.DENIED: &"ui_denied",
	UiCue.SCROLL: &"ui_scroll",
}

const SFX_PLAYER_COUNT := 4
const CUE_EXTENSION := ".ogg"

const MUSIC_DIR_KEY := &"music"
const AMBIENCE_DIR_KEY := &"ambience"

## A fade never asks linear_to_db() for -inf, and a muted bus parks the player here.
const SILENT_DB := -80.0

var _ui_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_track: StringName = &""
var _ambience_bed: StringName = &""
var _music_tween: Tween
var _ambience_tween: Tween


func _ready() -> void:
	_build_buses()
	_ui_player = _make_player(&"UI")
	for i in SFX_PLAYER_COUNT:
		_sfx_players.append(_make_player(&"SFX"))
	_music_player = _make_player(&"Music")
	_music_player.name = &"MusicPlayer"
	_ambience_player = _make_player(&"SFX")
	_ambience_player.name = &"AmbiencePlayer"
	_apply_settings_volumes()


func play_ui(cue: UiCue) -> void:
	_play(&"ui", StringName(UI_CUE_NAMES.get(cue, &"")))


func play_sfx(cue: StringName) -> void:
	_play(&"sfx", cue)


func play_music(track: StringName, fade_seconds: float = 1.0) -> void:
	if track == &"" or track == _music_track:
		return
	var stream := _load_cue(MUSIC_DIR_KEY, track)
	if stream == null:
		return
	_set_loop(stream)
	_music_track = track
	_kill_music_tween()
	_music_tween = _crossfade(_music_player, &"Music", stream, fade_seconds)


func stop_music(fade_seconds: float = 1.0) -> void:
	if _music_track == &"":
		return
	_music_track = &""
	_kill_music_tween()
	_music_tween = _fade_out(_music_player, fade_seconds)


func current_music() -> StringName:
	return _music_track


func play_ambience(bed: StringName, fade_seconds: float = 1.0) -> void:
	if bed == &"" or bed == _ambience_bed:
		return
	var stream := _load_cue(AMBIENCE_DIR_KEY, bed)
	if stream == null:
		return
	_set_loop(stream)
	_ambience_bed = bed
	_kill_ambience_tween()
	_ambience_tween = _crossfade(_ambience_player, &"SFX", stream, fade_seconds)


func stop_ambience(fade_seconds: float = 1.0) -> void:
	if _ambience_bed == &"":
		return
	_ambience_bed = &""
	_kill_ambience_tween()
	_ambience_tween = _fade_out(_ambience_player, fade_seconds)


func current_ambience() -> StringName:
	return _ambience_bed


func set_bus_linear(bus: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var linear := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.0)
	if linear > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


func bus_linear(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _build_buses() -> void:
	for bus: StringName in Paths.AUDIO_BUSES:
		_ensure_bus(bus)
		if bus != &"Master":
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), &"Master")
	for bus: StringName in Paths.AUDIO_SUB_BUSES:
		_ensure_bus(bus)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus), StringName(Paths.AUDIO_SUB_BUSES[bus]))


func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)


func _apply_settings_volumes() -> void:
	var settings := _service(&"SettingsManager")
	for key: StringName in BUS_BY_KEY:
		var value := 1.0
		if settings != null and settings.has_method(&"get_value"):
			value = float(settings.call(&"get_value", &"audio", key, 1.0))
		set_bus_linear(StringName(BUS_BY_KEY[key]), value)


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _play(bus: StringName, cue: StringName) -> void:
	if cue == &"":
		return
	var stream := _load_cue(bus, cue)
	if stream == null:
		return
	if bus == &"ui":
		_ui_player.stream = stream
		_ui_player.play()
		return
	var player := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	player.stream = stream
	player.play()


## AUDIO_SPEC section 6 requires a two-digit variant index, so an exact cue name
## is tried first and the "_01" convention second.
func _load_cue(bus: StringName, cue: StringName) -> AudioStream:
	var directory: String = CUE_DIRS.get(bus, "")
	if directory.is_empty():
		return null
	for candidate: String in [directory + cue + CUE_EXTENSION, directory + cue + "_01" + CUE_EXTENSION]:
		if ResourceLoader.exists(candidate):
			return load(candidate) as AudioStream
	return null


## One player per bus: the current track fades out, the stream is swapped in a
## callback, then the new stream fades in. Two beds can never sound at once and
## the outgoing one is never cut.
func _crossfade(player: AudioStreamPlayer, bus: StringName, stream: AudioStream, fade_seconds: float) -> Tween:
	var half := maxf(fade_seconds, 0.0) * 0.5
	var tween := create_tween()
	if player.playing:
		tween.tween_property(player, "volume_db", SILENT_DB, half)
	tween.tween_callback(_start_stream.bind(player, stream))
	tween.tween_property(player, "volume_db", _bus_target_db(bus), half)
	return tween


func _start_stream(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stream = stream
	player.volume_db = SILENT_DB
	player.play()


func _fade_out(player: AudioStreamPlayer, fade_seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, maxf(fade_seconds, 0.0))
	tween.tween_callback(player.stop)
	return tween


## A muted bus, or a bus that does not exist, leaves the player silent rather than
## asking linear_to_db() for -inf.
func _bus_target_db(bus: StringName) -> float:
	var linear := bus_linear(bus)
	if linear <= 0.0:
		return SILENT_DB
	return clampf(linear_to_db(linear), SILENT_DB, 0.0)


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null


func _kill_ambience_tween() -> void:
	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_tween = null


func _service(service_name: StringName) -> Node:
	## Autoload names are not resolvable identifiers until the project patch lands
	## (project.godot is applied by the orchestrator), so services are looked up by name.
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(service_name))
