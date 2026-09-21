@tool
extends McpTestSuite
## Suite ui_slot_layout: the UI-chrome wave's D3 guard, re-pointed at the P2-A layout.
##
## D3: every slot plate is a TextureButton whose minimum size was driven by the plate
## texture's native size, because no site set `ignore_texture_size`. The 2026-09-21 00:17
## chrome re-cut shipped whole sheet cells (880 x 876 weapon, 873 x 864 cargo), so the
## SHIPYARD hardpoint strip demanded 7 x 880 + 6 x 4 = 6184 px and the LAUNCH panel 4781 px,
## which put the ship list at x = -2393 and LaunchButton at x = 3178 (playtest session 1).
##
## The guard is `ignore_texture_size = true` at every plate site plus the documented 48 px
## weapon and 40 px cargo cell sizes, so the layout reads the cell and never the art.
##
## P2-A (CONTRACTS section 11) replaced the SHIPYARD's fixed seven-plate strip with the
## selected hull's own 08 section 3.2 matrix grid, and the HUD's fixed five-cell weapon row
## with the launched hull's own W cells. The strip's cell count, its `columns` and the HUD's
## weapon-cell count are therefore read from `ShipFit` for the selected / active hull, never
## from the literals 7 and 5 the pre-wave body carried; the cells that must still be exactly
## 48 px (weapon) and 40 px (cargo) and the 4096 px-art guard are unchanged.
##
## Every number here is measured off the shipped scenes with the shipped theme and the art
## that is on disk at the moment of the run: `get_combined_minimum_size()` is the quantity
## the station shell sizes a panel from, and it is the quantity the playtest's overflow was.
## The oversized-art tests then swap in a 4096 px plate and prove the measurement does not
## move. Nothing is awaited, because the headless runner calls a test synchronously: a
## coroutine would let the runner read a verdict before the assertions ran.

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const HudScene := preload("res://ui/hud/hud.tscn")
const SlotScene := preload("res://ui/components/slot_button.tscn")
const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Modules := preload("res://game/module_catalog.gd")
const Groups := preload("res://game/weapons.gd")

const VIEWPORT_WIDTH_SETTING := "display/window/size/viewport_width"
const VIEWPORT_HEIGHT_SETTING := "display/window/size/viewport_height"
const FALLBACK_VIEWPORT := Vector2(1920.0, 1080.0)

const WEAPON_CELL := Vector2(48.0, 48.0)
const CARGO_CELL := Vector2(40.0, 40.0)
const WEAPON_VARIATION: StringName = &"SlotButtonWeapon"
const CARGO_VARIATION: StringName = &"SlotButtonCargo"

const CARGO_CELLS := 5
const HARDPOINT_SEPARATION := 4.0
const CARGO_SEPARATION := 6.0
const HUD_CARGO_CELLS := 40
const HUGE_ART := Vector2(4096.0, 4096.0)

## CONTRACTS section 11's pinned row sets, transcribed here so the shipped panels are read
## against the pin rather than against themselves.
const STAT_KEYS: Array[StringName] = [&"hull", &"shield", &"cargo", &"engines", &"slots"]
const STAT_LABELS: Array[String] = ["HULL", "SHIELD", "CARGO", "ENGINES", "SLOT CELLS"]
const BRIEF_ROWS: Array[Dictionary] = [
	{&"key": &"destination", &"label": "DESTINATION"},
	{&"key": &"hull_name", &"label": "ACTIVE HULL"},
	{&"key": &"hull", &"label": "HULL LIMIT"},
	{&"key": &"shield", &"label": "SHIELD LIMIT"},
	{&"key": &"engines", &"label": "ENGINES"},
	{&"key": &"hardpoints", &"label": "HARDPOINTS"},
	{&"key": &"slots", &"label": "SLOT CELLS"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"ammo", &"label": "AMMUNITION"},
]
const LAYOUT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"
const META_FORMAT := "%d HULL · %d SLOTS"

## 09 section 1's slot glyph per slot-type key: the file stem each type draws. The grid's
## plates are read against the shipped files, not against the panel's own table.
const SLOT_GLYPH_STEMS: Dictionary = {
	&"engines": "engine",
	&"power": "power",
	&"weapons": "w",
	&"shields": "s",
	&"armour": "h",
	&"computers": "c",
	&"boosters": "b",
	&"utility": "u",
}
const SLOT_GLYPH_DIR := "res://assets/icons/slot/"
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s_48.png"
const SLOT_GLYPH_WEAPON := "res://assets/icons/slot/icon_slot_w_48.png"
## The one module the pushed HUD cells fit, so a fitted cell's icon is a real catalogue path
## (`ModuleCatalog.icon_path`) rather than a hand-written string.
const FITTED_MODULE := &"w_laser"

## Every site the guard has to hold, with the literal it has to carry: the component scene,
## the component's `configure()`/`configure_cell()`, the two station panels' `_make_plate()`
## and the HUD's builders (the last holds the literal once per site).
const PLATE_SITES: Array[String] = [
	"res://ui/components/slot_button.tscn",
	"res://ui/components/slot_button.gd",
	"res://ui/station/shipyard_panel.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/hud/hud.gd",
]
const PLATE_LITERAL := "ignore_texture_size = true"

var _host: Control = null


func suite_name() -> String:
	return "ui_slot_layout"


func setup() -> void:
	_host = Control.new()
	_host.name = "SlotLayoutHost"
	_host.theme = ThemeRes
	_host.size = viewport_size()
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


## The runner calls every test from inside its own `_ready`, so the root viewport is still
## busy adding the runner scene and `root.add_child(...)` fails ("Parent node is busy setting
## up children"). The profile autoload entered the tree before the main scene, so it hosts
## the fixtures the way suite engine2_hud hosts its own.
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var root := tree.root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


## The live window size, read from the project rather than assumed, so the panel has to fit
## the same frame the game boots into.
func viewport_size() -> Vector2:
	var width: float = float(ProjectSettings.get_setting(VIEWPORT_WIDTH_SETTING, FALLBACK_VIEWPORT.x))
	var height: float = float(ProjectSettings.get_setting(VIEWPORT_HEIGHT_SETTING, FALLBACK_VIEWPORT.y))
	return Vector2(width, height)


func _mount(scene: PackedScene) -> Control:
	var node := scene.instantiate() as Control
	if node == null:
		return null
	_host.add_child(node)
	return node


## The hull the player flies, straight from the profile the launch resolves through: the
## HUD's weapon row and the LAUNCH briefing both describe this hull, and the test derives
## its expectation from the same source instead of naming a ship.
func _active_hull() -> StringName:
	var host := _fixture_host()
	if host != null and host.has_method(&"active_ship"):
		return StringName(host.call(&"active_ship"))
	return &""


## The SHIPYARD's own selection (its active ship by default). Falls back to the profile when
## the panel has not resolved one, so the expectation always names a hull the grid could
## have been built from.
func _panel_hull(panel: Control) -> StringName:
	var hull := StringName(panel.get(&"_selected_id"))
	if hull != &"":
		return hull
	return _active_hull()


## How many non-gap cells `hull` carries, which is 08 section 3's Total: the sum of
## `ShipFit.grid_counts` (the grid never counts a gap).
func _slot_count(hull: StringName) -> int:
	var total := 0
	for count: Variant in FitData.grid_counts(hull).values():
		total += int(count)
	return total


func _engines(hull: StringName) -> int:
	return int(FitData.grid_counts(hull).get(&"engines", 0))


func _weapon_count(hull: StringName) -> int:
	return int(FitData.grid_counts(hull).get(&"weapons", 0))


## One comparison number: the catalogue's own field, or the hull's 08 section 3 count for the
## two keys no catalogue row carries.
func _stat_value(hull: StringName, key: StringName) -> int:
	if key == &"engines":
		return _engines(hull)
	if key == &"slots":
		return _slot_count(hull)
	return int(Catalog.ship(hull).get(key, 0))


## The W cells `game.gd` would push for `hull`: one per `ShipFit.grid_cells` W cell, layout
## order, the first fitted with a laser and the rest empty, selectable per the pin's index
## rule. Built from `ShipFit` and `ModuleCatalog`, never from a count written here.
func _pushed_cells(hull: StringName) -> Array:
	var cells: Array = []
	for cell: Dictionary in FitData.grid_cells(hull):
		if cell[&"type"] != &"weapons":
			continue
		var index: int = int(cell[&"index"])
		var fitted: bool = index == 0
		cells.append({
			&"slot": &"weapons",
			&"index": index,
			&"module": FITTED_MODULE if fitted else &"",
			&"icon": Modules.icon_path(FITTED_MODULE) if fitted else "",
			&"fitted": fitted,
			&"selectable": index < Groups.GROUPS_MAX,
		})
	return cells


func _plate_art(plate: TextureButton) -> Vector2:
	if plate == null or plate.texture_normal == null:
		return Vector2.ZERO
	return plate.texture_normal.get_size()


func _push_art(plate: TextureButton, art: Texture2D) -> void:
	if plate == null:
		return
	plate.texture_normal = art
	plate.texture_hover = art
	plate.texture_pressed = art
	plate.texture_disabled = art
	plate.update_minimum_size()


func _huge_art() -> Texture2D:
	var art := PlaceholderTexture2D.new()
	art.size = HUGE_ART
	return art


func _icon_of(plate: TextureButton) -> TextureRect:
	if plate == null:
		return null
	return plate.get_node_or_null(^"Icon") as TextureRect


func _glyph_path(cell: Dictionary) -> String:
	var stem := String(SLOT_GLYPH_STEMS.get(cell[&"type"], ""))
	return SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem


## ---------------------------------------------------------------------------
## The guard at every site
## ---------------------------------------------------------------------------


func test_every_plate_site_sets_ignore_texture_size() -> void:
	for path: String in PLATE_SITES:
		assert_true(FileAccess.file_exists(path), "%s exists" % path)
		var source := FileAccess.get_file_as_string(path)
		assert_true(
			source.contains(PLATE_LITERAL),
			"%s carries `%s`" % [path, PLATE_LITERAL]
		)


func test_the_slot_component_keeps_its_cell_whatever_the_plate_art_is() -> void:
	var slot := SlotScene.instantiate() as SlotButton
	assert_true(slot != null, "slot_button.tscn instantiates as a SlotButton")
	_host.add_child(slot)
	assert_true(slot.ignore_texture_size, "the scene itself ignores the texture size")

	slot.configure(WEAPON_VARIATION, null, 1)
	var weapon_art: Vector2 = _plate_art(slot)
	assert_eq(slot.custom_minimum_size, WEAPON_CELL, "configure keeps the 48 px weapon cell")
	assert_eq(slot.get_combined_minimum_size(), WEAPON_CELL, "and measures 48 px")
	assert_true(weapon_art != Vector2.ZERO, "the theme plate art is attached (not a vacuous 48)")

	slot.configure(CARGO_VARIATION, null, 0)
	var cargo_art: Vector2 = _plate_art(slot)
	assert_eq(slot.custom_minimum_size, CARGO_CELL, "configure keeps the 40 px cargo cell")
	assert_eq(slot.get_combined_minimum_size(), CARGO_CELL, "and measures 40 px")
	assert_true(cargo_art != Vector2.ZERO, "the cargo plate art is attached")

	# CONTRACTS section 11: `configure_cell` states its own cell and never a number.
	slot.configure_cell(WEAPON_VARIATION, null, WEAPON_CELL)
	assert_eq(slot.custom_minimum_size, WEAPON_CELL, "configure_cell keeps the explicit 48 px cell")
	assert_eq(slot.get_combined_minimum_size(), WEAPON_CELL, "and measures 48 px")
	assert_true(_plate_art(slot) != Vector2.ZERO, "configure_cell still copies the plate art")
	var number := slot.get_node_or_null(^"Number") as Label
	assert_true(number != null, "the component still has its Number slot")
	assert_false(number.visible, "a layout cell carries no number")
	assert_eq(number.text, "", "and no number text")

	slot.configure_cell(CARGO_VARIATION, null, CARGO_CELL)
	assert_eq(slot.custom_minimum_size, CARGO_CELL, "configure_cell keeps an explicit 40 px cell")
	assert_eq(slot.get_combined_minimum_size(), CARGO_CELL, "and measures 40 px")

	_push_art(slot, _huge_art())
	assert_eq(
		slot.get_combined_minimum_size(),
		CARGO_CELL,
		"a %s plate cannot grow a cell whose size the caller stated" % HUGE_ART
	)

	print(
		"[ui_slot_layout] slot component: weapon art %s -> cell %s, cargo art %s -> cell %s"
		% [weapon_art, WEAPON_CELL, cargo_art, CARGO_CELL]
	)


## ---------------------------------------------------------------------------
## SHIPYARD: the selected hull's matrix grid and a panel that fits the frame
## ---------------------------------------------------------------------------


func test_the_hardpoint_grid_is_the_selected_hulls_matrix() -> void:
	var panel := _mount(ShipyardScene)
	assert_true(panel != null, "shipyard_panel.tscn instantiates")
	var grid: GridContainer = panel.get(&"_hardpoints")
	assert_true(grid != null, "the slot layout grid exists")
	var hull := _panel_hull(panel)
	var size := FitData.grid_size(hull)
	var cells: Array = FitData.grid_cells(hull)
	assert_true(size.x > 0, "the selected hull %s carries an 08 section 3.2 matrix" % hull)
	assert_eq(grid.get_child_count(), cells.size(), "one cell per matrix cell of %s" % hull)
	assert_eq(grid.columns, size.x, "columns = the matrix width (%d) of %s" % [size.x, hull])

	var separation: float = float(grid.get_theme_constant(&"h_separation"))
	assert_eq(separation, HARDPOINT_SEPARATION, "the documented 4 px separation")
	var plates := 0
	var gaps := 0
	for index: int in cells.size():
		var cell: Dictionary = cells[index]
		var child: Node = grid.get_child(index)
		if bool(cell[&"gap"]):
			var gap := child as Control
			assert_true(
				gap != null and not (child is TextureButton),
				"matrix cell %d is a gap drawn as an empty cell with no plate" % index
			)
			assert_eq(gap.custom_minimum_size, WEAPON_CELL, "the gap still reserves its 48 px")
			gaps += 1
			continue
		var plate := child as TextureButton
		assert_true(plate != null, "matrix cell %d (%s) is a plate" % [index, cell[&"type"]])
		assert_true(plate.ignore_texture_size, "plate %d ignores its texture size" % index)
		assert_eq(plate.custom_minimum_size, WEAPON_CELL, "plate %d keeps the 48 px cell" % index)
		assert_eq(
			plate.get_combined_minimum_size(),
			WEAPON_CELL,
			"plate %d measures 48 px (art %s)" % [index, _plate_art(plate)]
		)
		assert_true(plate.disabled, "plate %d is a display, not a control" % index)
		plates += 1
	assert_eq(gaps, cells.size() - plates, "gaps are exactly the matrix's non-slot cells")
	assert_eq(plates, _slot_count(hull), "one plate per slot cell of %s (08 section 3's Total)" % hull)

	var expected: float = float(size.x) * WEAPON_CELL.x + float(size.x - 1) * separation
	assert_eq(
		grid.get_combined_minimum_size().x,
		expected,
		"the grid is %d x 48 + %d x 4 = %.0f" % [size.x, size.x - 1, expected]
	)

	var viewport := viewport_size()
	var measured: Vector2 = panel.get_combined_minimum_size()
	print(
		"[ui_slot_layout] shipyard %s: grid %s (%d matrix cells, %d plates, %d cols), panel minimum %s, viewport %s"
		% [hull, grid.get_combined_minimum_size(), cells.size(), plates, size.x, measured, viewport]
	)
	assert_true(
		measured.x <= viewport.x,
		"the shipyard panel minimum %s must fit the %s viewport" % [measured, viewport]
	)


func test_the_shipyard_layout_glyphs_are_the_slot_types() -> void:
	var panel := _mount(ShipyardScene)
	var grid: GridContainer = panel.get(&"_hardpoints")
	var hull := _panel_hull(panel)
	var cells: Array = FitData.grid_cells(hull)
	var checked := 0
	for index: int in cells.size():
		var cell: Dictionary = cells[index]
		if bool(cell[&"gap"]):
			continue
		var plate := grid.get_child(index) as TextureButton
		assert_true(plate != null, "matrix cell %d is a plate" % index)
		var glyph := _icon_of(plate)
		assert_true(glyph != null, "cell %d carries an Icon" % index)
		var expected := _glyph_path(cell)
		assert_true(
			FileAccess.file_exists(expected),
			"the %s slot glyph %s is on disk" % [cell[&"type"], expected]
		)
		assert_true(glyph.texture != null, "cell %d draws a glyph" % index)
		assert_eq(
			glyph.texture.resource_path,
			expected,
			"cell %d (%s) draws its type's slot glyph" % [index, cell[&"type"]]
		)
		checked += 1
	assert_eq(checked, _slot_count(hull), "every slot cell of %s was checked" % hull)
	print("[ui_slot_layout] shipyard %s: %d slot glyphs checked" % [hull, checked])


## Every player hull's matrix, driven through the panel's own rebuild: the shipped grid is
## one cell per matrix cell with `columns` = the matrix width for each of the nine hulls, and
## the panel still fits the frame after the widest (the capital's five columns) is built.
func test_the_layout_grid_builds_every_hulls_matrix() -> void:
	var panel := _mount(ShipyardScene)
	var grid: GridContainer = panel.get(&"_hardpoints")
	var caption: Label = panel.get(&"_hardpoint_caption")
	var hulls: Array = FitData.SLOT_GRIDS.keys()
	assert_eq(hulls.size(), 9, "the nine player hulls carry a matrix")
	for hull: StringName in hulls:
		var size := FitData.grid_size(hull)
		var matrix: Array = FitData.grid_cells(hull)
		panel.call(&"_set_layout_grid", hull)
		assert_eq(grid.columns, size.x, "%s columns = its matrix width %d" % [hull, size.x])
		assert_eq(grid.get_child_count(), matrix.size(), "%s draws one cell per matrix cell" % hull)
		var plates := 0
		for index: int in matrix.size():
			var cell: Dictionary = matrix[index]
			var child: Node = grid.get_child(index)
			if bool(cell[&"gap"]):
				assert_true(not (child is TextureButton), "%s cell %d is a gap with no plate" % [hull, index])
				continue
			var plate := child as TextureButton
			assert_true(plate != null, "%s cell %d (%s) is a plate" % [hull, index, cell[&"type"]])
			assert_eq(plate.custom_minimum_size, WEAPON_CELL, "%s cell %d keeps the 48 px cell" % [hull, index])
			assert_eq(
				plate.get_combined_minimum_size(),
				WEAPON_CELL,
				"%s cell %d measures 48 px (art %s)" % [hull, index, _plate_art(plate)]
			)
			plates += 1
		assert_eq(plates, _slot_count(hull), "%s's plate count is 08 section 3's Total" % hull)
		assert_eq(
			caption.text,
			LAYOUT_CAPTION % [plates, _engines(hull)],
			"%s's caption describes %s and not the previous hull" % [hull, hull]
		)
		var expected: float = float(size.x) * WEAPON_CELL.x + float(size.x - 1) * HARDPOINT_SEPARATION
		assert_eq(
			grid.get_combined_minimum_size().x,
			expected,
			"%s's grid is %d x 48 + %d x 4 = %.0f" % [hull, size.x, size.x - 1, expected]
		)
		print(
			"[ui_slot_layout] %s: matrix %dx%d, columns %d, cells %d (%d plates, %d gaps), grid width %.0f"
			% [
				hull, size.x, size.y, grid.columns, matrix.size(), plates,
				matrix.size() - plates, grid.get_combined_minimum_size().x
			]
		)
	var viewport := viewport_size()
	var measured: Vector2 = panel.get_combined_minimum_size()
	assert_true(
		measured.x <= viewport.x,
		"the shipyard panel minimum %s still fits the %s viewport after the widest grid"
		% [measured, viewport]
	)
	print("[ui_slot_layout] shipyard after all nine grids: panel minimum %s, viewport %s" % [measured, viewport])


func test_the_shipyard_caption_and_stat_rows_read_the_selected_hull() -> void:
	var panel := _mount(ShipyardScene)
	var hull := _panel_hull(panel)
	var grid: GridContainer = panel.get(&"_hardpoints")
	var caption: Label = panel.get(&"_hardpoint_caption")
	assert_true(caption != null, "the layout caption exists")
	assert_eq(
		caption.text,
		LAYOUT_CAPTION % [_slot_count(hull), _engines(hull)],
		"the caption is SLOT LAYOUT + the hull's cells and engines"
	)
	assert_eq(grid.columns, FitData.grid_size(hull).x, "the caption describes this grid's hull")
	assert_eq(
		grid.get_child_count(),
		FitData.grid_cells(hull).size(),
		"and the grid was not rebuilt for another hull"
	)

	var stats: VBoxContainer = panel.get(&"_stats")
	assert_true(stats != null, "the comparison column exists")
	var cells: Dictionary = panel.get(&"_stat_cells")
	var active := _active_hull()
	for index: int in STAT_KEYS.size():
		var key := STAT_KEYS[index]
		var row := stats.get_node_or_null(NodePath("Stat%s" % String(key).to_pascal_case()))
		assert_true(row != null, "the %s stat row exists" % key)
		var caption_label := row.get_child(0) as Label
		assert_eq(caption_label.text, STAT_LABELS[index], "row %d is labelled %s" % [index, STAT_LABELS[index]])
		var pair: Array = cells.get(key, [])
		assert_eq(pair.size(), 2, "the %s row has a selected and an active cell" % key)
		assert_eq(
			String((pair[0] as Label).text),
			str(_stat_value(hull, key)),
			"the %s selected value is the selected hull's" % key
		)
		assert_eq(
			String((pair[1] as Label).text),
			str(_stat_value(active, key)),
			"the %s active value is the active hull's" % key
		)

	var payloads: Array = panel.get(&"_payloads")
	assert_eq(payloads.size(), Catalog.SHIPS.size(), "one list row per catalogue hull")
	for payload: Dictionary in payloads:
		var row: Button = payload[&"row"]
		var meta := row.find_child("Meta", true, false) as Label
		assert_true(meta != null, "the %s list row has its meta line" % payload[&"id"])
		var ship_id: StringName = payload[&"id"]
		assert_eq(
			meta.text,
			META_FORMAT % [int(Catalog.ship(ship_id).get(&"hull", 0)), _slot_count(ship_id)],
			"the %s meta reads hull + slot cells" % ship_id
		)
	print(
		"[ui_slot_layout] shipyard %s: caption '%s', %d stat rows, %d list metas"
		% [hull, caption.text, STAT_KEYS.size(), payloads.size()]
	)


func test_oversized_plate_art_cannot_grow_the_shipyard_panel() -> void:
	var panel := _mount(ShipyardScene)
	var grid: GridContainer = panel.get(&"_hardpoints")
	var hull := _panel_hull(panel)
	var size := FitData.grid_size(hull)
	var before: Vector2 = panel.get_combined_minimum_size()
	var art := _huge_art()
	for child: Node in grid.get_children():
		_push_art(child as TextureButton, art)
	var grid_after: Vector2 = grid.get_combined_minimum_size()
	var after: Vector2 = panel.get_combined_minimum_size()
	var expected: float = (
		float(size.x) * WEAPON_CELL.x
		+ float(size.x - 1) * HARDPOINT_SEPARATION
	)
	print(
		"[ui_slot_layout] shipyard %s with %s art: grid %s, panel %s (before %s)"
		% [hull, HUGE_ART, grid_after, after, before]
	)
	assert_eq(grid_after.x, expected, "a %s plate cannot widen one 48 px cell" % HUGE_ART)
	assert_eq(after, before, "a %s plate cannot move the panel minimum" % HUGE_ART)


## ---------------------------------------------------------------------------
## LAUNCH: the nine brief rows, the 5 x 40 cargo strip and a panel that fits the frame
## ---------------------------------------------------------------------------


func test_the_launch_brief_rows_are_the_nine_pinned_rows() -> void:
	var panel := _mount(LaunchScene)
	assert_true(panel != null, "launch_panel.tscn instantiates")
	var rows: VBoxContainer = panel.get(&"_brief_rows")
	assert_true(rows != null, "the brief row column exists")
	assert_eq(rows.get_child_count(), BRIEF_ROWS.size(), "%d brief rows" % BRIEF_ROWS.size())
	var values: Dictionary = panel.get(&"_brief_values")
	for index: int in BRIEF_ROWS.size():
		var spec: Dictionary = BRIEF_ROWS[index]
		var line := rows.get_child(index) as HBoxContainer
		assert_true(line != null, "brief row %d is a row" % index)
		assert_eq(
			line.name,
			"Brief%s" % String(spec[&"key"]).to_pascal_case(),
			"brief row %d is %s" % [index, spec[&"key"]]
		)
		var caption := line.get_child(0) as Label
		assert_eq(caption.text, String(spec[&"label"]), "brief row %d is labelled %s" % [index, spec[&"label"]])
		assert_true(values.has(spec[&"key"]), "brief row %d has a value label" % index)
	var hull := _active_hull()
	assert_eq(
		String((values[&"engines"] as Label).text),
		str(_engines(hull)),
		"ENGINES is the active hull's own E count"
	)
	assert_eq(
		String((values[&"slots"] as Label).text),
		str(_slot_count(hull)),
		"SLOT CELLS is the active hull's own slot count"
	)
	assert_eq(
		String((values[&"hardpoints"] as Label).text),
		str(int(Catalog.ship(hull).get(&"hardpoints", 0))),
		"HARDPOINTS is still the catalogue's W count"
	)
	print(
		"[ui_slot_layout] launch %s: %d brief rows, ENGINES %s, SLOT CELLS %s"
		% [hull, rows.get_child_count(), (values[&"engines"] as Label).text, (values[&"slots"] as Label).text]
	)


func test_the_cargo_strip_is_five_40px_cells() -> void:
	var panel := _mount(LaunchScene)
	assert_true(panel != null, "launch_panel.tscn instantiates")
	var strip: HBoxContainer = panel.get(&"_cargo_slots")
	assert_true(strip != null, "the cargo strip exists")
	assert_eq(strip.get_child_count(), CARGO_CELLS, "five cargo plates")

	var separation: float = float(strip.get_theme_constant(&"separation"))
	assert_eq(separation, CARGO_SEPARATION, "the documented 6 px separation")
	for index: int in strip.get_child_count():
		var plate := strip.get_child(index) as TextureButton
		assert_true(plate != null, "cargo plate %d is a TextureButton" % (index + 1))
		assert_true(plate.ignore_texture_size, "cargo plate %d ignores its texture size" % (index + 1))
		assert_eq(plate.custom_minimum_size, CARGO_CELL, "cargo plate %d keeps the 40 px cell" % (index + 1))
		assert_eq(
			plate.get_combined_minimum_size(),
			CARGO_CELL,
			"cargo plate %d measures 40 px (art %s)" % [(index + 1), _plate_art(plate)]
		)

	var expected: float = (
		float(CARGO_CELLS) * CARGO_CELL.x
		+ float(CARGO_CELLS - 1) * separation
	)
	assert_eq(strip.get_combined_minimum_size().x, expected, "the strip is 5 x 40 + 4 x 6 = 224")

	var viewport := viewport_size()
	var measured: Vector2 = panel.get_combined_minimum_size()
	var art: Vector2 = _plate_art(strip.get_child(0) as TextureButton)
	assert_true(measured.x <= viewport.x, "the launch panel minimum %s must fit the %s viewport" % [measured, viewport])
	var launch: Button = panel.get(&"_launch_button")
	assert_true(launch != null, "the LAUNCH button exists")
	print(
		"[ui_slot_layout] launch: strip %s (art %s), panel minimum %s, LaunchButton minimum %s, viewport %s"
		% [strip.get_combined_minimum_size(), art, measured, launch.get_combined_minimum_size(), viewport]
	)
	assert_true(
		launch.get_combined_minimum_size().x <= viewport.x,
		"and the LAUNCH button stays inside the frame, not at x = 3178"
	)


func test_oversized_plate_art_cannot_grow_the_launch_panel() -> void:
	var panel := _mount(LaunchScene)
	var strip: HBoxContainer = panel.get(&"_cargo_slots")
	var before: Vector2 = panel.get_combined_minimum_size()
	var art := _huge_art()
	for child: Node in strip.get_children():
		_push_art(child as TextureButton, art)
	var strip_after: Vector2 = strip.get_combined_minimum_size()
	var after: Vector2 = panel.get_combined_minimum_size()
	var expected: float = (
		float(CARGO_CELLS) * CARGO_CELL.x
		+ float(CARGO_CELLS - 1) * CARGO_SEPARATION
	)
	print(
		"[ui_slot_layout] launch with %s art: strip %s, panel %s (before %s)"
		% [HUGE_ART, strip_after, after, before]
	)
	assert_eq(strip_after.x, expected, "a %s plate cannot widen one 40 px cell" % HUGE_ART)
	assert_eq(after, before, "a %s plate cannot move the panel minimum" % HUGE_ART)


## ---------------------------------------------------------------------------
## The in-flight HUD, which paints the same plates from the launched hull
## ---------------------------------------------------------------------------


func test_the_hud_slot_cells_keep_their_cell_sizes() -> void:
	var hud := _mount(HudScene)
	assert_true(hud != null, "hud.tscn instantiates")
	var hull := _active_hull()
	var count := _weapon_count(hull)
	assert_true(count > 0, "the active hull %s carries at least one W cell" % hull)
	var pushed := _pushed_cells(hull)
	assert_eq(pushed.size(), count, "the pushed cell set is one per W cell of %s" % hull)
	hud.call(&"set_hull_slots", hull, pushed)

	var weapons: Array = hud.get(&"_weapon_slots")
	assert_eq(weapons.size(), count, "%d weapon cells, read from ShipFit not a literal" % count)
	var grid: GridContainer = hud.get(&"_weapon_grid")
	assert_eq(
		grid.columns,
		mini(count, Groups.GROUPS_MAX),
		"columns = min(%d, %d)" % [count, Groups.GROUPS_MAX]
	)
	var readback: Array = hud.call(&"hull_slots")
	assert_eq(readback.size(), pushed.size(), "hull_slots() reads the pushed cells back")
	var weapon_art := Vector2.ZERO
	for index: int in weapons.size():
		var slot := weapons[index] as SlotButton
		assert_true(slot != null, "weapon cell %d is a SlotButton" % (index + 1))
		assert_true(slot.ignore_texture_size, "weapon cell %d ignores its texture size" % (index + 1))
		assert_eq(slot.custom_minimum_size, WEAPON_CELL, "weapon cell %d keeps 48 px" % (index + 1))
		assert_eq(slot.get_combined_minimum_size(), WEAPON_CELL, "weapon cell %d measures 48 px" % (index + 1))
		weapon_art = _plate_art(slot)

	hud.call(&"_ensure_cargo_cells", HUD_CARGO_CELLS)
	var cells: Array = hud.get(&"_cargo_cells")
	assert_eq(cells.size(), HUD_CARGO_CELLS, "the cargo grid builds one cell per slot")
	var cargo_art := Vector2.ZERO
	for index: int in cells.size():
		var cell := cells[index] as SlotButton
		assert_true(cell != null, "cargo cell %d is a SlotButton" % (index + 1))
		assert_true(cell.ignore_texture_size, "cargo cell %d ignores its texture size" % (index + 1))
		assert_eq(cell.custom_minimum_size, CARGO_CELL, "cargo cell %d keeps 40 px" % (index + 1))
		assert_eq(cell.get_combined_minimum_size(), CARGO_CELL, "cargo cell %d measures 40 px" % (index + 1))
		cargo_art = _plate_art(cell)

	_push_art(weapons[0] as TextureButton, _huge_art())
	assert_eq(
		(weapons[0] as SlotButton).get_combined_minimum_size(),
		WEAPON_CELL,
		"a %s plate cannot grow a HUD weapon cell" % HUGE_ART
	)

	print(
		"[ui_slot_layout] hud %s: %d x %s (art %s), columns %d, and %d x %s (art %s)"
		% [hull, count, WEAPON_CELL, weapon_art, grid.columns, HUD_CARGO_CELLS, CARGO_CELL, cargo_art]
	)


func test_the_hud_grid_wraps_and_marks_cells_past_the_group_count() -> void:
	var hud := _mount(HudScene)
	# The pin's own wrap case is the capital: its W count is more than the input map can
	# select, so the row wraps at `GROUPS_MAX` and the tail is drawn not selectable. Both
	# numbers come from `ShipFit` and `weapons.gd`, never from the test.
	var hull := &"ship_destroyer"
	var count := _weapon_count(hull)
	var pushed := _pushed_cells(hull)
	assert_eq(pushed.size(), count, "%s pushes one cell per W cell" % hull)
	assert_true(count > Groups.GROUPS_MAX, "%s has more W cells than selectable groups" % hull)
	hud.call(&"set_hull_slots", hull, pushed)

	var grid: GridContainer = hud.get(&"_weapon_grid")
	assert_eq(grid.columns, Groups.GROUPS_MAX, "a %d-cell fit wraps at %d columns" % [count, Groups.GROUPS_MAX])
	var weapons: Array = hud.get(&"_weapon_slots")
	assert_eq(weapons.size(), count, "every W cell is still drawn")
	for index: int in weapons.size():
		var slot := weapons[index] as SlotButton
		var selectable: bool = index < Groups.GROUPS_MAX
		assert_eq(
			slot.disabled,
			not selectable,
			"cell %d is %s" % [index, "selectable" if selectable else "marked not selectable"]
		)
		var icon := _icon_of(slot)
		assert_true(icon != null, "cell %d has an icon" % index)
		var expected := String(pushed[index][&"icon"])
		if expected.is_empty():
			expected = SLOT_GLYPH_WEAPON
		assert_eq(icon.texture.resource_path, expected, "cell %d draws %s" % [index, expected])
	print(
		"[ui_slot_layout] hud %s: %d cells, columns %d, %d not selectable"
		% [hull, count, grid.columns, count - Groups.GROUPS_MAX]
	)
