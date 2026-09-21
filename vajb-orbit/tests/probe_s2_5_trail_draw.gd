extends Node2D
## S2's focused draw probe: what the thruster trail's emitter actually puts on the
## framebuffer, and whether `amount_ratio` scales the emitted count once the emitter is
## restarted (the state probe cannot see either).
##
## Three arms, all over an explicitly drawn black world at zoom 1.0:
##   PLATE  - the trail's shipped master drawn as one additive `Sprite2D` at the same
##            scale/rotation/alpha the emitter uses: the brightest a streak can be;
##   TRAIL  - the shipped `sync_thruster_trails` emitter, 90 frames at ratio 0.15 and 1.0;
##   RATIO  - a synthetic emitter restarted per ratio, so the count is not polluted by the
##            previous arm's still-living particles.
##
## Needs a display; not part of the gate. Quits itself.
##
## Run: ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_trail_draw.tscn

const ProjectileScript := preload("res://game/projectile.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[S2D]"
const THRESHOLD := 0.002


func _ready() -> void:
	var camera := Camera2D.new()
	camera.name = &"ProbeCamera"
	add_child(camera)
	camera.make_current()
	var world := BlackWorld.new()
	add_child(world)
	print("%s HEAD viewport=%s" % [TAG, str(get_viewport().get_visible_rect().size)])
	await RenderingServer.frame_post_draw
	var empty := _frame()
	print(
		"%s BACKGROUND max=%.6f mean=%.6f lit=%d"
		% [TAG, _max(empty), _mean(empty), _lit(empty)]
	)
	await _case_plate()
	await _case_trail()
	await _case_scale_lever()
	await _case_ratio()
	await _case_shipped()
	print("%s done" % TAG)
	get_tree().quit()


## Which lever actually scales the streak: the node's own `scale`, or the process
## material's `scale_min/max` (the dust row's route)?
func _case_scale_lever() -> void:
	var row := ProjectileScript.feedback_row(&"trail")
	var texture := load(String(row[&"texture"])) as Texture2D
	for mode: String in ["node_scale", "particle_scale"]:
		var emitter := GPUParticles2D.new()
		emitter.texture = FxScript.frame(texture, row[&"region"] as Rect2)
		emitter.material = FxScript.additive_material()
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		process.initial_velocity_min = 0.0
		process.initial_velocity_max = 0.0
		process.gravity = Vector3.ZERO
		if mode == "particle_scale":
			process.scale_min = 0.017131
			process.scale_max = 0.017131
			process.color = Color(1.0, 1.0, 1.0, 0.35)
			emitter.scale = Vector2.ONE
		else:
			process.scale_min = 1.0
			process.scale_max = 1.0
			process.color = Color(1.0, 1.0, 1.0, 0.35)
			emitter.scale = Vector2(0.017131, 0.069767)
		emitter.process_material = process
		emitter.amount = 24
		emitter.lifetime = 0.4
		emitter.local_coords = false
		emitter.visibility_rect = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
		emitter.use_fixed_seed = true
		emitter.seed = 11
		add_child(emitter)
		for i in 60:
			await RenderingServer.frame_post_draw
		var image := _frame()
		print(
			"%s SCALE_LEVER mode=%s node_scale=(%.6f,%.6f) particle_scale=%.6f lit=%d max=%.4f box=%s"
			% [
				TAG,
				mode,
				emitter.scale.x,
				emitter.scale.y,
				process.scale_min,
				_lit(image),
				_max(image),
				str(_box(image)),
			]
		)
		emitter.queue_free()
		await RenderingServer.frame_post_draw


## The shipped scene: `game.tscn`, the throttle held, read off the framebuffer.
func _case_shipped() -> void:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		print("%s SHIPPED scene=missing" % TAG)
		return
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var stats: Variant = scene.get(&"_stats")
	if ship == null or stats == null:
		print("%s SHIPPED wiring=missing" % TAG)
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	Input.action_press(&"thrust_forward")
	## Held at rest: the throttle keeps the trail emitting (FX_SPEC section 1.3's own rule)
	## while the hull, the camera and the parallax stay still, so a frame diff measures the
	## trail's own footprint rather than the world's motion.
	for i in 90:
		if body != null:
			body.linear_velocity = Vector2.ZERO
		await RenderingServer.frame_post_draw
	var image := _frame()
	var trails: Array = ship.call(&"thruster_trails")
	var trail := trails[0] as GPUParticles2D
	print(
		"%s SHIPPED ship_speed_ratio=%.4f emitters=%d emitting=%s label_streak_scale=%s pos=(%.2f,%.2f) lit=%d max=%.4f"
		% [
			TAG,
			float(ship.call(&"speed_ratio")),
			trails.size(),
			str(trail.emitting),
			str(trail.scale),
			trail.global_position.x,
			trail.global_position.y,
			_lit(image),
			_max(image),
		]
	)
	## The trail's own contribution on the shipped scene: its emitters off, then on, from
	## the same camera and the same world, so the HUD, the stars and the ship cancel.
	trail.visible = false
	trail.emitting = false
	for i in 8:
		if body != null:
			body.linear_velocity = Vector2.ZERO
		await RenderingServer.frame_post_draw
	var without := _frame()
	trail.visible = true
	trail.emitting = true
	for i in 60:
		if body != null:
			body.linear_velocity = Vector2.ZERO
		await RenderingServer.frame_post_draw
	var with_trail := _frame()
	var delta := _delta(without, with_trail)
	print(
		"%s SHIPPED_DIFF changed=%d max_brighter=%.4f max_darker=%.4f box=%s"
		% [TAG, delta[&"changed"], delta[&"up"], delta[&"down"], str(delta[&"box"])]
	)
	## The band the emitter's own quad covers, in screen space, at both ends of the run: the
	## mean luminance inside it is robust to the world's own motion, which a whole-frame diff
	## is not.
	var centre := Vector2i(
		with_trail.get_width() / 2, with_trail.get_height() / 2
	)
	var band := Rect2i(centre.x - 700, centre.y - 43, 1401, 86)
	print(
		"%s SHIPPED_BAND band=%s mean_without=%.6f mean_with=%.6f lift=%.6f"
		% [
			TAG,
			str(band),
			_mean_rect(without, band),
			_mean_rect(with_trail, band),
			_mean_rect(with_trail, band) - _mean_rect(without, band),
		]
	)
	print("%s SHIPPED_DUMP%s" % [TAG, _dump(with_trail)])
	print(
		"%s SHIPPED_ALPHA trail_alpha=%.4f plate_peak=1.0000 additive=%s particles_alive=%d scale=%s"
		% [
			TAG,
			(trail.process_material as ParticleProcessMaterial).color.a,
			str(trail.material is CanvasItemMaterial),
			trail.amount,
			str(trail.scale),
		]
	)
	Input.action_release(&"thrust_forward")
	scene.queue_free()
	await RenderingServer.frame_post_draw


## The pixels that changed between two frames, and their bounding box.
func _delta(before: Image, after: Image) -> Dictionary:
	var changed := 0
	var up := 0.0
	var down := 0.0
	var min_x := before.get_width()
	var min_y := before.get_height()
	var max_x := -1
	var max_y := -1
	for y in before.get_height():
		for x in before.get_width():
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			var delta := maxf(b.r, maxf(b.g, b.b)) - maxf(a.r, maxf(a.g, a.b))
			if absf(delta) <= 0.02:
				continue
			changed += 1
			up = maxf(up, delta)
			down = maxf(down, -delta)
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	return {
		&"changed": changed,
		&"up": up,
		&"down": down,
		&"box": Rect2i() if max_x < 0 else Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
	}


## The trail's own master, drawn once, additively, at the emitter's own transform.
func _case_plate() -> void:
	var row := ProjectileScript.feedback_row(&"trail")
	var texture := load(String(row[&"texture"])) as Texture2D
	var region := row[&"region"] as Rect2
	var source := row[&"source"] as Vector2
	var sprite := Sprite2D.new()
	sprite.texture = FxScript.frame(texture, region)
	sprite.material = FxScript.additive_material()
	sprite.centered = true
	sprite.position = Vector2(-12.0, 0.0)
	sprite.rotation = PI
	sprite.scale = Vector2(24.0 / source.x, 6.0 / source.y)
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.35)
	add_child(sprite)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := _frame()
	var box := _box(image)
	print(
		(
			"%s PLATE texture=%s region=%s scale=(%.6f,%.6f) modulate_a=%.2f "
			+ "lit=%d max=%.4f mean=%.8f box=%s"
		)
		% [
			TAG,
			String(row[&"texture"]),
			str(region),
			sprite.scale.x,
			sprite.scale.y,
			sprite.modulate.a,
			_lit(image),
			_max(image),
			_mean(image),
			str(box),
		]
	)
	## The plate's own pixels, so "how bright can a streak be" is a number.
	var inside := texture.get_image().get_region(Rect2i(region))
	var peak := 0.0
	var total := 0.0
	for y in inside.get_height():
		for x in inside.get_width():
			var colour := inside.get_pixel(x, y)
			var value := maxf(colour.r, maxf(colour.g, colour.b))
			peak = maxf(peak, value)
			total += value
	print(
		"%s PLATE_MASTER peak=%.4f mean=%.4f (%d x %d px)"
		% [TAG, peak, total / float(inside.get_width() * inside.get_height()), inside.get_width(), inside.get_height()]
	)
	sprite.queue_free()
	await RenderingServer.frame_post_draw


## The shipped emitter, driven by the shipped sync.
func _case_trail() -> void:
	var holder := Node2D.new()
	add_child(holder)
	var anchors: Array[Vector2] = [Vector2.ZERO]
	for ratio: float in [0.15, 1.0]:
		ProjectileScript.clear_thruster_trails(holder)
		await RenderingServer.frame_post_draw
		ProjectileScript.sync_thruster_trails(holder, anchors, ratio, true)
		var trails: Array = ProjectileScript.sync_thruster_trails(holder, anchors, ratio, true)
		var trail := trails[0] as GPUParticles2D
		for i in 90:
			await RenderingServer.frame_post_draw
		var image := _frame()
		var box := _box(image)
		print(
			(
				"%s TRAIL ratio=%.2f emitting=%s amount=%d amount_ratio=%.6f lifetime=%.2f "
				+ "local_coords=%s scale=(%.6f,%.6f) pos=(%.4f,%.4f) rotation_deg=%.1f "
				+ "visibility_rect=%s material=%s sheet=%s lit=%d max=%.4f mean=%.8f box=%s"
			)
			% [
				TAG,
				ratio,
				str(trail.emitting),
				trail.amount,
				trail.amount_ratio,
				trail.lifetime,
				str(trail.local_coords),
				trail.scale.x,
				trail.scale.y,
				trail.position.x,
				trail.position.y,
				rad_to_deg(trail.rotation),
				str(trail.visibility_rect),
				str(trail.material),
				_source_path(trail.texture),
				_lit(image),
				_max(image),
				_mean(image),
				str(box),
			]
		)
		print("%s TRAIL_DUMP ratio=%.2f%s" % [TAG, ratio, _dump(image)])
	## The same emitter with a far larger visibility rect, to separate culling from drawing.
	ProjectileScript.clear_thruster_trails(holder)
	await RenderingServer.frame_post_draw
	var trails: Array = ProjectileScript.sync_thruster_trails(holder, anchors, 0.15, true)
	var trail := trails[0] as GPUParticles2D
	trail.visibility_rect = Rect2(-1200.0, -800.0, 2400.0, 1600.0)
	for i in 90:
		await RenderingServer.frame_post_draw
	var image := _frame()
	print(
		"%s TRAIL_WIDE visibility_rect=%s lit=%d max=%.4f box=%s"
		% [TAG, str(trail.visibility_rect), _lit(image), _max(image), str(_box(image))]
	)
	ProjectileScript.clear_thruster_trails(holder)
	holder.queue_free()
	await RenderingServer.frame_post_draw


## A synthetic emitter restarted per ratio: does `amount_ratio` scale the emitted count?
func _case_ratio() -> void:
	var emitter := GPUParticles2D.new()
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	emitter.texture = ImageTexture.create_from_image(image)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(700.0, 380.0, 0.0)
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.0
	process.gravity = Vector3.ZERO
	emitter.process_material = process
	emitter.amount = 24
	emitter.lifetime = 0.5
	emitter.local_coords = false
	emitter.visibility_rect = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
	emitter.use_fixed_seed = true
	emitter.seed = 7
	add_child(emitter)
	for ratio: float in [1.0, 0.333333, 0.5]:
		emitter.emitting = false
		await RenderingServer.frame_post_draw
		emitter.amount_ratio = ratio
		emitter.restart()
		emitter.emitting = true
		for i in 40:
			await RenderingServer.frame_post_draw
		var frame := _frame()
		print(
			"%s RATIO amount_ratio=%.6f expected_particles=%.2f lit=%d lit_per_particle=%.2f"
			% [TAG, ratio, 24.0 * ratio, _lit(frame), float(_lit(frame)) / maxf(24.0 * ratio, 1.0)]
		)
	emitter.queue_free()


class BlackWorld extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-4000.0, -4000.0, 8000.0, 8000.0), Color.BLACK)


func _frame() -> Image:
	return get_viewport().get_texture().get_image()


func _max(image: Image) -> float:
	var peak := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			peak = maxf(peak, maxf(colour.r, maxf(colour.g, colour.b)))
	return peak


func _mean(image: Image) -> float:
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			total += maxf(colour.r, maxf(colour.g, colour.b))
	return total / float(image.get_width() * image.get_height())


func _lit(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if maxf(colour.r, maxf(colour.g, colour.b)) > THRESHOLD:
				count += 1
	return count


## The bounding box of everything above the threshold.
func _box(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if maxf(colour.r, maxf(colour.g, colour.b)) <= THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


## A coarse luminance picture of the streak's own neighbourhood, in tens: 0-9 by decade.
func _dump(image: Image) -> String:
	var centre := Vector2i(image.get_width() / 2, image.get_height() / 2)
	var out := "\n"
	for y in range(-8, 9, 2):
		var row := "    "
		for x in range(-40, 41, 2):
			var at := centre + Vector2i(x, y)
			if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
				row += " "
				continue
			var colour := image.get_pixel(at.x, at.y)
			var value := maxf(colour.r, maxf(colour.g, colour.b))
			if value <= THRESHOLD:
				row += "."
			elif value < 0.1:
				row += "1"
			elif value < 0.25:
				row += "2"
			elif value < 0.5:
				row += "5"
			else:
				row += "9"
		out += row + "\n"
	return out


func _source_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	if texture is AtlasTexture:
		var atlas := (texture as AtlasTexture).atlas
		return atlas.resource_path if atlas != null else ""
	return texture.resource_path

func _mean_rect(image: Image, rect: Rect2i) -> float:
	var total := 0.0
	var count := 0
	for y in range(maxi(rect.position.y, 0), mini(rect.position.y + rect.size.y, image.get_height())):
		for x in range(maxi(rect.position.x, 0), mini(rect.position.x + rect.size.x, image.get_width())):
			var colour := image.get_pixel(x, y)
			total += maxf(colour.r, maxf(colour.g, colour.b))
			count += 1
	return total / maxf(float(count), 1.0)
