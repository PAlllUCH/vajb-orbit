@tool
extends McpTestSuite
## Suite s5_hardpoints: AC5 and AC6 of the S5 wave -- the per-hull measured hardpoint map
## and the gunnery built on it.
##
## The law is 09 section 11 (hardpoints + tracking), CONTRACTS section 17 (the J4 pin) and
## the wave brief; the acceptance this suite measures:
##
##  - **AC5, the nine rows resolve** -- `ShipFit.HARDPOINTS` carries a row for each of the
##    nine player hulls, each with all four thruster rows and one weapon mount per W cell,
##    every number inside its own render's canvas; a hull with no map (every NPC) answers
##    `{}` and keeps 09 section 8's derivation edge for edge.
##  - **AC5, the FX anchors read the map** -- `PlayerShip.thruster_anchors(mode)` answers
##    the map's row at the sprite's own scale, `weapon_mount(i)` the map's mount, and the
##    frame's flags follow the stick: thrust lights the rear row, brake/retro the front,
##    strafe the side it points at, a coast the rear row on the ratio's floor.
##  - **AC6, tracking** -- a 180 deg/s barrel measurably out-runs a 60 deg/s one (measured
##    angles below), a travelling shot leaves its mount along its barrel's **current
##    facing**, and a beam connects only inside `TRACK_TOLERANCE := 5.0 deg`.
##
## The numbers this suite prints are the wave's readings; the report
## (`.agents/gen/slices/S5-playtest-fixes/S5-J4_report.md`) carries them beside the
## probe's measured table. The map itself is `tests/probe_s5_hardpoints.gd`'s output --
## this suite never re-measures the art, it checks what the table says against the renders
## it names and against the runtime seams that read it.

const FitData := preload("res://game/ship_fit.gd")
const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")

const TAG := "[s5-hardpoints]"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const AUDIO_SERVICE: StringName = &"AudioManager"

## The nine player hulls, the map's key set (08 section 2's own nine).
const HULLS: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_corvette",
	&"ship_freighter",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]
## A hull with no grid and therefore no row: the fallback's own case (09 section 11's
## reversal).
const NPC_HULL: StringName = &"ship_swarmer"
## The map's rows, in the order the frame unions them.
const MODES: Array[StringName] = [&"rear", &"front", &"left", &"right"]
const RENDER_PATH := "res://assets/ships/ship_%s_side.png"
const SPRITE_NODE: StringName = &"Hull"

## The families the tracking row distinguishes, and the two the lag test pits against each
## other: a laser's 180 deg/s against a rocket's 60.
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const MINE: StringName = &"w_mine"
const AIM_DISTANCE := 400.0
const FRAME := 1.0 / 60.0

var _host: Node = null
var _holder: Node2D = null
var _guns: Node2D = null
var _state: PlayerState = null
var _staged: Array[Node] = []
var _pool_state: Dictionary = {}
var _had_pool_state := false


## A hull stub that answers the two seams `WeaponComponent` reads off its host: the mount
## table (S5) and the recoil sink every hull already had. Its mounts are the fixture's, so
## a test can place a barrel anywhere and read where the shot left.
class StubHull extends Node2D:
	var mounts: Array = []


	var recoils := 0


	func apply_recoil(_impulse: Vector2, _mass: float) -> void:
		recoils += 1


	func weapon_mount(index: int) -> Dictionary:
		if index < 0 or index >= mounts.size():
			return {}
		return mounts[index]


## A target that records what a beam's frame delivered (the same two-argument shape
## `_deliver` calls), so "the beam connected" is a number rather than a reading of the
## damage pipeline.
class DamageSink extends Node2D:
	var total := 0.0
	var hits := 0


	func take_damage(amount: float, _bypass_shield := false) -> void:
		total += amount
		hits += 1


## A component whose beam resolves on a target without a physics world: only the targeting
## seam is replaced, so the arming, the tracking, the tolerance gate, the per-barrel spend
## and the delivery are the shipped code's.
class BeamTargetSpy extends "res://game/weapons.gd":
	var target: Node2D = null


	func _beam_target(from: Vector2, _to: Vector2) -> Dictionary:
		if target == null or not is_instance_valid(target):
			return {}
		return {
			&"point": target.global_position,
			&"collider": target,
			&"distance": from.distance_to(target.global_position),
			&"projectile": false,
		}


func suite_name() -> String:
	return "s5_hardpoints"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed")
		return
	_host = tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _host == null:
		fail_setup("the PlayerProfile autoload is the tree host these rigs hang from")
		return
	_save_pools()


func suite_teardown() -> void:
	_restore_pools()


func setup() -> void:
	_free_rig()


func teardown() -> void:
	_free_rig()


## ------------------------------------------------------------------ fixtures


## The audio pools' round-robin cursors, saved and restored around the suite: the rigs fire
## real cues and `test_weapon_fx_f1` asserts the laser pool's take order a few suites later
## (the same hygiene `test_engine2_weapons` carries).
func _save_pools() -> void:
	_pool_state = {}
	_had_pool_state = false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var audio := tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_state = true
	_pool_state = (cursors as Dictionary).duplicate()


func _restore_pools() -> void:
	if not _had_pool_state:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var audio := tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_state, true)
	_pool_state = {}
	_had_pool_state = false


func _free_rig() -> void:
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
	if _holder != null and is_instance_valid(_holder):
		_holder.free()
	_holder = null
	_guns = null
	_state = null


## A component on a host, in a tree, with the fit under test and one pooled account.
## `hull` is null for the pre-S5 shape (a bare holder: no mounts, no hull id), a
## `StubHull` for a fixture's own mount table, or a real `PlayerShip` for a measured map.
func _rig(ids: Array, hull: Node2D = null, spy := false) -> Node2D:
	_state = PlayerStateScript.new()
	_state.call(&"setup")
	if hull != null:
		_holder = hull
	else:
		_holder = Node2D.new()
		_holder.name = &"S5HardpointRig"
	_hoster(_holder)
	_staged.append(_holder)
	_guns = (BeamTargetSpy.new() if spy else WeaponScript.new()) as Node2D
	_guns.name = &"WeaponComponent"
	_holder.add_child(_guns)
	_guns.call(&"setup", null, _state)
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	_guns.call(&"set_fitted", fit)
	return _guns


## Puts a fixture node under the suite's tree host once (a `StubHull` or a hull scene may
## already carry the caller's own parent).
func _hoster(node: Node2D) -> void:
	if node.get_parent() == null:
		_host.add_child(node)
	if not _staged.has(node):
		_staged.append(node)


## A launched hull scene with its hull id set, hung under the suite's host.
func _ship(hull_id: StringName) -> Node2D:
	var ship := PlayerShipScene.instantiate() as Node2D
	_host.add_child(ship)
	_staged.append(ship)
	ship.call(&"set_hull_id", hull_id)
	return ship


## `_state.set_ammo` for a family's slot, so a travelling test can fire.
func _load(weapon: StringName, rounds: int) -> void:
	_state.call(&"set_ammo", WeaponScript.ammo_slot(weapon), rounds)


func _shots() -> Array[Node]:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	return tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP)


func _clear_shots() -> void:
	for shot: Node in _shots():
		if is_instance_valid(shot):
			shot.free()


## `n` frames of `delta`, the shape every weapon test steps with.
func _step(guns: Node2D, frames: int, delta := FRAME) -> void:
	for _frame in frames:
		guns.call(&"tick", delta)


## ------------------------------------------------------------------ AC5: the table


## The pin's first half: a row per player hull, all four thruster rows present, one weapon
## mount per W cell, and every value inside the canvas of the render it was measured from
## -- so a row can never be silently invented. The NPC hulls have no row at all, which is
## what turns the fallback on.
func test_the_map_covers_the_nine_player_hulls_and_no_others() -> void:
	for hull_id: StringName in HULLS:
		assert_true(FitData.is_mapped(hull_id), "%s has a measured map" % hull_id)
		var map: Dictionary = FitData.hardpoints(hull_id)
		var thrusters: Dictionary = map.get(&"thrusters", {})
		for mode: StringName in MODES:
			var row: Array[Vector2] = FitData.thruster_points(hull_id, mode)
			assert_true(row.size() > 0, "%s.%s carries anchors" % [hull_id, mode])
		var mounts: Array = FitData.weapon_mounts(hull_id)
		var cells := FitData.slot_capacity(hull_id, &"weapons")
		assert_eq(mounts.size(), cells, "%s carries one mount per W cell" % hull_id)
		var canvas := _render_size(hull_id)
		assert_true(canvas.x > 0.0, "%s's render is on disk" % hull_id)
		var half := canvas * 0.5
		for mode: StringName in MODES:
			for point: Vector2 in FitData.thruster_points(hull_id, mode):
				assert_true(
					absf(point.x) <= half.x and absf(point.y) <= half.y,
					"%s.%s %s is inside its render's canvas" % [hull_id, mode, str(point)]
				)
		for index in mounts.size():
			var mount: Dictionary = mounts[index]
			var pos: Vector2 = mount.get(&"pos", Vector2.ZERO)
			var facing := float(mount.get(&"facing", 0.0))
			assert_true(
				absf(pos.x) <= half.x and absf(pos.y) <= half.y,
				"%s mount %d %s is inside its render's canvas" % [hull_id, index, str(pos)]
			)
			assert_true(
				absf(facing) < PI, "%s mount %d's facing %.3f rad is a direction" % [
					hull_id, index, facing
				]
			)
		assert_eq(
			FitData.weapon_mount(hull_id, mounts.size()).size(),
			0,
			"%s answers no mount past its last W cell" % hull_id
		)
		print(
			"%s %-14s rear=%d front=%d left=%d right=%d mounts=%d canvas=%s" % [
				TAG,
				hull_id,
				FitData.thruster_points(hull_id, &"rear").size(),
				FitData.thruster_points(hull_id, &"front").size(),
				FitData.thruster_points(hull_id, &"left").size(),
				FitData.thruster_points(hull_id, &"right").size(),
				mounts.size(),
				str(canvas),
			]
		)
	assert_false(FitData.is_mapped(NPC_HULL), "an NPC hull carries no measured map")
	assert_eq(FitData.hardpoints(NPC_HULL).size(), 0, "and answers an empty map")


## The other half of the pin: `weapon_mounts[i]` is what W cell `i` binds, in the hull's
## own row-major cell order (09 section 4 item 5) -- the last cell's mount is a different
## place from the first's on every hull that carries more than one W cell.
func test_each_w_cell_binds_its_own_measured_mount() -> void:
	var multi := 0
	for hull_id: StringName in HULLS:
		var mounts: Array = FitData.weapon_mounts(hull_id)
		if mounts.size() < 2:
			continue
		multi += 1
		var positions: Array[Vector2] = []
		for index in mounts.size():
			var one := FitData.weapon_mount(hull_id, index)
			assert_eq(
				(one.get(&"pos", Vector2.ZERO) as Vector2),
				(mounts[index].get(&"pos", Vector2.ZERO) as Vector2),
				"%s mount %d is the same entry both reads name" % [hull_id, index]
			)
			positions.append(one.get(&"pos", Vector2.ZERO))
		var distinct := {}
		for point: Vector2 in positions:
			distinct[point] = true
		print("%s %-14s cells=%d distinct=%d" % [TAG, hull_id, mounts.size(), distinct.size()])
		assert_true(
			distinct.size() >= 2,
			"%s's %d W cells do not all bind the same point" % [hull_id, mounts.size()]
		)
	assert_true(multi >= 5, "at least five hulls carry more than one W cell")


## 09 section 11's reversal, measured: a hull with no row keeps the pre-S5 shape exactly --
## the section 8 derivation for a hull with a grid, the single tail point for a hull with
## no grid -- and the frame answers no per-anchor flags, so the sync falls back to its own
## single `active`.
func test_a_hull_without_a_map_keeps_the_section_8_derivation() -> void:
	var ship := _ship(NPC_HULL)
	var anchors: Array = ship.call(&"thruster_anchors")
	assert_eq(anchors.size(), 1, "a hull with no grid answers the one tail point")
	var radius := float(ship.call(&"_hull_radius"))
	assert_true(radius > 0.0, "off the hull's own art-derived radius")
	assert_true(
		(anchors[0] as Vector2).is_equal_approx(Vector2(-radius * 0.55, 0.0)),
		"the shipped tail anchor, unchanged"
	)
	for mode: StringName in MODES:
		var same: Array = ship.call(&"thruster_anchors", mode)
		assert_eq(same.size(), 1, "every mode answers the same derived row for a hull with no map")
	var frame: Dictionary = ship.call(&"thruster_frame", true, 1.0, 0.0)
	assert_eq((frame[&"anchors"] as Array).size(), 1, "the frame unions the same row")
	assert_eq((frame[&"flags"] as Array).size(), 0, "and asks no per-anchor flags")
	assert_true(
		(ship.call(&"weapon_mount", 0) as Dictionary).is_empty(),
		"and no weapon mount: the component keeps its own origin"
	)


## ---------------------------------------------------------- AC5: the FX seam


## "the thruster_anchors() seam resolves to HARDPOINTS": the map's row, scaled by the
## sprite's own scene scale, for every mode -- and the default mode is the rear row, so
## every pre-S5 caller reads thrust.
func test_the_fx_anchors_read_the_map() -> void:
	var ship := _ship(&"ship_vanguard")
	var sprite := ship.get_node_or_null(NodePath(SPRITE_NODE)) as Sprite2D
	assert_true(sprite != null, "the hull scene carries its artwork node")
	var scale: Vector2 = sprite.scale
	for mode: StringName in MODES:
		var measured: Array[Vector2] = FitData.thruster_points(&"ship_vanguard", mode)
		var anchors: Array = ship.call(&"thruster_anchors", mode)
		assert_eq(anchors.size(), measured.size(), "%s answers the map's own row" % mode)
		for index in anchors.size():
			assert_true(
				(anchors[index] as Vector2).is_equal_approx(measured[index] * scale),
				"%s anchor %d is its measured px at the sprite's scale" % [mode, index]
			)
	var default_row: Array = ship.call(&"thruster_anchors")
	assert_eq(
		default_row.size(),
		FitData.thruster_points(&"ship_vanguard", &"rear").size(),
		"the default mode is thrust's own row"
	)
	var mounts: Array = FitData.weapon_mounts(&"ship_vanguard")
	for index in mounts.size():
		var one: Dictionary = ship.call(&"weapon_mount", index)
		assert_true(
			(one[&"pos"] as Vector2).is_equal_approx(
				(mounts[index].get(&"pos", Vector2.ZERO) as Vector2) * scale
			),
			"mount %d is its measured px at the sprite's scale" % index
		)
		assert_eq(
			float(one[&"facing"]),
			float(mounts[index].get(&"facing", 0.0)),
			"and its facing is the measured radians, unchanged by the frame's scale"
		)


## The stick picks the row: thrust lights the rear anchors, brake/retro the front ones,
## strafe the side it points at, and a coast (no stick, ratio above the section's floor)
## the rear row -- the pre-S5 drift read. The union's shape never changes, so the emitters
## never rebuild on a mode change.
func test_the_frame_lights_the_row_the_stick_asks_for() -> void:
	var ship := _ship(&"ship_destroyer")
	var rear := FitData.thruster_points(&"ship_destroyer", &"rear").size()
	var front := FitData.thruster_points(&"ship_destroyer", &"front").size()
	var left := FitData.thruster_points(&"ship_destroyer", &"left").size()
	var right := FitData.thruster_points(&"ship_destroyer", &"right").size()
	var expected := rear + front + left + right
	ship.call(&"set_speed_ratio", 0.0)
	var cases := [
		{&"stick": true, &"throttle": 1.0, &"strafe": 0.0, &"label": "thrust", &"range": [0, rear]},
		{
			&"stick": true,
			&"throttle": -1.0,
			&"strafe": 0.0,
			&"label": "brake/retro",
			&"range": [rear, rear + front],
		},
		{
			&"stick": false,
			&"throttle": 0.0,
			&"strafe": -1.0,
			&"label": "strafe left",
			&"range": [rear + front, rear + front + left],
		},
		{
			&"stick": false,
			&"throttle": 0.0,
			&"strafe": 1.0,
			&"label": "strafe right",
			&"range": [rear + front + left, expected],
		},
	]
	for row: Dictionary in cases:
		var frame: Dictionary = ship.call(
			&"thruster_frame", bool(row[&"stick"]), float(row[&"throttle"]), float(row[&"strafe"])
		)
		var anchors: Array = frame[&"anchors"]
		var flags: Array = frame[&"flags"]
		assert_eq(anchors.size(), expected, "%s: the union carries every row" % row[&"label"])
		assert_eq(flags.size(), expected, "%s: one flag per anchor" % row[&"label"])
		var lit := 0
		var span: Array = row[&"range"]
		var wanted := int(span[1]) - int(span[0])
		for index in flags.size():
			var inside := index >= int(span[0]) and index < int(span[1])
			if bool(flags[index]):
				lit += 1
			assert_eq(
				bool(flags[index]),
				inside,
				"%s: anchor %d is %s" % [row[&"label"], index, "lit" if inside else "dark"]
			)
		assert_eq(lit, wanted, "%s lights exactly its own row" % row[&"label"])
		print("%s frame %-12s lit=%d of %d" % [TAG, row[&"label"], lit, expected])
	## The drift case: no stick at all, but the hull is still moving -- the rear row lights
	## on the ratio's own 0.15 floor, exactly as the pre-S5 flame did.
	ship.call(&"set_speed_ratio", 0.5)
	var drift: Dictionary = ship.call(&"thruster_frame", false, 0.0, 0.0)
	var drift_flags: Array = drift[&"flags"]
	for index in drift_flags.size():
		assert_eq(
			bool(drift_flags[index]),
			index < rear,
			"a coasting hull lights the rear row only (anchor %d)" % index
		)
	ship.call(&"set_speed_ratio", 0.0)
	var still: Dictionary = ship.call(&"thruster_frame", false, 0.0, 0.0)
	for flag: Variant in (still[&"flags"] as Array):
		assert_false(bool(flag), "a hull standing still with no stick lights nothing")


## The frame end to end: the same emitter set across a mode change, and only the flagged
## anchors emitting -- the union exists so a mode change does not rebuild the trails.
func test_the_trail_sync_lights_only_the_flagged_anchors() -> void:
	var ship := _ship(&"ship_gunship")
	var rear := FitData.thruster_points(&"ship_gunship", &"rear").size()
	var total := (
		rear
		+ FitData.thruster_points(&"ship_gunship", &"front").size()
		+ FitData.thruster_points(&"ship_gunship", &"left").size()
		+ FitData.thruster_points(&"ship_gunship", &"right").size()
	)
	ship.call(&"set_speed_ratio", 0.5)
	ship.call(&"_update_thrust_feedback", true, 1.0, 0.0)
	var thrust: Array = ship.call(&"thruster_trails")
	assert_eq(thrust.size(), total, "one emitter per union anchor")
	var lit := 0
	for index in thrust.size():
		var emitter := thrust[index] as GPUParticles2D
		var on := emitter.emitting
		if on:
			lit += 1
		assert_eq(on, index < rear, "emitter %d follows the rear row's flag" % index)
	assert_eq(lit, rear, "the rear row is lit and nothing else")
	ship.call(&"_update_thrust_feedback", false, -1.0, 0.0)
	var retro: Array = ship.call(&"thruster_trails")
	assert_eq(retro.size(), total, "the same emitter set serves the retro row")
	for index in retro.size():
		var emitter := retro[index] as GPUParticles2D
		var inside := index >= rear and index < rear + FitData.thruster_points(
			&"ship_gunship", &"front"
		).size()
		assert_eq(emitter.emitting, inside, "emitter %d follows the front row's flag" % index)
		assert_eq(retro[index], thrust[index], "and it is the same node, not a rebuild")
	print("%s trail union=%d rear=%d" % [TAG, total, rear])


## ------------------------------------------------------------------ AC6: gunnery


## The taste table, one value per family, read through both spellings the tree uses (a
## weapon id and the module id the fit carries).
func test_the_track_dps_column_is_one_value_per_family() -> void:
	assert_eq(WeaponScript.track_dps_of(&"laser"), 180.0, "laser 180")
	assert_eq(WeaponScript.track_dps_of(&"cannon"), 120.0, "cannon 120")
	assert_eq(WeaponScript.track_dps_of(&"railgun"), 100.0, "railgun 100")
	assert_eq(WeaponScript.track_dps_of(&"plasma"), 75.0, "plasma 75")
	assert_eq(WeaponScript.track_dps_of(&"rocket"), 60.0, "rocket 60")
	assert_eq(WeaponScript.track_dps_of(&"mine"), 0.0, "mine fixed (no barrel to swing)")
	assert_eq(WeaponScript.track_dps_of(&"w_mining"), 150.0, "the mining tool's own 150")
	assert_eq(WeaponScript.track_dps_of(&"w_laser"), 180.0, "the module id reads its family")
	assert_eq(WeaponScript.track_dps_of(&"nonsense"), 0.0, "an unknown id has no barrel")
	assert_eq(WeaponScript.TRACK_MULT, 1.0, "the shipped taste table is unscaled")
	assert_eq(WeaponScript.TRACK_TOLERANCE, 5.0, "the beam's tolerance is the pin's 5 degrees")


## AC6's own measurement: aim at zero, let both barrels settle, then swing the aim a
## quarter turn and step half a second. The laser (180 deg/s) covers the 90 deg and
## arrives; the rocket (60 deg/s) covers a third of it and lags -- the owner's "weapons to
## not turn as fast", with the two speeds a factor of three apart.
func test_a_slow_barrel_measurably_lags_a_fast_one() -> void:
	var guns := _rig([LASER, ROCKET])
	if guns == null:
		return
	guns.call(&"set_aim_point", guns.global_position + Vector2.RIGHT * AIM_DISTANCE)
	_step(guns, 30)
	var settled_laser := float(guns.call(&"barrel_facing", 0))
	var settled_rocket := float(guns.call(&"barrel_facing", 1))
	assert_true(
		absf(settled_laser) <= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"the laser starts on the aim"
	)
	assert_true(
		absf(settled_rocket) <= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"and so does the rocket"
	)
	## The quarter turn: straight down the hull's own starboard axis becomes straight aft.
	guns.call(&"set_aim_point", guns.global_position + Vector2.DOWN * AIM_DISTANCE)
	var target := PI * 0.5
	_step(guns, 30)
	var laser := float(guns.call(&"barrel_facing", 0))
	var rocket := float(guns.call(&"barrel_facing", 1))
	var laser_error := absf(wrapf(target - laser, -PI, PI))
	var rocket_error := absf(wrapf(target - rocket, -PI, PI))
	var laser_moved := absf(wrapf(laser - settled_laser, -PI, PI))
	var rocket_moved := absf(wrapf(rocket - settled_rocket, -PI, PI))
	print(
		"%s 0.5 s after a 90 deg swing: laser moved %.1f deg (error %.1f), rocket moved %.1f deg (error %.1f)"
		% [TAG, rad_to_deg(laser_moved), rad_to_deg(laser_error), rad_to_deg(rocket_moved), rad_to_deg(rocket_error)]
	)
	assert_true(
		laser_error <= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"the 180 deg/s barrel arrived (error %.1f deg)" % rad_to_deg(laser_error)
	)
	assert_true(
		rocket_error >= deg_to_rad(50.0),
		"the 60 deg/s barrel is still visibly short (error %.1f deg)" % rad_to_deg(rocket_error)
	)
	assert_true(
		rocket_moved < laser_moved,
		"and it lagged the fast one (%.1f deg behind)" % rad_to_deg(laser_moved - rocket_moved)
	)
	assert_true(
		absf(laser_moved / maxf(rocket_moved, 0.0001) - 3.0) < 0.2,
		"the measured ratio is the table's 180/60"
	)
	## The mine is the table's fixed row: it keeps its mount's own facing however long the
	## aim sits elsewhere, while a barrel beside it swings away.
	var hull := StubHull.new()
	hull.name = &"S5MineHull"
	hull.mounts = [{&"pos": Vector2.ZERO, &"facing": 0.7}]
	var mixed := _rig([MINE, LASER], hull)
	if mixed == null:
		return
	mixed.call(&"set_aim_point", mixed.global_position + Vector2.DOWN * AIM_DISTANCE)
	_step(mixed, 30)
	assert_true(
		absf(float(mixed.call(&"barrel_facing", 0)) - 0.7) < 0.0001,
		"the fixed barrel holds its mount's 0.7 rad while the aim is a quarter turn away"
	)
	assert_true(
		absf(wrapf(PI * 0.5 - float(mixed.call(&"barrel_facing", 1)), -PI, PI))
		<= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"while the laser beside it has arrived on the aim"
	)


## The seam end to end on a real hull scene: a component mounted on a launched `PlayerShip`
## reads that hull's own map through `weapon_mount`, so its muzzle is the measured station
## scaled by the sprite's own transform -- the wiring `game.gd`'s launch performs.
func test_a_component_on_a_launched_hull_reads_the_hulls_own_map() -> void:
	var ship := _ship(&"ship_corvette")
	var guns := _rig([CANNON], ship)
	if guns == null:
		return
	_clear_shots()
	_load(CANNON, 30)
	var sprite := ship.get_node_or_null(NodePath(SPRITE_NODE)) as Sprite2D
	var scale: Vector2 = sprite.scale
	var mount: Array = FitData.weapon_mounts(&"ship_corvette")
	var muzzle: Vector2 = guns.call(&"muzzle_position", 0)
	assert_true(
		muzzle.is_equal_approx(
			ship.global_position + (mount[0].get(&"pos", Vector2.ZERO) as Vector2) * scale
		),
		"the component's first muzzle is its hull's measured mount (%s)" % str(muzzle)
	)
	guns.call(&"set_aim_point", ship.global_position + Vector2.RIGHT * AIM_DISTANCE)
	guns.call(&"set_firing", true)
	_step(guns, 1)
	var shots := _shots()
	assert_eq(shots.size(), 1, "and a released round leaves from it")
	if not shots.is_empty():
		assert_true(
			(shots[0] as Node2D).global_position.is_equal_approx(muzzle),
			"the shot's own spawn is that muzzle"
		)
	guns.call(&"set_firing", false)
	guns.call(&"tick", FRAME)


## AC6's second half: a released shot leaves **its own mount**, flying along **its own
## barrel's current facing** -- not the cursor. The fixture's hull places one mount off the
## origin with a 0.4 rad rest facing and the aim is a quarter turn away, so a shot on the
## wrong rule (aim, or origin) is unmistakable.
func test_a_travelling_shot_leaves_its_mount_along_the_barrels_facing() -> void:
	var hull := StubHull.new()
	hull.name = &"S5MountedHull"
	var mount := Vector2(12.0, -4.0)
	var rest := 0.4
	hull.mounts = [{&"pos": mount, &"facing": rest}]
	var guns := _rig([CANNON], hull)
	if guns == null:
		return
	_clear_shots()
	_load(CANNON, 30)
	guns.call(&"set_aim_point", guns.global_position + Vector2.DOWN * AIM_DISTANCE)
	guns.call(&"set_firing", true)
	_step(guns, 1)
	var shots := _shots()
	assert_eq(shots.size(), 1, "the barrel released its round")
	if shots.is_empty():
		return
	var shot := shots[0] as Node2D
	assert_true(
		shot.global_position.is_equal_approx(hull.global_position + mount),
		"the shot left the measured mount, not the hull's centre (%s)" % str(shot.global_position)
	)
	var borne := float(shot.call(&"velocity").angle())
	assert_true(
		absf(wrapf(borne - rest, -PI, PI)) < 0.05,
		"it flies along the barrel's facing (%.3f rad, the mount's own %.3f)" % [borne, rest]
	)
	print("%s shot at %s bearing %.1f deg" % [TAG, str(shot.global_position), rad_to_deg(borne)])
	guns.call(&"set_firing", false)
	guns.call(&"tick", FRAME)


## AC6's third half: the beam's `TRACK_TOLERANCE`. Aligned, it burns; swung a quarter turn
## away it keeps drawing its shaft (the barrel points there) and connects with **nothing**;
## once the barrel has swept back inside 5 degrees the damage resumes.
func test_the_beam_connects_only_inside_the_tolerance_cone() -> void:
	var guns := _rig([LASER], null, true)
	if guns == null:
		return
	var sink := DamageSink.new()
	sink.name = &"S5BeamTarget"
	_host.add_child(sink)
	_staged.append(sink)
	guns.set(&"target", sink)
	guns.call(&"set_aim_point", guns.global_position + Vector2.RIGHT * AIM_DISTANCE)
	guns.call(&"set_firing", true)
	_step(guns, 1)
	var on_target := sink.total
	assert_true(on_target > 0.0, "aligned, the beam burns (%.3f in one frame)" % on_target)
	## A quarter turn: one frame of tracking leaves the barrel ~87 deg off.
	guns.call(&"set_aim_point", guns.global_position + Vector2.DOWN * AIM_DISTANCE)
	_step(guns, 1)
	var off_aim := float(guns.call(&"barrel_facing", 0)) - PI * 0.5
	assert_true(
		absf(wrapf(off_aim, -PI, PI)) > deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"the barrel is outside the cone (%.1f deg off)" % rad_to_deg(off_aim)
	)
	assert_eq(sink.total, on_target, "and the beam connects with nothing while it swings")
	var halo := guns.get_node_or_null(NodePath(WeaponScript.BEAM_NAMES[0])) as Line2D
	assert_true(halo != null and halo.visible, "the shaft is still drawn, where the barrel points")
	## Sweep back inside the cone: 180 deg/s covers the 90 deg in half a second.
	_step(guns, 30)
	assert_true(
		sink.total > on_target,
		"the damage resumes once the barrel is back inside the tolerance"
	)
	var inside := absf(wrapf(PI * 0.5 - float(guns.call(&"barrel_facing", 0)), -PI, PI))
	print(
		"%s beam tolerance: aligned frame %.3f damage, %.1f deg off made no entry, sweep back in %.1f deg"
		% [TAG, on_target, rad_to_deg(off_aim), rad_to_deg(inside)]
	)
	assert_true(
		inside <= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"and it took the whole 0.5 s sweep to get there"
	)
	## The cone's own edge: a 3 deg error is inside the pin's 5, so it still connects.
	var edge := deg_to_rad(3.0)
	guns.call(
		&"set_aim_point",
		guns.global_position + Vector2.RIGHT.rotated(PI * 0.5 + edge) * AIM_DISTANCE
	)
	_step(guns, 1)
	assert_true(
		absf(wrapf(PI * 0.5 + edge - float(guns.call(&"barrel_facing", 0)), -PI, PI))
		<= deg_to_rad(WeaponScript.TRACK_TOLERANCE),
		"a 3 deg error is inside the 5 deg cone"
	)
	var before_edge := sink.total
	_step(guns, 1)
	assert_true(sink.total > before_edge, "so the beam still connects there")
	guns.call(&"set_firing", false)
	guns.call(&"tick", FRAME)


## The render's own canvas, so the table's px can be bounded against the art they were
## measured from (a missing render answers `Vector2.ZERO`, which the caller asserts on).
func _render_size(hull_id: StringName) -> Vector2:
	var stem := String(hull_id).trim_prefix("ship_")
	var texture := load(RENDER_PATH % stem) as Texture2D
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_width(), texture.get_height())
