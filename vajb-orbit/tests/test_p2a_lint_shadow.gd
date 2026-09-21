@tool
extends McpTestSuite
## Suite p2a_lint_shadow: the regression guard for R1-M1 - the one `--debug` warning
## ledger row wave P2-A owned.
##
## A constant whose name is also a project global class makes the GDScript compiler
## warn at reload, and CONTRACTS section 9's instrument treats that ledger as the
## lint gate, so a suite this wave added may contribute zero rows:
##
##   WARNING: The constant "ShipFit" has the same name as a global class defined in "ship_fit.gd".
##        at: GDScript::reload (res://tests/test_p2a_ship_roster.gd:10)
##
## The rule is name-based (the right-hand side plays no part), so this suite reads the
## name off every `const` under `res://tests/` and compares it with
## `ProjectSettings.get_global_class_list()` - the same table the compiler warns from.
## Measured before the fix: three such sites in `tests/`, three ledger rows, one per
## site, in the same run.
##
## Two of those sites predate this wave (`test_engine2_npc.gd:21`, `test_p1_repairs.gd:11`)
## and are outside a fixer's mandate, so they sit in PRE_EXISTING and ride forward - the
## first test fails on any site that is not one of them, and the second fails if a P2-A
## suite is ever excused by that list. Delete an entry here when its site is cured.
##
## Pure text scan over the suite sources plus the editor's global class table:
## no scene instancing, no editor API, no MCP.

const TESTS_DIR := "res://tests"

## The suites wave P2-A added or rewrote: these must be clean with no exception.
const WAVE_FILES: Array[String] = [
	"test_ship_grids.gd",
	"test_p2a_profile_fits.gd",
	"test_p2a_launch_fit.gd",
	"test_p2a_ship_roster.gd",
	"test_ui_slot_layout.gd",
]

## The shadowing sites the `--debug` ledger already carried before this wave started
## (R1's report section 10: 43 rows, of which 42 are pre-existing). Not this pass's to
## fix, and never an excuse for a P2-A file.
const PRE_EXISTING: Array[String] = [
	"test_engine2_npc.gd",
	"test_p1_repairs.gd",
]


func suite_name() -> String:
	return "p2a_lint_shadow"


## The ledger may not grow: any constant named after a global class, in any suite this
## wave did not own, is a failure with the file, the line, the name and the cure.
func test_no_const_shadows_a_global_class_outside_the_pre_existing_sites() -> void:
	var globals := _global_class_names()
	assert_gt(globals.size(), 0, "the project's global class table is readable headless")
	var offenders := PackedStringArray()
	for site: Dictionary in _shadowing_sites(globals):
		if PRE_EXISTING.has(site["file"]):
			continue
		offenders.append(_describe(site))
	assert_true(
		offenders.is_empty(),
		(
			"a constant may not share a global class's name - rename the constant:\n  "
			+ "\n  ".join(offenders)
		)
	)


## The wave's own files, held to the house bar of zero rows and never to the exception
## list above.
func test_wave_owned_suites_declare_no_shadowing_constant() -> void:
	var globals := _global_class_names()
	var by_file := _shadowing_sites_by_file(globals)
	for file: String in WAVE_FILES:
		assert_false(
			PRE_EXISTING.has(file), "%s is a P2-A suite and may not be excused" % file
		)
		assert_true(FileAccess.file_exists("%s/%s" % [TESTS_DIR, file]), "%s is present" % file)
		var sites: PackedStringArray = by_file.get(file, PackedStringArray())
		assert_eq(
			sites.size(),
			0,
			(
				"%s declares no constant named after a global class%s"
				% [file, "" if sites.is_empty() else ": " + ", ".join(sites)]
			)
		)


## The project's registered global classes, as a name -> script path set, off the table
## the GDScript compiler warns from.
func _global_class_names() -> Dictionary:
	var names := {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		var class_name_value := str(entry.get("class", ""))
		if not class_name_value.is_empty():
			names[class_name_value] = str(entry.get("path", ""))
	return names


## Every `const <Name>` in `res://tests/*.gd` whose name is a global class, in file order,
## as {file, line, name, target, text}. An empty `globals` reads nothing, which is why
## the callers guard its size first.
func _shadowing_sites(globals: Dictionary) -> Array:
	var sites: Array = []
	if globals.is_empty():
		return sites
	var const_pattern := RegEx.new()
	const_pattern.compile("^\\s*const\\s+([A-Za-z_]\\w*)\\b")
	for file_name: String in _test_file_names():
		var lines := FileAccess.get_file_as_string(TESTS_DIR + "/" + file_name).split("\n")
		for index: int in lines.size():
			var line: String = lines[index]
			var match_result := const_pattern.search(line)
			if match_result == null:
				continue
			var declared := match_result.get_string(1)
			if not globals.has(declared):
				continue
			sites.append(
				{
					"file": file_name,
					"line": index + 1,
					"name": declared,
					"target": globals[declared],
					"text": line.strip_edges(),
				}
			)
	return sites


## The same sites grouped by file name, each entry "line N: const Name".
func _shadowing_sites_by_file(globals: Dictionary) -> Dictionary:
	var grouped := {}
	for site: Dictionary in _shadowing_sites(globals):
		var file_name: String = site["file"]
		if not grouped.has(file_name):
			grouped[file_name] = PackedStringArray()
		var bucket: PackedStringArray = grouped[file_name]
		bucket.append("line %d: const %s" % [int(site["line"]), site["name"]])
		grouped[file_name] = bucket
	return grouped


## `const Name at <file>:<line> has the same name as the global class in <path>` - the
## compiler's own wording, with the cure attached.
func _describe(site: Dictionary) -> String:
	return (
		"const %s at %s:%d has the same name as a global class defined in %s - rename the constant"
		% [site["name"], site["file"], int(site["line"]), site["target"]]
	)


## Every `test_*.gd` in the suite directory, sorted so the scan and its messages are stable.
func _test_file_names() -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names
