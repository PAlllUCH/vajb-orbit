@tool
extends McpTestSuite
## Suite slice2_5_feel: the speed fantasy and damage states of engine slice 2.5 (worker
## S1, 2026-09-21) — the nine deliverables of
## `.agents/gen/slice2_5_feel_wave_task.md` section 1, one test apiece plus the wiring
## that reaches them.
##
## Everything here is synchronous: the gate's runner calls a test method and never steps
## the tree, so the timed behaviour (the vignette's pulse phase, the arcs' 6 s of cadence,
## the wheel's 0.18 s tween) is driven by calling the shipped steps directly
## (`SpeedFantasy._process`, `PlayerShip._update_damage_arcs`, `_update_boosters`) and the
## frame-stepped end-to-end run is the probe's (`tests/probe_s2_5_feel.tscn`).
##
## Contract: docs/design/FX_SPEC.md section 1.3 (its 2026-09-21 amendment — the trail's
## engine numbers), section 5 (blur, pull-back, dust), section 6 (the damage states),
## section 7.1 (the engine-side rows) and section 7.3 (the wiring contract);
## docs/design/AUDIO_SPEC.md section 4.5 (the held beds and the thruster curve);
## docs/gameplay/18_engine_spec.md section 3.4 (owner ruling 18 — `speed_ratio` is the one
## input and none of it is physics). docs/CONTRACTS.md sections 4/7/8.2 pin the interfaces
## this suite reads and never moves.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const FxScript := preload("res://game/fx.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const HULL: StringName = &"ship_vanguard"
const BOOSTER: StringName = &"b_afterburner"

const BLUR_SHADER := "res://game/speed_blur.gdshader"
## The re-cut frames: every effect draws its own per-frame file now, and the rows that read
## one frame of a sequence name that frame (`_f1`).
const VIGNETTE_SHEET := "res://assets/fx/fx_hull_critical_vignette_f1.png"
const TRAIL_SHEET := "res://assets/fx/fx_engine_trail_f1.png"
const DUST_SHEET := "res://assets/fx/fx_dust_streak_f1.png"
const ARC_SHEET := "res://assets/fx/fx_arc_spark_f1.png"
const CHARGE_SHEET := "res://assets/fx/fx_dash_charge_f1.png"

const THRUSTER_CUE: StringName = &"sfx_ship_engine_01"
const SHIELD_BED: StringName = &"sfx_impact_shield_loop"
const BEAM_BED: StringName = &"sfx_mining_beam"
const BOOST_CUE: StringName = &"sfx_ship_boost_01"

const ADD := CanvasItemMaterial.BLEND_MODE_ADD
const MIX := CanvasItemMaterial.BLEND_MODE_MIX
const PHYSICS_STEP := 1.0 / 60.0
const ARC_SECONDS := 6.0
## The tolerance every float comparison against a spec value carries: the arithmetic is
## transcendental in places (the sine, the ramps), so exact equality is not the claim.
const TOL := 1e-4

var _scene: Node2D = null
var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func suite_name() -> String:
	return "slice2_5_feel"


func suite_setup(_ctx: Dictionary) -> void:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null or _scene.get_node_or_null(NodePath(&"SpeedFantasy")) == null:
		fail_setup("game.tscn did not build its screen-space speed fantasy")
		return
	_host().add_child(_scene)


func suite_teardown() -> void:
	_clear_loops()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


func setup() -> void:
	_release_pressed()


func teardown() -> void:
	_release_pressed()
	_clear_loops()


## --- Deliverable 1: the directional motion blur (FX_SPEC section 5 row 1) -----


func test_the_blur_is_zero_below_the_onset_and_rises_to_the_dash_strength() -> void:
	assert_true(_near(SpeedFantasyScript.blur_for(0.0), 0.0), "a hull at rest has no blur")
	for quiet: float in [0.1, 0.5, 0.69, 0.70]:
		assert_true(
			_near(SpeedFantasyScript.blur_for(quiet), 0.0),
			"%.2f is below (or at) the 0.70 onset, so the strength is zero" % quiet
		)
	assert_true(
		_near(SpeedFantasyScript.blur_for(0.9), 0.5667, 1e-3),
		"0.9 is two thirds up the band: 0.1 + 0.7 * 2/3"
	)
	assert_true(
		_near(SpeedFantasyScript.blur_for(1.0), 0.8),
		"full speed is section 5's own 0.8"
	)
	var fantasy: Variant = _fantasy()
	var camera := _camera()
	fantasy.call(&"bind_camera", camera)
	fantasy.call(&"set_ratio", 0.9, Vector2(0.0, 300.0))
	var rect := fantasy.call(&"blur_rect") as ColorRect
	assert_true(rect != null, "the blur's ColorRect is built into the scene")
	assert_true(rect.visible, "and it draws above the onset")
	var material := rect.material as ShaderMaterial
	assert_true(material != null, "on the shipped screen-space shader")
	assert_eq(material.shader.resource_path, BLUR_SHADER, "which is `speed_blur.gdshader`")
	assert_true(
		_near(float(material.get_shader_parameter(&"blur_strength")), 0.5667, 1e-3),
		"the uniform carries the strength"
	)
	assert_true(
		_near(float(material.get_shader_parameter(&"chromatic_aberration")), 0.5667, 1e-3),
		"and the channel split rides the same strength (section 5's 'scales with strength')"
	)
	assert_true(
		(material.get_shader_parameter(&"blur_direction") as Vector2).is_equal_approx(
			Vector2.DOWN
		),
		"the smear follows `blur_direction = v / |v|`"
	)
	assert_true(
		float(material.get_shader_parameter(&"blur_span_px")) > 0.0,
		"the shader's own pixel scale is set from this side"
	)
	var layer := fantasy.call(&"layer") as CanvasLayer
	assert_true(layer != null, "on its own CanvasLayer")
	assert_eq(layer.layer, SpeedFantasyScript.SCREEN_LAYER, "at the layer the file pins")
	assert_true(
		SpeedFantasyScript.SCREEN_LAYER > 0 and SpeedFantasyScript.SCREEN_LAYER < 10,
		"above the world (0) and below the HUD (10)"
	)
	fantasy.call(&"set_ratio", 0.5, Vector2.RIGHT * 10.0)
	assert_false(rect.visible, "below the onset the full-screen pass is not drawn at all")


## --- Deliverable 2: the camera pull-back (FX_SPEC section 5 row 2) ------------


func test_the_pull_back_stacks_with_the_wheel_and_never_writes_the_wheel_back() -> void:
	var fantasy: Variant = _fantasy()
	var camera := _camera()
	fantasy.call(&"bind_camera", camera)
	fantasy.call(&"set_wheel_zoom", 1.0)
	fantasy.call(&"set_ratio", 0.5, Vector2.RIGHT)
	assert_true(_near(float(fantasy.call(&"pullback")), 1.0), "below the onset it is 1.0")
	assert_true(_near(float(fantasy.call(&"applied_zoom")), 1.0), "so the wheel applies 1:1")
	assert_true(_near(camera.zoom.x, 1.0), "which is what the camera carries")
	fantasy.call(&"set_ratio", 0.9, Vector2.RIGHT)
	assert_true(
		_near(float(fantasy.call(&"applied_zoom")), 0.88, 1e-3),
		"at 0.9 the wheel's 1.0 applies as 0.88 (lerp(1.0, 0.82, 2/3))"
	)
	assert_true(_near(camera.zoom.x, 0.88, 1e-3), "and the camera carries the applied value")
	fantasy.call(&"set_wheel_zoom", 1.30)
	assert_true(
		_near(float(fantasy.call(&"applied_zoom")), 1.144, 1e-3),
		"the wheel at 1.30 applies 1.144 at the same ratio: the pull-back multiplies it"
	)
	assert_true(
		_near(float(fantasy.call(&"wheel_zoom")), 1.30),
		"the pull-back is never written back into the wheel's own value"
	)
	assert_true(_near(camera.zoom.x, 1.144, 1e-3), "and the camera has exactly one writer")
	fantasy.call(&"set_ratio", 1.0, Vector2.RIGHT)
	assert_true(
		_near(float(fantasy.call(&"applied_zoom")), 1.30 * 0.82, 1e-3),
		"at full speed the wheel is multiplied by section 5's 0.82 end"
	)
	assert_true(
		_near(SpeedFantasyScript.pullback_for(1.0), 0.82),
		"the pull-back's own floor is the spec's 0.82"
	)


func test_the_wheel_still_clamps_and_tweens_and_the_stage_owns_the_camera() -> void:
	if _scene == null:
		assert_true(false, "the game scene is up")
		return
	assert_true(
		_scene.has_method(&"_push_speed_fantasy") and _scene.has_method(&"_bind_speed_fantasy"),
		"the stage pushes the stack and binds it to its own camera"
	)
	_scene.call(&"_set_camera_zoom", 2.0)
	assert_true(
		_near(float(_scene.get(&"_camera_zoom")), 1.50),
		"the wheel still clamps at CAMERA_ZOOM_MAX 1.50"
	)
	var tween := _scene.get(&"_camera_zoom_tween") as Tween
	assert_true(tween != null and tween.is_valid(), "and still owns a live tween")
	assert_true(
		_near(float(_scene.get(&"_camera_zoom_shown")), 1.0, 1e-6),
		"the value the camera reads is the tween's; it has not stepped, so it is still 1.0"
	)
	_scene.call(&"_set_camera_zoom", 0.10)
	assert_true(
		_near(float(_scene.get(&"_camera_zoom")), 0.70),
		"and at CAMERA_ZOOM_MIN 0.70"
	)
	var fantasy = _scene.get_node_or_null(NodePath(&"SpeedFantasy"))
	_scene.call(&"_push_speedometer")
	assert_true(
		_near(float(fantasy.call(&"applied_zoom")), 1.0),
		"a hull at rest applies the shown wheel zoom untouched (no pull-back below onset)"
	)


## --- Deliverable 3: the dust streaks (FX_SPEC section 5 row 3) --------------


func test_the_dust_emits_only_above_the_onset_and_lies_along_the_velocity() -> void:
	var quiet := SpeedFantasyScript.dust_read(0.5)
	assert_false(bool(quiet[&"on"]), "below the onset the dust is off")
	assert_eq(int(quiet[&"count"]), 0, "so it emits nothing")
	assert_true(_near(float(quiet[&"alpha"]), 0.0), "at no alpha at all")
	var loud := SpeedFantasyScript.dust_read(0.9)
	assert_true(bool(loud[&"on"]), "above it the dust is on")
	assert_true(_near(float(loud[&"rate"]), 30.0), "at section 5's own 30/s")
	assert_true(_near(float(loud[&"lifetime"]), 0.5), "over its own 0.5 s lifetime")
	assert_true(_near(float(loud[&"length"]), 12.0), "12 u long")
	assert_eq(int(loud[&"count"]), 15, "which is 30/s over that lifetime")
	var fantasy: Variant = _fantasy()
	var camera := _camera()
	fantasy.call(&"bind_camera", camera)
	var dust := fantasy.call(&"dust") as GPUParticles2D
	assert_true(dust != null, "the emitter is built when the camera arrives")
	assert_eq(dust.get_parent(), camera, "and parented to the camera (section 5 row 3)")
	assert_true(_near(dust.lifetime, 0.5), "with the row's own lifetime")
	assert_eq(dust.amount, 15, "and a capacity of the rate over that lifetime")
	assert_false(dust.emitting, "off until the ratio is high")
	assert_true(
		dust.material is CanvasItemMaterial
			and (dust.material as CanvasItemMaterial).blend_mode == MIX,
		"never additively blown: it draws with the sheet's own alpha (MIX), not ADD"
	)
	var process := dust.process_material as ParticleProcessMaterial
	assert_true(process != null, "its process material carries the low alpha")
	assert_true(_near(process.color.a, 0.35), "which is the ember trail's own alpha floor")
	var frame := dust.texture as AtlasTexture
	assert_true(frame != null, "the streak is the art's own ink box in its re-cut frame")
	assert_eq(frame.atlas.resource_path, DUST_SHEET, "which is `fx_dust_streak_f1.png`")
	assert_eq(frame.region, ProjectileScript.FEEDBACK[&"dust"][&"region"], "the measured object")
	fantasy.call(&"set_ratio", 0.9, Vector2(0.0, 100.0))
	assert_true(dust.emitting and dust.visible, "at speed it emits")
	assert_true(_near(dust.rotation, Vector2.DOWN.angle()), "with the streaks along the velocity")
	fantasy.call(&"set_ratio", 0.5, Vector2.RIGHT)
	assert_false(dust.emitting, "and it is off again below the onset")


## --- Deliverable 4: the hull-critical vignette (FX_SPEC section 6 row 1) -----


func test_the_hull_critical_vignette_pulses_and_is_removed_above_the_line() -> void:
	assert_true(
		_near(ProjectileScript.LOW_HULL_FRACTION, 0.25),
		"the states' one line is section 1.8's own 25 %"
	)
	var fantasy: Variant = _fantasy()
	var rect := fantasy.call(&"vignette_rect") as TextureRect
	assert_true(rect != null, "the overlay is built")
	assert_eq(rect.texture.resource_path, VIGNETTE_SHEET, "from the re-cut vignette frame")
	assert_true(
		rect.material is CanvasItemMaterial
			and (rect.material as CanvasItemMaterial).blend_mode == MIX,
		"blended with the frame's own alpha: the plate's transparent centre now draws nothing"
	)
	assert_false(rect.visible, "a healthy hull draws nothing")
	fantasy.call(&"set_hull_fraction", 0.2)
	assert_true(bool(fantasy.call(&"vignette_active")), "20 % is below the line")
	assert_true(rect.visible, "so the overlay is up")
	assert_true(
		_near(float(fantasy.call(&"vignette_alpha")), 0.8, 1e-3),
		"at the sine's midpoint on the frame it comes up"
	)
	fantasy.call(&"_process", 0.3)
	assert_true(
		_near(float(fantasy.call(&"vignette_alpha")), 1.0, 1e-3),
		"a quarter of the 1.2 s period later it is at section 1.8's 1.0"
	)
	fantasy.call(&"_process", 0.6)
	assert_true(
		_near(float(fantasy.call(&"vignette_alpha")), 0.6, 1e-3),
		"and three quarters through the period at its 0.6"
	)
	fantasy.call(&"_process", 0.3)
	assert_true(
		_near(float(fantasy.call(&"vignette_alpha")), 0.8, 1e-3),
		"a whole 1.2 s returns the pulse to where it started"
	)
	assert_true(
		_near(float(rect.modulate.a), float(fantasy.call(&"vignette_alpha")), 1e-3),
		"and the overlay's own modulate is the pulse"
	)
	fantasy.call(&"set_hull_fraction", 0.3)
	assert_false(bool(fantasy.call(&"vignette_active")), "30 % is above the line")
	assert_false(rect.visible, "so the overlay is removed")
	assert_true(_near(float(rect.modulate.a), 0.0), "and draws nothing")
	fantasy.call(&"set_hull_fraction", 0.2)
	assert_true(
		_near(float(fantasy.call(&"vignette_alpha")), 0.8, 1e-3),
		"re-entering the state restarts the pulse rather than resuming an old phase"
	)


## --- Deliverable 5: the low-hull electrical arcs (FX_SPEC section 6 row 3) ---


func test_the_low_hull_arcs_fire_on_the_sections_cadence_through_the_shipped_row() -> void:
	var rig := _ship_at(0.20)
	var ship: Node2D = rig[&"ship"]
	var audio := _audio()
	assert_true(audio != null, "the AudioManager autoload is live")
	assert_eq(int(ship.call(&"arc_count")), 0, "a fresh hull has fired none")
	var frames := int(round(ARC_SECONDS / PHYSICS_STEP))
	for i in frames:
		ship.call(&"_update_damage_arcs", PHYSICS_STEP)
		var next := float(ship.call(&"arc_interval"))
		if next > 0.0:
			assert_true(
				next >= PlayerShipScript.ARC_INTERVAL_MIN
				and next <= PlayerShipScript.ARC_INTERVAL_MAX,
				"every drawn interval stays inside section 6's own 1.6-2.6 s"
			)
	var fired := int(ship.call(&"arc_count"))
	assert_true(
		fired >= 2 and fired <= 3,
		"6 s of a 1.6-2.6 s cadence is two or three arcs (measured %d)" % fired
	)
	var arcs := _fx_nodes(ship, ARC_SHEET)
	assert_eq(arcs.size(), fired, "one arc sprite per fired arc, and none other")
	for node: Node in arcs:
		var sprite := node as AnimatedSprite2D
		assert_true(sprite != null, "the arc is the shipped one-shot sheet")
		assert_true(
			sprite.sprite_frames.get_animation_loop(FxScript.ANIMATION) == false,
			"which does not loop (section 7.3's one-shot rows)"
		)
		assert_true(
			_near(sprite.global_position.distance_to(ship.global_position), float(ship.call(&"_hull_radius")), 1e-3),
			"and it snaps on the hull's own radius, not at an invented distance"
		)
	assert_true(
		arcs.size() > 0 and (arcs[0] as CanvasItem).material is CanvasItemMaterial,
		"drawn with the sheet's own alpha, like every re-cut FX plate"
	)


func test_a_hull_above_the_line_never_arcs() -> void:
	var rig := _ship_at(0.80)
	var ship: Node2D = rig[&"ship"]
	var frames := int(round(ARC_SECONDS / PHYSICS_STEP))
	for i in frames:
		ship.call(&"_update_damage_arcs", PHYSICS_STEP)
	assert_eq(int(ship.call(&"arc_count")), 0, "above 25 % no arc fires at all")
	assert_eq(_fx_nodes(ship, ARC_SHEET).size(), 0, "and none is drawn")


## --- Deliverable 6: the thruster trail (FX_SPEC section 1.3's amendment) -----


func test_the_thruster_trail_is_one_emitter_per_anchor_shaped_by_the_ratio() -> void:
	var row := ProjectileScript.feedback_row(&"trail")
	var source := row.get(&"source", Vector2.ZERO) as Vector2
	assert_true(
		source.x > 0.0 and source.y > 0.0,
		"the trail row carries the drawn frame's own ink box"
	)
	var low := ProjectileScript.trail_read(0.15, source)
	assert_true(_near(float(low[&"rate"]), 20.0), "20 streaks/s at the amendment's 0.15 floor")
	assert_true(_near(float(low[&"length"]), 24.0), "24 u long there")
	assert_true(_near(float(low[&"width"]), 6.0), "6 u wide, the row's single constant")
	assert_true(_near(float(low[&"alpha"]), 0.35), "at alpha 0.35")
	assert_eq(int(low[&"amount"]), 24, "the emitter's capacity is the top rate over the lifetime")
	assert_true(
		_near(float(low[&"amount_ratio"]), 20.0 / 60.0, 1e-4),
		"and the floor rate rides a third of that capacity"
	)
	assert_true(
		(low[&"scale"] as Vector2).is_equal_approx(Vector2(24.0 / source.x, 6.0 / source.y)),
		"the quad scale reads the frame's pixels as 24 x 6 u"
	)
	var high := ProjectileScript.trail_read(1.0, source)
	assert_true(_near(float(high[&"rate"]), 60.0), "60 streaks/s at full speed")
	assert_true(_near(float(high[&"length"]), 56.0), "56 u long")
	assert_true(_near(float(high[&"alpha"]), 0.85), "at alpha 0.85")
	assert_true(_near(float(high[&"amount_ratio"]), 1.0), "the whole capacity")
	assert_true(
		(high[&"scale"] as Vector2).is_equal_approx(Vector2(56.0 / source.x, 6.0 / source.y)),
		"56 x 6 u"
	)
	var ship: Variant = PlayerShipScene.instantiate()
	_host().add_child(ship)
	_staged.append(ship)
	## The anchor seam: one tail point today, behind the hull's own art-derived radius.
	var radius := float(ship.call(&"_hull_radius"))
	assert_true(radius > 0.0, "the hull carries its own radius")
	var anchors: Array = ship.call(&"thruster_anchors")
	assert_eq(anchors.size(), 1, "today the seam returns one tail point")
	assert_true(
		(anchors[0] as Vector2).is_equal_approx(Vector2(-radius * 0.55, 0.0)),
		"behind the hull's centre, at the anchor row's own 0.55"
	)
	ship.call(&"set_speed_ratio", 1.0)
	ship.call(&"_update_thrust_feedback", true)
	var trails: Array = ship.call(&"thruster_trails")
	assert_eq(trails.size(), 1, "one emitter for the one anchor")
	var trail := trails[0] as GPUParticles2D
	assert_true(trail.emitting and trail.visible, "emitting while the thrust is held")
	assert_true(_near(trail.lifetime, 0.4), "each streak lives the amendment's own 0.4 s")
	assert_false(trail.local_coords, "and trails in world space, as the amendment requires")
	assert_true(_near(trail.rotation, PI), "turned half a turn so the streak's head is the anchor")
	assert_true(
		trail.scale.is_equal_approx(Vector2.ONE),
		"the node itself is unscaled: its `scale` does not reach what is drawn (S2 section 2.2)"
	)
	assert_true(
		_quad_scale(trail).is_equal_approx(Vector2(56.0 / source.x, 6.0 / source.y)),
		"the draw pass carries 56 x 6 u at full speed"
	)
	assert_true(
		_near(trail.amount_ratio, 1.0),
		"emitting its whole capacity"
	)
	assert_true(
		trail.position.is_equal_approx((anchors[0] as Vector2) - Vector2(28.0, 0.0)),
		"its origin is pulled back by half a streak, so the head - not the middle - rides the engine"
	)
	assert_true(
		trail.material is ShaderMaterial,
		"and the quad is sized through the draw pass, not the node (S2's HIGH 2)"
	)
	var frame := trail.texture as AtlasTexture
	assert_true(frame != null, "the streak is the art's own ink box in its re-cut frame")
	assert_eq(frame.atlas.resource_path, TRAIL_SHEET, "which is `fx_engine_trail_f1.png`")
	assert_eq(frame.region, row[&"region"], "the measured streak, not the frame's canvas")
	var material := trail.process_material as ParticleProcessMaterial
	assert_true(_near(material.color.a, 0.85), "and the row's own alpha is on the particle")
	## The active rule: the thrust input, or the ratio's own 0.15 floor (the drift case).
	ship.call(&"set_speed_ratio", 0.0)
	ship.call(&"_update_thrust_feedback", false)
	assert_false(trail.emitting, "a hull standing still with no stick emits nothing")
	ship.call(&"set_speed_ratio", 0.5)
	ship.call(&"_update_thrust_feedback", false)
	assert_true(trail.emitting, "but a drifting hull above the floor still reads as moving")
	ship.call(&"set_speed_ratio", 0.15)
	ship.call(&"_update_thrust_feedback", false)
	assert_true(trail.emitting, "the floor itself counts")
	ship.call(&"set_speed_ratio", 0.0)
	ship.call(&"_update_thrust_feedback", true)
	assert_true(trail.emitting, "and so does a hull standing on its thrust")


func test_the_trail_seam_takes_one_emitter_per_anchor_and_drops_the_extra() -> void:
	var ship: Variant = PlayerShipScene.instantiate()
	_host().add_child(ship)
	_staged.append(ship)
	## Wave P2-A's shape: one point per engine cell, handed to the same sync.
	var cells: Array[Vector2] = [
		Vector2(-18.0, -8.0),
		Vector2(-18.0, 0.0),
		Vector2(-18.0, 8.0),
	]
	var emitters := ProjectileScript.sync_thruster_trails(ship, cells, 0.5, true)
	assert_eq(emitters.size(), 3, "three anchors build three emitters")
	assert_true(
		emitters[0].position.is_equal_approx(
			cells[0] - Vector2(ProjectileScript.trail_length(0.5) * 0.5, 0.0)
		),
		"each on its own anchor, pulled back by half its streak"
	)
	var again := ProjectileScript.sync_thruster_trails(ship, cells, 0.5, true)
	assert_eq(again.size(), 3, "re-syncing is idempotent")
	assert_eq(again[0], emitters[0], "and keeps the same nodes rather than rebuilding them")
	ProjectileScript.clear_thruster_trails(ship)
	assert_eq(_fx_nodes(ship, TRAIL_SHEET).size(), 0, "clearing drops every emitter")


## --- Deliverable 7: the thruster bed (AUDIO_SPEC section 4.5) ----------------


## S2's HIGH 1, pinned where it failed: `bed_state`/`sounding_loops` read the cue table,
## which said the bed was sounding while the voice's own player held **no stream** - silent
## on a fresh voice, and still playing the *previous* bed's file on a re-used one, because
## `hold_thruster_bed` shaped the bed on the same frame it started it and the shape killed
## the crossfade tween's `_start_stream` callback. The shaped bed now owns its start, so
## this reads the voice itself: the cue's own file and `playing` true from the first frame,
## and never the file the voice held before.
func test_the_thruster_beds_voice_plays_its_own_stream_from_its_first_frame() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	## A voice this bed will re-use, in the state S2's arm C measured: the manager's voices
	## are shared, so the thruster can land on one left playing the previous bed's file.
	var other := load("res://assets/audio/sfx/sfx_ship_engine_02_loop.ogg") as AudioStream
	assert_true(other != null, "the alternative take is on disk")
	for player: AudioStreamPlayer in audio.get(&"_loop_players"):
		player.stream = other
		player.play()
	assert_true(bool(audio.call(&"hold_thruster_bed", 0.5, true)), "the thruster bed is held")
	var voice := audio.call(&"bed_voice", THRUSTER_CUE) as Dictionary
	assert_true(bool(voice[&"sounding"]), "the cue table reports it sounding")
	assert_true(
		bool(voice[&"playing"]),
		"and the voice's own player is playing: a held bed that never plays a stream is the bug"
	)
	assert_eq(
		String(voice[&"stream"]),
		"res://assets/audio/sfx/sfx_ship_engine_01.ogg",
		"the voice plays the bed's own cue, not whatever it held before"
	)
	assert_true(
		_near(float(voice[&"pitch_scale"]), 0.973529, 1e-4)
		and _near(float(voice[&"volume_db"]), -19.058823, 1e-4),
		"at the curve's own level for 0.5"
	)
	## A fresh voice is the shipped case (the first time a hull flies): the same read.
	audio.call(&"stop_thruster_bed")
	for player: AudioStreamPlayer in audio.get(&"_loop_players"):
		player.stop()
		player.stream = null
	assert_false(
		bool((audio.call(&"bed_voice", THRUSTER_CUE) as Dictionary)[&"sounding"]),
		"the bed is out"
	)
	assert_true(bool(audio.call(&"hold_thruster_bed", 1.0, false)), "re-held at full speed")
	voice = audio.call(&"bed_voice", THRUSTER_CUE) as Dictionary
	assert_true(bool(voice[&"playing"]), "a fresh voice plays on the frame it is asked for")
	assert_eq(
		String(voice[&"stream"]),
		"res://assets/audio/sfx/sfx_ship_engine_01.ogg",
		"with the cue's own file"
	)
	audio.call(&"stop_thruster_bed")


func test_the_thruster_bed_holds_by_ratio_with_hysteresis_and_its_own_cue() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_true(
		_near(AudioScript.thruster_ramp(0.15), 0.0)
		and _near(AudioScript.thruster_ramp(1.0), 1.0),
		"the curve runs 0 at its 0.15 floor to 1 at full speed"
	)
	assert_true(
		int(AudioScript.LOOP_PRIORITY[THRUSTER_CUE]) == 1,
		"the bed's own priority row is 1, beside the shaft's"
	)
	assert_false(
		bool(audio.call(&"hold_thruster_bed", 0.0, false)),
		"at rest with no throttle there is no bed"
	)
	assert_true(
		bool(audio.call(&"hold_thruster_bed", 0.0, true)),
		"a hull standing on its thrust reads even at zero speed"
	)
	var state := audio.call(&"bed_state", THRUSTER_CUE) as Dictionary
	assert_true(bool(state[&"sounding"]), "and the bed is sounding")
	assert_true(_near(float(state[&"pitch_scale"]), 0.85), "at the curve's own floor pitch")
	assert_true(_near(float(state[&"volume_db"]), -24.0), "and -24 dB")
	assert_true(
		bool(audio.call(&"hold_thruster_bed", 0.12, false)),
		"the hysteresis keeps it while the released ratio stays above 0.10"
	)
	assert_false(
		bool(audio.call(&"hold_thruster_bed", 0.09, false)),
		"below 0.10 it goes out"
	)
	assert_false(
		bool(audio.call(&"hold_thruster_bed", 0.12, false)),
		"and a released hull re-arms at 0.15: 0.12 alone does not bring it back"
	)
	assert_true(bool(audio.call(&"hold_thruster_bed", 0.15, false)), "0.15 does")
	assert_true(bool(audio.call(&"hold_thruster_bed", 1.0, false)), "and it holds at speed")
	state = audio.call(&"bed_state", THRUSTER_CUE) as Dictionary
	assert_true(_near(float(state[&"pitch_scale"]), 1.15), "1.15 at full speed")
	assert_true(_near(float(state[&"volume_db"]), -12.0), "and -12 dB")
	assert_true(
		(audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE),
		"the manager reports the bed sounding"
	)
	assert_true(bool(audio.call(&"stop_thruster_bed")), "the stop names its own cue")
	assert_false(
		(audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE),
		"and the bed is out"
	)
	assert_eq(
		audio.cue_path(THRUSTER_CUE),
		"res://assets/audio/sfx/sfx_ship_engine_01.ogg",
		"the bed is the owner's pinned take"
	)


func test_the_thruster_bed_cannot_stop_another_holders_bed() -> void:
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	audio.call(&"play_loop", SHIELD_BED)
	audio.call(&"play_loop", BEAM_BED)
	audio.call(&"hold_thruster_bed", 0.5, true)
	var beds := audio.call(&"sounding_loops") as Array
	assert_eq(beds.size(), 3, "the manager's three voices hold three beds at once")
	assert_true(
		beds.has(SHIELD_BED) and beds.has(BEAM_BED) and beds.has(THRUSTER_CUE),
		"the shield's hum, a held beam's bed and the thruster all sound together"
	)
	audio.call(&"stop_thruster_bed")
	var left := audio.call(&"sounding_loops") as Array
	assert_eq(left.size(), 2, "the thruster's stop takes exactly one bed")
	assert_true(
		left.has(SHIELD_BED) and left.has(BEAM_BED),
		"and it is the thruster's own, not the foreground one"
	)


## --- Deliverables 8 and 9: the boost cue and the dash charge ------------------


func test_the_afterburner_activation_fires_the_boost_cue_and_the_dash_charge_once() -> void:
	var rig := _ship_at(1.0, true)
	var ship: Node2D = rig[&"ship"]
	var audio := _audio()
	if audio == null:
		assert_true(false, "the AudioManager autoload is live")
		return
	assert_true(bool(ship.call(&"has_booster", BOOSTER)), "the hull carries the afterburner")
	assert_eq(int(ship.call(&"boost_activations")), 0, "nothing has lit yet")
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	_pressed.append(PlayerShipScript.BOOST_ACTION)
	for i in 3:
		ship.call(&"_update_boosters", PHYSICS_STEP)
	assert_eq(
		int(ship.call(&"boost_activations")),
		1,
		"three frames of one held trigger light the burner once"
	)
	assert_eq(
		String(audio.call(&"last_sfx")),
		String(BOOST_CUE),
		"AUDIO_SPEC section 4.5's S12 is the cue the activation plays"
	)
	assert_eq(
		audio.cue_path(BOOST_CUE),
		"res://assets/audio/sfx/sfx_ship_boost_01.ogg",
		"and it is the shipped take (no second asset owed)"
	)
	var holder := rig[&"holder"] as Node2D
	var charges := _fx_nodes(holder, CHARGE_SHEET)
	assert_eq(charges.size(), 1, "one dash charge for one activation")
	var charge := charges[0] as Sprite2D
	var row := ProjectileScript.feedback_row(&"dash_charge")
	var expected := FxScript.scale_for(
		row.get(&"source", Vector2.ONE) as Vector2, float(row.get(&"world", 0.0))
	)
	assert_true(
		_near(charge.scale.x, expected),
		"engine-scaled to section 7.1's proposed 32 u"
	)
	assert_true(
		_near(charge.global_position.distance_to(ship.global_position), 0.0, 1e-3),
		"and drawn on the hull that lit it"
	)
	## A second press while the burn is running lights nothing: the activation is the event.
	for i in 3:
		ship.call(&"_update_boosters", PHYSICS_STEP)
	assert_eq(int(ship.call(&"boost_activations")), 1, "a running burn does not re-fire")
	assert_eq(_fx_nodes(holder, CHARGE_SHEET).size(), 1, "so exactly one charge exists")


## --- The re-cut wiring (owner ruling 2026-09-21) ------------------------------


## S2's HIGH 2's lever, pinned in the gate: FX_SPEC section 1.3's 24-56 u x 6 u is a
## statement about the rectangle the emitter **draws**, and a particle emitter draws its
## texture at the texture's own size - the node's `scale` never reaches it (measured on
## three scales, S2's report section 2.2) and the process material's `scale_min/max` is
## uniform, so it cannot give a length and a width. The draw pass can, and this pins the
## pass itself; the rectangle it produces is `probe_s3_trail_quad.tscn`'s measurement.
func test_the_trails_quad_is_sized_through_a_vertex_scaling_draw_pass() -> void:
	var material := FxScript.quad_material(Vector2(0.25, 0.5))
	assert_true(material is ShaderMaterial, "the quad's material is a draw-pass shader")
	assert_true(material.shader != null, "on the shader the library builds once")
	assert_true(
		material.shader.code.contains("VERTEX *="),
		"whose vertex stage scales the quad's own vertices"
	)
	assert_true(
		_material_quad_scale(material).is_equal_approx(Vector2(0.25, 0.5)),
		"and the uniform is the quad's size in the drawn frame's texels"
	)
	assert_true(
		FxScript.set_quad_scale(material, Vector2(0.1, 0.2)), "a shaped emitter re-sizes it"
	)
	assert_true(
		_material_quad_scale(material).is_equal_approx(Vector2(0.1, 0.2)),
		"which is what the ratio writes"
	)
	assert_false(
		FxScript.set_quad_scale(FxScript.alpha_material(), Vector2.ONE),
		"and a sheet's own material is not a quad pass, so there is nothing to re-size"
	)
	var ship: Variant = PlayerShipScene.instantiate()
	_host().add_child(ship)
	_staged.append(ship)
	ship.call(&"set_speed_ratio", 0.15)
	ship.call(&"_update_thrust_feedback", true)
	var trail := (ship.call(&"thruster_trails") as Array)[0] as GPUParticles2D
	var source := ProjectileScript.feedback_row(&"trail").get(&"source", Vector2.ZERO) as Vector2
	assert_true(
		_quad_scale(trail).is_equal_approx(Vector2(24.0 / source.x, 6.0 / source.y)),
		"at the 0.15 floor the shipped emitter draws section 1.3's 24 x 6 u"
	)


## Every effect addresses its own per-frame files now (owner ruling 2026-09-21): the 2K
## masters are no longer an atlas source, and each frame carries its own alpha - which is
## what the blend is. A row that plays a sequence names every frame; a row that reads one
## frame names that one and carries the art's measured ink box.
func test_every_effect_row_addresses_its_own_per_frame_files() -> void:
	var rows: Array = []
	for name: Variant in ProjectileScript.FEEDBACK:
		rows.append([String(name), ProjectileScript.FEEDBACK[name]])
	for kind: Variant in ProjectileScript.SHEETS:
		rows.append([String(kind), ProjectileScript.SHEETS[kind]])
	assert_true(rows.size() >= 13, "the two tables carry every wired effect")
	for entry: Array in rows:
		var name: String = entry[0]
		var row: Dictionary = entry[1]
		var paths: Variant = row.get(&"frames", [])
		assert_true(
			paths is Array and not (paths as Array).is_empty(), "%s names its frames" % name
		)
		for path: Variant in paths:
			var file := String(path)
			assert_true(ResourceLoader.exists(file), "%s's frame is on disk (%s)" % [name, file])
			assert_true(
				file.ends_with(".png") and file.contains("_f"),
				"%s addresses a per-frame file, not a master (%s)" % [name, file]
			)
			var texture := load(file) as Texture2D
			assert_true(texture != null, "%s's frame loads" % name)
			if texture == null:
				continue
			var image := texture.get_image()
			assert_true(
				image != null and image.detect_alpha() != Image.ALPHA_NONE,
				"%s's frame carries its own alpha, which is the blend (%s)" % [name, file]
			)
			if row.has(&"region"):
				var region: Rect2 = row[&"region"]
				assert_true(
					region.end.x <= texture.get_size().x
					and region.end.y <= texture.get_size().y,
					"%s's region is inside its own frame" % name
				)
		if paths is Array and (paths as Array).size() > 1:
			assert_true(
				float(row.get(&"fps", 0.0)) > 0.0, "%s plays its sequence at a rate" % name
			)


## FX_SPEC section 7.2's mine, from the owner's ruling: the mine family owns `fx_mine` -
## its own sprite on the deployable (four frames, the lamp's own pulse) and its own burst
## where it goes off - replacing the `fx_ember_pulse` crop the wiring used before.
func test_the_mine_family_owns_its_sprite_and_its_burst() -> void:
	var sprite: Dictionary = ProjectileScript.SHEETS[&"mine"]
	assert_eq(
		String((sprite[&"frames"] as Array)[0]),
		"res://assets/fx/fx_mine_f1.png",
		"the deployable's sprite is the family's own art"
	)
	var row := ProjectileScript.feedback_row(&"mine_burst")
	assert_false(row.is_empty(), "and its burst is a row in the feedback table")
	assert_eq(row[&"frames"], sprite[&"frames"], "the burst is that same art, frame for frame")
	assert_eq(row[&"region"], sprite[&"region"], "read at the same measured box")
	assert_true(
		_near(float(row[&"world"]), float(sprite[&"world"])),
		"and at the same 22 u read, so the burst invents no size"
	)
	var shot: Variant = ProjectileScript.new()
	shot.call(&"configure", {&"kind": ProjectileScript.KIND_MINE, &"damage": 1.0})
	var holder := Node2D.new()
	holder.name = &"MineWorld"
	_host().add_child(holder)
	_staged.append(holder)
	holder.add_child(shot)
	shot.call(&"_detonate", Vector2(10.0, 20.0))
	var burst := holder.get_node_or_null(NodePath(&"mine_burst")) as AnimatedSprite2D
	assert_true(burst != null, "a mine's own detonation draws its own burst")
	if burst == null:
		return
	assert_eq(
		burst.sprite_frames.get_frame_count(FxScript.ANIMATION),
		(sprite[&"frames"] as Array).size(),
		"all four of its frames"
	)
	assert_false(
		burst.sprite_frames.get_animation_loop(FxScript.ANIMATION),
		"played once, as section 7.3's one-shot rows do"
	)
	assert_true(
		burst.material is CanvasItemMaterial
		and (burst.material as CanvasItemMaterial).blend_mode == MIX,
		"blended with the sheet's own alpha"
	)
	assert_true(
		_near(burst.global_position.distance_to(Vector2(10.0, 20.0)), 0.0, 1e-3),
		"where the mine went off"
	)
	assert_eq(
		_fx_nodes(holder, "res://assets/fx/fx_mine_f1.png").size(),
		2,
		"the family's art is on the deployable's own body and on the burst"
	)
	assert_eq(
		_fx_nodes(holder, "res://assets/fx/fx_explosion_f1.png").size(),
		1,
		"and FX_SPEC section 1.4's explosion is still drawn beside it"
	)


## --- The stage's own wiring of the one input ---------------------------------


func test_the_stage_pushes_one_ratio_to_the_stack_and_to_the_hull() -> void:
	if _scene == null:
		assert_true(false, "the game scene is up")
		return
	var fantasy = _scene.get_node_or_null(NodePath(&"SpeedFantasy"))
	var ship: Variant = _scene.get_node_or_null(NodePath(&"PlayerShip"))
	var state: Variant = _scene.get(&"_state")
	assert_true(fantasy != null and ship != null and state != null, "the scene built its ship and stack")
	_scene.call(&"_push_speedometer")
	assert_true(_near(float(fantasy.call(&"ratio")), 0.0), "a hull at rest reads the dial's zero")
	assert_true(
		_near(float(ship.call(&"speed_ratio")), 0.0),
		"and the hull's own thruster driver got the same frame's ratio"
	)
	var expected := clampf(float(state.hull) / float(state.hull_max), 0.0, 1.0)
	assert_true(
		_near(float(fantasy.call(&"hull_fraction")), expected),
		"the hull fraction is PlayerState's own, pushed every frame"
	)
	assert_true(
		_near(float(fantasy.call(&"applied_zoom")), 1.0),
		"and the camera's zoom is this node's to write, at rest 1:1 with the wheel"
	)
	assert_true(
		_scene.get(&"_hud") != null and float(_scene.get(&"_hud").call(&"speedometer_ratio")) >= -0.001,
		"the dial is still fed from the same computation"
	)


## --- Fixtures and helpers ---------------------------------------------------


## The draw pass's own quad size: the size a particle emitter cannot get from its node
## (S2's report section 2.2). The measured rectangle that size produces is
## `probe_s3_trail_quad.tscn`'s - a window is needed to draw, so the gate pins the lever
## and the probe pins the pixels.
func _quad_scale(node: CanvasItem) -> Vector2:
	var material := node.material as ShaderMaterial
	if material == null:
		return Vector2.ZERO
	return material.get_shader_parameter(&"quad_scale") as Vector2


## The same read on a material a caller holds directly (the draw pass itself, before any
## node carries it).
func _material_quad_scale(material: Material) -> Vector2:
	var quad := material as ShaderMaterial
	if quad == null:
		return Vector2.ZERO
	return quad.get_shader_parameter(&"quad_scale") as Vector2


## A detached/buildable SpeedFantasy, in the tree so `_ready` builds the screen stack; its
## clock only advances by the `_process` calls a test makes, which is what keeps the pulse
## readable.
func _fantasy() -> Variant:
	var node: Variant = SpeedFantasyScript.new()
	_host().add_child(node)
	_staged.append(node)
	return node


func _camera() -> Camera2D:
	var camera := Camera2D.new()
	_host().add_child(camera)
	_staged.append(camera)
	return camera


## A live hull at `fraction` of its own maximum, in a holder node that plays the world's
## part (the parent a world-space FX is placed into).
func _ship_at(fraction: float, with_booster: bool = false) -> Dictionary:
	var fit: Dictionary = ShipFitScript.STANDARD_FIT.duplicate(true)
	if with_booster:
		fit[&"boosters"] = [BOOSTER]
	var stats: Variant = ShipFitScript.resolve(HULL, fit)
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.setup()
	state.hull = stats.hull_max * fraction
	var holder := Node2D.new()
	holder.name = &"FeelWorld"
	_host().add_child(holder)
	_staged.append(holder)
	var ship: Variant = PlayerShipScene.instantiate()
	holder.add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return {&"ship": ship, &"state": state, &"holder": holder, &"stats": stats}


## Every sprite under `root` drawn from `sheet`: the shipped sheet's own path, reached
## through the `AtlasTexture` every frame is built over (`Fx.frame`).
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
		if frames == null or frames.get_frame_count(FxScript.ANIMATION) == 0:
			return false
		return _source_path(frames.get_frame_texture(FxScript.ANIMATION, 0)) == sheet
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


func _audio() -> Node:
	return _tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))


## The beds this suite could leave sounding are put out between tests, so one test cannot
## hear another's state (audio is not reset by the runner).
func _clear_loops() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.call(&"stop_bed", THRUSTER_CUE)
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)


func _release_pressed() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already there and
## takes children all through the run, whereas the root viewport is busy adding the
## runner scene during `_ready` (the `test_flight_feel_g1` idiom).
func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _near(a: float, b: float, tolerance: float = TOL) -> bool:
	return absf(a - b) <= tolerance
