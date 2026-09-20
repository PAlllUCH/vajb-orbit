class_name Refinery
extends RefCounted
## Station refinery: ore -> ingot conversion, the K3 fee sink (01 section 4).
## Pure transaction functions over PlayerProfile: verify -> take -> pay -> give ->
## log, all-or-nothing per confirmed batch (01 section 7, 17 section 5). The
## profile arrives as a Node handle and is reached through `call()`, so this
## module never references the PlayerProfile autoload identifier.
## Contract: docs/gameplay/04_refinery.md (section 2 the conversion rule,
## section 3 the fee schedule, section 5 the interaction contract).
## Deterministic on purpose: a fee-for-service machine, not a gamble; no RNG
## anywhere in this module (04 section 3). Integers only.
##
## Ratio conflict, resolved explicitly: 04 section 5 writes
## `remove_cargo(mineral_id, 4n)` while 04 section 2 and the 17 section 6 test
## both fix the ratio at 3 ore -> 1 ingot. This module takes 3n
## (ORE_PER_INGOT); the 4n line is a doc typo and is flagged in the P1e report.
## The ore/ingot division in `convertible` is deliberate integer division: whole
## conversions only, leftover ore stays in the hold untouched (04 section 2).
##
## Logging (01 section 7 line shape: timestamp, event, item, qty, credits_delta,
## balance): `refine` writes one REFINE line per call; `refine_all` writes ONE
## combined line for the whole batch (item `all`, qty = total ore taken,
## delta = -total fee) instead of one line per mineral, so a confirmed batch
## replays as a single action.

const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")

## CR per ore unit consumed (04 section 3).
const FEE_PER_UNIT := 5
## Ore units consumed per ingot produced (04 section 2).
const ORE_PER_INGOT := 3
## CR per conversion (3 ore), derived so 04 section 2 and section 3 cannot drift.
const FEE_PER_CONVERSION := FEE_PER_UNIT * ORE_PER_INGOT

const REASON_UNKNOWN_MINERAL: StringName = &"unknown_mineral"
const REASON_INVALID_COUNT: StringName = &"invalid_count"
const REASON_INSUFFICIENT_ORE: StringName = &"insufficient_ore"
const REASON_INSUFFICIENT_CREDITS: StringName = &"insufficient_credits"
const REASON_NOTHING_TO_REFINE: StringName = &"nothing_to_refine"


## Fee for a batch of `conversions` whole conversions; 0 for a non-positive count.
static func fee_for(conversions: int) -> int:
	if conversions <= 0:
		return 0
	return conversions * FEE_PER_CONVERSION


## Whole conversions currently available in the hold for one mineral; 0 for an
## unknown mineral.
static func convertible(profile: Node, mineral_id: StringName) -> int:
	if Catalog.mineral(mineral_id).is_empty():
		return 0
	@warning_ignore("integer_division")
	return int(profile.call(&"cargo_qty", Catalog.ore_id(mineral_id))) / ORE_PER_INGOT


## Read-only panel helper: one row per mineral with at least one conversion
## available, in catalogue order. Nothing is mutated.
static func stacks(profile: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry.get(&"id", &"")
		if mineral_id == &"":
			continue
		var conversions := convertible(profile, mineral_id)
		if conversions < 1:
			continue
		rows.append({
			&"mineral_id": mineral_id,
			&"entry": entry,
			&"ore_qty": int(profile.call(&"cargo_qty", Catalog.ore_id(mineral_id))),
			&"conversions": conversions,
			&"fee": fee_for(conversions),
		})
	return rows


## One confirmed batch: 3 * conversions ore -> conversions ingots for one fee.
## Returns `{ok, reason, mineral_id, conversions, ore_taken, ingots, fee}`; on
## refusal nothing is touched and `fee` is 0 (nothing was charged).
static func refine(profile: Node, mineral_id: StringName, conversions: int) -> Dictionary:
	if Catalog.mineral(mineral_id).is_empty():
		return _refusal(REASON_UNKNOWN_MINERAL, mineral_id, conversions)
	if conversions < 1:
		return _refusal(REASON_INVALID_COUNT, mineral_id, conversions)

	var ore_id: StringName = Catalog.ore_id(mineral_id)
	var ingot_id: StringName = Catalog.ingot_id(mineral_id)
	var ore_taken := conversions * ORE_PER_INGOT
	var fee := fee_for(conversions)

	if int(profile.call(&"cargo_qty", ore_id)) < ore_taken:
		return _refusal(REASON_INSUFFICIENT_ORE, mineral_id, conversions)
	if int(profile.call(&"credits")) < fee:
		return _refusal(REASON_INSUFFICIENT_CREDITS, mineral_id, conversions)

	# take -> pay -> give. Both steps are verified above, so a false here is
	# defensive only; whatever was taken is put back before refusing.
	if not bool(profile.call(&"remove_cargo", ore_id, ore_taken)):
		return _refusal(REASON_INSUFFICIENT_ORE, mineral_id, conversions)
	if not bool(profile.call(&"spend", fee)):
		profile.call(&"add_cargo", ore_id, ore_taken)
		return _refusal(REASON_INSUFFICIENT_CREDITS, mineral_id, conversions)
	profile.call(&"add_cargo", ingot_id, conversions)

	Log.append("REFINE", ore_id, ore_taken, -fee, int(profile.call(&"credits")))
	return {
		&"ok": true,
		&"reason": &"",
		&"mineral_id": mineral_id,
		&"conversions": conversions,
		&"ore_taken": ore_taken,
		&"ingots": conversions,
		&"fee": fee,
	}


## The 04 section 5 REFINERY ALL action: every convertible stack in one confirmed
## batch, one fee, one combined log line.
## Returns `{ok, reason, conversions, ingots, fee, minerals}`; `minerals` lists
## the converted mineral ids in catalogue order.
static func refine_all(profile: Node) -> Dictionary:
	var rows := stacks(profile)
	var minerals: Array[StringName] = []
	var total_conversions := 0
	var total_ore := 0
	var total_fee := 0
	for row: Dictionary in rows:
		var mineral_id: StringName = row.get(&"mineral_id", &"")
		var conversions: int = int(row.get(&"conversions", 0))
		minerals.append(mineral_id)
		total_conversions += conversions
		total_ore += conversions * ORE_PER_INGOT
		total_fee += int(row.get(&"fee", 0))

	if total_fee <= 0:
		return _batch(REASON_NOTHING_TO_REFINE, 0, 0, 0, minerals)
	if int(profile.call(&"credits")) < total_fee:
		return _batch(REASON_INSUFFICIENT_CREDITS, total_conversions, 0, 0, minerals)

	# take all -> pay once -> give all; `taken` tracks what to restore if a
	# defensive step fails, so no partial state can survive.
	var taken: Array[Dictionary] = []
	for row: Dictionary in rows:
		var ore_id: StringName = Catalog.ore_id(row.get(&"mineral_id", &""))
		var ore_qty: int = int(row.get(&"conversions", 0)) * ORE_PER_INGOT
		if not bool(profile.call(&"remove_cargo", ore_id, ore_qty)):
			_restore(profile, taken)
			return _batch(REASON_INSUFFICIENT_ORE, total_conversions, 0, 0, minerals)
		taken.append({&"ore_id": ore_id, &"ore_qty": ore_qty})

	if not bool(profile.call(&"spend", total_fee)):
		_restore(profile, taken)
		return _batch(REASON_INSUFFICIENT_CREDITS, total_conversions, 0, 0, minerals)

	for row: Dictionary in rows:
		var ingot_id: StringName = Catalog.ingot_id(row.get(&"mineral_id", &""))
		profile.call(&"add_cargo", ingot_id, int(row.get(&"conversions", 0)))

	Log.append("REFINE", &"all", total_ore, -total_fee, int(profile.call(&"credits")))
	return _batch(&"", total_conversions, total_conversions, total_fee, minerals)


static func _restore(profile: Node, taken: Array[Dictionary]) -> void:
	for item: Dictionary in taken:
		profile.call(&"add_cargo", item[&"ore_id"], int(item[&"ore_qty"]))


static func _refusal(reason: StringName, mineral_id: StringName, conversions: int) -> Dictionary:
	return {
		&"ok": false,
		&"reason": reason,
		&"mineral_id": mineral_id,
		&"conversions": conversions,
		&"ore_taken": 0,
		&"ingots": 0,
		&"fee": 0,
	}


static func _batch(
	reason: StringName, conversions: int, ingots: int, fee: int, minerals: Array[StringName]
) -> Dictionary:
	return {
		&"ok": reason == &"",
		&"reason": reason,
		&"conversions": conversions,
		&"ingots": ingots,
		&"fee": fee,
		&"minerals": minerals,
	}
