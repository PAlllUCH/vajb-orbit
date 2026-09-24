class_name ShipStatusScreen
extends Control
## UI_SPEC section 3.8 (amendment 2026-09-23, wave D6; **restyled 2026-09-24, wave D7 - the
## Mockup C block**) / CONTRACTS section 18: the ship status screen. A HUD-internal modal,
## hidden by default, in flight only, toggled by the `ship_status` action behind
## `InputMap.has_action`.
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
##   * the slot grid on the shipyard's own plate recipe (`ShipFit.grid_cells`, the
##     `SlotButtonWeapon` plate, the type's slot glyph inset, gaps as empty Controls);
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
##
## **D7 restyle (UI_SPEC section 3.8's Mockup C amendment + section 3.9's instrument language).**
## The D6 `ui_cockpit_frame` nine-slice body is replaced on screen by one painted console plate
## `ui_status_panel` (a FLAT plate, master 2x the 720 x 520 box, no nine-slice - UI_CHROME
## section 12 Amendment 2), its three wells **code-drawn** at the mockup's own 1:1 rects:
##
##   * left well (24,60)-(300,428): the hull side render **aspect-fit into the well** (the D6
##     320 px width pin is superseded by the mockup's well-fit) with the damaged-cut swap rule
##     unchanged, and the hardpoint markers as code-drawn **bone-ringed ember dots** (section
##     3.9 rule 4: state stays code-drawn over the painted face);
##   * right well (316,60)-(696,348): the hull's slot grid, cells 60 x 74 on a 72 x 88 pitch for
##     a 5 x 3 matrix (a larger matrix is scaled to fit rather than clipped - `status_grid_scale`),
##     the `W1..W5` refs as 10 px `SlotNumber` Labels, fitted modules as glyph plates;
##   * footer strip (24,444)-(696,494): `HULL` / `SHLD` / `PWR` `cur / max` `HudReadout` Labels
##     (the fitting panel's own power arithmetic, unchanged).
##
## **Every colour, layout metric and asset path comes from `CockpitStyle`** (section 3.9 rule 5,
## via `ui/hud/cockpit_style.gd`): a user `.tres` restyles and relayouts this screen with no code
## edit. The D6 nine-slice frame node survives (hidden) because `test_d6_status.gd` pins it - the
## "retire, do not delete" precedent the D7 cluster used for the old HUD column. Every D6
## behaviour row (toggle, dock guard, no-write proof, the read-only fits) is untouched.

const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
## The repairs pane's own render rule, reused as-is: `hull_render(ship_id, missing_hull)` is the
## `_side.png` -> `_damaged_side.png` swap, with its "intact when no damaged cut exists on disk"
## reading - never restated here.
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
## The fitted cell is a **slot** key in the fit's own spelling (09 section 1).
const WEAPONS_SLOT: StringName = &"weapons"
const POWER_SLOT: StringName = &"power"
const RACK_ORDINAL_MIN := 1

## UI_SPEC section 3.8's box, in the style's own `status_box` (the pinned 720 x 520, reversal
## 640 x 448). This constant is the fallback when no style is in force.
const MODAL_SIZE := Vector2(720.0, 520.0)

## Edge-on hulls are short; this is the box a hull with no renderable cut gets, so the layout
## cannot collapse to nothing on an unknown hull.
const RENDER_MISSING_SIZE := Vector2(320.0, 320.0)

## The shipyard's own plate recipe (STATION_HUB section 5.3, the FITTING precedent): a
## `SlotButtonWeapon` plate, the type's glyph inset, gaps as bare Controls. Duplicated
## byte-equivalently, exactly as the two station panes duplicate it; the cell's own size now
## comes from the style (Mockup C: 60 x 74 on a 72 x 88 pitch).
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"

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

## The modal's engine Labels (section 3.9 rule 3: words are Labels, never baked into art). The
## theme type variations carry the sizes; the style carries the point sizes.
const TITLE_TEXT := "SHIP STATUS"
const TITLE_VARIATION: StringName = &"StationPanelTitle"
const CAPTION_TEXT := "SLOT LAYOUT"
const CAPTION_VARIATION: StringName = &"StationCaption"
## The cell ref Labels: the weapon-slot number variation is exactly the pinned 10 px label.
const REF_VARIATION: StringName = &"SlotNumber"
## The footer readouts: the 18 px HUD readout (UI_SPEC section 3.8's own wording).
const FOOTER_VARIATION: StringName = &"HudReadout"

## UI_SPEC section 3.8's markers: bone-ringed ember dots, code-drawn, in the style's own
## colours. The geometry lives on the marker class below (an inner class cannot see these
## constants) - these are the shape names only.
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

const NODE_CENTER := "Center"
const NODE_BODY := "Body"
const NODE_FRAME := "Frame"
const NODE_PLATE := "StatusPlate"
const NODE_WELLS := "Wells"
const NODE_TITLE := "Title"
const NODE_RENDER_BOX := "HullRenderBox"
const NODE_RENDER := "HullRender"
const NODE_MARKERS := "HardpointMarkers"
const NODE_GRID := "SlotGrid"
const NODE_CAPTION := "SlotCaption"
const NODE_ROWS_BAND := "SlotRows"
const NODE_MODULE_ROWS := "ModuleRows"
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

var _style: Resource = null
var _body: Control = null
## The RETIRED D6 nine-slice frame: kept (hidden) because `test_d6_status.gd` pins its node.
var _frame: NinePatchRect = null
var _plate: TextureRect = null
var _wells: StatusWells = null
var _title: Label = null
var _render_box: Control = null
var _render: TextureRect = null
var _markers: HardpointMarkers = null
var _grid: GridContainer = null
var _caption: Label = null
var _rows_band: ScrollContainer = null
var _module_rows: VBoxContainer = null
var _hull_value: Label = null
var _shield_value: Label = null
var _power_value: Label = null
var _close: TextureButton = null

## The readings as drawn, so a probe can assert them without a screenshot (the section 3.7
## read-backs' precedent).
var _render_path: String = ""
## Seeded with the no-cut box, so the box is never a zero-size control before the first refresh;
## `_refresh_render` overwrites it with the drawn sprite's aspect-fit size.
var _render_size: Vector2 = RENDER_MISSING_SIZE
## The sprite's own scale as drawn: `HARDPOINTS`' values are render px relative to the sprite's
## centre, so a marker anchor is `centre + point * _render_scale`.
var _render_scale: float = 1.0
var _rows: Array[Dictionary] = []
var _footer: Dictionary = {}
var _cells: Array[Dictionary] = []
## One entry per drawn (non-gap) cell: its ref, the matrix position and the drawn widgets, so a
## probe can assert the Mockup C grid without a screenshot.
var _refs: Array[Dictionary] = []
## The matrix the drawn grid came from (columns, rows), so the style's derived geometry and the
## drawing agree.
var _matrix: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_build()
	visible = false


## Idempotent, so a re-`_ready` or a second call cannot double the chrome.
func _build() -> void:
	if _body != null:
		return
	if _style == null:
		_style = CockpitStyleScript.load_style()
	custom_minimum_size = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centre := CenterContainer.new()
	centre.name = NODE_CENTER
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_body = Control.new()
	_body.name = NODE_BODY
	_body.custom_minimum_size = MODAL_SIZE
	## The modal body is what eats a pointer over it; the screen's own full rect stays inert so
	## a hidden screen can never block the HUD (UI_SPEC section 3.2's MOUSE_FILTER rule).
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	centre.add_child(_body)
	_build_frame()
	_build_plate()
	_wells = StatusWells.new()
	_wells.name = NODE_WELLS
	_wells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wells.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.add_child(_wells)
	_build_title()
	_build_left_well()
	_build_right_well()
	_build_footer()
	_apply_style()
	_refresh_footer()


## The D6 nine-slice bezel, **retired**: section 3.8's amendment replaces it with the flat
## `ui_status_panel` plate, and `test_d6_status.gd` still pins this node's texture, patch band
## and half scale, so it stays in the tree hidden rather than deleted (the D7-C1 precedent for
## the old HUD column). Reversal: show it again and drop the plate.
func _build_frame() -> void:
	_frame = NinePatchRect.new()
	_frame.name = NODE_FRAME
	_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_frame.size = MODAL_SIZE * 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.visible = false
	_body.add_child(_frame)


## The painted console plate (section 3.9 rule 2: one flat painted panel, no nine-slice). The
## node scales to the box, so any master the style names is taken as-is.
func _build_plate() -> void:
	_plate = TextureRect.new()
	_plate.name = NODE_PLATE
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_plate)


## The title Label and the close box, top-right (Mockup C: `SHIP STATUS` at (30,22), a 26 x 26
## close box 52 px in from the right edge).
func _build_title() -> void:
	_title = Label.new()
	_title.name = NODE_TITLE
	_title.text = TITLE_TEXT
	_title.theme_type_variation = TITLE_VARIATION
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_title)
	_close = TextureButton.new()
	_close.name = NODE_CLOSE
	_close.ignore_texture_size = true
	_close.focus_mode = Control.FOCUS_NONE
	_close.pressed.connect(close)
	_body.add_child(_close)


## The left well: the render box (aspect-fit, the section 3.8 R1-MED-1 rule: the box takes the
## sprite's own aspect and never the row's height) with the hardpoint markers riding it.
func _build_left_well() -> void:
	_render_box = Control.new()
	_render_box.name = NODE_RENDER_BOX
	_render_box.custom_minimum_size = RENDER_MISSING_SIZE
	_render_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_render_box)
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


## The right well: the slot grid, the `SLOT LAYOUT` caption and the module rows band.
func _build_right_well() -> void:
	_grid = GridContainer.new()
	_grid.name = NODE_GRID
	_grid.columns = 1
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_grid)
	_caption = Label.new()
	_caption.name = NODE_CAPTION
	_caption.text = CAPTION_TEXT
	_caption.theme_type_variation = CAPTION_VARIATION
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_caption)
	_rows_band = ScrollContainer.new()
	_rows_band.name = NODE_ROWS_BAND
	_rows_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_rows_band)
	_module_rows = VBoxContainer.new()
	_module_rows.name = NODE_MODULE_ROWS
	_module_rows.add_theme_constant_override(&"separation", 2)
	_module_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows_band.add_child(_module_rows)


func _build_footer() -> void:
	_hull_value = _make_value(NODE_HULL_VALUE)
	_shield_value = _make_value(NODE_SHIELD_VALUE)
	_power_value = _make_value(NODE_POWER_VALUE)


func _make_value(node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.theme_type_variation = FOOTER_VARIATION
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(label)
	return label


## ---------------------------------------------------------------- the style (UI_SPEC 3.9 rule 5)

## Re-read the style into every child, in place: a user `.tres` restyles **and** relayouts the
## modal with no code edit, without rebuilding the tree.
func _apply_style() -> void:
	if _style == null or _body == null:
		return
	_body.custom_minimum_size = _style.status_box
	_apply_legacy_frame()
	_plate.texture = _style.texture(_style.status_panel_path)
	_wells.configure(_style, _plate.texture == null)
	_title.position = _style.status_title_pos
	_title.add_theme_font_size_override(&"font_size", _style.status_title_font_size)
	_close.texture_normal = _style.texture(_style.close_icon_path)
	_close.position = _style.status_close_rect().position
	_close.size = _style.status_close_size
	_place_render_box()
	_grid.position = _style.status_grid_origin()
	_caption.position = _style.status_caption_rect().position
	_caption.add_theme_font_size_override(&"font_size", _style.status_row_font_size)
	var rows: Rect2 = _style.status_rows_rect()
	_rows_band.position = rows.position
	_rows_band.size = rows.size
	for index: int in [_hull_value, _shield_value, _power_value].size():
		var label: Label = [_hull_value, _shield_value, _power_value][index]
		label.position = _style.status_footer_label_pos(index)
		label.size = Vector2(200.0, 24.0)


func _apply_legacy_frame() -> void:
	var texture: Texture2D = _style.texture(_style.status_legacy_frame_path)
	if texture == null:
		texture = load(_style.status_legacy_frame_path) as Texture2D
	_frame.texture = texture
	_frame.patch_margin_left = _style.status_legacy_frame_patch
	_frame.patch_margin_top = _style.status_legacy_frame_patch
	_frame.patch_margin_right = _style.status_legacy_frame_patch
	_frame.patch_margin_bottom = _style.status_legacy_frame_patch
	_frame.size = _style.status_box * 2.0
	_frame.scale = Vector2(_style.status_legacy_frame_scale, _style.status_legacy_frame_scale)


## The render box centred in the well's own fit area (the mockup's well-fit, which supersedes
## the D6 320 px width pin).
func _place_render_box() -> void:
	if _style == null or _render_box == null:
		return
	var area: Rect2 = _style.status_render_area()
	_render_box.size = _render_size
	_render_box.position = area.position + (area.size - _render_size) * 0.5
	_render_box.custom_minimum_size = _render_size


## The style in force (a probe read-back; section 3.9 rule 5).
func style() -> Resource:
	return _style


## Swap the whole style at runtime, from a `CockpitStyle` resource.
func set_style(style: Resource) -> void:
	if style == null:
		return
	_style = style
	if _body == null:
		return
	_apply_style()
	_refresh()


## Swap the style from a `.tres` path: the file the user drops in (`CockpitStyle.USER_PATH`) or
## any other style file. `load_style` falls back to the shipped defaults when it does not
## resolve.
func set_style_file(path: String) -> void:
	set_style(CockpitStyleScript.load_style(path))


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


## UI_SPEC section 3.8's left well: the side render, the damaged cut when damage is reported.
## The swap is `repairs_panel.gd`'s own `hull_render` - the suffix rule as the repairs pane
## applies it, with the same "intact when no damaged cut exists on disk" reading. The render is
## aspect-fit into the style's render area (Mockup C supersedes the D6 320 px width pin).
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
		## The render is drawn aspect-fit into the well, so the marker space is the sprite's own
		## frame scaled by the same factor - one derivation for the drawing and the read-back.
		var area: Vector2 = _style.status_render_area().size
		_render_scale = minf(area.x / native.x, area.y / native.y)
		_render_size = native * _render_scale
	_place_render_box()
	_refresh_markers(hull)


## UI_SPEC section 3.8: "overlaid hardpoint markers ... when `ShipFit.HARDPOINTS` carries the
## hull". `ShipFit.is_mapped` is the table's own `has()`, so the guard cannot drift from it; a
## hull with no row draws no marker and blocks on nothing.
func _refresh_markers(hull: StringName) -> void:
	var anchors: Array[Dictionary] = []
	if not hull.is_empty() and ShipFit.is_mapped(hull):
		anchors = _collect_markers(hull)
	_markers.configure(_style)
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


## UI_SPEC section 3.8's right well: the hull's slot grid, the shipyard's recipe cell for cell
## (`ShipFit.grid_cells` row-major, `columns` = the matrix width, a gap an empty Control), at
## the style's Mockup C cell geometry - 60 x 74 on a 72 x 88 pitch while the matrix fits, scaled
## to fit when a hull carries more (the whole matrix stays inside the well, never clipped). A
## non-gap cell draws its `W1..W5` ref Label and, when fitted, its module's own glyph plate.
func _refresh_grid(hull: StringName, fit: Dictionary) -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_cells.clear()
	_refs.clear()
	_matrix = Vector2i.ZERO
	if hull.is_empty() or ShipFit.grid_rows(hull).is_empty():
		_grid.columns = 1
		return
	_matrix = ShipFit.grid_size(hull)
	_grid.columns = _matrix.x
	_grid.position = _style.status_grid_origin()
	var cell_size: Vector2 = _style.status_cell_size_for(_matrix.x, _matrix.y)
	var gap: Vector2 = _style.status_cell_pitch_for(_matrix.x, _matrix.y) - cell_size
	## `GridContainer` separations are whole pixels and it rounds its own minimum size up, so the
	## gap is floored: the drawn matrix can then never overrun the well the style fitted it to
	## (a 5 x 3 matrix's 12 / 14 px gaps are whole anyway, so the pin is exact).
	_grid.add_theme_constant_override(&"h_separation", int(floor(gap.x)))
	_grid.add_theme_constant_override(&"v_separation", int(floor(gap.y)))
	for cell: Dictionary in ShipFit.grid_cells(hull):
		if bool(cell[&"gap"]):
			_grid.add_child(_make_gap_cell(cell_size))
			continue
		## `_make_slot_cell` parents its own plate (the shipyard's `_make_plate` convention).
		_make_slot_cell(cell, fit)


func _make_gap_cell(cell_size: Vector2) -> Control:
	var cell := Control.new()
	cell.name = "Gap"
	cell.custom_minimum_size = cell_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _make_slot_cell(cell: Dictionary, fit: Dictionary) -> TextureButton:
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var col := int(cell[&"col"])
	var row := int(cell[&"row"])
	var entry := _cell_entry(slot_key, index, fit)
	var base := _base_id(entry)
	var cell_name := "%s%02d" % [String(cell[&"token"]), index]
	var plate := TextureButton.new()
	plate.name = "Slot" + cell_name
	plate.theme_type_variation = PLATE_VARIATION
	plate.ignore_texture_size = true
	plate.custom_minimum_size = _style.status_cell_size_for(_matrix.x, _matrix.y)
	plate.focus_mode = Control.FOCUS_NONE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.disabled = base == &""
	_grid.add_child(plate)
	_apply_plate_textures(plate)
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := _cell_icon_path(slot_key, index, base)
	var glyph_texture: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		glyph_texture = load(path) as Texture2D
	glyph.texture = glyph_texture
	## The glyph's tint is the style's own (section 3.9 rule 5): a fitted module reads bright,
	## an empty cell dim - the shipyard's treatment, kept palette-neutral.
	glyph.modulate = _style.colour(&"text_primary" if base != &"" else &"text_dim")
	plate.add_child(glyph)
	_place_glyph(glyph, col, row)
	var ref := Label.new()
	ref.name = "Ref" + cell_name
	ref.text = "%s%d" % [String(cell[&"token"]), index + 1]
	ref.theme_type_variation = REF_VARIATION
	ref.add_theme_font_size_override(&"font_size", _style.status_ref_font_size)
	ref.add_theme_color_override(&"font_color", _style.colour(&"text_dim"))
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(ref)
	_place_ref(ref)
	_cells.append({
		&"token": String(cell[&"token"]),
		&"index": index,
		&"type": slot_key,
		&"module": base,
		&"icon": path,
		&"fitted": base != &"",
		&"col": col,
		&"row": row,
		&"rect": _style.status_cell_rect(col, row, _matrix.x, _matrix.y),
	})
	_refs.append({
		&"ref": ref.text,
		&"token": String(cell[&"token"]),
		&"index": index,
		&"type": slot_key,
		&"fitted": base != &"",
		&"col": col,
		&"row": row,
		&"rect": _style.status_cell_rect(col, row, _matrix.x, _matrix.y),
		&"label": ref,
		&"glyph": glyph,
		&"plate": plate,
	})
	return plate


## The fitted module glyph plate: the style's own 28 x 32 box centred under the ref zone of the
## cell (Mockup C's rounded stand-in is the module icon in the shipping surface).
func _place_glyph(glyph: TextureRect, col: int, row: int) -> void:
	var cell: Rect2 = _style.status_cell_rect(col, row, _matrix.x, _matrix.y)
	var target: Rect2 = _style.status_glyph_rect(col, row, _matrix.x, _matrix.y)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = target.position.x - cell.position.x
	glyph.offset_top = target.position.y - cell.position.y
	glyph.offset_right = -((cell.end.x) - target.end.x)
	glyph.offset_bottom = -((cell.end.y) - target.end.y)


## A cell's `W1..W5` ref Label (section 3.8's Mockup C block: "the `W1..W5` refs as 10 px
## Labels"), in the cell's top-left corner at the style's own inset.
func _place_ref(ref: Label) -> void:
	var inset: Vector2 = _style.status_ref_inset_for(_matrix.x, _matrix.y)
	var cell: Vector2 = _style.status_cell_size_for(_matrix.x, _matrix.y)
	ref.position = inset
	ref.size = Vector2(
		maxf(cell.x - inset.x * 2.0, 0.0), _style.status_ref_zone_for(_matrix.x, _matrix.y)
	)


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


## UI_SPEC section 3.8's module list, under the right well: one row per fitted module, its
## layout cell ref and its `ModuleCatalog` name. The cell set and the order are the grid's own
## (`ShipFit.grid_cells` row-major), so a row and its plate can never disagree.
func _refresh_module_rows() -> void:
	for child: Node in _module_rows.get_children():
		_module_rows.remove_child(child)
		child.queue_free()
	for row: Dictionary in _rows:
		var label := Label.new()
		label.name = "Row%s%02d" % [String(row[&"token"]), int(row[&"index"])]
		label.text = String(row[&"text"])
		label.theme_type_variation = CAPTION_VARIATION
		label.add_theme_font_size_override(&"font_size", _style.status_row_font_size)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_module_rows.add_child(label)


## The footer (UI_SPEC section 3.8): HULL/SHLD `cur / max` as 18 px readouts, and POWER draw
## over capacity from the fitting panel's own arithmetic.
func _refresh_footer() -> void:
	if _hull_value == null:
		return
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


## A theme change re-reads the style into the markers (the HUD calls this from `_notification`).
func apply_theme() -> void:
	if _markers != null:
		_markers.configure(_style)
		_markers.apply_theme()


## ---------------------------------------------------------------- the read-backs

## UI_SPEC section 3.8's box, from the style (the pinned 720 x 520, reversal 640 x 448).
func modal_size() -> Vector2:
	return _style.status_box if _style != null else MODAL_SIZE


func body() -> Control:
	return _body


## The RETIRED D6 nine-slice frame node (hidden; section 3.8's amendment replaces it with the
## flat plate). Kept because `test_d6_status.gd` pins it.
func frame() -> NinePatchRect:
	return _frame


## The painted console plate that replaced the frame (section 3.9 rule 2: one flat plate, no
## nine-slice).
func plate() -> TextureRect:
	return _plate


## The code-drawn wells, in paint order (the same list the painter walks).
func wells() -> Array[Rect2]:
	return _wells.well_rects() if _wells != null else []


func title_label() -> Label:
	return _title


func hull_render() -> TextureRect:
	return _render


func hull_render_path() -> String:
	return _render_path


func slot_grid() -> GridContainer:
	return _grid


## The matrix the drawn grid came from (columns, rows); `Vector2i.ZERO` when nothing is drawn.
func grid_matrix() -> Vector2i:
	return _matrix


func module_rows() -> Array[Dictionary]:
	return _rows


func grid_cells() -> Array[Dictionary]:
	return _cells


## One entry per drawn (non-gap) cell: `{ref, token, index, type, fitted, col, row, rect,
## label, glyph, plate}` - the Mockup C grid's own read-back.
func cell_refs() -> Array[Dictionary]:
	return _refs


func hardpoint_markers() -> Array[Dictionary]:
	return _markers.markers() if _markers != null else []


func footer_lines() -> Dictionary:
	return _footer


func close_button() -> TextureButton:
	return _close


## The status modal's three code-drawn wells (section 3.9 rule 2): the left render well and the
## right slot well as recesses (shadow on top/left, lit on bottom/right - the inverse of the
## raised bevel) and the footer strip as a raised ledge (Mockup C's own bevel). A probe reads
## `well_rects()` - the same list the painter walks, which is the style's `status_wells()`.
class StatusWells extends Control:
	var _style: Resource = null
	var _plate_missing: bool = false

	func configure(style: Resource, plate_missing: bool) -> void:
		_style = style
		_plate_missing = plate_missing
		queue_redraw()

	## The same list the style derives, so a probe and the painter cannot disagree.
	func well_rects() -> Array[Rect2]:
		if _style == null:
			return []
		return _style.status_wells()

	func _draw() -> void:
		if _style == null:
			return
		if _plate_missing:
			draw_rect(Rect2(Vector2.ZERO, _style.status_box), _style.colour(&"panel_steel"), true)
		_draw_recess(_style.status_well_left)
		_draw_recess(_style.status_well_right)
		_draw_raised(_style.status_footer)

	func _draw_recess(rect: Rect2) -> void:
		draw_rect(rect, _style.colour(&"void_base"), true)
		var dark: Color = _style.colour(&"metal_dark")
		var light: Color = _style.colour(&"metal_light")
		var width: float = _style.frame_width
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), dark, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), dark, width, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, light, width, true)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, light, width, true)

	## The footer ledge: the raised bevel (section 1's rule - light top/left, dark bottom/right),
	## no fill, so the label metal reads as the panel's own surface.
	func _draw_raised(rect: Rect2) -> void:
		var dark: Color = _style.colour(&"metal_dark")
		var light: Color = _style.colour(&"metal_light")
		var width: float = _style.frame_width
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), light, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), light, width, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, dark, width, true)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, dark, width, true)


## UI_SPEC section 3.8's overlaid markers as Mockup C restyles them: **bone-ringed ember dots**,
## code-drawn in the style's own colours over the painted render (section 3.9 rule 4 - state is
## code-drawn). The anchor space is the render box's own (`ShipFit.HARDPOINTS`' render px,
## origin at the sprite's centre, x right = bow, y down = starboard).
class HardpointMarkers extends Control:
	const TOKENS_TYPE: StringName = &"Tokens"
	const ROLE_RING: StringName = &"bone"
	const ROLE_FILL: StringName = &"accent_danger"

	var _markers: Array[Dictionary] = []
	var _size: Vector2 = Vector2.ZERO
	var _style: Resource = null
	var _ring_colour: Color = Color.WHITE
	var _fill_colour: Color = Color.WHITE
	var _radius: float = 5.0
	var _width: float = 1.0

	## The style in force; the dot's ring reads Bone and its core the ember (Mockup C's own
	## `ellipse(outline=BONE, fill=EMBER)`), so a restyle moves both.
	func configure(style: Resource) -> void:
		_style = style
		_apply_theme()
		queue_redraw()

	func set_markers(anchors: Array[Dictionary], box: Vector2) -> void:
		_markers = anchors.duplicate()
		_size = box
		queue_redraw()

	func markers() -> Array[Dictionary]:
		return _markers.duplicate()

	func marker_radius() -> float:
		return _radius

	func marker_width() -> float:
		return _width

	## The two drawn tones, so a probe can assert the bone-ringed ember read.
	func marker_colours() -> Dictionary:
		return {&"ring": _ring_colour, &"fill": _fill_colour}

	func apply_theme() -> void:
		_apply_theme()
		queue_redraw()

	func _apply_theme() -> void:
		if _style != null:
			_ring_colour = _style.colour(&"bone")
			_fill_colour = _style.colour(&"accent_danger")
			_radius = _style.status_marker_radius
			_width = _style.frame_width
			return
		## No style (a bare probe): the section 3.8 D6 roles, so the node is never blank.
		_ring_colour = _token(&"metal_light")
		_fill_colour = _token(&"text_dim")

	func _draw() -> void:
		if _markers.is_empty() or _size.x <= 0.0:
			return
		for marker: Dictionary in _markers:
			var pos: Vector2 = marker[&"pos"]
			draw_circle(pos, _radius, _fill_colour)
			draw_arc(pos, _radius, 0.0, TAU, 24, _ring_colour, _width, true)

	func _token(token: StringName) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE
