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

## Gate hermeticity, CONTRACTS section 14 (L90/L93): the gate must neither read nor
## write the owner's live account, so both writable stores are sandboxed before the
## first suite loads.
const PROFILE_SERVICE := &"PlayerProfile"
const GATE_SCRATCH_DIR := "user://_gate_scratch"
const GATE_SCRATCH_PROFILE := "user://_gate_scratch/profile.cfg"
const GATE_SCRATCH_LOG := "user://_gate_scratch/economy_log.txt"

const EconomyLogScript := preload("res://game/economy_log.gd")

var _passed := 0
var _failed := 0
var _filters := PackedStringArray()


func _ready() -> void:
	_seed_scratch_store()
	_filters = _suite_filters()
	if not _filters.is_empty():
		print("[RUN] suites=%s" % ",".join(_filters))
	for path: String in _discover():
		_run_file(path)
	print("[SUMMARY] passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## Sandboxes the gate's two writable stores. Three steps in this order, and each one
## is load-breaking without the one before it:
##   1. the directory - `ConfigFile.save` into a missing directory fails with `err=7`
##      (`ERR_FILE_NOT_FOUND`), and `PlayerProfile._write_profile` only warns and *drops*
##      the write, so a store repointed into no directory silently loses every seeded value;
##   2. `save_path` - the file the store reads and writes;
##   3. the **in-memory** reset - the autoload's own `_ready` loaded the live file before
##      this runner exists, so repointing alone would leave the owner's credits, packs and
##      fits in memory (and `_fits` is what a launch reads for its weapon slots); the reset
##      plus a flush then *seeds the deterministic default* inside the sandbox.
func _seed_scratch_store() -> void:
	var err := DirAccess.make_dir_recursive_absolute(GATE_SCRATCH_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("headless_runner: cannot create %s (error %d)" % [GATE_SCRATCH_DIR, err])
	var profile := _profile()
	if profile == null:
		push_error("headless_runner: no %s autoload to sandbox" % PROFILE_SERVICE)
	else:
		profile.set(&"save_path", GATE_SCRATCH_PROFILE)
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
	_sandbox_log()


func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


## `EconomyLog.log_path` is a static and several suites hand it back to the live default in
## their own `suite_teardown` (`test_engine2_dock.gd`), so the sandbox is re-applied around
## every suite and every method rather than once at boot. A suite's own scratch path is left
## alone: only the live default is ever replaced, so a suite that redirects the log to read
## its own lines back keeps reading them.
func _sandbox_log() -> void:
	if EconomyLogScript.log_path == EconomyLogScript.DEFAULT_PATH:
		EconomyLogScript.log_path = GATE_SCRATCH_LOG


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
	_sandbox_log()
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
		_sandbox_log()
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
