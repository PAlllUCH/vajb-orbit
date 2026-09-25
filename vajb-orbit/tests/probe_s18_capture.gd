extends Node
## S18's visual evidence probe: mounts the shipped station, settles the layout, and saves
## the rendered frame to `user://s18_armory_capture.png` at the window's own size.
##
##   $GODOT_CONSOLE --path "$VAJB_PROJ" res://tests/probe_s18_capture.tscn --quit-after 400
##
## A windowed standalone run (headless renders nothing); the wave's review reads the PNG.

const StationScene := preload("res://ui/screens/station.tscn")

const OUT_PATH := "user://s18_armory_capture.png"
const SETTLE_FRAMES := 12


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var station := StationScene.instantiate() as Control
	if station == null:
		push_error("s18 capture: the station scene failed to instantiate")
		get_tree().quit(1)
		return
	get_tree().root.add_child(station)
	ProjectSettings.set_setting("display/window/size/window_width_override", 0)
	ProjectSettings.set_setting("display/window/size/window_height_override", 0)
	get_window().size = Vector2i(1920, 1080)
	## The station's entry fade is opaque until the Router plays it; a directly-mounted
	## station keeps it, so the capture clears it to read the real ink.
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
			print("[s18cap] router fade alpha=%f" % fade_rect.color.a)
			fade_rect.color.a = 0.0
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUT_PATH)
	print("[s18cap] wrote %s (%dx%d)" % [OUT_PATH, image.get_width(), image.get_height()])
	get_tree().quit(0)
