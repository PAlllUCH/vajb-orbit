@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s29_map_deck: wave S29's map deck and navigation pin (UI_SPEC.md section 9
## N1-N6, section 10 N7-N23), the flight half. Composition and every number read off
## the law: N1's 80 % pane and its three toggle routes, N2's pan/zoom/arrow steps,
## N3's eight toggles with per-profile persistence, the N15-N23 class table (the
## fixer's toggle->blip-class law), the fixer's pin-precedence and pin-placement laws
## (N4/N14) and N10's `DIST <n>` reads on both maps.
##
## Input is driven through the real pipeline (`Input.parse_input_event` ->
## `flush_buffered_events`, S8-L170's lesson), with the deck's own layout pass
## delivered first (`_settle_layout`, the `test_s10_armory_input` idiom) because the
## gate runs no frames. The profile is the shipped autoload, borrowed on a scratch
## `save_path` (`test_d6_status.gd`'s idiom), so the owner's `user://profile.cfg` is
## never touched.

const DeckScript := preload("res://ui/hud/map_deck.gd")
const MinimapScript := preload("res://ui/hud/minimap.gd")
const HudScene := preload("res://ui/hud/hud.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s29_map_deck.cfg"
const PROFILE_SECTION := "profile"
const PROFILE_KEY_MAP_FILTERS := "map_filters"

const HOST_SIZE := Vector2(1600.0, 900.0)
const M_KEY := KEY_M

var _profile: Node = null
var _previous_path := ""
var _host: Control = null
var _deck: Control = null
var _hud: Control = null
var _orders: Array[Vector2] = []
var _cancels := 0
var _jumps: Array[Vector2] = []
var _pin_changes: Array = []


func suite_name() -> String:
	return "s29_map_deck"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the deck")
		return
	var profile := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_orders.clear()
	_jumps.clear()
	_pin_changes.clear()
	_cancels = 0
	## Every test starts N3's all-on default: the shared scratch profile carries no
	## filters in.
	(_profile.get(&"_config") as ConfigFile).set_value(PROFILE_SECTION, PROFILE_KEY_MAP_FILTERS, {})
	_host = Control.new()
	_host.name = "MapDeckHost"
	_host.theme = ThemeRes
	_host.size = HOST_SIZE
	_profile.add_child(_host)


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	if _host != null and is_instance_valid(_host):
		_host.free()
	_hud = null
	_deck = null
	_host = null


## ---------------------------------------------------------------------------
## A1 - the deck pane (N1) and its chrome (A5.4 rows)
## ---------------------------------------------------------------------------


func test_the_deck_pane_is_an_80_percent_centred_panel_on_the_pane_edge_chrome() -> void:
	_mount_deck()
	assert_true(_deck.visible == false, "the deck ships closed (N1's toggle routes open it)")
	_open_deck()
	assert_true(_deck.visible, "set_open opens it")
	var expected := HOST_SIZE * 0.8
	assert_true(
		absf(_deck.size.x - expected.x) <= 1.0 and absf(_deck.size.y - expected.y) <= 1.0,
		"the pane is 80 %% of the viewport (measured %s)" % str(_deck.size)
	)
	assert_true(
		absf(_deck.anchor_left - 0.1) <= 0.001 and absf(_deck.anchor_right - 0.9) <= 0.001,
		"centred by anchors 0.1..0.9, never coordinates"
	)
	assert_eq(String(_deck.theme_type_variation), "PanelRaised", "A5.4's Pane outer edge chrome")
	var filter_column := _deck.find_child("FilterColumn", true, false) as Control
	assert_true(filter_column != null, "the filter column ships")
	if filter_column != null:
		assert_eq(
			filter_column.custom_minimum_size.x, 240.0,
			"the column is section 10's (240, 0) (PROPOSED)"
		)


func test_the_filter_column_carries_n3s_eight_toggles_with_label_and_state_reads() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var column := _deck.find_child("FilterColumn", true, false)
	var caption := _deck.find_child("FiltersHeader", true, false) as Label
	assert_true(caption != null, "the column carries its N7 caption")
	if caption != null:
		assert_eq(caption.text, "MAP FILTERS", "N7's own spelling")
	var rows := MinimapScript.toggle_rows()
	assert_eq(rows.size(), 8, "N3's eight toggles")
	var buttons := _buttons(column)
	assert_eq(buttons.size(), 8, "one row per toggle")
	for index: int in rows.size():
		var row: Dictionary = rows[index]
		var button: Button = buttons[index]
		assert_eq(
			String(button.name), "Filter_%s" % String(row[&"id"]),
			"row %d is the table's own id" % index
		)
		assert_true(
			button.custom_minimum_size.y >= 56.0,
			"the %s row clears A5.4-2's min (0, 56)" % String(row[&"label"])
		)
		var name_label := button.find_child("Name", true, false) as Label
		assert_eq(String(name_label.text), String(row[&"label"]), "the N3 label verbatim")
		var state_label := button.find_child("State", true, false) as Label
		assert_eq(String(state_label.text), "ON", "N3's all-on default reads ON")
		assert_true(button.button_pressed, "and the toggle is on")


func test_the_foot_carries_the_zoom_read_the_hint_and_the_three_36px_buttons() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	assert_eq(String(_deck.call(&"zoom_read_text")), "ZOOM 100%", "N8's zoom read")
	var hint := _deck.find_child("HintCaption", true, false) as Label
	assert_true(hint != null, "the hint line ships")
	if hint != null:
		assert_eq(
			hint.text, "DRAG PAN \u00b7 WHEEL ZOOM \u00b7 CLICK PIN \u00b7 HOLD JUMP", "N9 verbatim"
		)
	for button_name: String in ["ZoomMinus", "ZoomPlus", "ExpandToggle"]:
		var button := _deck.find_child(button_name, true, false) as Control
		assert_true(button != null, "%s ships in the deck foot" % button_name)
		if button != null:
			assert_true(
				button.custom_minimum_size.x >= 36.0 and button.custom_minimum_size.y >= 36.0,
				"%s rides the compact footer's 36x36 idiom" % button_name
			)


## ---------------------------------------------------------------------------
## A1 - the filter toggles: persistence (N3) and the class table (N15-N23)
## ---------------------------------------------------------------------------


func test_a_toggle_persists_per_profile_through_the_profile_save() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	assert_true(bool(_deck.call(&"filter_state", MinimapScript.TOGGLE_STATIONS)), "starts on")
	_deck.call(&"set_filter", MinimapScript.TOGGLE_STATIONS, false)
	var state_label := _state_label(MinimapScript.TOGGLE_STATIONS)
	assert_eq(String(state_label.text), "OFF", "label + state, never colour alone")
	assert_true(
		state_label.has_theme_color_override(&"font_color"),
		"and the OFF state carries the text_dim seat as its second cue"
	)
	var stored: Dictionary = (_profile.get(&"_config") as ConfigFile).get_value(
		PROFILE_SECTION, PROFILE_KEY_MAP_FILTERS, {}
	)
	assert_eq(bool(stored.get(String(MinimapScript.TOGGLE_STATIONS), true)), false, "in the save")
	_profile.call(&"save")
	var reread := ConfigFile.new()
	assert_eq(reread.load(PROFILE_PATH), OK, "the profile save is readable")
	assert_eq(
		bool(
			(reread.get_value(PROFILE_SECTION, PROFILE_KEY_MAP_FILTERS, {}) as Dictionary).get(
				String(MinimapScript.TOGGLE_STATIONS), true
			)
		),
		false,
		"and the file carries it (user://profile.cfg, 01 section 7)"
	)
	var second := DeckScript.new()
	_host.add_child(second)
	assert_eq(
		bool(second.call(&"filter_state", MinimapScript.TOGGLE_STATIONS)), false,
		"a fresh deck loads the persisted toggle"
	)
	second.free()
	_deck.call(&"set_filter", MinimapScript.TOGGLE_STATIONS, true)
	assert_true(bool(_deck.call(&"filter_state", MinimapScript.TOGGLE_STATIONS)), "and back on")


func test_the_toggle_to_class_table_rides_the_fixers_laws() -> void:
	var rows := MinimapScript.toggle_rows()
	assert_eq(String(rows[0][&"label"]), "STATIONS", "N3's own order starts at STATIONS")
	assert_eq(String(rows[7][&"label"]), "CONTRACTS", "and ends at CONTRACTS")
	assert_eq(String(rows[6][&"label"]), "CARGO & WRECKS", "the CARGO & WRECKS spelling")
	var pois: Array = rows[3][&"kinds"]
	assert_true(pois.has(MinimapScript.KIND_POI), "POIS rides KIND_POI (N18)")
	assert_true(pois.has(MinimapScript.KIND_GHOST), "and the shipped ghost (N19)")
	var hostiles: Array = rows[4][&"kinds"]
	assert_true(hostiles.has(MinimapScript.KIND_HOSTILE), "HOSTILES rides KIND_HOSTILE")
	assert_true(hostiles.has(MinimapScript.KIND_SWARMER), "and the shipped swarmer (N20)")
	assert_true(bool(rows[0].get(&"n6", false)), "STATIONS is N6-exempt (N15)")
	assert_true(bool(rows[1].get(&"n6", false)), "and so is GATES (N16)")


func test_n6_exempts_station_and_gate_while_n23_keeps_unshipped_classes_inert() -> void:
	var map := MinimapScript.new()
	_host.add_child(map)
	map.call(&"set_filters", _all_off())
	assert_true(map.call(&"kind_visible", MinimapScript.KIND_SELF), "KIND_SELF is never filterable")
	assert_true(
		map.call(&"kind_visible", MinimapScript.KIND_STATION),
		"N6: station blips draw whatever the filters say"
	)
	assert_true(map.call(&"kind_visible", MinimapScript.KIND_GATE), "and so do gate blips")
	assert_false(
		map.call(&"kind_visible", MinimapScript.KIND_GHOST),
		"POIS-off hides the shipped ghost (N19)"
	)
	assert_false(map.call(&"kind_visible", MinimapScript.KIND_HOSTILE), "HOSTILES-off hides hostiles")
	assert_false(map.call(&"kind_visible", MinimapScript.KIND_SWARMER), "and swarmers (N20)")
	assert_false(map.call(&"kind_visible", MinimapScript.KIND_FRIENDLY), "FRIENDLY-off hides friendly")
	for kind: StringName in [
		MinimapScript.KIND_ASTEROID_FIELD, MinimapScript.KIND_POI,
		MinimapScript.KIND_WRECK, MinimapScript.KIND_CONTRACT,
	]:
		assert_true(
			map.call(&"kind_visible", kind),
			"N23: %s has not shipped, so its toggle filters nothing" % String(kind)
		)
		assert_false(
			MinimapScript.shipped_kinds().has(kind),
			"%s is not in the shipped set" % String(kind)
		)
	assert_true(map.call(&"kind_visible", &"neutral"), "the unmapped feed kinds filter nothing")
	map.free()


func test_station_and_gate_draw_the_friendly_diamond_and_the_new_classes_draw_dots() -> void:
	for kind: StringName in [
		MinimapScript.KIND_FRIENDLY, MinimapScript.KIND_STATION, MinimapScript.KIND_GATE,
	]:
		assert_eq(
			MinimapScript.blip_mark(kind), MinimapScript.MARK_DIAMOND,
			"%s wears the diamond the sector's station and gates wear today" % String(kind)
		)
	for kind: StringName in [
		MinimapScript.KIND_SELF, MinimapScript.KIND_HOSTILE, MinimapScript.KIND_SWARMER,
		MinimapScript.KIND_GHOST, MinimapScript.KIND_ASTEROID_FIELD, MinimapScript.KIND_POI,
		MinimapScript.KIND_WRECK, MinimapScript.KIND_CONTRACT, &"neutral",
	]:
		assert_eq(
			MinimapScript.blip_mark(kind), MinimapScript.MARK_DOT,
			"%s draws the map's own dot" % String(kind)
		)
	assert_eq(MinimapScript.draw_kinds().size(), 5, "the compact legend still names the shipped five")


## ---------------------------------------------------------------------------
## A1 - pan and zoom (N2, N14)
## ---------------------------------------------------------------------------


func test_wheel_zoom_clamps_at_25_and_400_percent_and_keeps_the_cursor_world_point() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var local := (_map_size(map) * 0.5) + Vector2(40.0, -30.0)
	var at: Vector2 = map.global_position + local
	var before: Vector2 = map.call(&"world_at", local)
	for _step: int in 12:
		_mouse_button(at, true, MOUSE_BUTTON_WHEEL_UP)
	assert_true(
		is_equal_approx(float(map.call(&"view_zoom")), MinimapScript.ZOOM_MAX),
		"the zoom stops at N2's 400 %"
	)
	var after: Vector2 = map.call(&"world_at", local)
	assert_true(
		before.distance_to(after) <= 0.001 * maxf(before.length(), 1.0) + 0.5,
		"the zoom is centred on the cursor (its world point stays put)"
	)
	for _step: int in 20:
		_mouse_button(at, true, MOUSE_BUTTON_WHEEL_DOWN)
	assert_true(
		is_equal_approx(float(map.call(&"view_zoom")), MinimapScript.ZOOM_MIN),
		"and the floor is N2's 25 %"
	)
	assert_eq(String(_deck.call(&"zoom_read_text")), "ZOOM 25%", "N8 reads the clamp")


func test_arrow_keys_pan_in_64_pixel_steps() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var before: Vector2 = map.call(&"map_origin")
	_key(KEY_RIGHT)
	var point: Vector2 = map.call(&"local_of", before)
	assert_true(
		point.distance_to(_map_size(map) * 0.5 - Vector2(64.0, 0.0)) <= 0.01,
		"one RIGHT step moves the view 64 px (N2)"
	)
	_key(KEY_UP)
	point = map.call(&"local_of", before)
	assert_true(
		point.distance_to(_map_size(map) * 0.5 - Vector2(64.0, -64.0)) <= 0.01,
		"and UP adds a 64 px step"
	)


func test_a_press_placed_past_the_8px_threshold_is_a_pan_that_keeps_the_pin() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var at := _map_centre()
	_press(at)
	var placed: Variant = map.call(&"pin")
	assert_true(placed != null, "the pin is placed at press-down (N14's fixer law)")
	if placed == null:
		return
	var origin: Vector2 = map.call(&"map_origin")
	_motion(at + Vector2(20.0, 0.0), at, true)
	assert_true(
		(map.call(&"pin") as Vector2).is_equal_approx(placed as Vector2),
		"and it does not follow the cursor"
	)
	assert_false(
		(origin as Vector2).is_equal_approx(map.call(&"map_origin")),
		"the held move past 8 px pans (N2/N14)"
	)
	_release(at + Vector2(20.0, 0.0))
	assert_eq(_orders.size(), 0, "a pan's release issues no order")
	assert_eq(_jumps.size(), 0, "and no hold-jump arms from a drag")


## ---------------------------------------------------------------------------
## A2 - the navigation pin (the fixer's precedence law, N4)
## ---------------------------------------------------------------------------


func test_a_short_press_places_the_pin_at_press_down_and_orders_the_existing_autopilot() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var at := _map_centre() + Vector2(30.0, 10.0)
	_press(at)
	var placed: Variant = map.call(&"pin")
	assert_true(placed != null, "placed at press-down")
	if placed == null:
		return
	assert_true(
		(placed as Vector2).distance_to(map.call(&"world_at", at - map.global_position)) <= 0.01,
		"at the press point (the gui event's position is map-local)"
	)
	assert_eq(_orders.size(), 0, "nothing orders before the release")
	_release(at)
	assert_eq(_orders.size(), 1, "the short press issues the existing autopilot order")
	assert_true(
		_orders[0].distance_to(placed as Vector2) <= 0.01, "to the pin"
	)
	assert_true(_pin_changes.size() >= 1, "and the pin change travelled up")


func test_a_press_that_hit_tests_the_pin_is_a_remove_candidate_and_never_a_place_or_move() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var at := _map_centre()
	_press(at)
	_release(at)
	var placed: Variant = map.call(&"pin")
	assert_true(placed != null, "the pin is placed")
	if placed == null:
		return
	_orders.clear()
	_cancels = 0
	var near := at + Vector2(4.0, 0.0)
	_press(near)
	assert_true(
		(map.call(&"pin") as Vector2).is_equal_approx(placed as Vector2),
		"a press on the pin is never a place or move"
	)
	_release(near)
	assert_true(map.call(&"pin") == null, "a short press on the pin removes it")
	assert_eq(_orders.size(), 0, "and never orders")
	assert_eq(_cancels, 1, "and cancels the standing order (cancel_orders, section 10)")


func test_hold_lmb_half_a_second_requests_the_jump_on_a_fresh_and_the_existing_pin() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	var at := _map_centre() + Vector2(-20.0, 15.0)
	_press(at)
	var fresh: Variant = map.call(&"pin")
	if fresh == null:
		assert_true(false, "the fresh pin is placed")
		return
	_deck.call(&"_process", 0.6)
	assert_eq(_jumps.size(), 1, "the hold fires at N4's 0.5 s on a fresh pin")
	assert_true((_jumps[0] as Vector2).is_equal_approx(fresh as Vector2), "to the pin")
	_release(at)
	assert_true(map.call(&"pin") != null, "the hold removes nothing")
	assert_eq(_orders.size(), 0, "and the release after a hold issues no order")
	_jumps.clear()
	_press(_map_centre() + Vector2(-20.0, 15.0))
	assert_true(map.call(&"pin") != null, "the second press hit-tests the existing pin")
	_deck.call(&"_process", 0.6)
	assert_eq(_jumps.size(), 1, "and the hold jumps on the existing pin alike")
	assert_true(map.call(&"pin") != null, "without removing it")
	_release(_map_centre() + Vector2(-20.0, 15.0))


func test_the_pin_distance_and_the_no_hyperdrive_caption_read_under_the_pin() -> void:
	_mount_deck()
	_settle_layout()
	_open_deck()
	var map := _deck.call(&"map_view") as Control
	_press(_map_centre())
	_release(_map_centre())
	_deck.call(&"map_view").call(&"set_pin_reads", "DIST 4 512", "NO HYPERDRIVE INSTALLED")
	var dist := map.find_child("PinDistanceCaption", true, false) as Label
	var caption := map.find_child("PinCaption", true, false) as Label
	assert_true(dist != null and caption != null, "both under-pin reads ship")
	assert_eq(String(dist.text), "DIST 4 512", "N10's DIST read rides the deck under the pin")
	assert_eq(
		String(caption.text), "NO HYPERDRIVE INSTALLED", "N4's caption wording under the pin"
	)
	assert_true(dist.visible and caption.visible, "and both show while the pin is placed")


## ---------------------------------------------------------------------------
## A1 - the three toggle routes (N1) and the shared feed (N3/N6/N10)
## ---------------------------------------------------------------------------


func test_the_deck_toggles_on_the_corner_button_the_m_key_and_the_hud_seam() -> void:
	_mount_hud()
	var deck := _hud.call(&"map_deck") as Control
	assert_true(deck != null, "the HUD builds the deck")
	assert_false(bool(_hud.call(&"map_deck_open")), "ships closed")
	var button := _hud.find_child("ExpandMap", true, false) as Control
	assert_true(button != null, "the compact footer carries its corner EXPAND button")
	_click(_centre_of(button))
	assert_true(bool(_hud.call(&"map_deck_open")), "the corner button opens the deck")
	_key(M_KEY)
	assert_false(bool(_hud.call(&"map_deck_open")), "M toggles it closed again (N1)")
	_key(M_KEY)
	assert_true(bool(_hud.call(&"map_deck_open")), "and open again")
	## The deck's own foot EXPAND, the same 36x36 idiom inside the pane.
	var foot_button := deck.find_child("ExpandToggle", true, false) as Control
	_click(_centre_of(foot_button))
	assert_false(bool(_hud.call(&"map_deck_open")), "the deck foot's EXPAND closes it")
	_hud.call(&"toggle_map_deck")
	assert_true(bool(_hud.call(&"map_deck_open")), "the hud seam (ESC's route in game.gd) toggles it back")


func test_the_compact_map_shares_the_pin_the_bearing_arrow_and_the_distance_read() -> void:
	_mount_hud()
	_settle_layout()
	var deck := _hud.call(&"map_deck") as Control
	deck.call(&"set_open", true)
	_settle_layout()
	var deck_map := deck.call(&"map_view") as Control
	var compact := _hud.find_child("MinimapView", true, false) as Control
	assert_true(compact != null, "the compact minimap ships")
	var feed: Array[Dictionary] = [{&"pos": Vector2.ZERO, &"kind": &"self"}]
	_hud.call(&"set_minimap_blips", feed)
	## Pan the deck view off the player first (N2's own seam): the next press places the
	## pin far from the self blip, which is N4's out-of-view case on the compact map.
	deck_map.call(&"pan_by_pixels", Vector2(3000.0, 0.0))
	_press(_map_centre_of(deck_map))
	_release(_map_centre_of(deck_map))
	assert_true(compact.call(&"pin") != null, "the compact map mirrors the pin")
	var arrow := compact.find_child("PinEdgeArrow", true, false) as Control
	assert_true(arrow != null, "the bearing arrow mark ships")
	assert_true(arrow.visible, "out of view the pin clamps to the edge as a bearing arrow")
	var sector := _hud.find_child("SectorLabel", true, false) as Label
	assert_true(
		String(sector.text).contains("DIST "),
		"N10's DIST read rides the footer's SectorLabel line"
	)
	## Back over the player the pin is in view on the compact map: its diamond mark.
	deck_map.call(&"pan_by_pixels", Vector2(-3000.0, 0.0))
	_press(_map_centre_of(deck_map))
	_release(_map_centre_of(deck_map))
	var stack := compact.find_child("PinStack", true, false) as Control
	assert_true(stack.visible, "in view the pin is its diamond mark in its own child rect")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _mount_deck() -> void:
	_deck = DeckScript.new()
	_deck.name = "MapDeckUnderTest"
	_host.add_child(_deck)
	_deck.connect(&"autopilot_to", _on_autopilot_to)
	_deck.connect(&"autopilot_cancel", _on_autopilot_cancel)
	_deck.connect(&"jump_requested", _on_jump_requested)
	_deck.connect(&"pin_changed", _on_pin_changed)
	_settle_layout()


func _mount_hud() -> void:
	_hud = HudScene.instantiate() as Control
	_hud.theme = ThemeRes
	## The d8 idiom: the HUD anchors to the viewport when its host is not a Control,
	## which is the geometry the game shows (a sized Control host skews the corner).
	## The gate runs no frames, so the anchored root keeps the size it was saved with
	## until a resize notification lands: set the viewport's own size to deliver one.
	_profile.add_child(_hud)
	_hud.size = _hud.get_viewport().get_visible_rect().size
	_place_minimap_corner()
	_settle_layout()
	var deck := _hud.call(&"map_deck") as Control
	if deck != null:
		deck.connect(&"autopilot_to", _on_autopilot_to)
		deck.connect(&"autopilot_cancel", _on_autopilot_cancel)
		deck.connect(&"jump_requested", _on_jump_requested)
		deck.connect(&"pin_changed", _on_pin_changed)


## Open + settle: a hidden container's layout is deferred and the gate runs no
## frames, so the deck must be visible before its containers sort.
func _open_deck() -> void:
	_deck.call(&"set_open", true)
	_settle_layout()


## The gate runs no frames and its headless window carries decoration height, so the
## anchored corner freezes below the viewport clip (measured: the footer lands at y
## 1140 of a 1080 viewport, where gui hit-testing never reaches it). The game's own
## layout is the anchors in `hud.tscn`; the fixture places the bottom-right anchor's
## result (its own content-minimum size at the HUD root's corner) the way the frame
## after the build would, then the container sorts take the rest.
func _place_minimap_corner() -> void:
	var corner := _hud.get_node_or_null(NodePath("CanvasLayer/BottomRight")) as Control
	if corner == null:
		return
	corner.size = corner.get_combined_minimum_size()
	corner.position = _hud.size - corner.size


func _on_autopilot_to(pos: Vector2) -> void:
	_orders.append(pos)


func _on_autopilot_cancel() -> void:
	_cancels += 1


func _on_jump_requested(pos: Vector2) -> void:
	_jumps.append(pos)


func _on_pin_changed(pin: Variant) -> void:
	_pin_changes.append(pin)


func _all_off() -> Dictionary:
	var out := {}
	for row: Dictionary in MinimapScript.toggle_rows():
		out[row[&"id"]] = false
	return out


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for child: Node in node.get_children():
		var button := child as Button
		if button != null:
			out.append(button)
	return out


func _state_label(toggle_id: StringName) -> Label:
	var column := _deck.find_child("FilterColumn", true, false)
	var button := column.get_node_or_null(NodePath("Filter_%s" % String(toggle_id))) as Button
	return button.find_child("State", true, false) as Label


## The deck's own layout pass, as the frame after the build makes it (the
## `test_s10_armory_input` idiom): containers sort their children once, parents
## first (a child's rect is only real after its container sorted).
func _settle_layout() -> void:
	var roots: Array[Node] = []
	if _host != null:
		roots.append(_host)
	if _hud != null:
		roots.append(_hud)
	for _pass: int in 2:
		for root: Node in roots:
			for node: Node in _descendants_breadth_first(root):
				var container := node as Container
				if container != null:
					container.notification(Container.NOTIFICATION_SORT_CHILDREN)


func _descendants_breadth_first(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var queue: Array[Node] = [root]
	var index := 0
	while index < queue.size():
		var node: Node = queue[index]
		index += 1
		for child: Node in node.get_children():
			out.append(child)
			queue.append(child)
	return out


func _map_centre() -> Vector2:
	return _map_centre_of(_deck.call(&"map_view") as Control)


func _map_centre_of(map: Control) -> Vector2:
	return map.global_position + map.size * 0.5


func _map_size(map: Control) -> Vector2:
	return map.size


func _centre_of(control: Control) -> Vector2:
	return control.global_position + control.size * 0.5


## ------------------------------------------------------------- the input harness


func _mouse_button(pos: Vector2, pressed: bool, index: int = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = pos
	event.global_position = pos
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _motion(pos: Vector2, previous: Vector2, pressed: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.relative = pos - previous
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _press(pos: Vector2) -> void:
	_motion(pos, pos, false)
	_mouse_button(pos, true)


func _release(pos: Vector2) -> void:
	_motion(pos, pos, true)
	_mouse_button(pos, false)


func _click(pos: Vector2) -> void:
	_press(pos)
	_release(pos)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
