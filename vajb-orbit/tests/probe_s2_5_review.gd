extends Node2D
## S2's review probe for slice 2.5 (2026-09-21). Independent re-measure of every number
## S1 published: nothing here calls S1's statics to obtain an expectation - the spec's own
## arithmetic is written out inline, and everything else is read off the shipped seams
## through real frames rather than by hand-driving private update methods.
##
## Run:
##   ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_review.tscn \
##     --fixed-fps 60 --quit-after 3600

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const MiningLaserScene := preload("res://game/mining_laser.tscn")

const TAG := "[S2R]"
const HULL: StringName = &"ship_vanguard"
const BOOSTER: StringName = &"b_afterburner"
const THRUST: StringName = &"thrust_forward"
const BOOST_ACTION: StringName = &"boost"

const THRUSTER_CUE: StringName = &"sfx_ship_engine_01"
const SHIELD_BED: StringName = &"sfx_impact_shield_loop"
const BEAM_BED: StringName = &"sfx_mining_beam"
const BOOST_CUE: StringName = &"sfx_ship_boost_01"

## The spec's own numbers, quoted from FX_SPEC section 5 / section 1.3 / section 1.8 and
## AUDIO_SPEC section 4.5 so every expectation below is independent of the shipped code.
const SPEC_ONSET := 0.70
const SPEC_STRENGTH_MIN := 0.1
const SPEC_STRENGTH_MAX := 0.8
const SPEC_PULLBACK_MIN := 0.82
const SPEC_VIGNETTE_MIN := 0.6
const SPEC_VIGNETTE_MAX := 1.0
const SPEC_VIGNETTE_PERIOD := 1.2
const SPEC_THRUSTER_ON := 0.15
const SPEC_THRUSTER_OFF := 0.10
const SPEC_THRUSTER_PITCH_MIN := 0.85
const SPEC_THRUSTER_PITCH_MAX := 1.15
const SPEC_THRUSTER_VOL_MIN := -24.0
const SPEC_THRUSTER_VOL_MAX := -12.0
const SPEC_TRAIL_RATE_MIN := 20.0
const SPEC_TRAIL_RATE_MAX := 60.0
const SPEC_TRAIL_LENGTH_MIN := 24.0
const SPEC_TRAIL_LENGTH_MAX := 56.0
const SPEC_TRAIL_WIDTH := 6.0
const SPEC_TRAIL_ALPHA_MIN := 0.35
const SPEC_TRAIL_ALPHA_MAX := 0.85
const SPEC_TRAIL_RATIO_MIN := 0.15

var _staged: Array[Node] = []
var _pressed: Array[StringName] = []
var _voice_frames := 0


func _ready() -> void:
	print("%s HEAD probe=s2_review" % TAG)
	_case_blur()
	_case_dust_plate()
	await _case_zoom_matrix()
	await _case_zoom_live()
	_case_dust_emitter()
	await _case_vignette_live()
	await _case_arcs_live()
	await _case_trail_live()
	_case_bed_curve()
	_case_bed_scope()
	await _case_bed_voice_liveness()
	_case_beam_bed_interaction()
	await _case_bed_shipped_live()
	await _case_death_state()
	await _case_trail_seam()
	await _case_boost_live()
	for action: StringName in _pressed:
		Input.action_release(action)
	print("%s done" % TAG)
	get_tree().quit()


## --- Fixtures -----------------------------------------------------------------


func _ship(fraction: float, with_booster: bool) -> Variant:
	var fit: Dictionary = ShipFitScript.STANDARD_FIT.duplicate(true)
	if with_booster:
		fit[&"boosters"] = [BOOSTER]
	var stats: Variant = ShipFitScript.resolve(HULL, fit)
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.setup()
	state.hull = stats.hull_max * fraction
	var holder := Node2D.new()
	holder.name = &"S2World%d" % _staged.size()
	add_child(holder)
	_staged.append(holder)
	var ship: Variant = PlayerShipScene.instantiate()
	holder.add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return ship


func _audio() -> Node:
	return get_tree().root.get_node_or_null(NodePath(&"AudioManager"))


func _fx_nodes(root: Node, sheet: String) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in root.get_children():
		if _draws_from(child, sheet):
			out.append(child)
		out.append_array(_fx_nodes(child, sheet))
	return out


func _draws_from(node: Node, sheet: String) -> bool:
	if node is AnimatedSprite2D:
		var frames := (node as AnimatedSprite2D).sprite_frames
		if frames == null or frames.get_frame_count(&"default") == 0:
			return false
		return _source_path(frames.get_frame_texture(&"default", 0)) == sheet
	if node is Sprite2D:
		return _source_path((node as Sprite2D).texture) == sheet
	return false


func _source_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	if texture is AtlasTexture:
		var atlas := (texture as AtlasTexture).atlas
		return atlas.resource_path if atlas != null else ""
	return texture.resource_path


func _names(values: Array) -> String:
	var out: PackedStringArray = []
	for value: Variant in values:
		out.append(String(value))
	return ", ".join(out)


## --- 1. The blur (FX_SPEC section 5 row 1) -----------------------------------


func _case_blur() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	var screen: Variant = SpeedFantasyScript.new()
	add_child(screen)
	screen.call(&"bind_camera", camera)
	var rect := screen.call(&"blur_rect") as ColorRect
	var material := rect.material as ShaderMaterial
	for ratio: float in [0.0, 0.5, 0.69, 0.70, 0.7001, 0.71, 0.85, 0.9, 1.0]:
		screen.call(&"set_wheel_zoom", 1.0)
		screen.call(&"set_ratio", ratio, Vector2(0.6, -0.8))
		## The spec's own arithmetic, re-derived here: 0 at/below the onset, then
		## lerp(0.1, 0.8, (r - 0.7) / 0.3).
		var expected := 0.0
		if ratio > SPEC_ONSET:
			expected = lerpf(
				SPEC_STRENGTH_MIN,
				SPEC_STRENGTH_MAX,
				clampf((ratio - SPEC_ONSET) / (1.0 - SPEC_ONSET), 0.0, 1.0)
			)
		var got := float(material.get_shader_parameter(&"blur_strength"))
		var direction := material.get_shader_parameter(&"blur_direction") as Vector2
		print(
			(
				"%s BLUR ratio=%.4f strength=%.6f spec=%.6f match=%s visible=%s "
				+ "chromatic=%.6f dir=(%.4f,%.4f) dir_spec=(%.4f,%.4f) layer=%d "
				+ "rect_size=%s viewport=%s"
			)
			% [
				TAG,
				ratio,
				got,
				expected,
				str(absf(got - expected) < 1e-6),
				str(rect.visible),
				float(material.get_shader_parameter(&"chromatic_aberration")),
				direction.x,
				direction.y,
				Vector2(0.6, -0.8).normalized().x,
				Vector2(0.6, -0.8).normalized().y,
				int((screen.call(&"layer") as CanvasLayer).layer),
				str(rect.size),
				str(get_viewport().get_visible_rect().size),
			]
		)


## --- 2. The camera pull-back (FX_SPEC section 5 row 2) -----------------------


func _case_zoom_matrix() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	var screen: Variant = SpeedFantasyScript.new()
	add_child(screen)
	screen.call(&"bind_camera", camera)
	for wheel: float in [0.70, 1.0, 1.30, 1.50]:
		for ratio: float in [0.0, 0.5, 0.70, 0.85, 1.0]:
			screen.call(&"set_wheel_zoom", wheel)
			screen.call(&"set_ratio", ratio, Vector2(1.0, 0.0))
			var expected_pull := 1.0
			if ratio > SPEC_ONSET:
				expected_pull = lerpf(
					1.0, SPEC_PULLBACK_MIN, clampf((ratio - SPEC_ONSET) / 0.3, 0.0, 1.0)
				)
			var applied := float(screen.call(&"applied_zoom"))
			print(
				(
					"%s ZOOM wheel=%.2f ratio=%.2f pullback=%.6f spec_pull=%.6f applied=%.6f "
					+ "spec_applied=%.6f camera=%.6f wheel_readback=%.4f delta=%.9f match=%s"
				)
				% [
					TAG,
					wheel,
					ratio,
					float(screen.call(&"pullback")),
					expected_pull,
					applied,
					wheel * expected_pull,
					camera.zoom.x,
					float(screen.call(&"wheel_zoom")),
					absf(camera.zoom.x - wheel * expected_pull),
					str(
						absf(applied - wheel * expected_pull) < 1e-6
						and absf(camera.zoom.x - wheel * expected_pull) < 1e-6
					),
				]
			)
	await get_tree().process_frame


## The wheel keeps its own target: clamp, the 0.18 s tween, a mid-tween sample proving the
## tween is live, and the camera carrying target x pull-back at the settled end.
func _case_zoom_live() -> void:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		print("%s ZOOM_LIVE scene=missing" % TAG)
		return
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	_staged.append(scene)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var fantasy = scene.get_node_or_null(NodePath(&"SpeedFantasy"))
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var stats: Variant = scene.get(&"_stats")
	if fantasy == null or ship == null or stats == null:
		print("%s ZOOM_LIVE wiring=missing" % TAG)
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	var fast := Vector2(0.95, 0.0) * float(stats.max_speed)
	## The wheel beyond its top clamp: 2.0 must read back as 1.50.
	scene.call(&"_set_camera_zoom", 2.0)
	print(
		"%s ZOOM_LIVE set=2.0 clamped=%.4f shown_at_once=%.4f tween=%s"
		% [
			TAG,
			float(scene.get(&"_camera_zoom")),
			float(scene.get(&"_camera_zoom_shown")),
			str(scene.get(&"_camera_zoom_tween") != null),
		]
	)
	## A mid-tween sample: 3 frames into a 0.18 s tween the shown value must be strictly
	## between where it started (1.0) and the target (1.5).
	for i in 3:
		await get_tree().process_frame
	var mid := float(scene.get(&"_camera_zoom_shown"))
	print(
		"%s ZOOM_LIVE mid_tween shown=%.6f strictly_between=%s"
		% [TAG, mid, str(mid > 1.0 and mid < 1.5)]
	)
	for i in 24:
		body.linear_velocity = fast
		await get_tree().physics_frame
	var wheel_target := float(scene.get(&"_camera_zoom"))
	var wheel_shown := float(scene.get(&"_camera_zoom_shown"))
	var pushed := float(fantasy.call(&"wheel_zoom"))
	var ratio := float(fantasy.call(&"ratio"))
	var pull := 1.0
	if ratio > SPEC_ONSET:
		pull = lerpf(1.0, SPEC_PULLBACK_MIN, clampf((ratio - SPEC_ONSET) / 0.3, 0.0, 1.0))
	var camera := scene.get(&"_camera") as Camera2D
	print(
		(
			"%s ZOOM_LIVE settled wheel_target=%.6f wheel_shown=%.6f pushed_to_stack=%.6f "
			+ "ratio=%.4f pullback=%.6f camera=%.6f spec_applied=%.6f composes=%s "
			+ "wheel_untouched_by_pullback=%s"
		)
		% [
			TAG,
			wheel_target,
			wheel_shown,
			pushed,
			ratio,
			pull,
			camera.zoom.x,
			wheel_shown * pull,
			str(absf(camera.zoom.x - wheel_shown * pull) < 1e-5),
			str(absf(wheel_target - wheel_shown) < 1e-5),
		]
	)
	scene.call(&"_set_camera_zoom", 0.10)
	for i in 24:
		body.linear_velocity = fast
		await get_tree().physics_frame
	print(
		"%s ZOOM_LIVE set=0.10 clamped=%.4f shown=%.6f camera=%.6f ratio=%.4f"
		% [
			TAG,
			float(scene.get(&"_camera_zoom")),
			float(scene.get(&"_camera_zoom_shown")),
			(scene.get(&"_camera") as Camera2D).zoom.x,
			float(fantasy.call(&"ratio")),
		]
	)
	## The pull-back never lands in the wheel's target: sweep the ratio with the wheel fixed.
	var before := float(scene.get(&"_camera_zoom"))
	for i in 10:
		body.linear_velocity = Vector2.ZERO
		await get_tree().physics_frame
		body.linear_velocity = fast
		await get_tree().physics_frame
	print(
		"%s ZOOM_LIVE pullback_writeback before=%.6f after=%.6f unchanged=%s"
		% [
			TAG,
			before,
			float(scene.get(&"_camera_zoom")),
			str(absf(before - float(scene.get(&"_camera_zoom"))) < 1e-9),
		]
	)


## --- 3. The dust (FX_SPEC section 5 row 3) ----------------------------------


## The drawn quad the emitter asks for: the draw pass's own `quad_scale` times the frame
## it draws (S3's fix; the node's `scale` is inert, S2's report section 2.2).
func _drawn_quad(node: CanvasItem, source: Vector2, length: float, width: float) -> Vector2:
	var material := node.material as ShaderMaterial
	if material == null:
		return node.scale * source
	var quad := material.get_shader_parameter(&"quad_scale") as Vector2
	return quad * source


## The shipped plate's own facts, read off the file.
func _case_dust_plate() -> void:
	var path := String(ProjectileScript.feedback_row(&"dust")[&"frames"][0])
	var texture := load(path) as Texture2D
	if texture == null:
		print("%s DUST_PLATE missing=%s" % [TAG, path])
		return
	var image := texture.get_image()
	var region := ProjectileScript.feedback_row(&"dust")[&"region"] as Rect2
	var inside := image.get_region(Rect2i(region))
	var min_value := 1.0
	var max_value := 0.0
	var min_colour := Color.BLACK
	var max_colour := Color.WHITE
	for y in inside.get_height():
		for x in inside.get_width():
			var colour := inside.get_pixel(x, y)
			var value := maxf(colour.r, maxf(colour.g, colour.b))
			if value < min_value:
				min_value = value
				min_colour = colour
			if value > max_value:
				max_value = value
				max_colour = colour
	print(
		(
			"%s DUST_PLATE size=%s region=%s region_inside=%s alpha_mode=%d "
			+ "min=%.4f min_rgb=(%d,%d,%d) max=%.4f max_rgb=(%d,%d,%d)"
		)
		% [
			TAG,
			str(image.get_size()),
			str(region),
			str(inside.get_size()),
			int(image.detect_alpha()),
			min_value,
			int(min_colour.r * 255.0),
			int(min_colour.g * 255.0),
			int(min_colour.b * 255.0),
			max_value,
			int(max_colour.r * 255.0),
			int(max_colour.g * 255.0),
			int(max_colour.b * 255.0),
		]
	)


func _case_dust_emitter() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	var screen: Variant = SpeedFantasyScript.new()
	add_child(screen)
	screen.call(&"bind_camera", camera)
	var dust := screen.call(&"dust") as GPUParticles2D
	if dust == null:
		print("%s DUST emitter=missing" % TAG)
		return
	var process := dust.process_material as ParticleProcessMaterial
	print(
		(
			"%s DUST_EMITTER parent=%s parent_is_camera=%s sheet=%s node_material=%s "
			+ "local_coords=%s lifetime=%.4f amount=%d color_a=%.4f scale_min=%.6f "
			+ "visibility_rect=%s"
		)
		% [
			TAG,
			dust.get_parent().name,
			str(dust.get_parent() == camera),
			_source_path(dust.texture),
			str(dust.material),
			str(dust.local_coords),
			dust.lifetime,
			dust.amount,
			process.color.a,
			process.scale_min,
			str(dust.visibility_rect),
		]
	)
	for ratio: float in [0.0, 0.5, 0.69, 0.70, 0.71, 1.0]:
		screen.call(&"set_ratio", ratio, Vector2(1.0, 0.0))
		print(
			(
				"%s DUST ratio=%.2f emitting=%s visible=%s spec_on=%s amount_ratio=%.6f "
				+ "expected_count=%.2f"
			)
			% [
				TAG,
				ratio,
				str(dust.emitting),
				str(dust.visible),
				str(ratio >= SPEC_ONSET),
				dust.amount_ratio,
				spec_dust_count(ratio),
			]
		)


## FX_SPEC section 5 row 3: "30/s at ratio 1.0, 0.5 s lifetime" - the count is the rate over
## the lifetime, and the row gives no ramp, so it is all-or-nothing at the onset.
func spec_dust_count(ratio: float) -> float:
	if ratio < SPEC_ONSET:
		return 0.0
	return 30.0 * 0.5


## --- 4. The vignette (FX_SPEC section 6 row 1 / section 1.8) -----------------


func _case_vignette_live() -> void:
	var path := "res://assets/fx/fx_hull_critical_vignette.png"
	var texture := load(path) as Texture2D
	if texture != null:
		var image := texture.get_image()
		var centre := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
		var corner := image.get_pixel(4, 4)
		var min_value := 1.0
		var edge := 0.0
		for y in range(0, image.get_height(), 4):
			for x in range(0, image.get_width(), 4):
				var colour := image.get_pixel(x, y)
				var value := maxf(colour.r, maxf(colour.g, colour.b))
				min_value = minf(min_value, value)
				if x < 8 or y < 8 or x >= image.get_width() - 8 or y >= image.get_height() - 8:
					edge = maxf(edge, value)
		print(
			(
				"%s VIGNETTE_PLATE alpha_mode=%d centre=(%d,%d,%d) corner=(%d,%d,%d) "
				+ "min=%.4f edge_max=%.4f"
			)
			% [
				TAG,
				int(image.detect_alpha()),
				int(centre.r * 255.0),
				int(centre.g * 255.0),
				int(centre.b * 255.0),
				int(corner.r * 255.0),
				int(corner.g * 255.0),
				int(corner.b * 255.0),
				min_value,
				edge,
			]
		)
	var camera := Camera2D.new()
	add_child(camera)
	var screen: Variant = SpeedFantasyScript.new()
	add_child(screen)
	screen.call(&"bind_camera", camera)
	## Threshold edges: 0.25 is not below the 25 % line, so it must be inactive.
	for fraction: float in [0.30, 0.2501, 0.25, 0.2499, 0.20]:
		screen.call(&"set_hull_fraction", fraction)
		print(
			"%s VIGNETTE hull=%.4f active=%s visible=%s modulate_a=%.6f"
			% [
				TAG,
				fraction,
				str(bool(screen.call(&"vignette_active"))),
				str((screen.call(&"vignette_rect") as TextureRect).visible),
				(screen.call(&"vignette_rect") as TextureRect).modulate.a,
			]
		)
	## The pulse, on the engine's own process frames, sampled every frame for 1.5 s.
	screen.call(&"set_hull_fraction", 0.30)
	screen.call(&"set_hull_fraction", 0.20)
	var clock := 0.0
	var worst := 0.0
	var low := 2.0
	var high := -1.0
	var low_clock := 0.0
	var high_clock := 0.0
	var step := get_process_delta_time()
	for i in 90:
		await get_tree().process_frame
		clock += step
		var expected := SPEC_VIGNETTE_MIN + (SPEC_VIGNETTE_MAX - SPEC_VIGNETTE_MIN) * (
			0.5 + 0.5 * sin(TAU * clock / SPEC_VIGNETTE_PERIOD)
		)
		var got := (screen.call(&"vignette_rect") as TextureRect).modulate.a
		worst = maxf(worst, absf(got - expected))
		if got < low:
			low = got
			low_clock = clock
		if got > high:
			high = got
			high_clock = clock
	print(
		"%s VIGNETTE_LIVE frames=90 step=%.6f clock=%.4f low=%.4f high=%.4f worst_sine_gap=%.4f"
		% [TAG, step, clock, low, high, worst]
	)
	print(
		"%s VIGNETTE_LIVE half_period=%.4f spec_half_period=%.4f (the peaks' own spacing)"
		% [TAG, high_clock - low_clock, SPEC_VIGNETTE_PERIOD * 0.5]
	)
	screen.call(&"set_hull_fraction", 0.30)
	await get_tree().process_frame
	print(
		"%s VIGNETTE_LIVE above_the_line visible=%s modulate_a=%.6f"
		% [
			TAG,
			str((screen.call(&"vignette_rect") as TextureRect).visible),
			(screen.call(&"vignette_rect") as TextureRect).modulate.a,
		]
	)


## --- 5. The low-hull arcs (FX_SPEC section 6 row 3) --------------------------


func _case_arcs_live() -> void:
	var ship: Variant = _ship(0.20, false)
	var holder := ship.get_parent() as Node2D
	var start := int(ship.call(&"arc_count"))
	var frame_start := get_tree().get_frame()
	var most_nodes := 0
	var frames_that_drew := 0
	for i in 360:
		await get_tree().physics_frame
		var drawn := _fx_nodes(holder, "res://assets/fx/fx_arc_spark_f1.png").size()
		if drawn > 0:
			frames_that_drew += 1
		most_nodes = maxi(most_nodes, drawn)
	var arcs := int(ship.call(&"arc_count")) - start
	var nodes := _fx_nodes(holder, "res://assets/fx/fx_arc_spark_f1.png")
	var interval := float(ship.call(&"arc_interval"))
	print(
		(
			"%s ARCS_LIVE hull=0.20 frames=%d seconds=6.0 count=%d nodes_now=%d "
			+ "most_nodes_at_once=%d frames_that_drew=%d next_interval=%.6f"
		)
		% [
			TAG,
			get_tree().get_frame() - frame_start,
			arcs,
			nodes.size(),
			most_nodes,
			frames_that_drew,
			interval,
		]
	)
	var healthy: Variant = _ship(0.80, false)
	var healthy_start := int(healthy.call(&"arc_count"))
	for i in 360:
		await get_tree().physics_frame
	print(
		"%s ARCS_LIVE hull=0.80 seconds=6.0 count=%d"
		% [TAG, int(healthy.call(&"arc_count")) - healthy_start]
	)


## --- 6. The thruster trail (FX_SPEC section 1.3's amendment) -----------------


func _case_trail_live() -> void:
	var ship: Variant = _ship(1.0, false)
	var holder := ship.get_parent() as Node2D
	var row := ProjectileScript.feedback_row(&"trail")
	var source := row[&"source"] as Vector2
	var anchors: Array = ship.call(&"thruster_anchors")
	print(
		"%s TRAIL anchors=%d first=(%.4f,%.4f) radius=%.4f sheet=%s"
		% [
			TAG,
			anchors.size(),
			(anchors[0] as Vector2).x,
			(anchors[0] as Vector2).y,
			float(ship.call(&"_hull_radius")),
			String(row[&"frames"][0]),
		]
	)
	for ratio: float in [0.15, 1.0]:
		ship.call(&"set_speed_ratio", ratio)
		Input.action_press(THRUST)
		for i in 3:
			await get_tree().physics_frame
		var trails: Array = ship.call(&"thruster_trails")
		var trail := trails[0] as GPUParticles2D
		var process := trail.process_material as ParticleProcessMaterial
		var ramp := clampf((ratio - SPEC_TRAIL_RATIO_MIN) / (1.0 - SPEC_TRAIL_RATIO_MIN), 0.0, 1.0)
		var length := lerpf(SPEC_TRAIL_LENGTH_MIN, SPEC_TRAIL_LENGTH_MAX, ramp)
		print(
			(
				"%s TRAIL ratio=%.2f emitters=%d amount=%d amount_ratio=%.6f spec_amount_ratio=%.6f "
				+ "scale=(%.8f,%.8f) spec_scale=(%.8f,%.8f) alpha=%.4f spec_alpha=%.4f "
				+ "emitting=%s lifetime=%.4f local_coords=%s material=%s pos=(%.4f,%.4f) "
				+ "spec_pos=(%.4f,%.4f) in_tree=%s"
			)
			% [
				TAG,
				ratio,
				trails.size(),
				trail.amount,
				trail.amount_ratio,
				lerpf(SPEC_TRAIL_RATE_MIN, SPEC_TRAIL_RATE_MAX, ramp) / SPEC_TRAIL_RATE_MAX,
				trail.scale.x,
				trail.scale.y,
				_drawn_quad(trail, source, length, SPEC_TRAIL_WIDTH).x,
				_drawn_quad(trail, source, length, SPEC_TRAIL_WIDTH).y,
				process.color.a,
				lerpf(SPEC_TRAIL_ALPHA_MIN, SPEC_TRAIL_ALPHA_MAX, ramp),
				str(trail.emitting),
				trail.lifetime,
				str(trail.local_coords),
				(
					"quad_pass"
					if trail.material is ShaderMaterial
					else ("additive" if trail.material is CanvasItemMaterial else "none")
				),
				trail.position.x,
				trail.position.y,
				(anchors[0] as Vector2).x - length * 0.5,
				0.0,
				str(trail.is_inside_tree()),
			]
		)
	## The active rule through real frames, on the input action rather than a hand call.
	for row_case: Array in [
		[0.0, false, "at_rest_no_stick"],
		[0.0, true, "at_rest_stick_down"],
		[0.15, false, "the_floor_drifting"],
		[0.50, false, "drifting"],
	]:
		ship.call(&"set_speed_ratio", row_case[0])
		if bool(row_case[1]):
			Input.action_press(THRUST)
		else:
			Input.action_release(THRUST)
		for i in 3:
			await get_tree().physics_frame
		var trail := (ship.call(&"thruster_trails") as Array)[0] as GPUParticles2D
		print(
			"%s TRAIL case=%s ratio=%.2f thrusting=%s emitting=%s visible=%s"
			% [
				TAG,
				String(row_case[2]),
				row_case[0],
				str(bool(row_case[1])),
				str(trail.emitting),
				str(trail.visible),
			]
		)
	Input.action_release(THRUST)
	print(
		"%s TRAIL sheet_nodes=%d"
		% [TAG, _fx_nodes(holder, String(row[&"frames"][0])).size()]
	)


## --- 7. The thruster bed (AUDIO_SPEC section 4.5) ----------------------------


func _case_bed_curve() -> void:
	var audio := _audio()
	if audio == null:
		print("%s BED audio=missing" % TAG)
		return
	audio.call(&"stop_thruster_bed")
	for ratio: float in [0.0, 0.15, 0.5, 0.9, 1.0]:
		var held := bool(audio.call(&"hold_thruster_bed", ratio, false))
		var state := audio.call(&"bed_state", THRUSTER_CUE) as Dictionary
		var ramp := 0.0
		if ratio > SPEC_THRUSTER_ON:
			ramp = clampf((ratio - SPEC_THRUSTER_ON) / (1.0 - SPEC_THRUSTER_ON), 0.0, 1.0)
		print(
			(
				"%s BED ratio=%.2f held=%s sounding=%s pitch=%.6f spec_pitch=%.6f "
				+ "volume_db=%.6f spec_volume=%.6f"
			)
			% [
				TAG,
				ratio,
				str(held),
				str(bool(state[&"sounding"])),
				float(state[&"pitch_scale"]),
				lerpf(SPEC_THRUSTER_PITCH_MIN, SPEC_THRUSTER_PITCH_MAX, ramp),
				float(state[&"volume_db"]),
				lerpf(SPEC_THRUSTER_VOL_MIN, SPEC_THRUSTER_VOL_MAX, ramp),
			]
		)
	## The hysteresis: on at 0.15, off below 0.10, re-armed at 0.15.
	audio.call(&"stop_thruster_bed")
	for row: Array in [
		[0.12, "below_on"],
		[0.15, "at_on"],
		[0.12, "latched_above_off"],
		[0.10, "at_off"],
		[0.095, "just_below_off"],
		[0.15, "re_armed"],
		[0.095, "re_latched_holding"],
	]:
		var held := bool(audio.call(&"hold_thruster_bed", row[0], false))
		print(
			"%s BED_HYST %s ratio=%.3f held=%s sounding=%s"
			% [
				TAG,
				String(row[1]),
				row[0],
				str(held),
				str((audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE)),
			]
		)
	audio.call(&"stop_thruster_bed")
	print(
		"%s BED thrust_only held_at_ratio_zero=%s"
		% [TAG, str(bool(audio.call(&"hold_thruster_bed", 0.0, true)))]
	)
	audio.call(&"stop_thruster_bed")
	print(
		"%s BED priority=%d cue=%s path=%s"
		% [
			TAG,
			int(AudioScript.LOOP_PRIORITY[THRUSTER_CUE]),
			THRUSTER_CUE,
			audio.call(&"cue_path", THRUSTER_CUE),
		]
	)


## The thruster's stop can only ever name its own bed; three beds sound at once.
func _case_bed_scope() -> void:
	var audio := _audio()
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)
	audio.call(&"stop_thruster_bed")
	audio.call(&"play_loop", SHIELD_BED)
	audio.call(&"play_loop", BEAM_BED)
	audio.call(&"hold_thruster_bed", 0.5, true)
	var beds := audio.call(&"sounding_loops") as Array
	print("%s BED_SCOPE sounding_at_once=%d beds=[%s]" % [TAG, beds.size(), _names(beds)])
	audio.call(&"stop_thruster_bed")
	var left := audio.call(&"sounding_loops") as Array
	print(
		"%s BED_SCOPE after_thruster_stop=%d beds=[%s] shield_kept=%s beam_kept=%s"
		% [
			TAG,
			left.size(),
			_names(left),
			str(left.has(SHIELD_BED)),
			str(left.has(BEAM_BED)),
		]
	)
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)


## Whether the bed's voice is actually playing a stream: the manager reports a bed as
## sounding from its cue table alone, so the voice is the only witness.
func _case_bed_voice_liveness() -> void:
	var audio := _audio()
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)
	audio.call(&"stop_thruster_bed")
	await get_tree().process_frame
	var players: Array = audio.get(&"_loop_players")
	var voices: Array = audio.get(&"_loop_cues")
	print("%s BED_VOICE start cues=[%s] players=%d" % [TAG, _names(voices), players.size()])
	## NOTE: the pre-wave control (a plain `play_loop`) lives in `probe_s2_5_voice.tscn`
	## arm A, because this probe's own staged hulls carry weapon components whose beam bed
	## shares the `sfx_mining_beam` cue and stops it. The thruster bed is read here.
	## The thruster bed: asked for once, then re-asked on the following frames as the ship
	## does every physics frame.
	audio.call(&"hold_thruster_bed", 0.5, true)
	print(
		"%s BED_VOICE asked cues=[%s] index=%d"
		% [
			TAG,
			_names(audio.get(&"_loop_cues") as Array),
			find_voice(audio.get(&"_loop_cues") as Array, THRUSTER_CUE),
		]
	)
	for frame: int in [1, 2, 3, 10, 30]:
		while _voice_frames < frame:
			_voice_frames += 1
			await get_tree().process_frame
		var index := find_voice(audio.get(&"_loop_cues") as Array, THRUSTER_CUE)
		if index < 0:
			print("%s BED_VOICE frame=%d cue=gone" % [TAG, frame])
			continue
		audio.call(&"hold_thruster_bed", 0.5, true)
		var player := players[index] as AudioStreamPlayer
		print(
			"%s BED_VOICE frame=%d index=%d playing=%s stream=%s volume_db=%.4f pitch=%.4f"
			% [
				TAG,
				frame,
				index,
				str(player.playing),
				_stream_path(player),
				player.volume_db,
				player.pitch_scale,
			]
		)
	var sounding := audio.call(&"sounding_loops") as Array
	print(
		"%s BED_VOICE sounding_reported=%s beds=[%s]"
		% [TAG, str(sounding.has(THRUSTER_CUE)), _names(sounding)]
	)
	audio.call(&"stop_thruster_bed")


func find_voice(cues: Array, cue: StringName) -> int:
	for index in cues.size():
		if StringName(cues[index]) == cue:
			return index
	return -1


func _stream_path(player: AudioStreamPlayer) -> String:
	if player == null or player.stream == null:
		return "<none>"
	return player.stream.resource_path


## The end-to-end reproduction: the shipped `game.tscn`, flown at speed with the throttle
## held, read off the manager's own voice for the thruster's cue.
func _case_bed_shipped_live() -> void:
	var audio := _audio()
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		print("%s BED_SHIPPED scene=missing" % TAG)
		return
	audio.call(&"stop_thruster_bed")
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	_staged.append(scene)
	await get_tree().physics_frame
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var stats: Variant = scene.get(&"_stats")
	if ship == null or stats == null:
		print("%s BED_SHIPPED wiring=missing" % TAG)
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	Input.action_press(THRUST)
	_pressed.append(THRUST)
	for i in 40:
		if body != null:
			body.linear_velocity = Vector2(0.95, 0.0) * float(stats.max_speed)
		await get_tree().physics_frame
	for i in 30:
		await get_tree().process_frame
	var cues: Array = audio.get(&"_loop_cues")
	var players: Array = audio.get(&"_loop_players")
	var index := find_voice(cues, THRUSTER_CUE)
	var state: Dictionary = audio.call(&"bed_state", THRUSTER_CUE)
	var line := "%s BED_SHIPPED cue_index=%d reported_sounding=%s pitch=%.4f volume_db=%.4f" % [
		TAG,
		index,
		str(bool(state[&"sounding"])),
		float(state[&"pitch_scale"]),
		float(state[&"volume_db"]),
	]
	if index >= 0:
		var player := players[index] as AudioStreamPlayer
		line += " playing=%s stream=%s matching_stream=%s" % [
			str(player.playing),
			_stream_path(player),
			str(player.stream != null and player.stream.resource_path.ends_with(str(THRUSTER_CUE) + ".ogg")),
		]
	print(line)
	Input.action_release(THRUST)
	audio.call(&"stop_thruster_bed")


## The anchor seam: one emitter per point handed in, and the extras dropped. Measured on a
## bare holder, because a live hull re-syncs to its own one-point anchor list every frame.
func _case_trail_seam() -> void:
	var holder := Node2D.new()
	holder.name = &"SeamWorld"
	add_child(holder)
	_staged.append(holder)
	var three: Array[Vector2] = [Vector2(-10.0, -5.0), Vector2(-10.0, 0.0), Vector2(-10.0, 5.0)]
	var got := ProjectileScript.sync_thruster_trails(holder, three, 1.0, true)
	var drawn := 0
	for child: Node in holder.get_children():
		if child is GPUParticles2D and String(child.name).begins_with("ThrusterTrail"):
			drawn += 1
	var one: Array[Vector2] = [Vector2(-10.0, 0.0)]
	ProjectileScript.sync_thruster_trails(holder, one, 1.0, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var after_shrink := 0
	for child: Node in holder.get_children():
		if child is GPUParticles2D and String(child.name).begins_with("ThrusterTrail"):
			after_shrink += 1
	ProjectileScript.clear_thruster_trails(holder)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var after_clear := 0
	for child: Node in holder.get_children():
		if child is GPUParticles2D and String(child.name).begins_with("ThrusterTrail"):
			after_clear += 1
	print(
		"%s TRAIL_SEAM three_anchors_returned=%d three_anchors_drawn=%d after_shrink=%d after_clear=%d"
		% [TAG, got.size(), drawn, after_shrink, after_clear]
	)


## --- The other holders of the manager's voices --------------------------------


## `mining_laser.gd` stops its bed through `current_loop()`, which names only the
## foreground bed - the route `weapons.gd` already replaced with `stop_bed`. Measured with
## and without the thruster bed up, so the wave's own contribution is separated from the
## pre-existing fragility.
func _case_beam_bed_interaction() -> void:
	var audio := _audio()
	var laser: Variant = (MiningLaserScene.instantiate() as Node)
	add_child(laser)
	_staged.append(laser)
	for with_thruster: bool in [false, true]:
		audio.call(&"stop_bed", SHIELD_BED)
		audio.call(&"stop_bed", BEAM_BED)
		audio.call(&"stop_thruster_bed")
		audio.call(&"play_loop", SHIELD_BED)
		laser.call(&"_play_beam_loop")
		if with_thruster:
			audio.call(&"hold_thruster_bed", 0.5, true)
		var foreground := StringName(audio.call(&"current_loop"))
		laser.call(&"_stop_beam_loop")
		var left := audio.call(&"sounding_loops") as Array
		print(
			(
				"%s BEAM_BED with_thruster=%s foreground=%s beam_still_sounding_after_stop=%s "
				+ "beds=[%s]"
			)
			% [TAG, str(with_thruster), foreground, str(left.has(BEAM_BED)), _names(left)]
		)
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)
	audio.call(&"stop_thruster_bed")


## --- 8/9. The boost cue and the dash charge ----------------------------------


func _case_boost_live() -> void:
	var ship: Variant = _ship(1.0, true)
	var holder := ship.get_parent() as Node2D
	var audio := _audio()
	audio.call(&"stop_thruster_bed")
	var charge_sheet := String(ProjectileScript.feedback_row(&"dash_charge")[&"frames"][0])
	Input.action_press(BOOST_ACTION)
	_pressed.append(BOOST_ACTION)
	for i in 2:
		await get_tree().physics_frame
	print(
		"%s BOOST activations=%d cue=%s last_sfx=%s charges=%d"
		% [
			TAG,
			int(ship.call(&"boost_activations")),
			BOOST_CUE,
			StringName(audio.call(&"last_sfx")),
			_fx_nodes(holder, charge_sheet).size(),
		]
	)
	var charges := _fx_nodes(holder, charge_sheet)
	if not charges.is_empty():
		var charge := charges[0] as Sprite2D
		var source := ProjectileScript.feedback_row(&"dash_charge")[&"source"] as Vector2
		print(
			"%s BOOST charge_scale=%.8f world_u=%.4f spec_world_u=%.4f on_hull=%s fade_seconds=%.2f"
			% [
				TAG,
				charge.scale.x,
				maxf(source.x, source.y) * charge.scale.x,
				float(ProjectileScript.feedback_row(&"dash_charge")[&"world"]),
				str(absf(charge.global_position.distance_to(ship.global_position)) < 1e-3),
				float(ProjectileScript.feedback_row(&"dash_charge")[&"seconds"]),
			]
		)
	for i in 30:
		await get_tree().physics_frame
	print(
		"%s BOOST after_burn_frames activations=%d charges=%d (the charge fades and frees)"
		% [TAG, int(ship.call(&"boost_activations")), _fx_nodes(holder, charge_sheet).size()]
	)

## What the screen-space stack does when the hull dies: `game.gd` stops pushing (its
## `_physics_process` returns early once `_dead`), so the last frame's blur, dust and
## hull-critical state are whatever they were.
func _case_death_state() -> void:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		print("%s DEATH scene=missing" % TAG)
		return
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	_staged.append(scene)
	await get_tree().physics_frame
	var fantasy = scene.get_node_or_null(NodePath(&"SpeedFantasy"))
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var state: Variant = scene.get(&"_state")
	var stats: Variant = scene.get(&"_stats")
	if fantasy == null or ship == null or state == null:
		print("%s DEATH wiring=missing" % TAG)
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	if body != null:
		body.linear_velocity = Vector2(0.95, 0.0) * float(stats.max_speed)
	for i in 3:
		await get_tree().physics_frame
	## A *real* death: the hull's own handler runs off `hull_changed`, so the trail and the
	## bed are released by the shipped path rather than by a hand call.
	state.damage(state.hull + 1.0, true)
	for i in 6:
		await get_tree().physics_frame
	scene.call(&"_on_ship_died")
	for i in 6:
		await get_tree().physics_frame
	for i in 6:
		await get_tree().process_frame
	var trails_left := 0
	for child: Node in ship.get_children():
		if child is GPUParticles2D and String(child.name).begins_with("ThrusterTrail"):
			trails_left += 1
	print(
		"%s DEATH_RELEASE trail_children=%d thruster_bed_sounding=%s beds=[%s]"
		% [
			TAG,
			trails_left,
			str((_audio().call(&"sounding_loops") as Array).has(THRUSTER_CUE)),
			_names(_audio().call(&"sounding_loops") as Array),
		]
	)
	print(
		(
			"%s DEATH dead=%s ratio=%.4f blur_strength=%.4f blur_visible=%s dust_emitting=%s "
			+ "vignette_active=%s vignette_visible=%s alpha=%.4f trail_emitting=%s"
		)
		% [
			TAG,
			str(body == null or not ship.is_physics_processing()),
			float(fantasy.call(&"ratio")),
			float(fantasy.call(&"blur_strength")),
			str((fantasy.call(&"blur_rect") as ColorRect).visible),
			str((fantasy.call(&"dust") as GPUParticles2D).emitting),
			str(bool(fantasy.call(&"vignette_active"))),
			str((fantasy.call(&"vignette_rect") as TextureRect).visible),
			float(fantasy.call(&"vignette_alpha")),
			str(((ship.call(&"thruster_trails") as Array)).size()),
		]
	)
