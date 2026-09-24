@tool
extends McpTestSuite
## Suite s6_travel: wave S6's travel core - the sector registry's spine rows, the jump
## gate's fee and transaction law, the border corridor's presence hold and the sector
## transition through the `loading` route.
##
## Contract: docs/CONTRACTS.md §19 (the pin), docs/gameplay/11_galactic_map.md §2/§3/§5
## (gates, corridors, transitions), docs/gameplay/17_coder_handoff.md §5 (transaction
## law), 18_engine_spec §14 slice 3. The fee's worked rows are 11 §2.1's own (adjacent
## 250, two away 350) and 11 §5's 750 - `floor(250 × 1.5 × 2)`; the `562` the first
## draft carried was the additive reversal's figure and is not this build's number.
##
## The pure tests are arithmetic on the shipped classes. The live tests instantiate
## `game.tscn` the way `test_engine2_dock.gd` does (the profile autoload as the fixture
## host) and repoint `PlayerProfile.save_path` at a scratch file for the length of the
## suite, so the owner's `user://profile.cfg` is never written.

const Registry := preload("res://game/sector_registry.gd")
const GateScript := preload("res://game/gate.gd")
const CorridorScript := preload("res://game/corridor.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const PickupScript := preload("res://game/pickup.gd")
const Log := preload("res://game/economy_log.gd")
const GameScript := preload("res://game/game.gd")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_s6_travel.cfg"
const SCRATCH_LOG := "user://test_s6_travel_log.txt"

const SECTOR_NAME_1 := "Halcyon Reach"
const SECTOR_NAME_2 := "Iron Marches"

## 11 §2.1's two worked rows and 11 §5's 750, as numbers, so a failure message names
## the doc's own figure.
const FEE_ADJACENT := 250
const FEE_TWO_AWAY := 350
const FEE_WANTED_INTO_7 := 750


## A profile double for the pure gate tests: the four methods `Gate` reaches, plus a
## `spend_calls` counter so "the refusal never charged" is a reading and not an absence.
class StubProfile extends RefCounted:
	var credits_value := 0
	var spend_calls := 0

	func credits() -> int:
		return credits_value

	func can_afford(amount: int) -> bool:
		return amount <= 0 or credits_value >= amount

	func spend(amount: int) -> bool:
		if amount <= 0:
			return true
		if amount > credits_value:
			return false
		credits_value -= amount
		spend_calls += 1
		return true


var _scenes: Array[Node2D] = []
## The bare (out-of-tree) gate/corridor fixtures. The editor runner frees what `track`
## registers, but the headless twin never calls it (see `test_engine2_npc.gd`), so the
## suite frees them itself: an Area2D left alive leaks its RID at exit.
var _bare: Array[Node] = []
var _previous_path := ""


func suite_name() -> String:
	return "s6_travel"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_scratch_store()
	GameScript._transit_destination = &""


## Per-test: a leaked transition flag would make the next scene boot as a crossing.
func setup() -> void:
	GameScript._transit_destination = &""


func teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()


func suite_teardown() -> void:
	_free_scenes()
	_free_bare()
	GameScript._transit_destination = &""
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## The registry rows (11 §1/§2.3, CONTRACTS §19)
## ---------------------------------------------------------------------------


func test_registry_rows_carry_the_spine_neighbours_and_gate_links() -> void:
	var expected := {
		1: [2], 2: [1, 3], 3: [2, 4], 4: [3, 5], 5: [4, 6], 6: [5, 7], 7: [6],
	}
	for number: int in expected.keys():
		var row: Dictionary = Registry.sector(Registry.sector_id_for(number))
		assert_false(row.is_empty(), "sector %d has a row" % number)
		if row.is_empty():
			continue
		assert_eq(
			row.get(&"neighbours", []),
			expected[number],
			"sector %d neighbours are the §2.3 spine" % number
		)
		assert_eq(
			row.get(&"gate_links", []),
			expected[number],
			"sector %d gate_links are the same spine links" % number
		)


func test_registry_corridors_match_the_spine_and_sit_on_a_map_edge() -> void:
	var half := Registry.SECTOR_SIZE.x * 0.5
	for number in range(1, 8):
		var row: Dictionary = Registry.sector(Registry.sector_id_for(number))
		var neighbours: Array = row.get(&"neighbours", [])
		var corridors: Array = row.get(&"corridors", [])
		assert_eq(
			corridors.size(),
			neighbours.size(),
			"sector %d has one corridor per neighbour" % number
		)
		for entry: Variant in corridors:
			var record: Dictionary = entry
			var dest := int(record.get(&"dest", 0))
			assert_contains(neighbours, dest, "corridor dest %d is a spine neighbour" % dest)
			var band: Rect2 = record.get(&"edge_rect", Rect2())
			assert_eq(band.size.x, Registry.CORRIDOR_DEPTH, "the band is CORRIDOR_DEPTH deep")
			assert_eq(band.size.y, Registry.SECTOR_SIZE.y, "and spans the arena")
			var at_edge := (
				is_equal_approx(band.position.x, -half)
				or is_equal_approx(band.position.x + band.size.x, half)
			)
			assert_true(at_edge, "corridor %d sits on a map edge" % dest)


func test_registry_carries_the_pinned_travel_constants() -> void:
	assert_eq(Registry.GATE_FEE_BASE, 150, "11 §2.1's base fee")
	assert_eq(Registry.GATE_FEE_PER_SECTOR, 100, "11 §2.1's per-sector fee")
	assert_eq(Registry.CORRIDOR_DEPTH, 600.0, "11 §5's proposed corridor depth")
	assert_eq(Registry.DERELICT_SCAN_RANGE, 300.0, "11 §5's proposed derelict scan range")
	assert_eq(Registry.RIFT_DRAIN, 12.0, "11 §5's proposed rift drain")
	assert_eq(
		Registry.ANOMALY_WEIGHTS_RIFT_DOUBLED,
		[&"sector_6"],
		"11 §3.2: the Hollows rolls the rift at 2x"
	)


## ---------------------------------------------------------------------------
## The gate fee (11 §2.1 + §5)
## ---------------------------------------------------------------------------


func test_gate_fee_reproduces_the_worked_rows() -> void:
	var adjacent = _gate(2, 1)
	assert_eq(
		int(adjacent.fee_for(NpcRegistryScript.HEAT_CLEAN)),
		FEE_ADJACENT,
		"adjacent = 150 + 100 x 1"
	)
	var two_away = _gate(3, 1)
	assert_eq(
		int(two_away.fee_for(NpcRegistryScript.HEAT_CLEAN)),
		FEE_TWO_AWAY,
		"two away = 150 + 100 x 2"
	)
	var into_seven = _gate(7, 6)
	assert_eq(
		int(into_seven.fee_for(NpcRegistryScript.HEAT_WANTED)),
		FEE_WANTED_INTO_7,
		"floor(250 x 1.5 x 2) = 750; 562 was the additive reversal"
	)


func test_gate_fee_composes_the_multipliers_multiplicatively() -> void:
	var two_away = _gate(3, 1)
	assert_eq(int(two_away.fee_for(NpcRegistryScript.HEAT_WANTED)), 525, "floor(350 x 1.5)")
	var two_into_seven = _gate(7, 5)
	assert_eq(int(two_into_seven.fee_for(NpcRegistryScript.HEAT_CLEAN)), 700, "floor(350 x 2)")
	assert_eq(
		int(two_into_seven.fee_for(NpcRegistryScript.HEAT_WANTED)),
		1050,
		"floor(350 x 1.5 x 2): the multipliers stack on the base, not on each other"
	)
	var adjacent_into_seven = _gate(7, 6)
	assert_eq(
		int(adjacent_into_seven.fee_for(NpcRegistryScript.HEAT_SUSPECT)),
		500,
		"the lawless multiplier alone: floor(250 x 2)"
	)


func test_gate_distance_is_the_spine_links() -> void:
	assert_eq(int(_gate(2, 1).distance_sectors()), 1, "adjacent is one link")
	assert_eq(int(_gate(3, 1).distance_sectors()), 2, "two away is two links")
	assert_eq(int(_gate(5, 7).distance_sectors()), 2, "and it is directionless")


func test_gate_names_its_destination_from_the_registry() -> void:
	assert_eq(String(_gate(2, 1).destination_name()), SECTOR_NAME_2, "sector 2's row name")
	assert_eq(String(_gate(1, 2).destination_name()), SECTOR_NAME_1, "and sector 1's")


## ---------------------------------------------------------------------------
## The gate transaction (17 §5, CONTRACTS §19)
## ---------------------------------------------------------------------------


func test_gate_jump_refuses_outlaw_and_writes_nothing() -> void:
	var gate = _gate(2, 1)
	var profile := StubProfile.new()
	profile.credits_value = 10000
	var code := int(gate.jump(profile, NpcRegistryScript.HEAT_OUTLAW))
	assert_eq(code, -1, "the Outlaw heat tier is refused (13 §3)")
	assert_eq(profile.credits(), 10000, "the refusal leaves the balance untouched")
	assert_eq(profile.spend_calls, 0, "and never reaches the charge")
	assert_false(bool(gate.is_charging()), "and starts no charge-up")


func test_gate_jump_refuses_short_funds_and_writes_nothing() -> void:
	var gate = _gate(2, 1)
	var profile := StubProfile.new()
	profile.credits_value = FEE_ADJACENT - 1
	var code := int(gate.jump(profile, NpcRegistryScript.HEAT_CLEAN))
	assert_eq(code, -2, "one credit short of the 250 fee is refused")
	assert_eq(profile.credits(), FEE_ADJACENT - 1, "the balance is untouched")
	assert_eq(profile.spend_calls, 0, "and never reaches the charge")


func test_gate_jump_charges_once_and_signals_after_two_seconds() -> void:
	var gate = _gate(2, 1)
	var profile := StubProfile.new()
	profile.credits_value = 1000
	var jumps: Array = []
	gate.jumped.connect(func(dest: int) -> void: jumps.append(dest))
	var code := int(gate.jump(profile, NpcRegistryScript.HEAT_CLEAN))
	assert_eq(code, 0, "the fee is paid")
	assert_eq(profile.credits(), 1000 - FEE_ADJACENT, "1000 - 250")
	assert_eq(profile.spend_calls, 1, "exactly one charge")
	assert_true(bool(gate.is_charging()), "the 2 s charge-up runs")
	var again := int(gate.jump(profile, NpcRegistryScript.HEAT_CLEAN))
	assert_eq(again, 0, "a second confirm inside the charge-up is inert")
	assert_eq(profile.spend_calls, 1, "and does not charge twice")
	gate.advance_charge(1.0)
	assert_eq(jumps.size(), 0, "1 s is short of the charge")
	assert_gt(float(gate.charge_progress()), 0.4, "and the charge has progressed")
	gate.advance_charge(1.0)
	assert_eq(jumps.size(), 1, "2 s completes the charge")
	assert_eq(int(jumps[0]), 2, "and names the destination")
	assert_false(bool(gate.is_charging()), "the charge is spent")


func test_gate_refusal_on_the_live_profile_is_byte_identical() -> void:
	var profile := _store()
	assert_true(profile != null, "the PlayerProfile autoload is the gate's store")
	if profile == null:
		return
	_reset_profile()
	var gate = _gate(2, 1)
	profile.call(&"set_heat", {"concord": 95})
	var outlaw_before := _profile_snapshot(profile)
	var outlaw_code := int(gate.jump(profile, NpcRegistryScript.HEAT_OUTLAW))
	assert_eq(outlaw_code, -1, "the live store's Outlaw tier is refused")
	assert_eq(
		_profile_snapshot(profile),
		outlaw_before,
		"the Outlaw refusal leaves the live profile byte-identical"
	)
	profile.call(&"spend", int(profile.call(&"credits")) - 100)
	var funds_before := _profile_snapshot(profile)
	var funds_code := int(gate.jump(profile, NpcRegistryScript.HEAT_CLEAN))
	assert_eq(funds_code, -2, "100 CR cannot pay the 250 fee")
	assert_eq(
		_profile_snapshot(profile),
		funds_before,
		"the funds refusal leaves the live profile byte-identical"
	)


func test_gate_contains_only_inside_the_ring() -> void:
	var gate = _gate(2, 1)
	gate.position = Vector2(900.0, 0.0)
	assert_true(bool(gate.contains(Vector2(900.0, 0.0))), "the centre is inside")
	assert_true(bool(gate.contains(Vector2(1050.0, 0.0))), "150 u off centre is inside")
	assert_false(bool(gate.contains(Vector2(1300.0, 0.0))), "400 u off centre is outside")


## ---------------------------------------------------------------------------
## The corridor hold (11 §2.2 + §5 tick 2)
## ---------------------------------------------------------------------------


func test_corridor_hold_is_fifteen_seconds_of_presence() -> void:
	var corridor = _corridor(2, Registry.edge_band(-1))
	var inside: Vector2 = Registry.edge_band(-1).get_center()
	assert_eq(float(corridor.hold_progress()), 0.0, "a fresh corridor is empty")
	corridor.update_presence(7.5, inside)
	assert_eq(float(corridor.hold_progress()), 0.5, "7.5 of 15 s is halfway")
	corridor.update_presence(0.1, Vector2.ZERO)
	assert_eq(float(corridor.hold_progress()), 0.0, "leaving the band resets the hold")
	assert_false(bool(corridor.is_holding()), "and the presence flag clears")


func test_corridor_crossing_names_the_neighbour_once() -> void:
	var corridor = _corridor(2, Registry.edge_band(-1))
	var inside: Vector2 = Registry.edge_band(-1).get_center()
	var crossed: Array = []
	corridor.crossed.connect(func(dest: int) -> void: crossed.append(dest))
	corridor.update_presence(14.9, inside)
	assert_eq(crossed.size(), 0, "14.9 s is short of the 15 s hold")
	corridor.update_presence(0.2, inside)
	assert_eq(crossed.size(), 1, "15 s completes the hold")
	assert_eq(int(crossed[0]), 2, "and names the neighbour")
	corridor.update_presence(1.0, inside)
	assert_eq(crossed.size(), 1, "the crossing fires once, not per frame")


func test_corridor_hull_damage_does_not_interrupt_the_hold() -> void:
	var scene := _open_game()
	assert_true(scene != null, "game.tscn instantiates")
	if scene == null:
		return
	var sector = scene.get(&"_sector")
	var corridors: Array = sector.call(&"corridors")
	assert_gt(corridors.size(), 0, "the sector spawns a border corridor")
	if corridors.is_empty():
		_close_game(scene)
		return
	var corridor = corridors[0]
	var band: Rect2 = corridor.get(&"edge")
	var inside: Vector2 = band.get_center()
	corridor.call(&"update_presence", 5.0, inside)
	var before := float(corridor.call(&"hold_progress"))
	assert_gt(before, 0.3, "5 of 15 s accrued")
	scene.call(&"_on_ship_damage_taken", 25.0)
	assert_eq(
		float(corridor.call(&"hold_progress")),
		before,
		"11 §5 tick 2 as built: a hull hit leaves the presence hold alone"
	)
	_close_game(scene)


## ---------------------------------------------------------------------------
## The sector transition (11 §2.3, CONTRACTS §19)
## ---------------------------------------------------------------------------


func test_launch_labels_the_registry_sector_name() -> void:
	var scene := _open_game()
	assert_true(scene != null, "game.tscn instantiates")
	if scene == null:
		return
	assert_eq(
		String(scene.get(&"_sector_name")),
		SECTOR_NAME_1,
		"the label is sector 1's registry name, not the stale Helios Drift interim"
	)
	_close_game(scene)


func test_gate_prompt_rides_the_prompt_line_and_refuses_at_outlaw() -> void:
	_reset_profile()
	var profile := _store()
	assert_true(profile != null, "the PlayerProfile autoload is the prompt's heat owner")
	if profile == null:
		return
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var sector = scene.get(&"_sector")
	var gates: Array = sector.call(&"gates")
	assert_gt(gates.size(), 0, "the sector spawns a gate ring")
	if gates.is_empty():
		_close_game(scene)
		return
	var gate = gates[0]
	scene.get(&"_ship").global_position = gate.global_position
	scene.call(&"_update_dock_prompt")
	var prompt := String(scene.get(&"_prompt"))
	assert_true(prompt.begins_with("JUMP TO "), "the gate line names the jump (%s)" % prompt)
	assert_true(prompt.ends_with(" CR"), "and the fee (%s)" % prompt)
	profile.call(&"set_heat", {"concord": 95})
	scene.call(&"_update_dock_prompt")
	assert_eq(
		String(scene.get(&"_prompt")),
		"GATE REFUSED \u2014 OUTLAW",
		"11 §5's refusal line at the Outlaw heat tier"
	)
	_close_game(scene)


func test_transition_files_the_vitals_and_keeps_the_hold_across_the_crossing() -> void:
	_reset_profile()
	var profile := _store()
	assert_true(profile != null, "the PlayerProfile autoload is the transition's store")
	if profile == null:
		return
	var scene := _open_game()
	if scene == null:
		assert_true(false, "game.tscn instantiates")
		return
	var state = scene.get(&"_state")
	state.set_hull(37.0)
	state.set_shield(12.0)
	state.set_fuel(88.0)
	profile.call(&"add_cargo", &"iron_ore", 7)
	profile.call(&"set_heat", {"concord": 42})
	profile.call(&"flush")
	var hold_before: Dictionary = profile.call(&"cargo_items")
	var pickup := PickupScript.new() as Node2D
	scene.add_child(pickup)
	pickup.global_position = Vector2(4000.0, 4000.0)
	pickup.call(&"setup", &"iron_ore", 1, false)
	assert_eq(_pickup_count(scene), 1, "the departing scene holds a pickup")
	var seen := {}
	var handler := func(route: StringName, params: Dictionary) -> void:
		seen["route"] = route
		seen["params"] = params
		seen["vitals"] = profile.call(&"vitals_of", profile.call(&"active_ship"))
	scene.route_requested.connect(handler)
	scene.call(&"_transition_to_sector", 2)
	scene.route_requested.disconnect(handler)
	assert_eq(seen.get("route"), &"loading", "the crossing routes through `loading`")
	var params: Dictionary = seen.get("params", {})
	assert_eq(params.get(&"destination"), &"game", "and asks for the game scene back")
	assert_eq(params.get(&"sector"), &"sector_2", "carrying the destination sector")
	var filed: Dictionary = seen.get("vitals", {})
	assert_eq(int(filed.get("hull", -1)), 37, "hull was filed before the route ran")
	assert_eq(int(filed.get("shield", -1)), 12, "shield too")
	assert_eq(int(filed.get("fuel", -1)), 88, "and the tank")
	_close_game(scene)
	## The reload: a fresh scene boots from the filed record, the pin's own mechanism.
	var arrived := _open_game()
	assert_true(arrived != null, "the destination scene boots")
	if arrived == null:
		return
	var arrived_state = arrived.get(&"_state")
	assert_eq(int(arrived_state.hull), 37, "hull persists across the crossing")
	assert_eq(int(arrived_state.shield), 12, "shield persists")
	assert_eq(int(arrived_state.fuel), 88, "fuel persists")
	assert_eq(
		profile.call(&"cargo_items"),
		hold_before,
		"the hold is byte-equal (the crossing does not spend it on a second ammo load)"
	)
	assert_eq(profile.call(&"heat"), {"concord": 42}, "heat persists")
	assert_eq(_pickup_count(arrived), 0, "pickups reset with the scene")
	arrived.call(&"on_route", {&"sector": &"sector_2"})
	assert_eq(
		String(arrived.get(&"_sector_row_id")),
		"sector_2",
		"the arrival lands the destination sector"
	)
	assert_eq(String(arrived.get(&"_sector_name")), SECTOR_NAME_2, "and its registry name")
	_close_game(arrived)


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## A bare gate, out of tree, with its origin set so `distance_sectors` answers.
## `track` hands it to the editor runner's cleanup; `_bare` is the headless twin's.
func _gate(dest: int, origin: int):
	var gate = GateScript.new()
	track(gate)
	_bare.append(gate)
	gate.setup(dest)
	gate.set_origin_sector(origin)
	return gate


func _corridor(dest: int, band: Rect2):
	var corridor = CorridorScript.new()
	track(corridor)
	_bare.append(corridor)
	corridor.setup(dest, band)
	return corridor


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy adding the runner scene, so
## `root.add_child(...)` fails there. The profile autoload takes children all run long
## (the same host `test_engine2_dock.gd` uses).
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


func _free_scenes() -> void:
	for scene: Node2D in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()


func _free_bare() -> void:
	for node: Node in _bare:
		if is_instance_valid(node):
			node.free()
	_bare.clear()


## The store the suite owns for its length: repointed before anything can write, then
## reset to the deterministic default inside the scratch path.
func _stage_scratch_store() -> void:
	var profile := _store()
	if profile == null:
		return
	_previous_path = String(profile.get(&"save_path"))
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")
	Log.log_path = SCRATCH_LOG


func _reset_profile() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")


## Every field a gate refusal must leave alone, deep-compared by `assert_eq`.
func _profile_snapshot(profile: Node) -> Dictionary:
	return {
		"credits": int(profile.call(&"credits")),
		"cargo": profile.call(&"cargo_items"),
		"heat": profile.call(&"heat"),
		"standing": profile.call(&"standing"),
		"ammo_laser": int(profile.call(&"ammo_of", &"laser")),
		"vitals": profile.call(&"vitals_of", profile.call(&"active_ship")),
	}


func _pickup_count(node: Node) -> int:
	var count := 0
	for child: Node in node.get_children():
		if child.is_in_group(&"pickup"):
			count += 1
		count += _pickup_count(child)
	return count


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
