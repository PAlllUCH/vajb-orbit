class_name CockpitCluster
extends Control
## UI_SPEC section 3.7 as amended 2026-09-24 (Mockup v5 + v7 approved) / CONTRACTS section 18:
## the cockpit instrument cluster. Wave D7 reworks the D6 surface onto the section 3.9
## instrument language:
##
##  - one painted **flat** panel plate (`ui_cockpit_panel`, fill-fit, no nine-slice) with the
##    wells **code-drawn** at the pinned rects (UI_CHROME section 12 Amendment 2: A0's baked
##    wells misregistered on 4 of 6 masters and Mockup v7 moved the bays, so layout changes
##    never invalidate art again);
##  - left bay: the section 3.6 gauge in its disc well plus the **battery lamps** `B1..B5`
##    band in the foot (the in-flight rack selector, the selected rack lit);
##  - middle bay: the two value dials **FUEL** and **ENRG** (36 px radius, 270 degree wedge
##    arc, needle and a Label over the lower face);
##  - right bay: the readout well at **full interior height** with four rows spread evenly
##    through it - SPD / HULL / SHLD / AMMO - the bottom row in the foot band.
##
## The compass, the HDG row and the section 3.6 dial's heading tick are **gone** (Mockup v6/v7:
## "we ditch the compass entirely"): `compass()`/`compass_heading()` survive callable as stubs
## per CONTRACTS section 18 and `readouts()` answers {spd, hull, shield, ammo}.
##
## **Every colour, layout metric and asset path comes from `CockpitStyle`** (section 3.9 rule
## 5); nothing here is hardcoded, and the digit cells are fill-fitted to their style-sized
## 20 x 36 cells on a 22 px pitch (section 3.7's digit fit law - the D6 overlap cure).
##
## Built in code by `ui/hud/hud.gd` in the section 7 inner-widget idiom; `hud.tscn` is
## untouched. It derives everything from the feeds section 7 already carries - no new feed.
## The speedometer itself is `Hud.Speedometer` (an inner class of the HUD, byte-identical
## contract), handed to the left bay by the HUD, because this file must not reference the HUD
## class back.

const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")

## Section 3.7's digit semantics (CONTRACTS section 18 repeats them verbatim). Every row is
## four cells wide; SPD is 4 cells like the others (the 2026-09-24 owner ruling).
const SPD_MAX: int = 9999
const POINTS_MAX: int = 9999
const AMMO_MAX: int = 9999
const HULL_DANGER_FRACTION: float = 0.25
const FUEL_DANGER_FRACTION: float = 0.15
## UI_SPEC section 3.6/3.7: the overdrive read is strict (`ratio > 0.9`).
const OVERDRIVE: float = 0.9

const ROW_SPD: StringName = &"spd"
const ROW_HULL: StringName = &"hull"
const ROW_SHLD: StringName = &"shld"
const ROW_AMMO: StringName = &"ammo"
## The stack, top to bottom (Mockup v7: "AMMO moves up into the stack"; four rows).
const ROW_ORDER: Array[StringName] = [ROW_SPD, ROW_HULL, ROW_SHLD, ROW_AMMO]
const ROW_LABELS: Dictionary = {
	ROW_SPD: "SPD", ROW_HULL: "HULL", ROW_SHLD: "SHLD", ROW_AMMO: "AMMO",
}
## Every row in the v7 stack carries four drums (the FUEL/ENRG rows retired with the dials).
const ROW_CELLS: int = 4

const DIAL_FUEL: StringName = &"fuel"
const DIAL_ENRG: StringName = &"enrg"
const DIAL_LABELS: Dictionary = {DIAL_FUEL: "FUEL", DIAL_ENRG: "ENRG"}

const POOL_FUEL: StringName = &"fuel"
const POOL_ENERGY: StringName = &"energy"

## The role names the surface asks the style for (section 1's own vocabulary).
const ROLE_DIM: StringName = &"text_dim"
const ROLE_DANGER: StringName = &"accent_danger"
const ROLE_DANGER_BRIGHT: StringName = &"accent_danger_bright"

const NODE_PANEL := "CockpitPanel"
const NODE_WELLS := "Wells"
const NODE_GAUGE_BAY := "GaugeBay"
const NODE_LAMPS := "BatteryLamps"
const NODE_DIALS := "ValueDials"
const NODE_READOUT := "ReadoutRows"

var _style: Resource = null
var _panel: TextureRect = null
var _wells: Wells = null
var _gauge_bay: Control = null
var _lamps: LampBand = null
var _dials: Dictionary = {}
var _dials_box: Control = null
var _readout: Control = null
var _rows: Dictionary = {}
var _row_order: Array[ReadoutRow] = []

## The readings as drawn (post-clamp), so a probe can assert them without a screenshot.
var _ratio: float = 0.0
var _spd: int = 0
var _hull: int = 0
var _shield: int = 0
var _ammo: int = 0
## The selected rack (1-based; the lamps' lit lamp), 0 when nothing is selected.
var _active_rack: int = 0

## The raw pools, kept for the dials and the danger reads (the digits are the clamped ints).
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


## Idempotent: a re-`_ready` cannot double the bays.
func _build() -> void:
	if _wells != null:
		return
	if _style == null:
		_style = CockpitStyleScript.load_style()
	_build_panel()
	_wells = Wells.new()
	_wells.name = NODE_WELLS
	_wells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wells.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_wells)
	_gauge_bay = Control.new()
	_gauge_bay.name = NODE_GAUGE_BAY
	_gauge_bay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gauge_bay)
	_lamps = LampBand.new()
	_lamps.name = NODE_LAMPS
	_lamps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lamps.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_lamps)
	_dials_box = Control.new()
	_dials_box.name = NODE_DIALS
	_dials_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dials_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dials_box)
	for key: StringName in [DIAL_FUEL, DIAL_ENRG]:
		var dial := ValueDial.new()
		dial.name = String(key)
		_dials_box.add_child(dial)
		_dials[key] = dial
	_readout = Control.new()
	_readout.name = NODE_READOUT
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_readout)
	for index: int in ROW_ORDER.size():
		var key: StringName = ROW_ORDER[index]
		var row := ReadoutRow.new()
		row.name = String(key)
		_readout.add_child(row)
		_rows[key] = row
		_row_order.append(row)
	_apply_style()
	_apply_readings()


## The painted plate under everything (section 3.7: one master, fill-fit, no nine-slice).
func _build_panel() -> void:
	_panel = TextureRect.new()
	_panel.name = NODE_PANEL
	_panel.texture = _style.texture(_style.panel_path)
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)


## Re-read the style into every child, in place: a user `.tres` restyles and relayouts the
## cluster with no code edit (section 3.9 rule 5) and without rebuilding the tree, so the
## section 3.6 dial the HUD attached to the gauge bay stays attached.
func _apply_style() -> void:
	if _style == null:
		return
	custom_minimum_size = _style.box_size
	_panel.texture = _style.texture(_style.panel_path)
	_wells.configure(_style, ROW_ORDER.size(), _panel.texture == null)
	var gauge_radius: float = _style.gauge_well_radius()
	var gauge: Vector2 = _style.gauge_centre()
	_gauge_bay.position = gauge - Vector2(gauge_radius, gauge_radius)
	_gauge_bay.size = Vector2(gauge_radius, gauge_radius) * 2.0
	_lamps.configure(_style)
	for key: StringName in _dials:
		var dial: ValueDial = _dials[key]
		dial.configure(_style, key, key == DIAL_FUEL)
		var centre: Vector2 = _style.dial_top if key == DIAL_FUEL else _style.dial_bottom
		var radius: float = _style.dial_radius
		dial.position = centre - Vector2(radius, radius)
	for index: int in _row_order.size():
		var row: ReadoutRow = _row_order[index]
		row.configure(_style, String(ROW_LABELS[ROW_ORDER[index]]), ROW_CELLS)
		row.position = _style.row_rect(index, ROW_CELLS).position


## The style in force (a probe read-back; section 3.9 rule 5).
func style() -> Resource:
	return _style


## Swap the whole style at runtime, from a `CockpitStyle` resource.
func set_style(style: Resource) -> void:
	if style == null:
		return
	_style = style
	if _wells == null:
		return
	_apply_style()
	_apply_readings()


## Swap the style from a `.tres` path: the file the user drops in
## (`CockpitStyle.USER_PATH`) or any other style file. `load_style` falls back to the
## shipped defaults when the path does not resolve.
func set_style_file(path: String) -> void:
	set_style(CockpitStyleScript.load_style(path))


## Replay every held reading into the children (used after a build or a restyle).
func _apply_readings() -> void:
	if _wells == null:
		return
	_update_spd_row()
	_update_row(ROW_HULL, _hull)
	_update_row(ROW_SHLD, _shield)
	_update_row(ROW_AMMO, _ammo)
	_readings_into_dials()
	if _lamps != null:
		_lamps.set_lit(_active_rack)
	_apply_danger()


func _readings_into_dials() -> void:
	var fuel: ValueDial = _dials.get(DIAL_FUEL, null)
	if fuel != null:
		fuel.set_reading(_fuel_current, _fuel_max)
	var energy: ValueDial = _dials.get(DIAL_ENRG, null)
	if energy != null:
		energy.set_reading(_energy_current, _energy_max)


func _update_row(key: StringName, value: int) -> void:
	var row: ReadoutRow = _rows.get(key, null)
	if row != null:
		row.set_digits(value)


func _update_spd_row() -> void:
	_update_row(ROW_SPD, _spd)


## The left bay, so `hud.gd` can attach the section 3.6 dial it owns.
func gauge_bay() -> Control:
	return _gauge_bay


## CONTRACTS section 18's read-back (here and on the HUD, the same seam): the cluster itself.
func cockpit() -> Control:
	return self


## CONTRACTS section 18's read-back, **retired** by UI_SPEC section 3.7's Mockup v7 block
## ("the compass is gone entirely"): the bay no longer exists, so this answers null while the
## signature stays callable. Reversal: return the rose bay again.
func compass() -> Control:
	return null


## CONTRACTS section 18's read-back, retired the same way: with no compass and no HDG row
## there is no heading readout to draw, so the stub answers 0.0 and the signature survives.
## Reversal: the mapped 0..359 reading of the section 3.7 compass bay.
func compass_heading() -> float:
	return 0.0


## CONTRACTS section 18's read-back as Mockup v7 reshapes it: the four clamped ints the rows
## show. The pools moved to the FUEL/ENRG dials, where `pool_readings()` reads them back.
func readouts() -> Dictionary:
	return {"spd": _spd, "hull": _hull, "shield": _shield, "ammo": _ammo}


## The two dials' own post-clamp readings ({value, maximum, percent, danger}), so a probe can
## assert the FUEL/ENRG instruments without a screenshot.
func pool_readings() -> Dictionary:
	var out: Dictionary = {}
	for key: StringName in _dials:
		var dial: ValueDial = _dials[key]
		out[String(key)] = {
			"value": dial.value(),
			"maximum": dial.maximum(),
			"percent": dial.percent(),
			"danger": dial.danger(),
		}
	return out


## One readout row, keyed by ROW_* (the D6 probe seam, kept).
func row(key: StringName) -> ReadoutRow:
	return _rows.get(key, null)


func rows() -> Array[ReadoutRow]:
	return _row_order


## One value dial, keyed by DIAL_*.
func value_dial(key: StringName) -> ValueDial:
	return _dials.get(key, null)


func lamp_band() -> LampBand:
	return _lamps


## The code-drawn wells, in paint order (the same list the painter walks).
func wells() -> Array[Rect2]:
	if _wells == null:
		return []
	return _wells.well_rects()


## The rack selector's lit lamp (1-based), 0 when nothing is selected.
func active_rack() -> int:
	return _active_rack


## UI_SPEC section 3.6's reading, section 3.7's cluster derivation: `ratio` drives the
## overdrive read and `prograde` the SPD digits (its length in u/s). The heading argument is
## still accepted because the section 7 feed carries it - nothing in the cluster draws it any
## more (the heading tick and the compass both retired with Mockup v6/v7).
func set_speedometer(ratio: float, prograde: Vector2, _heading: Vector2) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_spd = clampi(int(round(clampf(prograde.length(), 0.0, float(SPD_MAX)))), 0, SPD_MAX)
	_update_spd_row()
	_apply_danger()


func set_hull(current: float, maximum: float) -> void:
	_hull_current = maxf(current, 0.0)
	_hull_max = maxf(maximum, 0.0)
	_hull = clampi(int(round(clampf(_hull_current, 0.0, float(POINTS_MAX)))), 0, POINTS_MAX)
	_update_row(ROW_HULL, _hull)
	_apply_danger()


func set_shield(current: float, maximum: float) -> void:
	_shield_current = maxf(current, 0.0)
	_shield_max = maxf(maximum, 0.0)
	_shield = clampi(int(round(clampf(_shield_current, 0.0, float(POINTS_MAX)))), 0, POINTS_MAX)
	_update_row(ROW_SHLD, _shield)
	_apply_danger()


## Section 3.7's AMMO row: the active rack's loaded rounds on the existing ammo feed,
## `int(round(loaded))` clamped 0..9999 with leading blanks (never zeros).
func set_ammo(rounds: int) -> void:
	_ammo = clampi(int(round(float(rounds))), 0, AMMO_MAX)
	_update_row(ROW_AMMO, _ammo)


## The battery lamps' lit lamp: the selected rack's ordinal (`weapon_1..7` state, 1-based).
## An ordinal outside the band lights nothing.
func set_active_rack(ordinal: int) -> void:
	if ordinal >= 1 and ordinal <= _lamp_count():
		_active_rack = ordinal
	else:
		_active_rack = 0
	if _lamps != null:
		_lamps.set_lit(_active_rack)


func _lamp_count() -> int:
	return int(_style.lamp_count) if _style != null else 0


## Section 3.1b's two pool feeds, `kind` being `&"fuel"` or `&"energy"`; an unknown kind is
## ignored, exactly as `hud.gd::set_pool` ignores one. Mockup v7 moves the pools onto the two
## dials (the FUEL/ENRG digit rows retired).
func set_pool(kind: StringName, current: float, maximum: float) -> void:
	var value: float = maxf(current, 0.0)
	var cap: float = maxf(maximum, 0.0)
	if kind == POOL_FUEL:
		_fuel_current = value
		_fuel_max = cap
	elif kind == POOL_ENERGY:
		_energy_current = value
		_energy_max = cap
	else:
		return
	_readings_into_dials()
	_apply_danger()


## Section 3.7's row treatments, verbatim: hull below a quarter brightens its label and
## frames the row in `accent_danger`; overdrive frames the SPD row; **digits never recolour**.
## The fuel danger read now lives on the FUEL dial (needle `accent_danger_bright`, lit arc
## `accent_danger`), so it is not a row treatment any more.
func _apply_danger() -> void:
	var overdrive: bool = _ratio > OVERDRIVE
	_style_row(ROW_SPD, ROLE_DIM, ROLE_DANGER if overdrive else &"")
	var hull_critical: bool = _hull_max > 0.0 and _hull_current / _hull_max < HULL_DANGER_FRACTION
	_style_row(
		ROW_HULL,
		ROLE_DANGER_BRIGHT if hull_critical else ROLE_DIM,
		ROLE_DANGER if hull_critical else &""
	)
	_style_row(ROW_SHLD, ROLE_DIM, &"")
	_style_row(ROW_AMMO, ROLE_DIM, &"")


func _style_row(key: StringName, label_role: StringName, frame_role: StringName) -> void:
	var row: ReadoutRow = _rows.get(key, null)
	if row == null:
		return
	row.set_label_token(label_role)
	row.set_frame_token(frame_role)


## A restyle or a theme change re-reads the style (the HUD calls this from `_notification`).
func apply_theme() -> void:
	_apply_style()
	_apply_readings()


## The code-drawn wells (section 3.9 rule 2 + 4): every widget sits in a recess at the pinned
## rect, painted in the style's metal, and the state marks stay code-drawn. A recess's shadow
## edge is dark on top/left and lit on bottom/right (the inverse of section 1's raised bevel).
class Wells extends Control:
	var _style: Resource = null
	var _rows: int = 4
	var _plate_missing: bool = false

	func configure(style: Resource, rows: int, plate_missing: bool) -> void:
		_style = style
		_rows = rows
		_plate_missing = plate_missing
		queue_redraw()

	## The same list the style derives, so a probe and the painter cannot disagree.
	func well_rects() -> Array[Rect2]:
		if _style == null:
			return []
		return _style.wells(_rows)

	func _draw() -> void:
		if _style == null:
			return
		if _plate_missing:
			draw_rect(Rect2(Vector2.ZERO, _style.box_size), _style.colour(&"panel_steel"), true)
		_draw_disc(_style.gauge_centre(), _style.gauge_well_radius())
		_draw_recess(_style.foot_well())
		_draw_disc(_style.dial_top, _style.dial_well_radius())
		_draw_disc(_style.dial_bottom, _style.dial_well_radius())
		_draw_recess(_style.readout_well(_rows))

	func _draw_recess(rect: Rect2) -> void:
		draw_rect(rect, _style.colour(&"void_base"), true)
		var dark: Color = _style.colour(&"metal_dark")
		var light: Color = _style.colour(&"metal_light")
		var width: float = _style.frame_width
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), dark, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), dark, width, true)
		draw_line(
			Vector2(rect.position.x, rect.end.y), rect.end, light, width, true
		)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, light, width, true)

	func _draw_disc(centre: Vector2, radius: float) -> void:
		draw_circle(centre, radius, _style.colour(&"void_base"))
		var rim: float = radius - _style.frame_width * 0.5
		draw_arc(centre, rim, PI, TAU, 48, _style.colour(&"metal_dark"), _style.frame_width, true)
		draw_arc(centre, rim, 0.0, PI, 48, _style.colour(&"metal_light"), _style.frame_width, true)


## The battery lamps band (Mockup v5 delta 2): five `B1..B5` squares, code-drawn, the
## selected rack's lamp lit with the style's ember (dark-ember fill, bright border and caption;
## an unselected lamp is `void_panel_raised` / `metal_dark` / `text_dim`). Every caption is an
## engine Label - no baked text anywhere (UI_CHROME section 1.7).
class LampBand extends Control:
	var _style: Resource = null
	var _labels: Array[Label] = []
	var _lit: int = 0
	var _box_lit: StyleBoxFlat = null
	var _box_unlit: StyleBoxFlat = null

	func configure(style: Resource) -> void:
		_style = style
		_box_lit = null
		_box_unlit = null
		_sync_labels()
		_apply_lamp_colours()
		queue_redraw()

	## The lit lamp's ordinal (1-based); 0 lights nothing.
	func set_lit(ordinal: int) -> void:
		var wanted: int = ordinal if ordinal >= 1 and ordinal <= _label_count() else 0
		if wanted == _lit:
			return
		_lit = wanted
		_apply_lamp_colours()
		queue_redraw()

	func lit_rack() -> int:
		return _lit

	func lamp_rects() -> Array[Rect2]:
		var out: Array[Rect2] = []
		if _style == null:
			return out
		for index: int in _style.lamp_count:
			out.append(_style.lamp_rect(index))
		return out

	func lamp_labels() -> Array[Label]:
		return _labels

	func _label_count() -> int:
		return int(_style.lamp_count) if _style != null else 0

	func _sync_labels() -> void:
		if _style == null:
			return
		var wanted: int = _label_count()
		while _labels.size() > wanted:
			var removed: Label = _labels.pop_back()
			remove_child(removed)
			removed.queue_free()
		while _labels.size() < wanted:
			var label := Label.new()
			label.name = "Lamp%d" % (_labels.size() + 1)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(label)
			_labels.append(label)
		for index: int in _labels.size():
			var label: Label = _labels[index]
			label.text = "B%d" % (index + 1)
			label.position = _style.lamp_rect(index).position
			label.size = Vector2(_style.lamp_size, _style.lamp_size)
			label.add_theme_font_size_override(&"font_size", _style.lamp_font_size)

	func _apply_lamp_colours() -> void:
		if _style == null:
			return
		for index: int in _labels.size():
			var lit: bool = _lit == index + 1
			var role: StringName = &"accent_danger_bright" if lit else &"text_dim"
			_labels[index].add_theme_color_override(&"font_color", _style.colour(role))

	func _draw() -> void:
		if _style == null:
			return
		if _box_lit == null:
			_build_boxes()
		for index: int in _label_count():
			var rect: Rect2 = _style.lamp_rect(index)
			var lit: bool = _lit == index + 1
			draw_style_box(_box_lit if lit else _box_unlit, rect)

	## The two lamp faces, built from the style's own metrics (radius and border) rather than
	## drawn as bare rects, so a restyle moves the corners with everything else.
	func _build_boxes() -> void:
		if _style == null:
			return
		var corner: int = int(round(_style.lamp_corner))
		var border: int = maxi(int(round(_style.frame_width)), 1)
		_box_lit = StyleBoxFlat.new()
		_box_lit.bg_color = _style.lamp_fill(&"accent_danger_bright")
		_box_lit.border_color = _style.colour(&"accent_danger_bright")
		_box_lit.set_corner_radius_all(corner)
		_box_lit.set_border_width_all(border)
		_box_unlit = StyleBoxFlat.new()
		_box_unlit.bg_color = _style.colour(&"void_panel_raised")
		_box_unlit.border_color = _style.colour(&"metal_dark")
		_box_unlit.set_corner_radius_all(corner)
		_box_unlit.set_border_width_all(border)


## One value dial (Mockup v7): a 270 degree arc of thin wedges, a needle and the name as a
## Label over the lower face. The state marks stay code-drawn in the style's palette (section
## 3.9 rule 4): a lit wedge is `metal_light` (the fuel dial's lit wedges turn `accent_danger`
## at or below 15 %, with the needle `accent_danger_bright`), an unlit wedge `metal_dark`.
class ValueDial extends Control:
	var _style: Resource = null
	var _key: StringName = &""
	var _danger_row: bool = false
	var _value: float = 0.0
	var _maximum: float = 0.0
	var _percent: int = 0
	var _label: Label = null

	func configure(style: Resource, key: StringName, danger_row: bool) -> void:
		_style = style
		_key = key
		_danger_row = danger_row
		var radius: float = _style.dial_radius
		custom_minimum_size = Vector2(radius, radius) * 2.0
		size = custom_minimum_size
		if _label == null:
			_label = Label.new()
			_label.name = "Name"
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_label)
		_label.text = String(DIAL_LABELS.get(key, String(key).to_upper()))
		_label.add_theme_font_size_override(&"font_size", _style.dial_label_font_size)
		var height: float = float(_style.dial_label_font_size) + 4.0
		_label.position = Vector2(0.0, radius + radius * 0.5 - height * 0.5)
		_label.size = Vector2(radius * 2.0, height)
		_apply_label_colour()
		queue_redraw()

	## The pool feed, `round(100 x value / maximum)` clamped 0..100 over the sweep; a zero
	## maximum reads 0 (and is not a danger read).
	func set_reading(value: float, maximum: float) -> void:
		var next_value: float = maxf(value, 0.0)
		var next_max: float = maxf(maximum, 0.0)
		var next_percent: int = 0
		if next_max > 0.0:
			next_percent = clampi(int(round(100.0 * next_value / next_max)), 0, 100)
		if (
			is_equal_approx(next_value, _value)
			and is_equal_approx(next_max, _maximum)
			and next_percent == _percent
		):
			return
		_value = next_value
		_maximum = next_max
		_percent = next_percent
		_apply_label_colour()
		queue_redraw()

	func value() -> float:
		return _value

	func maximum() -> float:
		return _maximum

	func percent() -> int:
		return _percent

	func fraction() -> float:
		return float(_percent) / 100.0

	## The fuel dial's danger read (Mockup v7): at or below 15 % of the tank, and an empty
	## tank with capacity. A tank with no capacity is not empty (section 3.1b's own rule).
	func danger() -> bool:
		if not _danger_row or _maximum <= 0.0:
			return false
		return _value / _maximum <= FUEL_DANGER_FRACTION

	func lit_wedges() -> int:
		var wedges: int = int(_style.dial_wedges) if _style != null else 10
		return clampi(int(round(fraction() * wedges)), 0, wedges)

	func needle_colour() -> Color:
		if _style == null:
			return Color.WHITE
		var role: StringName = &"accent_danger_bright" if danger() else &"text_primary"
		return _style.colour(role)

	func dial_label() -> Label:
		return _label

	func dial_key() -> StringName:
		return _key

	func _apply_label_colour() -> void:
		if _label == null or _style == null:
			return
		var role: StringName = &"accent_danger_bright" if danger() else &"text_dim"
		_label.add_theme_color_override(&"font_color", _style.colour(role))

	func _draw() -> void:
		if _style == null:
			return
		var centre: Vector2 = size * 0.5
		var radius: float = _style.dial_radius
		draw_circle(centre, radius, _style.colour(&"void_base"))
		var rim: float = radius - _style.frame_width * 0.5
		draw_arc(centre, rim, PI, TAU, 40, _style.colour(&"metal_dark"), _style.frame_width, true)
		draw_arc(centre, rim, 0.0, PI, 40, _style.colour(&"metal_light"), _style.frame_width, true)
		var wedges: int = int(_style.dial_wedges)
		var start: float = _style.dial_start()
		var sweep: float = _style.dial_sweep()
		var step: float = sweep / float(wedges)
		var pad: float = step * 0.06
		var r_out: float = radius - 4.0
		var r_in: float = radius - 9.0
		var band: float = (r_out + r_in) * 0.5
		var thickness: float = r_out - r_in
		var lit: int = lit_wedges()
		var danger: bool = danger()
		for index: int in wedges:
			var colour: Color = _style.colour(&"metal_dark")
			if index < lit:
				colour = _style.colour(&"accent_danger" if danger else &"metal_light")
			draw_arc(
				centre,
				band,
				start + step * float(index) + pad,
				start + step * float(index + 1) - pad,
				6,
				colour,
				thickness,
				true
			)
		if _percent >= 0:
			var angle: float = start + sweep * fraction()
			draw_line(
				centre,
				centre + Vector2.RIGHT.rotated(angle) * (radius - 12.0),
				needle_colour(),
				_style.dial_needle_width,
				true
			)
		draw_circle(centre, _style.dial_hub_radius, _style.colour(&"metal_mid"))
		draw_circle(centre, _style.dial_hub_radius * 0.5, _style.colour(&"metal_dark"))


## One readout row: a `text_dim` label in the style's label zone plus the digit drums. The
## cells are **positioned at the style's own cell rects** rather than laid out by a container,
## so each `ui_seg_*` sprite is fill-fitted to its 20 x 36 cell on the 22 px pitch and two
## cells can never grow into each other (section 3.7's digit fit law - the D6 overlap cure).
## The digits themselves are never tinted; a danger read is the label's own role plus the 1 px
## script-drawn frame (section 3.2's palette-neutral precedent).
class ReadoutRow extends Control:
	const BLANK := -1

	var _style: Resource = null
	var _cells_count: int = 0
	var _label: Label = null
	var _digits: Array[TextureRect] = []
	var _seg: Array[Texture2D] = []
	var _blank: Texture2D = null
	var _shown: Array = []
	var _label_token: StringName = &"text_dim"
	var _frame_token: StringName = &""

	func configure(style: Resource, label_text: String, cells: int) -> void:
		_style = style
		_cells_count = maxi(cells, 1)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(_style.row_width(_cells_count), _style.row_height)
		size = custom_minimum_size
		_load_segments()
		if _label == null:
			_label = Label.new()
			_label.name = "Label"
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_label)
		_label.text = label_text
		_label.position = Vector2.ZERO
		_label.size = Vector2(_style.label_zone, _style.row_height)
		_label.add_theme_font_size_override(&"font_size", _style.label_font_size)
		while _digits.size() > _cells_count:
			var removed: TextureRect = _digits.pop_back()
			remove_child(removed)
			removed.queue_free()
		while _digits.size() < _cells_count:
			var cell := TextureRect.new()
			cell.name = "Digit%d" % _digits.size()
			cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell.stretch_mode = TextureRect.STRETCH_SCALE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell)
			_digits.append(cell)
		for index: int in _digits.size():
			var rect: Rect2 = _style.cell_rect(index)
			_digits[index].position = rect.position
			_digits[index].size = rect.size
		set_digits(0)
		apply_theme()

	## The twelve `ui_seg_*` cuts the style names (0..9, blank, percent).
	func _load_segments() -> void:
		if _style == null or not _seg.is_empty():
			return
		for digit: int in 10:
			_seg.append(_style.texture(_style.seg_path(str(digit))))
		_blank = _style.texture(_style.seg_path(_style.seg_blank_cell))

	## Right-aligned with leading blanks, never leading zeros (UI_SPEC section 3.7).
	func set_digits(value: int) -> void:
		_shown = _format(value)
		for index: int in _digits.size():
			var digit: int = _shown[index]
			var cut: Texture2D = _blank
			if digit != BLANK and digit < _seg.size():
				cut = _seg[digit]
			_digits[index].texture = cut
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

	## Every drawn cell's rect in the row's own coordinates (the digit fit law's own read-back:
	## the sprites are fill-fitted to these rects).
	func cell_rects() -> Array[Rect2]:
		var out: Array[Rect2] = []
		for cell: TextureRect in _digits:
			out.append(Rect2(cell.position, cell.size))
		return out

	func digit_cells() -> Array[TextureRect]:
		return _digits

	## Mockup v7 retires the `%` cell (the FUEL/ENRG rows went with the dials), so no row
	## carries one; the read-backs stay callable for the same reason the frozen ones do.
	func percent_lit() -> bool:
		return false


	func percent_cell() -> TextureRect:
		return null


	func label_node() -> Label:
		return _label


	func label_text() -> String:
		return _label.text if _label != null else ""


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
		return _role_colour(_label_token)


	func frame_colour() -> Color:
		return _role_colour(_frame_token)


	func apply_theme() -> void:
		if _label != null:
			_label.add_theme_color_override(&"font_color", _role_colour(_label_token))
		queue_redraw()


	func _draw() -> void:
		if _frame_token.is_empty() or _style == null:
			return
		draw_rect(
			Rect2(Vector2.ZERO, size), _role_colour(_frame_token), false, _style.frame_width
		)


	func _role_colour(role: StringName) -> Color:
		if _style == null:
			return Color.WHITE
		return _style.colour(role)
