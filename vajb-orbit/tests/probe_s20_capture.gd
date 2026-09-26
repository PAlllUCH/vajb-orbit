extends Node
## S20's visual evidence probe: mounts the shipped station on a S20-shaped fixture (a
## four-cell destroyer battery and an over-cap rocket hold, so the OVER CAP chips show),
## settles the layout, and saves the rendered frame to `user://s20_armory_capture.png`.
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --path "$VAJB_PROJ" res://tests/probe_s20_capture.tscn --quit-after 400
##
## A windowed standalone run (headless renders nothing) under a scratch store (L229: a
## station-mounting probe must never boot the owner's live profile).

const StationScene := preload("res://ui/screens/station.tscn")
const FitData := preload("res://game/ship_fit.gd")

const OUT_PATH := "user://s20_armory_capture.png"
const SETTLE_FRAMES := 12
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		push_error("s20 capture: no PlayerProfile autoload")
		get_tree().quit(1)
		return
	profile.set(&"_credits", 10000)
	profile.set(&"_active_ship", DESTROYER)
	profile.set(&"_owned_ships", [DESTROYER] as Array[StringName])
	profile.set(&"_modules", {})
	profile.set(&"_cargo", {&"ammo_rocket": 40, &"ammo_cannon": 15})
	var fit: Dictionary = FitData.standard_fit(DESTROYER)
	var weapons: Array = []
	for index in FitData.slot_capacity(DESTROYER, WEAPON_SLOT):
		weapons.append("" if index > 3 else ("w_laser" if index % 2 == 0 else "w_cannon"))
	fit[WEAPON_SLOT] = weapons
	profile.call(&"set_fit", DESTROYER, fit)
	profile.call(&"set_battery_groups", DESTROYER, [[0, 1, 2, 3]])
	var station := StationScene.instantiate() as Control
	if station == null:
		push_error("s20 capture: the station scene failed to instantiate")
		get_tree().quit(1)
		return
	get_tree().root.add_child(station)
	get_window().size = Vector2i(1920, 1080)
	var fade := station.get_node_or_null(^"Layout/Fade") as ColorRect
	if fade == null:
		fade = station.get_node_or_null(^"Fade") as ColorRect
	if fade != null:
		fade.color.a = 0.0
	for _frame in SETTLE_FRAMES:
		await get_tree().process_frame
	var router := get_tree().root.get_node_or_null(NodePath(&"Router"))
	if router != null:
		var fade_rect := router.get(&"_fade_rect") as ColorRect
		if fade_rect != null:
			fade_rect.color.a = 0.0
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUT_PATH)
	print("[s20cap] wrote %s (%dx%d)" % [OUT_PATH, image.get_width(), image.get_height()])
	get_tree().quit(0)
