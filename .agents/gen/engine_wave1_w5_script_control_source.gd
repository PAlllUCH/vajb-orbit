extends SceneTree
## Archived W5 control (the live copy was deleted with its .uid before the report).
## Run with:
##   "…_console.exe" --headless --path "…/vajb-orbit" --script res://tools/_probe_w5_script_try.gd
## and diff against .agents/gen/engine_wave1_w5_script_try.txt. It pins down whether a
## `--script` run fails on hud.gd itself or only on a script that statically references
## a HUD-typed identifier. `var _typed: Hud = null` is that reference; the runtime
## `load()` below succeeds either way.

var _typed: Hud = null


func _initialize() -> void:
	print("[w5-control] typed reference present = %s" % str(_typed == null))
	var packed := load("res://ui/hud/hud.tscn")
	print("[w5-control] hud.tscn load -> %s" % ("ok" if packed != null else "null"))
	quit(0)
