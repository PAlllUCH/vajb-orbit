@tool
extends McpTestSuite
## Suite s22_audio: wave S22's audio half, the S22-B2 subset - the quadrant feed the HUD
## pushes every status update (A5 / L241), AUDIO_SPEC section 4.1's exactly three anti-flam
## rules enforced in `play_pool` (A6 / L54, AUDIO-2), the mine's sourced CC0 deploy cue
## (A7 / L48, AUDIO-1) and `sfx_weapon_laser_04`'s drop from the laser pool (A14 / L49,
## AUDIO-3).
##
## Contract: `S22_BRIEF.md` sections 4 and 6; `docs/design/AUDIO_SPEC.md` sections 4.1 and
## 8.6 (every row owner-ticked 2026-09-29); `slices/D15-flight-feedback/D15-A1_report.md`'s
## tick sheet (AUDIO-1..3). The anti-flam floor is wall clock, so every probe that triggers
## one cue more than once spaces its own calls by the gate's own constant; the runner clears
## the gate's memory between methods (`clear_pool_history`), and this suite clears it in
## `setup` as well, so a row never reads another row's burst.
##
## One `game.tscn` is built once in `suite_setup` under a staged fixture fit (the
## `test_s22_feedback.gd` pattern), so A5 measures the real HUD the scene bound to its
## state and A7 fires a real mine through the real component. No frame is awaited (the
## runner never yields), so every reading is synchronous: `pool_rows()`, the `play_pool`
## plans and `AudioManager.last_sfx()`.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const GAME_SCENE := "res://game/game.tscn"

const LASER_CUE: StringName = &"sfx_weapon_laser"
const CANNON_CUE: StringName = &"sfx_weapon_cannon"
const ROCKET_CUE: StringName = &"sfx_weapon_rocket"
const BLAST_CUE: StringName = &"sfx_weapon_explosion"
const IMPACT_CUE: StringName = &"sfx_impact_hull"
const MINE_CUE: StringName = &"sfx_weapon_mine_drop"
const MINE_TAKES: Array[StringName] = [&"sfx_weapon_mine_drop_01", &"sfx_weapon_mine_drop_02"]
const LASER_TAKES: Array[StringName] = [
	&"sfx_weapon_laser_01", &"sfx_weapon_laser_02", &"sfx_weapon_laser_03"
]
const LASER_TAKE_04_PATH := "res://assets/audio/sfx/sfx_weapon_laser_04.ogg"
const SFX_DIR := "res://assets/audio/sfx/"

## The spec's ceiling for the S26 takes (AUDIO-1: "<= 0.5 s").
const MINE_TAKE_MAX_SECONDS := 0.5

## The fixture fit: the two families this suite fires, plus its own packs, staged on the
## profile before the scene launches (the `test_s22_feedback.gd` discipline - the account is
## restored untouched in `suite_teardown`).
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser", &"w_mine"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}
const FIXTURE_PACKS: Dictionary = {&"laser": 120, &"mine": 10}
const FIXTURE_FAMILIES: Array[StringName] = [&"laser", &"mine"]

const TARGET_OFFSET := Vector2(300.0, 0.0)

## The screen's own labels per quadrant key (`ship_status_screen.gd`'s `QUADRANT_ROWS`).
const QUADRANT_LABELS: Dictionary = {
	&"prow": "PROW",
	&"stern": "STERN",
	&"port": "PORT",
	&"starboard": "STBD",
}

var _scene: Node2D = null
var _ship: Node2D = null
var _hud: Control = null
var _state: Variant = null
var _guns: Node2D = null
var _previous_fits: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_rem: Dictionary = {}
var _pool_cursors: Dictionary = {}
var _had_pool_cursors := false


func suite_name() -> String:
	return "s22_audio"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_fixture()
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_fixture_host().add_child(_scene)
	_ship = _scene.get_node_or_null(NodePath("PlayerShip")) as Node2D
	_hud = _scene.get_node_or_null(NodePath("Hud")) as Control
	_state = _scene.get(&"_state")
	if _ship == null or _hud == null or _state == null:
		fail_setup("the game scene did not build its ship, HUD and state")
		return
	_guns = _ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	if _guns == null:
		fail_setup("the fixture fit mounted no weapon component")
		return
	_snapshot_cursors()


func suite_teardown() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_restore_cursors()
	_restore_fixture()


## Per row: the anti-flam gate's memory starts empty (its floor is wall clock and this
## runner is one frame long), the hull is whole and no trigger is held.
func setup() -> void:
	_clear_gate()
	if _scene != null:
		_scene.call(&"_cancel_lock")
	if _guns != null and is_instance_valid(_guns):
		_guns.call(&"set_firing", false)
	if _state != null:
		_state.call(&"set_hull", float(_state.hull_max))


func teardown() -> void:
	## Leave the shared autoload exactly as found: another suite's first trigger must not
	## meet this suite's clock state.
	_clear_gate()


## ---------------------------------------------------------------------------
## A5 (L241) - the HUD feeds the four real pools to the status screen
## ---------------------------------------------------------------------------


## One routed hit empties the port quadrant; the screen's rows then read the real pools
## (the breached quadrant at 0, its three peers whole) instead of the even split of the
## 3/4 hull figure the fallback would draw.
func test_a5_the_hud_pushes_the_four_pools_every_status_update() -> void:
	var quarter := float(_state.hull_max) / 4.0
	assert_true(quarter > 0.0, "the fixture hull carries a hull figure")
	## A bearing on the port flank (P2: -135..-45 degrees), so P3's stern multiplier does
	## not reach the routed amount and the hit lands exactly on the port pool.
	_state.call(&"damage", quarter, true, {&"direction": -PI / 2.0})
	assert_true(_near(float(_state.call(&"pool_of", &"port")), 0.0), "the port quadrant breached")
	var rows := _status_rows()
	assert_eq(
		String(rows.get(&"port", "")),
		"PORT 0 / %d" % int(round(quarter)),
		"the breached quadrant reads its real pool"
	)
	for key: StringName in [&"prow", &"stern", &"starboard"]:
		assert_eq(
			String(rows.get(key, "")),
			"%s %d / %d" % [QUADRANT_LABELS[key], int(round(quarter)), int(round(quarter))],
			"a whole quadrant reads its own pool"
		)
	assert_true(
		float(_state.hull) < float(_state.hull_max),
		"the even split of the hull figure would have printed a smaller share than a whole pool"
	)
	var screen: Control = _hud.call(&"status_screen")
	assert_true(screen != null, "the HUD built its status screen")
	print("[S22B2] A5 port=%s prow=%s hull=%.1f quarter=%.1f" % [
		String(rows.get(&"port", "")), String(rows.get(&"prow", "")),
		float(_state.hull), quarter,
	])


## ---------------------------------------------------------------------------
## A6 (L54) - section 4.1's three anti-flam rules, each by its own probe
## ---------------------------------------------------------------------------


## The numbers themselves: the 30 ms floor and the four per-class caps, as the spec states
## them (no other value lives anywhere).
func test_a6_the_anti_flam_numbers_are_the_specs() -> void:
	assert_eq(AudioScript.POOL_MIN_INTERVAL_MS, 30, "section 4.1's 30 ms floor")
	assert_eq(int(AudioScript.POOL_CAPS[&"weapons"]), 4, "weapons cap 4")
	assert_eq(int(AudioScript.POOL_CAPS[&"impacts"]), 6, "impacts cap 6")
	assert_eq(int(AudioScript.POOL_CAPS[&"mining"]), 1, "mining cap 1")
	assert_eq(int(AudioScript.POOL_CAPS[&"ui"]), 2, "UI cap 2")


## Rule (i): a second trigger of one cue inside 30 ms is dropped, not queued - it plays
## nothing and consumes no variant of the round-robin.
func test_a6_a_double_trigger_inside_thirty_ms_is_dropped() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var first: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_true(not first.is_empty(), "the first trigger plays")
	assert_eq(StringName(first.get(&"take", &"")), LASER_TAKES[0], "on take 01")
	var played := StringName(audio.call(&"last_sfx"))
	var second: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	var stamps: Variant = audio.get(&"_pool_last_ms")
	var gap := Time.get_ticks_msec() - int((stamps as Dictionary).get(LASER_CUE, 0))
	assert_true(gap < AudioScript.POOL_MIN_INTERVAL_MS, "the probe's gap is under the floor")
	assert_true(second.is_empty(), "the double-trigger inside the floor is dropped")
	assert_eq(StringName(audio.call(&"last_sfx")), played, "and nothing was played")
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var third: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_eq(
		StringName(third.get(&"take", &"")),
		LASER_TAKES[1],
		"the refusal consumed no variant: the next accepted trigger takes 02"
	)
	print("[S22B2] A6 double_trigger gap=%dms refused=%s next=%s" % [
		gap, str(second.is_empty()), StringName(third.get(&"take", &"")),
	])


## Rule (ii): a class at its four-voice cap refuses a fifth weapon trigger (a fresh voice);
## another class is untouched, and the cap's drop is what refused it, not rule (i).
func test_a6_a_fifth_weapon_voice_is_refused() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var cannon: Dictionary = audio.call(&"play_pool", CANNON_CUE, 0)
	assert_true(not cannon.is_empty(), "the cannon opens one long weapon voice")
	var rocket: Dictionary = audio.call(&"play_pool", ROCKET_CUE, -1)
	assert_true(not rocket.is_empty(), "the rocket a second")
	var blast: Dictionary = audio.call(&"play_pool", BLAST_CUE, -1)
	assert_true(not blast.is_empty(), "the blast a third")
	var laser: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_true(not laser.is_empty(), "the laser a fourth")
	var before := StringName(audio.call(&"last_sfx"))
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var fifth: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_true(fifth.is_empty(), "a fifth weapon-class voice is dropped at the cap")
	assert_eq(StringName(audio.call(&"last_sfx")), before, "nothing new played")
	var impact: Dictionary = audio.call(&"play_pool", IMPACT_CUE, -1)
	assert_true(not impact.is_empty(), "the manager still plays: another class is not blocked")
	var voices: Array = audio.call(&"voice_takes")
	print("[S22B2] A6 cap weapons_active=4 fifth_dropped=%s impact_plays=%s voices=%d" % [
		str(fifth.is_empty()), str(not impact.is_empty()), voices.size(),
	])


## Rule (iii): a round-robin pick skips the last used variant when the pool holds more than
## two takes. The probe leaves the cursor pointing at the just-played take via an explicit
## tier read, so the next round-robin call would repeat it without the skip.
func test_a6_the_round_robin_skips_the_last_used_variant() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var first: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_eq(StringName(first.get(&"take", &"")), LASER_TAKES[0], "the cycle opens on 01")
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var tier: Dictionary = audio.call(&"play_pool", LASER_CUE, 1)
	assert_eq(StringName(tier.get(&"take", &"")), LASER_TAKES[1], "an explicit tier plays 02")
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var skipped: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	assert_eq(
		StringName(skipped.get(&"take", &"")),
		LASER_TAKES[2],
		"the next round-robin read skips the last used 02 and takes 03"
	)
	print("[S22B2] A6 skip_last first=%s tier=%s next=%s" % [
		StringName(first.get(&"take", &"")), StringName(tier.get(&"take", &"")),
		StringName(skipped.get(&"take", &"")),
	])


## ---------------------------------------------------------------------------
## A7 (L48) - the mine's sourced CC0 deploy cue
## ---------------------------------------------------------------------------


## AUDIO-1's S26 row, end to end: the cue name wired in `FIRE_CUES`, the pooled takes that
## resolve and sit under the 0.5 s ceiling, the detonation's unchanged explosion cue, and a
## real mine release through the real component playing the sourced take.
func test_a7_the_mine_release_plays_the_sourced_deploy_cue() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_eq(
		WeaponScript.fire_cue_of(&"mine"),
		MINE_CUE,
		"AUDIO-1: the mine family's release cue is S26"
	)
	var takes: Array = AudioScript.CUE_POOLS[MINE_CUE][&"takes"]
	assert_eq(takes, MINE_TAKES as Array, "the sourced takes are pooled in order")
	for take: StringName in MINE_TAKES:
		var path := SFX_DIR + String(take) + ".ogg"
		assert_true(ResourceLoader.exists(path), "the take resolves (%s)" % path)
		var stream := load(path) as AudioStream
		if stream == null:
			continue
		assert_true(
			stream.get_length() <= MINE_TAKE_MAX_SECONDS,
			"AUDIO-1's ceiling: %s is %.3f s" % [String(take), stream.get_length()]
		)
	assert_eq(
		ProjectileScript.BLAST_CUE,
		&"sfx_weapon_explosion",
		"the detonation keeps S3's explosion cue (AUDIO-1)"
	)
	_fire_mine()
	var played := StringName(audio.call(&"last_sfx"))
	assert_true(
		MINE_TAKES.has(played),
		"the mine's release plays a sourced take (played %s)" % played
	)
	var lengths: Array[float] = []
	for take: StringName in MINE_TAKES:
		var stream := load(SFX_DIR + String(take) + ".ogg") as AudioStream
		lengths.append(stream.get_length() if stream != null else -1.0)
	print("[S22B2] A7 cue=%s played=%s seconds=%s" % [MINE_CUE, played, str(lengths)])


## ---------------------------------------------------------------------------
## A14 (L49) - take 04 drops from the laser pool; the file stays staged
## ---------------------------------------------------------------------------


## The pool's take list is 01-03 (the drop is a pool member, not an asset delete), the
## round-robin runs the three in order and starts over, and no take repeats itself.
func test_a14_the_laser_pool_runs_three_takes_and_04_stays_staged() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var takes: Array = AudioScript.CUE_POOLS[LASER_CUE][&"takes"]
	assert_eq(takes, LASER_TAKES as Array, "AUDIO-3: the round-robin runs 01-03")
	assert_eq(StringName(AudioScript.CUE_POOLS[LASER_CUE][&"mode"]), &"round_robin", "it cycles")
	assert_true(
		ResourceLoader.exists(LASER_TAKE_04_PATH),
		"take 04's file stays on disk (the 0.06-0.09 s trim stays staged)"
	)
	var cycle: Array[StringName] = []
	for index in 4:
		OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
		var plan: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
		if plan.is_empty():
			assert_true(false, "cycle read %d resolved" % index)
			return
		cycle.append(StringName(plan[&"take"]))
	assert_eq(cycle, [LASER_TAKES[0], LASER_TAKES[1], LASER_TAKES[2], LASER_TAKES[0]],
		"the cycle 01, 02, 03, 01: skip-last still applies at N = 3")
	for index in range(1, cycle.size()):
		assert_true(cycle[index] != cycle[index - 1], "no take repeats itself")
	print("[S22B2] A14 cycle=%s take_04_staged=%s" % [
		str(cycle), str(ResourceLoader.exists(LASER_TAKE_04_PATH)),
	])


## ---------------------------------------------------------------------------
## Fixtures and readers
## ---------------------------------------------------------------------------


## One real mine release on the shipped component: the fixture's own mine, aimed abeam and
## released once (the `test_s22_feedback.gd` `_fire_cannon` pattern).
func _fire_mine() -> void:
	var ids: Array[StringName] = [&"w_mine"]
	_guns.call(&"set_fitted", ids)
	_guns.call(&"set_batteries", [])
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + TARGET_OFFSET)
	var slot := int((_state.weapons as Array).find(&"mine"))
	assert_true(slot >= 0, "the fixture fit carries the mine")
	if slot >= 0 and slot < (_state.ammo as Array).size():
		_state.call(&"set_ammo", slot, 5)
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)


## The status screen's four rows as `key -> text`.
func _status_rows() -> Dictionary:
	var out: Dictionary = {}
	var screen: Control = _hud.call(&"status_screen")
	if screen == null:
		return out
	for row: Dictionary in screen.call(&"pool_rows"):
		out[row[&"key"]] = row[&"text"]
	return out


## The anti-flam memory, cleared (the runner does the same between methods).
func _clear_gate() -> void:
	var audio := _audio()
	if audio == null:
		return
	if audio.has_method(&"clear_pool_history"):
		audio.call(&"clear_pool_history")
	var cursors: Variant = audio.get(&"_pool_next")
	if cursors is Dictionary:
		(cursors as Dictionary).clear()


func _snapshot_cursors() -> void:
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_cursors = true
	_pool_cursors = (cursors as Dictionary).duplicate()


func _restore_cursors() -> void:
	if not _had_pool_cursors:
		return
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_cursors, true)
	_pool_cursors = {}
	_had_pool_cursors = false


func _audio() -> Node:
	return _tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _profile() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


func _near(a: float, b: float, epsilon: float = 0.001) -> bool:
	return absf(a - b) <= epsilon


## The fixture's fit and packs, written before the scene is instantiated and handed back in
## `suite_teardown`, so the account ends this suite exactly as it started.
func _stage_fixture() -> void:
	var profile := _profile()
	if profile == null:
		return
	_previous_fits = profile.call(&"fits")
	_previous_ammo = (profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_rem = (profile.get(&"_ammo_rem") as Dictionary).duplicate(true)
	profile.call(&"set_fit", StringName(profile.call(&"active_ship")), FIXTURE_FIT)
	var packs: Dictionary = _previous_ammo.duplicate(true)
	var cargo: Dictionary = _previous_cargo.duplicate(true)
	var rem: Dictionary = _previous_rem.duplicate(true)
	for family: StringName in FIXTURE_FAMILIES:
		packs[family] = int(FIXTURE_PACKS[family])
		rem.erase(family)
		cargo.erase(family)
		var item_id := StringName(profile.call(&"ammo_item_id", family))
		if item_id != &"":
			cargo.erase(item_id)
	profile.set(&"_ammo", packs)
	profile.set(&"_cargo", cargo)
	profile.set(&"_ammo_rem", rem)
	profile.call(&"flush")


func _restore_fixture() -> void:
	var profile := _profile()
	if profile == null:
		return
	profile.call(&"set_fits", _previous_fits)
	profile.set(&"_ammo", _previous_ammo)
	profile.set(&"_cargo", _previous_cargo)
	profile.set(&"_ammo_rem", _previous_rem)
	profile.call(&"flush")
	_previous_fits = {}
	_previous_ammo = {}
	_previous_cargo = {}
	_previous_rem = {}


## Where the scene may enter the tree (the runner's own `_ready` has `/root` busy).
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root
