@tool
extends McpTestSuite
## Suite s45_craft: the CRAFT tab's crafting model and list (07 section 6 C1-C10,
## STATION_HUB section 23.6 P52). One row per acceptance item:
##   1. `CraftingCatalog` is the four-recipe table, verbatim: ids/names/inputs (id ->
##      count) exactly 07 section 6.2's, the fees exactly 2 500 / 3 000 / 2 800 /
##      4 000 (C4), every fee over the 2 000 CR floor;
##   2. C8's `scrap_value` derives 50 % of the recipe materials round down, priced at
##      the live 02/03 baselines (the 07 section 6.3 derivations re-derived);
##   3. the commit consumes every input from the hold, pays the fee, grants the
##      output module through the shipped `add_module` seam, and writes one
##      economy-log line;
##   4. the commit is all-or-nothing: a missing input or a short purse refuses and
##      writes nothing; an unknown recipe refuses;
##   5. the refusal names the first short input with its shortfall, in recipe order;
##   6. the CRAFT list wears the AUCTION idiom: the RECIPE / INPUTS / FEE / STATE
##      column band, Button rows with the output name + stat line, the `<n>× <name>`
##      runs with the 24 px glyph at its own cut, the fee value + CR LABOUR caption,
##      the C3 CRAFT chip;
##   7. the state chips read `cargo_qty`: READY / MISSING <n>× <input>;
##   8. the row press opens the N28 sheet with the recipe's full bill;
##   9. the CRAFT chip opens the A4 door (8) confirm (CONFIRM PURCHASE, A6's craft
##      wording); the confirmed answer runs the transaction unchanged and can still
##      refuse on the section 5.6 strip;
##  10. the CRAFT hint is the reserved cell's content and the NOTHING TO CRAFT empty
##      state renders when the table is unreachable.
##
## The suite borrows the PlayerProfile autoload the way `test_s45_refinery.gd` does
## (`save_path` repointed at a scratch file, every borrowed field handed back in
## `suite_teardown`), mounts the shipped panel scene ONCE, keeps `profile_changed`
## disconnected and drives fresh state through silent field writes plus one
## `refresh_profile(&"cargo")` rebuild - the message-queue discipline V0's report
## disclosed (the gate now carries the developer's 64 MB bump). The transaction rows
## run on a throwaway `player_profile.gd` instance the way the refinery model rows
## do.

const PanelScene := preload("res://ui/station/refinery_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Craft := preload("res://game/crafting_catalog.gd")
const MineralData := preload("res://game/mineral_catalog.gd")
const ComponentData := preload("res://game/component_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "s45_craft"
const SCRATCH_PROFILE := "user://test_s45_craft.cfg"
const SCRATCH_LOG := "user://test_s45_craft_economy.txt"
const MODEL_SAVE := "user://test_s45_craft_model.cfg"
const MODEL_LOG := "user://test_s45_craft_model_log.txt"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const REACTOR: StringName = &"p_core_mk3"
const LATTICE: StringName = &"s_lattice"
const RAIL: StringName = &"c_rail_refit"
const SCANNER: StringName = &"c_deep_scanner"
const MECH_2: StringName = &"comp_mech_2"
const POW_2: StringName = &"comp_pow_2"
const INGOT_COBALT: StringName = &"ingot_cobalt"
const ORE_2: StringName = &"comp_ore_2"
const WEAP_2: StringName = &"comp_weap_2"
const ELEC_3: StringName = &"comp_elec_3"
const INGOT_TUNGSTEN: StringName = &"ingot_tungsten"
const VOIDGLASS: StringName = &"ingot_voidglass"

var _model: Node = null
var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_log_path := ""
var _previous_refinery: Dictionary = {}
var _statuses: Array[Array] = []
var _confirms: Array[Dictionary] = []
var _sheets: Array[Dictionary] = []


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the account the pane reads")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_log_path = Log.log_path
	_previous_refinery = {
		&"slots": _profile.call(&"refinery_slots"),
		&"input": _profile.call(&"refinery_input"),
		&"output": _profile.call(&"refinery_output"),
		&"jobs": _profile.call(&"refinery_jobs"),
		&"next_id": _profile.call(&"refinery_next_job_id"),
	}
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


func suite_teardown() -> void:
	_free_host()
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_refinery_slots", int(_previous_refinery[&"slots"]))
	_profile.set(&"_refinery_input", _previous_refinery[&"input"])
	_profile.set(&"_refinery_output", _previous_refinery[&"output"])
	_profile.set(&"_refinery_jobs", _previous_refinery[&"jobs"])
	_profile.set(&"_refinery_next_job_id", int(_previous_refinery[&"next_id"]))
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Log.log_path = _previous_log_path
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	_profile = null


func setup() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	_seed_account()
	Log.log_path = SCRATCH_LOG
	_statuses.clear()
	_confirms.clear()
	_sheets.clear()
	if _panel == null or not is_instance_valid(_panel):
		_mount_panel()


func teardown() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	_delete_file(MODEL_SAVE)
	_delete_file(MODEL_LOG)


## ------------------------------------------------- AC1: the recipe table (C2/C3/C4)


func test_c2_the_table_is_the_four_recipes() -> void:
	var recipes: Array[Dictionary] = Craft.recipes()
	assert_eq(recipes.size(), 4, "C9's four crafted-only recipes, no more")
	var ids: Array[StringName] = []
	for recipe: Dictionary in recipes:
		ids.append(StringName(recipe[&"id"]))
		assert_true(recipe.has(&"name"), "%s carries a name" % recipe[&"id"])
		assert_true(recipe.has(&"inputs"), "%s carries inputs" % recipe[&"id"])
		assert_true(recipe.has(&"fee"), "%s carries a fee" % recipe[&"id"])
		assert_true(recipe.has(&"output"), "%s carries an output" % recipe[&"id"])
		assert_true(recipe.has(&"description"), "%s carries a description" % recipe[&"id"])
		var output: Dictionary = recipe[&"output"]
		assert_false(StringName(output.get(&"module", &"")) == &"",
			"%s's output carries its module id" % recipe[&"id"])
		assert_false(String(output.get(&"effect", "")).is_empty(),
			"%s's output carries its effect" % recipe[&"id"])
	assert_eq(ids, [REACTOR, LATTICE, RAIL, SCANNER], "07 section 6.2's rows in order")
	assert_eq(int(Craft.recipe(REACTOR)[&"fee"]), 2500, "C4's first fee")
	assert_eq(int(Craft.recipe(LATTICE)[&"fee"]), 3000, "C4's second fee")
	assert_eq(int(Craft.recipe(RAIL)[&"fee"]), 2800, "C4's third fee")
	assert_eq(int(Craft.recipe(SCANNER)[&"fee"]), 4000, "C4's fourth fee")
	assert_eq(Craft.recipe(REACTOR)[&"inputs"], {MECH_2: 2, POW_2: 1, INGOT_COBALT: 6},
		"section 6.2's reactor bill")
	assert_eq(Craft.recipe(LATTICE)[&"inputs"], {ORE_2: 1, &"ingot_cerulite": 3, &"comp_elec_2": 2},
		"section 6.2's lattice bill")
	assert_eq(Craft.recipe(RAIL)[&"inputs"], {WEAP_2: 2, INGOT_TUNGSTEN: 4},
		"section 6.2's rail bill")
	assert_eq(Craft.recipe(SCANNER)[&"inputs"], {ELEC_3: 1, VOIDGLASS: 5},
		"section 6.2's scanner bill")
	for recipe: Dictionary in recipes:
		assert_true(int(recipe[&"fee"]) >= Craft.MIN_FEE,
			"%s clears the 2 000 CR sink floor (07 section 5 K7)" % recipe[&"id"])
	assert_true(Craft.recipe(&"no_such_recipe").is_empty(), "an unknown id answers empty")


## ------------------------------------------------- AC6: the scrap derivation (C8)


func test_c8_scrap_value_is_half_the_materials() -> void:
	assert_eq(Craft.materials_value(Craft.recipe(REACTOR)[&"inputs"]), 1078,
		"07 section 6.3's reactor derivation (2x45 + 1x40 + 6x158)")
	assert_eq(Craft.materials_value(Craft.recipe(LATTICE)[&"inputs"]), 1876,
		"07 section 6.3's lattice derivation (1x60 + 3x572 + 2x50)")
	assert_eq(Craft.materials_value(Craft.recipe(RAIL)[&"inputs"]), 830,
		"07 section 6.3's rail derivation (2x55 + 4x180)")
	assert_eq(Craft.materials_value(Craft.recipe(SCANNER)[&"inputs"]), 3740,
		"07 section 6.3's scanner derivation (1x120 + 5x724)")
	assert_eq(Craft.scrap_value(Craft.recipe(REACTOR)), 539, "half of 1 078, round down")
	assert_eq(Craft.scrap_value(Craft.recipe(LATTICE)), 938, "half of 1 876, round down")
	assert_eq(Craft.scrap_value(Craft.recipe(RAIL)), 415, "half of 830, round down")
	assert_eq(Craft.scrap_value(Craft.recipe(SCANNER)), 1870, "half of 3 740, round down")
	for recipe: Dictionary in Craft.recipes():
		@warning_ignore("integer_division")
		var half_value: int = Craft.materials_value(recipe[&"inputs"]) / 2
		assert_eq(
			Craft.scrap_value(recipe),
			half_value,
			"%s's scrap is 50 %% of its materials (10 section 3.3)" % recipe[&"id"]
		)


## ------------------------------------------- AC5: the commit consumes, pays, grants


func test_c10_the_commit_consumes_pays_and_grants() -> void:
	_model = _make_model()
	_model.add_cargo(MECH_2, 2)
	_model.add_cargo(POW_2, 1)
	_model.add_cargo(INGOT_COBALT, 6)
	_model.set(&"_credits", 10000)
	var before := int(_model.call(&"credits"))
	var result: Dictionary = Craft.craft(_model, REACTOR)
	assert_true(bool(result[&"ok"]), "a covered bill crafts")
	assert_eq(StringName(result[&"recipe_id"]), REACTOR, "the answer names the recipe")
	assert_eq(StringName(result[&"module"]), REACTOR, "the answer names the output module")
	assert_eq(int(result[&"fee"]), 2500, "the answer carries the fee")
	assert_eq(int(_model.call(&"credits")), before - 2500, "the labour fee left the balance")
	assert_eq(int(_model.call(&"cargo_qty", MECH_2)), 0, "every input left the hold")
	assert_eq(int(_model.call(&"cargo_qty", POW_2)), 0, "the second input left the hold")
	assert_eq(int(_model.call(&"cargo_qty", INGOT_COBALT)), 0, "the third input left the hold")
	assert_eq(int(_model.call(&"module_count", REACTOR)), 1,
		"the output module entered the bag through `add_module`")
	assert_true(FileAccess.file_exists(MODEL_LOG), "the success wrote the economy log")
	assert_true(FileAccess.get_file_as_string(MODEL_LOG).contains("CRAFT"),
		"the one transaction line is the CRAFT event")


## ------------------------------------------------------ AC5: all-or-nothing (01 §7)


func test_c10_the_commit_is_all_or_nothing() -> void:
	_model = _make_model()
	_model.add_cargo(MECH_2, 2)
	_model.add_cargo(POW_2, 1)
	_model.set(&"_credits", 10000)
	var before := int(_model.call(&"credits"))
	var result: Dictionary = Craft.craft(_model, REACTOR)
	assert_false(bool(result[&"ok"]), "a short bill refuses")
	assert_eq(StringName(result[&"reason"]), Craft.REASON_INSUFFICIENT_MATERIALS,
		"reason insufficient_materials")
	assert_eq(int(_model.call(&"cargo_qty", MECH_2)), 2, "the hold kept its inputs")
	assert_eq(int(_model.call(&"credits")), before, "no credits moved on a refusal")
	assert_eq(int(_model.call(&"module_count", REACTOR)), 0, "no module was granted")
	_delete_file(MODEL_LOG)
	assert_false(FileAccess.file_exists(MODEL_LOG), "a refusal logs nothing")
	## A covered bill with a short purse refuses the same way.
	_model.add_cargo(INGOT_COBALT, 6)
	_model.set(&"_credits", 10)
	var short := int(_model.call(&"credits"))
	result = Craft.craft(_model, REACTOR)
	assert_false(bool(result[&"ok"]), "a short purse refuses")
	assert_eq(StringName(result[&"reason"]), Craft.REASON_INSUFFICIENT_CREDITS,
		"reason insufficient_credits")
	assert_eq(int(result[&"fee"]), 2500, "the refusal carries the fee it needed")
	assert_eq(int(_model.call(&"cargo_qty", INGOT_COBALT)), 6, "the hold kept its inputs")
	assert_eq(int(_model.call(&"credits")), short, "no craft charge moved")
	assert_eq(int(_model.call(&"module_count", REACTOR)), 0, "no module was granted")
	## An id outside the table refuses as unknown.
	result = Craft.craft(_model, &"no_such_recipe")
	assert_false(bool(result[&"ok"]), "an unknown recipe refuses")
	assert_eq(StringName(result[&"reason"]), Craft.REASON_UNKNOWN_RECIPE,
		"reason unknown_recipe")


## ------------------------------------------- AC5: the refusal names the short input


func test_c10_the_refusal_names_the_missing_input() -> void:
	_model = _make_model()
	_model.add_cargo(MECH_2, 2)
	_model.add_cargo(POW_2, 1)
	_model.add_cargo(INGOT_COBALT, 4)
	_model.set(&"_credits", 10000)
	var missing := Craft.first_missing(_model, Craft.recipe(REACTOR))
	assert_eq(StringName(missing[&"id"]), INGOT_COBALT, "the short input is the cobalt ingot")
	assert_eq(int(missing[&"count"]), 2, "the shortfall is 2 (6 needed, 4 held)")
	var result: Dictionary = Craft.craft(_model, REACTOR)
	assert_false(bool(result[&"ok"]), "the craft refuses")
	assert_eq(StringName(result[&"missing_id"]), INGOT_COBALT, "the refusal names the input")
	assert_eq(int(result[&"missing_count"]), 2, "the refusal carries the shortfall")
	## The first short input in the recipe's own order wins the name.
	var lattice := Craft.recipe(LATTICE)
	missing = Craft.first_missing(_model, lattice)
	assert_eq(StringName(missing[&"id"]), ORE_2,
		"the lattice's first input is the one the hold lacks")
	assert_eq(int(missing[&"count"]), 1, "its whole count is missing")
	assert_false(Craft.first_missing(_model, Craft.recipe(REACTOR)).is_empty(),
		"the refusal wrote nothing: the reactor still reads short")


## ------------------------------------------- AC2: the list wears the AUCTION idiom


func test_p52_the_craft_chip_opens_the_confirm_door() -> void:
	var panel := _panel
	_profile.set(&"_cargo", {MECH_2: 2, POW_2: 1, INGOT_COBALT: 6})
	_profile.set(&"_credits", 10000)
	panel.call(&"refresh_profile", &"cargo")
	var chip := _craft_row(panel, REACTOR).get_node_or_null(NodePath("RowInner/RowBox/CraftChip")) as Button
	assert_true(chip != null, "the row carries its CRAFT chip")
	if chip == null:
		return
	assert_eq(String(chip.text), "CRAFT", "the chip's word")
	assert_eq(String(chip.get_meta(&"chrome_class", "")), "C3", "the ActionInline chrome")
	chip.pressed.emit()
	assert_eq(_confirms.size(), 1, "the chip opened one confirm request")
	if _confirms.is_empty():
		return
	var payload: Dictionary = _confirms[0]
	assert_eq(String(payload[&"title"]), "CONFIRM PURCHASE", "A6's title")
	assert_eq(
		String(payload[&"body"]),
		"ARE YOU SURE YOU WANT TO CRAFT REACTOR MK3 FOR 2× GENERATOR BLOCK · 1× CAPACITOR BANK · 6× COBALT INGOT + 2 500 CR LABOUR?",
		"A6's craft wording with the bill run idiom"
	)
	assert_eq(String(payload[&"confirm_text"]), "OK", "the OK answer")
	assert_eq(String(payload[&"cancel_text"]), "CANCEL", "the CANCEL answer")
	assert_eq(StringName(payload[&"action"]), &"craft_recipe", "the door's action")
	assert_eq(StringName(payload[&"id"]), REACTOR, "the door names the recipe")
	## The confirmed answer runs the transaction unchanged on the borrowed account.
	var before := int(_profile.call(&"credits"))
	panel.call(&"confirm_action", StringName(payload[&"action"]), StringName(payload[&"id"]))
	assert_eq(int(_profile.call(&"credits")), before - 2500, "the fee left the balance")
	assert_eq(int(_profile.call(&"cargo_qty", INGOT_COBALT)), 0, "the inputs left the hold")
	assert_eq(int(_profile.call(&"module_count", REACTOR)), 1, "the module entered the bag")
	assert_eq(_statuses.size(), 1, "the confirmed run reported once")
	if _statuses.size() == 1:
		assert_false(bool(_statuses[0][1]), "a success is not a danger line")
		assert_eq(String(_statuses[0][0]), "CRAFTED · REACTOR MK3", "the status wording")
	## The confirmed press can still refuse: the drained hold names the missing input
	## on the section 5.6 strip - the brief's own worked shortfall.
	_statuses.clear()
	_confirms.clear()
	_profile.set(&"_cargo", {MECH_2: 2, POW_2: 1, INGOT_COBALT: 4})
	chip.pressed.emit()
	assert_eq(_confirms.size(), 1, "the chip opened the door again")
	if _confirms.size() < 1:
		return
	panel.call(
		&"confirm_action",
		StringName(_confirms[0][&"action"]),
		StringName(_confirms[0][&"id"])
	)
	assert_eq(int(_profile.call(&"module_count", REACTOR)), 1, "no second module was granted")
	assert_eq(int(_profile.call(&"cargo_qty", INGOT_COBALT)), 4, "the hold kept its ingots")
	assert_eq(_statuses.size(), 1, "the refusal answered on the strip")
	if _statuses.size() == 1:
		assert_true(bool(_statuses[0][1]), "a refusal is a danger line")
		assert_eq(
			String(_statuses[0][0]),
			"REFUSED · MISSING 2× COBALT INGOT",
			"the strip names the missing input with its shortfall"
		)


func test_p52_the_empty_state_and_the_hint() -> void:
	var panel := _panel
	panel.call(&"set_mode", &"craft")
	var footer := panel.get_node_or_null(NodePath("%PaneFooter")) as Label
	assert_eq(
		String(footer.text), "EVERY INPUT IS CONSUMED ON CRAFT · THE FEE IS LABOUR",
		"P52's hint is the reserved cell's content"
	)
	var body := panel.get_node_or_null(NodePath("%CraftBody")) as Control
	var rows := panel.get_node_or_null(NodePath("%CraftRows")) as VBoxContainer
	var header := panel.get_node_or_null(NodePath("%CraftHeader")) as Control
	var empty := panel.get_node_or_null(NodePath("%CraftEmpty")) as Label
	assert_true(body.visible and rows.visible and not empty.visible,
		"the live table renders the list, not the caption")
	## The unreachable-table branch (C9 keeps it unreachable in production): the
	## section 19.4 empty-state idiom alone.
	var none: Array[Dictionary] = []
	panel.call(&"_build_craft_from", none)
	assert_true(empty.visible, "the empty state renders")
	assert_eq(String(empty.text), "NOTHING TO CRAFT", "the pinned wording")
	assert_false(rows.visible and header.visible, "the list and its band stand down")
	assert_eq(rows.get_child_count(), 0, "no rows under the caption")
	panel.call(&"_build_craft")
	assert_true(rows.visible and not empty.visible, "the live table returns the list")
	assert_eq(rows.get_child_count(), 5, "the four recipe rows plus the slack")
	panel.call(&"set_mode", &"refine")


func test_p52_the_list_wears_the_auction_idiom() -> void:
	var panel := _panel
	panel.call(&"refresh_profile", &"cargo")
	var header := panel.get_node_or_null(NodePath("%CraftHeader")) as HBoxContainer
	assert_true(header != null, "the column-header band ships")
	if header == null:
		return
	var words: Array[String] = []
	for child: Node in header.get_children():
		var label := child as Label
		words.append(label.text if label != null else "")
	assert_eq(words, ["RECIPE", "INPUTS", "FEE", "STATE", ""],
		"the four pinned columns, the chip's seat unnamed")
	var rows := panel.get_node_or_null(NodePath("%CraftRows")) as VBoxContainer
	var buttons: Array[Button] = []
	for child: Node in rows.get_children():
		var button := child as Button
		if button != null:
			buttons.append(button)
	assert_eq(buttons.size(), 4, "one row per recipe (C9)")
	var row := _craft_row(panel, REACTOR)
	assert_eq(row.custom_minimum_size.y, 76.0, "the AUCTION row height")
	assert_eq(String(row.get_meta(&"chrome_class", "")), "C4", "the C4 row strip chrome")
	var title := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Title")) as Label
	var meta := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Meta")) as Label
	assert_eq(String(title.text), "Reactor Mk3", "the output name")
	assert_eq(String(meta.text), "+4 POWER OUTPUT", "the output's stat line, upper-cased")
	assert_eq(
		title.text_overrun_behavior,
		TextServer.OVERRUN_TRIM_ELLIPSIS,
		"N45's trim law on the title"
	)
	var runs := row.get_node_or_null(NodePath("RowInner/RowBox/InputsBox")) as HBoxContainer
	assert_eq(runs.get_child_count(), 3, "one run per input")
	var first := runs.get_child(0) as HBoxContainer
	var glyph := first.get_node_or_null(NodePath("Glyph")) as TextureRect
	var run_label := first.get_node_or_null(NodePath("RunLabel")) as Label
	assert_eq(glyph.custom_minimum_size, Vector2(24.0, 24.0), "the family glyph at its own cut")
	assert_eq(glyph.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
		"the glyph never stretches")
	assert_eq(String(run_label.text), "2× GENERATOR BLOCK", "the <n>× <name> run idiom")
	var fee_value := row.get_node_or_null(NodePath("RowInner/RowBox/FeeBox/Value")) as Label
	var fee_caption := row.get_node_or_null(NodePath("RowInner/RowBox/FeeBox/Caption")) as Label
	assert_eq(String(fee_value.text), "2 500", "the fee, house-grouped")
	assert_eq(String(fee_caption.text), "CR LABOUR", "the fee's labour caption")
	var state_chip := row.get_node_or_null(NodePath("RowInner/RowBox/State/StateChip")) as PanelContainer
	var state_box := state_chip.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_true(state_box != null, "the state chip carries its own flat box")
	if state_box != null:
		assert_eq(state_box.border_color, panel.call(&"_token", &"metal_mid"), "the 1 px frame")
		assert_eq(state_box.bg_color, panel.call(&"_token", &"armory_chip_bg"), "the chip fill")
		assert_eq(state_box.border_width_left, 1, "the frame is 1 px")
	var chip := row.get_node_or_null(NodePath("RowInner/RowBox/CraftChip")) as Button
	assert_eq(chip.custom_minimum_size, Vector2(96.0, 32.0), "the ActionInline size")
	assert_eq(chip.focus_mode, Control.FOCUS_NONE, "the row stays the focus unit")
	var scanner_row := _craft_row(panel, SCANNER)
	var scanner_meta := scanner_row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Meta")) as Label
	assert_eq(String(scanner_meta.text), "+45 % SCANNER RANGE", "C6's scanner effect")
	var rail_meta := _craft_row(panel, RAIL).get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Meta")) as Label
	assert_eq(String(rail_meta.text), "KINETIC WEAPONS +25 % DAMAGE", "C6's rail effect")


func test_p52_the_row_press_opens_the_bill_sheet() -> void:
	var panel := _panel
	var row := _craft_row(panel, REACTOR)
	row.pressed.emit()
	assert_eq(_sheets.size(), 1, "the row press opened one sheet request")
	if _sheets.is_empty():
		return
	var payload: Dictionary = _sheets[0]
	assert_eq(String(payload[&"name"]), "Reactor Mk3", "the sheet's name row")
	assert_eq(
		String(payload[&"stats"]),
		"INPUTS · 2× GENERATOR BLOCK · 1× CAPACITOR BANK · 6× COBALT INGOT\nFEE · 2 500 CR LABOUR\nOUTPUT · +4 POWER OUTPUT",
		"the recipe's full bill, read-only"
	)
	assert_false(payload.has(&"price") or payload.has(&"owned"),
		"rows appear only where the data carries them (N35)")
	## The keyboard route (N34): the focused row's station_inspect opens the same sheet.
	_sheets.clear()
	panel.call(&"set_mode", &"craft")
	panel.call(&"focus_primary")
	panel.call(&"inspect_focused")
	assert_eq(_sheets.size(), 1, "the focused row's inspect opens the bill")
	panel.call(&"set_mode", &"refine")


func test_p52_the_state_chips_read_the_hold() -> void:
	var panel := _panel
	panel.call(&"refresh_profile", &"cargo")
	var texts := _chip_texts(panel)
	assert_eq(texts[0], "MISSING 2× GENERATOR BLOCK", "the reactor's first short input")
	assert_eq(texts[1], "MISSING 1× LATTICE SEED", "the lattice's first short input")
	assert_eq(texts[2], "MISSING 2× EMITTER HOUSING", "the rail's first short input")
	assert_eq(texts[3], "MISSING 1× NEURAL CORE", "the scanner's first short input")
	## The reactor's own bill lands in the hold: its chip flips to READY, the rest
	## still name their own first short input.
	_profile.set(&"_cargo", {MECH_2: 2, POW_2: 1, INGOT_COBALT: 6})
	panel.call(&"refresh_profile", &"cargo")
	texts = _chip_texts(panel)
	assert_eq(texts[0], "READY", "a covered bill reads READY")
	assert_eq(texts[1], "MISSING 1× LATTICE SEED", "the neighbours keep their own reads")
	## A partial stack still reads short, with the shortfall not the need.
	_profile.set(&"_cargo", {MECH_2: 1, POW_2: 1, INGOT_COBALT: 6})
	panel.call(&"refresh_profile", &"cargo")
	texts = _chip_texts(panel)
	assert_eq(texts[0], "MISSING 1× GENERATOR BLOCK", "the shortfall is what the chip names")


## ------------------------------------------------------------------------- helpers


func _make_model() -> Node:
	_delete_file(MODEL_LOG)
	var model: Node = load("res://autoload/player_profile.gd").new()
	model.save_path = MODEL_SAVE
	Log.log_path = MODEL_LOG
	return model


## A fresh account, written straight into the borrowed fields (the s44/s45 idiom):
## the setter doors emit per write, and this suite's shared pane pays one rebuild
## per test instead of one per field.
func _seed_account() -> void:
	var owned: Array[StringName] = [&"ship_vanguard"]
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", &"ship_vanguard")
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_refinery_slots", 2)
	_profile.set(&"_refinery_input", {})
	_profile.set(&"_refinery_output", {})
	_profile.set(&"_refinery_jobs", [])
	_profile.set(&"_refinery_next_job_id", 1)


func _mount_panel() -> void:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S45CraftHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		_fixture_host().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	## `profile_changed` stays DISCONNECTED for this suite (the s45 idiom): every
	## transaction this suite drives would otherwise rebuild the whole pane through
	## the signal, and the gate's one-frame window has no headroom for that churn.
	## Every row here reads the profile's own fields or the captured signals.
	_panel.connect(&"status_requested", _on_status_requested)
	_panel.connect(&"confirm_requested", _on_confirm_requested)
	_panel.connect(&"sheet_requested", _on_sheet_requested)


func _free_host() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _craft_row(panel: Control, recipe_id: StringName) -> Button:
	var rows := panel.get_node_or_null(NodePath("%CraftRows")) as VBoxContainer
	if rows == null:
		return null
	for child: Node in rows.get_children():
		var button := child as Button
		if button != null and StringName(button.get_meta(&"id", &"")) == recipe_id:
			return button
	return null


func _chip_texts(panel: Control) -> Array[String]:
	var texts: Array[String] = []
	var rows := panel.get_node_or_null(NodePath("%CraftRows")) as VBoxContainer
	if rows == null:
		return texts
	for child: Node in rows.get_children():
		var button := child as Button
		if button == null:
			continue
		var label := button.get_node_or_null(NodePath("RowInner/RowBox/State/StateChip/ChipLabel")) as Label
		if label != null:
			texts.append(String(label.text))
	return texts


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append([message, danger])


func _on_confirm_requested(payload: Dictionary) -> void:
	_confirms.append(payload)


func _on_sheet_requested(payload: Dictionary) -> void:
	_sheets.append(payload)


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
