class_name TargetReticle
extends Control
## Custom-drawn reticle in two modes: the lock (four 8 px corner brackets plus a
## hull micro-bar at a marked target's screen position) and the cursor reticle
## with its plain / in-range / out-of-range / hostile states.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.10, 4.7 and the 9.9
## engine-wave amendment (the reticle is drawn at the cursor; slice 1 ships the
## plain and mining states), UI_SPEC section 3.5.
## The cursor mode follows the pointer from its own motion event, so it needs no
## caller and no per-frame poll; a caller may still push a screen position with
## `set_cursor_position`, and the lock keeps its section 3.10 `set_target` /
## `clear_target` pair.

const TOKENS_TYPE: StringName = &"Tokens"
const COLOR_LOCK: StringName = &"accent_danger"
const COLOR_PLAIN: StringName = &"text_dim"
const COLOR_ENGAGED: StringName = &"text_primary"

## Reticle states (IMPLEMENTATION_PLAN section 9.9, ENGINE_SPEC section 10).
## `IN_RANGE` / `OUT_OF_RANGE` are the mining laser's states in slice 1 (the beam
## reaches MINE_LASER_RANGE 220 u, ENGINE_SPEC section 6) and `HOSTILE` is the
## slice-2 lock-on reading. Steel tokens only: the ember accent stays reserved
## for the lock brackets and danger states (ICONS_SPEC section 1).
enum State {
	PLAIN,
	IN_RANGE,
	OUT_OF_RANGE,
	HOSTILE,
}

const BRACKET_ARM: float = 8.0
const BRACKET_WIDTH: float = 1.0
const CURSOR_AXES: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN]
const CURSOR_CORNERS: Array[Vector2] = [
	Vector2(1.0, 1.0),
	Vector2(-1.0, 1.0),
	Vector2(1.0, -1.0),
	Vector2(-1.0, -1.0),
]
const CURSOR_GAP: float = 4.0
const CURSOR_TICK: float = 6.0
const CURSOR_RADIUS: float = 11.0
const CURSOR_DOT: float = 1.0
const CURSOR_SLASH: float = 9.0

@onready var _bar_box: VBoxContainer = $ReticleBarBox
@onready var _hull_bar: ProgressBar = $ReticleBarBox/ReticleHullBar

var _color_lock: Color = Color.WHITE
var _color_plain: Color = Color.WHITE
var _color_engaged: Color = Color.WHITE
var _state: int = State.PLAIN
var _cursor_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _screen_position: Vector2 = Vector2.ZERO
var _hull_fraction: float = 0.0


func _ready() -> void:
	_refresh_colors()
	var viewport := get_viewport()
	if viewport != null:
		_cursor_position = viewport.get_mouse_position()
	_apply()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_refresh_colors()


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	set_cursor_position(motion.position)


func set_cursor_position(screen_position: Vector2) -> void:
	if _cursor_position == screen_position:
		return
	_cursor_position = screen_position
	_apply()


func set_state(state: int) -> void:
	var wanted: int = clampi(state, State.PLAIN, State.HOSTILE)
	if wanted == _state:
		return
	_state = wanted
	queue_redraw()


## Read-only state, so a caller or a probe can assert what the reticle draws.
func state() -> int:
	return _state


## Section 3.10: a marked target takes the draw over from the cursor reticle until
## `clear_target` returns it (the frozen pair stays wired for slice 2).
func set_target(screen_position: Vector2, hull_fraction: float) -> void:
	_screen_position = screen_position
	_hull_fraction = clampf(hull_fraction, 0.0, 1.0)
	_has_target = true
	_apply()
	queue_redraw()


## Dropping the lock also returns the reticle to the cursor, which is always drawn
## (section 9.9), so the lock's brackets and micro-bar are what disappear.
func clear_target() -> void:
	if not _has_target:
		return
	_has_target = false
	_apply()
	queue_redraw()


func _draw() -> void:
	if _has_target:
		_draw_lock()
		return
	_draw_cursor()


## UI_SPEC section 3.5's lock look: 4 x 8 px L-shaped brackets at the box corners.
func _draw_lock() -> void:
	var inset: float = BRACKET_WIDTH * 0.5
	var left: float = inset
	var top: float = inset
	var right: float = size.x - inset
	var bottom: float = size.y - inset
	_bracket(Vector2(left, top), 1.0, 1.0, _color_lock)
	_bracket(Vector2(right, top), -1.0, 1.0, _color_lock)
	_bracket(Vector2(left, bottom), 1.0, -1.0, _color_lock)
	_bracket(Vector2(right, bottom), -1.0, -1.0, _color_lock)


## The cursor mode. Plain and hostile draw the offset crosshair; the mining states
## draw a focus box instead, dimmed with a range slash when the beam cannot reach
## the cursor (out of range).
func _draw_cursor() -> void:
	var centre: Vector2 = size * 0.5
	var colour: Color = _cursor_color()
	if _state == State.IN_RANGE or _state == State.OUT_OF_RANGE:
		for corner: Vector2 in CURSOR_CORNERS:
			_bracket(centre + corner * CURSOR_RADIUS, corner.x, corner.y, colour)
	else:
		_draw_crosshair(centre, colour)
	if _state == State.OUT_OF_RANGE:
		draw_line(
			centre + Vector2(-CURSOR_SLASH, CURSOR_SLASH),
			centre + Vector2(CURSOR_SLASH, -CURSOR_SLASH),
			colour,
			BRACKET_WIDTH
		)
	draw_circle(centre, CURSOR_DOT, colour)


func _draw_crosshair(centre: Vector2, colour: Color) -> void:
	for axis: Vector2 in CURSOR_AXES:
		draw_line(
			centre + axis * CURSOR_GAP,
			centre + axis * (CURSOR_GAP + CURSOR_TICK),
			colour,
			BRACKET_WIDTH
		)
		draw_line(
			centre - axis * CURSOR_GAP,
			centre - axis * (CURSOR_GAP + CURSOR_TICK),
			colour,
			BRACKET_WIDTH
		)


func _bracket(corner: Vector2, horizontal: float, vertical: float, colour: Color) -> void:
	draw_line(corner, corner + Vector2(BRACKET_ARM * horizontal, 0.0), colour, BRACKET_WIDTH)
	draw_line(corner, corner + Vector2(0.0, BRACKET_ARM * vertical), colour, BRACKET_WIDTH)


## Section 9.9: the cursor reticle is always drawn, so only the lock's micro-bar
## appears and disappears; the position follows whichever mode owns the draw.
func _apply() -> void:
	visible = true
	if _has_target:
		position = _screen_position - size * 0.5
		if _bar_box != null:
			_bar_box.visible = true
		if _hull_bar != null:
			_hull_bar.value = _hull_fraction * 100.0
		return
	if _bar_box != null:
		_bar_box.visible = false
	position = _cursor_position - size * 0.5


func _cursor_color() -> Color:
	if _state == State.HOSTILE:
		return _color_lock
	if _state == State.IN_RANGE:
		return _color_engaged
	return _color_plain


func _refresh_colors() -> void:
	_color_lock = _token(COLOR_LOCK)
	_color_plain = _token(COLOR_PLAIN)
	_color_engaged = _token(COLOR_ENGAGED)
	queue_redraw()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE
