extends McpTestSuite
## Suite s22_balance: wave S22's flight and balance rows, the S22-B3 subset - the
## seeker fuze's two thresholds (A9 / L25, ticks T-feel-1/1b; 18_engine_spec.md
## section 13's Rocket fuze row), the NPC midline drag's twin (A9 / L103, tick
## T-feel-2; CONTRACTS section 14's disclosure), the release ramp re-verified
## (A9 / L182, tick T-feel-3), the repair transaction's one figure (A10 / L168+L244,
## R-S22-1, tick M4) and the proportional spill (A11 / L242, R-S22-2, tick M5).
##
## Contract: `S22_BRIEF.md` section 4's six rules and section 6's A9-A11; D15's tick
## sheet (`S22_BRIEF.md` section 11); `docs/gameplay/18_engine_spec.md` sections
## 3.1/3.2/13; `docs/CONTRACTS.md` sections 14/22/23.5; `docs/gameplay/01_economy_core.md`
## section 6's 2026-09-27 P3 block (R-S22-1); `docs/gameplay/09_ship_slots_modules.md`
## section 3.3's P3 block (R-S22-2/3/4).
##
## R-S22-3 (S19's initials stand) and R-S22-4 (the per-cell magazine model is kept)
## are dispositions, not code: they are tabled in `S22-B3_report.md` and carry no row
## here. The two A9 verify-halves - T-feel-3's ramp and CONTRACTS section 22's struck
## T3 - are measured/cited in the report; the ramp's own row below re-proves the
## shipped one-decay release.
##
## Every fixture is built by hand (the `test_s2_6_flight.gd` pattern): no frame is
## awaited, so the physics server never integrates a hull the runner builds - the
## flight rows integrate the force the law applied through the hull's
## `applied_force()` seam, and the projectile rows drive `_physics_process` directly.

const ProjectileScript := preload("res://game/projectile.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const ShipFitScript := preload("res://game/ship_fit.gd")
const RepairsScript := preload("res://game/repairs.gd")
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const HULL: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_ARCHETYPE: StringName = &"pirate"

## The standard Vanguard fit's resolved pair (R-S22-1): 1000 + `h_plate_light`'s 250
## hull, 600 + `s_light`'s 200 shield - the figure both the pane and the transaction
## now read. Asserted against `ShipFit.resolve` in the row, so the constant cannot drift.
const HULL_MAX := 1250
const SHIELD_MAX := 800

## The skid fixture: 200 u/s of pure lateral velocity, the speed L182's own probe used.
const SKID_SPEED := 200.0
## Both flight rows settle inside this budget or the row fails loudly.
const SETTLE_BUDGET := 30.0
## The NPC twin must land within 2 % of the player's own release rate.
const SKID_TOLERANCE := 0.02
## Axial and lateral releases must land within 2 % of each other (§23.5's acceptance).
const RELEASE_TOLERANCE := 0.02

const SCRATCH_PROFILE := "user://test_s22_balance.cfg"

var _roots: Array[Node2D] = []
var _shots: Array[Node2D] = []


func suite_name() -> String:
	return "s22_balance"


func teardown() -> void:
	for shot: Node2D in _shots:
		if is_instance_valid(shot):
			shot.free()
	_shots.clear()
	for node: Node2D in _roots:
		if is_instance_valid(node):
			node.free()
	_roots.clear()


func suite_teardown() -> void:
	teardown()
	_delete_file(SCRATCH_PROFILE)


## ---------------------------------------------------------------------------
## A9 (L25) - the seeker fuze's two thresholds
## ---------------------------------------------------------------------------


func test_a9_the_seeker_fuse_is_the_ticked_pair() -> void:
	assert_eq(ProjectileScript.SEEKER_FUSE, 80.0, "T-feel-1: the 80 u proxy detonation")
	assert_eq(ProjectileScript.SEEKER_FUSE_S, 6.0, "T-feel-1b: the 6 s flight fuze")
	print("[S22B3] A9 fuse proxy=%.1f u flight=%.1f s" % [
		ProjectileScript.SEEKER_FUSE, ProjectileScript.SEEKER_FUSE_S
	])


## The proxy door: a lock sitting 79 u off the flight line detonates the shot and the
## warhead lands on the lock. `turn_rate` 0.0 keeps the flight a straight line, so the
## frame the distance crosses 80 u is arithmetic and not a pursuit; the 1/60 s steps
## keep the pre-existing "arrival" door's own reach (one frame's travel, 15 u) far
## outside the 79 u pass, so the reading can only be the fuse's.
func test_a9_a_near_miss_inside_the_fuse_detonates_on_the_lock() -> void:
	var lock := _npc(Vector2(400.0, 79.0))
	var hull_before := float(lock.call(&"hull"))
	var shot := _rocket(lock)
	for _frame: int in 30:
		_step(shot, 1.0 / 60.0)
		if bool(shot.get(&"_spent")):
			break
	assert_true(bool(shot.get(&"_spent")), "a 79 u pass is inside the fuse")
	assert_true(
		float(shot.get(&"_flight_clock")) < ProjectileScript.SEEKER_FUSE_S,
		"and it was the proxy that fired, not the flight fuze"
	)
	assert_true(
		is_equal_approx(hull_before - float(lock.call(&"hull")), 180.0),
		"the warhead's 180 alpha landed on the lock"
	)


## The other side of the 80 u line: an 81 u pass is outside it, and the shot flies on
## (its clock has not reached the fuze either).
func test_a9_a_pass_outside_the_fuse_does_not_detonate() -> void:
	var lock := _npc(Vector2(400.0, 81.0))
	var hull_before := float(lock.call(&"hull"))
	var shot := _rocket(lock)
	for _frame: int in 60:
		_step(shot, 1.0 / 60.0)
	assert_false(bool(shot.get(&"_spent")), "an 81 u pass is outside the fuse")
	assert_true(is_equal_approx(float(lock.call(&"hull")), hull_before), "nothing landed")
	assert_true(
		float(shot.get(&"_flight_clock")) < ProjectileScript.SEEKER_FUSE_S,
		"and the flight fuze is still seconds away"
	)


## The time door: with a lock the shot cannot reach, the sixth second detonates it and
## the warhead still lands on the lock the fuze names. 0.5 s steps are exact in binary,
## so the reading is 5.5 s -> alive, 6.0 s -> spent.
func test_a9_the_flight_fuze_expires_at_six_seconds() -> void:
	var lock := _npc(Vector2(-4000.0, 0.0))
	var hull_before := float(lock.call(&"hull"))
	var shot := _rocket(lock)
	for _second_half: int in 11:
		_step(shot, 0.5)
	assert_false(bool(shot.get(&"_spent")), "5.5 s in, the fuze has not expired")
	assert_true(
		is_equal_approx(float(shot.get(&"_flight_clock")), 5.5), "the flight clock reads 5.5 s"
	)
	_step(shot, 0.5)
	assert_true(bool(shot.get(&"_spent")), "the sixth second detonates the lock")
	assert_true(
		is_equal_approx(float(shot.get(&"_flight_clock")), 6.0), "at exactly the 6 s fuze"
	)
	assert_true(
		is_equal_approx(hull_before - float(lock.call(&"hull")), 180.0),
		"and the warhead lands on the lock the fuze names"
	)


## A dumb-fired rocket has no lock to fuze: the clock never runs and the shot flies past
## 6.5 s of steps untouched.
func test_a9_a_dumb_fired_rocket_has_no_fuse() -> void:
	var shot := _rocket(null)
	for _second_half: int in 13:
		_step(shot, 0.5)
	assert_false(bool(shot.get(&"_spent")), "no lock, no fuze")
	assert_true(is_zero_approx(float(shot.get(&"_flight_clock"))), "and the clock never started")


## ---------------------------------------------------------------------------
## A9 (L103) - the NPC midline drag twin
## ---------------------------------------------------------------------------


## The disclosure's binding clause (CONTRACTS section 14): "the NPC skid then settles at
## the player's rate". Same hull, same 200 u/s pure skid, both laws measured by
## integrating the force each one hands its body.
func test_a9_the_npc_skid_settles_at_the_players_rate() -> void:
	var npc := _npc()
	assert_true(npc.has_method(&"_step_lateral_drag"), "the NPC carries its own twin")
	var npc_t10 := _npc_skid_t10(npc)
	var pair := _launch(FIGHTER)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the player fixture did not build")
		return
	var player_t10 := _player_release_t10(ship, Vector2(0.0, SKID_SPEED))
	print("[S22B3] A9 skid npc t_10=%.3f s player t_10=%.3f s (coast_time=%.3f, damp=%.4f)" % [
		npc_t10, player_t10, float(stats.coast_time), 1.0 / float(stats.coast_time)
	])
	assert_true(npc_t10 > 0.0 and player_t10 > 0.0, "both fixtures settled inside the budget")
	assert_true(
		absf(npc_t10 - player_t10) / maxf(npc_t10, player_t10) <= SKID_TOLERANCE,
		"the NPC skid settles at the player's rate (npc %.3f s vs player %.3f s)" % [
			npc_t10, player_t10
		]
	)


## ---------------------------------------------------------------------------
## A9 (L182, tick T-feel-3) - the release ramp, re-verified
## ---------------------------------------------------------------------------


## The shipped ramp: one decay owns both axes, so an axial and a lateral release of the
## same speed ride the same curve (§23.5's acceptance; the ramp itself is the tick).
func test_a9_the_release_ramp_owns_both_axes() -> void:
	var pair := _launch(HULL)
	var ship: Variant = pair[0]
	var stats: Variant = pair[1]
	if ship == null or stats == null:
		assert_true(false, "the hull fixture did not build")
		return
	assert_true(
		is_equal_approx(float(ship.call(&"_lateral_damp")), float(ship.call(&"_linear_damp"))),
		"one rate owns both axes"
	)
	assert_true(
		is_zero_approx(float(ship.call(&"_lateral_extra_damp"))),
		"and the retired lateral drag is still exactly 0.0"
	)
	var axial := _player_release_t10(ship, Vector2(float(stats.max_speed), 0.0))
	var lateral := _player_release_t10(ship, Vector2(0.0, float(stats.max_speed)))
	print("[S22B3] A9 release ramp axial=%.3f s lateral=%.3f s" % [axial, lateral])
	assert_true(axial > 0.0 and lateral > 0.0, "both releases settled inside the budget")
	assert_true(
		absf(axial - lateral) / maxf(axial, lateral) <= RELEASE_TOLERANCE,
		"axial and lateral releases ride the same ramp (%.3f s vs %.3f s)" % [axial, lateral]
	)


## ---------------------------------------------------------------------------
## A10 (L168/L244, R-S22-1, tick M4) - the fee and the pane rows read one figure
## ---------------------------------------------------------------------------


func test_a10_the_fee_and_the_pane_resolve_one_figure() -> void:
	var profile := _scratch_profile()
	var resolved: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	assert_eq(int(round(resolved.hull_max)), HULL_MAX, "the standard fit's resolved hull")
	assert_eq(int(round(resolved.shield_max)), SHIELD_MAX, "and its resolved shield")
	var service: Dictionary = RepairsScript._maxima(profile, HULL)
	assert_eq(int(service[&"hull"]), HULL_MAX, "the service reads the resolved hull")
	assert_eq(int(service[&"shield"]), SHIELD_MAX, "and the resolved shield")
	var pane: Control = RepairsPanelScript.new()
	var printed: Dictionary = pane.call(&"_pool_maxima", profile, HULL)
	assert_eq(printed, service, "the pane and the service resolve the same pair")
	pane.free()
	profile.call(&"set_vitals", HULL, 200, 300)
	assert_eq(RepairsScript.fee(profile, HULL), 692, "(1050 / 2) + (500 / 3), that pair")
	var result: Dictionary = RepairsScript.repair(profile, HULL)
	assert_eq(int(result[&"hull_max"]), HULL_MAX, "the transaction restores to the same hull")
	assert_eq(int(result[&"shield_max"]), SHIELD_MAX, "and the same shield")
	var vitals: Dictionary = profile.call(&"vitals_of", HULL)
	assert_eq(int(vitals[&"hull"]), HULL_MAX, "the pane's HULL row prints that ceiling")
	assert_eq(int(vitals[&"shield"]), SHIELD_MAX, "and its SHIELD row the same")
	print("[S22B3] A10 figure hull=%d shield=%d fee=%d" % [
		HULL_MAX, SHIELD_MAX, int(result[&"fee"])
	])


## The pane's button reads the same pair as its figures (R-S22-1's "one figure"): a
## hull that is missing points against the resolved ceiling is offered, a full one is
## not, and a catalogue-ceiling reading between the two cannot strand a live repair.
func test_a10_the_pane_button_reads_the_resolved_pair() -> void:
	var profile := _scratch_profile()
	profile.call(&"set_vitals", HULL, 1000, 600)
	assert_true(
		RepairsScript.is_repairable(profile, HULL),
		"a reading at the catalogue ceiling is still damaged against the resolved one"
	)
	assert_gt(RepairsScript.fee(profile, HULL), 0, "and owes a fee")
	profile.call(&"set_vitals", HULL, HULL_MAX, SHIELD_MAX)
	assert_false(RepairsScript.is_repairable(profile, HULL), "a full resolved hull is offered nothing")
	assert_eq(RepairsScript.fee(profile, HULL), 0, "at a zero fee")


## ---------------------------------------------------------------------------
## A11 (L242, R-S22-2, tick M5) - the proportional spill
## ---------------------------------------------------------------------------


## The acceptance's own arithmetic: a 400 hit on `[200, 100, 0, 0]` lands 300 and kills,
## and `hull == sum(pools)` holds exactly.
func test_a11_the_spill_conserves_damage_on_the_l242_vector() -> void:
	var state := _state(400.0)
	state.set(&"hull", 300.0)
	state.set(&"armour_prow", 200.0)
	state.set(&"armour_stern", 100.0)
	state.set(&"armour_port", 0.0)
	state.set(&"armour_starboard", 0.0)
	state.set_shield(0.0)
	state.damage(400.0, true, _ctx(0.0))
	print("[S22B3] A11 spill 400 on [200,100,0,0]: pools=[%.6f,%.6f,%.6f,%.6f] hull=%.6f" % [
		state.pool_of(&"prow"), state.pool_of(&"stern"), state.pool_of(&"port"),
		state.pool_of(&"starboard"), state.hull
	])
	assert_true(is_equal_approx(state.pool_of(&"prow"), 0.0), "the routed pool emptied")
	assert_true(is_equal_approx(state.pool_of(&"stern"), 0.0), "the only pool with room took it all")
	assert_true(is_equal_approx(state.pool_of(&"port"), 0.0), "a breached pool takes nothing")
	assert_true(is_equal_approx(state.pool_of(&"starboard"), 0.0), "and neither does its twin")
	assert_true(is_equal_approx(state.hull, 0.0), "the 400 hit landed 300 and killed")
	assert_true(_pool_sum(state) == state.hull, "hull == sum(pools) exactly")


## The law behind it: the remainder re-offers **proportional to remaining capacity**, so
## a 300/100 split takes 3:1 of a 200 remainder where the retired even split would have
## clamped the small pool and under-landed.
func test_a11_the_spill_is_proportional_to_remaining_capacity() -> void:
	var state := _state(400.0)
	state.set(&"armour_prow", 0.0)
	state.set(&"armour_stern", 300.0)
	state.set(&"armour_port", 100.0)
	state.set(&"armour_starboard", 0.0)
	state.set(&"hull", 400.0)
	state.set_shield(0.0)
	var before := state.hull
	state.damage(200.0, true, _ctx(0.0))
	assert_true(is_equal_approx(state.pool_of(&"stern"), 150.0), "the larger pool takes the larger share")
	assert_true(is_equal_approx(state.pool_of(&"port"), 50.0), "the smaller one its proportional share")
	assert_true(is_equal_approx(state.pool_of(&"prow"), 0.0), "the empty routed pool takes nothing")
	assert_true(is_equal_approx(before - state.hull, 200.0), "the landed total is the incoming amount")
	assert_true(_pool_sum(state) == state.hull, "hull == sum(pools) exactly")
	print("[S22B3] A11 proportional: stern=%.3f port=%.3f hull=%.3f (was 400)" % [
		state.pool_of(&"stern"), state.pool_of(&"port"), state.hull
	])


## The capacity doors: a remainder larger than the surviving capacity lands all of it and
## stops (all pools empty); a remainder that fits lands whole in one pass.
func test_a11_the_spill_stops_when_every_pool_is_empty() -> void:
	var state := _state(400.0)
	state.set(&"armour_prow", 50.0)
	state.set(&"armour_stern", 50.0)
	state.set(&"armour_port", 0.0)
	state.set(&"armour_starboard", 0.0)
	state.set(&"hull", 100.0)
	state.set_shield(0.0)
	state.damage(600.0, true, _ctx(0.0))
	assert_true(is_equal_approx(state.hull, 0.0), "all 100 points landed and the hull died")
	assert_true(is_equal_approx(state.pool_of(&"stern"), 0.0), "with the spare re-offer emptied")
	assert_true(_pool_sum(state) == state.hull, "hull == sum(pools) exactly")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _state(hull_max: float) -> PlayerState:
	var state := PlayerState.new()
	state.hull_max = hull_max
	state.shield_max = 0.0
	state.setup()
	return state


func _ctx(direction: float) -> Dictionary:
	return {PlayerState.CTX_DIRECTION: direction}


func _pool_sum(state: PlayerState) -> float:
	var total := 0.0
	for quadrant: StringName in PlayerState.QUADRANTS:
		total += state.pool_of(quadrant)
	return total


## A staged seeker: the shipped rocket row's numbers, the lock (or null) as `target`, and
## `range` 0.0 so the range fizzle cannot end a row before the fuze door under test does.
func _rocket(lock: Node2D) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.name = "BalanceRocket"
	shot.call(&"configure", {
		&"kind": &"rocket",
		&"speed": 900.0,
		&"damage": 180.0,
		&"bypass_shield": true,
		&"homing": true,
		&"turn_rate": 0.0,
		&"range": 0.0,
		&"mass": 1.0,
		&"chip": 0.0,
		&"direction": Vector2.RIGHT,
		&"target": lock,
	})
	_fixture_host().add_child(shot)
	shot.global_position = Vector2.ZERO
	_shots.append(shot)
	return shot


func _step(shot: Node2D, delta: float) -> void:
	if shot != null and is_instance_valid(shot):
		shot.call(&"_physics_process", delta)


## The NPC fixture: a real hull of the registry, no brain so only the flight law moves it.
## Its `take_damage` is the projectile's own sink, so a lock it can also be hit.
func _npc(at: Vector2 = Vector2.ZERO) -> Node2D:
	var npc: Node2D = NpcShipScript.new()
	npc.name = "BalanceNpc"
	_fixture_host().add_child(npc)
	npc.global_position = at
	npc.call(
		&"setup",
		NPC_ARCHETYPE,
		ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT),
		NPC_HULL,
		{&"home": at, &"space_owner": &"concord"}
	)
	npc.set(&"_brain", null)
	_roots.append(npc)
	return npc


## One launched player hull (the `test_s2_6_flight.gd` fixture): the snapshot, a state,
## the scene, and the shipped flight law driving it.
func _launch(hull_id: StringName) -> Array:
	var stats: ShipStats = ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT)
	if stats == null:
		return [null, null]
	var state := PlayerState.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	if ship == null:
		return [null, null]
	_fixture_host().add_child(ship)
	ship.global_position = Vector2.ZERO
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	ship.call(&"set_aim_point", Vector2.ZERO)
	_roots.append(ship)
	return [ship, stats]


## The NPC's sideways skid: a pure lateral velocity, the drag's own force plus the
## engine's body damp integrated the way the physics server would (the runner never
## steps a frame), until it reaches 10 % of the release speed.
func _npc_skid_t10(npc: Node2D) -> float:
	var body := npc.call(&"impact_body") as RigidBody2D
	if body == null:
		return -1.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var velocity := Vector2(0.0, SKID_SPEED)
	var t := 0.0
	while t < SETTLE_BUDGET:
		body.global_rotation = 0.0
		body.linear_velocity = velocity
		var before: Vector2 = npc.call(&"applied_force")
		npc.call(&"_apply_intent", Vector2.ZERO, 0.0, dt)
		var force: Vector2 = npc.call(&"applied_force") - before
		velocity += (force / body.mass - velocity * body.linear_damp) * dt
		t += dt
		if velocity.length() <= SKID_SPEED * 0.1:
			return t
	return -1.0


## The player's release of the same velocity: one `_physics_process` per step, the force
## the release law applied plus the body's own damp integrated by this suite (no input
## is held, so the released state owns the frame).
func _player_release_t10(ship: Node2D, velocity: Vector2) -> float:
	var body := ship.call(&"impact_body") as RigidBody2D
	if body == null:
		return -1.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var carried := velocity
	var start := velocity.length()
	var t := 0.0
	while t < SETTLE_BUDGET:
		body.linear_velocity = carried
		ship.call(&"_physics_process", dt)
		var force: Vector2 = ship.call(&"applied_force")
		carried += (force / body.mass - carried * body.linear_damp) * dt
		t += dt
		if carried.length() <= start * 0.1:
			return t
	return -1.0


## A throwaway profile, the `test_p1_repairs.gd` fixture: its own scratch save path so
## nothing this suite files can reach the live account.
func _scratch_profile() -> Node:
	var profile := ProfileScript.new()
	profile.set(&"save_path", SCRATCH_PROFILE)
	return profile


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the
## runner scene during `_ready` (see `test_engine2_fixes.gd`).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var root: Node = tree.root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root
