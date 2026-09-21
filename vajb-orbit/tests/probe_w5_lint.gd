extends Node
## W5 reviewer probe: per-file GDScript-warning ledger for every script this wave changed.
##
## W3's report states that "a headless run cannot observe a warning". That is false on
## this engine build: `--headless --debug` attaches the local stdout debugger, and GDScript
## warnings are emitted as `WARNING: ...` lines on stdout. This probe exploits it to lint
## one file at a time: it prints a marker, loads that single file with
## CACHE_MODE_IGNORE (so the resource cache cannot serve a stale parse), prints another
## marker, and repeats. Every `WARNING:` line between two markers belongs to the file named
## by the opening marker, which attributes warnings to files that the bare engine output
## does not name.
##
## `game/weapons.gd` and `ui/hud/minimap.gd` are positive controls: they are known to warn
## today, so a run that shows no warning for them is a blind run and the whole ledger is
## worthless. `autoload/world_clock.gd` is a negative control.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_w5_lint.tscn --quit-after 600
## Signal: the [W5-LINT] lines; the last line is [W5-LINT] done.

const FILES_D5: Array[String] = [
	"res://autoload/settings_manager.gd",
	"res://autoload/router.gd",
	"res://autoload/audio_manager.gd",
	"res://autoload/dialog_manager.gd",
	"res://autoload/player_profile.gd",
	"res://ui/screen.gd",
	"res://ui/screens/station.gd",
	"res://ui/station/refinery_panel.gd",
	"res://game/exchange.gd",
]

const FILES_W1: Array[String] = [
	"res://ui/components/slot_button.gd",
	"res://ui/station/shipyard_panel.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/hud/hud.gd",
]

const FILES_W2: Array[String] = [
	"res://game/pickup.gd",
	"res://game/sector.gd",
	"res://game/sector_registry.gd",
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
	print("[W5-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("D5", FILES_D5)
	_lint_group("W1", FILES_W1)
	_lint_group("W2", FILES_W2)
	_lint_group("POSITIVE-CONTROL", CONTROLS_POSITIVE)
	_lint_group("NEGATIVE-CONTROL", CONTROLS_NEGATIVE)
	print("[W5-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		print("[W5-LINT] BEGIN %s %s" % [group, path])
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("[W5-LINT] END   %s %s loaded=%s" % [group, path, script != null])
