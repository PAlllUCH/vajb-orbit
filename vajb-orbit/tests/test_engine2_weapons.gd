@tool
extends McpTestSuite
## Suite engine2_weapons: the family table, the group/ammo seams and the projectile
## configuration of engine slice 2's W1 (ENGINE_SPEC sections 4.1, 4.3, 4.4, 4.6 and
## 13; docs/CONTRACTS.md sections 2/4/5/8.1).
##
## S5 (09 section 11, CONTRACTS section 17) adds the composed-rack seam: the racks are
## the player's mixed groups (`set_batteries`), the salvo gate is the slowest member's
## cycle, and the group key count is seven.
##
## Pure logic only, with one exception: the S4 volley's travelling half needs a world
## to spawn a shot into (`_spawn_shot` reads `get_tree()`), so those tests build the
## small tree-backed rig `_volley_rig` and nothing else leaves the tree. Every number
## here is checked against a hand transcription of section 13 (or section 4.1's prose),
## the same way the slice-0 probes do, so a drift in `weapons.gd` fails here. The timed
## half - firing each family, the range cap, the homing law, the mine's arm and
## trigger, the chaff window and the flare lure - needs stepped physics frames and
## is measured in `tools/_probe_s2w1_weapons.gd` (archived next to its log in
## `.agents/gen/`).

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const AUDIO_SERVICE: StringName = &"AudioManager"

## A sink that records what a beam's frame delivered, so the per-barrel damage read is
## a number and not a reading of the pipeline. `take_damage(amount, bypass)` is the
## pinned two-argument shape `_deliver` calls.
class DamageSink extends Node2D:
	var total := 0.0
	var hits := 0


	func take_damage(amount: float, _bypass_shield := false) -> void:
		total += amount
		hits += 1


## A battery whose beam resolves on a target without a physics world. The shipped
## `_beam_target` resolves through a ray query and a destructible shot on the segment
## takes the fizzle branch instead of the damage one, so a beam's frame cannot carry
## damage in a pure fixture; this double replaces the **targeting seam only** - the
## arming, the release, the per-barrel spend, the damage sum and the delivery are the
## shipped code's. The fixture's own target is a `DamageSink` in a tree.
class BeamTargetSpy extends "res://game/weapons.gd":
	var target: Node2D = null


	func _beam_target(from: Vector2, _to: Vector2) -> Dictionary:
		if target == null or not is_instance_valid(target):
			return {}
		return {
			&"point": target.global_position,
			&"collider": target,
			&"distance": from.distance_to(target.global_position),
			&"projectile": false,
		}


var _guns: Node2D = null
var _state: PlayerState = null
var _staged: Array[Node] = []

## The audio pools' round-robin cursors, saved and restored around every test. The
## volley's tree-backed rigs play the families' cues for real, and the laser pool's
## take order is asserted by `test_weapon_fx_f1` a few suites later - a cue this suite
## leaves spent would move that suite's first take (measured: it did, and this is the
## hygiene g2's own `_pool_state` exists for).
var _pool_state: Dictionary = {}
var _had_pool_state := false


func suite_name() -> String:
	return "engine2_weapons"


func setup() -> void:
	_save_pools()
	_guns = WeaponScript.new() as Node2D
	_state = PlayerStateScript.new()
	_state.setup()
	_guns.call(&"setup", null, _state)


func teardown() -> void:
	if _guns != null and is_instance_valid(_guns):
		_guns.free()
	_guns = null
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
	_clear_shots()
	_state = null
	_restore_pools()


func _audio() -> Node:
	var tree := _tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


func _save_pools() -> void:
	_pool_state = {}
	_had_pool_state = false
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_state = true
	_pool_state = (cursors as Dictionary).duplicate()


## `Object.get` hands the live dictionary, so the cursors are restored in place.
func _restore_pools() -> void:
	if not _had_pool_state:
		return
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_state, true)
	_pool_state = {}
	_had_pool_state = false


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


## **S5 (09 section 11, CONTRACTS section 17): the map holds seven keys**, so the clamp
## moved from five to `GROUPS_MAX` and a fit's **racks** - not its families - are what
## `weapon_1..7` addresses.
func test_groups_follow_the_fitted_order_and_clamp_to_weapon_1_7() -> void:
	var fit: Array[StringName] = [&"w_laser", &"cannon", &"rocket", &"mine", &"plasma"]
	_guns.call(&"set_fitted", fit)
	var fitted: Array = _guns.call(&"fitted")
	assert_eq(fitted.size(), 5, "the fit keeps its length")
	assert_eq(StringName(fitted[0]), &"laser", "module ids arrive as weapon ids")
	assert_eq(StringName(fitted[4]), &"plasma", "in group order")
	_guns.call(&"select_group", 3)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"rocket", "weapon_3 is the third")
	_guns.call(&"select_group", 9)
	assert_eq(
		int(_guns.call(&"selected_group")),
		WeaponScript.GROUPS_MAX,
		"a group past the map clamps to GROUPS_MAX"
	)
	assert_eq(WeaponScript.GROUPS_MAX, 7, "and the map is seven keys wide since S5")
	_guns.call(&"select_group", 0)
	assert_eq(int(_guns.call(&"selected_group")), 1, "a group below the map clamps to 1")


## Six families exist and the map now offers seven groups, so a six-weapon fit is
## selectable end to end. The list is kept whole rather than silently truncated, so the
## wiring layer can see any mismatch.
func test_a_six_weapon_fit_is_kept_whole() -> void:
	var fit: Array[StringName] = [&"laser", &"plasma", &"cannon", &"railgun", &"rocket", &"mine"]
	_guns.call(&"set_fitted", fit)
	assert_eq((_guns.call(&"fitted") as Array).size(), 6, "six weapons are fitted")
	_guns.call(&"select_group", 5)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"rocket", "group 5 is the fifth")
	_guns.call(&"select_group", 6)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"mine", "and group 6 the sixth")

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


## --- S4: batteries and the volley (CONTRACTS section 16, 09 section 10) ---
##
## A battery is the identical weapons fitted across W cells; one trigger pull
## discharges all of it. The shapes below are the pin's rules 1-3 and the volley is
## rule 4; the two that need a world to spawn a shot into (a travelling barrel) build
## one, because `_spawn_shot` has nowhere to put a shot outside a tree.


## CONTRACTS section 16 rule 1: one entry per barrel, fit order, duplicates kept - a
## Lancer's `[w_laser, w_laser]` reaches the component as two barrels, not one.
func test_fitted_keeps_one_entry_per_barrel() -> void:
	var fit: Array[StringName] = [&"w_laser", &"w_laser", &"w_laser"]
	_guns.call(&"set_fitted", fit)
	var fitted: Array = _guns.call(&"fitted")
	assert_eq(fitted.size(), 3, "N barrels keep N entries")
	assert_eq(StringName(fitted[0]), &"laser", "the module id normalizes")
	assert_eq(StringName(fitted[2]), &"laser", "and the order is the fit's own")
	var mixed: Array[StringName] = [&"cannon", &"w_laser", &"cannon"]
	_guns.call(&"set_fitted", mixed)
	var kept: Array = _guns.call(&"fitted")
	assert_eq(kept.size(), 3, "a mixed fit keeps its duplicates too")
	assert_eq(StringName(kept[1]), &"laser", "in place")
	assert_eq(StringName(kept[2]), &"cannon", "and in order")


## Rule 1's other half: the unknown and the family-less still drop, so a `w_mining`
## cell is never a dead barrel.
func test_fitted_still_drops_an_unknown_or_family_less_id() -> void:
	var fit: Array[StringName] = [&"w_mining", &"w_laser", &"w_nothing", &"w_laser"]
	_guns.call(&"set_fitted", fit)
	var fitted: Array = _guns.call(&"fitted")
	assert_eq(fitted.size(), 2, "the tool and the typo drop; both lasers stay")


## CONTRACTS section 16 rule 2: `battery_ids()` is the distinct ids of `fitted()` in
## first-barrel order.
func test_battery_ids_is_the_distinct_read_in_first_barrel_order() -> void:
	var fit: Array[StringName] = [&"w_laser", &"w_cannon", &"w_laser", &"cannon", &"w_rocket"]
	_guns.call(&"set_fitted", fit)
	var ids: Array = _guns.call(&"battery_ids")
	assert_eq(ids.size(), 3, "three distinct families, four barrels")
	assert_eq(StringName(ids[0]), &"laser", "in first-barrel order")
	assert_eq(StringName(ids[1]), &"cannon", "not catalogue order")
	assert_eq(StringName(ids[2]), &"rocket", "and never a duplicate")


## Rule 2: `weapon_1..5` addresses a **battery**, so a three-laser fit is one group
## and group 2 selects nothing (the pin's own consequence).
func test_groups_address_batteries_not_barrels() -> void:
	var fit: Array[StringName] = [&"w_laser", &"w_laser", &"w_laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"laser", "group 1 is the battery")
	_guns.call(&"select_group", 2)
	assert_eq(StringName(_guns.call(&"selected_weapon")), &"", "group 2 has no battery")
	assert_eq(StringName(_guns.call(&"dry_reason")), &"none", "and reports none")
	var two: Array[StringName] = [&"w_cannon", &"w_laser", &"w_cannon"]
	_guns.call(&"set_fitted", two)
	_guns.call(&"select_group", 2)
	assert_eq(
		StringName(_guns.call(&"selected_weapon")), &"laser", "the second battery is group 2"
	)


## CONTRACTS section 16 rule 3: barrel **positions in `fitted()`**, ascending,
## normalised through `weapon_id`, `[]` for a base with no firing family.
func test_battery_answers_positions_normalised_through_weapon_id() -> void:
	var fit: Array[StringName] = [&"w_laser", &"w_mining", &"w_cannon", &"w_laser"]
	_guns.call(&"set_fitted", fit)
	assert_eq(_guns.call(&"battery", &"w_laser"), [0, 2], "the module id answers")
	assert_eq(_guns.call(&"battery", &"laser"), [0, 2], "and so does the family id")
	assert_eq(_guns.call(&"battery", &"w_cannon"), [1], "the second battery's own positions")
	assert_eq(
		_guns.call(&"battery", &"w_mining"),
		[],
		"a family-less base answers nothing: its strip row exists, its trigger does not"
	)
	assert_eq(_guns.call(&"battery", &"w_nothing"), [], "and an unknown base answers nothing")


func test_the_strum_ceiling_is_the_pinned_number() -> void:
	assert_eq(WeaponScript.BATTERY_STRUM_MS, 40, "09 section 10's per-barrel ceiling, ms")


## --- S5: composed racks and the slowest-member salvo gate (CONTRACTS section 17) ---
##
## `set_batteries` hands the component the player-composed racks (the component's own
## index space: barrel positions into `fitted()`), a rack may mix kinds, and the salvo
## gate is `max(members' cadence)`. An empty spec keeps S4's grouping, so every pre-S5
## caller and fixture reads exactly what it always read.


## A composed spec is the rack list: the racks it names, in its order, then one trailing
## rack per barrel it does not mention - a fitted weapon is never left unfireable.
func test_composed_racks_follow_the_spec_and_claim_every_barrel() -> void:
	var fit: Array[StringName] = [&"cannon", &"laser", &"cannon", &"rocket"]
	_guns.call(&"set_fitted", fit)
	assert_eq(
		_guns.call(&"racks"),
		[[0, 2], [1], [3]],
		"with no spec, S4's grouping: the two cannons, the laser, the rocket"
	)
	_guns.call(&"set_batteries", [[0, 1], [2]])
	assert_eq(_guns.call(&"racks"), [[0, 1], [2], [3]], "the spec's racks, then the unclaimed barrel")
	assert_eq(int(_guns.call(&"rack_count")), 3, "three racks, three selectable keys")
	_guns.call(&"select_group", 1)
	assert_eq(_guns.call(&"selected_rack"), [0, 1], "rack 1 is the mixed pair")
	assert_eq(
		StringName(_guns.call(&"selected_weapon")), &"cannon", "whose representative is its first barrel"
	)
	_guns.call(&"select_group", 2)
	assert_eq(_guns.call(&"selected_rack"), [2], "rack 2 is the lone cannon")
	_guns.call(&"select_group", 3)
	assert_eq(_guns.call(&"selected_rack"), [3], "rack 3 the trailing rocket")
	_guns.call(&"select_group", 4)
	assert_eq(_guns.call(&"selected_rack"), [], "and rack 4 has no barrel")
	assert_eq(StringName(_guns.call(&"dry_reason")), &"none", "so the trigger is silent")


## A spec entry the fit cannot honour is dropped rather than trusted: a position past
## `fitted()` and one another rack already holds - and no barrel may be lost to it.
func test_a_spec_entry_the_fit_cannot_honour_is_dropped() -> void:
	var fit: Array[StringName] = [&"cannon", &"laser", &"cannon"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"set_batteries", [[0, 5], [0]])
	assert_eq(
		_guns.call(&"racks"),
		[[0], [], [1], [2]],
		"the duplicate and the out-of-range drop, the spec's empty rack kept for its ordinal, "
		+ "and the unclaimed barrels in their own racks"
	)
	_guns.call(&"set_batteries", [])
	assert_eq(
		_guns.call(&"racks"), [[0, 2], [1]], "an empty spec returns to S4's family grouping"
	)


## The salvo gate (09 section 11: "the rof will be limited by the slowest weapon"):
## `battery_cycle` is the selected rack's `max(members' cadence)`, so a mixed rack reads
## its slowest member and a rack of one family reads its own cadence.
func test_the_salvo_gate_is_the_slowest_members_cycle() -> void:
	var fit: Array[StringName] = [&"cannon", &"rocket", &"laser"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"set_batteries", [[0, 1, 2]])
	var slowest := maxf(
		WeaponScript.interval_of(&"cannon"),
		maxf(WeaponScript.interval_of(&"rocket"), WeaponScript.interval_of(&"laser"))
	)
	assert_eq(_guns.call(&"battery_cycle"), slowest, "the rack's own max(members' cadence)")
	assert_eq(_guns.call(&"battery_cycle"), 1.2, "cannon 0.6 + rocket 1.2 + laser 0 -> 1.2")
	_guns.call(&"set_batteries", [[0], [1, 2]])
	_guns.call(&"select_group", 1)
	assert_eq(_guns.call(&"battery_cycle"), 0.6, "a cannon rack reads 0.6")
	_guns.call(&"select_group", 2)
	assert_eq(_guns.call(&"battery_cycle"), 1.2, "and the rocket's rack 1.2")
	assert_eq(int(_guns.call(&"rack_cycle", 9)), 0, "an index outside the racks reads 0")


## The gate in flight: a held mixed rack fires one salvo per slowest-member cycle, and
## the member that fires travelling shots keeps that period. Measured over a 3.0 s hold at
## 1/60, the pair below is the shipped arithmetic - the laser states no cadence at all
## (`interval_of(&"laser") == 0.0`, an instant family) - so the pair's slowest member is
## the cannon's 0.6 s and the cannon's own salvo period must be that window, not a
## per-barrel one.
func test_a_held_mixed_rack_streams_at_its_slowest_members_cycle() -> void:
	var guns := _volley_rig()
	if guns == null:
		return
	_clear_shots()
	var fit: Array[StringName] = [&"cannon", &"laser"]
	guns.call(&"set_fitted", fit)
	guns.call(&"set_batteries", [[0, 1]])
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 30)
	guns.call(&"select_group", 1)
	var cycle: float = float(guns.call(&"battery_cycle"))
	var frame := 1.0 / 60.0
	var marks: Array[int] = []
	var beams := [0]
	var counter := [0]
	guns.connect(
		&"shot_fired",
		func(id: StringName) -> void:
			if id == &"cannon":
				marks.append(counter[0])
			else:
				beams[0] += 1
	)
	guns.call(&"set_firing", true)
	for index in int(3.0 / frame):
		counter[0] = index
		guns.call(&"tick", frame)
	print(
		"[s5-racks] mixed cannon+laser rack: cycle %.3f s, cannon salvos at %s, beam opens %d"
		% [cycle, str(marks), int(beams[0])]
	)
	assert_eq(cycle, 0.6, "the pair's slowest member is the cannon")
	assert_true(marks.size() >= 4, "a held rack streams, one salvo per slowest-member cycle")
	assert_eq(beams[0], 1, "and the beam member opened once for the whole hold")
	## The period is the rack's cycle with two sources of slack the pin states: the strum's
	## own 40 ms draw (2.4 frames) and the cannon's burst window, which can hold a barrel back
	## until the next on-window. Six frames (100 ms) covers both and still separates 0.6 s
	## from any per-barrel alternative a rack of this mix could have.
	var window := int(round(cycle / frame))
	for index in range(1, marks.size()):
		var gap: int = marks[index] - marks[index - 1]
		assert_true(
			absi(gap - window) <= 6,
			"salvo %d follows salvo %d by ~%d frames (measured %d)"
			% [index + 1, index, window, gap]
		)
	_release_trigger(guns, frame)


## Rule 6's per-barrel frame: every open barrel pays its family's `draw x delta`, so a
## three-laser battery burns three draws a frame. Measured against the one-barrel cost
## in the same pool.
func test_a_laser_battery_pays_a_draw_per_barrel_every_frame() -> void:
	var guns := _volley_rig([&"w_laser", &"w_laser", &"w_laser"])
	if guns == null:
		return
	var frame := 0.1
	var cost := float(WeaponScript.row_of(&"laser")[&"draw"]) * frame
	var before := _state.energy
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	guns.call(&"set_firing", true)
	guns.call(&"tick", frame)
	assert_true(
		_near(_state.energy, before - cost * 3.0),
		"three barrels, three draws: %.3f Energy for one frame (expected %.3f)"
		% [before - _state.energy, cost * 3.0]
	)
	## And the shaft is up: the battery opened on the pull's own frame.
	var halo := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D
	assert_true(halo != null and halo.visible, "the battery's one shaft is drawn")
	_release_trigger(guns, frame)


## Rule 6: "a pool that cannot pay a barrel's frame makes that barrel dry for that
## frame while the barrels before it keep drawing" - the earlier barrels pay, the
## later one is dry, and nothing aborts.
func test_a_pool_that_cannot_pay_one_barrel_leaves_the_others_drawing() -> void:
	var guns := _volley_rig([&"w_laser", &"w_laser", &"w_laser"])
	if guns == null:
		return
	var frame := 0.1
	var cost := float(WeaponScript.row_of(&"laser")[&"draw"]) * frame
	_state.set_energy(cost * 2.0)
	var dry := [0]
	var dry_id := [&""]
	guns.connect(&"dry_fired", func(id: StringName) -> void:
		dry[0] += 1
		dry_id[0] = id
	)
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	guns.call(&"set_firing", true)
	guns.call(&"tick", frame)
	assert_eq(_state.energy, 0.0, "the two barrels the pool could pay, paid")
	assert_eq(dry[0], 1, "the third is dry once")
	assert_eq(StringName(dry_id[0]), &"laser", "and names the family it could not pay")
	var halo := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D
	assert_true(halo != null and halo.visible, "and the barrels before it keep drawing")
	_release_trigger(guns, frame)


## Rule 6's per-barrel damage: the frame's delivery is the sum of the barrels that
## paid, so three open lasers deal three lasers' worth in one read.
func test_the_beam_frame_damage_is_the_open_barrels_sum() -> void:
	var sink := DamageSink.new()
	var row: Dictionary = WeaponScript.row_of(&"laser")
	var delta := 0.1
	_guns.call(&"_apply_beam", &"laser", row, sink, Vector2.ZERO, delta, 1.0)
	var one := sink.total
	assert_true(_near(one, WeaponScript.dps_of(&"laser") * delta), "one barrel: dps x delta")
	_guns.call(&"_apply_beam", &"laser", row, sink, Vector2.ZERO, delta, 3.0)
	assert_true(
		_near(sink.total - one, one * 3.0),
		"three barrels: three times the one-barrel frame (%.3f, expected %.3f)"
		% [sink.total - one, one * 3.0]
	)
	assert_eq(sink.hits, 2, "and the frame is still one delivery, not one per barrel")
	sink.free()


## The same reading end to end: a laser battery whose beam resolves on a target deals
## the sum of its barrels' frames, not one barrel's. The target comes from
## `BeamTargetSpy` because a movable target needs a physics world this suite does not
## build, so only the targeting seam is the double's.
func test_a_laser_battery_deals_one_frame_of_damage_per_barrel() -> void:
	var guns := _volley_rig([&"w_laser", &"w_laser", &"w_laser"], true)
	if guns == null:
		return
	var delta := 0.1
	var sink := DamageSink.new()
	guns.get_parent().add_child(sink)
	_staged.append(sink)
	guns.set(&"target", sink)
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	guns.call(&"set_firing", true)
	guns.call(&"tick", delta)
	var expected := WeaponScript.dps_of(&"laser") * delta * 3.0
	assert_true(
		_near(sink.total, expected),
		"three barrels deliver three frames (%.3f damage, expected %.3f)"
		% [sink.total, expected]
	)
	assert_eq(sink.hits, 1, "as one delivery for the frame, not three")
	_release_trigger(guns, delta)


## Rule 4, the volley itself: one pull, one round per barrel out of the family's one
## pack (rule 5), and every barrel's own shot on its own release offset - all inside
## `BATTERY_STRUM_MS`.
func test_a_volley_charges_one_round_per_barrel_from_the_one_pack() -> void:
	var guns := _volley_rig()
	if guns == null:
		return
	_clear_shots()
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 30)
	var shots := [0]
	guns.connect(&"shot_fired", func(_id: StringName) -> void: shots[0] += 1)
	guns.call(&"set_firing", true)
	var fired_at: Array[int] = []
	for frame in 60:
		var before: int = shots[0]
		guns.call(&"tick", 0.001)
		for _released in shots[0] - before:
			fired_at.append(frame + 1)
	assert_eq(shots[0], 3, "one trigger pull discharges all three barrels")
	assert_eq(30 - int(_state.ammo[slot]), 3, "three rounds leave the one cannon pack")
	assert_eq(3, _shots().size(), "and three shots are in the world")
	assert_eq(fired_at.size(), 3, "one release per barrel")
	assert_eq(fired_at[0], 1, "the lead barrel releases on the pull's own frame")
	assert_true(
		fired_at[2] <= WeaponScript.BATTERY_STRUM_MS,
		"and the last barrel is inside the %d ms ceiling (measured %d ms)"
		% [WeaponScript.BATTERY_STRUM_MS, fired_at[2]]
	)
	print(
		"[s4-weapons] volley: releases at %s ms, ceiling %d, pack 30 -> %d"
		% [str(fired_at), WeaponScript.BATTERY_STRUM_MS, int(_state.ammo[slot])]
	)


## Rule 4's per-barrel damage for a travelling family: each released barrel spawns its
## own shot carrying its own `shot_damage`, so a three-cannon battery delivers three
## cannon rounds rather than one.
func test_each_released_barrel_spawns_its_own_shot_with_its_own_damage() -> void:
	var guns := _volley_rig()
	if guns == null:
		return
	_clear_shots()
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 30)
	guns.call(&"set_firing", true)
	for _frame in 60:
		guns.call(&"tick", 0.001)
	var shots := _shots()
	assert_eq(shots.size(), 3, "three barrels, three shots")
	var per_shot := WeaponScript.shot_damage(&"cannon")
	for shot: Node in shots:
		assert_eq(
			float(shot.call(&"damage_amount")),
			per_shot,
			"each shot carries the cannon's own shot damage"
		)


## Rule 4: a barrel the family refuses is dry and never holds the battery back. The
## pack holds one round, so exactly one barrel leaves and the rest read dry once per
## pull.
func test_a_dry_barrel_does_not_hold_the_battery_back() -> void:
	var guns := _volley_rig()
	if guns == null:
		return
	_clear_shots()
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 1)
	var shots := [0]
	var dry := [0]
	guns.connect(&"shot_fired", func(_id: StringName) -> void: shots[0] += 1)
	guns.connect(&"dry_fired", func(_id: StringName) -> void: dry[0] += 1)
	guns.call(&"set_firing", true)
	for _frame in 60:
		guns.call(&"tick", 0.001)
	assert_eq(shots[0], 1, "the one round the pack held left")
	assert_eq(int(_state.ammo[slot]), 0, "and the pack is empty")
	assert_eq(dry[0], 1, "the refused barrels read dry once per pull, not once per barrel")
	assert_eq(_shots().size(), 1, "and the dry barrels spawn nothing")


## Rule 4's **stream**, the S4-H4 HIGH F1's regression test: a held trigger fires a salvo and
## then another one every time the barrels' own cadence timers come round, instead of one salvo
## and silence. The pre-S4 component streamed at the family's cadence through its single
## `_shot_timer` (`f3b0d24:vajb-orbit/game/weapons.gd:527`, `:601-617`), so one timer per barrel
## must stream too - three cannons, whose cadence is their 0.6 s burst cycle, deliver three
## shots per window and never a window with none. The defect measured before the fix: one 3.0 s
## pull gave 3 shots and then ~2 976 frames with zero.
func test_a_held_pull_streams_a_salvo_per_barrel_cadence() -> void:
	var guns := _volley_rig()
	if guns == null:
		return
	_clear_shots()
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 30)
	var cadence := WeaponScript.interval_of(&"cannon")
	var frame := 1.0 / 60.0
	var windows := 5
	var shots := [0]
	guns.connect(&"shot_fired", func(_id: StringName) -> void: shots[0] += 1)
	guns.call(&"set_firing", true)
	var releases: Array[int] = []
	## Exactly the five cadence windows are stepped: the stream is continuous, so a frame past
	## the last window's end would open the next salvo and count it.
	for index in int(float(windows) * cadence / frame):
		var before: int = shots[0]
		guns.call(&"tick", frame)
		for _release in int(shots[0]) - before:
			releases.append(index)
	print(
		"[s4-weapons] held pull: %d shots = %d windows x 3 barrels, releases at %s frames"
		% [int(shots[0]), windows, str(releases)]
	)
	assert_eq(
		int(shots[0]),
		windows * 3,
		"a 3.0 s pull streams one three-barrel salvo per 0.6 s cadence window, not one salvo"
	)
	assert_eq(30 - int(_state.ammo[slot]), windows * 3, "and one round leaves the pack per barrel")
	## Every window carries its own whole salvo: a window with fewer than three shots is the
	## silence F1 measured, however the release offsets fall.
	var per_window := int(cadence / frame)
	for window in windows:
		var first := window * per_window
		var inside := 0
		for at: int in releases:
			if at >= first and at < first + per_window:
				inside += 1
		assert_eq(
			inside,
			3,
			"cadence window %d carries the battery's whole salvo (release frames %s)"
			% [window + 1, str(releases)]
		)
	_release_trigger(guns, frame)


## The stream's one carve-out among the travelling families (rule 4 as built): the mine is a
## "drop", not a "held" family - 09 section 3.1's `edge` row, one release per trigger pull,
## which the pre-S4 `_fire_projectile` read from the same flag. A re-arming battery must not
## turn a held pull into a minefield.
func test_a_held_pull_keeps_the_mine_to_one_release() -> void:
	var guns := _volley_rig([&"w_mine"])
	if guns == null:
		return
	_clear_shots()
	var slot := WeaponScript.ammo_slot(&"mine")
	_state.set_ammo(slot, 10)
	var shots := [0]
	guns.connect(&"shot_fired", func(_id: StringName) -> void: shots[0] += 1)
	guns.call(&"set_firing", true)
	for _frame in 180:
		guns.call(&"tick", 1.0 / 60.0)
	assert_eq(shots[0], 1, "a held pull drops one mine, however long it is held")
	assert_eq(int(_state.ammo[slot]), 9, "and spends one round")
	## A second pull drops the next one: the arm is the pull, not the frame.
	_release_trigger(guns, 1.0 / 60.0)
	guns.call(&"set_firing", true)
	guns.call(&"tick", 1.0 / 60.0)
	assert_eq(shots[0], 2, "and the next pull drops its own")
	assert_eq(_shots().size(), 2, "two pulls, two mines in the world")
	_release_trigger(guns, 1.0 / 60.0)


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


## A battery on a component that lives in a tree. Two things need one: a travelling
## barrel's shot is spawned into the world (`_spawn_shot` reads `get_tree()`), and an
## instant barrel's muzzle flash is an `AnimatedSprite2D` that has to play somewhere
## (an untreed sprite logs `data.tree is null`). The host is the profile autoload
## because the runner calls every test from inside its own `_ready`, where `/root`
## refuses children (measured; the wiring suite's note). Returns null - and the caller
## skips - when the runner has no profile to hang the rig on.
func _volley_rig(ids: Array = [], spy := false) -> Node2D:
	var host := _service()
	if host == null:
		skip("no PlayerProfile autoload in this runner, so the rig has no host")
		return null
	var holder := Node2D.new()
	holder.name = &"S4VolleyRig"
	host.add_child(holder)
	var guns: Node2D = (BeamTargetSpy.new() if spy else WeaponScript.new()) as Node2D
	holder.add_child(guns)
	guns.call(&"setup", null, _state)
	var fit: Array[StringName] = []
	for id: Variant in (ids if not ids.is_empty() else [&"w_cannon", &"w_cannon", &"w_cannon"]):
		fit.append(StringName(id))
	guns.call(&"set_fitted", fit)
	_staged.append(holder)
	return guns


## Release the trigger and step one frame: the beam goes out and the bed with it, so a
## fixture that opened a shaft does not leave one sounding into the next suite.
func _release_trigger(guns: Node2D, delta := 0.1) -> void:
	guns.call(&"set_firing", false)
	guns.call(&"tick", delta)


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## The live shots in the world. The rig's own shots are what the volley's counts read,
## so the suite clears the group before and after every travelling test.
func _shots() -> Array[Node]:
	var tree := _tree()
	if tree == null:
		return []
	return tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP)


func _clear_shots() -> void:
	for shot: Node in _shots():
		if is_instance_valid(shot):
			shot.free()


func _near(measured: float, expected: float, tolerance := 0.0001) -> bool:
	return absf(measured - expected) <= tolerance


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
