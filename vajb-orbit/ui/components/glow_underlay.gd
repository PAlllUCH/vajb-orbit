extends Control
## Engine-drawn 6 px ember halo drawn behind the button plate, hover only.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.11.
## The halo is never baked art (docs/design/UI_CHROME_ASSETS_SPEC.md section 3).
## This node is outset 6 px around the plate, so its own rect is the halo band.

const UiTokensScript := preload("res://ui/components/ui_tokens.gd")
const GLOW_COLOR: StringName = &"menu_glow"
const HALO_EXPAND: float = 6.0

var _style: StyleBoxFlat


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.expand_margin_left = HALO_EXPAND
	_style.expand_margin_top = HALO_EXPAND
	_style.expand_margin_right = HALO_EXPAND
	_style.expand_margin_bottom = HALO_EXPAND
	_refresh_glow()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _style != null:
		_refresh_glow()


func _draw() -> void:
	if _style == null or _style.bg_color.a <= 0.0:
		return
	var plate := Rect2(
		Vector2(HALO_EXPAND, HALO_EXPAND),
		size - Vector2(HALO_EXPAND * 2.0, HALO_EXPAND * 2.0)
	)
	draw_style_box(_style, plate)


func _refresh_glow() -> void:
	_style.bg_color = _token(GLOW_COLOR)
	queue_redraw()


func _token(token: StringName) -> Color:
	return UiTokensScript.colour(self, token, Color.TRANSPARENT)
