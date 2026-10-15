extends Node
## One-shot boot for the visual audit sweep (owner 2026-10-15): spawns the sweep
## worker directly under the tree root so the Router's scene changes free this
## scene without killing the run. Run:
##   $GODOT_CONSOLE --path "$VAJB_PROJ" res://tools/audit_boot.tscn
## Captures land in /tmp/vajb_audit/ and progress prints carry the AUDIT tag.

const SweepScript := preload("res://tools/audit_sweep.gd")


func _ready() -> void:
	var worker := Node.new()
	worker.name = "AuditSweep"
	worker.set_script(SweepScript)
	get_tree().root.add_child.call_deferred(worker)
