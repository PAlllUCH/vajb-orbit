@tool
extends McpTestSuite
## Suite s13_caps: S13's owner-ticked rules (01 §5.6, 02 §5.1 Rule A, ruled
## 2026-09-25) - the setup split, the shatter attribution, the reserve rules and
## the anti-drift tie between `OreTuning` and the owner files' consts.
##
## AC6 (anti-drift) is asserted field by field at the top. AC1 (a gun-attributed
## shatter realises at most `GUN_BURST_SHARE x _bore_ore`) and AC2 (a fully mined
## family realises at most the root `_bore_ore`, ~1.0x) are measured on a seeded
## T1 field through the same doors the S12 probes measure: `apply_work` is the
## mining leg, `apply_gun_work` the gun leg, and a shatter's pickups are the
## field's own `pickup`-group children.
##
## Every roll these cases take is seeded, so each number is reproducible. The
## suites run synchronously (no frame awaited), and a detached field spawns its
## own pickups as children, so every reading is reachable without a tree.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const MineralScript := preload("res://game/mineral_catalog.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 12061
const FIELD_ROCKS := 6
const MAX_STEPS := 200000
const PICKUP_GROUP: StringName = &"pickup"

var _fields: Array[Node] = []


func suite_name() -> String:
	return "s13_caps"


func teardown() -> void:
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	_fields.clear()
	## A test that tuned the surface must not leak into the next suite.
	OreTuningScript.reset_to_defaults()


## ---------------------------------------------------------------------------
## AC6 - anti-drift
## ---------------------------------------------------------------------------


func test_ore_tuning_defaults_are_the_owner_files_consts() -> void:
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10),
		"GUN_BURST_SHARE default is the owner's 0.10")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, 0.25),
		"FRAGMENT_CORE_SHARE default is the owner's 0.25")
	assert_true(is_equal_approx(OreTuningScript.gun_chip_rate, WeaponsScript.GUN_CHIP_RATE),
		"the chip rate default is weapons.gd's const")
	assert_true(is_equal_approx(OreTuningScript.mine_cycle, MiningLaserScript.MINE_CYCLE),
		"the cycle default is mining_laser.gd's const")
	assert_true(is_equal_approx(OreTuningScript.work_per_unit, AsteroidScript.WORK_PER_UNIT),
		"the work-per-unit default is asteroid.gd's const")
	assert_eq(str(OreTuningScript.tier_base_yield), str(MineralScript.TIER_BASE_YIELD),
		"the tier curve default is mineral_catalog.gd's const")
	assert_true(is_equal_approx(OreTuningScript.yield_variance_min, MineralScript.YIELD_VARIANCE_MIN),
		"the variance floor is mineral_catalog.gd's const")
	assert_true(is_equal_approx(OreTuningScript.yield_variance_max, MineralScript.YIELD_VARIANCE_MAX),
		"the variance ceiling is mineral_catalog.gd's const")
	assert_eq(OreTuningScript.pickup_burst, AsteroidScript.PICKUP_BURST,
		"the burst default is asteroid.gd's const")


func test_reset_and_the_dict_round_trip_restore_the_defaults() -> void:
	var snapshot := OreTuningScript.to_dict()
	OreTuningScript.from_dict({
		&"gun_burst_share": 0.42,
		&"fragment_core_share": 0.75,
		&"tier_base_yield": {1: 1},
		&"pickup_burst": Vector2i(3, 4),
	})
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.42), "a tuned value lands")
	assert_eq(int(OreTuningScript.tier_base_yield.get(1, 0)), 1, "and so does a table")
	assert_eq(OreTuningScript.pickup_burst, Vector2i(3, 4), "and a burst pair")
	OreTuningScript.reset_to_defaults()
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10), "Reset restores it")
	assert_eq(int(OreTuningScript.tier_base_yield.get(1, 0)), 6, "and the tier curve")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, 0.25), "and the reserve share")
	## A snapshot round-trips (the overlay's Save/Load pair).
	OreTuningScript.from_dict(snapshot)
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.10),
		"the taken snapshot round-trips to the defaults")


## ---------------------------------------------------------------------------
## Rule 2 - the setup split
## ---------------------------------------------------------------------------


func test_setup_splits_the_bore_into_extractable_and_reserve() -> void:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, 5, AsteroidScript.SIZE_MEDIUM, false, 7.0)
	assert_eq(rock.yield_units, 5, "extraction gets the extractable 5")
	assert_true(is_equal_approx(float(rock.call(&"bore_ore")), 7.0),
		"the rock's own original yield is the bore")
	assert_true(is_equal_approx(float(rock.call(&"reserve_units")), 2.0),
		"the reserve is FRAGMENT_CORE_SHARE x the bore")
	## Extraction realises only the extractable: 100 work cannot reach the reserve,
	## and the rock cracks when the extractable is gone.
	assert_eq(int(rock.call(&"apply_work", 100.0)), 5, "all five extractable units")
	assert_true(bool(rock.call(&"is_depleted")), "the rock cracks on the extractable's end")
	rock.free()


func test_the_split_helpers_read_the_live_share() -> void:
	assert_eq(AsteroidScript.extractable_units(7), 5, "7 bore -> 5 extractable")
	assert_eq(AsteroidScript.reserve_units_of(7), 2, "and a 2-unit reserve")
	assert_eq(AsteroidScript.extractable_units(0), 0, "a bare rock has none")
	## A direct five-argument call derives the bore from its extractable, which is
	## what keeps `test_combat_repair_c5.gd`'s fixture exact.
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, 100, AsteroidScript.SIZE_MEDIUM)
	assert_eq(rock.yield_units, 100, "a direct call keeps its units")
	assert_true(is_equal_approx(float(rock.call(&"reserve_units")), 100.0 / 3.0),
		"and derives the reserve from the share")
	rock.free()


## ---------------------------------------------------------------------------
## Rule 3 - the shatter attribution and the reserve rules
## ---------------------------------------------------------------------------


func test_a_mining_shatter_pays_the_full_reserve_of_a_small() -> void:
	var field := _field()
	var small := _member(field, AsteroidScript.SIZE_SMALL, 4, "MinedSmall")
	var reserve := float(small.call(&"reserve_units"))
	assert_true(reserve >= 1.0, "the fixture's reserve crosses a whole unit")
	var before := _pickup_units(field)
	## Mining work delivers the final unit, so the shatter is mining-attributed.
	small.call(&"apply_work", float(int(small.get(&"yield_units"))))
	var paid := _pickup_units(field) - before
	assert_true(paid >= 1, "a mining Small pays its reserve, got %d" % paid)
	assert_true(float(paid) <= reserve + 1.0,
		"and no more than the reserve (%.3f), got %d" % [reserve, paid])


func test_a_gun_shatter_pays_at_most_the_capped_share() -> void:
	var field := _field()
	var rock := _member(field, AsteroidScript.SIZE_LARGE, 30, "ShotRock")
	var bore := float(rock.call(&"bore_ore"))
	var reserve := float(rock.call(&"reserve_units"))
	var chip := WeaponsScript.shot_damage(WeaponsScript.weapon_id(&"w_cannon")) \
		* OreTuningScript.gun_chip_rate
	var steps := 0
	while not bool(rock.call(&"is_depleted")) and steps < MAX_STEPS:
		rock.call(&"apply_gun_work", chip)
		steps += 1
	var owed := minf(reserve, OreTuningScript.gun_burst_share * bore)
	var paid := _pickup_units(field)
	assert_true(float(paid) <= owed + 1.0,
		"a gun shatter pays at most the cap (%.3f), realised %d" % [owed, paid])
	assert_true(owed < reserve, "the fixture exercises the cap, not the reserve")


## S14 (02 §5.2) moves only this row's count: a Medium's child set is now the rolled
## `S 1-3`, so "still leaves fragments" is `>= 1` rather than the retired fixed 2-5
## pair. The conservation rows are untouched: the reserve is split across whatever
## child set was rolled, and a gun's children still carry no ore. S22.5 (02 §5.3 A2)
## moves only the call's amount: the gun door divides by the rock's own
## `size_toughness_mult x toughness`, so the one-call crack carries that divisor and
## the claims below stand.
func test_a_gun_shatter_never_hands_its_fragments_ore() -> void:
	var field := _field()
	var rock := _member(field, AsteroidScript.SIZE_MEDIUM, 12, "DebrisRock")
	var before := _live_ids(field)
	var divisor := float(OreTuningScript.size_toughness_mult.get(
		int(rock.call(&"size_class")), 1.0)) * float(rock.call(&"toughness"))
	rock.call(&"apply_gun_work", (float(int(rock.get(&"yield_units"))) + 1.0) * divisor)
	var children: Array = []
	for node: Node2D in field.call(&"rocks"):
		if not before.has(node.get_instance_id()):
			children.append(node)
	assert_true(children.size() >= 1, "a gun-cracked Medium still leaves fragments")
	for child: Node2D in children:
		assert_true(float(child.call(&"bore_ore")) == 0.0,
			"but the excess reserve burned: a gun's fragments carry no ore")
		child.free()


## ---------------------------------------------------------------------------
## AC1 / AC2 - the field-level invariants
## ---------------------------------------------------------------------------


func test_gun_legs_deliver_at_most_gun_burst_share_of_the_bore() -> void:
	var field := _field()
	var bore := _total_bore(field)
	var delivered := _run_gun_leg(field)
	assert_true(float(delivered) <= OreTuningScript.gun_burst_share * bore + 1.0,
		"gun legs deliver %d <= %.3f (0.10 x %.1f + 1)"
		% [delivered, OreTuningScript.gun_burst_share * bore + 1.0, bore])
	assert_true(float(delivered) < bore * 0.5,
		"shooting stays a lossy route (%d against a %.1f bore)" % [delivered, bore])


func test_a_fully_mined_family_realises_the_root_bore() -> void:
	var field := _field()
	var bore := _total_bore(field)
	var delivered := _run_laser_leg(field)
	## 01 §5.6 invariant 3 / AC2: cleaving redistributes, so the family's whole
	## realisation is the field's own budget - ~1.0x, never S12's measured 4.0x.
	assert_true(float(delivered) <= bore + 1.0,
		"the family realises %d <= the bore %.1f + 1" % [delivered, bore])
	assert_true(float(delivered) >= bore - 1.0,
		"and no less than the bore: no mint, got %d against %.1f" % [delivered, bore])
	## S13-R1's F1: the credit is per cycle. The two rows above prove this family is
	## fully consumed, so the respawn below is a real cycle boundary and must clear
	## whatever a burst capped at `pickup_burst` left behind.
	var leftover := float(field.get(&"_ore_credit"))
	assert_true(bool(field.call(&"respawn")), "a fully consumed field respawns")
	assert_true(is_equal_approx(float(field.get(&"_ore_credit")), 0.0),
		"a respawn clears the cycle's leftover credit (%.3f before)" % leftover)


func test_a_gun_cracked_rock_leaves_the_laser_its_full_budget() -> void:
	## The per-rock row AC1 names: 0.10 x the rock's own bore, and nothing more.
	var field := _field()
	var rock := _member(field, AsteroidScript.SIZE_LARGE, 30, "OwnRock")
	var bore := float(rock.call(&"bore_ore"))
	var chip := WeaponsScript.shot_damage(WeaponsScript.weapon_id(&"w_cannon")) \
		* OreTuningScript.gun_chip_rate
	while not bool(rock.call(&"is_depleted")):
		rock.call(&"apply_gun_work", chip)
	var delivered := float(_pickup_units(field))
	assert_true(delivered <= OreTuningScript.gun_burst_share * bore + 1.0,
		"one gun-cracked rock delivers %.1f against its own %.1f bore" % [delivered, bore])
	field.free()


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _field() -> Node2D:
	## The rock look rolls on the global RNG (asteroid.gd's own note), so the field's
	## size classes are only reproducible if it is seeded before the build.
	seed(FIELD_SEED)
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": FIELD_ROCKS,
		&"seed": FIELD_SEED,
	})
	_fields.append(field)
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


func _live_ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _total_bore(field: Node2D) -> float:
	var bore := 0.0
	for rock: Node2D in field.call(&"rocks"):
		bore += float(rock.call(&"bore_ore"))
	return bore


func _run_laser_leg(field: Node2D) -> int:
	var delivered := 0
	var steps := 0
	while steps < MAX_STEPS:
		var live: Array = field.call(&"rocks")
		if live.is_empty():
			break
		delivered += int(live[0].call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
		steps += 1
	return delivered + _pickup_units(field)


func _run_gun_leg(field: Node2D) -> int:
	var chip := WeaponsScript.shot_damage(WeaponsScript.weapon_id(&"w_cannon")) \
		* OreTuningScript.gun_chip_rate
	var steps := 0
	while steps < MAX_STEPS:
		var live: Array = field.call(&"rocks")
		if live.is_empty():
			break
		live[0].call(&"apply_gun_work", chip)
		steps += 1
	return _pickup_units(field)


func _pickup_units(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total
