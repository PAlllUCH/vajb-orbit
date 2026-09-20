class_name Exchange
extends RefCounted
## The minerals exchange: the two books, the band-driven demand model and the
## sell transactions.
## Contract: docs/gameplay/05_exchange.md (law: sections 2 to 6, 8),
## docs/gameplay/01_economy_core.md section 7 (verify -> take -> pay -> emit, one
## running transaction log) and docs/gameplay/17_coder_handoff.md sections 4
## (one clock) and 5 (transaction law). Panel contract: docs/design/STATION_HUB.md
## section 5.8 (amendment 2026-09-18).
##
## Minerals book: dynamic price = baseline * demand, one demand index per mineral
## drifting in 20-minute bands (05 section 2). Surplus book: components at a flat
## 10 % discount, capped by a per-grade quota, with the overflow queued for the
## next cycle (05 section 4). Commission is 2 % of the gross with a 10 CR floor,
## rounded up, and is always reported separately, never baked into the quoted
## unit price (05 section 5).
##
## One pricing function family (05 section 8): UI code reads `exchange_price()`
## and never recomputes a price from a baseline.
##
## Two rounding bases, both taken from the design as written:
##   * `unit_net()` rounds the net product per unit, which reproduces the 05
##     section 3 table exactly (Iron ingot 65 at demand 1.0 -> 64).
##   * `sale_quote()` rounds one transaction-level gross and ceils the commission
##     on that gross, which reproduces the 05 section 5 worked examples exactly
##     (10 Gold ingots at demand 1.2 -> gross 4740, fee 95, paid 4645). On a
##     batch the two bases can differ by a few credits; that is documented
##     behaviour, and both are implemented and tested exactly as written.
## 05 section 2's raw-ore aside ("18 x 0.98 = 17") disagrees with both: the net
## product is 17.64, which rounds to 18. The section 3 table and `unit_net()` are
## the authority, so the aside is treated as a typo and deliberately not
## special-cased (P1d report).
##
## The 10 CR commission floor applies to a sale, never to a zero-gross
## transaction: a component stack the station cannot take this cycle is queued
## and pays 0 (05 section 4), so `commission_for(0)` is 0 and no path can charge
## the player for selling into a full book.
##
## Credits are ints everywhere; only demand is a float. Profile state is only
## ever touched through the PlayerProfile public API, and every economy event
## writes a line through EconomyLog (01 section 7).

## Preloaded by path on purpose: this file must not depend on autoload nodes or
## on the global class table, so a headless caller and the editor agree.
const MineralCatalog := preload("res://game/mineral_catalog.gd")
const ComponentCatalog := preload("res://game/component_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")

const COMMISSION := 0.02
const COMMISSION_MIN := 10
const DEMAND_MIN := 0.6
const DEMAND_MAX := 1.6
const DEMAND_STEP := 0.15
const TRADE_IMPACT := 0.01
const SURPLUS_DISCOUNT := 0.9
const STOCK_QUOTA: Dictionary = {1: 40, 2: 15, 3: 4}

## The demand index every mineral starts with (05 section 2).
const DEMAND_DEFAULT := 1.0

const KIND_MINERAL: StringName = &"mineral"
const KIND_COMPONENT: StringName = &"component"

const REASON_INVALID_QTY: StringName = &"invalid_qty"
const REASON_UNKNOWN_ITEM: StringName = &"unknown_item"
const REASON_INSUFFICIENT_CARGO: StringName = &"insufficient_cargo"

## 01 section 7 log vocabulary, plus the queue flush of 05 section 4.
const EVENT_SELL := "SELL"
const EVENT_QUEUE := "QUEUE"
const EVENT_QUEUE_BUY := "QUEUE_BUY"


## ---------------------------------------------------------------------------
## Pricing (the one pricing function family, 05 section 8)
## ---------------------------------------------------------------------------


## Per-unit net, commission deducted: "price = round(baseline x demand x
## (1 - commission))" (05 section 2). Reproduces the 05 section 3 table.
static func unit_net(baseline: int, demand: float) -> int:
	return roundi(baseline * demand * (1.0 - COMMISSION))


## Per-unit gross, before commission: the 05 §2 gross helper of the pricing family, kept for
## the pricing family and the suite (not dead code). The board does not draw it, because
## STATION_HUB §5.8's market row shows the baseline and the demand index separately next to
## the net PRICE.
static func unit_gross(baseline: int, demand: float) -> int:
	return roundi(baseline * demand)


## "2 % of each sale, minimum 10 CR per transaction, rounded up" (05 section 5).
## A zero-gross transaction is not a sale: a component stack the station could
## not take at all is queued and pays 0 (05 section 4), so it is charged nothing
## rather than the 10 CR floor, which would otherwise become a negative payout.
static func commission_for(gross: int) -> int:
	if gross <= 0:
		return 0
	return maxi(COMMISSION_MIN, ceili(gross * COMMISSION))


## One transaction-level quote: gross, fee and what the player is paid. The
## transaction rounding base (see the header); reproduces 05 section 5.
static func sale_quote(baseline: int, demand: float, qty: int) -> Dictionary:
	var gross := roundi(baseline * demand * qty)
	var fee := commission_for(gross)
	return {&"gross": gross, &"fee": fee, &"paid": maxi(0, gross - fee)}


## Surplus-book unit price: "round(baseline x 0.9)" (05 section 4).
static func component_unit_price(value: int) -> int:
	return roundi(value * SURPLUS_DISCOUNT)


## The sell baseline behind an item id: ore -> ore_value, ingot -> ingot_value,
## component -> value. A bare mineral id (or anything unknown) has none: 0.
static func baseline_of(item_id: StringName) -> int:
	if MineralCatalog.is_ore(item_id):
		return int(MineralCatalog.entry_for_item(item_id).get(&"ore_value", 0))
	if MineralCatalog.is_ingot(item_id):
		return int(MineralCatalog.entry_for_item(item_id).get(&"ingot_value", 0))
	if is_component(item_id):
		return int(ComponentCatalog.component(item_id).get(&"value", 0))
	return 0


## The single public price read for UI code (05 section 8): the current unit
## price of one item. Components ignore `demand` (flat surplus book).
static func exchange_price(item_id: StringName, demand: float) -> int:
	if is_component(item_id):
		return component_unit_price(baseline_of(item_id))
	if MineralCatalog.is_ore(item_id) or MineralCatalog.is_ingot(item_id):
		return unit_net(baseline_of(item_id), demand)
	return 0


static func is_component(item_id: StringName) -> bool:
	return not ComponentCatalog.component(item_id).is_empty()


## Everything the exchange buys: ore, ingots and components (05 section 1).
static func is_sellable(item_id: StringName) -> bool:
	return (
		MineralCatalog.is_ore(item_id)
		or MineralCatalog.is_ingot(item_id)
		or is_component(item_id)
	)


## The mineral's demand index, defaulting to 1.0 (the start state, 05 section 2).
## Accepts the bare mineral id or either item form.
static func demand_of(profile: Node, mineral_id: StringName) -> float:
	return _demand_from(profile.market(), mineral_id)


## Surplus-book quota for a grade. 0 for a grade the station does not stock.
static func quota_for(grade: int) -> int:
	return int(STOCK_QUOTA.get(grade, 0))


## The 05 section 6 trend glyph, rendered as a word: the STATION_HUB section 5.8
## amendment replaces the arrow glyphs with these three labels.
static func trend_word(trend: int) -> String:
	if trend < 0:
		return "COOLING"
	if trend > 0:
		return "HOT"
	return "STEADY"


## ---------------------------------------------------------------------------
## Market evaluation (the one clock, 05 sections 2 and 4)
## ---------------------------------------------------------------------------


## Advances the market to `now` and returns the number of bands applied.
##
## A profile whose market has never been evaluated (`last_band <= 0`) is simply
## stamped: no drift, and every component stock is filled to its quota. The same
## lazy evaluation runs on the one WorldClock band accumulator (17 section 4);
## there is no Timer anywhere.
##
## Per band, in order: demand drifts by a random step in
## [-DEMAND_STEP, +DEMAND_STEP] clamped to [DEMAND_MIN, DEMAND_MAX] with the step
## sign recorded per mineral in `trend` (05 section 2), every component restocks
## to its quota, then every queued surplus unit that fits the fresh stock is paid
## out at the surplus price minus commission (05 section 4).
static func evaluate_market(profile: Node, now: int, rng: RandomNumberGenerator = null) -> int:
	var state: Dictionary = profile.market()
	var last := _integer(state, &"last_band", 0)
	if last <= 0:
		state["last_band"] = now
		_restock_missing(state)
		profile.set_market(state)
		return 0
	var bands := Clock.bands_between(last, now)
	if bands <= 0:
		if _restock_missing(state):
			profile.set_market(state)
		return bands
	for _band: int in range(bands):
		_drift_demand(state, rng)
		_restock(state)
		_flush_queue(profile, state)
	state["last_band"] = now
	profile.set_market(state)
	return bands


## ---------------------------------------------------------------------------
## Transactions (01 section 7 order: verify -> take -> pay -> log)
## ---------------------------------------------------------------------------


## Reads a price and availability without touching cargo, credits or the market
## beyond the evaluation every entry point performs.
##
## Keys: `ok`, `reason`, `item`, `kind`, `qty`, `sellable`, `queued`, `unit`,
## `gross`, `fee`, `paid`, `demand`, `stock`. Minerals report `sellable = qty`,
## `queued = 0`, `stock = 0`; on the surplus book `sellable` is what the current
## stock takes, `queued` is the overflow that waits for the next band, and
## `demand` stays 1.0 because components are not on the demand market.
static func quote(
	profile: Node, item_id: StringName, qty: int, now: int, rng: RandomNumberGenerator = null
) -> Dictionary:
	evaluate_market(profile, now, rng)
	return _quote_from(profile.market(), profile.cargo_qty(item_id), item_id, qty)


## The full transaction: evaluate once, verify, take the goods, pay, update the
## market and log. All-or-nothing; a refused sale touches nothing at all.
##
## A component the station cannot take this cycle still hands over its goods and
## reports `queued = qty` with `paid = 0` (05 section 4: "STOCK FULL - 12 units
## queued"); the queue pays out at the next band evaluation.
static func sell(
	profile: Node, item_id: StringName, qty: int, now: int, rng: RandomNumberGenerator = null
) -> Dictionary:
	evaluate_market(profile, now, rng)
	var state: Dictionary = profile.market()
	var result := _quote_from(state, profile.cargo_qty(item_id), item_id, qty)
	if not bool(result[&"ok"]):
		return result
	if not profile.remove_cargo(item_id, qty):
		return _refuse(result, REASON_INSUFFICIENT_CARGO)
	profile.add_credits(int(result[&"paid"]))
	## remove_cargo and add_credits emit profile_changed, so a re-entrant listener (a panel
	## refreshing through Exchange.quote) can mint a newer market snapshot while this call is
	## still on the stack. Re-read the market here and apply the deltas to that fresh copy:
	## the price above was read at quote time, but the state written back is the market as it
	## stands now, so the newer evaluation is never rolled back by this older one.
	state = profile.market()
	_apply_trade(state, item_id, qty, result)
	profile.set_market(state)
	_log_sale(item_id, result, profile)
	return result


## SELL ALL RAW (05 section 6): every raw ore stack and every surplus-book
## component stack, sold under the same rules as `sell`, in one confirmed action
## on a single market evaluation. Ingots are never included - they sell stack by
## stack, so the shortcut can never dump refined value by accident.
##
## Returns `{ok, paid, lines, skipped}`; `lines` are the per-item sale results in
## catalogue order (ores first, then components), `skipped` the ids that refused,
## and `ok` is true when nothing refused. Ingots appear in neither list.
static func sell_all(profile: Node, now: int, rng: RandomNumberGenerator = null) -> Dictionary:
	evaluate_market(profile, now, rng)
	var state: Dictionary = profile.market()
	var lines: Array[Dictionary] = []
	var skipped: Array[StringName] = []
	var total := 0
	for item_id: StringName in _bulk_ids(profile):
		var qty: int = profile.cargo_qty(item_id)
		var result := _quote_from(state, qty, item_id, qty)
		if not bool(result[&"ok"]):
			lines.append(result)
			skipped.append(item_id)
			continue
		if not profile.remove_cargo(item_id, qty):
			lines.append(_refuse(result, REASON_INSUFFICIENT_CARGO))
			skipped.append(item_id)
			continue
		var paid := int(result[&"paid"])
		profile.add_credits(paid)
		total += paid
		## Same re-entrancy guard as `sell`: the emits above can mint a newer snapshot, so
		## each line's deltas are applied to the market as it is right now, and the next
		## line quotes against that same fresh copy instead of the pre-sale one.
		state = profile.market()
		_apply_trade(state, item_id, qty, result)
		profile.set_market(state)
		_log_sale(item_id, result, profile)
		lines.append(result)
	return {&"ok": skipped.is_empty(), &"paid": total, &"lines": lines, &"skipped": skipped}


## The item stacks SELL ALL RAW may touch, in catalogue order: ores the hold
## actually carries, then components. Ingots are deliberately absent.
static func _bulk_ids(profile: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	var cargo: Dictionary = profile.cargo_items()
	for mineral_id: StringName in MineralCatalog.mineral_ids():
		var ore_id := MineralCatalog.ore_id(mineral_id)
		if ore_id != &"" and _integer(cargo, ore_id, 0) > 0:
			ids.append(ore_id)
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if component_id != &"" and _integer(cargo, component_id, 0) > 0:
			ids.append(component_id)
	return ids


## ---------------------------------------------------------------------------
## Internals
## ---------------------------------------------------------------------------


static func _quote_from(state: Dictionary, held: int, item_id: StringName, qty: int) -> Dictionary:
	var result := _blank_quote(item_id, qty)
	if qty <= 0:
		return _refuse(result, REASON_INVALID_QTY)
	if not is_sellable(item_id):
		return _refuse(result, REASON_UNKNOWN_ITEM)
	if is_component(item_id):
		result[&"kind"] = KIND_COMPONENT
	else:
		result[&"kind"] = KIND_MINERAL
	if held < qty:
		return _refuse(result, REASON_INSUFFICIENT_CARGO)
	if is_component(item_id):
		var stock := _integer(_bucket(state, &"stock"), item_id, 0)
		var sold := mini(qty, stock)
		var unit := component_unit_price(baseline_of(item_id))
		var gross := unit * sold
		var fee := commission_for(gross)
		result[&"sellable"] = sold
		result[&"queued"] = qty - sold
		result[&"unit"] = unit
		result[&"gross"] = gross
		result[&"fee"] = fee
		result[&"paid"] = maxi(0, gross - fee)
		result[&"demand"] = DEMAND_DEFAULT
		result[&"stock"] = stock
		result[&"ok"] = true
		return result
	var demand := _demand_from(state, item_id)
	var quoted := sale_quote(baseline_of(item_id), demand, qty)
	result[&"sellable"] = qty
	result[&"unit"] = unit_net(baseline_of(item_id), demand)
	result[&"gross"] = int(quoted[&"gross"])
	result[&"fee"] = int(quoted[&"fee"])
	result[&"paid"] = int(quoted[&"paid"])
	result[&"demand"] = demand
	result[&"ok"] = true
	return result


## The market-side half of a sale: demand cools on the minerals book (05
## section 2), stock drops and the overflow queues on the surplus book
## (05 section 4).
static func _apply_trade(state: Dictionary, item_id: StringName, qty: int, result: Dictionary) -> void:
	if is_component(item_id):
		_set_stock(state, item_id, int(result[&"stock"]) - int(result[&"sellable"]))
		var waiting := _integer(_bucket(state, &"queue"), item_id, 0) + int(result[&"queued"])
		_set_queue(state, item_id, waiting)
		return
	var cooling := float(result[&"demand"]) - TRADE_IMPACT * qty
	_set_demand(state, item_id, clampf(cooling, DEMAND_MIN, DEMAND_MAX))


## One SELL line per confirmed sale, plus a QUEUE line for the surplus units the
## station could not take yet (01 section 7 shape, 05 section 6 flow).
static func _log_sale(item_id: StringName, result: Dictionary, profile: Node) -> void:
	Log.append(EVENT_SELL, item_id, int(result[&"sellable"]), int(result[&"paid"]), profile.credits())
	var queued := int(result[&"queued"])
	if queued > 0:
		Log.append(EVENT_QUEUE, item_id, queued, 0, profile.credits())


static func _drift_demand(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var demand := _bucket(state, &"demand")
	var trend := _bucket(state, &"trend")
	for mineral_id: StringName in MineralCatalog.mineral_ids():
		var step := _step(rng)
		var drifted := _demand_from(state, mineral_id) + step
		demand[String(mineral_id)] = clampf(drifted, DEMAND_MIN, DEMAND_MAX)
		trend[String(mineral_id)] = int(signf(step))


static func _step(rng: RandomNumberGenerator) -> float:
	if rng == null:
		return randf_range(-DEMAND_STEP, DEMAND_STEP)
	return rng.randf_range(-DEMAND_STEP, DEMAND_STEP)


## Fill only the stocks this profile has never carried. Used outside the band
## loop so a first entry into the station shows a full board, not a blank one.
static func _restock_missing(state: Dictionary) -> bool:
	var stock := _bucket(state, &"stock")
	var changed := false
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if component_id == &"" or _lookup(stock, component_id) != null:
			continue
		stock[String(component_id)] = quota_for(int(entry.get(&"grade", 0)))
		changed = true
	return changed


## "The station restocks a per-item quota every 20 minutes" (05 section 4): the
## quota is set, not topped up, so a cycle that sold nothing still starts clean.
static func _restock(state: Dictionary) -> void:
	var stock := _bucket(state, &"stock")
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if component_id == &"":
			continue
		stock[String(component_id)] = quota_for(int(entry.get(&"grade", 0)))


## Pay out every queued unit the restocked quota can take, oldest queue first,
## at the surplus price minus commission (05 section 4).
static func _flush_queue(profile: Node, state: Dictionary) -> void:
	var stock := _bucket(state, &"stock")
	var queue := _bucket(state, &"queue")
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if component_id == &"":
			continue
		var waiting := _integer(queue, component_id, 0)
		if waiting <= 0:
			continue
		var available := _integer(stock, component_id, 0)
		var sold := mini(waiting, available)
		if sold <= 0:
			continue
		var gross := component_unit_price(int(entry.get(&"value", 0))) * sold
		var fee := commission_for(gross)
		var paid := maxi(0, gross - fee)
		profile.add_credits(paid)
		stock[String(component_id)] = available - sold
		queue[String(component_id)] = waiting - sold
		Log.append(EVENT_QUEUE_BUY, component_id, sold, paid, profile.credits())


static func _blank_quote(item_id: StringName, qty: int) -> Dictionary:
	return {
		&"ok": false,
		&"reason": &"",
		&"item": item_id,
		&"kind": &"",
		&"qty": qty,
		&"sellable": 0,
		&"queued": 0,
		&"unit": 0,
		&"gross": 0,
		&"fee": 0,
		&"paid": 0,
		&"demand": DEMAND_DEFAULT,
		&"stock": 0,
	}


static func _refuse(result: Dictionary, reason: StringName) -> Dictionary:
	result[&"ok"] = false
	result[&"reason"] = reason
	return result


static func _demand_from(state: Dictionary, mineral_id: StringName) -> float:
	var resolved := MineralCatalog.mineral_id_of_item(mineral_id)
	if resolved == &"":
		return DEMAND_DEFAULT
	return _number(_bucket(state, &"demand"), resolved, DEMAND_DEFAULT)


static func _set_demand(state: Dictionary, item_id: StringName, value: float) -> void:
	var resolved := MineralCatalog.mineral_id_of_item(item_id)
	if resolved == &"":
		return
	_bucket(state, &"demand")[String(resolved)] = value


static func _set_stock(state: Dictionary, component_id: StringName, value: int) -> void:
	_bucket(state, &"stock")[String(component_id)] = maxi(0, value)


static func _set_queue(state: Dictionary, component_id: StringName, value: int) -> void:
	_bucket(state, &"queue")[String(component_id)] = maxi(0, value)


## A market sub-dictionary, created on demand. Returns the live nested reference
## so callers can mutate it in place; PlayerProfile normalises every key to
## String when it stores the state, which is why writes here use String keys.
static func _bucket(state: Dictionary, key: StringName) -> Dictionary:
	var raw: Variant = _lookup(state, key)
	if raw is Dictionary:
		return raw
	var fresh: Dictionary = {}
	state[String(key)] = fresh
	return fresh


## Reads a key in either string form: the persisted market uses String keys,
## in-memory callers tend to use StringName. Missing keys return null.
static func _lookup(source: Dictionary, id: StringName) -> Variant:
	if source.has(id):
		return source[id]
	return source.get(String(id), null)


static func _integer(source: Dictionary, id: StringName, fallback: int) -> int:
	var value: Variant = _lookup(source, id)
	if value is int or value is float:
		return int(value)
	return fallback


static func _number(source: Dictionary, id: StringName, fallback: float) -> float:
	var value: Variant = _lookup(source, id)
	if value is float or value is int:
		return float(value)
	return fallback
