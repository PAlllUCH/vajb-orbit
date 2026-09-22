@tool
extends McpTestSuite
## Suite engine_c3_flight_decay: the construction half of C3's flight-decay measurement.
##
## `tests/probe_c3_flight_decay.tscn` measures the shipped envelope (speed and distance
## per 0.1 s after a throttle release). This suite pins what builds that envelope, so a
## later retune cannot quietly re-point the decay at a literal:
##
## 1. every hull of the section 13 handling column reaches its body as
##    `linear_damp = 1 / coast_time` (DAMP_MODE_REPLACE) and `angular_damp =
##    1 / turn_spinup` — the two damp sizes the body integrates;
## 2. the release brake is `max_speed / coast_time` and the accelerate leg is
##    `max_speed / accel_time`, read straight off the `ShipStats` snapshot
##    (CONTRACTS section 4: "constants arrive via `ShipStats`, no literals in movement
##    code");
## 3. the afterburner case rides on the module's own numbers (`boost_speed_mult` 1.6,
##    `duration` 3.0 s, `cooldown` 8.0 s) and on `ShipStats.boosters` carrying the id,
##    which is what lets the burn light at all.
##
## Nothing here awaits a frame: every reading is synchronous off a shipped seam
## (instantiate + `setup` is enough, because `_apply_rigid_body` runs inside it), which is
## what keeps the gate deterministic. The numbers themselves are the probe's business; this
## suite deliberately pins the *ratios* and not the section 13 values, so C5's retune of
## the coast column moves the probe's curve without reddening this file.

const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const BOOSTER: StringName = &"b_afterburner"
const PLATE: StringName = &"h_plate_light"
const HULL_SHIPPED: StringName = &"ship_vanguard"
const HULL_FASTEST: StringName = &"ship_fighter"
const TOLERANCE := 1e-6

var _staged: Array[Node] = []


func suite_name() -> String:
	return "engine_c3_flight_decay"


func teardown() -> void:
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## 1-2. The class column reaches the body, and the release rates are its ratios
## ---------------------------------------------------------------------------


func test_the_coast_column_reaches_every_hulls_body_as_the_damp() -> void:
	## The resolved coast time is the row times the fit's plating multiplier times the
	## 2026-09-22 flight-feel ruling's `COAST_TIME_MULT` (x 2.0, the documented revert of
	## the combat wave's x 0.50 -- CONTRACTS section 14). The row itself is the retuned
	## half-of-section-13 literal this suite's other test pins, so the two halves of the
	## release are asserted against their own sources.
	var plate_penalty := absf(float(ShipFitScript.MODULES[PLATE][&"effects"][&"speed_penalty"]))
	var multiplier := (1.0 + plate_penalty) * ShipFitScript.COAST_TIME_MULT
	var checked := 0
	for raw_key: Variant in ShipFitScript.HANDLING.keys():
		var hull_id := StringName(raw_key)
		var row: Dictionary = ShipFitScript.HANDLING[hull_id]
		var pair := _launch(hull_id, ShipFitScript.STANDARD_FIT)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		assert_true(
			_near(stats.coast_time, float(row[&"coast_time"]) * multiplier, TOLERANCE),
			(
				"%s: the resolved coast time is the row x the plating multiplier x COAST_TIME_MULT (got %.6f)"
				% [hull_id, stats.coast_time]
			)
		)
		var body: RigidBody2D = ship.impact_body()
		if body == null:
			assert_true(false, "%s: the hull carries no rigid body" % hull_id)
			continue
		assert_true(
			_near(body.linear_damp, 1.0 / stats.coast_time, TOLERANCE),
			(
				"%s: the linear damp is 1 / coast_time (got %.6f, coast_time %.3f)"
				% [hull_id, body.linear_damp, stats.coast_time]
			)
		)
		assert_eq(
			body.linear_damp_mode,
			RigidBody2D.DAMP_MODE_REPLACE,
			"%s: the class damp replaces the project default, it does not add to it" % hull_id
		)
		assert_true(
			_near(body.angular_damp, 1.0 / stats.turn_spinup, TOLERANCE),
			"%s: the angular damp is 1 / turn_spinup, the same construction" % hull_id
		)
		checked += 1
	assert_eq(
		checked,
		ShipFitScript.HANDLING.size(),
		"every hull of the section 13 handling column was measured"
	)


func test_the_release_rates_are_the_snapshots_own_ratios() -> void:
	for hull_id: StringName in [HULL_SHIPPED, HULL_FASTEST]:
		var pair := _launch(hull_id, ShipFitScript.STANDARD_FIT)
		var ship: Variant = pair[0]
		var stats: Variant = pair[1]
		if ship == null or stats == null:
			assert_true(false, "%s: the hull fixture did not build" % hull_id)
			continue
		assert_true(stats.coast_time > 0.0 and stats.accel_time > 0.0, "%s carries its two times" % hull_id)
		assert_true(
			_near(float(ship.call(&"_coast_rate")), stats.max_speed / stats.coast_time, TOLERANCE),
			(
				"%s: the released throttle brakes at max_speed / coast_time (%.6f u/s^2)"
				% [hull_id, stats.max_speed / stats.coast_time]
			)
		)
		assert_true(
			_near(float(ship.call(&"_accel_rate")), stats.max_speed / stats.accel_time, TOLERANCE),
			(
				"%s: the accelerate leg is max_speed / accel_time (%.6f u/s^2)"
				% [hull_id, stats.max_speed / stats.accel_time]
			)
		)
		assert_true(
			_near(float(ship.call(&"_linear_damp")), 1.0 / stats.coast_time, TOLERANCE),
			"%s: the damp the release rides on is 1 / coast_time" % hull_id
		)


## ---------------------------------------------------------------------------
## 3. The afterburner case's own numbers
## ---------------------------------------------------------------------------


func test_the_afterburner_case_rides_on_the_modules_own_numbers() -> void:
	var effects: Dictionary = ShipFitScript.MODULES[BOOSTER][&"effects"]
	assert_true(
		_near(float(effects[&"boost_speed_mult"]), 1.6, TOLERANCE),
		"the burn's speed multiplier is the 09 section 3.5 +60 percent"
	)
	assert_true(float(effects[&"duration"]) > 0.0, "the burn has a duration to expire on")
	assert_true(float(effects[&"cooldown"]) > 0.0, "the burn has a cooldown")
	var fit: Dictionary = ShipFitScript.STANDARD_FIT.duplicate(true)
	fit[&"boosters"] = [BOOSTER]
	var boosted: Variant = ShipFitScript.resolve(HULL_SHIPPED, fit)
	var plain: Variant = ShipFitScript.resolve(HULL_SHIPPED, ShipFitScript.STANDARD_FIT)
	if boosted == null or plain == null:
		assert_true(false, "the booster fit did not resolve")
		return
	assert_true(boosted.boosters.has(BOOSTER), "a fit listing the afterburner resolves it into the snapshot")
	assert_false(plain.boosters.has(BOOSTER), "the standard fit grants no burn")
	var pair := _launch(HULL_SHIPPED, fit)
	var ship: Variant = pair[0]
	if ship == null:
		assert_true(false, "the boosted hull fixture did not build")
		return
	assert_true(ship.has_booster(BOOSTER), "the hull's own gate sees the fitted booster")
	var boosted_cruise: float = plain.max_speed * float(effects[&"boost_speed_mult"])
	assert_true(
		boosted_cruise > plain.max_speed,
		(
			"the burn raises the target the release starts from: %.3f u/s against %.3f u/s"
			% [boosted_cruise, plain.max_speed]
		)
	)


## ---------------------------------------------------------------------------
## Shared fixture
## ---------------------------------------------------------------------------


## One launched hull, the fixture the W6/W7 probes use: the resolved fit, a throwaway
## `PlayerState` seeded from it, then the shipped `PlayerShip.setup` (which is where
## `_apply_rigid_body` writes the damp, the mass and the inertia).
func _launch(hull_id: StringName, fit: Dictionary) -> Array:
	var stats: Variant = ShipFitScript.resolve(hull_id, fit)
	if stats == null:
		return [null, null]
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
	if ship == null:
		return [null, null]
	_host().add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return [ship, stats]


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the
## runner scene during `_ready` (see `test_engine2_fixes.gd`).
func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _near(measured: float, expected: float, tolerance: float) -> bool:
	return absf(measured - expected) <= tolerance
