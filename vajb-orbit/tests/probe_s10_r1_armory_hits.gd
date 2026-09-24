extends Node
## S10-R1 evidence probe: the ARMORY chip's hit map, measured on the **shipped station
## mount** through the real input pipeline, and again with the manual layout pass B1's
## suite (test_s10_armory_input.gd `_settle_layout`) delivers, so the two contexts can be
## compared point for point.
##
## It answers one question the wave's acceptance rests on: after the real frame's layout,
## which point on a fitted cell starts the move/swap drag, which one is the `x`, and does
## the suite's manual NOTIFICATION_SORT_CHILDREN show the same rects the game shows?
##
## Run (scratch store, bounded):
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
##     res://tests/probe_s10_r1_armory_hits.tscn --quit-after 3000
## Signal: the [S10R1] lines; the last line is `[S10R1] done`.

const StationScene := preload("res://ui/screens/station.tscn")

const TAG := "[S10R1]"
const HULL: StringName = &"ship_vanguard"
const LASER: StringName = &"w_laser"
const SCRATCH_PROFILE := "user://probe_s10_r1_armory_hits.cfg"
const ARMORY_PATH := "Layout/Page/Body/ModuleHost/HostMargin/Armory"
const MOVES := 4
const BLOCK_INSET := 4.0

var _profile: Node = null
var _station: Control = null
var _arm: Control = null
var _status: Array[String] = []
var _previous: Dictionary = {}


func _ready() -> void:
	await _run()
	print("%s done" % TAG)
	get_tree().quit(0)


func _run() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("%s FAIL no PlayerProfile autoload" % TAG)
		get_tree().quit(1)
		return
	_borrow()
	_seed()
	_station = StationScene.instantiate() as Control
	add_child(_station)
	await _frames(8)
	_station.call(&"_select_module", 0, true)
	await _frames(8)
	_arm = _station.get_node_or_null(NodePath(ARMORY_PATH))
	if _arm == null:
		print("%s FAIL armory pane not found" % TAG)
		get_tree().quit(1)
		return
	_arm.connect(&"status_requested", _on_status)
	await _three_barrel_rack()
	await _measure("station frame")
	await _drag_from(_block(_chip(0, 2)), "block below the x")
	await _drag_from(_name_left(_chip(0, 2)), "name plate's left column")
	await _drag_from(_name_centre(_chip(0, 2)), "name plate's own centre")
	await _settle_only()
	await _selection()
	await _chip_and_bay_click()
	await _close_click()
	_teardown()


## The fixture: three laser instances in W1..W3 of B1 (the shape S5's reorder rows and
## B1's suite use), one rack, every cell fitted.
func _three_barrel_rack() -> void:
	_profile.set(&"_credits", 10000)
	for _index in 3:
		_profile.call(&"add_instance", LASER, &"common", [], [])
	_profile.call(&"fit_battery", HULL, LASER, [0, 1, 2])
	_profile.call(&"set_battery_groups", HULL, [[0, 1, 2]])
	await _frames(10)


## ------------------------------------------------------------- the geometry read-out


func _views() -> Array:
	return _arm.get("_rack_views")


func _chip(rack: int, position: int) -> Control:
	var barrels: Array = (_views()[rack] as Dictionary)[&"barrels"]
	return ((barrels[position] as Dictionary)[&"name"] as Control).get_parent() as Control


func _rect(control: Control) -> String:
	return "P%s S%s" % [str(control.global_position), str(control.size)]


func _centre(control: Control) -> Vector2:
	return control.global_position + control.size * 0.5


func _name_centre(chip: Control) -> Vector2:
	return _centre(chip.get_node(^"Name") as Control)


func _name_left(chip: Control) -> Vector2:
	var name_button := chip.get_node(^"Name") as Control
	return Vector2(
		name_button.global_position.x + 2.0, name_button.global_position.y + name_button.size.y * 0.5
	)


func _block(chip: Control) -> Vector2:
	return Vector2(chip.global_position.x + chip.size.x * 0.5, chip.global_position.y + chip.size.y - BLOCK_INSET)


func _close(chip: Control) -> Vector2:
	return _centre(chip.get_node(^"Close") as Control)


## The chip's rects and, for five points on it, the Control the viewport actually hits.
func _measure(label: String) -> void:
	await _frames(6)
	var chip := _chip(0, 2)
	var name_button := chip.get_node(^"Name") as Control
	var close := chip.get_node(^"Close") as Control
	print("%s HITS %s: chip %s ; name %s ; close %s" % [
		TAG, label, _rect(chip), _rect(name_button), _rect(close),
	])
	var points := {
		"name centre": _name_centre(chip),
		"name left": _name_left(chip),
		"chip centre": _centre(chip),
		"block": _block(chip),
		"close centre": _close(chip),
	}
	for key: String in points:
		var at: Vector2 = points[key]
		var hit := await _hover(at)
		var over_close := close.get_global_rect().has_point(at)
		var over_name := name_button.get_global_rect().has_point(at)
		print("%s HITS %s: %-12s %s -> %s (in Close=%s in Name=%s)" % [
			TAG, label, key, str(at), _name_of(hit), str(over_close), str(over_name),
		])


## A real press on `from`, a move onto another barrel's block, a real release: report the
## rack record and the pane's own success line before and after.
func _drag_from(from: Vector2, label: String) -> void:
	await _restore()
	var chip := _chip(0, 2)
	var at := from
	var before := str(_profile.call(&"battery_groups", HULL))
	_status.clear()
	await _hover(at)
	var hit := _name_of(get_viewport().gui_get_hovered_control())
	_mouse_button(at, true)
	await _frames(3)
	var previous := at
	var target := _block(_chip(0, 0))
	for index in MOVES:
		var point: Vector2 = at.lerp(target, float(index + 1) / float(MOVES))
		_motion(point, previous, true)
		previous = point
		await _frames(3)
	_motion(target, target, true)
	await _frames(3)
	_mouse_button(target, false)
	await _frames(6)
	print("%s DRAG %-26s from=%s hit=%s groups %s -> %s status=%s" % [
		TAG, label, str(at), hit, before,
		str(_profile.call(&"battery_groups", HULL)), str(_status),
	])


## A motion-less press on a fitted cell's block, and a press on the plate strip of the same
## fitted bay: what each does to the selection (the seam's own reach on a bay that holds
## chips, which is where the owner's complaint lives).
func _chip_and_bay_click() -> void:
	await _restore()
	await _frames(30)
	_arm.call(&"set_selected_rack", 2)
	var before := str(_profile.call(&"battery_groups", HULL))
	_status.clear()
	var at := _block(_chip(0, 2))
	_mouse_button(at, true)
	await _frames(3)
	_motion(at, at, true)
	await _frames(3)
	_mouse_button(at, false)
	await _frames(6)
	print("%s PRESS block of a fitted cell at=%s selected=%s groups %s -> %s status=%s" % [
		TAG, str(at), str(_selected()), before, str(_profile.call(&"battery_groups", HULL)), str(_status),
	])
	var row := (_views()[0] as Dictionary)[&"row"] as Control
	var plate := row.global_position + Vector2(12.0, row.size.y - 12.0)
	_arm.call(&"set_selected_rack", 2)
	_mouse_button(plate, true)
	await _frames(3)
	_motion(plate, plate, true)
	await _frames(3)
	_mouse_button(plate, false)
	await _frames(6)
	print("%s PRESS fitted bay's own plate at=%s selected=%s groups %s" % [
		TAG, str(plate), str(_selected()), str(_profile.call(&"battery_groups", HULL)),
	])


## A real click on the `x`: the cell empties and the barrel returns to the bag.
func _close_click() -> void:
	await _restore()
	await _frames(30)
	var before: int = (_profile.call(&"modules") as Dictionary).size()
	var cells_before: Array = (_profile.call(&"fit_for", HULL) as Dictionary).get(&"weapons", [])
	_status.clear()
	var at := _close(_chip(0, 0))
	var hit := await _hover(at)
	at = _close(_chip(0, 0))
	_mouse_button(at, true)
	await _frames(3)
	_motion(at, at, true)
	await _frames(3)
	_mouse_button(at, false)
	await _frames(6)
	var cells: Array = (_profile.call(&"fit_for", HULL) as Dictionary).get(&"weapons", [])
	print("%s CLOSE at=%s hit=%s cells %s -> %s bag %d -> %d groups=%s status=%s" % [
		TAG, str(at), _name_of(hit), str(cells_before), str(cells),
		before, (_profile.call(&"modules") as Dictionary).size(),
		str(_profile.call(&"battery_groups", HULL)), str(_status),
	])


## The selection seam, presentation only: a real bay click and the drawn keys, with the
## scratch profile's own bytes and the fit/bag/rack records compared around each step.
func _selection() -> void:
	await _restore()
	_profile.call(&"flush")
	await _frames(4)
	var before := _snapshot()
	var m0 := _md5(SCRATCH_PROFILE)
	var dirty0 := bool(_profile.get(&"_dirty"))
	var at := _centre((_views()[2] as Dictionary)[&"row"] as Control)
	var hit := await _hover(at)
	_mouse_button(at, true)
	await _frames(3)
	_motion(at, at, true)
	await _frames(3)
	_mouse_button(at, false)
	await _frames(6)
	var after_click := _snapshot()
	print("%s SELECT click bay3 hit=%s selected=%s marked=%s records_equal=%s" % [
		TAG, _name_of(hit), str(_selected()), str(_marked(2)), str(before == after_click),
	])
	await _key(KEY_5)
	print("%s SELECT key5 selected=%s marked5=%s" % [TAG, str(_selected()), str(_marked(4))])
	await _key(KEY_1)
	_profile.call(&"flush")
	await _frames(4)
	var after_keys := _snapshot()
	print("%s SELECT key1 selected=%s marked1=%s records_equal=%s md5 %s -> %s dirty %s -> %s" % [
		TAG, str(_selected()), str(_marked(0)), str(before == after_keys),
		m0, _md5(SCRATCH_PROFILE), str(dirty0), str(bool(_profile.get(&"_dirty"))),
	])


## The suite's own layout pass (test_s10_armory_input.gd `_settle_layout`): a manual
## NOTIFICATION_SORT_CHILDREN on the chip, then the same read-out, so the two contexts'
## rects can be compared. No real input here.
func _settle_only() -> void:
	for view: Dictionary in _views():
		for barrel: Dictionary in view[&"barrels"]:
			var chip := (barrel[&"name"] as Control).get_parent() as Control
			chip.notification(Container.NOTIFICATION_SORT_CHILDREN)
	await _frames(4)
	await _measure("suite settle_layout")
	print("%s AFTER-SETTLE (one more real frame)" % TAG)
	await _frames(6)
	await _measure("settle + 6 real frames")


func _restore() -> void:
	_profile.call(&"set_battery_groups", HULL, [[0, 1, 2]])
	await _frames(10)


func _snapshot() -> Dictionary:
	return {
		&"fit": str(_profile.call(&"fit_for", HULL)),
		&"bag": str(_profile.call(&"modules")),
		&"racks": str(_profile.call(&"batteries")),
	}


func _selected() -> int:
	return int(_arm.call(&"selected_rack"))


func _marked(rack: int) -> bool:
	var marks = _arm.call(&"bay_marks", rack)
	return marks != null and bool(marks.call(&"is_selected"))


func _md5(path: String) -> String:
	return FileAccess.get_md5(path)


## ------------------------------------------------------------------ the input harness


func _frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame


func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	event.global_position = pos
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _motion(pos: Vector2, previous: Vector2, pressed: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.relative = pos - previous
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _hover(pos: Vector2) -> Control:
	_motion(pos, pos, false)
	await _frames(3)
	return get_viewport().gui_get_hovered_control()


func _key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await _frames(3)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await _frames(3)


func _name_of(node: Variant) -> String:
	if node == null:
		return "<null>"
	if not is_instance_valid(node):
		return "<freed>"
	return String(node.name)


func _on_status(message: String, _danger: bool) -> void:
	_status.append(message)


## ------------------------------------------------------------- the account


func _borrow() -> void:
	for key: String in [
		"save_path", "_credits", "_active_ship", "_owned_ships", "_fits", "_modules",
		"_ammo", "_cargo", "_batteries",
	]:
		_previous[key] = _profile.get(key)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove_scratch()


func _seed() -> void:
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_owned_ships", [HULL] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_batteries", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})


func _teardown() -> void:
	for key: String in _previous:
		_profile.set(key, _previous[key])
	_profile.set(&"save_path", _previous[&"save_path"])
	_remove_scratch()
	print("%s TEARDOWN scratch_present=%s save_path=%s" % [
		TAG, str(FileAccess.file_exists(SCRATCH_PROFILE)), String(_profile.get(&"save_path")),
	])


func _remove_scratch() -> void:
	var directory := DirAccess.open(SCRATCH_PROFILE.get_base_dir())
	if directory != null:
		directory.remove(SCRATCH_PROFILE.get_file())
