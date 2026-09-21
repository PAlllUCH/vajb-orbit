@tool
extends McpTestSuite
## Suite engine2_npc: slice 2's NPC layer - the archetype registry and its section 13
## count shape (`npc_registry.gd`), the one brain (`npc_brain.gd`) and the hull's sink
## contract (`npc_ship.gd`).
##
## Pure logic: no physics world, no frames, no profile writes and no scene tree at all -
## the hull is instantiated bare and driven through `take_damage`, which is why
## `NpcShip.despawn` defers its free on the message queue outside a tree. The registry is
## read as data, the brain is walked on synthetic positions with an injected LOS verdict
## (the shipping rock-ray is measured in `tools/_probe_s2w3_npc.gd`, which can step
## frames).
##
## Contract: docs/gameplay/18_engine_spec.md sections 2, 4.2, 5, 7, 13; docs/gameplay/13
## sections 2-5; docs/gameplay/06 sections 3-4; the slice-2 brief's pinned items 5-7.

const Registry := preload("res://game/npc_registry.gd")
const Brain := preload("res://game/npc_brain.gd")
const Ship := preload("res://game/npc_ship.gd")
const Loot := preload("res://game/loot_tables.gd")
const SectorRegistry := preload("res://game/sector_registry.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const FRAME := 1.0 / 60.0

## The bare hulls and helper nodes this suite builds. `track()` is the editor runner's
## cleanup and the headless twin never calls it, so the suite frees its own nodes in
## `teardown`: a hull left alive leaks its rigid body, its shape and its sprite at exit.
var _ships: Array[Node] = []


func suite_name() -> String:
	return "engine2_npc"


func teardown() -> void:
	for node: Node in _ships:
		if is_instance_valid(node):
			node.free()
	_ships.clear()


## --- The registry: section 13's count shape ----------------------------------------


func test_registry_carries_the_section_5_archetypes_and_ruling_24_aliens() -> void:
	var ids := Registry.ids()
	for wanted: StringName in [
		&"pirate", &"patrol", &"trader", &"turret", &"hunter", &"boss", &"swarmer",
		&"sibelon", &"apex",
	]:
		assert_contains(ids, wanted, "archetype '%s' is registered" % wanted)
	assert_eq(ids.size(), 9, "nine rows: section 5's six plus ruling 24's three aliens")


func test_hostile_bands_sum_to_the_section_13_shape() -> void:
	var wanted: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8),
	]
	for index in wanted.size():
		var sector: StringName = &"sector_%d" % (index + 1)
		var pirate := Registry.density(&"pirate", sector)
		var swarmer := Registry.density(&"swarmer", sector)
		assert_eq(
			pirate + swarmer,
			wanted[index],
			"%s hostiles (pirate %s + swarmer %s) match section 13" % [sector, pirate, swarmer]
		)


func test_patrols_only_in_owned_space() -> void:
	for row: Dictionary in SectorRegistry.SECTORS:
		var sector := StringName(row[&"id"])
		var owned := StringName(row[&"owner"]) != SectorRegistry.UNALIGNED
		var band := Registry.density(&"patrol", sector)
		if owned:
			assert_eq(band, Registry.PATROL_PRESENCE, "%s is owned and patrolled" % sector)
		else:
			assert_eq(band, Vector2i.ZERO, "%s is unaligned: no patrols" % sector)


func test_one_convoy_per_inhabited_sector() -> void:
	for row: Dictionary in SectorRegistry.SECTORS:
		var sector := StringName(row[&"id"])
		var densities: Dictionary = row[&"densities"]
		var inhabited := int(densities[&"convoys"]) > 0
		var band := Registry.density(&"trader", sector)
		if inhabited:
			assert_gt(band.y, 0, "%s is inhabited: one convoy" % sector)
		else:
			assert_eq(band, Vector2i.ZERO, "%s is unaligned: no convoy" % sector)


func test_the_convoy_is_a_hauler_and_its_escorts() -> void:
	var rows := Registry.spawns_for(&"sector_1")
	var haulers := 0
	var escorts := 0
	for row: Dictionary in rows:
		if StringName(row[Registry.KEY_ARCHETYPE]) != &"trader":
			continue
		assert_eq(row[Registry.KEY_GROUP_KIND], &"convoy", "convoy members share the group")
		if StringName(row[Registry.KEY_HULL_ID]) == Registry.CONVOY_HAULER:
			haulers += 1
			assert_eq(
				Vector2i(int(row[&"min"]), int(row[&"max"])),
				Vector2i(1, 1),
				"section 5: 1 hauler"
			)
		else:
			escorts += 1
			assert_eq(
				Vector2i(int(row[&"min"]), int(row[&"max"])),
				Registry.CONVOY_ESCORTS,
				"section 5: 1-2 fighter escorts"
			)
	assert_eq(haulers, 1, "one hauler row")
	assert_eq(escorts, 1, "one escort row (its own 1-2 band)")


func test_seams_and_station_rows_never_spawn_with_a_sector() -> void:
	for row: Dictionary in SectorRegistry.SECTORS:
		var sector := StringName(row[&"id"])
		for spawn: Dictionary in Registry.spawns_for(sector):
			var id := StringName(spawn[Registry.KEY_ARCHETYPE])
			assert_ne(id, &"hunter", "hunters are a slice-4 seam")
			assert_ne(id, &"boss", "the boss is a slice-4 seam")
			assert_ne(id, &"sibelon", "the sibelon is a slice-3 seam")
			assert_ne(id, &"apex", "the apex is a slice-4 seam")
			assert_ne(id, &"turret", "a turret is mounted on a station, not spawned in a sector")


func test_sector_seven_is_the_hardcore_band() -> void:
	var total := Vector2i.ZERO
	for spawn: Dictionary in Registry.spawns_for(&"sector_7"):
		var id := StringName(spawn[Registry.KEY_ARCHETYPE])
		if id == &"pirate" or id == &"swarmer":
			total += Vector2i(int(spawn[&"min"]), int(spawn[&"max"]))
	assert_eq(total, Vector2i(6, 8), "S7 is section 13's 6-8, no patrol and no convoy")


func test_loot_bands_match_the_tables_that_serve_them() -> void:
	for row: Dictionary in Registry.NPCS:
		var kind := StringName(row[Registry.KEY_LOOT_KIND])
		if kind == &"":
			assert_false(
				Loot.has(kind),
				"%s rolls no 06 table and the pipeline refuses an empty kind"
				% row[Registry.KEY_ID]
			)
			continue
		assert_true(Loot.has(kind), "%s's loot kind '%s' has a table" % [row[Registry.KEY_ID], kind])
		var table: Dictionary = Loot.TABLES[kind]
		assert_eq(
			int(row[Registry.KEY_TIER]),
			int(table[&"band"]),
			"%s's band is the table's band" % row[Registry.KEY_ID]
		)


func test_sprite_paths_are_swap_ready_and_livery_aware() -> void:
	var swarmer := Registry.archetype(&"swarmer")
	assert_eq(
		Registry.sprite_path(swarmer, &""),
		"res://assets/ships/ship_swarmer_side.png",
		"ruling 24's alien hull is named by the row, not by its class row"
	)
	var pirate := Registry.archetype(&"pirate")
	assert_eq(
		Registry.sprite_path(pirate, &"concord"),
		"res://assets/ships/ship_fighter_side.png",
		"a factionless hull never wears a livery"
	)
	var patrol := Registry.archetype(&"patrol")
	assert_eq(
		Registry.sprite_path(patrol, &"concord"),
		"res://assets/ships/ship_patrol_side.png",
		"a patrol falls back to its plain hull when no liveried file exists"
	)


## --- The registry: doc 13's heat tiers --------------------------------------------


func test_heat_tiers_are_doc_13_section_3_thresholds() -> void:
	assert_eq(Registry.heat_tier(0), &"clean")
	assert_eq(Registry.heat_tier(19), &"clean")
	assert_eq(Registry.heat_tier(20), &"suspect")
	assert_eq(Registry.heat_tier(49), &"suspect")
	assert_eq(Registry.heat_tier(50), &"wanted")
	assert_eq(Registry.heat_tier(79), &"wanted")
	assert_eq(Registry.heat_tier(80), &"outlaw")
	assert_eq(Registry.heat_tier(100), &"outlaw")
	assert_true(Registry.tier_at_least(&"outlaw", &"suspect"), "outlaw reaches suspect")
	assert_false(Registry.tier_at_least(&"clean", &"suspect"), "clean does not reach suspect")
	assert_false(Registry.tier_at_least(&"clean", &""), "an empty tier is never reached")


## --- The brain: section 5's one state set -----------------------------------------


func _brain_for(id: StringName, los := true) -> RefCounted:
	var brain: RefCounted = Brain.new()
	brain.call(&"setup", id, Registry.archetype(id), Vector2.ZERO)
	if not los:
		brain.call(&"set_line_of_sight", Callable(self, &"_blind_los"))
	return brain


func _blind_los(_from: Vector2, _to: Vector2) -> bool:
	return false


func _player(pos: Vector2) -> Dictionary:
	return {
		&"pos": pos,
		&"velocity": Vector2.ZERO,
		&"is_player": true,
		&"archetype": &"",
		&"hostility": Registry.HOSTILITY_NONE,
	}


func _ctx(pos: Vector2, contacts: Array[Dictionary], tier: StringName = &"clean", hull := 1.0) -> Dictionary:
	return {
		Brain.CTX_POS: pos,
		Brain.CTX_HULL_FRACTION: hull,
		Brain.CTX_HOME: Vector2.ZERO,
		Brain.CTX_HEAT_TIER: tier,
		Brain.CTX_CONTACTS: contacts,
		Brain.CTX_ATTACKED: false,
	}


func test_the_brain_starts_idle_and_patrols_with_nothing_to_see() -> void:
	var brain := _brain_for(&"pirate")
	assert_eq(brain.call(&"state_name"), &"idle", "a fresh brain is Idle")
	var intent: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, []))
	assert_eq(StringName(intent[Brain.INTENT_STATE]), &"patrol", "then it patrols")
	assert_eq(brain.call(&"state_name"), &"patrol")


func test_aggro_alert_and_engage_at_the_section_13_radius() -> void:
	var brain := _brain_for(&"pirate")
	var far: Array[Dictionary] = [_player(Vector2(2000.0, 0.0))]
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, far))
	assert_eq(brain.call(&"state_name"), &"patrol", "2000 u is past the 900 u pirate radius")
	var near: Array[Dictionary] = [_player(Vector2(100.0, 0.0))]
	var blocked := _brain_for(&"pirate", false)
	blocked.call(&"tick", FRAME, _ctx(Vector2.ZERO, near))
	assert_eq(blocked.call(&"state_name"), &"alert", "in radius, LOS blocked by a rock")
	var clear: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, near))
	assert_eq(clear[Brain.INTENT_STATE], &"engage", "in radius and clear: engage")
	assert_true(bool(clear[Brain.INTENT_FIRE]), "and it wants to fire")


func test_aggro_lasts_the_cooldown_then_returns_home() -> void:
	var brain := _brain_for(&"pirate")
	var near: Array[Dictionary] = [_player(Vector2(100.0, 0.0))]
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, near))
	assert_eq(brain.call(&"state_name"), &"engage")
	var held := 0.0
	while held < Brain.AGGRO_COOLDOWN - FRAME:
		brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, []))
		held += FRAME
	assert_eq(brain.call(&"state_name"), &"engage", "aggro is held for AGGRO_COOLDOWN")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, []))
	assert_eq(brain.call(&"state_name"), &"return", "then it drops the target and goes home")


func test_pirates_flee_below_thirty_percent_hull() -> void:
	var brain := _brain_for(&"pirate")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"clean", 0.31))
	assert_ne(brain.call(&"state_name"), &"flee", "31 % is above section 13's threshold")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"clean", 0.29))
	assert_eq(brain.call(&"state_name"), &"flee", "29 % hull: the pirate runs")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"clean", 0.80))
	assert_eq(brain.call(&"state_name"), &"return", "a recovered hull heads back")


func test_traders_flee_from_a_suspect_player_anywhere_in_the_sector() -> void:
	var brain := _brain_for(&"trader")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"clean"))
	assert_ne(brain.call(&"state_name"), &"flee", "a Clean player is left alone")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"suspect"))
	assert_eq(brain.call(&"state_name"), &"flee", "doc 13 section 5: Suspect+ starts the run")
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, [], &"clean"))
	assert_eq(brain.call(&"state_name"), &"return", "the tier cools and it heads home")


func test_a_patrol_ignores_the_clean_scans_the_suspect_and_attacks_the_outlaw() -> void:
	var brain := _brain_for(&"patrol")
	var near: Array[Dictionary] = [_player(Vector2(200.0, 0.0))]
	brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, near, &"clean"))
	assert_eq(brain.call(&"state_name"), &"patrol", "a Clean player is ignored")
	var scan: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, near, &"suspect"))
	assert_eq(scan[Brain.INTENT_STATE], &"scan", "section 5: scans Suspect+ on sight")
	assert_false(bool(scan[Brain.INTENT_FIRE]), "a scan is not a fight")
	var engage: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, near, &"outlaw"))
	assert_eq(engage[Brain.INTENT_STATE], &"engage", "an Outlaw is fair game")
	assert_true(bool(engage[Brain.INTENT_FIRE]), "and it fires")


func test_the_leash_ends_a_chase_that_runs_past_it() -> void:
	var brain := _brain_for(&"patrol")
	var far_from_home := Vector2(Brain.LEASH_RADIUS + 100.0, 0.0)
	var near: Array[Dictionary] = [_player(far_from_home + Vector2(100.0, 0.0))]
	brain.call(&"tick", FRAME, _ctx(far_from_home, near, &"outlaw"))
	assert_eq(brain.call(&"state_name"), &"return", "past the leash the hull goes home")


func test_a_convoy_route_replaces_the_patrol_walk() -> void:
	var brain := _brain_for(&"trader")
	var route: Array[Vector2] = [Vector2(600.0, 0.0), Vector2(600.0, 600.0)]
	brain.call(&"set_route", route)
	var intent: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2.ZERO, []))
	assert_eq(intent[Brain.INTENT_WAYPOINT], route[0], "the convoy flies its fixed route")
	assert_eq(intent[Brain.INTENT_SPEED], Brain.CRUISE, "at the hull's full cruise")


func test_a_turret_is_static_and_waits_to_be_attacked() -> void:
	var brain := _brain_for(&"turret")
	var near: Array[Dictionary] = [_player(Vector2(200.0, 0.0))]
	var idle: Dictionary = brain.call(&"tick", FRAME, _ctx(Vector2(60.0, 0.0), near, &"outlaw"))
	assert_eq(idle[Brain.INTENT_STATE], &"idle", "an untriggered turret watches")
	assert_ne(StringName(brain.call(&"state_name")), &"engage", "and does not engage")
	assert_eq(idle[Brain.INTENT_SPEED], Brain.HOLD, "a turret never thrusts")
	var attacked := _ctx(Vector2(60.0, 0.0), near, &"clean")
	attacked[Brain.CTX_ATTACKED] = true
	var aggro: Dictionary = brain.call(&"tick", FRAME, attacked)
	assert_eq(aggro[Brain.INTENT_STATE], &"engage", "hit once, it engages even a Clean player")
	assert_eq(aggro[Brain.INTENT_WAYPOINT], Vector2(60.0, 0.0), "from where it is bolted")
	assert_eq(aggro[Brain.INTENT_SPEED], Brain.HOLD, "static: no movement, ever")


func test_a_swarmer_is_hostile_to_other_hulls_and_not_to_its_own_kind() -> void:
	var swarmer := Registry.archetype(&"swarmer")
	var pirate := Registry.archetype(&"pirate")
	var pirate_contact := {
		&"pos": Vector2.ZERO,
		&"is_player": false,
		&"archetype": &"pirate",
		&"hostility": pirate[Registry.KEY_HOSTILITY],
	}
	var swarm_contact := pirate_contact.duplicate()
	swarm_contact[&"archetype"] = &"swarmer"
	assert_true(
		Registry.is_hostile(swarmer, pirate_contact, &"clean", false),
		"ruling 24: hostile to everything"
	)
	assert_false(
		Registry.is_hostile(swarmer, swarm_contact, &"clean", false),
		"a swarm does not fire on its own kind"
	)


func test_the_hostility_rules_follow_the_section_5_table() -> void:
	var pirate := Registry.archetype(&"pirate")
	var patrol := Registry.archetype(&"patrol")
	var trader := Registry.archetype(&"trader")
	var player := _player(Vector2.ZERO)
	assert_true(Registry.is_hostile(pirate, player, &"clean", false), "pirates engage anyone")
	assert_false(Registry.is_hostile(trader, player, &"outlaw", false), "traders never initiate")
	assert_false(
		Registry.is_hostile(patrol, player, &"suspect", false),
		"a patrol scans a Suspect, it does not attack one"
	)
	assert_true(
		Registry.is_hostile(patrol, player, &"outlaw", false),
		"an Outlaw is attacked (doc 13 section 2)"
	)


## --- The hull: the sink contract ---------------------------------------------------


func _ship(archetype: StringName, hull: StringName, opts := {}) -> Node2D:
	var stats: ShipStats = ShipFitScript.resolve(hull, ShipFitScript.STANDARD_FIT)
	var node: Node2D = Ship.new()
	_ships.append(node)
	node.call(&"setup", archetype, stats, hull, opts)
	return node


func test_a_new_hull_reports_its_row_its_blip_and_its_heat() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	assert_eq(ship.call(&"archetype"), &"pirate")
	assert_eq(ship.call(&"blip_kind"), Registry.BLIP_HOSTILE, "section 8: pirates are hostile")
	assert_eq(ship.call(&"heat_on_kill"), -3, "doc 13 section 4: killing a pirate returns 3 heat")
	assert_eq(ship.call(&"standing_on_kill"), 1, "and gains 1 standing")
	var trader := _ship(&"trader", Registry.CONVOY_HAULER)
	assert_eq(trader.call(&"blip_kind"), Registry.BLIP_NEUTRAL, "section 8: a convoy is neutral")
	assert_eq(trader.call(&"heat_on_kill"), 15, "doc 13 section 2: a trader costs 15 heat")


func test_the_hull_body_mirrors_the_players_physics_contract() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var body := ship.call(&"impact_body") as RigidBody2D
	assert_true(body != null, "the hull builds its own rigid body")
	assert_eq(body.collision_layer, Ship.HULL_LAYER, "layer 2, the ship layer")
	assert_eq(body.collision_mask, Ship.HULL_MASK, "masking the rock layer only")
	assert_true(body.gravity_scale == 0.0, "space: no gravity")
	assert_true(body.contact_monitor, "a ram resolves through the contact monitor")
	assert_true(not body.can_sleep, "a hull always answers a contact")
	assert_eq(body.linear_damp_mode, RigidBody2D.DAMP_MODE_REPLACE, "the class damp replaces")
	assert_true(body.mass > 0.0, "mass comes from the section 13 class column")


func test_damage_is_shield_first_with_no_carry_over() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var shield_before: float = ship.call(&"shield")
	var hull_before: float = ship.call(&"hull")
	ship.call(&"take_damage", shield_before + 500.0, false, {})
	assert_true(
		is_equal_approx(float(ship.call(&"shield")), 0.0),
		"the shield takes the whole hit and empties"
	)
	assert_true(
		is_equal_approx(float(ship.call(&"hull")), hull_before),
		"section 4.2 item 1: no carry-over, the hull is untouched"
	)
	ship.call(&"take_damage", 40.0, true, {})
	assert_true(
		is_equal_approx(float(ship.call(&"hull")), hull_before - 40.0),
		"a bypassing hit lands on the hull"
	)


func test_the_hit_context_is_recorded_and_the_death_signal_fires() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var seen := {"count": 0, "archetype": &"", "position": Vector2.ZERO}
	ship.connect(&"died", func(position: Vector2, archetype: StringName) -> void:
		seen["count"] = int(seen["count"]) + 1
		seen["archetype"] = archetype
		seen["position"] = position)
	var ctx := {&"direction": 1.25, &"impulse": 12.0, &"family": &"collision"}
	ship.call(&"take_damage", 1.0, false, ctx)
	var recorded: Dictionary = ship.call(&"last_damage_ctx")
	assert_true(
		is_equal_approx(float(recorded[&"direction"]), 1.25),
		"section 4.2 item 5: the context is recorded, not applied"
	)
	ship.call(&"take_damage", 100000.0, true, {})
	assert_eq(int(seen["count"]), 1, "hull 0 raises `died` exactly once")
	assert_eq(StringName(seen["archetype"]), &"pirate", "with the archetype the wiring needs")
	assert_false(bool(ship.call(&"is_alive")), "the hull is dead")
	ship.call(&"take_damage", 10.0, true, {})
	assert_eq(int(seen["count"]), 1, "a dead hull takes nothing further")


func test_the_players_collision_door_charges_the_npc_side() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var shield_before: float = ship.call(&"shield")
	ship.call(&"apply_collision_damage", 30.0)
	assert_true(
		is_equal_approx(float(ship.call(&"shield")), shield_before - 30.0),
		"section 4.2 item 6: the peer's half lands shield-first"
	)


func test_a_despawn_is_not_a_kill() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var deaths := {"count": 0}
	ship.connect(&"died", func(_position: Vector2, _archetype: StringName) -> void:
		deaths["count"] = int(deaths["count"]) + 1)
	ship.call(&"despawn")
	assert_eq(int(deaths["count"]), 0, "section 5's recycle raises no death")
	assert_false(bool(ship.call(&"is_alive")), "and the hull is gone")


func test_engaged_with_is_false_until_the_brain_holds_the_player() -> void:
	var ship := _ship(&"pirate", &"ship_fighter")
	var player := Node2D.new()
	_ships.append(player)
	assert_false(
		bool(ship.call(&"engaged_with", player)),
		"section 7's gate: nothing is engaged before the brain has a target"
	)
	assert_eq(StringName(ship.call(&"state_name")), &"idle", "the state is published for the wiring")
	player.free()
