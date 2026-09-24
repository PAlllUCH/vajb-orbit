@tool
extends McpTestSuite
## Suite s10_armory_input: wave S10's ARMORY interactivity, driven through the **real**
## input pipeline - `Input.parse_input_event` -> SceneTree -> `Viewport` GUI hit-test and
## drag routing - and never by calling the pane's own handlers (S8's L170: a suite that
## calls `can_drop` / `drop` directly proves the handler, never the plumbing).
##
## It measures S10-A0's four findings that the fix wave closed:
##  1. a fitted cell's **two hit targets** - the drag (the barrel chip's name plate, and the
##     chip itself) and the `x` remove - survive a layout pass; D7's restyle left both at
##     zero width, so a real press started neither (the owner's "cannot drag equipped
##     weapons" / "cannot remove");
##  2. a rolled/bought **instance** in a cell still yields the SALVO drum's cycle figure
##     (`weapon_id` answers `""` for `mod_0002`, so the drum was blank for the owner's own
##     fit shape);
##  3. a bay click and the drawn `(1)`..`(7)` keys move the selected rack, and the selection
##     writes nothing to the profile.
##
## **The gate runs one frame**: `headless_runner.gd` calls each `test_*` synchronously, so
## the pane's own layout pass is delivered by `_settle_layout()` (`Container.
## NOTIFICATION_SORT_CHILDREN` on every barrel chip - what the frame after the build does)
## before any input is injected. A drag the suite owns (`DragCanary`, mounted above the
## pane) proves the injection route before the pane's readings are trusted.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s10_armory_input.cfg"

const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const CANNON: StringName = &"w_cannon"
const LASER: StringName = &"w_laser"

const MOVES := 4
const CANARY_MOVE := Vector2(220.0, 320.0)
## The chip's block below the `x`: the part of a fitted cell a press reaches without the
## close button (the `x` sits in the slot's top corner).
const BLOCK_INSET := 4.0


## A drag the suite owns, mounted above the pane: if it cannot complete, the injection is at
## fault and the pane's readings say nothing.
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
var _host: Control = null
var _panel: Control = null
var _canary: DragCanary = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s10_armory_input"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "ArmoryInputHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	_profile.add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	_mount_canary()
	_run_canary()


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null
	_canary = null


## The fixture account every test starts from: the Vanguard active and owned, no stored fit
## (the racks are derived from the standard fit), no modules, no racks - written through the
## private fields the sibling suites hand back, so no purchase is charged and no signal fires
## before the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})


## The canary rides above the pane, so it wins the hit test inside its own rect.
func _mount_canary() -> void:
	_canary = DragCanary.new()
	_canary.name = "DragCanary"
	_canary.mouse_filter = Control.MOUSE_FILTER_STOP
	_canary.position = Vector2(5.0, 5.0)
	_canary.size = Vector2(100.0, 30.0)
	_host.add_child(_canary)


## The injection canary, run before every test: a drag the suite owns must complete (a
## `_get_drag_data` on the press's first motion, a `_drop_data` on the release over itself).
func _run_canary() -> void:
	var at := _canary.position + _canary.size * 0.5
	_hover(at)
	_press(at)
	_motion(at + CANARY_MOVE, at, true)
	_motion(at, at + CANARY_MOVE, true)
	_release(at)
	assert_true(
		_hovered_name() == "DragCanary",
		"the canary owns the point it sits on (hovered %s)" % _hovered_name()
	)
	assert_eq(_canary.drags, 1, "the canary's press + move opened a real drag")
	assert_eq(_canary.drops, 1, "and its release over itself delivered a real drop")


## --------------------------------------------------------------- the pane's read-backs


func _cells() -> Array:
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	return fit.get(WEAPON_SLOT, [])


func _stored() -> Array:
	return _profile.call(&"batteries").get(String(VANGUARD), [])


func _rack_cells(rack: int) -> Array:
	var rows: Array = _panel.call(&"rack_rows")
	return rows[rack][&"cells"]


func _figure_text(rack: int) -> String:
	return String(_panel.call(&"salvo_readout", rack)[&"text"])


func _figure(rack: int) -> int:
	return int(_panel.call(&"salvo_readout", rack)[&"figure"])


func _selected() -> int:
	return int(_panel.call(&"selected_rack"))


func _marked(rack: int) -> bool:
	var marks = _panel.call(&"bay_marks", rack)
	return marks != null and bool(marks.call(&"is_selected"))


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _snapshot() -> Dictionary:
	return {
		&"fit": _profile.call(&"fit_for", VANGUARD),
		&"bag": _profile.call(&"modules"),
		&"racks": _profile.call(&"batteries"),
	}


## ------------------------------------------------------------- the injected geometry


## One chip's `Name` / `Close` Control of a drawn rack (`Barrel<position + 1>`).
func _chip(rack: int, position: int) -> Control:
	var views: Array = _panel.get("_rack_views")
	var barrel: Dictionary = (views[rack][&"barrels"] as Array)[position]
	return (barrel[&"name"] as Control).get_parent() as Control


func _centre(control: Control) -> Vector2:
	return control.global_position + control.size * 0.5


func _name_centre(rack: int, position: int) -> Vector2:
	return _centre(_chip(rack, position).get_node(^"Name") as Control)


func _close_centre(rack: int, position: int) -> Vector2:
	return _centre(_chip(rack, position).get_node(^"Close") as Control)


func _block_centre(rack: int, position: int) -> Vector2:
	var chip := _chip(rack, position)
	return Vector2(
		chip.global_position.x + chip.size.x * 0.5,
		chip.global_position.y + chip.size.y - BLOCK_INSET
	)


func _bay_centre(rack: int) -> Vector2:
	var views: Array = _panel.get("_rack_views")
	return _centre(views[rack][&"row"] as Control)


## The pane's own layout pass, as the frame after the build makes it: a box container's sort
## reflows the chip's children to their minimum size, which is the reading A0 measured dead.
func _settle_layout() -> void:
	for view: Dictionary in _panel.get("_rack_views"):
		for barrel: Dictionary in view[&"barrels"]:
			var chip := (barrel[&"name"] as Control).get_parent() as Control
			chip.notification(Container.NOTIFICATION_SORT_CHILDREN)


## A three-laser rack in B1, one instance per W cell: the fixture S5's own reorder rows use,
## and the one whose post-write name reading is deterministic (the pane names the moved barrel
## from the rack's cell at that position **after** the write).
func _three_barrel_rack() -> void:
	for _index in 3:
		_profile.call(&"add_instance", LASER, &"common", [], [])
	assert_true(
		bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1, 2])),
		"three laser instances fill W1..W3"
	)
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0, 1, 2]])), "all in B1")


## ------------------------------------------------------------------ the input harness


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


func _hover(pos: Vector2) -> void:
	_motion(pos, pos, false)


func _hovered_name() -> String:
	var hovered := _panel.get_viewport().gui_get_hovered_control()
	return String(hovered.name) if hovered != null else "<null>"


func _press(pos: Vector2) -> void:
	_hover(pos)
	_mouse_button(pos, true)


func _release(pos: Vector2) -> void:
	_motion(pos, pos, true)
	_mouse_button(pos, false)


func _click(pos: Vector2) -> void:
	_press(pos)
	_release(pos)


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from)
	var previous := from
	for index in MOVES:
		var point: Vector2 = from.lerp(to, float(index + 1) / float(MOVES))
		_motion(point, previous, true)
		previous = point
	_release(to)


func _key(digit: int) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_0 + digit
		event.physical_keycode = KEY_0 + digit
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------- 1. the fitted cell's two hit targets


## The owner's "cannot drag equipped weapons": after a layout pass, a real press on the fitted
## cell's **name plate** opens a barrel drag and a real release on another barrel of the same
## rack commits the swap (09 section 11's within/between-rack drag).
func test_a_real_named_plate_drag_commits_the_swap() -> void:
	_three_barrel_rack()
	_settle_layout()
	assert_eq(_chip(0, 0).size, Vector2(40.0, 44.0), "the chip keeps its slot recess")
	_hover(_name_centre(0, 2))
	assert_eq(
		_hovered_name(), "Name",
		"the name plate is the drag handle (hovered %s)" % _hovered_name()
	)
	_drag(_name_centre(0, 2), _block_centre(0, 0))
	assert_eq(_stored(), [[2, 0, 1]], "the real drag committed the within-rack swap")
	assert_eq(_rack_cells(0), [2, 0, 1], "and the pane's read-back follows the record")
	assert_eq(
		_last_status(), PanelScript.STATUS_MOVED % ["LASER MKII", "B1"],
		"with the pane's own success line"
	)


## The chip itself carries the drag data too, so the machined block below the `x` is a handle:
## a real press there drags and commits the same way.
func test_the_chip_itself_is_a_drag_source() -> void:
	_three_barrel_rack()
	_settle_layout()
	_hover(_block_centre(0, 2))
	assert_eq(
		_hovered_name(), "Barrel3", "the chip's block is under the press (hovered %s)" % _hovered_name()
	)
	_drag(_block_centre(0, 2), _block_centre(0, 0))
	assert_eq(_stored(), [[2, 0, 1]], "the chip's own drag data committed the swap")
	assert_eq(
		_last_status(), PanelScript.STATUS_MOVED % ["LASER MKII", "B1"],
		"with the pane's own success line"
	)


## The section 5.11 `x`: a real click on it returns the barrel to the inventory. It is the one
## hit target on the chip a press does not drag from, so its own rect must be hittable too.
func test_a_real_close_click_removes_the_barrel() -> void:
	_settle_layout()
	var at := _close_centre(0, 0)
	_hover(at)
	assert_eq(
		_hovered_name(), "Close", "the x is its own hit target (hovered %s)" % _hovered_name()
	)
	_click(at)
	assert_eq(String(_cells()[0]), "", "the cell is empty")
	assert_eq(_stored(), [], "and the rack record drops the reference")
	assert_eq(
		_last_status(), PanelScript.STATUS_REMOVED % "LASER MKII", "the pane reports the remove"
	)


## ------------------------------------------- 2. the SALVO drum for an instance-keyed cell


## A2: `weapon_id("mod_0002")` is `""`, so `_rack_cycle` must resolve the cell's base id
## first. A base-keyed cell still reads exactly what it read before.
func test_an_instance_keyed_rack_reads_the_cycle_figure() -> void:
	var cannon := StringName(_profile.call(&"add_instance", CANNON, &"common", [], []))
	assert_true(String(cannon).begins_with("mod_"), "the fixture mints a rolled instance")
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, cannon)),
		"the instance fits W2"
	)
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "one barrel per rack")
	assert_eq(String(_cells()[1]), String(cannon), "the cell holds the instance id")
	assert_eq(_figure(1), 60, "the instance-keyed rack reads the cannon's 0.6 s in hundredths")
	assert_eq(_figure_text(1), "060", "which the three drum cells render as 060")
	## A base-keyed cell answers the same figure: the resolution is an identity for a base id.
	_profile.call(&"add_module", LASER, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, LASER)),
		"a base-keyed laser fits W3"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1, 2]])), "the laser joins B2"
	)
	assert_eq(_figure_text(1), "060", "the mixed rack still gates on its slowest member")


## ------------------------------------------------- 3. the selection seam


## A1: a real click on a bay selects it - the section 3.2 ember frame follows - and the drawn
## `(1)`..`(7)` keys do the same through `_unhandled_input`. Presentation only: no write.
func test_a_bay_click_and_the_keys_move_the_selection() -> void:
	_settle_layout()
	var before := _snapshot()
	assert_eq(_selected(), 0, "B1 wears the frame by default")
	var at := _bay_centre(2)
	_hover(at)
	assert_eq(_hovered_name(), "Rack3", "the bay itself owns its centre")
	_click(at)
	assert_eq(_selected(), 2, "a real click moves the selection to B3")
	assert_true(_marked(2), "and B3 wears the ember frame")
	assert_false(_marked(0), "while B1's frame is gone")
	assert_true(InputMap.has_action(&"weapon_5"), "the drawn hints are bound actions")
	_key(5)
	assert_eq(_selected(), 4, "the 5 key selects B5")
	assert_true(_marked(4), "whose bay wears the frame")
	_key(1)
	assert_eq(_selected(), 0, "and the 1 key selects B1")
	assert_eq(_profile.call(&"batteries"), before[&"racks"], "no selection wrote the rack record")
	assert_eq(_profile.call(&"fit_for", VANGUARD), before[&"fit"], "nor the fit")
	assert_eq(_profile.call(&"modules"), before[&"bag"], "nor the bag")
