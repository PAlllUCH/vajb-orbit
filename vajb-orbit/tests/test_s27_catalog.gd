@tool
extends McpTestSuite
## Suite s27_catalog: wave S27's catalog breadth and the shipyard. One row per pinned
## acceptance (A1-A7):
##   A1 the seven R-S27-2 affix rows (15 section 1/3/4, family bands, a 5k seeded roll)
##   A2 every suffix perk's consumer at the CONTRACTS section 20 seam (Echoes / Long
##      Watch / Pyre named and exercised)
##   A3 the `<base>_mk2` variant rows (R-S27-1: +1 tier, +15 % headline, L2-banded price,
##      one tier up in the sale pool)
##   A4 the four new 06 section 3 loot tables (interceptor/turret/sibelon/boss, 20k EV)
##   A5 the shipyard (10 section 3: hull recipes, module shape rule, queue, scrap)
##   A6 the tier-4 rider (T-153): a tier-4 row and the reserved slot reserving tier 4
##   A7 every new price derives from the ladder (no hand-picked flat)
##
## The law's figures appear only as the expected side of a comparison; every shipped
## number is read from its owner (ModuleCatalog, Affixes, LootTables, Shipyard,
## ContractRegistry, ComponentCatalog, MineralCatalog, Auction).

const ModuleData := preload("res://game/module_catalog.gd")
const AffixScript := preload("res://game/affixes.gd")
const LootScript := preload("res://game/loot_tables.gd")
const ShipyardScript := preload("res://game/shipyard.gd")
const ContractScript := preload("res://game/contract_registry.gd")
const ComponentScript := preload("res://game/component_catalog.gd")
const MineralScript := preload("res://game/mineral_catalog.gd")
const AuctionScript := preload("res://game/auction.gd")
const SectorScript := preload("res://game/sector_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const GameScript := preload("res://game/game.gd")
const WeaponScript := preload("res://game/weapons.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const PROFILE_PATH := "user://test_s27_catalog.cfg"
## S27-B2: the live launch harness' scratch store (the autoload's `save_path` is
## repointed here for the flight-call-site rows and restored at suite teardown).
const SCRATCH_PROFILE := "user://test_s27_catalog_live.cfg"
const GAME_SCENE := "res://game/game.tscn"
## A kill point in dead space, past every witness radius (`test_s7_suffixes.gd`'s own).
const KILL_POINT := Vector2(4800.0, -4800.0)
## 13 section 2's no-crime row: a swarmer kill files heat 0, so the handler's credited
## path is measured without the witness rung.
const SWARMER: StringName = &"swarmer"

## The seeded probes' own sample sizes.
const AFFIX_SAMPLE := 5000
const EV_SAMPLE := 20000
const EV_TOLERANCE := 0.05

## 01's 2026-10-08 block (the S28 block, M8): SC(t) for t1..t4, read from its owner.
const SC := ContractScript.SC

## R-S27-2's seven rows.
const NEW_PREFIXES: Array[StringName] = [&"dense", &"quickwarm", &"layered", &"farflung"]
const NEW_SUFFIXES: Array[StringName] = [&"echoes", &"long_watch", &"pyre"]
## The R-S27-2 prefix rows' family (09 section 1 slot) and stat, verbatim.
const NEW_PREFIX_ROWS: Dictionary = {
	&"dense": {&"slot": &"weapons", &"stat": &"damage_add"},
	&"quickwarm": {&"slot": &"weapons", &"stat": &"fire_rate_mult"},
	&"layered": {&"slot": &"armour", &"stat": &"hull_add"},
	&"farflung": {&"slot": &"weapons", &"stat": &"range_mult"},
}
## The live (non-staged) shipped suffix rows CONTRACTS section 20 names a consumer for.
const LIVE_SUFFIXES: Array[StringName] = [
	&"whale", &"embers", &"ledger", &"cartograph", &"leeches",
]

## A3: the family headline stat each variant scales by +15 %.
const HEADLINE: Dictionary = {
	&"shields": &"shield_add",
	&"armour": &"hull_add",
	&"computers": &"damage_add",
	&"boosters": &"boost_speed_mult",
	&"utility": &"cargo_add",
	&"power": &"power_add",
}

## A4: the four new kinds and their bands.
const NEW_KINDS: Dictionary = {
	&"interceptor": 1,
	&"turret": 2,
	&"sibelon": 2,
	&"boss": 3,
}

## A victim stand-in for the kill seam: the answers `game.gd:_on_npc_died` reads off a
## real `NpcShip` (its row, the two 13 section 2 values) plus the pre-blow hull share the
## Pyre ring gates on. S27-F1: the gate reads the share recorded **before** the killing
## blow, so `pre_hit` is what a real hull's `_pre_hit_hull_fraction` holds - 1.0 for a
## full-hull one-shot, below the quarter line for a finish.
class StubHull extends Node2D:
	var archetype_id: StringName = &"swarmer"
	var pre_hit := 0.0

	func row() -> Dictionary:
		return NpcRegistryScript.archetype(archetype_id)

	func heat_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))

	func standing_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))

	func hull_fraction() -> float:
		return 0.0

	func pre_hit_hull_fraction() -> float:
		return pre_hit


## A nearby hull the Pyre ring charges: records every `take_damage` the ring hands it.
class RingSink extends Node2D:
	var taken := 0.0

	func take_damage(amount: float, _bypass_shield: bool = false, _ctx: Dictionary = {}) -> void:
		taken += amount


var _profiles: Array[Node] = []
var _scenes: Array[Node2D] = []
var _bare: Array[Node] = []
var _previous_path := ""
var _state: PlayerState = null


func suite_name() -> String:
	return "s27_catalog"


func suite_setup(_ctx: Dictionary) -> void:
	GameScript._transit_destination = &""
	_stage_scratch_store()


func setup() -> void:
	GameScript._transit_destination = &""
	_reset_store()
	_state = PlayerStateScript.new()


func teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()
	_state = null


func suite_teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_delete_file(SCRATCH_PROFILE)


## ---------------------------------------------------------------------------
## A1 - the seven R-S27-2 affix rows
## ---------------------------------------------------------------------------


func test_a1_the_seven_rows_exist_with_their_families() -> void:
	for id: StringName in NEW_PREFIXES:
		assert_true(ModuleData.PREFIXES.has(id), "prefix %s ships" % id)
		var row: Dictionary = ModuleData.PREFIXES[id]
		assert_eq(StringName(row.get(&"slot", &"")), NEW_PREFIX_ROWS[id][&"slot"], "%s family" % id)
		assert_eq(StringName(row.get(&"stat", &"")), NEW_PREFIX_ROWS[id][&"stat"], "%s stat" % id)
	for id: StringName in NEW_SUFFIXES:
		assert_true(ModuleData.SUFFIXES.has(id), "suffix %s ships" % id)
		assert_false(String(ModuleData.SUFFIXES[id].get(&"perk", "")).is_empty(), "%s perk" % id)


func test_a1_family_bands_are_respected() -> void:
	## A shield never rolls a damage prefix: every prefix in `s_light`'s pool is a
	## shields row, and the new weapons rows never reach it.
	var shield_pool := ModuleData.prefix_pool(&"s_light")
	assert_false(shield_pool.is_empty(), "a shield rolls prefixes")
	for id: String in shield_pool:
		assert_eq(
			StringName(ModuleData.PREFIXES[id].get(&"slot", &"")),
			&"shields",
			"shield pool carries only shields prefixes"
		)
	for id: StringName in NEW_PREFIXES:
		if NEW_PREFIX_ROWS[id][&"slot"] == &"weapons":
			assert_false(shield_pool.has(String(id)), "%s is not a shield prefix" % id)
	## The armour row reaches armour and only armour.
	assert_true(ModuleData.prefix_pool(&"h_composite").has("layered"), "Layered rolls on armour")


func test_a1_values_are_in_their_family_tier_bands() -> void:
	for id: StringName in NEW_PREFIXES:
		var band: Array = ModuleData.PREFIXES[id][&"band"]
		assert_eq(band.size(), 3, "%s carries three tier columns" % id)
		for tier: int in [1, 2, 3]:
			assert_eq(ModuleData.prefix_value(id, tier), float(band[tier - 1]), "%s T%d" % [id, tier])


func test_a1_seeded_roll_probe_over_5k_instances() -> void:
	## 15 section 3's rarity contract over a seeded 5 000-instance roll: every rolled
	## prefix belongs to the module's own family and carries a value inside its band.
	seed(20261008)
	var hulls: Array[StringName] = [&"s_light", &"h_composite", &"c_target", &"w_laser"]
	var seen: Dictionary = {}
	for index in AFFIX_SAMPLE:
		var base: StringName = hulls[index % hulls.size()]
		var rarity: String = ModuleData.RARITY_MAGIC if index % 3 == 0 else ModuleData.RARITY_RARE
		var prefixes := ModuleData.roll_prefixes(base, rarity)
		assert_eq(
			prefixes.size(),
			ModuleData.affix_count(rarity),
			"%s rolled the rarity's prefix count" % base
		)
		var slot := ModuleData.fit_slot_of(base)
		for entry: Dictionary in prefixes:
			var id := StringName(entry[&"id"])
			assert_eq(
				StringName(ModuleData.PREFIXES[id].get(&"slot", &"")),
				slot,
				"%s's prefix %s is its own family" % [base, id]
			)
			var band: Array = ModuleData.PREFIXES[id][&"band"]
			var value := float(entry[&"value"])
			var low := minf(float(band[0]), float(band[2]))
			var high := maxf(float(band[0]), float(band[2]))
			assert_true(
				value >= low and value <= high,
				"%s's %s value %f is in band [%f, %f]" % [base, id, value, low, high]
			)
			seen[id] = int(seen.get(id, 0)) + 1
	## The four new rows are reachable (the probe actually rolled them).
	for id: StringName in NEW_PREFIXES:
		assert_gt(int(seen.get(String(id), 0)), 0, "%s rolled at least once in 5k" % id)


## S27-F1 (15 section 3's "the two prefixes of a Rare must be **different properties**"):
## the weapon family carries two rows per stat (`keen`/`dense` = `damage_add`,
## `rapid`/`quickwarm` = `fire_rate_mult`), so deduping by id is not enough. A seeded
## sweep of many Rare weapons asserts no roll pairs two prefixes bending one property.
func test_a1_a_rare_never_pairs_one_property_twice() -> void:
	seed(20261010)
	var weapons: Array[StringName] = [&"w_laser", &"w_cannon", &"w_plasma", &"w_flak"]
	for index in AFFIX_SAMPLE:
		var base: StringName = weapons[index % weapons.size()]
		var prefixes := ModuleData.roll_prefixes(base, ModuleData.RARITY_RARE)
		assert_eq(prefixes.size(), 2, "%s rolls two prefixes" % base)
		var stats: Array[StringName] = []
		for entry: Dictionary in prefixes:
			var id := StringName(entry[&"id"])
			stats.append(StringName(ModuleData.PREFIXES[id][&"stat"]))
		assert_ne(stats[0], stats[1], "%s's two prefixes bend different properties" % base)


## ---------------------------------------------------------------------------
## A2 - every suffix perk's consumer at the CONTRACTS section 20 seam
## ---------------------------------------------------------------------------


func test_a2_every_perk_names_its_consumer() -> void:
	for id: Variant in ModuleData.SUFFIXES:
		var key := StringName(str(id))
		assert_true(
			(ModuleData.SUFFIXES[id] as Dictionary).has(&"consumer"),
			"%s names its consumer" % key
		)
	for id: StringName in NEW_SUFFIXES:
		assert_false(
			String(ModuleData.SUFFIXES[id].get(&"consumer", "")).is_empty(),
			"%s's consumer is named" % id
		)
	for id: StringName in LIVE_SUFFIXES:
		assert_false(
			String(ModuleData.SUFFIXES[id].get(&"consumer", "")).is_empty(),
			"%s's live consumer is named" % id
		)


func test_a2_echoes_refunds_every_fifth_shot() -> void:
	var on: Dictionary = {&"suffixes": [&"echoes"]}
	var off: Dictionary = {&"suffixes": []}
	assert_true(AffixScript.echoes_refunds(on, 5), "the fifth shot is free")
	assert_true(AffixScript.echoes_refunds(on, 10), "the tenth too")
	assert_false(AffixScript.echoes_refunds(on, 4), "the fourth is not")
	assert_false(AffixScript.echoes_refunds(on, 0), "shot 0 is not a release")
	assert_false(AffixScript.echoes_refunds(off, 5), "no Echoes, no refund")


func test_a2_long_watch_holds_the_lock_two_seconds() -> void:
	var on: Dictionary = {&"suffixes": [&"long_watch"]}
	var off: Dictionary = {&"suffixes": []}
	assert_eq(AffixScript.lock_channel_seconds(on, 1.2), 3.2, "1.2 s becomes 3.2 s")
	assert_eq(AffixScript.lock_channel_seconds(off, 1.2), 1.2, "unchanged without the perk")
	assert_eq(AffixScript.LONG_WATCH_SECONDS, 2.0, "the +2 s pin")


func test_a2_pyre_detonates_below_quarter_hull() -> void:
	var on: Dictionary = {&"suffixes": [&"pyre"]}
	var off: Dictionary = {&"suffixes": []}
	assert_eq(AffixScript.pyre_ring_damage(on, 0.20), 50.0, "below 25 % hull pays the ring")
	assert_eq(AffixScript.pyre_ring_damage(on, 0.24), 50.0, "24 % still detonates")
	assert_eq(AffixScript.pyre_ring_damage(on, 0.25), 0.0, "exactly a quarter does not")
	assert_eq(AffixScript.pyre_ring_damage(on, 0.90), 0.0, "a healthy kill does not")
	assert_eq(AffixScript.pyre_ring_damage(off, 0.10), 0.0, "no Pyre, no ring")
	assert_eq(AffixScript.PYRE_RING_DAMAGE, 50.0, "the 50-damage pin")


## ---------------------------------------------------------------------------
## A3 - the `<base>_mk2` variant rows
## ---------------------------------------------------------------------------


func test_a3_variants_are_one_tier_up_with_the_headline_stat() -> void:
	assert_gt(ModuleData.VARIANTS.size(), 0, "variants ship")
	for id: StringName in ModuleData.variant_ids():
		var row := ModuleData.module(id)
		assert_false(row.is_empty(), "%s is a catalogue row" % id)
		var base := StringName(row.get(&"base", &""))
		var base_row := ModuleData.module(base)
		assert_false(base_row.is_empty(), "%s's base %s exists" % [id, base])
		assert_eq(
			int(row.get(&"tier", 0)),
			mini(int(base_row.get(&"tier", 1)) + 1, ModuleData.MAX_MODULE_TIER),
			"%s is one tier up" % id
		)
		var slot := StringName(row.get(&"slot", &""))
		var headline: StringName = HEADLINE.get(slot, &"")
		assert_ne(headline, &"", "%s's family has a headline stat" % id)
		var base_value := float((base_row.get(&"effects", {}) as Dictionary).get(headline, 0.0))
		var value := float((row.get(&"effects", {}) as Dictionary).get(headline, 0.0))
		assert_true(
			absf(value - base_value * 1.15) < 0.001,
			"%s: %s %.4f is %.2f x the base's %.4f" % [id, headline, value, 1.15, base_value]
		)


func test_a3_variant_prices_are_in_the_l2_band() -> void:
	for id: StringName in ModuleData.variant_ids():
		var row := ModuleData.module(id)
		var tier := int(row.get(&"tier", 0))
		var low := SC[tier - 1]
		var high := 2 * SC[tier - 1]
		var cost := int(row.get(&"cost", 0))
		assert_true(
			cost >= low and cost <= high,
			"%s cost %d is in tier %d's band [%d, %d]" % [id, cost, tier, low, high]
		)


func test_a3_variants_appear_in_the_sale_pool_one_tier_up() -> void:
	for id: StringName in ModuleData.variant_ids():
		var tier := int(ModuleData.module(id).get(&"tier", 0))
		assert_true(AuctionScript.sale_pool(tier).has(id), "%s lists at tier %d" % [id, tier])
		assert_true(ModuleData.variant_pool(tier).has(id), "%s is in its tier's variant pool" % id)


## ---------------------------------------------------------------------------
## A4 - the four new 06 section 3 loot tables
## ---------------------------------------------------------------------------


func test_a4_the_four_kinds_are_06_section_3_tables() -> void:
	for kind: StringName in NEW_KINDS:
		assert_true(LootScript.has(kind), "%s ships a table" % kind)
		var table: Dictionary = LootScript.TABLES[kind]
		assert_eq(int(table[&"band"]), NEW_KINDS[kind], "%s band" % kind)
		var lines: Array = table[&"lines"]
		assert_gt(lines.size(), 0, "%s has lines" % kind)
		for line: Dictionary in lines:
			assert_true(line.has(&"item"), "%s line carries an item" % kind)
			assert_true(line.has(&"chance"), "%s line carries a chance" % kind)
			assert_true(int(line[&"min"]) >= 1, "%s line min" % kind)
			assert_true(int(line[&"max"]) >= int(line[&"min"]), "%s line max" % kind)
		## 06 section 2.4: a cache line, where the table carries one, is last.
		var last: StringName = StringName(lines[lines.size() - 1][&"item"])
		for line: Dictionary in lines:
			if StringName(line[&"item"]) == LootScript.CREDIT_ITEM:
				assert_eq(last, LootScript.CREDIT_ITEM, "%s's cache line is last" % kind)
				break
	assert_eq(LootScript.cap_violations(), [] as Array[String], "the new tables are grade-clean")
	assert_eq(LootScript.uncatalogued_items(), [] as Array[StringName], "every line is catalogued")


func test_a4_seeded_ev_over_20k_rolls() -> void:
	for kind: StringName in NEW_KINDS:
		var expected := _expected_ev(kind)
		var sample := _sample_ev(kind)
		var credit_tolerance := EV_TOLERANCE * maxf(float(expected[&"credits"]), 1.0)
		var unit_tolerance := EV_TOLERANCE * maxf(float(expected[&"units"]), 1.0)
		assert_true(
			absf(float(sample[&"credits"]) - float(expected[&"credits"])) <= credit_tolerance,
			"%s: %.3f CR vs %.3f expected" % [kind, sample[&"credits"], expected[&"credits"]]
		)
		assert_true(
			absf(float(sample[&"units"]) - float(expected[&"units"])) <= unit_tolerance,
			"%s: %.3f units vs %.3f expected" % [kind, sample[&"units"], expected[&"units"]]
		)


## ---------------------------------------------------------------------------
## A5 - the shipyard (10 section 3)
## ---------------------------------------------------------------------------


func test_a5_hull_recipes_match_section_3_1() -> void:
	assert_eq(ShipyardScript.HULL_RECIPES.size(), 9, "nine hull classes")
	var corvette := ShipyardScript.hull_recipe(&"ship_corvette")
	assert_eq(corvette[ShipyardScript.KEY_LABOUR], 9450, "Corvette labour")
	assert_eq(corvette[ShipyardScript.KEY_MATERIALS][&"mineral_tungsten"], 60, "Corvette tungsten")
	assert_eq(corvette[ShipyardScript.KEY_MATERIALS][&"mineral_cobalt"], 35, "Corvette cobalt")
	assert_eq(corvette[ShipyardScript.KEY_MATERIALS][&"comp_scrap_2"], 4, "Corvette scrap")
	## The materials bill re-derives from the live 02/03 values (never a stale figure).
	var expected := 0
	for key: Variant in corvette[ShipyardScript.KEY_MATERIALS]:
		expected += ShipyardScript.item_value(StringName(str(key))) \
			* int(corvette[ShipyardScript.KEY_MATERIALS][key])
	assert_eq(ShipyardScript.materials_value(corvette[ShipyardScript.KEY_MATERIALS]), expected, "Corvette materials CR")


func test_a5_module_recipes_follow_the_shape_rule() -> void:
	var ids: Array[StringName] = [&"w_laser", &"s_light", &"h_plate_light", &"c_target", &"e_std", &"p_std", &"u_cargo"]
	for id: StringName in ids:
		var recipe := ShipyardScript.module_recipe(id)
		var row := ModuleData.module(id)
		var tier := int(row.get(&"tier", 1))
		var component := ShipyardScript.component_id(id)
		var ore := ShipyardScript.ore_id(tier)
		assert_eq(
			int(recipe[ShipyardScript.KEY_MATERIALS].get(component, 0)),
			ShipyardScript.COMPONENT_UNITS,
			"%s builds 2x its component" % id
		)
		assert_eq(
			int(recipe[ShipyardScript.KEY_MATERIALS].get(ore, 0)),
			ShipyardScript.ORE_UNITS,
			"%s builds 12x its ore" % id
		)
		assert_eq(
			int(recipe[ShipyardScript.KEY_LABOUR]),
			roundi(float(int(row.get(&"cost", 0))) * 0.20),
			"%s's labour is 20 %% of list" % id
		)
		## The CR total reads the live ore/component values.
		assert_eq(
			ShipyardScript.recipe_total(recipe),
			ShipyardScript.materials_value(recipe[ShipyardScript.KEY_MATERIALS]) + int(recipe[ShipyardScript.KEY_LABOUR]),
			"%s's CR total" % id
		)


func test_a5_queue_commits_at_queue_and_refunds_on_cancel() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 100)
	profile.add_cargo(&"mineral_chromium", 100)
	profile.add_cargo(&"comp_scrap_1", 10)
	var credits: int = profile.credits()
	assert_true(ShipyardScript.queue_job(profile, ShipyardScript.KIND_HULL, &"ship_fighter"), "queues")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 55, "45 iron left the hold")
	assert_eq(profile.cargo_qty(&"mineral_chromium"), 75, "25 chromium left the hold")
	assert_eq(profile.credits(), credits - 3150, "the labour left the credits")
	assert_false(
		ShipyardScript.queue_job(profile, ShipyardScript.KIND_HULL, &"ship_fighter"),
		"one build at a time"
	)
	assert_true(ShipyardScript.cancel_job(profile), "cancels before completion")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 100, "materials refunded in full")
	assert_eq(profile.credits(), credits, "labour refunded in full")
	assert_true(ShipyardScript.job(profile).is_empty(), "the queue is idle again")


func test_a5_queue_completes_after_one_session_and_persists() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 100)
	profile.add_cargo(&"mineral_chromium", 100)
	profile.add_cargo(&"comp_scrap_1", 10)
	assert_true(ShipyardScript.queue_job(profile, ShipyardScript.KIND_HULL, &"ship_fighter"), "queues")
	assert_false(ShipyardScript.is_ready(profile), "not ready before a flight")
	assert_false(ShipyardScript.collect(profile), "collect refuses before ready")
	ShipyardScript.note_flight(profile)
	assert_true(ShipyardScript.is_ready(profile), "ready after one in-space session")
	## Persists across a restart: a second profile reads the same queue back.
	profile.flush()
	var reader := ProfileScript.new()
	reader.save_path = PROFILE_PATH
	reader.reload()
	assert_true(ShipyardScript.is_ready(reader), "the queue survives a reload")
	assert_true(ShipyardScript.collect(reader), "collect delivers the hull")
	assert_true(reader.owns_ship(&"ship_fighter"), "the hull is owned")


func test_a5_scrap_path_is_half_the_materials() -> void:
	var recipe := ShipyardScript.hull_recipe(&"ship_fighter")
	var scrap := ShipyardScript.scrap_materials(recipe[ShipyardScript.KEY_MATERIALS])
	assert_eq(int(scrap[&"mineral_iron"]), 22, "45 iron scraps to 22 (round down)")
	assert_eq(int(scrap[&"mineral_chromium"]), 12, "25 chromium scraps to 12")
	assert_eq(int(scrap[&"comp_scrap_1"]), 1, "2 scrap parts to 1")
	var profile = _fresh()
	profile.grant_ship(&"ship_fighter")
	profile.remove_ship(&"ship_fighter")
	assert_false(profile.owns_ship(&"ship_fighter"), "the scrapped hull leaves the roster")


## ---------------------------------------------------------------------------
## A6 - the tier-4 rider (T-153)
## ---------------------------------------------------------------------------


func test_a6_a_tier_4_row_lands_and_the_reserved_slot_reserves_it() -> void:
	var tier4: Array[StringName] = []
	for id: StringName in ModuleData.variant_ids():
		if int(ModuleData.module(id).get(&"tier", 0)) == ModuleData.MAX_MODULE_TIER:
			tier4.append(id)
	assert_gt(tier4.size(), 0, "a tier-4 catalogue row lands")
	for id: StringName in tier4:
		var cost := int(ModuleData.module(id).get(&"cost", 0))
		assert_true(cost >= 6000 and cost <= 12000, "%s is priced in L2's tier-4 band" % id)
	assert_gt(AuctionScript.tier_pool(4).size(), 0, "tier_pool(4) is non-empty")
	## A tier-4 sector's reserved slot reserves tier 4.
	var tier4_sector := 0
	for sector_id: StringName in SectorScript.sector_ids():
		if SectorScript.sector_tier(sector_id) == 4:
			tier4_sector = SectorScript.sector_number(sector_id)
			break
	assert_gt(tier4_sector, 0, "a tier-4 sector exists")
	assert_eq(AuctionScript._reserved_tier({&"sector": tier4_sector}), 4, "the clamp reads tier 4")


## ---------------------------------------------------------------------------
## A7 - no hand-picked price (every new figure derives from the ladder)
## ---------------------------------------------------------------------------


func test_a7_every_variant_price_derives_from_the_ladder() -> void:
	for id: StringName in ModuleData.variant_ids():
		var row := ModuleData.module(id)
		var base := ModuleData.module(StringName(row.get(&"base", &"")))
		var tier := int(row.get(&"tier", 0))
		var base_tier := int(base.get(&"tier", 0))
		var derived := roundi(
			float(int(base.get(&"cost", 0))) * float(SC[tier - 1]) / float(SC[base_tier - 1])
		)
		var banded := clampi(derived, SC[tier - 1], 2 * SC[tier - 1])
		assert_eq(int(row.get(&"cost", 0)), banded, "%s's cost is the ladder's own step" % id)


## ---------------------------------------------------------------------------
## A2/A5 flight call sites (S27-B2): the perks and the play gate in play
## ---------------------------------------------------------------------------


## of Echoes in flight (15 section 4, CONTRACTS section 20): five releases from a cannon
## whose launch carries the flag spend four rounds; the same five without it spend five.
## The count and the gate live in `weapons.gd:_consume_ammo_at`.
func test_a2_echoes_refunds_a_shot_in_flight() -> void:
	var on := PlayerStateScript.new()
	var guns := _ammo_rig(on, [&"echoes"])
	on.set_ammo(0, 100)
	for _shot in 5:
		guns.call(&"_consume_ammo_at", 0, &"cannon")
	assert_eq(on.ammo[0], 96, "of Echoes made the fifth of five shots free")
	var off := PlayerStateScript.new()
	var plain := _ammo_rig(off, [])
	off.set_ammo(0, 100)
	for _shot in 5:
		plain.call(&"_consume_ammo_at", 0, &"cannon")
	assert_eq(off.ammo[0], 95, "without of Echoes all five shots cost a round")


## of the Long Watch in flight (15 section 4): a channel that lands at the pinned 1.2 s
## with no perk is still running at 1.3 s with it, and lands past 3.2 s. The duration is
## read in `game.gd:_update_lock` from the launch summary.
func test_a2_long_watch_extends_the_lock_in_flight() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var ship := scene.get(&"_ship") as Node2D
	assert_true(ship != null, "the launch spawned the player ship")
	if ship == null:
		return
	scene.set(&"_launch_summary", {})
	scene.call(&"_start_lock", _lock_target_at(ship.global_position + Vector2(60.0, 0.0)))
	scene.call(&"_update_lock", 1.3)
	assert_false(bool(scene.get(&"_lock_channeling")), "a plain launch acquires at the pinned 1.2 s")
	scene.call(&"_cancel_lock")
	scene.set(&"_launch_summary", {&"suffixes": [&"long_watch"]})
	scene.call(&"_start_lock", _lock_target_at(ship.global_position + Vector2(60.0, 0.0)))
	scene.call(&"_update_lock", 1.3)
	assert_true(bool(scene.get(&"_lock_channeling")), "of the Long Watch holds past 1.2 s")
	scene.call(&"_update_lock", 2.0)
	assert_false(bool(scene.get(&"_lock_channeling")), "and lands by 3.3 s")


## of the Pyre in flight (15 section 4): a finish on a hull below the quarter line
## detonates the 50-damage ring, charging a nearby hull once; a full-hull one-shot does
## not (S27-F1: the gate reads the victim's share **before** the killing blow, not the
## post-blow 0.0); without the flag the same kill pays nothing. The gate and the amount
## live in `game.gd:_on_npc_died`.
func test_a2_pyre_ring_fires_on_a_kill_in_flight() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var on := _ring_sink(KILL_POINT + Vector2(60.0, 0.0))
	scene.set(&"_launch_summary", {&"suffixes": [&"pyre"]})
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim(SWARMER, 0.10))
	assert_eq(on.taken, AffixScript.PYRE_RING_DAMAGE, "a below-quarter finish charged the nearby hull")
	var one_shot := _ring_sink(KILL_POINT + Vector2(60.0, 0.0))
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim(SWARMER, 1.0))
	assert_eq(one_shot.taken, 0.0, "a full-hull one-shot does not fire the ring")
	var off := _ring_sink(KILL_POINT + Vector2(60.0, 0.0))
	scene.set(&"_launch_summary", {})
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim(SWARMER, 0.10))
	assert_eq(off.taken, 0.0, "without of the Pyre the kill pays no ring")


## A5's play gate in play (10 section 3.3): a launch advances the profile's shipyard
## session by exactly one, so a queued build is ready on return; a crossing is not a
## launch and advances nothing.
func test_a5_a_launch_advances_the_shipyard_session() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"add_cargo", &"mineral_iron", 100)
	profile.call(&"add_cargo", &"mineral_chromium", 100)
	profile.call(&"add_cargo", &"comp_scrap_1", 10)
	assert_true(
		ShipyardScript.queue_job(profile, ShipyardScript.KIND_HULL, &"ship_fighter"),
		"the build queues"
	)
	assert_false(ShipyardScript.is_ready(profile), "not ready before a flight")
	var before: int = int(profile.call(&"shipyard_session"))
	GameScript._transit_destination = &""
	_open_game()
	assert_eq(int(profile.call(&"shipyard_session")), before + 1, "the launch advanced one session")
	assert_true(ShipyardScript.is_ready(profile), "so the queued build is ready")
	var after: int = int(profile.call(&"shipyard_session"))
	GameScript._transit_destination = &"station"
	_open_game()
	assert_eq(int(profile.call(&"shipyard_session")), after, "a crossing advances nothing")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := ProfileScript.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _item_value(item: StringName) -> float:
	if item == LootScript.CREDIT_ITEM:
		return 1.0
	return float(ComponentScript.component(item).get(&"value", 0))


func _expected_ev(kind: StringName) -> Dictionary:
	var credits := 0.0
	var units := 0.0
	for line: Dictionary in LootScript.TABLES[kind][&"lines"]:
		var chance := float(line[&"chance"])
		var mean := float(int(line[&"min"]) + int(line[&"max"])) * 0.5
		if StringName(line[&"item"]) == LootScript.CREDIT_ITEM:
			credits += chance * mean
		else:
			units += chance * mean
			credits += chance * mean * _item_value(StringName(line[&"item"]))
	return {&"credits": credits, &"units": units}


func _sample_ev(kind: StringName) -> Dictionary:
	var credits := 0.0
	var units := 0.0
	for index in EV_SAMPLE:
		for entry: Dictionary in LootScript.roll_band(kind, 20261008 + index):
			var amount := int(entry[LootScript.KEY_AMOUNT])
			if bool(entry[LootScript.KEY_CACHE]):
				credits += float(amount)
			else:
				units += float(amount)
				credits += float(amount) * _item_value(StringName(entry[LootScript.KEY_ITEM]))
	return {
		&"credits": credits / float(EV_SAMPLE),
		&"units": units / float(EV_SAMPLE),
	}


## The launch's suffix list, typed for `PlayerState.set_affix_flags`.
func _flags(ids: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: Variant in ids:
		out.append(StringName(str(id)))
	return out


## One cannon barrel on `state`, its launch suffix list set to `flags`. The component is
## hosted so a travelling shot could spawn; `_consume_ammo_at` only needs the state.
func _ammo_rig(state: PlayerState, flags: Array) -> Node2D:
	var families: Array[StringName] = [&"cannon"]
	state.set_weapons(families)
	state.setup()
	var per: Array[Dictionary] = [{}]
	state.set_weapon_affixes(per)
	state.set_affix_flags(_flags(flags))
	var guns := WeaponScript.new() as Node2D
	_fixture_host().add_child(guns)
	_bare.append(guns)
	guns.call(&"setup", null, state)
	var fit: Array[StringName] = [&"w_cannon"]
	guns.call(&"set_fitted", fit)
	return guns


## A lock target stand-in at `pos`, parented to the fixture host (the lock channel only
## reads its `global_position`; a bare Node2D is no LOS blocker).
func _lock_target_at(pos: Vector2) -> Node2D:
	var target := Node2D.new()
	_fixture_host().add_child(target)
	target.global_position = pos
	_bare.append(target)
	return target


## A victim stand-in, parented to the fixture host so it has a tree while the handler
## runs.
func _victim(archetype: StringName, pre_hit := 0.0) -> Node2D:
	var hull := StubHull.new()
	hull.archetype_id = archetype
	hull.pre_hit = pre_hit
	_fixture_host().add_child(hull)
	_bare.append(hull)
	return hull


## A hull the Pyre ring charges, in the `npc_ship` group at `pos`.
func _ring_sink(pos: Vector2) -> RingSink:
	var sink := RingSink.new()
	sink.add_to_group(&"npc_ship")
	_fixture_host().add_child(sink)
	sink.global_position = pos
	_bare.append(sink)
	return sink


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy, so the profile autoload hosts them.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _store() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_fixture_host().add_child(scene)
	_scenes.append(scene)
	return scene


func _free_scenes() -> void:
	for scene: Node2D in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()


func _free_bare() -> void:
	for node: Node in _bare:
		if is_instance_valid(node):
			node.free()
	_bare.clear()


func _reset_store() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")


func _stage_scratch_store() -> void:
	var profile := _store()
	if profile == null:
		return
	_previous_path = String(profile.get(&"save_path"))
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")
