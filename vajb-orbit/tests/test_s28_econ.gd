@tool
extends McpTestSuite
## S28 economy suite: the universal cost law's derivation, read off the live
## catalogue rather than off a copy of it.
## Contract: docs/gameplay/01_economy_core.md's 2026-10-08 block (the law and the
## SC table), docs/gameplay/02_minerals.md's 2026-10-08 block (the value table),
## docs/gameplay/04_refinery.md section 8 (the fee) and docs/gameplay/05_exchange.md
## section 10 (the restated pricing examples). Files under test:
## game/mineral_catalog.gd, game/refinery.gd, game/exchange.gd.
##
## Every figure is computed from `MineralCatalog.MINERALS`,
## `Refinery.conversion_fee` and `Exchange.unit_net`, so the suite fails the moment
## a value cell, a fee or a price drifts off the law. The law's own numbers appear
## only as the *expected* side of a comparison (the fee column, the 05 section 10
## rows, the SC model band), never as an input to the arithmetic.
##
## Pure static-function assertions: no profile, no cargo, no market state, so
## nothing here touches user://profile.cfg.

const Catalog := preload("res://game/mineral_catalog.gd")
const Ref := preload("res://game/refinery.gd")
const Ex := preload("res://game/exchange.gd")

const SUITE_ID := "s28_econ"

## 02's 2026-10-08 derivation: tier-mean ore = 22.6 x 2.0^(t-1) CR, the five
## minerals of a tier at these multipliers of that mean (ascending rank).
const TIER_MEAN_ORE_BASE := 22.6
const TIER_MEAN_FACTOR := 2.0
const WITHIN_TIER_MULTIPLIERS: Array[float] = [0.80, 0.88, 0.97, 1.11, 1.24]
const INGOT_ORE_RATIO := 3.6
const MEAN_TOLERANCE := 0.01

## 02's block, tier means as printed (the rounded reading of the ladder).
const TIER_MEAN_ORE: Array[float] = [22.6, 45.2, 90.4, 180.8]
const TIER_MEAN_INGOT: Array[float] = [81.4, 163.0, 326.0, 652.0]

## 04 section 8's fee column, in catalogue order: max(15, ingot x 80 / 1000).
const FEE_COLUMN: Array[int] = [
	15, 15, 15, 15, 15,
	15, 15, 15, 15, 16,
	20, 23, 25, 28, 32,
	41, 45, 50, 57, 64,
]

## 05 section 10's restated table: mineral id -> [1.0, 0.6, 1.6] net unit prices.
const SECTION_10: Dictionary = {
	&"iron": [64, 38, 102],
	&"titanium": [127, 76, 204],
	&"gold": [254, 152, 406],
	&"krilium": [790, 474, 1264],
}

const DEMANDS: Array[float] = [1.0, 0.6, 1.6]

## 01's 2026-10-08 SC table: one good 10-minute session in tier-t space, a
## 40-cargo hull, net of sinks.
const SC: Array[float] = [1100.0, 1500.0, 3000.0, 6000.0]
const SC_TOLERANCE := 0.30

## 11 section 1.1's per-sector tier mix for the belt (sectors 1-3): [T1, T2].
const BELT_MIX: Array[Array] = [[100, 0], [55, 45], [20, 80]]
## 01 section 5.1's hold: a full 40-unit cargo hold is ~13 whole conversions.
const HOLD_UNITS := 40
const ORE_PER_INGOT := 3
## The brief's SC model band for the two hold readings (10 %).
const HOLD_TOLERANCE := 0.10
const BELT_HOLD_TARGET := 1330.0
const T4_HOLD_TARGET := 8000.0


func suite_name() -> String:
	return SUITE_ID


## ---------------------------------------------------- 1. the value-ladder law


## 01's L1 / 02's block: the tier mean doubles per tier, and the shipped table is
## that mean. Both columns are checked, ore and ingot, within 1 %.
func test_tier_means_double_per_tier() -> void:
	for tier: int in [1, 2, 3, 4]:
		var ore_mean := _mean_value(tier, &"ore_value")
		var ingot_mean := _mean_value(tier, &"ingot_value")
		var expected_ore := TIER_MEAN_ORE_BASE * pow(TIER_MEAN_FACTOR, float(tier - 1))
		_near(
			ore_mean,
			expected_ore,
			MEAN_TOLERANCE,
			"T%d ore mean reads 22.6 x 2.0^(t-1) (%.2f vs %.2f)" % [tier, ore_mean, expected_ore]
		)
		_near(
			ore_mean,
			TIER_MEAN_ORE[tier - 1],
			MEAN_TOLERANCE,
			"T%d ore mean matches 02's printed mean" % tier
		)
		_near(
			ingot_mean,
			ore_mean * INGOT_ORE_RATIO,
			MEAN_TOLERANCE,
			"T%d ingot mean is the ore mean at the 3.6 ratio" % tier
		)
		_near(
			ingot_mean,
			TIER_MEAN_INGOT[tier - 1],
			MEAN_TOLERANCE,
			"T%d ingot mean matches 02's printed mean" % tier
		)
		assert_eq(
			Catalog.tier_minerals(tier).size(), 5, "tier %d still holds five minerals" % tier
		)


## 02's shape law: within a tier the five minerals sit at the five multipliers of
## the mean, ascending by rank, so the sorted values reproduce the ladder.
func test_within_tier_shape_is_the_multiplier_ladder() -> void:
	for tier: int in [1, 2, 3, 4]:
		var values := _sorted_values(tier, &"ore_value")
		assert_eq(values.size(), 5, "tier %d has five ore values" % tier)
		for index: int in values.size():
			var expected := _mean_value(tier, &"ore_value") * WITHIN_TIER_MULTIPLIERS[index]
			_near(
				values[index],
				expected,
				MEAN_TOLERANCE,
				"T%d rank %d sits at x%.2f of the mean" % [tier, index + 1, WITHIN_TIER_MULTIPLIERS[index]]
			)


## 02's block: `ingot = round(ore x 3.6)` for T2-T4 (T1's historical rounding
## stands, so it is excluded by design).
func test_ingot_is_three_point_six_ore_above_tier_one() -> void:
	var checked := 0
	for entry: Dictionary in Catalog.MINERALS:
		if int(entry[&"tier"]) == 1:
			continue
		var mineral_id := String(entry[&"id"])
		assert_eq(
			int(entry[&"ingot_value"]),
			roundi(float(int(entry[&"ore_value"])) * INGOT_ORE_RATIO),
			"%s ingot is round(ore x 3.6)" % mineral_id
		)
		checked += 1
	assert_eq(checked, 15, "all fifteen T2-T4 rows carry the ratio")


## 02's block: the board stays monotone across tiers, in both columns.
func test_the_board_is_monotone_across_tiers() -> void:
	for tier: int in [1, 2, 3]:
		var top_ore := _max_value(tier, &"ore_value")
		var next_ore := _min_value(tier + 1, &"ore_value")
		assert_true(
			top_ore <= next_ore,
			"T%d ore top %d <= T%d ore floor %d" % [tier, top_ore, tier + 1, next_ore]
		)
		var top_ingot := _max_value(tier, &"ingot_value")
		var next_ingot := _min_value(tier + 1, &"ingot_value")
		assert_true(
			top_ingot <= next_ingot,
			"T%d ingot top %d <= T%d ingot floor %d" % [tier, top_ingot, tier + 1, next_ingot]
		)


## ------------------------------------------------------------------ 2. the fee


## 04 section 8: `conversion_fee` reproduces the printed column for all twenty
## minerals, and the arithmetic behind each cell is the live ingot value.
func test_the_fee_column_is_the_live_arithmetic() -> void:
	assert_eq(Catalog.MINERALS.size(), FEE_COLUMN.size(), "the column covers all 20 minerals")
	for index: int in Catalog.MINERALS.size():
		var entry: Dictionary = Catalog.MINERALS[index]
		var mineral_id: StringName = entry[&"id"]
		var ingot := int(entry[&"ingot_value"])
		@warning_ignore("integer_division")
		var expected := maxi(Ref.FEE_FLOOR, ingot * Ref.FEE_VALUE_PERMILLE / 1000)
		assert_eq(
			Ref.conversion_fee(mineral_id),
			expected,
			"%s fee is max(15, ingot x 80 / 1000)" % String(mineral_id)
		)
		assert_eq(
			Ref.conversion_fee(mineral_id),
			FEE_COLUMN[index],
			"%s fee matches 04 section 8's column" % String(mineral_id)
		)


## 04 section 8: the floor binds through T1 and T2's four cheap rows, then the
## value share takes over (silver 16 is the first cell above the floor).
func test_the_floor_binds_where_the_law_says() -> void:
	assert_eq(Ref.FEE_FLOOR, 15, "the historical flat is the floor (tick M9)")
	assert_eq(Ref.FEE_VALUE_PERMILLE, 80, "8 % of the ingot the conversion produces")
	assert_eq(Ref.FEE_PER_CONVERSION, Ref.FEE_FLOOR, "the flat name reads the floor, not a copy")
	for mineral_id: StringName in [&"iron", &"copper", &"chromium", &"silicon", &"aluminium"]:
		assert_eq(Ref.conversion_fee(mineral_id), 15, "%s pays the T1 floor" % String(mineral_id))
	for mineral_id: StringName in [&"titanium", &"nickel", &"cobalt", &"tungsten"]:
		assert_eq(Ref.conversion_fee(mineral_id), 15, "%s still pays the floor" % String(mineral_id))
	assert_eq(Ref.conversion_fee(&"silver"), 16, "silver is the first row above the floor")
	assert_eq(Ref.conversion_fee(&"krilium"), 64, "the apex pays 64")
	assert_eq(Ref.conversion_fee(&"unobtainium"), 15, "an unknown mineral floors")


## 04 section 8: the floor is per conversion and binds before the multiplier, so
## `u_refine`'s half is truncated after it ("7, not 7.5").
func test_u_refine_halves_after_the_floor() -> void:
	assert_eq(Ref.fee_for(&"iron", 1), 15, "one list Iron conversion is 15")
	assert_eq(Ref.fee_for(&"iron", 2), 30, "Iron's 30 CR row survives")
	assert_eq(Ref.fee_for(&"iron", 3), 45, "Iron's 45 CR row survives")
	assert_eq(Ref.fee_for(&"iron", 0), 0, "no conversions, no fee")
	assert_eq(Ref.fee_for(&"iron", -2), 0, "a negative count is not a fee")
	assert_eq(Ref.fee_for(&"iron", 1, Ref.REFINE_FEE_MULT), 7, "7 whole credits, not 7.5")
	assert_eq(Ref.fee_for(&"krilium", 1, Ref.REFINE_FEE_MULT), 32, "the apex halves to 32")
	assert_eq(Ref.fee_for(&"gold", 2), 40, "two Gold conversions are 40")
	assert_eq(Ref.fee_for(&"gold", 2, Ref.REFINE_FEE_MULT), 20, "and 20 discounted")
	assert_eq(Ref.fee_for(&"krilium", 3), 192, "three apex conversions are 192")
	assert_eq(Ref.fee_for(&"iron", 1, 0.0), 0, "a zero multiplier is free")


## ------------------------------------------------------------- 3. the exchange


## 05 section 8 / S28's A2: the exchange has one pricing family and nothing else
## restates a price, so every sellable mineral's price is `unit_net` of the live
## baseline at the demand asked for.
func test_the_exchange_restates_no_price() -> void:
	var checked := 0
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry[&"id"]
		var ore_id: StringName = Catalog.ore_id(mineral_id)
		var ingot_id: StringName = Catalog.ingot_id(mineral_id)
		var expected: Dictionary = {ore_id: int(entry[&"ore_value"]), ingot_id: int(entry[&"ingot_value"])}
		for item_id: StringName in [ore_id, ingot_id]:
			assert_eq(
				Ex.baseline_of(item_id),
				int(expected[item_id]),
				"%s baseline reads the catalogue" % String(item_id)
			)
			for demand: float in DEMANDS:
				assert_eq(
					Ex.exchange_price(item_id, demand),
					Ex.unit_net(Ex.baseline_of(item_id), demand),
					"%s routes through unit_net at %.1f" % [String(item_id), demand]
				)
				checked += 1
	assert_eq(checked, 120, "twenty minerals, two items, three demands")


## 05 section 10's restated examples, computed from the live catalogue: iron's row
## is byte-unchanged, the other three restate on 02's new baselines.
func test_section_10_rows_come_out_of_the_live_catalogue() -> void:
	for mineral_id: StringName in SECTION_10:
		var item_id: StringName = Catalog.ingot_id(mineral_id)
		var baseline := Ex.baseline_of(item_id)
		assert_eq(
			baseline,
			int(Catalog.mineral(mineral_id)[&"ingot_value"]),
			"%s's baseline is the live ingot value" % String(mineral_id)
		)
		var expected: Array = SECTION_10[mineral_id]
		for index: int in DEMANDS.size():
			assert_eq(
				Ex.exchange_price(item_id, DEMANDS[index]),
				int(expected[index]),
				"%s at demand %.1f" % [String(item_id), DEMANDS[index]]
			)
	assert_eq(Ex.exchange_price(Catalog.ore_id(&"iron"), 1.0), 18, "raw Iron ore still reads 18")


## ------------------------------------------------------------- 4. the SC model


## 01's block: a full 40-unit hold is 13 conversions, and its reading has to be a
## session of its tier — the belt ~1 330 CR, a T4 hold ~8 000 CR, both within 10 %.
## The reading is the hold's net deposit: the exchange's net unit price at demand
## 1.0 for 13 conversions, less the fee those conversions paid at their tier's mean
## (01's SC is "a 40-cargo hull, net of sinks"). Nothing here is a literal hold
## value: the ingot means, the fees and the prices all come off the live catalogue.
func test_the_hold_reads_as_a_session_of_its_tier() -> void:
	var belt := _hold_reading(_belt_mix_ingot(), _belt_mix_fee())
	var t4 := _hold_reading(_mean_value(4, &"ingot_value"), _mean_fee(4))
	_near(
		belt,
		BELT_HOLD_TARGET,
		HOLD_TOLERANCE,
		"the belt hold reads ~1 330 CR gross (%.0f)" % belt
	)
	_near(t4, T4_HOLD_TARGET, HOLD_TOLERANCE, "a T4 hold reads ~8 000 CR gross (%.0f)" % t4)
	_near(
		belt / SC[0],
		1.0,
		SC_TOLERANCE,
		"the belt hold reads as one S1 session (%.2f x SC(1))" % (belt / SC[0])
	)
	_near(
		t4 / SC[3],
		1.0,
		SC_TOLERANCE,
		"a T4 hold reads as one S7 session (%.2f x SC(4))" % (t4 / SC[3])
	)


## ----------------------------------------------------------------- internals


## The whole conversions a full hold carries (01 section 5.1's model).
func _hold_conversions() -> int:
	@warning_ignore("integer_division")
	return HOLD_UNITS / ORE_PER_INGOT


## One hold's net deposit: the exchange's net unit price at demand 1.0 for every
## whole conversion, less the fee a conversion of that value pays.
func _hold_reading(ingot_value: float, fee_per_conversion: float) -> float:
	var unit := float(Ex.unit_net(roundi(ingot_value), 1.0))
	return float(_hold_conversions()) * (unit - fee_per_conversion)


## The belt's own tier mix (11 section 1.1, sectors 1-3) as weights.
func _belt_weights() -> Array[float]:
	var t1 := 0.0
	var t2 := 0.0
	for row: Array in BELT_MIX:
		t1 += float(row[0])
		t2 += float(row[1])
	var total := t1 + t2
	return [t1 / total, t2 / total]


## The belt's mean ingot value: its two tier means at the belt's own mix.
func _belt_mix_ingot() -> float:
	var weights := _belt_weights()
	return weights[0] * _mean_value(1, &"ingot_value") + weights[1] * _mean_value(2, &"ingot_value")


## The belt's mean conversion fee, the same mix over the two tier mean fees.
func _belt_mix_fee() -> float:
	var weights := _belt_weights()
	return weights[0] * _mean_fee(1) + weights[1] * _mean_fee(2)


## The mean of one tier's value column, live.
func _mean_value(tier: int, key: StringName) -> float:
	var rows := Catalog.tier_minerals(tier)
	var total := 0.0
	for entry: Dictionary in rows:
		total += float(int(entry.get(key, 0)))
	return total / float(rows.size())


## The mean conversion fee of one tier, live.
func _mean_fee(tier: int) -> float:
	var rows := Catalog.tier_minerals(tier)
	var total := 0.0
	for entry: Dictionary in rows:
		total += float(Ref.conversion_fee(entry[&"id"]))
	return total / float(rows.size())


## One tier's value column, ascending (the multiplier ladder's own order).
func _sorted_values(tier: int, key: StringName) -> Array[int]:
	var values: Array[int] = []
	for entry: Dictionary in Catalog.tier_minerals(tier):
		values.append(int(entry.get(key, 0)))
	values.sort()
	return values


func _min_value(tier: int, key: StringName) -> int:
	return _sorted_values(tier, key)[0]


func _max_value(tier: int, key: StringName) -> int:
	var values := _sorted_values(tier, key)
	return values[values.size() - 1]


## Within `tolerance` (a fraction) of `expected`, both sides live.
func _near(actual: float, expected: float, tolerance: float, msg: String) -> void:
	var span := absf(expected) * tolerance
	assert_true(
		absf(actual - expected) <= span,
		"%s (got %.2f, expected %.2f +/- %.0f%%)" % [msg, actual, expected, tolerance * 100.0]
	)
