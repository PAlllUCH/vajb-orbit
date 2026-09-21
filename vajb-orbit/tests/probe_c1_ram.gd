extends Node2D
## C1 ram probe (combat/collision-repair wave, 2026-09-21): the shipped ram, measured.
##
## Deterministic headless scene. No window, no `Input` action, no editor, no physics
## faked: a real `PlayerShip` (its shipped `HullBody`, its shipped contact monitor) is
## driven into a real `Asteroid` and the engine is asked what happened. CONTRACTS
## section 9's trap list is the reason for the shape -- a `--script` run cannot exercise
## `Input` state and a live-but-unfocused game window is unreliable -- and
## `tests/probe_w5_lint.tscn` is the reference for a deterministic headless probe.
##
## Per scenario it measures, with raw numbers:
##   * the rock's `linear_velocity` across the contact (pre-impact, peak, final) and its
##     position delta;
##   * both sides' pool deltas: the hull's `PlayerState.hull` / `shield`, and the rock's
##     own `yield_units` / `work` (the rock carries no hull pool at all, which is half of
##     the finding);
##   * whether the ship's contact monitor fires at all -- the probe connects its *own*
##     `body_entered` listener to the shipped `HullBody`, so "the engine reported no
##     contact" is distinguishable from "the ship's handler dropped it".
##
## Scenarios, each a fresh world (fresh `PlayerShip`, fresh `PlayerState`, fresh rock, no
## state carried over), so the three candidate causes separate:
##   S1 SHIPPED   the rock exactly as `Asteroid.setup` builds it (layer 1, mask 0);
##   S2 MASK2     the same rock with `collision_mask` corrected in memory to the hull's
##                layer 2 -- the one-way-pair candidate;
##   S2b MASK1    the same rock with a non-zero but wrong mask (its own layer 1), which
##                separates "the mask must be non-zero" from "the mask must name the
##                hull's layer" -- the difference between a fix that changes rock-rock
##                behaviour and one that does not;
##   S3 SINK      the shipped rock plus the `apply_collision_damage` stub shipping
##                `Asteroid` does not implement -- the missing-sink candidate. The stub
##                also records the *amount* the ship offers, which is what the 40 u/s
##                floor governs;
##   C1 CONTROL   a bare `RigidBody2D` (the rock's own layer, mask, mass, damp and
##                radius) rammed identically -- proves the harness can observe a solved
##                contact, so a null result in S1 means something;
##   S5 COAST     the shipped pair released at 450 u/s and *not* driven, i.e. the ram the
##                owner actually performs, with the flight model's coast decay live;
##   S6 FIXED     the two in-memory repairs together (`collision_mask` 2 *and* the stub
##                sink) -- the target numbers the fixer pass must reproduce.
##
## The ram is driven, not thrusted: this node's `_physics_process` runs before the ship's
## (tree order, parents first), so it re-asserts a fixed `linear_velocity` on the shipped
## `HullBody` each frame until the first contact is reported -- the brief's "fixed
## velocity step", which makes the closing speed a constant of the scenario rather than a
## product of the thrust model. The driver stops the instant `body_entered` fires.
##
## Read-only with respect to the project: it loads shipping scenes and scripts and
## writes nothing. The two in-memory deviations (the corrected mask, the stub sink) are
## per-scenario nodes, freed before the next scenario.
##
## Run:
##   godot --headless --path vajb-orbit res://tests/probe_c1_ram.tscn --quit-after 100000
##
## The probe quits itself once the last scenario's summary line is printed; `--quit-after`
## is the brief's hard bound, not the stop condition. Every line is prefixed `[C1-RAM]`;
## the last line is `[C1-RAM] done`.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const StubRockScript := preload("res://tests/c1_stub_rock.gd")
const ImpactScript := preload("res://game/impact.gd")

## The shipped default launch hull (`ShipFit.STANDARD_FIT`, the fit the owner flies).
const HULL: StringName = &"ship_vanguard"

## The velocity the ram is driven at, in units/s: above every candidate floor by an order
## of magnitude, and about the vanguard's own section 13 `max_speed` (428).
const APPROACH_SPEED := 450.0

## Where the ram starts, centre to centre, in units: far enough for a clean approach at
## 60 Hz (7.5 u per step) and short enough that nothing else in the world matters.
const START_GAP := 400.0

const ROCK_ORIGIN := Vector2.ZERO

## Pins the rock's look roll (and therefore its sprite and collision radius) across
## scenarios: `Asteroid.setup` rolls uniformly on the global RNG, so without this the
## three scenarios would ram differently sized rocks.
const RAM_SEED := 20260921

## Frames a scenario may spend closing before it declares "no contact at all".
const APPROACH_BUDGET := 300

## Frames recorded after the contact, for the rock's settle and the pools' final read.
const SETTLE_FRAMES := 120

## Frames between scenarios, so the freed fixtures leave the physics world cleanly.
const COOLDOWN_FRAMES := 8

const TRACE_BEFORE := 4
const TRACE_AFTER := 8

const PHASE_IDLE := 0
const PHASE_COOLDOWN := 1
const PHASE_APPROACH := 2
const PHASE_AFTER := 3

const SCENARIOS: Array[Dictionary] = [
	{"id": "S1 SHIPPED", "rock": "asteroid", "mask": -1, "drive": true},
	{"id": "S2 MASK2", "rock": "asteroid", "mask": 2, "drive": true},
	{"id": "S2b MASK1", "rock": "asteroid", "mask": 1, "drive": true},
	{"id": "S3 SINK", "rock": "stub", "mask": -1, "drive": true},
	{"id": "C1 CONTROL", "rock": "bare", "mask": -1, "drive": true},
	{"id": "S5 COAST", "rock": "asteroid", "mask": -1, "drive": false},
	{"id": "S6 FIXED", "rock": "stub", "mask": 2, "drive": true},
]

var _scenario_index := 0
var _phase := PHASE_IDLE
var _phase_frames := 0
var _frame := 0

var _ship: Node2D = null
var _state: Resource = null
var _body: RigidBody2D = null
var _rock: RigidBody2D = null
var _stub: Node = null

var _scenario_id := ""
var _driving := false
var _contact_seen := false
var _contact_frame := -1
var _contact: Dictionary = {}
var _approach_tail: PackedStringArray = PackedStringArray()
var _trace: PackedStringArray = PackedStringArray()

var _pre_ship_v := Vector2.ZERO
var _pre_rock_v := Vector2.ZERO
var _pre_gap := 0.0
var _min_gap := INF
var _rock_peak_speed := 0.0
var _rock_start := Vector2.ZERO
var _ship_start := Vector2.ZERO
var _pools: Dictionary = {}

## The medium rock row's collision radius, measured once from a real rock with the RAM_SEED
## look roll. The bare control body is given this radius so its geometry matches S1's.
var _medium_radius := 42.0


func _ready() -> void:
	await get_tree().process_frame
	print("[C1-RAM] probe start engine=%s physics_ticks=%d hull=%s approach=%.1f gap=%.1f seed=%d"
		% [
			Engine.get_version_info().get("string", "?"),
			Engine.physics_ticks_per_second,
			HULL, APPROACH_SPEED, START_GAP, RAM_SEED,
		])
	_measure_medium_radius()
	print("[C1-RAM] medium rock (pinned SIZE_MEDIUM + seed): radius=%.3f mass=%.1f"
		% [_medium_radius, _rock_mass()])
	## Scenario 0 enters through the same phase machine as every later one, so its frame
	## numbering cannot drift: setup runs from `_physics_process`, never from this idle
	## frame.
	_phase = PHASE_COOLDOWN
	_phase_frames = 1


## The pump. Every scenario is a state of this machine, so the driver always runs in this
## node's `_physics_process` -- i.e. before the ship's own frame, which is what makes the
## velocity step fixed.
func _physics_process(_delta: float) -> void:
	match _phase:
		PHASE_COOLDOWN:
			_phase_frames -= 1
			if _phase_frames <= 0:
				_start_scenario(_scenario_index)
		PHASE_APPROACH:
			_step_approach()
		PHASE_AFTER:
			_step_after()


## The rock's collision radius for the pinned medium row, read from a throwaway rock that
## is built and freed before any scenario exists.
func _measure_medium_radius() -> void:
	seed(RAM_SEED)
	var rock: RigidBody2D = AsteroidScript.new() as RigidBody2D
	rock.name = "RadiusProbe"
	add_child(rock)
	rock.call(&"setup", &"iron", 1, 8, AsteroidScript.SIZE_MEDIUM)
	_medium_radius = float(rock.call(&"world_radius"))
	remove_child(rock)
	rock.free()


func _rock_mass() -> float:
	var row: Dictionary = ShipFitScript.HANDLING.get(AsteroidScript.ROCK_MASS_REFERENCE, {})
	return AsteroidScript.ROCK_MASS_MULT * float(row.get(&"hull_mass", 0.0))


func _start_scenario(index: int) -> void:
	_scenario_index = index
	if index >= SCENARIOS.size():
		_finish()
		return
	_clear_fixture()

	var cfg: Dictionary = SCENARIOS[index]
	_scenario_id = String(cfg["id"])
	_driving = bool(cfg["drive"])
	_contact_seen = false
	_contact_frame = -1
	_contact = {}
	_approach_tail = PackedStringArray()
	_trace = PackedStringArray()
	_min_gap = INF
	_rock_peak_speed = 0.0
	_frame = 0
	seed(RAM_SEED)

	_state = PlayerStateScript.new()
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	_state.set(&"hull_max", stats.hull_max)
	_state.set(&"shield_max", stats.shield_max)
	_state.set(&"cargo_max", stats.cargo_max)
	_state.set(&"energy_max", stats.energy_max)
	_state.set(&"energy_regen", stats.energy_regen)
	_state.set(&"fuel_max", stats.fuel_max)
	_state.set(&"shield_regen", stats.shield_regen)
	_state.call(&"setup")

	_ship = PlayerShipScene.instantiate() as Node2D
	add_child(_ship)
	_ship.call(&"setup", stats, _state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	_ship.global_position = ROCK_ORIGIN - Vector2(START_GAP, 0.0)
	_ship.global_rotation = 0.0
	_body = _ship.get_node_or_null(
		NodePath(PlayerShipScript.HULL_BODY_NODE)
	) as RigidBody2D
	if _body == null:
		print("[C1-RAM] %s ABORT: the shipped player_ship.tscn carries no %s"
			% [_scenario_id, PlayerShipScript.HULL_BODY_NODE])
		_end_scenario()
		return
	_body.linear_velocity = Vector2(APPROACH_SPEED, 0.0)
	_body.body_entered.connect(_on_body_entered)

	_rock = _build_rock(cfg)
	_rock.global_position = ROCK_ORIGIN
	_rock.linear_velocity = Vector2.ZERO

	_rock_start = _rock.global_position
	_ship_start = _body.global_position
	_record_pools()
	_announce(cfg)
	_phase = PHASE_APPROACH


func _build_rock(cfg: Dictionary) -> RigidBody2D:
	var kind := String(cfg["rock"])
	var rock: RigidBody2D = null
	if kind == "bare":
		rock = RigidBody2D.new()
		rock.name = "BareControl"
		add_child(rock)
		rock.mass = _rock_mass()
		rock.linear_damp = AsteroidScript.LINEAR_DAMP
		rock.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
		rock.gravity_scale = 0.0
		rock.can_sleep = false
		rock.collision_layer = AsteroidScript.COLLISION_LAYER
		rock.collision_mask = 0
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var circle := CircleShape2D.new()
		circle.radius = _medium_radius
		shape.shape = circle
		rock.add_child(shape)
		return rock
	rock = (StubRockScript if kind == "stub" else AsteroidScript).new() as RigidBody2D
	rock.name = "Rock"
	add_child(rock)
	## 100 units, not C1's 8: the C5 fix gives this rock the ram sink it was missing, so a
	## 186.179 offer now chips 18.618 work through the same 10 % channel a gun uses. An
	## 8-unit fixture would `crack` and `queue_free` on the contact frame, which would delete
	## the rock the post-contact trace is measuring. The C2 weapon probe carries 100 units
	## for the same reason ("no case empties its own fixture"). The crack path itself is
	## measured by the C5 suite instead.
	rock.call(&"setup", &"iron", 1, 100, AsteroidScript.SIZE_MEDIUM)
	var mask := int(cfg["mask"])
	if mask >= 0:
		rock.collision_mask = mask
	if kind == "stub":
		_stub = rock
	return rock


func _announce(cfg: Dictionary) -> void:
	print("[C1-RAM] --- %s ---" % _scenario_id)
	print("[C1-RAM] %s kind=%s driven=%s rock layer=%d mask=%d mass=%.1f damp=%.3f radius=%.2f"
		% [
			_scenario_id, cfg["rock"], _driving,
			_rock.collision_layer, _rock.collision_mask, _rock.mass,
			_rock.linear_damp, _rock_shape_radius(_rock),
		])
	print("[C1-RAM] %s hull body layer=%d mask=%d mass=%.1f damp=%.3f radius=%.2f monitor=%s contacts=%d sleep=%s"
		% [
			_scenario_id, _body.collision_layer, _body.collision_mask, _body.mass,
			_body.linear_damp, _rock_shape_radius(_body),
			_body.contact_monitor, _body.max_contacts_reported, _body.can_sleep,
		])
	print("[C1-RAM] %s rock sinks: apply_collision_damage=%s take_damage=%s damage=%s apply_work=%s"
		% [
			_scenario_id,
			_rock.has_method(&"apply_collision_damage"),
			_rock.has_method(&"take_damage"),
			_rock.has_method(&"damage"),
			_rock.has_method(&"apply_work"),
		])
	print("[C1-RAM] %s solver view: rock mode=%d mass=%.3f inv_mass=%.6f | hull mode=%d mass=%.3f inv_mass=%.6f"
		% [
			_scenario_id,
			PhysicsServer2D.body_get_mode(_rock.get_rid()),
			float(PhysicsServer2D.body_get_param(
				_rock.get_rid(), PhysicsServer2D.BODY_PARAM_MASS
			)),
			_inverse_mass(_rock),
			PhysicsServer2D.body_get_mode(_body.get_rid()),
			float(PhysicsServer2D.body_get_param(
				_body.get_rid(), PhysicsServer2D.BODY_PARAM_MASS
			)),
			_inverse_mass(_body),
		])
	print("[C1-RAM] %s start gap=%.2f ship_v=(%.2f, %.2f) rock_v=(%.2f, %.2f)"
		% [
			_scenario_id, _ship_start.distance_to(_rock_start),
			_body.linear_velocity.x, _body.linear_velocity.y,
			_rock.linear_velocity.x, _rock.linear_velocity.y,
		])


func _step_approach() -> void:
	_frame += 1
	## The velocity the step that is about to run will actually see: the top-of-frame value
	## after the driver re-asserts the fixed step. The trace keeps the top-of-frame figure
	## instead, so the flight model's per-step decay stays visible.
	var entry_ship_v := _body.linear_velocity
	_pre_rock_v = _rock.linear_velocity
	_pre_gap = _rock.global_position.distance_to(_body.global_position)
	_min_gap = minf(_min_gap, _pre_gap)
	_approach_tail.append(_sample(_frame, _pre_gap, entry_ship_v, _pre_rock_v))
	while _approach_tail.size() > TRACE_BEFORE:
		_approach_tail.remove_at(0)
	if _driving:
		_body.linear_velocity = Vector2(APPROACH_SPEED, 0.0)
	_pre_ship_v = _body.linear_velocity
	if _frame >= APPROACH_BUDGET:
		print("[C1-RAM] %s NO CONTACT in %d frames: min gap=%.2f ship_v=(%.2f, %.2f) rock moved=%.3f"
			% [
				_scenario_id, _frame, _min_gap,
				_body.linear_velocity.x, _body.linear_velocity.y,
				_rock.global_position.distance_to(_rock_start),
			])
		_end_scenario()


func _step_after() -> void:
	_frame += 1
	_phase_frames += 1
	var rock_speed := _rock.linear_velocity.length()
	_rock_peak_speed = maxf(_rock_peak_speed, rock_speed)
	if _phase_frames <= TRACE_AFTER:
		_trace.append(_sample(
			_frame,
			_rock.global_position.distance_to(_body.global_position),
			_body.linear_velocity,
			_rock.linear_velocity
		))
	if _phase_frames >= SETTLE_FRAMES:
		_end_scenario()


## The probe's own contact listener on the shipped `HullBody`, connected alongside the
## ship's. It fires during the physics step, so it reads the pre-impact figures captured at
## the top of this frame -- exactly the pair `PlayerShip._closing_speed` reads.
func _on_body_entered(other: Node) -> void:
	if _contact_seen:
		return
	_contact_seen = true
	_contact_frame = _frame
	var peer := other as Node2D
	var offset := Vector2.ZERO
	if peer != null:
		offset = peer.global_position - _body.global_position
	var relative := _pre_ship_v - _pre_rock_v
	var direction := relative.normalized() if not relative.is_zero_approx() else Vector2.ZERO
	if offset.length_squared() > 0.0001:
		direction = offset.normalized()
	var closing := maxf(relative.dot(direction), 0.0)
	var rigid := other as RigidBody2D
	var script := other.get_script() as Script
	var ship_last: Variant = _ship.get(&"_last_velocity")
	_contact = {
		"frame": _frame,
		"peer": String(other.name),
		"peer_script": script.resource_path if script != null else "<none>",
		"peer_layer": rigid.collision_layer if rigid != null else -1,
		"peer_mask": rigid.collision_mask if rigid != null else -1,
		"gap": _pre_gap,
		"closing": closing,
		"ship_last_velocity": ship_last if ship_last is Vector2 else Vector2.ZERO,
		"rock_v_pre": _pre_rock_v,
		"has_sink": other.has_method(&"apply_collision_damage"),
		"contact_count": _body.get_contact_count(),
		"colliding": _body.get_colliding_bodies().size(),
		"damage_at_closing": ImpactScript.collision_damage(
			_body.mass, rigid.mass if rigid != null else INF, closing
		),
	}
	_phase = PHASE_AFTER
	_phase_frames = 0


func _end_scenario() -> void:
	_report()
	_scenario_index += 1
	if _scenario_index >= SCENARIOS.size():
		_finish()
		return
	_phase = PHASE_COOLDOWN
	_phase_frames = COOLDOWN_FRAMES


func _report() -> void:
	var id := _scenario_id
	for line in _approach_tail:
		print("[C1-RAM] %s pre  %s" % [id, line])
	if _contact.is_empty():
		print("[C1-RAM] %s contact=NO" % id)
	else:
		print("[C1-RAM] %s contact=YES frame=%d gap=%.2f closing=%.2f peer=%s (%s) layer=%d mask=%d"
			% [
				id, int(_contact["frame"]), float(_contact["gap"]),
				float(_contact["closing"]), _contact["peer"], _contact["peer_script"],
				int(_contact["peer_layer"]), int(_contact["peer_mask"]),
			])
		print("[C1-RAM] %s closing arithmetic: hull _last_velocity=(%.3f, %.3f) rock_v_pre=(%.3f, %.3f) dot=%.2f"
			% [
				id,
				(_contact["ship_last_velocity"] as Vector2).x,
				(_contact["ship_last_velocity"] as Vector2).y,
				(_contact["rock_v_pre"] as Vector2).x,
				(_contact["rock_v_pre"] as Vector2).y,
				float(_contact["closing"]),
			])
		print("[C1-RAM] %s engine view: contact_count=%d colliding_bodies=%d peer_has_sink=%s"
			% [
				id, int(_contact["contact_count"]), int(_contact["colliding"]),
				_contact["has_sink"],
			])
		print("[C1-RAM] %s Impact.collision_damage(%.1f, %.1f, %.2f)=%.3f (floor COLLISION_MIN_DV=%.1f)"
			% [
				id, _body.mass, _rock.mass, float(_contact["closing"]),
				float(_contact["damage_at_closing"]), ImpactScript.COLLISION_MIN_DV,
			])
	for line in _trace:
		print("[C1-RAM] %s post %s" % [id, line])
	var rock_delta := _rock.global_position - _rock_start
	print("[C1-RAM] %s rock: v_at_contact=(%.3f, %.3f) v_peak=%.3f v_final=(%.3f, %.3f) pos_delta=(%.3f, %.3f) |d|=%.3f"
		% [
			id,
			(_contact.get("rock_v_pre", Vector2.ZERO) as Vector2).x,
			(_contact.get("rock_v_pre", Vector2.ZERO) as Vector2).y,
			_rock_peak_speed,
			_rock.linear_velocity.x, _rock.linear_velocity.y,
			rock_delta.x, rock_delta.y, rock_delta.length(),
		])
	print("[C1-RAM] %s rock pools: yield %s -> %s, work %s -> %s, sink_hits=%s sink_total=%s"
		% [
			id, _show(_pools["rock_yield"]), _show(_rock.get(&"yield_units")),
			_show(_pools["rock_work"]), _show(_rock.get(&"work")),
			_stub.get(&"sink_hits") if _stub != null else "<no sink>",
			_stub.get(&"sink_total") if _stub != null else "<no sink>",
		])
	print("[C1-RAM] %s ship pools: hull %.3f -> %.3f (delta %+.3f) shield %.3f -> %.3f (delta %+.3f)"
		% [
			id, float(_pools["ship_hull"]), float(_state.get(&"hull")),
			float(_state.get(&"hull")) - float(_pools["ship_hull"]),
			float(_pools["ship_shield"]), float(_state.get(&"shield")),
			float(_state.get(&"shield")) - float(_pools["ship_shield"]),
		])
	print("[C1-RAM] %s ship body end: pos=(%.3f, %.3f) travelled=%.3f v=(%.3f, %.3f)"
		% [
			id, _body.global_position.x, _body.global_position.y,
			_ship_start.distance_to(_body.global_position),
			_body.linear_velocity.x, _body.linear_velocity.y,
		])


func _record_pools() -> void:
	_pools = {
		"ship_hull": _state.get(&"hull"),
		"ship_shield": _state.get(&"shield"),
		"rock_yield": _rock.get(&"yield_units"),
		"rock_work": _rock.get(&"work"),
	}


func _sample(frame: int, gap: float, ship_v: Vector2, rock_v: Vector2) -> String:
	return "f%-4d gap=%7.2f ship_v=(%7.2f,%7.2f) rock_v=(%7.2f,%7.2f)" % [
		frame, gap, ship_v.x, ship_v.y, rock_v.x, rock_v.y,
	]


func _rock_shape_radius(body: Node) -> float:
	for child: Node in body.get_children():
		var shape := child as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			return (shape.shape as CircleShape2D).radius
	return 0.0


## A pool value that a non-rock peer (the bare control) simply does not carry.
func _show(value: Variant) -> String:
	return "<none>" if value == null else str(value)


## The mass the solver actually divides by. `BODY_PARAM_MASS` is the parameter the server
## holds; a RigidBody2D that the solver treats as immovable reports an inverse mass of
## zero here, which is the difference this probe is looking for.
func _inverse_mass(body: RigidBody2D) -> float:
	var mass := float(PhysicsServer2D.body_get_param(
		body.get_rid(), PhysicsServer2D.BODY_PARAM_MASS
	))
	if mass <= 0.0:
		return 0.0
	return 1.0 / mass


func _clear_fixture() -> void:
	if _body != null and is_instance_valid(_body):
		if _body.body_entered.is_connected(_on_body_entered):
			_body.body_entered.disconnect(_on_body_entered)
	_body = null
	if _ship != null and is_instance_valid(_ship):
		remove_child(_ship)
		_ship.free()
	_ship = null
	_state = null
	if _rock != null and is_instance_valid(_rock):
		remove_child(_rock)
		_rock.free()
	_rock = null
	_stub = null


func _finish() -> void:
	_floor_sweep()
	print("[C1-RAM] done")
	get_tree().quit(0)


## The third candidate cause, measured as arithmetic rather than as a ram: where the
## 40 u/s floor of `game/impact.gd:26` actually bites, against the two closing speeds this
## run measured (the driven 446.77 and the coasting 272.171) and the vanguard's own
## section 13 mass 110 against the rock's 560. `Impact.collision_damage` is pure
## arithmetic, so this needs no world and cannot be an artefact of the harness.
func _floor_sweep() -> void:
	print("[C1-RAM] floor sweep: Impact.collision_damage(110.0, 560.0, v), COLLISION_MIN_DV=%.1f COLLISION_FACTOR=%.8f"
		% [ImpactScript.COLLISION_MIN_DV, ImpactScript.COLLISION_FACTOR])
	for speed: float in [0.0, 20.0, 39.9, 40.0, 41.0, 100.0, 272.171, 446.77, 450.0]:
		print("[C1-RAM] floor sweep v=%8.3f -> damage=%10.6f"
			% [speed, ImpactScript.collision_damage(110.0, 560.0, speed)])
