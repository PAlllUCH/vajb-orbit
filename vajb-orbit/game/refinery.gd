class_name Refinery
extends RefCounted
## Station refinery: ore -> ingot conversion, the K3 fee sink (01 section 4).
## Timed jobs on upgradable slots with input/output inventory (04 section 7, the
## 2026-10-05 amendment). Pure transaction functions over PlayerProfile: verify ->
## take -> pay -> give -> log, all-or-nothing per confirmed action (01 section 7,
## 17 section 5). The profile arrives as a Node handle and is reached through
## `call()`, so this module never references the PlayerProfile autoload identifier.
## Contract: docs/gameplay/04_refinery.md (section 2 the conversion rule, section 3
## the fee schedule, section 7 the job/slot/inventory model and values R1-R8).
## Deterministic on purpose: a fee-for-service machine, not a gamble; no RNG
## anywhere in this module (04 section 3). Integers only.
##
## Jobs run station-side on wall-clock `ready_at` (R6): a job queued while docked
## keeps running while the player flies, and `settle` completes every finished job
## it is next asked about. `settle` is idempotent and safe to call at any time.
##
## `stacks` / `convertible` (hold-side reads) are retained for the sealed
## `test_p1_refinery.gd:192` row and the LEFT block's hold rows; the queue draws
## from `refinery_input`, never the hold.

const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

## CR per ore unit consumed (04 section 3).
const FEE_PER_UNIT := 5
## Ore units consumed per ingot produced (04 section 2).
const ORE_PER_INGOT := 3
## CR per conversion (3 ore), derived so 04 section 2 and section 3 cannot drift.
const FEE_PER_CONVERSION := FEE_PER_UNIT * ORE_PER_INGOT

## R3/R4 (04 section 7.2): 2 slots base, +1 bought at the panel for 3,000 CR flat,
## hardcap 5. Reversal: 1 base / hardcap 3, or slots granted by `u_refine`.
const BASE_SLOTS := 2
const MAX_SLOTS := 5
const SLOT_UPGRADE_COST := 3000
## R5: input ore units, output ingot units. Reversal: 40 / 40.
const INPUT_CAP := 60
const OUTPUT_CAP := 60

## R1: `clamp(round(ingot_value_cr / 10), 10, 60)` seconds per conversion, read
## from 02 section 2's ingot value (04 section 7.1). Reversal: a per-tier ladder.
const RESOURCE_SECONDS_FLOOR := 10
const RESOURCE_SECONDS_CEIL := 60
const RESOURCE_SECONDS_DIVISOR := 10

## 09 section 3.6's `u_refine` row (S23, A2): "refinery fee -50 % for its ore". The
## multiplier a hull fitted with the module refines at; the ratio stays 3:1 (A2's
## own bracket) and only the fee halves. Every fee path reads it through
## `fee_multiplier(profile)`, so a caller cannot price one path at the discount and
## another at the list.
const REFINE_FEE_MULT := 0.5
## The fitted module the discount reads.
const REFINE_MODULE: StringName = &"u_refine"

## Job states (04 section 7.1). `pending` waits for a free slot, `running` counts
## down to `ready_at`, `done` has finished and awaits collection.
const JOB_PENDING: StringName = &"pending"
const JOB_RUNNING: StringName = &"running"
const JOB_DONE: StringName = &"done"

const REASON_UNKNOWN_MINERAL: StringName = &"unknown_mineral"
const REASON_INVALID_COUNT: StringName = &"invalid_count"
const REASON_INSUFFICIENT_ORE: StringName = &"insufficient_ore"
const REASON_INSUFFICIENT_CREDITS: StringName = &"insufficient_credits"
const REASON_NOTHING_TO_REFINE: StringName = &"nothing_to_refine"
const REASON_NOTHING_TO_QUEUE: StringName = &"nothing_to_queue"
const REASON_INPUT_FULL: StringName = &"input_full"
const REASON_OUTPUT_FULL: StringName = &"output_full"
const REASON_MAX_SLOTS: StringName = &"max_slots"
const REASON_UNKNOWN_JOB: StringName = &"unknown_job"
const REASON_JOB_DONE: StringName = &"job_done"


## The fee multiplier the account's active hull refines at: 1.0 without `u_refine`
## fitted, `REFINE_FEE_MULT` with it. The profile arrives as a Node handle (the
## house pattern); a stub without the fit accessors reads 1.0, so every existing
## caller and test keeps its list-fee behaviour.
static func fee_multiplier(profile: Node) -> float:
	if profile == null or not profile.has_method(&"resolved_fit"):
		return 1.0
	var ship: StringName = &""
	if profile.has_method(&"active_ship"):
		ship = StringName(profile.call(&"active_ship"))
	if ship == &"":
		return 1.0
	var fit: Dictionary = profile.call(&"resolved_fit", ship)
	var ids := ShipFitScript.fitted_ids(fit)
	for id: StringName in ids:
		if id == REFINE_MODULE:
			return REFINE_FEE_MULT
	return 1.0


## Fee for a batch of `conversions` whole conversions at `mult`; 0 for a
## non-positive count. The discounted fee is the conversion's own 15 CR share at
## the multiplier, floored (integers only, 04 section 3's whole-credit law): one
## discounted conversion is 7 CR, not 7.5.
static func fee_for(conversions: int, mult: float = 1.0) -> int:
	if conversions <= 0:
		return 0
	return int(float(conversions) * float(FEE_PER_CONVERSION) * maxf(mult, 0.0))


## R1: the wall seconds one conversion of `mineral_id` takes,
## `clamp(round(ingot_value / 10), 10, 60)` (04 section 7.1). Iron's 65 CR ingot
## reads 10 s, Gold's 395 reads 40 s; an unknown mineral floors at 10.
static func resource_seconds(mineral_id: StringName) -> int:
	var entry := Catalog.mineral(mineral_id)
	if entry.is_empty():
		return RESOURCE_SECONDS_FLOOR
	var seconds := roundi(float(int(entry.get(&"ingot_value", 0))) / float(RESOURCE_SECONDS_DIVISOR))
	return clampi(seconds, RESOURCE_SECONDS_FLOOR, RESOURCE_SECONDS_CEIL)


## Whole conversions currently available in the **hold** for one mineral; 0 for an
## unknown mineral. Retained for the LEFT block's hold rows and the sealed P1 row.
static func convertible(profile: Node, mineral_id: StringName) -> int:
	if Catalog.mineral(mineral_id).is_empty():
		return 0
	@warning_ignore("integer_division")
	return int(profile.call(&"cargo_qty", Catalog.ore_id(mineral_id))) / ORE_PER_INGOT


## Read-only panel helper: one row per mineral with at least one hold conversion,
## in catalogue order, each row's fee at the hull's own multiplier. Nothing is
## mutated.
static func stacks(profile: Node) -> Array[Dictionary]:
	var mult := fee_multiplier(profile)
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
			&"fee": fee_for(conversions, mult),
		})
	return rows


## ------------------------------------------------------------------ the store


## The whole job list, a deep copy: `[{id, mineral_id, conversions, ready_at,
## state, fee, settled}]`. `fee` is the CR charged when the job was queued (what
## `cancel` refunds); `settled` records whether its conversions have reached
## `refinery_output`.
static func jobs(profile: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if profile == null or not profile.has_method(&"refinery_jobs"):
		return out
	var raw: Variant = profile.call(&"refinery_jobs")
	if not raw is Array:
		return out
	for entry: Variant in (raw as Array):
		if entry is Dictionary:
			out.append(entry as Dictionary)
	return out


## R3: the account's slot count, clamped to the pin's ladder.
static func slots(profile: Node) -> int:
	if profile == null or not profile.has_method(&"refinery_slots"):
		return BASE_SLOTS
	return clampi(int(profile.call(&"refinery_slots")), BASE_SLOTS, MAX_SLOTS)


## The ore units `refinery_input` holds for one mineral.
static func input_units(profile: Node, mineral_id: StringName) -> int:
	if Catalog.mineral(mineral_id).is_empty():
		return 0
	return int(_input(profile).get(Catalog.ore_id(mineral_id), 0))


## The whole conversions `refinery_input` can queue for one mineral (R5).
static func input_conversions(profile: Node, mineral_id: StringName) -> int:
	@warning_ignore("integer_division")
	return input_units(profile, mineral_id) / ORE_PER_INGOT


## The ore units `refinery_input` holds across every mineral.
static func input_total(profile: Node) -> int:
	return _total(_input(profile))


## The ingot units `refinery_output` holds across every mineral.
static func output_total(profile: Node) -> int:
	return _total(_output(profile))


static func running_count(profile: Node) -> int:
	return _count_state(profile, JOB_RUNNING)


static func pending_count(profile: Node) -> int:
	return _count_state(profile, JOB_PENDING)


static func done_count(profile: Node) -> int:
	return _count_state(profile, JOB_DONE)


## ---------------------------------------------------------------- transactions


## R7's QUEUE N: one confirmed batch becomes one job {mineral_id, conversions} on
## one slot (04 section 7.1). All-or-nothing: verify fee -> spend fee -> take ore
## from `refinery_input` -> append the job; any step failing restores what earlier
## steps took and returns a refusal. Duration is `conversions x RESOURCE_SECONDS`.
## Returns `{ok, reason, mineral_id, conversions, ore_taken, ingots, fee, job_id}`.
static func queue(profile: Node, mineral_id: StringName, conversions: int) -> Dictionary:
	if Catalog.mineral(mineral_id).is_empty():
		return _refusal(REASON_UNKNOWN_MINERAL, mineral_id, conversions)
	if conversions < 1:
		return _refusal(REASON_INVALID_COUNT, mineral_id, conversions)

	var ore_id: StringName = Catalog.ore_id(mineral_id)
	var ore_units := conversions * ORE_PER_INGOT
	if input_units(profile, mineral_id) < ore_units:
		return _refusal(REASON_INSUFFICIENT_ORE, mineral_id, conversions)

	var fee := fee_for(conversions, fee_multiplier(profile))
	if int(profile.call(&"credits")) < fee:
		return _refusal(REASON_INSUFFICIENT_CREDITS, mineral_id, conversions)

	if not bool(profile.call(&"spend", fee)):
		return _refusal(REASON_INSUFFICIENT_CREDITS, mineral_id, conversions)
	if not _take_input(profile, ore_id, ore_units):
		profile.call(&"add_credits", fee)
		return _refusal(REASON_INSUFFICIENT_ORE, mineral_id, conversions)

	var job := _new_job(profile, mineral_id, conversions, fee)
	var list := jobs(profile)
	list.append(job)
	_write_jobs(profile, list)
	settle(profile)

	Log.append("REFINE", ore_id, ore_units, -fee, int(profile.call(&"credits")))
	return {
		&"ok": true,
		&"reason": &"",
		&"mineral_id": mineral_id,
		&"conversions": conversions,
		&"ore_taken": ore_units,
		&"ingots": conversions,
		&"fee": fee,
		&"job_id": int(job[&"id"]),
	}


## R7's QUEUE ALL: one job per convertible mineral (a mineral whose input holds at
## least one whole conversion), in catalogue order, one combined fee, one log line.
## FIFO pending beyond the free slots. All-or-nothing like `queue`.
## Returns `{ok, reason, conversions, ingots, fee, minerals, job_ids}`.
static func queue_all(profile: Node) -> Dictionary:
	var input := _input(profile)
	var mult := fee_multiplier(profile)
	var plan: Array[Dictionary] = []
	var minerals: Array[StringName] = []
	var total_conversions := 0
	var total_ore := 0
	var total_fee := 0
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry.get(&"id", &"")
		if mineral_id == &"":
			continue
		var ore_id: StringName = Catalog.ore_id(mineral_id)
		@warning_ignore("integer_division")
		var conversions := int(input.get(ore_id, 0)) / ORE_PER_INGOT
		if conversions < 1:
			continue
		var fee := fee_for(conversions, mult)
		plan.append({&"mineral_id": mineral_id, &"ore_id": ore_id, &"conversions": conversions, &"fee": fee})
		minerals.append(mineral_id)
		total_conversions += conversions
		total_ore += conversions * ORE_PER_INGOT
		total_fee += fee

	if plan.is_empty():
		return _batch(REASON_NOTHING_TO_QUEUE, 0, 0, 0, minerals)
	if int(profile.call(&"credits")) < total_fee:
		return _batch(REASON_INSUFFICIENT_CREDITS, total_conversions, 0, 0, minerals)
	if not bool(profile.call(&"spend", total_fee)):
		return _batch(REASON_INSUFFICIENT_CREDITS, total_conversions, 0, 0, minerals)

	var taken: Array[Dictionary] = []
	for row: Dictionary in plan:
		var ore_id: StringName = row[&"ore_id"]
		var ore_units: int = int(row[&"conversions"]) * ORE_PER_INGOT
		if not _take_input(profile, ore_id, ore_units):
			for restored: Dictionary in taken:
				_add_input(profile, restored[&"ore_id"], int(restored[&"units"]))
			profile.call(&"add_credits", total_fee)
			return _batch(REASON_INSUFFICIENT_ORE, total_conversions, 0, 0, minerals)
		taken.append({&"ore_id": ore_id, &"units": ore_units})

	var list := jobs(profile)
	var job_ids: Array[int] = []
	for row: Dictionary in plan:
		var job := _new_job(profile, row[&"mineral_id"], int(row[&"conversions"]), int(row[&"fee"]))
		job_ids.append(int(job[&"id"]))
		list.append(job)
	_write_jobs(profile, list)
	settle(profile)

	Log.append("REFINE", &"all", total_ore, -total_fee, int(profile.call(&"credits")))
	var result := _batch(&"", total_conversions, total_conversions, total_fee, minerals)
	result[&"job_ids"] = job_ids
	return result


## R7's CANCEL: drop a pending or running job, refund its fee through the credits
## door and return its ore to input, cap-checked (what does not fit goes to the
## hold). A done job is refused - it awaits collection.
## Returns `{ok, reason, job_id, fee, ore_returned}`.
static func cancel(profile: Node, job_id: int) -> Dictionary:
	var list := jobs(profile)
	var index := -1
	for i in list.size():
		if int(list[i].get(&"id", -1)) == job_id:
			index = i
			break
	if index < 0:
		return {&"ok": false, &"reason": REASON_UNKNOWN_JOB, &"job_id": job_id, &"fee": 0, &"ore_returned": 0}
	var job: Dictionary = list[index]
	if StringName(job.get(&"state", JOB_PENDING)) == JOB_DONE:
		return {&"ok": false, &"reason": REASON_JOB_DONE, &"job_id": job_id, &"fee": 0, &"ore_returned": 0}

	var mineral_id := StringName(job.get(&"mineral_id", &""))
	var ore_id: StringName = Catalog.ore_id(mineral_id)
	var ore_units := int(job.get(&"conversions", 0)) * ORE_PER_INGOT
	var fee := int(job.get(&"fee", 0))

	list.remove_at(index)
	_write_jobs(profile, list)
	if fee > 0:
		profile.call(&"add_credits", fee)

	var to_input := 0
	var to_hold := 0
	if ore_id != &"":
		var space := maxi(INPUT_CAP - input_total(profile), 0)
		to_input = mini(ore_units, space)
		to_hold = ore_units - to_input
		if to_input > 0:
			_add_input(profile, ore_id, to_input)
		if to_hold > 0:
			profile.call(&"add_cargo", ore_id, to_hold)

	Log.append("REFINE_CANCEL", ore_id, ore_units, fee, int(profile.call(&"credits")))
	return {&"ok": true, &"reason": &"", &"job_id": job_id, &"fee": fee, &"ore_returned": ore_units}


## R6: complete every finished job into `refinery_output` (cap-checked), promote
## pending jobs into free slots and start their countdown. Idempotent. Returns how
## many jobs moved their conversions into output this call.
static func settle(profile: Node) -> int:
	if profile == null or not profile.has_method(&"refinery_jobs"):
		return 0
	var list := jobs(profile)
	if list.is_empty():
		return 0
	var now := int(Time.get_unix_time_from_system())
	var changed := false
	var completed := 0

	for job: Dictionary in list:
		if StringName(job.get(&"state", JOB_PENDING)) == JOB_RUNNING and now >= int(job.get(&"ready_at", 0)):
			job[&"state"] = JOB_DONE
			changed = true

	for job: Dictionary in list:
		if StringName(job.get(&"state", JOB_PENDING)) != JOB_DONE:
			continue
		if bool(job.get(&"settled", false)):
			continue
		var conversions := int(job.get(&"conversions", 0))
		var ingot_id: StringName = Catalog.ingot_id(StringName(job.get(&"mineral_id", &"")))
		if ingot_id == &"" or conversions <= 0:
			continue
		if output_total(profile) + conversions > OUTPUT_CAP:
			continue
		_add_output(profile, ingot_id, conversions)
		job[&"settled"] = true
		completed += 1
		changed = true

	var running := 0
	for job: Dictionary in list:
		if StringName(job.get(&"state", JOB_PENDING)) == JOB_RUNNING:
			running += 1
	var capacity := slots(profile)
	for job: Dictionary in list:
		if running >= capacity:
			break
		if StringName(job.get(&"state", JOB_PENDING)) != JOB_PENDING:
			continue
		var conversions := int(job.get(&"conversions", 0))
		job[&"state"] = JOB_RUNNING
		job[&"ready_at"] = now + conversions * resource_seconds(StringName(job.get(&"mineral_id", &"")))
		running += 1
		changed = true

	if changed:
		_write_jobs(profile, list)
	return completed


## R5's LOAD: move `units` ore of one mineral from the hold into `refinery_input`,
## refused whole when the input would exceed its cap. Moves no credits.
## Returns `{ok, reason, mineral_id, units, input_total}`.
static func load_ore(profile: Node, mineral_id: StringName, units: int) -> Dictionary:
	if Catalog.mineral(mineral_id).is_empty():
		return {&"ok": false, &"reason": REASON_UNKNOWN_MINERAL, &"mineral_id": mineral_id, &"units": 0, &"input_total": input_total(profile)}
	if units < 1:
		return {&"ok": false, &"reason": REASON_INVALID_COUNT, &"mineral_id": mineral_id, &"units": 0, &"input_total": input_total(profile)}
	var ore_id: StringName = Catalog.ore_id(mineral_id)
	if int(profile.call(&"cargo_qty", ore_id)) < units:
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_ORE, &"mineral_id": mineral_id, &"units": 0, &"input_total": input_total(profile)}
	var space := INPUT_CAP - input_total(profile)
	if units > space:
		return {&"ok": false, &"reason": REASON_INPUT_FULL, &"mineral_id": mineral_id, &"units": 0, &"input_total": input_total(profile)}
	if not bool(profile.call(&"remove_cargo", ore_id, units)):
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_ORE, &"mineral_id": mineral_id, &"units": 0, &"input_total": input_total(profile)}
	_add_input(profile, ore_id, units)
	return {&"ok": true, &"reason": &"", &"mineral_id": mineral_id, &"units": units, &"input_total": input_total(profile)}


## R8's COLLECT ALL: move `refinery_output` into the hold, space permitting; the
## overflow stays in output. Done-and-settled jobs whose ingots were collected
## leave the job list. Returns `{ok, reason, collected, remaining}`.
static func collect_all(profile: Node) -> Dictionary:
	var output := _output(profile)
	if output.is_empty():
		return {&"ok": false, &"reason": REASON_NOTHING_TO_REFINE, &"collected": 0, &"remaining": 0}
	var capacity := _hold_capacity(profile)
	var used := _hold_used(profile)
	var remaining := output.duplicate()
	var collected := 0
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry.get(&"id", &"")
		var ingot_id: StringName = Catalog.ingot_id(mineral_id)
		var qty := int(remaining.get(ingot_id, 0))
		if qty <= 0:
			continue
		var take := qty
		if capacity >= 0:
			take = clampi(qty, 0, maxi(capacity - used, 0))
		if take <= 0:
			continue
		profile.call(&"add_cargo", ingot_id, take)
		used += take
		collected += take
		if take >= qty:
			remaining.erase(ingot_id)
		else:
			remaining[ingot_id] = qty - take
	_write_output(profile, remaining)
	_prune_collected(profile, remaining)
	return {&"ok": true, &"reason": &"", &"collected": collected, &"remaining": _total(remaining)}


## R4: buy one slot for `SLOT_UPGRADE_COST` flat, hardcap `MAX_SLOTS`.
## Returns `{ok, reason, slots, cost}`.
static func upgrade_slots(profile: Node) -> Dictionary:
	var current := slots(profile)
	if current >= MAX_SLOTS:
		return {&"ok": false, &"reason": REASON_MAX_SLOTS, &"slots": current, &"cost": 0}
	var cost := SLOT_UPGRADE_COST
	if int(profile.call(&"credits")) < cost:
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_CREDITS, &"slots": current, &"cost": cost}
	if not bool(profile.call(&"spend", cost)):
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_CREDITS, &"slots": current, &"cost": cost}
	var next := current + 1
	profile.call(&"set_refinery_slots", next)
	settle(profile)
	Log.append("REFINE_SLOT", &"refinery_slots", 1, -cost, int(profile.call(&"credits")))
	return {&"ok": true, &"reason": &"", &"slots": next, &"cost": cost}


## --------------------------------------------------------------------- internals


static func _new_job(profile: Node, mineral_id: StringName, conversions: int, fee: int) -> Dictionary:
	var id := int(profile.call(&"refinery_next_job_id"))
	profile.call(&"set_refinery_next_job_id", id + 1)
	return {
		&"id": id,
		&"mineral_id": mineral_id,
		&"conversions": conversions,
		&"ready_at": 0,
		&"state": JOB_PENDING,
		&"fee": fee,
		&"settled": false,
	}


## Drop the done-and-settled jobs whose ingots have actually left `output` (the
## post-collect store). A job whose mineral still holds units in output has not
## been collected, so its row stays listed: a zero-yield collect over a full hold
## prunes nothing and the row leaves only as the output drains (F1).
static func _prune_collected(profile: Node, output: Dictionary) -> void:
	var list := jobs(profile)
	var kept: Array[Dictionary] = []
	for job: Dictionary in list:
		if _is_collected(job, output):
			continue
		kept.append(job)
	if kept.size() != list.size():
		_write_jobs(profile, kept)


## A done-and-settled job counts as collected only once its mineral's ingots have
## left `output`.
static func _is_collected(job: Dictionary, output: Dictionary) -> bool:
	if StringName(job.get(&"state", JOB_PENDING)) != JOB_DONE:
		return false
	if not bool(job.get(&"settled", false)):
		return false
	var ingot_id: StringName = Catalog.ingot_id(StringName(job.get(&"mineral_id", &"")))
	return int(output.get(ingot_id, 0)) <= 0


static func _count_state(profile: Node, state: StringName) -> int:
	var count := 0
	for job: Dictionary in jobs(profile):
		if StringName(job.get(&"state", JOB_PENDING)) == state:
			count += 1
	return count


static func _input(profile: Node) -> Dictionary:
	return _read_qty(profile, &"refinery_input")


static func _output(profile: Node) -> Dictionary:
	return _read_qty(profile, &"refinery_output")


static func _read_qty(profile: Node, key: StringName) -> Dictionary:
	if profile == null or not profile.has_method(key):
		return {}
	var raw: Variant = profile.call(key)
	if not raw is Dictionary:
		return {}
	return raw as Dictionary


static func _total(source: Dictionary) -> int:
	var sum := 0
	for key: Variant in source:
		sum += int(source[key])
	return sum


static func _add_input(profile: Node, ore_id: StringName, units: int) -> void:
	if units <= 0 or ore_id == &"":
		return
	var store := _input(profile)
	store[ore_id] = int(store.get(ore_id, 0)) + units
	_write_input(profile, store)


static func _take_input(profile: Node, ore_id: StringName, units: int) -> bool:
	var store := _input(profile)
	var held := int(store.get(ore_id, 0))
	if held < units:
		return false
	if held == units:
		store.erase(ore_id)
	else:
		store[ore_id] = held - units
	_write_input(profile, store)
	return true


static func _add_output(profile: Node, ingot_id: StringName, units: int) -> void:
	if units <= 0 or ingot_id == &"":
		return
	var store := _output(profile)
	store[ingot_id] = int(store.get(ingot_id, 0)) + units
	_write_output(profile, store)


static func _write_input(profile: Node, store: Dictionary) -> void:
	profile.call(&"set_refinery_input", store)


static func _write_output(profile: Node, store: Dictionary) -> void:
	profile.call(&"set_refinery_output", store)


static func _write_jobs(profile: Node, list: Array) -> void:
	profile.call(&"set_refinery_jobs", list)


## The active hull's resolved cargo capacity (the hold cap), or -1 when the
## profile cannot resolve one - the unbounded fallback a stub deserves.
static func _hold_capacity(profile: Node) -> int:
	if profile == null or not profile.has_method(&"active_ship") or not profile.has_method(&"resolved_fit"):
		return -1
	var ship := StringName(profile.call(&"active_ship"))
	if ship == &"":
		return -1
	var stored: Variant = profile.call(&"resolved_fit", ship)
	if not stored is Dictionary:
		return -1
	var fit: Dictionary = profile.call(&"base_fit", stored as Dictionary)
	var summary: Variant = {}
	if profile.has_method(&"affix_summary"):
		summary = profile.call(&"affix_summary", ship)
	var stats: ShipStats = ShipFitScript.resolve(ship, fit, summary if summary is Dictionary else {})
	if stats == null:
		return -1
	return int(stats.cargo_max)


static func _hold_used(profile: Node) -> int:
	if profile == null or not profile.has_method(&"cargo_items"):
		return 0
	var raw: Variant = profile.call(&"cargo_items")
	if not raw is Dictionary:
		return 0
	return _total(raw as Dictionary)


static func _refusal(reason: StringName, mineral_id: StringName, conversions: int) -> Dictionary:
	return {
		&"ok": false,
		&"reason": reason,
		&"mineral_id": mineral_id,
		&"conversions": conversions,
		&"ore_taken": 0,
		&"ingots": 0,
		&"fee": 0,
		&"job_id": -1,
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
