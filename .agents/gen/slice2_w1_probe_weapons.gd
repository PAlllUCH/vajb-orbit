## Archived copy of the slice-2 W1 probe (tools/_probe_s2w1_weapons.gd, deleted
## from the project before the report). To re-run it, copy this file to
## `vajb-orbit/tools/` (the brief keeps tools/ holding only build_theme.gd and
## derive_icon_tints.gd) and:
##
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
##   --script res://tools/_probe_s2w1_weapons.gd --quit-after 20000
##
## Result line of the archived run (see _s2w1_probe_weapons.txt): [SUMMARY]
## ok=95 failed=0 blocked=0, exit 0.
##
extends SceneTree
## slice-2 W1 probe: the weapon families (ENGINE_SPEC 4.1), the energy draw (4.4),
## the seeker and the two countermeasures (4.6), guns on rocks (6, ruling 17) and
## the shooter's recoil (4.2 item 7).
##
##   "..._console.exe" --headless --path <proj> --script res://tools/_probe_s2w1_weapons.gd --quit-after 20000
##
## The probe builds a real scene tree (a host hull with the physics seams, real
## `PlayerState` pools, real `Projectile`s and an `Asteroid`) and lets the
## component's own frame loop do the work, so every measurement is the shipped
## path. Each stage is cold-started: the trigger is released and the world is
## swept of live shots first, so a leftover shot can never be measured as this
## stage's outcome.

const PlayerStateScript := preload("res://game/player_state.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const WeaponScript := preload("res://game/weapons.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const Profile := preload("res://autoload/player_profile.gd")

const SCRATCH_PROFILE := "user://_probe_s2w1.cfg"
const ROCK_YIELD := 6
const ROCK_TIER := 3
const COLD_FRAMES := 80

var _ok := 0
var _failed := 0
var _blocked := 0
var _frame := 0
var _world: Node2D = null
var _host: FakeHost = null
var _guns: Node2D = null
var _state: PlayerState = null
var _profile: Node = null
var _staged: Array[Node2D] = []
## Every shot signal this probe saw, with the frame and the live shot count at the
## moment it fired: a spent round with no shot in the tree would show up here.
var _shot_log: Array[String] = []


func _init() -> void:
	print("=== slice2 W1 probe: weapon families, draw, seeker, countermeasures ===")
	print("[env] physics_ticks_per_second=%d" % Engine.physics_ticks_per_second)
	## The autoloads are added after a script main loop's `_init` starts, so the
	## profile and the world are resolved one frame in.
	await _step(2)
	_check_keys()
	_check_table()
	_build_world()
	await _check_beam_families()
	await _check_kinetics()
	await _check_rocket()
	await _check_mine()
	await _check_countermeasures()
	await _check_rock_chips()
	if _profile != null:
		_profile.save_path = Profile.SAVE_FILE
	print("[SUMMARY] ok=%d failed=%d blocked=%d" % [_ok, _failed, _blocked])
	quit(1 if _failed > 0 else 0)


## --- Environment ---------------------------------------------------------


## A config dictionary may arrive with String keys and be read with StringName
## ones: the whole `configure` contract depends on the answer.
func _check_keys() -> void:
	var mixed := {"kind": &"bolt"}
	_check("String key is visible to a StringName lookup", mixed.get(&"kind", null) == &"bolt",
		"got %s" % str(mixed.get(&"kind", null)))
	var named := {&"kind": &"bolt"}
	_check("StringName key is visible to a String lookup", named.get("kind", null) == "bolt",
		"got %s" % str(named.get("kind", null)))


## --- The family table (4.1 + 13), transcribed once -----------------------


func _check_table() -> void:
	var expected := {
		&"laser": 500.0,
		&"plasma": 450.0,
		&"cannon": 600.0,
		&"railgun": 800.0,
		&"rocket": 900.0,
		&"mine": 0.0,
	}
	for id: StringName in expected:
		_check("range %s = %s" % [id, expected[id]], WeaponScript.range_of(id) == float(expected[id]),
			"got %s" % WeaponScript.range_of(id))
	_check("laser 30 DPS", WeaponScript.dps_of(&"laser") == 30.0, "got %s" % WeaponScript.dps_of(&"laser"))
	_check("plasma 70 DPS", WeaponScript.dps_of(&"plasma") == 70.0, "got %s" % WeaponScript.dps_of(&"plasma"))
	_check("cannon 45 DPS", WeaponScript.dps_of(&"cannon") == 45.0, "got %s" % WeaponScript.dps_of(&"cannon"))
	_check("railgun 60 DPS", WeaponScript.dps_of(&"railgun") == 60.0,
		"got %s" % WeaponScript.dps_of(&"railgun"))
	_check("rocket alpha 180", WeaponScript.shot_damage(&"rocket") == 180.0,
		"got %s" % WeaponScript.shot_damage(&"rocket"))
	_check("cannon bolt 1000 u/s", float(WeaponScript.row_of(&"cannon").get(&"speed", 0.0)) == 1000.0)
	_check("railgun slug 1400 u/s", float(WeaponScript.row_of(&"railgun").get(&"speed", 0.0)) == 1400.0)
	_check("rocket 900 u/s, 2.2 rad/s, 1.2 s",
		float(WeaponScript.row_of(&"rocket").get(&"speed", 0.0)) == 900.0
		and float(WeaponScript.row_of(&"rocket").get(&"turn_rate", 0.0)) == 2.2
		and WeaponScript.interval_of(&"rocket") == 1.2)
	_check("mine arm 2 s, trigger 60 u",
		float(WeaponScript.row_of(&"mine").get(&"arm", 0.0)) == 2.0
		and float(WeaponScript.row_of(&"mine").get(&"trigger", 0.0)) == 60.0)
	_check("cannon burst 0.35 on / 0.25 off",
		float(WeaponScript.row_of(&"cannon").get(&"burst_on", 0.0)) == 0.35
		and float(WeaponScript.row_of(&"cannon").get(&"burst_off", 0.0)) == 0.25)
	_check("energy draw laser 6 / plasma 10",
		float(WeaponScript.row_of(&"laser").get(&"draw", 0.0)) == 6.0
		and float(WeaponScript.row_of(&"plasma").get(&"draw", 0.0)) == 10.0)
	_check("shield rules: laser/plasma first, kinetic/missile/deployable bypass",
		WeaponScript.row_of(&"laser").get(&"bypass_shield", true) == false
		and WeaponScript.row_of(&"plasma").get(&"bypass_shield", true) == false
		and WeaponScript.row_of(&"cannon").get(&"bypass_shield", false) == true
		and WeaponScript.row_of(&"railgun").get(&"bypass_shield", false) == true
		and WeaponScript.row_of(&"rocket").get(&"bypass_shield", false) == true
		and WeaponScript.row_of(&"mine").get(&"bypass_shield", false) == true)
	_check("plasma hull bonus 1.25", float(WeaponScript.row_of(&"plasma").get(&"hull_bonus", 0.0)) == 1.25)
	_check("chaff 3 ghosts / 3.0 s", WeaponScript.CHAFF_GHOSTS == 3 and WeaponScript.CHAFF_WINDOW == 3.0)
	_check("flare lure 450 u", WeaponScript.FLARE_LURE == 450.0)
	_check("railgun shares the cannon pack",
		WeaponScript.ammo_slot(&"railgun") == WeaponScript.ammo_slot(&"cannon"))
	_check("shot_damage follows DPS x interval",
		is_equal_approx(WeaponScript.shot_damage(&"cannon"), 27.0)
		and is_equal_approx(WeaponScript.shot_damage(&"railgun"), 36.0),
		"cannon %s railgun %s" % [WeaponScript.shot_damage(&"cannon"), WeaponScript.shot_damage(&"railgun")])


## --- The stage -----------------------------------------------------------


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "ProbeWorld"
	get_root().add_child(_world)
	_host = FakeHost.new()
	_host.name = "ProbeShip"
	_world.add_child(_host)
	_guns = WeaponScript.new() as Node2D
	_guns.name = "Weapons"
	_host.add_child(_guns)
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	_state = PlayerStateScript.new()
	_state.energy_max = stats.energy_max
	_state.fuel_max = stats.fuel_max
	_state.energy_regen = stats.energy_regen
	_state.setup()
	_guns.call(&"setup", stats, _state)
	_guns.shot_fired.connect(func(id: StringName) -> void:
		_shot_log.append("%s@%d live=%d deep=%d" % [
			id, _frame, get_nodes_in_group(&"projectile").size(), _count_shots_deep()
		]))
	_check_groups()
	_profile = get_root().get_node_or_null(NodePath("PlayerProfile"))
	if _profile == null:
		print("[env] no PlayerProfile autoload in a --script run")
	else:
		_profile.save_path = SCRATCH_PROFILE


func _select(id: StringName) -> void:
	_guns.call(&"set_firing", false)
	var one: Array[StringName] = [id]
	_guns.call(&"set_fitted", one)
	_guns.call(&"select_group", 1)


## The group seam (section 4.3): `weapon_1..5` picks the fitted order, the range
## clamps, a module id normalizes to its weapon id, and an unknown id is refused.
func _check_groups() -> void:
	var five: Array[StringName] = [&"w_laser", &"cannon", &"rocket", &"mine", &"plasma"]
	_guns.call(&"set_fitted", five)
	_check("module ids normalize to weapon ids",
		(_guns.call(&"fitted") as Array)[0] == &"laser",
		"got %s" % str(_guns.call(&"fitted")))
	_guns.call(&"select_group", 3)
	_check("weapon_3 selects the third fitted weapon",
		StringName(_guns.call(&"selected_weapon")) == &"rocket",
		"got %s" % String(_guns.call(&"selected_weapon")))
	_guns.call(&"select_group", 9)
	_check("the group range clamps to weapon_1..5",
		int(_guns.call(&"selected_group")) == 5, "got %s" % _guns.call(&"selected_group"))
	_guns.call(&"select_group", 0)
	_check("group 0 clamps to 1", int(_guns.call(&"selected_group")) == 1)
	var six: Array[StringName] = [&"laser", &"plasma", &"cannon", &"railgun", &"rocket", &"mine"]
	_guns.call(&"set_fitted", six)
	_check("the sixth family is kept in the fit and reported through fitted()",
		(_guns.call(&"fitted") as Array).size() == 6,
		"got %d" % (_guns.call(&"fitted") as Array).size())
	var junk: Array[StringName] = [&"w_nothing", &"torpedo"]
	_guns.call(&"set_fitted", junk)
	_check("an unknown id cannot become a dead group",
		(_guns.call(&"fitted") as Array).is_empty(),
		"got %s" % str(_guns.call(&"fitted")))
	_guns.call(&"select_group", 1)


## A cold trigger: released, then enough frames for the last stage's shot
## cooldown to run out, so the next shot is this stage's first frame.
func _cold() -> void:
	_guns.call(&"set_firing", false)
	await _step(COLD_FRAMES)


## Sweep the world of the last stage's bodies and every live shot (a shot is
## parented to the scene root, not to this probe's world, so it survives a body
## sweep on its own).
func _stage_clear() -> void:
	_guns.call(&"set_firing", false)
	await _step(COLD_FRAMES)
	for node: Node2D in _staged:
		if is_instance_valid(node):
			node.queue_free()
	_staged.clear()
	for node: Node in get_nodes_in_group(&"projectile"):
		if is_instance_valid(node):
			node.queue_free()
	await _step(3)


func _spawn_hull(at: Vector2, shield: float) -> DummyHull:
	var hull := DummyHull.new()
	hull.name = "DummyHull"
	_world.add_child(hull)
	hull.global_position = at
	hull.shield = shield
	_staged.append(hull)
	## The body must be in the physics space before a ray can find it.
	await _step(3)
	return hull


func _step(frames: int) -> void:
	for _tick in frames:
		await physics_frame
		_frame += 1


func _seconds() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _tick_count(seconds: float) -> int:
	return int(roundf(seconds * float(Engine.physics_ticks_per_second)))


## --- Energy families: instant, range-capped, shields-first ----------------


func _check_beam_families() -> void:
	await _stage_clear()
	var near := await _spawn_hull(Vector2(300.0, 0.0), 600.0)
	_select(&"laser")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	await _step(_tick_count(1.0))
	_guns.call(&"set_firing", false)
	var dealt := 600.0 - near.shield
	_check("laser deals 30 DPS to a live shield", absf(dealt - 30.0) <= 1.0, "dealt %.2f" % dealt)
	_check("laser leaves the hull alone while the shield holds", near.hull == 1000.0,
		"hull %s" % near.hull)
	_check("laser draws 6 E/s", absf(_state.energy - (100.0 - 6.0)) <= 0.3,
		"energy %s" % _state.energy)
	_check("the energy toll burned fuel through the reactor",
		absf(_state.fuel - (200.0 - 0.6)) <= 0.05, "fuel %s" % _state.fuel)
	_check("laser does not bypass shields", near.last_bypass == false)
	_check("ctx rides the damage call (family/direction/impulse)",
		not near.last_ctx.is_empty() and StringName(near.last_ctx.get(&"family", &"")) == &"energy"
		and near.last_ctx.has(&"direction") and near.last_ctx.has(&"impulse"),
		"ctx %s" % str(near.last_ctx))

	## Out of range: the same target, past the cap.
	await _stage_clear()
	var far := await _spawn_hull(Vector2(600.0, 0.0), 600.0)
	_state.set_energy(_state.energy_max)
	_select(&"laser")
	_guns.call(&"set_aim_point", Vector2(600.0, 0.0))
	_guns.call(&"set_firing", true)
	await _step(_tick_count(1.0))
	_guns.call(&"set_firing", false)
	_check("no damage past the 500 u cap", far.shield == 600.0 and far.hull == 1000.0,
		"shield %s hull %s" % [far.shield, far.hull])

	## Plasma: shields first, then +25 % to hull once they are down.
	await _stage_clear()
	var plated := await _spawn_hull(Vector2(300.0, 0.0), 600.0)
	_state.set_energy(_state.energy_max)
	_select(&"plasma")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	await _step(_tick_count(1.0))
	_guns.call(&"set_firing", false)
	var plasma_shield := 600.0 - plated.shield
	_check("plasma deals 70 DPS to a live shield", absf(plasma_shield - 70.0) <= 1.5,
		"dealt %.2f" % plasma_shield)
	_check("plasma draws 10 E/s", absf(_state.energy - (100.0 - 10.0)) <= 0.3,
		"energy %s" % _state.energy)
	_check("plasma adds no hull bonus while the shield holds", plated.hull == 1000.0)
	plated.shield = 0.0
	plated.hull = 1000.0
	_state.set_energy(_state.energy_max)
	_guns.call(&"set_firing", true)
	await _step(_tick_count(1.0))
	_guns.call(&"set_firing", false)
	var melt := 1000.0 - plated.hull
	_check("plasma melts armour: 87.5 DPS with the shields down", absf(melt - 87.5) <= 2.0,
		"hull damage %.2f" % melt)

	## A short pool is dry fire, no shot (4.4).
	await _stage_clear()
	var ignored := await _spawn_hull(Vector2(300.0, 0.0), 600.0)
	_state.set_energy(0.0)
	var dry: Array[StringName] = []
	_guns.dry_fired.connect(func(id: StringName) -> void: dry.append(id))
	_select(&"plasma")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	await _step(30)
	_guns.call(&"set_firing", false)
	_check("an empty pool dry-fires once and deals nothing",
		dry.size() == 1 and ignored.shield == 600.0,
		"dry %d shield %s" % [dry.size(), ignored.shield])
	_check("dry_reason reports the empty pool", String(_guns.call(&"dry_reason")) == "energy",
		"got %s" % String(_guns.call(&"dry_reason")))


## --- Kinetics: travel speed, fizzle range, ammo, cadence, dry fire --------


func _check_kinetics() -> void:
	await _stage_clear()
	_select(&"cannon")
	var shots: Array[int] = []
	var dry: Array[StringName] = []
	_guns.shot_fired.connect(func(_id: StringName) -> void: shots.append(_frame))
	_guns.dry_fired.connect(func(id: StringName) -> void: dry.append(id))
	_guns.call(&"set_aim_point", Vector2(590.0, 0.0))
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	var bolts := _projectiles()
	var bolt: Node2D = bolts[0] if bolts.size() == 1 else null
	_check("a cannon shot spawns a bolt", bolt != null, "got %d" % bolts.size())
	if bolt != null:
		_check("bolt travels 1000 u/s", is_equal_approx(bolt.call(&"velocity").length(), 1000.0),
			"got %s" % bolt.call(&"velocity").length())
		_check("bolt carries 27 damage (45 DPS x 0.6 s)",
			is_equal_approx(bolt.call(&"damage_amount"), 27.0),
			"got %s" % bolt.call(&"damage_amount"))
		_check("bolt bypasses shields", bool(bolt.call(&"bypasses_shield")) == true)
	_check("one round leaves the pack per bolt", _ammo(&"cannon") == 299,
		"cannon ammo %d" % _ammo(&"cannon"))
	_check("recoil reaches the hull", _host.recoil_calls == 1, "calls %d" % _host.recoil_calls)
	_check("recoil is m x v opposite the muzzle",
		absf(_host.last_recoil_velocity.length() - 1000.0) < 0.5 and _host.last_recoil_mass == 1.0,
		"v %s m %s" % [_host.last_recoil_velocity, _host.last_recoil_mass])
	_check("the first shot is announced once", shots.size() == 1, "shots %d" % shots.size())
	## The cadence: one bolt per burst cycle while the trigger is held.
	await _step(_tick_count(2.4))
	_guns.call(&"set_firing", false)
	var gaps: Array[int] = []
	for index in range(1, shots.size()):
		gaps.append(shots[index] - shots[index - 1])
	var cadence_ok := gaps.size() >= 2
	for gap: int in gaps:
		if gap < 35 or gap > 38:
			cadence_ok = false
	_check("the cannon fires one bolt per burst cycle (0.6 s = 36 frames)", cadence_ok,
		"frames %s" % str(shots))
	var first_alive := is_instance_valid(bolt) and not bolt.is_queued_for_deletion()
	_check("a held trigger keeps replacing the bolt that fizzles", first_alive == false,
		"the first bolt is still alive")
	await _step(3)

	## The railgun: 1400 u/s, 36 damage, shields untouched, the cannon's pack.
	await _stage_clear()
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 2)
	var shielded := await _spawn_hull(Vector2(300.0, 0.0), 600.0)
	_select(&"railgun")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	var slugs := _projectiles()
	var slug: Node2D = slugs[0] if slugs.size() == 1 else null
	_check("a railgun shot spawns a slug", slug != null, "got %d" % slugs.size())
	if slug != null:
		_check("slug travels 1400 u/s", is_equal_approx(slug.call(&"velocity").length(), 1400.0),
			"got %s" % slug.call(&"velocity").length())
	_check("the railgun spends the cannon pack", _ammo(&"cannon") == 1, "ammo %d" % _ammo(&"cannon"))
	await _step(_tick_count(0.5))
	_guns.call(&"set_firing", false)
	_check("a slug bypasses the shield into the hull",
		shielded.shield == 600.0 and is_equal_approx(1000.0 - shielded.hull, 36.0),
		"shield %s hull %s" % [shielded.shield, shielded.hull])

	## An empty pack: dry fire, no shot.
	await _stage_clear()
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 0)
	shots.clear()
	dry.clear()
	_select(&"cannon")
	_guns.call(&"set_firing", true)
	await _step(30)
	_guns.call(&"set_firing", false)
	_check("an empty pack dry-fires once and fires nothing",
		dry.size() == 1 and shots.is_empty(),
		"dry %d shots %d" % [dry.size(), shots.size()])
	_check("dry_reason reports the empty pack", String(_guns.call(&"dry_reason")) == "ammo",
		"got %s" % String(_guns.call(&"dry_reason")))
	await _step(3)


## --- The seeker (4.1 + 4.6) ----------------------------------------------


func _check_rocket() -> void:
	await _stage_clear()
	_state.set_ammo(WeaponScript.ammo_slot(&"rocket"), 10)
	var prey := await _spawn_hull(Vector2(0.0, 400.0), 600.0)
	_select(&"rocket")
	_guns.call(&"set_lock_target", prey)
	_guns.call(&"set_aim_point", Vector2(600.0, 0.0))
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	var rockets := _projectiles()
	var rocket: Node2D = rockets[0] if rockets.size() == 1 else null
	_check("a rocket spawns on the trigger", rocket != null, "got %d" % rockets.size())
	if rocket == null:
		return
	_check("the rocket carries 180 alpha", is_equal_approx(rocket.call(&"damage_amount"), 180.0),
		"got %s" % rocket.call(&"damage_amount"))
	_check("the rocket is destructible in flight", bool(rocket.call(&"is_destructible")) == true)
	_check("the rocket took the lock as its target", rocket.call(&"lock_target") == prey,
		"target %s" % str(rocket.call(&"lock_target")))
	var before: Vector2 = rocket.call(&"velocity")
	await physics_frame
	_frame += 1
	var after: Vector2 = rocket.call(&"velocity")
	var turned := absf(wrapf(after.angle() - before.angle(), -PI, PI))
	var expected := 2.2 * _seconds()
	_check("homing turns at 2.2 rad/s", absf(turned - expected) < 0.003,
		"turned %.5f rad in one frame (expected %.5f)" % [turned, expected])
	_check("speed is held while turning", is_equal_approx(after.length(), 900.0),
		"got %s" % after.length())
	var flew := 0.0
	for _tick in _tick_count(1.6):
		if not is_instance_valid(rocket) or rocket.is_queued_for_deletion():
			break
		await physics_frame
		_frame += 1
		flew += _seconds()
	_guns.call(&"set_firing", false)
	## The turn measurement above is the homing law; arrival is measured against a
	## target the seeker is actually aimed at, because 2.2 rad/s at 900 u/s is a
	## 409 u turn radius and a target acquired abeam at less than that is orbited
	## rather than struck (reported: the spec pins no fuse radius).
	await _cold()
	_guns.call(&"set_lock_target", prey)
	_guns.call(&"set_aim_point", prey.global_position)
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	var inbound := _projectiles()
	var inbound_shot: Node2D = inbound[0] if inbound.size() == 1 else null
	for _tick in _tick_count(1.2):
		if not is_instance_valid(inbound_shot) or inbound_shot.is_queued_for_deletion():
			break
		await physics_frame
		_frame += 1
	_guns.call(&"set_firing", false)
	_check("the rocket reaches its locked hull and detonates",
		is_equal_approx(1000.0 - prey.hull, 180.0),
		"hull damage %s" % (1000.0 - prey.hull))
	_check("the rocket spends one rocket round", _ammo(&"rocket") == 8, "ammo %d" % _ammo(&"rocket"))

	## Without a lock it dumb-fires at the cursor and flies straight.
	await _cold()
	_guns.call(&"clear_lock_target")
	_guns.call(&"set_aim_point", Vector2(600.0, 0.0))
	_guns.call(&"set_firing", true)
	var dumb: Array[Node2D] = []
	for _tick in 5:
		await physics_frame
		_frame += 1
		dumb = _projectiles()
		if not dumb.is_empty():
			break
	var bearing := 0.0
	var straight := false
	if dumb.size() == 1:
		bearing = (dumb[0].call(&"velocity") as Vector2).angle()
		straight = true
	await _step(10)
	_guns.call(&"set_firing", false)
	if straight and is_instance_valid(dumb[0]):
		straight = absf(wrapf((dumb[0].call(&"velocity") as Vector2).angle() - bearing, -PI, PI)) < 0.001
	_check("a rocket without a lock flies straight (dumb-fire)", straight,
		"shots %d ammo %d dry %s" % [dumb.size(), _ammo(&"rocket"), String(_guns.call(&"dry_reason"))])
	await _step(3)

	## A weapon hit kills it in flight: a stationary rocket in the beam's path.
	await _stage_clear()
	var bullet := _spawn_projectile(&"rocket", Vector2(300.0, 0.0), Vector2.ZERO, null, 0.0, null)
	_state.set_energy(_state.energy_max)
	_select(&"laser")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	await _step(3)
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	_guns.call(&"set_firing", false)
	_check("a weapon hit destroys the rocket in flight",
		not is_instance_valid(bullet) or bullet.is_queued_for_deletion(),
		"still alive: %s" % str(is_instance_valid(bullet)))
	await _step(3)


## --- The mine (4.1 + 13) --------------------------------------------------


func _check_mine() -> void:
	await _stage_clear()
	_state.set_ammo(WeaponScript.ammo_slot(&"mine"), 4)
	var victim := await _spawn_hull(Vector2(59.0, 0.0), 0.0)
	_select(&"mine")
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	_guns.call(&"set_firing", false)
	var mines := _projectiles()
	var mine: Node2D = mines[0] if mines.size() == 1 else null
	_check("the mine drops on the trigger", mine != null, "got %d" % mines.size())
	if mine == null:
		return
	_check("a dropped mine is stationary", (mine.call(&"velocity") as Vector2).is_zero_approx(),
		"v %s" % str(mine.call(&"velocity")))
	_check("the mine spends one mine round", _ammo(&"mine") == 3, "ammo %d" % _ammo(&"mine"))
	await _step(_tick_count(1.9))
	_check("a mine does not trigger before its 2 s arm time",
		victim.hull == 1000.0 and is_instance_valid(mine) and not mine.is_queued_for_deletion(),
		"hull %s" % victim.hull)
	await _step(10)
	_check("an armed mine detonates on a hull inside 60 u", is_equal_approx(1000.0 - victim.hull, 180.0),
		"hull damage %s" % (1000.0 - victim.hull))

	## 61 u away: armed and silent.
	await _stage_clear()
	var far_hull := await _spawn_hull(Vector2(61.0, 0.0), 0.0)
	_select(&"mine")
	_guns.call(&"set_firing", true)
	await physics_frame
	_frame += 1
	_guns.call(&"set_firing", false)
	var far_mine: Array[Node2D] = []
	for _tick in 5:
		await physics_frame
		_frame += 1
		far_mine = _projectiles()
		if not far_mine.is_empty():
			break
	await _step(_tick_count(2.2))
	var any_alive := false
	for shot: Node2D in far_mine:
		if is_instance_valid(shot) and not shot.is_queued_for_deletion():
			any_alive = true
	_check("a mine at 61 u arms and stays silent", far_hull.hull == 1000.0 and any_alive,
		"hull %s mine alive %s dropped %d" % [far_hull.hull, any_alive, far_mine.size()])
	await _step(3)


## --- Countermeasures (4.6) -----------------------------------------------


func _check_countermeasures() -> void:
	await _stage_clear()
	if _profile == null:
		_blocked += 1
		print("[BLOCK] no PlayerProfile autoload: the countermeasure half is unmeasured")
		return
	_profile.call(&"add_cargo", WeaponScript.CHAFF_ITEM, 2)
	_profile.call(&"add_cargo", WeaponScript.FLARE_ITEM, 2)
	var locked := await _spawn_hull(Vector2(200.0, 0.0), 600.0)
	_guns.call(&"set_lock_target", locked)
	var breaks: Array[bool] = []
	_guns.locks_broken.connect(func() -> void: breaks.append(true))
	var used: bool = bool(_guns.call(&"use_countermeasure", WeaponScript.CHAFF_ITEM))
	_check("a chaff use spends one item",
		used and int(_profile.call(&"cargo_qty", WeaponScript.CHAFF_ITEM)) == 1,
		"held %d" % int(_profile.call(&"cargo_qty", WeaponScript.CHAFF_ITEM)))
	_check("chaff breaks the active lock", breaks.size() == 1 and _guns.call(&"lock_target") == null,
		"breaks %d" % breaks.size())
	var ghosts: Array = _guns.call(&"ghosts")
	_check("chaff spawns 3 ghosts", ghosts.size() == 3, "got %d" % ghosts.size())
	var kinds := true
	for ghost: Node2D in ghosts:
		if ghost.call(&"blip_kind") != &"ghost":
			kinds = false
	_check("every ghost answers the ghost blip kind", kinds)
	_check("locks cannot re-acquire while the ghosts live", bool(_guns.call(&"jamming")) == true)
	await _step(_tick_count(2.0))
	_check("the ghosts are still live at 2 s", bool(_guns.call(&"jamming")) == true)
	await _step(_tick_count(1.3))
	_check("the 3.0 s window ends and the ghosts clear",
		bool(_guns.call(&"jamming")) == false and (_guns.call(&"ghosts") as Array).is_empty(),
		"jamming %s ghosts %d" % [
			str(_guns.call(&"jamming")), (_guns.call(&"ghosts") as Array).size()
		])

	## A moving hull's ghosts drift away from it.
	_host.linear = Vector2(100.0, 0.0)
	used = bool(_guns.call(&"use_countermeasure", WeaponScript.CHAFF_ITEM))
	var drifting: Array = _guns.call(&"ghosts")
	var origin: Array[Vector2] = []
	for ghost: Node2D in drifting:
		origin.append(ghost.global_position)
	await _step(10)
	var moved := drifting.size() == 3
	for index in drifting.size():
		if not is_instance_valid(drifting[index]):
			moved = false
			continue
		if (drifting[index] as Node2D).global_position.distance_to(origin[index]) < 5.0:
			moved = false
	_check("ghosts drift away from the moving hull", moved)
	_check("a second chaff use spends the last item",
		used and int(_profile.call(&"cargo_qty", WeaponScript.CHAFF_ITEM)) == 0)
	var third: bool = bool(_guns.call(&"use_countermeasure", WeaponScript.CHAFF_ITEM))
	_check("a chaff use with no item left refuses", third == false)
	_host.linear = Vector2.ZERO
	await _step(_tick_count(3.2))

	## The flare: a homing rocket inside 450 u retargets and detonates on it.
	await _stage_clear()
	var lure_hull := await _spawn_hull(Vector2(400.0, 0.0), 600.0)
	var lured := _spawn_projectile(
		&"rocket", Vector2(-120.0, 0.0), Vector2(1.0, 0.0), null, 900.0, lure_hull
	)
	var far_away := _spawn_projectile(
		&"rocket", Vector2(600.0, 0.0), Vector2(1.0, 0.0), null, 900.0, lure_hull
	)
	var detonations: Array[Vector2] = []
	lured.detonated.connect(func(pos: Vector2, _d: float, _b: bool) -> void:
		detonations.append(pos))
	used = bool(_guns.call(&"use_countermeasure", WeaponScript.FLARE_ITEM))
	var flare: Node2D = _guns.call(&"flare")
	_check("a flare use spawns a decoy and spends one item",
		used and flare != null and int(_profile.call(&"cargo_qty", WeaponScript.FLARE_ITEM)) == 1,
		"flare %s held %d" % [
			str(flare != null), int(_profile.call(&"cargo_qty", WeaponScript.FLARE_ITEM))
		])
	_check("a rocket inside 450 u retargets to the flare", lured.call(&"decoy") == flare,
		"decoy %s" % str(lured.call(&"decoy")))
	_check("a rocket outside 450 u keeps its own target", far_away.call(&"decoy") == null,
		"decoy %s" % str(far_away.call(&"decoy")))
	var flare_at := flare.global_position
	await _step(_tick_count(1.0))
	_check("the lured rocket detonates on the flare", detonations.size() == 1,
		"detonations %d" % detonations.size())
	if not detonations.is_empty():
		_check("the detonation lands at the decoy",
			detonations[0].distance_to(flare_at) < 30.0, "at %s" % str(detonations[0]))
	_check("the decoy is freed once nothing is chasing it",
		not is_instance_valid(flare) and _guns.call(&"flare") == null)
	if is_instance_valid(lured):
		lured.queue_free()
	if is_instance_valid(far_away):
		far_away.queue_free()
	await _step(3)


## --- Guns on rocks (6, ruling 17) ----------------------------------------


func _check_rock_chips() -> void:
	await _stage_clear()
	var rock := AsteroidScript.new() as Node2D
	if rock == null:
		_blocked += 1
		print("[BLOCK] asteroid.gd did not instantiate: the chip half is unmeasured")
		return
	_world.add_child(rock)
	rock.global_position = Vector2(300.0, 0.0)
	rock.call(&"setup", &"mineral_iron", ROCK_TIER, ROCK_YIELD, AsteroidScript.SIZE_LARGE)
	_staged.append(rock)
	await _step(3)
	var yield_before := int(rock.get(&"yield_units"))
	_state.set_energy(_state.energy_max)
	_select(&"laser")
	_guns.call(&"set_aim_point", Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	await _step(_tick_count(1.0))
	_guns.call(&"set_firing", false)
	var mined := yield_before - int(rock.get(&"yield_units"))
	var chip_work := float(rock.get(&"work")) + float(mined)
	_check("a laser chips a rock at 10 % of its DPS (3 work over 1 s)", absf(chip_work - 3.0) <= 0.4,
		"work %.3f" % chip_work)
	var pickups := 0
	for node: Node in get_nodes_in_group(&"pickup"):
		if is_instance_valid(node):
			pickups += 1
	_check("chips never extract ore (no pickup spawned)", pickups == 0, "pickups %d" % pickups)
	_check("the rock lost depletion", mined > 0, "mined %d" % mined)


## --- Helpers --------------------------------------------------------------


func _projectiles() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for node: Node in get_nodes_in_group(&"projectile"):
		var shot := node as Node2D
		if shot != null and is_instance_valid(shot) and not shot.is_queued_for_deletion():
			out.append(shot)
	return out


## A bare shot for the cases the component cannot stage (a rocket already in the
## air). A null `source` means nobody's, which is what lets the probe's own beam
## shoot it down.
func _spawn_projectile(
	kind: StringName,
	at: Vector2,
	direction: Vector2,
	source: Node2D,
	speed: float,
	target: Node2D
) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "ProbeShot"
	shot.call(&"configure", {
		&"kind": kind,
		&"speed": speed,
		&"damage": 180.0,
		&"bypass_shield": true,
		&"homing": true,
		&"turn_rate": 2.2,
		&"target": target,
		&"source": source,
		&"direction": direction,
		&"range": 900.0,
		&"mass": 1.0,
		&"chip": 0.10,
	})
	_world.add_child(shot)
	shot.global_position = at
	_staged.append(shot)
	return shot


## Whether a node that never entered the tree would be invisible to a group count.
func _count_shots_deep() -> int:
	var count := 0
	var stack: Array[Node] = [get_root()]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.has_method(&"damage_amount") and is_instance_valid(node):
			count += 1
		for child: Node in node.get_children():
			stack.append(child)
	return count


func _ammo(weapon_id: StringName) -> int:
	var slot := WeaponScript.ammo_slot(weapon_id)
	if _state == null or slot < 0 or slot >= _state.ammo.size():
		return -1
	return _state.ammo[slot]


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_ok += 1
		print("[ok] %s" % label)
	else:
		_failed += 1
		print("[FAIL] %s%s" % [label, (" - " + detail) if detail != "" else ""])


## The hull the weapons are mounted on: the physics seams `weapons.gd` reaches for
## (`apply_recoil`, `velocity`), nothing else. It records what a shot asked for so
## the recoil term can be measured without a second rigid body.
class FakeHost extends Node2D:
	const IMPACT := preload("res://game/impact.gd")

	var recoil_calls := 0
	var last_recoil_velocity := Vector2.ZERO
	var last_recoil_mass := 0.0
	var linear := Vector2.ZERO

	func apply_recoil(projectile_velocity: Vector2, projectile_mass: float) -> void:
		recoil_calls += 1
		last_recoil_velocity = projectile_velocity
		last_recoil_mass = projectile_mass
		var instant := IMPACT.recoil_impulse(projectile_mass, projectile_velocity.length())
		if not projectile_velocity.is_zero_approx():
			linear -= projectile_velocity.normalized() * instant

	func velocity() -> Vector2:
		return linear


## The target seam's dummy: `take_damage(amount, bypass_shield, ctx)` exactly as
## the slice-2 pipeline pins it, a readable `shield`, and a rigid body so a hit's
## knockback has something to push.
class DummyHull extends RigidBody2D:
	var shield := 0.0
	var hull := 1000.0
	var last_bypass := false
	var last_ctx: Dictionary = {}

	func _ready() -> void:
		add_to_group(&"npc_ship")
		collision_layer = 2
		collision_mask = 0
		gravity_scale = 0.0
		mass = 110.0
		linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
		linear_damp = 4.0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 30.0
		shape.shape = circle
		add_child(shape)

	func take_damage(amount: float, bypass_shield: bool, ctx: Dictionary = {}) -> void:
		last_bypass = bypass_shield
		last_ctx = ctx
		if not bypass_shield and shield > 0.0:
			shield = maxf(shield - amount, 0.0)
			return
		hull = maxf(hull - amount, 0.0)
