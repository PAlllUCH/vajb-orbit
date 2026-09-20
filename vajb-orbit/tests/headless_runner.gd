extends Node
## Headless twin of the editor's test_run tool: discovers every
## res://tests/test_*.gd, runs all McpTestSuite test_* methods and prints one
## line per test plus a final [SUMMARY].
##
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
##     --path "G:/.../vajb-orbit" res://tests/headless_runner.tscn
##
## Exit code is 0 when nothing failed, 1 otherwise, so a shell gate can read the
## process result directly. No editor APIs: this file must run headless.
## Suites stay compatible with both this runner and the plugin's own runner.

const TESTS_DIR := "res://tests"
const TEST_PREFIX := "test_"
const SCRIPT_SUFFIX := ".gd"
const SUITE_FLAG := "--suite="

var _passed := 0
var _failed := 0
var _filters := PackedStringArray()


func _ready() -> void:
	_filters = _suite_filters()
	if not _filters.is_empty():
		print("[RUN] suites=%s" % ",".join(_filters))
	for path: String in _discover():
		_run_file(path)
	print("[SUMMARY] passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## Optional scoping for a single worker's gate: `-- --suite=test_p1_pricing`
## (repeatable). No flag means the whole res://tests directory, which is what
## the wave-level gate uses.
func _suite_filters() -> PackedStringArray:
	var filters := PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SUITE_FLAG):
			var value := arg.substr(SUITE_FLAG.length())
			if not value.is_empty():
				filters.append(value)
	return filters


func _selected(path: String) -> bool:
	if _filters.is_empty():
		return true
	var suite_name := path.get_file().trim_suffix(SCRIPT_SUFFIX)
	return _filters.has(suite_name)


## Every test_*.gd under res://tests, sorted so the run order is deterministic.
func _discover() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("headless_runner: cannot open %s" % TESTS_DIR)
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with(TEST_PREFIX) and file_name.ends_with(SCRIPT_SUFFIX):
			files.append(TESTS_DIR + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _run_file(path: String) -> void:
	if not _selected(path):
		return
	var suite_name := path.get_file()
	var script: Variant = load(path)
	if not script is GDScript:
		_failed += 1
		print("[FAIL] %s: script failed to load (see the parse error above)" % suite_name)
		return
	var gd := script as GDScript
	if not gd.can_instantiate():
		_failed += 1
		print(
			"[FAIL] %s: script cannot be instantiated (parse error, abstract, or missing @tool)"
			% suite_name
		)
		return
	var instance: Variant = gd.new()
	if instance == null:
		_failed += 1
		print("[FAIL] %s: instantiation returned null" % suite_name)
		return
	if not instance is McpTestSuite:
		print("[SKIP] %s: not a McpTestSuite" % suite_name)
		return
	var suite: McpTestSuite = instance
	suite.suite_setup({})
	if suite.get("_suite_failed"):
		_failed += 1
		print("[FAIL] %s: %s" % [suite_name, str(suite.get("_suite_failed_message"))])
		suite.suite_teardown()
		return
	if suite.get("_suite_skipped"):
		print("[SKIP] %s: %s" % [suite_name, str(suite.get("_suite_skipped_reason"))])
		suite.suite_teardown()
		return
	for method: String in _test_methods(suite):
		suite.call("_reset")
		suite.setup()
		suite.call(method)
		suite.teardown()
		if bool(suite.get("_failed")):
			_failed += 1
			print("[FAIL] %s.%s: %s" % [suite_name, method, str(suite.get("_message"))])
		else:
			_passed += 1
			print("[PASS] %s.%s" % [suite_name, method])
	suite.suite_teardown()


## test_* methods declared on the suite itself, sorted for a stable report.
func _test_methods(suite: McpTestSuite) -> Array[String]:
	var names: Array[String] = []
	for entry: Dictionary in suite.get_method_list():
		var method_name: String = str(entry.get("name", ""))
		if method_name.begins_with(TEST_PREFIX) and not names.has(method_name):
			names.append(method_name)
	names.sort()
	return names
