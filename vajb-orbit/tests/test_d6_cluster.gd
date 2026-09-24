@tool
extends McpTestSuite
## Suite d6_cluster: the cockpit instrument cluster (UI_SPEC section 3.7, CONTRACTS
## section 18), **re-aimed to the Mockup v5/v7 surface by wave D7** (UI_SPEC section 3.7's
## 2026-09-24 amendments). The cluster is the same widget the D6 wave introduced, so this
## suite stays the cluster's own yardstick; every D7-touched row is commented with the reason
## it moved:
##
##  - the box, the bays and the row set follow the Mockup v7 stack (SPD/HULL/SHLD/AMMO, the
##    FUEL/ENRG digit rows retired into the two value dials);
##  - the pool reads move from `readouts()` to the dials' own `pool_readings()`;
##  - the fuel danger read moves from the FUEL row to the FUEL dial (needle and lit arc);
##  - the `%` cell retired; the compass and the heading readout retired to stubs.
##
## Everything asserted here is a reading the HUD was handed back: the read-back dictionaries,
## the row roles, the cells as drawn and the dials' own angles.
##
## The shipped `hud.tscn` is instantiated into the runner's own scene tree, so `_ready` builds
## the cluster and the live theme is the one the tokens resolve against; the suite frees what
## it added (the same harness `test_engine2_hud.gd` uses).

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const SPD: StringName = &"spd"
const HULL: StringName = &"hull"
const SHLD: StringName = &"shld"
const AMMO: StringName = &"ammo"
const DIAL_FUEL: StringName = &"fuel"
const DIAL_ENRG: StringName = &"enrg"
## The pool feed's own kind strings (`hud.gd::set_pool`'s POOL_KIND_*), distinct from the
## dial keys above.
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


func _dial(key: StringName) -> Node:
	var cockpit: Control = _hud.call(&"cockpit")
	if cockpit == null:
		return null
	return cockpit.call(&"value_dial", key)


func _pools() -> Dictionary:
	var cockpit: Control = _hud.call(&"cockpit")
	if cockpit == null:
		return {}
	return cockpit.call(&"pool_readings")


func _token(name: StringName) -> Color:
	return HudTheme.get_color(name, &"Tokens")


## ---------------------------------------------------------------------------
## The cluster box, the section 3.6 dial it carries and the two value dials
## ---------------------------------------------------------------------------


## Re-aimed from `..._with_the_dial_and_the_compass_inside`: Mockup v7 pins a 464 x 256 box and
## replaces the compass bay with the two value dials, so the row asserts the new box, the
## gauge bay and the dials (the retired compass is asserted by its own row below).
func test_the_cluster_is_the_pinned_box_with_the_gauge_and_the_dials_inside() -> void:
	var cockpit: Control = _hud.call(&"cockpit")
	assert_true(cockpit != null, "the cluster exists")
	assert_eq(cockpit.custom_minimum_size, Vector2(464.0, 256.0), "UI_SPEC section 3.7's box")
	var gauge_bay: Control = cockpit.call(&"gauge_bay")
	assert_true(gauge_bay != null, "the gauge bay exists")
	assert_eq(gauge_bay.size, Vector2(120.0, 120.0), "the section 3.6 dial's own 120 x 120 box")
	var dial: Control = _hud.call(&"speedometer")
	assert_true(dial != null, "the dial exists")
	assert_true(cockpit.is_ancestor_of(dial), "the dial lives inside the cluster")
	for key: StringName in [SPD, HULL, SHLD, AMMO]:
		assert_true(_row(key) != null, "the %s row exists" % key)
	var fuel: Node = _dial(DIAL_FUEL)
	var energy: Node = _dial(DIAL_ENRG)
	assert_true(fuel != null and energy != null, "the two value dials exist")
	assert_eq(fuel.get(&"size"), Vector2(72.0, 72.0), "a 36 px radius dial is 72 x 72")
	assert_eq(
		fuel.call(&"dial_label").text, "FUEL", "the dial names itself with an engine Label"
	)


## The section 3.6 rows re-asserted through the cluster: the dial's contract is byte-identical
## (this is also `test_engine2_hud.gd:188-237`, re-run here from the cluster's own HUD).
## **Unchanged by D7**: section 3.6's own amendment keeps SEGMENTS/SWEEP/OVERDRIVE and the
## read-backs, and only retires the heading tick (which this row never asserted).
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


## Re-aimed: `readouts()` now answers {spd, hull, shield, ammo} (Mockup v7 moved AMMO into the
## stack and the pools onto the dials), so the ammo figure is asserted here and the two
## percents are read from the dials' own `pool_readings()`.
func test_the_readouts_are_the_clamped_ints_the_digits_show() -> void:
	_hud.call(&"set_speedometer", 0.5, Vector2(30.0, 40.0), Vector2.RIGHT)
	_hud.call(&"_on_hull_changed", 812.0, 1000.0)
	_hud.call(&"_on_shield_changed", 240.0, 300.0)
	_hud.call(&"set_pool", POOL_FUEL, 12.0, 200.0)
	_hud.call(&"set_pool", POOL_ENERGY, 40.0, 100.0)
	_hud.call(&"_on_weapon_changed", 0, &"cannon", 176, 300)
	var readings: Dictionary = _hud.call(&"readouts")
	assert_eq(int(readings["spd"]), 50, "the prograde length in u/s (a 3-4-5)")
	assert_eq(int(readings["hull"]), 812, "the hull points as drawn")
	assert_eq(int(readings["shield"]), 240, "the shield points as drawn")
	assert_eq(int(readings["ammo"]), 176, "the active rack's loaded rounds, on the AMMO row")
	assert_eq(
		readings.keys().size(), 4, "Mockup v7's four keys, and nothing else (no fuel_pct/hdg)"
	)
	var pools: Dictionary = _pools()
	assert_eq(int(pools[&"fuel"]["percent"]), 6, "12 of 200 as a percent, on the FUEL dial")
	assert_eq(int(pools[&"enrg"]["percent"]), 40, "40 of 100 as a percent, on the ENRG dial")


## Re-aimed from the FUEL row's 3-cell pad to the AMMO row's 4-cell pad (Mockup v7: every row
## is four cells wide; the FUEL/ENRG rows retired with the dials).
func test_the_digit_cells_pad_with_blanks_never_leading_zeros() -> void:
	_hud.call(&"set_speedometer", 0.1, Vector2(5.0, 0.0), Vector2.RIGHT)
	assert_eq(_cells(SPD), [BLANK, BLANK, BLANK, 5], "SPD pads to its 4 cells with blanks")
	_hud.call(&"_on_hull_changed", 0.0, 1000.0)
	assert_eq(_cells(HULL), [BLANK, BLANK, BLANK, 0], "a zero hull still shows its zero")
	_hud.call(&"_on_hull_changed", 1234.0, 2000.0)
	assert_eq(_cells(HULL), [1, 2, 3, 4], "a full 4-digit hull fills every cell")
	_hud.call(&"_on_weapon_changed", 0, &"cannon", 7, 300)
	assert_eq(_cells(AMMO), [BLANK, BLANK, BLANK, 7], "AMMO pads to its 4 cells with blanks")


## Re-aimed: the SPD/HULL/SHLD clamps are unchanged, the two percents clamp on the dials and
## the AMMO clamp is the new row's own (clamp 0..9999, section 3.7's battery-readout rule).
func test_the_readouts_clamp_at_their_cell_maxima() -> void:
	_hud.call(&"set_speedometer", 1.0, Vector2(5000.0, 0.0), Vector2.RIGHT)
	assert_eq(int(_hud.call(&"readouts")["spd"]), 5000, "a 4-digit speed no longer clips at 999")
	assert_eq(_cells(SPD), [5, 0, 0, 0], "and its 4 cells read 5000")
	_hud.call(&"set_speedometer", 1.0, Vector2(20000.0, 0.0), Vector2.RIGHT)
	assert_eq(int(_hud.call(&"readouts")["spd"]), 9999, "SPD clamps at 4 cells")
	assert_eq(_cells(SPD), [9, 9, 9, 9], "and its cells read 9999")
	_hud.call(&"_on_hull_changed", 20000.0, 20000.0)
	assert_eq(int(_hud.call(&"readouts")["hull"]), 9999, "HULL clamps at 4 cells")
	_hud.call(&"_on_shield_changed", 12345.0, 12345.0)
	assert_eq(int(_hud.call(&"readouts")["shield"]), 9999, "SHLD clamps at 4 cells")
	_hud.call(&"_on_weapon_changed", 0, &"cannon", 20000, 20000)
	assert_eq(int(_hud.call(&"readouts")["ammo"]), 9999, "AMMO clamps at 4 cells")
	assert_eq(_cells(AMMO), [9, 9, 9, 9], "and its cells read 9999")
	_hud.call(&"set_pool", POOL_FUEL, 250.0, 100.0)
	assert_eq(int(_pools()[&"fuel"]["percent"]), 100, "a percent clamps at 100")
	_hud.call(&"set_pool", POOL_ENERGY, 150.0, 100.0)
	assert_eq(int(_pools()[&"enrg"]["percent"]), 100, "either percent clamps at 100")


## Re-aimed from the retired FUEL row to the FUEL dial (section 3.1b's "a tank with no
## capacity is not an empty tank" now reads as the dial's own zero).
func test_a_pool_with_no_capacity_reads_zero() -> void:
	_hud.call(&"set_pool", POOL_FUEL, 50.0, 0.0)
	assert_eq(int(_pools()[&"fuel"]["percent"]), 0, "a zero maximum reads 0")
	assert_false(bool(_dial(DIAL_FUEL).call(&"danger")), "and is not a danger read")
	assert_eq(int(_dial(DIAL_FUEL).call(&"lit_wedges")), 0, "and lights no wedge")


## Re-aimed from `..._lights_only_on_the_fuel_and_energy_rows`: Mockup v7 retired the
## FUEL/ENRG digit rows, and with them the `%` cell, so the row now proves the absence.
func test_the_percent_cell_retired_with_the_fuel_and_energy_rows() -> void:
	for key: StringName in [SPD, HULL, SHLD, AMMO]:
		assert_false(bool(_row(key).call(&"percent_lit")), "%s carries no %% cell" % key)
		assert_true(_row(key).call(&"percent_cell") == null, "%s draws no %% node" % key)


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


## Re-aimed from the FUEL row to the FUEL dial: Mockup v7 moved the fuel danger read onto the
## instrument (needle `accent_danger_bright`, lit arc `accent_danger`), and section 3.1b's
## rule - the energy buffer has no share of its own - now reads as the ENRG dial staying calm.
func test_fuel_at_or_below_fifteen_percent_dangers_the_dial() -> void:
	_hud.call(&"set_pool", POOL_ENERGY, 1.0, 100.0)
	_hud.call(&"set_pool", POOL_FUEL, 16.0, 100.0)
	assert_false(bool(_dial(DIAL_FUEL).call(&"danger")), "above 15 % is not a danger read")
	assert_eq(
		_dial(DIAL_FUEL).call(&"needle_colour"), _token(&"text_primary"), "and the needle is bone"
	)
	_hud.call(&"set_pool", POOL_FUEL, 15.0, 100.0)
	assert_true(bool(_dial(DIAL_FUEL).call(&"danger")), "at 15 % the dial reads danger")
	assert_eq(
		_dial(DIAL_FUEL).call(&"needle_colour"),
		_token(&"accent_danger_bright"),
		"with the bright needle"
	)
	assert_eq(int(_dial(DIAL_FUEL).call(&"lit_wedges")), 2, "and the lit arc follows the value")
	assert_false(
		bool(_dial(DIAL_ENRG).call(&"danger")),
		"the energy dial has no share of its own (section 3.1b)"
	)


## Re-aimed from `..._frames_the_fuel_row_bright` to the dial, same intent: an empty tank is
## the bright read and a tank with no capacity is not empty.
func test_an_empty_tank_dangers_the_fuel_dial() -> void:
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 100.0)
	assert_true(bool(_dial(DIAL_FUEL).call(&"danger")), "an empty tank reads danger")
	assert_eq(
		_dial(DIAL_FUEL).call(&"needle_colour"),
		_token(&"accent_danger_bright"),
		"the bright needle"
	)
	assert_eq(int(_dial(DIAL_FUEL).call(&"lit_wedges")), 0, "and no wedge is lit at empty")
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 0.0)
	assert_false(bool(_dial(DIAL_FUEL).call(&"danger")), "a tank with no capacity is not empty")


func test_the_overdrive_read_is_strict_at_exactly_point_nine() -> void:
	_hud.call(&"set_speedometer", 0.9, Vector2.RIGHT, Vector2.RIGHT)
	assert_false(bool(_row(SPD).call(&"framed")), "at exactly 0.9 nothing is in overdrive")
	_hud.call(&"set_speedometer", 0.9001, Vector2.RIGHT, Vector2.RIGHT)
	assert_true(bool(_row(SPD).call(&"framed")), "just above 0.9 frames the SPD row")
	assert_eq(_row(SPD).call(&"frame_token"), &"accent_danger", "in the danger accent")
	assert_eq(_row(SPD).call(&"label_token"), &"text_dim", "the SPD label never recolours")
	_hud.call(&"set_speedometer", 0.1, Vector2.RIGHT, Vector2.RIGHT)
	assert_false(bool(_row(SPD).call(&"framed")), "and cruise clears the frame")


## Re-aimed: the row legs stay (the critical hull row is still framed and its label bright),
## the fuel leg moves to the dial's needle, and the digit-neutrality sweep now covers the
## three remaining four-cell rows.
func test_danger_reads_never_recolour_the_digits() -> void:
	_hud.call(&"_on_hull_changed", 10.0, 100.0)
	_hud.call(&"set_pool", POOL_FUEL, 0.0, 100.0)
	_hud.call(&"set_speedometer", 0.95, Vector2(500.0, 0.0), Vector2.RIGHT)
	_hud.call(&"_on_weapon_changed", 0, &"cannon", 500, 600)
	assert_eq(
		_row(HULL).call(&"label_colour"), _token(&"accent_danger_bright"), "the hull label read"
	)
	assert_eq(
		_row(HULL).call(&"frame_colour"), _token(&"accent_danger"), "the critical hull frame read"
	)
	assert_eq(
		_dial(DIAL_FUEL).call(&"needle_colour"),
		_token(&"accent_danger_bright"),
		"the empty-tank needle read"
	)
	for key: StringName in [SPD, HULL, SHLD, AMMO]:
		var cells: Array = _row(key).call(&"digit_cells")
		assert_true(cells.size() > 0, "%s draws digit cells" % key)
		for cell: TextureRect in cells:
			assert_eq(cell.modulate, Color.WHITE, "digits stay palette-neutral (%s)" % key)
			assert_true(cell.texture != null, "and keep a segment cut (%s)" % key)


## ---------------------------------------------------------------------------
## The retired compass (Mockup v7) and the heading stub
## ---------------------------------------------------------------------------


## Re-aimed from `test_the_compass_rose_rotates_against_the_heading`: Mockup v6/v7 ditched the
## compass entirely, so there is no rose to rotate and the read-back is a stub (CONTRACTS
## section 18 keeps the signatures callable).
func test_the_compass_retired_with_mockup_v7() -> void:
	assert_true(_hud.call(&"compass") == null, "the compass bay retired the Mockup v7 way")
	_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, Vector2.RIGHT.rotated(PI * 0.5))
	assert_true(
		is_zero_approx(float(_hud.call(&"compass_heading"))),
		"and the heading readout is the stub, whatever the feed says"
	)
	var cockpit: Control = _hud.call(&"cockpit")
	assert_true(cockpit.call(&"compass") == null, "the cluster answers the same stub")


## Re-aimed from `test_the_compass_heading_maps_into_zero_to_359`: heading has no readout any
## more (the owner: "we ditch the compass entirely"), so every heading reads the stub, and the
## HDG key is gone from `readouts()`.
func test_the_heading_stub_answers_zero_for_every_heading() -> void:
	var cases := {
		Vector2.RIGHT: 0.0,
		Vector2.RIGHT.rotated(PI * 0.5): 90.0,
		Vector2.RIGHT.rotated(PI): 180.0,
		Vector2.RIGHT.rotated(-PI * 0.5): 270.0,
	}
	for heading: Vector2 in cases:
		_hud.call(&"set_speedometer", 0.2, Vector2.ZERO, heading)
		assert_true(
			is_zero_approx(float(_hud.call(&"compass_heading"))),
			"the retired heading readout answers 0.0 for %s" % heading
		)
	assert_false(
		(_hud.call(&"readouts") as Dictionary).has(&"hdg"), "readouts() carries no HDG key"
	)
