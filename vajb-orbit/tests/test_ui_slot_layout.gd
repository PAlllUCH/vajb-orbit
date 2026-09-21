@tool
extends McpTestSuite
## Suite ui_slot_layout: the UI-chrome wave's D3 guard.
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

const VIEWPORT_WIDTH_SETTING := "display/window/size/viewport_width"
const VIEWPORT_HEIGHT_SETTING := "display/window/size/viewport_height"
const FALLBACK_VIEWPORT := Vector2(1920.0, 1080.0)

const WEAPON_CELL := Vector2(48.0, 48.0)
const CARGO_CELL := Vector2(40.0, 40.0)
const WEAPON_VARIATION: StringName = &"SlotButtonWeapon"
const CARGO_VARIATION: StringName = &"SlotButtonCargo"

const HARDPOINT_CELLS := 7
const CARGO_CELLS := 5
const HARDPOINT_SEPARATION := 4.0
const CARGO_SEPARATION := 6.0
const HUD_CARGO_CELLS := 40
const HUGE_ART := Vector2(4096.0, 4096.0)

## Every site the guard has to hold, with the literal it has to carry: the component scene,
## the component's `configure()`, the two station panels' `_make_plate()` and the HUD's two
## builders (the last holds the literal twice, once per builder).
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

	print(
		"[ui_slot_layout] slot component: weapon art %s -> cell %s, cargo art %s -> cell %s"
		% [weapon_art, WEAPON_CELL, cargo_art, CARGO_CELL]
	)


## ---------------------------------------------------------------------------
## SHIPYARD: 7 x 48 and a panel that fits the frame
## ---------------------------------------------------------------------------


func test_the_hardpoint_strip_is_seven_48px_cells() -> void:
	var panel := _mount(ShipyardScene)
	assert_true(panel != null, "shipyard_panel.tscn instantiates")
	var strip: HBoxContainer = panel.get(&"_hardpoints")
	assert_true(strip != null, "the hardpoint strip exists")
	assert_eq(strip.get_child_count(), HARDPOINT_CELLS, "seven hardpoint plates")

	var separation: float = float(strip.get_theme_constant(&"separation"))
	assert_eq(separation, HARDPOINT_SEPARATION, "the documented 4 px separation")
	for index: int in strip.get_child_count():
		var plate := strip.get_child(index) as TextureButton
		assert_true(plate != null, "plate %d is a TextureButton" % (index + 1))
		assert_true(plate.ignore_texture_size, "plate %d ignores its texture size" % (index + 1))
		assert_eq(plate.custom_minimum_size, WEAPON_CELL, "plate %d keeps the 48 px cell" % (index + 1))
		assert_eq(
			plate.get_combined_minimum_size(),
			WEAPON_CELL,
			"plate %d measures 48 px (art %s)" % [(index + 1), _plate_art(plate)]
		)

	var expected: float = (
		float(HARDPOINT_CELLS) * WEAPON_CELL.x
		+ float(HARDPOINT_CELLS - 1) * separation
	)
	assert_eq(strip.get_combined_minimum_size().x, expected, "the strip is 7 x 48 + 6 x 4 = 360")

	var viewport := viewport_size()
	var measured: Vector2 = panel.get_combined_minimum_size()
	var art: Vector2 = _plate_art(strip.get_child(0) as TextureButton)
	print(
		"[ui_slot_layout] shipyard: strip %s (art %s), panel minimum %s, viewport %s"
		% [strip.get_combined_minimum_size(), art, measured, viewport]
	)
	assert_true(
		measured.x <= viewport.x,
		"the shipyard panel minimum %s must fit the %s viewport" % [measured, viewport]
	)


func test_oversized_plate_art_cannot_grow_the_shipyard_panel() -> void:
	var panel := _mount(ShipyardScene)
	var strip: HBoxContainer = panel.get(&"_hardpoints")
	var before: Vector2 = panel.get_combined_minimum_size()
	var art := _huge_art()
	for child: Node in strip.get_children():
		_push_art(child as TextureButton, art)
	var strip_after: Vector2 = strip.get_combined_minimum_size()
	var after: Vector2 = panel.get_combined_minimum_size()
	var expected: float = (
		float(HARDPOINT_CELLS) * WEAPON_CELL.x
		+ float(HARDPOINT_CELLS - 1) * HARDPOINT_SEPARATION
	)
	print(
		"[ui_slot_layout] shipyard with %s art: strip %s, panel %s (before %s)"
		% [HUGE_ART, strip_after, after, before]
	)
	assert_eq(strip_after.x, expected, "a %s plate cannot widen one 48 px cell" % HUGE_ART)
	assert_eq(after, before, "a %s plate cannot move the panel minimum" % HUGE_ART)


## ---------------------------------------------------------------------------
## LAUNCH: 5 x 40 and a panel that fits the frame
## ---------------------------------------------------------------------------


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
## The in-flight HUD, which paints the same two plates
## ---------------------------------------------------------------------------


func test_the_hud_slot_cells_keep_their_cell_sizes() -> void:
	var hud := _mount(HudScene)
	assert_true(hud != null, "hud.tscn instantiates")
	var weapons: Array = hud.get(&"_weapon_slots")
	assert_eq(weapons.size(), 5, "five weapon cells")
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

	print(
		"[ui_slot_layout] hud: 5 x %s (art %s) and %d x %s (art %s)"
		% [WEAPON_CELL, weapon_art, HUD_CARGO_CELLS, CARGO_CELL, cargo_art]
	)
