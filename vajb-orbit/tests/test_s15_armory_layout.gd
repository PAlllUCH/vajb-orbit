extends McpTestSuite
## Suite s15_armory_layout: wave S15's ARMORY rework (09 section 12, STATION_HUB section
## 5.11) as wave S18's D13 rework re-derives it (UI_SPEC section 3.10 Amendment 3,
## owner-ticked 2026-09-25).
##
##  - **AC4** -- the pane draws five bays in ONE band, labelled `B1..B5`, each the band's
##    own 260 x 192 cell on the style's derivation from the host rect (P6), and every bay
##    carries the P3 2x2 rack - four 117 x 52 cell recesses inside the bay, the salvo ledge
##    at the foot with its three `ui_seg_*` drums, all at Amendment 3's own numbers. The
##    retired S15 4-in-a-row slot block (F1's ink-fit cure, superseded by P3) is measured
##    against the new rack as the "before".
##  - **AC5** -- armory rack i and cockpit lamp i are the same ordinal 1:1, the `(i)` key
##    selection lights lamp i, and the five lamps are the five bays.
##  - **AC1's pane half** -- a battery already holding four cells refuses the drop of a
##    fifth through the drop zone's own preview and the profile's transaction, and writes
##    nothing. (The record-level half is `tests/test_s15_battery_cap.gd`'s; the pane is
##    mounted here, so its refusal rides along.)
##
## The pane is mounted the way `tests/test_d7_armory.gd` mounts it (the shipped scene,
## the shipped theme, the profile borrowed and handed back), at the pinned 1392 x 610
## host so the derived geometry is the design's own base numbers; the cockpit's band the
## way `tests/test_d7_cockpit.gd` does.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const HudScene := preload("res://ui/hud/hud.tscn")
const FitData := preload("res://game/ship_fit.gd")
const WeaponData := preload("res://game/weapons.gd")

const CONSOLE_PATH := "res://assets/ui/ui_armory_console.png"
## The theme's own frame texture the pane's A4.1 chrome resolves to (S20).
const CONSOLE_PATH_THEME_FRAME := "res://assets/ui/ui_panel_frame.png"
const PROFILE_PATH := "user://test_s15_armory_layout.cfg"

## UI_SPEC section 3.10 Amendment 3's own numbers (the D13 rework, wave S18): the pinned
## host, the landscape console it derives, the scripted 2x master and the 2x2 rack.
const HOST := Vector2(1392.0, 610.0)
const CONSOLE_ORIGIN := Vector2(16.0, 68.0)
const CONSOLE := Vector2(1360.0, 516.0)
const CONSOLE_MASTER := Vector2(2720.0, 1032.0)
const ART_SCALE := 2.0
const BAND_ORIGIN := Vector2(16.0, 38.0)
const BAND := Vector2(1328.0, 192.0)
const BAY := Vector2(260.0, 192.0)
const BAY_GAP := 7.0
const CELL := Vector2(117.0, 52.0)
const CELL_ORIGIN := Vector2(10.0, 34.0)
const CELL_GAP := 6.0
const LEDGE_ORIGIN := Vector2(10.0, 150.0)
const LEDGE := Vector2(240.0, 34.0)
const SALVO_CELL := Vector2(18.0, 32.0)
const SALVO_PITCH := 20.0
## The retired S15 plate-fit block (finding F1's cure, superseded by P3): the 4-in-a-row
## W cells at the rack plate's own 34.5 drawn px pitch, 17 x 20 logical apiece. It is
## measured against the new 2x2 rack as the "before" the wave replaces.
const BEFORE_SLOT := Vector2(17.0, 20.0)
const BEFORE_SLOT_PITCH := 34.5
const RACK_COUNT := 5
const LAMP_COUNT := 5

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
	## The pinned host rect the pane derives every rect from (P6 / Amendment 3).
	_host.size = HOST
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


## ----------------------------------------------- AC4: the Amendment 3 console fit

## AC4's first half: the console is the host less its insets and the scripted master is
## exactly 2x it, so the nine-slice plate covers the whole rect at the base host - and
## every bay is the band's own cell on the style's own derivation (P6).
func test_the_console_and_the_bays_are_the_derived_geometry() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.art_scale, ART_SCALE, "section 10's @2x recipe")
	assert_eq(style.host_base, HOST, "the pinned host rect")
	assert_eq(style.canvas * ART_SCALE, CONSOLE, "the ruled console, at the base host")
	assert_eq(style.console_size_at_base(), CONSOLE, "the two cannot drift")
	assert_eq(
		style.console_rect(Rect2(Vector2.ZERO, HOST)), Rect2(CONSOLE_ORIGIN, CONSOLE),
		"and it derives from the host rect (P6)"
	)
	assert_eq(panel.call(&"block_size"), CONSOLE, "the pane draws that very console")
	## S20's A4.1 retires the scripted master from the pane: it still ships on disk (at the
	## pinned 2x size), but the plate's texture is cleared at build. **A5.1 (2026-09-26):**
	## the pane's one frame is the module host's own `PanelRaised` edge - the console draws
	## no inner frame (the 32 px band does not fit a 260x192 bay).
	var master: Vector2 = ResourceLoader.load(CONSOLE_PATH).get_size()
	assert_eq(master, CONSOLE_MASTER, "the scripted master still ships at 2x the console")
	var plate := panel.get_node("%ConsolePlate") as NinePatchRect
	assert_true(plate != null, "the console floor node stays in the scene")
	assert_true(plate.texture == null, "but the master is unwired from it (A4.1)")
	assert_eq(plate.size, CONSOLE, "drawn at the console rect (actual %s)" % str(plate.size))
	var frame := panel.get_theme_stylebox(&"panel", &"PanelRaised") as StyleBoxTexture
	assert_true(frame != null, "the theme's panel frame resolves (the shell's edge)")
	if frame != null:
		assert_eq(
			String(frame.texture.resource_path), CONSOLE_PATH_THEME_FRAME,
			"the ui_panel_frame nine-patch"
		)
		assert_eq(frame.texture_margin_left, 32.0, "at the pinned 32 px patch margin")
	var chrome := (panel.get_node(^"%Console") as Control).get_node(^"ConsolePanels")
	if chrome != null:
		assert_eq(chrome.get(&"frame_box"), null, "no frame is drawn inside the console (A5.1)")
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), RACK_COUNT, "five bays across the band")
	for index in bays.size():
		var want := Rect2(
			CONSOLE_ORIGIN + BAND_ORIGIN + Vector2(float(index) * (BAY.x + BAY_GAP), 0.0), BAY
		)
		assert_eq(bays[index], want, "bay %d is the band's own cell (actual %s)" % [index, str(bays[index])])
	## The P3 rack: four cells inside the bay, the ledge at the foot, the drums on it.
	var bay := Rect2(Vector2.ZERO, BAY)
	for index in 4:
		var cell: Rect2 = style.bay_cell_rect(index, bay)
		assert_true(bay.encloses(cell), "cell %d sits inside its bay (actual %s)" % [index, str(cell)])
		assert_eq(
			cell,
			Rect2(
				CELL_ORIGIN + Vector2(
					float(index % 2) * (CELL.x + CELL_GAP), float(index / 2) * (CELL.y + CELL_GAP)
				),
				CELL
			),
			"cell %d is the 2x2 rack's own recess" % index
		)
	var ledge: Rect2 = style.ledge_rect(bay)
	assert_eq(ledge, Rect2(LEDGE_ORIGIN, LEDGE), "the ledge is the bay's own foot band")
	for index in style.salvo_cells:
		var drum: Rect2 = style.salvo_cell_rect(index, ledge)
		assert_true(ledge.encloses(drum), "SALVO drum %d sits on the ledge" % index)
		assert_eq(
			drum, Rect2(LEDGE_ORIGIN + Vector2(float(index) * SALVO_PITCH, 1.0), SALVO_CELL),
			"drum %d on the ledge's own pitch" % index
		)
	## --- superseded: the retired S15 4-in-a-row block ---------
	## F1's cure was a 4-in-a-row slot row on the rack plate at the art's own 34.5 drawn
	## pitch; the P3 rack replaces it, so no drawn mark is the S15 block any more.
	assert_ne(BEFORE_SLOT, CELL, "the retired S15 slot is not the new cell")
	assert_ne(BEFORE_SLOT_PITCH, CELL.x + CELL_GAP, "nor is its pitch the new cell pitch")


## AC4's second half: the pane draws exactly five bays in ONE band (P3 supersedes S15's
## 4+1 flow), each the band's own cell, labelled `B1..B5` with the matching `(1)..(5)`
## key hints - and no sixth or seventh bay remains.
func test_the_pane_draws_five_bays_across_one_band() -> void:
	var panel := _mount()
	assert_eq(PanelScript.RACK_COUNT, RACK_COUNT, "the pane's rack count is the hardcap's five")
	assert_eq(RACK_COUNT, WeaponData.GROUPS_MAX, "and it is the input map's own number")
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), RACK_COUNT, "five bays, no more")
	var style := _style()
	assert_eq(style.bay_columns, 5, "the band's five columns")
	for index in bays.size():
		assert_eq(
			(bays[index] as Rect2).position.y, (bays[0] as Rect2).position.y,
			"bay %d rides the same band row as the first (actual %s)" % [index, str(bays[index])]
		)
		assert_eq(
			(bays[index] as Rect2).size, BAY,
			"bay %d is the band's own box (actual %s)" % [index, str(bays[index])]
		)
	var band: Rect2 = style.bays_band(Rect2(CONSOLE_ORIGIN, CONSOLE))
	assert_eq(band.size, BAND, "the band is the console less its side margins")
	var rack_rows := _panel.get_node("%RackRows") as VBoxContainer
	assert_eq(rack_rows.custom_minimum_size, BAND, "and the container fills it")
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
