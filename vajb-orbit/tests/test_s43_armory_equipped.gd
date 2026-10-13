@tool
extends McpTestSuite
## Suite s43_armory_equipped: wave S43's ARMORY equipped list (STATION_HUB section 23.4
## P49) and its two buy doors (UI_SPEC section 17 A4-A6). One row per acceptance item:
##   1. the third block under CELL INFO carries the `EQUIPPED — <n>/<slot count>` caption
##      (StationCaption), the counts re-derived from the matrix and the fit;
##   2. one row per fitted module in the grid's own cell order (09 section 8's matrix,
##      row-major), each carrying the cell id, the module's name, one stat line from the
##      catalogue's `effects` (the stat_line idiom) and the family glyph 24; empty cells
##      are not listed;
##   3. the rows wear the flat Tokens box (item_bg + 1 px metal_mid, inset 6) inside the
##      block's own ScrollContainer;
##   4. pressing a row selects that cell through the grid's own selection door
##      (`select_cell`), CELL INFO following - one selection, two views;
##   5. BATTERY CONFIG shows no list (the block rides FitCells);
##   6. the browser's module BUY opens the confirm dialog (A6's wording, the catalogue
##      row's own name and price) and the confirmed answer runs the existing buy path -
##      which can still refuse;
##   7. the ammo pack buy opens the same dialog with the pack's own name and price and
##      the confirmed answer runs `buy_ammo` (the refusal strip still works).
##
## The pane mounts the way the other armory suites mount it (the shipped scene, the
## shipped theme, the profile borrowed and handed back). The confirm door is watched
## through the pane's own `confirm_requested` signal - the shell overlay is not mounted
## here, so the suite answers through the seam's public `confirm_action` and never
## asserts the shell's own focus/ESC behaviour (that is station.gd's, already shipped).

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://test_s43_armory_equipped.cfg"
const VANGUARD: StringName = &"ship_vanguard"
const LASER: StringName = &"w_laser"
const REACTOR: StringName = &"p_std"
const SHIELD: StringName = &"s_light"
const ION: StringName = &"s_ion"
const ENGINE: StringName = &"e_ion"
const WINDOW := Vector2(1920.0, 1080.0)
## The seeded fit: the standard fit's own mandatory set minus the armour plate, so the
## fit is legal, every candidate previews legal and the block's list is fully determined.
const SEED_FIT := {
	&"engines": ["e_std"],
	&"weapons": ["w_laser"],
	&"power": "p_std",
	&"shields": ["s_light"],
}
const STACK_PATH := "ModeHost/FitCells/FitSectors/FitLeft/FitLeftBox/FitLeftInset/FitLeftStack"

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
var _confirms: Array[Dictionary] = []
var _statuses: Array[Array] = []


func suite_name() -> String:
	return "s43_armory_equipped"


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
	_confirms.clear()
	_statuses.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "S43ArmoryHost"
	_host.theme = ThemeRes
	_host.size = WINDOW
	_profile.add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"confirm_requested", _on_confirm_requested)
	_panel.connect(&"status_requested", _on_status_requested)


func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})
	_profile.set(&"_fits", {})
	_profile.call(&"set_fit", VANGUARD, SEED_FIT)


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _settle() -> void:
	_panel.call(&"_lay")


## S43-R0/F1's cure row: the cluster's BUY & FIT and a BUYABLE row's select-to-fit are
## acquisition doors too (A4's criterion) - the confirm opens, nothing charges before
## the answer, and the confirmed answer buys-then-fits through the existing path.
func test_f1_the_buy_fit_cluster_and_the_buyable_flow_are_doors() -> void:
	_settle()
	assert_true(bool(_panel.call(&"select_cell", &"engines", 0)), "the engine cell selects")
	_confirms.clear()
	## The cluster door: BUY & FIT on the focused buyable row.
	var focus: Dictionary = {}
	for entry: Dictionary in _panel.get(&"_browser_payloads"):
		if StringName(entry[&"base"]) == ENGINE:
			focus = entry
			break
	assert_true(not focus.is_empty(), "the ion row is the cluster's focused buyable")
	if focus.is_empty():
		return
	_panel.set(&"_browser_focused", focus)
	var cluster := _panel.get_node_or_null(NodePath("%BuyFitButton")) as Button
	assert_true(cluster != null, "the cluster's BUY & FIT button built")
	if cluster == null:
		return
	var before := int(_profile.call(&"credits"))
	cluster.pressed.emit()
	assert_eq(_confirms.size(), 1, "the cluster press opened exactly one confirm")
	assert_eq(int(_profile.call(&"credits")), before, "and charged nothing before the answer")
	if _confirms.is_empty():
		return
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_MODULE, ENGINE)
	assert_true(int(_profile.call(&"credits")) < before, "the confirmed answer charged")
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"engines", []) as Array)[0]),
		"e_ion", "and fitted the selected cell through the existing path"
	)
	## The flow door: a buyable row's select-to-fit. Shields are not a mandatory slot, so
	## the flow test fits there (engines cannot empty - `MANDATORY_SLOT_KEYS`): select S1,
	## restore its stock module, and press the ion row (a cell selected, the flow buys).
	assert_true(bool(_panel.call(&"select_cell", &"shields", 0)), "the shield cell selects")
	assert_true(bool(_profile.call(&"clear_fit_slot", VANGUARD, &"shields", 0)), "S1 empties")
	_profile.call(&"fit_module_at", VANGUARD, &"shields", 0, SHIELD)
	_confirms.clear()
	var row := _module_row_of(ION)
	assert_true(row != null, "the ion row built")
	if row == null:
		return
	row.pressed.emit()
	assert_eq(_confirms.size(), 1, "the buyable row's flow opened exactly one confirm")
	if _confirms.is_empty():
		return
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"shields", []) as Array)[0]),
		"s_light", "and nothing moved before the answer"
	)
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_MODULE, ION)
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"shields", []) as Array)[0]),
		"s_ion", "and the confirmed flow fitted the cell"
	)


func _on_confirm_requested(payload: Dictionary) -> void:
	_confirms.append(payload)


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append([message, danger])


func _node(path: String) -> Control:
	return _panel.get_node_or_null(NodePath(path)) as Control


## One hull cell's fitted entry, read the way the fit addressing reads it (09 section
## 4.5): POWER is one id, every other type indexes its array row-major.
func _fit_entry_of(fit: Dictionary, cell: Dictionary) -> String:
	if StringName(cell[&"type"]) == &"power":
		return String(fit.get(&"power", ""))
	var cells: Array = fit.get(StringName(cell[&"type"]), [])
	var index := int(cell[&"index"])
	if index < 0 or index >= cells.size():
		return ""
	return String(cells[index])


func _base_of(entry: String) -> StringName:
	return StringName(String(_profile.call(&"base_module_id", StringName(entry))))


func _module_name_of(base: StringName) -> String:
	return String(ModuleData.module(base).get(&"name", "")).to_upper()


func _equipped_row(index: int) -> Button:
	var rows := _panel.get_node("%EquippedRows") as VBoxContainer
	return rows.get_child(index) as Button


func _row_by_id(row_id: String) -> Button:
	var rows := _panel.get_node("%EquippedRows") as VBoxContainer
	for index: int in rows.get_child_count():
		if _row_cell_id(_equipped_row(index)) == row_id:
			return _equipped_row(index)
	return null


func _row_cell_id(row: Button) -> String:
	return String((row.get_node(NodePath("RowInner/RowBox/CellId")) as Label).text)


func _row_name(row: Button) -> String:
	return String((row.get_node(NodePath("RowInner/RowBox/ModuleName")) as Label).text)


func _row_stats(row: Button) -> Label:
	return row.get_node(NodePath("RowInner/RowBox/Stats")) as Label


## The seeded fit's expected equipped rows, re-derived from the matrix and the fit - the
## pin's own two sources, walked independently of the pane.
func _expected_rows() -> Array[Dictionary]:
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var out: Array[Dictionary] = []
	for cell: Dictionary in ShipFitScript.grid_cells(VANGUARD):
		if bool(cell[&"gap"]):
			continue
		var entry := _fit_entry_of(fit, cell)
		if entry.is_empty():
			continue
		var base := _base_of(entry)
		out.append({
			&"id": StringName("%s%d" % [String(cell[&"token"]), int(cell[&"index"]) + 1]),
			&"name": _module_name_of(base),
		})
	return out


func _module_row_of(base: StringName) -> Control:
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	for child: Node in rows.get_children():
		if child.name == "Module%s" % String(base).to_pascal_case():
			return child as Control
	return null


func _buy_chip_of(base: StringName) -> Button:
	var row := _module_row_of(base)
	if row == null:
		return null
	return row.get_node_or_null(NodePath("RowInner/RowBox/Buy")) as Button


func _ammo_card(pack_id: StringName) -> Control:
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	return rows.get_node_or_null(
		NodePath("Ammo%s" % String(pack_id).to_pascal_case())
	) as Control


func _card_price_text(card: Control) -> String:
	return String((card.get_node(NodePath("Price/Value")) as Label).text)


## ------------------------------------------------------------------ P49, items 1-2


func test_p49_the_block_sits_under_cell_info_with_its_caption() -> void:
	_settle()
	var stack := _node(STACK_PATH)
	var info := _panel.get_node("%CellInfoBlock") as Control
	var block := _panel.get_node("%EquippedBlock") as Control
	var caption := _panel.get_node("%EquippedCaption") as Label
	assert_true(
		stack != null and info != null and block != null and caption != null,
		"the equipped block mounts with its caption"
	)
	if stack == null or info == null or block == null or caption == null:
		return
	assert_true(stack.is_ancestor_of(block), "the block rides the left sector's stack")
	var children := stack.get_children()
	assert_true(
		children.find(block) > children.find(info),
		"the block is the third one, under CELL INFO"
	)
	assert_eq(
		caption.theme_type_variation, &"StationCaption",
		"the caption wears StationCaption (P49)"
	)
	var fitted := 0
	var total := 0
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	for cell: Dictionary in ShipFitScript.grid_cells(VANGUARD):
		if bool(cell[&"gap"]):
			continue
		total += 1
		if not _fit_entry_of(fit, cell).is_empty():
			fitted += 1
	assert_eq(
		caption.text, PanelScript.EQUIPPED_CAPTION % [fitted, total],
		"the caption counts the fitted cells against the hull's own cells (%d/%d)" % [
			fitted, total
		]
	)


func test_p49_one_row_per_fitted_module_in_the_grid_order() -> void:
	_settle()
	var rows := _panel.get_node("%EquippedRows") as VBoxContainer
	var expected := _expected_rows()
	assert_true(not expected.is_empty(), "the seeded fit equips something")
	assert_eq(
		rows.get_child_count(), expected.size(),
		"one row per fitted module, empty cells not listed"
	)
	if rows.get_child_count() != expected.size():
		return
	for index: int in expected.size():
		var row := _equipped_row(index)
		var want: Dictionary = expected[index]
		assert_eq(_row_cell_id(row), String(want[&"id"]), "row %d carries the grid's own id" % index)
		assert_eq(_row_name(row), String(want[&"name"]), "row %d carries the module's name" % index)
		assert_eq(
			(row.get_node(NodePath("RowInner/RowBox/CellId")) as Label).theme_type_variation,
			&"StationValue", "the cell id wears StationValue"
		)
		assert_eq(
			(row.get_node(NodePath("RowInner/RowBox/ModuleName")) as Label).theme_type_variation,
			&"StationValue", "the name wears StationValue"
		)
		var icon := row.get_node_or_null(NodePath("RowInner/RowBox/Icon")) as TextureRect
		assert_true(icon != null, "row %d carries the family glyph" % index)
		if icon != null:
			assert_eq(
				icon.custom_minimum_size, Vector2(24.0, 24.0),
				"and the glyph sits at its own 24 cut"
			)
	## The stat line: the catalogue's effects through the stat_line idiom - a shield
	## reads its two effects joined, the drive its multiplier line, the reactor its
	## zero-add percent, and a weapon (no effects dict) carries no line at all.
	assert_eq(
		_row_stats(_row_by_id("S1")).text, "SHIELD +200 · REGEN +4",
		"the shield's stat line is the effect column through the stat_line idiom"
	)
	assert_eq(
		_row_stats(_row_by_id("E1")).text, "SPEED ×1.0",
		"the drive's stat line is the idiom's multiplier branch"
	)
	assert_eq(
		_row_stats(_row_by_id("P1")).text, "POWER +0 %",
		"the reactor's stat line is its own add"
	)
	assert_false(_row_stats(_row_by_id("W1")).visible, "a weapon row carries no stat line")


func test_p49_the_rows_wear_the_flat_tokens_box_in_their_own_scroll() -> void:
	_settle()
	var block := _panel.get_node("%EquippedBlock") as Control
	var scroll := _panel.get_node("%EquippedScroll") as ScrollContainer
	var rows := _panel.get_node("%EquippedRows") as VBoxContainer
	assert_true(
		block != null and scroll != null and rows != null,
		"the block carries its own scroll and rows"
	)
	if block == null or scroll == null or rows == null:
		return
	assert_true(block.is_ancestor_of(scroll), "the scroll rides the block")
	assert_eq(
		scroll.get(&"horizontal_scroll_mode"), ScrollContainer.SCROLL_MODE_DISABLED,
		"the list never scrolls sideways"
	)
	assert_eq(
		scroll.get(&"size_flags_vertical"), Control.SIZE_EXPAND_FILL,
		"the list takes the sector's slack, so overflow is the scroll's"
	)
	var row := _equipped_row(0)
	assert_true(row != null, "a row exists to wear the idiom")
	if row == null:
		return
	var normal := row.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_true(normal != null, "the row's rest chrome is a flat stylebox")
	if normal == null:
		return
	var style: Resource = _panel.get(&"_style")
	assert_true(style != null, "the pane's own style is installed")
	if style == null:
		return
	assert_eq(
		normal.bg_color, style.call(&"colour", &"item_bg"),
		"the row fills with item_bg"
	)
	assert_eq(
		normal.border_color, style.call(&"colour", &"metal_mid"),
		"the row borders with metal_mid"
	)
	assert_eq(normal.border_width_left, 1, "the border is the 1 px flat Tokens border")
	assert_eq(
		(row.get_node(NodePath("RowInner")) as MarginContainer).get_theme_constant(&"margin_left"),
		6, "the row's content sits at the 6 px inset"
	)


## ------------------------------------------------------------------ P49, items 4-5


func test_p49_pressing_a_row_selects_its_cell() -> void:
	_settle()
	var row := _row_by_id("W1")
	assert_true(row != null, "the weapon row exists")
	if row == null:
		return
	row.pressed.emit()
	var selected: Dictionary = _panel.call(&"selected_cell")
	assert_eq(
		StringName(String(selected.get(&"type", ""))), &"weapons",
		"the press selected the row's own cell"
	)
	assert_eq(int(selected.get(&"index", -1)), 0, "and its layout index")
	assert_eq(
		String((_panel.get_node("%CellInfoId") as Label).text), "W1 · WEAPONS CELL",
		"CELL INFO follows the row (one selection, two views)"
	)
	assert_true(row.button_pressed, "the row itself shows the selection")
	var plate := _panel.get_node("%SlotLayoutGrid").get_node_or_null(
		NodePath("SlotW00")
	) as Button
	assert_true(plate != null and plate.button_pressed, "and so does the grid's own plate")
	## The other direction: a grid-made selection moves the rows with it.
	assert_true(bool(_panel.call(&"select_cell", &"power", 0)), "the reactor cell selects")
	assert_false(row.button_pressed, "the weapon row clears with the selection")
	assert_true(_row_by_id("P1").button_pressed, "the reactor row shows it")


func test_p49_battery_config_shows_no_list() -> void:
	_settle()
	var block := _panel.get_node("%EquippedBlock") as Control
	var cells := _panel.get_node("%FitCells") as Control
	assert_true(block != null and cells != null, "the block and its mode root exist")
	if block == null or cells == null:
		return
	assert_true(block.is_visible_in_tree(), "FIT CELLS shows the list")
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	assert_false(cells.visible, "the mode root itself hides")
	assert_false(block.is_visible_in_tree(), "BATTERY CONFIG shows no list")
	_panel.call(&"set_mode", PanelScript.MODE_FIT)
	_settle()
	assert_true(block.is_visible_in_tree(), "and FIT CELLS shows it again")


## ---------------------------------------------------------------- A4-A6, items 6-7


func test_a4_the_module_buy_door_opens_the_confirm() -> void:
	_settle()
	assert_true(bool(_panel.call(&"select_cell", &"engines", 0)), "the engine cell selects")
	var buy := _buy_chip_of(ENGINE)
	assert_true(buy != null, "the ion row carries its BUY chip")
	if buy == null:
		return
	var before := int(_profile.call(&"credits"))
	buy.pressed.emit()
	assert_eq(_confirms.size(), 1, "the press opened exactly one confirm")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	var row := _module_row_of(ENGINE)
	var name_text := String(
		(row.get_node(NodePath("RowInner/RowBox/TitleBox/Title")) as Label).text
	)
	var price_text := String(
		(row.get_node(NodePath("RowInner/RowBox/Read")) as Label).text
	).trim_suffix(" CR")
	assert_eq(String(payload[&"title"]), PanelScript.BUY_CONFIRM_TITLE, "A6's title")
	assert_eq(
		String(payload[&"body"]),
		"ARE YOU SURE YOU WANT TO BUY %s FOR %s CREDITS?" % [name_text, price_text],
		"A6's wording with the catalogue row's own name and price (%s)" % price_text
	)
	assert_eq(String(payload[&"confirm_text"]), "OK", "the confirm word is OK (A5)")
	assert_eq(String(payload[&"cancel_text"]), "CANCEL", "the cancel word is CANCEL (A5)")
	assert_eq(
		int(_profile.call(&"credits")), before,
		"nothing is charged before the answer"
	)
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"engines", []) as Array)[0]),
		"e_std", "and the cell still holds its module"
	)
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_MODULE, ENGINE)
	assert_true(int(_profile.call(&"credits")) < before, "the confirmed answer charged")
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"engines", []) as Array)[0]),
		"e_ion", "and fitted the selected cell through the existing path"
	)


func test_a5_a_confirmed_module_press_can_still_refuse() -> void:
	_settle()
	_profile.set(&"_credits", 0)
	_panel.call(&"refresh_profile", &"credits")
	assert_true(bool(_panel.call(&"select_cell", &"engines", 0)), "the engine cell selects")
	var buy := _buy_chip_of(ENGINE)
	assert_true(buy != null, "the unaffordable row still offers its BUY chip")
	if buy == null:
		return
	buy.pressed.emit()
	assert_eq(_confirms.size(), 1, "the door opens whatever the purse says")
	if _confirms.is_empty():
		return
	var statuses_before := _statuses.size()
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_MODULE, ENGINE)
	assert_true(_statuses.size() > statuses_before, "the refusal reached the strip")
	var price_text := String(
		(_module_row_of(ENGINE).get_node(NodePath("RowInner/RowBox/Read")) as Label).text
	).trim_suffix(" CR")
	assert_eq(
		String(_statuses.back()[0]),
		PanelScript.STATUS_SHORTFALL % price_text,
		"the strip carries section 5.6's own refusal wording"
	)
	assert_eq(
		String((_profile.call(&"fit_for", VANGUARD).get(&"engines", []) as Array)[0]),
		"e_std", "and the cell keeps its module"
	)


func test_a4_the_ammo_door_opens_the_confirm() -> void:
	_settle()
	_panel.call(&"select_tab", &"ammo")
	var card := _ammo_card(&"laser")
	assert_true(card != null, "the laser pack card built")
	if card == null:
		return
	var buy := card.get_node_or_null(NodePath("Buy")) as Button
	assert_true(buy != null, "the card carries its BUY chip")
	if buy == null:
		return
	var before := int(_profile.call(&"credits"))
	var ammo_before := int(_profile.call(&"ammo_units", &"laser"))
	buy.pressed.emit()
	assert_eq(_confirms.size(), 1, "the card's BUY opened exactly one confirm")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	var name_text := String((card.get_node(NodePath("Title")) as Label).text).to_upper()
	var price_text := _card_price_text(card).trim_suffix(" CR")
	assert_eq(
		String(payload[&"body"]),
		"ARE YOU SURE YOU WANT TO BUY %s (%d ROUNDS) FOR %s CREDITS?" % [
			name_text, 300, price_text
		],
		"A6's ammo wording, the pack's own name and price (%s)" % price_text
	)
	assert_eq(int(_profile.call(&"credits")), before, "nothing is charged before the answer")
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_AMMO, &"laser")
	assert_true(int(_profile.call(&"credits")) < before, "the confirmed answer charged")
	assert_true(
		int(_profile.call(&"ammo_units", &"laser")) > ammo_before,
		"and the rounds landed through the existing path"
	)


func test_a5_the_ammo_refusal_keeps_the_strip() -> void:
	_settle()
	_panel.call(&"select_tab", &"ammo")
	_profile.set(&"_credits", 1)
	_panel.call(&"refresh_profile", &"credits")
	var card := _ammo_card(&"plasma")
	assert_true(card != null, "the plasma pack card built")
	if card == null:
		return
	var buy := card.get_node_or_null(NodePath("Buy")) as Button
	assert_true(buy != null, "the unaffordable card still offers its BUY chip")
	if buy == null:
		return
	var ammo_before := int(_profile.call(&"ammo_units", &"plasma"))
	var credits_before := int(_profile.call(&"credits"))
	buy.pressed.emit()
	assert_eq(_confirms.size(), 1, "the door opened")
	if _confirms.is_empty():
		return
	_panel.call(&"confirm_action", PanelScript.ACTION_BUY_AMMO, &"plasma")
	assert_eq(int(_profile.call(&"credits")), credits_before, "the refused answer charged nothing")
	assert_eq(
		int(_profile.call(&"ammo_units", &"plasma")), ammo_before,
		"and bought nothing"
	)
	for entry: Dictionary in _panel.get(&"_payloads"):
		if StringName(entry[&"id"]) != &"plasma":
			continue
		var plate: Node = entry[&"plate"]
		assert_true(bool(plate.get(&"_danger")), "the card wears the section 3.1b danger frame")
		break
