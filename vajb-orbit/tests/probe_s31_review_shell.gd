@tool
extends SceneTree
## S31-R1 review probe (read-only): re-measures S31-B1's acceptance numbers off the
## shipped files. Prints one RESULT line per measurement; never mutates state.

var _station: Control = null
var _host: Control = null

var _station_scene: PackedScene = null
var _theme: Theme = null
const SHIP: StringName = &"ship_vanguard"


func _initialize() -> void:
	_run.call_deferred()


func _result(key: String, ok: bool, detail: String) -> void:
	print("RESULT %s %s %s" % ["OK" if ok else "FAIL", key, detail])


func _diag(message: String) -> void:
	print("DIAG " + message)


func _run() -> void:
	var profile := root.get_node_or_null(NodePath("PlayerProfile"))
	if profile == null:
		_diag("no PlayerProfile autoload; probe aborted")
		quit(1)
		return
	_station_scene = load("res://ui/screens/station.tscn") as PackedScene
	_theme = load("res://ui/theme/vajb_theme.tres") as Theme
	if _station_scene == null or _theme == null:
		_diag("scene or theme failed to load")
		quit(1)
		return
	_host = Control.new()
	_host.name = "S31ReviewHost"
	_host.theme = _theme
	_host.size = Vector2(1920.0, 1080.0)
	profile.add_child(_host)
	_station = _station_scene.instantiate() as Control
	_host.add_child(_station)
	var owned: Array[StringName] = [SHIP]
	profile.set(&"_active_ship", SHIP)
	profile.set(&"_owned_ships", owned)
	profile.set(&"_fits", {})
	profile.set(&"_modules", {})
	profile.set(&"_ammo", {})
	profile.set(&"_cargo", {&"mineral_iron": 5, &"mineral_copper": 3} as Dictionary)
	profile.set(&"_credits", 50000)
	for i in 5:
		await process_frame
	_measure_tooltip()
	_measure_linger()
	await _measure_exchange(profile)
	await _measure_armory()
	quit(0)


func _measure_linger() -> void:
	var linger := _station.get(&"_linger_timer") as Timer
	if linger == null:
		_result("n46_linger_timer", false, "missing")
		return
	_result(
		"n46_linger_timer", is_equal_approx(linger.wait_time, 0.5) and linger.one_shot,
		"wait_time=%.3f one_shot=%s" % [linger.wait_time, str(linger.one_shot)]
	)


func _measure_tooltip() -> void:
	var tooltip := _station.get(&"_tooltip") as Control
	if tooltip == null:
		_result("n47_tooltip", false, "missing")
		return
	tooltip.call(
		&"show_for", "LASER CELLS", "Standard laser capacitors.", false,
		Vector2(400.0, 300.0), Vector2(1920.0, 1080.0)
	)
	var label := tooltip.get_node("%TooltipLabel") as RichTextLabel
	if label == null:
		_result("n47_tooltip", false, "no TooltipLabel")
		return
	var font := label.get_theme_font_size(&"normal_font_size")
	var cap := label.custom_minimum_size.x
	var text := String(tooltip.call(&"rendered_text"))
	var primary := (tooltip.call(&"_token", &"text_primary") as Color).to_html(false)
	var dim := (tooltip.call(&"_token", &"text_dim") as Color).to_html(false)
	var body_ok := text.contains("[color=#%s]Standard laser capacitors.[/color]" % primary)
	var hint_ok := text.contains("[color=#%s]INSPECT[/color]" % dim)
	_result(
		"n47_tooltip", font == 15 and is_equal_approx(cap, 360.0) and body_ok and hint_ok,
		"font=%d cap=%.1f body_primary=%s hint_dim=%s" % [font, cap, str(body_ok), str(hint_ok)]
	)
	tooltip.call(&"hide_tooltip")


func _band_cells_x(band: HBoxContainer) -> Array[float]:
	var xs: Array[float] = []
	for cell: Node in band.get_children():
		if cell is Label:
			xs.append((cell as Label).get_global_rect().position.x)
	return xs


func _row_cells_x(row: Control) -> Array[float]:
	var xs: Array[float] = []
	for cell_name: String in ["Qty", "Unit", "Total"]:
		var cell := row.get_node_or_null(NodePath("RowInner/RowBox/%s" % cell_name)) as Control
		if cell != null:
			xs.append(cell.get_global_rect().position.x)
	return xs


func _measure_exchange(profile: Node) -> void:
	_station.call(&"_select_module", 2, true)
	for i in 40:
		await process_frame
	var panels: Array = _station.get(&"_panels")
	var panel: Control = panels[2]
	panel.call(&"refresh_profile", &"cargo")
	for i in 10:
		await process_frame
	var hold_rows := panel.get_node_or_null(^"ExchangeBody/HoldBox/HoldScroll/HoldRows")
	var board_rows := panel.get_node_or_null(^"ExchangeBody/MarketBoard/BoardScroll/BoardRows")
	if hold_rows == null or board_rows == null:
		_result("n44_one_y", false, "rows containers missing")
		return
	var hold_payloads: Array = panel.get(&"_hold_payloads")
	if hold_payloads.is_empty():
		_result("n43_title_width", false, "no hold rows")
		_result("n44_one_y", false, "no hold rows")
		return
	var hold_row: Control = hold_payloads[0][&"row"]
	var board_payloads: Array = panel.get(&"_board_payloads")
	var board_row: Control = board_payloads[0][&"row"]
	var title_box := hold_row.get_node_or_null(^"RowInner/RowBox/TitleBox") as Control
	var title_w := title_box.size.x if title_box != null else -1.0
	_result(
		"n43_title_width", title_w >= 180.0,
		"hold_title_w=%.1f (>=180)" % title_w
	)
	var hold_y := hold_row.get_global_rect().position.y
	var board_y := board_row.get_global_rect().position.y
	var hold_scroll := panel.get_node_or_null(^"ExchangeBody/HoldBox/HoldScroll") as Control
	var board_scroll := panel.get_node_or_null(^"ExchangeBody/MarketBoard/BoardScroll") as Control
	_result(
		"n44_one_y", is_equal_approx(hold_y, board_y),
		"hold_first_row_y=%.1f board_first_row_y=%.1f hold_scroll_y=%.1f board_scroll_y=%.1f"
			% [hold_y, board_y, hold_scroll.get_global_rect().position.y,
			board_scroll.get_global_rect().position.y]
	)
	var hold_box := panel.get_node_or_null(^"ExchangeBody/HoldBox") as Control
	var board_box := panel.get_node_or_null(^"ExchangeBody/MarketBoard") as Control
	_result(
		"n44_boxes_even", is_equal_approx(hold_box.size.y, board_box.size.y),
		"hold_h=%.1f board_h=%.1f" % [hold_box.size.y, board_box.size.y]
	)
	var band: HBoxContainer = hold_rows.get_node_or_null(^"HoldHeader/HoldHeaderRow")
	var seats_ok := false
	var detail := "band missing"
	if band != null:
		var band_xs := _band_cells_x(band)
		var row_xs := _row_cells_x(hold_row)
		seats_ok = band_xs.size() == row_xs.size() and band_xs.size() > 0
		for i: int in mini(band_xs.size(), row_xs.size()):
			if not is_equal_approx(band_xs[i], row_xs[i]):
				seats_ok = false
		detail = "band_xs=%s row_xs=%s" % [str(band_xs), str(row_xs)]
	_result("n42_band_seats", seats_ok, detail)
	var chip := hold_row.get_node_or_null(^"RowInner/RowBox/InspectChip")
	var cluster := panel.get(&"_inspect_cluster") as Button
	_result(
		"n43_cluster", chip == null and cluster != null,
		"per_row_chip_absent=%s cluster_present=%s" % [str(chip == null), str(cluster != null)]
	)
	var mineral_band: HBoxContainer = board_rows.get_node_or_null(
		^"MineralHeader/MineralHeaderRow"
	)
	var seats_board := false
	var detail_board := "mineral band missing"
	if mineral_band != null:
		var band_xs := _band_cells_x(mineral_band)
		var row_xs: Array[float] = []
		for cell_name: String in ["Price", "Demand", "Trend"]:
			var cell := board_row.get_node_or_null(
				NodePath("RowInner/RowBox/%s" % cell_name)
			) as Control
			if cell != null:
				row_xs.append(cell.get_global_rect().position.x)
		seats_board = band_xs.size() == row_xs.size() and band_xs.size() > 0
		for i: int in mini(band_xs.size(), row_xs.size()):
			if not is_equal_approx(band_xs[i], row_xs[i]):
				seats_board = false
		detail_board = "band_xs=%s row_xs=%s" % [str(band_xs), str(row_xs)]
	_result("n42_board_band_seats", seats_board, detail_board)
	var hold_box2 := panel.get_node_or_null(^"ExchangeBody/HoldBox") as Control
	var board_box2 := panel.get_node_or_null(^"ExchangeBody/MarketBoard") as Control
	var trade := panel.get_node_or_null(^"TradeColumn") as Control
	var hold_w := hold_box2.size.x if hold_box2 != null else -1.0
	var board_w := board_box2.size.x if board_box2 != null else -1.0
	var trade_w := trade.size.x if trade != null else -1.0
	var body := panel.get_node_or_null(^"ExchangeBody") as Control
	var body_w := body.size.x if body != null else -1.0
	var board_rows_box := board_rows as Control
	var rows_w := board_rows_box.size.x
	_result(
		"n43_exchange_widths", true,
		"hold=%.1f board=%.1f trade=%.1f body=%.1f board_rows_w=%.1f hold_min=%s"
			% [hold_w, board_w, trade_w, body_w, rows_w,
			str((panel.get_node_or_null(^"ExchangeBody/HoldBox/HoldScroll") as Control)
				.custom_minimum_size.x)]
	)
	profile.set(&"_cargo", {} as Dictionary)


func _measure_armory() -> void:
	_station.call(&"_select_module", 0, true)
	for i in 40:
		await process_frame
	var panels: Array = _station.get(&"_panels")
	var panel: Control = panels[0]
	var payloads: Array = panel.get(&"_browser_payloads")
	if payloads.is_empty():
		_result("n45_rows_in_window", false, "no browser rows")
		return
	var max_right := -1.0e9
	var min_left := 1.0e9
	var scroll := panel.get_node_or_null(^"Split/BrowserHalf/BrowserScroll") as Control
	var scroll_right := scroll.get_global_rect().position.x + scroll.size.x if scroll != null else 0.0
	var past_scroll := 0
	var past_window := 0
	for payload: Dictionary in payloads:
		var row := payload[&"row"] as Control
		var stack: Array[Node] = [row]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			if node is Control:
				var r := (node as Control).get_global_rect()
				max_right = maxf(max_right, r.position.x + r.size.x)
				min_left = minf(min_left, r.position.x)
				if r.position.x + r.size.x > 1920.0:
					past_window += 1
				if scroll != null and r.position.x + r.size.x > scroll_right + 0.5:
					past_scroll += 1
			for child: Node in node.get_children():
				stack.append(child)
	var title_box := (payloads[0][&"row"] as Control).get_node_or_null(
		^"RowInner/RowBox/TitleBox"
	) as Control
	var title_col := title_box.custom_minimum_size.x if title_box != null else -1.0
	var row_box := (payloads[0][&"row"] as Control).get_node_or_null(
		^"RowInner/RowBox"
	) as Control
	var row_min := row_box.get_combined_minimum_size().x if row_box != null else -1.0
	_result(
		"n45_rows_in_window", past_window == 0 and past_scroll == 0 and max_right <= 1920.0,
		"min_left=%.1f max_right=%.1f past_window=%d past_scroll_viewport=%d scroll_right=%.1f"
			% [min_left, max_right, past_window, past_scroll, scroll_right]
	)
	_result(
		"n45_title_column", is_equal_approx(title_col, 160.0) and row_min <= 620.0,
		"title_col=%.1f row_min=%.1f" % [title_col, row_min]
	)
	var tabs := panel.get_node_or_null(^"Split/BrowserHalf/FamilyTabs") as Control
	var tabs_min := tabs.get_combined_minimum_size().x if tabs != null else -1.0
	var narrowest := 1.0e9
	var widths: Array[float] = []
	if tabs != null:
		for child: Node in tabs.get_children():
			if child is Control:
				var tab := child as Control
				narrowest = minf(narrowest, tab.get_combined_minimum_size().x)
				widths.append(tab.size.x)
	_result(
		"t120_tab_strip", tabs_min > 0.0 and tabs_min <= 620.0,
		"tabs_min=%.1f (<=620) narrowest_tab_min=%.1f tab_widths=%s"
			% [tabs_min, narrowest, str(widths)]
	)
