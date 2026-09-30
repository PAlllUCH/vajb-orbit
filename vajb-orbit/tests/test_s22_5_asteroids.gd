@tool
extends McpTestSuite
## Suite s22_5_asteroids: wave S22.5's rock toughness (02 §5.3's A1-A5, owner-ticked
## 2026-09-30). One row per acceptance item, every fixture seeded and every reading
## taken through the shipped doors (`setup`, `_new_rock`, `apply_work`,
## `apply_gun_work`, `apply_collision_damage`), never a private copy of the arithmetic.
##
##   A1 - the per-rock toughness roll: band, reproducibility per field seed, and a
##        randomized field's own values;
##   A2 - the gun door divides by `size_toughness_mult[class] x toughness`, the four
##        T1 size times at the mean roll, and S is no longer an XL;
##   A3 - the mining door keeps the pinned 1.2 s/unit pace at any class and roll;
##   A4 - a 10-damage chip and a 10-damage ram do not crack an S fragment, the S
##        budget's 2.0 work does, and an S fragment survives >= 0.6 s of w_laser;
##   A5 - a gun-born fragment keeps bore 0 and never splits further;
##   A6 - the L/XL chip splinter: a real S body, its rate (25 %), the 0.5 s cap, S/M
##        rocks shed none and a cracking hit sheds none;
##   A7 - no ore is minted (the fully shot family cap) and the sealed constants are
##        the pinned rows.
##
## The T1 fixture is the one 02 §5.3's own worked table derives: a tier-1 rock with
## the mean yield roll's **6 work units** at the mean toughness roll (its "mining
## stays 7.2 s" line is the same 6 x 1.2 s). A field-spawned T1 rock carries S13's
## reserve, so its extractable is 4 units and every figure below scales by 4/6; the
## reserve arithmetic is rule 6's read-only region and is untouched.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 22501
const FIELD_ROCKS := 6
## The T1 mean yield roll: tier base 6 x variance 1.0 (02 §5).
const T1_WORK_UNITS := 6
## weapons.gd's FAMILIES.laser dps and GUN_CHIP_RATE (the beam's raw work per second).
const LASER_DPS := 30.0
## The simulated beam step, so a "measured time" is a sum of shipped chip calls.
const LASER_STEP := 0.01
## The A6 statistical sample and its tolerance band (points of the 0.25 chance).
const SPLINTER_ROLLS := 200
const SPLINTER_TOLERANCE := 0.06
## The seeded `_solo_field` fixture's root, matching the S13/S14 families (its own
## bore, so the shot-family cap is exercised at a large budget).
const ROOT_UNITS := 24
const MAX_STEPS := 200000

const PICKUP_GROUP: StringName = &"pickup"
const SPLINTER_PREFIX := "Splinter"

## 02 §5.3's anti-drift yardstick, a second copy of the pinned rows the F1 overlay
## must never have let drift (the S14/S16 pattern).
const PINNED_SPLIT_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
const PINNED_SIZE_WEIGHTS: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}
const PINNED_TIER_YIELD: Dictionary = {1: 6, 2: 5, 3: 4, 4: 3}

var _fields: Array[Node] = []
var _loose: Array[Node] = []


func suite_name() -> String:
	return "s22_5_asteroids"


func teardown() -> void:
	for node: Node in _loose:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_loose.clear()
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	_fields.clear()
	## A case that tuned the surface must not leak into the next suite.
	OreTuningScript.reset_to_defaults()


## ---------------------------------------------------------------------------
## A1 - the per-rock roll
## ---------------------------------------------------------------------------


func test_a1_every_field_rock_carries_a_rolled_toughness_in_band() -> void:
	var field := _field(FIELD_SEED)
	assert_eq(int(field.call(&"rock_count")), FIELD_ROCKS, "the field rolled its rocks")
	var seen := {}
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		var value := float(rock.call(&"toughness"))
		assert_true(
			value >= OreTuningScript.toughness_min and value <= OreTuningScript.toughness_max,
			"toughness %.6f sits in [%.2f, %.2f]"
			% [value, OreTuningScript.toughness_min, OreTuningScript.toughness_max]
		)
		seen[value] = true
	assert_true(seen.size() >= 2, "the rolls are per-rock, not one constant")
	print("[S22.5] A1 rocks=%d distinct_rolls=%d" % [FIELD_ROCKS, seen.size()])


func test_a1_the_roll_is_reproducible_per_seed() -> void:
	var a := _toughnesses(_field(FIELD_SEED))
	var b := _toughnesses(_field(FIELD_SEED))
	assert_eq(str(a), str(b), "two fields with one seed roll identical toughnesses")
	var c := _toughnesses(_field(0))
	assert_ne(str(a), str(c), "a randomized field rolls its own values")
	print("[S22.5] A1 same_seed_identical=true fresh_field_differs=true")


## ---------------------------------------------------------------------------
## A2 - the gun-door divisor and the four size times
## ---------------------------------------------------------------------------


func test_a2_a_gun_hit_divides_by_the_class_mult_and_its_own_roll() -> void:
	var mean := _mean_toughness()
	for size_class: int in [0, 1, 2, 3]:
		var rock := _tough_rock(size_class, T1_WORK_UNITS, mean)
		var expected := 1.0 / (
			float(OreTuningScript.size_toughness_mult[size_class]) * mean
		)
		assert_eq(
			int(rock.call(&"apply_gun_work", 1.0)), 0,
			"one work no longer mines a unit out of a class-%d rock" % size_class
		)
		assert_true(
			absf(float(rock.get(&"work")) - expected) < 1e-9,
			"class %d deposited %.9f work for one work in, expected %.9f"
			% [size_class, float(rock.get(&"work")), expected]
		)


func test_a2_the_four_t1_size_times_at_the_mean_roll() -> void:
	var mean := _mean_toughness()
	var floors := {0: 3.0, 1: 5.0, 2: 8.0, 3: 12.0}
	var measured := {}
	for size_class: int in [0, 1, 2, 3]:
		var rock := _tough_rock(size_class, T1_WORK_UNITS, mean)
		var time := _laser_time(rock)
		measured[size_class] = time
		var expected := float(T1_WORK_UNITS) * OreTuningScript.work_per_unit \
			* float(OreTuningScript.size_toughness_mult[size_class]) * mean \
			/ (LASER_DPS * OreTuningScript.gun_chip_rate)
		assert_true(
			time >= float(floors[size_class]),
			"class %d takes %.2f s >= the %.1f s floor" % [size_class, time, floors[size_class]]
		)
		assert_true(
			time <= expected + 2.0 * LASER_STEP,
			"class %d measured %.2f s against the %.2f s the divisor predicts"
			% [size_class, time, expected]
		)
	assert_true(
		float(measured[3]) > float(measured[0]) * 3.0,
		"S and XL no longer read alike (%.2f s vs %.2f s)" % [measured[0], measured[3]]
	)
	print("[S22.5] A2 work_total=%.1f S=%.2fs M=%.2fs L=%.2fs XL=%.2fs"
		% [float(T1_WORK_UNITS) * OreTuningScript.work_per_unit,
			measured[0], measured[1], measured[2], measured[3]])


## ---------------------------------------------------------------------------
## A3 - the mining door keeps its pace
## ---------------------------------------------------------------------------


func test_a3_mining_keeps_its_one_point_two_second_pace_at_any_roll() -> void:
	assert_true(
		is_equal_approx(MiningLaserScript.MINE_CYCLE, 1.2),
		"the mining cycle is still the pinned 1.2 s"
	)
	for size_class: int in [0, 1, 2, 3]:
		for toughness: float in [OreTuningScript.toughness_min, OreTuningScript.toughness_max]:
			var rock := _tough_rock(size_class, 12, toughness)
			assert_eq(
				int(rock.call(&"apply_work", OreTuningScript.work_per_unit)), 1,
				"one work unit mines one ore unit (class %d, roll %.2f)"
				% [size_class, toughness]
			)
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 1)
	var rock := _tough_rock(3, 12, OreTuningScript.toughness_max)
	assert_eq(
		int(laser.call(&"extract_cycle", rock, Vector2.ZERO)), 1,
		"one 1.2 s cycle realises one unit even on a max-roll XL"
	)
	laser.free()
	print("[S22.5] A3 mine_cycle=%.1f units_per_cycle=1" % MiningLaserScript.MINE_CYCLE)


## ---------------------------------------------------------------------------
## A4 - debris budgets
## ---------------------------------------------------------------------------


func test_a4_a_chip_and_a_ram_do_not_crack_an_s_fragment() -> void:
	var field := _solo_field()
	var chip_frag := _fragment(field, AsteroidScript.SIZE_SMALL, "ChipFrag")
	assert_eq(
		int(chip_frag.call(&"apply_gun_work", 1.0)), 0,
		"a 10-damage chip (work 1.0) no longer cracks an S fragment"
	)
	assert_eq(float(chip_frag.get(&"work")), 1.0, "the chip's full work is banked")
	var ram_frag := _fragment(field, AsteroidScript.SIZE_SMALL, "RamFrag")
	ram_frag.call(&"apply_collision_damage", 10.0)
	assert_eq(float(ram_frag.get(&"work")), 1.0, "a 10-damage ram is the same work unit")
	assert_true(
		not bool(ram_frag.get(&"_cracked")),
		"and it does not insta-crack the fragment either"
	)
	var exact := _fragment(field, AsteroidScript.SIZE_SMALL, "ExactFrag")
	var cracks: Array[int] = []
	exact.connect(&"cracked", func() -> void: cracks.append(1))
	exact.call(&"apply_gun_work", 2.0)
	assert_eq(cracks.size(), 1, "the S budget's 2.0 work does crack it")
	var beam := _fragment(field, AsteroidScript.SIZE_SMALL, "BeamFrag")
	var time := _laser_time(beam)
	assert_true(time >= 0.6, "an S fragment survives >= 0.6 s of w_laser (%.3f s)" % time)
	print("[S22.5] A4 chip=1.0 alive=true ram=1.0 alive=true budget_crack=true beam=%.3fs" % time)


func test_a4_each_debris_class_takes_its_own_budget() -> void:
	var field := _solo_field()
	for size_class: int in [0, 1, 2]:
		var budget := float(OreTuningScript.fragment_work[size_class])
		var rock := _fragment(field, size_class, "Budget%d" % size_class)
		var cracks: Array[int] = []
		rock.connect(&"cracked", func() -> void: cracks.append(1))
		rock.call(&"apply_gun_work", budget - 0.25)
		assert_eq(cracks.size(), 0, "class %d survives %.2f work" % [size_class, budget - 0.25])
		rock.call(&"apply_gun_work", 0.25)
		assert_eq(cracks.size(), 1, "class %d cracks at its own %.2f budget" % [size_class, budget])


## ---------------------------------------------------------------------------
## A5 - debris keeps bore 0 and never splits further
## ---------------------------------------------------------------------------


func test_a5_a_gunborn_fragment_keeps_bore_zero_and_splits_per_parentage() -> void:
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var before := _live_ids(field)
	_gun_deplete(root)
	var children := _new_since(field, before)
	assert_true(children.size() >= 1, "a shot XL still leaves fragments")
	var smalls: Array[Node2D] = []
	for child: Node2D in children:
		assert_true(float(child.call(&"bore_ore")) == 0.0, "a gun-born fragment carries bore 0")
		assert_true(bool(child.call(&"cleaves")), "parentage marks it for its own cleave")
		if int(child.call(&"size_class")) == AsteroidScript.SIZE_SMALL:
			smalls.append(child)
	assert_true(not smalls.is_empty(), "the mixed set carries its S pieces")
	for small: Node2D in smalls:
		var before_break := _live_ids(field)
		_gun_deplete(small)
		assert_eq(
			_new_since(field, before_break).size(), 0,
			"an S fragment's cleave is the bare break: it never splits further"
		)
	print("[S22.5] A5 children=%d bore_zero=true s_stops=true" % children.size())


## ---------------------------------------------------------------------------
## A6 - chip splinters
## ---------------------------------------------------------------------------


func test_a6_a_non_cracking_hit_on_an_l_sheds_one_real_splinter() -> void:
	var field := _solo_field()
	var rock := _member(field, AsteroidScript.SIZE_LARGE, T1_WORK_UNITS, "L")
	OreTuningScript.splinter_chance = 1.0
	var before := _live_ids(field)
	rock.call(&"apply_gun_work", 0.5)
	var splinters := _splinters_since(field, before)
	assert_eq(splinters.size(), 1, "one non-cracking chip sheds exactly one splinter")
	var splinter: Node2D = splinters[0]
	assert_eq(
		int(splinter.call(&"size_class")), AsteroidScript.SIZE_SMALL,
		"a splinter is a real S-class body"
	)
	assert_true(float(splinter.call(&"bore_ore")) == 0.0, "born bore 0, so it pays nothing")
	var radial := (splinter.global_position - rock.global_position).normalized()
	assert_true(
		(splinter as RigidBody2D).linear_velocity.dot(radial) > 0.0,
		"ejected outward along its own placement radial"
	)
	rock.call(&"apply_gun_work", 0.5)
	assert_eq(
		_splinters_since(field, before).size(), 1,
		"the 0.5 s cap refuses a second shed in the same instant"
	)
	OS.delay_msec(600)
	rock.call(&"apply_gun_work", 0.5)
	assert_eq(
		_splinters_since(field, before).size(), 2,
		"past the window it may shed again"
	)
	OreTuningScript.splinter_chance = 0.0
	rock.call(&"apply_gun_work", 0.5)
	assert_eq(_splinters_since(field, before).size(), 2, "chance 0 sheds none")
	var shed := _splinters_since(field, before)[1]
	shed.call(&"apply_gun_work", 1.0)
	assert_true(
		not bool(shed.get(&"_cracked")),
		"the shed body carries A3's S budget: one chip is not enough"
	)
	shed.call(&"apply_gun_work", 1.0)
	assert_true(bool(shed.get(&"_cracked")), "and 2.0 work cracks it")
	print("[S22.5] A6 shed=2 cap_refused=true chance0_none=true")


func test_a6_the_rate_is_the_tuned_chance_and_smalls_shed_none() -> void:
	OreTuningScript.splinter_chance = 0.25
	var field := _solo_field()
	var shed := 0
	for index in SPLINTER_ROLLS:
		var rock := _member(field, AsteroidScript.SIZE_LARGE, T1_WORK_UNITS, "Rate%d" % index)
		var before := _live_ids(field)
		rock.call(&"apply_gun_work", 0.5)
		if not _splinters_since(field, before).is_empty():
			shed += 1
	var rate := float(shed) / float(SPLINTER_ROLLS)
	assert_true(
		absf(rate - OreTuningScript.splinter_chance) <= SPLINTER_TOLERANCE,
		"the shed rate %.3f tracks the tuned %.2f" % [rate, OreTuningScript.splinter_chance]
	)
	OreTuningScript.splinter_chance = 1.0
	for size_class: int in [0, 1]:
		var small := _member(field, size_class, T1_WORK_UNITS, "No%d" % size_class)
		var before := _live_ids(field)
		small.call(&"apply_gun_work", 0.5)
		assert_eq(
			_splinters_since(field, before).size(), 0,
			"a class-%d rock sheds none" % size_class
		)
	var crack_me := _member(field, AsteroidScript.SIZE_LARGE, 2, "CrackMe")
	var before_crack := _live_ids(field)
	crack_me.call(&"apply_gun_work", 100.0)
	var kids := _new_since(field, before_crack)
	assert_true(kids.size() >= 1, "a cracking hit spawns the normal split set")
	for kid: Node2D in kids:
		assert_true(
			not String(kid.name).begins_with(SPLINTER_PREFIX),
			"and no splinter rides along with it"
		)
	print("[S22.5] A6 rate=%.3f S_M_shed=0 crack_set=%d" % [rate, kids.size()])


## ---------------------------------------------------------------------------
## A7 - no ore minted, the sealed constants unmoved
## ---------------------------------------------------------------------------


func test_a7_no_ore_is_minted_and_the_sealed_constants_are_pinned() -> void:
	assert_true(is_equal_approx(OreTuningScript.work_per_unit, 1.0), "work_per_unit is 1.0")
	assert_true(is_equal_approx(OreTuningScript.gun_chip_rate, 0.10), "gun_chip_rate is 0.10")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, 0.25),
		"FRAGMENT_CORE_SHARE is 0.25")
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10), "GUN_BURST_SHARE is 0.10")
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_SPLIT_MIX), "the split table is pinned")
	assert_eq(str(OreTuningScript.spawn_size_weights), str(PINNED_SIZE_WEIGHTS),
		"the spawn mix is pinned")
	assert_eq(str(OreTuningScript.tier_base_yield), str(PINNED_TIER_YIELD),
		"the tier curve is pinned")
	assert_true(is_equal_approx(OreTuningScript.yield_variance_min, 0.5),
		"the variance floor is pinned")
	assert_true(is_equal_approx(OreTuningScript.yield_variance_max, 1.5),
		"the variance ceiling is pinned")
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var bore := float(root.call(&"bore_ore"))
	var steps := 0
	while not (field.call(&"rocks") as Array).is_empty() and steps < MAX_STEPS:
		_gun_deplete((field.call(&"rocks") as Array)[0])
		steps += 1
	var paid := _pickup_units(field)
	var bound := OreTuningScript.gun_burst_share * bore + 1.0
	assert_true(
		float(paid) <= bound,
		"a fully shot family realises %d <= GUN_BURST_SHARE x %.1f = %.3f + 1" % [paid, bore, bound]
	)
	assert_true(steps < MAX_STEPS, "the shot chain terminated (%d steps)" % steps)
	print("[S22.5] A7 bore=%.1f realised=%d bound=%.3f steps=%d" % [bore, paid, bound, steps])


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _field(seed_value: int) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": FIELD_ROCKS,
		&"seed": seed_value,
	})
	_fields.append(field)
	return field


## A field with its own generation rocks freed, so only the fixtures a case builds
## remain. The generation rolls still ran, so the field RNG's later draws (splinters,
## splits, toughnesses) are seeded exactly as any other suite's.
func _solo_field(seed_value: int = FIELD_SEED) -> Node2D:
	var field := _field(seed_value)
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		rock.free()
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


## A 0-ore, marked fragment as a gun shatter builds one (units 0, bore 0, debris).
func _fragment(field: Node2D, size_class: int, node_name: String) -> Node2D:
	var rock := _member(field, size_class, 0, node_name)
	rock.call(&"mark_cleave_child")
	return rock


## A direct fixture with an explicit class, unit count, bore and toughness roll - the
## seam `setup` gained for S22.5 (02 §5.3 A1), so a case can pin the mean roll.
func _tough_rock(size_class: int, units: int, toughness: float) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, units, size_class, false, float(units), toughness)
	_loose.append(rock)
	return rock


## The mean of the ticked band (02 §5.3's 1.2x).
func _mean_toughness() -> float:
	return (OreTuningScript.toughness_min + OreTuningScript.toughness_max) / 2.0


## The simulated `w_laser` 30 dps hold: one chip per `LASER_STEP`, summed until the
## rock's own `cracked` emission. 02 §5.3's times are these sums.
func _laser_time(rock: Node2D) -> float:
	var cracks: Array[int] = []
	rock.connect(&"cracked", func() -> void: cracks.append(1))
	var elapsed := 0.0
	var chip := LASER_DPS * OreTuningScript.gun_chip_rate * LASER_STEP
	while cracks.is_empty() and elapsed < 120.0:
		rock.call(&"apply_gun_work", chip)
		elapsed += LASER_STEP
	return elapsed


## The gun door to a crack in one call: the rock's own work total carried through its
## divisor (an ore-bearing rock), or A3's raw budget (a 0-ore one).
func _gun_deplete(rock: Node2D) -> void:
	var units := float(int(rock.get(&"yield_units")))
	var amount := units
	if units <= 0.0:
		amount = float(OreTuningScript.fragment_work.get(int(rock.call(&"size_class")), 0.0))
	else:
		amount = units * float(OreTuningScript.size_toughness_mult.get(
			int(rock.call(&"size_class")), 1.0)) * float(rock.call(&"toughness"))
	rock.call(&"apply_gun_work", amount + AsteroidScript.WORK_EPSILON)


func _toughnesses(field: Node2D) -> Array[float]:
	var out: Array[float] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		out.append(float(rock.call(&"toughness")))
	return out


func _live_ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		out.append(rock.get_instance_id())
	return out


func _new_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


func _splinters_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _new_since(field, before):
		if String(rock.name).begins_with(SPLINTER_PREFIX):
			out.append(rock)
	return out


## The pickups a shatter left on the field (a detached field parents them to itself).
func _pickup_units(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total
