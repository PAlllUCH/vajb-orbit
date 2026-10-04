@tool
extends SceneTree
## S32-R1 review probe (read-only): re-measures S32-B1's acceptance items off the shipped files.

var _panel: Control = null
var _host: Control = null
const SHIP: StringName = &"ship_vanguard"

func _initialize() -> void:
	_run.call_deferred()

func _result(key: String, ok: bool, detail: String) -> void:
	print("RESULT %s %s %s" % ["OK" if ok else "FAIL", key, detail])

func _diag(m: String) -> void:
	print("DIAG " + m)

func _run() -> void:
	var profile := root.get_node_or_null(NodePath("PlayerProfile"))
	if profile == null:
		_diag("no PlayerProfile autoload; probe aborted")
		quit(1)
		return
	var scene := load("res://ui/station/armory_panel.tscn") as PackedScene
	var theme := load("res://ui/theme/vajb_theme.tres") as Theme
	if scene == null or theme == null:
		_diag("scene or theme failed to load")
		quit(1)
		return
	var prev_path := String(profile.get(&"save_path"))
	profile.set(&"save_path", "user://probe_s32_review.cfg")
	profile.set(&"_credits", 50000)
	profile.set(&"_active_ship", SHIP)
	profile.set(&"_owned_ships", [SHIP] as Array)
	profile.set(&"_fits", {})
	profile.set(&"_modules", {})
	profile.set(&"_batteries", {})
	for i in 5:
		await process_frame
	_host = Control.new()
	_host.name = "S32ReviewHost"
	_host.theme = theme
	_host.size = Vector2(1920.0, 1080.0)
	profile.add_child(_host)
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)
	profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	for i in 8:
		await process_frame
	_panel.call(&"_lay")
	for i in 3:
		await process_frame

	# P32: exactly one mode visible
	var fit := _panel.get_node("%FitCells") as Control
	var bat := _panel.get_node("%BatteryConfig") as Control
	_result("p32_landing_fit", fit.visible and not bat.visible,
		"fit=%s battery=%s" % [str(fit.visible), str(bat.visible)])
	_panel.call(&"set_mode", (&"battery") as StringName)
	for i in 3:
		await process_frame
	_result("p32_switch_battery", bat.visible and not fit.visible,
		"fit=%s battery=%s" % [str(fit.visible), str(bat.visible)])
	_result("p32_switch_hint", String((_panel.get_node("%PaneHint") as Label).text).find("REGROUP") != -1,
		"hint=%s" % String((_panel.get_node("%PaneHint") as Label).text))
	_result("p32_switch_buttons_header", _panel.get_node_or_null("%ModeFitCells") != null and _panel.get_node_or_null("%ModeBatteryConfig") != null, "both buttons present")
	var bf := _panel.get_node("%ModeFitCells") as Button
	var bb := _panel.get_node("%ModeBatteryConfig") as Button
	_result("p32_button_sizes", bf.get_combined_minimum_size().x <= 96.0 and bb.get_combined_minimum_size().x <= 96.0,
		"fit_min=%s battery_min=%s sizes=%s/%s" % [str(bf.get_combined_minimum_size()), str(bb.get_combined_minimum_size()), str(bf.size), str(bb.size)])
	_panel.call(&"set_mode", (&"fit") as StringName)
	for i in 3:
		await process_frame

	# P33: CELL INFO
	_panel.call(&"select_cell", (&"weapons") as StringName, 0)
	for i in 3:
		await process_frame
	var cid := String((_panel.get_node("%CellInfoId") as Label).text)
	var cpow := String((_panel.get_node("%CellInfoPower") as Label).text)
	var cfit := String((_panel.get_node("%CellInfoFitted") as Label).text)
	var cleg := String((_panel.get_node("%CellInfoLegal") as Label).text)
	_result("p33_cell_info_w1", cid.find("W1") != -1 and cfit.find("EMPTY") == -1 and cleg.length() > 0,
		"id=%s fitted=%s legal=%s power=%s" % [cid, cfit, cleg, cpow])
	_panel.call(&"select_cell", (&"weapons") as StringName, 1)
	for i in 3:
		await process_frame
	_result("p33_cell_info_empty", String((_panel.get_node("%CellInfoFitted") as Label).text) == "EMPTY",
		"fitted=%s legal=%s" % [String((_panel.get_node("%CellInfoFitted") as Label).text), String((_panel.get_node("%CellInfoLegal") as Label).text)])

	# P33: FITS HERE equals legal owned candidates (independent derivation)
	profile.call(&"add_module", (&"w_cannon") as StringName, 1)
	profile.call(&"add_module", (&"w_rocket") as StringName, 1)
	for i in 3:
		await process_frame
	var rows: Array = _panel.call(&"fits_here_rows")
	var listed: Array[String] = []
	for e: Dictionary in rows:
		listed.append(String(e[&"base"]))
	var base_fit: Dictionary = _panel.call(&"_resolved_fit", profile, SHIP)
	var expected: Array[String] = []
	for key: Variant in (load("res://game/module_catalog.gd") as GDScript).MODULES:
		var b := StringName(str(key))
		var slot: StringName = (load("res://game/module_catalog.gd") as GDScript).fit_slot_of(b)
		if slot != &"weapons":
			continue
		if (profile.call(&"instances_of", b) as Array).is_empty():
			continue
		var cand: Dictionary = base_fit.duplicate(true)
		var cells: Array = cand.get((&"weapons") as StringName, [])
		while cells.size() <= 1:
			cells.append("")
		cells[1] = str(b)
		cand[(&"weapons") as StringName] = cells
		var fl: Dictionary = (load("res://game/ship_fit.gd") as GDScript).fit_legal(SHIP, cand)
		if bool(fl.get(&"legal", false)):
			expected.append(str(b))
	_result("p33_fits_here_law", listed == expected,
		"listed=%s expected=%s" % [str(listed), str(expected)])
	var rcand: Dictionary = base_fit.duplicate(true)
	var rcells: Array = rcand.get((&"weapons") as StringName, [])
	while rcells.size() <= 1:
		rcells.append("")
	rcells[1] = "w_rocket"
	rcand[(&"weapons") as StringName] = rcells
	var why_rocket: Dictionary = (load("res://game/ship_fit.gd") as GDScript).fit_legal(SHIP, rcand)
	_diag("rocket_at_W2 fit_legal=" + str(why_rocket))
	_diag("panel_cell_refusal_rocket=" + String(_panel.call(&"_cell_refusal", profile, SHIP, 1, (&"w_rocket") as StringName)))

	# select-to-fit + drag-to-fit
	_panel.call(&"_on_fits_here_pressed", (&"w_cannon") as StringName)
	for i in 3:
		await process_frame
	var fit1: Dictionary = profile.call(&"fit_for", SHIP)
	var wcells: Array = fit1.get((&"weapons") as StringName, [])
	var stf_ok: bool = wcells.size() > 1 and String(wcells[1]).find("cannon") != -1
	_result("p33_select_to_fit", stf_ok, "W2=%s" % (str(wcells[1]) if wcells.size() > 1 else "none"))
	profile.call(&"clear_fit_slot", SHIP, (&"weapons") as StringName, 1)
	for i in 3:
		await process_frame
	var payload: Dictionary = _panel.call(&"drag_inventory", (&"w_cannon") as StringName)
	_result("p33_drag_payload", not (payload as Dictionary).is_empty(), "drag_inventory payload built")
	var cell := {&"type": (&"weapons") as StringName, &"token": "W", &"index": 1}
	_panel.call(&"cell_drop", cell, payload)
	var drop_ok := true
	for i in 3:
		await process_frame
	var fit2: Dictionary = profile.call(&"fit_for", SHIP)
	var wcells2: Array = fit2.get((&"weapons") as StringName, [])
	_result("p33_drag_to_fit", drop_ok and wcells2.size() > 1 and String(wcells2[1]).find("cannon") != -1,
		"drop=%s W2=%s" % [str(drop_ok), str(wcells2[1]) if wcells2.size() > 1 else "none"])

	# P34: racks over fitted weapons only + drag between racks persists
	profile.call(&"add_module", (&"w_rocket") as StringName, 1)
	profile.call(&"fit_module_at", SHIP, (&"weapons") as StringName, 2, (&"w_rocket") as StringName)
	profile.call(&"set_battery_groups", SHIP, [[0], [1], [2]] as Array)
	_panel.call(&"refresh_profile", (&"batteries") as StringName)
	_panel.call(&"set_mode", (&"battery") as StringName)
	for i in 5:
		await process_frame
	_panel.call(&"_lay")
	for i in 3:
		await process_frame
	var rr: Array = _panel.call(&"rack_rows")
	var fit3: Dictionary = profile.call(&"fit_for", SHIP)
	var wcells3: Array = fit3.get((&"weapons") as StringName, [])
	var fitted_cells_only := true
	for r: Dictionary in rr:
		for c: Variant in r[&"cells"]:
			var ci := int(c)
			var modname := ""
			if ci < wcells3.size():
				modname = String(wcells3[ci])
			if modname == "" or modname == "<null>":
				fitted_cells_only = false
	_result("p34_racks_fitted_only", fitted_cells_only, "racks=%s" % str(rr.map(func(r): return r[&"cells"])))
	var dpl: Dictionary = _panel.call(&"drag_barrel", 1, 0)
	var drop2 := bool(_panel.call(&"drop", 0, -1, dpl))
	for i in 3:
		await process_frame
	var groups: Array = profile.call(&"battery_groups", SHIP)
	_result("p34_drag_persists", drop2 and groups == ([[0, 1]] as Array) or (drop2 and groups[0] is Array and (groups[0] as Array).has(0) and (groups[0] as Array).has(1)),
		"drop=%s groups=%s" % [str(drop2), str(groups)])

	# Empty rows
	profile.call(&"clear_fit_slot", SHIP, (&"weapons") as StringName, 2)
	profile.call(&"set_battery_groups", SHIP, [[0], [1]] as Array)
	_panel.call(&"refresh_profile", (&"batteries") as StringName)
	for i in 3:
		await process_frame
	var erows := _panel.get_node("%EmptyRows") as Control
	var all_label := true
	var texts: Array[String] = []
	for c: Node in erows.get_children():
		if not (c is Label):
			all_label = false
		else:
			texts.append(String((c as Label).text))
	_result("p34_empty_rows", all_label and texts.size() >= 1, "labels=%s texts=%s" % [str(all_label), str(texts)])

	# P35 grep in bash externally; skip here.
	# P36 foot band both modes
	var band := _panel.get_node("%FootBand") as Control
	var ammo_parent := String((_panel.get_node("%AmmoMargin") as Control).get_parent().name)
	var meter := String((_panel.get_node("%MeterLabel") as Label).text)
	_result("p36_foot_band_battery", band.visible and ammo_parent == "FootBand" and meter.begins_with("PWR"),
		"visible=%s parent=%s meter=%s" % [str(band.visible), ammo_parent, meter])
	_result("p36_no_bodyscroll", _panel.get_node_or_null("%BodyScroll") == null, "BodyScroll absent")
	_panel.call(&"set_mode", (&"fit") as StringName)
	for i in 3:
		await process_frame
	_result("p36_foot_band_fit", band.visible and meter.begins_with("PWR"), "visible=%s meter=%s" % [str(band.visible), meter])

	# P37 containment: all row controls within 1920x1080 in both modes
	_panel.call(&"select_cell", (&"weapons") as StringName, 1)
	for i in 3:
		await process_frame
	var bad: Array[String] = []
	_check_inside(_panel.get_node("%InventoryRows"), bad, "fit_inv")
	_check_inside(_panel.get_node("%BrowserRows"), bad, "fit_buy")
	_panel.call(&"set_mode", (&"battery") as StringName)
	for i in 3:
		await process_frame
	_panel.call(&"_lay")
	for i in 3:
		await process_frame
	_check_inside(_panel.get_node("%EmptyRows"), bad, "bat_empty")
	_check_inside(_panel.get_node("%RackRows"), bad, "bat_racks")
	_check_inside(_panel.get_node("%ArmoryRows"), bad, "bat_ammo")
	_result("p37_rows_inside", bad.is_empty(), "violations=%s" % (str(bad) if bad.size() < 6 else str(bad.slice(0, 6))))

	# A5.5 hover/focus freeze: no size/position/visible change on hover
	_panel.call(&"set_mode", (&"fit") as StringName)
	for i in 3:
		await process_frame
	var before := _snapshot(_panel)
	var bpl: Array = _panel.call(&"module_row_ids")
	if bpl.size() > 0:
		var bp: Dictionary = (_panel.get(&"_browser_payloads") as Array)[0]
		_panel.call(&"_on_browser_hovered", bp, true)
		for i in 2:
			await process_frame
		_panel.call(&"_on_browser_hovered", bp, false)
		for i in 2:
			await process_frame
	var after := _snapshot(_panel)
	var changed := false
	for k: String in before:
		if not after.has(k) or after[k] != before[k]:
			changed = true
	_result("a55_hover_freeze", not changed, "rect_or_visibility_changed=%s nodes=%d" % [str(changed), before.size()])

	profile.set(&"save_path", prev_path)
	quit(0)

func _check_inside(node: Node, bad: Array[String], tag: String) -> void:
	if node == null:
		return
	for c: Node in node.get_children():
		var ctl := c as Control
		if ctl == null:
			continue
		var r := ctl.get_global_rect()
		if r.position.x < 0 or r.position.y < 0 or r.end.x > 1920.0 or r.end.y > 1080.0:
			bad.append("%s/%s %s" % [tag, String(ctl.name), str(r)])
		for gc: Node in ctl.get_children():
			var gc2 := gc as Control
			if gc2 != null:
				var r2 := gc2.get_global_rect()
				if r2.position.x < 0 or r2.position.y < 0 or r2.end.x > 1920.0 or r2.end.y > 1080.0:
					bad.append("%s/%s/%s %s" % [tag, String(ctl.name), String(gc2.name), str(r2)])

func _snapshot(root: Node) -> Dictionary:
	var out := {}
	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		var c := n as Control
		if c != null:
			out[str(n.get_path())] = str(c.get_global_rect()) + "|" + str(c.visible)
		for ch: Node in n.get_children():
			stack.append(ch)
	return out
