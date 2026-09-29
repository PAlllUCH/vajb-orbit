@tool
extends McpTestSuite
## Suite s21_stability: wave S21's stability and playtest fixes, the S21-B1 subset - the
## real death state (L24/A1), the 5-minute wreck window across a scene rebuild (L23/A2),
## ship-vs-ship crash damage charged exactly once (L22/A3), the stale crossing flag
## (L154/A4b), the heat-decay accumulator's rebuild (L150/A9a) and the gate's
## `cancel_jump` plus the NOT ENOUGH CR rung (L152/L153/A9b).
##
## Contract: `S21_BRIEF.md` section 4 (the five rules) and section 5's spec extract;
## `docs/gameplay/18_engine_spec.md` section 2 decision 7, section 2.1 rows 15-16 and
## section 7; `docs/gameplay/11_galactic_map.md` section 2; `docs/gameplay/13_heat_bounty.md`
## section 2; `docs/CONTRACTS.md` section 9. Every number compared against is read off its
## owner (`game.gd`'s own constants, `impact.gd`'s formula, `ShipFit`'s masses) rather than
## restated here.
##
## The live tests instantiate `game.tscn` the way `test_s6_heat.gd` does (the profile
## autoload as the fixture host) and repoint `PlayerProfile.save_path` at a scratch file
## for the length of the suite, so the owner's `user://profile.cfg` is never written.
## `WorldClock.set_override` is the fake clock the wreck window is measured on; it, the
## wreck ledger and the heat bank are all cleared in `teardown`, so no later suite reads
## this one's state. No test awaits a frame: the headless runner calls each `test_*` method
## and drops its return value, so the death frames and the window's seconds are driven by
## calling the shipped `_physics_process` directly (the `test_s2_6_flight.gd` pattern).

const GameScript := preload("res://game/game.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const AsteroidFieldScript := preload("res://game/asteroid_field.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ModuleDataScript := preload("res://game/module_catalog.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PickupScript := preload("res://game/pickup.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const ClockScript := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const StationScript := preload("res://ui/screens/station.gd")
const AuctionScript := preload("res://game/auction.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const ArmoryScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const GAME_SCENE := "res://game/game.tscn"
const STATION_SCENE := "res://ui/screens/station.tscn"
const FITTING_SCENE := "res://ui/station/fitting_panel.tscn"
const ARMORY_SCENE := "res://ui/station/armory_panel.tscn"
const AUCTION_SCENE := "res://ui/station/auction_panel.tscn"
const LAUNCH_SCENE := "res://ui/station/launch_panel.tscn"
const SCRATCH_PROFILE := "user://test_s21_stability.cfg"
const SCRATCH_LOG := "user://test_s21_stability_log.txt"

const HULL_BODY: StringName = &"HullBody"
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"
const ROCK_MINERAL: StringName = &"iron"
const ROCK_UNITS := 100

## The asteroid field's fixture seed: one pinned stream, so the virgin rocks' bores are the
## baseline the respawn's ×0.7 roll is measured against.
const FIELD_SEED := 20260928

## The fake clock: a fixed stamp so the wreck ledger's absolute expiry is arithmetic
## instead of 300 real seconds. `WorldClock` is the one clock 11's own respawn bookkeeping
## already reads, and its override is the seam `test_p1_*` suites use.
const FAKE_NOW := 1_700_000_000
const FAKE_LATER := 120

## One physics frame, and how many the death state is measured over.
const FRAME := 1.0 / 60.0
const DEATH_FRAMES := 24

## The input action the live/dead thrust contrast is driven with (`PlayerShip`'s own
## constant, so a rebind cannot desync this suite).
const THRUST := PlayerShipScript.THRUST_FORWARD


## A bare body with the one door a ram's peer half lands on: "the contact charged
## nothing" is then a call counter and not an absence.
class RamStub extends RigidBody2D:
	var amount := 0.0
	var calls := 0


	func apply_collision_damage(value: float) -> void:
		amount += value
		calls += 1


var _scenes: Array[Node2D] = []
var _nodes: Array[Node] = []
var _previous_path := ""


func suite_name() -> String:
	return "s21_stability"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_scratch_store()
	_reset_shared_state()


## Per-test: nothing static survives into the next row (or the next suite).
func setup() -> void:
	_reset_shared_state()


func teardown() -> void:
	_reset_shared_state()
	_free_scenes()


func suite_teardown() -> void:
	_free_scenes()
	_reset_shared_state()
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## A1 - the real death state (L24, 18 §7)
## ---------------------------------------------------------------------------


## The hull's own inertness over the death frames: thrust held, no force and no torque
## applied, and no momentum added by anything the dead state runs. The live half of the
## same measurement is the control (a hull under the stick does apply thrust).
func test_a_dead_hull_takes_no_input_no_force_and_no_torque() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var ship: Node2D = scene.get(&"_ship")
	var state = scene.get(&"_state")
	assert_true(ship != null and state != null, "the scene launched a hull and its state")
	if ship == null or state == null:
		return
	## A live hull under the stick: the force is the control reading.
	state.call(&"set_fuel", 200.0)
	Input.action_press(THRUST)
	ship.call(&"_physics_process", FRAME)
	Input.action_release(THRUST)
	assert_gt(
		float((ship.call(&"applied_force") as Vector2).length()),
		0.0,
		"a live hull under thrust_forward applies a central force"
	)
	## Hull 0 enters the state through the shipped door (`PlayerState.died`).
	state.call(&"set_hull", 0.0)
	assert_true(bool(ship.call(&"is_dead")), "hull 0 enters the hull's own death state (L24)")
	var body := ship.call(&"impact_body") as RigidBody2D
	var speed_before := body.linear_velocity.length() if body != null else 0.0
	Input.action_press(THRUST)
	for i in DEATH_FRAMES:
		ship.call(&"_physics_process", FRAME)
	Input.action_release(THRUST)
	assert_eq(
		ship.call(&"applied_force"), Vector2.ZERO, "the wreck applies no force over the death frames"
	)
	assert_eq(
		float(ship.call(&"applied_torque")), 0.0, "and no torque"
	)
	if body != null:
		assert_true(
			body.linear_velocity.length() <= speed_before + 1.0e-4,
			"and nothing in the dead frame adds momentum (%.6f -> %.6f)"
			% [speed_before, body.linear_velocity.length()]
		)


## The contact monitor's half of the state: a live hull offers a peer its half once, and
## the same contact against the wreck offers nothing on either side.
func test_a_dead_hulls_contact_monitor_charges_nothing() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var ship: Node2D = scene.get(&"_ship")
	var state = scene.get(&"_state")
	assert_true(ship != null and state != null, "the scene launched a hull and its state")
	if ship == null or state == null:
		return
	var stub := RamStub.new()
	stub.mass = 5.0
	scene.add_child(stub)
	_nodes.append(stub)
	stub.global_position = ship.global_position + Vector2(20.0, 0.0)
	ship.set(&"_last_velocity", Vector2(100.0, 0.0))
	stub.linear_velocity = Vector2(-100.0, 0.0)
	ship.call(&"_on_hull_body_entered", stub)
	assert_eq(stub.calls, 1, "a live hull offers the peer's half of a ram once")
	var pools_before := _pools(state)
	scene.call(&"_on_ship_died")
	ship.call(&"_on_hull_body_entered", stub)
	assert_eq(stub.calls, 1, "the wreck's contact monitor charges nothing (L24)")
	assert_eq(_pools(state), pools_before, "and takes nothing itself")


## §7's order, measured at the death itself: the explosion's own nodes enter the scene,
## then the wreck's pickups, and only then does the respawn route fire - from a hull that
## is already inert and a scene that is already dead.
func test_the_death_order_is_explosion_then_wreck_then_respawn() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the drop's store")
		return
	profile.call(&"add_cargo", &"mineral_iron", 7)
	profile.call(&"add_cargo", &"mineral_copper", 3)
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var order: Array[StringName] = []
	scene.child_entered_tree.connect(
		func(node: Node) -> void:
			order.append(&"drop" if node.get_script() == PickupScript else &"fx")
	)
	var route := {}
	scene.route_requested.connect(
		func(route_name: StringName, params: Dictionary) -> void:
			route[&"name"] = route_name
			route[&"params"] = params
			route[&"drops"] = _pickup_count(scene)
			route[&"inert"] = bool((scene.get(&"_ship") as Node).call(&"is_dead"))
	)
	scene.call(&"_on_ship_died")
	assert_true(bool(scene.get(&"_dead")), "the scene is dead before anything follows")
	assert_eq(_pickup_count(scene), 2, "the wreck dropped one pickup per stack (7 iron, 3 copper)")
	assert_gt(order.size(), 2, "the death added the blast's faces and the wreck's pickups")
	assert_eq(order[0], &"fx", "§7 step 1: the explosion's own nodes enter first")
	assert_eq(order[order.size() - 1], &"drop", "§7 step 2: the wreck's pickups come after them")
	assert_eq(route.get(&"name", &""), &"loading", "§7 step 3: then the respawn route")
	assert_eq(
		route.get(&"params", {}).get(&"destination", &""),
		&"station",
		"which asks for the last station visited (14 §3)"
	)
	assert_true(bool(route.get(&"inert", false)), "from a hull that is already inert")
	assert_eq(int(route.get(&"drops", -1)), 2, "with the hold already over the side")


## ---------------------------------------------------------------------------
## A2 - the 5-minute wreck window (L23, 18 §2 dec. 7 / §7)
## ---------------------------------------------------------------------------


## The seam itself: a drop's window is `DROP_WINDOW` on the pickup's own lifetime (not an
## age offset against the 60 s field lifetime), it is filed in the sector ledger with an
## absolute expiry, and the window's last second - not its 60th - frees it.
func test_a_wreck_drop_carries_the_five_minute_window() -> void:
	ClockScript.set_override(FAKE_NOW)
	_reset_profile()
	var profile := _store()
	if profile == null or not _arm_wreck_drop(profile, 7):
		return
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var wreck: Vector2 = scene.get(&"_ship").global_position
	scene.call(&"_on_ship_died")
	var drops := _pickups(scene)
	assert_eq(drops.size(), 1, "one stack, one pickup")
	if drops.is_empty():
		return
	var pickup: Node2D = drops[0]
	assert_eq(
		float(pickup.get(&"lifetime")),
		GameScript.DROP_WINDOW,
		"the drop's own window is DROP_WINDOW (300 s), through `Pickup.setup`'s seam"
	)
	assert_eq(pickup.global_position, wreck, "dropped at the wreck")
	assert_eq(GameScript._wreck_drops.size(), 1, "and filed in the sector ledger")
	var entry: Dictionary = GameScript._wreck_drops[0]
	assert_eq(
		int(entry.get(&"expires")),
		FAKE_NOW + int(GameScript.DROP_WINDOW),
		"with an absolute five-minute expiry on the one WorldClock"
	)
	assert_eq(String(entry.get(&"sector")), "sector_1", "keyed by the sector it fell in")
	## The fake clock over the pickup's own frames: 299 s of window leave it in the world,
	## the 300th frees it (a 60 s field lifetime would have taken it 240 s ago).
	for i in int(GameScript.DROP_WINDOW) - 1:
		pickup.call(&"_physics_process", 1.0)
		if pickup.is_queued_for_deletion():
			break
	assert_false(
		pickup.is_queued_for_deletion(),
		"299 s of a 300 s window is not its end (a field pickup is gone at 60)"
	)
	pickup.call(&"_physics_process", 1.1)
	assert_true(pickup.is_queued_for_deletion(), "and the window's last second frees it")


## The window across the two rebuilds L23 names: the respawn route discards the flight
## scene and a crossing rebuilds it, and the drop comes back with the seconds it has left.
## Past the expiry it is gone for good and the ledger is pruned.
func test_the_wreck_window_survives_the_respawn_route_and_a_crossing() -> void:
	ClockScript.set_override(FAKE_NOW)
	_reset_profile()
	var profile := _store()
	if profile == null or not _arm_wreck_drop(profile, 7):
		return
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var wreck: Vector2 = scene.get(&"_ship").global_position
	scene.call(&"_on_ship_died")
	assert_eq(_pickups(scene).size(), 1, "the drop exists where the wreck was")
	## The respawn route lands the station, so the scene is discarded; 120 s later the next
	## launch's scene re-materialises what the window has left.
	ClockScript.set_override(FAKE_NOW + FAKE_LATER)
	_close_game(scene)
	var arrived := _open_game()
	if arrived == null:
		assert_true(false, "the rebuilt scene instantiates")
		return
	var drops := _pickups(arrived)
	assert_eq(drops.size(), 1, "the window survived the respawn route's rebuild (L23)")
	if drops.is_empty():
		return
	assert_eq(
		float(drops[0].get(&"lifetime")),
		GameScript.DROP_WINDOW - float(FAKE_LATER),
		"with the seconds it had left, not the full window again"
	)
	assert_eq(drops[0].global_position, wreck, "at the wreck's own position")
	## A crossing draws another sector, so this sector's face comes down while its entry
	## keeps the window (11 §2.3 resets the fields' spawns, not the wreck's recovery).
	arrived.call(&"on_route", {&"sector": &"sector_2"})
	assert_eq(_pickups(arrived).size(), 0, "another sector draws none of the drop")
	assert_eq(GameScript._wreck_drops.size(), 1, "but the entry keeps its window")
	arrived.call(&"on_route", {&"sector": &"sector_1"})
	assert_eq(_pickups(arrived).size(), 1, "crossing back re-materialises the drop")
	## Past the expiry: gone, and pruned from the ledger.
	ClockScript.set_override(FAKE_NOW + int(GameScript.DROP_WINDOW) + 1)
	_close_game(arrived)
	var late := _open_game()
	assert_true(late != null, "a scene after the window boots")
	if late == null:
		return
	assert_eq(_pickups(late).size(), 0, "past its expiry the stack is not drawn")
	assert_eq(GameScript._wreck_drops.size(), 0, "and the ledger has pruned it")


## Collection is the ledger's other door: a stack taken aboard leaves the sector record the
## moment it is taken, and its cargo is back in the hold.
func test_a_collected_wreck_drop_leaves_the_ledger() -> void:
	ClockScript.set_override(FAKE_NOW)
	_reset_profile()
	var profile := _store()
	if profile == null or not _arm_wreck_drop(profile, 7):
		return
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	scene.call(&"_on_ship_died")
	var drops := _pickups(scene)
	assert_eq(drops.size(), 1, "the drop was spawned")
	if drops.is_empty():
		return
	drops[0].call(&"_collect")
	assert_eq(GameScript._wreck_drops.size(), 0, "a collected stack leaves the sector ledger")
	assert_eq(
		int(profile.call(&"cargo_items").get(&"mineral_iron", -1)),
		7,
		"and its cargo is back in the hold"
	)


## ---------------------------------------------------------------------------
## A3 - ship-vs-ship crash damage (L22, 18 §2.1 rows 15-16)
## ---------------------------------------------------------------------------


## The mask half of L22: the shipped hull body names both layers, so a hull-vs-hull pair
## exists for the engine to report - and the rock bit the C5 suite pins is untouched.
func test_the_player_hull_masks_the_ship_layer_so_a_ram_pair_exists() -> void:
	var ship := PlayerShipScene.instantiate() as Node2D
	assert_true(ship != null, "the shipped player_ship.tscn instantiates")
	if ship == null:
		return
	_nodes.append(ship)
	var body := ship.get_node_or_null(NodePath(HULL_BODY)) as RigidBody2D
	assert_true(body != null, "the hull carries its %s" % HULL_BODY)
	if body == null:
		return
	assert_eq(body.collision_layer, NpcShipScript.HULL_LAYER, "still layer 2, the ship layer")
	assert_ne(
		body.collision_mask & NpcShipScript.HULL_LAYER,
		0,
		"the mask names the ship layer (L22: a ram between two hulls resolves)"
	)
	assert_ne(
		body.collision_mask & AsteroidScript.COLLISION_LAYER,
		0,
		"and still names the rock layer, so rocks are unchanged"
	)


## The acceptance's own figure: one impact, both monitors, both halves charged - and the
## totals exactly one charge each, so the pair can never double-charge. The mass rule and
## the initiator tie-break are pinned here too, in the same arithmetic the two hulls run.
func test_a_ship_versus_ship_ram_charges_both_halves_exactly_once() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var ship: Node2D = scene.get(&"_ship")
	var npc := _npc(scene)
	var player_body := ship.call(&"impact_body") as RigidBody2D
	var npc_body := npc.call(&"impact_body") as RigidBody2D
	if player_body == null or npc_body == null:
		assert_true(false, "both hulls carry a body")
		return
	## A head-on pair: equal and opposite approach speeds, so `closing = 2 x 100` on both
	## monitors and the row-15 figure is `Impact`'s own (never restated here).
	ship.global_position = Vector2.ZERO
	npc.global_position = Vector2(NpcShipScript.HULL_LAYER * 30.0, 0.0)
	ship.set(&"_last_velocity", Vector2(100.0, 0.0))
	npc.set(&"_last_velocity", Vector2(-100.0, 0.0))
	player_body.linear_velocity = Vector2(100.0, 0.0)
	npc_body.linear_velocity = Vector2(-100.0, 0.0)
	var figure := ImpactScript.collision_damage(
		player_body.mass, npc_body.mass, 200.0
	)
	assert_gt(figure, 0.0, "the approach is past the 40 u/s floor")
	if figure <= 0.0:
		return
	## The authority is the heavier hull and the verdicts are complementary: exactly one
	## side charges, whichever it is.
	var player_is_authority := PlayerShipScript.ram_authority(ship, npc)
	assert_ne(
		player_is_authority,
		PlayerShipScript.ram_authority(npc, ship),
		"exactly one side of the pair is the authority"
	)
	assert_eq(
		player_is_authority,
		player_body.mass > npc_body.mass,
		"the heavier hull is the authority (row 15's ram authority)"
	)
	var state = scene.get(&"_state")
	var player_pools := _pools(state)
	var npc_pools := {"hull": float(npc.call(&"hull")), "shield": float(npc.call(&"shield"))}
	## The engine reports the impact once per monitor, back to back.
	ship.call(&"_on_hull_body_entered", npc_body)
	npc.call(&"_on_body_entered", player_body)
	var player_after := _pools(state)
	var npc_after := {"hull": float(npc.call(&"hull")), "shield": float(npc.call(&"shield"))}
	assert_true(
		is_equal_approx(_pool_total(player_pools) - _pool_total(player_after), figure),
		"the player's half landed once (%.6f vs %.6f)"
		% [_pool_total(player_pools) - _pool_total(player_after), figure]
	)
	assert_true(
		is_equal_approx(_pool_total(npc_pools) - _pool_total(npc_after), figure),
		"the NPC's half landed once (%.6f vs %.6f)"
		% [_pool_total(npc_pools) - _pool_total(npc_after), figure]
	)


## The tie-break rows the pair-agreement needs beyond the mass rule: at equal masses the
## hull that carried the greater approach speed into the contact (the initiator) is the
## authority, and a perfectly symmetric head-on still answers exactly once.
func test_the_pair_verdict_hands_a_tie_to_the_initiator() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var ship: Node2D = scene.get(&"_ship")
	var npc := _npc(scene)
	var player_body := ship.call(&"impact_body") as RigidBody2D
	var npc_body := npc.call(&"impact_body") as RigidBody2D
	if player_body == null or npc_body == null:
		assert_true(false, "both hulls carry a body")
		return
	ship.global_position = Vector2.ZERO
	npc.global_position = Vector2(60.0, 0.0)
	npc_body.mass = player_body.mass
	ship.set(&"_last_velocity", Vector2(200.0, 0.0))
	npc.set(&"_last_velocity", Vector2.ZERO)
	assert_true(
		PlayerShipScript.ram_authority(ship, npc),
		"an equal mass hands the pair to the hull that rammed"
	)
	assert_false(
		PlayerShipScript.ram_authority(npc, ship),
		"and the rammed hull stands down"
	)
	npc.set(&"_last_velocity", Vector2(-200.0, 0.0))
	assert_ne(
		PlayerShipScript.ram_authority(ship, npc),
		PlayerShipScript.ram_authority(npc, ship),
		"a symmetric head-on still answers exactly once on the pair"
	)


## Rocks are not ships: a rock's ram stays the shipped single-sided course, with the
## rock's own half arriving through its own gun-chip door.
func test_a_rock_ram_is_still_single_sided() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var ship: Node2D = scene.get(&"_ship")
	var rock := _rock(scene)
	var player_body := ship.call(&"impact_body") as RigidBody2D
	if player_body == null or rock == null:
		assert_true(false, "the fixture has a hull and a rock")
		return
	ship.global_position = Vector2.ZERO
	rock.global_position = Vector2(60.0, 0.0)
	rock.linear_velocity = Vector2.ZERO
	ship.set(&"_last_velocity", Vector2(200.0, 0.0))
	player_body.linear_velocity = Vector2(200.0, 0.0)
	var state = scene.get(&"_state")
	var figure := ImpactScript.collision_damage(player_body.mass, rock.mass, 200.0)
	assert_gt(figure, 0.0, "the rock ram is past the floor")
	if figure <= 0.0:
		return
	var pools_before := _pools(state)
	var work_before := float(rock.get(&"work"))
	ship.call(&"_on_hull_body_entered", rock)
	assert_true(
		is_equal_approx(_pool_total(pools_before) - _pool_total(_pools(state)), figure),
		"the player's half is the same one charge (%s)" % str(pools_before)
	)
	assert_gt(float(rock.get(&"work")), work_before, "and the rock's half reached its own door")


## ---------------------------------------------------------------------------
## A4b - the stale crossing flag (L154, 11 §2.3)
## ---------------------------------------------------------------------------


## The flag's whole life: a crossing arms it, a route that lands no game scene drops it, a
## scene that leaves on a route it never armed drops it in `_exit_tree`, and the real
## crossing's flag survives the teardown its successor consumes it after.
func test_a_stale_transit_flag_cannot_survive_an_interrupted_crossing() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	scene.route_requested.connect(
		func(_route_name: StringName, _params: Dictionary) -> void: pass
	)
	scene.call(&"_transition_to_sector", 2)
	assert_eq(
		GameScript._transit_destination,
		&"sector_2",
		"a crossing arms the flag for its successor game scene"
	)
	scene.call(&"_request_dock")
	assert_true(
		GameScript._transit_destination.is_empty(),
		"the station route lands no game scene, so it drops the flag"
	)
	## A scene that never armed it is the interrupted crossing: the dropped route left the
	## flag standing, and the scene now leaves through another door.
	GameScript._transit_destination = &"sector_2"
	_close_game(scene)
	assert_true(
		GameScript._transit_destination.is_empty(),
		"a scene leaving on a route it never armed drops the flag in `_exit_tree`"
	)
	## And the real crossing still works: its own flag survives the scene teardown, and the
	## successor consumes it.
	var crossing := _open_game()
	if crossing == null:
		assert_true(false, "the crossing's scene instantiates")
		return
	crossing.route_requested.connect(
		func(_route_name: StringName, _params: Dictionary) -> void: pass
	)
	crossing.call(&"_transition_to_sector", 2)
	_close_game(crossing)
	assert_eq(
		GameScript._transit_destination,
		&"sector_2",
		"the crossing's own flag survives the teardown"
	)
	var arrived := _open_game()
	assert_true(arrived != null, "the successor scene boots")
	if arrived == null:
		return
	assert_true(
		GameScript._transit_destination.is_empty(),
		"and the successor game scene consumes it (11 §2.3's crossing, not a launch)"
	)


## ---------------------------------------------------------------------------
## A9a - the heat-decay accumulator (L150, 13 §2)
## ---------------------------------------------------------------------------


## 13 §2's "−1 per minute of play, anywhere": the minute in progress is a static beside
## the crossing flag, so a scene rebuild banks it instead of discarding it.
func test_the_heat_minute_survives_a_scene_rebuild() -> void:
	GameScript._heat_play_time = 0.0
	_reset_profile()
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {"concord": 40})
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	scene.call(&"_decay_heat", GameScript.HEAT_DECAY_SECONDS - 0.1)
	assert_eq(_heat_of(profile, &"concord"), 40, "59.9 s of play is not yet a minute")
	_close_game(scene)
	var rebuilt := _open_game()
	if rebuilt == null:
		assert_true(false, "the rebuilt scene instantiates")
		return
	rebuilt.call(&"_decay_heat", 0.2)
	assert_eq(
		_heat_of(profile, &"concord"),
		39,
		"the minute in progress survived the rebuild (L150: the bank is static)"
	)
	assert_true(
		is_equal_approx(GameScript._heat_play_time, 0.1),
		"and the rebuilt scene's own tick carries the leftover, not a fresh bank"
	)


## ---------------------------------------------------------------------------
## A9b - the gate: cancel_jump and the funds rung (L152/L153, 11 §2.1/§5)
## ---------------------------------------------------------------------------


## The three cancels L152 names: leaving the ring, a hull hit, and the hull's death.
func test_a_running_charge_is_called_off_on_zone_exit_damage_and_death() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var profile := _store()
	var gate := _gate(scene)
	var ship: Node2D = scene.get(&"_ship")
	if profile == null or gate == null or ship == null:
		assert_true(false, "the fixture has a profile, a gate ring and a hull")
		return
	var inside: Vector2 = gate.global_position
	ship.global_position = inside
	assert_eq(
		int(gate.call(&"jump", profile, NpcRegistryScript.HEAT_CLEAN)),
		0,
		"a paid confirm starts the 2 s charge-up"
	)
	scene.call(&"_update_dock_prompt")
	assert_true(bool(gate.call(&"is_charging")), "still charging inside the ring")
	## 1. The zone exit.
	ship.global_position = inside + Vector2(4000.0, 0.0)
	scene.call(&"_update_dock_prompt")
	assert_false(
		bool(gate.call(&"is_charging")), "leaving the ring calls the charge off (L152)"
	)
	## 2. Damage.
	ship.global_position = inside
	gate.call(&"jump", profile, NpcRegistryScript.HEAT_CLEAN)
	scene.call(&"_update_dock_prompt")
	scene.call(&"_on_ship_damage_taken", 10.0)
	assert_false(bool(gate.call(&"is_charging")), "a hull hit calls the charge off too")
	## 3. Death.
	gate.call(&"jump", profile, NpcRegistryScript.HEAT_CLEAN)
	scene.call(&"_update_dock_prompt")
	assert_true(bool(gate.call(&"is_charging")), "the third confirm charged")
	scene.call(&"_on_ship_died")
	assert_false(
		bool(gate.call(&"is_charging")), "and hull 0 calls it off (the wreck never crosses)"
	)


## L153's missing rung: a short account reads why, in the same ladder that carries 11 §5's
## Outlaw line, and the priced line comes back the moment it can pay.
func test_the_gate_prompt_gains_the_not_enough_cr_rung() -> void:
	_reset_profile()
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var profile := _store()
	var gate := _gate(scene)
	var ship: Node2D = scene.get(&"_ship")
	if profile == null or gate == null or ship == null:
		assert_true(false, "the fixture has a profile, a gate ring and a hull")
		return
	ship.global_position = gate.global_position
	var fee := int(gate.call(&"fee_for", NpcRegistryScript.HEAT_CLEAN))
	profile.call(&"spend", int(profile.call(&"credits")) - (fee - 1))
	scene.call(&"_update_dock_prompt")
	assert_eq(
		String(scene.get(&"_prompt")),
		GameScript.GATE_REFUSED_FUNDS_PROMPT,
		"one credit short of the fee reads the refusal rung (L153)"
	)
	profile.call(&"add_credits", 2)
	scene.call(&"_update_dock_prompt")
	assert_true(
		String(scene.get(&"_prompt")).begins_with("JUMP TO "),
		"a funded account reads the priced line again (%s)" % String(scene.get(&"_prompt"))
	)
	profile.call(&"set_heat", {"concord": 95})
	scene.call(&"_update_dock_prompt")
	assert_eq(
		String(scene.get(&"_prompt")),
		GameScript.GATE_REFUSED_PROMPT,
		"and 11 §5's Outlaw line is the ladder's first rung, unchanged"
	)


## ---------------------------------------------------------------------------
## A9c - the asteroid field: the respawn's clock and the cleave marker (L73/L215)
## ---------------------------------------------------------------------------


## L73: `respawn(now)`'s `now` is the reading the cycle's own yield roll must be taken
## against. Two rolls of one pinned stream are compared: the field's virgin rocks are the
## stream's full-yield baseline, and the respawn is asked for the same stream through the
## ×0.7 window on a stamp the wall clock reads as long stale - the case a probe or a review
## sheet drives. Before the fix the roll read `Clock.now()` and the rocks came back at the
## baseline instead of the band the stamp had just opened.
func test_the_respawn_window_reaches_the_yield_roll() -> void:
	var field := _field()
	if field == null:
		assert_true(false, "the asteroid field builds")
		return
	var virgin := _bores(field)
	assert_eq(
		virgin.size(),
		int(field.call(&"rocks_per_cycle")),
		"the virgin field rolled its cycle's rocks at full yield"
	)
	var stamp := ClockScript.now() - AsteroidFieldScript.DIMINISHING_WINDOW_SECONDS * 10
	field.call(&"_clear_rocks")
	assert_true(bool(field.call(&"is_depleted")), "the fixture emptied the field through its own clear")
	field.rng.seed = FIELD_SEED
	assert_true(bool(field.call(&"respawn", stamp)), "a depleted field respawns on the driven stamp")
	assert_true(bool(field.call(&"diminishing_active", stamp)), "the driven stamp's window is open")
	assert_false(
		bool(field.call(&"diminishing_active")),
		"while the wall clock alone reads that window expired: one cycle, two clocks (L73)"
	)
	var rolled := _bores(field)
	assert_eq(rolled.size(), virgin.size(), "and rolls the same rock count back")
	var banded := 0
	for index in rolled.size():
		var expected := float(
			maxi(1, roundi(virgin[index] * AsteroidFieldScript.DIMINISHING_YIELD_MULT))
		)
		if is_equal_approx(rolled[index], expected):
			banded += 1
	assert_eq(banded, rolled.size(), "every rock rolled the x0.7 band the stamp opened (L73)")
	## The control: the same stream respawned on the wall clock's own stamp rolls the very
	## same band, so the fix changes which clock is read, never the window it applies.
	field.call(&"_clear_rocks")
	field.rng.seed = FIELD_SEED
	assert_true(
		bool(field.call(&"respawn", ClockScript.now())), "a respawn on the wall clock's own stamp"
	)
	assert_eq(_bores(field), rolled, "reads one window either way: the fix is only the reading")


## L215: the S16 marker is runtime state like the mining flag beside it, so a re-`setup`
## clears it. Left set, a reused instance would keep splitting at bore 0 - the latent
## infinite split the row names - although no shipped path reuses one today.
func test_a_re_setup_rock_is_an_original_again() -> void:
	var rock := AsteroidScript.new() as RigidBody2D
	if rock == null:
		assert_true(false, "a bare rock builds")
		return
	rock.call(&"setup", ROCK_MINERAL, 1, 0, AsteroidScript.SIZE_SMALL)
	assert_false(bool(rock.call(&"cleaves")), "a bore-0 original has nothing to cleave (ruling 17)")
	rock.call(&"mark_cleave_child")
	assert_true(
		bool(rock.call(&"cleaves")), "marked as a cleave's child, the same rock splits (S16)"
	)
	rock.call(&"setup", ROCK_MINERAL, 1, 0, AsteroidScript.SIZE_SMALL)
	assert_false(
		bool(rock.call(&"cleaves")), "and setup clears the marker with its other resets (L215)"
	)
	rock.free()


## ---------------------------------------------------------------------------
## A9d - the armory's MOVED line (L176)
## ---------------------------------------------------------------------------


## The between-rack move's success line is read from the source address **before** the
## record write, so it can name neither nothing nor the wrong barrel. Both cases the old
## order got wrong are measured: a move that empties its source (the line printed
## `MOVED ·  · B2`) and a swap, where the post-write source address holds the other barrel.
func test_the_armory_move_line_names_the_barrel_it_moved() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the armory's store")
		return
	var active := StringName(profile.call(&"active_ship"))
	StringName(profile.call(&"add_instance", &"w_cannon", &"common", [], []))
	StringName(profile.call(&"add_instance", &"w_laser", &"common", [], []))
	assert_true(
		bool(profile.call(&"fit_battery", active, &"w_cannon", [0])), "W1 holds the cannon"
	)
	assert_true(bool(profile.call(&"fit_battery", active, &"w_laser", [1])), "W2 the laser")
	assert_true(
		bool(profile.call(&"set_battery_groups", active, [[0], [1]])), "one barrel per rack"
	)
	var panel := _mount_panel(ARMORY_SCENE)
	if panel == null:
		assert_true(false, "the armory pane mounts")
		return
	profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	var statuses: Array[String] = []
	panel.connect(
		&"status_requested",
		func(message: String, _danger: bool) -> void: statuses.append(message)
	)
	assert_true(bool(panel.call(&"move_barrel", 0, 0, 1, 1)), "B1's cannon moves into B2's tail")
	assert_eq(
		_last_strip(statuses),
		ArmoryScript.STATUS_MOVED % [_module_name(&"w_cannon"), ArmoryScript.RACK_LABEL % 2],
		"the line names the barrel it moved, not the address it emptied (L176)"
	)
	assert_true(
		bool(profile.call(&"set_battery_groups", active, [[0], [1]])), "the racks are re-seated"
	)
	assert_true(bool(panel.call(&"move_barrel", 1, 0, 0, 0)), "B2's laser is dragged onto B1's")
	assert_eq(
		_last_strip(statuses),
		ArmoryScript.STATUS_MOVED % [_module_name(&"w_laser"), ArmoryScript.RACK_LABEL % 1],
		"and a swap names the dragged barrel, never the one that landed in its place (L176)"
	)


## ---------------------------------------------------------------------------
## A4a - booting the station writes nothing (L18/L122)
## ---------------------------------------------------------------------------


## The boot-only run, measured on the profile file itself: the fixture hands the store a
## **stale** market band and an **empty** AUCTION shelf (both would rewrite the file the
## moment anything evaluated them), flushes, mounts `station.tscn` the way the shell does,
## and reads the file's md5, its mtime, the store's dirty flag and both in-memory records
## back. Then the two halves the cure moves the work to: the dock (`on_route`) normalises
## the market, and the shell's switch into the AUCTION pane rolls its shelf.
func test_booting_the_station_writes_nothing_to_user() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the station's store")
		return
	var market := profile.call(&"market") as Dictionary
	market["last_band"] = ClockScript.now() - ClockScript.BAND_SECONDS * 3
	profile.call(&"set_market", market)
	profile.set(&"_auction", {&"last_band": 0, &"hulls": [], &"modules": {}, &"hot": &""})
	profile.call(&"flush")
	assert_false(bool(profile.get(&"_dirty")), "the fixture's own store is flushed before the boot")
	var market_before: Dictionary = profile.call(&"market")
	var shelf_before: Dictionary = profile.call(&"auction")
	var md5_before := FileAccess.get_md5(SCRATCH_PROFILE)
	var mtime_before := FileAccess.get_modified_time(SCRATCH_PROFILE)
	assert_true(FileAccess.file_exists(SCRATCH_PROFILE), "the fixture's store exists on disk")
	assert_true(not md5_before.is_empty(), "and its md5 reads (%s)" % md5_before)
	assert_gt(mtime_before, 0, "with a real mtime")
	var screen := _mount_station()
	if screen == null:
		assert_true(false, "station.tscn mounts on a themed host")
		return
	assert_false(
		bool(profile.get(&"_dirty")),
		"the build of every pane dirties nothing (L18/L122)"
	)
	assert_eq(profile.call(&"market"), market_before, "the stale market band is not advanced")
	assert_eq(profile.call(&"auction"), shelf_before, "and the AUCTION shelf is not drawn")
	profile.call(&"flush")
	assert_eq(FileAccess.get_md5(SCRATCH_PROFILE), md5_before, "md5 before and after: unchanged")
	assert_eq(
		FileAccess.get_modified_time(SCRATCH_PROFILE),
		mtime_before,
		"and the file was not rewritten at all"
	)
	## The dock half: the route entry is where the market normalises.
	screen.call(&"on_route", {})
	assert_eq(
		int((profile.call(&"market") as Dictionary).get("last_band", 0)),
		ClockScript.now(),
		"the dock normalised the market to the clock (L18)"
	)
	## The switch half: the shell's focus pass into the AUCTION pane pops `enter_pane`.
	screen.call(&"_select_module", StationScript.Module.AUCTION)
	screen.call(&"_focus_active_panel")
	assert_eq(
		int((profile.call(&"auction") as Dictionary).get("last_band", 0)),
		ClockScript.now(),
		"and entering the pane rolled the shelf (L122)"
	)


## ---------------------------------------------------------------------------
## A5 - the launch orders its slots by the fit, never the catalogue (L90/L93)
## ---------------------------------------------------------------------------


## The fixture-side half of A5, measured on the shipped launch: a fit whose W cells lead with
## the **railgun** (the catalogue's last family, and one `PlayerState.WEAPONS` does not carry
## at all) lands as `[railgun, laser]` in `_state.weapons`, each slot seeded from its own
## family's hold draw. The three engine2 suites' fixtures stage the same way (their own fit
## plus their own packs and hold), which is what makes the gate read one count on live and
## scratch `user://`.
func test_the_launch_orders_its_slots_by_the_fit_and_draws_its_own_hold() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the launch's store")
		return
	var active := StringName(profile.call(&"active_ship"))
	profile.call(&"set_fit", active, {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_railgun", &"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	})
	profile.set(&"_ammo", {&"railgun": 0, &"laser": 0})
	profile.set(&"_ammo_rem", {})
	profile.set(&"_cargo", {&"ammo_railgun": 5, &"ammo_laser": 3})
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var state = scene.get(&"_state")
	assert_true(state != null, "the scene built its state")
	if state == null:
		return
	assert_true(
		StringName(PlayerStateScript.WEAPONS[0]) != &"railgun",
		"the catalogue's first family is not the fit's first (%s)" % str(PlayerStateScript.WEAPONS)
	)
	assert_eq(
		state.weapons,
		[&"railgun", &"laser"] as Array[StringName],
		"the launched slots are the fit's own cells, in cell order"
	)
	assert_eq(
		state.ammo,
		[50, 30] as Array[int],
		"each slot is seeded from its own family's hold draw (5 x 10, 3 x 10)"
	)
	assert_eq(int(profile.call(&"ammo_of", &"railgun")), 50, "the railgun's pack is its load")
	assert_eq(int(profile.call(&"ammo_of", &"laser")), 30, "and the laser's its own")
	assert_eq(int(profile.call(&"cargo_qty", &"ammo_railgun")), 0, "the railgun's units are spent")
	assert_eq(int(profile.call(&"cargo_qty", &"ammo_laser")), 0, "and so are the laser's")


## ---------------------------------------------------------------------------
## A6 - one bag accessor law, and the lost fitted instance (L110/L124)
## ---------------------------------------------------------------------------


## The law, measured on both cases L110 names: `module_count(record_id)` is the **record**
## read - an instance-keyed bag answers 0 for the base id while `instances_of` lists every
## in-bag record, and a stacked record answers its units while `instances_of` still lists
## one cell - and every aggregate reads the bag itself. The fitting pane's `OWNED ×<n>` cell
## counts units (its pin), the armory's inventory row counts cells (its own suite's pin).
func test_the_bag_law_reads_records_and_aggregates_instances() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the bag's store")
		return
	profile.call(&"set_modules", {})
	var first := StringName(profile.call(&"add_instance", &"w_laser", &"common", [], []))
	var second := StringName(profile.call(&"add_instance", &"w_laser", &"common", [], []))
	var third := StringName(profile.call(&"add_instance", &"w_laser", &"common", [], []))
	assert_eq(
		int(profile.call(&"module_count", &"w_laser")),
		0,
		"an instance-keyed bag answers 0 for the base id (the record read)"
	)
	assert_eq(
		(profile.call(&"instances_of", &"w_laser") as Array).size(),
		3,
		"while instances_of lists the three in-bag records (the aggregate read)"
	)
	assert_eq(
		(profile.call(&"instances_of", &"w_laser") as Array),
		[first, second, third] as Array[StringName],
		"in creation order"
	)
	## The stacked case: one record, two units, one cell.
	profile.call(&"set_modules", {})
	profile.call(&"add_module", &"w_laser", 2)
	assert_eq(int(profile.call(&"module_count", &"w_laser")), 2, "a stacked record's own count")
	assert_eq(
		(profile.call(&"instances_of", &"w_laser") as Array).size(),
		1,
		"and it is still ONE instance: one cell, one pairing"
	)
	## The take is key-exact: it can never spend an instance of the base it is not handed.
	assert_true(bool(profile.call(&"take_module", &"w_laser", 1)), "one unit comes out of the stack")
	assert_eq(int(profile.call(&"module_count", &"w_laser")), 1, "and the stack is one lighter")
	## The panes' two figures, both read off the same law: units in FITTING, cells in the armory.
	var fitting := _mount_panel("res://ui/station/fitting_panel.tscn")
	var armory := _mount_panel("res://ui/station/armory_panel.tscn")
	if fitting == null or armory == null:
		assert_true(false, "the two panes mount on a themed host")
		return
	assert_eq(
		int(fitting.call(&"owned_total", &"w_laser")),
		1,
		"the fitting pane's OWNED counts the bag's units (its STATION_HUB 5.3 pin)"
	)
	var rows: Array = armory.call(&"inventory_rows")
	assert_eq(rows.size(), 1, "the armory draws one weapon row")
	assert_eq(int(rows[0][&"owned"]), 1, "whose OWNED figure is the base's in-bag records")


## L124's fallback: a fitted **instance** whose bag record is gone. `take_module` on a fitted
## instance is the one call that opens it, so the strip used to lose the module the hull is
## flying; the row is keyed by the id the fit holds and renders exactly **one** battery row,
## with `OWNED ×0` spares.
func test_a_fitted_instance_with_a_lost_record_renders_one_row() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the bag's store")
		return
	var instance := StringName(profile.call(&"add_instance", &"w_laser", &"rare", [], []))
	var active := StringName(profile.call(&"active_ship"))
	profile.call(&"set_fit", active, {&"engines": [&"e_std"], &"power": &"p_std", &"weapons": [instance]})
	## The record is gone: the bag is emptied under the fitted instance.
	profile.call(&"set_modules", {})
	assert_eq(
		int(profile.call(&"module_count", instance)), 0, "the instance's record is gone"
	)
	assert_true(
		(profile.call(&"instances_of", &"w_laser") as Array).is_empty(),
		"and the base carries nothing either"
	)
	var panel := _mount_panel("res://ui/station/fitting_panel.tscn")
	if panel == null:
		assert_true(false, "the fitting pane mounts")
		return
	var ids: Array = panel.call(&"module_row_ids")
	assert_eq(ids, [instance] as Array[StringName], "the strip still draws ONE row, keyed by the fit's id")
	var rows_container := panel.get_node_or_null(^"%ModuleRows") as VBoxContainer
	var row := rows_container.get_child(0) as Button if rows_container != null else null
	assert_true(row != null, "and the row is a real node")
	if row == null:
		return
	var owned := row.find_child("Owned", true, false) as Control
	var value := (owned.get_node_or_null(^"Value") as Label) if owned != null else null
	assert_true(value != null, "the row carries its OWNED cell")
	if value != null:
		assert_eq(value.text, "OWNED ×0", "which reads no spares")
	var title := row.find_child("Title", true, false) as Label
	assert_true(title != null, "and its title")
	if title != null:
		assert_eq(
			title.text, String(instance), "the id it holds is the honest fallback name"
		)


## ---------------------------------------------------------------------------
## A7 - the money edges (L130/L131/L136)
## ---------------------------------------------------------------------------


## R-S21-1 and R-S21-2 as 01's 2026-09-27 block writes them, measured on the shipped
## arithmetic: a 1-unit ammo sale pays `roundi(0.02 x 2)` = 0 where the 10 CR floor ate the
## whole payout, a 30-unit sale pays 1, and the launch's auto-load banks the last unit's
## unused rounds (cannon 295 + 1 unit -> 300 loaded, 5 rounds kept, spent by the next
## launch's draw). The LAUNCH strip reads the hold's units and the fit's real weapons.
func test_the_ammo_edges_and_the_launch_strip_read_them() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the exchange's store")
		return
	var now := ClockScript.now()
	ExchangeScript.evaluate_market(profile, now)
	## R-S21-1: the floor is skipped for ammunition and no other kind moves.
	assert_eq(ExchangeScript.commission_for(60), 10, "the 10 CR floor still guards every kind")
	assert_eq(ExchangeScript.COMMISSION, 0.02, "and the rate is the pinned 2 %")
	assert_eq(
		ExchangeScript.commission_for_item(&"ammo_laser", 2),
		0,
		"a 2 CR gross ammo sale pays no commission (R-S21-1)"
	)
	assert_eq(
		ExchangeScript.commission_for_item(&"ammo_laser", 60), 1, "a 60 CR one pays roundi(1.2)"
	)
	profile.set(&"_cargo", {&"ammo_laser": 31})
	var small: Dictionary = ExchangeScript.sell(profile, &"ammo_laser", 1, now)
	assert_eq(int(small[&"gross"]), 2, "one laser unit lists at 2 CR")
	assert_eq(int(small[&"fee"]), 0, "the floor no longer eats it")
	assert_eq(int(small[&"paid"]), 2, "so the unit nets its own 2 CR")
	var bulk: Dictionary = ExchangeScript.sell(profile, &"ammo_laser", 30, now)
	assert_eq(int(bulk[&"fee"]), 1, "thirty units pay roundi(0.02 x 60)")
	assert_eq(int(bulk[&"paid"]), 59, "and net 59")
	## R-S21-2: the auto-load draws rounds first and banks the last unit's remainder.
	profile.set(&"_ammo", {&"cannon": 295})
	profile.set(&"_ammo_rem", {})
	profile.set(&"_cargo", {&"ammo_cannon": 1})
	assert_eq(int(profile.call(&"load_ammo_from_hold", &"cannon")), 300, "the pack reaches 300")
	assert_eq(int(profile.call(&"cargo_qty", &"ammo_cannon")), 0, "the unit left the hold")
	assert_eq(
		int(profile.call(&"ammo_remainder", &"cannon")),
		5,
		"and its 5 unused rounds are banked, not burned (L131's loss)"
	)
	profile.set(&"_ammo", {&"cannon": 0})
	assert_eq(
		int(profile.call(&"load_ammo_from_hold", &"cannon")),
		5,
		"the next launch draws the banked rounds first"
	)
	assert_eq(int(profile.call(&"ammo_remainder", &"cannon")), 0, "and the bank is spent")
	## A bank only half drawn keeps its other half: a 3-round shortfall against a banked 6
	## spends 3 of the opened unit's rounds and returns the rest to the bank.
	profile.set(&"_ammo", {&"cannon": 297})
	profile.set(&"_ammo_rem", {&"cannon": 6})
	profile.set(&"_cargo", {})
	assert_eq(int(profile.call(&"load_ammo_from_hold", &"cannon")), 300, "the 3-round shortfall fills")
	assert_eq(
		int(profile.call(&"ammo_remainder", &"cannon")),
		3,
		"and the bank's unspent 3 rounds stay banked"
	)
	## The bank is persisted like the packs (a sibling key, save version 7 unchanged).
	profile.set(&"_ammo_rem", {&"cannon": 4})
	profile.call(&"flush")
	profile.call(&"reload")
	assert_eq(int(profile.call(&"ammo_remainder", &"cannon")), 4, "a banked remainder survives the file")
	## L136/A7: the strip reads the hold's units and the fit's real weapons.
	var active := StringName(profile.call(&"active_ship"))
	profile.call(&"set_fit", active, {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_cannon", &"w_cannon"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	})
	profile.set(&"_ammo", {&"cannon": 0})
	profile.set(&"_ammo_rem", {})
	profile.set(&"_cargo", {&"ammo_cannon": 12})
	var panel := _mount_panel("res://ui/station/launch_panel.tscn")
	if panel == null:
		assert_true(false, "the launch pane mounts")
		return
	assert_eq(
		int(panel.call(&"_weapon_count", profile, active)),
		2,
		"the strip counts the fit's two W cells, not a catalogue constant"
	)
	assert_eq(
		int(panel.call(&"_ammo_total", profile, active)),
		240,
		"and its total is the hold's 12 units (2 x 120 rounds), read without spending them"
	)
	assert_eq(int(profile.call(&"cargo_qty", &"ammo_cannon")), 12, "the pane drew nothing")


## ---------------------------------------------------------------------------
## A8 - the owned hull row (L114)
## ---------------------------------------------------------------------------


## R-S21-3 as 10's 2026-09-27 block writes it: an owned hull's row renders **disabled with an
## `OWNED` plate** in its ACTION column, and the press-refusal wording stays the
## transaction's own backstop (`buy_hull` still refuses a direct call). A hull the account
## does not own keeps its live `BUY` row.
func test_an_owned_hull_row_is_disabled_with_the_owned_plate() -> void:
	_reset_profile()
	var profile := _store()
	if profile == null:
		assert_true(false, "the PlayerProfile autoload is the AUCTION's store")
		return
	var shelf: Dictionary = AuctionScript.draw_shelf(profile, null)
	shelf["last_band"] = ClockScript.now()
	profile.call(&"set_auction", shelf)
	var panel := _mount_panel("res://ui/station/auction_panel.tscn")
	if panel == null:
		assert_true(false, "the AUCTION pane mounts")
		return
	var owned_id := StringName(profile.call(&"active_ship"))
	assert_true(bool(profile.call(&"owns_ship", owned_id)), "the fixture owns its active hull")
	var owned_row: Button = panel.call(&"row_of", owned_id)
	assert_true(owned_row != null, "the shelf lists the owned hull")
	if owned_row != null:
		assert_true(owned_row.disabled, "whose row is disabled (R-S21-3)")
		assert_eq(_cell_text(owned_row, "Action"), "OWNED", "with the OWNED plate in ACTION")
	assert_false(
		bool(panel.call(&"buy_hull", owned_id)),
		"and a direct press still refuses through the transaction's own line"
	)
	assert_true(
		String(panel.call(&"status_text")).begins_with("REFUSED · ALREADY OWNED"),
		"reading the pinned refusal wording (%s)" % String(panel.call(&"status_text"))
	)
	var other: StringName = &""
	for row: Dictionary in AuctionScript.hull_rows(profile):
		if not bool(row.get(&"owned", false)):
			other = StringName(row[&"id"])
			break
	assert_true(other != &"", "the shelf also lists a hull the account does not own")
	if other != &"":
		var live_row: Button = panel.call(&"row_of", other)
		assert_true(live_row != null and not live_row.disabled, "whose row stays live")
		assert_eq(_cell_text(live_row, "Action"), "BUY", "and wears BUY")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy adding the runner scene, so
## `root.add_child(...)` fails there. The profile autoload takes children all run long
## (the same host `test_s6_travel.gd` and `test_s6_heat.gd` use).
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _store() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_fixture_host().add_child(scene)
	_scenes.append(scene)
	return scene


func _close_game(scene: Node2D) -> void:
	if scene != null and is_instance_valid(scene):
		_scenes.erase(scene)
		scene.free()


## The station shell under a themed host Control, the way `test_s3_auction.gd` mounts it:
## the host carries the live theme at 1920x1080 so the shell's `_apply_tokens` resolves, and
## the shell's own `_ready` builds every pane - which is exactly what the boot-only A4a row
## measures.
func _mount_station() -> Control:
	return _mount_panel(STATION_SCENE)


## One pane (or the shell) under a themed host, added to the profile autoload because the
## runner calls every test from inside its own `_ready`, when `/root` is still busy.
func _mount_panel(path: String) -> Control:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var host := Control.new()
	host.name = "S21PaneHost"
	host.theme = ThemeRes
	host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(host)
	_nodes.append(host)
	var pane := packed.instantiate() as Control
	if pane == null:
		return null
	host.add_child(pane)
	return pane


## One row's cell text: the cell box's own `Value` label, `""` for a cell the row does not
## carry (`test_s3_auction.gd`'s own read-back).
func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


func _free_scenes() -> void:
	for scene: Node2D in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


## An NPC hull of the fixture's own archetype and class, inside the tree so its `_ready`
## joins the `npc_ship` group a ram's peer walk resolves through.
func _npc(parent: Node2D) -> Node2D:
	var stats: ShipStats = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	var npc := NpcShipScript.new() as Node2D
	if npc == null:
		return null
	parent.add_child(npc)
	_nodes.append(npc)
	npc.call(&"setup", NPC_ARCHETYPE, stats, NPC_HULL, {&"sprite_path": NPC_SPRITE})
	return npc


## A real rock, inside the tree (its own body is the node itself).
func _rock(parent: Node2D) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	if rock == null:
		return null
	parent.add_child(rock)
	_nodes.append(rock)
	rock.call(&"setup", ROCK_MINERAL, 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	return rock


## A field of `FIELD_ROCKS_MAX` rocks on the pinned seed and sector 1's own tier mix
## (`SECTOR_TIER_MIX[1]`), so every yield roll and its ×0.7 band come off one known stream.
func _field() -> Node2D:
	var field := AsteroidFieldScript.new() as Node2D
	if field == null:
		return null
	_fixture_host().add_child(field)
	_nodes.append(field)
	field.call(
		&"setup",
		{
			&"seed": FIELD_SEED,
			&"rocks": AsteroidFieldScript.FIELD_ROCKS_MAX,
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[1],
		}
	)
	return field


## The field's rocks' own bores (the roll the ×0.7 window is applied to), in spawn order.
func _bores(field: Node2D) -> Array[float]:
	var out: Array[float] = []
	for rock: Node2D in field.call(&"rocks"):
		out.append(float(rock.call(&"bore_ore")))
	return out


## One module's display name as the armory's own line spells it, read from the catalogue.
func _module_name(base_id: StringName) -> String:
	return String(ModuleDataScript.module(base_id).get(&"name", "")).to_upper()


## The last status line a pane strip handed out, `""` for a strip that said nothing.
func _last_strip(messages: Array[String]) -> String:
	return messages[messages.size() - 1] if not messages.is_empty() else ""


func _gate(scene: Node2D) -> Node:
	var sector = scene.get(&"_sector")
	if sector == null or not sector.has_method(&"gates"):
		return null
	var gates: Array = sector.call(&"gates")
	return gates[0] if not gates.is_empty() else null


## Every live wreck drop under a scene, by the group `Pickup.setup` joins.
func _pickups(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		if child.is_in_group(PickupScript.PICKUP_GROUP):
			out.append(child)
		out.append_array(_pickups(child))
	return out


func _pickup_count(node: Node) -> int:
	return _pickups(node).size()


func _pools(state) -> Dictionary:
	return {"hull": float(state.hull), "shield": float(state.shield)}


func _pool_total(pools: Dictionary) -> float:
	return float(pools.get("hull", 0.0)) + float(pools.get("shield", 0.0))


func _heat_of(profile: Node, faction: StringName) -> int:
	return int((profile.call(&"heat") as Dictionary).get(String(faction), 0))


func _arm_wreck_drop(profile: Node, amount: int) -> bool:
	profile.call(&"add_cargo", &"mineral_iron", amount)
	var held := int((profile.call(&"cargo_items") as Dictionary).get(&"mineral_iron", -1))
	assert_eq(held, amount, "the fixture's hold carries %d iron" % amount)
	return held == amount


## Clears every static this suite touches, in both directions: the crossing flag, the wreck
## ledger, the heat bank and the clock override. Called from `setup` and `teardown`, so a
## row can neither inherit nor leak one.
func _reset_shared_state() -> void:
	GameScript._transit_destination = &""
	GameScript._heat_play_time = 0.0
	GameScript._wreck_drops.clear()
	ClockScript.clear_override()


func _reset_profile() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")


func _stage_scratch_store() -> void:
	var profile := _store()
	if profile == null:
		return
	_previous_path = String(profile.get(&"save_path"))
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")
	Log.log_path = SCRATCH_LOG


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
