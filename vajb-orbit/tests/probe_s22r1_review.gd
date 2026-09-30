extends Node
## S22-R1's independent re-measurement (the W8/S19-R1 method: the reviewer re-derives every
## number from the code and the ticked sheet, never from a builder's report or its suite).
## Bounded, self-quitting, scratch store only (L229/T-93):
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
##     res://tests/probe_s22r1_review.tscn --quit-after 600
##
## Prints `[S22R1]` lines and exits 0 when every check holds, 1 otherwise. It mounts no
## station; the game scene it builds lives on the scratch profile only.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const RepairsScript := preload("res://game/repairs.gd")
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
const ModuleCatalogScript := preload("res://game/module_catalog.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const TAG := "[S22R1]"
const HULL: StringName = &"ship_vanguard"
const LASER_CUE: StringName = &"sfx_weapon_laser"
const MINE_CUE: StringName = &"sfx_weapon_mine_drop"
const IMPACT_CUE: StringName = &"sfx_impact_hull"
const EPSILON := 0.001

class StubHull:
	extends Node2D
	var damage_taken := 0.0
	var hits := 0

	func take_damage(amount: float, _bypass: bool) -> void:
		damage_taken += amount
		hits += 1

var _checks := 0
var _fails: Array[String] = []
var _died_count := 0


func _ready() -> void:
	print("%s probe start engine=%s xdg=%s" % [
		TAG, Engine.get_version_info()["string"], OS.get_environment("XDG_DATA_HOME")
	])
	var xdg := OS.get_environment("XDG_DATA_HOME")
	if xdg == "":
		_fails.append("scratch_store")
		print("%s FAIL scratch store missing - refusing to touch the live account (T-93)" % TAG)
		_summary()
		return
	var profile := _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile != null:
		profile.set(&"save_path", "user://probe_s22r1_profile.cfg")
	_static_checks()
	_spill_checks()
	_fuze_checks()
	_audio_checks()
	_ship_checks()
	_scene_checks()
	_repairs_checks()
	_summary()


func _summary() -> void:
	print("%s summary checks=%d fails=%d %s" % [TAG, _checks, _fails.size(), str(_fails)])
	get_tree().quit(1 if not _fails.is_empty() else 0)


func _check(name: String, ok: bool, evidence: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(name)
	print("%s %s %s - %s" % [TAG, "PASS" if ok else "FAIL", name, evidence])


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _host() -> Node:
	var root := _tree().root
	var fixture := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return fixture if fixture != null else root


func _sha256(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(file.get_buffer(file.get_length()))
	return ctx.finish().hex_encode()


func _source(path: String) -> String:
	var script := load(path) as GDScript
	return script.source_code if script != null else ""


## ------------------------------------------------------------------ static / seal


func _static_checks() -> void:
	var pins: Dictionary = (load("res://tests/test_s19_quadrants.gd") as GDScript).get_script_constant_map().get(
		"FORBIDDEN_FILES", {}
	)
	var matched := 0
	var lines: Array[String] = []
	for path: String in pins:
		var local_path := path.replace("res://", "res://")
		var digest := _sha256(local_path)
		lines.append("%s=%s" % [path.get_file(), digest.substr(0, 8)])
		if digest == String(pins[path]):
			matched += 1
	_check(
		"seal_hashes",
		matched == pins.size() and not pins.is_empty(),
		"%d/%d pins equal the finished tree [%s]" % [matched, pins.size(), ", ".join(lines)]
	)
	var game_src := _source("res://game/game.gd")
	var hud_src := _source("res://ui/hud/hud.gd")
	var guns_src := _source("res://game/weapons.gd")
	_check(
		"poll_retired",
		not game_src.contains("pools_seen") and hud_src.contains("set_quadrants(")
			and hud_src.contains("hit_landed"),
		"game.gd pools_seen=%s; hud.gd pushes set_quadrants=%s, consumes hit_landed=%s" % [
			str(game_src.contains("pools_seen")),
			str(hud_src.contains("set_quadrants(")),
			str(hud_src.contains("hit_landed")),
		]
	)
	_check(
		"spawn_pin",
		guns_src.contains("shot.global_position = muzzle_position(barrel)"),
		"the shot's spawn line is still muzzle_position(barrel) (A3 rule 1)"
	)
	_check(
		"fuse_consts",
		is_equal_approx(ProjectileScript.SEEKER_FUSE, 80.0)
			and is_equal_approx(ProjectileScript.SEEKER_FUSE_S, 6.0),
		"SEEKER_FUSE=%.1f SEEKER_FUSE_S=%.1f" % [
			ProjectileScript.SEEKER_FUSE, ProjectileScript.SEEKER_FUSE_S
		]
	)
	var ship_script := load("res://game/player_ship.gd") as GDScript
	_check(
		"arc_consts",
		is_equal_approx(float(ship_script.get_script_constant_map().get("ARC_INTERVAL_MIN", 0.0)), 1.6)
			and is_equal_approx(float(ship_script.get_script_constant_map().get("ARC_INTERVAL_MAX", 0.0)), 2.6),
		"ARC_INTERVAL_MIN=%.1f MAX=%.1f seed=%s" % [
			float(ship_script.get_script_constant_map().get("ARC_INTERVAL_MIN", 0.0)),
			float(ship_script.get_script_constant_map().get("ARC_INTERVAL_MAX", 0.0)),
			str(ship_script.get_script_constant_map().get("ARC_SEED", -1)),
		]
	)
	var fx_ok := true
	var fx_evidence: Array[String] = []
	var trail: Dictionary = ProjectileScript.SHEETS[&"rocket"]
	fx_ok = fx_ok and float(trail[&"fps"]) == 12.0 and bool(trail[&"loop"])
	fx_ok = fx_ok and float(trail[&"world"]) == 48.0
	fx_evidence.append("trail=%.0f/%s/%.0f" % [float(trail[&"fps"]), str(trail[&"loop"]), float(trail[&"world"])])
	fx_ok = fx_ok and float(ProjectileScript.SHEETS[&"mine"][&"world"]) == 22.0
	fx_evidence.append("mine=%.0f" % float(ProjectileScript.SHEETS[&"mine"][&"world"]))
	fx_ok = fx_ok and ProjectileScript.PLUME_AMOUNT == 16 and ProjectileScript.PLUME_LIFETIME == 1.4
	fx_ok = fx_ok and ProjectileScript.PLUME_PREPROCESS == 0.6 and ProjectileScript.PLUME_RADIUS == 14.0
	fx_ok = fx_ok and ProjectileScript.PLUME_SPREAD == 25.0
	fx_ok = fx_ok and ProjectileScript.PLUME_SPEED_MIN == 8.0 and ProjectileScript.PLUME_SPEED_MAX == 24.0
	fx_ok = fx_ok and ProjectileScript.PLUME_SCALE_MIN == 0.5 and ProjectileScript.PLUME_SCALE_MAX == 1.1
	fx_evidence.append("plume=%d/%.1f/%.1f/%.0f/%.0f/%.0f-%.0f/%.1f-%.1f" % [
		ProjectileScript.PLUME_AMOUNT, ProjectileScript.PLUME_LIFETIME,
		ProjectileScript.PLUME_PREPROCESS, ProjectileScript.PLUME_RADIUS,
		ProjectileScript.PLUME_SPREAD, ProjectileScript.PLUME_SPEED_MIN,
		ProjectileScript.PLUME_SPEED_MAX, ProjectileScript.PLUME_SCALE_MIN,
		ProjectileScript.PLUME_SCALE_MAX,
	])
	fx_ok = fx_ok and float(ProjectileScript.FEEDBACK[&"chip"][&"world"]) == 40.0
	fx_ok = fx_ok and float(ProjectileScript.FEEDBACK[&"arc"][&"world"]) == 40.0
	fx_ok = fx_ok and float(ProjectileScript.FEEDBACK[&"chip"][&"fps"]) == 20.0
	fx_ok = fx_ok and (ProjectileScript.FEEDBACK[&"chip"][&"frames"] as Array).size() == 4
	fx_evidence.append("chip=%.0f@%.0f/f%d arc=%.0f" % [
		float(ProjectileScript.FEEDBACK[&"chip"][&"world"]),
		float(ProjectileScript.FEEDBACK[&"chip"][&"fps"]),
		(ProjectileScript.FEEDBACK[&"chip"][&"frames"] as Array).size(),
		float(ProjectileScript.FEEDBACK[&"arc"][&"world"]),
	])
	fx_ok = fx_ok and float(ProjectileScript.SHEETS[&"bolt"][&"world"]) == 64.0
	fx_ok = fx_ok and float(ProjectileScript.SHEETS[&"slug"][&"world"]) == 96.0
	fx_evidence.append("bolt=%.0f slug=%.0f" % [
		float(ProjectileScript.SHEETS[&"bolt"][&"world"]),
		float(ProjectileScript.SHEETS[&"slug"][&"world"]),
	])
	_check("fx_pins", fx_ok, " ".join(fx_evidence))
	_check(
		"audio_consts",
		AudioScript.POOL_MIN_INTERVAL_MS == 30 and int(AudioScript.POOL_CAPS[&"weapons"]) == 4
			and int(AudioScript.POOL_CAPS[&"impacts"]) == 6
			and int(AudioScript.POOL_CAPS[&"mining"]) == 1
			and int(AudioScript.POOL_CAPS[&"ui"]) == 2,
		"floor=%d caps=%s" % [AudioScript.POOL_MIN_INTERVAL_MS, str(AudioScript.POOL_CAPS)]
	)


## ------------------------------------------------------------------ spill


func _spill_checks() -> void:
	var state := PlayerStateScript.new()
	state.hull_max = 500.0
	state.shield_max = 0.0
	state.setup()
	state.set(&"armour_prow", 40.0)
	state.set(&"armour_stern", 120.0)
	state.set(&"armour_port", 0.0)
	state.set(&"armour_starboard", 140.0)
	state.set(&"hull", 300.0)
	state.set_shield(0.0)
	state.damage(150.0, true, {PlayerStateScript.CTX_DIRECTION: -PI / 2.0})
	var sum := (
		state.pool_of(&"prow") + state.pool_of(&"stern")
		+ state.pool_of(&"port") + state.pool_of(&"starboard")
	)
	var proportional := (
		is_equal_approx(state.pool_of(&"prow"), 20.0)
		and is_equal_approx(state.pool_of(&"stern"), 60.0)
		and is_equal_approx(state.pool_of(&"starboard"), 70.0)
		and is_equal_approx(state.pool_of(&"port"), 0.0)
	)
	_check(
		"spill_prop",
		proportional and is_equal_approx(state.hull, 150.0) and is_equal_approx(sum, state.hull),
		"150 on [40,120,0,140] -> [%.1f,%.1f,%.1f,%.1f] hull=%.1f sum=%.6f" % [
			state.pool_of(&"prow"), state.pool_of(&"stern"), state.pool_of(&"port"),
			state.pool_of(&"starboard"), state.hull, sum,
		]
	)
	_died_count = 0
	var doomed := PlayerStateScript.new()
	doomed.hull_max = 100.0
	doomed.shield_max = 0.0
	doomed.setup()
	doomed.set(&"armour_prow", 50.0)
	doomed.set(&"armour_stern", 50.0)
	doomed.set(&"armour_port", 0.0)
	doomed.set(&"armour_starboard", 0.0)
	doomed.set(&"hull", 100.0)
	doomed.set_shield(0.0)
	doomed.died.connect(func() -> void: _died_count += 1)
	doomed.damage(600.0, true, {PlayerStateScript.CTX_DIRECTION: 0.0})
	var doomed_sum := (
		doomed.pool_of(&"prow") + doomed.pool_of(&"stern")
		+ doomed.pool_of(&"port") + doomed.pool_of(&"starboard")
	)
	_check(
		"spill_conserve",
		is_equal_approx(doomed.hull, 0.0) and _died_count == 1
			and is_equal_approx(doomed_sum, doomed.hull),
		"600 on [50,50,0,0]: hull=%.1f died=%d sum=%.6f" % [doomed.hull, _died_count, doomed_sum]
	)


## ------------------------------------------------------------------ seeker fuze


func _rocket(lock: Node2D) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "ProbeRocket"
	shot.call(&"configure", {
		&"kind": &"rocket",
		&"speed": 900.0,
		&"damage": 180.0,
		&"bypass_shield": true,
		&"homing": true,
		&"turn_rate": 0.0,
		&"range": 0.0,
		&"direction": Vector2.RIGHT,
		&"target": lock,
	})
	_host().add_child(shot)
	shot.global_position = Vector2.ZERO
	return shot


func _fuze_checks() -> void:
	var near := StubHull.new()
	near.name = "ProbeNearLock"
	_host().add_child(near)
	near.global_position = Vector2(70.0, 0.0)
	var shot := _rocket(near)
	var fired := bool(shot.call(&"_step_seeker_fuze", 0.016))
	_check(
		"fuze_proxy",
		fired and is_equal_approx(near.damage_taken, 180.0),
		"lock 70 u: detonated=%s damage=%.0f" % [str(fired), near.damage_taken]
	)
	shot.free()
	near.free()
	var dumb := _rocket(null)
	for _step: int in 13:
		dumb.call(&"_physics_process", 0.5)
	_check(
		"fuze_dumb",
		not bool(dumb.get(&"_spent")) and is_zero_approx(float(dumb.get(&"_flight_clock"))),
		"no lock: spent=%s clock=%.2f" % [str(dumb.get(&"_spent")), float(dumb.get(&"_flight_clock"))]
	)
	dumb.free()
	## The expiry door with a lock it cannot reach (abeam, no turn): if the shot still
	## lands 180 on the lock from thousands of units away, the delivery carries no
	## distance gate - the reading B3 tabulated for the owner.
	var far := StubHull.new()
	far.name = "ProbeFarLock"
	_host().add_child(far)
	far.global_position = Vector2(0.0, 500.0)
	var orbit := _rocket(far)
	var last_distance := 0.0
	for _step: int in 25:
		orbit.call(&"_physics_process", 0.25)
		last_distance = orbit.global_position.distance_to(far.global_position)
	_check(
		"fuze_expiry",
		bool(orbit.get(&"_spent")) and is_equal_approx(far.damage_taken, 180.0)
			and float(orbit.get(&"_flight_clock")) >= 6.0,
		"6 s fuze: spent=%s clock=%.2f damage=%.0f distance_at_expiry=%.0f u" % [
			str(orbit.get(&"_spent")), float(orbit.get(&"_flight_clock")),
			far.damage_taken, last_distance,
		]
	)
	orbit.free()
	far.free()


## ------------------------------------------------------------------ audio


func _audio() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"AudioManager"))


func _clear_audio() -> Node:
	var audio := _audio()
	if audio == null:
		return null
	audio.call(&"clear_pool_history")
	var cursors: Variant = audio.get(&"_pool_next")
	if cursors is Dictionary:
		(cursors as Dictionary).clear()
	return audio


func _audio_checks() -> void:
	var audio := _audio()
	if audio == null:
		_check("audio_service", false, "no AudioManager autoload")
		return
	var mine_cue := WeaponScript.fire_cue_of(&"mine")
	var takes: Array = AudioScript.CUE_POOLS.get(MINE_CUE, {}).get(&"takes", [])
	var lengths: Array[String] = []
	var under_ceiling := takes.size() == 2
	for take: StringName in takes:
		var stream := load("res://assets/audio/sfx/%s.ogg" % String(take)) as AudioStream
		var length := stream.get_length() if stream != null else -1.0
		lengths.append("%.3f" % length)
		under_ceiling = under_ceiling and length > 0.0 and length <= 0.5
	_check(
		"mine_pool",
		mine_cue == MINE_CUE and under_ceiling and ProjectileScript.BLAST_CUE == &"sfx_weapon_explosion",
		"FIRE_CUES[mine]=%s takes=%s lengths=%s blast=%s" % [
			str(mine_cue), str(takes), str(lengths), str(ProjectileScript.BLAST_CUE)
		]
	)
	var log_text := FileAccess.get_file_as_string("res://assets/audio/generation_log_audio.md")
	var workspace := OS.get_environment("VAJB_WORKSPACE")
	var manifest_text := FileAccess.get_file_as_string(
		workspace.path_join("asset-library/ASSET_MANIFEST.json")
	)
	var credits_text := FileAccess.get_file_as_string(
		workspace.path_join("asset-library/CREDITS.md")
	)
	_check(
		"mine_provenance",
		log_text.contains("sfx_weapon_mine_drop_01.ogg") and log_text.contains("qubodup")
			and log_text.contains("CC0")
			and manifest_text.contains("allowed_public_domain")
			and manifest_text.contains("7-mechanical-clicks-and-buzzes")
			and credits_text.contains("No attribution-required"),
		"gen log rows=%s manifest=%s credits=%s" % [
			str(log_text.contains("sfx_weapon_mine_drop_01.ogg")),
			str(manifest_text.contains("allowed_public_domain")),
			str(credits_text.contains("No attribution-required")),
		]
	)
	var laser_takes: Array = AudioScript.CUE_POOLS[LASER_CUE][&"takes"]
	_check(
		"laser_pool",
		laser_takes == [&"sfx_weapon_laser_01", &"sfx_weapon_laser_02", &"sfx_weapon_laser_03"]
			and FileAccess.file_exists("res://assets/audio/sfx/sfx_weapon_laser_04.ogg"),
		"takes=%s 04_staged=%s" % [
			str(laser_takes), str(FileAccess.file_exists("res://assets/audio/sfx/sfx_weapon_laser_04.ogg"))
		]
	)
	## Rule (i): a double trigger inside the floor is dropped and consumes no variant.
	audio = _clear_audio()
	var first: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	var second: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var third: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	_check(
		"antiflam_floor",
		not first.is_empty() and second.is_empty() and not third.is_empty()
			and StringName(third.get(&"take", &"")) == &"sfx_weapon_laser_02",
		"first=%s double=%s next=%s" % [
			str(first.get(&"take", &"")), str(second.is_empty()), str(third.get(&"take", &""))
		]
	)
	## The floor's own threshold: a 20 ms gap is inside the 30 ms window and refused;
	## the next accepted trigger (35 ms) takes the variant the refusal did not consume.
	audio = _clear_audio()
	var stamp_plan: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	OS.delay_msec(20)
	var twenty: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	OS.delay_msec(15)
	var thirty_five: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	_check(
		"antiflam_20ms",
		StringName(stamp_plan.get(&"take", &"")) == &"sfx_weapon_laser_01" and twenty.is_empty()
			and StringName(thirty_five.get(&"take", &"")) == &"sfx_weapon_laser_02",
		"20 ms refused=%s; 35 ms takes=%s" % [
			str(twenty.is_empty()), str(thirty_five.get(&"take", &""))
		]
	)
	## Rule (ii): four weapons voices open, the fifth refused; another class untouched.
	audio = _clear_audio()
	var voices := 0
	for play: Array in [
		[&"sfx_weapon_cannon", 0], [&"sfx_weapon_rocket", -1],
		[&"sfx_weapon_explosion", -1], [LASER_CUE, -1],
	]:
		var plan: Dictionary = audio.call(&"play_pool", play[0], play[1])
		if not plan.is_empty():
			voices += 1
	var active := int(audio.call(&"_active_class_voices", &"weapons", Time.get_ticks_msec()))
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var fifth: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	var impact: Dictionary = audio.call(&"play_pool", IMPACT_CUE, -1)
	_check(
		"antiflam_cap",
		voices == 4 and active == 4 and fifth.is_empty() and not impact.is_empty(),
		"played=%d active=%d fifth=%s impact=%s" % [
			voices, active, str(fifth.is_empty()), str(not impact.is_empty())
		]
	)
	## Rule (iii): the round-robin skips the last used variant at N = 3.
	audio = _clear_audio()
	var open_plan: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var tier: Dictionary = audio.call(&"play_pool", LASER_CUE, 1)
	OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
	var skipped: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
	_check(
		"antiflam_skip",
		StringName(open_plan.get(&"take", &"")) == &"sfx_weapon_laser_01"
			and StringName(tier.get(&"take", &"")) == &"sfx_weapon_laser_02"
			and StringName(skipped.get(&"take", &"")) == &"sfx_weapon_laser_03",
		"01 -> explicit 02 -> round-robin %s" % str(skipped.get(&"take", &""))
	)
	## A14's cycle over the three-take pool.
	audio = _clear_audio()
	var cycle: Array[StringName] = []
	for _index: int in 4:
		OS.delay_msec(AudioScript.POOL_MIN_INTERVAL_MS + 5)
		var plan: Dictionary = audio.call(&"play_pool", LASER_CUE, -1)
		cycle.append(StringName(plan.get(&"take", &"")))
	_check(
		"a14_cycle",
		cycle == [
			&"sfx_weapon_laser_01", &"sfx_weapon_laser_02", &"sfx_weapon_laser_03",
			&"sfx_weapon_laser_01",
		],
		"cycle=%s" % str(cycle)
	)


## ------------------------------------------------------------------ the hull seams


func _launch_ship() -> Array:
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	if stats == null:
		return [null, null]
	var state: PlayerState = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	_host().add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.call(&"set_hull_id", HULL)
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	ship.call(&"set_aim_point", Vector2.ZERO)
	return [ship, state]


func _ship_checks() -> void:
	var pair := _launch_ship()
	var ship: Node2D = pair[0]
	var state: PlayerState = pair[1]
	if ship == null:
		_check("ship_fixture", false, "the Vanguard fixture did not build")
		return
	## A3: the nose is the `ShipFit` bow band's average, scaled as the mounts are.
	var front := ShipFitScript.thruster_points(HULL, &"front")
	var expected := Vector2.ZERO
	for point: Vector2 in front:
		expected += point
	expected = (expected / float(front.size())) * ship.call(&"_hull_sprite_scale")
	var nose: Vector2 = ship.call(&"nose_point")
	_check(
		"nose_point",
		front.size() > 0 and nose.distance_to(expected) < EPSILON and nose.x > 5.0,
		"thruster_points=%d average*scale=(%.2f,%.2f) nose_point=(%.2f,%.2f)" % [
			front.size(), expected.x, expected.y, nose.x, nose.y
		]
	)
	## A2's geometry: the contact point is the hull's own surface on the pair's line.
	var peer := ship.global_position + Vector2(100.0, 0.0)
	var contact: Vector2 = ship.call(&"_contact_point", peer)
	var radius := float(ship.call(&"_hull_radius"))
	_check(
		"contact_point",
		radius > 0.0 and contact.distance_to(ship.global_position + Vector2(radius, 0.0)) < EPSILON
			and contact.distance_to((ship.global_position + peer) * 0.5) > 1.0,
		"radius=%.2f contact=(%.2f,%.2f) not_midpoint=%s" % [
			radius, contact.x, contact.y,
			str(contact.distance_to((ship.global_position + peer) * 0.5) > 1.0),
		]
	)
	## A3's anchor on the real component: the flash's mouth lands on the nose converted
	## into the component's frame, and the shot's spawn is `muzzle_position` still.
	var guns := WeaponScript.new() as Node2D
	guns.name = "ProbeGuns"
	ship.add_child(guns)
	var anchor: Vector2 = guns.call(&"_flash_anchor")
	var want: Vector2 = guns.to_local(ship.to_global(nose))
	var spawn: Vector2 = guns.call(&"muzzle_position", 0)
	_check(
		"flash_anchor",
		anchor.distance_to(want) < 0.01 and spawn.distance_to(anchor) > 1.0,
		"anchor=(%.2f,%.2f) nose_local=(%.2f,%.2f) muzzle=(%.2f,%.2f) desync=%s" % [
			anchor.x, anchor.y, want.x, want.y, spawn.x, spawn.y,
			str(spawn.distance_to(anchor) > 1.0),
		]
	)
	## A8: the live cadence, four expiries, every draw inside the ticked band.
	state.set_hull(state.hull_max * 0.20)
	ship.set(&"_arc_clock", 0.0)
	ship.set(&"_arc_next", 0.0)
	ship.set(&"_arc_count", 0)
	var draws: Array[float] = []
	for _step: int in 4:
		ship.call(&"_update_damage_arcs", 3.0)
		draws.append(float(ship.call(&"arc_interval")))
	_check(
		"arcs",
		int(ship.call(&"arc_count")) == 4 and draws.size() == 4
			and not is_equal_approx(draws[0], draws[draws.size() - 1]),
		"count=%d draws=%s" % [int(ship.call(&"arc_count")), str(draws)]
	)
	ship.free()


## ------------------------------------------------------------------ HUD scene


func _scene_checks() -> void:
	var game: Node2D = GameScene.instantiate() as Node2D
	_host().add_child(game)
	var hud: Control = game.get_node_or_null(NodePath("Hud")) as Control
	var state: Variant = game.get(&"_state")
	if hud == null or state == null:
		_check("game_fixture", false, "game.tscn built no HUD/state")
		return
	var ship: Node2D = game.get_node_or_null(NodePath("PlayerShip")) as Node2D
	_check(
		"game_fixture",
		ship != null,
		"HUD and state built on the scratch profile"
	)
	## A1's seam end to end: the live component's one signal reports an unmarked stub
	## hull's landing with its amount, and the HUD's marker flashes for it.
	if ship != null:
		var guns: Node = ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
		var marker: Control = hud.call(&"hit_marker_node")
		var stub := StubHull.new()
		stub.name = "ProbeUnmarkedHull"
		_host().add_child(stub)
		stub.global_position = ship.global_position + Vector2(120.0, 0.0)
		var seen: Array = []
		if guns != null and marker != null:
			guns.hit_landed.connect(
				func(target: Object, amount: float) -> void: seen.append([target, amount])
			)
			marker.visible = false
			guns.call(
				&"_deliver", stub, 10.0, false, stub.global_position, &"laser", Vector2.ZERO
			)
		_check(
			"hit_landed_seam",
			guns != null and marker != null and seen.size() == 1 and seen[0][0] == stub
				and float(seen[0][1]) == 10.0 and marker.visible,
			"signal deliveries=%d names_stub=%s marker=%s" % [
				seen.size(), str(seen.size() == 1 and seen[0][0] == stub),
				str(marker != null and marker.visible),
			]
		)
		stub.free()
	## A5: a real breach on the starboard flank reaches the screen's rows.
	var quarter := float(state.hull_max) / 4.0
	state.call(&"damage", quarter, true, {&"direction": PI / 2.0})
	var rows: Dictionary = {}
	var screen: Control = hud.call(&"status_screen")
	if screen != null:
		for row: Dictionary in screen.call(&"pool_rows"):
			rows[row[&"key"]] = String(row[&"text"])
	_check(
		"quadrant_feed",
		String(rows.get(&"starboard", "")) == "STBD 0 / %d" % int(round(quarter))
			and String(rows.get(&"prow", "")) == "PROW %d / %d" % [int(round(quarter)), int(round(quarter))]
			and float(state.hull) < float(state.hull_max),
		"starboard=%s prow=%s hull=%.1f quarter=%.1f" % [
			String(rows.get(&"starboard", "")), String(rows.get(&"prow", "")),
			float(state.hull), quarter,
		]
	)
	## A12: the tool slot reads its `ModuleCatalog` name; a family keeps the family label.
	hud.call(&"set_hull_slots", HULL, [
		{&"slot": &"weapons", &"index": 0, &"module": &"w_laser", &"battery": 1, &"position": 0},
		{&"slot": &"weapons", &"index": 1, &"module": &"w_mining", &"battery": 2, &"position": 1},
	])
	hud.call(&"_on_weapon_changed", 1, &"", 0, 0)
	var label := hud.get(&"_ammo_label") as Label
	var tool_name := String(ModuleCatalogScript.module(&"w_mining").get(&"name", ""))
	hud.call(&"_on_weapon_changed", 0, &"laser", 12, 120)
	var family := label.text if label != null else ""
	_check(
		"module_label",
		label != null and tool_name == "Mining Laser" and family.begins_with("Laser MkII"),
		"catalogue=%s family_label=%s" % [tool_name, family]
	)
	game.free()


## ------------------------------------------------------------------ repairs


func _repairs_checks() -> void:
	var profile := ProfileScript.new()
	profile.set(&"save_path", "user://probe_s22r1_profile_check.cfg")
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var expected_hull := int(round(stats.hull_max))
	var expected_shield := int(round(stats.shield_max))
	profile.call(&"set_vitals", HULL, 300, 400)
	var missing_hull := expected_hull - 300
	var missing_shield := expected_shield - 400
	var expected_fee := ceili(float(missing_hull) / 2.0) + ceili(float(missing_shield) / 3.0)
	var fee := int(RepairsScript.fee(profile, HULL))
	var service: Dictionary = RepairsScript._maxima(profile, HULL)
	var pane: Control = RepairsPanelScript.new()
	var printed: Dictionary = pane.call(&"_pool_maxima", profile, HULL)
	pane.free()
	var transaction: Dictionary = RepairsScript.repair(profile, HULL)
	_check(
		"fee_pair",
		fee == expected_fee and int(service[&"hull"]) == expected_hull
			and int(service[&"shield"]) == expected_shield and printed == service
			and int(transaction.get(&"hull_max", 0)) == expected_hull
			and int(transaction.get(&"shield_max", 0)) == expected_shield
			and int(transaction.get(&"fee", 0)) == expected_fee,
		"resolved=%d/%d missing=%d/%d fee=%d (service %d, pane %s)" % [
			expected_hull, expected_shield, missing_hull, missing_shield, fee,
			int(service[&"hull"]), str(printed == service),
		]
	)
	profile.free()
