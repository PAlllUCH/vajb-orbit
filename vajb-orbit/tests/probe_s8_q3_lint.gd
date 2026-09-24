extends Node
## S8-Q3 probe: the per-file GDScript-warning ledger for the wave's warning-ledger
## family (CONTRACTS section 21, AC8). Same instrument as `tests/probe_w1_lint.gd`:
## a marker is printed, the file is loaded with `CACHE_MODE_IGNORE` so the resource
## cache cannot serve a stale parse, and the closing marker follows, so every
## `WARNING:` line between two markers belongs to the file the opening marker named.
## `--headless --debug` attaches the stdout debugger, which is what makes the
## warnings visible at all.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_s8_q3_lint.tscn --quit-after 600

const FILES: Array[String] = [
	"res://game/weapons.gd",
	"res://game/module_catalog.gd",
	"res://game/projectile.gd",
	"res://game/player_state.gd",
	"res://game/game.gd",
	"res://game/asteroid.gd",
	"res://game/asteroid_field.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/station/repairs_panel.gd",
	"res://ui/hud/hud.gd",
]


func _ready() -> void:
	await get_tree().process_frame
	print("[S8-Q3-LINT] debugger_active=%s" % EngineDebugger.is_active())
	for path: String in FILES:
		print("[S8-Q3-LINT] BEGIN %s" % path)
		var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		print("[S8-Q3-LINT] END   %s loaded=%s" % [path, script != null])
	print("[S8-Q3-LINT] done")
	get_tree().quit(0)
