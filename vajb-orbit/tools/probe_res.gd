extends Node
## One-shot boot for the resolution sweep: spawns the worker under the tree
## root (the audit_boot pattern) so the Router's scene changes free this scene
## without killing the run. One game run per resolution:
##   $GODOT_CONSOLE --path "$VAJB_PROJ" --resolution 2560x1080 res://tools/probe_res.tscn

const ProbeScript := preload("res://tools/probe_res_worker.gd")


func _ready() -> void:
	var worker := Node.new()
	worker.name = "ProbeRes"
	worker.set_script(ProbeScript)
	get_tree().root.add_child.call_deferred(worker)
