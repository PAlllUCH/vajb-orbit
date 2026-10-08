extends Node
## S24-R1 (reviewer) evidence probe: the wave's acceptance list re-measured
## independently of both builders' suites - own seeds, own expected values read
## off the docs (14's 2026-09-27 table, 12's 4.1/5, 13 §4, 11's V8 block), never
## off the builders' constants. Changes nothing: throwaway profiles, scratch
## store, every scene freed before the probe quits.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s24_r1.tscn --quit-after 1200

const Reg := preload("res://game/station_registry.gd")
const Catalog := preload("res://game/station_catalog.gd")
const Repairs := preload("res://game/repairs.gd")
const Exchange := preload("res://game/exchange.gd")
const Modules := preload("res://game/module_catalog.gd")
const Auction := preload("res://game/auction.gd")
const SectorReg := preload("res://game/sector_registry.gd")
const NpcReg := preload("res://game/npc_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const SERVICE := &"PlayerProfile"
const SHIP: StringName = &"ship_vanguard"
const SHUNNED := -20
const KNOWN := 20
const TRUSTED := 50
const CHAMPION := 80
const MY_SEED := 424242
const GATE_REFUSED_PROMPT := "GATE REFUSED — OUTLAW"

## 14's 2026-09-27 P3 table, retyped from the doc for this probe (not from the
## builders' suites): id -> [name, character, sector, kind, faction].
const PLACES := {
	&"s1_primary": ["Halcyon Anchorage", "forge-grey bastion, the full menu", 1, "primary", "concord"],
	&"s2_primary": ["Ironworks Depot", "mill-town market floor", 2, "primary", "concord"],
	&"s2_outpost": ["Marchgate Post", "a dock and a vending wall", 2, "outpost", "concord"],
	&"s3_primary": ["Spanport Meridian", "the merchant's harbour, best contract rates", 3, "primary", "meridian"],
	&"s4_primary": ["Ashveil Exchange", "free-port chaos, component prices", 4, "primary", "meridian"],
	&"s4_outpost": ["Rimward Depot", "caravan stop", 4, "outpost", "meridian"],
	&"s5_primary": ["Cinder Gate", "incense and plasma scorch", 5, "primary", "choir"],
	&"s5_shrine": ["The First Ember", "the Choir's smallest rite", 5, "outpost", "choir"],
	&"s6_primary": ["Emberlight", "cathedral dark, meanest turrets", 6, "primary", "choir"],
}

var _pass := 0
var _fail := 0
var _profile: Node = null
var _previous := {}
var _scenes: Array = []
var _profiles: Array = []


func _ready() -> void:
	print("[S24R1] probe start")
	_borrow_profile()
	await _a1_rows()
	await _a1_seam()
	await _a1_plate()
	await _a2_price_law()
	await _a2_commission()
	await _a3_predicates()
	await _a3_hot_pair()
	await _a3_reserved_slot()
	await _a3_shelf_bias()
	await _a3_dock_gate()
	await _a4_bands()
	await _a5_cloud_roll()
	await _a5_cloud_readings()
	await _mechanisms()
	_release_profile()
	print("[S24R1] done pass=%d fail=%d" % [_pass, _fail])
	get_tree().quit(0 if _fail == 0 else 1)


func _check(tag: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("[S24R1] ok   %s %s" % [tag, detail])
	else:
		_fail += 1
		print("[S24R1] FAIL %s %s" % [tag, detail])


func _borrow_profile() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(SERVICE))
	_previous = {
		&"save_path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"heat": (_profile.call(&"heat") as Dictionary).duplicate(true),
		&"docked_faction": StringName(_profile.call(&"docked_faction")),
		&"docked_station": StringName(_profile.call(&"docked_station")),
		&"active_ship": StringName(_profile.call(&"active_ship")),
		&"owned": (_profile.get(&"_owned_ships") as Array).duplicate(true),
		&"auction": (_profile.call(&"auction") as Dictionary).duplicate(true),
	}
	_profile.set(&"save_path", "user://probe_s24_r1.cfg")
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.call(&"set_standing", {})
	_profile.call(&"set_heat", {})
	_profile.call(&"set_docked_faction", &"")
	_profile.call(&"set_docked_station", &"")


func _release_profile() -> void:
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	_profile.call(&"set_standing", _previous[&"standing"])
	_profile.call(&"set_heat", _previous[&"heat"])
	_profile.call(&"set_docked_faction", _previous[&"docked_faction"])
	_profile.call(&"set_docked_station", _previous[&"docked_station"])
	_profile.set(&"_credits", int(_previous[&"credits"]))
	_profile.set(&"_owned_ships", _previous[&"owned"])
	_profile.call(&"set_auction", _previous[&"auction"])
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))


func _fresh() -> Node:
	var profile := ProfileScript.new()
	profile.save_path = "user://probe_s24_r1.cfg"
	_profiles.append(profile)
	return profile


func _dock(profile: Node, station_id: StringName, standing: int) -> void:
	var row := Reg.station(station_id)
	profile.call(&"set_docked_station", station_id)
	profile.call(
		&"set_standing",
		{String(StringName(row.get(&"faction", &""))): standing} if not row.is_empty() else {}
	)
	profile.call(&"set_docked_faction", StringName(row.get(&"faction", &"")))


func _stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = MY_SEED
	return rng


func _shelf(profile: Node, rng: RandomNumberGenerator) -> Dictionary:
	seed(MY_SEED)
	var shelf: Dictionary = Auction.draw_shelf(profile, rng)
	profile.call(&"set_auction", shelf)
	return shelf


func _first_rolled_base(shelf: Dictionary) -> StringName:
	var listings: Dictionary = shelf[&"modules"]
	var keys: Array = listings.keys()
	var index := 0
	if not keys.is_empty() and Modules.EXCLUSIVES.has(StringName(listings[keys[0]][&"base_id"])):
		index = 1
	if index >= keys.size():
		return &""
	return StringName(listings[keys[index]][&"base_id"])


func _rolled_of(shelf: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var listings: Dictionary = shelf[&"modules"]
	var keys: Array = listings.keys()
	for index in keys.size():
		if index >= Auction.MODULE_SLOTS:
			continue
		var base := StringName(listings[keys[index]][&"base_id"])
		if index == 0 and Modules.EXCLUSIVES.has(base):
			continue
		out.append(base)
	return out


func _open_game() -> Node2D:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_profile.add_child(scene)
	_scenes.append(scene)
	return scene


func _mount_station() -> Control:
	var host := Control.new()
	host.theme = ThemeRes
	host.size = Vector2(1920.0, 1080.0)
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_scenes.append(host)
	return screen


func _panel_with(screen: Control, method: StringName) -> Node:
	for pane: Variant in screen.get(&"_panels"):
		if pane is Node and (pane as Node).has_method(method):
			return pane
	return null


## ---------------------------------------------------------------------------
## A1 - the nine rows, the matrix, the seam, the plate
## ---------------------------------------------------------------------------


func _a1_rows() -> void:
	_check("A1 nine rows", Reg.stations().size() == 9, "count=%d" % Reg.stations().size())
	for id: StringName in PLACES:
		var row := Reg.station(id)
		var want: Array = PLACES[id]
		var ok: bool = not row.is_empty() \
			and String(row.get(&"name")) == want[0] \
			and String(row.get(&"character")) == want[1] \
			and int(row.get(&"sector")) == int(want[2]) \
			and String(row.get(&"kind")) == want[3] \
			and String(row.get(&"faction")) == want[4]
		_check("A1 row %s" % id, ok, "name=%s" % String(row.get(&"name", "")))
	_check("A1 no s7 row", Reg.station(&"s7_primary").is_empty())
	var concord_ok := not Reg.offers(Reg.station(&"s1_primary"), Reg.SERVICE_ARENA) \
		and not Reg.offers(Reg.station(&"s2_primary"), Reg.SERVICE_ARENA)
	var choir_ok := not Reg.offers(Reg.station(&"s5_primary"), Reg.SERVICE_INSURANCE) \
		and not Reg.offers(Reg.station(&"s6_primary"), Reg.SERVICE_INSURANCE) \
		and Reg.offers(Reg.station(&"s5_primary"), Reg.SERVICE_ARENA)
	var meridian_ok := Reg.offers(Reg.station(&"s3_primary"), Reg.SERVICE_INSURANCE) \
		and Reg.offers(Reg.station(&"s3_primary"), Reg.SERVICE_ARENA) \
		and Reg.offers(Reg.station(&"s4_primary"), Reg.SERVICE_INSURANCE)
	var outpost_ok := true
	for outpost: StringName in [&"s2_outpost", &"s4_outpost", &"s5_shrine"]:
		var row := Reg.station(outpost)
		outpost_ok = outpost_ok \
			and Reg.offers(row, Reg.SERVICE_CONTRACTS) \
			and Reg.offers(row, Reg.SERVICE_BOUNTY) \
			and Reg.offers(row, Reg.SERVICE_VAULTS) \
			and not Reg.offers(row, Reg.SERVICE_INSURANCE) \
			and not Reg.offers(row, Reg.SERVICE_ARENA) \
			and int(row.get(&"vault_tiers", 0)) == 1
	_check("A1 concord primaries no arena (§1)", concord_ok)
	_check("A1 choir primaries no insurance (§1)", choir_ok)
	_check("A1 meridian primaries full menu (§1)", meridian_ok)
	_check("A1 outposts §8's three + tier 1", outpost_ok)
	_check(
		"A1 outpost refuel/recharge (B1 deviation 1, §1's own row)",
		Reg.offers(Reg.station(&"s2_outpost"), Reg.SERVICE_REFUEL)
			and Reg.offers(Reg.station(&"s2_outpost"), Reg.SERVICE_RECHARGE),
	)


func _a1_seam() -> void:
	var profile := _fresh()
	_check("A1 nothing filed", Reg.docked_station(profile).is_empty())
	_check("A1 null profile", Reg.docked_station(null).is_empty())
	profile.call(&"set_docked_station", &"s2_outpost")
	_check(
		"A1 outpost resolves by its own row",
		String(Reg.docked_station(profile).get(&"id")) == "s2_outpost",
	)
	profile.call(&"set_docked_station", &"s9_primary")
	_check(
		"A1 unknown id -> sector primary fallback or empty",
		Reg.docked_station(profile).is_empty()
			or String(Reg.docked_station(profile).get(&"kind")) == "primary",
	)


func _a1_plate() -> void:
	for id: StringName in [&"s1_primary", &"s3_primary", &"s5_primary"]:
		_dock(_profile, id, 0)
		var screen := _mount_station()
		await get_tree().process_frame
		var name_label := screen.get_node(NodePath("%StationName")) as Label
		var location := screen.get_node(NodePath("%StationLocation")) as Label
		var row := Reg.station(id)
		_check(
			"A1 plate %s" % id,
			String(name_label.text) == String(row[&"name"])
				and String(location.text) == String(row[&"character"]),
			"%s / %s" % [name_label.text, location.text],
		)
		var placeholders := 0
		var hits := ""
		for label: Node in screen.find_children("*", "Label", true, false):
			var text := (label as Label).text
			if text.contains("ORBITAL DRYDOCK") or text.contains("DOCKING RING 04"):
				placeholders += 1
				hits += "%s " % String(label.get(&"text")).left(30)
		_check(
			"A1 no plate placeholder at %s" % id,
			placeholders == 0,
			"hits=%d %s" % [placeholders, hits],
		)


## ---------------------------------------------------------------------------
## A2 - the price law, both directions
## ---------------------------------------------------------------------------


func _a2_price_law() -> void:
	var profile := _fresh()
	profile.call(&"set_vitals", SHIP, 200, 300)
	var s2 := Reg.station(&"s2_primary")
	_dock(profile, &"s2_primary", 0)
	var neutral_fee := int(Repairs.fee(profile, SHIP))
	_dock(profile, &"s2_primary", SHUNNED)
	var shunned_fee := int(Repairs.fee(profile, SHIP))
	_dock(profile, &"s2_primary", TRUSTED)
	var trusted_fee := int(Repairs.fee(profile, SHIP))
	_dock(profile, &"s2_primary", CHAMPION)
	var champion_fee := int(Repairs.fee(profile, SHIP))
	_check(
		"A2 repair fee Shunned +10 %",
		shunned_fee == roundi(neutral_fee * 1.10),
		"%d -> %d" % [neutral_fee, shunned_fee],
	)
	_check(
		"A2 repair fee Trusted -5 %",
		trusted_fee == roundi(neutral_fee * 0.95),
		"-> %d" % trusted_fee,
	)
	_check(
		"A2 repair fee Champion -10 %",
		champion_fee == roundi(neutral_fee * 0.90),
		"-> %d" % champion_fee,
	)
	profile.call(&"set_docked_station", &"")
	_check(
		"A2 no station reads the §6 figure",
		int(Repairs.fee(profile, SHIP)) == neutral_fee,
	)
	var list_proton := int(Modules.module(&"w_proton").get(&"cost", 0))
	var s1 := Reg.station(&"s1_primary")
	var s5 := Reg.station(&"s5_primary")
	_check(
		"A2 module list Shunned +10 %",
		Reg.apply_price(list_proton, s1, SHUNNED, &"w_proton") == roundi(list_proton * 1.10),
		"list=%d" % list_proton,
	)
	_check(
		"A2 module list Champion -10 %",
		Reg.apply_price(list_proton, s1, CHAMPION, &"w_proton") == roundi(list_proton * 0.90),
	)
	_check(
		"A2 additive stack 0.75 at a Choir station",
		Reg.apply_price(list_proton, s5, CHAMPION, &"w_proton") == roundi(list_proton * 0.75),
		"%d" % Reg.apply_price(list_proton, s5, CHAMPION, &"w_proton"),
	)
	_check(
		"A2 stack is additive, not multiplicative (0.765 rejected)",
		Reg.apply_price(list_proton, s5, CHAMPION, &"w_proton") != roundi(list_proton * 0.85 * 0.90),
	)
	_dock(_profile, &"s5_primary", CHAMPION)
	var screen := _mount_station()
	await get_tree().process_frame
	var armory := _panel_with(screen, &"_module_price")
	_check(
		"A2 the armory pane's own row reads 0.75 x list",
		armory != null
			and int(armory.call(&"_module_price", &"w_proton")) == roundi(list_proton * 0.75),
		"%d" % (int(armory.call(&"_module_price", &"w_proton")) if armory != null else -1),
	)


func _a2_commission() -> void:
	var s3 := Reg.station(&"s3_primary")
	var s1 := Reg.station(&"s1_primary")
	_check("A2 commission 1.5 %% at Meridian" % [], is_equal_approx(Exchange.commission_rate(s3), 0.015))
	_check("A2 commission 2 % elsewhere", is_equal_approx(Exchange.commission_rate(s1), 0.02))
	_check("A2 commission 2 % off-station", is_equal_approx(Exchange.commission_rate({}), 0.02))
	_check(
		"A2 Meridian fee = 1.5 % of gross",
		Exchange.commission_for(1800, s3) == 27,
	)
	_check("A2 elsewhere = 2 % of gross", Exchange.commission_for(1800, s1) == 36)
	_check(
		"A2 the 10 CR floor unchanged both rates",
		Exchange.commission_for(400, s3) == 10 and Exchange.commission_for(400, s1) == 10,
	)
	_check(
		"A2 ammo exemption at the station's own rate",
		Exchange.commission_for_item(&"ammo_laser", 400, s3) == 6
			and Exchange.commission_for_item(&"ammo_laser", 400, s1) == 8,
	)
	var profile := _fresh()
	profile.call(&"add_cargo", &"mineral_iron", 100)
	_dock(profile, &"s3_primary", SHUNNED)
	var shunned: Dictionary = Exchange.quote(profile, &"mineral_iron", 100, 1000000)
	_dock(profile, &"s3_primary", CHAMPION)
	var champion: Dictionary = Exchange.quote(profile, &"mineral_iron", 100, 1000000)
	_check(
		"A2 exchange quotes take no band multiplier",
		int(shunned[&"gross"]) == int(champion[&"gross"])
			and int(shunned[&"unit"]) == int(champion[&"unit"])
			and int(shunned[&"fee"]) == int(champion[&"fee"]),
		"fee=%d" % int(champion[&"fee"]),
	)


## ---------------------------------------------------------------------------
## A3 - the standing effects
## ---------------------------------------------------------------------------


func _a3_predicates() -> void:
	_check("A3 contracts hidden at the Shunned ceiling", not Reg.contracts_visible(-11))
	_check("A3 contracts offered one above", Reg.contracts_visible(-10))
	_check("A3 contracts hidden at Outlaw", not Reg.contracts_visible(-100))
	_check("A3 insurance 0.8 at the floor 71", Reg.insurance_multiplier(71) == 0.8)
	_check("A3 insurance 1.0 at 70", Reg.insurance_multiplier(70) == 1.0)
	_check("A3 insurance 1.0 elsewhere", Reg.insurance_multiplier(0) == 1.0)


func _a3_hot_pair() -> void:
	var profile := _fresh()
	_dock(profile, &"s2_primary", KNOWN)
	var rng := _stream()
	var second := 0
	var priced_ok := true
	for _draw: int in 256:
		_shelf(profile, rng)
		if Auction.hot_ids(profile).size() == 2:
			second += 1
		for row: Dictionary in Auction.listing_rows(profile):
			if bool(row[&"hot"]):
				priced_ok = priced_ok and int(row[&"price"]) == Auction.hot_price(int(row[&"was"]))
		for row: Dictionary in Auction.hull_rows(profile):
			if bool(row[&"hot"]):
				priced_ok = priced_ok and int(row[&"price"]) == Auction.hot_price(int(row[&"list"]))
	_check(
		"A3 Known's second hot row ~half of 256 seeded shelves",
		second > 88 and second < 168,
		"second=%d/256" % second,
	)
	_check("A3 both hot rows price the -20 % last", priced_ok)
	_dock(profile, &"s2_primary", 0)
	rng = _stream()
	var neutral_second := 0
	for _draw: int in 64:
		_shelf(profile, rng)
		if Auction.hot_ids(profile).size() == 2:
			neutral_second += 1
	_check("A3 Neutral carries one hot row only", neutral_second == 0)


func _a3_reserved_slot() -> void:
	var profile := _fresh()
	_dock(profile, &"s3_primary", TRUSTED)
	var rng := _stream()
	var tier := SectorReg.sector_tier(&"sector_3")
	var sized_ok := true
	var reserved_ok := true
	for _draw: int in 24:
		var shelf := _shelf(profile, rng)
		sized_ok = sized_ok \
			and (shelf[&"hulls"] as Array).size() == 6 \
			and (shelf[&"modules"] as Dictionary).size() == 20
		var base := _first_rolled_base(shelf)
		reserved_ok = reserved_ok and base != &"" and int(Modules.module(base)[&"tier"]) == tier
	_check("A3 Trusted's reserved slot reads the sector band", reserved_ok, "tier=%d" % tier)
	_check("A3 shelf stays 6 + 20 at Trusted", sized_ok)
	_dock(profile, &"s3_primary", 0)
	rng = _stream()
	var tiers := {}
	for _draw: int in 24:
		var base := _first_rolled_base(_shelf(profile, rng))
		tiers[int(Modules.module(base)[&"tier"])] = true
	_check("A3 Neutral's ordinary draw reaches several tiers", tiers.size() > 1, str(tiers.keys()))


func _a3_shelf_bias() -> void:
	var families := Reg.tech_families(&"choir")
	var plain := _fresh()
	var choir := _fresh()
	_dock(choir, &"s5_primary", 0)
	var plain_rng := _stream()
	var choir_rng := _stream()
	var plain_hits := 0
	var plain_total := 0
	var choir_hits := 0
	var choir_total := 0
	for _draw: int in 80:
		var plain_shelf := _shelf(plain, plain_rng)
		for base: StringName in _rolled_of(plain_shelf):
			plain_total += 1
			if families.has(Reg.family_of(base)):
				plain_hits += 1
		var choir_shelf := _shelf(choir, choir_rng)
		for base: StringName in _rolled_of(choir_shelf):
			choir_total += 1
			if families.has(Reg.family_of(base)):
				choir_hits += 1
	var plain_share := float(plain_hits) / maxf(float(plain_total), 1.0)
	var choir_share := float(choir_hits) / maxf(float(choir_total), 1.0)
	_check(
		"A3 V6 the owner's families weigh x2 in the rolled draw",
		choir_share > plain_share * 1.3,
		"choir=%.4f plain=%.4f" % [choir_share, plain_share],
	)
	_check(
		"A3 shelf_bias 2.0 / 1.0",
		Reg.shelf_bias(Reg.station(&"s5_primary"), &"s_ion") == 2.0
			and Reg.shelf_bias(Reg.station(&"s5_primary"), &"h_composite") == 1.0,
	)


func _a3_dock_gate() -> void:
	var scene := _open_game()
	if scene == null:
		_check("A3 two axes", false, "no game scene")
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	var gates: Array = sector.call(&"gates")
	var row_id := StringName((sector.get(&"_row") as Dictionary).get(&"id", &""))
	var routes: Array = []
	scene.connect(
		&"route_requested",
		func(_route: StringName, _params: Dictionary) -> void: routes.append(1)
	)
	ship.global_position = sector.call(&"station_position")
	scene.call(&"_request_dock")
	_check(
		"A3 the dock files the station beside the faction",
		routes.size() == 1
			and String(_profile.call(&"docked_station"))
				== String(Reg.primary_for(row_id).get(&"id"))
			and String(_profile.call(&"docked_faction"))
				== String(Reg.primary_for(row_id).get(&"faction")),
	)
	var owner := StringName((sector.get(&"_row") as Dictionary).get(&"owner", &""))
	_profile.call(&"set_heat", {})
	_profile.call(&"set_standing", {String(owner): -51})
	_check("A3 dock refuses at -51", bool(scene.call(&"_dock_refused")))
	if gates.is_empty():
		_check("A3 gate ticket", false, "no gate in the fixture sector")
		return
	ship.global_position = (gates[0] as Node2D).global_position
	scene.call(&"_update_dock_prompt")
	_check(
		"A3 clean-heat Outlaw is sold the gate ticket",
		String(scene.get(&"_prompt")).begins_with("JUMP TO"),
	)
	_profile.call(&"set_standing", {String(owner): -50})
	_check("A3 dock opens one above the floor", not bool(scene.call(&"_dock_refused")))
	_profile.call(&"set_standing", {})
	_profile.call(&"set_heat", {String(owner): 95})
	scene.call(&"_update_dock_prompt")
	_check(
		"A3 outlaw heat refuses the gate",
		String(scene.get(&"_prompt")) == GATE_REFUSED_PROMPT,
		"prompt=%s" % String(scene.get(&"_prompt")),
	)
	_check("A3 clean standing dock does not refuse", not bool(scene.call(&"_dock_refused")))


## ---------------------------------------------------------------------------
## A4 - the per-sector band
## ---------------------------------------------------------------------------


func _a4_bands() -> void:
	var want := {
		&"sector_1": [&"pirate"],
		&"sector_2": [&"pirate"],
		&"sector_3": [&"pirate", &"swarmer"],
		&"sector_4": [&"pirate", &"swarmer"],
		&"sector_5": [&"swarmer", &"sibelon", &"pirate"],
		&"sector_6": [&"swarmer", &"sibelon", &"pirate"],
		&"sector_7": [&"pirate", &"swarmer"],
	}
	var bands_ok := true
	for id: StringName in want:
		var band := SectorReg.hostile_band(id)
		var expected: Array = want[id]
		if band.size() != expected.size():
			bands_ok = false
			continue
		for index in expected.size():
			if band[index] != StringName(expected[index]):
				bands_ok = false
	_check("A4 the seven bands are R-S24-2 verbatim, in order", bands_ok)
	var densities := [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8),
	]
	var sums_ok := true
	for index: int in SectorReg.sector_ids().size():
		var sector: StringName = SectorReg.sector_ids()[index]
		var total := Vector2i.ZERO
		for filler: StringName in [&"pirate", &"swarmer", &"sibelon"]:
			total += NpcReg.density(filler, sector)
		if total != densities[index]:
			sums_ok = false
	_check("A4 the columns still sum to 13 §4's densities", sums_ok)
	_check(
		"A4 S6's pirate takes the remainder",
		NpcReg.density(&"pirate", &"sector_6") == Vector2i(2, 4)
			and NpcReg.density(&"swarmer", &"sector_6") == Vector2i(1, 1),
	)
	_check("A4 no sibelon in S7", NpcReg.density(&"sibelon", &"sector_7") == Vector2i.ZERO)
	var hunters_ok := true
	for row: Dictionary in SectorReg.SECTORS:
		if NpcReg.density(NpcReg.ARCHETYPE_HUNTER, StringName(row[&"id"])) != Vector2i.ZERO:
			hunters_ok = false
		for spawn: Dictionary in NpcReg.spawns_for(StringName(row[&"id"])):
			if StringName(spawn[NpcReg.KEY_ARCHETYPE]) == NpcReg.ARCHETYPE_HUNTER:
				hunters_ok = false
	_check("A4 hunters stay heat-driven map-wide", hunters_ok)
	_check(
		"A4 the heat path still answers a wing",
		int(NpcReg.hunter_spawn(&"sector_1", SHIP).get(NpcReg.KEY_MAX, 0)) > 0,
	)


## ---------------------------------------------------------------------------
## A5 - the nebula
## ---------------------------------------------------------------------------


func _a5_cloud_roll() -> void:
	var rng := _stream()
	var counts := {}
	var geometry_ok := true
	for _roll: int in 64:
		var rolled := SectorReg.roll_clouds(rng)
		counts[rolled.size()] = true
		for cloud: Dictionary in rolled:
			var reach: float = (cloud[&"centre"] as Vector2).length()
			geometry_ok = geometry_ok \
				and float(cloud[&"radius"]) == 900.0 \
				and reach >= 1500.0 \
				and reach <= SectorReg.cloud_outer_bound()
	_check("A5 0-2 clouds, radius 900, clearance 1500..outer", geometry_ok)
	_check("A5 several counts occur over 64 rolls", counts.size() >= 2, str(counts.keys()))
	_check("A5 the seeded stream decides the roll", SectorReg.roll_clouds(_stream()) == SectorReg.roll_clouds(_stream()))


func _a5_cloud_readings() -> void:
	var scene := _open_game()
	if scene == null:
		_check("A5 readings", false, "no game scene")
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	var found := -1
	var row := SectorReg.sector(&"sector_1")
	for seed_value in range(1, 64):
		sector.call(&"populate", row, seed_value)
		if not SectorReg.clouds(&"sector_1").is_empty():
			found = seed_value
			break
	_check("A5 a seed inside 1..64 rolls a cloud", found > 0, "seed=%d" % found)
	if found < 0:
		return
	var rolled := SectorReg.clouds(&"sector_1")
	var nodes: Array = sector.call(&"cloud_nodes")
	var wash := Color(SectorReg.CLOUD_WASH, SectorReg.CLOUD_WASH_ALPHA)
	var node_ok := nodes.size() == rolled.size()
	if node_ok:
		node_ok = (nodes[0] as Node2D).position == (rolled[0][&"centre"] as Vector2) \
			and (nodes[0].get(&"wash") as Color) == wash
	_check("A5 one node per rolled row, on its centre, in the wash", node_ok)
	var zoom := float(scene.get(&"_minimap_radius"))
	var lock := float((scene.get(&"_stats") as Object).get(&"lock_range"))
	ship.global_position = rolled[0][&"centre"]
	scene.call(&"_update_clouds")
	_check(
		"A5 inside: lock halves",
		is_equal_approx(float(scene.call(&"_lock_range")), lock * 0.5),
	)
	_check(
		"A5 inside: the POI channel reads 150 u",
		is_equal_approx(float(scene.call(&"_scan_range")), 150.0),
	)
	_check(
		"A5 inside: the pushed minimap radius halves, the zoom state never moves",
		is_equal_approx(float(scene.call(&"_minimap_radius_shown")), zoom * 0.5)
			and is_equal_approx(float((scene.get(&"_hud") as Object).get(&"_minimap_radius")), zoom * 0.5)
			and is_equal_approx(float(scene.get(&"_minimap_radius")), zoom),
	)
	_check(
		"A5 inside: the hull carries the 15 % wash tint",
		(ship.modulate as Color).is_equal_approx(Color.WHITE.lerp(SectorReg.CLOUD_WASH, 0.15)),
	)
	var outside := Vector2.ZERO
	for step in 64:
		var candidate := Vector2.RIGHT.rotated(TAU * float(step) / 64.0) * 4900.0
		if not SectorReg.in_cloud(rolled, candidate):
			outside = candidate
			break
	_check("A5 an outside point exists", outside != Vector2.ZERO)
	ship.global_position = outside
	scene.call(&"_update_clouds")
	_check(
		"A5 outside: the shipped values exactly",
		is_equal_approx(float(scene.call(&"_cloud_factor_now")), 1.0)
			and is_equal_approx(float(scene.call(&"_lock_range")), lock)
			and is_equal_approx(float(scene.call(&"_scan_range")), 300.0)
			and is_equal_approx(float(scene.call(&"_minimap_radius_shown")), zoom),
	)
	_check(
		"A5 outside: the tint is gone",
		(ship.modulate as Color).is_equal_approx(Color.WHITE),
	)


## ---------------------------------------------------------------------------
## The two mechanism choices
## ---------------------------------------------------------------------------


func _mechanisms() -> void:
	var profile := _fresh()
	_dock(profile, &"s2_primary", KNOWN)
	var rng := _stream()
	_shelf(profile, rng)
	_check(
		"M1 the shelf keeps CONTRACTS §15's four members",
		(profile.call(&"auction") as Dictionary).keys().size() == 4,
		str((profile.call(&"auction") as Dictionary).keys()),
	)
	var first := Auction.hot_id(profile)
	var second_once := Auction.second_hot_id(profile, first)
	var second_again := Auction.second_hot_id(profile, first)
	_check(
		"M1 the derived second row is deterministic per shelf",
		second_once == second_again,
		"second=%s" % String(second_once),
	)
	var s6 := SectorReg.sector_tier(&"sector_6")
	var pool4 := Auction.tier_pool(4)
	_dock(profile, &"s6_primary", TRUSTED)
	rng = _stream()
	var clamped_ok := true
	for _draw: int in 12:
		var base := _first_rolled_base(_shelf(profile, rng))
		clamped_ok = clamped_ok and base != &"" and int(Modules.module(base)[&"tier"]) == 3
	_check(
		"M2 sector_tier(S6)=4, tier_pool(4) empty, the clamp keeps the slot at tier 3",
		s6 == 4 and pool4.is_empty() and clamped_ok,
		"tier=%d pool4=%d" % [s6, pool4.size()],
	)
