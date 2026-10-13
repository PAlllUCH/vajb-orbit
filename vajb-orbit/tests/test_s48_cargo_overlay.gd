@tool
extends McpTestSuite
## Suite s48_cargo_overlay: wave S48 - UI_SPEC section 18 A7-A9's C-key cargo overlay
## (STATION_HUB section 23.2's station half). One row per pinned acceptance:
##   1. the surface is the N28 sheet idiom, one scene for both planes: full-rect STOP
##      root, void_base 60 % dimmer, centred panel_raised panel, margin 16, VBox 12,
##      420/720 width band, the 80 %-viewport scroll rule, the <= 0.2 s envelope;
##   2. the title reads CARGO - <n>/<cap> UNITS (the summed hold over the active hull's
##      cargo column, 08 section 3);
##   3. the five StationCaption groups carry A9's rows (ammo per fitted weapon, ore /
##      ingots / components / fuel cells per held stack), the tier / grade tints, the
##      24 px glyphs at their own rect, NONE HELD on an empty group;
##   4. no transactional control anywhere in the overlay;
##   5. the station shell handles C from any pane; C again, ESC (its P19 ladder step) or
##      the scrim closes it; focus returns to the trigger;
##   6. the flight plane: the layer-20 host above the HUD's own layer 10, the poll
##      driving the overlay and both mirrors, ESC as the one topmost step before the
##      map-deck step, nothing paused, the same fixture rows from the same overlay.
##
## The flight rows ride one game.tscn mounted once in suite_setup (the
## test_engine2_wiring.gd discipline): the launch `_ready` runs against the suite's
## staged fixture, and the hold carries no ammo item, so the launch's auto-load draw
## cannot move the hold the flight rows read.

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const OverlayScene := preload("res://ui/dialogs/cargo_overlay.tscn")
const OverlayScript := preload("res://ui/dialogs/cargo_overlay.gd")
const GameScene := preload("res://game/game.tscn")
const GameScript := preload("res://game/game.gd")
const Catalog := preload("res://game/station_catalog.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
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
}
const FIXTURE_HELD := 24

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
		panel.custom_minimum_size.x >= OverlayScript.MIN_WIDTH
			and panel.custom_minimum_size.x <= OverlayScript.MAX_WIDTH,
		"the width is size-to-content inside the 420/720 band"
	)
	var scroll := overlay.get_node(NodePath("%CargoScroll")) as ScrollContainer
	assert_true(scroll != null, "the body scrolls under the 80 %-viewport rule")
	assert_eq(
		float(OverlayScript.MAX_HEIGHT_RATIO), 0.8, "the height cap is N32's 80 %"
	)
	assert_true(
		float(OverlayScript.MOTION_SECONDS) <= 0.2, "the envelope obeys N29 (<= 0.2 s)"
	)
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


## ----------------------------------------------- 2/3. the title and the rows (items 2, 3)

func test_the_title_carries_the_hold_and_the_hull_capacity() -> void:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	var overlay := _overlay(screen)
	assert_eq(
		(overlay as Control).call(&"title_text"),
		"CARGO — %d/%d UNITS" % [FIXTURE_HELD, _capacity()],
		"the title sums the hold over the active hull's cargo column (08 section 3)"
	)


func test_the_five_groups_carry_the_pinned_rows() -> void:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	var overlay := _overlay(screen) as Control
	var rows: PackedStringArray = overlay.call(&"row_texts")
	var expected := PackedStringArray([
		"AMMUNITION",
		"LASER MKII · 120 ROUNDS",
		"CANNON MKI · 60 ROUNDS",
		"ORE",
		"IRON ORE · 7",
		"GOLD ORE · 3",
		"INGOTS",
		"TITANIUM INGOT · 4",
		"COMPONENTS",
		"TORN PLATING · 2",
		"LOGIC ARRAY · 1",
		"FUEL CELLS",
		"FUEL CELL · 5",
		"EMBER CELL · 2",
	])
	assert_eq(rows, expected, "the five groups in A9's order with A9's words")
	for text: String in rows:
		assert_false(text.contains(" CR"), "no priced row anywhere (item 4's seam law)")
	var groups := overlay.get_node(NodePath("%CargoContent/%CargoGroups")) as Node
	var iron := groups.get_node_or_null(NodePath("RowMineralIron/Glyph")) as TextureRect
	assert_eq(iron.custom_minimum_size, Vector2(24, 24), "the glyph sits at its own 24 rect")
	assert_eq(
		iron.modulate, MineralCatalogScript.TIER_TINTS[1], "the ore glyph takes the tier tint"
	)
	var gold := groups.get_node_or_null(NodePath("RowMineralGold/Glyph")) as TextureRect
	assert_eq(gold.modulate, MineralCatalogScript.TIER_TINTS[3], "tier 3's own tint")
	var scrap := groups.get_node_or_null(NodePath("RowCompScrap1/Glyph")) as TextureRect
	assert_eq(
		scrap.modulate, ComponentCatalogScript.GRADE_TINTS[1], "the component glyph takes the grade tint"
	)
	var elec := groups.get_node_or_null(NodePath("RowCompElec2/Glyph")) as TextureRect
	assert_eq(elec.modulate, ComponentCatalogScript.GRADE_TINTS[2], "grade II's own tint")
	var laser := groups.get_node_or_null(NodePath("RowLaser/Glyph")) as TextureRect
	assert_eq(laser.modulate, Color.WHITE, "the weapon glyph is the dedicated art, untinted")


func test_an_empty_group_reads_none_held() -> void:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	var overlay := _overlay(screen) as Control
	(overlay as Control).call(&"close")
	_stage_cargo({})
	(overlay as Control).call(&"open")
	var rows: PackedStringArray = overlay.call(&"row_texts")
	assert_eq(
		rows, PackedStringArray([
			"AMMUNITION",
			"LASER MKII · 120 ROUNDS",
			"CANNON MKI · 60 ROUNDS",
			"ORE", "NONE HELD",
			"INGOTS", "NONE HELD",
			"COMPONENTS", "NONE HELD",
			"FUEL CELLS", "NONE HELD",
		]),
		"an empty group shows the NONE HELD caption; the packs stay the battery's own read"
	)
	assert_eq(
		(overlay as Control).call(&"title_text"),
		"CARGO — 0/%d UNITS" % _capacity(),
		"and the title's <n> is the emptied hold"
	)


## ------------------------------------------------- 4. no transaction inside (item 4)

func test_no_transactional_control_inside() -> void:
	var screen := _mount()
	screen.call(&"_toggle_cargo")
	var overlay := _overlay(screen) as Control
	var buttons := 0
	var stack: Array[Node] = [overlay]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is BaseButton:
			buttons += 1
		for child: Node in node.get_children():
			stack.append(child)
	assert_eq(buttons, 0, "the overlay ships no button - the panes are the act")


## ------------------------------------------- 5. the shell's station wiring (item 5)

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


## ------------------------------------------- 6. the flight plane's wiring (item 6)
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
	var block := hud.get_node(NodePath("CanvasLayer/TopLeft/Blocks/CargoBlock")) as Control
	assert_true(block.visible, "the HUD's CargoBlock stays visible and untouched")
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


func test_the_flight_overlay_reads_the_fixture_rows() -> void:
	var overlay := _game.get(&"_cargo_overlay") as Control
	_poll_cargo()
	var rows: PackedStringArray = overlay.call(&"row_texts")
	var expected := PackedStringArray([
		"AMMUNITION",
		"LASER MKII · 120 ROUNDS",
		"CANNON MKI · 60 ROUNDS",
		"ORE",
		"IRON ORE · 7",
		"GOLD ORE · 3",
		"INGOTS",
		"TITANIUM INGOT · 4",
		"COMPONENTS",
		"TORN PLATING · 2",
		"LOGIC ARRAY · 1",
		"FUEL CELLS",
		"FUEL CELL · 5",
		"EMBER CELL · 2",
	])
	assert_eq(
		rows, expected,
		"the same overlay reads the same fixture rows in flight (hold and packs)"
	)
	assert_eq(
		(overlay as Control).call(&"title_text"),
		"CARGO — %d/%d UNITS" % [FIXTURE_HELD, _capacity()],
		"and the title carries the hold over the hull's cargo column"
	)
