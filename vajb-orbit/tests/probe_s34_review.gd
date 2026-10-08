extends Node
## S34-R1 review probe: independent re-measurement of the S34-B1 deliverable
## against the S34 brief's acceptance list (04 section 7 R1-R8, STATION_HUB 21.3).
##
##   godot --headless --path vajb-orbit res://tests/probe_s34_review.tscn --quit-after 300
##
## Signal: one [S34R] line per check; the last line is [S34R] PASS or [S34R] FAIL n.
## The shipped PlayerProfile autoload is borrowed with save_path repointed at the
## scratch file (the L17/T-93 hygiene idiom) and every snapshot field is restored
## in _teardown; the real user://profile.cfg is never written.

const Ref := preload("res://game/refinery.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const Log := preload("res://game/economy_log.gd")
const RefineryScene := preload("res://ui/station/refinery_panel.tscn")

const SCRATCH_PROFILE := "user://probe_s34_review.cfg"
const SCRATCH_LOG := "user://probe_s34_review_log.txt"

var _profile: Node = null
var _failures := 0
var _saved := {}


func _ready() -> void:
	await get_tree().process_frame
	_borrow()
	_probe_r1()
	_probe_queue_all_or_nothing()
	_probe_duration()
	_probe_queue_all_fifo()
	_probe_slot_ladder()
	_probe_caps()
	_probe_cancel()
	_probe_settle()
	_probe_save_round_trip()
	_teardown()
	await get_tree().process_frame
	_probe_panel()
	print("[S34R] %s %d" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
	print("[S34R] %s %s" % ["ok  " if ok else "FAIL", what])


func _borrow() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"fits": (_profile.get(&"_fits") as Dictionary).duplicate(true),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
		&"credits": int(_profile.call(&"credits")),
		&"slots": int(_profile.call(&"refinery_slots")),
		&"input": (_profile.get(&"_refinery_input") as Dictionary).duplicate(true),
		&"output": (_profile.get(&"_refinery_output") as Dictionary).duplicate(true),
		&"jobs": (_profile.get(&"_refinery_jobs") as Array).duplicate(true),
		&"next_id": int(_profile.call(&"refinery_next_job_id")),
	}
	_profile.set(&"save_path", SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG
	_reset()


func _reset() -> void:
	_profile.set(&"_credits", 100000)
	_profile.set(&"_cargo", {})
	_profile.set(&"_refinery_slots", 2)
	_profile.set(&"_refinery_input", {})
	_profile.set(&"_refinery_output", {})
	_profile.set(&"_refinery_jobs", [])
	_profile.set(&"_refinery_next_job_id", 1)


func _teardown() -> void:
	_profile.set(&"_active_ship", _saved[&"ship"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_cargo", _saved[&"cargo"])
	_profile.set(&"_credits", _saved[&"credits"])
	_profile.set(&"_refinery_slots", _saved[&"slots"])
	_profile.set(&"_refinery_input", _saved[&"input"])
	_profile.set(&"_refinery_output", _saved[&"output"])
	_profile.set(&"_refinery_jobs", _saved[&"jobs"])
	_profile.set(&"_refinery_next_job_id", _saved[&"next_id"])
	_profile.call(&"flush")
	_profile.set(&"save_path", _saved[&"path"])
	Log.log_path = Log.DEFAULT_PATH
	_unlink(SCRATCH_PROFILE)
	_unlink(SCRATCH_LOG)


func _unlink(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.open(path.get_base_dir()).remove(path.get_file())


func _load(mineral_id: StringName, units: int) -> void:
	_profile.call(&"add_cargo", Catalog.ore_id(mineral_id), units)
	_check(bool(Ref.load_ore(_profile, mineral_id, units)[&"ok"]), "load %d %s" % [units, mineral_id])


func _force_ready() -> void:
	var jobs := Ref.jobs(_profile)
	for job: Dictionary in jobs:
		job[&"ready_at"] = 0
	_profile.call(&"set_refinery_jobs", jobs)


## ---------------------------------------------------------------- R1


func _probe_r1() -> void:
	_check(Ref.resource_seconds(&"iron") == 10, "R1 Iron 10 s")
	_check(Ref.resource_seconds(&"gold") == 26, "R1 Gold 26 s")
	_check(Ref.resource_seconds(&"copper") == 10, "R1 Copper floors at 10")
	_check(Ref.resource_seconds(&"krilium") == 60, "R1 Krilium ceilings at 60")
	_check(Ref.resource_seconds(&"unobtainium") == 10, "R1 unknown floors at 10")
	var exact := true
	for entry: Dictionary in Catalog.MINERALS:
		var want := clampi(roundi(float(int(entry[&"ingot_value"])) / 10.0), 10, 60)
		if Ref.resource_seconds(entry[&"id"]) != want:
			exact = false
	_check(exact, "R1 clamp(round(ingot_value/10),10,60) exact for every catalog row")


## ------------------------------------------------- queue all-or-nothing + duration


func _probe_queue_all_or_nothing() -> void:
	var before := int(_profile.call(&"credits"))
	var r := Ref.queue(_profile, &"iron", 1)
	_check(not bool(r[&"ok"]) and int(_profile.call(&"credits")) == before and Ref.jobs(_profile).is_empty(),
		"queue refuses an empty input whole")
	_load(&"iron", 3)
	_profile.set(&"_credits", 10)
	r = Ref.queue(_profile, &"iron", 1)
	_check(not bool(r[&"ok"]) and int(_profile.call(&"credits")) == 10 and Ref.input_units(_profile, &"iron") == 3
		and Ref.jobs(_profile).is_empty(), "queue refuses a poor account whole")
	_check(Ref.queue(_profile, &"iron", 0)[&"reason"] == Ref.REASON_INVALID_COUNT, "queue refuses 0 conversions")
	_check(Ref.queue(_profile, &"unobtainium", 1)[&"reason"] == Ref.REASON_UNKNOWN_MINERAL, "queue refuses unknown")
	_profile.set(&"_credits", 100000)
	var now := int(Time.get_unix_time_from_system())
	var ok := Ref.queue(_profile, &"iron", 1)
	_check(bool(ok[&"ok"]) and int(_profile.call(&"credits")) == 100000 - 15
		and Ref.input_units(_profile, &"iron") == 0 and Ref.jobs(_profile).size() == 1, "queue success spends+takes+mints")
	var job := Ref.jobs(_profile)[0]
	_check(absi(int(job[&"ready_at"]) - (now + 10)) <= 2, "duration 1x10 ready_at=now+R1")


func _probe_duration() -> void:
	_reset()
	_load(&"gold", 6)
	var now := int(Time.get_unix_time_from_system())
	Ref.queue(_profile, &"gold", 2)
	var job := Ref.jobs(_profile)[0]
	_check(absi(int(job[&"ready_at"]) - (now + 52)) <= 2, "duration 2 Gold conversions = 2x26 s")


## ---------------------------------------------------- QUEUE ALL + FIFO pending


func _probe_queue_all_fifo() -> void:
	_reset()
	_load(&"iron", 3)
	_load(&"copper", 6)
	_load(&"gold", 3)
	var credits_before := int(_profile.call(&"credits"))
	var batch := Ref.queue_all(_profile)
	var ids: Array = batch[&"job_ids"]
	_check(bool(batch[&"ok"]) and ids.size() == 3 and int(batch[&"fee"]) == 65,
		"QUEUE ALL one job per mineral, combined 65 CR (Iron 15 + 2 Copper at 15 + Gold 20)")
	_check(int(_profile.call(&"credits")) == credits_before - 65, "QUEUE ALL charges the combined fee once")
	var jobs := Ref.jobs(_profile)
	_check(Ref.running_count(_profile) == 2 and Ref.pending_count(_profile) == 1,
		"2 slots run, the third waits FIFO")
	_check(StringName(jobs[2][&"mineral_id"]) == &"gold" and StringName(jobs[2][&"state"]) == Ref.JOB_PENDING,
		"catalogue order Iron, Copper, pending Gold")


## --------------------------------------------------------------- the slot ladder


func _probe_slot_ladder() -> void:
	_reset()
	_check(Ref.slots(_profile) == 2, "2 slots base")
	var paid := 0
	var ladder := true
	for want in [3, 4, 5]:
		var up := Ref.upgrade_slots(_profile)
		paid += int(up[&"cost"])
		if not bool(up[&"ok"]) or int(up[&"slots"]) != want or int(up[&"cost"]) != 3000:
			ladder = false
	_check(ladder and paid == 9000, "3,000 CR flat per +1 up to 5")
	var before := int(_profile.call(&"credits"))
	var refused := Ref.upgrade_slots(_profile)
	_check(not bool(refused[&"ok"]) and refused[&"reason"] == Ref.REASON_MAX_SLOTS
		and int(_profile.call(&"credits")) == before, "hardcap 5 refuses free")
	_reset()
	_load(&"iron", 12)
	for i in 3:
		Ref.queue(_profile, &"iron", 1)
	_check(Ref.running_count(_profile) == 2 and Ref.pending_count(_profile) == 1, "parallel 2 + FIFO pending")
	Ref.upgrade_slots(_profile)
	Ref.settle(_profile)
	_check(Ref.running_count(_profile) == 3 and Ref.pending_count(_profile) == 0, "upgrade promotes pending")


## ------------------------------------------------------------------- the caps


func _probe_caps() -> void:
	_reset()
	_profile.call(&"add_cargo", &"mineral_iron", 61)
	Ref.load_ore(_profile, &"iron", 60)
	var over := Ref.load_ore(_profile, &"iron", 1)
	_check(not bool(over[&"ok"]) and over[&"reason"] == Ref.REASON_INPUT_FULL
		and Ref.input_total(_profile) == 60 and int(_profile.call(&"cargo_qty", &"mineral_iron")) == 1,
		"over-cap LOAD refused whole, ore stays in the hold")
	_profile.call(&"set_refinery_input", {})
	_profile.call(&"set_refinery_output", {&"ingot_iron": 60})
	_load(&"gold", 3)
	Ref.queue(_profile, &"gold", 1)
	_force_ready()
	_check(Ref.settle(_profile) == 0 and Ref.output_total(_profile) == 60, "full output leaves the job done-unsettled")
	_force_ready()
	var cap := int(Ref._hold_capacity(_profile))
	var held := 0
	for qty: Variant in (_profile.call(&"cargo_items") as Dictionary).values():
		held += int(qty)
	var collected := Ref.collect_all(_profile)
	_check(int(collected[&"collected"]) == cap - held and Ref.output_total(_profile) == 60 - (cap - held),
		"COLLECT fills the hold to its cap (%d free), overflow stays" % (cap - held))
	_check(Ref.settle(_profile) == 1, "freed output settles the waiting job")


## -------------------------------------------------------------------- CANCEL


func _probe_cancel() -> void:
	_reset()
	_load(&"gold", 6)
	var before := int(_profile.call(&"credits"))
	var queued := Ref.queue(_profile, &"gold", 2)
	var cancelled := Ref.cancel(_profile, int(queued[&"job_id"]))
	_check(bool(cancelled[&"ok"]) and int(cancelled[&"fee"]) == 40
		and int(_profile.call(&"credits")) == before and Ref.input_units(_profile, &"gold") == 6,
		"CANCEL refunds the fee and returns the ore to the input")
	_profile.call(&"set_refinery_input", {})
	_load(&"iron", 60)
	var second := Ref.queue(_profile, &"iron", 1)
	_load(&"iron", 3)
	var hold_before := int(_profile.call(&"cargo_qty", &"mineral_iron"))
	Ref.cancel(_profile, int(second[&"job_id"]))
	_check(Ref.input_units(_profile, &"iron") == 60
		and int(_profile.call(&"cargo_qty", &"mineral_iron")) == hold_before + 3,
		"CANCEL into a full input sends the overflow to the hold")
	_check(Ref.cancel(_profile, 9999)[&"reason"] == Ref.REASON_UNKNOWN_JOB, "unknown job refuses CANCEL")
	_reset()
	_load(&"iron", 3)
	var third := Ref.queue(_profile, &"iron", 1)
	var done_id := int(third[&"job_id"])
	_force_ready()
	Ref.settle(_profile)
	_check(Ref.cancel(_profile, done_id)[&"reason"] == Ref.REASON_JOB_DONE, "a done job refuses CANCEL")


## ------------------------------------------------------------------- settle


func _probe_settle() -> void:
	_reset()
	_load(&"iron", 3)
	Ref.queue(_profile, &"iron", 1)
	_check(Ref.settle(_profile) == 0 and Ref.output_total(_profile) == 0, "a running job settles nothing")
	_force_ready()
	_check(Ref.settle(_profile) == 1 and int(_profile.get(&"_refinery_output").get(&"ingot_iron", 0)) == 1,
		"fake-ready job settles one ingot into the output")
	Ref.collect_all(_profile)
	_check(Ref.jobs(_profile).is_empty(), "a collected job leaves the list")


## -------------------------------------------------------------- persistence


func _probe_save_round_trip() -> void:
	_reset()
	_profile.call(&"set_refinery_slots", 4)
	_profile.call(&"set_refinery_input", {&"mineral_iron": 12})
	_profile.call(&"set_refinery_output", {&"ingot_gold": 3})
	_profile.call(&"set_refinery_jobs", [
		{&"id": 7, &"mineral_id": &"gold", &"conversions": 2, &"ready_at": 12345, &"state": &"running", &"fee": 30, &"settled": false},
	])
	_profile.call(&"set_refinery_next_job_id", 8)
	_profile.call(&"flush")
	_profile.call(&"reload")
	var ok: bool = int(_profile.call(&"refinery_slots")) == 4 \
		and int(_profile.call(&"refinery_input").get(&"mineral_iron", 0)) == 12 \
		and int(_profile.call(&"refinery_output").get(&"ingot_gold", 0)) == 3 \
		and _profile.call(&"refinery_jobs").size() == 1 \
		and int(_profile.call(&"refinery_jobs")[0][&"conversions"]) == 2 \
		and int(_profile.call(&"refinery_next_job_id")) == 8
	_check(ok, "the five new keys round-trip the save file")
	var fixture := ConfigFile.new()
	fixture.set_value("profile", "save_version", 7)
	fixture.set_value("profile", "credits", 5000)
	fixture.save(SCRATCH_PROFILE)
	_profile.call(&"reload")
	ok = int(_profile.call(&"refinery_slots")) == 2 \
		and (_profile.call(&"refinery_input") as Dictionary).is_empty() \
		and (_profile.call(&"refinery_output") as Dictionary).is_empty() \
		and (_profile.call(&"refinery_jobs") as Array).is_empty() \
		and int(_profile.call(&"refinery_next_job_id")) == 1
	_check(ok, "a pre-S34 save defaults the five keys")


## ------------------------------------------------------------------- the panel


func _probe_panel() -> void:
	var panel := RefineryScene.instantiate()
	get_tree().root.add_child(panel)
	var words := String(panel.get_node("%QueueButton").text) == "QUEUE 1" \
		and String(panel.get_node("%QueueAllButton").text) == "QUEUE ALL" \
		and String(panel.get_node("%CancelButton").text) == "CANCEL" \
		and String(panel.get_node("%LoadButton").text) == "LOAD" \
		and String(panel.get_node("%CollectButton").text) == "COLLECT ALL" \
		and String(panel.get_node("%SlotsLabel").text) == "SLOTS 2/5" \
		and String(panel.get_node("%UpgradeButton").text) == "UPGRADE (3,000 CR)"
	_check(words, "panel words: QUEUE N / QUEUE ALL / CANCEL / LOAD / COLLECT ALL / SLOTS n/5 + UPGRADE")
	_check(String(panel._mmss(95)) == "01:35" and String(panel._mmss(65)) == "01:05", "mm:ss renders")
	_reset()
	_load(&"gold", 6)
	Ref.queue(_profile, &"gold", 2)
	panel._build_jobs()
	var job := Ref.jobs(_profile)[0]
	var want := String(panel._mmss(maxi(int(job[&"ready_at"]) - int(Time.get_unix_time_from_system()), 0)))
	var got := String(panel._job_payloads[0][&"time"].text)
	## S28: the countdown re-derives off the live R1 duration (two Gold conversions,
	## 2 x 26 s on 02's 2026-10-08 ingot value) instead of the retired 40 s pin.
	var live := Ref.resource_seconds(&"gold") * 2
	_check(got == want and absi(int(job[&"ready_at"]) - int(Time.get_unix_time_from_system()) - live) <= 1,
		"running row countdown mm:ss (%s, live %d s)" % [got, live])
	_force_ready()
	var out_before := Ref.output_total(_profile)
	panel.refresh_profile(&"refinery")
	_check(Ref.output_total(_profile) > out_before, "settle runs on a &\"refinery\" pane refresh")
	_reset()
	_load(&"gold", 6)
	Ref.queue(_profile, &"gold", 2)
	_force_ready()
	panel._tick()
	_check(Ref.output_total(_profile) == 2, "settle runs on the 1 Hz tick")
	_reset()
	_load(&"gold", 6)
	Ref.queue(_profile, &"gold", 2)
	_force_ready()
	panel._on_visibility_changed()
	_check(Ref.output_total(_profile) == 2, "settle runs on becoming visible")
	_reset()
	_load(&"iron", 3)
	Ref.queue(_profile, &"iron", 1)
	_force_ready()
	Ref.settle(_profile)
	_profile.call(&"add_cargo", &"ingot_iron", 40)
	var rows_before := Ref.jobs(_profile).size()
	var collected := Ref.collect_all(_profile)
	_check(int(collected[&"collected"]) == 0 and Ref.jobs(_profile).size() == 1 and rows_before == 1
		and Ref.output_total(_profile) == 1,
		"F1 evidence: a zero-yield COLLECT keeps the done row while the ingot stays in output")
	_profile.call(&"remove_cargo", &"ingot_iron", 40)
	var drained := Ref.collect_all(_profile)
	_check(int(drained[&"collected"]) == 1 and Ref.jobs(_profile).size() == 0
		and Ref.output_total(_profile) == 0,
		"F1 evidence: once the output drains the done row leaves the list")
	_reset()
	_profile.call(&"add_cargo", &"mineral_iron", 6)
	panel._build_rows()
	var hold_row := {}
	for payload: Dictionary in panel._payloads:
		if payload[&"id"] == &"iron" and not bool(payload[&"loaded"]):
			hold_row = payload
	_check(not hold_row.is_empty() and int(hold_row[&"conversions"]) == 2
		and int(hold_row[&"fee"]) == 30,
		"F2 evidence: a hold row inspects as its own hold numbers (2 conversions, 30 fee)")
	panel.queue_free()
