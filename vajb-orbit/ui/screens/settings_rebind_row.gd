extends HBoxContainer
## One rebindable action row: action label, primary and alternate bind buttons, per-row reset.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 4.5; docs/design/UI_SPEC.md section 4.3.
## The row shows binding state and emits intent; the settings screen owns SettingsManager.

signal binding_pressed(action: StringName, index: int)
signal reset_pressed(action: StringName)

const LISTEN_TEXT := "PRESS KEY…"
const TOKENS_TYPE: StringName = &"Tokens"
const CONFLICT_TOKEN: StringName = &"accent_danger"
const PRIMARY_INDEX := 0
const ALTERNATE_INDEX := 1

var action: StringName = &""

@onready var _label: Label = $ActionLabel
@onready var _primary: Button = $PrimaryButton
@onready var _alternate: Button = $AlternateButton
@onready var _reset: Button = $ResetButton

var _label_text := ""
var _primary_text := ""
var _alternate_text := ""
var _listening_index := -1
var _conflict := false


func _ready() -> void:
	_wire_focus()
	_primary.pressed.connect(_on_binding_button_pressed.bind(PRIMARY_INDEX))
	_alternate.pressed.connect(_on_binding_button_pressed.bind(ALTERNATE_INDEX))
	_reset.pressed.connect(_on_reset_button_pressed)
	_apply_texts()
	_apply_label_color()


func configure(action_name: StringName, label_text: String, primary_text: String, alternate_text: String) -> void:
	action = action_name
	_label_text = label_text
	set_binding_texts(primary_text, alternate_text)


func set_binding_texts(primary_text: String, alternate_text: String) -> void:
	_primary_text = primary_text
	_alternate_text = alternate_text
	_listening_index = -1
	_apply_texts_when_ready()


func set_listening(index: int) -> void:
	_listening_index = index
	_apply_texts_when_ready()


func set_conflict(enabled: bool) -> void:
	if _conflict == enabled:
		return
	_conflict = enabled
	if is_node_ready():
		_apply_label_color()


func focus_controls() -> Array[Button]:
	var controls: Array[Button] = []
	controls.append(_primary)
	controls.append(_alternate)
	controls.append(_reset)
	return controls


func focus_button(index: int) -> void:
	var controls := focus_controls()
	if index >= 0 and index < controls.size() and controls[index] != null:
		controls[index].grab_focus()


func _apply_texts_when_ready() -> void:
	# configure() may run either side of _ready(), so the @onready refs are checked first.
	if is_node_ready():
		_apply_texts()


func _apply_texts() -> void:
	_label.text = _label_text
	_primary.text = LISTEN_TEXT if _listening_index == PRIMARY_INDEX else _primary_text
	_alternate.text = LISTEN_TEXT if _listening_index == ALTERNATE_INDEX else _alternate_text


func _apply_label_color() -> void:
	if _conflict:
		_label.add_theme_color_override(&"font_color", _token(CONFLICT_TOKEN))
	else:
		_label.remove_theme_color_override(&"font_color")


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _wire_focus() -> void:
	_primary.focus_neighbor_right = _primary.get_path_to(_alternate)
	_primary.focus_neighbor_left = _primary.get_path_to(_reset)
	_alternate.focus_neighbor_right = _alternate.get_path_to(_reset)
	_alternate.focus_neighbor_left = _alternate.get_path_to(_primary)
	_reset.focus_neighbor_right = _reset.get_path_to(_primary)
	_reset.focus_neighbor_left = _reset.get_path_to(_alternate)


func _on_binding_button_pressed(index: int) -> void:
	binding_pressed.emit(action, index)


func _on_reset_button_pressed() -> void:
	reset_pressed.emit(action)
