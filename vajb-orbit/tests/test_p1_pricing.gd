@tool
extends McpTestSuite
## P1 pricing suite: the exchange's one pricing function family.
## Contract: docs/gameplay/05_exchange.md sections 3 (the table) and 5 (the
## worked examples), docs/gameplay/17_coder_handoff.md section 6 (the 02/05
## checklist item). File under test: game/exchange.gd.
## Pure static-function assertions: no profile, no cargo, no market state, so
## nothing here can touch user://profile.cfg. The log path is still redirected
## and cleaned up, per the P1 suite rules.
## Scripts are preloaded by path on purpose (project convention).

const Ex := preload("res://game/exchange.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "p1_pricing"
const LOG_PATH := "user://test_p1_log.txt"

## docs/gameplay/05_exchange.md section 3, verbatim, for the four tabled
## ingots: mineral id -> [demand 1.0, demand 0.6, demand 1.6].
const INGOT_TABLE: Dictionary = {
	&"iron": [64, 38, 102],
	&"titanium": [159, 95, 254],
	&"gold": [387, 232, 619],
	&"krilium": [2117, 1270, 3387],
}

const DEMANDS: Array[float] = [1.0, 0.6, 1.6]


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


## 17 section 6, bullet 1: the price function reproduces the 05 section 3 table.
func test_unit_net_reproduces_the_section_3_table() -> void:
	assert_eq(INGOT_TABLE.size(), 4, "the table covers the four tabled minerals")
	for mineral_id: StringName in INGOT_TABLE:
		var entry := Catalog.mineral(mineral_id)
		assert_false(entry.is_empty(), "missing mineral %s" % String(mineral_id))
		var baseline: int = int(entry.get(&"ingot_value", 0))
		var expected: Array = INGOT_TABLE[mineral_id]
		for index: int in DEMANDS.size():
			assert_eq(
				Ex.unit_net(baseline, DEMANDS[index]),
				int(expected[index]),
				"%s ingot at demand %.1f" % [String(Catalog.ingot_id(mineral_id)), DEMANDS[index]]
			)


## 17 section 6, bullet 2: the 05 section 5 batch worked example, exactly.
func test_gold_batch_worked_example() -> void:
	var quote := Ex.sale_quote(395, 1.2, 10)
	assert_eq(int(quote[&"gross"]), 4740, "gross of 10 Gold ingots at demand 1.2")
	assert_eq(int(quote[&"fee"]), 95, "2 percent of 4740")
	assert_eq(int(quote[&"paid"]), 4645, "what the player is paid")
	assert_eq(Ex.unit_gross(395, 1.2), 474, "the quoted unit gross beside the net price")


## 17 section 6, bullet 3: the 05 section 5 component worked example, exactly.
func test_component_worked_example() -> void:
	assert_eq(Ex.component_unit_price(12), 11, "Torn Plating: round(12 x 0.9)")
	var quote := Ex.sale_quote(11, 1.0, 1)
	assert_eq(int(quote[&"gross"]), 11, "gross of one Torn Plating")
	assert_eq(int(quote[&"fee"]), 10, "the 10 CR commission minimum")
	assert_eq(int(quote[&"paid"]), 1, "one credit, as designed")


## 17 section 6, bullet 4: the commission floor, and the zero-gross case.
func test_commission_floor() -> void:
	assert_eq(Ex.commission_for(0), 0, "a zero-gross transaction is not a sale")
	assert_eq(Ex.commission_for(-1), 0, "a negative gross is never charged")
	for gross: int in [1, 2, 5, 11, 250, 499]:
		assert_eq(Ex.commission_for(gross), 10, "gross %d pays the 10 CR floor" % gross)
	assert_eq(Ex.commission_for(500), 10, "2 percent of 500 is exactly the floor")
	assert_eq(Ex.commission_for(501), 11, "above the floor the rate takes over")
	assert_eq(Ex.commission_for(4740), 95, "2 percent of 4740")
	assert_eq(Ex.commission_for(10000), 200, "2 percent of 10000")
	var floor_quote := Ex.sale_quote(1, 1.0, 1)
	assert_eq(int(floor_quote[&"gross"]), 1, "a one-credit gross")
	assert_eq(int(floor_quote[&"fee"]), 10, "the floor exceeds it")
	assert_eq(int(floor_quote[&"paid"]), 0, "and the payout is floored at zero")


## 17 section 6, bullet 5: the routing of the single public price read.
func test_exchange_price_routing() -> void:
	var iron_ore: StringName = Catalog.ore_id(&"iron")
	var iron_ingot: StringName = Catalog.ingot_id(&"iron")
	for demand: float in DEMANDS:
		assert_eq(
			Ex.exchange_price(iron_ore, demand),
			Ex.unit_net(18, demand),
			"Iron ore routes through unit_net at demand %.1f" % demand
		)
		assert_eq(
			Ex.exchange_price(iron_ingot, demand),
			Ex.unit_net(65, demand),
			"Iron ingot routes through unit_net at demand %.1f" % demand
		)
	# 05 section 2's raw-ore aside prints 17 for Iron ore at demand 1.0; the net
	# product is 17.64 and the section 3 table is the authority (exchange.gd
	# header, P1d report), so the round is asserted, not the aside.
	assert_eq(Ex.exchange_price(iron_ore, 1.0), 18, "Iron ore at demand 1.0")
	assert_eq(Ex.exchange_price(&"comp_scrap_1", 1.0), Ex.component_unit_price(12), "component price")
	assert_eq(Ex.exchange_price(&"comp_scrap_1", 1.0), 11, "Torn Plating at demand 1.0")
	assert_eq(Ex.exchange_price(&"comp_scrap_1", 1.6), 11, "components ignore demand")
	# The per-unit base rounds to 465; the batch base rounds the transaction
	# gross once and pays 464.5 per unit (05 section 5). Both are documented in
	# exchange.gd's header, so only the unit base is asserted here.
	assert_eq(Ex.exchange_price(&"ingot_gold", 1.2), 465, "Gold ingot at demand 1.2")
	assert_eq(Ex.exchange_price(&"iron", 1.0), 0, "a bare mineral id has no price")
	assert_eq(Ex.exchange_price(&"nonsense", 1.0), 0, "an unknown id has no price")
	assert_eq(Ex.exchange_price(&"", 1.0), 0, "an empty id has no price")
	assert_eq(Ex.baseline_of(iron_ore), 18, "ore baseline is ore_value")
	assert_eq(Ex.baseline_of(iron_ingot), 65, "ingot baseline is ingot_value")
	assert_eq(Ex.baseline_of(&"comp_ore_3"), 140, "component baseline is value")
	assert_eq(Ex.baseline_of(&"iron"), 0, "a bare mineral id has no baseline")
	assert_eq(Ex.baseline_of(&"nonsense"), 0, "an unknown id has no baseline")
