@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s47_launch_sequence: wave S47 - P48's departure sequence (STATION_HUB
## section 23.3; AUDIO_SPEC section 8.7 AUDIO-4/5) and T-174's briefing box
## (STATION_HUB section 23.9). One row per pinned acceptance:
##   1. press 1's arm law stands (colour, ARMED strip copy, the 3 s disarm Timer,
##      the breaker cue) and ESC during the armed window still disarms;
##   2. press 2 opens the departure overlay in its seat - full-rect, Tokens-only
##      chrome, above the panes and below the drawer/sheet/dialog layers, fade
##      <= 0.2 s, no click-through, and the pane tree untouched by it;
##   3. the four beats: t+0.0 the undock cue + the UNDOCKING strip, t+1.0 the spool
##      bed through the held-bed API, t+2.4 the fired pair, t+3.0 the route;
##   4. the spool bed stops at the route, cue-scoped (no bed leak into loading);
##   5. the fired pair no longer plays at the route instant (the re-point);
##   6. T-174: the briefing column sits inside one flat Tokens box (`bay_bg` +
##      1 px `metal_mid`), containers only, the labels unchanged.
##
## The station is mounted the way `test_s30_shell.gd` mounts it (the shipped scene,
## the shipped theme, the profile borrowed and handed back). The runner runs one
## test body atomically with no frames inside it, so the beats are walked by
## calling their own beat handlers - the same methods the beat timers fire - and
## the schedule itself is pinned by reading the timers' wait times. Audio is read
## headless through the manager's own probe surface (`last_sfx`, `sounding_loops`,
## `bed_voice`) plus the sequence's one-shot cue record.

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const LaunchPanelScript := preload("res://ui/station/launch_panel.gd")
const AudioManagerScript := preload("res://autoload/audio_manager.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const SUITE_ID := "s47_launch_sequence"
const PROFILE_PATH := "user://test_s47_launch_sequence.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const AUDIO_SERVICE: StringName = &"AudioManager"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"
const LAUNCH_DECK := 5
const TOKENS_TYPE: StringName = &"Tokens"

var _profile: Node = null
var _station: Control = null
var _routes: Array[Array] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0


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
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_credits", 50000)


func suite_teardown() -> void:
	_free_screen()
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_free_screen()
	_routes.clear()


func _free_screen() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null
func _mount() -> Control:
	var host := Control.new()
	host.name = "S47Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


func _launch_pane(screen: Control) -> Node:
	var panels: Array = screen.call(&"panes")
	return panels[LAUNCH_DECK]


func _open_launch(screen: Control) -> Node:
	screen.call(&"_select_module", LAUNCH_DECK, true)
	return _launch_pane(screen)


## The two-press commit: press 1 arms, press 2 fires into the shell's sequence.
func _press_twice(screen: Control) -> Node:
	var pane := _open_launch(screen)
	pane.call(&"_on_launch_pressed")
	pane.call(&"_on_launch_pressed")
	return pane


func _on_route(route: StringName, params: Dictionary) -> void:
	_routes.append([route, params])


## The nearest ancestor that paints an opaque flat surface under `node` (the S40
## legibility suite's own walk). A caller passes the pane root as the stop.
func _roof(node: Control, stop: Node) -> Control:
	var walker := node.get_parent() as Node
	while walker != null and walker != stop:
		if walker is PanelContainer or walker is Panel or walker is Button \
				or walker is TextureRect or walker is ColorRect or walker is NinePatchRect:
			var control := walker as Control
			var area := control.get_global_rect().intersection(node.get_global_rect())
			if area.get_area() >= node.get_global_rect().get_area() * 0.9:
				for slot: StringName in [&"panel", &"normal", &"background"]:
					var box := control.get_theme_stylebox(slot)
					if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a >= 0.9:
						return control
		walker = walker.get_parent()
	return null


func _token(name: StringName) -> Color:
	return ThemeRes.get_color(name, TOKENS_TYPE)


## ------------------------------------------------- 1. the arm law stands (item 1)

func test_press_one_arms_and_esc_still_disarms() -> void:
	var screen := _mount()
	var pane := _open_launch(screen)
	pane.call(&"_on_launch_pressed")
	assert_true(bool(pane.call(&"is_armed")), "press 1 arms the control")
	var button := pane.get_node(NodePath("%LaunchButton")) as Button
	assert_eq(
		button.get_theme_color(&"font_color"), _token(&"accent_danger_bright"),
		"the armed ink is the pinned accent"
	)
	var strip := pane.get_node(NodePath("%ConfirmStrip")) as Label
	assert_eq(strip.text, LaunchPanelScript.ARM_TEXT % 3, "the ARMED strip copy stands")
	var footer := screen.get_node(NodePath("%StatusLabel")) as Label
	assert_eq(footer.text, LaunchPanelScript.STATUS_ARMED, "and the shell's strip says so")
	var timer := pane.get_node_or_null(NodePath("ArmTimer")) as Timer
	assert_true(timer != null and not timer.is_stopped(), "the 3 s disarm Timer runs")
	assert_eq(timer.wait_time, 3.0, "at the pinned window")
	screen.call(&"_handle_cancel")
	assert_false(bool(pane.call(&"is_armed")), "ESC during the armed window disarms (P19 step 2)")
	assert_eq(strip.text, LaunchPanelScript.IDLE_TEXT % 3, "the strip re-anchors to idle")
	assert_eq(footer.text, LaunchPanelScript.STATUS_DISARMED, "and the shell's strip says so")


## ------------------------------------------- 2/3. the departure overlay (items 2, 3)

func test_press_two_opens_the_departure_overlay_in_its_seat() -> void:
	var screen := _mount()
	screen.connect(&"route_requested", _on_route)
	var pane := _press_twice(screen)
	assert_false(bool(pane.call(&"is_armed")), "press 2 consumed the arm")
	var departure := screen.get(&"_departure") as Control
	assert_true(departure != null and departure.visible, "the overlay shows at the commit")
	assert_eq(departure.anchor_right, 1.0, "full-rect: the right anchor")
	assert_eq(departure.anchor_bottom, 1.0, "and the bottom anchor")
	assert_eq(departure.mouse_filter, Control.MOUSE_FILTER_STOP, "no click-through")
	var host := screen.get_node(NodePath("%ModuleHost")) as Control
	assert_false(host.is_ancestor_of(departure), "the overlay is outside the pane tree (A5.5)")
	assert_true(
		screen.is_ancestor_of(departure),
		"and a child of the screen itself - the LeaveConfirm seat"
	)
	var strip := screen.get(&"_departure_strip") as Label
	var name_label := screen.get_node(NodePath("%StationName")) as Label
	assert_eq(
		strip.text, StationScript.DEPARTURE_STRIP % name_label.text,
		"the strip reads the shell's own identity read, never a re-derivation"
	)
	assert_eq(
		strip.theme_type_variation, &"StationPanelTitle", "the strip is a theme variation (Tokens only)"
	)
	assert_true(
		float(StationScript.SEQUENCE_FADE) <= 0.2, "the overlay's fade obeys N29 (<= 0.2 s)"
	)
	assert_true(
		departure.modulate.a >= 0.0 and departure.modulate.a <= 1.0,
		"and the overlay enters through its own fade"
	)
	var dim := screen.get(&"_departure_dim") as ColorRect
	var expected := _token(&"void_base")
	expected.a = float(StationScript.MODAL_DIM_ALPHA)
	assert_true(
		dim.color.is_equal_approx(expected), "the dim is the shell's own modal void"
	)
	assert_eq(_routes.size(), 0, "the route waits for the sequence's tail")
	assert_eq(
		(screen.get(&"_departure_cues") as Array).size(), 1,
		"the commit instant plays the undock cue alone"
	)


## ------------------------------------- 3/4. the four beats and the bed stop (items 3, 4)

func test_the_beats_play_the_pinned_cues_and_end_at_the_route() -> void:
	var screen := _mount()
	screen.connect(&"route_requested", _on_route)
	var audio := Support.audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_press_twice(screen)
	var strip_text := (screen.get(&"_departure_strip") as Label).text
	var cues: Array = screen.get(&"_departure_cues")
	assert_eq(StringName(cues[0]), StationScript.SEQUENCE_UNDOCK, "t+0.0: the dock-clamp cue S27")
	assert_true(strip_text.begins_with("UNDOCKING · "), "and the strip reads UNDOCKING · <name>")
	screen.call(&"_on_departure_spool")
	assert_eq((screen.get(&"_departure_strip") as Label).text, strip_text,
		"the strip holds through the spool beat")
	var loops: Array = audio.call(&"sounding_loops")
	assert_true(
		loops.has(StationScript.SEQUENCE_SPOOL), "t+1.0: the spool bed books through the held-bed API"
	)
	var bed: Dictionary = audio.call(&"bed_voice", StationScript.SEQUENCE_SPOOL)
	assert_true(bool(bed.get(&"sounding")), "the bed's own voice is booked")
	assert_eq(
		String(audio.call(&"cue_path", StationScript.SEQUENCE_SPOOL)),
		"res://assets/audio/sfx/sfx_station_spool_loop.ogg",
		"on the pinned take (the voice's stream arrives with the API's fade callback)"
	)
	screen.call(&"_on_departure_pair")
	assert_eq((screen.get(&"_departure_strip") as Label).text, strip_text,
		"and through the pair beat")
	cues = screen.get(&"_departure_cues")
	assert_eq(cues.size(), 3, "t+2.4: the fired pair joins the record")
	assert_eq(StringName(cues[1]), StationScript.SFX_LAUNCH_BOOST, "boost first")
	assert_eq(StringName(cues[2]), StationScript.SFX_LAUNCH_JUMP, "then jump")
	assert_eq(
		StringName(audio.call(&"last_sfx")), StationScript.SFX_LAUNCH_JUMP,
		"the pair is the last thing the SFX bus was handed"
	)
	var before := StringName(audio.call(&"last_sfx"))
	screen.call(&"_on_departure_route")
	assert_eq(_routes.size(), 1, "t+3.0: the route fires once")
	assert_eq(StringName(_routes[0][0]), &"loading", "route `&\"loading\"` unchanged")
	assert_eq(_routes[0][1], {StationScript.PARAM_DESTINATION: StationScript.DESTINATION_GAME},
		"with the pre-existing destination payload")
	assert_eq(
		StringName(audio.call(&"last_sfx")), before,
		"the route instant itself fires nothing"
	)
	loops = audio.call(&"sounding_loops")
	assert_false(
		loops.has(StationScript.SEQUENCE_SPOOL), "the spool bed stopped at the route (item 4)"
	)
	bed = audio.call(&"bed_voice", StationScript.SEQUENCE_SPOOL)
	assert_false(bool(bed.get(&"sounding")), "the cue table holds no spool bed any more")
	assert_eq(
		StringName(audio.call(&"current_ambience")), &"",
		"the ambience stop rides the route instant as today"
	)


func test_the_beat_timers_are_the_screen_s_own() -> void:
	var screen := _mount()
	_press_twice(screen)
	var rows: Array = [
		[&"DepartureSpoolTimer", StationScript.SEQUENCE_SPOOL_AT, "_on_departure_spool"],
		[&"DeparturePairTimer", StationScript.SEQUENCE_PAIR_AT, "_on_departure_pair"],
		[&"DepartureRouteTimer", StationScript.SEQUENCE_ROUTE_AT, "_on_departure_route"],
	]
	for row: Array in rows:
		var timer := screen.get_node_or_null(NodePath(String(row[0]))) as Timer
		assert_true(timer != null, "%s ships" % String(row[0]))
		if timer == null:
			continue
		assert_true(screen.is_ancestor_of(timer), "the beat timer dies with the screen")
		assert_true(timer.one_shot, "each beat fires once")
		assert_eq(timer.wait_time, float(row[1]), "at its pinned instant")
		var wired := false
		for connection: Dictionary in timer.timeout.get_connections():
			if connection.get(&"callable") == Callable(screen, String(row[2])):
				wired = true
		assert_true(wired, "and is bound to its own beat handler")


## ------------------------------------------- 5. the re-point stands (item 5)

func test_the_fired_pair_no_longer_plays_at_the_route_instant() -> void:
	var screen := _mount()
	screen.connect(&"route_requested", _on_route)
	var audio := Support.audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	_press_twice(screen)
	var cues: Array = screen.get(&"_departure_cues")
	assert_eq(cues.size(), 1, "the commit instant plays no fired pair (the re-point)")
	assert_ne(
		StringName(audio.call(&"last_sfx")), StationScript.SFX_LAUNCH_BOOST,
		"neither boost"
	)
	assert_ne(
		StringName(audio.call(&"last_sfx")), StationScript.SFX_LAUNCH_JUMP, "nor jump"
	)
	screen.call(&"_on_launch_requested")
	assert_eq(
		(screen.get(&"_departure_cues") as Array).size(), 1,
		"a second intent while the sequence runs is not another commit"
	)
	assert_eq(_routes.size(), 0, "and no second route")


## ------------------------------------- 6. the sequence is not cancellable (item 2)

func test_the_sequence_is_not_cancellable() -> void:
	var screen := _mount()
	screen.connect(&"route_requested", _on_route)
	_press_twice(screen)
	var departure := screen.get(&"_departure") as Control
	screen.call(&"_handle_cancel")
	assert_true(departure.visible, "ESC does nothing while the sequence runs")
	assert_true(bool(screen.get(&"_departure_running")), "the sequence still runs")
	assert_eq(_routes.size(), 0, "and the route still waits for its own beat")
	assert_false(bool(screen.call(&"is_drawer_open")), "no drawer opened over the sequence")
	assert_false(
		(screen.get_node(NodePath("%LeaveConfirm")) as Control).visible,
		"and no leave confirm either"
	)
	screen.call(&"_on_departure_route")
	assert_false(bool(screen.get(&"_departure_running")), "the route beat ends the sequence")
	screen.call(&"_handle_cancel")
	assert_true(
		(screen.get_node(NodePath("%LeaveConfirm")) as Control).visible,
		"ESC's steps live again once the sequence is over"
	)


## ------------------------------------------------- 7. the briefing box (item 6)

func test_t174_the_briefing_column_sits_in_one_flat_tokens_box() -> void:
	var screen := _mount()
	var pane := _open_launch(screen)
	var labels := _briefing_labels(pane)
	assert_eq(
		labels.size(), LaunchPanelScript.BRIEF_ROWS.size() + 1,
		"the column's header and its labels all resolve (A24: the cargo window retired)"
	)
	var bay := _token(&"armory_bay_bg")
	var metal := _token(&"metal_mid")
	var roof: Control = null
	var index := 0
	for label: Label in labels:
		var found := _roof(label, pane)
		assert_true(
			found != null,
			"label %d has an opaque flat surface between it and the deck backdrop" % index
		)
		if found == null:
			continue
		if roof == null:
			roof = found
		assert_true(found == roof, "label %d shares the column's one box" % index)
		index += 1
	assert_true(roof != null, "the briefing column has a roof at all")
	if roof == null:
		return
	var box := roof.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_true(box != null, "the roof is a flat Tokens box")
	if box == null:
		return
	assert_true(box.bg_color.a >= 0.9, "the box is opaque")
	assert_true(
		box.bg_color.is_equal_approx(bay), "the fill is the pinned `bay_bg` token"
	)
	assert_eq(box.border_width_left, 1, "the border is 1 px")
	assert_true(
		box.border_color.is_equal_approx(metal), "and the pinned `metal_mid`"
	)
	assert_eq(roof.custom_minimum_size.x, 560.0, "the brief column keeps its pinned width")
	assert_true(
		roof.get_script() == null,
		"the roof is a plain PanelContainer - containers and styleboxes only (A5.2)"
	)


## The briefing column's labels in column order: the FLIGHT BRIEFING header and
## one caption per BRIEF_ROWS row (the row HBox's first child - the rows are
## built by `_build_brief_rows`, so they carry no unique names).
func _briefing_labels(pane: Node) -> Array[Label]:
	var labels: Array[Label] = []
	var brief_caption := pane.get_node_or_null(NodePath("%BriefCaption")) as Label
	if brief_caption != null:
		labels.append(brief_caption)
	var rows_box := pane.get(&"_brief_rows") as Node
	for row: Dictionary in LaunchPanelScript.BRIEF_ROWS:
		var row_name := "Brief%s" % String(row[&"key"]).to_pascal_case()
		var row_box := rows_box.get_node_or_null(NodePath(row_name)) as HBoxContainer
		if row_box != null and row_box.get_child_count() > 0:
			labels.append(row_box.get_child(0) as Label)
	return labels


func test_t174_the_brief_rows_keep_their_labels_and_values() -> void:
	var screen := _mount()
	var pane := _open_launch(screen)
	var brief_caption := pane.get_node_or_null(NodePath("%BriefCaption")) as Label
	assert_true(brief_caption != null, "the FLIGHT BRIEFING header ships")
	if brief_caption != null:
		assert_eq(brief_caption.text, "FLIGHT BRIEFING", "and its word is unchanged")
	var rows_box := pane.get(&"_brief_rows") as Node
	for row: Dictionary in LaunchPanelScript.BRIEF_ROWS:
		var row_name := "Brief%s" % String(row[&"key"]).to_pascal_case()
		var row_box := rows_box.get_node_or_null(NodePath(row_name)) as HBoxContainer
		assert_true(row_box != null, "%s row ships" % String(row[&"label"]))
		if row_box == null:
			continue
		var caption := row_box.get_child(0) as Label
		assert_eq(caption.text, String(row[&"label"]), "its label is unchanged")
		assert_eq(
			caption.theme_type_variation, &"StationCaption", "and its variation too"
		)
		var value := row_box.get_child(1) as Label
		assert_true(value != null and not value.text.is_empty(), "with its value line filled")
	assert_eq(
		(pane.get_node(NodePath("%BriefNote")) as Label).text,
		LaunchPanelScript.BRIEF_NOTE, "the manifest note is unchanged"
	)


## ----------------- 7. AUDIO-4's world class rides the gate (the F1 cure)

func test_the_undock_cue_rides_the_world_pool_cap() -> void:
	var audio := Support.audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	var caps: Dictionary = AudioManagerScript.POOL_CAPS
	assert_true(caps.has(&"world"), "section 4.1's cap list gains the world class")
	assert_eq(int(caps.get(&"world", 0)), 2, "at its pinned cap of 2")
	assert_eq(
		StringName(audio.call(&"_pool_class_of", StationScript.SEQUENCE_UNDOCK)), &"world",
		"the undock cue is a world-class one-shot"
	)
	assert_eq(
		StringName(audio.call(&"_pool_class_of", &"sfx_stinger_boss_roar_01")), &"world",
		"and so is the stinger family the pin names"
	)
	assert_eq(
		StringName(audio.call(&"_pool_class_of", StationScript.SFX_LAUNCH_BOOST)), &"",
		"while the fired pair stays outside every class (its callers unchanged)"
	)
	assert_true(
		audio.call(&"has_pool", StationScript.SEQUENCE_UNDOCK),
		"the undock owns a pool row - the gated route"
	)
	var takes: Array = audio.call(&"pool_takes", StationScript.SEQUENCE_UNDOCK)
	assert_eq(takes.size(), 1, "with its single take")
	if takes.size() == 1:
		assert_eq(StringName(takes[0]), &"sfx_station_undock_01", "the pinned take")
