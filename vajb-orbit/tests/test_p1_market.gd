@tool
extends McpTestSuite
## Suite p1_market: the exchange's band-driven demand model and its two books
## (docs/gameplay/05_exchange.md sections 2 and 4, docs/gameplay/17_coder_handoff.md
## sections 4 and 5).
##
## Pure logic: no scene instancing, no editor API, no MCP. Every profile is a
## throwaway `PlayerProfile` instance whose save_path is repointed at a scratch
## file before the first mutation, and the economy log is repointed at a scratch
## file truncated before every test. `user://profile.cfg` and
## `user://economy_log.txt` are never touched.

const Exch := preload("res://game/exchange.gd")
const Minerals := preload("res://game/mineral_catalog.gd")
const Catalog := preload("res://game/component_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")
const Profile := preload("res://autoload/player_profile.gd")

const PROFILE_PATH := "user://test_p1_market.cfg"
const LOG_PATH := "user://test_p1_log.txt"

## A fixed, non-zero stamp: `bands_between` refuses 0 stamps, so the suites
## never use 0 as "now".
const NOW := 1000000

var _profiles: Array[Node] = []

## Re-entrancy fixture for the sale tests below: the listener records how often it ran and
## quotes a later band once, so the sale's write-back is exercised against a newer snapshot.
var _reentrant_profile: Node = null
var _reentrant_quotes := 0


func suite_name() -> String:
	return "p1_market"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_reset_log()
	Clock.set_override(NOW)


func teardown() -> void:
	Clock.clear_override()
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	_reentrant_profile = null
	_reentrant_quotes = 0


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(LOG_PATH)
	Log.log_path = Log.DEFAULT_PATH
	Clock.clear_override()


## ---------------------------------------------------------------------------
## Market evaluation
## ---------------------------------------------------------------------------


func test_first_evaluation_stamps_and_restocks() -> void:
	var profile = _fresh()
	assert_eq(Exch.evaluate_market(profile, NOW), 0, "a never-evaluated market only stamps")
	var market: Dictionary = profile.market()
	assert_eq(int(market["last_band"]), NOW)
	var demand: Dictionary = market["demand"]
	assert_true(demand.is_empty(), "the stamping pass applies no drift")
	var stock: Dictionary = market["stock"]
	assert_eq(stock.size(), Catalog.COMPONENTS.size(), "every component is stocked")
	assert_eq(int(stock["comp_scrap_1"]), 40, "grade I quota (05 section 4 table)")
	assert_eq(int(stock["comp_scrap_2"]), 15, "grade II quota (05 section 4 table)")
	assert_eq(int(stock["comp_scrap_3"]), 4, "grade III quota (05 section 4 table)")
	for entry: Dictionary in Catalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		var grade := int(entry.get(&"grade", 0))
		assert_eq(
			int(stock.get(String(component_id), -1)),
			Exch.quota_for(grade),
			"%s must be stocked to its grade %d quota" % [component_id, grade]
		)
	assert_eq(Exch.quota_for(1), 40)
	assert_eq(Exch.quota_for(2), 15)
	assert_eq(Exch.quota_for(3), 4)
	assert_eq(Exch.demand_of(profile, &"mineral_iron"), 1.0, "demand starts at 1.0")
	# A second evaluation with no time passed is a no-op.
	assert_eq(Exch.evaluate_market(profile, NOW), 0)
	assert_eq(int(profile.market()["last_band"]), NOW)


func test_one_band_drifts_within_range() -> void:
	var profile = _fresh()
	assert_eq(Exch.evaluate_market(profile, NOW), 0)
	var seed := 20260918
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	assert_eq(Exch.evaluate_market(profile, NOW + Clock.BAND_SECONDS, rng), 1, "one band")
	var market: Dictionary = profile.market()
	assert_eq(int(market["last_band"]), NOW + Clock.BAND_SECONDS, "the stamp advances")
	var demand: Dictionary = market["demand"]
	var trend: Dictionary = market["trend"]
	var ids := Minerals.mineral_ids()
	assert_eq(demand.size(), ids.size(), "every mineral has a demand index")
	# Mirror the seeded step sequence: one randf_range per mineral, catalogue order.
	var mirror := RandomNumberGenerator.new()
	mirror.seed = seed
	for mineral_id: StringName in ids:
		var step: float = mirror.randf_range(-Exch.DEMAND_STEP, Exch.DEMAND_STEP)
		var expected: float = clampf(Exch.DEMAND_DEFAULT + step, Exch.DEMAND_MIN, Exch.DEMAND_MAX)
		var actual: float = float(demand[String(mineral_id)])
		assert_true(
			actual >= Exch.DEMAND_MIN and actual <= Exch.DEMAND_MAX,
			"%s left the band: %f" % [mineral_id, actual]
		)
		assert_true(
			absf(actual - expected) < 0.000001,
			"%s expected %f, got %f" % [mineral_id, expected, actual]
		)
		assert_eq(
			int(trend[String(mineral_id)]),
			int(signf(step)),
			"trend for %s must match the seeded step" % mineral_id
		)


func test_three_bands_in_one_call() -> void:
	var profile = _fresh()
	assert_eq(Exch.evaluate_market(profile, NOW), 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	assert_eq(
		Exch.evaluate_market(profile, NOW + 3 * Clock.BAND_SECONDS, rng), 3, "3600s is three bands"
	)
	assert_eq(int(profile.market()["last_band"]), NOW + 3 * Clock.BAND_SECONDS)
	for mineral_id: StringName in Minerals.mineral_ids():
		var demand: float = Exch.demand_of(profile, mineral_id)
		assert_true(
			demand >= Exch.DEMAND_MIN and demand <= Exch.DEMAND_MAX,
			"%s left the band after three drifts: %f" % [mineral_id, demand]
		)


func test_drift_clamps_at_ceiling() -> void:
	var profile = _fresh()
	assert_eq(Exch.evaluate_market(profile, NOW), 0)
	_force_demand(profile, &"iron", 1.55)
	var seed := _seed_with_first_step(0.1, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	assert_eq(Exch.evaluate_market(profile, NOW + Clock.BAND_SECONDS, rng), 1)
	var demand: float = Exch.demand_of(profile, &"mineral_iron")
	assert_true(demand > 1.55, "the positive step moved the index up")
	assert_true(demand <= Exch.DEMAND_MAX, "clamped to the ceiling: %f" % demand)
	assert_eq(demand, Exch.DEMAND_MAX, "1.55 + >= 0.10 clamps to 1.6")
	assert_eq(int(profile.market()["trend"]["iron"]), 1, "trend records the sign")


func test_drift_clamps_at_floor() -> void:
	var profile = _fresh()
	assert_eq(Exch.evaluate_market(profile, NOW), 0)
	_force_demand(profile, &"iron", 0.65)
	var seed := _seed_with_first_step(0.1, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	assert_eq(Exch.evaluate_market(profile, NOW + Clock.BAND_SECONDS, rng), 1)
	var demand: float = Exch.demand_of(profile, &"mineral_iron")
	assert_true(demand < 0.65, "the negative step moved the index down")
	assert_true(demand >= Exch.DEMAND_MIN, "clamped to the floor: %f" % demand)
	assert_eq(demand, Exch.DEMAND_MIN, "0.65 - >= 0.10 clamps to 0.6")
	assert_eq(int(profile.market()["trend"]["iron"]), -1, "trend records the sign")


## ---------------------------------------------------------------------------
## Transactions
## ---------------------------------------------------------------------------


func test_mineral_sale_quote_and_payment() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 10)
	var quote: Dictionary = Exch.quote(profile, &"mineral_iron", 10, NOW)
	assert_true(bool(quote["ok"]))
	assert_eq(quote["kind"], Exch.KIND_MINERAL)
	assert_eq(int(quote["sellable"]), 10)
	assert_eq(int(quote["queued"]), 0)
	assert_eq(int(quote["stock"]), 0)
	assert_eq(quote["demand"], 1.0)
	assert_eq(int(quote["gross"]), 180, "10 iron ore at demand 1.0")
	assert_eq(int(quote["fee"]), 10, "2% floor")
	assert_eq(int(quote["paid"]), 170)
	assert_eq(profile.cargo_qty(&"mineral_iron"), 10, "a quote takes nothing")
	assert_eq(profile.credits(), 10000, "a quote pays nothing")
	assert_eq(_log_lines().size(), 0, "a quote logs nothing")

	var sale: Dictionary = Exch.sell(profile, &"mineral_iron", 10, NOW)
	assert_true(bool(sale["ok"]))
	assert_eq(int(sale["paid"]), 170)
	assert_eq(profile.cargo_qty(&"mineral_iron"), 0, "the hold is empty")
	assert_true(profile.cargo_items().is_empty())
	assert_eq(profile.credits(), 10170)
	assert_eq(Exch.demand_of(profile, &"mineral_iron"), 0.9, "one trade impact of 0.10")
	var lines := _log_lines()
	assert_eq(lines.size(), 1, "exactly one SELL line")
	var fields := lines[0].split(", ")
	assert_eq(fields.size(), 6)
	assert_eq(fields[1], "SELL")
	assert_eq(fields[2], "mineral_iron")
	assert_eq(fields[3], "10")
	assert_eq(fields[4], "+170")
	assert_eq(fields[5], "10170")


func test_sale_demand_floor() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 200)
	var sale: Dictionary = Exch.sell(profile, &"mineral_iron", 100, NOW)
	assert_true(bool(sale["ok"]))
	assert_eq(Exch.demand_of(profile, &"mineral_iron"), 0.6, "demand floors at 0.6")
	assert_eq(Exch.demand_of(profile, &"mineral_copper"), 1.0, "other minerals are untouched")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 100)


## F2 regression: `sell` re-reads the market before it writes the trade deltas back, so a
## `profile_changed` listener that quotes during the sale cannot have its newer snapshot
## (a drifted book stamped to a later band) rolled back by the sale's older copy.
func test_reentrant_quote_during_a_sale_keeps_the_fresh_market() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 10)
	## A second stack, still in the hold when the listener fires: the panel-style refresh
	## quotes a stack it can quote.
	profile.add_cargo(&"mineral_copper", 4)
	assert_eq(Exch.evaluate_market(profile, NOW), 0, "settle the market first")
	var demand_before: float = Exch.demand_of(profile, &"mineral_iron")
	assert_eq(demand_before, 1.0, "the pre-sale demand")

	_reentrant_profile = profile
	_reentrant_quotes = 0
	profile.profile_changed.connect(_on_reentrant_profile_changed)
	var sale: Dictionary = Exch.sell(profile, &"mineral_iron", 10, NOW)
	profile.profile_changed.disconnect(_on_reentrant_profile_changed)
	_reentrant_profile = null

	assert_gt(_reentrant_quotes, 0, "the listener ran inside the sale")
	assert_true(bool(sale["ok"]))
	assert_eq(int(sale["paid"]), 170, "the payout is the quoted one, untouched by the re-entry")
	assert_eq(profile.credits(), 10170, "credits match the quote")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 0, "cargo matches the quote")
	assert_eq(
		Exch.demand_of(profile, &"mineral_iron"),
		demand_before - 0.10,
		"the trade impact lands on the pre-sale demand"
	)
	assert_eq(
		int(profile.market()["last_band"]),
		NOW + Clock.BAND_SECONDS,
		"the re-entrant evaluation's stamp survives the sale"
	)
	var demand: Dictionary = profile.market()["demand"]
	assert_eq(
		demand.size(),
		Minerals.mineral_ids().size(),
		"the re-entrant pass's drifted book survives the sale"
	)
	assert_true(demand.has("iron"), "the sold mineral keeps its index")
	assert_eq(profile.cargo_qty(&"mineral_copper"), 4, "the quoted stack is untouched")


func test_component_sale_respects_quota() -> void:
	var profile = _fresh()
	profile.add_cargo(&"comp_scrap_1", 50)
	var sale: Dictionary = Exch.sell(profile, &"comp_scrap_1", 50, NOW)
	assert_true(bool(sale["ok"]))
	assert_eq(sale["kind"], Exch.KIND_COMPONENT)
	assert_eq(int(sale["sellable"]), 40, "the grade I quota")
	assert_eq(int(sale["queued"]), 10, "the overflow waits for the next band")
	assert_eq(int(sale["unit"]), 11, "round(12 * 0.9)")
	assert_eq(int(sale["gross"]), 440)
	assert_eq(int(sale["fee"]), 10)
	assert_eq(int(sale["paid"]), 430)
	assert_eq(profile.credits(), 10430)
	assert_eq(profile.cargo_qty(&"comp_scrap_1"), 0, "the whole stack changes hands")
	var market: Dictionary = profile.market()
	assert_eq(int(market["stock"]["comp_scrap_1"]), 0, "the quota is consumed")
	assert_eq(int(market["queue"]["comp_scrap_1"]), 10, "the overflow is queued")
	var lines := _log_lines()
	assert_eq(lines.size(), 2, "one SELL plus one QUEUE line")
	assert_eq(lines[0].split(", ")[1], "SELL")
	assert_eq(lines[1].split(", ")[1], "QUEUE")
	assert_eq(lines[1].split(", ")[3], "10")
	assert_eq(lines[1].split(", ")[4], "+0")


func test_queue_payout_on_next_band() -> void:
	var profile = _fresh()
	profile.add_cargo(&"comp_scrap_1", 50)
	Exch.sell(profile, &"comp_scrap_1", 50, NOW)
	assert_eq(profile.credits(), 10430)
	assert_eq(Exch.evaluate_market(profile, NOW + Clock.BAND_SECONDS), 1)
	var market: Dictionary = profile.market()
	assert_eq(int(market["queue"]["comp_scrap_1"]), 0, "the queue flushed")
	assert_eq(
		int(market["stock"]["comp_scrap_1"]),
		30,
		"restocked to 40, then drawn down by the 10 queued units"
	)
	assert_eq(profile.credits(), 10530, "gross 110, fee 10, paid 100")
	var lines := _log_lines()
	assert_eq(lines.size(), 3, "SELL, QUEUE, QUEUE_BUY")
	var last := lines[lines.size() - 1].split(", ")
	assert_eq(last[1], "QUEUE_BUY")
	assert_eq(last[2], "comp_scrap_1")
	assert_eq(last[3], "10")
	assert_eq(last[4], "+100")
	assert_eq(last[5], "10530")


func test_queue_with_empty_stock_pays_nothing() -> void:
	var profile = _fresh()
	profile.add_cargo(&"comp_scrap_1", 80)
	Exch.sell(profile, &"comp_scrap_1", 40, NOW)
	assert_eq(profile.credits(), 10430)
	assert_eq(int(profile.market()["stock"]["comp_scrap_1"]), 0, "quota spent")
	var credits_before: int = profile.credits()
	var sale: Dictionary = Exch.sell(profile, &"comp_scrap_1", 10, NOW)
	assert_true(bool(sale["ok"]), "a stack the station cannot take is still accepted")
	assert_eq(int(sale["sellable"]), 0)
	assert_eq(int(sale["queued"]), 10)
	assert_eq(int(sale["gross"]), 0)
	assert_eq(int(sale["fee"]), 0, "no sale, so no commission floor")
	assert_eq(int(sale["paid"]), 0)
	assert_eq(profile.credits(), credits_before, "a queued stack pays nothing yet")
	assert_eq(profile.cargo_qty(&"comp_scrap_1"), 30, "the goods still change hands")
	assert_eq(int(profile.market()["queue"]["comp_scrap_1"]), 10)


func test_sell_all_skips_ingots() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 10)
	profile.add_cargo(&"mineral_copper", 4)
	profile.add_cargo(&"ingot_iron", 5)
	profile.add_cargo(&"comp_scrap_1", 50)
	var bulk: Dictionary = Exch.sell_all(profile, NOW)
	assert_true(bool(bulk["ok"]), "nothing refused")
	var skipped: Array = bulk["skipped"]
	assert_true(skipped.is_empty())
	var lines: Array = bulk["lines"]
	assert_eq(lines.size(), 3, "two ore stacks plus one component stack")
	var total := 0
	for line: Variant in lines:
		var entry: Dictionary = line
		total += int(entry["paid"])
		assert_ne(entry["item"], &"ingot_iron", "ingots are never bulk sold")
	assert_eq(int(bulk["paid"]), total, "the total equals the sum of the lines")
	assert_eq(total, 678, "170 iron + 78 copper + 430 components")
	assert_eq(profile.credits(), 10678)
	assert_eq(profile.cargo_qty(&"ingot_iron"), 5, "ingots stay in the hold")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 0)
	assert_eq(profile.cargo_qty(&"mineral_copper"), 0)
	assert_eq(profile.cargo_qty(&"comp_scrap_1"), 0)


func test_refusals_leave_state_untouched() -> void:
	var profile = _fresh()
	profile.add_cargo(&"mineral_iron", 3)
	assert_eq(Exch.evaluate_market(profile, NOW), 0, "settle the market first")
	var cargo_before: Dictionary = profile.cargo_items()
	var credits_before: int = profile.credits()
	var market_before: Dictionary = profile.market()

	var zero: Dictionary = Exch.sell(profile, &"mineral_iron", 0, NOW)
	assert_false(bool(zero["ok"]))
	assert_eq(zero["reason"], Exch.REASON_INVALID_QTY)
	var negative: Dictionary = Exch.sell(profile, &"mineral_iron", -5, NOW)
	assert_eq(negative["reason"], Exch.REASON_INVALID_QTY)
	var unknown: Dictionary = Exch.sell(profile, &"unobtainium", 1, NOW)
	assert_eq(unknown["reason"], Exch.REASON_UNKNOWN_ITEM)
	var bare: Dictionary = Exch.sell(profile, &"iron", 1, NOW)
	assert_eq(bare["reason"], Exch.REASON_UNKNOWN_ITEM, "a bare mineral id is not an item")
	var short: Dictionary = Exch.sell(profile, &"mineral_iron", 5, NOW)
	assert_eq(short["reason"], Exch.REASON_INSUFFICIENT_CARGO)

	assert_true(_deep_eq(profile.cargo_items(), cargo_before), "cargo untouched")
	assert_eq(profile.credits(), credits_before, "credits untouched")
	assert_true(_deep_eq(profile.market(), market_before), "market untouched")
	assert_eq(_log_lines().size(), 0, "a refused sale logs nothing")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## The re-entrancy fixture's listener: quoting from inside a sale, at a later band, makes the
## nested `evaluate_market` mint a drifted snapshot while the sale is still on the stack. The
## queue is empty, so the flush pays nothing and the signal cannot recurse.
func _on_reentrant_profile_changed(_key: StringName) -> void:
	_reentrant_quotes += 1
	if _reentrant_profile == null or not is_instance_valid(_reentrant_profile):
		return
	var quote: Dictionary = Exch.quote(
		_reentrant_profile, &"mineral_copper", 4, NOW + Clock.BAND_SECONDS
	)
	assert_true(bool(quote["ok"]), "the re-entrant quote itself succeeds")


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


## Debug the demand index straight into the persisted market (the suite needs an
## exact starting value, which no public API exposes).
func _force_demand(profile: Node, mineral_id: StringName, value: float) -> void:
	var state: Dictionary = profile.market()
	var demand: Dictionary = state["demand"]
	demand[String(mineral_id)] = value
	profile.set_market(state)


## The lowest seed whose first drawn step is at least `magnitude` in the wanted
## direction. `_drift_demand` draws for the first catalogue mineral first, so a
## matching first step pins the mineral under test.
func _seed_with_first_step(magnitude: float, positive: bool) -> int:
	var probe := RandomNumberGenerator.new()
	for candidate: int in range(1, 1000):
		probe.seed = candidate
		var step: float = probe.randf_range(-Exch.DEMAND_STEP, Exch.DEMAND_STEP)
		if positive and step >= magnitude:
			return candidate
		if not positive and step <= -magnitude:
			return candidate
	return 1


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _reset_log() -> void:
	Log.log_path = LOG_PATH
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file != null:
		file.close()


func _log_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return lines
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line)
	return lines


## Structural equality used for before/after comparisons: `==` on nested
## dictionaries is not dependable across a ConfigFile round trip's key order.
func _deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not _deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not _deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b
