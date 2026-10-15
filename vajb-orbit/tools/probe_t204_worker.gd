extends Node
## The T-204 probe worker (spawned under /root by probe_t204.gd so the
## Router's scene changes cannot free it): the ARMORY's AMMUNITION tab
## geometry against the other tabs, the LAUNCH cargo segment's geometry, and
## the armory's left column (the cargo-preview seat). Captures land in
## /tmp/vajb_t204/; prints carry the T204 tag. The profile's save redirects
## to user://audit_profile.cfg; the real save is never touched.

const OUT_DIR := "/tmp/vajb_t204"

var _index := 0


func _ready() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var profile := get_node_or_null(NodePath("/root/PlayerProfile"))
	if profile != null:
		profile.save_path = "user://audit_profile.cfg"
	await _wait(1.0)
	_router().route(StringName("station"))
	await _wait_idle()
	var station := get_tree().root.get_node_or_null(NodePath("Station"))
	if station == null:
		print("T204 FATAL no station")
		get_tree().quit()
		return
	station._select_module(0, true)
	await _wait(0.5)
	var armory: Node = (station.get("_panels") as Array)[0]
	if armory == null:
		print("T204 FATAL no armory pane")
		get_tree().quit()
		return
	var rows: VBoxContainer = armory.get_node_or_null(^"%BrowserRows")
	var scroll: Control = armory.get_node_or_null(^"%BrowserScroll")
	for tab_id: StringName in [&"ammo", &"weapons", &"all"]:
		armory.call(&"select_tab", tab_id)
		await _wait(0.5)
		if scroll != null:
			print("T204 SCROLL ", String(tab_id), " size=", str(scroll.size),
					" min=", str(scroll.get_combined_minimum_size()))
		_print_rows(tab_id, rows)
		await _shot("armory_tab_" + String(tab_id))
	var left: Control = armory.get_node_or_null(^"%FitLeftStack")
	if left != null:
		print("T204 LEFTCOL ", left.name, " size=", str(left.size),
				" min=", str(left.get_combined_minimum_size()))
		for child in left.get_children():
			if child is Control:
				print("T204 LEFT ", child.name, " min=", str((child as Control).get_combined_minimum_size()),
						" size=", str((child as Control).size))

	station._select_module(5, true)
	await _wait(0.5)
	var launch: Node = (station.get("_panels") as Array)[5]
	for pair: Array in [["%CargoCaption", launch.get_node_or_null(^"%CargoCaption")],
			["%CargoSlots", launch.get_node_or_null(^"%CargoSlots")],
			["%CargoList", launch.get_node_or_null(^"%CargoList")]]:
		var node: Control = pair[1]
		if node != null:
			print("T204 LAUNCH ", pair[0], " size=", str(node.size),
					" min=", str(node.get_combined_minimum_size()), " pos=", str(node.position))
	await _shot("launch_cargo")

	print("T204 DONE index=", _index)
	get_tree().quit()


func _print_rows(tab_id: StringName, rows: VBoxContainer) -> void:
	if rows == null:
		print("T204 ROWS no browser rows node")
		return
	print("T204 TAB ", tab_id, " rows_size=", str(rows.size),
			" rows_min=", str(rows.get_combined_minimum_size()),
			" count=", rows.get_child_count())
	for child in rows.get_children():
		var control := child as Control
		if control == null:
			continue
		print("T204 ROW ", control.name, " size=", str(control.size),
				" min=", str(control.get_combined_minimum_size()))


func _router() -> Node:
	return get_node_or_null(NodePath("/root/Router"))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_idle() -> void:
	var router := _router()
	var budget := 6.0
	while router != null and router.is_busy() and budget > 0.0:
		await get_tree().create_timer(0.1).timeout
		budget -= 0.1
	await _wait(0.2)


func _shot(shot_name: String) -> void:
	await _wait(0.1)
	var image := get_viewport().get_texture().get_image()
	_index += 1
	var path := "%s/%02d_%s.png" % [OUT_DIR, _index, shot_name]
	image.save_png(path)
	print("T204 SHOT ", path, " ", image.get_width(), "x", image.get_height())
