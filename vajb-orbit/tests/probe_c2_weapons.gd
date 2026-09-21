extends Node2D
## C2 probe (combat/collision repair wave): what the five v1 weapon families actually
## deliver - to an NPC hull and to a rock - and what the launch fit actually installs.
##
## Contract: `.agents/gen/combat_repair_wave_task.md` (worker C2),
## `.agents/gen/owner_playtest_findings_20260921.md` (findings B/G),
## ENGINE_SPEC sections 4.1/4.2/4.3/4.4/6/13, docs/CONTRACTS.md sections 4/8.2.
##
## Rules the probe obeys, verbatim from the brief:
##   * deterministic headless scene, never a live window (`--headless`, no editor).
##   * the component's own **external trigger** (`set_firing`, never an `Input` action)
##     and the engine's fixed step (60 physics ticks/s); `set_aim_point` fixes the aim so
##     the cursor is never read. Both are the seams `weapons.gd` publishes for a probe.
##   * raw numbers per family: hull/shield pool deltas on an NPC hull, the rock's
##     `work`/`yield_units` deltas, `dry_reason()`, and the shot/dry signal counts, so an
##     empty or unfitted group can be told apart from a broken firing path.
##   * controls: a layer-1 body that *does* publish `take_damage` (positive) and one that
##     publishes nothing (negative), so "the shot never arrived" is distinguishable from
##     "the shot arrived and the sink was missing".
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000
##       (add `--fixed-fps 60` for the same output in about a second instead of ~80 s:
##        the physics delta is 1/60 either way, so only real-time pacing differs)
## Signal: the [C2] lines; the last line is `[C2] done ...`. Nothing is fixed here.

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const CatalogScript := preload("res://game/station_catalog.gd")
const DamageScript := preload("res://game/damage.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")

const TAG := "[C2]"
const SHIELD_UP: StringName = &"up"
const SHIELD_DOWN: StringName = &"down"

## The NPC target is the shipping hull + the shipping launch fit, so its pools are the
## game's own (ShipFit resolves them; nothing is transcribed here).
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const NPC_BODY_NODE: StringName = &"HullBody"

## The rock: a Medium look with ore, so `work` accumulates and `yield_units` can fall.
## The matrix rock carries far more units than any single case chips (a 5-unit rock is
## emptied by one second of plasma, so the fixture would not survive its own case);
## `ROCK_UNITS_SMALL` is the 5-unit rock the crack case uses on purpose, because "a
## weapon cracks a rock" is itself a measurement.
const ROCK_MINERAL: StringName = &"iron"
const ROCK_UNITS := 100
const ROCK_UNITS_SMALL := 5
const ROCK_SIZE_MEDIUM := 1

const HULL_DISTANCE := 200.0
const ROCK_DISTANCE := 200.0
## The mine is stationary with a 60 u proximity trigger, so its fixture stands close.
const MINE_DISTANCE := 40.0

## One row per family: the frames each fixture is fired for and the stand-off distance.
## Frames are the family's own cadence read from the table (`interval_of`, `arm`), not a
## feel number: a beam is fired 1 s, a kinetic 3 s (its 0.6 s cadence), a rocket 5 s
## (1.2 s interval + flight), a mine 2.5 s (the 2 s arm plus the trigger frame).
const FAMILIES: Array[Dictionary] = [
	{&"id": &"laser", &"frames": 60, &"distance": 200.0},
	{&"id": &"plasma", &"frames": 60, &"distance": 200.0},
	{&"id": &"cannon", &"frames": 180, &"distance": 200.0},
	{&"id": &"railgun", &"frames": 180, &"distance": 200.0},
	{&"id": &"rocket", &"frames": 300, &"distance": 200.0},
	{&"id": &"mine", &"frames": 150, &"distance": 40.0},
]

## The five v1 weapon ids in the launch panel's own order (`StationCatalog.AMMO_PACKS`
## and `PlayerState.WEAPONS` agree): the panel's "5 WEAPONS" line and the fit this probe
## fires group by group.
const V1_WEAPON_IDS: Array[StringName] = [
	&"laser", &"cannon", &"rocket", &"mine", &"plasma",
]
## The module ids for those five (the fit is a module list; `weapons.gd` normalizes).
const V1_MODULE_IDS: Array[StringName] = [
	&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma",
]

var _shots := 0
var _dry_events := 0
var _shot_ids: Array[StringName] = []
var _dry_ids: Array[StringName] = []
## Physics frames this probe stepped itself. Kept instead of `Engine.get_physics_frames()`
## because the engine's own counter also counts frames nobody awaited, which makes the
## last log line pace-dependent (real-time vs `--fixed-fps`); every measurement above is
## identical either way.
var _stepped := 0


## A hull that owns the physics seams `weapons.gd` reaches for, so the mount is the
## shipping shape (`_host()` finds `apply_recoil`; section 4.2 item 7's recoil is
## recorded here rather than discarded).
class StubHull extends Node2D:
	var recoil_calls := 0
	var last_recoil := Vector2.ZERO
	var last_mass := 0.0

	func apply_recoil(velocity: Vector2, mass: float) -> void:
		recoil_calls += 1
		last_recoil = velocity
		last_mass = mass


## The positive control: a layer-1 body (the rock layer) that publishes the pinned sink.
class SinkBody extends RigidBody2D:
	var hits := 0
	var taken := 0.0
	var last_bypass := false

	func take_damage(amount: float, bypass_shield: bool = false, ctx: Dictionary = {}) -> void:
		hits += 1
		taken += amount
		last_bypass = bypass_shield


## The negative control: a layer-1 body with no sink method at all, which is the shape
## `weapons.gd._deliver` and `Damage.apply` both answer silently - the rock's own gap,
## reproduced on a body that is not an `Asteroid`.
class BareBody extends RigidBody2D:
	pass


## A reader that publishes `shield_up()` the way `PlayerShip` does, so the plasma gate's
## read order can be measured against a sink that answers.
class ShieldReader extends Node2D:
	func shield_up() -> bool:
		return true


func _ready() -> void:
	await get_tree().process_frame
	_log_environment()
	_log_family_table()
	await _log_target_shapes()
	await _run_matrix(&"npc", SHIELD_UP)
	await _run_matrix(&"npc", SHIELD_DOWN)
	await _run_matrix(&"rock", SHIELD_UP)
	await _run_rock_crack()
	await _run_controls()
	await _run_sink_seam()
	await _run_dry_matrix()
	await _run_launch_fit()
	await _run_mount_probe()
	print("%s done stepped_frames=%d" % [TAG, _stepped])
	get_tree().quit(0)


## --- Environment ------------------------------------------------------------


func _log_environment() -> void:
	print(
		"%s ENV display=%s physics_ticks=%d physics_delta=%.6f time_scale=%.2f"
		% [
			TAG,
			DisplayServer.get_name(),
			Engine.physics_ticks_per_second,
			1.0 / float(Engine.physics_ticks_per_second),
			Engine.time_scale,
		]
	)
	print(
		"%s ENV input_action_present=%s (never read: the trigger is set_firing)"
		% [TAG, InputMap.has_action(WeaponScript.FIRE_ACTION)]
	)


func _log_family_table() -> void:
	for entry: Dictionary in FAMILIES:
		var id := StringName(entry[&"id"])
		var row := WeaponScript.row_of(id)
		print(
			"%s TABLE id=%s family=%s range=%.1f dps=%.1f draw=%.1f bypass=%s instant=%s"
			% [
				TAG,
				id,
				WeaponScript.family_of(id),
				WeaponScript.range_of(id),
				WeaponScript.dps_of(id),
				float(row.get(&"draw", 0.0)),
				str(bool(row.get(&"bypass_shield", false))),
				str(bool(row.get(&"instant", false))),
			]
		)
		print(
			"%s TABLE id=%s shot_damage=%.3f interval=%.3f chip=%.3f ammo_slot=%d"
			% [
				TAG,
				id,
				WeaponScript.shot_damage(id),
				WeaponScript.interval_of(id),
				WeaponScript.GUN_CHIP_RATE,
				WeaponScript.ammo_slot(id),
			]
		)


## The two targets' own method/layer/group surface, measured on live instances: this is
## the evidence for "which sink name the rock is missing" and for the shield reads the
## plasma bonus depends on.
func _log_target_shapes() -> void:
	var fixture := _build_fixture(&"npc", SHIELD_UP)
	var npc := fixture[&"target"] as Node
	var stats: Object = fixture[&"stats"]
	_trace_sink(&"npc", npc)
	print(
		"%s TARGET npc archetype=%s hull_id=%s hull_max=%.1f shield_max=%.1f layer=%d"
		% [
			TAG,
			NPC_ARCHETYPE,
			npc.call(&"hull_id"),
			float(stats.get(&"hull_max")),
			float(stats.get(&"shield_max")),
			(npc.get_node(NodePath(NPC_BODY_NODE)) as RigidBody2D).collision_layer,
		]
	)
	await _teardown(fixture)

	fixture = _build_fixture(&"rock", SHIELD_UP)
	var rock := fixture[&"target"] as Node
	_trace_sink(&"rock", rock)
	print(
		"%s TARGET rock group=%s layer=%d mask=%d work=%.3f yield=%d"
		% [
			TAG,
			str(rock.is_in_group(AsteroidScript.ROCK_GROUP)),
			(rock as RigidBody2D).collision_layer,
			(rock as RigidBody2D).collision_mask,
			float(rock.get(&"work")),
			int(rock.get(&"yield_units")),
		]
	)
	await _teardown(fixture)


func _trace_sink(label: String, node: Node) -> void:
	print(
		"%s SINK %s take_damage=%s damage=%s apply_work=%s shield_up=%s"
		% [
			TAG,
			label,
			str(node.has_method(&"take_damage")),
			str(node.has_method(&"damage")),
			str(node.has_method(&"apply_work")),
			str(node.has_method(&"shield_up")),
		]
	)


## --- Fixtures ---------------------------------------------------------------


func _build_fixture(
	kind: StringName, shield_mode: StringName, rock_units: int = ROCK_UNITS
) -> Dictionary:
	var root := Node2D.new()
	root.name = "Fixture"
	add_child(root)
	var host := StubHull.new()
	host.name = "Host"
	root.add_child(host)
	var guns := WeaponScript.new() as Node2D
	guns.name = &"WeaponComponent"
	host.add_child(guns)
	guns.connect(&"shot_fired", _on_shot)
	guns.connect(&"dry_fired", _on_dry)

	var stats: Object = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	if shield_mode == SHIELD_DOWN:
		## Shields down as an inert pool (max 0), so the frame's regen cannot re-fill it
		## and the hull is the only pool left: section 4.2 item 2's read is untouched.
		stats.set(&"shield_max", 0.0)
	var state: Object = PlayerStateScript.new()
	state.call(&"setup")
	guns.call(&"setup", stats, state)

	var target: Node = _build_target(kind, stats, rock_units)
	root.add_child(target)
	_target_placement(kind, target)
	guns.call(&"set_aim_point", (target as Node2D).global_position)
	return {
		&"root": root,
		&"host": host,
		&"guns": guns,
		&"stats": stats,
		&"state": state,
		&"target": target,
		&"kind": kind,
	}


func _build_target(kind: StringName, stats: Object = null, rock_units: int = ROCK_UNITS) -> Node:
	if kind == &"rock":
		var rock := AsteroidScript.new() as RigidBody2D
		rock.name = "Rock"
		rock.call(&"setup", ROCK_MINERAL, 1, rock_units, ROCK_SIZE_MEDIUM)
		rock.freeze = true
		return rock
	if kind == &"sink_body":
		var sink := SinkBody.new() as RigidBody2D
		sink.name = "SinkBody"
		sink.collision_layer = AsteroidScript.COLLISION_LAYER
		sink.collision_mask = 0
		sink.gravity_scale = 0.0
		sink.freeze = true
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 30.0
		shape.shape = circle
		sink.add_child(shape)
		return sink
	if kind == &"bare_body":
		var bare := BareBody.new() as RigidBody2D
		bare.name = "BareBody"
		bare.collision_layer = AsteroidScript.COLLISION_LAYER
		bare.collision_mask = 0
		bare.gravity_scale = 0.0
		var bare_shape := CollisionShape2D.new()
		var bare_circle := CircleShape2D.new()
		bare_circle.radius = 30.0
		bare_shape.shape = bare_circle
		bare.add_child(bare_shape)
		return bare
	## The fixture's own stats object, so a shields-down fixture is the same snapshot the
	## component was handed (a second resolve would silently restore a full shield pool).
	var npc_stats: Object = stats
	if npc_stats == null:
		npc_stats = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	var npc := NpcShipScript.new() as Node2D
	npc.name = "Npc"
	npc.call(&"setup", NPC_ARCHETYPE, npc_stats, NPC_HULL, {&"sprite_path": NPC_SPRITE})
	var body := npc.get_node_or_null(NodePath(NPC_BODY_NODE)) as RigidBody2D
	if body != null:
		## Frozen so the hull is a fixed target: the brain still ticks, the body cannot
		## drift, and the pools measured are the pools hit.
		body.freeze = true
	return npc


func _target_placement(kind: StringName, target: Node) -> void:
	var distance := HULL_DISTANCE
	if kind == &"rock":
		distance = ROCK_DISTANCE
	(target as Node2D).global_position = Vector2(distance, 0.0)


func _teardown(fixture: Dictionary) -> void:
	var root := fixture[&"root"] as Node
	if root != null and is_instance_valid(root):
		root.queue_free()
	for node: Node in get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP):
		node.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _on_shot(weapon_id: StringName) -> void:
	_shots += 1
	_shot_ids.append(weapon_id)


func _on_dry(weapon_id: StringName) -> void:
	_dry_events += 1
	_dry_ids.append(weapon_id)


## --- The frames -------------------------------------------------------------


func _step(frames: int) -> void:
	for index in frames:
		_stepped += 1
		await get_tree().physics_frame


func _count_projectiles() -> int:
	return get_tree().get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP).size()


## One family fired at one target kind for the family's own frame count, through the
## component's external trigger only.
func _fire_case(
	kind: StringName,
	shield_mode: StringName,
	weapon_id: StringName,
	frames: int,
	distance: float,
	rock_units: int = ROCK_UNITS
) -> Dictionary:
	var fixture := _build_fixture(kind, shield_mode, rock_units)
	var guns := fixture[&"guns"] as Node2D
	var state: Object = fixture[&"state"]
	var target := fixture[&"target"] as Node
	_guns_select(guns, [weapon_id])
	var stand_off := MINE_DISTANCE if weapon_id == &"mine" else distance
	(target as Node2D).global_position = Vector2(stand_off, 0.0)
	guns.call(&"set_aim_point", (target as Node2D).global_position)
	await get_tree().physics_frame

	_shots = 0
	_dry_events = 0
	_shot_ids.clear()
	_dry_ids.clear()
	var before := _snapshot(kind, target)
	var dry_before := StringName(guns.call(&"dry_reason"))
	var host := fixture[&"host"] as StubHull
	guns.call(&"set_firing", true)
	## Read after the trigger is set: `set_firing` is the external seam, and this flag is
	## the proof that `_sample_trigger` never reached `Input` for the whole case.
	var external: bool = bool(guns.get(&"_external_trigger"))
	await _step(frames)
	guns.call(&"set_firing", false)
	var after := _snapshot(kind, target)
	var row := {
		&"kind": kind,
		&"shield": shield_mode,
		&"weapon": weapon_id,
		&"frames": frames,
		&"distance": stand_off,
		&"before": before,
		&"after": after,
		&"dry_before": dry_before,
		&"dry_after": StringName(guns.call(&"dry_reason")),
		&"shots": _shots,
		&"dry_events": _dry_events,
		&"shot_ids": _shot_ids.duplicate(),
		&"external_trigger": external,
		&"projectiles": _count_projectiles(),
		&"energy": float(state.get(&"energy")),
		&"ammo": (state.get(&"ammo") as Array).duplicate(),
		&"recoil_calls": host.recoil_calls,
		&"recoil_mass": host.last_mass,
	}
	await _teardown(fixture)
	return row


func _guns_select(guns: Node2D, ids: Array) -> void:
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	guns.call(&"set_fitted", fit)
	guns.call(&"select_group", 1)


func _snapshot(kind: StringName, target: Variant) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {&"freed": true}
	if kind == &"rock":
		return {
			&"freed": false,
			&"work": float(target.get(&"work")),
			&"units": int(target.get(&"yield_units")),
			&"alive": not (target as Node).is_queued_for_deletion(),
		}
	if kind == &"sink_body":
		return {
			&"hits": int(target.get(&"hits")),
			&"taken": float(target.get(&"taken")),
		}
	if kind == &"bare_body":
		return {
			&"speed": (target as RigidBody2D).linear_velocity.length(),
			&"pos": (target as Node2D).global_position,
		}
	return {
		&"hull": float(target.call(&"hull")),
		&"shield": float(target.call(&"shield")),
		&"hull_max": float(target.call(&"hull_max")),
		&"shield_max": float(target.call(&"shield_max")),
	}


## --- The matrices -----------------------------------------------------------


func _run_matrix(kind: StringName, shield_mode: StringName) -> void:
	for entry: Dictionary in FAMILIES:
		var weapon_id := StringName(entry[&"id"])
		var row := await _fire_case(
			kind, shield_mode, weapon_id, int(entry[&"frames"]), float(entry[&"distance"])
		)
		_print_case(row)


func _print_case(row: Dictionary) -> void:
	var kind := StringName(row[&"kind"])
	var before: Dictionary = row[&"before"]
	var after: Dictionary = row[&"after"]
	var head := (
		"%s CASE target=%s shield=%s weapon=%s frames=%d dist=%.0f external_trigger=%s shots=%d dry_events=%d dry_before=\"%s\" dry_after=\"%s\" projectiles=%d recoil=%d"
		% [
			TAG,
			kind,
			row[&"shield"],
			row[&"weapon"],
			int(row[&"frames"]),
			float(row[&"distance"]),
			str(row[&"external_trigger"]),
			int(row[&"shots"]),
			int(row[&"dry_events"]),
			row[&"dry_before"],
			row[&"dry_after"],
			int(row[&"projectiles"]),
			int(row[&"recoil_calls"]),
		]
	)
	if kind == &"npc":
		print(
			"%s hull=%.3f->%.3f (d=%+.3f of %.3f) shield=%.3f->%.3f (d=%+.3f of %.3f)"
			% [
				head,
				float(before[&"hull"]),
				float(after[&"hull"]),
				float(after[&"hull"]) - float(before[&"hull"]),
				float(before[&"hull_max"]),
				float(before[&"shield"]),
				float(after[&"shield"]),
				float(after[&"shield"]) - float(before[&"shield"]),
				float(before[&"shield_max"]),
			]
		)
		return
	if kind == &"rock":
		if bool(after.get(&"freed", false)):
			print(
				"%s work=%.3f->FREED units=%d->0 cracked=true"
				% [head, float(before[&"work"]), int(before[&"units"])]
			)
			return
		## `apply_work` converts whole units the moment they are reached, so the work it
		## was handed is `units extracted + the residual left in the accumulator`.
		var credited := (
			float(int(before[&"units"]) - int(after[&"units"]))
			+ float(after[&"work"])
			- float(before[&"work"])
		)
		print(
			"%s work=%.3f->%.3f units=%d->%d (extracted=%d) work_credited=%.3f alive=%s"
			% [
				head,
				float(before[&"work"]),
				float(after[&"work"]),
				int(before[&"units"]),
				int(after[&"units"]),
				int(before[&"units"]) - int(after[&"units"]),
				credited,
				str(after[&"alive"]),
			]
		)
		return
	if kind == &"sink_body":
		print(
			"%s hits=%d->%d taken=%.3f->%.3f"
			% [
				head,
				int(before[&"hits"]),
				int(after[&"hits"]),
				float(before[&"taken"]),
				float(after[&"taken"]),
			]
		)
		return
	print(
		"%s bare_speed=%.3f->%.3f bare_pos=%.1f->%.1f"
		% [
			head,
			float(before[&"speed"]),
			float(after[&"speed"]),
			(before[&"pos"] as Vector2).x,
			(after[&"pos"] as Vector2).x,
		]
	)


## --- The rock, taken all the way to the crack ---------------------------------


## The owner's report was "I cannot shoot asteroids", so the rock is not only chipped in
## the matrix above but emptied here: a 5-unit rock with one beam hold and one kinetic
## burst. The answer is read off `yield_units` reaching 0 and the rock being freed (its
## own `cracked` emission), not off a work residue.
func _run_rock_crack() -> void:
	for weapon_id: StringName in [&"laser", &"cannon"]:
		var frames := 180
		for entry: Dictionary in FAMILIES:
			if StringName(entry[&"id"]) == weapon_id:
				if int(entry[&"frames"]) > frames:
					frames = int(entry[&"frames"])
		var row := await _fire_case(
			&"rock", SHIELD_UP, weapon_id, frames, ROCK_DISTANCE, ROCK_UNITS_SMALL
		)
		_print_case(row)


## --- Controls: a sink present, and no sink at all ---------------------------


func _run_controls() -> void:
	for weapon_id: StringName in [&"laser", &"cannon"]:
		_print_case(await _fire_case(&"sink_body", SHIELD_UP, weapon_id, 120, HULL_DISTANCE))
	for weapon_id: StringName in [&"laser", &"cannon"]:
		_print_case(await _fire_case(&"bare_body", SHIELD_UP, weapon_id, 120, HULL_DISTANCE))


## --- The sink seam itself ---------------------------------------------------


## The exact seam the brief names: `weapons.gd._deliver` and `Damage.apply` are both
## called with each target object directly. The rock answers neither `take_damage` nor
## `damage`, so both return without delivering anything; the layer-1 control that does
## publish `take_damage` takes the damage through the same two calls.
func _run_sink_seam() -> void:
	var fixture := _build_fixture(&"npc", SHIELD_UP)
	var guns := fixture[&"guns"] as Node2D
	var npc := fixture[&"target"] as Node
	var root := fixture[&"root"] as Node
	var rock := _build_target(&"rock")
	root.add_child(rock)
	(rock as Node2D).global_position = Vector2(HULL_DISTANCE, 200.0)
	var sink := _build_target(&"sink_body")
	root.add_child(sink)
	(sink as Node2D).global_position = Vector2(HULL_DISTANCE, 400.0)
	var bare := _build_target(&"bare_body")
	root.add_child(bare)
	(bare as Node2D).global_position = Vector2(HULL_DISTANCE, 600.0)
	await get_tree().physics_frame

	var shield_before := float(npc.call(&"shield"))
	DamageScript.apply(npc, 100.0, false)
	print(
		"%s SEAM Damage.apply(npc, 100.0, false) -> shield %.3f->%.3f (d=%+.3f)"
		% [
			TAG,
			shield_before,
			float(npc.call(&"shield")),
			float(npc.call(&"shield")) - shield_before,
		]
	)
	var work_before := float(rock.get(&"work"))
	var units_before := int(rock.get(&"yield_units"))
	DamageScript.apply(rock, 100.0, false)
	print(
		"%s SEAM Damage.apply(rock, 100.0, false) -> work %.3f->%.3f units %d->%d (no-op: _hit_method empty)"
		% [
			TAG,
			work_before,
			float(rock.get(&"work")),
			units_before,
			int(rock.get(&"yield_units")),
		]
	)
	var sink_before := float(sink.get(&"taken"))
	DamageScript.apply(sink, 100.0, false)
	print(
		"%s SEAM Damage.apply(sink_body, 100.0, false) -> taken %.3f->%.3f (control)"
		% [TAG, sink_before, float(sink.get(&"taken"))]
	)
	var bare_speed_before := (bare as RigidBody2D).linear_velocity.length()
	DamageScript.apply(bare, 100.0, false)
	print(
		"%s SEAM Damage.apply(bare_body, 100.0, false) -> speed %.3f->%.3f (no-op)"
		% [TAG, bare_speed_before, (bare as RigidBody2D).linear_velocity.length()]
	)

	work_before = float(rock.get(&"work"))
	units_before = int(rock.get(&"yield_units"))
	guns.call(&"_deliver", rock, 100.0, false, (rock as Node2D).global_position, &"kinetic", Vector2.ZERO)
	print(
		"%s SEAM weapons._deliver(rock, 100.0, false, kinetic) -> work %.3f->%.3f units %d->%d (no-op: neither sink name)"
		% [
			TAG,
			work_before,
			float(rock.get(&"work")),
			units_before,
			int(rock.get(&"yield_units")),
		]
	)
	sink_before = float(sink.get(&"taken"))
	guns.call(
		&"_deliver", sink, 100.0, false, (sink as Node2D).global_position, &"kinetic", Vector2.ZERO
	)
	print(
		"%s SEAM weapons._deliver(sink_body, 100.0, false, kinetic) -> taken %.3f->%.3f (control)"
		% [TAG, sink_before, float(sink.get(&"taken"))]
	)
	bare_speed_before = (bare as RigidBody2D).linear_velocity.length()
	guns.call(
		&"_deliver", bare, 100.0, false, (bare as Node2D).global_position, &"kinetic", Vector2.ZERO
	)
	print(
		"%s SEAM weapons._deliver(bare_body, 100.0, false, kinetic) -> speed %.3f->%.3f (no-op)"
		% [TAG, bare_speed_before, (bare as RigidBody2D).linear_velocity.length()]
	)

	var reader := ShieldReader.new()
	root.add_child(reader)
	print(
		"%s SEAM weapons._shield_up(npc)=%s _shield_up(shield_reader)=%s (the plasma bonus gate)"
		% [
			TAG,
			str(guns.call(&"_shield_up", npc)),
			str(guns.call(&"_shield_up", reader)),
		]
	)
	await _teardown(fixture)


## --- dry_reason per family --------------------------------------------------


## Every family with its own resource emptied: a beam's Energy pool at 0, a travelling
## family's pack at 0. `dry_reason()` must name the empty resource and nothing may fire.
##
## Which resource to empty is the row's own `instant` flag, i.e. exactly what selects
## `_fire_beam` against `_fire_projectile`. C2 read this off `interval_of(...) <= 0.0`,
## which agreed with the flag for all five v1 families until the C5 fix made the mine's
## cadence fallback family-aware: the mine's interval is 0.0 now because a deployable
## states no cadence, and it spends ammo, not Energy. Reading the flag keeps this matrix
## about the family's resource rather than about a cadence.
func _run_dry_matrix() -> void:
	for entry: Dictionary in FAMILIES:
		var weapon_id := StringName(entry[&"id"])
		var fixture := _build_fixture(&"npc", SHIELD_UP)
		var guns := fixture[&"guns"] as Node2D
		var state: Object = fixture[&"state"]
		var npc := fixture[&"target"] as Node
		_guns_select(guns, [weapon_id])
		guns.call(&"set_aim_point", (npc as Node2D).global_position)
		if bool(WeaponScript.row_of(weapon_id).get(&"instant", false)):
			state.set(&"energy", 0.0)
			print(
				"%s DRY weapon=%s drained=energy dry_reason=\"%s\""
				% [TAG, weapon_id, StringName(guns.call(&"dry_reason"))]
			)
		else:
			var slot := WeaponScript.ammo_slot(weapon_id)
			state.call(&"set_ammo", slot, 0)
			print(
				"%s DRY weapon=%s drained=ammo slot=%d dry_reason=\"%s\""
				% [TAG, weapon_id, slot, StringName(guns.call(&"dry_reason"))]
			)
		_shots = 0
		_dry_events = 0
		_shot_ids.clear()
		_dry_ids.clear()
		var hull_before := float(npc.call(&"hull"))
		var shield_before := float(npc.call(&"shield"))
		await get_tree().physics_frame
		guns.call(&"set_firing", true)
		await _step(60)
		guns.call(&"set_firing", false)
		print(
			"%s DRY weapon=%s fired_for=60 shots=%d dry_events=%d dry_ids=%s hull_d=%.3f shield_d=%.3f dry_after=\"%s\""
			% [
				TAG,
				weapon_id,
				_shots,
				_dry_events,
				str(_dry_ids),
				float(npc.call(&"hull")) - hull_before,
				float(npc.call(&"shield")) - shield_before,
				StringName(guns.call(&"dry_reason")),
			]
		)
		await _teardown(fixture)


## --- The launch fit ---------------------------------------------------------


## What the launch actually installs, and what the launch panel promises: the panel's
## own line ("%d ROUNDS ACROSS %d WEAPONS") is reproduced from `StationCatalog.AMMO_PACKS`
## and the live `PlayerProfile`, then `game.gd`'s installed fit is read from `ShipFit`,
## then the five-weapon fit is fired group by group so a group with no weapon is
## distinguishable from one whose firing path is broken.
func _run_launch_fit() -> void:
	var pack_ids: Array[StringName] = []
	for pack: Dictionary in CatalogScript.AMMO_PACKS:
		pack_ids.append(StringName(pack.get(&"id", &"")))
	print(
		"%s LAUNCH-PANEL packs=%d ids=%s player_state_ammo_default=%d"
		% [TAG, pack_ids.size(), str(pack_ids), int(PlayerStateScript.AMMO_DEFAULT)]
	)
	var profile := get_node_or_null(NodePath(&"/root/PlayerProfile"))
	if profile != null and profile.has_method(&"ammo_of"):
		var total := 0
		var parts: Array[String] = []
		for id: StringName in pack_ids:
			var held := int(profile.call(&"ammo_of", id))
			total += held
			parts.append("%s=%d" % [id, held])
		print("%s LAUNCH-PANEL profile_holdings=%s total=%d" % [TAG, str(parts), total])
	else:
		print("%s LAUNCH-PANEL profile=absent (autoload not present)" % TAG)

	var shipped: Array[StringName] = ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT)
	print(
		"%s LAUNCH-FIT ShipFit.STANDARD_FIT ids=%s (game.gd:_spawn_ship installs this)"
		% [TAG, str(shipped)]
	)
	## The mining laser is the rock-facing "weapon" and its own fit gate (rule 1 of the
	## brief is about rocks), so the same question is asked of it: is it unfitted at
	## launch, or is its trigger broken?
	print(
		"%s LAUNCH-FIT mining_gate module=%s in_standard_fit=%s in_five_weapon_fit=%s"
		% [
			TAG,
			PlayerShipScript.MINING_MODULE,
			str(shipped.has(PlayerShipScript.MINING_MODULE)),
			str(V1_MODULE_IDS.has(PlayerShipScript.MINING_MODULE)),
		]
	)

	var fixture := _build_fixture(&"npc", SHIELD_UP)
	var guns := fixture[&"guns"] as Node2D
	var state: Object = fixture[&"state"]
	## Pass A: the fit as `game.gd` installs it today.
	guns.call(&"set_fitted", shipped)
	print(
		"%s LAUNCH-FIT fitted_after_filter=%s groups=%d"
		% [TAG, str(guns.call(&"fitted")), int(WeaponScript.GROUPS_MAX)]
	)
	for group in range(1, WeaponScript.GROUPS_MAX + 1):
		guns.call(&"select_group", group)
		print(
			"%s LAUNCH-FIT shipped group=%d selected=\"%s\" dry_reason=\"%s\""
			% [
				TAG,
				group,
				StringName(guns.call(&"selected_weapon")),
				StringName(guns.call(&"dry_reason")),
			]
		)
	var ammo: Array = state.get(&"ammo")
	var ammo_total := 0
	for value: int in ammo:
		ammo_total += value
	print(
		"%s LAUNCH-FIT state rounds_per_slot=%s total=%d energy=%.1f"
		% [TAG, str(ammo), ammo_total, float(state.get(&"energy"))]
	)
	await _teardown(fixture)

	## Pass B: the five-weapon fit the panel's own line describes, fired group by group.
	print(
		"%s LAUNCH-FIT five-weapon fit modules=%s weapons=%s"
		% [TAG, str(V1_MODULE_IDS), str(V1_WEAPON_IDS)]
	)
	for index in V1_WEAPON_IDS.size():
		var weapon_id := V1_WEAPON_IDS[index]
		var frames := 60
		var distance := HULL_DISTANCE
		for entry: Dictionary in FAMILIES:
			if StringName(entry[&"id"]) == weapon_id:
				frames = int(entry[&"frames"])
				distance = float(entry[&"distance"])
		var row := await _fire_case(&"npc", SHIELD_UP, weapon_id, frames, distance)
		var before: Dictionary = row[&"before"]
		var after: Dictionary = row[&"after"]
		print(
			"%s LAUNCH-FIRE group=%d weapon=%s dry_before=\"%s\" shots=%d hull_d=%+.3f shield_d=%+.3f dry_after=\"%s\""
			% [
				TAG,
				index + 1,
				weapon_id,
				row[&"dry_before"],
				int(row[&"shots"]),
				float(after[&"hull"]) - float(before[&"hull"]),
				float(after[&"shield"]) - float(before[&"shield"]),
				row[&"dry_after"],
			]
		)


## What the launch actually *mounts* on the player hull: the ship scene is the shipping
## one, `setup` is the pinned launch handshake, and the children are read back by the
## names the wiring itself resolves. A fit that carries one weapon and a fit that carries
## five are told apart here, and so is the mining laser's own `w_mining` gate - an absent
## node is "unfitted", never "a broken firing path". The section closes by firing the
## mounted component at a real rock, so the matrix's rock numbers are confirmed on the
## shipping hull rather than only on the stub host. The hull's own `_physics_process` polls
## its flight actions (thrust, boost, fuel cell, the `E` mining action) exactly as it ships;
## headless with no events injected they all read idle, and the *weapon* trigger in every
## case is `set_firing`.
func _run_mount_probe() -> void:
	var state: Object = PlayerStateScript.new()
	state.call(&"setup")
	var stats: Object = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	var ship := PlayerShipScene.instantiate()
	add_child(ship)
	var cases: Array[Dictionary] = [
		{&"name": &"STANDARD_FIT", &"ids": _modules(ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))},
		{
			&"name": &"STANDARD_FIT+w_mining",
			&"ids": _with_mining(_modules(ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))),
		},
		{&"name": &"five_weapon_fit", &"ids": _modules(V1_MODULE_IDS)},
		{
			&"name": &"five_weapon_fit+w_mining",
			&"ids": _with_mining(_modules(V1_MODULE_IDS)),
		},
	]
	for entry: Dictionary in cases:
		var ids: Array[StringName] = entry[&"ids"]
		ship.call(&"setup", stats, state, ids)
		await get_tree().physics_frame
		var laser := ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
		var guns := ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
		var guns_fitted: Array = []
		if guns != null and guns.has_method(&"fitted"):
			guns_fitted = guns.call(&"fitted")
		print(
			"%s MOUNT fit=%s mining_laser_mounted=%s weapon_component_mounted=%s guns_fitted=%s"
			% [TAG, entry[&"name"], str(laser != null), str(guns != null), str(guns_fitted)]
		)
	## One more case, on the shipping hull instead of a stub host: the five-weapon fit, a
	## real rock, group 1 fired through the same external trigger. The matrix's rock row
	## and this row have to agree, or the mount (not the firing path) is the difference.
	var rock := _build_target(&"rock", stats, ROCK_UNITS_SMALL)
	add_child(rock)
	(rock as Node2D).global_position = Vector2(ROCK_DISTANCE, 0.0)
	(ship as Node2D).global_position = Vector2.ZERO
	await get_tree().physics_frame
	var mounted := ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	if mounted != null:
		mounted.call(&"select_group", 1)
		mounted.call(&"set_aim_point", (rock as Node2D).global_position)
		var before := _snapshot(&"rock", rock)
		mounted.call(&"set_firing", true)
		await _step(180)
		mounted.call(&"set_firing", false)
		var after := _snapshot(&"rock", rock)
		print(
			"%s MOUNT-FIRE ship=player_ship.tscn fit=five_weapon_fit+w_mining group=1 weapon=%s rock_units=%d->%d rock_freed=%s"
			% [
				TAG,
				StringName(mounted.call(&"selected_weapon")),
				int(before[&"units"]),
				int(after.get(&"units", 0)),
				str(bool(after.get(&"freed", false))),
			]
		)
	## A cracked rock freed itself (`Asteroid._crack`), so the cleanup is guarded: the
	## firing case's own result is that the rock is gone.
	if is_instance_valid(rock):
		rock.queue_free()
	ship.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _modules(ids: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(ids)
	return out


func _with_mining(ids: Array[StringName]) -> Array[StringName]:
	var out := _modules(ids)
	out.append(PlayerShipScript.MINING_MODULE)
	return out
