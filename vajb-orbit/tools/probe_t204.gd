extends Node
## One-shot boot for the T-204 probe: spawns the probe worker directly under
## the tree root so the Router's scene changes free this scene without killing
## the run (the audit_boot pattern). Run:
##   $GODOT_CONSOLE --path "$VAJB_PROJ" res://tools/probe_t204.tscn

const ProbeScript := preload("res://tools/probe_t204_worker.gd")


func _ready() -> void:
	var worker := Node.new()
	worker.name = "ProbeT204"
	worker.set_script(ProbeScript)
	get_tree().root.add_child.call_deferred(worker)
