@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s24_world: wave S24's world identity, builder 1's half - 14_station_services.md's
## 2026-10-08 block (the nine places, the service matrix, the docked-station seam, the plate
## landing) and 12_factions.md's 2026-10-08 V1/V2/V6 block (the price law).
##
## One row per pinned acceptance. The station is mounted the way `test_s30_shell.gd` mounts
## it (the shipped scene, the shipped theme, the profile borrowed and handed back); the
## flight scene the way `test_s6_heat.gd` mounts it (for the dock filing).

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const OverviewScript := preload("res://ui/station/overview_panel.gd")
const RegistryScript := preload("res://game/station_registry.gd")
const CatalogScript := preload("res://game/station_catalog.gd")
const RepairsScript := preload("res://game/repairs.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s24_world.cfg"
const GAME_SCENE := "res://game/game.tscn"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"
const NOW := 1000000

## 14's 2026-09-27 table (tick W3), verbatim: id -> name, character, sector, kind, faction.
const PLACES: Array[Dictionary] = [
	{&"id": &"s1_primary", &"name": "Halcyon Anchorage", &"character": "forge-grey bastion, the full menu", &"sector": 1, &"kind": &"primary", &"faction": &"concord"},
	{&"id": &"s2_primary", &"name": "Ironworks Depot", &"character": "mill-town market floor", &"sector": 2, &"kind": &"primary", &"faction": &"concord"},
	{&"id": &"s2_outpost", &"name": "Marchgate Post", &"character": "a dock and a vending wall", &"sector": 2, &"kind": &"outpost", &"faction": &"concord"},
	{&"id": &"s3_primary", &"name": "Spanport Meridian", &"character": "the merchant's harbour, best contract rates", &"sector": 3, &"kind": &"primary", &"faction": &"meridian"},
	{&"id": &"s4_primary", &"name": "Ashveil Exchange", &"character": "free-port chaos, component prices", &"sector": 4, &"kind": &"primary", &"faction": &"meridian"},
	{&"id": &"s4_outpost", &"name": "Rimward Depot", &"character": "caravan stop", &"sector": 4, &"kind": &"outpost", &"faction": &"meridian"},
	{&"id": &"s5_primary", &"name": "Cinder Gate", &"character": "incense and plasma scorch", &"sector": 5, &"kind": &"primary", &"faction": &"choir"},
	{&"id": &"s5_shrine", &"name": "The First Ember", &"character": "the Choir's smallest rite", &"sector": 5, &"kind": &"outpost", &"faction": &"choir"},
	{&"id": &"s6_primary", &"name": "Emberlight", &"character": "cathedral dark, meanest turrets", &"sector": 6, &"kind": &"primary", &"faction": &"choir"},
]

## 12 section 4.1's four bands, at a value inside each (Shunned <= -11, Trusted >= 41,
## Champion >= 71).
const SHUNNED := -20
const NEUTRAL := 0
const TRUSTED := 50
const CHAMPION := 80

var _profile: ProfileScript = null
var _station: Control = null
var _scenes: Array[Node] = []
var _profiles: Array[Node] = []
var _previous: Dictionary = {}


func suite_name() -> String:
	return "s24_world"


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
		&"market": (_profile.call(&"market") as Dictionary).duplicate(true),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"heat": (_profile.call(&"heat") as Dictionary).duplicate(true),
		&"vaults": (_profile.call(&"vaults") as Dictionary).duplicate(true),
		&"docked_faction": StringName(_profile.call(&"docked_faction")),
		&"docked_station": StringName(_profile.call(&"docked_station")),
		&"active_ship": StringName(_profile.call(&"active_ship")),
		&"owned": (_profile.get(&"_owned_ships") as Array).duplicate(true),
		&"fits": (_profile.get(&"_fits") as Dictionary).duplicate(true),
		&"modules": (_profile.get(&"_modules") as Dictionary).duplicate(true),
		&"vitals": (_profile.get(&"_vitals") as Dictionary).duplicate(true),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)
	_profile.call(&"set_standing", {})
	_profile.call(&"set_heat", {})
	_profile.call(&"set_vaults", {})
	_profile.call(&"set_docked_faction", &"")
	_profile.call(&"set_docked_station", &"")


func suite_teardown() -> void:
	_free_station()
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
			&"vaults":
				_profile.call(&"set_vaults", value)
			&"docked_faction":
				_profile.call(&"set_docked_faction", value)
			&"docked_station":
				_profile.call(&"set_docked_station", value)
			&"active_ship":
				_profile.set(&"_active_ship", value)
			&"owned":
				_profile.set(&"_owned_ships", value)
			&"fits":
				_profile.set(&"_fits", value)
			&"modules":
				_profile.set(&"_modules", value)
			&"vitals":
				_profile.set(&"_vitals", value)
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	Support.delete_file(PROFILE_PATH)
	_previous = {}
	_profile = null


func setup() -> void:
	_free_station()


func _free_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null

func _mount() -> Control:
	var host := Control.new()
	host.name = "S24Host"
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


func _overview(screen: Control) -> Control:
	return screen.call(&"overview_pane") as Control


## A station dock also files the place's own owner as the faction (`game.gd` files both),
## so every fixture here starts from what a real dock leaves behind.
func _dock(station_id: StringName, standing: Dictionary = {}) -> void:
	_profile.call(&"set_docked_station", station_id)
	_profile.call(&"set_standing", standing)
	var row := RegistryScript.station(station_id)
	_profile.call(
		&"set_docked_faction", StringName(row.get(&"faction", &"")) if not row.is_empty() else &""
	)


func _fresh() -> ProfileScript:
	var profile := ProfileScript.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


## The digits of `text`, separators and words dropped: the shell groups its numbers with the
## project's thousands space, so `5 510 NEEDED` and `5510` compare equal.
func _digits_only(text: String) -> String:
	var digits := ""
	for index in text.length():
		var glyph := text[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
	return digits


## The figure one refusal copy names, digits only.
func _refusal_cost(shell: Node, id: StringName) -> String:
	return _digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", id)))


## ---------------------------------------------------------------------------
## A1 - the nine places (14's 2026-10-08 block, R-S24-1)
## ---------------------------------------------------------------------------


## The nine rows exist with 14's own id / name / character / sector / kind / faction, and no
## tenth row exists: S7 has no station (11 section 1).
func test_the_registry_carries_the_nine_places() -> void:
	assert_eq(RegistryScript.stations().size(), 9, "nine docking places")
	assert_eq(RegistryScript.STATIONS.size(), 9, "and the table itself carries all nine")
	for place: Dictionary in PLACES:
		var row := RegistryScript.station(StringName(place[&"id"]))
		assert_false(row.is_empty(), "%s exists" % place[&"id"])
		if row.is_empty():
			continue
		assert_eq(String(row[&"name"]), String(place[&"name"]), "%s's name (W3)" % place[&"id"])
		assert_eq(
			String(row[&"character"]), String(place[&"character"]),
			"%s's character line (W3)" % place[&"id"]
		)
		assert_eq(int(row[&"sector"]), int(place[&"sector"]), "%s's sector" % place[&"id"])
		assert_eq(String(row[&"kind"]), String(place[&"kind"]), "%s's kind" % place[&"id"])
		assert_eq(String(row[&"faction"]), String(place[&"faction"]), "%s's faction" % place[&"id"])
	assert_true(RegistryScript.station(&"s7_primary").is_empty(), "S7 carries no station row")
	assert_true(RegistryScript.primary_for(&"sector_7").is_empty(), "and no primary to resolve")


## 14 section 1's table as the matrix: every row contracts / refuel / recharge / vaults /
## bounty; Concord primaries no arena; Choir primaries no insurance; Meridian primaries the
## full menu; the three outposts section 8's three plus the free pair, capped at vault tier 1.
func test_the_service_matrix_is_section_1_and_8s() -> void:
	for place: Dictionary in PLACES:
		var row := RegistryScript.station(StringName(place[&"id"]))
		var label := String(place[&"id"])
		for service: StringName in [
			&"contracts", &"refuel", &"recharge", &"vaults", &"bounty"
		]:
			assert_true(RegistryScript.offers(row, service), "%s offers %s" % [label, service])
		var outpost := String(place[&"kind"]) == &"outpost"
		var faction := String(place[&"faction"])
		assert_eq(
			RegistryScript.offers(row, &"insurance"), not outpost and faction != "choir",
			"%s: insurance (section 1's Choir line, section 8's outposts)" % label
		)
		assert_eq(
			RegistryScript.offers(row, &"arena"), not outpost and faction != "concord",
			"%s: arena (section 1's Concord line, section 8's outposts)" % label
		)
		assert_eq(int(row[&"vault_tiers"]), 1 if outpost else 3, "%s: vault tiers" % label)


## The U2 reasons: the Choir's own line at a Choir station, the outpost's at any outpost,
## nothing where 14 states none.
func test_the_unavailable_reasons_are_the_two_u2_captions() -> void:
	assert_eq(
		RegistryScript.service_reason(RegistryScript.station(&"s5_primary"), &"insurance"),
		"the Choir does not believe in accidents",
		"section 1's own line"
	)
	assert_eq(
		RegistryScript.service_reason(RegistryScript.station(&"s2_outpost"), &"insurance"),
		"fly to a capital",
		"section 8's line at an outpost"
	)
	assert_eq(
		RegistryScript.service_reason(RegistryScript.station(&"s3_primary"), &"insurance"),
		"", "a service the row carries has no reason"
	)


## The seam: the profile's own row when it names one, the sector's primary row for an id
## this wave does not ship, the starting sector's primary for an **empty** filed id (S38's
## H1 cold start: an empty id means "no run has filed a place" and nothing else), and an
## empty dictionary for no profile / an unparseable id - never a crash (the brief's rule 6).
func test_a_place_resolves_from_the_profile_seam() -> void:
	var profile := _fresh()
	assert_eq(
		String(RegistryScript.docked_station(profile)[&"id"]), "s1_primary",
		"nothing filed is the cold start, the starting sector's primary (S38 H1)"
	)
	assert_eq(
		RegistryScript.docked_station_id(profile), &"s1_primary", "and both seams answer it"
	)
	assert_true(RegistryScript.docked_station(null).is_empty(), "a null profile is a normal path")
	profile.set_docked_station(&"s2_outpost")
	assert_eq(
		String(RegistryScript.station(RegistryScript.docked_station_id(profile))[&"name"]),
		"Marchgate Post", "the filed outpost resolves"
	)
	assert_eq(
		String(RegistryScript.docked_station(profile)[&"id"]), "s2_outpost", "by its own row"
	)
	profile.set_docked_station(&"s2_secondary")
	assert_eq(
		String(RegistryScript.docked_station(profile)[&"id"]), "s2_primary",
		"an id this wave does not ship falls back to its sector's primary"
	)
	profile.set_docked_station(&"nonsense")
	assert_true(
		RegistryScript.docked_station(profile).is_empty(), "an unparseable id is a normal path"
	)


## The dock filing: `game.gd:_request_dock` names the place beside the faction, so the row
## the dock landed at is what the shell and every price read resolve.
func test_the_dock_files_the_station_beside_the_faction() -> void:
	var scene := _open_game()
	if scene == null or _profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	if sector == null or ship == null:
		return
	var routes: Array = []
	scene.route_requested.connect(
		func(_route: StringName, _params: Dictionary) -> void: routes.append(1)
	)
	ship.global_position = sector.call(&"station_position")
	scene.call(&"_request_dock")
	assert_eq(routes.size(), 1, "the dock routes once")
	var row := RegistryScript.primary_for(
		StringName((sector.get(&"_row") as Dictionary).get(&"id", &""))
	)
	assert_false(row.is_empty(), "the fixture sector has a primary row")
	assert_eq(
		String(_profile.call(&"docked_station")), String(row[&"id"]), "the place is filed"
	)
	assert_eq(
		String(_profile.call(&"docked_faction")), String(row[&"faction"]),
		"beside the faction filing"
	)


## The plate (STATION_HUB section 15.5 / 14's landing note): the two labels read the row's
## name and character line, the placeholder strings are gone, and the OVERVIEW identity block
## carries the same name. S41 (2026-10-11) retired the block's character line so all three
## service rows sit unscrolled at the pane's fold, so the pair now lives only in the shell.
func test_the_shell_plate_reads_the_row() -> void:
	_dock(&"s3_primary")
	var screen := _mount()
	var name_label := screen.get_node(NodePath("%StationName")) as Label
	var location := screen.get_node(NodePath("%StationLocation")) as Label
	assert_eq(name_label.text, "Spanport Meridian", "the row's name (W3)")
	assert_eq(
		location.text, "the merchant's harbour, best contract rates", "the row's character line"
	)
	assert_false(name_label.text.contains("ORBITAL DRYDOCK"), "no placeholder name anywhere")
	assert_false(location.text.contains("HELIOS DRIFT"), "no placeholder caption anywhere")
	var overview := _overview(screen)
	assert_eq(
		(overview.get(&"_identity_name") as Label).text, "Spanport Meridian",
		"OVERVIEW's identity block reads the same name"
	)
	## S41 (D23's F1): the identity block's character line is retired, and asserted as
	## **absence** - the earlier form read `.text` off a label that no longer exists, which
	## raised a `SCRIPT ERROR` and still reported PASS (the silent-abort false-green class).
	assert_eq(
		overview.get(&"_identity_character"), null,
		"the identity character line is retired (S41/F1)"
	)
	assert_eq(
		(overview.get(&"_identity_faction") as StringName), &"meridian",
		"and the faction the plate steps its ramp by"
	)


## S42 (P46): the availability law re-seated on the 3x3 grid's service tiles - an
## unavailable service keeps its label and goes `button_disabled`, the tile's caption
## line carries the section 1 / section 8 reason in `text_dim`, and an available one
## reads its own P46 caption.
func test_the_overview_marks_an_unavailable_service() -> void:
	_dock(&"s3_primary")
	var screen := _mount()
	var overview := _overview(screen)
	var seats := overview.get(&"_service_tiles") as Dictionary
	var insurance_btn := (seats[&"insurance"] as Dictionary)[&"button"] as Button
	var insurance_cap := (seats[&"insurance"] as Dictionary)[&"caption"] as Label
	assert_false(insurance_btn.disabled, "a Meridian primary insures")
	assert_eq(insurance_cap.text, "COVERS ONE LOSS", "and reads its own P46 caption")
	_dock(&"s5_primary")
	overview.call(&"_apply_service_availability")
	assert_true(insurance_btn.disabled, "the Choir's station does not insure")
	assert_eq(
		insurance_cap.text, "the Choir does not believe in accidents",
		"section 1's reason caption"
	)
	_dock(&"s2_outpost")
	overview.call(&"_apply_service_availability")
	assert_true(insurance_btn.disabled, "an outpost does not insure either")
	assert_eq(insurance_cap.text, "fly to a capital", "section 8's reason")
	assert_false(
		((seats[&"vaults"] as Dictionary)[&"button"] as Button).disabled,
		"an outpost still rents vault tier 1"
	)
	assert_false(
		((seats[&"contracts"] as Dictionary)[&"button"] as Button).disabled,
		"and still offers contracts"
	)


## UI_SPEC section 12.5's A5.5 test on the same tiles (S42/P46 re-seat): the availability
## state change mutates colour and the disabled flag only - no box (size,
## `custom_minimum_size`, position) moves.
func test_the_overview_state_change_moves_no_box() -> void:
	_dock(&"s3_primary")
	var screen := _mount()
	var overview := _overview(screen)
	var seats := overview.get(&"_service_tiles") as Dictionary
	var row := (seats[&"insurance"] as Dictionary)[&"button"] as Button
	var read := (seats[&"insurance"] as Dictionary)[&"caption"] as Label
	var before := [row.custom_minimum_size, row.position, row.size]
	var line_box := read.custom_minimum_size.y
	_dock(&"s5_primary")
	overview.call(&"_apply_service_availability")
	assert_true(row.disabled, "the state changed")
	assert_true(read.has_theme_color_override(&"font_color"), "the caption is dimmed")
	assert_eq(
		[row.custom_minimum_size, row.position, row.size], before,
		"the pinned tile box did not move (A5.5)"
	)
	assert_eq(
		read.custom_minimum_size.y, line_box,
		"the caption keeps its line box: N31's in-place content swap in a pinned box"
	)
	assert_eq(
		row.custom_minimum_size, Vector2(240.0, 120.0), "the tile stays at P44's (240, 120)"
	)


## S42 (P46): the U6/U10/U16 readouts retired with the P25 rows - the vault read lives
## only in the VAULTS panel now (14's 2026-10-08 block). Asserted as absence, the S41/F1
## precedent: the read seam's fields are gone, the record itself still resolves.
func test_the_vault_read_resolves_the_docked_station() -> void:
	_profile.call(&"set_vaults", {
		"s3_primary": {&"tier": 1, &"contents": {&"ingot_iron": 12}},
		"s5_primary": {&"tier": 1, &"contents": {&"ingot_iron": 7}},
	})
	_dock(&"s3_primary")
	var screen := _mount()
	var overview := _overview(screen)
	assert_eq(overview.get(&"_vault_units"), null, "the overview's vault read is retired (P46)")
	assert_eq(overview.get(&"_service_reads"), null, "and the readout cells with it")
	assert_eq(overview.get(&"_service_rows"), null, "the P25 rows are gone")
	var station_id: StringName = RegistryScript.docked_station_id(_profile)
	assert_eq(String(station_id), "s3_primary", "the docked station still resolves")


## The dead branch (the brief's rule 8): S30's `has_method(&"n")` fallback named a method that
## exists nowhere, so no behavioural probe can see it - the shipped source is the evidence.
func test_the_dead_faction_fallback_is_gone() -> void:
	for path: String in [
		"res://ui/screens/station.gd", "res://ui/station/overview_panel.gd"
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_true(file != null, "%s is readable" % path)
		if file == null:
			continue
		var source := file.get_as_text()
		file.close()
		assert_false(source.contains("has_method(&\"n\")"), "%s carries no dead fallback" % path)


## ---------------------------------------------------------------------------
## A2 - the price law (12's 2026-10-08 V1/V2/V6 block)
## ---------------------------------------------------------------------------


## The repair fee: the section 6 figure at a Neutral station, moved by the band alone
## (a repair is no module, so the tech step takes no part).
func test_the_band_multiplier_moves_the_repair_fee() -> void:
	var profile := _fresh()
	profile.set_vitals(SHIP, 200, 300)
	profile.set_docked_station(&"s2_primary")
	var neutral := RepairsScript.fee(profile, SHIP)
	assert_eq(neutral, 692, "(1050/2) + (500/3) at a Neutral station")
	for band: Array in [[SHUNNED, 761], [TRUSTED, 657], [CHAMPION, 623]]:
		profile.set_standing({"concord": int(band[0])})
		assert_eq(
			RepairsScript.fee(profile, SHIP), int(band[1]),
			"standing %d prices the same repair" % int(band[0])
		)
	profile.set_docked_station(&"sector_7")
	assert_eq(RepairsScript.fee(profile, SHIP), neutral, "no station is the section 6 number")


## The ammo pack cost: `StationCatalog.ammo_pack_price`, the reader the armory's pack cards
## quote through.
func test_the_band_multiplier_moves_the_ammo_pack_cost() -> void:
	var station := RegistryScript.station(&"s2_primary")
	assert_eq(
		CatalogScript.ammo_pack_price(&"laser", station, NEUTRAL), 120, "the list price"
	)
	assert_eq(CatalogScript.ammo_pack_price(&"laser", station, SHUNNED), 132, "+10 % Shunned")
	assert_eq(CatalogScript.ammo_pack_price(&"laser", station, TRUSTED), 114, "-5 % Trusted")
	assert_eq(CatalogScript.ammo_pack_price(&"laser", station, CHAMPION), 108, "-10 % Champion")
	assert_eq(CatalogScript.ammo_pack_price(&"bogus", station, SHUNNED), 0, "no pack, no price")


## The hull list price: `StationCatalog.ship_price`, over the catalogue's own `cost`.
func test_the_band_multiplier_moves_the_hull_list_price() -> void:
	var station := RegistryScript.station(&"s2_primary")
	assert_eq(
		CatalogScript.ship_price(&"ship_fighter", station, NEUTRAL), 9000, "the list price"
	)
	assert_eq(CatalogScript.ship_price(&"ship_fighter", station, SHUNNED), 9900, "+10 % Shunned")
	assert_eq(CatalogScript.ship_price(&"ship_fighter", station, TRUSTED), 8550, "-5 % Trusted")
	assert_eq(CatalogScript.ship_price(&"ship_fighter", station, CHAMPION), 8100, "-10 % Champion")
	assert_eq(CatalogScript.ship_price(&"bogus", station, SHUNNED), 0, "no hull, no price")


## V2's own worked example: a Champion of the Choir buying a proton missile launcher reads
## 0.75 x list (-15 % faction tech + -10 % band, added not multiplied). A26 (2026-10-16):
## the armory's own row read retired with its module rows — the registry's arithmetic is
## what the AUCTION's shelf pricing and the shell's refusal strip still read.
func test_the_module_price_stacks_the_tech_discount_additively() -> void:
	var choir := RegistryScript.station(&"s5_primary")
	assert_eq(ModuleData.module(&"w_proton")[&"cost"], 5200, "the launcher's list price")
	assert_eq(
		RegistryScript.apply_price(5200, choir, CHAMPION, &"w_proton"), 3900,
		"0.75 x list (12 section 5's own arithmetic)"
	)
	assert_eq(
		RegistryScript.apply_price(5200, choir, CHAMPION, &"w_railgun"), 4680,
		"a family the Choir does not own takes the band alone"
	)
	assert_eq(
		RegistryScript.apply_price(5200, RegistryScript.station(&"s3_primary"), CHAMPION, &"w_proton"),
		4680, "the Choir's family is not discounted in Meridian space"
	)


## F1 (S24-R1): the shell's refusal strip prices through the registry's one reader, so at a
## non-Neutral band its figure is the one the pane that triggered the refusal charged - the
## armory's pack card and the shell's module figure, the auction's hull row. With no place
## filed the catalogue's own number is still the copy (the shipped station-less path).
func test_the_refusal_strip_prices_through_the_registry() -> void:
	_dock(&"s2_primary", {"concord": SHUNNED})
	var screen := _mount()
	var station := RegistryScript.station(&"s2_primary")
	assert_eq(
		CatalogScript.ammo_pack_price(&"laser", station, SHUNNED), 132, "+10 % Shunned over 120"
	)
	assert_eq(
		_refusal_cost(screen, &"laser"), "132",
		"a pack's copy is the station price the armory charged"
	)
	assert_eq(
		_refusal_cost(screen, &"h_composite"),
		_digits_only(str(int(screen.call(&"_entry_cost", &"h_composite")))),
		"a module's copy is the shell's own station figure, the tech step included"
	)
	assert_eq(
		_refusal_cost(screen, &"ship_fighter"),
		_digits_only(str(CatalogScript.ship_price(&"ship_fighter", station, SHUNNED))),
		"and a hull's copy is the auction's station price"
	)
	_free_station()
	var bare := StationScript.new()
	assert_eq(
		_refusal_cost(bare, &"laser"),
		_digits_only(str(int(CatalogScript.ammo_pack(&"laser")[&"cost"]))),
		"no place filed, no band: the catalogue's own number stands"
	)
	bare.free()


## The Meridian commission (12 section 3 / 14 section 3): 1.5 % at a Meridian station, 2 %
## elsewhere, the 10 CR floor and the ammo exemption unchanged.
func test_the_meridian_commission_reads_1_5_percent() -> void:
	var meridian := RegistryScript.station(&"s3_primary")
	var concord := RegistryScript.station(&"s2_primary")
	assert_eq(ExchangeScript.commission_rate(meridian), 0.015, "1.5 % in Meridian space")
	assert_eq(ExchangeScript.commission_rate(concord), 0.02, "2 % elsewhere")
	assert_eq(ExchangeScript.commission_rate({}), 0.02, "and away from any station")
	assert_eq(ExchangeScript.commission_for(1800, meridian), 27, "1.5 % of 1 800")
	assert_eq(ExchangeScript.commission_for(1800, concord), 36, "2 % of 1 800")
	assert_eq(ExchangeScript.commission_for(60, meridian), 10, "the 10 CR floor still guards")
	assert_eq(
		ExchangeScript.commission_for_item(&"ammo_laser", 400, meridian), 6,
		"R-S21-1's floor-free ammo at the station's own rate"
	)
	assert_eq(ExchangeScript.commission_for_item(&"ammo_laser", 400, concord), 8, "and at 2 %")
	var profile := _fresh()
	profile.add_cargo(&"mineral_iron", 100)
	profile.set_docked_station(&"s3_primary")
	var quote: Dictionary = ExchangeScript.quote(profile, &"mineral_iron", 100, NOW)
	assert_eq(int(quote[&"gross"]), 1800, "100 iron ore at demand 1.0")
	assert_eq(int(quote[&"fee"]), 27, "the quote reads the Meridian rate")
	profile.set_docked_station(&"s2_primary")
	var concord_quote: Dictionary = ExchangeScript.quote(profile, &"mineral_iron", 100, NOW)
	assert_eq(int(concord_quote[&"fee"]), 36, "and 2 % at a Concord station")


## V1: the exchange is a market, not a shop - no band multiplies its quotes (the commission
## rate is its one station-aware number).
func test_the_exchange_quotes_take_no_band_multiplier() -> void:
	var profile := _fresh()
	profile.add_cargo(&"mineral_iron", 100)
	profile.set_docked_station(&"s3_primary")
	profile.set_standing({"meridian": NEUTRAL})
	var neutral: Dictionary = ExchangeScript.quote(profile, &"mineral_iron", 100, NOW)
	profile.set_standing({"meridian": SHUNNED})
	var shunned: Dictionary = ExchangeScript.quote(profile, &"mineral_iron", 100, NOW)
	assert_eq(
		int(shunned[&"gross"]), int(neutral[&"gross"]), "Shunned does not move an exchange quote"
	)
	assert_eq(int(shunned[&"unit"]), int(neutral[&"unit"]), "nor the unit price")
	assert_eq(int(shunned[&"fee"]), int(neutral[&"fee"]), "nor the commission")


## V6: the shelf bias - 2.0 for the owner's own tech families, 1.0 otherwise.
func test_shelf_bias_returns_two_for_the_owners_families() -> void:
	var concord := RegistryScript.station(&"s1_primary")
	var meridian := RegistryScript.station(&"s3_primary")
	var choir := RegistryScript.station(&"s5_primary")
	for base_id: StringName in [&"h_composite", &"e_vector"]:
		assert_eq(RegistryScript.shelf_bias(concord, base_id), 2.0, "Concord's %s" % base_id)
	for base_id: StringName in [&"c_nexus", &"b_fold", &"u_vault"]:
		assert_eq(RegistryScript.shelf_bias(meridian, base_id), 2.0, "Meridian's %s" % base_id)
	for base_id: StringName in [&"s_ion", &"w_plasma", &"w_proton"]:
		assert_eq(RegistryScript.shelf_bias(choir, base_id), 2.0, "the Choir's %s" % base_id)
	assert_eq(RegistryScript.shelf_bias(choir, &"w_railgun"), 1.0, "another family is uniform")
	assert_eq(RegistryScript.shelf_bias(choir, &"h_composite"), 1.0, "another owner's too")
	assert_eq(RegistryScript.shelf_bias(concord, &"w_flak"), 1.0, "V6's list is armour + engines")
	assert_eq(RegistryScript.shelf_bias({}, &"s_ion"), 1.0, "no place, no bias")


## The two seams S25/S26 read (the brief's rule 4): `contracts_visible` at each band and
## `insurance_multiplier` at Champion and elsewhere.
func test_contracts_visible_and_the_insurance_seam() -> void:
	assert_false(RegistryScript.contracts_visible(-100), "Outlaw sees no contracts")
	assert_false(RegistryScript.contracts_visible(-11), "nor does the Shunned floor")
	assert_true(RegistryScript.contracts_visible(-10), "Neutral does")
	assert_true(RegistryScript.contracts_visible(CHAMPION), "and Champion does")
	assert_eq(RegistryScript.insurance_multiplier(CHAMPION), 0.8, "V7: Champion insures at 0.8")
	assert_eq(RegistryScript.insurance_multiplier(TRUSTED), 1.0, "and everyone else at 1.0")
	assert_eq(RegistryScript.insurance_multiplier(-100), 1.0, "including the Outlaw band")
