@tool
extends McpTestSuite
## Suite s6_poi_loot: wave S6's POIs and loot - the kill roll and its hunter extra
## (`game/loot_tables.gd`), the derelict scan channel and its reward roll, the three
## anomaly kinds with the Hollows' doubled rift, the beacon reveal, 11 §5's soft-fog
## blips and 06 §4's 90 s wreck site (`game/poi.gd`, `game/sector.gd`, `game/game.gd`).
##
## Contract: docs/CONTRACTS.md §19 (the pin), docs/gameplay/11_galactic_map.md §3/§5,
## docs/gameplay/06_loot_drops.md §2-§6/§8, 15 §2/§5. The distributions are measured
## over seeded samples, so a failure is reproducible; the live tests instantiate
## `game.tscn` the way `test_s6_travel.gd` does and repoint `PlayerProfile.save_path`
## at a scratch file for the length of the suite.

const PoiScript := preload("res://game/poi.gd")
const LootTablesScript := preload("res://game/loot_tables.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ModuleCatalogScript := preload("res://game/module_catalog.gd")
const Registry := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const SectorScript := preload("res://game/sector.gd")
const PickupScript := preload("res://game/pickup.gd")
const GameScript := preload("res://game/game.gd")
const Log := preload("res://game/economy_log.gd")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_s6_poi_loot.cfg"
const SCRATCH_LOG := "user://test_s6_poi_loot_log.txt"

## Every sampled statistic's fixed seed and count (a failure is reproducible).
const SAMPLE_SEED := 20260924
const SAMPLE_COUNT := 10000

## The derelict distribution's tolerance: 2 percentage points (the brief's own).
const PP := 0.02
## 06 §6 check 1's tolerance, verbatim.
const EV_TOLERANCE := 0.05

const KIND_FIGHTER: StringName = &"fighter"
const KIND_CORVETTE: StringName = &"corvette"


## A player stand-in for the pure channel tests: the POI reads `global_position` and,
## for a fixture, a duck-typed scanner answer (11 §3.1).
class StubPlayer extends Node2D:
	var scanner := true

	func has_scanner() -> bool:
		return scanner


## A victim stand-in for the kill-seam test: exactly the four answers `_on_npc_died`
## reads off a real `NpcShip` (its row, and the two 13 §2 values the row carries). The
## row's key names are `NpcRegistry.KEY_LOOT_KIND` / `KEY_HEAT_ON_KILL` /
## `KEY_STANDING_ON_KILL`, spelled here because an inner class cannot see this file's
## constants.
class StubHull extends Node2D:
	func row() -> Dictionary:
		return {&"id": &"pirate", &"loot_kind": &"fighter"}

	func heat_on_kill() -> int:
		return -3

	func standing_on_kill() -> int:
		return 1


var _scenes: Array[Node2D] = []
var _bare: Array[Node] = []
var _previous_path := ""


func suite_name() -> String:
	return "s6_poi_loot"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_scratch_store()
	GameScript._transit_destination = &""


func setup() -> void:
	GameScript._transit_destination = &""


func teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()


func suite_teardown() -> void:
	_free_scenes()
	_free_bare()
	GameScript._transit_destination = &""
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## The kill roll (06 §2/§6/§8, CONTRACTS §19)
## ---------------------------------------------------------------------------


## The band roll is a delegate, not a second table: for every shipped kind it pays
## byte-for-byte what the shipped `roll(kind, band, seed)` pays. The shipped shape
## (`TABLES`, one entry per line, `amount = randi_range`) is untouched by this wave.
func test_roll_band_delegates_to_the_shipped_roll() -> void:
	for kind: StringName in LootTablesScript.TABLES:
		var band := int((LootTablesScript.TABLES[kind] as Dictionary)[&"band"])
		for index in 200:
			var seed_value := SAMPLE_SEED + index
			assert_eq(
				LootTablesScript.roll_band(kind, seed_value),
				LootTablesScript.roll(kind, band, seed_value),
				"%s: roll_band is roll(kind, band, seed)" % kind
			)


## 06 §6 check 1 over `roll_band`: the expected value per hull class equals the
## table's own arithmetic (±5 %, `randi_range` bounds inclusive). The expectation is
## computed from the doc's tables a second time here, never read off the shipped data.
func test_roll_band_expected_hauls_hold_within_five_percent() -> void:
	for kind: StringName in LootTablesScript.TABLES:
		var expected := _expected_haul(kind)
		var sample := _sample_haul(kind)
		var tolerance := EV_TOLERANCE * maxf(float(expected[&"credits"]), 1.0)
		assert_true(
			absf(float(sample[&"credits"]) - float(expected[&"credits"])) <= tolerance,
			"%s: %.3f CR vs %.3f expected (06 §6 check 1)" % [
				kind, sample[&"credits"], expected[&"credits"]
			]
		)
		var unit_tolerance := EV_TOLERANCE * maxf(float(expected[&"units"]), 1.0)
		assert_true(
			absf(float(sample[&"units"]) - float(expected[&"units"])) <= unit_tolerance,
			"%s: %.3f units vs %.3f expected (06 §6 check 1)" % [
				kind, sample[&"units"], expected[&"units"]
			]
		)


## 06 §8's hunter extra: the rows are the doc's, the grade cap is 06 §1.4's, and the
## roll is additive (a hunter drops its band table **and** this).
func test_hunter_extra_is_the_docs_rows_grade_capped_by_band() -> void:
	assert_eq(
		LootTablesScript.HUNTER_EXTRA.size(), 3, "06 §8 carries three comp_elec rows"
	)
	assert_eq(
		LootTablesScript.hunter_extra_violations(3),
		[] as Array[String],
		"band 3 pays the whole table"
	)
	assert_false(
		LootTablesScript.hunter_extra_violations(1).is_empty(),
		"band 1 caps comp_elec_2/_3 out (the cap is real)"
	)
	for index in 500:
		var seed_value := SAMPLE_SEED + index
		for entry: Dictionary in LootTablesScript.roll_hunter_extra(1, seed_value):
			assert_eq(
				entry[LootTablesScript.KEY_ITEM],
				&"comp_elec_1",
				"a band-1 hunter rolls comp_elec_1 only"
			)
		for entry: Dictionary in LootTablesScript.roll_hunter_extra(2, seed_value):
			assert_true(
				ComponentCatalogScript.component(entry[LootTablesScript.KEY_ITEM])[&"grade"] <= 2,
				"a band-2 hunter never rolls comp_elec_3"
			)


## 06 §8's rates over a seeded sample: 0.50 / 0.25 / 0.10, independent per line.
func test_hunter_extra_pays_the_docs_chances() -> void:
	var paid := {&"comp_elec_1": 0, &"comp_elec_2": 0, &"comp_elec_3": 0}
	for index in SAMPLE_COUNT:
		for entry: Dictionary in LootTablesScript.roll_hunter_extra(3, SAMPLE_SEED + index):
			var item: StringName = entry[LootTablesScript.KEY_ITEM]
			paid[item] = int(paid.get(item, 0)) + 1
	var expected := {&"comp_elec_1": 0.50, &"comp_elec_2": 0.25, &"comp_elec_3": 0.10}
	for item: StringName in expected:
		var rate := float(paid[item]) / float(SAMPLE_COUNT)
		assert_true(
			absf(rate - float(expected[item])) <= PP,
			"%s paid %.4f vs 06 §8's %.2f" % [item, rate, expected[item]]
		)


## 06 §4 / CONTRACTS §19: the wreck site's own window.
func test_wreck_pickup_lifetime_is_ninety_seconds() -> void:
	assert_eq(LootTablesScript.WRECK_PICKUP_LIFETIME, 90.0, "06 §4's 90 s window")


## The shipped five-kind table is untouched: the band roll adds a delegate, never a
## second table (test_engine2_loot.gd pins the shape; this is the guard that K2 did
## not reshape it).
func test_the_shipped_tables_and_roll_are_untouched() -> void:
	var kinds: Array[StringName] = [
		&"fighter", &"swarmer", &"freighter", &"corvette", &"maw",
	]
	assert_eq(LootTablesScript.TABLES.size(), 5, "the five slice-2 tables are all here")
	for kind: StringName in kinds:
		assert_true(LootTablesScript.has(kind), "%s is still a shipped kind" % kind)
		var payload: Array = LootTablesScript.roll(kind, 1, SAMPLE_SEED)
		for entry: Dictionary in payload:
			assert_eq(entry.size(), 3, "%s entry keeps the three pickup keys" % kind)
			assert_has_key(entry, String(LootTablesScript.KEY_ITEM), "entry item key")
			assert_has_key(entry, String(LootTablesScript.KEY_AMOUNT), "entry amount key")
			assert_has_key(entry, String(LootTablesScript.KEY_CACHE), "entry cache key")


## ---------------------------------------------------------------------------
## The derelict roll (11 §3.1)
## ---------------------------------------------------------------------------


## 11 §3.1's one roll over 10 000 seeded rolls: 0.40 / 0.35 / 0.25, each within 2 pp.
func test_derelict_roll_matches_its_three_weights() -> void:
	var counts := {
		PoiScript.DERELICT_CACHE: 0,
		PoiScript.DERELICT_DATA_CORE: 0,
		PoiScript.DERELICT_MODULE: 0,
	}
	for index in SAMPLE_COUNT:
		var reward := PoiScript.roll_derelict(SAMPLE_SEED + index)
		counts[reward] = int(counts.get(reward, 0)) + 1
	var expected := {
		PoiScript.DERELICT_CACHE: PoiScript.DERELICT_CACHE_CHANCE,
		PoiScript.DERELICT_DATA_CORE: PoiScript.DERELICT_DATA_CORE_CHANCE,
		PoiScript.DERELICT_MODULE: 1.0 - PoiScript.DERELICT_CACHE_CHANCE - PoiScript.DERELICT_DATA_CORE_CHANCE,
	}
	for reward: StringName in expected:
		var rate := float(counts[reward]) / float(SAMPLE_COUNT)
		assert_true(
			absf(rate - float(expected[reward])) <= PP,
			"%s rolled %.4f vs %.2f" % [reward, rate, expected[reward]]
		)


## The channel's codes (CONTRACTS §19): -1 out of range or scannerless, 0 running,
## -2 when the ship leaves range or takes a hit, and one shot per cycle.
func test_scan_channel_refuses_and_interrupts() -> void:
	var scanner := _player(Vector2.ZERO)
	var derelict := _bare_poi(PoiScript.KIND_DERELICT, {&"seed": 11})
	derelict.position = Vector2.ZERO

	var far := _player(Vector2(Registry.DERELICT_SCAN_RANGE + 1.0, 0.0))
	assert_eq(
		int(derelict.call(&"scan", far)),
		PoiScript.SCAN_REFUSED,
		"out of range is refused"
	)
	var blind := _player(Vector2.ZERO)
	blind.scanner = false
	assert_eq(
		int(derelict.call(&"scan", blind)),
		PoiScript.SCAN_REFUSED,
		"no scanner is refused"
	)
	assert_eq(int(derelict.call(&"scan", scanner)), PoiScript.SCAN_OK, "in range starts it")
	assert_true(bool(derelict.call(&"is_channelling")), "and the channel is running")
	assert_eq(
		int(derelict.call(&"scan", far)),
		PoiScript.SCAN_INTERRUPTED,
		"leaving range interrupts it"
	)
	assert_false(bool(derelict.call(&"is_channelling")), "and cancels the channel")
	assert_eq(int(derelict.call(&"scan", scanner)), PoiScript.SCAN_OK, "a fresh start is fine")
	derelict.call(&"interrupt")
	assert_eq(
		int(derelict.call(&"advance_scan", 0.1)),
		PoiScript.SCAN_INTERRUPTED,
		"a hull hit interrupts it"
	)
	assert_eq(int(derelict.call(&"scan", scanner)), PoiScript.SCAN_OK, "and it can restart")


## The 5 s channel completes, grants the row's own reward, and is one-shot until the
## sector clock re-arms it (11 §3.1).
func test_scan_channel_completes_and_is_one_shot_per_cycle() -> void:
	var seed_value := _seed_for(PoiScript.DERELICT_CACHE)
	var derelict := _bare_poi(PoiScript.KIND_DERELICT, {&"seed": seed_value})
	var scanner := _player(Vector2.ZERO)
	assert_eq(int(derelict.call(&"scan", scanner)), PoiScript.SCAN_OK, "the channel starts")
	assert_eq(int(derelict.call(&"advance_scan", 4.9)), PoiScript.SCAN_OK, "still running")
	assert_true(
		float(derelict.call(&"channel_progress")) > 0.97,
		"the progress reads the 4.9 s of 5"
	)
	assert_true(bool(derelict.call(&"is_channelling")), "and it has not completed")
	assert_eq(int(derelict.call(&"advance_scan", 0.2)), PoiScript.SCAN_OK, "it completes")
	assert_false(bool(derelict.call(&"is_channelling")), "the channel is closed")
	assert_true(bool(derelict.call(&"is_consumed")), "and the derelict is spent")
	assert_true(bool(derelict.call(&"is_revealed")), "a scanned POI is revealed")
	assert_eq(
		int(derelict.call(&"scan", scanner)), PoiScript.SCAN_REFUSED, "a second scan is refused"
	)
	derelict.call(&"respawn", 99)
	assert_false(bool(derelict.call(&"is_consumed")), "the sector clock re-arms it")
	assert_false(bool(derelict.call(&"is_revealed")), "and the fog returns")


## The data core pays 03's comp_elec plus `DATA_CORE_CREDITS` (11 §3.1), through the
## live profile; the cache pays a component pickup and no credits.
func test_derelict_data_core_pays_comp_elec_and_credits() -> void:
	var profile := _store()
	assert_true(profile != null, "the profile autoload is the fixture host")
	if profile == null:
		return
	var before := int(profile.call(&"credits"))
	var poi := _live_poi(PoiScript.KIND_DERELICT, {&"seed": _seed_for(PoiScript.DERELICT_DATA_CORE)})
	var scanner := _player(poi.global_position)
	assert_eq(int(poi.call(&"scan", scanner)), PoiScript.SCAN_OK, "the channel starts")
	poi.call(&"advance_scan", PoiScript.SCAN_SECONDS + 0.1)
	assert_eq(
		int(profile.call(&"credits")) - before,
		PoiScript.DATA_CORE_CREDITS,
		"the data core pays DATA_CORE_CREDITS"
	)
	var items := _pickup_items(poi)
	assert_true(items.has(&"comp_elec_1"), "and 03's comp_elec rides a pickup")


func test_derelict_cache_pays_a_component_stack_and_no_credits() -> void:
	var profile := _store()
	if profile == null:
		return
	var before := int(profile.call(&"credits"))
	var poi := _live_poi(PoiScript.KIND_DERELICT, {&"seed": _seed_for(PoiScript.DERELICT_CACHE)})
	var scanner := _player(poi.global_position)
	poi.call(&"scan", scanner)
	poi.call(&"advance_scan", PoiScript.SCAN_SECONDS + 0.1)
	assert_eq(int(profile.call(&"credits")), before, "the cache pays no credits")
	var items := _pickup_items(poi)
	assert_true(items.has(PoiScript.DERELICT_CACHE_ITEM), "the cache is a component pickup")
	var spawned: Array = poi.call(&"pickups")
	assert_true(
		not spawned.is_empty() and spawned[0].is_in_group(PickupScript.PICKUP_GROUP),
		"and it is a real 02 §7.1 pickup"
	)
	assert_true(
		int(items.get(PoiScript.DERELICT_CACHE_ITEM, 0)) >= PoiScript.DERELICT_CACHE_MIN
		and int(items.get(PoiScript.DERELICT_CACHE_ITEM, 0)) <= PoiScript.DERELICT_CACHE_MAX,
		"its stack sits inside the file's own bounds"
	)


func test_derelict_module_reward_mints_a_derelict_instance() -> void:
	var profile := _store()
	if profile == null:
		return
	var before: Dictionary = profile.call(&"modules")
	var poi := _live_poi(PoiScript.KIND_DERELICT, {&"seed": _seed_for(PoiScript.DERELICT_MODULE)})
	var scanner := _player(poi.global_position)
	poi.call(&"scan", scanner)
	poi.call(&"advance_scan", PoiScript.SCAN_SECONDS + 0.1)
	var after: Dictionary = profile.call(&"modules")
	assert_eq(after.size(), before.size() + 1, "the module reward mints one instance")
	var minted := ""
	for key: Variant in after:
		if not before.has(key):
			minted = str(key)
	assert_true(not minted.is_empty(), "the minted instance is a new record")
	if minted.is_empty():
		return
	var record: Dictionary = after[minted]
	var base := StringName(record.get("base_id", &""))
	assert_true(ModuleCatalogScript.MODULES.has(base), "%s is a catalogue module" % base)
	assert_false(
		ModuleCatalogScript.EXCLUSIVES.has(base),
		"and not one of 15 §5's faction exclusives"
	)
	assert_true(
		StringName(record.get("rarity", &"")) in [
			StringName(ModuleCatalogScript.RARITY_MAGIC),
			StringName(ModuleCatalogScript.RARITY_RARE),
		],
		"15 §2's derelict source never pays Common (the doc's magic-rarity promise)"
	)


## ---------------------------------------------------------------------------
## The anomaly kinds (11 §3.2/§5)
## ---------------------------------------------------------------------------


## Equal weights over the three kinds, except the Hollows (sector 6) doubles the rift.
func test_anomaly_kinds_and_the_hollows_weighting() -> void:
	var sector_1 := _anomaly_rates(&"sector_1")
	var sector_6 := _anomaly_rates(&"sector_6")
	for kind_name: StringName in PoiScript.ANOMALY_KINDS:
		assert_true(
			float(sector_1[kind_name]) > 0.0, "%s rolls outside the Hollows too" % kind_name
		)
	assert_true(
		absf(float(sector_1[PoiScript.ANOMALY_VOID_RIFT]) - 1.0 / 3.0) <= PP,
		"a normal sector's rift is 1/3 (11 §3.2)"
	)
	assert_true(
		absf(float(sector_6[PoiScript.ANOMALY_VOID_RIFT]) - 0.5) <= PP,
		"the Hollows' rift is 2x weight (11 §5)"
	)
	assert_eq(
		int(PoiScript.anomaly_weights(&"sector_6")[PoiScript.ANOMALY_VOID_RIFT]),
		2,
		"and its weight is the doubled one"
	)


## 11 §3.2's ore bloom: a T+1 cluster of 10 rocks at 2× yield.
func test_ore_bloom_spawns_ten_rocks_a_tier_up_at_double_yield() -> void:
	var poi := _bare_poi(
		PoiScript.KIND_ANOMALY,
		{&"sector_id": &"sector_1", &"anomaly_kind": PoiScript.ANOMALY_ORE_BLOOM, &"seed": 7}
	)
	poi.call(&"trigger", _player(Vector2.ZERO))
	var rocks := _rocks(poi)
	assert_eq(rocks.size(), PoiScript.ORE_BLOOM_ROCKS, "10 rocks, 11 §3.2")
	var expected_tier := mini(
		PoiScript.sector_band(1) + PoiScript.ORE_BLOOM_TIER_BONUS, 4
	)
	assert_eq(expected_tier, 2, "sector 1 is T1, so the bloom is T2")
	for rock: Node2D in rocks:
		assert_eq(int(rock.get(&"tier")), expected_tier, "every rock is T+1")
		var units := int(rock.get(&"yield_units"))
		assert_eq(units % PoiScript.ORE_BLOOM_YIELD_MULT, 0, "the yield is doubled")
		assert_true(units >= 2, "and never zero")
	assert_true(bool(poi.call(&"is_consumed")), "the event is one-shot")


## 11 §3.2's grave cache: 3-5 pickups of components one grade above the sector band.
func test_grave_cache_spawns_three_to_five_grade_up_pickups() -> void:
	var poi := _bare_poi(
		PoiScript.KIND_ANOMALY,
		{&"sector_id": &"sector_1", &"anomaly_kind": PoiScript.ANOMALY_GRAVE_CACHE, &"seed": 8}
	)
	poi.call(&"trigger", _player(Vector2.ZERO))
	var items := _pickup_items(poi)
	var total := 0
	for item: StringName in items:
		total += int(items[item])
		var entry: Dictionary = ComponentCatalogScript.component(item)
		assert_false(entry.is_empty(), "%s is a 03 component" % item)
		assert_eq(
			int(entry.get(&"grade", 0)),
			mini(
				PoiScript.sector_band(1) + PoiScript.GRAVE_CACHE_GRADE_BONUS,
				PoiScript.GRAVE_CACHE_GRADE_CEILING
			),
			"%s is one grade above the sector band" % item
		)
	assert_true(
		total >= PoiScript.GRAVE_CACHE_MIN and total <= PoiScript.GRAVE_CACHE_MAX,
		"3-5 pickups, 11 §3.2"
	)


## 11 §3.2's void rift: `RIFT_DRAIN` shield/s inside 200 u (and only for the rift),
## plus the exotic at its heart.
func test_void_rift_drains_shields_at_the_pinned_rate() -> void:
	var poi := _bare_poi(
		PoiScript.KIND_ANOMALY,
		{&"sector_id": &"sector_1", &"anomaly_kind": PoiScript.ANOMALY_VOID_RIFT, &"seed": 9}
	)
	var inside := _player(Vector2(100.0, 0.0))
	var outside := _player(Vector2(PoiScript.ANOMALY_TRIGGER_RADIUS + 1.0, 0.0))
	assert_eq(
		float(poi.call(&"update_presence", 1.0, inside)), 0.0, "an untriggered rift drains nothing"
	)
	poi.call(&"trigger", inside)
	assert_eq(
		float(poi.call(&"update_presence", 1.0, inside)),
		Registry.RIFT_DRAIN,
		"12 shield/s inside (11 §5)"
	)
	assert_eq(
		float(poi.call(&"update_presence", 0.5, inside)),
		Registry.RIFT_DRAIN * 0.5,
		"and it scales with the step"
	)
	assert_eq(
		float(poi.call(&"update_presence", 1.0, outside)), 0.0, "outside its radius, nothing"
	)
	var bloom := _bare_poi(
		PoiScript.KIND_ANOMALY,
		{&"sector_id": &"sector_1", &"anomaly_kind": PoiScript.ANOMALY_ORE_BLOOM, &"seed": 10}
	)
	bloom.call(&"trigger", inside)
	assert_eq(
		float(bloom.call(&"update_presence", 1.0, inside)), 0.0, "only the rift drains"
	)


## The rift's exotic: T4 ore, or a module at 0.10 (11 §3.2). The module rate is
## measured on the pure roll so 10 000 rifts need no scene.
func test_void_rift_exotic_is_t4_ore_or_a_module_at_ten_percent() -> void:
	var modules := 0
	for index in SAMPLE_COUNT:
		if PoiScript.roll_rift_exotic(SAMPLE_SEED + index):
			modules += 1
	var rate := float(modules) / float(SAMPLE_COUNT)
	assert_true(
		absf(rate - PoiScript.RIFT_EXOTIC_MODULE_CHANCE) <= PP,
		"the module rides %.4f vs 0.10" % rate
	)
	var poi := _bare_poi(
		PoiScript.KIND_ANOMALY,
		{&"sector_id": &"sector_7", &"anomaly_kind": PoiScript.ANOMALY_VOID_RIFT, &"seed": 3}
	)
	poi.call(&"trigger", _player(Vector2.ZERO))
	var items := _pickup_items(poi)
	assert_eq(items.size(), 1, "one exotic pickup when the roll is the ore")
	var item: StringName = items.keys()[0]
	assert_true(MineralCatalogScript.is_ore(item), "%s is an ore item id" % item)
	assert_eq(
		int(MineralCatalogScript.entry_for_item(item).get(&"tier", 0)),
		PoiScript.RIFT_EXOTIC_TIER,
		"and it is a T4 ore"
	)


## ---------------------------------------------------------------------------
## Beacons, fog and the sector (11 §3.3/§5)
## ---------------------------------------------------------------------------


## The beacon is the revealer (11 §3.3): scanning one clears the sector's fog, and the
## sector's own POI counts hold.
func test_beacon_reveals_the_sectors_unscanned_pois() -> void:
	var sector := _bare_sector()
	sector.call(&"populate", _row(&"sector_3"), 4242)
	var derelicts: Array = sector.call(&"derelicts")
	var anomalies: Array = sector.call(&"anomalies")
	var beacons: Array = sector.call(&"beacons")
	assert_true(beacons.size() >= 1, "a sector has at least one beacon (11 §3)")
	assert_true(derelicts.size() >= 1, "and a wreck field's derelict")
	for poi: Node2D in derelicts:
		assert_false(bool(poi.call(&"is_revealed")), "a derelict starts fogged")
	for poi: Node2D in anomalies:
		assert_false(bool(poi.call(&"is_revealed")), "an anomaly starts fogged")
	for poi: Node2D in beacons:
		assert_true(bool(poi.call(&"is_revealed")), "a beacon is a nav aid and always shows")
	var beacon: Node2D = beacons[0]
	assert_eq(int(beacon.call(&"scan", _player(Vector2.ZERO))), PoiScript.SCAN_OK, "scan it")
	for poi: Node2D in derelicts:
		assert_true(bool(poi.call(&"is_revealed")), "the beacon revealed the derelicts")
	for poi: Node2D in anomalies:
		assert_true(bool(poi.call(&"is_revealed")), "and the anomalies")


## 11 §5's soft fog in `blips()`: unrevealed POIs are absent, revealed ones are
## `neutral`, beacons and wreck sites are `friendly`/`neutral` and always present.
func test_blips_apply_the_soft_fog() -> void:
	var sector := _bare_sector()
	sector.call(&"populate", _row(&"sector_3"), 4243)
	var fields: int = (sector.call(&"fields") as Array).size()
	var gates: int = (sector.call(&"gates") as Array).size()
	var beacons: int = (sector.call(&"beacons") as Array).size()
	var poIs: int = (sector.call(&"derelicts") as Array).size() \
		+ (sector.call(&"anomalies") as Array).size()
	var neutral_hulls := 0
	for ship: Node2D in sector.call(&"npcs"):
		if StringName(ship.call(&"blip_kind")) == NpcRegistryScript.BLIP_NEUTRAL:
			neutral_hulls += 1
	var fogged := _blip_kinds(sector)
	assert_eq(
		int(fogged.get(&"neutral", 0)),
		fields + neutral_hulls,
		"only the fields and the convoys blip neutral while every POI is fogged"
	)
	assert_eq(
		int(fogged.get(&"friendly", 0)),
		gates + beacons + 1,
		"the station, the gates and the beacons are the friendly blips"
	)
	sector.call(&"reveal_pois")
	var revealed := _blip_kinds(sector)
	assert_eq(
		int(revealed.get(&"neutral", 0)),
		fields + neutral_hulls + poIs,
		"a beacon reveal adds one neutral blip per POI"
	)


## A wreck site (06 §4) is in the feed as `neutral` from its first frame, and the
## kill path leaves one at the kill point holding the band roll's payload.
func test_kill_path_leaves_a_wreck_site_holding_its_payload() -> void:
	var scene := _open_game()
	assert_true(scene != null, "game.tscn instantiates")
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	assert_true(sector != null, "the scene populated a sector")
	if sector == null:
		return
	var victim := StubHull.new()
	victim.name = &"StubVictim"
	_fixture_host().add_child(victim)
	_bare.append(victim)
	var kill_point := Vector2(1234.0, -432.0)
	scene.call(&"_on_npc_died", kill_point, &"pirate", victim)
	var wrecks: Array = sector.call(&"wrecks")
	assert_eq(wrecks.size(), 1, "the kill left exactly one wreck site")
	if wrecks.is_empty():
		return
	var site: Node2D = wrecks[0]
	assert_eq(
		site.global_position, kill_point, "the site sits on the kill point"
	)
	assert_true(bool(site.call(&"is_revealed")), "a wreck site is visible at once")
	assert_eq(
		StringName(site.call(&"blip_kind")), PoiScript.BLIP_NEUTRAL, "and blips neutral"
	)
	var kinds := _blip_kinds(sector)
	assert_true(int(kinds.get(&"neutral", 0)) >= 1, "so it is in the feed")
	## The payload is the fighter table's own lines (the stub hull's loot kind), one
	## pickup per paying line, inside each line's `randi_range` (06 §2).
	var ranges := {}
	for line: Dictionary in LootTablesScript.TABLES[&"fighter"][&"lines"]:
		ranges[line[&"item"]] = [int(line[&"min"]), int(line[&"max"])]
	for pickup: Node2D in site.call(&"pickups"):
		var item := StringName(pickup.get(&"item_id"))
		assert_true(ranges.has(item), "%s is a fighter-table line" % item)
		if not ranges.has(item):
			continue
		var bounds: Array = ranges[item]
		var amount := int(pickup.get(&"amount"))
		assert_true(
			amount >= int(bounds[0]) and amount <= int(bounds[1]),
			"%s amount %d sits inside %s" % [item, amount, bounds]
		)


## 06 §4: the wreck site holds its pickups for 90 s and then frees them.
func test_wreck_site_despawns_after_ninety_seconds() -> void:
	var payload: Array[Dictionary] = [
		{LootTablesScript.KEY_ITEM: &"comp_scrap_1", LootTablesScript.KEY_AMOUNT: 2, LootTablesScript.KEY_CACHE: false},
		{LootTablesScript.KEY_ITEM: &"credits", LootTablesScript.KEY_AMOUNT: 55, LootTablesScript.KEY_CACHE: true},
	]
	var site := _bare_poi(PoiScript.KIND_WRECK, {&"payload": payload})
	assert_eq((site.call(&"pickups") as Array).size(), 2, "the payload is aboard")
	assert_false(
		bool(site.call(&"advance_lifetime", LootTablesScript.WRECK_PICKUP_LIFETIME - 0.1)),
		"the window is still open at 89.9 s"
	)
	assert_eq((site.call(&"pickups") as Array).size(), 2, "and the pickups are still held")
	assert_true(
		bool(site.call(&"advance_lifetime", 0.2)), "90 s closes the window"
	)
	assert_true(bool(site.call(&"is_expired")), "the site reports expired")
	assert_eq((site.call(&"pickups") as Array).size(), 0, "and its pickups are gone")


## 06 §5's feed hook: a credit cache leaving the world while the site is open reports
## what it paid, and the site's own release at 90 s does not (that is not a collection).
func test_wreck_cache_reports_its_collection_but_not_its_release() -> void:
	var payload: Array[Dictionary] = [
		{LootTablesScript.KEY_ITEM: &"credits", LootTablesScript.KEY_AMOUNT: 77, LootTablesScript.KEY_CACHE: true},
	]
	var site := _live_poi(PoiScript.KIND_WRECK, {&"payload": payload})
	var collected: Array[int] = []
	site.cache_collected.connect(func(amount: int) -> void: collected.append(amount))
	var pickups: Array = site.call(&"pickups")
	assert_eq(pickups.size(), 1, "the cache is aboard")
	var cache: Node2D = pickups[0]
	cache.free()
	assert_eq(collected, [77] as Array[int], "a collected cache reports its credits")
	site.call(&"advance_lifetime", LootTablesScript.WRECK_PICKUP_LIFETIME + 1.0)
	assert_eq(collected, [77] as Array[int], "the release at 90 s reports nothing")


## The K1↔K2 seam: the scene's own scan tick drives the nearest scannable POI, and a
## beacon in range clears the sector's fog (11 §3.3) without a scanner (a beacon is a
## nav aid, not 11 §3.1's C-slot requirement).
func test_the_scene_scan_tick_reveals_through_a_beacon() -> void:
	var scene := _open_game()
	assert_true(scene != null, "game.tscn instantiates")
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	assert_true(sector != null and ship != null, "the scene has a sector and a ship")
	if sector == null or ship == null:
		return
	var beacons: Array = sector.call(&"beacons")
	assert_true(beacons.size() >= 1, "the sector spawned a beacon")
	if beacons.is_empty():
		return
	var derelicts: Array = sector.call(&"derelicts")
	assert_true(derelicts.size() >= 1, "and a derelict to reveal")
	if derelicts.is_empty():
		return
	ship.global_position = (beacons[0] as Node2D).global_position
	scene.call(&"_update_scan", 0.016)
	for poi: Node2D in derelicts:
		assert_true(bool(poi.call(&"is_revealed")), "the beacon cleared the fog")
	assert_true(ship.has_method(&"take_damage"), "and the ship has the rift's sink")


## The K1↔K2 seam for the hazard: the scene's POI tick fires the 200 u anomaly event
## and applies the rift's drain through the ship's own damage sink (11 §3.2/§5).
func test_the_scene_poi_tick_fires_the_anomaly_and_drains_the_rift() -> void:
	var scene := _open_game()
	assert_true(scene != null, "game.tscn instantiates")
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	var state: Variant = scene.get(&"_state")
	var anomalies: Array = sector.call(&"anomalies")
	assert_true(anomalies.size() >= 1, "the sector spawned an anomaly")
	if anomalies.is_empty():
		return
	var rift: Node2D = anomalies[0]
	rift.set(&"anomaly_kind", PoiScript.ANOMALY_VOID_RIFT)
	ship.global_position = rift.global_position
	var before := float(state.shield)
	scene.call(&"_update_pois", 1.0)
	assert_true(bool(rift.call(&"is_consumed")), "the 200 u event fired")
	assert_eq(
		float(state.shield),
		before - Registry.RIFT_DRAIN,
		"and the rift drained RIFT_DRAIN through the ship's sink"
	)


## The sector's respawn cycle re-arms its POIs on the one clock (17 §4): a spent
## derelict comes back unscanned, and the sector owns no timer of its own.
func test_the_sector_clock_re_arms_the_pois() -> void:
	var sector := _bare_sector()
	sector.call(&"populate", _row(&"sector_2"), 4244)
	var derelict: Node2D = (sector.call(&"derelicts") as Array)[0]
	derelict.call(&"reveal")
	derelict.set(&"_one_shot", true)
	sector.call(&"_respawn_cycle")
	assert_false(bool(derelict.call(&"is_consumed")), "the clock re-armed the derelict")
	assert_false(bool(derelict.call(&"is_revealed")), "and the fog is back")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _anomaly_rates(sector_id: StringName) -> Dictionary:
	var counts := {}
	for kind_name: StringName in PoiScript.ANOMALY_KINDS:
		counts[kind_name] = 0
	for index in SAMPLE_COUNT:
		var kind_name := PoiScript.roll_anomaly(sector_id, SAMPLE_SEED + index)
		counts[kind_name] = int(counts.get(kind_name, 0)) + 1
	var rates := {}
	for kind_name: StringName in counts:
		rates[kind_name] = float(counts[kind_name]) / float(SAMPLE_COUNT)
	return rates


## A seed whose derelict reward is `wanted`, so a reward test needs no luck.
func _seed_for(wanted: StringName) -> int:
	for seed_value in range(1, 200000):
		if PoiScript.roll_derelict(seed_value) == wanted:
			return seed_value
	return 1


## 06 §6 check 1's expectation, computed from the doc's own chance/min/max columns a
## second time here (never read off the shipped tables).
func _expected_haul(kind: StringName) -> Dictionary:
	var units := 0.0
	var credits := 0.0
	for line: Dictionary in _doc_lines(kind):
		var chance := float(line[&"chance"])
		var mean := (float(line[&"min"]) + float(line[&"max"])) / 2.0
		var item: StringName = line[&"item"]
		if item == LootTablesScript.CREDIT_ITEM:
			credits += chance * mean
		else:
			units += chance * mean
			credits += chance * mean * float(_value_of(item))
	return {&"units": units, &"credits": credits}


func _sample_haul(kind: StringName) -> Dictionary:
	var units := 0
	var credits := 0
	for index in SAMPLE_COUNT:
		for entry: Dictionary in LootTablesScript.roll_band(kind, SAMPLE_SEED + index):
			var amount := int(entry[LootTablesScript.KEY_AMOUNT])
			if bool(entry[LootTablesScript.KEY_CACHE]):
				credits += amount
			else:
				units += amount
				credits += amount * _value_of(entry[LootTablesScript.KEY_ITEM])
	return {
		&"units": float(units) / float(SAMPLE_COUNT),
		&"credits": float(credits) / float(SAMPLE_COUNT),
	}


## 06 §3's tables, transcribed from the doc (the independent copy the check reads).
func _doc_lines(kind: StringName) -> Array:
	match kind:
		&"fighter", &"swarmer":
			return [
				{&"item": &"comp_scrap_1", &"chance": 0.55, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_1", &"chance": 0.30, &"min": 1, &"max": 1},
				{&"item": &"comp_pow_1", &"chance": 0.35, &"min": 1, &"max": 2},
				{&"item": &"comp_elec_1", &"chance": 0.20, &"min": 1, &"max": 1},
				{&"item": &"cm_chaff", &"chance": 0.15, &"min": 1, &"max": 1},
				{&"item": &"cm_flare", &"chance": 0.15, &"min": 1, &"max": 1},
			]
		&"freighter":
			return [
				{&"item": &"comp_scrap_1", &"chance": 0.60, &"min": 2, &"max": 3},
				{&"item": &"comp_mech_1", &"chance": 0.35, &"min": 1, &"max": 1},
				{&"item": &"comp_ore_1", &"chance": 0.30, &"min": 1, &"max": 2},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 0.15, &"min": 40, &"max": 80},
			]
		&"corvette":
			return [
				{&"item": &"comp_scrap_2", &"chance": 0.50, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_2", &"chance": 0.30, &"min": 1, &"max": 1},
				{&"item": &"comp_mech_2", &"chance": 0.25, &"min": 1, &"max": 1},
				{&"item": &"comp_elec_2", &"chance": 0.20, &"min": 1, &"max": 1},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 0.10, &"min": 120, &"max": 250},
			]
		&"maw":
			return [
				{&"item": &"comp_scrap_3", &"chance": 1.00, &"min": 3, &"max": 5},
				{&"item": &"comp_mech_3", &"chance": 0.75, &"min": 1, &"max": 2},
				{&"item": &"comp_weap_3", &"chance": 0.60, &"min": 1, &"max": 1},
				{&"item": &"comp_elec_3", &"chance": 0.40, &"min": 1, &"max": 1},
				{&"item": &"comp_ore_3", &"chance": 0.25, &"min": 1, &"max": 1},
				{&"item": LootTablesScript.CREDIT_ITEM, &"chance": 1.00, &"min": 800, &"max": 1200},
			]
	return []


## 03 §3's value for an item, 0 for the credit key and the two countermeasures (no
## catalogue row), exactly as `test_engine2_loot.gd` reads it.
func _value_of(item: StringName) -> int:
	if item == LootTablesScript.CREDIT_ITEM:
		return 0
	return int(ComponentCatalogScript.component(item).get(&"value", 0))


func _blip_kinds(sector: Node) -> Dictionary:
	var kinds := {}
	for blip: Dictionary in sector.call(&"blips"):
		var kind := StringName(blip.get("kind", &""))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
	return kinds


## The item ids of a POI's own spawned pickups, summed by id.
func _pickup_items(poi: Node) -> Dictionary:
	var items := {}
	for node: Node in poi.call(&"pickups"):
		var item := StringName(node.get(&"item_id"))
		items[item] = int(items.get(item, 0)) + int(node.get(&"amount"))
	return items


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			out.append(child)
			stack.append(child)
	return out


func _rocks(poi: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for node: Node in _descendants(poi):
		var rock := node as Node2D
		if rock != null and rock.is_in_group(&"asteroid"):
			out.append(rock)
	return out


func _player(at: Vector2) -> StubPlayer:
	var player := StubPlayer.new()
	player.position = at
	_bare.append(player)
	return player


## A POI with no parent: the pure channel/reward logic, with rocks and pickups
## parented to the POI itself.
func _bare_poi(poi_kind: StringName, row: Dictionary) -> Node2D:
	var poi: Node2D = PoiScript.new() as Node2D
	poi.call(&"setup", poi_kind, row)
	_bare.append(poi)
	return poi


## A POI under the profile autoload (the fixture host), so its grants reach the live
## profile. The row's `sector_id` defaults to sector 1.
func _live_poi(poi_kind: StringName, row: Dictionary) -> Node2D:
	var poi: Node2D = PoiScript.new() as Node2D
	_fixture_host().add_child(poi)
	var full := row.duplicate()
	if not full.has(&"sector_id"):
		full[&"sector_id"] = &"sector_1"
	poi.call(&"setup", poi_kind, full)
	_bare.append(poi)
	return poi


func _bare_sector() -> Node2D:
	var sector: Node2D = SectorScript.new() as Node2D
	_bare.append(sector)
	return sector


func _row(sector_id: StringName) -> Dictionary:
	return Registry.sector(sector_id)


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


func _stage_scratch_store() -> void:
	var profile := _store()
	if profile == null:
		return
	_previous_path = String(profile.get(&"save_path"))
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")
	Log.log_path = SCRATCH_LOG


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
