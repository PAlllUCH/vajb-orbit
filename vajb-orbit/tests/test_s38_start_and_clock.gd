@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s38_start_and_clock: wave S38 - the hub's cold start and the board's clock.
## 14_station_services.md's 2026-10-08 S38 block (H1 the cold-start place, H2 the countdown,
## H3 the re-roll) and docs/design/STATION_HUB.md section 15.2's U22 row.
##
## One row per acceptance criterion (A1-A6). Every figure is computed from the shipped tables
## (`WorldClock`, `ContractRegistry`, `StationRegistry`) and the law's own numbers appear only
## as the expected side of a comparison. No await: the headless runner calls every test
## synchronously, so the real-time tick proof lives in `probe_s38_start_board.gd`.

const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const ContractRegistryScript := preload("res://game/contract_registry.gd")
const ContractsPanelScript := preload("res://ui/station/contracts_panel.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const GameScene := preload("res://game/game.tscn")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s38_start_and_clock.cfg"
const HOST := Vector2(1920.0, 1080.0)
## A stamp whose band remainder is 400 s, so the countdown reads 800 = 13:20 and the boundary
## is exactly `NOW + 800`.
const NOW := 4000000

var _profile: ProfileScript = null
var _station: Control = null
var _scenes: Array[Node] = []
var _previous: Dictionary = {}


func suite_name() -> String:
	return "s38_start_and_clock"


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
	}
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)
	_wipe()


func suite_teardown() -> void:
	_free_station()
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	Clock.clear_override()
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
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	Support.delete_file(PROFILE_PATH)
	_previous = {}
	_profile = null


func setup() -> void:
	_free_station()
	Clock.clear_override()
	_wipe()


## A clean account: no contracts, no standing, no cargo, no filed place, a full purse.
func _wipe() -> void:
	if _profile == null:
		return
	_profile.call(&"set_contracts", [])
	_profile.call(&"set_standing", {})
	_profile.call(&"set_docked_station", &"")
	_profile.set(&"_cargo", {})
	_profile.set(&"_credits", 50000)


func _free_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null

func _mount() -> Control:
	var host := Control.new()
	host.name = "S38Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


func _open_game() -> Node2D:
	var scene := GameScene.instantiate() as Node2D
	if scene == null:
		return null
	_profile.add_child(scene)
	_scenes.append(scene)
	return scene


func _panel() -> Control:
	if _station == null:
		return null
	return _station.call(&"service_panel", &"contracts") as Control


func _ids(rows: Array) -> Array:
	var out: Array = []
	for row: Dictionary in rows:
		out.append(String(row.get(&"id", &"")))
	return out


func _row_of_type(rows: Array, type: StringName) -> Dictionary:
	for row: Dictionary in rows:
		if StringName(row.get(&"type", &"")) == type:
			return row
	return {}


func _descends(child: Node, ancestor: Node) -> bool:
	var node := child
	while node != null:
		if node == ancestor:
			return true
		node = node.get_parent()
	return false


## ------------------------------------------------------------ A1: the hub's cold start


## H1: an empty filed id means "no run has filed a place", so the hub entered from the main
## menu offers the starting sector's primary - a full six-row board instead of U8's empty one.
func test_a1_the_cold_start_offers_the_full_board() -> void:
	_profile.call(&"set_docked_station", &"")
	assert_eq(String(_profile.call(&"docked_station")), "", "the profile has filed no place")
	assert_eq(
		String(StationRegistryScript.starting_station()[&"id"]), "s1_primary",
		"starting_station() is primary_for(SectorRegistry.DEFAULT_SECTOR_ID)"
	)
	assert_eq(
		String(SectorRegistryScript.DEFAULT_SECTOR_ID), "sector_1",
		"and the one sector constant is the game scene's old default"
	)
	assert_eq(
		String(StationRegistryScript.docked_station(_profile)[&"id"]), "s1_primary",
		"an empty filed id resolves the starting place"
	)
	assert_eq(
		String(StationRegistryScript.docked_station_id(_profile)), "s1_primary",
		"and the id seam answers it too"
	)
	var screen := _mount()
	var panel := _panel()
	assert_true(panel != null, "the CONTRACTS panel is mounted")
	var rows: Array = panel.call(&"board_rows")
	assert_eq(rows.size(), ContractRegistryScript.BOARD_SIZE, "the cold start offers six rows")
	assert_eq(String(panel.call(&"empty_state_text")), "", "and shows no U8 empty state")
	assert_eq(
		String((panel.get(&"_station_row") as Dictionary).get(&"id", &"")), "s1_primary",
		"the panel's own station row is the starting place"
	)
	assert_true(screen != null, "mounted once")


## H1's plate half: the header reads the starting row's own name and character line, never the
## scene's mockup-era placeholder copy.
func test_a1_the_plate_reads_the_row_not_the_placeholder() -> void:
	_profile.call(&"set_docked_station", &"")
	var screen := _mount()
	var name_label := screen.get_node(NodePath("%StationName")) as Label
	var location := screen.get_node(NodePath("%StationLocation")) as Label
	assert_eq(name_label.text, "Halcyon Anchorage", "the W3 name of S1's primary")
	assert_eq(location.text, "forge-grey bastion, the full menu", "and its character line")
	assert_false(name_label.text.contains("ORBITAL DRYDOCK"), "no placeholder name")
	assert_false(location.text.contains("HELIOS DRIFT"), "no dead sector name")


## --------------------------------------------------------------- A2: the countdown


## U22/H2: the strip's right end reads `NEW JOBS IN mm:ss` at
## `WorldClock.BAND_SECONDS - now % WorldClock.BAND_SECONDS`, on a 1 Hz tick that is running.
func test_a2_the_countdown_reads_the_clock() -> void:
	Clock.set_override(NOW)
	assert_eq(NOW % Clock.BAND_SECONDS, 400, "the fixture's remainder")
	_mount()
	var panel := _panel()
	assert_true(panel != null, "the CONTRACTS panel is mounted")
	assert_eq(
		int(panel.call(&"roll_remaining")),
		Clock.BAND_SECONDS - NOW % Clock.BAND_SECONDS,
		"H2's own arithmetic"
	)
	assert_eq(int(panel.call(&"roll_remaining")), 800, "the fixture reads 800 s")
	assert_eq(String(panel.call(&"roll_readout")), "NEW JOBS IN 13:20", "U22's wording, mm:ss")
	assert_eq(ContractsPanelScript.ROLL_FORMAT, "NEW JOBS IN %s", "the pinned format")
	assert_eq(ContractsPanelScript.TICK_SECONDS, 1.0, "the pinned tick")
	var timer := panel.get(&"_tick_timer") as Timer
	assert_true(timer != null, "the panel owns a tick timer")
	assert_eq(timer.wait_time, ContractsPanelScript.TICK_SECONDS, "at TICK_SECONDS")
	assert_false(timer.one_shot, "repeating, not one-shot")
	assert_false(timer.is_stopped(), "and running")
	## The readout is derived at each tick, never written once at build: one second of clock
	## moves it (the real-time proof is the probe's).
	var before := String(panel.call(&"roll_readout"))
	Clock.set_override(NOW + 1)
	panel.call(&"_tick")
	assert_ne(String(panel.call(&"roll_readout")), before, "a tick moves the readout")
	assert_eq(String(panel.call(&"roll_readout")), "NEW JOBS IN 13:19", "to the next second")


## H2's ceiling: the figure is two-digit minutes, so the maximum reads 20:00 and never 00:00.
func test_a2_the_countdown_ceiling_is_twenty_minutes() -> void:
	Clock.set_override(NOW + 800)
	_mount()
	var panel := _panel()
	assert_eq(int(panel.call(&"roll_remaining")), Clock.BAND_SECONDS, "the boundary reads a full band")
	assert_eq(String(panel.call(&"roll_readout")), "NEW JOBS IN 20:00", "two-digit minutes")


## ------------------------------------------------------------------- A3: the re-roll


## H3: at the boundary the panel re-rolls its own board - the next band's rows, the readout
## restarted - with no scene change and no player action.
func test_a3_the_boundary_rerolls_the_board_in_place() -> void:
	Clock.set_override(NOW)
	var screen := _mount()
	var panel := _panel()
	assert_eq(int(panel.call(&"board_band")), ContractRegistryScript.band_index(), "band filed")
	var before := _ids(panel.call(&"board_rows"))
	assert_eq(before.size(), ContractRegistryScript.BOARD_SIZE, "a full board to start")
	## Drive the clock to the exact boundary, then one tick: no waiting, no player action.
	Clock.set_override(NOW + 800)
	panel.call(&"_tick")
	var after := _ids(panel.call(&"board_rows"))
	assert_eq(
		int(panel.call(&"board_band")), ContractRegistryScript.band_index(),
		"the panel's band moved with the clock"
	)
	assert_eq(
		after,
		_ids(ContractRegistryScript.board(StationRegistryScript.starting_station(), 0)),
		"the rows are the next band's own board"
	)
	assert_ne(after, before, "and they differ from the band that was drawn")
	assert_eq(String(panel.call(&"roll_readout")), "NEW JOBS IN 20:00", "the readout restarts")
	assert_true(is_instance_valid(panel), "the panel survived the re-roll")
	assert_eq(_panel(), panel, "the shell is still drawing the same panel (no scene change)")
	assert_eq(screen, _station, "and the same station scene")


## ------------------------------------------------------- A4: S7 and the unchanged paths


## H1's boundary: a sector with no primary still resolves to no place (S7), and a null profile
## and an unparseable id are exactly what they were.
func test_a4_s7_and_the_two_unchanged_paths() -> void:
	assert_true(
		StationRegistryScript.primary_for(&"sector_7").is_empty(), "S7 has no primary row"
	)
	_profile.call(&"set_docked_station", &"sector_7")
	assert_eq(
		String(StationRegistryScript.docked_station_id(_profile)), "sector_7",
		"the sentinel is the sector's own id, not empty"
	)
	assert_true(
		StationRegistryScript.docked_station(_profile).is_empty(), "so S7 resolves to no place"
	)
	_profile.call(&"set_docked_station", &"")
	assert_true(
		StationRegistryScript.docked_station(null).is_empty(), "a null profile is unchanged"
	)
	_profile.call(&"set_docked_station", &"nonsense")
	assert_true(
		StationRegistryScript.docked_station(_profile).is_empty(), "an unparseable id is unchanged"
	)


## H1's other half: `game.gd:_file_docked_station` files the sector's **own** id when the
## sector has no primary row, so an empty id can only mean "no run has filed a place".
func test_a4_the_dock_files_the_sectors_own_id_with_no_primary() -> void:
	var scene := _open_game()
	if scene == null:
		return
	_profile.call(&"set_docked_station", &"s1_primary")
	scene.set(&"_sector_row_id", &"sector_7")
	scene.call(&"_file_docked_station")
	assert_eq(
		String(_profile.call(&"docked_station")), "sector_7",
		"a station-less sector files its own sector id"
	)
	assert_true(
		StationRegistryScript.docked_station(_profile).is_empty(),
		"and every reader still falls back"
	)
	scene.set(&"_sector_row_id", &"sector_2")
	scene.call(&"_file_docked_station")
	assert_eq(
		String(_profile.call(&"docked_station")), "s2_primary",
		"a sector with a primary row files that row"
	)


## ---------------------------------------------------------------- A5: the two riders


## T-156 / U7: the staged Expedition row dims **whole** - the one modulate on its inner box
## reaches the type icon and every cell under it, not the type label alone.
func test_a5_the_staged_row_dims_whole() -> void:
	_profile.call(&"set_docked_station", &"s1_primary")
	_mount()
	var panel := _panel()
	var dimmed: Array = panel.call(&"dimmed_rows")
	assert_eq(dimmed.size(), 1, "one staged Expedition row, one dimmed box")
	var inner := dimmed[0] as Control
	var dim: Color = panel.call(&"_token", &"text_dim")
	assert_ne(dim, Color.WHITE, "the text_dim token resolves from the theme")
	assert_eq(inner.modulate, dim, "the whole inner box at text_dim")
	var label := inner.find_child("TypeLabel", true, false) as Label
	var icon := inner.find_child("Icon", true, false) as TextureRect
	assert_true(label != null, "the type label sits under the dimmed box")
	assert_true(icon != null, "and so does the type icon")
	assert_true(_descends(icon, inner), "so the dim reaches the icon (U7's own scope)")
	## Negative control: the live rows carry no dim at all.
	var live := _row_of_type(panel.call(&"board_rows"), ContractRegistryScript.TYPE_HAUL)
	assert_false(live.is_empty(), "a live Haul row rolled")
	for node: Node in panel.get_node("%BoardList").get_children():
		if (node as Button) != null and not (node as Button).disabled:
			var box := node.get_node("RowInner") as Control
			assert_eq(box.modulate, Color.WHITE, "a live row is undimmed")
			assert_false(dimmed.has(box), "and is not in the dimmed set")


## T-157: an accepted row leaves the board, so the same id cannot be accepted twice in a band.
func test_a5_an_accepted_row_leaves_the_board() -> void:
	_profile.call(&"set_docked_station", &"s1_primary")
	_mount()
	var panel := _panel()
	var before: Array = panel.call(&"board_rows")
	var hunt := _row_of_type(before, ContractRegistryScript.TYPE_HUNT)
	assert_false(hunt.is_empty(), "a Hunt row rolled (it reserves no goods)")
	var id := StringName(hunt.get(&"id", &""))
	assert_true(bool(panel.call(&"accept", id)[&"ok"]), "the row accepts")
	var after: Array = panel.call(&"board_rows")
	assert_eq(after.size(), before.size() - 1, "and it leaves the board")
	assert_false(_ids(after).has(String(id)), "its own id is gone from the drawn rows")
	assert_eq(
		String(ContractRegistryScript.find(_profile, id).get(&"id", &"")), String(id),
		"while the record is active"
	)
	assert_false(bool(panel.call(&"accept", id)[&"ok"]), "so a second accept cannot happen")
	assert_eq(
		ContractRegistryScript.active_count(_profile), 1, "one accept, one record"
	)


## ------------------------------------------------------------ A6: the wave's numbers


## A6: this wave adds exactly two presentation values and one sector constant - S25's pinned
## numbers (CONTRACTS section 26) are byte-identical.
func test_a6_the_waves_numbers_are_the_only_ones_that_moved() -> void:
	assert_eq(ContractsPanelScript.TICK_SECONDS, 1.0, "TICK_SECONDS is new")
	assert_eq(ContractsPanelScript.ROLL_FORMAT, "NEW JOBS IN %s", "ROLL_FORMAT is new")
	assert_eq(String(SectorRegistryScript.DEFAULT_SECTOR_ID), "sector_1", "the sector constant")
	assert_eq(Clock.BAND_SECONDS, 1200, "the clock's band is unmoved")
	assert_eq(ContractRegistryScript.BOARD_SIZE, 6, "S25's board size")
	assert_eq(ContractRegistryScript.MAX_ACTIVE, 3, "S25's max active")
	assert_eq(ContractRegistryScript.CANCEL_FEE, 100, "S25's cancel fee")
	assert_eq(ContractRegistryScript.ROUND_UNIT, 100, "S25's round unit")
	assert_eq(ContractRegistryScript.HUNT_FLAT, 800, "S25's Hunt flat")
	assert_eq(ContractRegistryScript.ESCORT_FLAT, 1200, "S25's Escort flat")
	assert_eq(ContractRegistryScript.HAUL_FLAT, 300, "S25's Haul flat")
	assert_eq(ContractRegistryScript.KNOWN_FLOOR, 11, "12 section 4.1's Known floor")
	assert_eq(ContractRegistryScript.KNOWN_HOOK, 0.05, "and its +5 % hook")
	assert_eq(ContractRegistryScript.SC.size(), 4, "01's four sector tiers")
	assert_eq(ContractRegistryScript.SC[0], 1100, "tier 1")
	assert_eq(ContractRegistryScript.SC[3], 6000, "tier 4")
	assert_eq(StationRegistryScript.CONTRACTS_FLOOR, -11, "V3's gate floor")
