extends Screen
## Boot sequence: solid void, logo fade, one ember flicker, a three-tick progress
## line, then a crossfade whose completion hands the route to the Router.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 4.1, docs/design/MAIN_MENU_SPEC.md section 1.
## Key presses are ignored and nothing here is focusable, so the scene holds no interactive control.
## Boot stays silent: MAIN_MENU_SPEC section 1 defines no audio cue for it.

const TOKENS_TYPE: StringName = &"Tokens"
const MAIN_MENU_ROUTE: StringName = &"main_menu"

const LOGO_FADE_START := 0.5
const SKIP_TO_SECONDS := 1.4
const LOGO_FADE_SECONDS := SKIP_TO_SECONDS - LOGO_FADE_START
const FLICKER_SECONDS := 0.15
const TICK_FRACTIONS: Array[float] = [0.25, 0.6, 1.0]
const TICK_RISE_SECONDS := 0.2
const TICK_GAP_SECONDS := 0.1
const TICK_TAIL_SECONDS := 0.2
const LINE_WIDTH := 240.0
const CROSSFADE_SECONDS := 0.6

@onready var _backdrop: ColorRect = %Backdrop
@onready var _track: ColorRect = %Track
@onready var _logo: TextureRect = %Logo
@onready var _progress_line: Control = %ProgressLine
@onready var _progress_fill: ColorRect = %ProgressFill
@onready var _crossfade: ColorRect = %Crossfade

var _tweens: Array[Tween] = []


func _ready() -> void:
	_apply_scene_colors()
	_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_scene_colors()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func _apply_scene_colors() -> void:
	## Palette comes from the theme tokens; the scene holds no raw colour literals.
	_backdrop.color = _token(&"void_base")
	_track.color = _token(&"metal_dark")
	_progress_fill.color = _token(&"metal_light")


func _run() -> void:
	if ResourceLoader.has_cached(UIPaths.ROUTES[MAIN_MENU_ROUTE]):
		_logo.modulate.a = 1.0
	else:
		await _interval(LOGO_FADE_START)
		await _fade_in_logo()
	_progress_line.visible = true
	var flicker := _flicker_logo()
	await _run_ticks()
	if flicker.is_running():
		await flicker.finished
	await _crossfade_out()
	route_requested.emit(MAIN_MENU_ROUTE, {})


func _interval(seconds: float) -> void:
	var tween := _make_tween()
	tween.tween_interval(seconds)
	await tween.finished


func _fade_in_logo() -> void:
	var tween := _make_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_logo, "modulate:a", 1.0, LOGO_FADE_SECONDS)
	await tween.finished


func _flicker_logo() -> Tween:
	var base := _logo.modulate
	var tween := _make_tween()
	tween.tween_property(_logo, "modulate", _token(&"accent_danger_bright"), FLICKER_SECONDS)
	tween.tween_property(_logo, "modulate", base, FLICKER_SECONDS)
	return tween


func _run_ticks() -> void:
	var tween := _make_tween()
	for index in TICK_FRACTIONS.size():
		if index > 0:
			tween.tween_interval(TICK_GAP_SECONDS)
		tween.tween_property(
			_progress_fill, "size:x", LINE_WIDTH * TICK_FRACTIONS[index], TICK_RISE_SECONDS
		)
	tween.tween_interval(TICK_TAIL_SECONDS)
	await tween.finished


func _crossfade_out() -> void:
	var tween := _make_tween()
	tween.tween_property(_crossfade, "color:a", 1.0, CROSSFADE_SECONDS)
	await tween.finished


func _make_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.BLACK
