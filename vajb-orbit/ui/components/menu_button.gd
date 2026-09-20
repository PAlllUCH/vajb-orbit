extends Control
## Reusable menu button: breathing 1 px border, hover ember glow, press inset.
## The focus ring of IMPLEMENTATION_PLAN section 3.11 is retired by section 9.8 item 1,
## so this control draws nothing extra for focus and the owning screen cues selection.
## Behaviour: docs/design/MAIN_MENU_SPEC.md section 4.
## Emits intent only; the owning screen connects the signals to AudioManager.

signal pressed
signal hovered
signal unhovered

const TOKENS_TYPE: StringName = &"Tokens"
const IDLE_BORDER_DARK: StringName = &"metal_mid"
const IDLE_BORDER_LIGHT: StringName = &"metal_light"
const HOVER_BORDER: StringName = &"text_primary"

const BREATH_PERIOD: float = 4.0
const BREATH_DESYNC: float = 0.6
const BORDER_WIDTH: float = 1.0
const MINIMUM_HEIGHT: float = 70.0
const PRESS_SCALE: float = 0.98
const PRESS_DURATION: float = 0.08
const GOLDEN_RATIO_STRIDE: float = 0.6180339887498949

static var _instance_index: int = 0

@export var text: String = "":
	set(value):
		text = value
		_push_text()

@onready var _glow: Control = $Glow
@onready var _button: Button = $Button

var _breath_tween: Tween
var _press_tween: Tween
var _breath_offset: float = 0.0
var _breath_from: Color = Color.WHITE
var _breath_to: Color = Color.WHITE
var _hover_color: Color = Color.WHITE
var _border_color: Color = Color.WHITE
var _hovered: bool = false


func _ready() -> void:
	_breath_offset = _take_breath_offset()
	_push_text()
	_sync_minimum_height()
	_button.pressed.connect(_on_button_pressed)
	_button.button_down.connect(_on_button_down)
	_button.button_up.connect(_on_button_up)
	_button.mouse_entered.connect(_on_mouse_entered)
	_button.mouse_exited.connect(_on_mouse_exited)
	_glow.visible = false
	_refresh_colors()
	_apply_breath(0.0)
	_start_breathing()


func _exit_tree() -> void:
	if _breath_tween != null and _breath_tween.is_valid():
		_breath_tween.kill()
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_refresh_colors()
		_apply_breath(0.0)
		_sync_minimum_height()


func _draw() -> void:
	var ring := Rect2(
		BORDER_WIDTH * 0.5,
		BORDER_WIDTH * 0.5,
		size.x - BORDER_WIDTH,
		size.y - BORDER_WIDTH
	)
	if _hovered:
		draw_rect(ring, _hover_color, false, BORDER_WIDTH)
	else:
		draw_rect(ring, _border_color, false, BORDER_WIDTH)


func set_text(value: String) -> void:
	# In-class assignment writes the member directly, so the property setter
	# that forwards to the inner Button has to be pushed explicitly here.
	text = value
	_push_text()


func _push_text() -> void:
	# text can be written before _ready assigns the @onready reference, so the
	# inner Button is resolved on demand until then.
	var button: Button = _button
	if button == null:
		button = get_node_or_null(^"Button") as Button
	if button != null:
		button.text = text


func _sync_minimum_height() -> void:
	## The row height follows the font: the plate art's designed height is the floor and
	## the inner Button's font-driven minimum overtakes it as ui_scale grows, so no
	## consumer can pin the row to a constant (MAIN_MENU_V2 section 12.1).
	custom_minimum_size.y = maxf(MINIMUM_HEIGHT, _button.get_minimum_size().y)


func _start_breathing() -> void:
	if _breath_tween != null and _breath_tween.is_valid():
		_breath_tween.kill()
	_breath_tween = create_tween()
	_breath_tween.set_loops()
	_breath_tween.tween_method(_apply_breath, 0.0, BREATH_PERIOD, BREATH_PERIOD).set_trans(Tween.TRANS_LINEAR)


func _apply_breath(elapsed: float) -> void:
	var phase: float = fposmod((elapsed + _breath_offset) / BREATH_PERIOD, 1.0)
	# A cosine ping-pong is ease-in-out sine; it carries the per-instance phase
	# offset without stretching the 4 s loop, which a per-step delay would do.
	var wave: float = (1.0 - cos(TAU * phase)) * 0.5
	_border_color = _breath_from.lerp(_breath_to, wave)
	queue_redraw()


func _refresh_colors() -> void:
	_breath_from = _token(IDLE_BORDER_DARK)
	_breath_to = _token(IDLE_BORDER_LIGHT)
	_hover_color = _token(HOVER_BORDER)


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


static func _take_breath_offset() -> float:
	# Low-discrepancy stride keeps consecutive buttons spread across
	# -BREATH_DESYNC..BREATH_DESYNC instead of colliding on one phase.
	var fraction: float = fposmod(float(_instance_index) * GOLDEN_RATIO_STRIDE, 1.0)
	_instance_index += 1
	return BREATH_DESYNC * (2.0 * fraction - 1.0)


func _tween_press_scale(target: float) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	pivot_offset = size * 0.5
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2(target, target), PRESS_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_button_pressed() -> void:
	pressed.emit()


func _on_button_down() -> void:
	_glow.visible = false
	_tween_press_scale(PRESS_SCALE)


func _on_button_up() -> void:
	_tween_press_scale(1.0)
	_glow.visible = _hovered


func _on_mouse_entered() -> void:
	if _hovered:
		return
	_hovered = true
	_glow.visible = true
	queue_redraw()
	hovered.emit()


func _on_mouse_exited() -> void:
	if not _hovered:
		return
	_hovered = false
	_glow.visible = false
	queue_redraw()
	unhovered.emit()
