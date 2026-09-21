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


func _ready() -> void:
	_refresh_colors()
	set_process(_has_ghost())


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh_colors()


func set_world_radius(world_radius: float) -> void:
	var radius: float = maxf(world_radius, 1.0)
	if is_equal_approx(radius, _world_radius):
		return
	_world_radius = radius
	queue_redraw()


func set_blips(blips: Array[Dictionary]) -> void:
	if _blips == blips:
		return
	_blips = blips.duplicate()
	_sync_ghost_flicker()
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


func _draw() -> void:
	_draw_rose()
	_draw_blips()


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
	var unit: float = usable / _world_radius
	var origin: Vector2 = _blip_origin()
	for blip: Dictionary in _blips:
		var blip_position: Variant = blip.get("pos", null)
		if not (blip_position is Vector2):
			continue
		var world: Vector2 = blip_position
		var kind: StringName = blip.get("kind", &"")
		var offset: Vector2 = (world - origin) * unit
		if kind != KIND_SELF and offset.length() > usable:
			continue
		_draw_blip(centre + offset, kind)


func _draw_blip(point: Vector2, kind: StringName) -> void:
	var colour: Color = _color_for(kind)
	if kind == KIND_FRIENDLY:
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
	if kind == KIND_FRIENDLY:
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
	queue_redraw()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE
