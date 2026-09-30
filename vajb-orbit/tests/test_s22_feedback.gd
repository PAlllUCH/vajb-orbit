@tool
extends McpTestSuite
## Suite s22_feedback: wave S22's feedback seams, the S22-B1 subset - the hit marker's
## delivery seam (A1 / L28), the ram contact cue + spark (A2 / L56), the muzzle flash's
## nose anchor (A3 / L51), the mining chip burst (A4 / L52+L65, verify-only), the low-hull
## arc cadence (A8 / L55, verify-only), the tool slot's ModuleCatalog label (A12 / L70)
## and every pinned FX-2 number (A13, verify-only).
##
## Contract: `S22_BRIEF.md` section 4's six rules and section 6's acceptance list;
## `slices/D15-flight-feedback/D15-A1_report.md`'s ticked sheet (T-feel-4/5/6/7, FX-1,
## FX-2a-e); `docs/CONTRACTS.md` section 12 (the row-15 ram pair); `docs/design/FX_SPEC.md`
## sections 1.2/1.6/7.2 and its §8 amendment; `docs/design/AUDIO_SPEC.md` sections 4/8.
##
## One `game.tscn` is built once in `suite_setup` under a staged fixture fit (the
## `test_engine2_wiring.gd` pattern), so every row measures the shipped launch: the real
## ship, its WeaponsComponent, the HUD the scene bound to it and the real state. No frame
## is awaited (the runner never yields), so everything is a synchronous reading: the
## marker's `visible` flag, the FX nodes the shipped statics spawned, `AudioManager
## .last_sfx()` and the constants each pin names.

const GameScene := preload("res://game/game.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const MiningLaserScene := preload("res://game/mining_laser.tscn")
const ModuleCatalogScript := preload("res://game/module_catalog.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const FxScript := preload("res://game/fx.gd")

const AUDIO_SERVICE: StringName = &"AudioManager"
const GAME_SCENE := "res://game/game.tscn"

## The fixture fit: one beam family and one travelling family, plus its own packs, staged
## on the profile before the scene launches (the same discipline `test_engine2_wiring.gd`
## keeps - the account is restored untouched in `suite_teardown`).
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser", &"w_cannon"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}
const FIXTURE_PACKS: Dictionary = {&"laser": 120, &"cannon": 60}
const FIXTURE_FAMILIES: Array[StringName] = [&"laser", &"cannon"]

const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const ROCK_MINERAL: StringName = &"iron"
const ROCK_UNITS := 100

## The first frame of each sheet this suite counts nodes by, so a hit's own effect is
## found by what it draws rather than by a node name.
const FLASH_FRAME := "res://assets/fx/fx_muzzle_flash_f1.png"
const CHIP_FRAME := "res://assets/fx/fx_mining_beam_f1.png"
const ARC_FRAME := "res://assets/fx/fx_arc_spark_f1.png"

## A hull clear of the player but inside the weapons' range, the `engine2_wiring` fixture.
const TARGET_OFFSET := Vector2(300.0, 0.0)

var _scene: Node2D = null
var _ship: Node2D = null
var _hud: Control = null
var _state: Variant = null
var _guns: Node2D = null
var _roots: Array[Node2D] = []
var _previous_fits: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_rem: Dictionary = {}
## The deliveries the component's `hit_landed` reported to this suite (A1's row).
var _deliveries: Array = []


func suite_name() -> String:
	return "s22_feedback"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_fixture()
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_fixture_host().add_child(_scene)
	_ship = _scene.get_node_or_null(NodePath("PlayerShip")) as Node2D
	_hud = _scene.get_node_or_null(NodePath("Hud")) as Control
	_state = _scene.get(&"_state")
	if _ship == null or _hud == null or _state == null:
		fail_setup("the game scene did not build its ship, HUD and state")
		return
	_guns = _ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	if _guns == null:
		fail_setup("the fixture fit mounted no weapon component")
		return


func suite_teardown() -> void:
	_finalise()
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_restore_fixture()


## Per row: no trigger held, no lock, full pools and no leftover shots from the row
## before - every row then measures exactly what it spawns.
func setup() -> void:
	if _scene != null:
		_scene.call(&"_cancel_lock")
	if _guns != null and is_instance_valid(_guns):
		_guns.call(&"set_firing", false)
	if _state != null:
		_state.call(&"set_hull", float(_state.hull_max))
	_free_shots()


func teardown() -> void:
	_finalise()


func _finalise() -> void:
	_free_shots()
	for node: Node2D in _roots:
		if is_instance_valid(node):
			node.free()
	_roots.clear()


## ---------------------------------------------------------------------------
## A1 (L28) - one landed-delivery seam, the marker for any hull
## ---------------------------------------------------------------------------


## The retired poll's successor: the player's component publishes `hit_landed` and the
## HUD answers with the marker for an **unmarked** hull, so a hit reads whatever the
## target window is showing.
func test_a1_a_landed_delivery_marks_an_unmarked_hull() -> void:
	var hull := _spawn_hull(_ship.global_position + TARGET_OFFSET)
	assert_true(_scene.get(&"_lock_target") == null, "no hull is marked")
	var marker: Control = _hud.call(&"hit_marker_node")
	assert_true(marker != null, "the HUD built its hit marker")
	if marker == null:
		return
	marker.visible = false
	assert_true(_guns.has_signal(&"hit_landed"), "the component publishes the seam (A1)")
	_guns.call(&"_deliver", hull, 10.0, false, hull.global_position, &"laser", Vector2.ZERO)
	assert_true(marker.visible, "a landed hit marks an unmarked hull")


## The poll itself: a pool moved by something other than the player's fire is no longer
## a confirmed hit, and the field the old push kept is gone.
func test_a1_the_pool_drop_poll_is_retired() -> void:
	var hull := _spawn_hull(_ship.global_position + TARGET_OFFSET)
	_scene.call(&"_start_lock", hull)
	_scene.call(&"_push_target")
	var marker: Control = _hud.call(&"hit_marker_node")
	marker.visible = false
	hull.call(&"take_damage", 25.0, false, {})
	_scene.call(&"_push_target")
	assert_false(marker.visible, "a pool drop between two pushes is no longer a hit")
	assert_true(_scene.get(&"_target_pools_seen") == null, "the poll's own field is retired")


## The projectile half of the seam: a shot built by the component reports its landed
## delivery back through the same signal, and the marker fires for it too.
func test_a1_a_projectile_delivery_reaches_the_same_signal() -> void:
	var hull := _spawn_hull(_ship.global_position + TARGET_OFFSET)
	if not _guns.hit_landed.is_connected(_on_delivery):
		_guns.hit_landed.connect(_on_delivery)
	assert_true(_guns.hit_landed.is_connected(_on_delivery), "this suite listens to the seam")
	_deliveries.clear()
	var marker: Control = _hud.call(&"hit_marker_node")
	marker.visible = false
	_fire_cannon()
	var shot := _last_shot()
	assert_true(shot != null, "the cannon released a shot")
	if shot == null:
		return
	shot.call(&"_hit_body", hull, hull.global_position)
	assert_eq(_deliveries.size(), 1, "one landed projectile delivery, one signal")
	if _deliveries.size() == 1:
		assert_eq(_deliveries[0][0], hull, "the signal names the hull the hit landed on")
		assert_gt(float(_deliveries[0][1]), 0.0, "and the damage that landed")
	assert_true(marker.visible, "the projectile's delivery flashes the marker")


func _on_delivery(target: Object, amount: float) -> void:
	_deliveries.append([target, amount])


## ---------------------------------------------------------------------------
## A2 (L56) - the ram reads: foley + one spark at the contact
## ---------------------------------------------------------------------------


## The player's monitor against a hull: the hull foley plays and one chip burst draws
## at the contact point (the player's own radius along the pair's line).
func test_a2_a_player_ram_against_a_hull_plays_foley_and_sparks() -> void:
	var npc := _spawn_hull(_ship.global_position + Vector2(60.0, 0.0))
	var npc_body := npc.call(&"impact_body") as RigidBody2D
	var player_body := _ship.call(&"impact_body") as RigidBody2D
	if npc_body == null or player_body == null:
		assert_true(false, "both hulls carry a body")
		return
	## Heavier hull = the authority, so the player's monitor is the side that resolves
	## the pair (`PlayerShip.ram_authority`).
	npc_body.mass = player_body.mass * 0.5
	_ship.global_position = Vector2.ZERO
	npc.global_position = Vector2(60.0, 0.0)
	_ship.set(&"_last_velocity", Vector2(200.0, 0.0))
	npc.set(&"_last_velocity", Vector2.ZERO)
	var before := _fx_count(_scene, CHIP_FRAME)
	_ship.call(&"_on_hull_body_entered", npc_body)
	assert_true(_played_impact(&"sfx_impact_hull"), "a hull ram plays S4's hull foley")
	assert_eq(_fx_count(_scene, CHIP_FRAME), before + 1, "and one contact spark")
	var spark := _last_fx(_scene, CHIP_FRAME)
	if spark != null:
		var radius := float(_ship.call(&"_hull_radius"))
		var expected := Vector2.ZERO + Vector2.RIGHT * radius
		assert_true(
			(spark as Node2D).global_position.distance_to(expected) < 0.01,
			"the spark lands on the hull's own surface point (%.2f, %.2f)"
			% [(spark as Node2D).global_position.x, (spark as Node2D).global_position.y]
		)


## The player's monitor against a rock: the rock cue and the same spark.
func test_a2_a_player_ram_against_a_rock_plays_the_rock_cue() -> void:
	var rock := _rock(_scene)
	_ship.global_position = Vector2.ZERO
	rock.global_position = Vector2(60.0, 0.0)
	rock.linear_velocity = Vector2.ZERO
	_ship.set(&"_last_velocity", Vector2(200.0, 0.0))
	var before := _fx_count(_scene, CHIP_FRAME)
	_ship.call(&"_on_hull_body_entered", rock)
	assert_true(_played_impact(&"sfx_impact_rock"), "a rock ram plays S4's rock cue")
	assert_eq(_fx_count(_scene, CHIP_FRAME), before + 1, "and one contact spark")


## The NPC's own monitor: the same two pieces, measured from its side of the pair.
func test_a2_an_npc_ram_reads_too() -> void:
	var npc := _spawn_hull(_ship.global_position + TARGET_OFFSET)
	var rock := _rock(_scene)
	npc.global_position = Vector2.ZERO
	rock.global_position = Vector2(60.0, 0.0)
	rock.linear_velocity = Vector2.ZERO
	npc.set(&"_last_velocity", Vector2(200.0, 0.0))
	var before := _fx_count(_scene, CHIP_FRAME)
	npc.call(&"_on_body_entered", rock)
	assert_true(_played_impact(&"sfx_impact_rock"), "an NPC ram plays the rock cue")
	assert_eq(_fx_count(_scene, CHIP_FRAME), before + 1, "and one contact spark")
	var spark := _last_fx(_scene, CHIP_FRAME)
	if spark != null:
		var at := (spark as Node2D).global_position
		assert_true(
			at.x > 0.0 and at.x < 60.0 and absf(at.y) < 1.0,
			"the spark sits on the npc-rock line (%.2f, %.2f)" % [at.x, at.y]
		)


## ---------------------------------------------------------------------------
## A3 (L51 / tick T-feel-4) - the flash's mouth at the nose, the shot at its mount
## ---------------------------------------------------------------------------


## The flash's mouth sits on the hull's own nose (`nose_point`: the hardpoint map's bow
## band), while the shot still leaves from its pinned mount - the flash/shot desync the
## tick accepts.
func test_a3_the_flash_mouth_anchors_at_the_nose() -> void:
	_fire_cannon()
	var flash := _flash_of(_guns)
	assert_true(flash != null, "a released shot spawns the flash")
	if flash == null:
		return
	var mouth: Vector2 = flash.position + (WeaponScript.FLASH_MUZZLE_PX * flash.scale.x).rotated(
		flash.rotation
	)
	var nose_local: Vector2 = _guns.to_local(_ship.to_global(_ship.call(&"nose_point")))
	var nose_world: Vector2 = _ship.to_global(_ship.call(&"nose_point"))
	assert_true(
		mouth.distance_to(nose_local) < 0.01,
		"the flash's mouth anchors at the nose (%.2f, %.2f vs %.2f, %.2f)"
		% [mouth.x, mouth.y, nose_local.x, nose_local.y]
	)
	assert_gt(nose_local.x, 5.0, "and the nose is forward of the hull's middle")
	var shot := _last_shot()
	assert_true(shot != null, "the shot exists")
	if shot == null:
		return
	var spawn: Vector2 = _guns.call(&"muzzle_position", 0)
	assert_true(
		shot.global_position.distance_to(spawn) < 0.01,
		"the shot still spawns at the pinned mount (rule 1)"
	)
	if ShipFitScript.is_mapped(StringName(_ship.get(&"_hull_id"))):
		assert_gt(
			mouth.distance_to(_guns.to_local(spawn)),
			1.0,
			"and flash and shot genuinely desync on a mapped hull"
		)
		## The mouth is a world point on the bow, not a hull-local constant that missed
		## a rotation.
		assert_true(
			nose_world.distance_to(_ship.global_position) > 5.0,
			"the anchor is a world-space bow point"
		)


## ---------------------------------------------------------------------------
## A4 (L52/L65) - verify-only: the mining chip event already draws its burst
## ---------------------------------------------------------------------------


## `mining_laser.gd:_apply_cycle`'s shipped read: one realized unit plays S8's chip cue
## and draws FX_SPEC section 1.6's chip-sparks burst inside its own scatter disc, at the
## 40 u row both beams share.
func test_a4_the_mining_chip_event_draws_the_burst_beside_its_cue() -> void:
	var laser := MiningLaserScene.instantiate() as Node2D
	_scene.add_child(laser)
	_roots.append(laser)
	var rock := _rock(_scene)
	laser.set(&"_target", rock)
	laser.set(&"_hit_point", rock.global_position)
	var before := _fx_count(_scene, CHIP_FRAME)
	var drawn := before
	for _cycle in 5:
		laser.call(&"_apply_cycle")
		drawn = _fx_count(_scene, CHIP_FRAME)
		if drawn > before:
			break
	assert_eq(drawn, before + 1, "one chip burst on the cycle that realizes a unit")
	assert_true(_played_impact(MiningLaserScript.CHIP_CUE), "beside S8's chip cue")
	var spark := _last_fx(_scene, CHIP_FRAME)
	if spark != null:
		assert_true(
			(spark as Node2D).global_position.distance_to(rock.global_position)
			<= MiningLaserScript.HIT_FX_JITTER_MAX,
			"the burst stays inside FX_SPEC 1.6's own scatter disc"
		)
	print(
		(
			"[S22B1] A4 chip burst=%s cue=%s world=%.1f fps=%.1f"
			% [
				_fx_count(_scene, CHIP_FRAME),
				_played_impact(MiningLaserScript.CHIP_CUE),
				float(ProjectileScript.FEEDBACK[&"chip"][&"world"]),
				float(ProjectileScript.FEEDBACK[&"chip"][&"fps"]),
			]
		)
	)


## ---------------------------------------------------------------------------
## A8 (L55) - verify-only: the low-hull arcs' ticked random cadence
## ---------------------------------------------------------------------------


## Below 25 % hull the arcs fire at the ticked random interval and the constants hold
## the ticked pair; the 4.0 s proposal does not ship.
func test_a8_the_low_hull_arcs_hold_the_ticked_cadence() -> void:
	assert_eq(PlayerShipScript.ARC_INTERVAL_MIN, 1.6, "the ticked floor")
	assert_eq(PlayerShipScript.ARC_INTERVAL_MAX, 2.6, "the ticked ceiling")
	assert_eq(PlayerShipScript.ARC_SEED, 20260921, "the shipped determinism seed")
	_state.call(&"set_hull", float(_state.hull_max) * 0.20)
	_ship.set(&"_arc_clock", 0.0)
	_ship.set(&"_arc_next", 0.0)
	_ship.set(&"_arc_count", 0)
	var draws: Array[float] = []
	for _step in 6:
		_ship.call(&"_update_damage_arcs", 3.0)
		draws.append(float(_ship.call(&"arc_interval")))
	assert_eq(int(_ship.call(&"arc_count")), 6, "one arc per expiry, one redraw each")
	assert_eq(_fx_count(_ship, ARC_FRAME), 6, "and six arc bursts drew")
	for draw: float in draws:
		assert_true(
			draw >= 1.6 and draw <= 2.6, "every drawn interval is inside 1.6-2.6 (%.3f)" % draw
		)
	assert_true(
		draws.size() > 1 and not is_equal_approx(draws[0], draws[draws.size() - 1]),
		"the cadence draws are random, not a constant"
	)
	print("[S22B1] A8 arcs=%d intervals=%s" % [int(_ship.call(&"arc_count")), draws])


## ---------------------------------------------------------------------------
## A12 (L70 / tick T-feel-6) - the tool slot reads its ModuleCatalog name
## ---------------------------------------------------------------------------


## A family-less tool cell (`w_mining`) labels the readout with the catalogue's own
## name, and a firing family keeps the pre-wave label.
func test_a12_a_tool_slot_reads_its_module_catalog_name() -> void:
	_hud.call(
		&"set_hull_slots",
		&"ship_vanguard",
		[
			{
				&"slot": &"weapons",
				&"index": 0,
				&"module": &"w_laser",
				&"battery": 1,
				&"position": 0,
				&"selectable": true,
			},
			{
				&"slot": &"weapons",
				&"index": 1,
				&"module": &"w_mining",
				&"battery": 2,
				&"position": 1,
				&"selectable": true,
			},
		]
	)
	_hud.call(&"_on_weapon_changed", 1, &"", 0, 0)
	var label := _hud.get(&"_ammo_label") as Label
	assert_true(label != null, "the readout label exists")
	if label == null:
		return
	var tool_name := String(ModuleCatalogScript.module(&"w_mining").get(&"name", ""))
	assert_eq(tool_name, "Mining Laser", "the catalogue's own name")
	assert_true(
		label.text.begins_with(tool_name),
		"a tool slot labels by its ModuleCatalog name (%s)" % label.text
	)
	_hud.call(&"_on_weapon_changed", 0, &"laser", 12, 120)
	assert_true(
		label.text.begins_with("Laser MkII"),
		"and a firing family keeps the family label (%s)" % label.text
	)


## ---------------------------------------------------------------------------
## A13 (FX-1 / FX-2a-e / T-feel-7) - verify-only: the pins against the code
## ---------------------------------------------------------------------------


## Every FX-2 pin, read off the owners that ship them: the trail, the mine, the plume,
## the chip and the arc, plus FX-1's playback row and T-feel-7's measured bolt sizes.
func test_a13_every_fx_pin_matches_the_shipped_code() -> void:
	var trail: Dictionary = ProjectileScript.SHEETS[&"rocket"]
	assert_eq(float(trail[&"fps"]), 12.0, "FX-2a: the trail runs at 12 FPS")
	assert_true(bool(trail[&"loop"]), "FX-2a: and loops")
	assert_eq(float(trail[&"world"]), 48.0, "FX-2a: at 48 u")
	assert_eq(float(ProjectileScript.SHEETS[&"mine"][&"world"]), 22.0, "FX-2b: the mine at 22 u")

	assert_eq(ProjectileScript.PLUME_AMOUNT, 16, "FX-2c: plume amount")
	assert_eq(ProjectileScript.PLUME_LIFETIME, 1.4, "FX-2c: plume lifetime")
	assert_eq(ProjectileScript.PLUME_PREPROCESS, 0.6, "FX-2c: plume preprocess")
	assert_eq(ProjectileScript.PLUME_RADIUS, 14.0, "FX-2c: plume radius")
	assert_eq(ProjectileScript.PLUME_SPREAD, 25.0, "FX-2c: plume spread")
	assert_eq(ProjectileScript.PLUME_SPEED_MIN, 8.0, "FX-2c: plume speed floor")
	assert_eq(ProjectileScript.PLUME_SPEED_MAX, 24.0, "FX-2c: plume speed ceiling")
	assert_eq(ProjectileScript.PLUME_SCALE_MIN, 0.5, "FX-2c: plume scale floor")
	assert_eq(ProjectileScript.PLUME_SCALE_MAX, 1.1, "FX-2c: plume scale ceiling")
	assert_eq(
		float(ProjectileScript.FEEDBACK[&"chip"][&"world"]), 40.0, "FX-2d: the chip at 40 u"
	)
	assert_eq(float(ProjectileScript.FEEDBACK[&"arc"][&"world"]), 40.0, "FX-2d: the arc at 40 u")
	assert_eq(float(ProjectileScript.FEEDBACK[&"chip"][&"fps"]), 20.0, "FX-1: chip playback")
	assert_eq(
		(ProjectileScript.FEEDBACK[&"chip"][&"frames"] as Array).size(),
		4,
		"FX-1: four playback cells (3-object master, staged re-cut)"
	)
	assert_eq(float(ProjectileScript.SHEETS[&"bolt"][&"world"]), 64.0, "T-feel-7: the light bolt")
	assert_eq(float(ProjectileScript.SHEETS[&"slug"][&"world"]), 96.0, "T-feel-7: the medium bolt")
	print(
		(
			"[S22B1] A13 trail=%.1f/loop=%s/%.1f mine=%.1f plume=%.1f/%.1f/%.1f chip=%.1f arc=%.1f bolt=%.1f slug=%.1f"
			% [
				float(trail[&"fps"]),
				str(trail[&"loop"]),
				float(trail[&"world"]),
				float(ProjectileScript.SHEETS[&"mine"][&"world"]),
				ProjectileScript.PLUME_AMOUNT,
				ProjectileScript.PLUME_LIFETIME,
				ProjectileScript.PLUME_RADIUS,
				float(ProjectileScript.FEEDBACK[&"chip"][&"world"]),
				float(ProjectileScript.FEEDBACK[&"arc"][&"world"]),
				float(ProjectileScript.SHEETS[&"bolt"][&"world"]),
				float(ProjectileScript.SHEETS[&"slug"][&"world"]),
			]
		)
	)


## ---------------------------------------------------------------------------
## Fixtures and readers
## ---------------------------------------------------------------------------


## One trigger frame on the real component: a fresh cannon fit, aimed 300 u to starboard,
## released once (the `test_weapon_fx_f1.gd` pattern). The shot and the flash are then
## found by `_last_shot` / `_flash_of`.
func _fire_cannon() -> void:
	var ids: Array[StringName] = [&"cannon"]
	_guns.call(&"set_fitted", ids)
	_guns.call(&"set_batteries", [])
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", _guns.global_position + Vector2(300.0, 0.0))
	_guns.call(&"set_firing", true)
	_guns.call(&"tick", 0.016)
	_guns.call(&"set_firing", false)


func _flash_of(guns: Node) -> AnimatedSprite2D:
	for child: Node in guns.get_children():
		var sprite := child as AnimatedSprite2D
		if sprite != null:
			return sprite
	return null


## The live shot whose source is the player's hull, or null.
func _last_shot() -> Node2D:
	if _ship == null:
		return null
	for node: Node in _tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		var shot := node as Node2D
		if shot != null and shot.has_method(&"source") and shot.call(&"source") == _ship:
			return shot
	return null


func _free_shots() -> void:
	if _ship == null or not is_instance_valid(_ship):
		return
	for node: Node in _tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		if node.has_method(&"source") and node.call(&"source") == _ship:
			node.free()


## How many live effect nodes under `root` draw `sheet` as their first frame.
func _fx_count(root: Node, sheet: String) -> int:
	var count := 0
	for child: Node in root.get_children():
		var animated := child as AnimatedSprite2D
		if animated == null or animated.sprite_frames == null:
			continue
		if not animated.sprite_frames.has_animation(FxScript.ANIMATION):
			continue
		var texture := animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
		if texture != null and texture.resource_path == sheet:
			count += 1
	return count


## The last effect node under `root` drawing `sheet`.
func _last_fx(root: Node, sheet: String) -> Node:
	var found: Node = null
	for child: Node in root.get_children():
		var animated := child as AnimatedSprite2D
		if animated == null or animated.sprite_frames == null:
			continue
		if not animated.sprite_frames.has_animation(FxScript.ANIMATION):
			continue
		var texture := animated.sprite_frames.get_frame_texture(FxScript.ANIMATION, 0)
		if texture != null and texture.resource_path == sheet:
			found = child
	return found


## Whether `cue` (or one of its pool's takes) was the last thing the manager played -
## the same read `test_weapon_fx_f2.gd` uses, tolerant of the pool's take resolution.
func _played_impact(cue: StringName) -> bool:
	var audio := _audio()
	if audio == null:
		return false
	var played := StringName(audio.call(&"last_sfx"))
	if played == cue:
		return true
	return AudioScript.CUE_POOLS.get(cue, {}).get(&"takes", []).has(played)


func _audio() -> Node:
	return _tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))


## A real NPC hull of the shipped registry, placed by hand (the wiring suite's fixture).
func _spawn_hull(position: Vector2) -> Node2D:
	var hull: Node2D = NpcShipScript.new()
	hull.name = "SuitePirate"
	_scene.add_child(hull)
	hull.global_position = position
	hull.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"home": position, &"space_owner": &"concord"}
	)
	_roots.append(hull)
	return hull


## A real rock, inside the tree (its own body is the node itself).
func _rock(parent: Node2D) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	parent.add_child(rock)
	rock.call(&"setup", ROCK_MINERAL, 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	_roots.append(rock)
	return rock


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _profile() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


## The fixture's fit and packs, written before the scene is instantiated and handed back
## in `suite_teardown`, so the account ends this suite exactly as it started.
func _stage_fixture() -> void:
	var profile := _profile()
	if profile == null:
		return
	_previous_fits = profile.call(&"fits")
	_previous_ammo = (profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_rem = (profile.get(&"_ammo_rem") as Dictionary).duplicate(true)
	profile.call(&"set_fit", StringName(profile.call(&"active_ship")), FIXTURE_FIT)
	var packs: Dictionary = _previous_ammo.duplicate(true)
	var cargo: Dictionary = _previous_cargo.duplicate(true)
	var rem: Dictionary = _previous_rem.duplicate(true)
	for family: StringName in FIXTURE_FAMILIES:
		packs[family] = int(FIXTURE_PACKS[family])
		rem.erase(family)
		cargo.erase(family)
		var item_id := StringName(profile.call(&"ammo_item_id", family))
		if item_id != &"":
			cargo.erase(item_id)
	profile.set(&"_ammo", packs)
	profile.set(&"_cargo", cargo)
	profile.set(&"_ammo_rem", rem)
	profile.call(&"flush")


func _restore_fixture() -> void:
	var profile := _profile()
	if profile == null:
		return
	profile.call(&"set_fits", _previous_fits)
	profile.set(&"_ammo", _previous_ammo)
	profile.set(&"_cargo", _previous_cargo)
	profile.set(&"_ammo_rem", _previous_rem)
	profile.call(&"flush")
	_previous_fits = {}
	_previous_ammo = {}
	_previous_cargo = {}
	_previous_rem = {}


## Where the scene may enter the tree (the runner's own `_ready` has `/root` busy).
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root
