@tool
extends McpTestSuite
## Suite p2b_services: the SHIPYARD's slot-layout hover line and LAUNCH's two station service
## rows - the two smaller deliverables of the P2-B proper wave (owner requests 1 and 4).
##
## STATION_HUB section 5.2's 2026-09-22 amendment gives the shipyard's slot plates the fitting
## surface's own line on hover, `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, resolved from
## the selected hull's `fit_for` entry and the account's `module_count`; section 5.4's amendment
## gives DECK CONTROL a `REFUEL` and a `RECHARGE` action for the active hull, calling
## `Repairs.refuel` / `Repairs.recharge` and rendering the service's own result. Both are
## measured here against the shipped scenes, the shipped theme and the shipped autoload, with
## every expectation derived from the document, the catalogue or `ShipFit` rather than from a
## literal this suite invents.
##
## The profile is the shipped autoload, borrowed the way `test_p2b_fitting_panel.gd` borrows it:
## `save_path` is repointed at a scratch file before the first mutation, the fields the fixture
## writes (credits, ships, fits, modules, vitals) are handed back in `suite_teardown`, and the
## store is flushed while the scratch path is still in place, so the owner's `user://profile.cfg`
## is never written (probe hygiene L17).

const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const RepairsService := preload("res://game/repairs.gd")

const PROFILE_PATH := "user://test_p2b_services.cfg"

## 08 section 3.2's default hull: `.WW.` / `HSCB` / `HWU.` / `.EP.`, so W1 is its only weapons
## cell that a fit reaches and W2 the empty one the hover line has to read `EMPTY` for.
const HULL: StringName = &"ship_vanguard"
const UNOWNED_HULL: StringName = &"ship_fighter"
const LASER: StringName = &"w_laser"
const STANDARD_REACTOR: StringName = &"p_std"
const OWNED_LASERS := 3

const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
const PLATE_ICON_INSET := 6.0
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const GLYPH_DIR := "res://assets/icons/slot/"
const GLYPH_TEMPLATE := "icon_slot_%s.svg"

## STATION_HUB section 5.2's own line and section 5.4's report form, transcribed here (not read
## off the panels) so a drift in either direction is a red assertion. The caption is the
## shipyard recipe's (section 5.2) and the amendment does not move it.
const WORDING_HOVER := "%s%d · %s · OWNED ×%d"
const WORDING_EMPTY := "EMPTY"
const WORDING_REPORT := "%s %d"
const WORDING_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"

var _profile: Node = null
var _host: Control = null
var _shipyard: Control = null
var _launch: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_vitals: Dictionary = {}


func suite_name() -> String:
	return "p2b_services"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to mount the panes")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the panes' store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_vitals = _profile.get(&"_vitals")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore the real
	## one, so no dirty flag and no running timer carries a test's account home.
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_vitals", _previous_vitals)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "ServicesHost"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)
	_shipyard = _mount(ShipyardScene)
	_launch = _mount(LaunchScene)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_shipyard = null
	_launch = null


## The fixture account: the Vanguard active and owned with its delivered standard fit, three
## lasers in the inventory, and no other hull owned - so the hover line has a fitted cell, an
## empty cell, a module the account holds and a hull it does not own, all three at once.
func _seed_account() -> void:
	var owned: Array[StringName] = [HULL]
	_profile.set(&"_credits", int(Catalog.ship(HULL).get(&"cost", 0)))
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_vitals", {})
	_profile.set(&"_modules", {String(LASER): {"base_id": String(LASER), "count": OWNED_LASERS}})
	_profile.call(&"set_fit", HULL, ShipFit.standard_fit(HULL))


## The runner calls every test from inside its own `_ready`, so the root viewport is still busy
## adding the runner scene and `root.add_child(...)` fails. The profile autoload entered the
## tree before the main scene, so it hosts the fixture (suite p2b_fitting_panel's own reason).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _viewport_size() -> Vector2:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(width, height)


## Mount a shipped pane the way the shell does: into a sized host, with the shell's two wirings
## (the pane's status line up, the profile's keys down).
func _mount(scene: PackedScene) -> Control:
	var panel := scene.instantiate() as Control
	_host.add_child(panel)
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	panel.connect(&"status_requested", _on_status)
	return panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


## ----------------------------------------------------------------------- shipyard readers


## One grid cell as `ShipFit.grid_cells` describes it - the same record the plate was built
## from, so the line is measured against the document's own cell shape.
func _cell(slot_key: StringName, index: int) -> Dictionary:
	for cell: Dictionary in ShipFit.grid_cells(_selected_hull()):
		if bool(cell[&"gap"]):
			continue
		if StringName(cell[&"type"]) == slot_key and int(cell[&"index"]) == index:
			return cell
	return {}


func _selected_hull() -> StringName:
	return StringName(_shipyard.get(&"_selected_id"))


## One cell of a fit in `fit_for`'s shape, read the way both panels read it: POWER is the one
## scalar slot type (CONTRACTS section 11 rule 1) and every other type is a layout-indexed cell
## array, `&""` for a cell the fit does not reach.
func _fit_cell(fit: Dictionary, slot_key: StringName, index: int) -> StringName:
	if slot_key == &"power":
		return StringName(str(fit.get(slot_key, "")))
	var raw: Variant = fit.get(slot_key, [])
	if not raw is Array:
		return &""
	var cells: Array = raw
	if index < 0 or index >= cells.size():
		return &""
	return StringName(str(cells[index]))


func _hover(cell: Dictionary) -> String:
	return String(_shipyard.call(&"hover_line", cell))


func _plate(token: String, index: int) -> Control:
	return _shipyard.get_node("%HardpointSlots").get_node_or_null(
		NodePath("Slot%s%02d" % [token, index])
	) as Control


## The row button of one hull in the hull list.
func _row(ship_id: StringName) -> Button:
	for child: Node in _shipyard.get_node("%ShipList").get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == ship_id:
			return row
	return null


## ------------------------------------------------------------------------- launch readers


func _strip() -> String:
	return (_launch.get_node("%ConfirmStrip") as Label).text


func _strip_danger() -> bool:
	var label := _launch.get_node("%ConfirmStrip") as Label
	return label.has_theme_color_override(&"font_color")


func _press(button: Button) -> void:
	assert_true(button != null, "the service button exists")
	if button != null:
		button.pressed.emit()


func _refuel_button() -> Button:
	return _launch.call(&"refuel_button") as Button


func _recharge_button() -> Button:
	return _launch.call(&"recharge_button") as Button


## ------------------------------------------------------------------------- profile readers


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _credits() -> int:
	return int(_profile.call(&"credits"))


func _owned() -> Array:
	return _profile.call(&"owned_ships")


func _module_name(module_id: StringName) -> String:
	return String(ModuleCatalog.module(module_id).get(&"name", "")).to_upper()


func _catalogue_name(service_id: StringName) -> String:
	return String(Catalog.service(service_id).get(&"name", String(service_id)))


func _fuel_of(ship_id: StringName) -> int:
	return int(_profile.call(&"vitals_of", ship_id).get(&"fuel", -1))


## File a report for the hull with an empty tank: `Repairs.refuel` fills the tank the report
## carries, so the tank has to be filed before the service can be asked to fill it.
func _file_report(fuel: int) -> void:
	var ship := Catalog.ship(HULL)
	_profile.call(
		&"set_vitals", HULL, int(ship.get(&"hull", 0)), int(ship.get(&"shield", 0)), fuel
	)


## 18 section 13's pool figures, derived here exactly the way `Repairs._pool_max` derives them
## (the hull's own stats with the standard fit's modules), so the expectation is the service's
## own arithmetic rather than a number this suite invents.
func _pool_max(energy: bool) -> int:
	var stats: ShipStats = ShipFit.resolve(HULL, ShipFit.STANDARD_FIT)
	assert_true(stats != null, "the fixture hull resolves into a stats snapshot")
	if stats == null:
		return 0
	return maxi(0, int(round(stats.energy_max if energy else stats.fuel_max)))


## ------------------------------------------------------------------------------- the line


func test_the_hover_line_reads_a_fitted_cell() -> void:
	assert_eq(_selected_hull(), HULL, "the default selection is the active hull")
	assert_eq(int(_profile.call(&"module_count", LASER)), OWNED_LASERS, "the fixture's stock")
	var fitted := _cell(&"weapons", 0)
	assert_false(fitted.is_empty(), "the Vanguard's W1 is a real cell")
	assert_eq(_hover(fitted), WORDING_HOVER % ["W", 1, _module_name(LASER), OWNED_LASERS])
	## The delivered fit is the standard one (09 section 7), so W1 holds the laser the account
	## also owns three of - the fitted module and the owned count are two different reads.
	var reactor := _cell(&"power", 0)
	assert_false(reactor.is_empty(), "the Vanguard's P1 is a real cell")
	assert_eq(
		_hover(reactor),
		WORDING_HOVER % ["P", 1, _module_name(STANDARD_REACTOR), int(_profile.call(&"module_count", STANDARD_REACTOR))],
		"POWER is one id, not a cell array, and the standard fit's reactor is not in the inventory"
	)


func test_the_hover_line_reads_an_empty_cell() -> void:
	var empty := _cell(&"weapons", 1)
	assert_false(empty.is_empty(), "the Vanguard's W2 is a real cell")
	assert_eq(_hover(empty), WORDING_HOVER % ["W", 2, WORDING_EMPTY, 0])


func test_the_hover_line_reads_a_hull_the_account_does_not_own() -> void:
	assert_false(_owned().has(UNOWNED_HULL), "the fixture owns the Vanguard alone")
	var row := _row(UNOWNED_HULL)
	assert_true(row != null, "the hull list has a row for it")
	row.grab_focus()
	assert_eq(_selected_hull(), UNOWNED_HULL, "the preview follows the row")
	assert_gt(ShipFit.grid_cells(UNOWNED_HULL).size(), 0, "the hull has a layout to read")
	for cell: Dictionary in ShipFit.grid_cells(UNOWNED_HULL):
		if bool(cell[&"gap"]):
			assert_eq(_hover(cell), "", "a gap carries no plate and no line")
			continue
		assert_eq(
			_hover(cell),
			WORDING_HOVER % [String(cell[&"token"]), int(cell[&"index"]) + 1, WORDING_EMPTY, 0],
			"an unfit hull answers the all-empty shape, so every cell reads EMPTY"
		)


## R1 MED-1's shipyard half: a hull the account owns but holds no fit for reads the fit the
## launch would fly (the profile's own `resolved_fit`), so a delivered cell names its module
## instead of the `EMPTY` the FITTING pane would contradict. A hull the account does not own
## keeps the all-empty read the wave shipped.
func test_the_hover_line_reads_the_launchs_fit_for_an_owned_hull() -> void:
	var owned: Array[StringName] = [HULL, UNOWNED_HULL]
	_profile.set(&"_owned_ships", owned)
	assert_false(
		(_profile.get(&"_fits") as Dictionary).has(String(UNOWNED_HULL)), "nothing is stored for it"
	)
	var row := _row(UNOWNED_HULL)
	assert_true(row != null, "the hull list has a row for it")
	row.grab_focus()
	assert_eq(_selected_hull(), UNOWNED_HULL, "the preview follows the row")
	assert_true(_owned().has(UNOWNED_HULL), "and the account owns it")
	var delivered := ShipFit.standard_fit(UNOWNED_HULL)
	assert_false(delivered.is_empty(), "the hull is delivered with a fit to resolve to")
	for cell: Dictionary in ShipFit.grid_cells(UNOWNED_HULL):
		if bool(cell[&"gap"]):
			assert_eq(_hover(cell), "", "a gap carries no plate and no line")
			continue
		var module_id := _fit_cell(delivered, StringName(cell[&"type"]), int(cell[&"index"]))
		var name_text := WORDING_EMPTY
		var count := 0
		if module_id != &"":
			name_text = _module_name(module_id)
			count = int(_profile.call(&"module_count", module_id))
		assert_eq(
			_hover(cell),
			WORDING_HOVER % [String(cell[&"token"]), int(cell[&"index"]) + 1, name_text, count],
			"an owned hull reads the fit the launch would fly"
		)
	## W1 is the cell the delivered fit fills, so it is the one the stored fit alone would
	## answer `EMPTY` for.
	assert_eq(
		_hover(_cell(&"weapons", 0)),
		WORDING_HOVER % ["W", 1, _module_name(LASER), int(_profile.call(&"module_count", LASER))],
		"the delivered laser, not the EMPTY a bare stored fit answers"
	)


func test_hovering_a_plate_publishes_its_line_and_costs_the_plate_nothing() -> void:
	var grid := _shipyard.get_node("%HardpointSlots") as GridContainer
	var caption := (_shipyard.get_node("%HardpointCaption") as Label).text
	var plate := _plate("W", 0)
	assert_true(plate != null, "the plate exists")
	## The section 5.2 amendment's own guard: the hover line costs the grid nothing - the same
	## 48 px plate, the same theme art, the same 6 px glyph inset, the same separation and the
	## same caption - and the cell stays a display (disabled, no focus ring, no mutation).
	assert_eq(plate.custom_minimum_size, Vector2(PLATE_SIZE, PLATE_SIZE))
	assert_true(plate.disabled, "a display cell stays disabled")
	assert_eq(plate.focus_mode, Control.FOCUS_NONE, "a display cell carries no focus ring")
	assert_eq(plate.theme_type_variation, PLATE_VARIATION, "the plate art is unchanged")
	assert_ne(plate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the plate can be hovered at all")
	assert_eq(grid.get_theme_constant(&"h_separation"), PLATE_SEPARATION)
	assert_eq(grid.get_theme_constant(&"v_separation"), PLATE_SEPARATION)
	var glyph := plate.get_node_or_null(^"Icon") as TextureRect
	assert_true(glyph != null, "the slot glyph is a child of the plate")
	if glyph != null:
		assert_eq(glyph.texture.resource_path, GLYPH_DIR + GLYPH_TEMPLATE % "w")
		assert_eq(glyph.offset_left, PLATE_ICON_INSET)
	var before := [plate.texture_normal, plate.texture_hover, grid.columns, caption]
	plate.mouse_entered.emit()
	assert_eq(_last_status(), _hover(_cell(&"weapons", 0)), "the hover line goes up the shell's strip")
	assert_eq(
		[plate.texture_normal, plate.texture_hover, grid.columns, (_shipyard.get_node("%HardpointCaption") as Label).text],
		before,
		"hovering moves no plate texture, no column count and no caption"
	)
	assert_eq(
		caption,
		WORDING_CAPTION % [
			_slot_cell_count(HULL), int(ShipFit.grid_counts(HULL).get(&"engines", 0))
		]
	)
	plate.mouse_exited.emit()
	assert_ne(_last_status(), _hover(_cell(&"weapons", 0)), "leaving the plate drops its line")
	assert_contains(_last_status(), String(Catalog.ship(HULL).get(&"name", "")).to_upper())


func test_the_shipyard_reads_the_fit_without_ever_writing_it() -> void:
	var source := _read_source("res://ui/station/shipyard_panel.gd")
	assert_true(source.contains("\"fit_for\""), "the hover line reads the selected hull's fit")
	assert_true(source.contains("\"module_count\""), "and the account's stock of the module")
	for forbidden: String in [
		"\"set_fit\"", "\"set_fit_slot\"", "\"clear_fit\"", "\"fit_module_at\"",
		"\"clear_fit_slot\"", "\"add_module\"", "\"take_module\"", "\"buy_module\"",
		"\"spend\"", "\"add_credits\"", "\"set_vitals\"",
	]:
		assert_false(
			source.contains(forbidden), "the shipyard never calls PlayerProfile.%s" % forbidden
		)


func test_the_launch_pane_only_asks_the_service_and_never_touches_credits() -> void:
	var source := _read_source("res://ui/station/launch_panel.gd")
	for required: String in ["\"refuel\"", "\"recharge\"", "RepairsService.refuel", "RepairsService.recharge"]:
		assert_true(source.contains(required), "the pane reaches the service through %s" % required)
	for forbidden: String in [
		"\"set_vitals\"", "\"spend\"", "\"add_credits\"", "\"add_cargo\"", "\"remove_cargo\"",
		"\"set_ammo\"", "\"buy_ammo\"", "\"set_fit\"", "\"clear_fit\"", "\"add_module\"",
		"\"take_module\"", "\"install_upgrade\"",
	]:
		assert_false(
			source.contains(forbidden), "the LAUNCH pane never calls PlayerProfile.%s" % forbidden
		)


func _slot_cell_count(hull_id: StringName) -> int:
	var total := 0
	for count: Variant in ShipFit.grid_counts(hull_id).values():
		total += int(count)
	return total


func _read_source(path: String) -> String:
	assert_true(FileAccess.file_exists(path), "%s is readable" % path)
	return FileAccess.get_file_as_string(path)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


## ---------------------------------------------------------------------------- the services


func test_refuel_fills_the_tank_and_reports_the_figures_own_key() -> void:
	_file_report(0)
	var credits := _credits()
	var tank := _pool_max(false)
	_press(_refuel_button())
	assert_eq(_strip(), WORDING_REPORT % ["FUEL_MAX", tank])
	assert_eq(_fuel_of(HULL), tank, "the service filed the tank on the active hull")
	assert_eq(_credits(), credits, "a free service moves no credits")
	assert_false(_strip_danger(), "a success is not a refusal")
	assert_false(_strip().contains("CR"), "no price is printed")


func test_recharge_reports_the_energy_figure_and_files_nothing() -> void:
	_file_report(_pool_max(false))
	var credits := _credits()
	var fuel := _fuel_of(HULL)
	var cells := _pool_max(true)
	_press(_recharge_button())
	assert_eq(_strip(), WORDING_REPORT % ["ENERGY_MAX", cells])
	assert_eq(_fuel_of(HULL), fuel, "Energy recomputes at launch, so the call files no tank")
	assert_eq(_credits(), credits, "a free service moves no credits")
	assert_false(_strip_danger(), "a success is not a refusal")


func test_the_full_tank_refusal_is_rendered() -> void:
	var tank := _pool_max(false)
	_file_report(tank)
	var credits := _credits()
	_press(_refuel_button())
	assert_eq(_strip(), String(RepairsService.REASON_FUEL_FULL).to_upper())
	assert_true(_strip_danger(), "a refusal is rendered in the danger colour")
	assert_eq(_credits(), credits, "a refused service moves no credits")
	assert_eq(_fuel_of(HULL), tank, "and leaves the tank where it was")
	assert_false(_refuel_button().disabled, "the button stays pressable")


func test_an_unfiled_hull_refuses_with_the_services_own_reason() -> void:
	assert_true(_profile.call(&"vitals_of", HULL).is_empty(), "the fixture files no report")
	_press(_refuel_button())
	assert_eq(_strip(), String(RepairsService.REASON_NO_DAMAGE_REPORT).to_upper())
	assert_true(_strip_danger(), "a refusal is rendered in the danger colour")


func test_the_service_actions_are_deck_controls_own_catalogued_names() -> void:
	var refuel := _refuel_button()
	var recharge := _recharge_button()
	var launch_button := _launch.get_node("%LaunchButton") as Button
	var box := launch_button.get_parent()
	assert_true(refuel != null and recharge != null, "both actions exist")
	assert_eq(refuel.text, _catalogue_name(&"refuel"), "the label is the catalogue's own name")
	assert_eq(recharge.text, _catalogue_name(&"recharge"))
	assert_eq(refuel.theme_type_variation, &"StationButton")
	assert_eq(refuel.custom_minimum_size, Vector2(0.0, 56.0))
	assert_eq(refuel.get_parent().get_parent(), box, "the row lives in DECK CONTROL's own box")
	assert_eq(recharge.get_parent(), refuel.get_parent(), "one row holds both")
	assert_gt(launch_button.get_index(), refuel.get_parent().get_index(), "LAUNCH stays last")
