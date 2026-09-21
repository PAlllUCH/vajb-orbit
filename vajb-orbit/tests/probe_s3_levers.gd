extends Node2D
## S3's scratch probe: which lever actually sizes the quad a `GPUParticles2D` draws.
##
## S2's `probe_s2_5_trail_draw.tscn` measured that the emitter's own non-uniform `scale`
## does not reach the drawn particle, while the process material's `scale_min/max` does.
## This probe asks the follow-up question the fix needs answered: can the quad be sized
## *non-uniformly* (FX_SPEC section 1.3's 24-56 u long by 6 u wide) at all, and through
## which lever?
##
## One white 64 x 64 texture, one particle, six arms, each read off the framebuffer as a
## bounding box. Needs a display; not part of the gate. Quits itself.
##
## Run: ~/.local/bin/godot --path vajb-orbit res://tests/probe_s3_levers.tscn

const TAG := "[S3L]"

const VERTEX_SHADER := """
shader_type canvas_item;
uniform vec2 quad_scale = vec2(1.0, 1.0);
void vertex() {
	VERTEX *= quad_scale;
}
"""


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
	await _arm(&"a_node_scale", Vector2(0.375, 0.125))
	await _arm(&"b_parent_scale", Vector2(0.375, 0.125))
	await _arm(&"c_process_scale_uniform", Vector2(0.375, 0.125))
	await _arm(&"d_shader_vertex", Vector2(0.375, 0.125))
	await _arm(&"e_shader_vertex_control", Vector2(1.0, 1.0))
	print("%s done" % TAG)
	get_tree().quit()


func _arm(mode: StringName, factor: Vector2) -> void:
	var holder := Node2D.new()
	add_child(holder)
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
	match mode:
		&"a_node_scale":
			emitter.scale = factor
		&"b_parent_scale":
			holder.scale = factor
		&"c_process_scale_uniform":
			process.scale_min = factor.x
			process.scale_max = factor.x
		&"d_shader_vertex", &"e_shader_vertex_control":
			var shader := Shader.new()
			shader.code = VERTEX_SHADER
			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter(&"quad_scale", factor)
			emitter.material = material
	holder.add_child(emitter)
	for i in 30:
		await RenderingServer.frame_post_draw
	print(
		"%s LEVER mode=%s factor=(%.3f,%.3f) box=%s"
		% [TAG, mode, factor.x, factor.y, str(_box(_frame()))]
	)
	holder.queue_free()
	await RenderingServer.frame_post_draw


func _frame() -> Image:
	return get_viewport().get_texture().get_image()


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
