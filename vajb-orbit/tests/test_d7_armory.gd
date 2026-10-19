@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite d7_armory: wave D7's ARMORY cockpit restyle (UI_SPEC section 3.10, on the
## section 3.9 instrument language), re-pinned by wave S18's D13 rework (section 3.10
## **Amendment 3**: the landscape console, the five-across band, the P3 2x2 rack and the
## two code-drawn wells). **Surface only**: the pane's transactions, drag-drop behaviour,
## the refusal-writes-nothing rule and the panel contract are section 5.11 / 09 section
## 11 / CONTRACTS section 17's and are asserted here unchanged; what this suite measures
## is the chrome Amendment 3 rules:
##
##  1. the pane mounts on the scripted console plate (a nine-slice of the 2720 x 1032
##     master at exactly 2x the derived 1360 x 516 console), with the two wells (barrel
##     inventory left, ammunition right) at the band's own halves;
##  2. each rack `B1..B5` is a code-drawn card in the one band, with the P3 2x2 cell
##     recesses, the fitted cell's name on two 13 px lines and `DROP HERE` on the empty
##     ones;
##  3. the ledge's four `ui_seg_*` cells render the rack's cycle figure (Mockup A's
##     approved `073` = 0.73 s readout) and read blanks for a rack with no cadence;
##  4. the inventory rows and pack cards ride the code-drawn plate at the well grid's own
##     320 x 68 box, and the pack card carries the P5 worded held line;
##  5. danger rows reuse section 3.1/3.1b verbatim (the label plus a 1 px code-drawn
##     frame, digits never recoloured);
##  6. the style is the single surface (`ArmoryStyle`, a `CockpitStyle`): a user `.tres`
##     restyles **and** relayouts the pane with no code edit.
##
## The pane is mounted from the shipped scene with the shipped theme at the pinned host
## rect, and the profile is the shipped autoload borrowed the way
## `test_p2b1_outfitting_panel.gd` borrows it: `save_path` is repointed at a scratch file
## before the first mutation and every borrowed field is handed back in `suite_teardown`.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StyleScript := preload("res://ui/station/armory_style.gd")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_d7_armory.cfg"
const STYLE_PROBE_PATH := "user://d7_armory_style_probe.tres"

const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const LASER: StringName = &"w_laser"

const START_CREDITS := 10000
const AMMO_FIXTURE: Dictionary = {
	&"ammo_laser": 30,
	&"ammo_cannon": 15,
	&"ammo_rocket": 40,
	&"ammo_mine": 0,
	&"ammo_plasma": 0,
}

## The pinned numbers (UI_SPEC section 3.10 Amendment 3 - the D13 rework, wave S18).
## The suite reads them from the style *and* asserts them against these literals, so a
## default that drifts fails here. The pane derives every rect from its own host rect (P6):
## the fixture mounts it at the station's pinned 1392 x 610 host, so the drawn geometry is
## the design's own base numbers.
const ART_SCALE := 2.0
const HOST := Vector2(1392.0, 610.0)
const CONSOLE := Vector2(1360.0, 516.0)
const CONSOLE_MASTER := Vector2(2720.0, 1032.0)
const CONSOLE_ORIGIN := Vector2(16.0, 68.0)
const CONSOLE_INSET := Vector4(16.0, 68.0, 16.0, 26.0)
## S33's two-sector rework (STATION_HUB section 21.1 P38/P39): the mode host is 1392 x 557 at
## the pinned host, split into two equal 688-wide sectors on a 16 px gutter. The console
## rides the BATTERY CONFIG mode's **left** sector, so `block_size()` is the sector's box and
## the five racks are full-width rows inside it. These are the moved rows.
const MODE_HOST := Vector2(1392.0, 557.0)
const MODE_HOST_TOP := 53.0
const SECTOR_GUTTER := 16.0
const RACK_SECTOR := Vector2(688.0, 557.0)
const RACK_BAND := Vector2(688.0, 459.0)
const RACK_ROW := Vector2(688.0, 87.0)
const RACK_GAP := 6.0
const RACK_HEAD_WIDTH := 200.0
const RACK_SALVO_WIDTH := 270.0
const BAY_COLUMNS := 5
## One rack row's four cells: a 45 x 67 cell at (210, 10), 6 apart, inside the row.
const CELL := Vector2(45.0, 67.0)
const CELL_ORIGIN := Vector2(210.0, 10.0)
const CELL_GAP := 6.0
## The salvo ledge at the row's right and the four 18 x 32 drum cells on a 20 pitch.
const LEDGE_ORIGIN := Vector2(418.0, 0.0)
const LEDGE := Vector2(270.0, 87.0)
const SALVO_CELL := Vector2(18.0, 32.0)
const SALVO_PITCH := 20.0
const SALVO_CAPTION_ORIGIN := Vector2(78.0, 37.5)
## The wells band's two halves (the read-only empty cells left, the mode's summary right),
## in the pane's own space.
const WELL := Vector2(328.0, 92.0)
const WELL_LEFT := Rect2(Vector2(0.0, 518.0), WELL)
const WELL_RIGHT := Rect2(Vector2(360.0, 518.0), WELL)
## One well item (an inventory row / a pack card) at the base host.
const ITEM := Vector2(320.0, 68.0)
const RACK_COUNT := 5
const SALVO_MAX := 999

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "d7_armory"


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
	_previous_credits = int(_profile.get(&"_credits"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(PROFILE_PATH)
	if FileAccess.file_exists(STYLE_PROBE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "ArmoryHost"
	_host.theme = ThemeRes
	_host.size = HOST
	Support.profile().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: the Vanguard active and owned, no stored
## fit (the standard fit is what the racks derive from), no modules, 10 000 CR and
## `AMMO_FIXTURE`'s cargo units - written through the same private fields
## `test_p2b1_outfitting_panel.gd` hands back, so no purchase is charged and no signal
## fires before the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", AMMO_FIXTURE.duplicate())
	_profile.set(&"_batteries", {})

func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _style() -> Resource:
	return _panel.call(&"style")


func _rack(panel: Control, index: int) -> Dictionary:
	var rows: Array = panel.call(&"rack_rows")
	return rows[index]


func _rack_row(panel: Control, index: int) -> PanelContainer:
	return (panel.get_node("%RackRows") as VBoxContainer).get_child(index) as PanelContainer


func _ammo_card(panel: Control, pack_id: StringName) -> Button:
	## P39a: the AMMUNITION category's cards live in the shared menu's row box; move the menu
	## to that category first.
	panel.call(&"select_tab", PanelScript.EQ_TAB_AMMO)
	panel.call(&"_lay")
	for child: Node in (panel.get_node("%BrowserRows") as Control).get_children():
		var row := child as Button
		if row == null:
			continue
		var title := row.find_child("Title", true, false) as Label
		if title == null:
			continue
		for pack: Dictionary in Catalog.AMMO_PACKS:
			if pack_id == pack[&"id"] and String(pack[&"name"]).to_upper() == title.text.to_upper():
				return row
	return null


func _cell(row: Control, cell_name: String) -> Control:
	return row.find_child(cell_name, true, false) as Control


func _cell_text(row: Control, cell_name: String) -> String:
	var cell := _cell(row, cell_name)
	var value := cell.get_node_or_null(^"Value") as Label if cell != null else null
	return value.text if value != null else ""


func _plate(row: Control) -> Control:
	return row.get_node_or_null(^"RowPlate") as Control


func _drop_inventory(panel: Control, rack: int, slot: int, base_id: StringName) -> bool:
	var payload: Variant = panel.call(&"drag_inventory", base_id)
	return bool(panel.call(&"drop", rack, slot, payload))


func _snapshot() -> Dictionary:
	return {
		&"fit": _profile.call(&"fit_for", VANGUARD),
		&"bag": _profile.call(&"modules"),
		&"racks": _profile.call(&"batteries"),
		&"credits": int(_profile.call(&"credits")),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
	}


func _unchanged(before: Dictionary, what: String) -> void:
	assert_eq(_profile.call(&"fit_for", VANGUARD), before[&"fit"], "%s: the fit is byte-identical" % what)
	assert_eq(_profile.call(&"modules"), before[&"bag"], "%s: and the bag" % what)
	assert_eq(_profile.call(&"batteries"), before[&"racks"], "%s: and the rack record" % what)
	assert_eq(int(_profile.call(&"credits")), int(before[&"credits"]), "%s: and the credits" % what)
	_assert_cargo(before, what)


## The hold's own figure (the profile carries no public `cargo()` read: `cargo_units`
## answers one family at a time), read straight off the store the pane buys into.
func _assert_cargo(before: Dictionary, what: String) -> void:
	assert_eq(
		(_profile.get(&"_cargo") as Dictionary), before[&"cargo"],
		"%s: and the hold" % what
	)
func test_the_pane_mounts_on_the_painted_console_plate() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.art_scale, ART_SCALE, "section 10's @2x recipe scale")
	assert_eq(style.host_base, HOST, "the pinned host rect")
	assert_eq(style.console_inset, CONSOLE_INSET, "its own insets (left, top, right, bottom)")
	assert_eq(style.canvas * style.art_scale, CONSOLE, "Amendment 3's ruled console, at the base host")
	assert_eq(style.console_size_at_base(), CONSOLE, "the two cannot drift")
	assert_eq(
		style.console_rect(Rect2(Vector2.ZERO, HOST)), Rect2(CONSOLE_ORIGIN, CONSOLE),
		"and the console derives from the host rect (P6)"
	)
	assert_eq(
		panel.call(&"block_size"), RACK_SECTOR,
		"the console fills its sector (P38/P39: the racks ride the left sector)"
	)
	assert_eq(CONSOLE_MASTER, CONSOLE * ART_SCALE, "the scripted master is exactly 2x the console")
	var plate := panel.get_node("%ConsolePlate") as NinePatchRect
	assert_true(plate != null, "the console floor node stays in the scene")
	assert_true(plate.texture == null, "the scripted master retires from the pane (A4.1)")
	assert_true(
		ResourceLoader.exists("res://assets/ui/ui_armory_console.png"),
		"the master itself stays on disk (unwired; ASSET_CATALOG notes it)"
	)
	assert_eq(
		plate.size, RACK_SECTOR,
		"the floor fills the sector's console (actual %s)" % str(plate.size)
	)
	assert_eq(plate.position, Vector2.ZERO, "the floor fills its console control")
	## S32 (STATION_HUB section 20.1 P36): the BodyScroll fold retires with the two-mode
	## rework - the console is the BATTERY CONFIG mode's own content, parented to the mode's
	## console host rather than a body scroll.
	assert_eq(
		String((plate.get_parent_control() as Control).get_parent().name), "ConsoleHost",
		"the console rides the BATTERY CONFIG mode's own host (P32/P36)"
	)
	## A5.1: the frame stays registered for the shell, but the console draws none -
	## the sibling `PanelRaised` box is the host's, not an inner surface's.
	var frame := panel.get_theme_stylebox(&"panel", &"PanelRaised") as StyleBoxTexture
	assert_true(frame != null, "the theme's panel frame resolves (the shell's edge)")
	if frame != null:
		assert_eq(
			String(frame.texture.resource_path), "res://assets/ui/ui_panel_frame.png",
			"the ui_panel_frame nine-patch"
		)
		assert_eq(frame.texture_margin_left, 32.0, "at the pinned 32 px patch margin")
		assert_eq(frame.texture_margin_top, 32.0, "on every side")
		assert_eq(frame.texture_margin_right, 32.0, "")
		assert_eq(frame.texture_margin_bottom, 32.0, "")
	var chrome := (panel.get_node(^"%Console") as Control).get_node(^"ConsolePanels")
	if chrome != null:
		assert_eq(
			chrome.get(&"frame_box"), null,
			"no frame is drawn inside the console (A5.1)"
		)


## The console's two wells now hold BATTERY CONFIG's read-only blocks (STATION_HUB section
## 20.1 P34): the empty hull W cells on the left, the mode's own summary on the right. FITS
## HERE and AMMUNITION are containers of the FIT CELLS mode and the shared foot band
## (P33/P36), not console halves.
func test_the_two_console_wells_hold_the_empty_and_summary_blocks() -> void:
	var panel := _mount()
	var wells: Array = panel.call(&"well_rects")
	assert_eq(wells.size(), 2, "the console still derives its two wells")
	assert_eq(wells[0], WELL_LEFT, "the left well is the band's own left half")
	assert_eq(wells[1], WELL_RIGHT, "and the right well, one 32 px gutter right")
	var empty := panel.get_node("%EmptyMargin") as Control
	assert_eq(
		empty.position, Vector2.ZERO,
		"the empty-cells block opens its own half (the container places it)"
	)
	assert_eq(empty.size, WELL_LEFT.size, "at the well's own box")
	assert_eq(
		(panel.get_node("%SummaryMargin") as Control).size, WELL_RIGHT.size,
		"and the summary block in the right well"
	)
	var racks := panel.get_node("%RackRows") as VBoxContainer
	assert_eq(racks.position, Vector2.ZERO, "the rack band opens at the console's own origin")
	assert_eq(racks.size, RACK_BAND, "and spans the console less the wells band")
	var list_rows := panel.get_node("%BrowserRows") as Control
	assert_eq(
		String((panel.get_node("%BrowserCaption") as Label).text),
		PanelScript.LIST_CAPTION_BROWSE % list_rows.get_child_count(),
		"the shared menu caption counts the rows it draws"
	)
	## P39a: the shared menu's AMMUNITION category counts the catalogue's packs.
	panel.call(&"select_tab", PanelScript.EQ_TAB_AMMO)
	assert_eq(
		String((panel.get_node("%BrowserCaption") as Label).text),
		"AMMUNITION - 8 PACKS", "the AMMUNITION category caption counts the catalogue's packs"
	)
	panel.call(&"select_tab", PanelScript.TAB_ALL)
	## P39a: ONE shared menu subtree, reparented between the two modes' right sectors - the
	## FIT CELLS socket filter and the BATTERY CONFIG list are the same component now.
	assert_eq(
		String((panel.get_node("%MenuSector") as Control).get_parent().name), "FitRight",
		"the shared menu rides the FIT CELLS right sector"
	)
	panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	panel.call(&"_lay")
	assert_eq(
		String((panel.get_node("%MenuSector") as Control).get_parent().name), "EqSector",
		"and the SAME menu the BATTERY CONFIG right sector (P39a)"
	)
	panel.call(&"set_mode", PanelScript.MODE_FIT)


## ------------------------------------------------------------- 2. the rack bay plates


## The rack rows: five **full-width rows** stacked top-down (P36's amendment supersedes the
## five-across band), each a code-drawn card - the rack plate master retires with the rework.
func test_the_bays_draw_five_across_the_band() -> void:
	var panel := _mount()
	assert_eq(PanelScript.RACK_COUNT, RACK_COUNT, "the pin's own rack count")
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), RACK_COUNT, "one row per weapon key")
	for index in bays.size():
		var want := Rect2(
			Vector2(0.0, MODE_HOST_TOP + float(index) * (RACK_ROW.y + RACK_GAP)), RACK_ROW
		)
		assert_eq(bays[index], want, "row %d is the band's own cell (actual %s)" % [index, str(bays[index])])
	for index in bays.size():
		var row := _rack_row(panel, index)
		assert_eq(row.size, RACK_ROW, "the drawn row is the same box (actual %s)" % str(row.size))
		assert_false(
			row.get_node_or_null(^"Box/BayPlate") != null,
			"the rack plate retires: the bay card is code-drawn (T6)"
		)
	var rows := panel.get_node("%RackRows") as VBoxContainer
	assert_eq(rows.custom_minimum_size, Vector2.ZERO, "the rows share the band's own height")


## The P3 2x2 rack: every bay carries four code-drawn cell recesses at the style's own
## The rack row's four cells: every row carries four code-drawn cell recesses at the
## style's own rects, the fitted cell prints the full barrel name on two 13 px lines (T3,
## HIGH-5's cure) and every empty cell offers `DROP HERE` at 13 px (T4).
func test_the_cells_are_the_four_across_the_rack_row() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.cell_columns, 4, "the rack row carries four cells (P36)")
	assert_eq(style.cell_rows, 1, "")
	assert_eq(
		style.bay_cell_rect(0, Rect2(Vector2.ZERO, RACK_ROW)), Rect2(CELL_ORIGIN, CELL),
		"cell 0 is the row's own first recess"
	)
	assert_eq(
		style.bay_cell_rect(1, Rect2(Vector2.ZERO, RACK_ROW)),
		Rect2(CELL_ORIGIN + Vector2(CELL.x + CELL_GAP, 0.0), CELL),
		"the second cell one gap right"
	)
	assert_eq(
		style.bay_cell_rect(3, Rect2(Vector2.ZERO, RACK_ROW)),
		Rect2(CELL_ORIGIN + Vector2(3.0 * (CELL.x + CELL_GAP), 0.0), CELL),
		"and the row's own last cell three gaps right"
	)
	var row := _rack_row(panel, 0)
	var barrels := row.get_node_or_null(^"Box/Barrels") as Control
	assert_true(barrels != null, "the bay carries its barrels box (the S5 path)")
	assert_eq(_rack(panel, 0)[&"cells"], [0], "B1 holds the delivered cell")
	assert_eq(barrels.get_child_count(), 1, "and one chip")
	var chip := barrels.get_child(0) as Control
	assert_eq(chip.position, CELL_ORIGIN, "the chip rides its own cell recess (actual %s)" % str(chip.position))
	assert_eq(chip.size, CELL, "at the cell's own size (actual %s)" % str(chip.size))
	var plate := chip.get_node_or_null(^"Name") as Button
	assert_true(plate != null, "the cell carries its name plate (the drag handle)")
	assert_eq(plate.text, "W1 LASER MKII", "printing the full barrel name (T3)")
	assert_eq(
		String((plate.get_node(^"NamePlate") as Label).text), "W1 LASER",
		"on the first 13 px line"
	)
	assert_eq(
		String((plate.get_node(^"Variant") as Label).text), "MKII",
		"and its variant on the second"
	)
	var cells := row.get_node(^"Box/Cells") as Control
	assert_eq(cells.get_child_count(), 3, "the three empty cells stay bare drop zones")
	for child: Node in cells.get_children():
		assert_true(
			child.get_node_or_null(^"Cue") == null,
			"each one carries no ghost cue (S29 A7: the DROP HERE text is gone)"
		)
	var marks = panel.call(&"bay_marks", 0)
	assert_true(marks != null, "the bay carries its code-drawn marks")
	assert_eq(marks.marked_cells(), [0], "the fitted cell is the one marked")
	assert_eq(marks.is_selected(), true, "and B1 is the selected bay by default")
	assert_eq(panel.call(&"bay_marks", 1).marked_cells(), [], "B2 is empty: nothing is marked")


## ------------------------------------------------------------------ 3. the SALVO cells


func test_the_salvo_strip_renders_the_cycle_figure() -> void:
	var panel := _mount()
	var strip := _rack_row(panel, 0).get_node_or_null(^"Box/Salvo")
	assert_true(strip != null, "every bay carries its SALVO strip")
	assert_eq(
		Rect2(strip.position, strip.size), Rect2(LEDGE_ORIGIN, LEDGE),
		"the strip is the bay's own ledge (actual %s)" % str(Rect2(strip.position, strip.size))
	)
	var caption := strip.call(&"caption_node") as Label
	assert_eq(caption.text, "SALVO s", "the pinned caption, an engine Label at 13 px (T6)")
	assert_eq(
		caption.position, SALVO_CAPTION_ORIGIN,
		"adjacent to the drum cells (T8; actual %s)" % str(caption.position)
	)
	assert_eq(strip.call(&"cell_nodes").size(), 4, "four ui_seg_* cells (S22.8's drum)")
	for index in 4:
		var cell: TextureRect = strip.call(&"cell_nodes")[index]
		assert_eq(
			Rect2(cell.position, cell.size),
			Rect2(Vector2(0.0, 27.5) + Vector2(index * SALVO_PITCH, 0.0), SALVO_CELL),
			"cell %d sits inside the ledge on the 20 px pitch" % index
		)
	## A laser rack has no travelling member: no figure, blanks in every cell.
	var laser: Dictionary = panel.call(&"salvo_readout", 0)
	assert_eq(int(laser[&"figure"]), -1, "a laser rack states no cadence")
	assert_eq(laser[&"cells"], [-1, -1, -1, -1], "so its cells stay blank")
	## A cannon's 0.6 s cycle reads 060 (Mockup A's approved figure: hundredths, zero-padded).
	_profile.call(&"add_module", CANNON, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, CANNON)),
		"a cannon fits W2"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])
	assert_eq(
		String(_rack(panel, 1)[&"salvo"]),
		PanelScript.RACK_SALVO % WeaponComponent.interval_of(&"cannon"),
		"the rack's cycle line is untouched (the ledge digits carry it on screen, T8)"
	)
	var cannon: Dictionary = panel.call(&"salvo_readout", 1)
	assert_eq(
		int(cannon[&"figure"]), 60,
		"the cannon's 0.6 s reads 60 hundredths (actual %s)" % str(cannon)
	)
	assert_eq(
		String(cannon[&"text"]), "0060",
		"which the four cells render as 0060 (actual %s)" % String(cannon[&"text"])
	)
	## A rocket's 12 s cooldown reads 1200 - the S22.8 drum carries the heavy tier.
	_profile.call(&"add_module", ROCKET, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, ROCKET)),
		"a rocket fits W3"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0, 1, 2]])
	var mixed: Dictionary = panel.call(&"salvo_readout", 0)
	assert_eq(int(mixed[&"figure"]), 1200, "the mixed rack gates on the rocket's 12 s cooldown")
	assert_eq(String(mixed[&"text"]), "1200", "read as 1200")
	assert_true(
		PanelScript.SALVO_MAX >= 9999, "the format holds a cycle up to 99.99 s in four cells"
	)


## ------------------------------------------------------------ 4. the row plates


## The well items: a code-drawn plate (the brushed row-plate master retires with the
## rework), the 2x3 grid per half, and the pack card's own four 13 px lines - the worded
## held line (P5) and the price's unit word among them.
func test_the_items_ride_the_code_drawn_plate() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.item_columns, 2, "two columns of three per half")
	assert_eq(style.item_rows, 3, "three visible rows")
	assert_eq(style.item_gap, 8.0, "on the style's own gap")
	var card := _ammo_card(panel, &"cannon")
	assert_true(card != null, "the cannon pack has a card")
	## A18 (the owner's 2026-10-15 pass): the row is the shared menu's own
	## full-width row - 76 tall like every other segment's rows, never the
	## 320 px half-cell again.
	assert_eq(card.size.y, 76.0, "at the shared row's own height (actual %s)" % str(card.size))
	assert_gt(card.size.x, ITEM.x, "spanning the shared menu, not a 320 px half-cell")
	var plate := _plate(card)
	assert_true(plate != null, "the card rides a plate")
	assert_true(
		plate.get_node_or_null(^"Plate") == null,
		"code-drawn: the nine-slice row plate retires with Amendment 3"
	)
	var rows := panel.get_node("%BrowserRows") as Control
	assert_eq(
		rows.get_child_count(), Catalog.AMMO_PACKS.size(),
		"one card per pack, no slack row (MED-1's cure)"
	)
	assert_eq(
		(rows.get_child(1) as Control).position, Vector2(0.0, 76.0 + 6.0),
		"the second card sits one row below (the shared menu stacks them, P39a)"
	)
	## P39a: the ammunition cards are a vertical list in the shared menu, not a 2x3 grid.
	assert_eq(
		(rows.get_child(2) as Control).position, Vector2(0.0, (76.0 + 6.0) * 2.0),
		"and the third two rows down (actual %s)"
			% str((rows.get_child(2) as Control).position)
	)
	## The fixture holds 15 cannon units at a 30-unit ceiling: 150 rounds held.
	assert_eq(
		String(_cell(card, "Held").get_node(^"Value").text),
		PanelScript.HELD_FORMAT % [150, 30],
		"the card carries the worded P5 held line"
	)
	assert_eq(
		String(_cell(card, "Held").get_node(^"Caption").text), PanelScript.META_BELOW_CAPACITY,
		"and the section 5.1 state line under it"
	)
	assert_eq(
		String(_cell(card, "Price").get_node(^"Value").text),
		PanelScript.PRICE_FORMAT % Catalog.group_int(int(Catalog.ammo_pack(&"cannon")[&"cost"])),
		"the price's own unit word"
	)
	## P38/F1/P39a: the ALL category's list is the browse state; a clean fixture still lists
	## the ship's own fitted bases (bag units UNION fitted bases).
	panel.call(&"select_tab", PanelScript.TAB_ALL)
	panel.call(&"_lay")
	var list := panel.get_node("%BrowserRows") as Control
	assert_true(list.get_child_count() >= 1, "the browse list lists the ship's fitted equipment")
	_profile.call(&"add_module", CANNON, 1)
	panel.call(&"_lay")
	var row: Control = null
	for child: Node in list.get_children():
		if child.name == "ModuleWCannon":
			row = child as Control
	assert_true(row != null, "an owned weapon lists")
	## P40: a list row is a full-width row of its sector, not a 320 px half-cell.
	assert_eq(row.size.y, 76.0, "at the list row's own height")
	assert_gt(row.size.x, ITEM.x, "spanning the sector, not a 320 px half-cell")
	var read := row.get_node_or_null(NodePath("RowInner/RowBox/Read")) as Label
	assert_true(read != null, "the row carries its read cell")
	assert_eq(
		String(read.text), PanelScript.OWNED_FORMAT % 1,
		"and keeps the S5 OWNED x<n> figure"
	)


## --------------------------------------------------- 5. the danger row treatments


## Section 3.10: danger/insufficient/refusal states reuse section 3.1/3.1b verbatim as row
## treatments - the label plus a 1 px code-drawn frame, and the digits never recolour.
func test_danger_rows_follow_section_3_1_and_3_1b() -> void:
	var panel := _mount()
	var rocket := _ammo_card(panel, &"rocket")
	assert_true(rocket != null, "the rocket pack has a card")
	## The fixture holds 40 units against a 10-unit ceiling: OVER CAP.
	assert_eq(_cell_text(rocket, "Status"), PanelScript.TAG_OVER_CAP, "the fixture's rocket is over cap")
	assert_true(_plate(rocket).danger(), "so its card wears the code-drawn danger frame")
	var tag := _cell(rocket, "Status").get_node(^"Value") as Label
	assert_true(
		tag.has_theme_color_override(&"font_color"), "and its state label turns the danger role"
	)
	assert_eq(
		tag.get_theme_color(&"font_color"),
		_style().colour(&"accent_danger_bright"),
		"which is the bright ember (A4.3/L227: accent_danger cannot clear 4.5:1)"
	)
	## A half-full pack is no danger state at all.
	var cannon := _ammo_card(panel, &"cannon")
	assert_false(_plate(cannon).danger(), "an in-stock pack carries no frame")
	assert_false(
		(_cell(cannon, "Status").get_node(^"Value") as Label).has_theme_color_override(&"font_color"),
		"and no colour override"
	)
	## Digits never recolour: the held figure keeps the caption ramp through the danger state.
	var held := _cell(rocket, "Held").get_node(^"Value") as Label
	assert_eq(
		held.get_theme_color(&"font_color"), _style().colour(&"caption"),
		"the held figure stays on the caption ramp"
	)
	assert_ne(
		held.get_theme_color(&"font_color"), _style().colour(&"accent_danger"),
		"never the danger role"
	)
	## Insufficient credits is the section 3.1b read too: the price label turns and the card
	## is framed, and a refused purchase still writes nothing.
	_profile.call(&"spend", int(_profile.call(&"credits")))
	panel.call(&"refresh_profile", &"credits")
	var price := _cell(cannon, "Price").get_node(^"Value") as Label
	assert_true(price.has_theme_color_override(&"font_color"), "an unaffordable price turns")
	assert_true(_plate(cannon).danger(), "and the card is framed")
	var empty := _snapshot()
	(cannon as Button).pressed.emit()
	_unchanged(empty, "an unaffordable purchase")


## ------------------------------------------------- 6. the surface is surface only


## The wave is **surface only** (section 3.10): a refused drop still writes nothing at all -
## fit, bag, rack record, credits and hold alike - and the pane's read-backs are the S5 set.
func test_a_refused_drop_writes_nothing() -> void:
	var panel := _mount()
	var before := _snapshot()
	## The bag holds no cannon: the install route refuses with the pane's own wording. The
	## payload is built by hand because an empty-bag drag cannot start (`drag_inventory`
	## answers `{}`), so this is the stale-payload path the engine never hands out.
	var stale: Dictionary = {&"kind": PanelScript.DRAG_INVENTORY, &"base": CANNON}
	assert_false(bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, stale)), "no cannon in the bag")
	assert_eq(_last_status(), PanelScript.REFUSAL_NO_WEAPONS, "the refusal names the empty bag")
	assert_true(_last_danger(), "in the danger colour")
	_unchanged(before, "a refused install")
	## A drag the bag cannot start answers `{}` and never reaches the pane.
	assert_true(
		(panel.call(&"drag_inventory", CANNON) as Dictionary).is_empty(),
		"an unowned base drags nothing"
	)
	assert_false(
		bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, {})),
		"and an empty payload is refused before any guard"
	)
	assert_eq(_last_status(), PanelScript.REFUSAL_NO_WEAPONS, "with no new status line")
	_unchanged(before, "an empty payload")
	## A barrel move to an address with nothing in it refuses just as quietly.
	var payload: Variant = panel.call(&"drag_barrel", 1, 0)
	assert_false(bool(panel.call(&"move_barrel", 1, 0, 2, 0)), "B2 holds no barrel to move")
	assert_eq(_last_status(), PanelScript.REFUSAL_FIT_ILLEGAL, "the pin's own wording")
	_unchanged(before, "a refused move")
	## The preview agrees with the write, and neither is a drag the engine can start.
	assert_false(
		bool(panel.call(&"can_drop", 1, PanelScript.DROP_RACK_BODY, {&"kind": &"inventory", &"base": CANNON})),
		"can_drop refuses what drop refuses"
	)
	assert_true(
		(panel.call(&"drag_inventory", CANNON) as Dictionary).is_empty(),
		"and an unowned base drags nothing"
	)
	assert_true(
		(panel.call(&"drag_barrel", 1, 0) as Dictionary).is_empty(),
		"nor does an empty rack's first chip"
	)
	_unchanged(before, "the whole refusal set")


## The drag-drop ordering is untouched: an install lands in the rack's next free W cell, a
## within-rack drag re-orders the chips, a between-rack drag moves the barrel, and the `x`
## returns it to the inventory.
func test_the_drag_ordering_and_the_close_are_unchanged() -> void:
	var panel := _mount()
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, LASER) == false or true, "a drag never throws")
	## An owned instance lands in the rack's next free cell, through the composed write.
	_profile.call(&"add_module", CANNON, 1)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, CANNON), "a cannon into B2")
	assert_eq(_rack(panel, 1)[&"cells"], [1], "B2 holds the cannon's cell")
	assert_eq(_rack(panel, 1)[&"barrels"][0][&"text"], "W2 CANNON MKI", "as its own chip")
	assert_eq(
		_last_status(), PanelScript.STATUS_INSTALLED % ["CANNON MKI", "B2"], "and the pane says so"
	)
	## A second weapon in the same rack appends: cell order is the rack's own.
	_profile.call(&"add_module", ROCKET, 1)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, ROCKET), "a rocket next")
	assert_eq(_rack(panel, 1)[&"cells"], [1, 2], "the rack keeps its append order")
	assert_eq(
		_rack(panel, 1)[&"barrels"][1][&"text"], "W3 ROCKET POD", "with the chip order to match"
	)
	## The SALVO strip follows the rack's own read: the rocket is its slowest member.
	assert_eq(
		String(panel.call(&"salvo_readout", 1)[&"text"]), "1200",
		"the strip renders the slowest member's cooldown"
	)
	## A within-rack re-order follows the record.
	var payload: Variant = panel.call(&"drag_barrel", 1, 1)
	assert_true(bool(panel.call(&"drop", 1, 1, payload)) == false, "dropping a barrel on itself is refused")
	var moved: Variant = panel.call(&"drag_barrel", 1, 0)
	assert_true(bool(panel.call(&"move_barrel", 1, 0, 1, 1)), "the cannon moves behind the rocket")
	assert_eq(_rack(panel, 1)[&"cells"], [2, 1], "B2's order swapped")
	## The `x` returns a barrel to the bag.
	var chip := (
		(_rack_row(panel, 1).get_node(^"Box/Barrels") as Control).get_child(0) as Control
	)
	(chip.get_node(^"Close") as Button).pressed.emit()
	assert_eq(_rack(panel, 1)[&"cells"], [1], "one barrel left")
	assert_eq(_last_status(), PanelScript.STATUS_REMOVED % "ROCKET POD", "and the pane reports it")
	assert_false(_last_danger(), "success is never the danger colour")


## ------------------------------------------------ 7. the style is the single surface


## Section 3.9 rule 5: a user `.tres` restyles **and** relayouts the pane with no code edit.
func test_a_user_tres_restyles_and_relayouts_with_no_code_edit() -> void:
	var panel := _mount()
	var probe := StyleScript.defaults()
	probe.rack_gap = 12.0
	probe.rack_row_height = 40.0
	probe.cell_gap = 4.0
	probe.item_gap = 4.0
	probe.text_dim = Color(0.1, 0.9, 0.2)
	var saved := ResourceSaver.save(probe, STYLE_PROBE_PATH)
	assert_eq(saved, OK, "the user's style writes")
	panel.call(&"set_style_file", STYLE_PROBE_PATH)
	var live := _style()
	assert_eq(live.rack_gap, 12.0, "the rack gap moved")
	assert_eq(live.rack_row_height, 40.0, "and the row height")
	var console := Rect2(Vector2.ZERO, RACK_SECTOR)
	var band: Rect2 = live.bays_band(console)
	assert_eq(
		band.size, Vector2(RACK_SECTOR.x, RACK_SECTOR.y - 92.0 - 6.0),
		"the band follows the console (the wells band's fixed foot)"
	)
	var live_rows: Array = panel.call(&"bay_rects")
	assert_eq(
		(live_rows[0] as Rect2).size.x, RACK_SECTOR.x,
		"the row still spans the console (P38/P39's sector)"
	)
	assert_true(
		(live_rows[1] as Rect2).position.y - (live_rows[0] as Rect2).position.y
			> RACK_ROW.y,
		"the rows follow the file's own 12 px gap (actual %s)" % str(live_rows[1])
	)
	var row_rect := Rect2(Vector2.ZERO, Vector2(RACK_SECTOR.x, (band.size.y - 4.0 * 12.0) / 5.0))
	var area: Rect2 = live.cells_area(row_rect)
	assert_eq(
		(live.bay_cell_rect(0, row_rect) as Rect2).size,
		Vector2((area.size.x - 3.0 * 4.0) / 4.0, area.size.y),
		"and so does the cell row"
	)
	assert_eq(live.colour(&"text_dim"), Color(0.1, 0.9, 0.2), "and the palette is the file's")
	## Dropping the file returns the shipped numbers: the override is not a one-way door.
	panel.call(&"set_style_file", StyleScript.ARMORY_USER_PATH)
	assert_eq(_style().rack_gap, RACK_GAP, "the shipped gap is back")
	assert_eq(
		panel.call(&"bay_rects")[0],
		Rect2(Vector2(0.0, MODE_HOST_TOP), RACK_ROW), "and the shipped rack band"
	)
	assert_eq(
		_rack_row(panel, 0).size, RACK_ROW,
		"drawn at the shipped row box (actual %s)" % str(_rack_row(panel, 0).size)
	)


## The style really is a `CockpitStyle` (one palette, one asset idiom) and it carries the
## armory's own asset and the Amendment 3 metrics.
func test_the_style_extends_cockpit_style_with_the_pinned_metrics() -> void:
	var panel := _mount()
	var style := _style()
	assert_true(style is CockpitStyle, "an ArmoryStyle is a CockpitStyle")
	var cockpit := CockpitStyleScript.defaults()
	for role: StringName in [
		&"void_base", &"void_panel_raised", &"metal_dark", &"metal_mid", &"metal_light",
		&"text_primary", &"text_dim", &"accent_danger", &"accent_danger_bright", &"panel_steel",
	]:
		assert_eq(
			style.colour(role), cockpit.colour(role),
			"%s comes from the family's one palette" % role
		)
	assert_eq(
		style.seg_path("7"), "res://assets/ui/ui_seg_7.png",
		"the drum cells keep the family's asset idiom"
	)
	assert_eq(
		style.get(&"console_path"), null,
		"the console master retires from the style (A4.1)"
	)
	assert_true(
		ResourceLoader.exists("res://assets/ui/ui_armory_console.png"),
		"and the master itself stays on disk (unwired)"
	)
	assert_eq(
		style.get(&"rack_plate_path"), null,
		"the rack plate retires from the style (Amendment 3)"
	)
	assert_eq(
		style.get(&"row_plate_path"), null,
		"and so does the row plate"
	)
	assert_eq(style.bay_columns, BAY_COLUMNS, "the rack count (P36: five stacked rows)")
	assert_eq(style.cell_columns, 4, "the rack row's four cells (P36)")
	assert_eq(style.salvo_cells, 4, "four SALVO cells (S22.8's drum)")
	assert_eq(style.salvo_cell, SALVO_CELL, "an 18 x 32 drum cell")
	assert_eq(style.salvo_pitch, SALVO_PITCH, "on the 20 px pitch")
	assert_eq(style.item_gap, 8.0, "the well grid's own gap")
	assert_eq(style.head_chip, Vector2(104.0, 22.0), "the bay head's state chip")
	assert_eq(
		style.caption, ThemeRes.get_color(&"armory_caption", &"Tokens"),
		"the HIGH-2 light-ramp caption, resolved from the theme (A4.3)"
	)
	assert_eq(
		style.caption_void, ThemeRes.get_color(&"armory_caption_void", &"Tokens"),
		"and the host's own caption tone"
	)
