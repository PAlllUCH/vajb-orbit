@tool
extends McpTestSuite
## P1 catalogue suite: the 20-mineral and 18-component data tables and their
## static helpers.
## Contract: docs/gameplay/02_minerals.md (sections 1-6), docs/gameplay/03_components.md
## (sections 3-4), docs/gameplay/11_galactic_map.md section 1.1 (which supersedes
## 02 section 5's abstract sector ranges) and docs/gameplay/17_coder_handoff.md
## section 6 (the 02/05 checklist item).
## Files under test: game/mineral_catalog.gd, game/component_catalog.gd.
## Pure data assertions: no profile, no scene, no editor API, no mutation.
## Scripts are preloaded by path on purpose (project convention): the suite must
## not depend on the global class table when it runs headless.

const Catalog := preload("res://game/mineral_catalog.gd")
const Components := preload("res://game/component_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "p1_catalogues"
const LOG_PATH := "user://test_p1_log.txt"

## docs/gameplay/02_minerals.md section 2, verbatim: mineral id -> [ore, ingot].
const MINERAL_VALUES: Dictionary = {
	&"iron": [18, 65],
	&"copper": [22, 80],
	&"chromium": [25, 90],
	&"silicon": [28, 100],
	&"aluminium": [20, 72],
	&"titanium": [45, 162],
	&"nickel": [50, 180],
	&"cobalt": [55, 200],
	&"tungsten": [65, 235],
	&"silver": [70, 252],
	&"gold": [110, 395],
	&"platinum": [130, 470],
	&"neodymium": [150, 540],
	&"iridium": [170, 610],
	&"osmium": [190, 685],
	&"palladium": [300, 1080],
	&"cerulite": [350, 1260],
	&"emberite": [400, 1440],
	&"voidglass": [480, 1730],
	&"krilium": [600, 2160],
}

## docs/gameplay/03_components.md section 3, verbatim: component id -> value.
const COMPONENT_VALUES: Dictionary = {
	&"comp_scrap_1": 12,
	&"comp_scrap_2": 30,
	&"comp_scrap_3": 75,
	&"comp_mech_1": 18,
	&"comp_mech_2": 45,
	&"comp_mech_3": 110,
	&"comp_elec_1": 20,
	&"comp_elec_2": 50,
	&"comp_elec_3": 120,
	&"comp_weap_1": 22,
	&"comp_weap_2": 55,
	&"comp_weap_3": 130,
	&"comp_pow_1": 15,
	&"comp_pow_2": 40,
	&"comp_pow_3": 100,
	&"comp_ore_1": 25,
	&"comp_ore_2": 60,
	&"comp_ore_3": 140,
}

const COMPONENT_FAMILIES: Array[StringName] = [
	&"salvage", &"mech", &"elec", &"weap", &"pow", &"ore_grade",
]

## docs/gameplay/11_galactic_map.md section 1.1, verbatim: sector -> tier -> weight.
const SECTOR_MIX: Dictionary = {
	1: {1: 100},
	2: {1: 55, 2: 45},
	3: {1: 20, 2: 80},
	4: {2: 60, 3: 40},
	5: {2: 35, 3: 65},
	6: {3: 55, 4: 45},
	7: {3: 40, 4: 60},
}

## docs/gameplay/02_minerals.md section 5, verbatim.
const TIER_YIELDS: Dictionary = {1: 6, 2: 5, 3: 4, 4: 3}


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	Log.log_path = LOG_PATH
	_delete_files()


func setup() -> void:
	_delete_files()


func suite_teardown() -> void:
	_delete_files()
	Log.log_path = Log.DEFAULT_PATH


func _delete_files() -> void:
	if FileAccess.file_exists(LOG_PATH):
		var dir := DirAccess.open(LOG_PATH.get_base_dir())
		if dir != null:
			dir.remove(LOG_PATH.get_file())


# ----- minerals (02) -----


func test_mineral_catalogue_shape() -> void:
	assert_eq(Catalog.MINERALS.size(), 20, "20 minerals")
	assert_eq(Catalog.mineral_ids().size(), 20, "20 distinct mineral ids")
	for tier: int in [1, 2, 3, 4]:
		assert_eq(Catalog.tier_minerals(tier).size(), 5, "tier %d holds five minerals" % tier)
	var seen: Dictionary = {}
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry.get(&"id", &"")
		assert_ne(mineral_id, &"", "every mineral carries an id")
		assert_false(seen.has(mineral_id), "duplicate mineral id %s" % String(mineral_id))
		seen[mineral_id] = true
	assert_eq(seen.size(), 20, "four tiers of five, no overlap")


func test_mineral_values_match_docs() -> void:
	assert_eq(MINERAL_VALUES.size(), 20, "the table covers all 20 minerals")
	for mineral_id: StringName in MINERAL_VALUES:
		var entry := Catalog.mineral(mineral_id)
		assert_false(entry.is_empty(), "missing mineral %s" % String(mineral_id))
		var expected: Array = MINERAL_VALUES[mineral_id]
		assert_eq(
			int(entry.get(&"ore_value", -1)), int(expected[0]), "%s ore_value" % String(mineral_id)
		)
		assert_eq(
			int(entry.get(&"ingot_value", -1)), int(expected[1]), "%s ingot_value" % String(mineral_id)
		)


func test_mineral_units_are_one() -> void:
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: String = String(entry.get(&"id", &""))
		assert_eq(int(entry.get(&"ore_units", 0)), 1, "%s ore_units" % mineral_id)
		assert_eq(int(entry.get(&"ingot_units", 0)), 1, "%s ingot_units" % mineral_id)


## ICONS_SPEC §8.1: one dedicated 48 px glyph per mineral and per ingot, on disk and
## referenced by the catalogue, with 02 §6's shared fallback retired. The component icons
## keep the generic art of 03 §4.1, so nothing here asserts them.
func test_mineral_icons_are_the_dedicated_glyphs() -> void:
	var checked := 0
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id := String(entry.get(&"id", &""))
		assert_ne(mineral_id, "", "every mineral carries an id")
		var ore := String(entry.get(&"icon_ore", ""))
		var ingot := String(entry.get(&"icon_ingot", ""))
		assert_eq(
			ore,
			"res://assets/icons/mineral/icon_mineral_%s.svg" % mineral_id,
			"%s icon_ore" % mineral_id
		)
		assert_eq(
			ingot,
			"res://assets/icons/ingot/icon_ingot_%s.svg" % mineral_id,
			"%s icon_ingot" % mineral_id
		)
		assert_true(ResourceLoader.exists(ore), "%s is missing on disk" % ore)
		assert_true(ResourceLoader.exists(ingot), "%s is missing on disk" % ingot)
		checked += 2
	assert_eq(checked, 40, "20 ore plus 20 ingot glyphs")


func test_item_id_derivation_and_policy() -> void:
	assert_eq(Catalog.ore_id(&"iron"), &"mineral_iron", "ore id form")
	assert_eq(Catalog.ingot_id(&"gold"), &"ingot_gold", "ingot id form")
	assert_eq(Catalog.ore_id(&"unobtainium"), &"", "unknown mineral has no ore id")
	assert_eq(Catalog.ingot_id(&"unobtainium"), &"", "unknown mineral has no ingot id")
	for mineral_id: StringName in Catalog.mineral_ids():
		var ore: StringName = Catalog.ore_id(mineral_id)
		var ingot: StringName = Catalog.ingot_id(mineral_id)
		assert_eq(Catalog.mineral_id_of_item(ore), mineral_id, "%s round trip" % String(ore))
		assert_eq(Catalog.mineral_id_of_item(ingot), mineral_id, "%s round trip" % String(ingot))
		assert_eq(Catalog.entry_for_item(ore).get(&"id", &""), mineral_id, "%s entry" % String(ore))
		assert_eq(Catalog.entry_for_item(ingot).get(&"id", &""), mineral_id, "%s entry" % String(ingot))
		assert_true(Catalog.is_ore(ore), "%s is ore" % String(ore))
		assert_false(Catalog.is_ingot(ore), "%s is not an ingot" % String(ore))
		assert_true(Catalog.is_ingot(ingot), "%s is an ingot" % String(ingot))
		assert_false(Catalog.is_ore(ingot), "%s is not ore" % String(ingot))
		assert_false(Catalog.is_ore(mineral_id), "bare id %s is neither" % String(mineral_id))
		assert_false(Catalog.is_ingot(mineral_id), "bare id %s is neither" % String(mineral_id))
	assert_eq(Catalog.mineral_id_of_item(&"mineral_bogus"), &"", "unknown ore id")
	assert_eq(Catalog.mineral_id_of_item(&"ingot_bogus"), &"", "unknown ingot id")
	assert_eq(Catalog.mineral_id_of_item(&"comp_scrap_1"), &"", "components are not minerals")
	assert_eq(Catalog.mineral_id_of_item(&""), &"", "empty id resolves to nothing")
	assert_false(Catalog.is_ore(&"comp_scrap_1"), "a component is not ore")
	assert_false(Catalog.is_ingot(&"comp_scrap_1"), "a component is not an ingot")


func test_sector_tier_mix_matches_map() -> void:
	for sector: int in SECTOR_MIX:
		var mix := Catalog.sector_mix(sector)
		var expected: Dictionary = SECTOR_MIX[sector]
		assert_eq(mix.size(), expected.size(), "sector %d tier count" % sector)
		for tier: int in expected:
			assert_eq(
				int(mix.get(tier, 0)),
				int(expected[tier]),
				"sector %d tier %d weight" % [sector, tier]
			)
	assert_eq(Catalog.sector_mix(0), {}, "no mix outside 1..7")
	assert_eq(Catalog.sector_mix(8), {}, "no mix outside 1..7")


func test_tier_base_yield_and_variance() -> void:
	assert_eq(Catalog.TIER_BASE_YIELD.size(), 4, "four tiers of richness")
	for tier: int in TIER_YIELDS:
		assert_eq(
			int(Catalog.TIER_BASE_YIELD.get(tier, 0)),
			int(TIER_YIELDS[tier]),
			"tier %d base yield" % tier
		)
	assert_eq(Catalog.YIELD_VARIANCE_MIN, 0.5, "variance floor")
	assert_eq(Catalog.YIELD_VARIANCE_MAX, 1.5, "variance ceiling")


func test_seeded_rolls_are_tier_scoped() -> void:
	var single := RandomNumberGenerator.new()
	single.seed = 20250918
	for _i: int in 100:
		assert_eq(Catalog.roll_tier(1, single), 1, "sector 1 rolls tier 1 only")
	var mixed := RandomNumberGenerator.new()
	mixed.seed = 4242
	for _i: int in 100:
		var tier: int = Catalog.roll_tier(6, mixed)
		assert_true(tier == 3 or tier == 4, "sector 6 rolls tier 3 or 4 only")
	for tier: int in TIER_YIELDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + tier
		var base: int = int(TIER_YIELDS[tier])
		for _i: int in 50:
			var amount: int = Catalog.roll_yield(tier, rng)
			assert_gt(amount, 0, "tier %d yield is never empty" % tier)
			assert_true(
				amount >= roundi(base * Catalog.YIELD_VARIANCE_MIN),
				"tier %d yield floor" % tier
			)
			assert_true(
				amount <= roundi(base * Catalog.YIELD_VARIANCE_MAX),
				"tier %d yield ceiling" % tier
			)
		var picked := Catalog.roll_mineral(tier, rng)
		assert_eq(int(picked.get(&"tier", 0)), tier, "roll_mineral(%d) stays in tier" % tier)
	var nowhere := RandomNumberGenerator.new()
	nowhere.seed = 1
	assert_eq(Catalog.roll_tier(0, nowhere), 0, "an unknown sector has no tier")
	assert_eq(Catalog.roll_mineral(9, nowhere), {}, "an unknown tier has no mineral")
	var first := RandomNumberGenerator.new()
	first.seed = 7
	var second := RandomNumberGenerator.new()
	second.seed = 7
	for _i: int in 10:
		assert_eq(first.randi_range(1, 1000), second.randi_range(1, 1000), "same seed, same roll")


# ----- components (03) -----


func test_component_catalogue_shape() -> void:
	assert_eq(Components.COMPONENTS.size(), 18, "18 components")
	assert_eq(Components.component_ids().size(), 18, "18 distinct component ids")
	var families: Dictionary = {}
	var grades: Dictionary = {1: 0, 2: 0, 3: 0}
	var seen: Dictionary = {}
	for entry: Dictionary in Components.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		assert_ne(component_id, &"", "every component carries an id")
		assert_false(seen.has(component_id), "duplicate component id %s" % String(component_id))
		seen[component_id] = true
		assert_eq(int(entry.get(&"units", 0)), 1, "%s units" % String(component_id))
		var family: StringName = entry.get(&"family", &"")
		families[family] = int(families.get(family, 0)) + 1
		var grade: int = int(entry.get(&"grade", 0))
		grades[grade] = int(grades.get(grade, 0)) + 1
	assert_eq(families.size(), 6, "six families")
	for family: StringName in COMPONENT_FAMILIES:
		assert_eq(int(families.get(family, 0)), 3, "family %s holds three grades" % String(family))
	for grade: int in [1, 2, 3]:
		assert_eq(int(grades[grade]), 6, "grade %d holds six families" % grade)
		assert_eq(Components.grade_components(grade).size(), 6, "grade %d lookup" % grade)
	assert_eq(Components.family_components(&"salvage").size(), 3, "family lookup")
	assert_eq(Components.family_components(&"nonsense").size(), 0, "unknown family is empty")


func test_component_values_match_docs() -> void:
	assert_eq(COMPONENT_VALUES.size(), 18, "the table covers all 18 components")
	for component_id: StringName in COMPONENT_VALUES:
		var entry := Components.component(component_id)
		assert_false(entry.is_empty(), "missing component %s" % String(component_id))
		assert_eq(
			int(entry.get(&"value", -1)),
			int(COMPONENT_VALUES[component_id]),
			"%s value" % String(component_id)
		)


func test_component_grade_sums() -> void:
	var totals: Dictionary = {1: 0, 2: 0, 3: 0}
	for component_id: StringName in COMPONENT_VALUES:
		var grade: int = int(Components.component(component_id).get(&"grade", 0))
		totals[grade] = int(totals.get(grade, 0)) + int(COMPONENT_VALUES[component_id])
	assert_eq(int(totals[1]), 112, "grade I sum, the integer form of 03 section 3.1's 19 mean")
	assert_eq(int(totals[2]), 280, "grade II sum, the integer form of 03 section 3.1's 47 mean")
	assert_eq(int(totals[3]), 675, "grade III sum, the integer form of 03 section 3.1's 113 mean")
	assert_eq(roundi(112.0 / 6.0), 19, "grade I mean")
	assert_eq(roundi(280.0 / 6.0), 47, "grade II mean")
	assert_eq(roundi(675.0 / 6.0), 113, "grade III mean")
