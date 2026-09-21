class_name Screen
extends Control
## Base for every routed screen and overlay.
## Screens declare intent; the Router owns every transition.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.4.
##
## The three intent signals below are the routed-screen interface. Subclasses emit
## them (boot.gd, main_menu.gd, loading.gd, station.gd, settings.gd, dialog.gd) and
## autoload/router.gd connects them in _bind_intents(); this base class declares the
## interface and never emits it itself, so each signal carries an explicit
## unused_signal waiver instead of being deleted. The signatures are pinned by
## IMPLEMENTATION_PLAN section 3.4 and must not change.

@warning_ignore("unused_signal")
signal route_requested(route: StringName, params: Dictionary)
@warning_ignore("unused_signal")
signal overlay_requested(route: StringName, params: Dictionary)
@warning_ignore("unused_signal")
signal overlay_close_requested


func on_route(_params: Dictionary) -> void:
	pass
