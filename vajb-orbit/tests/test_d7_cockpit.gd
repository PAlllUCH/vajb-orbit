@tool
extends McpTestSuite
## Suite d7_cockpit: wave D7's cockpit cluster rework (UI_SPEC section 3.7 as amended
## 2026-09-24 - the Mockup v5/v7 blocks - and section 3.9 rule 5's `CockpitStyle`).
##
## The D6 cluster's *behaviour* yardstick stays in `test_d6_cluster.gd` (re-aimed, not
## retired); this suite measures the D7 surface the brief pins:
##
##  1. the box, the interior and the three bays are section 3.7's numbers, and the
##     code-drawn wells mount at the pinned rects (UI_CHROME section 12 Amendment 2: the
##     plate is FLAT and the wells are code);
##  2. the digit fit law - every `ui_seg_*` sprite is fill-fitted to its style-sized
##     20 x 36 cell on a 22 px pitch, and no two glyph rects in a row touch;
##  3. the readout stack runs the full interior height with the bottom row in the foot band;
##  4. the battery lamps are the five 22 px squares, exactly one lit for the selected rack
##     (the same rack ordinal the weapon grid selects), and the AMMO row reads the existing
##     ammo feed with the pinned clamps and blank padding;
##  5. the old HUD column is absent from the flight HUD, the section 7 frozen API survives
##     callable, and the section 3.6 dial draws no heading tick;
##  6. `CockpitStyle` really is the single style surface: a user `.tres` restyles **and**
##     relayouts the cluster with no code edit.
##
## Everything here is a reading the HUD or the cluster hands back; the shipped `hud.tscn` is
## instantiated into the runner's own scene tree the same way the D6 suites do.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")

const SPD: StringName = &"spd"
const HULL: StringName = &"hull"
const SHLD: StringName = &"shld"
const AMMO: StringName = &"ammo"
const ROWS: Array[StringName] = [SPD, HULL, SHLD, AMMO]
const DIAL_FUEL: StringName = &"fuel"
const DIAL_ENRG: StringName = &"enrg"
const POOL_FUEL: StringName = &"fuel"
const POOL_ENERGY: StringName = &"energy"

## The pinned numbers (UI_SPEC section 3.7's Mockup v5/v7 blocks). The suite reads them from
## the style *and* asserts them against these literals, so a default that drifts fails here.
const BOX := Vector2(464.0, 256.0)
const INTERIOR := Vector2(400.0, 192.0)
const BAND := 32.0
const BAYS: Array[float] = [126.0, 104.0, 156.0]
const GUTTER := 7.0
const CELL := Vector2(20.0, 36.0)
const CELL_PITCH := 22.0
const ROW_HEIGHT := 36.0
const ROW_PITCH := 50.7
const LABEL_ZONE := 36.0
const ROW_COUNT := 4
const DIAL_RADIUS := 36.0
const DIAL_RIM := 4.0
const DIAL_CLEARANCE := 23.0
const LAMP_SIZE := 22.0
const LAMP_GAP := 3.0
const LAMP_WIDTH := 122.0

const BLANK := -1
const STYLE_PROBE_PATH := "user://d7_cockpit_style_probe.tres"

var _hud: Control = null
var _cargo_events: Array[bool] = []


func suite_name() -> String:
	return "d7_cockpit"


func setup() -> void:
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		fail_setup("hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_fixture_host().add_child(_hud)


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null
	_cargo_events.clear()
	if FileAccess.file_exists(STYLE_PROBE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _cockpit() -> Control:
	return _hud.call(&"cockpit")


func _style() -> Resource:
	return _cockpit().call(&"style")


func _row(key: StringName) -> Node:
	return _cockpit().call(&"row", key)


func _dial(key: StringName) -> Node:
	return _cockpit().call(&"value_dial", key)


func _cells(key: StringName) -> Array:
	return _row(key).call(&"cells")


func _token(name: StringName) -> Color:
	return HudTheme.get_color(name, &"Tokens")


func _overlaps(rects: Array[Rect2]) -> int:
	var count := 0
	for a: int in rects.size():
		for b: int in rects.size():
			if b <= a:
				continue
			if rects[a].intersects(rects[b], false):
				count += 1
	return count


## ---------------------------------------------------------------------------
## 1. The box, the bays and the code-drawn wells at the pinned rects
## ---------------------------------------------------------------------------


func test_the_box_interior_and_bays_are_section_3_7s_numbers() -> void:
	var style: Resource = _style()
	assert_true(style != null, "the cluster reads a CockpitStyle")
	assert_eq(_cockpit().custom_minimum_size, BOX, "the 464 x 256 box")
	assert_eq(style.box_size, BOX, "and the style pins the same box")
	assert_eq(style.interior().size, INTERIOR, "the 400 x 192 painted interior")
	assert_eq(style.band, BAND, "on a 32 px band")
	var left: Rect2 = style.left_bay()
	var middle: Rect2 = style.middle_bay()
	var right: Rect2 = style.right_bay()
	assert_eq([left.size.x, middle.size.x, right.size.x], BAYS, "bays 126 / 104 / 156")
	assert_true(
		is_equal_approx(middle.position.x - left.end.x, GUTTER), "the first 7 px gutter"
	)
	assert_true(is_equal_approx(right.position.x - middle.end.x, GUTTER), "the second 7 px gutter")
	assert_true(
		is_equal_approx(
			left.size.x + middle.size.x + right.size.x + 2.0 * GUTTER, INTERIOR.x
		),
		"the bays and gutters fill the interior exactly"
	)
	assert_true(is_equal_approx(right.end.x, style.interior().end.x), "the right bay is flush")


func test_the_wells_mount_at_the_pinned_rects() -> void:
	var style: Resource = _style()
	var wells: Array[Rect2] = _cockpit().call(&"wells")
	assert_eq(wells, style.wells(ROW_COUNT), "the painter and the style derive one list")
	assert_eq(wells.size(), 5, "gauge disc, foot band, two dial discs, readout well")
	## UI_CHROME section 12 Amendment 2's architecture: the plate is FLAT and the wells are
	## code-drawn. The panel is a plain TextureRect (never a nine-slice) and the wells live on
	## a `Wells` Control whose own `well_rects()` is the list asserted above.
	var panel: Node = _cockpit().get_node("CockpitPanel")
	assert_true(panel != null and not (panel is NinePatchRect), "the plate is flat, no nine-slice")
	assert_true(panel is TextureRect, "and the plate is a plain TextureRect")
	assert_eq(
		(panel as TextureRect).texture.resource_path, style.panel_path, "the style's own master"
	)
	var painter: Control = _cockpit().get_node("Wells")
	assert_true(painter != null, "the wells are a code-drawn layer")
	assert_true(painter.call(&"well_rects") == wells, "painting the very rects asserted here")
	var gauge: Rect2 = wells[0]
	assert_eq(gauge.size, Vector2(120.0, 120.0), "the gauge well is the pinned 120 x 120")
	assert_eq(gauge.position, Vector2(35.0, 48.5), "centred in the left bay's gauge area")
	var foot: Rect2 = wells[1]
	assert_eq(foot, Rect2(32.0, 185.0, 126.0, 36.0), "the left foot band, 36 tall")
	assert_eq(wells[2].get_center(), Vector2(214.0, 78.0), "the FUEL dial's pinned centre")
	assert_eq(wells[3].get_center(), Vector2(214.0, 181.0), "the ENRG dial's pinned centre")
	assert_eq(wells[2].size, Vector2(80.0, 80.0), "a dial well is face + rim (36 + 4 each way)")
	var readout: Rect2 = wells[4]
	assert_eq(readout.position, Vector2(279.0, 32.0), "the readout well starts at the frame")
	assert_eq(readout.size.x, 150.0, "150 wide inside the 156 px right bay")
	assert_true(
		is_equal_approx(readout.end.y, wells[1].end.y + 0.1),
		"and the stack's bottom row lands in the foot band's bottom"
	)


func test_the_two_dial_rims_are_23_px_clear() -> void:
	var style: Resource = _style()
	assert_eq(style.dial_radius, DIAL_RADIUS, "a 36 px dial radius")
	assert_eq(style.dial_rim, DIAL_RIM, "and a 4 px rim")
	assert_true(
		is_equal_approx(style.dial_clearance(), DIAL_CLEARANCE),
		"the rims are 23 px clear (103 - 2 x 40)"
	)
	var wells: Array[Rect2] = _cockpit().call(&"wells")
	var gap: float = wells[3].position.y - wells[2].end.y
	assert_true(is_equal_approx(gap, DIAL_CLEARANCE), "measured from the drawn wells: %s" % gap)


## ---------------------------------------------------------------------------
## 2. The digit fit law
## ---------------------------------------------------------------------------


func test_every_drum_is_fill_fitted_to_its_style_cell() -> void:
	var style: Resource = _style()
	assert_eq(style.cell_size, CELL, "the style's 20 x 36 drum cell")
	assert_eq(style.cell_pitch, CELL_PITCH, "on a 22 px pitch")
	for key: StringName in ROWS:
		var rects: Array[Rect2] = _row(key).call(&"cell_rects")
		assert_eq(rects.size(), 4, "%s draws four drums" % key)
		for index: int in rects.size():
			assert_eq(rects[index].size, CELL, "%s cell %d is fill-fitted" % [key, index])
			assert_true(
				is_equal_approx(rects[index].position.x, LABEL_ZONE + index * CELL_PITCH),
				"%s cell %d sits on the pitch" % [key, index]
			)
			assert_true(is_equal_approx(rects[index].position.y, 0.0), "and fills the row height")


func test_no_two_glyph_rects_in_a_row_touch() -> void:
	for key: StringName in ROWS:
		var rects: Array[Rect2] = _row(key).call(&"cell_rects")
		assert_eq(_overlaps(rects), 0, "%s has no overlapping pair" % key)
		for index: int in rects.size() - 1:
			var gap: float = rects[index + 1].position.x - rects[index].end.x
			assert_true(gap > 0.0, "%s cells %d/%d are disjoint" % [key, index, index + 1])
			assert_true(
				is_equal_approx(gap, CELL_PITCH - CELL.x),
				"%s cells %d/%d keep the 2 px gap" % [key, index, index + 1]
			)


func test_every_glyph_rect_stays_inside_its_row() -> void:
	for key: StringName in ROWS:
		var row: Control = _row(key)
		var row_rect := Rect2(Vector2.ZERO, row.size)
		assert_eq(row.size.y, ROW_HEIGHT, "%s is 36 tall" % key)
		assert_eq(row.size.x, LABEL_ZONE + 4.0 * CELL_PITCH - 2.0, "%s is 122 wide" % key)
		var style: Resource = _style()
		assert_true(
			is_equal_approx(row.size.x, style.row_width(4)),
			"%s reads its width from the style" % key
		)
		for rect: Rect2 in row.call(&"cell_rects"):
			assert_true(row_rect.encloses(rect), "%s cell %s stays inside its row" % [key, rect])
		assert_true(
			is_equal_approx(float(row.call(&"label_node").size.x), LABEL_ZONE),
			"%s label zone" % key
		)
		assert_eq(
			int(row.call(&"label_node").get_theme_font_size(&"font_size")),
			int(_style().label_font_size),
			"%s label type (11 px, Mockup v5 delta 3)" % key
		)


## ---------------------------------------------------------------------------
## 3. The stack: full interior height, bottom row in the foot band
## ---------------------------------------------------------------------------


func test_the_rows_spread_evenly_through_the_full_interior_height() -> void:
	var style: Resource = _style()
	assert_true(is_equal_approx(style.row_pitch, ROW_PITCH), "the pinned 50.7 px pitch")
	assert_true(is_equal_approx(style.rows_top(), 33.0), "the first row starts at the frame")
	var well: Rect2 = style.readout_well(ROW_COUNT)
	for index: int in ROW_COUNT:
		var row: Control = _row(ROWS[index])
		var expected: Rect2 = style.row_rect(index, 4)
		assert_true(
			is_equal_approx(row.position.y, expected.position.y),
			"%s sits on the stack's own pitch" % ROWS[index]
		)
		assert_true(
			is_equal_approx(row.position.x, style.row_x()),
			"%s joins the row block's left edge" % ROWS[index]
		)
		assert_true(well.encloses(Rect2(row.position, row.size)), "%s is inside the well" % ROWS[index])
	var last: Control = _row(ROWS[ROW_COUNT - 1])
	assert_true(
		is_equal_approx(last.position.y + last.size.y, style.foot_well().end.y + 0.1),
		"the bottom row shares the foot band's bottom edge"
	)


func test_the_row_labels_are_engine_labels_with_the_pinned_text() -> void:
	var expected := ["SPD", "HULL", "SHLD", "AMMO"]
	for index: int in ROW_COUNT:
		var label: Label = _row(ROWS[index]).call(&"label_node")
		assert_true(label != null, "%s has an engine Label" % ROWS[index])
		assert_eq(label.text, expected[index], "%s's own words" % ROWS[index])
		assert_eq(label.horizontal_alignment, HORIZONTAL_ALIGNMENT_LEFT, "left aligned")


## ---------------------------------------------------------------------------
## 4. The battery lamps and the AMMO row
## ---------------------------------------------------------------------------


func test_the_battery_lamps_are_five_22_px_squares_across_122() -> void:
	var band: Control = _cockpit().call(&"lamp_band")
	var rects: Array[Rect2] = band.call(&"lamp_rects")
	assert_eq(rects.size(), 5, "B1..B5")
	assert_true(
		is_equal_approx(rects[4].end.x - rects[0].position.x, LAMP_WIDTH),
		"the band is 122 wide"
	)
	for index: int in rects.size():
		assert_eq(rects[index].size, Vector2(LAMP_SIZE, LAMP_SIZE), "lamp %d is 22 px" % index)
		if index > 0:
			var gap: float = rects[index].position.x - rects[index - 1].end.x
			assert_true(is_equal_approx(gap, LAMP_GAP), "lamp %d's 3 px gap" % index)
	var foot: Rect2 = _style().foot_well()
	assert_true(foot.encloses(rects[0]), "the band sits inside the left foot well")
	assert_true(foot.encloses(rects[4]), "both ends do")
	var labels: Array = band.call(&"lamp_labels")
	assert_eq(labels.size(), 5, "one engine Label per lamp")
	for index: int in labels.size():
		assert_eq((labels[index] as Label).text, "B%d" % (index + 1), "lamp %d's caption" % index)


func test_exactly_the_selected_rack_is_lit() -> void:
	var band: Control = _cockpit().call(&"lamp_band")
	var labels: Array = band.call(&"lamp_labels")
	for rack: int in range(1, 6):
		_hud.call(&"select_battery", rack)
		assert_eq(int(band.call(&"lit_rack")), rack, "rack %d lights its own lamp" % rack)
		for index: int in labels.size():
			var wanted: Color = (
				_token(&"accent_danger_bright") if index == rack - 1 else _token(&"text_dim")
			)
			assert_eq(
				(labels[index] as Label).get_theme_color(&"font_color"),
				wanted,
				"lamp B%d with rack %d selected" % [index + 1, rack]
			)
	## The band is five lamps wide while the input map reaches seven racks: a rack past the
	## band lights nothing rather than clamping onto B5.
	_hud.call(&"select_battery", 7)
	assert_eq(int(band.call(&"lit_rack")), 0, "rack 7 has no lamp to light")
	_hud.call(&"select_battery", 0)
	assert_eq(int(band.call(&"lit_rack")), 0, "and an ordinal outside 1..5 lights nothing")


func test_the_ammo_row_reads_the_existing_feed_with_clamps_and_blanks() -> void:
	_hud.call(&"_on_weapon_changed", 2, &"cannon", 176, 300)
	assert_eq(int(_hud.call(&"readouts")["ammo"]), 176, "the loaded rounds as drawn")
	assert_eq(_cells(AMMO), [BLANK, 1, 7, 6], "right-aligned with leading blanks")
	_hud.call(&"_on_weapon_changed", 2, &"cannon", 7, 300)
	assert_eq(_cells(AMMO), [BLANK, BLANK, BLANK, 7], "a small count pads with blanks, not zeros")
	_hud.call(&"_on_weapon_changed", 2, &"cannon", 9999, 9999)
	assert_eq(_cells(AMMO), [9, 9, 9, 9], "four digits fill the row")
	_hud.call(&"_on_weapon_changed", 2, &"cannon", 20000, 20000)
	assert_eq(int(_hud.call(&"readouts")["ammo"]), 9999, "and the row clamps at 4 cells")


func test_the_ammo_row_follows_the_selected_rack_the_weapon_grid_reads() -> void:
	## CONTRACTS section 11's cell set, built the way `game.gd` builds it: one entry per W
	## cell with the rack ordinal it fires from. Rack 2 holds two cells, so selecting it must
	## show that rack's own pack (the barrel `_barrel_of_battery` resolves), never cell 0's.
	var cells: Array = [
		{"slot": &"weapons", "index": 0, "module": &"w_cannon", "battery": 1, "position": 0},
		{"slot": &"weapons", "index": 1, "module": &"w_rocket", "battery": 2, "position": 1},
		{"slot": &"weapons", "index": 2, "module": &"w_rocket", "battery": 2, "position": 2},
	]
	_hud.call(&"set_hull_slots", &"ship_probe", cells)
	_hud.call(&"select_battery", 2)
	assert_eq(int(_cockpit().call(&"active_rack")), 2, "the lamps follow the rack selection")
	_hud.call(&"_on_weapon_changed", 1, &"rocket", 24, 60)
	assert_eq(int(_hud.call(&"readouts")["ammo"]), 24, "the rack's own barrel figure")
	var band: Control = _cockpit().call(&"lamp_band")
	assert_eq(int(band.call(&"lit_rack")), 2, "and B2 is the one lit")


## ---------------------------------------------------------------------------
## 5. The retired column, the frozen API and the retired heading tick
## ---------------------------------------------------------------------------


func test_the_old_hud_column_is_gone_from_the_flight_hud() -> void:
	var retired: Array = _hud.call(&"retired_widgets")
	assert_eq(retired.size(), 5, "the two crest blocks, the ammo panel, the cargo toggle+panel")
	for widget: Control in retired:
		assert_false(widget.is_visible_in_tree(), "%s is off the flight HUD" % widget.name)
	## The cluster carries what the column used to: HULL/SHLD in the rows and AMMO in the
	## right stack (section 3.7's own replacement list).
	_hud.call(&"_on_hull_changed", 640.0, 1000.0)
	_hud.call(&"_on_shield_changed", 120.0, 300.0)
	_hud.call(&"_on_weapon_changed", 0, &"cannon", 42, 300)
	assert_eq(_cells(HULL), [BLANK, 6, 4, 0], "HULL reads in the cluster")
	assert_eq(_cells(SHLD), [BLANK, 1, 2, 0], "SHLD reads in the cluster")
	assert_eq(_cells(AMMO), [BLANK, BLANK, 4, 2], "AMMO reads in the cluster")
	## Section 3.1b's pool blocks are NOT retired - section 3.7's list names section 3.1's
	## crest bars only, and its own rows stay green in `test_engine2_hud.gd`.
	var pool_bars: Dictionary = _hud.get(&"_pool_bars")
	assert_true(
		pool_bars.has(POOL_FUEL) and pool_bars.has(POOL_ENERGY),
		"the energy and fuel bars survive"
	)


func _on_cargo_toggled(open: bool) -> void:
	_cargo_events.append(open)


func test_every_frozen_section_seven_method_stays_callable() -> void:
	_hud.connect(&"cargo_toggled", Callable(self, "_on_cargo_toggled"))
	_hud.call(&"set_target", Vector2(500.0, 300.0), 0.5)
	_hud.call(&"set_target_info", {"name": "Lancer", "hull": 0.5})
	_hud.call(&"clear_target")
	_hud.call(&"set_cargo_open", true)
	assert_eq(_cargo_events, [true], "the frozen cargo toggle still emits its signal")
	assert_false(
		(_hud.get(&"_cargo_panel") as Control).visible, "its retired panel stays hidden"
	)
	_hud.call(&"set_cargo_open", false)
	_hud.call(&"set_prompt", "F · DOCK")
	_hud.call(&"set_warp_channel", 0.5)
	_hud.call(&"set_prompt", "")
	_hud.call(&"set_pool", POOL_FUEL, 100.0, 200.0)
	_hud.call(&"set_pool", POOL_ENERGY, 40.0, 100.0)
	_hud.call(&"set_emergency", true)
	_hud.call(&"set_emergency", false)
	_hud.call(&"set_reticle_state", TargetReticle.State.PLAIN)
	_hud.call(&"set_lock_progress", 0.5)
	_hud.call(&"set_lock_progress", 0.0)
	_hud.call(&"set_speedometer", 0.5, Vector2(30.0, 40.0), Vector2.RIGHT)
	_hud.call(&"hit_marker")
	_hud.call(&"set_sector_name", "Kepler")
	_hud.call(&"set_minimap_scale", 900.0)
	assert_true(_hud.call(&"hit_marker_node") != null, "hit_marker_node()")
	assert_true(_hud.call(&"lock_ring") != null, "lock_ring()")
	assert_true(_hud.call(&"speedometer") != null, "speedometer()")
	assert_true(_hud.call(&"cockpit") != null, "cockpit()")
	assert_true(float(_hud.call(&"speedometer_ratio")) == 0.5, "speedometer_ratio()")
	assert_true(_hud.call(&"target_info") is Dictionary, "target_info()")


func test_the_section_three_six_dial_draws_no_heading_tick() -> void:
	var dial: Control = _hud.call(&"speedometer")
	var constants: Dictionary = dial.get_script().get_script_constant_map()
	assert_false(constants.has("HEADING_LENGTH"), "the tick's length constant is gone")
	assert_true(dial.get(&"heading") == null, "and the dial holds no heading vector")
	assert_eq(dial.custom_minimum_size, Vector2(120.0, 120.0), "the 120 x 120 pin survives")
	assert_eq(int(constants["SEGMENTS"]), 10, "and the segment count")
	assert_true(is_equal_approx(float(constants["SWEEP"]), PI * 1.5), "and the 270 degree sweep")
	## The painted face and needle come from the style's asset paths (section 3.9 rule 5).
	var style: Resource = _style()
	assert_eq(
		(dial.get(&"_face") as Texture2D).resource_path,
		style.gauge_face_path,
		"the dial's face is the style's face"
	)
	assert_eq(
		(dial.get(&"_needle_texture") as Texture2D).resource_path,
		style.gauge_needle_path,
		"the dial's needle is the style's needle"
	)
	assert_eq(
		(_cockpit().get_node("CockpitPanel") as TextureRect).texture.resource_path,
		style.panel_path,
		"and the cluster's plate is the style's panel"
	)


## ---------------------------------------------------------------------------
## 6. CockpitStyle: the single style surface (section 3.9 rule 5)
## ---------------------------------------------------------------------------


func test_the_default_style_carries_the_specs_own_numbers() -> void:
	var style: Resource = CockpitStyleScript.defaults()
	assert_eq(style.box_size, BOX, "the box")
	assert_eq(style.band, BAND, "the band")
	assert_eq(style.bay_left, BAYS[0], "the left bay")
	assert_eq(style.bay_middle, BAYS[1], "the middle bay")
	assert_eq(style.bay_right, BAYS[2], "the right bay")
	assert_eq(style.gutter, GUTTER, "the gutters")
	assert_eq(style.cell_size, CELL, "the drum cell")
	assert_eq(style.cell_pitch, CELL_PITCH, "the drum pitch")
	assert_eq(style.row_pitch, ROW_PITCH, "the row pitch")
	assert_eq(style.label_zone, LABEL_ZONE, "the label zone")
	assert_eq(style.dial_radius, DIAL_RADIUS, "the dial radius")
	assert_eq(style.lamp_size, LAMP_SIZE, "the lamp size")
	assert_eq(style.lamp_gap, LAMP_GAP, "the lamp gap")
	## Every palette default is section 1's own token value, so the family can never drift
	## from the theme without a deliberate override.
	assert_eq(style.colour(&"text_dim"), _token(&"text_dim"), "text_dim is the token")
	assert_eq(style.colour(&"accent_danger"), _token(&"accent_danger"), "accent_danger is the token")
	assert_eq(
		style.colour(&"accent_danger_bright"),
		_token(&"accent_danger_bright"),
		"accent_danger_bright is the token"
	)
	assert_eq(style.colour(&"text_primary"), _token(&"text_primary"), "text_primary is the token")
	assert_true(style.colour(&"no_such_role") == Color.WHITE, "an unknown role falls back to white")


func test_the_loader_falls_back_to_the_defaults_when_no_file_resolves() -> void:
	## The override file is *allowed* to exist (that is the feature), so this row proves the
	## loader's contract: a path that does not resolve answers the built-in defaults, never a
	## broken cluster.
	var style: Resource = CockpitStyleScript.load_style("res://ui/hud/d7_missing_style.tres")
	assert_eq(style.box_size, BOX, "an unresolvable path answers the built-in defaults")
	assert_eq(style.bay_left, BAYS[0], "with the shipped layout")
	assert_true(style.has_method(&"interior"), "and the real CockpitStyle type")
	var live: Resource = _cockpit().call(&"style")
	assert_true(
		live != null and live.has_method(&"interior"),
		"the live cluster always reads a CockpitStyle"
	)
	assert_eq(
		(_cockpit() as Control).custom_minimum_size, live.box_size, "and lays out to its own box"
	)


func test_a_user_tres_restyles_and_relayouts_with_no_code_edit() -> void:
	var override: Resource = CockpitStyleScript.defaults()
	override.box_size = Vector2(600.0, 300.0)
	override.bay_left = 150.0
	override.row_pitch = 60.0
	override.cell_size = Vector2(24.0, 40.0)
	override.cell_pitch = 26.0
	override.text_dim = Color(0.1, 0.9, 0.2, 1.0)
	override.dial_top = Vector2(280.0, 90.0)
	var written: int = ResourceSaver.save(override, STYLE_PROBE_PATH)
	assert_eq(written, OK, "the user style writes to disk")
	assert_true(FileAccess.file_exists(STYLE_PROBE_PATH), "and exists for the loader")

	_cockpit().call(&"set_style_file", STYLE_PROBE_PATH)
	var style: Resource = _style()
	assert_eq(style.box_size, Vector2(600.0, 300.0), "the file's box is in force")
	assert_eq(
		(_cockpit() as Control).custom_minimum_size,
		Vector2(600.0, 300.0),
		"the cluster relayouts to the file's box"
	)
	assert_eq(style.bay_left, 150.0, "the file's bay moves")
	assert_true(is_equal_approx(style.row_pitch, 60.0), "the file's pitch moves")
	assert_eq(_row(SPD).call(&"cell_rects").size(), 4, "the rows survive the restyle")
	var cell: Rect2 = (_row(SPD).call(&"cell_rects") as Array[Rect2])[0]
	assert_eq(cell.size, Vector2(24.0, 40.0), "the file's drum cell is fill-fitted")
	assert_eq(
		_row(SPD).call(&"label_colour"),
		Color(0.1, 0.9, 0.2, 1.0),
		"the file's palette reaches the drawn label"
	)
	assert_eq(
		(_cockpit().call(&"wells") as Array[Rect2])[2].get_center(),
		Vector2(280.0, 90.0),
		"and the file's dial centre moves the well"
	)

	## Reversal: dropping the file (or pointing at a path that does not resolve) restores the
	## shipped defaults, so an override can never be a one-way door.
	_cockpit().call(&"set_style_file", CockpitStyleScript.USER_PATH)
	assert_eq(_cockpit().call(&"style").box_size, BOX, "back to the shipped box")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))
