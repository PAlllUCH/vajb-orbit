extends Node
## W2 evidence probe: the FITTING pane measured in memory, with the shipped scene and theme.
## No shipped file is written and the owner's profile is borrowed and handed back (the suite
## `test_p2b_fitting_panel`'s own hygiene), so the probe is re-runnable byte-identically.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_w2_fitting.tscn --quit-after 600
## Signal: the [W2-FITTING] lines; the last line is [W2-FITTING] done.

const PanelScene := preload("res://ui/station/fitting_panel.tscn")
const PanelScript := preload("res://ui/station/fitting_panel.gd")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://probe_w2_fitting.cfg"

const HULL: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const SHIELD_SLOT: StringName = &"shields"
const POWER_SLOT: StringName = &"power"
const CANNON: StringName = &"w_cannon"
const PLASMA: StringName = &"w_plasma"
const LASER: StringName = &"w_laser"
const ION: StringName = &"e_ion"
const RAILGUN: StringName = &"w_railgun"
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"disabled"]

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _saved: Dictionary = {}


func _ready() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[W2-FITTING] no PlayerProfile autoload; aborting")
		get_tree().quit(2)
		return
	_borrow()
	_host = Control.new()
	_host.name = "W2Host"
	_host.theme = ThemeRes
	_host.size = Vector2(1280.0, 900.0)
	tree.root.get_node(NodePath(&"PlayerProfile")).add_child(_host)
	await get_tree().process_frame
	_probe_grid_recipe()
	_probe_rows()
	_probe_meter()
	_probe_refusals()
	_probe_focus()
	_probe_seeding_hole()
	_return()
	print("[W2-FITTING] done")
	get_tree().quit(0)


func _borrow() -> void:
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"credits": int(_profile.call(&"credits")),
		&"fits": _profile.call(&"fits"),
		&"owned": _profile.call(&"owned_ships"),
		&"modules": _profile.call(&"modules"),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func _return() -> void:
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", _saved[&"ship"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.call(&"flush")
	_profile.set(&"save_path", _saved[&"path"])
	_delete_file(PROFILE_PATH)


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _records(modules: Dictionary) -> Dictionary:
	var records: Dictionary = {}
	for module_id: Variant in modules:
		records[String(module_id)] = {"base_id": String(module_id), "count": int(modules[module_id])}
	return records


func _seed(hull: StringName, modules: Dictionary, with_fit: bool) -> void:
	var owned: Array[StringName] = [hull]
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", _records(modules))
	if with_fit:
		_profile.call(&"set_fit", hull, ShipFit.standard_fit(hull))


func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	return _panel


func _unmount() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null


## ------------------------------------------------------------------ the grid, both panes


func _probe_grid_recipe() -> void:
	_seed(HULL, {}, true)
	var panel := _mount()
	var grid := panel.get_node("%SlotLayoutGrid") as GridContainer
	var cells: Array = ShipFit.grid_cells(HULL)
	print("[W2-FITTING] hull=%s matrix=%s cells=%d gaps=%d columns=%d plates=%d" % [
		HULL,
		ShipFit.grid_size(HULL),
		cells.size(),
		_count_gaps(cells),
		grid.columns,
		cells.size() - _count_gaps(cells),
	])
	print("[W2-FITTING] grid separations h=%d v=%d caption=%s" % [
		grid.get_theme_constant(&"h_separation"),
		grid.get_theme_constant(&"v_separation"),
		(panel.get_node("%SlotCaption") as Label).text,
	])
	for index in cells.size():
		var cell: Dictionary = cells[index]
		var child := grid.get_child(index) as Control
		var glyph := child.get_node_or_null(^"Icon") as TextureRect
		print("[W2-FITTING] cell %02d %s token=%s index=%d minsize=%s class=%s plate=%s glyph=%s glyph_min=%s" % [
			index,
			"gap " if bool(cell[&"gap"]) else "slot",
			cell[&"token"],
			int(cell[&"index"]),
			child.custom_minimum_size,
			child.get_class(),
			StringName(child.theme_type_variation) if child is Button else &"-",
			glyph.texture.resource_path if glyph != null and glyph.texture != null else "-",
			glyph.custom_minimum_size if glyph != null else Vector2.ZERO,
		])
	print("[W2-FITTING] cells focusable=%d disabled=%d" % [
		_count_focusable(panel), _count_disabled(panel),
	])
	var shipyard := ShipyardScene.instantiate() as Control
	_host.add_child(shipyard)
	var yard := shipyard.get_node("%HardpointSlots") as GridContainer
	print("[W2-FITTING] shipyard cells=%d columns=%d h=%d caption=%s" % [
		yard.get_child_count(),
		yard.columns,
		yard.get_theme_constant(&"h_separation"),
		(shipyard.get_node("%HardpointCaption") as Label).text,
	])
	for index in mini(yard.get_child_count(), grid.get_child_count()):
		var mine := grid.get_child(index) as Control
		var theirs := yard.get_child(index) as Control
		var same_size := mine.custom_minimum_size == theirs.custom_minimum_size
		var same_glyph := true
		var art := {}
		if mine is Button:
			var plate := mine as Button
			var yard_plate := theirs as TextureButton
			for state: StringName in PLATE_STATES:
				var box := plate.get_theme_stylebox(state, PLATE_VARIATION)
				var texture: Texture2D = null
				if box is StyleBoxTexture:
					texture = (box as StyleBoxTexture).texture
				art[state] = texture
				same_glyph = same_glyph and texture == _yard_texture(yard_plate, state)
			var glyph := mine.get_node_or_null(^"Icon") as TextureRect
			var yard_glyph := theirs.get_node_or_null(^"Icon") as TextureRect
			if glyph == null or yard_glyph == null:
				same_glyph = false
			elif glyph.texture != yard_glyph.texture:
				same_glyph = false
		print("[W2-FITTING] recipe cell %02d same_size=%s same_art=%s mine=%s theirs=%s art=%s" % [
			index,
			same_size,
			same_glyph,
			mine.get_class(),
			theirs.get_class(),
			String(art.get(&"normal", null).resource_path) if art.get(&"normal", null) != null else "-",
		])
	print("[W2-FITTING] focus stylebox on a FITTING cell: %s" % _focus_ring(panel))
	shipyard.free()
	_unmount()


func _focus_ring(panel: Control) -> String:
	for child: Node in (panel.get_node("%SlotLayoutGrid") as GridContainer).get_children():
		var plate := child as Button
		if plate == null:
			continue
		var box := plate.get_theme_stylebox(&"focus")
		if box == null:
			return "<none>"
		if box is StyleBoxFlat:
			var flat := box as StyleBoxFlat
			return "%s border=%d colour=%s" % [
				box.get_class(), flat.border_width_left, flat.border_color
			]
		return box.get_class()
	return "<no plate>"


func _yard_texture(plate: TextureButton, state: StringName) -> Texture2D:
	match state:
		&"normal":
			return plate.texture_normal
		&"hover":
			return plate.texture_hover
		&"pressed":
			return plate.texture_pressed
		&"disabled":
			return plate.texture_disabled
	return null


func _count_gaps(cells: Array) -> int:
	var gaps := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			gaps += 1
	return gaps


func _count_focusable(node: Node) -> int:
	var total := 0
	for child: Node in node.get_children():
		var button := child as Button
		if button != null and button.focus_mode != Control.FOCUS_NONE and not button.disabled:
			total += 1
		total += _count_focusable(child)
	return total


func _count_disabled(node: Node) -> int:
	var total := 0
	for child: Node in node.get_children():
		var button := child as Button
		if button != null and button.disabled:
			total += 1
		total += _count_disabled(child)
	return total


## ----------------------------------------------------------------------- the OWNED rows


func _probe_rows() -> void:
	_seed(HULL, {CANNON: 2, LASER: 1, ION: 1, RAILGUN: 1}, true)
	var panel := _mount()
	print("[W2-FITTING] rows=%s" % str(panel.call(&"module_row_ids")))
	for module_id: StringName in panel.call(&"module_row_ids"):
		var row := _row(panel, module_id)
		var module_row: Dictionary = ModuleData.module(module_id)
		print("[W2-FITTING] row %s name=%s meta=%s owned=%s action=%s" % [
			module_id,
			(row.find_child("Title", true, false) as Label).text,
			(row.find_child("Meta", true, false) as Label).text,
			_cell_text(row, "Owned"),
			_cell_text(row, "Action"),
		])
		print("[W2-FITTING]   icon=%s tinted=%s cell=%s draw=%d" % [
			_string_icon(row),
			PanelScript.FLAT_GLYPH_ICONS.has(String(module_row[&"icon"])),
			String(module_row[&"slot"]),
			int(module_row[&"draw"]),
		])
	var states: Array[String] = []
	for cell: Array in [[&"", -1], [WEAPON_SLOT, 0], [WEAPON_SLOT, 1], [ENGINE_SLOT, 0], [SHIELD_SLOT, 0]]:
		var slot: StringName = cell[0]
		if slot == &"":
			panel.call(&"clear_selection")
		else:
			panel.call(&"select_cell", slot, int(cell[1]))
		var actions := PackedStringArray()
		for module_id: StringName in panel.call(&"module_row_ids"):
			actions.append("%s=%s" % [module_id, panel.call(&"module_action", module_id)])
		states.append("%s -> %s · meter=%s · line=%s · remove=%s" % [
			"none" if slot == &"" else "%s%d" % [slot, int(cell[1])],
			",".join(actions),
			panel.call(&"meter_text"),
			panel.call(&"footer_text"),
			not (panel.get_node("%RemoveButton") as Button).disabled,
		])
	for line: String in states:
		print("[W2-FITTING] state %s" % line)
	panel.call(&"clear_selection")
	print("[W2-FITTING] empty state line=%s" % panel.call(&"footer_text"))
	_unmount()


func _string_icon(row: Button) -> String:
	for child: Node in row.find_children("*", "TextureRect", true, false):
		var texture := child as TextureRect
		if texture != null and texture.texture != null:
			return "%s (a=%.2f)" % [texture.texture.resource_path, texture.modulate.a]
	return "-"


func _row(panel: Control, module_id: StringName) -> Button:
	var rows := panel.get_node("%ModuleRows") as VBoxContainer
	for child: Node in rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


## --------------------------------------------------------------------------- the meter


func _probe_meter() -> void:
	var profile := _profile
	print("[W2-FITTING] --- meter ---")
	var power: Dictionary = ShipFit.fit_legal(HULL, profile.call(&"fit_for", HULL))[&"power"]
	var panel := _mount()
	print("[W2-FITTING] vanguard idle meter=%s (fit_legal power draw=%d out=%d spare=%d legal=%s)" % [
		panel.call(&"meter_text"),
		int(power[&"draw"]),
		int(power[&"out"]),
		int(power[&"spare"]),
		power[&"legal"],
	])
	print("[W2-FITTING] vanguard candidate on W2 with the cannon row read = %s" % _candidate_meter(
		panel, WEAPON_SLOT, 1, CANNON
	))
	_unmount()
	## The Lancer's over-budget case: two plasma coils against its 08 section 2 output.
	_seed(FIGHTER, {PLASMA: 2}, true)
	panel = _mount()
	panel.call(&"select_cell", WEAPON_SLOT, 0)
	_press(panel, PLASMA)
	print("[W2-FITTING] lancer after the first plasma: fit=%s meter=%s" % [
		str(profile.call(&"fit_for", FIGHTER)[WEAPON_SLOT]),
		panel.call(&"meter_text"),
	])
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	_press(panel, PLASMA)
	var over: Dictionary = ShipFit.fit_legal(FIGHTER, profile.call(&"fit_for", FIGHTER))[&"power"]
	print("[W2-FITTING] lancer over-budget press: meter=%s line=%s danger=%s power=%s" % [
		panel.call(&"meter_text"),
		panel.call(&"footer_text"),
		(panel.get_node("%MeterLabel") as Label).has_theme_color_override(&"font_color"),
		str(over),
	])
	print("[W2-FITTING] meter danger colour=%s theme accent_danger=%s" % [
		(panel.get_node("%MeterLabel") as Label).get_theme_color(&"font_color"),
		panel.get_theme_color(&"accent_danger", &"Tokens"),
	])
	_unmount()


## The candidate line without pressing: the pane previews the row the meter's own read names.
func _candidate_meter(panel: Control, slot_key: StringName, index: int, module_id: StringName) -> String:
	panel.call(&"select_cell", slot_key, index)
	_press(panel, module_id)
	var line: String = panel.call(&"meter_text")
	## Undo the install so the measurement leaves the fixture as it was found.
	panel.call(&"select_cell", slot_key, index)
	panel.call(&"remove_selected")
	panel.call(&"clear_selection")
	return line


func _press(panel: Control, module_id: StringName) -> void:
	var row := _row(panel, module_id)
	if row != null:
		row.pressed.emit()


## ------------------------------------------------------------------------ the refusals


func _probe_refusals() -> void:
	_seed(HULL, {CANNON: 1}, true)
	var panel := _mount()
	panel.call(&"select_cell", ENGINE_SLOT, 0)
	panel.call(&"remove_selected")
	print("[W2-FITTING] mandatory refusal line=%s danger=%s fit=%s" % [
		panel.call(&"footer_text"),
		(panel.get_node("%SelectionLine") as Label).has_theme_color_override(&"font_color"),
		str(_profile.call(&"fit_for", HULL)[ENGINE_SLOT]),
	])
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	panel.call(&"install_module", RAILGUN)
	print("[W2-FITTING] catch-all refusal (nothing owned) line=%s fit=%s module_count=%d" % [
		panel.call(&"footer_text"),
		str(_profile.call(&"fit_for", HULL)[WEAPON_SLOT]),
		int(_profile.call(&"module_count", RAILGUN)),
	])
	var words := PackedStringArray()
	for token: String in [
		PanelScript.REFUSAL_OVERLOAD, PanelScript.REFUSAL_MANDATORY, PanelScript.REFUSAL_FIT_ILLEGAL,
	]:
		words.append(token % [13, 11, 2] if token.contains("%") else token)
	print("[W2-FITTING] the three pinned refusals: %s" % " | ".join(words))
	_unmount()


## --------------------------------------------------------------------------- focus order


func _probe_focus() -> void:
	_seed(HULL, {CANNON: 1, RAILGUN: 1}, true)
	var panel := _mount()
	var order: Array[String] = []
	_collect_buttons(panel, order)
	print("[W2-FITTING] focus walk, nothing selected (%d stops): %s" % [
		order.size(), ", ".join(order)
	])
	panel.call(&"select_cell", WEAPON_SLOT, 0)
	order.clear()
	_collect_buttons(panel, order)
	print("[W2-FITTING] focus walk, W1 selected (%d stops): %s" % [
		order.size(), ", ".join(order)
	])
	panel.call(&"focus_primary")
	var focus_owner := panel.get_viewport().gui_get_focus_owner()
	var owner_name := "<none>"
	if focus_owner != null:
		owner_name = String(focus_owner.name)
	print("[W2-FITTING] focus_primary owner=%s" % owner_name)
	print("[W2-FITTING] scroll focus_mode=%d (engine default for a ScrollContainer)" % (
		(panel.get_node("%FittingScroll") as ScrollContainer).focus_mode
	))
	_unmount()


func _collect_buttons(node: Node, out: Array[String]) -> void:
	for child: Node in node.get_children():
		var button := child as Button
		if button != null and button.focus_mode != Control.FOCUS_NONE and not button.disabled:
			out.append(button.name)
		_collect_buttons(child, out)


## -------------------------------------------------------------- the unfit-hull read-back


## What the pane previews when the account holds no fit for the active hull, next to what the
## composed transaction answers: the one place where the two reads can disagree.
func _probe_seeding_hole() -> void:
	_seed(HULL, {CANNON: 1}, false)
	var panel := _mount()
	var shown: Dictionary = ShipFit.standard_fit(HULL)
	var preview := ShipFit.fit_legal(HULL, shown)
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	var before: Dictionary = _profile.call(&"fit_for", HULL)
	var stored_legal := ShipFit.fit_legal(HULL, _stored_candidate(before, CANNON))
	var wrote: bool = _profile.call(&"fit_module_at", HULL, WEAPON_SLOT, 1, CANNON)
	print("[W2-FITTING] unfit hull: pane preview legal=%s missing=%s | stored candidate legal=%s power=%s | fit_module_at=%s" % [
		preview[&"legal"],
		str(preview[&"missing"]),
		stored_legal[&"legal"],
		str(stored_legal[&"power"]),
		wrote,
	])
	print("[W2-FITTING] unfit hull: meter=%s line=%s action=%s" % [
		panel.call(&"meter_text"),
		panel.call(&"footer_text"),
		panel.call(&"module_action", CANNON),
	])
	_unmount()


func _stored_candidate(fit: Dictionary, module_id: StringName) -> Dictionary:
	var candidate: Dictionary = fit.duplicate(true)
	var cells: Array = candidate[WEAPON_SLOT]
	cells[1] = String(module_id)
	candidate[WEAPON_SLOT] = cells
	return candidate
