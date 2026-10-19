extends Control
## N28's INSPECT sheet (UI_SPEC section 5.2's modal idiom + section 12.3): the explicit
## sink of the station's `inspect_requested` chain (P21). A full-rect `MOUSE_FILTER_STOP`
## root, a `void_base` 60 % dimmer, a centred `panel_raised` sheet, a 16 px margin and a
## 12 px VBox of read-only rows.
##
## Size law (N28): size-to-content on both axes inside a min 420 / max 720 px band, under
## N32's 80 %-viewport scroll rule - the body scrolls before the sheet leaves the viewport.
## Open/close is N29's envelope: `modulate:a` 0 -> 1 / 1 -> 0 in 0.18 s `TRANS_CUBIC`
## `EASE_OUT` (an overlay, so A5.5 never touches the layout).
##
## One sheet at a time (§5.2): a second `open()` while one is up queues behind the first
## rather than stacking. ESC and the scrim both close it (N38); the shell owns the ESC
## route and the focus return (N39).

signal closed

const UiTokensScript := preload("res://ui/components/ui_tokens.gd")

const MIN_WIDTH := 420.0
const MAX_WIDTH := 720.0
const PANEL_MARGIN := 16.0
const MAX_HEIGHT_RATIO := 0.8
const DIMMER_ALPHA := 0.6
const MOTION_SECONDS := 0.18

## N35's formats and the payload keys every pane fills (rows appear only where the data
## carries them, N35's own rule).
const KEY_NAME: StringName = &"name"
const KEY_AFFIXES: StringName = &"affixes"
const KEY_AFFIX_DANGER: StringName = &"affix_danger"
const KEY_STATS: StringName = &"stats"
const KEY_FAMILY: StringName = &"family"
const KEY_PRICE: StringName = &"price"
const KEY_OWNED: StringName = &"owned"

const FAMILY_FORMAT := "SLOT FAMILY · %s"
const PRICE_FORMAT := "%d CR"
const OWNED_FORMAT := "OWNED ×%d"
const CLOSE_HINT := "ESC · CLOSE"

@onready var _dimmer: ColorRect = %SheetDimmer
@onready var _panel: PanelContainer = %SheetPanel
@onready var _scroll: ScrollContainer = %SheetScroll
@onready var _content: VBoxContainer = %SheetContent
@onready var _name_label: Label = %SheetName
@onready var _affix_label: Label = %SheetAffixes
@onready var _stats_label: Label = %SheetStats
@onready var _family_label: Label = %SheetFamily
@onready var _value_label: Label = %SheetValue
@onready var _hint_label: Label = %SheetHint

var _tween: Tween = null
var _open := false
var _pending: Dictionary = {}
var _has_pending := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	_apply_tokens()
	_dimmer.gui_input.connect(_on_dimmer_input)
	_clear_rows()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


## Open the sheet for one payload; a second open while one is up queues (section 5.2).
func open(payload: Dictionary) -> void:
	if _open:
		_pending = payload
		_has_pending = true
		return
	_fill(payload)
	_open = true
	visible = true
	modulate.a = 0.0
	_fit()
	_animate(1.0)


## Close the topmost sheet; the queued payload (if any) opens behind it. `_open` flips
## immediately so the ESC route is one operation (P19); the fade is cosmetic.
func close() -> void:
	if not _open:
		return
	_open = false
	_animate(0.0, true)


func is_open() -> bool:
	return _open


## How many payloads wait behind the open sheet (section 5.2's queue), for probes.
func pending_count() -> int:
	return 1 if _has_pending else 0


## The sheet's own row text, for probes: name, affixes, stats, family, value, hint.
func row_texts() -> PackedStringArray:
	return PackedStringArray([
		_name_label.text,
		_affix_label.text,
		_stats_label.text,
		_family_label.text,
		_value_label.text,
		_hint_label.text,
	])


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _fill(payload: Dictionary) -> void:
	var name_text := String(payload.get(KEY_NAME, ""))
	_name_label.text = name_text
	_name_label.visible = not name_text.is_empty()
	var affixes := _lines(payload.get(KEY_AFFIXES, PackedStringArray()))
	_affix_label.text = "\n".join(affixes)
	_affix_label.visible = not affixes.is_empty()
	if bool(payload.get(KEY_AFFIX_DANGER, false)):
		_affix_label.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	else:
		_affix_label.remove_theme_color_override(&"font_color")
	var stats := String(payload.get(KEY_STATS, ""))
	_stats_label.text = stats
	_stats_label.visible = not stats.is_empty()
	var family := String(payload.get(KEY_FAMILY, ""))
	_family_label.text = FAMILY_FORMAT % family if not family.is_empty() else ""
	_family_label.visible = not family.is_empty()
	var price := int(payload.get(KEY_PRICE, -1))
	var owned := int(payload.get(KEY_OWNED, -1))
	var value_text := ""
	if price >= 0:
		value_text = PRICE_FORMAT % price
	elif owned >= 0:
		value_text = OWNED_FORMAT % owned
	_value_label.text = value_text
	_value_label.visible = not value_text.is_empty()
	_hint_label.text = CLOSE_HINT
	_hint_label.visible = true


func _clear_rows() -> void:
	for label: Label in [_name_label, _affix_label, _stats_label, _family_label, _value_label, _hint_label]:
		label.text = ""
		label.visible = false


## Size-to-content inside N28's band: measure every row's natural width, floor at 420, cap
## at 720 (the rows then wrap at that edge), then cap the height at N32's 80 % viewport.
## S30-F1 (F3): the content node is re-sized, never the anchor-laid-out root - a root
## `reset_size()` collapses the full-rect sheet to 0x0 and the CenterContainer then centres
## the panel on the screen's top-left corner.
func _fit() -> void:
	_panel.custom_minimum_size.x = MIN_WIDTH
	_scroll.custom_minimum_size.y = 0.0
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.reset_size()
	var widest := 0.0
	for label: Label in [_name_label, _affix_label, _stats_label, _family_label, _value_label, _hint_label]:
		if not label.visible:
			continue
		widest = maxf(widest, _text_width(label))
	var target := clampf(widest + PANEL_MARGIN * 2.0, MIN_WIDTH, MAX_WIDTH)
	_panel.custom_minimum_size.x = target
	for label: Label in [_name_label, _affix_label, _stats_label, _family_label, _value_label, _hint_label]:
		label.custom_minimum_size.x = target - PANEL_MARGIN * 2.0
	_content.reset_size()
	var cap := _viewport_size().y * MAX_HEIGHT_RATIO - PANEL_MARGIN * 2.0
	var content_h := _content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = maxf(0.0, minf(content_h, cap))
	_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if content_h > cap
		else ScrollContainer.SCROLL_MODE_DISABLED
	)


func _text_width(label: Label) -> float:
	var font := label.get_theme_font(&"font")
	if font == null:
		return 0.0
	var size := label.get_theme_font_size(&"font_size")
	var widest := 0.0
	for line: String in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


func _animate(target: float, then_hide: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", target, MOTION_SECONDS)
	if then_hide:
		_tween.tween_callback(_on_closed)


func _on_closed() -> void:
	visible = false
	if _has_pending:
		var queued := _pending
		_has_pending = false
		_pending = {}
		open(queued)
	closed.emit()


func _apply_tokens() -> void:
	var dim: Color = _token(&"void_base")
	dim.a = DIMMER_ALPHA
	_dimmer.color = dim
	_name_label.add_theme_color_override(&"font_color", _token(&"text_primary"))
	_affix_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
	_stats_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
	_family_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
	_value_label.add_theme_color_override(&"font_color", _token(&"text_primary"))
	_hint_label.add_theme_color_override(&"font_color", _token(&"text_dim"))


func _viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2(1920.0, 1080.0)
	return viewport.get_visible_rect().size


func _lines(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is PackedStringArray:
		return value
	if value is Array:
		for item: Variant in value:
			out.append(String(item))
	return out


func _token(token: StringName) -> Color:
	return UiTokensScript.colour(self, token)
