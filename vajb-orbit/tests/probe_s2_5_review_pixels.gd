extends Node2D
## S2's rendering probe for slice 2.5's two questions the state probe cannot answer:
##
##   AMOUNT_RATIO - does the renderer's `GPUParticles2D.amount_ratio` actually scale the
##                  emitted particle count (S1's finding 6.3)? Measured as lit pixels from a
##                  synthetic emitter whose geometry is fixed, and on the shipped trail at
##                  ratio 0.15 against 1.0 (its rate is the ratio's own ramp).
##   DUST         - what the shipped dust emitter draws over a bright world: FX_SPEC section 5
##                  row 3 says "never additively blown", and the plate carries **no alpha**
##                  (measured), so a MIX draw composites the plate's whole rectangle, not a
##                  streak. Reported as changed pixels against a no-dust baseline.
##   CULL         - whether the shipped `visibility_rect` (200 x 200 around the node) clips
##                  particles emitted across the whole viewport.
##
## Needs a display; not part of the gate. Quits itself.
##
## Run: ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_review_pixels.tscn

const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const ProjectileScript := preload("res://game/projectile.gd")

const TAG := "[S2P]"
const THRESHOLD := 0.002

var _camera: Camera2D = null
var _world: Variant = null


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.name = &"ProbeCamera"
	add_child(_camera)
	_camera.make_current()
	_world = GreyWorld.new()
	## Behind everything: the camera's dust emitter is a child of the camera, which is
	## added first, so a world drawn on top would hide it (measured the hard way).
	_world.z_index = -100
	add_child(_world)
	print("%s HEAD viewport=%s" % [TAG, str(get_viewport().get_visible_rect().size)])
	await _case_amount_ratio_synthetic()
	await _case_trail_area()
	await _case_dust_vs_black()
	await _case_dust_vs_bright()
	await _case_visibility_rect()
	print("%s done" % TAG)
	get_tree().quit()


## A synthetic emitter with fixed geometry: a white square per particle, no velocity, no
## gravity, an emission box large enough that particles do not overlap.
func _case_amount_ratio_synthetic() -> void:
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
	process.scale_min = 1.0
	process.scale_max = 1.0
	emitter.process_material = process
	emitter.amount = 24
	emitter.lifetime = 60.0
	emitter.preprocess = 60.0
	emitter.local_coords = false
	emitter.visibility_rect = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
	emitter.use_fixed_seed = true
	emitter.seed = 7
	add_child(emitter)
	for ratio: float in [1.0, 0.333333, 0.5]:
		emitter.amount_ratio = ratio
		emitter.emitting = true
		await _settle(6)
		var lit := _lit(_frame_now())
		print(
			"%s AMOUNT_RATIO amount=24 amount_ratio=%.6f expected_particles=%.2f lit_px=%d"
			% [TAG, ratio, 24.0 * ratio, lit]
		)
		emitter.emitting = false
		await _settle(4)
	emitter.queue_free()


## The shipped trail's own area at the two spec ratios, over black: the rate is 20/s -> 60/s
## and the streak 24 u -> 56 u, so a honoured `amount_ratio` shows a much larger area ratio
## than the length change alone (56/24 = 2.33).
func _case_trail_area() -> void:
	var holder := Node2D.new()
	add_child(holder)
	var sheet := "res://assets/fx/fx_engine_trail_f1.png"
	var row := ProjectileScript.feedback_row(&"trail")
	var areas := {}
	for ratio: float in [0.15, 1.0]:
		ProjectileScript.clear_thruster_trails(holder)
		var anchors: Array[Vector2] = [Vector2.ZERO]
		ProjectileScript.sync_thruster_trails(holder, anchors, ratio, true)
		var trails: Array = ProjectileScript.sync_thruster_trails(holder, anchors, ratio, true)
		for i in 90:
			await get_tree().process_frame
		var image := _frame_now()
		var measured := _blob(image)
		areas[ratio] = measured
		print(
			"%s TRAIL_AREA ratio=%.2f sheet=%s blobs=%d lit_px=%d mean=%.6f peak=%.6f"
			% [TAG, ratio, sheet, measured[&"blobs"], measured[&"lit"], measured[&"mean"], measured[&"peak"]]
		)
		if trails.size() > 0:
			print(
				"%s TRAIL_AREA ratio=%.2f amount_ratio=%.6f lifetime=%.2f scale=(%.6f,%.6f)"
				% [
					TAG,
					ratio,
					(trails[0] as GPUParticles2D).amount_ratio,
					(trails[0] as GPUParticles2D).lifetime,
					(trails[0] as GPUParticles2D).scale.x,
					(trails[0] as GPUParticles2D).scale.y,
				]
			)
	if areas.has(0.15) and areas.has(1.0):
		var low: int = int(areas[0.15][&"blobs"])
		var high: int = int(areas[1.0][&"blobs"])
		print(
			"%s TRAIL_AREA blob_ratio=%.4f (20/s -> 60/s with 24 u -> 56 u: 7.0 if the rate scales, 2.33 if only the length does)"
			% [TAG, float(high) / maxf(float(low), 1.0)]
		)
	ProjectileScript.clear_thruster_trails(holder)
	holder.queue_free()


## The shipped dust over a black world, and the same emitter's own box over a bright one.
func _case_dust_vs_black() -> void:
	await _dust_case("black", 0.0)


func _case_dust_vs_bright() -> void:
	await _dust_case("bright", 0.5)


func _dust_case(label: String, brightness: float) -> void:
	if _world != null:
		_world.brightness = brightness
		_world.queue_redraw()
	var screen: Variant = SpeedFantasyScript.new()
	add_child(screen)
	screen.call(&"bind_camera", _camera)
	screen.call(&"set_wheel_zoom", 1.0)
	screen.call(&"set_ratio", 1.0, Vector2(1.0, 0.0))
	var dust := screen.call(&"dust") as GPUParticles2D
	## The blur rides the same ratio and covers the screen on its own canvas layer, so it is
	## switched off for this measurement: the reading is the dust's own pixels.
	var blur := screen.call(&"blur_rect") as ColorRect
	if blur != null:
		blur.visible = false
	if dust == null:
		print("%s DUST_%s emitter=missing" % [TAG, label])
		return
	## The baseline: the same scene with nothing emitted.
	dust.emitting = false
	dust.visible = false
	await _settle(8)
	var baseline := _frame_now()
	print(
		"%s DUST_%s emitter visibility_rect=%s emission_box=%s particle_scale=%.6f node_scale=%s background_measured=%.6f"
		% [
			TAG,
			label,
			str(dust.visibility_rect),
			str((dust.process_material as ParticleProcessMaterial).emission_box_extents),
			(dust.process_material as ParticleProcessMaterial).scale_min,
			str(dust.scale),
			_max(baseline),
		]
	)
	dust.emitting = true
	dust.visible = true
	for i in 40:
		await get_tree().process_frame
	if blur != null:
		blur.visible = false
	var with_dust := _frame_now()
	var stats := _diff(baseline, with_dust)
	print(
		(
			"%s DUST_%s background=%.2f changed_px=%d max_brighter=%.4f max_darker=%.4f "
			+ "mean_abs=%.6f interior_changed=%d interior_max_darker=%.4f"
		)
		% [
			TAG,
			label,
			brightness,
			stats[&"changed"],
			stats[&"up"],
			stats[&"down"],
			stats[&"mean"],
			stats[&"interior"],
			stats[&"interior_down"],
		]
	)
	screen.queue_free()
	await _settle(2)


## Does a 200 x 200 `visibility_rect` clip particles emitted across the whole viewport?
func _case_visibility_rect() -> void:
	if _world != null:
		_world.brightness = 0.0
		_world.queue_redraw()
	await _settle(2)
	var emitter := GPUParticles2D.new()
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	emitter.texture = ImageTexture.create_from_image(image)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(900.0, 500.0, 0.0)
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.0
	process.gravity = Vector3.ZERO
	emitter.process_material = process
	emitter.amount = 40
	emitter.lifetime = 60.0
	emitter.preprocess = 60.0
	emitter.local_coords = false
	emitter.use_fixed_seed = true
	emitter.seed = 3
	add_child(emitter)
	for rect: Rect2 in [Rect2(-100.0, -100.0, 200.0, 200.0), Rect2(-1000.0, -600.0, 2000.0, 1200.0)]:
		emitter.visibility_rect = rect
		emitter.emitting = true
		await _settle(6)
		var frame := _frame_now()
		var inside := _lit_in(frame, Rect2i(860, 440, 200, 200))
		var outside := _lit(frame) - inside
		print(
			"%s VISIBILITY_RECT rect=%s lit_inside_200x200=%d lit_outside=%d"
			% [TAG, str(rect), inside, outside]
		)
		emitter.emitting = false
		await _settle(4)
	emitter.queue_free()


## --- Rendering helpers --------------------------------------------------------

class GreyWorld extends Node2D:
	var brightness := 0.0

	func _draw() -> void:
		draw_rect(
			Rect2(-4000.0, -4000.0, 8000.0, 8000.0),
			Color(brightness, brightness, brightness)
		)


func _settle(frames: int) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw


## The framebuffer as it stands after the awaited `frame_post_draw` in `_settle`.
func _frame_now() -> Image:
	return get_viewport().get_texture().get_image()


func _lit(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if maxf(colour.r, maxf(colour.g, colour.b)) > THRESHOLD:
				count += 1
	return count


func _lit_in(image: Image, rect: Rect2i) -> int:
	var count := 0
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if y < 0 or x < 0 or y >= image.get_height() or x >= image.get_width():
				continue
			var colour := image.get_pixel(x, y)
			if maxf(colour.r, maxf(colour.g, colour.b)) > THRESHOLD:
				count += 1
	return count


## How many pixels changed between the two frames, the largest brightening and darkening,
## and the same over the middle of the frame (the emission box's own window).
func _diff(before: Image, after: Image) -> Dictionary:
	var changed := 0
	var up := 0.0
	var down := 0.0
	var total := 0.0
	var interior := 0
	var interior_down := 0.0
	var centre := Vector2i(before.get_width() / 2, before.get_height() / 2)
	for y in before.get_height():
		for x in before.get_width():
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			var delta := maxf(b.r, maxf(b.g, b.b)) - maxf(a.r, maxf(a.g, a.b))
			var is_interior := absi(x - centre.x) <= 100 and absi(y - centre.y) <= 100
			if absf(delta) > THRESHOLD:
				changed += 1
				if is_interior:
					interior += 1
				if delta > 0.0:
					up = maxf(up, delta)
				else:
					down = maxf(down, -delta)
					if is_interior:
						interior_down = maxf(interior_down, -delta)
			total += absf(delta)
	return {
		&"changed": changed,
		&"up": up,
		&"down": down,
		&"mean": total / float(before.get_width() * before.get_height()),
		&"interior": interior,
		&"interior_down": interior_down,
	}


## Distinct lit blobs (4-connected) and their area, so a particle count is a count rather
## than an area that two overlapping streaks could fake.
func _blob(image: Image) -> Dictionary:
	var seen := {}
	var blobs := 0
	var lit := 0
	var peak := 0.0
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			var value := maxf(colour.r, maxf(colour.g, colour.b))
			total += value
			peak = maxf(peak, value)
			if value <= THRESHOLD or seen.has(Vector2i(x, y)):
				continue
			lit += 1
			seen[Vector2i(x, y)] = true
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			while not queue.is_empty():
				var at: Vector2i = queue.pop_back()
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var next := at + offset
					if next.x < 0 or next.y < 0 or next.x >= image.get_width() or next.y >= image.get_height():
						continue
					if seen.has(next):
						continue
					var neighbour := image.get_pixel(next.x, next.y)
					if maxf(neighbour.r, maxf(neighbour.g, neighbour.b)) <= THRESHOLD:
						continue
					seen[next] = true
					queue.append(next)
			blobs += 1
	return {
		&"blobs": blobs,
		&"lit": lit,
		&"peak": peak,
		&"mean": total / float(image.get_width() * image.get_height()),
	}

## The brightest pixel in the frame (the background's own level, for a diff's context).
func _max(image: Image) -> float:
	var peak := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			peak = maxf(peak, maxf(colour.r, maxf(colour.g, colour.b)))
	return peak
