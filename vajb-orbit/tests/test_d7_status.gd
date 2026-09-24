@tool
extends McpTestSuite
## Suite d7_status: wave D7's ship status modal restyle (UI_SPEC section 3.8's **Mockup C
## amendment 2026-09-24** on section 3.9's instrument language).
##
## The screen's *behaviour* yardstick stays in `test_d6_status.gd` (untouched, byte-green): the
## toggle behind `InputMap.has_action`, the docked guard, the read-only fits, the damaged-side
## swap and the no-write proof. This suite measures the D7 surface the brief pins:
##
##  1. the modal is the flat `ui_status_panel` console plate (a 2x master, no nine-slice), the
##     D6 nine-slice frame node survives retired (hidden) and the title + close box are at
##     Mockup C's own rects;
##  2. the three code-drawn wells mount at section 3.8's pinned rects, and the painter walks
##     the style's own list;
##  3. the hardpoint markers are bone-ringed ember dots on the aspect-fit render (section 3.9
##     rule 4: the state marks stay code-drawn in the style's colours);
##  4. the slot grid is Mockup C's geometry - cells 60 x 74 on a 72 x 88 pitch for a 5 x 3
##     matrix, the `W1..W5` refs as 10 px `SlotNumber` Labels, fitted modules as glyph plates -
##     and a larger matrix is scaled to fit the well rather than clipped;
##  5. the footer strip carries HULL / SHLD / PWR from the fitting panel's own arithmetic;
##  6. `CockpitStyle` really is the single style surface: a user `.tres` restyles **and**
##     relayouts this modal with no code edit.
##
## Everything here is a reading the HUD, the screen or the style hands back; the shipped
## `hud.tscn` is instantiated into the runner's own scene tree the same way the D6 suites do.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_d7_status.cfg"
const STYLE_PROBE_PATH := "user://d7_status_style_probe.tres"

const VANGUARD: StringName = &"ship_vanguard"

## UI_SPEC section 3.8's pinned numbers (the Mockup C block). The suite reads them from the
## style *and* asserts them against these literals, so a default that drifts fails here.
const BOX := Vector2(720.0, 520.0)
const MASTER := Vector2(1440.0, 1040.0)
const WELL_LEFT := Rect2(24.0, 60.0, 276.0, 368.0)
const WELL_RIGHT := Rect2(316.0, 60.0, 380.0, 288.0)
const FOOTER := Rect2(24.0, 444.0, 672.0, 50.0)
const WELL_INSET := 16.0
const CELL := Vector2(60.0, 74.0)
const CELL_PITCH := Vector2(72.0, 88.0)
const GRID_ORIGIN := Vector2(332.0, 76.0)
const REF_INSET := Vector2(6.0, 4.0)
const REF_ZONE := 26.0
const GLYPH := Vector2(28.0, 32.0)
const TITLE_POS := Vector2(30.0, 22.0)
const CLOSE_POS := Vector2(668.0, 20.0)
const CLOSE_SIZE := Vector2(26.0, 26.0)
const FOOTER_X: Array[float] = [40.0, 250.0, 470.0]
const FOOTER_LABEL_Y := 14.0
const MARKER_RADIUS := 5.0
const FRAME_PATH := "res://assets/ui/ui_cockpit_frame.png"
const PANEL_PATH := "res://assets/ui/ui_status_panel.png"
const CLOSE_PATH := "res://assets/icons/hud/icon_close.svg"
const TITLE_TEXT := "SHIP STATUS"
## STYLE_BIBLE section 2.4's Bone Text, the tone section 3.9 rule 2's "Bone/Panel-Steel
## palette" names (`CockpitStyle.bone`; section 1 has no such token).
const BONE := Color("#c9cdd2")
## The repair kit's slot glyph stems, held here so a drift in either direction is a red
## assertion (the D6 suite's own table).
const SLOT_GLYPH_STEMS: Dictionary = {
	&"engines": "engine", &"power": "power", &"weapons": "w", &"shields": "s",
	&"armour": "h", &"computers": "c", &"boosters": "b", &"utility": "u",
}

var _profile: Node = null
var _hud: Control = null
var _previous_path := ""


func suite_name() -> String:
	return "d7_status"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to mount the HUD")
		return
	_profile = tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the screen's store")
		return
	## Probe hygiene (L17): the shipped autoload is borrowed on a scratch path and flushed
	## before the real one is restored, so a test's account never lands in the owner's file.
	_previous_path = String(_profile.get(&"save_path"))
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_seed_account(VANGUARD)
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
	if FileAccess.file_exists(STYLE_PROBE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Where a fixture may enter the tree; see `test_engine2_hud.gd` for why the profile autoload
## is the host rather than the busy root viewport.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


## The fixture account: the hull owned and active, an empty inventory and no stored fit - so
## `resolved_fit` answers 09 section 9's `ShipFit.standard_fit`, exactly as the launch would
## fly it (the D6 suite's own fixture).
func _seed_account(hull: StringName) -> void:
	var owned: Array[StringName] = [hull]
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Every read enters through here, and a fixture that did not build the screen is a red
## assertion rather than a null dereference the runner would still score as a pass.
func _screen() -> Control:
	var screen: Control = null
	if _hud != null:
		screen = _hud.call(&"status_screen")
	assert_true(screen != null, "the HUD built the section 3.8 screen")
	return screen


## Open with the vanguard pushed, so the drawn grid, the render and the markers are the
## shipped hull's own.
func _open_vanguard() -> Control:
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_screen().call(&"set_open", true)
	return _screen()


func _style() -> Resource:
	return _screen().call(&"style")


func _token(name: StringName) -> Color:
	return HudTheme.get_color(name, &"Tokens")


## The fitted module icons and the type slot glyphs of an empty cell (the D6 suite's own
## precedence, re-derived here so a drift is red).
func _expected_icon(slot_key: StringName, base: StringName) -> String:
	if base != &"":
		return ModuleData.icon_path(base)
	return "res://assets/icons/slot/icon_slot_%s.svg" % String(SLOT_GLYPH_STEMS[slot_key])


## ---------------------------------------------------------------------------
## The plate, the title and the close box (Mockup C's own chrome)
## ---------------------------------------------------------------------------


func test_the_modal_is_the_flat_mockup_c_plate_with_a_retired_frame() -> void:
	var screen := _screen()
	assert_eq(String(screen.name), "ShipStatusScreen", "the pinned node name")
	assert_eq(screen.call(&"modal_size"), BOX, "the 720 x 520 box, from the style")
	var body: Control = screen.call(&"body")
	assert_eq(body.custom_minimum_size, BOX, "the body carries the same box")
	var plate: TextureRect = screen.call(&"plate")
	assert_true(plate != null, "the console plate exists")
	assert_eq(plate.get_class(), "TextureRect", "a plain TextureRect, never a nine-slice patch")
	assert_eq(plate.texture.resource_path, PANEL_PATH, "the style's own plate master")
	assert_eq(plate.texture.get_size(), MASTER, "a master at 2x the 720 x 520 box")
	assert_eq(plate.stretch_mode, TextureRect.STRETCH_SCALE, "scaled to the box, no patch band")
	## The D6 nine-slice node survives retired rather than deleted (test_d6_status.gd pins it),
	## so the visible chrome is the plate alone.
	var frame: NinePatchRect = screen.call(&"frame")
	assert_true(frame != null, "the legacy frame node survives")
	assert_eq(frame.texture.resource_path, FRAME_PATH, "with its D6 texture intact")
	assert_false(frame.visible, "retired: it draws nothing any more")
	var title: Label = screen.call(&"title_label")
	assert_eq(title.text, TITLE_TEXT, "the title is an engine Label (no baked text)")
	assert_eq(title.position, TITLE_POS, "at Mockup C's own origin")
	assert_eq(title.theme_type_variation, &"StationPanelTitle", "in the panel-title variation")
	var close_button: TextureButton = screen.call(&"close_button")
	assert_true(close_button != null, "the close box exists")
	assert_eq(close_button.texture_normal.resource_path, CLOSE_PATH, "the icon_close cut")
	assert_eq(close_button.position, CLOSE_POS, "at Mockup C's own rect")
	assert_eq(close_button.size, CLOSE_SIZE, "26 x 26")


## ---------------------------------------------------------------------------
## The three code-drawn wells (section 3.9 rule 2)
## ---------------------------------------------------------------------------


func test_the_wells_mount_at_the_pinned_rects() -> void:
	var screen := _open_vanguard()
	var style: Resource = _style()
	var wells: Array = screen.call(&"wells")
	assert_eq(wells.size(), 3, "the render well, the slot well and the footer strip")
	assert_eq(wells[0], WELL_LEFT, "the left render well (24,60)-(300,428)")
	assert_eq(wells[1], WELL_RIGHT, "the right slot well (316,60)-(696,348)")
	assert_eq(wells[2], FOOTER, "the footer strip (24,444)-(696,494)")
	assert_eq(wells, style.status_wells(), "the painter walks the style's own list")
	assert_eq(
		style.status_render_area(),
		style.status_well_left.grow(-WELL_INSET),
		"the render's fit area is the left well, inset"
	)
	## Code-drawn, not a texture: the painter is a plain Control (the plate is the only art).
	var painter: Control = screen.find_child("Wells", true, false) as Control
	assert_true(painter != null, "the well painter exists")
	assert_false(painter is TextureRect, "the wells are code-drawn, never a baked plate")
	assert_false(painter is NinePatchRect, "and never a nine-slice")
	## Every well sits inside the box the plate covers.
	for well: Rect2 in wells:
		assert_true(Rect2(Vector2.ZERO, BOX).encloses(well), "well %s is inside the modal" % well)


## ---------------------------------------------------------------------------
## The hardpoint markers (bone-ringed ember dots)
## ---------------------------------------------------------------------------


func test_the_markers_are_bone_ringed_ember_dots_on_the_render() -> void:
	var screen := _open_vanguard()
	var style: Resource = _style()
	assert_true(ShipFit.is_mapped(VANGUARD), "the vanguard carries a HARDPOINTS row")
	var markers: Array = screen.call(&"hardpoint_markers")
	assert_eq(markers.size(), 11, "four thruster modes x two anchors + three weapon mounts")
	_assert_markers_on_the_drawn_sprite(markers)
	var painter: Control = screen.find_child("HardpointMarkers", true, false) as Control
	assert_true(painter != null, "the marker painter exists")
	var box: Control = screen.find_child("HullRenderBox", true, false) as Control
	assert_true(painter.get_parent() == box, "the dots ride the render box, over the hull")
	var colours: Dictionary = painter.call(&"marker_colours")
	assert_eq(colours[&"ring"], style.colour(&"bone"), "the ring is the style's Bone Text")
	assert_eq(colours[&"ring"], BONE, "STYLE_BIBLE section 2.4's own bone")
	assert_eq(colours[&"fill"], style.colour(&"accent_danger"), "the core is the ember")
	assert_true(is_equal_approx(float(painter.call(&"marker_radius")), MARKER_RADIUS), "a 5 px dot")
	assert_true(
		is_equal_approx(float(painter.call(&"marker_radius")), style.status_marker_radius),
		"from the style"
	)
	assert_true(
		is_equal_approx(float(painter.call(&"marker_width")), style.frame_width),
		"with the style's 1 px ring"
	)
	## No marker is an art file: the dots are state (section 3.9 rule 4).
	assert_false(painter is TextureRect, "the dots are code-drawn")


## The sprite's drawn space, re-derived the way `STRETCH_KEEP_ASPECT_CENTERED` draws it inside
## the render box, never from the screen's own render size: the box takes the sprite's aspect
## (section 3.8's R1-MED-1 rule), so box-local space is on-hull space. The D6 suite's own
## helper, kept because the marker anchors are the same derivation. The drawn box is read from
## `Control.size`, **never** `custom_minimum_size`: the difference between the two is exactly the
## stale-clamp class R1 HIGH-1 found, and the drawn box must stay inside `WELL_LEFT`.
func _assert_markers_on_the_drawn_sprite(markers: Array) -> void:
	var render: TextureRect = _screen().call(&"hull_render")
	assert_true(render.texture != null, "a side cut is drawn")
	var box := _screen().find_child("HullRenderBox", true, false) as Control
	assert_true(box != null, "the left well keeps its render box")
	if render.texture == null or box == null:
		return
	assert_false(
		bool(box.size_flags_vertical & Control.SIZE_EXPAND),
		"the render box takes the sprite's aspect, never the well's height"
	)
	var drawn_box := Rect2(box.position, box.size)
	assert_true(
		WELL_LEFT.encloses(drawn_box),
		"the drawn sprite box %s sits inside the left well %s" % [drawn_box, WELL_LEFT]
	)
	var native: Vector2 = render.texture.get_size()
	var box_size: Vector2 = box.size
	var fit: float = minf(box_size.x / native.x, box_size.y / native.y)
	var drawn: Vector2 = native * fit
	assert_true(drawn.is_equal_approx(box_size), "the aspect-fit sprite fills the box")
	var drawn_centre: Vector2 = (box_size - drawn) * 0.5 + drawn * 0.5
	var expected: Array[Vector2] = []
	for mode: StringName in [&"rear", &"front", &"left", &"right"]:
		for point: Vector2 in ShipFit.thruster_points(VANGUARD, mode):
			expected.append(drawn_centre + point * fit)
	for mount: Dictionary in ShipFit.weapon_mounts(VANGUARD):
		expected.append(drawn_centre + Vector2(mount[&"pos"]) * fit)
	assert_eq(markers.size(), expected.size(), "one marker per HARDPOINTS anchor")
	for i in range(mini(markers.size(), expected.size())):
		var pos: Vector2 = (markers[i] as Dictionary)[&"pos"]
		assert_true(
			pos.is_equal_approx(expected[i]),
			"marker %d lands on the sprite's drawn centre plus its render px" % i
		)


## ---------------------------------------------------------------------------
## The slot grid (Mockup C's own geometry)
## ---------------------------------------------------------------------------


func test_the_slot_grid_is_mockup_cs_cell_geometry() -> void:
	var style: Resource = _style()
	assert_eq(style.status_cell_size, CELL, "a 60 x 74 cell")
	assert_eq(style.status_cell_pitch, CELL_PITCH, "on a 72 x 88 pitch")
	assert_true(is_equal_approx(style.status_grid_scale(5, 3), 1.0), "a 5 x 3 matrix is the pin")
	assert_eq(style.status_cell_size_for(5, 3), CELL, "drawn at the pinned size")
	assert_eq(style.status_cell_pitch_for(5, 3), CELL_PITCH, "on the pinned pitch")
	assert_eq(style.status_grid_origin(), GRID_ORIGIN, "the grid starts at (332,76)")
	assert_eq(style.status_cell_rect(0, 0, 5, 3), Rect2(GRID_ORIGIN, CELL), "the first cell")
	assert_eq(
		style.status_cell_rect(4, 2, 5, 3),
		Rect2(Vector2(620.0, 252.0), CELL),
		"the 5 x 3 matrix's last cell"
	)
	assert_true(
		style.status_grid_inner().encloses(style.status_grid_rect(5, 3)),
		"and the whole 5 x 3 matrix fits the well"
	)
	## Every hull's own matrix fits too: one wider or taller is scaled down, never clipped.
	for hull: StringName in ShipFit.SLOT_GRIDS.keys():
		var matrix: Vector2i = ShipFit.grid_size(hull)
		var scale: float = style.status_grid_scale(matrix.x, matrix.y)
		assert_true(scale <= 1.0, "%s never scales up" % hull)
		assert_true(
			style.status_grid_inner().encloses(style.status_grid_rect(matrix.x, matrix.y)),
			"%s's whole matrix fits the well" % hull
		)
	## The drawn vanguard grid: the hull's own matrix, cell for cell.
	var screen := _open_vanguard()
	var grid: GridContainer = screen.call(&"slot_grid")
	var matrix: Vector2i = ShipFit.grid_size(VANGUARD)
	assert_eq(screen.call(&"grid_matrix"), matrix, "the drawn matrix is the hull's")
	assert_eq(grid.columns, matrix.x, "columns = the matrix width")
	assert_eq(
		grid.get_child_count(),
		ShipFit.grid_cells(VANGUARD).size(),
		"one child per matrix cell, gaps included"
	)
	assert_eq(grid.position, style.status_grid_origin(), "the grid mounts at the well's origin")


func test_every_cell_carries_its_ref_and_its_glyph_plate() -> void:
	var screen := _open_vanguard()
	var style: Resource = _style()
	var matrix: Vector2i = ShipFit.grid_size(VANGUARD)
	var refs: Array = screen.call(&"cell_refs")
	var cells: Array = screen.call(&"grid_cells")
	assert_eq(refs.size(), cells.size(), "one ref entry per drawn (non-gap) cell")
	assert_eq(refs.size(), 11, "the vanguard's eleven slots")
	var cell: Vector2 = style.status_cell_size_for(matrix.x, matrix.y)
	var fitted := 0
	for entry: Dictionary in refs:
		var label: Label = entry[&"label"]
		assert_eq(label.text, String(entry[&"ref"]), "the drawn ref is the reading")
		assert_eq(
			String(entry[&"ref"]),
			"%s%d" % [String(entry[&"token"]), int(entry[&"index"]) + 1],
			"the layout cell ref (index + 1)"
		)
		assert_eq(label.theme_type_variation, &"SlotNumber", "the 10 px slot-number variation")
		assert_eq(int(label.get_theme_font_size(&"font_size")), style.status_ref_font_size, "10 px")
		assert_eq(label.position, style.status_ref_inset_for(matrix.x, matrix.y), "at the style's corner inset")
		assert_eq(
			entry[&"rect"],
			style.status_cell_rect(int(entry[&"col"]), int(entry[&"row"]), matrix.x, matrix.y),
			"the cell's own rect"
		)
		var plate: TextureButton = entry[&"plate"]
		assert_eq(plate.custom_minimum_size, cell, "the plate is exactly one cell")
		var glyph: TextureRect = entry[&"glyph"]
		assert_true(glyph.texture != null, "every drawn cell carries a glyph texture")
		if glyph.texture != null:
			if bool(entry[&"fitted"]):
				assert_eq(
					glyph.texture.resource_path,
					_expected_icon(
						StringName(entry[&"type"]),
						_fitted_base(int(entry[&"col"]), int(entry[&"row"]))
					),
					"a fitted cell draws its module's own catalogue icon"
				)
			else:
				assert_eq(
					glyph.texture.resource_path,
					_expected_icon(StringName(entry[&"type"]), &""),
					"an empty cell draws its type's slot glyph"
				)
		if bool(entry[&"fitted"]):
			fitted += 1
	assert_eq(fitted, 5, "09 section 9's standard fit fills five cells")
	## The seam: the refs drawn on the cells are the refs the module rows name, in the grid's
	## own order (both derivations walk `ShipFit.grid_cells`).
	var drawn: Array = []
	for entry: Dictionary in refs:
		if bool(entry[&"fitted"]):
			drawn.append(String(entry[&"ref"]))
	var named: Array = []
	for row: Dictionary in screen.call(&"module_rows"):
		named.append(String(row[&"ref"]))
	assert_eq(drawn, named, "the fitted cells' refs are the module rows' refs")


## The base module a drawn cell holds, read off the screen's own `grid_cells` record.
func _fitted_base(col: int, row: int) -> StringName:
	for cell: Dictionary in _screen().call(&"grid_cells"):
		if int(cell[&"col"]) == col and int(cell[&"row"]) == row:
			return StringName(cell[&"module"])
	return &""


## ---------------------------------------------------------------------------
## The footer (the fitting panel's own arithmetic)
## ---------------------------------------------------------------------------


func test_the_footer_carries_the_fitting_panels_own_figures() -> void:
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_hud.call(&"_on_hull_changed", 812.0, 1000.0)
	_hud.call(&"_on_shield_changed", 240.0, 300.0)
	var screen := _screen()
	screen.call(&"set_open", true)
	var style: Resource = _style()
	var footer: Dictionary = screen.call(&"footer_lines")
	assert_eq(String(footer[&"hull"]), "HULL 812 / 1000", "HULL cur / max")
	assert_eq(String(footer[&"shield"]), "SHLD 240 / 300", "SHLD cur / max")
	## The reuse proof: the screen's PWR numbers are `ShipFit.fit_legal(hull, base_fit)[power]`
	## - the fitting panel's own `_power_of` - so both must agree cell for cell.
	var fit: Dictionary = _profile.call(&"resolved_fit", VANGUARD)
	var power: Dictionary = ShipFit.fit_legal(VANGUARD, _profile.call(&"base_fit", fit))[&"power"]
	assert_eq(int(footer[&"draw"]), int(power[&"draw"]), "the draw is fit_legal's own")
	assert_eq(int(footer[&"out"]), int(power[&"out"]), "the capacity is fit_legal's own")
	assert_eq(
		String(footer[&"power"]),
		"PWR %d / %d" % [int(power[&"draw"]), int(power[&"out"])],
		"and the line is the fitting pane's own METER_IDLE wording"
	)
	## The three labels are the 18 px HUD readouts at Mockup C's own origins.
	var names: Array[String] = ["HullValue", "ShieldValue", "PowerValue"]
	var lines: Array[String] = ["hull", "shield", "power"]
	for index: int in names.size():
		var label: Label = screen.find_child(names[index], true, false) as Label
		assert_true(label != null, "the %s readout exists" % names[index])
		assert_eq(label.text, String(footer[lines[index]]), "the drawn text is the reading")
		assert_eq(label.theme_type_variation, &"HudReadout", "an 18 px HUD readout")
		assert_eq(
			label.position,
			style.status_footer_label_pos(index),
			"at the strip's own origin"
		)
		assert_eq(label.position, Vector2(FOOTER_X[index], FOOTER.position.y + FOOTER_LABEL_Y), "the mockup's x")
		assert_true(
			FOOTER.encloses(Rect2(label.position, label.size)),
			"and inside the footer strip"
		)


## ---------------------------------------------------------------------------
## The style (UI_SPEC section 3.9 rule 5)
## ---------------------------------------------------------------------------


func test_the_default_style_carries_the_mockup_c_numbers() -> void:
	var style: Resource = CockpitStyleScript.defaults()
	assert_eq(style.status_box, BOX, "the 720 x 520 box")
	assert_eq(style.status_wells().size(), 3, "three wells")
	assert_eq(style.status_wells()[0], WELL_LEFT, "the render well")
	assert_eq(style.status_wells()[1], WELL_RIGHT, "the slot well")
	assert_eq(style.status_wells()[2], FOOTER, "the footer strip")
	assert_eq(style.status_well_inset, WELL_INSET, "the 16 px inset")
	assert_eq(style.status_cell_size, CELL, "the cell")
	assert_eq(style.status_cell_pitch, CELL_PITCH, "the pitch")
	assert_eq(style.status_ref_inset, REF_INSET, "the ref inset")
	assert_eq(style.status_ref_zone, REF_ZONE, "the ref zone")
	assert_eq(style.status_glyph_size, GLYPH, "the glyph plate")
	assert_eq(style.status_title_pos, TITLE_POS, "the title origin")
	assert_eq(style.status_close_size, CLOSE_SIZE, "the close box")
	assert_eq(style.colour(&"bone"), BONE, "STYLE_BIBLE section 2.4's Bone Text")
	assert_true(is_equal_approx(style.status_marker_radius, MARKER_RADIUS), "the 5 px dot")
	assert_eq(style.status_panel_path, PANEL_PATH, "the plate master")
	assert_eq(style.close_icon_path, CLOSE_PATH, "the close icon")
	assert_eq(style.status_footer_x, FOOTER_X, "the footer origins")
	## The shared palette is still section 1's own tokens (the D6 read-backs unchanged).
	assert_eq(style.colour(&"text_dim"), _token(&"text_dim"), "text_dim is the token")
	assert_eq(style.colour(&"accent_danger"), _token(&"accent_danger"), "accent_danger is the token")


func test_a_user_tres_restyles_and_relayouts_with_no_code_edit() -> void:
	var override: Resource = CockpitStyleScript.defaults()
	override.status_box = Vector2(800.0, 600.0)
	override.status_well_left = Rect2(30.0, 70.0, 300.0, 400.0)
	override.status_well_right = Rect2(340.0, 70.0, 400.0, 300.0)
	override.status_cell_size = Vector2(50.0, 60.0)
	override.status_cell_pitch = Vector2(60.0, 72.0)
	override.bone = Color(0.1, 0.9, 0.2, 1.0)
	override.status_panel_path = "res://assets/ui/ui_cockpit_panel.png"
	var footer_x: Array[float] = [36.0, 240.0, 460.0]
	override.status_footer_x = footer_x
	var written: int = ResourceSaver.save(override, STYLE_PROBE_PATH)
	assert_eq(written, OK, "the user style writes to disk")

	_open_vanguard()
	_screen().call(&"set_style_file", STYLE_PROBE_PATH)
	var style: Resource = _style()
	assert_eq(style.status_box, Vector2(800.0, 600.0), "the file's box is in force")
	assert_eq(
		(_screen().call(&"body") as Control).custom_minimum_size,
		Vector2(800.0, 600.0),
		"the modal relayouts to the file's box"
	)
	assert_eq(
		(_screen().call(&"wells") as Array)[0],
		Rect2(30.0, 70.0, 300.0, 400.0),
		"the file's left well moves the drawn recess"
	)
	assert_eq(style.status_grid_origin(), Vector2(356.0, 86.0), "the file's right well moves the grid")
	assert_eq(
		style.status_cell_rect(0, 0, 5, 3),
		Rect2(356.0, 86.0, 50.0, 60.0),
		"and the file's cell geometry is drawn"
	)
	var plate: TextureRect = _screen().call(&"plate")
	assert_eq(
		plate.texture.resource_path,
		"res://assets/ui/ui_cockpit_panel.png",
		"the file's panel path reaches the plate"
	)
	var painter: Control = _screen().find_child("HardpointMarkers", true, false) as Control
	assert_eq(
		(painter.call(&"marker_colours") as Dictionary)[&"ring"],
		Color(0.1, 0.9, 0.2, 1.0),
		"the file's palette reaches the drawn marker ring"
	)
	var power_label: Label = _screen().find_child("PowerValue", true, false) as Label
	assert_eq(
		power_label.position,
		Vector2(460.0, 444.0 + FOOTER_LABEL_Y),
		"and the file's footer origins move the readouts"
	)

	## Reversal: dropping the file (or a path that does not resolve) restores the shipped
	## numbers, so an override can never be a one-way door.
	_screen().call(&"set_style_file", CockpitStyleScript.USER_PATH)
	assert_eq(_style().status_box, BOX, "back to the shipped box")
	assert_eq((_screen().call(&"wells") as Array)[0], WELL_LEFT, "back to the pinned well")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))
