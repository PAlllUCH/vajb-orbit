@tool
extends McpTestSuite
## Suite s16_resplits: S16's debris re-splits (02 §5.2 ter, the owner's 2026-09-25
## ask, S16_BRIEF §2 rules 1-6).
##
##   AC1 - a gun shatter's L/M/S children cleave per their own size class into
##         strictly smaller children, and the chain reaches S and stops;
##   AC2 - every shatter in a shot chain pays 0 units and no pickup spawns from a
##         0-bore fragment (owed 0);
##   AC3 - conservation on both routes: a fully shot family realises at most
##         `GUN_BURST_SHARE x root _bore_ore + 1`; a fully mined family stays at
##         the root `_bore_ore` +- 1 (S14's yardstick, re-derived here);
##   AC4 - a yield-0 ORIGINAL built through the field still cleaves into nothing
##         (ruling 17); a marked 0-bore sibling does split;
##   AC5 - every chain terminates (strictly smaller children) and a fully shot XL
##         leaves no live family rock;
##   AC6 - the anti-drift tie: no shipped tunable moved and the marker is
##         runtime-only (a fresh rock is unmarked, `setup` cannot mark).
##
## Every split roll here comes off the field's own seeded `rng`; every size class
## is pinned through `_new_rock`, so no case depends on the global RNG the look
## roll uses. The PINNED_* tables below are a deliberate second copy of the S14
## pin -- an anti-drift yardstick that reads the pin and not the shipped field.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 16061
## AC3's root: its own original yield (`_bore_ore`) and the extractable units that
## bore leaves after `FRAGMENT_CORE_SHARE` is set aside (a copy of S14's fixture).
const ROOT_BORE := 32
const ROOT_UNITS := 24
const MAX_STEPS := 200000
const PICKUP_GROUP: StringName = &"pickup"

## S14_BRIEF §2's split table, the anti-drift yardstick (02 §5.2).
const PINNED_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
const PINNED_GUN_BURST := 0.10
const PINNED_CORE_SHARE := 0.25

var _fields: Array[Node] = []


func suite_name() -> String:
	return "s16_resplits"


func teardown() -> void:
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	_fields.clear()
	## A case that tuned the surface must not leak into the next suite.
	OreTuningScript.reset_to_defaults()


## ---------------------------------------------------------------------------
## AC1 - shot children cleave per their own class into strictly smaller children
## ---------------------------------------------------------------------------


## Gun-shatter an XL original, then shatter every L/M/S child and every descendant
## with the gun door: each child is strictly smaller than its parent, the mixed set
## carries all three classes, and the cascade reaches S and stops there (an S
## fragment's cleave is the burst, so it leaves no rock).
func test_ac1_shot_children_cleave_per_their_class_into_smaller_children() -> void:
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var before := _live_ids(field)
	_gun_deplete(root)
	var children := _new_since(field, before)
	assert_true(children.size() >= 1, "a shot XL still leaves fragments")
	var kinds: Dictionary = {}
	for child: Node2D in children:
		var kind := int(child.call(&"size_class"))
		assert_true(kind < AsteroidScript.SIZE_XL, "an XL's child is strictly smaller, got %d" % kind)
		kinds[kind] = true
	assert_true(kinds.has(AsteroidScript.SIZE_LARGE)
			and kinds.has(AsteroidScript.SIZE_MEDIUM)
			and kinds.has(AsteroidScript.SIZE_SMALL),
		"the shot XL's mixed set carries L, M and S: %s" % str(kinds.keys()))
	## Walk the whole chain. The frontier is the current generation; every member is
	## shattered and its own children become the next frontier. A generation pass is
	## only entered while a rock remains, so the loop count is the chain depth.
	var frontier: Array = children
	var passes := 0
	var saw_s := kinds.has(AsteroidScript.SIZE_SMALL)
	var shatters := 0
	while not frontier.is_empty() and passes < 8:
		var next: Array = []
		for rock: Node2D in frontier:
			var kind := int(rock.call(&"size_class"))
			var b := _live_ids(field)
			_gun_deplete(rock)
			shatters += 1
			var kids := _new_since(field, b)
			if kind == AsteroidScript.SIZE_SMALL:
				assert_true(kids.is_empty(), "an S fragment stops: its cleave is the burst")
			else:
				assert_true(kids.size() >= 1, "a class-%d fragment re-splits" % kind)
			for kid: Node2D in kids:
				assert_true(int(kid.call(&"size_class")) < kind,
					"class %d's child is strictly smaller, got %d"
					% [kind, int(kid.call(&"size_class"))])
			next.append_array(kids)
		frontier = next
		passes += 1
	assert_true(saw_s, "the chain reached the S class")
	assert_true(passes < 8, "the chain terminated in %d passes" % passes)
	print("[S16] AC1 shatters=%d passes=%d children_of_root=%d"
		% [shatters, passes, children.size()])


## ---------------------------------------------------------------------------
## AC2 - a 0-bore fragment pays nothing at every shatter
## ---------------------------------------------------------------------------


## The only pickup in a shot chain is the root's capped burst; every fragment it
## builds carries bore 0 (the reserve is spent), so each of their shatters owes 0
## and `_pay_burst` returns without spawning anything.
func test_ac2_a_zero_bore_fragment_pays_nothing_at_every_shatter() -> void:
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var root_bore := float(root.call(&"bore_ore"))
	var root_reserve := float(root.call(&"reserve_units"))
	var before := _live_ids(field)
	_gun_deplete(root)
	var cap := OreTuningScript.gun_burst_share * root_bore
	var root_paid := _pickup_units(field)
	assert_true(root_paid >= 1, "the root's capped burst paid (%d)" % root_paid)
	assert_true(float(root_paid) <= minf(root_reserve, cap) + 1.0,
		"and no more than the cap %.3f, got %d" % [minf(root_reserve, cap), root_paid])
	var frontier: Array = _new_since(field, before)
	var shatters := 0
	while not frontier.is_empty() and shatters < MAX_STEPS:
		var next: Array = []
		for rock: Node2D in frontier:
			assert_true(float(rock.call(&"bore_ore")) == 0.0,
				"a gun fragment carries no bore (%.3f)" % float(rock.call(&"bore_ore")))
			var b := _live_ids(field)
			_gun_deplete(rock)
			shatters += 1
			assert_eq(_pickup_units(field), root_paid,
				"shatter %d paid nothing: a 0-bore fragment's owed is 0" % shatters)
			next.append_array(_new_since(field, b))
		frontier = next
	assert_true(shatters >= 1, "the chain had at least one fragment shatter")
	assert_eq(_pickup_units(field), root_paid, "every fragment shatter paid 0")
	print("[S16] AC2 root_paid=%d fragment_shatters=%d total_paid=%d"
		% [root_paid, shatters, _pickup_units(field)])


## ---------------------------------------------------------------------------
## AC3 - conservation on both routes
## ---------------------------------------------------------------------------


## The shot route: shoot every live rock until the field is empty. Only the root's
## capped burst pays, so the family realises at most `GUN_BURST_SHARE x bore + 1`
## and stays well under a half of the bore (shooting never out-earns mining).
func test_ac3_a_fully_shot_family_realises_at_most_the_capped_share() -> void:
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var bore := float(root.call(&"bore_ore"))
	assert_true(is_equal_approx(bore, float(ROOT_BORE)), "the fixture's bore is its own yield")
	var steps := 0
	while steps < MAX_STEPS:
		var live: Array = field.call(&"rocks")
		if live.is_empty():
			break
		_gun_deplete(live[0])
		steps += 1
	var delivered := _pickup_units(field)
	var bound := OreTuningScript.gun_burst_share * bore + 1.0
	assert_true(float(delivered) <= bound,
		"a fully shot family realises %d <= %.3f" % [delivered, bound])
	assert_true(float(delivered) < bore * 0.5,
		"shooting stays a lossy route (%d against a %.1f bore)" % [delivered, bore])
	assert_true(steps < MAX_STEPS, "the shot chain terminated (%d steps)" % steps)
	print("[S16] AC3-gun root_bore=%.1f bound=%.3f realised=%d steps=%d"
		% [bore, bound, delivered, steps])


## The mining route, S14's AC3 fixture re-derived in this suite (S14's own row is
## untouched): a fully mined XL family realises the root's own bore and no more.
## The +1 is the whole-unit rounding `_unit_shares` carries.
func test_ac3_a_fully_mined_family_stays_at_the_root_bore() -> void:
	var field := _solo_field()
	var root: Node2D = field.call(
		&"_new_rock", "Root", &"iron", 1, ROOT_UNITS, AsteroidScript.SIZE_XL, false,
		float(ROOT_BORE)
	)
	var bore := float(root.call(&"bore_ore"))
	assert_true(is_equal_approx(bore, float(ROOT_BORE)), "the fixture's bore is its own yield")
	var family: Dictionary = {root.get_instance_id(): true}
	var mined := 0
	var steps := 0
	while steps < MAX_STEPS:
		var live: Array = []
		for rock: Node2D in field.call(&"rocks"):
			if family.has(rock.get_instance_id()):
				live.append(rock)
		if live.is_empty():
			break
		var b := _live_ids(field)
		mined += int(live[0].call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
		for rock: Node2D in _new_since(field, b):
			family[rock.get_instance_id()] = true
		steps += 1
	var delivered := mined + _pickup_units(field)
	print("[S16] AC3-mine root_bore=%.1f family_realised=%d steps=%d rocks_spawned=%d"
		% [bore, delivered, steps, family.size()])
	assert_true(float(delivered) <= bore + 1.0,
		"the family realises %d <= the root bore %.1f + 1" % [delivered, bore])
	assert_true(float(delivered) >= bore - 1.0,
		"and no less than the bore: no mint, got %d against %.1f" % [delivered, bore])
	assert_true(steps < MAX_STEPS, "the cascade terminated (%d steps)" % steps)


## ---------------------------------------------------------------------------
## AC4 - an unmarked yield-0 original still cleaves into nothing
## ---------------------------------------------------------------------------


## Ruling 17 for originals: a rock built through the field (`_new_rock` -> `setup`)
## with no ore is unmarked, so it cracks and leaves nothing. Its marked twin is the
## S16 half: parentage, not ore, gates a fragment.
func test_ac4_a_yield_zero_original_still_cleaves_into_nothing() -> void:
	var field := _solo_field()
	var bare: Node2D = field.call(&"_new_rock", "Bare", &"iron", 1, 0, AsteroidScript.SIZE_LARGE)
	assert_eq(int(bare.get(&"yield_units")), 0, "the original rolled no ore")
	assert_false(bool(bare.call(&"cleaves")), "and reports that it does not cleave")
	var before := _live_ids(field)
	_deplete(bare)
	assert_eq(_new_since(field, before).size(), 0, "it cleaves into nothing")
	assert_true(_live_ids(field).size() == before.size() - 1, "and it is gone from the field")
	## The contrast: the same yield, but born of a cleave, does split.
	var marked: Node2D = field.call(&"_new_rock", "Marked", &"iron", 1, 0, AsteroidScript.SIZE_MEDIUM)
	marked.call(&"mark_cleave_child")
	assert_true(bool(marked.call(&"cleaves")), "a marked 0-bore rock cleaves whatever its bore")
	var b2 := _live_ids(field)
	_deplete(marked)
	assert_true(_new_since(field, b2).size() >= 1, "so it splits into children")
	print("[S16] AC4 bare_cleaves=false marked_cleaves=true")


## ---------------------------------------------------------------------------
## AC5 - every chain terminates; a fully shot XL leaves no live family rock
## ---------------------------------------------------------------------------


## Walk the whole shot family one generation at a time; the pass count is bounded by
## the four size classes (an XL -> L/M/S -> M/S -> S -> nothing), so the chain
## terminates, and when the frontier empties no family rock is live in the field.
func test_ac5_every_chain_terminates_and_a_shot_xl_leaves_nothing() -> void:
	var field := _solo_field()
	var root := _member(field, AsteroidScript.SIZE_XL, ROOT_UNITS, "Root")
	var family: Dictionary = {root.get_instance_id(): true}
	var passes := 0
	while passes < MAX_STEPS:
		var live: Array = []
		for rock: Node2D in field.call(&"rocks"):
			if family.has(rock.get_instance_id()):
				live.append(rock)
		if live.is_empty():
			break
		for rock: Node2D in live:
			var kind := int(rock.call(&"size_class"))
			var b := _live_ids(field)
			_gun_deplete(rock)
			for kid: Node2D in _new_since(field, b):
				assert_true(int(kid.call(&"size_class")) < kind, "children stay strictly smaller")
				family[kid.get_instance_id()] = true
		passes += 1
	assert_true(passes < MAX_STEPS, "the chain terminated (%d passes)" % passes)
	assert_true(passes <= 4, "at most XL -> L/M/S -> M/S -> S -> nil, got %d passes" % passes)
	for rock: Node2D in field.call(&"rocks"):
		assert_false(family.has(rock.get_instance_id()), "no family rock survives the shot XL")
	assert_eq(field.call(&"rocks").size(), 0, "the fully shot field is empty")
	print("[S16] AC5 passes=%d family_rocks=%d live_after=0"
		% [passes, family.size()])


## ---------------------------------------------------------------------------
## AC6 - the anti-drift tie
## ---------------------------------------------------------------------------


## S16 moves no shipped number: the two shares and the split table are the pinned
## values. The marker is runtime-only -- a fresh rock is unmarked and `setup` has no
## marker parameter, so no field spawn, POI roll or fixture can be born marked.
func test_ac6_no_shipped_tunable_moved_and_the_marker_is_runtime_only() -> void:
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, PINNED_GUN_BURST),
		"GUN_BURST_SHARE is still 0.10")
	assert_true(is_equal_approx(OreTuningScript.fragment_core_share, PINNED_CORE_SHARE),
		"FRAGMENT_CORE_SHARE is still 0.25")
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_MIX),
		"split_mix is the pinned S14 table")
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, 0)
	assert_false(bool(rock.get(&"_cleave_child")), "a fresh, set-up rock is unmarked")
	assert_false(bool(rock.call(&"cleaves")), "and a 0-bore original does not cleave")
	rock.call(&"mark_cleave_child")
	assert_true(bool(rock.get(&"_cleave_child")), "the marker flips the flag")
	assert_true(bool(rock.call(&"cleaves")), "and the rock then cleaves")
	rock.free()
	print("[S16] AC6 gun_share=%.2f core_share=%.2f mix_pinned=true marker_runtime_only=true"
		% [OreTuningScript.gun_burst_share, OreTuningScript.fragment_core_share])


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A detached, seeded field with its own generation rocks freed, so the only live
## rocks a case sees are the ones it builds. The look roll still uses the global
## RNG, but every size class here is pinned through `_new_rock`, so the split rolls
## -- the field's own seeded `rng` -- are the only stream that matters.
func _field(seed_value: int = FIELD_SEED) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": 6,
		&"seed": seed_value,
	})
	_fields.append(field)
	return field


func _solo_field(seed_value: int = FIELD_SEED) -> Node2D:
	var field := _field(seed_value)
	for rock: Node2D in field.call(&"rocks"):
		rock.free()
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


## The mining door: deplete the rock in one call (`apply_work` is mining-attributed).
## S22.5 (02 §5.3 A3): a rock with no ore cracks at `fragment_work[class]`, so the
## 0-unit fixtures are handed that budget rather than WORK_PER_UNIT's single point.
func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(_work_budget(rock), AsteroidScript.WORK_PER_UNIT))


## The gun door: deplete the rock in one call (`apply_gun_work` is gun-attributed).
## S22.5 (02 §5.3 A2): the door divides an ore-bearing rock's work by its own
## `size_toughness_mult[class] x toughness`, so the call carries that divisor; a rock
## with no ore keeps the raw A3 budget (02 §5.3 A3).
func _gun_deplete(rock: Node2D) -> void:
	var units := float(int(rock.get(&"yield_units")))
	if units <= 0.0:
		rock.call(&"apply_gun_work", maxf(_work_budget(rock), AsteroidScript.WORK_PER_UNIT))
		return
	var class_mult := float(OreTuningScript.size_toughness_mult.get(
		int(rock.call(&"size_class")), 1.0))
	rock.call(&"apply_gun_work",
		units * class_mult * float(rock.call(&"toughness")) + AsteroidScript.WORK_EPSILON)


## The work a rock needs before its crack: the extractable units' worth for a rock
## that carries ore, A3's `fragment_work[class]` budget for one that does not.
func _work_budget(rock: Node2D) -> float:
	var units := float(int(rock.get(&"yield_units")))
	if units > 0.0:
		return units
	return float(OreTuningScript.fragment_work.get(int(rock.call(&"size_class")), 0.0))


func _live_ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _new_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks"):
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## The pickups a shatter left on the field (a detached field parents them to itself).
func _pickup_units(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total
