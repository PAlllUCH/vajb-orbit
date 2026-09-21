extends Node2D
## S1's **pixel** probe for the speed fantasy (slice 2.5, 2026-09-21): what the two
## screen-space rows actually draw, measured off the rendered framebuffer.
##
## `tests/probe_s2_5_feel.tscn` measures the shipped *state* (which is what a headless run
## can see); this one measures the *pixels*, so it needs a display and is deliberately not
## part of the gate. Everything here is a rendering measurement of the shipped shader and
## the shipped art:
##
##   BLUR     - a one-pixel bright rule on black is smeared: the count of lit pixels in its
##              row is the smear's own width in pixels, measured at the shipped full-speed
##              strength (0.8) and at the shader's own 1.0;
##   ABERR    - the red and blue channels' centres of mass shift the opposite way by the
##              aberration, so the channel split is a measured pixel offset;
##   VIGNETTE - the shipped vignette plate over black: the corner patch's mean luminance at
##              the pulse's own 1.0 and 0.6 alphas, and the centre's, which section 1.8
##              requires to stay clear.
##
## Run (a window is required; the framebuffer this measures is whatever the window gives
## the viewport - the readings below are for a 1920 x 1080 one):
##   ~/.local/bin/godot --path vajb-orbit res://tests/probe_s25_pixels.tscn
##       --fixed-fps 60 --quit-after 240

const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")

const TAG := "[S25P]"
## The rule the blur smears (the world's own line sits at the same x), the two patches
## the vignette is read from (the corner the plate is heaviest at, and the centre), and
## the small square the chromatic split is read off (its channel offset is perpendicular
## to the smear, so the feature it needs has an edge across that axis).
const LINE_X := 200
## The corner patch the vignette is read at, and the small square the chromatic split is
## read off (its channel offset is perpendicular to the smear, so the feature it needs has
## an edge across that axis). The centre patch is taken from the frame at runtime, because
## it is the middle of whatever framebuffer the window gives.
const CORNER := Rect2i(8, 8, 24, 24)
const SPOT := Vector2i(400, 100)
const SPOT_WINDOW := 12

var _fantasy: Variant = null


func _ready() -> void:
	var world := PixelWorld.new()
	world.name = &"PixelWorld"
	add_child(world)
	_fantasy = SpeedFantasyScript.new()
	add_child(_fantasy)
	_fantasy.call(&"set_wheel_zoom", 1.0)
	print(
		"%s HEAD viewport=%s span_px=%.1f aberration_px=%.1f line_x=%d"
		% [
			TAG,
			str(get_viewport().get_visible_rect().size),
			SpeedFantasyScript.BLUR_SPAN_PX,
			SpeedFantasyScript.ABERRATION_PX,
			LINE_X,
		]
	)
	await _case_blur(0.0, "at_rest_below_the_onset")
	await _case_blur(0.9, "ratio_0.9")
	await _case_blur(1.0, "full_speed_strength_0.8")
	await _case_uniform(1.0, "shader_uniform_at_1.0")
	await _case_vignette()
	print("%s done" % TAG)
	## The probe quits itself: a windowed run's frame budget is the display's, not the
	## probe's, so a measurement run must not depend on `--quit-after` to end.
	get_tree().quit()


## One rendered state of the blur, then the row through the rule.
func _case_blur(ratio: float, label: String) -> void:
	_fantasy.call(&"set_ratio", ratio, Vector2.RIGHT)
	var image := await _frame()
	var stats := _row_stats(image)
	var column := _column_split(image)
	print(
		(
			"%s BLUR case=%s ratio=%.2f strength=%.4f visible=%s lit_px=%d span_px=%d "
			+ "peak=%.3f row_split_px=%.3f column_split_px=%.3f"
		)
		% [
			TAG,
			label,
			ratio,
			float(_fantasy.call(&"blur_strength")),
			str((_fantasy.call(&"blur_rect") as ColorRect).visible),
			stats[&"lit"],
			stats[&"span"],
			stats[&"peak"],
			float(stats[&"red"]) - float(stats[&"blue"]),
			column,
		]
	)


## The same measurement with the shader's own uniforms pushed past the shipped band, so
## the pixel scale a strength maps to is a number rather than an inference.
func _case_uniform(strength: float, label: String) -> void:
	var rect := _fantasy.call(&"blur_rect") as ColorRect
	var material := rect.material as ShaderMaterial
	material.set_shader_parameter(&"blur_strength", strength)
	material.set_shader_parameter(&"blur_direction", Vector2.RIGHT)
	material.set_shader_parameter(&"chromatic_aberration", strength)
	rect.visible = true
	var stats := _row_stats(await _frame())
	print(
		"%s BLUR case=%s strength=%.4f lit_px=%d span_px=%d peak=%.3f row_split_px=%.3f"
		% [
			TAG,
			label,
			strength,
			stats[&"lit"],
			stats[&"span"],
			stats[&"peak"],
			float(stats[&"red"]) - float(stats[&"blue"]),
		]
	)


## The hull-critical overlay over black: the plate's own glow at the frame's corner, at
## the pulse's two ends, and the centre it must leave clear (FX_SPEC section 1.8).
func _case_vignette() -> void:
	var rect := _fantasy.call(&"blur_rect") as ColorRect
	var material := rect.material as ShaderMaterial
	material.set_shader_parameter(&"blur_strength", 0.0)
	rect.visible = false
	_fantasy.call(&"set_ratio", 0.0, Vector2.RIGHT)
	for row: Array in [[0.3, "pulse_1.0"], [0.9, "pulse_0.6"]]:
		## Leaving and re-entering the state restarts the pulse's clock, so each reading is
		## taken from a known phase (the engine's own frames add a fraction of a period).
		_fantasy.call(&"set_hull_fraction", 0.30)
		_fantasy.call(&"set_hull_fraction", 0.20)
		var clock := 0.0
		while clock < float(row[0]) - 1e-9:
			_fantasy.call(&"_process", 0.3)
			clock += 0.3
		var image := await _frame()
		print(
			"%s VIGNETTE case=%s alpha=%.4f corner_mean=%.4f centre_mean=%.4f"
			% [
				TAG,
				row[1],
				float(_fantasy.call(&"vignette_alpha")),
				_mean(image, CORNER),
				_mean(image, _centre_rect(image)),
			]
		)
	_fantasy.call(&"set_hull_fraction", 0.30)
	var image := await _frame()
	print(
		"%s VIGNETTE case=above_the_line visible=%s corner_mean=%.4f centre_mean=%.4f"
		% [
			TAG,
			str((_fantasy.call(&"vignette_rect") as TextureRect).visible),
			_mean(image, CORNER),
			_mean(image, _centre_rect(image)),
		]
	)


## --- Rendering helpers ------------------------------------------------------


## Two drawn frames, then the framebuffer: the first is the frame the change lands on, the
## second is the one whose screen texture was captured with it already applied.
func _frame() -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## The row through the rule: how many pixels are lit at all (a threshold well above the
## noise floor), the lit span's width, its peak, and the red and blue channels' centres of
## mass, whose distance apart is the chromatic split.
func _row_stats(image: Image) -> Dictionary:
	var y := image.get_height() / 2
	var lit := 0
	var first := -1
	var last := -1
	var peak := 0.0
	var red_weight := 0.0
	var red_total := 0.0
	var blue_weight := 0.0
	var blue_total := 0.0
	for x in image.get_width():
		var colour := image.get_pixel(x, y)
		var value := maxf(colour.r, maxf(colour.g, colour.b))
		if value > 0.02:
			lit += 1
			if first < 0:
				first = x
			last = x
		peak = maxf(peak, value)
		red_weight += colour.r * float(x)
		red_total += colour.r
		blue_weight += colour.b * float(x)
		blue_total += colour.b
	return {
		&"lit": lit,
		&"span": (last - first + 1) if first >= 0 else 0,
		&"peak": peak,
		&"red": (red_weight / red_total) if red_total > 0.0 else float(LINE_X),
		&"blue": (blue_weight / blue_total) if blue_total > 0.0 else float(LINE_X),
	}


## The middle of the frame the plate must leave clear (FX_SPEC section 1.8), taken from
## the image itself so the patch is the true centre at any window size.
func _centre_rect(image: Image) -> Rect2i:
	return Rect2i(
		image.get_width() / 2 - 12, image.get_height() / 2 - 12, 24, 24
	)


func _mean(image: Image, rect: Rect2i) -> float:
	var total := 0.0
	var count := 0
	for y in range(rect.position.y, mini(rect.position.y + rect.size.y, image.get_height())):
		for x in range(rect.position.x, mini(rect.position.x + rect.size.x, image.get_width())):
			var colour := image.get_pixel(x, y)
			total += (colour.r + colour.g + colour.b) / 3.0
			count += 1
	return total / maxf(float(count), 1.0)


## The chromatic split as a **vertical** offset: the shader offsets the channels along the
## axis perpendicular to the smear, so the small bright square's red profile and blue
## profile sit on opposite sides of where the square was drawn.
func _column_split(image: Image) -> float:
	var red_weight := 0.0
	var red_total := 0.0
	var blue_weight := 0.0
	var blue_total := 0.0
	var left := maxi(SPOT.x - 4, 0)
	var right := mini(SPOT.x + 5, image.get_width())
	var top := maxi(SPOT.y - SPOT_WINDOW, 0)
	var bottom := mini(SPOT.y + SPOT_WINDOW, image.get_height())
	for x in range(left, right):
		for y in range(top, bottom):
			var colour := image.get_pixel(x, y)
			red_weight += colour.r * float(y)
			red_total += colour.r
			blue_weight += colour.b * float(y)
			blue_total += colour.b
	if red_total <= 0.0 or blue_total <= 0.0:
		return 0.0
	return (red_weight / red_total) - (blue_weight / blue_total)


## The world the blur is measured over: black, one bright one-pixel rule crossing it (the
## smear's own reading) and one small square off to the side (the channel split's).
class PixelWorld extends Node2D:
	const RULE_X := 200.0
	const RULE_WIDTH := 1.0
	const SPOT_CENTRE := Vector2(400.5, 100.5)
	const SPOT_SIZE := 3.0

	func _draw() -> void:
		draw_rect(Rect2(-4000.0, -4000.0, 12000.0, 12000.0), Color(0.0, 0.0, 0.0))
		draw_rect(Rect2(RULE_X, -4000.0, RULE_WIDTH, 12000.0), Color.WHITE)
		draw_rect(
			Rect2(SPOT_CENTRE - Vector2.ONE * SPOT_SIZE * 0.5, Vector2.ONE * SPOT_SIZE),
			Color.WHITE
		)
