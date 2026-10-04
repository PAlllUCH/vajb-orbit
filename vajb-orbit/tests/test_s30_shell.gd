@tool
extends McpTestSuite
## Suite s30_shell: wave S30's station shell v2 (STATION_HUB section 18 P15-P21 + section
## 19, UI_SPEC section 11/12). One row per pinned acceptance: the shell re-lay (header
## TERMINAL + identity plate + credits, one body pane, footer strip), the TERMINAL drawer
## (open/close/ESC/entry navigation/focus trap), OVERVIEW landing on dock with its five
## blocks and its tile/REPAIR deep links, and P20's six-pane cycle wrap. The station is
## mounted the way `test_s29_station_panels.gd` mounts it (the shipped scene, the shipped
## theme, the profile borrowed and handed back).

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s30_shell.cfg"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"

var _profile: ProfileScript = null
var _station: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_credits := 0


func suite_name() -> String:
	return "s30_shell"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the station")
		return
	var service := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = service
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)


func suite_teardown() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
		_station = null
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


## A fresh shell per row under a themed host, added to the profile autoload (the runner
## calls every test from inside its own `_ready`, when `/root` is still busy).
func _mount() -> Control:
	var host := Control.new()
	host.name = "S30Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


## ----------------------------------------------------------- the shell re-lay (P15)


func test_the_shell_lands_on_overview() -> void:
	var screen := _mount()
	assert_eq(
		int(screen.get(&"_module")), StationScript.OVERVIEW, "P17: OVERVIEW is the landing pane"
	)
	var overview := screen.call(&"overview_pane") as CanvasItem
	assert_true(overview != null and overview.visible, "the OVERVIEW pane shows on dock")
	for pane: CanvasItem in (screen.get(&"_panels") as Array):
		assert_false(pane.visible, "and the six service panes stay hidden (%s)" % pane.name)


func test_the_header_carries_the_terminal_button_the_plate_and_the_credits() -> void:
	var screen := _mount()
	var terminal := screen.get_node_or_null(NodePath("%TerminalButton")) as Button
	assert_true(terminal != null, "N25: the TERMINAL button ships")
	if terminal != null:
		assert_eq(terminal.text, "TERMINAL", "and carries the pinned word")
		assert_eq(terminal.custom_minimum_size, Vector2(96.0, 32.0), "at the ActionInline size")
	var plate := screen.get_node_or_null(NodePath("%StationPlate")) as PanelContainer
	assert_true(plate != null, "the identity plate ships (A5.4-1)")
	assert_true(
		plate.get_node_or_null(^"PlateMargin/PlateRow/StationMark") != null,
		"with the faction glyph cell"
	)
	assert_true(
		screen.get_node_or_null(NodePath("%CreditsPanel")) != null, "the credits housing ships"
	)
	var page := screen.get_node(^"Layout/Page") as Control
	assert_eq(
		(page.get_node(^"Footer") as Control).get_index(),
		page.get_child_count() - 1,
		"the footer status strip is the last band"
	)
	assert_true(
		page.get_node_or_null(^"Body/ModuleRail") == null, "and the ModuleRail is gone (P15)"
	)


## ----------------------------------------------------------- the TERMINAL drawer (N25/N26)


func test_the_terminal_button_toggles_the_drawer() -> void:
	var screen := _mount()
	var terminal := screen.get_node(NodePath("%TerminalButton")) as Button
	assert_false(bool(screen.call(&"is_drawer_open")), "the drawer starts closed")
	terminal.pressed.emit()
	assert_true(bool(screen.call(&"is_drawer_open")), "the press opens it (N25)")
	assert_true((screen.get(&"_drawer") as Control).visible, "and the overlay shows")
	terminal.pressed.emit()
	assert_false(bool(screen.call(&"is_drawer_open")), "the second press closes it")


func test_the_drawer_closes_on_the_cancel_route() -> void:
	var screen := _mount()
	(screen.get_node(NodePath("%TerminalButton")) as Button).pressed.emit()
	assert_true(bool(screen.call(&"is_drawer_open")), "the drawer is up")
	screen.call(&"_handle_cancel")
	assert_false(bool(screen.call(&"is_drawer_open")), "P19: ESC closes it in one operation")


func test_a_drawer_entry_switches_the_pane_and_closes_the_drawer() -> void:
	var screen := _mount()
	(screen.get_node(NodePath("%TerminalButton")) as Button).pressed.emit()
	var entries := screen.call(&"drawer_entries") as Array
	assert_eq(entries.size(), 7, "P16: OVERVIEW + six service decks")
	var armory := entries[1] as Button
	assert_eq(armory.name, "ArmoryEntry", "the second entry is ARMORY")
	armory.pressed.emit()
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.OUTFITTING, "the entry switched the deck"
	)
	assert_false(bool(screen.call(&"is_drawer_open")), "and the drawer closed (N39)")


func test_the_drawer_focus_trap_wraps() -> void:
	var screen := _mount()
	(screen.get_node(NodePath("%TerminalButton")) as Button).pressed.emit()
	var order := screen.get(&"_drawer_focus_order") as Array
	assert_eq(order.size(), 8, "N39: the seven entries plus LOG OUT")
	(order[order.size() - 1] as Control).grab_focus()
	screen.call(&"_move_drawer_focus", 1)
	assert_eq(
		screen.get_viewport().gui_get_focus_owner(), order[0], "the walk wraps to the first entry"
	)
	screen.call(&"_move_drawer_focus", -1)
	assert_eq(
		screen.get_viewport().gui_get_focus_owner(),
		order[order.size() - 1],
		"and back to LOG OUT"
	)


## ----------------------------------------------------------- OVERVIEW (P17/P18)


func test_the_overview_carries_the_five_blocks() -> void:
	var screen := _mount()
	var overview := screen.call(&"overview_pane") as Control
	assert_true(overview != null, "the OVERVIEW pane ships")
	if overview == null:
		return
	assert_true(
		overview.get_node_or_null(^"PaneHeader/PaneTitle") != null, "P7's PaneHeader ships"
	)
	var plate := overview.find_child("IdentityBlock", true, false)
	assert_true(plate != null, "block 1: the identity plate ships")
	var grid := overview.find_child("TileGrid", true, false) as GridContainer
	assert_true(grid != null, "block 2: the tile grid ships")
	if grid != null:
		assert_eq(grid.columns, 3, "P23: three columns")
		assert_eq(grid.get_child_count(), 6, "and six tiles")
		assert_eq(
			(grid.get_child(0) as Button).custom_minimum_size, Vector2(300.0, 140.0),
			"each tile is at least 300x140 (P18)"
		)
	assert_true(overview.find_child("HullBlock", true, false) != null, "block 3: the hull block")
	assert_true(
		overview.find_child("ServiceRows", true, false) != null, "block 4: the services rows"
	)
	assert_true(
		overview.find_child("FlavourLine", true, false) != null, "block 5: the flavour line"
	)


func test_the_services_rows_carry_the_u2_names() -> void:
	var screen := _mount()
	var overview := screen.call(&"overview_pane") as Control
	var rows := overview.find_child("ServiceRows", true, false) as VBoxContainer
	assert_true(rows != null, "the services rows ship")
	if rows == null:
		return
	assert_eq(rows.get_child_count(), 3, "P25: three rows")
	var names: Array[String] = []
	for row: Node in rows.get_children():
		names.append(String(row.name))
	assert_eq(
		names, ["ContractsRow", "InsuranceRow", "VaultsRow"] as Array[String],
		"CONTRACTS / INSURANCE / VAULTS (U2)"
	)


func test_an_overview_tile_navigates_to_its_deck() -> void:
	var screen := _mount()
	var overview := screen.call(&"overview_pane") as Control
	var tile := overview.find_child("ShipyardTile", true, false) as Button
	assert_true(tile != null, "the SHIPYARD tile ships")
	tile.pressed.emit()
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.SHIPYARD,
		"P23: a tile press navigates on press"
	)


func test_the_repair_chip_deep_links_to_the_shipyard() -> void:
	var screen := _mount()
	var overview := screen.call(&"overview_pane") as Control
	var chip := overview.find_child("RepairChip", true, false) as Button
	assert_true(chip != null, "P18: the REPAIR chip ships")
	chip.pressed.emit()
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.SHIPYARD, "P24: REPAIR lands on SHIPYARD"
	)
	var shipyard := (screen.get(&"_panels") as Array)[StationScript.Module.SHIPYARD] as Node
	assert_true(
		shipyard.has_method(&"focus_repair"), "with the repair block focusable (P24)"
	)


## ----------------------------------------------------------- P20 cycling (A4)


func test_the_cycle_wraps_the_six_service_panes() -> void:
	var screen := _mount()
	screen.call(&"_select_module", StationScript.Module.LAUNCH, true)
	screen.call(&"_cycle_module", 1)
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.OUTFITTING,
		"P20: forward from LAUNCH wraps to ARMORY"
	)
	screen.call(&"_cycle_module", -1)
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.LAUNCH,
		"and back from ARMORY wraps to LAUNCH"
	)


func test_a_cycle_from_overview_enters_the_six() -> void:
	var screen := _mount()
	assert_eq(int(screen.get(&"_module")), StationScript.OVERVIEW, "on dock the shell is OVERVIEW")
	screen.call(&"_cycle_module", 1)
	assert_eq(
		int(screen.get(&"_module")), StationScript.Module.OUTFITTING,
		"P20: a forward cycle enters the six at ARMORY"
	)


## ------------------------------------------------- S30-F1 fix rows (F1-F4)


## F1 (UI_SPEC section 12.4 / STATION_HUB section 19.3): no pane may force the shell to
## reflow. The shipyard's tall comparison/repair column rides a `ScrollContainer`, so its
## minimum cannot push the header or the footer off the pinned bands. (A pane's minimum is
## only measurable once the shell has laid out, so the geometric proof is the reviewer's
## re-measurement; this row pins the cure itself.)
func test_the_shipyard_stats_column_scrolls_and_cannot_reflow_the_shell() -> void:
	var screen := _mount()
	var shipyard := (screen.get(&"_panels") as Array)[StationScript.Module.SHIPYARD] as Control
	var stats := shipyard.get_node_or_null(^"ShipyardBody/StatsBox")
	assert_true(stats is ScrollContainer, "the shipyard's stats column scrolls (F1)")
	if stats == null:
		return
	assert_true(
		stats.get_combined_minimum_size().y <= 56.0,
		"the scrolled column's minimum cannot grow the pane (min %s)"
			% str(stats.get_combined_minimum_size())
	)
	assert_true(
		(shipyard.get_node(^"ShipyardBody") as Control) != null, "the content split still ships"
	)


## F2 (UI_SPEC section 12.1 / N26): the drawer plate is R-S30-1's 362 px wide and carries
## no build-time minimum-size offset - opening re-writes its vertical box, so LOG OUT
## stays on screen.
func test_the_drawer_plate_carries_no_minimum_size_offset() -> void:
	var screen := _mount()
	var plate := screen.get(&"_drawer_plate") as Control
	plate.offset_bottom = 594.0
	(screen.get_node(NodePath("%TerminalButton")) as Button).pressed.emit()
	assert_eq(plate.offset_bottom, 0.0, "opening the drawer re-writes the plate's bottom box")
	assert_eq(plate.offset_top, 0.0, "and its top box")
	assert_eq(roundi(plate.custom_minimum_size.x), 362, "R-S30-1's plate width")


## F3 (UI_SPEC section 12.3 / N28): `_fit()` sizes the content, never the anchor-laid-out
## root, so the sheet stays full-rect instead of collapsing to 0x0.
func test_the_sheet_fit_never_resets_the_root() -> void:
	var screen := _mount()
	var sheet := screen.get(&"_sheet") as Control
	sheet.call(&"open", {&"name": "PROBE", &"stats": "A\nB"})
	assert_eq(sheet.anchor_right, 1.0, "the sheet root keeps its full-rect anchors")
	assert_eq(sheet.anchor_bottom, 1.0, "on both axes")
	assert_eq(sheet.offset_right, 0.0, "and no horizontal offset")
	assert_eq(sheet.offset_bottom, 0.0, "and no vertical offset")
	var panel := sheet.get_node("%SheetPanel") as Control
	assert_true(panel.custom_minimum_size.x >= 420.0, "the panel keeps N28's 420 px floor")
	sheet.call(&"close")


## F4 (UI_SPEC section 12.2/12.3): theme propagation stops at a CanvasLayer, so each popup
## root carries the theme itself and the drawer plate resolves `PanelRaised`.
func test_the_popup_layers_resolve_the_theme() -> void:
	var screen := _mount()
	assert_true((screen.get(&"_tooltip") as Control).theme != null, "the tooltip carries the theme")
	assert_true((screen.get(&"_sheet") as Control).theme != null, "the sheet too")
	assert_true((screen.get(&"_drawer") as Control).theme != null, "and the code-built drawer")
	var plate := screen.get(&"_drawer_plate") as PanelContainer
	var sb := plate.get_theme_stylebox(&"panel")
	assert_true(
		sb is StyleBoxTexture,
		"so the drawer plate resolves PanelRaised, not a default StyleBoxFlat (got %s)"
			% sb.get_class()
	)

