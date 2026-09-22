@tool
extends McpTestSuite
## Suite p2b_fitting_panel: the FITTING pane (STATION_HUB section 5.3's 2026-09-22 amendment,
## CONTRACTS section 13) and the rail swap that retired UPGRADES.
##
## Covers the SLOT LAYOUT grid (the active hull's matrix, gaps included, the shipyard's own
## recipe), the OWNED MODULES rows (one per owned id, `FIT_SLOT_KEYS` then catalogue order, the
## `SLOT <TYPE> · DRAW <n>` meta and `OWNED ×<n>`), the three ACTION states, the per-cell
## install, the swap that hands the displaced module back, the mandatory-cell refusal with its
## pinned wording, the power meter in its idle, candidate and over-budget forms with
## `fit_legal`'s own numbers, the three pinned refusals, the selection line, the empty state,
## the focus order, and that the pane writes only through the two composed profile calls.
##
## The pane is mounted from the shipped scene with the shipped theme and driven through the
## wiring the station shell itself uses - a row's own `pressed` signal for an action
## (`ui/screens/station.gd:_connect_panel`) and `profile_changed` -> `refresh_profile` for the
## refresh (`_on_profile_changed`) - so nothing here re-implements the panel's dispatch. Every
## number is read off the pane (a label's text, a plate's cell size, the meter) or off the
## profile / `ShipFit` / `ModuleCatalog` the pane reads, never off a literal this suite invents.
##
## The profile is the shipped autoload, borrowed the way `test_p2b1_outfitting_panel.gd` borrows
## it: `save_path` is repointed at a scratch file before the first mutation, the fields the
## fixture writes are handed back in `suite_teardown`, and the store is flushed while the
## scratch path is still in place, so the owner's `user://profile.cfg` is never written
## (probe hygiene L17).

const PanelScene := preload("res://ui/station/fitting_panel.tscn")
const PanelScript := preload("res://ui/station/fitting_panel.gd")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://test_p2b_fitting_panel.cfg"

## 08 section 3.2's two hulls this suite measures: the Vanguard (`.WW.`, `HSCB`, `HWU.`,
## `.EP.`: 11 cells, 5 gaps) is the default, the Lancer (`.WW.`, `HSCB`, `.EP.`) the
## over-budget case - its 08 section 2 power output is 6 against two W cells.
const HULL: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
const NPC_HULL: StringName = &"ship_swarmer"

const WEAPON_SLOT: StringName = &"weapons"
const SHIELD_SLOT: StringName = &"shields"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"

const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const PLASMA: StringName = &"w_plasma"
const RAILGUN: StringName = &"w_railgun"
const STANDARD_ENGINE: StringName = &"e_std"
const ION: StringName = &"e_ion"
const LIGHT_PLATE: StringName = &"h_plate_light"
const DEEP_SCANNER: StringName = &"c_scanner"
const CARGO: StringName = &"u_cargo"
const REACTOR_MK2: StringName = &"p_mk2"

const START_CREDITS := 10000
const PLATE_SIZE := 48.0
const PLATE_ICON_INSET := 6.0
const PLATE_SEPARATION := 4
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"disabled"]

## 09 section 1's shipped slot glyph per slot-type key, held here (not read off the panel) so
## the grid's faces are measured against the document's own stems.
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

## STATION_HUB section 5.3's pinned wordings, transcribed here (not read off the panel) so a
## drift in either direction is a red assertion.
const WORDING_SELECT := "SELECT A CELL"
const WORDING_MANDATORY := "MANDATORY CELL — SWAP ONLY, NEVER EMPTY"
const WORDING_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"
const WORDING_EMPTY_ROW := "NO MODULES OWNED · BUY THEM IN OUTFITTING"
const WORDING_METER_OVERLOAD := "%d / %d PWR — OVER BY %d"
const WORDING_METER_IDLE := "PWR %d / %d"
const WORDING_METER_CANDIDATE := "PWR %d / %d · CANDIDATE %d / %d"
const WORDING_METER_OVER := " — OVER BY %d"
const WORDING_SELECTION := "%s%d · %s · OWNED ×%d"
const WORDING_META := "SLOT %s · DRAW %d"
const WORDING_OWNED := "OWNED ×%d"
const WORDING_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}


func suite_name() -> String:
	return "p2b_fitting_panel"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to mount the pane")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the pane's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore the
	## real one, so no dirty flag and no running timer carries a test's account home.
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account(HULL, {}, true)
	_host = Control.new()
	_host.name = "FittingHost"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: `hull` active and owned, an empty inventory
## unless the test asks for one, and `with_fit` to seed 09 section 9's delivered fit (the fit
## `_resolved_fit` resolves and the transactions write against - W1's own fixture shape).
func _seed_account(hull: StringName, modules: Dictionary, with_fit: bool) -> void:
	var owned: Array[StringName] = [hull]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", _records(modules))
	if with_fit:
		_profile.call(&"set_fit", hull, ShipFit.standard_fit(hull))


## The inventory shape `PlayerProfile.add_module` writes: an id keyed record carrying a
## `base_id` (the id itself for a common module) and a `count`.
func _records(modules: Dictionary) -> Dictionary:
	var records: Dictionary = {}
	for module_id: Variant in modules:
		records[String(module_id)] = {
			"base_id": String(module_id), "count": int(modules[module_id])
		}
	return records


## The runner calls every test from inside its own `_ready`, so the root viewport is still busy
## adding the runner scene and `root.add_child(...)` fails. The profile autoload entered the
## tree before the main scene, so it hosts the fixture (suite ui_slot_layout's own reason).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _viewport_size() -> Vector2:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(width, height)


## Mount the shipped pane the way the shell does: into a sized host, with the shell's two
## wirings (the pane's status strip up, the profile's keys down).
func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


## ------------------------------------------------------------------------ pane readers


func _grid(panel: Control) -> GridContainer:
	return panel.get_node("%SlotLayoutGrid") as GridContainer


func _row(panel: Control, module_id: StringName) -> Button:
	var rows := panel.get_node("%ModuleRows") as VBoxContainer
	for child: Node in rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _row_children(panel: Control) -> Array[Node]:
	var rows := panel.get_node("%ModuleRows") as VBoxContainer
	return rows.get_children()


func _plate(panel: Control, token: String, index: int) -> Button:
	return _grid(panel).get_node_or_null(NodePath("Slot%s%02d" % [token, index])) as Button


func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


func _press(panel: Control, module_id: StringName) -> void:
	var row := _row(panel, module_id)
	assert_true(row != null, "%s has a row to press" % module_id)
	if row != null:
		row.pressed.emit()


func _press_remove(panel: Control) -> void:
	var remove := panel.get_node("%RemoveButton") as Button
	assert_false(remove.disabled, "the per-cell REMOVE is offered")
	remove.pressed.emit()


func _meter(panel: Control) -> String:
	return panel.call(&"meter_text")


func _footer(panel: Control) -> String:
	return panel.call(&"footer_text")


func _danger_override(label: Label) -> bool:
	return label.has_theme_color_override(&"font_color")


func _label_colour(panel: Control, node_path: String) -> Color:
	var label := panel.get_node(node_path) as Label
	return label.get_theme_color(&"font_color")


func _token(panel: Control, token: StringName) -> Color:
	return panel.get_theme_color(token, &"Tokens")


## -------------------------------------------------------------------- profile readers


func _fit(hull: StringName) -> Dictionary:
	return _profile.call(&"fit_for", hull)


func _cells(hull: StringName, slot_key: StringName) -> Array:
	return _fit(hull)[slot_key]


func _power(hull: StringName, fit: Dictionary) -> Dictionary:
	return ShipFit.fit_legal(hull, fit)[&"power"]


func _owned(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _read_source(path: String) -> String:
	assert_true(FileAccess.file_exists(path), "%s is readable" % path)
	return FileAccess.get_file_as_string(path)


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------------------- the rail swap (section 5.3)


## FITTING takes the retired UPGRADES entry: the same rail position, label word, icon path and
## tint, and the retired pane's two files are gone. Measured both on the script's own tables and
## on the assembled shell, so the entry the player sees is the one asserted.
func test_the_rail_entry_is_fitting_and_the_upgrades_pane_is_gone() -> void:
	## FITTING is the sixth rail entry since AUCTION took index 3 (STATION_HUB section
	## 5.10's S3 amendment, "directly after EXCHANGE"): the retired UPGRADES position is
	## still the one it took, shifted by that insertion.
	var module := 5
	assert_eq(StationScript.MODULE_LABELS[module], "FITTING", "the sixth rail entry is FITTING")
	assert_eq(StationScript.MODULE_FILES[module], "fitting", "and it loads the FITTING pane")
	assert_eq(
		StationScript.MODULE_ICONS[module],
		"res://assets/icons/equip/icon_equip_generator.png",
		"and keeps the retired entry's icon"
	)
	assert_eq(StationScript.MODULE_TINTED[module], false, "and its untinted treatment")
	assert_eq(
		StationScript.MODULE_BEDS[module],
		&"amb_station_noise_loop_01",
		"and its ambience (STATION_HUB section 11)"
	)
	assert_false(StationScript.MODULE_FILES.has("upgrades"), "no rail entry loads UPGRADES")
	assert_false(StationScript.MODULE_LABELS.has("UPGRADES"), "and no label reads UPGRADES")
	assert_false(
		ResourceLoader.exists("res://ui/station/upgrades_panel.tscn"),
		"the retired pane scene is deleted"
	)
	assert_false(
		ResourceLoader.exists("res://ui/station/upgrades_panel.gd"),
		"and its script with it"
	)
	assert_true(
		ResourceLoader.exists("res://ui/station/fitting_panel.tscn"), "FITTING's scene ships"
	)
	## The assembled shell: eight entries, the sixth FITTING, and one pane per module with no
	## Upgrades pane among them.
	var screen := StationScene.instantiate() as Control
	_host.add_child(screen)
	var buttons := screen.get_node("%ModuleButtons") as VBoxContainer
	assert_eq(
		buttons.get_child_count(),
		StationScript.MODULE_LABELS.size(),
		"one rail entry per module"
	)
	var entry := buttons.get_child(module) as Button
	assert_eq(entry.name, "FittingEntry", "the sixth entry is named for its label")
	var label := _first_label(entry)
	assert_eq(label.text, "FITTING", "and carries the FITTING label")
	var icon := _first_icon(entry)
	assert_true(icon != null, "the entry carries an icon")
	if icon != null:
		assert_eq(
			icon.texture.resource_path,
			"res://assets/icons/equip/icon_equip_generator.png",
			"the retired entry's own icon, not new art"
		)
	var host := screen.get_node("%HostMargin") as MarginContainer
	assert_true(
		host.get_node_or_null(^"Fitting") != null, "the shell loaded the FITTING pane"
	)
	assert_true(
		host.get_node_or_null(^"Upgrades") == null, "and no UPGRADES pane exists"
	)
	screen.free()


func _first_label(node: Node) -> Label:
	for child: Node in node.find_children("*", "Label", true, false):
		return child as Label
	return null


func _first_icon(node: Node) -> TextureRect:
	for child: Node in node.find_children("*", "TextureRect", true, false):
		return child as TextureRect
	return null


## ------------------------------------------------------------------ the SLOT LAYOUT grid


## The grid is the active hull's own 08 section 3.2 matrix: one child per matrix cell, gaps
## included, `columns` = the matrix width, every cell exactly 48 px, a gap an empty `Control`
## and a slot cell a named plate carrying its type's slot glyph - and, unlike the shipyard's
## display, selectable.
func test_the_grid_renders_the_active_hulls_cells_with_gaps() -> void:
	var panel := _mount()
	assert_eq(panel.call(&"active_hull"), HULL, "the grid reads the active hull")
	var cells: Array = ShipFit.grid_cells(HULL)
	assert_true(cells.size() > 0, "the Vanguard has a matrix")
	var grid := _grid(panel)
	assert_eq(grid.get_child_count(), cells.size(), "one child per matrix cell, gaps included")
	assert_eq(grid.columns, ShipFit.grid_size(HULL).x, "columns is the matrix width")
	assert_eq(
		grid.get_theme_constant(&"h_separation"), PLATE_SEPARATION, "the row gap is the recipe's"
	)
	assert_eq(
		grid.get_theme_constant(&"v_separation"), PLATE_SEPARATION, "and so is the column gap"
	)
	var gaps := 0
	var plates := 0
	for index in cells.size():
		var cell: Dictionary = cells[index]
		var child := grid.get_child(index) as Control
		assert_eq(
			child.custom_minimum_size, Vector2(PLATE_SIZE, PLATE_SIZE), "cell %d is 48 px" % index
		)
		if bool(cell[&"gap"]):
			gaps += 1
			assert_false(child is Button, "gap %d carries no plate" % index)
			continue
		plates += 1
		var plate := child as Button
		assert_true(plate != null, "cell %d is a plate" % index)
		if plate == null:
			continue
		assert_eq(
			plate.name,
			"Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])],
			"cell %d is named for its token and layout index" % index
		)
		assert_eq(
			plate.theme_type_variation, PLATE_VARIATION, "cell %d is a SlotButtonWeapon plate" % index
		)
		assert_false(plate.disabled, "cell %d is selectable, not a display" % index)
		assert_eq(plate.focus_mode, Control.FOCUS_ALL, "cell %d keeps the ring" % index)
		var glyph := plate.get_node_or_null(^"Icon") as TextureRect
		assert_true(glyph != null, "cell %d carries its slot glyph" % index)
		if glyph == null:
			continue
		var stem: String = SLOT_GLYPH_STEMS.get(cell[&"type"], "")
		assert_eq(
			glyph.texture.resource_path,
			SLOT_GLYPH_DIR + "icon_slot_%s.svg" % stem,
			"cell %d draws its type's slot glyph" % index
		)
		assert_eq(
			glyph.custom_minimum_size,
			Vector2(
				PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0
			),
			"cell %d insets its glyph 6 px" % index
		)
	assert_true(gaps > 0, "the Vanguard's matrix has gaps")
	assert_eq(
		plates,
		_count_cells(HULL),
		"the plate count is the hull's own cell count (gaps are not cells)"
	)
	var caption := panel.get_node("%SlotCaption") as Label
	assert_eq(
		caption.text,
		WORDING_CAPTION % [plates, int(ShipFit.grid_counts(HULL)[ENGINE_SLOT])],
		"the caption names the hull's cells and engines"
	)


## The FITTING grid is the shipyard's recipe: the same cell count, the same gap/plate split,
## the same 48 px cells, the same glyph per cell, the same plate art out of the theme's own
## `SlotButtonWeapon` item and the same caption - so the two grids render identically.
func test_the_grid_is_the_shipyards_own_recipe() -> void:
	var panel := _mount()
	var shipyard := ShipyardScene.instantiate() as Control
	_host.add_child(shipyard)
	var grid := _grid(panel)
	var yard := shipyard.get_node("%HardpointSlots") as GridContainer
	assert_eq(
		grid.get_child_count(), yard.get_child_count(), "the two grids carry the same cells"
	)
	assert_eq(grid.columns, yard.columns, "and the same columns")
	assert_eq(
		grid.get_theme_constant(&"h_separation"),
		yard.get_theme_constant(&"h_separation"),
		"and the same separation"
	)
	for index in grid.get_child_count():
		var mine := grid.get_child(index) as Control
		var theirs := yard.get_child(index) as Control
		assert_eq(
			mine is Button, theirs is TextureButton, "cell %d is a plate in both" % index
		)
		assert_eq(
			mine.custom_minimum_size, theirs.custom_minimum_size, "cell %d is 48 px in both" % index
		)
		if not mine is Button:
			continue
		var glyph := mine.get_node_or_null(^"Icon") as TextureRect
		var yard_glyph := theirs.get_node_or_null(^"Icon") as TextureRect
		assert_true(glyph != null and yard_glyph != null, "cell %d carries a glyph in both" % index)
		if glyph != null and yard_glyph != null:
			assert_eq(
				glyph.texture.resource_path,
				yard_glyph.texture.resource_path,
				"cell %d draws the same glyph file" % index
			)
		## The plate art: the shipyard copies the theme's texture onto its TextureButton, the
		## FITTING cell draws the same theme item, so the two must be one resource.
		var yard_plate := theirs as TextureButton
		for state: StringName in PLATE_STATES:
			if not mine.has_theme_stylebox(state, PLATE_VARIATION):
				continue
			var box := mine.get_theme_stylebox(state, PLATE_VARIATION)
			if not box is StyleBoxTexture:
				continue
			assert_eq(
				(box as StyleBoxTexture).texture,
				_yard_texture(yard_plate, state),
				"cell %d reads the theme's %s plate art" % [index, state]
			)
	var caption := panel.get_node("%SlotCaption") as Label
	var yard_caption := shipyard.get_node("%HardpointCaption") as Label
	assert_eq(caption.text, yard_caption.text, "the two captions read the same numbers")
	shipyard.free()


func _yard_texture(plate: TextureButton, state: StringName) -> Texture2D:
	match state:
		&"normal":
			return plate.texture_normal
		&"hover":
			return plate.texture_hover
		&"pressed":
			return plate.texture_pressed
		&"disabled":
			return plate.texture_disabled
	return null


## A hull with no matrix (an NPC id) draws no cells and leaves the caption empty, exactly as the
## shipyard's display does.
func test_an_npc_hull_draws_no_cells() -> void:
	_seed_account(NPC_HULL, {}, false)
	var panel := _mount()
	assert_eq(_grid(panel).get_child_count(), 0, "no matrix, no cells")
	assert_eq((panel.get_node("%SlotCaption") as Label).text, "", "and no caption")
	assert_eq(panel.call(&"meter_text"), WORDING_METER_IDLE % [0, 0], "the meter still reads")


## ------------------------------------------------------------- the OWNED MODULES rows


## One row per owned module id, ordered by `ShipFit.FIT_SLOT_KEYS` and then catalogue order,
## with the catalogue's name, the `SLOT <TYPE> · DRAW <n>` meta and `OWNED ×<n>`.
func test_the_owned_rows_are_the_inventory_in_pin_order() -> void:
	_seed_account(
		HULL,
		{
			CANNON: 2, LASER: 1, DEEP_SCANNER: 1, ION: 1, REACTOR_MK2: 1,
			LIGHT_PLATE: 1, CARGO: 1,
		},
		true
	)
	var panel := _mount()
	## The expected order is re-derived here: `FIT_SLOT_KEYS` first, catalogue order inside a
	## group, kept when the inventory holds the id.
	var owned: Dictionary = {
		CANNON: 2, LASER: 1, DEEP_SCANNER: 1, ION: 1, REACTOR_MK2: 1, LIGHT_PLATE: 1, CARGO: 1,
	}
	var expected: Array[StringName] = []
	for slot_key: StringName in ShipFit.FIT_SLOT_KEYS:
		for module_id: StringName in ModuleData.MODULES:
			if not owned.has(module_id):
				continue
			var slot: StringName = ModuleData.slot_of(module_id)
			if (slot if slot != &"engine" else &"engines") == slot_key:
				expected.append(module_id)
	assert_eq(expected.size(), owned.size(), "every owned id lands in a group")
	assert_eq(panel.call(&"module_row_ids"), expected, "the rows are in the pin's order")
	for module_id: StringName in expected:
		var row := _row(panel, module_id)
		assert_true(row != null, "%s has a row" % module_id)
		if row == null:
			continue
		var module_row: Dictionary = ModuleData.module(module_id)
		var title := row.find_child("Title", true, false) as Label
		assert_eq(title.text, String(module_row[&"name"]), "%s's title is the catalogue's" % module_id)
		var meta := row.find_child("Meta", true, false) as Label
		assert_eq(
			meta.text,
			WORDING_META % [String(module_row[&"slot"]).to_upper(), int(module_row[&"draw"])],
			"%s's meta is its slot and draw" % module_id
		)
		assert_eq(
			_cell_text(row, "Owned"),
			WORDING_OWNED % int(owned[module_id]),
			"%s's OWNED cell is its inventory count" % module_id
		)
		assert_eq(
			_cell_text(row, "Action"), WORDING_SELECT, "%s's ACTION waits for a cell" % module_id
		)
	## An id the catalogue does not ship never becomes a row, and neither does a zero count.
	_profile.set(
		&"_modules",
		_records({CANNON: 1, &"upgrade_engine": 3, &"w_laser": 0})
	)
	_panel.call(&"refresh_profile", &"modules")
	assert_eq(panel.call(&"module_row_ids"), [CANNON] as Array[StringName],
		"only catalogue ids with a count render")


## The empty state: one disabled row carrying the pin's own words (STATION_HUB section 5.3).
func test_the_empty_state_is_one_disabled_pinned_row() -> void:
	_seed_account(HULL, {}, true)
	var panel := _mount()
	var rows := _row_children(panel)
	assert_eq(rows.size(), 1, "one row")
	var row := rows[0] as Button
	assert_true(row != null, "the empty state is a row")
	assert_true(row.disabled, "and it is disabled")
	assert_false(row.focus_mode == Control.FOCUS_ALL, "and it takes no focus")
	var label_nodes := row.find_children("*", "Label", true, false)
	assert_true(label_nodes.size() > 0, "the empty row carries its wording")
	var label := label_nodes[0] as Label
	assert_eq(label.text, WORDING_EMPTY_ROW, "with the pin's own wording")
	assert_eq(panel.call(&"module_row_ids"), [] as Array[StringName], "and no module rows")
	assert_eq((panel.get_node("%OwnedCaption") as Label).text, PanelScript.OWNED_CAPTION,
		"the section caption still names the section")


## ------------------------------------------------------------------- the ACTION states


## `FIT` on an empty cell of the module's own type, `SWAP` on a cell that already holds one, and
## `SELECT A CELL` while no cell of that type is selected - the pin's three states.
func test_the_action_states_are_fit_swap_and_select_a_cell() -> void:
	_seed_account(HULL, {CANNON: 1, ION: 1, LASER: 1}, true)
	var panel := _mount()
	for module_id: StringName in [CANNON, ION, LASER]:
		assert_eq(
			panel.call(&"module_action", module_id), WORDING_SELECT, "nothing selected yet"
		)
	## W2 is empty in the delivered fit, W1 holds the laser; the E cell holds the standard drive.
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 1), "W2 is a cell of the Vanguard")
	assert_eq(panel.call(&"module_action", CANNON), "FIT", "an empty W cell offers FIT")
	assert_eq(panel.call(&"module_action", LASER), "FIT", "a second laser fits too (09 section 4 item 4)")
	assert_eq(
		panel.call(&"module_action", ION), WORDING_SELECT, "an engine row is not a W cell's module"
	)
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 0), "W1 is the fitted cell")
	assert_eq(panel.call(&"module_action", CANNON), "SWAP", "a filled W cell offers SWAP")
	assert_eq(panel.call(&"module_action", LASER), "SWAP", "and so does the module that is in it")
	assert_true(panel.call(&"select_cell", ENGINE_SLOT, 0), "the E cell is selectable")
	assert_eq(panel.call(&"module_action", ION), "SWAP", "the mandatory cell swaps, never empties")
	## A press in the SELECT A CELL state writes nothing at all.
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	var before := _fit(HULL)
	_press(panel, ION)
	assert_eq(_fit(HULL), before, "the refused-type press wrote no fit")
	assert_eq(_owned(ION), 1, "and took no module")
	assert_eq(_footer(panel), WORDING_SELECT, "and said so")
	assert_eq(_last_status(), WORDING_SELECT, "in the shell's strip too")


## ------------------------------------------------------------------ the two transactions


## A per-cell install lands on the cell it was given and leaves every other cell alone.
func test_a_per_cell_install_lands_on_the_cell_it_was_given() -> void:
	_seed_account(HULL, {CANNON: 1}, true)
	var panel := _mount()
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 1), "W2 is selected")
	_press(panel, CANNON)
	var weapons := _cells(HULL, WEAPON_SLOT)
	assert_eq(weapons.size(), 3, "the Vanguard keeps its three W cells")
	assert_eq(weapons[0], String(LASER), "the cell that was not named is untouched")
	assert_eq(weapons[1], String(CANNON), "the named cell took the module")
	assert_eq(weapons[2], "", "and the third stays empty")
	assert_eq(_owned(CANNON), 0, "the cannon left the inventory")
	assert_eq(_owned(LASER), 0, "and no laser came back")
	## The selection survives the transaction, and the footer line reads the new module.
	assert_eq(
		panel.call(&"selected_cell"),
		{&"type": WEAPON_SLOT, &"token": "W", &"index": 1},
		"the cell stays selected across its own install"
	)
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % ["W", 2, String(ModuleData.module(CANNON)[&"name"]).to_upper(), 0],
		"and the footer names the module now in it"
	)


## R1 MED-1: the pane's preview and the profile's commit on a hull the account holds no fit
## for. The launch flies 09 section 9's delivered fit, so the pane previews that fit - the
## Fighter's W1 reads its delivered laser - and the first install through the pane succeeds and
## leaves a launchable fit, never the `REFUSED · FIT ILLEGAL` the two reads used to disagree on.
func test_an_unfit_hulls_first_install_through_the_pane_succeeds() -> void:
	_seed_account(FIGHTER, {CANNON: 1}, false)
	var panel := _mount()
	assert_false(
		(_profile.get(&"_fits") as Dictionary).has(String(FIGHTER)), "the fixture stores no fit"
	)
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 0), "W1 is selected")
	## The pane previews the launch's fit, not the empty stored one: W1 holds the delivered laser.
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % ["W", 1, String(ModuleData.module(LASER)[&"name"]).to_upper(), 0],
		"the selection line reads the delivered laser, never EMPTY"
	)
	assert_eq(
		_cell_text(_row(panel, CANNON), "Action"),
		String(PanelScript.ACTION_SWAP),
		"and the cannon's row offers the swap that fit allows"
	)
	_press(panel, CANNON)
	assert_eq(_cells(FIGHTER, WEAPON_SLOT)[0], String(CANNON), "the install landed on that cell")
	assert_ne(_footer(panel), WORDING_FIT_ILLEGAL, "and the catch-all refusal is not the answer")
	var stored := _fit(FIGHTER)
	var legality: Dictionary = ShipFit.fit_legal(FIGHTER, stored)
	assert_true(bool(legality[&"legal"]), "the fit left behind is launchable: %s" % str(legality))
	assert_true((legality[&"missing"] as Array).is_empty(), "with no mandatory cell missing")
	assert_eq(
		_cells(FIGHTER, ENGINE_SLOT)[0], String(STANDARD_ENGINE), "the delivered engine stands"
	)
	assert_eq(
		_profile.call(&"resolved_fit", FIGHTER),
		stored,
		"the fit the launch would fly is the fit the profile now holds"
	)
	assert_eq(_owned(LASER), 0, "the delivered laser that cell held was never banked")
	assert_eq(_owned(CANNON), 0, "and the cannon left the inventory")


## A swap returns the displaced module to the inventory: nothing is destroyed (09 section 4
## item 8) and the profile's own transaction is the only writer.
func test_a_swap_returns_the_displaced_module() -> void:
	_seed_account(HULL, {CANNON: 1}, true)
	var panel := _mount()
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 0), "W1 is selected")
	assert_eq(_cell_text(_row(panel, CANNON), "Action"), "SWAP", "the row offers SWAP")
	_press(panel, CANNON)
	assert_eq(_cells(HULL, WEAPON_SLOT)[0], String(CANNON), "W1 took the cannon")
	assert_eq(_owned(CANNON), 0, "the cannon left the inventory")
	assert_eq(_owned(LASER), 1, "the displaced laser came back into it")
	assert_eq(_cells(HULL, WEAPON_SLOT)[1], "", "the other W cell was never touched")
	assert_eq(_cells(HULL, WEAPON_SLOT)[2], "", "and neither was the third")


## A mandatory cell refuses its remove with the pin's own wording, and the profile's fit is
## untouched (09 section 4 items 1 and 10).
func test_a_mandatory_cell_refuses_with_the_pinned_wording() -> void:
	_seed_account(HULL, {}, true)
	var panel := _mount()
	var before := _fit(HULL)
	assert_true(panel.call(&"select_cell", ENGINE_SLOT, 0), "the E cell is selected")
	assert_true(panel.call(&"can_remove"), "it holds a module, so REMOVE is offered")
	_press_remove(panel)
	assert_eq(_footer(panel), WORDING_MANDATORY, "the pinned mandatory wording")
	assert_true(_last_danger(), "rendered as a danger")
	assert_eq(_last_status(), WORDING_MANDATORY, "and written into the shell's strip")
	assert_eq(_fit(HULL), before, "the fit is untouched")
	assert_eq(_cells(HULL, ENGINE_SLOT)[0], String(STANDARD_ENGINE), "the engine stayed")
	## The same cell takes a better engine: a mandatory cell swaps, it never empties.
	_profile.call(&"add_module", ION, 1)
	panel.call(&"select_cell", ENGINE_SLOT, 0)
	_press(panel, ION)
	assert_eq(_cells(HULL, ENGINE_SLOT)[0], String(ION), "the mandatory cell swapped")
	assert_eq(_owned(STANDARD_ENGINE), 1, "and the displaced engine came back")
	## A non-mandatory cell of the same account empties through the composed remove.
	panel.call(&"select_cell", SHIELD_SLOT, 0)
	var shield := StringName(_cells(HULL, SHIELD_SLOT)[0])
	assert_true(shield != &"", "the delivered fit carries a shield")
	_press_remove(panel)
	assert_eq(_cells(HULL, SHIELD_SLOT)[0], "", "the shield cell is empty")
	assert_eq(_owned(shield), 1, "and its module is back in the inventory")


## R1 MED-2: a refusal's line belongs to the press that made it, and the successful action that
## answers it puts the footer back on the selected cell's own line - in the pane and in the
## shell's strip. There is no re-selection in between, so only the refusal's own lifetime is read.
func test_a_successful_swap_does_not_leave_the_refusals_line() -> void:
	_seed_account(HULL, {ION: 1}, true)
	var panel := _mount()
	assert_true(panel.call(&"select_cell", ENGINE_SLOT, 0), "the mandatory E cell is selected")
	assert_false(panel.call(&"remove_selected"), "it is never emptied")
	assert_eq(_footer(panel), WORDING_MANDATORY, "the refusal is on the footer")
	assert_eq(_last_status(), WORDING_MANDATORY, "and written into the shell's strip")
	assert_true(panel.call(&"install_module", ION), "the same cell takes the better drive")
	assert_eq(_cells(HULL, ENGINE_SLOT)[0], String(ION), "the swap landed")
	assert_ne(_footer(panel), WORDING_MANDATORY, "the refusal does not outlive the action")
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % [
			"E", 1, String(ModuleData.module(ION)[&"name"]).to_upper(), _owned(ION)
		],
		"the footer is back on the selected cell's own line"
	)
	assert_eq(_last_status(), _footer(panel), "and the shell's strip carries that same line")
	assert_false(_last_danger(), "neither line is the danger state anymore")


## The per-cell REMOVE is offered only for a cell that holds a module.
func test_remove_is_offered_only_for_a_filled_cell() -> void:
	_seed_account(HULL, {}, true)
	var panel := _mount()
	var remove := panel.get_node("%RemoveButton") as Button
	assert_true(remove.disabled, "nothing selected, nothing to remove")
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	assert_eq(_cells(HULL, WEAPON_SLOT)[1], "", "W2 is empty")
	assert_true(remove.disabled, "an empty cell has nothing to return")
	panel.call(&"select_cell", WEAPON_SLOT, 0)
	assert_false(remove.disabled, "the fitted W1 offers REMOVE")
	assert_eq(remove.text, PanelScript.REMOVE_ACTION, "and carries the pinned word")


## ------------------------------------------------------------------------ the power meter


## The meter's numbers are `ShipFit.fit_legal`'s own `power` dictionary for the fit the launch
## flies, in the pin's idle form.
func test_the_meter_numbers_are_fit_legals_power_dictionary() -> void:
	var panel := _mount()
	var fit := _fit(HULL)
	assert_true(not fit.is_empty(), "the fixture holds a delivered fit")
	var power := _power(HULL, fit)
	assert_eq(
		panel.call(&"meter_text"),
		WORDING_METER_IDLE % [int(power[&"draw"]), int(power[&"out"])],
		"the idle meter is the resolved fit's own arithmetic"
	)
	## And it moves with the fit the profile holds, not with a number of the pane's own.
	_profile.call(&"set_fit_slot", HULL, WEAPON_SLOT, 1, RAILGUN)
	panel.call(&"refresh_profile", &"fits")
	var moved := _power(HULL, _fit(HULL))
	assert_ne(moved[&"draw"], power[&"draw"], "the railgun draws more than nothing")
	assert_eq(
		panel.call(&"meter_text"),
		WORDING_METER_IDLE % [int(moved[&"draw"]), int(moved[&"out"])],
		"the meter follows the profile's own fit"
	)


## With a cell selected the meter adds the candidate's own line, and an over-budget candidate
## is the pin's danger form: the same line in the danger colour, ending `— OVER BY <n>`. The
## press that candidate comes from is refused with 09 section 2's own over-by wording.
func test_an_over_budget_candidate_is_the_danger_form() -> void:
	_seed_account(FIGHTER, {PLASMA: 2}, true)
	var panel := _mount()
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 0), "W1 of the Lancer is selected")
	_press(panel, PLASMA)
	assert_eq(_cells(FIGHTER, WEAPON_SLOT)[0], String(PLASMA), "the first plasma fits")
	var fit := _fit(FIGHTER)
	var power := _power(FIGHTER, fit)
	assert_eq(
		panel.call(&"meter_text"),
		WORDING_METER_CANDIDATE % [
			int(power[&"draw"]), int(power[&"out"]), int(power[&"draw"]), int(power[&"out"])
		],
		"the candidate matches the fit it would leave"
	)
	## The second plasma into the second W cell is one draw over the hull's output.
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 1), "W2 is selected")
	var before := _fit(FIGHTER)
	_press(panel, PLASMA)
	var candidate := before.duplicate(true)
	candidate[WEAPON_SLOT] = [String(PLASMA), String(PLASMA)]
	var over := _power(FIGHTER, candidate)
	assert_false(bool(over[&"legal"]), "the candidate is over budget")
	var over_by := int(over[&"draw"]) - int(over[&"out"])
	assert_eq(
		panel.call(&"meter_text"),
		WORDING_METER_CANDIDATE % [
			int(power[&"draw"]), int(power[&"out"]), int(over[&"draw"]), int(over[&"out"])
		] + WORDING_METER_OVER % over_by,
		"the meter is the candidate's own arithmetic, ending over by"
	)
	assert_eq(
		_footer(panel),
		WORDING_METER_OVERLOAD % [int(over[&"draw"]), int(over[&"out"]), over_by],
		"the refusal is 09 section 2's own over-by line"
	)
	assert_true(_last_danger(), "rendered as a danger")
	assert_eq(_fit(FIGHTER), before, "and nothing was written")
	assert_eq(_owned(PLASMA), 1, "the refused plasma is still in the inventory")
	var meter := panel.get_node("%MeterLabel") as Label
	assert_true(_danger_override(meter), "the over-budget meter draws in the danger colour")
	assert_eq(
		_label_colour(panel, "%MeterLabel"),
		_token(panel, &"accent_danger"),
		"the danger colour is the theme's accent_danger"
	)


## The footer's own line: the selected cell's `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`,
## the pin's word while nothing is selected, and the third pinned refusal as the catch-all.
func test_the_footer_line_reads_the_selected_cell() -> void:
	_seed_account(HULL, {LASER: 2}, true)
	var panel := _mount()
	assert_eq(_footer(panel), WORDING_SELECT, "the idle line is the pin's own word")
	panel.call(&"select_cell", WEAPON_SLOT, 0)
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % ["W", 1, String(ModuleData.module(LASER)[&"name"]).to_upper(), 2],
		"a fitted cell names its module and the inventory's count"
	)
	panel.call(&"select_cell", WEAPON_SLOT, 1)
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % ["W", 2, "EMPTY", 0],
		"an empty cell reads EMPTY"
	)
	panel.call(&"select_cell", POWER_SLOT, 0)
	assert_eq(
		_footer(panel),
		WORDING_SELECTION % [
			"P", 1, String(ModuleData.module(&"p_std")[&"name"]).to_upper(), 0
		],
		"the power cell is one cell, addressed like the rest"
	)
	assert_eq(PanelScript.REFUSAL_FIT_ILLEGAL, WORDING_FIT_ILLEGAL, "the catch-all wording")
	assert_eq(PanelScript.REFUSAL_MANDATORY, WORDING_MANDATORY, "the mandatory wording")


## --------------------------------------------------------- the profile_changed contract


## `&"modules"`, `&"fits"` and `&"ships"` drive the pane; every other key leaves it alone.
func test_profile_changed_drives_the_refresh() -> void:
	_seed_account(HULL, {CANNON: 1}, true)
	var panel := _mount()
	assert_eq(panel.call(&"module_row_ids"), [CANNON] as Array[StringName], "one row")
	## &"modules": a new inventory id grows a row, through the profile's own signal.
	_profile.call(&"add_module", RAILGUN, 1)
	assert_eq(
		panel.call(&"module_row_ids"), [CANNON, RAILGUN] as Array[StringName],
		"the railgun row arrived on profile_changed(&modules)"
	)
	assert_eq(_cell_text(_row(panel, RAILGUN), "Owned"), WORDING_OWNED % 1, "with its count")
	## &"fits": a fit write moves the meter and the footer line.
	var before: String = panel.call(&"meter_text")
	_profile.call(&"set_fit_slot", HULL, WEAPON_SLOT, 1, RAILGUN)
	var power := _power(HULL, _fit(HULL))
	assert_ne(panel.call(&"meter_text"), before, "the meter moved on profile_changed(&fits)")
	assert_eq(
		panel.call(&"meter_text"),
		WORDING_METER_IDLE % [int(power[&"draw"]), int(power[&"out"])],
		"and reads the new fit's arithmetic"
	)
	assert_eq(
		_footer(panel), WORDING_SELECT, "the footer line is unchanged while nothing is selected"
	)
	## &"ships": a hull switch rebuilds the grid from the new matrix.
	var grid := _grid(panel)
	assert_eq(grid.get_child_count(), ShipFit.grid_cells(HULL).size(), "the Vanguard's grid")
	_profile.set(&"_owned_ships", [HULL, FIGHTER] as Array[StringName])
	assert_true(_profile.call(&"set_active_ship", FIGHTER), "the Lancer is owned and set active")
	assert_eq(
		grid.get_child_count(), ShipFit.grid_cells(FIGHTER).size(),
		"the Lancer's matrix replaced it on profile_changed(&ships)"
	)
	assert_eq(panel.call(&"active_hull"), FIGHTER, "and the pane reads the new hull")
	assert_eq(
		(panel.get_node("%SlotCaption") as Label).text,
		WORDING_CAPTION % [
			_count_cells(FIGHTER), int(ShipFit.grid_counts(FIGHTER)[ENGINE_SLOT])
		],
		"the caption moved with it"
	)


func _count_cells(hull: StringName) -> int:
	var total := 0
	for count: Variant in ShipFit.grid_counts(hull).values():
		total += int(count)
	return total


## A credits change is another pane's business: the rows are not rebuilt and the meter does not
## move.
func test_a_credit_change_does_not_rebuild_the_rows() -> void:
	_seed_account(HULL, {CANNON: 1}, true)
	var panel := _mount()
	var row := _row(panel, CANNON)
	var meter: String = panel.call(&"meter_text")
	_profile.call(&"add_credits", 500)
	assert_eq(_profile.call(&"credits"), START_CREDITS + 500, "the balance moved")
	assert_true(_row(panel, CANNON) == row, "the row node survived profile_changed(&credits)")
	assert_eq(panel.call(&"meter_text"), meter, "and the meter did not move")


## ------------------------------------------------------------------------ the focus order


## The pane's focusable plate and row Buttons in tree order are the SLOT LAYOUT cells first
## (row-major), then the OWNED MODULES rows, then the footer's own REMOVE - the pane's own slice
## of STATION_HUB section 10's walk. The scroll container is a stop of its own (as it is in every
## shipped pane), so this measures the buttons the pin's bullet names.
func test_the_focus_order_is_cells_then_rows_then_footer() -> void:
	_seed_account(HULL, {CANNON: 1, RAILGUN: 1}, true)
	var panel := _mount()
	assert_true(panel.call(&"select_cell", WEAPON_SLOT, 0), "a filled cell so the footer offers REMOVE")
	var order: Array[String] = []
	_collect_focusable(panel, order)
	var expected: Array[String] = []
	for cell: Dictionary in ShipFit.grid_cells(HULL):
		if not bool(cell[&"gap"]):
			expected.append("Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])])
	for module_id: StringName in panel.call(&"module_row_ids"):
		expected.append("Module%s" % String(module_id).to_pascal_case())
	expected.append("RemoveButton")
	assert_eq(order, expected, "the walk is cells, then rows, then the footer")
	## Nothing else in the pane is a stop: the scroll container is not one, so the pin's bullet
	## is the whole walk.
	assert_eq(
		(panel.get_node("%FittingScroll") as ScrollContainer).focus_mode,
		Control.FOCUS_NONE,
		"the pane's own scroll is not a focus stop"
	)
	## The ring's first stop is the first cell.
	panel.call(&"focus_primary")
	var owner := panel.get_viewport().gui_get_focus_owner()
	assert_true(owner != null, "focus_primary takes the ring")
	if owner != null:
		assert_eq(owner.name, "SlotW00", "on the top-left cell")


func _collect_focusable(node: Node, out: Array[String]) -> void:
	for child: Node in node.get_children():
		var button := child as Button
		if button != null and button.focus_mode != Control.FOCUS_NONE and not button.disabled:
			out.append(button.name)
		_collect_focusable(child, out)


## ------------------------------------------------------------------ the write discipline


## CONTRACTS section 13 rule 5 and STATION_HUB section 12.4: the pane requests through the two
## composed calls and touches no other profile writer.
func test_the_pane_writes_only_through_the_two_composed_calls() -> void:
	var source := _read_source("res://ui/station/fitting_panel.gd")
	assert_true(source.contains("\"fit_module_at\""), "the pane requests the composed install")
	assert_true(source.contains("\"clear_fit_slot\""), "and the composed remove")
	for forbidden: String in [
		"\"set_fit\"", "\"set_fit_slot\"", "\"clear_fit\"", "\"set_fits\"", "\"add_module\"",
		"\"take_module\"", "\"buy_module\"", "\"spend\"", "\"add_credits\"",
		"\"install_upgrade\"", "\"buy_ship\"", "\"buy_ammo\"",
	]:
		assert_false(
			source.contains(forbidden), "the pane never calls PlayerProfile.%s" % forbidden
		)
	var methods: Array[String] = []
	for entry: Dictionary in _profile.get_method_list():
		methods.append(str(entry.get("name", "")))
	assert_true(methods.has("fit_module_at"), "the composed install exists")
	assert_true(methods.has("clear_fit_slot"), "and the composed remove")
