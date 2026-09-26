@tool
extends McpTestSuite
## Suite s18_armory_rework: wave S18's ARMORY rework - the D13 design of record landed
## (UI_SPEC section 3.10 Amendment 3, owner ticks T1-T8 of 2026-09-25). The suite gates the
## wave's floors, not the chrome the moved suites already measure:
##
##  - **HIGH-1 (T6)** - 13 px ink everywhere with **no `font_size` override** anywhere in
##    the pane: every label resolves its size from a theme variation registered in
##    `Router.FONT_SIZE_ITEMS`, so `ui_scale` can never be escaped per node again.
##  - **HIGH-2 (T6)** - the caption tones clear 4.5:1 against every surface they print on.
##  - **P5** - the pack card's held line is the worded `HELD %d ROUNDS - HOLD %d UNITS`
##    figure, never the old `%d / %d` pair.
##  - **P6 (T1's condition)** - every pane rect derives from the host rect: the three
##    proof canvases (1920x1080, 2580x1080, 1920x1536) all derive, nothing clips.
##  - **T4/T7** - `DROP HERE` on empty cells, the `READY` / `OVER CAP` chip (shape and
##    label) on the bay head at the section 12 hardcap.
##  - **T5 / Amendment 3** - the pane footer caption and the two plates retire.
##  - **P4** - a fitted barrel's inspector body carries two lines.
##
## The pane is mounted the way `tests/test_s15_armory_layout.gd` mounts it (the shipped
## scene, the shipped theme, the profile borrowed and handed back).

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StyleScript := preload("res://ui/station/armory_style.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s18_armory_rework.cfg"

const HOST := Vector2(1392.0, 610.0)
## The mockup's own three proof canvases (converted to the station's host by the same
## proportional derivation the station uses: a 16:9 canvas is the base, a wider one adds
## width to the host, a taller one height).
const PROOF_BASE := Vector2(1392.0, 610.0)
const PROOF_WIDE := Vector2(2032.0, 610.0)
const PROOF_TALL := Vector2(1392.0, 1066.0)
const CONSOLE := Vector2(1360.0, 516.0)
const CELL := Vector2(117.0, 52.0)
const MIN_INK := 13.0
const CONTRAST_FLOOR := 4.5

const VANGUARD: StringName = &"ship_vanguard"
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const START_CREDITS := 10000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _seen: Array[Array] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s18_armory_rework"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_credits = int(_profile.get(&"_credits"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_seen.clear()
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_host = Control.new()
	_host.name = "ArmoryS18Host"
	_host.theme = ThemeRes
	_host.size = HOST
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	return profile if profile != null else tree.root


func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	if not _panel.is_connected(&"inspect_requested", _record_inspect):
		_panel.connect(&"inspect_requested", _record_inspect)
	return _panel


func _record_inspect(title: String, body: String, danger: bool) -> void:
	_seen.append([title, body, danger])


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _style() -> Resource:
	return _panel.call(&"style")


func _rack_row(index: int) -> PanelContainer:
	return (_panel.get_node("%RackRows") as VBoxContainer).get_child(index) as PanelContainer


## ---------------------------------------------------- 1. the 13 px floor (HIGH-1)

## HIGH-1's cure: the pane carries **no** `font_size` override at all (the twelve escaping
## overrides died), so every label resolves its size from a theme variation registered in
## `Router.FONT_SIZE_ITEMS` - and every visible piece of ink is at least 13 px.
func test_no_font_size_override_escapes_the_scale() -> void:
	var panel := _mount()
	var overrides: Array[String] = []
	var below_floor: Array[String] = []
	_collect_font_sizes(panel, overrides, below_floor)
	assert_eq(
		overrides, [] as Array[String],
		"no node overrides font_size (HIGH-1's escaping overrides); found %s" % str(overrides)
	)
	assert_eq(
		below_floor, [] as Array[String],
		"and every visible label clears the 13 px floor; found %s" % str(below_floor)
	)
	## The registry the sizes come from really is the Router's own list.
	for variation: StringName in [&"StationCaption", &"StationPanelTitle", &"StationValue"]:
		var entry: Dictionary = {}
		for row: Dictionary in Router.FONT_SIZE_ITEMS:
			if StringName(row[&"type"]) == variation:
				entry = row
		assert_eq(
			String(entry.get(&"item", &"")), "font_size",
			"%s is registered in Router.FONT_SIZE_ITEMS" % variation
		)


func _collect_font_sizes(node: Node, overrides: Array[String], below_floor: Array[String]) -> void:
	var control := node as Control
	if control != null and control.has_theme_font_size_override(&"font_size"):
		overrides.append("%s (%s)" % [node.name, node.get_class()])
	if control != null and control.visible and (node is Label or node is Button):
		var size := control.get_theme_font_size(&"font_size")
		if size < int(MIN_INK):
			below_floor.append("%s (%d px)" % [node.name, size])
	for child: Node in node.get_children():
		_collect_font_sizes(child, overrides, below_floor)


## ------------------------------------------------- 2. the caption tones (HIGH-2)

## HIGH-2's cure: every caption tone clears 4.5:1 against every surface it prints on - the
## bay card, the cell recess, the ledger, the item plates and the host's own two tones.
func test_the_caption_tones_clear_the_contrast_floor() -> void:
	var panel := _mount()
	var style := _style()
	var caption: Color = style.colour(&"caption")
	var caption_void: Color = style.colour(&"caption_void")
	for role: StringName in [&"bay_bg", &"cell_bg", &"ledge_bg", &"item_bg", &"chip_bg"]:
		var ratio := _contrast(caption, style.colour(role))
		assert_true(
			ratio >= CONTRAST_FLOOR,
			"the caption clears %.2f:1 on %s (actual %.2f)" % [CONTRAST_FLOOR, role, ratio]
		)
	for role: StringName in [&"void_base", &"panel_steel", &"metal_dark"]:
		var ratio := _contrast(caption_void, style.colour(role))
		assert_true(
			ratio >= CONTRAST_FLOOR,
			"the host caption clears %.2f:1 on %s (actual %.2f)" % [CONTRAST_FLOOR, role, ratio]
		)


## WCAG 2.x relative luminance and contrast ratio, computed here so the floor is measured
## rather than asserted from a comment.
func _luminance(colour: Color) -> float:
	var channels: Array[float] = [colour.r, colour.g, colour.b]
	var weights: Array[float] = [0.2126, 0.7152, 0.0722]
	var out := 0.0
	for index in 3:
		var value: float = channels[index]
		var linear: float = value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)
		out += linear * weights[index]
	return out


func _contrast(first: Color, second: Color) -> float:
	var high: float = maxf(_luminance(first), _luminance(second))
	var low: float = minf(_luminance(first), _luminance(second))
	return (high + 0.05) / (low + 0.05)


## ------------------------------------------------------------- 3. the P5 wording

## P5: the pack card's held line spells its units out. The old `%d / %d` pair is gone.
func test_the_pack_card_carries_the_p5_worded_line() -> void:
	var panel := _mount()
	_profile.call(&"add_cargo", &"ammo_cannon", 15)
	panel.call(&"refresh_profile", &"cargo")
	var card: Button = null
	for child: Node in (panel.get_node("%ArmoryRows") as Control).get_children():
		var row := child as Button
		if row != null and row.name == "AmmoCannon":
			card = row
	assert_true(card != null, "the cannon pack has a card")
	if card == null:
		return
	var held := card.find_child("Held", true, false).get_node(^"Value") as Label
	assert_eq(
		held.text, PanelScript.HELD_FORMAT % [150, 30],
		"the worded held line (actual %s)" % held.text
	)
	assert_true(held.text.find(" ROUNDS") != -1, "carrying the rounds word")
	assert_true(held.text.find(" UNITS") != -1, "and the units word")
	assert_true(held.text.find(" / ") == -1, "never the retired slash pair")


## ------------------------------------------------- 4. the resolution law (P6 / T1)

## T1's condition: every pane rect derives from the host rect. The three proof canvases
## (base 1920x1080, wide 21:9, tall 5:4) all derive, none clips, and the geometry tracks
## the host's own proportions rather than any pinned rect.
func test_every_rect_derives_from_the_host_at_the_three_proofs() -> void:
	var panel := _mount()
	var style := _style()
	var widths: Array[float] = []
	for host_size: Vector2 in [PROOF_BASE, PROOF_WIDE, PROOF_TALL]:
		_host.size = host_size
		panel.call(&"_lay")
		var host := Rect2(Vector2.ZERO, host_size)
		var console: Rect2 = style.console_rect(host)
		assert_true(host.encloses(console), "the console stays inside the host at %s" % str(host_size))
		assert_eq(panel.call(&"block_size"), console.size, "the pane draws that console")
		var band: Rect2 = style.bays_band(console)
		assert_true(host.encloses(band), "the bay band stays inside the host at %s" % str(host_size))
		var bays: Array = panel.call(&"bay_rects")
		assert_eq(bays.size(), 5, "five bays at every canvas")
		for index in bays.size():
			assert_true(
				band.encloses(bays[index] as Rect2),
				"bay %d stays inside the band at %s" % [index, str(host_size)]
			)
		for index in 4:
			var cell: Rect2 = style.bay_cell_rect(index, Rect2(Vector2.ZERO, (bays[0] as Rect2).size))
			assert_true(
				(Rect2(Vector2.ZERO, (bays[0] as Rect2).size)).encloses(cell),
				"cell %d stays inside its bay at %s" % [index, str(host_size)]
			)
		var wells: Array = panel.call(&"well_rects")
		assert_eq(wells.size(), 2, "two wells at every canvas")
		for index in wells.size():
			assert_true(
				host.encloses(wells[index] as Rect2),
				"well %d stays inside the host at %s" % [index, str(host_size)]
			)
		widths.append((bays[0] as Rect2).size.x)
	## The wide canvas widens the bays; the tall one does not (both are derived, not pinned).
	assert_true(
		widths[1] > widths[0],
		"the wide canvas widens the bays (%.1f -> %.1f)" % [widths[0], widths[1]]
	)
	assert_true(
		is_equal_approx(widths[2], widths[0]),
		"and the tall one keeps them (%.1f -> %.1f)" % [widths[0], widths[2]]
	)
	_host.size = HOST
	panel.call(&"_lay")
	assert_eq(panel.call(&"block_size"), CONSOLE, "the base host is back to the ruled console")


## --------------------------------------------- 5. the states (T4 / T7)

## T4/T7: the bay head's chip states `READY`, or `OVER CAP` with its chevron when the
## battery holds the section 12 hardcap's four cells; every empty cell offers `DROP HERE`.
func test_the_bay_chip_states_the_cap_and_the_empty_cells_offer_drop() -> void:
	var panel := _mount()
	var state := _rack_row(0).get_node(^"Box/Head/State") as Label
	var chip := _rack_row(0).get_node(^"Box/Head/Chip") as Control
	assert_eq(state.text, PanelScript.RACK_READY, "a one-cell battery reads READY")
	assert_eq(bool(chip.get(&"chevron")), false, "with no chevron")
	## The empty cells of B2: every one carries the drop cue.
	var pads := _rack_row(1).get_node(^"Box/Cells") as Control
	assert_eq(pads.get_child_count(), 4, "an empty bay has four cells")
	for child: Node in pads.get_children():
		var cue := child.get_node_or_null(^"Cue") as Label
		assert_true(cue != null, "every empty cell carries its cue")
		assert_eq(String(cue.text), "DROP HERE", "the T4 wording, at 13 px")
	var bay1 := _rack_row(0)
	var bay1_pads := bay1.get_node(^"Box/Cells") as Control
	assert_eq(bay1_pads.get_child_count(), 3, "B1's fitted cell leaves three empty slots")
	var bay1_rect := Rect2(Vector2.ZERO, bay1.size)
	for index in bay1_pads.get_child_count():
		var pad := bay1_pads.get_child(index)
		var pad_slot := int(pad.get(&"slot"))
		assert_true(
			pad_slot >= 0 and pad_slot < 4,
			"the pad carries its own grid slot (pad %d reads %d)" % [index, pad_slot]
		)
		assert_eq(
			(pad as Control).position,
			_style().bay_cell_rect(pad_slot, bay1_rect).position,
			"pad %d sits in its own slot %d, not on the fitted chip (actual %s)"
			% [index, pad_slot, str((pad as Control).position)]
		)
	## The hardcap's four cells: the same bay's chip turns OVER CAP and grows its chevron.
	_profile.set(&"_active_ship", DESTROYER)
	_profile.set(&"_owned_ships", [DESTROYER] as Array[StringName])
	var fit: Dictionary = FitData.standard_fit(DESTROYER)
	var weapons: Array = []
	for index in FitData.slot_capacity(DESTROYER, WEAPON_SLOT):
		weapons.append("" if index > 3 else ("w_laser" if index % 2 == 0 else "w_cannon"))
	fit[WEAPON_SLOT] = weapons
	_profile.call(&"set_fit", DESTROYER, fit)
	_profile.call(&"set_battery_groups", DESTROYER, [[0, 1, 2, 3]])
	panel.call(&"refresh_profile", &"batteries")
	var full_state := _rack_row(0).get_node(^"Box/Head/State") as Label
	var full_chip := _rack_row(0).get_node(^"Box/Head/Chip") as Control
	assert_eq(full_state.text, PanelScript.RACK_STATE_OVER, "the full battery reads OVER CAP")
	assert_eq(bool(full_chip.get(&"chevron")), true, "with its chevron (shape and label)")


## A bay can hold any W cells of the hull (a 7-cell hull composes as B1(4) + B2(3)): the
## chips ride the bay's own 2x2 grid by their **position in the rack**, never by the
## W-cell index, so W5..W7 land on the first grid slots instead of off the bay.
func test_a_high_w_index_bay_places_its_cells_on_the_grid() -> void:
	var panel := _mount()
	_profile.set(&"_active_ship", DESTROYER)
	_profile.set(&"_owned_ships", [DESTROYER] as Array[StringName])
	var fit: Dictionary = FitData.standard_fit(DESTROYER)
	var weapons: Array = []
	for index in FitData.slot_capacity(DESTROYER, WEAPON_SLOT):
		weapons.append("w_laser" if index >= 4 else "")
	fit[WEAPON_SLOT] = weapons
	assert_true(bool(_profile.call(&"set_fit", DESTROYER, fit)), "the capital's fit installs")
	assert_true(
		bool(_profile.call(&"set_battery_groups", DESTROYER, [[4, 5, 6]])),
		"one battery holds W5..W7"
	)
	panel.call(&"refresh_profile", &"batteries")
	var row := _rack_row(0)
	var bay := Rect2(Vector2.ZERO, row.size)
	var barrels := row.get_node(^"Box/Barrels") as Control
	assert_eq(barrels.get_child_count(), 3, "three fitted chips")
	var style := _style()
	for index in barrels.get_child_count():
		var chip := barrels.get_child(index) as Control
		assert_eq(
			Rect2(chip.position, chip.size), style.bay_cell_rect(index, bay),
			"chip %d rides grid slot %d (actual %s)" % [index, index, str(chip.position)]
		)
		assert_true(bay.encloses(Rect2(chip.position, chip.size)), "and stays inside its bay")


## -------------------------------------------- 6. the retirements (T5 / Amendment 3)

## T5 retires the pane's own footer caption (LOW-3) and Amendment 3 retires the rack and
## row plates: nothing in the pane or the style still reaches for either master.
func test_the_footer_caption_and_the_plates_retire() -> void:
	var panel := _mount()
	var style := _style()
	assert_true(
		panel.get_node_or_null("%PaneFooter") == null, "the pane footer caption retires (T5)"
	)
	assert_eq(style.get(&"rack_plate_path"), null, "the rack plate retires")
	assert_eq(style.get(&"row_plate_path"), null, "and the row plate")
	assert_false(
		ResourceLoader.exists("res://ui/station/armory_style_user.tres"),
		"no user style is installed over the shipped one"
	)


## --------------------------------------------------- 7. the inspector (P4)

## P4/MED-3: a fitted barrel's inspector body carries two lines - the catalogue prose and
## the facts line - through the existing `inspect_requested` seam.
func test_the_barrel_inspector_carries_two_body_lines() -> void:
	var panel := _mount()
	_seen.clear()
	panel.call(&"_on_barrel_focused", 0, 0, &"w_laser")
	assert_eq(_seen.size(), 1, "a focus publishes one inspector line")
	if _seen.is_empty():
		return
	var title := String(_seen[0][0])
	var body := String(_seen[0][1])
	assert_eq(title, "W1 LASER MKII", "the title is the cell's own identity")
	assert_eq(body.split("\n").size(), 2, "the body is two lines (actual %s)" % body)
	assert_eq(
		body.split("\n")[0], Catalog.describe(LASER), "the catalogue prose leads"
	)
	assert_eq(
		body.split("\n")[1],
		PanelScript.INSPECT_STATS % [
			PanelScript.STATS_INSTANT, 30.0, "B1", 1
		],
		"and the facts line states the family's own salvo and dps"
	)


func test_the_chrome_layer_paints_under_every_text_and_control() -> void:
	var panel := _mount()
	var console := panel.get_node(^"%Console") as Control
	var chrome := console.get_node(^"ConsolePanels") as Control
	assert_true(chrome != null, "the console carries its code-drawn chrome layer")
	if chrome == null:
		return
	assert_eq(
		chrome.get_index(), 1,
		"the chrome sits directly over the painted plate (actual index %d)" % chrome.get_index()
	)
	var rack_rows := console.get_node(^"%RackRows") as Control
	var inventory := console.get_node(^"%InventoryMargin") as Control
	var ammo := console.get_node(^"%AmmoMargin") as Control
	assert_true(rack_rows != null, "the rack rows are in the console")
	assert_true(inventory != null, "the inventory margin is in the console")
	assert_true(ammo != null, "the ammunition margin is in the console")
	for content: Control in [rack_rows, inventory, ammo]:
		if content == null:
			continue
		assert_true(
			chrome.get_index() < content.get_index(),
			"the chrome paints under %s (chrome at %d, %s at %d)" % [
				String(content.name), chrome.get_index(),
				String(content.name), content.get_index(),
			]
		)
