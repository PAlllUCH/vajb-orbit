class_name Minimap
extends Control
## Custom-drawn minimap: compass rose, contact blips, no per-frame work.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.10 and 4.7.
## Blip positions are world coordinates; set_world_radius maps them onto the
## control's square around the self blip, so the map stays player-centred however
## far the ship flies. The compass rose is script-drawn by design (ICONS_SPEC preamble).
## Blip classes follow ENGINE_SPEC section 8 / 11 section 3.3: friendly (stations,
## gates, beacons), neutral (derelicts, convoys, scanned anomalies), hostile
## (pirates, hunters). Friendly blips are the one class drawn as a diamond, so a
## station stays readable next to the player-centred self blip, which shares their
## text_primary tint (UI_SPEC section 3.3).

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

const DEFAULT_WORLD_RADIUS: float = 4000.0
const SELF_RADIUS: float = 3.0
const BLIP_RADIUS: float = 2.0
const FRIENDLY_RADIUS: float = 3.0
const ROSE_RADIUS_RATIO: float = 0.36
const ROSE_SEGMENTS: int = 48
const ROSE_WIDTH: float = 1.0
const CARDINAL_TICK: float = 4.0
const NEEDLE_LENGTH: float = 7.0

var _world_radius: float = DEFAULT_WORLD_RADIUS
var _blips: Array = []
var _color_self: Color = Color.WHITE
var _color_hostile: Color = Color.WHITE
var _color_neutral: Color = Color.WHITE
var _color_friendly: Color = Color.WHITE
var _color_rose: Color = Color.WHITE
var _color_needle: Color = Color.WHITE


func _ready() -> void:
	_refresh_colors()


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
	queue_redraw()


func world_radius() -> float:
	return _world_radius


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
	if kind == KIND_HOSTILE:
		return _color_hostile
	if kind == KIND_FRIENDLY:
		return _color_friendly
	return _color_neutral


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
