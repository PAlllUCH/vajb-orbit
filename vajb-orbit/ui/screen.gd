class_name Screen
extends Control
## Base for every routed screen and overlay.
## Screens declare intent; the Router owns every transition.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.4.

signal route_requested(route: StringName, params: Dictionary)
signal overlay_requested(route: StringName, params: Dictionary)
signal overlay_close_requested


func on_route(_params: Dictionary) -> void:
	pass
