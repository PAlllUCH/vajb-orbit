@tool
extends McpTestSuite
## Suite p1_clock_log: the one 20-minute clock and the append-only economy log
## (docs/gameplay/17_coder_handoff.md sections 4 and 5,
## docs/gameplay/01_economy_core.md section 7).
##
## Pure logic: no scene instancing, no editor API, no MCP. The clock is used
## through its static API (`WorldClock` is an autoload node whose only job is to
## exist), and the log is redirected to a scratch file truncated before every
## test; `user://economy_log.txt` is never touched.

const Clock := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")

const LOG_PATH := "user://test_p1_log.txt"
const BAD_PATH := "user://p1l_missing_dir_do_not_create/economy_log.txt"


func suite_name() -> String:
	return "p1_clock_log"


func setup() -> void:
	Clock.clear_override()
	_delete_file(BAD_PATH)
	_reset_log()


func teardown() -> void:
	Clock.clear_override()


func suite_teardown() -> void:
	_delete_file(LOG_PATH)
	_delete_file(BAD_PATH)
	Log.log_path = Log.DEFAULT_PATH
	Clock.clear_override()


func test_band_seconds_and_bands_between_edges() -> void:
	assert_eq(Clock.BAND_SECONDS, 1200, "one band is 20 minutes")
	assert_eq(Clock.bands_between(1000, 2199), 0, "one second short of a band")
	assert_eq(Clock.bands_between(1000, 2200), 1, "exactly one band")
	assert_eq(Clock.bands_between(1000, 3400), 2, "exactly two bands")
	assert_eq(Clock.bands_between(0, 1200), 0, "a zero stamp never rolls")
	assert_eq(Clock.bands_between(1000, 0), 0, "a zero stamp never rolls")
	assert_eq(Clock.bands_between(-5, 1200), 0, "a negative stamp never rolls")
	assert_eq(Clock.bands_between(1000, 1000), 0, "no time passed")
	assert_eq(Clock.bands_between(2000, 1000), 0, "a reversed range never rolls")


func test_override_pins_and_restores_now() -> void:
	Clock.clear_override()
	assert_false(Clock.has_override(), "no override by default")
	assert_true(Clock.now() > 1000000000, "system time is a real unix stamp")

	Clock.set_override(5000)
	assert_true(Clock.has_override())
	assert_eq(Clock.now(), 5000)
	assert_eq(Clock.bands_between(Clock.now(), 6200), 1, "one band after the pinned stamp")

	Clock.clear_override()
	assert_false(Clock.has_override(), "the override is cleared")
	assert_true(Clock.now() > 1000000000, "system time is back")


func test_log_line_shape_and_append() -> void:
	Log.append("SELL", &"ingot_gold", 10, 1117, 101117)
	var lines := _log_lines()
	assert_eq(lines.size(), 1, "one line per event")
	var fields := lines[0].split(", ")
	assert_eq(fields.size(), 6, "six fields: %s" % lines[0])
	assert_eq(fields[0].length(), 19, "ISO timestamp: %s" % fields[0])
	assert_ne(fields[0].find("T"), -1, "ISO timestamp carries a T")
	assert_true(fields[0].substr(0, 4).is_valid_int(), "the stamp starts with a year")
	assert_eq(fields[1], "SELL")
	assert_eq(fields[2], "ingot_gold")
	assert_eq(fields[3], "10")
	assert_eq(fields[4], "+1117", "a credit gain is signed")
	assert_eq(fields[5], "101117", "the balance closes the line")

	Log.append("REPAIR", &"ship_vanguard", 0, -500, 9500)
	lines = _log_lines()
	assert_eq(lines.size(), 2, "a second append does not truncate the first")
	assert_contains(lines[0], "ingot_gold", "the first line survives")
	assert_eq(lines[0].split(", ")[4], "+1117")
	assert_eq(lines[1].split(", ")[4], "-500", "a credit loss is signed")


func test_unwritable_log_path_is_survivable() -> void:
	assert_false(FileAccess.file_exists(BAD_PATH), "the bad directory does not exist")
	Log.log_path = BAD_PATH
	# Must warn and return, never crash the transaction.
	Log.append("SELL", &"mineral_iron", 1, 1, 1)
	assert_false(FileAccess.file_exists(BAD_PATH), "a failed open creates nothing")
	Log.log_path = LOG_PATH
	Log.append("SELL", &"mineral_iron", 1, 1, 1)
	assert_eq(_log_lines().size(), 1, "logging still works after a failed open")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


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
