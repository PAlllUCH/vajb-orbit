extends Screen
## Main menu v2: the verb stack of three 350x70 riveted plates over the scrimmed vista,
## the emblem header, the footer read-out and the version stamp.
## Spec: docs/design/MAIN_MENU_V2.md. Structure: IMPLEMENTATION_PLAN sections 3.4, 3.11,
## 3.12, 4.3 and 9.2. The screen declares intent (route_requested / overlay_requested)
## and never routes itself, and every colour it needs is read from the theme.

const ROUTE_LOADING: StringName = &"loading"
const ROUTE_SETTINGS: StringName = &"settings"
const ROUTE_QUIT_CONFIRM: StringName = &"quit_confirm"
const ROUTE_STATION: StringName = &"station"
const PARAM_DESTINATION: StringName = &"destination"
const DESTINATION_GAME: StringName = &"game"

const VERB_PLAY: int = 0
const VERB_OPTIONS: int = 1
const VERB_EXIT: int = 2

const MUSIC_TRACK: StringName = &"mus_menu_theme_01"
const MUSIC_FADE_SECONDS: float = 1.5
const MUSIC_STOP_SECONDS: float = 0.6

const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_VOID_BASE: StringName = &"void_base"
const TOKEN_ACCENT: StringName = &"accent_danger_bright"
const TOKEN_TEXT_PRIMARY: StringName = &"text_primary"

## The footer read-out carries the flavour face (IMPLEMENTATION_PLAN section 9.8 item 2).
## The scene declares HudReadout, which the display face now owns, so the swap to the
## flavour variation lands here rather than in a per-node font override.
const READOUT_VARIATION: StringName = &"FlavourText"

## A Theme cannot carry a gradient texture, so the two legibility scrims are built
## here from the void_base token (MAIN_MENU_V2 section 6, item 2).
const SCRIM_STEPS: int = 256
const LEFT_SCRIM_ALPHA: float = 0.62
const LEFT_SCRIM_SPAN: float = 0.68
const BOTTOM_SCRIM_ALPHA: float = 0.70
const BOTTOM_SCRIM_START: float = 0.70

## STRETCH_KEEP_ASPECT_COVERED crops the vista differently at every aspect, so the
## ember is re-anchored on resize instead of trusting the 16:9 scene anchor.
const EMBER_ANCHOR: Vector2 = Vector2(0.791, 0.618)

## Every theme token is a dimmer, so the dark insignia is lifted by a white modulate
## multiplier rather than by a token (MAIN_MENU_V2 section 15.3). Focus flares it
## brighter instead of drawing the retired focus ring (IMPLEMENTATION_PLAN 9.8 item 1).
const EMBLEM_BRIGHTEN: float = 2.0
const EMBLEM_PULSE_PEAK: float = 2.35
const EMBLEM_PULSE_IN: float = 0.10
const EMBLEM_PULSE_OUT: float = 0.30

const DRIFT_DISTANCE: float = 96.0
const DRIFT_SECONDS: float = 20.0
const EMBER_ALPHA_MIN: float = 0.25
const EMBER_ALPHA_MAX: float = 0.45
const EMBER_HALF_PERIOD: float = 4.0

const LOGO_FADE: float = 0.40
const LOGO_POP: float = 0.55
const LOGO_SCALE: float = 1.03
const HEADER_DELAY: float = 0.10
const HEADER_FADE: float = 0.30
const HEADER_POP: float = 0.45
const HEADER_SCALE: float = 0.99
const VERB_DELAY: float = 0.30
const VERB_STAGGER: float = 0.10
const VERB_FADE: float = 0.26
const VERB_POP: float = 0.36
const VERB_SCALE: float = 0.97
const TICK_IN: float = 0.14
const TICK_OUT: float = 0.10

const READOUT: Array[String] = [
	"ENTER THE STATION HUB",
	"OPEN SYSTEM AND INTERFACE SETTINGS",
	"END THE SESSION",
]

@onready var _backdrop: TextureRect = %Backdrop
@onready var _ember: TextureRect = %EmberPulse
@onready var _left_scrim: TextureRect = %LeftScrim
@onready var _bottom_scrim: TextureRect = %BottomScrim
@onready var _logo: TextureRect = %Logo
@onready var _header: HBoxContainer = %CommandHeader
@onready var _badge: TextureRect = %InsigniaBadge
@onready var _stamp: Label = %VersionLabel
@onready var _readout: Label = %FocusReadout
@onready var _play_button: Control = %PlayButton
@onready var _options_button: Control = %OptionsButton
@onready var _exit_button: Control = %ExitButton
@onready var _play_tick: ColorRect = %PlayTick
@onready var _options_tick: ColorRect = %OptionsTick
@onready var _exit_tick: ColorRect = %ExitTick

var _verbs: Array[Control] = []
var _ticks: Array[ColorRect] = []
var _ambient: Array[Tween] = []
var _tick_tweens: Array[Tween] = []
var _entrance: Tween
var _emblem_pulse: Tween
var _active_verb: int = VERB_PLAY
var _opener_verb: int = VERB_PLAY


func _ready() -> void:
	_verbs.assign([_play_button, _options_button, _exit_button])
	_ticks.assign([_play_tick, _options_tick, _exit_tick])
	_tick_tweens.resize(_ticks.size())
	for mark in _ticks:
		mark.modulate.a = 0.0
	_apply_token_colours()
	_readout.theme_type_variation = READOUT_VARIATION
	_readout.text = READOUT[_active_verb]
	_connect_verbs()
	_connect_router()
	_prime_entrance()
	_backdrop.resized.connect(_on_backdrop_resized)
	_reanchor_ember()
	_start_ambient()
	_focus_verb(_active_verb)
	_start_entrance.call_deferred()
	AudioManager.play_music(MUSIC_TRACK, MUSIC_FADE_SECONDS)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_token_colours()


func _exit_tree() -> void:
	for tween in _ambient:
		if tween != null and tween.is_valid():
			tween.kill()
	_ambient.clear()
	for tween in _tick_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_stop_emblem_pulse()
	if _entrance != null and _entrance.is_valid():
		_entrance.kill()
	AudioManager.stop_music(MUSIC_STOP_SECONDS)


func on_route(_params: Dictionary) -> void:
	_focus_verb(VERB_PLAY)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	# An overlay on top owns its own cancel handling.
	if Router.overlay_depth() > 0:
		return
	get_viewport().set_input_as_handled()
	_open_overlay(ROUTE_QUIT_CONFIRM, _active_verb)


func _apply_token_colours() -> void:
	_style_scrim(_left_scrim, true)
	_style_scrim(_bottom_scrim, false)
	_stamp.add_theme_color_override(&"font_color", _token(TOKEN_TEXT_PRIMARY))
	_stop_emblem_pulse()
	_badge.modulate = _emblem_color(EMBLEM_BRIGHTEN)
	for mark in _ticks:
		mark.color = _token(TOKEN_ACCENT)


func _connect_verbs() -> void:
	for index in _verbs.size():
		var verb: Control = _verbs[index]
		verb.connect(&"hovered", _on_verb_hovered.bind(index))
		verb.connect(&"pressed", _on_verb_pressed.bind(index))
		var plate := _plate(index)
		if plate != null:
			plate.focus_entered.connect(_on_verb_focused.bind(index))


func _connect_router() -> void:
	if not Router.overlay_popped.is_connected(_on_overlay_popped):
		Router.overlay_popped.connect(_on_overlay_popped)


func _on_verb_hovered(index: int) -> void:
	if index == _active_verb:
		return
	# Hovering grabs focus, so the cue is emitted once here and the focus handler
	# stays quiet for the same verb.
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	_set_active_verb(index)
	_focus_verb(index)


func _on_verb_focused(index: int) -> void:
	if index != _active_verb:
		AudioManager.play_ui(AudioManager.UiCue.HOVER)
	_set_active_verb(index)


func _on_verb_pressed(index: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	match index:
		VERB_PLAY:
			route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: _play_destination()})
		VERB_OPTIONS:
			_open_overlay(ROUTE_SETTINGS, index)
		VERB_EXIT:
			_open_overlay(ROUTE_QUIT_CONFIRM, index)


func _on_overlay_popped(_route: StringName) -> void:
	_focus_verb(_opener_verb)


func _open_overlay(route: StringName, opener: int) -> void:
	_opener_verb = opener
	overlay_requested.emit(route, {})


func _play_destination() -> StringName:
	## The station hub lands after this screen; until its route exists PLAY must
	## still leave the menu, so the destination falls back to the game.
	return ROUTE_STATION if UIPaths.route_exists(ROUTE_STATION) else DESTINATION_GAME


func _set_active_verb(index: int) -> void:
	_active_verb = index
	_readout.text = READOUT[index]
	_set_tick(index)
	_pulse_emblem()


func _emblem_color(level: float) -> Color:
	return Color(level, level, level, 1.0)


func _pulse_emblem() -> void:
	## The emblem carries the focus cue the retired ring used to (IMPLEMENTATION_PLAN
	## section 9.8 item 1): it flares from the resting brighten and settles back to it.
	_stop_emblem_pulse()
	_emblem_pulse = create_tween()
	_emblem_pulse.tween_property(_badge, "modulate", _emblem_color(EMBLEM_PULSE_PEAK), EMBLEM_PULSE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_emblem_pulse.tween_property(_badge, "modulate", _emblem_color(EMBLEM_BRIGHTEN), EMBLEM_PULSE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_emblem_pulse() -> void:
	if _emblem_pulse != null and _emblem_pulse.is_valid():
		_emblem_pulse.kill()
	_emblem_pulse = null


func _focus_verb(index: int) -> void:
	var plate := _plate(index)
	if plate != null:
		plate.grab_focus()


func _plate(index: int) -> Button:
	if index < 0 or index >= _verbs.size():
		return null
	return _verbs[index].get_node_or_null(^"Button") as Button


func _set_tick(active: int) -> void:
	for index in _ticks.size():
		var previous: Tween = _tick_tweens[index]
		if previous != null and previous.is_valid():
			previous.kill()
		var target: float = 1.0 if index == active else 0.0
		var duration: float = TICK_IN if index == active else TICK_OUT
		var tween := create_tween()
		tween.tween_property(_ticks[index], "modulate:a", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tick_tweens[index] = tween


func _prime_entrance() -> void:
	_logo.modulate.a = 0.0
	_logo.scale = Vector2(LOGO_SCALE, LOGO_SCALE)
	_header.modulate.a = 0.0
	_header.scale = Vector2(HEADER_SCALE, HEADER_SCALE)
	for verb in _verbs:
		verb.modulate.a = 0.0
		verb.scale = Vector2(VERB_SCALE, VERB_SCALE)


func _start_entrance() -> void:
	## Containers own position and size, so the entrance only touches modulate and
	## scale, and each scaled node needs a pivot once layout is valid.
	_logo.pivot_offset = _logo.size * 0.5
	_header.pivot_offset = _header.size * 0.5
	for verb in _verbs:
		verb.pivot_offset = verb.size * 0.5
	_entrance = create_tween().set_parallel(true)
	_entrance.tween_property(_logo, "modulate:a", 1.0, LOGO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(_logo, "scale", Vector2.ONE, LOGO_POP).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(_header, "modulate:a", 1.0, HEADER_FADE).set_delay(HEADER_DELAY).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(_header, "scale", Vector2.ONE, HEADER_POP).set_delay(HEADER_DELAY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in _verbs.size():
		var delay: float = VERB_DELAY + VERB_STAGGER * float(index)
		_entrance.tween_property(_verbs[index], "modulate:a", 1.0, VERB_FADE).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_entrance.tween_property(_verbs[index], "scale", Vector2.ONE, VERB_POP).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _start_ambient() -> void:
	var drift := create_tween().set_loops()
	drift.tween_property(_backdrop, "position", Vector2(-DRIFT_DISTANCE, -DRIFT_DISTANCE), DRIFT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(_backdrop, "position", Vector2.ZERO, DRIFT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient.append(drift)
	_ember.modulate.a = EMBER_ALPHA_MIN
	var pulse := create_tween().set_loops()
	pulse.tween_property(_ember, "modulate:a", EMBER_ALPHA_MAX, EMBER_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_ember, "modulate:a", EMBER_ALPHA_MIN, EMBER_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient.append(pulse)


func _on_backdrop_resized() -> void:
	_reanchor_ember.call_deferred()


func _reanchor_ember() -> void:
	var texture: Texture2D = _backdrop.texture
	if texture == null or _backdrop.size.x <= 0.0 or _backdrop.size.y <= 0.0:
		return
	var native := Vector2(float(texture.get_width()), float(texture.get_height()))
	var cover: float = maxf(_backdrop.size.x / native.x, _backdrop.size.y / native.y)
	var drawn := native * cover
	var origin := (_backdrop.size - drawn) * 0.5
	_ember.position = origin + drawn * EMBER_ANCHOR - _ember.size * 0.5


func _style_scrim(target: TextureRect, horizontal: bool) -> void:
	var gradient := Gradient.new()
	var clear := _scrim_color(0.0)
	if horizontal:
		gradient.offsets = PackedFloat32Array([0.0, LEFT_SCRIM_SPAN, 1.0])
		gradient.colors = PackedColorArray([_scrim_color(LEFT_SCRIM_ALPHA), clear, clear])
	else:
		gradient.offsets = PackedFloat32Array([0.0, BOTTOM_SCRIM_START, 1.0])
		gradient.colors = PackedColorArray([clear, clear, _scrim_color(BOTTOM_SCRIM_ALPHA)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = SCRIM_STEPS if horizontal else 1
	texture.height = 1 if horizontal else SCRIM_STEPS
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(1.0, 0.0) if horizontal else Vector2(0.0, 1.0)
	target.texture = texture


func _scrim_color(alpha: float) -> Color:
	var token := _token(TOKEN_VOID_BASE)
	return Color(token.r, token.g, token.b, alpha)


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.BLACK
