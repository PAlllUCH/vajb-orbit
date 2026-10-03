class_name Minimap
extends Control
## Custom-drawn minimap: compass rose, contact blips, no per-frame work of its own
## (the one exception is the chaff ghost's flicker clock, on only while a ghost is
## on the feed).
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.10 and 4.7.
## Blip positions are world coordinates; set_world_radius maps them onto the
## control's square around the self blip, so the map stays player-centred however
## far the ship flies. The compass rose is script-drawn by design (ICONS_SPEC preamble).
## Blip classes follow ENGINE_SPEC section 8 / 11 section 3.3: friendly (stations,
## gates, beacons), neutral (derelicts, convoys, scanned anomalies), hostile
## (pirates, hunters). Friendly blips are the one class drawn as a diamond, so a
## station stays readable next to the player-centred self blip, which shares their
## text_primary tint (UI_SPEC section 3.3).
##
## Two sub-kinds ride those classes (ENGINE_SPEC section 10): `&"ghost"` is the
## chaff signature of section 4.6 - a dim `text_dim` dot flickering 0.3-0.7 alpha
## at 6 Hz for the 3 s window, never hostile-red (UI_SPEC section 3.3) - and
## `&"swarmer"` is the alien hull's hostile sub-kind, drawn exactly as a hostile
## blip. The flicker is the only clock this control reads, and it runs only while a
## ghost is on the feed, so the map stays frame-free the rest of the time.

const TOKENS_TYPE: StringName = &"Tokens"

const COLOR_SELF: StringName = &"text_primary"
const COLOR_HOSTILE: StringName = &"accent_danger"
const COLOR_NEUTRAL: StringName = &"text_dim"
const COLOR_FRIENDLY: StringName = &"text_primary"
const COLOR_ROSE: StringName = &"text_dim"
const COLOR_NEEDLE: StringName = &"text_primary"

const KIND_SELF: StringName = &"self"
const KIND_HOSTILE: StringName = &"hostile"
const KIND_FRIENDLY: StringName = &"friendly"
## ENGINE_SPEC section 10's two additions: the hostile sub-kind the alien hulls
## answer with, and the chaff ghost section 4.6 spawns.
const KIND_SWARMER: StringName = &"swarmer"
const KIND_GHOST: StringName = &"ghost"
## S29 (UI_SPEC.md section 10, N15-N18/N21-N22): the six PROPOSED blip classes the
## map deck's filter column names. They are drawn on deck and compact map exactly as
## the compact map's own law draws (STATION and GATE as the friendly diamond the
## sector's station and gates wear today; the rest as neutral dots), so a class that
## ships an emitter later changes no mark. Nothing emits them yet (N23: their toggles
## are inert), and STATION/GATE are the two N6-exempt classes - always drawn whatever
## the filters say.
const KIND_STATION: StringName = &"station"
const KIND_GATE: StringName = &"gate"
const KIND_ASTEROID_FIELD: StringName = &"asteroid_field"
const KIND_POI: StringName = &"poi"
const KIND_WRECK: StringName = &"wreck"
const KIND_CONTRACT: StringName = &"contract"

## The S29 navigation pin (N4): drawn as the diamond mark in `text_primary` at 6 px
## (friendly blips are 3 px - PROPOSED in UI_SPEC.md section 10, reversal
## `accent_ember`), and clamped to this control's own edge as a bearing arrow when
## the pin is out of view (the bezel's inner edge, band 16 - this control is already
## the bezel's inner rect).
const PIN_COLOUR: StringName = &"text_primary"
const PIN_RADIUS: float = 6.0
const PIN_ARROW_LENGTH: float = 7.0
const PIN_ARROW_WIDTH: float = 2.0
## S29 A2: the pin's press target. Derived from the pinned mark size (the diamond is
## drawn at PIN_RADIUS, the hit box is its double) - UI_SPEC.md section 10 fixes the
## precedence of a hit, not its radius.
const PIN_HIT_RADIUS: float = PIN_RADIUS * 2.0

## S29 A1 (UI_SPEC.md section 9 N2): the deck zoom's clamp (25 %-400 %) and one wheel
## notch / button press step. The clamp is the pin; the step is PROPOSED (reversal:
## any step - the 25 %-400 % clamp is the law), the range's fifth-root rounding.
const ZOOM_MIN: float = 0.25
const ZOOM_MAX: float = 4.0
const ZOOM_STEP: float = 1.25

const DEFAULT_WORLD_RADIUS: float = 4000.0
const SELF_RADIUS: float = 3.0
const BLIP_RADIUS: float = 2.0
const FRIENDLY_RADIUS: float = 3.0
const ROSE_RADIUS_RATIO: float = 0.36
const ROSE_SEGMENTS: int = 48
const ROSE_WIDTH: float = 1.0
const CARDINAL_TICK: float = 4.0
const NEEDLE_LENGTH: float = 7.0

## UI_SPEC section 3.3's ghost flicker, verbatim: "alpha 0.3-0.7 at 6 Hz". The
## alpha is a sine of the flicker's own clock rather than of a frame count, so the
## curve is the same at any frame rate and can be asserted without one.
const GHOST_FLICKER_HZ: float = 6.0
const GHOST_ALPHA_MIN: float = 0.3
const GHOST_ALPHA_MAX: float = 0.7
## Two samples per flicker cycle reproduce the sine: the repaint driver asks for a
## redraw at this rate instead of one per frame.
const GHOST_DRAW_HZ: float = GHOST_FLICKER_HZ * 2.0

## S29 (UI_SPEC.md section 10, N3/N7/N15-N23): the deck filter column's eight toggles
## and the blip classes each rides, the section 10 mapping table verbatim (N19: the
## shipped ghost rides POIS; N20: the shipped swarmer rides HOSTILES). `n6` marks the
## two classes N6 draws whatever the filters say. The deck builds its rows from this
## table and `kind_visible` reads the same rows, so a toggle and its classes can never
## disagree. N23's inert rule keys off `shipped_kinds`.
const TOGGLE_STATIONS: StringName = &"stations"
const TOGGLE_GATES: StringName = &"gates"
const TOGGLE_ASTEROID_FIELDS: StringName = &"asteroid_fields"
const TOGGLE_POIS: StringName = &"pois"
const TOGGLE_HOSTILES: StringName = &"hostiles"
const TOGGLE_FRIENDLY: StringName = &"friendly"
const TOGGLE_CARGO_WRECKS: StringName = &"cargo_wrecks"
const TOGGLE_CONTRACTS: StringName = &"contracts"

const MARK_DIAMOND: StringName = &"diamond"
const MARK_DOT: StringName = &"dot"

var _world_radius: float = DEFAULT_WORLD_RADIUS
var _blips: Array = []
var _ghost_clock: float = 0.0
var _ghost_elapsed: float = 0.0
var _color_self: Color = Color.WHITE
var _color_hostile: Color = Color.WHITE
var _color_neutral: Color = Color.WHITE
var _color_friendly: Color = Color.WHITE
var _color_rose: Color = Color.WHITE
var _color_needle: Color = Color.WHITE
## S29 A1/A2: the shared filter state (toggle id -> on; absent = N3's all-on default),
## the one destination pin (world point or null), and the deck's view state. A null
## `_view_centre` is the compact map's own law (the player is the map centre).
var _filters: Dictionary = {}
var _pin: Variant = null
var _view_centre: Variant = null
var _zoom: float = 1.0
var _pin_labels: bool = false
var _pin_distance_text: String = ""
var _pin_caption: String = ""
var _pin_stack: VBoxContainer = null
var _pin_diamond: Control = null
var _pin_dist_label: Label = null
var _pin_caption_label: Label = null
var _pin_arrow: Control = null


func _ready() -> void:
	_refresh_colors()
	_build_pin_marks()
	set_process(_has_ghost())


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh_colors()
	if what == NOTIFICATION_RESIZED:
		_sync_marks()


func set_world_radius(world_radius: float) -> void:
	var radius: float = maxf(world_radius, 1.0)
	if is_equal_approx(radius, _world_radius):
		return
	_world_radius = radius
	_sync_marks()
	queue_redraw()


func set_blips(blips: Array[Dictionary]) -> void:
	if _blips == blips:
		return
	_blips = blips.duplicate()
	_sync_ghost_flicker()
	_sync_marks()
	queue_redraw()


## UI_SPEC section 3.3's flicker, and the only per-frame work this control ever
## does: a ghost lives for the 3 s chaff window (section 4.6) and nothing else on
## the map moves on a clock, so processing is enabled while a ghost is on the feed
## and dropped the moment the last one leaves.
func _process(delta: float) -> void:
	var elapsed: float = maxf(delta, 0.0)
	_ghost_clock += elapsed
	_ghost_elapsed += elapsed
	var step: float = 1.0 / GHOST_DRAW_HZ
	if _ghost_elapsed < step:
		return
	_ghost_elapsed = fmod(_ghost_elapsed, step)
	queue_redraw()


func world_radius() -> float:
	return _world_radius


## The chaff blip's alpha `now` seconds into the flicker's own clock: UI_SPEC
## section 3.3's "alpha 0.3-0.7 at 6 Hz" as a sine, so the extremes are exact and
## a suite or a probe can assert the curve with no frame involved.
func ghost_alpha(now: float) -> float:
	var phase: float = sin(TAU * GHOST_FLICKER_HZ * now) * 0.5 + 0.5
	return lerpf(GHOST_ALPHA_MIN, GHOST_ALPHA_MAX, phase)


## How long the flicker's clock has been running: `_process`'s integral of the
## deltas, which is the reading `_color_for(&"ghost")` is drawn from.
func ghost_clock() -> float:
	return _ghost_clock


## S29 (UI_SPEC.md section 10): the filter column's rows in N3's own order - id, the
## N3 label, the classes the toggle rides and the N6 exemption. One table, read by the
## deck's column and by `kind_visible`, so the mapping (N15-N22) has exactly one home.
static func toggle_rows() -> Array[Dictionary]:
	return [
		{&"id": TOGGLE_STATIONS, &"label": "STATIONS", &"kinds": [KIND_STATION], &"n6": true},
		{&"id": TOGGLE_GATES, &"label": "GATES", &"kinds": [KIND_GATE], &"n6": true},
		{&"id": TOGGLE_ASTEROID_FIELDS, &"label": "ASTEROID FIELDS", &"kinds": [KIND_ASTEROID_FIELD]},
		{&"id": TOGGLE_POIS, &"label": "POIS", &"kinds": [KIND_POI, KIND_GHOST]},
		{&"id": TOGGLE_HOSTILES, &"label": "HOSTILES", &"kinds": [KIND_HOSTILE, KIND_SWARMER]},
		{&"id": TOGGLE_FRIENDLY, &"label": "FRIENDLY", &"kinds": [KIND_FRIENDLY]},
		{&"id": TOGGLE_CARGO_WRECKS, &"label": "CARGO & WRECKS", &"kinds": [KIND_WRECK]},
		{&"id": TOGGLE_CONTRACTS, &"label": "CONTRACTS", &"kinds": [KIND_CONTRACT]},
	]


## N23's "shipped": the classes something emits today - the shipped five above plus
## KIND_STATION/KIND_GATE (S29 re-anchors the sector's station and gate blips onto them,
## N6/N15/N16). A class outside this list has no emitter, so its toggle is inert (N23):
## drawn, persisted, filtering nothing.
static func shipped_kinds() -> Array[StringName]:
	return [
		KIND_SELF, KIND_HOSTILE, KIND_FRIENDLY, KIND_SWARMER, KIND_GHOST,
		KIND_STATION, KIND_GATE,
	]


## The mark each class draws: STATION/GATE wear the friendly diamond the sector's
## station and gates wear today (N15/N16: "a class that ships an emitter later changes
## no mark"); everything else is a dot, the compact map's own law.
static func blip_mark(kind: StringName) -> StringName:
	if kind == KIND_FRIENDLY or kind == KIND_STATION or kind == KIND_GATE:
		return MARK_DIAMOND
	return MARK_DOT


## N3/N6/N23 as one predicate. KIND_SELF carries no toggle and is never filterable;
## N6's two classes draw whatever the filters say; an unshipped class filters nothing
## (N23); every other class is read through its toggle (all-on default, N3's reversal).
func kind_visible(kind: StringName) -> bool:
	if kind == KIND_SELF or kind == KIND_STATION or kind == KIND_GATE:
		return true
	if not shipped_kinds().has(kind):
		return true
	for row: Dictionary in toggle_rows():
		if (row[&"kinds"] as Array).has(kind):
			return bool(_filters.get(row[&"id"], true))
	return true


func set_filters(filters: Dictionary) -> void:
	_filters = filters.duplicate()
	queue_redraw()


func filters() -> Dictionary:
	return _filters.duplicate()


## The one destination pin (N4): a world point or null. Drawn as the diamond mark in
## its own child rect (A5.2(iii)) when in view and as the edge bearing arrow clamped to
## this control's own edge (the bezel's inner rect) when not.
func set_pin(world: Variant) -> void:
	_pin = world if world is Vector2 else null
	_sync_marks()
	queue_redraw()


func pin() -> Variant:
	return _pin


## The deck's view state (N2): a world-space centre and the zoom multiplier. A null
## centre is the compact map's own law (follow the self blip). `local_of`/`world_at`
## are the one projection both the drawing and the deck's hit tests read.
func set_view(centre: Variant, zoom: float) -> void:
	_view_centre = centre if centre is Vector2 else null
	_zoom = clampf(zoom, ZOOM_MIN, ZOOM_MAX)
	_sync_marks()
	queue_redraw()


func set_view_centre(centre: Variant) -> void:
	set_view(centre, _zoom)


func set_view_zoom(zoom: float) -> void:
	set_view(_view_centre, zoom)


func map_origin() -> Vector2:
	return _blip_origin() if _view_centre == null else (_view_centre as Vector2)


## S29 A2 (the arrival read's "blip re-centring"): the deck view snaps back to the
## player at a hyperdrive arrival (`game.gd`'s N5 machine through `hud.gd`).
func recenter_on_player() -> void:
	set_view(_blip_origin(), _zoom)


func view_zoom() -> float:
	return _zoom


func local_of(world: Vector2) -> Vector2:
	return size * 0.5 + (world - map_origin()) * _unit()


func world_at(local: Vector2) -> Vector2:
	return map_origin() + (local - size * 0.5) / _unit()


## N2's 64 px arrow steps: the view centre moves `delta` screen pixels' worth of world.
## The first pan materialises the deck's free view centre at the player and stops the
## self-following law (the compact map's own), which is what makes panning possible.
func pan_by_pixels(delta: Vector2) -> void:
	if _view_centre == null:
		_view_centre = _blip_origin()
	set_view_centre(map_origin() + delta / _unit())


## N2's cursor-centred zoom: the world point under `local` stays under `local`, and the
## 25 %-400 % clamp is the pin (N2). Like `pan_by_pixels`, the first zoom materialises
## the free view centre - a self-following view cannot keep a foreign point fixed.
func zoom_at(local: Vector2, factor: float) -> void:
	var next := clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(next, _zoom):
		return
	var anchor_world := world_at(local)
	if _view_centre == null:
		_view_centre = _blip_origin()
	_zoom = next
	_view_centre = anchor_world + (size * 0.5 - local) / _unit()
	_sync_marks()
	queue_redraw()


## N10's `DIST <n>` value: the ship (the self blip) to the pin, in world units.
func pin_distance() -> float:
	if _pin == null:
		return 0.0
	return _blip_origin().distance_to(_pin as Vector2)


## The fixer's precedence law (UI_SPEC.md section 10): a press that hit-tests the pin is
## a remove candidate and never a place or move. The hit box is the mark's own double
## radius (PIN_HIT_RADIUS).
func pin_hit_test(local: Vector2) -> bool:
	if _pin == null:
		return false
	return (local_of(_pin as Vector2) - local).length() <= PIN_HIT_RADIUS


## Under-pin reads (N4/N10): the distance read rides the deck under the pin; the
## `NO HYPERDRIVE INSTALLED` caption is N4's own wording. Plain strings in, so the one
## distance format (the HUD's) is not duplicated here.
func set_pin_reads(distance_text: String, caption: String) -> void:
	_pin_distance_text = distance_text
	_pin_caption = caption
	if _pin_dist_label != null:
		_pin_dist_label.text = distance_text
		_pin_dist_label.visible = _pin_labels and not distance_text.is_empty()
	if _pin_caption_label != null:
		_pin_caption_label.text = caption
		_pin_caption_label.visible = _pin_labels and not caption.is_empty()
	_sync_marks()


## The compact map carries the pin mark and its edge arrow but no under-pin reads (those
## ride the deck and the compact footer's SectorLabel line, UI_SPEC.md section 10).
func set_pin_labels_visible(visible: bool) -> void:
	_pin_labels = visible
	set_pin_reads(_pin_distance_text, _pin_caption)


func _unit() -> float:
	var usable: float = minf(size.x, size.y) * 0.5
	return maxf(usable * _zoom, 0.001) / _world_radius


func _build_pin_marks() -> void:
	if _pin_stack != null:
		return
	_pin_stack = VBoxContainer.new()
	_pin_stack.name = &"PinStack"
	_pin_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_stack.add_theme_constant_override(&"separation", 2)
	_pin_diamond = PinDiamond.new()
	_pin_diamond.name = &"PinDiamond"
	_pin_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_diamond.radius = PIN_RADIUS
	_pin_diamond.colour = _token(PIN_COLOUR)
	_pin_stack.add_child(_pin_diamond)
	_pin_dist_label = Label.new()
	_pin_dist_label.name = &"PinDistanceCaption"
	_pin_dist_label.theme_type_variation = &"HudReadout"
	_pin_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_dist_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_stack.add_child(_pin_dist_label)
	_pin_caption_label = Label.new()
	_pin_caption_label.name = &"PinCaption"
	_pin_caption_label.theme_type_variation = &"HudReadout"
	_pin_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_stack.add_child(_pin_caption_label)
	add_child(_pin_stack)
	_pin_arrow = EdgeArrow.new()
	_pin_arrow.name = &"PinEdgeArrow"
	_pin_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_pin_arrow as EdgeArrow).length = PIN_ARROW_LENGTH
	(_pin_arrow as EdgeArrow).width = PIN_ARROW_WIDTH
	(_pin_arrow as EdgeArrow).colour = _token(PIN_COLOUR)
	add_child(_pin_arrow)
	_pin_stack.visible = false
	_pin_arrow.visible = false


## The two marks follow the projection: the diamond stack at the pin when it is in view,
## the bearing arrow clamped to this control's own edge when it is not (the bezel's inner
## rect on the compact map).
func _sync_marks() -> void:
	if _pin_stack == null:
		return
	if _pin == null:
		_pin_stack.visible = false
		_pin_arrow.visible = false
		return
	var offset: Vector2 = (_pin as Vector2 - map_origin()) * _unit()
	var usable: float = minf(size.x, size.y) * 0.5
	if offset.length() <= usable:
		var point := size * 0.5 + offset
		var mark_size: Vector2 = _pin_stack.get_combined_minimum_size()
		var diamond_half: float = _pin_diamond.custom_minimum_size.y * 0.5
		_pin_stack.position = point - Vector2(mark_size.x * 0.5, diamond_half)
		_pin_stack.visible = true
		_pin_arrow.visible = false
		return
	_pin_stack.visible = false
	_pin_arrow.visible = true
	var dir := offset.normalized()
	var inset: float = PIN_ARROW_LENGTH * 0.5 + 1.0
	var reach_x := INF
	var reach_y := INF
	if not is_zero_approx(dir.x):
		reach_x = (size.x * 0.5 - inset) / absf(dir.x)
	if not is_zero_approx(dir.y):
		reach_y = (size.y * 0.5 - inset) / absf(dir.y)
	var reach := minf(reach_x, reach_y)
	_pin_arrow.position = size * 0.5 + dir * reach - _pin_arrow.size * 0.5
	_pin_arrow.rotation = dir.angle()


func _draw() -> void:
	_draw_rose()
	_draw_blips()


## The blip kinds the compact legend names - the five shipped `KIND_*` constants the
## map has always drawn, and nothing else. The HUD's minimap legend is built from this
## list (D8 item 10), so it can never promise a kind the map does not draw. S29's six
## classes (N15-N22) draw through the same law but are named by the deck's filter
## column (`toggle_rows`), not by the legend: the compact minimap ships as today.
static func draw_kinds() -> Array[StringName]:
	return [KIND_SELF, KIND_HOSTILE, KIND_FRIENDLY, KIND_SWARMER, KIND_GHOST]


func _draw_rose() -> void:
	var centre: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 * ROSE_RADIUS_RATIO
	if radius <= 0.0:
		return
	var previous: Vector2 = centre + Vector2(radius, 0.0)
	for step: int in range(1, ROSE_SEGMENTS + 1):
		var angle: float = TAU * float(step) / float(ROSE_SEGMENTS)
		var point: Vector2 = centre + Vector2(cos(angle), sin(angle)) * radius
		draw_line(previous, point, _color_rose, ROSE_WIDTH)
		previous = point
	draw_line(centre + Vector2(0.0, -radius), centre + Vector2(0.0, -radius - CARDINAL_TICK), _color_rose, ROSE_WIDTH)
	draw_line(centre + Vector2(0.0, radius), centre + Vector2(0.0, radius + CARDINAL_TICK), _color_rose, ROSE_WIDTH)
	draw_line(centre + Vector2(-radius, 0.0), centre + Vector2(-radius - CARDINAL_TICK, 0.0), _color_rose, ROSE_WIDTH)
	draw_line(centre + Vector2(radius, 0.0), centre + Vector2(radius + CARDINAL_TICK, 0.0), _color_rose, ROSE_WIDTH)
	draw_line(centre, centre + Vector2(0.0, -NEEDLE_LENGTH), _color_needle, ROSE_WIDTH)
	draw_line(centre, centre + Vector2(0.0, NEEDLE_LENGTH * 0.5), _color_rose, ROSE_WIDTH)


func _draw_blips() -> void:
	var centre: Vector2 = size * 0.5
	var usable: float = minf(size.x, size.y) * 0.5
	if usable <= 0.0:
		return
	var unit: float = _unit()
	var origin: Vector2 = map_origin()
	for blip: Dictionary in _blips:
		var blip_position: Variant = blip.get("pos", null)
		if not (blip_position is Vector2):
			continue
		var world: Vector2 = blip_position
		var kind: StringName = blip.get("kind", &"")
		if not kind_visible(kind):
			continue
		var offset: Vector2 = (world - origin) * unit
		if kind != KIND_SELF and offset.length() > usable:
			continue
		_draw_blip(centre + offset, kind)


func _draw_blip(point: Vector2, kind: StringName) -> void:
	var colour: Color = _color_for(kind)
	if blip_mark(kind) == MARK_DIAMOND:
		draw_colored_polygon(_diamond(point, FRIENDLY_RADIUS), colour)
		return
	draw_circle(point, _radius_for(kind), colour)


func _diamond(centre: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		centre + Vector2(0.0, -radius),
		centre + Vector2(radius, 0.0),
		centre + Vector2(0.0, radius),
		centre + Vector2(-radius, 0.0),
	])


func _blip_origin() -> Vector2:
	## The player is the map centre; without a self blip the world origin is kept.
	for blip: Dictionary in _blips:
		if blip.get("kind", &"") != KIND_SELF:
			continue
		var blip_position: Variant = blip.get("pos", null)
		if blip_position is Vector2:
			return blip_position as Vector2
	return Vector2.ZERO


func _radius_for(kind: StringName) -> float:
	return SELF_RADIUS if kind == KIND_SELF else BLIP_RADIUS


func _color_for(kind: StringName) -> Color:
	if kind == KIND_SELF:
		return _color_self
	if kind == KIND_HOSTILE or kind == KIND_SWARMER:
		return _color_hostile
	if kind == KIND_FRIENDLY or kind == KIND_STATION or kind == KIND_GATE:
		return _color_friendly
	if kind == KIND_GHOST:
		return _ghost_color()
	return _color_neutral


## Section 3.3's ghost: the neutral token with only the alpha moved, so a ghost is
## a dim dot and never a hostile one. The colour is the same `_color_neutral` the
## other neutral blips wear, at the flicker's current reading.
func _ghost_color() -> Color:
	var colour: Color = _color_neutral
	colour.a = ghost_alpha(_ghost_clock)
	return colour


## Whether the feed carries a chaff ghost (section 4.6's `&"ghost"`).
func _has_ghost() -> bool:
	for blip: Dictionary in _blips:
		var kind: StringName = blip.get("kind", &"")
		if kind == KIND_GHOST:
			return true
	return false


## The flicker's repaint driver: on while a ghost is on the feed, off otherwise,
## and restarted from zero so a fresh chaff drop always opens at the same phase.
func _sync_ghost_flicker() -> void:
	var live := _has_ghost()
	if live == is_processing():
		return
	set_process(live)
	_ghost_clock = 0.0
	_ghost_elapsed = 0.0


func _refresh_colors() -> void:
	_color_self = _token(COLOR_SELF)
	_color_hostile = _token(COLOR_HOSTILE)
	_color_neutral = _token(COLOR_NEUTRAL)
	_color_friendly = _token(COLOR_FRIENDLY)
	_color_rose = _token(COLOR_ROSE)
	_color_needle = _token(COLOR_NEEDLE)
	## The pin's marks ride the same token feed: a theme change re-resolves them too
	## (S29-F1: the marks were born white because nothing ever assigned their colour).
	if _pin_diamond != null:
		_pin_diamond.colour = _token(PIN_COLOUR)
		_pin_diamond.queue_redraw()
	if _pin_arrow != null:
		_pin_arrow.colour = _token(PIN_COLOUR)
		_pin_arrow.queue_redraw()
	queue_redraw()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## S29's pin marks (UI_SPEC.md section 9 A5.2(iii): a code-drawn mark draws within its
## own child rect). `PinDiamond` is the diamond mark (6 px, `text_primary`); the stack
## around it carries the deck's under-pin reads (N4's caption, N10's distance);
## `EdgeArrow` is the bearing arrow clamped to the map's own edge when the pin is out of
## view. Each mark draws the deck's resolved pin token (`_token(PIN_COLOUR)`), handed
## to it at build time and re-read on theme changes, because an inner class cannot reach
## the enclosing class's helpers (the limit `hud.gd` documents).
class PinDiamond extends Control:
	var radius: float = 6.0
	var colour: Color = Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(14.0, 14.0)
		size = custom_minimum_size

	func _draw() -> void:
		var centre := size * 0.5
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(0.0, -radius),
			centre + Vector2(radius, 0.0),
			centre + Vector2(0.0, radius),
			centre + Vector2(-radius, 0.0),
		]), colour)


class EdgeArrow extends Control:
	const ARROW_RECT := Rect2(-7.0, -5.0, 14.0, 10.0)

	var length: float = 7.0
	var width: float = 2.0
	var colour: Color = Color.WHITE

	func _init() -> void:
		custom_minimum_size = ARROW_RECT.size
		size = custom_minimum_size
		pivot_offset = size * 0.5

	func _draw() -> void:
		## A wedge pointing +x (the mark is rotated towards the pin): a stem of `width`
		## and a head of `length`, both inside this mark's own rect.
		var centre := size * 0.5
		var stem := length * 0.45
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(-length * 0.5, -width * 0.5),
			centre + Vector2(stem - length * 0.5, -width * 0.5),
			centre + Vector2(length * 0.5, 0.0),
			centre + Vector2(stem - length * 0.5, width * 0.5),
			centre + Vector2(-length * 0.5, width * 0.5),
		]), colour)
