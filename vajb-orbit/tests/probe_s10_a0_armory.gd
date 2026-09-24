extends Node
## S10-A0 evidence probe: the owner's ARMORY symptoms driven through the REAL input
## pipeline - `Input.parse_input_event` -> SceneTree -> `Viewport` GUI hit-test and
## drag routing - never by calling the pane's own handlers.
##
## It mounts the shipped station screen (so the pane sits in its real ancestor chain,
## scroll container, console chrome and sibling panes), seeds a scratch account, and
## reports:
##   [S10A0] CANARY ...   a drag the probe owns, proving the injection route itself works
##   [S10A0] Q1 ...       rack selection: bay click, barrel-chip click, keys 1..7
##   [S10A0] Q2 ...       real press -> move -> release, from an inventory row and from a
##                        fitted barrel chip onto a bay
##   [S10A0] Q3 ...       the per-battery Controls the rack row actually draws
##   [S10A0] Q4 ...       mouse_filter audit + the Control the viewport hits at each bay
##
## Run (scratch store, bounded):
##   XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
##     res://tests/probe_s10_a0_armory.tscn --quit-after 5400
## Signal: the [S10A0] lines; the last line is `[S10A0] done`.

const StationScene := preload("res://ui/screens/station.tscn")
const Weapons := preload("res://game/weapons.gd")

const TAG := "[S10A0]"
const HULL: StringName = &"ship_vanguard"
const SCRATCH_PROFILE := "user://probe_s10_a0_armory.cfg"
const ARMORY_PATH := "Layout/Page/Body/ModuleHost/HostMargin/Armory"
const MOVES := 4


## A drag the probe owns: if this cannot complete, the injection is at fault and the
## pane's readings say nothing. It is mounted above the station so it wins the hit test.
class DragCanary extends Control:
	var drags := 0
	var drops := 0


	func _get_drag_data(_at: Vector2) -> Variant:
		drags += 1
		return {&"canary": true}


	func _can_drop_data(_at: Vector2, _data: Variant) -> bool:
		return true


	func _drop_data(_at: Vector2, _data: Variant) -> void:
		drops += 1


var _profile: Node = null
var _station: Control = null
var _arm: Control = null
var _canary: DragCanary = null
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
	print("%s SETUP viewport=%s pane=%s scroll=%s body=%s racks=%d inv=%d save_path=%s" % [
		TAG,
		str(get_viewport().get_visible_rect().size),
		str(_arm.size),
		str((_arm.get_node(^"ArmoryScroll") as Control).size),
		str((_arm.get_node(^"ArmoryScroll/ArmoryBody") as Control).size),
		(_arm.get("_rack_views") as Array).size(),
		(_arm.get("_inventory_views") as Array).size(),
		String(_profile.get(&"save_path")),
	])
	print("%s SETUP bay_marks=%s style=%s" % [
		TAG, str(_arm.has_method(&"bay_marks")), str(_arm.has_method(&"style")),
	])
	await _canary_check()
	await _q1()
	await _q2()
	_q3()
	await _q4()
	_teardown()


## --------------------------------------------------------------- the canary


func _canary_check() -> void:
	_canary = DragCanary.new()
	_canary.name = "DragCanary"
	_canary.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_canary)
	_canary.position = Vector2(5.0, 5.0)
	_canary.size = Vector2(100.0, 30.0)
	await _frames(2)
	var at := _canary.position + _canary.size * 0.5
	var hit := await _hover(at)
	print("%s CANARY hover=%s" % [TAG, _name_of(hit)])
	await _drag_open(at, Vector2(400.0, 700.0))
	print("%s CANARY mid-drag data=%s drags=%d" % [
		TAG, str(get_viewport().gui_get_drag_data()), _canary.drags,
	])
	await _drag_close(at)
	print("%s CANARY drags=%d drops=%d" % [TAG, _canary.drags, _canary.drops])


## ------------------------------------------------------------------- Q1 rows


func _q1() -> void:
	var bays := _bay_centres()
	print("%s Q1 seam handlers=%s" % [TAG, str(_declared_handlers())])
	print("%s Q1 before: sel=%d frames=%s focus=%s" % [
		TAG, int(_arm.call(&"selected_rack")), str(_frames_flags()),
		_name_of(get_viewport().gui_get_focus_owner()),
	])
	for rack in [1, 3]:
		if not bays.has(rack):
			continue
		var hit := await _hover(bays[rack])
		await _click(bays[rack])
		print("%s Q1 CLICK bay%d centre=%s hit=%s -> sel=%s frames=%s status=%s" % [
			TAG, rack + 1, str(bays[rack]), _name_of(hit),
			str(_sel()), str(_frames_flags()), str(_status),
		])
	var chips := _chip_centres(0)
	if not chips.is_empty():
		var chip_hit := await _hover(chips[0])
		await _click(chips[0])
		print("%s Q1 CLICK barrel chip B1 pos0 centre=%s hit=%s -> sel=%s frames=%s" % [
			TAG, str(chips[0]), _name_of(chip_hit), str(_sel()), str(_frames_flags()),
		])
	var focus_owner := _focus_a_row()
	print("%s Q1 key test with focus=%s" % [TAG, _name_of(focus_owner)])
	for digit in range(1, 8):
		var action := StringName("weapon_%d" % digit)
		var pressed := await _key(KEY_0 + digit, action)
		print("%s Q1 KEY %d mapped=%s action_pressed=%s -> sel=%s frames=%s focus=%s" % [
			TAG, digit, str(InputMap.has_action(action)), str(pressed),
			str(_sel()), str(_frames_flags()),
			_name_of(get_viewport().gui_get_focus_owner()),
		])


## ------------------------------------------------------------------- Q2 drags


func _q2() -> void:
	var bays := _bay_centres()
	print("%s Q2 bays=%s" % [TAG, str(bays)])
	print("%s Q2 inventory rows=%s" % [TAG, str(_inventory_centres())])
	print("%s Q2 groups before=%s fit.weapons=%s" % [
		TAG, str(_profile.call(&"battery_groups", HULL)),
		str(_profile.call(&"fit_for", HULL).get(&"weapons", [])),
	])
	if not bays.has(0):
		print("%s Q2 SKIP no bays drawn" % TAG)
		return
	await _drag_case(&"w_laser", bays[1], "inventory -> B2 body (empty rack)")
	await _drag_case(&"w_cannon", bays[0], "inventory -> B1 body (filled rack)")
	await _drag_case(&"w_laser", bays[2], "inventory -> B3 body (3rd instance)")
	await _barrel_source(0, bays[3])
	await _drag_case(&"w_cannon", bays[3], "inventory -> B4 body (every W cell full)")
	print("%s Q2 groups after=%s fit.weapons=%s status=%s" % [
		TAG, str(_profile.call(&"battery_groups", HULL)),
		str(_profile.call(&"fit_for", HULL).get(&"weapons", [])), str(_status),
	])


func _drag_case(base: StringName, target: Vector2, label: String) -> void:
	var source := _inventory_centre(base)
	if source == Vector2.INF:
		print("%s Q2 CASE %s: SKIP no inventory row for %s" % [TAG, label, base])
		return
	var at_source := await _hover(source)
	var at_target := await _hover(target)
	var data_target: Variant = get_viewport().gui_get_drag_data()
	print("%s Q2 CASE %s: base=%s source=%s target=%s" % [TAG, label, base, str(source), str(target)])
	print("%s Q2 CASE %s: hover source=%s target=%s" % [
		TAG, label, _name_of(at_source), _name_of(at_target),
	])
	await _drag_open(source, target)
	var hovered := get_viewport().gui_get_hovered_control()
	var data: Variant = get_viewport().gui_get_drag_data()
	print("%s Q2 CASE %s: OPEN hovered=%s drag_data=%s can_drop=%s" % [
		TAG, label, _name_of(hovered), str(data), str(_can_drop_of(hovered, data)),
	])
	await _drag_close(target)
	print("%s Q2 CASE %s: DROP hovered=%s groups=%s fit.weapons=%s status=%s" % [
		TAG, label, _name_of(get_viewport().gui_get_hovered_control()),
		str(_profile.call(&"battery_groups", HULL)),
		str(_profile.call(&"fit_for", HULL).get(&"weapons", [])), str(_status),
	])
	print("%s Q2 CASE %s: mid-target data=%s" % [TAG, label, str(data_target)])


## The barrel chip is the drag source 09 section 11 needs ("dragging within/between racks
## re-orders and swaps"). Press on the chip's own rect, mid-drag and after, and name the
## Control the viewport hits on the chip and on its name plate.
func _barrel_source(rack: int, target: Vector2) -> void:
	var views: Array = _arm.get("_rack_views")
	if rack >= views.size() or (views[rack][&"barrels"] as Array).is_empty():
		print("%s Q2 BARREL-SOURCE rack%d: SKIP no fitted barrel" % [TAG, rack + 1])
		return
	var barrel: Dictionary = (views[rack][&"barrels"] as Array)[0]
	var name_button := barrel[&"name"] as Control
	var chip := name_button.get_parent() as Control
	var at_chip := chip.global_position + chip.size * 0.5
	var at_name := name_button.global_position + name_button.size * 0.5
	var chip_hit := await _hover(at_chip)
	var name_hit := await _hover(at_name)
	print("%s Q2 BARREL-SOURCE chip=%s rect=%s filter=%d ; name rect=%s min=%s" % [
		TAG, chip.name, str(Rect2(chip.global_position, chip.size)), chip.mouse_filter,
		str(Rect2(name_button.global_position, name_button.size)),
		str(name_button.custom_minimum_size),
	])
	print("%s Q2 BARREL-SOURCE hover chip=%s hover name=%s groups=%s" % [
		TAG, _name_of(chip_hit), _name_of(name_hit),
		str(_profile.call(&"battery_groups", HULL)),
	])
	await _drag_open(at_chip, target)
	var data: Variant = get_viewport().gui_get_drag_data()
	var hovered := get_viewport().gui_get_hovered_control()
	print("%s Q2 BARREL-SOURCE OPEN hovered=%s drag_data=%s can_drop=%s sel=%s" % [
		TAG, _name_of(hovered), str(data), str(_can_drop_of(hovered, data)), str(_sel()),
	])
	await _drag_close(target)
	print("%s Q2 BARREL-SOURCE DROP groups=%s sel=%s status=%s" % [
		TAG, str(_profile.call(&"battery_groups", HULL)), str(_sel()), str(_status),
	])
	## The section 5.11 `x` on a barrel: the same chip, its close Button's own rect.
	var close_button := barrel[&"close"] as Control
	var at_close := close_button.global_position + close_button.size * 0.5
	var close_hit := await _hover(at_close)
	var before: Variant = _profile.call(&"battery_groups", HULL)
	await _click(at_close)
	print("%s Q2 BARREL-CLOSE rect=%s hit=%s groups before=%s after=%s status=%s" % [
		TAG, str(Rect2(close_button.global_position, close_button.size)), _name_of(close_hit),
		str(before), str(_profile.call(&"battery_groups", HULL)), str(_status),
	])


## ------------------------------------------------------------ Q3 the readout


func _q3() -> void:
	for view: Dictionary in _arm.get("_rack_views"):
		var rack := int(view[&"rack"])
		var row := view[&"row"] as Control
		var state := view[&"state"] as Label
		var hint := view[&"hint"] as Label
		var strip: Node = view[&"strip"] if view.has(&"strip") else null
		var figure: Variant = view[&"figure"] if view.has(&"figure") else "n/a"
		var salvo := "n/a"
		var caption := "n/a"
		if strip != null:
			salvo = String(strip.call(&"figure_text"))
			caption = (strip.call(&"caption_node") as Label).text
		var chips: Array = []
		for barrel: Dictionary in view[&"barrels"]:
			var name_button := barrel[&"name"] as Button
			var close_button := barrel[&"close"] as Button
			chips.append("name='%s' rect=%s min=%s ; close rect=%s" % [
				name_button.text, str(Rect2(name_button.global_position, name_button.size)),
				str(name_button.custom_minimum_size),
				str(Rect2(close_button.global_position, close_button.size)),
			])
		var texts: Array = []
		for node: Node in _labels(row):
			texts.append("%s='%s'" % [node.name, (node as Label).text])
		print("%s Q3 rack%d cells=%s fig=%s salvo=%s caption='%s' state='%s' state_vis=%s state_a=%s hint_vis=%s" % [
			TAG, rack + 1, str(view[&"cells"]), str(figure), salvo, caption,
			state.text, str(state.visible), str(state.modulate.a), str(hint.visible),
		])
		print("%s Q3 rack%d chips=%s labels=%s" % [TAG, rack + 1, str(chips), str(texts)])
	var found: Array = []
	for node: Node in _labels(_arm):
		var text := (node as Label).text.to_upper()
		if text.contains("AMMO") or text.contains("ROUND") or text.contains("SALVO") \
				or text.contains("SHOT") or text.contains("DRAW"):
			found.append("%s='%s'" % [node.name, (node as Label).text])
	print("%s Q3 pane labels matching ammo/round/salvo/shot/draw: %s" % [TAG, str(found)])
	print("%s Q3 ammo rows (pack cards)=%d" % [TAG, (_arm.get(&"_payloads") as Array).size()])
	print("%s Q3 SEAM weapon_id(mod_0002)='%s' weapon_id(w_cannon)='%s' weapon_id(w_laser)='%s' interval(cannon)=%s interval(laser)=%s" % [
		TAG, str(Weapons.weapon_id(&"mod_0002")), str(Weapons.weapon_id(&"w_cannon")),
		str(Weapons.weapon_id(&"w_laser")), str(Weapons.interval_of(&"cannon")),
		str(Weapons.interval_of(&"laser")),
	])
	print("%s Q3 CELLS hull weapons=%s" % [
		TAG, str(_profile.call(&"fit_for", HULL).get(&"weapons", [])),
	])


## ------------------------------------------------------ Q4 hit test + filters


func _q4() -> void:
	for path: String in [
		"ArmoryScroll",
		"ArmoryScroll/ArmoryBody",
		"ArmoryScroll/ArmoryBody/ConsolePlate",
		"ArmoryScroll/ArmoryBody/ConsoleWells",
		"ArmoryScroll/ArmoryBody/RacksMargin",
		"PaneFooter",
	]:
		var node := _arm.get_node_or_null(NodePath(path)) as Control
		if node != null:
			print("%s Q4 filter %s=%d rect=%s" % [
				TAG, path, node.mouse_filter, str(Rect2(node.global_position, node.size)),
			])
	var bays := _bay_centres()
	for rack: int in bays:
		var bay_hit := await _hover(bays[rack])
		print("%s Q4 HIT bay%d centre=%s -> %s ; chain=%s" % [
			TAG, rack + 1, str(bays[rack]), _name_of(bay_hit), _chain(bay_hit),
		])
	var first := (_arm.get("_rack_views") as Array)[0][&"row"] as Control
	for path: String in ["Box", "Box/BayPlate", "Box/BayMarks", "Box/Head", "Box/Barrels", "Box/Salvo"]:
		var node := first.get_node_or_null(NodePath(path)) as Control
		if node != null:
			print("%s Q4 filter RackRow/%s=%d rect=%s vis=%s" % [
				TAG, path, node.mouse_filter, str(Rect2(node.global_position, node.size)),
				str(node.visible),
			])
	print("%s Q4 RackRow mouse_filter=%d" % [TAG, first.mouse_filter])
	for path: String in ["LeaveConfirm", "LeaveDimmer", "Fade", "Backdrop", "Grain"]:
		var node := _station.get_node_or_null(NodePath(path)) as Control
		if node != null:
			print("%s Q4 overlay %s filter=%d visible=%s rect=%s" % [
				TAG, path, node.mouse_filter, str(node.visible),
				str(Rect2(node.global_position, node.size)),
			])
	for view: Dictionary in _arm.get("_rack_views"):
		var row := view[&"row"] as Control
		var inside := (_arm.get_node(^"ArmoryScroll") as Control).get_global_rect().encloses(
			Rect2(row.global_position, row.size)
		)
		print("%s Q4 bay%d rect=%s inside_scroll=%s" % [
			TAG, int(view[&"rack"]) + 1, str(Rect2(row.global_position, row.size)), str(inside),
		])


## ------------------------------------------------------------- the harness


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


func _motion(pos: Vector2, previous: Vector2, pressed: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.relative = pos - previous
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)


func _hover(pos: Vector2) -> Control:
	_motion(pos, pos, false)
	await _frames(3)
	return get_viewport().gui_get_hovered_control()


func _click(pos: Vector2) -> void:
	await _hover(pos)
	_mouse_button(pos, true)
	await _frames(3)
	_mouse_button(pos, false)
	await _frames(4)


func _drag_open(from: Vector2, to: Vector2) -> void:
	await _hover(from)
	_mouse_button(from, true)
	await _frames(3)
	var previous := from
	for index in MOVES:
		var point: Vector2 = from.lerp(to, float(index + 1) / float(MOVES))
		_motion(point, previous, true)
		previous = point
		await _frames(3)


func _drag_close(at: Vector2) -> void:
	_motion(at, at, true)
	await _frames(3)
	_mouse_button(at, false)
	await _frames(5)


## Press the key, report whether the InputMap action registered while it was held, release.
func _key(keycode: Key, action: StringName) -> bool:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(3)
	var registered := InputMap.has_action(action) and Input.is_action_pressed(action)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(3)
	return registered


func _bay_centres() -> Dictionary:
	var out: Dictionary = {}
	for view: Dictionary in _arm.get("_rack_views"):
		var row := view[&"row"] as Control
		out[int(view[&"rack"])] = row.global_position + row.size * 0.5
	return out


func _inventory_centres() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for view: Dictionary in _arm.get("_inventory_views"):
		var row := view[&"row"] as Control
		out.append(row.global_position + row.size * 0.5)
	return out


func _inventory_centre(base: StringName) -> Vector2:
	for view: Dictionary in _arm.get("_inventory_views"):
		if StringName(view[&"base"]) == base:
			var row := view[&"row"] as Control
			return row.global_position + row.size * 0.5
	return Vector2.INF


func _chip_centres(rack: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var views: Array = _arm.get("_rack_views")
	if rack < 0 or rack >= views.size():
		return out
	for barrel: Dictionary in views[rack][&"barrels"]:
		var name_button := barrel[&"name"] as Control
		var chip := name_button.get_parent() as Control
		out.append(chip.global_position + chip.size * 0.5)
	return out


func _focus_a_row() -> Control:
	var views: Array = _arm.get("_inventory_views")
	if views.is_empty():
		return null
	var row := views[0][&"row"] as Button
	row.grab_focus()
	return row


func _sel() -> Variant:
	if not _arm.has_method(&"selected_rack"):
		return "n/a"
	return int(_arm.call(&"selected_rack"))


func _frames_flags() -> Array:
	if not _arm.has_method(&"bay_marks"):
		return ["no bay_marks"]
	var out: Array = []
	for view: Dictionary in _arm.get("_rack_views"):
		var marks: Node = _arm.call(&"bay_marks", int(view[&"rack"]))
		out.append(int(view[&"rack"]) + 1 if marks != null and marks.call(&"is_selected") else 0)
	return out


func _declared_handlers() -> Array:
	var declared: Array = []
	var script: Script = _arm.get_script()
	if script == null:
		return declared
	for method: Dictionary in script.get_script_method_list():
		var name_text := String(method.get("name", ""))
		if name_text in ["_gui_input", "_input", "_unhandled_input", "_shortcut_input"]:
			declared.append(name_text)
	return declared


func _can_drop_of(control: Control, data: Variant) -> Variant:
	if control == null:
		return "no control"
	if data == null:
		return "no drag data"
	if control.has_method(&"_can_drop_data"):
		return control.call(&"_can_drop_data", control.get_local_mouse_position(), data)
	return "none on %s" % control.get_class()


func _labels(root: Node) -> Array[Label]:
	var out: Array[Label] = []
	for node: Node in root.find_children("*", "Label", true, false):
		out.append(node as Label)
	return out


func _name_of(node: Node) -> String:
	if node == null:
		return "<null>"
	if node == get_tree().root:
		return "<root>"
	return "%s[%s]" % [String(node.get_path()), node.get_class()]


func _chain(node: Node) -> String:
	var parts: PackedStringArray = []
	var cursor := node
	while cursor != null and cursor != get_tree().root:
		var control := cursor as Control
		var filter := str(control.mouse_filter) if control != null else "-"
		parts.append("%s:%s" % [cursor.name, filter])
		cursor = cursor.get_parent()
	return " < ".join(parts)


func _on_status(message: String, danger: bool) -> void:
	_status.append("%s%s" % ["DANGER " if danger else "", message])


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
	_profile.set(&"_modules", {
		"mod_0001": _record("mod_0001", "w_laser"),
		"mod_0002": _record("mod_0002", "w_cannon"),
		"mod_0003": _record("mod_0003", "w_laser"),
		"mod_0004": _record("mod_0004", "w_cannon"),
	})
	_profile.set(&"_cargo", {&"ammo_laser": 30, &"ammo_cannon": 15})


func _teardown() -> void:
	for key: String in _previous:
		_profile.set(key, _previous[key])
	_profile.set(&"save_path", _previous[&"save_path"])
	_remove_scratch()
	print("%s TEARDOWN scratch_present=%s save_path=%s" % [
		TAG, str(FileAccess.file_exists(SCRATCH_PROFILE)), String(_profile.get(&"save_path")),
	])


func _record(id: String, base: String) -> Dictionary:
	return {
		"base_id": base,
		"count": 1,
		"instance_id": id,
		"prefixes": [],
		"rarity": "common",
		"suffixes": [],
	}


func _remove_scratch() -> void:
	var directory := DirAccess.open(SCRATCH_PROFILE.get_base_dir())
	if directory != null:
		directory.remove(SCRATCH_PROFILE.get_file())
