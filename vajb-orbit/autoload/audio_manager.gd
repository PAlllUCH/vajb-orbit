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

## --- Cue pools (docs/design/ASSET_WIRING_HANDOFF.md section 1.2) -----------
##
## One cue name resolves to exactly one file above; the extra takes the AUDIO_SPEC
## round-robin rules need are unreachable through it. A pool is that missing route:
## the takes on disk a cue name owns, the mode that picks one per call, the pitch and
## volume range the spec states for it, and any layer that follows it after a delay.
##
## `mode` `round_robin` cycles the takes call by call; `tier` stays put (a weapon
## picks its own tier through `play_pool`'s index). `pitch` is the +/- fraction and
## `volume_db` is a [min, max] pair; a row that states neither randomises nothing,
## so only the ranges the spec actually gives are applied.
const POOL_ROUND_ROBIN: StringName = &"round_robin"
const POOL_TIER: StringName = &"tier"

## AUDIO_SPEC section 8's cue table with section 4.1's variant rules. The table is
## data, not policy: a caller asks for a cue name and gets a take.
const CUE_POOLS: Dictionary = {
	## S1: "round-robin of 3-4 laser one-shots, pitch +/-10 %, vol +/-3 dB".
	&"sfx_weapon_laser": {
		&"takes": [
			&"sfx_weapon_laser_01",
			&"sfx_weapon_laser_02",
			&"sfx_weapon_laser_03",
			&"sfx_weapon_laser_04",
		],
		&"mode": POOL_ROUND_ROBIN,
		&"pitch": 0.10,
		&"volume_db": [-3.0, 0.0],
	},
	## S2: take 01 is the cue's own tier-1 file; 02/03 are the heavier tiers, picked
	## by index (the tier is the shooter's, not the pool's, so the mode stays put).
	&"sfx_weapon_cannon": {
		&"takes": [
			&"sfx_weapon_cannon_01",
			&"sfx_weapon_cannon_02_medium",
			&"sfx_weapon_cannon_03_long",
		],
		&"mode": POOL_TIER,
		&"pitch": 0.0,
		&"volume_db": [0.0, 0.0],
	},
	## S3: the launch layer, plus the warhead layer 80 ms later (the handoff's own
	## offset). Both ride one call so no caller owns a timer.
	&"sfx_weapon_rocket": {
		&"takes": [&"sfx_weapon_rocket_01"],
		&"pitch": 0.0,
		&"volume_db": [0.0, 0.0],
		&"layers": [
			{
				&"take": &"sfx_weapon_rocket_02_warhead",
				&"delay": 0.08,
				&"volume_db": [0.0, 0.0],
			},
		],
	},
	&"sfx_weapon_explosion": {
		&"takes": [&"sfx_weapon_explosion_01", &"sfx_weapon_explosion_02"],
		&"mode": POOL_ROUND_ROBIN,
		&"pitch": 0.0,
		&"volume_db": [0.0, 0.0],
	},
	&"sfx_impact_hull": {
		&"takes": [
			&"sfx_impact_hull_01",
			&"sfx_impact_hull_02",
			&"sfx_impact_hull_03",
			&"sfx_impact_hull_04",
			&"sfx_impact_hull_05",
		],
		&"mode": POOL_ROUND_ROBIN,
		&"pitch": 0.0,
		&"volume_db": [0.0, 0.0],
	},
	&"sfx_impact_shield_hit": {
		&"takes": [
			&"sfx_impact_shield_hit_01",
			&"sfx_impact_shield_hit_02",
			&"sfx_impact_shield_hit_03",
			&"sfx_impact_shield_hit_04",
			&"sfx_impact_shield_hit_05",
			&"sfx_impact_shield_hit_06",
			&"sfx_impact_shield_hit_07",
			&"sfx_impact_shield_hit_08",
			&"sfx_impact_shield_hit_09",
		],
		&"mode": POOL_ROUND_ROBIN,
		&"pitch": 0.0,
		&"volume_db": [0.0, 0.0],
	},
}

## The default crossfade a loop voice fades in and out over.
const LOOP_FADE := 0.15

## --- Loop beds (AUDIO_SPEC section 4.2) -----------------------------------
##
## A bed is a looping stream that belongs to a held state: S7's mining shaft, S6's
## shield hum, a held weapon beam. Section 4.2 builds every composite cue out of
## sibling loop layers, and one voice for all of them made the two world beds contend
## for it - a miner who took a shielded hit heard the shaft and never the shield's hum
## (reported). Each bed now holds its own voice, a priority decides which bed gives way
## when every voice is busy, and a bed nobody re-asks for is released by its own lease.

## The beds the game can hold at once: a mining shaft, a held weapon beam, an impact hum.
const LOOP_VOICE_COUNT := 3

## How long a bed survives without being asked for again, in seconds. A held bed re-asks
## every frame it is held (the mining shaft and the held weapon beam both do), so the
## lease only ever releases a bed whose owner's stop call was skipped - the two existing
## callers find their bed through `current_loop()`, one value that cannot name two
## sounding beds at once (reported). Not a fade: a bed that keeps being asked for never
## expires, and a bed that is put out properly is never touched by this.
const LOOP_LEASE := 1.2

## Which bed gives way first when every voice is busy: the higher number keeps its voice
## against a lower one. An impact read (S6's hum) outranks a held tool's own bed.
const LOOP_PRIORITY: Dictionary = {
	&"sfx_impact_shield_loop": 2,
	&"sfx_mining_beam": 1,
}
const LOOP_PRIORITY_DEFAULT := 1

var _ui_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
## The take each one-shot voice was last handed ("" for a voice no pooled call has
## filled) and a monotonic stamp per assignment, so a take can find its own oldest
## voice. Side bookkeeping only: `play_sfx`'s own rotation never reads it.
var _sfx_take: Array[StringName] = []
var _sfx_stamp: Array[int] = []
var _sfx_clock := 0
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_track: StringName = &""
var _ambience_bed: StringName = &""
var _music_tween: Tween
var _ambience_tween: Tween
## The loop beds. Parallel arrays, one entry per voice: the cue it holds ("" for free),
## the stamp it started at (the oldest wins a tie) and the time it was last asked for
## (the lease). They are separate from the one-shot voices so a held bed can never steal
## a shot, exactly as the single loop voice was.
var _loop_players: Array[AudioStreamPlayer] = []
var _loop_cues: Array[StringName] = []
var _loop_started: Array[int] = []
var _loop_asked: Array[int] = []
var _loop_tweens: Array[Tween] = []
var _loop_clock := 0
## Per-cue round-robin cursor and the last cue the SFX bus was handed (a headless
## probe cannot hear a cue, so it reads this instead).
var _pool_next: Dictionary = {}
var _last_sfx: StringName = &""


func _ready() -> void:
	_build_buses()
	_ui_player = _make_player(&"UI")
	for i in SFX_PLAYER_COUNT:
		_sfx_players.append(_make_player(&"SFX"))
		_sfx_take.append(&"")
		_sfx_stamp.append(0)
	_music_player = _make_player(&"Music")
	_music_player.name = &"MusicPlayer"
	_ambience_player = _make_player(&"SFX")
	_ambience_player.name = &"AmbiencePlayer"
	for i in LOOP_VOICE_COUNT:
		var bed_player := _make_player(&"SFX")
		bed_player.name = &"LoopPlayer%d" % i
		_loop_players.append(bed_player)
		_loop_cues.append(&"")
		_loop_started.append(0)
		_loop_asked.append(0)
		_loop_tweens.append(null)
	_apply_settings_volumes()


## The beds' leases are checked every frame as well as on every ask, so a bed nobody
## asks for any more goes out even when nothing else is being asked for.
func _process(_delta: float) -> void:
	_expire_loops()


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


## --- Cue pools and loops (the two routes the player's hands need) ---------
##
## `play_sfx` stays exactly what it was: one cue name, one file, one shared voice.
## These two extend it without touching any existing caller.


## Whether a cue name owns a pool of takes (the handoff's section 1.2 table).
func has_pool(cue: StringName) -> bool:
	return cue_pool(cue).has(&"takes")


## A cue's pool row, or an empty Dictionary when the cue has none.
func cue_pool(cue: StringName) -> Dictionary:
	var row: Variant = CUE_POOLS.get(cue)
	if row is Dictionary:
		return row as Dictionary
	return {}


## The takes a cue's pool holds, in order (empty for a cue with no pool).
func pool_takes(cue: StringName) -> Array:
	return cue_pool(cue).get(&"takes", [])


## Play a pooled cue on its own SFX voice, with the row's own pitch and volume
## range, and schedule any layer the row carries (S3's warhead at +80 ms).
##
## `take` >= 0 picks that take by index (a weapon's tier); -1 leaves the choice to
## the row: `round_robin` cycles the takes call by call, `tier` stays on the first.
## A cue with no pool falls back to `play_sfx`, so one call site can address both.
##
## Returns the plan that went out - `{cue, take, take_index, path, pitch, volume_db,
## layers: [{take, delay}]}` - or `{}` when nothing resolved. A headless probe reads
## this instead of listening.
func play_pool(cue: StringName, take: int = -1) -> Dictionary:
	var pool := cue_pool(cue)
	if pool.is_empty():
		play_sfx(cue)
		return {}
	var takes: Array = pool.get(&"takes", [])
	if takes.is_empty():
		return {}
	var index := _pool_index(cue, pool, take, takes.size())
	var played := _play_take(StringName(takes[index]), pool)
	if played.is_empty():
		return {}
	var layers: Array = []
	for layer: Variant in pool.get(&"layers", []):
		if not layer is Dictionary:
			continue
		var row := layer as Dictionary
		var layer_take := StringName(row.get(&"take", &""))
		if layer_take == &"":
			continue
		var delay := maxf(float(row.get(&"delay", 0.0)), 0.0)
		if delay <= 0.0:
			_play_take(layer_take, row)
		else:
			_schedule_take(layer_take, row, delay)
		layers.append({&"take": layer_take, &"delay": delay})
	return {
		&"cue": cue,
		&"take": StringName(takes[index]),
		&"take_index": index,
		&"path": played[&"path"],
		&"pitch": played[&"pitch"],
		&"volume_db": played[&"volume_db"],
		&"layers": layers,
	}


## A bed sounds on its own voice: S7's mining shaft, S6's shield hum and a held weapon
## beam are three beds the game can hold at once, and one voice for all of them meant the
## second bed silenced the first (reported). Re-asking for a bed already sounding
## refreshes its lease and is otherwise a no-op, so a held bed may call this every frame.
## When every voice is busy a bed only gives way to a higher-priority one
## (`LOOP_PRIORITY`); a peer's request is dropped rather than thrashing a voice.
##
## Returns the cue in the foreground (`current_loop()`), which is not necessarily the bed
## this call started.
func play_loop(cue: StringName, fade_seconds: float = LOOP_FADE) -> StringName:
	_expire_loops()
	if cue == &"":
		return current_loop()
	var index := _loop_cues.find(cue)
	if index >= 0:
		_loop_asked[index] = _now_ms()
		return current_loop()
	var stream := _load_cue(&"sfx", cue)
	if stream == null:
		return current_loop()
	index = _loop_voice_for(cue)
	if index < 0:
		return current_loop()
	_set_loop(stream)
	_clear_loop_voice(index)
	_loop_cues[index] = cue
	_loop_started[index] = _loop_clock
	_loop_asked[index] = _now_ms()
	_loop_clock += 1
	_kill_loop_tween(index)
	_loop_tweens[index] = _crossfade(_loop_players[index], &"SFX", stream, fade_seconds)
	return current_loop()


## Put a bed out. Without a cue the bed in the foreground goes out - the pre-wave
## behaviour every existing caller relies on, since each of them checks `current_loop()`
## for its own bed first; with one, exactly that bed goes out.
func stop_loop(fade_seconds: float = LOOP_FADE, cue: StringName = &"") -> void:
	_expire_loops()
	var target := cue if cue != &"" else current_loop()
	if target == &"":
		return
	var index := _loop_cues.find(target)
	if index < 0:
		return
	_put_loop_voice_out(index, fade_seconds)


## Put one named bed out, whatever is in the foreground. A caller whose bed is not the
## foreground one cannot reach it through `current_loop()` plus `stop_loop()` - the two
## beds of a held weapon beam and an impact hum are both sounding at once, and only one of
## them can be the foreground (measured; `.agents/gen/weapon_fx_f4_probe.txt`).
## Returns whether that bed was sounding.
func stop_bed(cue: StringName, fade_seconds: float = LOOP_FADE) -> bool:
	_expire_loops()
	if cue == &"":
		return false
	var index := _loop_cues.find(cue)
	if index < 0:
		return false
	_put_loop_voice_out(index, fade_seconds)
	return true


## The bed in the foreground: the highest-priority one sounding, and the most recently
## started of equals. The two existing callers read it to check that the bed they are
## about to stop is their own, so the more important bed is the one they see. "" when no
## bed is sounding, which is the pre-wave answer for a voice with no bed on it.
func current_loop() -> StringName:
	var best := &""
	var best_priority := -1
	var best_started := -1
	for index in _loop_cues.size():
		var cue := _loop_cues[index]
		if cue == &"":
			continue
		var priority := int(LOOP_PRIORITY.get(cue, LOOP_PRIORITY_DEFAULT))
		if priority > best_priority or (
			priority == best_priority and _loop_started[index] > best_started
		):
			best = cue
			best_priority = priority
			best_started = _loop_started[index]
	return best


## Every bed currently sounding, in the foreground's own order. Audio cannot be heard
## headless: a probe reads this where a listener would hear it.
func sounding_loops() -> Array[StringName]:
	var ranked: Array[Dictionary] = []
	for index in _loop_cues.size():
		if _loop_cues[index] == &"":
			continue
		ranked.append({
			&"cue": _loop_cues[index],
			&"priority": int(LOOP_PRIORITY.get(_loop_cues[index], LOOP_PRIORITY_DEFAULT)),
			&"started": _loop_started[index],
		})
	ranked.sort_custom(_loop_rank_before)
	var out: Array[StringName] = []
	for row: Dictionary in ranked:
		out.append(StringName(row[&"cue"]))
	return out


## The take each one-shot voice currently holds, in voice order. A probe reads this
## instead of hearing the pool - the same reason `last_sfx()` exists.
func voice_takes() -> Array[StringName]:
	return _sfx_take.duplicate()


## The `res://` path a cue resolves to on the `sfx` bus ("" when nothing resolves).
## The same lookup `play_sfx` and the pools use, exposed so a headless test can prove
## a cue resolves without hearing it.
func cue_path(cue: StringName) -> String:
	return _cue_path(&"sfx", cue)


## The last cue name the SFX bus was handed, plain or pooled. Audio cannot be heard
## headless; a probe reads this and the plan `play_pool` returns instead.
func last_sfx() -> StringName:
	return _last_sfx


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


## One SFX voice, with its pitch and volume reset to the plain defaults so a pooled
## take's variation can never leak into the next caller's `play_sfx`.
##
## `key` is the take about to be handed the voice. A voice that already holds that same
## take is the one this call re-triggers (AUDIO_SPEC section 4.1, "overlapping triggers
## steal the oldest playing voice"), so a one-shot that outlasts its own cadence
## re-starts itself rather than consuming the pool and cutting another take's tail: the
## cannon's 3.46 s take against its 0.60 s cadence needed 5.8 of the 4 voices (reported).
## An empty key is the plain `play_sfx` path, whose rotation is pre-wave behaviour: the
## round-robin cursor always advances there.
func _take_sfx_player(key: StringName = &"") -> AudioStreamPlayer:
	var index := -1
	if key != &"":
		index = _oldest_voice_of(key)
	if index < 0:
		index = _sfx_next
		_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	_sfx_take[index] = key
	_sfx_stamp[index] = _sfx_clock
	_sfx_clock += 1
	var player := _sfx_players[index]
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	return player


## The voice whose take is `take`, oldest first; -1 when no voice holds it.
func _oldest_voice_of(take: StringName) -> int:
	var best := -1
	for index in _sfx_take.size():
		if _sfx_take[index] != take:
			continue
		if best < 0 or _sfx_stamp[index] < _sfx_stamp[best]:
			best = index
	return best


## The voice a new bed takes: a free one, else the oldest of the beds this one outranks.
## -1 when every voice is held by a bed of the same or a higher priority - the request is
## dropped rather than displacing a peer, so two held beds can never thrash one voice.
func _loop_voice_for(cue: StringName) -> int:
	var free := _loop_cues.find(&"")
	if free >= 0:
		return free
	var priority := int(LOOP_PRIORITY.get(cue, LOOP_PRIORITY_DEFAULT))
	var victim := -1
	for index in _loop_cues.size():
		var held := int(LOOP_PRIORITY.get(_loop_cues[index], LOOP_PRIORITY_DEFAULT))
		if held >= priority:
			continue
		if victim < 0 or _loop_started[index] < _loop_started[victim]:
			victim = index
	return victim


func _clear_loop_voice(index: int) -> void:
	_loop_cues[index] = &""
	_loop_started[index] = 0
	_loop_asked[index] = 0


## A bed goes out: its own voice fades and is freed for the next bed.
func _put_loop_voice_out(index: int, fade_seconds: float) -> void:
	_kill_loop_tween(index)
	var player := _loop_players[index]
	if player.playing:
		_loop_tweens[index] = _fade_out(player, fade_seconds)
	_clear_loop_voice(index)


## A bed nobody has asked for inside `LOOP_LEASE` goes out by itself: the two existing
## callers identify their bed through `current_loop()`, one value that cannot name two
## sounding beds, so a bed whose stop call was skipped has no other release (reported).
func _expire_loops() -> void:
	var now := _now_ms()
	var lease := int(round(LOOP_LEASE * 1000.0))
	for index in _loop_cues.size():
		if _loop_cues[index] == &"" or _loop_asked[index] <= 0:
			continue
		if now - _loop_asked[index] <= lease:
			continue
		_put_loop_voice_out(index, LOOP_FADE)


func _now_ms() -> int:
	return Time.get_ticks_msec()


## The foreground's order: the higher priority first, and the more recently started of
## equals.
func _loop_rank_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a[&"priority"]) != int(b[&"priority"]):
		return int(a[&"priority"]) > int(b[&"priority"])
	return int(a[&"started"]) > int(b[&"started"])


func _play(bus: StringName, cue: StringName) -> void:
	if cue == &"":
		return
	var stream := _load_cue(bus, cue)
	if stream == null:
		return
	_last_sfx = cue
	if bus == &"ui":
		_ui_player.stream = stream
		_ui_player.play()
		return
	var player := _take_sfx_player()
	player.stream = stream
	player.play()


## One take of a pool, on its own voice, with the row's stated pitch and volume
## range applied. Returns the numbers it played, or {} when the take's file is
## missing.
func _play_take(take: StringName, row: Dictionary) -> Dictionary:
	var path := _cue_path(&"sfx", take)
	if path.is_empty():
		return {}
	var stream := load(path) as AudioStream
	if stream == null:
		return {}
	var spread := maxf(float(row.get(&"pitch", 0.0)), 0.0)
	var pitch := 1.0
	if spread > 0.0:
		pitch = 1.0 + randf_range(-spread, spread)
	var volume := _db_range(row)
	var player := _take_sfx_player(take)
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume
	player.play()
	_last_sfx = take
	return {&"path": path, &"pitch": pitch, &"volume_db": volume}


## A pool row's [min, max] dB pair; a row without one plays at 0 dB.
func _db_range(row: Dictionary) -> float:
	var pair: Variant = row.get(&"volume_db")
	if pair is Array and (pair as Array).size() >= 2:
		return randf_range(
			minf(float(pair[0]), float(pair[1])), maxf(float(pair[0]), float(pair[1]))
		)
	return 0.0


## The take index a call plays: an explicit index wins (a weapon's own tier), else
## the row's mode picks - a round-robin cursor per cue, or the row's first take.
func _pool_index(cue: StringName, pool: Dictionary, take: int, count: int) -> int:
	if count <= 0:
		return 0
	if take >= 0:
		return clampi(take, 0, count - 1)
	if StringName(pool.get(&"mode", POOL_TIER)) == POOL_ROUND_ROBIN:
		var index := int(_pool_next.get(cue, 0)) % count
		_pool_next[cue] = (index + 1) % count
		return index
	return 0


## A layer the row asks for after a delay (S3's warhead at +80 ms): the caller owns
## no timer, the pool does.
func _schedule_take(take: StringName, row: Dictionary, delay: float) -> void:
	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_play_take.bind(take, row))


## AUDIO_SPEC section 6 requires a two-digit variant index, so an exact cue name
## is tried first and the "_01" convention second.
func _load_cue(bus: StringName, cue: StringName) -> AudioStream:
	var path := _cue_path(bus, cue)
	if path.is_empty():
		return null
	return load(path) as AudioStream


## The path a cue resolves to on a bus, "" when neither convention matches.
func _cue_path(bus: StringName, cue: StringName) -> String:
	var directory: String = CUE_DIRS.get(bus, "")
	if directory.is_empty() or cue == &"":
		return ""
	for candidate: String in [directory + cue + CUE_EXTENSION, directory + cue + "_01" + CUE_EXTENSION]:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


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


func _kill_loop_tween(index: int) -> void:
	if index < 0 or index >= _loop_tweens.size():
		return
	var tween := _loop_tweens[index]
	if tween != null and tween.is_valid():
		tween.kill()
	_loop_tweens[index] = null


func _service(service_name: StringName) -> Node:
	## Autoload names are not resolvable identifiers until the project patch lands
	## (project.godot is applied by the orchestrator), so services are looked up by name.
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(service_name))
