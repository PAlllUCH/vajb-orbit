class_name SlotButton
extends TextureButton
## Reusable HUD slot cell for the weapon grid and the cargo grid.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 2 and 4.7.
## Plate states come from the theme variations SlotButtonWeapon / SlotButtonCargo;
## the active-weapon frame is script-drawn, never a fifth texture (UI_SPEC 3.2).

const TOKENS_TYPE: StringName = &"Tokens"

const VARIATION_WEAPON: StringName = &"SlotButtonWeapon"
const VARIATION_CARGO: StringName = &"SlotButtonCargo"

const STATE_NORMAL: StringName = &"normal"
const STATE_HOVER: StringName = &"hover"
const STATE_PRESSED: StringName = &"pressed"
const STATE_DISABLED: StringName = &"disabled"

const CELL_SIZE_WEAPON: Vector2 = Vector2(48.0, 48.0)
const CELL_SIZE_CARGO: Vector2 = Vector2(40.0, 40.0)

const TOKEN_ACTIVE: StringName = &"text_primary"
const TOKEN_INACTIVE: StringName = &"text_dim"
const TOKEN_FRAME: StringName = &"accent_danger"

const FRAME_WIDTH: float = 1.0

@onready var _icon: TextureRect = $Icon
@onready var _number: Label = $Number

var _icon_texture: Texture2D = null
var _icon_token: StringName = TOKEN_INACTIVE
var _number_text: String = ""
var _active: bool = false
var _frame_color: Color = Color.WHITE


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_apply_plates(theme_type_variation)
	_push_icon()
	_push_number()
	_refresh_frame_color()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_apply_plates(theme_type_variation)
		_push_icon()
		_refresh_frame_color()


func _draw() -> void:
	if not _active:
		return
	var inset: float = FRAME_WIDTH * 0.5
	draw_rect(Rect2(inset, inset, size.x - FRAME_WIDTH, size.y - FRAME_WIDTH), _frame_color, false, FRAME_WIDTH)


func configure(variation: StringName, icon: Texture2D, number: int = 0, icon_token: StringName = TOKEN_INACTIVE) -> void:
	theme_type_variation = variation
	ignore_texture_size = true
	custom_minimum_size = CELL_SIZE_WEAPON if variation == VARIATION_WEAPON else CELL_SIZE_CARGO
	_icon_texture = icon
	_icon_token = icon_token
	_number_text = "" if number <= 0 else str(number)
	_apply_plates(variation)
	_push_icon()
	_push_number()


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	_refresh_frame_color()
	queue_redraw()


func is_active() -> bool:
	return _active


func set_icon_token(icon_token: StringName) -> void:
	if _icon_token == icon_token:
		return
	_icon_token = icon_token
	_push_icon()


func _apply_plates(variation: StringName) -> void:
	if variation.is_empty():
		return
	var normal: Texture2D = _plate_texture(variation, STATE_NORMAL)
	var hover: Texture2D = _plate_texture(variation, STATE_HOVER)
	var pressed: Texture2D = _plate_texture(variation, STATE_PRESSED)
	var disabled: Texture2D = _plate_texture(variation, STATE_DISABLED)
	if normal != null:
		texture_normal = normal
	if hover != null:
		texture_hover = hover
	if pressed != null:
		texture_pressed = pressed
	if disabled != null:
		texture_disabled = disabled


func _plate_texture(variation: StringName, state: StringName) -> Texture2D:
	if not has_theme_stylebox(state, variation):
		return null
	var box: StyleBox = get_theme_stylebox(state, variation)
	if box is StyleBoxTexture:
		return (box as StyleBoxTexture).texture
	return null


func _push_icon() -> void:
	var icon: TextureRect = _icon
	if icon == null:
		icon = get_node_or_null(^"Icon") as TextureRect
	if icon == null:
		return
	icon.texture = _icon_texture
	icon.modulate = _token(_icon_token)


func _push_number() -> void:
	var number: Label = _number
	if number == null:
		number = get_node_or_null(^"Number") as Label
	if number == null:
		return
	number.text = _number_text
	number.visible = not _number_text.is_empty()


func _refresh_frame_color() -> void:
	_frame_color = _token(TOKEN_FRAME)
	queue_redraw()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE
