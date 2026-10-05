@tool
extends McpTestSuite
## Suite s32_armory_modes: the ARMORY's two-sector rework (STATION_HUB section 21.1
## P38-P41, wave S33). One row per pinned acceptance:
##   0. P32 - the two modes behind the header switch, exactly one visible, the hint swapping.
##   1. P38 - FIT CELLS is two equal sectors (probe widths); the grid + CELL INFO stay left.
##   2. P38 - the right list's two states: browse (bag units union fitted bases, `FIT`/`STORED`)
##      and selected (owned-that-fits `OWNED` first, then buyable-that-fits `BUYABLE`, legality
##      per row).
##   3. P39 - BATTERY CONFIG is two equal sectors; the EQ container carries its category tabs
##      and count rows.
##   4. P34 - B1-B5 racks over fitted weapons, a drag between racks persisting through the
##      profile's battery record, the read-only `W<n> — EMPTY` rows and the SALVO/cycle.
##   5. P35 - no preset/save surface (a grep row).
##   6. P38/P39 - no `FITS HERE`/`BUYABLE THAT FITS` wide block and no P36 foot band remain.
##   7. P40 - every row control lands inside the 1920x1080 window; the hint follows mode +
##      selection.
##
## The pane is mounted the way the other armory suites mount it (the shipped scene, the
## shipped theme, the profile borrowed and handed back), so nothing here re-implements the
## panel's wiring.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s32_armory_modes.cfg"
const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const WINDOW := Vector2(1920.0, 1080.0)

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s32_armory_modes"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		skip_suite("the PlayerProfile autoload is the pane's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = _profile.get(&"_batteries")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
		_host = null
	_panel = null
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
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
	if _host != null and is_instance_valid(_host):
		_host.free()
		_host = null
	_seed_account()
	_host = Control.new()
	_host.name = "S32ArmoryHost"
	_host.theme = ThemeRes
	_host.size = WINDOW
	_profile.add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))


func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _settle() -> void:
	_panel.call(&"_lay")


## --------------------------------------------------------------- 1. the mode switch (P32)


func test_the_mode_switch_shows_exactly_one_mode() -> void:
	_settle()
	assert_eq(StringName(_panel.call(&"mode")), PanelScript.MODE_FIT, "FIT CELLS is the landing mode")
	var fit := _panel.get_node("%FitCells") as Control
	var battery := _panel.get_node("%BatteryConfig") as Control
	assert_true(fit.visible, "the FIT CELLS mode shows")
	assert_false(battery.visible, "and BATTERY CONFIG stays hidden")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	assert_eq(StringName(_panel.call(&"mode")), PanelScript.MODE_BATTERY, "the switch moved the mode")
	assert_false(fit.visible, "FIT CELLS hides")
	assert_true(battery.visible, "and BATTERY CONFIG shows - exactly one at a time")
	assert_eq(
		String((_panel.get_node("%PaneHint") as Label).text),
		PanelScript.PANE_HINT_BATTERY, "and the hint swaps with the mode"
	)
	_panel.call(&"set_mode", PanelScript.MODE_FIT)
	_settle()
	assert_true(fit.visible and not battery.visible, "and back to FIT CELLS")
	assert_eq(
		String((_panel.get_node("%PaneHint") as Label).text),
		PanelScript.PANE_HINT_FIT, "with the FIT CELLS hint"
	)


## ------------------------------------------------- 1. the two equal sectors (P38/P39)


func test_fit_cells_is_two_equal_sectors() -> void:
	_settle()
	var sectors := _panel.get_node("%FitSectors") as HBoxContainer
	assert_true(sectors != null, "the FIT CELLS mode carries its sector split")
	var left := _panel.get_node("%FitLeft") as Control
	var right := _panel.get_node("%FitRight") as Control
	assert_true(left != null and right != null, "both sectors ship")
	assert_true(
		absf(left.size.x - right.size.x) <= 1.0,
		"the two sectors are equal (left %.1f, right %.1f)" % [left.size.x, right.size.x]
	)
	assert_true(left.size.x > 0.0, "and the split has a real width")
	## The grid and the CELL INFO block ride the left sector.
	assert_true(left.is_ancestor_of(_panel.get_node("%SlotLayoutGrid")), "the grid is left (P38)")
	assert_true(left.is_ancestor_of(_panel.get_node("%CellInfoId")), "CELL INFO is left (P38)")
	assert_true(right.is_ancestor_of(_panel.get_node("%BrowserRows")), "the list is right (P38)")
	assert_true(right.is_ancestor_of(_panel.get_node("%BrowserBand")), "with its band")


func test_battery_config_is_two_equal_sectors() -> void:
	_settle()
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var sectors := _panel.get_node("%BatterySectors") as HBoxContainer
	assert_true(sectors != null, "BATTERY CONFIG carries its sector split")
	var left := _panel.get_node("%RackSector") as Control
	var right := _panel.get_node("%EqSector") as Control
	assert_true(left != null and right != null, "both sectors ship")
	assert_true(
		absf(left.size.x - right.size.x) <= 1.0,
		"the two sectors are equal (left %.1f, right %.1f)" % [left.size.x, right.size.x]
	)
	assert_true(left.is_ancestor_of(_panel.get_node("%RackRows")), "the racks are left (P39)")
	assert_true(left.is_ancestor_of(_panel.get_node("%EmptyRows")), "with the empty-cell list")
	assert_true(right.is_ancestor_of(_panel.get_node("%ArmoryRows")), "the EQ container is right")
	assert_true(right.is_ancestor_of(_panel.get_node("%EqTabs")), "with its category tabs")


## --------------------------------------------------------------- 2. CELL INFO (P33.1)


func test_the_cell_info_block_names_the_selected_cell() -> void:
	_settle()
	assert_eq(
		String((_panel.get_node("%CellInfoId") as Label).text),
		PanelScript.CELL_INFO_SELECT, "with no cell the block reads its select prompt"
	)
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 0)), "W1 of the Vanguard selects")
	assert_eq(
		String((_panel.get_node("%CellInfoId") as Label).text), "W1 · WEAPONS CELL",
		"the block names the cell id and its family"
	)
	assert_eq(
		String((_panel.get_node("%CellInfoFitted") as Label).text), "FITTED · LASER MKII",
		"and the delivered module"
	)
	assert_true(
		String((_panel.get_node("%CellInfoPower") as Label).text).begins_with("POWER DRAW "),
		"with the cell's own draw and the fit's PWR"
	)
	assert_true(
		not String((_panel.get_node("%CellInfoLegal") as Label).text).is_empty(),
		"and a proactive legality line"
	)
	_panel.call(&"select_cell", WEAPON_SLOT, 1)
	assert_eq(
		String((_panel.get_node("%CellInfoFitted") as Label).text), "EMPTY",
		"an empty cell reads EMPTY"
	)
	_panel.call(&"select_cell", ENGINE_SLOT, 0)
	assert_eq(
		String((_panel.get_node("%CellInfoLegal") as Label).text),
		PanelScript.REFUSAL_MANDATORY,
		"a mandatory cell proactively states its refusal wording"
	)


## ------------------------------------- 3. the one list's two states (P38 semantics)


func test_the_list_browses_owned_equipment_with_fit_and_stored_tags() -> void:
	_settle()
	## `w_laser` is the delivered fit's weapon (FIT); `w_cannon` is only in the bag (STORED).
	for base: StringName in [LASER, CANNON, &"w_railgun", &"p_std", &"e_ion"]:
		_profile.call(&"add_module", base, 1)
	_panel.call(&"refresh_profile", &"modules")
	_settle()
	## No cell selected: the list is the browse state, tagged FIT / STORED.
	assert_true(_panel.call(&"selected_cell").is_empty(), "no cell is selected")
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	assert_true(rows.get_child_count() > 0, "the browse list draws rows")
	var tags := _tags_of(rows)
	assert_true(
		tags.has(PanelScript.TAG_FIT) and tags.has(PanelScript.TAG_STORED),
		"the browse state tags FIT and STORED (tags %s)" % str(tags)
	)
	assert_eq(
		_tag_of_base(rows, LASER), PanelScript.TAG_FIT,
		"a base the ship already carries reads FIT"
	)
	assert_eq(
		_tag_of_base(rows, CANNON), PanelScript.TAG_STORED,
		"a base held only in the bag reads STORED"
	)
	## A press in the browse state only inspects - nothing is fitted.
	var before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	_panel.call(&"_on_browser_pressed", _payload_of(rows, &"p_std"))
	assert_eq(_profile.call(&"fit_for", VANGUARD), before, "a browse press fits nothing (P38)")


## F1: the browse state sources its rows from the bag's units UNION the hull's fitted bases, so
## a base the profile owns only as a fitted instance (no bag spare) still lists - tagged `FIT`,
## its count reading the fitted state rather than a price.
func test_a_fitted_only_module_still_lists_in_the_browse_state() -> void:
	_settle()
	## The standard Vanguard fit carries `w_laser`; the bag holds no spare of it.
	_panel.call(&"refresh_profile", &"modules")
	_settle()
	assert_true(_panel.call(&"selected_cell").is_empty(), "no cell is selected")
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	assert_eq(
		_tag_of_base(rows, LASER), PanelScript.TAG_FIT,
		"a base owned only as a fitted instance still lists, tagged FIT"
	)
	assert_eq(
		_read_of_base(rows, LASER), PanelScript.READ_FITTED,
		"and its count reads its fitted state, never a price"
	)
	## A base both fitted and held in the bag reads FIT with its bag count (the union rule).
	_profile.call(&"add_module", LASER, 2)
	_panel.call(&"refresh_profile", &"modules")
	_settle()
	rows = _panel.get_node("%BrowserRows") as VBoxContainer
	assert_eq(_tag_of_base(rows, LASER), PanelScript.TAG_FIT, "a fitted + held base reads FIT")
	assert_eq(
		_read_of_base(rows, LASER), PanelScript.OWNED_FORMAT % 2,
		"with its bag count, not the fitted read"
	)


## F2: the pane hint line follows the mode AND the selection (P40) - a content swap only.
func test_the_hint_line_follows_the_mode_and_the_selection() -> void:
	_settle()
	var hint := _panel.get_node("%PaneHint") as Label
	assert_eq(String(hint.text), PanelScript.PANE_HINT_FIT, "FIT CELLS idle reads its hint")
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 0)), "W1 selects")
	assert_eq(String(hint.text), PanelScript.PANE_HINT_FIT_CELL, "a selection swaps to the cell hint")
	_panel.call(&"clear_selection")
	assert_eq(String(hint.text), PanelScript.PANE_HINT_FIT, "clearing returns to the idle hint")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	assert_eq(
		String(hint.text), PanelScript.PANE_HINT_BATTERY, "and the mode swap reads the battery hint"
	)


func test_the_selected_list_lists_owned_then_buyable_with_legality() -> void:
	_settle()
	for base: StringName in [LASER, CANNON, &"w_railgun"]:
		_profile.call(&"add_module", base, 1)
	_panel.call(&"refresh_profile", &"modules")
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 1)), "W2 selects")
	_settle()
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	var tags := _tags_of(rows)
	assert_true(tags.has(PanelScript.TAG_OWNED), "the selected state lists OWNED rows")
	assert_true(tags.has(PanelScript.TAG_BUYABLE), "and BUYABLE rows")
	## Owned-that-fits first, then buyable-that-fits (P38's order).
	var seen_buyable := false
	for child: Node in rows.get_children():
		var tag := _row_tag(child)
		if tag == PanelScript.TAG_BUYABLE:
			seen_buyable = true
		elif tag == PanelScript.TAG_OWNED:
			assert_false(seen_buyable, "every OWNED row precedes every BUYABLE row (P38)")
	## The legality line is per row and is the CELL INFO vocabulary.
	for child: Node in rows.get_children():
		var legal := _row_legal(child)
		assert_false(legal.is_empty(), "each row carries its legality line (P38)")
	## A BUYABLE row carries BUY + INSPECT; the press buys-then-fits.
	var buyable := _first_row_with_tag(rows, PanelScript.TAG_BUYABLE)
	assert_true(buyable != null, "a buyable row ships")
	if buyable != null:
		assert_true(
			buyable.get_node_or_null(NodePath("RowInner/RowBox/Buy")) != null,
			"a BUYABLE row carries its BUY chip"
		)
		assert_true(
			buyable.get_node_or_null(NodePath("RowInner/RowBox/InspectChip")) != null,
			"and its INSPECT chip"
		)


## The owned-that-fits rows are exactly the legal owned candidates (the `OWNED` lane).
func test_the_owned_lane_is_exactly_the_legal_owned_candidates() -> void:
	_settle()
	for base: StringName in [LASER, CANNON, ROCKET, &"w_railgun"]:
		_profile.call(&"add_module", base, 1)
	_profile.call(&"add_module", &"p_std", 1)
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 1)), "W2 selects")
	var rows: Array = _panel.call(&"fits_here_rows")
	var listed: Array[StringName] = []
	for entry: Dictionary in rows:
		listed.append(StringName(entry[&"base"]))
	assert_eq(
		listed, _expected_candidates(WEAPON_SLOT, 1),
		"the owned lane is exactly the owned weapons that fit W2 (family + fit_legal)"
	)
	assert_true(not listed.has(&"p_std"), "a non-weapon module never lists on a W cell")


## The exact set the profile owns that can slot in one cell: the catalogue's modules of the
## cell's family, owned, whose candidate fit is legal - the same `fit_legal` the pane reads.
func _expected_candidates(slot_key: StringName, index: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var fit: Dictionary = _panel.call(&"_resolved_fit", _profile, VANGUARD)
	for key: Variant in ModuleData.MODULES:
		var base := StringName(str(key))
		if ModuleData.fit_slot_of(base) != slot_key:
			continue
		if (_profile.call(&"instances_of", base) as Array).is_empty():
			continue
		var candidate: Dictionary = fit.duplicate(true)
		var cells: Array = candidate.get(WEAPON_SLOT, [])
		while cells.size() <= index:
			cells.append("")
		cells[index] = String(base)
		candidate[WEAPON_SLOT] = cells
		if bool(FitData.fit_legal(VANGUARD, candidate)[&"legal"]):
			out.append(base)
	return out


## --------------------------------------------------- 4. BUY on a buyable row (P38)


func test_buy_on_a_buyable_row_buys_then_fits() -> void:
	_settle()
	assert_true(bool(_panel.call(&"select_cell", ENGINE_SLOT, 0)), "the engine cell selects")
	var ids: Array[StringName] = _panel.call(&"module_row_ids")
	assert_true(ids.has(&"e_ion"), "an engine that fits the cell lists")
	assert_false(ids.has(LASER), "a weapon never lists on an E cell (P38's cell filter)")
	for module_id: StringName in ids:
		assert_eq(
			ModuleData.fit_slot_of(module_id), ENGINE_SLOT,
			"every listed module is the cell's own family"
		)
	var before := int(_profile.call(&"credits"))
	var payload: Dictionary = {}
	for entry: Dictionary in _panel.get(&"_browser_payloads"):
		if StringName(entry[&"base"]) == &"e_ion":
			payload = entry
			break
	assert_true(not payload.is_empty(), "the e_ion row is built")
	if payload.is_empty():
		return
	_panel.call(&"_on_buy_pressed", payload)
	assert_true(int(_profile.call(&"credits")) < before, "BUY charged the catalogue's price")
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_eq(
		StringName(String((fit.get(ENGINE_SLOT, []) as Array)[0])), &"e_ion",
		"and fitted the module into the selected cell"
	)


## --------------------------------------------- 5. the rack drag persists (P34)


func test_a_rack_drag_persists_through_the_battery_record() -> void:
	_settle()
	_profile.call(&"add_module", CANNON, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, CANNON)), "a cannon fits W2"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "one barrel per rack"
	)
	_panel.call(&"refresh_profile", &"batteries")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var payload: Dictionary = _panel.call(&"drag_barrel", 1, 0)
	assert_true(not payload.is_empty(), "B2's cannon drags")
	assert_true(
		bool(_panel.call(&"drop", 0, PanelScript.DROP_RACK_BODY, payload)),
		"and drops onto B1's body"
	)
	assert_eq(
		_profile.call(&"battery_groups", VANGUARD), [[0, 1]],
		"the rack record persisted the regroup"
	)


## ------------------------------------------------ 6. the empty rows (P34, 09 section 10)


func test_the_empty_cells_read_read_only_w_n_empty() -> void:
	_settle()
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var rows := _panel.get_node("%EmptyRows") as VBoxContainer
	assert_eq(rows.get_child_count(), 2, "the Vanguard's W2 and W3 hold nothing")
	assert_eq(
		String((rows.get_child(0) as Label).text), "W2 — EMPTY", "the first empty cell reads its line"
	)
	assert_eq(
		String((rows.get_child(1) as Label).text), "W3 — EMPTY", "and the second"
	)
	for child: Node in rows.get_children():
		assert_true(child is Label, "every empty-cell row is a read-only Label, never a control")
	assert_eq(
		String((_panel.get_node("%EmptyCaption") as Label).text), "EMPTY CELLS - 2",
		"and the caption counts them"
	)


## ------------------------------------------- 7. the salvo meters and the cycle (P34)


func test_the_salvo_meter_and_cycle_are_the_slowest_member() -> void:
	_settle()
	_profile.call(&"add_module", CANNON, 1)
	_profile.call(&"add_module", ROCKET, 1)
	_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, CANNON)
	_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, ROCKET)
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1, 2]])
	_panel.call(&"refresh_profile", &"batteries")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var rows: Array = _panel.call(&"rack_rows")
	assert_eq(
		String(rows[1][&"salvo"]),
		PanelScript.RACK_SALVO % WeaponComponent.interval_of(&"rocket"),
		"the mixed rack's line is the rocket's own cycle, its slowest member"
	)
	var figure := int(round(WeaponComponent.interval_of(&"rocket") * 100.0))
	var readout: Dictionary = _panel.call(&"salvo_readout", 1)
	assert_eq(int(readout[&"figure"]), figure, "and the drum reads the rocket's hundredths")
	assert_eq(String(readout[&"text"]), "%04d" % figure, "as four zero-padded cells")


## ----------------------------------------------------- 8. the EQ container (P39)


func test_the_eq_container_lists_the_non_weapon_categories_with_counts() -> void:
	_settle()
	_profile.call(&"add_module", &"p_std", 2)
	_profile.call(&"add_module", &"e_ion", 1)
	_panel.call(&"refresh_profile", &"modules")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var tabs := _panel.get_node("%EqTabs") as HBoxContainer
	var labels: Array[String] = []
	for child: Node in tabs.get_children():
		labels.append((child as Button).text)
	assert_true(labels.has("AMMUNITION"), "the EQ container carries the AMMUNITION category")
	assert_true(labels.has("PWR/FUEL RODS"), "and the PWR/FUEL RODS category (P39)")
	assert_true(labels.has("DRIVES"), "and the other browser families")
	assert_eq(
		StringName(_panel.call(&"active_eq_tab")), PanelScript.EQ_TAB_AMMO,
		"AMMUNITION is the landing category"
	)
	var rows := _panel.get_node("%ArmoryRows") as VBoxContainer
	assert_eq(
		rows.get_child_count(), Catalog.AMMO_PACKS.size(),
		"the AMMUNITION category draws the shipped pack cards"
	)
	## A module category lists the owned modules as count rows.
	_panel.call(&"select_eq_tab", &"power")
	_settle()
	assert_eq(
		StringName(_panel.call(&"active_eq_tab")), &"power", "the PWR category is in force"
	)
	rows = _panel.get_node("%ArmoryRows") as VBoxContainer
	assert_true(rows.get_child_count() >= 1, "the owned power module lists")
	var first := rows.get_child(0) as Control
	var count := first.get_node_or_null(NodePath("RowInner/RowBox/Count")) as Label
	assert_true(count != null, "a count row ships (P39)")
	if count != null:
		assert_eq(count.text, PanelScript.EQ_COUNT_FORMAT % 2, "and carries its ×n count")
	assert_true(
		first.get_node_or_null(NodePath("RowInner/RowBox/InspectChip")) != null,
		"with its INSPECT chip (P39)"
	)
	var caption := String((_panel.get_node("%AmmoCaption") as Label).text)
	assert_true(caption.begins_with("PWR/FUEL RODS"), "and the caption names the category")


## ---------------------------------- 9. no wide blocks, no foot band (P38/P39, grep + probe)


func test_no_fits_here_or_buyable_wide_block_and_no_foot_band() -> void:
	var source := FileAccess.get_file_as_string("res://ui/station/armory_panel.gd")
	var scene := FileAccess.get_file_as_string("res://ui/station/armory_panel.tscn")
	for word: String in ["FITS HERE", "BUYABLE THAT FITS"]:
		assert_true(
			scene.find(word) == -1,
			"the pane's scene carries no '%s' wide block (P38)" % word
		)
	for symbol: String in ["FITS_HERE_CAPTION", "BUYABLE_CAPTION", "BUYABLE_EMPTY", "BUYABLE_NONE"]:
		assert_true(
			source.find(symbol) == -1,
			"the pane's script retires the '%s' block (P38)" % symbol
		)
	assert_true(scene.find("FootBand") == -1, "the scene carries no P36 foot band (P39)")
	assert_true(scene.find("InventoryRows") == -1, "and no FITS HERE list node (P38)")
	for node_name: String in ["%FootBand", "%InventoryRows", "%InventoryScroll", "%InventoryCaption"]:
		assert_true(
			_panel.get_node_or_null(NodePath(node_name)) == null,
			"%s is gone (P38/P39)" % node_name
		)


## ------------------------------------------------- 10. row containment (P40)


func test_every_row_control_lands_inside_the_window() -> void:
	_settle()
	for key: Variant in ModuleData.MODULES:
		var base := StringName(str(key))
		if ModuleData.fit_slot_of(base) == WEAPON_SLOT:
			_profile.call(&"add_module", base, 1)
	_panel.call(&"refresh_profile", &"modules")
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 1)), "W2 selects")
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	assert_true(rows.get_child_count() > 0, "the longest weapon names are listed")
	_assert_rows_scroll_contained(
		rows, _panel.get_node("%BrowserScroll") as ScrollContainer, "the list"
	)
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	_assert_rows_scroll_contained(
		_panel.get_node("%ArmoryRows") as VBoxContainer,
		_panel.get_node("%AmmoScroll") as ScrollContainer, "the EQ container"
	)


## P40's containment, measured against the row's own **scroll viewport**: every row must fit
## its viewport's width (the 160 px trim law) and ride the `ScrollContainer`.
func _assert_rows_scroll_contained(
	rows: VBoxContainer, scroll: ScrollContainer, label: String
) -> void:
	var viewport := scroll.get_global_rect()
	for child: Node in rows.get_children():
		var row := child as Control
		if row == null:
			continue
		var rect := row.get_global_rect()
		assert_true(
			rect.position.x >= viewport.position.x - 1.0 and rect.end.x <= viewport.end.x + 1.0,
			"the %s row %s fits its scroll viewport (x %.1f..%.1f, viewport %.1f..%.1f)" % [
				label, String(row.name), rect.position.x, rect.end.x,
				viewport.position.x, viewport.end.x
			]
		)
		assert_true(
			scroll.is_ancestor_of(row),
			"and the %s row %s is scroll-contained (reachable, never clipped)" % [
				label, String(row.name)
			]
		)


## --------------------------------------------- select-to-fit and drag-to-fit (P38)


func test_a_owned_row_fits_by_press_and_by_drag() -> void:
	_settle()
	_profile.call(&"add_module", CANNON, 1)
	_profile.call(&"add_module", CANNON, 1)
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 1)), "W2 selects")
	## Select-to-fit: the row's own press composes the fit into the selected cell.
	_panel.call(&"_on_fits_here_pressed", CANNON)
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_eq(
		StringName(String((fit.get(WEAPON_SLOT, []) as Array)[1])), CANNON,
		"the row's press fitted the held instance into W2"
	)
	## Drag-to-fit: a list payload lands on the grid cell through `cell_drop`.
	assert_true(bool(_profile.call(&"clear_fit_slot", VANGUARD, WEAPON_SLOT, 1)), "W2 empties")
	var cell := {&"type": WEAPON_SLOT, &"token": "W", &"index": 1}
	var payload: Dictionary = _panel.call(&"drag_inventory", CANNON)
	assert_true(bool(_panel.call(&"cell_can_drop", cell, payload)), "a list drag reaches the cell")
	_panel.call(&"cell_drop", cell, payload)
	fit = _profile.call(&"fit_for", VANGUARD)
	assert_eq(
		StringName(String((fit.get(WEAPON_SLOT, []) as Array)[1])), CANNON,
		"and the drag fitted it into W2"
	)


## ------------------------------------------ 11. bands + the 160 px trim (P40)


func test_every_list_wears_its_band_and_the_160_px_trim() -> void:
	_settle()
	for base: StringName in [LASER, CANNON]:
		_profile.call(&"add_module", base, 1)
	_panel.call(&"refresh_profile", &"modules")
	_settle()
	var browser_band := _panel.get_node("%BrowserBand") as HBoxContainer
	assert_true(browser_band.get_child_count() >= 2, "the one list wears its band (P40)")
	var words := _band_words(browser_band)
	assert_true(
		words.has(PanelScript.BAND_MODULE) and words.has(PanelScript.BAND_STATE)
			and words.has(PanelScript.BAND_COST),
		"with the row stacks' own words (%s)" % str(words)
	)
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	assert_true(rows.get_child_count() > 0, "the browse list draws rows")
	for child: Node in rows.get_children():
		var title_box := (child as Control).get_node_or_null(
			NodePath("RowInner/RowBox/TitleBox")
		) as Control
		assert_true(title_box != null, "every row carries its title column")
		assert_eq(title_box.custom_minimum_size.x, 160.0, "at the N45 160 px trim column")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var eq_band := _panel.get_node("%EqBand") as HBoxContainer
	assert_true(eq_band.get_child_count() >= 2, "the EQ container wears its band (P40)")
	var eq_words := _band_words(eq_band)
	assert_true(
		eq_words.has(PanelScript.EQ_BAND_EQUIPMENT) and eq_words.has(PanelScript.EQ_BAND_COUNT),
		"with the equipment/count words (%s)" % str(eq_words)
	)
	var eq_rows := _panel.get_node("%ArmoryRows") as VBoxContainer
	for child: Node in eq_rows.get_children():
		var row := child as Control
		var title_box := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox")) as Control
		if title_box == null:
			continue
		assert_eq(title_box.custom_minimum_size.x, 160.0, "the EQ rows trim at 160 too (P40)")


## A band's own caption words, in order.
func _band_words(band: HBoxContainer) -> Array[String]:
	var out: Array[String] = []
	for cell: Node in band.get_children():
		if cell is Label:
			out.append((cell as Label).text)
	return out


## --------------------------------------------------------- 12. no presets (P35)


func test_no_preset_or_save_surface_ships() -> void:
	var source := FileAccess.get_file_as_string("res://ui/station/armory_panel.gd")
	for word: String in ["loadout", "save_battery", "battery_set", "load_battery", "preset_row"]:
		assert_true(
			source.findn(word) == -1,
			"the pane's script carries no '%s' surface (P35)" % word
		)
	var scene := FileAccess.get_file_as_string("res://ui/station/armory_panel.tscn")
	for word: String in ["Preset", "Loadout", "SaveBattery"]:
		assert_true(
			scene.find(word) == -1,
			"the pane's scene carries no '%s' node (P35)" % word
		)


## --------------------------------------------------------- the row read-back helpers


func _row_tag(row: Node) -> String:
	var tag := (row as Control).get_node_or_null(NodePath("RowInner/RowBox/Tag")) as Label
	return tag.text if tag != null else ""


func _row_legal(row: Node) -> String:
	var legal := (row as Control).get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Legal")) as Label
	return legal.text if legal != null else ""


func _tags_of(rows: VBoxContainer) -> Array[String]:
	var out: Array[String] = []
	for child: Node in rows.get_children():
		var tag := _row_tag(child)
		if not tag.is_empty() and not out.has(tag):
			out.append(tag)
	return out


func _tag_of_base(rows: VBoxContainer, base: StringName) -> String:
	var wanted := "Module%s" % String(base).to_pascal_case()
	for child: Node in rows.get_children():
		if child.name == wanted:
			return _row_tag(child)
	return ""


func _read_of_base(rows: VBoxContainer, base: StringName) -> String:
	var wanted := "Module%s" % String(base).to_pascal_case()
	for child: Node in rows.get_children():
		if child.name == wanted:
			var read := (child as Control).get_node_or_null(NodePath("RowInner/RowBox/Read")) as Label
			return read.text if read != null else ""
	return ""


func _first_row_with_tag(rows: VBoxContainer, tag: String) -> Control:
	for child: Node in rows.get_children():
		if _row_tag(child) == tag:
			return child as Control
	return null


func _payload_of(rows: VBoxContainer, base: StringName) -> Dictionary:
	var wanted := "Module%s" % String(base).to_pascal_case()
	for child: Node in rows.get_children():
		if child.name == wanted:
			return (child as Control).get(&"payload")
	return {}
