extends Node2D
## S3's acceptance probe for HIGH 2: the rectangle the shipped thruster emitter **draws**,
## at the section's own ratios.
##
## S2's report section 2.2 measured that the emitter's node `scale` never reaches the
## drawn quad (a 1401 x 86 px band on a 1920 x 1080 frame, the master's native size), so
## FX_SPEC section 1.3's "24 u at ratio 0.15 -> 56 u at 1.0 / 6 u wide" never reached the
## screen. This probe re-measures that rectangle after the fix, on a black world at zoom
## 1.0 (1 world unit = 1 px), with three arms:
##
##   SHIPPED - the shipped `sync_thruster_trails` emitter, one anchor, over 90 frames, at
##             ratios 0.15 / 0.5 / 1.0: the lit box, the quad the draw pass asks for
##             (`quad_scale` x the drawn frame's own pixels), and where the streak's head
##             lands relative to the anchor;
##   SOLID   - the same quad scale over a solid frame of the same 159 x 26 px, so the
##             drawn rectangle is measurable to the pixel rather than to the art's taper;
##   LEVER   - the three levers on one emitter: the node's `scale` (inert), the process
##             material's uniform `scale_min` (aspect-locked), and the draw pass.
##
## Needs a display; not part of the gate. Quits itself.
##
## Run: ~/.local/bin/godot --path vajb-orbit res://tests/probe_s3_trail_quad.tscn

const ProjectileScript := preload("res://game/projectile.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[S3Q]"
const THRESHOLD := 0.002
const ANCHOR := Vector2(-16.5, 0.0)
const RATIOS: Array[float] = [0.15, 0.5, 1.0]


func _ready() -> void:
	var camera := Camera2D.new()
	camera.name = &"ProbeCamera"
	add_child(camera)
	camera.make_current()
	var world := Node2D.new()
	world.set_script(preload("res://tests/probe_s2_5_node_scale_world.gd"))
	add_child(world)
	print("%s HEAD viewport=%s" % [TAG, str(get_viewport().get_visible_rect().size)])
	await RenderingServer.frame_post_draw
	print("%s BACKGROUND box=%s" % [TAG, str(_box(_frame()))])
	for ratio: float in RATIOS:
		await _case_shipped(ratio)
	await _case_solid(0.15)
	await _case_solid(1.0)
	await _case_lever()
	print("%s done" % TAG)
	get_tree().quit()


## The shipped emitter: one anchor on a bare hull node, the shipped sync, 90 frames.
func _case_shipped(ratio: float) -> void:
	var hull := Node2D.new()
	hull.name = &"ProbeHull"
	add_child(hull)
	var emitters := ProjectileScript.sync_thruster_trails(hull, [ANCHOR], ratio, true)
	if emitters.is_empty():
		print("%s SHIPPED ratio=%.2f emitters=0" % [TAG, ratio])
		hull.queue_free()
		return
	var emitter := emitters[0]
	for i in 90:
		await RenderingServer.frame_post_draw
	var image := _frame()
	var box := _box(image)
	var quad := _quad_scale(emitter)
	var source := ProjectileScript.feedback_row(&"trail")[&"source"] as Vector2
	var bright := _bright_column(image, box)
	var anchor_px := _screen(ANCHOR)
	print(
		(
			"%s SHIPPED ratio=%.2f length=%.1f width=%.1f quad_scale=(%.6f,%.6f) "
			+ "quad_px=(%.1f,%.1f) node_scale=%s box=%s lit=%d max=%.4f bright_x=%d box_right=%d anchor_x=%d"
		)
		% [
			TAG,
			ratio,
			ProjectileScript.trail_length(ratio),
			ProjectileScript.TRAIL_WIDTH,
			quad.x,
			quad.y,
			quad.x * source.x,
			quad.y * source.y,
			str(emitter.scale),
			str(box),
			_lit(image),
			_max(image),
			bright,
			box.position.x + box.size.x,
			anchor_px,
		]
	)
	emitter.queue_free()
	hull.queue_free()
	await RenderingServer.frame_post_draw


## The same quad scale over a solid frame of the drawn frame's own size: the drawn
## rectangle to the pixel.
func _case_solid(ratio: float) -> void:
	var hull := Node2D.new()
	add_child(hull)
	var emitters := ProjectileScript.sync_thruster_trails(hull, [ANCHOR], ratio, true)
	if emitters.is_empty():
		hull.queue_free()
		return
	var emitter := emitters[0]
	var source := ProjectileScript.feedback_row(&"trail")[&"source"] as Vector2
	var image := Image.create(int(source.x), int(source.y), false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	emitter.texture = ImageTexture.create_from_image(image)
	for i in 60:
		await RenderingServer.frame_post_draw
	var frame := _frame()
	print(
		"%s SOLID ratio=%.2f frame=%dx%d box=%s lit=%d"
		% [
			TAG,
			ratio,
			int(source.x),
			int(source.y),
			str(_box(frame)),
			_lit(frame),
		]
	)
	emitter.queue_free()
	hull.queue_free()
	await RenderingServer.frame_post_draw


## The three levers on one 159 x 26 texture, so the comparison is the lever alone.
func _case_lever() -> void:
	var source := Vector2(159.0, 26.0)
	for mode: String in ["node_scale", "particle_uniform", "draw_pass"]:
		var emitter := GPUParticles2D.new()
		var image := Image.create(int(source.x), int(source.y), false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		emitter.texture = ImageTexture.create_from_image(image)
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		process.initial_velocity_min = 0.0
		process.initial_velocity_max = 0.0
		process.gravity = Vector3.ZERO
		process.color = Color(1.0, 1.0, 1.0, 1.0)
		process.scale_min = 1.0
		process.scale_max = 1.0
		emitter.process_material = process
		emitter.amount = 1
		emitter.lifetime = 60.0
		emitter.preprocess = 60.0
		emitter.local_coords = false
		emitter.visibility_rect = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
		emitter.use_fixed_seed = true
		emitter.seed = 7
		if mode == "node_scale":
			emitter.scale = Vector2(24.0 / source.x, 6.0 / source.y)
		elif mode == "particle_uniform":
			process.scale_min = 24.0 / source.x
			process.scale_max = 24.0 / source.x
		else:
			emitter.material = FxScript.quad_material(Vector2(24.0 / source.x, 6.0 / source.y))
		add_child(emitter)
		for i in 30:
			await RenderingServer.frame_post_draw
		var image_out := _frame()
		print(
			"%s LEVER mode=%s node_scale=%s particle_scale=%.6f quad_scale=%s box=%s lit=%d"
			% [
				TAG,
				mode,
				str(emitter.scale),
				process.scale_min,
				str(_quad_scale(emitter)),
				str(_box(image_out)),
				_lit(image_out),
			]
		)
		emitter.queue_free()
		await RenderingServer.frame_post_draw


## The luminance-weighted centre column of the drawn box: the streak's hot end (its head)
## pulls it toward itself, so the number says which way the streak points.
func _bright_column(image: Image, box: Rect2i) -> int:
	if box.size.x <= 0:
		return -1
	var weighted := 0.0
	var total := 0.0
	for x in range(box.position.x, box.position.x + box.size.x):
		var column := 0.0
		for y in range(box.position.y, box.position.y + box.size.y):
			column += _luminance(image.get_pixel(x, y))
		weighted += column * float(x)
		total += column
	if total <= 0.0:
		return -1
	return int(round(weighted / total))


## A world point's screen x: the camera sits at the viewport's centre at zoom 1.0 here, so
## this is the same 1:1 mapping the world units are quoted in.
func _screen(point: Vector2) -> int:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return int(point.x)
	var centre := camera.get_screen_center_position()
	return int(round((point.x - centre.x) * camera.zoom.x + get_viewport().get_visible_rect().size.x * 0.5))


func _quad_scale(node: CanvasItem) -> Vector2:
	var material := node.material as ShaderMaterial
	if material == null:
		return Vector2.ZERO
	return material.get_shader_parameter(&"quad_scale") as Vector2


func _frame() -> Image:
	return get_viewport().get_texture().get_image()


func _luminance(colour: Color) -> float:
	return maxf(colour.r, maxf(colour.g, colour.b))


func _lit(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if _luminance(image.get_pixel(x, y)) > THRESHOLD:
				count += 1
	return count


func _max(image: Image) -> float:
	var top := 0.0
	for y in image.get_height():
		for x in image.get_width():
			top = maxf(top, _luminance(image.get_pixel(x, y)))
	return top


## The bounding box of every pixel above the threshold - the drawn rectangle as the
## framebuffer sees it.
func _box(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if _luminance(image.get_pixel(x, y)) <= THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
