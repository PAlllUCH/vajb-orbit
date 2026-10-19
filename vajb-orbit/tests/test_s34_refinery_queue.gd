@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## S34 refinery queue suite: the timed job model, its slots, its inventory and its
## persistence. Contract: docs/gameplay/04_refinery.md section 7 (values R1-R8) and
## STATION_HUB section 21.3 (P42/P43). File under test: game/refinery.gd plus the
## `refinery_*` doors in autoload/player_profile.gd.
##
## Every profile is a throwaway instance of autoload/player_profile.gd with
## save_path pointed at user://test_s34_refinery.cfg before the first mutation and
## EconomyLog.log_path pointed at user://test_s34_log.txt; both files are deleted
## before every test and again in teardown, so the real user://profile.cfg and
## user://economy_log.txt are never touched.

const Ref := preload("res://game/refinery.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "s34_refinery_queue"
const SAVE_PATH := "user://test_s34_refinery.cfg"
const LOG_PATH := "user://test_s34_log.txt"
const SECTION := "profile"
const VANGUARD_CARGO := 40

var _profile: Node = null
var _signals: Array[StringName] = []


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	Log.log_path = LOG_PATH
	_delete_files()


func setup() -> void:
	_delete_files()
	_profile = load("res://autoload/player_profile.gd").new()
	_profile.save_path = SAVE_PATH


func teardown() -> void:
	if _profile != null and is_instance_valid(_profile):
		_profile.free()
	_profile = null
	_delete_files()


func suite_teardown() -> void:
	_delete_files()
	Log.log_path = Log.DEFAULT_PATH


func _delete_files() -> void:
	Support.delete_file(LOG_PATH)
	Support.delete_file(SAVE_PATH)

func _force_ready() -> void:
	var jobs := Ref.jobs(_profile)
	for job: Dictionary in jobs:
		job[&"ready_at"] = 0
	_profile.call(&"set_refinery_jobs", jobs)


## Load `units` of one mineral from the hold, asserting the load succeeded.
func _load(mineral_id: StringName, units: int) -> void:
	_profile.add_cargo(Catalog.ore_id(mineral_id), units)
	assert_true(
		bool(Ref.load_ore(_profile, mineral_id, units)[&"ok"]),
		"%d %s ore load" % [units, String(mineral_id)]
	)


## --------------------------------------------------------------- 1. R1 formula


func test_resource_seconds_is_the_r1_formula() -> void:
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry[&"id"]
		var expected := clampi(roundi(float(int(entry[&"ingot_value"])) / 10.0), 10, 60)
		assert_eq(
			Ref.resource_seconds(mineral_id),
			expected,
			"%s reads clamp(round(ingot_value/10), 10, 60)" % String(mineral_id)
		)
	assert_eq(Ref.resource_seconds(&"iron"), 10, "Iron is about 10 s a conversion")
	assert_eq(Ref.resource_seconds(&"gold"), 26, "Gold is about 26 s a conversion")
	assert_eq(Ref.resource_seconds(&"copper"), 10, "a cheap tier-1 ore floors at 10")
	assert_eq(Ref.resource_seconds(&"krilium"), 60, "the apex ore ceilings at 60")
	assert_eq(Ref.resource_seconds(&"unobtainium"), 10, "an unknown mineral floors at 10")


## ------------------------------------------------- 2. queue all-or-nothing


func test_queue_is_all_or_nothing_on_every_failure_path() -> void:
	# No input ore: nothing charged, no job.
	var credits_before: int = _profile.credits()
	var no_ore := Ref.queue(_profile, &"iron", 1)
	assert_false(bool(no_ore[&"ok"]), "an empty input refuses")
	assert_eq(no_ore[&"reason"], Ref.REASON_INSUFFICIENT_ORE, "reason insufficient_ore")
	assert_eq(_profile.credits(), credits_before, "credits untouched")
	assert_eq(Ref.jobs(_profile).size(), 0, "no job")

	# Too little credit: the input stays loaded, nothing charged.
	_load(&"iron", 3)
	assert_true(_profile.spend(credits_before - 10), "drain to 10 CR")
	var poor := Ref.queue(_profile, &"iron", 1)
	assert_false(bool(poor[&"ok"]), "10 CR cannot pay a 15 CR fee")
	assert_eq(poor[&"reason"], Ref.REASON_INSUFFICIENT_CREDITS, "reason insufficient_credits")
	assert_eq(Ref.input_units(_profile, &"iron"), 3, "input untouched")
	assert_eq(_profile.credits(), 10, "credits untouched")
	assert_eq(Ref.jobs(_profile).size(), 0, "no job")

	# Invalid count and unknown mineral.
	assert_eq(Ref.queue(_profile, &"iron", 0)[&"reason"], Ref.REASON_INVALID_COUNT, "0 conversions refuses")
	assert_eq(
		Ref.queue(_profile, &"unobtainium", 1)[&"reason"],
		Ref.REASON_UNKNOWN_MINERAL,
		"an unknown mineral refuses"
	)

	# The success path: fee spent, ore taken, one job minted.
	_profile.add_credits(1000)
	var before: int = _profile.credits()
	var result := Ref.queue(_profile, &"iron", 1)
	assert_true(bool(result[&"ok"]), "a funded, loaded batch queues")
	assert_eq(_profile.credits(), before - 15, "the 15 CR fee left the balance")
	assert_eq(Ref.input_units(_profile, &"iron"), 0, "the ore left the input")
	assert_eq(Ref.jobs(_profile).size(), 1, "one job")
	assert_eq(int(result[&"job_id"]), 1, "the first job id is 1")


## --------------------------------------------------- 3. cancel refunds and returns


func test_cancel_refunds_the_fee_and_returns_the_ore() -> void:
	_load(&"gold", 6)
	var before: int = _profile.credits()
	var queued := Ref.queue(_profile, &"gold", 2)
	assert_true(bool(queued[&"ok"]), "the batch queues")
	assert_eq(_profile.credits(), before - 40, "40 CR fee charged at queue time (two Gold conversions)")
	assert_eq(Ref.input_units(_profile, &"gold"), 0, "the ore left the input")
	var job_id := int(queued[&"job_id"])
	var cancelled := Ref.cancel(_profile, job_id)
	assert_true(bool(cancelled[&"ok"]), "the job cancels")
	assert_eq(int(cancelled[&"fee"]), 40, "the refund is the charged fee")
	assert_eq(_profile.credits(), before, "credits restored")
	assert_eq(Ref.input_units(_profile, &"gold"), 6, "the ore returned to the input")
	assert_eq(Ref.jobs(_profile).size(), 0, "the job is gone")

	# A job cancelled into a full input sends its ore to the hold instead.
	_profile.call(&"set_refinery_input", {})
	_load(&"iron", 60)
	assert_eq(Ref.input_total(_profile), 60, "the input is at its cap")
	var second := Ref.queue(_profile, &"iron", 1)
	assert_true(bool(second[&"ok"]), "a job queues out of the full input")
	assert_eq(Ref.input_units(_profile, &"iron"), 57, "three ore left the input")
	_load(&"iron", 3)
	assert_eq(Ref.input_total(_profile), 60, "the input is full again")
	var hold_before: int = _profile.cargo_qty(&"mineral_iron")
	var overflow := Ref.cancel(_profile, int(second[&"job_id"]))
	assert_true(bool(overflow[&"ok"]), "the second job cancels")
	assert_eq(Ref.input_units(_profile, &"iron"), 60, "the input stays capped")
	assert_eq(_profile.cargo_qty(&"mineral_iron"), hold_before + 3, "the overflow went to the hold")


## ------------------------------------------------------------- 4. the slot ladder


func test_slot_ladder_two_to_five_at_three_thousand_each() -> void:
	assert_eq(Ref.slots(_profile), 2, "2 slots base")
	assert_eq(_profile.call(&"refinery_slots"), 2, "the profile door reads 2")
	var credits_before: int = _profile.credits()
	var first := Ref.upgrade_slots(_profile)
	assert_true(bool(first[&"ok"]), "the first upgrade buys")
	assert_eq(int(first[&"slots"]), 3, "3 slots")
	assert_eq(_profile.credits(), credits_before - 3000, "3,000 CR flat")
	assert_true(bool(Ref.upgrade_slots(_profile)[&"ok"]), "the second buys")
	var last := Ref.upgrade_slots(_profile)
	assert_true(bool(last[&"ok"]), "the third buys")
	assert_eq(int(last[&"slots"]), 5, "the hardcap is 5")
	var credits_max: int = _profile.credits()
	var refused := Ref.upgrade_slots(_profile)
	assert_false(bool(refused[&"ok"]), "a sixth slot is refused")
	assert_eq(refused[&"reason"], Ref.REASON_MAX_SLOTS, "reason max_slots")
	assert_eq(_profile.credits(), credits_max, "the refusal charges nothing")


func test_slots_run_jobs_in_parallel_and_upgrade_promotes_pending() -> void:
	_load(&"iron", 12)
	var a := Ref.queue(_profile, &"iron", 1)
	var b := Ref.queue(_profile, &"iron", 1)
	var c := Ref.queue(_profile, &"iron", 1)
	assert_true(bool(a[&"ok"]) and bool(b[&"ok"]) and bool(c[&"ok"]), "three jobs queue")
	assert_eq(Ref.running_count(_profile), 2, "2 slots run 2 jobs")
	assert_eq(Ref.pending_count(_profile), 1, "the third waits (FIFO)")
	assert_true(bool(Ref.upgrade_slots(_profile)[&"ok"]), "buy a third slot")
	Ref.settle(_profile)
	assert_eq(Ref.running_count(_profile), 3, "the pending job starts on the new slot")
	assert_eq(Ref.pending_count(_profile), 0, "nothing waits")


## --------------------------------------------------------------- 5. the caps


func test_input_and_output_caps_refuse_and_hold_overflow() -> void:
	# Input cap: an over-cap load is refused whole.
	_profile.add_cargo(&"mineral_iron", 61)
	assert_true(bool(Ref.load_ore(_profile, &"iron", 60)[&"ok"]), "60 ore load")
	assert_eq(Ref.input_total(_profile), 60, "the input holds its cap")
	var over := Ref.load_ore(_profile, &"iron", 1)
	assert_false(bool(over[&"ok"]), "a load past the cap is refused")
	assert_eq(over[&"reason"], Ref.REASON_INPUT_FULL, "reason input_full")
	assert_eq(Ref.input_total(_profile), 60, "the input is untouched")
	assert_eq(_profile.cargo_qty(&"mineral_iron"), 1, "the refused ore stays in the hold")

	# Output cap: a ready job whose ingots do not fit stays done until collected.
	_profile.call(&"set_refinery_input", {})
	_profile.call(&"remove_cargo", &"mineral_iron", _profile.cargo_qty(&"mineral_iron"))
	_profile.call(&"set_refinery_output", {&"ingot_iron": 60})
	assert_eq(Ref.output_total(_profile), 60, "the output is at its cap")
	_profile.add_cargo(&"mineral_gold", 3)
	assert_true(bool(Ref.load_ore(_profile, &"gold", 3)[&"ok"]), "3 Gold ore load")
	var queued := Ref.queue(_profile, &"gold", 1)
	assert_true(bool(queued[&"ok"]), "the Gold job queues")
	_force_ready()
	assert_eq(Ref.settle(_profile), 0, "settle cannot move ingots into a full output")
	var job := Ref.jobs(_profile)[0]
	assert_eq(StringName(job[&"state"]), Ref.JOB_DONE, "the job is done, awaiting collection")
	assert_eq(Ref.output_total(_profile), 60, "the output is unchanged")

	# COLLECT ALL fills the hold and leaves the overflow in the output.
	var collected := Ref.collect_all(_profile)
	assert_true(bool(collected[&"ok"]), "COLLECT ALL runs")
	assert_eq(int(collected[&"collected"]), VANGUARD_CARGO, "the hold takes its 40 units")
	assert_eq(Ref.output_total(_profile), 20, "the overflow stays in the output")
	assert_eq(_profile.cargo_qty(&"ingot_iron"), VANGUARD_CARGO, "the hold holds the iron")
	assert_eq(Ref.settle(_profile), 1, "the freed output settles the waiting job")
	assert_eq(Ref.output_total(_profile), 21, "the Gold ingot landed")


func test_done_row_leaves_only_once_its_ingots_are_collected() -> void:
	# F1: a COLLECT ALL that moves nothing (full hold) must not erase the done row
	# while its ingots still sit in the output.
	_load(&"iron", 3)
	assert_true(bool(Ref.queue(_profile, &"iron", 1)[&"ok"]), "the iron job queues")
	_force_ready()
	assert_eq(Ref.settle(_profile), 1, "the ready job settles into the output")
	_profile.add_cargo(&"ingot_iron", VANGUARD_CARGO)
	var rows_before := Ref.jobs(_profile).size()
	var empty := Ref.collect_all(_profile)
	assert_eq(int(empty[&"collected"]), 0, "a full hold collects nothing")
	assert_eq(Ref.jobs(_profile).size(), rows_before, "the done row stays listed (F1)")
	assert_eq(Ref.output_total(_profile), 1, "the ingot stays in the output")
	_profile.remove_cargo(&"ingot_iron", VANGUARD_CARGO)
	var drained := Ref.collect_all(_profile)
	assert_eq(int(drained[&"collected"]), 1, "the drain collects the ingot")
	assert_eq(Ref.jobs(_profile).size(), 0, "the drained done row leaves the list")
	assert_eq(Ref.output_total(_profile), 0, "the output is empty")


## ---------------------------------------------------- 6. settle on the wall clock


func test_settle_completes_a_fake_ready_job() -> void:
	_load(&"iron", 3)
	var queued := Ref.queue(_profile, &"iron", 1)
	assert_true(bool(queued[&"ok"]), "the job queues")
	assert_eq(Ref.running_count(_profile), 1, "and starts on a slot")
	assert_eq(Ref.settle(_profile), 0, "a job that is not ready settles nothing")
	assert_eq(Ref.output_total(_profile), 0, "no ingots yet")
	var job := Ref.jobs(_profile)[0]
	var expected_ready := int(Time.get_unix_time_from_system()) + Ref.resource_seconds(&"iron")
	assert_true(int(job[&"ready_at"]) >= expected_ready - 2, "ready_at is the wall clock plus R1")
	_force_ready()
	assert_eq(Ref.settle(_profile), 1, "the ready job completes")
	assert_eq(_profile.call(&"refinery_output").get(&"ingot_iron", 0), 1, "one ingot in the output")
	assert_eq(StringName(Ref.jobs(_profile)[0][&"state"]), Ref.JOB_DONE, "the job is done")
	assert_true(bool(Ref.collect_all(_profile)[&"ok"]), "COLLECT ALL runs")
	assert_eq(_profile.cargo_qty(&"ingot_iron"), 1, "the ingot reached the hold")
	assert_eq(Ref.jobs(_profile).size(), 0, "a collected job leaves the list")


## ---------------------------------------------- 7. QUEUE ALL and FIFO pending


func test_queue_all_queues_one_job_per_mineral_fifo() -> void:
	_load(&"iron", 3)
	_load(&"copper", 6)
	_load(&"gold", 3)
	var batch := Ref.queue_all(_profile)
	assert_true(bool(batch[&"ok"]), "the batch queues")
	assert_eq((batch[&"job_ids"] as Array).size(), 3, "one job per mineral")
	assert_eq(Ref.running_count(_profile), 2, "2 slots run the first two")
	assert_eq(Ref.pending_count(_profile), 1, "the third waits FIFO")
	var jobs := Ref.jobs(_profile)
	assert_eq(StringName(jobs[0][&"mineral_id"]), &"iron", "catalogue order: Iron")
	assert_eq(StringName(jobs[1][&"mineral_id"]), &"copper", "then Copper")
	assert_eq(StringName(jobs[2][&"mineral_id"]), &"gold", "Gold waits")
	assert_eq(StringName(jobs[2][&"state"]), Ref.JOB_PENDING, "the tail job is pending")


## ------------------------------------------------- 8. save round-trip and defaults


func test_refinery_keys_round_trip_and_old_saves_default() -> void:
	_profile.call(&"set_refinery_slots", 4)
	_profile.call(&"set_refinery_input", {&"mineral_iron": 12})
	_profile.call(&"set_refinery_output", {&"ingot_gold": 3})
	_profile.call(&"set_refinery_jobs", [
		{&"id": 7, &"mineral_id": &"gold", &"conversions": 2, &"ready_at": 12345, &"state": &"running", &"fee": 30, &"settled": false},
	])
	_profile.call(&"set_refinery_next_job_id", 8)
	_profile.call(&"reload")
	assert_eq(_profile.call(&"refinery_slots"), 4, "slots round-trip")
	assert_eq(int(_profile.call(&"refinery_input").get(&"mineral_iron", 0)), 12, "input round-trips")
	assert_eq(int(_profile.call(&"refinery_output").get(&"ingot_gold", 0)), 3, "output round-trips")
	assert_eq(_profile.call(&"refinery_jobs").size(), 1, "jobs round-trip")
	assert_eq(int(_profile.call(&"refinery_jobs")[0][&"conversions"]), 2, "the job's payload round-trips")
	assert_eq(_profile.call(&"refinery_next_job_id"), 8, "the id counter round-trips")

	# A pre-S34 save (no refinery keys) loads at the defaults.
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 7)
	fixture.set_value(SECTION, "credits", 5000)
	assert_eq(fixture.save(SAVE_PATH), OK, "an old-save fixture is written")
	_profile.call(&"reload")
	assert_eq(_profile.call(&"refinery_slots"), 2, "slots default to 2")
	assert_true((_profile.call(&"refinery_input") as Dictionary).is_empty(), "input defaults empty")
	assert_true((_profile.call(&"refinery_output") as Dictionary).is_empty(), "output defaults empty")
	assert_true((_profile.call(&"refinery_jobs") as Array).is_empty(), "jobs default empty")
	assert_eq(_profile.call(&"refinery_next_job_id"), 1, "the id counter defaults to 1")


func test_every_refinery_write_emits_the_refinery_signal() -> void:
	_signals.clear()
	_profile.profile_changed.connect(_on_profile_changed)
	_profile.call(&"set_refinery_input", {&"mineral_iron": 3})
	_profile.call(&"set_refinery_slots", 3)
	assert_eq(_signals.size(), 2, "two writes, two signals")
	assert_eq(_signals[0], &"refinery", "the input write emits &\"refinery\"")
	assert_eq(_signals[1], &"refinery", "the slot write emits &\"refinery\"")
	_profile.profile_changed.disconnect(_on_profile_changed)


func _on_profile_changed(key: StringName) -> void:
	_signals.append(key)
