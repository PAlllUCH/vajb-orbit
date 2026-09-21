extends Node2D
## S1's probe for the speed-fantasy / damage-state wave (slice 2.5, 2026-09-21).
##
## It prints one `[S25]` line per measurement the wave's brief asks for, with the raw
## numbers, and it is **deterministic**: every number comes from a shipped seam driven by
## hand (`SpeedFantasy._process`, `PlayerShip._update_damage_arcs`, `_update_thrust_feedback`,
## `AudioManager.hold_thruster_bed`), so no measurement depends on wall-clock time, on the
## engine's own frame pacing or on the audio device. The one section that does run the real
## frame loop (the last one) reports booleans and ranges rather than raw floats, because
## those values are the frame loop's.
##
## What each group proves, in the brief's order:
##   BLUR      - FX_SPEC section 5 row 1: the strength is zero at and below the 0.70 onset
##               and runs 0.1 -> 0.8 above it, with the direction and the aberration riding
##               the same input;
##   ZOOM      - section 5 row 2: `applied = wheel * pullback(ratio)`, the wheel's own value
##               never written back, measured at the wheel's 1.0 and 1.30;
##   DUST      - section 5 row 3: emission on and off by the ratio, its rate/lifetime/length
##               and its non-additive blend;
##   VIGNETTE  - section 6 row 1: the 0.6 -> 1.0 / 1.2 s sine at hull 20 % and its removal
##               at 30 %;
##   ARCS      - section 6 row 3: how many arcs 6 s of a hull at 20 % draws, and that a hull
##               at 80 % draws none;
##   TRAIL     - section 1.3's amendment: the per-cell particle count, scale and alpha at
##               ratio 0.15 and 1.0, and the active rule's four cases;
##   BED       - AUDIO_SPEC section 4.5: sounding/pitch/volume by ratio and the 0.15/0.10
##               hysteresis, plus three beds sounding at once;
##   BOOST     - section 4.5's last paragraph and FX_SPEC section 7.1: one activation, one
##               S12 cue and one dash charge;
##   LIVE      - the shipped frame loop: `game.tscn` flies at speed and every row of the
##               stack is read back from the scene's own push (booleans, by construction).
##
## Run:
##   ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_feel.tscn \
##     --fixed-fps 60 --quit-after 900

const GameScene := preload("res://game/game.tscn")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[S25]"
const HULL: StringName = &"ship_vanguard"
const BOOSTER: StringName = &"b_afterburner"
const AUDIO_SERVICE: StringName = &"AudioManager"

const CHARGE_SHEET := "res://assets/fx/fx_dash_charge.png"
const ARC_SHEET := "res://assets/fx/fx_arc_spark.png"
const DUST_SHEET := "res://assets/fx/fx_dust_streak.png"
const TRAIL_SHEET := "res://assets/fx/fx_engine_trail.png"
const VIGNETTE_SHEET := "res://assets/fx/fx_hull_critical_vignette.png"

const THRUSTER_CUE: StringName = &"sfx_ship_engine_01"
const SHIELD_BED: StringName = &"sfx_impact_shield_loop"
const BEAM_BED: StringName = &"sfx_mining_beam"
const BOOST_CUE: StringName = &"sfx_ship_boost_01"

const RATIOS: Array[float] = [0.0, 0.5, 0.9, 1.0]
const ARCS_SECONDS := 6.0
const STEP := 1.0 / 60.0
## A non-zero velocity at every ratio, so the blur's direction line is comparable across
## the four readings (a zero velocity has no bearing at all).
const BEARING := Vector2(0.7071068, -0.7071068)

var _screen: Variant = null
var _camera: Camera2D = null
var _pulse: Variant = null
var _trail_ship: Variant = null
var _staged: Array[Node] = []
var _pressed: Array[StringName] = []


func _ready() -> void:
	_build()
	_case_blur()
	_case_zoom()
	_case_dust()
	_case_vignette()
	_case_arcs()
	_case_trail()
	_case_bed()
	_case_boost()
	await _case_live_frames()
	print("%s done" % TAG)


## --- Fixtures ---------------------------------------------------------------


func _build() -> void:
	var fixture := Node2D.new()
	fixture.name = &"S25Fixture"
	add_child(fixture)
	_staged.append(fixture)
	_camera = Camera2D.new()
	_camera.name = &"ProbeCamera"
	fixture.add_child(_camera)
	_screen = SpeedFantasyScript.new()
	fixture.add_child(_screen)
	_screen.call(&"bind_camera", _camera)
	## The pulse's own node is deliberately **out of the tree**: the engine never calls its
	## `_process`, so every alpha below is the probe's own clock and the reading is
	## reproducible frame by frame.
	_pulse = SpeedFantasyScript.new()
	_trail_ship = _ship(1.0, false)


## A hull at `fraction` of its own maximum, in a holder node that stands in for the world
## (the parent a world-space FX is placed into).
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
	holder.name = &"S25World%d" % _staged.size()
	add_child(holder)
	_staged.append(holder)
	var ship: Variant = PlayerShipScene.instantiate()
	holder.add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return ship


func _audio() -> Node:
	return get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))


## --- 1. The blur (FX_SPEC section 5 row 1) ----------------------------------


func _case_blur() -> void:
	print(
		"%s BLUR onset=%.2f span_px=%.1f aberration_px=%.1f shader=%s"
		% [
			TAG,
			SpeedFantasyScript.BLUR_ONSET,
			SpeedFantasyScript.BLUR_SPAN_PX,
			SpeedFantasyScript.ABERRATION_PX,
			(_screen.call(&"blur_rect") as ColorRect).material.shader.resource_path,
		]
	)
	for ratio: float in RATIOS:
		_screen.call(&"set_ratio", ratio, BEARING * 300.0)
		var rect := _screen.call(&"blur_rect") as ColorRect
		var material := rect.material as ShaderMaterial
		var direction := material.get_shader_parameter(&"blur_direction") as Vector2
		print(
			(
				"%s BLUR ratio=%.2f strength=%.6f chromatic=%.6f visible=%s "
				+ "direction=(%.4f,%.4f) layer=%d"
			)
			% [
				TAG,
				ratio,
				float(material.get_shader_parameter(&"blur_strength")),
				float(material.get_shader_parameter(&"chromatic_aberration")),
				str(rect.visible),
				direction.x,
				direction.y,
				int((_screen.call(&"layer") as CanvasLayer).layer),
			]
		)
	print(
		"%s BLUR onset_control at_0.70=%.6f at_0.69=%.6f at_0.71=%.6f"
		% [
			TAG,
			SpeedFantasyScript.blur_for(0.70),
			SpeedFantasyScript.blur_for(0.69),
			SpeedFantasyScript.blur_for(0.71),
		]
	)


## --- 2. The camera pull-back (FX_SPEC section 5 row 2) ----------------------


func _case_zoom() -> void:
	for wheel: float in [1.0, 1.30]:
		for ratio: float in RATIOS:
			_screen.call(&"set_wheel_zoom", wheel)
			_screen.call(&"set_ratio", ratio, BEARING * 300.0)
			print(
				(
					"%s ZOOM wheel=%.4f ratio=%.2f pullback=%.6f applied=%.6f camera=%.6f "
					+ "wheel_readback=%.4f"
				)
				% [
					TAG,
					wheel,
					ratio,
					float(_screen.call(&"pullback")),
					float(_screen.call(&"applied_zoom")),
					_camera.zoom.x,
					float(_screen.call(&"wheel_zoom")),
				]
			)


## --- 3. The dust streaks (FX_SPEC section 5 row 3) --------------------------


func _case_dust() -> void:
	var dust := _screen.call(&"dust") as GPUParticles2D
	print(
		"%s DUST emitter parent=%s sheet=%s blend=%s local_coords=%s lifetime=%.2f amount=%d"
		% [
			TAG,
			dust.get_parent().name,
			((dust.texture as AtlasTexture).atlas as Texture2D).resource_path,
			"add" if dust.material is CanvasItemMaterial else "mix",
			str(dust.local_coords),
			dust.lifetime,
			dust.amount,
		]
	)
	for ratio: float in [0.0, 0.5, 0.69, 0.70, 0.9, 1.0]:
		_screen.call(&"set_ratio", ratio, BEARING * 300.0)
		var read := SpeedFantasyScript.dust_read(ratio)
		var process := dust.process_material as ParticleProcessMaterial
		print(
			(
				"%s DUST ratio=%.2f on=%s emitting=%s visible=%s rate=%.2f count=%d "
				+ "length=%.1f alpha=%.2f color_a=%.2f rotation_deg=%.2f"
			)
			% [
				TAG,
				ratio,
				str(bool(read[&"on"])),
				str(dust.emitting),
				str(dust.visible),
				float(read[&"rate"]),
				int(read[&"count"]),
				float(read[&"length"]),
				float(read[&"alpha"]),
				process.color.a,
				rad_to_deg(dust.rotation),
			]
		)


## --- 4. The hull-critical vignette (FX_SPEC section 6 row 1) ----------------


func _case_vignette() -> void:
	_screen.call(&"set_hull_fraction", 0.30)
	var rect := _screen.call(&"vignette_rect") as TextureRect
	print(
		"%s VIGNETTE sheet=%s line=%.2f period=%.1f"
		% [
			TAG,
			(rect.texture as Texture2D).resource_path,
			ProjectileScript.LOW_HULL_FRACTION,
			SpeedFantasyScript.VIGNETTE_SECONDS,
		]
	)
	print(
		"%s VIGNETTE hull=0.30 active=%s visible=%s modulate_a=%.6f"
		% [TAG, str(bool(_screen.call(&"vignette_active"))), str(rect.visible), rect.modulate.a]
	)
	_pulse.call(&"set_hull_fraction", 0.20)
	_pulse.call(&"_process", 0.0)
	var clock := 0.0
	for step: float in [0.0, 0.3, 0.6, 0.9, 1.2]:
		while clock < step - 1e-9:
			_pulse.call(&"_process", 0.3)
			clock += 0.3
		print(
			"%s VIGNETTE hull=0.20 t=%.2f active=%s alpha=%.6f"
			% [TAG, step, str(bool(_pulse.call(&"vignette_active"))), float(_pulse.call(&"vignette_alpha"))]
		)
	_pulse.call(&"set_hull_fraction", 0.30)
	print(
		"%s VIGNETTE hull=0.30 after_the_pulse active=%s undrawn_alpha=%.6f"
		% [TAG, str(bool(_pulse.call(&"vignette_active"))), float(_pulse.call(&"vignette_alpha"))]
	)
	_pulse.call(&"set_hull_fraction", 0.20)
	print(
		"%s VIGNETTE re_entered alpha=%.6f (the clock restarts with the state)"
		% [TAG, float(_pulse.call(&"vignette_alpha"))]
	)


## --- 5. The low-hull arcs (FX_SPEC section 6 row 3) -------------------------


func _case_arcs() -> void:
	var ship: Variant = _ship(0.20, false)
	var frames := int(round(ARCS_SECONDS / STEP))
	var intervals: Array[String] = []
	for i in frames:
		ship.call(&"_update_damage_arcs", STEP)
		var next := float(ship.call(&"arc_interval"))
		if next > 0.0 and not intervals.has("%.6f" % next):
			intervals.append("%.6f" % next)
	print(
		"%s ARCS hull=0.20 seconds=%.1f steps=%d count=%d intervals=[%s] sheet_nodes=%d"
		% [
			TAG,
			ARCS_SECONDS,
			frames,
			int(ship.call(&"arc_count")),
			", ".join(intervals),
			_fx_nodes(ship, ARC_SHEET).size(),
		]
	)
	var healthy: Variant = _ship(0.80, false)
	for i in frames:
		healthy.call(&"_update_damage_arcs", STEP)
	print(
		"%s ARCS hull=0.80 seconds=%.1f count=%d nodes=%d"
		% [TAG, ARCS_SECONDS, int(healthy.call(&"arc_count")), _fx_nodes(healthy, ARC_SHEET).size()]
	)


## --- 6. The thruster trail (FX_SPEC section 1.3's amendment) ----------------


func _case_trail() -> void:
	var ship: Variant = _trail_ship
	var anchors: Array = ship.call(&"thruster_anchors")
	var radius := float(ship.call(&"_hull_radius"))
	print(
		"%s TRAIL anchors=%d point=(%.4f,%.4f) hull_radius=%.4f sheet=%s"
		% [TAG, anchors.size(), (anchors[0] as Vector2).x, (anchors[0] as Vector2).y, radius, TRAIL_SHEET]
	)
	for ratio: float in [0.15, 1.0]:
		ship.call(&"set_speed_ratio", ratio)
		ship.call(&"_update_thrust_feedback", true)
		var trails: Array = ship.call(&"thruster_trails")
		var trail := trails[0] as GPUParticles2D
		var process := trail.process_material as ParticleProcessMaterial
		var read := ProjectileScript.trail_read(
			ratio, ProjectileScript.feedback_row(&"trail")[&"source"] as Vector2
		)
		print(
			(
				"%s TRAIL ratio=%.2f emitters=%d amount=%d amount_ratio=%.6f rate=%.4f "
				+ "count=%.4f length=%.4f width=%.4f scale=(%.8f,%.8f) alpha=%.4f "
				+ "color_a=%.4f emitting=%s lifetime=%.2f local_coords=%s rotation_deg=%.2f pos=(%.4f,%.4f)"
			)
			% [
				TAG,
				ratio,
				trails.size(),
				trail.amount,
				trail.amount_ratio,
				float(read[&"rate"]),
				float(read[&"count"]),
				float(read[&"length"]),
				float(read[&"width"]),
				trail.scale.x,
				trail.scale.y,
				float(read[&"alpha"]),
				process.color.a,
				str(trail.emitting),
				trail.lifetime,
				str(trail.local_coords),
				rad_to_deg(trail.rotation),
				trail.position.x,
				trail.position.y,
			]
		)
	var cases: Array = [
		[0.0, false, "at_rest_no_stick"],
		[0.0, true, "at_rest_stick_down"],
		[0.15, false, "the_floor_drifting"],
		[0.50, false, "drifting"],
	]
	for row: Array in cases:
		ship.call(&"set_speed_ratio", row[0])
		ship.call(&"_update_thrust_feedback", row[1])
		var trail := (ship.call(&"thruster_trails") as Array)[0] as GPUParticles2D
		print(
			"%s TRAIL case=%s ratio=%.2f thrusting=%s emitting=%s"
			% [TAG, row[2], row[0], str(row[1]), str(trail.emitting)]
		)


## --- 7. The thruster bed (AUDIO_SPEC section 4.5) ---------------------------


func _case_bed() -> void:
	var audio := _audio()
	if audio == null:
		print("%s BED audio=missing" % TAG)
		return
	audio.call(&"stop_thruster_bed")
	print(
		"%s BED cue=%s path=%s priority=%d on=%.2f off=%.2f pitch=%.2f..%.2f volume_db=%.1f..%.1f"
		% [
			TAG,
			THRUSTER_CUE,
			audio.call(&"cue_path", THRUSTER_CUE),
			int(AudioScript.LOOP_PRIORITY[THRUSTER_CUE]),
			AudioScript.THRUSTER_ON_RATIO,
			AudioScript.THRUSTER_OFF_RATIO,
			AudioScript.THRUSTER_PITCH_MIN,
			AudioScript.THRUSTER_PITCH_MAX,
			AudioScript.THRUSTER_VOLUME_MIN_DB,
			AudioScript.THRUSTER_VOLUME_MAX_DB,
		]
	)
	for ratio: float in [0.0, 0.15, 0.5, 0.9, 1.0]:
		var held := bool(audio.call(&"hold_thruster_bed", ratio, false))
		var state := audio.call(&"bed_state", THRUSTER_CUE) as Dictionary
		print(
			"%s BED ratio=%.2f released_throttle held=%s sounding=%s pitch=%.6f volume_db=%.6f ramp=%.6f"
			% [
				TAG,
				ratio,
				str(held),
				str(bool(state[&"sounding"])),
				float(state[&"pitch_scale"]),
				float(state[&"volume_db"]),
				AudioScript.thruster_ramp(ratio),
			]
		)
	audio.call(&"stop_thruster_bed")
	print("%s BED thrust_only ratio=0.00 thrusting=true held=%s" % [TAG, str(bool(audio.call(&"hold_thruster_bed", 0.0, true)))])
	audio.call(&"stop_thruster_bed")
	for row: Array in [[0.12, "below_the_on_threshold"], [0.15, "at_the_on_threshold"], [0.12, "latched_above_off"], [0.10, "at_the_off_threshold"], [0.09, "below_the_off_threshold"], [0.12, "re_arm_needs_0.15"], [0.15, "re_armed"]]:
		var held := bool(audio.call(&"hold_thruster_bed", row[0], false))
		print(
			"%s BED hysteresis %s ratio=%.2f held=%s sounding=%s"
			% [TAG, row[1], row[0], str(held), str((audio.call(&"sounding_loops") as Array).has(THRUSTER_CUE))]
		)
	audio.call(&"stop_thruster_bed")
	audio.call(&"play_loop", SHIELD_BED)
	audio.call(&"hold_thruster_bed", 0.5, true)
	audio.call(&"play_loop", BEAM_BED)
	var beds := audio.call(&"sounding_loops") as Array
	print("%s BED sounding_at_once=%d beds=[%s]" % [TAG, beds.size(), _names(beds)])
	audio.call(&"stop_thruster_bed")
	var left := audio.call(&"sounding_loops") as Array
	print("%s BED after_thruster_stop=%d beds=[%s]" % [TAG, left.size(), _names(left)])
	audio.call(&"stop_bed", SHIELD_BED)
	audio.call(&"stop_bed", BEAM_BED)


## --- 8/9. The boost cue and the dash charge ---------------------------------


func _case_boost() -> void:
	var ship: Variant = _ship(1.0, true)
	var audio := _audio()
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	_pressed.append(PlayerShipScript.BOOST_ACTION)
	for i in 3:
		ship.call(&"_update_boosters", STEP)
	print(
		"%s BOOST cue=%s last_sfx=%s path=%s activations=%d"
		% [
			TAG,
			BOOST_CUE,
			audio.call(&"last_sfx"),
			audio.call(&"cue_path", BOOST_CUE),
			int(ship.call(&"boost_activations")),
		]
	)
	var holder := ship.get_parent() as Node2D
	var charges := _fx_nodes(holder, CHARGE_SHEET)
	var row := ProjectileScript.feedback_row(&"dash_charge")
	var source := row[&"source"] as Vector2
	for node: Node in charges:
		var charge := node as Sprite2D
		print(
			"%s BOOST charge=%s scale=%.8f world_u=%.4f at_hull=%s fades=%.2f"
			% [
				TAG,
				CHARGE_SHEET,
				charge.scale.x,
				maxf(source.x, source.y) * charge.scale.x,
				str(absf(charge.global_position.distance_to(ship.global_position)) < 1e-3),
				float(row[&"seconds"]),
			]
		)
	print(
		"%s BOOST charges=%d (one activation)"
		% [TAG, charges.size()]
	)
	for i in 3:
		ship.call(&"_update_boosters", STEP)
	print(
		"%s BOOST after_three_more_burning_frames activations=%d charges=%d"
		% [TAG, int(ship.call(&"boost_activations")), _fx_nodes(holder, CHARGE_SHEET).size()]
	)


## --- The shipped frame loop, read back from the scene's own push -----------


func _case_live_frames() -> void:
	var packed := load("res://game/game.tscn") as PackedScene
	if packed == null:
		print("%s LIVE scene=missing" % TAG)
		return
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	_staged.append(scene)
	var fantasy = scene.get_node_or_null(NodePath(&"SpeedFantasy"))
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var state: Variant = scene.get(&"_state")
	var stats: Variant = scene.get(&"_stats")
	if fantasy == null or ship == null or state == null or stats == null:
		print("%s LIVE wiring=missing" % TAG)
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	var fast := Vector2(0.95, 0.0) * float(stats.max_speed)
	body.linear_velocity = fast
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ratio := float(fantasy.call(&"ratio"))
	var strength := float(fantasy.call(&"blur_strength"))
	var trail := (ship.call(&"thruster_trails") as Array)
	var dust := fantasy.call(&"dust") as GPUParticles2D
	print(
		(
			"%s LIVE frames=2 ratio=%.4f ratio_pushed=%s blur_on=%s dust_on=%s dust_visible=%s "
			+ "trail_emitters=%d trail_emitting=%s hull_fraction=%.4f vignette=%s"
		)
		% [
			TAG,
			ratio,
			str(ratio > 0.5),
			str(strength > 0.0),
			str(dust.emitting),
			str(dust.visible),
			trail.size(),
			str(trail.size() > 0 and (trail[0] as GPUParticles2D).emitting),
			float(fantasy.call(&"hull_fraction")),
			str(bool(fantasy.call(&"vignette_active"))),
		]
	)
	body.linear_velocity = fast
	scene.call(&"_set_camera_zoom", 1.30)
	## 0.30 s of physics frames at the fixed rate, with the hull held at the same speed: the
	## wheel's own 0.18 s tween settles inside this window, so the applied value is the
	## settled composition rather than a mid-tween sample.
	for i in 18:
		body.linear_velocity = fast
		await get_tree().physics_frame
	var applied := float(fantasy.call(&"applied_zoom"))
	var wheel := float(fantasy.call(&"wheel_zoom"))
	var ratio_now := float(fantasy.call(&"ratio"))
	var pullback := SpeedFantasyScript.pullback_for(ratio_now)
	print(
		(
			"%s LIVE wheel target=%.2f shown=%.6f ratio=%.4f pullback=%.6f applied=%.6f "
			+ "camera=%.6f composes=%s pull_back_applied=%s"
		)
		% [
			TAG,
			float(scene.get(&"_camera_zoom")),
			wheel,
			ratio_now,
			pullback,
			applied,
			(scene.get(&"_camera") as Camera2D).zoom.x,
			str(absf(applied - wheel * pullback) < 1e-6),
			str(pullback < 1.0),
		]
	)
	## The hull-critical state through the scene's own push, on live frames: the pulse is
	## the frame clock's, so only its own band is asserted here.
	state.hull = float(state.hull_max) * 0.20
	scene.call(&"_push_speedometer")
	await get_tree().physics_frame
	var alpha := float(fantasy.call(&"vignette_alpha"))
	print(
		"%s LIVE hull=0.20 vignette_visible=%s alpha_in_band=%s alpha=%.6f band=%.2f..%.2f"
		% [
			TAG,
			str((fantasy.call(&"vignette_rect") as TextureRect).visible),
			str(alpha >= SpeedFantasyScript.VIGNETTE_ALPHA_MIN - 1e-6 and alpha <= SpeedFantasyScript.VIGNETTE_ALPHA_MAX + 1e-6),
			alpha,
			SpeedFantasyScript.VIGNETTE_ALPHA_MIN,
			SpeedFantasyScript.VIGNETTE_ALPHA_MAX,
		]
	)
	## The arcs on live frames: their first interval is the seeded hull's own (2.136 s in the
	## ARCS case above), so the window is 2.5 s of physics frames and the assertion is "at
	## least one arc inside the band".
	for i in 150:
		await get_tree().physics_frame
	var next := float(ship.call(&"arc_interval"))
	print(
		"%s LIVE hull=0.20 arced=%s next_interval_in_band=%s arcs=%d"
		% [
			TAG,
			str(int(ship.call(&"arc_count")) >= 1),
			str(next >= PlayerShipScript.ARC_INTERVAL_MIN and next <= PlayerShipScript.ARC_INTERVAL_MAX),
			int(ship.call(&"arc_count")),
		]
	)
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()



## --- Helpers ----------------------------------------------------------------


func _names(values: Array) -> String:
	var out: PackedStringArray = []
	for value: Variant in values:
		out.append(String(value))
	return ", ".join(out)


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
