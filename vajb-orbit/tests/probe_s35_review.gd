extends Node
## S35-R1's independent re-measurement (the acceptance list of `S35_BRIEF.md`, diffed
## against UI_SPEC section 14's N49 amendment and STATION_HUB section 21.1's P38a/P39a).
## Headless run under a scratch store:
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
##     res://tests/probe_s35_review.tscn --quit-after 900
##
## Prints `[r35]` lines and quits 0; the failure list is the review's evidence. It writes
## nothing else and never boots the owner's live profile.

const ExchangeScene := preload("res://ui/station/exchange_panel.tscn")
const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const ArmoryScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const IRON: StringName = &"mineral_iron"
const WINDOW := Vector2(1920.0, 1080.0)

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _failures: Array[String] = []


func _ready() -> void:
	var watchdog := get_tree().create_timer(150.0)
	watchdog.timeout.connect(func() -> void:
		print("[r35] WATCHDOG quit")
		get_tree().quit(2)
	)
	_run.call_deferred()


func _run() -> void:
	_fixture()
	await _exchange_trade_column()
	_exchange_sell_moves()
	await _armory_shared_menu()
	await _armory_click_away()
	await _armory_actions_intact()
	print("[r35] failures=%d" % _failures.size())
	for line: String in _failures:
		print("[r35] FAIL %s" % line)
	print("[r35] DONE")
	get_tree().quit(0)


func _check(condition: bool, what: String) -> void:
	if not condition:
		_failures.append(what)
	print("[r35] %s %s" % ["ok  " if condition else "FAIL", what])


func _fixture() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		_failures.append("no PlayerProfile autoload")
		get_tree().quit(1)
		return
	_profile.set(&"save_path", "user://probe_s35_review.cfg")
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", [VANGUARD] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_profile.call(&"add_module", LASER, 2)
	_profile.call(&"add_module", CANNON, 1)
	_profile.call(&"add_cargo", IRON, 5)


func _mount(scene: PackedScene, host_name: String) -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	get_window().size = Vector2i(int(WINDOW.x), int(WINDOW.y))
	_host = Control.new()
	_host.name = host_name
	_host.theme = ThemeRes
	_host.size = WINDOW
	add_child(_host)
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)


## ------------------------------------------- AC1/AC2: the exchange trade column

func _exchange_trade_column() -> void:
	_mount(ExchangeScene, "S35ExchangeHost")
	await get_tree().process_frame
	var trade := _panel.get_node(NodePath("%TradeBox")) as Control
	_check(trade != null, "e0 the TradeBox ships")
	_check(
		trade.get_node_or_null(NodePath("StepperRow")) == null,
		"e1 no StepperRow in the trade column (the S33 duplicate died, N49-amended)"
	)
	var steppers := 0
	var quantity_row: Node = null
	for child: Node in trade.get_children():
		if child.get_node_or_null(NodePath("SellMinus")) != null \
				and child.get_node_or_null(NodePath("SellPlus")) != null:
			steppers += 1
			quantity_row = child
	_check(steppers == 1, "e2 exactly one quantity control (stepper rows=%d)" % steppers)
	if quantity_row != null:
		var max_chip := quantity_row.get_node_or_null(NodePath("SellMaxButton")) as Button
		var zero_chip := quantity_row.get_node_or_null(NodePath("SellZeroButton")) as Button
		_check(
			max_chip != null and zero_chip != null
			and String(max_chip.text) == "MAX" and String(zero_chip.text) == "0",
			"e3 the MAX/0 chips ride the SELL UNITS row (P2 ActionInline beside it)"
		)
	var source := FileAccess.get_file_as_string("res://ui/station/exchange_panel.gd")
	var scene := FileAccess.get_file_as_string("res://ui/station/exchange_panel.tscn")
	_check(
		source.find("StepperRow") == -1 and scene.find("StepperRow") == -1
		and source.find("_set_step") == -1,
		"e4 grep: no second selector in the pane's script or scene"
	)
	## Bounds 0..row units (N49-amended: the floor is zero).
	_panel.call(&"_select", IRON)
	_panel.call(&"_set_sell_units", -5)
	_check(int(_panel.get(&"_sell_units")) == 0, "e5 the floor is zero units")
	_panel.call(&"_set_sell_units", 99)
	_check(int(_panel.get(&"_sell_units")) == 5, "e6 the ceiling is the row's own units")
	## MAX fills, 0 empties, SELL disabled at 0 and with no selection.
	var sell := _panel.get_node(NodePath("%SellButton")) as Button
	var max_chip := _panel.get_node(NodePath("%SellMaxButton")) as Button
	var zero_chip := _panel.get_node(NodePath("%SellZeroButton")) as Button
	_panel.call(&"_clear_selection")
	_check(
		sell.disabled and max_chip.disabled and zero_chip.disabled,
		"e7 with no selection SELL and both chips sit disabled"
	)
	_panel.call(&"_select", IRON)
	_panel.call(&"_on_sell_zero_pressed")
	_check(
		int(_panel.get(&"_sell_units")) == 0 and sell.disabled,
		"e8 the 0 chip empties and SELL disables"
	)
	_panel.call(&"_on_sell_max_pressed")
	_check(
		int(_panel.get(&"_sell_units")) == 5 and not sell.disabled,
		"e9 the MAX chip fills the row's units and SELL wakes"
	)
	await get_tree().process_frame
	var trade_min := (trade as Control).get_combined_minimum_size().x
	var sell_row := _panel.get_node(NodePath("%SellUnitsRow")) as Control
	var value_label := _panel.get_node(NodePath("%SellValue")) as Control
	print("[r35] measure trade_min=%.1f row_min=%.1f value_min=%.1f" % [
		trade_min, (sell_row as Control).get_combined_minimum_size().x,
		(value_label as Control).get_combined_minimum_size().x,
	])
	_check(
		trade_min >= 392.0,
		"e12 the trade column seats the stepper and both chips (min %.0f px)" % trade_min
	)
	var trade_rect := (trade as Control).get_global_rect()
	_check(
		trade_rect.position.x >= 0.0 and trade_rect.end.x <= WINDOW.x
		and sell_row.size.x <= (trade as Control).size.x + 0.5,
		"e13 the trade column lands inside the window, no clip (row %.0f of %.0f)" % [
			sell_row.size.x, (trade as Control).size.x
		]
	)


## ------------------------------------- AC2: a SELL press moves exactly the selector

func _exchange_sell_moves() -> void:
	var before_credits := int(_profile.call(&"credits"))
	var before_qty := int(_profile.call(&"cargo_qty", IRON))
	_panel.call(&"_set_sell_units", 3)
	var quoted_gross := int((_panel.get(&"_quoted") as Dictionary).get(&"gross", -1))
	(_panel.get_node(NodePath("%SellButton")) as Button).pressed.emit()
	var after_credits := int(_profile.call(&"credits"))
	var after_qty := int(_profile.call(&"cargo_qty", IRON))
	_check(
		before_qty - after_qty == 3,
		"e10 a SELL press moves exactly the selector value (%d -> %d)" % [before_qty, after_qty]
	)
	_check(
		after_credits > before_credits and quoted_gross > 0,
		"e11 the sale pays (credits +%d, quoted gross %d)" % [
			after_credits - before_credits, quoted_gross
		]
	)


## --------------------------------------------- AC4: one shared menu in both modes

func _tab_labels() -> Array[String]:
	var out: Array[String] = []
	for child: Node in (_panel.get_node(NodePath("%FamilyTabs")) as HBoxContainer).get_children():
		out.append(String((child as Button).text))
	return out


func _armory_shared_menu() -> void:
	_mount(ArmoryScene, "S35ArmoryHost")
	await get_tree().process_frame
	_panel.call(&"_lay")
	var menu := _panel.get_node_or_null(NodePath("%MenuSector")) as Control
	_check(menu != null, "a1 the one menu subtree ships")
	var fit_tabs := _tab_labels()
	_check(
		fit_tabs.size() == 10 and fit_tabs[0] == "AMMUNITION" and fit_tabs.has("POWER")
		and not fit_tabs.has("PWR/FUEL RODS") and not fit_tabs.has("HULLS"),
		"a2 the FIT CELLS category set (AMMUNITION leads, 10 tabs)"
	)
	_check(
		String(menu.get_parent().name) == "FitRight",
		"a3 the menu rides FIT CELLS' right sector"
	)
	_panel.call(&"set_mode", ArmoryScript.MODE_BATTERY)
	_panel.call(&"_lay")
	_check(
		String(menu.get_parent().name) == "EqSector",
		"a4 the SAME subtree rides BATTERY CONFIG's right sector"
	)
	_check(_tab_labels() == fit_tabs, "a5 the category set is identical in both modes")
	_panel.call(&"set_mode", ArmoryScript.MODE_FIT)
	_panel.call(&"_lay")
	_check(
		String(menu.get_parent().name) == "FitRight",
		"a6 and it rides back on the return switch"
	)
	var source := FileAccess.get_file_as_string("res://ui/station/armory_panel.gd")
	_check(
		source.find("_build_eq") == -1 and source.find("_refresh_eq") == -1
		and source.count("func _build_browser(") == 1,
		"a7 grep: one menu builder, the EQ builders gone"
	)


## ------------------------------------ AC3: click-away clears, controls keep theirs

func _armory_click_away() -> void:
	_panel.call(&"refresh_profile", &"modules")
	_panel.call(&"_lay")
	var rows := _panel.get_node(NodePath("%BrowserRows")) as VBoxContainer
	var payload := _payload_of(rows, LASER)
	_check(not payload.is_empty(), "b1 the laser row ships in the browse list")
	_panel.call(&"_on_browser_hovered", payload, true)
	_check(
		StringName(_panel.get(&"_candidate")) != &""
		or not (_panel.get(&"_focused_payload") as Dictionary).is_empty(),
		"b2 a hover preview is live"
	)
	_check(bool(_panel.call(&"select_cell", WEAPON_SLOT, 0)), "b3 W1 selects")
	_check(
		String((_panel.get_node(NodePath("%CellInfoId")) as Label).text)
		!= ArmoryScript.CELL_INFO_SELECT,
		"b4 CELL INFO names the selected cell"
	)
	_press_left((_panel as Control).get_global_rect().get_center())
	_check(
		(_panel.call(&"selected_cell") as Dictionary).is_empty(),
		"b5 the empty-chrome press clears the cell selection"
	)
	_check(
		StringName(_panel.get(&"_candidate")) == &""
		and (_panel.get(&"_focused_payload") as Dictionary).is_empty(),
		"b6 and the hover preview"
	)
	_check(
		String((_panel.get_node(NodePath("%CellInfoId")) as Label).text)
		== ArmoryScript.CELL_INFO_SELECT,
		"b7 CELL INFO returns to its select prompt"
	)
	_check(
		String((_panel.get_node(NodePath("%PaneHint")) as Label).text)
		== ArmoryScript.PANE_HINT_FIT,
		"b8 the hint returns to idle (P40)"
	)
	_press_left((_panel as Control).get_global_rect().get_center())
	_check(
		(_panel.call(&"selected_cell") as Dictionary).is_empty(),
		"b9 a second empty press stays idle"
	)
	_check(bool(_panel.call(&"select_cell", WEAPON_SLOT, 0)), "b10 W1 re-selects")
	_press_left((_panel as Control).get_global_rect().position - Vector2(64.0, 64.0))
	_check(
		not (_panel.call(&"selected_cell") as Dictionary).is_empty(),
		"b11 a press outside the pane's rect leaves the selection alone"
	)
	_panel.call(&"clear_selection")


## ------------------------- AC5: the modes' own actions through the public doors

func _armory_actions_intact() -> void:
	## FIT CELLS: a row press with a cell selected is the select-to-fit flow.
	_panel.call(&"refresh_profile", &"modules")
	_panel.call(&"_lay")
	_check(bool(_panel.call(&"select_cell", WEAPON_SLOT, 0)), "c1 W1 selects for the fit flow")
	var bag_before := int(_profile.call(&"module_count", LASER))
	var payload := _payload_of(_panel.get_node(NodePath("%BrowserRows")) as VBoxContainer, LASER)
	var row := payload.get(&"row", null) as Button
	if row != null and is_instance_valid(row):
		row.pressed.emit()
	var bag_after := int(_profile.call(&"module_count", LASER))
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	_check(
		bag_before - bag_after == 1
		and StringName(String((fit.get(WEAPON_SLOT, []) as Array)[0])) == LASER,
		"c2 a row press fits through the profile door (bag %d -> %d)" % [bag_before, bag_after]
	)
	var drag: Dictionary = _panel.call(&"drag_browser", payload)
	_check(
		String(drag.get(ArmoryScript.DRAG_KEY_KIND, "")) == String(ArmoryScript.DRAG_BROWSER)
		and StringName(drag.get(ArmoryScript.DRAG_KEY_BASE, &"")) == LASER,
		"c3 a FIT CELLS row drags the DRAG_BROWSER fit payload"
	)
	## BATTERY CONFIG: an owned weapon row drags the rack's own inventory payload and the
	## drop door installs it into the rack record.
	_panel.call(&"set_mode", ArmoryScript.MODE_BATTERY)
	_panel.call(&"_lay")
	var battery_drag: Dictionary = _panel.call(&"drag_browser", {&"base": CANNON, &"owned": true})
	_check(
		String(battery_drag.get(ArmoryScript.DRAG_KEY_KIND, ""))
		== String(ArmoryScript.DRAG_INVENTORY)
		and StringName(battery_drag.get(ArmoryScript.DRAG_KEY_BASE, &"")) == CANNON,
		"c4 a BATTERY CONFIG weapon row drags the DRAG_INVENTORY rack payload"
	)
	var installed := bool(_panel.call(&"install_weapon", 0, CANNON))
	var rack_fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var installed_ok := installed and (rack_fit.get(WEAPON_SLOT, []) as Array).has("w_cannon")
	_check(installed_ok, "c5 the rack's drop door installs the dragged weapon and persists it")
	_check(
		not (_profile.call(&"battery_groups", VANGUARD) as Array).is_empty(),
		"c6 the rack record covers the installed barrel"
	)
	_panel.call(&"set_mode", ArmoryScript.MODE_FIT)
	_panel.call(&"clear_selection")


func _press_left(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = at
	_panel.call(&"_unhandled_input", event)


func _payload_of(rows: VBoxContainer, base: StringName) -> Dictionary:
	var wanted := "Module%s" % String(base).to_pascal_case()
	for child: Node in rows.get_children():
		if child.name == wanted:
			return (child as Control).get(&"payload")
	return {}
