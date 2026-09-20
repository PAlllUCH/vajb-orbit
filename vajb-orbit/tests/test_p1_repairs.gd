@tool
extends McpTestSuite
## Suite p1_repairs: the station REPAIRS module and the `vitals` profile
## extension (docs/gameplay/01_economy_core.md sections 6 and 7).
##
## Pure logic: no scene instancing, no editor API, no MCP. Profiles are throwaway
## instances whose save_path is repointed at a scratch file before the first
## mutation; `user://profile.cfg` is never touched, and the economy log is
## redirected to a scratch file truncated before every test.

const Repairs := preload("res://game/repairs.gd")
const Clock := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")
const Profile := preload("res://autoload/player_profile.gd")

const PROFILE_PATH := "user://test_p1_repairs.cfg"
const LOG_PATH := "user://test_p1_log.txt"
const NOW := 1000000

var _profiles: Array[Node] = []


func suite_name() -> String:
	return "p1_repairs"


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


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(LOG_PATH)
	Log.log_path = Log.DEFAULT_PATH
	Clock.clear_override()


func test_vanguard_home_fee_and_repair() -> void:
	var profile = _fresh()
	profile.set_vitals(&"ship_vanguard", 200, 300)
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 500, "(800/2) + (300/3)")
	assert_true(Repairs.is_repairable(profile, &"ship_vanguard"))

	var result: Dictionary = Repairs.repair(profile, &"ship_vanguard")
	assert_true(bool(result["ok"]))
	assert_eq(int(result["fee"]), 500)
	assert_eq(int(result["hull_max"]), 1000)
	assert_eq(int(result["shield_max"]), 600)
	assert_eq(profile.credits(), 9500, "exactly the fee is spent")
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(vitals["hull"]), 1000, "hull restored")
	assert_eq(int(vitals["shield"]), 600, "shield restored")
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 0, "nothing left to pay")
	assert_false(Repairs.is_repairable(profile, &"ship_vanguard"))

	var lines := _log_lines()
	assert_eq(lines.size(), 1, "one REPAIR line")
	var fields := lines[0].split(", ")
	assert_eq(fields.size(), 6)
	assert_eq(fields[1], "REPAIR")
	assert_eq(fields[2], "ship_vanguard")
	assert_eq(fields[3], "0", "a repair takes no goods")
	assert_eq(fields[4], "-500")
	assert_eq(fields[5], "9500")


func test_full_pools_report_no_damage() -> void:
	var profile = _fresh()
	profile.set_vitals(&"ship_vanguard", 1000, 600)
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 0)
	assert_false(Repairs.is_repairable(profile, &"ship_vanguard"))
	var result: Dictionary = Repairs.repair(profile, &"ship_vanguard")
	assert_false(bool(result["ok"]))
	assert_eq(result["reason"], Repairs.REASON_NO_DAMAGE)
	assert_eq(profile.credits(), 10000, "nothing is charged")
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(vitals["hull"]), 1000)
	assert_eq(int(vitals["shield"]), 600)
	assert_eq(_log_lines().size(), 0, "a refused repair logs nothing")


func test_shield_exemption_is_free() -> void:
	var profile = _fresh()
	profile.set_vitals(&"ship_vanguard", 1000, 570)
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 0, "shield alone at 95% is exempt")
	assert_true(
		Repairs.is_repairable(profile, &"ship_vanguard"), "the free top-up is still a repair"
	)
	var result: Dictionary = Repairs.repair(profile, &"ship_vanguard")
	assert_true(bool(result["ok"]))
	assert_eq(int(result["fee"]), 0, "no fee")
	assert_eq(profile.credits(), 10000, "a free repair costs nothing")
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(vitals["hull"]), 1000, "hull already full")
	assert_eq(int(vitals["shield"]), 600, "shield topped up to the maximum")
	var lines := _log_lines()
	assert_eq(lines.size(), 1, "the free repair is still logged")
	assert_eq(lines[0].split(", ")[4], "+0")


func test_missing_damage_report_refuses() -> void:
	var profile = _fresh()
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 0)
	assert_false(Repairs.is_repairable(profile, &"ship_vanguard"))
	var result: Dictionary = Repairs.repair(profile, &"ship_vanguard")
	assert_false(bool(result["ok"]))
	assert_eq(result["reason"], Repairs.REASON_NO_DAMAGE_REPORT)
	assert_eq(profile.credits(), 10000)
	assert_true(profile.vitals_of(&"ship_vanguard").is_empty())
	assert_eq(_log_lines().size(), 0)

	# A damage report for a hull the catalogue does not know is refused the same way.
	profile.set_vitals(&"ship_bogus", 100, 100)
	assert_eq(Repairs.fee(profile, &"ship_bogus"), 0)
	assert_false(Repairs.is_repairable(profile, &"ship_bogus"))
	var unknown: Dictionary = Repairs.repair(profile, &"ship_bogus")
	assert_false(bool(unknown["ok"]))
	assert_eq(unknown["reason"], Repairs.REASON_NO_DAMAGE_REPORT)
	var vitals: Dictionary = profile.vitals_of(&"ship_bogus")
	assert_eq(int(vitals["hull"]), 100, "the report is left alone")


func test_insufficient_credits_refuses() -> void:
	var profile = _fresh()
	assert_true(profile.spend(9800))
	assert_eq(profile.credits(), 200)
	profile.set_vitals(&"ship_vanguard", 200, 300)
	assert_eq(Repairs.fee(profile, &"ship_vanguard"), 500, "the fee exceeds the balance")

	var result: Dictionary = Repairs.repair(profile, &"ship_vanguard")
	assert_false(bool(result["ok"]))
	assert_eq(result["reason"], Repairs.REASON_INSUFFICIENT)
	assert_eq(profile.credits(), 200, "credits untouched")
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(vitals["hull"]), 200, "hull untouched")
	assert_eq(int(vitals["shield"]), 300, "shield untouched")
	assert_eq(_log_lines().size(), 0, "a refused repair logs nothing")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


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
