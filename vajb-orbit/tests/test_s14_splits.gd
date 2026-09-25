@tool
extends McpTestSuite
## Suite s14_splits: S14's four size classes and the debris splits (02 §5.2, the
## owner's 2026-09-25 ask, S14_BRIEF §2 rules 1-6).
##
##   AC1 - a seeded 200-shatter sample of XL parents: every child is L/M/S, each
##         kind's per-shatter count sits inside its own rolled range, and the set
##         varies rather than being one fixed row;
##   AC2 - the shape of the cascade: M rolls only S, S never splits (its cleave is
##         the pickup burst), L rolls only M and S;
##   AC3 - S13's conservation, re-measured across a mixed chain: a fully mined
##         family realises at most the root's `_bore_ore` + 1 (S13's own yardstick);
##   AC4 - the spawn mix: 1000 seeded rolls on the field's own RNG land within 3
##         percentage points of S 40 / M 32 / L 20 / XL 8;
##   AC5 - an XL draws at 180 u from the row's three XL looks (the L silhouettes);
##   plus AC6's half of the anti-drift tie: `OreTuning`'s two new defaults equal the
##   pinned tables (S14_BRIEF §2 rule 6), through `reset_to_defaults` as well.
##
## Every number the split cases read is seeded: the child rolls come off the field's
## own `rng`, and the *class* of every rock here is pinned through `_new_rock`, so
## no case depends on the global RNG the look roll uses (except AC5, which seeds it
## on purpose). The PINNED_* tables below are a deliberate second copy of the pin -
## an anti-drift yardstick that reads the pin and not the shipped field.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 14061
const FIELD_ROCKS := 6
## AC1's sample: 200 XL shatters, the brief's own count.
const SHATTERS := 200
## AC2's per-rule sample.
const SPLIT_SAMPLE := 40
## AC3's root: its own original yield (`_bore_ore`) and the extractable units that
## bore leaves after `FRAGMENT_CORE_SHARE` is set aside (S13's `extractable_units`).
const ROOT_BORE := 32
const ROOT_UNITS := 24
## AC4's roll count and the pinned shares (02 §5.2's S/M/L/XL row).
const SPAWN_SEED := 14062
const SPAWN_ROLLS := 1000
const PINNED_SHARES: Dictionary = {0: 0.40, 1: 0.32, 2: 0.20, 3: 0.08}
const SHARE_SLACK := 0.03
## AC5: the 180 u target width and the seed the look stream is pinned with.
const XL_WIDTH := 180.0
const XL_LOOK_SEED := 14161
const XL_LOOK_DRAWS := 24
const PICKUP_GROUP: StringName = &"pickup"
const MAX_STEPS := 200000

## S14_BRIEF §2's two tables, the anti-drift yardstick (see the header).
const PINNED_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
const PINNED_WEIGHTS: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}

var _fields: Array[Node] = []


func suite_name() -> String:
	return "s14_splits"


func teardown() -> void:
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	_fields.clear()
	## A case that tuned the surface must not leak into the next suite.
	OreTuningScript.reset_to_defaults()


## ---------------------------------------------------------------------------
## AC1 - the mixed child set of 200 seeded XL shatters
## ---------------------------------------------------------------------------


func test_ac1_two_hundred_xl_shatters_roll_the_mixed_child_set() -> void:
	var field := _field()
	var kinds_total: Dictionary = {0: 0, 1: 0, 2: 0}
	var kinds_low: Dictionary = {0: 99, 1: 99, 2: 99}
	var kinds_high: Dictionary = {0: -1, 1: -1, 2: -1}
	var histogram: Dictionary = {}
	var children_total := 0
	var parents := 0
	for index in SHATTERS:
		var parent := _member(field, AsteroidScript.SIZE_XL, 8, "Xl%d" % index)
		var before := _live_ids(field)
		_deplete(parent)
		var children := _new_since(field, before)
		parents += 1
		children_total += children.size()
		histogram[children.size()] = int(histogram.get(children.size(), 0)) + 1
		var here: Dictionary = {0: 0, 1: 0, 2: 0}
		var wrong_kind := -1
		for child: Node2D in children:
			var kind := int(child.call(&"size_class"))
			if kind < AsteroidScript.SIZE_SMALL or kind >= AsteroidScript.SIZE_XL:
				wrong_kind = kind
			else:
				here[kind] = int(here.get(kind, 0)) + 1
			child.free()
		## Every child of an XL is strictly smaller than it, so no kind outside
		## S/M/L may appear at all.
		assert_eq(wrong_kind, -1, "every child of shatter %d is L, M or S" % index)
		## Per shatter, each kind's count sits inside that kind's own rolled range.
		var inside := true
		var seen_row: Array[String] = []
		for kind: int in [0, 1, 2]:
			var count := int(here[kind])
			var span: Vector2i = PINNED_MIX[AsteroidScript.SIZE_XL][kind]
			if count < span.x or count > span.y:
				inside = false
			kinds_total[kind] = int(kinds_total[kind]) + count
			kinds_low[kind] = mini(int(kinds_low[kind]), count)
			kinds_high[kind] = maxi(int(kinds_high[kind]), count)
			seen_row.append("%d:%d" % [kind, count])
		assert_true(inside,
			"shatter %d's per-kind counts sit inside the rolled ranges (%s)"
			% [index, ", ".join(seen_row)])
	assert_eq(parents, SHATTERS, "the sample cracked every parent it made")
	## The distribution table the report quotes: per-kind shares and the range of
	## each kind's per-shatter count, plus the spread of the total child set.
	var shares: Array[String] = []
	for kind: int in [0, 1, 2]:
		shares.append("size%d min=%d max=%d mean=%.3f" % [
			kind, int(kinds_low[kind]), int(kinds_high[kind]),
			float(kinds_total[kind]) / float(maxi(parents, 1)),
		])
	var totals: Array = histogram.keys()
	totals.sort()
	var spread: Array[String] = []
	for total: int in totals:
		spread.append("%d x%d" % [total, int(histogram[total])])
	print("[S14] AC1 shatters=%d children=%d mean=%.3f | %s | totals {%s}"
		% [parents, children_total, float(children_total) / float(maxi(parents, 1)),
		" | ".join(shares), ", ".join(spread)])
	## Each kind appears in every shatter (`L 1-3`, `M 2-4`, `S 2-5` all have a floor
	## of 1), and the total is not one fixed row.
	assert_eq(int(kinds_low[AsteroidScript.SIZE_LARGE]), 1, "an XL always leaves at least one L")
	assert_eq(int(kinds_low[AsteroidScript.SIZE_MEDIUM]), 2, "an XL always leaves at least two M")
	assert_eq(int(kinds_low[AsteroidScript.SIZE_SMALL]), 2, "an XL always leaves at least two S")
	assert_true(totals.size() >= 2, "the total child set varies (%s)" % [spread])


## ---------------------------------------------------------------------------
## AC2 - the shape of the cascade
## ---------------------------------------------------------------------------


func test_ac2_a_medium_rolls_only_smalls_one_to_three() -> void:
	var field := _field()
	var counts: Array[int] = []
	for index in SPLIT_SAMPLE:
		var before := _live_ids(field)
		_deplete(_member(field, AsteroidScript.SIZE_MEDIUM, 6, "Medium%d" % index))
		var children := _new_since(field, before)
		counts.append(children.size())
		for child: Node2D in children:
			assert_eq(int(child.call(&"size_class")), AsteroidScript.SIZE_SMALL,
				"a Medium's child is a Small")
			child.free()
	var span: Vector2i = PINNED_MIX[AsteroidScript.SIZE_MEDIUM][AsteroidScript.SIZE_SMALL]
	assert_true(counts.min() >= span.x and counts.max() <= span.y,
		"a Medium rolls %d-%d children, got %s" % [span.x, span.y, counts])


func test_ac2_a_small_never_splits() -> void:
	var field := _field()
	var pickups := 0
	for index in SPLIT_SAMPLE:
		var small := _member(field, AsteroidScript.SIZE_SMALL, 4, "Small%d" % index)
		var before := _live_ids(field)
		var owed := float(small.call(&"reserve_units"))
		_deplete(small)
		assert_true(_new_since(field, before).is_empty(),
			"a Small spawns no rock fragments (its cleave is the pickup burst)")
		assert_true(owed >= 1.0, "the fixture's reserve crosses a whole unit")
		pickups += _pickup_units(field)
		_free_pickups(field)
	assert_true(pickups >= SPLIT_SAMPLE, "the Smalls paid their reserve as pickups (%d)" % pickups)


func test_ac2_a_large_rolls_only_mediums_and_smalls() -> void:
	var field := _field()
	for index in SPLIT_SAMPLE:
		var before := _live_ids(field)
		_deplete(_member(field, AsteroidScript.SIZE_LARGE, 6, "Large%d" % index))
		var children := _new_since(field, before)
		var kinds: Dictionary = {}
		for child: Node2D in children:
			var kind := int(child.call(&"size_class"))
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			assert_true(kind == AsteroidScript.SIZE_MEDIUM or kind == AsteroidScript.SIZE_SMALL,
				"a Large's child is an M or an S, got %d" % kind)
			child.free()
		assert_true(kinds.has(AsteroidScript.SIZE_MEDIUM)
				and kinds.has(AsteroidScript.SIZE_SMALL),
			"a Large's mixed set carries both kinds: %s" % str(kinds))


## ---------------------------------------------------------------------------
## AC3 - S13's conservation across the mixed chain
## ---------------------------------------------------------------------------


## A fully mined XL family, measured through the mining door only. The children's
## `_bore_ore` is the parent's reserve split across the whole rolled child set (S13,
## 02 §5.1 Rule A), so the family may realise the root's own bore and no more: the
## +1 is the whole-unit rounding `_unit_shares` carries, exactly S13's yardstick.
func test_ac3_a_fully_mined_family_realises_the_root_bore() -> void:
	var field := _field()
	var root: Node2D = field.call(
		&"_new_rock", "Root", &"iron", 1, ROOT_UNITS, AsteroidScript.SIZE_XL, false,
		float(ROOT_BORE)
	)
	var root_id := root.get_instance_id()
	var bore := float(root.call(&"bore_ore"))
	assert_true(is_equal_approx(bore, float(ROOT_BORE)), "the fixture's bore is its own yield")
	var family: Dictionary = {root_id: true}
	var mined := 0
	var steps := 0
	while steps < MAX_STEPS:
		var live: Array = []
		for rock: Node2D in field.call(&"rocks"):
			if family.has(rock.get_instance_id()):
				live.append(rock)
		if live.is_empty():
			break
		var before := _live_ids(field)
		mined += int(live[0].call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
		for rock: Node2D in _new_since(field, before):
			family[rock.get_instance_id()] = true
		steps += 1
	var delivered := mined + _pickup_units(field)
	print("[S14] AC3 root_bore=%.4f family_realised=%d steps=%d rocks_spawned=%d"
		% [bore, delivered, steps, family.size()])
	assert_true(float(delivered) <= bore + 1.0,
		"the family realises %d <= the root bore %.1f + 1" % [delivered, bore])
	assert_true(float(delivered) >= bore - 1.0,
		"and no less than the bore: no mint, got %d against %.1f" % [delivered, bore])
	assert_true(steps < MAX_STEPS, "the cascade terminated (%d steps)" % steps)


## ---------------------------------------------------------------------------
## AC4 - the spawn mix
## ---------------------------------------------------------------------------


## 1000 rolls of the field's own size roll on a seeded RNG. `_roll_size` is the roll
## itself (a real field only rolls `FIELD_ROCKS_MIN..MAX` times per build), so this is
## the mix the spawn draws from, measured at the size the AC asks for.
func test_ac4_the_spawn_mix_is_within_three_percent_of_the_pinned_row() -> void:
	var field := _field(SPAWN_SEED)
	var rolls: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
	for _roll in SPAWN_ROLLS:
		var size_class := int(field.call(&"_roll_size"))
		assert_true(rolls.has(size_class), "the roll is a size class, got %d" % size_class)
		rolls[size_class] = int(rolls[size_class]) + 1
	var rows: Array[String] = []
	for size_class: int in [0, 1, 2, 3]:
		var share := float(rolls[size_class]) / float(SPAWN_ROLLS)
		var pinned := float(PINNED_SHARES[size_class])
		rows.append("size%d %d (%.3f vs %.2f)" % [size_class, int(rolls[size_class]), share, pinned])
		assert_true(absf(share - pinned) <= SHARE_SLACK,
			"size %d's share is %.4f, pinned %.2f +- %.2f" % [size_class, share, pinned, SHARE_SLACK])
	print("[S14] AC4 rolls=%d %s" % [SPAWN_ROLLS, " | ".join(rows)])
	## The weights themselves are the pinned row, and they are whole-number shares.
	var total := 0
	for weight: Variant in OreTuningScript.spawn_size_weights.values():
		total += int(weight)
	assert_eq(total, 100, "the spawn weights sum to 100")
	assert_eq(str(OreTuningScript.spawn_size_weights), str(PINNED_WEIGHTS),
		"the live spawn weights are the pinned row")


## ---------------------------------------------------------------------------
## AC5 - the XL look row
## ---------------------------------------------------------------------------


## The XL row is three looks at a 180 u target width, reusing the L silhouettes
## (02 §5.2's staging note), and an XL rock draws only inside that row.
func test_ac5_an_xl_draws_at_one_eighty_from_three_looks() -> void:
	var looks_per_size: int = AsteroidScript.LOOKS_PER_SIZE
	assert_eq(looks_per_size, 3, "three silhouettes per size class")
	assert_eq(AsteroidScript.LOOK_TEXTURES.size(), 4 * looks_per_size,
		"four size rows of three looks")
	assert_eq(AsteroidScript.LOOK_WIDTHS.size(), AsteroidScript.LOOK_TEXTURES.size(),
		"one target width per look")
	var first := AsteroidScript.SIZE_XL * looks_per_size
	for row: int in range(first, first + looks_per_size):
		assert_true(is_equal_approx(AsteroidScript.LOOK_WIDTHS[row], XL_WIDTH),
			"XL look %d targets 180 u, got %.1f" % [row, AsteroidScript.LOOK_WIDTHS[row]])
		assert_true(AsteroidScript.LOOK_TEXTURES[row]
				== AsteroidScript.LOOK_TEXTURES[row - looks_per_size],
			"XL look %d reuses the L silhouette (staged art)" % row)
	## The draws themselves: the global RNG the look roll uses is seeded here, so the
	## sampled look set is reproducible run to run.
	seed(XL_LOOK_SEED)
	var field := _field()
	var looks: Dictionary = {}
	for index in XL_LOOK_DRAWS:
		var rock := _member(field, AsteroidScript.SIZE_XL, 4, "Look%d" % index)
		var look := int(rock.call(&"look_index"))
		looks[look] = true
		assert_true(look >= first and look < first + looks_per_size,
			"an XL draws inside the XL row, got look %d" % look)
		var sprite := rock.get_node_or_null(NodePath(AsteroidScript.LOOK_NODE)) as Sprite2D
		assert_true(sprite != null, "the XL rock has its look sprite")
		var width := float(sprite.texture.get_width()) * sprite.scale.x
		assert_true(is_equal_approx(width, XL_WIDTH),
			"the XL sprite measures %.3f u wide, target %.1f" % [width, XL_WIDTH])
		assert_eq(int(rock.call(&"size_class")), AsteroidScript.SIZE_XL,
			"and it reads as the XL class")
	assert_eq(looks.size(), looks_per_size,
		"all three XL looks came up over %d drawn rocks (%s)"
		% [XL_LOOK_DRAWS, str(looks.keys())])


## ---------------------------------------------------------------------------
## The anti-drift tie (AC6's half, S14_BRIEF §2 rule 6)
## ---------------------------------------------------------------------------


## The defaults equal the pinned tables, the keys are the integer size classes
## `asteroid.gd` ships, every child kind is below its parent, and `reset_to_defaults`
## restores both after a tune (the overlay's Reset button is that call).
func test_the_tuning_defaults_are_the_pinned_tables() -> void:
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_MIX),
		"split_mix's default is the pinned table")
	assert_eq(str(OreTuningScript.spawn_size_weights), str(PINNED_WEIGHTS),
		"spawn_size_weights' default is the pinned row")
	for key: Variant in PINNED_WEIGHTS.keys():
		assert_true(int(key) >= AsteroidScript.SIZE_SMALL and int(key) <= AsteroidScript.SIZE_XL,
			"spawn_size_weights is keyed by a size class, got %s" % str(key))
	assert_eq(str(OreTuningScript.split_mix.keys().duplicate()),
		str(PINNED_MIX.keys().duplicate()),
		"the mix is keyed by the four size classes")
	for parent: Variant in PINNED_MIX.keys():
		var row: Dictionary = PINNED_MIX[parent]
		for child: Variant in row.keys():
			assert_true(int(child) < int(parent),
				"child %d is strictly below parent %d" % [int(child), int(parent)])
			var span: Vector2i = row[child]
			assert_true(span.x >= 1 and span.y >= span.x,
				"child %d rolls a positive range, got %s" % [int(child), str(span)])


## Rule 5: the dev overlay's Save/Load pair carries both fields, unknown keys are
## ignored, and a hand-edited (string-keyed) row is normalised rather than dropped.
func test_the_overlay_snapshot_carries_both_fields() -> void:
	var snapshot := OreTuningScript.to_dict()
	assert_has_key(snapshot, "split_mix", "to_dict carries the mix")
	assert_has_key(snapshot, "spawn_size_weights", "to_dict carries the weights")
	OreTuningScript.from_dict({
		&"split_mix": {
			"2": {"1": [2, 2]},
			"1": {"0": Vector2i(1, 1)},
			"0": {},
		},
		&"spawn_size_weights": {"0": 1, "3": 3},
	})
	assert_eq(int(OreTuningScript.spawn_size_weights.get(3, 0)), 3,
		"a string-keyed weight lands as the integer class")
	assert_eq(OreTuningScript.split_mix[2][1], Vector2i(2, 2),
		"a two-element array lands as a count range")
	assert_eq(OreTuningScript.split_mix[2].size(), 1, "a kind absent from the payload is absent")
	OreTuningScript.reset_to_defaults()
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_MIX), "Reset restores the mix")
	assert_eq(str(OreTuningScript.spawn_size_weights), str(PINNED_WEIGHTS),
		"and the spawn weights")
	OreTuningScript.from_dict(snapshot)
	assert_eq(str(OreTuningScript.split_mix), str(PINNED_MIX),
		"the taken snapshot round-trips to the defaults")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A detached, seeded field. The look roll still uses the global RNG (`asteroid.gd`'s
## own note), but every size class this suite reads is pinned through `_new_rock`, so
## the split rolls - the field's own seeded `rng` - are the only stream that matters.
func _field(seed_value: int = FIELD_SEED) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": FIELD_ROCKS,
		&"seed": seed_value,
	})
	_fields.append(field)
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(float(int(rock.get(&"yield_units"))),
		AsteroidScript.WORK_PER_UNIT))


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


func _free_pickups(field: Node2D) -> void:
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			child.free()
