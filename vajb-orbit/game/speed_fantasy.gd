class_name SpeedFantasy
extends Node
## The screen-space half of the speed fantasy and the hull-critical state: ONE node
## owns the motion blur, the camera's applied zoom, the dust streaks and the
## hull-critical vignette, so the single input `speed_ratio = |v| / v_max` is computed
## once (in `game.gd`, where the speedometer's own ratio already comes from) and pushed
## here every frame through `set_ratio(ratio, velocity)`.
##
## Contract: docs/gameplay/18_engine_spec.md section 3.4 (owner ruling 18 - the onset
## `FX_BLUR_ONSET` 0.70, "all of it is *feedback*, not physics: zero gameplay numbers
## live here"), docs/design/FX_SPEC.md section 5 (the three rows and their values),
## section 6 row 1 and section 1.8 (the hull-critical vignette and its 1.2 s pulse) and
## section 7.3 (the wiring contract). The blur shader itself is
## `res://game/speed_blur.gdshader`; the art is the shipped `assets/fx/` plates, drawn
## through `Fx`'s helpers (never re-keyed, re-cut or tinted in code -
## ASSET_WIRING_HANDOFF section 3). The hull-critical threshold is `Projectile`'s own
## `LOW_HULL_FRACTION`, so the vignette, the smoke plume and the electrical arcs all
## come up on the same 25 % line.
##
## The wheel owns the zoom *target* and this node owns the *applied* value: the wheel
## still clamps and tweens `game.gd`'s own `_camera_zoom`, and the camera is written as
## `wheel_zoom * pullback(ratio)` here, so the two never fight over one number and the
## pull-back is never written back into the wheel.

const FxScript := preload("res://game/fx.gd")
const ProjectileScript := preload("res://game/projectile.gd")

## FX_SPEC section 5 / engine spec section 3.4: the onset every element of the speed
## fantasy is active from, and the two ends of the blur's strength band.
const BLUR_ONSET := 0.70
const BLUR_STRENGTH_MIN := 0.1
const BLUR_STRENGTH_MAX := 0.8

## FX_SPEC section 5 row 2: the camera pull-back's far end (it is 1.0 below the onset).
const PULLBACK_MIN := 0.82

## FX_SPEC section 5 row 3 (the row is marked *proposed*: the owner's to tune). The
## rate, lifetime and length are the spec's; `DUST_ALPHA` is the one value the row
## states only as "low alpha" - it takes engine trail section 1.3's own alpha floor so
## the number comes from the law rather than from this file (reported, one line).
const DUST_RATE := 30.0
const DUST_LIFETIME := 0.5
const DUST_WORLD_LENGTH := 12.0
const DUST_ALPHA := 0.35

## FX_SPEC section 6 row 1 / section 1.8: "alpha pulsing 0.6 -> 1.0 at 1.2 s (sine)".
const VIGNETTE_ALPHA_MIN := 0.6
const VIGNETTE_ALPHA_MAX := 1.0
const VIGNETTE_SECONDS := 1.2

const BLUR_SHADER_PATH := "res://game/speed_blur.gdshader"
## FX_SPEC section 1.8's vignette: the re-cut's frame 1 of its own sequence
## (`fx_hull_critical_vignette_f1.png`), which carries the plate's own alpha - so the
## overlay blends with it instead of adding the plate's near-black field over the frame,
## and section 1.8's "centre must be fully transparent" is the art's own alpha rather
## than something the wiring had to subtract.
const VIGNETTE_SHEET := "res://assets/fx/fx_hull_critical_vignette_f1.png"

## The world draws on canvas layer 0 and the HUD on layer 10
## (`ui/hud/hud.tscn`), so the blur and the vignette sit between them.
const SCREEN_LAYER := 1

const BLUR_NODE: StringName = &"MotionBlur"
const VIGNETTE_NODE: StringName = &"HullCriticalVignette"
const DUST_NODE: StringName = &"DustStreaks"

## The blur shader's two own pixel scales (FX_SPEC states the strength band only);
## both are reported in `.agents/gen/slice2_5_s1_report.md` and are one line to tune.
const BLUR_SPAN_PX := 24.0
const ABERRATION_PX := 2.0

## The FEEDBACK row the dust streak's art comes from: the same table every other FX
## sheet is spawned through (`projectile.gd`), so no second FX helper file exists.
const DUST_ROW: StringName = &"dust"

var _ratio := 0.0
var _velocity := Vector2.ZERO
var _direction := Vector2.RIGHT
var _wheel_zoom := 1.0
var _hull_fraction := 1.0
var _vignette_clock := 0.0
var _camera: Camera2D = null
var _layer: CanvasLayer = null
var _blur: ColorRect = null
var _blur_material: ShaderMaterial = null
var _vignette: TextureRect = null
var _dust: GPUParticles2D = null


func _ready() -> void:
	_build_screen()
	_apply()


## The vignette's own clock. It only runs while the state is on, and entering the state
## restarts it, so the pulse's phase is a property of the state rather than of the run.
func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if _hull_fraction >= ProjectileScript.LOW_HULL_FRACTION:
		return
	_vignette_clock += delta
	_apply_vignette()


## The flight camera. The node is scene-placed (an only child entry in `game.tscn`), so
## the camera arrives from `game.gd` rather than by a path guess: the dust emitter is
## parented to it (FX_SPEC section 5 row 3, section 7.3's "parented emitters").
func bind_camera(camera: Camera2D) -> void:
	_camera = camera
	_build_dust()
	_apply_zoom()


## The wheel's own target, pushed by `game.gd` every frame. It is never written back.
func set_wheel_zoom(value: float) -> void:
	_wheel_zoom = value
	_apply_zoom()


## The one per-frame entry point: FX_SPEC section 5's single input, plus the velocity
## the blur direction and the dust's alignment are the only readers of.
func set_ratio(ratio: float, velocity: Vector2) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_velocity = velocity
	if not velocity.is_zero_approx():
		_direction = velocity.normalized()
	_apply()


## The hull's fraction of its maximum, pushed by `game.gd` from `PlayerState`. Below
## `Projectile.LOW_HULL_FRACTION` the vignette pulses (FX_SPEC section 6 row 1).
func set_hull_fraction(fraction: float) -> void:
	var previous := _hull_fraction
	_hull_fraction = clampf(fraction, 0.0, 1.0)
	var was_active := previous < ProjectileScript.LOW_HULL_FRACTION
	var now_active := _hull_fraction < ProjectileScript.LOW_HULL_FRACTION
	if now_active and not was_active:
		_vignette_clock = 0.0
	_apply_vignette()


## --- The read-backs every probe and test asserts against ------------------


func ratio() -> float:
	return _ratio


func wheel_zoom() -> float:
	return _wheel_zoom


func hull_fraction() -> float:
	return _hull_fraction


func velocity() -> Vector2:
	return _velocity


func blur_direction() -> Vector2:
	return _direction


func blur_strength() -> float:
	return blur_for(_ratio)


func chromatic_aberration() -> float:
	return blur_for(_ratio)


func pullback() -> float:
	return pullback_for(_ratio)


func applied_zoom() -> float:
	return _wheel_zoom * pullback()


func vignette_active() -> bool:
	return _hull_fraction < ProjectileScript.LOW_HULL_FRACTION


func vignette_alpha() -> float:
	return vignette_alpha_for(_vignette_clock)


func blur_rect() -> ColorRect:
	return _blur


func vignette_rect() -> TextureRect:
	return _vignette


func dust() -> GPUParticles2D:
	return _dust


func layer() -> CanvasLayer:
	return _layer


## --- The spec's own arithmetic, pure so a test needs no tree --------------


## FX_SPEC section 5: "`blur_strength` clamps 0.1 at cruise -> 0.8 during a dash" and
## "strength is 0 below the 0.70 onset".
static func blur_for(ratio: float) -> float:
	if ratio <= BLUR_ONSET:
		return 0.0
	return lerpf(BLUR_STRENGTH_MIN, BLUR_STRENGTH_MAX, ramp_for(ratio))


## FX_SPEC section 5: `lerp(1.0, 0.82, (speed_ratio - 0.7) / 0.3)`, 1.0 below the onset.
static func pullback_for(ratio: float) -> float:
	if ratio <= BLUR_ONSET:
		return 1.0
	return lerpf(1.0, PULLBACK_MIN, ramp_for(ratio))


## FX_SPEC section 6 row 1 / section 1.8: alpha 0.6 -> 1.0 at 1.2 s, sine.
static func vignette_alpha_for(seconds: float) -> float:
	var phase := sin(TAU * seconds / VIGNETTE_SECONDS)
	return lerpf(VIGNETTE_ALPHA_MIN, VIGNETTE_ALPHA_MAX, 0.5 + 0.5 * phase)


## The two rows' shared ramp: 0 at the onset, 1 at full speed.
static func ramp_for(ratio: float) -> float:
	var span := 1.0 - BLUR_ONSET
	if span <= 0.0:
		return 1.0 if ratio >= BLUR_ONSET else 0.0
	return clampf((ratio - BLUR_ONSET) / span, 0.0, 1.0)


## The dust row's own arithmetic (FX_SPEC section 5 row 3): the particle count is the
## rate over the lifetime, and the emitter is on from the section's own 0.70 onset.
static func dust_read(ratio: float) -> Dictionary:
	var on := ratio >= BLUR_ONSET
	return {
		&"on": on,
		&"rate": DUST_RATE if on else 0.0,
		&"count": roundi(DUST_RATE * DUST_LIFETIME) if on else 0,
		&"lifetime": DUST_LIFETIME,
		&"length": DUST_WORLD_LENGTH,
		&"alpha": DUST_ALPHA if on else 0.0,
	}


## --- The screen-space stack ---------------------------------------------


func _build_screen() -> void:
	if _layer != null:
		return
	_layer = CanvasLayer.new()
	_layer.name = &"SpeedFantasyLayer"
	_layer.layer = SCREEN_LAYER
	add_child(_layer)
	_blur = ColorRect.new()
	_blur.name = BLUR_NODE
	_blur.color = Color.WHITE
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur_material = ShaderMaterial.new()
	if ResourceLoader.exists(BLUR_SHADER_PATH):
		_blur_material.shader = load(BLUR_SHADER_PATH) as Shader
	_blur_material.set_shader_parameter(&"blur_span_px", BLUR_SPAN_PX)
	_blur_material.set_shader_parameter(&"aberration_px", ABERRATION_PX)
	_blur.material = _blur_material
	_blur.visible = false
	_layer.add_child(_blur)
	if ResourceLoader.exists(VIGNETTE_SHEET):
		_vignette = TextureRect.new()
		_vignette.name = VIGNETTE_NODE
		_vignette.texture = load(VIGNETTE_SHEET) as Texture2D
		_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_vignette.stretch_mode = TextureRect.STRETCH_SCALE
		_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		## The re-cut frame carries its own alpha, so the overlay blends with it (the
		## owner's 2026-09-21 ruling: every effect is drawn with the sheet's own alpha),
		## and the "alpha pulse" of section 1.8 is this node's own modulate.
		_vignette.material = FxScript.alpha_material()
		_vignette.visible = false
		_layer.add_child(_vignette)


## The dust emitter, on the camera (FX_SPEC section 5 row 3 / section 7.3). It is a
## child of the camera and emits in world space (`local_coords = false`), so the
## streaks it leaves behind the moving camera are what reads as speed; the emitter's own
## rotation is the velocity's bearing, which is what aims the streaks along the travel.
func _build_dust() -> void:
	if _camera == null or _dust != null:
		return
	if not is_instance_valid(_camera):
		return
	var row := ProjectileScript.feedback_row(DUST_ROW)
	if row.is_empty():
		return
	var texture := ProjectileScript.feedback_texture(DUST_ROW)
	if texture == null:
		return
	var base := FxScript.scale_for(
		row.get(&"source", texture.get_size()) as Vector2,
		float(row.get(&"world", DUST_WORLD_LENGTH))
	)
	var emitter := GPUParticles2D.new()
	emitter.name = DUST_NODE
	emitter.texture = texture
	## FX_SPEC section 5 row 3: "camera-space, never additively blown" - and the re-cut
	## frame now carries its own alpha, so the row's MIX draw is the blend it always
	## asked for rather than the plate's own surround at `DUST_ALPHA`.
	emitter.material = FxScript.alpha_material()
	emitter.process_material = _dust_material(base)
	emitter.amount = roundi(DUST_RATE * DUST_LIFETIME)
	emitter.lifetime = DUST_LIFETIME
	emitter.preprocess = DUST_LIFETIME
	emitter.local_coords = false
	emitter.emitting = false
	emitter.visible = false
	_camera.add_child(emitter)
	_dust = emitter


func _dust_material(base: float) -> ParticleProcessMaterial:
	var dust := ParticleProcessMaterial.new()
	dust.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(600.0, 340.0, 0.0)
	dust.direction = Vector3(1.0, 0.0, 0.0)
	dust.spread = 0.0
	dust.initial_velocity_min = 0.0
	dust.initial_velocity_max = 0.0
	dust.gravity = Vector3.ZERO
	dust.scale_min = base
	dust.scale_max = base
	dust.color = Color(1.0, 1.0, 1.0, DUST_ALPHA)
	return dust


## One frame of the whole stack, from the single input.
func _apply() -> void:
	_apply_blur()
	_apply_dust()
	_apply_zoom()


func _apply_blur() -> void:
	if _blur == null or _blur_material == null:
		return
	var strength := blur_strength()
	_blur_material.set_shader_parameter(&"blur_strength", strength)
	_blur_material.set_shader_parameter(&"blur_direction", _direction)
	_blur_material.set_shader_parameter(&"chromatic_aberration", chromatic_aberration())
	## Zero below the onset: the full-screen pass is not drawn at all.
	_blur.visible = strength > 0.0


func _apply_dust() -> void:
	if _dust == null or not is_instance_valid(_dust):
		return
	var read := dust_read(_ratio)
	var on := bool(read[&"on"])
	_dust.emitting = on
	_dust.visible = on
	if on:
		_dust.rotation = _direction.angle()
	_apply_dust_extents()


## The emission box covers the visible frame at the applied zoom, so the streaks read
## across the whole screen rather than only its middle. The size is derived from the
## viewport and the zoom, never invented.
func _apply_dust_extents() -> void:
	if _dust == null or not is_instance_valid(_dust):
		return
	var material := _dust.process_material as ParticleProcessMaterial
	if material == null or not is_inside_tree():
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var zoom := maxf(applied_zoom(), 0.01)
	var view := viewport.get_visible_rect().size / zoom
	material.emission_box_extents = Vector3(view.x * 0.5, view.y * 0.5, 0.0)


## The applied zoom, and nothing else: `wheel * pullback(ratio)` (FX_SPEC section 5 row
## 2 - "multiplied by lerp(1.0, 0.82, (speed_ratio - 0.7) / 0.3)", stacking with the
## wheel). The wheel's own target is never written here.
func _apply_zoom() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	var applied := applied_zoom()
	_camera.zoom = Vector2(applied, applied)
	_apply_dust_extents()


func _apply_vignette() -> void:
	if _vignette == null or not is_instance_valid(_vignette):
		return
	var active := vignette_active()
	_vignette.visible = active
	_vignette.modulate = Color(1.0, 1.0, 1.0, vignette_alpha() if active else 0.0)
