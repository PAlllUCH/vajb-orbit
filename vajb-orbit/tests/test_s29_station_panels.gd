@tool
extends McpTestSuite
## Suite s29_station_panels: wave S29's merged station panels (STATION_HUB section 16
## P4-P7, section 17's P8-P14, UI_SPEC section 8 P1-P3 and the D17 leftovers A7 owns).
##
## One row per pinned acceptance: the merged ARMORY's browser (P8's caption, the tab strip
## minus HULLS, the `e_hyperdrive` row), the drag law's wrong-slot refusal (P9) with the
## 0.5 s slot-caption flash (P10), the fit confirmation (P11), the buy-into-cell one flow
## with its credits check, the CANDIDATE rename (A7's `IF FITTED`), the cell tooltips,
## the merged SHIPYARD's `INSTALLED MODULES` caption (P12), the `NOMINAL` damage rows with
## the fee in the footer (P13), the comparison deltas (A7) and the P1 cluster sizes with
## the primary rightmost (P2). Panes mount the way `test_p2b1_outfitting_panel.gd` mounts
## them (the shipped scene, the shipped theme, the profile borrowed and handed back).

const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const ArmoryScript := preload("res://ui/station/armory_panel.gd")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s29_station_panels.cfg"
const HOST := Vector2(1392.0, 610.0)
const SHIP: StringName = &"ship_vanguard"
const HYPERDRIVE: StringName = &"e_hyperdrive"

var _profile: ProfileScript = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_credits := 0
var _statuses: Array[String] = []


func suite_name() -> String:
	return "s29_station_panels"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the panes")
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


func suite_teardown() -> void:
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
	_statuses.clear()
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _mount(scene: PackedScene) -> Control:
	var host := Control.new()
	host.name = "S29Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var pane := scene.instantiate() as Control
	host.add_child(pane)
	_profile.connect(&"profile_changed", Callable(pane, &"refresh_profile"))
	pane.connect(&"status_requested", _on_status)
	if pane.has_method(&"_lay"):
		pane.call(&"_lay")
	return pane


func _free_host(pane: Control) -> void:
	var host := pane.get_parent()
	if host != null and is_instance_valid(host):
		host.free()


func _on_status(message: String, _danger: bool) -> void:
	_statuses.append(message)


func _last_status() -> String:
	return "" if _statuses.is_empty() else _statuses[_statuses.size() - 1]


## ---------------------------------------------------------------- A4 - the merged ARMORY


func test_the_browser_caption_and_the_tab_strip_minus_hulls() -> void:
	var panel := _mount(ArmoryScene)
	assert_eq(
		String((panel.get_node("%BrowserCaption") as Label).text), "MODULES · OWNED & BUYABLE",
		"P8's own browser caption"
	)
	var tabs := panel.get_node("%FamilyTabs") as HBoxContainer
	var labels: Array[String] = []
	for child: Node in tabs.get_children():
		labels.append(String((child as Button).text))
	assert_eq(
		labels,
		[
			"WEAPONS", "DRIVES", "SHIELDS", "ARMOUR", "POWER",
			"COMPUTERS", "BOOSTERS", "UTILITY", "ALL",
		] as Array[String],
		"the auction's family tabs minus HULLS (P4's judgment)"
	)
	assert_true(not labels.has("HULLS"), "a hull is not a module row and fits no cell")
	assert_eq(StringName(panel.call(&"active_tab")), &"all", "ALL is the entry tab")
	_free_host(panel)


func test_the_hyperdrive_row_is_visible_at_tier_3() -> void:
	var panel := _mount(ArmoryScene)
	var ids: Array[StringName] = panel.call(&"module_row_ids")
	assert_true(ids.has(HYPERDRIVE), "the browser lists e_hyperdrive (R-S29-1's tier 3 row)")
	var read := ""
	for payload: Dictionary in panel.get(&"_browser_payloads"):
		if payload[&"base"] == HYPERDRIVE:
			read = String((payload[&"read"] as Label).text)
	assert_eq(read, "12 000 CR", "a buyable row reads its own price")
	panel.call(&"select_tab", &"drives")
	assert_true(
		(panel.call(&"module_row_ids") as Array).has(HYPERDRIVE),
		"and the DRIVES tab keeps it (the catalogue slot is `engine`)"
	)
	_free_host(panel)


func test_a_wrong_slot_drop_refuses_with_words_and_a_flash() -> void:
	var panel := _mount(ArmoryScene)
	panel.call(&"select_cell", &"weapons", 0)
	var cell: Dictionary = {}
	for payload: Dictionary in panel.get(&"_cells"):
		if payload[&"type"] == &"weapons" and int(payload[&"index"]) == 0:
			cell = payload
	assert_true(not cell.is_empty(), "the Vanguard carries a W cell")
	var data := {
		&"kind": ArmoryScript.DRAG_BROWSER,
		ArmoryScript.DRAG_KEY_BASE: HYPERDRIVE,
		ArmoryScript.DRAG_KEY_ENTRY: HYPERDRIVE,
		ArmoryScript.DRAG_KEY_OWNED: false,
		ArmoryScript.DRAG_KEY_PRICE: 12000,
	}
	assert_true(bool(panel.call(&"cell_can_drop", cell, data)), "a module payload reaches a cell")
	panel.call(&"cell_drop", cell, data)
	assert_eq(
		_last_status(),
		"DROP REFUSED — HYPERDRIVE FITS NO WEAPONS CELL",
		"P9's own refusal line, never a colour alone"
	)
	var caption := cell[&"caption"] as Label
	assert_true(caption.visible, "P10: the cell flashes its own slot caption")
	assert_eq(String(caption.text), "WEAPONS", "the cell's own slot word")
	_free_host(panel)


func test_a_fit_confirms_with_p11_and_the_meter_renames_the_candidate() -> void:
	var panel := _mount(ArmoryScene)
	assert_true(
		bool(panel.call(&"select_cell", &"engines", 0)), "the engine cell selects"
	)
	_profile.call(&"add_module", HYPERDRIVE, 1)
	assert_true(bool(panel.call(&"install_module", HYPERDRIVE)), "the composed install lands")
	assert_eq(_last_status(), "FITTED · HYPERDRIVE", "P11's own confirmation")
	assert_true(
		String(panel.call(&"meter_text")).contains("IF FITTED"),
		"A7: the meter reads IF FITTED, never the undefined CANDIDATE"
	)
	assert_true(
		not String(panel.call(&"meter_text")).contains("CANDIDATE"), "and the old word is gone"
	)
	assert_true(
		String((panel.get_node("%MeterLabel") as Label).text).begins_with("PWR "),
		"the meter keeps FITTING's own PWR numbers"
	)
	_free_host(panel)


func test_the_buy_flow_checks_credits_first() -> void:
	var panel := _mount(ArmoryScene)
	_profile.set(&"_credits", 10)
	_profile.set(&"_modules", {})
	panel.call(&"select_cell", &"engines", 0)
	var payload: Dictionary = {}
	for entry: Dictionary in panel.get(&"_browser_payloads"):
		if entry[&"base"] == HYPERDRIVE:
			payload = entry
	assert_true(not payload.is_empty(), "the hyperdrive row exists")
	panel.call(&"_buy_into_cell", payload)
	assert_eq(
		_last_status(), "REFUSED · NOT ENOUGH CREDITS · 12 000 NEEDED",
		"the shipped shortfall wording, before any purchase"
	)
	assert_eq(
		int(_profile.call(&"module_count", HYPERDRIVE)), 0, "and nothing was bought"
	)
	_profile.set(&"_credits", 50000)
	panel.call(&"_buy_into_cell", payload)
	assert_eq(_last_status(), "FITTED · HYPERDRIVE", "one press buys-then-fits")
	assert_eq(int(_profile.call(&"module_count", HYPERDRIVE)), 0, "the buy went straight into the cell")
	_free_host(panel)


func test_the_cell_tooltips_name_the_cell() -> void:
	var panel := _mount(ArmoryScene)
	var plate := (panel.get(&"_cells")[0] as Dictionary)[&"node"] as Button
	assert_true(
		plate.tooltip_text.contains(" · ") and plate.tooltip_text.contains("OWNED ×"),
		"A7: the cell tooltip is the cell's own naming line (actual \"%s\")" % plate.tooltip_text
	)
	assert_true(
		not String(plate.tooltip_text).contains("CANDIDATE"), "and carries no dead term"
	)
	_free_host(panel)


## ------------------------------------------------------------- A5 - the merged SHIPYARD


func test_the_repair_rows_read_nominal_and_the_fee_stays_in_the_footer() -> void:
	## A filed, intact vitals record (17 section 3's own silent write) so the report has
	## something to read - a fresh account carries no report at all (`NO DAMAGE REPORT`).
	_profile.call(&"set_vitals", SHIP, 9999, 9999)
	var panel := _mount(ShipyardScene)
	var values: Array[Dictionary] = panel.call(&"repair_row_values")
	var labels: Array[String] = []
	for row: Dictionary in values:
		labels.append(String(row[&"key"]))
	assert_true(not labels.has("missing"), "P5: no MISSING row reaches the body")
	assert_true(not labels.has("fee"), "and no FEE row either")
	assert_eq(labels.size(), 7, "ACTIVE HULL/HULL/SHIELD plus the four quadrants")
	for row: Dictionary in values:
		if row[&"key"] == &"hull_name":
			continue
		assert_eq(String(row[&"state"]), "NOMINAL", "P13: an intact row reads NOMINAL")
	assert_eq(
		String(panel.call(&"repair_footer_text")), "ALL SYSTEMS NOMINAL",
		"the intact footer is the shipped wording (repairs_panel.gd:50)"
	)
	assert_true(
		String(panel.call(&"repair_footer_text")).find("CR") == -1,
		"and the fee lives only in the footer line, never a body row"
	)
	_free_host(panel)


func test_the_comparison_carries_deltas_and_the_installed_caption_is_p12() -> void:
	var panel := _mount(ShipyardScene)
	assert_eq(
		String((panel.get_node("%InstalledCaption") as Label).text), "INSTALLED MODULES",
		"P12's own caption under the comparison"
	)
	var delta := panel.get(&"_delta_cells")[&"hull"] as Label
	assert_true(delta != null, "the comparison carries a delta column (A7)")
	if delta != null:
		assert_eq(String(delta.text), "+0", "a hull compared to itself reads +0, not two blank columns")
	_free_host(panel)


func test_the_cluster_is_the_p1_pair_with_the_primary_rightmost() -> void:
	var panel := _mount(ShipyardScene)
	var repair := panel.get_node("%RepairButton") as Button
	var set_active := panel.get_node("%ShipAction") as Button
	assert_eq(repair.custom_minimum_size, Vector2(360.0, 56.0), "REPAIR is P1's 360x56")
	assert_eq(set_active.custom_minimum_size, Vector2(360.0, 56.0), "and SET ACTIVE its secondary")
	assert_eq(String(repair.text), "REPAIR", "the primary's own word")
	assert_true(
		repair.get_index() > set_active.get_index(), "P2: the primary sits rightmost"
	)
	assert_true(repair.disabled, "all-nominal disables REPAIR (label + state)")
	var armory := _mount(ArmoryScene)
	var remove := armory.get_node("%RemoveButton") as Button
	var buy_fit := armory.get_node("%BuyFitButton") as Button
	assert_eq(remove.custom_minimum_size, Vector2(360.0, 56.0), "REMOVE is the P1 secondary")
	assert_eq(buy_fit.custom_minimum_size, Vector2(360.0, 56.0), "BUY & FIT the primary")
	assert_true(buy_fit.get_index() > remove.get_index(), "and the primary sits rightmost")
	assert_eq(String(buy_fit.text), "BUY & FIT", "P14's own label")
	armory.call(&"select_cell", &"weapons", 0)
	assert_eq(
		String(buy_fit.text), "BUY & FIT SELECTED", "P14 appends SELECTED when a cell is selected"
	)
	_free_host(armory)
	_free_host(panel)


## ----------------------------------------------------------------- A6 - the shell fills


func test_the_shipyard_and_launch_fill_the_band_when_idle() -> void:
	var screen := StationScene.instantiate() as Control
	var host := Control.new()
	host.theme = ThemeRes
	host.size = Vector2(1920.0, 1080.0)
	_profile.add_child(host)
	host.add_child(screen)
	var panels: Array = screen.get(&"_panels")
	assert_eq(panels.size(), 6, "P7's folded rail carries six panes")
	var title: Label = screen.get_node("%InspectorTitle")
	screen.call(&"_select_module", StationScript.Module.SHIPYARD, true)
	assert_true(
		not title.text.is_empty(), "P6: the band is never empty on SHIPYARD (actual \"%s\")" % title.text
	)
	var shipyard := panels[StationScript.Module.SHIPYARD] as CanvasItem
	shipyard.call(&"_inspect_row", {&"id": SHIP, &"name": "VANGUARD"}, false)
	assert_true(
		String(title.text).contains("ACTIVE HULL"),
		"the idle fill is the active hull's summary (actual \"%s\")" % title.text
	)
	screen.call(&"_select_module", StationScript.Module.LAUNCH, true)
	assert_true(
		not title.text.is_empty(), "P6: LAUNCH fills the band with its own summary (actual \"%s\")" % title.text
	)
	host.free()
