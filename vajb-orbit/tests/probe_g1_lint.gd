extends Node
## G1 warning ledger for the three files this worker owns (CONTRACTS section 9, fifth
## harness limit): `--headless --debug` attaches the local stdout debugger and every
## GDScript warning is printed as a `WARNING:` line attributed to the file being parsed.
## One file is loaded at a time between printed markers with CACHE_MODE_IGNORE, so the
## resource cache cannot serve a stale parse and every warning line between two markers
## belongs to the file named by the opening marker.
##
## `game/weapons.gd` and `ui/hud/minimap.gd` are the positive controls (known to warn on
## this build, per the W5 ledger); `autoload/world_clock.gd` is the negative control. A run
## reporting zero warnings for the positive controls is blind and its ledger is worthless.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_g1_lint.tscn --quit-after 600
## Signal: the [G1-LINT] lines; the last line is [G1-LINT] done.

const FILES_G1: Array[String] = [
	"res://game/player_ship.gd",
	"res://game/ship_fit.gd",
	"res://autoload/settings_manager.gd",
]

const CONTROLS_POSITIVE: Array[String] = [
	"res://game/weapons.gd",
	"res://ui/hud/minimap.gd",
]

const CONTROLS_NEGATIVE: Array[String] = [
	"res://autoload/world_clock.gd",
]


func _ready() -> void:
	await get_tree().process_frame
	print("[G1-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("G1", FILES_G1)
	_lint_group("POSITIVE-CONTROL", CONTROLS_POSITIVE)
	_lint_group("NEGATIVE-CONTROL", CONTROLS_NEGATIVE)
	print("[G1-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		print("[G1-LINT] BEGIN %s %s" % [group, path])
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("[G1-LINT] END   %s %s loaded=%s" % [group, path, script != null])
