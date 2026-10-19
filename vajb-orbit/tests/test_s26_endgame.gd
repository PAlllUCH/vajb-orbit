@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s26_endgame: wave S26's endgame - the two physical arenas and their contract run
## (14_station_services.md section 5), the three released bosses and the Maw's 06 section
## 3.4 table, death persistence (18_engine_spec section 2 dec. 7 / section 7), insurance
## (14 section 3, M14) and per-station vaults (14 section 4), plus the INSURANCE and
## VAULTS panels of docs/design/STATION_HUB.md sections 15.3/15.4.
##
## One row per pinned acceptance (A1-A8). The law's figures appear only as the expected
## side of a comparison; every shipped number is read from its own owner (NpcRegistry,
## ContractRegistry, PlayerProfile, StationRegistry, LootTables, ComponentCatalog).

const NpcRegistryScript := preload("res://game/npc_registry.gd")
const ContractRegistryScript := preload("res://game/contract_registry.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const LootTablesScript := preload("res://game/loot_tables.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const StationCatalogScript := preload("res://game/station_catalog.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const GameScript := preload("res://game/game.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const GAME_SCENE := "res://game/game.tscn"

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s26_endgame.cfg"
const HOST := Vector2(1920.0, 1080.0)
const NOW := 4000000
const NEUTRAL := 0

## 14 section 5's two arenas and their bosses (R-S26-1).
const ARENA_SECTOR := 3
const OTHER_ARENA_SECTOR := 6
const NO_ARENA_SECTOR := 1

## 14's 2026-10-08 S28 block (M10), verbatim.
const BONEYARD_PAYOUT := 6000
const PYRE_PAYOUT := 12000
## 06 section 3.4's own figures (component values from 03's catalogue).
const MAW_EV := 1584.75
const MAW_FLOOR := 1025

var _profile: ProfileScript = null
var _station: Control = null
var _scenes: Array[Node] = []
var _previous: Dictionary = {}
var _ledger: Array = []


func suite_name() -> String:
	return "s26_endgame"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the station")
		return
	var service := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = service
	_previous = {
		&"save_path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
		&"contracts": (_profile.call(&"contracts") as Array).duplicate(true),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"docked_station": StringName(_profile.call(&"docked_station")),
		&"owned": (_profile.get(&"_owned_ships") as Array).duplicate(),
		&"active": StringName(_profile.call(&"active_ship")),
		&"vaults": (_profile.call(&"vaults") as Dictionary).duplicate(true),
		&"insured": bool(_profile.call(&"insured")),
		&"mercy": bool(_profile.call(&"mercy_used")),
		&"arena_runs": (_profile.call(&"arena_runs") as Dictionary).duplicate(true),
		&"modules": (_profile.get(&"_modules") as Dictionary).duplicate(true),
		&"fits": (_profile.get(&"_fits") as Dictionary).duplicate(true),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)
	## The flight scene's wreck ledger is a static; hand it back untouched at the end.
	_ledger = GameScript._wreck_drops.duplicate(true)
	_wipe()


func suite_teardown() -> void:
	_free_station()
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	GameScript._wreck_drops.clear()
	GameScript._wreck_drops.append_array(_ledger)
	if _profile == null:
		return
	for key: StringName in _previous:
		var value: Variant = _previous[key]
		match key:
			&"save_path":
				_profile.call(&"flush")
				_profile.set(&"save_path", String(value))
			&"credits":
				_profile.set(&"_credits", int(value))
			&"cargo":
				_profile.set(&"_cargo", value)
			&"contracts":
				_profile.call(&"set_contracts", value)
			&"standing":
				_profile.call(&"set_standing", value)
			&"docked_station":
				_profile.call(&"set_docked_station", value)
			&"owned":
				_profile.set(&"_owned_ships", value)
			&"active":
				_profile.set(&"_active_ship", value)
			&"vaults":
				_profile.call(&"set_vaults", value)
			&"insured":
				_profile.call(&"set_insured", bool(value))
			&"mercy":
				_profile.call(&"set_mercy_used", bool(value))
			&"arena_runs":
				_profile.call(&"set_arena_runs", value)
			&"modules":
				_profile.set(&"_modules", value)
			&"fits":
				_profile.set(&"_fits", value)
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	Support.delete_file(PROFILE_PATH)
	_previous = {}
	_profile = null


func setup() -> void:
	_free_station()
	_wipe()


## A clean account: the default Cutter, a full purse, no cargo, no contracts, no vaults.
func _wipe() -> void:
	if _profile == null:
		return
	_profile.call(&"set_contracts", [])
	_profile.call(&"set_standing", {})
	_profile.call(&"set_docked_station", &"")
	_profile.call(&"set_vaults", {})
	_profile.call(&"set_insured", false)
	_profile.call(&"set_mercy_used", false)
	_profile.set(&"_insurance_paid_out", false)
	_profile.call(&"set_arena_runs", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_fits", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_credits", 50000)
	_set_owned([ProfileScript.DEFAULT_SHIP])
	_profile.set(&"_active_ship", ProfileScript.DEFAULT_SHIP)


## The owned fleet is a typed `Array[StringName]`; a plain literal would leave it untyped
## and break `owned_ships()`'s own typed build.
func _set_owned(ships: Array) -> void:
	var typed: Array[StringName] = []
	for id: Variant in ships:
		typed.append(StringName(id))
	_profile.set(&"_owned_ships", typed)


func _free_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
		_station = null

func _mount() -> Control:
	var host := Control.new()
	host.name = "S26Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_profile.add_child(scene)
	_scenes.append(scene)
	return scene


## ------------------------------------------------------------------ A1: arenas are places


## A1: the two arenas exist as data - a boss, a name, a centre and a ring - in their own
## sectors, and no other sector has one.
func test_a1_the_two_arenas_are_physical_places() -> void:
	assert_true(NpcRegistryScript.has_arena(ARENA_SECTOR), "S3 carries The Boneyard")
	assert_true(NpcRegistryScript.has_arena(OTHER_ARENA_SECTOR), "S6 carries The Pyre")
	assert_false(NpcRegistryScript.has_arena(NO_ARENA_SECTOR), "S1 carries no arena")
	var boneyard := NpcRegistryScript.arena_zone(ARENA_SECTOR)
	assert_eq(String(boneyard.get(&"name", "")), "The Boneyard", "the Meridian arena's name")
	assert_eq(
		NpcRegistryScript.arena_boss(ARENA_SECTOR), NpcRegistryScript.ARCHETYPE_BONEYARD,
		"and its boss"
	)
	var pyre := NpcRegistryScript.arena_zone(OTHER_ARENA_SECTOR)
	assert_eq(String(pyre.get(&"name", "")), "The Pyre", "the Choir arena's name")
	assert_eq(
		NpcRegistryScript.arena_boss(OTHER_ARENA_SECTOR), NpcRegistryScript.ARCHETYPE_PYRE,
		"and its boss"
	)
	assert_gt(NpcRegistryScript.ARENA_ZONE_RADIUS, 0.0, "the ring has a radius")
	assert_gt(NpcRegistryScript.ARENA_ZONE_PYLONS, 0, "and nav pylons")
	assert_gt(NpcRegistryScript.ARENA_ZONE_BARRICADES, 0, "and barricades")
	assert_true(
		ResourceLoader.exists(NpcRegistryScript.PYLON_TEXTURE), "the pylon render ships"
	)
	assert_true(
		ResourceLoader.exists(NpcRegistryScript.BARRICADE_TEXTURE), "the barricade render ships"
	)


## A1: the ring is built from the shipped parts as a child of the sector, and entering it
## without an active run does nothing.
func test_a1_the_ring_builds_and_an_idle_entry_does_nothing() -> void:
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	game.call(&"on_route", {GameScript.PARAM_SECTOR: "sector_3"})
	var ring: Node2D = game.get(&"_arena_zone_node") as Node2D
	assert_true(ring != null and is_instance_valid(ring), "S3's arena ring is built")
	assert_eq(
		ring.get_child_count(),
		NpcRegistryScript.ARENA_ZONE_PYLONS + NpcRegistryScript.ARENA_ZONE_BARRICADES,
		"the pylons and the barricades are all there"
	)
	## No active run: entering the ring spawns nothing.
	var ship: Node2D = game.get(&"_ship")
	var centre: Vector2 = game.get(&"_sector").to_global(
		NpcRegistryScript.arena_zone(ARENA_SECTOR).get(&"centre", Vector2.ZERO)
	)
	ship.global_position = centre
	game.call(&"_update_arena", 0.0)
	assert_true(game.get(&"_arena_boss") == null, "an idle entry marks the place and nothing else")


## ------------------------------------------------------------------ A2: the arena loop


## A2: the Expedition row is live at an arena station and still the greyed seam elsewhere.
func test_a2_the_expedition_row_is_live_at_the_arena() -> void:
	var arena_board := ContractRegistryScript.board(
		StationRegistryScript.station(&"s3_primary"), NEUTRAL, NOW
	)
	var arena_row := _expedition(arena_board)
	assert_false(arena_row.is_empty(), "the board carries an Expedition row")
	assert_false(bool(arena_row.get(&"staged", false)), "and it is live at the arena (U7 un-greys)")
	assert_eq(
		StringName(arena_row.get(&"boss", &"")), NpcRegistryScript.ARCHETYPE_BONEYARD,
		"and names the arena's boss"
	)
	var quiet_board := ContractRegistryScript.board(
		StationRegistryScript.station(&"s1_primary"), NEUTRAL, NOW
	)
	var quiet_row := _expedition(quiet_board)
	assert_false(quiet_row.is_empty(), "S1 still draws the row")
	assert_true(bool(quiet_row.get(&"staged", false)), "but it stays the greyed seam there")


## A2: accept opens a 60 s window, and the boss's 20-minute cooldown refuses a second run.
func test_a2_accept_opens_a_window_and_the_cooldown_gates() -> void:
	var row := StationRegistryScript.station(&"s3_primary")
	var board := ContractRegistryScript.board(row, NEUTRAL, NOW)
	var expedition := _expedition(board)
	var result := ContractRegistryScript.accept(_profile, row, NEUTRAL, expedition)
	assert_true(bool(result.get(&"ok", false)), "the arena contract is accepted")
	var record: Dictionary = result.get(&"contract", {})
	var opened := int(record.get(&"accepted_at", 0))
	assert_eq(
		int(record.get(&"arena_expires", 0)), opened + int(ContractRegistryScript.ARENA_ENTRY_WINDOW),
		"the 60 s entry window opens at accept"
	)
	assert_true(
		ContractRegistryScript.arena_entry_open(record, opened + 1), "inside the window it is open"
	)
	assert_false(
		ContractRegistryScript.arena_entry_open(record, opened + 61), "past it, it is closed"
	)
	## The run is on the boss's clock now: a second accept for the same boss is refused.
	var second := ContractRegistryScript.board(row, NEUTRAL, NOW)
	var refused := ContractRegistryScript.accept(_profile, row, NEUTRAL, _expedition(second))
	assert_eq(
		StringName(refused.get(&"reason", &"")), ContractRegistryScript.REASON_COOLDOWN,
		"one run per boss per 20-minute clock"
	)
	## Twenty minutes later the boss is ready again.
	_profile.call(&"arena_mark_run", NpcRegistryScript.ARCHETYPE_BONEYARD, opened - 1200)
	assert_true(
		bool(_profile.call(&"arena_ready", NpcRegistryScript.ARCHETYPE_BONEYARD, opened)),
		"and ready once the clock has passed"
	)


## A2: kill credit is the player's last hit - a run without it pays nothing, and the
## payout lands at return-to-station when the player landed the kill.
func test_a2_kill_credit_pays_and_a_stolen_kill_does_not() -> void:
	var row := StationRegistryScript.station(&"s3_primary")
	var board := ContractRegistryScript.board(row, NEUTRAL, NOW)
	var accepted := ContractRegistryScript.accept(_profile, row, NEUTRAL, _expedition(board))
	var id := StringName((accepted.get(&"contract", {}) as Dictionary).get(&"id", &""))
	var before := int(_profile.call(&"credits"))
	var stolen := ContractRegistryScript.arena_settle(_profile, id)
	assert_eq(int(stolen.get(&"paid", 0)), 0, "a run with no kill credit pays nothing")
	assert_eq(int(_profile.call(&"credits")), before, "and writes no credits")
	assert_eq(ContractRegistryScript.active_count(_profile), 0, "the run still closes on return")
	## A fresh run with the player's own last hit pays M10's figure and rolls a module.
	_profile.call(&"arena_mark_run", NpcRegistryScript.ARCHETYPE_BONEYARD, 0)
	var board2 := ContractRegistryScript.board(row, NEUTRAL, NOW + 60)
	var accepted2 := ContractRegistryScript.accept(_profile, row, NEUTRAL, _expedition(board2))
	var id2 := StringName((accepted2.get(&"contract", {}) as Dictionary).get(&"id", &""))
	assert_true(
		ContractRegistryScript.arena_credit_kill(_profile, NpcRegistryScript.ARCHETYPE_BONEYARD),
		"the player's last hit credits the kill"
	)
	var purse := int(_profile.call(&"credits"))
	var paid := ContractRegistryScript.arena_settle(_profile, id2)
	assert_eq(int(paid.get(&"paid", 0)), BONEYARD_PAYOUT, "the Boneyard pays 6 000 CR (M10)")
	assert_eq(int(_profile.call(&"credits")), purse + BONEYARD_PAYOUT, "and the purse moves")
	assert_ne(StringName(paid.get(&"module", &"")), &"", "plus its reward module")


## A2: the scene spawns the boss when the run is open and the ship is inside the ring.
func test_a2_the_scene_spawns_the_boss_in_the_ring() -> void:
	_profile.call(&"set_docked_station", &"s3_primary")
	var row := StationRegistryScript.station(&"s3_primary")
	var board := ContractRegistryScript.board(row, NEUTRAL, NOW)
	ContractRegistryScript.accept(_profile, row, NEUTRAL, _expedition(board))
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	game.call(&"on_route", {GameScript.PARAM_SECTOR: "sector_3"})
	var centre: Vector2 = game.get(&"_sector").to_global(
		NpcRegistryScript.arena_zone(ARENA_SECTOR).get(&"centre", Vector2.ZERO)
	)
	(game.get(&"_ship") as Node2D).global_position = centre
	game.call(&"_update_arena", 0.0)
	var boss: Node2D = game.get(&"_arena_boss") as Node2D
	assert_true(boss != null and is_instance_valid(boss), "the boss spawned on entry")
	assert_eq(StringName(boss.call(&"archetype")), NpcRegistryScript.ARCHETYPE_BONEYARD, "the Boneyard")


## ------------------------------------------------------------------ A3: the bosses


## A3: the three boss rows carry R-S26-1's vitals and weapon counts.
func test_a3_the_boss_rows_match_r_s26_1() -> void:
	var gunship := ShipFitScript.resolve(&"ship_gunship", ShipFitScript.STANDARD_FIT)
	var boneyard := NpcRegistryScript.boss_stats(NpcRegistryScript.ARCHETYPE_BONEYARD)
	assert_eq(boneyard.hull_max, gunship.hull_max * 2.5, "the Boneyard is gunship-tier x2.5")
	assert_eq(boneyard.shield_max, gunship.shield_max * 2.5, "its shield too")
	assert_eq(
		NpcRegistryScript.boss_weapons(NpcRegistryScript.ARCHETYPE_BONEYARD), 5, "5 weapons"
	)
	var frigate := ShipFitScript.resolve(&"ship_patrol", ShipFitScript.STANDARD_FIT)
	var pyre := NpcRegistryScript.boss_stats(NpcRegistryScript.ARCHETYPE_PYRE)
	assert_eq(pyre.hull_max, frigate.hull_max * 2.5, "the Pyre is frigate-tier x2.5")
	assert_eq(NpcRegistryScript.boss_weapons(NpcRegistryScript.ARCHETYPE_PYRE), 4, "4 weapons")
	var maw := NpcRegistryScript.boss_stats(NpcRegistryScript.ARCHETYPE_MAW)
	assert_eq(maw.hull_max, 12000.0, "the Maw's hull is 12 000")
	assert_eq(maw.shield_max, 6000.0, "and its shield 6 000")
	assert_eq(NpcRegistryScript.boss_weapons(NpcRegistryScript.ARCHETYPE_MAW), 7, "7 weapons")
	var freighter := ShipFitScript.resolve(&"ship_freighter", ShipFitScript.STANDARD_FIT)
	assert_eq(maw.max_speed, freighter.max_speed * 0.5, "and it roams at half freighter speed (E2)")
	assert_eq(NpcRegistryScript.MAW_ROAM_SECTOR, 7, "the Maw roams S7")
	assert_eq(NpcRegistryScript.MAW_AGGRO_RADIUS, 600.0, "and aggros within 600 u (E2)")


## A3: the two arena payouts are S28's block (M10) and their reward floors are 15 section
## 5's (the Boneyard's magic roll, the Pyre's guaranteed rare).
func test_a3_the_boss_payouts_are_m10() -> void:
	assert_eq(
		ContractRegistryScript.arena_payout(NpcRegistryScript.ARCHETYPE_BONEYARD), BONEYARD_PAYOUT,
		"the Boneyard pays 6 000 CR"
	)
	assert_eq(
		ContractRegistryScript.arena_payout(NpcRegistryScript.ARCHETYPE_PYRE), PYRE_PAYOUT,
		"the Pyre pays 12 000 CR"
	)
	assert_eq(
		ContractRegistryScript.arena_reward_floor(NpcRegistryScript.ARCHETYPE_BONEYARD), "magic",
		"the Boneyard's magic module roll"
	)
	assert_eq(
		ContractRegistryScript.arena_reward_floor(NpcRegistryScript.ARCHETYPE_PYRE), "rare",
		"the Pyre's guaranteed rare"
	)


## A3: the Maw rolls 06 section 3.4 exactly - 20 000 seeded rolls whose EV is the doc's
## 1 584.75 CR within 06 section 6's bound and whose guaranteed floor is 1 025 CR.
func test_a3_the_maw_rolls_06_3_4() -> void:
	assert_true(LootTablesScript.has(&"maw"), "the Maw has its 06 table")
	var rolls := 20000
	var total := 0.0
	var floor := 1 << 30
	var shards := 0
	for index in rolls:
		var payload: Array[Dictionary] = LootTablesScript.roll_band(&"maw", index + 1)
		var credits := 0
		var scrap_value := 0
		for entry: Dictionary in payload:
			var item := StringName(entry.get(&"item_id", &""))
			var amount := int(entry.get(&"amount", 0))
			if item == LootTablesScript.CREDIT_ITEM:
				credits += amount
				total += float(amount)
			else:
				var value := int(ComponentCatalogScript.component(item).get(&"value", 0))
				total += float(amount) * float(value)
				if item == &"comp_scrap_3":
					scrap_value += amount * value
				elif item == &"comp_ore_3":
					shards += 1
		floor = mini(floor, scrap_value + credits)
	var ev := total / float(rolls)
	assert_true(
		absf(ev - MAW_EV) <= MAW_EV * 0.05,
		"the 20k-roll EV is 06 section 3.4's %.2f within 5 %% (measured %.2f)" % [MAW_EV, ev]
	)
	assert_eq(floor, MAW_FLOOR, "the guaranteed floor is 1 025 CR (line 1 + line 6 always pay)")
	assert_gt(shards, 0, "and the Voidshard (line 5) drops in the run")


## ------------------------------------------------------------------ A4: death persistence


## A4 (18 section 2 dec. 7 / section 7): the wreck's cargo window survives the death to
## respawn route - a scene rebuilt after the wreck still materialises the drop - and the
## respawn lands docked at the station.
func test_a4_the_wreck_window_survives_the_respawn_route() -> void:
	GameScript._wreck_drops.clear()
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	_profile.set(&"_cargo", {&"ingot_iron": 5})
	game.call(&"_drop_cargo_at_wreck")
	assert_eq(GameScript._wreck_drops.size(), 1, "the hold dropped at the wreck")
	assert_eq(
		StringName((GameScript._wreck_drops[0] as Dictionary).get(&"item", &"")), &"ingot_iron",
		"as the one stack it held"
	)
	## The respawn route rebuilds the scene: the ledger outlives it and re-materialises.
	_scenes.erase(game)
	game.free()
	var respawn := _open_game()
	assert_true(respawn != null, "the respawn scene boots")
	assert_eq(
		(respawn.get(&"_drop_faces") as Array).size(), 1,
		"the pre-death wreck's pickup is collectable after the respawn"
	)
	## And the respawn lands docked at the station (the last one visited).
	var routed := {&"called": false, &"destination": &""}
	respawn.connect(
		&"route_requested",
		func(_route: StringName, params: Dictionary) -> void:
			routed[&"called"] = true
			routed[&"destination"] = params.get(GameScript.PARAM_DESTINATION, &"")
	)
	respawn.call(&"_respawn_docked")
	assert_true(bool(routed[&"called"]), "the death routes the player back to a station")
	assert_eq(
		StringName(routed[&"destination"]), GameScript.DESTINATION_STATION, "docked, not in space"
	)


## ------------------------------------------------------------------ A5: insurance


## A5 (M14): the premium is 1.5 % of the class row's cheapest hull list, 135-1 080, and
## Champion standing multiplies it by 0.8 through S24's seam.
func test_a5_the_premium_is_m14_and_champion_scales() -> void:
	var cheapest := {
		&"fighter": &"ship_fighter",
		&"cutter": &"ship_vanguard",
		&"delver_trader_corvette": &"ship_miner",
		&"hauler_gunship": &"ship_freighter",
		&"frigate": &"ship_patrol",
		&"destroyer": &"ship_destroyer",
	}
	var lowest := 1 << 30
	var highest := 0
	for tier: Variant in cheapest:
		var hull := StringName(cheapest[tier])
		var cost := int(_catalog_cost(hull))
		var expected := roundi(float(cost) * 0.015)
		var got := int(_profile.call(&"insurance_tier_premium", StringName(tier)))
		assert_eq(got, expected, "%s's premium is 1.5 %% of its list" % String(tier))
		lowest = mini(lowest, got)
		highest = maxi(highest, got)
	assert_eq(lowest, 135, "the band's floor is 135 CR (the Fighter)")
	assert_eq(highest, 1080, "and its ceiling 1 080 CR (the Destroyer)")
	assert_eq(
		StationRegistryScript.insurance_multiplier(StationRegistryScript.CHAMPION_FLOOR), 0.8,
		"Champion standing multiplies the premium x0.8 (S24's seam)"
	)
	## F1: the multiplier reaches the **charge**, not just the seam.
	_set_owned([&"ship_destroyer", &"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_destroyer")
	_profile.call(&"set_insured", true)
	_profile.call(&"set_standing", {&"concord": StationRegistryScript.CHAMPION_FLOOR})
	_profile.call(&"set_docked_station", &"s1_primary")
	var base := int(_profile.call(&"insurance_premium"))
	var purse := int(_profile.call(&"credits"))
	assert_true(bool(_profile.call(&"insurance_charge")), "the launch charges a policy")
	assert_eq(
		purse - int(_profile.call(&"credits")), roundi(float(base) * 0.8),
		"Champion's x0.8 reaches the charge, not just the seam"
	)


## A5: the charge happens at launch and covers exactly one loss; the payout flow credits
## the hull+fit value and replaces into the tier's cheapest base hull.
func test_a5_charge_and_payout_flow() -> void:
	## Two hulls, so the loss does not trip the mercy clause: the payout flow replaces into
	## the tier's cheapest base hull.
	_set_owned([&"ship_gunship", &"ship_miner"])
	_profile.set(&"_active_ship", &"ship_gunship")
	_profile.call(&"set_insured", true)
	var premium := int(_profile.call(&"insurance_premium"))
	var before := int(_profile.call(&"credits"))
	assert_true(bool(_profile.call(&"insurance_charge")), "the premium is charged at launch")
	assert_eq(int(_profile.call(&"credits")), before - premium, "exactly the premium")
	assert_true(bool(_profile.call(&"insured")), "and the policy is active")
	var value := int(_profile.call(&"hull_fit_value", &"ship_gunship"))
	var payout: Dictionary = _profile.call(&"insurance_payout")
	assert_eq(int(payout.get(&"credited", 0)), value, "the loss pays the hull+fit value back")
	assert_eq(
		StringName(payout.get(&"hull", &"")), &"ship_freighter",
		"and respawns in the Hauler/Gunship tier's cheapest base hull"
	)
	assert_false(bool(_profile.call(&"insured")), "the one-death policy is spent")
	## F2: an uninsured loss grants no replacement (14 section 3) and falls back to a
	## surviving hull.
	_wipe()
	_set_owned([&"ship_freighter", &"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_freighter")
	_profile.set(&"_fits", {&"ship_freighter": {&"marker": true}, &"ship_fighter": {&"marker": true}})
	var uninsured: Dictionary = _profile.call(&"insurance_payout")
	assert_eq(StringName(uninsured.get(&"hull", &"")), &"", "an uninsured loss grants no hull")
	assert_false(
		(_profile.get(&"_owned_ships") as Array).has(&"ship_freighter"),
		"and does not reissue the lost hull"
	)
	assert_eq(
		StringName(_profile.call(&"active_ship")), &"ship_fighter",
		"the account falls back to a surviving hull"
	)
	## F3: an insured loss that replaces into an already-owned hull keeps that hull's fit.
	_wipe()
	_set_owned([&"ship_gunship", &"ship_freighter"])
	_profile.set(&"_active_ship", &"ship_gunship")
	_profile.call(&"set_insured", true)
	_profile.set(&"_fits", {&"ship_freighter": {&"marker": true}})
	var owned_replacement: Dictionary = _profile.call(&"insurance_payout")
	assert_eq(
		StringName(owned_replacement.get(&"hull", &"")), &"ship_freighter",
		"the insured loss replaces into the tier's cheapest"
	)
	assert_true(
		(_profile.get(&"_fits") as Dictionary).has(&"ship_freighter"),
		"and the surviving hull keeps its own fit"
	)


## A5: the Choir sells no insurance at all.
func test_a5_choir_sells_none() -> void:
	var choir := StationRegistryScript.station(&"s6_primary")
	assert_false(
		StationRegistryScript.offers(choir, StationRegistryScript.SERVICE_INSURANCE),
		"Emberlight sells no policy"
	)
	assert_eq(
		StationRegistryScript.service_reason(choir, StationRegistryScript.SERVICE_INSURANCE),
		"the Choir does not believe in accidents", "and says why (14 verbatim)"
	)


## A5: the mercy clause reissues a bare Fighter exactly once per profile; a second total
## loss does not.
func test_a5_the_mercy_clause_fires_once() -> void:
	_set_owned([&"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_fighter")
	var first: Dictionary = _profile.call(&"insurance_payout")
	assert_true(bool(first.get(&"mercy", false)), "the first total loss is the mercy clause")
	assert_eq(StringName(first.get(&"hull", &"")), ProfileScript.MERCY_HULL, "a bare Fighter")
	assert_true(bool(_profile.call(&"mercy_used")), "and it is used up")
	_set_owned([&"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_fighter")
	var second: Dictionary = _profile.call(&"insurance_payout")
	assert_false(bool(second.get(&"mercy", false)), "a second total loss does not reissue")


## ------------------------------------------------------------------ A6: vaults


## A6: one vault per station, 20 units base, +20 per rented tier, Meridian's 40-unit base
## at +25 % tier prices.
func test_a6_capacity_tiers_and_meridian() -> void:
	var concord := StationRegistryScript.station(&"s1_primary")
	var meridian := StationRegistryScript.station(&"s3_primary")
	assert_eq(int(_profile.call(&"vault_capacity", concord)), 20, "20 units base")
	assert_eq(
		int(_profile.call(&"vault_capacity", meridian)), 40, "Meridian rents 40-unit vaults"
	)
	_profile.set(&"_credits", 50000)
	var rent: Dictionary = _profile.call(&"vault_rent", &"s1_primary", 2, concord)
	assert_true(bool(rent.get(&"ok", false)), "tier 2 is rented")
	assert_eq(int(_profile.call(&"vault_capacity", concord)), 60, "+20 per upgrade tier")
	assert_eq(
		int(_profile.call(&"vault_tier_cost", 1, concord)), 500, "tier 1 costs 500 CR"
	)
	assert_eq(
		int(_profile.call(&"vault_tier_cost", 1, meridian)), 625, "Meridian's tiers cost 25 %% more"
	)


## A6: deposits and withdrawals are free, contents persist per station, and the vault is
## excluded from launch cargo.
func test_a6_deposit_withdraw_persist_and_not_cargo() -> void:
	var concord := StationRegistryScript.station(&"s1_primary")
	_profile.set(&"_cargo", {&"ingot_iron": 10})
	assert_true(
		bool(_profile.call(&"vault_deposit", &"s1_primary", &"ingot_iron", 6, concord)),
		"the stack deposits"
	)
	assert_eq(int(_profile.call(&"cargo_qty", &"ingot_iron")), 4, "off the hold, for free")
	assert_eq(int(_profile.call(&"vault_used", &"s1_primary")), 6, "and into the vault")
	assert_eq(
		(_profile.call(&"cargo_items") as Dictionary).size(), 1,
		"the vault is not the hold - launch cargo is unchanged by it"
	)
	## Contents persist per station: another station's vault is empty.
	assert_eq(int(_profile.call(&"vault_used", &"s2_primary")), 0, "a vault is per-station")
	assert_true(
		bool(_profile.call(&"vault_withdraw", &"s1_primary", &"ingot_iron", 6)),
		"the stack withdraws, for free"
	)
	assert_eq(int(_profile.call(&"cargo_qty", &"ingot_iron")), 10, "and is back in the hold")
	assert_eq(int(_profile.call(&"vault_used", &"s1_primary")), 0, "the vault is empty again")


## A6: `u_vault` (15 section 5's `vault_add`) adds +20 units to every vault.
func test_a6_u_vault_adds_twenty() -> void:
	var concord := StationRegistryScript.station(&"s1_primary")
	var before := int(_profile.call(&"vault_capacity", concord))
	_profile.call(&"add_module", &"u_vault")
	assert_true(bool(_profile.call(&"owns_u_vault")), "the account holds u_vault")
	assert_eq(int(_profile.call(&"vault_capacity", concord)), before + 20, "+20 to the vault")


## ------------------------------------------------------------------ A7: the deck


## A7: the INSURANCE and VAULTS panels mount real (not placeholders) in the SERVICES deck
## beside S25's contracts strip, and carry STATION_HUB section 15.3/15.4's surfaces.
func test_a7_the_panels_mount_in_the_services_deck() -> void:
	_profile.call(&"set_docked_station", &"s3_primary")
	_profile.set(&"_credits", 50000)
	var screen := _mount()
	var deck: Control = screen.call(&"pane_for", 7) as Control
	assert_true(deck != null, "the SERVICES deck exists")
	var insurance: Control = screen.call(&"service_panel", &"insurance") as Control
	assert_true(insurance != null, "the INSURANCE panel is mounted")
	assert_false(insurance.is_in_group(&"station_placeholder"), "and it is a real panel (not D11's)")
	assert_eq(
		String(insurance.call(&"note_text")),
		"Champion standing multiplies the premium ×0.8", "U9's champion note verbatim"
	)
	assert_true(
		String(insurance.call(&"premium_line_text")).contains("CHARGED AT LAUNCH"),
		"U13's charge-at-launch line"
	)
	assert_eq(String(insurance.call(&"state_text")), "UNINSURED", "U10's opening chip state")
	assert_eq(
		String(insurance.call(&"mercy_text")), "MERCY AVAILABLE", "U11's opening mercy chip"
	)
	var vaults: Control = screen.call(&"service_panel", &"vaults") as Control
	assert_true(vaults != null, "the VAULTS panel is mounted")
	assert_false(vaults.is_in_group(&"station_placeholder"), "and it is a real panel")
	assert_eq(
		(vaults.call(&"tier_rows") as Array).size(), 3, "U14's three tier rows"
	)
	assert_true(
		String(vaults.call(&"capacity_text")).contains("UNITS"), "U16's capacity readout"
	)
	assert_eq(String(vaults.call(&"deposit_label")), "DEPOSIT", "U15's deposit pressable")
	assert_eq(String(vaults.call(&"withdraw_label")), "WITHDRAW", "and its withdrawal twin")
	assert_eq(
		String(vaults.call(&"not_cargo_caption_text")),
		"VAULT CONTENTS DO NOT COUNT AGAINST CARGO ON LAUNCH",
		"U15's not-cargo caption verbatim"
	)
	assert_false(
		bool(vaults.call(&"outpost_caption_visible")), "and no outpost caption at a capital"
	)
	## F5: at an outpost the caption renders and tiers 2/3 grey the whole row.
	_free_station()
	_profile.call(&"set_docked_station", &"s2_outpost")
	var outpost := _mount()
	var out_vaults: Control = outpost.call(&"service_panel", &"vaults") as Control
	assert_true(bool(out_vaults.call(&"outpost_caption_visible")), "U16's outpost caption shows")
	assert_eq(
		String(out_vaults.call(&"outpost_caption_text")), "tier 1 only — this is an outpost",
		"verbatim"
	)
	assert_true(bool(out_vaults.call(&"tier_row_disabled", 2)), "tier 2's whole row greys")
	assert_true(bool(out_vaults.call(&"tier_row_disabled", 3)), "and tier 3's")


## A7: the strip still holds the three services, and every pane still expands to the
## deck's height - no existing panel's layout moved.
func test_a7_the_strip_still_holds_three_services() -> void:
	_profile.call(&"set_docked_station", &"s3_primary")
	var screen := _mount()
	var deck: Control = screen.call(&"pane_for", 7) as Control
	var host := deck.get_node_or_null(NodePath("ServiceHost")) as Control
	assert_true(host != null, "the deck carries its own service host")
	for service: StringName in [&"contracts", &"insurance", &"vaults"]:
		screen.call(&"service_panel", service)
	assert_eq(host.get_child_count(), 3, "one pane per service in the strip")
	for child: Node in host.get_children():
		var pane := child as Control
		assert_true(pane != null, "a service pane is a Control")
		assert_true(
			bool(pane.size_flags_vertical & Control.SIZE_EXPAND),
			"%s fills the deck's height" % pane.name
		)
	assert_true(screen.call(&"service_panel", &"contracts") != null, "S25's CONTRACTS strip stays")


## ------------------------------------------------------------------ A8: the summary


## A8: every value this wave moved is the documented one - the boss payouts are M10's, the
## premium is M14's, and the R-S26-1 and E2 rows are E1/E2's.
func test_a8_the_moved_values_are_the_documented_ones() -> void:
	assert_eq(ContractRegistryScript.arena_payout(NpcRegistryScript.ARCHETYPE_BONEYARD), 6000, "M10")
	assert_eq(ContractRegistryScript.arena_payout(NpcRegistryScript.ARCHETYPE_PYRE), 12000, "M10")
	assert_eq(int(_profile.call(&"insurance_tier_premium", &"fighter")), 135, "M14's floor")
	assert_eq(int(_profile.call(&"insurance_tier_premium", &"destroyer")), 1080, "M14's ceiling")
	assert_eq(NpcRegistryScript.boss_weapons(NpcRegistryScript.ARCHETYPE_BONEYARD), 5, "R-S26-1 E1")
	assert_eq(NpcRegistryScript.boss_weapons(NpcRegistryScript.ARCHETYPE_PYRE), 4, "R-S26-1 E1")
	assert_eq(NpcRegistryScript.MAW_ROAM_SECTOR, 7, "E2's roam")
	assert_eq(int(ContractRegistryScript.ARENA_ENTRY_WINDOW), 60, "14 section 5's entry window")
	assert_eq(
		int(NpcRegistryScript.ARENA_COOLDOWN_SECONDS), 1200, "and its 20-minute cooldown"
	)


## ------------------------------------------------------------------ helpers


func _expedition(board: Array[Dictionary]) -> Dictionary:
	for row: Dictionary in board:
		if StringName(row.get(&"type", &"")) == ContractRegistryScript.TYPE_EXPEDITION:
			return row
	return {}


## The list price of one player hull, from the catalogue that owns it.
func _catalog_cost(hull_id: StringName) -> int:
	return int(StationCatalogScript.ship(hull_id).get(&"cost", 0))
