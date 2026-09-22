extends Node
## W2 probe (P2-B proper): the per-file GDScript-warning ledger for every script this worker
## changed or added - the shell it edited, the pane it created and the two test files.
##
## Same instrument as `tests/probe_w1_lint.gd` and `tests/probe_w5_lint.gd` (CONTRACTS
## section 9's ledger): a marker is printed, the file is loaded with `CACHE_MODE_IGNORE` so the
## resource cache cannot serve a stale parse, and the closing marker follows, so every
## `WARNING:` line between two markers belongs to the file the opening marker named.
## `--headless --debug` attaches the stdout debugger, which is what makes the warnings visible
## at all.
##
## `game/weapons.gd` is the positive control (a known warning source, so a run that shows
## nothing for it is blind) and `autoload/world_clock.gd` the negative one.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_w2_lint.tscn --quit-after 600

const FILES_SHIPPED: Array[String] = [
	"res://ui/station/fitting_panel.gd",
	"res://ui/screens/station.gd",
]

const FILES_TESTS: Array[String] = [
	"res://tests/test_p2b_fitting_panel.gd",
	"res://tests/probe_w2_fitting.gd",
]

const CONTROLS_POSITIVE: Array[String] = [
	"res://game/weapons.gd",
]

const CONTROLS_NEGATIVE: Array[String] = [
	"res://autoload/world_clock.gd",
]


func _ready() -> void:
	await get_tree().process_frame
	print("[W2-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("shipped", FILES_SHIPPED)
	_lint_group("tests", FILES_TESTS)
	_lint_group("POSITIVE-CONTROL", CONTROLS_POSITIVE)
	_lint_group("NEGATIVE-CONTROL", CONTROLS_NEGATIVE)
	print("[W2-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		print("[W2-LINT] BEGIN %s %s" % [group, path])
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("[W2-LINT] END   %s %s loaded=%s" % [group, path, script != null])
