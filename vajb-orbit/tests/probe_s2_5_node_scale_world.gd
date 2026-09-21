extends Node2D
## A black backdrop for the node-scale probe (behind everything).


func _draw() -> void:
	draw_rect(Rect2(-4000.0, -4000.0, 8000.0, 8000.0), Color.BLACK)
