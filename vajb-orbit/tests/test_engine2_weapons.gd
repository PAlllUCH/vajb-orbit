@tool
extends McpTestSuite
## Suite engine2_weapons: the family table, the group/ammo seams and the projectile
## configuration of engine slice 2's W1 (ENGINE_SPEC sections 4.1, 4.3, 4.4, 4.6 and
## 13; docs/CONTRACTS.md sections 2/4/5/8.1).
##
## Pure logic only: no physics, no awaits, no scene tree. Every number here is
## checked against a hand transcription of section 13 (or section 4.1's prose), the
## same way the slice-0 probes do, so a drift in `weapons.gd` fails here. The timed
## half - firing each family, the range cap, the homing law, the mine's arm and
## trigger, the chaff window and the flare lure - needs stepped physics frames and
## is measured in `tools/_probe_s2w1_weapons.gd` (archived next to its log in
## `.agents/gen/`).

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

var _guns: Node2D = null
var _state: PlayerState = null


func suite_name() -> String:
	return "engine2_weapons"


func setup() -> void:
	_guns = WeaponScript.new() as Node2D
	_state = PlayerStateScript.new()
	_state.setup()
	_guns.call(&"setup", null, _state)


func teardown() -> void:
	if _guns != null and is_instance_valid(_guns):
		_guns.free()
	_guns = null
	_state = null


## --- Section 4.1 + section 13: the family table ---------------------------


func test_ranges_are_the_section_13_row() -> void:
	assert_eq(WeaponScript.range_of(&"laser"), 500.0, "laser 500")
	assert_eq(WeaponScript.range_of(&"plasma"), 450.0, "plasma 450")
	assert_eq(WeaponScript.range_of(&"cannon"), 600.0, "cannon 600")
	assert_eq(WeaponScript.range_of(&"railgun"), 800.0, "railgun 800")
	assert_eq(WeaponScript.range_of(&"rocket"), 900.0, "rocket 900")


func test_dps_is_the_section_4_1_column() -> void:
	assert_eq(WeaponScript.dps_of(&"laser"), 30.0, "laser 30 DPS")
	assert_eq(WeaponScript.dps_of(&"plasma"), 70.0, "plasma 70 DPS")
	assert_eq(WeaponScript.dps_of(&"cannon"), 45.0, "cannon 45 DPS")
	assert_eq(WeaponScript.dps_of(&"railgun"), 60.0, "railgun 60 DPS")


func test_the_six_families_and_their_travel_rows() -> void:
	assert_eq(WeaponScript.family_of(&"laser"), &"energy", "laser is energy")
	assert_eq(WeaponScript.family_of(&"plasma"), &"energy", "plasma is energy")
	assert_eq(WeaponScript.family_of(&"cannon"), &"kinetic", "cannon is kinetic")
	assert_eq(WeaponScript.family_of(&"railgun"), &"kinetic", "railgun is kinetic")
	assert_eq(WeaponScript.family_of(&"rocket"), &"missile", "rocket is missile")
	assert_eq(WeaponScript.family_of(&"mine"), &"deployable", "mine is deployable")
	assert_eq(float(WeaponScript.row_of(&"cannon")[&"speed"]), 1000.0, "bolt 1000 u/s")
	assert_eq(float(WeaponScript.row_of(&"railgun")[&"speed"]), 1400.0, "slug 1400 u/s")
	assert_eq(float(WeaponScript.row_of(&"rocket")[&"speed"]), 900.0, "rocket 900 u/s")
	assert_eq(float(WeaponScript.row_of(&"rocket")[&"turn_rate"]), 2.2, "homing 2.2 rad/s")


func test_shield_rules_split_energy_from_the_rest() -> void:
	assert_eq(WeaponScript.row_of(&"laser")[&"bypass_shield"], false, "laser is shields first")
	assert_eq(WeaponScript.row_of(&"plasma")[&"bypass_shield"], false, "plasma is shields first")
	for id: StringName in [&"cannon", &"railgun", &"rocket", &"mine"]:
		assert_eq(WeaponScript.row_of(id)[&"bypass_shield"], true, "%s bypasses shields" % id)


func test_plasma_carries_the_25_percent_hull_bonus() -> void:
	assert_eq(float(WeaponScript.row_of(&"plasma")[&"hull_bonus"]), 1.25, "plasma melts armour")
	assert_false(WeaponScript.row_of(&"laser").has(&"hull_bonus"), "the laser has no bonus")


func test_energy_draw_is_six_and_ten() -> void:
	assert_eq(float(WeaponScript.row_of(&"laser")[&"draw"]), 6.0, "laser 6 E/s")
	assert_eq(float(WeaponScript.row_of(&"plasma")[&"draw"]), 10.0, "plasma 10 E/s")
	assert_false(WeaponScript.row_of(&"cannon").has(&"draw"), "kinetics draw no Energy")
	assert_false(WeaponScript.row_of(&"rocket").has(&"draw"), "rockets draw no Energy")
	assert_false(WeaponScript.row_of(&"mine").has(&"draw"), "mines draw no Energy")


func test_cannon_burst_cycle_and_the_rocket_interval() -> void:
	assert_eq(float(WeaponScript.row_of(&"cannon")[&"burst_on"]), 0.35, "0.35 s on")
	assert_eq(float(WeaponScript.row_of(&"cannon")[&"burst_off"]), 0.25, "0.25 s off")
	assert_eq(WeaponScript.interval_of(&"cannon"), 0.6, "the burst cycle sums to the cadence")
	assert_eq(WeaponScript.interval_of(&"rocket"), 1.2, "rocket 1.2 s interval")
	assert_eq(WeaponScript.interval_of(&"laser"), 0.0, "an instant family has no shot cadence")


func test_mine_rows_are_the_arm_and_trigger() -> void:
	assert_eq(float(WeaponScript.row_of(&"mine")[&"arm"]), 2.0, "arm 2 s")
	assert_eq(float(WeaponScript.row_of(&"mine")[&"trigger"]), 60.0, "trigger 60 u")
	assert_eq(float(WeaponScript.row_of(&"mine")[&"speed"]), 0.0, "a mine is static")


## The DPS column is the only damage figure section 4.1 states for the kinetics, so
## a released shot's damage is `DPS x interval` and a stream of hits delivers the
## spec's DPS exactly. `alpha` is used where the row states one.
func test_shot_damage_follows_dps_times_interval() -> void:
	assert_eq(WeaponScript.shot_damage(&"cannon"), 27.0, "45 DPS x 0.6 s")
	assert_eq(WeaponScript.shot_damage(&"railgun"), 36.0, "60 DPS x 0.6 s")
	assert_eq(WeaponScript.shot_damage(&"rocket"), 180.0, "rocket alpha")
	assert_eq(WeaponScript.shot_damage(&"mine"), 180.0, "mine alpha")
	assert_eq(WeaponScript.shot_damage(&"laser"), 0.0, "an instant family carries no shot damage")


func test_countermeasure_rows() -> void:
	assert_eq(WeaponScript.CHAFF_GHOSTS, 3, "3 ghost signatures")
	assert_eq(WeaponScript.CHAFF_WINDOW, 3.0, "CHAFF_WINDOW 3.0 s")
	assert_eq(WeaponScript.FLARE_LURE, 450.0, "FLARE_LURE 450 u")
	assert_eq(String(WeaponScript.CHAFF_ITEM), "cm_chaff", "06's item id")
	assert_eq(String(WeaponScript.FLARE_ITEM), "cm_flare", "06's item id")


## --- Section 4.3: groups and packs ---------------------------------------


func test_ammo_slots_come_from_player_state() -> void:
	assert_eq(WeaponScript.ammo_slot(&"laser"), PlayerStateScript.WEAPONS.find(&"laser"))
	assert_eq(WeaponScript.ammo_slot(&"cannon"), PlayerStateScript.WEAPONS.find(&"cannon"))
	assert_eq(WeaponScript.ammo_slot(&"rocket"), PlayerStateScript.WEAPONS.find(&"rocket"))
	assert_eq(WeaponScript.ammo_slot(&"mine"), PlayerStateScript.WEAPONS.find(&"mine"))
	assert_eq(WeaponScript.ammo_slot(&"plasma"), PlayerStateScript.WEAPONS.find(&"plasma"))


## 09 section 3.1 / CONTRACTS section 3: the railgun shares the cannon pack in v1,
## and it is the one family `PlayerState.WEAPONS` does not carry a slot for.
func test_the_railgun_shares_the_cannon_pack() -> void:
	assert_eq(WeaponScript.ammo_slot(&"railgun"), WeaponScript.ammo_slot(&"cannon"),
		"railgun spends the cannon slot")
	assert_eq(WeaponScript.ammo_slot(&"torpedo"), -1, "an unknown family has no slot")


func test_module_ids_normalize_to_weapon_ids() -> void:
	assert_eq(WeaponScript.weapon_id(&"w_laser"), &"laser", "w_laser -> laser")
	assert_eq(WeaponScript.weapon_id(&"laser"), &"laser", "a weapon id passes through")
	assert_eq(WeaponScript.weapon_id(&"w_nothing"), &"", "an unknown module is refused")


func test_groups_follow_the_fitted_order_and_clamp_to_weapon_1_5() -> void:
	var fit: Array[StringName] = [&"w_laser", &"cannon", &"rocket", &"mine", &"plasma"]
	_guns.call(&"set_fitted", fit)
	var fitted: Array = _guns.call(&"fitted")
	assert_eq(fitted.size(), 5, "the fit keeps its length")
	assert_eq(StringName(fitted[0]), &"laser", "module ids arrive as weapon ids")
	assert_eq(StringName(fitted[4]), &"plasma", "in group order")
	_guns.call(&"select_group", 3)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"rocket", "weapon_3 is the third")
	_guns.call(&"select_group", 9)
	assert_eq(int(_guns.call(&"selected_group")), 5, "a group past the map clamps to 5")
	_guns.call(&"select_group", 0)
	assert_eq(int(_guns.call(&"selected_group")), 1, "a group below the map clamps to 1")


## Six families exist and the input map offers five groups, so a fit can carry more
## weapons than it can select. The list is kept whole rather than silently
## truncated, so the wiring layer can see the mismatch.
func test_a_six_weapon_fit_is_kept_whole() -> void:
	var fit: Array[StringName] = [&"laser", &"plasma", &"cannon", &"railgun", &"rocket", &"mine"]
	_guns.call(&"set_fitted", fit)
	assert_eq((_guns.call(&"fitted") as Array).size(), 6, "six weapons are fitted")
	_guns.call(&"select_group", 5)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"rocket", "group 5 is the fifth")

func test_a_group_with_no_weapon_selects_nothing() -> void:
	var fit: Array[StringName] = [&"laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 2)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"", "an empty group fires nothing")
	assert_eq(StringName(_guns.call(&"dry_reason")), &"none", "and reports none")

func test_unknown_ids_do_not_become_dead_groups() -> void:
	var fit: Array[StringName] = [&"w_nothing", &"torpedo", &"w_mine"]
	_guns.call(&"set_fitted", fit)
	var fitted: Array = _guns.call(&"fitted")
	assert_eq(fitted.size(), 1, "only the known weapon survives")
	assert_eq(StringName(fitted[0]), &"mine", "and it is the mine")


## --- Section 4.4 / 4.3: the dry states ------------------------------------


func test_dry_reason_reports_the_empty_pack() -> void:
	var fit: Array[StringName] = [&"cannon"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	assert_eq(StringName(_guns.call(&"dry_reason")), &"", "a full pack is not dry")
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 0)
	assert_eq(StringName(_guns.call(&"dry_reason")), &"ammo", "an empty pack is dry")


func test_dry_reason_reports_the_empty_pool() -> void:
	var fit: Array[StringName] = [&"laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	assert_eq(StringName(_guns.call(&"dry_reason")), &"", "a full pool is not dry")
	_state.set_energy(0.0)
	assert_eq(StringName(_guns.call(&"dry_reason")), &"energy", "an empty pool is dry")

func test_a_weapon_without_a_state_is_dry_not_fatal() -> void:
	var loose: Node2D = WeaponScript.new() as Node2D
	var fit: Array[StringName] = [&"cannon"]
	loose.call(&"set_fitted", fit)
	loose.call(&"select_group", 1)
	assert_eq(StringName(loose.call(&"dry_reason")), &"ammo", "no state: nothing to spend")
	loose.call(&"tick", 0.1)
	assert_eq(int(loose.call(&"selected_group")), 1, "a tick without a state is a no-op")
	loose.free()


func test_section_4_4_draw_rides_the_energy_gate() -> void:
	var before := _state.energy
	assert_true(_state.try_spend_energy(WeaponScript.dps_of(&"laser") * 0.0), "a zero draw succeeds")
	assert_eq(_state.energy, before, "a zero draw spends nothing")
	assert_false(_state.try_spend_energy(_state.energy + 1.0), "a short pool refuses")


## --- Section 4.2 item 5 / 4.6: the lock and the countermeasure seams ------


func test_the_lock_seam_holds_and_clears_the_seeker_target() -> void:
	var target := Node2D.new()
	_guns.call(&"set_lock_target", target)
	assert_eq(_guns.call(&"lock_target"), target, "the lock target is held")
	_guns.call(&"clear_lock_target")
	assert_eq(_guns.call(&"lock_target"), null, "clearing drops it")
	target.free()


func test_an_unknown_countermeasure_is_refused_before_any_spend() -> void:
	assert_false(bool(_guns.call(&"use_countermeasure", &"cm_nope")), "an unknown item refuses")
	assert_false(bool(_guns.call(&"use_countermeasure", &"")), "an empty id refuses")


func test_an_empty_hold_refuses_a_countermeasure() -> void:
	var profile := _service()
	if profile == null:
		skip("no PlayerProfile autoload in this runner")
		return
	var held := int(profile.call(&"cargo_qty", WeaponScript.CHAFF_ITEM))
	assert_eq(held, 0, "the scratch-free hold carries no chaff")
	assert_false(bool(_guns.call(&"use_countermeasure", WeaponScript.CHAFF_ITEM)),
		"no item, no chaff")
	assert_true((_guns.call(&"ghosts") as Array).is_empty(), "and no ghost was spawned")
	assert_false(bool(_guns.call(&"jamming")), "and nothing is jamming")


func _service() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null(NodePath(PROFILE_SERVICE))


## --- The projectile's pinned configuration -------------------------------


func test_projectile_configure_reads_the_pinned_keys() -> void:
	var shot := ProjectileScript.new() as Node2D
	shot.call(&"configure", {
		&"kind": &"rocket",
		&"speed": 900.0,
		&"damage": 180.0,
		&"bypass_shield": true,
		&"homing": true,
		&"turn_rate": 2.2,
		&"range": 900.0,
		&"mass": 1.0,
		&"chip": 0.10,
		&"direction": Vector2.RIGHT,
	})
	assert_eq(StringName(shot.get(&"kind")), &"rocket", "kind")
	assert_eq(shot.call(&"damage_amount"), 180.0, "damage")
	assert_true(bool(shot.call(&"bypasses_shield")), "bypass_shield")
	assert_true(bool(shot.call(&"is_destructible")), "a rocket is destructible")
	assert_eq(shot.call(&"velocity"), Vector2(900.0, 0.0), "direction x speed")
	assert_eq(StringName(shot.call(&"family")), &"missile", "the family follows the kind")
	assert_eq(shot.call(&"hit_radius"), ProjectileScript.HIT_RADIUS, "the detection radius")
	shot.free()


## A caller may hand `configure` plain String keys: the dictionary is normalized
## with StringName keys on the way in, so a typo in key *type* cannot silently fall
## back to a default.
func test_projectile_configure_accepts_string_keys() -> void:
	var shot := ProjectileScript.new() as Node2D
	shot.call(&"configure", {
		"kind": "slug",
		"speed": 1400.0,
		"damage": 36.0,
		"direction": Vector2.RIGHT,
	})
	assert_eq(shot.call(&"velocity"), Vector2(1400.0, 0.0), "String keys read the same")
	assert_eq(shot.call(&"damage_amount"), 36.0, "damage rides a String key too")
	assert_eq(StringName(shot.call(&"family")), &"kinetic", "a slug is kinetic")
	assert_false(bool(shot.call(&"is_destructible")), "a slug is not destructible")
	shot.free()


func test_projectile_kinds_map_to_the_families() -> void:
	assert_eq(ProjectileScript.KIND_FAMILIES[&"bolt"], &"kinetic")
	assert_eq(ProjectileScript.KIND_FAMILIES[&"slug"], &"kinetic")
	assert_eq(ProjectileScript.KIND_FAMILIES[&"rocket"], &"missile")
	assert_eq(ProjectileScript.KIND_FAMILIES[&"mine"], &"deployable")
	assert_true(ProjectileScript.DESTRUCTIBLE_KINDS.has(&"rocket"),
		"the rocket is named destructible")
	assert_eq(ProjectileScript.DESTRUCTIBLE_KINDS.size(), 1,
		"and it is the only kind that is")


## Section 4.6: a flare overrides the seeker's target (projectile.gd owns the
## retarget, weapons.gd owns the activation).
func test_projectile_retarget_takes_the_decoy() -> void:
	var shot := ProjectileScript.new() as Node2D
	var lock := Node2D.new()
	var decoy := Node2D.new()
	shot.call(&"configure", {&"kind": &"rocket", &"speed": 900.0, &"target": lock})
	assert_eq(shot.call(&"lock_target"), lock, "the lock target is stored")
	assert_eq(shot.call(&"decoy"), null, "no decoy yet")
	shot.call(&"retarget", decoy)
	assert_eq(shot.call(&"decoy"), decoy, "the decoy overrides the lock target")
	shot.free()
	lock.free()
	decoy.free()


func test_projectile_shapes_and_layers_are_projectile_owned() -> void:
	var shot := ProjectileScript.new() as Node2D
	shot.call(&"configure", {&"kind": &"bolt", &"speed": 1000.0, &"damage": 27.0})
	assert_eq(shot.get(&"collision_layer"), ProjectileScript.PROJECTILE_LAYER, "own layer")
	assert_true(shot.get(&"collision_layer") != ProjectileScript.ROCK_LAYER_MASK,
		"a shot is not a rock")
	assert_true(shot.get(&"collision_layer") != ProjectileScript.HULL_LAYER_MASK,
		"a shot is not a hull")
	assert_eq(ProjectileScript.TARGET_MASK,
		ProjectileScript.ROCK_LAYER_MASK | ProjectileScript.HULL_LAYER_MASK,
		"shots touch rocks and hulls")
	shot.free()
