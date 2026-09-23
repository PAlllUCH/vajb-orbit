@tool
extends McpTestSuite
## Suite p2a_launch_fit: W4's launch path (wave P2-A, CONTRACTS section 11).
##
## The launch resolves the **active hull's own fit** instead of the one global
## `ShipFit.STANDARD_FIT`, maps the profile's module *instance* ids to the base ids
## `ShipFit` reads, seeds ammo per fitted family, hands the HUD the hull's own W cells
## and gives the hull one thruster anchor per engine cell. Every case here is measured
## on the shipped `game.tscn` launched off the shipped `PlayerProfile` autoload, so
## what is asserted is the flight scene's own behaviour rather than a re-implementation
## of it.
##
## The profile is the launch's source, so each test writes it (the scene never does)
## and the suite borrows the live autoload the way `test_engine2_dock.gd` does: its
## `save_path` is repointed at a scratch file before the first mutation, the four
## fields a launch reads are snapshotted once and handed back in `suite_teardown`, and
## the store is flushed while the scratch path is still in place, so the owner's
## `user://profile.cfg` is never written (probe hygiene L17).

const GameScene := preload("res://game/game.tscn")
const FitData := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/module_catalog.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const WeaponsScript := preload("res://game/weapons.gd")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_p2a_launch_fit.cfg"
const HUD_NODE: StringName = &"Hud"
const SHIP_NODE: StringName = &"PlayerShip"

## 08 section 2's ladder, by the three shapes this suite needs: a light hull with a
## two-weapon standard fit, the cutter whose grid carries three W cells, and the Mule
## whose three engine cells are the summed-set case.
const LANCER: StringName = &"ship_fighter"
const VANGUARD: StringName = &"ship_vanguard"
const HAULER: StringName = &"ship_freighter"
const CAPITAL: StringName = &"ship_destroyer"
const NPC_HULL: StringName = &"ship_swarmer"

## 09 section 3.7's pre-amendment product for the same three drives, quoted so the
## "summed, not multiplied" assertion has a number to be different from.
const VECTOR_ION_PRODUCT := 1.15 * 1.25

var _profile: Node = null
var _scene: Node2D = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _signals: Array[int] = []


func suite_name() -> String:
	return "p2a_launch_fit"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the launch's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_delete_file(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_scene()
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore
	## the real one, so no dirty flag and no running timer carries a test's fit home.
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(SCRATCH_PROFILE)
	_profile = null


func teardown() -> void:
	_free_scene()
	_signals.clear()


## ---------------------------------------------------------------------------
## The launched fit: the hull's own, the profile's, and the fallback
## ---------------------------------------------------------------------------


## 08 section 3's Lancer carries two W cells and 09 section 9's Lancer row fills both
## with `w_laser`, so the launch must resolve two live weapon slots - the owner gate's
## "the ship mounts [w_laser]" symptom, measured as a count rather than a briefing.
func test_a_lancer_launches_its_two_weapon_fit() -> void:
	var scene := _launch(LANCER, {})
	var state: Variant = scene.get(&"_state")
	var expected: Array[StringName] = [&"laser", &"laser"]
	assert_eq(
		FitData.slot_capacity(LANCER, &"weapons"), 2, "the Fighter's grid carries two W cells"
	)
	assert_eq(scene.get(&"_launch_hull"), LANCER, "the launch flew the active hull")
	assert_eq(state.weapons, expected, "and its own two-laser standard fit")
	assert_eq(state.ammo.size(), 2, "two live weapon slots, not the five fixed families")
	assert_eq(state.ammo_max.size(), 2, "and two ceilings")
	assert_eq(_hud_cells(scene).size(), 2, "the HUD was handed the hull's own two W cells")


## The Cutter's grid carries three W cells; a stored three-weapon fit launches three
## slots, and the shipped one-weapon standard fit launches one. Both numbers are read
## from 08 section 3's matrix, so a count and a layout cannot disagree.
func test_a_vanguard_launches_a_three_weapon_fit() -> void:
	var fit := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["w_laser", "w_cannon", "w_rocket"],
	}
	var scene := _launch(VANGUARD, fit)
	var state: Variant = scene.get(&"_state")
	var expected: Array[StringName] = [&"laser", &"cannon", &"rocket"]
	assert_eq(
		FitData.slot_capacity(VANGUARD, &"weapons"), 3, "the Cutter's grid carries three W cells"
	)
	assert_eq(state.weapons, expected, "the stored fit's three weapon ids, in W-cell order")
	assert_eq(state.ammo.size(), 3, "three live slots")
	assert_eq(_hud_cells(scene).size(), 3, "and three cells pushed to the HUD")


## The other half of the same count: 09 section 9's Vanguard row fills **one** of the
## Cutter's three W cells, so a launch on the standard fit has one live slot and two
## empty cells - the fit decides, the grid only frames it.
func test_the_standard_fit_fills_only_the_cells_it_names() -> void:
	var scene := _launch(VANGUARD, {})
	var state: Variant = scene.get(&"_state")
	var expected: Array[StringName] = [&"laser"]
	assert_eq(scene.get(&"_launch_fit"), FitData.standard_fit(VANGUARD), "09 section 9's row")
	assert_eq(state.weapons, expected, "one fitted weapon")
	assert_eq(_hud_cells(scene).size(), 3, "three cells displayed")
	var cells: Array = _hud_cells(scene)
	assert_true(bool(cells[0][&"fitted"]), "cell 0 is the fitted one")
	assert_false(bool(cells[1][&"fitted"]), "cell 1 is empty")
	assert_false(bool(cells[2][&"fitted"]), "cell 2 is empty")


## 09 section 3.7 as amended: a hull's engines are a **set whose deltas are summed
## once and clamped to `ENGINE_MULT_CEILING`**, never multiplied. The Mule's three
## cells with `e_std` + `e_ion` + `e_vector` resolve to 1.40 through the launch - where
## the pre-amendment product would have been 1.4375 - and the turn multiplier rides to
## 1.20 because the ceiling is the speed multiplier's only.
func test_a_three_engine_hull_sums_its_engines_and_clamps_at_the_ceiling() -> void:
	var fit := {
		&"engines": ["e_std", "e_ion", "e_vector"],
		&"power": "p_std",
	}
	var scene := _launch(HAULER, fit)
	var stats: Variant = scene.get(&"_stats")
	var handling: Dictionary = FitData.HANDLING[HAULER]
	var base_speed := float(handling[&"max_speed"])
	var base_turn := float(handling[&"turn_rate"])
	assert_eq(FitData.slot_capacity(HAULER, &"engines"), 3, "the Mule carries three engine cells")
	assert_true(
		absf(stats.max_speed - base_speed * FitData.ENGINE_MULT_CEILING) < 0.01,
		"the summed set clamps to 1.40 (%f vs %f)"
		% [stats.max_speed, base_speed * FitData.ENGINE_MULT_CEILING]
	)
	assert_true(
		absf(stats.max_speed - base_speed * VECTOR_ION_PRODUCT) > 1.0,
		"and it is not the old product of the same three drives (%f vs %f)"
		% [stats.max_speed, base_speed * VECTOR_ION_PRODUCT]
	)
	assert_true(
		absf(stats.turn_rate - base_turn * 1.20) < 0.001,
		"the turn multiplier carries no ceiling (%f vs %f)" % [stats.turn_rate, base_turn * 1.20]
	)


## 09 section 9's fallback, both halves: a hull the account holds **no** fit for, and a
## hull it holds an all-empty row for. Both launch on `ShipFit.standard_fit(hull)` -
## the hull's own row, not one global fit - and the profile is never written by the
## flight scene, so a bare account stays bare.
func test_a_fit_that_holds_nothing_falls_back_to_the_standard_fit() -> void:
	var bare := _launch(LANCER, {})
	assert_eq(
		bare.get(&"_launch_fit"), FitData.standard_fit(LANCER), "the Lancer's own standard fit"
	)
	assert_eq(bare.get(&"_state").weapons.size(), 2, "which fills both of its W cells")
	assert_eq(_profile.call(&"fits"), {}, "and the flight scene wrote nothing back")

	var empty := {
		&"engines": [],
		&"power": "",
		&"weapons": [],
	}
	var stored := _launch(VANGUARD, empty)
	assert_eq(
		stored.get(&"_launch_fit"),
		FitData.standard_fit(VANGUARD),
		"a stored but empty row is the same case"
	)
	assert_eq(stored.get(&"_state").weapons.size(), 1, "one weapon, per 09 section 9's row")


## The launch **reads** the profile's fit: an inventory instance id is mapped to its
## base id for the resolver while the store keeps the instance id it was saved with,
## and the launch leaves the stored fit byte-identical.
func test_the_launch_reads_the_profiles_fit_through_the_base_ids() -> void:
	_profile.call(&"set_modules", {"mod_0007": {"base_id": "w_cannon", "count": 1}})
	var fit := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["mod_0007"],
	}
	var scene := _launch(VANGUARD, fit)
	var stored_before: Dictionary = _profile.call(&"fits")
	var expected: Array[StringName] = [&"w_cannon", &"", &""]
	assert_eq(
		scene.get(&"_launch_fit")[&"weapons"],
		expected,
		"the instance id resolved to the base id the resolver reads, at the hull's capacity"
	)
	assert_eq(
		_profile.call(&"fit_for", VANGUARD)[&"weapons"][0],
		"mod_0007",
		"while the store keeps the instance id"
	)
	assert_eq(_profile.call(&"fits"), stored_before, "and the launch wrote nothing")
	assert_eq(
		scene.get(&"_state").weapons,
		[&"cannon"] as Array[StringName],
		"the base id reaches the live slot as its family"
	)


## ---------------------------------------------------------------------------
## Ammo: per fitted family, one pack behind every slot of that family
## ---------------------------------------------------------------------------


## 09 section 3.1 / 18_engine_spec section 4.3: the packs are keyed by **family**, and
## the launch seeds each live slot from its family's own store. Two different families
## take two different packs; two cells of one family both draw from that one pack.
func test_the_ammo_packs_seed_per_fitted_family() -> void:
	_profile.call(&"set_ammo", &"laser", 111)
	_profile.call(&"set_ammo", &"cannon", 222)
	var fit := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["w_laser", "w_cannon"],
	}
	var scene := _launch(VANGUARD, fit)
	var state: Variant = scene.get(&"_state")
	var expected: Array[int] = [111, 222]
	assert_eq(state.weapons, [&"laser", &"cannon"] as Array[StringName], "laser then cannon")
	assert_eq(state.ammo, expected, "each slot seeded from its own family's pack")

	## The twin case: a Lancer fit carrying two lasers - one pack, both slots.
	var twin := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["w_laser", "w_laser"],
	}
	var twin_scene := _launch(LANCER, twin)
	var twin_state: Variant = twin_scene.get(&"_state")
	var twin_expected: Array[int] = [111, 111]
	assert_eq(twin_state.ammo, twin_expected, "two lasers draw both slots from the laser pack")


## The filing half, on the same twin fit: the two slots of one family file their own
## fired deltas against the one pack, so the store pays their sum - and a second report
## in the same launch charges nothing again.
func test_two_slots_of_one_family_file_their_deltas_once() -> void:
	var twin := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["w_laser", "w_laser"],
	}
	var scene := _launch(LANCER, twin)
	var state: Variant = scene.get(&"_state")
	var stored_before: int = int(_profile.call(&"ammo_of", &"laser"))
	scene.call(&"_seed_ammo")
	assert_eq(state.ammo, [stored_before, stored_before] as Array[int], "both slots loaded")
	state.set_ammo(0, stored_before - 3)
	state.set_ammo(1, stored_before - 5)
	scene.call(&"_file_ammo_report")
	var filed: int = int(_profile.call(&"ammo_of", &"laser"))
	scene.call(&"_file_ammo_report")
	var filed_again: int = int(_profile.call(&"ammo_of", &"laser"))
	assert_eq(
		filed,
		maxi(stored_before - 8, 0),
		"the pack pays both slots' rounds (%d -> %d)" % [stored_before, filed]
	)
	assert_eq(filed_again, filed, "and a repeat report is inert")


## ---------------------------------------------------------------------------
## The HUD push and the mount anchors
## ---------------------------------------------------------------------------


## CONTRACTS section 11's `set_hull_slots` payload: one entry per W cell of the hull's
## own matrix, in layout order, carrying the fitted base id, the catalogue's icon path
## and the input map's selectability. The HUD read-back is asserted too, behind the
## method guard the other HUD pushes use.
func test_the_hud_receives_the_hulls_own_weapon_cells() -> void:
	var fit := {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["w_laser", "w_cannon"],
	}
	var scene := _launch(VANGUARD, fit)
	var cells: Array = _hud_cells(scene)
	assert_eq(cells.size(), 3, "one cell per W cell of the Cutter's grid")
	assert_eq(int(cells[0][&"index"]), 0, "layout index 0")
	assert_eq(int(cells[1][&"index"]), 1, "layout index 1")
	assert_eq(int(cells[2][&"index"]), 2, "layout index 2")
	assert_eq(StringName(cells[0][&"module"]), &"w_laser", "the fitted module")
	assert_eq(String(cells[0][&"icon"]), Catalog.icon_path(&"w_laser"), "its catalogue icon")
	assert_true(bool(cells[0][&"fitted"]), "cell 0 is fitted")
	assert_true(bool(cells[0][&"selectable"]), "and selectable (weapon_1)")
	assert_eq(StringName(cells[2][&"module"]), &"", "an unfitted cell carries no module")
	assert_eq(String(cells[2][&"icon"]), "", "and no icon, so the HUD draws the slot glyph")
	assert_false(bool(cells[2][&"fitted"]), "and it is not fitted")
	var hud: Control = scene.get_node_or_null(NodePath(HUD_NODE)) as Control
	if hud != null and hud.has_method(&"hull_slots"):
		assert_eq(hud.call(&"hull_slots").size(), 3, "the HUD kept the three cells it was handed")


## A 7-W capital: all seven cells display, and the last two are `selectable: false`
## because the input map stops at `weapon_5` (CONTRACTS section 11, owner tick 5).
func test_a_capitals_last_two_cells_display_without_a_key() -> void:
	var weapons: Array = []
	for index in FitData.slot_capacity(CAPITAL, &"weapons"):
		weapons.append("w_laser" if index % 2 == 0 else "w_cannon")
	var fit := {
		&"engines": ["e_std", "e_std", "e_std"],
		&"power": "p_std",
		&"weapons": weapons,
	}
	var scene := _launch(CAPITAL, fit)
	var cells: Array = _hud_cells(scene)
	assert_eq(cells.size(), 7, "the Obliterator's seven W cells")
	for index in cells.size():
		var selectable := bool(cells[index][&"selectable"])
		assert_eq(
			selectable,
			index < WeaponsScript.GROUPS_MAX,
			"cell %d's selectability follows the input map's five groups" % index
		)


## FX_SPEC section 1.3's anchor row, **re-pointed by S5 (09 section 11 supersedes 09
## section 8's one-per-cell rule)**: a hull with a measured map answers the map's own
## `rear` row -- the Mule's render shows **two** lit nozzles against its three engine
## cells, and the map is what the FX draw -- while a hull without one keeps the shipped
## derivation, one anchor per engine cell, and the single tail point for a hull with no
## grid. The Mule's row is `ShipFit.HARDPOINTS[&"ship_freighter"].thrusters.rear`.
func test_the_thruster_anchors_come_from_the_hulls_measured_map() -> void:
	var fit := {
		&"engines": ["e_std", "e_ion", "e_vector"],
		&"power": "p_std",
	}
	var scene := _launch(HAULER, fit)
	var ship: Node2D = scene.get_node_or_null(NodePath(SHIP_NODE)) as Node2D
	assert_true(ship != null, "the launch built its hull")
	if ship == null:
		return
	var map: Dictionary = FitData.hardpoints(HAULER)
	var thrusters: Dictionary = map.get(&"thrusters", {})
	var measured: Array = thrusters.get(&"rear", [])
	assert_eq(measured.size(), 2, "the Mule's render carries two lit nozzles")
	var anchors: Array = ship.call(&"thruster_anchors")
	assert_eq(anchors.size(), measured.size(), "the anchors are the map's own rear row")
	assert_true(
		anchors.size() != FitData.slot_capacity(HAULER, &"engines"),
		"which is the measured art, not the grid's E count (09 section 11 supersedes section 8)"
	)
	var scale: Vector2 = (ship.get_node_or_null(NodePath(&"Hull")) as Sprite2D).scale
	for index in anchors.size():
		var anchor: Vector2 = anchors[index]
		assert_true(anchor.x < 0.0, "anchor %d sits behind the hull's centre" % index)
		assert_true(
			anchor.is_equal_approx((measured[index] as Vector2) * scale),
			"anchor %d is its measured px at the sprite's own scale" % index
		)
	## A hull with no grid keeps the shipped single tail point.
	ship.call(&"set_hull_id", NPC_HULL)
	var fallback: Array = ship.call(&"thruster_anchors")
	assert_eq(fallback.size(), 1, "an NPC hull has no engine cells")
	assert_eq(
		FitData.slot_capacity(NPC_HULL, &"engines"), 0, "which is the empty grid shape"
	)


## ---------------------------------------------------------------------------
## The fitless default
## ---------------------------------------------------------------------------


## CONTRACTS section 11: `const WEAPONS` stays the five-family default a `PlayerState`
## built without a fit still runs on, and `set_weapons` is the launch's one writer -
## it sizes the packs to the ids it is handed and announces every slot.
func test_a_player_state_built_without_a_fit_keeps_the_five_family_default() -> void:
	var state: Variant = PlayerStateScript.new()
	assert_eq(
		state.weapons, PlayerStateScript.WEAPONS, "a fitless state runs on the five families"
	)
	state.setup()
	assert_eq(state.ammo.size(), 5, "five packs")
	assert_eq(state.ammo_max.size(), 5, "and five ceilings")
	state.weapon_changed.connect(_on_weapon_changed)
	var ids: Array[StringName] = [&"laser", &"laser", &"cannon"]
	state.set_weapons(ids)
	assert_eq(state.weapons, ids, "the launched list replaces the default")
	assert_eq(state.ammo.size(), 3, "and sizes the packs to it")
	assert_eq(state.ammo, [300, 300, 300] as Array[int], "seeded to AMMO_DEFAULT")
	assert_eq(_signals, [0, 1, 2] as Array[int], "one announcement per slot")
	state.set_ammo(2, 7)
	assert_eq(state.ammo[2], 7, "set_ammo writes the launched slot")
	assert_eq(_signals, [0, 1, 2, 2] as Array[int], "and announces that slot again")
	assert_eq(PlayerStateScript.WEAPONS.size(), 5, "the const itself never moved")


func _on_weapon_changed(slot: int, _weapon_id: StringName, _ammo: int, _ammo_max: int) -> void:
	_signals.append(slot)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## Launch one hull on one stored fit: the test writes the profile (the launch's own
## source), then instantiates the shipped flight scene, so every resolution, seed and
## push below is the scene's own.
func _launch(hull_id: StringName, fit: Dictionary) -> Node2D:
	_free_scene()
	_profile.set(&"_active_ship", hull_id)
	if fit.is_empty():
		_profile.set(&"_fits", {})
	else:
		_profile.call(&"set_fit", hull_id, fit)
	var packed := load(GAME_SCENE) as PackedScene
	_scene = packed.instantiate() as Node2D
	_fixture_host().add_child(_scene)
	return _scene


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy adding the runner scene, so
## `root.add_child(...)` fails there. The profile autoload took children all through
## the run, and `game.gd` resolves the profile from the tree root, so where the scene
## hangs does not matter to it.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## The cells the flight scene built for the HUD, read off the scene's own builder (not
## the HUD's copy), so the payload is asserted even while the HUD side is mid-wave.
func _hud_cells(scene: Node2D) -> Array:
	return scene.call(&"_hull_slot_cells")


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
