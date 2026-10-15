@tool
extends McpTestSuite
## Suite s39_feel: wave S39 - the owner's second playtest (2026-10-10), seven findings.
## One row per pinned acceptance (A1-A7):
##   A1 (T-164) an armed hostile fires at its target, a neutral never does;
##   A2 (T-165) thrust commanded against the travel accelerates at the reversal-assist rate;
##   A3 (T-166) a lit boost raises the commanded acceleration, not only the ceiling;
##   A4 (T-167) Shift boosts with no afterburner fitted, and the module stacks on top;
##   A5 (T-168) a route leg advances once the hull has carried past its waypoint;
##   A6 (T-169) the knockback share is below the pre-S39 pin;
##   A7 (T-170) the flight HUD carries a live hold readout and the armory subtitle its slots.
##
## Every shipped number is read from its own owner (`NpcRegistry`, `Impact`, `PlayerShip`,
## `NpcBrain`, `Hud`, `ArmoryPanel`); the expected side is the only place a literal appears.

const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcBrainScript := preload("res://game/npc_brain.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const HudScript := preload("res://ui/hud/hud.gd")
const ArmoryPanelScript := preload("res://ui/station/armory_panel.gd")

const HULL: StringName = &"ship_fighter"
const ARMORY_HULL: StringName = &"ship_vanguard"
const PHYSICS_STEP := 1.0 / 60.0
const SHOT_NODE := "NpcShot"

## A stand-in brain that answers only `target()`, so `NpcShip._step_weapon` can be driven
## without standing up the whole aggro state machine.
class FakeBrain:
	extends RefCounted
	var _target: Node2D = null
	func target() -> Node2D:
		return _target


var _staged: Array[Node] = []
var _hud: Control = null


func suite_name() -> String:
	return "s39_feel"


func setup() -> void:
	_staged.clear()


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()
	_release_pressed()


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## The fixture host: the `PlayerProfile` autoload (never busy setting up children), else
## the tree root - the same host the D7 and S2.5 suites stage their nodes into.
func _host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _release_pressed() -> void:
	for action: StringName in [PlayerShipScript.BOOST_ACTION]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _player(with_booster: bool = false) -> Dictionary:
	var fit: Dictionary = ShipFitScript.STANDARD_FIT.duplicate(true)
	if with_booster:
		fit[&"boosters"] = [&"b_afterburner"]
	var stats: Variant = ShipFitScript.resolve(HULL, fit)
	var state: Variant = PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.setup()
	state.hull = stats.hull_max
	var ship: Variant = PlayerShipScene.instantiate()
	_host().add_child(ship)
	ship.setup(stats, state, ShipFitScript.fitted_ids(fit))
	_staged.append(ship)
	return {&"ship": ship, &"state": state, &"stats": stats}


func _npc(archetype: StringName) -> Variant:
	var ship: Variant = NpcShipScript.new()
	_host().add_child(ship)
	ship.setup(archetype, ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT), HULL)
	_staged.append(ship)
	return ship


func _count_shots(root: Node) -> int:
	var total := 0
	for child: Node in root.get_children():
		if child.name == SHOT_NODE:
			total += 1
		total += _count_shots(child)
	return total


## --- A1 (T-164): enemies shoot back ------------------------------------------------


func test_a1_the_armed_archetypes_fire_and_the_neutral_does_not() -> void:
	for archetype: StringName in [&"pirate", &"swarmer", &"patrol", &"turret", &"boneyard", &"pyre", &"boss"]:
		assert_true(
			NpcRegistryScript.has_weapon(archetype),
			"%s carries a gun (the owner's 'enemies dont shoot back')" % archetype
		)
	assert_false(
		NpcRegistryScript.has_weapon(&"trader"),
		"the neutral convoy never fires (18 section 5: 'flies fixed route; flees from Suspect+')"
	)
	var row: Dictionary = NpcRegistryScript.weapon_row(&"pirate")
	assert_gt(float(row.get(&"damage", 0.0)), 0.0, "the pirate's gun deals damage")
	assert_gt(float(row.get(&"range", 0.0)), 0.0, "and has a reach")


func test_a1_an_engaged_hostile_puts_shots_on_target() -> void:
	var ship: Variant = _npc(&"pirate")
	assert_true(bool(ship.call(&"armed")), "the pirate hull is armed")
	var brain := FakeBrain.new()
	var target: Node2D = Node2D.new()
	_host().add_child(target)
	_staged.append(target)
	target.global_position = Vector2(200.0, 0.0)
	brain._target = target
	ship.set(&"_brain", brain)
	ship.set(&"_intent", {NpcBrainScript.INTENT_FIRE: true})
	var scene := _tree().root
	var before := _count_shots(scene)
	ship.call(&"_step_weapon", PHYSICS_STEP)
	var after := _count_shots(scene)
	assert_eq(
		after - before,
		int(NpcRegistryScript.weapon_row(&"pirate").get(&"shots", 1)),
		"one volley puts the row's shots in the world"
	)
	assert_eq(int(ship.call(&"weapon_volleys")), 1, "and the hull counts the volley")
	## The negative control: the same hull with the fire intent off fires nothing.
	ship.set(&"_intent", {NpcBrainScript.INTENT_FIRE: false})
	ship.set(&"_weapon_cooldown", 0.0)
	var quiet_before := _count_shots(scene)
	ship.call(&"_step_weapon", PHYSICS_STEP)
	assert_eq(_count_shots(scene), quiet_before, "no fire intent, no shot")


## --- A2 (T-165): the reversal assist -----------------------------------------------


func test_a2_a_reversal_thrusts_harder_than_a_forward_burn() -> void:
	var rig := _player()
	var ship: Variant = rig[&"ship"]
	var stats: Variant = rig[&"stats"]
	var nose: Vector2 = Vector2.RIGHT.rotated(float(ship.call(&"_heading")))
	var rate := float(ship.call(&"_accel_rate"))
	var desired: float = stats.max_speed
	## Forward: the commanded speed shares the travel's sign, so the class rate alone.
	## The travel is small so the force's damp-compensation term stays negligible next to
	## the thrust term, which is what the reversal multiplies.
	ship.impact_body().linear_velocity = nose * 5.0
	ship.set(&"_applied_force", Vector2.ZERO)
	ship.call(&"_step_speed", desired, rate, PHYSICS_STEP)
	var forward_force := Vector2(ship.call(&"applied_force")).length()
	## Reversal: the commanded speed opposes the travel, so the rate is multiplied.
	ship.impact_body().linear_velocity = -nose * 5.0
	ship.set(&"_applied_force", Vector2.ZERO)
	ship.call(&"_step_speed", desired, rate, PHYSICS_STEP)
	var reversal_force := Vector2(ship.call(&"applied_force")).length()
	assert_gt(
		reversal_force,
		forward_force * 1.4,
		"a turnaround burns at the assist rate (forward %.1f, reversal %.1f)"
		% [forward_force, reversal_force]
	)
	assert_true(
		is_equal_approx(PlayerShipScript.REVERSAL_ASSIST_MULT, 1.6),
		"the assist is the PROPOSED 1.6 (reversal: 1.0)"
	)


## --- A3 (T-166) and A4 (T-167): the boost buys thrust and works with no module -------


func test_a3_a_lit_boost_raises_the_commanded_acceleration() -> void:
	var rig := _player(true)
	var ship: Variant = rig[&"ship"]
	var base := float(ship.call(&"_accel_rate"))
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	ship.call(&"_update_boosters", PHYSICS_STEP)
	var lit := float(ship.call(&"_accel_rate"))
	assert_gt(lit, base, "a lit boost raises the accel rate (base %.1f, lit %.1f)" % [base, lit])
	assert_gt(
		float(ship.call(&"_boost_multiplier")),
		1.0,
		"and the multiplier is above 1"
	)


func test_a4_shift_boosts_with_no_afterburner_and_the_module_stacks_on_top() -> void:
	var bare := _player(false)
	var bare_ship: Variant = bare[&"ship"]
	assert_false(bool(bare_ship.call(&"has_booster", PlayerShipScript.BOOSTER_AFTERBURNER)),
		"the hull carries no afterburner")
	assert_true(
		is_equal_approx(float(bare_ship.call(&"_boost_multiplier")), 1.0),
		"with Shift up there is no boost"
	)
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	bare_ship.call(&"_update_boosters", PHYSICS_STEP)
	var bare_mult := float(bare_ship.call(&"_boost_multiplier"))
	assert_gt(bare_mult, 1.0, "Shift alone boosts (the owner's 'standard boost while pressing shift')")
	assert_true(
		is_equal_approx(bare_mult, PlayerShipScript.BOOST_BASE_MULT),
		"and it is the baseline multiplier"
	)
	## The module stacks on top of the same baseline.
	var fitted := _player(true)
	var fitted_ship: Variant = fitted[&"ship"]
	fitted_ship.call(&"_update_boosters", PHYSICS_STEP)
	var stacked := float(fitted_ship.call(&"_boost_multiplier"))
	assert_gt(stacked, bare_mult, "the afterburner multiplies on top of the baseline")


## --- A5 (T-168): the convoy recovers its route -------------------------------------


func test_a5_a_route_leg_advances_once_the_hull_has_passed_its_waypoint() -> void:
	var brain: Variant = NpcBrainScript.new()
	var route: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1000.0, 0.0), Vector2(2000.0, 0.0)]
	brain.set_route(route)
	## At the origin the first leg is reached on the ring and the route advances.
	var first := Vector2(brain.call(&"_patrol_waypoint", Vector2.ZERO))
	assert_true(first.is_equal_approx(Vector2(1000.0, 0.0)), "the first leg advances on the ring")
	## Short of the waypoint (500 u, inside the 40 u ring? no) the leg holds.
	var short := Vector2(brain.call(&"_patrol_waypoint", Vector2(500.0, 0.0)))
	assert_true(
		short.is_equal_approx(Vector2(1000.0, 0.0)),
		"a hull short of its waypoint keeps the leg"
	)
	## Past the waypoint (the owner's deflected convoy) the leg advances anyway.
	var passed := Vector2(brain.call(&"_patrol_waypoint", Vector2(1500.0, 0.0)))
	assert_true(
		passed.is_equal_approx(Vector2(2000.0, 0.0)),
		"a hull that carried past its waypoint re-acquires the next leg"
	)


## --- A6 (T-169): the knockback is gentler ------------------------------------------


func test_a6_the_knockback_share_is_below_the_pre_wave_pin() -> void:
	assert_true(
		is_equal_approx(ImpactScript.KNOCKBACK_FRACTION, 0.15),
		"the share is the PROPOSED 0.15 (reversal: 0.40)"
	)
	var mass := 110.0
	var speed := 1000.0
	var shot_mass := 1.0
	var energy := ImpactScript.knockback(speed, shot_mass)
	var new_dv := sqrt(2.0 * energy * mass) / mass
	var old_energy := 0.40 * 0.5 * shot_mass * speed * speed
	var old_dv := sqrt(2.0 * old_energy * mass) / mass
	assert_true(
		new_dv < old_dv,
		"a hit's delivered speed is below the pre-S39 figure (%.1f vs %.1f)" % [new_dv, old_dv]
	)


## --- A7 (T-170): the hold is visible in flight and at the armory --------------------


func test_a7_the_flight_hud_carries_a_live_hold_readout() -> void:
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		assert_true(false, "hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_host().add_child(_hud)
	var block: Node = _hud.get(&"_cargo_block")
	assert_true(block != null, "the HUD builds a cargo block (the owner's in-flight gap)")
	var value: Label = _hud.get(&"_cargo_block_value")
	assert_true(value != null, "with a value label")
	_hud.call(&"_on_cargo_changed", 3, 5)
	assert_eq(value.text, "3/5", "which reads the hold's slots")


## A17 (the owner's 2026-10-15 round): the readout is bounded - 6 rows plus the
## `+<n> MORE` tail, whatever the hold carries.
func test_a17_the_flight_readout_is_bounded() -> void:
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		assert_true(false, "hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_host().add_child(_hud)
	var tree := Engine.get_main_loop() as SceneTree
	var profile: Node = tree.root.get_node_or_null(NodePath("PlayerProfile"))
	assert_true(profile != null, "the profile autoload backs the read")
	if profile == null:
		return
	var previous: Dictionary = (profile.get(&"_cargo") as Dictionary).duplicate(true)
	var staged := {}
	var ids := ["iron", "copper", "chromium", "silicon", "aluminium", "titanium", "nickel", "gold"]
	for index in ids.size():
		staged[StringName("mineral_%s" % ids[index])] = index + 1
	profile.set(&"_cargo", staged)
	_hud.call(&"_refresh_cargo_block")
	var list: Control = _hud.get(&"_cargo_block_list")
	assert_eq(
		list.get_child_count(), HudScript.CARGO_BLOCK_ROWS + 1,
		"eight stacks read six rows and the overflow tail, not eight"
	)
	var tail := list.get_child(HudScript.CARGO_BLOCK_ROWS) as Label
	assert_eq(
		tail.text, HudScript.CARGO_MORE_FORMAT % 2,
		"the tail names the hidden remainder and the way to it"
	)
	profile.set(&"_cargo", previous)
	_hud.call(&"_refresh_cargo_block")
	assert_eq(
		(list.get_child(0) as Label).text, HudScript.CARGO_EMPTY,
		"the emptied hold reads its one row again"
	)


func test_a7_the_armory_subtitle_carries_the_hold_slots() -> void:
	assert_true(
		ArmoryPanelScript.SUBTITLE.contains("HOLD %d/%d"),
		"the ammo subtitle names the hold (the owner's 'how do i know that i have 5 slots')"
	)
	assert_true(
		ArmoryPanelScript.SUBTITLE_FIT.contains("%d CELLS"),
		"the fit subtitle is untouched"
	)
