@tool
extends McpTestSuite
## S28 events suite: the battery law and the ore-bloom cap, read off the live
## surfaces rather than off a copy of them.
## Contract: docs/gameplay/01_economy_core.md's 2026-10-08 block (L4: the battery
## and the bloom), docs/gameplay/11_galactic_map.md's 2026-10-08 block (the bloom
## cap) and docs/gameplay/02_minerals.md section 5 (the yield roll). Files under
## test: game/mining_laser.gd, game/ore_tuning.gd, game/poi.gd, game/player_ship.gd.
##
## The battery's law is `1 + gain x (N - 1)` work channels; both the constants and
## the arithmetic come off the live files (`MiningLaser.BATTERY_GAIN`,
## `OreTuning.battery_gain`, `extract_cycle`), and the bloom's cap is
## `Poi.ORE_BLOOM_ROCKS` x `Poi.ORE_BLOOM_YIELD_MULT`. The law's own numbers appear
## only as the expected side of a comparison, never as an input to the arithmetic.
##
## Nothing here touches user://profile.cfg: the battery is measured through the
## `extract_cycle` seam (no physics world or cursor) and the bloom through a
## parentless POI, exactly as `test_s13_mining_batteries.gd` and
## `test_s6_poi_loot.gd` measure them.

const MiningLaserScript := preload("res://game/mining_laser.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PoiScript := preload("res://game/poi.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")

const SUITE_ID := "s28_events"

## 01's L4 (tick M12): N fitted `w_mining` deliver these work channels per cycle.
const CHANNELS_BY_FIT: Dictionary = {1: 1.0, 2: 1.4, 3: 1.8, 7: 3.4}
## A generous reserve so a 7-module fit cannot exhaust the rock inside the sample.
const ROCK_UNITS := 400
const CYCLES := 25
const TOLERANCE := 0.20

## 11's 2026-10-08 block (tick M13): the capped bloom, its untouched trigger and its
## untouched T+1 tier bonus.
const BLOOM_ROCKS := 6
const BLOOM_YIELD_MULT := 1.5
const BLOOM_TIER_BONUS := 1
const BLOOM_TRIGGER_RADIUS := 200.0

var _bare: Array[Node] = []


## A player stand-in for the bloom trigger: the POI reads only `global_position`
## (the bloom ignores it) and, for a fixture, a duck-typed scanner answer (11 §3.1).
class StubPlayer extends Node2D:
	var scanner := true

	func has_scanner() -> bool:
		return scanner


func suite_name() -> String:
	return SUITE_ID


func teardown() -> void:
	OreTuningScript.reset_to_defaults()
	for node: Node in _bare:
		if is_instance_valid(node):
			node.free()
	_bare.clear()


## ----------------------------------------------------------- 1. the battery law


## 01's L4 (tick M12): the gain is declared in the laser, the live default is that
## constant (the S13 anti-drift pattern), and the cycle constant is untouched.
func test_the_battery_gain_is_declared_and_live() -> void:
	assert_true(is_equal_approx(MiningLaserScript.BATTERY_GAIN, 0.4),
		"mining_laser.gd declares the 0.4 gain")
	assert_true(is_equal_approx(OreTuningScript.battery_gain, MiningLaserScript.BATTERY_GAIN),
		"the live gain is the declared constant (the S13 pattern)")
	assert_true(is_equal_approx(MiningLaserScript.MINE_CYCLE, 1.2),
		"the cycle constant is untouched")


## 01's L4 / A6: N fitted `w_mining` deliver `1 + 0.4 x (N - 1)` work channels per
## cycle - 1, 1.4, 1.8 and 3.4 for 1/2/3/7 modules - measured through the one-cycle
## seam, with `battery()` still reporting the fitted count.
func test_the_fit_delivers_the_gain_channels_per_cycle() -> void:
	for fit: int in [1, 2, 3, 7]:
		var laser := MiningLaserScript.new() as Node2D
		laser.call(&"set_battery", fit)
		assert_eq(int(laser.call(&"battery")), fit, "battery() reports the fitted count")
		var rock := AsteroidScript.new() as RigidBody2D
		rock.call(&"setup", &"iron", 1, ROCK_UNITS)
		var delivered := 0
		for _cycle in CYCLES:
			delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
		var per_cycle := float(delivered) / float(CYCLES)
		var expected := float(CHANNELS_BY_FIT[fit])
		assert_true(
			absf(per_cycle - expected) <= TOLERANCE * expected,
			"a %d-module fit delivers %.3f work units/cycle, within 20 %% of %.1f"
				% [fit, per_cycle, expected]
		)
		laser.free()
		rock.free()


## 01's L4: the arithmetic reads the live gain, so a reverted gain (1.0, linear N)
## moves the same measurement - the law is not a literal baked into the laser.
func test_the_law_reads_the_live_gain() -> void:
	OreTuningScript.battery_gain = 1.0
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 3)
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, ROCK_UNITS)
	var delivered := 0
	for _cycle in CYCLES:
		delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
	var per_cycle := float(delivered) / float(CYCLES)
	assert_true(
		absf(per_cycle - 3.0) <= TOLERANCE * 3.0,
		"gain 1.0 restores the linear 3 channels (got %.3f)" % per_cycle
	)
	laser.free()
	rock.free()


## A6: the floor is one channel, and a fit without `w_mining` mounts no laser.
func test_the_floor_is_one_channel_and_no_fit_mounts_no_laser() -> void:
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 0)
	assert_eq(int(laser.call(&"battery")), 1, "the floor is one channel")
	laser.call(&"set_battery", -6)
	assert_eq(int(laser.call(&"battery")), 1, "and never below it")
	laser.free()
	var none: Array[StringName] = [&"w_cannon"]
	var bare := PlayerShipScene.instantiate() as Node2D
	_bare.append(bare)
	bare.call(&"setup", null, null, none)
	assert_true(
		bare.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE)) == null,
		"a fit without w_mining mounts no laser"
	)
	var two: Array[StringName] = [&"w_mining", &"w_mining"]
	var fitted := PlayerShipScene.instantiate() as Node2D
	_bare.append(fitted)
	fitted.call(&"setup", null, null, two)
	var mounted := fitted.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	assert_true(mounted != null, "a w_mining fit mounts the laser node")
	if mounted != null:
		assert_eq(int(mounted.call(&"battery")), 2, "and reads the fitted count")


## ------------------------------------------------------------- 2. the bloom cap


## 11's 2026-10-08 block (tick M13): the capped constants, with the trigger and the
## T+1 tier bonus untouched.
func test_the_bloom_constants_are_capped() -> void:
	assert_eq(PoiScript.ORE_BLOOM_ROCKS, BLOOM_ROCKS, "the bloom spawns 6 rocks")
	assert_true(is_equal_approx(PoiScript.ORE_BLOOM_YIELD_MULT, BLOOM_YIELD_MULT),
		"the yield multiplier reads 1.5")
	assert_eq(PoiScript.ORE_BLOOM_TIER_BONUS, BLOOM_TIER_BONUS, "the T+1 bonus stands")
	assert_true(is_equal_approx(PoiScript.ANOMALY_TRIGGER_RADIUS, BLOOM_TRIGGER_RADIUS),
		"the 200 u trigger stands")


## The live spawn reads those constants: a triggered bloom spawns exactly the capped
## rock count, every rock a tier up, each yield the 1.5x roll of its tier.
func test_a_triggered_bloom_spawns_the_capped_cluster() -> void:
	var poi: Node2D = PoiScript.new() as Node2D
	_bare.append(poi)
	poi.call(&"setup", PoiScript.KIND_ANOMALY, {
		&"sector_id": &"sector_1",
		&"anomaly_kind": PoiScript.ANOMALY_ORE_BLOOM,
		&"seed": 7,
	})
	var player := StubPlayer.new()
	_bare.append(player)
	poi.call(&"trigger", player)
	var rocks := _rocks(poi)
	assert_eq(rocks.size(), PoiScript.ORE_BLOOM_ROCKS, "the spawn reads the rock count")
	var tier := mini(PoiScript.sector_band(1) + PoiScript.ORE_BLOOM_TIER_BONUS, 4)
	assert_eq(tier, 2, "sector 1 is T1, so the bloom is T2")
	var base := int(MineralCatalogScript.TIER_BASE_YIELD.get(tier, 0))
	var low := _bloom_units(base, MineralCatalogScript.YIELD_VARIANCE_MIN)
	var high := _bloom_units(base, MineralCatalogScript.YIELD_VARIANCE_MAX)
	for rock: Node2D in rocks:
		assert_eq(int(rock.get(&"tier")), tier, "every rock is T+1")
		var units := int(rock.get(&"yield_units"))
		assert_true(
			units >= low and units <= high,
			"the yield is a 1.5x roll (%d..%d), got %d" % [low, high, units]
		)
	assert_true(bool(poi.call(&"is_consumed")), "the event is one-shot")


## ----------------------------------------------------------------- internals


## The bloom's own arithmetic, mirrored from `poi.gd`: a `roll_yield` of the tier at
## the given variance, rounded, then scaled by the capped multiplier and rounded.
func _bloom_units(base: int, variance: float) -> int:
	return roundi(
		float(maxi(1, roundi(float(base) * variance))) * PoiScript.ORE_BLOOM_YIELD_MULT
	)


## The bloom's own rocks: the asteroid-group descendants of the POI.
func _rocks(poi: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var stack: Array[Node] = [poi]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			var rock := child as Node2D
			if rock != null and rock.is_in_group(&"asteroid"):
				out.append(rock)
			stack.append(child)
	return out
