extends Screen
## Shared confirm/message dialog. Structure: UI_SPEC section 5.2,
## contract: IMPLEMENTATION_PLAN section 4.4. DialogManager owns its lifecycle;
## this scene only reports the outcome.

const TOKENS_TYPE: StringName = &"Tokens"

const DIMMER_ALPHA: float = 0.6

const PARAM_ID: StringName = &"id"
const PARAM_TITLE: StringName = &"title"
const PARAM_BODY: StringName = &"body"
const PARAM_CONFIRM_TEXT: StringName = &"confirm_text"
const PARAM_CANCEL_TEXT: StringName = &"cancel_text"

@export var default_title: String = ""
@export var default_body: String = ""
@export var default_confirm_text: String = "CONFIRM"
@export var default_cancel_text: String = "CANCEL"
## MAIN_MENU_SPEC section 6 keeps a destructive default CANCELLED (quit_confirm.tscn
## turns this off); every other dialog opens with CONFIRM focused (UI_SPEC section 5.2).
@export var focus_confirm: bool = true

@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton

var _dialog_id: StringName = &""
var _resolved: bool = false


func _ready() -> void:
	_apply_theme_styles()
	_push_texts()
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	# Deferred so Router still records the screen behind the dialog as the focus
	# opener and can restore it when the overlay is popped.
	_grab_default_focus.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_theme_styles()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	_resolve(false)


func on_route(params: Dictionary) -> void:
	_dialog_id = StringName(_param(params, PARAM_ID, _dialog_id))
	configure(
		String(_param(params, PARAM_TITLE, default_title)),
		String(_param(params, PARAM_BODY, default_body)),
		String(_param(params, PARAM_CONFIRM_TEXT, default_confirm_text)),
		String(_param(params, PARAM_CANCEL_TEXT, default_cancel_text))
	)


func configure(title: String, body: String, confirm_text: String, cancel_text: String) -> void:
	default_title = title
	default_body = body
	default_confirm_text = confirm_text
	default_cancel_text = cancel_text
	if is_node_ready():
		_push_texts()


func _on_confirm_pressed() -> void:
	_resolve(true)


func _on_cancel_pressed() -> void:
	_resolve(false)


func _resolve(confirmed: bool) -> void:
	if _resolved:
		return
	_resolved = true
	if _dialog_id != &"":
		DialogManager.resolved(_dialog_id, confirmed)
		return
	overlay_close_requested.emit()
	if confirmed:
		Router.request_quit()


func _push_texts() -> void:
	_title_label.text = default_title
	_body_label.text = default_body
	_confirm_button.text = default_confirm_text
	_cancel_button.text = default_cancel_text


func _grab_default_focus() -> void:
	var target := _confirm_button if focus_confirm else _cancel_button
	target.grab_focus()


func _apply_theme_styles() -> void:
	var source := theme
	if source == null:
		return
	_dimmer.color = _with_alpha(_token(&"void_base"), DIMMER_ALPHA)
	var panel_style := source.get_stylebox(&"panel_raised", &"")
	if panel_style != null:
		_panel.add_theme_stylebox_override(&"panel", panel_style)
	var danger_style := _danger_normal_style(source)
	if danger_style != null:
		_confirm_button.add_theme_stylebox_override(&"normal", danger_style)


func _danger_normal_style(source: Theme) -> StyleBox:
	var base := source.get_stylebox(&"button_normal", &"")
	if base == null:
		return null
	var style := base.duplicate() as StyleBox
	if style is StyleBoxFlat:
		(style as StyleBoxFlat).border_color = _token(&"accent_danger")
	return style


func _param(params: Dictionary, key: StringName, fallback: Variant) -> Variant:
	if params.has(key):
		return params[key]
	var text_key := String(key)
	if params.has(text_key):
		return params[text_key]
	return fallback


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.BLACK
