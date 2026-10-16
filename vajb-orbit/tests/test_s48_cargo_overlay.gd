@tool
extends McpTestSuite
## Suite s48_cargo_overlay: UI_SPEC section 18 A7-A13's C-key cargo overlay - the
## 18.2 rework (owner 2026-10-14: refinery look, armory categories, per-slot
## dispose, sort by categories) on the two A7 planes. One row per pinned
## acceptance:
##   1. the surface is the N28 sheet idiom, one scene for both planes: full-rect STOP
##      root, void_base 60 % dimmer, centred panel_raised panel, margin 16, VBox 12,
##      A15's one geometry (720 wide, the 80 %-viewport cap tall, held while open),
##      the <= 0.2 s envelope;
##   2. the title reads CARGO - <n>/<cap> UNITS (the summed hold over the active hull's
##      cargo column, 08 section 3);
##   3. A11's category strip is the armory MENU_TABS idiom: six tabs (the A9 five +
##      ALL), the active one pressed and `text_primary`, the rest `text_dim`, and a tab
##      filters the one list;
##   4. A10's slot rows are the refinery grammar: 76-tall C4 strips, the 40 px material
##      icon at its own rect (the refinery ink law), StationValue/StationMeta title box,
##      the 130 AMOUNT cell, A12's 96x32 DISPOSE chip per row, the ITEM/AMOUNT/ACTION
##      column band, the A13 group bands in A9's order;
##   5. A13's sort chip cycles CATEGORY -> NAME -> AMOUNT (NAME flat A-Z, AMOUNT biggest
##      stack first, CATEGORY the grouped default);
##   6. A12's DISPOSE is the one transaction: the row's whole hold stack through
##      remove_cargo, the refresh landing the same frame, ammunition rows disposing only
##      the hold's ammo_* units (the loaded pack stays, the chip disables at 0 units);
##   7. the station shell handles C from any pane; C again, ESC (its P19 ladder step) or
##      the scrim closes it; focus returns to the trigger;
##   8. the flight plane: the layer-20 host above the HUD's own layer 10, the poll
##      driving the overlay and both mirrors, ESC as the one topmost step before the
##      map-deck step, nothing paused, the same slot rows from the same overlay and the
##      same dispose writing the shared profile.
##
## The flight rows ride one game.tscn mounted once in suite_setup (the
## test_engine2_wiring.gd discipline): the launch `_ready` runs against the suite's
## staged fixture, and every row's `setup()` re-stages the fixture afterwards, so
## the launch's auto-load draw (which consumes hold units) cannot move the hold
## the flight rows read.
##
##   9. the 2026-10-15 round (UI_SPEC section 18.3): A14 - hold units are an
##      ammunition row's existence test (a loaded pack over an empty hold lists
##      nothing); A15 - the surface holds one geometry while it is open; A16 -
##      the title column never collapses.

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const OverlayScene := preload("res://ui/dialogs/cargo_overlay.tscn")
const OverlayScript := preload("res://ui/dialogs/cargo_overlay.gd")
const GameScene := preload("res://game/game.tscn")
const GameScript := preload("res://game/game.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const SUITE_ID := "s48_cargo_overlay"
const PROFILE_PATH := "user://test_s48_cargo_overlay.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"
const EXCHANGE_DECK := 2
const TOKENS_TYPE: StringName = &"Tokens"

const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser", &"w_cannon"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}
const FIXTURE_PACKS: Dictionary = {&"laser": 120, &"cannon": 60}
const FIXTURE_CARGO: Dictionary = {
	&"mineral_iron": 7,
	&"mineral_gold": 3,
	&"ingot_titanium": 4,
	&"comp_scrap_1": 2,
	&"comp_elec_2": 1,
	&"comp_pow_1": 5,
	&"comp_pow_3": 2,
	&"ammo_laser": 2,
}
const FIXTURE_HELD := 26
## The A10/A12 fixture in A9's category order: [id, category, name, meta, amount,
## dispose-armed]. A14: the cannon family (its 60-round pack loaded, the hold
## empty) lists NO row - hold units are the row's existence test.
const FIXTURE_SLOTS := [
	[&"ammo_laser", &"ammo", "LASER CELLS", "120 ROUNDS IN PACK", 2, true],
	[&"mineral_iron", &"ore", "IRON ORE", "TIER 1 ORE", 7, true],
	[&"mineral_gold", &"ore", "GOLD ORE", "TIER 3 ORE", 3, true],
	[&"ingot_titanium", &"ingots", "TITANIUM INGOT", "TIER 2 INGOT", 4, true],
	[&"comp_scrap_1", &"components", "TORN PLATING", "GRADE 1 COMPONENT", 2, true],
	[&"comp_elec_2", &"components", "LOGIC ARRAY", "GRADE 2 COMPONENT", 1, true],
	[&"comp_pow_1", &"fuel", "FUEL CELL", "GRADE 1 FUEL CELL", 5, true],
	[&"comp_pow_3", &"fuel", "EMBER CELL", "GRADE 3 FUEL CELL", 2, true],
]
const FIXTURE_BANDS := ["AMMUNITION", "ORE", "INGOTS", "COMPONENTS", "FUEL CELLS"]
const IDLE_INK := Color(1.0, 1.0, 1.0, 0.72)

var _profile: Node = null
var _station: Control = null
var _game: Node2D = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the station")
		return
	var service := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = service
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_credits", 50000)
	_profile.call(&"set_fit", SHIP, FIXTURE_FIT)
	_profile.set(&"_ammo", FIXTURE_PACKS.duplicate(true))
	_stage_cargo(FIXTURE_CARGO)
	_mount_game()


func suite_teardown() -> void:
	_free_screen()
	if _game != null and is_instance_valid(_game):
		_game.free()
	_game = null
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"set_fits", _previous_fits)
	_profile.set(&"_ammo", _previous_ammo)
	_stage_cargo(_previous_cargo)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_free_screen()
	## Every method starts from the suite's own fixture: an earlier row's emptied hold
	## must not leak into the next row's reads.
	_stage_cargo(FIXTURE_CARGO)
	_profile.set(&"_ammo", FIXTURE_PACKS.duplicate(true))
	_settle_cargo()


func _free_screen() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
		_station = null


func _stage_cargo(cargo: Dictionary) -> void:
	_profile.set(&"_cargo", cargo.duplicate(true))
	_profile.call(&"flush")


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


## A fresh shell per row under a themed host, added to the profile autoload (the runner
## calls every test from inside its own `_ready`, when `/root` is still busy).
func _mount() -> Control:
	var host := Control.new()
	host.name = "S48Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


## The flight plane, mounted once (the engine2 discipline): its launch `_ready` runs
## against the suite's staged fixture - the packs feed the battery, the hold carries
## no ammo item, so the auto-load draw cannot move the fixture hold.
func _mount_game() -> void:
	_game = GameScene.instantiate() as Node2D
	if _game == null:
		fail_setup("game.tscn did not instantiate")
		return
	_profile.add_child(_game)


## One flight poll beat: press, call the poll, release. The runner grants no frames,
## so the press is "just pressed" for the direct call that follows it.
func _poll_cargo() -> void:
	Input.action_press(&"cargo_toggle")
	_game.call(&"_update_cargo_input")
	Input.action_release(&"cargo_toggle")


## The flight rows' entry law: whatever an earlier row left open, the next one starts
## from the closed overlay - closed through the poll itself, the one driver.
func _settle_cargo() -> void:
	if _game == null or not is_instance_valid(_game):
		return
	var overlay := _game.get(&"_cargo_overlay") as Control
	if overlay != null and bool(overlay.call(&"is_open")):
		_poll_cargo()


func _overlay(screen: Control) -> Control:
	return screen.get(&"_cargo_overlay") as Control


func _c_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_C
	event.pressed = true
	return event


func _scrim_event() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event


func _token(name: StringName) -> Color:
	return ThemeRes.get_color(name, TOKENS_TYPE)


func _capacity() -> int:
	return int(Catalog.ship(SHIP).get(&"cargo", 0))


func _open_overlay() -> Control:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	return _overlay(screen)


func _slot_names(overlay: Control) -> PackedStringArray:
	var out := PackedStringArray()
	for row: Dictionary in overlay.call(&"slot_rows"):
		out.append(String(row[&"name"]))
	return out


func _slot_ids(overlay: Control) -> Array:
	var out: Array = []
	for row: Dictionary in overlay.call(&"slot_rows"):
		out.append(StringName(row[&"id"]))
	return out


## ------------------------------------------------- 1. the surface is the N28 idiom (item 1)

func test_the_surface_is_the_n28_idiom() -> void:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	var overlay := _overlay(screen)
	assert_true(overlay != null and overlay.visible, "C opens the overlay in its seat")
	if overlay == null:
		return
	assert_eq(overlay.anchor_right, 1.0, "the root is full-rect (right anchor)")
	assert_eq(overlay.anchor_bottom, 1.0, "and the bottom anchor")
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "no click-through")
	var dimmer := overlay.get_node(NodePath("%CargoDimmer")) as ColorRect
	var expected := _token(&"void_base")
	expected.a = OverlayScript.DIMMER_ALPHA
	assert_true(dimmer.color.is_equal_approx(expected), "the dim is void_base at 60 %")
	var panel := overlay.get_node(NodePath("%CargoPanel")) as PanelContainer
	assert_eq(panel.theme_type_variation, &"PanelRaised", "the panel is panel_raised")
	var margin := overlay.get_node(NodePath("%CargoMargin")) as MarginContainer
	assert_eq(margin.get_theme_constant(&"margin_left"), 16, "the margin is 16")
	var content := overlay.get_node(NodePath("%CargoContent")) as VBoxContainer
	assert_eq(content.get_theme_constant(&"separation"), 12, "the VBox separates by 12")
	assert_true(
		panel.custom_minimum_size.x == OverlayScript.PANEL_WIDTH,
		"A15's one geometry: the panel's width is the 720 ceiling, not a fit"
	)
	var scroll := overlay.get_node(NodePath("%CargoScroll")) as ScrollContainer
	assert_true(scroll != null, "the body scrolls under the 80 %-viewport rule")
	assert_eq(
		float(OverlayScript.MAX_HEIGHT_RATIO), 0.8, "the height cap is N32's 80 %"
	)
	assert_true(
		float(OverlayScript.MOTION_SECONDS) <= 0.2, "the envelope obeys N29 (<= 0.2 s)"
	)
	## The rework's own skeleton: the title row (title + sort chip), the tab strip, the
	## column band and the rows list, all inside the one content VBox.
	assert_true(overlay.get_node(NodePath("%CargoTitleRow")) != null, "the title row exists")
	assert_true(overlay.get_node(NodePath("%CargoSort")) != null, "with A13's sort chip")
	var tabs := overlay.get_node(NodePath("%CargoTabs")) as HBoxContainer
	assert_true(tabs != null, "the A11 tab strip exists")
	var band := overlay.get_node(NodePath("%CargoBand")) as HBoxContainer
	assert_true(band != null, "the A10 column band exists")
	var rows := overlay.get_node(NodePath("%CargoRows")) as VBoxContainer
	assert_eq(rows.get_theme_constant(&"separation"), 8, "the rows separate by 8")
	var hint := overlay.get_node(NodePath("%CargoHint")) as Label
	assert_eq(hint.text, "ESC · CLOSE", "the close hint is wired (S48 left it dead)")
	var layer := screen.get(&"_cargo_layer") as CanvasLayer
	assert_eq(layer.layer, StationScript.CARGO_LAYER, "the shell seat rides its own layer")
	assert_true(
		layer.layer < (screen.get(&"_sheet_layer") as CanvasLayer).layer,
		"below the sheet's dialog layer (section 12.2's stack law)"
	)
	assert_true(
		layer.layer < (screen.get(&"_confirm_layer") as CanvasLayer).layer,
		"and below the confirm's layer"
	)


## ----------------------------------------------- 2. the title (item 2)

func test_the_title_carries_the_hold_and_the_hull_capacity() -> void:
	var overlay := _open_overlay()
	assert_eq(
		overlay.call(&"title_text"),
		"CARGO — %d/%d UNITS" % [FIXTURE_HELD, _capacity()],
		"the title sums the hold over the active hull's cargo column (08 section 3)"
	)


## ------------------------------- 2b. A15's one geometry (the owner's 2026-10-15 round)

func test_the_surface_holds_one_geometry_while_open() -> void:
	var overlay := _open_overlay()
	var panel := overlay.get_node(NodePath("%CargoPanel")) as PanelContainer
	var scroll := overlay.get_node(NodePath("%CargoScroll")) as ScrollContainer
	var stylebox := panel.get_theme_stylebox(&"panel")
	var inset := 0.0
	if stylebox != null:
		inset = stylebox.get_margin(SIDE_TOP) + stylebox.get_margin(SIDE_BOTTOM)
	var cap: float = float(HOST.y) * OverlayScript.MAX_HEIGHT_RATIO \
			- OverlayScript.PANEL_MARGIN * 2.0 - inset
	assert_eq(panel.custom_minimum_size.x, OverlayScript.PANEL_WIDTH, "the width is the 720 ceiling")
	assert_eq(scroll.custom_minimum_size.y, cap, "the scroll holds the 80 % viewport cap")
	for category in [&"ore", &"ingots", &"components", &"fuel", &"all"]:
		overlay.call(&"select_category", category)
	for mode in 3:
		overlay.call(&"cycle_sort")
	assert_eq(panel.custom_minimum_size.x, OverlayScript.PANEL_WIDTH, "tab switches do not resize")
	assert_eq(scroll.custom_minimum_size.y, cap, "sort cycles do not resize")
	var chip: Button = overlay.call(&"dispose_button", &"mineral_iron")
	chip.pressed.emit()
	assert_eq(panel.custom_minimum_size.x, OverlayScript.PANEL_WIDTH, "a dispose does not resize")
	assert_eq(scroll.custom_minimum_size.y, cap, "and the height holds too")
	var band := overlay.get_node(NodePath("%CargoBand")) as HBoxContainer
	var gap := band.get_node(NodePath("IconGap")) as Control
	assert_eq(
		gap.custom_minimum_size.x, OverlayScript.BAND_LEAD_GAP,
		"the band's lead gap carries the row's inner margin (the captions seat over the columns)"
	)


## A23 (the owner's 2026-10-16 third instruction): the overlay is a moveable
## window - the title row drags it, a CLOSE chip closes it, and the seat is
## free (the panel rides a plain control, centered on open, clamped inside the
## viewport). A15's own geometry law is untouched.
func test_a23_the_window_moves_and_closes() -> void:
	var overlay := _open_overlay()
	var title_row := overlay.get_node(NodePath("%CargoTitleRow")) as Control
	assert_true(title_row != null, "the title row ships")
	if title_row == null:
		return
	assert_eq(
		title_row.mouse_filter, Control.MOUSE_FILTER_STOP,
		"the title row takes the drag press"
	)
	assert_eq(
		title_row.mouse_default_cursor_shape, Control.CURSOR_DRAG,
		"and it advertises the drag"
	)
	var close_chip := overlay.get_node(NodePath("%CargoClose")) as Button
	assert_true(close_chip != null, "the CLOSE chip ships (A23)")
	if close_chip == null:
		return
	assert_eq(close_chip.text, "CLOSE", "and carries its word")
	var panel := overlay.get_node(NodePath("%CargoPanel")) as PanelContainer
	var seat := panel.get_parent() as Control
	assert_true(
		seat != null and seat.name == StringName("CargoCenter")
			and not (seat is CenterContainer),
		"the window rides a free seat, not a centering container"
	)
	var view := overlay.get_viewport_rect().size
	assert_true(
		panel.position.x >= 0.0 and panel.position.y >= 0.0
			and panel.position.x + panel.size.x <= view.x
			and panel.position.y + panel.size.y <= view.y,
		"the open seats the whole window inside its viewport"
	)
	var before := panel.position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = Vector2(100.0, 100.0)
	overlay.call(&"_on_title_row_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.global_position = Vector2(160.0, 140.0)
	overlay.call(&"_on_title_row_input", motion)
	assert_true(
		panel.position.x > before.x and panel.position.y > before.y,
		"the drag moves the window"
	)
	var far := InputEventMouseMotion.new()
	far.button_mask = MOUSE_BUTTON_MASK_LEFT
	far.global_position = Vector2(100000.0, 100000.0)
	overlay.call(&"_on_title_row_input", far)
	assert_true(
		panel.position.x + panel.size.x <= view.x + 0.01
			and panel.position.y + panel.size.y <= view.y + 0.01,
		"and the window clamps inside its viewport"
	)
	overlay.call(&"close")


## ------------------------------- 3. A11's category strip - the armory idiom (item 3)

func test_the_category_strip_is_the_armory_idiom() -> void:
	var overlay := _open_overlay()
	var ids: Array = overlay.call(&"category_ids")
	assert_eq(
		ids, [&"ammo", &"ore", &"ingots", &"components", &"fuel", &"all"],
		"six tabs: A9's five words + ALL, in A9's order"
	)
	assert_eq(
		StringName(overlay.call(&"active_category")), &"all",
		"the default tab is ALL"
	)
	var tabs := overlay.get_node(NodePath("%CargoTabs")) as HBoxContainer
	var labels := PackedStringArray()
	for child: Node in tabs.get_children():
		labels.append((child as Button).text)
	assert_eq(
		labels, PackedStringArray(["AMMUNITION", "ORE", "INGOTS", "COMPONENTS", "FUEL CELLS", "ALL"]),
		"the armory's own tab words"
	)
	var all_tab := tabs.get_node(NodePath("TabAll")) as Button
	assert_true(all_tab.toggle_mode, "the tabs are the armory's toggle buttons")
	assert_eq(all_tab.custom_minimum_size.y, 32.0, "at the armory's own 32 px minimum")
	assert_true(all_tab.button_pressed, "the default tab is pressed")
	assert_eq(
		all_tab.get_theme_color(&"font_color"), _token(&"text_primary"),
		"the active tab reads text_primary"
	)
	var ore_tab := tabs.get_node(NodePath("TabOre")) as Button
	assert_false(ore_tab.button_pressed, "an inactive tab is not pressed")
	assert_eq(
		ore_tab.get_theme_color(&"font_color"), _token(&"text_dim"),
		"and reads text_dim (the theme's TabBar language)"
	)
	## The one door both the tab press and a probe share filters the list.
	overlay.call(&"select_category", &"ore")
	assert_eq(_slot_ids(overlay), [&"mineral_iron", &"mineral_gold"], "the ORE tab lists the ore stacks only")
	assert_eq(PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(), "no bands in a single-category view")
	assert_true(ore_tab.button_pressed, "the ORE tab took the pressed state")
	assert_false(all_tab.button_pressed, "and ALL gave it up")


## ------------------------------- 4. A10's slot rows - the refinery grammar (item 4)

func test_the_slot_rows_carry_the_refinery_grammar() -> void:
	var overlay := _open_overlay()
	var rows: Array = overlay.call(&"slot_rows")
	assert_eq(rows.size(), FIXTURE_SLOTS.size(), "one slot per held stack (A14: no pack-only rows)")
	for index in rows.size():
		var row: Dictionary = rows[index]
		var pinned: Array = FIXTURE_SLOTS[index]
		assert_eq(StringName(row[&"id"]), StringName(pinned[0]), "slot %d's id" % index)
		assert_eq(StringName(row[&"category"]), StringName(pinned[1]), "slot %d's category" % index)
		assert_eq(String(row[&"name"]), String(pinned[2]), "slot %d's name" % index)
		assert_eq(String(row[&"meta"]), String(pinned[3]), "slot %d's meta line" % index)
		assert_eq(int(row[&"amount"]), int(pinned[4]), "slot %d's amount is its hold stack" % index)
		assert_eq(bool(row[&"dispose"]), bool(pinned[5]), "slot %d's chip arming" % index)
	assert_eq(
		PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(FIXTURE_BANDS),
		"BY CATEGORY groups the ALL view under the five A9 bands"
	)
	## The band's own captions, seated over the row's columns.
	var band := overlay.get_node(NodePath("%CargoBand")) as HBoxContainer
	var lead := band.get_node(NodePath("HeaderLead")) as Label
	assert_eq(lead.text, "ITEM", "the leading caption")
	var amount_header := band.get_node(NodePath("HeaderAmount")) as Label
	assert_eq(amount_header.text, "AMOUNT", "the amount column's caption")
	assert_eq(amount_header.custom_minimum_size.x, 130.0, "at the 130 cell")
	assert_eq(
		(band.get_node(NodePath("HeaderAction")) as Label).text, "ACTION",
		"the chip column's caption"
	)
	## The row's own anatomy: the C4 strip at 76, the 40 px icon at its own rect with
	## the refinery's idle ink, the chip at the ActionInline box.
	var iron := overlay.get_node(NodePath("%CargoRows/SlotMineralIron")) as Button
	assert_eq(iron.custom_minimum_size.y, 76.0, "the row is the refinery's 76-tall strip")
	assert_eq(String(iron.get_meta(&"chrome_class", "")), "C4", "wearing the C4 row strip")
	var icon := iron.get_node(NodePath("RowInner/RowBox/Icon")) as TextureRect
	assert_eq(icon.custom_minimum_size, Vector2(40, 40), "the material icon at its own 40 rect")
	assert_eq(icon.modulate, IDLE_INK, "raw catalogue art takes the refinery's idle ink")
	var chip := iron.get_node(NodePath("RowInner/RowBox/Dispose")) as Button
	assert_eq(chip.custom_minimum_size, Vector2(96, 32), "the DISPOSE chip is the ActionInline 96x32")
	assert_eq(chip.text, "DISPOSE", "with the pinned word")
	assert_false(chip.disabled, "armed on a held stack")
	var laser_chip := overlay.get_node(NodePath("%CargoRows/SlotAmmoLaser/RowInner/RowBox/Dispose")) as Button
	assert_false(laser_chip.disabled, "a held ammo family arms its chip")
	## A14: the cannon pack rides loaded (60 rounds) with an empty hold - it lists
	## no row at all; the owner's "shows ammo even if i have 0 ammo".
	assert_true(
		overlay.call(&"dispose_button", &"ammo_cannon") == null,
		"a pack with rounds and an empty hold lists no row"
	)
	assert_false(_slot_ids(overlay).has(&"ammo_cannon"), "the cannon family is not drawn")
	## A16: the title column never collapses - the box carries the fixed column.
	var title_box := iron.get_node(NodePath("RowInner/RowBox/TitleBox")) as VBoxContainer
	assert_eq(
		title_box.custom_minimum_size.x, float(overlay.get(&"_title_col")),
		"the title box carries the overlay's title column (A16: it never collapses)"
	)
	assert_gt(OverlayScript.TITLE_COL, 200.0, "the column leaves the names room")


## ----------------------------------------------- 5. A13's sort cycle (item 5)

func test_the_sort_chip_cycles_the_three_modes() -> void:
	var overlay := _open_overlay()
	var chip := overlay.get_node(NodePath("%CargoSort")) as Button
	assert_eq(
		StringName(overlay.call(&"sort_mode")), &"category",
		"CATEGORY is the default (the grouped view)"
	)
	assert_eq(chip.text, "SORT: CATEGORY", "the chip reads the mode")
	overlay.call(&"cycle_sort")
	assert_eq(StringName(overlay.call(&"sort_mode")), &"name", "one press reads NAME")
	assert_eq(chip.text, "SORT: NAME", "the chip follows")
	assert_eq(
		_slot_names(overlay),
		PackedStringArray([
			"EMBER CELL", "FUEL CELL", "GOLD ORE", "IRON ORE",
			"LASER CELLS", "LOGIC ARRAY", "TITANIUM INGOT", "TORN PLATING",
		]),
		"NAME reads A-Z flat across the whole hold"
	)
	assert_eq(PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(), "no bands in a flat read")
	overlay.call(&"cycle_sort")
	assert_eq(StringName(overlay.call(&"sort_mode")), &"amount", "the next press reads AMOUNT")
	assert_eq(
		_slot_names(overlay),
		PackedStringArray([
			"IRON ORE", "FUEL CELL", "TITANIUM INGOT", "GOLD ORE", "EMBER CELL",
			"LASER CELLS", "TORN PLATING", "LOGIC ARRAY",
		]),
		"AMOUNT reads the biggest stack first, ties by name"
	)
	overlay.call(&"cycle_sort")
	assert_eq(StringName(overlay.call(&"sort_mode")), &"category", "the cycle wraps")
	assert_eq(
		PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(FIXTURE_BANDS),
		"and CATEGORY re-groups the five bands"
	)


## ----------------------------------------------- 6. A12's dispose (item 6)

func test_dispose_removes_the_whole_stack_through_the_profile() -> void:
	var overlay := _open_overlay()
	var chip: Button = overlay.call(&"dispose_button", &"mineral_iron")
	assert_true(chip != null and not chip.disabled, "the iron row's chip is live")
	chip.pressed.emit()
	assert_eq(
		int(_profile.call(&"cargo_qty", &"mineral_iron")), 0,
		"one press removes the row's whole hold stack through remove_cargo"
	)
	assert_false(_slot_ids(overlay).has(&"mineral_iron"), "the row left the list the same frame")
	assert_true(
		overlay.get_node_or_null(NodePath("%CargoRows/SlotMineralIron")) == null,
		"and the row node left the tree"
	)
	assert_eq(
		int(_profile.call(&"cargo_qty", &"mineral_gold")), 3,
		"the other stacks are untouched"
	)
	assert_eq(
		overlay.call(&"title_text"), "CARGO — %d/%d UNITS" % [FIXTURE_HELD - 7, _capacity()],
		"the title recounts the emptied hold"
	)


func test_ammo_rows_dispose_only_the_hold_units() -> void:
	var cargo := FIXTURE_CARGO.duplicate()
	cargo[&"ammo_laser"] = 3
	_stage_cargo(cargo)
	var overlay := _open_overlay()
	var laser: Dictionary = {}
	for row: Dictionary in overlay.call(&"slot_rows"):
		if StringName(row[&"id"]) == &"ammo_laser":
			laser = row
	assert_eq(int(laser[&"amount"]), 3, "the laser cells row reads the hold units")
	assert_true(bool(laser[&"dispose"]), "with an armed chip")
	assert_eq(String(laser[&"meta"]), "120 ROUNDS IN PACK", "the pack read rides the meta line")
	var chip: Button = overlay.call(&"dispose_button", &"ammo_laser")
	chip.pressed.emit()
	assert_eq(
		int(_profile.call(&"cargo_qty", &"ammo_laser")), 0,
		"the dispose removed the hold's ammo units"
	)
	assert_eq(
		int(_profile.call(&"ammo_of", &"laser")), 120,
		"the loaded pack is the ship's and stays (A12's carve-out)"
	)
	var chip_after: Button = overlay.call(&"dispose_button", &"ammo_laser")
	assert_true(chip_after == null, "A14: with the hold empty the row leaves the list")
	assert_eq(
		int(_profile.call(&"ammo_of", &"laser")), 120,
		"the loaded pack is the ship's and stays (A12's carve-out)"
	)


func test_a_zero_hold_with_loaded_packs_lists_nothing() -> void:
	## A14's own row: the packs ride loaded, the hold is empty - nothing lists,
	## whichever way the sort reads (the owner's "shows ammo even if i have 0 ammo").
	_stage_cargo({})
	var overlay := _open_overlay()
	assert_eq((overlay.call(&"slot_rows") as Array).size(), 0, "no rows at an empty hold")
	assert_eq(
		PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(["NONE HELD"]),
		"the empty state reads NONE HELD"
	)
	assert_eq(
		overlay.call(&"title_text"), "CARGO — 0/%d UNITS" % _capacity(),
		"and the title's <n> is the emptied hold"
	)


func test_an_empty_category_reads_none_held() -> void:
	_stage_cargo({})
	var overlay := _open_overlay()
	overlay.call(&"select_category", &"fuel")
	assert_eq(
		PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(["NONE HELD"]),
		"an empty single category reads the 5.8 empty-state caption"
	)
	overlay.call(&"select_category", &"all")
	assert_eq(
		PackedStringArray(overlay.call(&"band_texts")), PackedStringArray(["NONE HELD"]),
		"the grouped ALL view reads one empty state (A14: the packs summon nothing)"
	)


## ------------------------------------------- 7. the shell's station wiring (item 7)

func test_the_shell_handles_c_from_any_pane() -> void:
	var screen := _mount()
	var terminal := screen.get_node(NodePath("%TerminalButton")) as Control
	terminal.grab_focus()
	screen.call(&"_unhandled_input", _c_event())
	var overlay := _overlay(screen) as Control
	assert_true(bool(overlay.call(&"is_open")), "C opens the overlay from the landing pane")
	(overlay as Control).call(&"close")
	screen.call(&"_select_module", EXCHANGE_DECK, true)
	screen.call(&"_unhandled_input", _c_event())
	assert_true(bool(overlay.call(&"is_open")), "and from any other pane")
	screen.call(&"_unhandled_input", _c_event())
	assert_false(bool(overlay.call(&"is_open")), "C again closes it (A8's close law)")
	terminal.grab_focus()
	screen.call(&"_unhandled_input", _c_event())
	screen.call(&"_handle_cancel")
	assert_false(bool(overlay.call(&"is_open")), "ESC closes it as the shell's own step")
	var leave := screen.get_node(NodePath("%LeaveConfirm")) as Control
	assert_false(leave.visible, "and the ladder stops there - no leave confirm")
	screen.call(&"_unhandled_input", _c_event())
	var dimmer := overlay.get_node(NodePath("%CargoDimmer")) as ColorRect
	dimmer.gui_input.emit(_scrim_event())
	assert_false(bool(overlay.call(&"is_open")), "the scrim closes it (N38)")
	## The focus return rides the fade's own callback (N39); the runner grants no
	## frames, so the callback is driven the way the S47 suite drives its beats.
	(overlay as Control).call(&"_on_closed")
	assert_eq(
		screen.get_viewport().gui_get_focus_owner(), terminal,
		"focus returns to the trigger (N39)"
	)


func test_the_ladder_keeps_the_higher_overlays_in_front() -> void:
	var screen := _mount()
	var overlay := _overlay(screen) as Control
	screen.call(&"_toggle_drawer")
	screen.call(&"_unhandled_input", _c_event())
	assert_false(bool(overlay.call(&"is_open")), "C does not open under the drawer")
	screen.call(&"_close_drawer", true)
	screen.call(&"open_sheet", {&"name": "T", &"stats": ""})
	screen.call(&"_unhandled_input", _c_event())
	assert_false(bool(overlay.call(&"is_open")), "nor under the sheet")
	screen.call(&"_handle_cancel")
	screen.call(&"_unhandled_input", _c_event())
	assert_true(bool(overlay.call(&"is_open")), "once the sheet is away, C opens")
	screen.call(&"_handle_cancel")


func test_the_cargo_binding_is_the_pinned_c_key() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_C
	event.pressed = true
	assert_true(
		InputMap.event_is_action(event, &"cargo_toggle"),
		"cargo_toggle is bound to C (project.godot's shipped event)"
	)
	assert_true(InputMap.has_action(&"cargo_toggle"), "and the action exists in the input map")


## ------------------------------------------- 8. the flight plane's wiring (item 8)
##
## The polls are called directly: the runner grants no frames, so a press stays
## "just pressed" for every direct call that follows it in the same frame.

func test_the_flight_seat_is_the_layer20_host_above_the_hud() -> void:
	var layer := _game.get(&"_cargo_overlay_layer") as CanvasLayer
	assert_eq(layer.layer, GameScript.OVERLAY_LAYER, "the seat is the dialog layer 20")
	var hud := _game.get(&"_hud") as Control
	var hud_layer := hud.get_node(NodePath("CanvasLayer")) as CanvasLayer
	assert_eq(hud_layer.layer, 10, "the HUD rides its own layer 10 (hud.tscn)")
	assert_gt(layer.layer, hud_layer.layer, "the overlay's seat is above the HUD's")
	assert_eq(layer.get_parent(), _game, "the game scene owns the seat, not the HUD")
	var overlay := _game.get(&"_cargo_overlay") as Control
	assert_eq(overlay.get_parent(), layer, "the overlay rides the game's host layer")


func test_the_poll_drives_the_overlay_and_the_mirror_stays_in_step() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	var hud := _game.get(&"_hud") as Control
	_poll_cargo()
	assert_true(bool(overlay.call(&"is_open")), "C opens the overlay over the live HUD")
	assert_true(bool(_game.get(&"_cargo_open")), "the game's mirror latched true")
	assert_true(bool(hud.get(&"_cargo_open")), "the HUD's own flag latched true")
	var panel := hud.get_node(NodePath("%CargoPanel")) as Control
	assert_false(panel.visible, "the retired HUD panel stays hidden")
	var block := hud.get_node(NodePath("CanvasLayer/TopLeft/Blocks/CargoPlate/CargoBlock")) as Control
	assert_true(block.visible, "the HUD's CargoBlock stays visible and untouched (V1's plate seat)")
	_poll_cargo()
	assert_false(bool(overlay.call(&"is_open")), "C again closes it (A8's close law)")
	assert_false(bool(_game.get(&"_cargo_open")), "and the mirror is false again")


func test_esc_closes_the_overlay_before_the_map_deck_step() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	var hud := _game.get(&"_hud") as Control
	_poll_cargo()
	assert_true(bool(overlay.call(&"is_open")), "the overlay is up over the HUD")
	Input.action_press(&"ui_cancel")
	_game.call(&"_update_cancel_input")
	Input.action_release(&"ui_cancel")
	assert_false(bool(overlay.call(&"is_open")), "ESC closes the overlay as the topmost step")
	assert_false(bool(hud.call(&"map_deck_open")), "and the map-deck step never ran")


func test_the_overlay_pauses_nothing_in_flight() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	_poll_cargo()
	assert_true(bool(overlay.call(&"is_open")), "the overlay is up")
	var tree := Engine.get_main_loop() as SceneTree
	assert_false(tree.paused, "nothing pauses under the overlay (A7's live HUD)")


func test_the_flight_overlay_reads_the_fixture_slots() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	_poll_cargo()
	var rows: Array = overlay.call(&"slot_rows")
	assert_eq(rows.size(), FIXTURE_SLOTS.size(), "the same overlay reads the same fixture slots in flight")
	for index in rows.size():
		assert_eq(
			String((rows[index] as Dictionary)[&"name"]), String(FIXTURE_SLOTS[index][2]),
			"flight slot %d's name" % index
		)
	assert_eq(
		overlay.call(&"title_text"), "CARGO — %d/%d UNITS" % [FIXTURE_HELD, _capacity()],
		"and the title carries the hold over the hull's cargo column"
	)


func test_the_flight_dispose_writes_the_shared_profile() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	_poll_cargo()
	var chip: Button = overlay.call(&"dispose_button", &"mineral_gold")
	assert_true(chip != null and not chip.disabled, "the flight overlay carries the same chips")
	chip.pressed.emit()
	assert_eq(
		int(_profile.call(&"cargo_qty", &"mineral_gold")), 0,
		"a dispose in flight writes the shared profile (the one law, both planes)"
	)
	assert_false(_slot_ids(overlay).has(&"mineral_gold"), "and the flight list recounts")
