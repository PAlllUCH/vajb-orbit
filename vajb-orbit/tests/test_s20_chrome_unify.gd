@tool
extends McpTestSuite
## Suite s20_chrome_unify: wave S20's ARMORY chrome unification and the station shell's
## inspector pin (UI_SPEC section 3.10 Amendment 4, A4.1-A4.5; owner feedback after the
## S18 live playtest: "i need to unify it to the rest of game (chromes) and on hover the
## bottom description panel sometis gets 'bigger' and all shifts up").
##
##  - **AC1 (A4.1, amended by A5.1 2026-09-26)** - `ui_armory_console` retires from the
##    pane: no reference in the pane's code or style, the scene's nine-slice is cleared at
##    build, and the console draws **no inner frame** - the pane's outer edge is the module
##    host's own `PanelRaised`, and every surface inside is the flat Tokens box (the 32 px
##    `ui_panel_frame` band does not fit a 260x192 bay).
##  - **AC2 (A4.2, amended by A5.1/A5.3)** - every bay cell keeps its machined recess and
##    draws the `ui_slot_weapon_*` plate **at its own 48x48**, centred (the
##    `SlotButtonWeapon` family FITTING's weapon slots wear, never stretched); `BUY` and
##    the cell's `X` wear `StationButton` / `ui_button_plate_*` (the `X` pinned at its
##    laid-out 24x29, L236).
##  - **AC3 (A4.3)** - zero hex literal outside `tools/build_theme.gd` in the wave's
##    files; the palette fields resolve from `Tokens/armory_*`; the
##    `armory_style_user.tres` override path still restyles.
##  - **AC4 (A4.3/L227)** - the `OVER CAP` label (bay chip and pack card) measures
##    >= 4.5:1 on its fill; the measured ratio is printed for the report.
##  - **AC5 (A4.4)** - the shell's `Inspector` reserves a constant height - the title line
##    plus two body lines, font-derived - at content states "", 1, 2 and 3+ lines, and the
##    `ModuleHost` rect never moves across `inspect_requested`.
##
## Amendment 3's geometry rows (console 1360x516, P3 cells, wells band, P6 derivation,
## the 13 px floor, P5 wording, T7 chip semantics) live in `test_s15_armory_layout.gd`,
## `test_s18_armory_rework.gd` and `test_d7_armory.gd` and are not repeated here.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StyleScript := preload("res://ui/station/armory_style.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s20_chrome_unify.cfg"
const STYLE_PROBE_PATH := "user://test_s20_style_probe.tres"
const PANE_SCRIPT := "res://ui/station/armory_panel.gd"
const STYLE_SCRIPT := "res://ui/station/armory_style.gd"
const SHELL_SCRIPT := "res://ui/screens/station.gd"
const FRAME_TEXTURE := "res://assets/ui/ui_panel_frame.png"
const SLOT_TEXTURE := "res://assets/ui/ui_slot_weapon_normal.png"
const PLATE_TEXTURE := "res://assets/ui/ui_button_plate_normal.png"
const CONSOLE_MASTER := "res://assets/ui/ui_armory_console.png"

const HOST := Vector2(1392.0, 610.0)
const STATION_HOST := Vector2(1920.0, 1080.0)
const FRAME_PATCH := 32.0
const SLOT_SIZE := Vector2(48.0, 48.0)
const CONTRAST_FLOOR := 4.5
const BAY_CELLS := 20

const VANGUARD: StringName = &"ship_vanguard"
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const ROCKET_PACK: StringName = &"rocket"
const MIN_UNITS := 40
const START_CREDITS := 10000

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _station: Control = null
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
	return "s20_chrome_unify"


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
	_delete_file(STYLE_PROBE_PATH)
	_profile = null


func setup() -> void:
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", [VANGUARD] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_host = Control.new()
	_host.name = "ArmoryS20Host"
	_host.theme = ThemeRes
	_host.size = HOST
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _station != null and is_instance_valid(_station):
		_station.free()
	_station = null
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
	return _panel


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _style() -> Resource:
	return _panel.call(&"style")


func _chrome() -> Control:
	return (_panel.get_node(^"%Console") as Control).get_node(^"ConsolePanels") as Control


func _rack_row(index: int) -> PanelContainer:
	return (_panel.get_node("%RackRows") as VBoxContainer).get_child(index) as PanelContainer


func _card(pack_id: StringName) -> Button:
	for child: Node in (_panel.get_node("%ArmoryRows") as Control).get_children():
		var row := child as Button
		if row != null and String(row.name).to_lower().ends_with(String(pack_id)):
			return row
	return null


## ---------------------------------------------------- 1. AC1: the chrome family (A4.1)

## A4.1: the scripted master retires from the pane - no reference in its code or style, the
## scene's nine-slice is cleared at build, and the file itself stays on disk (unwired).
func test_ac1_the_console_master_retires_for_the_panel_frame() -> void:
	var panel := _mount()
	var style := _style()
	for path: String in [PANE_SCRIPT, STYLE_SCRIPT]:
		var source := FileAccess.get_file_as_string(path)
		assert_true(
			source.find("ui_armory_console") == -1,
			"%s carries no console-master reference" % path
		)
	assert_eq(style.get(&"console_path"), null, "the style's console field retires")
	assert_eq(style.get(&"console_patch"), null, "and its patch margin")
	assert_true(
		ResourceLoader.exists(CONSOLE_MASTER), "the master file itself stays on disk"
	)
	var plate := panel.get_node("%ConsolePlate") as NinePatchRect
	assert_true(plate != null, "the scene's plate node stays")
	if plate != null:
		assert_true(plate.texture == null, "its texture is cleared at build (unwired)")
	var chrome := _chrome()
	assert_true(chrome != null, "the chrome layer ships")


## A5.1 (2026-09-26, owner-ruled): **no frame is drawn inside the console.** The two clean
## panes are the yardstick - AUCTION has no framed body surface and SHIPYARD's only frame
## is its outer `PreviewFrame` - so the bays and well halves wear the flat Tokens box and
## the pane's own outer frame stays the module host's `PanelRaised`. The asset itself stays
## registered for the shell (asserted below), so only its *use here* retires.
func test_ac1_the_console_draws_flat_tokens_boxes_and_no_inner_frame() -> void:
	var panel := _mount()
	var chrome := _chrome()
	assert_eq(
		chrome.get(&"frame_box"), null,
		"the console's chrome draws no frame nine-patch (A5.1)"
	)
	var sibling := PanelContainer.new()
	sibling.theme_type_variation = &"PanelRaised"
	panel.add_child(sibling)
	var host_frame: StyleBox = sibling.get_theme_stylebox(&"panel")
	assert_true(host_frame is StyleBoxTexture, "the shell's own frame stays registered")
	if host_frame is StyleBoxTexture:
		assert_eq(
			String((host_frame as StyleBoxTexture).texture.resource_path), FRAME_TEXTURE,
			"the host's frame is the one ui_panel_frame (the pane's outer edge)"
		)
		assert_eq(
			(host_frame as StyleBoxTexture).texture_margin_left, FRAME_PATCH,
			"at the pinned 32 px patch margin"
		)
	sibling.free()
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), 5, "all five bays draw the flat box")
	var wells: Array = panel.call(&"well_rects")
	assert_eq(wells.size(), 2, "and both wells halves")


## --------------------------------------------------- 2. AC2: cells, BUY and X (A4.2)

## A4.2 amended by A5.1/A5.3: every 2x2 bay cell draws the game's weapon-slot plate **at
## its own 48x48**, centred in the cell (never stretched to the cell's 117x52 box, which
## smeared the painted silhouette across it); the pressable chips keep
## `StationButton` / `ui_button_plate_*`.
func test_ac2_the_cells_and_the_pressables_wear_the_family() -> void:
	var panel := _mount()
	var chrome := _chrome()
	var plate_texture: Texture2D = chrome.get(&"slot_plate")
	assert_true(plate_texture != null, "the cells draw the family's own slot plate")
	if plate_texture == null:
		return
	assert_eq(
		String(plate_texture.resource_path), SLOT_TEXTURE,
		"the ui_slot_weapon_* slot chrome"
	)
	assert_eq(
		plate_texture.get_size(), SLOT_SIZE,
		"drawn at the size it was cut for (48x48), never stretched"
	)
	assert_eq(
		(chrome.get(&"cells") as Array).size(), BAY_CELLS,
		"one plate per cell of the five bays (A3's 2x2 grid stands)"
	)
	var centred: Rect2 = panel.call(&"slot_plate_rect", Rect2(0.0, 0.0, 117.0, 52.0), plate_texture)
	assert_eq(centred.position, Vector2(34.5, 2.0), "the plate centres inside the cell")
	assert_eq(centred.size, SLOT_SIZE, "and keeps its own size")
	## BUY: a StationButton at the plate's own texture.
	var card := _card(ROCKET_PACK)
	assert_true(card != null, "the rocket pack has a card")
	if card == null:
		return
	var buy := card.get_node_or_null(^"Buy") as Button
	assert_true(buy != null, "the card carries its BUY chip")
	if buy != null:
		assert_eq(buy.theme_type_variation, &"StationButton", "BUY is a StationButton")
		var plate: StyleBox = buy.get_theme_stylebox(&"normal")
		assert_true(plate is StyleBoxTexture, "drawn from the button plate atlas")
		if plate is StyleBoxTexture:
			assert_eq(
				String((plate as StyleBoxTexture).texture.resource_path), PLATE_TEXTURE,
				"ui_button_plate_*"
			)
	## X: the fitted cell's remove chip wears the same plate (it was flat before S20).
	_profile.call(&"add_module", &"w_laser", 1)
	panel.call(&"refresh_profile", &"modules")
	var chip := (_rack_row(0).get_node(^"Box/Barrels") as Control).get_child(0) as Control
	assert_true(chip != null, "one fitted chip in B1")
	if chip != null:
		var close := chip.get_node_or_null(^"Close") as Button
		assert_true(close != null, "the chip carries its X")
		if close != null:
			assert_eq(close.theme_type_variation, &"StationButton", "the X is a StationButton")
			assert_false(close.flat, "and no longer draws flat")
			assert_eq(close.size, Vector2(24.0, 29.0), "pinned at the plate's own minimum (L236)")


## ----------------------------------------------- 3. AC3: no hex, theme-resolved (A4.3)

## A4.3: hex literals live only in `tools/build_theme.gd`; the wave's files carry none and
## the palette fields resolve from the generated theme's `Tokens/armory_*`.
func test_ac3_no_hex_outside_the_builder_and_the_palette_resolves() -> void:
	var panel := _mount()
	var style := _style()
	for path: String in [PANE_SCRIPT, STYLE_SCRIPT, SHELL_SCRIPT]:
		var source := FileAccess.get_file_as_string(path)
		assert_true(
			source.find("Color(\"#") == -1,
			"%s carries no hex colour literal" % path
		)
	assert_eq(
		style.colour(&"caption"), ThemeRes.get_color(&"armory_caption", &"Tokens"),
		"the caption resolves from the theme"
	)
	assert_eq(
		style.colour(&"caption_void"), ThemeRes.get_color(&"armory_caption_void", &"Tokens"),
		"and the host's caption tone"
	)
	for role: StringName in [&"bay_bg", &"cell_bg", &"ledge_bg", &"item_bg", &"chip_bg"]:
		var token := StringName("armory_" + String(role))
		assert_eq(
			style.colour(role), ThemeRes.get_color(token, &"Tokens"),
			"%s resolves from Tokens/%s" % [role, token]
		)


## A4.3: the `armory_style_user.tres` override path stays - a user file restyles a palette
## role and dropping it returns the theme's own values.
func test_ac3_the_user_tres_override_path_still_restyles() -> void:
	var panel := _mount()
	var shipped: Color = _style().colour(&"caption")
	assert_eq(
		shipped, ThemeRes.get_color(&"armory_caption", &"Tokens"),
		"the shipped caption is the theme's own"
	)
	var probe := StyleScript.defaults()
	assert_eq(
		probe.colour(&"caption"), shipped,
		"a fresh default style resolves the same theme palette"
	)
	probe.caption = Color(0.1, 0.9, 0.2)
	assert_eq(ResourceSaver.save(probe, STYLE_PROBE_PATH), OK, "the user's style writes")
	panel.call(&"set_style_file", STYLE_PROBE_PATH)
	assert_eq(
		_style().colour(&"caption"), Color(0.1, 0.9, 0.2), "the file's palette is live"
	)
	panel.call(&"set_style_file", StyleScript.ARMORY_USER_PATH)
	assert_eq(_style().colour(&"caption"), shipped, "and the theme's returns when it drops")


## ------------------------------------------------- 4. AC4: the OVER CAP floor (L227)

## A4.3/L227: the `OVER CAP` label clears 4.5:1 on its fill, on the bay chip and on the
## section 5.1 stock chip alike. The measured ratios print for the wave report.
func test_ac4_the_over_cap_label_clears_the_contrast_floor() -> void:
	var panel := _mount()
	var style := _style()
	## The pack card's own chip: 40 rocket units against the family's 10-unit ceiling.
	_profile.call(&"add_cargo", &"ammo_rocket", MIN_UNITS)
	panel.call(&"refresh_profile", &"ammo")
	var card := _card(ROCKET_PACK)
	assert_true(card != null, "the rocket pack has a card")
	if card == null:
		return
	var tag := (card.get_node(^"Status") as Control).get_node(^"Value") as Label
	assert_eq(tag.text, PanelScript.TAG_OVER_CAP, "the fixture's rocket reads OVER CAP")
	var fill: Color = style.colour(&"chip_danger_bg")
	var card_ratio := _contrast(tag.get_theme_color(&"font_color"), fill)
	assert_true(
		card_ratio >= CONTRAST_FLOOR,
		"the card's OVER CAP label clears 4.5:1 (measured %.2f)" % card_ratio
	)
	## The bay chip: a destroyer battery holding the hardcap's four cells.
	_profile.set(&"_active_ship", DESTROYER)
	_profile.set(&"_owned_ships", [DESTROYER] as Array[StringName])
	_profile.set(&"_modules", {})
	var fit: Dictionary = FitData.standard_fit(DESTROYER)
	var weapons: Array = []
	for index in FitData.slot_capacity(DESTROYER, WEAPON_SLOT):
		weapons.append("" if index > 3 else ("w_laser" if index % 2 == 0 else "w_cannon"))
	fit[WEAPON_SLOT] = weapons
	_profile.call(&"set_fit", DESTROYER, fit)
	_profile.call(&"set_battery_groups", DESTROYER, [[0, 1, 2, 3]])
	panel.call(&"refresh_profile", &"batteries")
	var state := _rack_row(0).get_node(^"Box/Head/State") as Label
	assert_eq(state.text, PanelScript.RACK_STATE_AT_CAP, "the four-cell battery reads AT CAP")
	var bay_ratio := _contrast(state.get_theme_color(&"font_color"), fill)
	assert_true(
		bay_ratio >= CONTRAST_FLOOR,
		"the bay's OVER CAP label clears 4.5:1 (measured %.2f)" % bay_ratio
	)
	print("[s20] OVER CAP ratio: card=%.2f bay=%.2f on %s" % [card_ratio, bay_ratio, fill])
	## The resting chips keep the caption tone on the resting fill.
	var ready := _rack_row(1).get_node(^"Box/Head/State") as Label
	assert_eq(ready.text, PanelScript.RACK_READY, "an empty battery reads READY")
	assert_true(
		_contrast(ready.get_theme_color(&"font_color"), style.colour(&"chip_bg"))
		>= CONTRAST_FLOOR,
		"the READY label clears the floor on chip_bg"
	)


## ---------------------------------------- 5. AC5: the constant inspector (A4.4)

## A4.4: the shell's Inspector reserves one title line plus `INSPECTOR_BODY_MAX_LINES` body
## lines as font-derived minimums, so "", one line, two lines and 3+ line hover content all
## reserve the same box and the ModuleHost never reflows when `inspect_requested` fires.
func test_ac5_the_inspector_reserves_a_constant_height() -> void:
	_station = StationScene.instantiate() as Control
	_host.size = STATION_HOST
	_host.add_child(_station)
	var title := _station.get_node(^"%InspectorTitle") as Label
	var body := _station.get_node(^"%InspectorBody") as Label
	var inspector := _station.get_node(^"%Inspector") as Control
	var module_host := _station.get_node(^"%ModuleHost") as Control
	var panels: Array = _station.get(&"_panels")
	assert_eq(panels.size(), 8, "the shell mounted its eight panes")
	var pane := panels[0] as CanvasItem
	assert_true(
		pane != null and pane.has_signal(&"inspect_requested"), "the armory pane ships"
	)
	if title == null or body == null or inspector == null or module_host == null or pane == null:
		return
	## The pin itself: measured against the label's own shaped minimum for that many lines
	## (not re-derived from the production formula).
	var title_line := _label_min_for(title, "T")
	var body_lines := _label_min_for(body, _two_lines("a", "b"))
	assert_true(title_line > 0.0 and body_lines > 0.0, "both labels resolve a theme font")
	assert_eq(
		title.custom_minimum_size.y, title_line,
		"the title line is reserved, font-derived (%.1f)" % title_line
	)
	assert_eq(
		body.custom_minimum_size.y, body_lines,
		"and the body's two lines (INSPECTOR_BODY_MAX_LINES, %.1f)" % body_lines
	)
	## The four content states, each measured after a forced layout settle.
	var states: Array = [
		["", ""],
		["LASER CELLS", "One line of catalogue prose."],
		["LASER CELLS", _two_lines("Two lines", "of hover prose.")],
		["LASER CELLS", "Four\nlines\nof\nhover prose."],
	]
	var heights: Array[float] = []
	var host_rects: Array[Rect2] = []
	var mins: Array[float] = []
	for state: Array in states:
		pane.inspect_requested.emit(String(state[0]), String(state[1]), false)
		_settle_station()
		heights.append(inspector.size.y)
		host_rects.append(Rect2(module_host.position, module_host.size))
		mins.append(inspector.get_combined_minimum_size().y)
	for index in range(1, heights.size()):
		assert_true(
			is_equal_approx(heights[index], heights[0]),
			"the inspector height at state %d is state 0's (%.1f vs %.1f)"
			% [index, heights[index], heights[0]]
		)
		assert_eq(
			host_rects[index], host_rects[0],
			"and the ModuleHost rect never moves (state %d)" % index
		)
	for index in range(1, mins.size()):
		assert_true(
			is_equal_approx(mins[index], mins[0]),
			"the reserved minimum is constant (state %d: %.1f vs %.1f)"
			% [index, mins[index], mins[0]]
		)
	assert_eq(title.text, "LASER CELLS", "the last emit wrote the title")
	print("[s20] inspector heights=%s host=%s title_pin=%.1f body_pin=%.1f" % [
		str(heights), str(host_rects[0]), title.custom_minimum_size.y,
		body.custom_minimum_size.y,
	])


## Two body lines, the pane's own P4 shape.
func _two_lines(first: String, second: String) -> String:
	return first + "\n" + second


## A label's own shaped minimum height for a given text, measured off the label itself.
func _label_min_for(label: Label, text: String) -> float:
	var saved := label.text
	label.text = text
	var height := label.get_minimum_size().y
	label.text = saved
	return height


## The frame after the build, as the shell's own containers make it: the page and the
## block's own containers reflow to the new minimums, top down.
func _settle_station() -> void:
	var blocks: Array[Container] = [
		_station.get_node(^"Layout") as Container,
		_station.get_node(^"Layout/Page") as Container,
		_station.get_node(^"Layout/Page/Body") as Container,
		_station.get_node(^"Layout/Page/Body/ModuleHost") as Container,
		_station.get_node(^"Layout/Page/Body/ModuleHost/HostMargin") as Container,
		_station.get_node(^"Layout/Page/Inspector") as Container,
		_station.get_node(^"Layout/Page/Inspector/InspectorMargin") as Container,
		_station.get_node(^"Layout/Page/Inspector/InspectorMargin/InspectorBox") as Container,
	]
	for _pass in 2:
		for block: Container in blocks:
			block.notification(Container.NOTIFICATION_SORT_CHILDREN)


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
