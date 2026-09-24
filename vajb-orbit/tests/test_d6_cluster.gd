@tool
extends McpTestSuite
## Suite d6_cluster: wave D6's cockpit instrument cluster (UI_SPEC section 3.7, CONTRACTS
## section 18). It re-asserts the section 3.6 dial contract through the cluster, then proves
## the readouts map (clamps, blank padding, percent cells), every danger-row rule, the
## overdrive strict boundary, and the compass rotation and heading map.
##
## The shipped `hud.tscn` is instantiated into the runner's own scene tree, so `_ready` builds
## the cluster and the live theme is the one the tokens resolve against; the suite frees what
## it added (the same harness `test_engine2_hud.gd` uses).
##
## Everything asserted here is a reading the HUD was handed back: the read-back dictionaries,
## the row tokens, the cells as drawn and the rose's own angle.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const SPD: StringName = &"spd"
const HULL: StringName = &"hull"
const SHLD: StringName = &"shld"
const ROW_FUEL: StringName = &"fuel"
const ROW_ENRG: StringName = &"enrg"
const HDG: StringName = &"hdg"
## The pool feed's own kind strings (`hud.gd::set_pool`'s POOL_KIND_*), distinct from the
## row keys above.
const POOL_FUEL: StringName = &"fuel"
const POOL_ENERGY: StringName = &"energy"

const BLANK := -1

var _hud: Control = null


func suite_name() -> String:
	return "d6_cluster"


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


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Where a fixture may enter the tree; see `test_engine2_hud.gd` for why the profile autoload
## is the host rather than the busy root viewport.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _row(key: StringName) -> Node:
	var cockpit: Control = _hud.call(&"cockpit")
	if cockpit == null:
		return null
	return cockpit.call(&"row", key)


func _cells(key: StringName) -> Array:
	var row: Node = _row(key)
	if row == null:
		return []
	return row.call(&"cells")


func _token(name: StringName) -> Color:
	return HudTheme.get_color(name, &"Tokens")


## ---------------------------------------------------------------------------
## The cluster box and the section 3.6 dial it carries
## ---------------------------------------------------------------------------


func test_the_cluster_is_the_pinned_box_with_the_dial_and_the_compass_inside() -> void:
	var cockpit: Control = _hud.call(&"cockpit")
	assert_true(cockpit != null, "the cluster exists")
	assert_eq(cockpit.custom_minimum_size, Vector2(404.0, 216.0), "UI_SPEC section 3.7's box")
	var compass: Control = _hud.call(&"compass")
	assert_true(compass != null, "the compass bay exists")
	assert_eq(compass.custom_minimum_size, Vector2(96.0, 96.0), "the 96 x 96 rose bay")
	var dial: Control = _hud.call(&"speedometer")
	assert_true(dial != null, "the dial exists")
	assert_true(cockpit.is_ancestor_of(dial), "the dial lives inside the cluster")
	for key: StringName in [SPD, HULL, SHLD, ROW_FUEL, ROW_ENRG, HDG]:
		assert_true(_row(key) != null, "the %s row exists" % key)


## The section 3.6 rows re-asserted through the cluster: the dial's contract is byte-identical
## (this is also `test_engine2_hud.gd:188-237`, re-run here from the cluster's own HUD).
func test_the_section_3_6_dial_contract_holds_through_the_cluster() -> void:
	var dial: Control = _hud.call(&"speedometer")
	assert_eq(dial.custom_minimum_size, Vector2(120.0, 120.0), "the 120 x 120 box")
	var constants: Dictionary = dial.get_script().get_script_constant_map()
	assert_eq(int(constants["SEGMENTS"]), 10, "10 segments")
	assert_true(is_equal_approx(float(constants["SWEEP"]), PI * 1.5), "across 270 degrees")
	assert_eq(float(constants["OVERDRIVE"]), 0.9, "the overdrive read above 0.9")
	var cases := {0.0: 1, 0.05: 1, 0.55: 6, 0.95: 10, 1.0: 10}
	for ratio: float in cases:
		_hud.call(&"set_speedometer", ratio, Vector2.RIGHT, Vector2.RIGHT)
		assert_eq(
			int(dial.call(&"filled_segments")),
			int(cases[ratio]),
			"segment i fills when ratio >= i/10 (ratio %s)" % ratio
		)
	_hud.call(&"set_speedometer", 0.95, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(int(dial.call(&"overdrive_segment")), 9, "the tenth segment reads red")
	_hud.call(&"set_speedometer", 0.9, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(int(dial.call(&"overdrive_segment")), -1, "at exactly 0.9 nothing is in overdrive")
	var wanted: Color = Color("#6fb8c4")
	if HudTheme.has_color(&"accent_nav", &"Tokens"):
		wanted = HudTheme.get_color(&"accent_nav", &"Tokens")
	assert_eq(dial.call(&"needle_colour"), wanted, "the needle's one sanctioned cyan")


## ---------------------------------------------------------------------------
## The readouts map: semantics, clamps and blank padding
## ---------------------------------------------------------------------------


func test_the_readouts_are_the_clamped_ints_the_digits_show() -> void:
	_hud.call(&"set_speedometer", 0.5, Vector2(30.0, 40.0), Vector2.RIGHT)
	_hud.call(&"_on_hull_changed", 812.0, 1000.0)
	_hud.call(&"_on_shield_changed", 240.0, 300.0)
	_hud.call(&"set_pool", POOL_FUEL, 12.0, 200.0)
	_hud.call(&"set_pool", POOL_ENERGY, 40.0, 100.0)
	var readings: Dictionary = _hud.call(&"readouts")
	assert_eq(int(readings["spd"]), 50, "the prograde length in u/s (a 3-4-5)")
	assert_eq(int(readings["hull"]), 812, "the hull points as drawn")
	assert_eq(int(readings["shield"]), 240, "the shield points as drawn")
	assert_eq(int(readings["fuel_pct"]), 6, "12 of 200 as a percent")
	assert_eq(int(readings["energy_pct"]), 40, "40 of 100 as a percent")


func test_the_digit_cells_pad_with_blanks_never_leading_zeros() -> void:
	_hud.call(&"set_speedometer", 0.1, Vector2(5.0, 0.0), Vector2.RIGHT)
	assert_eq(_cells(SPD), [BLANK, BLANK, 5], "SPD pads to its 3 cells with blanks")
	_hud.call(&"_on_hull_changed", 0.0, 1000.0)
	assert_eq(_cells(HULL), [BLANK, BLANK, BLANK, 0], "a zero hull still shows its zero")
	_hud.call(&"_on_hull_changed", 1234.0, 2000.0)
	assert_eq(_cells(HULL), [1, 2, 3, 4], "a full 4-digit hull fills every cell")
	_hud.call(&"set_pool", POOL_FUEL, 7.0, 100.0)
	assert_eq(_cells(ROW_FUEL), [BLANK, BLANK, 7], "FUEL pads to its 3 digits before the %")


func test_the_readouts_clamp_at_their_cell_maxima() -> void:
	_hud.call(&"set_speedometer", 1.0, Vector2(5000.0, 0.0), Vector2.RIGHT)
	assert_eq(int(_hud.call(&"readouts")["spd"]), 999, "SPD clamps at 3 cells")
	assert_eq(_cells(SPD), [9, 9, 9], "and its cells read 999")
	_hud.call(&"_on_hull_changed", 20000.0, 20000.0)
	assert_eq(int(_hud.call(&"readouts")["hull"]), 9999, "HULL clamps at 4 cells")
	_hud.call(&"_on_shield_changed", 12345.0, 12345.0)
	assert_eq(int(_hud.call(&"readouts")["shield"]), 9999, "SHLD clamps at 4 cells")
	_hud.call(&"set_pool", POOL_FUEL, 250.0, 100.0)
	assert_eq(int(_hud.call(&"readouts")["fuel_pct"]), 100, "a percent clamps at 100")
	_hud.call(&"set_pool", POOL_ENERGY, 150.0, 100.0)
	assert_eq(int(_hud.call(&"readouts")["energy_pct"]), 100, "either percent clamps at 100")


func test_a_pool_with_no_capacity_reads_zero() -> void:
	_hud.call(&"set_pool", POOL_FUEL, 50.0, 0.0)
	assert_eq(int(_hud.call(&"readouts")["fuel_pct"]), 0, "a zero maximum reads 0")
	assert_eq(_cells(ROW_FUEL), [BLANK, BLANK, 0], "and draws a single zero")


func test_the_percent_cell_lights_only_on_the_fuel_and_energy_rows() -> void:
	assert_true(bool(_row(ROW_FUEL).call(&"percent_lit")), "FUEL carries the % cell")
	assert_true(bool(_row(ROW_ENRG).call(&"percent_lit")), "ENRG carries the % cell")
	assert_false(bool(_row(SPD).call(&"percent_lit")), "SPD carries no % cell")
	assert_false(bool(_row(HULL).call(&"percent_lit")), "HULL carries no % cell")
	assert_false(bool(_row(HDG).call(&"percent_lit")), "HDG carries no % cell")
	var pct: TextureRect = _row(ROW_FUEL).call(&"percent_cell")
	assert_true(pct != null, "the % cell node exists")
	assert_eq(
		pct.texture.resource_path,
		"res://assets/ui/ui_seg_pct.png",
		"the % cell is the ui_seg_pct cut"
	)


## ---------------------------------------------------------------------------
## The danger-row rules, verbatim
## ---------------------------------------------------------------------------


func test_hull_below_a_quarter_brightens_the_label_and_frames_the_row() -> void:
	_hud.call(&"_on_hull_changed", 25.0, 100.0)
	assert_false(bool(_row(HULL).call(&"framed")), "exactly a quarter is not critical")
	assert_eq(_row(HULL).call(&"label_token"), &"text_dim", "and the label stays dim")
	_hud.call(&"_on_hull_changed", 24.9, 100.0)
	assert_true(bool(_row(HULL).call(&"framed")), "below a quarter frames the row")
	assert_eq(_row(HULL).call(&"frame_token"), &"accent_danger", "in the danger accent")
	assert_eq(
		_row(HULL).call(&"label_token"), &"accent_danger_bright", "and brightens the label"
	)
	_hud.call(&"_on_hull_changed", 0.0, 0.0)
	assert_false(bool(_row(HULL).call(&"framed")), "a hull with no maximum is not critical")


func test_fuel_at_or_below_fifteen_percent_frames_the_row() -> void:
	_hud.call(&"set_pool", POOL_FUEL, 16.0, 100.0)
	assert_false(bool(_row(ROW_FUEL).call(&"framed")), "above 15 % is not a danger read")
	assert_eq(_row(ROW_FUEL).call(&"label_token"), &"text_dim", "and the label stays dim")
	_hud.call(&"set_pool", POOL_FUEL, 15.0, 100.0)
	assert_eq(_row(ROW_FUEL).call(&"frame_token"), &"accent_danger", "at 15 % the row is framed")
	assert_eq(_row(ROW_FUEL).call(&"label_token"), &"accent_danger", "and the label follows")


func test_an_empty_tank_frames_the_fuel_row_bright() -> void:
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 100.0)
	assert_eq(
		_row(ROW_FUEL).call(&"frame_token"), &"accent_danger_bright", "an empty tank reads bright"
	)
	assert_eq(_row(ROW_FUEL).call(&"label_token"), &"accent_danger", "the label is the 15 % read")
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 0.0)
	assert_false(bool(_row(ROW_FUEL).call(&"framed")), "a tank with no capacity is not empty")


func test_the_overdrive_read_is_strict_at_exactly_point_nine() -> void:
	_hud.call(&"set_speedometer", 0.9, Vector2.RIGHT, Vector2.RIGHT)
	assert_false(bool(_row(SPD).call(&"framed")), "at exactly 0.9 nothing is in overdrive")
	_hud.call(&"set_speedometer", 0.9001, Vector2.RIGHT, Vector2.RIGHT)
	assert_true(bool(_row(SPD).call(&"framed")), "just above 0.9 frames the SPD row")
	assert_eq(_row(SPD).call(&"frame_token"), &"accent_danger", "in the danger accent")
	assert_eq(_row(SPD).call(&"label_token"), &"text_dim", "the SPD label never recolours")
	_hud.call(&"set_speedometer", 0.1, Vector2.RIGHT, Vector2.RIGHT)
	assert_false(bool(_row(SPD).call(&"framed")), "and cruise clears the frame")


func test_danger_reads_never_recolour_the_digits() -> void:
	_hud.call(&"_on_hull_changed", 10.0, 100.0)
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 100.0)
	_hud.call(&"set_speedometer", 0.95, Vector2(500.0, 0.0), Vector2.RIGHT)
	assert_eq(
		_row(HULL).call(&"label_colour"), _token(&"accent_danger_bright"), "the hull label read"
	)
	assert_eq(
		_row(ROW_FUEL).call(&"frame_colour"),
		_token(&"accent_danger_bright"),
		"the empty-tank frame read"
	)
	for key: StringName in [SPD, HULL, ROW_FUEL]:
		var cells: Array = _row(key).call(&"digit_cells")
		assert_true(cells.size() > 0, "%s draws digit cells" % key)
		for cell: TextureRect in cells:
			assert_eq(cell.modulate, Color.WHITE, "digits stay palette-neutral (%s)" % key)
			assert_true(cell.texture != null, "and keep a segment cut (%s)" % key)


## ---------------------------------------------------------------------------
## The compass: counter-rotation and the 0..359 heading
## ---------------------------------------------------------------------------


func test_the_compass_rose_rotates_against_the_heading() -> void:
	var compass: Control = _hud.call(&"compass")
	_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, Vector2.RIGHT.rotated(PI * 0.5))
	assert_true(
		is_equal_approx(float(compass.call(&"rose_angle")), -PI * 0.5),
		"the rose rotates -heading.angle()"
	)
	_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, Vector2.RIGHT.rotated(-PI * 0.5))
	assert_true(
		is_equal_approx(float(compass.call(&"rose_angle")), PI * 0.5),
		"and the other way for the other turn"
	)


func test_the_compass_heading_maps_into_zero_to_359() -> void:
	var cases := {
		Vector2.RIGHT: 0.0,
		Vector2.RIGHT.rotated(PI * 0.5): 90.0,
		Vector2.RIGHT.rotated(PI): 180.0,
		Vector2.RIGHT.rotated(-PI * 0.5): 270.0,
	}
	for heading: Vector2 in cases:
		_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, heading)
		assert_true(
			is_equal_approx(float(_hud.call(&"compass_heading")), float(cases[heading])),
			"the heading maps to %s" % cases[heading]
		)
	_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, Vector2.RIGHT.rotated(-PI * 0.5))
	assert_eq(_cells(HDG), [2, 7, 0], "HDG draws the mapped 270")
