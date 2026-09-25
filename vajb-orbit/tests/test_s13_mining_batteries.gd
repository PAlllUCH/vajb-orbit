@tool
extends McpTestSuite
## Suite s13_mining_batteries: S13_BRIEF §2 rule 5 / AC3 - N fitted `w_mining`
## modules deliver N x the extraction work per `OreTuning.mine_cycle`, measured
## 1x / 2x / 3x within 20 percent, with no unit realised twice.
##
## The route is N **work channels on the one laser node** (the alternative, N beam
## nodes, would multiply the reticle, the trigger and `_laser`'s single-instance
## reads): `MiningLaser.set_battery(N)`, and `PlayerShip` hands the fitted module
## count in. `extract_cycle` is the one-cycle seam, so the scaling is measured
## without a physics world or the cursor.

const AsteroidScript := preload("res://game/asteroid.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const ROCK_UNITS := 90
const CYCLES := 30
const TOLERANCE := 0.20


func suite_name() -> String:
	return "s13_mining_batteries"


func teardown() -> void:
	OreTuningScript.reset_to_defaults()


## The core AC3 measurement: with a rock that can pay every cycle, the units one
## cycle realises are exactly the module count, so the rate scales N x.
func test_n_modules_deliver_n_times_the_units_per_cycle() -> void:
	var baseline := 0.0
	for bank in [1, 2, 3]:
		var laser := MiningLaserScript.new() as Node2D
		laser.call(&"set_battery", bank)
		assert_eq(int(laser.call(&"battery")), bank, "the battery holds the fitted count")
		var rock := AsteroidScript.new() as RigidBody2D
		rock.call(&"setup", &"iron", 1, ROCK_UNITS)
		var delivered := 0
		for _cycle in CYCLES:
			delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
		var per_cycle := float(delivered) / float(CYCLES)
		assert_true(
			absf(per_cycle - float(bank)) <= TOLERANCE * float(bank),
			"bank %d realises %.3f units/cycle, within 20 %% of %d" % [bank, per_cycle, bank]
		)
		assert_true(delivered <= ROCK_UNITS, "never more than the rock carried")
		var rate := per_cycle / OreTuningScript.mine_cycle
		if bank == 1:
			baseline = rate
		else:
			assert_true(
				absf(rate - baseline * float(bank)) <= TOLERANCE * baseline * float(bank),
				"bank %d's %.4f units/s is within 20 %% of %d x the 1x rate %.4f"
				% [bank, rate, bank, baseline]
			)
		laser.free()
		rock.free()


## One unit of work never realises twice: the rock's own extractable is decremented
## by exactly what the cycles delivered, never more.
func test_extraction_never_pays_a_unit_twice() -> void:
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 3)
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, ROCK_UNITS)
	var delivered := 0
	for _cycle in CYCLES:
		delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
	var removed := ROCK_UNITS - int(rock.get(&"yield_units"))
	assert_eq(removed, delivered, "the rock lost exactly the units the cycles paid")
	assert_true(delivered <= ROCK_UNITS, "and the reserve was never touched")
	laser.free()
	rock.free()


## The fit wiring: `PlayerShip` reads its own module ids and hands the count to the
## one laser node, so a two-module fit mines twice per cycle.
func test_the_ship_hands_its_module_count_to_the_laser() -> void:
	var two: Array[StringName] = [&"w_mining", &"w_mining"]
	var ship := PlayerShipScene.instantiate() as Node2D
	ship.call(&"setup", null, null, two)
	var laser := ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	assert_true(laser != null, "a w_mining fit mounts the laser node")
	if laser != null:
		assert_eq(int(laser.call(&"battery")), 2, "two w_mining modules are two channels")
	var one_fit: Array[StringName] = [&"w_mining"]
	var single := PlayerShipScene.instantiate() as Node2D
	single.call(&"setup", null, null, one_fit)
	var one := single.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	assert_true(one != null, "one module still mounts the node")
	if one != null:
		assert_eq(int(one.call(&"battery")), 1, "and reads one channel")
	ship.free()
	single.free()


## The default: a scene-authored laser with no fit still mines once, so the count
## can never be zero.
func test_the_battery_floor_is_one_channel() -> void:
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 0)
	assert_eq(int(laser.call(&"battery")), 1, "the floor is one channel")
	laser.call(&"set_battery", -4)
	assert_eq(int(laser.call(&"battery")), 1, "and never below it")
	laser.free()
