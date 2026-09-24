@tool
extends McpTestSuite
## Suite d6_status: wave D6's ship status screen (UI_SPEC section 3.8, CONTRACTS section 18).
##
## Covers the toggle behind `InputMap.has_action` with no input row present (and the positive
## branch with a runtime-seeded row, so `project.godot` is never touched), the docked guard, the
## pinned 720 x 520 modal on the section 3.7 nine-slice frame, the slot grid and module rows
## rendered from a seeded scratch profile, the damaged-side swap on both branches, the hardpoint
## markers behind `ShipFit.HARDPOINTS`, the footer reading the fitting panel's own power
## arithmetic, and the no-write proof (the scratch profile's bytes identical before and after).
##
## The screen is mounted the way the HUD mounts it - `hud.tscn` instantiated with the shipped
## theme, `ShipStatusScreen` built in `_ready` - and driven through the HUD's own seams
## (`set_hull_slots`, `_on_hull_changed`, `_unhandled_input`), so nothing here re-implements the
## dispatch. Every number is read off the screen, the profile, `ShipFit`, `ModuleCatalog` or the
## repairs pane's own `hull_render`, never off a literal this suite invents.
##
## The profile is the shipped autoload, borrowed the way `test_p2b_fitting_panel.gd` borrows it:
## `save_path` is repointed at a scratch file, the fields the fixture writes are handed back in
## `suite_teardown`, and the store is flushed while the scratch path is still in place, so the
## owner's `user://profile.cfg` is never written (probe hygiene L17).

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
const ModuleData := preload("res://game/module_catalog.gd")
## The screen, reached by path (not its `class_name`) so the suite still parses in a headless gate
## whose global class table predates it - the family's own lesson.
const StatusScreenScript := preload("res://ui/hud/ship_status_screen.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_d6_status.cfg"

## UI_SPEC section 3.8's action (the `project.godot` row is orchestrator-applied at close-out;
## this suite seeds it at runtime only, and only when the project carries none).
const ACTION: StringName = &"ship_status"

const VANGUARD: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
## An id outside the nine player hulls: no grid, no map, nothing to draw (CONTRACTS section 11
## rule 6, 09 section 11's fallback hull).
const NPC_HULL: StringName = &"ship_swarmer"

const WEAPONS_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const MINING: StringName = &"w_mining"
const LIGHT_PLATE: StringName = &"h_plate_light"
const LIGHT_SHIELD: StringName = &"s_light"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_POWER: StringName = &"p_std"

const START_CREDITS := 10000
const MODAL_SIZE := Vector2(720.0, 520.0)
const FRAME_PATH := "res://assets/ui/ui_cockpit_frame.png"
const CLOSE_PATH := "res://assets/icons/hud/icon_close.svg"
## UI_SPEC section 3.8's Mockup C left well, in the modal body's own space. The D6 `320` width pin
## that used to sit here is superseded by the mockup's well-fit: it is the rect the drawn sprite
## box must stay inside (R1 HIGH-1 measured the stale pin pushing the sprite 60 px past it).
const RENDER_WELL := Rect2(24.0, 60.0, 276.0, 368.0)
const SIDE_PATH := "res://assets/ships/ship_%s_side.png"
const DAMAGED_PATH := "res://assets/ships/ship_%s_damaged_side.png"
## 09 section 1's slot glyph the shipyard and the fitting pane draw in an empty cell, held here
## so a drift in either direction is a red assertion.
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
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s.svg"
const MARKER_KIND_THRUSTER: StringName = &"thruster"
const MARKER_KIND_MOUNT: StringName = &"mount"

var _profile: Node = null
var _hud: Control = null
var _previous_path := ""
var _seeded_action := false


func suite_name() -> String:
	return "d6_status"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to mount the HUD")
		return
	_profile = tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the screen's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	_drop_seeded_action()
	if _profile == null:
		return
	## Flush on the scratch path and only then restore the real one, so no dirty flag and no
	## running timer carries a test's account home.
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_seed_account(VANGUARD, {})
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		fail_setup("hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_fixture_host().add_child(_hud)


func teardown() -> void:
	_drop_seeded_action()
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Where a fixture may enter the tree; see `test_engine2_hud.gd` for why the profile autoload
## is the host rather than the busy root viewport.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


## Every read enters through here, and a fixture that did not build the screen is a red
## assertion rather than a null dereference the runner would still score as a pass.
func _screen() -> Control:
	var screen: Control = null
	if _hud != null:
		screen = _hud.call(&"status_screen")
	assert_true(screen != null, "the HUD built the section 3.8 screen")
	return screen


func _open_screen() -> Control:
	var screen := _screen()
	if screen != null:
		screen.call(&"set_open", true)
	return screen


## The fixture account every test starts from: the hull owned and active, an empty inventory and
## no stored fit - so `resolved_fit` answers 09 section 9's `ShipFit.standard_fit`, exactly as
## the launch would fly it.
func _seed_account(hull: StringName, fit: Dictionary) -> void:
	var owned: Array[StringName] = [hull]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	if not fit.is_empty():
		_profile.call(&"set_fit", hull, fit)


## The standard vanguard fit's own record, resolved through the profile so a fixture and the
## screen cannot disagree about what "fitted" means (`resolved_fit`'s fallback included).
func _resolved_fit(hull: StringName) -> Dictionary:
	var fit: Variant = _profile.call(&"resolved_fit", hull)
	return fit if fit is Dictionary else {}


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ---------------------------------------------------------------- the input row (runtime only)

## Seeds the `ship_status` row at runtime when the project carries none, so the toggle's
## positive branch is provable without touching `project.godot`. Only a row this suite created
## is ever erased (see `_drop_seeded_action`), so a close-out row is never disturbed.
func _seed_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION)
	_seeded_action = true


func _drop_seeded_action() -> void:
	if _seeded_action and InputMap.has_action(ACTION):
		InputMap.erase_action(ACTION)
	_seeded_action = false


## Temporarily removes the row (remembering its events and deadzone) so the guard's absent
## branch is provable even after the close-out pass adds it. `_restore_action` puts it back
## exactly; an absent row restores to absent.
func _take_action_away() -> Dictionary:
	var state := {"had": false, "events": [], "deadzone": 0.5}
	if not InputMap.has_action(ACTION):
		return state
	state["had"] = true
	state["events"] = InputMap.action_get_events(ACTION)
	state["deadzone"] = InputMap.action_get_deadzone(ACTION)
	InputMap.erase_action(ACTION)
	return state


func _restore_action(state: Dictionary) -> void:
	if not bool(state["had"]) or InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION, float(state["deadzone"]))
	for event: InputEvent in state["events"]:
		InputMap.action_add_event(ACTION, event)


func _press_status() -> void:
	var event := InputEventAction.new()
	event.action = ACTION
	event.pressed = true
	_hud.call(&"_unhandled_input", event)


func _toggle_open() -> void:
	_seed_action()
	_press_status()


## ---------------------------------------------------------------------------
## The modal and its chrome
## ---------------------------------------------------------------------------


func test_the_screen_is_the_pinned_modal_and_is_hidden_by_default() -> void:
	var screen := _screen()
	assert_true(screen != null, "the HUD builds the section 3.8 screen")
	assert_eq(screen.name, "ShipStatusScreen", "the pinned node name")
	assert_false(bool(screen.call(&"is_open")), "hidden by default")
	assert_false(screen.visible, "and not visible")
	assert_eq(screen.call(&"modal_size"), MODAL_SIZE, "the 720 x 520 box")
	var body: Control = screen.call(&"body")
	assert_true(body != null, "the nine-slice body exists")
	assert_eq(body.custom_minimum_size, MODAL_SIZE, "the body carries the pinned box")
	var frame: NinePatchRect = screen.call(&"frame")
	assert_true(frame != null, "the frame exists")
	assert_eq(frame.texture.resource_path, FRAME_PATH, "the section 3.7 cockpit frame")
	assert_eq(frame.patch_margin_left, 64, "the 64 px master band")
	assert_eq(frame.patch_margin_top, 64, "the 64 px master band")
	assert_true(is_equal_approx(frame.scale.x, 0.5), "drawn at half scale (the D2 ruling)")
	var close_button: TextureButton = screen.call(&"close_button")
	assert_true(close_button != null, "the icon_close control exists")
	assert_eq(close_button.texture_normal.resource_path, CLOSE_PATH, "the icon_close cut")


func test_the_toggle_is_inert_with_no_input_row_present() -> void:
	var state := _take_action_away()
	assert_false(InputMap.has_action(ACTION), "the row really is absent for this read")
	_press_status()
	assert_false(bool(_screen().call(&"is_open")), "an absent row leaves the screen closed")
	_restore_action(state)
	assert_false(_seeded_action, "nothing was seeded in this test")


func test_the_toggle_opens_and_closes_when_the_row_exists() -> void:
	_seed_action()
	assert_true(InputMap.has_action(ACTION), "the row exists for this read")
	_press_status()
	assert_true(bool(_screen().call(&"is_open")), "the action opens the modal")
	_press_status()
	assert_false(bool(_screen().call(&"is_open")), "the same action closes it")


func test_the_close_button_and_the_screen_api_close_the_modal() -> void:
	_open_screen()
	assert_true(bool(_screen().call(&"is_open")), "the screen is open")
	var close_button: TextureButton = _screen().call(&"close_button")
	close_button.pressed.emit()
	assert_false(bool(_screen().call(&"is_open")), "the icon_close button closes it")
	assert_true(bool(_screen().call(&"toggle")), "toggle opens")
	assert_false(bool(_screen().call(&"toggle")), "toggle closes")


func test_a_docked_hud_keeps_the_screen_hidden() -> void:
	_hud.call(&"set_docked", true)
	assert_true(bool(_hud.call(&"docked")), "the latch is up")
	_screen().call(&"set_open", true)
	assert_false(bool(_screen().call(&"is_open")), "a docked screen refuses to open")
	_toggle_open()
	assert_false(bool(_screen().call(&"is_open")), "and the action cannot open it either")
	_hud.call(&"set_docked", false)
	_open_screen()
	assert_true(bool(_screen().call(&"is_open")), "undocked, the screen opens again")


## ---------------------------------------------------------------------------
## The grid and the module rows (a seeded scratch profile)
## ---------------------------------------------------------------------------


## The vanguard's matrix (`.WW.`, `HSCB`, `HWU.`, `.EP.`) and a fit that fills all three W
## cells, so one row per type and a three-cell weapon group are both exercised.
func _seed_vanguard_fit() -> Dictionary:
	var fit := {
		&"engines": [STANDARD_ENGINE],
		&"power": STANDARD_POWER,
		&"weapons": [LASER, CANNON, MINING],
		&"shields": [LIGHT_SHIELD],
		&"armour": [LIGHT_PLATE],
	}
	_profile.call(&"set_fit", VANGUARD, fit)
	return _resolved_fit(VANGUARD)


func test_the_grid_is_the_hulls_own_matrix() -> void:
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_open_screen()
	var grid: GridContainer = _screen().call(&"slot_grid")
	assert_eq(grid.columns, ShipFit.grid_size(VANGUARD).x, "columns = the matrix width")
	assert_eq(
		grid.get_child_count(),
		ShipFit.grid_cells(VANGUARD).size(),
		"one child per matrix cell, gaps included"
	)
	var cells: Array = _screen().call(&"grid_cells")
	assert_eq(cells.size(), 11, "the vanguard's eleven slots")
	var fitted := 0
	for cell: Dictionary in cells:
		if bool(cell[&"fitted"]):
			fitted += 1
	assert_eq(fitted, 5, "09 section 9's standard fit fills five of them")
	var gaps := 0
	for cell: Dictionary in ShipFit.grid_cells(VANGUARD):
		if bool(cell[&"gap"]):
			gaps += 1
	assert_eq(gaps, 5, "and the matrix carries five gaps")
	assert_eq(grid.get_child_count(), cells.size() + gaps, "cells + gaps = the matrix")


func test_the_module_rows_read_the_seeded_fit_with_its_cell_refs_and_names() -> void:
	var fit := _seed_vanguard_fit()
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_open_screen()
	var rows: Array = _screen().call(&"module_rows")
	assert_eq(rows.size(), 7, "three weapons, one shield, one plate, one engine, one power")
	var refs: Array = []
	for row: Dictionary in rows:
		refs.append(String(row[&"ref"]))
	assert_eq(
		refs,
		["W1", "W2", "H1", "S1", "W3", "E1", "P1"],
		"the layout cell refs in the grid's row-major order (index + 1)"
	)
	for row: Dictionary in rows:
		var base := StringName(row[&"base"])
		var expected := String(ModuleData.module(base).get(&"name", String(base)))
		assert_eq(String(row[&"name"]), expected, "the row names the ModuleCatalog module")
		assert_eq(
			String(row[&"text"]),
			"%s · %s" % [String(row[&"ref"]), expected],
			"the row reads ref and name"
		)
	assert_eq(String(rows[0][&"module"]), String(LASER), "the first W cell holds the laser")
	var fit_weapons: Array = fit.get(&"weapons", [])
	assert_eq(String(fit_weapons[1]), String(CANNON), "the fixture's second W cell is the cannon")
	assert_eq(String(rows[1][&"base"]), String(CANNON), "and the second row reads it")
	## The grid and the rows are one grid: each plate and its row share the cell's token+index
	## in their node names (the shipyard's own naming), and the drawn label is the reading.
	for row: Dictionary in rows:
		var cell_name := "%s%02d" % [String(row[&"token"]), int(row[&"index"])]
		var plate: Node = _screen().find_child("Slot" + cell_name, true, false)
		var label: Node = _screen().find_child("Row" + cell_name, true, false)
		assert_true(plate != null, "the %s cell has its plate" % row[&"ref"])
		assert_true(label != null, "and its row")
		assert_eq((label as Label).text, String(row[&"text"]), "the drawn row text is the reading")


func test_an_empty_slot_draws_its_type_glyph_and_a_fitted_cell_its_module_icon() -> void:
	_seed_vanguard_fit()
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_open_screen()
	var fitted := 0
	var empty := 0
	for cell: Dictionary in _screen().call(&"grid_cells"):
		var type_key := StringName(cell[&"type"])
		if bool(cell[&"fitted"]):
			fitted += 1
			assert_eq(
				String(cell[&"icon"]),
				ModuleData.icon_path(StringName(cell[&"module"])),
				"a fitted %s cell draws its module's catalogue icon" % type_key
			)
		else:
			empty += 1
			assert_eq(
				String(cell[&"icon"]),
				SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % String(SLOT_GLYPH_STEMS[type_key]),
				"an empty %s cell draws its type's slot glyph" % type_key
			)
	assert_eq(fitted, 7, "seven of the eleven slots carry the seeded fit")
	assert_eq(empty, 4, "and the four the fit leaves empty draw their slot glyph")


## CONTRACTS section 11 / UI_SPEC section 3.8: a weapon cell the launch pushed adds the rack
## ordinal its `battery` field carries, and the pushed cell (not the fit) is the cell's ref.
func test_a_pushed_weapon_cell_supplies_the_rack_ordinal() -> void:
	var fit := {
		&"engines": [STANDARD_ENGINE],
		&"power": STANDARD_POWER,
		&"weapons": [LASER, ""],
		&"shields": [LIGHT_SHIELD],
		&"armour": [LIGHT_PLATE],
	}
	_profile.call(&"set_fit", VANGUARD, fit)
	var cells: Array = [{
		&"slot": WEAPONS_SLOT,
		&"index": 1,
		&"module": CANNON,
		&"icon": ModuleData.icon_path(CANNON),
		&"fitted": true,
		&"battery": 3,
		&"position": 1,
		&"selectable": true,
	}]
	_hud.call(&"set_hull_slots", VANGUARD, cells)
	_open_screen()
	var rows: Array = _screen().call(&"module_rows")
	assert_eq(rows.size(), 6, "the pushed W2 joins the five fitted cells")
	assert_eq(String(rows[1][&"ref"]), "W2", "the pushed cell's own layout index")
	assert_eq(int(rows[1][&"rack"]), 3, "its rack ordinal (the payload's battery)")
	assert_eq(
		String(rows[1][&"text"]),
		"W2 · B3 · %s" % String(ModuleData.module(CANNON).get(&"name", "Cannon MkI")),
		"the row carries the rack the HUD's W-slot buttons address"
	)
	assert_eq(String(rows[1][&"base"]), String(CANNON), "the pushed module, not the fit's")


func test_a_hull_with_no_grid_and_no_map_draws_nothing() -> void:
	_hud.call(&"set_hull_slots", NPC_HULL, [])
	_open_screen()
	assert_eq(_screen().call(&"slot_grid").get_child_count(), 0, "no grid cells")
	assert_eq((_screen().call(&"module_rows") as Array).size(), 0, "no module rows")
	assert_eq((_screen().call(&"hardpoint_markers") as Array).size(), 0, "no markers")
	assert_eq(String(_screen().call(&"hull_render_path")), "", "no render for an NPC hull")


## ---------------------------------------------------------------------------
## The damaged-side swap (the repairs pane's own rule)
## ---------------------------------------------------------------------------


func test_the_render_swaps_to_the_damaged_cut_when_damage_is_reported() -> void:
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_hud.call(&"_on_hull_changed", 500.0, 1000.0)
	_open_screen()
	assert_eq(
		String(_screen().call(&"hull_render_path")),
		RepairsPanelScript.hull_render(VANGUARD, 500),
		"the repairs pane's own hull_render answers for the same damage"
	)
	assert_eq(
		String(_screen().call(&"hull_render_path")),
		DAMAGED_PATH % "vanguard",
		"the vanguard's damaged cut is on disk and is drawn"
	)
	var render: TextureRect = _screen().call(&"hull_render")
	assert_eq(
		render.texture.resource_path,
		DAMAGED_PATH % "vanguard",
		"the texture is the damaged cut"
	)


func test_an_intact_hull_and_a_hull_with_no_damaged_cut_keep_the_intact_render() -> void:
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_hud.call(&"_on_hull_changed", 1000.0, 1000.0)
	_open_screen()
	assert_eq(
		String(_screen().call(&"hull_render_path")),
		SIDE_PATH % "vanguard",
		"no missing hull keeps the intact side render"
	)
	assert_eq(
		RepairsPanelScript.hull_render(VANGUARD, 0),
		SIDE_PATH % "vanguard",
		"the repairs pane agrees with the zero-damage read"
	)
	_hud.call(&"set_hull_slots", FIGHTER, [])
	_hud.call(&"_on_hull_changed", 500.0, 1000.0)
	_open_screen()
	assert_eq(
		String(_screen().call(&"hull_render_path")),
		SIDE_PATH % "fighter",
		"damage on a hull with no damaged cut keeps the intact render"
	)
	assert_false(
		ResourceLoader.exists(DAMAGED_PATH % "fighter"),
		"and that cut really is absent, so the branch is the no-cut one"
	)


## ---------------------------------------------------------------------------
## The hardpoint markers
## ---------------------------------------------------------------------------


func test_the_hardpoint_markers_follow_the_hulls_own_map() -> void:
	var fit := _resolved_fit(VANGUARD)
	assert_true(fit.size() > 0, "the vanguard resolves a fit")
	_hud.call(&"set_hull_slots", VANGUARD, [])
	## R1 HIGH-1's guard, read before the modal opens (see the helper): the box the push left is
	## already the sprite's own aspect-fit rect, inside the well.
	_assert_render_box_takes_the_well(_screen(), "intact")
	_open_screen()
	var markers: Array = _screen().call(&"hardpoint_markers")
	var thrusters := 0
	var mounts := 0
	for marker: Dictionary in markers:
		if StringName(marker[&"kind"]) == MARKER_KIND_THRUSTER:
			thrusters += 1
		elif StringName(marker[&"kind"]) == MARKER_KIND_MOUNT:
			mounts += 1
	assert_eq(thrusters, 8, "ShipFit.HARDPOINTS' four thruster modes, two anchors each")
	assert_eq(mounts, 3, "the vanguard's three W cells, one measured mount each")
	assert_eq(markers.size(), 11, "every anchor is drawn")
	_assert_markers_on_the_drawn_sprite(markers, "intact")
	var mount: Dictionary = ShipFit.weapon_mounts(VANGUARD)[0]
	assert_true(
		is_equal_approx(float(markers[8][&"facing"]), float(mount[&"facing"])),
		"the first mount's facing is the table's own rest direction"
	)


## The same guarantee on the damaged branch, where the swap changes the sprite's aspect (the
## vanguard's damaged cut is 1.8x taller than its intact one), which is where a stale marker space
## would drift. The damage is reported **before** the push, so the read below measures the damaged
## branch's own box at the first refresh - the moment R1 HIGH-1's stale clamp is visible.
func test_the_markers_stay_on_the_sprite_when_the_damaged_cut_is_drawn() -> void:
	_hud.call(&"_on_hull_changed", 500.0, 1000.0)
	_hud.call(&"set_hull_slots", VANGUARD, [])
	assert_eq(
		String(_screen().call(&"hull_render_path")),
		DAMAGED_PATH % "vanguard",
		"the vanguard's damaged cut is the drawn sprite for this read"
	)
	_assert_render_box_takes_the_well(_screen(), "damaged")
	_open_screen()
	var markers: Array = _screen().call(&"hardpoint_markers")
	assert_eq(markers.size(), 11, "every HARDPOINTS anchor is drawn over the damaged cut too")
	_assert_markers_on_the_drawn_sprite(markers, "damaged")


## R1 HIGH-1's guard, staged where the class is actually visible: a screen whose **first** render
## refresh lands on a hull it did not have at build. `Control.size` clamps up to
## `custom_minimum_size`, so while the D6 320 x 320 minimum was lowered only *after* the size write
## it held the box at 320 x 320 - the sprite drew 60 px past the left well (box right edge 360
## against the well's 300). The fixture HUD refreshes once at its own build, which heals the box,
## so no read taken off it can see the class; this row mounts a bare screen the way `hud.gd` mounts
## it and pushes exactly one hull into it.
func test_a_screen_whose_first_hull_arrives_after_build_keeps_the_box_in_the_well() -> void:
	var screen := StatusScreenScript.new() as Control
	assert_true(screen != null, "the ship status screen builds")
	if screen == null:
		return
	screen.name = "FreshStatusScreen"
	_fixture_host().add_child(screen)
	screen.theme = HudTheme
	screen.call(&"apply_theme")
	screen.call(&"set_hull", VANGUARD)
	_assert_render_box_takes_the_well(screen, "first push")
	screen.queue_free()


## R1 HIGH-1's guard: the box the **last refresh** left, read before the modal is opened, is the
## sprite's own aspect-fit rect inside the left well. `Control.size` clamps up to
## `custom_minimum_size`, so the D6 320 x 320 minimum held the box oversized whenever the size was
## written before the minimum was lowered (R1 HIGH-1). The box is read from the laid-out
## `Control.size`, never `custom_minimum_size` - the two differ exactly in that stale state.
func _assert_render_box_takes_the_well(screen: Control, state: String) -> void:
	var render: TextureRect = screen.call(&"hull_render")
	assert_true(render.texture != null, "%s: a side cut is drawn before the modal opens" % state)
	var box := screen.find_child("HullRenderBox", true, false) as Control
	assert_true(box != null, "%s: the left column keeps its render box" % state)
	if render.texture == null or box == null:
		return
	var style: Resource = screen.call(&"style")
	var area: Rect2 = style.status_render_area()
	var native: Vector2 = render.texture.get_size()
	var fit: float = minf(area.size.x / native.x, area.size.y / native.y)
	var expected: Vector2 = native * fit
	var drawn_box := Rect2(box.position, box.size)
	assert_true(
		box.size.is_equal_approx(expected),
		"%s: the drawn box %s is the sprite's own aspect fit %s" % [state, box.size, expected]
	)
	assert_true(
		RENDER_WELL.encloses(drawn_box),
		"%s: the drawn sprite box %s sits inside the left well %s" % [state, drawn_box, RENDER_WELL]
	)


## The sprite's drawn space, re-derived the way `STRETCH_KEEP_ASPECT_CENTERED` draws it inside the
## render box, never from the screen's own render size. The box must take the sprite's aspect and
## never the row's height: an expanding box centred an aspect-fit sprite and left every marker off
## by the difference (R1-MED-1), so that flag is the property this helper guards. The drawn box is
## read from `Control.size`, **never** `custom_minimum_size`: `size` clamps up to the minimum, so
## the two differ exactly when a stale minimum held the box oversized - the class R1 HIGH-1 found
## (the D6 320 px pin), where the sprite drew past the well and every marker landed off-hull.
func _assert_markers_on_the_drawn_sprite(markers: Array, state: String) -> void:
	var render: TextureRect = _screen().call(&"hull_render")
	assert_true(render.texture != null, "%s: a side cut is drawn" % state)
	var box := _screen().find_child("HullRenderBox", true, false) as Control
	assert_true(box != null, "%s: the left column keeps its render box" % state)
	if render.texture == null or box == null:
		return
	assert_false(
		bool(box.size_flags_vertical & Control.SIZE_EXPAND),
		"%s: the render box takes the sprite's aspect, never the row's height" % state
	)
	var drawn_box := Rect2(box.position, box.size)
	assert_true(
		RENDER_WELL.encloses(drawn_box),
		"%s: the drawn sprite box %s sits inside the left well %s" % [state, drawn_box, RENDER_WELL]
	)
	var native: Vector2 = render.texture.get_size()
	var box_size: Vector2 = box.size
	var fit: float = minf(box_size.x / native.x, box_size.y / native.y)
	var drawn: Vector2 = native * fit
	var drawn_centre: Vector2 = (box_size - drawn) * 0.5 + drawn * 0.5
	assert_true(
		drawn.is_equal_approx(box_size),
		"%s: the aspect-fit sprite fills the box, so box-local is on-hull space" % state
	)
	var expected: Array[Vector2] = []
	for mode: StringName in [&"rear", &"front", &"left", &"right"]:
		for point: Vector2 in ShipFit.thruster_points(VANGUARD, mode):
			expected.append(drawn_centre + point * fit)
	for mount: Dictionary in ShipFit.weapon_mounts(VANGUARD):
		expected.append(drawn_centre + Vector2(mount[&"pos"]) * fit)
	assert_eq(markers.size(), expected.size(), "%s: one marker per HARDPOINTS anchor" % state)
	for i in range(mini(markers.size(), expected.size())):
		var pos: Vector2 = (markers[i] as Dictionary)[&"pos"]
		assert_true(
			pos.is_equal_approx(expected[i]),
			"%s: marker %d lands on the sprite's drawn centre plus its render px" % [state, i]
		)


## ---------------------------------------------------------------------------
## The footer
## ---------------------------------------------------------------------------


func test_the_footer_reads_the_pools_and_the_fitting_panels_power_arithmetic() -> void:
	var fit := _seed_vanguard_fit()
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_hud.call(&"_on_hull_changed", 812.0, 1000.0)
	_hud.call(&"_on_shield_changed", 240.0, 300.0)
	_open_screen()
	var footer: Dictionary = _screen().call(&"footer_lines")
	assert_eq(String(footer[&"hull"]), "HULL 812 / 1000", "HULL cur / max")
	assert_eq(String(footer[&"shield"]), "SHLD 240 / 300", "SHLD cur / max")
	## The reuse proof: the screen's POWER numbers are `ShipFit.fit_legal(hull, base_fit)[power]`
	## - the fitting panel's own `_power_of` - so both must agree cell for cell.
	var power: Dictionary = ShipFit.fit_legal(
		VANGUARD, _profile.call(&"base_fit", fit)
	)[&"power"]
	assert_eq(int(footer[&"draw"]), int(power[&"draw"]), "the draw is fit_legal's own")
	assert_eq(int(footer[&"out"]), int(power[&"out"]), "the capacity is fit_legal's own")
	assert_eq(
		String(footer[&"power"]),
		"PWR %d / %d" % [int(power[&"draw"]), int(power[&"out"])],
		"and the line is the fitting pane's own METER_IDLE wording"
	)
	var label: Label = _screen().find_child("PowerValue", true, false) as Label
	assert_true(label != null, "the power readout is a Label")
	assert_eq(label.text, String(footer[&"power"]), "the drawn text is the reading")
	assert_eq(label.theme_type_variation, &"HudReadout", "an 18 px HUD readout")


## ---------------------------------------------------------------------------
## The no-write proof
## ---------------------------------------------------------------------------


func test_the_screen_writes_nothing_to_the_profile() -> void:
	_seed_vanguard_fit()
	_hud.call(&"set_hull_slots", VANGUARD, [])
	_hud.call(&"_on_hull_changed", 640.0, 1000.0)
	_hud.call(&"_on_shield_changed", 120.0, 300.0)
	_profile.call(&"flush")
	var path := String(_profile.get(&"save_path"))
	var before := FileAccess.get_file_as_bytes(path)
	assert_true(before.size() > 0, "the scratch profile exists before the read")
	var before_fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var before_modules: Dictionary = _profile.call(&"modules")
	var before_credits := int(_profile.call(&"credits"))
	## Open, read every surface, toggle, close - the whole screen lifecycle.
	_open_screen()
	_screen().call(&"module_rows")
	_screen().call(&"grid_cells")
	_screen().call(&"footer_lines")
	_screen().call(&"hull_render_path")
	_screen().call(&"hardpoint_markers")
	_screen().call(&"toggle")
	_screen().call(&"toggle")
	_screen().call(&"close")
	assert_false(bool(_profile.get(&"_dirty")), "no write is left pending")
	var after := FileAccess.get_file_as_bytes(path)
	assert_eq(after.size(), before.size(), "the scratch profile's size is unchanged")
	assert_true(
		after == before,
		"the scratch profile's bytes are identical before and after the read"
	)
	assert_eq(
		_profile.call(&"fit_for", VANGUARD),
		before_fit,
		"the stored fit is unchanged"
	)
	assert_eq(_profile.call(&"modules"), before_modules, "the inventory is unchanged")
	assert_eq(int(_profile.call(&"credits")), before_credits, "the credits are unchanged")
