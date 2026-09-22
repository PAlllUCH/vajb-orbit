@tool
extends McpTestSuite
## Suite s2_6_blur: the player hull's exclusion from the motion blur (S2.6-R5, AC7).
##
## The owner's request, verbatim: "when motion blur happens the ship shouldn't be blurred,
## everything else can be." The pinned route is shader-side - `speed_fantasy.gd` (which owns
## the camera and can read the `player_ship` group) pushes the hull's own screen disc, and
## `speed_blur.gdshader` skips the smear **and its chromatic split** inside it. A canvas or
## layer split is forbidden: the hull-critical vignette is a sibling on the same
## `SCREEN_LAYER`, so lifting the hull onto a layer of its own would also lift it above that
## tint (CONTRACTS section 14, F4).
##
## Contract read: docs/design/FX_SPEC.md section 5 and its 2026-09-22 amendment (the rule, the
## acceptance and the reversal), section 1.8 (the vignette the exclusion must not disturb);
## docs/CONTRACTS.md section 14 (the pin, including F4 and F16's radius object for a hull:
## `CollisionShape2D.radius`, measured 30 u on the shipped `player_ship.tscn`); docs/CONTRACTS.md
## section 5 row 1 of FX_SPEC section 5 (the strength band, `blur_span_px` and `aberration_px`).
##
## **What this suite measures, and what it cannot.** The gate's runner calls a test method and
## steps no frame at all, and `RenderingServer.force_draw()` re-renders the viewports without
## rebuilding canvas item draw commands (measured on this host: a SubViewport's full-strength
## blur leaves every patch at the clear colour), so an in-gate framebuffer read is impossible.
## The fixture is `game.tscn` for the shipped wiring (the blur's rect, the one layer, the
## camera) plus the shipped `player_ship.tscn` when the tree launched no hull of its own, so
## nothing here depends on the launch or the owner's account. The suite therefore pins the
## three things a framebuffer read would otherwise carry:
##   1. the shader's own parsed structure - the exclusion guard wraps the smear *and* the two
##      channel writes, with one guarded path and no second unguarded one;
##   2. the wiring - the pushed disc is the hull's own radius at the hull's own screen
##      position, tracking the ship and the camera's zoom, and off when no hull resolves;
##   3. the acceptance's own comparison, evaluated in-process over a synthetic framebuffer with
##      the numbers the shipped material actually carries (see `_fragment_pixel`).
## The on-GPU pixel numbers - hull-region pixels identical to the unblurred render, background
## measurably different, and the same region measurably different with the flag off - are in
## `.agents/gen/slices/S2.6-truth-and-feel/S2.6-R5_report.md`.

const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")

const GAME_SCENE := "res://game/game.tscn"
const PLAYER_SHIP_SCENE := "res://game/player_ship.tscn"
const BLUR_SHADER := "res://game/speed_blur.gdshader"
const SPEED_FANTASY_NODE: StringName = &"SpeedFantasy"
const CAMERA_NODE: StringName = &"Camera"

## F16's radius object for a hull, as the shipped scene carries it (`HullBody/Shape`'s
## `CircleShape2D`): 30 u. Measured against the art it must cover - the shipped
## `ship_vanguard_side.png` is 960 x 521 with an 888 x 449 px ink box, so at the scene's own
## 0.0663 hull scale the drawn hull is 58.87 u long (a 29.44 u half-length) and 29.77 u tall.
const HULL_RADIUS_UNITS := 30.0
## FX_SPEC section 5 row 1: full speed is the top of the strength band.
const FULL_RATIO := 1.0
## The gate's own float tolerance: the arithmetic is transcendental in places (the ramps).
const TOL := 1e-4
## The shipped shader's tap count (`const int TAPS`), which the in-process evaluation below
## mirrors: the structural test reads the shader's own declaration, so the two cannot drift.
const TAPS := 17
## The sampling pattern's own figures - the suite's, not the shader's: the hull disc is read
## across its inner 85 % (leaving the boundary ring, where a hard disc test is a border case,
## out of the comparison) and the background patch is a window around a bright rule placed
## three radii off the hull's centre.
const HULL_SAMPLE_FRACTION := 0.85
const HULL_SAMPLE_STEP := 2
const BACKGROUND_RULE_RADII := 3.0
const BACKGROUND_PATCH_RADII := 1.2

var _scene: Node2D = null
var _fantasy: Node = null
var _camera: Camera2D = null
var _ship: Node2D = null
var _measured := ""


func suite_name() -> String:
	return "s2_6_blur"


func suite_setup(_ctx: Dictionary) -> void:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_host().add_child(_scene)
	_fantasy = _scene.get_node_or_null(NodePath(SPEED_FANTASY_NODE))
	_camera = _scene.get_node_or_null(NodePath(CAMERA_NODE)) as Camera2D
	if _fantasy == null or _camera == null:
		fail_setup("game.tscn carries no speed fantasy or no camera")
		return
	_ship = _host().get_tree().get_first_node_in_group(SpeedFantasyScript.PLAYER_GROUP) as Node2D
	if _ship == null:
		## The fixture does not depend on the launch: a tree that spawned no hull gets the
		## shipped scene, whose collider is the region's radius object either way, and the
		## tracking assertion below is what proves the wiring resolved *this* hull.
		var packed_ship := load(PLAYER_SHIP_SCENE) as PackedScene
		if packed_ship == null:
			fail_setup("player_ship.tscn did not load")
			return
		_ship = packed_ship.instantiate() as Node2D
		if _ship == null:
			fail_setup("player_ship.tscn did not instantiate")
			return
		_scene.add_child(_ship)
	if not _ship.is_in_group(SpeedFantasyScript.PLAYER_GROUP):
		fail_setup("the fixture's hull is not in the `player_ship` group")
		return


func suite_teardown() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_fantasy = null
	_camera = null
	_ship = null
	_measured = ""


func teardown() -> void:
	## The fixture is shared: put the flag back the way the wiring left it, so a test that
	## pokes the uniforms cannot leak into the next one.
	_set_flag(SpeedFantasyScript.SPEED_BLUR_EXCLUDE_PLAYER)


## --- The shader's own structure, and the layer stack it must not disturb (F4) ---


func test_the_exclusion_guards_the_smear_and_the_split_and_never_splits_the_layer() -> void:
	assert_true(
		SpeedFantasyScript.SPEED_BLUR_EXCLUDE_PLAYER,
		"the pin's flag is on (its reversal is the flag itself)"
	)
	## 1. The shader parses, and it parses *with* the three uniforms. A shader Godot cannot
	## compile does not lose only its pixels: it loses its uniform list, so this is the gate's
	## proof that the shipped file compiles as written (measured on a broken build).
	var shader := load(BLUR_SHADER) as Shader
	assert_true(shader != null, "the blur shader loads")
	var uniforms := {}
	for entry: Dictionary in shader.get_shader_uniform_list(false):
		uniforms[String(entry.get(&"name", ""))] = int(entry.get(&"type", -1))
	for name: String in ["exclude_player", "player_screen_uv", "player_screen_radius"]:
		assert_true(uniforms.has(name), "the shader declares `%s`" % name)
	assert_eq(uniforms.get("exclude_player", -1), TYPE_BOOL, "the flag is a bool uniform")
	assert_eq(uniforms.get("player_screen_uv", -1), TYPE_VECTOR2, "the centre is a vec2")
	assert_eq(
		uniforms.get("player_screen_radius", -1),
		TYPE_VECTOR2,
		"and the radius travels per axis, so the disc is a circle at any aspect"
	)
	## 2. Both effects - not only the smear - are behind the region guard.
	var body := _fragment_body(String(shader.code))
	var guard := body.find("&& !on_hull")
	assert_true(guard > 0, "the fragment's only blur branch is guarded by the region test")
	assert_true(
		body.find("exclude_player") < guard and body.find("player_screen_radius") < guard,
		"and the guard reads the flag and the radius the wiring pushes"
	)
	var open := body.find("{", guard)
	var close := _block_end(body, open)
	assert_true(open > guard and close > open, "the guarded block is a real block")
	var smear := body.find("smear(")
	assert_true(smear > open and smear < close, "the smear is inside the guard")
	var red := body.find("tint.r = ")
	var blue := body.find("tint.b = ")
	assert_true(
		red > open and red < close and blue > open and blue < close,
		"and so are both halves of the chromatic split: the hull loses neither blur nor split"
	)
	assert_true(
		body.find("smear(", smear + 1) == -1,
		"the smear has no second, unguarded call site"
	)
	assert_true(
		body.find("COLOR = vec4(tint, 1.0)") > close,
		"the fragment still writes the pass-through tap it read before the guard"
	)
	assert_true(
		String(shader.code).contains("const int TAPS = %d;" % TAPS),
		"and the tap count this suite evaluates against is the shader's own"
	)
	## 3. F4: the exclusion must not be bought with a canvas or layer split. The blur and the
	## hull-critical vignette stay siblings on one layer, vignette above, so a damaged hull
	## keeps its tint while its pixels skip the blur.
	var layer := _fantasy.call(&"layer") as CanvasLayer
	var blur := _fantasy.call(&"blur_rect") as ColorRect
	var vignette := _fantasy.call(&"vignette_rect") as TextureRect
	assert_true(layer != null and blur != null and vignette != null, "the stack is built")
	assert_eq(
		layer.layer,
		SpeedFantasyScript.SCREEN_LAYER,
		"the stack draws on the pinned screen layer"
	)
	assert_true(
		blur.get_parent() == layer and vignette.get_parent() == layer,
		"the blur and the vignette share one CanvasLayer: no canvas/layer split"
	)
	assert_true(
		vignette.get_index() > blur.get_index(),
		"and the vignette still draws above the blur, so the hull keeps its hull-critical tint"
	)
	var layers := 0
	for child: Node in _fantasy.get_children():
		if child is CanvasLayer:
			layers += 1
	assert_eq(layers, 1, "the speed fantasy owns exactly one CanvasLayer")


## --- The wiring's own region, and AC7's comparison ---------------------------


func test_at_full_blur_strength_the_hull_region_pixels_match_the_unblurred_render() -> void:
	var material := _material()
	assert_true(material != null, "the blur carries the shipped shader material")
	_full_strength()
	## The region's provenance: the hull's own collider radius (F16), at the hull's own
	## position, scaled by the camera's applied zoom.
	var push := _pushed()
	assert_true(bool(push[&"exclude"]), "at full strength the flag is pushed on")
	assert_true(
		_near(float(_fantasy.call(&"hull_radius_units")), HULL_RADIUS_UNITS),
		"the region's radius object is the hull's own `CollisionShape2D` radius (30 u)"
	)
	var size := _size()
	var radius_uv := push[&"radius"] as Vector2
	var zoom := float(_fantasy.call(&"applied_zoom"))
	assert_true(
		_near(radius_uv.x * size.x, HULL_RADIUS_UNITS * zoom, 1e-3)
		and _near(radius_uv.y * size.y, HULL_RADIUS_UNITS * zoom, 1e-3),
		"which reaches the shader as the same radius on both axes, scaled by the applied zoom"
	)
	assert_true(
		(push[&"uv"] as Vector2).x > 0.0 and (push[&"uv"] as Vector2).x < 1.0
		and (push[&"uv"] as Vector2).y > 0.0 and (push[&"uv"] as Vector2).y < 1.0,
		"and the hull's centre lands on screen (%s)" % str(push[&"uv"])
	)
	## The region tracks the hull rather than being frozen at the first push.
	var before := push[&"uv"] as Vector2
	var origin := _ship.global_position
	_ship.global_position = origin + Vector2(120.0, 0.0)
	_full_strength()
	var moved := (_pushed()[&"uv"] as Vector2) - before
	assert_true(
		_near(moved.x, 120.0 * zoom / size.x, 1e-4) and _near(moved.y, 0.0, 1e-4),
		"moving the hull 120 u moves the pushed region by 120 u of screen (measured %s)" % str(moved)
	)
	_ship.global_position = origin
	## The reversal path: a radius worth pushing comes only from a hull that answers one.
	_ship.remove_from_group(SpeedFantasyScript.PLAYER_GROUP)
	_full_strength()
	var off := _pushed()
	assert_false(bool(off[&"exclude"]), "no hull in the group: the exclusion is off")
	assert_true(
		(off[&"radius"] as Vector2).is_zero_approx(),
		"and a zero radius is pushed, which the shader reads as no region"
	)
	_ship.add_to_group(SpeedFantasyScript.PLAYER_GROUP, true)
	_full_strength()
	assert_true(bool(_pushed()[&"exclude"]), "a hull back in the group restores the region")
	## AC7, evaluated in-process: the shipped fragment's own arithmetic over a synthetic
	## framebuffer built around the disc the shipped material just received.
	var image := _framebuffer(push)
	assert_true(image != null, "the synthetic framebuffer is built")
	if image == null:
		return
	var hull := _sample_hull(image, push)
	var background := _sample_background(image, push)
	assert_true(
		int(hull[&"count"]) > 0,
		"the hull region is on the framebuffer with pixels to compare (%s)" % hull[&"note"]
	)
	assert_true(
		_near(float(hull[&"max"]), 0.0, 1e-6),
		(
			"full blur strength: every hull-region pixel equals the unblurred render (split "
			+ "included), max channel delta %.6f"
		) % float(hull[&"max"])
	)
	assert_true(
		float(background[&"mean"]) > 0.01,
		("while the background differs measurably: mean channel delta %.4f over the patch")
		% float(background[&"mean"])
	)
	## The control that makes the two readings mean something: with the flag off, the same
	## region over the same framebuffer does change, so the exclusion is what preserved it.
	_set_flag(false)
	var uncontrolled := push.duplicate()
	uncontrolled[&"exclude"] = false
	var control := _sample_hull(image, uncontrolled)
	assert_true(
		float(control[&"mean"]) > 0.05,
		("with the flag off the same hull pixels blur (mean channel delta %.4f, %d px)")
		% [float(control[&"mean"]), int(control[&"count"])]
	)
	_set_flag(SpeedFantasyScript.SPEED_BLUR_EXCLUDE_PLAYER)
	_measured = (
		"hull_px=%d hull_max=%.6f hull_mean=%.6f background_mean=%.4f control_mean=%.4f "
		+ "radius_px=%.2f span_px=%.2f"
	) % [
		int(hull[&"count"]),
		float(hull[&"max"]),
		float(hull[&"mean"]),
		float(background[&"mean"]),
		float(control[&"mean"]),
		radius_uv.x * size.x,
		float(push[&"span_px"]),
	]
	print("[S2.6-R5] %s" % _measured)


## --- The fixture's own plumbing ---------------------------------------------


func _material() -> ShaderMaterial:
	var blur := _fantasy.call(&"blur_rect") as ColorRect
	if blur == null:
		return null
	return blur.material as ShaderMaterial


## The frame's own push, exactly as `game.gd` drives it: the wheel's value, the ratio and a
## rightward velocity (so the smear and the split run along screen x).
func _full_strength() -> void:
	_fantasy.call(&"set_wheel_zoom", 1.0)
	_fantasy.call(&"set_ratio", FULL_RATIO, Vector2(400.0, 0.0))


## The three uniforms as the shader received them, plus the span a full-strength smear covers
## in this frame (FX_SPEC section 5's `blur_span_px` times the strength).
func _pushed() -> Dictionary:
	var material := _material()
	var strength := float(_fantasy.call(&"blur_strength"))
	return {
		&"exclude": bool(material.get_shader_parameter(SpeedFantasyScript.EXCLUDE_UNIFORM)),
		&"uv": material.get_shader_parameter(SpeedFantasyScript.HULL_UV_UNIFORM) as Vector2,
		&"radius": material.get_shader_parameter(
			SpeedFantasyScript.HULL_RADIUS_UNIFORM
		) as Vector2,
		&"strength": strength,
		&"aberration": float(material.get_shader_parameter(&"chromatic_aberration")),
		&"span_px": SpeedFantasyScript.BLUR_SPAN_PX * strength,
		&"aberration_px": SpeedFantasyScript.ABERRATION_PX * float(
			material.get_shader_parameter(&"chromatic_aberration")
		),
	}


func _set_flag(value: bool) -> void:
	var material := _material()
	if material != null:
		material.set_shader_parameter(SpeedFantasyScript.EXCLUDE_UNIFORM, value)


func _size() -> Vector2:
	return _host().get_viewport().get_visible_rect().size


## --- The acceptance's comparison, in-process ---------------------------------


## A synthetic framebuffer the size of the game's own viewport, built around the disc the
## material carries: black, the hull's inner disc striped along the smear axis (so a blur
## would visibly wash it out), and one bright rule three radii to the side for the
## background's own reading. Everything is derived from the pushed region, so a wrong region
## moves the stripes with it and the comparison still measures the shipped numbers.
func _framebuffer(push: Dictionary) -> Image:
	var radius_px := (push[&"radius"] as Vector2).x * _size().x
	if radius_px < 2.0:
		assert_true(false, "the pushed radius is too small to measure (%.3f px)" % radius_px)
		return null
	var image := Image.create_empty(int(_size().x), int(_size().y), false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	var centre := (push[&"uv"] as Vector2) * _size()
	var rule_x := int(centre.x + radius_px * BACKGROUND_RULE_RADII)
	if rule_x >= image.get_width() - 4:
		assert_true(false, "no room for the background rule at x=%d" % rule_x)
		return null
	var top := int(maxf(centre.y - radius_px * 4.0, 0.0))
	var bottom := int(minf(centre.y + radius_px * 4.0, float(image.get_height())))
	for y in range(top, bottom):
		image.set_pixel(rule_x, y, Color.WHITE)
		image.set_pixel(rule_x + 1, y, Color.WHITE)
	## The hull's own disc: two-pixel stripes along the smear's axis, at full contrast.
	for y in range(int(centre.y - radius_px), int(centre.y + radius_px) + 1):
		for x in range(int(centre.x - radius_px), int(centre.x + radius_px) + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			if Vector2(x + 0.5, y + 0.5).distance_to(centre) > radius_px * 0.97:
				continue
			image.set_pixel(x, y, Color.WHITE if (x / 2) % 2 == 0 else Color.BLACK)
	return image


## Every hull-region pixel of the inner disc, as the shipped fragment would write it against
## what the unblurred render holds: the max and mean channel deltas.
func _sample_hull(image: Image, push: Dictionary) -> Dictionary:
	var radius_px := (push[&"radius"] as Vector2).x * _size().x
	var centre := (push[&"uv"] as Vector2) * _size()
	var inner := radius_px * HULL_SAMPLE_FRACTION
	var count := 0
	var max_delta := 0.0
	var total := 0.0
	var y := int(centre.y - inner)
	while y <= int(centre.y + inner):
		var x := int(centre.x - inner)
		while x <= int(centre.x + inner):
			if Vector2(x + 0.5, y + 0.5).distance_to(centre) <= inner:
				var got := _fragment_pixel(image, x, y, push)
				var want := image.get_pixel(x, y)
				var delta := maxf(
					absf(got.r - want.r), maxf(absf(got.g - want.g), absf(got.b - want.b))
				)
				max_delta = maxf(max_delta, delta)
				total += delta
				count += 1
			x += HULL_SAMPLE_STEP
		y += HULL_SAMPLE_STEP
	return {
		&"count": count,
		&"max": max_delta,
		&"mean": total / maxf(float(count), 1.0),
		&"note": "inner %.1f px of a %.1f px radius" % [inner, radius_px],
	}


## The background patch, one radius either side of the bright rule: the smear spreads that
## two-pixel rule into a band as wide as its own span, so the delta here is the "everything
## else can be" half of the ruling.
func _sample_background(image: Image, push: Dictionary) -> Dictionary:
	var radius_px := (push[&"radius"] as Vector2).x * _size().x
	var centre := (push[&"uv"] as Vector2) * _size()
	var patch := radius_px * BACKGROUND_PATCH_RADII
	var rule_x := int(centre.x + radius_px * BACKGROUND_RULE_RADII)
	var count := 0
	var total := 0.0
	var max_delta := 0.0
	for x in range(rule_x - int(patch), rule_x + int(patch) + 1):
		for y in range(
			int(centre.y - patch), int(centre.y + patch) + 1
		):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var got := _fragment_pixel(image, x, y, push)
			var want := image.get_pixel(x, y)
			var delta := maxf(
				absf(got.r - want.r), maxf(absf(got.g - want.g), absf(got.b - want.b))
			)
			max_delta = maxf(max_delta, delta)
			total += delta
			count += 1
	return {&"count": count, &"mean": total / maxf(float(count), 1.0), &"max": max_delta}


## `speed_blur.gdshader`'s own fragment, evaluated in GDScript over `image`: the pass-through
## tap, the region test, and - outside the region only - the 17-tap triangular smear and the
## channel split, all with the numbers the shipped material carries. Godot will not run a
## canvas shader outside a frame, so this is the closest the gate can get to the fragment;
## `test_the_exclusion_guards_the_smear_and_the_split_and_never_splits_the_layer` is what pins
## this evaluation to the shipped source, and the report carries the on-GPU numbers.
func _fragment_pixel(image: Image, x: int, y: int, push: Dictionary) -> Color:
	var uv := (Vector2(x + 0.5, y + 0.5)) / _size()
	var tint := _tap(image, uv)
	if bool(push[&"exclude"]) and (push[&"radius"] as Vector2).x > 0.0:
		var offset := (uv - (push[&"uv"] as Vector2)) / (push[&"radius"] as Vector2)
		if offset.dot(offset) <= 1.0:
			return tint
	var strength := float(push[&"strength"])
	if strength <= 0.0:
		return tint
	var dir := Vector2.RIGHT
	var span := SpeedFantasyScript.BLUR_SPAN_PX * strength / _size().x
	var acc := Vector3.ZERO
	var total := 0.0
	for i in TAPS:
		var t := (float(i) / float(TAPS - 1)) - 0.5
		var weight := 1.0 - absf(t * 2.0)
		acc += _to_vec3(_tap(image, uv + dir * t * span))
		total += weight
	tint = _to_color(acc / maxf(total, 0.0001))
	var side := Vector2(-dir.y, dir.x) * SpeedFantasyScript.ABERRATION_PX
	var split := side * float(push[&"aberration"]) * strength * Vector2.ONE / _size()
	tint.r = _tap(image, uv + split).r
	tint.b = _tap(image, uv - split).b
	return tint


func _tap(image: Image, uv: Vector2) -> Color:
	return image.get_pixel(
		clampi(int(uv.x * float(image.get_width())), 0, image.get_width() - 1),
		clampi(int(uv.y * float(image.get_height())), 0, image.get_height() - 1)
	)


func _to_vec3(colour: Color) -> Vector3:
	return Vector3(colour.r, colour.g, colour.b)


func _to_color(value: Vector3) -> Color:
	return Color(value.x, value.y, value.z, 1.0)


## --- Source helpers ---------------------------------------------------------


## The shipped shader's fragment processor, from its declaration to the end of the file.
func _fragment_body(code: String) -> String:
	var start := code.find("void fragment()")
	assert_true(start >= 0, "the shader declares a fragment processor")
	return code.substr(start) if start >= 0 else ""


## The index of the `}` matching the `{` at `open`, counted rather than guessed.
func _block_end(text: String, open: int) -> int:
	var depth := 0
	var index := open
	while index < text.length():
		var char := text[index]
		if char == "{":
			depth += 1
		elif char == "}":
			depth -= 1
			if depth == 0:
				return index
		index += 1
	return -1


## --- Small helpers ----------------------------------------------------------


func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	var main := Engine.get_main_loop()
	assert_true(main is SceneTree, "the suite runs inside a SceneTree")
	return main as SceneTree


func _near(value: float, expected: float, tolerance: float = TOL) -> bool:
	return absf(value - expected) <= tolerance
