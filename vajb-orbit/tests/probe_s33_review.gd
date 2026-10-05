@tool
extends SceneTree
## S33-R1 review probe (read-only): re-measures S33-B1's acceptance items off the shipped
## files. Two sections: the ARMORY two-sector rework (P38-P40) and the exchange sell
## cluster (N48/N49). Prints RESULT lines only; exits 0 always (the reviewer reads the
## RESULT verdicts, not the exit code).

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
const SHIP: StringName = &"ship_vanguard"

func _initialize() -> void:
	_run.call_deferred()

func _result(key: String, ok: bool, detail: String) -> void:
	print("RESULT %s %s %s" % ["OK" if ok else "FAIL", key, detail])

func _diag(m: String) -> void:
	print("DIAG " + m)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	_profile = root.get_node_or_null(NodePath("PlayerProfile"))
	if _profile == null:
		_diag("no PlayerProfile autoload; probe aborted")
		quit(1)
		return
	var prev_path := String(_profile.get(&"save_path"))
	_profile.set(&"save_path", "user://probe_s33_review.cfg")
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})
	await _frames(5)

	var scene := load("res://ui/station/armory_panel.tscn") as PackedScene
	var theme := load("res://ui/theme/vajb_theme.tres") as Theme
	if scene == null or theme == null:
		_diag("scene or theme failed to load")
		quit(1)
		return
	_host = Control.new()
	_host.name = "S33ReviewHost"
	_host.theme = theme
	_host.size = Vector2(1920.0, 1080.0)
	_profile.add_child(_host)
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	await _frames(8)
	_panel.call(&"_lay")
	await _frames(3)

	# --- A1: FIT CELLS two equal sectors (P38), measured
	var left := _panel.get_node("%FitLeft") as Control
	var right := _panel.get_node("%FitRight") as Control
	var sectors := _panel.get_node("%FitSectors") as HBoxContainer
	_result("a1_fit_sectors_equal", left != null and right != null
		and absf(left.size.x - right.size.x) <= 1.0 and left.size.x > 0.0,
		"left=%s right=%s" % [str(left.size), str(right.size)])
	_result("a1_gutter_16", is_equal_approx(
			right.position.x - (left.position.x + left.size.x), 16.0),
		"gutter=%.1f" % (right.position.x - (left.position.x + left.size.x)))
	_result("a1_grid_left", left.is_ancestor_of(_panel.get_node("%SlotLayoutGrid"))
		and left.is_ancestor_of(_panel.get_node("%CellInfoId")), "grid+cellinfo left")
	_result("a1_list_right", right.is_ancestor_of(_panel.get_node("%BrowserRows"))
		and right.is_ancestor_of(_panel.get_node("%BrowserBand")), "list+band right")
	_result("a1_hint_fit_idle", String((_panel.get_node("%PaneHint") as Label).text)
		== "DRAG TO FIT - RIGHT-CLICK TO PULL - 1-5 SELECT RACK",
		"hint=%s" % String((_panel.get_node("%PaneHint") as Label).text))

	# --- A2: the browse state (no selection): FIT/STORED tags, press fits nothing
	# laser x2: one fitted (W0), one stays in the bag -> the row lists, tag FIT.
	# cannon x2: bag only -> tag STORED.
	# rocket x1: fitted (W2), none left in the bag -> P38's "everything the profile
	# owns" would list it; the bag-only read drops it (recorded as evidence).
	_profile.call(&"add_module", (&"w_laser") as StringName, 2)
	_profile.call(&"add_module", (&"w_cannon") as StringName, 2)
	_profile.call(&"add_module", (&"w_rocket") as StringName, 1)
	_profile.call(&"fit_module_at", SHIP, (&"weapons") as StringName, 0, (&"w_laser") as StringName)
	_profile.call(&"fit_module_at", SHIP, (&"weapons") as StringName, 2, (&"w_rocket") as StringName)
	_panel.call(&"refresh_profile", (&"modules") as StringName)
	await _frames(3)
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	var tags := {}
	var laser_tag := ""
	var cannon_tag := ""
	var rocket_present := false
	for child: Node in rows.get_children():
		var tag_label := (child as Control).get_node_or_null(
			NodePath("RowInner/RowBox/Tag")) as Label
		if tag_label == null:
			continue
		tags[String(tag_label.text)] = true
		var title := (child as Control).get_node_or_null(
			NodePath("RowInner/RowBox/TitleBox/Title")) as Label
		if title == null:
			continue
		var title_text := String(title.text)
		if title_text.find("LASER") != -1:
			laser_tag = String(tag_label.text)
		elif title_text.find("CANNON") != -1:
			cannon_tag = String(tag_label.text)
		elif title_text.find("ROCKET") != -1:
			rocket_present = true
	_result("a2_browse_tags", tags.has("FIT") and tags.has("STORED"),
		"tags=%s" % str(tags.keys()))
	_result("a2_fit_stored_meaning", laser_tag == "FIT" and cannon_tag == "STORED",
		"laser=%s cannon=%s" % [laser_tag, cannon_tag])
	_diag("fitted-only rocket in browse rows=%s (P38 says the profile owns it)" % str(rocket_present))
	var fit_before: Dictionary = _profile.call(&"fit_for", SHIP)
	_panel.call(&"_on_browser_pressed", (_panel.get(&"_browser_payloads") as Array)[0])
	await _frames(2)
	_result("a2_browse_press_inert", _profile.call(&"fit_for", SHIP) == fit_before,
		"browse press fitted nothing")

	# --- A3: the selected state: OWNED first then BUYABLE, legality, three actions
	_panel.call(&"select_cell", (&"weapons") as StringName, 1)
	await _frames(3)
	_result("a3_hint_fit_cell", String((_panel.get_node("%PaneHint") as Label).text)
		== "PRESS OR DRAG A ROW TO FIT THE CELL - RIGHT-CLICK PULLS A BARREL",
		"hint=%s" % String((_panel.get_node("%PaneHint") as Label).text))
	rows = _panel.get_node("%BrowserRows") as VBoxContainer
	var order_ok := true
	var seen_buyable := false
	var legal_all := true
	var buy_chip := false
	var inspect_chip := false
	var buyable_payload: Dictionary = {}
	var owned_count := 0
	for child: Node in rows.get_children():
		var ctl := child as Control
		var tag_label := ctl.get_node_or_null(NodePath("RowInner/RowBox/Tag")) as Label
		if tag_label == null:
			continue
		var tag := String(tag_label.text)
		var legal := String((ctl.get_node_or_null(
			NodePath("RowInner/RowBox/TitleBox/Legal")) as Label).text)
		if not legal.is_empty() and legal.find("LEGAL") == -1 and legal.find("FIT") == -1:
			legal_all = false
		if tag == "BUYABLE":
			seen_buyable = true
			buy_chip = ctl.get_node_or_null(NodePath("RowInner/RowBox/Buy")) != null
			inspect_chip = ctl.get_node_or_null(NodePath("RowInner/RowBox/InspectChip")) != null
			if buyable_payload.is_empty():
				for p: Dictionary in _panel.get(&"_browser_payloads"):
					if p[&"row"] == ctl:
						buyable_payload = p
		elif tag == "OWNED":
			owned_count += 1
			if seen_buyable:
				order_ok = false
	_result("a3_owned_then_buyable", order_ok and owned_count > 0 and seen_buyable,
		"owned=%d order_ok=%s" % [owned_count, str(order_ok)])
	_result("a3_legality_lines", legal_all, "every listed row carries its legality line")
	_result("a3_buyable_actions", buy_chip and inspect_chip,
		"buy=%s inspect=%s" % [str(buy_chip), str(inspect_chip)])
	var press_fit: Dictionary = _profile.call(&"fit_for", SHIP)
	var owned_payload: Dictionary = {}
	for p: Dictionary in _panel.get(&"_browser_payloads"):
		if bool(p.get(&"owned", false)) and String(p.get(&"tag", "")) == "OWNED":
			owned_payload = p
			break
	if not owned_payload.is_empty():
		_panel.call(&"_on_browser_pressed", owned_payload)
		await _frames(2)
		var after: Dictionary = _profile.call(&"fit_for", SHIP)
		_result("a3_select_to_fit", after != press_fit, "an OWNED row's press fitted W2")
		_profile.call(&"clear_fit_slot", SHIP, (&"weapons") as StringName, 1)
		await _frames(3)
		## Re-grab the payloads: the profile write rebuilt the rows.
		var fresh_buyable: Dictionary = {}
		for p: Dictionary in _panel.get(&"_browser_payloads"):
			if String(p.get(&"tag", "")) == "BUYABLE":
				fresh_buyable = p
				break
		var drag: Dictionary = _panel.call(&"drag_browser", fresh_buyable if fresh_buyable.is_empty() else owned_payload)
		_result("a3_drag_to_fit", not drag.is_empty()
			and bool(_panel.call(&"cell_can_drop", {&"type": (&"weapons") as StringName, &"token": "W", &"index": 1}, drag)),
			"drag payload reaches the cell")
		var credits_before := int(_profile.call(&"credits"))
		if not fresh_buyable.is_empty():
			_panel.call(&"_on_buy_pressed", fresh_buyable)
			await _frames(2)
			var fit_after: Dictionary = _profile.call(&"fit_for", SHIP)
			var wcells: Array = fit_after.get((&"weapons") as StringName, [])
			var bought: bool = wcells.size() > 1 and String(wcells[1]) != ""
			_result("a3_buy_then_fit", bought
				and int(_profile.call(&"credits")) < credits_before,
				"buy moved credits %d -> %d, W2=%s" % [credits_before,
				int(_profile.call(&"credits")), str(wcells[1]) if wcells.size() > 1 else "none"])
			_profile.call(&"clear_fit_slot", SHIP, (&"weapons") as StringName, 1)
			await _frames(2)

	# --- A4: no wide blocks, no foot band (node probes + scene grep)
	var gone := true
	for n in ["%FootBand", "%InventoryRows", "%InventoryScroll", "%InventoryCaption"]:
		if _panel.get_node_or_null(NodePath(n)) != null:
			gone = false
	var scene_text := FileAccess.get_file_as_string("res://ui/station/armory_panel.tscn")
	var script_text := FileAccess.get_file_as_string("res://ui/station/armory_panel.gd")
	var words_ok := scene_text.find("FITS HERE") == -1 \
		and scene_text.find("BUYABLE THAT FITS") == -1 and scene_text.find("FootBand") == -1 \
		and script_text.find("FITS_HERE_CAPTION") == -1 and script_text.find("BUYABLE_CAPTION") == -1
	_result("a4_no_wide_blocks_no_foot_band", gone and words_ok,
		"nodes_gone=%s words_gone=%s" % [str(gone), str(words_ok)])

	# --- A5: BATTERY CONFIG two equal sectors + racks persist + EQ container
	_profile.call(&"add_module", (&"p_std") as StringName, 2)
	_panel.call(&"refresh_profile", (&"modules") as StringName)
	_panel.call(&"set_mode", (&"battery") as StringName)
	await _frames(4)
	_result("a5_hint_battery", String((_panel.get_node("%PaneHint") as Label).text)
		== "DRAG BETWEEN RACKS TO REGROUP - 1-5 SELECT RACK",
		"hint=%s" % String((_panel.get_node("%PaneHint") as Label).text))
	_panel.call(&"_lay")
	await _frames(3)
	var rack_sector := _panel.get_node("%RackSector") as Control
	var eq_sector := _panel.get_node("%EqSector") as Control
	_result("a5_battery_sectors_equal", absf(rack_sector.size.x - eq_sector.size.x) <= 1.0
		and rack_sector.size.x > 0.0,
		"rack=%s eq=%s" % [str(rack_sector.size), str(eq_sector.size)])
	_profile.call(&"set_battery_groups", SHIP, [[0], [2]] as Array)
	_panel.call(&"refresh_profile", (&"batteries") as StringName)
	await _frames(3)
	_diag("groups after seed=%s" % str(_profile.call(&"battery_groups", SHIP)))
	var drag2: Dictionary = _panel.call(&"drag_barrel", 1, 0)
	var dropped := bool(_panel.call(&"drop", 0, -1, drag2))
	await _frames(3)
	var groups: Array = _profile.call(&"battery_groups", SHIP)
	var persisted := false
	for g: Variant in groups:
		var arr: Array = g
		if arr.has(0) and arr.has(2):
			persisted = true
	_result("a5_rack_drag_persists", dropped and persisted,
		"drop=%s groups=%s" % [str(dropped), str(groups)])
	var eq_tabs := _panel.get_node("%EqTabs") as HBoxContainer
	var labels: Array[String] = []
	for child: Node in eq_tabs.get_children():
		labels.append(String((child as Button).text))
	_result("a5_eq_tabs", labels.has("AMMUNITION") and labels.has("PWR/FUEL RODS"),
		"tabs=%s" % str(labels))
	_panel.call(&"select_eq_tab", (&"power") as StringName)
	await _frames(3)
	var eq_rows := _panel.get_node("%ArmoryRows") as VBoxContainer
	var count_ok := false
	var count_text := ""
	if eq_rows.get_child_count() > 0:
		var first := eq_rows.get_child(0) as Control
		var count_label := first.get_node_or_null(NodePath("RowInner/RowBox/Count")) as Label
		if count_label != null:
			count_ok = true
			count_text = String(count_label.text)
	_result("a5_eq_count_rows", count_ok and count_text.begins_with("×"),
		"count=%s" % count_text)
	var eq_band := _panel.get_node("%EqBand") as HBoxContainer
	_result("a5_eq_band", eq_band.get_child_count() >= 2, "band cells=%d" % eq_band.get_child_count())

	# --- A7: containment at 1920x1080, both modes
	var bad: Array[String] = []
	_check_inside(_panel.get_node("%ArmoryRows"), bad, "eq_rows")
	_check_inside(_panel.get_node("%EmptyRows"), bad, "empty_rows")
	_check_inside(_panel.get_node("%RackRows"), bad, "rack_rows")
	_panel.call(&"set_mode", (&"fit") as StringName)
	await _frames(4)
	_panel.call(&"_lay")
	await _frames(3)
	_panel.call(&"select_cell", (&"weapons") as StringName, 1)
	await _frames(3)
	_check_inside(_panel.get_node("%BrowserRows"), bad, "list_rows")
	_check_inside(_panel.get_node("%SlotLayoutGrid"), bad, "grid")
	_result("a7_containment", bad.is_empty(),
		"violations=%s" % (str(bad) if bad.size() < 6 else str(bad.slice(0, 6))))

	# --- A8: A5.5 hover freeze (no size/position/visible change on hover)
	var snap_before := _snapshot(_panel)
	var payloads: Array = _panel.get(&"_browser_payloads")
	if payloads.size() > 0:
		_panel.call(&"_on_browser_hovered", payloads[0], true)
		await _frames(2)
		_panel.call(&"_on_browser_hovered", payloads[0], false)
		await _frames(2)
	var snap_after := _snapshot(_panel)
	var changed := false
	for k: String in snap_before:
		if not snap_after.has(k) or snap_after[k] != snap_before[k]:
			changed = true
	_result("a8_hover_freeze", not changed,
		"changed=%s nodes=%d" % [str(changed), snap_before.size()])
	_host.free()
	_panel = null
	_host = null
	await _frames(3)

	# --- B: the exchange sell cluster (N48/N49)
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var escene := load("res://ui/station/exchange_panel.tscn") as PackedScene
	var ehost := Control.new()
	ehost.name = "S33ExchangeHost"
	ehost.theme = theme
	ehost.size = Vector2(1920.0, 1080.0)
	_profile.add_child(ehost)
	var epanel := escene.instantiate() as Control
	ehost.add_child(epanel)
	await _frames(8)
	var sell := epanel.get(&"_sell") as Button
	var sell_row := epanel.get(&"_sell_units_row") as Control
	var step_row := (epanel.get(&"_step_minus") as Control).get_parent() as Control
	var cluster := epanel.get(&"_inspect_cluster") as Control
	_result("b1_sell_word_idle", String(sell.text) == "SELL" and sell.disabled,
		"text=%s disabled=%s" % [String(sell.text), str(sell.disabled)])
	_result("b1_stack_order", step_row.get_index() < sell_row.get_index()
		and sell_row.get_index() < cluster.get_index(),
		"step=%d sell_units=%d cluster=%d" % [step_row.get_index(),
		sell_row.get_index(), cluster.get_index()])
	var minus := epanel.get(&"_sell_minus") as Button
	var plus := epanel.get(&"_sell_plus") as Button
	_result("b1_disabled_no_selection", minus.disabled and plus.disabled,
		"stepper disabled without a selection")
	epanel.call(&"_select", (&"mineral_iron") as StringName)
	await _frames(2)
	_result("b1_sell_word_armed", String(sell.text) == "SELL", "text=%s" % String(sell.text))
	_result("b1_armed_at_one", int(epanel.get(&"_sell_units")) == 1,
		"sell_units=%d" % int(epanel.get(&"_sell_units")))
	epanel.call(&"_set_sell_units", 0)
	_result("b1_floor_one", int(epanel.get(&"_sell_units")) == 1, "min 1")
	epanel.call(&"_set_sell_units", 99)
	_result("b1_ceiling_row_units", int(epanel.get(&"_sell_units")) == 5, "max = row units")
	epanel.call(&"_set_sell_units", 3)
	_result("b1_sell_word_stepped", String(sell.text) == "SELL", "text=%s" % String(sell.text))
	var strip := String((epanel.get(&"_confirm_strip") as Label).text)
	_result("b1_confirm_counted", strip.find("SELL 3") != -1, "strip=%s" % strip)
	var hold_before := int(_profile.call(&"cargo_qty", (&"mineral_iron") as StringName))
	epanel.call(&"_on_sell_pressed")
	await _frames(2)
	var hold_after := int(_profile.call(&"cargo_qty", (&"mineral_iron") as StringName))
	_result("b1_sell_moves_selector_value", hold_before - hold_after == 3,
		"hold %d -> %d" % [hold_before, hold_after])
	epanel.call(&"_clear_selection")
	await _frames(2)
	_result("b1_sell_word_cleared", String(sell.text) == "SELL", "text=%s" % String(sell.text))
	var ebad: Array[String] = []
	_check_inside(epanel.get_node("%ExchangeBody"), ebad, "exchange_body")
	_result("b2_exchange_containment", ebad.is_empty(),
		"violations=%s" % (str(ebad) if ebad.size() < 6 else str(ebad.slice(0, 6))))
	ehost.free()
	_profile.set(&"save_path", prev_path)
	await _frames(2)
	quit(0)

func _check_inside(node: Node, bad: Array[String], tag: String) -> void:
	if node == null:
		return
	for c: Node in node.get_children():
		var ctl := c as Control
		if ctl == null:
			continue
		var r := ctl.get_global_rect()
		if r.position.x < -1.0 or r.position.y < -1.0 or r.end.x > 1921.0 or r.end.y > 1081.0:
			bad.append("%s/%s %s" % [tag, String(ctl.name), str(r)])

func _snapshot(root_node: Node) -> Dictionary:
	var out := {}
	var stack: Array[Node] = [root_node]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		var c := n as Control
		if c != null:
			out[str(n.get_path())] = str(c.get_global_rect()) + "|" + str(c.visible)
		for ch: Node in n.get_children():
			stack.append(ch)
	return out
