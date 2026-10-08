extends SceneTree
## S28-R1's re-measurement: the fee column, the battery law and the bloom cap read
## off the live tree on a fresh scratch store, printed so the review holds numbers
## instead of the builders' word. Byte-identical on replay (no unseeded RNG).
##
##   XDG_DATA_HOME=$(mktemp -d) "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/s28_r1_remeasure.gd

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const RefineryScript := preload("res://game/refinery.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")
const PoiScript := preload("res://game/poi.gd")

const TAG := "[S28R1]"
const FEE_COLUMN: Array[int] = [
	15, 15, 15, 15, 15, 15, 15, 15, 15, 16,
	20, 23, 25, 28, 32, 41, 45, 50, 57, 64,
]
const CHANNELS := {1: 1.0, 2: 1.4, 3: 1.8, 7: 3.4}
const ROCK_UNITS := 400
const CYCLES := 25
const SECTION_10 := {
	&"iron": [64, 38, 102],
	&"titanium": [127, 76, 204],
	&"gold": [254, 152, 406],
	&"krilium": [790, 474, 1264],
}
const DEMANDS: Array[float] = [1.0, 0.6, 1.6]

var _failures: Array[String] = []


class StubPlayer extends Node2D:
	func has_scanner() -> bool:
		return true


func _init() -> void:
	_fee_column()
	_fee_discount()
	_battery()
	_bloom()
	_exchange()
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


func _check(name: String, ok: bool, detail: String) -> void:
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", name, detail])
	if not ok:
		_failures.append(name)


func _fee_column() -> void:
	for index: int in MineralCatalogScript.MINERALS.size():
		var entry: Dictionary = MineralCatalogScript.MINERALS[index]
		var mineral_id: StringName = entry[&"id"]
		var ingot := int(entry[&"ingot_value"])
		@warning_ignore("integer_division")
		var derived := maxi(RefineryScript.FEE_FLOOR, ingot * RefineryScript.FEE_VALUE_PERMILLE / 1000)
		var live := int(RefineryScript.conversion_fee(mineral_id))
		_check(
			"fee_%s" % String(mineral_id),
			live == derived and live == FEE_COLUMN[index],
			"ingot %d -> fee %d (doc column %d)" % [ingot, live, FEE_COLUMN[index]]
		)


func _fee_discount() -> void:
	var mult := RefineryScript.REFINE_FEE_MULT
	_check("u_refine_iron", int(RefineryScript.fee_for(&"iron", 1, mult)) == 7,
		"iron x0.5 = %d (7, not 7.5)" % int(RefineryScript.fee_for(&"iron", 1, mult)))
	_check("u_refine_krilium", int(RefineryScript.fee_for(&"krilium", 1, mult)) == 32,
		"krilium x0.5 = %d" % int(RefineryScript.fee_for(&"krilium", 1, mult)))
	_check("iron_rows", int(RefineryScript.fee_for(&"iron", 3)) == 45,
		"iron 15/30/45 rows: 3 conversions = %d" % int(RefineryScript.fee_for(&"iron", 3)))
	_check("no_retired_read", int(RefineryScript.FEE_PER_CONVERSION) == RefineryScript.FEE_FLOOR,
		"the flat name aliases the floor, and no fee path reads it")


func _battery() -> void:
	for fit: int in [1, 2, 3, 7]:
		var laser := MiningLaserScript.new() as Node2D
		laser.call(&"set_battery", fit)
		var rock := AsteroidScript.new() as RigidBody2D
		rock.call(&"setup", &"iron", 1, ROCK_UNITS)
		var delivered := 0
		for _cycle in CYCLES:
			delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
		var per_cycle := float(delivered) / float(CYCLES)
		var expected: float = CHANNELS[fit]
		_check(
			"battery_%d" % fit,
			int(laser.call(&"battery")) == fit and absf(per_cycle - expected) <= 0.20 * expected,
			"battery()=%d, %.3f units/cycle (law %.1f)" % [int(laser.call(&"battery")), per_cycle, expected]
		)
		laser.free()
		rock.free()


func _bloom() -> void:
	_check("bloom_consts",
		int(PoiScript.ORE_BLOOM_ROCKS) == 6 and is_equal_approx(PoiScript.ORE_BLOOM_YIELD_MULT, 1.5)
			and int(PoiScript.ORE_BLOOM_TIER_BONUS) == 1
			and is_equal_approx(PoiScript.ANOMALY_TRIGGER_RADIUS, 200.0),
		"rocks=%d mult=%.2f bonus=%d trigger=%.0f" % [
			int(PoiScript.ORE_BLOOM_ROCKS), PoiScript.ORE_BLOOM_YIELD_MULT,
			int(PoiScript.ORE_BLOOM_TIER_BONUS), PoiScript.ANOMALY_TRIGGER_RADIUS,
		])
	var poi: Node2D = PoiScript.new() as Node2D
	poi.call(&"setup", PoiScript.KIND_ANOMALY, {
		&"sector_id": &"sector_1", &"anomaly_kind": PoiScript.ANOMALY_ORE_BLOOM, &"seed": 7,
	})
	var player := StubPlayer.new()
	poi.call(&"trigger", player)
	var rocks := _rocks(poi)
	var tier := mini(PoiScript.sector_band(1) + PoiScript.ORE_BLOOM_TIER_BONUS, 4)
	var base := int(MineralCatalogScript.TIER_BASE_YIELD.get(tier, 0))
	var low := roundi(float(maxi(1, roundi(float(base) * MineralCatalogScript.YIELD_VARIANCE_MIN))) * PoiScript.ORE_BLOOM_YIELD_MULT)
	var high := roundi(float(maxi(1, roundi(float(base) * MineralCatalogScript.YIELD_VARIANCE_MAX))) * PoiScript.ORE_BLOOM_YIELD_MULT)
	var in_band := true
	for rock: Node2D in rocks:
		var units := int(rock.get(&"yield_units"))
		if int(rock.get(&"tier")) != tier or units < low or units > high:
			in_band = false
	_check("bloom_spawn", rocks.size() == 6 and tier == 2 and in_band,
		"%d rocks at T%d, units in %d..%d" % [rocks.size(), tier, low, high])
	poi.free()
	player.free()


func _rocks(poi: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var stack: Array[Node] = [poi]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			var rock := child as Node2D
			if rock != null and rock.is_in_group(&"asteroid"):
				out.append(rock)
			stack.append(child)
	return out


func _exchange() -> void:
	for mineral_id: StringName in SECTION_10:
		var item_id: StringName = MineralCatalogScript.ingot_id(mineral_id)
		var expected: Array = SECTION_10[mineral_id]
		var got: Array[int] = []
		for demand: float in DEMANDS:
			got.append(int(ExchangeScript.exchange_price(item_id, demand)))
		_check("s10_%s" % String(mineral_id),
			got[0] == int(expected[0]) and got[1] == int(expected[1]) and got[2] == int(expected[2]),
			"%s net at 1.0/0.6/1.6 = %d/%d/%d" % [String(item_id), got[0], got[1], got[2]])
	var quote: Dictionary = ExchangeScript.sale_quote(259, 1.2, 10)
	_check("gold_batch",
		int(quote[&"gross"]) == 3108 and int(quote[&"fee"]) == 63 and int(quote[&"paid"]) == 3045,
		"sale_quote(259, 1.2, 10) = %d/%d/%d" % [int(quote[&"gross"]), int(quote[&"fee"]), int(quote[&"paid"])])
	_check("gold_unit",
		int(ExchangeScript.unit_gross(259, 1.2)) == 311
			and int(ExchangeScript.exchange_price(&"ingot_gold", 1.2)) == 305,
		"unit_gross=%d exchange_price=%d" % [
			int(ExchangeScript.unit_gross(259, 1.2)), int(ExchangeScript.exchange_price(&"ingot_gold", 1.2))])
	_check("raw_iron", int(ExchangeScript.exchange_price(&"mineral_iron", 1.0)) == 18,
		"raw iron at demand 1.0 = %d" % int(ExchangeScript.exchange_price(&"mineral_iron", 1.0)))
