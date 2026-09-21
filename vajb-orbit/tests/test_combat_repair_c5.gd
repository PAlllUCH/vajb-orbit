@tool
extends McpTestSuite
## Suite combat_repair_c5: the four defects the C1-C3 measurements proved, plus the
## owner's drag retune (brief `.agents/gen/combat_repair_wave_task.md`; owner rulings
## 2026-09-21, second round). One test per fix, each pinned at the seam the fix lives at:
##
## 1. the rock's collision half (`Asteroid.COLLISION_MASK`): the rock's own mass enters a
##    hull contact, the hull's mass enters it too, and two rocks still do not collide
##    with each other (Godot pairs from both sides: `interacts_with` decides a pair
##    exists, `collides_with` decides whose mass is in the solve - C1's trace);
## 2. the rock's ram sink (`Asteroid.apply_collision_damage`): the peer's half the hull
##    offers lands in the rock's own mining channel at the shipped `GUN_CHIP_RATE`, and
##    there is no second conversion constant to drift from it;
## 3. plasma's `hull_bonus` (C2-F1): the +25 % stays off a live NPC shield, which is what
##    publishing `NpcShip.shield_up()` buys, and lands once the pool is down;
## 4. `WeaponComponent.interval_of`'s fallback (C2-F4): the cannon's burst cycle is a
##    *kinetic* row's cadence, so a family that states none (the mine) reads 0.0 and no
##    gun cadence is invented for it;
## 5. the retune: all nine section 13 `coast_time` rows are scaled x 0.50 and nothing
##    else in the handling column moved (the later flight-feel wave's x 0.50 on
##    `turn_rate` is asserted at its retuned value in the same test, with the ruling
##    that moved it named there).
##
## Nothing awaits a frame: the timed halves - the ram itself, the per-frame beam, the
## decay curve - are measured by C1's, C2's and C3's probes, which are the probes a
## reviewer re-runs. The one private seam reached here is `_apply_beam`, because that is
## where the plasma bonus exists; its ray needs a physics world the synchronous gate does
## not have, so the collider is handed in directly.

const AsteroidScript := preload("res://game/asteroid.gd")
const WeaponScript := preload("res://game/weapons.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")

const PLASMA: StringName = &"plasma"
const MINE: StringName = &"mine"
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const HULL_BODY: StringName = &"HullBody"
const ROCK_MINERAL: StringName = &"iron"

## C1's measured offer for a 450 u/s ram of the shipped hull into a 560 t medium rock:
## `Impact.collision_damage(110.0, 560.0, 450.0)`, to the digit C1 read.
const RAM_OFFER := 186.179104477612

## The rock fixture's yield: 100 units, so the ram's own chip cannot deplete the
## fixture before a second call is measured (C2's matrix carries 100 for the same
## reason). The crack path is measured with its own 8-unit rock.
const ROCK_UNITS := 100
const ROCK_UNITS_SMALL := 8

## One second of plasma at its own row: 70 DPS, and 70 x 1.25 = 87.5 once shields are
## down (section 4.1).
const ONE_SECOND := 1.0
const PLASMA_DPS := 70.0
const PLASMA_BONUS := 1.25

const TOLERANCE := 1e-9

## The section 13 handling column *before* the retune, quoted from
## `docs/gameplay/18_engine_spec.md` "Handling per class". The owner's ruling scales each
## of these by 0.50; keeping the pre-retune figure here is what makes the assertion a
## statement about the ruling rather than a copy of the new table.
const SECTION_13_COAST: Dictionary = {
	&"ship_fighter": 1.6,
	&"ship_vanguard": 2.0,
	&"ship_miner": 3.4,
	&"ship_trader": 2.6,
	&"ship_corvette": 1.8,
	&"ship_freighter": 5.2,
	&"ship_gunship": 3.8,
	&"ship_patrol": 3.4,
	&"ship_destroyer": 5.6,
}

const RETUNE_SCALE := 0.50

var _staged: Array[Node] = []


func suite_name() -> String:
	return "combat_repair_c5"


func teardown() -> void:
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


## ---------------------------------------------------------------------------
## 1. The rock's collision half
## ---------------------------------------------------------------------------


## The shipped `HullBody`'s own layer/mask pair, read off the scene rather than quoted:
## the mask the rock must name is the hull's layer, and the pairing is two-way only when
## each side's mask contains the other's layer.
func test_the_rock_masks_the_hull_layer_so_a_ram_pair_is_two_way() -> void:
	var ship := PlayerShipScene.instantiate() as Node2D
	assert_true(ship != null, "the shipped player_ship.tscn instantiates")
	if ship == null:
		return
	_staged.append(ship)
	var hull := ship.get_node_or_null(NodePath(HULL_BODY)) as RigidBody2D
	assert_true(hull != null, "the hull carries its %s" % HULL_BODY)
	if hull == null:
		return
	var hull_layer := hull.collision_layer
	var hull_mask := hull.collision_mask
	var rock := _rock(ROCK_UNITS)
	assert_eq(rock.collision_layer, AsteroidScript.COLLISION_LAYER, "setup writes the rock layer")
	assert_eq(
		rock.collision_mask,
		AsteroidScript.COLLISION_MASK,
		"setup writes the shipped mask"
	)
	assert_eq(
		AsteroidScript.COLLISION_MASK,
		hull_layer,
		"the mask names the hull's own layer (%d), not merely a non-zero value" % hull_layer
	)
	assert_ne(
		rock.collision_mask & hull_layer,
		0,
		"the rock's inverse mass enters the solve (C1: with mask 0 the solver held it as immovable)"
	)
	assert_ne(
		hull_mask & rock.collision_layer,
		0,
		"and the hull's own mask still sees the rock, so the pair stays two-way"
	)
	assert_eq(
		AsteroidScript.COLLISION_MASK & AsteroidScript.COLLISION_LAYER,
		0,
		"two rocks are both layer 1, so rocks still do not collide with each other"
	)


## ---------------------------------------------------------------------------
## 2. The rock's ram sink
## ---------------------------------------------------------------------------


func test_the_rock_takes_its_half_of_a_ram_through_the_shipped_gun_chip_rate() -> void:
	var rock := _rock(ROCK_UNITS)
	var control := _rock(ROCK_UNITS)
	assert_true(
		rock.has_method(&"apply_collision_damage"),
		"the rock answers the peer's half of a collision (CONTRACTS section 4)"
	)
	assert_true(rock.has_method(&"apply_work"), "and keeps its mining channel")
	rock.call(&"apply_collision_damage", RAM_OFFER)
	control.call(&"apply_work", RAM_OFFER * WeaponScript.GUN_CHIP_RATE)
	assert_true(
		_near(rock.work, control.work),
		"the ram's conversion is the shipped gun chip rate, not a second constant (%.9f vs %.9f)"
		% [rock.work, control.work]
	)
	## `apply_work` converts whole units the moment they are reached, so the credit is the
	## units that left plus the fraction still in the accumulator (C2's `work_credited`).
	var credited := float(ROCK_UNITS - int(rock.yield_units)) + float(rock.work)
	assert_true(
		_near(credited, RAM_OFFER * WeaponScript.GUN_CHIP_RATE),
		"a 186.179 offer credits exactly 10 %% of it, 18.618 work: %.9f" % credited
	)
	assert_eq(rock.yield_units, ROCK_UNITS - 18, "18 whole ore units leave the rock")
	assert_eq(control.yield_units, ROCK_UNITS - 18, "nothing is lost on the way through")


## The same channel is the one that cracks a rock, so a hard ram can deplete a low-yield
## rock exactly as gunfire can (measured: 18.618 work against an 8-unit roll).
func test_a_ram_reaches_the_crack_path_the_guns_use() -> void:
	var small := _rock(ROCK_UNITS_SMALL)
	var cracks: Array[int] = []
	small.connect(&"cracked", func() -> void: cracks.append(1))
	assert_true(not small.is_depleted(), "the fixture starts with ore in it")
	small.call(&"apply_collision_damage", RAM_OFFER)
	assert_eq(small.yield_units, 0, "the ram's chip emptied the rock")
	assert_true(small.is_depleted(), "and the rock is depleted")
	assert_eq(cracks.size(), 1, "cracked fires once, through the same door a gun uses")


## ---------------------------------------------------------------------------
## 3. Plasma's hull bonus (C2-F1)
## ---------------------------------------------------------------------------


func test_plasma_bonus_stays_off_a_live_npc_shield() -> void:
	var live := _npc(600.0)
	assert_true(live.call(&"shield_up"), "a 600-shield NPC hull reads shields-up")
	assert_true(
		bool(_guns().call(&"_shield_up", live)),
		"the weapon side's own reading agrees with the hull's (the C2-F1 gap)"
	)
	var shield_before := float(live.call(&"shield"))
	var hull_before := float(live.call(&"hull"))
	_beam_plasma(live)
	var shield_delta := shield_before - float(live.call(&"shield"))
	var hull_delta := hull_before - float(live.call(&"hull"))
	assert_true(
		_near(shield_delta, PLASMA_DPS),
		"a 1 s plasma hold removes the row's 70.000 through a live shield, not 87.500: %.3f"
		% shield_delta
	)
	assert_true(_near(hull_delta, 0.0), "no carry-over: the hull is untouched (%.3f)" % hull_delta)


func test_plasma_bonus_lands_once_the_npc_shield_pool_is_down() -> void:
	var inert := _npc(0.0)
	assert_true(not inert.call(&"shield_up"), "a zero-pool NPC hull reads shields-down")
	assert_true(
		not bool(_guns().call(&"_shield_up", inert)),
		"so the weapon side reads it the same way"
	)
	var hull_before := float(inert.call(&"hull"))
	_beam_plasma(inert)
	var hull_delta := hull_before - float(inert.call(&"hull"))
	var shield_delta := float(inert.call(&"shield"))
	assert_true(
		_near(hull_delta, PLASMA_DPS * PLASMA_BONUS),
		"the row's own +25 %% lands on the hull: 70 x 1.25 = 87.500, measured %.3f" % hull_delta
	)
	assert_true(_near(shield_delta, 0.0), "the inert pool stays at zero (%.3f)" % shield_delta)


## ---------------------------------------------------------------------------
## 4. The cadence fallback (C2-F4)
## ---------------------------------------------------------------------------


func test_the_interval_fallback_is_family_aware() -> void:
	assert_eq(WeaponScript.family_of(MINE), &"deployable", "the mine's family is a deployable")
	assert_eq(
		WeaponScript.interval_of(MINE),
		0.0,
		"a deployable that states no cadence reads none, not the guns' 0.600"
	)
	assert_eq(
		WeaponScript.interval_of(&"cannon"),
		WeaponScript.KINETIC_INTERVAL,
		"a kinetic row still borrows the cannon's burst cycle"
	)
	assert_eq(
		WeaponScript.interval_of(&"railgun"),
		WeaponScript.KINETIC_INTERVAL,
		"and so does the railgun, whose row states no cycle either"
	)
	assert_eq(WeaponScript.interval_of(&"rocket"), 1.2, "the rocket keeps its own row")
	assert_eq(WeaponScript.interval_of(&"laser"), 0.0, "an instant family has no shot cadence")
	assert_eq(
		WeaponScript.shot_damage(MINE),
		float(WeaponScript.row_of(MINE)[&"alpha"]),
		"the mine's damage is its alpha, so the fallback never reaches it"
	)


## ---------------------------------------------------------------------------
## 5. The drag retune
## ---------------------------------------------------------------------------


func test_the_coast_column_is_the_retuned_half_of_the_section_13_rows() -> void:
	assert_eq(
		ShipFitScript.HANDLING.size(),
		SECTION_13_COAST.size(),
		"all nine classes of the handling column were retuned"
	)
	for hull_id: StringName in SECTION_13_COAST:
		assert_true(
			ShipFitScript.HANDLING.has(hull_id),
			"%s is still in the handling column" % hull_id
		)
		var row: Dictionary = ShipFitScript.HANDLING.get(hull_id, {})
		var before := float(SECTION_13_COAST[hull_id])
		var after := float(row.get(&"coast_time", -1.0))
		assert_true(
			_near(after, before * RETUNE_SCALE),
			"%s: coast_time %.3f -> %.3f (the owner's x 0.50)" % [hull_id, before, after]
		)
	## The rest of the shipped hull's row is the section 13 column untouched: a retune of
	## the release must not have moved the speed or the accelerate leg with it.
	## `turn_rate` is the one column that moved *after* this suite was written -- the
	## flight-feel wave's owner ruling (2026-09-21, third round) scaled all nine rows
	## x 0.50, so the Vanguard's 3.0 rad/s is 1.5 -- and it is asserted at its retuned
	## value here so this file keeps proving the coast retune's own blast radius.
	var vanguard: Dictionary = ShipFitScript.HANDLING[&"ship_vanguard"]
	assert_true(_near(float(vanguard[&"max_speed"]), 428.0), "max_speed is still 428")
	assert_true(_near(float(vanguard[&"accel_time"]), 2.4), "accel_time is still 2.4")
	assert_true(
		_near(float(vanguard[&"turn_rate"]), 1.5),
		"turn_rate is the flight-feel x 0.50 (3.0 -> 1.5)"
	)
	assert_true(_near(float(vanguard[&"turn_spinup"]), 0.5), "turn_spinup is still 0.5")
	assert_true(_near(float(vanguard[&"hull_mass"]), 110.0), "hull_mass is still 110")
	## The plating multiplier still rides on the retuned row (C3: the launch fit's
	## `h_plate_light` is what made 2.0 s resolve to 2.1 s; it is what makes 1.0 s resolve
	## to 1.05 s now).
	var penalty := absf(float(ShipFitScript.MODULES[&"h_plate_light"][&"effects"][&"speed_penalty"]))
	var stats: Variant = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	assert_true(stats != null, "the shipped hull resolves")
	if stats != null:
		assert_true(
			_near(float(stats.coast_time), 1.0 * (1.0 + penalty)),
			"the launched Vanguard's coast time is 1.05 s, measured %.3f" % float(stats.coast_time)
		)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A rock as `Asteroid.setup` builds it. Detached, like the cleaving suite's field: the
## body properties are measurable without a physics world.
func _rock(units: int) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", ROCK_MINERAL, 1, units, AsteroidScript.SIZE_MEDIUM)
	_staged.append(rock)
	return rock


## A real `NpcShip` with `shield_max` forced to the passed pool (0.0 is the inert case:
## no regen can re-fill a zero pool, so the hull is the only pool left).
func _npc(shield_max: float) -> Node2D:
	var stats: ShipStats = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	stats.shield_max = shield_max
	var npc := NpcShipScript.new() as Node2D
	npc.call(&"setup", NPC_ARCHETYPE, stats, NPC_HULL, {&"sprite_path": NPC_SPRITE})
	_staged.append(npc)
	return npc


func _guns() -> Node2D:
	var guns := WeaponScript.new() as Node2D
	_staged.append(guns)
	return guns


## One second of the plasma beam on a target, through the beam's own delivery: the ray
## needs a physics world, so the collider is handed in directly. `delta` 1.0 makes the
## frame's damage the row's own DPS, which is the number C2's 1 s holds measured.
func _beam_plasma(target: Node2D) -> void:
	var guns := _guns()
	guns.call(
		&"_apply_beam",
		PLASMA,
		WeaponScript.row_of(PLASMA),
		target,
		target.global_position,
		ONE_SECOND
	)


func _near(measured: float, expected: float, tolerance: float = TOLERANCE) -> bool:
	return absf(measured - expected) <= tolerance
