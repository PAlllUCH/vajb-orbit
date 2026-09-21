@tool
extends McpTestSuite
## Suite engine2_loot: engine slice 2's kill-drop tables (`game/loot_tables.gd`,
## docs/gameplay/06_loot_drops.md §2/§3/§5/§6, 18_engine_spec §4.6 + §6).
##
## The tables are pure data and the API is one roll, so every test here is
## arithmetic: the fixture below is 06 §3 transcribed from the doc a second time
## (the independent copy the fidelity test compares the shipped const against), and
## every statistic is measured over a seeded run - no scene, no autoload, no awaits.
##
## 06 §6 check 1 reads "expected value per hull class equals the sums above (±5 %)".
## "The sums above" are §3's prose hauls, and those prose figures are stale against
## §3's own tables (§3.1's amendment block says so and defers the re-check to the
## wave report). This suite therefore applies the check to the table's own
## arithmetic - the arithmetic the doc's numbers are made of - and the drift against
## the prose is measured and reported in `.agents/gen/slice2_w4_report.md`.

const LootTablesScript := preload("res://game/loot_tables.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")

const KIND_FIGHTER: StringName = &"fighter"
const KIND_SWARMER: StringName = &"swarmer"
const KIND_FREIGHTER: StringName = &"freighter"
const KIND_CORVETTE: StringName = &"corvette"
const KIND_MAW: StringName = &"maw"

## The roll seed for every sampled statistic. Fixed, so a failure is reproducible.
const SAMPLE_SEED := 20260921
const SAMPLE_COUNT := 20000
const MAW_SAMPLE_COUNT := 2000

## 06 §6 check 1's tolerance, verbatim.
const EV_TOLERANCE := 0.05

## 06 §3's table headings: fighter and freighter are Grade I, the corvette Grade II,
## the Maw "the only Grade III source".
const BAND_FIGHTER := 1
const BAND_CORVETTE := 2
const BAND_MAW := 3

## 06 §3's chance columns, summed. Independent lines, so these are the "table's own
## total" the W4 acceptance names - never 1.0 (06 §2.3).
const CHANCE_TOTAL_FIGHTER := 1.70
const CHANCE_TOTAL_FREIGHTER := 1.40
const CHANCE_TOTAL_CORVETTE := 1.35
const CHANCE_TOTAL_MAW := 4.00

## 03 §3's CR values, read through the catalogue rather than restated here; only the
## two countermeasures are catalogued nowhere yet, and they count 0 (see the report).
const COUNTERMEASURES: Array[StringName] = [&"cm_chaff", &"cm_flare"]


func suite_name() -> String:
	return "engine2_loot"


## 06 §3, transcribed from the doc: kind -> {band, lines}, each line
## {item, chance, min, max} in the doc's order.
func _doc_tables() -> Dictionary:
	return {
		KIND_FIGHTER: {
			&"band": BAND_FIGHTER,
			&"lines": [
				{&"item": &"comp_scrap_1", &"chance": 0.55, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_1", &"chance": 0.30, &"min": 1, &"max": 1},
				{&"item": &"comp_pow_1", &"chance": 0.35, &"min": 1, &"max": 2},
				{&"item": &"comp_elec_1", &"chance": 0.20, &"min": 1, &"max": 1},
				{&"item": &"cm_chaff", &"chance": 0.15, &"min": 1, &"max": 1},
				{&"item": &"cm_flare", &"chance": 0.15, &"min": 1, &"max": 1},
			],
		},
		KIND_FREIGHTER: {
			&"band": BAND_FIGHTER,
			&"lines": [
				{&"item": &"comp_scrap_1", &"chance": 0.60, &"min": 2, &"max": 3},
				{&"item": &"comp_mech_1", &"chance": 0.35, &"min": 1, &"max": 1},
				{&"item": &"comp_ore_1", &"chance": 0.30, &"min": 1, &"max": 2},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 0.15, &"min": 40, &"max": 80},
			],
		},
		KIND_CORVETTE: {
			&"band": BAND_CORVETTE,
			&"lines": [
				{&"item": &"comp_scrap_2", &"chance": 0.50, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_2", &"chance": 0.30, &"min": 1, &"max": 1},
				{&"item": &"comp_mech_2", &"chance": 0.25, &"min": 1, &"max": 1},
				{&"item": &"comp_elec_2", &"chance": 0.20, &"min": 1, &"max": 1},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 0.10, &"min": 120, &"max": 250},
			],
		},
		KIND_MAW: {
			&"band": BAND_MAW,
			&"lines": [
				{&"item": &"comp_scrap_3", &"chance": 1.00, &"min": 3, &"max": 5},
				{&"item": &"comp_mech_3", &"chance": 0.75, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_3", &"chance": 0.60, &"min": 1, &"max": 1},
				{&"item": &"comp_elec_3", &"chance": 0.40, &"min": 1, &"max": 1},
				{&"item": &"comp_ore_3", &"chance": 0.25, &"min": 1, &"max": 1},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 1.00, &"min": 800, &"max": 1200},
			],
		},
	}


## The band the fixture gives a kind, shared by the swarmer (18 §5 ruling 24 sends
## the alien swarmer down the fighter weights).
func _doc_lines(kind: StringName) -> Array:
	var table: Dictionary = _doc_tables()
	return (table[kind] as Dictionary)[&"lines"] as Array


## 03 §3's value for an item: 0 for the credit key and for the two countermeasures,
## which no catalogue row covers yet (reported, not guessed - brief ruling four).
func _value_of(item: StringName) -> int:
	if item == LootTablesScript.CREDIT_ITEM:
		return 0
	var entry: Dictionary = ComponentCatalogScript.component(item)
	return int(entry.get(&"value", 0))


## Rolls `count` payloads and aggregates them: units, credits, empty kills, kills
## with two or more paying lines, and the chance sum the sample paid out (each
## paying line is one chance roll, so the total tracks the table's chance column).
func _sample(kind: StringName, count: int) -> Dictionary:
	var units := 0
	var credits := 0
	var empties := 0
	var multi := 0
	var lines_paid := 0
	var samples: Array = []
	for index in count:
		var payload: Array = LootTablesScript.roll(kind, 1, SAMPLE_SEED + index)
		if payload.is_empty():
			empties += 1
		if payload.size() >= 2:
			multi += 1
		lines_paid += payload.size()
		for entry: Dictionary in payload:
			var amount := int(entry[LootTablesScript.KEY_AMOUNT])
			if bool(entry[LootTablesScript.KEY_CACHE]):
				credits += amount
			else:
				units += amount
				credits += amount * _value_of(entry[LootTablesScript.KEY_ITEM])
		if index < 20:
			samples.append(payload)
	return {
		&"units": float(units) / float(count),
		&"credits": float(credits) / float(count),
		&"empty_rate": float(empties) / float(count),
		&"multi_rate": float(multi) / float(count),
		&"lines_paid": float(lines_paid) / float(count),
		&"samples": samples,
	}


## The table's arithmetic expectation: units, catalogue CR, cache CR per kill, and
## the independent-line empty rate. Everything comes out of the doc's own numbers.
func _expected(kind: StringName) -> Dictionary:
	var units := 0.0
	var credits := 0.0
	var lines := 0.0
	var empty := 1.0
	var max_amount := 0
	for line: Dictionary in _doc_lines(kind):
		var chance := float(line[&"chance"])
		var mean := (float(line[&"min"]) + float(line[&"max"])) / 2.0
		var item: StringName = line[&"item"]
		if item == LootTablesScript.CREDIT_ITEM:
			credits += chance * mean
		else:
			units += chance * mean
			credits += chance * mean * float(_value_of(item))
		lines += chance
		empty *= 1.0 - chance
		max_amount = maxi(max_amount, int(line[&"max"]))
	return {
		&"units": units,
		&"credits": credits,
		&"chance_total": lines,
		&"empty_rate": empty,
		&"cache_amount_max": max_amount,
	}


## ---------------------------------------------------------------------------
## The tables are 06 §3, line for line
## ---------------------------------------------------------------------------


func test_every_shipped_table_matches_its_doc_06_transcription() -> void:
	var doc: Dictionary = _doc_tables()
	for kind: StringName in doc:
		assert_true(LootTablesScript.has(kind), "%s is a shipped kind" % kind)
		var shipped: Dictionary = LootTablesScript.TABLES[kind]
		var doc_table: Dictionary = doc[kind]
		assert_eq(int(shipped[&"band"]), int(doc_table[&"band"]), "%s band (06 §3 heading)" % kind)
		var shipped_lines: Array = shipped[&"lines"]
		var doc_lines: Array = doc_table[&"lines"]
		assert_eq(
			shipped_lines.size(), doc_lines.size(), "%s line count (06 §3 table)" % kind
		)
		for index in doc_lines.size():
			var shipped_line: Dictionary = shipped_lines[index]
			var doc_line: Dictionary = doc_lines[index]
			var label := "%s line %d" % [kind, index + 1]
			assert_eq(shipped_line[&"item"], doc_line[&"item"], "%s item" % label)
			assert_eq(
				float(shipped_line[&"chance"]), float(doc_line[&"chance"]), "%s chance" % label
			)
			assert_eq(int(shipped_line[&"min"]), int(doc_line[&"min"]), "%s min" % label)
			assert_eq(int(shipped_line[&"max"]), int(doc_line[&"max"]), "%s max" % label)


func test_swarmer_reuses_the_fighter_weights() -> void:
	assert_eq(int(LootTablesScript.TABLES[KIND_SWARMER][&"band"]), BAND_FIGHTER, "swarmer band")
	assert_true(
		LootTablesScript.TABLES[KIND_SWARMER][&"lines"] == LootTablesScript.FIGHTER_LINES,
		"the swarmer shares the one fighter line array, so the two cannot drift",
	)
	var fighter: Array = LootTablesScript.roll(KIND_FIGHTER, BAND_FIGHTER, SAMPLE_SEED)
	var swarmer: Array = LootTablesScript.roll(KIND_SWARMER, BAND_FIGHTER, SAMPLE_SEED)
	assert_eq(swarmer, fighter, "same seed, same weights, same payload")


## 06 §3.1 + the 2026-09-20 amendment: the two countermeasure rows sit at lines 5 and
## 6 at 0.15 each, and no other 06 table carries a countermeasure.
func test_countermeasure_rows_entered_the_fighter_table_only() -> void:
	var fighter_lines: Array = _doc_lines(KIND_FIGHTER)
	var counter_lines: Array[int] = []
	for index in fighter_lines.size():
		if COUNTERMEASURES.has((fighter_lines[index] as Dictionary)[&"item"]):
			counter_lines.append(index + 1)
	assert_eq(counter_lines, [5, 6] as Array[int], "cm_chaff and cm_flare are lines 5 and 6")
	for index in counter_lines.size():
		var shipped: Dictionary = LootTablesScript.FIGHTER_LINES[counter_lines[index] - 1]
		assert_eq(float(shipped[&"chance"]), 0.15, "countermeasure line chance")
		assert_eq(int(shipped[&"min"]), 1, "countermeasure line min")
		assert_eq(int(shipped[&"max"]), 1, "countermeasure line max")
	for kind: StringName in [KIND_FREIGHTER, KIND_CORVETTE, KIND_MAW]:
		for line: Dictionary in _doc_lines(kind):
			assert_false(
				COUNTERMEASURES.has(line[&"item"]),
				"%s carries no countermeasure row (06 §3.1 amendment: the other tables are untouched)" % kind,
			)


func test_chance_totals_are_the_tables_own_sums_not_one() -> void:
	var totals := {
		KIND_FIGHTER: CHANCE_TOTAL_FIGHTER,
		KIND_SWARMER: CHANCE_TOTAL_FIGHTER,
		KIND_FREIGHTER: CHANCE_TOTAL_FREIGHTER,
		KIND_CORVETTE: CHANCE_TOTAL_CORVETTE,
		KIND_MAW: CHANCE_TOTAL_MAW,
	}
	for kind: StringName in totals:
		var expected := float(totals[kind])
		var doc_sum := 0.0
		for line: Dictionary in _doc_lines(kind if kind != KIND_SWARMER else KIND_FIGHTER):
			doc_sum += float(line[&"chance"])
		assert_true(
			absf(doc_sum - expected) < 0.0001, "%s chance column sums to %f" % [kind, expected]
		)
		var sample: Dictionary = _sample(kind, SAMPLE_COUNT)
		assert_true(
			absf(float(sample[&"lines_paid"]) - expected) < 0.05,
			"%s pays %f lines per kill on average, the table's own total"
			% [kind, float(sample[&"lines_paid"])],
		)


## 06 §2.3: odds are independent per line, so a kill can pay two lines and a kill
## can pay nothing at all.
func test_lines_are_independent_and_an_empty_kill_is_legal() -> void:
	var sample: Dictionary = _sample(KIND_FIGHTER, SAMPLE_COUNT)
	assert_true(float(sample[&"multi_rate"]) > 0.15, "two-line kills happen")
	assert_true(float(sample[&"empty_rate"]) > 0.0, "empty kills happen")
	var expected: Dictionary = _expected(KIND_FIGHTER)
	assert_true(
		absf(float(sample[&"empty_rate"]) - float(expected[&"empty_rate"])) < 0.02,
		"empty-kill rate %f tracks the independent-line product %f"
		% [float(sample[&"empty_rate"]), float(expected[&"empty_rate"])],
	)


## 06 §6 check 1, applied to the tables' arithmetic: measured units and CR per hull
## class within 5 % of the chance x amount x 03 §3 value expectation.
func test_expected_value_per_hull_class_is_within_five_percent() -> void:
	for kind: StringName in [KIND_FIGHTER, KIND_FREIGHTER, KIND_CORVETTE, KIND_MAW]:
		var expected: Dictionary = _expected(kind)
		var measured: Dictionary = _sample(kind, SAMPLE_COUNT)
		assert_true(
			absf(float(measured[&"units"]) - float(expected[&"units"]))
			<= float(expected[&"units"]) * EV_TOLERANCE,
			"%s units %f vs %f expected (06 §6 check 1)"
			% [kind, float(measured[&"units"]), float(expected[&"units"])],
		)
		assert_true(
			absf(float(measured[&"credits"]) - float(expected[&"credits"]))
			<= float(expected[&"credits"]) * EV_TOLERANCE,
			"%s CR %f vs %f expected (06 §6 check 1)"
			% [kind, float(measured[&"credits"]), float(expected[&"credits"])],
		)


## 06 §3.4: "line 1 + line 6 always pay" - the Maw's only guarantee, and the reason
## a Maw kill is a progression event.
func test_maw_guarantees_its_scrap_line_and_its_credit_cache() -> void:
	var scrap_min := 0
	var guaranteed_cache_min := 0
	for line: Dictionary in _doc_lines(KIND_MAW):
		var item: StringName = line[&"item"]
		if float(line[&"chance"]) < 1.0:
			continue
		if item == LootTablesScript.CREDIT_ITEM:
			guaranteed_cache_min = int(line[&"min"])
		else:
			scrap_min = int(line[&"min"])
	assert_true(scrap_min > 0, "the Maw has a guaranteed scrap line")
	assert_eq(guaranteed_cache_min, 800, "the Maw's cache line starts at 800 CR")
	for index in MAW_SAMPLE_COUNT:
		var payload: Array = LootTablesScript.roll(KIND_MAW, BAND_MAW, SAMPLE_SEED + index)
		var items: Array = []
		var cache_present := false
		for entry: Dictionary in payload:
			if bool(entry[LootTablesScript.KEY_CACHE]):
				cache_present = true
			else:
				items.append(entry[LootTablesScript.KEY_ITEM])
		assert_true(items.has(&"comp_scrap_3"), "every Maw kill pays Dreadnought Slag")
		assert_true(cache_present, "every Maw kill pays a credit cache")
		if not items.has(&"comp_scrap_3") or not cache_present:
			return


## 06 §2.4: "credit caches roll last and always spawn as a single distinct pickup",
## and a cache entry is money, never cargo (06 §5). Only the freighter, corvette and
## Maw tables carry a cache line (06 §3.2-§3.4); the fighter table has none.
func test_cache_lines_are_last_and_flagged_as_credit() -> void:
	var expected_caches := {
		KIND_FIGHTER: 0,
		KIND_FREIGHTER: 1,
		KIND_CORVETTE: 1,
		KIND_MAW: 1,
	}
	for kind: StringName in expected_caches:
		var lines: Array = _doc_lines(kind)
		var caches := 0
		for index in lines.size():
			if (lines[index] as Dictionary)[&"item"] == LootTablesScript.CREDIT_ITEM:
				caches += 1
				assert_eq(index, lines.size() - 1, "%s cache line is last" % kind)
		assert_eq(caches, int(expected_caches[kind]), "%s cache line count (06 §3)" % kind)
		var sample: Dictionary = _sample(kind, 200)
		for payload: Array in sample[&"samples"]:
			for index in payload.size():
				if bool(payload[index][LootTablesScript.KEY_CACHE]):
					assert_eq(
						index,
						payload.size() - 1,
						"%s: the cache is the last pickup of the roll" % kind,
					)


## CONTRACTS §5: a roll result is the three `Pickup.setup` arguments, and each
## amount sits inside its line's `randi_range` (06 §2.2).
func test_payloads_are_pickup_setup_arguments_within_their_ranges() -> void:
	for kind: StringName in [KIND_FIGHTER, KIND_FREIGHTER, KIND_CORVETTE, KIND_MAW]:
		var ranges := {}
		for line: Dictionary in _doc_lines(kind if kind != KIND_SWARMER else KIND_FIGHTER):
			ranges[line[&"item"]] = [int(line[&"min"]), int(line[&"max"])]
		var sample: Dictionary = _sample(kind, 200)
		for payload: Array in sample[&"samples"]:
			for entry: Dictionary in payload:
				assert_eq(entry.size(), 3, "%s entry carries exactly the three keys" % kind)
				assert_has_key(entry, String(LootTablesScript.KEY_ITEM), "entry item key")
				assert_has_key(entry, String(LootTablesScript.KEY_AMOUNT), "entry amount key")
				assert_has_key(entry, String(LootTablesScript.KEY_CACHE), "entry cache key")
				var item: StringName = entry[LootTablesScript.KEY_ITEM]
				assert_true(ranges.has(item), "%s rolls only its own items" % kind)
				if not ranges.has(item):
					return
				var bounds: Array = ranges[item]
				assert_true(
					int(entry[LootTablesScript.KEY_AMOUNT]) >= int(bounds[0])
					and int(entry[LootTablesScript.KEY_AMOUNT]) <= int(bounds[1]),
					"%s %s amount inside %s" % [kind, item, bounds],
				)


## 06 §6 check 2: no table references a component grade above its hull band.
func test_grade_caps_hold_against_the_03_catalogue() -> void:
	assert_eq(LootTablesScript.cap_violations(), [] as Array[String], "06 §6 check 2")
	for kind: StringName in LootTablesScript.TABLES:
		var band := int((LootTablesScript.TABLES[kind] as Dictionary)[&"band"])
		for line: Dictionary in LootTablesScript.TABLES[kind][&"lines"]:
			var item: StringName = line[&"item"]
			if item == LootTablesScript.CREDIT_ITEM:
				continue
			assert_true(
				ComponentCatalogScript.component(item).is_empty()
				or int(ComponentCatalogScript.component(item)[&"grade"]) <= band,
				"%s: %s is inside band %d" % [kind, item, band],
			)


## The 03 catalogue gap this wave found: 06 §3.1's countermeasure rows have no 03 §3
## row, so their grade (and so their cap) cannot be proved. Reported, not assumed.
func test_the_only_uncatalogued_items_are_the_two_countermeasures() -> void:
	assert_eq(
		LootTablesScript.uncatalogued_items(),
		COUNTERMEASURES,
		"cm_chaff and cm_flare are the two ids 03 §3 does not carry",
	)
	for item: StringName in COUNTERMEASURES:
		assert_true(
			MineralCatalogScript.is_ore(item) == false, "%s is not a mineral id" % item
		)


## The kind axis is the 06 table name, so an 18 §5 archetype with no 06 table is
## refused rather than guessed (the caller maps archetype -> band).
func test_unknown_kinds_are_not_tables() -> void:
	for kind: StringName in [KIND_FIGHTER, KIND_SWARMER, KIND_FREIGHTER, KIND_CORVETTE, KIND_MAW]:
		assert_true(LootTablesScript.has(kind), "%s is shipped" % kind)
	for kind: StringName in [&"boss", &"hunter", &"patrol", &"turret", &"sibelon", &"apex", &""]:
		assert_false(LootTablesScript.has(kind), "%s has no 06 table" % kind)


## `tier` is the rolling hull's band (06 §7's deferred sector-cache axis): v1 rolls
## the table verbatim at every tier, so a tier can never cost a hull its loot.
func test_tier_does_not_change_the_roll_in_v1() -> void:
	for kind: StringName in [KIND_FIGHTER, KIND_FREIGHTER, KIND_CORVETTE, KIND_MAW]:
		var baseline: Array = LootTablesScript.roll(kind, 1, SAMPLE_SEED)
		for tier: int in [2, 3, 4, 7]:
			assert_eq(
				LootTablesScript.roll(kind, tier, SAMPLE_SEED),
				baseline,
				"%s: tier %d rolls the table verbatim (06 §7: not built in v1)" % [kind, tier],
			)
