class_name ShipStatusScreen
extends Control
## UI_SPEC section 3.8 (amendment 2026-09-23, wave D6) / CONTRACTS section 18: the ship status
## screen. A HUD-internal modal ("computer screen with current ship layout"), hidden by default,
## in flight only, toggled by the `ship_status` action behind `InputMap.has_action`.
##
## Built in code by `ui/hud/hud.gd` in the section 7 inner-widget idiom (the pool blocks, the
## slice-2 widgets and the section 3.7 cluster's precedent); `hud.tscn` stays untouched. It
## **reads only** and writes nothing:
##
##   * the active hull's side render through `ui/station/repairs_panel.gd`'s own
##     `hull_render` static (its `_side.png` -> `_damaged_side.png` suffix rule, intact when no
##     damaged cut exists on disk) - the rule is reused, never restated;
##   * the fit the launch would fly, `PlayerProfile.resolved_fit`, translated to base ids
##     through `PlayerProfile.base_fit` exactly as the fitting panel translates it;
##   * the slot grid on the shipyard's own plate recipe (`ShipFit.grid_cells`, the 48 px
##     `SlotButtonWeapon` plate, the type's slot glyph inset 6 px, gaps as empty Controls);
##   * the module names and glyph paths from `ModuleCatalog` (through
##     `PlayerProfile.base_module_id`, the same bridge the fitting panel and the shipyard use);
##   * POWER draw / capacity from the fitting panel's own arithmetic,
##     `ShipFit.fit_legal(hull, base_fit)[power]` - the panel's `_power_of`;
##   * the hardpoint markers from `ShipFit.HARDPOINTS`, behind `ShipFit.is_mapped(hull)` (the
##     table's own `has()`), read-only and never a blocker on the wave that writes it.
##
## Per-module damage is not in the sim (measured 2026-09-23: damage is hull/shield only), so the
## screen lists the fitted modules with their layout cell ref and their powered presence; a
## module-condition model is staged for the owner's `18_engine_spec.md` pass.

const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_TEXT_PRIMARY: StringName = &"text_primary"
const TOKEN_TEXT_DIM: StringName = &"text_dim"

const PROFILE_SERVICE: StringName = &"PlayerProfile"
## The repairs pane's own render rule, reused as-is: `hull_render(ship_id, missing_hull)` is the
## `_side.png` -> `_damaged_side.png` swap, with its "intact when no damaged cut exists on disk"
## reading - never restated here.
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
## The fitted cell is a **slot** key in the fit's own spelling (09 section 1).
const WEAPONS_SLOT: StringName = &"weapons"
const POWER_SLOT: StringName = &"power"
const RACK_ORDINAL_MIN := 1

## UI_SPEC section 3.8's box (reversal: 640 x 448).
const MODAL_SIZE := Vector2(720.0, 520.0)
const MODAL_MARGIN := 24
const FOOTER_SEPARATION := 16
const COLUMN_SEPARATION := 12
const ROW_SEPARATION := 20
const INFO_SEPARATION := 8

## The section 3.7 nine-slice recipe (UI_CHROME section 11: one 192 x 192 master at 2x the
## logical box, section 10's law "display size stays logical", so the 64 px master band draws
## at half scale). One master, no size variant.
const FRAME_TEXTURE: Texture2D = preload("res://assets/ui/ui_cockpit_frame.png")
const FRAME_PATCH: int = 64
const FRAME_SCALE := 0.5

const CLOSE_TEXTURE: Texture2D = preload("res://assets/icons/hud/icon_close.svg")
const CLOSE_SIZE := Vector2(16.0, 16.0)

## UI_SPEC section 3.8: the left column is the side render at 320 px, the markers ride it.
const RENDER_WIDTH := 320.0
## Edge-on hulls are short; this is the box a hull with no renderable cut gets, so the layout
## cannot collapse to nothing on an unknown hull.
const RENDER_MISSING_SIZE := Vector2(320.0, 320.0)

## The shipyard's own plate recipe (STATION_HUB section 5.3, the FITTING precedent): a 48 px
## `SlotButtonWeapon` plate, the type's glyph inset 6 px, 4 px separation, gaps as bare
## Controls. Duplicated byte-equivalently, exactly as the two station panes duplicate it.
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
const PLATE_ICON_INSET := 6.0

## 09 section 1's slot glyph per slot-type key (the panes' own table, third copy of the pin).
const SLOT_GLYPHS: Dictionary = {
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

## UI_SPEC section 3.8's markers: 1 px code-drawn, thrusters as small triangles and weapon
## mounts as 3 px circles with a facing tick. The geometry itself lives on the marker class
## below (an inner class cannot see these constants) - this is the name of the shape only.
const MARKER_KIND_THRUSTER: StringName = &"thruster"
const MARKER_KIND_MOUNT: StringName = &"mount"
## `ShipFit.HARDPOINTS`' own thruster keys (09 section 11), in the table's reading order.
const THRUSTER_MODES: Array[StringName] = [&"rear", &"front", &"left", &"right"]

## One fitted module per row: its layout cell ref (`<TOKEN><n>`, 09 section 4.5's index + 1,
## the fitting panel's `SELECTION_FORMAT` prefix) and its `ModuleCatalog` name. A weapon cell
## the launch pushed through `set_hull_slots` adds its rack ordinal (that payload's `battery`,
## the 1-based rack the HUD's W-slot buttons address).
const MODULE_ROW_FORMAT := "%s%d · %s"
const MODULE_ROW_RACK_FORMAT := "%s%d · B%d · %s"

## UI_SPEC section 3.8's footer: HULL/SHLD `cur / max` as an 18 px `HudReadout`, POWER draw over
## capacity. The power line is the fitting panel's own `METER_IDLE` wording, reused verbatim.
const FOOTER_HULL_FORMAT := "HULL %d / %d"
const FOOTER_SHIELD_FORMAT := "SHLD %d / %d"
const FOOTER_POWER_FORMAT := "PWR %d / %d"

const NODE_FRAME := "Frame"
const NODE_MARGIN := "Margin"
const NODE_ROW := "Row"
const NODE_RENDER_BOX := "HullRenderBox"
const NODE_RENDER := "HullRender"
const NODE_MARKERS := "HardpointMarkers"
const NODE_INFO := "Info"
const NODE_GRID := "SlotGrid"
const NODE_MODULE_ROWS := "ModuleRows"
const NODE_FOOTER := "Footer"
const NODE_HULL_VALUE := "HullValue"
const NODE_SHIELD_VALUE := "ShieldValue"
const NODE_POWER_VALUE := "PowerValue"
const NODE_CLOSE := "Close"

var _docked: bool = false
var _hull_id: StringName = &""
var _hull_current: float = 0.0
var _hull_max: float = 0.0
var _shield_current: float = 0.0
var _shield_max: float = 0.0

## The `set_hull_slots` payload the HUD last pushed (its W cells, keyed by layout index), so a
## weapon cell's ref and rack read the launch's own cells rather than a second derivation.
var _pushed_cells: Dictionary = {}

var _body: Control = null
var _frame: NinePatchRect = null
var _render_box: Control = null
var _render: TextureRect = null
var _markers: HardpointMarkers = null
var _grid: GridContainer = null
var _module_rows: VBoxContainer = null
var _hull_value: Label = null
var _shield_value: Label = null
var _power_value: Label = null
var _close: TextureButton = null

## The readings as drawn, so a probe can assert them without a screenshot (the section 3.7
## read-backs' precedent).
var _render_path: String = ""
var _render_size: Vector2 = Vector2.ZERO
## The sprite's own scale as drawn: `HARDPOINTS`' values are render px relative to the sprite's
## centre, so a marker anchor is `centre + point * _render_scale`.
var _render_scale: float = 1.0
var _rows: Array[Dictionary] = []
var _footer: Dictionary = {}
var _cells: Array[Dictionary] = []


func _ready() -> void:
	_build()
	visible = false


## Idempotent, so a re-`_ready` or a second call cannot double the chrome.
func _build() -> void:
	if _body != null:
		return
	custom_minimum_size = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centre := CenterContainer.new()
	centre.name = "Center"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_body = Control.new()
	_body.name = "Body"
	_body.custom_minimum_size = MODAL_SIZE
	## The modal body is what eats a pointer over it; the screen's own full rect stays inert so
	## a hidden screen can never block the HUD (UI_SPEC section 3.2's MOUSE_FILTER rule).
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	centre.add_child(_body)
	_build_frame()
	var margin := MarginContainer.new()
	margin.name = NODE_MARGIN
	margin.add_theme_constant_override(&"margin_left", MODAL_MARGIN)
	margin.add_theme_constant_override(&"margin_top", MODAL_MARGIN)
	margin.add_theme_constant_override(&"margin_right", MODAL_MARGIN)
	margin.add_theme_constant_override(&"margin_bottom", MODAL_MARGIN)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	_build_row(column)
	_build_footer(column)


## The nine-slice bezel, added before everything else so the content draws on top of it. The
## master's 64 px band draws at 32 logical px: the node is scaled to half, the section 3.7
## recipe verbatim.
func _build_frame() -> void:
	_frame = NinePatchRect.new()
	_frame.name = NODE_FRAME
	_frame.texture = FRAME_TEXTURE
	_frame.patch_margin_left = FRAME_PATCH
	_frame.patch_margin_top = FRAME_PATCH
	_frame.patch_margin_right = FRAME_PATCH
	_frame.patch_margin_bottom = FRAME_PATCH
	_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_frame.size = MODAL_SIZE * 2.0
	_frame.scale = Vector2(FRAME_SCALE, FRAME_SCALE)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_frame)


func _build_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.name = NODE_ROW
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	_render_box = Control.new()
	_render_box.name = NODE_RENDER_BOX
	_render_box.custom_minimum_size = RENDER_MISSING_SIZE
	_render_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_render_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_render_box)
	_render = TextureRect.new()
	_render.name = NODE_RENDER
	_render.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_render.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_render.set_anchors_preset(Control.PRESET_FULL_RECT)
	_render.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_render_box.add_child(_render)
	_markers = HardpointMarkers.new()
	_markers.name = NODE_MARKERS
	_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_render_box.add_child(_markers)
	var info := VBoxContainer.new()
	info.name = NODE_INFO
	info.add_theme_constant_override(&"separation", INFO_SEPARATION)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	_grid = GridContainer.new()
	_grid.name = NODE_GRID
	_grid.columns = 1
	_grid.add_theme_constant_override(&"h_separation", PLATE_SEPARATION)
	_grid.add_theme_constant_override(&"v_separation", PLATE_SEPARATION)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_grid)
	_module_rows = VBoxContainer.new()
	_module_rows.name = NODE_MODULE_ROWS
	_module_rows.add_theme_constant_override(&"separation", 2)
	_module_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_module_rows)


func _build_footer(parent: Node) -> void:
	var footer := HBoxContainer.new()
	footer.name = NODE_FOOTER
	footer.add_theme_constant_override(&"separation", FOOTER_SEPARATION)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(footer)
	_hull_value = _make_value(footer, NODE_HULL_VALUE)
	_shield_value = _make_value(footer, NODE_SHIELD_VALUE)
	_power_value = _make_value(footer, NODE_POWER_VALUE)
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(spacer)
	_close = TextureButton.new()
	_close.name = NODE_CLOSE
	_close.ignore_texture_size = true
	_close.texture_normal = CLOSE_TEXTURE
	_close.custom_minimum_size = CLOSE_SIZE
	_close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_close.focus_mode = Control.FOCUS_NONE
	_close.pressed.connect(close)
	footer.add_child(_close)


func _make_value(parent: Node, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.theme_type_variation = &"HudReadout"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## ---------------------------------------------------------------- the toggle (UI_SPEC 3.8)

## Open or close the modal. Closed while docked: the screen is in flight only, and a docked HUD
## that is asked to open it stays hidden rather than drawing a dead modal. Opening re-reads the
## profile and the pushed pools, so the layout shown is always the current one.
func set_open(wanted: bool) -> void:
	var shown: bool = wanted and not _docked
	if shown:
		_refresh()
	visible = shown
	_markers_visible()


func open() -> void:
	set_open(true)


func close() -> void:
	set_open(false)


func toggle() -> bool:
	set_open(not visible)
	return visible


func is_open() -> bool:
	return visible


## UI_SPEC section 3.8: "in flight only (hidden while docked like section 3.7)". The dock route
## replaces the game scene, so nothing in production calls this today; it is the seam that makes
## the rule expressible and testable. Reversal: delete the flag and the two guards.
func set_docked(active: bool) -> void:
	_docked = active
	if active:
		close()


func docked() -> bool:
	return _docked


## ---------------------------------------------------------------- the HUD's pushes

## CONTRACTS section 11's `set_hull_slots` cells, keyed by layout index: the W cells the launch
## pushed, so a weapon row's ref and rack read the launch's own payload.
func set_hull_slots(cells: Array) -> void:
	_pushed_cells = {}
	for value: Variant in cells:
		if value is Dictionary:
			_pushed_cells[int((value as Dictionary).get(&"index", -1))] = value
	_refresh()


## The launched hull, pushed with the W cells; empty falls back to `PlayerProfile.active_ship()`
## (a probe-mounted HUD with no launch).
func set_hull(hull_id: StringName) -> void:
	if hull_id == _hull_id:
		return
	_hull_id = hull_id
	_refresh()


## The live pools the HUD already holds, so the footer cannot disagree with the bars above it.
func set_pools(
	hull_current: float, hull_max: float, shield_current: float, shield_max: float
) -> void:
	_hull_current = maxf(hull_current, 0.0)
	_hull_max = maxf(hull_max, 0.0)
	_shield_current = maxf(shield_current, 0.0)
	_shield_max = maxf(shield_max, 0.0)
	_refresh_footer()


## ---------------------------------------------------------------- the refresh

func _refresh() -> void:
	if _body == null:
		return
	var hull := _active_hull()
	var fit := _resolved_fit(hull)
	_refresh_render(hull)
	_refresh_grid(hull, fit)
	_rows = _collect_rows(hull, fit)
	_refresh_module_rows()
	_refresh_footer()


## UI_SPEC section 3.8's left column: the side render, the damaged cut when damage is reported.
## The swap is `repairs_panel.gd`'s own `hull_render` - the suffix rule as the repairs pane
## applies it, with the same "intact when no damaged cut exists on disk" reading.
func _refresh_render(hull: StringName) -> void:
	var missing := int(round(maxf(_hull_max - _hull_current, 0.0)))
	_render_path = String(RepairsPanelScript.hull_render(hull, missing))
	var texture: Texture2D = null
	if not _render_path.is_empty() and ResourceLoader.exists(_render_path):
		texture = load(_render_path) as Texture2D
	_render.texture = texture
	_render_scale = 1.0
	if texture == null:
		_render_size = RENDER_MISSING_SIZE
	else:
		var native := texture.get_size()
		## The render is drawn at the pinned 320 px width, so the marker space is the sprite's
		## own frame scaled by the same factor - one derivation for the drawing and the
		## read-back.
		_render_scale = RENDER_WIDTH / native.x
		_render_size = Vector2(RENDER_WIDTH, native.y * _render_scale)
	_render_box.custom_minimum_size = _render_size
	_refresh_markers(hull)


## UI_SPEC section 3.8: "overlaid hardpoint markers ... when `ShipFit.HARDPOINTS` carries the
## hull". `ShipFit.is_mapped` is the table's own `has()`, so the guard cannot drift from it; a
## hull with no row draws no marker and blocks on nothing.
func _refresh_markers(hull: StringName) -> void:
	var anchors: Array[Dictionary] = []
	if not hull.is_empty() and ShipFit.is_mapped(hull):
		anchors = _collect_markers(hull)
	_markers.set_markers(anchors, _render_size)
	_markers_visible()


func _markers_visible() -> void:
	if _markers != null:
		_markers.visible = visible and not _markers.markers().is_empty()


## The marker anchors in the render box's own coordinates (its centre is the sprite's centre,
## x right = bow, y down = the hull's starboard - 09 section 11's own frame), so the drawing and
## the read-back are one derivation.
func _collect_markers(hull: StringName) -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	var centre: Vector2 = _render_size * 0.5
	var render_scale := _render_scale
	for mode: StringName in THRUSTER_MODES:
		for point: Vector2 in ShipFit.thruster_points(hull, mode):
			markers.append({
				&"kind": MARKER_KIND_THRUSTER,
				&"mode": mode,
				&"pos": centre + point * render_scale,
				&"facing": 0.0,
			})
	for mount: Dictionary in ShipFit.weapon_mounts(hull):
		markers.append({
			&"kind": MARKER_KIND_MOUNT,
			&"mode": &"",
			&"pos": centre + Vector2(mount.get(&"pos", Vector2.ZERO)) * render_scale,
			&"facing": float(mount.get(&"facing", 0.0)),
		})
	return markers


## UI_SPEC section 3.8's right column, first half: the hull's slot grid, the shipyard's recipe
## cell for cell (`ShipFit.grid_cells` row-major, `columns` = the matrix width, a gap an empty
## 48 px Control). A fitted cell draws its module's own glyph, an empty slot the type's slot
## glyph dimmed - the shipyard's treatment, kept palette-neutral.
func _refresh_grid(hull: StringName, fit: Dictionary) -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_cells.clear()
	if hull.is_empty() or ShipFit.grid_rows(hull).is_empty():
		_grid.columns = 1
		return
	_grid.columns = ShipFit.grid_size(hull).x
	for cell: Dictionary in ShipFit.grid_cells(hull):
		if bool(cell[&"gap"]):
			_grid.add_child(_make_gap_cell())
			continue
		## `_make_slot_cell` parents its own plate (the shipyard's `_make_plate` convention).
		_make_slot_cell(cell, fit)


func _make_gap_cell() -> Control:
	var cell := Control.new()
	cell.name = "Gap"
	cell.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _make_slot_cell(cell: Dictionary, fit: Dictionary) -> TextureButton:
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var entry := _cell_entry(slot_key, index, fit)
	var base := _base_id(entry)
	var plate := TextureButton.new()
	plate.name = "Slot%s%02d" % [String(cell[&"token"]), index]
	plate.theme_type_variation = PLATE_VARIATION
	plate.ignore_texture_size = true
	plate.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	plate.focus_mode = Control.FOCUS_NONE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.disabled = base == &""
	_grid.add_child(plate)
	_apply_plate_textures(plate)
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.custom_minimum_size = Vector2(
		PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0
	)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := _cell_icon_path(slot_key, index, base)
	var glyph_texture: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		glyph_texture = load(path) as Texture2D
	glyph.texture = glyph_texture
	glyph.modulate = _token(TOKEN_TEXT_PRIMARY if base != &"" else TOKEN_TEXT_DIM)
	plate.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = PLATE_ICON_INSET
	glyph.offset_top = PLATE_ICON_INSET
	glyph.offset_right = -PLATE_ICON_INSET
	glyph.offset_bottom = -PLATE_ICON_INSET
	_cells.append({
		&"token": String(cell[&"token"]),
		&"index": index,
		&"type": slot_key,
		&"module": base,
		&"icon": path,
		&"fitted": base != &"",
	})
	return plate


## The `SlotButtonWeapon` look, copied off the theme's styleboxes exactly as the two station
## panes copy it (a TextureButton has no stylebox items, so a bare `theme_type_variation` is
## never read by the engine).
func _apply_plate_textures(plate: TextureButton) -> void:
	plate.texture_normal = _plate_texture(PLATE_VARIATION, &"normal")
	plate.texture_hover = _plate_texture(PLATE_VARIATION, &"hover")
	plate.texture_pressed = _plate_texture(PLATE_VARIATION, &"pressed")
	plate.texture_disabled = _plate_texture(PLATE_VARIATION, &"disabled")


func _plate_texture(variation: StringName, state: StringName) -> Texture2D:
	if not has_theme_stylebox(state, variation):
		return null
	var box := get_theme_stylebox(state, variation)
	if box is StyleBoxTexture:
		return (box as StyleBoxTexture).texture
	return null


## UI_SPEC section 3.8's right column, second half: one row per fitted module, its layout cell
## ref and its `ModuleCatalog` name. The cell set and the order are the grid's own
## (`ShipFit.grid_cells` row-major), so a row and its plate can never disagree.
func _refresh_module_rows() -> void:
	for child: Node in _module_rows.get_children():
		_module_rows.remove_child(child)
		child.queue_free()
	for row: Dictionary in _rows:
		var label := Label.new()
		label.name = "Row%s%02d" % [String(row[&"token"]), int(row[&"index"])]
		label.text = String(row[&"text"])
		label.theme_type_variation = &"StationCaption"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_module_rows.add_child(label)


## The footer (UI_SPEC section 3.8): HULL/SHLD `cur / max` above an 18 px readout, and POWER
## draw over capacity from the fitting panel's own arithmetic.
func _refresh_footer() -> void:
	var hull := _active_hull()
	var power := _power_of(hull, _resolved_fit(hull))
	var draws := int(power.get(&"draw", 0))
	var out := int(power.get(&"out", 0))
	var hull_line := FOOTER_HULL_FORMAT % [int(round(_hull_current)), int(round(_hull_max))]
	var shield_line := FOOTER_SHIELD_FORMAT % [int(round(_shield_current)), int(round(_shield_max))]
	var power_line := FOOTER_POWER_FORMAT % [draws, out]
	_hull_value.text = hull_line
	_shield_value.text = shield_line
	_power_value.text = power_line
	_footer = {
		&"hull": hull_line,
		&"shield": shield_line,
		&"power": power_line,
		&"draw": draws,
		&"out": out,
	}


## ---------------------------------------------------------------- the readings

func _active_hull() -> StringName:
	if not _hull_id.is_empty():
		return _hull_id
	var profile := _profile()
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _resolved_fit(hull: StringName) -> Dictionary:
	var profile := _profile()
	if profile == null or hull.is_empty():
		return {}
	var fit: Variant = profile.call(&"resolved_fit", hull)
	if fit is Dictionary:
		return fit
	return {}


## `PlayerProfile.base_fit`, the translation every fit judgement goes through (a fit cell holds
## an instance id and `ShipFit` reads base ids) - the fitting panel's own bridge.
func _base_fit(fit: Dictionary) -> Dictionary:
	var profile := _profile()
	if profile == null:
		return fit
	var translated: Variant = profile.call(&"base_fit", fit)
	if translated is Dictionary:
		return translated
	return fit


## The fitting panel's `_power_of`: `ShipFit.fit_legal(hull, base_fit)[power]`, reused verbatim.
func _power_of(hull: StringName, fit: Dictionary) -> Dictionary:
	if hull.is_empty():
		return {&"out": 0, &"draw": 0, &"spare": 0, &"legal": false}
	return ShipFit.fit_legal(hull, _base_fit(fit))[&"power"]


## `PlayerProfile.base_module_id`, the bridge the panes name modules through; an entry the bag
## does not carry comes back unchanged.
func _base_id(entry: StringName) -> StringName:
	var profile := _profile()
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


## One fit cell's module: a W cell the launch pushed uses the pushed module (that payload is the
## grid's own record of which cells are fitted), every other cell reads the fit in
## `fit_for`'s shape (`power` is one id, every list type is an array - the panes' own read).
func _cell_entry(slot_key: StringName, index: int, fit: Dictionary) -> StringName:
	if slot_key == WEAPONS_SLOT and _pushed_cells.has(index):
		return StringName(String((_pushed_cells[index] as Dictionary).get(&"module", "")))
	if slot_key == POWER_SLOT:
		var single: Variant = fit.get(slot_key, fit.get(String(slot_key), ""))
		if single is Array:
			for value: Variant in single as Array:
				if String(value) != "":
					return StringName(String(value))
			return &""
		return StringName(String(single)) if single != null else &""
	var raw: Variant = fit.get(slot_key, fit.get(String(slot_key), []))
	if not raw is Array:
		return &""
	var cells: Array = raw as Array
	if index < 0 or index >= cells.size():
		return &""
	return StringName(String(cells[index]))


## The glyph a cell draws: the launch's own icon when it pushed one, else the base id's
## catalogue icon, else the type's slot glyph - the HUD's own `_weapon_cell_icon` precedence.
func _cell_icon_path(slot_key: StringName, index: int, base: StringName) -> String:
	if slot_key == WEAPONS_SLOT and _pushed_cells.has(index):
		var pushed := String((_pushed_cells[index] as Dictionary).get(&"icon", ""))
		if not pushed.is_empty():
			return pushed
	if base != &"":
		var path := ModuleCatalog.icon_path(base)
		if not path.is_empty():
			return path
	var stem := String(SLOT_GLYPHS.get(slot_key, ""))
	if stem.is_empty():
		return ""
	return SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem


## One row per fitted cell, in the grid's order: the layout cell ref (`<TOKEN><n>`, the fitting
## panel's `SELECTION_FORMAT` prefix), the rack ordinal a pushed W cell carries, the module id
## and the `ModuleCatalog` name.
func _collect_rows(hull: StringName, fit: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if hull.is_empty():
		return rows
	for cell: Dictionary in ShipFit.grid_cells(hull):
		if bool(cell[&"gap"]):
			continue
		var slot_key: StringName = cell[&"type"]
		var index := int(cell[&"index"])
		var entry := _cell_entry(slot_key, index, fit)
		if entry == &"":
			continue
		var base := _base_id(entry)
		var token := String(cell[&"token"])
		var rack := 0
		if slot_key == WEAPONS_SLOT and _pushed_cells.has(index):
			rack = int((_pushed_cells[index] as Dictionary).get(&"battery", 0))
		var name_text := String(ModuleCatalog.module(base).get(&"name", String(base)))
		var text := MODULE_ROW_FORMAT % [token, index + 1, name_text]
		if rack >= RACK_ORDINAL_MIN:
			text = MODULE_ROW_RACK_FORMAT % [token, index + 1, rack, name_text]
		rows.append({
			&"token": token,
			&"index": index,
			&"ref": "%s%d" % [token, index + 1],
			&"rack": rack,
			&"module": entry,
			&"base": base,
			&"name": name_text,
			&"base_name": String(ModuleCatalog.module(base).get(&"name", "")),
			&"text": text,
		})
	return rows


func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _token(token: StringName) -> Color:
	if not token.is_empty() and has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## A theme change re-reads the marker tokens (the HUD calls this from `_notification`).
func apply_theme() -> void:
	if _markers != null:
		_markers.apply_theme()


## ---------------------------------------------------------------- the read-backs

## UI_SPEC section 3.8's box, the nine-slice body a test measures against.
func modal_size() -> Vector2:
	return MODAL_SIZE


func body() -> Control:
	return _body


func frame() -> NinePatchRect:
	return _frame


func hull_render() -> TextureRect:
	return _render


func hull_render_path() -> String:
	return _render_path


func slot_grid() -> GridContainer:
	return _grid


func module_rows() -> Array[Dictionary]:
	return _rows


func grid_cells() -> Array[Dictionary]:
	return _cells


func hardpoint_markers() -> Array[Dictionary]:
	return _markers.markers() if _markers != null else []


func footer_lines() -> Dictionary:
	return _footer


func close_button() -> TextureButton:
	return _close


## UI_SPEC section 3.8's overlaid markers, code-drawn in their theme tokens. The anchor space is
## the render box's own (`ShipFit.HARDPOINTS`' render px, origin at the sprite's centre, x right
## = bow, y down = starboard), scaled to the 320 px render - the same derivation the read-back
## hands out.
class HardpointMarkers extends Control:
	const TOKENS_TYPE: StringName = &"Tokens"
	const TOKEN_THRUSTER: StringName = &"text_dim"
	const TOKEN_MOUNT: StringName = &"metal_light"
	## UI_SPEC section 3.8's marker geometry, repeated here because an inner class cannot see the
	## enclosing class's constants (the limitation `weapons.gd`'s `ChaffGhost` documents).
	const WIDTH := 1.0
	const TRIANGLE := 5.0
	const MOUNT_RADIUS := 3.0
	const TICK := 6.0

	var _markers: Array[Dictionary] = []
	var _size: Vector2 = Vector2.ZERO
	var _thruster_colour: Color = Color.WHITE
	var _mount_colour: Color = Color.WHITE

	func set_markers(anchors: Array[Dictionary], box: Vector2) -> void:
		_markers = anchors.duplicate()
		_size = box
		queue_redraw()

	func markers() -> Array[Dictionary]:
		return _markers.duplicate()

	func apply_theme() -> void:
		## UI_SPEC section 3.8 names the two tokens without splitting them, so the mounts read
		## brighter than the thrusters; reversal: both `text_dim`.
		_thruster_colour = _token(TOKEN_THRUSTER)
		_mount_colour = _token(TOKEN_MOUNT)
		queue_redraw()

	func _draw() -> void:
		if _markers.is_empty() or _size.x <= 0.0:
			return
		for marker: Dictionary in _markers:
			var pos: Vector2 = marker[&"pos"]
			if StringName(marker[&"kind"]) == &"mount":
				draw_arc(pos, MOUNT_RADIUS, 0.0, TAU, 16, _mount_colour, WIDTH, true)
				var facing := float(marker.get(&"facing", 0.0))
				draw_line(pos, pos + Vector2.RIGHT.rotated(facing) * TICK, _mount_colour, WIDTH)
				continue
			var points := PackedVector2Array([
				pos + Vector2(0.0, -TRIANGLE),
				pos + Vector2(TRIANGLE * 0.8, TRIANGLE * 0.8),
				pos + Vector2(-TRIANGLE * 0.8, TRIANGLE * 0.8),
				pos + Vector2(0.0, -TRIANGLE),
			])
			draw_polyline(points, _thruster_colour, WIDTH)

	func _token(token: StringName) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE
