@tool
extends McpTestSuite
## Suite s24_bands: wave S24's world identity, builder 2's half - `12_factions.md`'s
## 2026-10-08 block (V3-V7: `contracts_visible`, the Known hot pair, the Trusted reserved
## slot, the shelf bias and the insurance seam, plus the auction's price-law gap),
## `13_heat_bounty.md`'s 2026-09-27 R-S24-2 / 2026-10-08 block (the band on the sector row)
## and `11_galactic_map.md`'s R-S24-3 / 2026-10-08 block (the clouds and the three cover
## readings).
##
## One row per pinned acceptance. The auction is drawn on throwaway profiles (the shape
## `test_s3_auction.gd` uses); the flight scene is mounted the way `test_s6_heat.gd` mounts
## it (the shipped scene, the shipped profile borrowed and handed back).

const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const AuctionScript := preload("res://game/auction.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const CatalogScript := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const GameScript := preload("res://game/game.gd")

const GAME_SCENE := "res://game/game.tscn"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s24_bands.cfg"
const SEED := 20261008
const SHIP: StringName = &"ship_vanguard"

## 12 section 4.1's band table, at a value inside each band (Shunned <= -11, Known >= 11,
## Trusted >= 41, Champion >= 71), plus the Outlaw floor the dock refusal reads.
const OUTLAW := -51
const SHUNNED := -20
const NEUTRAL := 0
const KNOWN := 11
const TRUSTED := 50
const CHAMPION := 80
const HEAT_OUTLAW := 95

## R-S24-2 verbatim (13's 2026-09-27 P3 block): each sector's band, in fill order.
const BANDS: Array[Dictionary] = [
	{&"sector": &"sector_1", &"band": "pirate"},
	{&"sector": &"sector_2", &"band": "pirate"},
	{&"sector": &"sector_3", &"band": "pirate,swarmer"},
	{&"sector": &"sector_4", &"band": "pirate,swarmer"},
	{&"sector": &"sector_5", &"band": "swarmer,sibelon,pirate"},
	{&"sector": &"sector_6", &"band": "swarmer,sibelon,pirate"},
	{&"sector": &"sector_7", &"band": "pirate,swarmer"},
]

## 13 section 4's own densities, S1 to S7.
const DENSITIES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
	Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8),
]

const HOT_DRAWS := 64
const BIAS_DRAWS := 80
const RESERVE_DRAWS := 24
const CLOUD_DRAWS := 64
const CLOUD_SEED_SCAN := 64

var _profile: ProfileScript = null
var _scenes: Array[Node] = []
var _profiles: Array[Node] = []
var _previous: Dictionary = {}


func suite_name() -> String:
	return "s24_bands"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the flight scene")
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
		&"market": (_profile.call(&"market") as Dictionary).duplicate(true),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"heat": (_profile.call(&"heat") as Dictionary).duplicate(true),
		&"docked_faction": StringName(_profile.call(&"docked_faction")),
		&"docked_station": StringName(_profile.call(&"docked_station")),
		&"active_ship": StringName(_profile.call(&"active_ship")),
		&"owned": (_profile.get(&"_owned_ships") as Array).duplicate(true),
		&"modules": (_profile.get(&"_modules") as Dictionary).duplicate(true),
		&"vitals": (_profile.get(&"_vitals") as Dictionary).duplicate(true),
		&"auction": (_profile.call(&"auction") as Dictionary).duplicate(true),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 500000)
	_profile.call(&"set_standing", {})
	_profile.call(&"set_heat", {})
	_profile.call(&"set_docked_faction", &"")
	_profile.call(&"set_docked_station", &"")


func suite_teardown() -> void:
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
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
			&"market":
				_profile.call(&"set_market", value)
			&"standing":
				_profile.call(&"set_standing", value)
			&"heat":
				_profile.call(&"set_heat", value)
			&"docked_faction":
				_profile.call(&"set_docked_faction", value)
			&"docked_station":
				_profile.call(&"set_docked_station", value)
			&"active_ship":
				_profile.set(&"_active_ship", value)
			&"owned":
				_profile.set(&"_owned_ships", value)
			&"modules":
				_profile.set(&"_modules", value)
			&"vitals":
				_profile.set(&"_vitals", value)
			&"auction":
				_profile.call(&"set_auction", value)
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## Harnesses
## ---------------------------------------------------------------------------


func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## A throwaway profile whose store is the scratch file, never the live account.
func _fresh() -> Node:
	var profile := ProfileScript.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


## A station dock files the place's own owner as the faction (`game.gd` files both), so a
## fixture that prices a shelf starts from what a real dock leaves behind.
func _dock(profile: Node, station_id: StringName, standing: int) -> void:
	var row := StationRegistryScript.station(station_id)
	profile.call(&"set_docked_station", station_id)
	profile.call(
		&"set_standing",
		{String(StringName(row.get(&"faction", &""))): standing} if not row.is_empty() else {}
	)
	profile.call(&"set_docked_faction", StringName(row.get(&"faction", &"")))


func _stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng


## One shelf drawn from both fixed streams (the local one for the hull/tier/hot draws, the
## global seed for `roll_listing`'s rarity and affix rolls - `test_s3_auction.gd`'s reason),
## stamped on the profile so every reader sees it.
func _shelf(profile: Node) -> Dictionary:
	seed(SEED)
	var shelf: Dictionary = AuctionScript.draw_shelf(profile, _stream())
	profile.call(&"set_auction", shelf)
	return shelf


## A run of shelves off **one advancing** stream, returned whole: for a probe that measures
## the shelves themselves. A probe that reads the profile per draw must use `_next_shelf`
## instead - `_draw_run` finishes before its caller's loop body runs, so the profile would
## hold the run's **last** shelf for every iteration.
func _draw_run(profile: Node, count: int) -> Array[Dictionary]:
	seed(SEED)
	var rng := _stream()
	var out: Array[Dictionary] = []
	for _draw: int in count:
		var shelf: Dictionary = AuctionScript.draw_shelf(profile, rng)
		profile.call(&"set_auction", shelf)
		out.append(shelf)
	return out


## One shelf off a stream the caller keeps across its own loop, stamped on the profile so
## the iteration's assertions read the shelf it just drew.
func _next_shelf(profile: Node, rng: RandomNumberGenerator) -> Dictionary:
	var shelf: Dictionary = AuctionScript.draw_shelf(profile, rng)
	profile.call(&"set_auction", shelf)
	return shelf


## The base id of the shelf's **first rolled** module slot: the first key after the F lot
## (15 section 8's interim keeps the exclusive in slot 0).
func _first_rolled_base(shelf: Dictionary) -> StringName:
	var listings: Dictionary = shelf[&"modules"]
	var keys: Array = listings.keys()
	var index := 0
	if not keys.is_empty():
		var first: Dictionary = listings[keys[0]]
		if ModuleData.EXCLUSIVES.has(StringName(first[&"base_id"])):
			index = 1
	if index >= keys.size():
		return &""
	return StringName((listings[keys[index]] as Dictionary)[&"base_id"])


## The nine rolled slots after the F lot, as base ids.
func _rolled_bases(shelf: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var listings: Dictionary = shelf[&"modules"]
	var keys: Array = listings.keys()
	for index in keys.size():
		var record: Dictionary = listings[keys[index]]
		var base := StringName(record[&"base_id"])
		if index == 0 and ModuleData.EXCLUSIVES.has(base):
			continue
		if index >= AuctionScript.MODULE_SLOTS:
			continue
		out.append(base)
	return out


## The share of the rolled draw that lands on one owner's own tech families.
func _family_share(profile: Node, faction: StringName) -> float:
	var families := StationRegistryScript.tech_families(faction)
	var hits := 0
	var total := 0
	for shelf: Dictionary in _draw_run(profile, BIAS_DRAWS):
		for base: StringName in _rolled_bases(shelf):
			total += 1
			if families.has(StationRegistryScript.family_of(base)):
				hits += 1
	return float(hits) / float(maxi(total, 1))


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


## The first seed whose sector-1 roll draws at least one cloud, with the sector populated
## on it. Returns -1 when the scan finds none (the suite then fails on its own assert).
func _populate_until_clouds(sector: Node) -> int:
	var row := SectorRegistryScript.sector(&"sector_1")
	for seed_value in range(1, CLOUD_SEED_SCAN):
		sector.call(&"populate", row, seed_value)
		if not SectorRegistryScript.clouds(&"sector_1").is_empty():
			return seed_value
	return -1


## A point no rolled cloud covers: the bearings at the arena's inner edge first, then the
## four corners. `Vector2.ZERO` when the scan finds none (a failure the caller asserts on).
func _outside_point(rolled: Array[Dictionary]) -> Vector2:
	var candidates: Array[Vector2] = []
	for step in 32:
		candidates.append(Vector2.RIGHT.rotated(TAU * float(step) / 32.0) * 4900.0)
	candidates.append(Vector2(-4800.0, -4800.0))
	candidates.append(Vector2(4800.0, 4800.0))
	for candidate: Vector2 in candidates:
		if not SectorRegistryScript.in_cloud(rolled, candidate):
			return candidate
	return Vector2.ZERO


## ---------------------------------------------------------------------------
## A3 - the standing effects (12's 2026-10-08 V3-V7 block)
## ---------------------------------------------------------------------------


## V3: `contracts_visible` reads standing above -11 - Shunned and Outlaw see no contracts,
## Neutral and above do. S25 owns the board that reads it.
func test_contracts_visible_reads_above_minus_eleven() -> void:
	assert_false(StationRegistryScript.contracts_visible(OUTLAW), "Outlaw: none")
	assert_false(StationRegistryScript.contracts_visible(-51), "the dock refusal's own floor")
	assert_false(StationRegistryScript.contracts_visible(-11), "Shunned's ceiling: none")
	assert_false(StationRegistryScript.contracts_visible(SHUNNED), "Shunned: none")
	assert_true(StationRegistryScript.contracts_visible(-10), "one above the ceiling: offered")
	assert_true(StationRegistryScript.contracts_visible(NEUTRAL), "Neutral: offered")
	assert_true(StationRegistryScript.contracts_visible(KNOWN), "Known: offered")
	assert_true(StationRegistryScript.contracts_visible(CHAMPION), "Champion: offered")


## V7: the insurance seam reads 0.8 at Champion and 1.0 everywhere else. S26 owns the
## premium table and its consumer.
func test_the_insurance_seam_reads_point_eight_at_champion() -> void:
	assert_eq(StationRegistryScript.INSURANCE_CHAMPION, 0.8, "12 section 4.1's x0.8")
	assert_eq(
		StationRegistryScript.insurance_multiplier(CHAMPION), 0.8, "Champion: 0.8"
	)
	assert_eq(
		StationRegistryScript.insurance_multiplier(71), 0.8, "the Champion floor itself"
	)
	assert_eq(StationRegistryScript.insurance_multiplier(70), 1.0, "one below: 1.0")
	assert_eq(StationRegistryScript.insurance_multiplier(TRUSTED), 1.0, "Trusted: 1.0")
	assert_eq(StationRegistryScript.insurance_multiplier(NEUTRAL), 1.0, "Neutral: 1.0")
	assert_eq(StationRegistryScript.insurance_multiplier(SHUNNED), 1.0, "Shunned: 1.0")
	assert_eq(StationRegistryScript.insurance_multiplier(OUTLAW), 1.0, "Outlaw: 1.0")


## V4: at Known and above the restock's shelf carries the drawn hot row plus a 50 % chance
## of a second; below Known it carries the shipped single row. The roll rides the shelf's
## own seeded draw, so this is stable per seed.
func test_known_rolls_the_second_hot_row_and_neutral_does_not() -> void:
	seed(SEED)
	var profile := _fresh()
	var rng := _stream()
	_dock(profile, &"s1_primary", NEUTRAL)
	for _draw: int in HOT_DRAWS:
		_next_shelf(profile, rng)
		assert_eq(AuctionScript.hot_ids(profile).size(), 1, "Neutral: the shipped one hot row")
		assert_eq(
			AuctionScript.second_hot_id(profile, AuctionScript.hot_id(profile)), &"",
			"and no second row is derivable"
		)
	_dock(profile, &"s1_primary", -20 + 31)
	assert_eq(KNOWN, 11, "12 section 4.1's Known floor")
	_dock(profile, &"s1_primary", KNOWN)
	var doubles := 0
	for _draw: int in HOT_DRAWS:
		_next_shelf(profile, rng)
		var ids := AuctionScript.hot_ids(profile)
		assert_true(ids.size() >= 1, "Known: the first hot row is guaranteed")
		assert_true(ids.size() <= 2, "and never more than the pair")
		if ids.size() == 2:
			doubles += 1
			assert_ne(ids[0], ids[1], "the second row is its own id")
			assert_eq(ids[0], AuctionScript.hot_id(profile), "the first stays the drawn slot")
	assert_gt(doubles, 0, "the 50 %% second row lands inside %d shelves" % HOT_DRAWS)
	assert_gt(HOT_DRAWS - doubles, 0, "and it misses inside them too")
	assert_true(
		doubles >= HOT_DRAWS / 4 and doubles <= HOT_DRAWS * 3 / 4,
		"roughly half the shelves carry two (%d of %d)" % [doubles, HOT_DRAWS]
	)


## V4's second row is a real -20 % row on both lists, and the station's list is the
## registry's price (V1/V2), so the hot step lands on the station's own figure.
func test_both_hot_rows_charge_the_hot_price() -> void:
	seed(SEED)
	var profile := _fresh()
	var rng := _stream()
	_dock(profile, &"s1_primary", KNOWN)
	var station := StationRegistryScript.station(&"s1_primary")
	var seen_two := false
	for _draw: int in HOT_DRAWS:
		_next_shelf(profile, rng)
		if AuctionScript.hot_ids(profile).size() < 2:
			continue
		seen_two = true
		var hot_rows := 0
		for row: Dictionary in AuctionScript.listing_rows(profile):
			var list := StationRegistryScript.apply_price(
				ModuleData.list_price(row[&"base_id"], row[&"rarity"]),
				station,
				KNOWN,
				row[&"base_id"]
			)
			if bool(row[&"hot"]):
				hot_rows += 1
				assert_eq(int(row[&"price"]), AuctionScript.hot_price(list), "the -20 % row")
				assert_eq(int(row[&"was"]), list, "showing the station's own list")
			else:
				assert_eq(int(row[&"price"]), list, "a plain row charges the station's list")
		var hull_hot := 0
		for row: Dictionary in AuctionScript.hull_rows(profile):
			var list := CatalogScript.ship_price(StringName(row[&"id"]), station, KNOWN)
			if bool(row[&"hot"]):
				hull_hot += 1
				assert_eq(int(row[&"price"]), AuctionScript.hot_price(list), "the hot hull's -20 %")
				assert_eq(int(row[&"list"]), list, "at the station's own hull price")
			else:
				assert_eq(int(row[&"price"]), list, "a plain hull charges the station's list")
		assert_eq(hot_rows + hull_hot, 2, "two hot rows, both at the shipped hot price")
		break
	assert_true(seen_two, "a Known shelf carries the pair inside %d draws" % HOT_DRAWS)


## V5: at Trusted the shelf's first rolled module slot comes off the docked sector's tier
## band, and the shelf's size does not move (six hulls + twenty modules, no extra row).
func test_the_reserved_slot_comes_off_the_sector_band() -> void:
	seed(SEED)
	var profile := _fresh()
	var rng := _stream()
	_dock(profile, &"s3_primary", TRUSTED)
	var tier := SectorRegistryScript.sector_tier(&"sector_3")
	assert_eq(tier, 2, "Meridian Span is a tier-2 sector (11 section 1.1)")
	for _draw: int in RESERVE_DRAWS:
		var shelf := _next_shelf(profile, rng)
		assert_eq((shelf[&"hulls"] as Array).size(), AuctionScript.HULL_SLOTS, "still six hulls")
		assert_eq(
			(shelf[&"modules"] as Dictionary).size(),
			AuctionScript.MODULE_SLOTS + AuctionScript.STOCK_SLOTS,
			"still twenty modules"
		)
		var base := _first_rolled_base(shelf)
		assert_ne(base, &"", "the reserved slot mints a listing")
		assert_eq(
			int(ModuleData.module(base)[&"tier"]), tier,
			"the first rolled slot is the sector's band, not the I/II/III weights"
		)
	## Below Trusted the reservation is gone and 10 section 2.1's weights are back.
	_dock(profile, &"s3_primary", NEUTRAL)
	var tiers: Dictionary = {}
	for _draw: int in RESERVE_DRAWS:
		var base := _first_rolled_base(_next_shelf(profile, rng))
		tiers[int(ModuleData.module(base)[&"tier"])] = true
	assert_true(
		tiers.size() > 1, "the ordinary draw reaches more than one tier (%s)" % str(tiers.keys())
	)


## V6: the station owner's own tech families weigh x2 in the rolled draw - measured, because
## the hook is a weight and not a filter.
func test_the_shelf_bias_weights_the_owners_families() -> void:
	var station := StationRegistryScript.station(&"s5_primary")
	assert_eq(StationRegistryScript.shelf_bias(station, &"s_ion"), 2.0, "a Choir shield")
	assert_eq(StationRegistryScript.shelf_bias(station, &"w_plasma"), 2.0, "a Choir plasma line")
	assert_eq(StationRegistryScript.shelf_bias(station, &"h_composite"), 1.0, "Concord armour")
	assert_eq(StationRegistryScript.shelf_bias({}, &"s_ion"), 1.0, "no station: uniform")
	var plain := _fresh()
	var choir := _fresh()
	_dock(choir, &"s5_primary", NEUTRAL)
	var plain_own := _family_share(plain, &"choir")
	var choir_own := _family_share(choir, &"choir")
	var choir_other := _family_share(choir, &"concord")
	var plain_other := _family_share(plain, &"concord")
	assert_true(
		choir_own > plain_own * 1.3,
		"the Choir's own families draw x2 at Cinder Gate (%.4f vs %.4f)" % [choir_own, plain_own]
	)
	assert_true(
		choir_other < plain_other,
		"and everyone else's share falls (%.4f vs %.4f)" % [choir_other, plain_other]
	)


## V1/V2 on the shelf: the hull list, the module list, `buy_hull` and `buy_listing` all read
## the registry's price law (the band, then the owner's tech step, then the hot row's -20 %).
func test_the_shelf_prices_through_the_registry() -> void:
	for entry: Array in [[NEUTRAL, 1.0], [SHUNNED, 1.10], [TRUSTED, 0.95], [CHAMPION, 0.90]]:
		var profile := _fresh()
		_shelf(profile)
		var hull_id := AuctionScript.hull_ids(profile)[0]
		var base_cost := int(CatalogScript.ship(hull_id)[&"cost"])
		var listing := _band_only_listing(profile)
		assert_false(listing.is_empty(), "the shelf lists a module outside the owner's families")
		if listing.is_empty():
			return
		var plain := ModuleData.list_price(listing[&"base_id"], listing[&"rarity"])
		_dock(profile, &"s1_primary", int(entry[0]))
		var hull := _hull_row(profile, hull_id)
		assert_eq(
			int(hull[&"list"]),
			roundi(float(base_cost) * float(entry[1])),
			"standing %d: the hull list is the catalogue's cost through the band" % int(entry[0])
		)
		var row := _listing_row(profile, listing[&"id"])
		assert_eq(
			int(row[&"was"] if bool(row[&"hot"]) else row[&"price"]),
			roundi(float(plain) * float(entry[1])),
			"standing %d: and so is the module list" % int(entry[0])
		)
		assert_eq(
			int(AuctionScript.buy_hull(profile, hull_id)[&"cost"]),
			int(hull[&"price"]),
			"standing %d: buy_hull charges the row's price" % int(entry[0])
		)
		assert_eq(
			int(AuctionScript.buy_listing(profile, listing[&"id"])[&"cost"]),
			int(row[&"price"]),
			"standing %d: and buy_listing the listing's" % int(entry[0])
		)
	## V2's additive stack, on the owner's own family: Champion of the Choir at Cinder Gate
	## reads 0.75 x list on a Choir module (a Champion of the Concord at a Concord station
	## reads the same on armour or an engine).
	var choir := _fresh()
	_shelf(choir)
	var choir_family_listing := _owner_family_listing(choir, &"choir")
	assert_false(choir_family_listing.is_empty(), "the shelf lists a Choir-family module")
	if choir_family_listing.is_empty():
		return
	_dock(choir, &"s5_primary", CHAMPION)
	var choir_row := _listing_row(choir, choir_family_listing[&"id"])
	assert_eq(
		int(choir_row[&"was"] if bool(choir_row[&"hot"]) else choir_row[&"price"]),
		roundi(
			float(ModuleData.list_price(
				choir_family_listing[&"base_id"], choir_family_listing[&"rarity"]
			)) * 0.75
		),
		"a Choir family at a Choir station: -15 % tech and -10 % band, added"
	)


## 12 section 4.1's two axes (13 section 7): the dock refusal reads standing at -51, the
## gate refusal reads the heat tier - a clean-heat Outlaw is still sold a gate ticket.
func test_the_dock_reads_standing_and_the_gate_reads_heat() -> void:
	var scene := _open_game()
	if scene == null or _profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	if sector == null or ship == null:
		return
	var gates: Array = sector.call(&"gates")
	assert_true(gates.size() >= 1, "sector 1 has a gate link")
	if gates.is_empty():
		return
	var owner := StringName((sector.get(&"_row") as Dictionary).get(&"owner", &""))
	var gate: Node2D = gates[0]
	_profile.call(&"set_heat", {})
	_profile.call(&"set_standing", {String(owner): OUTLAW})
	ship.global_position = gate.global_position
	scene.call(&"_update_dock_prompt")
	assert_true(
		String(scene.get(&"_prompt")).begins_with("JUMP TO"),
		"clean heat, standing Outlaw: the gate sells a ticket"
	)
	assert_true(bool(scene.call(&"_dock_refused")), "and the dock refuses at -51")
	_profile.call(&"set_standing", {String(owner): -50})
	assert_false(bool(scene.call(&"_dock_refused")), "one point above the floor: the dock opens")
	_profile.call(&"set_standing", {})
	_profile.call(&"set_heat", {String(owner): HEAT_OUTLAW})
	scene.call(&"_update_dock_prompt")
	assert_eq(
		String(scene.get(&"_prompt")), GameScript.GATE_REFUSED_PROMPT, "13 section 3: refused"
	)
	assert_false(bool(scene.call(&"_dock_refused")), "clean standing: the dock does not care")


## ---------------------------------------------------------------------------
## A4 - the per-sector band (13's R-S24-2 / 2026-10-08 block)
## ---------------------------------------------------------------------------


## R-S24-2 verbatim: every sector row carries its own band, in the row's own order.
func test_each_sector_row_carries_its_band() -> void:
	for entry: Dictionary in BANDS:
		var sector := StringName(entry[&"sector"])
		assert_false(SectorRegistryScript.sector(sector).is_empty(), "%s exists" % sector)
		assert_eq(
			_band_text(SectorRegistryScript.hostile_band(sector)),
			String(entry[&"band"]),
			"%s's band, in fill order" % sector
		)
	assert_eq(SectorRegistryScript.hostile_band(&"sector_9").size(), 0, "an unknown id is empty")


## The row's order is the fill order and the columns still sum to 13 section 4's own
## densities; the alien is a band member in S5-S6 only.
func test_the_band_fills_in_row_order_and_sums_to_section_13() -> void:
	for index in DENSITIES.size():
		var sector := SectorRegistryScript.sector_ids()[index]
		var total := Vector2i.ZERO
		for filler: StringName in [&"pirate", &"swarmer", &"sibelon"]:
			total += NpcRegistryScript.density(filler, sector)
		assert_eq(total, DENSITIES[index], "%s's hostiles sum to 13 section 4" % sector)
	for entry: Dictionary in BANDS:
		var sector := StringName(entry[&"sector"])
		var members := SectorRegistryScript.hostile_band(sector)
		for filler: StringName in [&"pirate", &"swarmer", &"sibelon"]:
			var band := NpcRegistryScript.density(filler, sector)
			if not members.has(filler):
				assert_eq(band, Vector2i.ZERO, "%s is not in %s's band" % [filler, sector])
			elif members.find(filler) == members.size() - 1:
				var index := SectorRegistryScript.sector_ids().find(sector)
				var rest := DENSITIES[index]
				assert_eq(
					band,
					Vector2i(maxi(rest.x - members.size() + 1, 0), maxi(rest.y - members.size() + 1, 0)),
					"%s's last filler takes the rest of %s's band" % [filler, sector]
				)
			else:
				assert_true(band.x <= 1 and band.y <= 1, "a guard slot is one hull")
	## The source moved: with the S23 global order the pirate would be a guard slot and the
	## sibelon the remainder; on the row's order S6 makes the pirate the remainder.
	assert_eq(
		NpcRegistryScript.density(&"pirate", &"sector_6"), Vector2i(2, 4),
		"S6's pirate takes the remainder of 4-6"
	)
	assert_eq(
		NpcRegistryScript.density(&"swarmer", &"sector_6"), Vector2i(1, 1),
		"with the swarmer in slot 0"
	)
	assert_eq(
		NpcRegistryScript.density(&"sibelon", &"sector_7"), Vector2i.ZERO,
		"and no alien in S7"
	)


## Hunters stay heat-driven map-wide: no sector's population carries one and no band names
## it, while the heat path still answers a wing.
func test_hunters_stay_heat_driven_map_wide() -> void:
	for row: Dictionary in SectorRegistryScript.SECTORS:
		var sector := StringName(row[&"id"])
		assert_eq(
			NpcRegistryScript.density(NpcRegistryScript.ARCHETYPE_HUNTER, sector),
			Vector2i.ZERO,
			"%s's band carries no hunter" % sector
		)
		for spawn: Dictionary in NpcRegistryScript.spawns_for(sector):
			assert_ne(
				StringName(spawn[NpcRegistryScript.KEY_ARCHETYPE]),
				NpcRegistryScript.ARCHETYPE_HUNTER,
				"hunters are never part of %s's population" % sector
			)
	var wing := NpcRegistryScript.hunter_spawn(&"sector_1", SHIP)
	assert_false(wing.is_empty(), "13 section 3's heat path still answers a wing")
	assert_gt(int(wing.get(NpcRegistryScript.KEY_MAX, 0)), 0, "with its own 2-3 band")


## ---------------------------------------------------------------------------
## A5 - the nebula (11's R-S24-3 / 2026-10-08 block)
## ---------------------------------------------------------------------------


## V8's roll: 0-2 rows on the caller's own stream, radius 900, centres at least 1500 u from
## the arena centre and inside the arena.
func test_the_cloud_roll_is_zero_to_two_inside_the_clearance() -> void:
	var rng := _stream()
	var counts: Dictionary = {}
	for _roll: int in CLOUD_DRAWS:
		var rolled := SectorRegistryScript.roll_clouds(rng)
		assert_true(rolled.size() <= SectorRegistryScript.CLOUDS_MAX, "at most two clouds")
		counts[rolled.size()] = true
		for cloud: Dictionary in rolled:
			assert_eq(float(cloud[&"radius"]), 900.0, "V8's radius")
			var reach := (cloud[&"centre"] as Vector2).length()
			assert_true(reach >= 1500.0, "V8's clearance from the arena centre (%.1f)" % reach)
			assert_true(
				reach <= SectorRegistryScript.cloud_outer_bound(),
				"and inside the arena (%.1f)" % reach
			)
	assert_eq(counts.keys().size(), 3, "0, 1 and 2 all occur (%s)" % str(counts.keys()))
	assert_eq(
		SectorRegistryScript.roll_clouds(_stream()),
		SectorRegistryScript.roll_clouds(_stream()),
		"the sector's own seeded stream decides the roll"
	)


## The sector row carries the rolled rows and the node draws them itself in the Void Haze
## wash at 15 % alpha.
func test_the_cloud_node_draws_in_the_void_haze_wash() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	if sector == null:
		return
	var found := _populate_until_clouds(sector)
	assert_gt(found, 0, "a seed inside 1..%d rolls at least one cloud" % CLOUD_SEED_SCAN)
	if found < 0:
		return
	var rolled := SectorRegistryScript.clouds(&"sector_1")
	var nodes: Array = sector.call(&"cloud_nodes")
	assert_eq(nodes.size(), rolled.size(), "one node per rolled row")
	assert_eq(
		sector.call(&"clouds"), rolled, "and the sector reads back the rows it filed"
	)
	var wash := Color(SectorRegistryScript.CLOUD_WASH, SectorRegistryScript.CLOUD_WASH_ALPHA)
	assert_eq(SectorRegistryScript.CLOUD_WASH_ALPHA, 0.15, "11's 15 % alpha")
	for index in rolled.size():
		var node: Node2D = nodes[index]
		assert_eq(node.position, rolled[index][&"centre"], "the node sits on its own centre")
		assert_eq(float(node.get(&"radius")), float(rolled[index][&"radius"]), "with its radius")
		assert_eq(node.get(&"wash"), wash, "in the Void Haze wash at 15 %")


## R-S24-3 inside a cloud: the lock range, the POI scan range and the minimap radius all read
## x0.5, and the hull carries the 15 % tint. The player's own zoom state never moves.
func test_inside_a_cloud_the_three_readings_halve() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	if sector == null or ship == null:
		return
	var found := _populate_until_clouds(sector)
	assert_gt(found, 0, "a cloud to fly into")
	if found < 0:
		return
	var rolled := SectorRegistryScript.clouds(&"sector_1")
	var zoom := float(scene.get(&"_minimap_radius"))
	var lock := float((scene.get(&"_stats") as Object).get(&"lock_range"))
	ship.global_position = rolled[0][&"centre"]
	scene.call(&"_update_clouds")
	assert_eq(float(scene.call(&"_cloud_factor_now")), 0.5, "inside a cloud: x0.5")
	assert_eq(float(scene.call(&"_lock_range")), lock * 0.5, "the lock range halves")
	assert_eq(float(scene.call(&"_scan_range")), 150.0, "the derelict's 300 u channel halves")
	assert_eq(
		float(scene.call(&"_minimap_radius_shown")), zoom * 0.5, "the minimap radius halves"
	)
	assert_eq(
		float((scene.get(&"_hud") as Object).get(&"_minimap_radius")),
		zoom * 0.5,
		"and the push carries the factor, not the zoom state"
	)
	assert_eq(float(scene.get(&"_minimap_radius")), zoom, "the player's own zoom state is untouched")
	assert_eq(
		ship.modulate,
		Color.WHITE.lerp(SectorRegistryScript.CLOUD_WASH, 0.15),
		"the hull carries the 15 % wash tint"
	)
	## The wheel still writes the player's own state; only the push is scaled.
	scene.call(&"_on_minimap_zoom_changed", 1)
	assert_eq(
		float(scene.get(&"_minimap_radius")), zoom + GameScript.MINIMAP_RADIUS_STEP, "the wheel moved"
	)
	assert_eq(
		float((scene.get(&"_hud") as Object).get(&"_minimap_radius")),
		(zoom + GameScript.MINIMAP_RADIUS_STEP) * 0.5,
		"and the HUD reads it through the factor"
	)
	scene.call(&"_on_minimap_zoom_changed", -1)
	assert_eq(float(scene.get(&"_minimap_radius")), zoom, "the wheel is back at the fixture's zoom")


## R-S24-3 outside a cloud: all three readings are the shipped values exactly, the tint is
## gone and the radius is the player's own again.
func test_outside_a_cloud_the_three_readings_are_the_shipped_ones() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	if sector == null or ship == null:
		return
	var found := _populate_until_clouds(sector)
	assert_gt(found, 0, "a rolled set to fly out of")
	if found < 0:
		return
	var rolled := SectorRegistryScript.clouds(&"sector_1")
	var outside := _outside_point(rolled)
	assert_ne(outside, Vector2.ZERO, "a point no cloud covers")
	var zoom := float(scene.get(&"_minimap_radius"))
	var lock := float((scene.get(&"_stats") as Object).get(&"lock_range"))
	ship.global_position = outside
	scene.call(&"_update_clouds")
	assert_eq(float(scene.call(&"_cloud_factor_now")), 1.0, "outside every cloud: x1.0")
	assert_eq(float(scene.call(&"_lock_range")), lock, "the lock range is the fit's own")
	assert_eq(
		float(scene.call(&"_scan_range")),
		SectorRegistryScript.DERELICT_SCAN_RANGE,
		"the POI scan range is 11 section 5's 300 u exactly"
	)
	assert_eq(float(scene.call(&"_minimap_radius_shown")), zoom, "the minimap radius is the zoom's own")
	assert_eq(
		float((scene.get(&"_hud") as Object).get(&"_minimap_radius")),
		zoom,
		"and the HUD shows the exact radius"
	)
	assert_eq(ship.modulate, Color.WHITE, "no tint outside")
	## And the same readings on the way back out of a cloud: in, then out, then equal.
	ship.global_position = rolled[0][&"centre"]
	scene.call(&"_update_clouds")
	assert_eq(float(scene.call(&"_scan_range")), 150.0, "inside: halved")
	ship.global_position = outside
	scene.call(&"_update_clouds")
	assert_eq(
		float((scene.get(&"_hud") as Object).get(&"_minimap_radius")),
		zoom,
		"leaving the cloud restores the exact radius"
	)


func _band_text(band: Array) -> String:
	var parts: Array[String] = []
	for member: Variant in band:
		parts.append(String(member))
	return ",".join(parts)


func _hull_row(profile: Node, ship_id: StringName) -> Dictionary:
	for row: Dictionary in AuctionScript.hull_rows(profile):
		if StringName(row[&"id"]) == ship_id:
			return row
	return {}


func _listing_row(profile: Node, id: StringName) -> Dictionary:
	for row: Dictionary in AuctionScript.listing_rows(profile):
		if StringName(row[&"id"]) == id:
			return row
	return {}


## One listed module whose family the Concord does not own, so its price carries the band
## alone (V2's tech step needs an owner family to move).
func _band_only_listing(profile: Node) -> Dictionary:
	for row: Dictionary in AuctionScript.listing_rows(profile):
		var family := StationRegistryScript.family_of(row[&"base_id"])
		if StationRegistryScript.tech_families(&"concord").has(family):
			continue
		if ModuleData.EXCLUSIVES.has(row[&"base_id"]):
			continue
		return row
	return {}


## One listed module whose family the station's owner counts as its own (V2's tech step
## needs one), searched over a run of shelves: a twenty-slot shelf need not carry one.
func _owner_family_listing(profile: Node, faction: StringName) -> Dictionary:
	seed(SEED)
	var families := StationRegistryScript.tech_families(faction)
	var rng := _stream()
	for _draw: int in BIAS_DRAWS:
		_next_shelf(profile, rng)
		for row: Dictionary in AuctionScript.listing_rows(profile):
			if families.has(StationRegistryScript.family_of(row[&"base_id"])):
				return row
	return {}
