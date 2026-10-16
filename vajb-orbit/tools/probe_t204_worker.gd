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
	var cargo_window: Control = launch.find_child("CargoWindow", true, false)
	if cargo_window != null:
		print("T204 LAUNCH CargoWindow size=", str(cargo_window.size),
				" min=", str(cargo_window.get_combined_minimum_size()), " pos=", str(cargo_window.position))
		var cargo_rows: Control = cargo_window.get_node_or_null(
				^"CargoMargin/CargoScroll/CargoContent/CargoRows")
		if cargo_rows != null:
			for row in cargo_rows.get_children():
				if row is Control:
					print("T204 LROW ", row.name, " min=", str((row as Control).get_combined_minimum_size()))
	await _shot("launch_cargo")

	var overlay_node: Node = station.get_node_or_null(NodePath("CargoLayer/CargoOverlay"))
	if overlay_node != null and overlay_node.has_method(&"open"):
		overlay_node.call(&"open")
		await _wait(0.4)
		await _shot("overlay_open")
		var panel: Control = overlay_node.get_node_or_null(^"%CargoPanel")
		if panel != null:
			print("T204 SEAT open pos=", str(panel.position), " size=", str(panel.size))
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			press.global_position = Vector2(200.0, 200.0)
			overlay_node.call(&"_on_title_row_input", press)
			var motion := InputEventMouseMotion.new()
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			motion.global_position = Vector2(360.0, 260.0)
			overlay_node.call(&"_on_title_row_input", motion)
			print("T204 SEAT dragged pos=", str(panel.position))
			var close_chip: Button = overlay_node.get_node_or_null(^"%CargoClose")
			if close_chip != null:
				close_chip.pressed.emit()
				await _wait(0.3)
				print("T204 SEAT closed is_open=", str(overlay_node.call(&"is_open")))
			overlay_node.call(&"open")
			await _wait(0.4)
			print("T204 SEAT reopened pos=", str(panel.position))
	for host_node: Node in [launch, overlay_node]:
		if host_node == null:
			continue
		var title: Label = host_node.find_child("CargoTitle", true, false)
		if title == null:
			print("T204 TITLE no title node in ", host_node.name)
			continue
		print("T204 TITLE ", host_node.name, " text='", title.text, "' size=", str(title.size),
				" rect=", str(title.get_global_rect()), " visible=", title.is_visible_in_tree())
		var walker: Node = title
		while walker != null and walker != host_node:
			if walker is Control and not (walker as Control).visible:
				print("T204 HIDDENBY ", host_node.name, " <- ", walker.get_class(), "::", walker.name)
			walker = walker.get_parent()
		var win_node: Control = host_node.find_child("CargoWindow", true, false)
		if win_node == null and host_node.name == StringName("CargoOverlay"):
			win_node = host_node.find_child("CargoPanel", true, false)
		if win_node != null:
			var scroll_node: ScrollContainer = win_node.find_child("CargoScroll", true, false)
			if scroll_node != null:
				print("T204 WIN ", host_node.name, " scroll_v=", scroll_node.scroll_vertical,
						" scroll_size=", str(scroll_node.size))
			var content: Control = win_node.find_child("CargoContent", true, false)
			if content != null:
				for child in content.get_children():
					if child is Control:
						print("T204 CONTENT ", host_node.name, " ", child.name,
								" size=", str((child as Control).size),
								" min=", str((child as Control).get_combined_minimum_size()),
								" vis=", (child as Control).is_visible_in_tree())

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
