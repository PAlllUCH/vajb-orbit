@tool
extends McpTestSuite
## P1 refinery suite: the ore -> ingot conversion, its fee sink and its log.
## Contract: docs/gameplay/04_refinery.md sections 2 (the conversion rule) and
## 3 (the fee schedule), amended by section 7 (S34: jobs, slots, inventory),
## docs/gameplay/17_coder_handoff.md section 6 (the 04 checklist item). File under
## test: game/refinery.gd.
##
## The instant-conversion rows restated as queue / settle / collect rows (S34,
## disclosed in S34-B1_report.md): a confirmed batch is now one job that finishes
## on the wall clock, so each row drives `queue` (or `queue_all`), forces the job
## ready and `settle`s it, then `collect_all`s the output into the hold. The
## `test_stacks_lists_only_convertible_minerals` row (the sealed row, the S34 brief
## section 7) is unchanged.
##
## Every profile is a throwaway instance of autoload/player_profile.gd with
## save_path pointed at user://test_p1_refinery.cfg before the first mutation,
## and EconomyLog.log_path pointed at user://test_p1_log.txt; both files are
## deleted before every test and again in teardown, so the real
## user://profile.cfg and user://economy_log.txt are never touched.
## Scripts are preloaded by path on purpose (project convention).

const Ref := preload("res://game/refinery.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "p1_refinery"
const SAVE_PATH := "user://test_p1_refinery.cfg"
const LOG_PATH := "user://test_p1_log.txt"

var _profile: Node = null


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
	_delete(LOG_PATH)
	_delete(SAVE_PATH)


func _delete(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(path.get_base_dir())
	if dir != null:
		dir.remove(path.get_file())


## Log lines carrying the given event marker, in file order.
func _lines_with(marker: String) -> PackedStringArray:
	var matches := PackedStringArray()
	if not FileAccess.file_exists(LOG_PATH):
		return matches
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return matches
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n", false):
		if line.find(marker) != -1:
			matches.append(line)
	return matches


## Force every job ready (the fake-ready probe, 04 section 7.1 R6): the wall clock
## is not waited on in a test, so the job's `ready_at` is written into the past.
func _force_ready() -> void:
	var jobs := Ref.jobs(_profile)
	for job: Dictionary in jobs:
		job[&"ready_at"] = 0
	_profile.call(&"set_refinery_jobs", jobs)


## queue -> force ready -> settle -> collect, the whole S34 pipeline, returning the
## settle's completed count.
func _finish() -> int:
	_force_ready()
	var completed := Ref.settle(_profile)
	Ref.collect_all(_profile)
	return completed


## 17 section 6, the 04 checklist item, restated for S34: 3 Iron ore loaded into the
## input becomes one job, finishes into `refinery_output`, and collecting it pays
## exactly one Iron ingot for one 15 CR fee.
func test_iron_three_ore_becomes_one_ingot() -> void:
	_profile.add_cargo(&"mineral_iron", 3)
	var loaded := Ref.load_ore(_profile, &"iron", 3)
	assert_true(bool(loaded[&"ok"]), "3 Iron ore loads into the input")
	assert_eq(Ref.input_units(_profile, &"iron"), 3, "the input holds 3 ore")
	var credits_before: int = _profile.credits()
	var result := Ref.queue(_profile, &"iron", 1)
	assert_true(bool(result[&"ok"]), "queue must succeed: %s" % String(result[&"reason"]))
	assert_eq(int(result[&"conversions"]), 1, "one conversion")
	assert_eq(int(result[&"ore_taken"]), 3, "three ore units taken from the input")
	assert_eq(int(result[&"ingots"]), 1, "one ingot promised")
	assert_eq(int(result[&"fee"]), 15, "the fee is 15 CR")
	assert_eq(Ref.input_units(_profile, &"iron"), 0, "all three ore left the input")
	assert_eq(_profile.cargo_qty(&"ingot_iron"), 0, "nothing is in the hold before settle")
	assert_eq(_profile.credits(), credits_before - 15, "credits minus the fee")
	var completed := _finish()
	assert_eq(completed, 1, "settle completed the one job")
	assert_eq(_profile.cargo_qty(&"ingot_iron"), 1, "exactly one Iron ingot in the hold")
	var lines := _lines_with(", REFINE, ")
	assert_eq(lines.size(), 1, "exactly one REFINE log line")
	assert_contains(
		lines[0],
		", REFINE, mineral_iron, 3, -15, %d" % _profile.credits(),
		"log line shape: event, item, qty, delta, balance"
	)


func test_partial_stack_converts_whole_units_only() -> void:
	_profile.add_cargo(Catalog.ore_id(&"gold"), 8)
	assert_eq(Ref.load_ore(_profile, &"gold", 8)[&"ok"], true, "8 Gold ore loads")
	var credits_before: int = _profile.credits()
	var result := Ref.queue(_profile, &"gold", 2)
	assert_true(bool(result[&"ok"]), "queue must succeed: %s" % String(result[&"reason"]))
	assert_eq(int(result[&"fee"]), 30, "one fee for the whole batch")
	assert_eq(Ref.input_units(_profile, &"gold"), 2, "2 leftover ore stay in the input")
	assert_eq(Ref.input_conversions(_profile, &"gold"), 0, "the leftovers are no longer convertible")
	assert_eq(_profile.credits(), credits_before - 30, "credits minus the batch fee")
	_finish()
	assert_eq(_profile.cargo_qty(Catalog.ingot_id(&"gold")), 2, "2 ingots held")
	assert_false(
		bool(Ref.queue(_profile, &"gold", 1)[&"ok"]),
		"a sub-conversion remainder cannot be queued"
	)


func test_refusals_leave_everything_untouched() -> void:
	# Too little ore in the input.
	_profile.add_cargo(&"mineral_iron", 2)
	assert_true(bool(Ref.load_ore(_profile, &"iron", 2)[&"ok"]), "2 ore load")
	var credits_before: int = _profile.credits()
	var short := Ref.queue(_profile, &"iron", 1)
	assert_false(bool(short[&"ok"]), "2 ore cannot make a conversion")
	assert_eq(short[&"reason"], Ref.REASON_INSUFFICIENT_ORE, "reason is insufficient_ore")
	assert_eq(Ref.input_units(_profile, &"iron"), 2, "input untouched")
	assert_eq(_profile.credits(), credits_before, "credits untouched")
	assert_eq(Ref.jobs(_profile).size(), 0, "no job queued")

	# Too little credit.
	_profile.add_cargo(&"mineral_iron", 1)
	assert_true(bool(Ref.load_ore(_profile, &"iron", 1)[&"ok"]), "the third ore loads")
	assert_eq(Ref.input_units(_profile, &"iron"), 3, "the input holds a conversion")
	assert_true(_profile.spend(credits_before - 10), "drain the account down to 10 CR")
	var poor := Ref.queue(_profile, &"iron", 1)
	assert_false(bool(poor[&"ok"]), "10 CR cannot pay a 15 CR fee")
	assert_eq(poor[&"reason"], Ref.REASON_INSUFFICIENT_CREDITS, "reason is insufficient_credits")
	assert_eq(_profile.credits(), 10, "credits untouched")
	assert_eq(Ref.input_units(_profile, &"iron"), 3, "input untouched")
	assert_eq(Ref.jobs(_profile).size(), 0, "no job queued")
	assert_eq(int(poor[&"fee"]), 0, "a refused batch is charged nothing")

	# Unknown mineral.
	var credits_after: int = _profile.credits()
	var unknown := Ref.queue(_profile, &"unobtainium", 1)
	assert_false(bool(unknown[&"ok"]), "an unknown mineral is refused")
	assert_eq(unknown[&"reason"], Ref.REASON_UNKNOWN_MINERAL, "reason is unknown_mineral")
	assert_eq(_profile.credits(), credits_after, "credits untouched")
	assert_eq(Ref.input_conversions(_profile, &"unobtainium"), 0, "no conversions for an unknown mineral")

	assert_eq(_lines_with(", REFINE, ").size(), 0, "refusals write no log line")


func test_queue_all_charges_one_combined_fee() -> void:
	_profile.add_cargo(&"mineral_iron", 3)
	_profile.add_cargo(&"mineral_gold", 6)
	assert_true(bool(Ref.load_ore(_profile, &"iron", 3)[&"ok"]), "Iron loads")
	assert_true(bool(Ref.load_ore(_profile, &"gold", 6)[&"ok"]), "Gold loads")
	var credits_before: int = _profile.credits()
	var batch := Ref.queue_all(_profile)
	assert_true(bool(batch[&"ok"]), "the batch must succeed: %s" % String(batch[&"reason"]))
	assert_eq(int(batch[&"conversions"]), 3, "1 Iron + 2 Gold conversions")
	assert_eq(int(batch[&"ingots"]), 3, "3 ingots out")
	assert_eq(int(batch[&"fee"]), 45, "one combined fee (15 + 30)")
	var minerals: Array = batch[&"minerals"]
	assert_eq(minerals.size(), 2, "two minerals converted")
	assert_eq(StringName(minerals[0]), &"iron", "catalogue order: Iron first")
	assert_eq(StringName(minerals[1]), &"gold", "then Gold")
	assert_eq((batch[&"job_ids"] as Array).size(), 2, "one job per mineral (R7)")
	assert_eq(Ref.input_units(_profile, &"iron"), 0, "Iron input consumed")
	assert_eq(Ref.input_units(_profile, &"gold"), 0, "Gold input consumed")
	assert_eq(_profile.credits(), credits_before - 45, "credits minus the combined fee")
	_finish()
	assert_eq(_profile.cargo_qty(&"ingot_iron"), 1, "1 Iron ingot")
	assert_eq(_profile.cargo_qty(&"ingot_gold"), 2, "2 Gold ingots")
	var lines := _lines_with(", REFINE, ")
	assert_eq(lines.size(), 1, "one combined REFINE line, not one per mineral")
	assert_contains(
		lines[0],
		", REFINE, all, 9, -45, %d" % _profile.credits(),
		"combined log line: item all, total ore taken, total fee"
	)


func test_nothing_to_queue() -> void:
	_profile.add_cargo(&"mineral_iron", 2)
	_profile.add_cargo(&"mineral_copper", 1)
	var credits_before: int = _profile.credits()
	var batch := Ref.queue_all(_profile)
	assert_false(bool(batch[&"ok"]), "an empty input has nothing to queue")
	assert_eq(batch[&"reason"], Ref.REASON_NOTHING_TO_QUEUE, "reason is nothing_to_queue")
	assert_eq(int(batch[&"fee"]), 0, "nothing is charged")
	assert_eq(int(batch[&"conversions"]), 0, "nothing is converted")
	assert_eq(_profile.credits(), credits_before, "credits untouched")
	assert_eq(Ref.input_units(_profile, &"iron"), 0, "input untouched")
	assert_eq(Ref.jobs(_profile).size(), 0, "no jobs")
	assert_eq(Ref.stacks(_profile).size(), 0, "no convertible stacks")
	assert_eq(_lines_with(", REFINE, ").size(), 0, "no log line")


func test_stacks_lists_only_convertible_minerals() -> void:
	assert_eq(Ref.stacks(_profile).size(), 0, "an empty hold has no stacks")
	_profile.add_cargo(&"mineral_iron", 7)
	_profile.add_cargo(&"mineral_gold", 3)
	_profile.add_cargo(&"mineral_copper", 2)
	_profile.add_cargo(&"comp_scrap_1", 5)
	var rows := Ref.stacks(_profile)
	assert_eq(rows.size(), 2, "only minerals holding 3 or more ore")
	assert_eq(StringName(rows[0][&"mineral_id"]), &"iron", "catalogue order first")
	assert_eq(int(rows[0][&"ore_qty"]), 7, "Iron ore count")
	assert_eq(int(rows[0][&"conversions"]), 2, "Iron conversions")
	assert_eq(int(rows[0][&"fee"]), 30, "Iron fee")
	assert_eq(StringName(rows[1][&"mineral_id"]), &"gold", "then Gold")
	assert_eq(int(rows[1][&"ore_qty"]), 3, "Gold ore count")
	assert_eq(int(rows[1][&"conversions"]), 1, "Gold conversions")
	assert_eq(int(rows[1][&"fee"]), 15, "Gold fee")
	var listed: Array[StringName] = []
	for row: Dictionary in rows:
		listed.append(StringName(row[&"mineral_id"]))
	assert_false(listed.has(&"copper"), "2 Copper ore is not convertible")
	assert_false(listed.has(&"comp_scrap_1"), "components never refine")
	assert_eq(Ref.convertible(_profile, &"iron"), 2, "Iron convertible count")
	assert_eq(Ref.convertible(_profile, &"copper"), 0, "Copper convertible count")
	assert_eq(Ref.fee_for(0), 0, "no conversions, no fee")
	assert_eq(Ref.fee_for(3), 45, "3 conversions cost 45 CR")
	assert_eq(Ref.ORE_PER_INGOT, 3, "the 04 section 2 ratio")
	assert_eq(Ref.FEE_PER_CONVERSION, 15, "the 04 section 3 fee per conversion")
