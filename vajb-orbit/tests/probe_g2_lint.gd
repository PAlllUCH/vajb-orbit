extends Node
## G2 probe: the CONTRACTS section 9 debug-lint ledger for this worker's two files.
##
## Same mechanism as `probe_w5_lint.gd`: `--headless --debug` attaches the local
## stdout debugger, which prints every GDScript warning as `WARNING: ...` with an
## `at: GDScript::reload (res://file:line)` line. This probe prints a marker, loads
## one file with CACHE_MODE_IGNORE (so the resource cache cannot serve a stale
## parse), prints another marker, and repeats; every `WARNING:` between two markers
## belongs to the file named by the opening marker.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_g2_lint.tscn --quit-after 600
## Signal: the [G2-LINT] lines; the last line is [G2-LINT] done.

const FILES_OWNED: Array[String] = [
	"res://game/weapons.gd",
	"res://game/projectile.gd",
]

## A file this wave does not own but that is known to warn today: a run that shows
## no warning for it is blind, and the ledger is worthless.
const CONTROL_POSITIVE: String = "res://ui/hud/minimap.gd"

## A file with no warning today.
const CONTROL_NEGATIVE: String = "res://autoload/world_clock.gd"


func _ready() -> void:
	await get_tree().process_frame
	print("[G2-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("OWNED", FILES_OWNED)
	_lint_file("POSITIVE-CONTROL", CONTROL_POSITIVE)
	_lint_file("NEGATIVE-CONTROL", CONTROL_NEGATIVE)
	print("[G2-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		_lint_file(group, path)


func _lint_file(group: String, path: String) -> void:
	print("[G2-LINT] BEGIN %s %s" % [group, path])
	var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	print("[G2-LINT] END   %s %s loaded=%s" % [group, path, script != null])
