extends Node2D
## Does a *uniform* `GPUParticles2D.scale` reach the drawn quad? One arm, one number.
const TAG := "[S2S]"


func _ready() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()
	var world := Node2D.new()
	world.set_script(preload("res://tests/probe_s2_5_node_scale_world.gd"))
	add_child(world)
	await RenderingServer.frame_post_draw
	for scale: Vector2 in [Vector2.ONE, Vector2(0.5, 0.5), Vector2(0.017131, 0.069767)]:
		var emitter := GPUParticles2D.new()
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		emitter.texture = ImageTexture.create_from_image(image)
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		process.initial_velocity_min = 0.0
		process.initial_velocity_max = 0.0
		process.gravity = Vector3.ZERO
		emitter.process_material = process
		emitter.amount = 1
		emitter.lifetime = 60.0
		emitter.preprocess = 60.0
		emitter.local_coords = false
		emitter.visibility_rect = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
		emitter.use_fixed_seed = true
		emitter.seed = 5
		emitter.scale = scale
		add_child(emitter)
		for i in 30:
			await RenderingServer.frame_post_draw
		var box := _box(get_viewport().get_texture().get_image())
		print("%s NODE_SCALE scale=(%.6f,%.6f) drawn_box=%s" % [TAG, scale.x, scale.y, str(box)])
		emitter.queue_free()
		await RenderingServer.frame_post_draw
	get_tree().quit()


func _box(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if maxf(colour.r, maxf(colour.g, colour.b)) <= 0.5:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
