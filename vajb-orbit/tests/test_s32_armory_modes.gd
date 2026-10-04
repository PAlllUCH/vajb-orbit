@tool
extends McpTestSuite
## Suite s32_armory_modes: wave S32's ARMORY two-module rework (STATION_HUB section 20.1
## P32-P37). One row per pinned acceptance:
##   1. P32 - the two full-screen modes behind the header switch, exactly one visible.
##   2. P33 - the CELL INFO block, FITS HERE (owned, family + fit_legal filtered),
##      BUYABLE THAT FITS (filtered to the cell) and its BUY.
##   3. P34 - B1-B5 racks over fitted weapons, a drag between racks persisting through the
##      profile's battery record, the read-only `W<n> — EMPTY` rows and the SALVO/cycle.
##   4. P35 - no preset/save surface (a grep row).
##   5. P36 - AMMUNITION + the PWR meter in the shared foot band on both modes, no BodyScroll.
##   6. P37 - every row's controls inside the 1920x1080 window, longest names included.
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


## --------------------------------------------------------- 3. FITS HERE (P33.2)


func test_fits_here_lists_exactly_the_legal_owned_candidates() -> void:
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
		"FITS HERE is exactly the owned weapons that fit W2 (family + fit_legal)"
	)
	assert_true(not listed.has(&"p_std"), "a non-weapon module never lists on a W cell")
	## Every row is a drag source and the list is the mode's own full-width column.
	assert_true(
		not (_panel.call(&"drag_inventory", LASER) as Dictionary).is_empty(),
		"each FITS HERE row drags its own base id"
	)
	var caption := String((_panel.get_node("%InventoryCaption") as Label).text)
	assert_eq(caption, PanelScript.FITS_HERE_CAPTION % listed.size(), "and the caption counts them")


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


## --------------------------------------------------- 4. BUYABLE THAT FITS (P33.3)


func test_buyable_that_fits_filters_and_buys() -> void:
	_settle()
	assert_true(bool(_panel.call(&"select_cell", ENGINE_SLOT, 0)), "the engine cell selects")
	var ids: Array[StringName] = _panel.call(&"module_row_ids")
	assert_true(ids.has(&"e_ion"), "an engine that fits the cell lists")
	assert_false(ids.has(LASER), "a weapon never lists on an E cell (P33's cell filter)")
	for module_id: StringName in ids:
		assert_eq(
			ModuleData.fit_slot_of(module_id), ENGINE_SLOT,
			"every listed module is the cell's own family"
		)
	## BUY on the row buys-then-fits through the profile's own doors.
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


## ------------------------------------------------- 5. the rack drag persists (P34)


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
	## The profile probe: the record itself moved (the drag writes the profile's own door,
	## `move_rack_cell`, which commits through `set_battery_groups`).
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


## --------------------------------------------- 8. the shared foot band (P36)


func test_the_foot_band_is_shared_by_both_modes() -> void:
	_settle()
	var band := _panel.get_node("%FootBand") as Control
	assert_true(band.visible, "the foot band shows in FIT CELLS")
	assert_eq(
		String((_panel.get_node("%AmmoMargin") as Control).get_parent().name), "FootBand",
		"and AMMUNITION rides it"
	)
	assert_true(
		String((_panel.get_node("%MeterLabel") as Label).text).begins_with("PWR "),
		"with the PWR meter"
	)
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	assert_true(band.visible, "the same foot band shows in BATTERY CONFIG (P36: shared)")
	assert_true(
		String((_panel.get_node("%MeterLabel") as Label).text).begins_with("PWR "),
		"with the meter still live"
	)
	assert_true(_panel.get_node_or_null("%BodyScroll") == null, "and the BodyScroll fold is gone (P36)")


## ------------------------------------------------- 9. row containment (P37)


func test_every_row_control_lands_inside_the_window() -> void:
	_settle()
	for key: Variant in ModuleData.MODULES:
		var base := StringName(str(key))
		if ModuleData.fit_slot_of(base) == WEAPON_SLOT:
			_profile.call(&"add_module", base, 1)
	_panel.call(&"refresh_profile", &"modules")
	assert_true(bool(_panel.call(&"select_cell", WEAPON_SLOT, 1)), "W2 selects")
	var rows := _panel.get_node("%InventoryRows") as VBoxContainer
	assert_true(rows.get_child_count() > 0, "the longest weapon names are listed")
	_assert_rows_scroll_contained(
		rows, _panel.get_node("%InventoryScroll") as ScrollContainer, "FITS HERE"
	)
	var browser := _panel.get_node("%BrowserRows") as VBoxContainer
	_assert_rows_scroll_contained(
		browser, _panel.get_node("%BrowserScroll") as ScrollContainer, "BUYABLE"
	)


## P37's containment, measured against the row's own **scroll viewport** rather than the raw
## window: every row must fit its viewport's width (the 160 px trim law) and ride the
## `ScrollContainer`, so any vertical overflow scrolls and stays reachable, never clips.
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
			rect.position.x >= viewport.position.x and rect.end.x <= viewport.end.x,
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


## --------------------------------------------- 3b. select-to-fit and drag-to-fit (P33.2)


func test_a_fits_here_row_fits_by_press_and_by_drag() -> void:
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
	## Drag-to-fit: an inventory payload lands on the grid cell through `cell_drop`.
	assert_true(bool(_profile.call(&"clear_fit_slot", VANGUARD, WEAPON_SLOT, 1)), "W2 empties")
	var cell := {&"type": WEAPON_SLOT, &"token": "W", &"index": 1}
	var payload: Dictionary = _panel.call(&"drag_inventory", CANNON)
	assert_true(bool(_panel.call(&"cell_can_drop", cell, payload)), "a FITS HERE drag reaches the cell")
	_panel.call(&"cell_drop", cell, payload)
	fit = _profile.call(&"fit_for", VANGUARD)
	assert_eq(
		StringName(String((fit.get(WEAPON_SLOT, []) as Array)[1])), CANNON,
		"and the drag fitted it into W2"
	)


## --------------------------------------------------------- 4. no presets (P35)


## P35 (T-126): the editor composes the live fit only - no loadout presets, no save/load of
## battery sets. The pane's own script and scene carry no preset surface.
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
