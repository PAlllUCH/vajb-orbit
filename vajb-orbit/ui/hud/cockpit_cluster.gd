class_name CockpitCluster
extends Control
## UI_SPEC section 3.7 (amendment 2026-09-23, wave D6) / CONTRACTS section 18: the cockpit
## instrument cluster. It replaces the bare section 3.6 dial with the same dial inside a
## framed three-bay cluster: left bay the unchanged 120 x 120 gauge, middle bay the compass
## rose + the HDG readout, right bay the five segmented readout rows on `ui_readout_glass`.
##
## Built in code by `ui/hud/hud.gd` in the section 7 inner-widget idiom (the pool blocks and
## the slice-2 widgets' precedent); `hud.tscn` stays untouched. It derives everything from
## the feeds section 7 already carries - `set_speedometer(ratio, prograde, heading)` and
## `set_pool(kind, value, maximum)` plus the hull/shield handlers - so the wave introduces
## **zero new feeds**. The speedometer itself is `Hud.Speedometer` (an inner class of the HUD,
## byte-identical contract), handed to the left bay by the HUD, because this file must not
## reference the HUD class back.
##
## State colours are never baked: the digits stay palette-neutral (UI_SPEC section 3.2's
## precedent) and only the row label and a script-drawn 1 px frame carry a danger read.
## Tokens come from the cascading theme; a theme change re-reads them (`apply_theme`).

const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_TEXT_DIM: StringName = &"text_dim"
const TOKEN_DANGER: StringName = &"accent_danger"
const TOKEN_DANGER_BRIGHT: StringName = &"accent_danger_bright"

## UI_SPEC section 3.7: the cluster box and the three bays (reversal 340 x 184 compact).
const CLUSTER_SIZE := Vector2(404.0, 216.0)
const GAUGE_SIZE := Vector2(120.0, 120.0)
const COMPASS_SIZE := Vector2(96.0, 96.0)
## UI_CHROME section 11's `ui_readout_glass` logical box (136 x 190), the right bay plate.
const GLASS_SIZE := Vector2(136.0, 190.0)
const BAY_SEPARATION := 20
const BAY_SEPARATION_TIGHT := 2

const FRAME_TEXTURE: Texture2D = preload("res://assets/ui/ui_cockpit_frame.png")
const GLASS_TEXTURE: Texture2D = preload("res://assets/ui/ui_readout_glass.png")
## UI_CHROME section 11 ships one master per sprite at **2x its logical box** (the D2 ruling:
## no `@2x` families) and section 10's law is "display size stays logical ... renders it at
## half scale", so the frame's 64 px master band draws at 32 logical px: the nine-slice node
## carries the master's 64 px patch margins and is scaled to half.
const FRAME_PATCH: int = 64
const FRAME_SCALE := 0.5

## UI_SPEC section 3.7's digit semantics (CONTRACTS section 18 repeats them verbatim).
## SPD is 4 cells like every other row (owner amendment 2026-09-24), so it clamps 0..9999.
const SPD_MAX: int = 9999
const POINTS_MAX: int = 9999
const PCT_MAX: int = 100
const HULL_DANGER_FRACTION: float = 0.25
const FUEL_DANGER_FRACTION: float = 0.15
## UI_SPEC section 3.6/3.7: the overdrive read is strict (`ratio > 0.9`).
const OVERDRIVE: float = 0.9

const ROW_SPD: StringName = &"spd"
const ROW_HULL: StringName = &"hull"
const ROW_SHLD: StringName = &"shld"
const ROW_FUEL: StringName = &"fuel"
const ROW_ENRG: StringName = &"enrg"
const ROW_HDG: StringName = &"hdg"

const POOL_FUEL: StringName = &"fuel"
const POOL_ENERGY: StringName = &"energy"

const BAY_GAUGE := "GaugeBay"
const BAY_MID := "MidBay"
const BAY_READOUT := "ReadoutBay"
const NODE_FRAME := "CockpitFrame"
const NODE_COMPASS := "Compass"
const NODE_GLASS := "ReadoutGlass"
const NODE_ROWS := "ReadoutRows"

var _gauge_bay: Control = null
var _compass: Compass = null
var _rows: Dictionary = {}
var _row_order: Array[ReadoutRow] = []
var _hdg_row: ReadoutRow = null

## The readings as drawn (post-clamp), so a probe can assert them without a screenshot.
var _ratio: float = 0.0
var _compass_heading: float = 0.0
var _spd: int = 0
var _hull: int = 0
var _shield: int = 0
var _fuel_pct: int = 0
var _energy_pct: int = 0

## The raw pools, kept for the danger rows only (the digits are the clamped ints above).
var _hull_current: float = 0.0
var _hull_max: float = 0.0
var _shield_current: float = 0.0
var _shield_max: float = 0.0
var _fuel_current: float = 0.0
var _fuel_max: float = 0.0
var _energy_current: float = 0.0
var _energy_max: float = 0.0


func _ready() -> void:
	_build()


## Idempotent, so a re-`_ready` or a second call cannot double the bays.
func _build() -> void:
	if _gauge_bay != null:
		return
	custom_minimum_size = CLUSTER_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frame()
	var bays := HBoxContainer.new()
	bays.name = "Bays"
	bays.alignment = BoxContainer.ALIGNMENT_CENTER
	bays.add_theme_constant_override(&"separation", BAY_SEPARATION)
	bays.set_anchors_preset(Control.PRESET_FULL_RECT)
	bays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bays)
	_build_gauge_bay(bays)
	_build_middle_bay(bays)
	_build_readout_bay(bays)


## The nine-slice bezel, drawn under everything (added first, so later children draw on top).
func _build_frame() -> void:
	var frame := NinePatchRect.new()
	frame.name = NODE_FRAME
	frame.texture = FRAME_TEXTURE
	frame.patch_margin_left = FRAME_PATCH
	frame.patch_margin_top = FRAME_PATCH
	frame.patch_margin_right = FRAME_PATCH
	frame.patch_margin_bottom = FRAME_PATCH
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.size = CLUSTER_SIZE * 2.0
	frame.scale = Vector2(FRAME_SCALE, FRAME_SCALE)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)


## The left bay holds the unchanged section 3.6 dial; `hud.gd` attaches it here.
func _build_gauge_bay(parent: Node) -> void:
	_gauge_bay = Control.new()
	_gauge_bay.name = BAY_GAUGE
	_gauge_bay.custom_minimum_size = GAUGE_SIZE
	_gauge_bay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gauge_bay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_gauge_bay)


## The middle bay: the 96 x 96 rose and the 3-cell HDG readout beneath it.
func _build_middle_bay(parent: Node) -> void:
	var mid := VBoxContainer.new()
	mid.name = BAY_MID
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_theme_constant_override(&"separation", BAY_SEPARATION_TIGHT)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(mid)
	_compass = Compass.new()
	_compass.name = NODE_COMPASS
	_compass.custom_minimum_size = COMPASS_SIZE
	_compass.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_compass)
	_hdg_row = _add_row(mid, ROW_HDG, "HDG", 3, false)


## The right bay: the glass plate behind the five readout rows.
func _build_readout_bay(parent: Node) -> void:
	var right := Control.new()
	right.name = BAY_READOUT
	right.custom_minimum_size = GLASS_SIZE
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(right)
	var glass := TextureRect.new()
	glass.name = NODE_GLASS
	glass.texture = GLASS_TEXTURE
	glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glass.stretch_mode = TextureRect.STRETCH_SCALE
	glass.set_anchors_preset(Control.PRESET_FULL_RECT)
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(glass)
	var rows := VBoxContainer.new()
	rows.name = NODE_ROWS
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override(&"separation", BAY_SEPARATION_TIGHT)
	rows.set_anchors_preset(Control.PRESET_FULL_RECT)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(rows)
	_add_row(rows, ROW_SPD, "SPD", 4, false)
	_add_row(rows, ROW_HULL, "HULL", 4, false)
	_add_row(rows, ROW_SHLD, "SHLD", 4, false)
	_add_row(rows, ROW_FUEL, "FUEL", 3, true)
	_add_row(rows, ROW_ENRG, "ENRG", 3, true)


func _add_row(
	parent: Node, key: StringName, label_text: String, cells: int, percent: bool
) -> ReadoutRow:
	var row := ReadoutRow.new()
	row.name = String(key)
	row.configure(label_text, cells, percent)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(row)
	_rows[key] = row
	_row_order.append(row)
	return row


## The left bay, so `hud.gd` can attach the section 3.6 dial it owns.
func gauge_bay() -> Control:
	return _gauge_bay


## CONTRACTS section 18's read-back (here and on the HUD, the same seam): the cluster itself.
func cockpit() -> Control:
	return self


## CONTRACTS section 18's read-back: the compass bay.
func compass() -> Control:
	return _compass


## CONTRACTS section 18's read-back: the ship's heading 0..359 as the HDG row draws it.
func compass_heading() -> float:
	return _compass_heading


## CONTRACTS section 18's read-back: the five clamped ints the digits show.
func readouts() -> Dictionary:
	return {
		"spd": _spd,
		"hull": _hull,
		"shield": _shield,
		"fuel_pct": _fuel_pct,
		"energy_pct": _energy_pct,
	}


## UI_SPEC section 3.6's reading, section 3.7's cluster derivation: `ratio` drives the
## overdrive read, `prograde` the SPD digits (its length in u/s) and `heading` both the
## compass rotation and the HDG digits.
func set_speedometer(ratio: float, prograde: Vector2, heading: Vector2) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_spd = clampi(int(round(clampf(prograde.length(), 0.0, float(SPD_MAX)))), 0, SPD_MAX)
	_compass_heading = _map_heading(heading)
	if _compass != null:
		_compass.set_heading(heading.angle())
	var spd_row: ReadoutRow = _rows.get(ROW_SPD, null)
	if spd_row != null:
		spd_row.set_digits(_spd)
	if _hdg_row != null:
		_hdg_row.set_digits(int(_compass_heading))
	_apply_danger()


func set_hull(current: float, maximum: float) -> void:
	_hull_current = maxf(current, 0.0)
	_hull_max = maxf(maximum, 0.0)
	_hull = clampi(int(round(clampf(_hull_current, 0.0, float(POINTS_MAX)))), 0, POINTS_MAX)
	var hull_row: ReadoutRow = _rows.get(ROW_HULL, null)
	if hull_row != null:
		hull_row.set_digits(_hull)
	_apply_danger()


func set_shield(current: float, maximum: float) -> void:
	_shield_current = maxf(current, 0.0)
	_shield_max = maxf(maximum, 0.0)
	_shield = clampi(int(round(clampf(_shield_current, 0.0, float(POINTS_MAX)))), 0, POINTS_MAX)
	var shield_row: ReadoutRow = _rows.get(ROW_SHLD, null)
	if shield_row != null:
		shield_row.set_digits(_shield)
	_apply_danger()


## Section 3.1b's two pool feeds, `kind` being `&"fuel"` or `&"energy"`; an unknown kind is
## ignored, exactly as `hud.gd::set_pool` ignores one.
func set_pool(kind: StringName, current: float, maximum: float) -> void:
	var value: float = maxf(current, 0.0)
	var cap: float = maxf(maximum, 0.0)
	if kind == POOL_FUEL:
		_fuel_current = value
		_fuel_max = cap
		_fuel_pct = _percent(value, cap)
		var fuel_row: ReadoutRow = _rows.get(ROW_FUEL, null)
		if fuel_row != null:
			fuel_row.set_digits(_fuel_pct)
	elif kind == POOL_ENERGY:
		_energy_current = value
		_energy_max = cap
		_energy_pct = _percent(value, cap)
		var energy_row: ReadoutRow = _rows.get(ROW_ENRG, null)
		if energy_row != null:
			energy_row.set_digits(_energy_pct)
	else:
		return
	_apply_danger()


## UI_SPEC section 3.7's row treatments, verbatim: hull below a quarter brightens its label
## and frames the row in `accent_danger`; fuel at or below 15 % frames the row in
## `accent_danger` with the label following; an empty tank frames it `accent_danger_bright`;
## overdrive frames the SPD row. **Digits never recolour** - only labels and frames move.
func _apply_danger() -> void:
	var overdrive: bool = _ratio > OVERDRIVE
	_style_row(ROW_SPD, TOKEN_TEXT_DIM, TOKEN_DANGER if overdrive else &"")
	var hull_critical: bool = _hull_max > 0.0 and _hull_current / _hull_max < HULL_DANGER_FRACTION
	_style_row(
		ROW_HULL,
		TOKEN_DANGER_BRIGHT if hull_critical else TOKEN_TEXT_DIM,
		TOKEN_DANGER if hull_critical else &""
	)
	var fuel_low: bool = _fuel_max > 0.0 and _fuel_current / _fuel_max <= FUEL_DANGER_FRACTION
	## A tank with no capacity is not an empty tank: `maximum == 0` reads 0 and is not framed.
	var fuel_empty: bool = _fuel_max > 0.0 and _fuel_current <= 0.0
	var fuel_frame: StringName = &""
	if fuel_empty:
		fuel_frame = TOKEN_DANGER_BRIGHT
	elif fuel_low:
		fuel_frame = TOKEN_DANGER
	_style_row(ROW_FUEL, TOKEN_DANGER if fuel_low else TOKEN_TEXT_DIM, fuel_frame)
	_style_row(ROW_ENRG, TOKEN_TEXT_DIM, &"")


func _style_row(key: StringName, label_token: StringName, frame_token: StringName) -> void:
	if not _rows.has(key):
		return
	var row: ReadoutRow = _rows[key]
	row.set_label_token(label_token)
	row.set_frame_token(frame_token)


## UI_SPEC section 3.7: `int(round(rad_to_deg(heading.angle())))` mapped into 0..359.
static func _map_heading(heading: Vector2) -> float:
	return float(posmod(roundf(rad_to_deg(heading.angle())), 360.0))


## UI_SPEC section 3.7: `int(round(100 x value/maximum))`, clamped 0..100; a zero maximum
## reads 0.
static func _percent(value: float, maximum: float) -> int:
	if maximum <= 0.0:
		return 0
	return clampi(int(round(100.0 * value / maximum)), 0, PCT_MAX)


## A theme change re-reads the row tokens (the HUD calls this from `_notification`).
func apply_theme() -> void:
	for row: ReadoutRow in _row_order:
		row.apply_theme()
	if _compass != null:
		_compass.queue_redraw()


## Probe access to one row's own state, keyed by ROW_*.
func row(key: StringName) -> ReadoutRow:
	return _rows.get(key, null)


## The middle bay's compass: the rose rotates `-heading.angle()` under a fixed lubber
## triangle (UI_SPEC section 3.7). No cardinal letters - UI_CHROME section 1.7's no-text law.
class Compass extends Control:
	const ROSE: Texture2D = preload("res://assets/ui/ui_compass_rose.png")
	const LUBBER: Texture2D = preload("res://assets/ui/ui_compass_lubber.png")
	## UI_CHROME section 11's logical lubber box (16 x 12; the master is 2x).
	const LUBBER_SIZE := Vector2(16.0, 12.0)

	var _angle: float = 0.0

	## The ship's facing in radians; the rose counter-rotates by it.
	func set_heading(angle: float) -> void:
		if is_equal_approx(angle, _angle):
			return
		_angle = angle
		queue_redraw()

	func heading_angle() -> float:
		return _angle

	## The rose's own rotation as drawn, `-heading.angle()`.
	func rose_angle() -> float:
		return -_angle

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		draw_set_transform(centre, -_angle, Vector2.ONE)
		draw_texture_rect(ROSE, Rect2(-centre, size), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture_rect(
			LUBBER,
			Rect2((size.x - LUBBER_SIZE.x) * 0.5, 0.0, LUBBER_SIZE.x, LUBBER_SIZE.y),
			false
		)


## One readout row: a 12 px label (34 px column) plus digit cells, with a script-drawn 1 px
## frame on the danger reads. The digits themselves are never tinted.
class ReadoutRow extends HBoxContainer:
	const TOKENS_TYPE: StringName = &"Tokens"
	const BLANK := -1
	const LABEL_WIDTH := 34.0
	const LABEL_FONT_SIZE := 12
	const CELL_SIZE := Vector2(20.0, 36.0)
	const DIGIT_GAP := 2
	const SEG: Array[Texture2D] = [
		preload("res://assets/ui/ui_seg_0.png"),
		preload("res://assets/ui/ui_seg_1.png"),
		preload("res://assets/ui/ui_seg_2.png"),
		preload("res://assets/ui/ui_seg_3.png"),
		preload("res://assets/ui/ui_seg_4.png"),
		preload("res://assets/ui/ui_seg_5.png"),
		preload("res://assets/ui/ui_seg_6.png"),
		preload("res://assets/ui/ui_seg_7.png"),
		preload("res://assets/ui/ui_seg_8.png"),
		preload("res://assets/ui/ui_seg_9.png"),
	]
	const SEG_PCT: Texture2D = preload("res://assets/ui/ui_seg_pct.png")
	const SEG_BLANK: Texture2D = preload("res://assets/ui/ui_seg_blank.png")

	var _cells_count: int = 0
	var _percent: bool = false
	var _label: Label = null
	var _digits: Array[TextureRect] = []
	var _pct: TextureRect = null
	var _shown: Array = []
	var _label_token: StringName = &"text_dim"
	var _frame_token: StringName = &""

	func configure(label_text: String, cells: int, percent: bool) -> void:
		_cells_count = maxi(cells, 1)
		_percent = percent
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override(&"separation", DIGIT_GAP)
		_label = Label.new()
		_label.name = "Label"
		_label.text = label_text
		_label.custom_minimum_size = Vector2(LABEL_WIDTH, 0.0)
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override(&"font_size", LABEL_FONT_SIZE)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
		for index: int in _cells_count:
			var cell := _make_cell("Digit%d" % index, SEG_BLANK)
			_digits.append(cell)
		if _percent:
			_pct = _make_cell("Percent", SEG_PCT)
		set_digits(0)
		apply_theme()

	func _make_cell(cell_name: String, texture: Texture2D) -> TextureRect:
		var cell := TextureRect.new()
		cell.name = cell_name
		cell.custom_minimum_size = CELL_SIZE
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_SCALE
		cell.texture = texture
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cell)
		return cell

	## Right-aligned with leading blanks, never leading zeros (UI_SPEC section 3.7).
	func set_digits(value: int) -> void:
		_shown = _format(value)
		for index: int in _digits.size():
			var digit: int = _shown[index]
			_digits[index].texture = SEG_BLANK if digit == BLANK else SEG[digit]
		queue_redraw()

	## The value is already clamped by the cluster; a value wider than the row keeps its
	## right-most cells so a cell count can never silently grow the box.
	func _format(value: int) -> Array:
		var text := str(maxi(value, 0))
		var out: Array = []
		for index: int in _cells_count:
			out.append(BLANK)
		var count: int = mini(text.length(), _cells_count)
		var offset: int = _cells_count - count
		for index: int in count:
			var character := text.substr(text.length() - count + index, 1)
			out[offset + index] = character.to_int()
		return out

	## The digits as drawn: the cell value 0..9, or BLANK for a `ui_seg_blank` cell.
	func cells() -> Array:
		return _shown.duplicate()

	func set_label_token(token: StringName) -> void:
		if token == _label_token:
			return
		_label_token = token
		apply_theme()

	func set_frame_token(token: StringName) -> void:
		if token == _frame_token:
			return
		_frame_token = token
		queue_redraw()

	func label_token() -> StringName:
		return _label_token

	func frame_token() -> StringName:
		return _frame_token

	func framed() -> bool:
		return not _frame_token.is_empty()

	func label_colour() -> Color:
		return _token(_label_token)

	func frame_colour() -> Color:
		return _token(_frame_token)

	func percent_lit() -> bool:
		return _pct != null

	func percent_cell() -> TextureRect:
		return _pct

	func digit_cells() -> Array[TextureRect]:
		return _digits

	func apply_theme() -> void:
		if _label != null:
			_label.add_theme_color_override(&"font_color", _token(_label_token))
		queue_redraw()

	func _draw() -> void:
		if _frame_token.is_empty():
			return
		draw_rect(Rect2(Vector2.ZERO, size), _token(_frame_token), false, 1.0)

	func _token(token: StringName) -> Color:
		if not token.is_empty() and has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE
