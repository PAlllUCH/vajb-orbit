@tool
extends McpTestSuite
## Suite engine2_pools: the reactor chain of engine slice 0 (ENGINE_SPEC 4.4,
## rulings 10-14) and the pool figures `ShipFit` resolves (section 9/13).
##
## Pure logic: the state is a throwaway `PlayerState` and the fuel cell spends
## through the real `PlayerProfile` singleton with its `save_path` repointed at a
## scratch file, so the player's own profile.cfg is never written and the one cell
## the suite burns is one it added. No physics, no awaits: the gate's runner calls
## test methods synchronously.
##
## The timed half of the same rules (a burn applied per frame over a second, the
## refill under emergency) is measured in `tools/_probe_s0m2_pools.gd`, which can
## step frames.

const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const Profile := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SCRATCH_PROFILE := "user://test_engine2_pools.cfg"
const BOOST_FUEL_PER_SECOND := 3.0
const DASH_FUEL := 25.0
const FRAMES_PER_SECOND := 60

var _state: PlayerState = null
var _profile: Node = null
var _cells_before := 0


func suite_name() -> String:
	return "engine2_pools"


func setup() -> void:
	_delete_file(SCRATCH_PROFILE)
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	_state = PlayerStateScript.new()
	_state.energy_max = stats.energy_max
	_state.fuel_max = stats.fuel_max
	_state.energy_regen = stats.energy_regen
	_state.setup()
	_profile = _service()
	if _profile != null:
		_profile.save_path = SCRATCH_PROFILE
		_cells_before = int(_profile.call(&"cargo_qty", &"fuel_cell"))


func teardown() -> void:
	if _profile != null:
		var held := int(_profile.call(&"cargo_qty", &"fuel_cell"))
		if held != _cells_before:
			if held > _cells_before:
				_profile.call(&"remove_cargo", &"fuel_cell", held - _cells_before)
			else:
				_profile.call(&"add_cargo", &"fuel_cell", _cells_before - held)
		_profile.save_path = Profile.SAVE_FILE
	_profile = null
	_state = null
	_delete_file(SCRATCH_PROFILE)


## ---------------------------------------------------------------------------
## The pool figures the fit resolves
## ---------------------------------------------------------------------------


func test_fit_resolves_the_pool_base_and_the_mass_column() -> void:
	var cutter: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	assert_eq(cutter.energy_max, 100.0, "energy_max base")
	assert_eq(cutter.fuel_max, 200.0, "fuel_max base")
	assert_eq(cutter.energy_regen, 5.0, "energy_regen base")
	assert_eq(cutter.hull_mass, 110.0, "Cutter hull_mass (13 class column)")
	var fighter: ShipStats = ShipFitScript.resolve(&"ship_fighter", ShipFitScript.STANDARD_FIT)
	assert_eq(fighter.hull_mass, 80.0, "Fighter hull_mass")
	var destroyer: ShipStats = ShipFitScript.resolve(&"ship_destroyer", ShipFitScript.STANDARD_FIT)
	assert_eq(destroyer.hull_mass, 300.0, "Destroyer hull_mass")


func test_plating_mass_lands_on_the_hull_mass() -> void:
	var plated: ShipStats = ShipFitScript.resolve(&"ship_vanguard", {
		&"engine": &"e_std", &"power": &"p_std", &"weapons": [], &"shields": [],
		&"armour": [&"h_composite"], &"computers": [], &"boosters": [], &"utility": [],
	})
	assert_true(is_equal_approx(plated.hull_mass, 110.0 * 1.10),
		"h_composite mass_add 0.10 -> 121 t, got %s" % plated.hull_mass)
	assert_true(is_equal_approx(plated.hull_max, 1000.0 + 1000.0),
		"the plate's flat hull_add still applies")


func test_pools_clamp_at_three_times_their_own_base() -> void:
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	assert_eq(stats.energy_max, minf(stats.energy_max, 3.0 * 100.0))
	assert_eq(stats.fuel_max, minf(stats.fuel_max, 3.0 * 200.0))


func test_setup_seeds_both_pools_full() -> void:
	var energy_events: Array[float] = []
	var fuel_events: Array[float] = []
	_state.energy_changed.connect(func(current: float, _maximum: float) -> void:
		energy_events.append(current))
	_state.fuel_changed.connect(func(current: float, _maximum: float) -> void:
		fuel_events.append(current))
	_state.setup()
	assert_eq(_state.energy, 100.0, "energy seeded")
	assert_eq(_state.fuel, 200.0, "fuel seeded")
	assert_eq(energy_events.size(), 1, "one energy_changed at seeding")
	assert_eq(fuel_events.size(), 1, "one fuel_changed at seeding")


## ---------------------------------------------------------------------------
## Spending, the toll, and the two burns
## ---------------------------------------------------------------------------


func test_ten_energy_burns_one_fuel() -> void:
	assert_true(_state.try_spend_energy(10.0), "10 Energy is affordable")
	assert_eq(_state.energy, 90.0, "the pool took the spend")
	assert_true(is_equal_approx(_state.fuel, 199.0),
		"10 Energy x FUEL_PER_ENERGY 0.10 = 1 Fuel, got %s" % _state.fuel)


func test_short_pool_refuses_and_changes_nothing() -> void:
	var energy := _state.energy
	var fuel := _state.fuel
	assert_false(_state.try_spend_energy(energy + 1.0), "a short pool refuses")
	assert_eq(_state.energy, energy, "the pool is untouched")
	assert_eq(_state.fuel, fuel, "no toll is charged on a refusal")


func test_zero_and_negative_spends() -> void:
	assert_true(_state.try_spend_energy(0.0), "zero Energy is a no-op success")
	assert_true(_state.try_spend_fuel(0.0), "zero Fuel is a no-op success")
	assert_false(_state.try_spend_energy(-1.0), "negative Energy is refused")
	assert_false(_state.try_spend_fuel(-1.0), "negative Fuel is refused")
	assert_eq(_state.energy, 100.0, "nothing was spent")
	assert_eq(_state.fuel, 200.0, "no toll was charged")


func test_boost_burns_three_fuel_per_second() -> void:
	for _frame in FRAMES_PER_SECOND:
		_state.try_spend_fuel(BOOST_FUEL_PER_SECOND / float(FRAMES_PER_SECOND))
	assert_true(is_equal_approx(_state.fuel, 200.0 - BOOST_FUEL_PER_SECOND),
		"one second of afterburner burns BOOST_FUEL 3.0, got %s" % _state.fuel)
	assert_eq(_state.energy, 100.0, "boost draws no Energy")


func test_dash_costs_twenty_five_fuel() -> void:
	assert_true(_state.try_spend_fuel(DASH_FUEL), "a dash burst is affordable")
	assert_true(is_equal_approx(_state.fuel, 200.0 - DASH_FUEL),
		"DASH_FUEL 25, got %s" % _state.fuel)


## ---------------------------------------------------------------------------
## Emergency Flight Mode (ruling 14)
## ---------------------------------------------------------------------------


func test_emergency_mode_at_zero_fuel() -> void:
	assert_false(_state.emergency_mode, "a full tank is not in emergency")
	_state.try_spend_fuel(_state.fuel)
	assert_eq(_state.fuel, 0.0, "tank drained")
	assert_true(_state.emergency_mode, "fuel 0 raises the mode")
	assert_false(_state.try_spend_fuel(BOOST_FUEL_PER_SECOND), "boost is locked out")
	assert_false(_state.try_spend_fuel(DASH_FUEL), "dash is locked out")
	assert_eq(_state.reactor_efficiency(), 0.7, "the reactor runs at x0.7")


func test_reactor_efficiency_and_the_refill_penalty() -> void:
	_state.try_spend_fuel(_state.fuel)
	assert_eq(_state.reactor_efficiency(), 0.7, "x0.7 under emergency")
	_state.try_spend_energy(10.0)
	var energy := _state.energy
	_state.tick(1.0)
	assert_true(is_equal_approx(_state.energy - energy, 0.7 * 5.0),
		"one second under emergency refills 0.7 x 5/s, gained %s" % (_state.energy - energy))
	assert_eq(_state.fuel, 0.0, "an empty tank cannot make the toll go negative")


func test_regen_is_demand_driven() -> void:
	_state.tick(1.0)
	assert_eq(_state.energy, 100.0, "a full pool regenerates nothing")
	_state.try_spend_energy(10.0)
	var energy := _state.energy
	_state.tick(1.0)
	assert_true(is_equal_approx(_state.energy - energy, 5.0),
		"a spent pool refills energy_regen 5/s, gained %s" % (_state.energy - energy))


## ---------------------------------------------------------------------------
## The fuel cell (ruling 13)
## ---------------------------------------------------------------------------


func test_fuel_cell_refills_forty_and_ends_the_mode() -> void:
	_require_profile()
	_state.try_spend_fuel(_state.fuel)
	_state.try_spend_energy(10.0)
	assert_true(_state.emergency_mode, "drained for the test")
	_profile.call(&"add_cargo", &"fuel_cell", 1)
	var fuel := _state.fuel
	assert_true(_state.consume_fuel_cell(), "the cell burns")
	assert_true(is_equal_approx(_state.fuel, fuel + 40.0),
		"FUEL_CELL_UNITS 40, got %s" % _state.fuel)
	assert_false(_state.emergency_mode, "the mode ends immediately")
	assert_eq(_state.reactor_efficiency(), 1.0, "efficiency is back to 1.0")
	assert_eq(int(_profile.call(&"cargo_qty", &"fuel_cell")), _cells_before,
		"exactly one cell left the hold")


func test_fuel_cell_cooldown_blocks_a_second_burn() -> void:
	_require_profile()
	_state.try_spend_fuel(_state.fuel)
	_profile.call(&"add_cargo", &"fuel_cell", 2)
	assert_true(_state.consume_fuel_cell(), "the first cell burns")
	assert_eq(_state.fuel_cell_cooldown, 10.0, "the cooldown arms")
	assert_false(_state.consume_fuel_cell(), "the second burn is refused")
	assert_eq(int(_profile.call(&"cargo_qty", &"fuel_cell")), _cells_before + 1,
		"the refused burn cost no cargo")
	_state.tick(10.0)
	assert_eq(_state.fuel_cell_cooldown, 0.0, "the cooldown expires on the tick")


func test_fuel_cell_refuses_a_full_tank_and_an_empty_hold() -> void:
	_require_profile()
	assert_false(_state.fuel_cell_ready(), "a full tank refuses before the hold is read")
	_profile.call(&"add_cargo", &"fuel_cell", 1)
	assert_false(_state.fuel_cell_ready(), "still a full tank")
	assert_false(_state.consume_fuel_cell(), "and it is refused outright")
	assert_eq(_state.fuel_cell_cooldown, 0.0, "a refusal arms no cooldown")
	assert_eq(int(_profile.call(&"cargo_qty", &"fuel_cell")), _cells_before + 1,
		"the cell is still in the hold")
	_state.set_fuel(0.0)
	assert_true(_state.fuel_cell_ready(), "a dry tank with a cell is ready")
	_profile.call(&"remove_cargo", &"fuel_cell", 1)
	assert_false(_state.fuel_cell_ready(), "an empty hold is not ready")


## ---------------------------------------------------------------------------
## The damage context (section 4.2 item 5)
## ---------------------------------------------------------------------------


func test_damage_ctx_is_accepted_and_recorded() -> void:
	var shield := _state.shield
	_state.damage(10.0, false, {&"direction": &"stern", &"source": &"probe"})
	assert_eq(_state.shield, shield - 10.0, "the shield-first rule still holds")
	assert_eq(_state.last_damage_ctx().get(&"direction", &""), "stern",
		"the context is recorded for slice 3")
	var hull := _state.hull
	_state.damage(25.0, true, {&"direction": &"prow"})
	assert_eq(_state.hull, hull - 25.0, "kinetic damage still bypasses the shield")
	assert_eq(_state.last_damage_ctx().get(&"direction", &""), "prow",
		"the second hit's context replaced the first")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## The p1 suites carry this helper per file rather than on the base class.
func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _service() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null(NodePath(PROFILE_SERVICE))


## The fuel-cell tests need the cargo owner; without it the state refuses cleanly,
## which is its own contract, but these three tests are about the successful path.
func _require_profile() -> void:
	if _profile == null:
		fail_setup("the PlayerProfile singleton is not in the tree")
