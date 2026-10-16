extends Node
## The resolution-sweep worker: menu, armory, launch and the C overlay, one
## shot each, at whatever window size the run was launched with. Captures land
## in /tmp/vajb_res/ tagged with RES_TAG (the resolution string, passed by the
## driver); the DONE print carries the live viewport size the WM actually gave.
## Progress prints carry the RES tag.

const OUT_DIR := "/tmp/vajb_res"


func _ready() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var tag := OS.get_environment("RES_TAG")
	if tag.is_empty():
		tag = "base"
	## The project's window_*_override pins the opening size at 1920x1080 and
	## outranks --resolution, so the sweep sizes the window itself.
	var parts := tag.split("x")
	if parts.size() == 2:
		DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
		await _wait(0.2)
		print("RES WIN want=", tag, " now=", str(DisplayServer.window_get_size()),
				" viewport=", str(get_viewport().get_visible_rect().size))
	var profile := get_node_or_null(NodePath("/root/PlayerProfile"))
	if profile != null:
		profile.save_path = "user://audit_profile.cfg"
	await _wait(1.0)
	await _shot("menu")
	_router().route(StringName("settings"))
	await _wait_idle()
	await _shot("settings")
	_router().route(StringName("station"))
	await _wait_idle()
	await _wait(0.5)
	var station := get_tree().root.get_node_or_null(NodePath("Station"))
	if station == null:
		print("RES FATAL no station")
		get_tree().quit()
		return
	station._select_module(0, true)
	await _wait(0.5)
	await _shot("armory")
	var armory: Node = (station.get("_panels") as Array)[0]
	if armory != null and armory.has_method(&"_on_left_tab"):
		armory.call(&"_on_left_tab", StringName(&"hold"))
		await _wait(0.4)
		await _shot("armory_hold")
	station._select_module(5, true)
	await _wait(0.5)
	await _shot("launch")
	var overlay := station.get_node_or_null(NodePath("CargoLayer/CargoOverlay"))
	if overlay != null:
		overlay.open()
		await _wait(0.4)
		await _shot("overlay")
		overlay.close()
		await _wait(0.3)
	print("RES DONE tag=", tag, " viewport=", str(get_viewport().get_visible_rect().size),
			" window=", str(DisplayServer.window_get_size()))
	get_tree().quit()


func _router() -> Node:
	return get_node_or_null(NodePath("/root/Router"))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var tag := OS.get_environment("RES_TAG")
	if tag.is_empty():
		tag = "base"
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s_%s.png" % [OUT_DIR, tag, shot_name]
	image.save_png(path)
	_index += 1
	print("RES SHOT ", path, " ", image.get_width(), "x", image.get_height())

var _index := 0


func _wait_idle() -> void:
	var router := _router()
	var budget := 6.0
	while router != null and router.is_busy() and budget > 0.0:
		await get_tree().create_timer(0.1).timeout
		budget -= 0.1
	await _wait(0.2)
