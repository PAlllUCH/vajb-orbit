extends PanelContainer
## N27 hover tooltip (UI_SPEC section 5.1 + 12.2): the hover sink of the station's
## `inspect_requested` chain (P21). One BBCode `RichTextLabel` under a `tooltip_panel`
## stylebox, 320 px cap, cursor + (12, 12), clamped to the viewport (N32), and
## `MOUSE_FILTER_IGNORE` so it never eats the pointer that summoned it.
##
## Grammar (section 5.1 unchanged): the identity line in `text_primary` bold, the body in
## `text_dim`, a danger clause in `accent_danger`, then N33's own hint line `INSPECT`.
## Colours are read off the theme's Tokens (never hardcoded), so a token change moves the
## tooltip with the rest of the chrome.
##
## The tooltip is a pure reading: it owns no state beyond what it draws, and showing or
## hiding it mutates only its own `visible` and `position` (A5.5 is about the panes' state
## handlers; the tooltip is an overlay, not in-flow).

const TOKENS_TYPE: StringName = &"Tokens"
const CAP_WIDTH := 320.0
const CURSOR_OFFSET := Vector2(12.0, 12.0)
const VIEWPORT_MARGIN := 8.0
const HINT_TEXT := "INSPECT"
const DANGER_FALLBACK := Color("c8471f")

@onready var _label: RichTextLabel = %TooltipLabel

var _title: String = ""
var _body: String = ""
var _danger: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_refresh()


## Show the tooltip for one payload at `cursor`, clamped into `viewport_size` (N32).
func show_for(title: String, body: String, danger: bool, cursor: Vector2, viewport_size: Vector2) -> void:
	_title = title
	_body = body
	_danger = danger
	_refresh()
	visible = true
	_place(cursor, viewport_size)


func hide_tooltip() -> void:
	visible = false


func is_open() -> bool:
	return visible


func content_title() -> String:
	return _title


func content_body() -> String:
	return _body


## The label's own text, for probes: the BBCode the tooltip renders.
func rendered_text() -> String:
	return "" if _label == null else _label.text


func _refresh() -> void:
	if _label == null:
		return
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(CAP_WIDTH, 0.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = _compose()


func _compose() -> String:
	if _title.is_empty() and _body.is_empty():
		return ""
	var primary := _html(_token(&"text_primary"))
	var dim := _html(_token(&"text_dim"))
	var danger := _html(_token(&"accent_danger", DANGER_FALLBACK))
	var lines := PackedStringArray()
	if not _title.is_empty():
		lines.append("[b][color=#%s]%s[/color][/b]" % [primary, _title])
	if not _body.is_empty():
		var body_color := danger if _danger else dim
		lines.append("[color=#%s]%s[/color]" % [body_color, _body])
	lines.append("[color=#%s]%s[/color]" % [dim, HINT_TEXT])
	return "\n".join(lines)


## N32's clamp: flip to the cursor's opposite quadrant on an overflowing axis, then keep
## the box 8 px inside the viewport. The anchor is the tooltip's own top-left (N27).
func _place(cursor: Vector2, viewport_size: Vector2) -> void:
	reset_size()
	var box := size
	var pos := cursor + CURSOR_OFFSET
	if pos.x + box.x > viewport_size.x - VIEWPORT_MARGIN:
		pos.x = cursor.x - CURSOR_OFFSET.x - box.x
	if pos.y + box.y > viewport_size.y - VIEWPORT_MARGIN:
		pos.y = cursor.y - CURSOR_OFFSET.y - box.y
	pos.x = clampf(pos.x, VIEWPORT_MARGIN, maxf(VIEWPORT_MARGIN, viewport_size.x - box.x - VIEWPORT_MARGIN))
	pos.y = clampf(pos.y, VIEWPORT_MARGIN, maxf(VIEWPORT_MARGIN, viewport_size.y - box.y - VIEWPORT_MARGIN))
	position = pos


func _token(token: StringName, fallback: Color = Color.WHITE) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return fallback


static func _html(colour: Color) -> String:
	return colour.to_html(false)
