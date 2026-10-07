@tool
extends McpTestSuite
## Suite s36_chrome_census: wave S36's one true-aspect chrome family (UI_SPEC section 15).
##
## The station is mounted the way `test_s30_shell.gd` mounts it (the shipped scene, the
## shipped theme, the profile borrowed and handed back). The suite only ADDS rows; it never
## touches the keep-list surfaces it asserts.
##
## Four assertion groups, one per S36_BRIEF acceptance:
##   (a) class-aspect  - every swap-map class cut's aspect equals its class master within 1 %
##                       (the rails draw at their slot rects; the canvas is the cut's aspect).
##   (b) no-smear      - every nine-slice plate carries the N51 measured margins and a canvas
##                       class draws the whole cut uniformly (no band stretch).
##   (c) keep-group    - the keep-list surfaces stand shipped (textures, sizes, native styles).
##   (d) backdrops     - BG-1..4 sit behind the pane content, cover-fit, mouse_filter IGNORE.
##
## Reversal: the family retires and the swap-map surfaces return to their shipped plates.

const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s36_chrome_census.cfg"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"

## The swap-map classes and their true-aspect masters (UI_SPEC section 15.1/15.3). C9's
## landed rail is the band's max (360x56), not section 15.1's 272 nominal; the builder
## reports that doc/cut mismatch (bucket 2) and wires the landed art.
const CLASS_MASTERS := {
	"C1": Vector2(567.0, 140.0),
	"C2": Vector2(360.0, 56.0),
	"C3": Vector2(96.0, 32.0),
	"C4": Vector2(560.0, 76.0),
	"C5": Vector2(260.0, 192.0),
	"C6": Vector2(1360.0, 516.0),
	"C7": Vector2(360.0, 240.0),
	"C9": Vector2(360.0, 56.0),
	"C12": Vector2(96.0, 96.0),
}
const ASPECT_TOLERANCE := 0.01

## N51 measured margins (cut px), left/right/top/bottom - the order R1's
## `probe_s36_r1_measure.py` publishes as "lrtb"; the max of its two methods.
const MEASURED_MARGINS := {
	"C3": Vector4(24.0, 34.0, 23.0, 39.0),
	"C4": Vector4(74.0, 74.0, 35.0, 49.0),
	"C7": Vector4(22.0, 43.0, 50.0, 64.0),
}

## The keep-list surfaces and their shipped cut sizes (UI_SPEC section 15.6 keep-restore).
const KEEP_TEXTURES := {
	"res://assets/ui/ui_slot_weapon_normal.png": Vector2(48.0, 48.0),
	"res://assets/ui/ui_bar_caps.png": Vector2(42.0, 14.0),
	"res://assets/ui/ui_minimap_bezel.png": Vector2(200.0, 200.0),
}
const PLATE_TEXTURE := "res://assets/ui/ui_button_plate_normal.png"

var _profile: ProfileScript = null
var _station: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_credits := 0


func suite_name() -> String:
	return "s36_chrome_census"


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
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)


func suite_teardown() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
		_station = null
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


## A fresh shell per row under a themed host, added to the profile autoload (the runner
## calls every test from inside its own `_ready`, when `/root` is still busy).
func _mount() -> Control:
	var host := Control.new()
	host.name = "S36Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	_settle(screen)
	return screen


## Force a synchronous container sort so geometry reads the laid-out frame (the armory's
## own `_flush_layout` idiom).
func _settle(node: Node) -> void:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Container:
			(current as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
		for child: Node in current.get_children():
			stack.append(child)


func _switch(screen: Control, deck: int) -> void:
	screen.call(&"_select_module", deck, true)
	_settle(screen)


func _pane(screen: Control, deck: int) -> Node:
	var panes := screen.get(&"_panels") as Array
	if deck < 0 or deck >= panes.size():
		return null
	return panes[deck] as Node


func _aspect(size: Vector2) -> float:
	return size.x / maxf(size.y, 0.001)


func _aspect_close(a: float, b: float) -> bool:
	if b <= 0.0:
		return false
	return absf(a - b) / b <= ASPECT_TOLERANCE


func _stylebox_texture(box: StyleBox) -> String:
	if box is StyleBoxTexture:
		var tex := (box as StyleBoxTexture).texture
		return tex.resource_path if tex != null else ""
	return ""


## ============================================================== (a) class-aspect


## Every swap-map class cut exists and its aspect equals its class master within 1 %.
func test_a_every_class_cut_matches_its_master_aspect() -> void:
	for cls: String in CLASS_MASTERS:
		var cut := ChromeFamily.cut_texture(cls)
		assert_true(cut != null, "%s cut resolves (%s)" % [cls, ChromeFamily.cut_path(cls)])
		if cut == null:
			continue
		var master: Vector2 = CLASS_MASTERS[cls]
		assert_true(
			_aspect_close(_aspect(cut.get_size()), _aspect(master)),
			"%s cut aspect %.4f == master %s aspect %.4f"
				% [cls, _aspect(cut.get_size()), str(master), _aspect(master)]
		)


## The OVERVIEW tile draws the C1 cut as a uniform canvas (the drawn rect is the cut's
## aspect, never a stretch): the canvas is aspect-preserving and pointer-transparent.
func test_a_the_tile_draws_the_c1_canvas_at_its_own_aspect() -> void:
	var screen := _mount()
	var tile := _find(screen, "ArmoryTile") as Button
	assert_true(tile != null, "the OVERVIEW ARMORY tile ships")
	if tile == null:
		return
	var canvas := tile.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
	assert_true(canvas != null, "the tile carries its C1 chrome canvas")
	if canvas == null:
		return
	assert_eq(
		canvas.texture.resource_path, ChromeFamily.cut_path("C1"), "the C1 ui_tile_slab cut"
	)
	assert_eq(
		canvas.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
		"drawn uniformly (the pad canvas is the look, never cropped to fill)"
	)
	assert_eq(canvas.mouse_filter, Control.MOUSE_FILTER_IGNORE, "and never eats the pointer")
	var slot := Vector2(567.0, 140.0)
	var drawn := ChromeFamily.canvas_rect(slot, "C1")
	assert_true(
		_aspect_close(_aspect(drawn.size), ChromeFamily.cut_aspect("C1")),
		"the drawn rect keeps the cut's aspect"
	)


## The drawer entry draws the C9 rail cut as a uniform canvas at its slot rect.
func test_a_the_drawer_entry_draws_the_c9_canvas() -> void:
	var screen := _mount()
	var entries := screen.call(&"drawer_entries") as Array
	assert_true(entries.size() > 0, "the drawer has entries")
	if entries.is_empty():
		return
	var entry := entries[0] as Button
	var canvas := entry.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
	assert_true(canvas != null, "the entry carries its C9 chrome canvas")
	if canvas == null:
		return
	assert_eq(
		canvas.texture.resource_path, ChromeFamily.cut_path("C9"), "the C9 ui_drawer_entry cut"
	)
	assert_eq(
		canvas.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "drawn uniformly"
	)
	var drawn := ChromeFamily.canvas_rect(entry.custom_minimum_size, "C9")
	assert_true(
		_aspect_close(_aspect(drawn.size), ChromeFamily.cut_aspect("C9")),
		"the drawn rect keeps the cut's aspect"
	)


## ============================================================== (b) no-smear


## Every nine-slice plate carries the N51 measured margins (the max of the two methods), at
## cut scale. The box's (l, t, r, b) is the table's (l, r, t, b) re-ordered (F1, S36-F1).
func test_b_the_nine_slice_plates_carry_the_measured_margins() -> void:
	for cls: String in MEASURED_MARGINS:
		var box := ChromeFamily.stylebox(cls)
		assert_true(box != null, "%s builds a nine-slice plate" % cls)
		if box == null:
			continue
		var want: Vector4 = MEASURED_MARGINS[cls]
		assert_true(
			box.texture_margin_left > 0.0 and box.texture_margin_top > 0.0,
			"%s holds its ornament inside a non-zero margin (caps never stretch)" % cls
		)
		assert_eq(
			Vector4(
				box.texture_margin_left, box.texture_margin_top,
				box.texture_margin_right, box.texture_margin_bottom
			),
			Vector4(want.x, want.z, want.y, want.w),
			"%s margins are the measured N51 values" % cls
		)


## S36-F1 (F1, the units cure): the wired nine-slice margins scale from the measured cut-px
## table to each surface's drawn rect, and the guard keeps every margin pair under the rect
## (the engine has no centre branch below the margins sum - never draw in that regime).
func test_b_the_nine_slice_margins_scale_and_never_degenerate() -> void:
	for case: Array in [
		["C3", Vector2(96.0, 32.0)],
		["C4", Vector2(338.0, 76.0)],
		["C4", Vector2(1756.0, 76.0)],
		["C7", Vector2(360.0, 134.0)],
	]:
		var cls: String = case[0]
		var size: Vector2 = case[1]
		var box := ChromeFamily.stylebox(cls, size)
		assert_true(box != null, "%s builds a scaled plate at %s" % [cls, str(size)])
		if box == null:
			continue
		var lr: float = box.texture_margin_left + box.texture_margin_right
		var tb: float = box.texture_margin_top + box.texture_margin_bottom
		assert_true(
			lr < size.x, "%s at %s: horizontal margins %.0f < %.0f" % [cls, str(size), lr, size.x]
		)
		assert_true(
			tb < size.y, "%s at %s: vertical margins %.0f < %.0f" % [cls, str(size), tb, size.y]
		)
		assert_eq(
			Vector4(
				box.texture_margin_left, box.texture_margin_top,
				box.texture_margin_right, box.texture_margin_bottom
			),
			ChromeFamily.drawn_margins(cls, size),
			"%s at %s wears the drawn-space margins" % [cls, str(size)]
		)


## A canvas class (C1/C2/C5/C9) carries no nine-slice: the whole cut is drawn uniformly.
func test_b_the_canvas_classes_have_no_nine_slice() -> void:
	for cls: String in ["C1", "C2", "C5", "C9"]:
		assert_true(
			ChromeFamily.stylebox(cls) == null,
			"%s is a canvas class (no nine-slice plate)" % cls
		)
		var canvas := ChromeFamily.make_canvas(cls)
		assert_true(canvas != null, "%s builds a uniform canvas" % cls)
		if canvas != null:
			assert_eq(
				canvas.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
				"%s canvas is aspect-preserving" % cls
			)
			canvas.free()


## The action bars (C2) wired in the panes draw the whole cut uniformly, never a band
## stretch; the SELL/CANCEL keep-list pressables stay native (asserted in group c).
func test_b_the_action_bars_draw_the_c2_canvas() -> void:
	var screen := _mount()
	_switch(screen, StationScript.Module.SHIPYARD)
	var shipyard := _pane(screen, StationScript.Module.SHIPYARD)
	assert_true(shipyard != null, "the SHIPYARD pane mounts")
	if shipyard == null:
		return
	for member: StringName in [&"_repair_button", &"_action"]:
		var button := shipyard.get(member) as Button
		assert_true(button != null, "SHIPYARD carries %s" % member)
		if button == null:
			continue
		var canvas := button.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
		assert_true(canvas != null, "%s wears a C2 canvas" % member)
		if canvas != null:
			assert_eq(
				canvas.texture.resource_path, ChromeFamily.cut_path("C2"),
				"%s draws the C2 ui_action_bar cut" % member
			)
		var normal := button.get_theme_stylebox(&"normal")
		assert_true(
			normal is StyleBoxEmpty, "%s normal state is the empty plate (the canvas draws)" % member
		)


## The pane row strips draw the C4 nine-slice; the tooltip draws the C7 nine-slice.
func test_b_the_rows_and_the_tooltip_wear_their_nine_slice() -> void:
	var screen := _mount()
	var row := _find(screen, "ContractsRow") as Button
	assert_true(row != null, "the OVERVIEW CONTRACTS row ships")
	if row != null:
		assert_eq(
			_stylebox_texture(row.get_theme_stylebox(&"normal")), ChromeFamily.cut_path("C4"),
			"the service row wears the C4 ui_row_strip"
		)
	var identity := _find(screen, "IdentityBlock") as PanelContainer
	assert_true(identity != null, "the OVERVIEW identity block ships")
	if identity != null:
		assert_true(
			identity.get_theme_stylebox(&"panel") is StyleBoxFlat,
			"the identity block keeps its flat Tokens box (the faction border is code)"
		)
	var chip := _find(screen, "RepairChip") as Button
	assert_true(chip != null, "the OVERVIEW REPAIR chip ships")
	if chip != null:
		assert_eq(
			_stylebox_texture(chip.get_theme_stylebox(&"normal")), ChromeFamily.cut_path("C3"),
			"the chip wears the C3 ui_inline_chip"
		)
	var tooltip := screen.get(&"_tooltip") as PanelContainer
	assert_true(tooltip != null, "the tooltip ships")
	if tooltip != null:
		var box := tooltip.get_theme_stylebox(&"panel")
		assert_eq(
			_stylebox_texture(box), ChromeFamily.cut_path("C7"),
			"the tooltip frame wears the C7 ui_tooltip_frame"
		)
		if box is StyleBoxTexture:
			## F1/S36-F1: the C7 margins scale to the tooltip's drawn rect; F4 restores the
			## tooltip's text inset as the box's top/bottom content margin (the C7 bevel).
			var sbt := box as StyleBoxTexture
			assert_eq(
				Vector4(
					sbt.texture_margin_left, sbt.texture_margin_top,
					sbt.texture_margin_right, sbt.texture_margin_bottom
				),
				ChromeFamily.drawn_margins("C7", tooltip.size),
				"at the drawn-space C7 margins"
			)
			assert_eq(sbt.content_margin_top, MEASURED_MARGINS["C7"].z, "the C7 text inset top")
			assert_eq(
				sbt.content_margin_bottom, MEASURED_MARGINS["C7"].w, "the C7 text inset bottom"
			)


## ============================================================== (c) keep-group


## The keep-list textures stand at their shipped cut sizes (UI_SPEC section 15.6).
func test_c_the_keep_list_textures_stand_shipped() -> void:
	for path: String in KEEP_TEXTURES:
		var tex := load(path) as Texture2D
		assert_true(tex != null, "%s resolves" % path)
		if tex == null:
			continue
		assert_eq(tex.get_size(), KEEP_TEXTURES[path], "%s stands at its shipped size" % path)


## The drawer SURFACE, the CANCEL/SELL pressables and the main-menu chrome stay native.
func test_c_the_native_styles_stay_on_the_keep_list() -> void:
	var screen := _mount()
	var plate := screen.get(&"_drawer_plate") as PanelContainer
	assert_true(plate != null, "the drawer plate ships")
	if plate != null:
		var panel := plate.get_theme_stylebox(&"panel")
		assert_true(
			panel is StyleBoxTexture,
			"the drawer SURFACE stays native PanelRaised (never the family plate)"
		)
	var cancel := _find(screen, "LeaveCancel") as Button
	assert_true(cancel != null, "the STAY DOCKED pressable ships")
	if cancel != null:
		assert_eq(cancel.theme_type_variation, &"StationButton", "it stays a StationButton")
	_switch(screen, StationScript.Module.EXCHANGE)
	var exchange := _pane(screen, StationScript.Module.EXCHANGE)
	assert_true(exchange != null, "the EXCHANGE pane mounts")
	if exchange != null:
		for member: StringName in [&"_sell", &"_sell_all", &"_cancel"]:
			var button := exchange.get(member) as Button
			assert_true(button != null, "EXCHANGE carries %s" % member)
			if button == null:
				continue
			assert_eq(button.theme_type_variation, &"StationButton", "%s stays native" % member)
			assert_eq(
				_stylebox_texture(button.get_theme_stylebox(&"normal")), PLATE_TEXTURE,
				"%s keeps the shipped ui_button_plate_* plate" % member
			)


## The main-menu chrome keeps the shipped button plate (owner: "keep the chromes from
## main menu").
func test_c_the_main_menu_chrome_keeps_its_plate() -> void:
	var theme := ThemeRes
	var box := theme.get_stylebox(&"normal", &"MenuButtonPlate")
	assert_true(box is StyleBoxTexture, "the main-menu button plate stays a StyleBoxTexture")
	if box is StyleBoxTexture:
		assert_eq(
			_stylebox_texture(box), PLATE_TEXTURE, "at the shipped ui_button_plate_* texture"
		)


## ============================================================== (d) backdrops


## The four BG layers exist on the pane content, behind it, cover-fit and pointer-transparent.
func test_d_the_four_backdrops_sit_behind_the_content_cover_fit() -> void:
	var screen := _mount()
	var backdrops := screen.get(&"_backdrops") as Dictionary
	assert_eq(backdrops.size(), 4, "one layer per BG id (BG-1..4)")
	var host := screen.get_node("%ModuleHost") as PanelContainer
	var content_index := (host.get_node("%HostMargin") as Control).get_index()
	for bg_id: String in ChromeFamily.BG_CUTS:
		assert_true(backdrops.has(bg_id), "%s layer exists" % bg_id)
		if not backdrops.has(bg_id):
			continue
		var layer := backdrops[bg_id] as TextureRect
		assert_true(layer != null, "%s is a TextureRect layer" % bg_id)
		if layer == null:
			continue
		assert_eq(
			layer.texture.resource_path, ChromeFamily.CUT_DIR + String(ChromeFamily.BG_CUTS[bg_id]),
			"%s carries its own backdrop cut" % bg_id
		)
		assert_eq(
			layer.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED,
			"%s cover-fits (1765:753, no stretch)" % bg_id
		)
		assert_eq(
			layer.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"%s never interferes with hit-testing" % bg_id
		)
		assert_true(
			layer.get_index() < content_index, "%s draws behind the pane content" % bg_id
		)
		assert_true(
			layer.size.x >= ChromeFamily.BG_BOX.x and layer.size.y >= ChromeFamily.BG_BOX.y,
			"%s covers the 1765x753 content box (got %s)" % [bg_id, str(layer.size)]
		)


## The active deck shows its own BG layer and only that one (BG-1 ARMORY, BG-2 REFINERY,
## BG-3 EXCHANGE+AUCTION, BG-4 SHIPYARD+LAUNCH+OVERVIEW).
func test_d_the_active_deck_shows_its_assigned_backdrop() -> void:
	var screen := _mount()
	var backdrops := screen.get(&"_backdrops") as Dictionary
	for deck: int in [0, 1, 2, 3, 4, 5, 6]:
		_switch(screen, deck)
		var active := String(StationScript.DECK_BACKDROP.get(deck, ""))
		for bg_id: String in backdrops:
			var layer := backdrops[bg_id] as CanvasItem
			assert_eq(
				layer.visible, bg_id == active,
				"deck %d shows only %s" % [deck, active]
			)


## The first descendant with the given node name (a recursive name match).
func _find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	for child: Node in root.find_children(node_name, "", true, false):
		return child
	return null
