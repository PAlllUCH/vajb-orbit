extends Node
## G3 warning-sweep probe: per-file GDScript-warning ledger for the six files G3 owns.
##
## Same harness as probe_w5_lint.gd (CONTRACTS §9, fifth harness limit): `--headless
## --debug` attaches the local stdout debugger and GDScript warnings are printed as
## `WARNING:` lines attributed `at: GDScript::reload (res://file:line)`. This probe
## prints a marker, loads the single file with CACHE_MODE_IGNORE (so the resource cache
## cannot serve a stale parse), prints a closing marker, and repeats. Every WARNING line
## between two markers belongs to the file named by the opening marker.
##
## `game/weapons.gd` and `ui/hud/minimap.gd` are positive controls (known to warn on
## this build); `autoload/world_clock.gd` is a negative control. A run that reports zero
## warnings for the positive controls is blind and its ledger is worthless.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_g3_lint.tscn --quit-after 600
## Signal: the [G3-LINT] lines; the last line is [G3-LINT] done.

const FILES_G3: Array[String] = [
	"res://ui/station/exchange_panel.gd",
	"res://ui/station/shipyard_panel.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/components/slot_button.gd",
	"res://game/sector.gd",
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
	print("[G3-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("G3", FILES_G3)
	_lint_group("POSITIVE-CONTROL", CONTROLS_POSITIVE)
	_lint_group("NEGATIVE-CONTROL", CONTROLS_NEGATIVE)
	print("[G3-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		print("[G3-LINT] BEGIN %s %s" % [group, path])
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("[G3-LINT] END   %s %s loaded=%s" % [group, path, script != null])
