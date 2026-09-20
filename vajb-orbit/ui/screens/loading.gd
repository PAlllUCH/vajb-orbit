extends Screen
## Loading bridge: the only route in and out of gameplay, so every destination the
## caller asks for is forwarded unchanged (docs/design/MENU_FLOW.md section 1).
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 4.2, docs/design/MAIN_MENU_SPEC.md section 2.
## The sequence starts in _ready() so the scene also plays standalone (F6); the Router's
## on_route() then supplies the real destination well before the fade-out can fire.
## Phase D (IMPLEMENTATION_PLAN section 9.2) adds the station leg:
## PLAY -> loading{destination: &"station"} -> station -> LAUNCH -> loading{destination: &"game"} -> game.

const Paths := preload("res://ui/paths.gd")

const DEFAULT_DESTINATION: StringName = &"game"
const DEFAULT_LABEL := "ENTERING SPACE"
const SECTOR_LABEL := "ENTERING SECTOR — %s"
const TOKENS_TYPE: StringName = &"Tokens"

const DESTINATION_KEY := "destination"
const SECTOR_KEY := "sector"
const MINIMUM_DISPLAY_SECONDS := 1.2
const FADE_SECONDS := 0.4
const FULL_PERCENT := 100.0

@onready var _backdrop: ColorRect = $Backdrop
@onready var _destination_label: Label = %DestinationLabel
@onready var _progress: ProgressBar = %Progress
@onready var _fade: ColorRect = %Fade

var _destination: StringName = DEFAULT_DESTINATION
var _params: Dictionary = {}
var _tweens: Array[Tween] = []


func _ready() -> void:
	_apply_scene_colors()
	_refresh_label()
	_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_scene_colors()


func _apply_scene_colors() -> void:
	## Palette comes from the theme tokens; the scene holds no raw colour literals.
	_backdrop.color = _token(&"void_base")


func on_route(params: Dictionary) -> void:
	_destination = _resolve_destination(
		StringName(params.get(DESTINATION_KEY, DEFAULT_DESTINATION))
	)
	_params = params
	_refresh_label()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func _refresh_label() -> void:
	var sector := String(_params.get(SECTOR_KEY, ""))
	if sector.is_empty():
		_destination_label.text = DEFAULT_LABEL
		return
	_destination_label.text = SECTOR_LABEL % sector


func _resolve_destination(requested: StringName) -> StringName:
	## Every destination the caller asks for is forwarded unchanged, and &"station" is
	## forwarded like any other route (ui/paths.gd ROUTES). The fallback exists so a
	## destination with no route cannot leave the bridge stalled on its own fade.
	if Paths.route_exists(requested):
		return requested
	return DEFAULT_DESTINATION


func _run() -> void:
	await _run_progress()
	await _run_fade()
	route_requested.emit(_destination, _params)


func _run_progress() -> void:
	_progress.value = 0.0
	var tween := _make_tween()
	tween.tween_property(_progress, "value", FULL_PERCENT, MINIMUM_DISPLAY_SECONDS)
	await tween.finished


func _run_fade() -> void:
	var tween := _make_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	await tween.finished


func _make_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.BLACK
