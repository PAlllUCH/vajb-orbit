@tool
extends McpTestSuite
## Suite s29_hyperdrive: wave S29's `e_hyperdrive` row (A3, `10_ship_acquisition.md`'s
## 2026-10-03 block R-S29-1: name "Hyperdrive", tier 3, slot `engine`, 12 000 CR,
## draw 3, one jump per 30 s cooldown, 1 s spool, no fuel charge) and the N5 machine's
## reads (UI_SPEC.md section 10: `HYPERDRIVE SPOOLING`, `JUMP COOLDOWN <t> s` /
## `JUMP READY`, `ARRIVED \u00b7 <name>`, N4's `NO HYPERDRIVE INSTALLED` caption).
##
## The machine is driven through the shipped flight scene (`test_p2a_launch_fit`'s
## `_launch` idiom: the profile carries the fit, the scene does the rest), with the
## N5 clocks ticked by hand because the gate runs no frames. The profile is the
## shipped autoload on a scratch `save_path` (`test_d6_status.gd`'s idiom).

const ModuleData := preload("res://game/module_catalog.gd")
const AuctionScript := preload("res://game/auction.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const GameScript := preload("res://game/game.gd")

const GAME_SCENE := "res://game/game.tscn"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s29_hyperdrive.cfg"

const VANGUARD: StringName = &"ship_vanguard"
const ENGINE_SLOT: StringName = &"engines"
const DRIVE: StringName = &"e_hyperdrive"
const VECTOR_DRIVE: StringName = &"e_vector"

## R-S29-1's own numbers, restated so a moved row shows as a failure.
const PIN_COST := 12000
const PIN_DRAW := 3
const PIN_TIER := 3

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _scene: Node2D = null
var _staged: Array[Node] = []


func suite_name() -> String:
	return "s29_hyperdrive"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to launch the flight scene")
		return
	var profile := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_free_scene()
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_active_ship", VANGUARD)


func teardown() -> void:
	_free_scene()
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## A3 - the `e_hyperdrive` row (R-S29-1) and its auction roll column
## ---------------------------------------------------------------------------


func test_the_e_hyperdrive_row_carries_r_s29_1s_numbers_verbatim() -> void:
	var row: Dictionary = ModuleData.module(DRIVE)
	assert_true(not row.is_empty(), "the row ships")
	assert_eq(String(row.get(&"name", "")), "Hyperdrive", "name \"Hyperdrive\"")
	assert_eq(StringName(str(row.get(&"slot", &""))), &"engine", "slot `engine` (tier 3's family)")
	assert_eq(int(row.get(&"tier", 0)), PIN_TIER, "tier 3")
	assert_eq(int(row.get(&"cost", 0)), PIN_COST, "cost 12 000 CR")
	assert_eq(int(row.get(&"draw", 0)), PIN_DRAW, "draw 3")
	assert_true((row.get(&"effects", {}) as Dictionary).is_empty(), "no stat effect - it enables the jump")
	assert_eq(ModuleData.fit_slot_of(DRIVE), &"engines", "and fits the engine slot (09 section 1)")


func test_the_hyperdrive_rolls_in_the_auction_source_rolls_engine_column() -> void:
	var pool := AuctionScript.tier_pool(PIN_TIER)
	assert_true(pool.has(DRIVE), "the row joins the tier-3 pool the auction rolls from")
	assert_false(
		ModuleData.EXCLUSIVES.has(DRIVE),
		"and is no faction exclusive (SOURCE_ROLLS' auction row rolls it like any engine)"
	)
	for tier: int in [1, 2, 3]:
		if tier != PIN_TIER:
			assert_false(
				AuctionScript.tier_pool(tier).has(DRIVE), "in exactly one tier's pool"
			)
	var rarity := String(ModuleData.roll_rarity(ModuleData.SOURCE_AUCTION, DRIVE))
	assert_true(
		rarity == "common" or rarity == "magic" or rarity == "rare",
		"the SOURCE_ROLLS auction column answers for it (got %s)" % rarity
	)


func test_the_row_reuses_the_tier3_drive_glyph_so_no_new_art_ships() -> void:
	var row: Dictionary = ModuleData.module(DRIVE)
	var vector: Dictionary = ModuleData.module(VECTOR_DRIVE)
	assert_eq(
		String(row.get(&"icon", "")), String(vector.get(&"icon", "")),
		"the hyperdrive draws `e_vector`'s own glyph (the S3 reuse precedent)"
	)
	assert_eq(
		String(ModuleData.ICON_REUSE.get(DRIVE, &"")), String(vector.get(&"icon", "")),
		"and ICON_REUSE names the same cut"
	)


## ---------------------------------------------------------------------------
## A2 - the N5 reads and clocks (UI_SPEC.md section 10) and the hull seams
## ---------------------------------------------------------------------------


func test_the_jump_reads_are_n11_n13_and_n4s_caption_verbatim() -> void:
	assert_eq(
		GameScript.jump_read_text(GameScript.JUMP_SPOOL, 0, ""), "HYPERDRIVE SPOOLING", "N11"
	)
	assert_eq(
		GameScript.jump_read_text(GameScript.JUMP_COOLDOWN, 12, ""),
		"JUMP COOLDOWN 12 s", "N12's cooldown read"
	)
	assert_eq(GameScript.jump_read_text(GameScript.JUMP_READY, 0, ""), "JUMP READY", "N12's ready read")
	assert_eq(
		GameScript.jump_read_text(GameScript.JUMP_ARRIVE, 0, "Halcyon Reach"),
		"ARRIVED \u00b7 HALCYON REACH", "N13's arrival read, ~2 s"
	)
	assert_eq(GameScript.PIN_CAPTION_NO_DRIVE, "NO HYPERDRIVE INSTALLED", "N4's caption")


func test_the_hyperdrive_clocks_are_n5s_own_numbers() -> void:
	assert_true(is_equal_approx(GameScript.HYPERDRIVE_SPOOL, 1.0), "1 s spool")
	assert_true(is_equal_approx(GameScript.HYPERDRIVE_COOLDOWN, 30.0), "one jump per 30 s")
	assert_true(is_equal_approx(GameScript.HYPERDRIVE_ARRIVAL, 2.0), "the arrival read's ~2 s")


func test_has_hyperdrive_reads_the_fitted_id_and_jump_to_is_an_arrival() -> void:
	var plain_ids: Array[StringName] = []
	plain_ids.assign(ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	var plain := _bare_ship(plain_ids)
	assert_false(plain.call(&"has_hyperdrive"), "a fit without the row carries no jump")
	var fitted_ids: Array[StringName] = [DRIVE]
	var fitted := _bare_ship(fitted_ids)
	assert_true(fitted.call(&"has_hyperdrive"), "the fitted id is the one gate (the u_drones precedent)")
	fitted.set(&"_has_move_target", true)
	fitted.call(&"jump_to", Vector2(4200.0, -1700.0))
	assert_true(
		fitted.global_position.distance_to(Vector2(4200.0, -1700.0)) <= 0.01,
		"the hull is placed at the pin"
	)
	var body := fitted.get(&"_body") as RigidBody2D
	if body != null:
		assert_true(body.linear_velocity.is_zero_approx(), "the velocity into the fold is dropped")
	assert_false(bool(fitted.get(&"_has_move_target")), "and every order is cancelled")


## ---------------------------------------------------------------------------
## A2 - the N5 machine through the shipped flight scene
## ---------------------------------------------------------------------------


func test_hold_on_a_fit_without_the_hyperdrive_shows_n4s_caption() -> void:
	var scene := _launch(VANGUARD, {})
	assert_true(scene != null, "game.tscn launches on the standard fit")
	if scene == null:
		return
	var ship: Variant = scene.get(&"_ship")
	assert_true(ship != null, "and spawns the hull")
	if ship == null:
		return
	assert_false(ship.has_hyperdrive(), "whose fit carries no hyperdrive")
	var before: Vector2 = ship.global_position
	scene.call(&"_on_map_jump_requested", Vector2(6000.0, 2000.0))
	var hud: Node = scene.get(&"_hud")
	var map: Control = hud.call(&"map_deck").call(&"map_view")
	assert_eq(
		String(map.find_child("PinCaption", true, false).get(&"text")),
		"NO HYPERDRIVE INSTALLED",
		"N4's caption under the pin"
	)
	assert_eq(
		String(hud.call(&"map_deck").call(&"jump_read_text")), "",
		"and no N5 read while the module is absent"
	)
	assert_true(
		ship.global_position.distance_to(before) <= 0.01,
		"the hull does not move"
	)


func test_the_machine_spools_one_second_arrives_and_runs_the_thirty_second_cooldown() -> void:
	var scene := _launch(VANGUARD, _hyperdrive_fit())
	assert_true(scene != null, "game.tscn launches on a fitted hyperdrive")
	if scene == null:
		return
	var ship: Variant = scene.get(&"_ship")
	assert_true(ship.has_hyperdrive(), "the fitted id gates the jump")
	var deck: Node = (scene.get(&"_hud") as Node).call(&"map_deck")
	var target := Vector2(5000.0, -3000.0)
	var before: Vector2 = ship.global_position
	scene.call(&"_on_map_jump_requested", target)
	assert_eq(String(deck.call(&"jump_read_text")), "HYPERDRIVE SPOOLING", "N11 the moment it spools")
	scene.call(&"_update_hyperdrive", 0.4)
	assert_eq(String(deck.call(&"jump_read_text")), "HYPERDRIVE SPOOLING", "and spools for the full 1 s")
	assert_true(
		ship.global_position.distance_to(before) <= 0.01,
		"no arrival before the spool ends"
	)
	scene.call(&"_update_hyperdrive", 0.7)
	assert_true(ship.global_position.distance_to(target) <= 0.01, "the arrival lands on the pin")
	assert_true(
		String(deck.call(&"jump_read_text")).begins_with("ARRIVED \u00b7 "),
		"N13's arrival read"
	)
	scene.call(&"_on_map_jump_requested", Vector2.ZERO)
	assert_true(
		String(deck.call(&"jump_read_text")).begins_with("ARRIVED \u00b7 "),
		"a jump inside the cooldown is refused by the read itself"
	)
	scene.call(&"_update_hyperdrive", 2.5)
	assert_true(
		String(deck.call(&"jump_read_text")).begins_with("JUMP COOLDOWN "),
		"N12's cooldown read after the ~2 s arrival read"
	)
	assert_true(ship.global_position.distance_to(target) <= 0.01, "and the refused attempt moved nothing")
	scene.call(&"_update_hyperdrive", 30.0)
	assert_eq(String(deck.call(&"jump_read_text")), "JUMP READY", "N12's ready read when the cooldown ends")


func test_the_short_press_orders_the_existing_autopilot_and_the_pin_remove_cancels_it() -> void:
	var scene := _launch(VANGUARD, {})
	assert_true(scene != null, "game.tscn launches")
	if scene == null:
		return
	var ship: Variant = scene.get(&"_ship")
	scene.call(&"_on_map_autopilot_to", Vector2(900.0, 450.0))
	assert_true(bool(ship.get(&"_has_move_target")), "the short press issues the existing order")
	assert_true(
		(ship.get(&"_move_target") as Vector2).is_equal_approx(Vector2(900.0, 450.0)),
		"to the pin (set_move_target, player_ship.gd)"
	)
	scene.call(&"_on_map_autopilot_cancel")
	assert_false(bool(ship.get(&"_has_move_target")), "the pin's remove cancels it (cancel_orders)")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## R-S29-1's fitted shape: the standard fit with the engine cell holding the row.
func _hyperdrive_fit() -> Dictionary:
	var fit: Dictionary = (ShipFitScript.STANDARD_FIT as Dictionary).duplicate(true)
	fit[ENGINE_SLOT] = [DRIVE]
	return fit


func _bare_ship(fit_ids: Array[StringName]) -> Node2D:
	var fit := {ENGINE_SLOT: [DRIVE]} if fit_ids.has(DRIVE) else ShipFitScript.STANDARD_FIT
	var stats: Variant = ShipFitScript.resolve(VANGUARD, fit)
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship: Variant = PlayerShipScene.instantiate()
	_host().add_child(ship)
	## Staged before `setup`, so a fixture can never leak a `player_ship`-grouped hull
	## into the tree (the group is what `test_s2_6_blur` resolves its fixture through).
	_staged.append(ship)
	ship.call(&"setup", stats, state, fit_ids)
	return ship


func _launch(hull_id: StringName, fit: Dictionary) -> Node2D:
	_free_scene()
	_profile.set(&"_active_ship", hull_id)
	if fit.is_empty():
		_profile.set(&"_fits", {})
	else:
		_profile.call(&"add_module", DRIVE)
		_profile.call(&"set_fit", hull_id, fit)
	var packed := load(GAME_SCENE) as PackedScene
	_scene = packed.instantiate() as Node2D
	_host().add_child(_scene)
	return _scene


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


func _host() -> Node:
	var root := (Engine.get_main_loop() as SceneTree).root
	var profile := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return profile if profile != null else root


func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
