extends McpTestSuite
## Suite s15_armory_layout: wave S15's ARMORY rework (09 section 12, STATION_HUB section
## 5.11's 2026-09-25 amendment) -- **five bays flowing 4+1, one per cockpit lamp**, and the
## rack plate's fit corrected onto the plate's own ink (playthrough finding F1).
##
##  - **AC4** -- the pane draws five bays (4 + 1), labelled `B1..B5`, and every bay's four
##    slots, its ledge and its three SALVO drums sit **inside the plate's ink**
##    (`ui_armory_rack_plate.png`, the bar at rows 49..132) at the art's own ~34.5 px slot
##    pitch, with the drums' bottom edge flush with the ink's bottom. The pre-S15 block
##    (40 x 44 at drawn (10, 38) on a 44 px pitch) is measured against the same ink and
##    shown to fall outside it: that is F1, and the fix is the difference.
##  - **AC5** -- armory rack i and cockpit lamp i are the same ordinal 1:1, the `(i)` key
##    selection lights lamp i, and the five lamps are the five bays.
##  - **AC1's pane half** -- a battery already holding four cells refuses the drop of a
##    fifth through the drop zone's own preview and the profile's transaction, and writes
##    nothing. (The record-level half is `tests/test_s15_battery_cap.gd`'s; the pane is
##    mounted here, so its refusal rides along.)
##
## The ink is read off the **shipped texture**, pixel by pixel, so the measurement is the
## frame's own and not a copy of a constant. The pane is mounted the way
## `tests/test_d7_armory.gd` mounts it (the shipped scene, the shipped theme, the
## profile borrowed and handed back), and the cockpit's band the way
## `tests/test_d7_cockpit.gd` does. Neither suite is touched.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StyleScript := preload("res://ui/station/armory_style.gd")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const HudScene := preload("res://ui/hud/hud.tscn")
const FitData := preload("res://game/ship_fit.gd")
const WeaponData := preload("res://game/weapons.gd")

const PLATE_PATH := "res://assets/ui/ui_armory_rack_plate.png"
const PROFILE_PATH := "user://test_s15_armory_layout.cfg"

## The plate's own ink box, measured 2026-09-25 and re-measured below on every run:
## `ui_armory_rack_plate.png` is 194 x 182 with its plate bar at rows 49..132, cols 7..186.
const INK := Rect2(7.0, 49.0, 180.0, 84.0)
## The same box as the art's **rows**: 49..132 inclusive, so the drums' bottom-most pixel
## row can be compared against the bar's own last row rather than an exclusive edge.
const INK_ROWS := Vector2i(49, 132)
## The art's drawn recesses: centres x 45 / 79 / 114 / 148 -> a ~34.5 px pitch.
const SLOT_PITCH := 34.5
const PITCH_TOLERANCE := 2.0
const FIRST_SLOT_CENTRE := 45.0
const RACK_COUNT := 5
const LAMP_COUNT := 5
## The pre-S15 bay block (the F1 defect): slots 40 x 44 drawn at (10, 38), pitch 44 -
## `ui/station/armory_style.gd`'s retired defaults, kept here as the measured "before".
const BEFORE_SLOT := Rect2(10.0, 38.0, 40.0, 44.0)
const BEFORE_SLOT_PITCH := 44.0

const VANGUARD: StringName = &"ship_vanguard"
const START_CREDITS := 10000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _hud: Control = null
var _status: Array[String] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s15_armory_layout"


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
	_previous_credits = int(_profile.get(&"_credits"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_batteries", {})
	_host = Control.new()
	_host.name = "ArmoryLayoutHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	return profile if profile != null else tree.root


func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, _danger: bool) -> void:
	_status.append(message)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _mount_hud() -> Control:
	_hud = HudScene.instantiate() as Control
	_hud.theme = ThemeRes
	_host.add_child(_hud)
	return _hud


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _style() -> Resource:
	return _panel.call(&"style")


func _rack_row(index: int) -> PanelContainer:
	return (_panel.get_node("%RackRows") as VBoxContainer).get_child(index) as PanelContainer


func _drawn_slot_rects(style: Resource) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for index in style.slot_count:
		out.append(style.drawn_rect(style.slot_rect(index)))
	return out


## The plate's ink box, measured off the shipped texture pixel by pixel: every pixel with
## alpha > 0 is ink, so the box is the art's bar. The import is lossless
## (`compress/mode=0`) and the panel draws this very texture, so the measurement is the
## frame's own.
func _measured_ink() -> Rect2:
	var image: Image = null
	var texture: Texture2D = ResourceLoader.load(PLATE_PATH) as Texture2D
	if texture != null:
		image = texture.get_image()
	if image == null and FileAccess.file_exists(PLATE_PATH):
		image = Image.load_from_file(PLATE_PATH)
	if image == null:
		return Rect2()
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2()
	return Rect2(
		float(min_x), float(min_y), float(max_x - min_x + 1), float(max_y - min_y + 1)
	)


## ------------------------------------------------- AC4: the plate fit (finding F1)

## AC4's ink row: the shipped plate is the 194 x 182 master with its bar at rows 49..132,
## and **every drawn mark the bay lays sits inside that bar** -- the four slot recesses on
## the art's own ~34.5 px pitch (first centre at drawn x 45), the ledge spanning the bar,
## and the three SALVO drums with their bottom edge flush with the bar's bottom. The
## pre-S15 block is measured against the same bar and does **not** fit it: that is F1.
func test_the_bay_marks_sit_on_the_plates_own_ink() -> void:
	var panel := _mount()
	var style := _style()
	var master: Vector2 = ResourceLoader.load(PLATE_PATH).get_size()
	assert_eq(master, Vector2(194.0, 182.0), "the plate master is the bay's own 194 x 182 box")
	var ink := _measured_ink()
	assert_eq(
		ink, INK,
		"the measured ink box is the plate bar at rows 49..132, cols 7..186 (actual %s)" % str(ink)
	)
	## --- after: the shipped marks -------------------------------
	var slots := _drawn_slot_rects(style)
	assert_eq(slots.size(), 4, "four W-cell recesses per bay")
	for index: int in slots.size():
		assert_true(
			INK.encloses(slots[index]),
			"slot %d sits inside the ink bar (actual %s)" % [index, str(slots[index])]
		)
		var centre: float = slots[index].position.x + slots[index].size.x * 0.5
		assert_true(
			absf(centre - (FIRST_SLOT_CENTRE + float(index) * SLOT_PITCH)) <= PITCH_TOLERANCE,
			"slot %d is centred on the art's recess (centre %.1f)" % [index, centre]
		)
	var pitch: float = (
		(slots[3].position.x + slots[3].size.x * 0.5)
		- (slots[0].position.x + slots[0].size.x * 0.5)
	) / 3.0
	assert_true(
		absf(pitch - SLOT_PITCH) <= PITCH_TOLERANCE,
		"the drawn slot pitch is the art's ~34.5 px (actual %.2f)" % pitch
	)
	var ledge := Rect2(
		style.drawn_vector(Vector2(4.0, style.ledge_offset)),
		style.drawn_vector(Vector2(style.bay_size.x - 8.0, 4.0))
	)
	assert_true(INK.encloses(ledge), "the ledge band lies on the ink bar (actual %s)" % str(ledge))
	for index in style.salvo_cells:
		var drum: Rect2 = style.drawn_rect(style.salvo_cell_rect(index))
		assert_true(INK.encloses(drum), "SALVO drum %d sits on the ink bar" % index)
		assert_eq(
			int(drum.end.y) - 1, INK_ROWS.y,
			"drum %d's bottom-most pixel row is the bar's own last row (bottom-aligned)" % index
		)
	## --- before: the retired S15-predecessor block ---------------
	for index in 4:
		var before := Rect2(
			BEFORE_SLOT.position + Vector2(float(index) * BEFORE_SLOT_PITCH, 0.0), BEFORE_SLOT.size
		)
		assert_false(
			INK.encloses(before),
			"the pre-S15 slot %d fell outside the ink (F1: actual %s)" % [index, str(before)]
		)


## ---------------------------------------- AC4: the five bays, 4 + 1, B1..B5

## AC4's other half: the pane draws exactly five bays flowing 4 + 1, each a bolted plate
## at the pinned 194 x 182 box with the tail bay full-width, labelled `B1..B5` with the
## matching `(1)..(5)` key hints -- and no sixth or seventh bay remains.
func test_the_pane_draws_five_bays_flowing_four_plus_one() -> void:
	var panel := _mount()
	assert_eq(PanelScript.RACK_COUNT, RACK_COUNT, "the pane's rack count is the hardcap's five")
	assert_eq(RACK_COUNT, WeaponData.GROUPS_MAX, "and it is the input map's own number")
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), RACK_COUNT, "five bays, no more")
	var columns: int = int(_style().bay_columns)
	assert_eq(columns, 4, "the grid's four columns")
	var cell: Vector2 = _style().drawn_vector(_style().bay_size)
	var gap: float = _style().drawn(_style().bay_gap)
	var well: Rect2 = _style().drawn_rect(_style().racks_well)
	var origin: Vector2 = _style().drawn_vector(_style().bay_origin)
	var row_width: float = float(columns) * cell.x + float(maxi(columns - 1, 0)) * gap
	for index in bays.size():
		var bay: Rect2 = bays[index]
		var column := index % columns
		var row := index / columns
		var size: Vector2 = Vector2(row_width, cell.y) if index == RACK_COUNT - 1 else cell
		var want := Rect2(
			well.position + origin + Vector2(float(column) * (cell.x + gap), float(row) * (cell.y + gap)),
			size
		)
		assert_true(
			bay.is_equal_approx(want),
			"bay %d is the grid's own %s cell (actual %s)" % [index, str(want), str(bay)]
		)
	for index in RACK_COUNT:
		var row := _rack_row(index)
		assert_eq(
			(row.get_node(^"Box/Head/Label") as Label).text, "B%d" % (index + 1),
			"bay %d carries its own label" % index
		)
		assert_eq(
			(row.get_node(^"Box/Head/Key") as Label).text, "(%d)" % (index + 1),
			"and its own key hint"
		)
	assert_eq(int(_style().bay_row_count(RACK_COUNT)), 2, "five bays flow 4 + 1 into two rows")


## ----------------------------------------- AC5: rack i <-> cockpit lamp i

## AC5: the five bays and the cockpit band's five lamps are the same ordinal space -- the
## `(i)` key selection lights lamp i -- and the armory's own selection seam moves the same
## ordinal's bay. The sixth ordinal is past the hardcap: nothing is lit and nothing is
## selected for it. `tests/test_d7_cockpit.gd`'s lamp rows are exercised unchanged by the
## gate; this suite only re-measures the seam they share.
func test_rack_i_and_lamp_i_are_one_ordinal() -> void:
	var panel := _mount()
	var hud := _mount_hud()
	var cockpit_style := CockpitStyleScript.defaults()
	assert_eq(int(cockpit_style.lamp_count), LAMP_COUNT, "the cockpit band is five lamps")
	assert_eq(LAMP_COUNT, RACK_COUNT, "one lamp per bay")
	assert_eq(LAMP_COUNT, WeaponData.GROUPS_MAX, "and one per battery the map addresses")
	var band: Control = (hud.call(&"cockpit") as Control).call(&"lamp_band")
	for rack: int in range(1, RACK_COUNT + 1):
		hud.call(&"select_battery", rack)
		assert_eq(int(band.call(&"lit_rack")), rack, "rack %d lights lamp %d" % [rack, rack])
		panel.call(&"set_selected_rack", rack - 1)
		assert_eq(
			int(panel.call(&"selected_rack")), rack - 1,
			"and the same ordinal's bay wears the armory's frame"
		)
		assert_true(
			bool((panel.call(&"bay_marks", rack - 1) as Node).call(&"is_selected")),
			"bay %d is the marked one" % rack
		)
		if rack > 1:
			assert_false(
				bool((panel.call(&"bay_marks", 0) as Node).call(&"is_selected")),
				"and B1's frame is gone"
			)
	## The sixth ordinal is past the hardcap: the HUD refuses it and forwards it to the
	## band, whose own rule clears the lamp (F1's root fix), and the pane marks no bay for
	## an ordinal that has none.
	hud.call(&"select_battery", RACK_COUNT + 1)
	assert_eq(int(band.call(&"lit_rack")), 0, "a sixth battery clears the lamp")
	panel.call(&"set_selected_rack", RACK_COUNT)
	assert_eq(int(panel.call(&"selected_rack")), -1, "an ordinal past the bays marks none")
	assert_false(
		bool((panel.call(&"bay_marks", RACK_COUNT - 1) as Node).call(&"is_selected")),
		"so B5's frame is gone too"
	)


## ------------------------------------------- AC1's pane half: the full battery refuses

## A drop zone whose battery already holds four cells refuses the fifth through the pane's
## own preview and its writing half, with the pinned `W SLOTS FULL` wording, and the
## record, the fit and the bag are byte-identical afterwards. The cell the drag would land
## in (W5) is deliberately **empty** and the bag holds an instance, so the battery's own
## cap is the only thing that can refuse.
func test_a_drop_on_a_four_cell_battery_is_refused() -> void:
	var panel := _mount()
	var hull: StringName = &"ship_destroyer"
	_profile.set(&"_active_ship", hull)
	var owned: Array[StringName] = [hull]
	_profile.set(&"_owned_ships", owned)
	var fit: Dictionary = FitData.standard_fit(hull)
	var weapons: Array = []
	for index in FitData.slot_capacity(hull, &"weapons"):
		weapons.append("" if index == 4 else ("w_laser" if index % 2 == 0 else "w_cannon"))
	fit[&"weapons"] = weapons
	assert_true(bool(_profile.call(&"set_fit", hull, fit)), "the capital's fit installs")
	_profile.call(&"add_module", &"w_laser", 1)
	assert_true(
		bool(_profile.call(&"set_battery_groups", hull, [[0, 1, 2, 3], [5]])),
		"B1 filled to its four cells"
	)
	panel.call(&"refresh_profile", &"batteries")
	assert_eq(panel.call(&"rack_rows")[0][&"cells"], [0, 1, 2, 3], "the bay draws B1's four cells")
	var before: Dictionary = {
		&"record": _profile.call(&"batteries"),
		&"fit": _profile.call(&"fit_for", hull),
		&"bag": _profile.call(&"modules"),
	}
	var payload: Variant = panel.call(&"drag_inventory", &"w_laser")
	assert_false(
		bool(panel.call(&"can_drop", 0, PanelScript.DROP_RACK_BODY, payload)),
		"the preview refuses the fifth cell"
	)
	assert_false(
		bool(panel.call(&"drop", 0, PanelScript.DROP_RACK_BODY, payload)), "and so does the drop"
	)
	## The 9 px refusals row is not the pane's to print: the footer line is the S5 literal.
	assert_eq(
		_last_status(), PanelScript.REFUSAL_W_SLOTS_FULL, "the pinned wording, byte for byte"
	)
	assert_eq(
		{
			&"record": _profile.call(&"batteries"),
			&"fit": _profile.call(&"fit_for", hull),
			&"bag": _profile.call(&"modules"),
		},
		before,
		"and the refused drop wrote nothing"
	)
	## A battery with room still takes the same drop: the refusal is the four-cell cap, not
	## the drag itself (B2 holds one cell, and the drag would land in W5).
	assert_eq(panel.call(&"rack_rows")[1][&"cells"], [5], "B2 holds one cell")
	assert_true(
		bool(panel.call(&"can_drop", 1, PanelScript.DROP_RACK_BODY, payload)),
		"the same drag is accepted where the battery has room"
	)
	assert_true(
		bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, payload)),
		"and it installs there"
	)
	assert_eq(
		_profile.call(&"battery_groups", hull), [[0, 1, 2, 3], [5, 4], [6]],
		"the fifth cell lands in B2, inside the cap"
	)
