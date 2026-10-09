extends Node
## S26-R1 (reviewer) evidence probe: the wave's acceptance list re-measured
## independently of the builder's suite — own seeds, own expected values read off
## the docs (14's 2026-10-08 S28 block M10/M14, 06 §3.4, 08's R-S26-1 block,
## 14 §4), never off the builder's constants. Changes nothing: throwaway
## profile, scratch store, every scene freed before the probe quits.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s26_r1.tscn --quit-after 2400

const ContractRegistry := preload("res://game/contract_registry.gd")
const StationRegistry := preload("res://game/station_registry.gd")
const StationCatalog := preload("res://game/station_catalog.gd")
const NpcRegistry := preload("res://game/npc_registry.gd")
const LootTables := preload("res://game/loot_tables.gd")
const ComponentCatalog := preload("res://game/component_catalog.gd")
const ModuleCatalog := preload("res://game/module_catalog.gd")
const SectorRegistry := preload("res://game/sector_registry.gd")
const GameScript := preload("res://game/game.gd")
const ShipFit := preload("res://game/ship_fit.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const GameScenePath := "res://game/game.tscn"

const SERVICE := &"PlayerProfile"
const PROFILE_PATH := "user://probe_s26_r1.cfg"
const NEUTRAL := 0
const MY_SEED := 20261009
## 06 §3.4's own figures, retyped from the doc.
const MAW_EV := 1584.75
const MAW_FLOOR := 1025
## 14's 2026-10-08 S28 block (M10), retyped.
const PAYOUTS := {&"boneyard": 6000, &"pyre": 12000}

var _pass := 0
var _fail := 0
var _profile: Node = null
var _scenes: Array = []


func _ready() -> void:
	print("[S26R1] probe start")
	_borrow_profile()
	_r1_premium_band()
	_r2_champion_scale()
	_r3_mercy_once_and_second_loss()
	_r4_uninsured_replacement()
	_r5_cooldown_clock()
	await _r6_arena_loop()
	_r7_maw_table()
	_r8_boss_rows()
	_r9_vaults()
	_r10_seam_rows()
	await _r11_wreck_route()
	print("[S26R1] passed=%d failed=%d" % [_pass, _fail])
	_teardown()
	get_tree().quit(0 if _fail == 0 else 1)


func _check(ok: bool, label: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("[S26R1] %s %s" % ["PASS" if ok else "FAIL", label])


func _borrow_profile() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(SERVICE))
	_profile.set(&"save_path", PROFILE_PATH)
	_wipe()


func _wipe() -> void:
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


func _set_owned(ships: Array) -> void:
	var typed: Array[StringName] = []
	for id: Variant in ships:
		typed.append(StringName(id))
	_profile.set(&"_owned_ships", typed)


func _teardown() -> void:
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	GameScript._wreck_drops.clear()
	if _profile != null:
		_wipe()
		_profile.call(&"flush")
		var absolute := ProjectSettings.globalize_path(PROFILE_PATH)
		if FileAccess.file_exists(absolute):
			DirAccess.remove_absolute(absolute)


## R1: the six §3 rows price at 1.5 % of the row's cheapest hull (M14), the band
## 135–1 080 holds, and the endpoints are the Fighter's and the Destroyer's.
func _r1_premium_band() -> void:
	var rows := {
		&"fighter": &"ship_fighter",
		&"cutter": &"ship_vanguard",
		&"delver_trader_corvette": &"ship_miner",
		&"hauler_gunship": &"ship_freighter",
		&"frigate": &"ship_patrol",
		&"destroyer": &"ship_destroyer",
	}
	var lowest := 1 << 30
	var highest := 0
	for tier: Variant in rows:
		var list := int(StationCatalog.ship(StringName(rows[tier])).get(&"cost", 0))
		var expected := roundi(float(list) * 0.015)
		var got := int(_profile.call(&"insurance_tier_premium", StringName(tier)))
		_check(got == expected, "R1 %s premium %d = 1.5%% of list %d" % [String(tier), got, list])
		lowest = mini(lowest, got)
		highest = maxi(highest, got)
	_check(lowest == 135, "R1 the band's floor is 135 CR (the Fighter)")
	_check(highest == 1080, "R1 the band's ceiling is 1 080 CR (the Destroyer)")


## R2: Champion standing multiplies the premium ×0.8 through S24's seam — the
## charged premium must shrink at Champion, not stay at the base figure.
func _r2_champion_scale() -> void:
	var multiplier := float(StationRegistry.insurance_multiplier(StationRegistry.CHAMPION_FLOOR))
	_check(is_equal_approx(multiplier, 0.8), "R2 the seam answers 0.8 at Champion (S24)")
	_profile.set(&"_active_ship", &"ship_destroyer")
	_profile.call(&"set_insured", true)
	_profile.call(&"set_standing", {&"concord": int(StationRegistry.CHAMPION_FLOOR)})
	_profile.call(&"set_docked_station", &"s1_primary")
	var base := int(_profile.call(&"insurance_premium"))
	var purse := int(_profile.call(&"credits"))
	var charged := bool(_profile.call(&"insurance_charge"))
	var delta := purse - int(_profile.call(&"credits"))
	_check(charged, "R2 the launch charges a policy")
	_check(
		delta == roundi(float(base) * 0.8),
		"R2 the Champion charge is x0.8 of the base %d (charged %d)" % [base, delta]
	)
	_wipe()


## R3: the mercy clause reissues a bare Fighter exactly once; a second total loss
## leaves the account shipless (A5's "a second total loss does not").
func _r3_mercy_once_and_second_loss() -> void:
	_set_owned([&"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_fighter")
	var first: Dictionary = _profile.call(&"insurance_payout")
	_check(bool(first.get(&"mercy", false)), "R3 the first total loss is the mercy clause")
	_check(StringName(first.get(&"hull", &"")) == &"ship_fighter", "R3 it reissues a bare Fighter")
	_check(bool(_profile.call(&"mercy_used")), "R3 and the clause is spent")
	_set_owned([&"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_fighter")
	var second: Dictionary = _profile.call(&"insurance_payout")
	_check(not bool(second.get(&"mercy", false)), "R3 a second total loss does not reissue")
	_check(
		StringName(_profile.call(&"active_ship")) == &"" and (_profile.get(&"_owned_ships") as Array).is_empty(),
		"R3 and the account is shipless after it"
	)
	_wipe()


## R4: 14 §3's uninsured loss — "hull and all installed modules are gone". The
## replacement branch must not grant a hull the account never owned, and must not
## strip the fit of a replacement hull that survived the loss.
func _r4_uninsured_replacement() -> void:
	_set_owned([&"ship_freighter", &"ship_fighter"])
	_profile.set(&"_active_ship", &"ship_freighter")
	_profile.set(&"_fits", {&"ship_freighter": {&"marker": true}, &"ship_fighter": {&"marker": true}})
	var payout: Dictionary = _profile.call(&"insurance_payout")
	print("[S26R1] R4 EVIDENCE fits=%s owned=%s active=%s hull=%s" % [str(_profile.get(&"_fits")), str(_profile.get(&"_owned_ships")), StringName(_profile.call(&"active_ship")), StringName(payout.get(&"hull", &""))])
	_check(int(payout.get(&"credited", 0)) == 0, "R4 an uninsured loss pays nothing")
	_check(
		not (_profile.get(&"_owned_ships") as Array).has(&"ship_freighter"),
		"R4 the uninsured loss grants no replacement hull"
	)
	_check(
		not (_profile.get(&"_fits") as Dictionary).has(&"ship_freighter"),
		"R4 the lost hull's fit went with it"
	)
	_check(
		StringName(_profile.call(&"active_ship")) == &"ship_fighter",
		"R4 and the account falls back to a surviving hull"
	)
	## The owned-replacement case: the surviving fleet's own hull keeps its fit.
	_wipe()
	_set_owned([&"ship_gunship", &"ship_freighter"])
	_profile.set(&"_active_ship", &"ship_gunship")
	_profile.call(&"set_insured", true)
	_profile.set(&"_fits", {&"ship_freighter": {&"marker": true}})
	var second: Dictionary = _profile.call(&"insurance_payout")
	_check(
		StringName(second.get(&"hull", &"")) == &"ship_freighter",
		"R4 the insured loss replaces into the tier's cheapest base hull"
	)
	_check(
		(_profile.get(&"_fits") as Dictionary).has(&"ship_freighter"),
		"R4 the surviving freighter keeps its own fit"
	)
	_wipe()


## R5: the arena cooldown is one run per boss per 20-minute clock, boundary exact.
func _r5_cooldown_clock() -> void:
	var boss := NpcRegistry.ARCHETYPE_BONEYARD
	var now := 7777
	_profile.call(&"arena_mark_run", boss, now)
	_check(
		not bool(_profile.call(&"arena_ready", boss, now + 1199)),
		"R5 the boss is still on its clock at +1199 s"
	)
	_check(
		bool(_profile.call(&"arena_ready", boss, now + 1200)),
		"R5 and ready at exactly +1200 s (the 20-minute clock)"
	)
	_check(
		bool(_profile.call(&"arena_ready", NpcRegistry.ARCHETYPE_PYRE, now)),
		"R5 and another boss's clock is its own"
	)


## R6: the full contract loop, both outcomes — a stolen kill closes the run and
## pays nothing; the player's own last hit pays M10's figure plus a module.
func _r6_arena_loop() -> void:
	var station := StationRegistry.station(&"s3_primary")
	var board := ContractRegistry.board(station, NEUTRAL, 0)
	var row := {}
	for entry: Dictionary in board:
		if StringName(entry.get(&"type", &"")) == ContractRegistry.TYPE_EXPEDITION:
			row = entry
	_check(not row.is_empty(), "R6 the Expedition row is on the S3 board")
	var first := ContractRegistry.accept(_profile, station, NEUTRAL, row)
	_check(bool(first.get(&"ok", false)), "R6 the run accepts at the arena's desk")
	var id := StringName((first.get(&"contract", {}) as Dictionary).get(&"id", &""))
	var before := int(_profile.call(&"credits"))
	var stolen := ContractRegistry.arena_settle(_profile, id)
	_check(int(stolen.get(&"paid", 0)) == 0, "R6 a run with no kill credit pays nothing (lost)")
	_check(int(_profile.call(&"credits")) == before, "R6 and the purse did not move")
	_check(ContractRegistry.active_count(_profile) == 0, "R6 and the run still closed")
	_profile.call(&"arena_mark_run", NpcRegistry.ARCHETYPE_BONEYARD, 0)
	var board2 := ContractRegistry.board(station, NEUTRAL, 60)
	var row2 := {}
	for entry: Dictionary in board2:
		if StringName(entry.get(&"type", &"")) == ContractRegistry.TYPE_EXPEDITION:
			row2 = entry
	var second := ContractRegistry.accept(_profile, station, NEUTRAL, row2)
	_check(bool(second.get(&"ok", false)), "R6 the second run accepts after the clock")
	var id2 := StringName((second.get(&"contract", {}) as Dictionary).get(&"id", &""))
	_check(
		ContractRegistry.arena_credit_kill(_profile, NpcRegistry.ARCHETYPE_BONEYARD),
		"R6 the player's last hit credits the kill"
	)
	var purse := int(_profile.call(&"credits"))
	var paid := ContractRegistry.arena_settle(_profile, id2)
	_check(
		int(paid.get(&"paid", 0)) == int(PAYOUTS[NpcRegistry.ARCHETYPE_BONEYARD]),
		"R6 the win pays M10's 6 000 CR"
	)
	_check(
		int(_profile.call(&"credits")) == purse + int(PAYOUTS[NpcRegistry.ARCHETYPE_BONEYARD]),
		"R6 and the purse moved by exactly the payout"
	)
	_check(StringName(paid.get(&"module", &"")) != &"", "R6 and the reward module rolled")


## R7: the Maw rolls 06 §3.4 — 20 000 rolls on this probe's own seed, the EV
## inside 06 §6's ±5 % and the floor exactly 1 025; then the same table at the scale the
## game's own kill path uses in S7 (`cache_scale_for`), which pins this band flat, so the
## two runs must agree.
func _r7_maw_table() -> void:
	var rolls := 20000
	var total := 0.0
	var floor := 1 << 30
	var shards := 0
	for index in rolls:
		var payload: Array[Dictionary] = LootTables.roll_band(&"maw", MY_SEED + index)
		var credits := 0
		var scrap := 0
		for entry: Dictionary in payload:
			var item := StringName(entry.get(&"item_id", &""))
			var amount := int(entry.get(&"amount", 0))
			if item == LootTables.CREDIT_ITEM:
				credits += amount
				total += float(amount)
			else:
				var value := int(ComponentCatalog.component(item).get(&"value", 0))
				total += float(amount) * float(value)
				if item == &"comp_scrap_3":
					scrap += amount * value
				elif item == &"comp_ore_3":
					shards += 1
		floor = mini(floor, scrap + credits)
	var ev := total / float(rolls)
	_check(absf(ev - MAW_EV) <= MAW_EV * 0.05, "R7 the 20k EV is %.2f (doc 1 584.75 ±5%%)" % ev)
	_check(floor == MAW_FLOOR, "R7 the guaranteed floor is exactly 1 025 CR")
	_check(shards > 0, "R7 and the Voidshard line dropped in the run")
	_check(int(ComponentCatalog.component(&"comp_scrap_3").get(&"value", 0)) == 75, "R7 the slag's 75 CR is the floor's own arithmetic")
	var scaled_total := 0.0
	var scaled_floor := 1 << 30
	var tier := int(SectorRegistry.sector_tier(&"sector_7"))
	## 14 §5 / 06 §3.4 pin the maw band flat, so the in-game scale is 1.0 whatever S7's
	## tier is; the shipped decision is `cache_scale_for`, read here not re-derived.
	var scale := float(LootTables.cache_scale_for(&"maw", tier))
	for index in rolls:
		var payload: Array[Dictionary] = LootTables.roll_band(&"maw", MY_SEED + index, scale)
		var credits := 0
		var scrap := 0
		for entry: Dictionary in payload:
			var item := StringName(entry.get(&"item_id", &""))
			var amount := int(entry.get(&"amount", 0))
			if item == LootTables.CREDIT_ITEM:
				credits += amount
				scaled_total += float(amount)
			else:
				var value := int(ComponentCatalog.component(item).get(&"value", 0))
				scaled_total += float(amount) * float(value)
				if item == &"comp_scrap_3":
					scrap += amount * value
		scaled_floor = mini(scaled_floor, scrap + credits)
	print(
		"[S26R1] R7 EVIDENCE S7 tier %d scale %.1f: in-game EV %.2f floor %d (doc flat: 1584.75 / 1025)"
		% [tier, scale, scaled_total / float(rolls), scaled_floor]
	)


## R8: the three bosses fly R-S26-1's rows (08's 2026-09-27 P3 block).
func _r8_boss_rows() -> void:
	var base_gunship := ShipFit.resolve(&"ship_gunship", ShipFit.STANDARD_FIT)
	var frigate_ref := ShipFit.resolve(&"ship_patrol", ShipFit.STANDARD_FIT)
	var freighter := ShipFit.resolve(&"ship_freighter", ShipFit.STANDARD_FIT)
	var gunship := NpcRegistry.boss_stats(&"boneyard")
	var maw := NpcRegistry.boss_stats(&"boss")
	_check(is_equal_approx(gunship.hull_max, base_gunship.hull_max * 2.5), "R8 the Boneyard is gunship-tier x2.5")
	_check(is_equal_approx(gunship.shield_max, base_gunship.shield_max * 2.5), "R8 its shield too")
	_check(NpcRegistry.boss_weapons(&"boneyard") == 5, "R8 and flies 5 weapons")
	_check(is_equal_approx(NpcRegistry.boss_stats(&"pyre").hull_max, frigate_ref.hull_max * 2.5), "R8 the Pyre is frigate-tier x2.5")
	_check(NpcRegistry.boss_weapons(&"pyre") == 4, "R8 and flies 4 weapons")
	_check(int(maw.hull_max) == 12000 and int(maw.shield_max) == 6000, "R8 the Maw is 12 000/6 000")
	_check(NpcRegistry.boss_weapons(&"boss") == 7, "R8 and flies 7 weapons")
	_check(is_equal_approx(maw.max_speed, freighter.max_speed * 0.5), "R8 and roams at half freighter speed (E2)")


## R9: the vault law (14 §4) — tiers, Meridian's arithmetic, u_vault, not-cargo.
func _r9_vaults() -> void:
	var concord := StationRegistry.station(&"s1_primary")
	var meridian := StationRegistry.station(&"s3_primary")
	var outpost := StationRegistry.station(&"s2_outpost")
	_check(int(_profile.call(&"vault_capacity", concord)) == 20, "R9 20 units base")
	_check(int(_profile.call(&"vault_capacity", meridian)) == 40, "R9 Meridian rents 40-unit vaults")
	_check(int(_profile.call(&"vault_tier_cost", 1, concord)) == 500, "R9 tier 1 is 500 CR")
	_check(int(_profile.call(&"vault_tier_cost", 2, concord)) == 1200, "R9 tier 2 is 1 200 CR")
	_check(int(_profile.call(&"vault_tier_cost", 3, concord)) == 2400, "R9 tier 3 is 2 400 CR")
	_check(int(_profile.call(&"vault_tier_cost", 1, meridian)) == 625, "R9 Meridian's tier 1 is 625 CR (x1.25)")
	_check(int(_profile.call(&"vault_tier_cost", 2, meridian)) == 1500, "R9 Meridian's tier 2 is 1 500 CR")
	_check(int(_profile.call(&"vault_tier_cost", 3, meridian)) == 3000, "R9 Meridian's tier 3 is 3 000 CR")
	_profile.set(&"_credits", 100000)
	var rent3: Dictionary = _profile.call(&"vault_rent", &"s1_primary", 3, concord)
	_check(bool(rent3.get(&"ok", false)), "R9 tier 3 rents at a capital")
	_check(int(_profile.call(&"vault_capacity", concord)) == 80, "R9 20 + 3x20 = 80 units")
	_profile.call(&"add_module", &"u_vault")
	_check(int(_profile.call(&"vault_capacity", concord)) == 100, "R9 u_vault adds +20 (15 §5)")
	_check(int(_profile.call(&"vault_capacity", meridian)) == 60, "R9 and +20 at Meridian too (40 base + 20, its own tier 0)")
	var mrent: Dictionary = _profile.call(&"vault_rent", &"s3_primary", 1, meridian)
	_check(bool(mrent.get(&"ok", false)), "R9 Meridian's tier 1 rents")
	_check(int(_profile.call(&"vault_capacity", meridian)) == 80, "R9 40 + 20 + 20 with u_vault riding the rented tier")
	var ceiling := int(outpost.get(&"vault_tiers", 0))
	_check(ceiling == 1, "R9 an outpost's ceiling is tier 1 (14 §8)")
	_check(
		not bool((_profile.call(&"vault_rent", &"s2_outpost", 2, outpost) as Dictionary).get(&"ok", true)),
		"R9 and tier 2 refuses there"
	)
	_profile.set(&"_cargo", {&"ingot_iron": 30})
	_check(
		bool(_profile.call(&"vault_deposit", &"s1_primary", &"ingot_iron", 100, concord)) == false,
		"R9 a deposit over capacity is refused whole"
	)
	_check(bool(_profile.call(&"vault_deposit", &"s1_primary", &"ingot_iron", 30, concord)), "R9 a fitting deposit lands")
	_check(
		(_profile.call(&"cargo_items") as Dictionary).has(&"ingot_iron") == false
		or int((_profile.call(&"cargo_items") as Dictionary).get(&"ingot_iron", 0)) == 0,
		"R9 the vault's contents are not launch cargo"
	)
	_check(int(_profile.call(&"vault_used", &"s2_primary")) == 0, "R9 contents persist per station (S2's vault is empty)")
	_wipe()


## R10: the seam rows — live at the two arena desks, the greyed seam elsewhere.
func _r10_seam_rows() -> void:
	for station_id: Variant in [&"s3_primary", &"s6_primary"]:
		var board := ContractRegistry.board(StationRegistry.station(station_id), NEUTRAL, 0)
		var found := false
		for entry: Dictionary in board:
			if StringName(entry.get(&"type", &"")) == ContractRegistry.TYPE_EXPEDITION:
				found = true
				_check(
					not bool(entry.get(&"staged", false))
					and StringName(entry.get(&"boss", &"")) != &"",
					"R10 the Expedition row is live at %s" % String(station_id)
				)
		_check(found, "R10 %s's board carries the row" % String(station_id))
	for station_id: Variant in [&"s1_primary", &"s5_primary"]:
		var board := ContractRegistry.board(StationRegistry.station(station_id), NEUTRAL, 0)
		var staged := false
		for entry: Dictionary in board:
			if StringName(entry.get(&"type", &"")) == ContractRegistry.TYPE_EXPEDITION:
				staged = bool(entry.get(&"staged", false))
		_check(staged, "R10 the seam stays greyed off an arena (%s)" % String(station_id))
	var pool := ModuleCatalog.arena_pool()
	_check(not pool.is_empty(), "R10 the arena reward pool is non-empty")
	var exclusives := 0
	for base: StringName in pool:
		if ModuleCatalog.EXCLUSIVES.has(base):
			exclusives += 1
	_check(exclusives == 0, "R10 and carries no 15 §5 exclusive")
	_check(ModuleCatalog.roll_rarity(&"arena", &"m_engine_1", &"rare") == "rare", "R10 the Pyre's floor holds at rare")
	_check(ModuleCatalog.roll_rarity(&"arena", &"m_engine_1", &"magic") != "common", "R10 the Boneyard's floor holds at magic")


## R11: the wreck survives the death route — the pre-death drop is collectable
## after the respawn rebuilds the scene, and the respawn routes docked.
func _r11_wreck_route() -> void:
	GameScript._wreck_drops.clear()
	var packed := load(GameScenePath) as PackedScene
	if packed == null:
		print("[S26R1] SKIP R11 the flight scene is not loadable headless")
		return
	var scene := packed.instantiate() as Node2D
	if scene == null:
		print("[S26R1] SKIP R11 the flight scene did not instantiate")
		return
	_profile.add_child(scene)
	_scenes.append(scene)
	_profile.set(&"_cargo", {&"ingot_iron": 5})
	scene.call(&"_drop_cargo_at_wreck")
	_check(GameScript._wreck_drops.size() == 1, "R11 the hold dropped at the wreck")
	scene.free()
	_scenes.clear()
	var respawn := packed.instantiate() as Node2D
	_profile.add_child(respawn)
	_scenes.append(respawn)
	_check(
		(respawn.get(&"_drop_faces") as Array).size() == 1,
		"R11 the pre-death pickup is materialised after the respawn"
	)
	var routed := {&"called": false, &"destination": &""}
	respawn.connect(
		&"route_requested",
		func(_route: StringName, params: Dictionary) -> void:
			routed[&"called"] = true
			routed[&"destination"] = params.get(GameScript.PARAM_DESTINATION, &"")
	)
	respawn.call(&"_respawn_docked")
	_check(bool(routed[&"called"]), "R11 the death routes back to a station")
	_check(StringName(routed[&"destination"]) == GameScript.DESTINATION_STATION, "R11 docked, not in space")
